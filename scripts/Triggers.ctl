/*
    Скрипт для формирования временных триггеров
    Перед включением скрипта проверить значения переменных
    Sybcom.Values.StartShift | Sybcom.Values.EndShift

    Значение данной внутренней dp _Event.Heartbeat меняюся
    каждую секунду, по изменению её значения
    текущее системное время расскладывается на переменные и
    хранится во внутренных dp - Sybcom.Values.
    По изменению времени меняют свое значение триггеры.
    Триггеры хранятся во внутренних dp Sybcom.Triggers.
*/

string System = getSystemName();

main (string p1)
{
  if(p1 != "-RES")
    dpConnect("updateTrigger", System + "_Event.Heartbeat");  // Для основной системы
  else
    dpConnect("updateTrigger", System + "_Event_2.Heartbeat"); // Для резервной системы
}

void updateTrigger (string dpeName, int dpeValue)
{
  string printStr;

  time   currentTime;

  bool   tempTrigger,
         changeTrigger,
         change = FALSE;

  int    tempSecond,
         tempMinute,
         tempHour,
         startShift,
         endShift;

// Получаем текущее системное время и раскладываем его не переменные
  currentTime = getCurrentTime();
  dpSet(System + "Sybcom.Values.Second",  second(currentTime),
        System + "Sybcom.Values.Minute",  minute(currentTime),
        System + "Sybcom.Values.Hour",    hour(currentTime),

        System + "Sybcom.Values.Day",     day(currentTime),
        System + "Sybcom.Values.Month",   month(currentTime),
        System + "Sybcom.Values.Year",    year(currentTime));

// Формирование секундного триггера
  dpGet(System + "Sybcom.Triggers.1s_Trigger",  tempTrigger);
  dpSet(System + "Sybcom.Triggers.1s_Trigger", !tempTrigger);

  dpGet(System + "Sybcom.Values.Second",  tempSecond);

// Формирование 5ти секундного триггера
  if ((tempSecond % 5) == 0)
  {
    dpGet(System + "Sybcom.Triggers.5s_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.5s_Trigger", !tempTrigger);
  }

// Формирование 10ти секундного триггера
  if ((tempSecond % 10) == 0)
  {
    dpGet(System + "Sybcom.Triggers.10s_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.10s_Trigger", !tempTrigger);
  }

// Формирование 30ти секундного триггера
  if ((tempSecond % 30) == 0)
  {
    dpGet(System + "Sybcom.Triggers.30s_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.30s_Trigger", !tempTrigger);
  }

// Формирование минутного триггера
  if ((tempSecond % 60) == 0)
  {
    dpGet(System + "Sybcom.Triggers.1min_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.1min_Trigger", !tempTrigger);
  }


// Получаем текущее значение минут и пересчитываем в количество секунд
  dpGet(System + "Sybcom.Values.Minute",  tempMinute);
  tempMinute = tempMinute * 60 + tempSecond;

// Формирование 5ти минутного триггера
  if ((tempMinute % 300) == 0)
  {
    dpGet(System + "Sybcom.Triggers.5min_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.5min_Trigger", !tempTrigger);
  }

// Формирование 10ти минутного триггера
  if ((tempMinute % 600) == 0)
  {
    dpGet(System + "Sybcom.Triggers.10min_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.10min_Trigger", !tempTrigger);
  }

// Формирование 30ти минутного триггера
  if ((tempMinute % 1800) == 0)
  {
    dpGet(System + "Sybcom.Triggers.30min_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.30min_Trigger", !tempTrigger);
  }

// Формирование часового триггера
  if ((tempMinute % 3600) == 0)
  {
    dpGet(System + "Sybcom.Triggers.1h_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.1h_Trigger", !tempTrigger);
  }


// Получаем текущее значение часов и пересчитываем в количество секунд
  dpGet(System + "Sybcom.Values.Hour",  tempHour);
  tempHour = tempHour * 3600 + tempMinute;

// Формирование 2х часового триггера
  if ((tempHour % 7200) == 0)
  {
    dpGet(System + "Sybcom.Triggers.2h_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.2h_Trigger", !tempTrigger);
  }

// Формирование 12ти часового триггера
  if ((tempHour % 43200) == 0)
  {
    dpGet(System + "Sybcom.Triggers.12h_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.12h_Trigger", !tempTrigger);
  }

// Формирование 24х часового триггера
  if ((tempHour % 86400) == 0)
  {
    dpGet(System + "Sybcom.Triggers.24h_Trigger",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.24h_Trigger", !tempTrigger);
  }

// Получаем время начала смены и пересчитываем в количество секунд
  dpGet(System + "Sybcom.Values.StartShift", startShift);
  startShift = startShift * 3600;

// Формирование триггера смены,
// плюс дополнительно формируется триггер 2х смен (суточный)
  changeTrigger = FALSE;
  if ((tempHour == 0) && (startShift == 0))
    changeTrigger = TRUE;
  else
    if (startShift != 0)
      if (((float)tempHour / (float)startShift) == 1.0)
        changeTrigger = TRUE;

  if (changeTrigger)
  {
    changeTrigger = FALSE;
    dpGet(System + "Sybcom.Triggers.Shift",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.Shift", !tempTrigger);

    dpGet(System + "Sybcom.Triggers.Two_Shifts",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.Two_Shifts", !tempTrigger);
  }

// Получаем время окончания смены и пересчитываем в количество секунд
  dpGet(System + "Sybcom.Values.EndShift", endShift);
  endShift = endShift * 3600;

// Формирование триггера смены
  changeTrigger = FALSE;
  if ((tempHour == 0) && (endShift == 0))
    changeTrigger = TRUE;
  else
    if (endShift != 0)
      if (((float)tempHour / (float)endShift) == 1.0)
        changeTrigger = TRUE;

  if (changeTrigger)
  {
    changeTrigger = FALSE;
    dpGet(System + "Sybcom.Triggers.Shift",  tempTrigger);
    dpSet(System + "Sybcom.Triggers.Shift", !tempTrigger);
  }
}
