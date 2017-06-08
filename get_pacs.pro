pro get_pacs, outdir=outdir, filename=filename, objname=objname, suffix=suffix,general=general, separate=separate, hsa=hsa

outdir = outdir+'cube/'
plotdir = outdir+'plots/spectrum/'
if file_test(outdir) eq 0 then file_mkdir, outdir
if file_test(plotdir) eq 0 then file_mkdir, plotdir

; For some reasons, HSA products stop at different wavelength than CDF for B2A
b2a_break = 72.3
if keyword_set(hsa) then b2a_break = 71.8
; if KEYWORD_SET(hsa) then begin
;     ext_index = []
; endif else begin
;     ext_index = [8, 1, 5, 2, 3]
; endelse

if keyword_set(general) then begin
	for i = 0, n_elements(filename)-1 do begin
		wl = []
		flux = []
		ra = []
		dec = []
		for foo = 0, n_elements(filename)-1 do begin
			wl_dum = readfits(filename[foo], exten=8,/silent)
			flux_dum = readfits(filename[foo], exten=1,/silent)
			std_dum = readfits(filename[foo], exten=5,/silent)
			ra_dum = readfits(filename[foo], exten=2,/silent)
			dec_dum = readfits(filename[foo], exten=3,/silent)
			hdr = headfits(filename[foo],/silent)
			if foo eq 0 then begin
				min_wl = [min(wl_dum)]
				ifile = [foo]
			endif else begin
				min_wl = [min_wl, min(wl_dum)]
				ifile = [ifile,foo]
			endelse
		endfor
		ifile = ifile[sort(min_wl)]
	endfor
	for i = 0, n_elements(ifile)-1 do begin
		wl_dum = readfits(filename[ifile[i]], exten=8,/silent)
		flux_dum = readfits(filename[ifile[i]], exten=1,/silent)
		std_dum = readfits(filename[ifile[i]], exten=5,/silent)
		ra_dum = readfits(filename[ifile[i]], exten=2,/silent)
		dec_dum = readfits(filename[ifile[i]], exten=3,/silent)
		hdr = headfits(filename[ifile[i]],/silent)

        if KEYWORD_SET(separate) then begin
            band = strtrim(sxpar(hdr,'BAND'),1)
    		band = strcompress(band,/remove_all)

            flux_dum = flux[*,*,sort(wl_dum)]
        	std_dum = std[*,*,sort(wl_dum)]
        	wl_dum = wl[sort(wl_dum)]
        	pix = 1
        	for x = 0, 4 do begin
        		for y = 0, 4 do begin
        			openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+band+'.txt',/get_lun
        			printf, lun, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'; , 'Error(Jy)'
        			for dum = 0, n_elements(wl_dum)-1 do printf, lun, format='(2(g16.10,2x))',wl_dum[dum],flux_dum[x,y,dum];,std[x,y,dum]
        			free_lun, lun
        			close, lun

        			openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+band+'_coord.txt',/get_lun
        			printf, lun, format='(3(a16,2x))', 'Wavelength(um)', 'RA(deg)', 'Dec(deg)'
        			for dum = 0, n_elements(wl_dum)-1 do printf, lun, format='(3(g16.12,2x))', wl_dum[dum], ra_dum[x,y,dum], dec_dum[x,y,dum]
        			free_lun, lun
        			close, lun
                endfor
            endfor
        endif

		if i eq 0 then begin
			wl = [wl_dum]
			flux = [flux_dum]
			std = [std_dum]
			ra = [ra_dum]
			dec = [dec_dum]
		endif else begin
			flux = flux[*,*,sort(wl)]
			wl = wl[sort(wl)]
			flux_dum = flux_dum[*,*,sort(wl_dum)]
			std_dum = std_dum[*,*,sort(wl_dum)]
			ra_dum = ra_dum[*,*,sort(wl_dum)]
			dec_dum = dec_dum[*,*,sort(wl_dum)]
			wl_dum = wl_dum[sort(wl_dum)]
;			if (where(wl gt min(wl_dum) and wl lt max(wl_dum)))[0] eq -1 then begin
;				flux = [[[flux]],[[flux_dum]]]
;				std = [[[std]],[[std_dum]]]
;				ra = [[[ra]],[[ra_dum]]]
;				dec = [[[dec]],[[dec_dum]]]
;				wl = [wl,wl_dum]
;			endif else begin
				case 1 of
					max(wl) le min(wl_dum): begin
						wl = [wl,wl_dum]
						flux = [[[flux]],[[flux_dum]]]
						std = [[[std]],[[std_dum]]]
						ra = [[[ra]],[[ra_dum]]]
						dec = [[[dec]],[[dec_dum]]]
					end
					min(wl) ge max(wl_dum): begin
						wl = [wl_dum,wl]
						flux = [[[flux_dum]],[[flux]]]
						std = [[[std_dum]],[[std]]]
						ra = [[[ra]],[[ra_dum]]]
						dec = [[[dec]],[[dec_dum]]]
					end
					(max(wl) gt min(wl_dum)) and (min(wl) lt min(wl_dum)): begin
						;flux = [flux,flux_dum[where(wl_dum gt max(wl))]]
						;wl = [wl,wl_dum[where(wl_dum gt max(wl))]]
						flux = [[[flux[*,*,where(wl lt min(wl_dum))]]], [[flux_dum]]]
						std = [[[std[*,*,where(wl lt min(wl_dum))]]],[[std_dum]]]
						ra = [[[ra[*,*,where(wl lt min(wl_dum))]]], [[ra_dum]]]
						dec = [[[dec[*,*,where(wl lt min(wl_dum))]]], [[dec_dum]]]
						wl = [wl[where(wl lt min(wl_dum))], wl_dum]
					end
					(min(wl) lt max(wl_dum)) and (max(wl) gt max(wl_dum)): begin
						;flux = [flux_dum,flux[where(wl gt max(wl_dum))]]
						;wl = [wl_dum,wl[where(wl gt max(wl_dum))]]
						flux = [[[flux_dum[*,*,where(wl_dum lt min(wl))]]], [[flux]]]
						std = [[[std_dum[*,*,where(wl_dum lt min(wl))]]],[[std]]]
						ra = [[[ra_dum[*,*,where(wl_dum lt min(wl))]]], [[ra]]]
						dec = [[[dec_dum[*,*,where(wl_dum lt min(wl))]]], [[dec]]]
						wl = [wl_dum[where(wl_dum lt min(wl))], wl]
					end
				endcase
