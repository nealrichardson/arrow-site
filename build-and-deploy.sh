#!/bin/bash
set -ev

if [ "${TRAVIS_PULL_REQUEST}" = "false" ] && [ "${TRAVIS_BRANCH}" = "master" ]; then
    export AUTHOR_EMAIL=$(git log -1 --pretty=format:%ae)
    export AUTHOR_NAME=$(git log -1 --pretty=format:%an)
    git config --global user.email "${AUTHOR_EMAIL}"
    git config --global user.name "${AUTHOR_NAME}"

    if [ ! -z "${STAGING_URL}" ]; then
        perl -pe 's@^baseurl.*@baseurl: '"${STAGING_URL}"'@' -i _config.yml
        export TARGET_BRANCH=gh-pages
    elif [ "${TRAVIS_REPO_SLUG}" = "apache/arrow-site" ]; then
        # Production
        export TARGET_BRANCH=asf-site
    else
        echo "You must set a STAGING_URL environment variable in the Travis repository settings"
        exit 1
    fi

    if [ -z "${GITHUB_PAT}" ]; then
        echo "You must set a GITHUB_PAT in the Travis repository settings"
        exit 1
    fi

    # Build
    gem install jekyll bundler
    bundle install
    JEKYLL_ENV=production bundle exec jekyll build

    # Publish
    git clone -b ${TARGET_BRANCH} https://${GITHUB_PAT}@github.com/$TRAVIS_REPO_SLUG.git OUTPUT
    rsync -r build/ OUTPUT/
    cd OUTPUT


    git add .
    git commit -m "Updating built site (build ${TRAVIS_BUILD_NUMBER})" || true
    git push origin ${TARGET_BRANCH} || true
fi
