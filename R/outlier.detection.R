#' Outlier Detection
#'
#' This function calculates outlier's using geodesic distances of the SRVFs from
#' the median
#'
#' @param q matrix (\eqn{M} x \eqn{N}) of \eqn{M} SRVF functions with \eqn{N} 
#' samples
#' @param time vector of size \eqn{N} describing the sample points
#' @param mq median calcuated using \code{\link{time_warping}}
#' @param k cutoff threshold (default = 1.5)
#' @return \item{q_outlier}{outlier functions}
#' @keywords srvf outlier detection
#' @references Srivastava, A., Wu, W., Kurtek, S., Klassen, E., Marron, J. S.,
#'  May 2011. Registration of functional data using fisher-rao metric, 
#'  arXiv:1103.3817v2 [math.ST].
#' @export
#' @examples
#' data("toy_data")
#' out = time_warping(toy_data$f,toy_data$time, method = "median")
#' q_outlier = outlier.detection(out$q0,toy_data$time,out$mqn,k=.1)
outlier.detection <- function(q, time, mq, k = 1.5){
	N = ncol(q)
	ds = rep(0,N)
	for (kk in 1:N)
		ds[kk] = sqrt(sum(simpson(time, (mq-q[,kk])^2)))
	
	quartile_range = quantile(ds)
	IQR = quartile_range[4] - quartile_range[2]
	
	thresh = quartile_range[4] + k * IQR
	
	ind = which(ds > thresh)
	
	q_outlier = q[,ind]
	
	return(q_outlier)
}