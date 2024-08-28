pipelineJob('HSS_CCSM_deploy_verify') {
    properties {
        disableConcurrentBuilds()
    }
    logRotator {
        numToKeep(15)
        artifactNumToKeep(15)
    }
    parameters {
        stringParam('GERRIT_BRANCH', 'master', 'Use this parameter to select your repository BRANCH.<br><br>')
        stringParam('GERRIT_REFSPEC', 'master', 'Use same value as GERRIT_BRANCH.<br><br>')
        stringParam ('ADP_VERSION', '', 'ADP Version. Keep empty to use default configuration')
        stringParam ('NRFAGENT_VERSION', '', 'NRFAGENT Version. Keep empty to use default configuration')
    }
    environmentVariables {
        env('DRYRUN', true)
    }
    triggers {
        gerrit {
            events {
                patchsetCreated()
            }

            project('plain:HSS/CCSM/deploy', ["plain:drop84","plain:drop79","plain:drop72","plain:drop67"])

            configure { gerritTrigger ->
                new groovy.util.Node(gerritTrigger, 'serverName', 'adp')

                def gerritProjects = gerritTrigger.getAt('gerritProjects')[0]
                def gerritProject = gerritProjects.getAt('com.sonyericsson.hudson.plugins.gerrit.trigger.hudsontrigger.data.GerritProject')[0]

                // Allowed topic
                topics = new groovy.util.Node(gerritProject, 'topics')
                topic = new groovy.util.Node(topics, 'com.sonyericsson.hudson.plugins.gerrit.trigger.hudsontrigger.data.Topic')
                compareType = new groovy.util.Node(topic, 'compareType', 'reg_exp')
                new groovy.util.Node(topic, 'pattern', '^((?!CCSM_DEPLOY_CI_SKIP).)*$')
            }
            buildSuccessful(null, null)
        }
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
                scriptPath ('Jenkinsfile.ccsm_deploy')
            }
        }
    }
}
