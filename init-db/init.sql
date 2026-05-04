-- init-db/init.sql
-- Task Manager Database Schema

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    priority VARCHAR(50) DEFAULT 'medium',
    due_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for better query performance
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);

-- Insert sample data
INSERT INTO tasks (title, description, status, priority, due_date) VALUES
('Welcome to Task Manager', 'Get started with managing your tasks efficiently', 'pending', 'high', CURRENT_TIMESTAMP + INTERVAL '7 days'),
('Explore the Dashboard', 'Check out all the features available', 'in-progress', 'medium', CURRENT_TIMESTAMP + INTERVAL '3 days'),
('Create Your First Task', 'Use the form to add a new task', 'pending', 'low', CURRENT_TIMESTAMP + INTERVAL '1 day'),
('Review Completed Tasks', 'Mark tasks as done when finished', 'completed', 'medium', CURRENT_TIMESTAMP - INTERVAL '1 day');

-- Create function to automatically update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
CREATE TRIGGER update_tasks_updated_at 
    BEFORE UPDATE ON tasks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();