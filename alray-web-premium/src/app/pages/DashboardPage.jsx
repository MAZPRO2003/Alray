import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Building2, IndianRupee, Users, ArrowUpRight, ArrowDownRight, ArrowUpLeft, Activity, TrendingUp, Clock, MessageSquareText } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { projectService } from '../services/projectService';
import { contactService } from '../services/contactService';

export default function DashboardPage() {
    const { currentUser } = useAuth();
    const navigate = useNavigate();
    const [projects, setProjects] = useState([]);
    const [contacts, setContacts] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (!currentUser) return;
        const uid = currentUser.uid;
        // projectService now fetches all entries embedded inside projects if we aggregate them,
        // or we can aggregate all entries from all projects.
        const unsub1 = projectService.subscribeToProjects(uid, setProjects);
        const unsub2 = contactService.subscribeToContacts(uid, setContacts);

        setLoading(false);
        return () => { unsub1(); unsub2(); };
    }, [currentUser]);

    const formatCurrency = (n) => {
        if (n >= 10000000) return `₹${(n / 10000000).toFixed(1)}Cr`;
        if (n >= 100000) return `₹${(n / 100000).toFixed(1)}L`;
        if (n >= 1000) return `₹${(n / 1000).toFixed(1)}K`;
        return `₹${Math.round(n)}`;
    };

    // Aggregate all entries
    const allEntries = projects.flatMap(p =>
        (p.entries || []).map(e => ({ ...e, projectName: p.name }))
    );

    // Sort all entries by date (newest first)
    allEntries.sort((a, b) => {
        const da = a.date?.toDate ? a.date.toDate() : (a.date ? new Date(a.date) : new Date(0));
        const db = b.date?.toDate ? b.date.toDate() : (b.date ? new Date(b.date) : new Date(0));
        return db - da;
    });

    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay() + (now.getDay() === 0 ? -6 : 1)); // Start on Monday
    startOfWeek.setHours(0, 0, 0, 0);

    const weekEntries = allEntries.filter(e => {
        const d = e.date?.toDate ? e.date.toDate() : (e.date ? new Date(e.date) : null);
        return d && d >= startOfWeek;
    });

    const weekIn = weekEntries.filter(e => e.transactionType === 'credit').reduce((sum, e) => sum + (e.amount || 0), 0);
    const weekOut = weekEntries.filter(e => e.transactionType === 'expense').reduce((sum, e) => sum + (e.amount || 0), 0);
    const weekNet = weekIn - weekOut;

    const activeProjects = projects.filter(p => !p.isCompleted);

    // Calculate total pending payables across all projects
    const totalPending = projects.reduce((sum, p) => {
        const payables = p.payables || [];
        const entries = p.entries || [];
        return sum + payables.reduce((pSum, payable) => {
            const paid = entries.filter(e => e.payableId === payable.id).reduce((eSum, e) => eSum + (e.amount || 0), 0);
            return pSum + Math.max(0, (payable.totalAmount || 0) - paid);
        }, 0);
    }, 0);

    const recentEntries = allEntries.slice(0, 12);

    const stats = [
        { label: 'Active Projects', value: activeProjects.length, icon: Building2, color: '#3b6fd4', bg: 'rgba(59,111,212,0.1)', link: '/app/projects' },
        { label: 'Total Contacts', value: contacts.length, icon: Users, color: '#059669', bg: 'rgba(5,150,105,0.1)', link: '/app/contacts' },
        { label: 'Pending Bills', value: formatCurrency(totalPending), icon: Clock, color: '#d97706', bg: 'rgba(217,119,6,0.1)', link: '/app/projects' },
        { label: 'This Wk Net', value: `${weekNet < 0 ? '-' : '+'}${formatCurrency(Math.abs(weekNet))}`, icon: TrendingUp, color: weekNet >= 0 ? '#10b981' : '#ef4444', bg: weekNet >= 0 ? 'rgba(16,185,129,0.1)' : 'rgba(239, 68, 68, 0.1)', link: '/app/expenses' },
    ];

    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <h1 className="text-2xl font-bold" style={{ color: 'var(--color-secondary)', letterSpacing: '-0.02em' }}>
                    Welcome back, {currentUser?.displayName || currentUser?.email?.split('@')[0] || 'there'} 👋
                </h1>
                <p style={{ color: 'var(--color-text-light)', fontSize: '14px', marginTop: '4px', marginBottom: 0 }}>
                    Here's what's happening across your projects
                </p>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
                {stats.map((stat, i) => (
                    <motion.div key={stat.label} initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.07 }}>
                        <Link to={stat.link} className="block">
                            <div className="bg-white rounded-2xl border p-5 hover:shadow-md transition-shadow" style={{ borderColor: 'var(--color-border)' }}>
                                <div className="flex items-center justify-between mb-4">
                                    <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: stat.bg }}>
                                        <stat.icon size={20} style={{ color: stat.color }} />
                                    </div>
                                    <ArrowUpRight size={16} style={{ color: 'var(--color-text-light)' }} />
                                </div>
                                <p className="text-xs font-bold uppercase tracking-wider mb-1" style={{ color: 'var(--color-text-light)' }}>{stat.label}</p>
                                <p className="text-2xl font-bold" style={{ color: 'var(--color-secondary)' }}>{stat.value}</p>
                            </div>
                        </Link>
                    </motion.div>
                ))}
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
                {/* Active Projects */}
                <div className="xl:col-span-2">
                    <div className="bg-white rounded-2xl border overflow-hidden" style={{ borderColor: 'var(--color-border)' }}>
                        <div className="px-5 py-4 border-b flex items-center justify-between" style={{ borderColor: 'var(--color-border)' }}>
                            <h2 className="font-bold" style={{ color: 'var(--color-secondary)' }}>Active Projects</h2>
                            <Link to="/app/projects" className="text-xs font-semibold" style={{ color: 'var(--color-primary)' }}>View All →</Link>
                        </div>
                        {activeProjects.length === 0 ? (
                            <div className="p-12 text-center" style={{ color: 'var(--color-text-light)' }}>
                                <Building2 size={32} className="mx-auto mb-3" style={{ color: 'var(--color-border)' }} />
                                <p className="text-sm">No active projects yet</p>
                            </div>
                        ) : (
                            <div className="divide-y" style={{ borderColor: 'var(--color-border)' }}>
                                {activeProjects.slice(0, 5).map(project => {
                                    const spent = project.totalSpent || 0;
                                    const budget = project.budget || 1;
                                    const pct = Math.min(Math.round((spent / budget) * 100), 100);
                                    return (
                                        <Link to={`/app/projects/${project.id}`} key={project.id}
                                            className="flex items-center gap-4 px-5 py-4 hover:bg-gray-50/50 transition-colors block">
                                            <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
                                                style={{ background: 'rgba(13,27,75,0.06)' }}>
                                                <Building2 size={17} style={{ color: 'var(--color-secondary)' }} />
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <p className="font-semibold text-sm truncate" style={{ color: 'var(--color-secondary)' }}>{project.name}</p>
                                                <p className="text-xs mb-1 truncate" style={{ color: 'var(--color-text-light)', marginBottom: '6px' }}>{project.clientName || 'No client'}</p>
                                                <div className="h-1.5 rounded-full" style={{ background: 'var(--color-border)' }}>
                                                    <div className="h-1.5 rounded-full transition-all" style={{
                                                        width: `${pct}%`,
                                                        background: pct > 85 ? 'var(--color-primary)' : pct > 60 ? '#f59e0b' : '#10b981'
                                                    }} />
                                                </div>
                                            </div>
                                            <div className="text-right shrink-0">
                                                <p className="text-xs font-bold" style={{ color: 'var(--color-secondary)' }}>{pct}%</p>
                                                <p className="text-xs" style={{ color: 'var(--color-text-light)' }}>used</p>
                                            </div>
                                        </Link>
                                    );
                                })}
                            </div>
                        )}
                    </div>
                </div>

                {/* Recent Activity */}
                <div>
                    <div className="bg-white rounded-2xl border overflow-hidden" style={{ borderColor: 'var(--color-border)' }}>
                        <div className="px-5 py-4 border-b flex items-center justify-between" style={{ borderColor: 'var(--color-border)' }}>
                            <h2 className="font-bold" style={{ color: 'var(--color-secondary)' }}>Recent Activity</h2>
                            <Link to="/app/expenses" className="text-xs font-semibold" style={{ color: 'var(--color-primary)' }}>View All →</Link>
                        </div>
                        {recentEntries.length === 0 ? (
                            <div className="p-10 text-center" style={{ color: 'var(--color-text-light)' }}>
                                <Activity size={28} className="mx-auto mb-2" style={{ color: 'var(--color-border)' }} />
                                <p className="text-sm">No activity yet</p>
                            </div>
                        ) : (
                            <div className="divide-y" style={{ borderColor: 'var(--color-border)' }}>
                                {recentEntries.map(entry => {
                                    const date = entry.date?.toDate ? entry.date.toDate() : (entry.date ? new Date(entry.date) : null);
                                    const isCredit = entry.transactionType === 'credit';

                                    return (
                                        <div key={entry.id} className="flex items-center gap-3 px-4 py-3">
                                            <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                                                style={{ background: isCredit ? 'rgba(16,185,129,0.1)' : 'rgba(239,68,68,0.1)' }}>
                                                {isCredit ? (
                                                    <ArrowUpLeft size={14} style={{ color: '#10b981' }} />
                                                ) : (
                                                    <ArrowDownRight size={14} style={{ color: '#ef4444' }} />
                                                )}
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <p className="text-xs font-semibold truncate" style={{ color: 'var(--color-secondary)' }}>
                                                    {entry.description || entry.category || (isCredit ? 'Payment Received' : 'Expense')}
                                                </p>
                                                <p className="text-xs" style={{ color: 'var(--color-text-light)', marginBottom: 0 }}>
                                                    {entry.projectName} • {date ? date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }) : '—'}
                                                </p>
                                            </div>
                                            <p className="text-xs font-bold shrink-0" style={{ color: isCredit ? '#10b981' : '#ef4444' }}>
                                                {isCredit ? '+' : '-'}{formatCurrency(entry.amount)}
                                            </p>
                                        </div>
                                    );
                                })}
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* AI Chat FAB */}
            <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => navigate('/app/chat')}
                className="fixed bottom-6 right-6 w-14 h-14 rounded-full flex items-center justify-center shadow-lg text-white z-50 overflow-hidden"
                style={{
                    background: 'linear-gradient(135deg, #4f46e5 0%, #312e81 100%)',
                    boxShadow: '0 10px 25px -5px rgba(79, 70, 229, 0.5)'
                }}
            >
                <div className="absolute inset-0 bg-white opacity-0 hover:opacity-10 transition-opacity"></div>
                <MessageSquareText size={24} />
            </motion.button>
        </div>
    );
}
