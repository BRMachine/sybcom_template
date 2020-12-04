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

int deviceToPost(int device){
  int post = -1;
  if(device>0){
    dyn_int num_mes, num_line, num_post;
    dpGet("MES_HELPER.ASN_HELPER.num_mes"  , num_mes,
          "MES_HELPER.ASN_HELPER.num_line" , num_line,
          "MES_HELPER.ASN_HELPER.num_post" , num_post);
    for(int i=1; i<=num_mes.count(); i++){
      DebugFTN("lg_info", "WC_ORDERS | device to post", num_mes[i], device, num_post[i]);
      if(num_mes[i] == device){
        post = num_post[i];
        break;
      }
    }
  }
  return post;
}

int deviceToLine(int device){
  int line = -1;
  if(device>0){
    dyn_int num_mes, num_line, num_post;
    dpGet("MES_HELPER.ASN_HELPER.num_mes"  , num_mes,
          "MES_HELPER.ASN_HELPER.num_line" , num_line,
          "MES_HELPER.ASN_HELPER.num_post" , num_post);
    for(int i=1; i<=num_mes.count(); i++){
      DebugFTN("lg_info", "WC_ORDERS | device to line", num_mes[i], device, num_line[i]);
      if(num_mes[i] == device){
        line = num_line[i];
        break;
      }
    }
  }
  return line;
}

int getDozer(int line, int post){
  int dozer = -1;
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
  return dozer;
}
void postAsnStart(int line, int post, int section){
  time rDtStart = getCurrentTime();
  anytype rSumVolumeStart,rSumWeightStart;
  dpGet("ASN_"+line+".Post"+post+".xTotalMass", rSumWeightStart,
        "ASN_"+line+".Post"+post+".xTotalValue", rSumVolumeStart);
  dpSetWait("ORDER_LINE"+line+".items."+section+".result.SumVolumeStart", rSumVolumeStart,
            "ORDER_LINE"+line+".items."+section+".result.SumWeightStart", rSumWeightStart,
            "ORDER_LINE"+line+".items."+section+".result.DtStart", rDtStart);

}

