#!/bin/bash
#
#	download the latest reportingarea.dat file from the
#	airnow gateway, and process like in shell_grab_epa
#	and shell_newtoold.
#
#	output:
#		/wx/data/epa/forecast.csv
#		/wx/data/epa/for_avail_notext.csv
#		/wx/data/epa/hourly_pollution.txt
#
#	matthew t. kallio, june 2012
#	weather underground, inc. 



dir=/prod/ingest/pollution/airnow/
cd ${dir}

# if these change, be sure to update
# http://wiki.as5000.com/index.php/Pollution_epa

site=ftp.AirnowGateway.org
siteuser=WxUnderground
sitepasswd=ePA123

# the the location / reporting area datafiles

ftp -n << endfile
open ${site}
user ${siteuser} ${sitepasswd} 
passive
prompt off
cd Locations
get monitoring_site_locations.dat
get reporting_area_locations.dat
cd ../ReportingArea
get reportingarea.dat forecast.csv
quit
endfile


# reportingarea.dat is like the old "forecast.csv" file, let's do everything we need right now
# note that is downloaded into forecast.csv above

hour=`date +%H`
day=`date +%d`
month=`date +%m`
year=`date +%Y`

# update the for_avail_notext.csv file
rm -f ${dir}for_avail_notext.csv
while read line; do

	city=`echo "${line}" | cut -f8 -d"|"`
	num=`grep -c "${city}" ${dir}epa.cty`

	if [ $num -gt 0 ]; then
		fday=`echo "${line}" | cut -c13-14`
		forecast=`echo "${line}" | cut -f6 -d"|"`
		if [ $fday = $day -a $forecast = F ]; then
			state=`echo "${line}" | cut -f9 -d"|"`
			lat=`echo "${line}" | cut -f10 -d"|"`
			lon=`echo "${line}" | cut -f11 -d"|"`
			pollutant=`echo "${line}" | cut -f12 -d"|"`
			case "${pollutant}" in
				"OZONE" ) pollutant="Ozone" ;;
				"PM2.5" | "PM10" ) pollutant="Particulate Matter" ;;
				"CO" ) pollutant="Carbon Monoxide" ;;
				"NO2" ) pollutant="Nitrogen Dioxide" ;;
				"SO2" ) pollutant="Sulfur Dioxide" ;;
			esac

			good=`echo "${line}" | cut -f14 -d"|"`
			yesno=`echo "${line}" | cut -f15 -d"|"`

			if [ $num = 1 ]; then
				zone=`grep "${city}" ${dir}epa.cty | cut -f6 -d","`
			else
				if [ "${city}" = "Portland" -a "${state}" = "ME" ]; then
					zone=me002
				fi
				if [ "${city}" = "Portland" -a "${state}" = "OR" ]; then
					zone=or001
				fi
				if [ "${city}" = "Springfield" -a "${state}" = "IL" ]; then
					zone=il005
				fi
				if [ "${city}" = "Springfield" -a "${state}" = "MA" ]; then
					zone=ma003
				fi
			fi
			echo "${year},${month},${day},\"${city}\",\"${state}\",\"${good}\",\"AQC\",\"${pollutant}\",0,${lat},${lon},\"${yesno}\",${zone}" >> ${dir}for_avail_notext.csv
		fi
	fi
done < ${dir}forecast.csv

cp -f ${dir}for_avail_notext.csv /wx/data/epa
/usr/local/bin/shell_pqhack /wx/data/epa/for_avail_notext.csv
cp -f ${dir}forecast.csv /wx/data/epa
/usr/local/bin/shell_pqhack /wx/data/epa/forecast.csv



# update the hourly_pollution.txt file
rm -f ${dir}hourly_pollution.txt
# Take out ^M control characters.
cat ${dir}forecast.csv | /usr/bin/tr -d '\015' > ${dir}forecast.csv.new
while read line; do 
	city=`echo "${line}" | cut -f8 -d"|"`
	num=`grep -c "${city}" ${dir}epa2003.cty`
	if [ $num -gt 0 ]; then
		state=`echo "${line}" | cut -f9 -d"|"`
		zone=`grep "${city}|${state}" ${dir}epa2003.cty | cut -f3 -d"|"`
		echo "${line}|${zone}" >> ${dir}hourly_pollution.txt
	fi
done < ${dir}forecast.csv.new

# not yet
cp -f ${dir}hourly_pollution.txt /wx/data/epa
/usr/local/bin/shell_pqhack /wx/data/epa/hourly_pollution.txt

exit 0

