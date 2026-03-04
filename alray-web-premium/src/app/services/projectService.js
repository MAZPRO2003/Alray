import { db } from '../../firebase';
import {
    collection, addDoc, updateDoc, deleteDoc,
    doc, query, orderBy, where, onSnapshot, serverTimestamp
} from 'firebase/firestore';

export const projectService = {
    subscribeToProjects: (userId, callback) => {
        const q = query(
            collection(db, 'projects'),
            where('userId', '==', userId)
        );
        return onSnapshot(q, snap => {
            const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
            // Sort locally to avoid requiring a Firebase composite index
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

    subscribeToProject: (id, callback) => {
        return onSnapshot(doc(db, 'projects', id), (doc) => {
            if (doc.exists()) {
                callback({ id: doc.id, ...doc.data() });
            } else {
                callback(null);
            }
        });
    },

    addProject: async (userId, data) => {
        return await addDoc(collection(db, 'projects'), {
            ...data,
            userId,
            budget: Number(data.budget) || 0,
            status: data.status || 'active',
            startDate: data.startDate ? new Date(data.startDate).toISOString() : null,
            endDate: data.endDate ? new Date(data.endDate).toISOString() : null,
            createdAt: new Date().toISOString() // Using ISO string for mobile sync
        });
    },

    updateProject: async (id, data) => {
        const updateData = { ...data };
        if (data.startDate) updateData.startDate = new Date(data.startDate).toISOString();
        if (data.endDate) updateData.endDate = new Date(data.endDate).toISOString();
        await updateDoc(doc(db, 'projects', id), updateData);
    },

    deleteProject: async (id) => {
        await deleteDoc(doc(db, 'projects', id));
    }
};
