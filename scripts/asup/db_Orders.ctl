// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author Admin_tobSSPD
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "CtrlADO"
#uses "lib_asup"

//--------------------------------------------------------------------------------
// variables and constants
dyn_mapping mConfig;
int iConnection = 1;
string dp_srv_act = "_ReduManager.EvStatus";      // Для основного сервера

//--------------------------------------------------------------------------------
/**
*/

void cbDatabase(string dp, int db){
  iConnection = db;
}

void traceErrors(){
 dyn_errClass err = getLastError();
    for(int i=1; i<=dynlen(err); i++){
      DebugFTN("db_error", err[i]);
    }
}

void getOrders(int line){
  dbConnection con;
  dbRecordset rs;
  string loc_connection = mConfig[iConnection]["connection"];
  string loc_database = mConfig[iConnection]["db"];

  dyn_mapping all_order;

  int res = dbOpenConnection(loc_connection, con);
  if(!res){
    string query = "SELECT [sOrderNr], [sIdCard], [sRegNr], [sRegANr], [bLoadingType], [dtAdded], [iOrderPriority], [iLine], [iProcessed], [iID]\n" +
                   "FROM ["+loc_database+"].[dbo].[Orders]\n" +
                   "WHERE ["+loc_database+"].[dbo].[Orders].[iProcessed] = 0 and ["+loc_database+"].[dbo].[Orders].[iLine] = " + line + ";";
    DebugFTN("db_info", "ORDERS | select last order");
    DebugFTN("db_info", "ORDERS | query is \n-----------------------------\n", query, "\n-----------------------------");
    res = dbOpenRecordset(con, query, rs);
    if(!res){
      DebugFTN("db_info", "ORDERS | Recordset opened");
      while(!res && !dbEOF(rs)){
        mapping one_order;
        dbGetField(rs, 0, one_order["sOrderNr"]);
        dbGetField(rs, 1, one_order["sIdCard"]);
        dbGetField(rs, 2, one_order["sRegNr"]);
        dbGetField(rs, 3, one_order["sRegANr"]);
        dbGetField(rs, 4, one_order["bLoadingType"]);
        dbGetField(rs, 5, one_order["dtAdded"]);
        dbGetField(rs, 6, one_order["iOrderPriority"]);
        dbGetField(rs, 7, one_order["iLine"]);
        dbGetField(rs, 8, one_order["iProcessed"]);
        dbGetField(rs, 9, one_order["iID"]);
        all_order.append(one_order);
        res = dbMoveNext(rs);
      } // while(!res && !dbEOF(rs))
      dbCloseRecordset(rs);
      if(!all_order.isEmpty()){
        DebugFTN("db_info", "ORDERS | Data is: \n--------------------\n", all_order, "\n-----------------------------");
        getItems(all_order, con);
      }else{ // (!all_order.isEmpty())
        DebugFTN("db_info", "ORDERS | Empty data from db");
      }
    }else{// dbOpenRecordset(con, query, rs);
      DebugFTN("db_error", "ORDERS | Error open recordset");
      traceErrors();
    }
    setOrderDp(all_order, con);
    dbCloseConnection(con);
    dpSetWait("ORDER_LINE" + line + ".getOrder", false);
  }else{ // dbOpenConnection(loc_connection, con);
    changeActiveConnection(iConnection, mConfig);
    DebugFTN("db_error", "ORDERS | Error connection database");
    traceErrors();
  }
}

