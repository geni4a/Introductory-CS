include tables
include shared-gdrive("cs111-2020.arr", "1imMXJxpNWFCUaawtzIJzPhbDuaLHtuDX")
include gdrive-sheets
include image
import math as M
import statistics as S
import data-source as DS

include shared-gdrive("taxi-project-support-2020.arr", 
  "1RF7AvfRpZ6a4asxQzHeC_2a91gNrZtgF")

taxi-ssid = "1ZbiTAuBpy55akMtA-gWjRBBW0Jo6EP0h_mQWmLMyfkc" 
taxi-sheet = load-spreadsheet(taxi-ssid) # load spreadsheet
taxi-data-sheet = taxi-sheet.sheet-by-name("data", true) # get data sheet
taxi-data-long =
  load-table:
    day, weekday, timeframe, num-rides, avg-dist, total-fare
    source: taxi-data-sheet
  end 
weather-ssid = "1uiWXHjKAeZ7aUjiL6V_IFN5j9uLRHv_b1ji_Nc3IZm4" 
wdata-sheet = load-spreadsheet(weather-ssid)
weather-data =
  load-table: date, weekday, awnd, prcp, snow, tavg, tmax, tmin
    source: wdata-sheet.sheet-by-name("final2", true)
  end

#-----------------------------------

#Making test tables for subsequent functions

taxi-test-data = table: day :: String, weekday :: String, timeframe :: String, num-rides :: Number,
  avg-dist :: Number, total-fare :: Number

  row: "01/02/2016", "Saturday", "0-6", 10, 3, 50
  row: "01/02/2016", "Saturday", "6-12", 20, 4, 60
  row: "01/02/2016", "Saturday", "12-18", 40, 4, 70
  row: "01/02/2016", "Saturday", "18-24", 20, 3, 80
  row: "01/03/2016", "Sunday", "0-6", 15, 4, 70
  row: "01/03/2016", "Sunday", "6-12", 25, 5, 80
  row: "01/03/2016", "Sunday", "12-18", 45, 5, 90
  row: "01/03/2016", "Sunday", "18-24", 25, 4, 80
end

weather-test-data = table: date, weekday, awnd :: Number, prcp :: Number, snow :: Number,
  tavg :: Number, tmax :: Number, tmin :: Number

  row: "2016-01-02", "Saturday", 12, 0, 0, 50, 75, 25
  row: "2016-01-03", "Sunday", 8, 2, 1, 30, 45, 15
end

combined-test-data = table: day :: String, weekday :: String, timeframe :: String,
  num-rides :: Number, avg-dist :: Number, total-fare :: Number, prcp :: Number, snow :: Number,
  clear :: Boolean, temp-avg :: Number

  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 50
  row: "01/02/2016", "Saturday", "Morning", 20, 4, 60, 0, 0, true, 50
  row: "01/02/2016", "Saturday", "Afternoon", 40, 4, 70, 0, 0, true, 50
  row: "01/02/2016", "Saturday", "Evening", 20, 3, 80, 0, 0, true, 50
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 30
  row: "01/03/2016", "Sunday", "Morning", 25, 5, 80, 2, 1, false, 30
  row: "01/03/2016", "Sunday", "Afternoon", 45, 5, 90, 2, 1, false, 30
  row: "01/03/2016", "Sunday", "Evening", 25, 4, 80, 2, 1, false, 30
end


taxi-test-data2 = table: day :: String, weekday :: String, timeframe :: String, num-rides :: Number,
  avg-dist :: Number, total-fare :: Number
  row: "03/04/2016", "Friday", "0-6", 15, 1, 50
  row: "03/04/2016", "Friday", "6-12", 20, 4, 60
  row: "03/04/2016", "Friday", "12-18", 42, 4, 30
  row: "03/04/2016", "Friday", "18-24", 24, 3, 60
  row: "03/05/2016", "Saturday", "0-6", 15, 2, 70
  row: "03/05/2016", "Saturday", "6-12", 25, 5, 40
  row: "03/05/2016", "Saturday", "12-18", 45, 3, 90
  row: "03/05/2016", "Saturday", "18-24", 25, 4, 80
end

weather-test-data2 = table: date :: String, weekday :: String, awnd :: Number, prcp :: Number,
  snow :: Number, tavg :: Number, tmax :: Number, tmin :: Number
  row: "2016-03-04", "Friday", 12.97,	0.08, 1.2, 34, 42, 30
  row: "2016-03-05", "Saturday", 8.5, 0, 0, 35, 41, 30
end

