const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "5432", 10),
  database: process.env.DB_NAME || "taskmanager",
  user: process.env.DB_USER || "appuser",
  password: process.env.DB_PASSWORD || "apppassword",
});

// --------------- Routes ---------------

// Health check
app.get("/health", async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "healthy", timestamp: new Date().toISOString() });
  } catch (err) {
    res.status(503).json({ status: "unhealthy", error: err.message });
  }
});

// GET all tasks
app.get("/api/tasks", async (_req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM tasks ORDER BY id ASC"
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Error fetching tasks:", err.message);
    res.status(500).json({ error: "Failed to fetch tasks" });
  }
});

// POST create a task
app.post("/api/tasks", async (req, res) => {
  const { title, description, status } = req.body;

  if (!title) {
    return res.status(400).json({ error: "Title is required" });
  }

  try {
    const result = await pool.query(
      "INSERT INTO tasks (title, description, status) VALUES ($1, $2, $3) RETURNING *",
      [title, description || "", status || "pending"]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error("Error creating task:", err.message);
    res.status(500).json({ error: "Failed to create task" });
  }
});

// PUT update a task
app.put("/api/tasks/:id", async (req, res) => {
  const { id } = req.params;
  const { title, description, status } = req.body;

  try {
    const result = await pool.query(
      "UPDATE tasks SET title = COALESCE($1, title), description = COALESCE($2, description), status = COALESCE($3, status) WHERE id = $4 RETURNING *",
      [title, description, status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Task not found" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error("Error updating task:", err.message);
    res.status(500).json({ error: "Failed to update task" });
  }
});

// DELETE a task
app.delete("/api/tasks/:id", async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      "DELETE FROM tasks WHERE id = $1 RETURNING *",
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Task not found" });
    }

    res.json({ message: "Task deleted", task: result.rows[0] });
  } catch (err) {
    console.error("Error deleting task:", err.message);
    res.status(500).json({ error: "Failed to delete task" });
  }
});

// Start server
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Backend listening on port ${PORT}`);
});