void getItems(dyn_mapping &orders, dbConnection con){
  string loc_connection = mConfig[iConnection]["connection"];
  string loc_database = mConfig[iConnection]["db"];
  for(int i=1; i<=orders.count(); i++){
    dbRecordset rs_it;
    string query = "SELECT [OrderItem].[sOrderNr], [OrderItem].[iCompNr], [OrderItem].[sProductCode], [OrderItem].[iQuantity], [OrderItem].[dtAdded], " +
                          "[OrderItem].[iProcessed], [OrderItem].[bTrailer], [OrderItem].[sRegNr], [OrderItem].[sKompNr], [OrderItem].[sDoc], " +
                          "[OrderItem].[sDelivery], [OrderItem].[nMass], [OrderItem].[Device], [OrderItem].[iPercent], [OrderItem].[iID]\n" +
                   "FROM ["+loc_database+"].[dbo].[OrderItem]\n" +
                   "WHERE [OrderItem].[iProcessed] = 0 and [OrderItem].[sOrderNr] = '" + orders[i]["sOrderNr"] + "';";
    DebugFTN("db_info", "ORDERS | select items for order: " + orders[i]["sOrderNr"]);
    DebugFTN("db_info", "ORDERS | query is \n-----------------------------\n", query, "\n-----------------------------");
    int res = dbOpenRecordset(con, query, rs_it);
    DebugFTN("db_error", getLastError());
    if(!res){
      orders[i]["items"] = makeDynMapping();
      DebugFTN("db_info", "ORDERS | Recordset opened");
      while(!res && !dbEOF(rs_it)){
        mapping one_item;
        dbGetField(rs_it, 0,  one_item["sOrderNr"]);
        dbGetField(rs_it, 1,  one_item["iCompNr"]);
        dbGetField(rs_it, 2,  one_item["sProductCode"]);
        dbGetField(rs_it, 3,  one_item["iQuantity"]);
        dbGetField(rs_it, 4,  one_item["dtAdded"]); //asd
        dbGetField(rs_it, 5,  one_item["iProcessed"]);
        dbGetField(rs_it, 6,  one_item["bTrailer"]);
        dbGetField(rs_it, 7,  one_item["sRegNr"]);
        dbGetField(rs_it, 8,  one_item["sKompNr"]);
        dbGetField(rs_it, 9,  one_item["sDoc"]); // asd
        dbGetField(rs_it, 10, one_item["sDelivery"]);
        dbGetField(rs_it, 11, one_item["nMass"]);
        dbGetField(rs_it, 12, one_item["Device"]);
        dbGetField(rs_it, 13, one_item["iPercent"]);
        dbGetField(rs_it, 14, one_item["iID"]);
        dynAppend(orders[i]["items"], one_item);
        res = dbMoveNext(rs_it);
      }
      DebugFTN("db_info", "ORDERS | Data is: \n--------------------\n", orders[i]["items"], "\n-----------------------------");
    }else{// dbOpenRecordset(con, query, rs);
      DebugFTN("db_error", "ORDERS | Error open recordset");
    }
  }
}

void updOrderProcessed(anytype id, dbConnection con){
  dbCommand cmd;
  dbStartCommand(con, "UPDATE " + mConfig[iConnection]["db"] + ".dbo.Orders SET iProcessed = 1 WHERE iID=" + id + ";", cmd);
  dbExecuteCommand(cmd);
  dbFinishCommand(cmd);
}

void updItemProcessed(anytype id, dbConnection con){
  dbCommand cmd;
  dbStartCommand(con, "UPDATE " + mConfig[iConnection]["db"] + ".dbo.OrderItem SET iProcessed = 1 WHERE iID=" + id + ";", cmd);
  dbExecuteCommand(cmd);
  dbFinishCommand(cmd);
}

