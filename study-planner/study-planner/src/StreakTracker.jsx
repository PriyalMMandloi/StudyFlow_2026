import { useStore } from './useStore'

export default function StreakTracker() {
  const store = useStore()
  const streak = store.getStreak()
  const streaks = store.streaks || []

  // Build last 84 days (12 weeks)
  const days = []
  const today = new Date()
  for (let i = 83; i >= 0; i--) {
    const d = new Date(today)
    d.setDate(d.getDate() - i)
    const ds = d.toISOString().split('T')[0]
    days.push({ date: ds, active: streaks.includes(ds), isToday: i === 0 })
  }

  const weeks = []
  for (let i = 0; i < days.length; i += 7) {
    weeks.push(days.slice(i, i + 7))
  }

  const totalStudied = streaks.length
  const thisWeek = days.slice(-7).filter(d => d.active).length
  const bestStreak = getBestStreak(streaks)

  return (
    <div className="page-enter">
      <div className="page-header">
        <div>
          <h1 className="page-title">Streak Tracker</h1>
          <p className="page-subtitle">Stay consistent every day</p>
        </div>
      </div>

      {/* Big Streak Display */}
      <div className="card" style={{ textAlign: 'center', marginBottom: 24, padding: '36px 20px', background: 'linear-gradient(135deg, var(--green), var(--sage))' }}>
        <div style={{ fontSize: '4rem', marginBottom: 8 }}>🔥</div>
        <div style={{ fontFamily: 'DM Serif Display, serif', fontSize: '3.5rem', color: 'white', lineHeight: 1 }}>{streak}</div>
        <div style={{ color: 'rgba(255,255,255,0.85)', fontSize: '1rem', marginTop: 6 }}>Day Streak</div>
        {streak > 0 && (
          <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: '0.82rem', marginTop: 8 }}>
            Keep it up! Don't break the chain 💪
          </div>
        )}
        {streak === 0 && (
          <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: '0.82rem', marginTop: 8 }}>
            Start studying today to begin your streak!
          </div>
        )}
      </div>

      <div className="grid-3" style={{ marginBottom: 24 }}>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#d4edda' }}>📅</div>
          <div className="stat-value">{totalStudied}</div>
          <div className="stat-label">Total Days Studied</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#fff3cd' }}>🗓</div>
          <div className="stat-value">{thisWeek}/7</div>
          <div className="stat-label">This Week</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#dbeafe' }}>🏆</div>
          <div className="stat-value">{bestStreak}</div>
          <div className="stat-label">Best Streak</div>
        </div>
      </div>

      {/* Streak Calendar */}
      <div className="card-white">
        <div className="section-header">
          <span className="section-title">Study History (Last 84 days)</span>
          <div style={{ display: 'flex', gap: 12, alignItems: 'center', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <span style={{ width: 12, height: 12, background: 'var(--border)', borderRadius: 3, display: 'inline-block' }} /> No study
            </span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <span style={{ width: 12, height: 12, background: 'var(--green)', borderRadius: 3, display: 'inline-block' }} /> Studied
            </span>
          </div>
        </div>

        <div style={{ display: 'flex', gap: 4, overflowX: 'auto', paddingBottom: 8 }}>
          {weeks.map((week, wi) => (
            <div key={wi} style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              {week.map((day, di) => (
                <div
                  key={di}
                  className={`streak-dot${day.active ? ' active' : ''}${day.isToday ? ' today' : ''}`}
                  title={`${day.date}${day.active ? ' ✓ Studied' : ''}`}
                />
              ))}
            </div>
          ))}
        </div>

        {/* Month labels */}
        <div style={{ marginTop: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: 'var(--text-muted)' }}>
            {[-84, -56, -28, 0].map(offset => {
              const d = new Date(today)
              d.setDate(d.getDate() + offset)
              return <span key={offset}>{d.toLocaleDateString('en', { month: 'short', year: '2-digit' })}</span>
            })}
          </div>
        </div>
      </div>

      {/* Motivational milestones */}
      <div className="card-white" style={{ marginTop: 20 }}>
        <div className="section-header">
          <span className="section-title">Milestones</span>
        </div>
        <div className="grid-3">
          {[
            { days: 7, label: '1 Week', emoji: '⭐' },
            { days: 14, label: '2 Weeks', emoji: '🌟' },
            { days: 30, label: '1 Month', emoji: '🏅' },
            { days: 60, label: '2 Months', emoji: '🥈' },
            { days: 100, label: '100 Days', emoji: '🥇' },
            { days: 365, label: '1 Year', emoji: '👑' },
          ].map(m => (
            <div key={m.days} style={{
              padding: '12px 14px',
              borderRadius: 10,
              border: `1.5px solid ${bestStreak >= m.days ? 'var(--green)' : 'var(--border)'}`,
              background: bestStreak >= m.days ? '#d4edda' : 'var(--white)',
              display: 'flex', alignItems: 'center', gap: 10
            }}>
              <span style={{ fontSize: '1.4rem', opacity: bestStreak >= m.days ? 1 : 0.3 }}>{m.emoji}</span>
              <div>
                <div style={{ fontSize: '0.85rem', fontWeight: 600 }}>{m.label}</div>
                <div style={{ fontSize: '0.72rem', color: bestStreak >= m.days ? '#2d6a4f' : 'var(--text-muted)' }}>
                  {bestStreak >= m.days ? 'Achieved!' : `${m.days - bestStreak} days to go`}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

function getBestStreak(streaks) {
  if (!streaks.length) return 0
  const sorted = [...new Set(streaks)].sort()
  let best = 1, cur = 1
  for (let i = 1; i < sorted.length; i++) {
    const prev = new Date(sorted[i - 1])
    const curr = new Date(sorted[i])
    const diff = (curr - prev) / (1000 * 60 * 60 * 24)
    if (diff === 1) { cur++; best = Math.max(best, cur) }
    else cur = 1
  }
  return best
}
