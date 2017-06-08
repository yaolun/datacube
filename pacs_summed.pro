pro pacs_summed, indir=indir
pix = [7,8,9,12,13,14,17,18,19]
wl = []
flux_sum = 0
for i = 0, n_elements(pix)-1 do begin
	readcol, indir+'pacs_pixel'+strtrim(string(pix[i]),1)+'.txt',format='D,D', wl, flux
	flux_sum = flux+flux_sum
endfor
openw, lun, indir+'pacs_finalcube_3x3_summed.txt', /get_lun
for i = 0, n_elements(flux_sum)-1 do printf, lun, wl[i], flux_sum[i]
free_lun, lun
close, lun
pix = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]
wl = []
flux_sum = 0
for i = 0, n_elements(pix)-1 do begin
	readcol, indir+'pacs_pixel'+strtrim(string(pix[i]),1)+'.txt',format='D,D', wl, flux
	flux_sum = flux+flux_sum
endfor
openw, lun, indir+'pacs_finalcube_5x5_summed.txt', /get_lun
for i = 0, n_elements(flux_sum)-1 do printf, lun, wl[i], flux_sum[i]
free_lun, lun
close, lun
end
