import { db } from '../../firebase';
import {
    collection, addDoc, updateDoc, deleteDoc,
    doc, query, orderBy, where, onSnapshot, serverTimestamp
} from 'firebase/firestore';

export const laborService = {
    subscribeToLaborers: (userId, callback) => {
        const q = query(
            collection(db, 'labor_tasks'),
            where('userId', '==', userId)
        );
        return onSnapshot(q, snap => {
            const map = {};
            snap.docs.forEach(d => {
                const data = { id: d.id, ...d.data() };
                const key = data.laborerName || data.name || d.id;
                if (!map[key]) {
                    map[key] = {
                        id: d.id,
                        name: key,
                        wagePerDay: data.rate || data.wagePerDay || 0,
                        pendingDays: 0,
                        pendingAmount: 0,
                        category: data.category || ''
                    };
                }
            });
            callback(Object.values(map));
        });
    },

    addLaborer: async (userId, data) => {
        return await addDoc(collection(db, 'labor_tasks'), {
            ...data,
            userId,
            wagePerDay: Number(data.wagePerDay) || 0,
            pendingDays: 0,
            pendingAmount: 0,
            createdAt: serverTimestamp()
        });
    },

    updateLaborer: async (id, data) => {
        await updateDoc(doc(db, 'labor_tasks', id), data);
    },

    deleteLaborer: async (id) => {
        await deleteDoc(doc(db, 'labor_tasks', id));
    }
};

export const laborTaskService = {
    subscribeToProjectTasks: (userId, projectId, callback) => {
        const q = query(
            collection(db, 'labor_tasks'),
            where('userId', '==', userId),
            where('projectId', '==', projectId)
        );
        return onSnapshot(q, snap => {
            const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
            data.sort((a, b) => {
                const getTime = (val) => {
                    if (!val) return 0;
                    if (val.toMillis) return val.toMillis();
                    return new Date(val).getTime();
                };
                return getTime(b.startDate || b.date) - getTime(a.startDate || a.date);
            });
            callback(data);
        });
    },

    addLaborTask: async (userId, data) => {
        return await addDoc(collection(db, 'labor_tasks'), {
            ...data,
            userId,
            name: data.name,
            laborerCount: Number(data.laborerCount) || 1,
            role: data.role || 'Worker',
            completionPercentage: Number(data.completionPercentage || 0) / 100, // Sync with mobile 0.0-1.0
            startDate: data.startDate ? new Date(data.startDate) : new Date(),
            endDate: data.endDate ? new Date(data.endDate) : null,
            createdAt: serverTimestamp()
        });
    },

    deleteTask: async (id) => {
        await deleteDoc(doc(db, 'labor_tasks', id));
    },

    updateTask: async (id, data) => {
        await updateDoc(doc(db, 'labor_tasks', id), data);
    },

    updateTaskProgress: async (id, completionPercentage) => {
        await updateDoc(doc(db, 'labor_tasks', id), {
            completionPercentage: Number(completionPercentage) / 100, // Sync with mobile 0.0-1.0
            lastUpdated: serverTimestamp()
        });
    }
};

export const laborPaymentService = {
    subscribeToProjectPayments: (userId, projectId, callback) => {
        const q = query(
            collection(db, 'labor_payments'),
            where('userId', '==', userId),
            where('projectId', '==', projectId)
        );
        return onSnapshot(q, snap => {
            const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
            data.sort((a, b) => {
                const getTime = (val) => {
                    if (!val) return 0;
                    if (val.toMillis) return val.toMillis();
                    return new Date(val).getTime();
                };
                return getTime(b.date) - getTime(a.date);
            });
            callback(data);
        });
    },

    addPayment: async (userId, data) => {
        return await addDoc(collection(db, 'labor_payments'), {
            userId,
            projectId: data.projectId,
            laborerName: data.laborerName,
            amount: Number(data.amount),
            periodStart: new Date(data.periodStart),
            periodEnd: new Date(data.periodEnd),
            description: data.description || '',
            date: serverTimestamp(),
            createdAt: serverTimestamp()
        });
    },

    updatePayment: async (id, data) => {
        await updateDoc(doc(db, 'labor_payments', id), {
            ...data,
            amount: Number(data.amount),
            periodStart: new Date(data.periodStart),
            periodEnd: new Date(data.periodEnd),
        });
    },

    deletePayment: async (id) => {
        await deleteDoc(doc(db, 'labor_payments', id));
    }
};
