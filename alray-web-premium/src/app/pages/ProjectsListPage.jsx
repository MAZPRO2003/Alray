import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Plus, Search, Building2, MapPin, CalendarClock, CheckCircle2, Clock, Hammer } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { projectService } from '../services/projectService';
import AddProjectDialog from '../components/projects/AddProjectDialog';

export default function ProjectsListPage() {
    const { currentUser } = useAuth();
    const [projects, setProjects] = useState([]);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('active');
    const [searchQuery, setSearchQuery] = useState('');
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);

    useEffect(() => {
        if (!currentUser) return;
        const unsubscribe = projectService.subscribeToProjects(currentUser.uid, (data) => {
            setProjects(data);
            setLoading(false);
        });
        return () => unsubscribe();
    }, [currentUser]);

    const formatCurrency = (amount) => new Intl.NumberFormat('en-IN', {
        style: 'currency', currency: 'INR', maximumFractionDigits: 0
    }).format(amount);

    const filterProjectsByTab = (tab) => {
        const now = new Date();
        return projects.filter(p => {
            const startDate = p.startDate?.toDate ? p.startDate.toDate() : (p.startDate ? new Date(p.startDate) : null);
            const endDate = p.endDate?.toDate ? p.endDate.toDate() : (p.endDate ? new Date(p.endDate) : null);

            const matchesSearch = !searchQuery ||
                p.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
                p.clientName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
                p.location?.toLowerCase().includes(searchQuery.toLowerCase());

            if (!matchesSearch) return false;

            if (tab === 'active') return p.status === 'active' || (!p.status && (!endDate || endDate >= now));
            if (tab === 'upcoming') return startDate && startDate > now;
            if (tab === 'completed') return p.status === 'completed';
            return true;
        });
    };

    const displayed = filterProjectsByTab(activeTab);
    const tabs = [
        { id: 'active', label: 'Active', icon: Hammer },
        { id: 'upcoming', label: 'Upcoming', icon: Clock },
        { id: 'completed', label: 'Completed', icon: CheckCircle2 },
    ];

    const getStatusColor = (p) => {
        if (p.status === 'completed') return 'bg-emerald-100 text-emerald-700';
        if (p.status === 'active') return 'bg-blue-100 text-blue-700';
        return 'bg-amber-100 text-amber-700';
    };

    return (
        <div className="space-y-6">
            {/* Page Header */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: 'var(--color-secondary)', letterSpacing: '-0.02em' }}>Projects</h1>
                    <p style={{ color: 'var(--color-text-light)', fontSize: '14px', marginTop: '4px', marginBottom: 0 }}>Manage and track all your construction projects</p>
                </div>
                <button
                    onClick={() => setIsAddModalOpen(true)}
                    className="flex items-center gap-2 text-sm font-semibold text-white px-5 py-2.5 rounded-xl transition-all hover:opacity-90 active:scale-95"
                    style={{ background: 'var(--color-primary)', boxShadow: '0 4px 14px rgba(224,31,38,0.3)' }}
                >
                    <Plus size={18} /> New Project
                </button>
            </div>

            {/* Tabs + Search */}
            <div className="flex flex-col sm:flex-row gap-3 items-start sm:items-center justify-between">
                <div className="flex gap-1 bg-white border p-1 rounded-xl" style={{ borderColor: 'var(--color-border)' }}>
                    {tabs.map(tab => (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id)}
                            className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-semibold transition-all"
                            style={{
                                background: activeTab === tab.id ? 'var(--color-secondary)' : 'transparent',
                                color: activeTab === tab.id ? '#fff' : 'var(--color-text-light)',
                            }}
                        >
                            <tab.icon size={15} />
                            {tab.label}
                        </button>
                    ))}
                </div>
                <div className="relative">
                    <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2" style={{ color: 'var(--color-text-light)' }} />
                    <input
                        type="text"
                        placeholder="Search projects..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="pl-9 pr-4 py-2.5 rounded-xl text-sm border bg-white focus:outline-none"
                        style={{ borderColor: 'var(--color-border)', width: '240px', fontFamily: 'Inter, sans-serif', color: 'var(--color-text)' }}
                    />
                </div>
            </div>

            {/* Projects Grid */}
            {loading ? (
                <div className="text-center py-16" style={{ color: 'var(--color-text-light)' }}>Loading projects...</div>
            ) : displayed.length === 0 ? (
                <div className="bg-white rounded-2xl border p-16 text-center" style={{ borderColor: 'var(--color-border)' }}>
                    <Building2 size={48} className="mx-auto mb-4" style={{ color: 'var(--color-border)' }} />
                    <p className="font-semibold text-lg mb-1" style={{ color: 'var(--color-secondary)' }}>No projects here yet</p>
                    <p className="text-sm mb-4" style={{ color: 'var(--color-text-light)', marginBottom: '16px' }}>Get started by creating a new project</p>
                    <button onClick={() => setIsAddModalOpen(true)} className="text-sm font-semibold px-4 py-2 rounded-xl text-white" style={{ background: 'var(--color-primary)' }}>
                        + Add Project
                    </button>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
                    {displayed.map((project, idx) => (
                        <motion.div
                            key={project.id}
                            initial={{ opacity: 0, y: 16 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: idx * 0.05 }}
                        >
                            <Link to={`/app/projects/${project.id}`} className="block">
                                <div className="bg-white rounded-2xl border hover:shadow-lg transition-shadow overflow-hidden h-full"
                                    style={{ borderColor: 'var(--color-border)' }}>
                                    <div className="h-1.5" style={{ background: 'var(--color-primary)' }} />
                                    <div className="p-5">
                                        <div className="flex items-start justify-between mb-3">
                                            <span className={`text-xs font-bold uppercase tracking-wider px-2 py-1 rounded-md ${getStatusColor(project)}`}>
                                                {project.status || 'Active'}
                                            </span>
                                            <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: 'rgba(224,31,38,0.08)' }}>
                                                <Building2 size={18} style={{ color: 'var(--color-primary)' }} />
                                            </div>
                                        </div>

                                        <h3 className="font-bold text-base mb-1 truncate" style={{ color: 'var(--color-secondary)' }}>{project.name}</h3>
                                        <p className="text-sm mb-4 truncate" style={{ color: 'var(--color-text-light)', marginBottom: '16px' }}>{project.clientName || 'No Client'}</p>

                                        {project.location && (
                                            <div className="flex items-center gap-1.5 text-xs mb-3" style={{ color: 'var(--color-text-light)' }}>
                                                <MapPin size={13} />
                                                {project.location}
                                            </div>
                                        )}

                                        <div className="pt-4 border-t flex items-center justify-between" style={{ borderColor: 'var(--color-border)' }}>
                                            <div>
                                                <p className="text-xs font-bold uppercase tracking-wider mb-0.5" style={{ color: 'var(--color-text-light)' }}>Budget</p>
                                                <p className="font-bold text-sm" style={{ color: 'var(--color-secondary)' }}>{formatCurrency(project.budget || 0)}</p>
                                            </div>
                                            {project.endDate && (
                                                <div className="flex items-center gap-1.5 text-xs" style={{ color: 'var(--color-text-light)' }}>
                                                    <CalendarClock size={13} />
                                                    {(project.endDate?.toDate ? project.endDate.toDate() : new Date(project.endDate)).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </Link>
                        </motion.div>
                    ))}
                </div>
            )}

            <AddProjectDialog
                isOpen={isAddModalOpen}
                onClose={() => setIsAddModalOpen(false)}
            />
        </div>
    );
}