;			endelse
		endelse
	endfor
	flux = flux[*,*,sort(wl)]
	std = std[*,*,sort(wl)]
	wl = wl[sort(wl)]
	pix = 1
	for x = 0, 4 do begin
		for y = 0, 4 do begin
			openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'.txt',/get_lun
			printf, lun, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'; , 'Error(Jy)'
			for dum = 0, n_elements(wl)-1 do printf, lun, format='(2(g16.10,2x))',wl[dum],flux[x,y,dum];,std[x,y,dum]
			free_lun, lun
			close, lun

			openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_coord.txt',/get_lun
			printf, lun, format='(3(a16,2x))', 'Wavelength(um)', 'RA(deg)', 'Dec(deg)'
			for dum = 0, n_elements(wl)-1 do printf, lun, format='(3(g16.12,2x))', wl[dum], ra[x,y,dum], dec[x,y,dum]
			free_lun, lun
			close, lun

			; Make a plot

			set_plot, 'ps'
			!p.font=0
			loadct,13,/silent
			!p.thick=3 & !x.thick=3 & !y.thick=3
			device, filename = plotdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
			plot, wl, flux, xtitle = 'Wavelength (!9m!3m)', ytitle = 'Flux Density (Jy)', thick=2;,/nodata
			al_legend, [objname], textcolors=[0], /left
			device, /close_file,decomposed=1
			!p.multi = 0
			pix = pix+1
		endfor
	endfor
