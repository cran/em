#' Initialization of EM algorithm
#' @description Given a matrix with number of rows equal to the number of
#' observation and number of columns equal to the number of latent classes,
#' function `init.em` generate the posterior probability using that matrix
#' based on the method set by the user.
#' @param object A matrix.
#' @param ... other used arguments.
#' @return The posterior probability matrix
#' @importFrom "stats" "aggregate" "rlnorm" "runif" "binomial" "optim"
#' @export
init.em <- function(object, ...) {
  if (!is.matrix(object)) {
    stop("The object should be a matrix!")
  }
  UseMethod("init.em")
}

#' Random initialization
#' @param object A matrix.
#' @param ... other used arguments.
#' @return The posterior probability matrix
init.em.random <- function(object, ...) {
  args <- list()
  if (!missing(...)) {
    args <- list(...)
  }
  z <- vdummy(sample(seq_len(ncol(object)), size = nrow(object), replace = TRUE, prob = args$init.prob))
  z
}

#' Random initialization with weights
#' @param object A matrix.
#' @param ... other used arguments.
#' @return The posterior probability matrix
init.em.random.weights <- function(object, ...) {
  args <- list()
  if (!missing(...)) {
    args <- list(...)
  }
  z <- apply(object, 2, function(x) {
    runif(x, min = 0.001, max = 1)
  })
  z <- t(apply(z, 1, function(x) {
    x / sum(x)
  }))
  z
}

#' K-mean initialization
#' @param object A matrix.
#' @param ... other used arguments.
#' @return The posterior probability matrix
init.em.kmeans <- function(object, ...) {
  if (!missing(...)) {
    args <- list(...)
  }
  if (is.null(args$data)) {
    stop("Please provide the data")
  }
  # args$data[is.na(args$data)] <- 0
  z <- suppressWarnings(vdummy(kmeans(args$data, centers = ncol(object), nstart = 20, algorithm = "Lloyd")$cluster))
  z
}

#' model-based agglomerative hierarchical clustering
#' @param object A matrix.
#' @param ... other used arguments.
#' @return The posterior probability matrix
init.em.hc <- function(object, ...) {
  if (!missing(...)) {
    args <- list(...)
  }
  if (is.null(args$data)) {
    stop("Please provide the data")
  }
  # browser()
  z <- vdummy(mclust::hclass(mclust::hcEII(args$data), 2))
  z
}

#' Initialization using sampling 5 times.
#' @param object A matrix.
#' @param ... other used arguments.
#' @return The posterior probability matrix
init.em.sample5 <- function(object, ...) {
  args <- list()
  if (!missing(...)) {
    args <- list(...)
  }
  z <- vdummy(sample(seq_len(ncol(object)), size = nrow(object), replace = TRUE, prob = args$init.prob))
  z
}
