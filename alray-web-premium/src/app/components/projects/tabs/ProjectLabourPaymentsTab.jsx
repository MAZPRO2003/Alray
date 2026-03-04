import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Plus, IndianRupee, Calendar, MoreVertical, Edit2, Trash2, CreditCard, Search } from 'lucide-react';
import { laborPaymentService } from '../../../services/labourService';
import { useAuth } from '../../../context/AuthContext';
import AddLabourPaymentDialog from '../AddLabourPaymentDialog';

export default function ProjectLaborPaymentsTab({ projectId }) {
    const { currentUser } = useAuth();
    const [payments, setPayments] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isAddOpen, setIsAddOpen] = useState(false);
    const [editingPayment, setEditingPayment] = useState(null);
    const [searchQuery, setSearchQuery] = useState('');

    useEffect(() => {
        if (!currentUser) return;
        const unsubscribe = laborPaymentService.subscribeToProjectPayments(currentUser.uid, projectId, (data) => {
            setPayments(data);
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

    const handleEdit = (payment) => {
        setEditingPayment(payment);
        setIsAddOpen(true);
    };

    const handleDelete = async (id) => {
        if (window.confirm("Are you sure you want to delete this payment record?")) {
            try {
                await laborPaymentService.deletePayment(id);
            } catch (error) {
                console.error("Error deleting labor payment", error);
            }
        }
    };

    const filteredPayments = payments.filter(p =>
        p.laborerName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.description?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const totalPaid = filteredPayments.reduce((sum, p) => sum + (p.amount || 0), 0);

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div className="flex items-center gap-3">
                    <div className="p-2 bg-blue-50 rounded-xl text-blue-600">
                        <CreditCard size={20} />
                    </div>
                    <div>
                        <h3 className="text-lg font-bold text-[var(--color-secondary)]">Weekly Labor Payments</h3>
                        <p className="text-xs text-gray-500 font-medium">Recorded settlements for labor work</p>
                    </div>
                </div>
                <button
                    onClick={() => { setEditingPayment(null); setIsAddOpen(true); }}
                    className="btn btn-primary flex items-center gap-2 px-4 py-2 text-sm shadow-md"
                >
                    <Plus size={18} />
                    Record Settlement
                </button>
            </div>

            {/* Stats & Search */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="bg-white p-5 rounded-2xl border border-gray-100 flex items-center justify-between">
                    <div>
                        <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">TOTAL LABOR SETTLEMENTS</p>
                        <p className="text-2xl font-black text-red-600">{formatCurrency(totalPaid)}</p>
                    </div>
                    <div className="p-3 bg-red-50 rounded-xl text-red-600">
                        <IndianRupee size={24} />
                    </div>
                </div>
                <div className="relative">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
                    <input
                        type="text"
                        placeholder="Search by name or notes..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full h-full pl-12 pr-4 py-4 bg-white border border-gray-100 rounded-2xl focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 focus:border-[var(--color-primary)] transition-all font-medium text-sm"
                    />
                </div>
            </div>

            {loading ? (
                <div className="p-12 text-center text-gray-400">Loading payments...</div>
            ) : filteredPayments.length === 0 ? (
                <div className="p-20 text-center bg-gray-50/50 rounded-3xl border border-dashed border-gray-200">
                    <CreditCard size={48} className="mx-auto text-gray-200 mb-4" />
                    <p className="text-gray-400 font-bold uppercase tracking-widest text-xs">No records found</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 gap-4">
                    {filteredPayments.map((payment) => (
                        <motion.div
                            key={payment.id}
                            layout
                            className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-all group"
                        >
                            <div className="flex justify-between items-start gap-4">
                                <div className="flex-1 space-y-3">
                                    <div className="flex items-center gap-3">
                                        <div className="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center font-bold text-[var(--color-secondary)]">
                                            {payment.laborerName?.charAt(0)}
                                        </div>
                                        <div>
                                            <h4 className="font-bold text-[var(--color-secondary)]">{payment.laborerName}</h4>
                                            <div className="flex items-center gap-2 text-[10px] text-gray-400 font-bold">
                                                <Calendar size={12} />
                                                <span>{new Date(payment.periodStart).toLocaleDateString('en-GB')} - {new Date(payment.periodEnd).toLocaleDateString('en-GB')}</span>
                                            </div>
                                        </div>
                                    </div>
                                    {payment.description && (
                                        <p className="text-xs text-gray-500 italic px-13">{payment.description}</p>
                                    )}
                                </div>
                                <div className="text-right">
                                    <p className="text-lg font-black text-red-600">{formatCurrency(payment.amount)}</p>
                                    <p className="text-[10px] font-bold text-gray-400 mt-1 uppercase">Paid on {new Date(payment.date).toLocaleDateString('en-GB')}</p>
                                    <div className="flex items-center justify-end gap-1 mt-3 opacity-0 group-hover:opacity-100 transition-opacity">
                                        <button onClick={() => handleEdit(payment)} className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg">
                                            <Edit2 size={16} />
                                        </button>
                                        <button onClick={() => handleDelete(payment.id)} className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg">
                                            <Trash2 size={16} />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </motion.div>
                    ))}
                </div>
            )}

            <AddLabourPaymentDialog
                isOpen={isAddOpen}
                onClose={() => setIsAddOpen(false)}
                projectId={projectId}
                existingPayment={editingPayment}
            />
        </motion.div>
    );
}
