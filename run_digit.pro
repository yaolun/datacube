pro run_digit, indir=indir,outdir=outdir,fixed_width=fixed_width,localbaseline=localbaseline,global_noise=global_noise,noiselevel=noiselevel,test=test,$
    central9=central9,centralyes=centralyes,centralno=centralno,cube=cube,hsa_cube=hsa_cube,jitter=jitter,nojitter=nojitter,refine=refine,no_fit=no_fit,print_all=print_all,$
    co_add=co_add,no_plot=no_plot,proj=proj,double_gauss=double_gauss,contour=contour,FWD=FWD,single=single,obj_flag=obj_flag,localnoise=localnoise
; don’t use the jitter-corrected version for L1455-IRS3, L1014, Serpens-SMM4, RCrA-IRS5A, RCrA-IRS7C, or IRAM 04191.
if not keyword_set(FWD) then tic
if not keyword_set(outdir) then outdir = indir
if file_test(outdir) eq 0 then file_mkdir, outdir
if keyword_set(no_plot) then begin
    no_plot = 1
endif else begin
	 no_plot = 0
endelse

objname = []
suffix = ''
word2 = ''
if keyword_set(cube) then suffix = 'os8_sf7'
if keyword_set(jitter) then word2 = suffix+'.fits'
if keyword_set(nojitter) then word2 = suffix+'_nojitter.fits'
case 1 of
  	keyword_set(central9): search_word = '*central9Spaxels_PointSourceCorrected_slice_00*'+word2
  	keyword_set(centralyes): search_word = '*centralSpaxel_PointSourceCorrected_Corrected3x3YES_slice_00*'+word2
  	keyword_set(centralno): search_word = '*centralSpaxel_PointSourceCorrected_Corrected3x3NO_slice_00*'+word2
  	keyword_set(cube): search_word = 'OBSID*finalcubes_slice00*'+word2
endcase

; Get the data listing
;
if not keyword_set(hsa_cube) then begin
    filelist = file_search(indir, search_word)
endif else begin
    search_word = ['hpacs*_20hps3drbs_00*', 'hpacs*_20hps3drrs_00*']
    filelist = [file_search(indir, search_word[0]), file_search(indir, search_word[1])]
    suffix = 'hsa'
endelse
if n_elements(filelist) eq 0 then begin
  	return
  	end
digit_file = []
for file = 0, n_elements(filelist)-1 do begin
  	hdr = headfits(filelist[file])
  	scan_mode = sxpar(hdr,'INSTMODE')
  	; Fit the data observed by digit programs (simplify the data format)
  	;
  	case 1 of
    		proj eq 'digit': proj_name = ['KPOT_nevans_1','SDP_nevans_3']
    		proj eq 'foosh': proj_name = ['OT1_jgreen02_2','TOO_jgreen02_4']
    		proj eq 'wish' : proj_name = ['KPGT_evandish_1','SDP_evandish_3']
  	endcase
  	if (total(sxpar(hdr, 'PROPOSAL') eq proj_name) eq 0) or (scan_mode ne 'PacsRangeSpec') then begin
        continue
  	endif
  	objname = [objname, sxpar(hdr, 'OBJECT')]
  	digit_file = [digit_file, filelist[file]]
endfor
digit_file = digit_file[sort(objname)]
objname = objname[sort(objname)]

