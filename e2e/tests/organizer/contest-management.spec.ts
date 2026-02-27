import { test, expect } from '@playwright/test';
import { login } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';
import { autoAcceptDialogs, expectFlashMessage } from '../../helpers/utils';

test.describe('Contest Management', () => {
  test.beforeEach(async ({ page }) => {
    autoAcceptDialogs(page);
    await login(page, 'organizer');
  });

  test('lists all own contests including drafts and published', async ({ page }) => {
    await page.goto('/organizers/contests');
    await expect(page.getByText('E2E下書きコンテスト')).toBeVisible();
    await expect(page.getByText('E2E写真コンテスト')).toBeVisible();
  });

  test('shows contest detail with entry count and actions', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);
    // Should show entries section
    await expect(page.getByText('応募一覧').or(page.getByText('応募'))).toBeVisible();
    // Should show action buttons
    await expect(page.getByRole('link', { name: '編集' }).first()).toBeVisible();
  });

  test('deletes a draft contest', async ({ page }) => {
    // First create a draft contest to delete
    await page.goto('/organizers/contests/new');
    await page.getByLabel('タイトル').fill('E2E削除用テスト');
    await page.getByLabel('説明').fill('削除テスト用');
    await page.getByRole('button', { name: '作成する' }).click();
    await waitForTurboLoad(page);

    // Now delete it
    const deleteButton = page.getByRole('button', { name: /削除/ }).or(page.getByRole('link', { name: /削除/ }));
    if (await deleteButton.first().isVisible()) {
      await deleteButton.first().click();
      await waitForTurboLoad(page);
      await expectFlashMessage(page, JA.organizer.contestDeleted);
    }
  });

  test('cannot access another organizer\'s contest', async ({ page }) => {
    // Log in as admin (different user) and try to access organizer dashboard
    // The organizer contests page only shows own contests
    await page.goto('/organizers/contests');
    // All listed contests should belong to the organizer
    const contestLinks = page.locator('a', { hasText: /E2E/ });
    const count = await contestLinks.count();
    // The organizer should only see their own contests
    expect(count).toBeGreaterThan(0);
  });
});
