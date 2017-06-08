pro fit_line, pixelname, linename, wl, flux, std=std, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
baseline=baseline, test=test, single_gauss=single_gauss, double_gauss=double_gauss, outdir=outdir, noiselevel=noiselevel, fixed_width=fixed_width,global_noise=global_noise,base_range=base_range,brightness=brightness,$
no_plot=no_plot,b3a=b3a,fix_dg=fix_dg,spire=spire,feedback=feedback, r_spectral=r_spectral

; The double gaussian function still in alpha test
; Create a separated directory for putting the double fitting plots
if file_test(outdir+'double_gauss/',/directory) eq 0 then file_mkdir, outdir+'double_gauss/'
; the default outdir directory contains /base, /cannot_fit for better sorting.  You can create these directories at first or use other path you want.

c = 2.998d10
; make the unit consist with each other. Change F_nu (Jy) -> F_lambda (W cm-2 um-1)
; flux = flux*1d-4*c/(wl*1d-6)^2*1d-6*1d-26

; ; weight = 1+0*flux
; wl = double(wl)
; flux = double(flux)
; expo = round(alog10(abs(median(flux))))*(-1)+1
; factor = 10d^expo
; nwl = wl - median(wl)
; if keyword_set(std) then begin
;   weight = double(std)*factor
; endif else begin
;   weight = 1+0*flux
; endelse
; fluxx = flux*factor
; nflux = fluxx - median(fluxx)

; baseline part
;
; weight = 1+0*flux
if (not keyword_set(spire)) and (not keyword_set(baseline)) then begin
    flux = flux[where((wl le median(wl)+10) and (wl ge median(wl)-10))]
    if keyword_set(std) then std = std[where((wl le median(wl)+10) and (wl ge median(wl)-10))]
    wl = wl[where((wl le median(wl)+10) and (wl ge median(wl)-10))]
endif
wl = double(wl)
flux = double(flux)
expo = round(alog10(abs(median(flux))))*(-1)+1
factor = 10d^expo
nwl = wl - median(wl)
if keyword_set(std) then begin
    ; Prevent the uncertainty has zero in the array
    std[where(std eq 0)] = mean(std)
    weight = double(std)*factor
    ; if keyword_set(spire) then weight = 1+0*flux
endif else begin
    weight = 1+0*flux
endelse

; Feedback option for the third fitting.  Take the well-estimated noise as the local error of the data.
if keyword_set(feedback) then weight = feedback*factor
fluxx = flux*factor
nflux = fluxx - median(fluxx)

  ;baseline part
if keyword_set(baseline) then begin
    ; Fit the baseline with 2nd order polynomial
    start = dblarr(3)
    start[0] = 0
    start[1] = (nflux[n_elements(nwl)-1] - nflux[0])/(nwl[n_elements(nwl)-1] - nwl[0])
    start[2] = nflux(0)
    ; result = mpfitfun('base2d', nwl, nflux, weight, start, /quiet, perror=sigma, status=status, errmsg=errmsg, /nan)
    ; Use an uniform weights for the baseline fitting
    ; Although putting zeros in err will result in the ignorance of the corresponding data points, specifying weights keyword ignores the err instead.
    result = mpfitfun('base2d', nwl, nflux, 0*flux, start, weights=(1+0*flux), /quiet, perror=sigma, status=status, errmsg=errmsg, /nan)
    p = result/factor & p_sig = sigma/factor
    p[2] = p[2] + median(flux)
    base = p[0]*(wl-median(wl))^2 + p[1]*(wl-median(wl)) + p[2]
    base_para = [p[0], p[1]-2*p[0]*median(wl), p[2]-p[1]*median(wl)+p[0]*median(wl)^2]
    mid_base = median(base)
    residual = flux-base
    noise = stddev(residual)
    ;-------------------------------------------
    if not keyword_set(no_plot) then begin
        set_plot, 'ps'
        !p.font = 0
        device, filename = outdir+'base/'+pixelname+'_'+linename+'_base.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 14, decomposed = 0, /color

        loadct ,13,/silent
        !p.thick = 3 & !x.thick = 3 & !y.thick = 3
        ylabel = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)'
        if keyword_set(brightness) then ylabel = '!3Brightness (10!u-22!n W/cm!u2!n/!9m!3m/arcsec!u2!n)'

        ; plot, wl, flux/1d-22, psym = 10, xtitle = '!3Wavelength(!9m!3m)', ytitle = '!3Flux Density(10!u-22!n W/cm!u2!n/!9m!3m)'                   ;plot the original data
        ; plot the actual spectrum instead of the line-free spectrum
        plot, plot_base[*,0], plot_base[*,1]/1d-22, psym = 10, yrange=[1.2*min(residual)/1d-22, 1.1*max(flux)/1d-22], xtitle = '!3Wavelength(!9m!3m)', ytitle = ylabel,position=[0.2,0.15,0.95,0.95]                   ;plot the original data
        oplot, wl, flux/1d-22, psym = 2
        oplot, wl, base/1d-22, color = 40                                                                           ;plot the fitted curve
        oplot, wl, residual/1d-22, psym = 10, color = 250                                                           ;plot the reidual
        al_legend, ['Data','Baseline','Residual'], color=[0,40,250], linestyle=[0,0,0], /left, /bottom
        device, /close_file, decomposed = 1
    endif
