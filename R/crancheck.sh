#!/bin/bash
if [ $# -lt 1 ]; then
    echo no arguments provided
else {

    [ -d ~/tmpdir ] && rm -r ~/tmpdir
    mkdir ~/tmpdir
    cd ~/tmpdir

    echo ---------- updating R packages ----------
    R CMD BATCH --vanilla ~/repos/notes/R/updates.R updates.Rout

    for i in $@; do {

        echo ---------- clone R package $i ----------
        git clone https://github.com/psolymos/$i

        echo ---------- build R package $i ----------
        R CMD build $i

        echo ---------- check R package $i ----------
        R CMD check $i_*.tar.gz --as-cran

    }
    done
    echo done
}
fi




