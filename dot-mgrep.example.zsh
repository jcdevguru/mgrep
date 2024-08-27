#!/bin/zsh
declare -a xf xd od of

# Examples of configurations
# Write shell functions to set options

ignore_github() {
  github=0
  xf+=(.gitignore)
  xd+=(.git)
}

ignore_npm_artifact() {
  xd+=(.npm node_modules)
  xf+=(package-lock.json)
}

ignore_pnpm_artifact() {
  xf+=(pnpm-lock.yaml pnpm-workspace.yaml)
}

ignore_vim() {
  xf+=('.vim*' viminfo .exrc))
}

ignore_minified() {
  xf+=('*.min.js' '*.min.css')
}

ignore_package_manager_artifact() {
  ignore_npm_artifact
  ignore_pnpm_artifact
}

ignore_version_managers() {
  xf+=('.nvm*' '.asdf*' .tool-versions)
}

dev_no_github() {
  ignore_github
  ignore_artifact
  ignore_vim
  ignore_package_managers
}

dev_github() {
  github=1
}

ignore_magento_artifact() {
  xd+=(.composer generated 'pub*')
  xf+=(composer.lock)
}

# Sample preferences for a developer who
# uses Github but is not interested in
# lock files from package managers, and
# where minified files are tracked in Github

dev_github
ignore_minified
ignore_package_manager_artifact
