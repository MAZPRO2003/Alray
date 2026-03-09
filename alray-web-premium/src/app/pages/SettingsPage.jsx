import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { User, Mail, Shield, Bell, Contact, Info, LogOut, ChevronRight, Hash } from 'lucide-react';
import BusinessCard from '../components/settings/BusinessCard';

export default function SettingsPage() {
    const { currentUser, logout } = useAuth();
    const [isBusinessCardOpen, setIsBusinessCardOpen] = useState(false);

    // Default to true (Indian System) like flutter
    const [useIndianSystem, setUseIndianSystem] = useState(() => {
        const stored = localStorage.getItem('indian_system');
        return stored !== null ? stored === 'true' : true;
    });

    const toggleIndianSystem = (checked) => {
        setUseIndianSystem(checked);
        localStorage.setItem('indian_system', checked.toString());
        // Reload page to apply formatting everywhere across the app
        window.location.reload();
    };

    const handleLogout = async () => {
        if (window.confirm('Are you sure you want to log out?')) {
            try {
                await logout();
            } catch (error) {
                console.error("Failed to log out", error);
                alert("Failed to log out.");
            }
        }
    };

    return (
        <div className="max-w-4xl mx-auto space-y-6 pb-24 h-[calc(100vh-80px)] overflow-y-auto">
            <div>
                <h1 className="text-2xl font-bold text-[var(--color-secondary)]">Settings</h1>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="p-0">
                    {/* Account Profile */}
                    <div className="p-4 flex items-center justify-between hover:bg-slate-50 cursor-pointer transition-colors border-b border-gray-100">
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center">
                                <User size={20} className="text-blue-500" />
                            </div>
                            <div>
                                <h3 className="font-bold text-slate-800 text-[15px]">Account Profile</h3>
                                <p className="text-sm text-slate-500">{currentUser?.email || 'Not logged in'}</p>
                            </div>
                        </div>
                        <ChevronRight size={20} className="text-slate-400" />
                    </div>

                    {/* My Business Card */}
                    <div
                        className="p-4 flex items-center justify-between hover:bg-slate-50 cursor-pointer transition-colors border-b border-gray-100"
                        onClick={() => setIsBusinessCardOpen(true)}
                    >
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-full bg-purple-50 flex items-center justify-center">
                                <Contact size={20} className="text-purple-600" />
                            </div>
                            <div>
                                <h3 className="font-bold text-slate-800 text-[15px]">My Business Card</h3>
                                <p className="text-sm text-slate-500">View and share your digital card</p>
                            </div>
                        </div>
                        <ChevronRight size={20} className="text-slate-400" />
                    </div>

                    {/* Indian Unit System */}
                    <div className="p-4 flex items-center justify-between border-b border-gray-100 hover:bg-slate-50 transition-colors">
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-full bg-green-50 flex items-center justify-center">
                                <Hash size={20} className="text-green-600" />
                            </div>
                            <div>
                                <h3 className="font-bold text-slate-800 text-[15px]">Indian Unit System</h3>
                                <p className="text-sm text-slate-500">Use Lakhs & Crores (instead of M/B)</p>
                            </div>
                        </div>
                        <label className="relative inline-flex items-center cursor-pointer">
                            <input
                                type="checkbox"
                                className="sr-only peer"
                                checked={useIndianSystem}
                                onChange={(e) => toggleIndianSystem(e.target.checked)}
                            />
                            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[var(--color-primary)]"></div>
                        </label>
                    </div>

                    {/* App Theme (Fixed) */}
                    <div className="p-4 flex items-center justify-between border-b border-gray-100">
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-full bg-amber-50 flex items-center justify-center">
                                <Bell size={20} className="text-amber-500" />
                            </div>
                            <div>
                                <h3 className="font-bold text-slate-800 text-[15px]">App Theme</h3>
                                <p className="text-sm text-slate-500">Alray Premium Design</p>
                            </div>
                        </div>
                    </div>

                    {/* About App */}
                    <div
                        className="p-4 flex items-center justify-between hover:bg-slate-50 cursor-pointer transition-colors border-b border-gray-100"
                        onClick={() => alert("Real Estate Budget Web v1.0.0")}
                    >
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-full bg-slate-50 flex items-center justify-center">
                                <Info size={20} className="text-slate-600" />
                            </div>
                            <div>
                                <h3 className="font-bold text-slate-800 text-[15px]">About App</h3>
                                <p className="text-sm text-slate-500">Real Estate Budget v1.0.0</p>
                            </div>
                        </div>
                    </div>

                    {/* Logout */}
                    <div
                        className="p-4 flex items-center justify-between hover:bg-red-50 cursor-pointer transition-colors"
                        onClick={handleLogout}
                    >
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-full bg-red-50 flex items-center justify-center">
                                <LogOut size={20} className="text-red-500" />
                            </div>
                            <div>
                                <h3 className="font-bold text-red-500 text-[15px]">Logout</h3>
                            </div>
                        </div>
                    </div>

                </div>
            </div>

            {isBusinessCardOpen && (
                <BusinessCard onClose={() => setIsBusinessCardOpen(false)} />
            )}
        </div>
    );
}
