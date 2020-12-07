// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author r.arslanov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "CtrlADO"
//--------------------------------------------------------------------------------
// variables and constants
string sConnection, sDatabase;

//--------------------------------------------------------------------------------
/**
*/
void genConLine(string &line, string &db){
  bool type;
  string dsn, uid, pwd;

  dpGet("_NB_CONFIG.DSN", dsn,
        "_NB_CONFIG.UID", uid,
        "_NB_CONFIG.PWD", pwd,
        "_NB_CONFIG.WIN", type,
        "_NB_CONFIG.DB", db);

  line = "DSN=" + dsn + ";";
  if(!type){
    line += "UID=" + uid + ";";
    line += "PWD=" + pwd + ";";
  }
}

void traceErrors(){
  dyn_errClass err = getLastError();
  for(int i=1; i<=dynlen(err); i++){
    DebugFTN("error", err[i]);
  }
}

void worker(string dp, bool upd){
  dyn_string names = dpNames("order_*", "SQL_ORDERS");
  string order_nr;
  dbConnection con;
  dbRecordset rs;
  for(int i = 1; i <= names.count(); i++){
    bool tmp_upd;
    dpGet(names[i] + ".needUpdate", tmp_upd);
    if(tmp_upd && names[i] != "System1:order_default"){
      dpGet(names[i] + ".nr", order_nr);
      int res = dbOpenConnection(sConnection, con);
      if(!res){
        dyn_mapping result_query;
        string query = "SELECT ";
               query+= "[iID], [sOrderNr], [sProductCode], [iQuantity], [iCompNr], [iQuantity] ";
               query+= "FROM ["+sDatabase+"].[dbo].[OrderItem] ";
               query+= "WHERE ["+sDatabase+"].[dbo].[OrderItem].[sOrderNr] LIKE '" + order_nr + "%';";
        res = dbOpenRecordset(con, query, rs);
        traceErrors();
        if(!res){
          while(!res && !dbEOF(rs)){
            mapping one;
            res = dbGetField(rs, 0, one["id"]);
            res = dbGetField(rs, 1, one["order"]);
            res = dbGetField(rs, 2, one["product"]);
            res = dbGetField(rs, 3, one["section"]);
            res = dbGetField(rs, 4, one["quantity"]);
            result_query.append(one);
            res = dbMoveNext(rs);
          }
          if(result_query.count() > 0){
            dyn_anytype product, section, quantity;
            for(int i=1; i<=result_query.count(); i++){
              product.append(result_query[i]["product"]);
              section.append(result_query[i]["section"]);
              quantity.append(result_query[i]["quantity"]);
            }
            dpSetWait(names[i] + ".items.product",  product,
                      names[i] + ".items.quantity", section,
                      names[i] + ".items.section",  quantity,
                      names[i] + ".needUpdate", false);
          }
          dbCloseRecordset(rs);
        } // dbOpenRecordSet
        else{
          DebugTN("Error query");
        }
        dbCloseConnection(con);
      } // dbOpenConnection
      else{
        DebugTN("Error connection");
      }
    } // tmp_upd = true
  } // for
}

main(){
  genConLine(sConnection, sDatabase);
  dpConnect("worker", "order_default.needUpdate");
}
