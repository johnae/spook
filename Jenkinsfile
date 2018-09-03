#!/usr/bin/groovy

// gets the id of self (eg. the container we are executing within at the moment)
def getContainerID() {
  return sh(script: 'cat /proc/self/cgroup | head -n 1 | awk -F \'/\' \'{print $NF}\'', returnStdout: true).trim()
}

// this will return the actual path to the directory containing the workspace of the running slave
// since a slave is itself a container, it is slightly more involved mounting things in other
// containers from here so we use a helper that queries the docker daemon for information
// on where the mount is on the host
def getContainerWorkspaceVolume() {
  return sh(
    script: "docker inspect -f '{{ range .Mounts }}{{ if eq .Destination \"/home/jenkins\" }}{{ .Source }}{{ end }}{{ end }}' ${getContainerID()}",
    returnStdout: true
  ).trim()
}

def dockerRun(image, cmdline) {
  sh "docker run --rm -v ${getContainerWorkspaceVolume()}:/home/jenkins -w \$(pwd) ${image} /bin/sh -c '${cmdline}'"
}

stage("Test") {
  node {
    deleteDir()
    stage("Checkout") {
      checkout scm
    }
    stage("Build") {
      dockerRun("nixos/nix", '''
        nix-shell --run "make lint && make test"
      ''')
    }
  }
}
