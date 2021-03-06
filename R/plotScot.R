#' Plotting Counts of Documents or Words over Time (relative to Corpus)
#' 
#' Creates a plot of the counts/proportion of documents/words in the subcorpus,
#' which could be specified by \code{id}.
#' 
#' @param object \code{\link{textmeta}} object - with strictly tokenized
#' \code{text} component (\code{character} vectors) if \code{type = "words"}
#' @param id \code{character} vector (default: \code{object$meta$id}) which IDs
#' specify the subcorpus
#' @param type \code{character} (default: \code{"docs"}) should counts/proportion
#' of documents \code{"docs"} or words \code{"words"} be plotted
#' @param rel \code{logical} (default: \code{FALSE}) should counts
#' (\code{FALSE}) or proportion (\code{TRUE}) be plotted
#' @param mark \code{logical} (default: \code{TRUE}) should years be marked by
#' vertical lines
#' @param unit \code{character} (default: \code{"month"}) to which unit should
#' dates be floored
#' @param curves \code{character} (default: \code{"exact"}) should \code{"exact"},
#' \code{"smooth"} curve or \code{"both"} be plotted
#' @param smooth \code{numeric} (default: \code{0.05}) smoothing parameter
#' which is handed over to \code{\link{lowess}} as \code{f}
#' @param both.lwd graphical parameter for smoothed values if \code{curves = "both"}
#' @param both.col graphical parameter for smoothed values if \code{curves = "both"}
#' @param both.lty graphical parameter for smoothed values if \code{curves = "both"}
#' @param main \code{character} graphical parameter
#' @param xlab \code{character} graphical parameter
#' @param ylim (default if \code{rel = TRUE}: \code{c(0, 1)}) graphical parameter
#' @param natozero \code{logical} (default: \code{TRUE}) should NAs be coerced
#' to zeros. Only has effect if \code{rel = TRUE}.
#' @param ... additional graphical parameters 
#' @return A plot.
#' Invisible: A dataframe with columns \code{date} and \code{counts},
#' respectively \code{proportion}
#' @keywords ~kwd1 ~kwd2
#' @examples ##
#' @export plotScot

plotScot <- function(object, id = object$meta$id, type = c("docs", "words"),
  rel = FALSE, mark = TRUE, unit = "month", curves = c("exact", "smooth", "both"),
  smooth = 0.05, main, xlab, ylim, both.lwd, both.col, both.lty,
  natozero = TRUE, ...){
  
  stopifnot(is.textmeta(object), is.character(id), is.logical(rel),
    is.logical(mark), length(rel) == 1, length(mark) == 1, is.character(unit),
    length(unit) == 1, all(type %in% c("docs", "words")),
    all(curves %in% c("exact", "smooth", "both")), is.numeric(smooth),
    length(smooth) == 1)
  # set x-label if missing
  if (missing(xlab)) xlab <- "date"
  # match id with id which appears in object$text
  if (type[1] == "words"){
    id <- names(object$text)[names(object$text) %in% id]
    insert <- "words"
  }
  else insert <- "documents"
  # generate x-values date (non-unique at this point)
  dates <- lubridate::floor_date(
    object$meta$date[match(id, object$meta$id)], unit)
  # generate markers on every beginning year
  if (mark) markYears <- seq(from = lubridate::floor_date(
    min(dates, na.rm = TRUE), unit = "year"), to = lubridate::ceiling_date(
      max(dates, na.rm = TRUE), unit = "year"), by = "year")
  else markYears <- NA
  # compute counts (of words/documents)
  if (type[1] == "words"){
    docLengths <- lengths(object$text[match(id, names(object$text))])
    counts <- sapply(split(docLengths, dates), sum)
  }
  else counts <- table(dates)
  
  if (rel){
    # compute normalisation
    if (type[1] == "words"){
      allDates <- lubridate::floor_date(
        object$meta$date[match(names(object$text), object$meta$id)], unit)
      allCounts <- sapply(split(lengths(object$text), allDates), sum)
    }
    else{
      allDates <- lubridate::floor_date(object$meta$date, unit)
      allCounts <- table(allDates)
    }
    # compute proportions
    proportion <- counts[match(names(allCounts), names(counts))] / allCounts
    # some preparation for plotting
    dateNames <- as.Date(names(allCounts))
    proportion <- as.vector(proportion)
    proportion[is.na(proportion)] <- 0
    # set main and ylim if missing
    if (missing(main)) main <- paste("Proportion of", insert, "over time")
    if (missing(ylim)) ylim <- c(0, 1)
    tab = data.frame(date = dateNames, proportion = proportion)
  }
  else{
    # some preparation for plotting
    dateNames <- as.Date(names(counts))
    counts <- as.vector(counts)
    # set main if missing
    if (missing(main)) main <- paste("Count of", insert, "over time")
    if (missing(ylim)) ylim <- c(0, max(counts))
    tab = data.frame(date = dateNames, counts = counts)
  }
  levs <-
    unique(lubridate::floor_date(
      seq(from = min(tab$date), to = max(tab$date), by = "day"), unit = unit))
  zerosToAdd <- !(levs %in% tab$date)
  if(any(zerosToAdd)){
    # add NA for proportion or zero for counts
    zerosToAdd <- data.frame(levs[zerosToAdd], ifelse(rel, NA, 0))
    names(zerosToAdd) <- names(tab)
    tab <- rbind(tab, zerosToAdd)
  }
  tab <- tab[order(tab$date),]
  if(natozero) tab[is.na(tab)] <- 0
  row.names(tab) <- 1:nrow(tab)
  if (curves[1] %in% c("exact", "both")){
    plot(tab, type = "l", main = main, xlab = xlab, ylim = ylim, ...)
    if (curves[1] == "both"){
      if (missing(both.lwd)) both.lwd <- 1
      if (missing(both.col)) both.col <- "red"
      if (missing(both.lty)) both.lty <- 1
      lines(lowess(tab, f = smooth), type = "l",
        lwd = both.lwd, col = both.col, lty = both.lty)
    }
  }
  else{
    tab2 <- data.frame(date = tab$date, values = lowess(tab, f = smooth)$y)
    colnames(tab2) <- colnames(tab)
    plot(tab2, type = "l", main = main, xlab = xlab, ylim = ylim, ...)
  }
  abline(v = markYears, lty = 3)
  invisible(tab)
}
