import { test, expect } from "@playwright/test";

test.describe("SafeCase shell", () => {
  test("homepage loads with hero-level SafeCase branding", async ({ page }) => {
    await page.goto("/");

    await expect(page).toHaveTitle(/SafeCase/);
    await expect(page.getByRole("link", { name: /SafeCase/i })).toBeVisible();
    await expect(
      page.getByText("Victim services case management"),
    ).toBeVisible();
    await expect(page.getByRole("heading", { name: "Dashboard" })).toBeVisible();
  });

  test("main navigation placeholders are visible", async ({ page }) => {
    await page.goto("/");

    const nav = page.getByRole("navigation", { name: "Main" });
    await expect(nav.getByRole("link", { name: "Dashboard" })).toBeVisible();
    await expect(nav.getByRole("link", { name: "Clients" })).toBeVisible();
    await expect(nav.getByRole("link", { name: "Cases" })).toBeVisible();
    await expect(nav.getByRole("link", { name: "Tasks" })).toBeVisible();
    await expect(nav.getByRole("link", { name: "Timeline" })).toBeVisible();
    await expect(nav.getByRole("link", { name: "Settings" })).toBeVisible();
  });

  test("login page explains Entra-hosted sign-in", async ({ page }) => {
    await page.goto("/login");

    await expect(
      page.getByRole("heading", { name: "Sign in to SafeCase" }),
    ).toBeVisible();
    await expect(page.getByText(/Microsoft Entra ID/)).toBeVisible();
  });
});
