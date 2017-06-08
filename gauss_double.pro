function gauss_double, x, a
  f = a[0]*exp((-(x-a[1])^2)/2/a[2]^2) + a[3]*exp(-(x-a[4])^2/2/a[5]^2)
  return, f
end