void setOrderDp(dyn_mapping orders, dbConnection con){
  DebugFTN("lg_info", "ORDERS | orders to DP\n", orders);
  for(int i=1; i<=orders.count(); i++){
    int line = orders[i]["iLine"];
    dyn_mapping items = orders[i]["items"];
    clrOrderDp(line);
    dpSetWait("ORDER_LINE" + line + ".sOrderNr",       orders[i]["sOrderNr"],
              "ORDER_LINE" + line + ".sIdCard",        orders[i]["sIdCard"],
              "ORDER_LINE" + line + ".sRegNr",         orders[i]["sRegNr"],
              "ORDER_LINE" + line + ".sRegANr",        orders[i]["sRegANr"],
              "ORDER_LINE" + line + ".bLoadingType",   orders[i]["bLoadingType"],
              "ORDER_LINE" + line + ".dtAdded",        orders[i]["dtAdded"],
              "ORDER_LINE" + line + ".iOrderPriority", orders[i]["iOrderPriority"],
              "ORDER_LINE" + line + ".iLine",          orders[i]["iLine"],
              "ORDER_LINE" + line + ".iProcessed",     orders[i]["iProcessed"],
              "ORDER_LINE" + line + ".iID",            orders[i]["iID"]);
    updOrderProcessed(orders[i]["iID"], con);
    DebugFTN("lg_info", "ORDERS | update order DP", orders[i]["sOrderNr"], orders[i]["iID"]);
    for(int j=1; j<=items.count(); j++){
      int section = items[j]["iCompNr"];
      float prisadka = 0.0;
//       if(items[j]["iPercent"] != "")
//         prisadka = (items[j]["iPercent"] < 0.1) ? items[j]["iPercent"] * 100 : (1 - items[j]["iPercent"]) * 100;

      dpSetWait("ORDER_LINE" + line + ".items." + section + ".init.sOrderNr",     items[j]["sOrderNr"],
                "ORDER_LINE" + line + ".items." + section + ".init.iCompNr",      items[j]["iCompNr"],
                "ORDER_LINE" + line + ".items." + section + ".init.sProductCode", items[j]["sProductCode"],
                "ORDER_LINE" + line + ".items." + section + ".init.iQuantity",    items[j]["iQuantity"],
                "ORDER_LINE" + line + ".items." + section + ".init.dtAdded",      items[j]["dtAdded"],
                "ORDER_LINE" + line + ".items." + section + ".init.iProcessed",   items[j]["iProcessed"],
                "ORDER_LINE" + line + ".items." + section + ".init.bTrailer",     items[j]["bTrailer"],
                "ORDER_LINE" + line + ".items." + section + ".init.sRegNr",       items[j]["sRegNr"],
                "ORDER_LINE" + line + ".items." + section + ".init.sKompNr",      items[j]["sKompNr"],
                "ORDER_LINE" + line + ".items." + section + ".init.sDoc",         items[j]["sDoc"],
                "ORDER_LINE" + line + ".items." + section + ".init.sDelivery",    items[j]["sDelivery"],
                "ORDER_LINE" + line + ".items." + section + ".init.nMass",        items[j]["nMass"],
                "ORDER_LINE" + line + ".items." + section + ".init.Device",       items[j]["Device"],
                "ORDER_LINE" + line + ".items." + section + ".init.iID",          items[j]["iID"],
                "ORDER_LINE" + line + ".items." + section + ".init.iPercent",     items[j]["iPercent"]);
      updItemProcessed(items[j]["iID"], con);
      DebugFTN("lg_info", "ORDERS | update itmes DP", items[j]["iCompNr"], items[j]["iID"]);
    }
  }
}

