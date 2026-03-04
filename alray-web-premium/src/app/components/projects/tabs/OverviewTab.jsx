import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    TrendingUp, AlertCircle, Calendar, CheckCircle2,
    Flag, Receipt, Wallet, ArrowRight, Plus,
    Clock, ShieldAlert, ChevronRight, IndianRupee,
    Briefcase
} from 'lucide-react';
import { useAuth } from '../../../context/AuthContext';
import { milestoneService } from '../../../services/milestoneService';
import { snagService } from '../../../services/snagService';
import { payableService } from '../../../services/payableService';
import { expenseService } from '../../../services/expenseService';
import { laborTaskService } from '../../../services/labourService';
import AddMilestoneDialog from '../AddMilestoneDialog';
import AddSnagItemDialog from '../AddSnagItemDialog';
import { generateOverallReportPDF, generateOverallReportCSV } from '../../../utils/exportUtils';
import { FileText, Layout, Edit2, Trash2 } from 'lucide-react';

export default function OverviewTab({ project }) {
    const { currentUser } = useAuth();
    const [milestones, setMilestones] = useState([]);
    const [snags, setSnags] = useState([]);
    const [payables, setPayables] = useState([]);
    const [entries, setEntries] = useState([]);
    const [laborTasks, setLaborTasks] = useState([]);
    const [isAddMilestoneOpen, setIsAddMilestoneOpen] = useState(false);
    const [isAddSnagOpen, setIsAddSnagOpen] = useState(false);
    const [editingSnag, setEditingSnag] = useState(null);
    const [loading, setLoading] = useState(true);

    const handleDeleteSnag = async (id) => {
        if (window.confirm('Are you sure you want to delete this issue?')) {
            try {
                await snagService.deleteSnagItem(id);
            } catch (err) {
                console.error(err);
            }
        }
    };

    useEffect(() => {
        if (!currentUser || !project) return;

        const subs = [
            milestoneService.subscribeToProjectMilestones(currentUser.uid, project.id, setMilestones),
            snagService.subscribeToProjectSnags(currentUser.uid, project.id, setSnags),
            payableService.subscribeToProjectPayables(currentUser.uid, project.id, setPayables),
            expenseService.subscribeToProjectExpenses(currentUser.uid, project.id, setEntries),
            laborTaskService.subscribeToProjectTasks(currentUser.uid, project.id, setLaborTasks)
        ];

        setLoading(false);
        return () => subs.forEach(unsub => unsub());
    }, [currentUser, project]);

    if (!project) return null;

    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
            maximumFractionDigits: 0
        }).format(amount);
    };

    // Financial Calculations
    const totalReceived = entries
        .filter(e => e.transactionType === 'credit')
        .reduce((sum, e) => sum + (e.amount || 0), 0);

    const entrySpent = entries
        .filter(e => e.transactionType === 'expense')
        .reduce((sum, e) => sum + (e.amount || 0), 0);

    const totalSpent = entrySpent;

    const pendingReceived = Math.max(0, project.budget - totalReceived);

    // Pending Payables (Owed to Vendors)
    const pendingPayables = payables.reduce((sum, p) => {
        const paidForThis = entries
            .filter(e => e.payableId === p.id && e.transactionType === 'expense')
            .reduce((s, e) => s + (e.amount || 0), 0);
        const remaining = (p.totalAmount || p.amount || 0) - paidForThis;
        return sum + (remaining > 0 ? remaining : 0);
    }, 0);

    const remainingBudget = Math.max(0, project.budget - totalSpent);

    // Timeline & Health
    const getTimeElapsed = () => {
        if (!project.startDate || !project.endDate) return 0;
        const start = project.startDate.toDate ? project.startDate.toDate() : new Date(project.startDate);
        const end = project.endDate.toDate ? project.endDate.toDate() : new Date(project.endDate);
        const now = new Date();
        if (now < start) return 0;
        if (now > end) return 1;
        return (now - start) / (end - start);
    };

    const timePassed = getTimeElapsed();
    const milestoneProgress = milestones.length > 0
        ? milestones.filter(m => m.isCompleted).length / milestones.length
        : 0;

    const getHealth = () => {
        const budgetRatio = totalSpent / (project.budget || 1);
        const diff = budgetRatio - timePassed;
        if (totalSpent > project.budget) return { label: 'Over Budget', color: 'text-red-600', bg: 'bg-red-50', border: 'border-red-200', icon: AlertCircle };
        if (diff > 0.15) return { label: 'High Spend', color: 'text-orange-600', bg: 'bg-orange-50', border: 'border-orange-200', icon: TrendingUp };
        if (timePassed > 0.8 && milestoneProgress < 0.5) return { label: 'Behind Schedule', color: 'text-orange-600', bg: 'bg-orange-50', border: 'border-orange-200', icon: Clock };
        return { label: 'On Track', color: 'text-green-600', bg: 'bg-green-50', border: 'border-green-200', icon: CheckCircle2 };
    };

    const health = getHealth();

    const handleToggleMilestone = async (m) => {
        try {
            await milestoneService.updateMilestone(m.id, { isCompleted: !m.isCompleted });
        } catch (err) {
            console.error(err);
        }
    };

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8 pb-12">

            {/* Header & Export Tools */}
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4 mb-2">
                <div>
                    <h2 className="text-2xl font-black text-slate-800">Project Overview</h2>
                    <p className="text-sm font-bold text-slate-500 mt-1">Financial summary and progress tracking</p>
                </div>
                <div className="flex items-center gap-2">
                    <span className="hidden md:inline text-xs font-bold text-slate-400 uppercase tracking-widest mr-2">Export Summary:</span>
                    <button
                        onClick={() => generateOverallReportPDF(project, { totalReceived, totalSpent, pendingReceived, pendingPayables, remainingBudget, health })}
                        className="px-4 py-2 bg-white border border-slate-200 text-rose-500 hover:bg-rose-50 hover:border-rose-200 shadow-sm rounded-xl flex items-center justify-center gap-2 text-sm font-bold transition-all"
                        title="Download PDF Summary"
                    >
                        <FileText size={16} className="shrink-0" />
                        <span>PDF</span>
                    </button>
                    <button
                        onClick={() => generateOverallReportCSV(project, { totalReceived, totalSpent, pendingReceived, pendingPayables, remainingBudget, health })}
                        className="px-4 py-2 bg-white border border-slate-200 text-emerald-600 hover:bg-emerald-50 hover:border-emerald-200 shadow-sm rounded-xl flex items-center justify-center gap-2 text-sm font-bold transition-all"
                        title="Download CSV Summary"
                    >
                        <Layout size={16} className="shrink-0" />
                        <span>CSV</span>
                    </button>
                </div>
            </div>

            {/* 1. Main Summary Cards */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Finance Overview */}
                <div className="lg:col-span-2 bg-gradient-to-br from-[var(--color-secondary)] to-[#1e293b] rounded-3xl p-8 text-white shadow-xl shadow-slate-200 relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl pointer-events-none" />

                    <div className="relative z-10 grid grid-cols-2 sm:grid-cols-3 gap-8">
                        <div className="space-y-1">
                            <p className="text-slate-400 text-xs font-bold uppercase tracking-widest">Total Budget</p>
                            <h2 className="text-3xl font-black">{formatCurrency(project.budget)}</h2>
                        </div>
                        <div className="space-y-1">
                            <p className="text-slate-400 text-xs font-bold uppercase tracking-widest">Received</p>
                            <h2 className="text-3xl font-black text-emerald-400">{formatCurrency(totalReceived)}</h2>
                        </div>
                        <div className="space-y-1">
                            <p className="text-slate-400 text-xs font-bold uppercase tracking-widest">Spent</p>
                            <h2 className="text-3xl font-black text-rose-400">{formatCurrency(totalSpent)}</h2>
                        </div>
                        <div className="space-y-1">
                            <p className="text-slate-400 text-xs font-bold uppercase tracking-widest">Rem. Budget</p>
                            <h2 className="text-xl font-bold">{formatCurrency(remainingBudget)}</h2>
                        </div>
                        <div className="space-y-1">
                            <p className="text-slate-400 text-xs font-bold uppercase tracking-widest">Pending Rcvd</p>
                            <h2 className="text-xl font-bold text-orange-400">{formatCurrency(pendingReceived)}</h2>
                        </div>
                        <div className="space-y-1">
                            <p className="text-slate-400 text-xs font-bold uppercase tracking-widest">To Pay Others</p>
                            <h2 className="text-xl font-bold text-sky-400">{formatCurrency(pendingPayables)}</h2>
                        </div>
                    </div>

                    <div className="mt-8 pt-6 border-t border-white/10 flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <div className={`p-2 rounded-full ${health.bg} ${health.color} flex items-center justify-center`}>
                                <health.icon size={20} className="shrink-0" />
                            </div>
                            <span className="font-bold text-sm tracking-wide">Status: {health.label}</span>
                        </div>
                        <div className="text-right">
                            <p className="text-[10px] text-slate-400 font-bold uppercase mb-1">Overall Progress</p>
                            <div className="flex items-center gap-3">
                                <div className="w-32 h-1.5 bg-white/10 rounded-full overflow-hidden">
                                    <div
                                        className="h-full bg-emerald-400 rounded-full"
                                        style={{ width: `${milestoneProgress * 100}%` }}
                                    />
                                </div>
                                <span className="font-black text-sm">{Math.round(milestoneProgress * 100)}%</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Timeline Card */}
                <div className="bg-white rounded-3xl border border-slate-100 p-8 flex flex-col justify-between shadow-sm">
                    <div className="space-y-6">
                        <div className="flex items-center gap-3">
                            <div className="p-2.5 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center">
                                <Calendar size={20} />
                            </div>
                            <h3 className="font-bold text-slate-800">Project Timeline</h3>
                        </div>

                        <div className="space-y-4">
                            <div className="flex justify-between items-center text-sm">
                                <span className="text-slate-400 font-medium">Start Date</span>
                                <span className="font-bold text-slate-700">
                                    {project.startDate ? (project.startDate.toDate ? project.startDate.toDate().toLocaleDateString('en-GB') : new Date(project.startDate).toLocaleDateString('en-GB')) : 'Not set'}
                                </span>
                            </div>
                            <div className="flex justify-between items-center text-sm">
                                <span className="text-slate-400 font-medium">Expected End</span>
                                <span className="font-bold text-orange-600">
                                    {project.endDate ? (project.endDate.toDate ? project.endDate.toDate().toLocaleDateString('en-GB') : new Date(project.endDate).toLocaleDateString('en-GB')) : 'Not set'}
                                </span>
                            </div>
                        </div>
                    </div>

                    <div className="mt-8">
                        <div className="flex justify-between text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">
                            <span>Time Elapsed</span>
                            <span>{Math.round(timePassed * 100)}%</span>
                        </div>
                        <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                            <div
                                className="h-full bg-blue-500 rounded-full"
                                style={{ width: `${timePassed * 100}%` }}
                            />
                        </div>
                    </div>
                </div>
            </div>

            {/* 2. Content Matrix */}
            <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">

                {/* Milestones & Schedule */}
                <section className="space-y-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                            <Flag size={20} className="text-slate-400" />
                            <h3 className="text-lg font-bold text-slate-800">Critical Milestones</h3>
                        </div>
                        <button
                            onClick={() => setIsAddMilestoneOpen(true)}
                            className="text-blue-600 text-xs font-bold hover:underline flex items-center justify-center gap-1"
                        >
                            <Plus size={14} className="shrink-0" />
                            <span>Add Milestone</span>
                        </button>
                    </div>

                    <div className="bg-slate-50/50 rounded-2xl border border-slate-100 divide-y divide-slate-100 overflow-hidden">
                        {milestones.length === 0 ? (
                            <div className="p-8 text-center text-slate-400 text-sm italic">
                                No milestones added yet.
                            </div>
                        ) : (
                            milestones.map(m => (
                                <div key={m.id} className="p-4 flex items-center justify-between hover:bg-white transition-colors group">
                                    <div className="flex items-center gap-4">
                                        <button
                                            onClick={() => handleToggleMilestone(m)}
                                            className={`p-1.5 rounded-lg border transition-all flex items-center justify-center ${m.isCompleted ? 'bg-emerald-500 border-emerald-500 text-white' : 'bg-white border-slate-200 text-slate-300 hover:border-emerald-500'}`}
                                        >
                                            <CheckCircle2 size={16} className="shrink-0" />
                                        </button>
                                        <span className={`text-sm font-bold ${m.isCompleted ? 'text-slate-400 line-through' : 'text-slate-700'}`}>
                                            {m.title}
                                        </span>
                                    </div>
                                    <ChevronRight size={16} className="text-slate-200 opacity-0 group-hover:opacity-100 transition-opacity" />
                                </div>
                            ))
                        )}
                    </div>
                </section>

                {/* Risk & Snags */}
                <section className="space-y-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                            <ShieldAlert size={20} className="text-slate-400" />
                            <h3 className="text-lg font-bold text-slate-800">Pending Issues & Snags</h3>
                        </div>
                        <div className="flex items-center gap-3">
                            <span className="text-xs font-bold text-slate-400">{snags.filter(s => s.status !== 'resolved').length} Active</span>
                            <button
                                onClick={() => { setEditingSnag(null); setIsAddSnagOpen(true); }}
                                className="p-1 px-2.5 bg-rose-50 text-rose-600 rounded-lg hover:bg-rose-100 transition-all font-bold text-[10px] uppercase tracking-wider flex items-center gap-1"
                            >
                                <Plus size={12} /> Add Issue
                            </button>
                        </div>
                    </div>

                    <div className="bg-slate-50/50 rounded-2xl border border-slate-100 divide-y divide-slate-100 overflow-hidden">
                        {snags.length === 0 ? (
                            <div className="p-8 text-center text-slate-400 text-sm italic">
                                No reported issues or snags.
                            </div>
                        ) : (
                            snags.slice(0, 5).map(s => (
                                <div key={s.id} className="p-4 flex items-center justify-between hover:bg-white transition-colors group">
                                    <div className="flex items-center justify-center gap-4">
                                        <div className={`w-2 h-2 rounded-full shrink-0 ${s.priority === 'high' ? 'bg-rose-500' : s.priority === 'medium' ? 'bg-orange-500' : 'bg-blue-500'}`} />
                                        <div className="space-y-0.5">
                                            <p className={`text-sm font-bold ${s.status === 'resolved' ? 'text-slate-400 line-through' : 'text-slate-700'}`}>
                                                {s.title || s.description}
                                            </p>
                                            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">{s.location || 'Site wide'} • {s.priority} priority</p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <span className={`text-[10px] px-2 py-0.5 rounded font-bold uppercase tracking-wider ${s.status === 'resolved' ? 'bg-emerald-50 text-emerald-600' : 'bg-orange-50 text-orange-600'}`}>
                                            {s.status}
                                        </span>
                                        <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                            <button
                                                onClick={() => { setEditingSnag(s); setIsAddSnagOpen(true); }}
                                                className="p-1 text-slate-300 hover:text-blue-500 hover:bg-blue-50 rounded-md transition-all"
                                            >
                                                <Edit2 size={12} />
                                            </button>
                                            <button
                                                onClick={() => handleDeleteSnag(s.id)}
                                                className="p-1 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-md transition-all"
                                            >
                                                <Trash2 size={12} />
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            ))
                        )}
                        {snags.length > 5 && (
                            <div className="p-3 text-center">
                                <button className="text-[10px] font-bold text-blue-600 uppercase tracking-widest hover:underline">View all snags</button>
                            </div>
                        )}
                    </div>
                </section>

                {/* Pending Payments (Payables) */}
                <section className="space-y-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                            <Receipt size={20} className="text-slate-400" />
                            <h3 className="text-lg font-bold text-slate-800">Upcoming Payables</h3>
                        </div>
                        <span className="text-xs font-bold text-orange-600">{formatCurrency(pendingPayables)} total</span>
                    </div>

                    <div className="bg-slate-50/50 rounded-2xl border border-slate-100 divide-y divide-slate-100 overflow-hidden">
                        {payables.filter(p => !p.isPaid).length === 0 ? (
                            <div className="p-8 text-center text-slate-400 text-sm italic">
                                No pending bills found.
                            </div>
                        ) : (
                            payables.filter(p => !p.isPaid).slice(0, 4).map(p => {
                                const paidForThis = entries
                                    .filter(e => e.payableId === p.id && e.transactionType === 'expense')
                                    .reduce((s, e) => s + (e.amount || 0), 0);
                                const remaining = (p.totalAmount || p.amount || 0) - paidForThis;
                                if (remaining <= 0) return null;

                                return (
                                    <div key={p.id} className="p-4 flex items-center justify-between hover:bg-white transition-colors">
                                        <div className="space-y-0.5">
                                            <p className="text-sm font-bold text-slate-700">{p.vendorName || p.supplier}</p>
                                            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Due: {p.dueDate ? (p.dueDate.toDate ? p.dueDate.toDate().toLocaleDateString('en-GB') : new Date(p.dueDate).toLocaleDateString('en-GB')) : 'N/A'}</p>
                                        </div>
                                        <div className="text-right">
                                            <p className="text-sm font-black text-slate-800">{formatCurrency(remaining)}</p>
                                            <p className="text-[10px] text-emerald-500 font-bold uppercase">Pending</p>
                                        </div>
                                    </div>
                                );
                            }).filter(Boolean)
                        )}
                    </div>
                </section>

                {/* Recent Income */}
                <section className="space-y-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                            <Wallet size={20} className="text-slate-400" />
                            <h3 className="text-lg font-bold text-slate-800">Customer Income Tracker</h3>
                        </div>
                        <span className="text-xs font-bold text-emerald-600">Recent credits</span>
                    </div>

                    <div className="bg-slate-50/50 rounded-2xl border border-slate-100 divide-y divide-slate-100 overflow-hidden">
                        {entries.filter(e => e.transactionType === 'credit').length === 0 ? (
                            <div className="p-8 text-center text-slate-400 text-sm italic">
                                No income logs found.
                            </div>
                        ) : (
                            entries.filter(e => e.transactionType === 'credit').slice(0, 4).map(e => (
                                <div key={e.id} className="p-4 flex items-center justify-between hover:bg-white transition-colors">
                                    <div className="space-y-0.5">
                                        <p className="text-sm font-bold text-slate-700">{e.description || 'Customer Payment'}</p>
                                        <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">{e.date ? (e.date.toDate ? e.date.toDate().toLocaleDateString('en-GB') : new Date(e.date).toLocaleDateString('en-GB')) : 'N/A'}</p>
                                    </div>
                                    <div className="text-right">
                                        <p className="text-sm font-black text-emerald-600">+{formatCurrency(e.amount)}</p>
                                        <div className="flex items-center justify-end gap-1.5">
                                            <div className="w-1.5 h-1.5 bg-emerald-500 rounded-full shrink-0" />
                                            <p className="text-[9px] text-emerald-500 font-bold uppercase leading-none">Received</p>
                                        </div>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </section>

            </div>

            {/* 3. Project Scope Section */}
            <section className="bg-slate-50/30 rounded-3xl border border-slate-100 p-8 space-y-4">
                <div className="flex items-center gap-2 mb-2">
                    <Briefcase size={20} className="text-slate-400" />
                    <h3 className="text-lg font-bold text-slate-800">Project Scope & Scope of Work</h3>
                </div>
                <div className="prose prose-slate max-w-none">
                    <p className="text-slate-600 leading-relaxed text-sm">
                        {project.description || 'No detailed scope of work provided for this project. Update the project settings to include specific contractual obligations, material specifications, or site notes here for your team.'}
                    </p>
                </div>
            </section>

            <AddMilestoneDialog
                isOpen={isAddMilestoneOpen}
                onClose={() => setIsAddMilestoneOpen(false)}
                projectId={project.id}
            />
            <AddSnagItemDialog
                isOpen={isAddSnagOpen}
                onClose={() => setIsAddSnagOpen(false)}
                projectId={project.id}
                existingSnag={editingSnag}
            />
        </motion.div>
    );
}