for obj = 0, n_elements(objname)-1 do begin
  	if strmatch(objname[obj],'*-1') eq 1 then objname[obj] = strmid(objname[obj],0,strlen(objname[obj])-2)
  	if strcompress(objname[obj],/remove_all) eq 'SerSMM1' then objname[obj] = 'Serpens-SMM1'
  	if strcompress(objname[obj],/remove_all) eq 'NGC1333IRAS4B' then objname[obj] = 'NGC1333-IRAS4B'
  	if strcompress(objname[obj],/remove_all) eq 'NGC1333IRAS4A' then objname[obj] = 'NGC1333-IRAS4A'
  	if strcompress(objname[obj],/remove_all) eq 'NGC1333IRAS2' then objname[obj] = 'NGC1333-IRAS2A'
  	if strcompress(objname[obj],/remove_all) eq 'VLA1623-243' then objname[obj] = 'VLA1623'
  	if strcompress(objname[obj],/remove_all) eq 'IRAS03245+3002' then objname[obj] = 'IRAS03245'
  	if strcompress(objname[obj],/remove_all) eq 'IRAS03301+3111' then objname[obj] = 'IRAS03301'
  	if strcompress(objname[obj],/remove_all) eq 'FUOrionis' then objname[obj] = 'FUOri'
  	if strmatch(digit_file[obj],'*1342221379*',/fold_case) eq 1 then objname[obj] = 'HBC722_May2011'
  	if strmatch(digit_file[obj],'*1342221380*',/fold_case) eq 1 then objname[obj] = 'HBC722_May2011'
  	if strmatch(digit_file[obj],'*1342211173*',/fold_case) eq 1 then objname[obj] = 'HBC722_Dec2010'
  	if strmatch(digit_file[obj],'*1342211174*',/fold_case) eq 1 then objname[obj] = 'HBC722_Dec2010'
endfor

objname = objname[where(strmatch(digit_file, '*basic*',/fold_case) ne 1)]
digit_file = digit_file[where(strmatch(digit_file, '*basic*',/fold_case) ne 1)]

; if not keyword_set(cube) then begin
  	; Exclude every with 'basic' and not using 'os8sf7' parameters
  	;
    ;	objname = objname[where(strmatch(digit_file, '*basic*',/fold_case) ne 1)]
    ;	digit_file = digit_file[where(strmatch(digit_file, '*basic*',/fold_case) ne 1)]
    ;	objname = objname[where(strmatch(digit_file, '*os8sf7*',/fold_case) eq 1)]
    ;	digit_file = digit_file[where(strmatch(digit_file, '*os8sf7*',/fold_case) eq 1)]
  	; Other temperary exclusion
  	;
  	; objname = objname[where(strmatch(digit_file, '*HD203024*',/fold_case) ne 1)]
  	; digit_file = digit_file[where(strmatch(digit_file, '*HD203024*',/fold_case) ne 1)]
  	; objname = objname[where(strmatch(digit_file, '*HD245906*',/fold_case) ne 1)]
  	; digit_file = digit_file[where(strmatch(digit_file, '*HD245906*',/fold_case) ne 1)]
  	;
  	; WISH range scan object: Serpens-SMM1, NGC1333 IRAS2A, NGC1333 IRAS4A, and NGC1333 IRAS4B
  	;if proj eq 'wish' then begin
  	; NGC1333 IRAS2
  	;objname = objname[where(strmatch(digit_file, '*1342190686*',/fold_case) ne 1)]
  	;digit_file = digit_file[where(strmatch(digit_file, '*1342190686*',/fold_case) ne 1)]
  	; Ser SMM1
  	;objname = objname[where(strmatch(digit_file, '*1342207781*',/fold_case) ne 1)]
  	;digit_file = digit_file[where(strmatch(digit_file, '*1342207781*',/fold_case) ne 1)]
  	;endif
; endif
; if keyword_set(cube) and proj eq 'wish' then begin
  	; objname = objname[where(strmatch(digit_file, '*slice*',/fold_case) ne 1)]
  	; digit_file = digit_file[where(strmatch(digit_file, '*slice*',/fold_case) ne 1)]
    ;	objname = objname[where(strmatch(digit_file, '*basic*',/fold_case) ne 1)]
    ;	digit_file = digit_file[where(strmatch(digit_file, '*basic*',/fold_case) ne 1)]
; endif