void clrOrderDp(int line){
  dpSetWait("ORDER_LINE" + line + ".sOrderNr",         "",
            "ORDER_LINE" + line + ".sIdCard",          "",
            "ORDER_LINE" + line + ".sRegNr",           "",
            "ORDER_LINE" + line + ".sRegANr",          "",
            "ORDER_LINE" + line + ".bLoadingType",     false,
            "ORDER_LINE" + line + ".dtAdded",          0,
            "ORDER_LINE" + line + ".iOrderPriority",   0,
            "ORDER_LINE" + line + ".iLine",            0,
            "ORDER_LINE" + line + ".iProcessed",       99);

  for(int j=1; j<=10; j++){
      dpSetWait("ORDER_LINE" + line + ".items." + j + ".init.sOrderNr",     "",
                "ORDER_LINE" + line + ".items." + j + ".init.iCompNr",      0,
                "ORDER_LINE" + line + ".items." + j + ".init.sProductCode", "",
                "ORDER_LINE" + line + ".items." + j + ".init.iQuantity",    0,
                "ORDER_LINE" + line + ".items." + j + ".init.dtAdded",      0,
                "ORDER_LINE" + line + ".items." + j + ".init.iProcessed",   99,
                "ORDER_LINE" + line + ".items." + j + ".init.bTrailer",     false,
                "ORDER_LINE" + line + ".items." + j + ".init.sRegNr",       "",
                "ORDER_LINE" + line + ".items." + j + ".init.sKompNr",      "",
                "ORDER_LINE" + line + ".items." + j + ".init.sDoc",         "",
                "ORDER_LINE" + line + ".items." + j + ".init.sDelivery",    "",
                "ORDER_LINE" + line + ".items." + j + ".init.nMass",        0,
                "ORDER_LINE" + line + ".items." + j + ".init.Device",       0,
                "ORDER_LINE" + line + ".items." + j + ".init.iPercent",     0);
  }
}

void worker(int line, string dp, bool val){
  bool temp_srv;
  dpGet(dp_srv_act, temp_srv);
  if(true & val){ // (temp_srv & val)
    getOrders(line);
  }else{
    DebugFTN("lg_info", "This project NoActive(main)");
  }
}

