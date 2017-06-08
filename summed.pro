pro summed, indir=indir, outdir=outdir, aor_name=aor_name, slice=slice, five=five, three=three

band = ['blue','blue','red','red']
if keyword_set(five) then pixel = indgen(25)+1
if keyword_set(three) then pixel = [6,7,8,11,12,13,16,17,18]
for iband = 0, n_elements(band)-1 do begin
	for i_slice = 0, slice[iband] do begin
		filename = 'linescan_'+aor_name[iband]+'v13os4_'+band[iband]+'norm_sl'+strtrim(string(i_slice),1)
		readcol, indir+filename+'_pixel13.txt',format='D,D',wl,flux,/silent
		wl = wl & flux = flux*0
		line = 0
		for pix = 0, n_elements(pixel)-1 do begin
			readcol, indir+filename+'_pixel'+strtrim(string(pixel[pix]),1)+'.txt', format='D,D',wlp, fluxp,/silent
			for r = 0, n_elements(wl)-1 do begin
				for k = 0, n_elements(wlp)-1 do begin
					if wl[r] eq wlp[k] then begin
						flux[r] = flux[r] + fluxp[k]
						line = line + 1
						break
					endif
				endfor
			endfor
		endfor
		print, line
		if keyword_set(five) then openw, lun, indir+filename+'_summed_5x5.txt',/get_lun
		if keyword_set(three) then openw,lun, indir+filename+'_summed_3x3.txt',/get_lun
		for i =0, n_elements(wl)-1 do printf, lun, format='(2(g16.6,2x))',wl[i],flux[i]
		free_lun, lun
		close, lun
	endfor
endfor
end

pro summed_five, indir=indir, outdir=outdir, object=object, suffix=suffix, plot=plot
;msg = ''
;if keyword_set(nojitter) then  msg = 'nojitter/'
readcol, indir+object+'_pacs_pixel13_'+suffix+'.txt',format='D,D',wl, flux,/silent
flux = fltarr(n_elements(flux))
print, '------>Co-adding the 5x5 cube into 1D spectrum...'
for i = 1, 25 do begin
	line = 0
	readcol, indir+object+'_pacs_pixel'+strtrim(string(i),1)+'_'+suffix+'.txt',format='D,D',wll, fluxx,/silent
	for j =0, n_elements(wl)-1 do begin
		for k = 0, n_elements(wll)-1 do begin
			if wl[j] eq wll[k] then begin
				flux[j] = flux[j]+fluxx[k]
				line = line+1
				break
			endif
		endfor
	endfor
	;print, line, ' lines matched in pixel'+strtrim(string(i),1)+'!'
endfor
openw, lun, outdir+object+'_pacs_summed_5x5_'+suffix+'.txt',/get_lun
for i =0, n_elements(wl)-1 do printf,lun, format='(2(g16.6,2x))',wl[i],flux[i]
free_lun, lun
close, lun
if keyword_set(plot) then begin
	plotdir = plot
	flux_b2a = flux[where(wl ge 54.80 and wl le 72.3)]
	wl_b2a = wl[where(wl ge 54.80 and wl le 72.3)]
	flux_b2b = flux[where(wl gt 72.3 and wl le 95.05)]
	wl_b2b = wl[where(wl gt 72.3 and wl le 95.05)]
	flux_r1s = flux[where(wl gt 100 and wl le 143)]
	wl_r1s = wl[where(wl gt 100 and wl le 143)]
	flux_r1l = flux[where(wl gt 143 and wl le 190.31)]
	wl_r1l = wl[where(wl gt 143 and wl le 190.31)]
	set_plot, 'ps'
	!p.font=0
	loadct,13,/silent
	!p.thick=3 & !x.thick=3 & !y.thick=3
	device, filename = plotdir+object+'_pacs_cube_coadd_5x5_'+suffix+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
	plot, wl, flux, xtitle = 'Wavelength (!9m!3m)', ytitle = 'Flux (Jy)',/nodata
	if n_elements(wl_b2a) ne 0 then oplot, reform(wl_b2a), reform(flux_b2a), color=60    ;blue
	if n_elements(wl_b2b) ne 0 then oplot, reform(wl_b2b), reform(flux_b2b), color=160   ;green
	if n_elements(wl_r1s) ne 0 then oplot, reform(wl_r1s), reform(flux_r1s), color=237   ;orange
	if n_elements(wl_r1l) ne 0 then oplot, reform(wl_r1l), reform(flux_r1l), color=250   ;red
	al_legend, ['B2A','B2B','R1A','R1B'],textcolors = [60, 160, 237, 250],/right
	al_legend, [object], textcolors=[0], /left
	device, /close_file,decomposed=1
	!p.multi = 0
endif
;print, 'Done!'
end

pro summed_spire, indir=indir, outdir=outdir, object=object, plot=plot

pix_slw = ['SLWA1','SLWA2','SLWA3','SLWB1','SLWB2','SLWB3','SLWB4','SLWC1','SLWC2','SLWC3','SLWC4','SLWC5','SLWD1','SLWD2','SLWD3','SLWD4','SLWE1','SLWE2','SLWE3']
pix_ssw = ['SSWA1','SSWA2','SSWA3','SSWA4','SSWB1','SSWB2','SSWB3','SSWB4','SSWB5','SSWC1','SSWC2','SSWC3','SSWC4','SSWC5','SSWC6','SSWD1','SSWD2','SSWD3','SSWD4',$
		   'SSWD6','SSWD7','SSWE1','SSWE2','SSWE3','SSWE4','SSWE5','SSWE6','SSWF1','SSWF2','SSWF3','SSWF5','SSWG1','SSWG2','SSWG3','SSWG4']
