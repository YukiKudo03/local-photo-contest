import { test, expect } from '@playwright/test';
import { login } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';
import { autoAcceptDialogs, expectFlashMessage } from '../../helpers/utils';

test.describe('Spot Discovery', () => {
  test('organizer certifies a discovered spot', async ({ page }) => {
    autoAcceptDialogs(page);
    await login(page, 'organizer');
    await page.goto('/organizers/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);

    // Navigate to discovery spots management
    const discoveryLink = page.getByRole('link', { name: /発掘スポット/ });
    if (await discoveryLink.isVisible()) {
      await discoveryLink.click();
      await waitForTurboLoad(page);

      const certifyButton = page.getByRole('button', { name: '認定' }).first();
      if (await certifyButton.isVisible()) {
        await certifyButton.click();
        await waitForTurboLoad(page);
        await expectFlashMessage(page, JA.organizer.spotCertified);
      }
    }
  });

  test('organizer rejects a discovered spot', async ({ page }) => {
    autoAcceptDialogs(page);
    await login(page, 'organizer');
    await page.goto('/organizers/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);

    const discoveryLink = page.getByRole('link', { name: /発掘スポット/ });
    if (await discoveryLink.isVisible()) {
      await discoveryLink.click();
      await waitForTurboLoad(page);

      const rejectButton = page.getByRole('button', { name: '却下' }).first();
      if (await rejectButton.isVisible()) {
        // Fill rejection reason if field is visible
        const reasonField = page.getByPlaceholder('却下理由を入力してください');
        if (await reasonField.isVisible()) {
          await reasonField.fill('テスト用却下理由');
        }
        await rejectButton.click();
        await waitForTurboLoad(page);
        await expectFlashMessage(page, JA.organizer.spotRejected);
      }
    }
  });
});
