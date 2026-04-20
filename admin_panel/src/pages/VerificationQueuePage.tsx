import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import { CheckCircle, XCircle, Star, MapPin, Briefcase } from 'lucide-react'
import clsx from 'clsx'

interface PendingPhysio {
  id: number
  name: string
  phone: string
  email: string | null
  specializations: string[]
  experience_years: number
  registration_number: string | null
  city: string | null
  rating: number
  created_at: string
}

function usePendingPhysios() {
  return useQuery<PendingPhysio[]>({
    queryKey: ['pending-physios'],
    queryFn: async () => {
      const res = await api.get('/admin/physios/pending')
      return res.data.data ?? []
    },
  })
}

export default function VerificationQueuePage() {
  const { data = [], isLoading, error } = usePendingPhysios()
  const qc = useQueryClient()
  const [rejectId, setRejectId] = useState<number | null>(null)
  const [rejectReason, setRejectReason] = useState('')

  const approveMutation = useMutation({
    mutationFn: (id: number) =>
      api.put(`/admin/physios/${id}/verify`, { action: 'approve' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['pending-physios'] }),
  })

  const rejectMutation = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason: string }) =>
      api.put(`/admin/physios/${id}/verify`, { action: 'reject', reason }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['pending-physios'] })
      setRejectId(null)
      setRejectReason('')
    },
  })

  if (isLoading) return <Loader />
  if (error) return <div className="p-6 text-red-600">{error.message}</div>

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Verification Queue</h1>
        <p className="text-sm text-gray-500">{data.length} physios awaiting review</p>
      </div>

      {data.length === 0 ? (
        <EmptyState />
      ) : (
        <div className="space-y-4">
          {data.map((physio) => (
            <PhysioCard
              key={physio.id}
              physio={physio}
              onApprove={() => approveMutation.mutate(physio.id)}
              onReject={() => setRejectId(physio.id)}
              approving={approveMutation.isPending && approveMutation.variables === physio.id}
            />
          ))}
        </div>
      )}

      {/* Reject dialog */}
      {rejectId !== null && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md">
            <h2 className="text-lg font-bold mb-2">Reject Physiotherapist</h2>
            <p className="text-sm text-gray-500 mb-4">Provide a reason for rejection (sent to the physio).</p>
            <textarea
              rows={3}
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-red-500"
              placeholder="e.g. Registration certificate unclear, please re-upload"
            />
            <div className="flex gap-3 mt-4">
              <button
                onClick={() => { setRejectId(null); setRejectReason('') }}
                className="flex-1 py-2 rounded-lg border border-gray-300 text-sm font-medium"
              >Cancel</button>
              <button
                onClick={() => rejectMutation.mutate({ id: rejectId, reason: rejectReason })}
                disabled={rejectMutation.isPending}
                className="flex-1 py-2 rounded-lg bg-red-600 text-white text-sm font-semibold disabled:opacity-60"
              >
                {rejectMutation.isPending ? 'Rejecting…' : 'Reject'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function PhysioCard({ physio, onApprove, onReject, approving }: {
  physio: PendingPhysio
  onApprove: () => void
  onReject: () => void
  approving: boolean
}) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5">
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-start gap-4">
          <div className="w-12 h-12 rounded-full bg-brand-50 flex items-center justify-center text-brand-600 font-bold text-lg flex-shrink-0">
            {physio.name?.[0]?.toUpperCase() ?? 'P'}
          </div>
          <div>
            <p className="font-semibold text-gray-900">Dr. {physio.name}</p>
            <p className="text-sm text-gray-500">{physio.phone}{physio.email ? ` · ${physio.email}` : ''}</p>
            <div className="flex flex-wrap gap-3 mt-2 text-xs text-gray-500">
              {physio.city && (
                <span className="flex items-center gap-1">
                  <MapPin size={12} /> {physio.city}
                </span>
              )}
              <span className="flex items-center gap-1">
                <Briefcase size={12} /> {physio.experience_years}y exp
              </span>
              <span className="flex items-center gap-1">
                <Star size={12} /> {physio.rating.toFixed(1)}
              </span>
            </div>
            {physio.specializations.length > 0 && (
              <div className="flex flex-wrap gap-1.5 mt-2">
                {physio.specializations.map((s) => (
                  <span key={s} className="px-2 py-0.5 rounded-full bg-gray-100 text-xs text-gray-600">{s}</span>
                ))}
              </div>
            )}
            {physio.registration_number && (
              <p className="mt-2 text-xs text-gray-400">Reg: {physio.registration_number}</p>
            )}
          </div>
        </div>

        <div className="flex flex-col gap-2 flex-shrink-0">
          <button
            onClick={onApprove}
            disabled={approving}
            className={clsx(
              'flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-semibold transition-colors',
              'bg-green-600 text-white hover:bg-green-700 disabled:opacity-60'
            )}
          >
            <CheckCircle size={15} />
            {approving ? 'Approving…' : 'Approve'}
          </button>
          <button
            onClick={onReject}
            className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-semibold border border-red-300 text-red-600 hover:bg-red-50 transition-colors"
          >
            <XCircle size={15} />
            Reject
          </button>
        </div>
      </div>
    </div>
  )
}

function Loader() {
  return (
    <div className="flex items-center justify-center h-64">
      <div className="animate-spin w-8 h-8 border-2 border-brand-500 border-t-transparent rounded-full" />
    </div>
  )
}

function EmptyState() {
  return (
    <div className="text-center py-16 text-gray-400">
      <CheckCircle size={48} className="mx-auto mb-3 text-green-300" />
      <p className="text-lg font-medium">All caught up!</p>
      <p className="text-sm mt-1">No pending verifications.</p>
    </div>
  )
}
