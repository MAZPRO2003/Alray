import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Search, Building2, CalendarClock, CheckCircle2, Clock, Hammer, ChevronRight } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { projectService } from '../services/projectService';
import AddProjectDialog from '../components/projects/AddProjectDialog';

export default function ProjectsListPage() {
    const { currentUser } = useAuth();
    const navigate = useNavigate();
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
    }).format(amount || 0);

    const getStatus = (p) => {
        if (p.isCompleted) return 'Completed';
        const now = new Date();
        const endDate = p.endDate?.toDate ? p.endDate.toDate() : (p.endDate ? new Date(p.endDate) : null);
        const startDate = p.startDate?.toDate ? p.startDate.toDate() : (p.startDate ? new Date(p.startDate) : null);

        if (endDate && endDate < now) return 'Completed';
        if (startDate && startDate > now) return 'Upcoming';
        return 'Active';
    };

    const getStatusColor = (status) => {
        if (status === 'Active') return { bg: 'rgba(76, 175, 80, 0.1)', text: '#4CAF50', border: 'rgba(76, 175, 80, 0.3)' };
        if (status === 'Completed') return { bg: 'rgba(3, 169, 244, 0.1)', text: '#03A9F4', border: 'rgba(3, 169, 244, 0.3)' };
        if (status === 'Upcoming') return { bg: 'rgba(255, 152, 0, 0.1)', text: '#FF9800', border: 'rgba(255, 152, 0, 0.3)' };
        return { bg: 'rgba(158, 158, 158, 0.1)', text: '#9E9E9E', border: 'rgba(158, 158, 158, 0.3)' };
    };

    const getHealthInfo = (p) => {
        const budget = p.budget || 0;
        const spent = p.totalSpent || 0;

        if (budget <= 0) return { label: 'No Budget', color: '#9E9E9E', score: 0 };

        const budgetUsed = spent / budget;

        // Calculate time ratio
        let timeRatio = 0;
        const now = new Date();
        const startDate = p.startDate?.toDate ? p.startDate.toDate() : (p.startDate ? new Date(p.startDate) : null);
        const endDate = p.endDate?.toDate ? p.endDate.toDate() : (p.endDate ? new Date(p.endDate) : null);

        if (startDate && endDate && endDate > startDate) {
            const totalDuration = endDate.getTime() - startDate.getTime();
            const elapsed = now.getTime() - startDate.getTime();
            timeRatio = Math.max(0, Math.min(1, elapsed / totalDuration));
        }

        const overrun = budgetUsed - timeRatio;

        if (spent > budget) return { label: 'Critical', color: '#F44336', score: Math.min(1.5, budgetUsed) };
        if (overrun > 0.2) return { label: 'At Risk', color: '#FF9800', score: Math.min(1, budgetUsed) };
        if (budgetUsed < 0.5) return { label: 'Healthy', color: '#4CAF50', score: Math.min(1, budgetUsed) };
        return { label: 'Good', color: '#2196F3', score: Math.min(1, budgetUsed) };
    };

    const Badge = ({ label, colorObj }) => {
        // Handle both simple hex strings (for health) and complex objects (for status)
        const bg = colorObj.bg || `${colorObj}1A`; // 10% opacity if hex
        const border = colorObj.border || `${colorObj}4D`; // 30% opacity if hex
        const text = colorObj.text || colorObj;

        return (
            <span
                className="px-2 py-0.5 rounded-full text-[10px] font-semibold border whitespace-nowrap"
                style={{ backgroundColor: bg, borderColor: border, color: text }}
            >
                {label}
            </span>
        );
    };

    const filterProjectsByTab = (tab) => {
        return projects.filter(p => {
            const matchesSearch = !searchQuery ||
                p.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
                p.clientName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
                p.location?.toLowerCase().includes(searchQuery.toLowerCase());

            if (!matchesSearch) return false;

            const status = getStatus(p);
            if (tab === 'active') return status === 'Active';
            if (tab === 'upcoming') return status === 'Upcoming';
            if (tab === 'completed') return status === 'Completed';
            return true;
        });
    };

    const displayed = filterProjectsByTab(activeTab);
    const tabs = [
        { id: 'active', label: 'Active', icon: Hammer, count: projects.filter(p => getStatus(p) === 'Active').length },
        { id: 'upcoming', label: 'Upcoming', icon: Clock, count: projects.filter(p => getStatus(p) === 'Upcoming').length },
        { id: 'completed', label: 'Done', icon: CheckCircle2, count: projects.filter(p => getStatus(p) === 'Completed').length },
    ];

    return (
        <div className="space-y-6 pb-24">
            {/* Page Header */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: 'var(--color-secondary)' }}>Projects</h1>
                </div>
                <button
                    onClick={() => setIsAddModalOpen(true)}
                    className="flex items-center gap-2 text-sm font-semibold text-white px-5 py-2.5 rounded-xl transition-all hover:opacity-90 active:scale-95 shadow-md"
                    style={{ background: 'var(--color-primary)' }}
                >
                    <Plus size={18} /> New Project
                </button>
            </div>

            {/* Tabs + Search */}
            <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
                <div className="flex gap-1 border-b" style={{ borderColor: 'var(--color-border)', width: '100%', maxWidth: '400px' }}>
                    {tabs.map(tab => (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id)}
                            className="flex-1 pb-3 text-sm font-semibold transition-all relative"
                            style={{
                                color: activeTab === tab.id ? 'var(--color-primary)' : 'var(--color-text-light)',
                            }}
                        >
                            {tab.label} ({tab.count})
                            {activeTab === tab.id && (
                                <motion.div
                                    layoutId="projectTab"
                                    className="absolute bottom-0 left-0 right-0 h-0.5 rounded-t-full"
                                    style={{ background: 'var(--color-primary)' }}
                                />
                            )}
                        </button>
                    ))}
                </div>
                <div className="relative w-full sm:w-auto">
                    <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2" style={{ color: 'var(--color-text-light)' }} />
                    <input
                        type="text"
                        placeholder="Search projects..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full sm:w-64 pl-9 pr-4 py-2.5 rounded-xl text-sm bg-white shadow-sm border border-slate-100 focus:outline-none"
                    />
                </div>
            </div>

            {/* Projects List */}
            {loading ? (
                <div className="space-y-4">
                    {[1, 2, 3].map(i => <div key={i} className="h-48 bg-white rounded-2xl animate-pulse border border-slate-100" />)}
                </div>
            ) : displayed.length === 0 ? (
                <div className="bg-white rounded-2xl border border-slate-100 p-16 text-center shadow-sm">
                    <Building2 size={48} className="mx-auto mb-4" style={{ color: 'var(--color-border)' }} />
                    <p className="font-semibold text-lg mb-1" style={{ color: 'var(--color-secondary)' }}>No projects here yet</p>
                    <p className="text-sm mb-4 text-slate-500">Get started by creating a new project</p>
                    <button onClick={() => setIsAddModalOpen(true)} className="text-sm font-semibold px-4 py-2 rounded-xl text-white" style={{ background: 'var(--color-primary)' }}>
                        + Add Project
                    </button>
                </div>
            ) : (
                <div className="space-y-4">
                    {displayed.map((project, idx) => {
                        const status = getStatus(project);
                        const statusColor = getStatusColor(status);
                        const health = getHealthInfo(project);

                        let daysLeft = null;
                        if (project.endDate) {
                            const endDate = project.endDate.toDate ? project.endDate.toDate() : new Date(project.endDate);
                            const diffTime = endDate.getTime() - new Date().getTime();
                            daysLeft = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                        }

                        const budget = project.budget || 0;
                        const spent = project.totalSpent || 0;
                        const remaining = Math.max(0, budget - spent);

                        return (
                            <motion.div
                                key={project.id}
                                initial={{ opacity: 0, y: 16 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ delay: idx * 0.05 }}
                            >
                                <Link to={`/app/projects/${project.id}`} className="block">
                                    <div className="bg-white rounded-[20px] border border-slate-200 hover:shadow-md transition-all p-4">

                                        {/* Header Row */}
                                        <div className="flex items-start gap-3">
                                            <div className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0"
                                                style={{ background: statusColor.bg }}>
                                                <Building2 size={24} style={{ color: statusColor.text }} />
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <h3 className="font-bold text-base truncate" style={{ color: 'var(--color-secondary)' }}>
                                                    {project.name}
                                                </h3>
                                                <div className="flex flex-wrap gap-2 mt-1">
                                                    <Badge label={status} colorObj={statusColor} />
                                                    {status !== 'Completed' && <Badge label={health.label} colorObj={health.color} />}
                                                    {status !== 'Completed' && daysLeft !== null && (
                                                        <Badge
                                                            label={daysLeft >= 0 ? `${daysLeft} days left` : `${Math.abs(daysLeft)}d overdue`}
                                                            colorObj={daysLeft >= 0 ? '#9E9E9E' : '#F44336'}
                                                        />
                                                    )}
                                                </div>
                                            </div>
                                            <ChevronRight className="text-slate-300" />
                                        </div>

                                        {/* Financial Stats Grid */}
                                        <div className="grid grid-cols-3 gap-2 mt-4">
                                            <div className="flex flex-col">
                                                <span className="text-[10px] text-slate-500 uppercase tracking-wider font-semibold">Budget</span>
                                                <span className="text-sm font-bold text-slate-700">{formatCurrency(budget)}</span>
                                            </div>
                                            <div className="flex flex-col">
                                                <span className="text-[10px] text-slate-500 uppercase tracking-wider font-semibold">Spent</span>
                                                <span className="text-sm font-bold text-red-600">{formatCurrency(spent)}</span>
                                            </div>
                                            <div className="flex flex-col">
                                                <span className="text-[10px] text-slate-500 uppercase tracking-wider font-semibold">Remaining</span>
                                                <span className={`text-sm font-bold ${remaining >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                                                    {formatCurrency(remaining)}
                                                </span>
                                            </div>
                                        </div>

                                        {/* Health Bar */}
                                        <div className="mt-4">
                                            <div className="flex justify-between items-center mb-1">
                                                <span className="text-[10px] text-slate-500 uppercase font-semibold">Budget Used</span>
                                                <span className="text-[10px] font-bold" style={{ color: health.color }}>
                                                    {Math.round(health.score * 100)}%
                                                </span>
                                            </div>
                                            <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
                                                <motion.div
                                                    className="h-full rounded-full"
                                                    initial={{ width: 0 }}
                                                    animate={{ width: `${Math.min(100, health.score * 100)}%` }}
                                                    transition={{ duration: 1, delay: 0.1 }}
                                                    style={{ background: health.color }}
                                                />
                                            </div>
                                        </div>

                                        {/* Dates */}
                                        {status !== 'Completed' && (project.startDate || project.endDate) && (
                                            <div className="flex items-center gap-1.5 mt-3 text-xs text-slate-500">
                                                <CalendarClock size={12} />
                                                <span>
                                                    {project.startDate ? (project.startDate.toDate ? project.startDate.toDate().toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: '2-digit' }) : new Date(project.startDate).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: '2-digit' })) : '?'}
                                                    {' → '}
                                                    {project.endDate ? (project.endDate.toDate ? project.endDate.toDate().toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: '2-digit' }) : new Date(project.endDate).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: '2-digit' })) : 'Ongoing'}
                                                </span>
                                            </div>
                                        )}

                                    </div>
                                </Link>
                            </motion.div>
                        );
                    })}
                </div>
            )}

            <AddProjectDialog
                isOpen={isAddModalOpen}
                onClose={() => setIsAddModalOpen(false)}
            />
        </div>
    );
}
