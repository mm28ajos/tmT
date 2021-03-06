#' Read preprocessed files from Nexis Online
#'
#' Reads the HTML-files from preprocessed Lexis Nexis files and seperates the
#' text and meta data.
#'
#'
#' @param path Path where the data files are.
#' @param file Character string with names of the HTML files.
#' @param do.meta Logical: Should the algorithm collect meta data?
#' @param do.text Logical: Should the algorithm collect text data?
#' @return List of two \item{meta}{id topic nr from title source date releaseNote
#' downloadDate loadDate language length dateline byline section type pubType
#' series graphic copyright}
#' \item{text}{text}
#' @keywords manip
#' @examples
#'
#' @export readNexisOnline
#'
readNexisOnline <- function(path = getwd(),
                            file = list.files(path = path, pattern = "*.HTML$",
                                              full.names = FALSE, recursive = TRUE),
                            do.meta = TRUE, do.text = TRUE){
  stopifnot(is.character(file), is.character(path),
            is.logical(do.meta), is.logical(do.text),
            length(do.meta) == 1, length(do.text) == 1, length(path) == 1)
  text <- NULL
  meta <- NULL
  temp_time <- Sys.getlocale("LC_TIME")
  Sys.setlocale("LC_TIME", "C")
  for (i in 1:length(file)) {
    cat(paste(file[i]), "\n")
    article <- readLines(con = paste(path, file[i], sep="/"), warn = FALSE)
    # warn = FALSE because incomplete final line in files
    article <- gsub(pattern = "&nbsp;", replacement = "", article)
    article <- gsub(pattern = "&quot;", replacement = "\"", article)
    article <- gsub(pattern = "&amp;", replacement = "&", article)
    
    header <- grep(pattern = "<META", article, value = TRUE)
    
    style <- article[grep(pattern = "<STYLE", article):grep(pattern = "</STYLE>", article)]
    
    lines <- cbind(grep(pattern = "<DOCFULL>", article), grep(pattern = "</DOCFULL>", article))
    nr <- article[lines[, 1] + 1]
    source <- article[lines[, 1] + 3]
    date <- article[lines[, 1] + 5]
    copyright <- article[lines[, 2] - 3]
    article <- apply(lines, 1, function(x) paste(article[x[1]:x[2]], collapse = " "))
    n <- length(article)
    id <- paste("ID", paste(i, 1L:n, sep = "-"), sep = " ")
    
    if (do.meta) {
      # meta-data in header (identical for all documents in the same file):
      from <- stringr::str_extract(header, "DOCUMENTS=\"(.*?)\"")
      from <- as.integer(gsub(pattern = "DOCUMENTS=|\"", replacement = "", from))
      from <- rep(from, times = n)
      
      topic <- stringr::str_extract(header, "TOPIC=\"(.*?)\"")
      topic <- rep(gsub(pattern = "TOPIC=|\"", replacement = "", topic), times = n)
      topic <- ifelse(topic == "null", NA, topic)
      
      downloadDate <- stringr::str_extract(header, "UPDATED=\"(.*?)\"")
      downloadDate <- gsub(pattern = "UPDATED=|\"", replacement = "", downloadDate)
      downloadDate <- rep(as.Date(downloadDate, format = "%A, %B %d, %Y  %T"), times = n)
      
      # meta-data in each document:
      cand <- paste0(c("LOAD-DATE", "LANGUAGE", "LENGTH", "DATELINE", "BYLINE",
                       "SECTION","TYPE", "PUBLICATION-TYPE", "SERIES", "GRAPHIC"), ": ")
      cand_names <- c("loadDate", "language", "length", "dateline", "byline",
                      "section", "type", "pubType", "series", "graphic")
      mData <- NULL
      for(k in 1:length(cand)){
        mData_new <- stringr::str_extract(article, paste0(cand[k], "(.*?)</P>"))
        mData_new <- removeXML(gsub(pattern = cand[k], replacement = "", x = mData_new))
        mData <- cbind(mData, mData_new)
      }
      mData <- as.data.frame(mData, stringsAsFactors = FALSE)
      colnames(mData) <- cand_names
      mData$length <- as.integer(gsub(pattern = " words", replacement = "", mData$length))
      mData$loadDate <- as.Date(mData$loadDate, format = "%B %d, %Y")
      
      nr <- as.integer(removeXML(gsub(pattern = "of [0-9]{1,7} DOCUMENTS",
                                      replacement = "", x = nr)))
      source <- removeXML(source)
      date <- removeXML(date)
      releaseNote <- trimws(gsub(pattern = "(.*?) [1-9][0-9]{0,5}, [12][0-9]{3},? [MFSTW][a-z]{2,5}day,?",
                                 replacement = "", x = date))
      releaseNote <- ifelse(releaseNote == "", NA, releaseNote)
      date <- as.Date(stringr::str_extract(date, "(.*?) [1-9][0-9]{0,5}, [12][0-9]{3}"),
                      format = "%B %d, %Y")
      copyright <- removeXML(copyright)
      
      titlestyle <- character(4)
      titlestyle[1] <- grep(pattern = " \\{ text-align: left; \\}", style, value = TRUE)
      titlestyle[2] <- grep(pattern = " \\{ text-align: left; margin-top: 0em; margin-bottom: 0em; \\}", style, value = TRUE)
      titlestyle[3] <- grep(pattern = " \\{ font-family: Arial; font-size: 14pt; font-style: normal; font-weight: bold; color: \\#000000; text-decoration: none; \\}", style, value = TRUE)
      temp <- grep(pattern = " \\{ font-family: Arial; font-size: 14pt; font-style: normal; font-weight: bold; color: \\#CC0033; text-decoration: none; \\}", style, value = TRUE)
      titlestyle[4] <- ifelse(length(temp > 0), temp , "")
      titlestyle <- gsub(pattern = " \\{(.*?) \\}|\\.c", replacement = "", titlestyle)
      titlestyle <- paste0("<BR><DIV CLASS=\"c", titlestyle[1], "\"><P CLASS=\"c", titlestyle[2],
                           "\"><SPAN CLASS=\"c(", titlestyle[3],"|", titlestyle[4], ")\">")
      title <- stringr::str_extract(article, paste0(titlestyle, "(.*?)</DIV>"))
      title <- removeXML(title)
      
      mData <- cbind(id, topic, nr, from, title, source, date, releaseNote,
                     downloadDate, mData, copyright, stringsAsFactors = FALSE)
      meta <- rbind(meta, mData)
    }
    if (do.text) {
      textstyle <- character(5)
      textstyle[1] <- grep(pattern = " \\{ text-align: left; \\}", style, value = TRUE)
      textstyle[2] <- grep(pattern = " \\{ text-align: left; margin-top: 0em; margin-bottom: 0em; \\}", style, value = TRUE)
      textstyle[3] <- grep(pattern = " \\{ text-align: left; margin-top: 1em; margin-bottom: 0em; \\}", style, value = TRUE)
      textstyle[4] <- grep(pattern = " \\{ font-family: Arial; font-size: 10pt; font-style: normal; font-weight: normal; color: \\#000000; text-decoration: none; \\}", style, value = TRUE)
      temp <- grep(pattern = " \\{ font-family: Arial; font-size: 10pt; font-style: normal; font-weight: bold; color: \\#CC0033; text-decoration: none; \\}", style, value = TRUE)
      textstyle[5] <- ifelse(length(temp > 0), temp , "")
      textstyle <- gsub(pattern = " \\{(.*?) \\}|\\.c", replacement = "", textstyle)
      textstyle <- paste0("<BR><DIV CLASS=\"c", textstyle[1], "\">(<BR>)?<P CLASS=\"c(", textstyle[2], "|",
                          textstyle[3], ")\">(<BR>)?<SPAN CLASS=\"c(", textstyle[4],"|", textstyle[5], ")\">")
      
      text_new <- stringr::str_extract(article, paste0(textstyle, "(.*?)</DIV>"))
      
      text_new <- removeXML(text_new)
      names(text_new) <- id
      text <- as.list(c(text, text_new))
    }
  }
  Sys.setlocale("LC_TIME", temp_time)
  res <- list(meta = meta, text = text, metamult = NULL)
  class(res) <- "textmeta"
  if (do.text) res <- deleteAndRenameDuplicates(res, paragraph = FALSE)
  summary(res)
}
