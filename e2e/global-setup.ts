import { execSync } from 'child_process';
import path from 'path';

export default function globalSetup() {
  const projectRoot = path.resolve(__dirname, '..');
  console.log('Running e2e:reset to prepare test database...');
  execSync('bin/rails e2e:reset', {
    cwd: projectRoot,
    env: { ...process.env, RAILS_ENV: 'test' },
    stdio: 'inherit',
    timeout: 120_000,
  });
  console.log('E2E test data ready.');
}
