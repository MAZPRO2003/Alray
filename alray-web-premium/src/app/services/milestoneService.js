import { db } from '../../firebase';
import {
    collection, addDoc, updateDoc, deleteDoc,
    doc, query, orderBy, where, onSnapshot, serverTimestamp
} from 'firebase/firestore';

export const milestoneService = {
    subscribeToProjectMilestones: (userId, projectId, callback) => {
        const q = query(
            collection(db, 'milestones'),
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
                return getTime(a.dateCreated) - getTime(b.dateCreated);
            });
            callback(data);
        });
    },

    addMilestone: async (userId, data) => {
        return await addDoc(collection(db, 'milestones'), {
            ...data,
            userId,
            isCompleted: false,
            dateCreated: new Date().toISOString(),
            createdAt: serverTimestamp()
        });
    },

    updateMilestone: async (id, data) => {
        await updateDoc(doc(db, 'milestones', id), data);
    },

    deleteMilestone: async (id) => {
        await deleteDoc(doc(db, 'milestones', id));
    }
};
