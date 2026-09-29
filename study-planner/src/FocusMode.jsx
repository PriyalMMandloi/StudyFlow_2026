import { useState, useEffect, useRef } from 'react'
import { useStore } from './useStore'
import { useToast } from './ToastContext'

const PHASES = [
  { id: 'work', label: 'Focus Time', duration: 25 * 60, color: '#8FAE8E' },
  { id: 'break', label: 'Short Break', duration: 5 * 60, color: '#AFC9A8' },
  { id: 'long', label: 'Long Break', duration: 15 * 60, color: '#C8DEC6' },
]

export default function FocusMode({ onExit }) {
  const store = useStore()
  const toast = useToast()
  const [phaseIdx, setPhaseIdx] = useState(0)
  const [timeLeft, setTimeLeft] = useState(PHASES[0].duration)
  const [running, setRunning] = useState(false)
  const [session, setSession] = useState(0)
  const [customWork, setCustomWork] = useState(25)
  const [customBreak, setCustomBreak] = useState(5)
  const [showSettings, setShowSettings] = useState(false)
  const intervalRef = useRef(null)
  const startTimeRef = useRef(null)
  const phase = PHASES[phaseIdx]

  useEffect(() => {
    if (running) {
      startTimeRef.current = Date.now()
      intervalRef.current = setInterval(() => {
        setTimeLeft(t => {
          if (t <= 1) {
            clearInterval(intervalRef.current)
            handlePhaseComplete()
            return 0
          }
          return t - 1
        })
      }, 1000)
    } else {
      clearInterval(intervalRef.current)
    }
    return () => clearInterval(intervalRef.current)
  }, [running, phaseIdx])

  function handlePhaseComplete() {
    setRunning(false)
    if (phaseIdx === 0) {
      // Log study time
      store.logStudyTime(customWork)
      setSession(s => s + 1)
      toast('Focus session complete! 🎉', 'success')
      // Auto switch to break
      const nextPhase = session > 0 && (session + 1) % 4 === 0 ? 2 : 1
      switchPhase(nextPhase)
    } else {
      toast('Break over! Ready to focus? 💪')
      switchPhase(0)
    }
  }

  function switchPhase(idx) {
    setPhaseIdx(idx)
    const durations = [customWork * 60, customBreak * 60, 15 * 60]
    setTimeLeft(durations[idx])
    setRunning(false)
  }

  function resetTimer() {
    setRunning(false)
    const durations = [customWork * 60, customBreak * 60, 15 * 60]
    setTimeLeft(durations[phaseIdx])
  }

  function applySettings() {
    setCustomWork(customWork)
    setCustomBreak(customBreak)
    resetTimer()
    setShowSettings(false)
    switchPhase(0)
  }

  const mins = Math.floor(timeLeft / 60)
  const secs = timeLeft % 60
  const durations = [customWork * 60, customBreak * 60, 15 * 60]
  const totalDuration = durations[phaseIdx]
  const progress = (totalDuration - timeLeft) / totalDuration

  // SVG ring
  const radius = 90
  const circumference = 2 * Math.PI * radius
  const dashOffset = circumference * (1 - progress)

  const phaseColors = [phase.color, '#AFC9A8', '#C8DEC6']
  const bgColors = ['rgba(143,174,142,0.1)', 'rgba(175,201,168,0.1)', 'rgba(200,222,198,0.1)']

  return (
    <div className="focus-overlay" style={{ background: '#FAFAFA' }}>
      {/* Top bar */}
      <div style={{ position: 'absolute', top: 20, left: 20, right: 20, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontFamily: 'DM Serif Display, serif', fontSize: '1.1rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: '1rem' }}>🌿</span> Focus Mode
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-ghost btn-sm" onClick={() => setShowSettings(true)}>⚙ Settings</button>
          <button className="btn btn-ghost btn-sm" onClick={onExit}>✕ Exit</button>
        </div>
      </div>

      {/* Phase tabs */}
      <div style={{ display: 'flex', gap: 6, background: 'var(--card)', padding: '4px', borderRadius: 12 }}>
        {['Focus', 'Short Break', 'Long Break'].map((label, i) => (
          <button key={i} onClick={() => switchPhase(i)}
            style={{ padding: '7px 16px', border: 'none', borderRadius: 9, fontSize: '0.82rem', fontWeight: 500, cursor: 'pointer', background: phaseIdx === i ? 'white' : 'transparent', color: phaseIdx === i ? 'var(--text)' : 'var(--text-muted)', boxShadow: phaseIdx === i ? 'var(--shadow)' : 'none', transition: 'all 0.2s' }}>
            {label}
          </button>
        ))}
      </div>

      {/* Timer Ring */}
      <div className="pomo-ring">
        <svg className="pomo-svg" viewBox="0 0 220 220">
          <circle cx="110" cy="110" r={radius} fill="none" stroke="var(--border)" strokeWidth="8" />
          <circle cx="110" cy="110" r={radius} fill="none" stroke={phase.color} strokeWidth="8"
            strokeLinecap="round" strokeDasharray={circumference} strokeDashoffset={dashOffset}
            style={{ transition: 'stroke-dashoffset 1s linear' }}
          />
        </svg>
        <div className="pomo-time">{String(mins).padStart(2, '0')}:{String(secs).padStart(2, '0')}</div>
        <div className="pomo-label">{phase.label}</div>
      </div>

      {/* Controls */}
      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <button className="btn btn-ghost" style={{ padding: '10px 20px' }} onClick={resetTimer}>↺ Reset</button>
        <button
          className="btn btn-primary"
          style={{ padding: '12px 36px', fontSize: '1rem', background: phase.color }}
          onClick={() => setRunning(r => !r)}
        >
          {running ? '⏸ Pause' : '▶ Start'}
        </button>
        <button className="btn btn-ghost" style={{ padding: '10px 20px' }} onClick={() => switchPhase((phaseIdx + 1) % 3)}>⏭ Skip</button>
      </div>

      {/* Session counter */}
      <div style={{ marginTop: 24, display: 'flex', gap: 6, alignItems: 'center' }}>
        {[0,1,2,3].map(i => (
          <div key={i} style={{ width: 10, height: 10, borderRadius: '50%', background: i < (session % 4) ? phase.color : 'var(--border)' }} />
        ))}
        <span style={{ marginLeft: 8, fontSize: '0.78rem', color: 'var(--text-muted)' }}>
          Session {session + 1} · {session} completed today
        </span>
      </div>

      {/* Settings modal */}
      {showSettings && (
        <div className="modal-overlay">
          <div className="modal" style={{ maxWidth: 340 }}>
            <div className="modal-header">
              <h3 className="modal-title">Timer Settings</h3>
              <button className="btn btn-icon btn-ghost btn-sm" onClick={() => setShowSettings(false)}>✕</button>
            </div>
            <div className="form-group">
              <label className="form-label">Focus Duration (minutes)</label>
              <input type="number" className="form-input" value={customWork} min="1" max="90" onChange={e => setCustomWork(Number(e.target.value))} />
            </div>
            <div className="form-group">
              <label className="form-label">Short Break (minutes)</label>
              <input type="number" className="form-input" value={customBreak} min="1" max="30" onChange={e => setCustomBreak(Number(e.target.value))} />
            </div>
            <div className="modal-footer">
              <button className="btn btn-ghost" onClick={() => setShowSettings(false)}>Cancel</button>
              <button className="btn btn-primary" onClick={applySettings}>Apply</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
