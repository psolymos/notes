#!/bin/bash

# this file is to spare few moments when testing R packages
# it cleans TMPDIR and clone/build/check packages one by one
# package names are taken from args list

# use it like:
# $ sudo bash ~/repos/notes/R/crancheck.sh pkg_1 pkg_2 ... pkg_n

# for my selfish purposes:
# $ sudo bash crancheck.sh detect pbapply ResourceSelection mefa4
# $ sudo bash crancheck.sh sharx PVAClone dcmle dclone


TMPDIR=~/tmpdir
UPDATE=0
REPO1=psolymos
REPO2=datacloning

# exclude tests when those take too long for CRAN submission
RUNTEST=0

if [ $# -lt 1 ]; then
    echo no arguments provided
else {

    [ -d $TMPDIR ] && rm -r $TMPDIR
    mkdir $TMPDIR
    cd $TMPDIR

    if [ $UPDATE -gt 0 ]; then
        echo ---------- updating R packages ----------
        R CMD BATCH --vanilla ~/repos/notes/R/updates.R updates.Rout
    fi

    for i in $@; do {

        REPO=$REPO1
        if [ $i = 'dclone' ]; then
            REPO=$REPO2
        fi
        if [ $i = 'dcmle' ]; then
            REPO=$REPO2
        fi

        echo ---------- cloning R package $i ----------
        git clone https://github.com/$REPO/$i

        if [ $RUNTEST -lt 1 ]; then
            echo ---------- tests dir removed ----------
            rm -r -f $i/tests
        fi

        echo ---------- building R package $i ----------
        R CMD build $i --compact-vignettes

    }
    done
    for f in *.tar.gz; do {
        echo ---------- checking R package from file $f ----------
        R CMD check $f --as-cran
    }
    done
    echo ---------- done ----------
}
fi
