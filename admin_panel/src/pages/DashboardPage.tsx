import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import { Users, CalendarDays, DollarSign, TrendingUp, Clock, CheckCircle } from 'lucide-react'
import clsx from 'clsx'

interface DashboardData {
  total_users: number
  total_physios: number
  total_patients: number
  total_bookings: number
  pending_bookings: number
  completed_bookings: number
  total_revenue: number
  month_revenue: number
  pending_verifications: number
}

function useDashboard() {
  return useQuery<DashboardData>({
    queryKey: ['admin-dashboard'],
    queryFn: async () => {
      const res = await api.get('/admin/dashboard')
      return res.data.data
    },
  })
}

export default function DashboardPage() {
  const { data, isLoading, error } = useDashboard()

  if (isLoading) return <PageLoader />
  if (error) return <ErrorMsg msg={error.message} />

  const stats = [
    { label: 'Total Users',    value: data!.total_users,    icon: Users,         color: 'blue' },
    { label: 'Physiotherapists', value: data!.total_physios, icon: Users,         color: 'teal' },
    { label: 'Total Bookings', value: data!.total_bookings, icon: CalendarDays,  color: 'purple' },
    { label: 'Pending Bookings', value: data!.pending_bookings, icon: Clock,      color: 'amber' },
    { label: 'Completed',      value: data!.completed_bookings, icon: CheckCircle, color: 'green' },
    { label: 'Pending Verifs', value: data!.pending_verifications, icon: TrendingUp, color: 'red' },
  ]

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-sm text-gray-500">Platform overview at a glance</p>
      </div>

      {/* Revenue cards */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="bg-gradient-to-br from-brand-500 to-brand-700 rounded-2xl p-5 text-white">
          <p className="text-sm text-blue-100 mb-1">Total Revenue</p>
          <p className="text-3xl font-bold">₹{(data!.total_revenue).toLocaleString('en-IN')}</p>
          <div className="flex items-center gap-1 mt-2 text-blue-100 text-sm">
            <DollarSign size={14} />
            All time
          </div>
        </div>
        <div className="bg-gradient-to-br from-teal-500 to-teal-600 rounded-2xl p-5 text-white">
          <p className="text-sm text-teal-100 mb-1">This Month</p>
          <p className="text-3xl font-bold">₹{(data!.month_revenue).toLocaleString('en-IN')}</p>
          <div className="flex items-center gap-1 mt-2 text-teal-100 text-sm">
            <TrendingUp size={14} />
            Current month
          </div>
        </div>
      </div>

      {/* Stats grid */}
      <div className="grid grid-cols-3 gap-4">
        {stats.map((s) => (
          <StatCard key={s.label} {...s} />
        ))}
      </div>
    </div>
  )
}

function StatCard({ label, value, icon: Icon, color }: {
  label: string; value: number; icon: React.ElementType; color: string
}) {
  const colors: Record<string, string> = {
    blue:   'bg-blue-50 text-blue-600',
    teal:   'bg-teal-50 text-teal-600',
    purple: 'bg-purple-50 text-purple-600',
    amber:  'bg-amber-50 text-amber-600',
    green:  'bg-green-50 text-green-600',
    red:    'bg-red-50 text-red-600',
  }

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className={clsx('w-9 h-9 rounded-lg flex items-center justify-center mb-3', colors[color])}>
        <Icon size={18} />
      </div>
      <p className="text-2xl font-bold text-gray-900">{value.toLocaleString()}</p>
      <p className="text-xs text-gray-500 mt-0.5">{label}</p>
    </div>
  )
}

function PageLoader() {
  return (
    <div className="flex items-center justify-center h-full">
      <div className="animate-spin w-8 h-8 border-2 border-brand-500 border-t-transparent rounded-full" />
    </div>
  )
}

function ErrorMsg({ msg }: { msg: string }) {
  return <div className="p-6 text-red-600">{msg}</div>
}
