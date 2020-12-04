#uses "CtrlHTTP"
#uses "http.ctl"

//==============================================================================
// This script (rs_http.ctl) starts the standard PVSS HTTP-Server
// You can add your own http resources ( for httpConnect() ) by adding additional
// config files ( parameter for HttpMain() and/or setting config key(s) like:
//    httpConnect0 = "MyScript1,/MyResource1"
//    httpConnect1 = "MyScript2,/MyResource2,text/plain"
//    ...
//
// Dirk Hegewisch 15.01.01
//==============================================================================
//
//==============================================================================
// Changes: [15.03.01]-[MH]:[TI 9168: Subdir http unter Linux wird nicht angelegt]
// Changes: [06.03.01]-[DH]:[TI#9043: All files moved under 'data/http/']
// Changes: [01.06.01]-[DH]:[WAP (new Feature)]
// Changes: [11.03.03]-[PK]:[moved all functions except main() to http.ctl;
//                           reading config files in all (sub-) projects;
//                           reading additional config files;
//                           adding my own http resources]
// Changes: [8.7.03]-[WOKL]:#uses eingefuegt
// Changes: [Date]-[Name]:[Changes]
//==============================================================================

main()
{
  int x;
  HttpMain(makeDynString(""));
  httpConnect("archive", "/archive");
  httpConnect("online", "/online");
}

/**
  * Запрос текущего значения точки данных
  * ===========================================
  * @param DPE - Точка данных для запроса
  * @param TIME - Время запроса
  *
  * @return json - закодированная в json строка
  * ===========================================
  */
string online(dyn_string asParameter, dyn_string asValue, string sUser, string sIP){
  mapping params;          //маппинг для параметров
  dyn_mapping dpoints;     //хранит все точки
  dyn_string DPEs;         //хранит запрашиваемые точки данных
  dyn_string DPEs_values;  //хранит возвращаемые данные запрашиваемых точек данных
  string json;             //хранит json
  time d = getCurrentTime();

  params["TIME"]= (string)second(d) + "_" + (string)minute(d) + "_" + (string)hour(d);
  if(asParameter.count() > 0){
    for (int i=1;i<=dynlen(asParameter);i++){ //параметры преобразуем в маппинг
      params[asParameter[i]]=asValue[i];
      if (patternMatch("DPE*", asParameter[i])){ //а заодно формируем массив запрашиваемых точек
        DebugFTN("verbose", asValue[i]);
        dynAppend(DPEs, asValue[i]);
      }
    }
  }else{
    mapping err = makeMapping("code", -1,
                              "error", "Отсутствуют необходимые параметры",
                              "desc", "@param DPE - Точка данных для запроса | @param TIME - Время запроса");
    DebugTN(err);
    return jsonEncode(err);
  }
  dyn_string t = strsplit(params["TIME"], "_");
  d=makeTime(year(d), month(d), day(d), t[3], t[2], t[1]);

  DebugFTN("verbose", params["TIME"]);
  DebugFTN("verbose", t);
  DebugFTN("verbose", d);

  for (int i=1;i<=dynlen(DPEs);i++){
    anytype value;
    DebugFTN("verbose", "Datapoint checker: " + DPEs[i]);
    if (dpExists(DPEs[i])){
      dpGetAsynch(d, DPEs[i], value);
      if(dynlen(getLastError()) > 0)
        dpGet(DPEs[i], value);
      dpoints[i]["unit"] = (dpGetUnit(DPEs[i]) != "") ? dpGetUnit(DPEs[i]) : "EUEU";
      dpoints[i]["value"] = value;
      DebugFTN("verbose", value);
    }
    else
    {
      dpoints[i]["unit"] = "DP does not exist";
      dpoints[i]["value"] = "DP does not exist";
    }
      dpoints[i]["DPE"] = DPEs[i];
      DebugFTN("verbose", dpoints[i]["value"]);
      DebugFTN("verbose", dpoints[i]["unit"]);
  }
  json=jsonEncode(dpoints, true);
  return json;
}

/**
  * Запрос текущего значения точки данных
  * ===========================================
  * @param DPE - Точки данных для запроса
  * @param time - Диапазон истории в часах
  * @param count - Диапазон истории в количестве значений
  *
  * @return json - закодированная в json строка
  * ===========================================
  */

string archive(dyn_string asParameter, dyn_string asValue, string sUser, string sIP){
  long int_time;
  mapping map_param;            //маппинг для параметров
  dyn_string DPEs;              //хранит запрашиваемые точки данных
  mapping map_json_tempRPBro;   //временный маппинг для json ReportBro
  dyn_float values;             //значения точек данных
  dyn_time timl;                //время изменения значения точек данных
  dyn_string timlstr;           //то же но в строковом формате
  dyn_mapping dpoints;          //хранит все точки
  dyn_mapping jsonMappingRPBro; //хранит все точки

  //дефолтные значения параметров
  map_param["time"]=0;
  map_param["count"]=1;
  map_param["DPE"]="ExampleDP_Arg1.";

  if(asParameter.count() != 0){
    for (int i=1; i<=dynlen(asParameter); i++){    //параметры преобразуем в маппинг
      if (patternMatch("DPE*", asParameter[i])){   //а заодно формируем массив запрашиваемых точек
        dynAppend(DPEs, asValue[i]);
      }else{
        map_param[asParameter[i]]=asValue[i];
      }
    }
  }

  int_time = map_param["time"];
  int_time *= 3600;       //вычисляем кол-во секунд которых надо отнять
  time start_time = (time)((float)getCurrentTime() - int_time);

  for (int i=1; i<=dynlen(DPEs); i++){
    dpGetPeriod(start_time, getCurrentTime(), map_param["count"], DPEs[i], values, timl); //забираем историю
    dpoints[i]["DPE"] = DPEs[i];
    dpoints[i]["value"] = values;
    dpoints[i]["datetime"] = timl;
    dpoints[i]["unit"] = dpGetUnit(DPEs[i]);
  }
  int x = 1;
  for (int i=1; i<=dynlen(DPEs); i++){
    for (int j=1; j<=dynlen(dpoints[i]["value"]); j++){
        map_json_tempRPBro["id"] = x;
        map_json_tempRPBro["value"] = dpoints[i]["value"][j];
        map_json_tempRPBro["pointname"] = dpoints[i]["DPE"];
        map_json_tempRPBro["unit"] = dpoints[i]["unit"]["ru_RU.utf8"];
        timlstr[x] = dpoints[i]["datetime"][j];        //преобразуем время в строки
        map_json_tempRPBro["datetime"]=timlstr[x];
        map_json_tempRPBro["user"] = "";            //захардкожено для проверки кириллицы
        dynAppend(jsonMappingRPBro, map_json_tempRPBro);
        x++;
      }
    }
  return jsonEncode(jsonMappingRPBro, true);
}
