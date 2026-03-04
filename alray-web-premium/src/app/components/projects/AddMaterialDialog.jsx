import React, { useState } from 'react';
import Modal from '../ui/Modal';
import { materialService } from '../../services/materialService';
import { PackageOpen, IndianRupee, Hash, UserSquare2, AlertCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function AddMaterialDialog({ isOpen, onClose, projectId, initialData }) {
    const { currentUser } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const defaultState = {
        type: 'Material',
        categoryId: 'cement-M',
        description: '',
        quantity: '',
        unit: 'bags',
        rate: '',
        supplier: '',
        invoiceNumber: '',
        date: new Date().toISOString().split('T')[0]
    };

    const [formData, setFormData] = useState(defaultState);

    React.useEffect(() => {
        if (isOpen) {
            if (initialData) {
                setFormData({
                    type: initialData.type || 'Material',
                    categoryId: initialData.categoryId || 'cement-M',
                    description: initialData.description || '',
                    quantity: initialData.quantity || '',
                    unit: initialData.unit || 'bags',
                    rate: initialData.rate || '',
                    supplier: initialData.supplier || '',
                    invoiceNumber: initialData.invoiceNumber || '',
                    date: initialData.date ? new Date(initialData.date).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]
                });
            } else {
                setFormData(defaultState);
            }
        }
    }, [isOpen, initialData]);

    // Auto-calculate amount
    const amount = (parseFloat(formData.quantity) || 0) * (parseFloat(formData.rate) || 0);

    const handleChange = (e) => {
        setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (!formData.description || !formData.quantity || !formData.rate) {
            setError('Description, Quantity, and Rate are required.');
            return;
        }

        try {
            setLoading(true);
            const submitData = {
                ...formData,
                projectId,
                amount,
                quantity: Number(formData.quantity),
                rate: Number(formData.rate),
                date: new Date(formData.date)
            };

            if (initialData?.id) {
                await materialService.updateMaterial(initialData.id, submitData);
            } else {
                await materialService.addMaterial(currentUser.uid, submitData);
            }

            onClose();
        } catch (err) {
            console.error('Error adding material:', err);
            setError('Failed to add entry. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    const categories = [
        { id: 'cement-M', label: 'Cement' },
        { id: 'steel-M', label: 'Steel' },
        { id: 'sand-M', label: 'Sand' },
        { id: 'aggregate-M', label: 'Aggregate' },
        { id: 'bricks-M', label: 'Bricks/Blocks' },
        { id: 'plumbing-M', label: 'Plumbing' },
        { id: 'electrical-M', label: 'Electrical' },
        { id: 'paint-M', label: 'Paint' },
        { id: 'wood-M', label: 'Wood/Carpentry' },
        { id: 'tiles-M', label: 'Tiles/Marble' },
        { id: 'otherMiscMaterials', label: 'Other' }
    ];
    const types = ['Material', 'Equipment', 'Service', 'Other'];

    return (
        <Modal isOpen={isOpen} onClose={onClose} title={initialData ? "Edit Construction Entry" : "Add Construction Entry"} maxWidth="max-w-2xl">
            {error && (
                <div className="mb-6 p-4 bg-red-50 text-red-600 rounded-xl flex items-center gap-3 font-medium text-sm border border-red-100">
                    <AlertCircle size={18} />
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {/* Description */}
                    <div className="space-y-2 md:col-span-2">
                        <label className="text-sm font-bold text-gray-700">Description / Item Name *</label>
                        <div className="relative">
                            <PackageOpen className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="text"
                                name="description"
                                value={formData.description}
                                onChange={handleChange}
                                placeholder="e.g. UltraTech Cement 53 Grade"
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                                required
                            />
                        </div>
                    </div>

                    {/* Type */}
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Type</label>
                        <select
                            name="type"
                            value={formData.type}
                            onChange={handleChange}
                            className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                        >
                            {types.map(t => <option key={t} value={t}>{t}</option>)}
                        </select>
                    </div>

                    {/* Category */}
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Category</label>
                        <select
                            name="categoryId"
                            value={formData.categoryId}
                            onChange={handleChange}
                            className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                        >
                            {categories.map(c => <option key={c.id} value={c.id}>{c.label}</option>)}
                        </select>
                    </div>

                    {/* Quantity & Unit */}
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Quantity & Unit *</label>
                        <div className="flex gap-2">
                            <div className="relative flex-1">
                                <Hash className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                                <input
                                    type="number"
                                    name="quantity"
                                    value={formData.quantity}
                                    onChange={handleChange}
                                    placeholder="0"
                                    min="0"
                                    step="0.01"
                                    className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                                    required
                                />
                            </div>
                            <input
                                type="text"
                                name="unit"
                                value={formData.unit}
                                onChange={handleChange}
                                placeholder="bags, tons"
                                className="w-24 px-3 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                            />
                        </div>
                    </div>

                    {/* Rate */}
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Rate / Price per unit *</label>
                        <div className="relative">
                            <IndianRupee className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="number"
                                name="rate"
                                value={formData.rate}
                                onChange={handleChange}
                                placeholder="0.00"
                                min="0"
                                step="0.01"
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                                required
                            />
                        </div>
                    </div>

                    {/* Total Amount (Readonly) */}
                    <div className="space-y-2 md:col-span-2">
                        <label className="text-sm font-bold text-gray-700">Calculated Total Amount</label>
                        <div className="relative">
                            <IndianRupee className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-primary)]" size={18} />
                            <input
                                type="text"
                                value={amount.toFixed(2)}
                                readOnly
                                className="w-full pl-10 pr-4 py-4 bg-[var(--color-primary)]/5 border border-[var(--color-primary)]/20 rounded-xl focus:outline-none transition-all text-lg font-bold text-[var(--color-secondary)]"
                            />
                        </div>
                    </div>

                    {/* Supplier */}
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Supplier / Vendor</label>
                        <div className="relative">
                            <UserSquare2 className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="text"
                                name="supplier"
                                value={formData.supplier}
                                onChange={handleChange}
                                placeholder="Supplier name"
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                            />
                        </div>
                    </div>

                    {/* Date */}
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Date</label>
                        <input
                            type="date"
                            name="date"
                            value={formData.date}
                            onChange={handleChange}
                            className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium text-gray-700"
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
                            initialData ? 'Update Entry' : 'Save Entry'
                        )}
                    </button>
                </div>
            </form>
        </Modal>
    );
}
