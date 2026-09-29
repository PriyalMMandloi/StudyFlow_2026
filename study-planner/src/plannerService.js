// src/plannerService.js
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDocs,
  query,
  updateDoc,
  where,
} from "firebase/firestore"
import { auth, db } from "./firebase/firebase"
import { updateGoal } from "./goalsService"

function getUserId() {
  return auth.currentUser?.uid
}

// Fetch tasks for a specific date
export async function getTasks(date) {
  const userId = getUserId()
  if (!userId) return []

  const snapshot = await getDocs(collection(db, "users", userId, "planner"))
  return snapshot.docs
    .map(doc => ({ id: doc.id, ...doc.data() }))
    .filter(task => task.date === date)
}

// Add a new task
export async function addTask(task) {
  const userId = getUserId()
  if (!userId) throw new Error("User not authenticated")

  return await addDoc(collection(db, "users", userId, "planner"), task)
}

// Update an existing task
export async function updateTask(id, updates) {
  const userId = getUserId()
  if (!userId) throw new Error("User not authenticated")

  await updateDoc(doc(db, "users", userId, "planner", id), updates)
}

// Delete a task
export async function deleteTask(id) {
  const userId = getUserId()
  if (!userId) throw new Error("User not authenticated")

  await deleteDoc(doc(db, "users", userId, "planner", id))
}

// Fetch all tasks linked to a specific goal
export async function getTasksForGoal(goalId) {
  const userId = getUserId()
  if (!userId) return []

  // Requires a Firestore composite index on goalId.
  // Firebase will log a link in the console the first time — click it to auto-create.
  const q = query(
    collection(db, "users", userId, "planner"),
    where("goalId", "==", goalId)
  )
  const snapshot = await getDocs(q)
  return snapshot.docs.map(d => ({ id: d.id, ...d.data() }))
}

// Recompute and persist goal progress based on its linked tasks
export async function recalcGoalProgress(goalId) {
  if (!goalId) return

  const tasks = await getTasksForGoal(goalId)
  if (tasks.length === 0) return

  const completedTasks = tasks.filter(t => t.completed).length
  const progress = Math.round((completedTasks / tasks.length) * 100)

  await updateGoal(goalId, {
    progress,
    totalTasks: tasks.length,
    completedTasks,
  })

  return progress
}

// Toggle task completion — also syncs goal progress if the task is linked to a goal
export async function toggleTask(id, completed, goalId) {
  const userId = getUserId()
  if (!userId) throw new Error("User not authenticated")

  await updateDoc(doc(db, "users", userId, "planner", id), { completed })

  if (goalId) {
    await recalcGoalProgress(goalId)
  }
}
