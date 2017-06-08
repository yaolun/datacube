pro get_spire_1d, indir=indir, filename=filename, outdir=outdir,object=object, brightness=brightness,fx=fx,trim_detail=trim_detail

	if file_test(outdir) eq 0 then file_mkdir, outdir

	if keyword_set(brightness) then begin
		ylabel = 'I!d!9n!n!3 (Jy/arcsec!u2!n)'
	endif
	if keyword_set(fx) then begin
		ylabel = 'Flux (Jy)'
	endif
	; The beam center spacing of SLW and SSW
	; Convert them into pixel size (arcsec2)
    ; SPIRE observar manual p. 48.  This is the averaged value.  The profile versus wavelength see p. 92.
	pix_slw = !PI/4*34^2
	pix_ssw = !PI/4*19^2
	; The extended corrected data cube still has slices for each spaxel, but only take the central one and reduce them into 1D spectrum
	; 12/19/14  It seems that 1-D spectrum is already in Jy unit.  No longer need to do the unit conversion
  	data_slw = readfits(filename, hdr_slw, exten=5,/silent)
	data_ssw = readfits(filename, hdr_ssw, exten=18,/silent)
	; data_slw = readfits(filename, hdr_slw, exten=2,/silent)
	; data_ssw = readfits(filename, hdr_ssw, exten=3,/silent)
	if data_slw[0] ne -1 and data_ssw[0] ne -1 then begin
		wl_slw = 2.998e10/tbget(hdr_slw, data_slw, 1)*1e-5
		wl_ssw = 2.998e10/tbget(hdr_ssw, data_ssw, 1)*1e-5
		if keyword_set(fx) then begin
			flux_slw = tbget(hdr_slw,data_slw, 2);*(!PI/180/3600)^2*1e26*pix_slw                            ;convert W m-2 Hz-1 sr-1 to Jy
			flux_ssw = tbget(hdr_ssw,data_ssw, 2);*(!PI/180/3600)^2*1e26*pix_ssw                            ;convert W m-2 Hz-1 sr-1 to Jy
		endif
		if keyword_set(brightness) then begin
    		flux_slw = tbget(hdr_slw, data_slw, 2);*(!PI/180/3600)^2*1e26                                   ;convert W m-2 Hz-1 sr-1 to Jy arcsec-2
			flux_ssw = tbget(hdr_ssw, data_ssw, 2);*(!PI/180/3600)^2*1e26                                   ;convert W m-2 Hz-1 sr-1 to Jy arcsec-2
		endif
        ; option for writing out the untrimmed spectra
        if keyword_set(trim_detail) then begin
            ; SSW
            openw, lun, outdir+object+'_spire_corrected_ssw.txt', /get_lun
            if keyword_set(fx) then printf, lun, format='(2(a14,2x))','Wavelength(um)', 'Flux_Density(Jy)'
            if keyword_set(brightness) then printf, lun, format='(2(a14,2x))','Wavelength(um)', 'I_nu(Jy/as2)'
            for k = 0, n_elements(wl_ssw)-1 do printf, lun, format = '(2(g14.6,2X))', wl_ssw[k], flux_ssw[k]
            free_lun, lun
            close, lun
            ; SSW
            openw, lun, outdir+object+'_spire_corrected_slw.txt', /get_lun
            if keyword_set(fx) then printf, lun, format='(2(a14,2x))','Wavelength(um)', 'Flux_Density(Jy)'
            if keyword_set(brightness) then printf, lun, format='(2(a14,2x))','Wavelength(um)', 'I_nu(Jy/as2)'
            for k = 0, n_elements(wl_slw)-1 do printf, lun, format = '(2(g14.6,2X))', wl_slw[k], flux_slw[k]
            free_lun, lun
            close, lun
        endif
		; Trim the spectrum
        ; flux_ssw = flux_ssw[where(wl_ssw le 304 and wl_ssw gt 195)]
        ; wl_ssw = wl_ssw[where(wl_ssw le 304 and wl_ssw gt 195)]
        ; flux_slw = flux_slw[where(wl_slw gt 304)]
        ; wl_slw = wl_slw[where(wl_slw gt 304)]
        flux_ssw = flux_ssw[where(wl_ssw le 310 and wl_ssw gt 195)]
        wl_ssw = wl_ssw[where(wl_ssw le 310 and wl_ssw gt 195)]
        flux_slw = flux_slw[where(wl_slw gt 310)]
        wl_slw = wl_slw[where(wl_slw gt 310)]
		flux_ssw = flux_ssw[sort(wl_ssw)]
		wl_ssw = wl_ssw[sort(wl_ssw)]
		flux_slw = flux_slw[sort(wl_slw)]
		wl_slw = wl_slw[sort(wl_slw)]
		wl = [wl_ssw,wl_slw]
		flux = [flux_ssw,flux_slw]
	endif else begin
		data = readfits(filename, hdr, exten=2)
		wl = 2.998e10/tbget(hdr,data,1)*1e-5
		flux = tbget(hdr,data,2)
		flux = flux[sort(wl)]
		wl = wl[sort(wl)]
		; wl_ssw = wl[where(wl gt 195 and wl le 304)]
		; flux_ssw = flux[where(wl gt 195 and wl le 304)]
		; wl_slw = wl[where(wl gt 304)]
		; flux_slw = wl[where(wl gt 304)]
        wl_ssw = wl[where(wl gt 195 and wl le 310)]
        flux_ssw = flux[where(wl gt 195 and wl le 310)]
        wl_slw = wl[where(wl gt 310)]
        flux_slw = wl[where(wl gt 310)]
	endelse

    ; Sort the spectrum
    flux = flux[sort(wl)]
    wl = wl[sort(wl)]
    openw, lun, outdir+object+'_spire_corrected.txt',/get_lun
    if keyword_set(fx) then printf, lun, format='(2(a14,2x))','Wavelength(um)', 'Flux_Density(Jy)'
    if keyword_set(brightness) then printf, lun, format='(2(a14,2x))','Wavelength(um)', 'I_nu(Jy/as2)'
    for k = 0, n_elements(wl)-1 do printf, lun, format = '(2(g14.6,2X))', wl[k], flux[k]
    free_lun, lun
    close, lun
    ; Plot the spectrum
    set_plot, 'ps'
	!p.font=0
	loadct,13,/silent
	!p.thick=3 & !x.thick=3 & !y.thick=3
    device, filename = outdir+object+'_spire_corrected.eps', /helvetica, /portrait, /encapsulated, font_size = 12, isolatin = 1, decomposed = 0, /color
    plot, wl, flux, xtitle = 'Wavelength (!9m!3m)', ytitle = 'Flux Density (Jy)',/nodata
	oplot, wl_slw, flux_slw, color=250, thick=2
	oplot, wl_ssw, flux_ssw, color=60, thick=2
	al_legend, ['SPIRE-SSW','SPIRE-SLW'],textcolors=[60,250],/right
	al_legend, [object],textcolor=[0],/left
	device, /close_file,decomposed=1
	!p.multi = 0
