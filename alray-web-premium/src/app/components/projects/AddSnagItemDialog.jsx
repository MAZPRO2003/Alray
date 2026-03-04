import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, CheckCircle2, AlertCircle, MessageSquare } from 'lucide-react';
import { snagService } from '../../services/snagService';
import { useAuth } from '../../context/AuthContext';

export default function AddSnagItemDialog({ isOpen, onClose, projectId, existingSnag }) {
    const { currentUser } = useAuth();
    const [loading, setLoading] = useState(false);
    const [formData, setFormData] = useState({
        description: '',
        priority: 'medium',
        status: 'pending'
    });

    useEffect(() => {
        if (existingSnag) {
            setFormData({
                description: existingSnag.description || '',
                priority: existingSnag.priority || 'medium',
                status: existingSnag.status || 'pending'
            });
        } else {
            setFormData({
                description: '',
                priority: 'medium',
                status: 'pending'
            });
        }
    }, [existingSnag, isOpen]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!currentUser || loading) return;

        setLoading(true);
        try {
            if (existingSnag) {
                await snagService.updateSnagItem(existingSnag.id, formData);
            } else {
                await snagService.addSnagItem(currentUser.uid, {
                    ...formData,
                    projectId
                });
            }
            onClose();
        } catch (error) {
            console.error("Error saving snag:", error);
            alert("Failed to save issue. Please try again.");
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
                    className="bg-white rounded-3xl shadow-2xl w-full max-w-md overflow-hidden"
                >
                    <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                        <h2 className="text-xl font-bold text-[var(--color-secondary)]">
                            {existingSnag ? 'Edit Issue' : 'Add New Issue'}
                        </h2>
                        <button onClick={onClose} className="p-2 hover:bg-gray-200 rounded-full transition-colors">
                            <X size={20} />
                        </button>
                    </div>

                    <form onSubmit={handleSubmit} className="p-6 space-y-6">
                        <div className="space-y-4">
                            {/* Description */}
                            <div>
                                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 text-center">ISSUE DESCRIPTION</label>
                                <div className="relative">
                                    <MessageSquare className="absolute left-4 top-4 text-gray-400" size={18} />
                                    <textarea
                                        required
                                        placeholder="e.g. Tile crack in master bedroom balcony..."
                                        value={formData.description}
                                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                        className="w-full pl-12 pr-4 py-4 bg-gray-50 border border-gray-200 rounded-2xl focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 focus:border-[var(--color-primary)] transition-all min-h-[120px] font-medium"
                                    />
                                </div>
                            </div>

                            {/* Priority Selection */}
                            <div>
                                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 text-center">PRIORITY LEVEL</label>
                                <div className="grid grid-cols-3 gap-3">
                                    {['low', 'medium', 'high'].map((p) => (
                                        <button
                                            key={p}
                                            type="button"
                                            onClick={() => setFormData({ ...formData, priority: p })}
                                            className={`py-3 rounded-xl text-xs font-bold uppercase tracking-widest border-2 transition-all ${formData.priority === p
                                                    ? p === 'high' ? 'bg-red-50 border-red-500 text-red-700' : p === 'medium' ? 'bg-orange-50 border-orange-500 text-orange-700' : 'bg-green-50 border-green-500 text-green-700'
                                                    : 'bg-white border-gray-100 text-gray-400 hover:border-gray-200'
                                                }`}
                                        >
                                            {p}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            {/* Status Selection (Only if editing) */}
                            {existingSnag && (
                                <div>
                                    <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 text-center">CURRENT STATUS</label>
                                    <select
                                        value={formData.status}
                                        onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                                        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]/20 focus:border-[var(--color-primary)] transition-all text-sm font-bold text-[var(--color-secondary)] appearance-none text-center"
                                    >
                                        <option value="pending">PENDING</option>
                                        <option value="inProgress">IN PROGRESS</option>
                                        <option value="resolved">RESOLVED</option>
                                    </select>
                                </div>
                            )}
                        </div>

                        <button
                            disabled={loading}
                            type="submit"
                            className="w-full btn btn-primary py-4 flex items-center justify-center gap-2 text-lg shadow-lg shadow-[var(--color-primary)]/20"
                        >
                            {loading ? (
                                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                            ) : (
                                <CheckCircle2 size={20} />
                            )}
                            {existingSnag ? 'Update Issue' : 'Record Issue'}
                        </button>
                    </form>
                </motion.div>
            </div>
        </AnimatePresence>
    );
}
