---
name: skill-publish-chrome-web-store
description: Publish the new version of the extension on the Chrome Web Store (RELEASING.md step 6)
disable-model-invocation: true
---

# Publish on the Chrome Web Store

[RELEASING.md](../../../RELEASING.md) step 6 holds the steps. This skill adds what to check first, where to wait for
the user's go-ahead, and what to report.

## Names Used Below

- `<version>`: `version` in package.json.
- `<prev-tag>`: `git describe --tags --abbrev=0 v<version>^` (the tag before `v<version>`).

## Before the Upload

- `git ls-remote origin 'refs/tags/v<version>^{}'` gives the commit of `v<version>`, and
  `npm run release:check:zips` passes. Otherwise run `/skill-release-new-version` first.
- **Privacy** tab: needed only when `git diff <prev-tag> v<version> -- extension/manifest.json` adds, removes or
  widens an entry which
  [store-listings/chrome-web-store/privacy.md](../../../store-listings/chrome-web-store/privacy.md) justifies (its
  intro lists them). The texts are in that file.
- **Store listing** tab: the dashboard keeps its texts between uploads, so paste them only when
  `git diff <prev-tag> v<version> -- store-listings/chrome-web-store/store-listing.md` shows a change.

## Steps

- Upload `web-ext-artifacts/double-right-click-<version>-chrome.zip` on the **Package** tab, as step 6 says.
- Update the **Privacy** and **Store listing** tabs where the checks above call for it.
- Before **Submit for review**, get the user's go-ahead, and ask whether to keep the checkbox which publishes as soon
  as the review passes.

## Report

- The version submitted, the tabs changed, and whether it publishes on its own once the review passes.
- What remains: RELEASING.md step 8 once the review passes.
