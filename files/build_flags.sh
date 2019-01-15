# This script simply takes the args into the docker container for version,
# githash, and semver and passes them on to as build flags for build in the
# final app.
#
extra_flag_prefix="-X $FRAMEWORK_PACKAGE"

extra_build_flags=""
if [[ -z "$VERSION" ]]; then
    echo "No version argument provided."
else
    echo "Version argument found: $VERSION"
    extra_build_flags="$extra_flag_prefix.Version=$VERSION "
fi

if [[ -z "$GITHASH" ]]; then
    echo "No githash argument provided."
else
    echo "Githash argument found: $GITHASH"
    git_hash_extra_flag="$extra_flag_prefix.GitHash=$GITHASH"
    extra_build_flags="$extra_build_flags$git_hash_extra_flag"
fi

printf "%s" "$extra_build_flags " > /buildflags

if [[ -z "$SEMVER" ]]; then
    echo "No semver argument provided."
else
    echo "Generated flags for version: $SEMVER"
fi

exit 0
