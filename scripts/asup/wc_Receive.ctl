// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author R.Arslanov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)


//--------------------------------------------------------------------------------
// variables and constants

 string dp_srv_act = "_ReduManager.EvStatus";      // Для основного сервера
 dyn_bool init_is_sts = makeDynBool(false, false, false);
 dyn_dyn_bool g_is_prev_sts = makeDynBool(init_is_sts, init_is_sts, init_is_sts, init_is_sts);
//--------------------------------------------------------------------------------

// pubic functions
public void normalizeQueryData(dyn_dyn_anytype &data){
  data.removeAt(0);
}

public int getNumIS(string dp){
  return (int)strltrim( dpSubStr(dp, DPSUB_DP), "IS_");
}

public int getPostIS(string dp){
  dyn_string ds_temp = strsplit(dpSubStr(dp, DPSUB_DP_EL), ".");
  return (int)strltrim(ds_temp[2], "PST_");

}

//--------------------------------------------------------------------------------

// private functions

private int getRvsNum(int uu){
  int res = -1;
  for(int i=1; i<=8; i++){
    int tmp = 0;
    dpGet("LAST_RECEIVE_" + uu + ".init." + i + ".tank", tmp);
    if(tmp != 0){
      res = tmp;
      break;
    }
  }
  return res;
}

private mapping getSumData(int is, int post){
  mapping res;
  string dp_is = "IS_" + is + ".PST_" + post + ".";
  dpGet(dp_is + "vol_total"  , res["vol"],
        dp_is + "mass_total" , res["mas"]);
  return res;
}

private mapping getRvsData(int rvs_num){
  mapping res = makeMapping("lvl", 0, "vol", 0,
                            "mas", 0, "dns", 0,
                            "tmp", 0, "wtr", 0,
                            "prs", 0, "lwtr", 0);
  if(rvs_num > 0){
    dpGet("RVS_" + rvs_num + ".LVL.val"    , res["lvl"],
          "RVS_" + rvs_num + ".VOL.val"    , res["vol"],
          "RVS_" + rvs_num + ".MAS.val"    , res["mas"],
          "RVS_" + rvs_num + ".DNS.val"    , res["dns"],
          "RVS_" + rvs_num + ".TMP.val"    , res["tmp"],
          "RVS_" + rvs_num + ".WTR.val"    , res["wtr"],
          "RVS_" + rvs_num + ".VPR.PRS.val", res["prs"]);
    res["lwtr"] = res["wtr"];
  }
  return res;
}

private void startReceive(int is, int post){
  g_is_prev_sts[is][post] = true;
  string dp_rec = "LAST_RECEIVE_" + is + ".result.";

  time dt_start = getCurrentTime();
  int rvs_num = getRvsNum(is);
  mapping rvs_data = getRvsData(rvs_num);
  mapping is_data = getSumData(is, post);

  dpSetWait(dp_rec + "volume_sum_start"        , is_data["vol"],
            dp_rec + "weight_sum_start"        , is_data["mas"]);
  dpSetWait(dp_rec + "tank_data.level_start"   , rvs_data["lvl"],
            dp_rec + "tank_data.volume_start"  , rvs_data["vol"],
            dp_rec + "tank_data.weight_start"  , rvs_data["mas"],
            dp_rec + "tank_data.density_start" , rvs_data["dns"],
            dp_rec + "tank_data.temp_start"    , rvs_data["tmp"],
            dp_rec + "tank_data.waterl_start"  , rvs_data["wtr"],
            dp_rec + "tank_data.press_start"   , rvs_data["prs"],
            dp_rec + "tank_data.lwater_start"  , rvs_data["lwtr"]);

  dpSetWait("LAST_RECEIVE_" + is + ".state", 1);
  dpSetWait(dp_rec + "dt_start"    , dt_start);
}

