#!/bin/bash

set -e

CRATE=num-rational
MSRV=1.60

get_rust_version() {
  local array=($(rustc --version));
  echo "${array[1]}";
  return 0;
}
RUST_VERSION=$(get_rust_version)

check_version() {
  IFS=. read -ra rust <<< "$RUST_VERSION"
  IFS=. read -ra want <<< "$1"
  [[ "${rust[0]}" -gt "${want[0]}" ||
   ( "${rust[0]}" -eq "${want[0]}" &&
     "${rust[1]}" -ge "${want[1]}" )
  ]]
}

echo "Testing $CRATE on rustc $RUST_VERSION"
if ! check_version $MSRV ; then
  echo "The minimum for $CRATE is rustc $MSRV"
  exit 1
fi

STD_FEATURES=(num-bigint-std serde)
NO_STD_FEATURES=(num-bigint serde)
echo "Testing supported features: ${STD_FEATURES[*]}"
echo " no_std supported features: ${NO_STD_FEATURES[*]}"

set -x

# test the default with std
cargo build
cargo test

# test each isolated feature with std
for feature in ${STD_FEATURES[*]}; do
  cargo build --no-default-features --features="std $feature"
  cargo test --no-default-features --features="std $feature"
done

# test all supported features with std
cargo build --no-default-features --features="std ${STD_FEATURES[*]}"
cargo test --no-default-features --features="std ${STD_FEATURES[*]}"


# test minimal `no_std`
cargo build --no-default-features
cargo test --no-default-features

# test each isolated feature without std
for feature in ${NO_STD_FEATURES[*]}; do
  cargo build --no-default-features --features="$feature"
  cargo test --no-default-features --features="$feature"
done

# test all supported features without std
cargo build --no-default-features --features="${NO_STD_FEATURES[*]}"
cargo test --no-default-features --features="${NO_STD_FEATURES[*]}"

# make sure benchmarks can be built and sanity-tested
if rustc --version | grep -q nightly; then
    cargo test --manifest-path ci/benchmarks/Cargo.toml
fi
