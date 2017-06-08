pro refine_fitting, indir=indir, filename=filename, outdir=outdir,oh2o=oh2o,ph2o=ph2o,co=co,oh=oh,co13=co13,hco=hco,other=other,all=all,cube=cube,pacs=pacs,spire=spire
if file_test(outdir) eq 0 then file_mkdir, outdir
;spawn, 'rm -f outdir/filename*.txt'
if keyword_set(pacs) then noiselevel=3
if keyword_set(spire) then noiselevel=4
if keyword_set(cube) then begin
	readcol, indir+filename+'.txt',format='A,D,D,D,D,D,D,D,D,D,D,D,D,D,D,A,A,A,I',$
		line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, pix_n, blend_n, valid_n, /silent
endif else begin
	readcol, indir+filename+'.txt',format='A,D,D,D,D,D,D,D,D,D,D,D,D,D,D,A,A,I',$
		line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, blend_n, valid_n, /silent
endelse

line_name_oh2o = ['o-H2O8_27-7_16','o-H2O10_29-10_110','o-H2O9_09-8_18','o-H2O7_52-8_27','o-H2O4_32-3_21','o-H2O5_41-6_16','o-H2O9_18-9_09','o-H2O8_18-7_07','o-H2O6_61-6_52','o-H2O7_61-7_52',$
    	              'o-H2O6_25-5_14','o-H2O7_16-6_25','o-H2O3_30-2_21','o-H2O3_30-3_03','o-H2O8_27-8_18','o-H2O7_07-6_16','o-H2O7_25-6_34','o-H2O3_21-2_12','o-H2O8_54-8_45','o-H2O6_52-6_43',$
    	              'o-H2O5_50-5_41','o-H2O7_52-7_43','o-H2O4_23-3_12','o-H2O9_27-9_18','o-H2O6_16-5_05','o-H2O8_36-8_27','o-H2O7_16-7_07','o-H2O8_45-8_36','o-H2O6_43-6_34','o-H2O6_25-6_16',$
    	              'o-H2O4_41-4_32','o-H2O6_34-6_25','o-H2O2_21-1_10','o-H2O7_43-7_34','o-H2O4_41-5_14','o-H2O4_14-3_03','o-H2O9_27-10_110','o-H2O8_36-9_09','o-H2O7_34-6_43','o-H2O4_32-4_23',$
    	              'o-H2O9_36-9_27','o-H2O7_25-7_16','o-H2O9_45-9_36','o-H2O4_23-4_14','o-H2O8_36-7_43','o-H2O5_14-5_05','o-H2O3_30-3_21','o-H2O5_23-4_32','o-H2O8_45-7_52','o-H2O6_34-7_07',$
    	              'o-H2O5_32-5_23','o-H2O7_34-7_25','o-H2O3_03-2_12','o-H2O4_32-5_05','o-H2O2_12-1_01','o-H2O2_21-2_12','o-H2O8_54-9_27','o-H2O5_23-5_14','o-H2O6_25-5_32','o-H2O8_45-9_18',$
    	              'o-H2O8_27-7_34','o-H2O7_43-6_52','o-H2O8_54-7_61','o-H2O3_21-3_12','o-H2O6_34-5_41','o-H2O3_12-2_21','o-H2O7_25-8_18','o-H2O3_12-3_03','o-H2O5_32-4_41','o-H2O1_10-1_01']
    	              
line_name_ph2o = ['p-H2O6_51-7_26','p-H2O7_71-7_62','p-H2O10_19-10_010','p-H2O4_31-3_22','p-H2O9_19-8_08','p-H2O4_22-3_13','p-H2O8_17-7_26','p-H2O6_42-7_17','p-H2O7_26-6_15','p-H2O8_26-7_35',$
					  'p-H2O7_62-8_35','p-H2O4_31-4_04','p-H2O4_40-5_15','p-H2O9_28-9_19','p-H2O8_08-7_17','p-H2O7_62-7_53','p-H2O3_31-2_20','p-H2O5_24-4_13','p-H2O7_17-6_06','p-H2O5_51-6_24',$
					  'p-H2O8_17-8_08','p-H2O9_37-9_28','p-H2O5_51-5_42','p-H2O7_53-7_44','p-H2O6_51-6_42','p-H2O6_15-5_24','p-H2O9_46-9_37','p-H2O8_53-8_44','p-H2O7_26-7_17','p-H2O8_35-7_44',$
					  'p-H2O6_06-5_15','p-H2O3_22-2_11','p-H2O7_44-7_35','p-H2O5_42-5_33','p-H2O6_42-6_33','p-H2O6_15-6_06','p-H2O5_24-5_15','p-H2O5_33-5_24','p-H2O9_46-8_53','p-H2O9_37-8_44',$
					  'p-H2O8_44-8_35','p-H2O4_04-3_13','p-H2O3_31-3_22','p-H2O7_53-8_26','p-H2O7_35-8_08','p-H2O3_13-2_02','p-H2O8_44-7_53','p-H2O4_13-3_22','p-H2O4_31-4_22','p-H2O8_35-8_26',$
					  'p-H2O5_42-6_15','p-H2O3_22-3_13','p-H2O3_31-4_04','p-H2O8_26-9_19','p-H2O6_24-6_15','p-H2O7_35-6_42','p-H2O6_33-6_24','p-H2O5_33-6_06','p-H2O4_13-4_04','p-H2O7_26-6_33',$
					  'p-H2O9_46-10_19','p-H2O7_44-8_17','p-H2O2_20-2_11','p-H2O4_22-4_13','p-H2O8_53-7_62','p-H2O7_44-6_51','p-H2O1_11-0_00','p-H2O2_02-1_11','p-H2O5_24-4_31','p-H2O4_22-3_31',$
					  'p-H2O9_28-8_35','p-H2O2_11-2_02','p-H2O6_24-7_17','p-H2O5_33-4_40','p-H2O6_42-5_51']

