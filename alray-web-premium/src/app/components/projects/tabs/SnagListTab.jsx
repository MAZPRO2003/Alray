import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Plus, CheckCircle2, AlertCircle, Clock, MoreVertical, Edit2, Trash2, ShieldAlert } from 'lucide-react';
import { snagService } from '../../../services/snagService';
import { useAuth } from '../../../context/AuthContext';
import AddSnagItemDialog from '../AddSnagItemDialog';

export default function SnagListTab({ projectId }) {
    const { currentUser } = useAuth();
    const [snags, setSnags] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isAddOpen, setIsAddOpen] = useState(false);
    const [editingSnag, setEditingSnag] = useState(null);

    useEffect(() => {
        if (!currentUser) return;
        const unsubscribe = snagService.subscribeToProjectSnags(currentUser.uid, projectId, (data) => {
            setSnags(data);
            setLoading(false);
        });
        return () => unsubscribe();
    }, [projectId, currentUser]);

    const handleEdit = (snag) => {
        setEditingSnag(snag);
        setIsAddOpen(true);
    };

    const handleDelete = async (id) => {
        if (window.confirm("Are you sure you want to delete this issue?")) {
            try {
                await snagService.deleteSnagItem(id);
            } catch (error) {
                console.error("Error deleting snag", error);
            }
        }
    };

    const getPriorityColor = (p) => {
        switch (p) {
            case 'high': return 'text-red-600 bg-red-50 border-red-100';
            case 'medium': return 'text-orange-600 bg-orange-50 border-orange-100';
            case 'low': return 'text-green-600 bg-green-50 border-green-100';
            default: return 'text-gray-600 bg-gray-50 border-gray-100';
        }
    };

    const getStatusIcon = (s) => {
        switch (s) {
            case 'resolved': return <CheckCircle2 className="text-green-500" size={18} />;
            case 'inProgress': return <Clock className="text-orange-500" size={18} />;
            default: return <AlertCircle className="text-red-400" size={18} />;
        }
    };

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-6">
            <div className="flex justify-between items-center">
                <div className="flex items-center gap-3">
                    <div className="p-2 bg-red-50 rounded-xl text-red-600">
                        <ShieldAlert size={20} />
                    </div>
                    <div>
                        <h3 className="text-lg font-bold text-[var(--color-secondary)]">Defect Tracking</h3>
                        <p className="text-xs text-gray-500 font-medium">{snags.filter(s => s.status !== 'resolved').length} open issues remaining</p>
                    </div>
                </div>
                <button
                    onClick={() => { setEditingSnag(null); setIsAddOpen(true); }}
                    className="btn btn-primary flex items-center gap-2 px-4 py-2 text-sm shadow-md"
                >
                    <Plus size={18} />
                    Record Issue
                </button>
            </div>

            {loading ? (
                <div className="p-12 text-center text-gray-400">Loading issues...</div>
            ) : snags.length === 0 ? (
                <div className="p-20 text-center bg-gray-50/50 rounded-3xl border border-dashed border-gray-200">
                    <ShieldAlert size={48} className="mx-auto text-gray-200 mb-4" />
                    <p className="text-gray-400 font-bold uppercase tracking-widest text-xs">No issues found</p>
                    <p className="text-gray-500 mt-2 text-sm max-w-xs mx-auto">This project is currently issue-free. Great work!</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 gap-4">
                    {snags.map((snag) => (
                        <motion.div
                            key={snag.id}
                            layout
                            className={`p-5 rounded-2xl border transition-all ${snag.status === 'resolved' ? 'bg-gray-50 border-gray-100 opacity-75' : 'bg-white border-gray-100 shadow-sm hover:shadow-md'}`}
                        >
                            <div className="flex justify-between items-start gap-4">
                                <div className="flex-1 space-y-3">
                                    <div className="flex items-center gap-3">
                                        {getStatusIcon(snag.status)}
                                        <span className={`px-2 py-0.5 rounded-md text-[10px] font-black uppercase tracking-tighter border ${getPriorityColor(snag.priority)}`}>
                                            {snag.priority} Priority
                                        </span>
                                        <span className="text-[10px] font-bold text-gray-400">
                                            {new Date(snag.createdAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
                                        </span>
                                    </div>
                                    <p className={`text-sm font-bold leading-relaxed ${snag.status === 'resolved' ? 'text-gray-400 line-through' : 'text-[var(--color-secondary)]'}`}>
                                        {snag.description}
                                    </p>
                                    {snag.resolvedAt && (
                                        <p className="text-[10px] font-medium text-green-600 flex items-center gap-1">
                                            <CheckCircle2 size={10} />
                                            Resolved on {new Date(snag.resolvedAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
                                        </p>
                                    )}
                                </div>
                                <div className="flex items-center gap-1">
                                    <button
                                        onClick={() => handleEdit(snag)}
                                        className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-colors"
                                    >
                                        <Edit2 size={16} />
                                    </button>
                                    <button
                                        onClick={() => handleDelete(snag.id)}
                                        className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-colors"
                                    >
                                        <Trash2 size={16} />
                                    </button>
                                </div>
                            </div>
                        </motion.div>
                    ))}
                </div>
            )}

            <AddSnagItemDialog
                isOpen={isAddOpen}
                onClose={() => setIsAddOpen(false)}
                projectId={projectId}
                existingSnag={editingSnag}
            />
        </motion.div>
    );
}
