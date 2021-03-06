#!/bin/bash
#
#
grab_file="usr/bin/tv_grab_file"
rc_file=".zap2xmlrc"
cat_file="xmltv/category-filter.pl"
script_file="xmltv/zap2xml.sh"
perl_file="zap2xml.pl"
dest_folder=~/xmltv
htsuser="hts"

runfrom=`pwd`
cd `dirname $0`

# Determine if all files are present
echo
echo "### Checking for files to install"

isAllFound=true
for file in "$grab_file" "x$rc_file" "$cat_file" "$script_file" ; do
  if [[ ! -r "$file" ]] ; then
    echo "$file not found"
    echo "Please download and extract the files from"
    echo "https://github.com/rocky4546/script.xmltv.tvheadend/releases"
    echo
    isAllFound=false
  fi
done
if [[ ! -r "xmltv/$perl_file" ]] ; then
  if [[ ! -r "$perl_file" ]] ; then
    echo "$perl_file not found"
    echo "Download file from http://zap2xml.awardspace.info"
    echo "If you have downloaded the file, please"
    isFound=false
    while [ $isFound == "false" ] ; do
      read -p "Enter the folder to $perl_file: " newpath
      if [[ -z $newpath ]] ; then
        echo "Aborting install..."
        exit
      elif [[ $newpath = /* ]] ; then
        # absolute path provided
        eval newloc=$newpath/$perl_file
      else
        eval newloc=$runfrom/$newpath/$perl_file
      fi
      if [[ -r "${newloc}" ]] ; then
        echo "Found file, thank you at $newloc"
        echo
        cp $newloc .
        isFound=true
      else
        echo "Hmmm, unable to find the file at $newloc"
      fi
    done
  elif [[ ! -d "xmltv" ]] ; then
    echo "ERROR: Unable to find xmltv folder in the release install folder"
    echo "It looks like this is not a released version from"
    echo "https://github.com/rocky4546/script.xmltv.tvheadend/releases"
    isAllFound=false
  else
    cp $perl_file xmltv/$perl_file
  fi
else
  perl_file="xmltv/$perl_file"
fi

[[ "$isAllFound" == "false" ]] && exit

echo "Found all needed files for installation"

echo
echo "### Determine if xmltv-util is installed"
x=`tv_find_grabbers`
if (( $? != 0 )) ; then
  echo "ERROR: xmltv-util not installed, please install the package xmltv-util"
  exit
else
  echo "xmltv-util package found"
fi

echo
echo "### establishing the softlink to the tvheadend user home folder"
eval htshome=~$htsuser
if [ ! -d $htshome ] ; then
  echo "$htshome does not exist.  Is tvheadend installed?"
  read -p "Enter TVHeadend user [hts]: " newhtsuser
  htsuser=${newhtsuser:-hts}
  eval htshome=~$htsuser
  if [ ! -d $htshome ] ; then
    echo "ERROR: $htshome does not exists on system. Aborting."
    exit
  fi
fi
if [ ! -L $htshome/.xmltv ] ; then
  echo "Softlink not found, Adding softlink"
  sudo rm -rf  $htshome/.xmltv
  sudo ln -s $dest_folder $htshome/.xmltv
  sudo chown -h $htsuser:$htsuser $htshome/.xmltv
else
  echo "Softlink $htshome/.xmltv already exists, skipping"
fi

echo
echo "### Installing $grab_file"
isRedeploy=true
if [ -x /$grab_file ] ; then
  echo "WARNING: Found /$grab_file already present"
  read -p "Replace /$grab_file? [N|y]" answer
  if [[ ! "$answer" =~ [Y|y] ]] ; then
    echo "Not updating /$grab_file"
    isRedeploy=false
  fi
fi
if [[ "$isRedeploy" == "true" ]] ; then

  echo "Copying $grab_file to /usr/bin"
  sudo cp $grab_file /usr/bin
  sudo chmod 755 /$grab_file
  fileFound=`tv_find_grabbers | grep $grab_file`
  if [[ -z $fileFound ]] ; then
    echo "ERROR: The command tv_find_grabbers did not find ${grab_file}."
    echo "This should not happen. Aborting install until resolved"
    exit
  fi
  echo "Restarting tvheadend to list the new grabber file"
  sudo service tvheadend restart
  sleep 3
else
  echo "/$grab_file not deployed, skipping"
fi
echo "Checking to see if TVHeadend knows about the grabber file"
present=`sudo grep $grab_file ~hts/.hts/tvheadend/epggrab/config`
if [[ -z "$present" ]] ; then
  echo "ERROR: TVHeadend has not recognized the new $grab_file"
  echo "try logging into the TVHeadend website"
  echo "Once the $grab_file appears in the EPG Grabber Modules list"
  echo "Rerun this installation script"
  exit
else
  echo "Found, TVHeadend has grabber file listed"
fi

echo
echo "### Deploying $rc_file file"

isRedeploy=true
if [[ -f ~/$rc_file ]] ; then
  echo "WARNING: Found ~/$rc_file already present"
  read -p "Replace $rc_file? [N|y]" answer
  if [[ ! "$answer" =~ [Y|y] ]] ; then
    echo "Not updating $rc_file"
    isRedeploy=false
  fi
fi
if [[ "$isRedeploy" == "true" ]] ; then

  echo "Obtain zap2it login information"
  isNotValid=false
  while [ $isNotValid == "false" ] ; do
    read -p "zap2it.com email: " zap2itEmail
    if [[ $zap2itEmail == *"@"* ]] ; then
      isNotValid=true
    else
      echo "ERROR: not a valid email address"
    fi
  done
  
  read -s -p "zap2it password: " zap2itPassword
  
  echo
  echo
  echo "Testing zap2it login"
  cmd='{"usertype":"0","facebookuser":"false","emailid":"'${zap2itEmail}'","password":"'${zap2itPassword}'"}'
  response=`curl -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -X POST -d $cmd https://tvlistings.zap2it.com/api/user/login 2>/dev/null`
  if [[ "$response" != "200" ]] ; then
    echo "ERROR: Login failed, recieved message"
    echo $response
    exit
  else
    echo "Login Successful!"
  fi

  cp x$rc_file ~/$rc_file
  sed -i "s/<email>/$zap2itEmail/" ~/$rc_file
  sed -i "s/<password in the clear>/$zap2itPassword/" ~/$rc_file
  sed -i "s/<user>/$USER/g" ~/$rc_file
fi

echo
echo "### Deploying scripts to $dest_folder"
if [[ ! -d $dest_folder ]] ; then
  mkdir $dest_folder
fi 
chmod 755 $cat_file $script_file $perl_file 
cp $cat_file $script_file $perl_file ${dest_folder}/


echo
echo "### Adding a cronjob to run daily"
read -p "What hour do you want the cronjob to run? [1] (Recommend between 0 and 7) " hour
hour=${hour:-1}
# random generate the minute between 5 and 55
minute=$(((RANDOM % 55)+5))
echo "cronjob will run script at $hour:$(printf %02d $minute) every day"
pulltime=$(($hour+3))
(crontab -l 2>/dev/null | grep -v $script_file; echo "$minute $hour * * * /home/$USER/$script_file >/dev/null 2>&1") | crontab -
echo "Cronjob added to crontab"

echo
echo "###### Installation Completed Successfully ######"
echo 
read -p "Do you want to quickly create a 2 day EPG? [Y|n] " answer
if [[ -z "$answer" || "$answer" =~ [Y|y] ]] ; then
  echo "Running script from ${dest_folder}/"
  echo "Once the xmltv.xml file is generated, it can be imported into"
  echo "TVHeadend. If it does not appear, check the log"
  echo "at ~/kodi/temp/zap2xml.log or ${dest_folder}/"
  echo 
  /home/$USER/$script_file fast -d 2
  echo "zap2xml.sh script finished"
else
  echo "Generation of xmltv.xml skipped"
fi

echo
echo "### MANUAL CHANGES TO MAKE IN TVHEADEND"
echo "Log into the TVHeadend website"
echo "Configuration -> Channel / EPG -> EPG Grabber"
echo "Find $grab_file and make sure the round circle to the left is checked"
echo "No other row should be checked"
echo "Go to Configuration -> Channel / EPG -> EPG Grabber"
echo "Set the Cron multiline to include"
echo "0 $pulltime \* \* \*"
echo "This will pull in the updated xmltv.xml file at ${pulltime}am every day"
echo "Save the changes"
echo "If you have not generated the xmltv.xml file, the web console at the"
echo "bottom of the web page will error"
echo
echo "Clicking on Re-run Internal EPG Grabbers will manual import"
echo "the xmltv.xml file"
echo
echo "Additional information can be found on the Wiki:"
echo "https://github.com/rocky4546/script.xmltv.tvheadend/wiki/Guide:-How-to-Setup-XMLTV-for-TVHeadEnd"

