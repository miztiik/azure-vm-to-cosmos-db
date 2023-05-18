LOG_FILE=/var/log/miztiik-store-events-producer.log &&\
>$LOG_FILE &&\
REPO_NAME=azure-vm-to-cosmos-db &&\
export APP_CONFIG_NAME=APP_CONFIG_VAR_NAME &&\
echo pwd: $(pwd) >> $LOG_FILE &&\
echo whoami: $(whoami) >> $LOG_FILE &&\
echo which: $(which python3) >> $LOG_FILE &&\
echo USER: ${USER} >> $LOG_FILE &&\
echo PATH: ${PATH} >> $LOG_FILE &&\
echo EVENTS_TO_PRODUCE: $1 >> $LOG_FILE &&\
echo EVENTS_TO_PRODUCE_AS_ENV_VAR: $EVENTS_TO_PRODUCE >> $LOG_FILE &&\
echo which pip : $(which pip) >> $LOG_FILE &&\
echo which pip3 : $(which pip3) >> $LOG_FILE &&\
echo pip version: $(/usr/bin/pip3 --version) >> $LOG_FILE &&\
echo /usr/bin/pip3 show azure.identity: $(/usr/bin/pip3 show azure.identity) >> $LOG_FILE &&\
/usr/bin/python3 /var/$REPO_NAME/app/az_producer_for_cosmos_db.py >> $LOG_FILE &
