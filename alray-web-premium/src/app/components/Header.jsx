import React from 'react';
import { LogOut, User } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';

export default function Header() {
    const { currentUser, logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = async () => {
        try {
            await logout();
            navigate('/login');
        } catch (error) {
            console.error('Failed to log out', error);
        }
    };

    return (
        <header className="h-16 bg-white border-b flex items-center justify-between px-8 sticky top-0 z-10" style={{ borderColor: 'var(--color-border)' }}>
            <div className="flex items-center gap-4">
                <h1 className="text-xl font-semibold text-[var(--color-secondary)]">Alray Associates Portal</h1>
            </div>

            <div className="flex items-center gap-6">
                <button
                    onClick={() => navigate('/app/profile')}
                    className="flex items-center gap-3 text-sm hover:bg-gray-50 p-1.5 rounded-xl transition-colors group"
                >
                    <div className="w-8 h-8 rounded-full bg-[var(--color-light)] flex items-center justify-center text-[var(--color-primary)] group-hover:bg-[var(--color-primary)] group-hover:text-white transition-colors">
                        <User size={18} />
                    </div>
                    <span className="font-medium text-[var(--color-text)]">
                        {currentUser?.email?.split('@')[0] || 'User'}
                    </span>
                </button>

                <button
                    onClick={handleLogout}
                    className="flex items-center gap-2 text-gray-500 hover:text-red-600 transition-colors text-sm font-medium"
                >
                    <LogOut size={18} />
                    Logout
                </button>
            </div>
        </header>
    );
}
