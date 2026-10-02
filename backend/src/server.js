const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  database: process.env.POSTGRES_DB,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
});

app.get("/api/health", async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "ok", database: "connected", timestamp: new Date().toISOString() });
  } catch {
    res.status(503).json({ status: "degraded", database: "unavailable" });
  }
});

app.get("/api/tasks", async (req, res) => {
  try {
    const { status, priority, search } = req.query;
    const values = [];
    const conditions = [];

    if (status && status !== "all") {
      values.push(status);
      conditions.push(`status = $${values.length}`);
    }

    if (priority && priority !== "all") {
      values.push(priority);
      conditions.push(`priority = $${values.length}`);
    }

    if (search) {
      values.push(`%${search}%`);
      conditions.push(`(title ILIKE $${values.length} OR description ILIKE $${values.length})`);
    }

    const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
    const result = await pool.query(
      `SELECT * FROM tasks ${where} ORDER BY
       CASE priority WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,
       created_at DESC`,
      values
    );

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch tasks" });
  }
});

app.post("/api/tasks", async (req, res) => {
  try {
    const { title, description = "", priority = "medium", due_date = null } = req.body;
    if (!title?.trim()) return res.status(400).json({ error: "Title is required" });

    const result = await pool.query(
      `INSERT INTO tasks (title, description, priority, due_date)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [title.trim(), description, priority, due_date || null]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to create task" });
  }
});

app.patch("/api/tasks/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, status, priority, due_date } = req.body;

    const result = await pool.query(
      `UPDATE tasks SET
        title = COALESCE($1, title),
        description = COALESCE($2, description),
        status = COALESCE($3, status),
        priority = COALESCE($4, priority),
        due_date = $5,
        updated_at = NOW()
       WHERE id = $6
       RETURNING *`,
      [title, description, status, priority, due_date ?? null, id]
    );

    if (!result.rowCount) return res.status(404).json({ error: "Task not found" });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update task" });
  }
});

app.delete("/api/tasks/:id", async (req, res) => {
  try {
    const result = await pool.query("DELETE FROM tasks WHERE id = $1 RETURNING id", [req.params.id]);
    if (!result.rowCount) return res.status(404).json({ error: "Task not found" });
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete task" });
  }
});

app.get("/api/stats", async (_req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE status = 'todo')::int AS todo,
        COUNT(*) FILTER (WHERE status = 'in-progress')::int AS in_progress,
        COUNT(*) FILTER (WHERE status = 'done')::int AS done
      FROM tasks
    `);
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch stats" });
  }
});

const PORT = Number(process.env.PORT || 4000);
app.listen(PORT, () => console.log(`API listening on port ${PORT}`));