endif else begin
	for i = 0, n_elements(filename)-1 do begin
		wl_dum = readfits(filename[i], exten=8,/silent)
		flux_dum = readfits(filename[i], exten=1,/silent)
		std_dum = readfits(filename[i], exten=5,/silent)
		ra_dum = readfits(filename[i], exten=2,/silent)
		dec_dum = readfits(filename[i], exten=3,/silent)
		hdr = headfits(filename[i],/silent)
		band = strtrim(sxpar(hdr,'BAND'),1)
		band = strcompress(band,/remove_all)
		; Save all the information of this object into arrays

		case 1 of
			band eq 'B2A': begin
				wl_b2a = fltarr(5,5,n_elements(where(wl_dum ge 54.80 and wl_dum le b2a_break)))
				flux_b2a = fltarr(5,5,n_elements(where(wl_dum ge 54.80 and wl_dum le b2a_break)))
				std_b2a = fltarr(5,5,n_elements(where(wl_dum ge 54.80 and wl_dum le b2a_break)))
				ra_b2a = fltarr(5,5,n_elements(where(wl_dum ge 54.80 and wl_dum le b2a_break))) & dec_b2a = fltarr(5,5,n_elements(where(wl_dum ge 54.80 and wl_dum le b2a_break)))
				if objname eq 'HD150193' then begin
					wl_b2a = fltarr(5,5,n_elements(where(wl_dum ge 54.80 and wl_dum le 71.75)))
					flux_b2a = fltarr(5,5,n_elements(where(wl_dum ge 54.80 and wl_dum le 71.75)))
					std_b2a = fltarr(5,5,n_elements(where(wl_dum ge 54.80 and wl_dum le 71.75)))
					ra_b2a = fltarr(5,5,n_elements(where(wl_dum ge 54.80 and wl_dum le 71.75))) & dec_b2a = fltarr(5,5,n_elements(where(wl_dum ge 54.80 and wl_dum le 71.75)))
				endif
			end
			band eq 'B2B': begin
				wl_b2b = fltarr(5,5,n_elements(where(wl_dum ge b2a_break and wl_dum le 95.05)))
				flux_b2b = fltarr(5,5,n_elements(where(wl_dum ge b2a_break and wl_dum le 95.05)))
				std_b2b = fltarr(5,5,n_elements(where(wl_dum ge b2a_break and wl_dum le 95.05)))
			    ra_b2b = fltarr(5,5,n_elements(where(wl_dum ge b2a_break and wl_dum le 95.05))) & dec_b2b = fltarr(5,5,n_elements(where(wl_dum ge b2a_break and wl_dum le 95.05)))
			end
			band eq 'R1': begin
				if min(wl_dum) lt 130 then begin
					wl_r1s = fltarr(5,5,n_elements(where(wl_dum ge 103 and wl_dum le 143)))
					flux_r1s = fltarr(5,5,n_elements(where(wl_dum ge 103 and wl_dum le 143)))
					std_r1s = fltarr(5,5,n_elements(where(wl_dum ge 103 and wl_dum le 143)))
					ra_r1s = fltarr(5,5,n_elements(where(wl_dum ge 103 and wl_dum le 143))) & dec_r1s = fltarr(5,5,n_elements(where(wl_dum ge 103 and wl_dum le 143)))
				endif else begin
					wl_r1l = fltarr(5,5,n_elements(where(wl_dum ge 143 and wl_dum le 190.31)))
					flux_r1l = fltarr(5,5,n_elements(where(wl_dum ge 143 and wl_dum le 190.31)))
					std_r1l = fltarr(5,5,n_elements(where(wl_dum ge 143 and wl_dum le 190.31)))
					ra_r1l = fltarr(5,5,n_elements(where(wl_dum ge 143 and wl_dum le 190.31))) & dec_r1l = fltarr(5,5,n_elements(where(wl_dum ge 143 and wl_dum le 190.31)))
				endelse
			end
		endcase

		for x = 0, 4 do begin
			for y = 0, 4 do begin
				flux_dum[x,y,*] = flux_dum[x,y,sort(wl_dum)]
				std_dum[x,y,*] = std_dum[x,y,sort(wl_dum)]
				wl_dum = wl_dum[sort(wl_dum)]
				ra_dum[x,y,*] = ra_dum[x,y,sort(wl_dum)]
				dec_dum[x,y,*] = dec_dum[x,y,sort(wl_dum)]
				case 1 of
					band eq 'B2A': begin
						if objname ne 'HD150193' then begin
							flux_b2a[x,y,*] = flux_dum[x,y,where(wl_dum ge 54.80 and wl_dum le b2a_break)]
							std_b2a[x,y,*] = std_dum[x,y,where(wl_dum ge 54.80 and wl_dum le b2a_break)]
							wl_b2a[x,y,*] = wl_dum[where(wl_dum ge 54.80 and wl_dum le b2a_break)]
							ra_b2a[x,y,*] = ra_dum[x,y,where(wl_dum ge 54.80 and wl_dum le b2a_break)]
							dec_b2a[x,y,*] = dec_dum[x,y,where(wl_dum ge 54.80 and wl_dum le b2a_break)]
						endif else begin
							flux_b2a[x,y,*] = flux_dum[x,y,where(wl_dum ge 54.80 and wl_dum le 71.75)]
							std_b2a[x,y,*] = std_dum[x,y,where(wl_dum ge 54.80 and wl_dum le 71.75)]
							wl_b2a[x,y,*] = wl_dum[where(wl_dum ge 54.80 and wl_dum le 71.75)]
							ra_b2a[x,y,*] = ra_dum[x,y,where(wl_dum ge 54.80 and wl_dum le 71.75)]
							dec_b2a[x,y,*] = dec_dum[x,y,where(wl_dum ge 54.80 and wl_dum le 71.75)]
						endelse
					end
					band eq 'B2B': begin
						flux_b2b[x,y,*] = flux_dum[x,y,where(wl_dum gt b2a_break and wl_dum le 95.05)]
						std_b2b[x,y,*] = std_dum[x,y,where(wl_dum gt b2a_break and wl_dum le 95.05)]
						wl_b2b[x,y,*] = wl_dum[where(wl_dum gt b2a_break and wl_dum le 95.05)]
						ra_b2b[x,y,*] = ra_dum[x,y,where(wl_dum gt b2a_break and wl_dum le 95.05)]
						dec_b2b[x,y,*] = dec_dum[x,y,where(wl_dum gt b2a_break and wl_dum le 95.05)]
					end
					band eq 'R1': begin
						if min(wl_dum) lt 130 then begin
							flux_r1s[x,y,*] = flux_dum[x,y,where(wl_dum ge 103 and wl_dum le 143)]
							std_r1s[x,y,*] = std_dum[x,y,where(wl_dum ge 103 and wl_dum le 143)]
							wl_r1s[x,y,*] = wl_dum[where(wl_dum ge 103 and wl_dum le 143)]
							ra_r1s[x,y,*] = ra_dum[x,y,where(wl_dum ge 103 and wl_dum le 143)]
							dec_r1s[x,y,*] = dec_dum[x,y,where(wl_dum ge 103 and wl_dum le 143)]
						endif else begin
							flux_r1l[x,y,*] = flux_dum[x,y,where(wl_dum gt 143 and wl_dum le 190.31)]
							std_r1l[x,y,*] = std_dum[x,y,where(wl_dum gt 143 and wl_dum le 190.31)]
							wl_r1l[x,y,*] = wl_dum[where(wl_dum gt 143 and wl_dum le 190.31)]
							ra_r1l[x,y,*] = ra_dum[x,y,where(wl_dum gt 143 and wl_dum le 190.31)]
							dec_r1l[x,y,*] = dec_dum[x,y,where(wl_dum gt 143 and wl_dum le 190.31)]
						endelse
					end
				endcase
			endfor
		endfor
	endfor

	for pix =1, 26 do file_delete, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_coord.txt',/allow_nonexistent,/recursive
	pix = 1
	for x = 0, 4 do begin
		for y = 0, 4 do begin
			wl = []
			flux = []
			std = []
			ra = []
			dec = []
			; Write into ACSII file
			openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'.txt',/get_lun
			printf, lun, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'
			if n_elements(wl_b2a) ne 0 then begin
				for dum = 0, n_elements(wl_b2a[x,y,*])-1 do printf, lun, format='(2(g16.10,2x))',wl_b2a[x,y,dum],flux_b2a[x,y,dum]; ,std_b2a[x,y,dum]
				wl = [wl,reform(wl_b2a[x,y,*])] & flux = [flux,reform(flux_b2a[x,y,*])] & std = [std,reform(std_b2a[x,y,*])]
			endif
			if n_elements(wl_b2b) ne 0 then begin
				for dum = 0, n_elements(wl_b2b[x,y,*])-1 do printf, lun, format='(2(g16.10,2x))',wl_b2b[x,y,dum],flux_b2b[x,y,dum]; ,std_b2b[x,y,dum]
				wl = [wl,reform(wl_b2b[x,y,*])] & flux = [flux,reform(flux_b2b[x,y,*])] & std = [std,reform(std_b2b[x,y,*])]
			endif
			if n_elements(wl_r1s) ne 0 then begin
				for dum = 0, n_elements(wl_r1s[x,y,*])-1 do printf, lun, format='(2(g16.10,2x))',wl_r1s[x,y,dum],flux_r1s[x,y,dum]; ,std_r1s[x,y,dum]
				wl = [wl,reform(wl_r1s[x,y,*])] & flux = [flux,reform(flux_r1s[x,y,*])] & std = [std,reform(std_r1s[x,y,*])]
			endif
			if n_elements(wl_r1l) ne 0 then begin
				for dum = 0, n_elements(wl_r1l[x,y,*])-1 do printf, lun, format='(2(g16.10,2x))',wl_r1l[x,y,dum],flux_r1l[x,y,dum]; ,std_r1l[x,y,dum]
				wl = [wl,reform(wl_r1l[x,y,*])] & flux = [flux,reform(flux_r1l[x,y,*])] & std = [std,reform(std_r1l[x,y,*])]
			endif
			free_lun, lun
			close, lun

			; Write the RA & Dec coordinate into ASCII file
			openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_coord.txt',/get_lun
			printf, lun, format='(3(a16,2x))', 'Wavelength(um)', 'RA(deg)', 'Dec(deg)'
			if n_elements(wl_b2a) ne 0 then begin
				for dum = 0, n_elements(wl_b2a[x,y,*])-1 do printf, lun, format='(3(g16.12,2x))',wl_b2a[x,y,dum],ra_b2a[x,y,dum],dec_b2a[x,y,dum]
				wl = [wl,reform(wl_b2a[x,y,*])] & flux = [flux,reform(flux_b2a[x,y,*])]
				ra = [ra,reform(ra_b2a[x,y,*])] & dec = [dec,reform(dec_b2a[x,y,*])]
			endif
			if n_elements(wl_b2b) ne 0 then begin
			    for dum = 0, n_elements(wl_b2b[x,y,*])-1 do printf, lun, format='(3(g16.12,2x))',wl_b2b[x,y,dum],ra_b2b[x,y,dum],dec_b2b[x,y,dum]
			    wl = [wl,reform(wl_b2b[x,y,*])] & flux = [flux,reform(flux_b2b[x,y,*])]
				ra = [ra,reform(ra_b2b[x,y,*])] & dec = [dec,reform(dec_b2b[x,y,*])]
			endif
			if n_elements(wl_r1s) ne 0 then begin
			    for dum = 0, n_elements(wl_r1s[x,y,*])-1 do printf, lun, format='(3(g16.12,2x))',wl_r1s[x,y,dum],ra_r1s[x,y,dum],dec_r1s[x,y,dum]
			    wl = [wl,reform(wl_r1s[x,y,*])] & flux = [flux,reform(flux_r1s[x,y,*])]
				ra = [ra,reform(ra_r1s[x,y,*])] & dec = [dec,reform(dec_r1s[x,y,*])]
			endif
			if n_elements(wl_r1l) ne 0 then begin
			    for dum = 0, n_elements(wl_r1l[x,y,*])-1 do printf, lun, format='(3(g16.12,2x))',wl_r1l[x,y,dum],ra_r1l[x,y,dum],dec_r1l[x,y,dum]
			    wl = [wl,reform(wl_r1l[x,y,*])] & flux = [flux,reform(flux_r1l[x,y,*])]
				ra = [ra,reform(ra_r1l[x,y,*])] & dec = [dec,reform(dec_r1l[x,y,*])]
			endif
			free_lun, lun
			close, lun

            ; For printing out the spectrum of each band separately
            if KEYWORD_SET(separate) then begin
                if n_elements(wl_b2a) ne 0 then begin
                    ; Spectrum
                    openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_b2a.txt',/get_lun
        			printf, lun, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'
                    for dum = 0, n_elements(wl_b2a[x,y,*])-1 do printf, lun, format='(2(g16.10,2x))',wl_b2a[x,y,dum],flux_b2a[x,y,dum]
                    free_lun, lun
                    close, lun
                    ; RA & Dec
                    openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_b2a_coord.txt',/get_lun
        			printf, lun, format='(3(a16,2x))', 'Wavelength(um)', 'RA(deg)', 'Dec(deg)'
                    for dum = 0, n_elements(wl_b2a[x,y,*])-1 do printf, lun, format='(3(g16.12,2x))',wl_b2a[x,y,dum],ra_b2a[x,y,dum],dec_b2a[x,y,dum]
                    free_lun, lun
                    close, lun
                endif
                if n_elements(wl_b2b) ne 0 then begin
                    ; Spectrum
                    openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_b2b.txt',/get_lun
        			printf, lun, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'
                    for dum = 0, n_elements(wl_b2b[x,y,*])-1 do printf, lun, format='(2(g16.10,2x))',wl_b2b[x,y,dum],flux_b2b[x,y,dum]
                    free_lun, lun
                    close, lun
                    ; RA & Dec
                    openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_b2b_coord.txt',/get_lun
        			printf, lun, format='(3(a16,2x))', 'Wavelength(um)', 'RA(deg)', 'Dec(deg)'
                    for dum = 0, n_elements(wl_b2b[x,y,*])-1 do printf, lun, format='(3(g16.12,2x))',wl_b2b[x,y,dum],ra_b2b[x,y,dum],dec_b2b[x,y,dum]
                    free_lun, lun
                    close, lun
                endif
                if n_elements(wl_r1s) ne 0 then begin
                    ; Spectrum
                    openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_r1s.txt',/get_lun
        			printf, lun, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'
                    for dum = 0, n_elements(wl_r1s[x,y,*])-1 do printf, lun, format='(2(g16.10,2x))',wl_r1s[x,y,dum],flux_r1s[x,y,dum]
                    free_lun, lun
                    close, lun
                    ; RA & Dec
                    openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_r1s_coord.txt',/get_lun
        			printf, lun, format='(3(a16,2x))', 'Wavelength(um)', 'RA(deg)', 'Dec(deg)'
                    for dum = 0, n_elements(wl_r1s[x,y,*])-1 do printf, lun, format='(3(g16.12,2x))',wl_r1s[x,y,dum],ra_r1s[x,y,dum],dec_r1s[x,y,dum]
                    free_lun, lun
                    close, lun
                endif
                if n_elements(wl_r1l) ne 0 then begin
                    ; Spectrum
                    openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_r1l.txt',/get_lun
        			printf, lun, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'
                    for dum = 0, n_elements(wl_r1l[x,y,*])-1 do printf, lun, format='(2(g16.10,2x))',wl_r1l[x,y,dum],flux_r1l[x,y,dum]
                    free_lun, lun
                    close, lun
                    ; RA & Dec
                    openw, lun, outdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_r1l_coord.txt',/get_lun
        			printf, lun, format='(3(a16,2x))', 'Wavelength(um)', 'RA(deg)', 'Dec(deg)'
                    for dum = 0, n_elements(wl_r1l[x,y,*])-1 do printf, lun, format='(3(g16.12,2x))',wl_r1l[x,y,dum],ra_r1l[x,y,dum],dec_r1l[x,y,dum]
                    free_lun, lun
                    close, lun
                endif
            endif

			; Make a plot
			set_plot, 'ps'
			!p.font=0
			loadct,13,/silent
			!p.thick=3 & !x.thick=3 & !y.thick=3
			device, filename = plotdir+objname+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
			plot, wl, flux, xtitle = 'Wavelength (!9m!3m)', ytitle = 'Flux Density (Jy)',/nodata
			if n_elements(wl_b2a) ne 0 then oplot, reform(wl_b2a[x,y,*]), reform(flux_b2a[x,y,*]), color=60    , thick=2  ;blue
			if n_elements(wl_b2b) ne 0 then oplot, reform(wl_b2b[x,y,*]), reform(flux_b2b[x,y,*]), color=160   , thick=2  ;green
			if n_elements(wl_r1s) ne 0 then oplot, reform(wl_r1s[x,y,*]), reform(flux_r1s[x,y,*]), color=237   , thick=2  ;orange
			if n_elements(wl_r1l) ne 0 then oplot, reform(wl_r1l[x,y,*]), reform(flux_r1l[x,y,*]), color=250   , thick=2  ;red
			al_legend, ['B2A','B2B','R1A','R1B'],textcolors = [60, 160, 237, 250],/right
			al_legend, [objname], textcolors=[0], /left
			device, /close_file,decomposed=1
			!p.multi = 0
			pix = pix+1
		endfor
	endfor
