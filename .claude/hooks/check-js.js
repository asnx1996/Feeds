// PostToolUse: after editing index.html or sw.js, check the JavaScript for syntax errors.
const fs = require('fs');
const vm = require('vm');

let input = '';
process.stdin.on('data', c => input += c).on('end', () => {
  let path = '';
  try { path = JSON.parse(input).tool_input?.file_path || ''; } catch (e) { process.exit(0); }
  const isHtml = /\.html$/i.test(path);
  if (!isHtml && !/\.js$/i.test(path)) process.exit(0);
  if (/[\\/]\.claude[\\/]/.test(path) || !fs.existsSync(path)) process.exit(0);

  const text = fs.readFileSync(path, 'utf8');
  const scripts = [];
  if (isHtml) {
    const re = /<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi;
    let m;
    while ((m = re.exec(text))) {
      const line = text.slice(0, m.index).split('\n').length;
      scripts.push({ code: m[1], line });
    }
  } else {
    scripts.push({ code: text, line: 1 });
  }

  const errors = [];
  scripts.forEach(({ code, line }) => {
    try { new vm.Script(code, { lineOffset: line - 1, filename: path }); }
    catch (e) {
      const at = (e.stack || '').split('\n')[0];
      errors.push(`${at}\n  ${e.message}`);
    }
  });
  if (errors.length) {
    console.error('JavaScript syntax error after edit:\n' + errors.join('\n'));
    process.exit(2);
  }
});
