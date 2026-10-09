set shell := ["bash", "-c"] 
set dotenv-load

# Setup the gamescope source for the pip plugin repo
[group('Gamescope Source Setup')]
srcsetup:
    #!/usr/bin/env bash
    mkdir -p backend/src backend/out
    pushd backend/
    git clone -b pip-window https://github.com/zeroultragames/gamescope.git src
    pushd src
    git submodule update --init
    cat > subprojects/wayland-protocols.wrap <<EOF
    [wrap-git]
    url = https://gitlab.freedesktop.org/wayland/wayland-protocols.git
    revision = 1.46
    EOF
    rm -rf .git .github
    popd
    meson subprojects download --sourcedir src
    meson subprojects download --sourcedir src/subprojects/libdisplay-info
    pushd src/subprojects/libdisplay-info/subprojects
    mv v4l-utils.wrap v4l-utils.wrap.bak

# Clean up gamescope source and build files
[group('Gamescope Source Setup')]
srcclean:
    rm -rf backend/src backend/out

# Rebuild backend/src directory for gamescope
[group('Gamescope Source Setup')]
srcresetup: srcclean srcsetup

# Check if the src files are proper
[group('Gamescope Source Setup')]
srctest:
    #!/usr/bin/env bash
    dirs=("backend/src" \
    "backend/src/src/reshade" \
    "backend/src/subprojects/libdisplay-info" \
    "backend/src/subprojects/libliftoff" \
    "backend/src/subprojects/openvr" \
    "backend/src/subprojects/vkroots" \
    "backend/src/subprojects/wlroots" \
    "backend/src/thirdparty/SPIRV-Headers" \
    "backend/src/subprojects/libdisplay-info/subprojects/v4l-utils")
    
    for dir in "${dirs[@]}"; do
        path="$dir/.git"
        echo "check $path"
        if [ ! -e "$path" ]; then
            echo "Error: $path directory is not setup to build gamescope"
            echo "you probably need to run, just srcsetup"
            exit 1
        fi
    done


# Install depedencies for basic setup
[group('PRELIMINARY SETUP TASKS')]
depsetup:
    bash .vscode/setup.sh

# pnpm setup task to grab all needed modules
[group('PRELIMINARY SETUP TASKS')]
pnpmsetup:
    which pnpm && pnpm i

# Preliminary "All-in-one" setup task
[group('PRELIMINARY SETUP TASKS')]
setup: srctest depsetup pnpmsetup updatefrontendlib
    echo "Set up depedencies pnpm and update Decky Frontend Library."

# Preliminary Deploy Config Setup
[group('PRELIMINARY SETUP TASKS')]
settingscheck:
    #!/usr/bin/env bash
    echo "Check that .env has been created"
    FILE=default.env
    if [ ! -f "$FILE" ]; then
    cat > $FILE <<EOF
    DECKIP=deck
    DECKPASS='${DECK_PASS}'
    DECKUSER=deck
    DECKDIR=/home/deck
    PLUGINNAME=gamescope-custom
    PYTHON_ANALYSIS_EXTRAPATHS_0=./py_modules
    EOF
    fi

# Build plugin with CLI
[group('BUILD TASKS')]
cli-build:
    #!/usr/bin/env bash
    CLI_LOCATION="$(pwd)/cli"
    echo "Building plugin in $(pwd)"
    $CLI_LOCATION/decky plugin build $(pwd)

# "All-in-one" build task
[group('BUILD TASKS')]
build: setup settingscheck cli-build
    echo "Build gamescope-picture-in-picture"

# "After Initial srcsetup" build task
[group('BUILD TASKS')]
short_build: settingscheck cli-build
    echo "Build gamescope-picture-in-picture"

# Copies the zip file of the built plugin to the plugins folder
[group('DEPLOY TASKS')]
copyzip: chmodplugins
    #!/usr/bin/env bash
    echo "Deploy plugin zip to deck"
    scp out/*.zip deck:${DECKDIR}/homebrew/plugins/
    ssh ${DECKIP} "echo ${DECKPASS} | sudo -S chmod --recursive 0755 ${DECKDIR}/homebrew/plugins"

[group('DEPLOY TASKS')]
extractzip:
    #!/usr/bin/env bash
    echo "${DECKDIR}/homebrew/plugins/${PLUGINNAME}.zip"
    ssh ${DECKIP} "echo ${DECKPASS} | sudo -S mkdir -m 755 -p ${DECKDIR}/homebrew/plugins/${PLUGINNAME}"
    ssh ${DECKIP} "echo ${DECKPASS} | sudo -S chown ${DECKUSER}:${DECKUSER} ${DECKDIR}/homebrew/plugins/${PLUGINNAME}"
    ssh ${DECKIP} "echo ${DECKPASS} | sudo -S bsdtar -xzpf ${DECKDIR}/homebrew/plugins/${PLUGINNAME}.zip -C ${DECKDIR}/homebrew/plugins/${PLUGINNAME} --strip-components=1 --fflags"

# "All-in-one" deploy task
[group('DEPLOY TASKS')]
deploy: copyzip extractzip

# "All-in-on" build & deploy task
[group('DEPLOY TASKS')]
builddeploy: build deploy
    echo "Builds plugin and deploys to deck"

#  Update Decky Frontend Library aka DFL
[group('GENERAL TASKS')]
updatefrontendlib:
    pnpm update @decky/ui --latest

test_var:
    #!/usr/bin/env bash
    var1='${HOME}'
    echo $var1
    ssh deck "echo ${DECKPASS} ${var1} > deckpass.txt"

# Used chmod plugins folder to allow copy-over of files
[group('GENERAL TASKS')]
chmodplugins:
    #!/usr/bin/env bash
    ssh ${DECKIP} "echo ${DECKPASS} | sudo -S chown -R ${DECKUSER} ${DECKDIR}/homebrew/plugins/"

# restarts decky
[group('GENERAL TASKS')]
restartdecky:
    #!/usr/bin/env bash
    ssh ${DECKIP} "echo ${DECKPASS} | sudo -S systemctl restart plugin_loader"

