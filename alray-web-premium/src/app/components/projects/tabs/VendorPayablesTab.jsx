import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Plus, Search, IndianRupee, CheckCircle2, Clock } from 'lucide-react';
import { payableService } from '../../../services/payableService';
import AddPayableDialog from '../AddPayableDialog';
import { useAuth } from '../../../context/AuthContext';

export default function VendorPayablesTab({ projectId }) {
    const { currentUser } = useAuth();
    const [payables, setPayables] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [isAddOpen, setIsAddOpen] = useState(false);

    useEffect(() => {
        if (!currentUser) return;
        const unsubscribe = payableService.subscribeToProjectPayables(currentUser.uid, projectId, (data) => {
            setPayables(data);
            setLoading(false);
        });
        return () => unsubscribe();
    }, [projectId, currentUser]);

    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
            maximumFractionDigits: 0
        }).format(amount);
    };

    const handleMarkAsPaid = async (item) => {
        if (window.confirm(`Mark ${item.vendorName} invoice as fully paid?`)) {
            await payableService.updatePayable(item.id, {
                isPaid: true,
                paidAmount: item.amount
            });
        }
    };

    const filteredPayables = payables.filter(p =>
        p.vendorName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.description?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const pendingTotal = filteredPayables.reduce((sum, item) => sum + (!item.isPaid ? (item.amount || 0) - (item.paidAmount || 0) : 0), 0);

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">

            {/* Toolbar */}
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-gray-50/50 p-4 rounded-xl border border-gray-100">
                <div className="relative flex-1 w-full sm:w-80">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                    <input
                        type="text"
                        placeholder="Search vendors or invoices..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-10 pr-4 py-2 bg-white border border-gray-200 rounded-lg focus:outline-none focus:border-[var(--color-primary)] transition-all text-sm"
                    />
                </div>

                <button
                    onClick={() => setIsAddOpen(true)}
                    className="btn btn-primary w-full sm:w-auto flex items-center justify-center gap-2 py-2"
                >
                    <Plus size={18} />
                    Add Payable
                </button>
            </div>

            {/* Content Area */}
            {loading ? (
                <div className="text-center p-12 text-gray-500">Loading payables...</div>
            ) : filteredPayables.length === 0 ? (
                <div className="text-center p-16 bg-gray-50/50 rounded-xl border border-dashed border-gray-300">
                    <IndianRupee size={48} className="mx-auto text-gray-300 mb-4" />
                    <h3 className="text-lg font-bold text-[var(--color-secondary)] mb-2">No vendor payables found</h3>
                    <p className="text-gray-500 mb-6 text-sm">Track your supplier invoices and pending payments here.</p>
                    <button onClick={() => setIsAddOpen(true)} className="btn btn-secondary text-[var(--color-primary)] border-gray-200">
                        Add Vendor Payable
                    </button>
                </div>
            ) : (
                <div className="space-y-6">
                    {/* Summary Bar */}
                    <div className="flex justify-between items-center px-4 py-3 bg-[var(--color-primary)]/5 border border-[var(--color-primary)]/10 rounded-xl">
                        <span className="text-sm font-bold text-[var(--color-secondary)]">Showing {filteredPayables.length} payables</span>
                        <div className="text-right flex items-center gap-6">
                            <div>
                                <span className="text-xs text-gray-500 font-bold uppercase tracking-wider mr-2">Total Pending:</span>
                                <span className="text-lg font-bold text-orange-600">{formatCurrency(pendingTotal)}</span>
                            </div>
                        </div>
                    </div>

                    <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden mt-4">
                        <div className="overflow-x-auto custom-scrollbar">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-gray-50/80 border-b border-gray-100">
                                        <th className="p-4 text-xs font-bold uppercase tracking-wider text-gray-500">Vendor & Details</th>
                                        <th className="p-4 text-xs font-bold uppercase tracking-wider text-gray-500">Due Date</th>
                                        <th className="p-4 text-xs font-bold uppercase tracking-wider text-gray-500 text-right">Invoice Total</th>
                                        <th className="p-4 text-xs font-bold uppercase tracking-wider text-gray-500 text-right">Balance</th>
                                        <th className="p-4 text-xs font-bold uppercase tracking-wider text-gray-500 text-center">Status</th>
                                        <th className="p-4 text-xs font-bold uppercase tracking-wider text-gray-500 text-center">Action</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-100">
                                    {filteredPayables.map((item) => {
                                        const pending = (item.amount || 0) - (item.paidAmount || 0);
                                        const isPaid = item.isPaid || pending <= 0;

                                        return (
                                            <tr key={item.id} className="hover:bg-gray-50/50 transition-colors">
                                                <td className="p-4 text-sm font-bold text-[var(--color-secondary)]">
                                                    {item.vendorName}
                                                    <div className="text-xs font-medium text-gray-500 mt-0.5 font-normal">{item.description}</div>
                                                </td>
                                                <td className="p-4 text-sm font-medium text-gray-600 whitespace-nowrap">
                                                    {item.dueDate?.toDate ? item.dueDate.toDate().toLocaleDateString('en-GB') : (item.dueDate ? new Date(item.dueDate).toLocaleDateString('en-GB') : 'N/A')}
                                                </td>
                                                <td className="p-4 text-sm font-medium text-gray-600 text-right whitespace-nowrap">
                                                    {formatCurrency(item.amount)}
                                                </td>
                                                <td className="p-4 text-sm font-bold text-[var(--color-secondary)] text-right whitespace-nowrap">
                                                    {isPaid ? (
                                                        <span className="text-green-600">Paid</span>
                                                    ) : (
                                                        <span className="text-orange-600">{formatCurrency(pending)}</span>
                                                    )}
                                                </td>
                                                <td className="p-4 text-center">
                                                    <span className={`px-2.5 py-1 rounded-md text-[10px] font-bold uppercase tracking-wider whitespace-nowrap align-middle inline-flex items-center gap-1 ${isPaid ? 'bg-green-100 text-green-700' : 'bg-orange-100 text-orange-700'
                                                        }`}>
                                                        {isPaid ? <CheckCircle2 size={12} /> : <Clock size={12} />}
                                                        {isPaid ? 'Settled' : 'Pending'}
                                                    </span>
                                                </td>
                                                <td className="p-4 text-center">
                                                    {!isPaid && (
                                                        <button
                                                            onClick={() => handleMarkAsPaid(item)}
                                                            className="text-xs font-bold text-[var(--color-primary)] hover:text-blue-800 transition-colors bg-blue-50 px-3 py-1.5 rounded-lg"
                                                        >
                                                            Pay Full
                                                        </button>
                                                    )}
                                                </td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            )}

            <AddPayableDialog
                isOpen={isAddOpen}
                onClose={() => setIsAddOpen(false)}
                projectId={projectId}
            />
        </motion.div>
    );
}
