import { createContext, useCallback, useContext, useEffect, useState } from 'react'
import {
  Navigate,
  NavLink,
  Outlet,
  Route,
  Routes,
  useLocation,
  useNavigate,
  useParams,
} from 'react-router-dom'
import { api, getData, getPagination, tokenStore, UNAUTHORIZED_EVENT } from './api'
import { messages, roleLabels } from './messages'
import './App.css'

const AuthContext = createContext(null)
const USER_KEY = 'yemekyemek_admin_user'
const PAGE_SIZE = 10
const HIDDEN_COLUMNS = new Set(['password_hash'])

function readStoredUser() {
  try {
    return JSON.parse(localStorage.getItem(USER_KEY))
  } catch {
    return null
  }
}

function isAdmin(user) {
  return user?.role === 'admin'
}

function AuthProvider({ children }) {
  const [user, setUser] = useState(readStoredUser)
  const [checking, setChecking] = useState(Boolean(tokenStore.get()))

  const clearSession = useCallback(() => {
    tokenStore.clear()
    localStorage.removeItem(USER_KEY)
    setUser(null)
  }, [])

  useEffect(() => {
    window.addEventListener(UNAUTHORIZED_EVENT, clearSession)
    return () => window.removeEventListener(UNAUTHORIZED_EVENT, clearSession)
  }, [clearSession])

  useEffect(() => {
    if (!tokenStore.get()) {
      setChecking(false)
      return
    }

    api
      .verifyToken()
      .then((response) => {
        const verifiedUser = response?.user ?? response?.data?.user ?? response?.data
        const nextUser = verifiedUser?.role ? verifiedUser : readStoredUser()
        if (!isAdmin(nextUser)) {
          clearSession()
        } else {
          setUser(nextUser)
          localStorage.setItem(USER_KEY, JSON.stringify(nextUser))
        }
      })
      .catch(clearSession)
      .finally(() => setChecking(false))
  }, [clearSession])

  const login = async (credentials) => {
    const response = await api.login(credentials)
    const token = response?.token ?? response?.data?.token
    const loginUser = response?.user ?? response?.data?.user

    if (!token || !isAdmin(loginUser)) {
      clearSession()
      throw new Error(messages.adminRequired)
    }

    tokenStore.set(token)
    localStorage.setItem(USER_KEY, JSON.stringify(loginUser))
    setUser(loginUser)
  }

  return (
    <AuthContext.Provider value={{ user, checking, login, logout: clearSession }}>
      {children}
    </AuthContext.Provider>
  )
}

function useAuth() {
  return useContext(AuthContext)
}

function LoadingScreen() {
  return (
    <div className="screen-center">
      <span className="spinner" aria-hidden="true" />
      <p>{messages.loading}</p>
    </div>
  )
}

function ProtectedRoute() {
  const { user, checking } = useAuth()
  const location = useLocation()

  if (checking) return <LoadingScreen />
  if (!isAdmin(user)) {
    return <Navigate to="/giris" replace state={{ from: location }} />
  }
  return <Outlet />
}

function LoginPage() {
  const { user, login } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [form, setForm] = useState({ email: '', password: '' })
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  if (isAdmin(user)) return <Navigate to="/" replace />

  const submit = async (event) => {
    event.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      await login(form)
      navigate(location.state?.from?.pathname || '/', { replace: true })
    } catch (requestError) {
      setError(requestError.message || messages.invalidLogin)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <main className="login-page">
      <section className="login-card">
        <div className="brand brand-login">
          <span className="brand-mark">{messages.appShortName}</span>
          <span>{messages.appName}</span>
        </div>
        <h1>{messages.loginTitle}</h1>
        <p className="muted">{messages.loginSubtitle}</p>
        {error && <Alert type="error">{error}</Alert>}
        <form onSubmit={submit} className="form-stack">
          <label>
            <span>{messages.email}</span>
            <input
              type="email"
              autoComplete="email"
              required
              value={form.email}
              onChange={(event) => setForm({ ...form, email: event.target.value })}
            />
          </label>
          <label>
            <span>{messages.password}</span>
            <input
              type="password"
              autoComplete="current-password"
              required
              value={form.password}
              onChange={(event) => setForm({ ...form, password: event.target.value })}
            />
          </label>
          <button className="button primary full" disabled={submitting}>
            {submitting ? messages.loggingIn : messages.login}
          </button>
        </form>
      </section>
    </main>
  )
}

