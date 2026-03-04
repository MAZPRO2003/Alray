import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Mail, Lock, ArrowRight, Eye, EyeOff } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function LoginPage() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPass, setShowPass] = useState(false);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { login } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            setError('');
            setLoading(true);
            await login(email, password);
            navigate('/app/dashboard');
        } catch (err) {
            setError('Failed to sign in. Please check your credentials.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{
            minHeight: '100vh',
            width: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #0a113d 0%, #121c4e 60%, #1a0a0a 100%)',
            padding: '20px',
            fontFamily: "'Outfit', sans-serif",
            position: 'relative',
            overflow: 'hidden',
        }}>
            {/* Background blobs */}
            <div style={{
                position: 'absolute', top: '-100px', right: '-100px',
                width: '500px', height: '500px',
                background: 'rgba(234, 33, 39, 0.08)',
                borderRadius: '50%', filter: 'blur(80px)',
                pointerEvents: 'none',
            }} />
            <div style={{
                position: 'absolute', bottom: '-100px', left: '-100px',
                width: '400px', height: '400px',
                background: 'rgba(252, 194, 1, 0.06)',
                borderRadius: '50%', filter: 'blur(80px)',
                pointerEvents: 'none',
            }} />

            <motion.div
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6 }}
                style={{
                    width: '100%',
                    maxWidth: '440px',
                    background: 'rgba(255,255,255,0.04)',
                    backdropFilter: 'blur(24px)',
                    WebkitBackdropFilter: 'blur(24px)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '24px',
                    padding: '48px',
                    boxShadow: '0 24px 64px rgba(0,0,0,0.5)',
                    position: 'relative',
                    zIndex: 1,
                }}
            >
                {/* Top glare line */}
                <div style={{
                    position: 'absolute', top: 0, left: '32px', right: '32px', height: '1px',
                    background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent)',
                    borderRadius: '50%',
                }} />

                {/* Logo and header */}
                <div style={{ textAlign: 'center', marginBottom: '40px' }}>
                    <Link to="/" style={{ display: 'inline-block', textDecoration: 'none' }}>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px', marginBottom: '8px' }}>
                            <div style={{
                                width: '44px', height: '44px',
                                background: 'linear-gradient(135deg, #ea2127, #c41c21)',
                                borderRadius: '10px',
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                boxShadow: '0 4px 12px rgba(234,33,39,0.4)',
                            }}>
                                <span style={{ color: '#fcc201', fontWeight: 900, fontSize: '20px' }}>A</span>
                            </div>
                            <div style={{ textAlign: 'left' }}>
                                <div style={{ color: '#fff', fontWeight: 800, fontSize: '18px', letterSpacing: '0.05em', lineHeight: 1 }}>AL RAY</div>
                                <div style={{ color: '#fcc201', fontWeight: 600, fontSize: '10px', letterSpacing: '0.15em' }}>ASSOCIATES</div>
                            </div>
                        </div>
                    </Link>
                    <h2 style={{ color: '#ffffff', fontSize: '26px', fontWeight: 700, marginTop: '20px', marginBottom: '8px' }}>
                        Welcome Back
                    </h2>
                    <p style={{ color: 'rgba(255,255,255,0.5)', fontSize: '14px', fontWeight: 400 }}>
                        Sign in to access your management portal
                    </p>
                </div>

                {error && (
                    <div style={{
                        background: 'rgba(234,33,39,0.15)',
                        border: '1px solid rgba(234,33,39,0.4)',
                        borderRadius: '12px',
                        padding: '12px 16px',
                        color: '#fca5a5',
                        fontSize: '13px',
                        marginBottom: '24px',
                        textAlign: 'center',
                    }}>
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    {/* Email */}
                    <div style={{ position: 'relative' }}>
                        <Mail size={18} style={{
                            position: 'absolute', left: '14px', top: '50%',
                            transform: 'translateY(-50%)', color: 'rgba(255,255,255,0.35)',
                            pointerEvents: 'none',
                        }} />
                        <input
                            type="email"
                            required
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            placeholder="Email address"
                            style={{
                                width: '100%',
                                background: 'rgba(255,255,255,0.06)',
                                border: '1px solid rgba(255,255,255,0.12)',
                                borderRadius: '12px',
                                padding: '14px 14px 14px 44px',
                                color: '#fff',
                                fontSize: '14px',
                                fontFamily: 'inherit',
                                outline: 'none',
                                transition: 'border-color 0.2s',
                                boxSizing: 'border-box',
                            }}
                            onFocus={e => e.target.style.borderColor = 'rgba(252,194,1,0.6)'}
                            onBlur={e => e.target.style.borderColor = 'rgba(255,255,255,0.12)'}
                        />
                    </div>

                    {/* Password */}
                    <div style={{ position: 'relative' }}>
                        <Lock size={18} style={{
                            position: 'absolute', left: '14px', top: '50%',
                            transform: 'translateY(-50%)', color: 'rgba(255,255,255,0.35)',
                            pointerEvents: 'none',
                        }} />
                        <input
                            type={showPass ? 'text' : 'password'}
                            required
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="Password"
                            style={{
                                width: '100%',
                                background: 'rgba(255,255,255,0.06)',
                                border: '1px solid rgba(255,255,255,0.12)',
                                borderRadius: '12px',
                                padding: '14px 44px 14px 44px',
                                color: '#fff',
                                fontSize: '14px',
                                fontFamily: 'inherit',
                                outline: 'none',
                                transition: 'border-color 0.2s',
                                boxSizing: 'border-box',
                            }}
                            onFocus={e => e.target.style.borderColor = 'rgba(252,194,1,0.6)'}
                            onBlur={e => e.target.style.borderColor = 'rgba(255,255,255,0.12)'}
                        />
                        <button
                            type="button"
                            onClick={() => setShowPass(p => !p)}
                            style={{
                                position: 'absolute', right: '14px', top: '50%',
                                transform: 'translateY(-50%)',
                                background: 'none', border: 'none', cursor: 'pointer',
                                color: 'rgba(255,255,255,0.35)', padding: 0,
                                display: 'flex', alignItems: 'center',
                            }}
                        >
                            {showPass ? <EyeOff size={18} /> : <Eye size={18} />}
                        </button>
                    </div>

                    {/* Submit */}
                    <button
                        type="submit"
                        disabled={loading}
                        style={{
                            width: '100%',
                            marginTop: '8px',
                            padding: '15px',
                            background: loading ? 'rgba(234,33,39,0.5)' : 'linear-gradient(135deg, #ea2127, #c41c21)',
                            border: 'none',
                            borderRadius: '12px',
                            color: '#fff',
                            fontSize: '15px',
                            fontWeight: 700,
                            cursor: loading ? 'not-allowed' : 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '8px',
                            fontFamily: 'inherit',
                            boxShadow: loading ? 'none' : '0 8px 24px rgba(234,33,39,0.35)',
                            transition: 'transform 0.2s, box-shadow 0.2s',
                        }}
                        onMouseEnter={e => { if (!loading) { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 12px 28px rgba(234,33,39,0.45)'; } }}
                        onMouseLeave={e => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 8px 24px rgba(234,33,39,0.35)'; }}
                    >
                        {loading ? 'Signing In...' : (
                            <> Sign In <ArrowRight size={18} /> </>
                        )}
                    </button>
                </form>

                <p style={{ textAlign: 'center', marginTop: '28px', color: 'rgba(255,255,255,0.4)', fontSize: '13px' }}>
                    Don't have an account?{' '}
                    <Link to="/signup" style={{ color: '#fcc201', fontWeight: 600, textDecoration: 'none' }}>
                        Create one now
                    </Link>
                </p>
            </motion.div>
        </div>
    );
}
