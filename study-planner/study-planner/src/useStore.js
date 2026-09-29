import { useState, useEffect, useCallback } from 'react'

const defaultData = {
  tasks: [],
  notes: [],
  goals: [],
  streaks: [],
  studyLogs: [], // [{date, minutes}]
  settings: { name: 'Student' }
}

function loadData() {
  try {
    const saved = localStorage.getItem('studyflow-data')
    if (saved) {
      const parsed = JSON.parse(saved)
      return { ...defaultData, ...parsed }
    }
  } catch {}
  return defaultData
}

function saveData(data) {
  try {
    localStorage.setItem('studyflow-data', JSON.stringify(data))
  } catch {}
}

let globalData = loadData()
const listeners = new Set()

function setGlobal(updater) {
  globalData = typeof updater === 'function' ? updater(globalData) : { ...globalData, ...updater }
  saveData(globalData)
  listeners.forEach(fn => fn(globalData))
}

export function useStore() {
  const [data, setData] = useState(globalData)

  useEffect(() => {
    listeners.add(setData)
    return () => listeners.delete(setData)
  }, [])

  const addTask = useCallback((task) => {
    const newTask = { ...task, id: Date.now().toString(), createdAt: new Date().toISOString(), completed: false }
    setGlobal(d => ({ ...d, tasks: [...d.tasks, newTask] }))
  }, [])

  const updateTask = useCallback((id, updates) => {
    setGlobal(d => ({ ...d, tasks: d.tasks.map(t => t.id === id ? { ...t, ...updates } : t) }))
  }, [])

  const deleteTask = useCallback((id) => {
    setGlobal(d => ({ ...d, tasks: d.tasks.filter(t => t.id !== id) }))
  }, [])

  const toggleTask = useCallback((id) => {
    setGlobal(d => ({ ...d, tasks: d.tasks.map(t => t.id === id ? { ...t, completed: !t.completed } : t) }))
    // Log study time when completing
    updateStreak()
  }, [])

  const addNote = useCallback((note) => {
    const newNote = { ...note, id: Date.now().toString(), createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() }
    setGlobal(d => ({ ...d, notes: [...d.notes, newNote] }))
  }, [])

  const updateNote = useCallback((id, updates) => {
    setGlobal(d => ({ ...d, notes: d.notes.map(n => n.id === id ? { ...n, ...updates, updatedAt: new Date().toISOString() } : n) }))
  }, [])

  const deleteNote = useCallback((id) => {
    setGlobal(d => ({ ...d, notes: d.notes.filter(n => n.id !== id) }))
  }, [])

  const addGoal = useCallback((goal) => {
    const newGoal = { ...goal, id: Date.now().toString(), createdAt: new Date().toISOString(), progress: 0 }
    setGlobal(d => ({ ...d, goals: [...d.goals, newGoal] }))
  }, [])

  const updateGoal = useCallback((id, updates) => {
    setGlobal(d => ({ ...d, goals: d.goals.map(g => g.id === id ? { ...g, ...updates } : g) }))
  }, [])

  const deleteGoal = useCallback((id) => {
    setGlobal(d => ({ ...d, goals: d.goals.filter(g => g.id !== id) }))
  }, [])

  const logStudyTime = useCallback((minutes) => {
    const today = new Date().toISOString().split('T')[0]
    setGlobal(d => {
      const logs = d.studyLogs || []
      const idx = logs.findIndex(l => l.date === today)
      if (idx >= 0) {
        const updated = [...logs]
        updated[idx] = { ...updated[idx], minutes: updated[idx].minutes + minutes }
        return { ...d, studyLogs: updated }
      }
      return { ...d, studyLogs: [...logs, { date: today, minutes }] }
    })
    updateStreak()
  }, [])

  function updateStreak() {
    const today = new Date().toISOString().split('T')[0]
    setGlobal(d => {
      const streaks = d.streaks || []
      if (!streaks.includes(today)) {
        return { ...d, streaks: [...streaks, today] }
      }
      return d
    })
  }

  const getStreak = useCallback(() => {
    const streaks = data.streaks || []
    if (!streaks.length) return 0
    let count = 0
    const today = new Date()
    for (let i = 0; i < 365; i++) {
      const d = new Date(today)
      d.setDate(d.getDate() - i)
      const ds = d.toISOString().split('T')[0]
      if (streaks.includes(ds)) count++
      else if (i > 0) break
    }
    return count
  }, [data.streaks])

  const getWeeklyData = useCallback(() => {
    const days = []
    const today = new Date()
    for (let i = 6; i >= 0; i--) {
      const d = new Date(today)
      d.setDate(d.getDate() - i)
      const ds = d.toISOString().split('T')[0]
      const log = (data.studyLogs || []).find(l => l.date === ds)
      days.push({
        day: d.toLocaleDateString('en', { weekday: 'short' }),
        date: ds,
        minutes: log ? log.minutes : 0,
        hours: log ? Math.round(log.minutes / 60 * 10) / 10 : 0
      })
    }
    return days
  }, [data.studyLogs])

  const getMonthlyData = useCallback(() => {
    const weeks = []
    const today = new Date()
    for (let w = 3; w >= 0; w--) {
      let total = 0
      for (let d = 0; d < 7; d++) {
        const date = new Date(today)
        date.setDate(date.getDate() - w * 7 - d)
        const ds = date.toISOString().split('T')[0]
        const log = (data.studyLogs || []).find(l => l.date === ds)
        if (log) total += log.minutes
      }
      weeks.push({ week: `W${4 - w}`, hours: Math.round(total / 60 * 10) / 10 })
    }
    return weeks
  }, [data.studyLogs])

  const getTodayTasks = useCallback(() => {
    const today = new Date().toISOString().split('T')[0]
    return data.tasks.filter(t => t.date === today)
  }, [data.tasks])

  const getTasksByDate = useCallback((date) => {
    return data.tasks.filter(t => t.date === date)
  }, [data.tasks])

  const getTotalHoursToday = useCallback(() => {
    const today = new Date().toISOString().split('T')[0]
    const log = (data.studyLogs || []).find(l => l.date === today)
    return log ? Math.round(log.minutes / 60 * 10) / 10 : 0
  }, [data.studyLogs])

  return {
    ...data,
    addTask, updateTask, deleteTask, toggleTask,
    addNote, updateNote, deleteNote,
    addGoal, updateGoal, deleteGoal,
    logStudyTime,
    getStreak, getWeeklyData, getMonthlyData,
    getTodayTasks, getTasksByDate, getTotalHoursToday,
    updateStreak
  }
}
