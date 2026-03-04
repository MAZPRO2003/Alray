import React, { useState } from 'react';
import Modal from '../ui/Modal';
import { expenseService } from '../../services/expenseService';
import { IndianRupee, Tag, FileText, Calendar, AlertCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function AddExpenseDialog({ isOpen, onClose, projectId, initialData }) {
    const { currentUser } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const defaultState = {
        description: '',
        amount: '',
        categoryId: 'cement-M',
        date: new Date().toISOString().split('T')[0]
    };
    const [formData, setFormData] = useState(defaultState);

    React.useEffect(() => {
        if (isOpen) {
            if (initialData) {
                setFormData({
                    description: initialData.description || '',
                    amount: initialData.amount || '',
                    categoryId: initialData.categoryId || 'cement-M',
                    date: initialData.date ? new Date(initialData.date).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]
                });
            } else {
                setFormData(defaultState);
            }
        }
    }, [isOpen, initialData]);

    const categories = {
        'Materials': [
            { id: 'cement-M', label: 'Cement' },
            { id: 'sand-M', label: 'Sand' },
            { id: 'bricks-M', label: 'Bricks' },
            { id: 'steel-M', label: 'Steel' },
            { id: 'otherMiscMaterials', label: 'Other Materials' }
        ],
        'Labor': [
            { id: 'mason-L', label: 'Mason / Labour' },
            { id: 'electrical-L', label: 'Electrician' },
            { id: 'plumbing-L', label: 'Plumber' },
            { id: 'miscL', label: 'Misc Labour' }
        ],
        'Specialized': [
            { id: 'planApproval', label: 'Plan Approval' },
            { id: 'additionalWorks', label: 'Additional Works' }
        ],
        'Other': [
            { id: 'miscExp', label: 'Miscellaneous' }
        ]
    };

    const handleChange = (e) => {
        setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (!formData.description || !formData.amount) {
            setError('Description and Amount are required.');
            return;
        }

        try {
            setLoading(true);
            const submitData = {
                projectId,
                ...formData,
                amount: Number(formData.amount),
                date: new Date(formData.date)
            };

            if (initialData?.id) {
                await expenseService.updateExpense(initialData.id, submitData);
            } else {
                await expenseService.addExpense(currentUser.uid, submitData);
            }
            onClose();
        } catch (err) {
            console.error('Error adding expense:', err);
            setError('Failed to add expense. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal isOpen={isOpen} onClose={onClose} title={initialData ? "Edit Expense" : "Log New Expense"} maxWidth="max-w-md">
            {error && (
                <div className="mb-6 p-4 bg-red-50 text-red-600 rounded-xl flex items-center gap-3 font-medium text-sm border border-red-100">
                    <AlertCircle size={18} />
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-6">
                {/* Description */}
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Expense Description *</label>
                    <div className="relative">
                        <FileText className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text"
                            name="description"
                            value={formData.description}
                            onChange={handleChange}
                            placeholder="e.g. Purchased 50 bags of cement"
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                            required
                        />
                    </div>
                </div>

                {/* Amount */}
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Amount *</label>
                    <div className="relative">
                        <IndianRupee className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="number"
                            name="amount"
                            value={formData.amount}
                            onChange={handleChange}
                            placeholder="0.00"
                            min="0"
                            step="0.01"
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                            required
                        />
                    </div>
                </div>

                {/* Category (Grouped) */}
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Category</label>
                    <div className="relative">
                        <Tag className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <select
                            name="categoryId"
                            value={formData.categoryId}
                            onChange={handleChange}
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium appearance-none"
                        >
                            {Object.entries(categories).map(([groupName, items]) => (
                                <optgroup key={groupName} label={groupName}>
                                    {items.map(item => (
                                        <option key={item.id} value={item.id}>{item.label}</option>
                                    ))}
                                </optgroup>
                            ))}
                        </select>
                    </div>
                </div>

                {/* Date */}
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Date</label>
                    <div className="relative">
                        <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="date"
                            name="date"
                            value={formData.date}
                            onChange={handleChange}
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium text-gray-700"
                        />
                    </div>
                </div>

                {/* Footer Buttons */}
                <div className="flex gap-3 pt-6 border-t border-gray-100">
                    <button
                        type="button"
                        onClick={onClose}
                        className="flex-1 btn bg-gray-100 text-gray-700 hover:bg-gray-200 py-3"
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        disabled={loading}
                        className="flex-1 btn btn-primary py-3 disabled:opacity-70 flex justify-center items-center"
                    >
                        {loading ? (
                            <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                        ) : (
                            initialData ? 'Update Expense' : 'Save Expense'
                        )}
                    </button>
                </div>
            </form>
        </Modal>
    );
}
