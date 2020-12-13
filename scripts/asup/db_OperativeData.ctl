// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file db_OperativeData.ctl
  @copyright $copyright
  @author Admin_tobSSPD
*/
/**
changelog:
  v.1.0 - R.Arslanov
    1. initial version
  v.1.1 - R.Arslanov
    1. В обработку добавлен резервный сервер БД АСУП
    2. static функции вынесены в библиотеку
  v.1.2 - V.Bakutov
    1. Не используется процедура на стороне MS SQL
    2. Добавлено групповое обновление метки времени по instanceid
  v.1.3 - R.Arslanov
    1. Добавлена обработка уровня подтоварной воды
  v.1.4 - V.Bakutov
    1. Добавлено условие для резервирование серверов
*/
//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "CtrlADO"
#uses "lib_asup"
//--------------------------------------------------------------------------------
// variables and constants
dyn_anytype previous;
bool init = true;

int iConnection = 1;
dyn_mapping mConfig;

dyn_string dbIds;
dyn_string dbValues;
dyn_string wcValues;
dyn_string datapoints;
string sConnection, sDatabase;


//  string dp_srv_act = "_ReduManager.EvStatus";      // Для основного сервера
string dp_srv_act = "_ReduManager_2.EvStatus"; // Для резервного сервера
//--------------------------------------------------------------------------------
// predefined functions
//
// void initialValue(){
//   dynClear(dbIds);
//   dynClear(dbValues);
//   dynClear(wcValues);
//   dynClear(datapoints);
//
//   dbConnection con;
//   dbRecordset rs;
//
//   string loc_connection = mConfig[iConnection]["connection"];
//   string loc_database = mConfig[iConnection]["db"];
//
//   int res = dbOpenConnection(loc_connection, con);
//   DebugFTN("info", "Initial started");
//   if(!res){
//     DebugFTN("db_verbose", "Database connected Init fct");
//     string query = "SELECT [basename], [value], [instanceid] ";
//     query += "FROM ["+loc_database+"].[dbo].[OperativeData] ";
//     query += "WHERE [basename] != ''";// AND [basename] NOT LIKE 'RVS_%'";
//     DebugFTN( query);
//     res = dbOpenRecordset(con, query, rs);
//     DebugFTN("db_verbose", "Query executed");
//     if(!res){
//       while(!res && !dbEOF(rs)){
//         anytype id, datapoint, value;
//         res = dbGetField(rs, 0, datapoint);
//         res = dbGetField(rs, 1, value);
//         res = dbGetField(rs, 2, id);
//         DebugFTN("lg_verbose", datapoint, value);
//         dynAppend(datapoints, datapoint);
//         dynAppend(dbValues, strtoupper(value));
//         dynAppend(dbIds, id);
//
//         res = dbMoveNext(rs);
//       }
//       dbCloseRecordset(rs);
//       DebugFTN("info", "Initial success finished");
      //****************** Одноразово **********************//
      //            dpSetWait(datapoints, dbValues);
      //****************** Одноразово **********************//
//       init = false;
//     }else{ // Error Query
//       dyn_errClass err = getLastError();
//       if(dynlen(err)>0){
//         for(int i = 1; i<=dynlen(err); i++){
//           DebugFTN("db_error", err[i]);
//         }
//       }
//     }
//     dbCloseConnection(con);
//   }else{  // Error connection
//     dyn_errClass err = getLastError();
//     if(dynlen(err)>0){
//       for(int i = 1; i<=dynlen(err); i++){
//         DebugFTN("db_error", err[i]);
//       }
//     }
//     changeActiveConnection(iConnection, mConfig);
//     init = true;
//   }
// }

