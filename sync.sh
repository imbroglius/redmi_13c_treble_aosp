#!/bin/bash

echo
echo "--------------------------------------"
echo "          AOSP 14.0 Syncbot           "
echo "                  by                  "
echo "                ponces                "
echo "--------------------------------------"
echo

set -e

BL=$PWD/imbroglios_gsi
TD="android-14.0"

initRepos() {
    echo "--> Getting latest upstream version"
    aosp=$(curl -sL https://github.com/TrebleDroid/treble_manifest/raw/$TD/replace.xml | grep -oP "${TD}.0_r\d+" | head -1)
    
    echo "--> Initializing workspace"
    repo init -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r61 --git-lfs
    echo

    echo "--> Preparing local manifest"
    if [ -d .repo/local_manifests ]; then
        (cd .repo/local_manifests; git fetch; git reset --hard; git checkout origin/$TD)
    else
        git clone https://github.com/TrebleDroid/treble_manifest .repo/local_manifests -b $TD
    fi
    echo
}

syncRepos() {
    echo "--> Syncing repos"
    repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all) || repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
    echo
}

generatePatches() {
    echo "--> Generating patches"
    rm -rf patchest patchest.zip
    wget -q https://github.com/TrebleDroid/treble_experimentations/raw/master/list-patches.sh -O list-patches.sh
    sed -i "s/patches/patchest/g" list-patches.sh
    bash list-patches.sh
    echo
}

updatePatches() {
    echo "--> Updating patches"
    #rm -rf $BL/patches/trebledroid
    unzip -q patchest.zip
    mv patchest $BL/patches/trebledroid
    echo
}

START=$(date +%s)

initRepos
syncRepos
generatePatches
updatePatches

END=$(date +%s)
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Syncbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo
