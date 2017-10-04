#!/usr/bin/groovy

stage("Test") {
  parallel linux: {
    node("linux") {
      deleteDir()
      stage("Install dependencies") {
        sh "apt-get update"
        sh "apt-get install -y tmux git"
      }
      stage("Checkout") {
        checkout scm
      }
      stage("Build") {
        sh "make -j4"
      }
      stage("Lint") {
        sh "make lint"
      }
      stage("Test") {
        sh "make test"
      }
    }
  },
  freebsd: {
    node("freebsd") {
      deleteDir()
      withEnv(['ASSUME_ALWAYS_YES=YES']) {
        stage("Install dependencies") {
          sh "pkg install tmux gmake git"
        }
      }
      stage("Checkout") {
        checkout scm
      }
      stage("Build") {
        sh "gmake -j4"
      }
      stage("Lint") {
        sh "gmake lint"
      }
      stage("Test") {
        sh "gmake test"
      }
    }
  }
}
