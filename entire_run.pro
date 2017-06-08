pro entire_run, indir=indir,outdir=outdir,outname=outname,slim=slim,clean=clean,contour_only=contour_only,obj_flag=obj_flag, $
				spire_test=spire_test, pacs_test=pacs_test, test=test, localnoise=localnoise
;entire_run,/contour_only,outdir='~/data/FWD_bettyjo/FWD_archive'
tic
; Keyword and directory setting
for i = 1, 128 do free_lun, i

if not keyword_set(indir) then begin
	digit_dir = '~/data/digit_v65/'
	digit_dir_nojitter = '~/data/digit_v65_nojitter/'
	foosh_dir = '~/data/foosh_v65/'
	cops_dir = '~/data/hipe12spire/'
endif else begin
	digit_dir = indir
	digit_dir_nojitter = indir
	foosh_dir = indir
	cops_dir = indir
endelse

if not keyword_set(outdir) then outdir = '~/data/FWD_archive'

if keyword_set(test) then outdir = outdir+'_test'

if keyword_set(slim) then begin
	no_plot = 1
	outdir = outdir+'_slim/'
endif else begin
	no_plot = 0
	outdir = outdir+'/'
endelse

if file_test(outdir) eq 0 then file_mkdir, outdir

if not keyword_set(outname) then outname = 'CDF_archive'

if not keyword_set(obj_flag) then obj_flag = 0

if not keyword_set(localnoise) then localnoise = 0

; Option for updating the contours plot only
if keyword_set(contour_only) then begin
	proj = 'digit'
	run_digit,indir=digit_dir,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/no_fit,/FWD,obj_flag=obj_flag
	run_digit,indir=digit_dir_nojitter,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/nojitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/no_fit,/FWD,obj_flag=obj_flag

	proj='foosh'
	run_digit,indir=digit_dir,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/no_fit,/FWD,obj_flag=obj_flag
;	run_digit,indir=digit_dir_nojitter,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/nojitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/no_fit,/FWD

	proj='wish'
	run_digit,indir=digit_dir,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/no_fit,/FWD,obj_flag=obj_flag
	run_digit,indir=digit_dir_nojitter,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/nojitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/no_fit,/FWD,obj_flag=obj_flag

	run_cops,indir=cops_dir,outdir=outdir,localbaseline=10,global_noise=20,noiselevel=3,/cube,/cops,no_plot=no_plot,print_all=outname+'_spire_cube',/double_gauss,/contour,/no_fit,/FWD,obj_flag=obj_flag
	goto, bottom
endif

; Option for dedugging and testing the pacs or spire individually
if keyword_set(pacs_test) then begin
	; run DIGIT 1-D + cube jittered
	proj = 'digit'
	run_digit,indir=digit_dir,outdir=outdir,/centralyes,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_1d',no_plot=no_plot,proj=proj,/double_gauss,/FWD,obj_flag=obj_flag
	; run_digit,indir=digit_dir,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/FWD,obj_flag=obj_flag
	goto, bottom
endif
if keyword_set(spire_test) then begin
	; run COPS 1-D + cube
	run_cops,indir=cops_dir,outdir=outdir,localbaseline=10,global_noise=20,noiselevel=3,/corrected,/cops,no_plot=no_plot,print_all=outname+'_spire_1d',/double_gauss,/FWD,obj_flag=obj_flag
	run_cops,indir=cops_dir,outdir=outdir,localbaseline=10,global_noise=20,noiselevel=3,/cube,/cops,no_plot=no_plot,print_all=outname+'_spire_cube',/double_gauss,/contour,/FWD,obj_flag=obj_flag
	goto, bottom
endif

if keyword_set(clean) then begin
	list = file_search(outdir, '*')
	if (n_elements(list) gt 0) and strlen(list[0]) gt 0 then file_delete,list,/allow_nonexistent,/recursive
endif

; Output of the grand text file

; 1D spectra
openw, gff, outdir+outname+'_pacs_1d_lines.txt',/get_lun
printf, gff, format='(19(a18,2x))',$
	'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Blend','Validity'
free_lun, gff
close, gff

openw, gff, outdir+outname+'_spire_1d_lines.txt',/get_lun
printf, gff, format='(19(a18,2x))',$
	'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Blend','Validity'
free_lun, gff
close, gff

; cube
openw, gff, outdir+outname+'_pacs_cube_lines.txt',/get_lun
printf, gff, format='(20(a18,2x))',$
     'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel_No.','Blend','Validity'
free_lun, gff
close, gff

openw, gff, outdir+outname+'_spire_cube_lines.txt',/get_lun
printf, gff, format='(20(a18,2x))',$
     'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2/as2)','Sig_str(W/cm2/as2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um/as2)','Noise(W/cm2/um/as2)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel_No.','Blend','Validity'
free_lun, gff
close, gff

; everything in one ASCII file
openw, all, outdir+outname+'_lines.txt',/get_lun
printf, all, format='(20(a18,2x))',$
     'Object','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2/as2)','Sig_str(W/cm2/as2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um/as2)','Noise(W/cm2/um/as2)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel_No.','Blend','Validity'