; SSW
pix = pix_ssw
cen_pix = 'SSWD4'
msg = '------>Co-adding the SPIRE-SSW cube into 1D spectrum...'

readcol, indir+object+'_'+cen_pix+'.txt',format='D,D',wl, flux
flux = fltarr(n_elements(flux))
print, msg
for i = 0, n_elements(pix) do begin
	line = 0
	readcol, indir+object+'_'+pix[i]+'.txt',format='D,D',wll, fluxx,/silent
	for j =0, n_elements(wl)-1 do begin
		for k = 0, n_elements(wll)-1 do begin
			if wl[j] eq wll[k] then begin
				flux[j] = flux[j]+fluxx[k]
				line = line+1
				break
			endif
		endfor
	endfor
	;print, line, ' lines matched in pixel'+strtrim(string(i),1)+'!'
endfor
wl_ssw = sl
flux_ssw = flux
; SLW
pix = pix_slw
cen_pix = 'SLWC3'
msg = '------>Co-adding the SPIRE-SLW cube into 1D spectrum...'

readcol, indir+object+'_'+cen_pix+'.txt',format='D,D',wl, flux
flux = fltarr(n_elements(flux))
print, msg
for i = 0, n_elements(pix) do begin
	line = 0
	readcol, indir+object+'_'+pix[i]+'.txt',format='D,D',wll, fluxx,/silent
	for j =0, n_elements(wl)-1 do begin
		for k = 0, n_elements(wll)-1 do begin
			if wl[j] eq wll[k] then begin
				flux[j] = flux[j]+fluxx[k]
				line = line+1
				break
			endif
		endfor
	endfor
	;print, line, ' lines matched in pixel'+strtrim(string(i),1)+'!'
endfor
wl_slw = wl
flux_slw = flux

wl = [wl_ssw,wl_slw]
flux = [flux_ssw, flux_slw]
openw, lun, outdir+object+'_spire_cube_coadd.txt',/get_lun
for i =0, n_elements(wl)-1 do printf,lun, format='(2(g16.6,2x))',wl[i],flux[i]
free_lun, lun
close, lun

if keyword_set(plot) then begin
	plotdir = plot
	set_plot, 'ps'
	!p.font=0
	loadct,13,/silent
	!p.thick=3 & !x.thick=3 & !y.thick=3
	device, filename = plotdir+object+'_spire_cube_coadd.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
	plot, wl, flux, xtitle = 'Wavelength (!9m!3m)', ytitle = 'Flux (Jy)',/nodata
	if n_elements(wl_ssw) ne 0 then oplot, reform(wl_ssw), reform(flux_ssw), color=60    ;blue
	if n_elements(wl_slw) ne 0 then oplot, reform(wl_slw), reform(flux_slw), color=250   ;red
	al_legend, ['SPIRE-SLW','SPIRE_SSW'],textcolors = [250,60],/right
	al_legend, [object], textcolors=[0], /left
	device, /close_file,decomposed=1
	!p.multi = 0
endif
end
pro summed_three, indir, outdir, suffix, objname, wl, flux, nojitter=nojitter
msg = ''
if keyword_set(nojitter) then  msg = 'nojitter/'
readcol, indir+objname+msg+'_pacs_pixel13_'+suffix+'.txt',format='D,D',wl, flux,/silent
pixel = [6,7,8,11,12,13,16,17,18]
flux = fltarr(n_elements(flux))
for i = 0, n_elements(pixel)-1 do begin
	line = 0
	readcol, indir+objname+msg+'_pacs_pixel'+strtrim(string(pixel[i]),1)+'_'+suffix+'.txt',format='D,D',wll, fluxx,/silent
	for j =0, n_elements(wl)-1 do begin
		for k = 0, n_elements(wll)-1 do begin
		    if wl[j] eq wll[k] then begin
			    flux[j] = flux[j]+fluxx[k]
			    line = line+1
			    break
			endif
		endfor
	endfor
	print, line, ' lines matched in pixel'+strtrim(string(pixel[i]),1)+'!'
endfor
openw, lun, outdir+objname+msg+'_pacs_summed_3x3_'+suffix+'.txt',/get_lun
for i =0, n_elements(wl)-1 do printf,lun, format='(2(g16.6,2x))',wl[i],flux[i]
free_lun, lun
close, lun
print, 'Done!'
end


pro summed_innerring,wl, flux

readcol, '~/tmc1/data/pacs_pixel13.txt',format='D,D',wl, flux
pixel = [6,7,8,11,12,16,17,18]
for i = 0, n_elements(pixel)-1 do begin
	line = 0
	readcol, '~/tmc1/data/pacs_pixel'+strtrim(string(pixel[i]),1)+'.txt',format='D,D',wll, fluxx
	for j =0, n_elements(wl)-1 do begin
		for k = 0, n_elements(wll)-1 do begin
			if wl[j] eq wll[k] then begin
				flux[j] = flux[j]+fluxx[k]
				line = line+1
				break
			endif
		endfor
	endfor
	;print, line
endfor
openw, lun, '~/tmc1/data/pacs_summed_innerring.txt',/get_lun
for i =0, n_elements(wl)-1 do printf,lun, format='(2(g16.6,2x))',wl[i],flux[i]
free_lun, lun
close, lun
print, 'Done!'
end
