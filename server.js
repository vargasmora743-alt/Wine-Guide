const http = require('http');
const fs = require('fs');
const path = require('path');

const port = process.env.PORT || 10000;
const root = path.join(__dirname, 'public');

const server = http.createServer((req, res) => {
  let urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
  if (urlPath === '/') urlPath = '/index.html';

  const filePath = path.normalize(path.join(root, urlPath));
  if (!filePath.startsWith(root)) {
    res.writeHead(403);
    return res.end('Forbidden');
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404, {'Content-Type': 'text/plain; charset=utf-8'});
      return res.end('Not found');
    }
    const ext = path.extname(filePath);
    const types = {
      '.html': 'text/html; charset=utf-8',
      '.css': 'text/css; charset=utf-8',
      '.js': 'application/javascript; charset=utf-8',
      '.json': 'application/json; charset=utf-8',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.svg': 'image/svg+xml'
    };
    res.writeHead(200, {'Content-Type': types[ext] || 'application/octet-stream'});
    res.end(data);
  });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Wine Guide listening on port ${port}`);
});