function Layout() {
  const { user, logout } = useAuth()
  const [menuOpen, setMenuOpen] = useState(false)

  return (
    <div className="app-shell">
      <aside className={`sidebar ${menuOpen ? 'open' : ''}`}>
        <div className="brand">
          <span className="brand-mark">{messages.appShortName}</span>
          <span>{messages.appName}</span>
        </div>
        <nav onClick={() => setMenuOpen(false)}>
          <NavLink to="/" end>⌂ <span>{messages.dashboard}</span></NavLink>
          <NavLink to="/kullanicilar">♙ <span>{messages.users}</span></NavLink>
          <NavLink to="/veritabani">▦ <span>{messages.database}</span></NavLink>
        </nav>
        <div className="sidebar-user">
          <strong>{user?.name || user?.email || messages.unknownUser}</strong>
          <small>{roleLabels[user?.role] || user?.role}</small>
          <button className="button ghost" onClick={logout}>{messages.logout}</button>
        </div>
      </aside>
      {menuOpen && <button className="backdrop" aria-label={messages.close} onClick={() => setMenuOpen(false)} />}
      <section className="main-area">
        <header className="mobile-header">
          <button className="icon-button" aria-label={messages.menu} onClick={() => setMenuOpen(true)}>☰</button>
          <strong>{messages.appName}</strong>
        </header>
        <Outlet />
      </section>
    </div>
  )
}

function PageHeader({ title, subtitle, actions }) {
  return (
    <div className="page-header">
      <div>
        <h1>{title}</h1>
        <p>{subtitle}</p>
      </div>
      {actions}
    </div>
  )
}

function Alert({ type = 'info', children }) {
  return <div className={`alert ${type}`} role="alert">{children}</div>
}

function ErrorState({ error, retry }) {
  return (
    <div className="state-card">
      <Alert type="error">{error || messages.loadError}</Alert>
      {retry && <button className="button secondary" onClick={retry}>{messages.retry}</button>}
    </div>
  )
}