// void refreshData(string dp, bool trg){
//   DebugFTN("lg_verbose", "INIT", init);
//   if(init){
//     initialValue();
//   }else{
//     mapping unack;
//     DebugFTN("lg_verbose", "Exec refresh data");
//     if(dynlen(datapoints) == 0)
//       return;
//     dpGet(datapoints, wcValues);
//     dyn_errClass dp_err = getLastError();
//     for (int i = 1; i<=dynlen(dp_err); i++){
//       DebugFTN("lg_error", dp_err[i]);
//     }
//     DebugFTN("lg_verbose", "WCC Values | dbValues");
//     DebugFTN("lg_verbose", dynlen(wcValues), dynlen(dbValues));
//     if(dynlen(dbValues) == dynlen(wcValues)){
//       unack["dp"]  = makeDynString();
//       unack["val"] = makeDynString();
//       unack["id"] = makeDynString();
//       DebugFTN("lg_verbose", "Equal lenght");
//       for(int i=1; i<=dynlen(wcValues); i++){
//         if(dbValues[i] != wcValues[i]){
//           dynAppend(unack["dp"], datapoints[i]);
//           dynAppend(unack["val"], wcValues[i]);
//           dynAppend(unack["id"], dbIds[i]);
//         }
//       }
//       updateDB(unack);
//       DebugFTN("lg_verbose", "Unacknowledge data", unack);
//     }else{
//       DebugFTN("lg_error", "NOT Equal lenght");
//     }
//   }
// }


void cbDatabase(string dp, int db){
  DebugFTN("db_info", "callback dbChanged");
  iConnection = db;
}

void refreshRVS(string dp, bool trg){
  bool temp_srv;
  dpGet(dp_srv_act, temp_srv);
  if (temp_srv){           //если сервер активный
    dbConnection con;
    dbRecordset rs;
    dyn_string rvs_dps, rvs_vals, rvs_ids;
    mapping unack_rvs;
    string loc_connection = mConfig[iConnection]["connection"];
    string loc_database = mConfig[iConnection]["db"];
    time starttime;

    starttime = getCurrentTime();
    DebugFTN("lg_info", "REFRESH RVS STARTED AT:", starttime);
    int res = dbOpenConnection(loc_connection, con);
    dyn_errClass t_err = getLastError();
    DebugFTN("db_error", t_err);
    DebugFTN("info", "Initial started", res);
    if(!res){
      DebugFTN("db_info", "Database connected Init fct");
      string query = "SELECT [basename] ";
      query += "FROM ["+loc_database+"].[dbo].[OperativeData] ";
      query += "WHERE [basename] LIKE '%RVS_%'";
      res = dbOpenRecordset(con, query, rs);
      DebugFTN("db_verbose", "Query executed");
      if(!res){
        while(!res && !dbEOF(rs)){
          anytype id, datapoint, value;
          res = dbGetField(rs, 0, datapoint);
          DebugFTN("lg_verbose", datapoint, value);
          dynAppend(rvs_dps, datapoint);

          res = dbMoveNext(rs);
        }
        dbCloseRecordset(rs);

        unack_rvs["dp"]  = makeDynString();
        unack_rvs["val"] = makeDynString();
        dpGet(rvs_dps, rvs_vals);
        for(int i=1; i<=dynlen(rvs_dps); i++){
            dynAppend(unack_rvs["dp"], rvs_dps[i]);
            dynAppend(unack_rvs["val"],rvs_vals[i]);
        }
        dbCloseConnection(con);
        updateRVS(unack_rvs, getCurrentTime());
      }else{ // Error Query
      dbCloseConnection(con);
      DebugFTN("db_error", "OPERATIVEDATA | Error open query database");
        dyn_errClass err = getLastError();
        if(dynlen(err)>0){
          for(int i = 1; i<=dynlen(err); i++){
            DebugFTN("db_error", err[i]);
          }
        }
      }
    }else{  // Error connection
      DebugFTN("db_error", "OPERATIVEDATA | Error open connection database");
      dyn_errClass err = getLastError();
      if(dynlen(err)>0){
        for(int i = 1; i<=dynlen(err); i++){
          DebugFTN("db_error", err[i]);
        }
      }
      changeActiveConnection(iConnection, mConfig);
      init = true;
    }
    DebugFTN("lg_info", "REFRESH RVS FINISHED AT:",getCurrentTime());
  }else{
    DebugFTN("lg_info", "This project NoActive(main)");
  }
}


//--------------------------------------------------------------------------------

main(){
  mConfig = getConnectionParams();
  dpConnect("cbDatabase", "_NB_CONFIG.ST");
  dpConnect("refreshRVS", true, "Sybcom.Triggers.1min_Trigger"); // TODO: delete init startup
}
