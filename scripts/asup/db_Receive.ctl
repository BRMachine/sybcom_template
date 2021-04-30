// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author r.arslanov
*/
/*

INSERT INTO [ASU_MES_DB].[dbo].[vReceptionResult_new] (
  DateRecording, PostName, TankCode, DtStart, DtEnd, RecWeight, RecVolume, RecDensity, RecTemperature, RecDensityCoerced, RecVolumeCoerced, SumVolumeStart, SumVolumeEnd, SumWeightStart, SumWeightEnd, Volume,
  CompNbr, DispathOrder, sInvNum, OsProduct, iProcessed, qTankLevelStart, qVolumeTankStart, qWeightTankStart, qDensityTankStart, qTempTankStart, qTankWaterLStart, qCoercedDensityStart, qCoercedVolumeStart,
  qPressureStart, qLevelWaterStart, qVolumeWaterStart, qTankLevelEnd, qVolumeTankEnd, qWeightTankEnd, qDensityTankEnd, qTempTankEnd, qTankWaterLEnd, qCoercedDensityEnd, qCoercedVolumeEnd, qPressureEnd, qLevelWaterEnd,
  qVolumeWaterEnd, ModeCtrl) Values(GETDATE(), 'ИС3', 0, '2021-01-22T22:26:35', '2021-01-22T22:27:16', 0, 0, 0.761, -19.7, 0, 0, 24121834, 24121834, 18032536, 18032536, 0, '', '', '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
*/
//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "CtrlADO"
#uses "lib_asup"
//--------------------------------------------------------------------------------
// variables and constants

int iConnection = 1;
dyn_mapping mConfig;
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

