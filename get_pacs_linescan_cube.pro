pro get_pacs_linescan_cube,indir=indir,outdir=outdir,plotdir=plotdir,aor_name=aor_name,slice=slice

band=['blue','blue','red','red']
for iband = 0, n_elements(band)-1 do begin
	for i_slice = 0, slice[iband] do begin
		filename = aor_name[iband]+'v13os4_'+band[iband]+'norm_sl'+strtrim(string(i_slice),1)
		print, filename
	    flux = readfits(indir+filename+'.fits', exten=1)
	    ra = readfits(indir+filename+'.fits', exten=2)
	    dec = readfits(indir+filename+'.fits', exten=3)
	    flux_stddev = readfits(indir+filename+'.fits', exten=5)
	    wl = readfits(indir+filename+'.fits', exten=8)
	    hdr = headfits(indir+filename+'.fits')
	    ;band = sxpar(hdr, 'BAND') & obj = sxpar(hdr, 'OBJECT')
		ind = 0
		;Print out the spetrum of each pixel into individual file
		pix = 1
		for i = 0, 4 do begin
			for j = 0, 4 do begin
				openw, lun, outdir+'linescan_'+filename+'_pixel'+strtrim(string(pix),1)+'.txt', /get_lun
				for line = 0, n_elements(wl)-1 do begin
					if Finite(flux[i,j,line]) ne 0 then printf, lun, format='(3(g16.8,2x))', wl[line], flux[i,j,line], flux_stddev[i,j,line]
				endfor
				pix = pix + 1
				free_lun, lun
				close, lun
			endfor
		endfor
		print, filename
	endfor
endfor
;summed_five
;extract_pacs,indir=outdir,filename='linescan_'+filename,outdir=outdir,plotdir=plotdir,$
;     noiselevel=3,/test,ra=70.302251,dec=25.776591,localbaseline=10,/linescan,/fixed_width

end

