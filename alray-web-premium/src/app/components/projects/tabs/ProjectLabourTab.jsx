import React, { useState, useEffect, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    Plus, Calendar as CalendarIcon, FileText,
    CheckCircle2, Layout, ArrowRight, X, Trash2, Edit2,
    Users, IndianRupee, Banknote, CalendarDays, ClipboardList, Star
} from 'lucide-react';
import { attendanceService } from '../../../services/attendanceService';
import { useAuth } from '../../../context/AuthContext';
import AddAttendanceDialog from '../AddAttendanceDialog';
import { generateAttendancePDF, generateAttendanceCSV } from '../../../utils/labourExportUtils';

const roles = [
    { key: 'mason', title: 'Mason', countKey: 'mason', rateKey: 'masonRate' },
    { key: 'helper', title: 'Helper', countKey: 'helper', rateKey: 'helperRate' },
    { key: 'plumber', title: 'Plumber', countKey: 'plumber', rateKey: 'plumberRate' },
    { key: 'electrician', title: 'Electrician', countKey: 'electrician', rateKey: 'electricianRate' },
    { key: 'carpenter', title: 'Carpenter', countKey: 'carpenter', rateKey: 'carpenterRate' },
    { key: 'steelWorker', title: 'Steel worker', countKey: 'steelWorker', rateKey: 'steelWorkerRate' },
    { key: 'grillWorker', title: 'Grill worker', countKey: 'grillWorker', rateKey: 'grillWorkerRate' },
    { key: 'tileLabour', title: 'Tile labour', countKey: 'tileLabour', rateKey: 'tileLabourRate' },
    { key: 'painter', title: 'Painter', countKey: 'painter', rateKey: 'painterRate' },
    { key: 'others', title: 'Others', countKey: 'others', rateKey: 'othersRate' }
];