combined-test-data2 = table: day :: String, weekday :: String, timeframe :: String,
  num-rides :: Number, avg-dist :: Number, total-fare :: Number, prcp :: Number,
  snow :: Number, clear :: Boolean, temp-avg :: Number
  row: "03/04/2016", "Friday", "Night", 15, 1, 50, 0.08, 1.2, false, 34
  row: "03/04/2016", "Friday", "Morning", 20, 4, 60, 0.08, 1.2, false, 34
  row: "03/04/2016", "Friday", "Afternoon", 42, 4, 30, 0.08, 1.2, false, 34
  row: "03/04/2016", "Friday", "Evening", 24, 3, 60, 0.08, 1.2, false, 34
  row: "03/05/2016", "Saturday", "Night", 15, 2, 70, 0, 0, true, 35
  row: "03/05/2016", "Saturday", "Morning", 25, 5, 40, 0, 0, true, 35
  row: "03/05/2016", "Saturday", "Afternoon", 45, 3, 90, 0, 0, true, 35
  row: "03/05/2016", "Saturday", "Evening", 25, 4, 80, 0, 0, true, 35
end


#-----------------------------------

#aligns the date formats of the two tables
fun fix-date(date :: String) -> String:
  doc:"takes in a date with yyyy-mm-dd format and changes it to mm/dd/yyyy"
  mm-dd = string-substring(date, 5, 10)
  second-hyphen = string-char-at(date, 4)
  yyyy = string-substring(date, 0, 4)
  string-replace(
    string-append(
      mm-dd, 
      string-append(second-hyphen,
        yyyy)),"-", "/")
where:
  fix-date("2016-05-22") is "05/22/2016"  
  fix-date("2016-02-02") is "02/02/2016" 
  fix-date("2016-10-20") is "10/20/2016"
end

# changes the laguardia weather data date column to match that of the 2016 table
fixed-weather-data = transform-column(weather-data, "date", fix-date)
fixed-weather-test-data = transform-column(weather-test-data, "date", fix-date)
fixed-weather-test-data2 = transform-column(weather-test-data2, "date", fix-date)

#assigns time period to time-frame
fun time(p :: String) ->String:
  doc:"takes in a timeframe and converts it into a time period."
  if p == "0-6":
    "Night"
  else if p == 	"6-12":
    "Morning"
  else if p == "12-18":
    "Afternoon"
  else:
    "Evening"
  end

where:
  time("0-6") is "Night"
  time("6-12") is "Morning"
  time("12-18") is "Afternoon"
  time("18-24") is "Evening"
  time("") is "Evening"
end

#changes the timeframe column in taxi data to the word equivalent
fixed-taxi-test-data = transform-column(taxi-test-data, "timeframe", time)
fixed-taxi-test-data2 = transform-column(taxi-test-data2, "timeframe", time)
time-period = transform-column(taxi-data-long, "timeframe", time)


fun precip-for-date(weather :: Table, date :: String) -> Number:
  doc:"returns rain value for a given date from weather :: Table"
  filter-with(weather, lam(r): r["date"] == date end).row-n(0)["prcp"]

where:
  precip-for-date(fixed-weather-test-data, "01/02/2016") is 0
  precip-for-date(fixed-weather-test-data, "01/03/2016") is 2
end 


fun snow-for-date(weather :: Table, date :: String) -> Number:
  doc:"returns snow value for a given date from weather :: Table"
  filter-with(weather, lam(r): r["date"] == date end).row-n(0)["snow"]

where:
  snow-for-date(fixed-weather-data, "01/02/2016") is 0
  snow-for-date(fixed-weather-data, "01/03/2016") is 0
  snow-for-date(fixed-weather-data, "01/17/2016") is 0.6
  snow-for-date(fixed-weather-data, "01/23/2016") is 27.9
  snow-for-date(fixed-weather-data, "02/05/2016") is 2.4
end

fun clear(r :: Row) -> Boolean:
  doc:"returns true if snow and prcp are 0"
  (r["prcp"] == 0) and (r["snow"] == 0)

where:
  clear(fixed-weather-data.row-n(0)) is true
  clear(fixed-weather-data.row-n(1)) is true
  clear(fixed-weather-data.row-n(39)) is false
end

fun temp-for-date(weather :: Table, date :: String) -> Number:
  doc:"returns tavg value from weather :: Table on given date :: String"
  filter-with(weather, lam(r): r["date"] == date end).row-n(0)["tavg"]

where:
  temp-for-date(fixed-weather-data, "01/02/2016") is 37
  temp-for-date(fixed-weather-data, "01/03/2016") is 40
  temp-for-date(fixed-weather-data, "01/04/2016") is 34
end

#| We elected to use tavg instead of tmax and tmin because tmax and tmin are extreme values and we
   don't know how long each day those were the exact temperatures. Consequently, to just smooth out
   our temperature data, we chose to apply tavg to all time periods.
   
   We chose not to include wind because winds less than 25 mph are not considered severe. 
   We visually scanned the table and did not see any winds we thought could be classified as bad 
   weather, so we elected not to include it in our final combined table.
|#

fun add-precip(taxi :: Table, weather :: Table) -> Table:
  doc:```add prcp, snow, and clear data from Table weather onto Table taxi by adding columns ```
  with-rain = build-column(taxi, "prcp", lam(r): 
      precip-for-date(weather, r["day"]) 
    end)
  with-snow =  build-column(with-rain, "snow", lam(r): 
    snow-for-date(weather, r["day"]) end )
  with-clear = build-column(with-snow, "clear", clear)
  build-column(with-clear, "temp-avg", lam(r): temp-for-date(weather, r["day"] ) end)

