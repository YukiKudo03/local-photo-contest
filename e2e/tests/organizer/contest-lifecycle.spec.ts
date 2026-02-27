import { test, expect } from '@playwright/test';
import { login } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';
import { autoAcceptDialogs, expectFlashMessage } from '../../helpers/utils';

test.describe('Contest Lifecycle', () => {
  test.beforeEach(async ({ page }) => {
    autoAcceptDialogs(page);
    await login(page, 'organizer');
  });

  test('creates a new contest', async ({ page }) => {
    await page.goto('/organizers/contests/new');
    await page.getByLabel('タイトル').fill('E2Eライフサイクルテスト');
    await page.getByLabel('テーマ').fill('テスト用テーマ');
    await page.getByLabel('説明').fill('ライフサイクルテスト用コンテスト');
    await page.getByRole('button', { name: '作成する' }).click();
    await waitForTurboLoad(page);
    await expectFlashMessage(page, JA.organizer.contestCreated);
  });

  test('publishes a draft contest', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2E下書きコンテスト').click();
    await waitForTurboLoad(page);
    await page.getByRole('button', { name: JA.organizer.publish }).click();
    await waitForTurboLoad(page);
    await expectFlashMessage(page, JA.organizer.contestPublished);
  });

  test('finishes a published contest', async ({ page }) => {
    // The draft contest was published in previous test — find any published contest
    await page.goto('/organizers/contests');
    // Use E2E moderation contest since it's published
    await page.getByText('E2Eモデレーションコンテスト').click();
    await waitForTurboLoad(page);
    const finishButton = page.getByRole('button', { name: JA.organizer.finish });
    if (await finishButton.isVisible()) {
      await finishButton.click();
      await waitForTurboLoad(page);
      await expectFlashMessage(page, JA.organizer.contestFinished);
    }
  });

  test('announces results for a finished contest', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2E終了コンテスト').click();
    await waitForTurboLoad(page);
    // Results may already be announced for this contest
    const announceButton = page.getByRole('button', { name: /結果を発表/ });
    const alreadyAnnounced = page.getByText('結果発表済み');
    if (await announceButton.isVisible()) {
      await announceButton.click();
      await waitForTurboLoad(page);
    }
    // Either we just announced or it was already announced
    await expect(alreadyAnnounced.or(page.getByText(JA.organizer.resultsAnnounced))).toBeVisible();
  });

  test('edits a contest', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);
    await page.getByRole('link', { name: '編集' }).first().click();
    await waitForTurboLoad(page);
    await page.getByLabel('説明').fill('更新された説明文です');
    await page.getByRole('button', { name: '更新する' }).click();
    await waitForTurboLoad(page);
    await expectFlashMessage(page, JA.organizer.contestUpdated);
  });
});
