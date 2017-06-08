pro extract_line, indir=indir, filename=filename, outdir=outdir, plotdir=plotdir, noiselevel=noiselevel, ra=ra, dec=dec,$
	localbaseline=localbaseline, global_noise=global_noise, fixed_width=fixed_width, continuum=continuum, object=object, flat=flat,$
	plot_subtraction=plot_subtraction, no_plot=no_plot, double_gauss=double_gauss, r_spectral=r_spectral
	; The indir is the path of the spectrum of each pixel, including every letter in the filename except the pixel number.  For example, '/path/to/data/pacs_pixel13.txt', the indir will be '/path/to/data/pacs_pixel'
	; Same method of the indir apply to the outdir.
	if file_test(outdir) eq 0 then file_mkdir, outdir
	if not keyword_set(no_plot) then begin
		if file_test(plotdir+'base',/directory) eq 0 then file_mkdir,plotdir+'base'
	endif
	if file_test(plotdir+'cannot_fit',/directory) eq 0 then file_mkdir,plotdir+'cannot_fit'

	; no_plot flags the option of plotting the fitting results of individual line.
	if keyword_set(no_plot) then begin
		no_plot = 1
	endif else begin
		no_plot = 0
	endelse
    ; The path to the data that you want to fit.  wavelength in um and flux in Jy.
    readcol, indir+filename+'.txt', format='D,D,D', comment='#', wl, flux , /silent
    ; Get rid off the NaN
    wl = wl[where(finite(flux) eq 1)]
    std = flux[where(finite(flux) eq 1)] * 0
    flux = flux[where(finite(flux) eq 1)]
    ; Convert the flux to appropriate unit
    c = 2.998d8
    flux = flux*1d-4*c/(wl*1d-6)^2*1d-6*1d-26  ; Change F_nu (Jy) -> F_lambda (W cm-2 um-1)
    std = std*1d-4*c/(wl*1d-6)^2*1d-6*1d-26 + 1 ; weight = 1/0 cause problem
    ; Information about the line that you want to fit including the range for baseline fitting.
    ; every level is equal to LAMDA level-1
    ; In the later version, the 10 times of resolutions is used for determining the baseline. Thus the baseline number here is less important

