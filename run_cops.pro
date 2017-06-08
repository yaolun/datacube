pro run_cops, indir=indir,outdir=outdir,fixed_width=fixed_width,localbaseline=localbaseline,global_noise=global_noise,noiselevel=noiselevel,test=test,corrected=corrected,cube=cube,$
	refine=refine,no_fit=no_fit,print_all=print_all,co_add=co_add,no_plot=no_plot,cops=cops,double_gauss=double_gauss,contour=contour,FWD=FWD,single=single,obj_flag=obj_flag,localnoise=localnoise

if not keyword_set(FWD) then tic
if not keyword_set(outdir) then outdir = indir
if file_test(outdir) eq 0 then file_mkdir, outdir
if keyword_set(no_plot) then begin
	no_plot = 1
endif else begin
	no_plot = 0
endelse
if not keyword_set(print_all) then print_all = 0

objname = []
case 1 of
	keyword_set(corrected): search_word = '*_spire_corrected.fits'
	keyword_set(cube): search_word = '*spectrum_extended_HR_aNB_15.fits'
endcase
; Get the data listing
;
filelist = file_search(indir, search_word)
proj_file = []
for file = 0, n_elements(filelist)-1 do begin
	hdr = headfits(filelist[file])
	; Fit the data observed by digit programs (simplify the data format)
	;
	case 1 of
		keyword_set(cops): proj_name = ['OT2_jgreen02_6','OT1_jgreen02_2','GT1_golofs01_4']
	endcase
	if total(sxpar(hdr, 'PROPOSAL') eq proj_name) eq 0 then begin
		continue
	endif
	objname = [objname, sxpar(hdr, 'OBJECT')]
	proj_file = [proj_file, filelist[file]]
endfor
proj_file = proj_file[sort(objname)]
objname = objname[sort(objname)]
for obj = 0, n_elements(objname)-1 do begin
	if strcompress(objname[obj],/remove_all) eq 'IRAS12496/HH54' then objname[obj] = 'IRAS12496'
	if strcompress(objname[obj],/remove_all) eq 'IRAS15398/B228' then objname[obj] = 'IRAS15398'
	if strcompress(objname[obj],/remove_all) eq 'GSS30IRS1' then objname[obj] = 'GSS30-IRS1'
	if strcompress(objname[obj],/remove_all) eq 'RCrAIRS5' then objname[obj] = 'RCrA-IRS5A'
	if strcompress(objname[obj],/remove_all) eq 'FUOrionis' then objname[obj] = 'FUOri'
	if strcompress(objname[obj],/remove_all) eq 'Ced110IRS4' then objname[obj] = 'Ced110-IRS4'
	if strcompress(objname[obj],/remove_all) eq 'IRAS03245+3002' then objname[obj] = 'IRAS03245'
	if strcompress(objname[obj],/remove_all) eq 'IRAS03301+3111' then objname[obj] = 'IRAS03301'
	if strcompress(objname[obj],/remove_all) eq 'L723MM' then objname[obj] = 'L723-MM'
	if strcompress(objname[obj],/remove_all) eq 'L1551IRS5' then objname[obj] = 'L1551-IRS5'
	if strmatch(objname[obj],'*-1') eq 1 then objname[obj] = strmid(objname[obj],0,strlen(objname[obj])-2)

	; if strcompress(objname[obj],/remove_all) ne 'BHR71' then continue ; comment this line for all objects fitting

	;if strmatch(objname[obj],'*/*') ne 0 then objname[obj] = (strsplit(objname[obj],'/',/extract))[0]+'_'+(strsplit(objname[obj],'/',/extract))[1]
