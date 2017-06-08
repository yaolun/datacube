pro run_fit, test=test
pixelname_slw = ['SLWA1','SLWA2','SLWA3','SLWB1','SLWB2','SLWB3','SLWB4','SLWC1','SLWC2','SLWC3','SLWC4','SLWC5','SLWD1','SLWD2','SLWD3','SLWD4','SLWE1','SLWE2','SLWE3']
;This part is for SLW module.
;pixelname_slw = ['SLWC2']
for i = 0, n_elements(pixelname_slw)-1 do begin
readcol, '~/Rebecca/L1455-IRS3_spirecube/L1455-IRS3_'+pixelname_slw[i]+'.txt', format='D,D',wl, flux
c = 2.998d8
flux = flux*1d-4*c/(wl*1d-6)^2*1d-6*1d-26
;some useful information
;you can construct array that contains the position of pixels and other information
line_name = ['H2O303','CO8-7','13CO8-7','CO7-6','CI370','13CO7-6','H2O398','CO6-5','13CO6-5','HCOP7-6','CO5-4','H2O529','13CO5-4','CI610','CO4-3']
line_center = [303.67,325.26,340.42,371.65,370.3,389.01,398.92,433.56,453.81,480.13,520.23,538.29,544.54,608.95,650.25]
range = [[303,305],[324,326],[339.5,340.5],[370.5,372.5],[369.5,370.5],[388,389.5],[397,399.5],[432,435],[452,455],[479,482],[516,522],[536,540],[542,546],[607,611],[647,654]]
cont = [[301,303,304,306],[321,324,326,329],[336,339.5,340.5,343],[355,372,373,388],[355,369,370,388],[380,388,389.5,393],[393,397,401,415],[425,432,435,442],[442,452,455,470],$
       [465,479,482,499],[503,518,522,531],[525,536,540,542],[540,541,546,563],[590,607,611,628],[628,647,654,662]]
;line_name = ['CI370']
;line_center = [370.3]
;range = [369.5,370.5]
;cont = [355,369,370,388]
;=======================================================================================
openw, lun, '~/Rebecca/data/'+pixelname_slw[i]+'lines.txt', /get_lun
printf, lun, format='((a16,2x),8(a16,2x))', 'Line', 'WL (um)', 'Sig_Cen (um)', 'Str(erg/cm2)', 'Sig_str(erg/cm2)', 'FWHM (um)', 'Sig_FWHM (um)', 'Base_str', 'SNR'
  for j = 0, n_elements(line_name)-1 do begin
    ;select the baseline
    indb = where((wl gt cont[0,j] and wl lt cont[1,j]) or (wl gt cont[2,j] and wl lt cont[3,j]))
    wlb = wl[indb] & fluxb = flux[indb]
    ;fit the baseline and return the baseline parameter in 'base_para'
    fit_line_becca, pixelname_slw[i],line_name[j], wlb, fluxb, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, /baseline
    ;select the line+baseline
    indl = where(wl gt cont[0,j] and wl lt cont[3,j])
    ;indl = where(wl gt range[0,J] and wl lt range[1,j])
    wll = wl[indl] & fluxl = flux[indl]
    ;use 1st order polynomial
    ;base = base_para[0]*wll +base_para[1]
    ;use 2nd order polynomial
    base = base_para[0]*wll^2+base_para[1]*wll+base_para[2]
    fluxx = fluxl - base
    line = [line_center[j],range[0,j],range[1,j]]
      if keyword_set(test) then fit_line_becca, pixelname_slw[i],line_name[j], wll, fluxx, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, /test
      if not keyword_set(test) then fit_line_becca, pixelname_slw[i],line_name[j], wll, fluxx, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line
      if status le 0 then begin
        printf, lun, format = '((a16,2X),(a50))', line_name[j], errmsg
      endif else begin
        base_str = interpol(fluxx, wll, cen_wl)
        printf, lun, format = '((a16,2X),10(g16.4,2X))', line_name[j], cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_str, snr
      endelse
    endfor
