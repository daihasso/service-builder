FROM golang:alpine

RUN apk update && apk add openssh git upx git

ENV DEP_VERSION v0.5.0
ENV OS linux
ENV ARCH amd64

LABEL dep_version=${DEP_VERSION}

RUN wget \
    https://github.com/golang/dep/releases/download/$DEP_VERSION/dep-$OS-$ARCH
RUN mv ./dep-$OS-$ARCH /usr/local/bin/dep
RUN chmod +x /usr/local/bin/dep
COPY files/build_flags.sh /build_flags.sh

# === Onbuild Begin ===
# If you need ssh_info is a container with custom ssh info. It can just be a
# simple scratch with ssh keys included or with an empty /root/.ssh if you don't
# need anything.
ONBUILD COPY --from=ssh_info /root/.ssh /root/.ssh


# === Required ARGs ===
#
# PACKAGE_NAME is the fully qualified name of this service such as:
#   mycompany.com/mycoolservice
ONBUILD ARG PACKAGE_NAME

# === Optional ARGs ===
#
# UPX_ARGS are args passed directly into upx.
# Example:
#   UPX_ARGS="--best --ultra-brute"
#
ONBUILD ARG UPX_ARGS

#
# FRAMEWORK_PACKAGE is the go package which contains a Version, GitHash and SemVer
# export which will be overriden on compile-time.
# Example:
#   ARG FRAMEWORK_PACKAGE=vendor/mycompany.com/coolframework/versioning
#
# See files/build_flags.sh for more information.
#
ONBUILD ARG FRAMEWORK_PACKAGE

# All of the following args regard versioning and are completly optional.
# VERSION is the raw root version for this build in semver format (with no
# prefix or suffix) such as:
#   1.0.0
#
# This will be set to ${FRAMEWORK_PACKAGE}.Version via build flags or not set at
# all if variable is empty.
ONBUILD ARG VERSION

# GITHASH is the short hash for the current commit, this is typically used if
# the working branch is dirty. Ex:
#   e19668f
#
# This will be set to ${FRAMEWORK_PACKAGE}.GitHash via build flags or not set at
# all if variable is empty.
ONBUILD ARG GITHASH

# SEMVER is the full semver version as you want it presented such as:
#   1.0.0-alpha-e19668f
#
# This will be set to ${FRAMEWORK_PACKAGE}.SemVer via build flags or not set at
# all if variable is empty.
ONBUILD ARG SEMVER

ONBUILD RUN if [ -f /root/.ssh/id_rsa ]; then chmod 700 /root/.ssh/id_rsa; fi
ONBUILD RUN if [ -f /root/.ssh/config ]; then chmod 600 /root/.ssh/config; fi

ONBUILD RUN if [ -z "$PACKAGE_NAME" ]; then echo "NOT SET - ERROR"; exit 1; fi

ONBUILD RUN echo "Building package '${PACKAGE_NAME}'..."

ONBUILD WORKDIR /go/src/${PACKAGE_NAME}
ONBUILD COPY Gopkg.toml Gopkg.lock ./
ONBUILD RUN dep ensure -v --vendor-only
ONBUILD COPY . ./

ONBUILD RUN sh /build_flags.sh

ONBUILD RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags \
            "$(cat /buildflags)-s -w" -o /app .

ONBUILD RUN echo "Compressing binary using upx with args: $UPX_ARGS"

ONBUILD RUN upx $UPX_ARGS /app &> /tmp/out.log && tail -5 /tmp/out.log | \
    head -3

ONBUILD RUN echo "Copying compiled go binary to final container..."