where:
  add-precip(fixed-taxi-test-data, fixed-weather-test-data) is combined-test-data
  add-precip(fixed-taxi-test-data2, fixed-weather-test-data2) is combined-test-data2
end

#Table with all data except for classified temps
table-with-almost-all-data = add-precip(time-period, fixed-weather-data)

#-----------------------------------
#Creating more sample tables for later testing
combined-test-data-with-temp-cat = table: day :: String, weekday :: String, timeframe :: String,
  num-rides :: Number, avg-dist :: Number, total-fare :: Number, prcp :: Number, snow :: Number,
  clear :: Boolean, temp-avg :: Number
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 50 #normal
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 30 #cold
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 39 #cold
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 40 #edge case cold
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 39 #cold
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 40 #edge case cold
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 78 #normal
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 79 #edge case hot
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 212 #suuuper hot
end

combined-test-data2-with-temp-cat = table: day :: String, weekday :: String, timeframe :: String,
  num-rides :: Number, avg-dist :: Number, total-fare :: Number, prcp :: Number, snow :: Number,
  clear :: Boolean, temp-avg :: Number, classified-temp :: String
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 50, "40F to 79F (normal temp)"
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 30, "40F or below (cold)"
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 39, "40F or below (cold)"
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 40, "40F or below (cold)"
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 39, "40F or below (cold)"
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 40, "40F or below (cold)"
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 78, "40F to 79F (normal temp)"
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 79, "79F or above (hot)"
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 212, "79F or above (hot)"
end

fun classify-temp(table :: Table) -> Table:
  doc: "takes in a table with temp data and classifies it as being extreme if too hot or too cold"
  fun hot-or-not(row :: Row) -> String:
    doc: "nested function to classify temps"
    if (row["temp-avg"] >= 79):
      "79F or above (hot)"
    else if (row["temp-avg"] <= 40):
      "40F or below (cold)"
    else:
      "40F to 79F (normal temp)"
    end
  where:
    hot-or-not(combined-test-data2.row-n(0)) is "40F or below (cold)"
    hot-or-not(combined-test-data.row-n(0)) is "40F to 79F (normal temp)"
  end
  build-column(table, "classified-temp", hot-or-not)

where:
  classify-temp(combined-test-data-with-temp-cat) is combined-test-data2-with-temp-cat
end

#-----------------------------------

#| Table with all data, with cols day, weekday, timeframe, num-rides, avg-dist, total-fare,
 prcp, snow, clear, temp-avg, classify-temp |#
table-with-all-data = classify-temp(table-with-almost-all-data)


#creating condensed tables where the 4 time frames are made into 1 day

#Test tables to test our consolidation functions
consolidation-test-table = table: date, weekday, num-rides, total-fare
  row: "01/02/2016", "Saturday", 124069, 1688964.14
  row: "01/02/2016", "Saturday", 42487, 577486.41
  row: "01/02/2016", "Saturday", 93045, 1150122.8
  row: "01/02/2016", "Saturday", 85436, 1019544.07
  row: "01/03/2016", "Sunday", 10, 20
  row: "01/03/2016", "Sunday", 10, 20
  row: "01/03/2016", "Sunday", 10, 20
  row: "01/03/2016", "Sunday", 10, 20
end

consolidation-test-table-2 = table: date, weekday, num-rides, total-fare
  row: "01/02/2016", "Saturday", 124069, 1688964.14
  row: "01/02/2016", "Saturday", 42487, 577486.41
  row: "01/02/2016", "Saturday", 93045, 1150122.8
  row: "01/02/2016", "Saturday", 85436, 1019544.07
end


#Consolidate rides by day
fun consolidate-rides-by-day(row :: Row) -> Number:
  doc: "combines total rides of all time periods on a given date"
  sum(filter-with(table-with-all-data, lam(s): s["day"] == row["date"] end), "num-rides")
where:
  consolidate-rides-by-day(consolidation-test-table.row-n(0)) is 345037
end

#Consolidate fares by day
fun consolidate-fares-by-day(row :: Row) -> Number:
  doc: "combines total fares of all time periods on a given date"
  sum(filter-with(table-with-all-data, lam(s): s["day"] == row["date"] end), "total-fare")
where:
  consolidate-fares-by-day(consolidation-test-table.row-n(0)) is 4436117.42
end

add-rides-fares-test-table = table: date, weekday, awnd :: Number, prcp :: Number, snow :: Number,
  tavg :: Number, tmax :: Number, tmin :: Number, num-rides :: Number, total-fare :: Number
  row: "01/02/2016", "Saturday", 12, 0, 0, 50, 75, 25, 345037, 4436117.42
  row: "01/03/2016", "Sunday", 8, 2, 1, 30, 45, 15, 312831, 3889888.11
end


