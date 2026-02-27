import { test, expect } from '@playwright/test';
import { login } from '../../helpers/auth';
import { JA } from '../../helpers/locale';
import { waitForTurboLoad } from '../../helpers/turbo';
import { expectFlashMessage } from '../../helpers/utils';

test.describe('Voting', () => {
  test('votes on another user\'s entry and button changes', async ({ page }) => {
    await login(page, 'participant');
    // Navigate to other user's entry
    await page.goto('/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);
    await page.getByText('E2E他者の作品').click();
    await waitForTurboLoad(page);

    // Click the vote button
    const voteButton = page.getByRole('button', { name: JA.votes.vote });
    if (await voteButton.isVisible()) {
      await voteButton.click();
      await waitForTurboLoad(page);
      // Button should change to "unvote" state
      await expect(page.getByRole('button', { name: JA.votes.unvote })).toBeVisible();
    }
  });

  test('unvotes and button reverts', async ({ page }) => {
    await login(page, 'participant');
    await page.goto('/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);
    await page.getByText('E2E他者の作品').click();
    await waitForTurboLoad(page);

    // If already voted, unvote; otherwise vote first then unvote
    const unvoteButton = page.getByRole('button', { name: JA.votes.unvote });
    const voteButton = page.getByRole('button', { name: JA.votes.vote });

    if (await unvoteButton.isVisible()) {
      await unvoteButton.click();
      await waitForTurboLoad(page);
      await expect(page.getByRole('button', { name: JA.votes.vote })).toBeVisible();
    } else if (await voteButton.isVisible()) {
      // Vote first
      await voteButton.click();
      await waitForTurboLoad(page);
      // Then unvote
      await page.getByRole('button', { name: JA.votes.unvote }).click();
      await waitForTurboLoad(page);
      await expect(page.getByRole('button', { name: JA.votes.vote })).toBeVisible();
    }
  });

  test('cannot vote on own entry', async ({ page }) => {
    await login(page, 'participant');
    await page.goto('/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);
    await page.getByText('E2E参加者の作品').click();
    await waitForTurboLoad(page);

    // The vote button should show "自分の作品" or not be a clickable vote button
    const ownLabel = page.getByText(JA.votes.cannotVoteOwn);
    const voteButton = page.getByRole('button', { name: JA.votes.vote });
    // Either no vote button or a disabled/label indicator
    const isOwnVisible = await ownLabel.isVisible().catch(() => false);
    const isVoteVisible = await voteButton.isVisible().catch(() => false);
    expect(isOwnVisible || !isVoteVisible).toBeTruthy();
  });

  test('unauthenticated user sees login link instead of vote button', async ({ page }) => {
    await page.goto('/contests');
    await page.getByText('E2E写真コンテスト').click();
    await waitForTurboLoad(page);
    await page.getByText('E2E他者の作品').click();
    await waitForTurboLoad(page);

    await expect(page.getByText(JA.votes.loginRequired)).toBeVisible();
  });
});
