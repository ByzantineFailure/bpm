#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
INSTALL_OPTIONS=("Download correct node and install" "Install using local version" "Exit");
DISCORD_TEST="resources/app.asar";

runInstaller() {
    echo "Please enter the install directory";
    
    #Get and verify install dir
    read INSTALL_DIR;
    if [ -e "${INSTALL_DIR}/${DISCORD_TEST}"  ]; then
        echo "Installing to $INSTALL_DIR";
        $1 $DIR/index.js $DIR -p $INSTALL_DIR --ptb;
    else
        echo "Couldn't find ${INSTALL_DIR}/${DISCORD_TEST}, please enter a different directory.";
    fi
}

downloadNodeAndInstall() {
    echo "Downloading standalone tarball...";
    if [ $(getconf LONG_BIT) == "64" ]; then
        #Download 64-bit node
        curl -o $DIR/node.tar.gz https://nodejs.org/dist/v4.2.4/node-v4.2.4-linux-x64.tar.gz;
        echo "Unpacking node...";
        tar --strip-components=2 -xvf $DIR/node.tar.gz -C $DIR node-v4.2.4-linux-x64/bin/node;
    else
        #Download 32-bit node
        curl -o $DIR/node.tar.gz https://nodejs.org/dist/v4.2.4/node-v4.2.4-linux-x32.tar.gz;
        echo "Unpacking node...";
        tar --strip-components=2 -xvf $DIR/node.tar.gz -C $DIR node-v4.2.4-linux-x32/bin/node;
    fi
    runInstaller $DIR/node;
    echo "Removing node tarball and extract...";
    rm -rf $DIR/node;
    rm -f $DIR/node.tar.gz;
}

# Confirm `curl` exists
# Redirect stderr for command -v to stdout, redirect the error message to stderr.
command -v curl >/dev/null 2>&1 || { echo 'curl is required to install BPM for Discord.  Please place its binary on your PATH and try again.' >&2; exit 1; }

if [ -z $(which node) ]; then
    echo "Cannot find node";
    downloadNodeAndInstall;
else
    NODE_VERSION=$(node --version);
    #Test if node version is v4.2.* using regex
    if [[ $NODE_VERSION =~ ^v4\.2\..* ]]; then
        echo "Found node, running with local version...";
        runInstaller "node";
    else    
        echo "Could not find node of version v4.2.x, found node version $NODE_VERSION. What would you like to do?";
        select yn in "${INSTALL_OPTIONS[@]}"; do
            case $yn in
                "${INSTALL_OPTIONS[0]}") 
                    downloadNodeAndInstall;
                    exit;
                    ;;
                "${INSTALL_OPTIONS[1]}")
                    runInstaller "node";
                    exit;
                    ;;
                "${INSTALL_OPTIONS[2]}")
                    exit;
                    ;;
                *)
                    echo "Invalid option, try another one.";
                    continue;
                    ;;
            esac
        done
    fi
fi

echo "Press enter to continue..."
read BLANK

