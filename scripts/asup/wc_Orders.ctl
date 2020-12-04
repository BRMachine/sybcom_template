// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author Admin_tobSSPD
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)

//--------------------------------------------------------------------------------
// variables and constants

//--------------------------------------------------------------------------------
/**

*/

public void normalizeQueryData(dyn_dyn_anytype &data){
  data.removeAt(0);
}

int getDozer(int device){
  int dozer = 0;
  /*
  dyn_string ds_dp;
  dyn_int di_conf;
  for(int i=1; i<=12; i++){
    ds_dp.append("ASN_" + line + ".Global_Variable.bui_PostDozator_" + i);
  }
  dpGet(ds_dp, di_conf);
  for(int i=1; i<=di_conf.count(); i++){
    if(di_conf[i] == post){
      dozer = i;
      break;
    }
  }
  */

  dpGet("POST_" + device + ".local.HelperDozer", dozer);
  return dozer;
}

void postAsnStart(int line, int section, int device){
  time rDtStart = getCurrentTime();
  anytype rSumVolumeStart,rSumWeightStart;
  dpGet("POST_" + device + ".xTotalMass"  , rSumWeightStart,
        "POST_" + device + ".xTotalValue" , rSumVolumeStart);

  dpSetWait("ORDER_LINE"+line+".items."+section+".result.SumVolumeStart" , rSumVolumeStart,
            "ORDER_LINE"+line+".items."+section+".result.SumWeightStart" , rSumWeightStart,
            "ORDER_LINE"+line+".items."+section+".result.DtStart"        , rDtStart);
}

int getPostRvs(int device){
  int tank = -1;
  dyn_int list_rvs;
  dpGet("POST_" + device + ".local.HelperRvs", list_rvs);
  for(int i=1; i<=list_rvs.count(); i++){
    int temp_sts;
    if(dpExists("LogicRVS_"+list_rvs[i] + ".STS.ststus_mes")){
      dpGet("LogicRVS_"+list_rvs[i] + ".STS.ststus_mes", temp_sts);
      if(temp_sts == 3){
        rTankCode = list_rvs[i];
        break;
      }
    }
  }
  return tank;
}

