import { db } from '../../firebase';
import {
    collection, addDoc, updateDoc, deleteDoc,
    doc, query, orderBy, where, onSnapshot, serverTimestamp
} from 'firebase/firestore';

export const expenseService = {
    // Flutter uses 'entries' collection for all expense data (unified)
    subscribeToAllExpenses: (userId, callback) => {
        const q = query(
            collection(db, 'entries'),
            where('userId', '==', userId)
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

    subscribeToProjectExpenses: (userId, projectId, callback) => {
        const q = query(
            collection(db, 'entries'),
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

    addExpense: async (userId, data) => {
        return await addDoc(collection(db, 'entries'), {
            ...data,
            userId,
            transactionType: 'expense',
            categoryId: data.categoryId || 'miscExp',
            quantity: 1,
            rate: Number(data.amount) || 0,
            amount: Number(data.amount) || 0,
            date: data.date ? new Date(data.date).toISOString() : new Date().toISOString(),
            createdAt: new Date().toISOString()
        });
    },

    addRevenue: async (userId, data) => {
        return await addDoc(collection(db, 'entries'), {
            ...data,
            userId,
            transactionType: 'credit',
            categoryId: 'revenue',
            amount: Number(data.amount) || 0,
            date: data.date ? new Date(data.date).toISOString() : new Date().toISOString(),
            createdAt: new Date().toISOString()
        });
    },

    updateExpense: async (id, data) => {
        await updateDoc(doc(db, 'entries', id), data);
    },

    deleteExpense: async (id) => {
        await deleteDoc(doc(db, 'entries', id));
    }
};
