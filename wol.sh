#! /bin/sh
#
# Location /etc/kodi/live.d
# Referenced /etc/init/xbmcbuntu.conf
# Dependencies - wakeonlan, mysql-client
# Summary - Wakes a computer and checks for a mySQL connection
#

## Change the follwing settings as required ##

# Which actions to take
DO_WOL=1
DO_MYSQL=1

# Backend settings
SERVER_MAC='MA:CA:DD:RE:SS:00'
SERVER_IP='192.168.999.666'

# mySQL settings on backend
MYSQL_USER='dummy'
MYSQL_PASS='mydummymysqlpassword'

# Wait settings (in seconds)
WAIT_LAN=1
WAIT_MYSQL=5
WAIT_FINAL=5
WAIT_MAX=40

## Not recommended to change anything below this line ##

timesofar=0
    
if [ $DO_WOL -eq 1 ]; then
  #
  # Issue wakeonlan at intervals until our own network interface
  #  is active and the magic packet is successfully sent.
  #
  echo "Waiting for client network interface to become active"

  until /usr/bin/wakeonlan $SERVER_MAC > /dev/null 2>&1 ; do
  
    if [ $timesofar -gt $WAIT_MAX ]; then
      echo "Waited too long"
      exit 0;
    fi
  
    timesofar=$((timesofar + WAIT_LAN))

    sleep $WAIT_LAN
  done

  echo "  -Client network interface is active"
  
  #
  # Issue ping at intervals until reply received
  #
  echo "Waiting for reply from $SERVER_IP (MAC - $SERVER_MAC)"
  
  pingcount=0
  
  until [ ${pingcount:-0} -gt 0 ]; do
  
    if [ $timesofar -gt $WAIT_MAX ]; then
      echo "Waited too long"
      exit 0;
    fi
  
    pingcount=$(ping -c1 $SERVER_IP | grep 'received' | awk -F ',' '{print $2}' | awk '{ print $1}')
  
    timesofar=$((timesofar + WAIT_LAN))

    sleep $WAIT_LAN
  done

  echo "  -Reply received"
fi

if [ $DO_MYSQL -eq 1 ]; then
  #
  # Try to connect with mysql until it connects successfully
  #
  echo "Waiting for mySQL on $SERVER_IP"

  until mysql -e "SELECT USER();" -h $SERVER_IP -u $MYSQL_USER --password=$MYSQL_PASS > /dev/null 2>&1 ; do

    if [ $timesofar -gt $WAIT_MAX ]; then
      echo "Waited too long"
      exit 0;
    fi
  
    timesofar=$((timesofar + WAIT_MYSQL))

    sleep $WAIT_MYSQL
  done

  echo "  -Connected to mySQL on $SERVER_IP"
  
  # An extra wait is required if mySQL was not already running
  if [ $timesofar -gt 0 ]; then
    sleep $WAIT_FINAL
  fi
fi
	
echo "Success"
  
exit 0
