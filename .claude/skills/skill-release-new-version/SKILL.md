---
name: skill-release-new-version
description: >-
  Create a new version of the extension and its store and source zips (RELEASING.md "Before You Start" and steps 1-5)
disable-model-invocation: true
---

# Release a New Version

[RELEASING.md](../../../RELEASING.md) holds the steps; follow it from "Before You Start" through step 5. This skill
adds where to stop for the user, what to check after each step, and what to hand back.

## Names Used Below

Read these once the version is bumped (after step 4): before that, package.json still holds the previous version.

- `<version>`: `version` in package.json.
- `<prev-tag>`: `git describe --tags --abbrev=0 v<version>^` (the tag before `v<version>`).
- Commit list: `git log --format='- %s' <prev-tag>..v<version>`. Before the bump, it is the list which
  `npm run release:check` prints.

## Already Tagged?

Before step 1, ask the user whether the version in package.json is the new one (bumped already, not yet in the
stores) or the one already published. The repo cannot tell these apart, since commits after the tag are allowed
either way. When it is the new one:

- Skip steps 1, 3 and 4: `npm run release:check` fails by design on the tag itself, since it wants commits since the
  tag.
- Do step 2 for the commit of `v<version>`, then go on with step 5.

## Steps

- **Step 1**: run `npm run release:check`. On a failure, report it and stop. Keep the commit list it prints.
- **Step 2**: ask the user which real-input checks already ran on this commit. Read the commit list: when a commit
  changes how the content script gets injected or counts clicks, the checks against real sites apply too. Offer to
  run the missing ones, and give the warning from "Commands With Side Effects" in [AGENTS.md](../../../AGENTS.md)
  right before each run. A failing check stops the release until the user decides.
- **Step 3**: propose `patch`, `minor` or `major` with a one-line reason drawn from the commit list. The user decides.
- **Step 4**: give the user the `npm version <type>` command to run: it tags and pushes, and AGENTS.md leaves that to a
  human. Once they report it done, check that
  `git ls-remote origin refs/heads/main 'refs/tags/v<version>^{}'` gives the commit of `HEAD` on both lines.
- **Step 5**: run `npm run build`, `npm run build:source` and `npm run release:check:zips`. Done when every check of
  `release:check:zips` passes; on a failure, rebuild as step 5 says and check again.

## Hand Back

- The paths of the three zips of `<version>` in `web-ext-artifacts/`.
- Whether `permissions`, `optional_permissions`, `host_permissions` or the `matches` of the content script changed
  since `<prev-tag>` (`git diff <prev-tag> v<version> -- extension/manifest.json`).
- Which files under `store-listings/` changed since `<prev-tag>`: their texts need pasting in the store dashboards.
- The commit list, marking the commits which change something for users.
- Next: `/skill-publish-chrome-web-store` and `/skill-publish-firefox-add-ons`.