export default function ProjectLabourTab({ projectId, project }) {
    const { currentUser } = useAuth();
    const [records, setRecords] = useState([]);
    const [loading, setLoading] = useState(true);

    const [isAddOpen, setIsAddOpen] = useState(false);
    const [editRecord, setEditRecord] = useState(null);
    const [filterDate, setFilterDate] = useState(null);

    useEffect(() => {
        if (!currentUser) return;
        const unsub = attendanceService.subscribeToProjectAttendance(currentUser.uid, projectId, (data) => {
            setRecords(data);
            setLoading(false);
        });
        return () => unsub();
    }, [projectId, currentUser]);

    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN').format(Math.round(amount || 0));
    };

    const formatDate = (dStr) => {
        if (!dStr) return '';
        const d = dStr.toDate ? dStr.toDate() : new Date(dStr);
        return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', weekday: 'short' });
    };

    const calculateTotals = (recordList) => {
        let workers = 0;
        let cost = 0;
        recordList.forEach(r => {
            roles.forEach(role => {
                workers += (r[role.countKey] || 0);
                cost += (r[role.countKey] || 0) * (r[role.rateKey] || 0);
            });
            workers += (r.customEntered || 0);
            cost += (r.customEntered || 0) * (r.customEnteredRate || 0);
        });
        return { workers, cost };
    };

    const handleDelete = async (id) => {
        if (window.confirm('Delete Entry?\nRemove attendance for this day?')) {
            await attendanceService.deleteAttendanceRecord(projectId, id);
        }
    };

    const openAdd = (existing = null, preset = null) => {
        setEditRecord(existing);
        setIsAddOpen(true);
    };

    // Derived Date logic
    const { workers: totalWorkerDays, cost: totalCost } = calculateTotals(records);
    const totalDays = records.length;

    // Filter Logic
    const isSameDay = (d1, d2) => {
        if (!d1 || !d2) return false;
        const date1 = d1.toDate ? d1.toDate() : new Date(d1);
        const date2 = d2.toDate ? d2.toDate() : new Date(d2);
        return date1.toDateString() === date2.toDateString();
    };

    const filteredRecords = filterDate
        ? records.filter(r => isSameDay(r.date, filterDate))
        : [];

    const groupToWeeks = (recordList) => {
        const weeks = {};
        recordList.forEach(r => {
            const date = r.date.toDate ? r.date.toDate() : new Date(r.date);
            const d = new Date(date);
            const day = d.getDay() || 7; // Get current day number, converting Sun. to 7
            d.setHours(-24 * (day - 1)); // Get Monday
            d.setHours(0, 0, 0, 0);
            const weekKey = d.toISOString();
            if (!weeks[weekKey]) weeks[weekKey] = [];
            weeks[weekKey].push(r);
        });
        return Object.keys(weeks).sort((a, b) => new Date(b) - new Date(a)).map(key => ({
            weekStart: new Date(key),
            weekEnd: new Date(new Date(key).getTime() + 6 * 24 * 60 * 60 * 1000),
            records: weeks[key]
        }));
    };

    const weeklyGroups = filterDate ? [] : groupToWeeks(records);

    if (loading) return <div className="p-10 text-center text-slate-400">Loading Attendance...</div>;

    const renderDayCard = (r) => {
        const rTotals = calculateTotals([r]);
        return (
            <div key={r.id} className="bg-white rounded-2xl border border-slate-100 shadow-sm mb-3 overflow-hidden group">
                <div className="p-4">
                    <div className="flex justify-between items-center mb-3">
                        <div className="bg-blue-600 text-white px-3 py-1.5 rounded-lg text-xs font-bold shadow-sm">
                            {formatDate(r.date)}
                        </div>
                        <div className="flex items-center gap-3">
                            {rTotals.cost > 0 && <span className="font-bold text-emerald-600 text-sm">₹{formatCurrency(rTotals.cost)}</span>}
                            <button onClick={() => openAdd(r)} className="p-1.5 text-slate-400 hover:text-blue-500 hover:bg-blue-50 rounded-lg transition-colors">
                                <Edit2 size={16} />
                            </button>
                            <button onClick={() => handleDelete(r.id)} className="p-1.5 text-slate-400 hover:text-rose-500 hover:bg-rose-50 rounded-lg transition-colors">
                                <Trash2 size={16} />
                            </button>
                        </div>
                    </div>
                </div>
                <div className="px-4 pb-4">
                    <div className="flex flex-wrap gap-2">
                        {roles.map(role => {
                            const c = r[role.countKey] || 0;
                            const rate = r[role.rateKey] || 0;
                            if (c > 0) {
                                return (
                                    <div key={role.key} className="bg-orange-50 border border-orange-200 text-orange-800 px-2.5 py-1 rounded-md text-[11px] font-bold flex items-center gap-1.5 shadow-sm">
                                        <Users size={12} className="text-orange-600" />
                                        <span>
                                            {role.title}: {c} {rate > 0 && `– ₹${formatCurrency(rate)}`}
                                        </span>
                                    </div>
                                );
                            }
                            return null;
                        })}
                        {(r.customEntered || 0) > 0 && (
                            <div className="bg-orange-50 border border-orange-200 text-orange-800 px-2.5 py-1 rounded-md text-[11px] font-bold flex items-center gap-1.5 shadow-sm">
                                <Star size={12} className="text-orange-500" />
                                <span>
                                    {r.customRoleName || 'Custom'}: {r.customEntered} {(r.customEnteredRate || 0) > 0 && `– ₹${formatCurrency(r.customEnteredRate)}`}
                                </span>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        );
    };

    return (
        <div className="space-y-6 pb-20 relative">

            {/* Filter Banner */}
            {filterDate && (
                <div className="flex items-center justify-between bg-blue-50 border border-blue-100 rounded-2xl p-4">
                    <div className="flex items-center gap-3">
                        <div className="bg-blue-600 text-white rounded-xl px-4 py-2 flex items-center gap-2 cursor-pointer shadow-md text-sm font-bold" onClick={() => {
                            const input = document.createElement('input');
                            input.type = 'date';
                            input.onchange = (e) => setFilterDate(new Date(e.target.value));
                            input.click();
                        }}>
                            <CalendarDays size={16} />
                            {new Date(filterDate).toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'long', year: 'numeric' })}
                        </div>
                        <button onClick={() => setFilterDate(null)} className="p-2 bg-slate-200 text-slate-600 rounded-full hover:bg-slate-300">
                            <X size={14} />
                        </button>
                    </div>
                    <span className="text-xs text-slate-400 font-bold uppercase tracking-widest hidden sm:block">Filtered View</span>
                </div>
            )}

            {/* Summary Card */}
            {!filterDate && (
                <div className="bg-blue-50/80 rounded-3xl border border-blue-100 p-6 flex flex-col justify-between shadow-sm relative overflow-hidden">
                    <div className="flex items-start justify-between mb-4">
                        <h3 className="text-xl font-black text-blue-900">Attendance Register</h3>
                        <div className="flex gap-1 items-center z-10">
                            {records.length > 0 && (
                                <>
                                    <button onClick={() => generateAttendanceCSV(project, records)} className="p-2 bg-white/50 hover:bg-white text-emerald-600 rounded-xl transition-all shadow-sm" title="Export Excel">
                                        <Layout size={18} />
                                    </button>
                                    <button onClick={() => generateAttendancePDF(project, records)} className="p-2 bg-white/50 hover:bg-white text-rose-500 rounded-xl transition-all shadow-sm mx-1" title="Export PDF">
                                        <FileText size={18} />
                                    </button>
                                </>
                            )}
                            <button onClick={() => {
                                const input = document.createElement('input');
                                input.type = 'date';
                                input.onchange = (e) => setFilterDate(new Date(e.target.value));
                                input.click();
                            }} className="p-2 bg-white/50 hover:bg-white text-slate-600 rounded-xl transition-all shadow-sm" title="Filter Date">
                                <CalendarIcon size={18} />
                            </button>
                            <button onClick={() => openAdd()} className="p-2 bg-white/50 hover:bg-white text-blue-600 rounded-xl transition-all shadow-sm ml-1" title="Add Attendance">
                                <Plus size={18} />
                            </button>
                        </div>
                    </div>

                    <div className="flex flex-wrap gap-3">
                        <div className="bg-blue-100/50 text-blue-800 px-3 py-1.5 rounded-full text-xs font-bold flex items-center gap-1.5 border border-blue-200/50">
                            <CalendarIcon size={14} /> {totalDays} Days
                        </div>
                        <div className="bg-purple-100/50 text-purple-800 px-3 py-1.5 rounded-full text-xs font-bold flex items-center gap-1.5 border border-purple-200/50">
                            <Users size={14} /> {totalWorkerDays} Worker-Days
                        </div>
                        {totalCost > 0 && (
                            <div className="bg-emerald-100/50 text-emerald-800 px-3 py-1.5 rounded-full text-xs font-bold flex items-center gap-1.5 border border-emerald-200/50">
                                <IndianRupee size={14} /> ₹{formatCurrency(totalCost)}
                            </div>
                        )}
                    </div>
                </div>
            )}

            {/* Content Body */}
            {filterDate ? (
                // Filtered List
                <div className="space-y-4">
                    {filteredRecords.length === 0 ? (
                        <div className="py-20 text-center flex flex-col items-center">
                            <CalendarIcon size={48} className="text-slate-200 mb-4" />
                            <p className="text-slate-400 font-bold mb-4">No attendance on {new Date(filterDate).toLocaleDateString('en-GB')}</p>
                            <button onClick={() => openAdd(null, filterDate)} className="bg-blue-600 text-white px-6 py-2.5 rounded-xl font-bold flex items-center gap-2 hover:bg-blue-700 shadow-lg">
                                <Plus size={16} /> Add for this day
                            </button>
                        </div>
                    ) : (
                        filteredRecords.map(r => renderDayCard(r))
                    )}
                </div>
            ) : (
                // Weekly List
                records.length === 0 ? (
                    <div className="py-20 text-center flex flex-col items-center">
                        <ClipboardList size={64} className="text-slate-200 mb-4" />
                        <p className="text-slate-500 font-bold text-lg mb-2">No attendance recorded yet.</p>
                        <button onClick={() => openAdd()} className="bg-blue-50 text-blue-600 px-6 py-2.5 rounded-xl font-bold flex items-center gap-2 hover:bg-blue-100 mt-4 transition-colors">
                            <Plus size={16} /> Add First Entry
                        </button>
                    </div>
                ) : (
                    <div className="space-y-8">
                        {weeklyGroups.map((group, idx) => {
                            const wTotals = calculateTotals(group.records);
                            const wStartStr = group.weekStart.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' });
                            const wEndStr = group.weekEnd.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });

                            return (
                                <div key={idx} className="space-y-4">
                                    <div className="flex flex-wrap items-center gap-3">
                                        <div className="w-1.5 h-6 bg-blue-600 rounded-full" />
                                        <h4 className="font-bold text-slate-800 flex-1">{wStartStr} – {wEndStr}</h4>
                                        <div className="flex items-center gap-2">
                                            {wTotals.workers > 0 && (
                                                <div className="bg-purple-50 border border-purple-100 text-purple-700 px-2 py-1 rounded-lg text-[10px] font-bold">
                                                    {wTotals.workers} workers
                                                </div>
                                            )}
                                            {wTotals.cost > 0 && (
                                                <div className="bg-emerald-50 border border-emerald-100 text-emerald-800 px-2 py-1 rounded-lg text-[10px] font-bold">
                                                    ₹{formatCurrency(wTotals.cost)}
                                                </div>
                                            )}
                                            <button onClick={() => generateAttendanceCSV(project, group.records, true, group.weekStart, group.weekEnd)} className="text-emerald-500 hover:bg-emerald-50 p-1.5 rounded transition-all">
                                                <Layout size={18} />
                                            </button>
                                            <button onClick={() => generateAttendancePDF(project, group.records, true, group.weekStart, group.weekEnd)} className="text-rose-500 hover:bg-rose-50 p-1.5 rounded transition-all">
                                                <FileText size={18} />
                                            </button>
                                        </div>
                                    </div>
                                    <div>
                                        {group.records.map(r => renderDayCard(r))}
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )
            )}

            <AddAttendanceDialog
                isOpen={isAddOpen}
                onClose={() => setIsAddOpen(false)}
                projectId={projectId}
                existingRecord={editRecord}
            />
        </div>
    );
}
