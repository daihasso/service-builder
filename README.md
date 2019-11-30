# service-builder
Docker onbuild image for multi-phase builds of a golang service with support 
for semver versioning and private repos.

## Example Dockerfile
This docker image is would be used like so:

```dockerfile
# PACKAGE_NAME can be provided here before the FROM to override the name used
# in compilation and must be your full prefixed service name such as
# github.com/foo/bar
#
ARG PACKAGE_NAME="github.com/foo/bar"

# FRAMEWORK_PACKAGE is the go package which contains a Version, GitHash and
# SemVer export which will be overriden on compile-time.
# Example:
#   ARG FRAMEWORK_PACKAGE=vendor/mycompany.com/coolframework/versioning
#
# See files/build_flags.sh for more information.
ARG FRAMEWORK_PACKAGE=vendor/mycompany.com/coolframework/versioning

# --- Custom Files ---
# This container should contain custom files such as ssh keys, git config, etc.
FROM scratch AS custom_files
COPY .gitconfig /root/.gitconfig
COPY .ssh /root/.ssh

# ---- Build ----
# Builds a go executable called app to the container root using dep for
# dependencies.
#
# This image must be titled 'build' in order for the runner to grab the
# executable correctly.
FROM daihasso/service-builder:latest AS build


# ---- Create Final Image ----
# Copies the /app executable into a scratch docker image and sets it as the
# entry point.
FROM daihasso/service-runner:latest
```

## Dockerfile Build ARGs
#### You might want to set the following ARGs in your Dockerfile

**PACKAGE_NAME**: Defines the final package name to be built.

**GOPRIVATE**: The list of packages which should be considered private by **go
mod** such as`mycompany.com/*`. More info [here][1].

**UPX_ARGS**: Optionally define extra args to [upx](https://upx.github.io/).

**USE_PKGER**: If this variable is set [pkger][2] will be run before building
in order to include binary files into your go binary.

**FRAMEWORK_PACKAGE**: Defines the package which contains the exported values
`Version`, `GitHash`, and `SemVer` for overriding at build-time.

---

#### You might want to set the following ARGs at build-time

**VERSION**: The raw root version for this build such as `1.0.0`.

**GITHASH**: The short githash to append to the version if the branch is dirty.

**SEMVER**: The full semver version as you wanted it represented such as
 `1.0.0-alpha+exp.sha.e19668f`.

## Requirements
This dockerfile expects at minimum a `go.mod` and `go.sum` to be present
though something to build probably makes sense too.

[1]: https://tip.golang.org/cmd/go/#hdr-Module_downloading_and_verification
[2]: https://github.com/markbates/pkger
