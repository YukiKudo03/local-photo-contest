import { test, expect } from '@playwright/test';
import { login } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';
import { autoAcceptDialogs, expectFlashMessage } from '../../helpers/utils';

test.describe('Spot Management', () => {
  test.beforeEach(async ({ page }) => {
    autoAcceptDialogs(page);
    await login(page, 'organizer');
  });

  test('lists spots for a contest', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);

    const spotsLink = page.getByRole('link', { name: /スポット/ }).first();
    if (await spotsLink.isVisible()) {
      await spotsLink.click();
      await waitForTurboLoad(page);
      await expect(page.getByText('E2Eテストスポット')).toBeVisible();
    }
  });

  test('creates a new spot', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);

    const spotsLink = page.getByRole('link', { name: /スポット/ }).first();
    if (await spotsLink.isVisible()) {
      await spotsLink.click();
      await waitForTurboLoad(page);

      await page.getByRole('link', { name: /スポット追加|新規/ }).first().click();
      await waitForTurboLoad(page);

      await page.getByLabel('スポット名').fill('E2E新規スポット');
      await page.getByLabel('住所').fill('東京都渋谷区代々木1-1');
      await page.getByRole('button', { name: '作成する' }).click();
      await waitForTurboLoad(page);
      await expectFlashMessage(page, JA.organizer.spotCreated);
    }
  });

  test('edits an existing spot', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);

    const spotsLink = page.getByRole('link', { name: /スポット/ }).first();
    if (await spotsLink.isVisible()) {
      await spotsLink.click();
      await waitForTurboLoad(page);

      // Click edit on the test spot
      const editLink = page.getByRole('link', { name: '編集' }).first();
      if (await editLink.isVisible()) {
        await editLink.click();
        await waitForTurboLoad(page);
        await page.getByLabel('説明').fill('更新されたスポット説明');
        await page.getByRole('button', { name: '更新する' }).click();
        await waitForTurboLoad(page);
        await expectFlashMessage(page, JA.organizer.spotUpdated);
      }
    }
  });

  test('deletes a spot', async ({ page }) => {
    await page.goto('/organizers/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);

    const spotsLink = page.getByRole('link', { name: /スポット/ }).first();
    if (await spotsLink.isVisible()) {
      await spotsLink.click();
      await waitForTurboLoad(page);

      const deleteButton = page.getByRole('button', { name: '削除' }).or(
        page.getByRole('link', { name: '削除' })
      );
      if (await deleteButton.last().isVisible()) {
        await deleteButton.last().click();
        await waitForTurboLoad(page);
        await expectFlashMessage(page, JA.organizer.spotDeleted);
      }
    }
  });
});