endelse
end

pro get_pacs_1d, outdir=outdir, objname=objname, filename=filename, central9=central9, centralyes=centralyes,$
	 			 centralno=centralno, linescan=linescan, ra=ra, dec=dec, general=general, datadir=datadir,$
	 			 coorddir=coorddir, trim_detail=trim_detail;, wish=wish
objname = strcompress(objname,/remove_all)
special_list = ['NGC1333-IRAS2A','Serpens-SMM1','G327-06','DR21(OH)','NGC7538-IRS1','NGC6334-I','G34.3+0.1']

if keyword_set(central9) then name = '_central9Spaxels_PointSourceCorrected'
if keyword_set(centralyes) then name = '_centralSpaxel_PointSourceCorrected_CorrectedYES'
if keyword_set(centralno) then name = '_centralSpaxel_PointSourceCorrected_CorrectedNO'

if (where(special_list eq objname))[0] eq -1 then begin


if file_test(coorddir+objname+'_pacs_pixel13_os8_sf7_coord.txt') eq 1 then begin
	readcol, coorddir+objname+'_pacs_pixel13_os8_sf7_coord.txt', format='D,D,D', wl_coord, ra, dec, /silent

	ra = mean(ra)
	dec = mean(dec)
endif else begin
	if not (keyword_set(ra) and keyword_set(dec)) then begin
		print, 'Make sure you have extracted the cube products'
		; read, coordfile, PROMPT='Where is the coordinate file (cube)? (type 0 to escape)'
		coordfile = 0
		if coordfile eq 0 then begin
			ra = 0.0
			dec = 0.0
		endif else begin
			readcol, coordfile, format='D,D,D', wl_coord, ra, dec, /silent
			ra = mean(ra)
			dec = mean(dec)
		endelse
	endif