endif

; Fit the baseline substracted spectrum.
if not keyword_set(baseline) then begin
    ; Calculate the baseline
    base = base_para[0]*wl^2+base_para[1]*wl+base_para[2]

    if keyword_set(r_spectral) then begin
        dl = median(wl)/r_spectral/2.354
    endif else begin
        ; define the initial guess of the line profile
        ;--------------------------------------------
        ; First, construct the structure of the constrain.  Here to constrain that the width of the Gaussian cannot larger than the range of the wavelength put into this program
        case 1 of 
        max(wl) gt 200: begin
            ; instrument resolution 1.2 GHz and plus apodize 1.5 factor in the pipeline
            ; FWHM = 1.207*delta_sigma  (from silde: spire dp webinar by Nanyao Lu)
            dl = 1.5*1.207*(1.2*1e9*(line[0]*1e-4)^2/c)/2.354 * 1e4
            end
        (max(wl) lt 200) and (max(wl) gt 50): begin
            ; the width in these files are the FWHM.
            readcol, '~/programs/line_fitting/spectralresolution_order1.txt', format='D,D', wl1, res1,/silent
            readcol, '~/programs/line_fitting/spectralresolution_order2.txt', format='D,D', wl2, res2,/silent
            readcol, '~/programs/line_fitting/spectralresolution_order3.txt', format='D,D', wl3, res3,/silent
            fwhm1 = wl1/res1 & fwhm2 = wl2/res2 & fwhm3 = wl3/res3
            ;wl_ins = [wl3, wl2[where(wl2 eq max(wl3)):*], wl1[where(wl1 eq max(wl2)):*]]
            ;fwhm_ins = [fwhm3, fwhm2[where(wl2 eq max(wl3)):*], fwhm1[where(wl1 eq max(wl2)):*]]/2.354
            ;wl_ins = [wl2, wl1[where(wl1 eq max(wl2)):*]]
            wl_ins = [wl2[where(wl2 lt min(wl1))],wl1]
            ;fwhm_ins = [fwhm2, fwhm1[where(wl1 eq max(wl2)):*]]/2.354
            fwhm_ins = [fwhm2[where(wl2 lt min(wl1))],fwhm1]/2.354
            dl = double(interpol(fwhm_ins, wl_ins, line[0]))
            ; different band used in WISH
            if keyword_set(b3a) then begin
                if line[0] lt 69.2 then begin
                    dl = double(interpol(fwhm3/2.354,wl3,line[0]))
                endif
            endif
            end
        (max(wl) lt 50) and max(wl) gt 5: begin
            dl = median(wl)/600/2.354
        endcase

    ; Calculate the over sample rate
    if n_elements(wl) le 1 then begin
        ; if wl point equal to 1 or fewer, fitting cannot be proceded.  over_sample is meaningless.
        over_sample = 1
    endif else begin
        over_sample = dl/mean(wl[1:-1]-wl[0:-2])
    endelse
