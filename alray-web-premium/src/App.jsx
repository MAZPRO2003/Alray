import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './app/context/AuthContext';
import PrivateRoute from './app/components/PrivateRoute';
import LandingPage from './app/pages/LandingPage';

import LoginPage from './app/pages/Auth/LoginPage';
import SignupPage from './app/pages/Auth/SignupPage';
import ProjectsListPage from './app/pages/ProjectsListPage';
import ProjectDetailsPage from './app/pages/ProjectDetailsPage';
import ContactsPage from './app/pages/ContactsPage';
import ContactDetailsPage from './app/pages/ContactDetailsPage';
import AllExpensesPage from './app/pages/AllExpensesPage';
import SettingsPage from './app/pages/SettingsPage';
import ProfilePage from './app/pages/ProfilePage';
import AppLayout from './app/components/AppLayout';

// Placeholder Pages for App
import DashboardPage from './app/pages/DashboardPage';

function App() {
    return (
        <AuthProvider>
            <BrowserRouter>
                <Routes>
                    {/* Public Routes */}
                    <Route path="/" element={<LandingPage />} />
                    <Route path="/login" element={<LoginPage />} />
                    <Route path="/signup" element={<SignupPage />} />

                    {/* Protected Routes */}
                    <Route path="/app" element={
                        <PrivateRoute>
                            <AppLayout />
                        </PrivateRoute>
                    }>
                        <Route index element={<Navigate to="dashboard" replace />} />
                        <Route path="dashboard" element={<DashboardPage />} />
                        <Route path="projects" element={<ProjectsListPage />} />
                        <Route path="projects/:id" element={<ProjectDetailsPage />} />
                        <Route path="contacts" element={<ContactsPage />} />
                        <Route path="contacts/:id" element={<ContactDetailsPage />} />
                        <Route path="expenses" element={<AllExpensesPage />} />
                        <Route path="settings" element={<SettingsPage />} />
                        <Route path="profile" element={<ProfilePage />} />
                    </Route>

                    {/* Catch-all */}
                    <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
            </BrowserRouter>
        </AuthProvider>
    );
}

export default App;
