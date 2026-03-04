import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    Plus, Hammer, Users, Calendar,
    CheckCircle2, Clock, ChevronRight,
    TrendingUp, FileText, Layout, ArrowRight,
    IndianRupee, MoreVertical, Trash2, Edit2
} from 'lucide-react';
import { laborTaskService, laborPaymentService } from '../../../services/labourService';
import { projectService } from '../../../services/projectService';
import { useAuth } from '../../../context/AuthContext';
import AddLabourTaskDialog from '../AddLabourTaskDialog';
import AddLabourPaymentDialog from '../AddLabourPaymentDialog';
import { generateLabourPDF, generateLabourCSV } from '../../../utils/labourExportUtils';

export default function ProjectLaborTab({ projectId }) {
    const { currentUser } = useAuth();
    const [project, setProject] = useState(null);
    const [tasks, setTasks] = useState([]);
    const [payments, setPayments] = useState([]);
    const [loading, setLoading] = useState(true);

    // Dialog States
    const [isAddTaskOpen, setIsAddTaskOpen] = useState(false);
    const [editTask, setEditTask] = useState(null);
    const [isAddPaymentOpen, setIsAddPaymentOpen] = useState(false);
    const [editPayment, setEditPayment] = useState(null);
    const [exportMode, setExportMode] = useState('combined');

    useEffect(() => {
        if (!currentUser) return;
        const subs = [
            projectService.subscribeToProject(projectId, setProject),
            laborTaskService.subscribeToProjectTasks(currentUser.uid, projectId, setTasks),
            laborPaymentService.subscribeToProjectPayments(currentUser.uid, projectId, setPayments)
        ];
        setLoading(false);
        return () => subs.forEach(unsub => unsub());
    }, [projectId, currentUser]);

    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency', currency: 'INR', maximumFractionDigits: 0
        }).format(amount || 0);
    };

    const formatDate = (date) => {
        if (!date) return '—';
        const d = date.toDate ? date.toDate() : new Date(date);
        return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
    };

    // Task Grouping (Mobile Parity)
    const ongoingTasks = tasks.filter(t => t.completionPercentage > 0 && t.completionPercentage < 1);
    const pendingTasks = tasks.filter(t => t.completionPercentage === 0 || t.completionPercentage === undefined);
    const doneTasks = tasks.filter(t => t.completionPercentage === 1);

    const totalLabourSpent = payments.reduce((sum, p) => sum + (p.amount || 0), 0);

    const handleProgressUpdate = async (taskId, value) => {
        try {
            await laborTaskService.updateTaskProgress(taskId, value);
        } catch (error) {
            console.error('Failed to update progress:', error);
        }
    };

    const handleDeleteTask = async (id) => {
        if (window.confirm('Are you sure you want to delete this task?')) {
            await laborTaskService.deleteTask(id);
        }
    };

    const handleDeletePayment = async (id) => {
        if (window.confirm('Are you sure you want to delete this payment?')) {
            try {
                await laborPaymentService.deletePayment(id);
            } catch (error) {
                console.error('Failed to delete payment:', error);
            }
        }
    };

    if (loading) return <div className="p-10 text-center text-slate-400">Loading Labour Details...</div>;

    return (
        <div className="space-y-8 pb-10">
            {/* Summary Card (Mobile Parity: Orange Theme) */}
            <div className="bg-orange-50 rounded-[2.5rem] p-8 border border-orange-100 flex items-center justify-between">
                <div className="flex items-center gap-6">
                    <div className="w-16 h-16 rounded-2xl bg-orange-100 flex items-center justify-center text-orange-600">
                        <IndianRupee size={32} />
                    </div>
                    <div>
                        <p className="text-[10px] font-black uppercase tracking-widest text-slate-400 mb-1">Total Labour Spent</p>
                        <h2 className="text-3xl font-black text-orange-900">{formatCurrency(totalLabourSpent)}</h2>
                    </div>
                </div>
                <div className="hidden md:flex items-center gap-1 bg-white border border-orange-100 rounded-xl p-1 shadow-sm">
                    <select
                        value={exportMode}
                        onChange={(e) => setExportMode(e.target.value)}
                        className="text-xs py-1 px-2 rounded-lg bg-transparent border-none outline-none font-bold text-orange-900 cursor-pointer"
                    >
                        <option value="combined">Combined Data</option>
                        <option value="tasks">Task Management</option>
                        <option value="payments">Weekly Payments</option>
                    </select>
                    <div className="w-px h-4 bg-orange-200 mx-1"></div>
                    <button
                        onClick={() => generateLabourPDF(project, tasks, payments, exportMode)}
                        className="p-1.5 bg-white rounded-lg text-rose-500 hover:bg-orange-50 transition-all"
                        title="Export PDF Report"
                    >
                        <FileText size={18} />
                    </button>
                    <button
                        onClick={() => generateLabourCSV(project, tasks, payments, exportMode)}
                        className="p-1.5 bg-white rounded-lg text-emerald-600 hover:bg-orange-50 transition-all"
                        title="Export CSV Report"
                    >
                        <Layout size={18} />
                    </button>
                </div>
            </div>

            {/* Task Management Section */}
            <section className="space-y-6">
                <div className="flex justify-between items-center px-2">
                    <h3 className="text-xl font-black text-slate-800 tracking-tight">Task Management</h3>
                    <button
                        onClick={() => {
                            setEditTask(null);
                            setIsAddTaskOpen(true);
                        }}
                        className="p-2 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-100 transition-all flex items-center gap-2 px-4 text-xs font-black uppercase tracking-widest"
                    >
                        <Plus size={16} /> Add Task
                    </button>
                </div>

                {tasks.length === 0 ? (
                    <div className="p-16 text-center bg-slate-50 rounded-[3rem] border border-dashed border-slate-200">
                        <Hammer size={48} className="mx-auto text-slate-200 mb-4" />
                        <p className="text-slate-400 font-bold">No tasks added yet.</p>
                    </div>
                ) : (
                    <div className="space-y-8">
                        {ongoingTasks.length > 0 && <TaskGroup title="Ongoing Tasks" color="orange" tasks={ongoingTasks} onUpdate={handleProgressUpdate} onEdit={(t) => { setEditTask(t); setIsAddTaskOpen(true); }} onDelete={handleDeleteTask} formatDate={formatDate} />}
                        {pendingTasks.length > 0 && <TaskGroup title="Pending Tasks" color="slate" tasks={pendingTasks} onUpdate={handleProgressUpdate} onEdit={(t) => { setEditTask(t); setIsAddTaskOpen(true); }} onDelete={handleDeleteTask} formatDate={formatDate} />}
                        {doneTasks.length > 0 && <TaskGroup title="Completed / Done" color="emerald" tasks={doneTasks} onUpdate={handleProgressUpdate} onEdit={(t) => { setEditTask(t); setIsAddTaskOpen(true); }} onDelete={handleDeleteTask} formatDate={formatDate} />}
                    </div>
                )}
            </section>

            {/* Weekly Payments Section */}
            <section className="space-y-6">
                <div className="flex justify-between items-center px-2">
                    <h3 className="text-xl font-black text-slate-800 tracking-tight">Weekly Payments</h3>
                    <button
                        onClick={() => {
                            setEditPayment(null);
                            setIsAddPaymentOpen(true);
                        }}
                        className="p-2 bg-emerald-50 text-emerald-600 rounded-xl hover:bg-emerald-100 transition-all flex items-center gap-2 px-4 text-xs font-black uppercase tracking-widest"
                    >
                        <Plus size={16} /> Add Payment
                    </button>
                </div>

                <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
                    {payments.length === 0 ? (
                        <div className="p-12 text-center text-slate-400 font-bold italic">No weekly payments recorded.</div>
                    ) : (
                        <div className="divide-y divide-slate-50">
                            {payments.slice(0, 5).map(payment => (
                                <div key={payment.id} className="p-6 flex items-center gap-4 hover:bg-slate-50 transition-all">
                                    <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
                                        <Users size={20} />
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <h4 className="font-black text-slate-800 truncate">{payment.laborerName}</h4>
                                        <p className="text-[10px] font-bold text-slate-400">
                                            {formatDate(payment.periodStart)} – {formatDate(payment.periodEnd)}
                                        </p>
                                    </div>
                                    <div className="text-right flex flex-col items-end gap-2">
                                        <div>
                                            <p className="text-lg font-black text-rose-500">{formatCurrency(payment.amount)}</p>
                                            <p className="text-[10px] font-bold text-slate-300 uppercase tracking-widest">Amount Paid</p>
                                        </div>
                                        <div className="flex items-center gap-2 opacity-0 group-[&:hover]:opacity-100 transition-opacity">
                                            <button
                                                onClick={() => {
                                                    setEditPayment(payment);
                                                    setIsAddPaymentOpen(true);
                                                }}
                                                className="p-1.5 text-slate-300 hover:text-blue-500 hover:bg-blue-50 rounded-lg transition-all"
                                            >
                                                <Edit2 size={16} />
                                            </button>
                                            <button
                                                onClick={() => handleDeletePayment(payment.id)}
                                                className="p-1.5 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-lg transition-all"
                                            >
                                                <Trash2 size={16} />
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </section>

            {/* Dialogs */}
            <AddLabourTaskDialog
                isOpen={isAddTaskOpen}
                onClose={() => {
                    setIsAddTaskOpen(false);
                    setEditTask(null);
                }}
                projectId={projectId}
                initialData={editTask}
            />
            <AddLabourPaymentDialog
                isOpen={isAddPaymentOpen}
                onClose={() => {
                    setIsAddPaymentOpen(false);
                    setEditPayment(null);
                }}
                projectId={projectId}
                initialData={editPayment}
            />
        </div>
    );
}

function TaskGroup({ title, color, tasks, onUpdate, onDelete, onEdit, formatDate }) {
    const colorClasses = {
        orange: "bg-orange-500 text-orange-500",
        slate: "bg-slate-300 text-slate-400",
        emerald: "bg-emerald-500 text-emerald-500"
    };

    return (
        <div className="space-y-4">
            <div className="flex items-center gap-3 px-2">
                <div className={`w-1 h-4 rounded-full ${colorClasses[color].split(' ')[0]}`} />
                <h4 className={`text-xs font-black uppercase tracking-widest ${colorClasses[color].split(' ')[1]}`}>{title}</h4>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {tasks.map(task => (
                    <div key={task.id} className="bg-white p-6 rounded-[2.2rem] border border-slate-100 shadow-sm hover:shadow-md transition-all relative group">
                        <div className="flex justify-between items-start mb-4">
                            <div>
                                <h5 className="font-black text-slate-800 text-lg">{task.name}</h5>
                                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                                    {task.laborerCount} Laborers • {task.role}
                                </p>
                            </div>
                            <div className="flex items-center gap-1">
                                <button
                                    onClick={() => onEdit(task)}
                                    className="p-2 text-slate-200 hover:text-blue-500 hover:bg-blue-50 bg-white rounded-xl transition-all"
                                >
                                    <Edit2 size={14} />
                                </button>
                                <button
                                    onClick={() => onDelete(task.id)}
                                    className="p-2 text-slate-200 hover:text-rose-500 hover:bg-rose-50 bg-white rounded-xl transition-all"
                                >
                                    <Trash2 size={14} />
                                </button>
                            </div>
                        </div>

                        <div className="space-y-3">
                            <div className="flex justify-between text-[10px] font-black uppercase tracking-widest text-slate-400">
                                <span>Completion</span>
                                <span>{Math.round((task.completionPercentage || 0) * 100)}%</span>
                            </div>
                            <input
                                type="range"
                                min="0" max="100"
                                value={(task.completionPercentage || 0) * 100}
                                onChange={(e) => onUpdate(task.id, e.target.value)}
                                className={`w-full h-1.5 rounded-full appearance-none cursor-pointer ${color === 'emerald' ? 'accent-emerald-500' : 'accent-blue-600'} bg-slate-100`}
                            />
                        </div>

                        <div className="mt-6 pt-4 border-t border-slate-50 flex items-center gap-4 text-slate-300 group-hover:text-slate-400 transition-colors">
                            <div className="flex items-center gap-1.5">
                                <Clock size={12} />
                                <span className="text-[10px] font-bold">Started {formatDate(task.startDate)}</span>
                            </div>
                            <div className="flex items-center gap-1 bg-slate-50 px-2 py-0.5 rounded-md">
                                <span className="text-[10px] font-black uppercase text-slate-500">{task.durationInDays || 0} Days</span>
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
