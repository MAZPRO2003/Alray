import React, { useState, useEffect, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    Search,
    MoreVertical as MoreVert,
    Handshake,
    HardHat as Construction,
    Package as Inventory2,
    LayoutGrid as Category,
    CloudOff,
    Receipt
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { expenseService } from '../services/expenseService';
import { projectService } from '../services/projectService';
import { payableService } from '../services/payableService';
import TransactionDetailsDialog from '../components/projects/TransactionDetailsDialog';
import AddExpenseDialog from '../components/projects/AddExpenseDialog';

const CATEGORY_ICONS = {
    revenue: Handshake,
    labor: Construction,
    material: Inventory2,
    other: Category,
};

const CATEGORY_COLORS = {
    revenue: { bg: 'rgba(103, 80, 164, 0.1)', text: '#6750A4', border: 'rgba(103, 80, 164, 0.3)' }, // Purple
    labor: { bg: 'rgba(230, 81, 0, 0.1)', text: '#E65100', border: 'rgba(230, 81, 0, 0.3)' }, // Deep orange
    material: { bg: 'rgba(46, 125, 50, 0.1)', text: '#2E7D32', border: 'rgba(46, 125, 50, 0.3)' }, // Green
    other: { bg: 'rgba(2, 119, 189, 0.1)', text: '#0277BD', border: 'rgba(2, 119, 189, 0.3)' }, // Blue
};

export default function AllExpensesPage() {
    const { currentUser } = useAuth();
    const [entries, setEntries] = useState([]);
    const [projects, setProjects] = useState([]);
    const [payables, setPayables] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [searchQuery, setSearchQuery] = useState('');

    // Filters
    const [selectedProjectId, setSelectedProjectId] = useState(null); // null = all, 'General' = general
    const [selectedFilter, setSelectedFilter] = useState(null); // null = all, 'revenue', 'labor', 'material', 'other'
    const [paymentFilter, setPaymentFilter] = useState('all'); // 'all', 'pending', 'paid'

    // Dialogs
    const [selectedTransaction, setSelectedTransaction] = useState(null);
    const [isDetailsOpen, setIsDetailsOpen] = useState(false);
    const [isEditOpen, setIsEditOpen] = useState(false);

    // Popup Menu State
    const [openMenuId, setOpenMenuId] = useState(null);

    const loadData = () => {
        if (!currentUser) return;
        setLoading(true);
        setError(null);

        let unsub1, unsub2, unsub3;
        try {
            unsub1 = projectService.subscribeToProjects(currentUser.uid, setProjects);
            unsub2 = expenseService.subscribeToAllExpenses(currentUser.uid, setEntries);
            unsub3 = payableService.subscribeToAllPayables(currentUser.uid, (data) => {
                setPayables(data);
                setLoading(false);
            });

        } catch (err) {
            console.error("Error loading data:", err);
            setError(err.message);
            setLoading(false);
        }

        return () => {
            if (unsub1) unsub1();
            if (unsub2) unsub2();
            if (unsub3) unsub3();
        };
    };

    useEffect(() => {
        const cleanup = loadData();
        return cleanup;
    }, [currentUser]);

    // Close menus when clicking outside
    useEffect(() => {
        const handleClickOutside = () => setOpenMenuId(null);
        document.addEventListener('click', handleClickOutside);
        return () => document.removeEventListener('click', handleClickOutside);
    }, []);

    const formatCurrency = (n) => new Intl.NumberFormat('en-IN', {
        style: 'currency', currency: 'INR', maximumFractionDigits: 0
    }).format(n || 0);

    // Process data to match Flutter logic
    const processedData = useMemo(() => {
        const allTransactions = entries.map(entry => {
            let pName = 'General';
            if (entry.projectId) {
                const p = projects.find(p => p.id === entry.projectId);
                if (p) pName = p.name;
            }
            return {
                data: entry,
                projectName: pName,
                date: entry.date?.toDate ? entry.date.toDate() : (entry.date ? new Date(entry.date) : new Date(0))
            };
        });

        // Sort newest first
        allTransactions.sort((a, b) => b.date.getTime() - a.date.getTime());

        // 1. Filter by Project First
        const projectFiltered = selectedProjectId === null
            ? allTransactions
            : allTransactions.filter(t =>
                selectedProjectId === 'General' ? t.projectName === 'General' : t.data.projectId === selectedProjectId
            );

        // Calculate Totals based on Project Filter
        let totalRevenue = 0, totalWorkers = 0, totalMaterial = 0, totalCustom = 0;

        projectFiltered.forEach(item => {
            const entry = item.data;
            if (entry.transactionType === 'credit') {
                totalRevenue += (entry.amount || 0);
            } else {
                const catId = entry.categoryId || entry.category || '';
                if (catId.endsWith('-L') || catId === 'Plan Approval') {
                    totalWorkers += (entry.amount || 0);
                } else if (catId.endsWith('-M') || catId === 'Other Misc Materials') {
                    totalMaterial += (entry.amount || 0);
                } else {
                    totalCustom += (entry.amount || 0);
                }
            }
        });

        // Search Filter
        const searchFiltered = projectFiltered.filter(t =>
            !searchQuery ||
            (t.data.description || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
            (t.data.categoryId || t.data.category || '').toLowerCase().includes(searchQuery.toLowerCase())
        );

        // 2. Filter by Category Type
        const categoryFiltered = selectedFilter === null
            ? searchFiltered
            : searchFiltered.filter(t => {
                const entry = t.data;
                const catId = entry.categoryId || entry.category || '';

                if (selectedFilter === 'revenue') return entry.transactionType === 'credit';

                if (entry.transactionType === 'expense' || !entry.transactionType) {
                    if (selectedFilter === 'labor') {
                        return catId.endsWith('-L') || catId === 'Plan Approval';
                    }
                    if (selectedFilter === 'material') {
                        return catId.endsWith('-M') || catId === 'Other Misc Materials';
                    }
                    if (selectedFilter === 'other') {
                        return !catId.endsWith('-L') && catId !== 'Plan Approval' &&
                            !catId.endsWith('-M') && catId !== 'Other Misc Materials';
                    }
                }
                return false;
            });

        // 3. Build set of pending expense IDs
        const pendingExpenseIds = new Set();
        
        const pendingPayableIds = new Set(
            payables.filter(p => {
                const paid = entries
                    .filter(e => e.payableId === p.id)
                    .reduce((sum, e) => sum + (e.amount || 0), 0);
                return ((p.totalAmount || p.amount || 0) - paid) > 0;
            }).map(p => p.id)
        );

        entries.forEach(e => {
            if ((e.transactionType === 'expense' || !e.transactionType) &&
                e.payableId && pendingPayableIds.has(e.payableId)) {
                pendingExpenseIds.add(e.id);
            }
        });

        // 4. Filter by Payment Status
        const finalFiltered = paymentFilter === 'all'
            ? categoryFiltered
            : paymentFilter === 'pending'
                ? categoryFiltered.filter(t => t.data.transactionType !== 'credit' && pendingExpenseIds.has(t.data.id))
                : categoryFiltered.filter(t => t.data.transactionType === 'credit' || !pendingExpenseIds.has(t.data.id));

        return {
            filteredList: finalFiltered,
            pendingExpenseIds,
            totals: { revenue: totalRevenue, workers: totalWorkers, material: totalMaterial, custom: totalCustom }
        };

    }, [entries, projects, payables, selectedProjectId, selectedFilter, paymentFilter, searchQuery]);

    const { filteredList, pendingExpenseIds, totals } = processedData;

    const handleDelete = async (expense) => {
        if (window.confirm('Are you sure you want to delete this expense?')) {
            try {
                await projectService.deleteEntry(expense.projectId, expense.id);
                // Entries will update automatically via subscription
            } catch (error) {
                console.error("Error deleting expense:", error);
                alert("Failed to delete expense.");
            }
        }
    };

    const SummaryCard = ({ label, amount, type }) => {
        const colorObj = CATEGORY_COLORS[type];
        const Icon = CATEGORY_ICONS[type];

        return (
            <div className="flex flex-col bg-white rounded-[16px] p-4 min-w-[140px] border shadow-sm shrink-0"
                style={{ borderColor: 'var(--color-border)' }}>
                <div className="flex items-center gap-2 mb-2">
                    <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ background: colorObj.bg }}>
                        <Icon size={16} style={{ color: colorObj.text }} />
                    </div>
                    <span className="text-[13px] font-bold text-slate-700">{label}</span>
                </div>
                <span className="text-xl font-bold" style={{ color: type === 'revenue' ? '#2196F3' : 'var(--color-primary)' }}>
                    {formatCurrency(amount)}
                </span>
            </div>
        );
    };

    const FilterChip = ({ label, isSelected, onClick, colorObj, fallbackColor }) => {
        const bg = isSelected ? (colorObj ? colorObj.text : fallbackColor || 'var(--color-primary)') : 'transparent';
        const text = isSelected ? '#fff' : (colorObj ? colorObj.text : '#475569');
        const border = isSelected ? 'transparent' : (colorObj ? colorObj.border : 'var(--color-border)');

        return (
            <button
                onClick={onClick}
                className="px-4 py-1.5 rounded-full text-[13px] font-bold border transition-all shrink-0 flex items-center gap-1.5"
                style={{ backgroundColor: bg, color: text, borderColor: border }}
            >
                {label}
            </button>
        );
    };

    const TabButton = ({ label, isSelected, onClick, activeColor }) => {
        return (
            <button
                onClick={onClick}
                className={`flex-1 py-2 text-sm font-bold border-b-2 transition-all ${isSelected ? '' : 'text-slate-400 border-transparent hover:bg-slate-50'}`}
                style={{
                    borderColor: isSelected ? activeColor || 'var(--color-primary)' : '',
                    color: isSelected ? activeColor || 'var(--color-primary)' : ''
                }}
            >
                {label}
            </button>
        );
    };

    if (error) {
        return (
            <div className="flex flex-col items-center justify-center p-12 text-center">
                <CloudOff size={48} className="text-slate-300 mb-4" />
                <p className="text-slate-500 mb-4">Failed to load data. {error}</p>
                <button onClick={loadData} className="px-4 py-2 bg-slate-100 rounded-lg font-semibold text-slate-700 hover:bg-slate-200 transition-colors">
                    Retry
                </button>
            </div>
        );
    }

    return (
        <div className="space-y-4 pb-24 h-[calc(100vh-80px)] flex flex-col">
            {/* Header */}
            <div className="flex items-center justify-between shrink-0">
                <h1 className="text-[22px] font-bold text-slate-800">All Transactions</h1>
            </div>

            {/* Summary Cards Row (Horizontal Scroll) */}
            <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar shrink-0 -mx-4 px-4 sm:mx-0 sm:px-0">
                <SummaryCard label="Received" amount={totals.revenue} type="revenue" />
                <SummaryCard label="Workers" amount={totals.workers} type="labor" />
                <SummaryCard label="Material" amount={totals.material} type="material" />
                <SummaryCard label="Custom" amount={totals.custom} type="other" />
            </div>

            {/* Project Filter Chips */}
            <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar shrink-0 -mx-4 px-4 sm:mx-0 sm:px-0">
                <FilterChip label="All Projects" isSelected={selectedProjectId === null} onClick={() => setSelectedProjectId(null)} />
                {projects.map(p => (
                    <FilterChip key={p.id} label={p.name} isSelected={selectedProjectId === p.id} onClick={() => setSelectedProjectId(p.id)} />
                ))}
                <FilterChip label="General" isSelected={selectedProjectId === 'General'} onClick={() => setSelectedProjectId('General')} />
            </div>

            {/* Category Filter Chips */}
            <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar shrink-0 -mx-4 px-4 sm:mx-0 sm:px-0">
                <FilterChip label="All" isSelected={selectedFilter === null} onClick={() => setSelectedFilter(null)} fallbackColor="#475569" />
                <FilterChip label="Payments" isSelected={selectedFilter === 'revenue'} onClick={() => setSelectedFilter('revenue')} colorObj={CATEGORY_COLORS['revenue']} />
                <FilterChip label="Workers" isSelected={selectedFilter === 'labor'} onClick={() => setSelectedFilter('labor')} colorObj={CATEGORY_COLORS['labor']} />
                <FilterChip label="Material" isSelected={selectedFilter === 'material'} onClick={() => setSelectedFilter('material')} colorObj={CATEGORY_COLORS['material']} />
                <FilterChip label="Custom" isSelected={selectedFilter === 'other'} onClick={() => setSelectedFilter('other')} colorObj={CATEGORY_COLORS['other']} />
            </div>

            {/* Search Bar */}
            <div className="relative shrink-0">
                <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                    type="text"
                    placeholder="Search descriptions, categories..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-10 pr-4 py-3 rounded-[14px] text-sm bg-white border border-slate-200 focus:outline-none focus:border-red-400 shadow-sm transition-colors text-slate-800 placeholder-slate-400"
                />
            </div>

            {/* Tabs for Pending/Paid */}
            <div className="flex shrink-0">
                <TabButton label="All" isSelected={paymentFilter === 'all'} onClick={() => setPaymentFilter('all')} activeColor="var(--color-primary)" />
                <TabButton label="Pending" isSelected={paymentFilter === 'pending'} onClick={() => setPaymentFilter('pending')} activeColor="#F97316" />
                <TabButton label="Paid" isSelected={paymentFilter === 'paid'} onClick={() => setPaymentFilter('paid')} activeColor="#22C55E" />
            </div>
            <div className="h-[1px] bg-slate-200 shrink-0 w-full mt-[-2px]"></div>


            {/* Transaction List */}
            <div className="flex-1 overflow-y-auto pt-2 pb-6 min-h-0">
                {loading ? (
                    <div className="space-y-3">
                        {[1, 2, 3, 4, 5].map(i => (
                            <div key={i} className="bg-white p-4 rounded-[16px] border border-slate-100 shadow-sm animate-pulse flex items-center gap-4">
                                <div className="w-10 h-10 rounded-full bg-slate-100"></div>
                                <div className="flex-1 space-y-2">
                                    <div className="h-4 bg-slate-100 rounded w-1/3"></div>
                                    <div className="h-3 bg-slate-100 rounded w-1/2"></div>
                                </div>
                            </div>
                        ))}
                    </div>
                ) : filteredList.length === 0 ? (
                    <div className="flex flex-col items-center justify-center p-12 text-center h-full">
                        <Receipt size={64} className="text-slate-200 mb-4" />
                        <h3 className="text-lg font-bold text-slate-700 mb-1">No transactions found</h3>
                        <p className="text-sm text-slate-500 max-w-xs">We couldn't find any transactions matching your current filters.</p>
                        {(selectedProjectId !== null || selectedFilter !== null || paymentFilter !== 'all' || searchQuery !== '') && (
                            <button
                                onClick={() => {
                                    setSelectedProjectId(null);
                                    setSelectedFilter(null);
                                    setPaymentFilter('all');
                                    setSearchQuery('');
                                }}
                                className="mt-4 text-sm font-bold text-red-600 hover:text-red-700 bg-red-50 px-4 py-2 rounded-lg transition-colors"
                            >
                                Clear all filters
                            </button>
                        )}
                    </div>
                ) : (
                    <div className="space-y-3">
                        {filteredList.map((item, idx) => {
                            const isRevenue = item.data.transactionType === 'credit';
                            let expenseKey = 'other';

                            if (!isRevenue) {
                                const cat = item.data.categoryId || item.data.category || '';
                                if (cat.endsWith('-L') || cat === 'Plan Approval') expenseKey = 'labor';
                                else if (cat.endsWith('-M') || cat === 'Other Misc Materials') expenseKey = 'material';
                            }

                            const color = isRevenue ? CATEGORY_COLORS['revenue'] : CATEGORY_COLORS[expenseKey];
                            const Icon = isRevenue ? CATEGORY_ICONS['revenue'] : CATEGORY_ICONS[expenseKey];

                            const isPending = !isRevenue && pendingExpenseIds.has(item.data.id);
                            const statusLabel = isRevenue ? 'Received' : (isPending ? 'Pending' : 'Paid');

                            let statusColor = { text: '#2196F3', bg: 'rgba(33, 150, 243, 0.12)', border: 'rgba(33, 150, 243, 0.4)' }; // Blue for Received
                            if (!isRevenue) {
                                if (isPending) statusColor = { text: '#F97316', bg: 'rgba(249, 115, 22, 0.12)', border: 'rgba(249, 115, 22, 0.4)' }; // Orange
                                else statusColor = { text: '#22C55E', bg: 'rgba(34, 197, 94, 0.12)', border: 'rgba(34, 197, 94, 0.4)' }; // Green
                            }

                            return (
                                <motion.div
                                    key={item.data.id}
                                    initial={{ opacity: 0, y: 10 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    transition={{ delay: idx * 0.03, duration: 0.2 }}
                                    className="bg-white rounded-[16px] border shadow-sm p-4 cursor-pointer hover:shadow-md transition-shadow relative"
                                    style={{ borderColor: 'var(--color-border)' }}
                                    onClick={() => {
                                        setSelectedTransaction({ entry: item.data, projectName: item.projectName });
                                        setIsDetailsOpen(true);
                                    }}
                                >
                                    <div className="flex items-start gap-4">
                                        <div className="w-[44px] h-[44px] rounded-full flex items-center justify-center shrink-0" style={{ background: color.bg }}>
                                            <Icon size={22} style={{ color: color.text }} />
                                        </div>

                                        <div className="flex-1 min-w-0">
                                            <div className="flex justify-between items-start gap-2 mb-1 pl-1">
                                                <div className="flex-1 overflow-hidden">
                                                    <h3 className="font-bold text-[16px] text-slate-800 truncate leading-tight">
                                                        {isRevenue ? 'Customer Payment' : (item.data.categoryId || item.data.category || 'Other')}
                                                    </h3>
                                                </div>
                                                <div
                                                    className="px-2 py-0.5 rounded-[12px] border flex-shrink-0"
                                                    style={{ backgroundColor: statusColor.bg, borderColor: statusColor.border }}
                                                >
                                                    <span className="text-[11px] font-bold" style={{ color: statusColor.text }}>
                                                        {statusLabel}
                                                    </span>
                                                </div>
                                            </div>

                                            <div className="pl-1">
                                                {isRevenue ? (
                                                    <p className="text-[14px] text-slate-600 leading-snug truncate">
                                                        {item.data.description}
                                                    </p>
                                                ) : ((item.data.categoryId || item.data.category || '').endsWith('-M') ? null : (
                                                    <p className="text-[14px] text-slate-600 leading-snug truncate">
                                                        {item.data.description}
                                                    </p>
                                                ))}

                                                <p className="text-[13px] text-slate-500 mt-1 truncate">
                                                    {item.projectName}  •  {item.date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
                                                </p>
                                            </div>
                                        </div>

                                        <div className="flex flex-col items-end gap-2 pt-1">
                                            <span className="font-bold text-[15px] whitespace-nowrap" style={{ color: isRevenue ? '#2196F3' : 'var(--color-primary)' }}>
                                                {formatCurrency(item.data.amount)}
                                            </span>

                                            {!isRevenue && (
                                                <div className="relative">
                                                    <button
                                                        onClick={(e) => {
                                                            e.stopPropagation();
                                                            setOpenMenuId(openMenuId === item.data.id ? null : item.data.id);
                                                        }}
                                                        className="p-1 -mr-2 text-slate-400 hover:text-slate-600 rounded-full hover:bg-slate-100 transition-colors"
                                                    >
                                                        <MoreVert size={20} />
                                                    </button>

                                                    {openMenuId === item.data.id && (
                                                        <div className="absolute right-0 top-full mt-1 w-32 bg-white rounded-xl shadow-lg border border-slate-100 py-1 z-10 overflow-hidden transform origin-top-right">
                                                            <button
                                                                onClick={(e) => {
                                                                    e.stopPropagation();
                                                                    setSelectedTransaction({ entry: item.data, projectName: item.projectName });
                                                                    setOpenMenuId(null);
                                                                    setIsEditOpen(true);
                                                                }}
                                                                className="w-full text-left px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 transition-colors"
                                                            >
                                                                Edit
                                                            </button>
                                                            <button
                                                                onClick={(e) => {
                                                                    e.stopPropagation();
                                                                    setOpenMenuId(null);
                                                                    handleDelete(item.data);
                                                                }}
                                                                className="w-full text-left px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 transition-colors"
                                                            >
                                                                Delete
                                                            </button>
                                                        </div>
                                                    )}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </motion.div>
                            );
                        })}
                    </div>
                )}
            </div>

            {/* Dialogs */}
            {selectedTransaction && (
                <TransactionDetailsDialog
                    isOpen={isDetailsOpen}
                    onClose={() => setIsDetailsOpen(false)}
                    transaction={selectedTransaction.entry}
                    projectName={selectedTransaction.projectName}
                />
            )}

            {selectedTransaction && (
                <AddExpenseDialog
                    isOpen={isEditOpen}
                    onClose={() => setIsEditOpen(false)}
                    projectId={selectedTransaction.entry.projectId}
                    originalData={selectedTransaction.entry}
                />
            )}
        </div>
    );
}
