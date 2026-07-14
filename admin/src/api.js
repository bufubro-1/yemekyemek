import { messages } from './messages'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/v1'
const TOKEN_KEY = 'yemekyemek_admin_token'
export const UNAUTHORIZED_EVENT = 'yemekyemek:unauthorized'

export const tokenStore = {
  get: () => localStorage.getItem(TOKEN_KEY),
  set: (token) => localStorage.setItem(TOKEN_KEY, token),
  clear: () => localStorage.removeItem(TOKEN_KEY),
}

async function request(path, options = {}) {
  const token = tokenStore.get()
  const headers = new Headers(options.headers)

  if (options.body && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json')
  }
  if (token) {
    headers.set('Authorization', `Bearer ${token}`)
  }

  const response = await fetch(`${API_URL}${path}`, { ...options, headers })
  const contentType = response.headers.get('content-type') || ''
  const payload = contentType.includes('application/json')
    ? await response.json()
    : await response.text()

  if (!response.ok) {
    if (response.status === 401 && path !== '/auth/login') {
      tokenStore.clear()
      window.dispatchEvent(new Event(UNAUTHORIZED_EVENT))
    }
    const error = new Error(
      payload?.message || payload?.error || messages.apiError,
    )
    error.status = response.status
    throw error
  }

  return payload
}

function queryString(params) {
  const query = new URLSearchParams()
  Object.entries(params).forEach(([key, value]) => {
    if (value !== '' && value !== null && value !== undefined) {
      query.set(key, value)
    }
  })
  return query.toString()
}

export const api = {
  login: (credentials) =>
    request('/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    }),
  verifyToken: () => request('/auth/verify-token'),
  overview: () => request('/admin/overview'),
  users: (params) => request(`/admin/users?${queryString(params)}`),
  updateUser: (id, changes) =>
    request(`/admin/users/${encodeURIComponent(id)}`, {
      method: 'PATCH',
      body: JSON.stringify(changes),
    }),
  resetPassword: (id, password) =>
    request(`/admin/users/${encodeURIComponent(id)}/password`, {
      method: 'PATCH',
      body: JSON.stringify({ password }),
    }),
  deleteUser: (id) =>
    request(`/admin/users/${encodeURIComponent(id)}`, { method: 'DELETE' }),
  tables: () => request('/admin/tables'),
  tableRows: (name, params) =>
    request(`/admin/tables/${encodeURIComponent(name)}?${queryString(params)}`),
  updateTableRow: (name, primaryKey, changes) =>
    request(`/admin/tables/${encodeURIComponent(name)}/rows`, {
      method: 'PATCH',
      body: JSON.stringify({ primaryKey, changes }),
    }),
  deleteTableRow: (name, primaryKey) =>
    request(`/admin/tables/${encodeURIComponent(name)}/rows`, {
      method: 'DELETE',
      body: JSON.stringify({ primaryKey }),
    }),
}

export function getData(payload, fallback = []) {
  return payload?.data ?? payload?.rows ?? payload?.users ?? payload?.tables ?? fallback
}

export function getPagination(payload, fallbackCount = 0) {
  const source = payload?.pagination ?? payload?.meta ?? payload ?? {}
  const total = Number(source.total ?? source.totalCount ?? source.count ?? fallbackCount)
  const page = Number(source.page ?? source.currentPage ?? 1)
  const pageSize = Number(source.pageSize ?? source.limit ?? 10)
  const totalPages = Number(source.totalPages ?? Math.max(1, Math.ceil(total / pageSize)))
  return { total, page, pageSize, totalPages }
}
