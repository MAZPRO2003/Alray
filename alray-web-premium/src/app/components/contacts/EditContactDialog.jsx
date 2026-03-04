import React, { useState, useEffect } from 'react';
import Modal from '../ui/Modal';
import { contactService } from '../../services/contactService';
import { UserSquare2, Phone, Mail, MapPin, Tag, AlertCircle, PlusCircle, Building2, Trash2 } from 'lucide-react';
import { motion } from 'framer-motion';

export default function EditContactDialog({ isOpen, onClose, contact }) {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [isCustomRole, setIsCustomRole] = useState(false);
    const [formData, setFormData] = useState({
        name: '',
        role: '',
        customRole: '',
        phoneNumber: '',
        email: '',
        address: '',
        company: ''
    });

    const roleGroups = {
        'Labour': [
            'Mason / Labour',
            'Electrician',
            'Plumber',
            'Carpenter',
            'Tile Fixer',
            'Painter',
            'Helper',
            'Misc Labour',
        ],
        'Others': [
            'Contractor',
            'Client',
            'Supervisor',
            'Architect',
            'Engineer',
            'Other',
        ],
    };

    const allPredefinedRoles = Object.values(roleGroups).flat();

    useEffect(() => {
        if (contact) {
            const isPredefined = allPredefinedRoles.includes(contact.role);
            setFormData({
                name: contact.name || '',
                role: isPredefined ? contact.role : 'Other',
                customRole: isPredefined ? '' : contact.role,
                phoneNumber: contact.phoneNumber || '',
                email: contact.email || '',
                address: contact.address || '',
                company: contact.company || ''
            });
            setIsCustomRole(!isPredefined);
        }
    }, [contact]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        if (name === 'role') {
            setIsCustomRole(value === 'Other');
        }
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (!formData.name || !formData.phoneNumber) {
            setError('Name and Phone Number are required.');
            return;
        }

        try {
            setLoading(true);
            const finalRole = isCustomRole ? formData.customRole : formData.role;
            const category = isCustomRole ? 'Other' : (Object.keys(roleGroups).find(k => roleGroups[k].includes(formData.role)) || 'Other');

            await contactService.updateContact(contact.id, {
                ...formData,
                role: finalRole || 'Other',
                category: category
            });

            onClose();
        } catch (err) {
            console.error('Error updating contact:', err);
            setError('Failed to update contact. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async () => {
        if (!window.confirm(`Are you sure you want to delete ${contact.name}?`)) return;

        try {
            setLoading(true);
            await contactService.deleteContact(contact.id);
            onClose();
        } catch (err) {
            console.error('Error deleting contact:', err);
            setError('Failed to delete. Please try again.');
            setLoading(false);
        }
    };

    return (
        <Modal isOpen={isOpen} onClose={onClose} title="Edit Person Details" maxWidth="max-w-md">
            {error && (
                <div className="mb-6 p-4 bg-red-50 text-red-600 rounded-xl flex items-center gap-3 font-medium text-sm border border-red-100">
                    <AlertCircle size={18} />
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
                {/* Name */}
                <div className="space-y-1">
                    <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-1">Full Name *</label>
                    <div className="relative">
                        <UserSquare2 className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                        <input
                            type="text" name="name" value={formData.name} onChange={handleChange}
                            placeholder="e.g. Ramesh Kumar"
                            className="w-full pl-12 pr-4 py-3.5 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-red-500/20 transition-all text-sm font-bold text-slate-700"
                            required
                        />
                    </div>
                </div>

                {/* Role / Category */}
                <div className="space-y-1">
                    <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-1">Role / Category *</label>
                    <div className="relative">
                        <Tag className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                        <select
                            name="role" value={formData.role} onChange={handleChange}
                            className="w-full pl-12 pr-4 py-3.5 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-red-500/20 transition-all text-sm font-bold text-slate-700 appearance-none"
                        >
                            {Object.entries(roleGroups).map(([group, roles]) => (
                                <optgroup key={group} label={group}>
                                    {roles.map(r => <option key={r} value={r}>{r}</option>)}
                                </optgroup>
                            ))}
                        </select>
                    </div>
                </div>

                {/* Custom Role */}
                {isCustomRole && (
                    <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="space-y-1">
                        <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-1">Enter Role</label>
                        <div className="relative">
                            <PlusCircle className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                            <input
                                type="text" name="customRole" value={formData.customRole} onChange={handleChange}
                                placeholder="e.g. Interior Designer"
                                className="w-full pl-12 pr-4 py-3.5 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-red-500/20 transition-all text-sm font-bold text-slate-700"
                            />
                        </div>
                    </motion.div>
                )}

                {/* Phone */}
                <div className="space-y-1">
                    <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-1">Phone Number *</label>
                    <div className="relative">
                        <Phone className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                        <input
                            type="tel" name="phoneNumber" value={formData.phoneNumber} onChange={handleChange}
                            placeholder="10 digit number"
                            className="w-full pl-12 pr-4 py-3.5 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-red-500/20 transition-all text-sm font-bold text-slate-700"
                            required
                        />
                    </div>
                </div>

                {/* Company */}
                <div className="space-y-1">
                    <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-1">Company</label>
                    <div className="relative">
                        <Building2 className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                        <input
                            type="text" name="company" value={formData.company} onChange={handleChange}
                            placeholder="e.g. Alray Associates"
                            className="w-full pl-12 pr-4 py-3.5 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-red-500/20 transition-all text-sm font-bold text-slate-700"
                        />
                    </div>
                </div>

                {/* Footer Buttons */}
                <div className="flex flex-col gap-3 pt-6 border-t border-slate-100">
                    <div className="flex gap-3">
                        <button
                            type="button" onClick={onClose}
                            className="flex-1 py-3.5 rounded-2xl bg-slate-100 text-slate-600 font-black text-sm hover:bg-slate-200 transition-all"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit" disabled={loading}
                            className="flex-1 py-3.5 rounded-2xl bg-black text-white font-black text-sm shadow-xl shadow-slate-200 hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50"
                        >
                            {loading ? 'Saving...' : 'Update Person'}
                        </button>
                    </div>

                    <button
                        type="button" onClick={handleDelete} disabled={loading}
                        className="w-full py-3.5 rounded-2xl text-red-600 font-black text-sm hover:bg-red-50 transition-all flex items-center justify-center gap-2"
                    >
                        <Trash2 size={16} /> Delete Person
                    </button>
                </div>
            </form>
        </Modal>
    );
}