free_lun, all
close, all

; Run through every project and reduction

;DIGIT
;
proj = 'digit'

run_digit,indir=digit_dir,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/FWD,obj_flag=obj_flag,localnoise=localnoise
run_digit,indir=digit_dir_nojitter,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/nojitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/FWD,obj_flag=obj_flag,localnoise=localnoise

run_digit,indir=digit_dir,outdir=outdir,/centralyes,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_1d',no_plot=no_plot,proj=proj,/double_gauss,/FWD,obj_flag=obj_flag,localnoise=localnoise
run_digit,indir=digit_dir_nojitter,outdir=outdir,/centralyes,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/nojitter,/refine,print_all=outname+'_pacs_1d',no_plot=no_plot,proj=proj,/double_gauss,/FWD,obj_flag=obj_flag,localnoise=localnoise


;FOOSH
proj = 'foosh'

run_digit,indir=foosh_dir,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/FWD,obj_flag=obj_flag,localnoise=localnoise
run_digit,indir=foosh_dir,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/nojitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/FWD,obj_flag=obj_flag,localnoise=localnoise

run_digit,indir=foosh_dir,outdir=outdir,/centralyes,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_1d',no_plot=no_plot,proj=proj,/double_gauss,/FWD,obj_flag=obj_flag,localnoise=localnoise
run_digit,indir=foosh_dir,outdir=outdir,/centralyes,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/nojitter,/refine,print_all=outname+'_pacs_1d',no_plot=no_plot,proj=proj,/double_gauss,/FWD,obj_flag=obj_flag,localnoise=localnoise


;WISH
proj='wish'

run_digit,indir=digit_dir,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/FWD,obj_flag=obj_flag,localnoise=localnoise
run_digit,indir=digit_dir_nojitter,outdir=outdir,/cube,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/nojitter,/refine,print_all=outname+'_pacs_cube',no_plot=no_plot,proj=proj,/double_gauss,/contour,/FWD,obj_flag=obj_flag,localnoise=localnoise

run_digit,indir=digit_dir,outdir=outdir,/centralyes,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/jitter,/refine,print_all=outname+'_pacs_1d',no_plot=no_plot,proj=proj,/double_gauss,/FWD,obj_flag=obj_flag,localnoise=localnoise
run_digit,indir=digit_dir_nojitter,outdir=outdir,/centralyes,/fixed_width,localbaseline=10,noiselevel=3,global_noise=20,/nojitter,/refine,print_all=outname+'_pacs_1d',no_plot=no_plot,proj=proj,/double_gauss,/FWD,obj_flag=obj_flag,localnoise=localnoise


;COPS
run_cops,indir=cops_dir,outdir=outdir,localbaseline=10,global_noise=20,noiselevel=3,/corrected,/cops,no_plot=no_plot,print_all=outname+'_spire_1d',/refine,/double_gauss,/FWD,obj_flag=obj_flag,localnoise=localnoise
run_cops,indir=cops_dir,outdir=outdir,localbaseline=10,global_noise=20,noiselevel=3,/cube,/cops,no_plot=no_plot,print_all=outname+'_spire_cube',/refine,/double_gauss,/contour,/FWD,obj_flag=obj_flag,localnoise=localnoise


;stop
;SPIRE for only text file format
; B335, RcrA-IRS7B, BHR71, HD142527, HD97048
obj = ['B335','RCrA-IRS7B','BHR71']; ,'HD142527','HD97048']
ra = [294.2700500,285.4640808,180.40109,-65.147993,239.1745453,67.89822744]
dec = [7.548758507,-36.93764496,-65.147993,-42.32313156,-77.6548556,18.12826098]
; for i = 0, n_elements(obj)-1 do begin
  ; only do BHR71, the rest of coordinates seems bogus

