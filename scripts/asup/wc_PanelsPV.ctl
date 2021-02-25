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
string dp_srv_act = "_ReduManager.EvStatus";      // Для основного сервера
//--------------------------------------------------------------------------------
/**
*/
int getAsciiCode(string in){
  int out = 0;
  const dyn_int codes = makeDynInt(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,0,
                                   48,49,50,51,52,53,54,55,56,57,33,40,41);
  const dyn_string symbols = makeDynString("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"," ",
                                           "0","1","2","3","4","5","6","7","8","9","!","(",")");
  for(int i=1; i<=codes.count(); i++){
    if(in == symbols[i]){
      return codes[i];
    }
  }
}

string toLatin(string in){
  const dyn_string rus = makeDynString("А","В","С","Е","Н","К","М","И","О","Р","Т","У");
  const dyn_string eng = makeDynString("A","B","C","E","H","K","M","N","O","P","T","Y");
  string res;
  for(int i=0; i<in.length(); i++){
    string temp = in.at(i);
    for(int j=1; j<=rus.count(); j++){
      if(in.at(i) == rus[j]){
        temp = eng[j];
        break;
      }
    }
    res += temp;
  }
  return res;
}


int fuelToInt(string fuel_st){
  int fuel = 0;
  switch (fuel_st){
    case "АИ-92":
    case "АИ-92(G)":
      fuel = 1;
      break;
    case "АИ-95":
    case "АИ-95(G)":
      fuel = 2;
      break;
    case "АИ-98":
    case "АИ-98(G)":
      fuel = 3;
      break;
    case "АИ-100":
    case "АИ-100(G)":
      fuel = 4;
      break;
    case "ДТ":
    case "ДТ(O)":
      fuel = 5;
      break;
  }
  return fuel;
}

dyn_int stringToAscii(string input){
  dyn_int result = makeDynInt(0,0,0,0,0,0,0,0,0,0,0,0);
  for(int i=0; i<input.length() & i<12; i++){
    result[i + 1] = getAsciiCode(input.at(i));
  }
  return result;
}

void worker_data(int line, dyn_string dp, dyn_anytype val){
  bool temp_srv;
  dpGet(dp_srv_act, temp_srv);
  if (temp_srv){           //если сервер активный
    dyn_string panel_text;
    for(int i=1; i<=12; i++){
      panel_text.append("Panel_"+line+".GosNumber.Symbol_" + i);
    }
    int count = 1;
    for(int i=1; i<=val.count() - 1; i+=4){
      dpSetWait("Panel_" + line + ".sections." + count + ".Zadano", val[i],
                "Panel_" + line + ".sections." + count + ".TypeOil", fuelToInt(val[i+1]),
                "Panel_" + line + ".sections." + count + ".StateSection", val[i+2],
                "Panel_" + line + ".sections." + count + ".Nalito", val[i+3]);
      count++;
    }
    dpSetWait(panel_text, stringToAscii(toLatin(val.last())));
  }
}


main(string p1){
  if(p1 == "-RES"){ dp_srv_act = "_ReduManager_2.EvStatus"; } // RESERVER SERVER
  dyn_string panels1_text, panels2_text, panels3_text;
  for(int i=1; i<=10; i++){
    panels1_text.append("ORDER_LINE1.items." + i + ".init.iQuantity");
    panels1_text.append("ORDER_LINE1.items." + i + ".init.sProductCode");
    panels1_text.append("ORDER_LINE1.items." + i + ".init.iProcessed");
    panels1_text.append("LINE1_PV." + i + ".vol_base");

    panels2_text.append("ORDER_LINE2.items." + i + ".init.iQuantity");
    panels2_text.append("ORDER_LINE2.items." + i + ".init.sProductCode");
    panels2_text.append("ORDER_LINE2.items." + i + ".init.iProcessed");
    panels2_text.append("LINE2_PV." + i + ".vol_base");

    panels3_text.append("ORDER_LINE3.items." + i + ".init.iQuantity");
    panels3_text.append("ORDER_LINE3.items." + i + ".init.sProductCode");
    panels3_text.append("ORDER_LINE3.items." + i + ".init.iProcessed");
    panels3_text.append("LINE3_PV." + i + ".vol_base");
  }
  panels1_text.append("ORDER_LINE1.sRegNr");
  panels2_text.append("ORDER_LINE2.sRegNr");
  panels3_text.append("ORDER_LINE3.sRegNr");

  dpConnectUserData("worker_data", 1, panels1_text);
  dpConnectUserData("worker_data", 2, panels2_text);
  dpConnectUserData("worker_data", 3, panels3_text);

}