private void endReceive(int is, int post){

  if(g_is_prev_sts[is][post]){
    string dp_is = "IS_" + is + ".PST_" + post + ".";
    string dp_rec = "LAST_RECEIVE_" + is + ".result.";


    float volume_dose;
    string rails, task, inventory, product, fuel;
    int tank, mode;

    time dt_end = getCurrentTime();
    float weight, volume, dens, temp, dens_15, volume_15, volume_sum, weight_sum;

    dyn_dyn_anytype q_res;
    string query = "SELECT '_original.._value' "                     +
                   "FROM   '{LAST_RECEIVE_" + is + ".init.?.task,"   +
                            "LAST_RECEIVE_" + is + ".init.?.doc,"    +
                            "LAST_RECEIVE_" + is + ".init.?.usn,"    +
                            "LAST_RECEIVE_" + is + ".init.?.tank,"   +
                            "LAST_RECEIVE_" + is + ".init.?.fuel,"   +
                            "LAST_RECEIVE_" + is + ".init.?.weight}'";
    dpQuery(query, q_res);
    normalizeQueryData(q_res);
    delay(30);  // Задержка для опроса актуальных значений по modbus
// add rvs data
    mapping is_data = getSumData(is, post);
    int rvs_num = getRvsNum(is);
    mapping rvs_data = getRvsData(rvs_num);

    dpSetWait(dp_rec + "tank_data.level_end"   , rvs_data["lvl"],
              dp_rec + "tank_data.volume_end"  , rvs_data["vol"],
              dp_rec + "tank_data.weight_end"  , rvs_data["mas"],
              dp_rec + "tank_data.density_end" , rvs_data["dns"],
              dp_rec + "tank_data.temp_end"    , rvs_data["tmp"],
              dp_rec + "tank_data.waterl_end"  , rvs_data["wtr"],
              dp_rec + "tank_data.press_end"   , rvs_data["prs"],
              dp_rec + "tank_data.lwater_end"  , rvs_data["lwtr"]);

    dpSetWait(dp_rec + "volume_sum"        , is_data["vol"],
              dp_rec + "weight_sum"        , is_data["mas"]);
// end rvs data

    for(int i=1; i<=q_res.count(); i+=6){
      if(q_res[i+0][2] != ""){
        task           = q_res[i+0][2];
        inventory     += q_res[i+1][2] + "-";
        rails         += q_res[i+2][2] + "-";
        tank           = q_res[i+3][2];
        fuel           = q_res[i+4][2];
        volume_dose   += q_res[i+5][2];
        dpSetWait("LAST_RECEIVE_" + is + ".init." + q_res[i+2][2] + ".state", 2);
      }
    }

    mode = (task == "ОПЕРАТОР") ? 1 : 2;
    rails = strrtrim(rails, "-");
    inventory = strrtrim(inventory, "-");

    dpSetWait("LAST_RECEIVE_" + is + ".state", 2);
    dpGet(dp_is + "mass_fact"       , weight,
          dp_is + "vol_fact"        , volume,
          dp_is + "avg_density"     , dens,
          dp_is + "avg_temperature" , temp,
          dp_is + "dens_15"         , dens_15,
          dp_is + "vol_15"          , volume_15,
          dp_is + "vol_total"       , volume_sum,
          dp_is + "mass_total"      , weight_sum);

    dpSetWait(dp_rec + "weight_fct"    , weight,
              dp_rec + "volume_fct"    , volume,
              dp_rec + "density_fct"   , dens,
              dp_rec + "temp_fct"      , temp,
              dp_rec + "density_15"    , dens_15,
              dp_rec + "volume_15"     , volume_15,
              dp_rec + "volume_sum"    , volume_sum,
              dp_rec + "weight_sum"    , weight_sum,
              dp_rec + "dt_end"        , dt_end,
              dp_rec + "tank"          , tank,
              dp_rec + "volume_dose"   , volume_dose,
              dp_rec + "task"          , task,
              dp_rec + "inventory"     , inventory,
              dp_rec + "product"       , fuel,
              dp_rec + "rail_num"      , rails,
              dp_rec + "post_name"     , is,
              dp_rec + "ModeCtrl"      , mode);

    g_is_prev_sts[is][post] = false;
  }
}

