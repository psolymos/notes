if (.Platform$OS.type != "windows") {
  aspell_pkg <-
    function(pkg,
             path = "~/repos",
             prog = "hunspell")
  {
      f_R <- Sys.glob(file.path(path, pkg, "R/*.R"))
      f_Rd <- Sys.glob(file.path(path, pkg, "man/*.Rd"))
      x_R <- utils:::aspell(f_R, program=prog, filter="R")
      x_Rd <- utils:::aspell(f_Rd, program=prog, filter="Rd")
      if (length(x_R[[1]]) > 0) {
          x_R$Suggestions <- sapply(x_R$Suggestions, paste, collapse=" ")
          df_R <- data.frame(Package=pkg, Subdir="R", as.data.frame(x_R))
      } else {
          df_R <- NULL
      }
      if (length(x_Rd[[1]]) > 0) {
          x_Rd$Suggestions <- sapply(x_Rd$Suggestions, paste, collapse=" ")
          df_Rd <- data.frame(Package=pkg, Subdir="Rd", as.data.frame(x_Rd))
      } else {
          df_Rd <- NULL
      }
      out <- rbind(df_R, df_Rd)
      write.csv(out,
          file = file.path(path, paste0(pkg, ".Rcheck"),
          paste0(pkg, "_aspell.csv")), row.names = FALSE)
      invisible(NULL)
  }
  aspell_pkg(pkg = commandArgs(trailingOnly = TRUE)[1])
}
q("no")
