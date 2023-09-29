var dorita980 = require('dorita980');
var http = require('http');
var url = require('url');

/*** how to get below BLID and PASSWORD
1. $ npm install -g dorita980
2. $ get-roomba-password-cloud <iRobot Username> <iRobot Password> [Optional API-Key]
***/

const BLID = '_BLID_HERE_';
const PASSWORD = '_PASSWORD_HERE_';
const API_KEY = 'ADD_YOUR_OWN_API_KEY_HERE_AND_ADD_IN_TIDBYT_CONFIG';

const HOST = '0.0.0.0';
const PORT = '6565';

var myRobotViaLocal;
dorita980.getRobotIP((ierr, ip) => {
    myRobotViaLocal = new dorita980.Local(BLID, PASSWORD, ip);
});

const server = http.createServer((req, res) => {
    if (req.method === "GET") {
        if (req.headers['x-api-key'] != API_KEY) {
            res.writeHead(401);
            res.end();
            return;
        }
        var _req = url.parse(req.url, true);
        switch (_req.pathname) {
            case '/status':
                myRobotViaLocal.getRobotState(['batPct']).then((state) => {
                    res.writeHead(200, {'Content-Type': 'application/json'});
                    res.write(JSON.stringify(state));
                    res.end();
                    console.log(`request made to roomba at ${Date()}`);
                    // myRobotViaLocal.end();
                }).catch((err) => {
                    console.error(err);
                });
                break;
            default:
                res.writeHead(404);
                res.end();
        }
    } else {
        res.writeHead(404);
        res.end();
    }
});

server.listen(PORT, HOST, () => {
    console.log(`Roomba API server running on http://${HOST}:${PORT}`)
})