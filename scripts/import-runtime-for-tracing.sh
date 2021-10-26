#!/bin/bash

CHAINS=(
    moonbase
    moonriver
)

CRATES_PATHS=(
  primitives\\/account\\/
  primitives\\/xcm\\/
  core-primitives
  pallets\\/ethereum-chain-id
  pallets\\/parachain-staking
  pallets\\/asset-manager
  precompiles\\/parachain-staking
  precompiles\\/pallet-democracy
  pallets\\/maintenance-mode
  pallets\\/migrations
  pallets\\/author-mapping
  precompiles\\/utils
  precompiles\\/balances-erc20
  precompiles\\/assets-erc20
  precompiles\\/xtokens
  precompiles\\/crowdloan-rewards
  primitives\\/rpc\\/txpool
)

SPEC_VERSION=$1
GIT_REF=${2:-"runtime-$SPEC_VERSION"}

# Get moonbeam repository shopshot
echo "Get moonbeam branch..."
rm -rf tmp
mkdir tmp
git clone https://github.com/PureStake/moonbeam -b $GIT_REF tmp/moonbeam

# Copy relevant files
echo "Copy relevant files and folders..."
mkdir -p tracing/$SPEC_VERSION/primitives/rpc
cp tmp/moonbeam/Cargo.lock tracing/$SPEC_VERSION/Cargo.lock
cp tmp/moonbeam/rust-toolchain tracing/$SPEC_VERSION/rust-toolchain
cp -r tmp/moonbeam/primitives/ext tracing/$SPEC_VERSION/primitives
cp -r tmp/moonbeam/primitives/rpc/{debug,evm-tracing-events} tracing/$SPEC_VERSION/primitives/rpc
cp -r tmp/moonbeam/runtime tracing/$SPEC_VERSION

# Remove unused moonbeam runtime
# TODO: revert theses lines when moonbeam will be in production
echo "Remove unused moonbeam runtime..."
rm -rf tracing/$SPEC_VERSION/runtime/moonbeam 

# Create a virtual manifest for this new rust workspace from tracing template
echo "Create a virtual manifest for this new rust workspace"
cp tracing/Cargo.toml.template tracing/$SPEC_VERSION/Cargo.toml

# Set evm branch
EVM_BRANCH="runtime-$SPEC_VERSION-substitute-tracing"
sed -i -e "s/EVM_BRANCH/$EVM_BRANCH/g" tracing/$SPEC_VERSION/Cargo.toml

# Enable evm-tracing feature
echo "Enable evm-tracing feature..."
for CHAIN in ${CHAINS[@]}; do
  sed -i -e 's/\["std"\]/\["std", "evm-tracing"\]/g' tracing/$SPEC_VERSION/runtime/$CHAIN/Cargo.toml
done

# Replace path dependencies by git dependencies
echo "Replace path dependencies by git dependencies..."
for CRATE_PATH in ${CRATES_PATHS[@]}; do
  sed -i -e "s/path = \"..\/..\/$CRATE_PATH\"/git = \"https:\/\/github.com\/purestake\/moonbeam\", rev = \"runtime-$SPEC_VERSION\"/g" tracing/$SPEC_VERSION/runtime/common/Cargo.toml
  for CHAIN in ${CHAINS[@]}; do
    sed -i -e "s/path = \"..\/..\/$CRATE_PATH\"/git = \"https:\/\/github.com\/purestake\/moonbeam\", rev = \"runtime-$SPEC_VERSION\"/g" tracing/$SPEC_VERSION/runtime/$CHAIN/Cargo.toml
  done
done