endelse
if keyword_set(general) then begin
	hdr = headfits(filename[0],/silent)

;	ra = double(sxpar(hdr,'RA'))
;	dec = double(sxpar(hdr,'Dec'))
	wl = []
	flux = []
	for foo = 0, n_elements(filename)-1 do begin
		data = readfits(filename[foo],hdr,exten=1,/silent)
		wl_dum = tbget(hdr, data,1)
		flux_dum = tbget(hdr,data,4)
		std_dum = tbget(hdr,data,5)
		wl_dum = wl_dum[where(finite(flux_dum) eq 1)]
		std_dum = std_dum[where(finite(flux_dum) eq 1)]
		flux_dum = flux_dum[where(finite(flux_dum) eq 1)]
		;print, filename[foo]+'   '+sxpar(hdr, 'BAND')
		;print, min(wl_dum), max(wl_dum)
		if foo eq 0 then begin
			min_wl = [min(wl_dum)]
			ifile = [foo]
		endif else begin
			min_wl = [min_wl, min(wl_dum)]
			ifile = [ifile,foo]
		endelse
	endfor
	ifile = ifile[sort(min_wl)]
	for i = 0, n_elements(ifile)-1 do begin
		data = readfits(filename[ifile[i]],hdr,exten=1,/silent)
		wl_dum = tbget(hdr, data,1)
		flux_dum = tbget(hdr,data,4)
		std_dum = tbgeT(hdr,data,5)
		wl_dum = wl_dum[where(finite(flux_dum) eq 1)]
		std_dum = std_dum[where(finite(flux_dum) eq 1)]
		flux_dum = flux_dum[where(finite(flux_dum) eq 1)]
		if n_elements(wl) eq 0 then begin
			wl = [wl,wl_dum]
			flux = [flux,flux_dum]
			std = [std,std_dum]
		endif else begin
			flux = flux[sort(wl)]
			std = std[sort(wl)]
			wl = wl[sort(wl)]
			flux_dum = flux_dum[sort(wl_dum)]
			std_dum = std_dum[sort(wl_dum)]
			wl_dum = wl_dum[sort(wl_dum)]
			if (where(wl gt min(wl_dum) and wl lt max(wl_dum)))[0] eq -1 then begin
				flux = [flux,flux_dum]
				std = [std,std_dum]
				wl = [wl,wl_dum]
			endif else begin
				case 1 of
					max(wl) le min(wl_dum): begin
						wl = [wl,wl_dum]
						flux = [flux,flux_dum]
						std = [std,std_dum]
					end
					min(wl) ge max(wl_dum): begin
						wl = [wl_dum,wl]
						flux = [flux_dum,flux]
						std = [std_dum,std]
					end
					(max(wl) gt min(wl_dum)) and (min(wl) lt min(wl_dum)): begin
						;flux = [flux,flux_dum[where(wl_dum gt max(wl))]]
						;wl = [wl,wl_dum[where(wl_dum gt max(wl))]]
						flux = [flux[where(wl lt min(wl_dum))], flux_dum]
						std = [std[where(wl lt min(wl_dum))], std_dum]
						wl = [wl[where(wl lt min(wl_dum))], wl_dum]
					end
					(min(wl) lt max(wl_dum)) and (max(wl) gt max(wl_dum)): begin
						;flux = [flux_dum,flux[where(wl gt max(wl_dum))]]
						;wl = [wl_dum,wl[where(wl gt max(wl_dum))]]
						flux = [flux_dum[where(wl_dum lt min(wl))], flux]
						std = [std_dum[where(wl_dum lt min(wl))], std]
						wl = [wl_dum[where(wl_dum lt min(wl))], wl]
					end
				endcase
			endelse
		endelse
	endfor
	flux = flux[sort(wl)]
	std = std[sort(wl)]
	wl = wl[sort(wl)]

	set_plot, 'ps'
	!p.font=0
	loadct,13,/silent
	!p.thick=3 & !x.thick=3 & !y.thick=3
	device, filename = outdir+objname+name+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
	plot, wl, flux, xtitle = 'Wavelength (!9m!3m)', ytitle = 'Flux Density (Jy)', thick=2;,/nodata
	device, /close_file,decomposed=1
	!p.multi = 0
	openw, lun, outdir+objname+name+'_trim.txt',/get_lun
	printf, lun, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'; , 'Error(Jy)'
	for i = 0, n_elements(wl)-1 do printf, lun, format='(2(g16.6,2X))',wl[i],flux[i]; ,std[i]
	free_lun, lun
	close, lun
