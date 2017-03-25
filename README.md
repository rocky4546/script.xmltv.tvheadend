# script.xmltv.tvheadend
This repository contains the instructions and files to use zap2it.com to produce and maintain a tv guide within tvheadend that can be integrated with Kodi. It tries to automate the installation and setup to the extent possible on Debian operating systems.  It uses zap2xml.pl from http://zap2xml.awardspace.info to scrape and generate the initial xmltv.xml file from zap2it.com.  So any impacts do to changes on the zap2it.com website are managed by http://zap2xml.awardspace.info.<p>
The xmltv/category-filter.pl perl script can convert any xmltv.xml file to comply with tvheadend genre requirements; such as, schedule direct and zap2it although special instructions on how to use zap2it scripts are provided.<p>
Requirements and installation instructions can be found on the Wiki.  The install.sh script assumes a Debian or Ubuntu operating system, while alll scripts are written in bash and perl, and are assumed to run under a Linux OS.<p>
You can change the genre translations if you are not getting the correct conversions between what the tvguide says and tvheadend needs. The translation table is found in the xmltv/category-filter.pl file.
