pro fit_line_becca, pixelname, linename, wl, flux, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, baseline=baseline, test=test
;---------------------------------
A = FINDGEN(17) * (!PI*2/16.)
; Define the symbol to be a unit circle with 16 points, 
; and set the filled flag:
USERSYM, 0.5*COS(A), 0.5*SIN(A), /FILL
;---------------------------------
  c = 2.998d8
  ;make the unit consist with each other. Change F_nu (Jy) -> F_lambda (W cm-2 um-1)
  ;flux = flux*1d-4*c/(wl*1d-6)^2*1d-6*1d-26

  weight = 1+0*flux
  wl = double(wl)
  flux = double(flux)
  weight = double(weight)
  expo = round(alog10(abs(median(flux))))*(-1)+1
  factor = 10d^expo
  nwl = wl - median(wl)
  fluxx = flux*factor
  nflux = fluxx - median(fluxx)
  
  ;baseline part
if keyword_set(baseline) then begin
;    start = dblarr(2)
;    start[0] = (nflux[n_elements(nwl)-1] - nflux[0])/(nwl[n_elements(nwl)-1] - nwl[0])
;    start[1] = nflux(0)
;    ;Fit the baseline with 1st order polynomial
;    result = mpfitfun('base1d', nwl, nflux, weight, start, /quiet, perror=sigma, status = status, errmsg = errmsg)
;    p = result/factor & p_sig = sigma/factor
;    p[1] = p[1]+median(flux)
;    base = p[0]*(wl-median(wl)) + p[1]
;    base_para = [p[0],p[1]-p[0]*median(wl)]
;    mid_base = median(base)
;    residual = flux -base
    
    ;Fit the baseline with 2nd order polynomial
    start = dblarr(3)
    start[0] = 0
    start[1] = (nflux[n_elements(nwl)-1] - nflux[0])/(nwl[n_elements(nwl)-1] - nwl[0])
    start[2] = nflux(0)
    result = mpfitfun('base2d', nwl, nflux, weight, start, /quiet, perror=sigma, status=status, errmsg=errmsg)
    p = result/factor & p_sig = sigma/factor
    p[2] = p[2] + median(flux)
    base = p[0]*(wl-median(wl))^2 + p[1]*(wl-median(wl)) + p[2]
    base_para = [p[0], p[1]-2*p[0]*median(wl), p[2]-p[1]*median(wl)+p[0]*median(wl)^2]
    mid_base = median(base)
    residual = flux-base
    ;-------------------------------------------
    set_plot, 'ps'
    !p.font = 0
    device, filename='/Users/yaolun/Rebecca/plots/base/'+pixelname+'_'+linename+'base.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 14, decomposed = 0, /color
    loadct ,13
    !p.thick = 1 & !x.thick = 3 & !y.thick = 3
    plot, wl, flux/1d-22, psym = 10, xtitle = '!9m!3m', ytitle = '10!u-22!n W/cm!u2!n/!9m!3m'                   ;plot the original data
    oplot, wl, base/1d-22, color = 40                                                                           ;plot the fitted curve
    oplot, wl, residual/1d-22, psym = 10, color = 250                                                           ;plot the reidual
    device, /close, decomposed = 1
endif
  
  ;fit the baseline substracted spectrum with single Gaussian 
