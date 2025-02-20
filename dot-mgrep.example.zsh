#!/bin/zsh
declare -a xf xd od of
 
# Examples of configurations
# Write shell functions to set options
 
ignore_vim() {
  xf+=('.vim*' viminfo .exrc)
}
 
ignore_zshell_artifact() {
  xf+=(.z .zsh_history)
}
 
ignore_version_managers() {
  xf+=('.nvm*' '.asdf*' .tool-versions)
}
 
ignore_github_dir() {
  xd+=(.git)
}
 
ignore_tool_dirs() {
  # Local History VS Code plugin
  xd+=(.history)
}
 
ignore_npm_artifact() {
  xd+=(.npm)
  xf+=(package-lock.json)
}
 
ignore_node_modules() {
  xd+=(.node_modules)
}
 
ignore_pnpm_artifact() {
  xf+=(pnpm-lock.yaml)
}
 
ignore_yarn_artifact() {
  xf+=(yarn.lock)
  xd+=(.yarn)
}
 
ignore_package_manager_artifact() {
  ignore_npm_artifact
  ignore_pnpm_artifact
  ignore_yarn_artifact
}
 
ignore_log_artifact() {
  xf+=('*.log')
}
 
ignore_minified() {
  xf+=('*.min.js' '*.min.css' '*.chunk.js')
}
 
ignore_newrelic() {
  xf+=('newRelic*.js')
}
 
ignore_source_map() {
  xf+=('*.js.map' '*.css.map')
}
 
ignore_build_artifact() {
  ignore_minified
  ignore_source_map
  xd+=(build dist .nx)
}
 
ignore_dev_artifact() {
  ignore_package_manager_artifact
  ignore_log_artifact
  ignore_build_artifact
}
 
ignore_dev_config() {
  ignore_github_dir
  ignore_tool_dirs
  ignore_version_managers
}
 
ignore_user_environment() {
  ignore_vim
  ignore_zshell_artifact
}
 
source_code() {
  # Will follow Github if so configured
  ignore_dev_artifact
  ignore_dev_config
  ignore_newrelic
  ignore_user_environment
}
 
code() {
  # All source code - even node_modules
  github=0
  source_code
}
 
# Can be used for searching multiple projects
project_code() {
  ignore_node_modules
  source_code
}
 
# Default init - project search
init_mgrep() {
  project_code
}
 
