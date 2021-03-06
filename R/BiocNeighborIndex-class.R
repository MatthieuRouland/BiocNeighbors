#' The BiocNeighborIndex class
#'
#' A virtual class for indexing structures of different nearest-neighbor search algorithms.
#' 
#' @details
#' The BiocNeighborIndex class is a virtual base class on which other index objects are built.
#' There are 4 concrete subclasses:
#' \describe{
#'     \item{}{\code{\link{KmknnIndex}}: exact nearest-neighbor search with the KMKNN algorithm.}
#'     \item{}{\code{\link{VptreeIndex}}: exact nearest-neighbor search with a VP tree.}
#'     \item{}{\code{\link{AnnoyIndex}}: approximate nearest-neighbor search with the Annoy algorithm.}
#'     \item{}{\code{\link{HnswIndex}}: approximate nearest-neighbor search with the HNSW algorithm.}
#' }
#' 
#' These objects hold indexing structures for a given data set - see the associated documentation pages for more details.
#' It also retains information about the input data as well as the sample names.
#' 
#' @section Methods:
#' In the following code snippets, \code{x} and \code{object} are BiocNeighborIndex objects.
#' 
#' The main user-accessible methods are:
#' \describe{
#'     \item{\code{show(object)}:}{Display the class and dimensions of \code{object}.}
#'     \item{\code{dim(x)}:}{Return the dimensions of \code{x}, in terms of the matrix used to construct it.}
#'     \item{\code{dimnames(x)}:}{Return the dimension names of \code{x}.
#'         Only the row names of the input matrix are stored, in the same order.
#'     }
#'     \item{\code{x[[i]]}:}{Return the value of slot \code{i}, as used in the constructor for \code{x}.}
#' }
#' 
#' More advanced methods (intended for developers of other packages) are:
#' \describe{
#'     \item{\code{bndata(object)}:}{Return a numeric matrix containing the data used to construct \code{object}.
#'         Each column should represent a data point and each row should represent a variable 
#'         (i.e., it is transposed compared to the usual input, for efficient column-major access in C++ code).
#'         Columns may be reordered from the input matrix according to \code{bnorder(object)}.
#'     }
#'     \item{\code{bnorder(object)}:}{Return an integer vector specifying the new ordering of columns in \code{bndata(object)}.
#'         This generally only needs to be considered if \code{raw.index=TRUE}, see \code{?"\link{BiocNeighbors-raw-index}"}.
#'     }
#'     \item{\code{bndistance(object)}:}{Return a string specifying the distance metric to be used for searching, usually \code{"Euclidean"} or \code{"Manhattan"}.
#'         Obviously, this should be the same as the distance metric used for constructing the index.
#'     }
#' }
#' 
#' @seealso
#' \code{\link{KmknnIndex}},
#' \code{\link{VptreeIndex}},
#' \code{\link{AnnoyIndex}},
#' and \code{\link{HnswIndex}} for direct constructors.
#' 
#' \code{\link{buildIndex}} for construction on an actual data set. 
#' 
#' \code{\link{findKNN}} and \code{\link{queryKNN}} for dispatch.
#' 
#' @author
#' Aaron Lun
#'
#' @aliases
#' BiocNeighborIndex-class
#' show,BiocNeighborIndex-method
#' dim,BiocNeighborIndex-method
#' dimnames,BiocNeighborIndex-method
#'
#' bndata
#' bndata,BiocNeighborIndex-method
#'
#' bndistance
#' bndistance,BiocNeighborIndex-method
#'
#' bnorder
#' [[,BiocNeighborIndex-method
#'
#' @docType class
#' @name BiocNeighborIndex
NULL

#' @export
#' @importFrom methods show 
setMethod("show", "BiocNeighborIndex", function(object) {
    cat(sprintf("class: %s\n", class(object)))
    cat(sprintf("dim: %i %i\n", nrow(object), ncol(object)))
    cat(sprintf("distance: %s\n", bndistance(object)))
})

#' @export
setMethod("bndistance", "BiocNeighborIndex", function(x) x@distance)

#' @export
setMethod("dimnames", "BiocNeighborIndex", function(x) {
    list(x@NAMES, NULL)
})

#' @export
setMethod("bndata", "BiocNeighborIndex", function(x) x@data)

#' @export
setMethod("dim", "BiocNeighborIndex", function(x) rev(dim(bndata(x))) ) # reversed, as matrix was transposed.

#' @importFrom S4Vectors setValidity2
setValidity2("BiocNeighborIndex", function(object) {
    msg <- character(0) 

    NAMES <- rownames(object)
    if (!is.null(NAMES) && length(NAMES)!=nrow(object)) {
        msg <- c(msg, "length of non-NULL 'NAMES' is not equal to the number of rows")
    }

    if (length(bndistance(object))!=1L) {
        msg <- c(msg, "'distance' must be a string")
    }
    
    if (length(msg)) return(msg)
    return(TRUE)
})

#' @export
setMethod("[[", "BiocNeighborIndex", function(x, i, j, ...) {
    # Provides a layer of protection that we can use to update
    # the object or intercept slot queries if the class changes.
    slot(x, i)
})
