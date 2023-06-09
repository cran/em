% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/em.R
\name{em}
\alias{em}
\title{A Generic EM Algorithm}
\usage{
em(object, ...)
}
\arguments{
\item{object}{the model used, e.g. `lm`, `glm`, `gnm`, `clogit`, `multinom`}

\item{...}{arguments used in the `model`.}
}
\value{
An object of class `em` is a list containing at least the following components:
 \code{models} a list of models/objects whose class are determined by a model fitting from the previous step.  
 \code{pi} the prior probabilities.
 \code{latent} number of the latent classes.
 \code{algorithm} the algorithm used (could be either `em`, `sem` or `cem`).
 \code{obs} the number of observations.
 \code{post_pr} the posterior probabilities.
 \code{concomitant} a list of the concomitant model. It is empty if no concomitant model is used.
 \code{init.method} the initialization method used.
 \code{call} the matched call.
 \code{terms} the code{terms} object used.
}
\description{
This is a generic EM algorithm that can work on specific models/objects.
Currently, it supports `lm`, `glm`, `gnm` in package gnm,
`clogit` in package survival and `multinom` in package nnet.
Use `?em.default` to check the manual of the default function of `em`.
}
\examples{

fit.lm <- lm(yn ~ x, data = simreg)
results <- em(fit.lm, latent = 2, verbose = FALSE) 
fmm_fit <- predict(results)
fmm_fit_post <- predict(results, prob = "posterior")

}
\author{
Dongjie Wu
}