function DashboardPage() {
  const [state, setState] = useState({ loading: true, error: '', rows: [] })

  const load = useCallback(async () => {
    setState((current) => ({ ...current, loading: true, error: '' }))
    try {
      const response = await api.overview()
      const raw = response?.data ?? response?.overview ?? response
      const rows = Array.isArray(raw)
        ? raw.map((item) => ({
            name: item.name ?? item.tableName ?? item.table,
            count: item.count ?? item.rowCount ?? item.total ?? 0,
          }))
        : Object.entries(raw || {})
            .filter(([, value]) => typeof value === 'number' || typeof value === 'object')
            .map(([name, value]) => ({
              name,
              count: typeof value === 'number'
                ? value
                : value?.count ?? value?.rowCount ?? value?.total ?? 0,
            }))
      setState({ loading: false, error: '', rows })
    } catch (error) {
      setState({ loading: false, error: error.message, rows: [] })
    }
  }, [])

  useEffect(() => { load() }, [load])

  return (
    <main className="page">
      <PageHeader title={messages.dashboard} subtitle={messages.dashboardSubtitle} />
      {state.loading ? <LoadingScreen /> : state.error ? (
        <ErrorState error={state.error} retry={load} />
      ) : (
        <>
          <div className="stat-grid">
            {state.rows.slice(0, 4).map((row) => (
              <article className="stat-card" key={row.name}>
                <span>{row.name}</span>
                <strong>{Number(row.count).toLocaleString('tr-TR')}</strong>
              </article>
            ))}
          </div>
          <div className="card table-card">
            <table>
              <thead><tr><th>{messages.table}</th><th>{messages.rowCount}</th></tr></thead>
              <tbody>
                {state.rows.map((row) => (
                  <tr key={row.name}>
                    <td><code>{row.name}</code></td>
                    <td>{Number(row.count).toLocaleString('tr-TR')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!state.rows.length && <EmptyState text={messages.noData} />}
          </div>
        </>
      )}
    </main>
  )
}

function UsersPage() {
  const [users, setUsers] = useState([])
  const [pagination, setPagination] = useState({ page: 1, totalPages: 1, total: 0 })
  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [passwordUser, setPasswordUser] = useState(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const response = await api.users({ page, pageSize: PAGE_SIZE, search })
      const rows = getData(response)
      setUsers(Array.isArray(rows) ? rows : [])
      setPagination(getPagination(response, rows.length))
    } catch (requestError) {
      setError(requestError.message)
    } finally {
      setLoading(false)
    }
  }, [page, search])

  useEffect(() => { load() }, [load])

  const perform = async (action, successMessage) => {
    setError('')
    setNotice('')
    try {
      await action()
      setNotice(successMessage)
      await load()
      return true
    } catch (requestError) {
      setError(requestError.message)
      return false
    }
  }

  const updateRole = (user, role) =>
    perform(() => api.updateUser(user.id, { role }), messages.roleUpdated)

  const deleteUser = async (user) => {
    if (!window.confirm(`${messages.deleteUserTitle}\n${messages.deleteUserText}`)) return
    await perform(() => api.deleteUser(user.id), messages.userDeleted)
  }

  const submitSearch = (event) => {
    event.preventDefault()
    setPage(1)
    setSearch(searchInput.trim())
  }

  return (
    <main className="page">
      <PageHeader title={messages.users} subtitle={messages.usersSubtitle} />
      <form className="toolbar" onSubmit={submitSearch}>
        <input
          type="search"
          placeholder={messages.searchUsers}
          value={searchInput}
          onChange={(event) => setSearchInput(event.target.value)}
        />
        <button className="button primary">{messages.search}</button>
      </form>
      {error && <Alert type="error">{error}</Alert>}
      {notice && <Alert type="success">{notice}</Alert>}
      <div className="card table-card">
        {loading ? <LoadingScreen /> : (
          <>
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>{messages.name}</th>
                    <th>{messages.email}</th>
                    <th>{messages.role}</th>
                    <th>{messages.createdAt}</th>
                    <th>{messages.actions}</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user) => (
                    <tr key={user.id}>
                      <td>{user.name || user.full_name || '—'}</td>
                      <td>{user.email}</td>
                      <td>
                        <select
                          value={user.role}
                          aria-label={messages.role}
                          onChange={(event) => updateRole(user, event.target.value)}
                        >
                          {Object.entries(roleLabels).map(([value, label]) => (
                            <option key={value} value={value}>{label}</option>
                          ))}
                        </select>
                      </td>
                      <td>{formatValue(user.created_at ?? user.createdAt)}</td>
                      <td>
                        <div className="row-actions">
                          <button className="button small secondary" onClick={() => setPasswordUser(user)}>
                            {messages.resetPassword}
                          </button>
                          <button className="button small danger" onClick={() => deleteUser(user)}>
                            {messages.delete}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {!users.length && <EmptyState text={messages.noData} />}
            <Pagination pagination={pagination} page={page} setPage={setPage} />
          </>
        )}
      </div>
      {passwordUser && (
        <PasswordModal
          user={passwordUser}
          onClose={() => setPasswordUser(null)}
          onSave={async (password) => {
            const successful = await perform(
              () => api.resetPassword(passwordUser.id, password),
              messages.passwordReset,
            )
            if (successful) setPasswordUser(null)
          }}
        />
      )}
    </main>
  )
}

function PasswordModal({ user, onClose, onSave }) {
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)

  const submit = async (event) => {
    event.preventDefault()
    if (password.length < 8) {
      setError(messages.passwordTooShort)
      return
    }
    setSaving(true)
    await onSave(password)
    setSaving(false)
  }

  return (
    <Modal title={`${messages.resetPassword} · ${user.email}`} onClose={onClose}>
      <form onSubmit={submit} className="form-stack">
        {error && <Alert type="error">{error}</Alert>}
        <label>
          <span>{messages.newPassword}</span>
          <input
            type="password"
            autoFocus
            autoComplete="new-password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
          />
          <small>{messages.passwordHint}</small>
        </label>
        <ModalActions onClose={onClose} saving={saving} />
      </form>
    </Modal>
  )
}

