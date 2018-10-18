#!/usr/bin/groovy

def hasCmd(cmd) { "command -v ${cmd} >/dev/null 2>&1" }

def shell(cmd) {
  def nixInitPath = '$HOME/.nix-profile/etc/profile.d/nix.sh'
  sh """
     if ! ${hasCmd('nix-shell')}; then
        if [ -e ${nixInitPath} ]; then
           . ${nixInitPath}
        else
           curl https://nixos.org/nix/install | sh
           . ${nixInitPath}
        fi
     fi
     ${cmd}
     """
}

def nixShell(cmd) { shell """ nix-shell --run "${cmd}" """ }

//def labels = ['linux', 'osx']
def labels = ['linux']
def builders = [:]

for (x in labels) {
    def label = x
    builders[label] = {
      node(label) {

        stage("Prerequisites") { shell """ nix-env -iA nixpkgs.git """ }

        stage("Checkout") { checkout scm }

        stage("Build") { nixShell "make" }

        stage("Lint") { nixShell "make lint" }

        stage("Test") { nixShell "make test" }
    }
  }
}

parallel builders