import { useStore } from './useStore'

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

export default function Sidebar({ active, onNav, open }) {
  const { getStreak } = useStore()
  const streak = getStreak()

  const sections = [
    { key: 'main', label: 'Study' },
    { key: 'insights', label: 'Insights' },
    { key: 'tools', label: 'Tools' },
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
            {NAV.filter(n => n.section === section.key).map(item => (
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
