import React from 'react';
import { useAuth } from '../context/AuthContext';
import { User, Mail, Shield, Bell } from 'lucide-react';

export default function SettingsPage() {
    const { currentUser } = useAuth();

    return (
        <div className="max-w-4xl mx-auto space-y-6">
            <div>
                <h1 className="text-2xl font-bold text-[var(--color-secondary)]">Profile & Settings</h1>
                <p className="text-gray-500">Manage your account preferences and application settings.</p>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="p-6 border-b border-gray-100">
                    <h2 className="text-lg font-bold text-[var(--color-secondary)] flex items-center gap-2">
                        <User size={20} className="text-[var(--color-primary)]" />
                        Personal Information
                    </h2>
                </div>
                <div className="p-6 space-y-4">
                    <div className="flex flex-col sm:flex-row gap-4 sm:items-center">
                        <div className="w-32 text-gray-500 text-sm font-medium">Email Address</div>
                        <div className="flex-1 flex items-center gap-3">
                            <Mail size={16} className="text-gray-400" />
                            <span className="text-[var(--color-secondary)] font-medium">{currentUser?.email || 'Not logged in'}</span>
                        </div>
                    </div>
                    <div className="flex flex-col sm:flex-row gap-4 sm:items-center">
                        <div className="w-32 text-gray-500 text-sm font-medium">Account ID</div>
                        <div className="flex-1 flex items-center gap-3">
                            <Shield size={16} className="text-gray-400" />
                            <span className="text-[var(--color-secondary)] font-mono text-sm">{currentUser?.uid || 'Unknown'}</span>
                        </div>
                    </div>
                </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="p-6 border-b border-gray-100">
                    <h2 className="text-lg font-bold text-[var(--color-secondary)] flex items-center gap-2">
                        <Bell size={20} className="text-[var(--color-primary)]" />
                        Preferences
                    </h2>
                </div>
                <div className="p-6 space-y-4">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="font-medium text-[var(--color-secondary)]">Email Notifications</p>
                            <p className="text-sm text-gray-500">Receive alerts for new inquiries and project updates.</p>
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" className="sr-only peer" defaultChecked />
                            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[var(--color-primary)]"></div>
                        </label>
                    </div>

                    <div className="flex items-center justify-between pt-4 border-t border-gray-100">
                        <div>
                            <p className="font-medium text-[var(--color-secondary)]">App Theme</p>
                            <p className="text-sm text-gray-500">The theme is permanently set to the Alray Premium Design System.</p>
                        </div>
                        <span className="px-3 py-1 bg-[var(--color-secondary)] text-white text-xs font-medium rounded-full">
                            Premium Fixed
                        </span>
                    </div>

                    <div className="flex items-center justify-between pt-4 border-t border-gray-100">
                        <div>
                            <p className="font-medium text-[var(--color-secondary)]">Sign Out</p>
                            <p className="text-sm text-gray-500">Securely sign out of your account on this device.</p>
                        </div>
                        <button
                            className="px-4 py-2 border border-red-200 text-red-600 bg-red-50 hover:bg-red-100 rounded-xl text-sm font-bold transition-colors"
                        >
                            Sign Out
                        </button>
                    </div>
                </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="p-6 border-b border-gray-100">
                    <h2 className="text-lg font-bold text-[var(--color-secondary)] flex items-center gap-2">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-[var(--color-primary)]"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                        Data & Reporting
                    </h2>
                </div>
                <div className="p-6 space-y-4">
                    <p className="text-sm text-gray-500 mb-4">Export your project and financial data for external reporting and analysis.</p>

                    <div className="flex flex-col sm:flex-row gap-4">
                        <button className="flex-1 px-4 py-3 bg-gray-50 border border-gray-200 hover:border-[var(--color-primary)] hover:bg-blue-50/50 rounded-xl text-sm font-bold text-gray-700 transition-colors flex items-center justify-center gap-2">
                            Export Ledger (CSV)
                        </button>
                        <button className="flex-1 px-4 py-3 bg-gray-50 border border-gray-200 hover:border-[var(--color-primary)] hover:bg-blue-50/50 rounded-xl text-sm font-bold text-gray-700 transition-colors flex items-center justify-center gap-2">
                            Generate Tax Report
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
