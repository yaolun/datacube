pro read_line_ref, line, E_u, A, g
readcol, '~/programs/line_fitting/all_line_ref.txt', format='A,D,D,I', name, E_u, A, g,/silent
ind = where(line eq name)
if ind[0] eq -1 then print, 'Line information is missing -- ', line
E_u = E_u[ind]
A = A[ind]
g = g[ind]
end
