; LH
;
;indir = '/Users/yaolun/data/hh168_texes/ggd37-yaolun/5005568/'
;filename = 'aor_5005568_expid_126_0_file1_pixel1_TSA'
;expo_id = 126
;prefix = 'aor_5005568_expid_'
;outdir = '~/test/ggd37_fitting/LH/'
;objname = 'ggd37'
;radec=  indir+'ra_dec_5005568_LH.txt'
;max_file_num = 30
;r_spectral = 600.0
;
;readcol, radec, format='I,I,I,I,D,D', comment=';', Module, EXPID, File_num_coord, Pixel_num_coord, RA_PIX, DEC_PIX, /silent
;
;pix_counter = 0
;
;for file_num = 1, max_file_num do begin
;  for pix_num = 1, 5 do begin
;    ra_dum = ra_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
;    dec_Dum = dec_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
;    filename = prefix+strtrim(expo_id-1+file_num,2)+'_0_file'+strtrim(file_num,2)+'_pixel'+strtrim(pix_num,2)+'_TSA'
;    extract_line, indir=indir, filename=filename, outdir=outdir, plotdir=outdir, noiselevel=3, ra=ra_dum, dec=dec_dum,$
;      localbaseline=10, global_noise=0, fixed_width=0, continuum=1, object='GGD37', flat=1,$
;      plot_subtraction=0, no_plot=0, double_gauss=0, r_spectral=r_spectral
;     pix_counter = pix_counter + 1
;    file_move, outdir+filename+'_lines.txt', outdir+objname+'_irs_pixel'+strtrim(pix_counter,2)+'_lines.txt', /overwrite
;  endfor
;endfor
;
;indir = '/Users/yaolun/data/hh168_texes/ggd37-yaolun/5005312/'
;filename = 'aor_5005312_expid_126_0_file1_pixel1_TSA'
;expo_id = 126
;prefix = 'aor_5005312_expid_'
;outdir = '~/test/ggd37_fitting/LH/'
;objname = 'ggd37'
;radec=  indir+'ra_dec_5005312_LH.txt'
;max_file_num = 30
;r_spectral = 600.0
;
;readcol, radec, format='I,I,I,I,D,D', comment=';', Module, EXPID, File_num_coord, Pixel_num_coord, RA_PIX, DEC_PIX, /silent
;
;for file_num = 1, max_file_num do begin
;  for pix_num = 1, 5 do begin
;    ra_dum = ra_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
;    dec_Dum = dec_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
;    filename = prefix+strtrim(expo_id-1+file_num,2)+'_0_file'+strtrim(file_num,2)+'_pixel'+strtrim(pix_num,2)+'_TSA'
;    extract_line, indir=indir, filename=filename, outdir=outdir, plotdir=outdir, noiselevel=3, ra=ra_dum, dec=dec_dum,$
;      localbaseline=10, global_noise=0, fixed_width=0, continuum=1, object='GGD37', flat=1,$
;      plot_subtraction=0, no_plot=0, double_gauss=0, r_spectral=r_spectral
;    pix_counter = pix_counter + 1
;    file_move, outdir+filename+'_lines.txt', outdir+objname+'_irs_pixel'+strtrim(pix_counter,2)+'_lines.txt', /overwrite
;  endfor
;endfor
;
;plot_contour_irs, noiselevel=3, indir=outdir, plotdir=outdir, objname=objname, verbose=1, fx=1,spitzerirs=1, max_irs_pixel=pix_counter
;
;; SH
;
;indir = '/Users/yaolun/data/hh168_texes/ggd37-yaolun/5005568/'
;filename = 'aor_5005568_expid_0_0_file1_pixel1_TSA'
;expo_id = 0
;prefix = 'aor_5005568_expid_'
;outdir = '~/test/ggd37_fitting/SH/'
;objname = 'ggd37'
;radec=  indir+'ra_dec_5005568_SH.txt'
;max_file_num = 126
;r_spectral = 600.0
;
;readcol, radec, format='I,I,I,I,D,D', comment=';', Module, EXPID, File_num_coord, Pixel_num_coord, RA_PIX, DEC_PIX, /silent
;
;pix_counter = 0
;
;for file_num = 1, max_file_num do begin
;  for pix_num = 1, 5 do begin
;    ra_dum = ra_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
;    dec_Dum = dec_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
;    filename = prefix+strtrim(expo_id-1+file_num,2)+'_0_file'+strtrim(file_num,2)+'_pixel'+strtrim(pix_num,2)+'_TSA'
;    extract_line, indir=indir, filename=filename, outdir=outdir, plotdir=outdir, noiselevel=3, ra=ra_dum, dec=dec_dum,$
;      localbaseline=10, global_noise=0, fixed_width=0, continuum=1, object='GGD37', flat=1,$
;      plot_subtraction=0, no_plot=0, double_gauss=0, r_spectral=r_spectral
;    pix_counter = pix_counter + 1
;    file_move, outdir+filename+'_lines.txt', outdir+objname+'_irs_pixel'+strtrim(pix_counter,2)+'_lines.txt', /overwrite
;  endfor
;endfor
;
;indir = '/Users/yaolun/data/hh168_texes/ggd37-yaolun/5005312/'
;filename = 'aor_5005312_expid_0_0_file1_pixel1_TSA'
;expo_id = 0
;prefix = 'aor_5005312_expid_'
;outdir = '~/test/ggd37_fitting/SH/'
;objname = 'ggd37'
;radec=  indir+'ra_dec_5005312_SH.txt'
;max_file_num = 126
;r_spectral = 600.0
;
;readcol, radec, format='I,I,I,I,D,D', comment=';', Module, EXPID, File_num_coord, Pixel_num_coord, RA_PIX, DEC_PIX, /silent
;
;for file_num = 1, max_file_num do begin
;  for pix_num = 1, 5 do begin
;    ra_dum = ra_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
;    dec_Dum = dec_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
;    filename = prefix+strtrim(expo_id-1+file_num,2)+'_0_file'+strtrim(file_num,2)+'_pixel'+strtrim(pix_num,2)+'_TSA'
;    extract_line, indir=indir, filename=filename, outdir=outdir, plotdir=outdir, noiselevel=3, ra=ra_dum, dec=dec_dum,$
;      localbaseline=10, global_noise=0, fixed_width=0, continuum=1, object='GGD37', flat=1,$
;      plot_subtraction=0, no_plot=0, double_gauss=0, r_spectral=r_spectral
;    pix_counter = pix_counter + 1
;    file_move, outdir+filename+'_lines.txt', outdir+objname+'_irs_pixel'+strtrim(pix_counter,2)+'_lines.txt', /overwrite
;  endfor
;endfor
;
;plot_contour_irs, noiselevel=3, indir=outdir, plotdir=outdir, objname=objname, verbose=1, fx=1,spitzerirs=1, max_irs_pixel=pix_counter


