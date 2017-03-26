#!/bin/bash
path=`dirname $0`
logfile="${path}/../.kodi/temp/zap2xml.log"
tempTvXmlFile="xmltv_default.xml"

logpath=`dirname $logfile`
if [[ ! -d $logpath ]] ; then
  # kodi may not be installed.  use folder where
  # script is located
  logfile=$path/`basename $logfile`
fi

rm -f $logfile
# create the default xmltv.xml
${path}/zap2xml.pl -D -S 3  > ${logfile} 2>&1
#${path}/zap2xml.pl -D > ${logfile} 2>&1

# if the file was generated, then update it
file=`find $path -name ${tempTvXmlFile} -mtime -1`
if [[ -z "$file" ]] ; then
  echo "ERROR:: ${tempTvXmlFile} file did not generate" >> ${logfile} 2>&1
else
  ${path}/category-filter.pl ${path}/${tempTvXmlFile} >${path}/xmltv.xml 2>>${logfile}
  echo "SUCCESS:: New xmltv.xml file generated" >> ${logfile} 2>&1
fi

