import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    X, Calendar as CalendarIcon, Save,
    Calculator, Users, Check, Banknote
} from 'lucide-react';
import { attendanceService } from '../../services/attendanceService';

const roles = [
    { key: 'mason', title: 'Mason', countKey: 'mason', rateKey: 'masonRate' },
    { key: 'helper', title: 'Helper', countKey: 'helper', rateKey: 'helperRate' },
    { key: 'plumber', title: 'Plumber', countKey: 'plumber', rateKey: 'plumberRate' },
    { key: 'electrician', title: 'Electrician', countKey: 'electrician', rateKey: 'electricianRate' },
    { key: 'carpenter', title: 'Carpenter', countKey: 'carpenter', rateKey: 'carpenterRate' },
    { key: 'steelWorker', title: 'Steel worker', countKey: 'steelWorker', rateKey: 'steelWorkerRate' },
    { key: 'grillWorker', title: 'Grill worker', countKey: 'grillWorker', rateKey: 'grillWorkerRate' },
    { key: 'tileLabour', title: 'Tile labour', countKey: 'tileLabour', rateKey: 'tileLabourRate' },
    { key: 'painter', title: 'Painter', countKey: 'painter', rateKey: 'painterRate' },
    { key: 'others', title: 'Others', countKey: 'others', rateKey: 'othersRate' }
];

const defaultFormState = {
    date: new Date().toISOString().split('T')[0],
    mason: 0, masonRate: 0,
    helper: 0, helperRate: 0,
    plumber: 0, plumberRate: 0,
    electrician: 0, electricianRate: 0,
    carpenter: 0, carpenterRate: 0,
    steelWorker: 0, steelWorkerRate: 0,
    grillWorker: 0, grillWorkerRate: 0,
    tileLabour: 0, tileLabourRate: 0,
    painter: 0, painterRate: 0,
    others: 0, othersRate: 0,
    customEntered: 0, customEnteredRate: 0,
    customRoleName: '',
    notes: ''
};

