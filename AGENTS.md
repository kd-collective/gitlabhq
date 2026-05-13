# GitLab Project Guidelines

This file provides default AI agent instructions for the GitLab project.
For customization options, see .ai/README.md.

## Local Overrides

Read @CLAUDE.local.md

## Context Loading

Load the following instruction files based on your current task:

- When working with **git, commits, or branches**: Read .ai/git.md
- When working with **merge requests**: Read .ai/merge-requests.md
- When working with **CI/CD pipelines or `.gitlab-ci.yml`**: Read .ai/ci-cd.md
- Before planning or implementing code changes, load the
  `gitlab-coding-principles` skill: read
  .agents/skills/gitlab-coding-principles/SKILL.md and follow its instructions.

## Project Notes

- Default branch: `master`
- GitLab has extensive CI/CD pipelines; be patient with pipeline results
- Danger bot will comment on MRs with warnings; these are often non-blocking
- This repository is very large; use targeted searches and glob patterns