;objname = objname[where(strmatch(digit_file, '*TMC1_*',/fold_case) eq 1)]
;digit_file = digit_file[where(strmatch(digit_file, '*TMC1_*',/fold_case) eq 1)]
;Find the files that are targeting to the same object and iterarte through them
i = 1
num_obj = 0
; Open a txt file and print everything into it
if keyword_set(print_all) and not keyword_set(no_fit) and not keyword_set(FWD) then begin
  	global_outname = '_lines_fixwidth'
  	if not keyword_set(cube) or (keyword_set(cube) and keyword_set(co_add)) then begin
        openw, gff, outdir+print_all+'_lines_fixwidth.txt',/get_lun
    		printf, gff, format='(19(a16,2x))',$
            	'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Blend','Validity'
    		free_lun, gff
    		close, gff

    		openw, gff, outdir+print_all+'_lines_fixwidth_global_noise.txt',/get_lun
    		printf, gff, format='(19(a16,2x))',$
    			'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Blend','Validity'
    		free_lun, gff
    		close, gff
  	endif
  	if keyword_set(cube) then begin
      	openw, gff, outdir+print_all+'_lines_fixwidth_global_noise.txt',/get_lun
      	printf, gff, format='(20(a16,2x))',$
      	     'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel_No.','Blend','Validity'
      	free_lun, gff
      	close, gff

        openw, gff, outdir+print_all+'_lines_fixwidth.txt',/get_lun
        printf, gff, format='(20(a16,2x))',$
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

if obj_flag[0] ne '0' then begin
  	if obj_flag[0] eq '1' then begin
    		; Set the source list that we want to report to the archive
    		cdf = ['ABAur','AS205','B1-a','B1-c','B335','BHR71','Ced110-IRS4','DGTau','EC82','Elias29','FUOri','GSS30-IRS1','HD100453','HD100546','HD104237','HD135344B','HD139614',$
    			   'HD141569','HD142527','HD142666','HD144432','HD144668','HD150193','HD163296','HD169142','HD179218','HD203024','HD245906','HD35187','HD36112','HD38120','HD50138',$
    			   'HD97048','HD98922','HH46','HH100','HTLup','IRAM04191','IRAS03245','IRAS03301','IRAS12496','IRAS15398','IRS46','IRS48','IRS63','L1014','L1157','L1448-MM','L1455-IRS3',$
    			   'L1489','L1527','L1551-IRS5','L483','L723-MM','RCrA-IRS5A','RCrA-IRS7B','RCrA-IRS7C','RNO90','RNO91','RULup','RYLup','SCra','SR21',$
    			   'Serpens-SMM3','Serpens-SMM4','TMC1','TMC1A','TMR1','V1057Cyg','V1331Cyg','V1515Cyg','V1735Cyg','VLA1623','WL12']
    		; WISH sources
    		; cdf = ['NGC1333-IRAS2A','NGC1333-IRAS4A','NGC1333-IRAS4B','Serpens-SMM1']
    		; Debugging purpose
    		; cdf = ['EC82','NGC1333-IRAS2A','Serpens-SMM1']
    		; cdf = ['L1489']
  	endif else begin
        cdf = obj_flag
  	endelse