void postAsnStop(int line, int post, int section, int dozer){
  int doz_pst = 1; // = dozer+6;
  anytype rDispatchOrder, rReceipId, rPostNumber, rRegistrationNumber, rSectionNumber, rOrderedVolume, rDispatchOrder, rOrderedWeight,
          rLoadedWeight, rLoadedVolume, rLoadedTemperature, rLoadedDensity,
          rLoadedBaseWeight, rLoadedBaseVolume, rLoadedBaseTemperature, rLoadedBaseDensity,
          rLoadedMixed1Weight, rLoadedMixed1Volume, rLoadedMixed1Temperature, rLoadedMixed1Density,
          rErrorCode, rResultCode ,rDtEnd, rSumVolumeEnd, rSumWeightEnd, rModeCtrl, rsHash;
  dyn_int list_rvs;
  int rTankCode = -1;
  dpGet("ASN_"+line+".Post"+post+".HelperRvs", list_rvs);
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
  rDtEnd = getCurrentTime();
  rOrderedWeight = 0.0;
  dpGet("ORDER_LINE"+line+".items."+section+".init.sProductCode", rReceipId,
        "ORDER_LINE"+line+".items."+section+".init.sOrderNr"    , rDispatchOrder,
        "ORDER_LINE"+line+".items."+section+".init.Device"      , rPostNumber,
        "ORDER_LINE"+line+".items."+section+".init.sRegNr"      , rRegistrationNumber,
        "ORDER_LINE"+line+".items."+section+".init.iCompNr"     , rSectionNumber,
        "ORDER_LINE"+line+".items."+section+".init.iQuantity"   , rOrderedVolume,
        "ASN_"+line+".Post"+post+".xAverageTemperature"         , rLoadedTemperature,
        "ASN_"+line+".Post"+post+".xAverageDensity"             , rLoadedDensity,
        "ASN_"+line+".Post"+post+".xMassFact"                   , rLoadedBaseWeight,
        "ASN_"+line+".Post"+post+".xVolumeFact"                 , rLoadedBaseVolume,
        "ASN_"+line+".Post"+post+".xAverageTemperature"         , rLoadedBaseTemperature,
        "ASN_"+line+".Post"+post+".xAverageDensity"             , rLoadedBaseDensity,
        "ASN_"+line+".Post"+doz_pst+".xMassFact"                , rLoadedMixed1Weight,
        "ASN_"+line+".Post"+doz_pst+".xVolumeFact"              , rLoadedMixed1Volume,
        "ASN_"+line+".Post"+doz_pst+".xAverageTemperature"      , rLoadedMixed1Temperature,
        "ASN_"+line+".Post"+doz_pst+".xAverageDensity"          , rLoadedMixed1Density,
        "ASN_"+line+".Post"+post+".sErrorNaliv"                 , rErrorCode,
        "ASN_"+line+".Post"+post+".sStatusStop"                 , rResultCode,
        "ASN_"+line+".Post"+post+".xTotalValue"                 , rSumVolumeEnd,
        "ASN_"+line+".Post"+post+".xTotalMass"                  , rSumWeightEnd,
        "ORDER_LINE"+line+".control"                            , rModeCtrl);
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

void worker(int line, string dp, int card05){
  int order_sts;
  string driver_card;
  dyn_dyn_anytype items;
  string query = "SELECT '_original.._value' "+
                 "FROM '{ORDER_LINE"+line+".items.?.init.Device,"+
                        "ORDER_LINE"+line+".items.?.init.iCompNr,"+
                        "ORDER_LINE"+line+".items.?.init.iProcessed,"+
                        "ORDER_LINE"+line+".items.?.init.iQuantity,"+
                        "ORDER_LINE"+line+".items.?.init.iPercent}'";

  dyn_int prev_post_sts = makeDynInt(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
  while(order_sts < 2){
    dpGet("ORDER_LINE" + line + ".iProcessed", order_sts,
          "ORDER_LINE" + line + ".sIdCard", driver_card);
    dpQuery(query, items);
    normalizeQueryData(items);


    /*
      0 - iCompNr
      1 - iQuantity
      2 - iProcessed
      3 - Device
      4 - iPercent
    */
    for(int i=1; i<=items.count(); i+=5){
      int loc_post = deviceToPost(items[i+3][2]);
      int loc_line = deviceToLine(items[i+3][2]);
      int post_sts;
      if(items[i+2][2] != 99){
        dpGet("ASN_"+loc_line+".Post"+loc_post+".sStatusPosta", post_sts);
        DebugFTN("lg_info", "WC_ORDERS | ln/pst/itm/pr/cr",loc_line, loc_post, items[i+0][2], prev_post_sts[items[i+0][2]], post_sts);
        if(prev_post_sts[items[i+0][2]] == 0x20 & post_sts == 0x00 & items[i+2][2] == 1 ){
          int dozer = getDozer(loc_line, loc_post);
          postAsnStop(loc_line, loc_post, items[i+0][2], dozer);
          dpSetWait(items[i+2][1], 2);
        }
        if(items[i+2][2] > 0){
          prev_post_sts[items[i+0][2]] = post_sts;
        }
      }else{
        continue;
      }
      if(items[i+2][2] == 0 & post_sts == 0x00){
        if(loc_line == line){
          bool prisadka = (items[i+4][2] > 0);
          int dozer = getDozer(loc_line, loc_post);
          dpSetWait("ASN_" + line + ".Post" + loc_post + ".cVolumeDose", items[i+1][2],
                    "ASN_" + line + ".Post" + loc_post + ".сPrisadka", prisadka,
                    "ASN_" + line + ".Post" + loc_post + ".sStatusPosta", 0x10,
                    items[i+2][1], 1);
          if(dozer >0){
            dpSetWait("ASN_" + line + ".Global_Variable.bui_PercentPrisadki_" + dozer + "Post", items[i+4][2]);
          }
          postAsnStart(loc_line, loc_post, items[i+0][2]);
        }
      }
//       delay(5); // Для опроса АСН по modbus
    }
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
  dpConnectUserData("worker", 1, false, "ASN_1.Global_Variable.bui_IDCard.bui_IDCard_05");
  dpConnectUserData("worker", 2, false, "ASN_2.Global_Variable.bui_IDCard.bui_IDCard_05");
  dpConnectUserData("worker", 3, false, "ASN_3.Global_Variable.bui_IDCard.bui_IDCard_05");
//   dpConnectUserData("worker", 4, false, "ASN_3.Global_Variable.bui_IDCard.bui_IDCard_05");
//   dpConnectUserData("worker", 5, false, "ASN_3.Global_Variable.bui_IDCard.bui_IDCard_05");
//   dpConnectUserData("worker", 6, false, "ASN_3.Global_Variable.bui_IDCard.bui_IDCard_05");
}
