import React, { useState } from 'react';
import Modal from '../ui/Modal';
import { laborService } from '../../services/labourService';
import { UserSquare2, Tag, AlertCircle, PlusCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { motion } from 'framer-motion';

export default function AddLaborDialog({ isOpen, onClose }) {
    const { currentUser } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [isCustomRole, setIsCustomRole] = useState(false);
    const [formData, setFormData] = useState({
        name: '',
        category: 'Helper',
        customRole: ''
    });

    const categories = ['Helper', 'Mason', 'Carpenter', 'Plumber', 'Electrician', 'Painter', 'Driver', 'Contractor', 'Other'];

    const handleChange = (e) => {
        const { name, value } = e.target;
        if (name === 'category') {
            setIsCustomRole(value === 'Other');
        }
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (!formData.name) {
            setError('Name is required.');
            return;
        }

        try {
            setLoading(true);
            const finalCategory = isCustomRole ? formData.customRole : formData.category;

            await laborService.addLaborer(currentUser.uid, {
                name: formData.name,
                category: finalCategory || 'Other',
                wagePerDay: 0 // Defaulting as user wanted daily wage option removed
            });

            onClose();
            // Reset state
            setFormData({ name: '', category: 'Helper', customRole: '' });
            setIsCustomRole(false);
        } catch (err) {
            console.error('Error adding laborer:', err);
            setError('Failed to add laborer. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal isOpen={isOpen} onClose={onClose} title="Add New Person" maxWidth="max-w-md">
            {error && (
                <div className="mb-6 p-4 bg-red-50 text-red-600 rounded-xl flex items-center gap-3 font-medium text-sm border border-red-100">
                    <AlertCircle size={18} />
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-6">
                {/* Name */}
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Full Name *</label>
                    <div className="relative">
                        <UserSquare2 className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text"
                            name="name"
                            value={formData.name}
                            onChange={handleChange}
                            placeholder="e.g. Ramesh Kumar"
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                            required
                        />
                    </div>
                </div>

                {/* Category */}
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Role / Category *</label>
                    <div className="relative">
                        <Tag className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <select
                            name="category"
                            value={formData.category}
                            onChange={handleChange}
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium appearance-none"
                        >
                            {categories.map(c => <option key={c} value={c}>{c}</option>)}
                        </select>
                    </div>
                </div>

                {/* Custom Role Input */}
                {isCustomRole && (
                    <motion.div
                        initial={{ opacity: 0, height: 0 }}
                        animate={{ opacity: 1, height: 'auto' }}
                        className="space-y-2"
                    >
                        <label className="text-sm font-bold text-gray-700">Enter Custom Role</label>
                        <div className="relative">
                            <PlusCircle className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="text"
                                name="customRole"
                                value={formData.customRole}
                                onChange={handleChange}
                                placeholder="e.g. Supervisor"
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                            />
                        </div>
                    </motion.div>
                )}

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
                            'Save Person'
                        )}
                    </button>
                </div>
            </form>
        </Modal>
    );
}
