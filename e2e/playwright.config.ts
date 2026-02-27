import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? 'html' : 'list',
  use: {
    baseURL: 'http://localhost:3001',
    extraHTTPHeaders: { 'Accept-Language': 'ja' },
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
  globalSetup: './global-setup.ts',
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'cd .. && RAILS_ENV=test bin/rails server -p 3001',
    url: 'http://localhost:3001/health',
    timeout: 120_000,
    reuseExistingServer: !process.env.CI,
  },
});
