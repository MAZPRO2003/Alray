import React from 'react';
import { NavLink } from 'react-router-dom';
import { LayoutDashboard, FolderKanban, Users, Receipt, CreditCard, Settings, User } from 'lucide-react';
import Logo from '../../components/Logo';

export default function Sidebar() {
    const menuItems = [
        { name: 'Dashboard', path: '/app/dashboard', icon: LayoutDashboard },
        { name: 'Projects', path: '/app/projects', icon: FolderKanban },
        { name: 'Contacts', path: '/app/contacts', icon: Users },
        { name: 'All Expenses', path: '/app/expenses', icon: Receipt },
    ];

    return (
        <aside className="w-64 h-screen fixed left-0 top-0 border-r" style={{ background: 'var(--color-secondary)', borderColor: 'var(--color-secondary-light)' }}>
            <div className="h-16 flex items-center px-6 border-b" style={{ borderColor: 'var(--color-secondary-light)' }}>
                <Logo light className="h-8" />
            </div>

            <div className="flex flex-col h-[calc(100vh-4rem)] justify-between py-6">
                <nav className="px-4 space-y-2">
                    {menuItems.map((item) => (
                        <NavLink
                            key={item.name}
                            to={item.path}
                            className={({ isActive }) =>
                                `flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 ${isActive
                                    ? 'bg-gradient-to-r from-[var(--color-primary)] to-[var(--color-primary-hover)] text-white shadow-lg'
                                    : 'text-gray-400 hover:bg-white/5 hover:text-white'
                                }`
                            }
                        >
                            <item.icon size={20} />
                            <span className="font-medium">{item.name}</span>
                        </NavLink>
                    ))}
                </nav>

                <div className="px-4 space-y-2">
                    <NavLink
                        to="/app/profile"
                        className={({ isActive }) =>
                            `flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 ${isActive
                                ? 'bg-gradient-to-r from-[var(--color-primary)] to-[var(--color-primary-hover)] text-white shadow-lg'
                                : 'text-gray-400 hover:bg-white/5 hover:text-white'
                            }`
                        }
                    >
                        <User size={20} />
                        <span className="font-medium">Profile</span>
                    </NavLink>
                    <NavLink
                        to="/app/settings"
                        className={({ isActive }) =>
                            `flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 ${isActive
                                ? 'bg-gradient-to-r from-[var(--color-primary)] to-[var(--color-primary-hover)] text-white shadow-lg'
                                : 'text-gray-400 hover:bg-white/5 hover:text-white'
                            }`
                        }
                    >
                        <Settings size={20} />
                        <span className="font-medium">Settings</span>
                    </NavLink>
                </div>
            </div>
        </aside>
    );
}
