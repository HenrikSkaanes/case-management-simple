import { useState, useEffect } from 'react';
import { QueryClient, QueryClientProvider, useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ticketsApi } from './api';
import './App.css';

const queryClient = new QueryClient();

const STATUSES = [
  { id: 'new', label: 'New', color: '#3b82f6' },
  { id: 'in_progress', label: 'In Progress', color: '#f59e0b' },
  { id: 'resolved', label: 'Resolved', color: '#10b981' },
  { id: 'closed', label: 'Closed', color: '#6b7280' },
];

const PRIORITIES = ['low', 'medium', 'high', 'critical'];
const CATEGORIES = ['income_tax', 'vat', 'deductions', 'general', 'compliance'];

function TicketCard({ ticket, onClick }) {
  const priorityClass = `priority-${ticket.priority}`;
  
  return (
    <div className="ticket-card" onClick={() => onClick(ticket)}>
      <div className="ticket-header">
        <span className="ticket-number">{ticket.ticket_number}</span>
        <span className={`priority-badge ${priorityClass}`}>{ticket.priority}</span>
      </div>
      <h3 className="ticket-title">{ticket.title}</h3>
      {ticket.customer_name && (
        <p className="ticket-customer">👤 {ticket.customer_name}</p>
      )}
      <div className="ticket-meta">
        <span className="category-badge">{ticket.category}</span>
        {ticket.assigned_to && <span>👨‍💼 {ticket.assigned_to}</span>}
      </div>
    </div>
  );
}

function TicketModal({ ticket, onClose, onUpdate, onDelete }) {
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState(ticket || {});

  const handleSubmit = (e) => {
    e.preventDefault();
    onUpdate(formData);
    setIsEditing(false);
  };

  if (!ticket) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2 className="modal-title">
            {ticket.ticket_number} - {ticket.title}
          </h2>
          <button className="close-btn" onClick={onClose}>×</button>
        </div>

        {isEditing ? (
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Title</label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label>Description</label>
              <textarea
                value={formData.description || ''}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label>Status</label>
              <select
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value })}
              >
                {STATUSES.map(s => <option key={s.id} value={s.id}>{s.label}</option>)}
              </select>
            </div>

            <div className="form-group">
              <label>Priority</label>
              <select
                value={formData.priority}
                onChange={(e) => setFormData({ ...formData, priority: e.target.value })}
              >
                {PRIORITIES.map(p => <option key={p} value={p}>{p}</option>)}
              </select>
            </div>

            <div className="form-group">
              <label>Assigned To</label>
              <input
                type="text"
                value={formData.assigned_to || ''}
                onChange={(e) => setFormData({ ...formData, assigned_to: e.target.value })}
              />
            </div>

            <div className="form-actions">
              <button type="button" className="btn btn-secondary" onClick={() => setIsEditing(false)}>
                Cancel
              </button>
              <button type="submit" className="btn btn-primary">
                Save Changes
              </button>
            </div>
          </form>
        ) : (
          <>
            <div style={{ marginBottom: '1.5rem' }}>
              <p><strong>Description:</strong> {ticket.description || 'No description'}</p>
              <p><strong>Status:</strong> {ticket.status}</p>
              <p><strong>Priority:</strong> {ticket.priority}</p>
              <p><strong>Category:</strong> {ticket.category}</p>
              {ticket.customer_name && <p><strong>Customer:</strong> {ticket.customer_name}</p>}
              {ticket.customer_email && <p><strong>Email:</strong> {ticket.customer_email}</p>}
              {ticket.assigned_to && <p><strong>Assigned To:</strong> {ticket.assigned_to}</p>}
              <p><strong>Created:</strong> {new Date(ticket.created_at).toLocaleString()}</p>
            </div>

            <div className="form-actions">
              <button className="btn btn-danger" onClick={() => onDelete(ticket.id)}>
                Delete
              </button>
              <button className="btn btn-primary" onClick={() => setIsEditing(true)}>
                Edit
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

function CreateTicketModal({ onClose, onCreate }) {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: 'general',
    priority: 'medium',
    customer_name: '',
    customer_email: '',
    customer_phone: '',
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    onCreate(formData);
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2 className="modal-title">Create New Ticket</h2>
          <button className="close-btn" onClick={onClose}>×</button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Title *</label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label>Description</label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label>Category *</label>
            <select
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
            >
              {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>

          <div className="form-group">
            <label>Priority</label>
            <select
              value={formData.priority}
              onChange={(e) => setFormData({ ...formData, priority: e.target.value })}
            >
              {PRIORITIES.map(p => <option key={p} value={p}>{p}</option>)}
            </select>
          </div>

          <div className="form-group">
            <label>Customer Name</label>
            <input
              type="text"
              value={formData.customer_name}
              onChange={(e) => setFormData({ ...formData, customer_name: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label>Customer Email</label>
            <input
              type="email"
              value={formData.customer_email}
              onChange={(e) => setFormData({ ...formData, customer_email: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label>Customer Phone</label>
            <input
              type="tel"
              value={formData.customer_phone}
              onChange={(e) => setFormData({ ...formData, customer_phone: e.target.value })}
            />
          </div>

          <div className="form-actions">
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              Create Ticket
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function KanbanBoard() {
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const queryClient = useQueryClient();

  const { data: tickets = [], isLoading, error } = useQuery({
    queryKey: ['tickets'],
    queryFn: async () => {
      const response = await ticketsApi.getAll();
      return response.data;
    },
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  const createMutation = useMutation({
    mutationFn: (data) => ticketsApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries(['tickets']);
      setShowCreateModal(false);
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => ticketsApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['tickets']);
      setSelectedTicket(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => ticketsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries(['tickets']);
      setSelectedTicket(null);
    },
  });

  if (isLoading) return <div className="loading">Loading tickets...</div>;
  if (error) return <div className="error">Error loading tickets: {error.message}</div>;

  const ticketsByStatus = STATUSES.reduce((acc, status) => {
    acc[status.id] = tickets.filter(t => t.status === status.id);
    return acc;
  }, {});

  return (
    <>
      <div className="kanban-board">
        {STATUSES.map(status => (
          <div key={status.id} className="kanban-column">
            <div className="column-header">
              <h2 className="column-title">{status.label}</h2>
              <span className="ticket-count">{ticketsByStatus[status.id]?.length || 0}</span>
            </div>
            <div className="column-content">
              {ticketsByStatus[status.id]?.map(ticket => (
                <TicketCard
                  key={ticket.id}
                  ticket={ticket}
                  onClick={setSelectedTicket}
                />
              ))}
            </div>
          </div>
        ))}
      </div>

      <button className="add-ticket-btn" onClick={() => setShowCreateModal(true)}>
        +
      </button>

      {selectedTicket && (
        <TicketModal
          ticket={selectedTicket}
          onClose={() => setSelectedTicket(null)}
          onUpdate={(data) => updateMutation.mutate({ id: selectedTicket.id, data })}
          onDelete={(id) => deleteMutation.mutate(id)}
        />
      )}

      {showCreateModal && (
        <CreateTicketModal
          onClose={() => setShowCreateModal(false)}
          onCreate={(data) => createMutation.mutate(data)}
        />
      )}
    </>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <div className="app-container">
        <header className="app-header">
          <h1>📋 Case Management System</h1>
          <p>Wrangler Tax Services</p>
        </header>
        <KanbanBoard />
      </div>
    </QueryClientProvider>
  );
}

export default App;
