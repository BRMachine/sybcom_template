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
// dyn_dyn_string dds_cur_post;
// dyn_int prev_sect = makeDynInt(0,0,0);
string dp_srv_act = "_ReduManager.EvStatus";      // Для основного сервера

//--------------------------------------------------------------------------------
/**

*/

public void normalizeQueryData(dyn_dyn_anytype &data){
  data.removeAt(0);
}

int getDozer(int device){
  int dozer = 0;
  dpGet("Post_" + device + ".local.HelperDozer", dozer);
  return dozer;
}

void postAsnStart(int line, int section, int device){
  time rDtStart = getCurrentTime();
  anytype rSumVolumeStart,rSumWeightStart;
  int numdoz = getDozer(device);
  anytype SumVolumeStartpr, Delivery;
  int num_rvs = getPostRvs(device);
  mapping resrvs = getRvsData(num_rvs);

  dpGet("Post_" + device + ".xTotalMass"  , rSumWeightStart,
        "Post_" + device + ".xTotalValue" , rSumVolumeStart,
        "ORDER_LINE"+line+".items."+section+".init.sDelivery"     , Delivery);

  if (numdoz > 0){
    dpGet("Post_" +numdoz + ".xTotalValue"  , SumVolumeStartpr);
  }   else{
    SumVolumeStartpr = 0;
  }

  dpSetWait("ORDER_LINE"+line+".items."+section+".result.SumVolumeStart"     , rSumVolumeStart,
            "ORDER_LINE"+line+".items."+section+".result.SumWeightStart"     , rSumWeightStart,
            "ORDER_LINE"+line+".items."+section+".result.DtStart"            , rDtStart,
            "ORDER_LINE"+line+".items."+section+".result.SumVolumeStartpr"   , SumVolumeStartpr,
            "ORDER_LINE"+line+".items."+section+".result.qTankLevelStart"    , resrvs["lvl"],
            "ORDER_LINE"+line+".items."+section+".result.qVolumeTankStart"   , resrvs["vol"],
            "ORDER_LINE"+line+".items."+section+".result.qWeightTankStart"   , resrvs["mas"],
            "ORDER_LINE"+line+".items."+section+".result.qDensityTankStart"  , resrvs["dns"],
            "ORDER_LINE"+line+".items."+section+".result.qTempTankStart"     , resrvs["tmp"],
            "ORDER_LINE"+line+".items."+section+".result.qPressureStart"     , resrvs["prs"],
            "ORDER_LINE"+line+".items."+section+".result.qLevelWaterStart"   , resrvs["wtr"],
            "Post_"+device+".MES.TimeStart"                                  , getCurrentTime(),
            "Post_"+device+".MES.sDelivery"                                  , Delivery,
            "Post_"+device+".MES.numSection"                                 , section);
}

private int getPostRvs(int post){
  int res = 0;
  dyn_int di_postRvs;
  dpGet("Post_" + post + ".local.HelperRvs", di_postRvs);
  for(int i=1; i<=di_postRvs.count(); i++){
    int tmp_sts;
    dpGet("LogicRVS_" + di_postRvs[i] + ".STS.status_mes", tmp_sts);
    if(tmp_sts == 3){
      res = di_postRvs[i];
      break;
    }
  }
  return res;
}

