import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, CheckCircle2, IndianRupee, Calendar, FileText, Hash, User } from 'lucide-react';
import { expenseService } from '../../services/expenseService';
import { useAuth } from '../../context/AuthContext';
import { receiptGenerator } from '../../utils/receiptGenerator';

export default function AddRevenueDialog({ isOpen, onClose, projectId, initialData }) {
    const { currentUser } = useAuth();
    const [loading, setLoading] = useState(false);

    // Auto-generate basic receipt number
    const generateReceiptNo = () => {
        const d = new Date();
        return `${d.getFullYear()}${(d.getMonth() + 1).toString().padStart(2, '0')}${d.getDate().toString().padStart(2, '0')}-${d.getMilliseconds()}`;
    };

    const defaultState = {
        amount: '',
        description: '',
        date: new Date().toISOString().split('T')[0],
        paymentMode: 'cash',
        receiptNumber: '',
        receiverName: '',
        referenceData: '', // Cheque No or TXN ID
        bank: '', // New: Deposited bank
        bankName: '',
        branchName: '',
        paymentDate: new Date().toISOString().split('T')[0] // Dated for cheque
    };

    const [formData, setFormData] = useState(defaultState);

    useEffect(() => {
        if (isOpen) {
            if (initialData) {
                setFormData({
                    amount: initialData.amount || '',
                    description: initialData.description || '',
                    date: initialData.date ? new Date(initialData.date).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
                    paymentMode: initialData.paymentMode || 'cash',
                    receiptNumber: initialData.receiptNumber || '',
                    receiverName: initialData.receiverName || '',
                    referenceData: initialData.referenceData || '',
                    bank: initialData.bank || '',
                    bankName: initialData.bankName || '',
                    branchName: initialData.branchName || '',
                    paymentDate: initialData.paymentDate ? new Date(initialData.paymentDate).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]
                });
            } else {
                setFormData({
                    ...defaultState,
                    receiptNumber: generateReceiptNo()
                });
            }
        }
    }, [isOpen, initialData]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!currentUser || loading) return;

        setLoading(true);
        try {
            const submitData = {
                ...formData,
                amount: Number(formData.amount),
                // Map referenceData back to match flutter's usage if needed
            };

            if (initialData?.id) {
                await expenseService.updateExpense(initialData.id, submitData);
            } else {
                await expenseService.addRevenue(currentUser.uid, { ...submitData, projectId });
                // Generate PDF receipt on successful save
                receiptGenerator.generate({ ...submitData, id: 'temp' });
            }

            onClose();
        } catch (error) {
            console.error("Error saving revenue:", error);
            alert("Failed to save payment. Please try again.");
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <AnimatePresence>
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
                <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    className="bg-white rounded-3xl shadow-2xl w-full max-w-lg overflow-hidden flex flex-col max-h-[90vh]"
                >
                    <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                        <h2 className="text-xl font-bold text-[var(--color-secondary)]">
                            {initialData ? 'Edit Receipt' : 'Issue Receipt'}
                        </h2>
                        <button onClick={onClose} className="p-2 hover:bg-gray-200 rounded-full transition-colors">
                            <X size={20} />
                        </button>
                    </div>

                    <div className="overflow-y-auto w-full custom-scrollbar">
                        <form onSubmit={handleSubmit} className="p-6 space-y-6">

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Receipt No.</label>
                                    <div className="relative">
                                        <Hash className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                                        <input
                                            required
                                            type="text"
                                            value={formData.receiptNumber}
                                            onChange={(e) => setFormData({ ...formData, receiptNumber: e.target.value })}
                                            className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 focus:border-[var(--color-primary)] transition-all font-bold text-sm"
                                        />
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Receipt Date</label>
                                    <div className="relative">
                                        <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                                        <input
                                            required
                                            type="date"
                                            value={formData.date}
                                            onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                                            className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 focus:border-[var(--color-primary)] transition-all text-sm"
                                        />
                                    </div>
                                </div>
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Received From (Customer Name)</label>
                                <div className="relative">
                                    <User className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                                    <input
                                        required
                                        type="text"
                                        placeholder="e.g., Mr. Peer Mohamed"
                                        value={formData.receiverName}
                                        onChange={(e) => setFormData({ ...formData, receiverName: e.target.value })}
                                        className="w-full pl-12 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 focus:border-[var(--color-primary)] transition-all text-sm font-bold"
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Amount (₹)</label>
                                <div className="relative">
                                    <IndianRupee className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                                    <input
                                        required
                                        type="number"
                                        placeholder="0.00"
                                        value={formData.amount}
                                        onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                                        className="w-full pl-12 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 focus:border-[var(--color-primary)] transition-all font-black text-xl text-emerald-600"
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Our Bank (Deposited To)</label>
                                <input
                                    type="text"
                                    placeholder="e.g. HDFC Bank, SBI..."
                                    value={formData.bank}
                                    onChange={(e) => setFormData({ ...formData, bank: e.target.value })}
                                    className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 focus:border-[var(--color-primary)] transition-all font-bold text-sm"
                                />
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">Payment Mode</label>
                                <div className="grid grid-cols-3 gap-3">
                                    {['cash', 'cheque', 'online'].map((mode) => (
                                        <button
                                            key={mode}
                                            type="button"
                                            onClick={() => setFormData({ ...formData, paymentMode: mode })}
                                            className={`py-2 px-3 rounded-xl border-2 transition-all font-bold text-sm uppercase tracking-wider ${formData.paymentMode === mode
                                                ? 'bg-blue-500 border-blue-500 text-white shadow-md shadow-blue-200'
                                                : 'bg-white border-slate-100 text-slate-400 hover:border-slate-200'
                                                }`}
                                        >
                                            {mode}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            {formData.paymentMode !== 'cash' && (
                                <div className="p-4 bg-slate-50/50 rounded-2xl border border-slate-100 space-y-4">
                                    <div className="grid grid-cols-2 gap-4">
                                        <div>
                                            <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">
                                                {formData.paymentMode === 'cheque' ? 'Cheque No.' : 'Ref/TXN ID'}
                                            </label>
                                            <input
                                                type="text"
                                                value={formData.referenceData}
                                                onChange={(e) => setFormData({ ...formData, referenceData: e.target.value })}
                                                className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:border-blue-500 transition-all text-sm"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">Dated / Ref Date</label>
                                            <input
                                                type="date"
                                                value={formData.paymentDate}
                                                onChange={(e) => setFormData({ ...formData, paymentDate: e.target.value })}
                                                className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:border-blue-500 transition-all text-sm"
                                            />
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div>
                                            <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">Drawn On (Bank)</label>
                                            <input
                                                type="text"
                                                value={formData.bankName}
                                                onChange={(e) => setFormData({ ...formData, bankName: e.target.value })}
                                                className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:border-blue-500 transition-all text-sm"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">Branch</label>
                                            <input
                                                type="text"
                                                value={formData.branchName}
                                                onChange={(e) => setFormData({ ...formData, branchName: e.target.value })}
                                                className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg focus:outline-none focus:border-blue-500 transition-all text-sm"
                                            />
                                        </div>
                                    </div>
                                </div>
                            )}

                            <div>
                                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Towards (Reason/Stage)</label>
                                <div className="relative">
                                    <FileText className="absolute left-4 top-3 text-gray-400" size={18} />
                                    <textarea
                                        required
                                        placeholder="e.g. Construction Advance, 5th Installment..."
                                        value={formData.description}
                                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                        className="w-full pl-12 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 focus:border-[var(--color-primary)] transition-all min-h-[80px] text-sm font-medium"
                                    />
                                </div>
                            </div>

                            <button
                                disabled={loading}
                                type="submit"
                                className="w-full btn btn-primary py-4 flex flex-row items-center justify-center gap-2 text-base font-bold"
                            >
                                {loading ? (
                                    <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin shrink-0" />
                                ) : null}
                                <span>{initialData ? 'UPDATE RECEIPT' : 'SAVE & ISSUE RECEIPT'}</span>
                            </button>
                        </form>
                    </div>
                </motion.div>
            </div>
        </AnimatePresence>
    );
}

