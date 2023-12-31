#' maskFromBSGenome
#' 
#' @description 
#' Extracts the merge of all the active masks from a \code{\link{BSgenome}}
#'
#' @note
#' This function is memoised (cached) using the \code{\link{memoise}} package. To empty the cache, use \code{\link{forget}(maskFromBSGenome)}
#' 
#' @usage maskFromBSGenome(bsgenome)
# @usage maskFromBSGenome(...) 
#' 
#' @param bsgenome a \code{\link{BSgenome}} object
#' 
#' @return
#' A \code{\link{GRanges}} object with the active mask in the \code{\link{BSgenome}}
#' 
#' @seealso \code{\link{getGenomeAndMask}}, \code{\link{characterToBSGenome}}, \code{\link{emptyCacheRegioneR}}
#' 
#' @examples
#' g <- characterToBSGenome("hg19")
#' 
#' maskFromBSGenome(g)
#' 
#' @export maskFromBSGenome
#' 
#' @importFrom Biostrings masks collapse
#' @importFrom S4Vectors Rle

maskFromBSGenome <- memoise::memoise(function(bsgenome) {
  
  
  if(!methods::hasArg(bsgenome)) stop("parameter bsgenome is required")
  if(!methods::is(bsgenome, "BSgenome")) stop("bsgenome must be a BSGenome object")
  
  if(!methods::is(bsgenome, "MaskedBSgenome")) {
    warning("bsgenome is not a MaskedBSgenome. Returning an empty mask.")
    return(GenomicRanges::GRanges())
  }
  
  
  #WARNING: This is ugly. Since I have not found a way to extract the positions 
  #of the masks from a BSGenome object in a simple way,
  # we are doing it by iterating over the chromosomes
  
  #get the chromosome names using the getGenomes function, so we get exactly the same chromosomes
  chrs <- as.character(GenomicRanges::seqnames(getGenome(bsgenome)))
  
  
  chr.masks <- sapply(chrs, function(chr) {
                                      mm <- Biostrings::masks(bsgenome[[chr]])
                                      if(is.null(mm)) {
                                        return(NULL)
                                      } else {
                                        mm <- Biostrings::collapse(mm)[[1]]
                                        return(mm)
                                      }})
  
  if(do.call(all, lapply(chr.masks, is.null))) { #If the mask is null for all chromosomes, rise a warning and return an empty GRanges
    warning("No mask is active for this BSgenome. Returning an empty mask.")
    return(GenomicRanges::GRanges())
  }
  
  
  chr.masks <- sapply(chrs, function(chr) {
                                  if(is.null(chr.masks[[chr]])) {
                                    return(NULL)
                                  } else {
                                    return(GenomicRanges::GRanges(seqnames=S4Vectors::Rle(rep(chr, length(chr.masks[[chr]]))), ranges=chr.masks[[chr]], seqinfo = seqinfo(bsgenome)))
                                  }
                                })
  
  #Combine the mask for each chromosome into a single mask
  mask <- GenomicRanges::GRanges(seqinfo = seqinfo(bsgenome))
  for(chr in chrs) {
    if(!is.null(chr.masks[[chr]])) {
      suppressWarnings(mask <- c(mask, chr.masks[[chr]]))
    }
  }

  return(mask)
})

