import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import {
  AreaChart, Area, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from 'recharts'
import { TrendingUp, DollarSign, CreditCard, Percent } from 'lucide-react'

interface RevenueData {
  total_revenue: number
  total_transactions: number
  avg_transaction: number
  platform_fee_collected: number
  monthly: Array<{ month: string; revenue: number; transactions: number }>
  by_type: Array<{ type: string; revenue: number; count: number }>
}

export default function RevenueAnalyticsPage() {
  const { data, isLoading, error } = useQuery<RevenueData>({
    queryKey: ['revenue-analytics'],
    queryFn: async () => {
      const res = await api.get('/admin/analytics/revenue')
      return res.data.data
    },
  })

  if (isLoading) return <Loader />
  if (error) return <div className="p-6 text-red-600">{error.message}</div>
  if (!data) return null

  const kpis = [
    { label: 'Total Revenue',       value: `₹${data.total_revenue.toLocaleString('en-IN')}`, icon: TrendingUp,  color: 'blue' },
    { label: 'Total Transactions',  value: data.total_transactions.toLocaleString(),          icon: CreditCard,  color: 'teal' },
    { label: 'Avg Transaction',     value: `₹${data.avg_transaction.toFixed(0)}`,             icon: DollarSign,  color: 'purple' },
    { label: 'Platform Fees',       value: `₹${data.platform_fee_collected.toLocaleString('en-IN')}`, icon: Percent, color: 'green' },
  ]

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Revenue Analytics</h1>
        <p className="text-sm text-gray-500">Financial overview of the platform</p>
      </div>

      {/* KPI cards */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        {kpis.map((k) => (
          <KpiCard key={k.label} {...k} />
        ))}
      </div>

      {/* Monthly revenue chart */}
      <div className="grid grid-cols-5 gap-4">
        <div className="col-span-3 bg-white rounded-xl border border-gray-200 p-5">
          <h2 className="text-base font-semibold text-gray-900 mb-4">Monthly Revenue</h2>
          <ResponsiveContainer width="100%" height={260}>
            <AreaChart data={data.monthly}>
              <defs>
                <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#1A6FD4" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#1A6FD4" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}k`} />
              <Tooltip formatter={(v: number) => [`₹${v.toLocaleString('en-IN')}`, 'Revenue']} />
              <Area
                type="monotone"
                dataKey="revenue"
                stroke="#1A6FD4"
                strokeWidth={2}
                fill="url(#revenueGrad)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="col-span-2 bg-white rounded-xl border border-gray-200 p-5">
          <h2 className="text-base font-semibold text-gray-900 mb-4">Revenue by Type</h2>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={data.by_type} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" horizontal={false} />
              <XAxis type="number" tick={{ fontSize: 12 }} tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}k`} />
              <YAxis dataKey="type" type="category" tick={{ fontSize: 12 }} width={90}
                tickFormatter={(v) => v.replaceAll('_', ' ')} />
              <Tooltip formatter={(v: number) => [`₹${v.toLocaleString('en-IN')}`, 'Revenue']} />
              <Bar dataKey="revenue" fill="#00B4A6" radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Transactions trend */}
      <div className="mt-4 bg-white rounded-xl border border-gray-200 p-5">
        <h2 className="text-base font-semibold text-gray-900 mb-4">Monthly Transactions</h2>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={data.monthly}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="month" tick={{ fontSize: 12 }} />
            <YAxis tick={{ fontSize: 12 }} />
            <Tooltip />
            <Legend />
            <Bar dataKey="transactions" fill="#1A6FD4" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

function KpiCard({ label, value, icon: Icon, color }: {
  label: string; value: string; icon: React.ElementType; color: string
}) {
  const colors: Record<string, string> = {
    blue:   'bg-blue-50 text-blue-600',
    teal:   'bg-teal-50 text-teal-600',
    purple: 'bg-purple-50 text-purple-600',
    green:  'bg-green-50 text-green-600',
  }
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className={`w-9 h-9 rounded-lg flex items-center justify-center mb-3 ${colors[color]}`}>
        <Icon size={18} />
      </div>
      <p className="text-xl font-bold text-gray-900">{value}</p>
      <p className="text-xs text-gray-500 mt-0.5">{label}</p>
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
