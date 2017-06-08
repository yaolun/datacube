indir = '/Users/yaolun/research/mapping_code/VIRUS-P/spectra/'
filename = 'CuFcalFeSpesvp_F13_R_0212'
expo_id = 0
prefix = filename
outdir = '/Users/yaolun/research/mapping_code/spectra/fitting/'
objname = 'M82'
radec = '/Users/yaolun/research/mapping_code/VIRUS-P/'+filename+'_coord.txt'
r_spectral = 1000.0

readcol, radec, format='A,D,D', pix_num, ra, dec, skipline=1, /silent

for pix = 1, max(pix_num) do begin
    ra_dum = ra[where(pix_num eq pix)]
    dec_dum = dec[where(pix_num eq pix)]
    filename = indir+prefix+'_pixel'+strtrim(pix,2)+'.txt'
    extract_line, indir=indir, filename=filename, outdir=outdir, plotdir=outdir, noiselevel=3, ra=ra_dum, dec=dec_dum,$
      localbaseline=10, global_noise=0, fixed_width=0, continuum=1, object=objname, flat=1,$
      plot_subtraction=0, no_plot=0, double_gauss=0, r_spectral=r_spectral
endfor

; plot_contour_irs, noiselevel=3, indir=outdir, plotdir=outdir, objname=objname, verbose=1, fx=1, spitzerirs=1, max_irs_pixel=pix_counter

end
