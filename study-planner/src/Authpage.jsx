import { createUserWithEmailAndPassword, signInWithEmailAndPassword } from "firebase/auth";
import { useState } from "react";
import { auth } from "./firebase/firebase";

export default function AuthPage() {
  const [isSignup, setIsSignup] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  async function handleAuth(e) {
    e.preventDefault();
    try {
      if (isSignup) {
        await createUserWithEmailAndPassword(auth, email, password);
      } else {
        await signInWithEmailAndPassword(auth, email, password);
      }
    } catch (err) {
      alert(err.message);
    }
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h2 style={styles.title}>
          {isSignup ? "Create Account" : "Welcome Back"}
        </h2>

        <form onSubmit={handleAuth} style={styles.form}>
          <input
            style={styles.input}
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />

          <input
            style={styles.input}
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />

          <button style={styles.button} type="submit">
            {isSignup ? "Sign Up" : "Login"}
          </button>
        </form>

        <p onClick={() => setIsSignup(!isSignup)} style={styles.switch}>
          {isSignup
            ? "Already have an account? Login"
            : "Don't have an account? Sign up"}
        </p>
      </div>
    </div>
  );
}

const styles = {
  container: {
    height: "100vh",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    background: "#f5f7f3",
  },
  card: {
    background: "white",
    padding: "30px",
    borderRadius: "16px",
    width: "320px",
    boxShadow: "0 10px 30px rgba(0,0,0,0.1)",
    textAlign: "center",
  },
  title: {
    marginBottom: "20px",
    color: "#4f6f52",
  },
  form: {
    display: "flex",
    flexDirection: "column",
    gap: "12px",
  },
  input: {
    padding: "10px",
    borderRadius: "8px",
    border: "1px solid #ccc",
    outline: "none",
  },
  button: {
    padding: "10px",
    borderRadius: "8px",
    border: "none",
    background: "#8FAE8E",
    color: "white",
    fontWeight: "bold",
    cursor: "pointer",
  },
  switch: {
    marginTop: "15px",
    fontSize: "0.9rem",
    color: "#6b7280",
    cursor: "pointer",
  },
};