consolidation-test-table-3 = table: day, weekday, num-rides, total-fare
 row: "01/02/2016", "Saturday", 124069, 1688964.14
 row: "01/02/2016", "Saturday", 42487, 577486.41
 row: "01/02/2016", "Saturday", 93045, 1150122.8
 row: "01/02/2016", "Saturday", 85436, 1019544.07
 row: "01/03/2016", "Sunday", 10, 20
 row: "01/03/2016", "Sunday", 10, 20
 row: "01/03/2016", "Sunday", 10, 20
 row: "01/03/2016", "Sunday", 10, 20
end

#putting fares and rides onto a weather table
fun consolidate-by-date(data-table :: Table, day :: String, colname :: String) -> Number:
  doc: ```takes in a data table, day, and colname in data table and outputs the value in data 
          table at that day and column```
  sum(filter-with(data-table, lam(r): r["day"] == day end), colname)
where:
  consolidate-by-date(consolidation-test-table-3, "01/02/2016", "num-rides") is 345037
  consolidate-by-date(consolidation-test-table-3, "01/02/2016", "total-fare") is 4436117.42
  consolidate-by-date(consolidation-test-table-3, "01/03/2016", "num-rides") is 40
  consolidate-by-date(consolidation-test-table-3, "01/03/2016", "total-fare") is 80
end

fun add-rides-fares(weather-table :: Table, data-table :: Table) -> Table:
  doc: ```takes in a weather data table and adds the rides and fares from taxi-data-table
          to the weather table```
  table-weather-rides = build-column(weather-table, "num-rides", 
    lam(r): consolidate-by-date(data-table, r["date"], "num-rides") end)
  build-column(table-weather-rides, "total-fare", 
    lam(r): consolidate-by-date(data-table, r["date"], "total-fare") end)
where:
  add-rides-fares(fixed-weather-test-data, table-with-all-data) is add-rides-fares-test-table
end

#add a new temp-avg col which is the same as t-avg
table-with-weather-rides-fares = add-rides-fares(fixed-weather-data, table-with-all-data)
table-with-weather-rides-fares-temp = build-column(table-with-weather-rides-fares, "temp-avg",
  lam(r): r["tavg"] end)
table-with-cat-rides-fares = classify-temp(table-with-weather-rides-fares-temp)



#| Building our condensed data table with cols date :: String, weekday :: String,
daily-total-rides :: Number, daily-total-fares :: Number |#
table-with-days = select-columns(fixed-weather-data, [list: "date", "weekday"])
table-days-rides = build-column(table-with-days, "daily-total-rides", consolidate-rides-by-day)
table-days-rides-fares = build-column(table-days-rides, "daily-total-fares",
  consolidate-fares-by-day)


consolidate-Saturday = table: day :: String, weekday :: String, timeframe :: String,
  num-rides :: Number, avg-dist :: Number, total-fare :: Number, prcp :: Number, snow :: Number,
  clear :: Boolean, temp-avg :: Number
  row: "01/02/2016", "Saturday", "Night",	10,	3, 50, 0,	0,	true,	50
  row:"01/02/2016", "Saturday",	"Morning",	20,	4, 60,	0,	0,	true,	50
  row: "01/02/2016", "Saturday", "Afternoon", 40, 4, 70, 0,	0,	true,	50
  row:"01/02/2016",	"Saturday",	"Evening",	20,	3, 80,	0,	0,	true,	50
end

# 2nd test table for function consolidate-by-day
consolidate-Sunday = table: day :: String, weekday :: String, timeframe :: String,
  num-rides :: Number, avg-dist :: Number, total-fare :: Number, prcp :: Number, snow :: Number,
  clear :: Boolean, temp-avg :: Number
  row: "01/03/2016",	"Sunday",	"Night",	15,	4,	70,	2,	1,	false,	30
  row: "01/03/2016",	"Sunday",	"Morning",	25,	5,	80,	2,	1,	false,	30
  row: "01/03/2016",	"Sunday",	"Afternoon",	45,	5,	90,	2,	1,	false,	30
  row: "01/03/2016",	"Sunday",	"Evening",	25,	4,	80,	2,	1,	false,	30
end


fun consolidate-by-day(table :: Table, day :: String) -> Table:
  doc:```takes in a table and filters out a value in a column which has the name of the
         input string and outputs a table with instances of that value only ```
  filter-with(table, lam(t): t["weekday"] == day end)
where:
  consolidate-by-day(combined-test-data, "Saturday") is consolidate-Saturday
  consolidate-by-day(combined-test-data, "Sunday") is consolidate-Sunday
end


avg-rides-on-temp-test-data = table: temp-status :: String, avg-rides :: Number
  row: "40F or below (cold)", 13
  row: "40F to 79F (normal temp)", 10
  row: "79F or above (hot)", 15
end

