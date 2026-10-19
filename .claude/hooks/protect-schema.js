// PreToolUse: schema.sql is the original setup script. Schema changes go in a new migration file.
let input = '';
process.stdin.on('data', c => input += c).on('end', () => {
  let path = '';
  try { path = JSON.parse(input).tool_input?.file_path || ''; } catch (e) { process.exit(0); }
  if (/(^|[\\/])schema\.sql$/i.test(path)) {
    console.error('schema.sql is locked. Put schema changes in a new file, e.g. migrations/YYYYMMDD_name.sql.');
    process.exit(2);
  }
});
