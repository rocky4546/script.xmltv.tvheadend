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

#
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
    echo "Please download file from http://zap2xml.awardspace.info"
    echo "and place into the folder containing install.sh"
    echo
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
  sudo ln -s $dest_folder $htshome/.xmltv
  sudo chown -h $htsuser:$htsuser $htshome/.xmltv
  if [ ! -L $htshome/.xmltv ] ; then
    echo "Unable to create softlink $htshome/.xmltv.  Is there a file/folder already there?"
    echo "If so, try removing the file/folder and running the install script again"
    exit
  fi
else
  echo "Softlink $htshome/.xmltv already exists, skipping"
fi

echo
echo "### Installing $grab_file"
isRedeploy=true
if [ -x /$grab_file ] ; then
  echo "WARNING: Found /$grab_file already present"
  read -p "Replace /$grab_file? [N]" answer
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
  echo "Checking to see if TVHeadend knows about the new file"
  present=`sudo grep $grab_file ~hts/.hts/tvheadend/epggrab/config`
  if [[ -z "$present" ]] ; then
    echo "ERROR: TVHeadend has not recognized the new $grab_file"
    echo "try rebooting and logging into the TVHeadend website"
    echo "Once the $grab_file appears in the EPG Grabber Modules list"
    echo "Rerun this installation script"
    exit
  fi
else
  echo "/$grab_file not deployed, skipping"
fi

echo
echo "### Deploying $rc_file file"

isRedeploy=true
if [[ -f ~/$rc_file ]] ; then
  echo "WARNING: Found ~/$rc_file already present"
  read -p "Replace $rc_file? [N]" answer
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
  response=`curl -w   -o /dev/null -w "%{http_code}" -X POST -F "username=${zap2itEmail}" -F "password=$zap2itPassword" http://tvschedule.zap2it.com/tvlistings/ZCLogin.do 2>/dev/null`
  if [[ "$response" != "000302" ]] ; then
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
read -p "What hour do you want the cronjob to run? (Recommend between 0 and 7) " hour
# random generate the minute between 5 and 55
minute=$(((RANDOM % 55)+5))
pulltime=$(($hour+3))
(crontab -l 2>/dev/null | grep -v $script_file; echo "$minute $hour * * * /home/$USER/xmltv/$script_file >/dev/null 2>&1") | crontab -
echo "Cronjob added to crontab"

echo
echo "###### Installation Completed Successfully ######"

echo
echo "### MANUAL CHANGES TO MAKE IN TVHEADEND"
echo "Log into the TVHeadend website"
echo "Configuration -> Channel / EPG -> EPG Grabber"
echo "Find $grab_file and make sure the round circle to the left is checked"
echo "No other row should be checked"
echo "Go to Configuration -> Channel / EPG -> EPG Grabber
echo "Set the Cron multiline to include"
echo "0 $pulltime \* \* \*"
echo "This will pull in the updated xmltv.xml file at 8am every day"
echo "Save the changes"
echo
echo "Additional information can be found on the Wiki:
echo "https://github.com/rocky4546/script.xmltv.tvheadend/wiki/Guide:-How-to-Setup-XMLTV-for-TVHeadEnd"



