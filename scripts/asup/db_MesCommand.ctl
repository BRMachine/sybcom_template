// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file db_MesCommand.ctl
  @copyright $copyright
  @author r.arslanov
  @version 1.1
*/
/**
changelog:
  v.1.0 - R.Arslanov
    1. initial version
  v.1.1 - R.Arslanov
    1. В обработку добавлен резервный сервер БД АСУП
    2. static функции вынесены в библиотеку
*/
//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "CtrlADO"
#uses "lib_asup"

//--------------------------------------------------------------------------------
// variables and constants
bool busy;
int iConnection = 1;
dyn_mapping mConfig;
 string dp_srv_act = "_ReduManager.EvStatus";      // Для основного сервера
// string dp_srv_act = "_ReduManager_2.EvStatus"; // Для резервного сервера

//--------------------------------------------------------------------------------

void getLastCommand(string dp, bool trg){
  bool temp_srv;
  dpGet(dp_srv_act, temp_srv);
  if (temp_srv) {           //если сервер активный
    if(!busy){
      busy = true;
      dbConnection con;
      dbRecordset rs;
      int res;

      string loc_connection = mConfig[iConnection]["connection"];
      string loc_database = mConfig[iConnection]["db"];

      res = dbOpenConnection(loc_connection, con);
      if(!res){
        string query = "SELECT TOP(1) *";
        query += "FROM ["+loc_database+"].[dbo].[MesCommand] ";
        query += "WHERE ["+loc_database+"].[dbo].[MesCommand].[State] = 0 ";
        //DebugN("query", query);
        res = dbOpenRecordset(con, query, rs);
        dyn_errClass err = getLastError();
        for(int i=1; i<=dynlen(err); i++){
          //DebugFTN("error", err[i]);
          DebugN("error", err[i]);
        }
        if(!res){
          anytype id, tag, val, ts, state, c_tag, c_val, t_out;
          mapping com;
          dbGetField(rs, 0, com["id"]);
          dbGetField(rs, 3, com["tag"]);
          dbGetField(rs, 4, com["val"]);
          //dbGetField(rs, 3, com["argv"]);
          dbGetField(rs, 5, com["ts"]);
          dbGetField(rs, 6, com["state"]);
          dbGetField(rs, 7, com["c_tag"]);
          dbGetField(rs, 8, com["c_val"]);
          dbGetField(rs, 9, com["t_out"]);

          if(com["id"] != ""){
            //DebugFTN("info", com);
            DebugN("info", com);
            updateDP(com);
            updateRowDB(con, com["id"], 1);
          }

          dbCloseRecordset(rs);
          dbCloseConnection(con);
          busy = false;
        }else{
          DebugN("Error query DB_MES_COMMAND", iConnection);
          busy = false;
        }
      }else{
        DebugN("Error connection DB_MES_COMMAND", iConnection);
        changeActiveConnection(iConnection, mConfig);
        busy = false;
      }
    }
  }else{
    DebugFTN("lg_info", "This project NoActive(main)");
  }
}

void updateDP(mapping com){
  mapping dp;
  dpGet("CURRENT_COMMAND.id"   , dp["id"],
        "CURRENT_COMMAND.tag"  , dp["tag"],
        "CURRENT_COMMAND.val"  , dp["val"],
        //"CURRENT_COMMAND.argv" , dp["argv"],
        "CURRENT_COMMAND.ts"   , dp["ts"],
        "CURRENT_COMMAND.state", dp["state"],
        "CURRENT_COMMAND.c_tag", dp["c_tag"],
        "CURRENT_COMMAND.c_val", dp["c_val"],
        "CURRENT_COMMAND.t_out", dp["t_out"]);

  dynAppend(dp["id"]   , com["id"]);
  dynAppend(dp["tag"]  , com["tag"]);
  dynAppend(dp["val"]  , com["val"]);
  //dynAppend(dp["argv"] , com["argv"]);
  dynAppend(dp["ts"]   , com["ts"]);
  dynAppend(dp["state"], com["state"]);
  dynAppend(dp["c_tag"], com["c_tag"]);
  dynAppend(dp["c_val"], com["c_val"]);
  dynAppend(dp["t_out"], com["t_out"]);

  dpSet("CURRENT_COMMAND.id"   , dp["id"],
        "CURRENT_COMMAND.tag"  , dp["tag"],
        "CURRENT_COMMAND.val"  , dp["val"],
       // "CURRENT_COMMAND.argv" , dp["argv"],
        "CURRENT_COMMAND.ts"   , dp["ts"],
        "CURRENT_COMMAND.state", dp["state"],
        "CURRENT_COMMAND.c_tag", dp["c_tag"],
        "CURRENT_COMMAND.c_val", dp["c_val"],
        "CURRENT_COMMAND.t_out", dp["t_out"]);
}

void updateRowDB(dbConnection con, string id, int rdps){
  dbCommand cmd;
  dbStartCommand(con, "UPDATE "+mConfig[iConnection]["db"]+".dbo.MesCommand SET State = "+rdps+" WHERE id=" + id + ";", cmd);
  DebugN("Updated row: " + id);
  dbExecuteCommand(cmd);
  dbFinishCommand(cmd);
}

void cbDatabase(string dp, int db){
  iConnection = db;
}

main(){
  mConfig = getConnectionParams();
  dpConnect("cbDatabase", "_NB_CONFIG.ST");
  dpConnect("getLastCommand", "Sybcom.Triggers.1s_Trigger");

}
