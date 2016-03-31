#!/bin/bash

# $1: Project
# $2: Repo URL
# $3: Branch
# $4: Release version
# TODO: Need an option to toggle between dry-run and release
# TODO: Need an option to toggle between quick and full build when releasing
# TODO: What should be the process when the build fails? How should the fixes be handled?
#       Should that be part of the script? Should the script have an option to only do a build?
# TODO: Need to add a check for SNAPSHOT dependencies
# TODO: Get configuration from config files so more complex release processes can be automated
# TODO: Need to support source and destination repos and branches (or sha for source),
#       e.g., codice/ddf -> connexta/ddf. Destination = Source by default.
# TODO: Maven repo for deploy (path to settings.xml or options)

if [ "$#" -ne 4 ]; then
    echo "Invalid number of arguments"
    exit 1
fi

# TODO: Should be able to determine this instead of taking it in as a parameter
PROJECT=$1
GIT_REPO=$2
BRANCH=$3
NEW_VERSION=$4

echo "Project: $PROJECT"
echo "Git Repository: $GIT_REPO"
echo "Branch: $BRANCH"
# TODO: Determine next release version from current one
echo "New version: $NEW_VERSION"

LOCAL_MAVEN_REPO="/tmp/m2"
MVN_BASE_OPTS="-Dmaven.repo.local=$LOCAL_MAVEN_REPO"
# TODO: Need to run with documentation profile enabled
MVN_DRY_RUN_OPTS="$MVN_BASE_OPTS -DskipTests"
MVN_RELEASE_OPTS="$MVN_BASE_OPTS"
MVN_RELEASE_DEPLOY_OPTS="$MVN_BASE_OPTS -nsu -P\!documentation -P\!findbugs -DskipTests -Dpmd.skip=true -Djacoco.skip=true -Dfindbugs.skip=true -Dcheckstyle.skip=true"

fail() {
    message=$1; exitCode=$2

    echo "Error: $message"
    exit ${exitCode}
}

cleanup() {
    rm -rf ${PROJECT}
    rm -rf ${LOCAL_MAVEN_REPO}
}

clone() {
    gitRepo=$1; branch=$2; project=$3

    git clone --depth 1 ${gitRepo} --branch ${branch} ${project} \
        || fail "Failed to clone git repository" 1
}

setVersion() {
    newVersion=$1

    mvn versions:set -DnewVersion=${newVersion} \
        || fail "Failed to update project to version $newVersion" 1
}

clone ${GIT_REPO} ${BRANCH} ${PROJECT}

cd ${PROJECT}

CURRENT_VERSION=`mvn -N help:evaluate -Dexpression=project.version | grep "^[0-9].*"`
echo "Current version: $CURRENT_VERSION"

setVersion ${NEW_VERSION}

# If dry-run
mvn ${MVN_DRY_RUN_OPTS} clean install \
    || fail "Dry-run build failed" 1

exit 0


# If release
mvn ${MVN_RELEASE_OPTS} clean install

# TODO: git commit and tag

# TODO: Consider using a staging Nexus repo
mvn ${MVN_RELEASE_DEPLOY_OPTS} deploy

# TODO: git push
