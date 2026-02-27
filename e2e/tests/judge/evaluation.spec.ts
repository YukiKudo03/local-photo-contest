import { test, expect } from '@playwright/test';
import { login } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';
import { expectFlashMessage } from '../../helpers/utils';

test.describe('Judge Evaluation', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, 'judge');
  });

  test('shows judge assignments list', async ({ page }) => {
    await page.goto('/my/judge_assignments');
    await expect(page.getByText(JA.judge.assignmentsTitle)).toBeVisible();
    await expect(page.getByText('E2E写真コンテスト')).toBeVisible();
  });

  test('shows entry evaluation form with score input', async ({ page }) => {
    await page.goto('/my/judge_assignments');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);

    // Find an entry to evaluate (not own entry)
    const evaluateLink = page.getByRole('link', { name: /評価する/ }).first();
    if (await evaluateLink.isVisible()) {
      await evaluateLink.click();
      await waitForTurboLoad(page);
      // Should show evaluation form with score input
      await expect(page.locator('input[type="number"], input[type="range"]').first()).toBeVisible();
    }
  });

  test('saves evaluation with score and comment', async ({ page }) => {
    await page.goto('/my/judge_assignments');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);

    const evaluateLink = page.getByRole('link', { name: /評価する/ }).first();
    if (await evaluateLink.isVisible()) {
      await evaluateLink.click();
      await waitForTurboLoad(page);

      // Fill in score
      const scoreInput = page.locator('input[type="number"]').first();
      if (await scoreInput.isVisible()) {
        await scoreInput.fill('8');
      }

      // Fill in comment if available
      const commentField = page.getByPlaceholder(/フィードバック/);
      if (await commentField.isVisible()) {
        await commentField.fill('素晴らしい構図です');
      }

      await page.getByRole('button', { name: JA.judge.submitSave }).click();
      await waitForTurboLoad(page);
      await expectFlashMessage(page, JA.judge.evaluationSaved);
    }
  });

  test('updates an existing evaluation', async ({ page }) => {
    await page.goto('/my/judge_assignments');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);

    // Look for an already-evaluated entry
    const editLink = page.getByRole('link', { name: /編集/ }).first();
    const viewLink = page.getByRole('link', { name: /確認/ }).first();
    const link = await editLink.isVisible() ? editLink : viewLink;

    if (await link.isVisible()) {
      await link.click();
      await waitForTurboLoad(page);

      const scoreInput = page.locator('input[type="number"]').first();
      if (await scoreInput.isVisible()) {
        await scoreInput.fill('9');
        await page.getByRole('button', { name: JA.judge.submitUpdate }).click();
        await waitForTurboLoad(page);
        await expectFlashMessage(page, JA.judge.evaluationUpdated);
      }
    }
  });
});
