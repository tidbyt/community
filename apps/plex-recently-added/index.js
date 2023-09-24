var http = require('http');
var request = require('request');
const host = '0.0.0.0';
const port = '6969';
const plexServerHost = 'localhost';
const plexServerPort = '32400';
const API_KEY = "<CUSTOM_API_HERE>";

const server = http.createServer(async (req, res) => {
    if ((req.headers['x-api-key'] || '') != API_KEY) {
        res.writeHead(401);
        res.end();
        return;
    }
    if (req.method === "GET") {
        if (req.url.includes("/library/recentlyAdded") || req.url.includes("/status/sessions") || req.url.includes("/library/metadata")) {
            const _type = req.url.includes("/library/metadata") ? 'image/jpeg' : 'application/json';
            var options = {
                'method': 'GET',
                'url': `http://${plexServerHost}:${plexServerPort}${req.url}?X-Plex-Token=${req.headers['x-plex-token']}`,
                'headers': {
                    'accept': _type
                },
                encoding: null
              };
              request(options, function (error, response) {
                  if (error) throw new Error(error);
                  response.setEncoding('base64')
                  res.writeHead(200, {'Content-Type': _type});
                  res.write(response.body);
                  res.end();
                  console.log(`requested plex at ${Date()}`);
              });
        }
    } else {
        res.writeHead(404);
        res.end();
    }
});

server.listen(port, host, () => {
    console.log(`Plex (tidbyt) proxy server running on http://${host}:${port}`)
})