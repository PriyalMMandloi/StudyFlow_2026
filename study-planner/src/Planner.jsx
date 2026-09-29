// src/Planner.jsx
import { useEffect, useState } from "react"
import { getGoals } from "./goalsService"
import { addTask, deleteTask, getTasks, toggleTask, updateTask } from "./plannerService"
import { useToast } from "./ToastContext"

const SUBJECTS = [
  "Math", "Science", "English", "History", "Physics",
  "Chemistry", "Biology", "Computer Science", "Literature", "Art", "Other",
]
const PRIORITIES = ["Low", "Medium", "High"]

// ─── Timezone-safe date helper ─────────────────────────────────────────────
// toISOString() converts to UTC which causes off-by-one in IST (UTC+5:30).
// This always returns the LOCAL date string "YYYY-MM-DD".
function toLocalDateStr(d) {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, "0")
  const day = String(d.getDate()).padStart(2, "0")
  return `${y}-${m}-${day}`
}

export default function Planner() {
  const toast = useToast()
  const [currentDate, setCurrentDate] = useState(new Date())
  const [selectedDate, setSelectedDate] = useState(toLocalDateStr(new Date()))  // ✅ fixed
  const [showModal, setShowModal] = useState(false)
  const [editTask, setEditTask] = useState(null)
  const [form, setForm] = useState({
    title: "",
    subject: "",
    time: "",
    duration: "",
    priority: "Medium",
    notes: "",
    goalId: "",
  })
  const [tasks, setTasks] = useState([])
  const [allTaskDates, setAllTaskDates] = useState(new Set()) // tracks which dates have tasks
  const [goals, setGoals] = useState([])

  // Load tasks for selected date
  useEffect(() => {
    async function fetchTasks() {
      try {
        const data = await getTasks(selectedDate)
        setTasks(data)
      } catch (err) {
        toast("Error fetching tasks", "error")
        console.error(err)
      }
    }
    fetchTasks()
  }, [selectedDate])

  // Load ALL task dates once (for dot indicators on calendar)
  useEffect(() => {
    async function fetchAllDates() {
      try {
        // Fetch tasks for the entire visible month range
        // We fetch a wider range so dots show correctly when navigating months
        const year = currentDate.getFullYear()
        const month = currentDate.getMonth()
        const firstDay = toLocalDateStr(new Date(year, month, 1))
        const lastDay = toLocalDateStr(new Date(year, month + 1, 0))

        // getTasks supports date range — adjust if your service only supports single date
        // Here we batch-fetch by getting all tasks and filtering by date prefix (month)
        // If your plannerService supports a month query, use that instead
        const monthPrefix = `${year}-${String(month + 1).padStart(2, "0")}`

        // Fallback: fetch each day of the month (replace with a bulk API if available)
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const dateSet = new Set()

        // Try to get all tasks for the month in one shot using date range
        // If your getTasks doesn't support ranges, replace with a loop or a new service method
        try {
          for (let i = 1; i <= daysInMonth; i++) {
            const d = toLocalDateStr(new Date(year, month, i))
            const dayTasks = await getTasks(d)
            if (dayTasks.length > 0) dateSet.add(d)
          }
        } catch (e) {
          console.error("Could not prefetch month tasks:", e)
        }

        setAllTaskDates(dateSet)
      } catch (err) {
        console.error("Error fetching all task dates:", err)
      }
    }
    fetchAllDates()
  }, [currentDate]) // re-run when user navigates months

  // Keep allTaskDates in sync when tasks are added/deleted on selected date
  useEffect(() => {
    setAllTaskDates(prev => {
      const next = new Set(prev)
      if (tasks.length > 0) {
        next.add(selectedDate)
      } else {
        next.delete(selectedDate)
      }
      return next
    })
  }, [tasks, selectedDate])

  // Load goals once on mount
  useEffect(() => {
    getGoals()
      .then(setGoals)
      .catch(err => console.error("Error fetching goals:", err))
  }, [])

  // ─── Calendar helpers ──────────────────────────────────────────────────────
  const year = currentDate.getFullYear()
  const month = currentDate.getMonth()
  const firstDay = new Date(year, month, 1).getDay()
  const daysInMonth = new Date(year, month + 1, 0).getDate()
  const today = toLocalDateStr(new Date())  // ✅ fixed — no UTC shift

  const calDays = []
  for (let i = 0; i < firstDay; i++) calDays.push({ date: "", day: "", otherMonth: true })
  for (let i = 1; i <= daysInMonth; i++) {
    const d = new Date(year, month, i)
    calDays.push({ date: toLocalDateStr(d), day: i, otherMonth: false })  // ✅ fixed
  }
  while (calDays.length < 42) calDays.push({ date: "", day: "", otherMonth: true })

  // ─── Modal helpers ─────────────────────────────────────────────────────────
  function openAdd() {
    setEditTask(null)
    setForm({ title: "", subject: "", time: "", duration: "60", priority: "Medium", notes: "", goalId: "" })
    setShowModal(true)
  }

  function openEdit(task) {
    setEditTask(task)
    setForm({ ...task })
    setShowModal(true)
  }

  // ─── CRUD handlers ─────────────────────────────────────────────────────────
  async function handleSubmit() {
    if (!form.title.trim()) return
    try {
      if (editTask) {
        await updateTask(editTask.id, { ...form, date: selectedDate })
        setTasks(prev => prev.map(t => (t.id === editTask.id ? { ...t, ...form } : t)))
        toast("Task updated ✓", "success")
      } else {
        const docRef = await addTask({ ...form, date: selectedDate })
        setTasks(prev => [...prev, { ...form, id: docRef.id }])
        toast("Task added ✓", "success")
      }
      setShowModal(false)
    } catch (err) {
      toast("Error saving task", "error")
      console.error(err)
    }
  }

  async function handleDelete(id) {
    try {
      await deleteTask(id)
      setTasks(prev => prev.filter(t => t.id !== id))
      toast("Task deleted")
    } catch (err) {
      toast("Error deleting task", "error")
      console.error(err)
    }
  }

  async function handleToggle(task) {
    try {
      await toggleTask(task.id, !task.completed, task.goalId)
      setTasks(prev =>
        prev.map(t => (t.id === task.id ? { ...t, completed: !t.completed } : t))
      )
    } catch (err) {
      toast("Error updating task", "error")
      console.error(err)
    }
  }

  const monthStr = currentDate.toLocaleDateString("en", { month: "long", year: "numeric" })
  const selectedStr = new Date(selectedDate + "T12:00:00").toLocaleDateString("en", {
    weekday: "long", month: "long", day: "numeric",
  })

  return (
    <div className="page-enter">
      <div className="page-header">
        <div>
          <h1 className="page-title">Study Planner</h1>
          <p className="page-subtitle">Organize your study sessions</p>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "320px 1fr", gap: 20 }}>
        {/* ── Calendar ── */}
        <div className="card-white">
          <div className="section-header" style={{ marginBottom: 12 }}>
            <button
              className="btn btn-icon btn-ghost btn-sm"
              onClick={() => setCurrentDate(new Date(year, month - 1))}
            >‹</button>
            <span style={{ fontWeight: 600, fontSize: "0.9rem" }}>{monthStr}</span>
            <button
              className="btn btn-icon btn-ghost btn-sm"
              onClick={() => setCurrentDate(new Date(year, month + 1))}
            >›</button>
          </div>

          <div className="calendar-grid">
            {["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"].map(d => (
              <div key={d} className="cal-header">{d}</div>
            ))}
            {calDays.map((d, i) => {
              const isToday = d.date === today
              const isSelected = d.date === selectedDate
              const hasTasks = d.date && allTaskDates.has(d.date)  // ✅ dot indicator

              return (
                <div
                  key={i}
                  className={[
                    "cal-day",
                    d.otherMonth ? "other-month" : "",
                    isToday ? "today" : "",
                    isSelected && !isToday ? "selected" : "",
                  ].filter(Boolean).join(" ")}
                  onClick={() => d.date && setSelectedDate(d.date)}
                  style={{ position: "relative" }}
                >
                  {d.day}

                  {/* Task dot indicator */}
                  {hasTasks && (
                    <div
                      style={{
                        position: "absolute",
                        bottom: 3,
                        left: "50%",
                        transform: "translateX(-50%)",
                        width: 5,
                        height: 5,
                        borderRadius: "50%",
                        // Green dot if selected/today, else use accent color
                        backgroundColor: isToday
                          ? "rgba(255,255,255,0.85)"
                          : isSelected
                          ? "var(--primary, #4f7942)"
                          : "var(--primary, #4f7942)",
                        opacity: 0.85,
                      }}
                    />
                  )}
                </div>
              )
            })}
          </div>

          {/* Legend */}
          <div style={{
            display: "flex",
            alignItems: "center",
            gap: 6,
            marginTop: 12,
            paddingTop: 10,
            borderTop: "1px solid var(--border, #eee)",
            fontSize: "0.72rem",
            color: "var(--text-muted, #888)",
          }}>
            <div style={{
              width: 7, height: 7, borderRadius: "50%",
              backgroundColor: "var(--primary, #4f7942)",
              opacity: 0.85, flexShrink: 0,
            }} />
            <span>Date has tasks scheduled</span>
          </div>
        </div>

        {/* ── Task list ── */}
        <div className="card-white">
          <div className="section-header">
            <span className="section-title">{selectedStr}</span>
            <button className="btn btn-primary btn-sm" onClick={openAdd}>+ Add Task</button>
          </div>

          {tasks.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">📅</div>
              <div className="empty-text">No tasks for this day</div>
              <button className="btn btn-primary btn-sm" onClick={openAdd}>Schedule a Session</button>
            </div>
          ) : (
            tasks.map(task => (
              <div key={task.id} className={`task-item${task.completed ? " completed" : ""}`}>
                <div
                  className={`task-checkbox${task.completed ? " checked" : ""}`}
                  onClick={() => handleToggle(task)}
                >
                  {task.completed && <span style={{ color: "white", fontSize: "10px" }}>✓</span>}
                </div>
                <div className="task-content">
                  <div className="task-title">{task.title}</div>
                  <div className="task-meta">
                    {task.time && <span>⏰ {task.time}</span>}
                    {task.duration && <span>⏱ {task.duration} min</span>}
                    {task.subject && <span className="badge badge-green">{task.subject}</span>}
                    {task.priority && task.priority !== "Medium" && (
                      <span className={`badge badge-${task.priority === "High" ? "red" : "blue"}`}>
                        {task.priority}
                      </span>
                    )}
                    {task.goalId && goals.length > 0 && (() => {
                      const linked = goals.find(g => g.id === task.goalId)
                      return linked
                        ? <span className="badge badge-gray">🎯 {linked.title}</span>
                        : null
                    })()}
                  </div>
                  {task.notes && (
                    <p style={{ fontSize: "0.78rem", color: "var(--text-muted)" }}>{task.notes}</p>
                  )}
                </div>
                <div className="task-actions">
                  <button className="btn btn-icon btn-ghost btn-sm" onClick={() => openEdit(task)}>✎</button>
                  <button className="btn btn-icon btn-danger btn-sm" onClick={() => handleDelete(task.id)}>✕</button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* ── Task Modal ── */}
      {showModal && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setShowModal(false)}>
          <div className="modal">
            <div className="modal-header">
              <h3 className="modal-title">{editTask ? "Edit Task" : "Add Study Task"}</h3>
              <button className="btn btn-icon btn-ghost btn-sm" onClick={() => setShowModal(false)}>✕</button>
            </div>

            <div className="form-group">
              <label>Task Title *</label>
              <input
                className="form-input"
                value={form.title}
                onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
              />
            </div>

            <div className="grid-2">
              <div className="form-group">
                <label>Subject</label>
                <select
                  className="form-select"
                  value={form.subject}
                  onChange={e => setForm(f => ({ ...f, subject: e.target.value }))}
                >
                  <option value="">Select subject</option>
                  {SUBJECTS.map(s => <option key={s}>{s}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label>Priority</label>
                <select
                  className="form-select"
                  value={form.priority}
                  onChange={e => setForm(f => ({ ...f, priority: e.target.value }))}
                >
                  {PRIORITIES.map(p => <option key={p}>{p}</option>)}
                </select>
              </div>
            </div>

            <div className="grid-2">
              
              
            </div>

            <div className="form-group">
              <label>Notes</label>
              <textarea
                className="form-textarea"
                value={form.notes}
                onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
              />
            </div>

            <div className="form-group">
              <label>Link to Goal (optional)</label>
              <select
                className="form-select"
                value={form.goalId}
                onChange={e => setForm(f => ({ ...f, goalId: e.target.value }))}
              >
                <option value="">— No goal —</option>
                {goals.map(g => (
                  <option key={g.id} value={g.id}>{g.title}</option>
                ))}
              </select>
            </div>

            <div className="modal-footer">
              <button className="btn btn-ghost" onClick={() => setShowModal(false)}>Cancel</button>
              <button className="btn btn-primary" onClick={handleSubmit}>
                {editTask ? "Save Changes" : "Add Task"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