endfor
; Find the files that are targeting to the same object and iterarte through them
i = 1
num_obj = 0
; Open a txt file and print everything into it
global_outname = '_lines'
if keyword_set(fixed_width) then global_outname = global_outname+'_fixwidth'
if keyword_set(print_all) and not keyword_set(no_fit) and not keyword_set(FWD) then begin
	if not keyword_set(cube) or (keyword_set(cube) and keyword_set(co_add)) then begin
    	openw, gff, outdir+print_all+global_outname+'.txt',/get_lun
		printf, gff, format='(19(a18,2x))',$
        	'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Blend','Validity'
		free_lun, gff
		close, gff

		openw, gff, outdir+print_all+global_outname+'_global_noise.txt',/get_lun
		printf, gff, format='(19(a18,2x))',$
			'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Blend','Validity'
		free_lun, gff
		close, gff

	endif
	if keyword_set(cube) and not keyword_set(coadd) then begin
		openw, gff, outdir+print_all+global_outname+'.txt',/get_lun
		printf, gff, format='(20(a18,2x))',$
				'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel_No.','Blend','Validity'
		free_lun, gff
		close, gff
		openw, gff, outdir+print_all+global_outname+'_global_noise.txt',/get_lun
		printf, gff, format='(20(a18,2x))',$
				'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel_No.','Blend','Validity'
		free_lun, gff
		close, gff
	endif
endif

; Prevent error only, need to be fixed in the future
if not keyword_set(print_all) and not keyword_set(FWD) then begin
	print_all = 'temp'
	global_outname = 'Unknown'
endif

global_outname = '_lines'
print, obj_flag[0]
if obj_flag[0] ne '0' then begin
	if obj_flag[0] eq '1' then begin
		cdf = ['B1-a','B1-c','B335','BHR71','Ced110-IRS4','FUOri','GSS30-IRS1','HH46','HH100','IRAS03245','IRAS03301','IRAS12496','IRAS15398','IRS46','L1014','L1157','L1455-IRS3',$
			   'L1551-IRS5','L483','L723-MM','RCrA-IRS5A','RCrA-IRS7B','RCrA-IRS7C','RNO91','TMC1','TMC1A','TMR1','V1057Cyg','V1331Cyg','V1515Cyg','V1735Cyg','VLA1623','WL12']
		; Debug option
		; cdf = ['BHR71']
	endif else begin
		cdf = obj_flag
	endelse
endif

; ignore object for 1d fitting which is done separately
;ignore_obj = ['B335','RCrA-IRS7B','BHR71']
ignore_obj = ['BHR71']
exception_obj = []
; Force to use Local noise for all sources
if keyword_set(localnoise) then exception_obj = objname

