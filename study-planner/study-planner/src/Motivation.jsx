import { useState } from 'react'

const QUOTES = [
  { text: "The secret of getting ahead is getting started.", author: "Mark Twain" },
  { text: "Education is the most powerful weapon which you can use to change the world.", author: "Nelson Mandela" },
  { text: "The more that you read, the more things you will know.", author: "Dr. Seuss" },
  { text: "Learning is not attained by chance, it must be sought for with ardor and attended to with diligence.", author: "Abigail Adams" },
  { text: "An investment in knowledge pays the best interest.", author: "Benjamin Franklin" },
  { text: "Education is not the filling of a pail, but the lighting of a fire.", author: "W.B. Yeats" },
  { text: "The beautiful thing about learning is that nobody can take it away from you.", author: "B.B. King" },
  { text: "Live as if you were to die tomorrow. Learn as if you were to live forever.", author: "Mahatma Gandhi" },
  { text: "The mind is not a vessel to be filled, but a fire to be kindled.", author: "Plutarch" },
  { text: "Success is no accident. It is hard work, perseverance, learning, studying, sacrifice.", author: "Pelé" },
  { text: "The expert in anything was once a beginner.", author: "Helen Hayes" },
  { text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius" },
  { text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt" },
  { text: "The only way to do great work is to love what you do.", author: "Steve Jobs" },
  { text: "You don't have to be great to start, but you have to start to be great.", author: "Zig Ziglar" },
  { text: "Every expert was once a beginner. Every pro was once an amateur.", author: "Robin Sharma" },
  { text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt" },
  { text: "Success is the sum of small efforts, repeated day in and day out.", author: "Robert Collier" },
]

const TIPS = [
  { emoji: "🧠", title: "Spaced Repetition", desc: "Review material at increasing intervals to boost long-term retention." },
  { emoji: "🍅", title: "Pomodoro Technique", desc: "Study for 25 minutes, then take a 5-minute break. Repeat 4 times, then take a longer break." },
  { emoji: "🗺", title: "Mind Mapping", desc: "Create visual diagrams to connect ideas and concepts for better understanding." },
  { emoji: "🗣", title: "Active Recall", desc: "Test yourself frequently rather than passively re-reading notes." },
  { emoji: "😴", title: "Sleep Well", desc: "Sleep consolidates memories. Aim for 7-9 hours before important exams." },
  { emoji: "✍️", title: "Feynman Technique", desc: "Explain concepts in simple terms as if teaching a child — it reveals gaps in understanding." },
  { emoji: "🎯", title: "Set Clear Goals", desc: "Break large tasks into smaller, achievable milestones to stay motivated." },
  { emoji: "📵", title: "Eliminate Distractions", desc: "Put your phone away and use website blockers during study sessions." },
]

export default function Motivation() {
  const [quoteIdx, setQuoteIdx] = useState(() => Math.floor(Math.random() * QUOTES.length))
  const [animating, setAnimating] = useState(false)

  function nextQuote() {
    setAnimating(true)
    setTimeout(() => {
      setQuoteIdx(Math.floor(Math.random() * QUOTES.length))
      setAnimating(false)
    }, 200)
  }

  const q = QUOTES[quoteIdx]

  return (
    <div className="page-enter">
      <div className="page-header">
        <div>
          <h1 className="page-title">Motivation</h1>
          <p className="page-subtitle">Stay inspired on your learning journey</p>
        </div>
      </div>

      {/* Quote */}
      <div style={{ marginBottom: 28 }}>
        <div className="quote-card" style={{ opacity: animating ? 0 : 1, transition: 'opacity 0.2s' }}>
          <div className="quote-mark">"</div>
          <p className="quote-text">"{q.text}"</p>
          <p className="quote-author">— {q.author}</p>
        </div>
        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <button className="btn btn-secondary" onClick={nextQuote}>✨ New Quote</button>
        </div>
      </div>

      {/* All quotes carousel */}
      <div className="card-white" style={{ marginBottom: 24 }}>
        <div className="section-header">
          <span className="section-title">Quote Collection</span>
          <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{QUOTES.length} quotes</span>
        </div>
        <div style={{ maxHeight: 280, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {QUOTES.map((quote, i) => (
            <div key={i}
              onClick={() => setQuoteIdx(i)}
              style={{
                padding: '12px 14px', borderRadius: 10, border: `1.5px solid ${i === quoteIdx ? 'var(--green)' : 'var(--border)'}`,
                cursor: 'pointer', background: i === quoteIdx ? '#d4edda' : 'var(--white)',
                transition: 'all 0.2s'
              }}>
              <p style={{ fontSize: '0.85rem', fontStyle: 'italic', color: 'var(--text)', marginBottom: 3 }}>"{quote.text}"</p>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>— {quote.author}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Study Tips */}
      <div className="card-white">
        <div className="section-header">
          <span className="section-title">Study Tips & Techniques</span>
        </div>
        <div className="grid-2">
          {TIPS.map((tip, i) => (
            <div key={i} style={{ padding: '14px', borderRadius: 10, background: 'var(--card)', border: '1.5px solid var(--border)' }}>
              <div style={{ fontSize: '1.5rem', marginBottom: 6 }}>{tip.emoji}</div>
              <div style={{ fontWeight: 600, fontSize: '0.9rem', marginBottom: 4 }}>{tip.title}</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', lineHeight: 1.5 }}>{tip.desc}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