for i = 2, 2 do begin
	if obj_flag[0] ne '0' then begin
		if where(obj_flag eq obj[i]) eq -1 then continue
	endif
	if file_test(outdir+'full_source_list.txt') eq 0 then begin
		openw, tot_list, outdir+'full_source_list.txt',/get_lun
		printf, tot_list, format='(4(a16,2x))', 'Object','PACS/SPIRE','Reduction','Noise'
		free_lun, tot_list
		close, tot_list
	endif

	openw, tot_list, outdir+'full_source_list.txt',/get_lun, /append
	printf, tot_list, format='(4(a16,2x))', obj[i],'SPIRE','Standard','Global'
	free_lun, tot_list
	close, tot_list

	if file_test(outdir+obj[i]+'/spire/data/',/directory) eq 0 then file_mkdir, outdir+obj[i]+'/spire/data/'
	file_copy, cops_dir+obj[i]+'_spire_corrected.txt', outdir+obj[i]+'/spire/data/',/overwrite

	readcol, cops_dir+obj[i]+'_spire_corrected.txt', format='D,D', wl, flux,/silent

	set_plot, 'ps'
	!p.font=0
	loadct,13,/silent
	!p.thick=3 & !x.thick=3 & !y.thick=3
    device, filename = outdir+obj[i]+'/spire/data/'+obj[i]+'_spire_corrected.eps', /helvetica, /portrait, /encapsulated, font_size = 8, isolatin = 1, decomposed = 0, /color
    plot, wl, flux, xtitle = 'Wavelength (!9m!3m)', ytitle = 'Flux (Jy)' ,/nodata
    oplot, wl[where(wl gt 195 and wl le 310)], flux[where(wl gt 195 and wl le 310)], color=250, thick=2
    oplot, wl[where(wl gt 310)], flux[where(wl gt 310)], color=60, thick=2
	al_legend, [obj[i]],textcolor=[0],/left
	al_legend, ['SPIRE-SSW','SPIRE-SLW'],textcolors=[60,250],/right
	device, /close_file,decomposed=1
	!p.multi = 0
	if not keyword_set(local) then begin
		extract_spire,indir=cops_dir,filename=obj[i]+'_spire_corrected',outdir=outdir+obj[i]+'/spire/advanced_products/',plotdir=outdir+obj[i]+'/spire/advanced_products/plots/',localbaseline=10,global_noise=20,$
		ra=ra[i],dec=dec[i],noiselevel=3,/fx,object=obj[i],print_all=outdir+outname+'_spire_1d_lines',/flat,/continuum,/double_gauss,no_plot=no_plot
	endif else begin
		extract_spire,indir=cops_dir,filename=obj[i]+'_spire_corrected',outdir=outdir+obj[i]+'/spire/advanced_products/',plotdir=outdir+obj[i]+'/spire/advanced_products/plots/',localbaseline=10,$
		ra=ra[i],dec=dec[i],noiselevel=3,/fx,object=obj[i],print_all=outdir+outname+'_spire_1d_lines',/flat,/continuum,/double_gauss,no_plot=no_plot
	endelse
endfor

; Refine the source list
;
readcol, outdir+'full_source_list.txt',format='A,A,A,A',obj,inst,ver,noise,skipline=1,/silent
inst = inst[sort(obj)]
ver = ver[sort(obj)]
noise = noise[sort(obj)]
obj = obj[sort(obj)]

printobj = []
pacs = []
jitter = []
nojitter = []
cubejitter = []
cubenojitter = []
spire = []
spire1d = []
spirecube = []

i = 1

while i eq 1 do begin
	obj_dum = obj[0]
	ind_dum = where(obj eq obj_dum)
	num = n_elements(ind_dum)

	printobj = [printobj,obj_dum]

	if (where(inst[ind_dum] eq 'PACS'))[0] ne -1 then begin
		pacs = [pacs,'x']
	endif else begin
		pacs = [pacs,'']
	endelse

	if (where(ver[ind_dum] eq 'jitter'))[0] ne -1 then begin
		jitter = [jitter,'x']
	endif else begin
		jitter = [jitter,'']
	endelse

	if (where(ver[ind_dum] eq 'nojitter'))[0] ne -1 then begin
		nojitter = [nojitter,'x']
	endif else begin
		nojitter = [nojitter,'']
	endelse

	if (where(ver[ind_dum] eq 'cube-jitter'))[0] ne -1 then begin
		cubejitter = [cubejitter,'x']
	endif else begin
		cubejitter = [cubejitter,'']
	endelse

	if (where(ver[ind_dum] eq 'cube-nojitter'))[0] ne -1 then begin
		cubenojitter = [cubenojitter,'x']
	endif else begin
		cubenojitter = [cubenojitter,'']
	endelse

	if (where(inst[ind_dum] eq 'SPIRE'))[0] ne -1 then begin
		spire = [spire,'x']
	endif else begin
		spire = [spire,'']
	endelse

	if (where(ver[ind_dum] eq 'Standard'))[0] ne -1 then begin
		spire1d = [spire1d,'x']
	endif else begin
		spire1d = [spire1d,'']
	endelse

	if (where(ver[ind_dum] eq 'spirecube'))[0] ne -1 then begin
		spirecube = [spirecube,'x']
	endif else begin
		spirecube = [spirecube,'']
	endelse

	if array_equal(obj,obj[where(obj ne obj[0])]) then i = 0
	inst = inst[where(obj ne obj[0])]
	ver = ver[where(obj ne obj[0])]
	obj = obj[where(obj ne obj[0])]
endwhile

openw, tot_list, outdir+'full_source_list_refine.txt',/get_lun
printf, tot_list, format='((a16,2x),8(a10,2x))','Object','PACS','1Djitter','1Dnojitter','c-jitter','c-nojitter','SPIRE','SPIRE-1D','SPIRE-cube'
for i = 0, n_elements(printobj)-1 do printf, tot_list, format='((a16,2x),8(a10,2x))',printobj[i],pacs[i],jitter[i],nojitter[i],cubejitter[i],cubenojitter[i],spire[i],spire1d[i],spirecube[i]
free_lun, tot_list
close, tot_list
toc
bottom: toc
end
