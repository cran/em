#' The em function for `panelmodel` such as `plm`.
#' @param object the model used, e.g. `lm`, `glm`, `gnm`, `plm`.
#' @param ... arguments used in the `model`.
#' @param latent the number of latent classes.
#' @param verbose `True` to print the process of convergence.
#' @param init.method the initialization method used in the model.
#' The default method is `random`.
#' @param max_iter the maximum iteration for em algorithm.
#' @param algo the algorithm used in em: the default EM algorithm,
#' the classification em `cem`, or the stochastic em `sem`.
#' @param concomitant the formula to define the concomitant part of the model.
#' The default is NULL.
#' @return An object of class `em` is a list containing at least the following components:
#'  \code{models} a list of models/objects whose class are determined by a model fitting from the previous step.  
#'  \code{pi} the prior probabilities.
#'  \code{latent} number of the latent classes.
#'  \code{algorithm} the algorithm used (could be either `em`, `sem` or `cem`).
#'  \code{obs} the number of observations.
#'  \code{post_pr} the posterior probabilities.
#'  \code{concomitant} a list of the concomitant model. It is empty if no concomitant model is used.
#'  \code{init.method} the initialization method used.
#'  \code{call} the matched call.
#'  \code{terms} the code{terms} object used.
#' @importFrom plm pmodel.response
#' @export
em.panelmodel <- function(object, latent = 2, verbose = FALSE,
                          init.method = c("random", "kmeans"),
                          algo = c("em", "cem", "sem"),
                          max_iter = 500, concomitant = list(...), ...) {
  if (!missing(...)) warning("extra arguments discarded")
  algo <- match.arg(algo)
  if (!("weights" %in% names(formals(match.fun(object$call[[1]]))))) {
    warning("The model cannot be weighted. Changed to `sem` instead.")
    algo <- "sem"
  }
  cl <- match.call()
  m <- match(c("call", "terms", "formula", "model", "y", "data", "x"), names(object), 0L)
  if (is.na(m[[1]])) {
    warning("There is no `call` for the model used.")
  } else if (is.na(m[[2]])) {
    warning("There is no `terms` for the model used.")
  } else {
    mt <- object[m]
  }
  # attr(mt$terms, ".Environment") <- environment() # attached to the current env
  if (is.null(mt$model)) {
    mf <- mt$call
    mm <- match(
      c("formula", "data", "subset", "weights", "na.action", "offset"),
      names(mf), 0L
    )
    mf <- mf[c(1L, mm)]
    mf[[1L]] <- quote(stats::model.frame)
    mf <- eval(mf, parent.frame())
    mt$model <- mf
  }
  nr <- nrow(mt$model)
  n <- length(levels(attr(mt$model, "index")[, 1]))
  mt$x <- model.matrix(mt$model)
  mt$y <- pmodel.response(mt$model)
  # mt$y <- as.double(mt$y[,2])


  ## load the concomitant model
  if (length(concomitant) != 0) {
    m.con <- match(
      c("formula", "data", "subset", "weights", "na.action", "offset"),
      names(concomitant), 0L
    )
    mf.con <- concomitant[m.con]
    mf.con$drop.unused.levels <- TRUE
    mf.con <- do.call(model.frame, mf.con)
    mt.con <- attr(mf.con, "terms")
  }
  #### TODO: use init.em for init_pr

  post_pr <- matrix(0, nrow = n, ncol = latent)
  class(post_pr) <- match.arg(init.method)
  post_pr <- init.em(post_pr, mt$x)
  # post_pr <- vdummy(sample(1:latent, size=n, replace=T))
  models <- list()
  for (i in 1:latent) {
    models[[i]] <- mt
  }
  results.con <- NULL
  cnt <- 0
  conv <- 1
  llp <- 0
  while ((abs(conv) > 1e-4) & (max_iter > cnt)) {
    pi_matrix <- matrix(colSums(post_pr) / nrow(post_pr),
      nrow = nrow(post_pr), ncol = ncol(post_pr),
      byrow = T
    )
    results <- mstep(models, post_pr = post_pr)
    if (length(concomitant) != 0) {
      if ("formula" %in% names(concomitant)) {
        results.con <- mstep.concomitant(concomitant$formula, mf.con, post_pr)
        pi_matrix <- results.con$fitted.values
      } else {
        stop("concomitant need to be a formula")
      }
    }
    pi <- colSums(pi_matrix) / sum(pi_matrix)
    post_pr <- estep(results, pi_matrix)
    if (algo == "cem") {
      post_pr <- cstep(post_pr)
    } else if (algo == "sem") {
      post_pr <- sstep(post_pr)
    }
    ll <- 0
    if (length(concomitant) == 0) {
      for (i in seq_len(length(results))) {
        if (pi[[i]] != 0) {
          ll <- ll + pi[[i]] * fit.den(results[[i]])
        }
      }
      ll <- sum(log(ll))
    } else {
      for (i in seq_len(length(results))) {
        if (any(!is.na(results[[i]]))) {
          ll <- ll + results.con$fitted.values[, i] * fit.den(results[[i]])
        }
      }
      ll <- sum(log(ll))
    }
    conv <- ll - llp
    llp <- ll
    if (verbose) {
      cat(paste0(
        "Iteration ", cnt, ": ",
        "(EM) log likelihood = ",
        round(ll, 4), "\n"
      ))
    }
    cnt <- cnt + 1
  }
  z <- list(
    models = results,
    pi = colSums(pi_matrix) / sum(pi_matrix),
    latent = latent,
    init.method = match.arg(init.method),
    call = cl,
    terms = mt$terms,
    algorithm = algo,
    obs = n,
    post_pr = estep(results, pi_matrix),
    concomitant = concomitant
  )
  if (length(concomitant) != 0) {
    z$results.con <- mstep.concomitant.refit(concomitant$formula, mf.con, post_pr)
    z$terms.con <- mt.con
  }
  class(z) <- c("em")
  return(z)
}
