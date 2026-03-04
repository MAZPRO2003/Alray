import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Search, Receipt, Building2, IndianRupee } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { expenseService } from '../services/expenseService';
import { projectService } from '../services/projectService';

export default function AllExpensesPage() {
    const { currentUser } = useAuth();
    const [expenses, setExpenses] = useState([]);
    const [projects, setProjects] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [filterCategory, setFilterCategory] = useState('all');

    useEffect(() => {
        if (!currentUser) return;
        const unsub1 = expenseService.subscribeToAllExpenses(currentUser.uid, setExpenses);
        const unsub2 = projectService.subscribeToProjects(currentUser.uid, (data) => {
            setProjects(data);
            setLoading(false);
        });
        return () => { unsub1(); unsub2(); };
    }, [currentUser]);

    const formatCurrency = (n) => new Intl.NumberFormat('en-IN', {
        style: 'currency', currency: 'INR', maximumFractionDigits: 0
    }).format(n || 0);

    const getProjectName = (id) => projects.find(p => p.id === id)?.name || 'Unknown Project';

    const categories = [...new Set(expenses.map(e => e.category).filter(Boolean))];

    const filtered = expenses.filter(e => {
        const matchSearch = !searchQuery || e.description?.toLowerCase().includes(searchQuery.toLowerCase());
        const matchCat = filterCategory === 'all' || e.category === filterCategory;
        return matchSearch && matchCat;
    });

    const totalAmount = filtered.reduce((sum, e) => sum + (e.amount || 0), 0);

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: 'var(--color-secondary)', letterSpacing: '-0.02em' }}>All Expenses</h1>
                    <p style={{ color: 'var(--color-text-light)', fontSize: '14px', marginTop: '4px', marginBottom: 0 }}>Global view of all project expenses</p>
                </div>
            </div>

            {/* Total card */}
            <div className="bg-white rounded-2xl border p-5 flex items-center gap-5" style={{ borderColor: 'var(--color-border)' }}>
                <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{ background: 'rgba(224,31,38,0.1)' }}>
                    <IndianRupee size={22} style={{ color: 'var(--color-primary)' }} />
                </div>
                <div>
                    <p className="text-xs font-bold uppercase tracking-wider mb-1" style={{ color: 'var(--color-text-light)' }}>Total Showing</p>
                    <p className="text-2xl font-bold" style={{ color: 'var(--color-secondary)' }}>{formatCurrency(totalAmount)}</p>
                </div>
                <div className="ml-auto text-sm font-semibold" style={{ color: 'var(--color-text-light)' }}>{filtered.length} entries</div>
            </div>

            {/* Filters */}
            <div className="flex flex-col sm:flex-row gap-3">
                <div className="relative flex-1 max-w-sm">
                    <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2" style={{ color: 'var(--color-text-light)' }} />
                    <input
                        type="text" placeholder="Search expenses..." value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-9 pr-4 py-2.5 rounded-xl text-sm border bg-white focus:outline-none"
                        style={{ borderColor: 'var(--color-border)', fontFamily: 'Inter, sans-serif', color: 'var(--color-text)' }}
                    />
                </div>
                <select
                    value={filterCategory}
                    onChange={(e) => setFilterCategory(e.target.value)}
                    className="px-4 py-2.5 rounded-xl text-sm border bg-white focus:outline-none"
                    style={{ borderColor: 'var(--color-border)', fontFamily: 'Inter, sans-serif', color: 'var(--color-text)' }}
                >
                    <option value="all">All Categories</option>
                    {categories.map(c => <option key={c} value={c}>{c}</option>)}
                </select>
            </div>

            {/* Table */}
            <div className="bg-white rounded-2xl border overflow-hidden" style={{ borderColor: 'var(--color-border)' }}>
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead>
                            <tr style={{ borderBottom: '1px solid var(--color-border)', background: '#f8f9fc' }}>
                                <th className="text-left text-xs font-bold uppercase tracking-wider px-5 py-3.5" style={{ color: 'var(--color-text-light)' }}>Description</th>
                                <th className="text-left text-xs font-bold uppercase tracking-wider px-5 py-3.5" style={{ color: 'var(--color-text-light)' }}>Project</th>
                                <th className="text-left text-xs font-bold uppercase tracking-wider px-5 py-3.5" style={{ color: 'var(--color-text-light)' }}>Category</th>
                                <th className="text-left text-xs font-bold uppercase tracking-wider px-5 py-3.5" style={{ color: 'var(--color-text-light)' }}>Date</th>
                                <th className="text-right text-xs font-bold uppercase tracking-wider px-5 py-3.5" style={{ color: 'var(--color-text-light)' }}>Amount</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr><td colSpan={5} className="text-center py-12" style={{ color: 'var(--color-text-light)' }}>Loading expenses...</td></tr>
                            ) : filtered.length === 0 ? (
                                <tr><td colSpan={5} className="text-center py-12">
                                    <Receipt size={36} className="mx-auto mb-3" style={{ color: 'var(--color-border)' }} />
                                    <p style={{ color: 'var(--color-text-light)' }}>No expenses found</p>
                                </td></tr>
                            ) : filtered.map((expense, idx) => {
                                const date = expense.date?.toDate ? expense.date.toDate() : (expense.date ? new Date(expense.date) : null);
                                return (
                                    <motion.tr key={expense.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: idx * 0.03 }}
                                        className="border-t hover:bg-gray-50/50 transition-colors" style={{ borderColor: 'var(--color-border)' }}>
                                        <td className="px-5 py-4 text-sm font-semibold" style={{ color: 'var(--color-secondary)' }}>{expense.description || '—'}</td>
                                        <td className="px-5 py-4">
                                            <span className="flex items-center gap-1.5 text-xs font-medium" style={{ color: 'var(--color-text-light)' }}>
                                                <Building2 size={13} /> {getProjectName(expense.projectId)}
                                            </span>
                                        </td>
                                        <td className="px-5 py-4">
                                            {expense.category && <span className="text-xs font-semibold px-2 py-1 rounded-md" style={{ background: 'rgba(79,142,247,0.1)', color: '#3b6fd4' }}>{expense.category}</span>}
                                        </td>
                                        <td className="px-5 py-4 text-sm" style={{ color: 'var(--color-text-light)' }}>
                                            {date ? date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : '—'}
                                        </td>
                                        <td className="px-5 py-4 text-sm font-bold text-right" style={{ color: 'var(--color-primary)' }}>{formatCurrency(expense.amount)}</td>
                                    </motion.tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}
