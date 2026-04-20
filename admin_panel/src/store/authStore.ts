import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  token: string | null
  admin: { id: number; name: string; email: string } | null
  setSession: (token: string, admin: AuthState['admin']) => void
  clearSession: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      admin: null,
      setSession: (token, admin) => set({ token, admin }),
      clearSession: () => set({ token: null, admin: null }),
    }),
    { name: 'physio-admin-auth' }
  )
)