endif else begin
	hdr = headfits(filename[0],/silent)
;	ra = double(sxpar(hdr,'RA'))
;	dec = double(sxpar(hdr,'Dec'))

	objname = strcompress(objname,/remove_all)
	wl_b2a = [] & flux_b2a = [] & std_b2a = []
	wl_b2b = [] & flux_b2b = [] & std_b2b = []
	wl_r1s = [] & flux_r1s = [] & std_r1s = []
	wl_r1l = [] & flux_r1l = [] & std_r1l = []

	if not keyword_set(linescan) then begin
		for i = 0, n_elements(filename)-1 do begin
			data = readfits(filename[i], hdr, exten=1,/silent)
			band = strtrim(sxpar(hdr,'BAND'),1)
			band = strcompress(band,/remove_all)
			wl_dum = tbget(hdr, data, 1)
			flux_dum = tbget(hdr, data, 4)
			std_dum = tbget(hdr, data, 5)
			flux_dum = flux_dum[sort(wl_dum)]
			std_dum = std_dum[sort(wl_dum)]
			wl_dum = wl_dum[sort(wl_dum)]
			;print, filename[i]+'   '+sxpar(hdr, 'BAND')
			;print, min(wl_dum), max(wl_dum)
			case 1 of
				band eq 'B2A' or band eq 'B3A': begin
					flux_b2a = flux_dum[where(wl_dum ge 54.80 and wl_dum lt 72.3)]
					std_b2a = std_dum[where(wl_dum ge 54.80 and wl_dum lt 72.3)]
					wl_b2a = wl_dum[where(wl_dum ge 54.80 and wl_dum lt 72.3)]
					if keyword_set(trim_detail) then begin
						openw, print_b2a, outdir+objname+name+'_b2a.txt', /get_lun
						printf, print_b2a, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'; , 'Error(Jy)'
						for j = 0, n_elements(wl_dum)-1 do printf, print_b2a, format='(2(g16.6,2X))',wl_dum[j],flux_dum[j];,std_dum[j]
						free_lun, print_b2a
						close, print_b2a
					endif
				end
				band eq 'B2B': begin
					flux_b2b = flux_dum[where(wl_dum ge 72.3 and wl_dum le 95.05)]
					std_b2b = std_dum[where(wl_dum ge 72.3 and wl_dum le 95.05)]
					wl_b2b = wl_dum[where(wl_dum ge 72.3 and wl_dum le 95.05)]
					if keyword_set(trim_detail) then begin
						openw, print_b2b, outdir+objname+name+'_b2b.txt', /get_lun
						printf, print_b2b, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'; , 'Error(Jy)'
						for j = 0, n_elements(wl_dum)-1 do printf, print_b2b, format='(2(g16.6,2X))',wl_dum[j],flux_dum[j];,std_dum[j]
						free_lun, print_b2b
						close, print_b2b
					endif
				end
				band eq 'R1': begin
					if min(wl_dum) lt 130 then begin
						flux_r1s = flux_dum[where(wl_dum ge 103 and wl_dum lt 143)]
						std_r1s = std_dum[where(wl_dum ge 103 and wl_dum lt 143)]
						wl_r1s = wl_dum[where(wl_dum ge 103 and wl_dum lt 143)]
						if keyword_set(trim_detail) then begin
							openw, print_r1s, outdir+objname+name+'_r1s.txt', /get_lun
							printf, print_r1s, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'; , 'Error(Jy)'
							for j = 0, n_elements(wl_dum)-1 do printf, print_r1s, format='(2(g16.6,2X))',wl_dum[j],flux_dum[j];,std_dum[j]
							free_lun, print_r1s
							close, print_r1s
						endif
					endif else begin
						flux_r1l = flux_dum[where(wl_dum ge 143 and wl_dum le 190.31)]
						std_r1l = std_dum[where(wl_dum ge 143 and wl_dum le 190.31)]
						wl_r1l = wl_dum[where(wl_dum ge 143 and wl_dum le 190.31)]
						if keyword_set(trim_detail) then begin
							openw, print_r1l, outdir+objname+name+'_r1l.txt', /get_lun
							printf, print_r1l, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'; , 'Error(Jy)'
							for j = 0, n_elements(wl_dum)-1 do printf, print_r1l, format='(2(g16.6,2X))',wl_dum[j],flux_dum[j];,std_dum[j]
							free_lun, print_r1l
							close, print_r1l
						endif
					endelse
				end
			endcase
		endfor

		wl = [wl_b2a, wl_b2b, wl_r1s, wl_r1l]
		flux = [flux_b2a, flux_b2b, flux_r1s, flux_r1l]
		std = [std_b2a, std_b2b, std_r1s, std_r1l]
		wl = wl[where(flux gt 0)]
		std = std[where(flux gt 0)]
		flux = flux[where(flux gt 0)]
		set_plot, 'ps'
		!p.font=0
		loadct,13,/silent
		!p.thick=3 & !x.thick=3 & !y.thick=3
		device, filename = outdir+objname+name+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 12, decomposed = 0, /color
		plot, wl, flux, xtitle = 'Wavelength (!9m!3m)', ytitle = '!3Flux Density(Jy)!3',/nodata
		;if objname eq 'EC82' then stop
		if n_elements(wl_b2a) gt 1 then oplot, wl_b2a, flux_b2a, color=60 , thick=2   ;blue
		if n_elements(wl_b2b) gt 1 then oplot, wl_b2b, flux_b2b, color=160, thick=2   ;green
		if n_elements(wl_r1s) gt 1 then oplot, wl_r1s, flux_r1s, color=237, thick=2   ;orange
		if n_elements(wl_r1l) gt 1 then oplot, wl_r1l, flux_r1l, color=250, thick=2   ;red
		al_legend, ['B2A','B2B','R1A','R1B'],textcolors = [60, 160, 237, 250],/right
		device, /close_file,decomposed=1
		!p.multi = 0
		openw, lun, outdir+objname+name+'_trim.txt',/get_lun
		printf, lun, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)';, 'Error(Jy)'
		for i = 0, n_elements(wl)-1 do printf, lun, format='(2(g16.6,2X))',wl[i],flux[i];,std[i]
		free_lun, lun
		close, lun
	endif