while i eq 1 do begin
	obj = where(objname eq objname[0])
	current_obj = strcompress(objname[0],/remove_all)
	filename = proj_file[obj]
	if array_equal(objname,objname[where(objname ne objname[0])]) then i = 0
	proj_file = proj_file[where(objname ne objname[0])]
	objname = objname[where(objname ne objname[0])]

	if keyword_set(FWD) then begin
		if file_test(outdir+'full_source_list.txt') eq 0 then begin
			openw, tot_list, outdir+'full_source_list.txt',/get_lun
			printf, tot_list, format='(4(a16,2x))', 'Object','PACS/SPIRE','Reduction','Noise'
			free_lun, tot_list
			close, tot_list
		endif
		if keyword_set(obj_flag) then begin
			if (where(cdf eq current_obj))[0] eq -1 then continue
		endif
		openw, tot_list, outdir+'full_source_list.txt',/get_lun, /append
		reduction = 'Standard'
		if keyword_set(cube) then reduction = 'spirecube'

		; Copy the fits files into the archive directory
		if file_test(outdir+current_obj+'/spire/data/fits/') eq 0 then file_mkdir, outdir+current_obj+'/spire/data/fits'
		file_copy, filename, outdir+current_obj+'/spire/data/fits/',/overwrite

		noisetype = 'None'
		; Print source info
		if (keyword_set(no_fit)) and (not keyword_set(contour)) then begin
			printf, tot_list, format='(4(a16,2x))',current_obj, 'SPIRE', reduction, noisetype
			free_lun, tot_list
			close, tot_list
			continue
		endif

	endif

	if keyword_set(single) then if current_obj ne single then continue

	if file_test(outdir+current_obj+'/spire/data',/directory) eq 0 then file_mkdir, outdir+current_obj+'/spire/data'

	if (where(ignore_obj eq current_obj))[0] ne -1 and not keyword_set(cube) then continue
	print, 'Fitting', current_obj, '...',format='(a7,x,a'+strtrim(string(strlen(current_obj)),1)+',a3)'
	; design for cpoying FITS files
	; if keyword_set(no_fit) then continue
	; "filename" contains the all of the filepath of the object in each iteration
	; Extract the fits files of each object now.  Output a two-column spectrum in ascii file and a whole spectrum plot.
	;
	if keyword_set(corrected) and (not keyword_set(no_fit)) then begin
		get_spire_1d, outdir=outdir+current_obj+'/spire/data/',object=current_obj,filename=filename,/fx
		get_radec_spire, filename=filename, pix, ra, dec, /central
	endif
	if keyword_set(cube) and (not keyword_set(no_fit)) then begin
		get_spire, outdir=outdir+current_obj+'/spire/data/cube/',object=current_obj,filename=filename,/brightness;/fx
		get_radec_spire, filename=filename, pix_slw, ra_slw, dec_slw, /slw
		get_radec_spire, filename=filename, pix_ssw, ra_ssw, dec_ssw, /ssw
	endif
	; Set the name of the ascii file containing the spectrum
	;
	;if keyword_set(corrected) then name = '_extended_corrected'
	;if keyword_set(cube) then name = '_spectrum_extended_HR_aNB_15'
	; Fitting part

	; For 1D spectra (extended corrected spectra)
	if not keyword_set(cube) and not keyword_set(no_fit) then begin
		; skip_obj = ['B335','RCrA-ISR7B','BHR71','HD142527','HD97048']
;		skip_obj = []
;		if (where(skip_obj eq current_obj))[0] ne -1 then continue
		; In case some spectra are complete enough to perform the smooth interpolation

		; special treatment for L1455-IRS3 since the corrected spectrum is not exist.
;		if current_obj ne 'L1455-IRS3' then begin
		if (where(exception_obj eq current_obj))[0] eq -1 then begin
			noisetype='Global'
			extract_spire, indir=outdir+current_obj+'/spire/data/',filename=current_obj+'_spire_corrected',outdir=outdir+current_obj+'/spire/advanced_products/',plotdir=outdir+current_obj+'/spire/advanced_products/plots/',fixed_width=fixed_width,localbaseline=localbaseline,$
						   global_noise=global_noise,ra=ra,dec=dec,noiselevel=noiselevel,/fx,object=current_obj,print_all=outdir+print_all+global_outname,/flat,/continuum,double_gauss=double_gauss,no_plot=no_plot
			msg = ''
			if keyword_set(fixed_width) then msg = '_fixwidth'
			outname = '_lines';+msg+'_global_noise'
		endif else begin
			noisetype='Local'
			extract_spire, indir=outdir+current_obj+'/spire/data/',filename=current_obj+'_spire_corrected',outdir=outdir+current_obj+'/spire/advanced_products/',plotdir=outdir+current_obj+'/spire/advanced_products/plots/',fixed_width=fixed_width,localbaseline=localbaseline,$
						   ra=ra,dec=dec,noiselevel=noiselevel,/fx,object=current_obj,print_all=outdir+print_all+global_outname,/flat,/continuum,double_gauss=double_gauss,no_plot=no_plot
			msg = ''
			if keyword_set(fixed_width) then msg = '_fixwidth'
			outname = '_lines';+msg
		endelse