if not keyword_set(baseline) then begin
  indl = where(nwl gt line[1]-median(wl) and nwl lt line[2]-median(wl))
  nfluxx = nflux
  nflux = nflux[indl] & nwl = nwl[indl] & weight = weight[indl]
  r = -700*(median(wl)-200)/470+1000
  dl = median(wl)/r
  ;define the initial guess of the line profile
  start = dblarr(3)
  start[0] = max(nflux)
  start[1] = nwl[where(nflux eq max(nflux))]
  ind = where(nflux gt 0.5*(max(nflux) - min(nflux)) + min(nflux))
  start[2] = dl

  
  ;First, construct the structure of the constrain.  Here to constrain that the width of the Gaussian cannot larger than the range of the wavelength put into this program

  parinfo = replicate({parname:'', value:0.D, fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
  parinfo[*].parname = ['height','center','width']
  parinfo[*].value = start
  parinfo[0].limited = [1,0] & parinfo[0].limits[0] = 0
  parinfo[1].limited = [1,1] & parinfo[1].limits = line[1:2]-median(wl);[min(nwl), max(nwl)]
  parinfo[2].limited = [0,1] & parinfo[2].limits[1] = 10*dl
  
  ;Fit it!
  result = mpfitfun('gauss', nwl, nflux, weight, start, /quiet, perror=sigma, status = status, errmsg = errmsg, parinfo=parinfo)
  p = result
    if status gt 0 then begin
    ;Recover everything since they are changed at first.  And calculate the physical quantities
      rms2 = total((gauss(nwl,p)-nflux)^2)/(n_elements(wl)-2-1)
      rms = sqrt(rms2)
  
      sigma = sigma*rms
      cen_wl = p[1] + median(wl) & sig_cen_wl = sigma[1]
      height = p[0]/factor & sig_height = sigma[0]/factor
      fwhm = 2.354*abs(p[2]) & sig_fwhm = 2.354*abs(sigma[2])
      str = (2*!PI)^0.5*height*abs(p[2]) & sig_str = str*((sig_height/height)^2+(abs(sigma[2])/abs(p[2]))^2)^0.5
      gauss = height*exp(-(wl-cen_wl)^2/2/p[2]^2)
      residual = flux - gauss
      noise = stddev(residual)
      snr = height/noise
      
      if keyword_set(test) then begin
        if snr le 5 then begin
          set_plot, 'ps'
          !p.font = 0
          device, filename = '/Users/yaolun/Rebecca/plots/'+pixelname+'_'+linename+'_below5sigma.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 14, decomposed = 0, /color
          loadct ,13
          !p.thick = 1 & !x.thick = 3 & !y.thick = 3
          maxx = max([max(flux), p[0]/factor])
          minn = min([0,min(flux)])
          plot, wl, flux/1d-22, psym = 10, xtitle = '!9m!3m', ytitle = '10!u-22!n W/cm!u2!n/!9m!3m', yrange = [minn/1d-22, maxx*1.1/1d-22]        ;plot the baseline substracted spectrum
          oplot, wl, (gauss)/1d-22, color = 80                                                                                                    ;plot the fitted curve(Gaussian)
          oplot, wl, (flux-gauss)/1d-22, psym = 10, color = 250                                                                                   ;plot the residual
          oplot, [line[0], line[0]], [0,max(flux)*1.1]/1d-22, linestyle = 2
          xyouts, 0.2, 0.85, 'SNR='+strtrim(string(snr),1), /normal
          xyouts, 0.2, 0.8, 'FWHM='+strtrim(string(abs(p[2])),1), /normal
          xyouts, 0.7, 0.85, title_name(linename), /normal
          device, /close, decomposed = 1
          !p.multi = 0
        endif
      endif
      if not keyword_set(test) then begin
        ;Make a plot
        ;plot the well-functional fitting result
        set_plot, 'ps'
        !p.font = 0
        device, filename = '/Users/yaolun/Rebecca/plots/'+pixelname+'_'+linename+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 14, decomposed = 0, /color
        loadct ,13
        !p.thick = 3 & !x.thick = 3 & !y.thick = 3
        maxx = max([max(flux), p[0]/factor])
        minn = min([0,min(flux)])
        plot, wl, flux/1d-22, psym = 10, xtitle = '!9m!3m', ytitle = '10!u-22!n W/cm!u2!n/!9m!3m', yrange = [minn/1d-22, maxx*1.1/1d-22]        ;plot the baseline substracted spectrum
        oplot, wl, (gauss)/1d-22, color = 80                                                                                                    ;plot the fitted curve(Gaussian)
        oplot, wl, (flux-gauss)/1d-22, psym = 10, color = 250                                                                                              ;plot the residual
        oplot, [line[0], line[0]], [-50,50]/1d-22, linestyle = 2
        xyouts, 0.2, 0.85, 'SNR='+strtrim(string(snr),1), /normal
        xyouts, 0.2, 0.8, 'FWHM='+strtrim(string(abs(p[2])),1), /normal
        xyouts, 0.7, 0.85, title_name(linename), /normal
        device, /close_file, decomposed = 1
        !p.multi = 0
      endif
    endif else begin 
      offset = 0-min(flux)
      fluxs = flux + offset
      
      expo = round(alog10(abs(median(fluxs))))*(-1)+1
      factor = 10d^expo
      nwl = wl - median(wl)
      fluxx = fluxs*factor
      nflux = fluxx - median(fluxx)
      
      ;define the initial guess of the line profile
      r = -700*(median(wl)-200)/470+1000
      dl = median(wl)/r
      start = dblarr(3)
      start[0] = max(nflux)
      start[1] = nwl[where(nflux eq max(nflux))]
      ind = where(nflux gt 0.5*(max(nflux) - min(nflux)) + min(nflux))
      start[2] = dl;(max(nwl[ind]) - min(nwl[ind]))
  
      ;First, construct the structure of the constrain.  Here to constrain that the width of the Gaussian cannot larger than the range of the wavelength put into this program

      parinfo = replicate({parname:'', value:0.D, fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
      parinfo[*].parname = ['height','center','width']
      parinfo[*].value = start
      parinfo[0].limited = [1,0] & parinfo[0].limits[0] = 0
      parinfo[1].limited = [1,1] & parinfo[1].limits = line[1:2]-median(wl);[min(nwl), max(nwl)]
      parinfo[2].limited = [0,1] & parinfo[2].limits[1] = 10*dl
  
      ;Fit it!
      result = mpfitfun('gauss', nwl, nflux, weight, start, /quiet, perror=sigma, status = status, errmsg = errmsg, parinfo=parinfo)
      p = result
      if status gt 0 then begin
        print, 'GOTCHA!'
        ;Recover everything since they are changed at first.  And calculate the physical quantities
        rms2 = total((gauss(nwl,p)-nflux)^2)/(n_elements(wl)-2-1)
        rms = sqrt(rms2)
  
        sigma = sigma*rms
        cen_wl = p[1] + median(wl) & sig_cen_wl = sigma[1]
        height = p[0]/factor & sig_height = sigma[0]/factor
        fwhm = 2.354*abs(p[2]) & sig_fwhm = 2.354*abs(sigma[2])
        str = (2*!PI)^0.5*height*abs(p[2]) & sig_str = str*((sig_height/height)^2+(abs(sigma[2])/abs(p[2]))^2)^0.5
        gauss = height*exp(-(wl-cen_wl)^2/2/p[2]^2)
        residual = fluxs - gauss
        noise = stddev(residual)
        snr = height/noise
       ;plot it
        set_plot, 'ps'
        !p.font = 0
        device, filename = '/Users/yaolun/Rebecca/plots/cannot_fit/'+pixelname+'_'+linename+'_2nd.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 14, decomposed = 0, /color
        loadct ,13
        !p.thick = 3 & !x.thick = 3 & !y.thick = 3
        maxx = max([max(flux), p[0]/factor])
        minn = min([0,min(flux)])
        plot, wl, flux/1d-22, psym = 10, xtitle = '!9m!3m', ytitle = '10!u-22!n W/cm!u2!n/!9m!3m', yrange = [minn/1d-22, maxx*1.1/1d-22]        ;plot the baseline substracted spectrum
        oplot, wl, (gauss-offset)/1d-22, color = 80                                                                                                    ;plot the fitted curve(Gaussian)
        oplot, wl, (flux-gauss+offset)/1d-22, psym = 10, color = 250                                                                                              ;plot the residual
        oplot, [line[0], line[0]], [-50,50]/1d-22, linestyle = 2
        xyouts, 0.2, 0.85, 'SNR='+strtrim(string(snr),1), /normal
        xyouts, 0.2, 0.8, 'FWHM='+strtrim(string(abs(p[2])),1), /normal
        xyouts, 0.7, 0.85, title_name(linename), /normal
        device, /close_file, decomposed = 1
        !p.multi = 0
      endif else begin
        ;plot the spectrum when it is failed to converge
        ind = where(wl gt line[1] and wl lt line[2])
        fluxx = flux-min(flux)
        line_str = total(fluxx[ind])/(line[2]-line[1])
        noise = (total(fluxx)-total(fluxx[ind]))/(max(wl)-min(wl)-line[2]+line[1])
        if line_str/noise gt 2 then msg = '_over_2sigma' else msg = ''
        set_plot, 'ps'
        !p.font = 0
        device, filename = '/Users/yaolun/Rebecca/plots/cannot_fit/'+pixelname+'_'+linename+'cannot_fit'+msg+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 14, decomposed = 0, /color
        loadct ,13
        !p.thick = 3 & !x.thick = 3 & !y.thick = 3
        plot, wl, flux/1d-22, psym = 10, xtitle = '!9m!3m', ytitle = '10!u-22!n W/cm!u2!n/!9m!3m'  ;plot the baseline substracted spectrum
        oplot, [line[1], line[1]], [-50,50]/1d-22, linestyle = 2
        oplot, [line[2], line[2]], [-50,50]/1d-22, linestyle = 2
        xyouts, 0.2, 0.85, 'Fail to Converge', /normal
        xyouts, 0.2, 0.8, string(line_str/noise), /normal
        xyouts, 0.7, 0.85, title_name(linename), /normal
        device, /close_file, decomposed = 1
        !p.multi = 0
      endelse
 
    endelse

    
endif
end
