// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author Arslanov.RA
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)

//--------------------------------------------------------------------------------
// variables and constants
dyn_dyn_int prev_state;
dyn_mapping prev_connects;

//--------------------------------------------------------------------------------
/**
*/

dyn_string genDpData(int post, int dozer){
  dyn_string ds_res;
  string post_dp = "Post_" + post;
  string doze_dp = "Post_" + dozer;
  if(dozer != 0){
    ds_res = makeDynString(post_dp + ".xVolumeFact",
                           doze_dp + ".xVolumeFact",
                           post_dp + ".xMassFact",
                           post_dp + ".xAverageTemperature",
                           post_dp + ".xAverageDensity");
  }else{
    ds_res = makeDynString(post_dp + ".xVolumeFact",
                           post_dp + ".xMassFact",
                           post_dp + ".xAverageTemperature",
                           post_dp + ".xAverageDensity");
  }
  return ds_res;
}

int getSection(string dp){
  int res = 0;
  dyn_string tmp = stringToDynString(dp, ".");
  res = (int)tmp[3];
  return res;
}

void worker_order(int line, dyn_dyn_anytype val){
  for(int i=2; i<=val.count(); i++){
    dyn_string local_dps;
    int post, dozer;
    int section = getSection(val[i][1]);
    DebugTN(line, section, val[i][2],  prev_state[i][section]);

    if(val[i][2] == 1 & prev_state[i][section] == 0){
      dpGet("ORDER_LINE" + line + ".items." + section + ".init.Device", post);
      dpGet("Post_" + post + ".local.HelperDozer"                     , dozer);
      local_dps = genDpData(post, dozer);
      dpConnectUserData("worker_data", line + "|" + section, local_dps);
      DebugTN("ASNPV", "dpConnect()", "worker_data", line + "|" + section, dynStringToString(local_dps));
      // previous
      prev_connects[line]["sections"][section]["ud"]   = line + "|" + section;
      prev_connects[line]["sections"][section]["data"] = local_dps;
    }else if(val[i][2] == 99 & (prev_state[i][section] == 2 | prev_state[i][section] == 0 | prev_state[i][section] == 99)){
//       DebugTN("ASN_PV", line, section, "Задание очищено");
      worker_data(line + "|" + section, local_dps, makeDynAnytype(0,0,0,0,0));
    }else{
      dpDisconnectUserData("worker_data", prev_connects[line]["sections"][section]["ud"], prev_connects[line]["sections"][section]["data"]);
      DebugTN("ASNPV", "dpDisconnect()", "worker_data", prev_connects[line]["sections"][section]["ud"], dynStringToString(prev_connects[line]["sections"][section]["data"]));
    }
    prev_state[i][section] = val[i][2];
  }
}

void worker_data(string ud, dyn_string dp, dyn_anytype data){
  dyn_string asn = stringToDynString(ud);
  if(data.count() == 4){
    dpSetWait("LINE" + asn[1] + "_PV." + asn[2] + ".vol_base"    , data[1],
              "LINE" + asn[1] + "_PV." + asn[2] + ".vol_doser"   , 0,
              "LINE" + asn[1] + "_PV." + asn[2] + ".mas_base"    , data[2],
              "LINE" + asn[1] + "_PV." + asn[2] + ".temp"        , data[3],
              "LINE" + asn[1] + "_PV." + asn[2] + ".density"     , data[4]);
  }else{
    dpSetWait("LINE" + asn[1] + "_PV." + asn[2] + ".vol_base"   , data[1],
              "LINE" + asn[1] + "_PV." + asn[2] + ".vol_doser"  , data[2],
              "LINE" + asn[1] + "_PV." + asn[2] + ".mas_base"   , data[3],
              "LINE" + asn[1] + "_PV." + asn[2] + ".temp"       , data[4],
              "LINE" + asn[1] + "_PV." + asn[2] + ".density"    , data[5]);
  }
}

main(){
  string query_order1 = "SELECT '_original.._value' FROM 'ORDER_LINE1.items.*.init.iProcessed'",
         query_order2 = "SELECT '_original.._value' FROM 'ORDER_LINE2.items.*.init.iProcessed'",
         query_order3 = "SELECT '_original.._value' FROM 'ORDER_LINE3.items.*.init.iProcessed'";
  for( int i=1; i<=3; i++){
    prev_state.append(makeDynInt(0,0,0,0,0,0,0,0,0,0));
  }

  prev_connects[1]["sections"] = makeDynMapping(
                        makeMapping("work", "worker_data", "ud"  , "", "data"  , makeDynString() ),
                        makeMapping("work", "worker_data", "ud"  , "", "data"  , makeDynString() ),
                        makeMapping("work", "worker_data", "ud"  , "", "data"  , makeDynString() ),
                        makeMapping("work", "worker_data", "ud"  , "", "data"  , makeDynString() ),
                        makeMapping("work", "worker_data", "ud"  , "", "data"  , makeDynString() ),
                        makeMapping("work", "worker_data", "ud"  , "", "data"  , makeDynString() ),
                        makeMapping("work", "worker_data", "ud"  , "", "data"  , makeDynString() ),
                        makeMapping("work", "worker_data", "ud"  , "", "data"  , makeDynString() ),
                        makeMapping("work", "worker_data", "ud"  , "", "data"  , makeDynString() ),
                        makeMapping("work", "worker_data", "ud"  , "", "data"  , makeDynString() )
                      );

  prev_connects[2] = prev_connects[1];
  prev_connects[3] = prev_connects[1];

  dpQueryConnectSingle("worker_order", false, 1, query_order1);
  dpQueryConnectSingle("worker_order", false, 2, query_order2);
  dpQueryConnectSingle("worker_order", false, 3, query_order3);
}
