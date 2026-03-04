import React, { useState } from 'react';
import Modal from '../ui/Modal';
import { payableService } from '../../services/payableService';
import { IndianRupee, UserSquare2, FileText, Calendar, AlertCircle, Tag } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function AddPayableDialog({ isOpen, onClose, projectId, initialData, categoryFilter }) {
    const { currentUser } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const categories = {
        'Materials': [
            { id: 'cement-M', label: 'Cement' },
            { id: 'sand-M', label: 'Sand' },
            { id: 'aggregate-M', label: 'Aggregate / Jelly' },
            { id: 'bricks-M', label: 'Bricks' },
            { id: 'steel-M', label: 'Steel' },
            { id: 'rmc-M', label: 'RMC (Ready Mix)' },
            { id: 'electrical-M', label: 'Electrical (Material)' },
            { id: 'plumbing-M', label: 'Plumbing (Material)' },
            { id: 'carpentry-M', label: 'Carpentry / Wood' },
            { id: 'grill-M', label: 'Grill / MS Work' },
            { id: 'tile-M', label: 'Tiles' },
            { id: 'paint-M', label: 'Paint (Material)' },
            { id: 'otherMiscMaterials', label: 'Other Materials' }
        ],
        'Specialized': [
            { id: 'planApproval', label: 'Plan Approval' },
            { id: 'additionalWorks', label: 'Additional Works' },
            { id: 'miscExp', label: 'Miscellaneous' }
        ]
    };

    const getFilteredCategories = () => {
        if (categoryFilter === 'material') {
            return { 'Materials': categories['Materials'] };
        } else if (categoryFilter === 'specialized') {
            return { 'Specialized': categories['Specialized'] };
        }
        return categories;
    };

    const defaultCategoryId = categoryFilter === 'specialized' ? 'planApproval' : 'cement-M';

    const defaultState = {
        vendorName: '',
        description: '',
        amount: '',
        paidAmount: '0',
        dueDate: '',
        categoryId: defaultCategoryId
    };

    const [formData, setFormData] = useState(defaultState);

    React.useEffect(() => {
        if (isOpen) {
            if (initialData) {
                setFormData({
                    vendorName: initialData.vendorName || '',
                    description: initialData.description || '',
                    amount: initialData.totalAmount || initialData.amount || '',
                    paidAmount: initialData.paidAmount || '0',
                    dueDate: initialData.dueDate ? new Date(initialData.dueDate).toISOString().split('T')[0] : '',
                    categoryId: initialData.categoryId || defaultCategoryId
                });
            } else {
                setFormData(defaultState);
            }
        }
    }, [isOpen, initialData, categoryFilter]);

    const handleChange = (e) => {
        setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }));
    };

    const getCategoryLabel = (catId) => {
        for (const group of Object.values(categories)) {
            const match = group.find(item => item.id === catId);
            if (match) return match.label;
        }
        return 'Materials';
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (!formData.vendorName || !formData.amount || !formData.description) {
            setError('Vendor Name, Description, and Amount are required.');
            return;
        }

        try {
            setLoading(true);
            const submitData = {
                ...formData,
                projectId,
                category: getCategoryLabel(formData.categoryId),
                amount: Number(formData.amount),
                paidAmount: Number(formData.paidAmount),
                dueDate: formData.dueDate ? new Date(formData.dueDate) : null
            };

            if (initialData?.id) {
                await payableService.updatePayable(initialData.id, submitData);
            } else {
                await payableService.addPayable(currentUser.uid, submitData);
            }

            onClose();
        } catch (err) {
            console.error('Error adding/updating payable:', err);
            setError('Failed to save vendor payable. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal isOpen={isOpen} onClose={onClose} title={initialData ? "Edit Pending Bill" : "Add Vendor Payable"} maxWidth="max-w-md">
            {error && (
                <div className="mb-6 p-4 bg-red-50 text-red-600 rounded-xl flex items-center gap-3 font-medium text-sm border border-red-100">
                    <AlertCircle size={18} />
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-6">
                {/* Vendor Name */}
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Vendor / Supplier Name *</label>
                    <div className="relative">
                        <UserSquare2 className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text"
                            name="vendorName"
                            value={formData.vendorName}
                            onChange={handleChange}
                            placeholder="e.g. ABC Cements Ltd."
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                            required
                        />
                    </div>
                </div>

                {/* Description */}
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Invoice / Description *</label>
                    <div className="relative">
                        <FileText className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text"
                            name="description"
                            value={formData.description}
                            onChange={handleChange}
                            placeholder="e.g. Invoice #1024 for Batch 1"
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
                            {Object.entries(getFilteredCategories()).map(([groupName, items]) => (
                                <optgroup key={groupName} label={groupName}>
                                    {items.map(item => (
                                        <option key={item.id} value={item.id}>{item.label}</option>
                                    ))}
                                </optgroup>
                            ))}
                        </select>
                    </div>
                </div>

                {/* Amount */}
                <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Total Invoice Amount *</label>
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

                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Already Paid</label>
                        <div className="relative">
                            <IndianRupee className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="number"
                                name="paidAmount"
                                value={formData.paidAmount}
                                onChange={handleChange}
                                placeholder="0.00"
                                min="0"
                                step="0.01"
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                            />
                        </div>
                    </div>
                </div>

                {/* Date */}
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Payment Due Date</label>
                    <div className="relative">
                        <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="date"
                            name="dueDate"
                            value={formData.dueDate}
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
                            initialData ? 'Update Bill' : 'Save Payable'
                        )}
                    </button>
                </div>
            </form>
        </Modal>
    );
}
