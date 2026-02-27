import { test, expect } from '@playwright/test';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';

test.describe('Contest Browsing', () => {
  test('shows published contests and hides drafts', async ({ page }) => {
    await page.goto('/contests');
    await expect(page.getByText(JA.contests.pageTitle)).toBeVisible();
    // Published contest should be visible
    await expect(page.getByText('E2E写真コンテスト')).toBeVisible();
    // Draft contest should NOT be visible
    await expect(page.getByText('E2E下書きコンテスト')).not.toBeVisible();
  });

  test('shows contest details with title, theme, and accepting badge', async ({ page }) => {
    await page.goto('/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);
    await expect(page.getByText('E2E写真コンテスト')).toBeVisible();
    await expect(page.getByText('自然と風景')).toBeVisible();
    await expect(page.getByText(JA.contests.acceptingEntries)).toBeVisible();
  });

  test('shows finished contest with results link', async ({ page }) => {
    await page.goto('/contests');
    await page.getByText('E2E終了コンテスト').click();
    await waitForTurboLoad(page);
    await expect(page.getByText(JA.contests.resultsAnnounced)).toBeVisible();
    await expect(page.getByRole('link', { name: JA.contests.viewResults })).toBeVisible();
  });

  test('shows rankings on results page', async ({ page }) => {
    await page.goto('/contests');
    await page.getByText('E2E終了コンテスト').click();
    await waitForTurboLoad(page);
    await page.getByRole('link', { name: JA.contests.viewResults }).click();
    await waitForTurboLoad(page);
    await expect(page.getByText(JA.results.winnersTitle)).toBeVisible();
    await expect(page.getByText('E2E入賞作品1')).toBeVisible();
  });
});
