#!/usr/bin/groovy

stage("Test") {
  node {
    deleteDir()
    stage("Install dependencies") {
      sh "sudo apt-get update"
      sh "sudo apt-get install -y tmux git"
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
}