endif
while i eq 1 do begin
	obj = where(objname eq objname[0])
	current_obj = strcompress(objname[0],/remove_all)
	filename = digit_file[obj]
	if array_equal(objname,objname[where(objname ne objname[0])]) then i = 0
	digit_file = digit_file[where(objname ne objname[0])]
	objname = objname[where(objname ne objname[0])]
	if keyword_set(FWD) then begin
		if file_test(outdir+'full_source_list.txt') eq 0 then begin
			openw, tot_list, outdir+'full_source_list.txt',/get_lun
			printf, tot_list, format='(4(a16,2x))', 'Object','PACS/SPIRE','Reduction','Noise'
			free_lun, tot_list
			close, tot_list
		endif

		exclude_jitter = ['IRAM04191','IRS46','L1014','L1455-IRS3','RCrA-IRS5A',$
						  'RCrA-IRS7C','Serpens-SMM4','HBC722_May2011','HBC722_Dec2010','EC82',$
						  'HD98922','HD245906','HD203024','HTLup','HD142666','HD35187']
		if keyword_set(obj_flag) then begin
			if (where(cdf eq current_obj))[0] eq -1 then continue
		endif
		if keyword_set(jitter) and (where(exclude_jitter eq current_obj))[0] ne -1 then continue

		; Even if the source is not what we want to process, we still copy the FITS files over.  Such as 3x3NO, nojitter
		; Copy the fits files into the archive directory
		if file_test(outdir+current_obj+'/pacs/data/fits/') eq 0 then file_mkdir, outdir+current_obj+'/pacs/data/fits'
		; Copy either 1-D Corrected3x3YES or finalcubes FITS file.
		file_copy, filename, outdir+current_obj+'/pacs/data/fits/',/overwrite
		; If 1-D, looking for centralSpaxel_PointSourceCorrected_Corrected3x3NO_slice... and
		; 					  central9Spaxels_PointSourceCorrected_slice
		if not keyword_set(cube) then begin
			for ifoo = 0, n_elements(filename)-1 do begin
				foo_front = (strsplit(filename[ifoo], 'centralSpaxel_PointSourceCorrected_Corrected3x3YES', /extract, /regex))[0]
				foo_back = (strsplit(filename[ifoo], 'centralSpaxel_PointSourceCorrected_Corrected3x3YES', /extract, /regex))[1]
				; Copy 3x3NO
				file_copy, foo_front + 'centralSpaxel_PointSourceCorrected_Corrected3x3NO' + foo_back, outdir+current_obj+'/pacs/data/fits/',/overwrite
				; Copy central9Spaxels
				file_copy, foo_front + 'central9Spaxels_PointSourceCorrected' + foo_back, outdir+current_obj+'/pacs/data/fits/',/overwrite
			endfor
		endif
		; If cube, looking for rebinnedcubenoda and rebinnedcubenodb
		if keyword_set(cube) then begin
			for ifoo = 0, n_elements(filename)-1 do begin
				foo_front = (strsplit(filename[ifoo], 'finalcubes', /extract, /regex))[0]
				foo_back = (strsplit(filename[ifoo], 'finalcubes', /extract, /regex))[1]
				; Copy rebinnedcubenoda
				file_copy, foo_front + 'rebinnedcubesnoda' + foo_back, outdir+current_obj+'/pacs/data/fits/',/overwrite
				; Copy rebinnedcubenodb
				file_copy, foo_front + 'rebinnedcubesnodb' + foo_back, outdir+current_obj+'/pacs/data/fits/',/overwrite
			endfor
		endif
		; print the source info
		openw, tot_list, outdir+'full_source_list.txt',/get_lun, /append
		if keyword_set(jitter) then reduction='jitter'
		if keyword_set(nojitter) then reduction='nojitter'
		if keyword_set(cube) and keyword_set(jitter) then reduction='cube-jitter'
		if keyword_set(cube) and keyword_set(nojitter) then reduction='cube-nojitter'
		; set the default noisetype.  If the fitting is executed, the noisetype will change accordingly.
		noisetype = 'None'

		; Skip the nojitter run if the jitter reduction are found
		if not keyword_set(cube) then begin
			if (file_test(outdir+current_obj+'/pacs/data/'+current_obj+'_centralSpaxel_PointSourceCorrected_CorrectedYES_trim.txt') ne 0) and keyword_set(nojitter) then begin
				printf, tot_list, format='(4(a16,2x))',current_obj, 'PACS', reduction,noisetype
				free_lun, tot_list
				close, tot_list
				continue
			endif
		endif else begin
			if (file_test(outdir+current_obj+'/pacs/data/cube/'+current_obj+'_pacs_pixel1_'+suffix+'.txt') ne 0) and keyword_set(nojitter) then begin
				printf, tot_list, format='(4(a16,2x))',current_obj, 'PACS', reduction,noisetype
				free_lun, tot_list
				close, tot_list
				continue
			endif
		endelse

	endif else begin
        ; prevent the end-of-code-write-out failed
        openw, tot_list, outdir+'full_source_list.txt',/get_lun, /append
    endelse

	if keyword_set(single) then if current_obj ne single then continue ; Uncomment this line for all objects fitting

	if file_test(outdir+current_obj+'/pacs/data',/directory) eq 0 then file_mkdir, outdir+current_obj+'/pacs/data'
	print, 'Fitting', current_obj, '...',format='(a7,x,a'+strtrim(string(strlen(current_obj)),1)+',a3)'

	; design for copying the FITS
	if (keyword_set(no_fit)) and (not keyword_set(contour)) then begin
		if keyword_set(jitter) then begin
			printf, tot_list, format='(4(a16,2x))',current_obj, 'PACS', reduction,noisetype
			free_lun, tot_list
			close, tot_list
		endif
		; continue
	endif
	; "filename" contains the all of the filepath of the object in each iteration
	; Extract the fits files of each object now.  Output a two-column spectrum in ascii file and a whole spectrum plot.
	;
	general = 0
	if (proj eq 'wish') and (current_obj ne 'NGC1333-IRAS4A') and (current_obj ne 'NGC1333-IRAS4B') then general = 1
	if keyword_set(central9) then get_pacs_1d,outdir=outdir+current_obj+'/pacs/data/',objname=current_obj, filename=filename,/central9,ra=ra,dec=dec,general=general,datadir=indir,coorddir=outdir+current_obj+'/pacs/data/cube/'
	if keyword_set(centralyes) then get_pacs_1d,outdir=outdir+current_obj+'/pacs/data/',objname=current_obj, filename=filename,/centralyes,ra=ra,dec=dec,general=general,datadir=indir,coorddir=outdir+current_obj+'/pacs/data/cube/'
	if keyword_set(centralno) then get_pacs_1d,outdir=outdir+current_obj+'/pacs/data/',objname=current_obj, filename=filename,/centralno,ra=ra,dec=dec,general=general,datadir=indir,coorddir=outdir+current_obj+'/pacs/data/cube/'
	if keyword_set(cube) then get_pacs, outdir=outdir+current_obj+'/pacs/data/',objname=current_obj, filename=filename, suffix=suffix,general=general;,datadir=indir
	; suffix='os8_sf7'

	; Set the name of the ascii file containing the spectrum
	;
	if keyword_set(central9) then name = '_central9Spaxels_PointSourceCorrected'
	if keyword_set(centralyes) then name = '_centralSpaxel_PointSourceCorrected_CorrectedYES'
	if keyword_set(centralno) then name = '_centralSpaxel_PointSourceCorrected_CorrectedNO'
	if keyword_set(cube) then name = suffix
	exception_obj = []
	; The exclusion list in jitter verion for running global noise re-evaluation
	if keyword_set(jitter) then exception_obj = ['HD50138','IRAM04191','IRS46','L1014','L1455-IRS3','RCrA-IRS5A','RCrA-IRS7C','Serpens-SMM4']
	if keyword_set(nojitter) then exception_obj = ['HD203024','RCrA-IRS5A','RCrA-IRS5A','RCrA-IRS7C','Serpens-SMM4']
	; force to use Local noise for all sources
	if keyword_set(localnoise) then exception_obj = ['ABAur','AS205','B1-a','B1-c','B335','BHR71','Ced110-IRS4','DGTau','EC82','Elias29','FUOri','GSS30-IRS1','HD100453','HD100546','HD104237','HD135344B','HD139614',$
		   'HD141569','HD142527','HD142666','HD144432','HD144668','HD150193','HD163296','HD169142','HD179218','HD203024','HD245906','HD35187','HD36112','HD38120','HD50138',$
		   'HD97048','HD98922','HH46','HH100','HTLup','IRAM04191','IRAS03245','IRAS03301','IRAS12496','IRAS15398','IRS46','IRS48','IRS63','L1014','L1157','L1448-MM','L1455-IRS3',$
		   'L1489','L1527','L1551-IRS5','L483','L723-MM','RCrA-IRS5A','RCrA-IRS7B','RCrA-IRS7C','RNO90','RNO91','RULup','RYLup','SCra','SR21',$
		   'Serpens-SMM3','Serpens-SMM4','TMC1','TMC1A','TMR1','V1057Cyg','V1331Cyg','V1515Cyg','V1735Cyg','VLA1623','WL12']


	; Fitting part
	; For 1D spectra
	if not keyword_set(cube) and not keyword_set(no_fit) then begin
		if (n_elements(filename) eq 4 and (where(exception_obj eq current_obj))[0] eq -1) then begin
		; if (where(exception_obj eq current_obj))[0] eq -1 then begin
			noisetype='Global'
			outname = '_lines_fixwidth_global_noise'
			extract_pacs, indir=outdir+current_obj+'/pacs/data/', filename=current_obj+name+'_trim', outdir=outdir+current_obj+'/pacs/advanced_products/', plotdir=outdir+current_obj+'/pacs/advanced_products/plots/', noiselevel=noiselevel,$
						  ra=ra,dec=dec,localbaseline=localbaseline,global_noise=global_noise,fixed_width=fixed_width,/opt_width,/continuum,/flat,object=current_obj,print_all=outdir+print_all+global_outname,$
						  no_plot=no_plot,double_gauss=double_gauss
		endif else begin
			noisetype='Local'
			outname = '_lines_fixwidth'
			extract_pacs, indir=outdir+current_obj+'/pacs/data/', filename=current_obj+name+'_trim', outdir=outdir+current_obj+'/pacs/advanced_products/', plotdir=outdir+current_obj+'/pacs/advanced_products/plots/', noiselevel=noiselevel,$
						  ra=ra,dec=dec,localbaseline=localbaseline,fixed_width=fixed_width,/opt_width,/continuum,/flat,object=current_obj,print_all=outdir+print_all+global_outname,$
						  no_plot=no_plot,double_gauss=double_gauss
		endelse
	endif
	; For cube
	;
	if keyword_set(cube) and not keyword_set(co_add) and not keyword_set(no_fit) then begin
		;readcol, outdir+current_obj+'/cube/'+current_obj+'_pacs_coord.txt', format='D,D,D', pix_ind, ra, dec,/silent
		if (n_elements(filename) eq 4 and (where(exception_obj eq current_obj))[0] eq -1) then begin
			noisetype='Global'
			outname = '_lines_fixwidth_global_noise'
			if not keyword_set(no_fit) then begin
				; Print the fitting results of 25 spaxels into a single text file for each object
				if file_test(outdir+current_obj+'/pacs/advanced_products/cube/') eq 0 then file_mkdir, outdir+current_obj+'/pacs/advanced_products/cube/'
				;openw, gff, outdir+current_obj+'/cube/data/'+current_obj+outname+'.txt',/get_lun
				;printf, gff, format='(19(a16,2x))',$
				;	'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel No.','Blend','Validity'
				;free_lun, gff
				;close, gff
				for pix=1,25 do begin
					;print, current_obj,'pixel',strtrim(string(pix),1),format='(8x,a'+strtrim(string(strlen(current_obj)),1)+',1x,a6,1x,a2)'
					extract_pacs, indir=outdir+current_obj+'/pacs/data/cube/', filename=current_obj+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix, outdir=outdir+current_obj+'/pacs/advanced_products/cube/', plotdir=outdir+current_obj+'/pacs/advanced_products/cube/plots/',$
										      noiselevel=noiselevel,localbaseline=localbaseline,global_noise=global_noise,fixed_width=fixed_width,/opt_width,/continuum,/flat,object=current_obj,$
										      print_all=outdir+print_all+global_outname,current_pix=strtrim(string(pix),1),no_plot=no_plot,double_gauss=double_gauss;ra=ra[pix-1],dec=dec[pix-1],
				endfor
			endif
		endif else begin
			noisetype='Local'
			outname = '_lines_fixwidth'
			if not keyword_set(no_fit) then begin
				; Print the fitting results of 25 spaxels into a single text file for each object
				if file_test(outdir+current_obj+'/pacs/data/cube/') eq 0 then file_mkdir, outdir+current_obj+'/pacs/data/cube/'
				;openw, gff, outdir+current_obj+'/cube/data/'+current_obj+outname+'.txt',/get_lun
				;printf, gff, format='(19(a16,2x))',$
        		;	'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel No.','Blend','Validity'
				;free_lun, gff
				;close, gff
				for pix=1,25 do begin
					;print, current_obj,'pixel',strtrim(string(pix),1),format='(8x,a'+strtrim(string(strlen(current_obj)),1)+',1x,a6,1x,a2)'
					extract_pacs, indir=outdir+current_obj+'/pacs/data/cube/', filename=current_obj+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix, outdir=outdir+current_obj+'/pacs/advanced_products/cube/', plotdir=outdir+current_obj+'/pacs/advanced_products/cube/plots/',$
										      noiselevel=noiselevel,localbaseline=localbaseline,fixed_width=fixed_width,/opt_width,/continuum,/flat,object=current_obj,$
										      print_all=outdir+print_all+global_outname,current_pix=strtrim(string(pix),1),no_plot=no_plot,double_gauss=double_gauss;,ra=ra[pix-1],dec=dec[pix-1]
				endfor
			endif
		endelse
	endif
	; For cube, but co-add the 5x5 spaxels into 1d spectrum at first
	;
	if keyword_set(cube) and keyword_set(co_add) and not keyword_set(no_fit) then begin
		readcol, outdir+current_obj+'/pacs/data/cube/'+current_obj+'pixel_13_'+suffix+'_coord.txt', format='D,D,D', pix_ind, ra, dec,/silent
		ra = mean(ra) & dec = mean(dec)
		summed_five, indir=outdir+current_obj+'/pacs/data/cube/', outdir=outdir+current_obj+'/pacs/data/cube/', object=current_obj, suffix=suffix, plot=outdir+current_obj+'/pacs/data/cube/'
		if (n_elements(filename) eq 4 and (where(exception_obj eq current_obj))[0] eq -1) then begin
			noisetype='Global'
			extract_pacs, indir=outdir+current_obj+'/pacs/data/cube/', filename=current_obj+'_pacs_summed_5x5_'+suffix, outdir=outdir+current_obj+'/pacs/advanced_products/cube/', plotdir=outdir+current_obj+'/pacs/advanced_products/cube/plots/', noiselevel=noiselevel,$
						  ra=ra,dec=dec,localbaseline=localbaseline,global_noise=global_noise,fixed_width=fixed_width,/opt_width,/continuum,/flat,object=current_obj,print_all=outdir+print_all+global_outname,no_plot=no_plot,double_gauss=double_gauss
			outname = '_lines_fixwidth_global_noise'
		endif else begin
			noisetype='Local'
			extract_pacs, indir=outdir+current_obj+'/pacs/data/cube/', filename=current_obj+'_pacs_summed_5x5_'+suffix, outdir=outdir+current_obj+'/pacs/advanced_products/cube/', plotdir=outdir+current_obj+'/pacs/advanced_products/cube/plots/', noiselevel=noiselevel,$
						  ra=ra,dec=dec,localbaseline=localbaseline,fixed_width=fixed_width,/opt_width,/continuum,/flat,object=current_obj,print_all=outdir+print_all+global_outname,no_plot=no_plot,double_gauss=double_gauss
			outname = '_lines_fixwidth'
		endelse
	endif
	; Write the information of different species into different files
	;

	if keyword_set(refine) and not keyword_set(cube) then begin