#creating a new table to graph extreme temps against avg. rides
fun avg-rides-on-temp(data-table :: Table) -> Table:
  doc: ```takes in a data-table like table-with-all-data, and outputs table below with extra col
       'avg-rides' which is the avg # of rides in that temp condition```
  temp-vs-rides = table: temp-status
    row: "40F or below (cold)"
    row: "40F to 79F (normal temp)"
    row: "79F or above (hot)"
  end
  
  fun avg-rides-on-temp-builder(row :: Row) -> Number:
    doc: "builder function that finds avg # of rides for temp-status in row"
    filtered-table = filter-with(data-table,
      lam(r): r["classified-temp"] == row["temp-status"] end)
    avg-rides = mean(filtered-table, "num-rides")
    num-round(avg-rides)
  end
  build-column(temp-vs-rides, "avg-rides", avg-rides-on-temp-builder)
where:
  avg-rides-on-temp(combined-test-data2-with-temp-cat) is avg-rides-on-temp-test-data
end

temp-bar-chart-table = avg-rides-on-temp(table-with-cat-rides-fares)
temp-rides-bar-chart = bar-chart(temp-bar-chart-table, "temp-status", "avg-rides")
temp-box-plot = box-plot(table-with-all-data, "temp-avg")


#-----------------------------------

#TASK 1: To what extent does bad weather affect how many rides people take?

#| makes bar charts for types of precipitation
   we realize prcp-amt-bin can be made a boolean but we had different bins before and didn't want
   to change type |#

prcp-test-data = table: day :: String, weekday :: String, timeframe :: String, 
  num-rides :: Number, avg-dist :: Number, total-fare :: Number, prcp :: Number,
  snow :: Number, clear :: Boolean, temp-avg :: Number
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 50
  row: "01/02/2016", "Saturday", "Morning", 20, 4, 60, 0, 0, true, 50
  row: "01/02/2016", "Saturday", "Afternoon", 40, 4, 70, 0, 0, true, 50
  row: "01/02/2016", "Saturday", "Evening", 20, 3, 80, 0, 0, true, 50
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 30
  row: "01/03/2016", "Sunday", "Morning", 25, 5, 80, 2, 1, false, 30
  row: "01/03/2016", "Sunday", "Afternoon", 45, 5, 90, 2, 1, false, 30
  row: "01/03/2016", "Sunday", "Evening", 25, 4, 80, 2, 1, false, 30
end

prcp-bin-test-data = table: day :: String, weekday :: String, timeframe :: String, 
  num-rides :: Number, avg-dist :: Number, total-fare :: Number, prcp :: Number,
  snow :: Number, clear :: Boolean, temp-avg :: Number, prcp-amt-bin :: String
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 50, "no prcp"
  row: "01/02/2016", "Saturday", "Morning", 20, 4, 60, 0, 0, true, 50, "no prcp"
  row: "01/02/2016", "Saturday", "Afternoon", 40, 4, 70, 0, 0, true, 50, "no prcp"
  row: "01/02/2016", "Saturday", "Evening", 20, 3, 80, 0, 0, true, 50, "no prcp"
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 30, "yes prcp"
  row: "01/03/2016", "Sunday", "Morning", 25, 5, 80, 2, 1, false, 30, "yes prcp"
  row: "01/03/2016", "Sunday", "Afternoon", 45, 5, 90, 2, 1, false, 30, "yes prcp"
  row: "01/03/2016", "Sunday", "Evening", 25, 4, 80, 2, 1, false, 30, "yes prcp"
end

snow-bin-test-data = table: day :: String, weekday :: String, timeframe :: String, 
  num-rides :: Number, avg-dist :: Number, total-fare :: Number, prcp :: Number,
  snow :: Number, clear :: Boolean, temp-avg :: Number, snow-amt-bin :: String
  row: "01/02/2016", "Saturday", "Night", 10, 3, 50, 0, 0, true, 50, "no snow"
  row: "01/02/2016", "Saturday", "Morning", 20, 4, 60, 0, 0, true, 50, "no snow"
  row: "01/02/2016", "Saturday", "Afternoon", 40, 4, 70, 0, 0, true, 50, "no snow"
  row: "01/02/2016", "Saturday", "Evening", 20, 3, 80, 0, 0, true, 50, "no snow"
  row: "01/03/2016", "Sunday", "Night", 15, 4, 70, 2, 1, false, 30, "yes snow"
  row: "01/03/2016", "Sunday", "Morning", 25, 5, 80, 2, 1, false, 30, "yes snow"
  row: "01/03/2016", "Sunday", "Afternoon", 45, 5, 90, 2, 1, false, 30, "yes snow"
  row: "01/03/2016", "Sunday", "Evening", 25, 4, 80, 2, 1, false, 30, "yes snow"
end

empty-prcp-bin-table = table: prcp :: String, num-value :: Number
  row: "no prcp", 0
  row: "yes prcp", 1
end

empty-snow-bin-table = table: snow :: String, num-value :: Number
  row: "no snow", 0
  row: "yes snow", 1
end