endelse
endif

if (where(special_list eq objname))[0] ne -1 then begin
	hdr = headfits(filename[0],/silent)
;	ra = double(sxpar(hdr,'RA'))
;	dec = double(sxpar(hdr,'Dec'))
	objname = strcompress(objname,/remove_all)

	if not keyword_set(datadir) then begin
		;datadir = '~/HSA_archive_data/'
		datadir = '~/foryaolun/'
	endif
	if keyword_set(central9) then name = '_central9Spaxels_PointSourceCorrected'
	if keyword_set(centralyes) then name = '_centralSpaxel_PointSourceCorrected_Corrected3x3YES'
	if keyword_set(centralno) then name = '_centralSpaxel_PointSourceCorrected_Corrected3x3NO'
	case 1 of
		objname eq 'NGC1333-IRAS2A': begin
			filename = datadir + ['OBSID_1342190686_NGC1333_IRAS2_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342191149_NGC1333_IRAS2_blue'+name+'_slice_01_os8sf7.fits',$
				                  'OBSID_1342191149_NGC1333_IRAS2_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342191149_NGC1333_IRAS2_red'+name+'_slice_03_os8sf7.fits',$
				                  'OBSID_1342191149_NGC1333_IRAS2_red'+name+'_slice_02_os8sf7.fits','OBSID_1342191149_NGC1333_IRAS2_red'+name+'_slice_01_os8sf7.fits',$
				                  'OBSID_1342191149_NGC1333_IRAS2_red'+name+'_slice_00_os8sf7.fits']
		end
		objname eq 'Serpens-SMM1': begin
			filename = datadir + ['OBSID_1342207781_Ser_SMM1_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342207780_Ser_SMM1_blue'+name+'_slice_01_os8sf7.fits',$
				                  'OBSID_1342207780_Ser_SMM1_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342207780_Ser_SMM1_red'+name+'_slice_03_os8sf7.fits',$
				                  'OBSID_1342207780_Ser_SMM1_red'+name+'_slice_02_os8sf7.fits','OBSID_1342207780_Ser_SMM1_red'+name+'_slice_01_os8sf7.fits',$
				                  'OBSID_1342207780_Ser_SMM1_red'+name+'_slice_00_os8sf7.fits']
		end
		objname eq 'G327-06': begin
			filename = datadir + ['OBSID_1342216202_G327-06_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342216201_G327-06_blue'+name+'_slice_01_os8sf7.fits',$
				                  'OBSID_1342216201_G327-06_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342216201_G327-06_red'+name+'_slice_03_os8sf7.fits',$
				                  'OBSID_1342216201_G327-06_red'+name+'_slice_02_os8sf7.fits','OBSID_1342216201_G327-06_red'+name+'_slice_01_os8sf7.fits',$
				                  'OBSID_1342216202_G327-06_red'+name+'_slice_00_os8sf7.fits']
		end
		objname eq 'DR21(OH)': begin
			filename = datadir + ['OBSID_1342209400_DR21(OH)_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342209401_DR21(OH)_blue'+name+'_slice_01_os8sf7.fits',$
								  'OBSID_1342209401_DR21(OH)_red'+name+'_slice_01_os8sf7.fits','OBSID_1342209401_DR21(OH)_red'+name+'_slice_02_os8sf7.fits',$
								  'OBSID_1342209401_DR21(OH)_red'+name+'_slice_03_os8sf7.fits','OBSID_1342209400_DR21(OH)_red'+name+'_slice_00_os8sf7.fits']
		end
		objname eq 'NGC7538-IRS1':begin

			filename = datadir + ['OBSID_1342258102_NGC7538-IRS1_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342258102_NGC7538-IRS1_red'+name+'_slice_00_os8sf7.fits',$
								  'OBSID_1342258102_NGC7538-IRS1_red'+name+'_slice_01_os8sf7.fits','OBSID_1342258102_NGC7538-IRS1_red'+name+'_slice_02_os8sf7.fits']
		end
		objname eq 'NGC6334-I':begin
			filename = datadir + ['OBSID_1342252275_NGC6334-I_blue'+name+'_slice_00_os8sf7_nojitter.fits','OBSID_1342252275_NGC6334-I_red'+name+'_slice_00_os8sf7_nojitter.fits',$
								  'OBSID_1342252275_NGC6334-I_red'+name+'_slice_01_os8sf7_nojitter.fits','OBSID_1342252275_NGC6334-I_red'+name+'_slice_02_os8sf7_nojitter.fits']
		end
		objname eq 'G34.3+0.1':begin
			filename = datadir + ['OBSID_1342209733_G34.3+0.1_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342209734_G34.3+0.1_blue'+name+'_slice_00_os8sf7.fits',$
								  'OBSID_1342209733_G34.3+0.1_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342209734_G34.3+0.1_red'+name+'_slice_00_os8sf7.fits']
		end
		objname eq 'W28A':begin
			filename = datadir + ['OBSID_1342217940_W28A_blue'+name+'_slice_00_os8sf7_nojitter.fits','OBSID_1342217940_W28A_red'+name+'_slice_00_os8sf7_nojitter.fits',$
								  'OBSID_1342217941_W28A_blue'+name+'_slice_00_os8sf7.fits','OBSID_1342217941_W28A_red'+name+'_slice_00_os8sf7.fits']
		end
	endcase

	wl = [] & flux = [] & std = []

	wl_b3a = [] & flux_b3a = [] & std_b3a = []
	wl_b2b_1 = [] & flux_b2b_1 = [] & std_b2b_1 = []
	wl_b2b_2 = [] & flux_b2b_2 = [] & std_b2b_2 = []
	wl_r1_1 = [] & flux_r1_1 = [] & std_r1_1 = []
	wl_r1_2 = [] & flux_r1_2 = [] & std_r1_2 = []
	wl_r1_3 = [] & flux_r1_3 = [] & std_r1_3 = []
	wl_r1_4 = [] & flux_r1_4 = [] & std_r1_4 = []
	if not keyword_set(linescan) then begin
		for i = 0, n_elements(filename)-1 do begin
			data = readfits(filename[i], hdr, exten=1,/silent)
			band = strtrim(sxpar(hdr,'BAND'),1)
			band = strcompress(band,/remove_all)
			wl_dum = tbget(hdr, data, 1)
			flux_dum = tbget(hdr, data, 4)
			std_dum = tbget(hdr, data, 5)
			flux_dum = flux_dum[sort(wl_dum)]
			std_dum = std_dum[sort(wl_dum)]
			wl_dum = wl_dum[sort(wl_dum)]
			;print, filename[i]+'   '+sxpar(hdr, 'BAND')
			;print, min(wl_dum), max(wl_dum)
			if i eq 0 then begin
				wl = [wl, wl_dum]
				flux = [flux, flux_dum]
				std = [std,std_dum]
			endif else begin
				wl = [wl[where(wl lt min(wl_dum))], wl_dum]
				flux = [flux[where(wl lt min(wl_dum))], flux_dum]
				std = [std[where(wl lt min(wl_dum))], std_dum]
			endelse

		endfor
		wl = wl[where(flux gt 0)]
		std = std[where(flux gt 0)]
		flux = flux[where(flux gt 0)]
		ind = where((wl ge 54.80 and wl le 95.05) or (wl ge 103 and wl le 190.31))
		wl = wl[ind]
		flux = flux[ind]
		std = std[ind]
		set_plot, 'ps'
		!p.font=0
		loadct,13,/silent
		!p.thick=3 & !x.thick=3 & !y.thick=3
		device, filename = outdir+objname+name+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
		plot, wl, flux, xtitle = 'Wavelength (!9m!3m)', ytitle = 'Flux Density (Jy)', thick=2;,/nodata
		device, /close_file,decomposed=1
		!p.multi = 0

		if keyword_set(central9) then name = '_central9Spaxels_PointSourceCorrected'
		if keyword_set(centralyes) then name = '_centralSpaxel_PointSourceCorrected_CorrectedYES'
		if keyword_set(centralno) then name = '_centralSpaxel_PointSourceCorrected_CorrectedNO'

		openw, lun, outdir+objname+name+'_trim.txt',/get_lun
		printf, lun, format='(2(a16,2x))', 'Wavelength(um)', 'Flux_Density(Jy)'; , 'Error(Jy)'
		for i = 0, n_elements(wl)-1 do printf, lun, format='(2(g16.6,2X))',wl[i],flux[i]; ,std[i]
		free_lun, lun
		close, lun
	endif