line_name_co = ['CO40-39','CO39-38','CO38-37','CO37-36','CO36-35','CO35-34','CO34-33','CO33-32','CO32-31','CO31-30',$
					'CO30-29','CO29-28','CO28-27','CO25-24','CO24-23','CO23-22','CO22-21','CO21-20','CO20-19',$;'CO27-26',
					'CO19-18','CO18-17','CO17-16','CO16-15','CO15-14','CO14-13','CO13-12','CO12-11','CO11-10','CO10-9',$
					'CO9-8','CO8-7','CO7-6','CO6-5','CO5-4','CO4-3']

line_name_oh = ['OH19-14','OH18-15','OH13-9','OH12-8','OH14-10','OH15-11','OH5-1','OH4-0','OH9-3','OH8-2',$
				    'OH10-8','OH11-9','OH3-1','OH2-0','OH14-12','OH15-13','OH19-16','OH18-17','OH7-5','OH6-4']
				    
line_name_13co = ['13CO13-12','13CO12-11','13CO11-10','13CO10-9','13CO9-8','13CO8-7','13CO7-6','13CO6-5','13CO5-4']

line_name_hco = ['HCO+16-15','HCO+15-14','HCO+14-13','HCO+13-12','HCO+12-11','HCO+11-10','HCO+10-9','HCO+9-8','HCO+8-7','HCO+7-6','HCO+6-5']

line_name_other = ['OI3P1-3P2','NII_122','OI3P0-3P1','CII2P3_2-2P1_2']

if keyword_set(all) then begin
	oh2o=1
	ph2o=1
	co=1
	oh=1
	co13=1
	hco=1
	other=1
endif

if keyword_set(oh2o) then begin
	if file_test(outdir+filename+'_oh2o.txt') eq 0 then begin
		openw, lun, outdir+filename+'_oh2o.txt',/get_lun
		printf, lun, format='((a14,2x),(a8,2x),2(a21,2x))','Line','Wave(um)','Str(W/cm2)','Str_sig(W/cm2)'
	endif else begin
		openw, lun, outdir+filename+'_oh2o.txt',/get_lun,/append
	endelse
	
	for i = 0, n_elements(line_name_oh2o)-1 do begin
		ind = where(line_name_n eq line_name_oh2o[i])
		if ((ind ne -1) and (snr_n[ind] ge noiselevel)) and (valid_n[ind] eq 1) then printf, lun, format='((a14,2x),(f8.3,2x),2(g21.8,2x))',line_name_n[ind],cen_wl_n[ind],str_n[ind],sig_str_n[ind]
	endfor
	free_lun, lun
	close, lun
endif
if keyword_set(ph2o) then begin
	if file_test(outdir+filename+'_ph2o.txt') eq 0 then begin
		openw, lun, outdir+filename+'_ph2o.txt',/get_lun
		printf, lun, format='((a14,2x),(a8,2x),2(a21,2x))','Line','Wave(um)','Str(W/cm2)','Str_sig(W/cm2)'
	endif else begin
		openw, lun, outdir+filename+'_ph2o.txt',/get_lun,/append
	endelse
	
	for i = 0, n_elements(line_name_ph2o)-1 do begin
		ind = where(line_name_n eq line_name_ph2o[i])
		if ((ind ne -1) and (snr_n[ind] ge noiselevel)) and (valid_n[ind] eq 1) then printf, lun, format='((a14,2x),(f8.3,2x),2(g21.8,2x))',line_name_n[ind],cen_wl_n[ind],str_n[ind],sig_str_n[ind]
	endfor
	free_lun, lun
	close, lun
