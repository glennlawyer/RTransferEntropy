#' Function to implement Renyi transfer entropy.
#'
#' @param x a vector of coded values
#' @param lx Markov order of x
#' @param y a vector of coded values
#' @param ly Markov order of y
#' @param q weighting parameter in Renyi transfer entropy
#' @param const if TRUE, then shuffle is constant for all bootstraps
#' @param constx constant value substracted from transfer entropy measure
#' @param consty constant value substracted from transfer entropy measure
#' @param shuffle if TRUE, shuffled transfer entropy is calculated
#' @param nreps number of replications for each shuffle
#' @param shuffles number of shuffles
#' @param ncores number of cores in parallel computation
#' @param type bins, limits or quantiles of empirical distribution to discretize
#' the data
#' @param quantiles quantiles to use for discretization
#' @param bins the number of bins with equal width used for discretization
#' @param limits limits used for discretization
#' @param boots number of bootstrap samples
#' @param nboot number of bootstrap replications
#' @param burn number of observations that are dropped from the beginning of
#' the bootstrapped Markov chain
#'
#' @return returns a list
#' @keywords internal
#' @export
#'
#' @examples
#'
te_renyi <- function(x,
                                   lx,
                                   y,
                                   ly,
                                   q,
                                   shuffle = TRUE,
                                   const = FALSE,
                                   constx = 0,
                                   consty = 0,
                                   nreps = 2,
                                   shuffles = 6,
                                   ncores = parallel::detectCores() - 1,
                                   type = "quantiles",
                                   quantiles = c(5, 95),
                                   bins = NULL,
                                   limits = NULL,
                                   nboot,
                                   burn = 50) {

  # Code time series
  x <- code_sample(x, type, quantiles, bins, limits)
  y <- code_sample(y, type, quantiles, bins, limits)

  # Calculate transfer entropy (withour shuffling)
  # Lead = x
  tex <- transfer_entropy_ren(x, lx = lx, y, ly = ly, q)$transentropy
  # Lead = y
  tey <- transfer_entropy_ren(y, lx = ly, x, ly = lx, q)$transentropy

  # Calculate transfer entropy (with shuffling)
  constx <- shuffled_transfer_entropy_ren(x,
                                          lx = lx,
                                          y,
                                          ly = ly,
                                          q,
                                          nreps,
                                          shuffles,
                                          diff = FALSE,
                                          ncores)

  consty <- shuffled_transfer_entropy_ren(y,
                                          lx = ly,
                                          x,
                                          ly = lx,
                                          q,
                                          nreps,
                                          shuffles,
                                          diff = FALSE,
                                          ncores)

  # Lead = x
  stex <- tex - constx
  # Lead = y
  stey <- tey - consty

  # Bootstrap
  boot <- replicate(nboot,
                    trans_boot_H0_ren(x,
                                      lx,
                                      y,
                                      ly,
                                      q,
                                      burn,
                                      shuffle,
                                      const,
                                      constx,
                                      consty,
                                      nreps))


  return(list(tex   = tex,
              tey   = tey,
              stex = stex,
              stey = stey,
              bootstrap_H0 = boot))
}