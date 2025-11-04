import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Tickets API
export const ticketsApi = {
  getAll: (params = {}) => api.get('/tickets/', { params }),
  getById: (id) => api.get(`/tickets/${id}`),
  create: (data) => api.post('/tickets/', data),
  update: (id, data) => api.put(`/tickets/${id}`, data),
  delete: (id) => api.delete(`/tickets/${id}`),
  respond: (id, data) => api.post(`/tickets/${id}/respond`, data),
  getResponses: (id) => api.get(`/tickets/${id}/responses`),
};

export default api;
