#!/usr/bin/env groovy

def setJobProperties() {
  properties([
    [
      $class: 'GithubProjectProperty',
      displayName: 'Test',
      projectUrlStr: 'https://github.com/reancloud/trendmicro'
    ],
    [
      $class: 'BuildDiscarderProperty',
      strategy: [
        $class: 'BuildRotator',
        daysToKeep: 5,
        numToKeep: 10,
        artifactsDaysToKeep: 5,
        artifactsNumToKeep: 10
      ]
    ],
    pipelineTriggers([
      [
        $class: 'GitHubPRTrigger',
        spec: '',
        triggerMode: 'HEAVY_HOOKS',
        events: [[
            $class: 'GitHubPROpenEvent'
        ]],
        abortRunning: true,
        branchRestriction: ([
          targetBranch: 'master\ndevelop'
        ]),
        preStatus: true,
        skipFirstRun: true
      ]
    ])
  ])
}

pipeline {
  agent {
    node {
      label 'master'
    }
  }
  parameters {
    string(name: 'REGION', defaultValue: 'us-east-1', description: 'The AWS region to use')
    string(name: 'SUBNET_ID', defaultValue: 'subnet-991258fc', description: 'The subnet id to use')
    string(name: 'SECURITY_GROUP_ID', defaultValue: 'sg-0a236475', description: 'The security group to attach to the launched instance')
    string(name: 'IAM_PROFILE', defaultValue: 'svc_rean-product-default-jenkins-role', description: 'The IAM profile to use for the instance')
    string(name: 'Environment', defaultValue: 'Development', description: 'Environment tag')
    string(name: 'Project', defaultValue: 'reandeploy', description: 'Project tag')
  }
  environment {
    AWS_REGION = "${params.REGION}"
    SUBNET_ID = "${params.SUBNET_ID}"
    SG_ID = "${params.SECURITY_GROUP_ID}"
    IAM_PROFILE = "${params.IAM_PROFILE}"
    TAGS_ENVIRONMENT = "${params.Environment}"
    TAGS_PROJECT = "${params.Project}"
    REPO_NAME = sh(returnStdout: true, script: 'basename -s .git $(git config --get remote.origin.url)').trim()
    SSH_KEY = "${REPO_NAME}-${env.BUILD_NUMBER}"
    SSH_KEY_PATH = "./${REPO_NAME}-${env.BUILD_NUMBER}"
    TAGS_EXPIRY = sh(returnStdout: true, script: 'date -d +10days +%Y-%m-%d').trim()
    USER = sh(returnStdout: true, script: 'git show -s --pretty=%ae').trim()
    TAGS_OWNER = sh(returnStdout: true, script: 'git show -s --pretty=%ae | cut -d "@" -f 1').trim()
  }
  stages {
    stage('Set job properties') {
      steps {
        setJobProperties()
      }
    }
    stage('Validating cookbook Standards') {
      steps {
        script {
          def user = ''
          try {
            user = currentBuild.getRawBuild().getCauses()[0].getUserId()
          }
          catch (Exception e){
            user = "${USER}"
          }
          def slackStatus =  "${JOB_NAME}".split("/").join(" » ") + " - #${BUILD_NUMBER} Started by user " + user
          ansiColor('xterm') {
            int exitCode = 0
            try {
              slackSend(color: '#D4DADF', message: "BUILD STARTED: ${slackStatus} (<${env.BUILD_URL}/console|Logs>) for (<${env.CHANGE_URL}|#${env.BRANCH_NAME}>) TITLE: ${env.CHANGE_TITLE}")
              stage('validating README') {
                script {
                  try {
                    githubNotify(context: 'README validation', description: 'validating cookbook README', status: 'PENDING')
                    sh "chef exec mdl -r ~MD013 README.md"
                    githubNotify(context: 'README validation', description: 'README validation passed', status: 'SUCCESS')
                  }
                  catch (Exception e) {
                    githubNotify(context: 'README validation', description: 'README validation failed', status: 'FAILURE')
                    exitCode = 1
                  }
                }
              }
              stage('validating cookbook with cookstyle') {
                script {
                  try {
                    githubNotify(context: 'cookstyle validation', description: 'validating cookbook with cookstyle', status: 'PENDING')
                    sh "chef exec cookstyle"
                    githubNotify(context: 'cookstyle validation', description: 'cookstyle passed', status: 'SUCCESS')
                  }
                  catch (Exception e) {
                    githubNotify(context: 'cookstyle validation', description: 'cookstyle failed', status: 'FAILURE')
                    exitCode = 1
                  }
                }
              }
              stage('validating cookbook with foodcritic') {
                script {
                  try {
                    githubNotify(context: 'foodcritic validation', description: 'validating cookbook with foodcritic', status: 'PENDING')
                    sh "chef exec foodcritic ."
                    githubNotify(context: 'foodcritic validation', description: 'foodcritic passed', status: 'SUCCESS')
                    if (exitCode == '1') {
                      sh "exit 1"
                    }
                  }
                  catch (Exception e) {
                    githubNotify(context: 'foodcritic validation', description: 'foodcritic failed', status: 'FAILURE')
                    sh "exit 1"
                  }
                }
              }
              stage('AWS steps') {
                script {
                  try {
                    githubNotify(context: 'AWS steps', description: 'Creating key pair', status: 'PENDING')
                    sh "aws ec2 delete-key-pair --key-name ${SSH_KEY} --region ${AWS_REGION}"
                    sh "aws ec2 create-key-pair --key-name ${SSH_KEY} --region ${AWS_REGION} | chef exec ruby -e \"require 'json'; puts JSON.parse(STDIN.read)['KeyMaterial']\" > ./${SSH_KEY}"
                    sh "chmod 400 ${SSH_KEY}"
                    githubNotify(context: 'AWS steps', description: 'Creating key pair successfull', status: 'SUCCESS')
                  }
                  catch (Exception e) {
                    echo "Creating aws key pair failed. Investigate!"
                    githubNotify(context: 'AWS steps', description: 'Creating key pair failed', status: 'FAILURE')
                    sh "exit 1"
                  }
                }
              }
              stage('Creating test infrastructure') {
                script {
                  try {
                    githubNotify(context: 'kitchen create', description: 'creating infrastructure', status: 'PENDING')
                    sh "chef exec kitchen create"
                    // Adding sleep after kitchen create if defined as transport.sleep
                    sh "sleep \$(chef exec ruby -e \"require 'yaml'; delta=YAML.load_file('.kitchen.yml')['transport']['sleep']; puts delta.nil? ? 0 : delta\")"
                    githubNotify(context: 'kitchen create', description: 'creating infrastructure passed', status: 'SUCCESS')
                  }
                  catch (Exception e) {
                    githubNotify(context: 'kitchen create', description: 'creating infrastructure failed', status: 'FAILURE')
                    sh "chef exec kitchen destroy"
                    sh "exit 1"
                  }
                }
              }
              stage('converging cookbook') {
                script {
                  try {
                    githubNotify(context: 'kitchen converge', description: 'converging cookbook', status: 'PENDING')
                    sh "chef exec kitchen converge"
                    sh "chef exec kitchen converge"
                    githubNotify(context: 'kitchen converge', description: 'kitchen converge passed', status: 'SUCCESS')
                  }
                  catch (Exception e) {
                    githubNotify(context: 'kitchen converge', description: 'kitchen converge failed', status: 'FAILURE')
                    sh "chef exec kitchen destroy"
                    sh "exit 1"
                  }
                }
              }
              stage('rebooting nodes') {
                script {
                  try {
                    githubNotify(context: 'rebooting nodes', description: 'rebooting nodes', status: 'PENDING')
		    sh "chef exec kitchen exec -c 'sudo reboot' > /dev/null 2>&1"
                  }
                  catch (Exception e) {
                    sh "sleep \$(chef exec ruby -e \"require 'yaml'; delta=YAML.load_file('.kitchen.yml')['transport']['timeout']; puts delta.nil? ? 180 : delta\")"
                    try {
                      sh "chef exec kitchen exec -c 'touch /tmp/rebooted'"
                      githubNotify(context: 'rebooting nodes', description: 'rebooting nodes passed', status: 'SUCCESS')
                    }
                    catch (Exception ex) {
                      githubNotify(context: 'rebooting nodes', description: 'rebooting nodes failed', status: 'FAILURE')
                      sh "chef exec kitchen destroy"
                      sh "exit 1"
                    }
                  }
                }
              }
              stage('verifying cookbook') {
                script {
                  try {
                    githubNotify(context: 'kitchen verify', description: 'verifying cookbook', status: 'PENDING')
                    sh "chef exec kitchen verify"
                    githubNotify(context: 'kitchen verify', description: 'kitchen verify passed', status: 'SUCCESS')
                    sh "chef exec kitchen destroy"
                  }
                  catch (Exception e) {
                    githubNotify(context: 'kitchen verify', description: 'kitchen verify failed', status: 'FAILURE')
                    sh "chef exec kitchen destroy"
                    sh "exit 1"
                  }
                }
              }
              sh "exit $exitCode"
              slackSend(color: 'good', message: "BUILD PASSED: ${slackStatus} (<${env.BUILD_URL}/console|Logs>) for (<${env.CHANGE_URL}|#${env.BRANCH_NAME}>) TITLE: ${env.CHANGE_TITLE}")
            }
            catch (Exception e) {
              println "\u001B[31m\u001B[1mERROR: Cookbook does not adhere to the required standards or creating/converging/verifying failed"
              slackSend(color: 'danger', message: "BUILD FAILED: ${slackStatus} (<${env.BUILD_URL}/console|Logs>) for (<${env.CHANGE_URL}|#${env.BRANCH_NAME}>) TITLE: ${env.CHANGE_TITLE}")
              currentBuild.result = 'FAILURE' 
            }
          }
        }
      }
    }
  }
  post {
    always {
      sh "aws ec2 delete-key-pair --key-name ${SSH_KEY} --region ${AWS_REGION}"
      deleteDir()
    }
  }
}
