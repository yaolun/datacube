function gauss, x, a
  f = a[0]*exp((-(x-a[1])^2)/2/a[2]^2)
  return, f
end