exp_map<-function(psi, v){
  v_norm <- l2_norm(v)
  expgam <- cos(v_norm) * psi + sin(v_norm) * v / v_norm
  return(expgam)
}

inv_exp_map<-function(Psi, psi){
  theta <- acos(inner_product(Psi,psi))

  if (theta < 1e-10){
    exp_inv = rep(0,length(psi))
  } else {
    exp_inv = theta / sin(theta) * (psi-cos(theta)*Psi)
  }
  return(exp_inv)
}

warp_q_gamma <- function(time, q, gam){
  M = length(gam)
  gam_dev = gradient(gam, 1/(M-1))
  q_tmp = approx(time,q,xout=(time[length(time)]-time[1])*gam +
               time[1])$y*sqrt(gam_dev)
  return(q_tmp)
}

randomGamma <- function(gam,num){
    out = SqrtMean(gam)
    mu = out$mu
    psi = out$psi
    vec = out$vec

    K = cov(t(vec))
    out = svd(K)
    s = out$d
    U = out$u
    n = 5
    TT = nrow(vec)
    vm = rowMeans(vec)
    time <- seq(0,1,length.out=TT)

    rgam = matrix(0,num,TT)
    for (k in 1:num){
        a = rnorm(n)
        v = rep(0,length(vm))
        for (i in 1:n){
            v = v + a[i]*sqrt(s[i])*U[,i]
        }
        psi <- exp_map(mu,v)

        gam0 <- cumtrapz(time,psi*psi)
        rgam[k,] = (gam0 - min(gam0))/(max(gam0)-min(gam0))
    }
    return(rgam)
}

SqrtMeanInverse <- function(gam){
  TT = nrow(gam)
  n = ncol(gam)
  eps = .Machine$double.eps
  time <- seq(0,1,length.out=TT)

  psi = matrix(0,TT,n)
  binsize <- mean(diff(time))
  for (i in 1:n){
      psi[,i] = sqrt(gradient(gam[,i],binsize))
  }

  # Find Direction
  mu = rowMeans(psi)
  stp <- .3
  maxiter = 501
  vec = matrix(0,TT,n)
  lvm = rep(0,maxiter)
  iter <- 1

  for (i in 1:n){
    vec[,i] <- inv_exp_map(mu, psi[,i])
  }
  vbar <- rowMeans(vec)
  lvm[iter] <- l2_norm(vbar)

  while (lvm[iter]>0.00000001 & iter<maxiter){
    mu <- exp_map(mu, stp*vbar)
    iter <- iter + 1
    for (i in 1:n){
      vec[,i] <- inv_exp_map(mu, psi[,i])
    }
    vbar <- rowMeans(vec)
    lvm[iter] <- l2_norm(vbar)
  }

  gam_mu = cumtrapz(time, mu*mu)
  gam_mu = (gam_mu - min(gam_mu))/(max(gam_mu)-min(gam_mu))
  gamI = invertGamma(gam_mu)
  return(gamI)
}

findkarcherinv <- function(warps, times, round = F){
  m <- dim(warps)[1]
  n <- dim(warps)[2]
  psi.m <- matrix(0,m-1,n)
  for(j in 1:n){psi.m[,j]<- sqrt(diff(warps[,j])/times)}
  w <- apply(psi.m,1,mean)
  mupsi <- w/sqrt(sum(w^2/(m-1)))
  v.m <- matrix(0,m-1,n)
  check <- 1
  while(check > 0.01){
    for (i in 1:n){
      theta <- acos(sum(mupsi*psi.m[,i]/(m-1)))
      v.m[,i] <- theta/sin(theta)*(psi.m[,i]-cos(theta)*mupsi)
    }
    vbar <- apply(v.m,1,mean)
    check <- Enorm(vbar)/sqrt(m-1)
    if (check>0){
      mupsi.update <- cos(0.01*Enorm(vbar)/sqrt(m-1))*mupsi+sin(0.01*Enorm(vbar)/sqrt(m-1))*vbar/(Enorm(vbar)/sqrt(m-1))
    }
    else { mupsi.update <- cos(0.01*Enorm(vbar)/sqrt(m-1))*mupsi}
  }
  karcher.s <- 1+c(0,cumsum(mupsi.update^2)*times)
  if(round){
    invidy <- c(round(approx(karcher.s,seq(1,(m-1)*times+1,times),method="linear",xout=1:((m-1)*times))$y),(m-1)*times+1)
  }
  else{
    invidy <- c((approx(karcher.s,seq(1,(m-1)*times+1,times),method="linear",xout=1:((m-1)*times))$y),(m-1)*times+1)
  }
  revscalevec <- sqrt(diff(invidy))
  return(list(invidy = invidy,revscalevec = revscalevec))
}
