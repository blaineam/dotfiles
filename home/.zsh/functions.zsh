# Convenient function to allow local overrides for all sourced files
function load_file {
    [ -e ~/.zsh/${1} ] && . ~/.zsh/${1} || true
    [ -e ~/.zsh.local/${1} ] && . ~/.zsh.local/${1} || true
}

function man {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
        man "$@"
}

function git_ignore {
    selections=$(curl -s 'https://www.toptal.com/developers/gitignore/api/list?format=json' | \
        jq '.[].name' | \
        fzf -m --prompt='Template> ' | \
        sed 's/^"\(.*\)"$/\1/' | \
        tr '\n' ',' | \
        sed 's/.$//')

    if [ $? -ne 0 ]; then
        return 1
    fi

    if [ -e .gitignore ]; then
        echo "Appending to existing .gitignore file."
    fi

    curl -sLw "\n" "https://www.gitignore.io/api/${selections}" >> .gitignore
}

function record_gif {
    if [ -z "$1" ]; then
        echo "You must provide a name for the gif"
        return 1
    fi

    local currentDir=$(pwd)

    tmpDir=$(mktemp -d /tmp/gif-recording.XXXXXX)

    if [ $? -ne 0 ]; then
        echo "Failed to create temp dir"
        return 1
    fi

    cd $tmpDir

    if [ $? -ne 0 ]; then
        echo "Failed to change into $tmpDir"
        return 1
    fi

    echo "Click the window to record"
    winInfo=$(xwininfo)

    width=$(echo $winInfo | grep 'Width:' | awk -F: '{ print $2 }')
    height=$(echo $winInfo | grep 'Height:' | awk -F: '{ print $2 }')
    upperLeftX=$(echo $winInfo | grep 'Absolute upper-left X:' | awk -F: '{ print $2 }')
    upperLeftY=$(echo $winInfo | grep 'Absolute upper-left Y:' | awk -F: '{ print $2 }')

    echo "Beginning screen capture. Press [q] when finished"
    ffmpeg -loglevel quiet -f x11grab -video_size ${width}x${height} -framerate 60 -i :0.0+${upperLeftX},${upperLeftY} -c:v ffvhuff screen.mkv

    if [ $? -ne 0 ]; then
        echo "An error occurred capturing video"
        cd -
        return 1
    fi

    echo "Generating palette.png"
    ffmpeg -loglevel quiet -i screen.mkv -vf fps=15,scale=${width}:-1:flags=lanczos,palettegen palette.png

    echo "Converting screen.mkv to ${currentDir}/${1}.gif"
    ffmpeg -loglevel quiet -i screen.mkv -i palette.png -filter_complex "fps=15,scale=${width}:-1:flags=lanczos[x];[x][1:v]paletteuse" ${currentDir}/$1.gif

    cd "$currentDir"
}

function swatch {
    if [[ $# == 0 ]]; then
        echo "Fetch recent logs and follow for new messages. Parameters:"
        echo "  -h|--hours ..... hours of logs in the past to fetch (optional, defaults to 1 hr)"
        echo "  -g|--group ..... log group"
        echo "  -p|--profile ... aws profile"
        echo "  -x|--prefix .... stream prefix"
        return
    fi

    local hours=1
    local group=
    local profile=default
    local prefix=

    while [[ "$#" > 0 ]]; do
        case "${1}" in
            -h|--hours)
                hours=${2}
                shift 2;;
            -g|--group)
                group=${2}
                shift 2;;
            -p|--profile)
                profile=${2}
                shift 2;;
            -x|--prefix)
                prefix=${2}
                shift 2;;
            *)
                shift;; # unexpected params
        esac
    done

    echo "Fetching ${hours}h of ${group} ${prefix} logs using ${profile} profile..."

    if [[ ! -z ${prefix} ]]; then
        prefix=(--prefix "${prefix}")
    fi

    saw --profile ${profile} get ${group} "${prefix[@]}" --pretty --start -${hours}h
    saw --profile ${profile} watch ${group} "${prefix[@]}"
}

function load_nvm () {
    if [ ! -e "$HOME/.nvm" ]; then
        >&2 echo "You do not have nvm installed"
        return
    fi

    command -v nvm > /dev/null
    if [ $? -ne 0 ]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
    else
        >&2 echo "nvm already loaded"
    fi
}

function load_rvm () {
    if [ ! -e $HOME/.cache/yay/rvm/rvm.sh ]; then
        >&2 echo "You do not have rvm installed"
        return
    fi

    command -v rvm > /dev/null

    if [ $? -ne 0 ]; then
        . $HOME/.cache/yay/rvm/rvm.sh
    else
        >&2 echo "rvm already loaded"
    fi
}

. ~/.zsh/functions/docker.zsh

function gPo {
    read -q "reply?push to: $(git rev-parse --abbrev-ref HEAD) ? (N/y)"
    echo

    if [[ $reply =~ ^[Yy]$ ]]
    then
        git push origin $(git rev-parse --abbrev-ref HEAD)
    else
        echo "Aborting!"
    fi
}

