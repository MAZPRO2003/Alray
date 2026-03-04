import { db } from '../../firebase';
import {
    collection, addDoc, updateDoc, deleteDoc,
    doc, query, where, onSnapshot
} from 'firebase/firestore';

export const snagService = {
    subscribeToProjectSnags: (userId, projectId, callback) => {
        const q = query(
            collection(db, 'snags'),
            where('userId', '==', userId),
            where('projectId', '==', projectId)
        );
        return onSnapshot(q, snap => {
            const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
            // Sort by priority (high first) and then by date
            const priorityMap = { high: 0, medium: 1, low: 2 };
            data.sort((a, b) => {
                if (a.status !== b.status) {
                    return a.status === 'resolved' ? 1 : -1;
                }
                if (a.priority !== b.priority) {
                    return priorityMap[a.priority] - priorityMap[b.priority];
                }
                return new Date(b.createdAt) - new Date(a.createdAt);
            });
            callback(data);
        });
    },

    addSnagItem: async (userId, data) => {
        return await addDoc(collection(db, 'snags'), {
            ...data,
            userId,
            status: data.status || 'pending',
            priority: data.priority || 'medium',
            createdAt: new Date().toISOString(),
            resolvedAt: data.status === 'resolved' ? new Date().toISOString() : null
        });
    },

    updateSnagItem: async (id, data) => {
        const updateData = { ...data };
        if (data.status === 'resolved' && !data.resolvedAt) {
            updateData.resolvedAt = new Date().toISOString();
        } else if (data.status !== 'resolved') {
            updateData.resolvedAt = null;
        }
        await updateDoc(doc(db, 'snags', id), updateData);
    },

    deleteSnagItem: async (id) => {
        await deleteDoc(doc(db, 'snags', id));
    }
};
