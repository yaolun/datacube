pro plot_contour, noise=noise, no_plot=no_plot,indir=indir,plotdir=plotdir,objname=objname,spire=spire,pacs=pacs,verbose=verbose,brightness=brightness,fx=fx,plot_irs2=plot_irs2
if file_test(plotdir,/directory) eq 0 then file_mkdir,plotdir

; determine flux unit
if keyword_set(brightness) then begin
  	unit = '!n arcsec!u-2!n'
  	fx=0
  	; default setting is extracting SPIRe spectra with brightness keyword, therefore the unit is already in /arcsec2
  	beam_slw = 1
  	beam_ssw = 1
  	beam_pacs = !pi*(9.4/2.0)^2
endif
if keyword_set(fx) then begin
  	unit = ''
  	brightness=0
  	beam_slw = 1
  	beam_ssw = 1
  	beam_pacs = 1
endif
;Construct the data structure in each band
if keyword_set(spire) then begin
  	;SPIRE
  	;SLW
  	pixelname = ['SLWA1','SLWA2','SLWA3','SLWB1','SLWB2','SLWB3','SLWB4','SLWC1','SLWC2','SLWC3','SLWC4','SLWC5','SLWD1','SLWD2','SLWD3','SLWD4','SLWE1','SLWE2','SLWE3']
  	suffix = '_lines.txt'
  	if file_test(indir+objname+'_SLWC3'+suffix) eq 0 then suffix = '_lines.txt'
  	readcol, indir+objname+'_SLWC3'+suffix, format='A,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,A,A,D', name, lab_wl, wl, sig_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, E_u, A, g, ra, dec, pixel, blend, validity,/silent,skipline=1
  	ra_cen_slw = ra
  	dec_cen_slw = dec
  	data_slw = replicate({line:strarr(n_elements(name)), ra: dblarr(n_elements(ra)), dec: dblarr(n_elements(dec)), lab_wl:dblarr(n_elements(lab_wl)), wl:dblarr(n_elements(wl)), flux: dblarr(n_elements(str)), flux_sig: dblarr(n_elements(sig_str)),$
  		  fwhm: dblarr(n_elements(fwhm)), snr: dblarr(n_elements(snr)), base_str: dblarr(n_elements(base_str)), validity: dblarr(n_elements(validity))},n_elements(pixelname))
  	for pix = 0, n_elements(pixelname)-1 do begin
      	readcol, indir+objname+'_'+pixelname[pix]+suffix, format='A,D,D,D,D, D,D,D,D,D, D,D,D,D,D, D,A,A,D', name, lab_wl, wl, sig_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, E_u, A, g, ra, dec, pixel, blend, validity,/silent,skipline=1
		; beam size = 35"
		data_slw[pix].line = name
		data_slw[pix].lab_wl = lab_wl
		data_slw[pix].wl = wl
		data_slw[pix].flux = str / beam_slw
		data_slw[pix].flux_sig = sig_str / beam_slw
		data_slw[pix].fwhm = fwhm
		data_slw[pix].ra = ra
		data_slw[pix].dec = dec
		data_slw[pix].snr = snr
		data_slw[pix].validity = validity
		for i = 0, n_elements(base_str)-1 do if base_str[i] lt 0 then base_str[i] = 0
		data_slw[pix].base_str = base_str*fwhm / beam_slw ;*2.354    ; Use a top-hat function to calculate the baseline strength under the line
  	endfor
  	;SSW
  	pixelname = ['SSWA1','SSWA2','SSWA3','SSWA4','SSWB1','SSWB2','SSWB3','SSWB4','SSWB5','SSWC1','SSWC2','SSWC3','SSWC4','SSWC5','SSWC6','SSWD1','SSWD2','SSWD3','SSWD4','SSWD6','SSWD7','SSWE1','SSWE2','SSWE3','SSWE4','SSWE5','SSWE6','SSWF1','SSWF2','SSWF3','SSWF5','SSWG1','SSWG2','SSWG3','SSWG4']
  	readcol, indir+objname+'_SSWD4'+suffix, format='A,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,A,A,D', name, lab_wl, wl, sig_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, E_u, A, g, ra, dec, pixel, blend, validity,/silent,skipline=1
  	ra_cen_ssw = ra
  	dec_cen_ssw = dec
  	data_ssw = replicate({line:strarr(n_elements(name)), ra: dblarr(n_elements(ra)), dec: dblarr(n_elements(dec)), lab_wl:dblarr(n_elements(lab_wl)), wl:dblarr(n_elements(wl)), flux: dblarr(n_elements(str)), flux_sig: dblarr(n_elements(sig_str)),$
  		  fwhm: dblarr(n_elements(fwhm)), snr: dblarr(n_elements(snr)), base_str: dblarr(n_elements(base_str)), validity: dblarr(n_elements(validity))}, n_elements(pixelname))
  	for pix = 0, n_elements(pixelname)-1 do begin
      	readcol, indir+objname+'_'+pixelname[pix]+suffix, format='A,D,D,D,D, D,D,D,D,D, D,D,D,D,D, D,A,A,D', name, lab_wl, wl, sig_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, E_u, A, g, ra, dec, pixel, blend, validity,/silent,skipline=1
		; beam size = 19"
		data_ssw[pix].line = name
		data_ssw[pix].lab_wl = lab_wl
		data_ssw[pix].wl = wl
		data_ssw[pix].flux = str / beam_ssw
		data_ssw[pix].flux_sig = sig_str / beam_ssw
		data_ssw[pix].fwhm = fwhm
		data_ssw[pix].ra = ra
		data_ssw[pix].dec = dec
		data_ssw[pix].snr = snr
		data_ssw[pix].validity = validity
		for i = 0, n_elements(base_str)-1 do if base_str[i] lt 0 then base_str[i] = 0
		data_ssw[pix].base_str = base_str*fwhm / beam_ssw ;*2.354    ; Use a top-hat function to calculate the baseline strength under the line
  	endfor
