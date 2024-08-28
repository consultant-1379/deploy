How to manually build and deploy the CCSM Helm package
======================================================

__Note__

This document must be ignored if the helm chart will not be built in local VM,
jenkins job will build it instead.

## 1. Description

The CCSM Helm chart bundles a set of fixed NFs into a single VNF.  This is the parent Helm Chart which includes the following subcharts:

- name: **eric-adp-5g-udm**

  **alias**: _eric-ccsm-adp_

- name: **eric-nrfagent-release**

  **alias**: _eric-ccsm-nrfagent_

- name: **ericsson-ausf-release**

  **alias**: _eric-ccsm-ausf_

- name: **eric-udm-umbrella**

  **alias**: _eric-ccsm-udm_

## 2. Add Helm repositories

The following subcharts helm repositories must be added to the repo list.

- ADP and NRF Agent:

```console
helm repo add arm-udm-adp-helm https://arm.seli.gic.ericsson.se/artifactory/proj-5g-udm-release-helm
helm repo add arm-nrfagent-helm https://arm.epk.ericsson.se/artifactory/proj-nrf-client-helm
helm repo add arm-pvtb-helm https://arm.sero.gic.ericsson.se/artifactory/proj-pc-released-helm
helm repo update
```

Depending your needs UDM/AUSF Development or UDM/AUSF Release helm repository will be needed to generate CCSM Helm Chart.
Check your currently configured helm repository using the command:
```console
helm repo list
```
If you need to remove any helm repository use the command:

```console
helm repo remove <helm repo alias>
```

Example:

```console
helm repo remove arm-ausf-helm
```

- UDM/AUSF Development:
If you need to add UDM/AUSF Development repository execute the following commands and continue with bullet 3

```console
helm repo add arm-ausf-helm https://arm.seli.gic.ericsson.se/artifactory/proj-5g-udm-dev-helm
helm repo add arm-udm-helm https://arm.seli.gic.ericsson.se/artifactory/proj-5g-udm-dev-helm
helm repo update
```

- UDM/AUSF Release:
If you need to add UDM/AUSF Release repository execute the following commands and continue with bullet 3

```console
helm repo add arm-ausf-helm https://arm.seli.gic.ericsson.se/artifactory/proj-5g-udm-release-helm
helm repo add arm-udm-helm https://arm.seli.gic.ericsson.se/artifactory/proj-5g-udm-release-helm
helm repo update
```

Notice that above repositories should be used only for testing, the pipelines will automate it.

## 3. Build the CCSM Helm package

### 3.1 Pre-requisites

Select a target directory to clone CCSM/deploy repository and move to it, like in the following example

```console
mkdir -p $HOME/udm/git/CCSM && cd $HOME/udm/git/CCSM
```

Clone CCSM/deploy repository

```console
git clone ssh://$USER@gerrit-gamma.gic.ericsson.se:29418/HSS/CCSM/deploy
```
 
Create a test directory to execute all commands

```console
mkdir -p deploy/test && cd deploy/test
```
 
Create a symbolic link to 'helm' directory which includes the templates and dependencies.

```console
ln -s ../helm eric-ccsm
```

### 3.2 Build CCSM Helm package

Run the following commands that validate and builds the parent CCSM Helm chart package including a set of subchart dependencies.

```console
helm lint eric-ccsm && \
helm package --dependency-update eric-ccsm --destination $PWD
```

## 4. Test the deploy of CCSM Helm package

```console
helm install $PWD/eric-ccsm-x.x.x.tgz --name eric-ccsm --debug --dry-run
```
Notice that the user can supply custom values that will override the default ones, in case want to overwrite subchart values the children's aliases must be used.

For example:

```console
# Install CCSM without the UDM's 4G micro-services
helm install $PWD/eric-ccsm-x.x.x.tgz --name eric-ccsm --set eric-udm.tags.4g=false --debug --dry-run
```


How to create an Emergency Package
==================================

## Strategy about Emergency Packages

Although the main strategy consists in avoiding creating EPs as much as possible,
and delivering fixes and corrections on the latest version (i.e. One Track),
there are some use cases we foresee that EPs will be needed on, for example when
the latest versions of the software have introduced backward incompatible
changes, or when customers do not want to "risk" upgrading to a newer version of
a VNF that includes not only some specific bugfixes, but also additional changes
and features.

These cases should be minimized, but still we need a plan to provide quick fixes
when critical bugs are detected.

## EP creation process

### 1. Reception of a critical TR that has to be solved in a previous drop

The work starts when a JIRA with a TR is received and assigned to a team, which
will analyze and fix the issue in one or several microservices.

### 2. Identification of the versions to fix

The way to identify exactly which version of the code corresponds to the services
in that specific drop is:

