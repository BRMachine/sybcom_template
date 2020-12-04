// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author R.Arslanov
  @version 1.0
*/
/**
changelog:
  v.1.0 - R.Arslanov
    1. initial version
  v.1.1 - R.Arslanov
    1. rename functions for operativeData and Orders
  v.1.2 - R.Arslanov
    1. Иземенен формат даты для корректной работы с MS SQL (%Y-%m-%dT%H:%M:%S)
*/
//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "CtrlADO"
#uses "classes/ASN"
//--------------------------------------------------------------------------------
// variables and constants

enum Fuels{
  UNDEF,
  DT = 0, DT_OPTI = 1,
  AI_92 = 2, AI_95 = 3
};

const string STATE_DP;

// public const ASN lib_line_1 = new ASN("ASN_1");
// public const ASN lib_line_2 = new ASN("ASN_2");
// public const ASN lib_line_3 = new ASN("ASN_3");
// public const ASN lib_line_4 = new ASN("ASN_4");



// main() {
//   string searchtext, file, command, path;
//   int return;    file="data.txt";
//   path=PROJ_PATH + "data//ddc_parameter//";
//   getValue("Searchtext", "text", searchtext);    // Команда поиска осуществляет поиск строк в файле, который содержит
  // строку "Searchtext" и записывает выходное значение в файл.
//   command="find /"" + searchtext + "/" " + path + file + " > " + path + "result.txt";    // В отношении расширенной команды (переназначение файла), ее необходимо задавать    // в кавычках.
//   return=system("cmd /c start /MIN cmd /c" + "/"" + command + "/"");
// }

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

/** Строка в enum Fuels
  * @params string inp - Строка источник
  * @return string   - хэшсумма SHA-1 для строки источника
*/
public string getHash(string inp){
  DebugTN("Exec getHash",inp);
  string cmd = "powershell " + PROJ_PATH + "data/getHashsum.ps1" + " \"" + inp + "\"";
  DebugTN(cmd);
  string hash;
  system(cmd, hash);
  DebugTN(hash);
  return "0x" + hash;
}

/** Строка в enum Fuels
  * @params string f - Строка с типом топлива из БД OrderItems
  * @return Fuels - Тип топлива соответствующий строке
*/
public Fuels strToFuels(string f){
  Fuels fuel;
  switch(f){
    case "ДТЛ":       fuel = Fuels::DT;       break;
    case "ДТЛ OPTI":  fuel = Fuels::DT_OPTI;  break;
    case "АИ-95":     fuel = Fuels::AI_95;    break;
    case "АИ-92":     fuel = Fuels::AI_92;    break;
    default :         fuel = Fuels::UNDEF;
  }
  return fuel;
}
/**
 * enum Fuels в строку для корректного отображения в логе
 * @params Fuels f - топливо в формате enum
 * @return string - строка с именем топлива
*/
public string fuelsToStr(Fuels f){
  if     (f == Fuels::DT){ return "ДТЛ"; }
  else if(f == Fuels::DT_OPTI){ return "ДТЛ OPTI"; }
  else if(f == Fuels::AI_92){ return "АИ-92"; }
  else if(f == Fuels::AI_95){ return "АИ-95"; }
}

/**  Получение параметров подключения заданных в точках данных

  @return mapping - Параметры подключения к базе данных в формате
  ------------------------
  | dp | connection | db |
  ------------------------
*/

public dyn_mapping getConnectionParams(){
  dyn_mapping conf;
  dyn_string dps = getDatapointsDB();
  // generate connection_line from all datapoints
  for(int i=1; i<=dynlen(dps); i++){
    bool type;
    string dsn, uid, pwd, t_conf, t_db;
    mapping t_conf;

    dpGet(dps[i] + ".DSN", dsn,
          dps[i] + ".UID", uid,
          dps[i] + ".PWD", pwd,
          dps[i] + ".WIN", type,
          dps[i] + ".DB", t_conf["db"]);

    t_conf["connection"] = "DSN=" + dsn + ";";
    if(!type){
      t_conf["connection"] += "UID=" + uid + ";";
      t_conf["connection"] += "PWD=" + pwd + ";";
    }
    t_conf["dp"] += dps[i];
    dynAppend(conf, t_conf);
  }
  return conf;
}

/** Изменение активного соединения в зависимости от количества точек данных с параметрами подключения
  @param cur - Текущий номер подключения к БД
  @param conf - Параметры подключения (Результат работы функции getConnectionParams()
*/
public void changeActiveConnection(int cur, dyn_mapping conf){
  DebugFTN("db_error", "CHANGE CONNECTION | ", conf);
  if(iConnection < dynlen(conf))
    cur++;
  else
    cur = 1;

  DebugFTN("db_error", "connection changed", "current " + cur);
  dpSetWait("_NB_CONFIG.ST", cur);

}

