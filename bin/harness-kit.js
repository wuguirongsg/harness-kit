#!/usr/bin/env node
'use strict';

const { spawnSync } = require('child_process');
const path = require('path');
const os = require('os');

const pkgDir = path.join(__dirname, '..');
const args = process.argv.slice(2);

if (args[0] === '--help' || args[0] === '-h') {
  console.log([
    'Usage: harness-kit [target-dir]',
    '',
    'Install harness-kit into the specified project directory.',
    'If no directory is given, installs into the current directory.',
    '',
    'Options:',
    '  --help, -h     Show this help message',
    '  --version, -v  Show version number',
  ].join('\n'));
  process.exit(0);
}

if (args[0] === '--version' || args[0] === '-v') {
  const pkg = require(path.join(pkgDir, 'package.json'));
  console.log(pkg.version);
  process.exit(0);
}

const targetDir = args[0] || process.cwd();

let result;
if (os.platform() === 'win32') {
  result = spawnSync(
    'cmd',
    ['/c', path.join(pkgDir, 'install.bat'), targetDir],
    { stdio: 'inherit' }
  );
} else {
  result = spawnSync(
    'bash',
    [path.join(pkgDir, 'install.sh'), targetDir],
    { stdio: 'inherit' }
  );
}

process.exit(result.status ?? 0);