;		endif else begin
;			if (where(exception_obj eq current_obj))[0] eq -1 then begin
;				noisetype='Global'
;				extract_spire, indir=outdir+current_obj+'/spire/data/',filename=current_obj+'_spire',outdir=outdir+current_obj+'/spire/advanced_products/',plotdir=outdir+current_obj+'/spire/advanced_products/plots/',fixed_width=fixed_width,localbaseline=localbaseline,$
;							   global_noise=global_noise,ra=ra,dec=dec,noiselevel=noiselevel,/fx,object=current_obj,print_all=outdir+print_all+global_outname,/flat,/continuum,double_gauss=double_gauss,no_plot=no_plot
;				msg = ''
;				if keyword_set(fixed_width) then msg = '_fixwidth'
;				outname = '_lines';+msg+'_global_noise'
;			endif else begin
;				noisetype='Local'
;				extract_spire, indir=outdir+current_obj+'/spire/data/',filename=current_obj+'_spire',outdir=outdir+current_obj+'/spire/advanced_products/',plotdir=outdir+current_obj+'/spire/advanced_products/plots/',fixed_width=fixed_width,localbaseline=localbaseline,$
;							   ra=ra,dec=dec,noiselevel=noiselevel,/fx,object=current_obj,print_all=outdir+print_all+global_outname,/flat,/continuum,double_gauss=double_gauss,no_plot=no_plot
;				msg = ''
;				if keyword_set(fixed_width) then msg = '_fixwidth'
;				outname = '_lines';+msg
;			endelse
;		endelse
	endif
	; For cube
	;
	if keyword_set(cube) and not keyword_set(co_add) then begin
		if (where(exception_obj eq current_obj))[0] eq -1 then begin
			noisetype='Global'
			msg = ''
			if keyword_set(fixed_width) then msg = '_fixwidth'
			outname = '_lines'
			if not keyword_set(no_fit) then begin
				; Print the fitting results of 25 spaxels into a single text file for each object
				if file_test(outdir+current_obj+'/spire/data/cube/') eq 0 then file_mkdir, outdir+current_obj+'/spire/data/cube/'
				; SLW
				extract_spire, indir=outdir+current_obj+'/spire/data/cube/',outdir=outdir+current_obj+'/spire/advanced_products/cube/',plotdir=outdir+current_obj+'/spire/advanced_products/cube/plots/',fixed_width=fixed_width,localbaseline=localbaseline,$
						   global_noise=global_noise,ra=ra_slw,dec=dec_slw,coordpix=pix_slw,/slw,noiselevel=noiselevel,/brightness,object=current_obj,print_all=outdir+print_all+global_outname,/flat,/continuum,$
						   /current_pix,double_gauss=double_gauss,no_plot=no_plot
				; SSW
				extract_spire, indir=outdir+current_obj+'/spire/data/cube/',outdir=outdir+current_obj+'/spire/advanced_products/cube/',plotdir=outdir+current_obj+'/spire/advanced_products/cube/plots/',fixed_width=fixed_width,localbaseline=localbaseline,$
						   global_noise=global_noise,ra=ra_ssw,dec=dec_ssw,coordpix=pix_ssw,/ssw,noiselevel=noiselevel,/brightness,object=current_obj,print_all=outdir+print_all+global_outname,/flat,/continuum,$
						   /current_pix,double_gauss=double_gauss,no_plot=no_plot
			endif

		endif else begin
			noisetype='Local'
			msg = ''
			if keyword_set(fixed_width) then msg = '_fixwidth'
			outname = '_lines'
			if not keyword_set(no_fit) then begin
				; Print the fitting results of 25 spaxels into a single text file for each object
				if file_test(outdir+current_obj+'/spire/data/cube/') eq 0 then file_mkdir, outdir+current_obj+'/spire/data/cube/'
				;openw, gff, outdir+current_obj+'/cube/data/'+current_obj+outname+'.txt',/get_lun
				; SLW
				extract_spire, indir=outdir+current_obj+'/spire/data/cube/',outdir=outdir+current_obj+'/spire/advanced_products/cube/',plotdir=outdir+current_obj+'/spire/advanced_products/cube/plots/',fixed_width=fixed_width,localbaseline=localbaseline,$
						   ra=ra_slw,dec=dec_slw,coordpix=pix_slw,/slw,noiselevel=noiselevel,/brightness,object=current_obj,print_all=outdir+print_all+global_outname,/flat,/continuum,/current_pix,double_gauss=double_gauss,no_plot=no_plot
				; SSW
				extract_spire, indir=outdir+current_obj+'/spire/data/cube/',outdir=outdir+current_obj+'/spire/advanced_products/cube/',plotdir=outdir+current_obj+'/spire/advanced_products/cube/plots/',fixed_width=fixed_width,localbaseline=localbaseline,$
						   ra=ra_ssw,dec=dec_ssw,coordpix=pix_ssw,/ssw,noiselevel=noiselevel,/brightness,object=current_obj,print_all=outdir+print_all+global_outname,/flat,/continuum,/current_pix,double_gauss=double_gauss,no_plot=no_plot
			endif
		endelse
	endif
	; For cube, but co-add the SLW and SSW spaxels into 1d spectrum at first, but still fit them separately
	;
	if keyword_set(cube) and keyword_set(co_add) and not keyword_set(no_fit) then begin
		ra = ra[where(pix_slw eq 'SLWC3')]
		dec = dec[where(pix_slw eq 'SLWC3')]
		summed_spire, indir=outdir+current_obj+'/spire/data/cube/', outdir=outdir+current_obj+'/spire/advanced_products/cube/', object=current_obj, plot=outdir+current_obj+'/'
		; In case some spectra are complete enough to perform the smooth interpolation
		; Change '_spire_corrected' to whatever the filename after co-add process
		if (where(exception_obj eq current_obj))[0] eq -1 then begin
			noisetype='Global'
			extract_spire, indir=outdir+current_obj+'/spire/data/cube/',filename=current_obj+'_spire_cube_coadd',outdir=outdir+current_obj+'/spire/advanced_products/cube/',plotdir=outdir+current_obj+'/spire/advanced_products/cube/plots/',fixed_width=fixed_width,localbaseline=localbaseline,$
						   global_noise=global_noise,ra=ra,dec=dec,noiselevel=noiselevel,/fx,object=current_obj,print_all=outdir+print_all+global_outname,/flat,/continuum,double_gauss=double_gauss,no_plot=no_plot
			msg = ''
			if keyword_set(fixed_width) then msg = '_fixwidth'
			outname = '_lines'
		endif else begin
			noisetype='Local'
			extract_spire, indir=outdir+current_obj+'/spire/data/cube/',filename=current_obj+'_spire_cube_coadd',outdir=outdir+current_obj+'/spire/advanced_products/cube/',plotdir=outdir+current_obj+'/spire/advanced_products/cube/plots/',fixed_width=fixed_width,localbaseline=localbaseline,$
						   ra=ra,dec=dec,noiselevel=noiselevel,/fx,object=current_obj,print_all=outdir+print_all+global_outname,/flat,/continuum,double_gauss=double_gauss,no_plot=no_plot
			msg = ''
			if keyword_set(fixed_width) then msg = '_fixwidth'
			outname = '_lines'
		endelse
	endif
	; Write the information of different species into different files
	;

	if keyword_set(refine) and not keyword_set(cube) then begin
