---
name: skill-publish-firefox-add-ons
description: Publish the new version of the extension on Firefox Add-ons (AMO) (RELEASING.md step 7)
disable-model-invocation: true
---

# Publish on Firefox Add-ons

[RELEASING.md](../../../RELEASING.md) step 7 holds the steps. This skill adds the texts to prepare, where to wait for
the user's go-ahead, and what to check after each step.

## Names Used Below

- `<version>`: `version` in package.json.
- `<prev-tag>`: `git describe --tags --abbrev=0 v<version>^` (the tag before `v<version>`).
- Commit list: `git log --format='- %s' <prev-tag>..v<version>`.

## Before the Upload

- `git ls-remote origin 'refs/tags/v<version>^{}'` gives the commit of `v<version>`, and
  `npm run release:check:zips` passes. Otherwise run `/skill-release-new-version` first.
- Draft the **Release Notes** for the users of the add-on, from the commit list: only what changed for them, and of
  the limits only those which apply to Firefox (README.md marks the Chrome-only ones). Some Markdown works there: a
  list needs a blank line before it.
- Fill in the **Notes to Reviewer** template of step 7 with `<version>`.
- Show both texts to the user and adjust them until they approve.

## Steps

- **Upload**: upload `web-ext-artifacts/double-right-click-<version>-firefox.zip` as a new version, as step 7 says.
  The validation must end with 0 errors and exactly the 3 known warnings listed in [AGENTS.md](../../../AGENTS.md);
  anything else stops the release until the user decides.
- **Continue**: get the user's go-ahead first. It creates the version on AMO, and its number can never be uploaded
  again.
- **Describe Version**: enter the approved texts, then read both fields back and compare them with the approved
  texts.
- **Submit Version**: get the user's go-ahead first.
- **Source code**: AMO asks for it before **Describe Version**, after **Submit Version**, or not at all; step 7
  covers each case. Use `web-ext-artifacts/double-right-click-<version>-source.zip`.
- **Check**: on **Manage Version** of `<version>`, the Version Notes and the Notes for Reviewers hold the approved
  texts, the source code is attached and the file is awaiting review.

## Product Page

Update it only when `git diff <prev-tag> v<version> -- store-listings/firefox-add-ons/product-page.md` shows a change.
Compare the live texts on **Edit Product Page** with the file paragraph by paragraph, and show the user what changes.
Get their go-ahead before **Save Changes**: the page is public at once, while the previous version stays live until
the review passes. Read the saved page back.

## Report

- The version submitted, how the source zip got attached, and the product page changes saved.
- Any screen or question of AMO which step 7 does not describe, with a proposed update to RELEASING.md.
- What remains: RELEASING.md step 8 once the review passes.
