#!/bin/bash
path=`dirname $0`
logfile="${path}/../.kodi/temp/zap2xml.log"
tempTvXmlFile="xmltv_default.xml"

if [[ "$1" == "fast" ]] ; then
  options="-D"
  echo "Executing with no delays"
  echo "This will put a load on zap2it.com"
  echo "Please be careful when using this command"
else
  options="-D -S 3"
fi

logpath=`dirname $logfile`
if [[ ! -d $logpath ]] ; then
  # kodi may not be installed.  use folder where
  # script is located
  logfile=$path/`basename $logfile`
fi

rm -f $logfile
# create the default xmltv.xml
# Determine if the default xmltv.xml was created in the last 12 hours
file=`find $path -name ${tempTvXmlFile} -mtime -1`
if [[ ! -z "$file" ]] ; then
  options="$options -N 0"
fi
${path}/zap2xml.pl $options  > ${logfile} 2>&1


# if the file was generated, then update it
file=`find $path -name ${tempTvXmlFile} -mtime -1`
if [[ -z "$file" ]] ; then
  echo "ERROR:: ${tempTvXmlFile} file did not generate" >> ${logfile} 2>&1
else
  ${path}/category-filter.pl ${path}/${tempTvXmlFile} >${path}/xmltv.xml 2>>${logfile}
  echo "SUCCESS:: New xmltv.xml file generated" >> ${logfile} 2>&1
fi

