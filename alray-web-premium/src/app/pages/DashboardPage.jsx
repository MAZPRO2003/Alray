import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Building2, IndianRupee, Users, ArrowUpRight, ArrowDownRight, Activity, TrendingUp, Clock } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { projectService } from '../services/projectService';
import { expenseService } from '../services/expenseService';
import { contactService } from '../services/contactService';
import { payableService } from '../services/payableService';

export default function DashboardPage() {
    const { currentUser } = useAuth();
    const [projects, setProjects] = useState([]);
    const [expenses, setExpenses] = useState([]);
    const [contacts, setContacts] = useState([]);
    const [payables, setPayables] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (!currentUser) return;
        const uid = currentUser.uid;
        const u1 = projectService.subscribeToProjects(uid, setProjects);
        const u2 = expenseService.subscribeToAllExpenses(uid, setExpenses);
        const u3 = contactService.subscribeToContacts(uid, setContacts);
        const u4 = payableService.subscribeToAllPayables(uid, setPayables);
        setLoading(false);
        return () => { u1(); u2(); u3(); u4(); };
    }, [currentUser]);

    const formatCurrency = (n) => new Intl.NumberFormat('en-IN', {
        style: 'currency', currency: 'INR', maximumFractionDigits: 0
    }).format(n || 0);

    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    startOfWeek.setHours(0, 0, 0, 0);

    const weeklyExpenses = expenses.filter(e => {
        const d = e.date?.toDate ? e.date.toDate() : (e.date ? new Date(e.date) : null);
        return d && d >= startOfWeek;
    }).reduce((sum, e) => sum + (e.amount || 0), 0);

    const activeProjects = projects.filter(p => p.status === 'active' || !p.status);
    const pendingPayables = payables.filter(p => !p.isPaid);
    const pendingPayablesAmount = pendingPayables.reduce((sum, p) => sum + ((p.amount || 0) - (p.paidAmount || 0)), 0);
    const recentExpenses = [...expenses].slice(0, 8);

    const stats = [
        { label: 'Active Projects', value: activeProjects.length, icon: Building2, color: '#3b6fd4', bg: 'rgba(59,111,212,0.1)', link: '/app/projects' },
        { label: 'Total Contacts', value: contacts.length, icon: Users, color: '#059669', bg: 'rgba(5,150,105,0.1)', link: '/app/contacts' },
        { label: 'Pending Bills', value: formatCurrency(pendingPayablesAmount), icon: Clock, color: '#d97706', bg: 'rgba(217,119,6,0.1)', link: '/app/projects' },
        { label: 'This Week Spend', value: formatCurrency(weeklyExpenses), icon: TrendingUp, color: 'var(--color-primary)', bg: 'rgba(224,31,38,0.08)', link: '/app/expenses' },
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
                            <h2 className="font-bold" style={{ color: 'var(--color-secondary)' }}>Recent Expenses</h2>
                            <Link to="/app/expenses" className="text-xs font-semibold" style={{ color: 'var(--color-primary)' }}>View All →</Link>
                        </div>
                        {recentExpenses.length === 0 ? (
                            <div className="p-10 text-center" style={{ color: 'var(--color-text-light)' }}>
                                <Activity size={28} className="mx-auto mb-2" style={{ color: 'var(--color-border)' }} />
                                <p className="text-sm">No expenses yet</p>
                            </div>
                        ) : (
                            <div className="divide-y" style={{ borderColor: 'var(--color-border)' }}>
                                {recentExpenses.map(expense => {
                                    const date = expense.date?.toDate ? expense.date.toDate() : (expense.date ? new Date(expense.date) : null);
                                    return (
                                        <div key={expense.id} className="flex items-center gap-3 px-4 py-3">
                                            <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                                                style={{ background: 'rgba(224,31,38,0.07)' }}>
                                                <ArrowDownRight size={14} style={{ color: 'var(--color-primary)' }} />
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <p className="text-xs font-semibold truncate" style={{ color: 'var(--color-secondary)' }}>{expense.description || expense.category}</p>
                                                <p className="text-xs" style={{ color: 'var(--color-text-light)', marginBottom: 0 }}>{date ? date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }) : '—'}</p>
                                            </div>
                                            <p className="text-xs font-bold shrink-0" style={{ color: 'var(--color-primary)' }}>-{formatCurrency(expense.amount)}</p>
                                        </div>
                                    );
                                })}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
