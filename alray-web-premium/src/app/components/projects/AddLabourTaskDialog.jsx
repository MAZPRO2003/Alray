import React, { useState } from 'react';
import Modal from '../ui/Modal';
import { laborTaskService } from '../../services/labourService';
import { Hammer, Users, User, Calendar, AlertCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function AddLabourTaskDialog({ isOpen, onClose, projectId, initialData }) {
    const { currentUser } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const defaultState = {
        name: '',
        laborerCount: '1',
        role: '',
        startDate: new Date().toISOString().split('T')[0]
    };
    const [formData, setFormData] = useState(defaultState);

    React.useEffect(() => {
        if (isOpen) {
            if (initialData) {
                setFormData({
                    name: initialData.name || '',
                    laborerCount: initialData.laborerCount?.toString() || '1',
                    role: initialData.role || '',
                    startDate: initialData.startDate ? new Date(initialData.startDate).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]
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

        if (!formData.name || !formData.laborerCount || !formData.role) {
            setError('All fields are required.');
            return;
        }

        try {
            setLoading(true);
            const submitData = {
                projectId,
                ...formData,
                laborerCount: parseInt(formData.laborerCount),
                startDate: new Date(formData.startDate)
            };

            if (initialData?.id) {
                await laborTaskService.updateTask(initialData.id, submitData);
            } else {
                await laborTaskService.addLaborTask(currentUser.uid, submitData);
            }
            onClose();
        } catch (err) {
            console.error('Error adding labor task:', err);
            setError('Failed to add labor task. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal isOpen={isOpen} onClose={onClose} title={initialData ? "Edit Labor Task" : "Add Labor Task"} maxWidth="max-w-md">
            {error && (
                <div className="mb-6 p-4 bg-red-50 text-red-600 rounded-xl flex items-center gap-3 font-medium text-sm border border-red-100">
                    <AlertCircle size={18} />
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-6">
                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Task Name *</label>
                    <div className="relative">
                        <Hammer className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text" name="name" value={formData.name} onChange={handleChange}
                            placeholder="e.g. Brickwork"
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500 focus:bg-white transition-all text-sm font-medium"
                            required
                        />
                    </div>
                </div>

                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Laborer Count *</label>
                    <div className="relative">
                        <Users className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="number" name="laborerCount" value={formData.laborerCount} onChange={handleChange}
                            min="1"
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500 focus:bg-white transition-all text-sm font-medium"
                            required
                        />
                    </div>
                </div>

                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Role *</label>
                    <div className="relative">
                        <User className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="text" name="role" value={formData.role} onChange={handleChange}
                            placeholder="e.g. Masons"
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500 focus:bg-white transition-all text-sm font-medium"
                            required
                        />
                    </div>
                </div>

                <div className="space-y-2">
                    <label className="text-sm font-bold text-gray-700">Start Date *</label>
                    <div className="relative">
                        <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input
                            type="date" name="startDate" value={formData.startDate} onChange={handleChange}
                            className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-blue-500 focus:bg-white transition-all text-sm font-medium text-gray-700"
                            required
                        />
                    </div>
                </div>

                <div className="flex gap-3 pt-6 border-t border-gray-100">
                    <button type="button" onClick={onClose} className="flex-1 btn bg-gray-100 text-gray-700 hover:bg-gray-200 py-3">Cancel</button>
                    <button type="submit" disabled={loading} className="flex-1 btn bg-blue-600 text-white hover:bg-blue-700 py-3 disabled:opacity-70 flex justify-center items-center">
                        {loading ? <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" /> : (initialData ? 'Update Task' : 'Add Task')}
                    </button>
                </div>
            </form>
        </Modal>
    );
}
