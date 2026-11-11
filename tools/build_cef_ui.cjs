// Embed the app at the end of the document: resource WebViews need not support
// deferred external script loading. CSP authorizes only these exact script bytes.
const fs = require('node:fs');
const path = require('node:path');
const {createHash} = require('node:crypto');
const root = path.join(__dirname,'../scriptfiles/cef/lsrp');
const app = fs.readFileSync(path.join(root,'app.js'),'utf8').replace(/\r\n/g,'\n');
const source = `\n(function () {\n${app}\n})();\n`;
const hash = createHash('sha256').update(source).digest('base64');
let html = fs.readFileSync(path.join(root,'index.html'),'utf8');
html = html.replace(/script-src [^;]+;/, `script-src 'sha256-${hash}';`);
html = html.replace(/<!-- CEF_APP_START -->[\s\S]*?<!-- CEF_APP_END -->/, `<!-- CEF_APP_START -->\n<script>${source}</script>\n  <!-- CEF_APP_END -->`);
fs.writeFileSync(path.join(root,'index.html'),html);
console.log('Built CEF page with embedded app and SHA-256 CSP.');
