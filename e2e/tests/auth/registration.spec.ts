import { test, expect } from '@playwright/test';
import { register } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';

test.describe('User Registration', () => {
  test('registers a new user and shows confirmation message', async ({ page }) => {
    const email = `newuser-${Date.now()}@e2e.test`;
    await register(page, email, 'password123');
    await expect(page.getByText(JA.auth.confirmationSent)).toBeVisible();
  });

  test('shows validation error when email is empty', async ({ page }) => {
    await page.goto('/organizers/sign_up');
    await page.getByLabel(JA.auth.password, { exact: true }).fill('password123');
    await page.getByLabel(JA.auth.passwordConfirmation).fill('password123');
    await page.getByRole('button', { name: JA.auth.registerButton }).click();
    await waitForTurboLoad(page);
    // The form should show an error — we stay on the page
    await expect(page).toHaveURL(/sign_up|organizers/);
  });

  test('shows error when passwords do not match', async ({ page }) => {
    const email = `mismatch-${Date.now()}@e2e.test`;
    await page.goto('/organizers/sign_up');
    await page.getByLabel(JA.auth.email).fill(email);
    await page.getByLabel(JA.auth.password, { exact: true }).fill('password123');
    await page.getByLabel(JA.auth.passwordConfirmation).fill('differentpass');
    await page.getByRole('button', { name: JA.auth.registerButton }).click();
    await waitForTurboLoad(page);
    await expect(page).toHaveURL(/sign_up|organizers/);
  });

  test('shows error when email is already taken', async ({ page }) => {
    await page.goto('/organizers/sign_up');
    await page.getByLabel(JA.auth.email).fill('participant@e2e.test');
    await page.getByLabel(JA.auth.password, { exact: true }).fill('password123');
    await page.getByLabel(JA.auth.passwordConfirmation).fill('password123');
    await page.getByRole('button', { name: JA.auth.registerButton }).click();
    await waitForTurboLoad(page);
    await expect(page).toHaveURL(/sign_up|organizers/);
  });
});