void postAsnStop(int line, int section, int device){
  anytype rDispatchOrder, rReceipId, rPostNumber, rRegistrationNumber, rSectionNumber, rOrderedVolume, rDispatchOrder, rOrderedWeight,
          rLoadedWeight, rLoadedVolume, rLoadedTemperature, rLoadedDensity,
          rLoadedBaseWeight, rLoadedBaseVolume, rLoadedBaseTemperature, rLoadedBaseDensity,
          rLoadedMixed1Weight, rLoadedMixed1Volume, rLoadedMixed1Temperature, rLoadedMixed1Density,
          rErrorCode, rResultCode ,rDtEnd, rSumVolumeEnd, rSumWeightEnd, rModeCtrl, rsHash, SumVolumeEndpr, idCard, iPercent;

  int dozer = getDozer(device);       // Номер поста дозатора
  int rTankCode = getPostRvs(device); //РВС, который в отпуске
  rDtEnd = getCurrentTime();
  rOrderedWeight = 0.0;
  rLoadedMixed1Volume = 0.0;

  mapping resrvs = getRvsData(rTankCode);
  dpGet("ORDER_LINE"+line+".items."+section+".init.sProductCode", rReceipId,
        "ORDER_LINE"+line+".items."+section+".init.sOrderNr"    , rDispatchOrder,
        "ORDER_LINE"+line+".items."+section+".init.Device"      , rPostNumber,
        "ORDER_LINE"+line+".items."+section+".init.sRegNr"      , rRegistrationNumber,
        "ORDER_LINE"+line+".items."+section+".init.iCompNr"     , rSectionNumber,
        "ORDER_LINE"+line+".items."+section+".init.iQuantity"   , rOrderedVolume,
        "ORDER_LINE"+line+".items."+section+".init.iPercent"    , iPercent,
        "Post_" + device + ".xAverageTemperature"               , rLoadedTemperature,
        "Post_" + device + ".xAverageDensity"                   , rLoadedDensity,
        "Post_" + device + ".xMassFact"                         , rLoadedBaseWeight,
        "Post_" + device + ".xVolumeFact"                       , rLoadedBaseVolume,
        "Post_" + device + ".xAverageTemperature"               , rLoadedBaseTemperature,
        "Post_" + device + ".xAverageDensity"                   , rLoadedBaseDensity,
        "Post_" + device + ".sErrorNaliv"                       , rErrorCode,
        "Post_" + device + ".sStatusStop"                       , rResultCode,
        "Post_" + device + ".xTotalValue"                       , rSumVolumeEnd,
        "Post_" + device + ".xTotalMass"                        , rSumWeightEnd,
        "ORDER_LINE"+line+".control"                            , rModeCtrl,
        "ORDER_LINE"+line+".sIdCard"                            , idCard);

  if(dozer > 0 & iPercent > 0){
     dpGet("Post_" + dozer + ".xVolumeFact"              , rLoadedMixed1Volume,
           "Post_" + dozer + ".MES.DensityPr"            , rLoadedMixed1Density,
           "Post_" + dozer + ".xTotalValue"              , SumVolumeEndpr);
  }else{
    rLoadedMixed1Weight       = 0;
    rLoadedMixed1Volume       = 0;
    rLoadedMixed1Temperature  = 0;
    rLoadedMixed1Density      = 0;
  }
// Расчет присадки
  rLoadedMixed1Volume = rLoadedMixed1Volume / 1000;
  rLoadedMixed1Temperature = rLoadedBaseTemperature;
  if(rLoadedMixed1Density > 1)
    rLoadedMixed1Weight = rLoadedMixed1Volume * (rLoadedMixed1Density/1000);
  else
    rLoadedMixed1Weight = rLoadedMixed1Volume * rLoadedMixed1Density;
// Расчет брендированого топлива
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
            "ORDER_LINE"+line+".items."+section+".result.OrderedWeight"           , rOrderedWeight,
//            "ORDER_LINE"+line+".items."+section+".result.qTankLevelEnd"           , resrvs["lvl"],
            "ORDER_LINE"+line+".items."+section+".result.qVolumeTankEnd"          , resrvs["vol"],
            "ORDER_LINE"+line+".items."+section+".result.qWeightTankEnd"          , resrvs["mas"],
            "ORDER_LINE"+line+".items."+section+".result.qDensityTankEnd"         , resrvs["dns"],
            "ORDER_LINE"+line+".items."+section+".result.qTempTankEnd"            , resrvs["tmp"],
            "ORDER_LINE"+line+".items."+section+".result.qPressureEnd"            , resrvs["prs"],
            "ORDER_LINE"+line+".items."+section+".result.qLevelWaterEnd"          , resrvs["wtr"],
            "ORDER_LINE"+line+".items."+section+".result.qCardID"                 , idCard,
            "ORDER_LINE"+line+".items."+section+".result.qNbrLine"                , line,
            "ORDER_LINE"+line+".items."+section+".result.SumVolumeEndpr"          , SumVolumeEndpr,
            "Post_"+device+".MES.TimeEnd"                                         , getCurrentTime());
}