private void errReceive(int is, int post){
  if(g_is_prev_sts[is][post]){
    string dp_is = "IS_" + is + ".PST_" + post + ".";
    string dp_rec = "LAST_RECEIVE_" + is + ".result.";

    float volume_dose;
    string rails, task, inventory, product, fuel;
    int tank;

    time dt_end = getCurrentTime();
    float weight, volume, dens, temp, dens_15, volume_15, volume_sum, weight_sum;

    dyn_dyn_anytype q_res;
    string query = "SELECT '_original.._value' "                     +
                   "FROM   '{LAST_RECEIVE_" + is + ".init.?.task,"   +
                            "LAST_RECEIVE_" + is + ".init.?.doc,"    +
                            "LAST_RECEIVE_" + is + ".init.?.usn,"    +
                            "LAST_RECEIVE_" + is + ".init.?.tank,"   +
                            "LAST_RECEIVE_" + is + ".init.?.fuel,"   +
                            "LAST_RECEIVE_" + is + ".init.?.weight}'";
    dpQuery(query, q_res);
    normalizeQueryData(q_res);
    for(int i=1; i<=q_res.count(); i+=6){
      if(q_res[i+0][2] != ""){
        task           = q_res[i+0][2];
        inventory     += q_res[i+1][2] + "-";
        rails         += q_res[i+2][2] + "-";
        tank           = q_res[i+3][2];
        fuel           = q_res[i+4][2];
        volume_dose   += q_res[i+5][2];
        dpSetWait("LAST_RECEIVE_" + is + ".init." + q_res[i+2][2] + ".state", -1);
      }
    }
    rails     = strrtrim(rails, "-");
    inventory = strrtrim(inventory, "-");
    dpSetWait("LAST_RECEIVE_" + is + ".state", -1);

    delay(30);  // Задержка для опроса актуальных значений по modbus
    dpGet(dp_is + "mass_fact"       , weight,
          dp_is + "vol_fact"        , volume,
          dp_is + "avg_density"     , dens,
          dp_is + "avg_temperature" , temp,
          dp_is + "dens_15"         , dens_15,
          dp_is + "vol_15"          , volume_15,
          dp_is + "vol_total"       , volume_sum,
          dp_is + "mass_total"      , weight_sum);

    dpSetWait(dp_rec + "weight_fct"    , weight,
              dp_rec + "volume_fct"    , volume,
              dp_rec + "density_fct"   , dens,
              dp_rec + "temp_fct"      , temp,
              dp_rec + "density_15"    , dens_15,
              dp_rec + "volume_15"     , volume_15,
              dp_rec + "volume_sum"    , volume_sum,
              dp_rec + "weight_sum"    , weight_sum,
              dp_rec + "dt_end"        , dt_end,
              dp_rec + "tank"          , tank,
              dp_rec + "volume_dose"   , volume_dose,
              dp_rec + "task"          , task,
              dp_rec + "inventory"     , inventory,
              dp_rec + "product"       , fuel,
              dp_rec + "rail_num"      , rails,
              dp_rec + "post_name"     , is);
  }
  g_is_prev_sts[is][post] = false;
}

private void cbIS(string ud, dyn_dyn_anytype res){
  bool temp_srv;
  dpGet(dp_srv_act, temp_srv);
  if (temp_srv){           //если сервер активный
    dyn_mapping wd;

    normalizeQueryData(res);
    for(int i=1; i<=res.count(); i++){
      if(res[i][2]==0x10){
        DebugFTN("lg_debug", "IS_REC | START RECEIVE");
        startReceive(getNumIS(res[i][1]), getPostIS(res[i][1]));
      }

      if(res[i][2] == 0x60){
        DebugFTN("lg_debug", "IS_REC | ERROR POST RECEIVE");
        errReceive(getNumIS(res[i][1]), getPostIS(res[i][1]));
      }

      if(res[i][2] == 0x00){
        DebugFTN("lg_debug", "IS_REC | END RECEIVE");
        endReceive(getNumIS(res[i][1]), getPostIS(res[i][1]));
      }
    }
  }else{
    DebugFTN("lg_info", "This project NoActive(main)");
  }
}
//--------------------------------------------------------------------------------

/**
*/
main(string p1){
  if(p1 == "-RES"){
    dp_srv_act = "_ReduManager_2.EvStatus";
  }
  dpQueryConnectSingle("cbIS", false, "ud", "SELECT '_original.._value' FROM 'IS_?.PST_?.status'");
}
