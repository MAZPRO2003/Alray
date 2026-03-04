import React from 'react';
import { motion } from 'framer-motion';
import { User, Mail, ShieldCheck, LogOut, Camera } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';

export default function ProfilePage() {
    const { currentUser, logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = async () => {
        try {
            await logout();
            navigate('/login');
        } catch (error) {
            console.error("Logout error", error);
        }
    };

    if (!currentUser) return null;

    const userName = currentUser.displayName || currentUser.email?.split('@')[0] || 'User';
    const initials = userName[0].toUpperCase();

    return (
        <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="max-w-2xl mx-auto space-y-8 py-8"
        >
            <div className="flex flex-col items-center space-y-4">
                <div className="relative group">
                    <div className="w-32 h-32 rounded-full bg-[var(--color-primary)]/10 border-4 border-white shadow-xl flex items-center justify-center overflow-hidden">
                        <span className="text-5xl font-black text-[var(--color-primary)]">{initials}</span>
                    </div>
                    <button className="absolute bottom-0 right-0 p-2 bg-white rounded-full shadow-lg border border-gray-100 text-gray-500 hover:text-[var(--color-primary)] transition-colors">
                        <Camera size={20} />
                    </button>
                </div>
                <div className="text-center">
                    <h1 className="text-3xl font-black text-[var(--color-secondary)]">{userName}</h1>
                    <p className="text-gray-500 font-medium">Project Administrator</p>
                </div>
            </div>

            <div className="bg-white rounded-3xl border border-gray-100 shadow-sm overflow-hidden">
                <div className="p-6 border-b border-gray-50 bg-gray-50/50">
                    <h2 className="text-lg font-bold text-[var(--color-secondary)]">Personal Information</h2>
                </div>
                <div className="p-6 space-y-6">
                    <div className="flex items-center gap-4">
                        <div className="p-3 bg-gray-100 rounded-xl text-gray-500">
                            <User size={20} />
                        </div>
                        <div className="flex-1">
                            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-0.5">Full Name</p>
                            <p className="font-bold text-[var(--color-secondary)]">{userName}</p>
                        </div>
                    </div>

                    <div className="flex items-center gap-4">
                        <div className="p-3 bg-gray-100 rounded-xl text-gray-500">
                            <Mail size={20} />
                        </div>
                        <div className="flex-1">
                            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-0.5">Email Address</p>
                            <p className="font-bold text-[var(--color-secondary)]">{currentUser.email}</p>
                        </div>
                    </div>

                    <div className="flex items-center gap-4">
                        <div className="p-3 bg-gray-100 rounded-xl text-gray-500">
                            <ShieldCheck size={20} />
                        </div>
                        <div className="flex-1">
                            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-0.5">Account ID</p>
                            <p className="font-mono text-xs text-gray-500">{currentUser.uid}</p>
                        </div>
                    </div>
                </div>
            </div>

            <div className="flex justify-center">
                <button
                    onClick={handleLogout}
                    className="flex items-center gap-2 text-red-600 font-bold hover:bg-red-50 px-6 py-3 rounded-xl transition-colors"
                >
                    <LogOut size={20} />
                    Sign Out of Account
                </button>
            </div>
        </motion.div>
    );
}