void updateDP(dyn_mapping init, dbConnection con){
  DebugFTN("lg_info", "RECEIVE | calling updateDP()");
  DebugFTN("lg_info", "RECEIVE | init is empty? ", init.isEmpty());
  DebugFTN("lg_info", "RECEIVE | init is  ", init);
  for(int i=1; i<=4; i++){
    int sts;
    dpGet("LAST_RECEIVE_" + i + ".state", sts);
    if(sts == 2){
      for(int j=1; j<=8; j++){
        dpSetWait("LAST_RECEIVE_" + i + ".init." + j + ".id"       , 0,
                  "LAST_RECEIVE_" + i + ".init." + j + ".task"     , "",
                  "LAST_RECEIVE_" + i + ".init." + j + ".doc"      , "",
                  "LAST_RECEIVE_" + i + ".init." + j + ".usn"      , 0,
                  "LAST_RECEIVE_" + i + ".init." + j + ".rail"     , "",
                  "LAST_RECEIVE_" + i + ".init." + j + ".tank"     , 0,
                  "LAST_RECEIVE_" + i + ".init." + j + ".fuel"     , "",
                  "LAST_RECEIVE_" + i + ".init." + j + ".weight"   , 0,
                  "LAST_RECEIVE_" + i + ".init." + j + ".uu"       , 0,
                  "LAST_RECEIVE_" + i + ".init." + j + ".state"    , 99,
                  "LAST_RECEIVE_" + i + ".init." + j + ".datetime" , 0,
                  "LAST_RECEIVE_" + i + ".init." + j + ".init"     , 0,
                  "LAST_RECEIVE_" + i + ".init." + j + ".type"     , 0,
                  "LAST_RECEIVE_" + i + ".state"                   , 0);
      }
    }
  }

  for(int i=1; i<=init.count(); i++){
    if(!dpExists(init[i]["task_num"])){ dpCreate(init[i]["task_num"], "SQL_RECEIVES"); }
    else                              { DebugFTN("lg_info", "RECEIVE | dp alredy exist", init[i]["task_num"]); }
    DebugFTN("lg_info", "RECEIVE | Datapoint is: ", init[i]["task_num"] + ".init." + init[i]["usn_num"]);

    dpSetWait(init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".id"      , init[i]["id"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".task"    , init[i]["task_num"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".doc"     , init[i]["doc_num"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".usn"     , init[i]["usn_num"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".rail"    , init[i]["rail_num"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".tank"    , init[i]["tank_num"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".fuel"    , init[i]["fuel"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".weight"  , init[i]["weight"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".uu"      , init[i]["uu_num"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".state"   , init[i]["state"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".datetime", init[i]["datetime"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".init"    , init[i]["init"],
              init[i]["task_num"] + ".init." + init[i]["usn_num"] + ".type"    , init[i]["type"]);
    int temp_rail_sts;
    dpGet("LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".state", temp_rail_sts);
    if(temp_rail_sts == 2 | temp_rail_sts == 99){
      updProcessed(init[i]["id"], con);
      dpSetWait("LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".id"      , init[i]["id"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".task"    , init[i]["task_num"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".doc"     , init[i]["doc_num"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".usn"     , init[i]["usn_num"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".rail"    , init[i]["rail_num"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".tank"    , init[i]["tank_num"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".fuel"    , init[i]["fuel"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".weight"  , init[i]["weight"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".uu"      , init[i]["uu_num"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".state"   , init[i]["state"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".datetime", init[i]["datetime"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".init"    , init[i]["init"],
                "LAST_RECEIVE_" + init[i]["uu_num"] + ".init." + init[i]["usn_num"] + ".type"    , init[i]["type"]);

    }
  }
}

void updateProcessed(dyn_mapping data, dbConnection con){
  dbCommand cmd;
  for(int i=1; i<=data.count(); i++){
    int temp_sts;
    dpGet("LAST_RECEIVE_" + data[i]["uu_num"] + ".init." + data[i]["usn_num"] + ".state", temp_sts);
    DebugFTN("lg_info", "_________________________________________________________________",data[i]["usn_num"], data[i]["task_num"], temp_sts);
    if(temp_sts == 2 | temp_sts == 99){
      dbStartCommand(con, "UPDATE " + mConfig[iConnection]["db"] + ".dbo.ReceptionOrderItem SET iProcessed = 1 WHERE iID=" + data[i]["id"] + ";", cmd);
      dbExecuteCommand(cmd);
      dbFinishCommand(cmd);
    }
  }
}

void updProcessed(anytype id, dbConnection con){
  dbCommand cmd;
  dbStartCommand(con, "UPDATE " + mConfig[iConnection]["db"] + ".dbo.ReceptionOrderItem SET iProcessed = 1 WHERE iID=" + id + ";", cmd);
  dbExecuteCommand(cmd);
  dbFinishCommand(cmd);
}

void workerReceive(string dp, bool trg){
  bool temp_srv;
  dpGet(dp_srv_act, temp_srv);
  if (temp_srv){           //если сервер активный
    dbConnection con;
    dbRecordset rs;

    string loc_connection = mConfig[iConnection]["connection"];
    string loc_database = mConfig[iConnection]["db"];
    DebugFTN("db_info", "RECEIVE | Connection config: ", loc_connection + "\n" + loc_database);

    int res = dbOpenConnection(loc_connection, con);

    if(!res){
      DebugFTN("db_info", "RECEIVE | Connection opened");
      dyn_mapping data;
      string query = "SELECT  \n";
             query+= " [iID], [Initialized], [iType], [sTaskNr], [sDocNum], [CompNr], [RealCompNr], [TankCode], [Product], [OrderedWeight], [PostNr], [iProcessed], [dtAdded] \n";
             query+= "FROM ["+loc_database + "].[dbo].[ReceptionOrderItem] \n";
             query+= "WHERE ["+loc_database+"].[dbo].[ReceptionOrderItem].[iProcessed] = 0; ";
      DebugFTN("db_info", "RECEIVE | query is: \n", query);
      res = dbOpenRecordset(con, query, rs);
      if(!res){
        DebugFTN("db_info", "RECEIVE | Recordset opened");
        while(!res && !dbEOF(rs)){
          mapping one_data;
          dbGetField(rs, 0,  one_data["id"]);
          dbGetField(rs, 1,  one_data["init"]);
          dbGetField(rs, 2,  one_data["type"]);
          dbGetField(rs, 3,  one_data["task_num"]);
          dbGetField(rs, 4,  one_data["doc_num"]);
          dbGetField(rs, 5,  one_data["usn_num"]);
          dbGetField(rs, 6,  one_data["rail_num"]);
          dbGetField(rs, 7,  one_data["tank_num"]);
          dbGetField(rs, 8,  one_data["fuel"]);
          dbGetField(rs, 9,  one_data["weight"]);
          dbGetField(rs, 10, one_data["uu_num"]);
          dbGetField(rs, 11, one_data["state"]);
          dbGetField(rs, 12, one_data["datetime"]);
          data.append(one_data);
          res = dbMoveNext(rs);
        }
        dbCloseRecordset(rs);
        if(!data.isEmpty()){
          updateDP(data, con);
//           updateProcessed(data, con);
          DebugFTN("db_info", "RECEIVE | Data is: \n", data);
        }else{
          DebugFTN("db_info", "RECEIVE | Empty data from db");
        }
      }else{ // Open recordset
        DebugFTN("db_error", "RECEIVE | Error open recordset");
        traceErrors();
      }
      dbCloseConnection(con);
    }else{ // open connection
      DebugFTN("db_error", "RECEIVE | Error connection database");
      traceErrors();
      changeActiveConnection(iConnection, mConfig);
    }
  }else{
    DebugFTN("lg_info", "This project NoActive(main)");
  }
}

void updateReceive(int is, string dp, time val){
  bool temp_srv;
  dpGet(dp_srv_act, temp_srv);
  if (temp_srv){           //если сервер активный
    DebugFTN("db_info", "RECEIVE | updateReceive called");
    dbConnection con;
    dbCommand cmd;
    int res;
    string loc_connection = mConfig[iConnection]["connection"];
    string loc_database = mConfig[iConnection]["db"];
    res = dbOpenConnection(loc_connection, con);
    if(!res){
      DebugFTN("db_info", "RECEIVE | updateReceive db Opened");
      string dp_rec = "LAST_RECEIVE_" + is + ".result.";
      string PostName, CompNbr, DispathOrder, sInvNum, OsProduct;
      int TankCode;
      time DtStart, DtEnd;
      float RecWeight, RecVolume, RecDensity, RecTemperature, RecDensityCoerced, RecVolumeCoerced,
            SumVolumeEnd, SumWeightEnd, SumVolumeStart, SumWeightStart, Volume,
            qTankLevelStart, qVolumeTankStart, qWeightTankStart, qDensityTankStart,
            qTempTankStart, qTankWaterLStart, qCoercedDensityStart, qCoercedVolumeStart,
            qPressureStart, qLevelWaterStart, qVolumeWaterStart,

            qTankLevelEnd, qVolumeTankEnd, qWeightTankEnd, qDensityTankEnd,
            qTempTankEnd, qTankWaterLEnd, qCoercedDensityEnd, qCoercedVolumeEnd,
            qPressureEnd, qLevelWaterEnd, qVolumeWaterEnd, ModeCtrl;

      dpGet(dp_rec + "post_name"      , PostName,
            dp_rec + "tank"           , TankCode,
            dp_rec + "dt_start"       , DtStart,
            dp_rec + "dt_end"         , DtEnd,
            dp_rec + "weight_fct"     , RecWeight,
            dp_rec + "volume_fct"     , RecVolume,
            dp_rec + "density_fct"    , RecDensity,
            dp_rec + "temp_fct"       , RecTemperature,
            dp_rec + "density_15"     , RecDensityCoerced,
            dp_rec + "volume_15"      , RecVolumeCoerced,
            dp_rec + "volume_sum"     , SumVolumeEnd,
            dp_rec + "weight_sum"     , SumWeightEnd,
            dp_rec + "volume_dose"    , Volume,
            dp_rec + "post_name"      , PostName,
            dp_rec + "rail_num"       , CompNbr,
            dp_rec + "task"           , DispathOrder,
            dp_rec + "inventory"      , sInvNum,
            dp_rec + "product"        , OsProduct,

            dp_rec + "volume_sum_start"  , SumVolumeStart,
            dp_rec + "weight_sum_start"  , SumWeightStart,

            dp_rec + "tank_data.level_start"      , qTankLevelStart,
            dp_rec + "tank_data.volume_start"     , qVolumeTankStart,
            dp_rec + "tank_data.weight_start"     , qWeightTankStart,
            dp_rec + "tank_data.density_start"    , qDensityTankStart, // checkpoint
            dp_rec + "tank_data.temp_start"       , qTempTankStart,
            dp_rec + "tank_data.waterl_start"     , qTankWaterLStart,
            dp_rec + "tank_data.density_15_start" , qCoercedDensityStart,
            dp_rec + "tank_data.volume_15_start"  , qCoercedVolumeStart,
            dp_rec + "tank_data.press_start"      , qPressureStart,
            dp_rec + "tank_data.lwater_start"     , qLevelWaterStart,
            dp_rec + "tank_data.vwater_start"     , qVolumeWaterStart,

            dp_rec + "tank_data.level_end"        , qTankLevelEnd,
            dp_rec + "tank_data.volume_end"       , qVolumeTankEnd,
            dp_rec + "tank_data.weight_end"       , qWeightTankEnd,
            dp_rec + "tank_data.density_end"      , qDensityTankEnd, // checkpoint
            dp_rec + "tank_data.temp_end"         , qTempTankEnd,
            dp_rec + "tank_data.waterl_end"       , qTankWaterLEnd,
            dp_rec + "tank_data.density_15_end"   , qCoercedDensityEnd,
            dp_rec + "tank_data.volume_15_end"    , qCoercedVolumeEnd,
            dp_rec + "tank_data.press_end"        , qPressureEnd,
            dp_rec + "tank_data.lwater_end"       , qLevelWaterEnd,
            dp_rec + "tank_data.vwater_end"       , qVolumeWaterEnd,

            dp_rec + "ModeCtrl"              , ModeCtrl);

      delay(10);
      int cur_is_sts;
//       dpGet("IS_" + is + ".PST_1.status", cur_is_sts);
//       if(cur_is_sts == 0x00 || 0x60){
   // Old query
        string query = "INSERT INTO [" + loc_database + "].[dbo].[vReceptionResult] " +
                       "(DateRecording, PostName, TankCode, DtStart, DtEnd, RecWeight, RecVolume, RecDensity, " +
                       "RecTemperature, RecDensityCoerced, RecVolumeCoerced, SumVolume, SumWeight, Volume, CompNbr, DispathOrder, sInvNum, OsProduct, iProcessed) " +
                       "VALUES ( GETDATE(), '" + PostName + "', " + TankCode + ", '" + formatTime("%Y-%m-%dT%H:%M:%S", DtStart) + "', '" + formatTime("%Y-%m-%dT%H:%M:%S", DtEnd) + "', " +
                                 RecWeight + ", " + RecVolume + ", " + RecDensity + ", " + RecTemperature + ", " + RecDensityCoerced + ", " + RecVolumeCoerced + ", " + SumVolumeEnd + ", " +
                                 SumWeightEnd + ", " + Volume + ", '" + CompNbr + "', '" + DispathOrder + "', '" + sInvNum + "', '" + OsProduct + "', 0);";
   // New query
        // string query = "INSERT INTO [" + loc_database + "].[dbo].[vReceptionResult] " +
        //                "(DateRecording, PostName, TankCode, DtStart, DtEnd, RecWeight, RecVolume, RecDensity, RecTemperature, RecDensityCoerced, RecVolumeCoerced, SumVolumeStart, SumVolumeEnd, SumWeightStart, SumWeightEnd, " +
        //                "Volume, CompNbr, DispathOrder, sInvNum, OsProduct, iProcessed, " + //, Fingerprint  

        //                "qTankLevelStartTo, qVolumeTankStartTo, qWeightTankStartTo, qDensityTankStartTo, qTempTankStartTo, qTankWaterLStartTo, qPressureStartTo, " + // start RVS section
        //                "qTankLevelEndTo, qVolumeTankEndTo, qWeightTankEndTo, qDensityTankEndTo, qTempTankEndTo, qTankWaterLEndTo, qPressureEndTo, " + // end RVS section
        //                "ModeCtrl) " +
        //                "Values(GETDATE(), '" + PostName + "', " + TankCode + ", '" + formatTime("%Y-%m-%dT%H:%M:%S", DtStart) + "', '" + formatTime("%Y-%m-%dT%H:%M:%S", DtEnd) + "', " +
        //                RecWeight + ", " + RecVolume + ", " + RecDensity + ", " + RecTemperature + ", " + RecDensityCoerced + ", " +
        //                RecVolumeCoerced + ", " + SumVolumeStart + ", " + SumVolumeEnd + ", " + SumWeightStart + ", " + SumWeightEnd + ", " +

        //                Volume + ", '" + CompNbr + "', '" + DispathOrder + "', '" + sInvNum + "', '" + OsProduct + "', 0, " + //, Fingerprint 

        //                qTankLevelStart + ", " + qVolumeTankStart + ", " + qWeightTankStart + ", " + qDensityTankStart + ", " + qTempTankStart + ", " + qTankWaterLStart + ", " + qPressureStart + ", " +  // start RVS values
        //                qTankLevelEnd + ", " + qVolumeTankEnd + ", " + qWeightTankEnd + ", " + qDensityTankEnd + ", " + qTempTankEnd + ", " + qTankWaterLEnd + ", " + qPressureEnd + ", " +  // end RVS values

        //                ModeCtrl + ");";
    // New query (NOYABRSK) 30.04.2021
        string query = "INSERT INTO [" + loc_database + "].[dbo].[vReceptionResult] " +
        "(DateRecording, PostName, TankCode, DtStart, DtEnd, RecWeight, RecVolume, RecDensity, " +

        DebugFTN("db_info", "RECEIVE | updateReceive query \n", query);
        dbStartCommand(con, query, cmd);
        dbExecuteCommand(cmd);
        DebugTN(getLastError());
        dbFinishCommand(cmd);
//       }else{
//
//       }
    }else{  // db open connection
      DebugTN("RECEIVE | Error connection database");
      traceErrors();
      changeActiveConnection(iConnection, mConfig);
    }
  }else{
    DebugFTN("lg_info", "This project NoActive(main)");
  }
}

main(string p1){
  if(p1 == "-RES"){
    dp_srv_act = "_ReduManager_2.EvStatus";
  }
  mConfig = getConnectionParams();
  dpConnect("cbDatabase", "_NB_CONFIG.ST");

  dpConnect("workerReceive", "Sybcom.Triggers.10s_Trigger"); // TODO: change trigger interval

  dpConnectUserData("updateReceive", 1, false, "LAST_RECEIVE_1.result.dt_end");
  dpConnectUserData("updateReceive", 2, false, "LAST_RECEIVE_2.result.dt_end");
  dpConnectUserData("updateReceive", 3, false, "LAST_RECEIVE_3.result.dt_end");
  dpConnectUserData("updateReceive", 4, false, "LAST_RECEIVE_4.result.dt_end");
}
