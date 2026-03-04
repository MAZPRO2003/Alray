import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowLeft, UserSquare2, Building2, Phone, Mail, MapPin, Briefcase } from 'lucide-react';
import { contactService } from '../services/contactService';
import { useAuth } from '../context/AuthContext';

export default function ContactDetailsPage() {
    const { id } = useParams();
    const [contact, setContact] = useState(null);
    const [loading, setLoading] = useState(true);

    const { currentUser } = useAuth();

    useEffect(() => {
        if (!currentUser) return;

        const unsubscribe = contactService.subscribeToContact(id, (data) => {
            setContact(data);
            setLoading(false);
        });

        return () => unsubscribe();
    }, [id, currentUser]);

    if (loading) return <div className="p-10 text-center text-gray-500">Loading contact details...</div>;
    if (!contact) return <div className="p-10 text-center text-red-500">Contact not found</div>;

    return (
        <div className="space-y-6 max-w-4xl mx-auto">
            {/* Header / Back Link */}
            <div>
                <Link to="/app/contacts" className="flex items-center gap-2 text-gray-500 hover:text-[var(--color-primary)] transition-colors mb-4 text-sm font-medium w-fit">
                    <ArrowLeft size={16} />
                    Back to Directory
                </Link>
            </div>

            {/* Profile Card */}
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-3xl p-8 border border-gray-100 shadow-sm relative overflow-hidden">
                <div className="absolute top-0 left-0 w-full h-32 bg-gradient-to-r from-[var(--color-primary)]/10 to-blue-50/50"></div>

                <div className="relative z-10 flex flex-col md:flex-row items-center md:items-start gap-8 mt-8">
                    {/* Avatar */}
                    <div className="w-32 h-32 rounded-full bg-white border-4 border-white shadow-lg flex items-center justify-center text-5xl font-bold text-[var(--color-primary)] bg-gradient-to-br from-[var(--color-primary)]/10 to-[var(--color-primary)]/5 shrink-0">
                        {contact.name.charAt(0).toUpperCase()}
                    </div>

                    {/* Info */}
                    <div className="flex-1 text-center md:text-left space-y-4">
                        <div>
                            <span className="bg-[var(--color-primary)]/10 text-[var(--color-primary)] px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider mb-3 inline-block">
                                {contact.category || 'Contact'}
                            </span>
                            <h1 className="text-3xl font-bold text-[var(--color-secondary)]">{contact.name}</h1>
                            {contact.company && (
                                <p className="text-lg text-gray-500 font-medium flex items-center justify-center md:justify-start gap-2 mt-2">
                                    <Building2 size={20} />
                                    {contact.company}
                                </p>
                            )}
                        </div>

                        <div className="flex flex-wrap gap-4 pt-4 border-t border-gray-100 justify-center md:justify-start">
                            {contact.phone && (
                                <a href={`tel:${contact.phone}`} className="flex items-center gap-2 bg-gray-50 hover:bg-[var(--color-primary)]/10 hover:text-[var(--color-primary)] px-4 py-2 rounded-xl transition-colors font-medium text-gray-700">
                                    <Phone size={16} />
                                    {contact.phone}
                                </a>
                            )}
                            {contact.email && (
                                <a href={`mailto:${contact.email}`} className="flex items-center gap-2 bg-gray-50 hover:bg-[var(--color-primary)]/10 hover:text-[var(--color-primary)] px-4 py-2 rounded-xl transition-colors font-medium text-gray-700">
                                    <Mail size={16} />
                                    {contact.email}
                                </a>
                            )}
                        </div>
                    </div>
                </div>
            </motion.div>

            {/* Details Section */}
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="grid grid-cols-1 md:grid-cols-2 gap-6">

                {/* About Box */}
                <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-sm">
                    <h3 className="text-lg font-bold text-[var(--color-secondary)] mb-4 flex items-center gap-2">
                        <UserSquare2 size={20} className="text-gray-400" />
                        Contact Details
                    </h3>
                    <div className="space-y-4">
                        <div>
                            <p className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">Full Name</p>
                            <p className="font-medium text-gray-800">{contact.name}</p>
                        </div>
                        {contact.address && (
                            <div>
                                <p className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">Address Location</p>
                                <p className="font-medium text-gray-800 flex items-start gap-2">
                                    <MapPin size={16} className="text-gray-400 mt-1 shrink-0" />
                                    <span>{contact.address}</span>
                                </p>
                            </div>
                        )}
                        <div>
                            <p className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">Date Added</p>
                            <p className="font-medium text-gray-800">
                                {contact.createdAt?.toDate ? contact.createdAt.toDate().toLocaleDateString('en-GB') : (contact.createdAt ? new Date(contact.createdAt).toLocaleDateString('en-GB') : 'N/A')}
                            </p>
                        </div>
                    </div>
                </div>

                {/* Activity Box (Placeholder for future integrations like invoices assigned to vendor) */}
                <div className="bg-gray-50/50 rounded-2xl p-6 border border-dashed border-gray-300 flex flex-col items-center justify-center text-center">
                    <Briefcase size={40} className="text-gray-300 mb-4" />
                    <h3 className="text-lg font-bold text-[var(--color-secondary)] mb-2">History & Activity</h3>
                    <p className="text-sm text-gray-500 max-w-xs">
                        {contact.category === 'Vendor' || contact.category === 'Supplier'
                            ? "Invoices and material orders associated with this vendor will appear here."
                            : contact.category === 'Client'
                                ? "Projects and payment schedules linked to this client will appear here."
                                : "Recent activity involving this contact."}
                    </p>
                </div>

            </motion.div>
        </div>
    );
}
