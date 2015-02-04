DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
REPOS_PYTHON=$DIR/repos.py

export PATH=$PATH:$DIR
# Shortcut for: find <dir> -iname *<search>*
flike() {
  local search path
  if [ -z "$2" ]; then
    search="$1"
    path=.
  else
    search="$2"
    path="$1"
  fi
  find "${path}" -iname "*${search}*"
}

# Shortcut for: find -iname *<search>* -print0 | xargs -0 grep <grepfor>
ffg() {
  local search grepfor
  if [ -z "$2" ]; then
    grepfor="$1"
    search=
  else
    grepfor="$2"
    search="$1"
  fi

  gfind -type f -iname "*${search}*" -print0|xargs -0 grep "${grepfor}"
}

# Show listening ports
listening_ports() {
  sudo lsof -P -i -n | grep LISTEN
}

#List ips for interfaces
ips() {
  for interface in $(ifconfig -l); do
    ip=$(ifconfig $interface | grep "inet "  | cut -d\  -f2)
    if [ -n "$ip" ]; then
      echo "$interface: $ip"
    fi
  done
}

# Set the SOURCE ROOT, i.e. current environment.
# Also updates M2 settings to current environment
function base() {
  BASE_ROOT=$1
  NEW_SOURCE_ROOT=${SOURCES_ROOT}/${BASE_ROOT}
  if [ -z "${NEW_SOURCE_ROOT}" ]; then
    echo "No path for SOURCE_ROOT specified. Not updating"
    return
  fi
  if [ ! -d "${NEW_SOURCE_ROOT}" ]; then
    echo "Not a valid path [${NEW_SOURCE_ROOT}] for SOURCE_ROOT specified. Not updating"
    return
  fi

  if [ "${NEW_SOURCE_ROOT}" == "${SOURCE_ROOT}" ]; then
    echo "No new path for SOURCE_ROOT specified. Not updating"
    return
  fi

  if [ -f $HOME/.m2/settings-${BASE_ROOT}.xml ]; then
    echo "Switching M2 settings"
    cp $HOME/.m2/settings-${BASE_ROOT}.xml $HOME/.m2/settings.xml
  fi

  echo "Setting SOURCE_ROOT to: ${NEW_SOURCE_ROOT}"
  export SOURCE_ROOT=${NEW_SOURCE_ROOT}

  if [ -d "${NEW_SOURCE_ROOT}/.config" ]; then
    echo "Sourcing config"
    source "${NEW_SOURCE_ROOT}/.config"
  fi
  cd ${SOURCE_ROOT}
}

# Go to a source folder under current "SOURCE_ROOT"
function root() {
        cd ${SOURCE_ROOT}/$1
}

# Clone a git repo from GIT_BASE_URL
function clone() {
  cd ${SOURCE_ROOT}

  URL=$(python $REPOS_PYTHON print_clone_url $1)
  TOOL=${URL##*.}
  if [ $TOOL != "git" ]; then TOOL="hg"; fi
  DIRNAME=${URL##*/}
  DIRNAME=${DIRNAME%.*}
  $TOOL clone $URL
  cd $DIRNAME
}

# COMPLETIONS
_root() {
        if [ -z "${SOURCE_ROOT}" ]; then
                echo "ERROR: You must set SOURCE_ROOT to use the root command!"
                return
        fi
        local cur prev opts
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        opts="$(cd ${SOURCE_ROOT} && find -mindepth 1 -maxdepth 1 -type d -printf %f\\n)"

        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
}

_base() {
        local cur prev opts
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        opts="$(cd ${SOURCES_ROOT} && find -mindepth 1 -maxdepth 1 -type d -printf %f\\n)"

        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
}

_clone() {
        local cur prev opts
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        opts=$(python $REPOS_PYTHON print_repo_list)

        COMPREPLY=( $(compgen -W "${opts}" -X '!*'${cur}'*') )
}

_tabc() {
  NAME=$1; if [ -z "$NAME" ]; then NAME="Default"; fi
  # if you have trouble with this, change
  # "Default" to the name of your default theme
  echo -e "\033]50;SetProfile=$NAME\a"
}



_colorssh() {
    tab_reset() {
        echo "P"
        NAME="Solarized Dark"
        _tabc "Solarized Dark"
    }
    if [[ -n "$ITERM_SESSION_ID" ]]; then
        trap tab_reset INT EXIT # Hmmm..
        if [[ "$*" =~ "production*" ]]; then
            _tabc Production
        elif [[ "$*" =~ "staging*" ]]; then
            _tabc Staging
        else
            _tabc SSH
        fi
    fi
    ssh $*
    tab_reset
}
alias ssh="_colorssh"

complete -F _root root
complete -F _base base
complete -F _clone clone