fun generate-empty-bin-table(type-prcp :: String) -> Table:
  doc: ```generates an empty table for weather type to build off of in make-prcp-chart-table```
  if type-prcp == "prcp":
    bin-table = table: prcp, num-value
      row: "no prcp", 0
      row: "yes prcp", 1
    end
    bin-table
  else:
    bin-table = table: snow, num-value
      row: "no snow", 0
      row: "yes snow", 1
    end
    bin-table
  end
where:
  generate-empty-bin-table("prcp") is empty-prcp-bin-table
  generate-empty-bin-table("snow") is empty-snow-bin-table
  generate-empty-bin-table("") is empty-snow-bin-table
end

fun make-bin-prcp(data-table :: Table, type-prcp :: String) -> Table:
  doc: ```takes in a data-table and puts the type-prcp into bins```
  fun bin-prcp-builder(row :: Row) -> String:
    doc: "builder function which puts prcp into bins"
    amt-prcp = row[type-prcp]
    if amt-prcp == 0:
      string-append("no ", type-prcp)
    else:
      string-append("yes ", type-prcp)
    end
  end
  col-name = string-append(type-prcp, "-amt-bin")
  build-column(data-table, col-name, bin-prcp-builder)
where:
  make-bin-prcp(combined-test-data, "prcp") is prcp-bin-test-data
  make-bin-prcp(combined-test-data, "snow") is snow-bin-test-data
end


fun make-prcp-chart-table(data-table :: Table, type-prcp :: String) -> Table:
  doc: ```takes in data table with taxi data and weather data, chart-table, and type-prcp being 
          either 'prcp' or 'snow' and outputs a valid bar-chart-table```
  empty-bin-table = generate-empty-bin-table(type-prcp)
  bin-data-table = make-bin-prcp(data-table, type-prcp)
  bin-col-name = string-append(type-prcp, "-amt-bin")
  fun prcp-bar-chart-builder(row :: Row) -> Number:
    doc: "builder function to make a useable bar chart table"
    table-by-bin = filter-with(bin-data-table, lam(r): r[bin-col-name] == row[type-prcp] end)
    avg-rides = mean(table-by-bin, "num-rides")
    num-round(avg-rides)
  end
  build-column(empty-bin-table, "avg-rides", prcp-bar-chart-builder)
  
where:
  make-prcp-chart-table-results = table: prcp :: String, num-value :: Number, 
    avg-rides :: Number
    row: "no prcp", 0, 23
    row: "yes prcp", 1, 28
  end
  make-prcp-chart-table(prcp-test-data, "prcp") is make-prcp-chart-table-results
end


rain-chart-table = make-prcp-chart-table(table-with-weather-rides-fares, "prcp")
rain-bar-chart = bar-chart(rain-chart-table, "prcp", "avg-rides")
rain-regression = lr-plot(rain-chart-table, "num-value", "avg-rides")
snow-chart-table = make-prcp-chart-table(table-with-weather-rides-fares, "snow")
snow-bar-chart = bar-chart(snow-chart-table, "snow", "avg-rides")
snow-regression = lr-plot(snow-chart-table, "num-value", "avg-rides")

#-----------------------------------

#| TASK 2: Do the number of rides and total fares follow similar patterns 
   for each day of the week across the year? |#


rsd-test-data = table: date :: String, weekday :: String, daily-total-rides :: Number,
  daily-total-fares :: Number
  row: "01/04/2016", "Monday", 1, 10
  row: "01/05/2016", "Tuesday",	2, 12
  row: "01/06/2016", "Wednesday",	5, 14
  row: "01/07/2016", "Thursday", 7, 3
  row: "01/08/2016", "Friday", 2, 5
  row: "01/09/2016", "Saturday", 15, 6
  row: "01/10/2016", "Sunday", 34, 40
  row: "01/11/2016", "Monday", 2, 20
  row: "01/12/2016", "Tuesday", 4, 20
  row: "01/13/2016", "Wednesday", 6, 10
  row: "01/14/2016", "Thursday", 7, 4
  row: "01/15/2016", "Friday", 14, 7
  row: "01/16/2016", "Saturday", 12, 8
  row: "01/17/2016", "Sunday", 20, 36
end

rsd-test-result = table: weekday :: String, num-rides-rsd :: Number, total-fare-rsd :: Number
  row: "Monday", 33.3, 33.3
  row: "Tuesday", 33.3, 25
  row: "Wednesday", 9.1, 16.7
  row: "Thursday", 0, 14.3
  row: "Friday", 75, 16.7
  row: "Saturday", 11.1, 14.3
  row: "Sunday", 25.9, 5.3
end

