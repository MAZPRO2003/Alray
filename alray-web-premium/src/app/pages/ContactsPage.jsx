import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    Search, UserPlus, Edit2, MessageSquareText
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { contactService } from '../services/contactService';
import AddContactDialog from '../components/contacts/AddContactDialog';
import EditContactDialog from '../components/contacts/EditContactDialog';
import { Link, useNavigate } from 'react-router-dom';

export default function ContactsPage() {
    const { currentUser } = useAuth();
    const navigate = useNavigate();
    const [contacts, setContacts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedRole, setSelectedRole] = useState('All');
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [editingContact, setEditingContact] = useState(null);

    useEffect(() => {
        if (!currentUser) return;
        const unsubscribe = contactService.subscribeToContacts(currentUser.uid, (data) => {
            setContacts(data);
            setLoading(false);
        });
        return () => unsubscribe();
    }, [currentUser]);

    // Extract unique roles for filter chips (only for non-Customers, but we'll include all here just in case)
    const workers = contacts.filter(c => c.role !== 'Customer');
    const roles = ['All', ...new Set(workers.map(c => c.role).filter(Boolean))].sort();

    // Apply search and role filters
    const filtered = workers.filter(c => {
        const matchesQuery = !searchQuery ||
            c.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            c.phoneNumber?.includes(searchQuery) ||
            c.company?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            c.role?.toLowerCase().includes(searchQuery.toLowerCase());

        const matchesRole = selectedRole === 'All' || c.role === selectedRole;
        return matchesQuery && matchesRole;
    });

    // Sort newest first, then by call count (if available)
    filtered.sort((a, b) => {
        const dateA = a.createdAt?.toDate ? a.createdAt.toDate() : (a.createdAt ? new Date(a.createdAt) : new Date(0));
        const dateB = b.createdAt?.toDate ? b.createdAt.toDate() : (b.createdAt ? new Date(b.createdAt) : new Date(0));

        if (dateA.getTime() !== dateB.getTime()) {
            return dateB.getTime() - dateA.getTime();
        }
        return (b.callCount || 0) - (a.callCount || 0);
    });

    const handleDelete = async (contact) => {
        if (window.confirm(`Are you sure you want to delete ${contact.name}?`)) {
            try {
                await contactService.deleteContact(contact.id);
            } catch (error) {
                console.error("Error deleting contact", error);
                alert("Failed to delete contact");
            }
        }
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: 'var(--color-secondary)' }}>People</h1>
                    <p style={{ color: 'var(--color-text-light)', fontSize: '14px', marginTop: '4px' }}>
                        Manage your network of contacts and professionals.
                    </p>
                </div>
            </div>

            {/* Search */}
            <div className="relative w-full max-w-md">
                <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                    type="text"
                    placeholder="Search people..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-12 pr-4 py-3 rounded-2xl bg-white shadow-sm border border-slate-100 focus:outline-none font-medium"
                />
            </div>

            {/* Role Filter Chips */}
            {roles.length > 1 && (
                <div className="flex gap-2 overflow-x-auto pb-2 w-full custom-scrollbar">
                    {roles.map(role => (
                        <button
                            key={role}
                            onClick={() => setSelectedRole(role)}
                            className="px-4 py-2 rounded-xl text-sm font-semibold whitespace-nowrap border transition-colors inline-flex items-center gap-1.5"
                            style={{
                                background: selectedRole === role ? 'rgba(79, 70, 229, 0.1)' : 'white',
                                color: selectedRole === role ? '#4f46e5' : 'var(--color-text-light)',
                                borderColor: selectedRole === role ? '#4f46e5' : 'var(--color-border)',
                            }}
                        >
                            {selectedRole === role && (
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
                                    <path fillRule="evenodd" d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z" clipRule="evenodd" />
                                </svg>
                            )}
                            {role}
                        </button>
                    ))}
                </div>
            )}

            {/* Content List */}
            {loading ? (
                <div className="space-y-4">
                    {[1, 2, 3].map(i => <div key={i} className="h-24 bg-white rounded-2xl animate-pulse border border-slate-100" />)}
                </div>
            ) : filtered.length === 0 ? (
                <div className="text-center py-20 text-slate-500 font-medium">
                    {searchQuery ? 'No matches found.' : 'No people added yet.'}
                </div>
            ) : (
                <div className="space-y-4 pb-24">
                    {filtered.map((contact, idx) => (
                        <motion.div
                            key={contact.id}
                            initial={{ opacity: 0, x: 20 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: idx * 0.05 }}
                        >
                            <Link to={`/app/contacts/${contact.id}`} className="block">
                                <div className="bg-white rounded-2xl border border-slate-100 p-4 flex items-center gap-4 hover:shadow-md transition-shadow cursor-pointer">
                                    <div className="w-14 h-14 rounded-full bg-indigo-50 flex items-center justify-center font-bold text-xl text-indigo-700 shrink-0">
                                        {contact.name?.charAt(0).toUpperCase() || '?'}
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <h3 className="font-bold text-slate-800 text-lg truncate">{contact.name}</h3>
                                        <p className="text-sm font-semibold text-indigo-600 truncate">{contact.role}</p>
                                    </div>

                                    <div className="flex gap-2">
                                        <button
                                            onClick={(e) => { e.preventDefault(); setEditingContact(contact); }}
                                            className="p-2 text-slate-400 hover:text-indigo-600 transition-colors"
                                        >
                                            <Edit2 size={18} />
                                        </button>
                                        <button
                                            onClick={(e) => { e.preventDefault(); handleDelete(contact); }}
                                            className="p-2 text-slate-400 hover:text-red-600 transition-colors"
                                        >
                                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"></path><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path></svg>
                                        </button>
                                    </div>
                                </div>
                            </Link>
                        </motion.div>
                    ))}
                </div>
            )}

            {/* Floating Action Buttons */}
            <div className="fixed bottom-6 right-6 flex flex-col gap-3 z-50">
                <motion.button
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => navigate('/app/chat')}
                    className="w-12 h-12 rounded-full flex items-center justify-center shadow-lg text-white"
                    style={{ background: '#4f46e5' }}
                    title="AI Chat Assistant"
                >
                    <MessageSquareText size={20} />
                </motion.button>
                <motion.button
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => setIsAddModalOpen(true)}
                    className="w-14 h-14 rounded-2xl flex items-center justify-center shadow-lg text-white"
                    style={{ background: 'var(--color-primary)' }}
                >
                    <UserPlus size={24} />
                </motion.button>
            </div>

            <AddContactDialog
                isOpen={isAddModalOpen}
                onClose={() => setIsAddModalOpen(false)}
            />

            <AnimatePresence>
                {editingContact && (
                    <EditContactDialog
                        isOpen={!!editingContact}
                        onClose={() => setEditingContact(null)}
                        contact={editingContact}
                    />
                )}
            </AnimatePresence>
        </div>
    );
}
