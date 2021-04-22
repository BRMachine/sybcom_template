// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author R.Arslanov
  @version 1.2
*/
/** changelog
	v. 1.1 ============
		1. Добавлена возможность использования массива значений подтверждающих команду
		2. Добавлены комментарии к коду
	v. 1.2 ============
		1. Добавлена поддержка нескольких баз данных

*/

/*
   0 - Новая команда
   1 - Команда в очереди ССПД
   2 - Команда выполнена
  -1 - Неизвестное значение команды
  -2 - Неизвестный тэг
  -3 - Таймаут
*/
//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "CtrlADO"
#uses "lib_asup"

//--------------------------------------------------------------------------------
// variables and constants
int g_iteration;
mapping c_command;

dyn_mapping mConfig;
int iConnection = 1;
 string dp_srv_act = "_ReduManager.EvStatus";      // Для основного сервера

//--------------------------------------------------------------------------------
/**
*/
// Запись состояния выполнения команды
void updateDB(int sts){
  dbConnection con;
  dbCommand cmd;
  int res;

  string loc_connection = mConfig[iConnection]["connection"];
  string loc_database = mConfig[iConnection]["db"];
  res = dbOpenConnection(loc_connection, con);
  if(!res){
    mapping local_command;
	// Получение текущей команды из очереди
    dpGet("CURRENT_COMMAND.id"   , local_command["id"],
          "CURRENT_COMMAND.tag"  , local_command["tag"],
          "CURRENT_COMMAND.val"  , local_command["val"],
         // "CURRENT_COMMAND.argv" , local_command["argv"],
          "CURRENT_COMMAND.ts"   , local_command["ts"],
          "CURRENT_COMMAND.state", local_command["state"],
          "CURRENT_COMMAND.c_tag", local_command["c_tag"],
          "CURRENT_COMMAND.c_val", local_command["c_val"],
          "CURRENT_COMMAND.t_out", local_command["t_out"]);
	// Сборка SQL запроса к базе данных
      string query = "UPDATE ["+loc_database+"].[dbo].[MesCommand] ";	 // БД
      query += "SET State = " + sts + ", ";							               // Статус выполнения
      query += "Timestamp = SYSDATETIME() ";						               // Текущее время
      query += "WHERE ID = " + local_command["id"][1] + " ";		       // Фильтрация по ID команды в БД
	  // Выполнение SQL команды
      dbStartCommand(con, query, cmd);
      dbExecuteCommand(cmd);
	  // Обработка ошибок
      dyn_errClass err = getLastError();
	  if(dynlen(err) != 0){
		  //DebugFTN("error", err);
		  //DebugFTN("error", query);
		  DebugN("error", err);
		  DebugN("error", query);
	  }
	  // Закрытие соединиения с БД
      dbFinishCommand(cmd);
      dbCloseConnection(con);
      removeUpCommand();
    }else{
      DebugN("Error connection WC_MES_COMMAND", iConnection);
      changeActiveConnection(iConnection, mConfig);
    }

}
//
void removeUpCommand(){
  mapping local_command;
// Получение очереди команд
  dpGet("CURRENT_COMMAND.id"   , local_command["id"],
        "CURRENT_COMMAND.tag"  , local_command["tag"],
        "CURRENT_COMMAND.val"  , local_command["val"],
       // "CURRENT_COMMAND.argv" , local_command["argv"],
        "CURRENT_COMMAND.ts"   , local_command["ts"],
        "CURRENT_COMMAND.state", local_command["state"],
        "CURRENT_COMMAND.c_tag", local_command["c_tag"],
        "CURRENT_COMMAND.c_val", local_command["c_val"],
        "CURRENT_COMMAND.t_out", local_command["t_out"]);
// Удаление первого элемента из всех массивов
  dynRemove(local_command["id"], 1);
  dynRemove(local_command["tag"], 1);
  dynRemove(local_command["val"], 1);
  //dynRemove(local_command["argv"], 1);
  dynRemove(local_command["ts"], 1);
  dynRemove(local_command["state"], 1);
  dynRemove(local_command["c_tag"], 1);
  dynRemove(local_command["c_val"], 1);
  dynRemove(local_command["t_out"], 1);
// Запись очереди команд без первого элемента
  dpSetWait("CURRENT_COMMAND.id"   , local_command["id"],
            "CURRENT_COMMAND.tag"  , local_command["tag"],
            "CURRENT_COMMAND.val"  , local_command["val"],
           // "CURRENT_COMMAND.argv" , local_command["argv"],
            "CURRENT_COMMAND.ts"   , local_command["ts"],
            "CURRENT_COMMAND.state", local_command["state"],
            "CURRENT_COMMAND.c_tag", local_command["c_tag"],
            "CURRENT_COMMAND.c_val", local_command["c_val"],
            "CURRENT_COMMAND.t_out", local_command["t_out"]);

}
// Обработка очереди команд,
// Запускается раз в секунду по триггеру
void worker(string dp, bool trg){
  bool act;
  dpGet(dp_srv_act, act);
  if(act) {
  // Получение очереди команд
    dpGet("CURRENT_COMMAND.id"   , c_command["id"],
          "CURRENT_COMMAND.tag"  , c_command["tag"],
          "CURRENT_COMMAND.val"  , c_command["val"],
         // "CURRENT_COMMAND.argv" , c_command["argv"],
          "CURRENT_COMMAND.ts"   , c_command["ts"],
          "CURRENT_COMMAND.state", c_command["state"],
          "CURRENT_COMMAND.c_tag", c_command["c_tag"],
          "CURRENT_COMMAND.c_val", c_command["c_val"],
          "CURRENT_COMMAND.t_out", c_command["t_out"]);
  // Если в очереди есть команды
    if(dynlen(c_command["tag"]) && g_iteration < c_command["t_out"][1]){
      // Если команда выполняется первый раз
      if(g_iteration == 0){
        //Проверяем имя в TagName и переделываем на свое
        switch(c_command["tag"][1]){
          case "Line01/L01.cmdAcceprtOrder":
            c_command["tag"][1] = "ORDER_LINE1.getOrder";
            break;
          case "Line02/L02.cmdAcceprtOrder":
            c_command["tag"][1] = "ORDER_LINE2.getOrder";
            break;
          case "Line03/L03.cmdAcceprtOrder":
            c_command["tag"][1] = "ORDER_LINE3.getOrder";
            break;
        }
        //Проверяем имя в ControlTagName и переделываем на свое
        switch(c_command["c_tag"][1]){
          case "Line01/L01.AcceprtOrder":
            c_command["c_tag"][1] = "ORDER_LINE1.getOrder";
            break;
          case "Line02/L02.AcceprtOrder":
            c_command["c_tag"][1] = "ORDER_LINE2.getOrder";
            break;
          case "Line03/L03.AcceprtOrder":
            c_command["c_tag"][1] = "ORDER_LINE3.getOrder";
            break;
        }
        // Запись команды в точку данных из столбца TagName
        // Если запись в точку данных завершилась с ошибкой
        if(dpSetWait(c_command["tag"][1], c_command["val"][1]) == -1){
          updateDB(-2);      // Записываем в БД статус -2 (Точка данных не существует)
          g_iteration = 0;   // Обнуляем счетчик итераций
          return ;
        }
      }
      anytype c_value;
      dpGet(c_command["c_tag"][1], c_value);
      dyn_anytype d_args = stringToDynString(c_command["c_val"][1], "|");
      mapping control_vals;
      for(int i=1; i<=dynlen(d_args); i++){
        dyn_string d_tmp = stringToDynString(d_args[i], "=");
        control_vals[d_tmp[1]] = stringToDynString(d_tmp[2], ",");
      }
      if(!mappingHasKey(control_vals, c_command["val"][1])){
        updateDB(-1);
        g_iteration = 0;
        return;
      }
      if(!dynContains(control_vals[c_command["val"][1]], c_value)){
        g_iteration++;
      }else{
        updateDB(2);
        g_iteration = 0;
      }
    }else if(!dynlen(c_command["id"])){
    }else{
        updateDB(-3);
        g_iteration = 0;
    }
  }else{
    DebugFTN("lg_info", "This project NoActive(main)");
  }
}

void cbDatabase(string dp, int db){
  iConnection = db;
}

//--------------------------------------------------------------------------------
/**
*/
main(string p1){
  if(p1 == "-RES"){
    dp_srv_act = "_ReduManager_2.EvStatus";
  }
  mConfig = getConnectionParams();
  dpConnect("cbDatabase", "_NB_CONFIG.ST");
  dpConnect("worker", "Sybcom.Triggers.1s_Trigger");
}
