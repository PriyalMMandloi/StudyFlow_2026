// src/Goals.jsx
import { useEffect, useState } from "react"
import { addGoal, deleteGoal, getGoals, updateGoal } from "./goalsService"
import { useToast } from "./ToastContext"

const TYPES = ["Short-term", "Long-term"]
const CATS = ["Academic", "Skills", "Reading", "Projects", "Health", "Other"]

export default function Goals() {
  const toast = useToast()
  const [goals, setGoals] = useState([])
  const [showModal, setShowModal] = useState(false)
  const [editGoal, setEditGoal] = useState(null)
  const [activeTab, setActiveTab] = useState("all")
  const [form, setForm] = useState({
    title: "",
    description: "",
    type: "Short-term",
    category: "Academic",
    target: "",
    unit: "",
    deadline: "",
    progress: 0,
  })

  // Fetch goals on mount
  useEffect(() => {
    async function fetchGoals() {
      try {
        const data = await getGoals()
        setGoals(data)
      } catch (err) {
        toast("Error fetching goals", "error")
        console.error(err)
      }
    }
    fetchGoals()
  }, [])

  const filtered =
    activeTab === "all"
      ? goals
      : goals.filter(g => g.type?.toLowerCase() === activeTab)

  // ─── Modal helpers ─────────────────────────────────────────────────────────
  function openAdd() {
    setEditGoal(null)
    setForm({
      title: "", description: "", type: "Short-term",
      category: "Academic", target: "", unit: "", deadline: "", progress: 0,
    })
    setShowModal(true)
  }

  function openEdit(goal) {
    setEditGoal(goal)
    setForm({ ...goal })
    setShowModal(true)
  }

  // ─── CRUD handlers ─────────────────────────────────────────────────────────
  async function handleSubmit() {
    if (!form.title.trim()) return
    try {
      if (editGoal) {
        await updateGoal(editGoal.id, form)
        setGoals(prev => prev.map(g => (g.id === editGoal.id ? { ...g, ...form } : g)))
        toast("Goal updated ✓", "success")
      } else {
        const docRef = await addGoal(form)
        setGoals(prev => [...prev, { ...form, id: docRef.id }])
        toast("Goal created ✓", "success")
      }
      setShowModal(false)
    } catch (err) {
      toast("Error saving goal", "error")
      console.error(err)
    }
  }

  async function handleDelete(id) {
    try {
      await deleteGoal(id)
      setGoals(prev => prev.filter(g => g.id !== id))
      toast("Goal deleted", "success")
    } catch (err) {
      toast("Error deleting goal", "error")
      console.error(err)
    }
  }

  // Manual progress update — only used for goals NOT linked to planner tasks
  async function updateProgress(id, val) {
    const progress = Math.min(100, Math.max(0, Number(val)))
    try {
      await updateGoal(id, { progress })
      setGoals(prev => prev.map(g => (g.id === id ? { ...g, progress } : g)))
    } catch (err) {
      toast("Error updating progress", "error")
      console.error(err)
    }
  }

  const completed = goals.filter(g => g.progress >= 100).length
  const active = goals.filter(g => g.progress < 100).length

  // A goal is "task-driven" when recalcGoalProgress has written totalTasks onto it
  function isTaskDriven(goal) {
    return goal.totalTasks != null && goal.totalTasks > 0
  }

  return (
    <div className="page-enter">
      {/* Header */}
      <div className="page-header">
        <div>
          <h1 className="page-title">Goals</h1>
          <p className="page-subtitle">{active} active · {completed} completed</p>
        </div>
        <button className="btn btn-primary" onClick={openAdd}>+ New Goal</button>
      </div>

      {/* Stats */}
      <div className="grid-3" style={{ marginBottom: 24 }}>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: "#d4edda" }}>🎯</div>
          <div className="stat-value">{goals.length}</div>
          <div className="stat-label">Total Goals</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: "#fff3cd" }}>⚡</div>
          <div className="stat-value">{active}</div>
          <div className="stat-label">In Progress</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon" style={{ background: "#dbeafe" }}>🏆</div>
          <div className="stat-value">{completed}</div>
          <div className="stat-label">Completed</div>
        </div>
      </div>

      {/* Tabs */}
      <div className="tabs">
        {["all", "short-term", "long-term"].map(t => (
          <button
            key={t}
            className={`tab${activeTab === t ? " active" : ""}`}
            onClick={() => setActiveTab(t)}
          >
            {t === "all" ? "All Goals" : t === "short-term" ? "Short-term" : "Long-term"}
          </button>
        ))}
      </div>

      {/* Goals list */}
      {filtered.length === 0 ? (
        <div className="empty-state">
          <div className="empty-icon">🎯</div>
          <div className="empty-text">No goals yet. Set your first goal!</div>
          <button className="btn btn-primary btn-sm" style={{ marginTop: 12 }} onClick={openAdd}>
            Add Goal
          </button>
        </div>
      ) : (
        filtered.map(goal => (
          <div key={goal.id} className="goal-card">
            {/* Title row */}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 6 }}>
              <div>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 3 }}>
                  <span className="goal-title">{goal.title}</span>
                  {goal.progress >= 100 && <span style={{ fontSize: "1rem" }}>🏆</span>}
                </div>
                <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                  <span className={`badge ${goal.type === "Long-term" ? "badge-blue" : "badge-yellow"}`}>
                    {goal.type}
                  </span>
                  {goal.category && <span className="badge badge-gray">{goal.category}</span>}
                  {goal.deadline && <span className="badge badge-gray">📅 {goal.deadline}</span>}
                  {/* Show a "task-linked" badge when progress is auto-managed */}
                  {isTaskDriven(goal) && (
                    <span className="badge badge-green">📋 Task-linked</span>
                  )}
                </div>
              </div>
              <div style={{ display: "flex", gap: 6 }}>
                <button className="btn btn-sm btn-ghost" onClick={() => openEdit(goal)}>✎</button>
                <button className="btn btn-sm btn-danger" onClick={() => handleDelete(goal.id)}>✕</button>
              </div>
            </div>

            {goal.description && <p className="goal-desc">{goal.description}</p>}

            {/* Progress header */}
            <div className="goal-progress-text">
              <span>Progress</span>
              <span>
                {goal.progress || 0}%
                {isTaskDriven(goal)
                  ? ` · ${goal.completedTasks ?? 0} / ${goal.totalTasks} tasks`
                  : goal.target
                    ? ` · ${goal.target} ${goal.unit || ""}`
                    : ""}
              </span>
            </div>

            {/* Progress bar */}
            <div className="progress-bar">
              <div
                className="progress-fill"
                style={{
                  width: `${goal.progress || 0}%`,
                  background: goal.progress >= 100 ? "#2d6a4f" : "var(--green)",
                }}
              />
            </div>

            {/* Manual slider — only for goals NOT driven by planner tasks */}
            {!isTaskDriven(goal) && (
              <div style={{ display: "flex", alignItems: "center", gap: 10, marginTop: 10 }}>
                <span style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Update progress:</span>
                <input
                  type="range"
                  min="0" max="100" step="5"
                  value={goal.progress || 0}
                  onChange={e => updateProgress(goal.id, e.target.value)}
                  style={{ flex: 1, accentColor: "var(--green)" }}
                />
                <input
                  type="number"
                  min="0" max="100"
                  value={goal.progress || 0}
                  onChange={e => updateProgress(goal.id, e.target.value)}
                  style={{
                    width: 52, padding: "3px 7px",
                    border: "1.5px solid var(--border)",
                    borderRadius: 7, fontSize: "0.8rem", outline: "none",
                  }}
                />
                <span style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>%</span>
              </div>
            )}

            {/* Info note for task-driven goals */}
            {isTaskDriven(goal) && (
              <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 8 }}>
                Progress updates automatically when planner tasks are completed.
              </p>
            )}
          </div>
        ))
      )}

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setShowModal(false)}>
          <div className="modal">
            <div className="modal-header">
              <h3 className="modal-title">{editGoal ? "Edit Goal" : "New Goal"}</h3>
              <button className="btn btn-icon btn-ghost btn-sm" onClick={() => setShowModal(false)}>✕</button>
            </div>

            <div className="form-group">
              <label className="form-label">Goal Title *</label>
              <input
                className="form-input"
                placeholder="e.g., Complete Image Processing Course"
                value={form.title}
                onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Description</label>
              <textarea
                className="form-textarea"
                placeholder="Why is this goal important?"
                value={form.description}
                onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                style={{ minHeight: 60 }}
              />
            </div>

            <div className="grid-2">
           
              
              <div className="form-group">
                <label className="form-label">Category</label>
                <select
                  className="form-select"
                  value={form.category}
                  onChange={e => setForm(f => ({ ...f, category: e.target.value }))}
                >
                  {CATS.map(c => <option key={c}>{c}</option>)}
                </select>
              </div>
            </div>

            <div className="grid-2">
              <div className="form-group">
                <label className="form-label">Target (optional)</label>
                <input
                  className="form-input"
                  placeholder="e.g., 10"
                  value={form.target}
                  onChange={e => setForm(f => ({ ...f, target: e.target.value }))}
                />
              </div>
              <div className="form-group">
                <label className="form-label">Unit</label>
                <input
                  className="form-input"
                  placeholder="e.g., chapters, hours"
                  value={form.unit}
                  onChange={e => setForm(f => ({ ...f, unit: e.target.value }))}
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Deadline</label>
              <input
                type="date"
                className="form-input"
                value={form.deadline}
                onChange={e => setForm(f => ({ ...f, deadline: e.target.value }))}
              />
            </div>

            <div className="modal-footer">
              <button className="btn btn-ghost" onClick={() => setShowModal(false)}>Cancel</button>
              <button className="btn btn-primary" onClick={handleSubmit}>
                {editGoal ? "Save" : "Create Goal"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
