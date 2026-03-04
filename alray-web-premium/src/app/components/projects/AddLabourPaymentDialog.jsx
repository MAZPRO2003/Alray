import React, { useState } from 'react';
import Modal from '../ui/Modal';
import { laborPaymentService } from '../../services/labourService';
import { User, IndianRupee, Calendar, FileText, AlertCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function AddLabourPaymentDialog({ isOpen, onClose, projectId, initialData }) {
    const { currentUser } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const defaultState = {
        laborerName: '',
        amount: '',
        periodStart: new Date().toISOString().split('T')[0],
        periodEnd: new Date().toISOString().split('T')[0],
        description: ''
    };
    const [formData, setFormData] = useState(defaultState);

    React.useEffect(() => {
        if (isOpen) {
            if (initialData) {
                setFormData({
                    laborerName: initialData.laborerName || '',
                    amount: initialData.amount || '',
                    periodStart: initialData.periodStart ? new Date(initialData.periodStart).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
                    periodEnd: initialData.periodEnd ? new Date(initialData.periodEnd).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
                    description: initialData.description || ''
                });
            } else {
                setFormData(defaultState);
            }
        }
    }, [isOpen, initialData]);

    const handleChange = (e) => {
        setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (!formData.laborerName || !formData.amount || !formData.periodStart || !formData.periodEnd) {
            setError('Please fill all required fields.');
            return;
        }

        try {
            setLoading(true);
            const submitData = {
                projectId,
                ...formData,
                amount: parseFloat(formData.amount)
            };

            if (initialData?.id) {
                await laborPaymentService.updatePayment(initialData.id, submitData);
            } else {
                await laborPaymentService.addPayment(currentUser.uid, submitData);
            }
            onClose();
        } catch (err) {
            console.error('Error adding labor payment:', err);
            setError('Failed to add payment. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal isOpen={isOpen} onClose={onClose} title={initialData ? "Edit Labor Payment" : "Add Weekly Labor Payment"} maxWidth="max-w-md">
            {error && (
                <div className="mb-6 p-4 bg-red-50 text-red-600 rounded-xl flex items-center gap-3 font-medium text-sm border border-red-100">
                    <AlertCircle size={18} />
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-6">
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Laborer Name / Group *</label>
                    <div className="relative">
                        <User className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text" name="laborerName" value={formData.laborerName} onChange={handleChange}
                            placeholder="e.g. Ramesh & Team"
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-red-500 focus:bg-white transition-all text-sm font-medium"
                            required
                        />
                    </div>
                </div>

                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Amount Paid *</label>
                    <div className="relative">
                        <IndianRupee className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="number" name="amount" value={formData.amount} onChange={handleChange}
                            placeholder="0.00"
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-red-500 focus:bg-white transition-all text-sm font-medium"
                            required
                        />
                    </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">From *</label>
                        <div className="relative">
                            <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="date" name="periodStart" value={formData.periodStart} onChange={handleChange}
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-red-500 focus:bg-white transition-all text-sm font-medium text-gray-700"
                                required
                            />
                        </div>
                    </div>
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">To *</label>
                        <div className="relative">
                            <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="date" name="periodEnd" value={formData.periodEnd} onChange={handleChange}
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-red-500 focus:bg-white transition-all text-sm font-medium text-gray-700"
                                required
                            />
                        </div>
                    </div>
                </div>

                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Description (Optional)</label>
                    <div className="relative">
                        <FileText className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text" name="description" value={formData.description} onChange={handleChange}
                            placeholder="e.g. Clearing old dues"
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-red-500 focus:bg-white transition-all text-sm font-medium"
                        />
                    </div>
                </div>

                <div className="flex gap-3 pt-6 border-t border-gray-100">
                    <button type="button" onClick={onClose} className="flex-1 btn bg-gray-100 text-gray-700 hover:bg-gray-200 py-3">Cancel</button>
                    <button type="submit" disabled={loading} className="flex-1 btn bg-red-600 text-white hover:bg-red-700 py-3 disabled:opacity-70 flex justify-center items-center">
                        {loading ? <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" /> : (initialData ? 'Update Payment' : 'Save Payment')}
                    </button>
                </div>
            </form>
        </Modal>
    );
}