;	line_name = ['NeII12', 'FeII18', 'FeII26', 'FeII35']
;	line_center = [12.81, 17.93, 25.97, 35.3]
;	cont = [[12.4, 12.7, 13.0, 13.3], [17.6, 17.8, 18.1,18.4], [25.5, 25.92, 26.02, 26.5],[35.0, 35.2, 35.4, 36.0]]

    ; line_name =  ['H2S2', 'NeII12', 'NeIII15', 'H2S1', 'FeII18',$
    ;               'SIII18','FeIII23', 'SI25',$
    ;               'FeII24', 'FeII26', 'H2S0',$
    ;               'SIII33', 'SiII34',  'FeII35', 'NeIII36', 'H2S3',$
    ;               'H2S4', 'H2S5', 'H2S6', 'H2S7', 'FeII53']
    ;
    ; line_center = [12.28, 12.81, 15.55, 17.03, 17.93,$
    ;               18.71, 22.91, 24.52,$
    ;               25.25, 25.98, 28.50,$
    ;               33.48, 34.81, 35.34, 35.96, 9.67,$
    ;               8.02, 6.92, 6.11, 5.51, 5.33]
    ;
    ; cont = [[11.9,12.1,12.4,12.7],[12.4, 12.7, 13.0, 13.3],[15.1,15.4,15.7,16.0],[16.6,16.9,17.2,17.5], [17.6, 17.8, 18.1,18.4],$
    ;         [18.1,18.5,18.9,19.2],[22.4,22.7,23.2,23.5],[24.35, 24.45, 24.7, 24.9],$
    ;         [24.8,25.1,25.4,25.7],[25.5, 25.82, 26.02, 26.5],[27.8,28.1,28.7,29.0],$
    ;         [32.9,33.2,33.7,34.0],[34.3,34.6, 35.0,35.2],[35.0, 35.2, 35.4, 35.8],[35.4,35.8,36.2,36.5], [9.6,9.65,9.7,9.75],$
    ;         [7.9,7.97,8.1,8.2], [6.8,6.88,7.0,7.1], [5.95,6.05,6.12,6.14], [5.4,5.45,5.6,5.7], [5.2,5.3,5.4,5.45]]

    line_name = ['Halpha', 'fake']
    line_center = [6569, 5000]
    cont = [[6459,6559,6580,6680]]

    ; resolving power of the spectrograph
    ; dl in the unit of um
    if keyword_set(r_spectral) then begin
        R = r_spectral
    endif else begin
        R = 600.0
    endelse
    dl = median(wl)/R

	; Define the range of line center by setting the range within -2-2 times of the resolution elements of the line center
	; Since the [OI] 63 um lines are usually wider, we use -3-3 times of the resolution for this line.
	range = []
  ; sort the lists of line info
	line_name = line_name[sort(line_center)]
	cont = cont[*,sort(line_center)]
	line_center = line_center[sort(line_center)]

	; exclude the lines that are not in the input spectrum
	line_name = line_name[where((line_center ge min(wl)) and (line_center le max(wl)))]
	cont = cont[*,where((line_center ge min(wl)) and (line_center le max(wl)))]
	line_center = line_center[where((line_center ge min(wl)) and (line_center le max(wl)))]

  ; define the range of line centroids
  range_factor = 3
	for i = 0, n_elements(line_center)-1 do begin
		if i eq 0 then begin
			lower = line_center[i]-(range_factor)*dl
			if (range_factor)*dl gt 0.5*(line_center[i+1]-line_center[i]) then begin
				upper = line_center[i]+0.5*(line_center[i+1]-line_center[i])
			endif else begin
				upper = line_center[i]+(range_factor)*dl
			endelse
			range = [[range], [[lower, upper]]]
		endif
		if (i ne 0) and (i ne n_elements(line_center)-1) then begin
			if range_factor*dl gt 0.5*(line_center[i]-line_center[i-1]) then begin
				lower = line_center[i]-0.5*(line_center[i]-line_center[i-1])
			endif else begin
				lower = line_center[i]-(range_factor)*dl
			endelse
			if (range_factor)*dl gt 0.5*(line_center[i+1]-line_center[i]) then begin
				upper = line_center[i]+0.5*(line_center[i+1]-line_center[i])
			endif else begin
				upper = line_center[i]+(range_factor)*dl
			endelse
			range = [[range], [[lower, upper]]]
		endif
		if i eq n_elements(line_center)-1 then begin
			if range_factor*dl gt 0.5*(line_center[i]-line_center[i-1]) then begin
				lower = line_center[i]-0.5*(line_center[i]-line_center[i-1])
			endif else begin
				lower = line_center[i]-(range_factor)*dl
			endelse
			upper = line_center[i]+(range_factor)*dl
			range = [[range], [[lower, upper]]]
		endif
	endfor

	; Create a wavelength array that every elements in this array can be selected as a valid point for baseline fitting
	base_mask = 0*wl
	for i = 0, n_elements(wl)-1 do begin
		valid=1
		for j = 0, n_elements(line_name)-1 do begin
			if (wl[i] ge range[0,j]) and (wl[i] le range[1,j]) then valid = valid*0
		endfor
		if valid eq 1 then base_mask[i] = 1
	endfor

	wl_basepool = wl[where(base_mask ne 0)] & flux_basepool = flux[where(base_mask ne 0)] & std_basepool = std[where(base_mask ne 0)]

    if keyword_set(double_gauss) then begin
    	; Modified the line list for double Gaussian fitting
    	line_name_dg = [[]]
    	line_center_dg = []
    	range_dg = []
    	line_dg = []
    	excluded_line =[]

    	for dg = 0, n_elements(line_name_dg[0,*])-1 do begin
    		ind = where(line_name eq line_name_dg[0,dg] or line_name eq line_name_dg[1,dg])
    		if n_elements(ind) eq 2 then begin
    			range_dg = [[range_dg],[min(range[*,ind]), max(range[*,ind])]]
    			excluded_line = [excluded_line,line_name_dg[0,dg],line_name_dg[1,dg]]
    			line_center_dg = [line_center_dg,line_center[ind]]
    			for k = 0, n_elements(ind)-1 do begin
    				line_dg = [[line_dg], [line_center[ind[k]], range[0,ind[k]], range[1,ind[k]]]]
    			endfor
    		endif
    	endfor
    endif

    ; The path to the output file for print out the fitting result.
    ; Always print out the pixel number.  If processing 1D spectrum, use 'c'.
	name = filename+'_lines'
    openw, firstfit, outdir+name+'.txt', /get_lun
	printf, firstfit, format='(15(a18,2x))', $
		'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)',$
        'Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)',$
        'SNR','RA(deg)','Dec(deg)','Pixel_No.','Blend'

    ; Do the fitting for every line in the list
    ; Single Gaussian fitting
    for i = 0, n_elements(line_name)-1 do begin
    	; Check if the line that about to fit is the one in the double Gaussian fitting list.
    	if (keyword_set(double_gauss)) then if ((where(excluded_line eq line_name[i]))[0] ne -1) then continue

        ; select the baseline
		; Usually localbaseline = 10
		dlb = localbaseline*dl
		wl_diff = wl[1:-1]-wl[0:-2]
        ; find the how many pixels correspond to the number of resolution elements specified.
		numb = ceil(dlb/(wl_diff[where(wl ge line_center[i])])[0])

		left = where(wl_basepool lt range[0,i] and wl_basepool ge min(wl))
		right = where(wl_basepool gt range[1,i] and wl_basepool le max(wl))

		if n_elements(left) gt numb then left = left[n_elements(left)-1-numb:n_elements(left)-1]
		if n_elements(right) gt numb then right = right[0:numb-1]

        if left[0] ne -1 and right[0] ne -1 then begin
            wlb = [wl_basepool[left], wl_basepool[right]]
            fluxb = [flux_basepool[left], flux_basepool[right]]
            stdb = [std_basepool[left], std_basepool[right]]
            base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]], wl_basepool[right[0]], wl_basepool[right[n_elements(right)-1]]]
        endif
        if left[0] eq -1 and right[0] ne -1 then begin
            wlb = [wl_basepool[right]]
            fluxb = [flux_basepool[right]]
            stdb = [std_basepool[right]]
            base_range = [wl_basepool[right[0]], wl_basepool[right[0]],wl_basepool[right[0]],wl_basepool[right[n_elements(right)-1]]]
        endif
        if left[0] ne -1 and right[0] eq -1 then begin
            wlb = [wl_basepool[left]]
            fluxb = [flux_basepool[left]]
            stdb = [std_basepool[left]]
            base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]]]
        endif

        ; the region of spectrum that will use for fitting
        indl = where(wl gt base_range[0] and wl lt base_range[3])
		if base_range[0] eq base_range[1] then indl = where(wl gt min(wl) and wl lt base_range[3])
		if base_range[2] eq base_range[3] then indl = where(wl gt base_range[0] and wl lt max(wl))
		wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]

        ; select the line+baseline
        ; use the plot_base feature to plot the actual spectrum (with line) here
		plot_base = [[wll],[fluxl]]

		if n_elements(wlb) lt 3 then continue
        ; fit the baseline and return the baseline parameter in 'base_para'
        fit_line, filename, line_name[i], wlb, fluxb, std=stdb, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, /baseline, outdir=plotdir, no_plot=no_plot, plot_base=plot_base

		; extract the wave and flux for plottng that is for better visualization of the fitting results.
		; ind_plot = where(wl gt base_range[0]-5*dl and wl lt base_range[3]+5*dl)
		; plot_wl = wl[ind_plot] & plot_flux = flux[ind_plot] & plot_std = std[ind_plot]
		plot_base = [[wlb],[fluxb]]
        ; Subtract the baseline from the spectrum
        ; First, calculate the baseline
        ; base = base_para[0]*wll +base_para[1]                       ;use 1st order polynomial
        base = base_para[0]*wll^2+base_para[1]*wll+base_para[2]      ;use 2nd order polynomial
        ; Subtract
        fluxx = fluxl - base
        stdd = stdl
        line = [line_center[i],range[0,i],range[1,i]]                      ;[line_center, line profile lower limit, line profile upper limit]
        ; Fitting part
        ; Different fitting keyword for fixed width and test arguement


        if keyword_set(fixed_width) then begin
			fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para,$
                      snr, line, noise, plot_base=plot_base, /single_gauss, outdir=plotdir, noiselevel=noiselevel, /fixed_width,$
                      base_range=base_range, no_plot=no_plot
        endif else begin
			fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para,$
                      snr, line, noise, plot_base=plot_base, /single_gauss, outdir=plotdir, noiselevel=noiselevel, base_range=base_range,$
                      no_plot=no_plot
        endelse
        ; if the global_noise keyword is not specified, then do the fitting again but take the evaluated noise as the error of the data
        if not keyword_set(global_noise) then begin
        	feedback = noise + fluxx*0
	        if keyword_set(fixed_width) then begin
				fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm,$
                          base_para, snr, line, noise, plot_base=plot_base, /single_gauss, outdir=plotdir, noiselevel=noiselevel,$
                          /fixed_width, base_range=base_range, no_plot=no_plot, feedback=feedback
	        endif else begin
				fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm,$
                          base_para, snr, line, noise, plot_base=plot_base, /single_gauss, outdir=plotdir, noiselevel=noiselevel,$
                          base_range=base_range, no_plot=no_plot, feedback=feedback
	        endelse
       	endif

        ; Print the fittng result into text file
        if status le 0 then begin
            printf, firstfit, format = '((a18,2X),(a50))', line_name[i], errmsg
        endif else begin
            ; The baseline are in the unit of W/cm2/um
            base_str = interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl)
            if not keyword_set(ra) then ra = 0
            if not keyword_set(dec) then dec = 0

            ; if (keyword_set(current_pix)) and ~(string(current_pix) eq 'c') then begin
            ; 	ra = interpol(ra_tot, wl_coord, line_center[i])
            ; 	dec = interpol(dec_tot, wl_coord, line_center[i])
            ; endif

            ; Blended lines classification
            blue_blend = 0 & red_blend = 0
            if i eq 0 then begin
            	if line_center[i+1]-cen_wl lt fwhm then red_blend = 1
            endif
            if i ne 0 and i ne n_elements(line_center)-1 then begin
            	if cen_wl-line_center[i-1] lt fwhm then blue_blend = 2
            	if line_center[i+1]-cen_wl lt fwhm then red_blend  = 1
            endif
            if i eq n_elements(line_center)-1 then begin
            	if cen_wl-line_center[i-1] lt fwhm then blue_blend = 2
            endif
            blend_flag = red_blend+blue_blend
            if blend_flag eq 0 then blend_msg = 'x'
            if blend_flag eq 1 then blend_msg = 'Red'
            if blend_flag eq 2 then begin
            	blend_msg = 'Blue'
            	blend_flag = 3
            endif
            if blend_flag eq 3 then begin
            	blend_msg = 'Red/Blue'
            	blend_flag = 2
            endif

            ; Throw away the bogus results due to the missing segment in the spectrum
            if finite(snr,/nan) eq 1 then continue
            ; blend flag = 0: no blend; blend_flag = 1: Red blend; blend_flag = 2: Red/Blue blend; blend_flag = 3: Blue blend.
            ;
        	printf, firstfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),2(a18,2x))',$
        		line_name[i], line_center[i], cen_wl, sig_cen_wl, str,$
                sig_str, fwhm, sig_fwhm, base_str, noise,$
                snr, ra, dec, 'c', blend_msg
        endelse
    endfor
    ; Double Gaussian fit
	if keyword_set(double_gauss) then begin
		for i = 0, n_elements(line_center_dg)/2-1 do begin
			mean_wl = (line_center_dg[2*i]+line_center_dg[2*i+1])/2
			if (min(wl) gt mean_wl) or (max(wl) lt mean_wl) then continue
			dlb = localbaseline*dl
			wl_diff = wl[1:-1]-wl[0:-2]
			numb = ceil(dlb/(wl_diff[where(wl ge line_center_dg[2*i])])[0])
			left = where(wl_basepool lt range_dg[0,i] and wl_basepool ge min(wl)) & right = where(wl_basepool gt range_dg[1,i] and wl_basepool le max(wl))
			if n_elements(left) gt numb then left = left[n_elements(left)-1-numb:n_elements(left)-1]
			if n_elements(right) gt numb then right = right[0:numb-1]
			if left[0] ne -1 and right[0] ne -1 then begin
            	wlb = [wl_basepool[left], wl_basepool[right]]
            	fluxb = [flux_basepool[left], flux_basepool[right]]
            	stdb = [std_basepool[left], std_basepool[right]]
				base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]], wl_basepool[right[0]], wl_basepool[right[n_elements(right)-1]]]
				indl = where(wl gt base_range[0] and wl lt base_range[3])
				wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
			endif
			if left[0] eq -1 and right[0] ne -1 then begin
                wlb = [wl_basepool[right]] & fluxb = [flux_basepool[right]] & stdb = [std_basepool[right]]
				base_range = [wl_basepool[right[0]], wl_basepool[right[0]],wl_basepool[right[0]],wl_basepool[right[n_elements(right)-1]]]
				indl = where(wl gt min(wl) and wl lt base_range[2])
				wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
			endif
			if left[0] ne -1 and right[0] eq -1 then begin
				wlb = [wl_basepool[left]] & fluxb = [flux_basepool[left]] & stdb = [std_basepool[left]]
				base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]]]
				indl = where(wl gt base_range[0] and wl lt max(wl))
				wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
			endif

			; use the plot_base feature to plot the actual spectrum (with line) here
			plot_base = [[wll],[fluxl]]
			fit_line, filename, line_name_dg[2*i]+'+'+line_name_dg[2*i+1], wlb, fluxb, std=stdb, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, /baseline, outdir=plotdir,no_plot=no_plot, plot_base=plot_base
			; extract the wave and flux for plottng that is for better visualization of the fitting results.
			; ind_plot = where(wl gt base_range[0]-5*dl and wl lt base_range[3]+5*dl)
			; plot_wl = wl[ind_plot] & plot_flux = flux[ind_plot] & plot_std = std[ind_plot]
			plot_base = [[wlb],[fluxb]]
			; Subtract the baseline from the spectrum
			; First, calculate the baseline
			; base = base_para[0]*wll +base_para[1]                       ;use 1st order polynomial
			base = base_para[0]*wll^2+base_para[1]*wll+base_para[2]       ;use 2nd order polynomial
			; Subtract
			fluxx = fluxl - base
			stdd = stdl
			; line = [cen1,ran1,ran1,cen2,ran2,ran2]
			line = [line_dg[*,2*i],line_dg[*,2*i+1]]
			; Fitting part
			; Different fitting keyword for fixed width and test arguement
			; Using band 3 resolution for some of WISH sources
			fit_line,filename,line_name_dg[2*i]+'+'+line_name_dg[2*i+1],wll,fluxx,std=stdd,status,errmsg,cen_wl,sig_cen_wl,str,sig_str,fwhm,sig_fwhm,base_para,snr,line,noise,/double_gauss,outdir=plotdir,$
				noiselevel=noiselevel,base_range=base_range,plot_base=plot_base,/fix_dg,/fixed_width

			; if the keyword global_noise is not specified, then do the fitting again but take the evaluated noise as the error of the data
			if not keyword_set(global_noise) then begin
				feedback = noise + fluxx*0
				fit_line,filename,line_name_dg[2*i]+'+'+line_name_dg[2*i+1],wll,fluxx,std=stdd,status,errmsg,cen_wl,sig_cen_wl,str,sig_str,fwhm,sig_fwhm,base_para,snr,line,noise,/double_gauss,outdir=plotdir,$
					noiselevel=noiselevel,base_range=base_range,plot_base=plot_base,/fix_dg,/fixed_width, feedback=feedback
			endif

			if status eq 0 then begin
				printf, firstfit, format = '((a18,2X),(a50))', line_name_dg[2*i]+'_'+line_name_dg[2*i+1], errmsg
			endif else begin
				; Making sure the line classification is correct
				i1 = where(line_name eq line_name_dg[2*i])
				i2 = where(line_name eq line_name_dg[2*i+1])
				if (abs(line_center[i1]-cen_wl[0]) gt abs(line_center[i1]-cen_wl[1])) and (abs(line_center[i2]-cen_wl[1]) gt abs(line_center[i2]-cen_wl[0])) then begin
					print, 'Line misplacement found in '+line_name_dg[2*i]+'+'+line_name_dg[2*i+1]
					cen_wl = reverse(cen_wl)
					sig_cen_wl = reverse(sig_cen_wl)
					str = reverse(str)
					sig_str = reverse(sig_str)
					fwhm = reverse(fwhm)
					sig_fwhm = reverse(sig_fwhm)
					snr = reverse(snr)
				endif

				if (keyword_set(current_pix)) and ~(string(current_pix) eq 'c') then begin
            		ra = interpol(ra_tot, wl_coord, line[0])
					dec = interpol(dec_tot, wl_coord, line[0])
				endif

				base_str = [interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl[0]), $
				            interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl[1])]
				blend_msg = 'x'
				if (finite(snr,/nan))[0] eq 1 then continue
				printf, firstfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),2(a18,2x))',$
					line_name_dg[2*i], line[0], cen_wl[0], sig_cen_wl[0], str[0], sig_str[0], fwhm[0], sig_fwhm[0], base_str[0], noise, snr[0], ra, dec, current_pix, blend_msg
				printf, firstfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),2(a18,2x))',$
					line_name_dg[2*i+1], line[3], cen_wl[1], sig_cen_wl[1], str[1], sig_str[1], fwhm[1], sig_fwhm[1], base_str[1], noise, snr[1], ra, dec, current_pix, blend_msg
			endelse
		endfor
	endif
    free_lun, firstfit
    close, firstfit

    ; Blended lines labeling and pick out the most possible line
	readcol, outdir+name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,A,A', $
		line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, ra_n, dec_n, pix_n, blend_flag_n, skipline=1,/silent

	blend_group = []
	blend_subgroup = []
	blend_msg_all = []
	possible_all = []
	for line = 0, n_elements(line_name_n)-1 do begin
		if (keyword_set(double_gauss)) then if ((where(line_name_dg eq line_name_n[line]))[0] ne -1) then begin
			blend_msg = 'DoubleGaussian'
			blend_msg_all = [blend_msg_all,blend_msg]
			continue
		endif
		; Blended lines classification
        blue_blend = 0 & red_blend = 0
        if line eq 0 then begin
            if abs(cen_wl_n[line+1]-cen_wl_n[line]) lt fwhm_n[line] then red_blend = 1
        endif
        if line ne 0 and line ne n_elements(line_name_n)-1 then begin
            if abs(cen_wl_n[line]-cen_wl_n[line-1]) lt fwhm_n[line] then blue_blend = 2
            if abs(cen_wl_n[line+1]-cen_wl_n[line]) lt fwhm_n[line] then red_blend  = 1
        endif
        if line eq n_elements(line_name_n)-1 then begin
            if abs(cen_wl_n[line]-cen_wl_n[line-1]) lt fwhm_n[line] then blue_blend = 2
        endif
        blend_flag = red_blend+blue_blend
        if blend_flag eq 0 then blend_msg = 'x'
        if blend_flag eq 1 then blend_msg = 'Red'
        if blend_flag eq 2 then begin
            blend_msg = 'Blue'
            blend_flag = 3
        endif
        if blend_flag eq 3 then begin
            blend_msg = 'Red/Blue'
            blend_flag = 2
        endif
        blend_msg_all = [blend_msg_all,blend_msg]
		if n_elements(blend_subgroup) eq 0 then group_flag = 0
		if blend_flag ge group_flag then begin
			if blend_flag eq 0 then continue
			blend_subgroup = [[blend_subgroup],[line_name_n[line],string(E_u_n[line])]]
			group_flag = blend_flag
		endif else begin
			possible_line = blend_subgroup[0,where(float(blend_subgroup[1,*]) eq min(float(blend_subgroup[1,*])))]
			if n_elements(possible_line) gt 1 then begin
				A_dum = A_n[where(line_name_n eq possible_line)]
				possible_line = possible_line[(where(line_name_n eq possible_line))[where(A_dum eq max(A_dum))]]
			endif
			blend_subgroup = []
			possible_all = [possible_all, possible_line]
			if blend_flag ne 0 then begin
				blend_subgroup = [[blend_subgroup],[line_name_n[line],string(E_u_n[line])]]
				group_flag = blend_flag
			endif
		endelse
	endfor
    openw, firstfit, outdir+name+'.txt', /get_lun
	printf, firstfit, format='(16(a18,2x))', $
		'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)',$
        'Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)',$
        'SNR','RA(deg)','Dec(deg)','Pixel_No.','Blend','Validity'

    for line = 0, n_elements(line_name_n)-1 do begin
    	lowest = '0'
     	if (where(possible_all eq line_name_n[line]))[0] ne -1 then lowest = '1'
     	if (blend_msg_all[line] eq 'x') or (blend_msg_all[line] eq 'DoubleGaussian') then lowest = '1'
     	if finite(snr_n[line],/nan) eq 1 then lowest = '0'
     	; Reason for sig_str is that some sources have very poor spectra like EC82.  It will fit on the edge
     	if (sig_cen_wl_n[line] eq -999) or (sig_fwhm_n[line] eq -999) or (sig_str_n[line] eq -999)then lowest = '0'
 		printf, firstfit, format = '( (a18,2x),3(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),2(f18.7,2x),3(a18,2x) )',$
        	line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line],$
            sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line], noise_n[line],$
            snr_n[line], ra_n[line], dec_n[line], pix_n[line], blend_msg_all[line], lowest
    endfor
    free_lun, firstfit
    close, firstfit
    ; Plot the line subtracted spectrum
    if not keyword_set(global_noise) then begin
		readcol, outdir+name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,A,A,I', $
			line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, ra_n, dec_n, pix_n, blend_flag_n, lowest_E_n, /silent
    	flux_sub = flux
    	for line = 0, n_elements(line_name_n)-1 do begin
    		if abs(snr_n[line]) ge noiselevel-1.0 then begin
				if (lowest_E_n[line] ne 1) then continue
    			ind = where((wl gt cen_wl_n[line]-2*fwhm_n[line]) and (wl lt cen_wl_n[line]+2*fwhm_n[line]))
    			wl_n = wl[ind]
    			line_profile = gauss(wl_n, [2.354*str_n[line]/fwhm_n[line]/(2*!PI)^0.5, cen_wl_n[line], fwhm_n[line]/2.354]);+base_str[line]
    			flux_sub[ind] = flux_sub[ind] - line_profile
    			if keyword_set(plot_subtraction) then begin
    				set_plot,'ps'
					!p.font=0
					loadct,12,/silent
					device, filename=plotdir+'line_subtracted_'+line_name[line]+'.eps',/helvetica,/portrait,/encapsulated,isolatin=1,font_size=12,decomposed=0,/color
					!p.thick=3 & !x.thick=3 & !y.thick=3

    				plot, wl_n, flux[ind], psym=10, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)', position=[0.15,0.1,0.95,0.95], $
    					yrange=[0.9*min([flux[ind],line_profile+base_str_n[line],flux_sub[line]]),1.1*max([flux[ind],line_profile+base_str_n[line],flux_sub[line]])]
					oplot, wl_n, line_profile+base_str_n[line], color=120, psym=10 ;purple
					oplot, wl_n, flux_sub[ind], color=200, psym=10 ;red
					al_legend, ['Data','Line+Baseline Fit','Subtraction'], textcolors=[0,120,200], /right
					device, /close_file, decomposed=1
					!p.multi=0
				endif
    		endif
    	endfor
    	set_plot, 'ps'
		!p.font = 0
		loadct,12,/silent
		msg = ''
		device, filename = plotdir+'spectrum_line_subtracted_'+filename+msg+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
		!p.thick=2 & !x.thick=3 & !y.thick=3
		plot, wl, flux/1e-22, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)',/nodata, position=[0.15,0.1,0.95,0.95]
		oplot, wl, flux/1e-22
		oplot, wl, flux_sub/1e-22, color=200
		al_legend,['Data','lines_subtracted'],textcolors=[0,200],/right
		al_legend,[object],textcolors=[0],/left
		device, /close_file, decomposed = 1
		!p.multi = 0
    endif

    ; Second fitting to use the results of the previous one to better estimate the noise
    if keyword_set(global_noise) then begin
    	print, '---> Re-calculating the noise level...'

    	; Read in the results of first fitting
		readcol, outdir+name+'.txt', format='A,D,D,D,D, D,D,D,D,D, D,D,D,A,A,I', $
			line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n,$
            sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n,$
            snr_n, ra_n, dec_n, pix_n, blend_flag_n, lowest_E_n, /silent

    	; Line subtraction
    	flux_sub = flux
    	for line = 0, n_elements(line_name_n)-1 do begin
            ; use SNR = 2.0 cut for better line exclusion
    		if abs(snr_n[line]) ge noiselevel-1.0 then begin
    			ind = where((wl gt cen_wl_n[line]-2*fwhm_n[line]) and (wl lt cen_wl_n[line]+2*fwhm_n[line]))
    			wl_n = wl[ind]
    			line_profile = gauss(wl_n, [2.354*str_n[line]/fwhm_n[line]/(2*!PI)^0.5, cen_wl_n[line], fwhm_n[line]/2.354]);+base_str[line]
    			flux_sub[ind] = flux_sub[ind] - line_profile
    			if keyword_set(plot_subtraction) then begin
    				set_plot,'ps'
					!p.font=0
					loadct,12,/silent
					device, filename=plotdir+'line_subtracted_'+line_name_n[line]+'.eps',/helvetica,/portrait,/encapsulated,isolatin=1,font_size=12,decomposed=0,/color
					!p.thick=3 & !x.thick=3 & !y.thick=3
    				plot, wl_n, flux[ind], psym=10, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)', position=[0.15,0.1,0.95,0.95], $
    					yrange=[0.9*min([flux[ind],line_profile+base_str_n[line],flux_sub[line]]),1.1*max([flux[ind],line_profile+base_str_n[line],flux_sub[line]])]
					oplot, wl_n, line_profile+base_str_n[line], color=120, psym=10 ;purple
					oplot, wl_n, flux_sub[ind], color=200, psym=10 ;red
					al_legend, ['Data','Line+Baseline Fit','Subtraction'], textcolors=[0,120,200], /right
					device, /close_file, decomposed=1
					!p.multi=0
				endif
    		endif
    	endfor

    	; Smooth the line subtracted spectrum
    	sbin=10
    	if keyword_set(linescan) then sbin=10
    	spec_continuum_smooth,wl,flux_sub,continuum_sub, continuum_sub_error,w1 = min(wl), w2 = max(wl), sbin=sbin,upper=0.9,lower=0.9
    	spec_continuum_smooth,wl,flux,continuum, continuum_error,w1 = min(wl), w2 = max(wl), sbin=sbin,upper=0.9, lower=0.9
    	flat_noise = flux_sub - continuum_sub

    	; ; Deal with the edge effect that can sabotage the SNR later
    	; edge_low = where(wl lt 100 and wl gt max(wl[where(wl lt 100)])-0.5)
    	; edge_hi = where(wl gt 100 and wl lt min(wl[where(wl gt 100)])+0.5)
    	; flat_noise[edge_low] = flat_noise[edge_low-n_elements(edge_low)]
    	; flat_noise[edge_hi] = flat_noise[edge_hi+n_elements(edge_hi)]

    	if keyword_set(continuum) then begin
    		openw, sed, outdir+filename+'_continuum.txt', /get_lun
    		printf, sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)'
    		print_continuum_sub = continuum_sub*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
    		for k =0, n_elements(wl)-1 do printf, sed, format='(3(g16.6,2x))', wl[k],print_continuum_sub[k]
    		free_lun, sed
    		close, sed
    	endif
    	if keyword_set(flat) then begin
    		openw, flat_sed, outdir+filename+'_flat_spectrum.txt',/get_lun
    		printf, flat_sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)'
    		flat = (flux-continuum_sub)*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
    		for k =0, n_elements(wl)-1 do printf, flat_sed, format='(3(g16.6,2x))',wl[k],flat[k]
    		free_lun, flat_sed
    		close,flat_sed
    	endif
	    openw, noise_sed, outdir+filename+'_residual_spectrum.txt',/get_lun
		printf, noise_sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)'
		print_flatnoise = flat_noise*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
		for k =0, n_elements(wl)-1 do printf, noise_sed, format='(3(g16.6,2x))',wl[k],print_flatnoise[k]
		close,noise_sed

        set_plot, 'ps'
		!p.font = 0
		loadct,12,/silent
		msg = ''
		device, filename = plotdir+'spectrum_line_subtracted_'+filename+msg+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 12, decomposed = 0, /color
		!p.thick=2 & !x.thick=3 & !y.thick=3
		plot, wl, flux/1e-22, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)',/nodata, position=[0.15,0.1,0.95,0.95]
		oplot, wl, flux/1e-22
		oplot, wl, continuum_sub/1e-22, color=100
		oplot, wl, flat_noise/1e-22+min(flux)/1e-22, color=10
		al_legend,['data','continuum', 'flat/featureless'],textcolors=[0,100,10],/right
		al_legend,[object],textcolors=[0],/left
		device, /close_file, decomposed = 1
		!p.multi = 0

		; Do the same fitting again but using the global noise value
		; Define the name of the output data of fitting results
		openw, secondfit, outdir+name+'.txt', /get_lun
		printf, secondfit, format='(15(a18,2x))',$
			'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)',$
            'Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)',$
            'SNR','RA(deg)','Dec(deg)','Pixel_No.','Blend'

    	for i = 0, n_elements(line_name)-1 do begin
    		if (keyword_set(double_gauss)) then if ((where(excluded_line eq line_name[i]))[0] ne -1) then continue
			; select the baseline

			dlb = localbaseline*dl
			wl_diff = wl[1:-1]-wl[0:-2]
			numb = ceil(dlb/(wl_diff[where(wl ge line_center[i])])[0])
			if n_elements(left) gt numb then left = left[n_elements(left)-1-numb:n_elements(left)-1]
			if n_elements(right) gt numb then right = right[0:numb-1]

			if left[0] ne -1 and right[0] ne -1 then begin
            	wlb = [wl_basepool[left], wl_basepool[right]]
            	fluxb = [flux_basepool[left], flux_basepool[right]]
            	stdb = [std_basepool[left], std_basepool[right]]
				base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]], wl_basepool[right[0]], wl_basepool[right[n_elements(right)-1]]]
			endif
			if left[0] eq -1 and right[0] ne -1 then begin
            	wlb = [wl_basepool[right]]
            	fluxb = [flux_basepool[right]]
            	stdb = [std_basepool[right]]
				base_range = [wl_basepool[right[0]], wl_basepool[right[0]],wl_basepool[right[0]],wl_basepool[right[n_elements(right)-1]]]
			endif
			if left[0] ne -1 and right[0] eq -1 then begin
            	wlb = [wl_basepool[left]]
            	fluxb = [flux_basepool[left]]
            	stdb = [std_basepool[left]]
				base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]]]
			endif

            indl = where(wl gt base_range[0] and wl lt base_range[3])
			if base_range[0] eq base_range[1] then indl = where(wl gt min(wl) and wl lt base_range[3])
			if base_range[2] eq base_range[3] then indl = where(wl gt base_range[0] and wl lt max(wl))
			wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]

			; use the plot_base feature to plot the actual spectrum (with line) here
			plot_base = [[wll],[fluxl]]
			; Fit the baseline and return the baseline parameter in 'base_para'
			fit_line, filename, line_name[i], wlb, fluxb, std=stdb, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, /baseline, outdir=plotdir, no_plot=no_plot, plot_base=plot_base
			; Extract the wave and flux for plottng that is for better visualization of the fitting results.
			; ind_plot = where(wl gt base_range[0]-5*dl and wl lt base_range[3]+5*dl)
			; plot_wl = wl[ind_plot] & plot_flux = flux[ind_plot] & plot_std = std[ind_plot]
			plot_base = [[wlb],[fluxb]]
			; Substract the baseline from the spectrum
			; First, calculate the baseline
			; base = base_para[0]*wll +base_para[1]                       ;use 1st order polynomial
			base = base_para[0]*wll^2+base_para[1]*wll+base_para[2]      ;use 2nd order polynomial
			; Subtract
			fluxx = fluxl - base
			stdd =  stdl
			line = [line_center[i],range[0,i],range[1,i]]      ;[line_center, line profile lower limit, line profile upper limit]

			; Calculate the noise level at the line using the flat noise spectrum
			limit_low = max([min(wl), range[0,i]-global_noise*dl]) & limit_hi = min([max(wl), range[1,i]+global_noise*dl])
			ind_n = where(wl gt limit_low and wl lt limit_hi)
			wl_n = wl[ind_n] & flux_n = flat_noise[ind_n] & std_n = std[ind_n]
			flat_noise_smooth = [[wl_n],[flux_n],[std_n]]

			;
			; Fitting part
			if keyword_set(fixed_width) then begin
				fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm,$
                          base_para, snr, line, noise, plot_base=plot_base, /single_gauss, outdir=plotdir, noiselevel=noiselevel,$
                          /fixed_width, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot
			endif else begin
				fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm,$
                          base_para, snr, line, noise, plot_base=plot_base, /single_gauss, outdir=plotdir, noiselevel=noiselevel,$
                          global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot
			endelse

			; A third fitting right after the noise being well-estimated.
			; Use the feedback keyword to feed in the noise level at certain wavelength and treat it as the local noise level.
			feedback = noise + fluxx*0

			if keyword_set(fixed_width) then begin
				fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm,$
                          base_para, snr, line, noise, plot_base=plot_base, /single_gauss, outdir=plotdir, noiselevel=noiselevel,$
                          /fixed_width, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot, feedback=feedback
			endif else begin
				fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm,$
                          base_para, snr, line, noise, plot_base=plot_base, /single_gauss,outdir=plotdir, noiselevel=noiselevel,$
                          global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot, feedback=feedback
			endelse

			; Print the fittng result into text file

        	if status le 0 then begin
				printf, secondfit, format = '((a18,2X),(a50))', line_name[i], errmsg
			endif else begin

				base_str = interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl)
            	if not keyword_set(ra) then ra = 0
            	if not keyword_set(dec) then dec = 0
				; if (keyword_set(current_pix)) and ~(string(current_pix) eq 'c') then begin
            	; 	ra = interpol(ra_tot, wl_coord, line_center[i])
				; 	dec = interpol(dec_tot, wl_coord, line_center[i])
				; endif
				; Blended lines classification
				blue_blend = 0 & red_blend = 0
				if i eq 0 then begin
            		if line_center[i+1]-cen_wl lt fwhm then red_blend = 1
				endif
				if i ne 0 and i ne n_elements(line_center)-1 then begin
            		if cen_wl-line_center[i-1] lt fwhm then blue_blend = 2
					if line_center[i+1]-cen_wl lt fwhm then red_blend  = 1
				endif
				if i eq n_elements(line_center)-1 then begin
            		if cen_wl-line_center[i-1] lt fwhm then blue_blend = 2
				endif
				blend_flag = red_blend+blue_blend
            	if blend_flag eq 0 then blend_msg = 'x'
				if blend_flag eq 1 then blend_msg = 'Red'
				if blend_flag eq 2 then begin
            		blend_msg = 'Blue'
					blend_flag = 3
				endif
				if blend_flag eq 3 then begin
            		blend_msg = 'Red/Blue'
					blend_flag = 2
				endif
				; blend flag = 0: no blend; blend_flag = 1: Red blend; blend_flag = 2: Red/Blue blend; blend_flag = 3: Blue blend.
				;
				; Throw away the bogus results due to the missing segment in the spectrum
				if finite(snr,/nan) eq 1 then continue
				printf, secondfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),2(a18,2x))',$
        			line_name[i], line_center[i], cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, ra, dec, 'c', blend_msg
			endelse
		endfor
		; Double Gaussian fit
		if keyword_set(double_gauss) then begin
			for i = 0, n_elements(line_center_dg)/2-1 do begin
				mean_wl = (line_center_dg[2*i]+line_center_dg[2*i+1])/2
				if (min(wl) gt mean_wl) or (max(wl) lt mean_wl) then continue
				dlb = localbaseline*dl
				wl_diff = wl[1:-1]-wl[0:-2]
				numb = ceil(dlb/(wl_diff[where(wl ge line_center_dg[2*i])])[0])
				left = where(wl_basepool lt range_dg[0,i] and wl_basepool ge min(wl)) & right = where(wl_basepool gt range_dg[1,i] and wl_basepool le max(wl))
				if n_elements(left) gt numb then left = left[n_elements(left)-1-numb:n_elements(left)-1]
				if n_elements(right) gt numb then right = right[0:numb-1]
				if left[0] ne -1 and right[0] ne -1 then begin
            		wlb = [wl_basepool[left], wl_basepool[right]]
            		fluxb = [flux_basepool[left], flux_basepool[right]]
            		stdb = [std_basepool[left], std_basepool[right]]
					base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]], wl_basepool[right[0]], wl_basepool[right[n_elements(right)-1]]]
					indl = where(wl gt base_range[0] and wl lt base_range[3])
					wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
				endif
				if left[0] eq -1 and right[0] ne -1 then begin
                	wlb = [wl_basepool[right]]
                	fluxb = [flux_basepool[right]]
                	stdb = [std_basepool[right]]
					base_range = [wl_basepool[right[0]], wl_basepool[right[0]],wl_basepool[right[0]],wl_basepool[right[n_elements(right)-1]]]
					indl = where(wl gt min(wl) and wl lt base_range[2])
					wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
				endif
				if left[0] ne -1 and right[0] eq -1 then begin
                	wlb = [wl_basepool[left]]
                	fluxb = [flux_basepool[left]]
                	stdb = [std_basepool[left]]
					base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]]]
					indl = where(wl gt base_range[0] and wl lt max(wl))
					wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
				endif

				; use the plot_base feature to plot the actual spectrum (with line) here
				plot_base = [[wll],[fluxl]]
				fit_line, filename, line_name_dg[2*i]+'+'+line_name_dg[2*i+1], wlb, fluxb, std=stdb, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, /baseline, outdir=plotdir,no_plot=no_plot, plot_base=plot_base
				; extract the wave and flux for plottng that is for better visualization of the fitting results.
				; ind_plot = where(wl gt base_range[0]-5*dl and wl lt base_range[3]+5*dl)
				; plot_wl = wl[ind_plot] & plot_flux = flux[ind_plot] & plot_std = std[ind_plot]
				plot_base = [[wlb],[fluxb]]
				; Calculate the gloe noise spectrum
				limit_low = max([min(wl), range_dg[0,i]-global_noise*dl]) & limit_hi = min([max(wl), range_dg[1,i]+global_noise*dl])
				ind_n = where(wl gt limit_low and wl lt limit_hi)
				wl_n = wl[ind_n] & flux_n = flat_noise[ind_n] & std_n = std[ind_n]
				flat_noise_smooth = [[wl_n],[flux_n],[std_n]]
				; Subtract the baseline from the spectrum
				; First, calculate the baseline
				; base = base_para[0]*wll +base_para[1]                       ;use 1st order polynomial
				base = base_para[0]*wll^2+base_para[1]*wll+base_para[2]      ;use 2nd order polynomial
				; Subtract
				fluxx = fluxl - base
				stdd = stdl
				line = [line_dg[*,2*i],line_dg[*,2*i+1]]
				; Fitting part
				; Different fitting keyword for fixed width and test arguement
				fit_line,filename,line_name_dg[2*i]+'+'+line_name_dg[2*i+1],wll,fluxx,std=stdd,status,errmsg,cen_wl,sig_cen_wl,str,sig_str,fwhm,sig_fwhm,base_para,snr,line,noise,/double_gauss,outdir=plotdir,$
					 noiselevel=noiselevel,base_range=base_range,plot_base=plot_base,global_noise=flat_noise_smooth,/fix_dg,/fixed_width

				; A third fitting to take the well-estimated noise as the error of the data into the fitting routine to get the best estimation of the unceratinty of the fitted parameters
				feedback = noise + fluxx*0
				fit_line,filename,line_name_dg[2*i]+'+'+line_name_dg[2*i+1],wll,fluxx,std=stdd,status,errmsg,cen_wl,sig_cen_wl,str,sig_str,fwhm,sig_fwhm,base_para,snr,line,noise,/double_gauss,outdir=plotdir,$
					 noiselevel=noiselevel,base_range=base_range,plot_base=plot_base,global_noise=flat_noise_smooth,/fix_dg,/fixed_width,feedback=feedback

				if status eq 0 then begin
					printf, secondfit, format = '((a18,2X),(a50))', line_name_dg[2*i]+'_'+line_name_dg[2*i+1], errmsg
				endif else begin
					; Making sure the line classification is correct
					i1 = where(line_name eq line_name_dg[2*i])
					i2 = where(line_name eq line_name_dg[2*i+1])
					if (abs(line_center[i1]-cen_wl[0]) gt abs(line_center[i1]-cen_wl[1])) and (abs(line_center[i2]-cen_wl[1]) gt abs(line_center[i2]-cen_wl[0])) then begin
						print, 'Line misplacement found in '+line_name_dg[2*i]+'+'+line_name_dg[2*i+1]
						cen_wl = reverse(cen_wl)
						sig_cen_wl = reverse(sig_cen_wl)
						str = reverse(str)
						sig_str = reverse(sig_str)
						fwhm = reverse(fwhm)
						sig_fwhm = reverse(sig_fwhm)
						snr = reverse(snr)
					endif
					; if (keyword_set(current_pix)) and ~(string(current_pix) eq 'c') then begin
					; 	ra = interpol(ra_tot, wl_coord, line[0])
					; 	dec = interpol(dec_tot, wl_coord, line[0])
					; endif
					base_str = [interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl[0]), $
								interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl[1])]
					blend_msg = 'x'
					; Throw away the bogus results due to the missing segment in the spectrum
					if (finite(snr,/nan))[0] eq 1 then continue
					printf, secondfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),2(a18,2x))',$
						line_name_dg[2*i], line[0], cen_wl[0], sig_cen_wl[0], str[0], sig_str[0], fwhm[0], sig_fwhm[0], base_str[0],noise,snr[0], ra, dec, current_pix, blend_msg
					printf, secondfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),2(a18,2x))',$
						line_name_dg[2*i+1], line[3], cen_wl[1], sig_cen_wl[1], str[1], sig_str[1], fwhm[1], sig_fwhm[1], base_str[1],noise,snr[1], ra, dec, current_pix, blend_msg
				endelse
			endfor
		endif
		free_lun, secondfit
    	close, secondfit
    	; Identify the blended lines
		readcol, outdir+name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,A,A', $
			line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, ra_n, dec_n, pix_n, blend_flag_n, /silent, skipline=1

		blend_subgroup = []
		blend_msg_all = []
		possible_all = []
		for line = 0, n_elements(line_name_n)-1 do begin
			if (keyword_set(double_gauss)) then if ((where(line_name_dg eq line_name_n[line]))[0] ne -1) then begin
				blend_msg = 'DoubleGaussian'
				blend_msg_all = [blend_msg_all,blend_msg]
			continue
			endif
			; Blended lines classification
			blue_blend = 0 & red_blend = 0
			if line eq 0 then begin
				if abs(cen_wl_n[line+1]-cen_wl_n[line]) lt fwhm_n[line] then red_blend = 1
			endif
			if line ne 0 and line ne n_elements(line_name_n)-1 then begin
            	if abs(cen_wl_n[line]-cen_wl_n[line-1]) lt fwhm_n[line] then blue_blend = 2
				if abs(cen_wl_n[line+1]-cen_wl_n[line]) lt fwhm_n[line] then red_blend  = 1
			endif
			if line eq n_elements(line_name_n)-1 then begin
				if abs(cen_wl_n[line]-cen_wl_n[line-1]) lt fwhm_n[line] then blue_blend = 2
			endif
			blend_flag = red_blend+blue_blend
			if blend_flag eq 0 then blend_msg = 'x'
			if blend_flag eq 1 then blend_msg = 'Red'
			if blend_flag eq 2 then begin
				blend_msg = 'Blue'
				blend_flag = 3
			endif
			if blend_flag eq 3 then begin
            	blend_msg = 'Red/Blue'
				blend_flag = 2
			endif
			blend_msg_all = [blend_msg_all,blend_msg]
			if n_elements(blend_subgroup) eq 0 then group_flag = 0
			if blend_flag ge group_flag then begin
				if blend_flag eq 0 then continue
				blend_subgroup = [[blend_subgroup],[line_name_n[line],string(E_u_n[line])]]
				group_flag = blend_flag
			endif else begin
				possible_line = blend_subgroup[0,where(float(blend_subgroup[1,*]) eq min(float(blend_subgroup[1,*])))]
				if n_elements(possible_line) gt 1 then begin
					A_dum = A_n[where(line_name_n eq possible_line)]
					possible_line = possible_line[(where(line_name_n eq possible_line))[where(A_dum eq max(A_dum))]]
				endif
				blend_subgroup = []
				possible_all = [possible_all, possible_line]
				if blend_flag ne 0 then begin
					blend_subgroup = [[blend_subgroup],[line_name_n[line],string(E_u_n[line])]]
					group_flag = blend_flag
				endif
			endelse
		endfor
		openw, secondfit, outdir+name+'.txt', /get_lun
		printf, secondfit, format='(16(a18,2x))', $
			'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)',$
            'Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)',$
            'SNR','RA(deg)','Dec(deg)','Pixel_No.','Blend','Validity'

		for line = 0, n_elements(line_name_n)-1 do begin
    		lowest = '0'
			if (where(possible_all eq line_name_n[line]))[0] ne -1 then lowest = '1'
			if (blend_msg_all[line] eq 'x') or (blend_msg_all[line] eq 'DoubleGaussian') then lowest = '1'
			if finite(snr_n[line],/nan) eq 1 then lowest = '0'
			; Reason for sig_str is that some sources have very poor spectra like EC82.  It will fit on the edge
			if (sig_cen_wl_n[line] eq -999) or (sig_fwhm_n[line] eq -999) or (sig_str_n[line] eq -999)then lowest = '0'
			printf, secondfit, format = '( (a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),2(f18.7,2x),3(a18,2x) )',$
        		line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line],$
                sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line], noise_n[line],$
                snr_n[line], ra_n[line], dec_n[line], pix_n[line], blend_msg_all[line], lowest
		endfor
		free_lun, secondfit
		close, secondfit

		; Calculate the line subtracted spectrum again
		readcol, outdir+name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,A,A,I',$
			line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, ra_n, dec_n, pix_n, blend_flag_n, lowest_E_n, /silent

		flux_sub = flux
		for line = 0, n_elements(line_name_n)-1 do begin
			if snr_n[line] ge noiselevel then begin
				if lowest_E_n[line] ne 1 then continue
				ind = where((wl gt cen_wl_n[line]-5*fwhm_n[line]) and (wl lt cen_wl_n[line]+5*fwhm_n[line]))
				wl_n = wl[ind]
				line_profile = gauss(wl_n, [2.354*str_n[line]/fwhm_n[line]/(2*!PI)^0.5, cen_wl_n[line], fwhm_n[line]/2.354]);+base_str[line]
				flux_sub[ind] = flux_sub[ind] - line_profile
				if keyword_set(plot_subtraction) then begin
					set_plot,'ps'
					!p.font=0
					loadct,12,/silent
					device, filename=plotdir+'line_subtracted_'+filename+'_'+line_name_n[line]+'.eps',/helvetica,/portrait,/encapsulated,isolatin=1,font_size=12,decomposed=0,/color
					!p.thick=3 & !x.thick=3 & !y.thick=3
    				plot, wl_n, flux[ind], psym=10, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)', position=[0.15,0.1,0.95,0.95], $
    					yrange=[0.9*min([flux[ind],line_profile+base_str_n[line],flux_sub[line]]),1.1*max([flux[ind],line_profile+base_str_n[line],flux_sub[line]])]
					oplot, wl_n, (line_profile+base_str_n[line])/1e-22, color=120, psym=10 ;purple
					oplot, wl_n, flux_sub[ind]/1e-22, color=200, psym=10 ;red
					al_legend, ['Data','Line+Baseline Fit','Subtraction'], textcolors=[0,120,200], /right
					device, /close_file, decomposed=1
					!p.multi=0
				endif
			endif
		endfor
		; Smooth the line subtracted spectrum
		sbin=10
		spec_continuum_smooth,wl, flux_sub, continuum_sub, continuum_sub_error,w1 = min(wl), w2 = max(wl), sbin=sbin,upper=0.9,lower=0.9
		flat_noise = flux_sub - continuum_sub

    	; ; Deal with the edge effect that can sabotage the SNR later
    	; edge_low = where(wl lt 100 and wl gt max(wl[where(wl lt 100)])-0.5)
    	; edge_hi = where(wl gt 100 and wl lt min(wl[where(wl gt 100)])+0.5)
    	; flat_noise[edge_low] = flat_noise[edge_low-n_elements(edge_low)]
    	; flat_noise[edge_hi] = flat_noise[edge_hi+n_elements(edge_hi)]

		if keyword_set(continuum) then begin
    		openw, sed, outdir+filename+'_continuum.txt', /get_lun
    		printf, sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)'
    		print_continuum_sub = continuum_sub*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
    		for k =0, n_elements(wl)-1 do printf, sed, format='(3(g16.6,2x))', wl[k],print_continuum_sub[k]
    		free_lun, sed
    		close, sed
    	endif
    	if keyword_set(flat) then begin
    		openw, flat_sed, outdir+filename+'_flat_spectrum.txt',/get_lun
    		printf, flat_sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)'
    		flat = (flux-continuum_sub) *1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
    		for k =0, n_elements(wl)-1 do printf, flat_sed, format='(3(g16.6,2x))',wl[k],flat[k]
    		free_lun, flat_sed
    		close,flat_sed
    	endif
		openw, noise_sed, outdir+filename+'_residual_spectrum.txt',/get_lun
		printf, noise_sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)'
		print_flatnoise = flat_noise *1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
		; stdd = std*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
		for k =0, n_elements(wl)-1 do printf, noise_sed, format='(3(g16.6,2x))',wl[k],print_flatnoise[k]
		free_lun, noise_sed
		close,noise_sed

		; Plot the results
		set_plot, 'ps'
		!p.font = 0
		loadct,12,/silent
		msg = ''
		device, filename = plotdir+'spectrum_line_subtracted_'+filename+msg+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 12, decomposed = 0, /color
		!p.thick=2 & !x.thick=3 & !y.thick=3
		trim1 = where(wl lt 100) & trim2 = where(wl ge 100)
		plot, wl, flux/1e-22, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)',ystyle=2, /nodata, position=[0.15,0.1,0.95,0.95]
		oplot, wl, flux/1e-22
		oplot, wl, continuum_sub/1e-22, color=100
		oplot, wl, flat_noise/1e-22 + min(flux)/1e-22, color=10
		al_legend,['data','continuum', 'flat/featureless'],textcolors=[0,100,10],/right
		al_legend,[object],textcolors= [0],/left
		device, /close_file, decomposed = 1
		!p.multi = 0

	endif
end