function gpo {
    read -q "reply?pull from: $(git rev-parse --abbrev-ref HEAD) ? (N/y)"
    echo

    if [[ $reply =~ ^[Yy]$ ]]
    then
        git pull origin $(git rev-parse --abbrev-ref HEAD)
    else
        echo "Aborting!"
    fi
}

function dkr-stopall {
    read -q "reply?Are you sure you'd like to stop everything? "
    echo

    if [[ $reply =~ ^[Yy]$ ]]
    then
        docker stop $(docker ps -a -q)
    else
        echo "Aborting!"
    fi
}

function start-repo {
    local DIR="$(pwd)"
    cd ../docker-rs
    ../docker-rs/docker.sh symlink
    ../docker-rs/docker.sh restart
    ../docker-rs/docker.sh proxy
    aws-rotate-iam-keys --profile default,rsc-main
    set-aws-env default
    cd "$DIR"
    ./bin/docker.sh restart
}

function start-repo-no-keys {
    local DIR="$(pwd)"
    cd ../docker-rs
    ../docker-rs/docker.sh symlink
    ../docker-rs/docker.sh restart
    ../docker-rs/docker.sh proxy
    cd "$DIR"
    ./bin/docker.sh restart
}


function stop-repo {
    local DIR="$(pwd)"
    cd ../docker-rs
    ../docker-rs/docker.sh stop
    cd "$DIR"
    ./bin/docker.sh stop
}


function stop-operations {
    cd $HOME/operations
    stop-repo
}


function start-operations {
    cd $HOME/operations
    start-repo
}

function dev-env {
    tmux send-keys 'pwd' C-m
    # Launch Vim Window
    tmux new-window
    tmux rename-window vim
    tmux send-keys 'vim' C-m

    # Launch Docker Shell Window
    tmux new-window
    tmux rename-window docker
    tmux send-keys './bin/docker.sh bash' C-m

    # Launch SQL Window
    tmux new-window
    tmux rename-window sql
    tmux send-keys 'vim ./sql.mysql' C-m

    # Launch Log Window
    tmux new-window
    tmux rename-window logs
    tmux send-keys 'dkr-logs' C-m

    tmux select-window -t 1
}

function dev {
    tmux new -s DEV -d
    tmux send-keys -t DEV 'dev-env' C-m
    tmux attach -t DEV
}

function tdev {
    tmate -S /tmp/tmate.sock new-session -s TDEV -n Shell -d
    tmate -S /tmp/tmate.sock send-keys -t TDEV 'q'
    tmate -S /tmp/tmate.sock send-keys -t TDEV 'dev-env' C-m
    tmate -S /tmp/tmate.sock send-keys -t TDEV 'tmate show-messages' C-m
    tmate -S /tmp/tmate.sock attach -t TDEV
}

function thor {
    cd $HOME/operations
    tdev
}

function oden {
    cd $HOME/operations
    dev
}

function t {
    if [ $# -ne 1 ]; then
      echo "Usage: `basename $0` session-name"
      exit;
    fi

    session_name="$1"

    tmux has-session -t ${session_name} 2> /dev/null

    if [ $? != 0 ]
    then
      # Create the session with a default shell window
      tmux new-session -s "${session_name}" -n Shell -d

      # Create a window dedicated for my editor
      tmux new-window -n vim -t "${session_name}:2"
      tmux send-keys -t "${session_name}:2" 'vim' C-m

      # Start out on the first window when we attach
      tmux select-window -t "${session_name}:1"
    fi

    # tmux -CC attach -t "${session_name}"
    tmux attach -t "${session_name}"
}

function dkr-proxy {
    mkdir -p ~/.config/nginx-proxy/{html,vhost.d,htpasswd,certs}
    touch ~/.config/nginx-proxy/proxy.conf

    docker stop proxy && \
        docker rm proxy

    docker pull jwilder/nginx-proxy && \
        dkr-run --name proxy -d \
            -p 80:80 \
            -v /var/run/docker.sock:/tmp/docker.sock:ro \
            -v ~/.config/nginx-proxy/html:/usr/share/nginx/html:rw \
            -v ~/.config/nginx-proxy/proxy.conf:/etc/nginx/conf.d/custom-proxy.conf:ro \
            -v ~/.config/nginx-proxy/vhost.d/:/etc/nginx/vhost.d:rw \
            -v ~/.config/nginx-proxy/htpasswd/:/etc/nginx/htpasswd:ro \
            --log-opt max-size=5M \
            --net bridge \
            --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true \
            jwilder/nginx-proxy

    docker network connect rsc proxy 2> /dev/null || true
}

function set-aws-env() {
    typeset -A AWS_SETTINGS=($(awk -F"=" "/\[$1\]/{ x = NR + 2; next }(NR <= x){ printf \"%s %s \", \$1, \$2 }" ~/.aws/credentials))
    for k v in ${(kv)AWS_SETTINGS}
    do
        export ${k:u}=$v
    done
}

