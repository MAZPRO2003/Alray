import { collection, doc, query, where, orderBy, onSnapshot, setDoc, deleteDoc, updateDoc } from 'firebase/firestore';
import { db } from '../../firebase';

const COLLECTION_NAME = 'attendance_records';

export const attendanceService = {
    subscribeToProjectAttendance(userId, projectId, callback) {
        if (!userId || !projectId) return () => { };

        const q = query(
            collection(db, COLLECTION_NAME),
            where('projectId', '==', projectId)
        );

        return onSnapshot(q, (snapshot) => {
            const records = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            
            // Sort client-side if no compound index exists for projectId + date
            records.sort((a, b) => {
                const dateA = a.date?.toDate ? a.date.toDate() : (a.date ? new Date(a.date) : new Date(0));
                const dateB = b.date?.toDate ? b.date.toDate() : (b.date ? new Date(b.date) : new Date(0));
                return dateB - dateA; // Descending
            });
            
            callback(records);
        });
    },

    async addAttendanceRecord(projectId, data) {
        try {
            const docRef = doc(collection(db, COLLECTION_NAME));

            const payload = {
                ...data,
                projectId,
                createdAt: new Date()
            };

            await setDoc(docRef, payload);
            return docRef.id;
        } catch (error) {
            console.error('Error adding attendance record:', error);
            throw error;
        }
    },

    async updateAttendanceRecord(projectId, recordId, data) {
        try {
            const docRef = doc(db, COLLECTION_NAME, recordId);

            const payload = {
                ...data,
                updatedAt: new Date()
            };

            await updateDoc(docRef, payload);
        } catch (error) {
            console.error('Error updating attendance record:', error);
            throw error;
        }
    },

    async deleteAttendanceRecord(projectId, recordId) {
        try {
            await deleteDoc(doc(db, COLLECTION_NAME, recordId));
        } catch (error) {
            console.error('Error deleting attendance record:', error);
            throw error;
        }
    }
};
