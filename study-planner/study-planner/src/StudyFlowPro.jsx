export default function StudyFlowPro() {
  return (
    <div className="page-enter">
      <div className="page-header">
        <div>
          <h1 className="page-title">StudyFlow Pro</h1>
          <p className="page-subtitle">A deeper view of your study habits</p>
        </div>
      </div>

      <section className="card-white" style={{ maxWidth: 760 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 18 }}>
          <div className="stat-icon" style={{ background: '#d4edda', marginBottom: 0 }} aria-hidden="true">
            ✦
          </div>
          <div>
            <h2 style={{ fontSize: '1.25rem', margin: 0 }}>Premium study analytics</h2>
            <p style={{ color: 'var(--text-muted)', fontSize: '0.82rem', marginTop: 3 }}>
              RevenueCat subscription access for StudyFlow Pro
            </p>
          </div>
        </div>

        <div style={{ display: 'grid', gap: 12, marginBottom: 20 }}>
          {[
            'See weekly study time and progress trends',
            'Review task completion and subject breakdowns',
            'Keep your study progress connected to your account',
          ].map((benefit) => (
            <div key={benefit} style={{ display: 'flex', alignItems: 'center', gap: 9, fontSize: '0.9rem' }}>
              <span style={{ color: '#557a5c' }} aria-hidden="true">✓</span>
              <span>{benefit}</span>
            </div>
          ))}
        </div>

        <div style={{ borderTop: '1px solid var(--border)', paddingTop: 14, color: 'var(--text-muted)', fontSize: '0.8rem', lineHeight: 1.5 }}>
          RevenueCat purchases are currently available in the Flutter Android and iOS apps. Web checkout is not configured for this browser app yet.
        </div>
      </section>
    </div>
  )
}