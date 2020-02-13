#!/bin/bash
set -e

function do_help {
  echo HELP:
  echo "Supported commands:"
  echo "   hadoop-nm              - Start Hadoop Namenode"
  echo "   hive-metastore         - Start Hive Metastore"
  echo "   impala-state-store     - Start Impala Statestore"
  echo "   impala-catalog         - Start Impala Catalog"
  echo "   impala-server          - Start Impala Server and Hadoop Datanode"
  echo "   standalone             - Start Standalone mode for Impala for Test"
  echo "   help                   - print useful information and exit"
  echo ""
  echo "Other commands can be specified to run shell commands."
  #echo "Set the environment variable KUDU_OPTS to pass additional"
  #echo "arguments to the kudu process. DEFAULT_KUDU_OPTS contains"
  echo "a recommended base set of options."

  exit 0
}

KUDU_MASTERS=${KUDU_MASTERS:=""}

IMPALA_CATALOG_SERVICE_HOST=${IMPALA_CATALOG_SERVICE_HOST:="impala-catalog"}
IMPALA_STATE_STORE_HOST=${IMPALA_STATE_STORE_HOST:="impala-state-store"}

IMPALA_STATE_STORE_PORT=24000
IMPALA_BACKEND_PORT=22000
IMPALA_LOG_DIR=/var/log/impala

IMPALA_CATALOG_ARGS=" -log_dir=${IMPALA_LOG_DIR} -state_store_host=${IMPALA_STATE_STORE_HOST}"
IMPALA_STATE_STORE_ARGS=" -log_dir=${IMPALA_LOG_DIR} -state_store_port=${IMPALA_STATE_STORE_PORT}"


chmod +x /wait-for-it.sh


if [[ "$1" == "hadoop-nm" ]]; then

  echo "Formatting HDFS..."
  service hadoop-hdfs-namenode init

  /etc/init.d/hadoop-hdfs-namenode start

  sudo -u hdfs hdfs dfs -chmod 777 /
 
elif [[ "$1" == "hive-metastore" ]]; then
   # PostgreSQL depandency
   /wait-for-it.sh postgres:5432 -t 120

   psql -h postgres -U postgres -c "CREATE DATABASE metastore;" 2>/dev/null

   /usr/lib/hive/bin/schematool -dbType postgres -initSchema
  
   /etc/init.d/hive-metastore start

elif [[ "$1" == "impala-state-store" ]]; then
   #/etc/init.d/impala-state-store start
   /bin/su -s /bin/bash -c "/bin/bash -c 'cd ~ && exec /usr/bin/statestored ${IMPALA_CATALOG_ARGS} >>${IMPALA_LOG_DIR}/impala-state-store.log 2>&1' &" impala

elif [[ "$1" == "impala-catalog" ]]; then
  # Hive-Metastore depandency  
  /wait-for-it.sh hive-metastore:9083 -t 120

  #/etc/init.d/impala-catalog start
  /bin/su -s /bin/bash -c "/bin/bash -c 'cd ~ && exec /usr/bin/catalogd ${IMPALA_CATALOG_ARGS} >>${IMPALA_LOG_DIR}/impala-catalog.log 2>&1' &" impala

elif [[ "$1" == "impala-server" ]]; then

#  /wait-for-it.sh kudu-master-1:7051 -t 120
#  /wait-for-it.sh kudu-master-2:7051 -t 120
#  /wait-for-it.sh kudu-master-3:7051 -t 120

   if [[ -n "$KUDU_MASTERS" ]]; then
    IMPALA_SERVER_ARGS=" \
      -log_dir=${IMPALA_LOG_DIR} \
      -catalog_service_host=${IMPALA_CATALOG_SERVICE_HOST} \
      -state_store_port=${IMPALA_STATE_STORE_PORT} \
      -state_store_host=${IMPALA_STATE_STORE_HOST} \
      -be_port=${IMPALA_BACKEND_PORT} \
      -kudu_master_hosts=$KUDU_MASTERS"
   else
    IMPALA_SERVER_ARGS=" \
      -log_dir=${IMPALA_LOG_DIR} \
      -catalog_service_host=${IMPALA_CATALOG_SERVICE_HOST} \
      -state_store_port=${IMPALA_STATE_STORE_PORT} \
      -state_store_host=${IMPALA_STATE_STORE_HOST} \
      -be_port=${IMPALA_BACKEND_PORT}"
   fi


   /etc/init.d/hadoop-hdfs-datanode start
  
   #/etc/init.d/impala-server start
   /bin/su -s /bin/bash -c "/bin/bash -c 'cd ~ && exec /usr/bin/impalad ${IMPALA_SERVER_ARGS} >>${IMPALA_LOG_DIR}/impala-server.log 2>&1' &" impala

elif [[ "$1" == "standalone" ]]; then

  echo "=========== Standalone for Test ==============="
  
  echo "=========== HDFS start ==============="
  service hadoop-hdfs-namenode init
  /etc/init.d/hadoop-hdfs-namenode start
  /etc/init.d/hadoop-hdfs-datanode start

  sudo -u hdfs hdfs dfs -chmod 777 /

  echo "=========== HDFS end ==============="


  echo "=========== hive (Embedded DB : Derby) setup start ==============="
  # Init Schema
  sudo -u hive /usr/lib/hive/bin/schematool -initSchema -dbType derby
  # Service Start
  /etc/init.d/hive-metastore start
  #echo "=========== hive (Embedded DB : Derby) setup end ==============="


  echo "===========Impala Service start ==============="
  /etc/init.d/impala-state-store start
  /etc/init.d/impala-catalog start
  /etc/init.d/impala-server start
  echo "=========== Impala Service end ==============="


elif [[ "$1" == "help" ]]; then
  print_help
  exit 0
fi


# Container Run without stopping
tail -f /dev/null

