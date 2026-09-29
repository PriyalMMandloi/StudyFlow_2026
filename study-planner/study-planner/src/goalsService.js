// src/goalsService.js
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDocs,
  updateDoc,
} from "firebase/firestore"
import { auth, db } from "./firebase/firebase"

function getUserId() {
  return auth.currentUser?.uid
}

// Get all goals for the current user
export async function getGoals() {
  const userId = getUserId()
  if (!userId) return []

  const snapshot = await getDocs(collection(db, "users", userId, "goals"))
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))
}

// Add a new goal
export async function addGoal(goal) {
  const userId = getUserId()
  if (!userId) throw new Error("User not authenticated")

  return addDoc(collection(db, "users", userId, "goals"), goal)
}

// Update an existing goal (also used internally by recalcGoalProgress)
export async function updateGoal(id, updates) {
  const userId = getUserId()
  if (!userId) throw new Error("User not authenticated")

  await updateDoc(doc(db, "users", userId, "goals", id), updates)
}

// Delete a goal
export async function deleteGoal(id) {
  const userId = getUserId()
  if (!userId) throw new Error("User not authenticated")

  await deleteDoc(doc(db, "users", userId, "goals", id))
}
