#!/bin/bash

function run_service {
  node -r dotenv/config ./node_modules/iot-bgw-$1/index.js dotenv_config_path=./node_modules/config.env &
}
function run__dev_service {
  node -r dotenv/config ./node_modules/nodemon/bin/nodemon -w ./dev/iot-bgw-aaa-client -w ./dev/iot-bgw-$1 ./dev/iot-bgw-$1/index.js dotenv_config_path=./node_modules/config.env &
}

if [ "$1" = "build" ]; then
    echo Building the dependencies for all components...
    npm install --only=dev
    cd dev/iot-bgw-external-interface && git checkout master && npm install && cd ../..
    cd dev/iot-bgw-auth-server && git checkout master && npm install && cd ../..
    cd dev/iot-bgw-mqtt-proxy && git checkout master && npm install && cd ../..
    cd dev/iot-bgw-http-proxy && git checkout master && npm install && cd ../..
    cd dev/iot-bgw-aaa-client && git checkout master && npm install && cd ../..
    echo Finished building the dependencies for all components
    exit 0

elif [ "$1" = "part" ]; then

    node json2env.js
    if [ "$2" = "http2https" ]; then
      node -r dotenv/config http2https.js dotenv_config_path=./node_modules/config.env
    else
      node -r dotenv/config ./node_modules/iot-bgw-$2/index.js dotenv_config_path=./node_modules/config.env
    fi

elif [ "$1" = "service" ]; then

    node json2env.js
    node -r dotenv/config http2https.js dotenv_config_path=./node_modules/config.env  &
    hs_pid=$!
    run_service external-interface
    ei_pid=$!
    run_service http-proxy
    ht_pid=$!
    run_service mqtt-proxy
    mq_pid=$!
    run_service auth-server
    as_pid=$!

    if [ "$2" = "benchmark" ]; then
      HTTP_PROXY_DIRECT_TLS_MODE=5099 run_service http-proxy
      bnh_pid=$!
      MQTT_PROXY_DIRECT_TLS_MODE=5098 run_service mqtt-proxy
      bnm_pid=$!
    fi
    trap 'kill $hs_pid ; kill $ei_pid ; kill $ht_pid ; kill $mq_pid ; kill $as_pid ; [ "$bnh_pid" != "" ] && kill $bnh_pid ; [ "$bnm_pid" != "" ] && kill $bnm_pid ; echo shutting down ; exit 0' INT

    while true
    do
        sleep 1
    done


elif [ "$1" = "dev" ]; then

    node json2env.js
    node -r dotenv/config http2https.js dotenv_config_path=./node_modules/config.env &
    hs_pid=$!
    run__dev_service external-interface
    ei_pid=$!
    run__dev_service http-proxy
    ht_pid=$!
    run__dev_service mqtt-proxy
    mq_pid=$!
    run__dev_service auth-server
    as_pid=$!

    trap 'kill $hs_pid ;kill $ei_pid ; kill $ht_pid ; kill $mq_pid ; kill $as_pid ;  echo shutting down ; exit 0' INT

    while true
    do
        sleep 1
    done

elif [ "$1" = "forever" ]; then

    trap './node_modules/.bin/forever stopall ; exit 0' INT

    node json2env.js && \
    ./node_modules/.bin/forever --minUptime=1000 --spinSleepTime=1000 forever.json --colors  dotenv_config_path=./node_modules/config.env &

    while true
    do
        sleep 1
    done
else
  echo
  echo choose the correct bgw option
  echo
  echo
  echo -e  '\t'     bgw forever            '\t\t\t\t' uses forever to ensure process never exist \(default for docker single container\)
  echo
  echo -e  '\t'     bgw part \$part_name   '\t\t\t' used for docker_compose to run each proccess in a docoer container
  echo
  echo -e  '\t'     bgw service            '\t\t\t\t' Run all bgw components
  echo
  echo -e  '\t'     bgw service benchmark  '\t\t\t' Run all bgw components plus duplicates http and mqtt proxy
  echo
  echo -e  '\t'     bgw dev                '\t\t\t\t' Run bgw in dev mode using nodemon with reload on change
  echo
fi