endif
if keyword_set(pacs) then begin
  	;PACS
  	suffix = '_mixed_lines.txt'
  	if file_test(indir+objname+'_pacs_pixel13'+suffix) eq 0 then suffix = '_os8_sf7_lines.txt'
  	if file_test(indir+objname+'_pacs_pixel13'+suffix) eq 0 then suffix = '_hsa_lines.txt'
  	readcol, indir+objname+'_pacs_pixel13'+suffix, format='A,D,D,D,D, D,D,D,D,D, D,D,D,D,D, D,A,A,D', name, lab_wl, wl, sig_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, E_u, A, g, ra, dec, pixel, blend, validity,/silent,skipline=1
  	ra_cen_pacs = ra
  	dec_cen_pacs = dec
  	data_pacs = replicate({line:strarr(n_elements(name)), ra: dblarr(n_elements(ra)), dec: dblarr(n_elements(dec)), lab_wl:dblarr(n_elements(lab_wl)), wl:dblarr(n_elements(wl)), flux: dblarr(n_elements(str)), flux_sig: dblarr(n_elements(sig_str)),$
  		  fwhm: dblarr(n_elements(fwhm)), snr: dblarr(n_elements(snr)), base_str: dblarr(n_elements(base_str)), validity: dblarr(n_elements(validity))}, 25)

  	for pix = 0, 24 do begin
      	readcol, indir+objname+'_pacs_pixel'+strtrim(string(pix+1),1)+suffix, format='A,D,D,D,D, D,D,D,D,D, D,D,D,D,D, D,A,A,D', name, lab_wl, wl, sig_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, E_u, A, g, ra, dec, pixel, blend, validity,/silent,skipline=1
		data_pacs[pix].line = name
		data_pacs[pix].lab_wl = lab_wl
		data_pacs[pix].wl = wl
		data_pacs[pix].flux = str / beam_pacs
		data_pacs[pix].flux_sig = sig_str / beam_pacs
		data_pacs[pix].fwhm = fwhm
		data_pacs[pix].ra = ra
		data_pacs[pix].dec = dec
		data_pacs[pix].snr = snr
		data_pacs[pix].validity = validity
		for i = 0, n_elements(base_str)-1 do if base_str[i] lt 0 then base_str[i] = 0
		data_pacs[pix].base_str = base_str*fwhm / beam_pacs ;*2.354    ; Use a top-hat function to calculate the baseline strength under the line
  	endfor

endif