1. Go to [ARM](https://arm.epk.ericsson.se/artifactory/list/proj-hss-docker-global/proj_hss/5g/helm/)
2. Download the latest EP umbrella chart (if available) for that drop, or the
   drop package itself if no EP has been created yet, e.g. `eric-ccsm-udm-0.23.1.tgz`
3. Untar the umbrella chart to see its contents
4. Open the `requirements.yaml` file, which contains information about the
   microservices in the package
5. Each microservice is created with a well known versioning format:
   `<name>-<version>-<timestamp>+<commit_hash>`
   * *name*: Name of the microservice (e.g. `eric-udm-hss4gnotifier`)
   * *version*: Version of the microservice, following semantic versioning (although
     the patch version is not incremented by one unit for each EP, and it's based on
     the Jenkins job instead) (e.g. `1.0.134`)
   * *timestamp*: Date and time when the package was created (e.g. `20190705095927`)
   * *commit_hash*: Prefix of the commit hash in the git repository used for
     building the service in the package (e.g. `dfa5dfb`)

### 3. Branching strategy

After cloning the repository or pulling the latest changes, *create a branch for
that drop if not done previously* (e.g. `demo19`). This helps to:

* Identify easily the software level version in that drop
* Include the fixes exactly on top of the previous drop, so that later on only
  these fixes are included in the release

### 4. Fixing and validating the issues

Once the changes in the microservice(s) are done, they are committed and pushed
for review to [gerrit](https://gerrit-gamma.gic.ericsson.se/) and a pipeline in Jenkins
is triggered to validate the change (*TODO: add the correct pipeline*):
[HSS_5G_FT_ALL](https://fem101-eiffel012.seli.gic.ericsson.se:8443/jenkins/job/HSS_5G_FT_ALL/)

Regular code review process is followed (+1, +2, submit), then another Jenkins
pipeline is executed in the master branch to verify the changes and to generate
the Helm chart for the service (*TODO: add the correct pipeline*):
[HSS_5G_FT_ALL](https://fem101-eiffel012.seli.gic.ericsson.se:8443/jenkins/job/HSS_5G_FT_ALL/)

The regular tests in the microservice repository are executed
*TODO*: But what about if there are other tests that should be executed and not in that repository, for example integration tests?
*NOTE*: The new patch version generated may seem to "jump" several versions, even though it's only one change from a former drop (this is ok for now)

### 5. Creating the umbrella chart for the EP

There's a Jenkins job to create the EP itself: [HSS_GENERATE_EP](https://fem101-eiffel012.seli.gic.ericsson.se:8443/jenkins/job/HSS_GENERATE_EP/)

This job only generates a Helm chart, it does not run any tests. It defines several
manual parameters to finetune its execution and the contents of the EP package,
for example a list of specific microservices (and their version) can be provided
in the parameter list, compared to the previous version, and it will include those
in the new Helm chart.

*NOTE*: It uses the latest version of the tools, as it's not easy to roll back
exactly to how we generated the former drop. This is a known issue and it is
acceptable for now.

Once generated, there's a `cicd` CLI tool that can be used to inspect and get
information about the helm charts. This is used to check manually the versions
included in the new helm chart, comparing the requirements.yaml from previous
versions to make sure that the changes are included.
(*TODO*: some example can be added about where it is and how to use it)

### 6. Testing the umbrella chart for the EP

#### Function Tests

There's a Jenkins job to validate the EP itself: [HSS_5G_FT_ALL_MANUAL](https://fem101-eiffel012.seli.gic.ericsson.se:8443/jenkins/job/HSS_5G_FT_ALL_MANUAL/)

This job executes a manual FT (i.e. "integration" tests at NF level).

These tests are stored in the following repositories:

* [FT](https://gerrit-gamma.gic.ericsson.se/#/admin/projects/HSS/5G/ft)
* [FTFW](https://gerrit-gamma.gic.ericsson.se/#/admin/projects/HSS/5G/ftfw)

These repositories contain one branch per drop, and they run all the FT tests
(~20 minutes for UDM)

#### System Test

Currently, for running System Tests the IBD images are generated (*TODO:
consider using the CSAR packages from drop 24 on*)

The Jenkins job used to run the System Tests is:
[HSS_UMBRELLA](https://fem101-eiffel012.seli.gic.ericsson.se:8443/jenkins/job/HSS_UMBRELLA/)


*NOTE*: The tests to be executed to validate the EP should depend on the root cause of the issue:
* All the microservice tests and FTs are executed (short duration)
* Only _some_ System Tests are executed (installation? performance? on demand, depending on the change)

### 7. Notes

Currently the ADP services are the latest available, which are already installed
in the cluster, but to validate properly the EPs this should use a different version.
Anyway, this should change with the new CSAR packages, which will include everything
in a single CSAR package (including the ADP services and even the Service Mesh).

