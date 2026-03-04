import { db } from '../../firebase';
import {
    collection, addDoc, updateDoc, deleteDoc,
    doc, query, orderBy, where, onSnapshot, serverTimestamp
} from 'firebase/firestore';

export const contactService = {
    subscribeToContacts: (userId, callback) => {
        const q = query(
            collection(db, 'contacts'),
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

    subscribeToContact: (id, callback) => {
        return onSnapshot(doc(db, 'contacts', id), (doc) => {
            if (doc.exists()) {
                callback({ id: doc.id, ...doc.data() });
            } else {
                callback(null);
            }
        });
    },

    addContact: async (userId, data) => {
        return await addDoc(collection(db, 'contacts'), {
            ...data,
            userId,
            createdAt: serverTimestamp()
        });
    },

    updateContact: async (id, data) => {
        await updateDoc(doc(db, 'contacts', id), data);
    },

    deleteContact: async (id) => {
        await deleteDoc(doc(db, 'contacts', id));
    }
};
