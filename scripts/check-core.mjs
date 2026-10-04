import { build } from 'esbuild';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';

const scratch = mkdtempSync(join(tmpdir(), 'bighand-web-checks-'));
try {
  const outfile = join(scratch, 'core.test.mjs');
  await build({ entryPoints: ['tests/core.test.ts'], bundle: true, platform: 'node', format: 'esm', outfile });
  execFileSync(process.execPath, ['--test', outfile], { stdio: 'inherit' });
} finally {
  rmSync(scratch, { recursive: true, force: true });
}
