import React, { useState } from 'react';
import Modal from '../ui/Modal';
import { projectService } from '../../services/projectService';
import { Building2, Calendar, IndianRupee, MapPin, UserCheck, AlertCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function AddProjectDialog({ isOpen, onClose }) {
    const { currentUser } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [formData, setFormData] = useState({
        name: '',
        clientName: '',
        location: '',
        startDate: '',
        endDate: '',
        budget: '',
        description: ''
    });

    const handleChange = (e) => {
        setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (!formData.name || !formData.clientName || !formData.budget) {
            setError('Project Name, Client Name, and Budget are required.');
            return;
        }

        try {
            setLoading(true);
            await projectService.addProject(currentUser.uid, {
                ...formData,
                startDate: formData.startDate ? new Date(formData.startDate) : null,
                endDate: formData.endDate ? new Date(formData.endDate) : null
            });
            onClose();
            // Reset state
            setFormData({
                name: '',
                clientName: '',
                location: '',
                startDate: '',
                endDate: '',
                budget: '',
                description: ''
            });
        } catch (err) {
            console.error('Error adding project:', err);
            setError('Failed to add project. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal isOpen={isOpen} onClose={onClose} title="Create New Project" maxWidth="max-w-2xl">
            {error && (
                <div className="mb-6 p-4 bg-red-50 text-red-600 rounded-xl flex items-center gap-3 font-medium text-sm border border-red-100">
                    <AlertCircle size={18} />
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {/* Project Name */}
                    <div className="space-y-2 md:col-span-2">
                        <label className="text-sm font-bold text-gray-700">Project Name *</label>
                        <div className="relative">
                            <Building2 className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="text"
                                name="name"
                                value={formData.name}
                                onChange={handleChange}
                                placeholder="e.g. Al Safa Tower Construction"
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                                required
                            />
                        </div>
                    </div>

                    {/* Client Name */}
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Client / Owner *</label>
                        <div className="relative">
                            <UserCheck className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="text"
                                name="clientName"
                                value={formData.clientName}
                                onChange={handleChange}
                                placeholder="Client full name"
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                                required
                            />
                        </div>
                    </div>

                    {/* Location */}
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Location</label>
                        <div className="relative">
                            <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="text"
                                name="location"
                                value={formData.location}
                                onChange={handleChange}
                                placeholder="City or Site Address"
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium"
                            />
                        </div>
                    </div>

                    {/* Start Date */}
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Start Date</label>
                        <div className="relative">
                            <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="date"
                                name="startDate"
                                value={formData.startDate}
                                onChange={handleChange}
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium text-gray-700"
                            />
                        </div>
                    </div>

                    {/* End Date */}
                    <div className="space-y-2">
                        <label className="text-sm font-bold text-gray-700">Expected End Date</label>
                        <div className="relative">
                            <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="date"
                                name="endDate"
                                value={formData.endDate}
                                onChange={handleChange}
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium text-gray-700"
                            />
                        </div>
                    </div>

                    {/* Total Budget */}
                    <div className="space-y-2 md:col-span-2">
                        <label className="text-sm font-bold text-gray-700">Total Approved Budget *</label>
                        <div className="relative">
                            <IndianRupee className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                            <input
                                type="number"
                                name="budget"
                                value={formData.budget}
                                onChange={handleChange}
                                placeholder="0.00"
                                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-bold text-[var(--color-secondary)]"
                                required
                            />
                        </div>
                    </div>

                    {/* Description */}
                    <div className="space-y-2 md:col-span-2">
                        <label className="text-sm font-bold text-gray-700">Scope / Notes</label>
                        <textarea
                            name="description"
                            value={formData.description}
                            onChange={handleChange}
                            placeholder="Optional project description..."
                            rows={3}
                            className="w-full p-4 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-[var(--color-primary)] focus:bg-white transition-all text-sm font-medium resize-none"
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
                            'Create Project'
                        )}
                    </button>
                </div>
            </form>
        </Modal>
    );
}
