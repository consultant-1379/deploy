How to build the CCSM HELM and CSAR Packages
============================================

This document only contains manual steps.

Setup
-----

Set variables to be used in the following chapters.

- Drop

```console
CCSM_DROP="drop27"
```

- CCSM:

```console
CCSM_RELEASE_HELM_VERSION="0.27.3"
CCSM_CSAR_VERSION="0.27.3"
CCSM_CSAR_VNFD_VERSION="0.0.2"
CCSM_CSAR_UUID=$(uuidgen)
```

- Destination directory with a lot of extra space

```console
DEST_DIR=/tmp/csar && mkdir -p ${DEST_DIR} && cd ${DEST_DIR}
```

Build the CSAR Packages
-----------------------

### Common pre-requisites

1. __Install uuid-runtime__

```console
sudo apt-get update
sudo apt-get install uuid-runtime
```

2. __Download the "run_package_manager.sh" executable script__

```console
FILE="run_package_manager.sh" && \
git archive --remote=ssh://gerrit-gamma.gic.ericsson.se:29418/OSS/com.ericsson.orchestration.mgmt.packaging/am-package-manager \
HEAD "src/scripts/${FILE}" | \
tar -xO > ${DEST_DIR}/${FILE} && \
chmod +x ${DEST_DIR}/${FILE}
```

3. __Login the Docker registry__

```console
sudo su
docker login armdocker.rnd.ericsson.se
```

### __CCSM__

1. __Download the CCSM release Helm Chart__

```console
curl -sS -u $USER -X GET https://arm.seli.gic.ericsson.se/artifactory/proj-5g-udm-release-helm/eric-ccsm-${CCSM_RELEASE_HELM_VERSION%-*}.tgz \
-o eric-ccsm-${CCSM_RELEASE_HELM_VERSION%-*}.tgz
```

2. __Copy the VNFD, Manifest and Helm values.yaml files in destination directory__

2.1. __CCSM VNF Descriptor__: [eric-ccsm-vnfd.yaml](https://gerrit-gamma.gic.ericsson.se/plugins/gitiles/HSS/CCSM/deploy/+/refs/heads/master/evnfm/eric-ccsm-vnfd.yaml)

```console
FILE="eric-ccsm-vnfd.yaml" && \
git archive --remote=ssh://gerrit-gamma.gic.ericsson.se:29418/HSS/CCSM/deploy \
HEAD "evnfm/${FILE}" | \
tar -xO > ${DEST_DIR}/${FILE}
```

__IMPORTANT:__ Note that file `eric-ccsm-vnfd.yaml` must be updated with the right information.

- Replace the unique descriptor_id:

```console
FILE="eric-ccsm-vnfd.yaml" && \
sed -i "s/UUID/${CCSM_CSAR_UUID}/g" ${DEST_DIR}/${FILE}
```

- Replace the CSAR package name

```console
FILE="eric-ccsm-vnfd.yaml" && \
sed -i -E \
"s/Ericsson.CCSM.(.*)/Ericsson.CCSM.${CCSM_CSAR_VERSION//./_}.${CCSM_CSAR_VNFD_VERSION//./_}:/g" \
${DEST_DIR}/${FILE}
```

- Replace the software_version

```console
FILE="eric-ccsm-vnfd.yaml" && \
sed -i "s/SOFTWARE_VERSION/${CCSM_RELEASE_HELM_VERSION%-*}/g" ${DEST_DIR}/${FILE}
```

- Replace the descriptor_version

```console
FILE="eric-ccsm-vnfd.yaml" && \
sed -i "s/DESCRIPTOR_VERSION/${CCSM_CSAR_VNFD_VERSION}/g" ${DEST_DIR}/${FILE}
```

2.2. __CCSM package Manifest file__: [eric-ccsm-vnfd.mf](https://gerrit-gamma.gic.ericsson.se/plugins/gitiles/HSS/CCSM/deploy/+/refs/heads/master/evnfm/eric-ccsm-vnfd.mf)

```console
FILE="eric-ccsm-vnfd.mf" && \
git archive --remote=ssh://gerrit-gamma.gic.ericsson.se:29418/HSS/CCSM/deploy \
HEAD "evnfm/${FILE}" | \
tar -xO > ${DEST_DIR}/${FILE}
```

- Replace the vnf_package_version:

```console
FILE="eric-ccsm-vnfd.mf" && \
sed -i -E \
"s/vnf_package_version:(.*)/vnf_package_version: ${CCSM_CSAR_VNFD_VERSION}/g" \
${DEST_DIR}/${FILE}
```

- Replace the vnf_release_date_time:

```console
FILE="eric-ccsm-vnfd.mf" && \
sed -i -E \
"s/vnf_release_date_time:(.*)/vnf_release_date_time: `date --iso-8601=seconds`/g" \
${DEST_DIR}/${FILE}
```

2.3. __CCSM Custom Values__: [eric-ccsm-values.yaml](https://gerrit-gamma.gic.ericsson.se/plugins/gitiles/HSS/CCSM/deploy/+/refs/heads/master/helm/values.yaml)

```console
FILE="eric-ccsm-values.yaml" && \
git archive --remote=ssh://gerrit-gamma.gic.ericsson.se:29418/HSS/CCSM/deploy \
HEAD "helm/values.yaml" | \
tar -xO > ${DEST_DIR}/${FILE}
```

- Edit the files to add custom values, note that if any parameter is duplicated in VNFD and “values.yaml” the one VNFD will take precedence

```console
ll ${DEST_DIR}
eric-ccsm-values.yaml
eric-ccsm-vnfd.yaml
```

2.4. __CCSM ChangeLog__: [ChangeLog.txt](https://gerrit-gamma.gic.ericsson.se/plugins/gitiles/HSS/CCSM/deploy/+/refs/heads/master/evnfm/ChangeLog.txt)

```console
FILE="ChangeLog.txt" && \
git archive --remote=ssh://gerrit-gamma.gic.ericsson.se:29418/HSS/CCSM/deploy \
HEAD "evnfm/ChangeLog.txt" | \
tar -xO > ${DEST_DIR}/${FILE}
```

- Edit the file to add custom content:

```console
vi ${DEST_DIR}/ChangeLog.txt
```

3. __Build the CCSM CSAR Package__

```console
${DEST_DIR}/run_package_manager.sh ${DEST_DIR} /root/.docker/ \
"--helm eric-ccsm-${CCSM_RELEASE_HELM_VERSION%-*}.tgz --name eric-ccsm-${CCSM_CSAR_VERSION%-*}-${CCSM_CSAR_VNFD_VERSION} --vnfd eric-ccsm-vnfd.yaml --manifest eric-ccsm-vnfd.mf --history ChangeLog.txt -sc ConfigMgmt/"
```

4. __Publish the CSAR Package and values.yaml files__

```console
curl -u $USER -X PUT https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-cudb-external-local/tmp/ccsm/csar/${CCSM_DROP}/ \
-T eric-ccsm-${CCSM_CSAR_VERSION%-*}-${CCSM_CSAR_VNFD_VERSION}.csar
```
```console
curl -u $USER -X PUT https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-cudb-external-local/tmp/ccsm/csar/${CCSM_DROP}/ \
-T eric-ccsm-values.yaml
```
