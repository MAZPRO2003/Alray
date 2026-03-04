import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    Plus, Receipt, IndianRupee, Wallet,
    Download, Clock, ArrowDownCircle,
    CheckCircle2, ChevronRight, Filter, Edit2, Trash2
} from 'lucide-react';
import { expenseService } from '../../../services/expenseService';
import { useAuth } from '../../../context/AuthContext';
import AddRevenueDialog from '../AddRevenueDialog';
import { generateCustomerReportPDF, generateCustomerReportCSV } from '../../../utils/exportUtils';

export default function CustomerTab({ project }) {
    const { currentUser } = useAuth();
    const [payments, setPayments] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isAddOpen, setIsAddOpen] = useState(false);
    const [editPayment, setEditPayment] = useState(null);

    const handleDelete = async (id) => {
        if (window.confirm('Are you sure you want to delete this payment?')) {
            try {
                await expenseService.deleteExpense(id);
            } catch (error) {
                console.error('Failed to delete payment:', error);
            }
        }
    };

    useEffect(() => {
        if (!currentUser || !project?.id) return;
        const unsubscribe = expenseService.subscribeToProjectExpenses(currentUser.uid, project.id, (data) => {
            const credits = data.filter(e => e.transactionType === 'credit');
            setPayments(credits);
            setLoading(false);
        });
        return () => unsubscribe();
    }, [project?.id, currentUser]);

    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
            maximumFractionDigits: 0
        }).format(amount);
    };

    const totalReceived = payments.reduce((sum, p) => sum + (p.amount || 0), 0);
    const totalBudget = project?.budget || 0;
    const pendingBalance = totalBudget - totalReceived;

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">

            {/* Payment Summary Banner (Mobile Parity) */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-8 rounded-[2.5rem] border border-slate-100 shadow-sm relative overflow-hidden group hover:shadow-md transition-all">
                    <div className="absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity">
                        <Wallet size={80} />
                    </div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-slate-400 mb-2">Project Value</p>
                    <h3 className="text-3xl font-black text-slate-800">{formatCurrency(totalBudget)}</h3>
                    <div className="w-12 h-1 bg-blue-500 rounded-full mt-4" />
                </div>

                <div className="bg-emerald-500 p-8 rounded-[2.5rem] text-white shadow-xl shadow-emerald-200 relative overflow-hidden group">
                    <div className="absolute top-0 right-0 p-4 opacity-10">
                        <ArrowDownCircle size={80} />
                    </div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-emerald-100 mb-2">Total Received</p>
                    <h3 className="text-3xl font-black">{formatCurrency(totalReceived)}</h3>
                    <div className="w-12 h-1 bg-white/30 rounded-full mt-4" />
                </div>

                <div className="bg-white p-8 rounded-[2.5rem] border border-slate-100 shadow-sm relative overflow-hidden group hover:shadow-md transition-all">
                    <div className="absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity">
                        <Clock size={80} />
                    </div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-slate-400 mb-2">Balance Due</p>
                    <h3 className={`text-3xl font-black ${pendingBalance > 0 ? 'text-orange-500' : 'text-slate-800'}`}>
                        {formatCurrency(pendingBalance)}
                    </h3>
                    <div className={`w-12 h-1 rounded-full mt-4 ${pendingBalance > 0 ? 'bg-orange-400' : 'bg-slate-200'}`} />
                </div>
            </div>

            {/* Payment List History */}
            <div className="space-y-4">
                <div className="flex justify-between items-center px-2">
                    <h3 className="text-xl font-black text-slate-800 flex items-center gap-2">
                        <Receipt className="text-emerald-500" size={24} />
                        Income History
                    </h3>
                    <div className="flex items-center gap-3">
                        <div className="hidden sm:flex items-center gap-1 bg-white border border-slate-200 rounded-xl p-1 shadow-sm">
                            <span className="text-xs font-bold text-slate-500 px-2">Export:</span>
                            <button
                                onClick={() => generateCustomerReportPDF(project, payments)}
                                className="p-1.5 text-rose-500 hover:bg-rose-50 rounded-lg transition-colors" title="Export PDF"
                            >
                                <Receipt size={16} />
                            </button>
                            <button
                                onClick={() => generateCustomerReportCSV(project, payments)}
                                className="p-1.5 text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors" title="Export CSV"
                            >
                                <Download size={16} />
                            </button>
                        </div>
                        <button
                            onClick={() => {
                                setEditPayment(null);
                                setIsAddOpen(true);
                            }}
                            className="bg-slate-900 hover:bg-black text-white px-6 py-2.5 rounded-2xl shadow-lg transition-all flex items-center gap-2 text-sm font-black"
                        >
                            <Plus size={18} />
                            Add Income
                        </button>
                    </div>
                </div>

                {loading ? (
                    <div className="p-12 text-center text-slate-400 font-bold animate-pulse">Synchronizing income data...</div>
                ) : payments.length === 0 ? (
                    <div className="p-20 text-center bg-slate-50/50 rounded-[3rem] border border-dashed border-slate-200">
                        <ArrowDownCircle size={48} className="mx-auto text-slate-200 mb-4" />
                        <h4 className="text-lg font-black text-slate-400 uppercase tracking-widest">No entries found</h4>
                        <p className="text-slate-400 text-sm mt-2 max-w-xs mx-auto">Once the customer makes a payment, record it here to track project liquidity.</p>
                    </div>
                ) : (
                    <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
                        <div className="overflow-x-auto custom-scrollbar">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-slate-50 border-b border-slate-100">
                                        <th className="p-5 text-[10px] font-black uppercase tracking-widest text-slate-400 pl-10">Date</th>
                                        <th className="p-5 text-[10px] font-black uppercase tracking-widest text-slate-400">Description</th>
                                        <th className="p-5 text-[10px] font-black uppercase tracking-widest text-slate-400">Payment Mode</th>
                                        <th className="p-5 text-[10px] font-black uppercase tracking-widest text-slate-400 text-right pr-10">Income Amount</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {payments.map((p) => (
                                        <tr key={p.id} className="hover:bg-slate-50/50 transition-colors group">
                                            <td className="p-5 text-sm font-black text-slate-400 pl-10">
                                                {p.date ? new Date(p.date).toLocaleDateString('en-GB') : 'N/A'}
                                            </td>
                                            <td className="p-5">
                                                <h5 className="text-sm font-black text-slate-800">{p.description || 'Project Milestone Payment'}</h5>
                                                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1">Ref ID: {p.id.substring(0, 8)}</p>
                                            </td>
                                            <td className="p-5">
                                                <div className="flex items-center gap-2">
                                                    <span className={`px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-widest ${p.paymentMode === 'cash' ? 'bg-orange-100 text-orange-600' : 'bg-blue-100 text-blue-600'}`}>
                                                        {p.paymentMode || 'Credit'}
                                                    </span>
                                                    {p.paymentMode === 'bank' && <CheckCircle2 size={14} className="text-blue-500" />}
                                                </div>
                                            </td>
                                            <td className="p-5 text-right pr-10">
                                                <div className="flex flex-col items-end gap-2">
                                                    <p className="text-lg font-black text-emerald-600">{formatCurrency(p.amount)}</p>
                                                    <div className="flex items-center gap-2">
                                                        <button
                                                            onClick={() => {
                                                                setEditPayment(p);
                                                                setIsAddOpen(true);
                                                            }}
                                                            className="p-1.5 text-slate-300 hover:text-blue-500 hover:bg-blue-50 rounded-lg transition-all"
                                                        >
                                                            <Edit2 size={16} />
                                                        </button>
                                                        <button
                                                            onClick={() => handleDelete(p.id)}
                                                            className="p-1.5 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-lg transition-all"
                                                        >
                                                            <Trash2 size={16} />
                                                        </button>
                                                    </div>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}
            </div>

            <AddRevenueDialog
                isOpen={isAddOpen}
                onClose={() => {
                    setIsAddOpen(false);
                    setEditPayment(null);
                }}
                projectId={project.id}
                initialData={editPayment}
            />
        </motion.div>
    );
}
