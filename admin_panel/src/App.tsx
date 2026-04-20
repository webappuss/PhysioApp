import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from './store/authStore'
import LoginPage from './pages/LoginPage'
import Layout from './components/Layout'
import DashboardPage from './pages/DashboardPage'
import VerificationQueuePage from './pages/VerificationQueuePage'
import BookingsPage from './pages/BookingsPage'
import UsersPage from './pages/UsersPage'
import RevenueAnalyticsPage from './pages/RevenueAnalyticsPage'

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const token = useAuthStore((s) => s.token)
  return token ? <>{children}</> : <Navigate to="/login" replace />
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/"
          element={
            <PrivateRoute>
              <Layout />
            </PrivateRoute>
          }
        >
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard"    element={<DashboardPage />} />
          <Route path="verification" element={<VerificationQueuePage />} />
          <Route path="bookings"     element={<BookingsPage />} />
          <Route path="users"        element={<UsersPage />} />
          <Route path="revenue"      element={<RevenueAnalyticsPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