void workerEnd(anytype ud, dyn_dyn_anytype data){
  data.removeAt(0);
  for(int i=1; i<=data.count(); i++){
    dbConnection con;
    dbCommand cmd;
    int res;
    string loc_connection = mConfig[iConnection]["connection"];
    string loc_database = mConfig[iConnection]["db"];
    res = dbOpenConnection(loc_connection, con);
      if(!res){
      string dp_section = dpSubStr(data[i][1], DPSUB_DP_EL);
      dyn_string temp_dp = stringToDynString(dp_section , ".");
      dp_section = temp_dp[1] + "." + temp_dp[2] + "." + temp_dp[3];
      DebugFTN("lg_info", "ORDERS | result datapoint: ", dp_section);
      anytype rDispatchOrder, rReceipId, rPostNumber, rRegistrationNumber, rSectionNumber, rOrderedVolume, rDispatchOrder, rOrderedWeight,
          rLoadedWeight, rLoadedVolume, rLoadedTemperature, rLoadedDensity, rTankCode,
          rLoadedBaseWeight, rLoadedBaseVolume, rLoadedBaseTemperature, rLoadedBaseDensity,
          rLoadedMixed1Weight, rLoadedMixed1Volume, rLoadedMixed1Temperature, rLoadedMixed1Density,
          rErrorCode, rResultCode ,rDtStart, rDtEnd, rSumVolumeStart, rSumVolumeEnd, rSumWeightStart, rSumWeightEnd, rModeCtrl, rsHash, rDispatchOrder,
          SumVolumeStartpr, SumVolumeEndpr, qTankLevelStart, qVolumeTankStart, qWeightTankStart, qDensityTankStart, qTempTankStart, qPressureStart, qLevelWaterStart,
          qVolumeWaterStart, qVolumeTankEnd, qWeightTankEnd, qDensityTankEnd, qTempTankEnd, qPressureEnd, qLevelWaterEnd, qCardID, qNbrLine;

      dpGet(dp_section + ".result.ReceipId"                , rReceipId,
            dp_section + ".result.PostNumber"              , rPostNumber,
            dp_section + ".result.TankCode"                , rTankCode,
            dp_section + ".result.RegistrationNumber"      , rRegistrationNumber,
            dp_section + ".result.SectionNumber"           , rSectionNumber,
            dp_section + ".result.OrderedVolume"           , rOrderedVolume,
            dp_section + ".result.LoadedWeight"            , rLoadedWeight,
            dp_section + ".result.LoadedVolume"            , rLoadedVolume,
            dp_section + ".result.LoadedTemperature"       , rLoadedTemperature,
            dp_section + ".result.LoadedDensity"           , rLoadedDensity, //asd
            dp_section + ".result.LoadedBaseWeight"        , rLoadedBaseWeight,
            dp_section + ".result.LoadedBaseVolume"        , rLoadedBaseVolume,
            dp_section + ".result.LoadedBaseTemperature"   , rLoadedBaseTemperature,
            dp_section + ".result.LoadedBaseDensity"       , rLoadedBaseDensity,
            dp_section + ".result.LoadedMixed1Weight"      , rLoadedMixed1Weight,
            dp_section + ".result.LoadedMixed1Volume"      , rLoadedMixed1Volume,
            dp_section + ".result.LoadedMixed1Temperature" , rLoadedMixed1Temperature,
            dp_section + ".result.LoadedMixed1Density"     , rLoadedMixed1Density,
            dp_section + ".result.ErrorCode"               , rErrorCode,
            dp_section + ".result.ResultCode"              , rResultCode,
            dp_section + ".result.SumVolumeStart"          , rSumVolumeStart,
            dp_section + ".result.SumVolumeEnd"            , rSumVolumeEnd,
            dp_section + ".result.SumWeightStart"          , rSumWeightStart,
            dp_section + ".result.SumWeightEnd"            , rSumWeightEnd,
            dp_section + ".result.ModeCtrl"                , rModeCtrl,
            dp_section + ".result.DtStart"                 , rDtStart,
            dp_section + ".result.DtEnd"                   , rDtEnd,
            dp_section + ".result.OrderedWeight"           , rOrderedWeight,
 //           dp_section + ".result.OrderedWeight"           , rOrderedWeight,
            dp_section + ".init.sOrderNr"                  , rDispatchOrder,
            dp_section + ".result.SumVolumeStartpr"        , SumVolumeStartpr,
            dp_section + ".result.SumVolumeEndpr"          , SumVolumeEndpr,
            dp_section + ".result.qTankLevelStart"         , qTankLevelStart,
            dp_section + ".result.qVolumeTankStart"        , qVolumeTankStart,
            dp_section + ".result.qWeightTankStart"        , qWeightTankStart,
            dp_section + ".result.qDensityTankStart"       , qDensityTankStart,
            dp_section + ".result.qTempTankStart"          , qTempTankStart,
            dp_section + ".result.qPressureStart"          , qPressureStart,
            dp_section + ".result.qLevelWaterStart"        , qLevelWaterStart,
            dp_section + ".result.qVolumeWaterStart"       , qVolumeWaterStart,
            dp_section + ".result.qVolumeTankEnd"          , qVolumeTankEnd,
            dp_section + ".result.qWeightTankEnd"          , qWeightTankEnd,
            dp_section + ".result.qDensityTankEnd"         , qDensityTankEnd,
            dp_section + ".result.qTempTankEnd"            , qTempTankEnd,
            dp_section + ".result.qPressureEnd"            , qPressureEnd,
            dp_section + ".result.qLevelWaterEnd"          , qLevelWaterEnd,
            dp_section + ".result.qCardID"                 , qCardID,
            dp_section + ".result.qNbrLine"                , qNbrLine);

      string dataToHash =  rLoadedWeight + ", " + rLoadedVolume + ", " + rLoadedTemperature;
      string rSHash = getHash(dataToHash);
      string query = "INSERT INTO [" + loc_database + "].[dbo].[vLoadingResult] " +
                         "(DateRecording, RecipeId, PostNumber, TankCode, RegistrationNumber, SectionNumber, OrderedVolume, " +
                         "LoadedWeight, LoadedVolume, LoadedTemperature, LoadedDensity, LoadedBaseWeight, LoadedBaseVolume, LoadedBaseTemp, LoadedBaseDensity, "+
                         "LoadedMixed1Weight, LoadedMixed1Volume, LoadedMixed1Temp, LoadedMixed1Density, ErrorCode, ResultCode, SumVolumeStart, SumVolumeEnd, "+
                         "SumWeightStart, SumWeightEnd, ModeCtrl, DtStart, DtEnd, OrderedWeight, DispatchOrder, sHash, iProcessed, "+
                         "SumVolumeStartpr, SumVolumeEndpr, qTankLevelStart, qVolumeTankStart, qWeightTankStart, qDensityTankStart, qTempTankStart, qPressureStart, qLevelWaterStart, qVolumeWaterStart, "+
                         "qVolumeTankEnd, qWeightTankEnd, qDensityTankEnd, qTempTankEnd, qPressureEnd, qLevelWaterEnd, qCardID, qNbrLine) " +
                         "VALUES ( GETDATE(), '" + rReceipId + "', " + rPostNumber + ", '" + rTankCode + "', '" + rRegistrationNumber + "', " +
                                   rSectionNumber + ", " + rOrderedVolume + ", " + rLoadedWeight + ", " + rLoadedVolume + ", " + rLoadedTemperature + ", " +
                                   rLoadedDensity + ", " + rLoadedBaseWeight + ", " + rLoadedBaseVolume + ", " + rLoadedBaseTemperature + ", " + rLoadedBaseDensity + ", " +
                                   rLoadedMixed1Weight + ", " + rLoadedMixed1Volume + ", " + rLoadedMixed1Temperature + ", '" + rLoadedMixed1Density + "', '" +
                                   rErrorCode + "', '" + rResultCode + "', '" + rSumVolumeStart + "', '" + rSumVolumeEnd + "', '" + rSumWeightStart + "', '" + rSumWeightEnd + "', '" + rModeCtrl + "', '" +
                                   formatTime("%Y-%m-%dT%H:%M:%S", rDtStart)  + "', '" + formatTime("%Y-%m-%dT%H:%M:%S", rDtEnd) + "', '" + rOrderedWeight + "', '" + rDispatchOrder + "', '" + rSHash + "', 0, " +
                                   SumVolumeStartpr + ", " + SumVolumeEndpr + ", " + qTankLevelStart + ", " + qVolumeTankStart + ", " + qWeightTankStart + ", " + qDensityTankStart + ", " + qTempTankStart + ", " +
                                   qPressureStart + ", " + qLevelWaterStart + ", " + qVolumeWaterStart + ", " + qVolumeTankEnd + ", " + qWeightTankEnd + ", " + qDensityTankEnd + ", " +
                                   qTempTankEnd + ", " + qPressureEnd + ", " + qLevelWaterEnd + ", " + qCardID + ", " + qNbrLine +" )";

      DebugFTN("db_info", "ORDERS | update vLoadingResult query \n", query);
      dbStartCommand(con, query, cmd);
      dbExecuteCommand(cmd);
      DebugFTN("db_error", getLastError());
      dbFinishCommand(cmd);
    }else{  // db open connection
      DebugFTN("db_error", "RECEIVE | Error connection database");
      traceErrors();
      changeActiveConnection(iConnection, mConfig);
    }
  }
}

main(string p1){
  if(p1 == "-RES"){
    dp_srv_act = "_ReduManager_2.EvStatus";
  }
  mConfig = getConnectionParams();
  dpConnect("cbDatabase", "_NB_CONFIG.ST");

  dpConnectUserData("worker",1, false, "System1:ORDER_LINE1.getOrder");
  dpConnectUserData("worker",2, false, "System1:ORDER_LINE2.getOrder");
  dpConnectUserData("worker",3, false, "System1:ORDER_LINE3.getOrder");
//   dpConnectUserData("worker",4, false, "System1:ORDER_LINE4.getOrder");
//   dpConnectUserData("worker",5, false, "System1:ORDER_LINE5.getOrder");
//   dpConnectUserData("worker",6, false, "System1:ORDER_LINE6.getOrder");

  dpQueryConnectSingle("workerEnd", false, "ud", "SELECT '_original.._value' FROM 'ORDER_LINE?.items.?.result.DtEnd'");
}
