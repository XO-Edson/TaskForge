CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  title VARCHAR(160) NOT NULL,
  description TEXT DEFAULT '',
  status VARCHAR(20) NOT NULL DEFAULT 'todo',
  priority VARCHAR(20) NOT NULL DEFAULT 'medium',
  due_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO tasks (title, description, status, priority, due_date)
SELECT 'Build the EKS architecture', 'Provision the AWS foundation with Terraform.', 'in-progress', 'high', CURRENT_DATE + 7
WHERE NOT EXISTS (SELECT 1 FROM tasks);

INSERT INTO tasks (title, description, status, priority)
SELECT 'Create Jenkins pipeline', 'Automate test, build, scan, push and deploy.', 'todo', 'high'
WHERE NOT EXISTS (SELECT 1 FROM tasks WHERE title = 'Create Jenkins pipeline');

INSERT INTO tasks (title, description, status, priority)
SELECT 'Set up Grafana dashboards', 'Monitor Kubernetes and application metrics.', 'todo', 'medium'
WHERE NOT EXISTS (SELECT 1 FROM tasks WHERE title = 'Set up Grafana dashboards');