void worker(int line, string dp, int card){
  bool temp_srv;
  dpGet(dp_srv_act, temp_srv);
  if(temp_srv){
    int order_sts;
    bool init;
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
    if(card == (int)order_card | (int)order_card == 0 | order_card == "getCard") //После интеграции МЕС (водители будут везде прикладывать карты) перенести условие из if в while 231 строки (цикл налива задания).
      DebugFTN("lg_info", "WC_ORDERS | Order and driver cards is equals");
    else
      DebugTN("WC_ORDERS | Order and driver cards NOT equals", order_card, card);

  // Цикл налива задания
    while(order_sts < 2){ //& order_card == card)   // Пока налив задание не налито
      dpGet("ORDER_LINE" + line + ".iProcessed", order_sts,  // состояние задания (0 - новое, 1 - налив, 2 - завершено)
            "ORDER_LINE" + line + ".sIdCard", order_card);   // Номер карты водителя из задания
      if(!init){
         dpSetWait("ORDER_LINE"+line+".TimeStart", getCurrentTime());
         init = !init;
       }
      dpQuery(query, items);
      normalizeQueryData(items);
  // Перебор секций в задании
      for(int i=1; i<=items.count(); i+=5){
        DebugFTN("lg_info", "ITEM", items[i+0][2], items[i+1][2], items[i+2][2], items[i+3][2], items[i+4][2]);
        int device = items[i+3][2];
        int post_sts;
        // Если секция была в задании и секция еще не налита
        if(items[i+2][2] < 2){
          dpGet("Post_" + device + ".sStatusPosta", post_sts);
          // Налив по секции завершен
          if((prev_post_sts[items[i+0][2]] == 0x20 | prev_post_sts[items[i+0][2]] == 0x10 | prev_post_sts[items[i+0][2]] == 0x30) &
            post_sts == 0x00 & items[i+2][2] == 1 ){
            delay(40);
            DebugFTN("lg_info", "WC_ORDERS | End section: ", items[i+2][1]);
            postAsnStop(line, items[i+0][2], device);
            dpSetWait(items[i+2][1], 2);
            if(post_sts == 0x60){
              dpSetWait("ORDER_LINE"+line+".ErrorCode", 0-i);
            }
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
  //       if((items[i+2][2] == 0 & post_sts == 0x00) | (items[i+2][2] == 1 & post_sts == 0x00 & prev_post_sts[items[i+0][2]] == 0x00))
        if(items[i+2][2] == 0 & post_sts == 0x00){
          bool prisadka = (items[i+4][2] > 0);
          DebugFTN("lg_info", "WC_ORDERS | Start section: ", items[i+2][1]);
          anytype post_dose, post_prisadka, post_percent, post_status;
          int count_while;
          dpSetWait("Post_" + device + ".cVolumeDose"       , items[i+1][2],
                    "Post_" + device + ".сPrisadka"         , prisadka,
                    "Post_" + device + ".cPercentPrisadki"  , items[i+4][2],
                    "Post_" + device + ".cCommand"          , 0x10,
                    items[i+2][1], 1);
          delay(40); // Для опроса АСН по modbus
          postAsnStart(line, items[i+0][2], device);
        }

        // Перекладка данных в ORDERS_PV
        if(items[i+2][2] == 1){
          anytype vol_base, vol_doser, mas_base, temp, density;
          dpGet("Post_" + device + ".xVolumeFact"          , vol_base,
                "Post_" + getDozer(device) + ".xVolumeFact", vol_doser,
                "Post_" + device + ".xMassFact"            , mas_base,
                "Post_" + device + ".xAverageTemperature"  , temp,
                "Post_" + device + ".xAverageDensity"      , density);
          if(items[i+4][2]<=0) { vol_doser = 0; }

          dpSetWait("LINE" + line + "_PV."+items[i+0][2]+".vol_base", vol_base,
                    "LINE" + line + "_PV."+items[i+0][2]+".vol_doser", vol_doser,
                    "LINE" + line + "_PV."+items[i+0][2]+".mas_base", mas_base,
                    "LINE" + line + "_PV."+items[i+0][2]+".temp", temp,
                    "LINE" + line + "_PV."+items[i+0][2]+".density", density);
        }
      }
      // Проверка завершения налива задания
      int sts_itm1, sts_itm2, sts_itm3, sts_itm4, sts_itm5,
          sts_itm6, sts_itm7, sts_itm8, sts_itm9, sts_itm0;
      dpGet("ORDER_LINE"+line+".items.1.init.iProcessed" , sts_itm1,
            "ORDER_LINE"+line+".items.2.init.iProcessed" , sts_itm2,
            "ORDER_LINE"+line+".items.3.init.iProcessed" , sts_itm3,
            "ORDER_LINE"+line+".items.4.init.iProcessed" , sts_itm4,
            "ORDER_LINE"+line+".items.5.init.iProcessed" , sts_itm5,
            "ORDER_LINE"+line+".items.6.init.iProcessed" , sts_itm6,
            "ORDER_LINE"+line+".items.7.init.iProcessed" , sts_itm7,
            "ORDER_LINE"+line+".items.8.init.iProcessed" , sts_itm8,
            "ORDER_LINE"+line+".items.9.init.iProcessed" , sts_itm9,
            "ORDER_LINE"+line+".items.10.init.iProcessed", sts_itm0);
      if(sts_itm1 > 1 & sts_itm2 > 1 & sts_itm3 > 1 & sts_itm4 > 1 & sts_itm5 > 1 &
          sts_itm6 > 1 & sts_itm7 > 1 & sts_itm8 > 1 & sts_itm9 > 1 & sts_itm0 > 1){
        dpSetWait("ORDER_LINE" + line + ".iProcessed", 2,
                  "ORDER_LINE"+line+".TimeEnd", getCurrentTime());
      }
      DebugFTN("lg_info", "WC_ORDERS | ========================END WHILE======================");
      delay(2);
    }
    DebugFTN("lg_info", "WC_ORDERS | =======================END СCONNECT====================");
  }
}

private mapping getRvsData(int rvs_num){
  mapping res = makeMapping("lvl", 0.0, "vol", 0.0,
                            "mas", 0.0, "dns", 0.0,
                            "tmp", 0.0, "wtr", 0.0,
                            "prs", 0.0
                            );
  if(rvs_num > 0){
    dpGet("RVS_" + rvs_num + ".LVL.val"    , res["lvl"],
          "RVS_" + rvs_num + ".VOL.val"    , res["vol"],
          "RVS_" + rvs_num + ".MAS.val"    , res["mas"],
          "RVS_" + rvs_num + ".DNS.val"    , res["dns"],
          "RVS_" + rvs_num + ".TMP.val"    , res["tmp"],
          "RVS_" + rvs_num + ".WTR.val"    , res["wtr"],
          "RVS_" + rvs_num + ".VPR.PRS.val", res["prs"]);
  }
  return res;
}

main(string p1){
  if(p1 == "-RES"){ dp_srv_act = "_ReduManager_2.EvStatus"; }
//   string query_order1 = "SELECT '_original.._value' FROM 'ORDER_LINE1.items.*.init.iProcessed'",
//          query_order2 = "SELECT '_original.._value' FROM 'ORDER_LINE2.items.*.init.iProcessed'",
//          query_order3 = "SELECT '_original.._value' FROM 'ORDER_LINE3.items.*.init.iProcessed'";
//
//   for(int i=1; i<=10; i++){
//     dds_cur_post.append(makeDynString());
//   }
//
  dpConnectUserData("worker", 1, false, "ORDER_LINE1.current_card");
  dpConnectUserData("worker", 2, false, "ORDER_LINE2.current_card");
  dpConnectUserData("worker", 3, false, "ORDER_LINE3.current_card");
  dpConnectUserData("worker", 4, false, "ORDER_LINE4.current_card");
  dpConnectUserData("worker", 5, false, "ORDER_LINE5.current_card");
  dpConnectUserData("worker", 6, false, "ORDER_LINE6.current_card");

//   dpQueryConnectSingle("worker_order", false, 1, query_order1);
}
