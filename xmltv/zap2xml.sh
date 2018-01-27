#!/bin/bash
path=`dirname $0`
logfile="${path}/../.kodi/temp/zap2xml.log"
tempTvXmlFile="xmltv_default.xml"

# determine where we can put the log file
logpath=`dirname $logfile`
if [[ ! -d $logpath ]] ; then
  # kodi may not be installed.  use folder where
  # script is located if kodi not present
  logfile=$path/`basename $logfile`
fi
rm -f $logfile

# setup the options for perl script
if [[ "$1" == "fast" ]] ; then
  shift
  options="-T -D"
  echo "Executing with no delays"
  echo "This will put a load on zap2it.com"
  echo "Please be careful when using this command"
  echo "Running with options $options"else
  options="-T -D -S 1"
  echo "Running with options $options"
fi
options="$options $@"

# Set flag if script was recently executed, if so
# run a faster version
# Determine if the default xmltv.xml was created in the last 12 hours
file=`find $path -name ${tempTvXmlFile} -mtime -1`
if [[ ! -z "$file" ]] ; then
  # was executed recently
  # do not clean current day files
  options="$options -N 0"
else
  # perl script does not clean detail files properly, 
  # associated with using the -D option.
  # below will remove cache non-detail files that are within x days of 
  # today, which will force the current days to be refreshed
  # to current data.  It does not touch the detail cache files, so 
  # this does not heavily impact the website.
  daystoremove=3
  cachefolder=cache
  htmlfiles=`cd ${path}/${cachefolder}; ls *gz | egrep "^[0-9]+"`
  todaysec=`date +%s`
  todaymilli=$(($todaysec * 1000))
  twodaysmilli=$(($todaymilli + daystoremove * 24 * 60 * 60 * 1000))
  echo "Removing cache files older than $twodaysmilli" > ${logfile} 2>&1
  for file in $htmlfiles; do
    filetime=`echo $file | cut -d'.' -f1`
    if ((filetime < twodaysmilli)); then
      echo "Removing file ${filetime}.js.gz" >> ${logfile} 2>&1
      rm  ${path}/${cachefolder}/${filetime}.js.gz
    fi
  done
fi


###### GENERATE ${tempTvXmlFile} FILE
${path}/zap2xml.pl $options  >> ${logfile} 2>&1


# if the xml file was generated, then update it
file=`find $path -name ${tempTvXmlFile} -mtime -1`
if [[ -z "$file" ]] ; then
  echo "ERROR:: ${tempTvXmlFile} file did not generate" >> ${logfile} 2>&1
else
  ${path}/category-filter.pl ${path}/${tempTvXmlFile} >${path}/xmltv.xml 2>>${logfile}
  echo "SUCCESS:: New xmltv.xml file generated" >> ${logfile} 2>&1
fi