;    print, 'over_sample', over_sample

    ;-------------------------------------------e
    ;For single Gaussian fit
    if keyword_set(single_gauss) then begin
        start = dblarr(3)
        start[0] = interpol(nflux,nwl,line[0]-median(wl));max(nflux)
        start[1] = line[0] - median(wl);nwl[where(nflux eq max(nflux))]
        ind = where(nflux gt 0.5*(max(nflux) - min(nflux)) + min(nflux))
        ; For unapodized spectra, the width should be dl/1.5, dl for apodized spectra.
        ; Here the width can vary from dl/1.5 to dl for better fitting results.
        if not keyword_set(spire) then begin
            start[2] = dl;(max(nwl[ind]) - min(nwl[ind]))
        endif else begin
            start[2] = dl
        endelse
    endif
    ;For double Gaussian fit
    if keyword_set(double_gauss) then begin
        start = dblarr(6) & nflux_sort = sort(reverse(nflux))
        ;start[0] = nflux_sort[0] & start[3] = nflux_sort[1]
        ;start[0] = nflux[where(abs(wl-line[0]) eq min(abs(wl-line[0])))]
        ;start[3] = nflux[where(abs(wl-line[3]) eq min(abs(wl-line[3])))]
        start[0] = max(nflux[where(nwl gt line[1]-median(wl) and nwl lt line[5]-median(wl))])
        start[3] = max(nflux[where(nwl gt line[1]-median(wl) and nwl lt line[5]-median(wl))])
        ;start[0] = interpol(nflux,nwl,line[0]-median(wl)) & start[3] = interpol(nflux,nwl,line[3]-median(wl))
        if start[0] lt 0 then start[0] = 0
        if start[3] lt 0 then start[3] = 0
        ;start[1] = nwl[where(nflux eq nflux_sort[0])] & start[4] = nwl[where(nflux eq nflux_sort[1])]
        start[1] = line[0]-median(wl) & start[4] = line[3]-median(wl)
        if not keyword_set(spire) then begin
            start[2] = dl & start[5] = dl
        endif else begin
            start[2] = dl & start[5] = dl
        endelse
    endif

    if keyword_set(single_gauss) then begin
        parinfo = replicate({parname:'', value:0.D, fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
        parinfo[*].parname = ['height','center','width']
        parinfo[*].value = start
        ;parinfo[0].limited = [1,0] & parinfo[0].limits[0] = 0  ; constrain the line flux won't be negative
        parinfo[1].limited = [1,1] & parinfo[1].limits = line[1:2]-median(wl);[min(nwl), max(nwl)]
        ;Let the width vary while iterating
        ;parinfo[2].limited = [1,1] & parinfo[2].limits = [dl,10*dl]
        ;Let the width is fixed as the size of the resolution limit
        if keyword_set(fixed_width) then begin
            parinfo[2].fixed = 1
        endif else begin
            if dl eq 0 then stop
            if not keyword_set(spire) then begin
                ; sometime [OI] is wider
                parinfo[2].limited = [1,1] & parinfo[2].limits = [0.7*dl, 1.5*dl]
                ; parinfo[2].limited = [1,1] & parinfo[2].limits = [0.7*dl, 1.3*dl]
            endif else begin
                parinfo[2].limited = [1,1] & parinfo[2].limits = [0.7*dl, 1.3*dl];[dl/1.5, 1.5*dl];[dl,2*dl]
            endelse
        endelse
    endif

    if keyword_set(double_gauss) then begin
        height_lim = max(nflux[where(nwl gt line[1]-median(wl) and nwl lt line[5]-median(wl))])
            parinfo = replicate({parname:'', value:0.D, fixed:0, limited:[0,0], limits:[0.D,0.D]}, 6)
            parinfo[*].parname = ['height_1','center_1','width_1','height_2','center_2','width_2']
            parinfo[*].value = start
            if height_lim le 0 then begin
                parinfo[0].limited = [1,0] & parinfo[0].limits[0] = 0                     ; Constrain the line flux to be positive
                parinfo[3].limited = [1,0] & parinfo[3].limits[0] = 0
            endif else begin
                ; Temperory remove the upper limit of the height to test the sigma evaluation
                parinfo[0].limited = [1,0] & parinfo[0].limits = [0,height_lim]
                parinfo[3].limited = [1,0] & parinfo[3].limits = [0,height_lim]
            endelse
        ; Fixed the line centroids or not
            if not keyword_set(fix_dg) then begin
                parinfo[1].limited = [1,1] & parinfo[1].limits = line[1:2]-median(wl)     ; Restrict the range of the line center can be varied
                parinfo[4].limited = [1,1] & parinfo[4].limits = line[4:5]-median(wl)
            endif else begin
                parinfo[1].fixed = 1
                parinfo[4].fixed = 1
                ; flexible line centroids might yield a better fit for CO31-30/OH9-3 blended
                ; parinfo[1].limited = [1,1] & parinfo[1].limits = line[1:2]-median(wl)     ; Restrict the range of the line center can be varied
                ; parinfo[4].limited = [1,1] & parinfo[4].limits = line[4:5]-median(wl)
            ; Fixed the line width
            endelse
            if keyword_set(fixed_width) then begin
                parinfo[2].fixed = 1
                parinfo[5].fixed = 1
          endif else begin
              ; let the line width varied flexible
              if not keyword_set(spire) then begin
                  parinfo[2].limited = [1,1] & parinfo[2].limits = [0.7*dl, 1.3*dl]
                  parinfo[5].limited = [1,1] & parinfo[5].limits = [0.7*dl, 1.3*dl]
              endif else begin
                  parinfo[2].limited = [1,1] & parinfo[2].limits = [0.7*dl, 1.3*dl];[dl/1.5, dl]
                  parinfo[5].limited = [1,1] & parinfo[5].limits = [0.7*dl, 1.3*dl];[dl/1.5, dl]
              endelse
          endelse
            if dl eq 0 then stop
    endif
    ;-------------------------------------------
    ;Fit it!
    if keyword_set(single_gauss) then func = 'gauss'
    if keyword_set(double_gauss) then func = 'gauss_double'

    if not keyword_set(feedback) then begin
        result = mpfitfun(func, nwl, nflux, start, /quiet, weights = 1/weight^2, perror=sigma, status = status, errmsg = errmsg, parinfo=parinfo, /nan, bestnorm=bestnorm, dof=dof)
    endif else begin
        ; if feedback is provided, then the fitting routine has a precise measurement of the local error.
        result = mpfitfun(func, nwl, nflux, weight, start, /quiet, perror=sigma, status = status, errmsg = errmsg, parinfo=parinfo, /nan, bestnorm=bestnorm, dof=dof)
    endelse
    p = result
    if status gt 0 then begin
    ;This if statement is to make sure that the fitting routine actually gets the converged result.
    ;Recover everything since they are changed at first.  And calculate the physical quantities
    ;----------------------------------------------------------------
        if keyword_set(single_gauss) then begin
            rms2 = total((gauss(nwl,p)-nflux)^2)/(n_elements(wl)-2-1)
            rms = sqrt(rms2)
            ; Additional procedure for using the actual uncertainty from the data
            ; The 'rms' approach is inheritated from smart. But may be not the right for using uncertainty from data.
            ; if not keyword_set(std) then begin
            ;     sigma = sigma*rms
            ; endif
            if keyword_set(std) then sigma = sigma * sqrt(bestnorm/dof)
        cen_wl = p[1] + median(wl) & sig_cen_wl = sigma[1]
        height = p[0]/factor & sig_height = sigma[0]/factor
        fwhm = 2.354*abs(p[2]) & sig_fwhm = 2.354*abs(sigma[2])
        str = (2*!PI)^0.5*p[0]*abs(p[2]) & sig_str = abs(str)*((sigma[0]/p[0])^2+(abs(sigma[2])/abs(p[2]))^2)^0.5
        str = str/factor & sig_str = sig_str/factor
        gauss = height*exp(-(wl-cen_wl)^2/2/p[2]^2)
        fine_wl = (findgen(5001)-2500)/5000.*(max(wl)-min(wl))+(max(wl)+min(wl))/2
        gauss_fine = height*exp(-(fine_wl-cen_wl)^2/2/p[2]^2)
        base_gauss = base_para[0]*fine_wl^2+base_para[1]*fine_wl+base_para[2]
        residual = flux - gauss
        noise = stddev(residual[where(wl gt line[1]-5*dl and wl lt line[2]+5*dl)]) * (over_sample)^0.5
        if keyword_set(global_noise) then begin
            ; stich the residual and global_noise together
            ; Take the residual under the line area and use the global_noise at other place
            ; 1/e^2 full width = 1.699 * fwhm
            if not keyword_set(spire) then begin
                indl = where((wl ge cen_wl-1.699/2*fwhm) and (wl le cen_wl+1.699/2*fwhm))
                indb = where((global_noise[*,0] lt cen_wl-1.699/2*fwhm) or (global_noise[*,0] gt cen_wl+1.699/2*fwhm))
            endif else begin
                indl = where((wl ge cen_wl-1./2*fwhm) and (wl le cen_wl+1./2*fwhm))
                indb = where((global_noise[*,0] lt cen_wl-1./2*fwhm) or (global_noise[*,0] gt cen_wl+1./2*fwhm))
            endelse

            comb_noise = [residual[indl], global_noise[indb,1]]
            comb_noise_wl = [wl[indl], global_noise[indb,0]]
            comb_noise = comb_noise[sort(comb_noise_wl)]
            comb_noise_wl = comb_noise_wl[sort(comb_noise_wl)]
            noise = stddev(comb_noise) * (over_sample)^0.5
            ; noise = stddev(global_noise[*,1])
            ; Use Eq. 4.57 from Robinson's note
            ; if n_elements(global_noise[0,*]) eq 3 then begin
            ;   mean_noise = total(1/(global_noise[*,2])^2*global_noise[*,1])/total(1/(global_noise[*,2])^2)
            ;   std_noise = (double(1./n_elements(global_noise[*,1]))*total(1/(global_noise[*,2])^2*(global_noise[*,1]-mean_noise)^2)/total(1/(global_noise[*,2])^2)
            ;   noise = std_noise
            ; endif
        endif

        snr = abs(str/(1.064*noise*fwhm))
        ; The constraint on fwhm has already considered the boardening caused by the apodization. Therefore, there is no need to address the oversample
        ; if keyword_set(spire) then snr = abs(str/noise/fwhm);/sqrt(4.8312294)
        ; snr = height/noise
        ;
        ; extra procedure to make sure that not report the zero value for sig_cen_wl and sig_fwhm when the fitting is properly procede
        if ((where(line eq cen_wl))[0] ne -1) and sig_cen_wl eq 0 then sig_cen_wl = -999
        ; for one line in EC82
        if ((where(line eq cen_wl))[0] ne -1) and sig_cen_wl gt 1e10 then sig_cen_wl = -999
        if keyword_set(fixed_width) then sig_fwhm = -998
        if not keyword_set(spire) then begin
            if (fwhm eq 0.7*dl*2.354 or fwhm eq 1.3*dl*2.354) and sig_fwhm eq 0 then sig_fwhm = -999
        endif else begin
            if (fwhm eq 0.7*dl*2.354 or fwhm eq 1.3*dl*2.354) and sig_fwhm eq 0 then sig_fwhm = -999
        endelse
        ; extra procedure to exclude the case with 0 in line strength uncertainty.  There are many situations that can lead to this outcome.  Always double-check each line.
        if sig_str eq 0 then sig_str = -999

    endif
    if keyword_set(double_gauss) then begin
        ; print, 'Finishing double Gaussian fit for '+linename
        rms2 = total((gauss_double(nwl,p)-nflux)^2)/(n_elements(wl)-2-1)
        rms = sqrt(rms2)
        ; Additional procedure for using the actual uncertainty from the data
        ; The 'rms' approach is inheritated from smart. But may be not the right for using uncertainty from data.
        ; if not keyword_set(std) then begin
        ;     sigma = sigma*rms
        ; endif
        if keyword_set(std) then sigma = sigma * sqrt(bestnorm/dof)
        cen_wl = [p[1]+median(wl), p[4]+median(wl)] & sig_cen_wl = [sigma[1],sigma[4]]
        height = [p[0],p[3]]/factor & sig_height = [sigma[0],sigma[3]]/factor
        fwhm = 2.354*[abs(p[2]), abs(p[5])] & sig_fwhm = 2.354*[abs(sigma[2]), abs(sigma[5])]
        str = (2*!PI)^0.5*[p[0]*abs(p[2]), p[3]*abs(p[5])]
        sig_str = [abs(str[0])*((sigma[0]/p[0])^2+(abs(sigma[2])/abs(p[2]))^2)^0.5,abs(str[1])*((sigma[3]/p[3])^2+(abs(sigma[5])/abs(p[5]))^2)^0.5]
        str = str/factor
        sig_str = sig_str/factor
        gauss = height[0]*exp(-(wl-cen_wl[0])^2/2/p[2]^2) + height[1]*exp(-(wl-cen_wl[1])^2/2/p[5]^2)
        fine_wl = (findgen(5001)-2500)/5000.*(max(wl)-min(wl))+(max(wl)+min(wl))/2
        gauss_fine = height[0]*exp(-(fine_wl-cen_wl[0])^2/2/p[2]^2) + height[1]*exp(-(fine_wl-cen_wl[1])^2/2/p[5]^2)
        base_gauss = base_para[0]*fine_wl^2+base_para[1]*fine_wl+base_para[2]
        residual = flux - gauss
        noise = stddev(residual[where(wl gt line[1]-5*dl and wl lt line[5]+5*dl)]) * (over_sample)^0.5            ; if linename eq 'CI3P1-3P0_p-H2O6_24-7_17' then stop
        if keyword_set(global_noise) then begin
            ; stich the residual and global_noise together
            ; Take the residual under the line area and use the global_noise at other place
            ; 1/e^2 full width = 1.699 * fwhm
            ; indl = where((wl ge min(cen_wl)-1.699/2*fwhm[where(cen_wl eq min(cen_wl))]) and (wl le max(cen_wl)+1.699/2*fwhm[where(cen_wl eq max(cen_wl))]))
            ; indb = where((global_noise[*,0] lt min(cen_wl)-1.699/2*fwhm[where(cen_wl eq min(cen_wl))]) or (global_noise[*,0] gt max(cen_wl)+1.699/2*fwhm[where(cen_wl eq max(cen_wl))]))
            indl = where(wl ge line[1] and wl le line[5])
            indb = where(global_noise[*,0] lt line[1] or global_noise[*,0] gt line[5])
            comb_noise = [residual[indl], global_noise[indb,1]]
            comb_noise_wl = [wl[indl], global_noise[indb,0]]
            comb_noise = comb_noise[sort(comb_noise_wl)]
            comb_noise_wl = comb_noise_wl[sort(comb_noise_wl)]
            noise = stddev(comb_noise) * (over_sample)^0.5
            ; noise = stddev(global_noise[*,1])
            ; Use Eq. 4.57 from Robinson's note
            ; if n_elements(global_noise[0,*]) eq 3 then begin
            ;   mean_noise = total(1/(global_noise[*,2])^2*global_noise[*,1])/total(1/(global_noise[*,2])^2)
            ;   std_noise = (double(1./n_elements(global_noise[*,1]))*total(1/(global_noise[*,2])^2*(global_noise[*,1]-mean_noise)^2)/total(1/(global_noise[*,2])^2))^0.5
            ;   noise = std_noise
            ; endif
        endif
        snr = abs(str/(1.064*noise*fwhm))
        ; Account for the oversample in spire band
        ; if keyword_set(spire) then snr = abs(str/noise/fwhm);/sqrt(4.8312294)
        ;snr = height/noise
        ; Making sure the line classification is correct
        if (abs(line[0]-cen_wl[0]) gt abs(line[0]-cen_wl[1])) and (abs(line[3]-cen_wl[1]) gt abs(line[3]-cen_wl[0])) then begin
            print, 'Line misplacement found'
            cen_wl = reverse(cen_wl)
            sig_cen_wl = reverse(sig_cen_wl)
            str = reverse(str)
            sig_str = reverse(sig_str)
            fwhm = reverse(fwhm)
            sig_fwhm = reverse(sig_fwhm)
            snr = reverse(snr)
        endif
        ; extra procedure to make sure that not report the zero value for sig_cen_wl and sig_fwhm when the fitting is properly procede
        ;
        if keyword_set(fix_dg) then sig_cen_wl = [-998,-998]
        for k = 0, 1 do begin
            if (parinfo[2].fixed ne 1) and (parinfo[5].fixed ne 1) then begin
                if (abs(fwhm[k]-double(dl*2.354))/fwhm[k] lt 5e-8) or (abs(fwhm[k]-double(2*dl*2.354))/fwhm[k] lt 5e-8) and sig_fwhm[k] eq 0 then begin
                    sig_fwhm[k] = -999
                    ; if sig_cen_wl[k] eq 0 then sig_cen_wl[k] = -999
                endif
            endif
            if (parinfo[2].fixed eq 1) and (parinfo[5].fixed eq 1) then sig_fwhm[k] = -998

            if ((where(line[3*k] eq cen_wl[k]))[0] ne -1) and sig_cen_wl[k] eq 0 then sig_cen_wl[k] = -999
            if (str[k] eq 0) then begin
                sig_cen_wl[k] = -998
                sig_str[k] = -998
            endif
            ; extra procedure to exclude the case with 0 in line strength uncertainty.  There are many situations that can lead to this outcome.  Always double-check each line.
            if sig_str[k] eq 0 then sig_str[k] = -999
        endfor
        endif

        base = base_para[0]*wl^2+base_para[1]*wl+base_para[2]
        msg=''
        if keyword_set(test) then begin
            if snr le noiselevel then msg='_below'+strtrim(string(noiselevel),1)+'sigma'
        endif
        ;if keyword_set(fixed_width) then msg = msg + '_fixwidth'
        ;if keyword_set(global_noise) then msg = msg + '_global_noise'
        ;

     ;Make a plot
        ;plot the well-functional fitting result
        if not keyword_set(no_plot) then begin
            set_plot, 'ps'
            !p.font = 0
            if not keyword_set(double_gauss) then begin
                device, filename = outdir+pixelname+'_'+linename+msg+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 12, decomposed = 0, /color
            endif else begin
                device, filename = outdir+'double_gauss/'+pixelname+'_'+linename+msg+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 12, decomposed = 0, /color
            endelse

            loadct ,13,/silent
            !p.thick = 3 & !x.thick = 3 & !y.thick = 3
            maxx = max([max(flux), height])
            minn = min([0,min(flux)])
            ;plot, plot_wl, plot_flux/1d-22, psym = 10, xtitle = '!9m!3m', ytitle = '10!u-22!n W/cm!u2!n/!9m!3m', yrange = [min(plot_flux)/1d-22, max(plot_flux)*1.1/1d-22]
            ylabel = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)'
            if keyword_set(brightness) then ylabel = '!3Intensity (10!u-22!n W/cm!u2!n/!9m!3m/arcsec!u2!n)'
            if not keyword_set(double_gauss) then plot, wl, (flux+base)/1d-22, psym = 10, xtitle = 'Wavelength (!9m!3m)', ytitle = ylabel, yrange = [min(flux+base)/1d-22, max(flux+base)*1.1/1d-22],position=[0.15,0.1,0.95,0.95]        ;plot the baseline substracted spectrum
            if keyword_set(double_gauss) then begin
                plot, wl, (flux+base)/1d-22, psym = 10, xtitle = 'Wavelength (!9m!3m)', ytitle = ylabel, yrange = [min(flux+base)/1d-22, $
                    max([height[0]*exp(-(fine_wl-cen_wl[0])^2/2/p[2]^2)+base_gauss,height[1]*exp(-(fine_wl-cen_wl[1])^2/2/p[5]^2)+base_gauss,flux+base])*1.1/1d-22],$
                    xrange=[base_range[1],base_range[2]],position=[0.15,0.1,0.95,0.95]
                oplot, fine_wl, (height[0]*exp(-(fine_wl-cen_wl[0])^2/2/p[2]^2)+base_gauss)/1d-22, color=30
                oplot, fine_wl, (height[1]*exp(-(fine_wl-cen_wl[1])^2/2/p[5]^2)+base_gauss)/1d-22, color=225
            endif
            oplot, fine_wl, (gauss_fine+base_gauss)/1d-22, color = 80                                                                                                 ;plot the fitted curve(Gaussian)
            ;oplot, wl, (flux+base-gauss)/1d-22, psym = 10, color = 250                                                                                                ;plot the residual
            oplot, [line[0], line[0]], [-1000,1000]/1d-22, linestyle = 2
            oplot, [base_range[0],base_range[0]], [-1000,1000]/1d-22, linestyle = 1
            oplot, [base_range[1],base_range[1]], [-1000,1000]/1d-22, linestyle = 1
            oplot, [base_range[2],base_range[2]], [-1000,1000]/1d-22, linestyle = 1
            oplot, [base_range[3],base_range[3]], [-1000,1000]/1d-22, linestyle = 1
            ; if keyword_set(plot_base) then oplot, plot_base[*,0],plot_base[*,1]/1d-22,psym=4,symsize=0.5
            ; if keyword_set(global_noise) then oplot, global_noise[*,0], (global_noise[*,1]+interpol(base,wl, line[0]))/1e-22, psym=10, color=160
            if keyword_set(global_noise) then oplot, comb_noise_wl, (comb_noise+interpol(base,wl, line[0]))/1e-22, psym=10, color=160
            if not keyword_set(global_noise) then oplot, wl, (residual+interpol(base,wl, line[0]))/1d-22, psym=10, color=160
            if keyword_set(double_gauss) then oplot, [line[3],line[3]], [-1000,1000]/1d-22, linestyle = 2
            if keyword_set(single_gauss) then begin
                xyouts, 0.75, 0.75, 'S/N ='+string(snr,format='(g6.4)'), /normal
                xyouts, 0.75, 0.7, 'FWHM ='+string(fwhm,format='(g7.4)'), /normal
            endif
            if keyword_set(double_gauss) then begin
                xyouts, 0.6, 0.75, 'S/N ='+string(snr[0],format='(g6.4)')+', FWHM ='+string(fwhm[0],format='(g7.4)'), /normal, color=30
                xyouts, 0.6, 0.7, 'S/N ='+string(snr[1],format='(g6.4)')+', FWHM ='+string(fwhm[1],format='(g7.4)'), /normal, color=225
                ; xyouts, 0.2, 0.75, 'SNR ='+string(snr[0],format='(g6.4)')+', FWHM ='+string(fwhm[0],format='(g7.4)'), /normal, color=30
                ; xyouts, 0.2, 0.7, 'SNR ='+string(snr[1],format='(g6.4)')+', FWHM ='+string(fwhm[1],format='(g7.4)'), /normal, color=225
;               xyouts, 0.2, 0.75, 'FWHM='+strtrim(string(fwhm[0]),1), /normal
;               xyouts, 0.2, 0.7, '     '+strtrim(string(fwhm[1]),1), /normal
            endif
            if keyword_set(global_noise) then begin
                if not keyword_set(double_gauss) then begin
                   ;al_legend, ['Data','Fit','Residual','Noise'],colors=[0,80,250,160], linestyle=[0,0,0,0], /bottom
                    al_legend, ['Data','Fit','Residual+Noise'],colors=[0,80,160], linestyle=[0,0,0], /left
                endif else begin
                    al_legend, ['Data','Comb. Fit','Residual+Noise'],colors=[0,80,160], linestyle=[0,0,0], /left
                endelse
            endif else begin
                if not keyword_set(double_gauss) then begin
                   ;al_legend, ['Data','Fit','Residual'],colors=[0,80,250], linestyle=[0,0,0], /bottom
                    al_legend, ['Data','Fit','Residual'],colors=[0,80,160], linestyle=[0,0,0], /left
                endif else begin
                    al_legend, ['Data','Comb. Fit','Residual'],colors=[0,80,160], linestyle=[0,0,0], /left
                endelse
            endelse
            if not keyword_set(double_gauss) then al_legend, [title_name(linename)],textcolors=[0],/right
            ; Print the two line names in their corresponding colors
            if keyword_set(double_gauss) then al_legend, [title_name((strsplit(linename,'+',/extract))[0]), title_name((strsplit(linename,'+',/extract))[1])],$
                                                textcolors=[30,225],/right
            ;xyouts, 0.7, 0.85, title_name(linename), /normal
            device, /close_file, decomposed = 1
            !p.multi = 0
        endif
    endif else begin
        if keyword_set(single_gauss) then begin
            ind = where(wl gt line[1] and wl lt line[2])
            fluxx = flux-min(flux)
            line_str = total(fluxx[ind])/(line[2]-line[1])
            noise = (total(fluxx)-total(fluxx[ind]))/(max(wl)-min(wl)-line[2]+line[1])
            if line_str/noise gt 2 then msg = 'over_2sigma' else msg = ''
        endif
        if keyword_set(double_gauss) then begin
            ind1 = where(wl gt line[2] and wl lt line[3]) & ind2 = where(wl gt line[4] and wl lt line[5])
            fluxx = flux - min(flux)
            line_str = [total(fluxx[ind1])/(line[3]-line[2]), total(fluxx[ind2])/(line[5]-line[4])]
            noise = (total(fluxx)-total(fluxx[ind1])-total(fluxx[ind2]))/(max(wl)-min(wl)-line[3]+line[2]-line[5]+line[4])
            if total(line_str)/noise gt 2 then msg = 'over_2sigma' else msg = ''
            print, 'Double Gaussian fitting fail'
            print, errmsg
            if strmatch(outdir, '*EC82*', /fold_case) eq 1 then begin
                print, 'EC82 failed.'
            endif else begin
                stop
                pause
            endelse
            ;msg = ''
        endif
        if not keyword_set(no_plot) then begin
            set_plot, 'ps'
            !p.font = 0
            device, filename = outdir+'cannot_fit/'+pixelname+'_'+linename+'cannot_fit'+msg+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 14, decomposed = 0, /color

            loadct ,13,/silent
            !p.thick = 3 & !x.thick = 3 & !y.thick = 3
            plot, wl, (flux+base)/1d-22, psym = 10, xtitle = '!3!9m!3m', ytitle = '!3Flux Density(10!u-22!n W/cm!u2!n/!9m!3m)',position=[0.15,0.1,0.95,0.95]  ;plot the baseline substracted spectrum
            if keyword_set(single_gauss) then begin
                oplot, [line[1], line[1]], [-1000,1000], linestyle = 2
                plot, [line[2], line[2]], [-1000,1000], linestyle = 2
                xyouts, 0.2, 0.8, strtrim(string(line_str/noise),1), /normal
            endif
            if keyword_set(double_gauss) then begin
                oplot, [line[2], line[2]], [-1000,1000], linestyle = 2
                oplot, [line[3], line[3]], [-1000,1000], linestyle = 2
                oplot, [line[4], line[4]], [-1000,1000], linestyle = 2
                oplot, [line[5], line[5]], [-1000,1000], linestyle = 2
                xyouts, 0.2, 0.8, strtrim(string(line_str[0]/noise),1), /normal
                xyouts, 0.2, 0.75, strtrim(string(line_str[1]/noise),1), /normal
            endif
            xyouts, 0.2, 0.85, 'Fail to Converge', /normal
            if not keyword_set(double_gauss) then al_legend, [title_name(linename)],textcolors=[0],/right
            ; Print the two line names in their corresponding colors
            if keyword_set(double_gauss) then al_legend, [title_name((strsplit(linename,'+',/extract))[0]), title_name((strsplit(linename,'+',/extract))[1])],$
                                                textcolors=[30,225],/right
            device, /close_file, decomposed = 1
            !p.multi = 0
        endif
    endelse
endif
end