end

pro plot_spire_1d, wl, flux, object=object, pixname=pixname, outdir=outdir, fx=fx, brightness=brightness
    ; This routine is designed for plotting the individual spaxel either from SSW or SLW.  Callable by get_spire
    ; Sort the spectrum
    flux = flux[sort(wl)]
    wl = wl[sort(wl)]
    if keyword_set(brightness) then ylabel = 'I!d!9n!n!3 (Jy/arcsec!u2!n)'
    if keyword_set(fx) then ylabel = 'Flux Density (Jy)'
    ; Plot the spectrum
    set_plot, 'ps'
    !p.font=0
    loadct,13,/silent
    !p.thick=3 & !x.thick=3 & !y.thick=3
    plotposition = [0.1,0.1,0.95,0.95]
    device, filename = outdir+object+'_'+pixname+'.eps', /helvetica, /portrait, /encapsulated, font_size = 8, isolatin = 1, decomposed = 0, /color
    plot, wl, flux, xtitle = 'Wavelength (!9m!3m)', ytitle = ylabel, thick = 2, position=plotposition
    al_legend, [object+' '+pixname],textcolors=[0],/right
    device, /close_file,decomposed=1
    !p.multi = 0
end

pro get_spire, object=object,indir=indir, filename=filename, outdir=outdir, brightness=brightness,fx=fx;, hsa=hsa

; extension range for CDF products: SLW-[2, 20], SSW-[21,55]

if file_test(outdir) eq 0 then file_mkdir, outdir
plotdir = outdir
;if file_test(plotdir) eq 0 then file_mkdir, plotdir
; The beam center spacing of SLW and SSW
; Convert them into pixel size (arcsec2)
; SPIRE observar manual p. 48.  This is the averaged value.  The profile versus wavelength see p. 92.
pix_slw = !PI/4*34^2
pix_ssw = !PI/4*19^2
; Read the object info from the header
;SLW
; !p.multi = [0,5,5]
; set_plot, 'ps'
; !p.font = 0
if keyword_set(brightness) then begin
	plotname_slw = plotdir+object+'_brightness_slw.eps'
	plotname_ssw = plotdir+object+'_brightness_ssw.eps'
	ylabel = 'I!d!9n!n!3 (Jy/arcsec!u2!n)'
    fx = 0
endif
if keyword_set(fx) then begin
	plotname_slw = plotdir+object+'_flux_slw.eps'
	plotname_ssw = plotdir+object+'_flux_ssw.eps'
	ylabel = 'Flux Density(Jy)'
    brightness = 0