fun make-rsd-table(data-table :: Table) -> Table:
  doc: ```takes in a data table and outputs table with 7 rows, one for each day of week and cols
          with the relative standard deviation (rsd) of total rides and fares```
  days-table = table: weekday
    row: "Monday"
    row: "Tuesday"
    row: "Wednesday"
    row: "Thursday"
    row: "Friday"
    row: "Saturday"
    row: "Sunday"
  end
  fun stdev-col-builder(row :: Row, col-name :: String) -> Number: 
    doc: "takes in row for builder and outputs std-dev of fares for day"
    consolidated-day-table = consolidate-by-day(data-table, row["weekday"])
    col-stdev = stdev(consolidated-day-table, col-name)
    col-mean = mean(consolidated-day-table, col-name)
    stdev-mean-percent = (col-stdev / col-mean) * 100
    rounded-percent = num-round(stdev-mean-percent * 10) / 10
    rounded-percent
  end
  rides-rsd-table = build-column(days-table, "num-rides-rsd",
    lam(r): stdev-col-builder(r, "daily-total-rides") end)
  build-column(rides-rsd-table, "total-fare-rsd",
    lam(r): stdev-col-builder(r, "daily-total-fares") end)
where:
  make-rsd-table(rsd-test-data) is rsd-test-result 
end

daily-rsd-table = make-rsd-table(table-days-rides-fares)
sorted-daily-rsd-table = sort-by(daily-rsd-table, "num-rides-rsd", false)
daily-rides-rsd-chart = bar-chart(daily-rsd-table, "weekday", "num-rides-rsd")
daily-fares-rsd-chart = bar-chart(daily-rsd-table, "weekday", "total-fare-rsd")

sunday-consolidated-data = consolidate-by-day(table-days-rides-fares, "Sunday")
sunday-total-rides-chart = bar-chart(sunday-consolidated-data, "date", "daily-total-rides")
sunday-total-fares-chart = bar-chart(sunday-consolidated-data, "date", "daily-total-fares")

thursday-consolidated-data = consolidate-by-day(table-days-rides-fares, "Thursday")
thursday-total-rides-chart = bar-chart(thursday-consolidated-data, "date", "daily-total-rides")
thursday-total-fares-chart = bar-chart(thursday-consolidated-data, "date", "daily-total-fares")

#-----------------------------------

#TASK 3: Are some days of the week more likely than others to have high numbers of rides?
popular-day-test-table = table: date :: String, weekday :: String, daily-total-rides :: Number
 row: "01/04/2016", "Monday", 1
 row: "01/05/2016", "Tuesday", 2
 row: "01/06/2016", "Wednesday", 5
 row: "01/07/2016", "Thursday", 7
 row: "01/08/2016", "Friday", 2
 row: "01/09/2016", "Saturday", 15
 row: "01/10/2016", "Sunday", 34
 row: "01/11/2016", "Monday", 2
 row: "01/12/2016", "Tuesday", 4
 row: "01/13/2016", "Wednesday", 6
 row: "01/14/2016", "Thursday", 7
 row: "01/15/2016", "Friday", 14
 row: "01/16/2016", "Saturday", 12
 row: "01/17/2016", "Sunday", 20
end

popular-day-test-result = table: weekday :: String, average-riders :: Number
 row: "Monday", 1.5
 row: "Tuesday", 3
 row: "Wednesday", 5.5
 row: "Thursday", 7
 row: "Friday", 8
 row: "Saturday", 13.5
 row: "Sunday", 27
end

fun make-popular-day-table(data-table :: Table) -> Table:
 doc: ```generates a table using data-table to help compare which day of the week has most rides```
 which-day-is-popular = table: weekday :: String
   row: "Monday"
   row: "Tuesday"
   row: "Wednesday"
   row: "Thursday"
   row: "Friday"
   row: "Saturday"
   row: "Sunday"
 end
  
 fun day-rides-mean(row :: Row) -> Number:
   doc: ```builder function to help make popular day table```
   consolidated-day-table = consolidate-by-day(data-table, row["weekday"])
   mean(consolidated-day-table, "daily-total-rides")
 end
  
 build-column(which-day-is-popular, "average-riders", day-rides-mean)
where:
 make-popular-day-table(popular-day-test-table) is popular-day-test-result
end

popular-day-chart-table = make-popular-day-table(table-days-rides)

which-day-is-popular-bar = bar-chart(popular-day-chart-table , "weekday", "average-riders")


#------------------------------------
# more test tables for summary-table function
summary-test-table = table: time :: String, prcp :: Number, snow :: Number, clear :: Number
  row: "Morning",	10233040,	992131,	21798440
  row: "Afternoon",	12654552,	1358084,	26405441
  row: "Evening",	14319868,	1492558,	30132458
  row:"Night",	5247145,	722459,	10374099 
end

#2nd test table for summary-table function
summary-test-table1 = table: time :: String, prcp :: Number, snow :: Number, clear :: Number
  row: "Morning",	87461.88,	82677.58,	87543.94
  row: "Afternoon",	108158.56,	113173.67,	106045.95
  row: "Evening",	122392.03,	124379.83,	121013.89
  row: "Night",	44847.39,	60204.92,	41663.05
end

#3rd test table for summary-table function
summary-test-table2 = table: time :: String, prcp :: Number, snow :: Number, clear :: Number
  row: "Morning",	20776.37,	28932.34,	20344.79
  row: "Afternoon",	15069.21,	32712.52,	11085.22
  row:"Evening",	23621.35,	41213.35,	21520.77
  row:"Night",	23618.42,	23634.96,	22977.81
