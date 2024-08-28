pipelineJob('HSS_CCSM_deploy_design_rule_check') {
    properties {
        disableConcurrentBuilds()
    }
    logRotator {
        numToKeep(15)
        artifactNumToKeep(15)
    }
    parameters {
        stringParam ('CHART_REPO', 'https://arm.seli.gic.ericsson.se/artifactory/proj-5g-udm-dev-helm-local/', 'Use this parameter to select your repository ARM REPO.')
        stringParam ('CHART_NAME', 'eric-ccsm', 'Use this parameter to select your helm chart NAME.')
        stringParam ('CHART_VERSION', '<x>.<y>.<z>-<metadata>', 'Use this parameter to select your helm chart VERSION.')
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url ('https://madridci@${COMMON_GERRIT_URL}/a/HSS/CCSM/ci')
                        credentials ('userpwd-hss')
                        branch('master')
                        refspec('')
                    }
                    extensions {
                        wipeOutWorkspace()
                    }
                }
                lightweight (false)
                scriptPath ('Jenkinsfile.design_rule_check')
            }
        }
    }
}

