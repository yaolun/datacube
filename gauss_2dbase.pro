function gauss_2dbase, x, a
  f = a[0]*exp((-(x-a[1])^2)/2/a[2]^2)+a[3]*x^2+a[4]*x+a[5]
  return, f
end
