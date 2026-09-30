import { useStore } from './useStore'
import { sendPasswordResetEmail } from 'firebase/auth'
import { auth } from './firebase/firebase'
import { useToast } from './ToastContext'

const NAV = [
  { id: 'dashboard', label: 'Dashboard', icon: '⊞', section: 'main' },
  { id: 'planner', label: 'Study Planner', icon: '📅', section: 'main' },
  { id: 'notes', label: 'Notes', icon: '📝', section: 'main' },
  { id: 'goals', label: 'Goals', icon: '🎯', section: 'main' },
  { id: 'analytics', label: 'Analytics', icon: '📊', section: 'insights' },
  { id: 'streak', label: 'Streak Tracker', icon: '🔥', section: 'insights' },
  { id: 'focus', label: 'Focus Mode', icon: '🎧', section: 'tools' },
  { id: 'motivation', label: 'Motivation', icon: '✨', section: 'tools' },
]

export default function Sidebar({ active, onNav, open, user }) {
  const { getStreak } = useStore()
  const toast = useToast()
  const streak = getStreak()
  const email = user?.email || ''
  const displayName = user?.displayName || email.split('@')[0] || 'Student'

  async function handlePasswordReset() {
    if (!email) {
      toast('This account has no email address for password recovery.', 'error')
      return
    }

    try {
      await sendPasswordResetEmail(auth, email)
      toast(`Password reset email sent to ${email}.`, 'success')
    } catch (error) {
      console.error('Password reset email failed:', error)
      toast('Could not send the password reset email. Please try again.', 'error')
    }
  }

  const sections = [
    { key: 'main', label: 'Study' },
    { key: 'insights', label: 'Insights' },
    { key: 'tools', label: 'Tools' },
    { key: 'user', label: 'User' },
  ]

  return (
    <aside className={`sidebar${open ? ' open' : ''}`}>
      <div className="sidebar-logo">
        <div className="sidebar-logo-icon">🌿</div>
        <span className="sidebar-logo-text">StudyFlow</span>
      </div>

      <nav className="sidebar-nav">
        {sections.map(section => (
          <div key={section.key}>
            <div className="nav-section-label">{section.label}</div>
            {section.key === 'user' ? (
              <div className="sidebar-user">
                <div className="sidebar-user-identity">
                  <div className="sidebar-user-avatar" aria-hidden="true">
                    {displayName.charAt(0).toUpperCase()}
                  </div>
                  <div className="sidebar-user-details">
                    <div className="sidebar-user-name" title={displayName}>{displayName}</div>
                    <div className="sidebar-user-email" title={email}>{email || 'Email unavailable'}</div>
                  </div>
                </div>
                <button className="sidebar-reset-password" onClick={handlePasswordReset}>
                  Reset password
                </button>
              </div>
            ) : NAV.filter(n => n.section === section.key).map(item => (
              <button
                key={item.id}
                className={`nav-item${active === item.id ? ' active' : ''}`}
                onClick={() => onNav(item.id)}
              >
                <span style={{ fontSize: '1rem' }}>{item.icon}</span>
                {item.label}
              </button>
            ))}
          </div>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="streak-badge">
          <span className="streak-fire">🔥</span>
          <div>
            <div className="streak-count">{streak} days</div>
            <div className="streak-label">Study streak</div>
          </div>
        </div>
      </div>
    </aside>
  )
}