// not used TODO: delete it
// public void updateDB(mapping unack){
//   if(dynlen(unack["dp"]) == 0){
//     return;
//   }
//   DebugFTN("info", "Unacknowledge variable");
//   dbConnection con;
//
//   string loc_connection = mConfig[iConnection]["connection"];
//   string loc_database = mConfig[iConnection]["db"];
//
//   int res = dbOpenConnection(loc_connection, con);
//   if(!res){
//     DebugFTN("db_verbose", "Database connected Update fct");
//     for(int i = 1; i<=dynlen(unack["dp"]); i++){
//       bit64 sts;
//       bool d,n,f,s, D,E,R;
//       dpGet(unack["dp"][i] + ":_online.._default_bad"  , d,
//             unack["dp"][i] + ":_online.._online_bad"   , n,
//             unack["dp"][i] + ":_online.._offline_bad"  , f,
//             unack["dp"][i] + ":_online.._stime_inv"    , s,
//             unack["dp"][i] + ":_online.._aut_inv"      , D,
//             unack["dp"][i] + ":_online.._invalid"      , E,
//             unack["dp"][i] + ":_online.._bad"          , R);
//       setBit(sts, 0, d);
//       setBit(sts, 1, n);
//       setBit(sts, 2, f);
//       setBit(sts, 3, s);
//       setBit(sts, 4, D);
//       setBit(sts, 8, E);
//       setBit(sts, 9, R);
//
      // prepare update value command
//       dbCommand cmd;
//       string sCommand = "update ["+loc_database+"].[dbo].[OperativeData] ";
//       sCommand += " SET [value] = '" + (string)unack["val"][i] + "', ";
//       sCommand += "[quality] = IIF("+ (long)sts + " > 1, 0, 1) ";
//       sCommand += "where (basename = '" + unack["dp"][i] + "') AND (instanceid not between 1000 and 2000) ";
//
//       DebugFTN("db_verbose", "update value command", sCommand);
//       dbStartCommand(con, sCommand, cmd);
//       dbExecuteCommand(cmd);
//       dyn_errClass err = getLastError();
//       if(dynlen(err)>0){
//         DebugFTN("db_error",err);
//       }else{
//         DebugFTN("info", "success updated row");
//         DebugFTN("info", unack["dp"][i], unack["val"][i]);
//       }
//       dbFinishCommand(cmd);
//
      /// update timestamp now
//       dbCommand cmd;
//       time now = getCurrentTime();
//
//       string s_time = formatTime("%Y-%m-%d %H:%M:%S", now, ".%03d");
//       dyn_string d_time = strsplit(s_time, ".");
//       string sCommand = "update ["+loc_database+"].[dbo].[OperativeData] ";
//       sCommand += "set timestamp = {ts '"+ s_time +"'} ";
//       sCommand += "where (instanceid not between 1000 and 2000) and (instanceid = " + unack["id"][i]+")";
//       DebugFTN("db_verbose", "update timestamp command", sCommand);
//       dbStartCommand(con, sCommand, cmd);
//       dbExecuteCommand(cmd);
//       dyn_errClass err = getLastError();
//       if(dynlen(err)>0){
//         DebugFTN("db_error",err);
//       }else{
//         DebugFTN("info", "success updated row");
//         DebugFTN("info", unack["dp"][i], unack["val"][i]);
//       }
//       dbFinishCommand(cmd);
//       DebugFTN("db_verbose", sCommand);
//       dbStartCommand(con, sCommand, cmd);
//       dbExecuteCommand(cmd);
//       dyn_errClass err = getLastError();
//       if(dynlen(err)>0){
//         DebugFTN("db_error",err);
//       }else{
//         DebugFTN("info", "success updated row");
//         DebugFTN("info", unack["dp"][i], unack["val"][i]);
//       }
//       DebugFTN("db_verbose", "Update row", unack["dp"][i], unack["val"][i]);
//       dbValues[dynContains(datapoints, unack["dp"][i])] = unack["val"][i];
//       dbFinishCommand(cmd);
//     }
//   }else{ // Error connection
//     dyn_errClass err = getLastError();
//     if(dynlen(err)>0){
//       for(int i = 1; i<=dynlen(err); i++){
//         DebugFTN("db_error", err[i]);
//       }
//     }
//     DebugFTN("db_error", "Error query DB_MES_COMMAND", iConnection);
//     changeActiveConnection(iConnection, mConfig);
//     init = true;
//   }
//   dbCloseConnection(con);
// }

