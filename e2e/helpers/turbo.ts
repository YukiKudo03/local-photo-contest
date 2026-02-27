import { type Page, type Locator } from '@playwright/test';

/**
 * Wait for Turbo Drive navigation to complete.
 */
export async function waitForTurboLoad(page: Page) {
  await page.waitForLoadState('domcontentloaded');
  // Wait for Turbo to settle — either the turbo:load event or a short fallback
  await Promise.race([
    page.evaluate(() =>
      new Promise<void>((resolve) => {
        if (!document.documentElement.hasAttribute('data-turbo-preview')) {
          resolve();
          return;
        }
        document.addEventListener('turbo:load', () => resolve(), { once: true });
      })
    ),
    page.waitForTimeout(2000),
  ]);
}

/**
 * Wait for a specific Turbo Frame to finish loading.
 */
export async function waitForTurboFrame(page: Page, frameId: string) {
  await page.waitForFunction(
    (id) => {
      const frame = document.querySelector(`turbo-frame#${id}`);
      return frame && !frame.hasAttribute('busy');
    },
    frameId,
    { timeout: 10_000 }
  );
}

/**
 * Click a locator and wait for Turbo navigation to complete.
 */
export async function turboClick(page: Page, locator: Locator) {
  await locator.click();
  await waitForTurboLoad(page);
}
