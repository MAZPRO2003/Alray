import { db } from '../../firebase';
import {
    collection, addDoc, updateDoc, deleteDoc,
    doc, query, orderBy, where, onSnapshot, serverTimestamp
} from 'firebase/firestore';

export const payableService = {
    subscribeToProjectPayables: (userId, projectId, callback) => {
        const q = query(
            collection(db, 'payables'),
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
                return getTime(b.createdAt) - getTime(a.createdAt);
            });
            callback(data);
        });
    },

    subscribeToAllPayables: (userId, callback) => {
        const q = query(
            collection(db, 'payables'),
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
                return getTime(b.createdAt) - getTime(a.createdAt);
            });
            callback(data);
        });
    },

    addPayable: async (userId, data) => {
        return await addDoc(collection(db, 'payables'), {
            ...data,
            userId,
            totalAmount: Number(data.amount) || 0,
            amount: Number(data.amount) || 0,
            paidAmount: Number(data.paidAmount) || 0,
            isPaid: false,
            createdAt: new Date().toISOString()
        });
    },

    markAsPaid: async (id, paidAmount) => {
        await updateDoc(doc(db, 'payables', id), {
            isPaid: true,
            paidAmount: Number(paidAmount) || 0,
            paidAt: serverTimestamp()
        });
    },

    updatePayable: async (id, data) => {
        await updateDoc(doc(db, 'payables', id), data);
    },

    deletePayable: async (id) => {
        await deleteDoc(doc(db, 'payables', id));
    }
};