;		refine_list = file_search(outdir+current_obj+'/pacs/advanced_products/species_separated/', current_obj+name+'_trim*')
;		if n_elements(refine_list) eq 1 then begin
;			if strlen(refine_list) gt 0 then file_delete,refine_list,/allow_nonexistent,/recursive
;		endif
		;print,'-----> Clean up (species_separated) folder for updating the results.'
		refine_fitting, indir=outdir+current_obj+'/pacs/advanced_products/',filename=current_obj+name+'_trim_lines',outdir=outdir+current_obj+'/pacs/advanced_products/species_separated/',/all,/pacs
	endif

	if keyword_set(refine) and keyword_set(cube) and keyword_set(co_add) then begin
;		refine_list = file_search(outdir+current_obj+'/pacs/advanced_products/cube/species_separated/', current_obj+'_pacs_summed_5x5_'+suffix+'*')
;		if n_elements(refine_list) eq 1 then begin
;			if strlen(refine_list) gt 0 then file_delete,refine_list,/allow_nonexistent,/recursive
;		endif
		;print,'-----> Clean up (species_separated) folder for updating the results.'
		refine_fitting, indir=outdir+current_obj+'/pacs/advanced_products/cube/',filename=current_obj+'_pacs_summed_5x5_'+suffix+outname,outdir=outdir+current_obj+'/pacs/advanced_products/cube/species_separated/',/all,/pacs
	endif

	if keyword_set(refine) and keyword_set(cube) and not keyword_set(co_add) then begin
		for pix = 1, 25 do begin
