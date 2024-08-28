pipelineJob('HSS_CCSM_deploy') {
    properties {
        disableConcurrentBuilds()
    }
    logRotator {
        numToKeep(60)
        artifactNumToKeep(15)
    }
    parameters {
        stringParam('GERRIT_BRANCH', 'master', 'Use this parameter to select your repository BRANCH.<br><br>')
        stringParam('GERRIT_REFSPEC', 'master', 'Use same value as GERRIT_BRANCH.<br><br>')
        stringParam('ADP_VERSION', '', 'ADP Version. Keep empty to use default configuration')
        stringParam('NRFAGENT_VERSION', '', 'NRFAGENT Version. Keep empty to use default configuration')
        stringParam('ADDITIONAL_NF', '', 'Add additional NF to be replaced in the Deploy. Must end or splitted by ";"')
        stringParam('CHART_NAME', '', 'Chart name of the microservice to test<br><br>')
        stringParam('CHART_VERSION', '', 'Version of microservice to test<br><br>')
        stringParam('CHART_REPO', '', 'ARM repository where microservice to test is stored<br><br>')
    }
    environmentVariables {
        env('DRYRUN', false)
    }
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://madridci@${COMMON_GERRIT_URL}/a/HSS/CCSM/ci')
                        credentials('userpwd-hss')
                        branch('${GERRIT_BRANCH}')
                        refspec('${GERRIT_REFSPEC}')
                    }
                    extensions {
                        choosingStrategy {
                            gerritTrigger()
                        }
                    }
                }
                lightweight(false)
                scriptPath('Jenkinsfile.ccsm_deploy')
            }
        }
    }
}
