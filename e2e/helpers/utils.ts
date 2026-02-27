import { type Page, expect } from '@playwright/test';
import path from 'path';

export const TEST_PHOTO_PATH = path.resolve(__dirname, '..', 'fixtures', 'test_photo.jpg');

/**
 * Upload a photo via a hidden file input.
 * Finds the first file input on the page and sets the test photo.
 */
export async function uploadPhoto(page: Page, inputSelector = 'input[type="file"]') {
  const fileInput = page.locator(inputSelector).first();
  await fileInput.setInputFiles(TEST_PHOTO_PATH);
}

/**
 * Auto-accept browser confirmation dialogs.
 */
export function autoAcceptDialogs(page: Page) {
  page.on('dialog', (dialog) => dialog.accept());
}

/**
 * Assert that a flash message with the given text is visible.
 */
export async function expectFlashMessage(page: Page, text: string) {
  // Flash messages may appear in various containers — look for any visible text match
  await expect(page.getByText(text).first()).toBeVisible({ timeout: 5000 });
}
