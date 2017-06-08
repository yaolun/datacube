;a linear interpolation of the SPIRE beamsize at a given wavelength
function intpsf,wavein,spire=spire

;SPIRE beam data
;Wavenumber Wavelength Beamsize(arcsec)
spirebeam=[[47.0, 212.8, 16.9],$
[42.0, 238.1, 17.6],$
[40.5, 246.9, 17.1],$
[35.5, 281.7, 18.7],$
[31.3, 319.5, 21.1],$
[32.0, 312.5, 37.3],$
[24.8, 403.2, 33.4],$
[23.5, 425.5, 29.2],$
[22.0, 454.5, 30.0],$
[20.0, 500.0, 32.4],$
[18.0, 555.6, 33.0],$
[14.9, 671.1, 42.0]]

;waverebin=[congrid(wave[where(wave LT 100)],n_elements(wave)/150),congrid(wave[where(wave GT 100 and wave LT 190)],n_elements(wave)/50),wave[where(wave GT 100 and wave GT 190)]]
;fluxrebin=[congrid(flux[where(wave LT 100)],n_elements(wave)/150),congrid(flux[where(wave GT 100 and wave LT 190)],n_elements(wave)/50),flux[where(wave GT 100 and wave GT 190)]]

;wavein=200.+5*findgen(100)
if not keyword_set(spire) then spire=1

if keyword_set(spire) then beamrebin=interpol(spirebeam[2,*],spirebeam[1,*],wavein)
;plot,wavein,beamrebin

return, beamrebin
end
