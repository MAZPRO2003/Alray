import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import {
    ArrowLeft, FileText, Download, IndianRupee,
    Wallet, Users, Receipt, Plus, Minus,
    ChevronUp, Landmark, ShieldAlert, BadgeInfo
} from 'lucide-react';
import { projectService } from '../services/projectService';

import OverviewTab from '../components/projects/tabs/OverviewTab';
import BudgetsTab from '../components/projects/tabs/BudgetsTab'; // Material
import ProjectExpensesTab from '../components/projects/tabs/ProjectExpensesTab'; // Specialized
import ProjectLabourTab from '../components/projects/tabs/ProjectLabourTab';
import CustomerTab from '../components/projects/tabs/CustomerTab';

import AddRevenueDialog from '../components/projects/AddRevenueDialog';
import AddExpenseDialog from '../components/projects/AddExpenseDialog';
import AddSnagItemDialog from '../components/projects/AddSnagItemDialog';
import AddPayableDialog from '../components/projects/AddPayableDialog';

export default function ProjectDetailsPage() {
    const { id } = useParams();
    const [project, setProject] = useState(null);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('overview');

    // Dialog States
    const [isRevenueOpen, setIsRevenueOpen] = useState(false);
    const [isExpenseOpen, setIsExpenseOpen] = useState(false);
    const [isFabOpen, setIsFabOpen] = useState(false);
    const [isAddSnagOpen, setIsAddSnagOpen] = useState(false);
    const [isAddPayableOpen, setIsAddPayableOpen] = useState(false);

    useEffect(() => {
        const unsubscribe = projectService.subscribeToProject(id, (data) => {
            setProject(data);
            setLoading(false);
        });

        return () => unsubscribe();
    }, [id]);


    if (loading) return <div className="p-10 text-center text-gray-500">Loading project details...</div>;
    if (!project) return <div className="p-10 text-center text-red-500">Project not found</div>;

    // Mobile Parity: Exactly 5 main tabs
    const tabs = [
        { id: 'overview', name: 'Overview', icon: FileText },
        { id: 'customer', name: 'Customer', icon: Wallet },
        { id: 'material', name: 'Material', icon: Receipt },
        { id: 'labor', name: 'Labour', icon: Users },
        { id: 'specialized', name: 'Specialized', icon: IndianRupee },
    ];

    return (
        <div className="space-y-6 relative min-h-screen pb-24">
            {/* Header */}
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b pb-6 border-gray-100">
                <div>
                    <Link to="/app/projects" className="flex items-center gap-2 text-gray-500 hover:text-[var(--color-primary)] transition-colors mb-2 text-sm font-medium">
                        <ArrowLeft size={16} />
                        Back to Projects
                    </Link>
                    <h1 className="text-2xl font-bold text-[var(--color-secondary)]">{project.name}</h1>
                    <p className="text-gray-500 text-sm font-medium">{project.clientName} | {project.location}</p>
                </div>

            </div>

            {/* Tabs Navigation */}
            <div className="flex overflow-x-auto border-b border-gray-200 hide-scrollbar scroll-smooth -mx-6 px-6">
                {tabs.map(tab => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id)}
                        className={`flex items-center gap-2 px-6 py-4 font-bold transition-all whitespace-nowrap border-b-2 text-sm ${activeTab === tab.id
                            ? 'border-[var(--color-primary)] text-[var(--color-primary)] bg-[var(--color-primary)]/5'
                            : 'border-transparent text-gray-500 hover:text-[var(--color-secondary)] hover:bg-gray-50'
                            }`}
                    >
                        <tab.icon size={18} />
                        {tab.name}
                    </button>
                ))}
            </div>

            {/* Tab Content Display */}
            <div className="bg-white rounded-3xl shadow-sm border border-gray-100 p-8 min-h-[500px]">
                <AnimatePresence mode="wait">
                    <motion.div
                        key={activeTab}
                        initial={{ opacity: 0, x: 10 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: -10 }}
                        transition={{ duration: 0.2 }}
                    >
                        {activeTab === 'overview' && <OverviewTab project={project} />}
                        {activeTab === 'customer' && <CustomerTab project={project} />}
                        {activeTab === 'material' && <BudgetsTab projectId={id} project={project} />}
                        {activeTab === 'labor' && <ProjectLabourTab projectId={id} project={project} />}
                        {activeTab === 'specialized' && <ProjectExpensesTab projectId={id} project={project} />}
                    </motion.div>
                </AnimatePresence>
            </div>

            {/* Floating Action Menu (Mobile Parity) */}
            <div className="fixed bottom-8 right-8 z-50 flex flex-col items-end gap-4">
                <AnimatePresence>
                    {isFabOpen && (
                        <div className="flex flex-col items-end gap-3 mb-2">
                            <motion.button
                                initial={{ opacity: 0, scale: 0.5, y: 20 }}
                                animate={{ opacity: 1, scale: 1, y: 0 }}
                                exit={{ opacity: 0, scale: 0.5, y: 20 }}
                                onClick={() => { setIsRevenueOpen(true); setIsFabOpen(false); }}
                                className="flex items-center gap-3 bg-emerald-600 text-white rounded-full pl-5 pr-4 py-3 shadow-lg hover:bg-emerald-700 transition-colors"
                            >
                                <span className="text-sm font-bold">Add Revenue</span>
                                <div className="p-1 bg-white/20 rounded-full">
                                    <Landmark size={18} />
                                </div>
                            </motion.button>

                            <motion.button
                                initial={{ opacity: 0, scale: 0.5, y: 20 }}
                                animate={{ opacity: 1, scale: 1, y: 0 }}
                                exit={{ opacity: 0, scale: 0.5, y: 20 }}
                                transition={{ delay: 0.05 }}
                                onClick={() => { setIsExpenseOpen(true); setIsFabOpen(false); }}
                                className="flex items-center gap-3 bg-rose-600 text-white rounded-full pl-5 pr-4 py-3 shadow-lg hover:bg-rose-700 transition-colors"
                            >
                                <span className="text-sm font-bold">Add Expense</span>
                                <div className="p-1 bg-white/20 rounded-full">
                                    <Receipt size={18} />
                                </div>
                            </motion.button>

                            <motion.button
                                initial={{ opacity: 0, scale: 0.5, y: 20 }}
                                animate={{ opacity: 1, scale: 1, y: 0 }}
                                exit={{ opacity: 0, scale: 0.5, y: 20 }}
                                transition={{ delay: 0.1 }}
                                onClick={() => { setIsAddPayableOpen(true); setIsFabOpen(false); }}
                                className="flex items-center gap-3 bg-orange-600 text-white rounded-full pl-5 pr-4 py-3 shadow-lg hover:bg-orange-700 transition-colors"
                            >
                                <span className="text-sm font-bold">Record Pending Bill</span>
                                <div className="p-1 bg-white/20 rounded-full">
                                    <BadgeInfo size={18} />
                                </div>
                            </motion.button>

                            <motion.button
                                initial={{ opacity: 0, scale: 0.5, y: 20 }}
                                animate={{ opacity: 1, scale: 1, y: 0 }}
                                exit={{ opacity: 0, scale: 0.5, y: 20 }}
                                transition={{ delay: 0.15 }}
                                onClick={() => { setIsAddSnagOpen(true); setIsFabOpen(false); }}
                                className="flex items-center gap-3 bg-slate-600 text-white rounded-full pl-5 pr-4 py-3 shadow-lg hover:bg-slate-700 transition-colors"
                            >
                                <span className="text-sm font-bold">Record Issue</span>
                                <div className="p-1 bg-white/20 rounded-full">
                                    <ShieldAlert size={18} />
                                </div>
                            </motion.button>
                        </div>
                    )}
                </AnimatePresence>

                <button
                    onClick={() => setIsFabOpen(!isFabOpen)}
                    className={`w-14 h-14 rounded-full flex items-center justify-center shadow-xl transition-all duration-300 ${isFabOpen ? 'bg-slate-800 rotate-45 text-white' : 'bg-[var(--color-primary)] text-white shadow-[var(--color-primary)]/40 hover:scale-110'}`}
                >
                    <Plus size={28} />
                </button>
            </div>

            {/* Global Actions Dialogs */}
            <AddRevenueDialog
                isOpen={isRevenueOpen}
                onClose={() => setIsRevenueOpen(false)}
                projectId={id}
            />
            <AddExpenseDialog
                isOpen={isExpenseOpen}
                onClose={() => setIsExpenseOpen(false)}
                projectId={id}
            />
            <AddSnagItemDialog
                isOpen={isAddSnagOpen}
                onClose={() => setIsAddSnagOpen(false)}
                projectId={id}
            />
            <AddPayableDialog
                isOpen={isAddPayableOpen}
                onClose={() => setIsAddPayableOpen(false)}
                projectId={id}
            />
        </div>
    );
}
