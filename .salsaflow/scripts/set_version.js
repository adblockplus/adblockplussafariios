var fs = require('fs');

var pkg = JSON.parse(fs.readFileSync('package.json'));
pkg.version = process.argv[2];
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
