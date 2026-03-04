import { db } from '../../firebase';
import {
    collection, addDoc, updateDoc, deleteDoc,
    doc, query, orderBy, where, onSnapshot, serverTimestamp
} from 'firebase/firestore';

// Flutter uses 'entries' collection for materials/budget entries
export const materialService = {
    subscribeToProjectMaterials: (userId, projectId, callback) => {
        const q = query(
            collection(db, 'entries'),
            where('userId', '==', userId),
            where('projectId', '==', projectId)
        );
        return onSnapshot(q, snap => {
            const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
            // Sort locally to avoid index errors
            data.sort((a, b) => {
                const aTime = a.date?.toMillis ? a.date.toMillis() : 0;
                const bTime = b.date?.toMillis ? b.date.toMillis() : 0;
                return bTime - aTime;
            });
            callback(data);
        });
    },

    addMaterial: async (userId, data) => {
        return await addDoc(collection(db, 'entries'), {
            ...data,
            userId,
            transactionType: 'expense',
            categoryId: data.categoryId || 'otherMiscMaterials',
            quantity: Number(data.quantity) || 1,
            rate: Number(data.rate) || 0,
            amount: (Number(data.quantity) || 1) * (Number(data.rate) || 0),
            date: data.date ? new Date(data.date).toISOString() : new Date().toISOString(),
            createdAt: new Date().toISOString()
        });
    },

    updateMaterial: async (id, data) => {
        await updateDoc(doc(db, 'entries', id), data);
    },

    deleteMaterial: async (id) => {
        await deleteDoc(doc(db, 'entries', id));
    }
};
