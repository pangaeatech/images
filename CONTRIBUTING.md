# Contributing

Thank you for helping improve Pangaea Images.

## Before you start

- Search the issue tracker before opening a new issue.
- Describe the expected behavior, actual behavior, and reproduction steps.
- Keep changes focused on one issue and include tests when behavior changes.

For security reports, follow [SECURITY.md](SECURITY.md) rather than opening a
public issue.

## Development

The images are defined by the root-level `*.dockerfile` files. To validate a
Dockerfile change, build the affected image locally:

```bash
docker build --file <name>.dockerfile --tag <name>:test .
```

Changes to the Redmine synchronization scripts should pass the existing
shell tests:

```bash
docker build --load --tag rmsync:latest --file rmsync.dockerfile .
docker run --rm \
  --volume "$PWD/scripts:/scripts:ro" \
  --workdir /scripts \
  --entrypoint ./tests/run_tests.sh \
  rmsync:latest
```

Tests are Bash scripts named `test_*.sh` under `scripts/tests/`. Add a focused
test for each behavior you introduce or fix.

## Pull requests

- Keep commits and the final diff small and relevant.
- Explain the reason for the change and how it was verified.
- Update relevant documentation and examples.
- Do not commit credentials, tokens, private URLs, or generated files.
- Ensure image package changes use an explicit version.
- Link the issue that the pull request addresses.

Image dependency automation is configured through Dependabot and Renovate.
Maintainers publish a release by creating a `v<version>` tag; the build
workflow publishes every root-level image with the version part of that tag.

## Code of conduct

Participation in this project is governed by the
[Code of Conduct](CODE_OF_CONDUCT.md).
