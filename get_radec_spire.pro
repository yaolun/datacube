pro get_radec_spire, filename=filename, pix, ra, dec, slw=slw, ssw=ssw, central=central, hsa=hsa, write=write

; the extension index for CDF product: SLW-11, SSW-39
; the extension index for HSA product: point--SLW-5, SSW-18; ext--SLW-11, SSW-39
slw_ext = 11
ssw_ext = 39
if keyword_set(hsa) then begin
  slw_ext = 5
  ssw_ext = 18
endif
if not keyword_set(central) then begin
	if keyword_set(slw) then begin
		pix_name = strarr(19)
		coord = dblarr(2,19)
		plot_coord = dblarr(2,19)
		hdr = headfits(filename, exten=slw_ext,/silent)
		cen_dec = sxpar(hdr, 'DEC') & cen_ra = sxpar(hdr, 'RA')
		for i = 2, 20 do begin
			hdr = headfits(filename, exten=i,/silent)
			dec = sxpar(hdr, 'DEC') & ra = sxpar(hdr, 'RA')
			pix = sxpar(hdr,'EXTNAME')
			pix_name[i-2] = strcompress(pix,/remove_all)
			coord[*,i-2] = [ra, dec]
			plot_coord[*,i-2] = [ra-cen_ra, dec-cen_dec]
		endfor
		;print, cen_ra, cen_dec
	endif

	if keyword_set(ssw) then begin
		pix_name = strarr(35)
		coord = dblarr(2,35)
		plot_coord = dblarr(2,35)
		hdr = headfits(filename, exten=ssw_ext,/silent)
		cen_dec = sxpar(hdr, 'DEC') & cen_ra = sxpar(hdr, 'RA')
		for i = 21, 55 do begin
			hdr = headfits(filename, exten=i,/silent)
			dec = sxpar(hdr, 'DEC') & ra = sxpar(hdr, 'RA')
			pix = sxpar(hdr,'EXTNAME')
			pix_name[i-21] = strcompress(pix,/remove_all)
			coord[*,i-21] = [ra, dec]
			plot_coord[*,i-21] = [ra-cen_ra, dec-cen_dec]
		endfor
	endif
	pix = pix_name
	ra = coord[0,*]
	dec = coord[1,*]

    ; write out the results
    if KEYWORD_SET(write) then begin
        if KEYWORD_SET(slw) then module = 'slw'
        if KEYWORD_SET(ssw) then module  = 'ssw'

        openw, lun, write+'_radec_'+module+'.txt', /get_lun
        printf, lun, format='(3(a16,2x))', 'Pixel', 'RA(dec)', 'Dec(deg)'
        for i = 0, n_elements(pix)-1 do printf, lun, format='((a16,2x),2(g16.6,2X))', pix[i], ra[i], dec[i]
        free_lun, lun
        close, lun
    endif
endif else begin
	hdr = headfits(filename, exten=5,/silent)
	dec = [sxpar(hdr, 'DEC')] & ra = [sxpar(hdr, 'RA')]
	pix = ['SLWC3']
endelse

end
