// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author BRM
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "CtrlADO"
#uses "rdb"
//--------------------------------------------------------------------------------
// variables and constants
const string CONNECTION_LINE = "DSN=ASUP_DB1;UID=spb-tr_asutp_gld;PWD=Qwerty@1;";

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
//Забрать данные из БД по приему при открытии мнемосхемы отчета.
dyn_dyn_string recieve_data(string query){
    dyn_dyn_string data;
    dbConnection con;
    dbRecordset rs;
    int res = dbOpenConnection(CONNECTION_LINE, con);
    if(!res){
      res = rdbSelect(con, query, data, 500);
      if(!res){
        return data;
      }
      else{
        dyn_errClass err = getLastError();
        if(dynlen(err)>0){
          for(int i = 1; i<=dynlen(err); i++){
            DebugTN("query_error", err[i]);
          }
        }
      }
    }else{  // Error connection
      dyn_errClass err = getLastError();
      if(dynlen(err)>0){
        for(int i = 1; i<=dynlen(err); i++){
          DebugTN("db_error", err[i]);
        }
      }
    }
}

dyn_dyn_string loading_data(string query){
    dyn_dyn_string data;
    dbConnection con;
    dbRecordset rs;
    int res = dbOpenConnection(CONNECTION_LINE, con);
    if(!res){
     res = rdbSelect(con, query, data, 500);
      if(!res){
        return data;
      }
      else{
        dyn_errClass err = getLastError();
        if(dynlen(err)>0){
          for(int i = 1; i<=dynlen(err); i++){
            DebugTN("query_error", err[i]);
          }
        }
      }
    }else{  // Error connection
   	  dyn_errClass err = getLastError();
      if(dynlen(err)>0){
        for(int i = 1; i<=dynlen(err); i++){
          DebugTN("db_error", err[i]);
        }
      }
    }
}
//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