function DatabasePage() {
  const navigate = useNavigate()
  const { tableName } = useParams()
  const [tables, setTables] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const response = await api.tables()
      const raw = getData(response)
      setTables((Array.isArray(raw) ? raw : []).map((table) =>
        typeof table === 'string' ? { name: table } : {
          ...table,
          name: table.name ?? table.tableName ?? table.table_name,
        },
      ))
    } catch (requestError) {
      setError(requestError.message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  return (
    <main className="page">
      <PageHeader title={messages.database} subtitle={messages.databaseSubtitle} />
      {error && <Alert type="error">{error}</Alert>}
      <div className="database-layout">
        <aside className="card table-list">
          {loading ? <LoadingScreen /> : tables.length ? tables.map((table) => (
            <button
              key={table.name}
              className={tableName === table.name ? 'active' : ''}
              onClick={() => navigate(`/veritabani/${encodeURIComponent(table.name)}`)}
            >
              <code>{table.name}</code>
              {table.rowCount !== undefined && <span>{table.rowCount}</span>}
            </button>
          )) : <EmptyState text={messages.noTables} />}
        </aside>
        <section className="database-content">
          {tableName ? <TableExplorer key={tableName} tableName={tableName} /> : (
            <div className="card select-table"><EmptyState text={messages.selectTable} /></div>
          )}
        </section>
      </div>
    </main>
  )
}

function TableExplorer({ tableName }) {
  const [rows, setRows] = useState([])
  const [columns, setColumns] = useState([])
  const [primaryKeys, setPrimaryKeys] = useState([])
  const [pagination, setPagination] = useState({ page: 1, totalPages: 1, total: 0 })
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [editingRow, setEditingRow] = useState(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const response = await api.tableRows(tableName, { page, pageSize: PAGE_SIZE })
      const data = getData(response)
      const safeRows = Array.isArray(data) ? data : []
      const rawColumns = response?.columns ?? response?.table?.columns ?? response?.data?.columns
      const columnNames = Array.isArray(rawColumns)
        ? rawColumns.map((column) => typeof column === 'string' ? column : column.name ?? column.column_name)
        : Object.keys(safeRows[0] || {})
      const metadataKeys = Array.isArray(rawColumns)
        ? rawColumns
            .filter((column) => typeof column === 'object' && (column.primaryKey || column.isPrimaryKey))
            .map((column) => column.name ?? column.column_name)
        : []
      const keys = response?.primaryKeys
        ?? response?.primaryKeyColumns
        ?? response?.primaryKey
        ?? response?.table?.primaryKey
        ?? response?.data?.primaryKeys
        ?? metadataKeys
      setRows(safeRows)
      setColumns(columnNames.filter((column) => column && !HIDDEN_COLUMNS.has(column)))
      setPrimaryKeys(Array.isArray(keys) ? keys : keys ? [keys] : (columnNames.includes('id') ? ['id'] : []))
      setPagination(getPagination(response, safeRows.length))
    } catch (requestError) {
      setError(requestError.message)
    } finally {
      setLoading(false)
    }
  }, [page, tableName])

  useEffect(() => {
    setPage(1)
  }, [tableName])
  useEffect(() => { load() }, [load])

  const primaryKeyFor = (row) => Object.fromEntries(
    primaryKeys.filter((key) => Object.hasOwn(row, key)).map((key) => [key, row[key]]),
  )

  const perform = async (action, successMessage) => {
    setError('')
    setNotice('')
    try {
      await action()
      setNotice(successMessage)
      await load()
      return true
    } catch (requestError) {
      setError(requestError.message)
      return false
    }
  }

  const deleteRow = async (row) => {
    const primaryKey = primaryKeyFor(row)
    if (!Object.keys(primaryKey).length) {
      setError(messages.primaryKeyMissing)
      return
    }
    if (!window.confirm(`${messages.deleteRowTitle}\n${messages.deleteRowText}`)) return
    await perform(() => api.deleteTableRow(tableName, primaryKey), messages.rowDeleted)
  }

  return (
    <>
      <div className="subpage-title">
        <div><span>{messages.table}</span><h2>{tableName}</h2></div>
        <span className="badge">{pagination.total} {messages.rowCount.toLocaleLowerCase('tr-TR')}</span>
      </div>
      {error && <Alert type="error">{error}</Alert>}
      {notice && <Alert type="success">{notice}</Alert>}
      <div className="card table-card">
        {loading ? <LoadingScreen /> : (
          <>
            <div className="table-scroll wide">
              <table>
                <thead>
                  <tr>
                    {columns.map((column) => <th key={column}>{column}</th>)}
                    <th className="sticky-actions">{messages.actions}</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((row, index) => (
                    <tr key={JSON.stringify(primaryKeyFor(row)) || index}>
                      {columns.map((column) => <td key={column}>{formatValue(row[column])}</td>)}
                      <td className="sticky-actions">
                        <div className="row-actions">
                          <button className="button small secondary" onClick={() => setEditingRow(row)}>
                            {messages.edit}
                          </button>
                          <button className="button small danger" onClick={() => deleteRow(row)}>
                            {messages.delete}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {!rows.length && <EmptyState text={messages.noData} />}
            <Pagination pagination={pagination} page={page} setPage={setPage} />
          </>
        )}
      </div>
      {editingRow && (
        <RowEditModal
          row={editingRow}
          columns={columns}
          primaryKeys={primaryKeys}
          onClose={() => setEditingRow(null)}
          onSave={async (changes) => {
            const primaryKey = primaryKeyFor(editingRow)
            if (!Object.keys(primaryKey).length) {
              setError(messages.primaryKeyMissing)
              return
            }
            const successful = await perform(
              () => api.updateTableRow(tableName, primaryKey, changes),
              messages.rowUpdated,
            )
            if (successful) setEditingRow(null)
          }}
        />
      )}
    </>
  )
}

function RowEditModal({ row, columns, primaryKeys, onClose, onSave }) {
  const editableColumns = columns.filter((column) => !primaryKeys.includes(column))
  const [values, setValues] = useState(() => Object.fromEntries(
    editableColumns.map((column) => [column, inputValue(row[column])]),
  ))
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)

  const submit = async (event) => {
    event.preventDefault()
    if (!editableColumns.length) {
      setError(messages.noEditableFields)
      return
    }
    try {
      const changes = Object.fromEntries(editableColumns.map((column) => [
        column,
        parseInputValue(values[column], row[column]),
      ]))
      setSaving(true)
      await onSave(changes)
    } catch (parseError) {
      setError(parseError.message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal title={messages.editRow} onClose={onClose} wide>
      <form onSubmit={submit} className="form-stack edit-grid">
        {error && <Alert type="error">{error}</Alert>}
        {editableColumns.map((column) => (
          <label key={column}>
            <span>{column}</span>
            {typeof row[column] === 'boolean' ? (
              <select
                value={values[column]}
                onChange={(event) => setValues({ ...values, [column]: event.target.value })}
              >
                <option value="true">{messages.trueValue}</option>
                <option value="false">{messages.falseValue}</option>
              </select>
            ) : (
              <textarea
                rows={typeof row[column] === 'object' ? 4 : 2}
                value={values[column]}
                onChange={(event) => setValues({ ...values, [column]: event.target.value })}
              />
            )}
          </label>
        ))}
        <ModalActions onClose={onClose} saving={saving} />
      </form>
    </Modal>
  )
}

function Modal({ title, onClose, children, wide = false }) {
  useEffect(() => {
    const close = (event) => event.key === 'Escape' && onClose()
    window.addEventListener('keydown', close)
    return () => window.removeEventListener('keydown', close)
  }, [onClose])

  return (
    <div className="modal-layer" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <section className={`modal ${wide ? 'wide' : ''}`} role="dialog" aria-modal="true" aria-label={title}>
        <header><h2>{title}</h2><button className="icon-button" aria-label={messages.close} onClick={onClose}>×</button></header>
        <div className="modal-body">{children}</div>
      </section>
    </div>
  )
}

function ModalActions({ onClose, saving }) {
  return (
    <div className="modal-actions">
      <button type="button" className="button secondary" onClick={onClose}>{messages.cancel}</button>
      <button className="button primary" disabled={saving}>{saving ? messages.saving : messages.save}</button>
    </div>
  )
}

function Pagination({ pagination, page, setPage }) {
  if (pagination.totalPages <= 1 && !pagination.total) return null
  return (
    <div className="pagination">
      <span>{messages.pageStatus(page, pagination.totalPages, pagination.total)}</span>
      <div>
        <button
          className="button small secondary"
          disabled={page <= 1}
          onClick={() => setPage((current) => current - 1)}
        >
          {messages.previous}
        </button>
        <button
          className="button small secondary"
          disabled={page >= pagination.totalPages}
          onClick={() => setPage((current) => current + 1)}
        >
          {messages.next}
        </button>
      </div>
    </div>
  )
}

function EmptyState({ text }) {
  return <div className="empty-state"><span>◇</span><p>{text}</p></div>
}

function inputValue(value) {
  if (value === null || value === undefined) return ''
  if (typeof value === 'object') return JSON.stringify(value, null, 2)
  return String(value)
}

function parseInputValue(value, original) {
  if (typeof original === 'number') {
    const number = Number(value)
    if (Number.isNaN(number)) throw new Error(messages.apiError)
    return number
  }
  if (typeof original === 'boolean') return value === 'true'
  if (typeof original === 'object' && original !== null) return JSON.parse(value)
  if (original === null && value === '') return null
  return value
}

function formatValue(value) {
  if (value === null || value === undefined) return <span className="null">{messages.nullValue}</span>
  if (typeof value === 'boolean') return value ? messages.trueValue : messages.falseValue
  if (typeof value === 'object') return <code title={JSON.stringify(value)}>{JSON.stringify(value)}</code>
  const text = String(value)
  if (/^\d{4}-\d{2}-\d{2}T/.test(text)) {
    const date = new Date(text)
    if (!Number.isNaN(date.getTime())) return date.toLocaleString('tr-TR')
  }
  return <span title={text}>{text.length > 80 ? `${text.slice(0, 77)}…` : text}</span>
}

function App() {
  return (
    <AuthProvider>
      <Routes>
        <Route path="/giris" element={<LoginPage />} />
        <Route element={<ProtectedRoute />}>
          <Route element={<Layout />}>
            <Route index element={<DashboardPage />} />
            <Route path="/kullanicilar" element={<UsersPage />} />
            <Route path="/veritabani" element={<DatabasePage />} />
            <Route path="/veritabani/:tableName" element={<DatabasePage />} />
          </Route>
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AuthProvider>
  )
}

export default App
