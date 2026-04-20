import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import { Search, Calendar } from 'lucide-react'
import clsx from 'clsx'

interface Booking {
  id: number
  patient_name: string
  physio_name: string
  booking_type: string
  scheduled_date: string
  scheduled_time: string
  status: string
  payment_status: string
  total_amount: number
}

const STATUS_COLORS: Record<string, string> = {
  confirmed:   'bg-green-100 text-green-700',
  completed:   'bg-blue-100 text-blue-700',
  pending:     'bg-amber-100 text-amber-700',
  cancelled:   'bg-red-100 text-red-700',
  in_progress: 'bg-purple-100 text-purple-700',
}

export default function BookingsPage() {
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')

  const { data = [], isLoading } = useQuery<Booking[]>({
    queryKey: ['admin-bookings', statusFilter],
    queryFn: async () => {
      const res = await api.get('/admin/bookings', {
        params: statusFilter ? { status: statusFilter } : undefined,
      })
      return res.data.data ?? []
    },
  })

  const filtered = data.filter((b) => {
    if (!search) return true
    const q = search.toLowerCase()
    return (
      b.patient_name?.toLowerCase().includes(q) ||
      b.physio_name?.toLowerCase().includes(q) ||
      String(b.id).includes(q)
    )
  })

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Bookings</h1>
        <p className="text-sm text-gray-500">All platform bookings</p>
      </div>

      {/* Filters */}
      <div className="flex gap-3 mb-5">
        <div className="relative flex-1 max-w-xs">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search patient, physio, ID…"
            className="w-full pl-9 pr-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="rounded-lg border border-gray-300 text-sm px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-500"
        >
          <option value="">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="confirmed">Confirmed</option>
          <option value="in_progress">In Progress</option>
          <option value="completed">Completed</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </div>

      {isLoading ? (
        <Loader />
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['#', 'Patient', 'Physiotherapist', 'Type', 'Date & Time', 'Status', 'Payment', 'Amount'].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-4 py-10 text-center text-gray-400">
                    No bookings found
                  </td>
                </tr>
              ) : (
                filtered.map((b) => (
                  <tr key={b.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3 font-medium text-gray-500">#{b.id}</td>
                    <td className="px-4 py-3 font-medium text-gray-900">{b.patient_name}</td>
                    <td className="px-4 py-3 text-gray-700">{b.physio_name}</td>
                    <td className="px-4 py-3 text-gray-500">{b.booking_type.replaceAll('_', ' ')}</td>
                    <td className="px-4 py-3 text-gray-500">
                      <div className="flex items-center gap-1">
                        <Calendar size={13} />
                        {b.scheduled_date} {b.scheduled_time.substring(0, 5)}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={clsx('px-2 py-1 rounded-full text-xs font-semibold', STATUS_COLORS[b.status] ?? 'bg-gray-100 text-gray-600')}>
                        {b.status.replaceAll('_', ' ')}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={clsx('px-2 py-1 rounded-full text-xs font-semibold',
                        b.payment_status === 'paid' ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'
                      )}>
                        {b.payment_status}
                      </span>
                    </td>
                    <td className="px-4 py-3 font-semibold text-gray-900">
                      ₹{b.total_amount.toFixed(0)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
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
