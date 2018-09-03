#!/usr/bin/groovy

// gets the id of self (eg. the container we are executing within at the moment)
def getContainerID() {
  return sh(script: 'cat /proc/self/cgroup | head -n 1 | awk -F \'/\' \'{print $NF}\'', returnStdout: true).trim()
}

// this will return the ACTUAL path to the directory containing the workspace of the running slave
// since a slave is itself a container, it is slightly more involved mounting things in other
// containers from here so we use a helper that queries the docker daemon for information
// on where the mount is on the host - you still need to append the WORKSPACE basename
def getContainerWorkspaceVolume() {
  return sh(
    script: "docker inspect -f '{{ range .Mounts }}{{ if eq .Destination \"/home/jenkins\" }}{{ .Source }}{{ end }}{{ end }}' ${getContainerID()}",
    returnStdout: true
  ).trim()
}

stage("Test") {
  node {
    deleteDir()
    stage("Checkout") {
      checkout scm
    }
    stage("Build") {
      sh "ls -lah"
      sh "env"
      sh "docker inspect ${getContainerID()}"
      sh "pwd"
      echo getContainerWorkspaceVolume()
      echo "waiting 10 minutes..."
      sh "sleep 600"
      sh "docker run --rm -v ${getContainerWorkspaceVolume()}:/checkout -w /checkout nixos/nix /bin/sh -c \"nix-shell --run 'make lint && make test'\""
    }
  }
}
