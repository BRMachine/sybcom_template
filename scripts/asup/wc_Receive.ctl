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

private void startReceive(int is, int post){
  string dp_rec = "LAST_RECEIVE_" + is + ".result.";
  time dt_start = getCurrentTime();
  dpSetWait("LAST_RECEIVE_" + is + ".state", 1);
  dpSetWait(dp_rec + "dt_start"    , dt_start);
}

private void endReceive(int is, int post){
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
  delay(30);  // Задержка для опроса актуальных значений по modbus
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
            dp_rec + "post_name"     , "ИС" + is);
}

private void errReceive(int is, int post){
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
  rails = strrtrim(rails, "-");
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
            dp_rec + "post_name"     , "ИС" + is);
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
main()
{
  if(p1 == "-RES"){
    dp_srv_act = "_ReduManager_2.EvStatus";
  }
  dpQueryConnectSingle("cbIS", false, "ud", "SELECT '_original.._value' FROM 'IS_?.PST_?.status'");
}