; SL

indir = '/Users/yaolun/data/hh168_texes/ggd37-yaolun/17856768/'
filename = 'aor_17856768_expid_0_0_file1_pixel1_TSA'
expo_id = 0
prefix = 'aor_17856768_expid_'
outdir = '~/test/ggd37_fitting/SL/'
objname = 'ggd37'
radec=  indir+'ra_dec_17856768_SL_trim.txt'
max_file_num = 124
r_spectral = 60.0

readcol, radec, format='I,I,I,I,D,D', comment=';', Module, EXPID, File_num_coord, Pixel_num_coord, RA_PIX, DEC_PIX, /silent

pix_counter = 0

for file_num = 1, max_file_num do begin
  for pix_num = 2, 27 do begin
    ra_dum = ra_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
    dec_Dum = dec_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
    filename = prefix+strtrim(expo_id+floor((file_num-1)/2),2)+'_0_file'+strtrim(file_num,2)+'_pixel'+strtrim(pix_num,2)+'_TSA'
    extract_line, indir=indir, filename=filename, outdir=outdir, plotdir=outdir, noiselevel=3, ra=ra_dum, dec=dec_dum,$
      localbaseline=10, global_noise=0, fixed_width=0, continuum=1, object='GGD37', flat=1,$
      plot_subtraction=0, no_plot=0, double_gauss=0, r_spectral=r_spectral
    pix_counter = pix_counter + 1
    file_move, outdir+filename+'_lines.txt', outdir+objname+'_irs_pixel'+strtrim(pix_counter,2)+'_lines.txt', /overwrite
  endfor
endfor

indir = '/Users/yaolun/data/hh168_texes/ggd37-yaolun/17857536/'
filename = 'aor_17857536_expid_0_0_file1_pixel1_TSA'
expo_id = 0
prefix = 'aor_17857536_expid_'
outdir = '~/test/ggd37_fitting/SL/'
objname = 'ggd37'
radec=  indir+'ra_dec_17857536_SL_trim.txt'
max_file_num = 124
r_spectral = 60.0

readcol, radec, format='I,I,I,I,D,D', comment=';', Module, EXPID, File_num_coord, Pixel_num_coord, RA_PIX, DEC_PIX, /silent

for file_num = 1, max_file_num do begin
  for pix_num = 2, 27 do begin
    ra_dum = ra_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
    dec_dum = dec_pix[where((file_num_coord eq file_num) and (pixel_num_coord eq pix_num))]
    filename = prefix+strtrim(expo_id+floor((file_num-1)/2),2)+'_0_file'+strtrim(file_num,2)+'_pixel'+strtrim(pix_num,2)+'_TSA'
    extract_line, indir=indir, filename=filename, outdir=outdir, plotdir=outdir, noiselevel=3, ra=ra_dum, dec=dec_dum,$
      localbaseline=10, global_noise=0, fixed_width=0, continuum=1, object='GGD37', flat=1,$
      plot_subtraction=0, no_plot=0, double_gauss=0, r_spectral=r_spectral
    pix_counter = pix_counter + 1
    file_move, outdir+filename+'_lines.txt', outdir+objname+'_irs_pixel'+strtrim(pix_counter,2)+'_lines.txt', /overwrite
  endfor
endfor

plot_contour_irs, noiselevel=3, indir=outdir, plotdir=outdir, objname=objname, verbose=1, fx=1, spitzerirs=1, max_irs_pixel=pix_counter

end