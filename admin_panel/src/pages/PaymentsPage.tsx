import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import { Search, CreditCard, TrendingUp, CheckCircle, XCircle } from 'lucide-react'
import clsx from 'clsx'

interface Payment {
  id: number
  uuid: string
  patient_name: string
  physio_name: string
  booking_id: number | null
  amount: number
  platform_fee: number
  razorpay_payment_id: string | null
  payment_method: string | null
  status: string
  created_at: string
  captured_at: string | null
}

const STATUS_COLORS: Record<string, string> = {
  captured:  'bg-green-100 text-green-700',
  pending:   'bg-amber-100 text-amber-700',
  failed:    'bg-red-100 text-red-700',
  refunded:  'bg-blue-100 text-blue-700',
}

const METHOD_LABELS: Record<string, string> = {
  upi:         'UPI',
  card:        'Card',
  netbanking:  'Net Banking',
  wallet:      'Wallet',
}

function fmt(amount: number) {
  return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(amount / 100)
}

function fmtDate(dt: string) {
  return new Date(dt).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
}

export default function PaymentsPage() {
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')

  const { data = [], isLoading } = useQuery<Payment[]>({
    queryKey: ['admin-payments', statusFilter],
    queryFn: async () => {
      const res = await api.get('/admin/payments', {
        params: statusFilter ? { status: statusFilter } : undefined,
      })
      return res.data.data ?? []
    },
  })

  const filtered = data.filter((p) => {
    if (!search) return true
    const q = search.toLowerCase()
    return (
      p.patient_name?.toLowerCase().includes(q) ||
      p.physio_name?.toLowerCase().includes(q) ||
      p.razorpay_payment_id?.toLowerCase().includes(q) ||
      String(p.id).includes(q)
    )
  })

  // Summary stats
  const captured  = data.filter((p) => p.status === 'captured')
  const totalRev  = captured.reduce((s, p) => s + p.amount, 0)
  const totalFees = captured.reduce((s, p) => s + p.platform_fee, 0)

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Payments</h1>
        <p className="text-sm text-gray-500 mt-1">All payment transactions</p>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <SummaryCard
          icon={<TrendingUp className="w-5 h-5 text-green-600" />}
          label="Total Revenue"
          value={fmt(totalRev)}
          bg="bg-green-50"
        />
        <SummaryCard
          icon={<CreditCard className="w-5 h-5 text-indigo-600" />}
          label="Platform Fees Collected"
          value={fmt(totalFees)}
          bg="bg-indigo-50"
        />
        <SummaryCard
          icon={<CheckCircle className="w-5 h-5 text-blue-600" />}
          label="Successful Transactions"
          value={String(captured.length)}
          bg="bg-blue-50"
        />
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            className="w-full pl-9 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            placeholder="Search by patient, physio, payment ID…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <select
          className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="">All statuses</option>
          <option value="captured">Captured</option>
          <option value="pending">Pending</option>
          <option value="failed">Failed</option>
          <option value="refunded">Refunded</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden border border-gray-100">
        {isLoading ? (
          <div className="p-10 text-center text-gray-400">Loading payments…</div>
        ) : filtered.length === 0 ? (
          <div className="p-10 text-center">
            <XCircle className="w-10 h-10 text-gray-300 mx-auto mb-3" />
            <p className="text-gray-500">No payments found</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  {['#ID', 'Patient', 'Physio', 'Amount', 'Fee', 'Method', 'Status', 'Date'].map((h) => (
                    <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map((payment) => (
                  <tr key={payment.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">#{payment.id}</td>
                    <td className="px-4 py-3 font-medium text-gray-900">{payment.patient_name ?? '—'}</td>
                    <td className="px-4 py-3 text-gray-600">{payment.physio_name ?? '—'}</td>
                    <td className="px-4 py-3 font-semibold">{fmt(payment.amount)}</td>
                    <td className="px-4 py-3 text-gray-500">{fmt(payment.platform_fee)}</td>
                    <td className="px-4 py-3 text-gray-500">
                      {payment.payment_method ? (METHOD_LABELS[payment.payment_method] ?? payment.payment_method) : '—'}
                    </td>
                    <td className="px-4 py-3">
                      <span className={clsx('px-2 py-1 rounded-full text-xs font-semibold', STATUS_COLORS[payment.status] ?? 'bg-gray-100 text-gray-600')}>
                        {payment.status.toUpperCase()}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                      {payment.captured_at ? fmtDate(payment.captured_at) : fmtDate(payment.created_at)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}

function SummaryCard({ icon, label, value, bg }: { icon: React.ReactNode; label: string; value: string; bg: string }) {
  return (
    <div className={clsx('rounded-xl p-4 flex items-center gap-4', bg)}>
      <div className="p-2 bg-white rounded-lg shadow-sm">{icon}</div>
      <div>
        <p className="text-xs text-gray-500 font-medium">{label}</p>
        <p className="text-xl font-bold text-gray-900 mt-0.5">{value}</p>
      </div>
    </div>
  )
}