;		refine_list = file_search(outdir+current_obj+'/spire/advanced_products/species_separated/', current_obj+name+'*')
;		if n_elements(refine_list) eq 1 then begin
;			if strlen(refine_list) gt 0 then file_delete,refine_list,/allow_nonexistent,/recursive
;		endif
		;print,'-----> Clean up (species_separated) folder for updating the results.'
		refine_fitting, indir=outdir+current_obj+'/spire/advanced_products/',filename=current_obj+'_spire_corrected'+outname,outdir=outdir+current_obj+'/spire/advanced_products/species_separated/',/all,/spire
	endif

	if keyword_set(refine) and keyword_set(cube) and keyword_set(co_add) then begin
;		refine_list = file_search(outdir+current_obj+'/spire/advanced_products/cube/species_separated/', current_obj+'_summed_*')
;		if n_elements(refine_list) eq 1 then begin
;			if strlen(refine_list) gt 0 then file_delete,refine_list,/allow_nonexistent,/recursive
;		endif
		;print,'-----> Clean up (species_separated) folder for updating the results.'
		refine_fitting, indir=outdir+current_obj+'/spire/advanced_products/cube/',filename=current_obj+'_summed_'+outname,outdir=outdir+current_obj+'/spire/advanced_products/cube/species_separated/',/all,/spire,/cube
	endif

	if keyword_set(refine) and keyword_set(cube) and not keyword_set(co_add) then begin
		name_slw = ['SLWA1','SLWA2','SLWA3','SLWB1','SLWB2','SLWB3','SLWB4','SLWC1','SLWC2','SLWC3','SLWC4','SLWC5','SLWD1','SLWD2','SLWD3','SLWD4','SLWE1','SLWE2','SLWE3']
		name_ssw = ['SSWA1','SSWA2','SSWA3','SSWA4','SSWB1','SSWB2','SSWB3','SSWB4','SSWB5','SSWC1','SSWC2','SSWC3','SSWC4','SSWC5','SSWC6','SSWD1','SSWD2','SSWD3','SSWD4','SSWD6','SSWD7','SSWE1','SSWE2','SSWE3','SSWE4','SSWE5','SSWE6','SSWF1','SSWF2','SSWF3','SSWF5','SSWG1','SSWG2','SSWG3','SSWG4']
		pix_name = [name_slw, name_ssw]
		for pix = 0, n_elements(pix_name)-1 do begin