endif
if keyword_set(co) then begin
	if file_test(outdir+filename+'_co.txt') eq 0 then begin
		openw, lun, outdir+filename+'_co.txt',/get_lun
		printf, lun, format='((a14,2x),(a8,2x),2(a21,2x))','Line','Wave(um)','Str(W/cm2)','Str_sig(W/cm2)'
	endif else begin
		openw, lun, outdir+filename+'_co.txt',/get_lun,/append
	endelse
	
	for i = 0, n_elements(line_name_co)-1 do begin
		ind = where(line_name_n eq line_name_co[i])
		if ((ind ne -1) and (snr_n[ind] ge noiselevel)) and (valid_n[ind] eq 1) then printf, lun, format='((a14,2x),(f8.3,2x),2(g21.8,2x))',line_name_n[ind],cen_wl_n[ind],str_n[ind],sig_str_n[ind]
	endfor
	free_lun, lun
	close, lun
endif
if keyword_set(oh) then begin
	if file_test(outdir+filename+'_oh.txt') eq 0 then begin
		openw, lun, outdir+filename+'_oh.txt',/get_lun
		printf, lun, format='((a14,2x),(a8,2x),2(a21,2x))','Line','Wave(um)','Str(W/cm2)','Str_sig(W/cm2)'
	endif else begin
		openw, lun, outdir+filename+'_oh.txt',/get_lun,/append
	endelse
	
	for i = 0, n_elements(line_name_oh)-1 do begin
		ind = where(line_name_n eq line_name_oh[i])
		if ((ind ne -1) and (snr_n[ind] ge noiselevel)) and (valid_n[ind] eq 1) then printf, lun, format='((a14,2x),(f8.3,2x),2(g21.8,2x))',line_name_n[ind],cen_wl_n[ind],str_n[ind],sig_str_n[ind]
	endfor
	free_lun, lun
	close, lun
endif
if keyword_set(co13) then begin
	if file_test(outdir+filename+'_13co.txt') eq 0 then begin
		openw, lun, outdir+filename+'_13co.txt',/get_lun
		printf, lun, format='((a14,2x),(a8,2x),2(a21,2x))','Line','Wave(um)','Str(W/cm2)','Str_sig(W/cm2)'
	endif else begin
		openw, lun, outdir+filename+'_13co.txt',/get_lun,/append
	endelse
	
	for i = 0, n_elements(line_name_13co)-1 do begin
		ind = where(line_name_n eq line_name_13co[i])
		if ((ind ne -1) and (snr_n[ind] ge noiselevel)) and (valid_n[ind] eq 1) then printf, lun, format='((a14,2x),(f8.3,2x),2(g21.8,2x))',line_name_n[ind],cen_wl_n[ind],str_n[ind],sig_str_n[ind]
	endfor
	free_lun, lun
	close, lun
endif
if keyword_set(hco) then begin
	if file_test(outdir+filename+'_hco.txt') eq 0 then begin
		openw, lun, outdir+filename+'_hco.txt',/get_lun
		printf, lun, format='((a14,2x),(a8,2x),2(a21,2x))','Line','Wave(um)','Str(W/cm2)','Str_sig(W/cm2)'
	endif else begin
		openw, lun, outdir+filename+'_hco.txt',/get_lun,/append
	endelse
	
	for i = 0, n_elements(line_name_hco)-1 do begin
		ind = where(line_name_n eq line_name_hco[i])
		if ((ind ne -1) and (snr_n[ind] ge noiselevel)) and (valid_n[ind] eq 1) then printf, lun, format='((a14,2x),(f8.3,2x),2(g21.8,2x))',line_name_n[ind],cen_wl_n[ind],str_n[ind],sig_str_n[ind]
	endfor
	free_lun, lun
	close, lun
endif 

if keyword_set(other) then begin
	if file_test(outdir+filename+'_atomic.txt') eq 0 then begin
		openw, lun, outdir+filename+'_atomic.txt',/get_lun
		printf, lun, format='((a14,2x),(a8,2x),2(a21,2x))','Line','Wave(um)','Str(W/cm2)','Str_sig(W/cm2)'
	endif else begin
		openw, lun, outdir+filename+'_atomic.txt',/get_lun,/append
	endelse
	
	for i = 0, n_elements(line_name_other)-1 do begin
		ind = where(line_name_n eq line_name_other[i])
		if ((ind ne -1) and (snr_n[ind] ge noiselevel)) and (valid_n[ind] eq 1) then printf, lun, format='((a14,2x),(f8.3,2x),2(g21.8,2x))',line_name_n[ind],cen_wl_n[ind],str_n[ind],sig_str_n[ind]
	endfor
	free_lun, lun
	close, lun
endif
end