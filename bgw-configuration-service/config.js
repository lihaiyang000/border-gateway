let config = {
    bind_port: 5056,
    redis_port: 6379,
    redis_host: undefined,
    aaa_client: {
        name: "configuration-service",
        log_level: "",
        no_timestamp: false
    },
    no_auth: false,
    auth_service: "http://localhost:5053/auth",
    openidConnectProviderName: undefined

};
const fs = require('fs');
const configFromFile = require('../config/config.json');
Object.assign(config,configFromFile["configuration-service"]);
//require('../bgw-aaa-client').init("CONFIGURATION_SERVICE", config);
module.exports = config;
