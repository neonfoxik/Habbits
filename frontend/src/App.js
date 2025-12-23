// App.js
import React, { useState, useEffect } from 'react';
import './App.css';
import { habitsAPI, datesAPI, usersAPI } from './api';

const App = () => {
  const [selectedDate, setSelectedDate] = useState(null);
  const [activeButtons, setActiveButtons] = useState({});
  const [habits, setHabits] = useState([]);
  const [dates, setDates] = useState([]);
  const [currentUser, setCurrentUser] = useState(null);
  const [loading, setLoading] = useState(true);

  
  // Данные календаря
  const calendarData = {
    month: "30 июня-июля 2025г.",
    days: [
      { day: "Пн", value: "Душа" },
      { day: "Вт", value: "Личное" },
      { day: "Ср", value: "Работа" },
      { day: "Чт", value: "" },
      { day: "Пт", value: "50 Вчера" },
      { day: "Сб", value: "" },
      { day: "Вс", value: "35 Сегодня" }
    ]
  };

  // Загрузка данных при монтировании компонента
  useEffect(() => {
    const loadData = async () => {
      try {
        // Создаем или получаем пользователя по умолчанию
        let users = await usersAPI.getUsers();
        let user;

        if (users.data.length === 0) {
          // Создаем пользователя по умолчанию
          user = await usersAPI.createUser({
            name: 'Default User',
            age: '25',
            slug: 'default-user'
          });
          setCurrentUser(user.data);
        } else {
          user = users.data[0];
          setCurrentUser(user);
        }

        // Загружаем привычки пользователя
        const habitsResponse = await habitsAPI.getHabits();
        const userHabits = habitsResponse.data.filter(habit => habit.user === user.id);
        setHabits(userHabits);

        // Загружаем даты
        const datesResponse = await datesAPI.getDates();
        const userDates = datesResponse.data.filter(date => date.user === user.id);
        setDates(userDates);

      } catch (error) {
        console.error('Error loading data:', error);
        // Fallback to default habits if API fails
        setHabits([
          { id: 1, name: "Пост", slug: "post" },
          { id: 2, name: "Техеджут", slug: "techedjut" },
          { id: 3, name: "КК", slug: "kk" },
          { id: 4, name: "Джевшен", slug: "djevshen" },
          { id: 5, name: "Тарсир", slug: "tarsir" },
          { id: 6, name: "Гимнастика/холодный душ/прогулка", slug: "gymnastics" },
          { id: 7, name: "Настрой на благополучный день", slug: "mood" }
        ]);
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, []);
  const bar_menu = [

  ];

  // Дополнительные задачи
  const additionalTasks = [
    "Журналы",
    "Графики", 
    "Смелки",
    "Испоминания",
    "Настройка"
  ];

  // Функция для переключения состояния кнопки
  const toggleButton = async (habitIndex, buttonIndex) => {
    if (!currentUser || !habits[habitIndex]) return;

    const habit = habits[habitIndex];
    const today = new Date().toISOString().split('T')[0];
    const key = `${habitIndex}-${buttonIndex}`;

    try {
      // Проверяем, есть ли уже запись для этой привычки на сегодня
      const existingDate = dates.find(date =>
        date.habit === habit.id &&
        date.habit_date === today &&
        date.name === `day-${buttonIndex}`
      );

      if (existingDate) {
        // Обновляем существующую запись
        await datesAPI.updateDate(existingDate.id, {
          ...existingDate,
          is_done: !existingDate.is_done
        });

        setDates(prev => prev.map(date =>
          date.id === existingDate.id
            ? { ...date, is_done: !date.is_done }
            : date
        ));
      } else {
        // Создаем новую запись
        const dateData = {
          user: currentUser.id,
          habit: habit.id,
          habit_date: today,
          name: `day-${buttonIndex}`,
          is_done: true,
          slug: `${habit.slug}-${today}-${buttonIndex}`
        };

        const response = await datesAPI.createDate(dateData);
        setDates(prev => [...prev, response.data]);
      }

      // Обновляем локальное состояние кнопок
      setActiveButtons(prev => ({
        ...prev,
        [key]: !prev[key]
      }));

    } catch (error) {
      console.error('Error toggling habit:', error);
    }
  };

  return (
    <div className="app">
      <div className="container">
        {/* Заголовок месяца */}
        <div className="month-header">
          <h2>{calendarData.month}</h2>
          <progress value={selectedDate} max="30">Задача выполнена на 80%</progress>
        </div>

        {/* Календарь */}
        <div className="calendar">
          <table className="calendar-table">
            <thead>
              <tr>
                {calendarData.days.map((day, index) => (
                  <th key={index}>{day.day}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              <tr>
                {calendarData.days.map((day, index) => (
                  <td 
                    key={index}
                    className={`calendar-cell ${day.value ? 'has-content' : ''}`}
                    onClick={() => setSelectedDate(day)}
                  >
                    {day.value && (
                      <div className="day-content">
                        {day.value}
                      </div>
                    )}
                  </td>
                ))}
              </tr>
            </tbody>
          </table>
        </div>

        {/* Основные привычки */}
        <div className="habits-section">
          <h3>Ежедневные привычки</h3>
          {loading ? (
            <p>Загрузка привычек...</p>
          ) : (
            <div className="habits-list">
              {habits.map((habit, habitIndex) => (
                <div key={habit.id || habitIndex} className="habit-item">
                  <p>
                    <label>{habit.name}</label><br />
                    {[0, 1, 2, 3, 4, 5, 6].map((buttonIndex) => {
                      const today = new Date().toISOString().split('T')[0];
                      const dateRecord = dates.find(date =>
                        date.habit === habit.id &&
                        date.habit_date === today &&
                        date.name === `day-${buttonIndex}`
                      );
                      const isActive = dateRecord ? dateRecord.is_done : false;

                      return (
                        <button
                          key={buttonIndex}
                          className={isActive ? 'active' : ''}
                          onClick={() => toggleButton(habitIndex, buttonIndex)}
                        >
                          ⠀⠀⠀⠀
                        </button>
                      );
                    })}
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>


        {/* Число 13 (как на изображении) */}
        <div className="number-13">
          13
        </div>

        {/* Модальное окно для выбранной даты */}
        <div class="image-menu">
            <img class="image-menu" src="/images/jurnaly.jpg" width = "100" height = "100" alt="Журнал" on/>
            <img class="image-menu" src="/images/grafiki.jpg" width = "100" height = "100" alt="Графики!" />
            <img class="image-menu" src="/images/setting.jpg" width = "100" height = "100" alt="Настройки" />
        </div>


        {/* Дополнительные задачи */}
        <div className="additional-tasks">
          <div className="tasks-grid">
            {additionalTasks.map((task, index) => (
              <div key={index} className="task-item">
                {task}
              </div>
            ))}
          </div>
        </div>

        {/* Число 13 (как на изображении) */}
        <div className="number-13">
          13
        </div>

        {/* Модальное окно для выбранной даты */}
        {selectedDate && selectedDate.value && (
          <div className="modal-overlay" onClick={() => setSelectedDate(null)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <h3>Детали дня</h3>
              <p><strong>{selectedDate.day}:</strong> {selectedDate.value}</p>
              <button onClick={() => setSelectedDate(null)}>Закрыть</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default App;