import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    Plus, Search, Phone, Mail, Building2,
    UserPlus, Users, Edit2, MoreVertical,
    ChevronRight, MapPin, Contact2, Heart
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { contactService } from '../services/contactService';
import AddContactDialog from '../components/contacts/AddContactDialog';
import EditContactDialog from '../components/contacts/EditContactDialog';
import { Link } from 'react-router-dom';

export default function ContactsPage() {
    const { currentUser } = useAuth();
    const [contacts, setContacts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
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

    const filtered = contacts.filter(c =>
        !searchQuery ||
        c.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        c.phoneNumber?.includes(searchQuery) ||
        c.company?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        c.role?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const grouped = filtered.reduce((acc, c) => {
        const key = c.category || 'Other';
        if (!acc[key]) acc[key] = [];
        acc[key].push(c);
        return acc;
    }, {});

    const categoryColors = {
        'Others': { bg: 'bg-indigo-50', text: 'text-indigo-700', border: 'border-indigo-100', dot: 'bg-indigo-500' },
        'Labour': { bg: 'bg-orange-50', text: 'text-orange-700', border: 'border-orange-100', dot: 'bg-orange-500' },
        'Client': { bg: 'bg-emerald-50', text: 'text-emerald-700', border: 'border-emerald-100', dot: 'bg-emerald-500' },
        'Other': { bg: 'bg-slate-50', text: 'text-slate-600', border: 'border-slate-100', dot: 'bg-slate-400' },
    };

    return (
        <div className="space-y-8">
            {/* Header */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
                <div>
                    <h1 className="text-3xl font-black text-slate-800 tracking-tight">Directory</h1>
                    <p className="text-slate-500 font-medium mt-1">
                        Manage your network of {contacts.length} people and professionals.
                    </p>
                </div>
                <button
                    onClick={() => setIsAddModalOpen(true)}
                    className="flex items-center gap-2 bg-slate-900 text-white px-8 py-3.5 rounded-[1.5rem] font-black text-sm shadow-xl shadow-slate-200 hover:scale-[1.02] transition-all"
                >
                    <UserPlus size={20} /> Add New Person
                </button>
            </div>

            {/* Search & Stats */}
            <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
                <div className="relative w-full max-w-md">
                    <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                        type="text"
                        placeholder="Search by name, role, or company..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-12 pr-4 py-4 rounded-2xl border-none bg-white shadow-sm focus:ring-2 focus:ring-red-500/10 font-medium transition-all"
                    />
                </div>

                <div className="flex gap-2 overflow-x-auto pb-2 w-full md:w-auto">
                    {Object.keys(grouped).map(cat => (
                        <span key={cat} className="px-4 py-2 rounded-xl bg-white text-[10px] font-black uppercase tracking-widest text-slate-500 border border-slate-100 whitespace-nowrap">
                            {cat}: {grouped[cat].length}
                        </span>
                    ))}
                </div>
            </div>

            {/* Content */}
            {loading ? (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                    {[1, 2, 3].map(i => <div key={i} className="h-40 bg-white rounded-[2.5rem] animate-pulse border border-slate-100" />)}
                </div>
            ) : filtered.length === 0 ? (
                <div className="bg-white rounded-[3rem] border border-slate-100 p-20 text-center shadow-sm">
                    <div className="w-20 h-20 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-6">
                        <Users size={40} className="text-slate-200" />
                    </div>
                    <p className="font-black text-xl text-slate-800">No match found</p>
                    <p className="text-slate-400 font-medium mt-2">Try adjusting your search or add a new person.</p>
                </div>
            ) : (
                <div className="space-y-12 pb-20">
                    {Object.entries(grouped).map(([category, items]) => {
                        const colors = categoryColors[category] || categoryColors['Other'];
                        return (
                            <div key={category} className="space-y-6">
                                <div className="flex items-center gap-4 px-2">
                                    <div className={`w-1.5 h-6 rounded-full ${colors.dot}`} />
                                    <h2 className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">{category}S</h2>
                                    <div className="flex-1 h-px bg-slate-100" />
                                </div>
                                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                                    {items.map((contact, idx) => (
                                        <motion.div
                                            key={contact.id}
                                            layout
                                            initial={{ opacity: 0, scale: 0.95 }}
                                            animate={{ opacity: 1, scale: 1 }}
                                            transition={{ delay: idx * 0.05 }}
                                            className="group relative"
                                        >
                                            <div className="bg-white rounded-[2.2rem] border border-slate-100 p-6 flex flex-col h-full hover:shadow-2xl hover:shadow-slate-200/50 transition-all duration-500">
                                                <div className="flex items-start justify-between mb-6">
                                                    <Link to={`/app/contacts/${contact.id}`} className="flex items-center gap-4 group/avatar">
                                                        <div className={`w-14 h-14 rounded-[1.2rem] ${colors.bg} flex items-center justify-center font-black text-xl ${colors.text} shadow-inner group-hover/avatar:scale-105 transition-transform`}>
                                                            {contact.name?.charAt(0).toUpperCase()}
                                                        </div>
                                                        <div className="min-w-0">
                                                            <h3 className="font-black text-slate-800 text-base truncate pr-2 group-hover:text-red-600 transition-colors">{contact.name}</h3>
                                                            <span className={`text-[10px] font-black uppercase tracking-widest px-2 py-0.5 rounded-md ${colors.bg} ${colors.text}`}>
                                                                {contact.role}
                                                            </span>
                                                        </div>
                                                    </Link>
                                                    <button
                                                        onClick={(e) => { e.preventDefault(); setEditingContact(contact); }}
                                                        className="p-2 rounded-xl text-slate-300 hover:text-slate-900 hover:bg-slate-50 transition-all"
                                                    >
                                                        <Edit2 size={16} />
                                                    </button>
                                                </div>

                                                <div className="space-y-3 mt-auto">
                                                    {contact.phoneNumber && (
                                                        <a href={`tel:${contact.phoneNumber}`} className="flex items-center gap-3 text-sm font-bold text-slate-600 hover:text-red-500 transition-colors">
                                                            <div className="w-8 h-8 rounded-xl bg-slate-50 flex items-center justify-center text-slate-400 group-hover:bg-red-50 group-hover:text-red-500 transition-colors">
                                                                <Phone size={14} />
                                                            </div>
                                                            {contact.phoneNumber}
                                                        </a>
                                                    )}
                                                    {contact.company && (
                                                        <div className="flex items-center gap-3 text-sm font-bold text-slate-400">
                                                            <div className="w-8 h-8 rounded-xl bg-slate-50 flex items-center justify-center">
                                                                <Building2 size={14} />
                                                            </div>
                                                            <span className="truncate">{contact.company}</span>
                                                        </div>
                                                    )}
                                                </div>

                                                <Link
                                                    to={`/app/contacts/${contact.id}`}
                                                    className="mt-6 flex items-center justify-center gap-2 py-3 rounded-2xl bg-slate-50 text-[10px] font-black uppercase tracking-widest text-slate-500 hover:bg-slate-900 hover:text-white transition-all"
                                                >
                                                    View Details <ChevronRight size={14} />
                                                </Link>
                                            </div>
                                        </motion.div>
                                    ))}
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}

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
