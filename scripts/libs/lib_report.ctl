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
//--------------------------------------------------------------------------------
// variables and constants
const string CONNECTION_LINE = "DSN=ASUP_NB;UID=sa;PWD=Qwerty123;";

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
//Забрать данные из БД по приему при открытии мнемосхемы отчета.
dyn_dyn_string recieve_data(string query){
    string temp;
    dyn_string ID, DateRecording, PostName, PumpNr, TankCode, RecWeight, RecVolume, RecDensity,
           RecTemperature, RecDensityCoerced, RecVolumeCoerced, SumVolume, SumWeight, DtStart, DtEnd,
           Volume, CompNbr, DispathOrder, slnvNum, OsProduct, iProcessed, Fingerprint;
//     string query = "SELECT TOP 10 * FROM [ASU_MES_DB].[dbo].[vReceptionResult] ORDER BY id DESC;";
    dbConnection con;
    dbRecordset rs;
    int res = dbOpenConnection(CONNECTION_LINE, con);
    if(!res){
      res = dbOpenRecordset(con, query, rs);
      if(!res){
        while(!res && !dbEOF(rs)){
          dbGetField(rs, 0, temp);
          ID.append(temp);
          dbGetField(rs, 1, temp);
          DateRecording.append(temp);
          dbGetField(rs, 2, temp);
          PostName.append(temp);
          dbGetField(rs, 3, temp);
          PumpNr.append(temp);
          dbGetField(rs, 4, temp);
          TankCode.append(temp);
          dbGetField(rs, 5, temp);
          RecWeight.append(temp);
          dbGetField(rs, 6, temp);
          RecVolume.append(temp);
          dbGetField(rs, 7, temp);
          RecDensity.append(temp);
          dbGetField(rs, 8, temp);
          RecTemperature.append(temp);
          dbGetField(rs, 9, temp);
          RecDensityCoerced.append(temp);
          dbGetField(rs, 10, temp);
          RecVolumeCoerced.append(temp);
          dbGetField(rs, 11, temp);
          SumVolume.append(temp);
          dbGetField(rs, 12, temp);
          SumWeight.append(temp);
          dbGetField(rs, 13, temp);
          DtStart.append(temp);
          dbGetField(rs, 14, temp);
          DtEnd.append(temp);
          dbGetField(rs, 15, temp);
          Volume.append(temp);
          dbGetField(rs, 16, temp);
          CompNbr.append(temp);
          dbGetField(rs, 17, temp);
          DispathOrder.append(temp);
          dbGetField(rs, 18, temp);
          slnvNum.append(temp);
          dbGetField(rs, 19, temp);
          OsProduct.append(temp);
          dbGetField(rs, 20, temp);
          iProcessed.append(temp);
          dbGetField(rs, 21, temp);
          Fingerprint.append(temp);
          dbMoveNext(rs);
        }
        dbCloseRecordset(rs);
      }else{ // Error Query
      dyn_errClass err = getLastError();
      if(dynlen(err)>0){
        for(int i = 1; i<=dynlen(err); i++){
          DebugTN("db_error", err[i]);
        }
      }
    }
    dbCloseConnection(con);
    dyn_dyn_string data_str;
    data_str.append(ID);
    data_str.append(DateRecording);
    data_str.append(PostName);
    data_str.append(PumpNr);
    data_str.append(TankCode);
    data_str.append(RecWeight);
    data_str.append(RecVolume);
    data_str.append(RecDensity);
    data_str.append(RecTemperature);
    data_str.append(RecDensityCoerced);
    data_str.append(RecVolumeCoerced);
    data_str.append(SumVolume);
    data_str.append(SumWeight);
    data_str.append(DtStart);
    data_str.append(DtEnd);
    data_str.append(Volume);
    data_str.append(CompNbr);
    data_str.append(DispathOrder);
    data_str.append(slnvNum);
    data_str.append(OsProduct);
    data_str.append(iProcessed);
    data_str.append(Fingerprint);
    return data_str;
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
    string temp;
    dyn_string ID, DateRecording, RecipeId, PostNumber, TankCode, RegistrationNumber, SectionNumber,
               OrderedVolume, OrderedWeight, LoadedVolume, LoadedWeight, LoadedTemperature,
               LoadedDensity, LoadedBaseVolume, LoadedBaseWeight, LoadedBaseTemp, LoadedBaseDensity,
               LoadedMixed1Volume, LoadedMixed1Temp, LoadedMixed1Density, LoadedMixed1Weight, DtStart,
               DtEnd, SumVolumeStart, SumVolumeEnd, SumWeightStart, SumWeightEnd, ModeCtrl;
//     string query = "SELECT TOP 10 * FROM [ASU_MES_DB].[dbo].[vReceptionResult] ORDER BY id DESC;";
    dbConnection con;
    dbRecordset rs;
    int res = dbOpenConnection(CONNECTION_LINE, con);
    if(!res){
      res = dbOpenRecordset(con, query, rs);
      if(!res){
        while(!res && !dbEOF(rs)){
          dbGetField(rs, 0, temp);
          ID.append(temp);
          dbGetField(rs, 1, temp);
          DateRecording.append(temp);
          dbGetField(rs, 2, temp);
          RecipeId.append(temp);
          dbGetField(rs, 3, temp);
          PostNumber.append(temp);
          dbGetField(rs, 4, temp);
          TankCode.append(temp);
          dbGetField(rs, 5, temp);
          RegistrationNumber.append(temp);
          dbGetField(rs, 6, temp);
          SectionNumber.append(temp);
          dbGetField(rs, 7, temp);
          OrderedVolume.append(temp);
          dbGetField(rs, 8, temp);
          OrderedWeight.append(temp);
          dbGetField(rs, 9, temp);
          LoadedVolume.append(temp);
          dbGetField(rs, 10, temp);
          LoadedWeight.append(temp);
          dbGetField(rs, 11, temp);
          LoadedTemperature.append(temp);
          dbGetField(rs, 12, temp);
          LoadedDensity.append(temp);
          dbGetField(rs, 13, temp);
          LoadedBaseVolume.append(temp);
          dbGetField(rs, 14, temp);
          LoadedBaseWeight.append(temp);
          dbGetField(rs, 15, temp);
          LoadedBaseTemp.append(temp);
          dbGetField(rs, 16, temp);
          LoadedBaseDensity.append(temp);
          dbGetField(rs, 17, temp);
          LoadedMixed1Volume.append(temp);
          dbGetField(rs, 18, temp);
          LoadedMixed1Temp.append(temp);
          dbGetField(rs, 19, temp);
          LoadedMixed1Density.append(temp);
          dbGetField(rs, 20, temp);
          LoadedMixed1Weight.append(temp);
          dbGetField(rs, 27, temp);
          DtStart.append(temp);
          dbGetField(rs, 28, temp);
          DtEnd.append(temp);
          dbGetField(rs, 29, temp);
          SumVolumeStart.append(temp);
          dbGetField(rs, 30, temp);
          SumVolumeEnd.append(temp);
          dbGetField(rs, 31, temp);
          SumWeightStart.append(temp);
          dbGetField(rs, 32, temp);
          SumWeightEnd.append(temp);
          dbGetField(rs, 33, temp);
          ModeCtrl.append(temp);
          dbMoveNext(rs);
        }
        dbCloseRecordset(rs);
      }else{ // Error Query
      dyn_errClass err = getLastError();
      if(dynlen(err)>0){
        for(int i = 1; i<=dynlen(err); i++){
          DebugTN("db_error", err[i]);
        }
      }
    }
    dbCloseConnection(con);
    dyn_dyn_string data_str;
    data_str.append(ID);
    data_str.append(DateRecording);
    data_str.append(RecipeId);
    data_str.append(PostNumber);
    data_str.append(TankCode);
    data_str.append(RegistrationNumber);
    data_str.append(SectionNumber);
    data_str.append(OrderedVolume);
    data_str.append(OrderedWeight);
    data_str.append(LoadedVolume);
    data_str.append(LoadedWeight);
    data_str.append(LoadedTemperature);
    data_str.append(LoadedDensity);
    data_str.append(LoadedBaseVolume);
    data_str.append(LoadedBaseWeight);
    data_str.append(LoadedBaseTemp);
    data_str.append(LoadedBaseDensity);
    data_str.append(LoadedMixed1Volume);
    data_str.append(LoadedMixed1Temp);
    data_str.append(LoadedMixed1Density);
    data_str.append(LoadedMixed1Weight);
    data_str.append(DtStart);
    data_str.append(DtEnd);
    data_str.append(SumVolumeStart);
    data_str.append(SumVolumeEnd);
    data_str.append(SumWeightStart);
    data_str.append(SumWeightEnd);
    data_str.append(ModeCtrl);
    return data_str;
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

