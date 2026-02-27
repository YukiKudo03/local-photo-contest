import { test, expect } from '@playwright/test';
import { login, USERS } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';

test.describe('User Login', () => {
  test('participant logs in and sees their email in header', async ({ page }) => {
    await login(page, 'participant');
    await expect(page.getByText(USERS.participant.email)).toBeVisible();
  });

  test('organizer logs in and sees dashboard link', async ({ page }) => {
    await login(page, 'organizer');
    await expect(page.getByRole('link', { name: JA.header.dashboard })).toBeVisible();
  });

  test('admin logs in and sees admin panel link', async ({ page }) => {
    await login(page, 'admin');
    await expect(page.getByRole('link', { name: JA.header.adminPanel })).toBeVisible();
  });

  test('shows error with wrong password', async ({ page }) => {
    await page.goto('/organizers/sign_in');
    await page.getByLabel(JA.auth.email).fill(USERS.participant.email);
    await page.getByLabel(JA.auth.password, { exact: true }).fill('wrongpassword');
    await page.getByRole('button', { name: JA.auth.loginButton }).click();
    await waitForTurboLoad(page);
    await expect(page.getByText(JA.auth.invalidCredentials)).toBeVisible();
  });

  test('unconfirmed user cannot log in', async ({ page }) => {
    // Register a new user (unconfirmed) and try to log in
    const email = `unconfirmed-${Date.now()}@e2e.test`;
    await page.goto('/organizers/sign_up');
    await page.getByLabel(JA.auth.email).fill(email);
    await page.getByLabel(JA.auth.password, { exact: true }).fill('password123');
    await page.getByLabel(JA.auth.passwordConfirmation).fill('password123');
    await page.getByRole('button', { name: JA.auth.registerButton }).click();
    await waitForTurboLoad(page);

    // Now try to log in
    await page.goto('/organizers/sign_in');
    await page.getByLabel(JA.auth.email).fill(email);
    await page.getByLabel(JA.auth.password, { exact: true }).fill('password123');
    await page.getByRole('button', { name: JA.auth.loginButton }).click();
    await waitForTurboLoad(page);
    await expect(page.getByText(JA.auth.unconfirmed)).toBeVisible();
  });
});
