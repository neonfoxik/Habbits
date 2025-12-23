import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// API endpoints
export const habitsAPI = {
  // Получить все привычки
  getHabits: () => api.get('/v1/habits/'),

  // Создать привычку
  createHabit: (habitData) => api.post('/v1/habits/', habitData),

  // Получить привычку по ID
  getHabit: (id) => api.get(`/v1/habits/${id}/`),

  // Обновить привычку
  updateHabit: (id, habitData) => api.put(`/v1/habits/${id}/`, habitData),

  // Удалить привычку
  deleteHabit: (id) => api.delete(`/v1/habits/${id}/`),
};

export const datesAPI = {
  // Получить все даты
  getDates: () => api.get('/v1/dates/'),

  // Создать дату
  createDate: (dateData) => api.post('/v1/dates/', dateData),

  // Получить дату по ID
  getDate: (id) => api.get(`/v1/date/${id}/`),

  // Обновить дату
  updateDate: (id, dateData) => api.put(`/v1/date/${id}/`, dateData),

  // Удалить дату
  deleteDate: (id) => api.delete(`/v1/date/${id}/`),
};

export const usersAPI = {
  // Получить всех пользователей
  getUsers: () => api.get('/v1/userall/'),

  // Создать пользователя
  createUser: (userData) => api.post('/v1/userall/', userData),

  // Получить пользователя по ID
  getUser: (id) => api.get(`/v1/user/${id}/`),

  // Обновить пользователя
  updateUser: (id, userData) => api.put(`/v1/user/${id}/`, userData),

  // Удалить пользователя
  deleteUser: (id) => api.delete(`/v1/user/${id}/`),
};

export default api;
