# Pangaea Images

Container images and workflow templates used by Pangaea projects.

## Images

Each image has a matching Dockerfile at the repository root.

| Image | Purpose |
| --- | --- |
| `devenv` | A general development environment with common build, language, and command-line tools. |
| `runner` | A non-root development and CI base image with common build tools and the .NET and PowerShell toolchains. |
| `rmsync` | A compact image for synchronizing GitHub or GitLab work with Redmine. |

Released images are published to GitHub Container Registry with their release
number as the tag:

```text
ghcr.io/pangaeatech/images/devenv:<version>
ghcr.io/pangaeatech/images/runner:<version>
ghcr.io/pangaeatech/images/rmsync:<version>
```

The repository's `v*` tags build and publish all images. For example, tag
`v1.0.0` publishes the `1.0.0` variants.

## Build locally

Docker is required to build the images:

```bash
docker build --file devenv.dockerfile --tag images/devenv .
docker build --file runner.dockerfile --tag images/runner .
docker build --file rmsync.dockerfile --tag images/rmsync .
```

## Redmine synchronization

The `rmsync` image provides three commands:

```text
rmsync sync
rmsync wiki [file] [page]
rmsync file [file ...]
```

`sync` selects an action from the triggering pull request or merge request
event. `wiki` updates a Redmine wiki page, and `file` uploads files to a Redmine
project, version, or issue. See the files in
[`workflow_template`](workflow_template/) for GitHub Actions examples and the
required inputs, secrets, and variables.

The templates currently reference the published `rmsync:v1.0.0` image. Copy a
template into a consuming repository's `.github/workflows` directory and update
the image tag when a newer release is available.

## Test

The shell tests run inside the `rmsync` image:

```bash
docker build --load --tag rmsync:latest --file rmsync.dockerfile .
docker run --rm \
  --volume "$PWD/scripts:/scripts:ro" \
  --workdir /scripts \
  --entrypoint ./tests/run_tests.sh \
  rmsync:latest
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development and pull request
guidelines. By participating in this project, you agree to follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Please report vulnerabilities according to [SECURITY.md](SECURITY.md). Do not
open a public issue for a suspected vulnerability.

## License

This project is licensed under the [MIT License](LICENSE).