void postAsnStop(int line, int section, int device){
  anytype rDispatchOrder, rReceipId, rPostNumber, rRegistrationNumber, rSectionNumber, rOrderedVolume, rDispatchOrder, rOrderedWeight,
          rLoadedWeight, rLoadedVolume, rLoadedTemperature, rLoadedDensity,
          rLoadedBaseWeight, rLoadedBaseVolume, rLoadedBaseTemperature, rLoadedBaseDensity,
          rLoadedMixed1Weight, rLoadedMixed1Volume, rLoadedMixed1Temperature, rLoadedMixed1Density,
          rErrorCode, rResultCode ,rDtEnd, rSumVolumeEnd, rSumWeightEnd, rModeCtrl, rsHash;

  int dozer = getDozer(device);
  int rTankCode = getPostRvs(device);
  rDtEnd = getCurrentTime();
  rOrderedWeight = 0.0;

  dpGet("ORDER_LINE"+line+".items."+section+".init.sProductCode", rReceipId,
        "ORDER_LINE"+line+".items."+section+".init.sOrderNr"    , rDispatchOrder,
        "ORDER_LINE"+line+".items."+section+".init.Device"      , rPostNumber,
        "ORDER_LINE"+line+".items."+section+".init.sRegNr"      , rRegistrationNumber,
        "ORDER_LINE"+line+".items."+section+".init.iCompNr"     , rSectionNumber,
        "ORDER_LINE"+line+".items."+section+".init.iQuantity"   , rOrderedVolume,
        "POST_" + device + ".xAverageTemperature"               , rLoadedTemperature,
        "POST_" + device + ".xAverageDensity"                   , rLoadedDensity,
        "POST_" + device + ".xMassFact"                         , rLoadedBaseWeight,
        "POST_" + device + ".xVolumeFact"                       , rLoadedBaseVolume,
        "POST_" + device + ".xAverageTemperature"               , rLoadedBaseTemperature,
        "POST_" + device + ".xAverageDensity"                   , rLoadedBaseDensity,
        "POST_" + device + ".sErrorNaliv"                       , rErrorCode,
        "POST_" + device + ".sStatusStop"                       , rResultCode,
        "POST_" + device + ".xTotalValue"                       , rSumVolumeEnd,
        "POST_" + device + ".xTotalMass"                        , rSumWeightEnd,
        "ORDER_LINE"+line+".control"                            , rModeCtrl);

  if(dozer >0){
    dpGet("POST_" + dozer + ".xMassFact"                , rLoadedMixed1Weight,
          "POST_" + dozer + ".xVolumeFact"              , rLoadedMixed1Volume,
          "POST_" + dozer + ".xAverageTemperature"      , rLoadedMixed1Temperature,
          "POST_" + dozer + ".xAverageDensity"          , rLoadedMixed1Density);
  }else{
    rLoadedMixed1Weight       = 0;
    rLoadedMixed1Volume       = 0;
    rLoadedMixed1Temperature  = 0;
    rLoadedMixed1Density      = 0;
  }

  rLoadedVolume = rLoadedBaseVolume + rLoadedMixed1Volume;  // Проверить правильность
  rLoadedWeight = rLoadedBaseWeight + rLoadedMixed1Weight;  // Проверить правильность

  dpSetWait("ORDER_LINE"+line+".items."+section+".result.ReceipId"                , rReceipId,
            "ORDER_LINE"+line+".items."+section+".result.PostNumber"              , rPostNumber,
            "ORDER_LINE"+line+".items."+section+".result.TankCode"                , rTankCode,
            "ORDER_LINE"+line+".items."+section+".result.RegistrationNumber"      , rRegistrationNumber,
            "ORDER_LINE"+line+".items."+section+".result.SectionNumber"           , rSectionNumber,
            "ORDER_LINE"+line+".items."+section+".result.OrderedVolume"           , rOrderedVolume,
            "ORDER_LINE"+line+".items."+section+".result.LoadedWeight"            , rLoadedWeight,
            "ORDER_LINE"+line+".items."+section+".result.LoadedVolume"            , rLoadedVolume,
            "ORDER_LINE"+line+".items."+section+".result.LoadedTemperature"       , rLoadedTemperature,
            "ORDER_LINE"+line+".items."+section+".result.LoadedDensity"           , rLoadedDensity,
            "ORDER_LINE"+line+".items."+section+".result.LoadedBaseWeight"        , rLoadedBaseWeight,
            "ORDER_LINE"+line+".items."+section+".result.LoadedBaseVolume"        , rLoadedBaseVolume,
            "ORDER_LINE"+line+".items."+section+".result.LoadedBaseTemperature"   , rLoadedBaseTemperature,
            "ORDER_LINE"+line+".items."+section+".result.LoadedBaseDensity"       , rLoadedBaseDensity,
            "ORDER_LINE"+line+".items."+section+".result.LoadedMixed1Weight"      , rLoadedMixed1Weight,
            "ORDER_LINE"+line+".items."+section+".result.LoadedMixed1Volume"      , rLoadedMixed1Volume,
            "ORDER_LINE"+line+".items."+section+".result.LoadedMixed1Temperature" , rLoadedMixed1Temperature,
            "ORDER_LINE"+line+".items."+section+".result.LoadedMixed1Density"     , rLoadedMixed1Density,
            "ORDER_LINE"+line+".items."+section+".result.ErrorCode"               , rErrorCode,
            "ORDER_LINE"+line+".items."+section+".result.ResultCode"              , rResultCode,
            "ORDER_LINE"+line+".items."+section+".result.SumVolumeEnd"            , rSumVolumeEnd,
            "ORDER_LINE"+line+".items."+section+".result.SumWeightEnd"            , rSumWeightEnd,
            "ORDER_LINE"+line+".items."+section+".result.ModeCtrl"                , rModeCtrl,
            "ORDER_LINE"+line+".items."+section+".result.DtEnd"                   , rDtEnd,
            "ORDER_LINE"+line+".items."+section+".result.OrderedWeight"           , rOrderedWeight);
}

