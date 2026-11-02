---
name: commit
description: How to write git commit messages in this repo. Use whenever creating a commit.
---

# Making commits

## Format: Conventional Commits

Every commit message is a single line following the Conventional Commits format
(https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>: <subject>
```

## Types

- **feat**: a new feature or capability. `feat: add the board hierarchy`
- **fix**: a bug fix. `fix: pick the closest board as a document's primary parent`
- **refactor**: restructuring without behavior change. `refactor: build the hierarchy when decoding the contents`
- **chore**: maintenance, dependencies, config, tooling. `chore: add swift-format and EditorConfig settings`
- **docs**: documentation only. `docs: explain how to export a board from Allume`
- **test**: adding or changing tests. `test: cover documents that are cards on several boards`

## Subject rules

1. **No scopes**: `feat: render notes`, not `feat(site): render notes`.
2. **Lowercase type**, imperative mood, no period at the end.
   - ✅ `fix: decode empty boards`
   - ❌ `Fix: fixed decoding of empty boards.`
3. **Concise but descriptive**: say what the change does, not how it was made.
4. **Never use em dashes**, anywhere in the message. Prefer separate sentences
   with periods, or clauses with commas.
5. **Don't append PR numbers** like `(#12)`. GitHub adds those on squash merge.

## Authorship

The commit's author and committer must be the user creating the PR, and no one
else. Never add a `Co-Authored-By` trailer, a "Generated with" line, or any
other attribution (AI or human) to the commit message.

## Workflow

1. Analyze the staged changes (`git diff --staged`) and write a message that
   matches what actually changed.
2. Keep commits atomic: one logical change per commit. If the working tree
   holds unrelated changes, stage and commit them separately.
3. Keep the message a single line. Issue references like `Closes #12` belong
   in the PR description, which becomes the squash commit body on merge.
