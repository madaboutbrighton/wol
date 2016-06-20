#! /bin/sh
#
# Location /etc/kodi/live.d
# Referenced /etc/init/xbmcbuntu.conf
# Dependencies - wakeonlan, mysql-client
# Summary - Wakes a computer and checks for a mySQL connection
#

# Which actions to take
DO_WOL=1
DO_MYSQL=1

# Backend settings
SERVER_MAC='90:2B:34:AE:B5:A0'
SERVER_IP='192.168.1.10'

# mySQL settings on backend
MYSQL_USER='dummy'
MYSQL_PASS='12dummy34'

# Wait settings (in seconds)
WAIT_LAN=1
WAIT_MYSQL=5
WAIT_FINAL=5
WAIT_MAX=300
WAIT_HAPPENED=0
WAIT_COUNT=0
    
if [ $DO_WOL -eq 1 ]; then
  #
  # Issue wakeonlan at intervals until our own network interface
  #  is active and the magic packet is successfully sent.
  #
  echo "Waiting for connection with $SERVER_IP($SERVER_MAC)"

  until /usr/bin/wakeonlan $SERVER_MAC > /dev/null 2>&1 ; do
  
    if [ $WAIT_COUNT -gt $WAIT_MAX ]; then
      echo "Waited too long."
      exit 0;
    fi
  
    WAIT_COUNT=$((WAIT_COUNT + WAIT_LAN))
    WAIT_HAPPENED=1
    sleep $WAIT_LAN
  done

  echo "Connected to $SERVER_IP"
fi

if [ $DO_MYSQL -eq 1 ]; then
  #
  # Try to connect with mysql until it connects successfully
  #
  echo "Waiting for mySQL on $SERVER_IP"

  until mysql -e "SELECT USER();" -h $SERVER_IP -u $MYSQL_USER --password=$MYSQL_PASS > /dev/null 2>&1 ; do

    if [ $WAIT_COUNT -gt $WAIT_MAX ]; then
      echo "Waited too long."
      exit 0;
    fi
  
    WAIT_COUNT=$((WAIT_COUNT + WAIT_MYSQL))
    WAIT_HAPPENED=1
    sleep $WAIT_MYSQL
  done

  echo "Connected to mySQL on $SERVER_IP"
fi

#
# An extra wait is required if mysql was not already running
#
if [ $WAIT_HAPPENED -eq 1 ]; then
	sleep $WAIT_FINAL
fi
	
exit 0