import { test, expect } from '@playwright/test';
import { login } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';
import { uploadPhoto, expectFlashMessage } from '../../helpers/utils';

test.describe('Entry Submission', () => {
  test('submits entry with photo and all fields', async ({ page }) => {
    await login(page, 'participant');
    await page.goto('/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);
    await page.getByRole('link', { name: JA.contests.submitEntry }).click();
    await waitForTurboLoad(page);

    await uploadPhoto(page);
    await page.getByLabel(JA.entries.titleLabel).fill('E2Eテスト投稿');
    await page.getByLabel(JA.entries.descriptionLabel).fill('テスト説明文');
    await page.getByLabel(JA.entries.locationLabel).fill('東京都渋谷区');
    await page.getByRole('button', { name: JA.entries.submit }).click();
    await waitForTurboLoad(page);

    await expectFlashMessage(page, JA.flash.entryCreated);
  });

  test('submits entry with photo only (minimal input)', async ({ page }) => {
    await login(page, 'other');
    await page.goto('/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);
    await page.getByRole('link', { name: JA.contests.submitEntry }).click();
    await waitForTurboLoad(page);

    await uploadPhoto(page);
    await page.getByRole('button', { name: JA.entries.submit }).click();
    await waitForTurboLoad(page);

    await expectFlashMessage(page, JA.flash.entryCreated);
  });

  test('shows validation error when no photo is attached', async ({ page }) => {
    await login(page, 'participant');
    await page.goto('/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);
    await page.getByRole('link', { name: JA.contests.submitEntry }).click();
    await waitForTurboLoad(page);

    // Submit without photo
    await page.getByRole('button', { name: JA.entries.submit }).click();
    await waitForTurboLoad(page);

    // Should stay on form with error
    await expect(page.locator('.field_with_errors, [class*="error"], [class*="alert"]').first()).toBeVisible();
  });

  test('finished contest has no submit button', async ({ page }) => {
    await login(page, 'participant');
    await page.goto('/contests');
    await page.getByText('E2E終了コンテスト').click();
    await waitForTurboLoad(page);
    await expect(page.getByRole('link', { name: JA.contests.submitEntry })).not.toBeVisible();
  });

  test('unauthenticated user is redirected to login', async ({ page }) => {
    // Try to access entry form directly
    await page.goto('/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);

    // The page should show login link instead of submit button for unauthenticated users
    // or redirect when trying to access new entry form
    const submitLink = page.getByRole('link', { name: JA.contests.submitEntry });
    if (await submitLink.isVisible()) {
      await submitLink.click();
      await waitForTurboLoad(page);
      await expect(page).toHaveURL(/sign_in/);
    } else {
      // Login link should be visible instead
      await expect(page.getByText('ログイン')).toBeVisible();
    }
  });
});
