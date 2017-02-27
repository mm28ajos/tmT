#' Subcorpus With Word Filter
#'
#' Creates a subcorpus including specific words.
#'
#'
#' @param text List of article texts
#' @param wordlist List of character vectors. Every List element is an 'or'
#' link, every character String in a vector is linked by an 'and'. If
#' \code{wordlist} is only a character Vector the link is 'or'.
#' @param counts Integer, or same list structure like \code{wordlist}. Number
#' of times a word must appear to be counted.
#' @param ignore.case Option from \code{\link{grepl}}.
#' @param perl Option from \code{\link{grepl}}.
#' @param fixed Option from \code{\link{grepl}}.
#' @param useBytes Option from \code{\link{grepl}}.
#' @param out Type of output: \code{text} filtered corpus, \code{bin} logical vector for all texts, \code{count} the number of matches (max one match per character string).
#' @param ... additional parameters for \code{grepl}
#' @return Filtered list of texts.
#' @keywords ~kwd1 ~kwd2
#' @examples
#'
#' ##---- Should be DIRECTLY executable !! ----
#' @export subcorpusWord
subcorpusWord <- function(text, wordlist, counts = 1L, ignore.case = FALSE,
                          perl = FALSE, fixed = FALSE, useBytes = FALSE,
                          out = c("text", "bin", "count"), ...){
    stopifnot((is.list(text) || is.character(text)),
              all(sapply(wordlist, is.character)),
              all(sapply(counts, is.numeric)),
              all.equal(unlist(sapply(counts, as.integer)), unlist(counts)),
              is.logical(ignore.case), is.logical(perl), is.logical(fixed),
              is.logical(useBytes), length(ignore.case) == 1, length(perl) == 1,
              length(fixed) == 1, length(useBytes) == 1, is.character(out))
    subid <- numeric(length(text))

    if(out[1] == "count"){
        tmp <- NULL
        for(j in wordlist){
            tmp <- cbind(tmp, sapply(text, function(x)
                sum(grepl(pattern = j, x = x, ignore.case = ignore.case, perl = perl,
                          fixed = fixed, useBytes = useBytes, ...))))
        }
        colnames(tmp) <- wordlist
        return(tmp)
    }else{
        if(!is.list(wordlist)){wordlist <- list(wordlist)}
        if(!is.list(counts)){counts <- list(counts)}
        if(length(counts) == 1L){counts[1:length(wordlist)] <- counts[1]}

        for(i in 1:length(wordlist)){
            tmp <- NULL
            for(j in 1:length(wordlist[[i]])){
                if(length(counts[[i]]) == 1){co <- counts[[i]]}
                else{co <- counts[[i]][j]}
                tmp <- cbind(tmp, sapply(text, function(x)
                    sum(grepl(pattern = wordlist[[i]][j], x = x, ignore.case = ignore.case,
                              perl = perl, fixed = fixed, useBytes = useBytes)) >= co))
            }
            subid <- subid + apply(tmp, 1, prod)
        }
        subid <- subid>0
        if(out[1] == "text"){
            return(text[subid])}
        if(out[1] == "bin"){
            return(subid)}
    }
}