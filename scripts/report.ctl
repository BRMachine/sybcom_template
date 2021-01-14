/*
Скрипт для формирования отчетов на АРМе.
По изменению точки данных query(тип точки REPORT) считываются данные из БД.
Затем данные записываются в точку данных report_data для приема или отпуска (разные точки).
По изменению точки report_data данные забираются и сортируются по таблице на мнемосхеме отчетов.
*/
#uses "lib_report"

dyn_dyn_string data;

void cbLoading(string dpe, string query){
  data = loading_data(query);
  dpSet("report.loading.report_data", data);
}

void cbRecieve(string dpe, string query){
  data = recieve_data(query);
  dpSet("report.recieve.report_data", data);
}

main(){
  dpConnect("cbLoading", "report.loading.query");
  dpConnect("cbRecieve", "report.recieve.query");
}
