#!/usr/bin/env bash

# TODO: In the future, have this script take a branch
# for each repo containing the right PO files.

REPOS_DIR_ROOT=`mktemp -d`
PUPPET_GIT_URL="git@github.com:puppetlabs"
PUPPET_REPOS=(
  "pe-console-ui"
  "jdbc-util"
  "clj-rbac-client"
  "pe-console-auth-ui"
  "classifier"
  "pe-rbac-service"
  "pe-activity-service"
  "orchestrator"
  "pcp-broker"
  "clj-pcp-client"
  "bouncer-validators"
  "clj-pxp-puppet"
  "orchestrator-client"
  "puppet-forge-web"
  "puppet"
  "puppet-access"
  "higgs"
  )
THIRD_PARTY_REPOS=(
  "git@github.com:postgres/postgres.git"
  )
ALL_REPOS=()
for puppet_repo in "${PUPPET_REPOS[@]}"; do
  ALL_REPOS+=("${PUPPET_GIT_URL}/${puppet_repo}.git")
done
ALL_REPOS=("${ALL_REPOS[@]}" "${THIRD_PARTY_REPOS[@]}")

PO_FILES_DIR_ROOT="resources/ja"

is_japanese_po_file() {
  file="$1"
  if [[ -z `grep "Language: ja" "$file"` ]]; then
    return 1
  fi 

  return 0
}

get_all_po_files() {
  repo_url="$1"
  repo_name=`echo "${repo_url}" | sed -n 's/.*\/\(.*\).git/\1/p'`
  repo_dir="${REPOS_DIR_ROOT}/${repo_name}"
  cwd=`pwd`

  cd "$REPOS_DIR_ROOT"
  git clone "${repo_url}" 
  cd "$cwd"
 
  # at this point, our repo should have been created.
  counter=0
  for po_file in `find "${repo_dir}" -name "*.po"`; do
    if is_japanese_po_file "$po_file"; then
      cp "$po_file" "${PO_FILES_DIR_ROOT}/${repo_name}${counter}.po"
      counter=$((counter+1))
    fi
  done
}

mkdir ${REPOS_DIR_ROOT}
mkdir ${PO_FILES_DIR_ROOT}

# Core loop to do the processing work
for repo in "${ALL_REPOS[@]}"; do
  get_all_po_files "$repo"
done

# Clean up
rm -rf ${REPOS_DIR_ROOT}
