import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { auth } from './firebase/firebase'; // 🔥 NEW
import { useStore } from './useStore';

const SUBJECTS = ['Math', 'Science', 'English', 'History', 'Physics', 'Chemistry', 'Biology', 'Computer Science', 'Literature', 'Art']

export default function Dashboard({ onNav }) {
  const store = useStore()

  // 🔥 FIREBASE USER
  const user = auth.currentUser
  const username = user?.email?.split("@")[0] || "Student"

  // EXISTING DATA
  const todayTasks = store.getTodayTasks()
  const weeklyData = store.getWeeklyData()
  const streak = store.getStreak()
  const hoursToday = store.getTotalHoursToday()
  const completedToday = todayTasks.filter(t => t.completed).length
  const activeGoals = (store.goals || []).filter(g => g.progress < 100).length

  const today = new Date().toLocaleDateString('en', {
    weekday: 'long',
    month: 'long',
    day: 'numeric'
  })

  return (
    <div className="page-enter">
     {/* HEADER */}
<div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
  <div>
    <h1 className="page-title">
      Good {getGreeting()}, {store.settings?.name || username}! 👋
    </h1>
    <p className="page-subtitle">{today}</p>
  </div>

  <div style={{ display: 'flex', gap: '12px' }}>
    <button className="btn btn-primary" onClick={() => onNav('focus')}>
      🎧 Start Focus Session
    </button>
    
    {/* LOGOUT BUTTON */}
    <button
      className="btn btn-secondary"
      onClick={() => {
        auth.signOut()
          .then(() => onNav('login')) // redirect to login page
          .catch(err => console.error('Logout error:', err))
      }}
    >
      🔒 Logout
    </button>
  </div>
</div>
      {/* STATS */}
      <div className="grid-4" style={{ marginBottom: 24 }}>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#d4edda' }}>📚</div>
          <div className="stat-value">{1}Hr</div>
          <div className="stat-label">Studied Today</div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#fff3cd' }}>✅</div>
          <div className="stat-value">{completedToday}/{todayTasks.length}</div>
          <div className="stat-label">Tasks Done</div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#fee2e2' }}>🔥</div>
          <div className="stat-value">{streak}</div>
          <div className="stat-label">Day Streak</div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#dbeafe' }}>🎯</div>
          <div className="stat-value">{activeGoals}</div>
          <div className="stat-label">Active Goals</div>
        </div>
      </div>

      <div className="grid-2">

        {/* TODAY TASKS */}
        <div className="card-white">
          <div className="section-header">
            <span className="section-title">Today's Schedule</span>
            <button className="btn btn-sm btn-ghost" onClick={() => onNav('planner')}>
              View All
            </button>
          </div>

          {todayTasks.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">📅</div>
              <div className="empty-text">No tasks scheduled for today</div>
              <button
                className="btn btn-primary btn-sm"
                style={{ marginTop: 12 }}
                onClick={() => onNav('planner')}
              >
                Add Tasks
              </button>
            </div>
          ) : (
            todayTasks.slice(0, 5).map(task => (
              <div
                key={task.id}
                className={`task-item${task.completed ? ' completed' : ''}`}
                onClick={() => store.toggleTask(task.id)}
              >
                <div className={`task-checkbox${task.completed ? ' checked' : ''}`}>
                  {task.completed && <span style={{ color: 'white', fontSize: '10px' }}>✓</span>}
                </div>

                <div className="task-content">
                  <div className="task-title">{task.title}</div>

                  <div className="task-meta">
                    {task.time && <span className="task-time">⏰ {task.time}</span>}
                    {task.subject && (
                      <span className={`badge badge-${getSubjectColor(task.subject)}`}>
                        {task.subject}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

        {/* WEEKLY CHART */}
        <div className="card-white">
          <div className="section-header">
            <span className="section-title">This Week</span>
            <button className="btn btn-sm btn-ghost" onClick={() => onNav('analytics')}>
              Analytics
            </button>
          </div>

          <div className="chart-wrap">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={weeklyData}>
                <XAxis dataKey="day" />
                <YAxis />
                <Tooltip formatter={(v) => [`${v}h`, 'Study Time']} />
                <Bar dataKey="hours" fill="#8FAE8E" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* GOALS */}
      {store.goals?.length > 0 && (
        <div className="card-white" style={{ marginTop: 20 }}>
          <div className="section-header">
            <span className="section-title">Active Goals</span>
            <button className="btn btn-sm btn-ghost" onClick={() => onNav('goals')}>
              Manage Goals
            </button>
          </div>

          <div className="grid-2">
            {store.goals
              .filter(g => g.progress < 100)
              .slice(0, 4)
              .map(goal => (
                <div key={goal.id} style={{ padding: '12px 0' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ fontSize: '0.88rem', fontWeight: 500 }}>
                      {goal.title}
                    </span>
                    <span style={{ fontSize: '0.78rem' }}>
                      {goal.progress}%
                    </span>
                  </div>

                  <div className="progress-bar">
                    <div
                      className="progress-fill"
                      style={{ width: `${goal.progress}%` }}
                    />
                  </div>
                </div>
              ))}
          </div>
        </div>
      )}
    </div>
  )
}

// HELPERS
function getGreeting() {
  const h = new Date().getHours()
  if (h < 12) return 'morning'
  if (h < 17) return 'afternoon'
  return 'evening'
}

function getSubjectColor(subject) {
  const map = {
    Math: 'blue',
    Science: 'green',
    English: 'yellow',
    History: 'red',
    Physics: 'blue',
    Chemistry: 'green'
  }
  return map[subject] || 'gray'
}