import { addDoc, collection, deleteDoc, doc, getDocs, updateDoc } from "firebase/firestore";
import { auth, db } from "./firebase/firebase";
import * as NotesService from "./notesService";
console.log(NotesService);
// Get user id
function getUserId() {
  return auth.currentUser?.uid;
}

// Get notes
export async function getNotes(userId = getUserId()) {
  if (!userId) return [];

  const snapshot = await getDocs(collection(db, "users", userId, "notes"));
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

// Add note
export async function addNote(userId, note) {
  if (!userId || getUserId() !== userId) throw new Error("User authentication changed");

  return addDoc(collection(db, "users", userId, "notes"), note);
}

// Delete note
export async function deleteNote(userId, id) {
  if (!userId || getUserId() !== userId) throw new Error("User authentication changed");

  const ref = doc(db, "users", userId, "notes", id);
  await deleteDoc(ref);
}

// Update note
export async function updateNote(userId, id, updates) {
  if (!userId || getUserId() !== userId) throw new Error("User authentication changed");

  const ref = doc(db, "users", userId, "notes", id);
  await updateDoc(ref, updates);
}