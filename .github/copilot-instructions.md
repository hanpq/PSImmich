# Commit messages

Always use Conventional Commits when generating or creating commit messages:

```text
<type>[optional scope][!]: <short description>
```

- Choose the type from the actual changes: `feat`, `fix`, `perf`, `docs`, `test`, `refactor`, `build`, `ci`, `chore`, or `revert`.
- Use `feat:` for new functionality, `fix:` for bug fixes, and `perf:` for performance improvements. These request a release through Release Please.
- Use `docs:`, `test:`, `refactor:`, `build:`, `ci:`, or `chore:` for changes that do not request a release. A release-mode configuration toggle alone normally uses `chore:`.
- Mark breaking changes with `!` before the colon and explain them in a `BREAKING CHANGE:` footer.
- Keep the description concise and imperative. Never use an unprefixed subject such as `release 5.2.6`.
- Apply the same format to pull request titles intended for squash merging. Preserve required commit trailers.

See [BUILDING.md](../BUILDING.md) for the release process. Do not mislabel changes merely to trigger or suppress a release.
