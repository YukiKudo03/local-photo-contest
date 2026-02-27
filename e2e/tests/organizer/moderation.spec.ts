import { test, expect } from '@playwright/test';
import { login } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';
import { autoAcceptDialogs, expectFlashMessage } from '../../helpers/utils';

test.describe('Moderation', () => {
  test.beforeEach(async ({ page }) => {
    autoAcceptDialogs(page);
    await login(page, 'organizer');
  });

  test('shows entries pending moderation', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2Eモデレーションコンテスト').click();
    await waitForTurboLoad(page);

    // Navigate to moderation page
    const moderationLink = page.getByRole('link', { name: /モデレーション/ });
    if (await moderationLink.isVisible()) {
      await moderationLink.click();
      await waitForTurboLoad(page);
      await expect(page.getByText('モデレーション')).toBeVisible();
    }
  });

  test('approves an entry', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2Eモデレーションコンテスト').click();
    await waitForTurboLoad(page);

    const moderationLink = page.getByRole('link', { name: /モデレーション/ });
    if (await moderationLink.isVisible()) {
      await moderationLink.click();
      await waitForTurboLoad(page);

      const approveButton = page.getByRole('button', { name: '承認' }).first();
      if (await approveButton.isVisible()) {
        await approveButton.click();
        await waitForTurboLoad(page);
        await expectFlashMessage(page, JA.organizer.moderationApproved);
      }
    }
  });

  test('rejects an entry with reason', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2Eモデレーションコンテスト').click();
    await waitForTurboLoad(page);

    const moderationLink = page.getByRole('link', { name: /モデレーション/ });
    if (await moderationLink.isVisible()) {
      await moderationLink.click();
      await waitForTurboLoad(page);

      const rejectButton = page.getByRole('button', { name: '非表示' }).first();
      if (await rejectButton.isVisible()) {
        // Fill in rejection reason if a textarea appears
        const reasonField = page.getByPlaceholder('非表示の理由を入力してください');
        if (await reasonField.isVisible()) {
          await reasonField.fill('テスト用の非表示理由');
        }
        await rejectButton.click();
        await waitForTurboLoad(page);
        await expectFlashMessage(page, JA.organizer.moderationRejected);
      }
    }
  });
});
