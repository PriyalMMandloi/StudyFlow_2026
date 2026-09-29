
import { useState } from 'react'
import { useStore } from './useStore'
import {
  BarChart, Bar, LineChart, Line, PieChart, Pie, Cell,
  XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, Legend
} from 'recharts'

const COLORS = ['#8FAE8E', '#AFC9A8', '#C8DEC6', '#7a9e79', '#5f8b5e']

export default function Analytics() {
  const store = useStore()
  const [tab, setTab] = useState('weekly')

  const weeklyData = store.getWeeklyData()
  const monthlyData = store.getMonthlyData()

  const allTasks = store.tasks || []
  const completed = allTasks.filter(t => t.completed).length
  const pending = allTasks.filter(t => !t.completed).length

  const pieData = [
    { name: 'Completed', value: completed },
    { name: 'Pending', value: pending },
  ].filter(d => d.value > 0)

  // Subject breakdown
  const subjectMap = {}
  allTasks.forEach(t => {
    if (t.subject) {
      subjectMap[t.subject] = (subjectMap[t.subject] || 0) + (t.completed ? 1 : 0.5)
    }
  })
  const subjectData = Object.entries(subjectMap).map(([name, value]) => ({ name, value: Math.round(value) })).sort((a, b) => b.value - a.value)

  const totalHours = (store.studyLogs || []).reduce((sum, l) => sum + l.minutes, 0) / 60
  const avgDaily = weeklyData.reduce((s, d) => s + d.hours, 0) / 7

  return (
    <div className="page-enter">
      <div className="page-header">
        <div>
          <h1 className="page-title">Analytics</h1>
          <p className="page-subtitle">Track your study progress</p>
        </div>
      </div>

      <div className="grid-4" style={{ marginBottom: 24 }}>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#d4edda' }}>⏱</div>
          <div className="stat-value">{Math.round(totalHours * 10) / 10}h</div>
          <div className="stat-label">Total Study Time</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#fff3cd' }}>📊</div>
          <div className="stat-value">{Math.round(avgDaily * 10) / 10}h</div>
          <div className="stat-label">Daily Average</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#dbeafe' }}>✅</div>
          <div className="stat-value">{completed}</div>
          <div className="stat-label">Tasks Completed</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: '#fee2e2' }}>📋</div>
          <div className="stat-value">{pending}</div>
          <div className="stat-label">Pending Tasks</div>
        </div>
      </div>

      <div className="tabs">
        <button className={`tab${tab === 'weekly' ? ' active' : ''}`} onClick={() => setTab('weekly')}>Weekly</button>
        <button className={`tab${tab === 'monthly' ? ' active' : ''}`} onClick={() => setTab('monthly')}>Monthly</button>
      </div>

      <div className="grid-2" style={{ marginBottom: 20 }}>
        {/* Study Time Chart */}
        <div className="card-white">
          <div className="section-header">
            <span className="section-title">{tab === 'weekly' ? 'Study Hours This Week' : 'Monthly Overview'}</span>
          </div>
          <div className="chart-wrap">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={tab === 'weekly' ? weeklyData : monthlyData} margin={{ top: 5, right: 5, left: -20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E8E0D5" vertical={false} />
                <XAxis dataKey={tab === 'weekly' ? 'day' : 'week'} tick={{ fontSize: 11, fill: '#7A7A7A' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 10, fill: '#7A7A7A' }} axisLine={false} tickLine={false} />
                <Tooltip contentStyle={{ background: '#fff', border: '1px solid #E8E0D5', borderRadius: 10, fontSize: 12 }} formatter={(v) => [`${v}h`, 'Hours']} />
                <Bar dataKey="hours" fill="#8FAE8E" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Task Completion Pie */}
        <div className="card-white">
          <div className="section-header">
            <span className="section-title">Task Status</span>
          </div>
          {pieData.length === 0 ? (
            <div className="empty-state"><div className="empty-text">No task data yet</div></div>
          ) : (
            <div className="chart-wrap">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={pieData} cx="50%" cy="50%" innerRadius={55} outerRadius={85} paddingAngle={3} dataKey="value">
                    {pieData.map((_, i) => <Cell key={i} fill={COLORS[i]} />)}
                  </Pie>
                  <Tooltip formatter={(v, n) => [v, n]} contentStyle={{ borderRadius: 10, border: '1px solid #E8E0D5', fontSize: 12 }} />
                  <Legend iconType="circle" iconSize={10} wrapperStyle={{ fontSize: 12 }} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>
      </div>

      {/* Subject breakdown */}
      {subjectData.length > 0 && (
        <div className="card-white">
          <div className="section-header">
            <span className="section-title">Subject Breakdown</span>
          </div>
          <div className="chart-wrap" style={{ height: 180 }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={subjectData} layout="vertical" margin={{ top: 5, right: 20, left: 30, bottom: 5 }}>
                <XAxis type="number" tick={{ fontSize: 10, fill: '#7A7A7A' }} axisLine={false} tickLine={false} />
                <YAxis type="category" dataKey="name" tick={{ fontSize: 11, fill: '#7A7A7A' }} axisLine={false} tickLine={false} width={100} />
                <Tooltip contentStyle={{ borderRadius: 10, border: '1px solid #E8E0D5', fontSize: 12 }} />
                <Bar dataKey="value" fill="#AFC9A8" radius={[0, 6, 6, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}
    </div>
  )
}
