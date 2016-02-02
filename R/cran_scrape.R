## http://rpubs.com/bbolker/3750

getBlob <- function(repos=getOption("repos")[1],blob=NULL) {
    if (is.null(blob)) {
        if (substr(repos,nchar(repos),nchar(repos))!="/")
           repos <- paste0(repos,"/")
        ## does this work if getOption("repos") is @CRAN ?
        blob <- readLines(url(paste0(repos,"report_cran.html")))
        ## FIXME: check if this worked or not ... may not work for all repos
        attr(blob,"repos") <- repos
    }
    return(blob)
}
scrapePackageStats <- function(...) {
    require(stringr)
    blob <- getBlob(...)
    binstr <- c("/bin/.*/contrib/[^/]+/.*\\.tgz",  ## MacOS binaries
                "/bin/.*/contrib/[^/]+/.*\\.zip",  ## Windows binaries
                "/src/contrib/.*.tar.gz")          ## source
    ## pull all lines matching patterns
    split1 <- unlist(lapply(binstr,grep,x=blob,value=TRUE))
    ## get package names
    x2 <- str_extract(split1,pattern="[^/]+\\.(tgz|tar\\.gz|zip)")
    ## get numbers of times downloaded
    x3 <- as.numeric(gsub("^.*class=\"R\">([0-9]+).*$","\\1",split1))
    ## could also distinguish by OS version ...
    x4 <- tapply(x3,list(x2),sum)
    d <- data.frame(pkgfull=names(x4),n=x4)
    rownames(d) <- NULL
    transform(d,
              pkg=gsub("_.*$","",pkgfull),
              num=gsub(".*_([0-9.-]+)\\..*$","\\1",pkgfull),
              type=str_extract(pkgfull,"(tar\\.gz|tgz|zip)$"))
}

blob <- getBlob("http://cran.at.r-project.org/")
#blob <- getBlob("http://cran.rapporter.net/")
#blob <- getBlob("http://cran.stat.sfu.ca/")
x <- scrapePackageStats(blob=blob)
xx <- aggregate(data.frame(n=x$n), list(pkg=x$pkg), sum)
xx$rank <- rank(-xx$n)
xx$q <- round(xx$rank / length(xx$rank), 2)
xx <- xx[order(xx$rank),]
mypkg <- c("mefa", "mefa4", "detect", "sharx", "ResourceSelection",
    "epiR", "plotrix", "adegenet", "vegan", "detect", "dcmle", "dclone",
    "pbapply", "PVAClone", "sharx")
(xxx <- xx[xx$pkg %in% mypkg,])


mirrors <- readLines(url("http://cran.r-project.org/mirrors.html"))
mirrors <- mirrors[grep("<a href=\"http://", mirrors)]
mirrors <- mirrors[!grepl("rstudio", mirrors)]
mirrors <- mirrors[!grepl("several <a href", mirrors)]
mirrors <- strsplit(mirrors, "\"")
mirrors <- sapply(mirrors, "[[", 2)


plot(xx$q, log(xx$n), type="l")
for (i in 1:nrow(xxx)) {
    lines(xxx$q[c(i,i)], c(0, log(xxx$n[i])))
    text(xxx$q[i], log(xxx$n[i])+0.4, as.character(xxx$pkg[i]))
}
#abline(h=log(xxx$n),col=2)
abline(v=xxx$q,col=2)


### seeing top R pachage authors

library(XML)
url <- "http://cran.r-project.org/web/checks/check_summary_by_maintainer.html"
x <- readHTMLTable(url)[[1]]
colnames(x) <- gsub(" ", "", colnames(x))
maint <- x$Maintainer
for (i in 2:length(maint))
    if (maint[i] == "")
        maint[i] <- maint[i-1]
maint <- droplevels(maint)

tab <- data.frame(n=rev(sort(table(maint))))
tab$rank <- 1:nrow(tab)
tab$q <- round(tab$rank / nrow(tab), 3)
grep("Solymos", rownames(tab))
tab[1:grep("Solymos", rownames(tab)),]


