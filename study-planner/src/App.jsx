import { useEffect, useState } from 'react'
import Analytics from './Analytics'
import Dashboard from './Dashboard'
import FocusMode from './FocusMode'
import Goals from './Goals'
import './index.css'
import Motivation from './Motivation'
import Notes from './Notes'
import Planner from './Planner'
import Sidebar from './Sidebar'
import StreakTracker from './StreakTracker'
import { ToastProvider } from './ToastContext'

// 🔥 NEW IMPORTS
import { onAuthStateChanged, signOut } from 'firebase/auth'
import AuthPage from './AuthPage'
import { auth } from './firebase/firebase'

function App() {
  // 🔐 USER STATE
  const [user, setUser] = useState(null)

  // YOUR EXISTING STATES
  const [page, setPage] = useState('dashboard')
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [focusMode, setFocusMode] = useState(false)

  // 🔥 CHECK LOGIN STATE
  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser)
    })
    return () => unsub()
  }, [])

  function handleNav(p) {
    if (p === 'focus') { setFocusMode(true); setSidebarOpen(false); return }
    setPage(p)
    setSidebarOpen(false)
  }

  const pages = {
    dashboard: <Dashboard onNav={handleNav} />,
    planner: <Planner />,
    notes: <Notes />,
    goals: <Goals />,
    analytics: <Analytics />,
    streak: <StreakTracker />,
    motivation: <Motivation />,
  }

  // 🔥 IF NOT LOGGED IN → SHOW LOGIN PAGE
  if (!user) {
    return <AuthPage />
  }

  // 🔥 FOCUS MODE (same as yours)
  if (focusMode) {
    return (
      <ToastProvider>
        <FocusMode onExit={() => setFocusMode(false)} />
      </ToastProvider>
    )
  }

  // 🔥 MAIN APP (same as yours + logout button)
  return (
    <ToastProvider>
      <div className="mobile-topbar">
        <button className="btn btn-icon btn-ghost" onClick={() => setSidebarOpen(o => !o)}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <line x1="3" y1="6" x2="21" y2="6"/>
            <line x1="3" y1="12" x2="21" y2="12"/>
            <line x1="3" y1="18" x2="21" y2="18"/>
          </svg>
        </button>

        <span style={{fontFamily:'DM Serif Display,serif',fontSize:'1.1rem'}}>
          StudyFlow
        </span>

        {/* 🔥 LOGOUT BUTTON */}
        <button 
          className="btn btn-primary btn-sm"
          onClick={() => signOut(auth)}
        >
          Logout
        </button>
      </div>

      <div className={`sidebar-overlay${sidebarOpen?' show':''}`} onClick={() => setSidebarOpen(false)} />

      <div className="app-layout">
        <Sidebar active={page} onNav={handleNav} open={sidebarOpen} />

        <main className="main-content">
          {pages[page] || pages.dashboard}
        </main>
      </div>
    </ToastProvider>
  )
}

export default App