;			refine_list = file_search(outdir+current_obj+'/spire/advanced_products/cube/species_separated/', current_obj+'_'+pix_name[pix]+'*')
;			if n_elements(refine_list) eq 1 then begin
;				if strlen(refine_list) gt 0 then file_delete,refine_list,/allow_nonexistent,/recursive
;			endif
			;print,'----> Clean up (species_separated) folder for updating the results.'
			refine_fitting, indir=outdir+current_obj+'/spire/advanced_products/cube/',filename=current_obj+'_'+pix_name[pix]+outname,outdir=outdir+current_obj+'/spire/advanced_products/cube/species_separated/',/all,/spire,/cube
		endfor
	endif

	; Plot the contour
	if keyword_set(contour) and keyword_set(cube) then begin
		skip = ['GSS30-IRS1','IRAS15398','IRAS03301','L723-MM','TMC1','VLA1623']
		skip = []
		if (where(skip eq strcompress(current_obj,/remove_all)))[0] ne -1 then break
		print, 'Plotting the contour plots...'
		; plot_contour, noise=3, indir=outdir+current_obj+'/spire/advanced_products/cube/',plotdir=outdir+'contour/'+current_obj+'/',objname=current_obj,/spire,/brightness
		; Plot position of IRS2 in BHR71
		plot_contour, noise=3, indir=outdir+current_obj+'/spire/advanced_products/cube/',plotdir=outdir+'contour/'+current_obj+'/',objname=current_obj,/spire,/brightness, plot_irs2=[180.392041667, -65.1464888889]
	endif

	if not keyword_set(no_fit) then begin
		printf, tot_list, format='(4(a16,2x))',current_obj, 'SPIRE', reduction, noisetype
		free_lun, tot_list
		close, tot_list
	endif else begin
		free_lun, tot_list
		close, tot_list
	endelse

	num_obj = num_obj+1
endwhile
print, 'Finish fitting', strtrim(string(num_obj),1),'objects (SPIRE)',format='(a14,x,a3,x,a7)'
if not keyword_set(FWD) then toc
end
