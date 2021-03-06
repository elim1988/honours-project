copyInline <- function(line) {
    # NOTE that the regular expression below is the "official"
    # pattern for knitr inline R code (all_patterns$html$inline.code)
    temp <- gsub("<!--\\s*rinline", "<!--keep.rinline", line)
    paste(line, temp, sep = "")
}

processRinline <- function(line) {
    mark <- gsub("(<!--rinline(.+?)-->)", "~MARKER~\\1~MARKER~", line)
    temp <- unlist(strsplit(mark, "~MARKER~"))
    lines <- grep("<!--rinline", temp)
    for (i in 1:length(lines)) {
        temp[lines][i] <- copyInline(temp[lines][i])
    }
    result <- paste(temp, collapse = "")
    result
}


sew <- function(infile = NULL, outfile = NULL) {
    if (is.null(infile)) {
        infile <- load.dir()
    }
    if (!grepl("Rhtml$", infile) & !grepl("std.Rmd$", infile))
        stop("infile must be an Rhtml or std.Rmd file")
    src <- readLines(infile)
    
    ########################## inline R code chunks ###########################
    in.line <- grep("<!--\\s*rinline", src)
    for (i in 1:length(in.line)) {
        src[in.line][i] <- processRinline(src[in.line][i])
    }
    
    ############### generate a list of R code chunks to "keep" ################
    R.begin <- grep("^.*<!--\\s*begin.rcode", src)
    R.end <- grep("^.*end.rcode-->$", src)
    
    if (length(R.begin) != length(R.end)) {
        stop ('Number of "begin.rcode" and "end.rcode" lines do not match')
    }
    
    keep.list <- vector("list", length(R.begin))
    for(i in 1:length(R.begin)) {
        keep.list[[i]] <- src[R.begin[i]:R.end[i]]
        last <- length(keep.list[[i]])
        # Change the first AND last lines.
        newLines <- gsub("[.]r", ".keep", keep.list[[i]][c(1,last)])
        keep.list[[i]][c(1,last)] <- newLines
    }
    
    ############################ write post.Rhtml #############################
    for (i in length(R.end):1) {
        src <- append(src, keep.list[[i]], after = R.end[i])
    }
    
    #----- for std.Rmd files -----#
    if (grepl("std.Rmd$", infile)) {
        # replace Rhtml syntax with Rmd syntax
        src <- gsub("<!--begin.rcode", "```", src)
        src <- gsub("end.rcode-->", "```", src)
        src <- gsub("<!-- metadata", "---", src)
        src <- gsub("metadata -->", "---", src)
        src <- gsub("(<!--rinline)(.+)(-->+?)", "`r\\2`", src)
    }
    
    if (is.null(outfile)) {
        if (grepl("Rhtml$", infile)) {
            outfile <- gsub("Rhtml$", "post.Rhtml", infile)
        } else {
            outfile <- gsub("std.Rmd$", "post.Rmd", infile)
        }    
    }
    writeLines(src, outfile)
}
