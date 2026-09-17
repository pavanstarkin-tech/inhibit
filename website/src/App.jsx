import React, { useState } from 'react';
import { 
  Shield, 
  Smartphone, 
  Sparkles, 
  Lock, 
  Check, 
  EyeOff, 
  Zap, 
  Download, 
  ExternalLink, 
  Camera, 
  Play, 
  Music, 
  MessageSquare, 
  Sliders, 
  ChevronDown,
  Menu,
  X
} from 'lucide-react';
import confetti from 'canvas-confetti';

const FacebookIcon = ({ size = 20, className = '' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z" />
  </svg>
);

export default function App() {
  // Mobile Navigation State
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Simulator State
  const [activeTab, setActiveTab] = useState('home'); // 'home' | 'shield' | 'profile'
  const [simulatedBlockedCount, setSimulatedBlockedCount] = useState(164);
  const [isSimulatingSwipe, setIsSimulatingSwipe] = useState(false);
  const [simulationToast, setSimulationToast] = useState(null);

  // Intentional Post Mode Simulator
  const [unlocksRemaining, setUnlocksRemaining] = useState(4);
  const [isUnlocked, setIsUnlocked] = useState(false);

  // Granular Shield Toggles
  const [shieldReels, setShieldReels] = useState(true);
  const [shieldExplore, setShieldExplore] = useState(true);
  const [shieldShorts, setShieldShorts] = useState(true);

  // Impact Calculator State
  const [dailyHours, setDailyHours] = useState(2.5);

  // Modal State
  const [showDownloadModal, setShowDownloadModal] = useState(false);
  const [activeFaq, setActiveFaq] = useState(null);

  // Handle Reel Doomscroll Simulation
  const triggerSimulation = () => {
    if (isSimulatingSwipe) return;
    setIsSimulatingSwipe(true);
    setSimulationToast({
      title: '🚨 Reel Doomscroll Detected!',
      desc: 'Intercepted Reels player swipe container...',
      type: 'warning'
    });

    setTimeout(() => {
      setSimulationToast({
        title: '✨ Auto-Redirected to Home Feed',
        desc: 'Gracefully returned to chronological feed without closing app!',
        type: 'success'
      });
      setSimulatedBlockedCount(prev => prev + 1);
      setActiveTab('home');

      try {
        confetti({
          particleCount: 60,
          spread: 70,
          origin: { y: 0.7 }
        });
      } catch (_) {}

      setTimeout(() => {
        setIsSimulatingSwipe(false);
        setTimeout(() => setSimulationToast(null), 3000);
      }, 800);
    }, 1200);
  };

  const handleUnlockPostMode = () => {
    if (unlocksRemaining > 0 && !isUnlocked) {
      setUnlocksRemaining(prev => prev - 1);
      setIsUnlocked(true);
      try {
        confetti({ particleCount: 40, spread: 60, origin: { y: 0.6 } });
      } catch (_) {}
    }
  };

  // Calculate savings
  const yearlyHoursSaved = Math.round(dailyHours * 365);
  const lifetimeYearsGained = ((dailyHours * 365 * 60) / (24 * 365)).toFixed(1);

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* 1. TOP ANNOUNCEMENT BAR (INFINITE MARQUEE STRIP) */}
      <div className="top-marquee-container" title="Click to download APK" onClick={() => setShowDownloadModal(true)}>
        <div className="top-marquee-track">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="marquee-item">
              <span className="neo-badge green strip-badge">v1.0.0 RELEASE</span>
              <span>⚡ Zero Telemetry Android Shield — Instagram Reels & YouTube Shorts auto-redirection active!</span>
              <span style={{ opacity: 0.5 }}>•</span>
              <button 
                onClick={(e) => { e.stopPropagation(); setShowDownloadModal(true); }} 
                className="strip-link"
              >
                Download APK →
              </button>
              <span style={{ opacity: 0.4 }}>✦</span>
            </div>
          ))}
        </div>
      </div>

      {/* 2. NAVBAR */}
      <header style={{ position: 'sticky', top: 0, zIndex: 50, backgroundColor: 'rgba(255, 253, 240, 0.96)', backdropFilter: 'blur(8px)', borderBottom: '2.5px solid #000', padding: '12px 20px' }}>
        <div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          {/* Logo */}
          <a href="#" style={{ display: 'flex', alignItems: 'center', gap: '8px', textDecoration: 'none', color: '#000' }}>
            <img src="./logo.png" alt="Inhibit Logo" style={{ height: '32px', width: 'auto', objectFit: 'contain' }} onError={(e) => { e.target.style.display = 'none'; }} />
            <span style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: '22px', letterSpacing: '-0.03em', display: 'flex', alignItems: 'center', gap: '4px' }}>
              Inhibit<span style={{ color: 'var(--accent-yellow)' }}>★</span>
            </span>
          </a>

          {/* Desktop Nav Links */}
          <nav style={{ display: 'flex', alignItems: 'center', gap: '24px', fontWeight: 800, fontSize: '14px' }} className="hidden-on-mobile">
            <a href="#features" style={{ color: '#000', textDecoration: 'none' }}>Features</a>
            <a href="#simulator" style={{ color: '#000', textDecoration: 'none' }}>Interactive Demo</a>
            <a href="#services" style={{ color: '#000', textDecoration: 'none' }}>Protected Services</a>
            <a href="#privacy" style={{ color: '#000', textDecoration: 'none' }}>Privacy Manifesto</a>
            <a href="#faq" style={{ color: '#000', textDecoration: 'none' }}>FAQ</a>
          </nav>

          {/* Action & Mobile Hamburger Buttons */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <button 
              onClick={() => setShowDownloadModal(true)}
              className="neo-btn"
              style={{ padding: '8px 14px', fontSize: '13px' }}
            >
              <Download size={15} />
              <span>Get APK</span>
            </button>

            {/* Mobile Hamburger Toggle */}
            <button 
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="neo-btn white visible-on-mobile"
              style={{ padding: '8px 10px', fontSize: '14px' }}
              aria-label="Toggle Navigation Menu"
            >
              {mobileMenuOpen ? <X size={18} /> : <Menu size={18} />}
            </button>
          </div>
        </div>

        {/* Mobile Dropdown Drawer */}
        {mobileMenuOpen && (
          <div className="visible-on-mobile" style={{ flexDirection: 'column', gap: '12px', padding: '16px 0 8px', borderTop: '2px solid #000', marginTop: '12px' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontWeight: 800, fontSize: '14px' }}>
              <a 
                href="#features" 
                onClick={() => setMobileMenuOpen(false)}
                style={{ color: '#000', textDecoration: 'none', padding: '8px 12px', backgroundColor: '#fff', border: '1.5px solid #000', borderRadius: '8px', boxShadow: '2px 2px 0px #000' }}
              >
                Features
              </a>
              <a 
                href="#simulator" 
                onClick={() => setMobileMenuOpen(false)}
                style={{ color: '#000', textDecoration: 'none', padding: '8px 12px', backgroundColor: '#fff', border: '1.5px solid #000', borderRadius: '8px', boxShadow: '2px 2px 0px #000' }}
              >
                Interactive Phone Demo
              </a>
              <a 
                href="#services" 
                onClick={() => setMobileMenuOpen(false)}
                style={{ color: '#000', textDecoration: 'none', padding: '8px 12px', backgroundColor: '#fff', border: '1.5px solid #000', borderRadius: '8px', boxShadow: '2px 2px 0px #000' }}
              >
                Protected Services
              </a>
              <a 
                href="#privacy" 
                onClick={() => setMobileMenuOpen(false)}
                style={{ color: '#000', textDecoration: 'none', padding: '8px 12px', backgroundColor: '#fff', border: '1.5px solid #000', borderRadius: '8px', boxShadow: '2px 2px 0px #000' }}
              >
                Privacy Manifesto
              </a>
              <a 
                href="#faq" 
                onClick={() => setMobileMenuOpen(false)}
                style={{ color: '#000', textDecoration: 'none', padding: '8px 12px', backgroundColor: '#fff', border: '1.5px solid #000', borderRadius: '8px', boxShadow: '2px 2px 0px #000' }}
              >
                FAQ
              </a>
            </div>
          </div>
        )}
      </header>

      {/* 3. HERO SECTION */}
      <section style={{ padding: '48px 20px', borderBottom: '2.5px solid #000', backgroundColor: '#FFFDF0' }}>
        <div className="container" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '36px', alignItems: 'center' }}>
          
          {/* Left Column: Value Prop */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
            <div className="hidden-on-mobile" style={{ flexWrap: 'wrap', gap: '8px' }}>
              <span className="neo-badge green" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span className="pulse-dot"></span> 100% LOCAL ON-DEVICE
              </span>
              <span className="neo-badge pink">ZERO TELEMETRY</span>
              <span className="neo-badge blue">NO APP EXITS</span>
            </div>

            <h1 style={{ fontSize: 'clamp(34px, 5.5vw, 60px)', fontWeight: 900, color: '#000', lineHeight: 1.08 }}>
              SCROLL LESS.<br />
              <span style={{ backgroundColor: 'var(--accent-yellow)', padding: '2px 8px', border: '2.5px solid #000', display: 'inline-block', boxShadow: '4px 4px 0px #000', transform: 'rotate(-1deg)', marginTop: '6px' }}>
                LIVE MORE.
              </span>
            </h1>

            <p style={{ fontSize: '16px', fontWeight: 700, color: '#333', maxWidth: '580px', lineHeight: 1.5 }}>
              The first privacy-engineered Android guard that intercepts algorithmic short-form loops in <span style={{ textDecoration: 'underline', textDecorationColor: '#FF6B6B', textDecorationThickness: '2px' }}>Instagram Reels</span> and <span style={{ textDecoration: 'underline', textDecorationColor: '#FF6B6B', textDecorationThickness: '2px' }}>YouTube Shorts</span> and seamlessly redirects you to your chronological feed — <strong>without closing your apps.</strong>
            </p>

            <div className="hero-cta-group" style={{ display: 'flex', flexWrap: 'wrap', gap: '12px', paddingTop: '6px' }}>
              <button 
                onClick={() => setShowDownloadModal(true)}
                className="neo-btn"
                style={{ fontSize: '15px', padding: '12px 20px', backgroundColor: 'var(--accent-yellow)' }}
              >
                <Download size={18} />
                <span>Download Inhibit v1.0.0</span>
              </button>

              <button 
                onClick={triggerSimulation}
                className="neo-btn green"
                style={{ fontSize: '15px', padding: '12px 20px' }}
              >
                <Zap size={18} />
                <span>Test Live Simulation</span>
              </button>
            </div>

            {/* Quick Proof Metrics */}
            <div className="proof-metrics-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px', paddingTop: '10px', maxWidth: '500px' }}>
              <div className="neo-card" style={{ padding: '12px 8px', textAlign: 'center', backgroundColor: '#fff' }}>
                <div style={{ fontSize: '22px', fontWeight: 900 }}>0ms</div>
                <div style={{ fontSize: '9px', fontWeight: 800, color: '#666', textTransform: 'uppercase' }}>Cloud Latency</div>
              </div>
              <div className="neo-card" style={{ padding: '12px 8px', textAlign: 'center', backgroundColor: 'var(--accent-pink)' }}>
                <div style={{ fontSize: '22px', fontWeight: 900 }}>100%</div>
                <div style={{ fontSize: '9px', fontWeight: 800, color: '#666', textTransform: 'uppercase' }}>Local & Private</div>
              </div>
              <div className="neo-card" style={{ padding: '12px 8px', textAlign: 'center', backgroundColor: 'var(--accent-yellow)' }}>
                <div style={{ fontSize: '22px', fontWeight: 900 }}>4 Daily</div>
                <div style={{ fontSize: '9px', fontWeight: 800, color: '#666', textTransform: 'uppercase' }}>Post Unlocks</div>
              </div>
            </div>
          </div>

          {/* Right Column: Live Interactive App Simulator */}
          <div id="simulator" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            
            {/* Interactive Control Pill */}
            <div style={{ marginBottom: '14px', backgroundColor: '#FFFFFF', border: '2.5px solid #000', padding: '8px 16px', borderRadius: '999px', boxShadow: '3px 3px 0px #000', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span className="pulse-dot"></span>
              <span style={{ fontSize: '11px', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Interactive Phone Simulator</span>
            </div>

            {/* Simulated Phone Container */}
            <div className="phone-mockup">
              <div className="phone-island"></div>

              {/* Status Bar */}
              <div style={{ position: 'absolute', top: '8px', left: '24px', right: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '11px', fontWeight: 800, zIndex: 10 }}>
                <span>9:41</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <span>5G</span>
                  <span>100%</span>
                </div>
              </div>

              {/* Toast Notification Simulation */}
              {simulationToast && (
                <div style={{
                  position: 'absolute',
                  top: '48px',
                  left: '12px',
                  right: '12px',
                  padding: '12px',
                  borderRadius: '12px',
                  border: '2.5px solid #000',
                  zIndex: 30,
                  boxShadow: '4px 4px 0px #000',
                  backgroundColor: simulationToast.type === 'warning' ? 'var(--accent-yellow)' : 'var(--accent-green)'
                }}>
                  <div style={{ fontWeight: 900, fontSize: '12px' }}>{simulationToast.title}</div>
                  <div style={{ fontSize: '10px', fontWeight: 700, opacity: 0.9 }}>{simulationToast.desc}</div>
                </div>
              )}

              {/* Phone Content Screen */}
              <div className="phone-screen">
                <div className="phone-body">
                  
                  {/* TAB 1: HOME SCREEN */}
                  {activeTab === 'home' && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                      {/* Top Header */}
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <span style={{ fontWeight: 900, fontSize: '18px' }}>Inhibit</span>
                          <span style={{ color: 'var(--accent-yellow)', fontSize: '16px' }}>★</span>
                        </div>
                        <div style={{ width: '32px', height: '32px', borderRadius: '8px', border: '2px solid #000', backgroundColor: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '2px 2px 0px #000' }}>
                          <Sliders size={14} />
                        </div>
                      </div>

                      {/* Banner */}
                      <div className="neo-card" style={{ padding: '12px', backgroundColor: 'var(--accent-pink)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                          <div style={{ fontWeight: 900, fontSize: '13px', lineHeight: 1.2 }}>SCROLL LESS.</div>
                          <div style={{ fontWeight: 900, fontSize: '13px', lineHeight: 1.2 }}>LIVE MORE.</div>
                        </div>
                        <span style={{ fontSize: '24px' }}>😊</span>
                      </div>

                      {/* Stat Card */}
                      <div className="neo-card" style={{ padding: '12px', backgroundColor: 'var(--accent-yellow)' }}>
                        <div style={{ fontSize: '9px', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Doomscrolls Intercepted</div>
                        <div style={{ display: 'flex', alignItems: 'baseline', gap: '6px', marginTop: '4px' }}>
                          <div style={{ fontSize: '32px', fontWeight: 900 }}>{simulatedBlockedCount}</div>
                          <div style={{ fontSize: '11px', fontWeight: 700, color: '#444' }}>today</div>
                        </div>
                        <div style={{ marginTop: '6px', backgroundColor: 'rgba(255, 255, 255, 0.85)', border: '1.5px solid #000', borderRadius: '4px', padding: '2px 8px', fontSize: '9px', fontWeight: 800, display: 'inline-block' }}>
                          📊 Total Reels Scrolled: 214
                        </div>
                      </div>

                      {/* Protected Services Title */}
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '4px' }}>
                        <span style={{ fontSize: '10px', fontWeight: 900, textTransform: 'uppercase' }}>Protected Services</span>
                        <span style={{ fontSize: '9px', fontWeight: 700, color: '#666' }}>Settings →</span>
                      </div>

                      {/* Services Grid (2 Active, 2 Coming Soon in simulator) */}
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '8px' }}>
                        {/* Instagram (Active) */}
                        <div className="neo-card" style={{ padding: '10px', backgroundColor: '#fff', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', minHeight: '75px' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <div style={{ width: '28px', height: '28px', borderRadius: '6px', backgroundColor: 'var(--accent-pink)', border: '1.5px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                              <Camera size={14} />
                            </div>
                            <span style={{ fontSize: '8px', fontWeight: 900, padding: '2px 6px', backgroundColor: 'var(--accent-green)', border: '1px solid #000', borderRadius: '4px' }}>Active</span>
                          </div>
                          <div style={{ fontWeight: 900, fontSize: '12px', marginTop: '6px' }}>Instagram</div>
                        </div>

                        {/* YouTube (Active) */}
                        <div className="neo-card" style={{ padding: '10px', backgroundColor: '#fff', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', minHeight: '75px' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <div style={{ width: '28px', height: '28px', borderRadius: '6px', backgroundColor: 'var(--accent-coral)', border: '1.5px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
                              <Play size={14} fill="currentColor" />
                            </div>
                            <span style={{ fontSize: '8px', fontWeight: 900, padding: '2px 6px', backgroundColor: 'var(--accent-green)', border: '1px solid #000', borderRadius: '4px' }}>Active</span>
                          </div>
                          <div style={{ fontWeight: 900, fontSize: '12px', marginTop: '6px' }}>YouTube</div>
                        </div>

                        {/* TikTok (Coming Soon) */}
                        <div className="neo-card" style={{ padding: '10px', backgroundColor: '#F8FAFC', opacity: 0.6, borderStyle: 'dashed', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', minHeight: '75px' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <div style={{ width: '28px', height: '28px', borderRadius: '6px', backgroundColor: '#E2E8F0', border: '1px solid #94A3B8', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748B' }}>
                              <Music size={14} />
                            </div>
                            <span style={{ fontSize: '8px', fontWeight: 800, padding: '2px 5px', backgroundColor: '#E2E8F0', borderRadius: '4px', color: '#64748B' }}>Soon</span>
                          </div>
                          <div style={{ fontWeight: 800, fontSize: '12px', color: '#64748B', marginTop: '6px' }}>TikTok</div>
                        </div>

                        {/* Facebook (Coming Soon) */}
                        <div className="neo-card" style={{ padding: '10px', backgroundColor: '#F8FAFC', opacity: 0.6, borderStyle: 'dashed', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', minHeight: '75px' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <div style={{ width: '28px', height: '28px', borderRadius: '6px', backgroundColor: '#E2E8F0', border: '1px solid #94A3B8', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748B' }}>
                              <FacebookIcon size={14} />
                            </div>
                            <span style={{ fontSize: '8px', fontWeight: 800, padding: '2px 5px', backgroundColor: '#E2E8F0', borderRadius: '4px', color: '#64748B' }}>Soon</span>
                          </div>
                          <div style={{ fontWeight: 800, fontSize: '12px', color: '#64748B', marginTop: '6px' }}>Facebook</div>
                        </div>
                      </div>

                      {/* Trigger Simulation Button */}
                      <button 
                        onClick={triggerSimulation}
                        disabled={isSimulatingSwipe}
                        className="neo-btn green"
                        style={{ width: '100%', padding: '10px', fontSize: '12px', marginTop: '4px' }}
                      >
                        <Zap size={14} />
                        <span>{isSimulatingSwipe ? 'Simulating Intercept...' : 'Simulate Reel Doomscroll'}</span>
                      </button>
                    </div>
                  )}

                  {/* TAB 2: SHIELD SCREEN */}
                  {activeTab === 'shield' && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', paddingTop: '4px' }}>
                      <div style={{ textAlign: 'center', fontWeight: 900, fontSize: '14px' }}>Shield & Post Mode</div>

                      {/* Intentional Post Mode */}
                      <div className="neo-card" style={{ padding: '12px', backgroundColor: '#fff' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <div style={{ width: '28px', height: '28px', borderRadius: '6px', backgroundColor: 'var(--accent-blue)', border: '1.5px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <Zap size={14} />
                          </div>
                          <div style={{ fontWeight: 900, fontSize: '12px' }}>Intentional Post Mode</div>
                        </div>
                        <div style={{ fontSize: '10px', color: '#555', marginTop: '4px', fontWeight: 600 }}>
                          Get 4 daily unlocks to create & post content distraction-free.
                        </div>
                        <div style={{ textAlign: 'center', padding: '8px 0' }}>
                          <div style={{ fontSize: '24px', fontWeight: 900 }}>{unlocksRemaining} / 4</div>
                          <div style={{ fontSize: '9px', fontWeight: 700, color: '#777' }}>unlocks remaining today</div>
                        </div>
                        <button 
                          onClick={handleUnlockPostMode}
                          disabled={isUnlocked || unlocksRemaining === 0}
                          className="neo-btn"
                          style={{ width: '100%', padding: '8px', fontSize: '11px', backgroundColor: 'var(--accent-yellow)' }}
                        >
                          {isUnlocked ? 'POSTING UNLOCKED (30m)' : 'UNLOCK FOR 30 MIN'}
                        </button>
                      </div>

                      {/* Live Toggles */}
                      <div className="neo-card" style={{ padding: '12px', backgroundColor: '#fff', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                        <div style={{ fontSize: '10px', fontWeight: 900, textTransform: 'uppercase', color: '#333' }}>Device App Shielding</div>
                        
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '6px', borderTop: '1px solid #eee' }}>
                          <div>
                            <div style={{ fontWeight: 900, fontSize: '12px' }}>Instagram Reels</div>
                            <div style={{ fontSize: '9px', color: '#666' }}>Auto-redirects to Home</div>
                          </div>
                          <input 
                            type="checkbox" 
                            checked={shieldReels} 
                            onChange={(e) => setShieldReels(e.target.checked)} 
                            style={{ width: '16px', height: '16px', cursor: 'pointer', accentColor: '#000' }}
                          />
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '6px', borderTop: '1px solid #eee' }}>
                          <div>
                            <div style={{ fontWeight: 900, fontSize: '12px' }}>Instagram Explore</div>
                            <div style={{ fontSize: '9px', color: '#666' }}>Blocks recommendation grid</div>
                          </div>
                          <input 
                            type="checkbox" 
                            checked={shieldExplore} 
                            onChange={(e) => setShieldExplore(e.target.checked)} 
                            style={{ width: '16px', height: '16px', cursor: 'pointer', accentColor: '#000' }}
                          />
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '6px', borderTop: '1px solid #eee' }}>
                          <div>
                            <div style={{ fontWeight: 900, fontSize: '12px' }}>YouTube Shorts</div>
                            <div style={{ fontSize: '9px', color: '#666' }}>Auto-redirects to Home</div>
                          </div>
                          <input 
                            type="checkbox" 
                            checked={shieldShorts} 
                            onChange={(e) => setShieldShorts(e.target.checked)} 
                            style={{ width: '16px', height: '16px', cursor: 'pointer', accentColor: '#000' }}
                          />
                        </div>
                      </div>
                    </div>
                  )}

                  {/* TAB 3: PROFILE SCREEN */}
                  {activeTab === 'profile' && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', paddingTop: '4px' }}>
                      <div style={{ textAlign: 'center', fontWeight: 900, fontSize: '14px' }}>You & Privacy</div>

                      {/* Impact */}
                      <div className="neo-card" style={{ padding: '12px', backgroundColor: 'var(--accent-purple)' }}>
                        <div style={{ fontSize: '9px', fontWeight: 900, textTransform: 'uppercase' }}>YOUR IMPACT</div>
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '4px', marginTop: '8px', textAlign: 'center' }}>
                          <div style={{ backgroundColor: '#fff', border: '1.5px solid #000', borderRadius: '6px', padding: '4px' }}>
                            <div style={{ fontWeight: 900, fontSize: '13px' }}>3.5h</div>
                            <div style={{ fontSize: '7px', fontWeight: 700, color: '#666' }}>saved daily</div>
                          </div>
                          <div style={{ backgroundColor: '#fff', border: '1.5px solid #000', borderRadius: '6px', padding: '4px' }}>
                            <div style={{ fontWeight: 900, fontSize: '13px' }}>1,278h</div>
                            <div style={{ fontSize: '7px', fontWeight: 700, color: '#666' }}>yearly</div>
                          </div>
                          <div style={{ backgroundColor: '#fff', border: '1.5px solid #000', borderRadius: '6px', padding: '4px' }}>
                            <div style={{ fontWeight: 900, fontSize: '13px' }}>9.9</div>
                            <div style={{ fontSize: '7px', fontWeight: 700, color: '#666' }}>years gained</div>
                          </div>
                        </div>
                      </div>

                      {/* Privacy Guarantee */}
                      <div className="neo-card" style={{ padding: '12px', backgroundColor: '#fff', display: 'flex', flexDirection: 'column', gap: '6px', fontSize: '11px' }}>
                        <div style={{ fontWeight: 900, fontSize: '10px', textTransform: 'uppercase', color: '#333' }}>Privacy Guarantee</div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 800 }}>
                          <Check size={14} style={{ color: '#10B981' }} /> No server analytics
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 800 }}>
                          <Check size={14} style={{ color: '#10B981' }} /> No cloud tracking
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 800 }}>
                          <Check size={14} style={{ color: '#10B981' }} /> Zero account required
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 800 }}>
                          <Check size={14} style={{ color: '#10B981' }} /> Sandboxed local rules
                        </div>
                      </div>
                    </div>
                  )}

                </div>

                {/* Bottom Navigation Bar */}
                <div className="phone-bottom-nav">
                  <div 
                    onClick={() => setActiveTab('home')}
                    className={`nav-tab-item ${activeTab === 'home' ? 'active' : ''}`}
                  >
                    <Smartphone size={16} />
                    <span style={{ fontSize: '9px', fontWeight: 900, marginTop: '2px' }}>Home</span>
                  </div>

                  <div 
                    onClick={() => setActiveTab('shield')}
                    className={`nav-tab-item ${activeTab === 'shield' ? 'active shield' : ''}`}
                  >
                    <Shield size={16} />
                    <span style={{ fontSize: '9px', fontWeight: 900, marginTop: '2px' }}>Shield</span>
                  </div>

                  <div 
                    onClick={() => setActiveTab('profile')}
                    className={`nav-tab-item ${activeTab === 'profile' ? 'active profile' : ''}`}
                  >
                    <Lock size={16} />
                    <span style={{ fontSize: '9px', fontWeight: 900, marginTop: '2px' }}>Profile</span>
                  </div>
                </div>
              </div>
            </div>

            <p style={{ fontSize: '12px', fontWeight: 800, color: '#666', marginTop: '12px', textAlign: 'center' }}>
              💡 Click the bottom tabs inside the phone to explore real Inhibit screens!
            </p>
          </div>

        </div>
      </section>

      {/* 4. THE 3 NON-NEGOTIABLES (FEATURES) */}
      <section id="features" style={{ padding: '80px 20px', borderBottom: '2.5px solid #000', backgroundColor: '#FFFFFF' }}>
        <div className="container">
          
          <div style={{ textAlign: 'center', maxWidth: '720px', margin: '0 auto 60px' }}>
            <span className="neo-badge pink" style={{ marginBottom: '12px' }}>HOW INHIBIT DIFFERS</span>
            <h2 style={{ fontSize: 'clamp(28px, 4vw, 44px)', fontWeight: 900, color: '#000' }}>
              Built for people who still want to use Instagram & YouTube.
            </h2>
            <p style={{ fontSize: '16px', fontWeight: 700, color: '#555', marginTop: '12px' }}>
              Traditional blockers lock you out or crash your apps completely. Inhibit removes the algorithmic trap while keeping all useful communication intact.
            </p>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '28px' }}>
            {/* Feature 1 */}
            <div className="neo-card" style={{ padding: '28px', backgroundColor: '#FFFDF0', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ width: '56px', height: '56px', borderRadius: '12px', backgroundColor: 'var(--accent-green)', border: '2.5px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '3px 3px 0px #000', marginBottom: '20px' }}>
                  <EyeOff size={28} />
                </div>
                <h3 style={{ fontSize: '22px', fontWeight: 900, marginBottom: '10px' }}>Zero App Exits</h3>
                <p style={{ fontSize: '14px', fontWeight: 700, color: '#444', lineHeight: 1.6 }}>
                  When you accidentally swipe into Reels or Shorts, Inhibit doesn't close your app or kick you back to your phone launcher. It gracefully navigates back to your standard feed so you can continue chatting with friends and checking normal posts.
                </p>
              </div>
              <div style={{ marginTop: '20px', paddingTop: '14px', borderTop: '2px solid rgba(0,0,0,0.1)', display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px', fontWeight: 900 }}>
                <Check size={16} style={{ color: '#10B981' }} />
                <span>DMs & Feed Posts remain 100% functional</span>
              </div>
            </div>

            {/* Feature 2 */}
            <div className="neo-card" style={{ padding: '28px', backgroundColor: 'var(--accent-pink)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ width: '56px', height: '56px', borderRadius: '12px', backgroundColor: 'var(--accent-yellow)', border: '2.5px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '3px 3px 0px #000', marginBottom: '20px' }}>
                  <Zap size={28} />
                </div>
                <h3 style={{ fontSize: '22px', fontWeight: 900, marginBottom: '10px' }}>Intentional Post Mode</h3>
                <p style={{ fontSize: '14px', fontWeight: 700, color: '#444', lineHeight: 1.6 }}>
                  Need to post a story, upload a video, or reply to followers? Inhibit grants you 4 intentional 30-minute creation sessions daily. Upload your content without falling into the infinite scroll loop.
                </p>
              </div>
              <div style={{ marginTop: '20px', paddingTop: '14px', borderTop: '2px solid rgba(0,0,0,0.1)', display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px', fontWeight: 900 }}>
                <Check size={16} style={{ color: '#10B981' }} />
                <span>4 Daily 30-Min Unlocks</span>
              </div>
            </div>

            {/* Feature 3 */}
            <div className="neo-card" style={{ padding: '28px', backgroundColor: 'var(--accent-purple)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ width: '56px', height: '56px', borderRadius: '12px', backgroundColor: '#fff', border: '2.5px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '3px 3px 0px #000', marginBottom: '20px' }}>
                  <Lock size={28} />
                </div>
                <h3 style={{ fontSize: '22px', fontWeight: 900, marginBottom: '10px' }}>Zero Cloud Telemetry</h3>
                <p style={{ fontSize: '14px', fontWeight: 700, color: '#444', lineHeight: 1.6 }}>
                  Your screen contents and activity never leave your phone. Inhibit runs a sandboxed, local accessibility detector directly on your device CPU. No server calls, no telemetry, no tracking databases.
                </p>
              </div>
              <div style={{ marginTop: '20px', paddingTop: '14px', borderTop: '2px solid rgba(0,0,0,0.1)', display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px', fontWeight: 900 }}>
                <Check size={16} style={{ color: '#10B981' }} />
                <span>100% Offline Compatible</span>
              </div>
            </div>
          </div>

        </div>
      </section>

      {/* 5. PROTECTED SERVICES GRID (MATCHING APP) */}
      <section id="services" style={{ padding: '80px 20px', borderBottom: '2.5px solid #000', backgroundColor: '#FFFDF0' }}>
        <div className="container">
          
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: '40px', flexWrap: 'wrap', gap: '16px' }}>
            <div>
              <span className="neo-badge blue" style={{ marginBottom: '10px' }}>SUPPORTED ECOSYSTEM</span>
              <h2 style={{ fontSize: 'clamp(28px, 4vw, 44px)', fontWeight: 900, color: '#000' }}>
                Protected Services
              </h2>
              <p style={{ fontSize: '15px', fontWeight: 700, color: '#555', marginTop: '6px' }}>
                Active protection for YouTube and Instagram, with remaining platforms coming in upcoming releases.
              </p>
            </div>
            <div className="neo-badge green" style={{ fontSize: '12px', padding: '6px 14px' }}>
              ⚡ 2 Active • 6 Coming Soon
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '20px' }}>
            
            {/* INSTAGRAM (ACTIVE) */}
            <div className="neo-card" style={{ padding: '20px', backgroundColor: '#fff', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '14px' }}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '10px', backgroundColor: 'var(--accent-pink)', border: '2px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '2px 2px 0px #000' }}>
                    <Camera size={22} color="#000" />
                  </div>
                  <span className="neo-badge green" style={{ fontSize: '10px' }}>ACTIVE SHIELD</span>
                </div>
                <h3 style={{ fontSize: '20px', fontWeight: 900 }}>Instagram</h3>
                <p style={{ fontSize: '13px', fontWeight: 700, color: '#555', marginTop: '8px', lineHeight: 1.5 }}>
                  Auto-redirects full-screen Reels viewer back to Home feed. Blocks algorithmic Explore recommendations.
                </p>
              </div>
              <div style={{ marginTop: '16px', paddingTop: '12px', borderTop: '1px solid #eee', fontSize: '11px', fontWeight: 800, color: '#15803d', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Check size={14} /> DMs & Home feed allowed
              </div>
            </div>

            {/* YOUTUBE (ACTIVE) */}
            <div className="neo-card" style={{ padding: '20px', backgroundColor: '#fff', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '14px' }}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '10px', backgroundColor: 'var(--accent-coral)', border: '2px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '2px 2px 0px #000', color: '#fff' }}>
                    <Play size={22} fill="currentColor" />
                  </div>
                  <span className="neo-badge green" style={{ fontSize: '10px' }}>ACTIVE SHIELD</span>
                </div>
                <h3 style={{ fontSize: '20px', fontWeight: 900 }}>YouTube</h3>
                <p style={{ fontSize: '13px', fontWeight: 700, color: '#555', marginTop: '8px', lineHeight: 1.5 }}>
                  Intercepts YouTube Shorts player and redirects back to standard video recommendations & subscriptions.
                </p>
              </div>
              <div style={{ marginTop: '16px', paddingTop: '12px', borderTop: '1px solid #eee', fontSize: '11px', fontWeight: 800, color: '#15803d', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Check size={14} /> Long-form videos allowed
              </div>
            </div>

            {/* TIKTOK (COMING SOON) */}
            <div className="neo-card" style={{ padding: '20px', backgroundColor: '#F8FAFC', opacity: 0.6, borderStyle: 'dashed', borderColor: '#94A3B8', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '14px' }}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '10px', backgroundColor: '#E2E8F0', border: '1.5px solid #94A3B8', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748B' }}>
                    <Music size={22} />
                  </div>
                  <span className="neo-badge gray" style={{ fontSize: '10px' }}>COMING SOON</span>
                </div>
                <h3 style={{ fontSize: '20px', fontWeight: 800, color: '#475569' }}>TikTok</h3>
                <p style={{ fontSize: '13px', fontWeight: 600, color: '#64748B', marginTop: '8px', lineHeight: 1.5 }}>
                  Upcoming rule probe for algorithmic feed interception and timer limits.
                </p>
              </div>
              <div style={{ marginTop: '16px', paddingTop: '12px', borderTop: '1px solid #E2E8F0', fontSize: '11px', fontWeight: 700, color: '#94A3B8' }}>
                In Calibration
              </div>
            </div>

            {/* FACEBOOK (COMING SOON) */}
            <div className="neo-card" style={{ padding: '20px', backgroundColor: '#F8FAFC', opacity: 0.6, borderStyle: 'dashed', borderColor: '#94A3B8', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '14px' }}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '10px', backgroundColor: '#E2E8F0', border: '1.5px solid #94A3B8', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748B' }}>
                    <FacebookIcon size={22} />
                  </div>
                  <span className="neo-badge gray" style={{ fontSize: '10px' }}>COMING SOON</span>
                </div>
                <h3 style={{ fontSize: '20px', fontWeight: 800, color: '#475569' }}>Facebook</h3>
                <p style={{ fontSize: '13px', fontWeight: 600, color: '#64748B', marginTop: '8px', lineHeight: 1.5 }}>
                  Facebook Reels and suggested video loops filter integration.
                </p>
              </div>
              <div style={{ marginTop: '16px', paddingTop: '12px', borderTop: '1px solid #E2E8F0', fontSize: '11px', fontWeight: 700, color: '#94A3B8' }}>
                In Calibration
              </div>
            </div>

            {/* X / TWITTER (COMING SOON) */}
            <div className="neo-card" style={{ padding: '20px', backgroundColor: '#F8FAFC', opacity: 0.6, borderStyle: 'dashed', borderColor: '#94A3B8', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '14px' }}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '10px', backgroundColor: '#E2E8F0', border: '1.5px solid #94A3B8', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748B' }}>
                    <span style={{ fontWeight: 900, fontSize: '18px' }}>𝕏</span>
                  </div>
                  <span className="neo-badge gray" style={{ fontSize: '10px' }}>COMING SOON</span>
                </div>
                <h3 style={{ fontSize: '20px', fontWeight: 800, color: '#475569' }}>X (Twitter)</h3>
                <p style={{ fontSize: '13px', fontWeight: 600, color: '#64748B', marginTop: '8px', lineHeight: 1.5 }}>
                  Immersive video feed blocker & timeline algorithmic declutter.
                </p>
              </div>
              <div style={{ marginTop: '16px', paddingTop: '12px', borderTop: '1px solid #E2E8F0', fontSize: '11px', fontWeight: 700, color: '#94A3B8' }}>
                In Calibration
              </div>
            </div>

            {/* REDDIT (COMING SOON) */}
            <div className="neo-card" style={{ padding: '20px', backgroundColor: '#F8FAFC', opacity: 0.6, borderStyle: 'dashed', borderColor: '#94A3B8', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '14px' }}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '10px', backgroundColor: '#E2E8F0', border: '1.5px solid #94A3B8', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748B' }}>
                    <MessageSquare size={22} />
                  </div>
                  <span className="neo-badge gray" style={{ fontSize: '10px' }}>COMING SOON</span>
                </div>
                <h3 style={{ fontSize: '20px', fontWeight: 800, color: '#475569' }}>Reddit</h3>
                <p style={{ fontSize: '13px', fontWeight: 600, color: '#64748B', marginTop: '8px', lineHeight: 1.5 }}>
                  Vertical media swipe player filter with text discussion preservation.
                </p>
              </div>
              <div style={{ marginTop: '16px', paddingTop: '12px', borderTop: '1px solid #E2E8F0', fontSize: '11px', fontWeight: 700, color: '#94A3B8' }}>
                In Calibration
              </div>
            </div>

            {/* SNAPCHAT (COMING SOON) */}
            <div className="neo-card" style={{ padding: '20px', backgroundColor: '#F8FAFC', opacity: 0.6, borderStyle: 'dashed', borderColor: '#94A3B8', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '14px' }}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '10px', backgroundColor: '#E2E8F0', border: '1.5px solid #94A3B8', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748B' }}>
                    <Sparkles size={22} />
                  </div>
                  <span className="neo-badge gray" style={{ fontSize: '10px' }}>COMING SOON</span>
                </div>
                <h3 style={{ fontSize: '20px', fontWeight: 800, color: '#475569' }}>Snapchat</h3>
                <p style={{ fontSize: '13px', fontWeight: 600, color: '#64748B', marginTop: '8px', lineHeight: 1.5 }}>
                  Spotlight infinite feed shield with direct messaging preservation.
                </p>
              </div>
              <div style={{ marginTop: '16px', paddingTop: '12px', borderTop: '1px solid #E2E8F0', fontSize: '11px', fontWeight: 700, color: '#94A3B8' }}>
                In Calibration
              </div>
            </div>

            {/* LINKEDIN (COMING SOON) */}
            <div className="neo-card" style={{ padding: '20px', backgroundColor: '#F8FAFC', opacity: 0.6, borderStyle: 'dashed', borderColor: '#94A3B8', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '14px' }}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '10px', backgroundColor: '#E2E8F0', border: '1.5px solid #94A3B8', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748B' }}>
                    <span style={{ fontWeight: 900, fontSize: '14px' }}>in</span>
                  </div>
                  <span className="neo-badge gray" style={{ fontSize: '10px' }}>COMING SOON</span>
                </div>
                <h3 style={{ fontSize: '20px', fontWeight: 800, color: '#475569' }}>LinkedIn</h3>
                <p style={{ fontSize: '13px', fontWeight: 600, color: '#64748B', marginTop: '8px', lineHeight: 1.5 }}>
                  Short-form video stream filter while maintaining professional networking.
                </p>
              </div>
              <div style={{ marginTop: '16px', paddingTop: '12px', borderTop: '1px solid #E2E8F0', fontSize: '11px', fontWeight: 700, color: '#94A3B8' }}>
                In Calibration
              </div>
            </div>

          </div>

        </div>
      </section>

      {/* 6. IMPACT CALCULATOR */}
      <section style={{ padding: '80px 20px', borderBottom: '2.5px solid #000', backgroundColor: 'var(--accent-yellow)' }}>
        <div style={{ maxWidth: '800px', margin: '0 auto' }} className="neo-card">
          <div style={{ padding: '40px 32px', backgroundColor: '#fff', borderRadius: '12px' }}>
            <div style={{ textAlign: 'center', marginBottom: '32px' }}>
              <span className="neo-badge pink" style={{ marginBottom: '8px' }}>LIFE IN WEEKS</span>
              <h2 style={{ fontSize: 'clamp(26px, 3.5vw, 36px)', fontWeight: 900 }}>Calculate What You Reclaim</h2>
              <p style={{ fontSize: '14px', fontWeight: 700, color: '#666', marginTop: '6px' }}>
                See the real compounding effect of stopping endless vertical scrolling.
              </p>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontWeight: 800, marginBottom: '8px', fontSize: '15px' }}>
                  <span>Daily Short Video Doomscrolling:</span>
                  <span className="neo-badge yellow" style={{ fontSize: '13px', padding: '4px 12px' }}>{dailyHours} Hours / Day</span>
                </div>
                <input 
                  type="range" 
                  min="0.5" 
                  max="6" 
                  step="0.5" 
                  value={dailyHours}
                  onChange={(e) => setDailyHours(parseFloat(e.target.value))}
                  style={{ width: '100%', height: '12px', backgroundColor: '#e2e8f0', borderRadius: '8px', cursor: 'pointer', accentColor: '#000', border: '2px solid #000' }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '14px', paddingTop: '10px' }}>
                <div className="neo-card" style={{ padding: '16px', backgroundColor: '#FFFDF0', textAlign: 'center' }}>
                  <div style={{ fontSize: '32px', fontWeight: 900 }}>{dailyHours}h</div>
                  <div style={{ fontSize: '11px', fontWeight: 800, color: '#666', textTransform: 'uppercase', marginTop: '4px' }}>Saved Daily</div>
                </div>
                <div className="neo-card" style={{ padding: '16px', backgroundColor: 'var(--accent-green)', textAlign: 'center' }}>
                  <div style={{ fontSize: '32px', fontWeight: 900 }}>{yearlyHoursSaved}h</div>
                  <div style={{ fontSize: '11px', fontWeight: 800, color: '#1e293b', textTransform: 'uppercase', marginTop: '4px' }}>Hours Yearly</div>
                </div>
                <div className="neo-card" style={{ padding: '16px', backgroundColor: 'var(--accent-pink)', textAlign: 'center' }}>
                  <div style={{ fontSize: '32px', fontWeight: 900 }}>{lifetimeYearsGained} Yrs</div>
                  <div style={{ fontSize: '11px', fontWeight: 800, color: '#1e293b', textTransform: 'uppercase', marginTop: '4px' }}>Lifetime Gained</div>
                </div>
              </div>

              <div style={{ textAlign: 'center', paddingTop: '10px' }}>
                <button 
                  onClick={() => setShowDownloadModal(true)}
                  className="neo-btn"
                  style={{ fontSize: '16px', padding: '14px 32px', backgroundColor: 'var(--accent-yellow)' }}
                >
                  Reclaim Your Attention Today →
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 7. PRIVACY MANIFESTO */}
      <section id="privacy" style={{ padding: '80px 20px', borderBottom: '2.5px solid #000', backgroundColor: '#FFFFFF' }}>
        <div style={{ maxWidth: '800px', margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: '40px' }}>
            <span className="neo-badge green" style={{ marginBottom: '8px' }}>PRIVACY FIRST</span>
            <h2 style={{ fontSize: 'clamp(28px, 4vw, 44px)', fontWeight: 900 }}>The Inhibit Privacy Manifesto</h2>
          </div>

          <div className="neo-card" style={{ padding: '32px', backgroundColor: '#FFFDF0', display: 'flex', flexDirection: 'column', gap: '24px' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '16px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: '8px', backgroundColor: 'var(--accent-green)', border: '2px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Check size={20} />
              </div>
              <div>
                <h4 style={{ fontSize: '18px', fontWeight: 900 }}>Zero Telemetry & Zero Cloud Databases</h4>
                <p style={{ fontSize: '14px', fontWeight: 700, color: '#555', marginTop: '4px', lineHeight: 1.5 }}>
                  Inhibit has no user account servers, no tracking analytics, and no remote databases. Everything operates strictly within Android's sandboxed local runtime on your device.
                </p>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '16px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: '8px', backgroundColor: 'var(--accent-pink)', border: '2px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Check size={20} />
              </div>
              <div>
                <h4 style={{ fontSize: '18px', fontWeight: 900 }}>Strict Accessibility Scope</h4>
                <p style={{ fontSize: '14px', fontWeight: 700, color: '#555', marginTop: '4px', lineHeight: 1.5 }}>
                  Android Accessibility permission is strictly queried to identify full-screen short-form feed player container IDs. It never records keystrokes, personal chats, credentials, or private photos.
                </p>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '16px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: '8px', backgroundColor: 'var(--accent-yellow)', border: '2px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Check size={20} />
              </div>
              <div>
                <h4 style={{ fontSize: '18px', fontWeight: 900 }}>Open Rule Engine</h4>
                <p style={{ fontSize: '14px', fontWeight: 700, color: '#555', marginTop: '4px', lineHeight: 1.5 }}>
                  All detection signatures and redirection patterns are fully auditable, open-source rules that you can toggle individually at any time.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 8. FAQ ACCORDION */}
      <section id="faq" style={{ padding: '80px 20px', borderBottom: '2.5px solid #000', backgroundColor: '#FFFDF0' }}>
        <div style={{ maxWidth: '800px', margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: '40px' }}>
            <span className="neo-badge yellow" style={{ marginBottom: '8px' }}>QUESTIONS ANSWERED</span>
            <h2 style={{ fontSize: 'clamp(28px, 4vw, 44px)', fontWeight: 900 }}>Frequently Asked Questions</h2>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {[
              {
                q: "Why does Inhibit not close my Instagram or YouTube app?",
                a: "Because closing the app disrupts legitimate activities like replying to friends' direct messages, looking up an instructional video, or checking normal photo posts. Inhibit smartly navigates you back to your chronological Home feed instead of kicking you out."
              },
              {
                q: "What is Intentional Post Mode?",
                a: "If you are a creator or want to share photos/stories with friends, Intentional Post Mode gives you 4 daily 30-minute unlock windows so you can post content and reply to messages without falling into the infinite scrolling loop."
              },
              {
                q: "Does Inhibit drain my phone battery?",
                a: "No. Inhibit utilizes native event-driven Android Accessibility callbacks. It uses 0% background CPU and only wakes for a few milliseconds when an app screen transition occurs."
              },
              {
                q: "Why is Accessibility Permission required?",
                a: "On Android, the Accessibility Service API is the official native system bridge that allows Inhibit to identify when a full-screen Reels or Shorts container has opened and perform the safe in-app navigation back to your feed."
              }
            ].map((faq, index) => (
              <div 
                key={index}
                onClick={() => setActiveFaq(activeFaq === index ? null : index)}
                className="neo-card"
                style={{ padding: '18px 22px', backgroundColor: '#fff', cursor: 'pointer', userSelect: 'none' }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontWeight: 900, fontSize: '16px' }}>
                  <span>{faq.q}</span>
                  <ChevronDown size={20} style={{ transform: activeFaq === index ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s ease' }} />
                </div>
                {activeFaq === index && (
                  <p style={{ marginTop: '12px', fontSize: '14px', fontWeight: 700, color: '#555', lineHeight: 1.6, borderTop: '1px solid #eee', paddingTop: '12px' }}>
                    {faq.a}
                  </p>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 9. DOWNLOAD & INSTALLATION GUIDE */}
      <section id="download" style={{ padding: '80px 20px', borderBottom: '2.5px solid #000', backgroundColor: 'var(--accent-green)' }}>
        <div style={{ maxWidth: '800px', margin: '0 auto' }} className="neo-card">
          <div style={{ padding: '40px 32px', backgroundColor: '#fff', borderRadius: '12px', textAlign: 'center' }}>
            <span className="neo-badge green" style={{ marginBottom: '10px' }}>GET STARTED IN 60 SECONDS</span>
            <h2 style={{ fontSize: 'clamp(28px, 4vw, 44px)', fontWeight: 900, marginBottom: '12px' }}>Install Inhibit for Android</h2>
            <p style={{ fontSize: '15px', fontWeight: 700, color: '#555', maxWidth: '580px', margin: '0 auto 30px' }}>
              Ready to reclaim your attention and live more? Download the open release package and set up your device shield today.
            </p>

            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '16px', marginBottom: '36px', flexWrap: 'wrap' }}>
              <button 
                onClick={() => setShowDownloadModal(true)}
                className="neo-btn"
                style={{ fontSize: '16px', padding: '14px 28px', backgroundColor: 'var(--accent-yellow)' }}
              >
                <Download size={20} />
                <span>Download Inhibit APK (v1.0.0)</span>
              </button>
              <a 
                href="https://github.com/pavanstarkin-tech/inhibit" 
                target="_blank" 
                rel="noreferrer"
                className="neo-btn white"
                style={{ fontSize: '16px', padding: '14px 28px' }}
              >
                <ExternalLink size={20} />
                <span>GitHub Repository</span>
              </a>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '14px', textAlign: 'left' }}>
              <div style={{ padding: '16px', backgroundColor: '#FFFDF0', borderRadius: '10px', border: '2px solid #000' }}>
                <div style={{ fontWeight: 900, fontSize: '11px', color: '#666', marginBottom: '4px' }}>STEP 1</div>
                <div style={{ fontWeight: 900, fontSize: '14px' }}>Download APK</div>
                <p style={{ fontSize: '12px', fontWeight: 700, color: '#555', marginTop: '4px' }}>Download the verified `inhibit-v1.0.0.apk` release package.</p>
              </div>
              <div style={{ padding: '16px', backgroundColor: '#FFFDF0', borderRadius: '10px', border: '2px solid #000' }}>
                <div style={{ fontWeight: 900, fontSize: '11px', color: '#666', marginBottom: '4px' }}>STEP 2</div>
                <div style={{ fontWeight: 900, fontSize: '14px' }}>Allow Unknown Apps</div>
                <p style={{ fontSize: '12px', fontWeight: 700, color: '#555', marginTop: '4px' }}>Tap install and accept installation from your browser/files.</p>
              </div>
              <div style={{ padding: '16px', backgroundColor: '#FFFDF0', borderRadius: '10px', border: '2px solid #000' }}>
                <div style={{ fontWeight: 900, fontSize: '11px', color: '#666', marginBottom: '4px' }}>STEP 3</div>
                <div style={{ fontWeight: 900, fontSize: '14px' }}>Turn On Shield</div>
                <p style={{ fontSize: '12px', fontWeight: 700, color: '#555', marginTop: '4px' }}>Complete Step 5 in onboarding to turn on Inhibit Shield in Accessibility.</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 10. FOOTER */}
      <footer style={{ padding: '40px 24px', backgroundColor: '#FFFDF0' }}>
        <div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <img src="./logo.png" alt="Inhibit" style={{ height: '32px', width: 'auto', objectFit: 'contain' }} onError={(e) => { e.target.style.display = 'none'; }} />
            <div>
              <div style={{ fontWeight: 900, fontSize: '18px' }}>Inhibit</div>
              <div style={{ fontSize: '12px', fontWeight: 700, color: '#666' }}>Same social media. A better you.</div>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '24px', fontWeight: 800, fontSize: '14px', flexWrap: 'wrap' }}>
            <a href="#features" style={{ color: '#000', textDecoration: 'none' }}>Features</a>
            <a href="#services" style={{ color: '#000', textDecoration: 'none' }}>Services</a>
            <a href="#privacy" style={{ color: '#000', textDecoration: 'none' }}>Privacy</a>
            <a href="https://github.com/pavanstarkin-tech/inhibit" target="_blank" rel="noreferrer" style={{ color: '#000', textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '4px' }}>
              GitHub <ExternalLink size={14} />
            </a>
          </div>

          <div style={{ fontSize: '12px', fontWeight: 700, color: '#777' }}>
            © {new Date().getFullYear()} Inhibit Project. Open Source & Zero Telemetry.
          </div>
        </div>
      </footer>

      {/* 11. DOWNLOAD MODAL */}
      {showDownloadModal && (
        <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(4px)', zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '16px' }}>
          <div className="neo-card" style={{ padding: '28px', backgroundColor: '#FFFDF0', maxWidth: '480px', width: '100%', position: 'relative' }}>
            <button 
              onClick={() => setShowDownloadModal(false)}
              style={{ position: 'absolute', top: '16px', right: '16px', width: '32px', height: '32px', borderRadius: '8px', border: '2px solid #000', backgroundColor: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 900, cursor: 'pointer', boxShadow: '2px 2px 0px #000' }}
            >
              ✕
            </button>

            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: '8px', backgroundColor: 'var(--accent-yellow)', border: '2px solid #000', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Download size={20} />
              </div>
              <div>
                <h3 style={{ fontSize: '20px', fontWeight: 900 }}>Download Inhibit</h3>
                <span className="neo-badge green" style={{ fontSize: '10px' }}>v1.0.0 RELEASE</span>
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '13px', fontWeight: 700, color: '#444', marginBottom: '20px' }}>
              <div style={{ padding: '12px', backgroundColor: '#fff', border: '1.5px solid #000', borderRadius: '8px' }}>
                <div style={{ fontWeight: 900, fontSize: '11px', textTransform: 'uppercase', color: '#666' }}>Target Architecture</div>
                <div style={{ color: '#000', fontWeight: 800 }}>Android 8.0+ (arm64-v8a, armeabi-v7a, x86_64)</div>
              </div>
              <div style={{ padding: '12px', backgroundColor: '#fff', border: '1.5px solid #000', borderRadius: '8px' }}>
                <div style={{ fontWeight: 900, fontSize: '11px', textTransform: 'uppercase', color: '#666' }}>Security Guarantee</div>
                <div style={{ color: '#000', fontWeight: 800 }}>100% Local Sandboxed Engine • Zero Network Requests</div>
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <a 
                href="https://github.com/pavanstarkin-tech/inhibit/releases/download/v1.0.0/inhibit-v1.0.0.apk" 
                target="_blank" 
                rel="noreferrer"
                download="inhibit-v1.0.0.apk"
                className="neo-btn"
                style={{ padding: '12px', backgroundColor: 'var(--accent-yellow)', width: '100%', textAlign: 'center', textDecoration: 'none' }}
              >
                <Download size={18} />
                <span>Direct APK Download (v1.0.0)</span>
              </a>

              <a 
                href="https://github.com/pavanstarkin-tech/inhibit/releases/tag/v1.0.0" 
                target="_blank" 
                rel="noreferrer"
                className="neo-btn white"
                style={{ padding: '12px', width: '100%', textAlign: 'center', textDecoration: 'none' }}
              >
                <ExternalLink size={18} />
                <span>View Release on GitHub</span>
              </a>
            </div>
          </div>
        </div>
      )}

      {/* 12. FLOATING DOWNLOAD BUTTON */}
      <div className="floating-download-container">
        <button 
          onClick={() => setShowDownloadModal(true)}
          className="floating-download-btn"
          aria-label="Download Inhibit APK"
        >
          <span className="pulse-dot"></span>
          <Download size={18} />
          <span>Get APK (v1.0.0)</span>
        </button>
      </div>
    </div>
  );
}