export default function AddAttendanceDialog({ isOpen, onClose, projectId, existingRecord = null }) {
    const [formData, setFormData] = useState(defaultFormState);
    const [loading, setLoading] = useState(false);
    const [showCustom, setShowCustom] = useState(false);

    useEffect(() => {
        if (isOpen) {
            if (existingRecord) {
                const dateVal = existingRecord.date?.toDate ? existingRecord.date.toDate() : new Date(existingRecord.date);
                setFormData({
                    ...defaultFormState,
                    ...existingRecord,
                    date: dateVal.toISOString().split('T')[0]
                });
                if (existingRecord.customEntered > 0 || existingRecord.customRoleName) {
                    setShowCustom(true);
                } else {
                    setShowCustom(false);
                }
            } else {
                setFormData(defaultFormState);
                setShowCustom(false);
            }
        }
    }, [isOpen, existingRecord]);

    const handleNumChange = (field, value) => {
        const parsed = field.endsWith('Rate') ? parseFloat(value) : parseInt(value, 10);
        setFormData(prev => ({
            ...prev,
            [field]: isNaN(parsed) ? 0 : parsed
        }));
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            const payload = {
                ...formData,
                date: new Date(formData.date)
            };

            if (existingRecord?.id) {
                await attendanceService.updateAttendanceRecord(projectId, existingRecord.id, payload);
            } else {
                await attendanceService.addAttendanceRecord(projectId, payload);
            }
            onClose();
        } catch (error) {
            console.error('Failed to save attendance:', error);
            alert('Failed to save attendance. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    const calculateTotals = () => {
        let workers = 0;
        let cost = 0;

        roles.forEach(role => {
            workers += (formData[role.countKey] || 0);
            cost += (formData[role.countKey] || 0) * (formData[role.rateKey] || 0);
        });

        workers += (formData.customEntered || 0);
        cost += (formData.customEntered || 0) * (formData.customEnteredRate || 0);

        return { workers, cost };
    };

    const totals = calculateTotals();

    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN').format(amount || 0);
    };

    if (!isOpen) return null;

    return (
        <AnimatePresence>
            <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4">
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm"
                    onClick={() => !loading && onClose()}
                />

                <motion.div
                    initial={{ opacity: 0, y: 100, scale: 0.95 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: 20, scale: 0.95 }}
                    transition={{ type: "spring", bounce: 0, duration: 0.3 }}
                    className="relative w-full max-w-2xl bg-white rounded-[2rem] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]"
                >
                    {/* Header */}
                    <div className="flex items-center justify-between p-6 border-b border-slate-100 bg-slate-50/50">
                        <div className="flex items-center gap-4">
                            <div className="w-12 h-12 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center shrink-0">
                                <CalendarIcon size={24} />
                            </div>
                            <div>
                                <h2 className="text-xl font-black text-slate-800 tracking-tight">
                                    {existingRecord ? 'Edit Attendance' : 'Record Attendance'}
                                </h2>
                                <p className="text-xs font-bold text-slate-400">Daily labor log & costs</p>
                            </div>
                        </div>
                        <button
                            onClick={onClose}
                            className="p-2 text-slate-400 hover:bg-slate-100 rounded-full transition-colors"
                        >
                            <X size={20} />
                        </button>
                    </div>

                    {/* Content */}
                    <div className="flex-1 overflow-y-auto p-6 space-y-8 custom-scrollbar">
                        <form id="attendance-form" onSubmit={handleSubmit} className="space-y-6">

                            {/* Date Picker */}
                            <div className="space-y-2">
                                <label className="text-xs font-bold text-slate-500 uppercase tracking-widest ml-1">Date</label>
                                <input
                                    type="date"
                                    name="date"
                                    required
                                    value={formData.date}
                                    onChange={handleChange}
                                    className="w-full bg-slate-50 border border-slate-200 text-slate-800 rounded-2xl px-4 py-3 outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all font-medium"
                                />
                            </div>

                            {/* Matrix Header */}
                            <div className="flex px-4 py-2 border-b border-slate-100 gap-4 mt-4">
                                <div className="flex-[3] text-xs font-bold text-slate-400 uppercase tracking-widest text-left">Worker Type</div>
                                <div className="flex-[2] text-xs font-bold text-slate-400 uppercase tracking-widest text-center">Count</div>
                                <div className="flex-[3] text-xs font-bold text-slate-400 uppercase tracking-widest text-center">Daily Rate (₹)</div>
                            </div>

                            {/* Roles List */}
                            <div className="space-y-3">
                                {roles.map(role => (
                                    <div key={role.key} className="flex items-center gap-4">
                                        <div className="flex-[3] font-bold text-slate-700 text-sm">
                                            {role.title}
                                        </div>
                                        <div className="flex-[2]">
                                            <input
                                                type="number"
                                                min="0"
                                                value={formData[role.countKey] || ''}
                                                onChange={(e) => handleNumChange(role.countKey, e.target.value)}
                                                placeholder="0"
                                                className="w-full text-center bg-slate-50 border border-slate-200 rounded-xl px-0 py-2 text-sm font-bold text-slate-800 focus:border-blue-500 outline-none transition-colors"
                                            />
                                        </div>
                                        <div className="flex-[3] relative">
                                            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 font-bold text-sm">₹</span>
                                            <input
                                                type="number"
                                                min="0"
                                                step="0.01"
                                                value={formData[role.rateKey] || ''}
                                                onChange={(e) => handleNumChange(role.rateKey, e.target.value)}
                                                placeholder="0"
                                                className="w-full text-center bg-slate-50 border border-slate-200 rounded-xl pl-6 pr-2 py-2 text-sm font-bold text-slate-800 focus:border-blue-500 outline-none transition-colors"
                                            />
                                        </div>
                                    </div>
                                ))}

                                {/* Custom Role */}
                                {showCustom ? (
                                    <div className="flex items-center gap-4 mt-6 p-4 bg-slate-50/50 rounded-2xl border border-slate-200 border-dashed">
                                        <div className="flex-[3]">
                                            <input
                                                type="text"
                                                name="customRoleName"
                                                value={formData.customRoleName}
                                                onChange={handleChange}
                                                placeholder="Custom Role Name"
                                                className="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-sm font-bold text-slate-800 focus:border-blue-500 outline-none"
                                            />
                                        </div>
                                        <div className="flex-[2]">
                                            <input
                                                type="number"
                                                min="0"
                                                value={formData.customEntered || ''}
                                                onChange={(e) => handleNumChange('customEntered', e.target.value)}
                                                placeholder="0"
                                                className="w-full text-center bg-white border border-slate-200 rounded-xl px-0 py-2 text-sm font-bold text-slate-800 focus:border-blue-500 outline-none"
                                            />
                                        </div>
                                        <div className="flex-[3] relative">
                                            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 font-bold text-sm">₹</span>
                                            <input
                                                type="number"
                                                min="0"
                                                step="0.01"
                                                value={formData.customEnteredRate || ''}
                                                onChange={(e) => handleNumChange('customEnteredRate', e.target.value)}
                                                placeholder="0"
                                                className="w-full text-center bg-white border border-slate-200 rounded-xl pl-6 pr-2 py-2 text-sm font-bold text-slate-800 focus:border-blue-500 outline-none"
                                            />
                                        </div>
                                        <button
                                            type="button"
                                            onClick={() => {
                                                setShowCustom(false);
                                                setFormData(prev => ({ ...prev, customRoleName: '', customEntered: 0, customEnteredRate: 0 }));
                                            }}
                                            className="text-slate-400 hover:text-rose-500 transition-colors"
                                        >
                                            <X size={20} />
                                        </button>
                                    </div>
                                ) : (
                                    <button
                                        type="button"
                                        onClick={() => setShowCustom(true)}
                                        className="text-sm font-bold text-blue-600 hover:text-blue-700 flex items-center gap-1 mt-4 ml-2"
                                    >
                                        + Add Custom Labor Type
                                    </button>
                                )}
                            </div>

                            {/* Live Total Banner */}
                            <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 flex items-center justify-between mt-6">
                                <div className="flex items-center gap-2 text-blue-800 font-black">
                                    <Calculator size={20} />
                                    <span>Daily Total</span>
                                </div>
                                <div className="flex items-center gap-4">
                                    <div className="flex items-center gap-1.5 px-3 py-1 bg-blue-100/50 rounded-xl text-blue-700 font-bold text-sm">
                                        <Users size={16} />
                                        {totals.workers} workers
                                    </div>
                                    {totals.cost > 0 && (
                                        <div className="flex items-center gap-1.5 px-3 py-1 bg-emerald-100/50 border border-emerald-200 rounded-xl text-emerald-700 font-black text-sm">
                                            <Banknote size={16} />
                                            ₹{formatCurrency(totals.cost)}
                                        </div>
                                    )}
                                </div>
                            </div>

                            {/* Notes */}
                            <div className="space-y-2">
                                <label className="text-xs font-bold text-slate-400 uppercase tracking-widest ml-1">Notes (Optional)</label>
                                <textarea
                                    name="notes"
                                    value={formData.notes}
                                    onChange={handleChange}
                                    rows={2}
                                    placeholder="Add any additional details..."
                                    className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-4 py-4 text-slate-700 outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all font-medium resize-none shadow-sm"
                                />
                            </div>
                        </form>
                    </div>

                    {/* Footer Actions */}
                    <div className="p-6 border-t border-slate-100 bg-slate-50/50 flex flex-col-reverse sm:flex-row justify-end gap-3 shrink-0">
                        <button
                            type="button"
                            onClick={onClose}
                            className="px-6 py-3.5 text-slate-500 hover:text-slate-700 font-bold rounded-xl hover:bg-slate-200/50 transition-colors w-full sm:w-auto text-sm"
                        >
                            Cancel
                        </button>
                        <button
                            form="attendance-form"
                            type="submit"
                            disabled={loading || totals.workers === 0}
                            className="px-8 py-3.5 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 focus:ring-4 focus:ring-blue-600/20 transition-all flex items-center justify-center gap-2 shadow-lg hover:shadow-xl hover:-translate-y-0.5 w-full sm:w-auto text-sm disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0 disabled:hover:shadow-lg"
                        >
                            {loading ? (
                                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                            ) : (
                                <>
                                    <Save size={18} />
                                    <span>{existingRecord ? 'Update' : 'Save'} Record</span>
                                </>
                            )}
                        </button>
                    </div>
                </motion.div>
            </div>
        </AnimatePresence>
    );
}
