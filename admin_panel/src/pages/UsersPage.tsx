import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import { Search, ShieldCheck, UserX } from 'lucide-react'
import clsx from 'clsx'

interface User {
  id: number
  name: string | null
  phone: string
  email: string | null
  role: string
  status: string
  created_at: string
}

export default function UsersPage() {
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('')

  const { data = [], isLoading } = useQuery<User[]>({
    queryKey: ['admin-users', roleFilter],
    queryFn: async () => {
      const res = await api.get('/admin/users', {
        params: roleFilter ? { role: roleFilter } : undefined,
      })
      return res.data.data ?? []
    },
  })

  const filtered = data.filter((u) => {
    if (!search) return true
    const q = search.toLowerCase()
    return (
      u.name?.toLowerCase().includes(q) ||
      u.phone.includes(q) ||
      u.email?.toLowerCase().includes(q)
    )
  })

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Users</h1>
        <p className="text-sm text-gray-500">All registered users</p>
      </div>

      <div className="flex gap-3 mb-5">
        <div className="relative flex-1 max-w-xs">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search name, phone, email…"
            className="w-full pl-9 pr-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="rounded-lg border border-gray-300 text-sm px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-500"
        >
          <option value="">All Roles</option>
          <option value="patient">Patient</option>
          <option value="physio">Physiotherapist</option>
          <option value="admin">Admin</option>
        </select>
      </div>

      {isLoading ? <Loader /> : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['#', 'Name', 'Phone', 'Email', 'Role', 'Status', 'Joined'].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.length === 0 ? (
                <tr><td colSpan={7} className="px-4 py-10 text-center text-gray-400">No users found</td></tr>
              ) : (
                filtered.map((u) => (
                  <tr key={u.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3 text-gray-500">{u.id}</td>
                    <td className="px-4 py-3 font-medium text-gray-900">{u.name ?? '—'}</td>
                    <td className="px-4 py-3 text-gray-700">{u.phone}</td>
                    <td className="px-4 py-3 text-gray-500">{u.email ?? '—'}</td>
                    <td className="px-4 py-3">
                      <RoleBadge role={u.role} />
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={u.status} />
                    </td>
                    <td className="px-4 py-3 text-gray-400 text-xs">
                      {new Date(u.created_at).toLocaleDateString('en-IN')}
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

function RoleBadge({ role }: { role: string }) {
  const styles: Record<string, string> = {
    patient: 'bg-blue-100 text-blue-700',
    physio:  'bg-teal-100 text-teal-700',
    admin:   'bg-purple-100 text-purple-700',
  }
  return (
    <span className={clsx('px-2 py-1 rounded-full text-xs font-semibold capitalize', styles[role] ?? 'bg-gray-100 text-gray-600')}>
      {role}
    </span>
  )
}

function StatusBadge({ status }: { status: string }) {
  const active = status === 'active'
  return (
    <span className={clsx('flex items-center gap-1 text-xs font-semibold w-fit px-2 py-1 rounded-full',
      active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
    )}>
      {active ? <ShieldCheck size={12} /> : <UserX size={12} />}
      {status}
    </span>
  )
}

function Loader() {
  return (
    <div className="flex items-center justify-center h-64">
      <div className="animate-spin w-8 h-8 border-2 border-brand-500 border-t-transparent rounded-full" />
    </div>
  )
}
