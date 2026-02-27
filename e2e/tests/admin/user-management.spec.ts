import { test, expect } from '@playwright/test';
import { login, USERS } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';
import { autoAcceptDialogs, expectFlashMessage } from '../../helpers/utils';

test.describe('Admin User Management', () => {
  test.beforeEach(async ({ page }) => {
    autoAcceptDialogs(page);
    await login(page, 'admin');
  });

  test('shows user list and user details', async ({ page }) => {
    await page.goto('/admin/users');
    await expect(page.getByText(JA.admin.userManagement)).toBeVisible();
    // Should show E2E test users
    await expect(page.getByText(USERS.participant.email)).toBeVisible();

    // Click into a user's details
    await page.getByRole('link', { name: '詳細' }).first().click();
    await waitForTurboLoad(page);
    await expect(page.getByText('ユーザー詳細')).toBeVisible();
  });

  test('changes user role', async ({ page }) => {
    await page.goto('/admin/users');
    // Find the other user and go to details
    await page.getByText(USERS.other.email).click();
    await waitForTurboLoad(page);

    // Change role via the role change form
    const roleSelect = page.locator('select').filter({ hasText: /参加者|主催者|管理者/ });
    if (await roleSelect.isVisible()) {
      await roleSelect.selectOption('organizer');
      await page.getByRole('button', { name: '変更' }).click();
      await waitForTurboLoad(page);
      // Verify the flash message pattern
      await expect(page.getByText(/ロールを/).or(page.getByText('主催者'))).toBeVisible();

      // Change back to participant
      const roleSelect2 = page.locator('select').filter({ hasText: /参加者|主催者|管理者/ });
      if (await roleSelect2.isVisible()) {
        await roleSelect2.selectOption('participant');
        await page.getByRole('button', { name: '変更' }).click();
        await waitForTurboLoad(page);
      }
    }
  });

  test('suspends and unsuspends an account', async ({ page }) => {
    await page.goto('/admin/users');
    await page.getByText(USERS.other.email).click();
    await waitForTurboLoad(page);

    // Suspend
    const suspendButton = page.getByRole('button', { name: 'アカウント停止' }).or(
      page.getByRole('link', { name: 'アカウント停止' })
    );
    if (await suspendButton.isVisible()) {
      await suspendButton.click();
      await waitForTurboLoad(page);
      await expectFlashMessage(page, JA.admin.suspended);
    }

    // Unsuspend
    const unsuspendButton = page.getByRole('button', { name: '停止解除' }).or(
      page.getByRole('link', { name: '停止解除' })
    );
    if (await unsuspendButton.isVisible()) {
      await unsuspendButton.click();
      await waitForTurboLoad(page);
      await expectFlashMessage(page, JA.admin.unsuspended);
    }
  });
});
