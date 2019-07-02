references:
  prepare_ci: &prepare_ci
    run:
      name: Prepare CI Environment
      command: |
        nix-channel --add \
        https://nixos.org/channels/nixpkgs-unstable nixpkgs && \
        nix-channel --update

version: 2
jobs:
  test:
    docker:
      - image: nixorg/nix:circleci
    steps:

      - checkout
      - *prepare_ci
      - run:
          name: Test
          command: |
            nix-shell .circleci/build.nix --run strict-bash <<'NIXSH'
              echo "there are no tests - please implement some"
            NIXSH

  deploy:
    docker:
      - image: nixorg/nix:circleci
    steps:

      - checkout
      - *prepare_ci
      - setup_remote_docker
      - run:
          name: Docker Build
          command: |
            nix-shell .circleci/build.nix --run strict-bash <<'NIXSH'

              if [ -z "$NPM_TOKEN" ]; then
                echo Missing NPM_TOKEN environment variable
                exit 1
              fi

              docker build --build-arg NPM_TOKEN="$NPM_TOKEN" \
                 -t "$PROJECT_NAME" .

              docker tag "$PROJECT_NAME" \
                 "eu.gcr.io/$INFRA_GOOGLE_PROJECT_ID/$PROJECT_NAME:$SHORTSHA"

            NIXSH

      - run:
          name: Kustomize and store kubernetes manifests
          command: |
            nix-shell .circleci/build.nix --run strict-bash <<'NIXSH'

              export VARIABLES="\$GOOGLE_PROJECT_ID:\$SHORTSHA"

              deploy-manifest() {
                DEST=$1
                export GOOGLE_PROJECT_ID=$2

                echo -e "\nUploading $DEST k8s manifest to gcp bucket '$MANIFESTS_BUCKET'"
                kustomize build "kubernetes/overlays/$DEST" | \
                  envsubst $VARIABLES > "$DEST-manifest.yaml"

                cat "$DEST-manifest.yaml"

                gsutil -h "x-goog-meta-commit:$SHORTSHA" cp \
                  "$DEST-manifest.yaml" \
                  "gs://$MANIFESTS_BUCKET/$PROJECT_NAME/$SHORTSHA-$DEST-manifest.yaml"
              }

              deploy-manifest development "$DEVELOPMENT_GCP_PROJECT"
              deploy-manifest production "$PRODUCTION_GCP_PROJECT"

            NIXSH

      - run:
          name: Docker Push
          command: |
            nix-shell .circleci/build.nix --run strict-bash <<'NIXSH'

              docker push \
                 "eu.gcr.io/$INFRA_GOOGLE_PROJECT_ID/$PROJECT_NAME:$SHORTSHA"

            NIXSH

workflows:
  version: 2
  build_test_deploy:
    jobs:
      - test
      - deploy:
          requires:
            - test
          filters:
            branches:
              only:
                - master
                - dev