import { useEffect, useMemo, useState } from "react";
import {
  Activity, AlertCircle, ArrowUpRight, CheckCircle2, Circle,
  Clock3, Filter, Layers3, Plus, Search, Server, Trash2, X, Zap
} from "lucide-react";

const API = "/api";

const priorityMeta = {
  high: { label: "High", className: "priority-high" },
  medium: { label: "Medium", className: "priority-medium" },
  low: { label: "Low", className: "priority-low" }
};

const statusMeta = {
  todo: { label: "To do", className: "status-todo" },
  "in-progress": { label: "In progress", className: "status-progress" },
  done: { label: "Done", className: "status-done" }
};

function App() {
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState({ total: 0, todo: 0, in_progress: 0, done: 0 });
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("all");
  const [priority, setPriority] = useState("all");
  const [showModal, setShowModal] = useState(false);
  const [loading, setLoading] = useState(true);
  const [apiHealthy, setApiHealthy] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (search) params.set("search", search);
      if (status !== "all") params.set("status", status);
      if (priority !== "all") params.set("priority", priority);

      const [taskRes, statsRes, healthRes] = await Promise.all([
        fetch(`${API}/tasks?${params}`),
        fetch(`${API}/stats`),
        fetch(`${API}/health`)
      ]);

      setTasks(await taskRes.json());
      setStats(await statsRes.json());
      setApiHealthy(healthRes.ok);
    } catch {
      setApiHealthy(false);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [search, status, priority]);

  const completion = useMemo(
    () => stats.total ? Math.round((stats.done / stats.total) * 100) : 0,
    [stats]
  );

  const createTask = async (payload) => {
    await fetch(`${API}/tasks`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    setShowModal(false);
    load();
  };

  const updateTask = async (id, payload) => {
    await fetch(`${API}/tasks/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    load();
  };

  const deleteTask = async (id) => {
    await fetch(`${API}/tasks/${id}`, { method: "DELETE" });
    load();
  };

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark"><Zap size={18} fill="currentColor" /></div>
          <div>
            <strong>TaskForge</strong>
            <span>DevOps Control Plane</span>
          </div>
        </div>

        <nav>
          <div className="nav-label">Workspace</div>
          <button className="nav-item active"><Layers3 size={18}/> Overview</button>
          <button className="nav-item"><Activity size={18}/> Activity</button>
          <button className="nav-item"><Server size={18}/> Infrastructure</button>
        </nav>

        <div className="sidebar-bottom">
          <div className="system-card">
            <div className="system-header">
              <span className={`pulse ${apiHealthy ? "online" : ""}`}></span>
              <span>System status</span>
            </div>
            <strong>{apiHealthy ? "All systems operational" : "API unavailable"}</strong>
            <small>API · PostgreSQL</small>
          </div>
          <div className="version">TaskForge v1.0 · Local environment</div>
        </div>
      </aside>

      <main className="main">
        <header className="topbar">
          <div>
            <div className="eyebrow">WORKSPACE / TASKS</div>
            <h1>Command center</h1>
            <p>Track the work. Ship the infrastructure.</p>
          </div>
          <button className="primary-btn" onClick={() => setShowModal(true)}>
            <Plus size={18}/> New task
          </button>
        </header>

        <section className="metrics">
          <Metric icon={<Layers3 />} label="Total tasks" value={stats.total} />
          <Metric icon={<Clock3 />} label="In progress" value={stats.in_progress} />
          <Metric icon={<CheckCircle2 />} label="Completed" value={stats.done} />
          <div className="metric progress-metric">
            <div className="metric-icon"><Activity /></div>
            <div className="metric-copy"><span>Completion</span><strong>{completion}%</strong></div>
            <div className="progress-track"><div style={{ width: `${completion}%` }} /></div>
          </div>
        </section>

        <section className="toolbar">
          <div className="search">
            <Search size={17}/>
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search tasks..." />
          </div>
          <div className="filters">
            <div className="select-wrap"><Filter size={15}/><select value={status} onChange={e => setStatus(e.target.value)}>
              <option value="all">All statuses</option>
              <option value="todo">To do</option>
              <option value="in-progress">In progress</option>
              <option value="done">Done</option>
            </select></div>
            <div className="select-wrap"><select value={priority} onChange={e => setPriority(e.target.value)}>
              <option value="all">All priorities</option>
              <option value="high">High priority</option>
              <option value="medium">Medium priority</option>
              <option value="low">Low priority</option>
            </select></div>
          </div>
        </section>

        <section className="task-section">
          <div className="section-heading">
            <div><h2>Active workload</h2><span>{tasks.length} task{tasks.length === 1 ? "" : "s"} shown</span></div>
            <span className="live-dot"><i/> LIVE</span>
          </div>

          {loading ? <div className="empty"><div className="spinner"/><p>Loading workload...</p></div> :
            tasks.length === 0 ? <div className="empty"><AlertCircle/><h3>No tasks found</h3><p>Try changing your filters or create a new task.</p></div> :
            <div className="task-grid">
              {tasks.map(task => (
                <TaskCard key={task.id} task={task} onUpdate={updateTask} onDelete={deleteTask}/>
              ))}
            </div>
          }
        </section>

        <footer>
          <span><span className="footer-dot"/> Connected to local API</span>
          <span>Architecture-ready · Docker → Kubernetes → AWS</span>
        </footer>
      </main>

      {showModal && <NewTaskModal onClose={() => setShowModal(false)} onCreate={createTask}/>}
    </div>
  );
}

function Metric({ icon, label, value }) {
  return <div className="metric"><div className="metric-icon">{icon}</div><div className="metric-copy"><span>{label}</span><strong>{value}</strong></div></div>;
}

function TaskCard({ task, onUpdate, onDelete }) {
  const p = priorityMeta[task.priority] || priorityMeta.medium;
  const s = statusMeta[task.status] || statusMeta.todo;

  const cycleStatus = () => {
    const next = task.status === "todo" ? "in-progress" : task.status === "in-progress" ? "done" : "todo";
    onUpdate(task.id, { status: next, due_date: task.due_date });
  };

  return (
    <article className={`task-card ${task.status === "done" ? "completed" : ""}`}>
      <div className="card-top">
        <button className="check-btn" onClick={cycleStatus} title="Change status">
          {task.status === "done" ? <CheckCircle2/> : task.status === "in-progress" ? <Clock3/> : <Circle/>}
        </button>
        <div className="badges"><span className={`status-badge ${s.className}`}>{s.label}</span><span className={`priority ${p.className}`}>{p.label}</span></div>
        <button className="icon-btn delete" onClick={() => onDelete(task.id)}><Trash2 size={16}/></button>
      </div>
      <h3>{task.title}</h3>
      <p>{task.description || "No description provided."}</p>
      <div className="card-bottom">
        <span>{task.due_date ? `Due ${new Date(task.due_date).toLocaleDateString(undefined, {month: "short", day: "numeric"})}` : "No deadline"}</span>
        <span className="task-id">TF-{String(task.id).padStart(4, "0")}</span>
      </div>
    </article>
  );
}

function NewTaskModal({ onClose, onCreate }) {
  const [form, setForm] = useState({ title: "", description: "", priority: "medium", due_date: "" });

  const submit = e => {
    e.preventDefault();
    if (form.title.trim()) onCreate(form);
  };

  return (
    <div className="modal-backdrop" onMouseDown={onClose}>
      <div className="modal" onMouseDown={e => e.stopPropagation()}>
        <div className="modal-head"><div><div className="eyebrow">CREATE / TASK</div><h2>New task</h2></div><button className="icon-btn" onClick={onClose}><X/></button></div>
        <form onSubmit={submit}>
          <label>Title<input autoFocus value={form.title} onChange={e => setForm({...form, title:e.target.value})} placeholder="e.g. Configure EKS ingress"/></label>
          <label>Description<textarea value={form.description} onChange={e => setForm({...form, description:e.target.value})} placeholder="What needs to be done?"/></label>
          <div className="form-row">
            <label>Priority<select value={form.priority} onChange={e => setForm({...form, priority:e.target.value})}><option value="high">High</option><option value="medium">Medium</option><option value="low">Low</option></select></label>
            <label>Due date<input type="date" value={form.due_date} onChange={e => setForm({...form, due_date:e.target.value})}/></label>
          </div>
          <div className="modal-actions"><button type="button" className="secondary-btn" onClick={onClose}>Cancel</button><button className="primary-btn" type="submit"><Plus size={17}/> Create task</button></div>
        </form>
      </div>
    </div>
  );
}

export default App;