// to operative data IS_RVS type
public void updateRVS(mapping unack, time timestamp){
  if(dynlen(unack["dp"]) == 0){
    return;
  }
  DebugFTN("lg_info", "Unacknowledge variable");
  dbConnection con;

  string loc_connection = mConfig[iConnection]["connection"];
  string loc_database = mConfig[iConnection]["db"];
  string rvs_time = formatTime("%Y-%m-%d %H:%M:%S", timestamp, ".%03d");
  DebugFTN("lg_info", loc_connection, loc_database);
  int res = dbOpenConnection(loc_connection, con);
  if(!res){
    DebugFTN("db_verbose", "Database connected Update fct:",(string)dynlen(unack["dp"]));
    for(int i = 1; i<=dynlen(unack["dp"]); i++){
      bit64 sts;
      bool d,n,f,s, D,E,R;
      dpGet(unack["dp"][i] + ":_online.._default_bad"  , d,
            unack["dp"][i] + ":_online.._online_bad"   , n,
            unack["dp"][i] + ":_online.._offline_bad"  , f,
            unack["dp"][i] + ":_online.._stime_inv"    , s,
            unack["dp"][i] + ":_online.._aut_inv"      , D,
            unack["dp"][i] + ":_online.._invalid"      , E,
            unack["dp"][i] + ":_online.._bad"          , R);
      setBit(sts, 0, d);
      setBit(sts, 1, n);
      setBit(sts, 2, f);
      setBit(sts, 3, s);
      setBit(sts, 4, D);
      setBit(sts, 5, E);
      setBit(sts, 6, R);
      if(patternMatch("RVS_*.WTR.val", unack["dp"][i])){
        DebugFTN("lg_info", "WATER value");
        ulong tmp_sts;
        string temp_dp = dpSubStr(unack["dp"][i], DPSUB_DP);
        dpGet(temp_dp + ".WTR.sts", tmp_sts);
        setBit(sts, 8, (bool)tmp_sts);
      }
      // prepare update value command
      dbCommand cmd;
      string sCommand = "update ["+loc_database+"].[dbo].[OperativeData] ";
      sCommand += " SET [value] = '" + (string)unack["val"][i] + "', ";
      sCommand += "[quality] = IIF("+ (long)sts + " > 1, 0, 1) ";
      sCommand += "where  (basename  = '" + unack["dp"][i] + "') ";
      dbStartCommand(con, sCommand, cmd);
      dbExecuteCommand(cmd);
      dyn_errClass err = getLastError();
      if(dynlen(err)>0){
        DebugFTN("db_error",err);
      }else{
        DebugFTN("db_info", "success updated value row");
        DebugFTN("db_info", unack["dp"][i], unack["val"][i]);
      }
      dbFinishCommand(cmd);
    }
     /// update timestamp
      dbCommand cmd;
      time timestamp = getCurrentTime();

      string sCommand = "update ["+loc_database+"].[dbo].[OperativeData] ";
      sCommand += "set [timestamp] = {ts '"+ rvs_time +"'} ";
      sCommand += "where instanceid between 1000 and 2000"; // = " + unack["id"][i];
      DebugFTN("db_verbose", "update timestamp command", sCommand);
      dbStartCommand(con, sCommand, cmd);
      dbExecuteCommand(cmd);
      dyn_errClass err = getLastError();
      if(dynlen(err)>0){
        DebugFTN("db_error",err);
      }else{
        DebugFTN("info", "success updated time row");
      }
      dbFinishCommand(cmd);
  }else{ // Error connection
    dyn_errClass err = getLastError();
    if(dynlen(err)>0){
      for(int i = 1; i<=dynlen(err); i++){
        DebugFTN("db_error", __LINE__,  err[i]);
      }
    }
   // DebugFTN("db_error", "Error query DB_MES_COMMAND", iConnection);
    changeActiveConnection(iConnection, mConfig);
    init = true;
  }
  DebugFTN("db_info", "Connection try closing");
  DebugFTN("db_info", "Result close connection", dbCloseConnection(con));
}

public void updateOrders(mapping data, time timestamp){}
//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

/** Получение точек данных с конфигурациями БД
  @return dyn_string - массив имен точек данных (кроме _NB_CONFIG)
*/

private dyn_string getDatapointsDB(){
  dyn_string res = dpNames("*", "_SYBCOM_DB_CONFIG");
  for(int i=1; i<=dynlen(res); i++){
    res[i] = dpSubStr(res[i], DPSUB_DP);
    if(res[i] == "_NB_CONFIG"){
      dynRemove(res, i);
    }
  }
  return res;
}



