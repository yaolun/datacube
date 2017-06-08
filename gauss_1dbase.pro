function gauss_1dbase, x, a
  f = a[0]*exp((-(x-a[1])^2)/2/a[2]^2)+a[3]*x+a[4]
  return, f
end