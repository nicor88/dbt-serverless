#!/usr/bin/env bash

LAYER_NAME=$1
ZIP_ARTIFACT=${LAYER_NAME}.zip
LAYER_BUILD_DIR="python"

# note: put the libraries in a folder supported by the runtime, means that should by python

rm -rf ${LAYER_BUILD_DIR} && mkdir -p ${LAYER_BUILD_DIR}

docker run --rm -v `pwd`:/var/task:z lambci/lambda:build-python3.7 python3.7 -m pip install -t ${LAYER_BUILD_DIR} -r requirements.txt

zip -r ${ZIP_ARTIFACT} .

echo "Loading layer to AWS..."
aws lambda publish-layer-version --layer-name ${LAYER_NAME} --zip-file fileb://${ZIP_ARTIFACT} --compatible-runtimes python3.7

rm -rf ${LAYER_BUILD_DIR}
