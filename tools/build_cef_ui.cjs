// Embed the app at the end of the document: resource WebViews need not support
// deferred external script loading. CSP authorizes only these exact script bytes.
const fs = require('node:fs');
const path = require('node:path');
const {createHash} = require('node:crypto');
const root = path.join(__dirname,'../scriptfiles/cef/lsrp');
const app = fs.readFileSync(path.join(root,'auth','app.js'),'utf8').replace(/\r\n/g,'\n');
const source = `\n(function () {\n${app}\n})();\n`;
const hash = createHash('sha256').update(source).digest('base64');
let html = fs.readFileSync(path.join(root,'shell.html'),'utf8');
for (const [marker, folder] of [['AUTH','auth'], ['SELECTOR','character_selector'], ['CREATOR','character_creator']]) {
  html = html.replace(`<!-- ${marker}_VIEW -->`, fs.readFileSync(path.join(root,folder,'view.html'),'utf8'));
}
const styles = ['shared/theme.css','auth/style.css','character_selector/style.css','character_creator/style.css','shared/notifications.css'];
fs.writeFileSync(path.join(root,'style.css'), styles.map(file => fs.readFileSync(path.join(root,file),'utf8')).join('\n'));
html = html.replace(/script-src [^;]+;/, `script-src 'sha256-${hash}';`);
html = html.replace(/<!-- CEF_APP_START -->[\s\S]*?<!-- CEF_APP_END -->/, `<!-- CEF_APP_START -->\n<script>${source}</script>\n  <!-- CEF_APP_END -->`);
fs.writeFileSync(path.join(root,'index.html'),html);
console.log('Built CEF page with embedded app and SHA-256 CSP.');
