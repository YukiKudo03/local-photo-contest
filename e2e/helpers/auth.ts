import { type Page } from '@playwright/test';
import { waitForTurboLoad } from './turbo';

export const USERS = {
  participant: { email: 'participant@e2e.test', password: 'password123', role: 'participant' },
  organizer:   { email: 'organizer@e2e.test',   password: 'password123', role: 'organizer' },
  admin:       { email: 'admin@e2e.test',       password: 'password123', role: 'admin' },
  judge:       { email: 'judge@e2e.test',       password: 'password123', role: 'participant' },
  other:       { email: 'other@e2e.test',       password: 'password123', role: 'participant' },
} as const;

export type UserKey = keyof typeof USERS;

export async function login(page: Page, userKey: UserKey) {
  const user = USERS[userKey];
  await page.goto('/organizers/sign_in');
  await page.getByLabel('メールアドレス').fill(user.email);
  await page.getByLabel('パスワード', { exact: true }).fill(user.password);
  await page.getByRole('button', { name: 'ログイン' }).click();
  await waitForTurboLoad(page);
}

export async function logout(page: Page) {
  await page.getByRole('link', { name: 'ログアウト' }).click();
  await waitForTurboLoad(page);
}

export async function register(page: Page, email: string, password: string) {
  await page.goto('/organizers/sign_up');
  await page.getByLabel('メールアドレス').fill(email);
  await page.getByLabel('パスワード', { exact: true }).fill(password);
  await page.getByLabel('パスワード（確認）').fill(password);
  await page.getByRole('button', { name: 'アカウントを作成' }).click();
  await waitForTurboLoad(page);
}
