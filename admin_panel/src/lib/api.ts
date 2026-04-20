import axios from 'axios'
import { useAuthStore } from '../store/authStore'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? 'https://api.physioconnect.in/api/v1',
  headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (r) => r,
  (err) => {
    const msg = err.response?.data?.message ?? 'Something went wrong.'
    if (err.response?.status === 401) useAuthStore.getState().clearSession()
    return Promise.reject(new Error(msg))
  }
)