void worker(int line, string dp, int card){
  int order_sts;
  string order_card;
  dyn_dyn_anytype items;   // 0 - iCompNr | 1 - iQuantity | 2 - iProcessed | 3 - Device | 4 - iPercent
  dyn_int prev_post_sts = makeDynInt(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
  string query = "SELECT '_original.._value' "+
                 "FROM '{ORDER_LINE"+line+".items.?.init.Device,"+        // 3 - Пост
                        "ORDER_LINE"+line+".items.?.init.iCompNr,"+       // 0 - Секция
                        "ORDER_LINE"+line+".items.?.init.iProcessed,"+    // 2 - Состояние (0 - новое, 1 - налив, 2 - завершено)
                        "ORDER_LINE"+line+".items.?.init.iQuantity,"+     // 1 - Объем (л) в задании
                        "ORDER_LINE"+line+".items.?.init.iPercent}'";     // 4 - Процент присадки (если используется)

  dpGet("ORDER_LINE" + line + ".iProcessed", order_sts,  // состояние задания (0 - новое, 1 - налив, 2 - завершено)
        "ORDER_LINE" + line + ".sIdCard", order_card);   // Номер карты водителя из задания
  if(card == order_card)
    DebugFTN("lg_info", "WC_ORDERS | Order and driver cards is equals");
  else
    DebugTN("WC_ORDERS | Order and driver cards NOT equals", order_card, card);

// Цикл налива задания
  while(order_sts < 2 & order_card == card){   // Пока налив задание не налито
    dpGet("ORDER_LINE" + line + ".iProcessed", order_sts,  // состояние задания (0 - новое, 1 - налив, 2 - завершено)
          "ORDER_LINE" + line + ".sIdCard", order_card);   // Номер карты водителя из задания
    dpQuery(query, items);
    normalizeQueryData(items);
// Перебор секций в задании
    for(int i=1; i<=items.count(); i+=5){
      int device = items[i+3][2];
      int post_sts;
      // Если секция была в задании
      if(items[i+2][2] != 99){
        dpGet("POST_" + device + ".sStatusPosta", post_sts);
        // Налив по секции завершен
        if(prev_post_sts[items[i+0][2]] == 0x20 & post_sts == 0x00 & items[i+2][2] == 1 ){
          postAsnStop(line, items[i+0][2], device);
          dpSetWait(items[i+2][1], 2);
        }
        // Запись предыдущего состояние поста
        if(items[i+2][2] > 0){
          prev_post_sts[items[i+0][2]] = post_sts;
        }
      }else{ // (items[i+2][2] != 99)
        // Секции небыло в задании
        continue;
      }
      // Секция была в задании и пост свободен
      if(items[i+2][2] == 0 & post_sts == 0x00){
        bool prisadka = (items[i+4][2] > 0);
        dpSetWait("POST_" + device + ".cVolumeDose"       , items[i+1][2],
                  "POST_" + device + ".сPrisadka"         , prisadka,
                  "POST_" + device + ".cPercentPrisadki"  , items[i+4][2],
                  "POST_" + device + ".sStatusPosta"      , 0x10,
                  items[i+2][1], 1);
        postAsnStart(line, items[i+0][2], device);
      }
//       delay(5); // Для опроса АСН по modbus
    }
    // Проверка завершения налива задания
    int sts_itm1, sts_itm2, sts_itm3, sts_itm4, sts_itm5,
        sts_itm6, sts_itm7, sts_itm8, sts_itm9, sts_itm0;
    dpGet("ORDER_LINE1.items.1.init.iProcessed" , sts_itm1,
          "ORDER_LINE1.items.2.init.iProcessed" , sts_itm2,
          "ORDER_LINE1.items.3.init.iProcessed" , sts_itm3,
          "ORDER_LINE1.items.4.init.iProcessed" , sts_itm4,
          "ORDER_LINE1.items.5.init.iProcessed" , sts_itm5,
          "ORDER_LINE1.items.6.init.iProcessed" , sts_itm6,
          "ORDER_LINE1.items.7.init.iProcessed" , sts_itm7,
          "ORDER_LINE1.items.8.init.iProcessed" , sts_itm8,
          "ORDER_LINE1.items.9.init.iProcessed" , sts_itm9,
          "ORDER_LINE1.items.10.init.iProcessed", sts_itm0);
    if(sts_itm1 > 1 & sts_itm2 > 1 & sts_itm3 > 1 & sts_itm4 > 1 & sts_itm5 > 1 &
       sts_itm6 > 1 & sts_itm7 > 1 & sts_itm8 > 1 & sts_itm9 > 1 & sts_itm0 > 1){
      dpSetWait("ORDER_LINE" + line + ".iProcessed", 2);
    }
    DebugFTN("lg_info", "WC_ORDERS | ========================END WHILE======================");
    delay(2);
  }
    DebugFTN("lg_info", "WC_ORDERS | =======================END СCONNECT====================");
}

main()
{
  dpConnectUserData("worker", 1, false, "ORDER_LINE1.current_card");
  dpConnectUserData("worker", 2, false, "ORDER_LINE2.current_card");
  dpConnectUserData("worker", 3, false, "ORDER_LINE3.current_card");
//   dpConnectUserData("worker", 4, false, "ORDER_LINE4.current_card");
//   dpConnectUserData("worker", 5, false, "ORDER_LINE5.current_card");
//   dpConnectUserData("worker", 6, false, "ORDER_LINE6.current_card");
}
