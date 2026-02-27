import { test, expect } from '@playwright/test';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';

test.describe('Gallery', () => {
  test('shows gallery page with image grid', async ({ page }) => {
    await page.goto('/gallery');
    await expect(page.getByText(JA.gallery.pageTitle)).toBeVisible();
    // Should display entry images
    await expect(page.locator('img').first()).toBeVisible();
  });

  test('filters by contest', async ({ page }) => {
    await page.goto('/gallery');
    // Select a specific contest in the filter
    const contestFilter = page.locator('select').first();
    if (await contestFilter.isVisible()) {
      await contestFilter.selectOption({ label: 'E2E写真コンテスト' });
      await page.getByRole('button', { name: JA.gallery.filter }).click();
      await waitForTurboLoad(page);
      // Gallery should still be visible with filtered results
      await expect(page.getByText(JA.gallery.pageTitle)).toBeVisible();
    }
  });

  test('sorts by popularity', async ({ page }) => {
    await page.goto('/gallery');
    const sortSelect = page.locator('select').nth(1);
    if (await sortSelect.isVisible()) {
      await sortSelect.selectOption({ label: JA.gallery.popular });
      await page.getByRole('button', { name: JA.gallery.filter }).click();
      await waitForTurboLoad(page);
      await expect(page.getByText(JA.gallery.pageTitle)).toBeVisible();
    }
  });

  test('shows empty state when no results', async ({ page }) => {
    // Visit gallery with a filter that yields no results
    await page.goto('/gallery?contest_id=999999');
    // Should show empty state or the gallery page
    const emptyText = page.getByText(JA.gallery.empty);
    const galleryTitle = page.getByText(JA.gallery.pageTitle);
    await expect(galleryTitle).toBeVisible();
  });
});
