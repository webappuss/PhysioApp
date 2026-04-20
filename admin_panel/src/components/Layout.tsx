import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { useAuthStore } from '../store/authStore'
import {
  LayoutDashboard, ShieldCheck, CalendarDays,
  Users, TrendingUp, LogOut, Activity,
} from 'lucide-react'
import clsx from 'clsx'

const NAV = [
  { to: '/dashboard',    label: 'Dashboard',    icon: LayoutDashboard },
  { to: '/verification', label: 'Verification',  icon: ShieldCheck },
  { to: '/bookings',     label: 'Bookings',      icon: CalendarDays },
  { to: '/users',        label: 'Users',         icon: Users },
  { to: '/revenue',      label: 'Revenue',       icon: TrendingUp },
]

export default function Layout() {
  const { admin, clearSession } = useAuthStore()
  const navigate = useNavigate()

  function logout() {
    clearSession()
    navigate('/login')
  }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className="w-60 bg-white border-r border-gray-200 flex flex-col">
        <div className="h-16 flex items-center gap-2 px-5 border-b border-gray-200">
          <Activity className="text-brand-500" size={22} />
          <span className="text-lg font-bold text-gray-900">PhysioConnect</span>
        </div>

        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              className={({ isActive }) => clsx(
                'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                isActive
                  ? 'bg-brand-50 text-brand-600'
                  : 'text-gray-600 hover:bg-gray-100'
              )}
            >
              <Icon size={18} />
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-gray-200">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-8 h-8 rounded-full bg-brand-500 flex items-center justify-center text-white text-sm font-bold">
              {admin?.name?.[0]?.toUpperCase() ?? 'A'}
            </div>
            <div className="min-w-0">
              <p className="text-sm font-medium text-gray-900 truncate">{admin?.name ?? 'Admin'}</p>
              <p className="text-xs text-gray-500 truncate">{admin?.email ?? ''}</p>
            </div>
          </div>
          <button
            onClick={logout}
            className="flex items-center gap-2 w-full px-3 py-2 rounded-lg text-sm text-red-600 hover:bg-red-50 transition-colors"
          >
            <LogOut size={16} />
            Logout
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-auto">
        <Outlet />
      </main>
    </div>
  )
}
