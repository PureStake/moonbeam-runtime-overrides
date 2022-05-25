#!/bin/bash

WASM_RUNTIME_OVERRIDES="moonbase-overrides"

chmod uog+x target/release/moonbeam
mkdir -p tests/$WASM_RUNTIME_OVERRIDES
cp wasm/moonbase-* tests/$WASM_RUNTIME_OVERRIDES
cd moonbeam-types-bundle
npm install
npm run build
cd ../tests
npm install
node_modules/.bin/mocha --parallel -j 1 -r ts-node/register 'tracing-tests/**/test-*.ts'
