import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    Plus, Search, Briefcase, LayoutGrid, List,
    Receipt, Hourglass, CreditCard, ChevronRight,
    ArrowRight, Info, Zap, Edit2, Trash2
} from 'lucide-react';
import { expenseService } from '../../../services/expenseService';
import { payableService } from '../../../services/payableService';
import AddExpenseDialog from '../AddExpenseDialog';
import AddPayableDialog from '../AddPayableDialog';
import { useAuth } from '../../../context/AuthContext';
import { generateFinancialReportPDF, generateFinancialReportCSV } from '../../../utils/exportUtils';

export default function ProjectExpensesTab({ projectId }) {
    const { currentUser } = useAuth();
    const [expenses, setExpenses] = useState([]);
    const [payables, setPayables] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [isAddOpen, setIsAddOpen] = useState(false);
    const [viewMode, setViewMode] = useState('list');
    const [showPending, setShowPending] = useState(false);
    const [exportMode, setExportMode] = useState('combined');
    const [editExpense, setEditExpense] = useState(null);
    const [isAddPayableOpen, setIsAddPayableOpen] = useState(false);
    const [editPayable, setEditPayable] = useState(null);

    const handleDeletePayable = async (id) => {
        if (window.confirm('Are you sure you want to delete this pending bill?')) {
            try {
                await payableService.deletePayable(id);
            } catch (error) {
                console.error('Failed to delete payable:', error);
            }
        }
    };

    const handleDeleteExpense = async (id) => {
        if (window.confirm('Are you sure you want to delete this expense?')) {
            try {
                await expenseService.deleteExpense(id);
            } catch (error) {
                console.error('Failed to delete expense:', error);
            }
        }
    };

    useEffect(() => {
        if (!currentUser) return;

        const subs = [
            expenseService.subscribeToProjectExpenses(currentUser.uid, projectId, setExpenses),
            payableService.subscribeToProjectPayables(currentUser.uid, projectId, setPayables)
        ];

        setLoading(false);
        return () => subs.forEach(unsub => unsub());
    }, [projectId, currentUser]);

    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
            maximumFractionDigits: 0
        }).format(amount);
    };

    // Filter Specialized (Not Material, Not Labor)
    const isSpecialized = (catId) => {
        if (!catId) return true;
        const isLabor = catId.endsWith('-L') || catId === 'planApproval';
        const isMaterial = catId.endsWith('-M') || catId === 'otherMiscMaterials';
        return !isLabor && !isMaterial;
    };

    const paidSpecialized = expenses.filter(e => {
        const matchesSearch = (e.description?.toLowerCase() || '').includes(searchQuery.toLowerCase()) ||
            (e.category?.toLowerCase() || '').includes(searchQuery.toLowerCase());
        const specialized = isSpecialized(e.categoryId);
        const isExpense = e.transactionType === 'expense' || !e.transactionType;
        return matchesSearch && specialized && isExpense;
    });

    const pendingSpecializedPayables = payables.filter(p => {
        const matchesSearch = (p.vendorName?.toLowerCase() || '').includes(searchQuery.toLowerCase()) ||
            (p.description?.toLowerCase() || '').includes(searchQuery.toLowerCase());
        const specialized = isSpecialized(p.categoryId);

        const paidForThis = expenses
            .filter(e => e.payableId === p.id && e.transactionType === 'expense')
            .reduce((s, e) => s + (e.amount || 0), 0);
        const remaining = (p.totalAmount || p.amount || 0) - paidForThis;

        return matchesSearch && specialized && remaining > 0;
    }).map(p => {
        const paidForThis = expenses
            .filter(e => e.payableId === p.id && e.transactionType === 'expense')
            .reduce((s, e) => s + (e.amount || 0), 0);
        return { ...p, remainingAmount: (p.totalAmount || p.amount || 0) - paidForThis };
    });

    const totalPaid = paidSpecialized.reduce((sum, item) => sum + (item.amount || 0), 0);
    const totalPending = pendingSpecializedPayables.reduce((sum, item) => sum + (item.remainingAmount || 0), 0);

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">

            {/* Summary Banner Toggle */}
            <div className="grid grid-cols-2 gap-4">
                <button
                    onClick={() => setShowPending(false)}
                    className={`p-6 rounded-2xl border-2 transition-all flex flex-col items-start gap-2 relative overflow-hidden ${!showPending ? 'border-sky-500 bg-sky-50/50 ring-4 ring-sky-500/10' : 'border-slate-100 bg-white hover:border-slate-200'}`}
                >
                    <div className={`p-2 rounded-lg ${!showPending ? 'bg-sky-500 text-white shadow-lg shadow-sky-200' : 'bg-slate-100 text-slate-400'}`}>
                        <CreditCard size={18} />
                    </div>
                    <div>
                        <p className={`text-[10px] font-black uppercase tracking-widest ${!showPending ? 'text-sky-600' : 'text-slate-400'}`}>Actual Paid</p>
                        <h3 className={`text-xl font-black ${!showPending ? 'text-slate-900' : 'text-slate-400'}`}>{formatCurrency(totalPaid)}</h3>
                    </div>
                </button>

                <button
                    onClick={() => setShowPending(true)}
                    className={`p-6 rounded-2xl border-2 transition-all flex flex-col items-start gap-2 relative overflow-hidden ${showPending ? 'border-orange-500 bg-orange-50/50 ring-4 ring-orange-500/10' : 'border-slate-100 bg-white hover:border-slate-200'}`}
                >
                    <div className={`p-2 rounded-lg ${showPending ? 'bg-orange-500 text-white shadow-lg shadow-orange-200' : 'bg-slate-100 text-slate-400'}`}>
                        <Hourglass size={18} />
                    </div>
                    <div>
                        <p className={`text-[10px] font-black uppercase tracking-widest ${showPending ? 'text-orange-600' : 'text-slate-400'}`}>Still Pending</p>
                        <h3 className={`text-xl font-black ${showPending ? 'text-slate-900' : 'text-slate-400'}`}>{formatCurrency(totalPending)}</h3>
                    </div>
                </button>
            </div>

            {/* Toolbar */}
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-slate-50/50 p-4 rounded-2xl border border-slate-100">
                <div className="relative flex-1 w-full sm:w-80">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                    <input
                        type="text"
                        placeholder={`Search ${showPending ? 'pending bills' : 'paid expenses'}...`}
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] transition-all text-sm font-medium"
                    />
                </div>

                <div className="flex items-center gap-3 w-full sm:w-auto">
                    {/* Export Controls */}
                    <div className="hidden md:flex items-center gap-1 bg-white border border-slate-200 rounded-xl p-1 shadow-sm">
                        <select
                            value={exportMode}
                            onChange={(e) => setExportMode(e.target.value)}
                            className="text-xs py-1 px-2 rounded-lg bg-transparent border-none outline-none font-bold text-slate-600 cursor-pointer"
                        >
                            <option value="combined">Combined Data</option>
                            <option value="paid">Paid Expenses</option>
                            <option value="pending">Pending Bills</option>
                        </select>
                        <div className="w-px h-4 bg-slate-200 mx-1"></div>
                        <button
                            onClick={() => generateFinancialReportPDF(project, 'Specialized Tasks', paidSpecialized, pendingSpecializedPayables, exportMode)}
                            className="p-1.5 text-rose-500 hover:bg-rose-50 rounded-lg transition-colors" title="Export PDF"
                        >
                            <Receipt size={16} className="rotate-180" />
                        </button>
                        <button
                            onClick={() => generateFinancialReportCSV(project, 'Specialized Tasks', paidSpecialized, pendingSpecializedPayables, exportMode)}
                            className="p-1.5 text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors" title="Export CSV"
                        >
                            <LayoutGrid size={16} />
                        </button>
                    </div>

                    {!showPending && (
                        <div className="hidden sm:flex bg-slate-200/50 p-1 rounded-xl">
                            <button onClick={() => setViewMode('list')} className={`p-2 rounded-lg transition-all ${viewMode === 'list' ? 'bg-white shadow-sm text-slate-800' : 'text-slate-400 hover:text-slate-600'}`}><List size={16} /></button>
                            <button onClick={() => setViewMode('grid')} className={`p-2 rounded-lg transition-all ${viewMode === 'grid' ? 'bg-white shadow-sm text-slate-800' : 'text-slate-400 hover:text-slate-600'}`}><LayoutGrid size={16} /></button>
                        </div>
                    )}
                    <button
                        onClick={() => {
                            if (showPending) {
                                setEditPayable(null);
                                setIsAddPayableOpen(true);
                            } else {
                                setEditExpense(null);
                                setIsAddOpen(true);
                            }
                        }}
                        className={`p-2 rounded-xl transition-all flex items-center gap-2 px-4 text-xs font-black uppercase tracking-widest sm:flex-none ${showPending ? 'bg-orange-50 text-orange-600 hover:bg-orange-100' : 'bg-sky-50 text-sky-600 hover:bg-sky-100'}`}
                    >
                        <Plus size={16} /> {showPending ? 'Add Pending Bill' : 'Add Expense'}
                    </button>
                </div>
            </div>

            {/* Content Area */}
            <AnimatePresence mode="wait">
                <motion.div
                    key={showPending ? 'pending' : 'paid'}
                    initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}
                    transition={{ duration: 0.2 }}
                >
                    {loading ? (
                        <div className="text-center p-12 text-slate-400 font-medium">Loading specialized data...</div>
                    ) : (showPending ? pendingSpecializedPayables : paidSpecialized).length === 0 ? (
                        <div className="text-center p-16 bg-slate-50/50 rounded-3xl border border-dashed border-slate-200">
                            <Zap size={48} className="mx-auto text-slate-200 mb-4" />
                            <h3 className="text-lg font-bold text-slate-800 mb-2">No {showPending ? 'pending bills' : 'records'} found</h3>
                            <button onClick={() => { showPending ? setIsAddPayableOpen(true) : setIsAddOpen(true) }} className="btn btn-secondary text-blue-600 border-slate-200 bg-white">
                                {showPending ? 'Add Pending Bill' : 'Add Specialized Expense'}
                            </button>
                        </div>
                    ) : showPending ? (
                        <div className="space-y-4">
                            {pendingSpecializedPayables.map((p) => (
                                <div key={p.id} className="bg-white p-5 rounded-3xl border border-slate-100 shadow-sm flex items-center justify-between hover:border-orange-200 transition-colors group">
                                    <div className="flex items-center gap-5">
                                        <div className="p-3 bg-orange-50 text-orange-600 rounded-2xl"><Receipt size={24} /></div>
                                        <div>
                                            <h4 className="font-black text-slate-800">{p.vendorName || 'Specialized Provider'}</h4>
                                            <p className="text-xs text-slate-400 font-bold uppercase tracking-wider">{p.category || 'Specialized'} • Due {p.dueDate ? new Date(p.dueDate).toLocaleDateString('en-GB') : 'N/A'}</p>
                                        </div>
                                    </div>
                                    <div className="text-right flex flex-col items-end gap-2">
                                        <div className="flex items-center gap-6">
                                            <div>
                                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Owed</p>
                                                <p className="text-lg font-black text-orange-600">{formatCurrency(p.remainingAmount)}</p>
                                            </div>
                                            <ChevronRight size={20} className="text-slate-200 group-hover:text-orange-300 transition-colors" />
                                        </div>
                                        <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                            <button
                                                onClick={(e) => { e.stopPropagation(); setEditPayable(p); setIsAddPayableOpen(true); }}
                                                className="p-1.5 text-slate-300 hover:text-blue-500 hover:bg-blue-50 rounded-lg transition-all"
                                            >
                                                <Edit2 size={16} />
                                            </button>
                                            <button
                                                onClick={(e) => { e.stopPropagation(); handleDeletePayable(p.id); }}
                                                className="p-1.5 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-lg transition-all"
                                            >
                                                <Trash2 size={16} />
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    ) : (
                        viewMode === 'list' ? (
                            <div className="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">
                                <div className="overflow-x-auto custom-scrollbar">
                                    <table className="w-full text-left border-collapse">
                                        <thead>
                                            <tr className="bg-slate-50/80 border-b border-slate-100">
                                                <th className="p-4 text-xs font-black uppercase tracking-widest text-slate-400 pl-8">Date</th>
                                                <th className="p-4 text-xs font-black uppercase tracking-widest text-slate-400">Description</th>
                                                <th className="p-4 text-xs font-black uppercase tracking-widest text-slate-400 text-right pr-8">Paid</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-slate-100">
                                            {paidSpecialized.map((item) => (
                                                <tr key={item.id} className="hover:bg-slate-50/50 transition-colors cursor-pointer group">
                                                    <td className="p-4 text-sm font-bold text-slate-400 pl-8">{item.date ? new Date(item.date).toLocaleDateString('en-GB') : 'N/A'}</td>
                                                    <td className="p-4">
                                                        <h5 className="text-sm font-black text-slate-800">{item.description}</h5>
                                                        <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1">{item.category}</p>
                                                    </td>
                                                    <td className="p-4 text-right pr-8">
                                                        <div className="flex flex-col items-end gap-2">
                                                            <p className="text-sm font-black text-rose-500">{formatCurrency(item.amount)}</p>
                                                            {item.payableId ? (
                                                                <span className="text-[9px] font-black text-emerald-500 uppercase">From Bill</span>
                                                            ) : (
                                                                <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                                                    <button
                                                                        onClick={() => {
                                                                            setEditExpense(item);
                                                                            setIsAddOpen(true);
                                                                        }}
                                                                        className="p-1.5 text-slate-300 hover:text-blue-500 hover:bg-blue-50 rounded-lg transition-all"
                                                                    >
                                                                        <Edit2 size={16} />
                                                                    </button>
                                                                    <button
                                                                        onClick={() => handleDeleteExpense(item.id)}
                                                                        className="p-1.5 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-lg transition-all"
                                                                    >
                                                                        <Trash2 size={16} />
                                                                    </button>
                                                                </div>
                                                            )}
                                                        </div>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        ) : (
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                                {paidSpecialized.map((item) => (
                                    <div key={item.id} className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm hover:shadow-md transition-all group">
                                        <div className="flex justify-between items-start mb-4">
                                            <div className="p-2.5 bg-slate-50 text-slate-400 rounded-xl group-hover:bg-sky-50 group-hover:text-sky-500 transition-colors"><Zap size={18} /></div>
                                            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{item.date ? new Date(item.date).toLocaleDateString('en-GB') : 'N/A'}</span>
                                        </div>
                                        <h4 className="font-black text-slate-800 text-lg mb-1">{item.description}</h4>
                                        <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mb-4">{item.category}</p>
                                        <div className="pt-4 border-t border-slate-50 text-right flex flex-col items-end gap-2">
                                            <div>
                                                <p className="text-[10px] text-slate-400 font-bold uppercase mb-1">Total Paid</p>
                                                <p className="text-xl font-black text-rose-500">{formatCurrency(item.amount)}</p>
                                            </div>
                                            {!item.payableId && (
                                                <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                                    <button
                                                        onClick={() => {
                                                            setEditExpense(item);
                                                            setIsAddOpen(true);
                                                        }}
                                                        className="p-1.5 text-slate-300 hover:text-blue-500 hover:bg-blue-50 rounded-lg transition-all"
                                                    >
                                                        <Edit2 size={16} />
                                                    </button>
                                                    <button
                                                        onClick={() => handleDeleteExpense(item.id)}
                                                        className="p-1.5 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-lg transition-all"
                                                    >
                                                        <Trash2 size={16} />
                                                    </button>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )
                    )}
                </motion.div>
            </AnimatePresence>

            <AddExpenseDialog
                isOpen={isAddOpen}
                onClose={() => {
                    setIsAddOpen(false);
                    setEditExpense(null);
                }}
                projectId={projectId}
                initialData={editExpense}
            />
            <AddPayableDialog
                isOpen={isAddPayableOpen}
                onClose={() => {
                    setIsAddPayableOpen(false);
                    setEditPayable(null);
                }}
                projectId={projectId}
                initialData={editPayable}
                categoryFilter={'specialized'}
            />
        </motion.div>
    );
}