endif
; device, filename = plotname_slw, /helvetica, /portrait, /encapsulated, font_size = 8, isolatin = 1, decomposed = 0, /color
; loadct, 12,/silent
; !p.thick = 1; & !x.thick = 3 & !y.thick = 3
label = ['SLWA1','SLWA2','SLWA3','SLWB1','SLWB2','SLWB3','SLWB4','SLWC1','SLWC2','SLWC3','SLWC4','SLWC5','SLWD1','SLWD2','SLWD3','SLWD4','SLWE1','SLWE2','SLWE3','SSWA1','SSWA2','SSWA3',$
         'SSWA4','SSWB1','SSWB2','SSWB3','SSWB4','SSWB5','SSWC1','SSWC2','SSWC3','SSWC4','SSWC5','SSWC6','SSWD1','SSWD2','SSWD3','SSWD4','SSWD6','SSWD7','SSWE1','SSWE2','SSWE3',$
         'SSWE4','SSWE5','SSWE6','SSWF1','SSWF2','SSWF3','SSWF5','SSWG1','SSWG2','SSWG3','SSWG4']

; SLW
for i =2, 20 do begin
    data = readfits(filename, hdr,exten=i,/silent)
    wl = 2.998e10/tbget(hdr, data, 1)*1e-5
    if keyword_set(fx) then flux = tbget(hdr,data, 2)*(!PI/180/3600)^2*1e26*pix_slw                            ;convert W m-2 Hz-1 sr-1 to Jy
    if keyword_set(brightness) then flux = tbget(hdr, data, 2)*(!PI/180/3600)^2*1e26                           ;convert W m-2 Hz-1 sr-1 to Jy arcsec-2
    ; flux = flux[where(wl gt 304)]
    ; wl = wl[where(wl gt 304)]
    flux = flux[where(wl gt 310)]
    wl = wl[where(wl gt 310)]
    flux = flux[sort(wl)]
    wl = wl[sort(wl)]
    ; plot spaxel spectrum
    plot_spire_1d, wl, flux, object=object, pixname=label[i-2], outdir=outdir, fx=fx, brightness=brightness
    openw, lun, outdir+object+'_'+label[i-2]+'.txt', /get_lun
    if keyword_set(fx) then printf, lun, format='(2(a14,2x))','Wavelength(um)', 'Flux_Density(Jy)'
    if keyword_set(brightness) then printf, lun, format='(2(a14,2x))','Wavelength(um)', 'I_nu(Jy/as2)'
    for k = 0, n_elements(wl)-1 do printf, lun, format = '(2(g14.6,2X))', wl[k], flux[k]
    free_lun, lun
    close, lun
endfor

; SSW
for i = 21, 55 do begin
    data = readfits(filename, hdr,exten=i,/silent)
    wl = 2.998e10/tbget(hdr, data, 1)*1e-5
    if keyword_set(fx) then flux = tbget(hdr,data, 2)*(!PI/180/3600)^2*1e26*pix_ssw                            ;convert W m-2 Hz-1 sr-1 to Jy
    if keyword_set(brightness) then flux = tbget(hdr, data, 2)*(!PI/180/3600)^2*1e26                           ;convert W m-2 Hz-1 sr-1 to Jy arcsec-2
    ; flux = flux[where(wl gt 195 and wl le 304)]
    ; wl = wl[where(wl gt 195 and wl le 304)]
    flux = flux[where(wl gt 195 and wl le 310)]
    wl = wl[where(wl gt 195 and wl le 310)]
    flux = flux[sort(wl)]
    wl = wl[sort(wl)]
    ; plot spaxel spectrum
    plot_spire_1d, wl, flux, object=object, pixname=label[i-2], outdir=outdir, fx=fx, brightness=brightness
    openw, lun, outdir+object+'_'+label[i-2]+'.txt', /get_lun
    if keyword_set(fx) then printf, lun, format='(2(a14,2x))','Wavelength(um)', 'Flux_Density(Jy)'
    if keyword_set(brightness) then printf, lun, format='(2(a14,2x))','Wavelength(um)', 'I_nu(Jy/as2)'
    for k = 0, n_elements(wl)-1 do printf, lun, format = '(2(g14.6,2X))', wl[k], flux[k]
    free_lun, lun
    close, lun
endfor

end

pro get_all,name=name, indir=indir, outdir=outdir, plotdir=plotdir
  get_spire, name=name,indir=indir,outdir=outdir,plotdir=plotdir,/brightness
  get_spire, name=name,indir=indir,outdir=outdir,plotdir=plotdir,/fx
end
;BHR71: plot_all, name='1342248249_spectrum_extended_HR_aNB_15',indir='~/bhr71/data/',outdir='~/bhr71/data/'
