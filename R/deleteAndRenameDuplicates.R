#' Delete And Rename Articles with the same ID
#'
#' Deletes Articles with the same ID and same text. Renames the ID of Articles
#' with the same ID but different text-component (_IDFakeDup, _IDRealDup).
#'
#' @param object A textmeta-object as a result of a read-function.
#' @param paragraph Logical: Should be set to \code{TRUE} if the article is a
#' list of character strings, representing the paragraphs.
#' 
#' @export deleteAndRenameDuplicates
#'

# 1. Artikel-IDs, deren IDs gleich, der Text aber unterschiedlich ist
#     -> hier _IDFakeDup1 ... _IDFakeDupn anhaengen
#    (hier keine Option fuer gleiche Meta-Daten, da Text unterschiedlich,
#     also sind gleiche Meta-Daten nicht zu erwarten)
# 2. Artikel mit identischer ID und Text (aber unterschiedlichen Meta-Daten)
#     -> hier _IDRealDup1 ... _IDRealDupn anheangen
# 3. Artikel mit komplett identischen ID, Text, Meta werden geloescht!!


deleteAndRenameDuplicates <- function(object, paragraph = FALSE){
  stopifnot(is.textmeta(object), is.logical(paragraph), length(paragraph) == 1)
  
  if (is.null(object$meta)){ #if do.meta == FALSE:
    ind <- which(duplicated(names(object$text)) | duplicated(names(object$text),
                                                             fromLast = TRUE))
    if (length(ind) < 1) return(object)
    if (paragraph == TRUE){
      textvek <- unlist(lapply(object$text[ind], paste, collapse = " "))
    }
    else textvek <- unlist(object$text[ind])
    # Delete duplicates of ID !and! text:
    to_del <- ind[duplicated(textvek)]
    if (length(to_del) > 0){
      cat(paste("Delete Duplicates:", length(to_del)))
      object$text <- object$text[-to_del]
      cat("  next Step\n")
    }
    # Rename if text differs:
    to_rename <- which(duplicated(names(object$text)) | duplicated(names(object$text),
                                                                   fromLast = TRUE))
    if (length(to_rename) > 0){
      ind_loop = logical(length(names(object$text)))
      ind_loop[to_rename] = TRUE
      cat(paste("Rename Fake-Duplicates:", length(to_rename)))
      for (i in na.omit(unique(names(object$text)[to_rename]))){
        to_rename_loop <- (names(object$text) == i) & ind_loop
        to_rename_loop[is.na(to_rename_loop)] <- FALSE
        names(object$text)[to_rename_loop] <- paste0(names(object$text)[to_rename_loop],
                                                     "_IDFakeDup", 1:sum(to_rename_loop))
      }
      cat("  next Step\n")
    }
    cat("Success\n")
    return(object)
  }
  # Ansonsten existieren text und meta:
  # 3. Artikel mit komplett identischen ID, Text, Meta werden geloescht:
  ind <- which(duplicated(names(object$text)) | duplicated(names(object$text),
                                                           fromLast = TRUE))
  if (length(ind) < 1){
    cat("Success\n")
    return(object)
  }
  if (paragraph == TRUE){
    textvek <- unlist(lapply(object$text[ind], paste, collapse = " "))
  }
  else textvek <- unlist(object$text[ind])
  to_del <- ind[duplicated(object$meta[ind,]) & duplicated(textvek)]
  if (length(to_del) > 0){
    cat(paste("Delete Duplicates:", length(to_del)))
    object$text <- object$text[-to_del]
    object$meta <- object$meta[-to_del,]
    object$metamult <- object$metamult[-to_del]
    cat("  next Step\n")
    ind <- which(duplicated(names(object$text)) | duplicated(names(object$text),
                                                             fromLast = TRUE))
  }
  
  # 2. Artikel mit identischer ID und Text (aber unterschiedlichen Meta-Daten):
  if (length(ind) < 1){
    cat("Success\n")
    return(object)
  }
  if (paragraph == TRUE){
    textvek <- unlist(lapply(object$text[ind], paste, collapse = " "))
  }
  else textvek <- unlist(object$text[ind])
  text_same <- duplicated(textvek) | duplicated(textvek, fromLast = TRUE)
  to_rename <- ind[text_same]
  if (length(to_rename) > 0){
    ind_loop = logical(length(names(object$text)))
    ind_loop[to_rename] = TRUE
    cat(paste("Rename Real-Duplicates:", length(to_rename)))
    for (i in na.omit(unique(names(object$text)[to_rename]))){
      to_rename_loop <- names(object$text) == i & ind_loop
      to_rename_loop[is.na(to_rename_loop)] <- FALSE
      new_ids <- paste0(names(object$text)[to_rename_loop], "_IDRealDup",
                        1:sum(to_rename_loop))
      names(object$text)[to_rename_loop] <- new_ids
      object$meta$id[to_rename_loop] <- new_ids
      if (!is.null(object$metamult))
        names(object$metamult)[to_rename_loop] <- new_ids
    }
    cat("  next Step\n")
  }
  
  # 1. Artikel-IDs, deren IDs gleich, der Text aber unterschiedlich ist:
  to_rename <- ind[!text_same]
  if (length(to_rename) < 1){
    cat("Success\n")
    return(object)
  }
  ind_loop = logical(length(names(object$text)))
  ind_loop[to_rename] = TRUE
  cat(paste("Rename remaining Fake-Duplicates:", length(to_rename)))
  for (i in na.omit(unique(names(object$text)[to_rename]))){
    to_rename_loop <- names(object$text) == i & ind_loop
    to_rename_loop[is.na(to_rename_loop)] <- FALSE
    new_ids <- paste0(names(object$text)[to_rename_loop], "_IDFakeDup",
                      1:sum(to_rename_loop))
    names(object$text)[to_rename_loop] <- new_ids
    object$meta$id[to_rename_loop] <- new_ids
    if (!is.null(object$metamult))
      names(object$metamult)[to_rename_loop] <- new_ids
  }
  cat("  Success\n")
  return(object)
}