if not keyword_set(no_plot) then begin
    ;Plot the contour for each band
  	if keyword_set(spire) then begin
		;SPIRE
		;Create the line name
		line_name_oh2o = ['o-H2O5_23-5_14','o-H2O6_25-5_32','o-H2O8_45-9_18','o-H2O8_27-7_34','o-H2O7_43-6_52','o-H2O8_54-7_61','o-H2O3_21-3_12','o-H2O6_34-5_41','o-H2O3_12-2_21','o-H2O7_25-8_18',$
                      'o-H2O3_12-3_03','o-H2O5_32-4_41','o-H2O1_10-1_01'];,'o-H2O4_23-3_30'
		line_center_oh2o = [212.5309344,226.7664669,229.2112944,231.2537873,234.5364534,256.5992833,257.8011350,258.8222114,259.9887495,261.4637873,$
							          273.1998800,483.0021428,538.3023584];,669.1946510

		line_name_ph2o = ['p-H2O7_26-6_33','p-H2O9_46-10_1_9','p-H2O7_44-8_17','p-H2O2_20-2_11','p-H2O4_22-4_13','p-H2O8_53-7_62','p-H2O7_44-6_51','p-H2O1_11-0_00','p-H2O2_02-1_11','p-H2O5_24-4_31',$
						          'p-H2O4_22-3_31','p-H2O9_28-8_35','p-H2O2_11-2_02','p-H2O6_24-7_17','p-H2O5_33-4_40','p-H2O6_42-5_51']
		line_center_ph2o = [208.0814648,208.9186114,222.9532762,243.9800446,248.2530166,251.7573722,255.6872873,269.2790845,303.4638096,308.9717523,$
                        327.2312598,330.8298372,398.6525967,613.7265992,631.5709820,636.6680083]

		line_name_co = ['CO13-12','CO12-11','CO11-10','CO10-9','CO9-8','CO8-7','CO7-6','CO6-5','CO5-4','CO4-3']
		line_center_co = [200.27751475,216.93275100,236.61923625,260.24634206,289.12760810,325.23334516,371.65973939,433.56713410,520.24411585,650.26787364]

        line_name_13co = ['13CO13-12','13CO12-11','13CO11-10','13CO10-9','13CO9-8','13CO8-7','13CO7-6','13CO6-5','13CO5-4']
    	line_center_13co = [209.481440501,226.903680083,247.496622503,272.21147644,302.422210195,340.18977646,388.752815449,453.509061166,544.174435197]

        line_name_hco = ['HCO+16-15','HCO+15-14','HCO+14-13','HCO+13-12','HCO+12-11','HCO+11-10','HCO+10-9','HCO+9-8','HCO+8-7','HCO+7-6','HCO+6-5']
    	line_center_hco = [210.28816791,224.28135601,240.27541266,258.73206751,280.26711943,305.71952487,336.26530802,373.60195435,420.27521465,480.28810368,560.30913387]

        line_name_other = ['NII_205','CI3P2-3P0','CI3P2-3P1','CI3P1-3P0'];,'Unknown_221.3','Unknown_225.2']
    	line_center_other = [205.178,230.349132,370.424383,609.150689];,221.3,225.2]

        line_name_spire = [line_name_oh2o,line_name_ph2o,line_name_co,line_name_13co,line_name_hco,line_name_other]
		line_center_spire = [line_center_oh2o,line_center_ph2o,line_center_co,line_center_13co,line_center_hco,line_center_other]
		line_name_slw = line_name_spire[where(line_center_spire gt 314)]
		line_name_ssw = line_name_spire[where(line_center_spire lt 314)]
		;SLW
		;line_name = ['p-H2O2_02-1_11','CO8-7','13CO8-7','CO7-6','CI370','13CO7-6','p-H2O2_11-2_02','CO6-5','13CO6-5','HCO+P7-6','CO5-4','o-H2O1_10-1_01','13CO5-4','CI610','CO4-3']
		line_name = line_name_slw
		if keyword_set(verbose) then print, 'contour plots for SPIRE-SLW'
		for i = 0, n_elements(line_name)-1 do begin
  			wl = []
  			flux = []
  			flux_sig = []
  			base_str = []
  			snr = []
  			ra = []
  			ra_tot = []
  			dec = []
  			dec_tot = []
  			for pix = 0, n_elements(data_slw[*].ra[0])-1 do begin
				; read in the central position
				if pix eq 9 then begin
  					ra_cen = ra_cen_slw[where(data_slw[pix].line eq line_name[i])]
  					dec_cen = dec_cen_slw[where(data_slw[pix].line eq line_name[i])]
				endif

				data_ind = where(data_slw[pix].line eq line_name[i])
				ra_tot = [ra_tot, data_slw[pix].ra[data_ind]]
				dec_tot = [dec_tot, data_slw[pix].dec[data_ind]]
				base_str = [base_str, data_slw[pix].base_str[data_ind]]
				; exclude absorption lines
				; set every absorption line to zero
				if (data_slw[pix].flux[data_ind] lt 0) or (data_slw[pix].snr[data_ind] lt 3d0) or (data_ind eq -1) or (data_slw[pix].validity[data_ind] eq 0) then begin
  					wl = [wl, data_slw[pix].wl[data_ind]]
  					flux = [flux, 0]
  					flux_sig = [flux_sig, 0]
  					snr = [snr, data_slw[pix].snr[data_ind]]
  					ra = [ra, data_slw[pix].ra[data_ind]]
  					dec = [dec, data_slw[pix].dec[data_ind]]
				endif else begin
  					wl = [wl, data_slw[pix].wl[data_ind]]
  					flux = [flux, data_slw[pix].flux[data_ind]]
  					flux_sig = [flux_sig, data_slw[pix].flux_sig[data_ind]]
  					snr = [snr, data_slw[pix].snr[data_ind]]
  					ra = [ra, data_slw[pix].ra[data_ind]]
  					dec = [dec, data_slw[pix].dec[data_ind]]
				endelse
  			endfor

  			if (n_elements(flux[where(flux ne 0)]) ge 1) and ((where(flux ne 0))[0] ne -1) then begin
                if keyword_set(verbose) then print, 'Plotting ',objname,'-',line_name[i]
				set_plot, 'ps'
				!p.font = 0
				device, filename = plotdir+objname+'_'+line_name[i]+'_contour.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
				loadct,13,/silent
				!p.thick = 4 & !x.thick = 5 & !y.thick = 5
				if (where(flux_sig gt 1))[0] ne -1 then flux_sig[where(flux_sig gt 1)] = 0
				noisefloor = median(flux/snr*noise)
				level = indgen(6)/5.*(max(flux)-min(flux[where(flux ne 0)]))+min(flux[where(flux ne 0)])
				level = level[sort(level)]
				if max(flux) ne min(flux[where(flux ne 0)]) then begin
                    level = level[1:-1]
    		    endif else begin
  		        	ind = where(flux eq max(flux))
  		        	noise = flux[ind]/snr[ind]
  		        	level = indgen(6)/5.*max(flux)
  		        	level = level[where(level ge 3*noise[0])]
  		        	if 3*noise ge max(flux) then stop
    		    endelse
				ra = (ra-ra_cen[0])*3600*cos(dec*!pi/180.)
				dec = (dec-dec_cen[0])*3600
				ra_tot = (ra_tot-ra_cen[0])*3600*cos(dec_tot*!pi/180.)
				dec_tot = (dec_tot-dec_cen[0])*3600
				flux_smooth = min_curve_surf(flux,ra,dec,/double);,nx=100,ny=100)
				base_str_smooth = min_curve_surf(base_str,ra_tot,dec_tot,/double);,nx=100,ny=100)
				base_str_smooth[where(base_str_smooth lt 0)] = 0
				base_str_smooth = rotate(base_str_smooth,5)
				ra_smooth = min_curve_surf(ra,ra,dec,/double);,nx=100,ny=100)
				dec_smooth = min_curve_surf(dec,ra,dec,/double);,nx=100,ny=100)
				ra_tot_smooth = min_curve_surf(ra_tot,ra_tot,dec_tot,/double);,nx=100,ny=100)
				dec_tot_smooth = min_curve_surf(dec_tot,ra_tot,dec_tot,/double);,nx=100,ny=100)

				plotposition = [0.15,0.15,0.95,0.9]
				position = [0.5*(120-max(ra_tot_smooth[*,0]))/120+plotposition[0], 0.5*(120+min(dec_tot_smooth[0,*]))/120+plotposition[1],$
							plotposition[2]-0.5*(min(ra_tot_smooth[*,0])+120)/120, plotposition[3]-0.5*(120-max(dec_tot_smooth[0,*]))/120]
				loadct, 13, /silent
        		cgplot, ra_tot, dec_tot, psym=1,xrange=[120,-120],yrange=[-120,120], position=plotposition,/nodata,color=255,xtitle='!nRA offset (arcsec)',ytitle='!nDec offset (arcsec)',aspect=1.0
		        colorFile = '~/programs/misc/fsc_brewer.tbl';Filepath(SUBDIRECTORY=['resource','colors'], 'fsc_brewer.tbl')
		        cgloadct, 10, /reverse, file=colorfile, /silent
		        cgimage, base_str_smooth/max(base_str_smooth)*255,/overplot,$
		        		     oposition=oposition,/keep_aspect_ratio,alphafgposition=position,$;, xrange=[30,-30], yrange=[-30,30]
		        		     xrange=[max(ra_tot_smooth[*,0]), min(ra_tot_smooth[*,0])],$
		        		     yrange=[min(dec_tot_smooth[0,*]), max(dec_tot_smooth[0,*])]
		        op = oposition
    			cgcolorbar,range=[0,max(base_str_smooth)/1e-22],/vertical,/right,Position=[plotposition[2]+0.03,plotposition[1],plotposition[2]+0.055,plotposition[3]],title='!3I!dbase!n [10!u-18!n W m!u-2!n'+unit+']'
		        loadct, 13, /silent
        		cgplot, ra_tot, dec_tot, psym=1,color=0, symsize=1.5, position=oposition, /overplot
		        ; if encounter an error skip this one and keep going
		        catch, error_status
		        if error_status ne 0 then begin
                    if !error_state.msg eq 'Program caused arithmetic error: Floating illegal operand' then continue
  		        	print, 'Object: ', objname, ' Line: ',line_name[i]
  		        	print, !error_state.msg
  		        	file_delete, plotdir+objname+'_'+line_name[i]+'_contour.eps',/allow_nonexistent,/verbose
                goto, exit_slw
		        endif
		        if n_elements(flux[where(flux ne 0)]) ge 3 then begin
  		        	cgplot, ra_tot, dec_tot, psym=1,color=0, symsize=1.5, position=oposition, /overplot;,xrange=[140,-140],yrange=[-140,140], position=plotposition, /overplot
  		        	cgplot, ra_tot[where(flux ne 0)], dec_tot[where(flux ne 0)], psym=1, color=160, symsize=1.5, position=oposition, /overplot
                    cgplot, [0], [0], psym=1, color=250, symsize=1.5, position=oposition, /overplot
  		        	cgcontour, flux_smooth, ra_smooth, dec_smooth, levels=level, /irregular, /noerase, color='blue',/onimage,label=0
		        endif else begin
  		        	cgplot, ra_tot, dec_tot, psym=1,color=0, symsize=1.5, position=oposition, /overplot
  		        	cgplot, ra_tot[where(flux ne 0)], dec_tot[where(flux ne 0)], psym=1, color=160, symsize=1.5, position=oposition, /overplot
                    cgplot, [0], [0], psym=1, color=250, symsize=1.5, position=oposition, /overplot
  		        	cgcontour, flux_smooth, ra_smooth, dec_smooth, levels=level, /noerase, /onimage, color=0,/nodata,label=0
		        endelse
		        if keyword_set(plot_irs2) then begin
		            cgplot, (plot_irs2[0]-ra_cen[0])*3600.*cos(plot_irs2[1]*!pi/180.), (plot_irs2[1]-dec_cen[0])*3600., psym=7, color=110, symsize=1.5, position=oposition, /overplot  ; light blue
		        endif
		        loadct, 0, /silent
		        ; place it in the upper right
		        al_legend,['!3'+title_name(line_name[i])+'!n'],textcolors=[0], box=0, charsize=1.5,pos=[0.55,0.87],/normal
		        al_legend,['!3'+objname+'!n'],textcolors=[0], box=0, charsize=1.5, pos=[0.3,0.87],/normal
		        exit_slw:
		        device, /close_file, decomposed = 1
		        !p.multi = 0
		        cleanplot,/silent
  			endif
		endfor
		;SSW
		if keyword_set(verbose) then print, 'contour plots for SPIRE-SSW'
		line_name = line_name_ssw
		for i = 0, n_elements(line_name)-1 do begin
  			wl = []
  			flux = []
  			flux_sig = []
  			base_str = []
  			snr = []
  			ra = []
  			ra_tot = []
  			dec = []
  			dec_tot = []
  			for pix = 0, n_elements(data_ssw[*].ra[0])-1 do begin
				; read in the central position
				if pix eq 18 then begin
  					ra_cen = ra_cen_ssw[where(data_ssw[pix].line eq line_name[i])]
  					dec_cen = dec_cen_ssw[where(data_ssw[pix].line eq line_name[i])]
				endif

				data_ind = where(data_ssw[pix].line eq line_name[i])
				ra_tot = [ra_tot, data_ssw[pix].ra[data_ind]]
				dec_tot = [dec_tot, data_ssw[pix].dec[data_ind]]
				base_str = [base_str, data_ssw[pix].base_str[data_ind]]
				; exclude absorption lines
				; set every absorption line to zero
				if (data_ssw[pix].flux[data_ind] lt 0) or (data_ssw[pix].snr[data_ind] lt 3) or (data_ind eq -1) or (data_ssw[pix].validity[data_ind] eq 0) then begin
  					wl = [wl, data_ssw[pix].wl[data_ind]]
  					flux = [flux, 0]
  					flux_sig = [flux_sig, 0]
  					snr = [snr, data_ssw[pix].snr[data_ind]]
  					ra = [ra, data_ssw[pix].ra[data_ind]]
  					dec = [dec, data_ssw[pix].dec[data_ind]]
				endif else begin
  					wl = [wl, data_ssw[pix].wl[data_ind]]
  					flux = [flux, data_ssw[pix].flux[data_ind]]
  					flux_sig = [flux_sig, data_ssw[pix].flux_sig[data_ind]]
  					snr = [snr, data_ssw[pix].snr[data_ind]]
  					ra = [ra, data_ssw[pix].ra[data_ind]]
  					dec = [dec, data_ssw[pix].dec[data_ind]]
				endelse
  			endfor

  			if (n_elements(flux[where(flux ne 0)]) ge 1) and ((where(flux ne 0))[0] ne -1) then begin
				if keyword_set(verbose) then print, 'Plotting ',objname,'-',line_name[i]
				set_plot, 'ps'
				!p.font = 0
				device, filename = plotdir+objname+'_'+line_name[i]+'_contour.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
				loadct,13,/silent
				!p.thick = 4 & !x.thick = 5 & !y.thick = 5
				if (where(flux_sig gt 1))[0] ne -1 then flux_sig[where(flux_sig gt 1)] = 0
				noisefloor = median(flux/snr*noise)
				level = indgen(6)/5.*(max(flux)-min(flux[where(flux ne 0)]))+min(flux[where(flux ne 0)])
				level = level[sort(level)]
				if max(flux) ne min(flux[where(flux ne 0)]) then begin
		        	level = level[1:-1]
                endif else begin
    	        	ind = where(flux eq max(flux))
    	        	noise = flux[ind]/snr[ind]
    	        	level = indgen(6)/5.*max(flux)
    	        	level = level[where(level ge 3*noise[0])]
    	        	if 3*noise ge max(flux) then stop
                endelse
				ra = (ra-ra_cen[0])*3600*cos(dec*!pi/180.)
				dec = (dec-dec_cen[0])*3600
				ra_tot = (ra_tot-ra_cen[0])*3600*cos(dec_tot*!pi/180.)
				dec_tot = (dec_tot-dec_cen[0])*3600
				flux_smooth = min_curve_surf(flux,ra,dec,/double);,nx=100,ny=100)
				base_str_smooth = min_curve_surf(base_str,ra_tot,dec_tot,/double);,nx=100,ny=100)
				base_str_smooth[where(base_str_smooth lt 0)] = 0
				base_str_smooth = rotate(base_str_smooth,5)
				ra_smooth = min_curve_surf(ra,ra,dec,/double);,nx=100,ny=100)
				dec_smooth = min_curve_surf(dec,ra,dec,/double);,nx=100,ny=100)
				ra_tot_smooth = min_curve_surf(ra_tot,ra_tot,dec_tot,/double);,nx=100,ny=100)
				dec_tot_smooth = min_curve_surf(dec_tot,ra_tot,dec_tot,/double);,nx=100,ny=100)

				plotposition = [0.15,0.15,0.95,0.9]
				position = [0.5*(100-max(ra_tot_smooth[*,0]))/120+plotposition[0], 0.5*(120+min(dec_tot_smooth[0,*]))/120+plotposition[1],$
							     plotposition[2]-0.5*(min(ra_tot_smooth[*,0])+120)/120, plotposition[3]-0.5*(120-max(dec_tot_smooth[0,*]))/120]
				loadct, 13, /silent
        		cgplot, ra_tot, dec_tot, psym=1,xrange=[120,-120],yrange=[-120,120], position=plotposition,/nodata,color=255,xtitle='!nRA offset (arcsec)',ytitle='!nDec offset (arcsec)',aspect=1.0
		        colorFile = '~/programs/misc/fsc_brewer.tbl';Filepath(SUBDIRECTORY=['resource','colors'], 'fsc_brewer.tbl')
		        cgloadct, 10, /reverse, file=colorfile, /silent
		        cgimage, base_str_smooth/max(base_str_smooth)*255,/overplot,$
		        		     oposition=oposition,/keep_aspect_ratio,alphafgposition=position,$;, xrange=[30,-30], yrange=[-30,30]
		        		     xrange=[max(ra_tot_smooth[*,0]), min(ra_tot_smooth[*,0])],$
		        		     yrange=[min(dec_tot_smooth[0,*]), max(dec_tot_smooth[0,*])]
		        op = oposition
    			cgcolorbar,range=[0,max(base_str_smooth)/1e-22],/vertical,/right,Position=[plotposition[2]+0.03,plotposition[1],plotposition[2]+0.055,plotposition[3]],title='I!dbase!n [10!u-18!n W m!u-2!n'+unit+']'
		        loadct, 13, /silent
        		cgplot, ra_tot, dec_tot, psym=1,color=0, symsize=1.5, position=oposition, /overplot
		        ; if encounter an error skip this one and keep going
		        catch, error_status
		        if error_status ne 0 then begin
                    if !error_state.msg eq 'Program caused arithmetic error: Floating illegal operand' then continue
  		        	print, 'Object: ', objname, ' Line: ',line_name[i]
  		        	print, !error_state.msg
  		        	file_delete, plotdir+objname+'_'+line_name[i]+'_contour.eps',/allow_nonexistent,/verbose
                goto, exit_ssw
    		    endif
		        if n_elements(flux[where(flux ne 0)]) ge 3 then begin
  		        	cgplot, ra_tot, dec_tot, psym=1,color=0, symsize=1.5, position=oposition, /overplot;,xrange=[140,-140],yrange=[-140,140], position=plotposition, /overplot
  		        	cgplot, ra_tot[where(flux ne 0)], dec_tot[where(flux ne 0)], psym=1, color=160, symsize=1.5, position=oposition, /overplot
                    cgplot, [0], [0], psym=1, color=250, symsize=1.5, position=oposition, /overplot
  		        	cgcontour, flux_smooth, ra_smooth, dec_smooth, levels=level, /irregular, /noerase, color='blue',/onimage,label=0
		        endif else begin
  		        	cgplot, ra_tot, dec_tot, psym=1,color=0, symsize=1.5, position=oposition, /overplot
  		        	cgplot, ra_tot[where(flux ne 0)], dec_tot[where(flux ne 0)], psym=1, color=160, symsize=1.5, position=oposition, /overplot
                    cgplot, [0], [0], psym=1, color=250, symsize=1.5, position=oposition, /overplot
  		        	cgcontour, flux_smooth, ra_smooth, dec_smooth, levels=level, /noerase, /onimage, color=0,/nodata,label=0
		        endelse
		        if keyword_set(plot_irs2) then begin
		            cgplot, (plot_irs2[0]-ra_cen[0])*3600.*cos(plot_irs2[1]*!pi/180.), (plot_irs2[1]-dec_cen[0])*3600., psym=7, color=110, symsize=1.5, position=oposition, /overplot
		        endif
		        loadct, 0, /silent
		        ; place it in the upper right
		        al_legend,['!n'+title_name(line_name[i])],textcolors=[0], box=0, charsize=1.5,pos=[0.55,0.87],/normal
		        al_legend,['!n'+objname],textcolors=[0], box=0, charsize=1.5, pos=[0.3,0.87],/normal
		        exit_ssw:
		        device, /close_file, decomposed = 1
		        !p.multi = 0
		        cleanplot,/silent
  			endif
		endfor
  	endif
  	;PACS
  	if keyword_set(pacs) then begin
      	;Create the line name list first
  	    line_name_oh2o = ['o-H2O8_27-7_16','o-H2O10_29-10_110','o-H2O9_09-8_18','o-H2O7_52-8_27','o-H2O4_32-3_21','o-H2O5_41-6_16','o-H2O9_18-9_09','o-H2O8_18-7_07','o-H2O6_61-6_52','o-H2O7_61-7_52',$
  	                      'o-H2O6_25-5_14','o-H2O7_16-6_25','o-H2O3_30-2_21','o-H2O3_30-3_03','o-H2O8_27-8_18','o-H2O7_07-6_16','o-H2O7_25-6_34','o-H2O3_21-2_12','o-H2O8_54-8_45','o-H2O6_52-6_43',$
  	                      'o-H2O5_50-5_41','o-H2O7_52-7_43','o-H2O4_23-3_12','o-H2O9_27-9_18','o-H2O6_16-5_05','o-H2O8_36-8_27','o-H2O7_16-7_07','o-H2O8_45-8_36','o-H2O6_43-6_34','o-H2O6_25-6_16',$
  	                      'o-H2O4_41-4_32','o-H2O6_34-6_25','o-H2O2_21-1_10','o-H2O7_43-7_34','o-H2O4_41-5_14','o-H2O4_14-3_03','o-H2O9_27-10_110','o-H2O8_36-9_09','o-H2O7_34-6_43','o-H2O4_32-4_23',$
  	                      'o-H2O9_36-9_27','o-H2O7_25-7_16','o-H2O9_45-9_36','o-H2O4_23-4_14','o-H2O8_36-7_43','o-H2O5_14-5_05','o-H2O3_30-3_21','o-H2O5_23-4_32','o-H2O8_45-7_52','o-H2O6_34-7_07',$
  	                      'o-H2O5_32-5_23','o-H2O7_34-7_25','o-H2O3_03-2_12','o-H2O4_32-5_05','o-H2O2_12-1_01','o-H2O2_21-2_12','o-H2O8_54-9_27']
                         ;'o-H2O5_41-5_32','o-H2O5_05-4_14','o-H2O5_14-4_23'
  	    line_name_ph2o = ['p-H2O6_51-7_26','p-H2O7_71-7_62','p-H2O10_19-10_010','p-H2O4_31-3_22','p-H2O9_19-8_08','p-H2O4_22-3_13','p-H2O8_17-7_26','p-H2O6_42-7_17','p-H2O7_26-6_15','p-H2O8_26-7_35',$
  	                      'p-H2O7_62-8_35','p-H2O4_31-4_04','p-H2O4_40-5_15','p-H2O9_28-9_19','p-H2O8_08-7_17','p-H2O7_62-7_53','p-H2O3_31-2_20','p-H2O5_24-4_13','p-H2O7_17-6_06','p-H2O5_51-6_24',$
  	                      'p-H2O8_17-8_08','p-H2O9_37-9_28','p-H2O5_51-5_42','p-H2O7_53-7_44','p-H2O6_51-6_42','p-H2O6_15-5_24','p-H2O9_46-9_37','p-H2O8_53-8_44','p-H2O7_26-7_17','p-H2O8_35-7_44',$
  	                      'p-H2O6_06-5_15','p-H2O3_22-2_11','p-H2O7_44-7_35','p-H2O5_42-5_33','p-H2O6_42-6_33','p-H2O6_15-6_06','p-H2O5_24-5_15','p-H2O5_33-5_24','p-H2O9_46-8_53','p-H2O9_37-8_44',$
  	                      'p-H2O8_44-8_35','p-H2O4_04-3_13','p-H2O3_31-3_22','p-H2O7_53-8_26','p-H2O7_35-8_08','p-H2O3_13-2_02','p-H2O8_44-7_53','p-H2O4_13-3_22','p-H2O4_31-4_22','p-H2O8_35-8_26',$
  	                      'p-H2O5_42-6_15','p-H2O3_22-3_13','p-H2O3_31-4_04','p-H2O8_26-9_19','p-H2O6_24-6_15','p-H2O7_35-6_42','p-H2O6_33-6_24','p-H2O5_33-6_06','p-H2O4_13-4_04']
  	                      ;,'p-H2O5_15-4_04','p-H2O4_40-4_31','p-H2O9_37-10_010','p-H2O8_26-8_17','p-H2O2_20-1_11','p-H2O6_24-5_33'
  	    line_name_co = ['CO40-39','CO39-38','CO38-37','CO37-36','CO36-35','CO35-34','CO34-33','CO33-32','CO32-31','CO31-30',$
						'CO30-29','CO29-28','CO28-27','CO25-24','CO24-23','CO23-22','CO22-21','CO21-20','CO20-19',$;'CO27-26',
						'CO19-18','CO18-17','CO17-16','CO16-15','CO15-14','CO14-13','CO41-40','CO42-41','CO43-42','CO44-43',$
						'CO45-44','CO46-45','CO47-46','CO48-47']
  	    line_name_oh = ['OH19-14','OH18-15','OH13-9','OH12-8','OH14-10','OH15-11','OH5-1','OH4-0','OH9-3','OH8-2',$
  				        'OH10-8','OH11-9','OH3-1','OH2-0','OH14-12','OH15-13','OH19-16','OH18-17','OH7-5','OH6-4']
  	    line_name_other = ['OI3P1-3P2','NII','OI3P0-3P1','CII2P3_2-2P1_2']
  	    line_name_pacs = [line_name_oh2o, line_name_ph2o, line_name_co, line_name_oh, line_name_other]

		line_name = line_name_pacs
		if keyword_set(verbose) then print, 'contour plots for PACS'
		for i = 0, n_elements(line_name)-1 do begin
		    wl = []
		    flux = []
		    flux_sig = []
		    base_str = []
		    snr = []
		    ra = []
		    ra_tot = []
		    dec = []
		    dec_tot = []
		    for pix = 0, n_elements(data_pacs[*].ra[0])-1 do begin
				; read in the central position
				if pix eq 12 then begin
  					ra_cen = ra_cen_pacs[where(data_pacs[pix].line eq line_name[i])]
  					dec_cen = dec_cen_pacs[where(data_pacs[pix].line eq line_name[i])]
				endif
      	        data_ind = where(data_pacs[pix].line eq line_name[i])
      	        ra_tot = [ra_tot, data_pacs[pix].ra[data_ind]]
				dec_tot = [dec_tot, data_pacs[pix].dec[data_ind]]
				base_str = [base_str, data_pacs[pix].base_str[data_ind]]
				; exclude absorption lines
				; set every absorption line to zero
      	        if (data_pacs[pix].flux[data_ind] lt 0) or (data_pacs[pix].snr[data_ind] lt 3d0) or (data_ind eq -1) or (data_pacs[pix].validity[data_ind] eq 0) then begin
    	        	wl = [wl, data_pacs[pix].wl[data_ind]]
    		        flux = [flux, 0]
    		        flux_sig = [flux_sig, 0]
    				snr = [snr, data_pacs[pix].snr[data_ind]]
    				ra = [ra, data_pacs[pix].ra[data_ind]]
    				dec = [dec, data_pacs[pix].dec[data_ind]]
      	        endif else begin
    	        	wl = [wl, data_pacs[pix].wl[data_ind]]
    		        flux = [flux, data_pacs[pix].flux[data_ind]]
    		        flux_sig = [flux_sig, data_pacs[pix].flux_sig[data_ind]]
    				snr = [snr, data_pacs[pix].snr[data_ind]]
    				ra = [ra, data_pacs[pix].ra[data_ind]]
    				dec = [dec, data_pacs[pix].dec[data_ind]]
      	        endelse
            endfor
		    if (n_elements(flux[where(flux ne 0)]) ge 1) and ((where(flux ne 0))[0] ne -1) then begin
    			if keyword_set(verbose) then print, 'Plotting ',objname,'-',line_name[i]
      	        set_plot, 'ps'
      	        !p.font = 0
      	        device, filename = plotdir+objname+'_'+line_name[i]+'_contour.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
      	        loadct,13,/silent
      	        !p.thick = 4 & !x.thick = 5 & !y.thick = 5
      	        if (where(flux_sig gt 1))[0] ne -1 then flux_sig[where(flux_sig gt 1)] = 0
      	        noisefloor = median(flux/snr*noise)
        		level = indgen(6)/5.*(max(flux)-min(flux[where(flux ne 0)]))+min(flux[where(flux ne 0)])
      	        level = level[sort(level)]
      	        if max(flux) ne min(flux[where(flux ne 0)]) then begin
                    level = level[1:-1]
                endif else begin
                	ind = where(flux eq max(flux))
                	noise = flux[ind]/snr[ind]
                	level = indgen(6)/5.*max(flux)
                	level = level[where(level ge 3*noise[0])]
                	if 3*noise ge max(flux) then stop
    	        endelse
    		    ra = (ra-ra_cen[0])*3600*cos(dec*!pi/180.)
				dec = (dec-dec_cen[0])*3600
				ra_tot = (ra_tot-ra_cen[0])*3600*cos(dec_tot*!pi/180.)
				dec_tot = (dec_tot-dec_cen[0])*3600
      	        flux_smooth = min_curve_surf(flux,ra,dec,/double);,nx=100,ny=100)
                base_str_smooth = min_curve_surf(base_str,ra_tot,dec_tot,/double);,nx=100,ny=100)
    			base_str_smooth[where(base_str_smooth lt 0)] = 0
    			base_str_smooth = rotate(base_str_smooth,5)
                ra_smooth = min_curve_surf(ra,ra,dec,/double);,nx=100,ny=100)
                dec_smooth = min_curve_surf(dec,ra,dec,/double);,nx=100,ny=100)
                ra_tot_smooth = min_curve_surf(ra_tot,ra_tot,dec_tot,/double);,nx=100,ny=100)
                dec_tot_smooth = min_curve_surf(dec_tot,ra_tot,dec_tot,/double);,nx=100,ny=100)

				plotposition = [0.15,0.15,0.95,0.9]
				position = [0.5*(30-max(ra_tot_smooth[*,0]))/30+plotposition[0], 0.5*(30+min(dec_tot_smooth[0,*]))/30+plotposition[1],$
    							     plotposition[2]-0.5*(min(ra_tot_smooth[*,0])+30)/30, plotposition[3]-0.5*(30-max(dec_tot_smooth[0,*]))/30]
    			loadct, 13, /silent
        		cgplot, ra_tot, dec_tot, psym=1,xrange=[30,-30],yrange=[-30,30], position=plotposition,/nodata,color=255,xtitle='!nRA offset (arcsec)',ytitle='!nDec offset (arcsec)',aspect=1.0
      	        colorFile = '~/programs/misc/fsc_brewer.tbl';Filepath(SUBDIRECTORY=['resource','colors'], 'fsc_brewer.tbl')
      	        cgloadct, 10, /reverse, file=colorfile, /silent
      	        cgimage, base_str_smooth/max(base_str_smooth)*255,/overplot,$
                oposition=oposition,/keep_aspect_ratio,alphafgposition=position,$;, xrange=[30,-30], yrange=[-30,30]
                xrange=[max(ra_tot_smooth[*,0]), min(ra_tot_smooth[*,0])],$
                yrange=[min(dec_tot_smooth[0,*]), max(dec_tot_smooth[0,*])]
                op = oposition
                cgcolorbar,range=[0,max(base_str_smooth)/1e-22],/vertical,/right,Position=[plotposition[2]+0.03,plotposition[1],plotposition[2]+0.055,plotposition[3]],title='I!dbase!n [10!u-18!n W m!u-2!n'+unit+']'
                loadct, 13, /silent
        		cgplot, ra_tot, dec_tot, psym=1,color=0, symsize=1.5, position=oposition, /overplot
                ; if encounter an error skip this one and keep going
                catch, error_status
                if error_status ne 0 then begin
                    if !error_state.msg eq 'Program caused arithmetic error: Floating illegal operand' then continue
    	        	print, 'Object: ', objname, ' Line: ',line_name[i]
    	        	print, !error_state.msg
    	        	file_delete, plotdir+objname+'_'+line_name[i]+'_contour.eps',/allow_nonexistent,/verbose
                    goto, exit_pacs
                endif
      	        if n_elements(flux[where(flux ne 0)]) ge 3 then begin
    	        	cgplot, ra_tot, dec_tot, psym=1,color=0, symsize=1.5, position=oposition, /overplot;,xrange=[140,-140],yrange=[-140,140], position=plotposition, /overplot
    	        	cgplot, ra_tot[where(flux ne 0)], dec_tot[where(flux ne 0)], psym=1, color=160, symsize=1.5, position=oposition, /overplot
                    cgplot, [0], [0], psym=1, color=250, symsize=1.5, position=oposition, /overplot
    	        	cgcontour, flux_smooth, ra_smooth, dec_smooth, levels=level, /irregular, /noerase, color='blue',/onimage,label=0
      	        endif else begin
    	        	cgplot, ra_tot, dec_tot, psym=1,color=0, symsize=1.5, position=oposition, /overplot
    	        	cgplot, ra_tot[where(flux ne 0)], dec_tot[where(flux ne 0)], psym=1, color=160, symsize=1.5, position=oposition, /overplot
                    cgplot, [0], [0], psym=1, color=250, symsize=1.5, position=oposition, /overplot
    	        	cgcontour, flux_smooth, ra_smooth, dec_smooth, levels=level, /noerase, /onimage, color=0,/nodata,label=0
      	        endelse
      	        if keyword_set(plot_irs2) then begin
                    cgplot, (plot_irs2[0]-ra_cen[0])*3600.*cos(plot_irs2[1]*!pi/180.), (plot_irs2[1]-dec_cen[0])*3600., psym=7, color=110, symsize=1.5, position=oposition, /overplot
      	        endif
      	        loadct, 0, /silent
      	        ; place it in the upper right
                if strmatch(line_name[i],'OH*',/fold_case) eq 1 then begin
                    al_legend,['!n'+title_name(line_name[i])],textcolors=[0], box=0, charsize=1.5,pos=[0.48,0.89],/normal
                endif else begin
      	            al_legend,['!n'+title_name(line_name[i])],textcolors=[0], box=0, charsize=1.5,pos=[0.55,0.89],/normal
      	        endelse
      	        al_legend,['!n'+objname],textcolors=[0], box=0, charsize=1.5, pos=[0.3,0.89],/normal
      	        exit_pacs:
      	        device, /close_file, decomposed = 1
      	        !p.multi = 0
      	        cleanplot,/silent
		    endif
		endfor
  	endif
endif
end

pro run_plot_contour
plot_contour, slw, ssw, pacs, noise=[1,1,1],indir='~/bhr71/data/',plotdir='~/bhr71/plots/contour/',objname='BHR71'
end
