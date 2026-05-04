// The API base URL is resolved through the nginx reverse proxy (same origin).
const API_URL = "/api/tasks";

const form = document.getElementById("task-form");
const taskIdInput = document.getElementById("task-id");
const titleInput = document.getElementById("task-title");
const descInput = document.getElementById("task-description");
const statusSelect = document.getElementById("task-status");
const submitBtn = document.getElementById("submit-btn");
const cancelBtn = document.getElementById("cancel-btn");
const taskList = document.getElementById("task-list");

// ---- Helpers ----

async function fetchTasks() {
  try {
    const res = await fetch(API_URL);
    const tasks = await res.json();
    renderTasks(tasks);
  } catch (err) {
    console.error("Failed to load tasks:", err);
    taskList.innerHTML = '<p class="empty-msg">Failed to load tasks.</p>';
  }
}

function renderTasks(tasks) {
  if (tasks.length === 0) {
    taskList.innerHTML = '<p class="empty-msg">No tasks yet. Add one above!</p>';
    return;
  }

  taskList.innerHTML = tasks
    .map(
      (t) => `
    <div class="task-card" data-id="${t.id}">
      <div class="task-info">
        <h3>${escapeHtml(t.title)}</h3>
        <p>${escapeHtml(t.description)}</p>
        <span class="badge ${t.status}">${formatStatus(t.status)}</span>
      </div>
      <div class="task-actions">
        <button class="btn-edit" onclick="editTask(${t.id}, '${escapeAttr(t.title)}', '${escapeAttr(t.description)}', '${t.status}')">Edit</button>
        <button class="btn-delete" onclick="deleteTask(${t.id})">Delete</button>
      </div>
    </div>`
    )
    .join("");
}

function formatStatus(s) {
  return s.replace("_", " ");
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str || "";
  return div.innerHTML;
}

function escapeAttr(str) {
  return (str || "").replace(/'/g, "\\'").replace(/"/g, "&quot;");
}

// ---- CRUD ----

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  const payload = {
    title: titleInput.value.trim(),
    description: descInput.value.trim(),
    status: statusSelect.value,
  };

  const id = taskIdInput.value;

  try {
    if (id) {
      // Update
      await fetch(`${API_URL}/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
    } else {
      // Create
      await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
    }

    resetForm();
    fetchTasks();
  } catch (err) {
    console.error("Save failed:", err);
  }
});

function editTask(id, title, description, status) {
  taskIdInput.value = id;
  titleInput.value = title;
  descInput.value = description;
  statusSelect.value = status;
  submitBtn.textContent = "Update Task";
  cancelBtn.classList.remove("hidden");
  titleInput.focus();
}

async function deleteTask(id) {
  if (!confirm("Delete this task?")) return;

  try {
    await fetch(`${API_URL}/${id}`, { method: "DELETE" });
    fetchTasks();
  } catch (err) {
    console.error("Delete failed:", err);
  }
}

cancelBtn.addEventListener("click", resetForm);

function resetForm() {
  taskIdInput.value = "";
  titleInput.value = "";
  descInput.value = "";
  statusSelect.value = "pending";
  submitBtn.textContent = "Add Task";
  cancelBtn.classList.add("hidden");
}

// Initial load
fetchTasks();