free_lun, lun
close, lun
endfor

pixelname_ssw = ['SSWA1','SSWA2','SSWA3','SSWA4','SSWB1','SSWB2','SSWB3','SSWB4','SSWC1','SSWC2','SSWC3','SSWC4','SSWC5','SSWC6','SSWD1','SSWD2','SSWD3','SSWD4','SSWD6','SSWD7','SSWE1','SSWE2','SSWE3',$
         'SSWE4','SSWE5','SSWE6','SSWF1','SSWF2','SSWF3','SSWF5','SSWG1','SSWG2','SSWG3','SSWG4']
;pixelname_ssw = []
for i = 0, n_elements(pixelname_ssw)-1 do begin
readcol, '~/Rebecca/L1455-IRS3_spirecube/L1455-IRS3_'+pixelname_ssw[i]+'.txt', format='D,D',wl, flux
c = 2.998d8
flux = flux*1d-4*c/(wl*1d-6)^2*1d-6*1d-26
;some useful information
;you can construct array that contains the position of pixels and other information
line_name = ['CO13-12','NII205','CO12-11','CO11-10','13CO11-10','CO10-9','H2O269','13CO10-9','CO9-8']
line_center = [200.27,205.178,216.93,236.61,247.66,260.24,269.46,272.39,289.12]
range = [[199.7,200.7],[204.6,205.8],[216.5,217.2],[236.0,237.2],[247,248],[259.6,260.6],[268.8,269.7],[271.9,272.6],[288.5,289.7]]
cont = [[198.7,199.6,200.8,203.5],[203.5,204.5,206,210],[210,216.5,217.5,220],[230,235.5,237.5,245],[245,247,248,255],[255,259.5,260.7,267],[262,268.8,269.7,271],[270,271.3,272.8,280],[280,288.5,289.8,291]]
;line_name = []
;line_center = []
;range = []
;cont = []
;=======================================================================================
openw, lun, '~/Rebecca/data/'+pixelname_ssw[i]+'lines.txt', /get_lun
printf, lun, format='((a16,2x),8(a16,2x))', 'Line', 'WL (um)', 'Sig_Cen (um)', 'Str(erg/cm2)', 'Sig_str(erg/cm2)', 'FWHM (um)', 'Sig_FWHM (um)', 'Base_str', 'SNR'
  for j = 0, n_elements(line_name)-1 do begin
    ;select the baseline
    indb = where((wl gt cont[0,j] and wl lt cont[1,j]) or (wl gt cont[2,j] and wl lt cont[3,j]))
    wlb = wl[indb] & fluxb = flux[indb]
    ;fit the baseline and return the baseline parameter in 'base_para'
    fit_line_becca, pixelname_ssw[i],line_name[j], wlb, fluxb, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, /baseline
    ;select the line+baseline
    indl = where(wl gt cont[0,j] and wl lt cont[3,j])
    ;indl = where(wl gt range[0,J] and wl lt range[1,j])
    wll = wl[indl] & fluxl = flux[indl]
    ;use 1st order polynomial
    ;base = base_para[0]*wll +base_para[1]
    ;use 2nd order polynomial
    base = base_para[0]*wll^2+base_para[1]*wll+base_para[2]
    fluxx = fluxl - base
    line = [line_center[j],range[0,j],range[1,j]]
      if keyword_set(test) then fit_line_becca, pixelname_ssw[i],line_name[j], wll, fluxx, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, /test
      if not keyword_set(test) then fit_line_becca, pixelname_ssw[i],line_name[j], wll, fluxx, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line
      if status le 0 then begin
        printf, lun, format = '((a16,2X),(a50))', line_name[j], errmsg
      endif else begin
        base_str = interpol(fluxx, wll, cen_wl)
        printf, lun, format = '((a16,2X),10(g16.4,2X))', line_name[j], cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_str, snr
      endelse
    endfor
free_lun, lun
close, lun
endfor
end