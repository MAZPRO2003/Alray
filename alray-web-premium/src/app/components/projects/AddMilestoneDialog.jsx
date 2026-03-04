import React, { useState } from 'react';
import Modal from '../ui/Modal';
import { milestoneService } from '../../services/milestoneService';
import { Flag, AlertCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function AddMilestoneDialog({ isOpen, onClose, projectId }) {
    const { currentUser } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [title, setTitle] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!title.trim()) return;

        try {
            setLoading(true);
            await milestoneService.addMilestone(currentUser.uid, {
                projectId,
                title: title.trim()
            });
            setTitle('');
            onClose();
        } catch (err) {
            console.error('Error adding milestone:', err);
            setError('Failed to add milestone.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal isOpen={isOpen} onClose={onClose} title="Add Project Milestone" maxWidth="max-w-md">
            {error && (
                <div className="mb-4 p-3 bg-red-50 text-red-600 rounded-lg flex items-center gap-2 text-sm">
                    <AlertCircle size={16} />
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Milestone Title</label>
                    <div className="relative">
                        <Flag className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            placeholder="e.g. Completion of Ground Floor"
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                            required
                            autoFocus
                        />
                    </div>
                </div>

                <div className="flex gap-3 pt-4">
                    <button type="button" onClick={onClose} className="flex-1 btn bg-gray-100 text-gray-700 hover:bg-gray-200 py-2.5">
                        Cancel
                    </button>
                    <button type="submit" disabled={loading || !title.trim()} className="flex-1 btn btn-primary py-2.5 disabled:opacity-50">
                        {loading ? 'Adding...' : 'Add Milestone'}
                    </button>
                </div>
            </form>
        </Modal>
    );
}
