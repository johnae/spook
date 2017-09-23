stage("Test") {
  parallel linux: {
    node("linux") {
      stage("Checkout") {
        checkout scm
      }
      stage("Install dependencies") {
        sh "apk update"
        sh "apk add tmux"
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
      stage("Checkout") {
        checkout scm
      }
      stage("Install dependencies") {
        sh "pkg add tmux gmake"
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
