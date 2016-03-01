project.skeleton <-
function(name="project", path="~/repos",...)
{
    foo <- function(x) x
    dat <- data.frame(x=1)
    e <- list2env(list(dat=dat, foo=foo))
    package.skeleton(name = name, list=c("dat","foo"),
        environment=e,
        path = path, force = FALSE)
    file.remove(file.path(path, name, "Read-and-delete-me"))
    writeLines(paste0("# ", name, "\n\nWrite something about the ",
        name, " project here.\n"),
        file.path(path, name, "README.md"))
    writeLines(c("# No PDF/html/doc unless exceptions", "*.pdf", "*.doc", "*.docx",
        "*.htm", "*.html", "", "# Windows image file caches", "Thumbs.db",
        "ehthumbs.db", "", "# Folder config file", "Desktop.ini", "",
        "# Recycle Bin used on file shares", "$RECYCLE.BIN/", "", "# Windows Installer files",
        "*.cab", "*.msi", "*.msm", "*.msp", "", "# Windows shortcuts",
        "*.lnk", "", "# =========================", "# Operating System Files",
        "# =========================", "", "# OSX", "# =========================",
        "", ".DS_Store", ".AppleDouble", ".LSOverride", "", "# Thumbnails",
        "._*", "", "# Files that might appear on external disk", ".Spotlight-V100",
        ".Trashes", "", "# Directories potentially created on remote AFP share",
        ".AppleDB", ".AppleDesktop", "Network Trash Folder", "Temporary Items",
        ".apdisk", "",
        "## R related files", "*.Rdata", "*.Rhistory",
        ".Rproj.user*", ".Rproj.user"),
        file.path(path, name, ".gitignore"))
    writeLines(c("extras", "inst/doc", "\\.md", ".git*", ".DS_Store", ".*~",
        ".travis.yml", "^.*\\.Rproj$", "^\\.Rproj\\.user$"),
        file.path(path, name, ".Rbuildignore"))
    writeLines(c("language: r", "sudo: required"),
        file.path(path, name, ".travis.yml"))
    writeLines(c("# Auto detect text files and perform LF normalization", "* text=auto",
        "", "# Custom for Visual Studio", "*.cs     diff=csharp", "",
        "# Standard to msysgit", "*.doc    diff=astextplain", "*.DOC    diff=astextplain",
        "*.docx   diff=astextplain", "*.DOCX   diff=astextplain", "*.dot    diff=astextplain",
        "*.DOT    diff=astextplain", "*.pdf    diff=astextplain", "*.PDF    diff=astextplain",
        "*.rtf    diff=astextplain", "*.RTF    diff=astextplain"),
        file.path(path, name, ".gitattributes"))
    writeLines(c("Version: 1.0", "", "RestoreWorkspace: Default",
        "SaveWorkspace: Default",
        "AlwaysSaveHistory: Default", "", "EnableCodeIndexing: Yes",
        "UseSpacesForTab: Yes", "NumSpacesForTab: 4", "Encoding: UTF-8",
        "", "RnwWeave: knitr", "LaTeX: XeLaTeX", "", "AutoAppendNewline: Yes",
        "StripTrailingWhitespace: Yes", "", "BuildType: Package",
        "PackageUseDevtools: Yes",
        "PackageInstallArgs: --no-multiarch --with-keep.source"),
        file.path(path, name, paste0(name, ".Rproj")))
    cat("...oops, Read-and-delete-me is deleted...\n")
    invisible(NULL)
}

## usage
if (FALSE) {

project.skeleton("project_007")

}
