PRO spec_continuum_smooth, wave, flux, continuum, continuum_error, continuum_error_2,$ 
	fit=fit, w1=wave_1, w2=wave_2, sbin=sbin, maxiter=maxiter, upper=upper, $
	lower=lower, plot=plot

  on_error,3 

  if (NOT keyword_set(w1)) 	then w1 	= !x.range[0]
  if (NOT keyword_set(w2)) 	then w2 	= !x.range[1]
  if (NOT keyword_set(maxiter)) then maxiter 	= 1000
  if (NOT keyword_set(upper))   then upper   	= 2
  if (NOT keyword_set(lower))   then lower   	= 3
  if (NOT keyword_set(sbin))    then sbin  	= 20
  
  kk      = where((wave ge wave_1) and (wave le wave_2))
  k_wave  = wave(kk)
  k_flux  = flux(kk)
  mom     = moment(k_flux)
  std     = sqrt(mom[1])
  err     = replicate(std, n_elements(kk))
  xdata   = k_wave
  ydata   = k_flux

  iiter   = 0
  outmask = 0 * ydata + 1 			; Begin with all points good
  ymodel  = smooth(ydata, sbin, /nan, /edge_mirror)
  ymodel0 = ymodel
  mom	  = moment(ymodel-ydata)
  continuum_error = sqrt(mom(1))*abs(interpol(ymodel, k_wave, (wave_2 + wave_1)/2.))   ;Add the absolute function  Yao-Lun
  ;print, '3 sigma = ', string(3.*continuum_error, f='(e10.3)')
  ;print, mom[1]
  sigma     = replicate(continuum_error, n_elements(kk))
  ;cleanplot
  ;set_plot,'x'
  ;plot, wave,ydata
  ;stop
  while (NOT keyword_set(qdone) AND iiter LE maxiter) do begin
     qdone  = djs_reject(ydata, ymodel, outmask=outmask, sigma=sigma, upper=upper, lower=lower);, /sticky
     index  = where(outmask eq 0)
     xgood  = xdata(index)
     ygood  = ydata(index)
     err    = err(index)
     ymodel = smooth(ygood, sbin, /nan, /edge_mirror)
     ymodel = interpol(ymodel, xgood, xdata)
	 ;oplot,wave, ymodel, linestyle=2
     iiter  = iiter + 1
  endwhile
  continuum 	= interpol(ymodel, xdata, wave)
  continuum	= smooth(continuum, 12)   ; Thinking about changing this later
  ind 		= where(outmask eq 0)
  ind2 		= where(outmask eq 1)
  ;mom		= moment(ymodel(ind2)/ydata(ind2))
  mom_2		= moment(ymodel/ydata)
  continuum_error_2 = sqrt(mom_2(1))*abs(interpol(continuum, wave, (wave_2 + wave_1)/2.))  ;Add the absolute function  Yao-Lun
  ;print, '3 sigma (new)= ', string(3.*continuum_error_2, f='(e10.3)')

if (keyword_set(plot)) then begin
  oplot, xdata, ymodel0, color=2 
  oplot, xdata, ymodel,  thick=2, color=3
  oplot, xdata, ymodel+3.*continuum_error, line=3, thick=2, color=3
  oplot, xdata, ymodel-3.*continuum_error, line=3, thick=2, color=3
  if (ind[0] ne -1) then plots, xdata(ind), ydata(ind), psym=2, color=2, thick=2
text = 	' Mode = Smooth'+ $
	', sbin  = '+string(strcompress(long(sbin))) + $
	', lower = '+string(strcompress(long(lower)))  + $
	', upper = '+string(strcompress(long(upper)))  + $
	', 3sigma = '+string(strcompress(3.*continuum_error), f='(e10.3)')
  xyouts, 0.1, 0.03, text, /normal, charsize=2, color=3

endif

END