end

#4th test table for summary-table function
summary-test-table3 = table: time :: String, prcp :: Number, snow :: Number, clear :: Number
  row: "Morning",	87461.88,	82677.58,	87543.94
  row:"Afternoon",	108158.56,	113173.67,	106045.95
  row:"Evening",	122392.03,	124379.83,	121013.89
  row: "Night",	44847.39,	60204.92,	41663.05
end

#Creating test tables for sum-table-builder
test-data-after-sum-table-builder-rain = table: time :: String, prcp :: Number
  row: "Morning", 25
  row: "Afternoon", 45
  row: "Evening", 25
  row: "Night", 15
end

test-data-after-sum-table-builder-snow = table: time :: String, snow :: Number
  row: "Morning", 25
  row: "Afternoon", 45
  row: "Evening", 25
  row: "Night", 15
end

test-data-after-sum-table-builder-clear = table: time :: String, clear :: Number
  row: "Morning", 20
  row: "Afternoon", 40
  row: "Evening", 20
  row: "Night", 10
end

test-data2-after-sum-table-builder-rain = table: time :: String, prcp :: Number
  row: "Morning", 20
  row: "Afternoon", 42
  row: "Evening", 24
  row: "Night", 15
end

test-data2-after-sum-table-builder-snow = table: time :: String, snow :: Number
  row: "Morning", 20
  row: "Afternoon", 42
  row: "Evening", 24
  row: "Night", 15
end

test-data2-after-sum-table-builder-clear = table: time :: String, clear :: Number
  row: "Morning", 25
  row: "Afternoon", 45
  row: "Evening", 25
  row: "Night", 15
end

sum-table-test = table: time :: String
  row: "Morning"
  row: "Afternoon"
  row: "Evening"
  row: "Night"
end


#TASK 4: make the summary table
fun sum-table-builder(sum-table :: Table, data-table :: Table, weather :: String,
    f :: (Table, String -> Number)) -> Table:
  doc: ```inputs a sum-table to add cols to, a data table to grab data from, a weather type
          representing a col in data-table, and f a function like sum, mean, stdev, etc...```
  fun col-builder-function(row :: Row) -> Number:
    doc:```builder function for sum-table-builder, takes in row from sum-table and filters by
           timeframe and weather condition 'weather' and outputs result of function f on the
           filtered table and 'num-rides'```
    if weather == "clear":
      filtered-clear-time = filter-with(data-table, lam(r): (r["timeframe"] == row["time"])
        and r[weather] end)
      #rounds to 2 decimal places
      num-round(f(filtered-clear-time, "num-rides") * 100) / 100
    else:
      filtered-prcp-time = filter-with(data-table, lam(r): (r["timeframe"] == row["time"])
        and (r[weather] > 0) end)
      num-round(f(filtered-prcp-time, "num-rides") * 100) / 100
    end
  end
  build-column(sum-table, weather, col-builder-function)
  
where:
  sum-table-builder(sum-table-test, combined-test-data, "prcp", sum) is
  test-data-after-sum-table-builder-rain
  sum-table-builder(sum-table-test, combined-test-data, "snow", sum) is 
  test-data-after-sum-table-builder-snow
  sum-table-builder(sum-table-test, combined-test-data, "clear", mean) is 
  test-data-after-sum-table-builder-clear
  sum-table-builder(sum-table-test, combined-test-data2, "prcp", mean) is 
  test-data2-after-sum-table-builder-rain
  sum-table-builder(sum-table-test, combined-test-data2, "snow", sum) is 
  test-data2-after-sum-table-builder-snow
  sum-table-builder(sum-table-test, combined-test-data2, "clear", sum) is 
  test-data2-after-sum-table-builder-clear
end

fun summary-table(data-table :: Table, f :: (Table, String -> Number)) -> Table:
  doc: ```Produces a table that uses the given function f to summarize
        rides for each of rain/snow/clear weather during morning/
        afternoon/evening/night timeframes based on the data in the table, data-table.```
  
  sum-table = table: time :: String
    row: "Morning"
    row: "Afternoon"
    row: "Evening"
    row: "Night"
  end

  rain-table = sum-table-builder(sum-table, table-with-all-data, "prcp", f)
  snow-rain-table = sum-table-builder(rain-table, table-with-all-data, "snow", f)
  sum-table-builder(snow-rain-table, table-with-all-data, "clear", f)

where:
  summary-table(combined-test-data, sum) is summary-test-table
  summary-table(combined-test-data, mean) is summary-test-table1
  summary-table(combined-test-data, stdev) is summary-test-table2
  summary-table(combined-test-data2, mean) is summary-test-table3
end

mean-summary-table = summary-table(table-with-all-data, mean)
sum-summary-table = summary-table(table-with-all-data, sum)
stdev-summary-table = summary-table(table-with-all-data, stdev)