;			refine_list = file_search(outdir+current_obj+'/pacs/advanced_products/cube/species_separated/', current_obj+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'*')
;			if n_elements(refine_list) eq 1 then begin
;				if strlen(refine_list) gt 0 then file_delete,refine_list,/allow_nonexistent,/recursive
;			endif
			;print,'----> Clean up (species_separated) folder for updating the results.'
			refine_fitting, indir=outdir+current_obj+'/pacs/advanced_products/cube/',filename=current_obj+'_pacs_pixel'+strtrim(string(pix),1)+'_'+suffix+'_lines',outdir=outdir+current_obj+'/pacs/advanced_products/cube/species_separated/',/all,/cube,/pacs
		endfor
	endif
	if keyword_set(contour) then begin
		skip = [];'HBC722_379','HBC722_173','AS205'
		if (where(skip eq strcompress(current_obj,/remove_all)))[0] ne -1 then continue
		print, 'Plotting the contour plots...'
		; if keyword_set(jitter) then plot_contour, noise=3, indir=outdir+current_obj+'/pacs/advanced_products/cube/',plotdir=outdir+'contour/'+current_obj+'/',objname=current_obj,/pacs,/brightness
		; for plot the position of IRS2 in BHR71
		if keyword_set(jitter) then plot_contour, noise=3, indir=outdir+current_obj+'/pacs/advanced_products/cube/',plotdir=outdir+'contour/'+current_obj+'/',objname=current_obj,/pacs,/brightness, plot_irs2=[180.392041667, -65.1464888889]
		if keyword_set(nojitter) then plot_contour, noise=3, indir=outdir+current_obj+'/pacs/advanced_products/cube/',plotdir=outdir+'contour/'+current_obj+'/',objname=current_obj,/pacs,/brightness
	endif

	if not keyword_set(no_fit) then begin
		printf, tot_list, format='(4(a16,2x))',current_obj, 'PACS', reduction,noisetype
		free_lun, tot_list
		close, tot_list
	endif else begin
		free_lun, tot_list
		close, tot_list
	endelse
	num_obj = num_obj+1
endwhile
print, 'Finish fitting', strtrim(string(num_obj),1),'objects (PACS)',format='(a14,x,a3,x,a7)'

if not keyword_set(FWD) then toc
end