endif

if keyword_set(linescan) then begin
	data = readfits(indir+filename+'.fits', hdr, exten=1)
	wl = tbget(hdr, data, 1) & print, min(wl), max(wl)
	flux = tbget(hdr, data, 4)
	std = tbget(hdr, data, 5)
	flux = flux[sort(wl)]
	std = std[sort(wl)]
	wl = wl[sort(wl)]
	;suffix = strtrim(string(min(wl)),1)+'_'+strtrim(string(max(wl)),1)
	openw, lun, indir+'linescan_'+filename+'.txt', /get_lun
endif

;for j = 0, n_elements(wl)-1 do begin
;	if ((wl[j] ge 54.8) and (wl[j] le 95.1)) or ((wl[j] ge 101.6) and (wl[j] le 190.3)) then printf, lun, format='(2(g16.8,2x))', wl[j],flux[j]
;endfor
;free_lun, lun
;close, lun
end

pro get_pacs_linescan,indir=indir,outdir=outdir, plotdir=plotdir, aor_name=aor_name,slice=slice,greg=greg,cube=cube

band = ['blue','blue','red','red']
reduction = ['_central9Spaxels_PointSourceCorrected_slice_0','_centralSpaxel_PointSourceCorrected_Corrected3x3NO_slice_0','_centralSpaxel_PointSourceCorrected_Corrected3x3YES_slice_0']

for rec = 0, n_elements(reduction)-1 do begin
	for iband = 0, n_elements(band)-1 do begin
		for i_slice = 0, slice[iband] do begin
			filename = 'OBSID_' + aor_name[iband] +'_'+ band[iband] +'_BackNorm'+ reduction[rec] + strtrim(string(i_slice),1); + '_os7sf3'
			if keyword_set(greg) then filename = aor_name[iband]+'v13os4_'+band[iband]+'norm_sl'+strtrim(string(i_slice),1)
			print, filename
			if not keyword_set(cube) then get_pacs_1d, indir=indir, filename=filename,/linescan
			if keyword_set(cube) then get_pacs, filename=filename+'.fits', indir=indir, outdir=outdir, plotdir=plotdir
		endfor
	endfor
endfor
end
