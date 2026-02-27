import { test, expect } from '@playwright/test';
import { login, logout } from '../../helpers/auth';
import { JA } from '../../helpers/locale';

test.describe('User Logout', () => {
  test('logs out and redirects to root with login link visible', async ({ page }) => {
    await login(page, 'participant');
    await logout(page);
    await expect(page).toHaveURL('/');
    await expect(page.getByRole('link', { name: JA.header.login })).toBeVisible();
  });
});
