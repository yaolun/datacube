pro extract_pacs, indir=indir, filename=filename, outdir=outdir, plotdir=plotdir, pospath=pospath, noiselevel=noiselevel, test=test, ra=ra, dec=dec,$
	localbaseline=localbaseline,global_noise=global_noise,fixed_width=fixed_width,linescan=linescan,continuum=continuum,opt_width=opt_width,object=object,flat=flat,print_all=print_all,$
	plot_subtraction=plot_subtraction,current_pix=current_pix,no_plot=no_plot,double_gauss=double_gauss ;glo_print_only=glo_print_only,
	; The indir is the path of the spectrum of each pixel, including every letter in the filename except the pixel number.  For example, '/path/to/data/pacs_pixel13.txt', the indir will be '/path/to/data/pacs_pixel'
	; Same method of the indir apply to the outdir.
	if file_test(outdir) eq 0 then file_mkdir, outdir
	if not keyword_set(no_plot) then begin
		if file_test(plotdir+'base',/directory) eq 0 then file_mkdir,plotdir+'base'
	endif
	if file_test(plotdir+'cannot_fit',/directory) eq 0 then file_mkdir,plotdir+'cannot_fit'

	; no_plot flags the option of plotting the fitting results of individual line.
	if keyword_set(no_plot) then begin
		no_plot = 1
	endif else begin
		no_plot = 0
	endelse
    ; The path to the data that you want to fit.  wavelength in um and flux in Jy.
    readcol, indir+filename+'.txt', format='D,D', wl, flux,/silent
    ; Read the corrdinates information if we are fitting data cube.
    if (keyword_set(current_pix)) and ~(string(current_pix) eq 'c') then readcol, indir+filename+'_coord.txt', format='D,D,D', wl_coord, ra_tot, dec_tot, /silent
    ; Get rid off the NaN
    wl = wl[where(finite(flux) eq 1)]
    std = flux[where(finite(flux) eq 1)] * 0
    flux = flux[where(finite(flux) eq 1)]
    ; Convert the flux to appropriate unit
    c = 2.998d8
    flux = flux*1d-4*c/(wl*1d-6)^2*1d-6*1d-26  ;Change F_nu (Jy) -> F_lambda (W cm-2 um-1)
    std = std*1d-4*c/(wl*1d-6)^2*1d-6*1d-26 + 1 ; weight = 1/0 cause problem
    ; Information about the line that you want to fit including the range for baseline fitting.
    ; every level is equal to LAMDA level-1
    ; In the later version, the 10 times of resolutions is used for determining the baseline. Thus the baseline number here is less important
    line_name_oh2o = ['o-H2O8_27-7_16','o-H2O9_09-8_18','o-H2O7_52-8_27','o-H2O4_32-3_21','o-H2O5_41-6_16','o-H2O9_18-9_09','o-H2O8_18-7_07','o-H2O6_61-6_52','o-H2O7_61-7_52',$ ;'o-H2O10_29-10_110',
    	              'o-H2O6_25-5_14','o-H2O7_16-6_25','o-H2O3_30-2_21','o-H2O3_30-3_03','o-H2O8_27-8_18','o-H2O7_07-6_16','o-H2O7_25-6_34','o-H2O3_21-2_12','o-H2O8_54-8_45','o-H2O6_52-6_43',$
    	              'o-H2O5_50-5_41','o-H2O7_52-7_43','o-H2O4_23-3_12','o-H2O9_27-9_18','o-H2O6_16-5_05','o-H2O8_36-8_27','o-H2O7_16-7_07','o-H2O8_45-8_36','o-H2O6_43-6_34','o-H2O6_25-6_16',$
    	              'o-H2O4_41-4_32','o-H2O6_34-6_25','o-H2O2_21-1_10','o-H2O7_43-7_34','o-H2O4_41-5_14','o-H2O4_14-3_03','o-H2O9_27-10_110','o-H2O8_36-9_09','o-H2O7_34-6_43','o-H2O4_32-4_23',$
    	              'o-H2O9_36-9_27','o-H2O7_25-7_16','o-H2O9_45-9_36','o-H2O4_23-4_14','o-H2O8_36-7_43','o-H2O5_14-5_05','o-H2O3_30-3_21','o-H2O5_23-4_32','o-H2O8_45-7_52','o-H2O6_34-7_07',$
    	              'o-H2O5_32-5_23','o-H2O7_34-7_25','o-H2O3_03-2_12','o-H2O4_32-5_05','o-H2O2_12-1_01','o-H2O2_21-2_12','o-H2O8_54-9_27']
    	              ;'o-H2O5_41-5_32','o-H2O5_05-4_14','o-H2O5_14-4_23'
    line_center_oh2o = [55.13237858,56.81776703,57.39510658,58.70051448,61.31781921,62.92978624,63.32514386,63.91602319,63.95696098,$ ;55.84107632,
    	                65.16779477,66.09434431,66.43936941,67.27066614,70.70435046,71.94880555,74.94690356,75.38256949,75.49739784,75.83187829,$
    	                75.91180234,77.76344508,78.74431117,81.40747341,82.03351147,82.97879320,84.76907298,85.77088313,92.81311776,94.64642892,$
						94.70758174,104.0962925,108.0758815,112.5134151,112.8057590,113.5402058,114.4565616,116.3528767,116.7819562,121.7247732,$
						123.4635170,127.8873463,129.3421955,132.4117288,133.5524240,134.9386313,136.4994335,156.2690816,159.0545289,159.4042699,$
						160.5140957,166.8188522,174.6302863,174.9244086,179.5311752,180.4928070,187.8148753]
						;98.49638273,99.49555191,100.9155494,
	range_oh2o = [[55,55.4],[56.31,57.31],[56.89,57.89],[58.2,59.2],[60.81,61.81],[62.42,63.3],[62.82,63.85],[63.4,63.95],[63.92,64.45],$ ;[55.34,56.34],
		  		  [64.67,65.67],[65.7,66.59],[65.9,66.9],[66.57,67.57],[70.2,70.8],[71.44,72.44],[74.89,75.37],[74.95,75.45],[75.39,75.8],[75.5,75.9],$
		  		  [75.84,76.41],[77.26,78.26],[78.24,79.24],[80.9,81.7],[81.5,82.5],[82.4,83.4],[84.6,85.26],[85.27,86.27],[92.3,93.3],[94.14,94.7],$
		  		  [94.65,95.15],[103.5,104.4],[107.5,108.5],[112,112.75],[112.55,113.5],[112.9,114],[114,115],[115.86,116.7],[116.4,117.28],[121.22,122.22],$
		  		  [122.96,123.96],[127.38,128.38],[128.84,129.84],[131.91,132.91],[133.05,134.05],[134.43,135.43],[135.96,136.96],[155.76,156.76],[158.55,159.35],[159.1,159.9],$
		  		  [160,161],[166.3,167.3],[174.25,175.25],[174.77,175.4],[179,180],[180.31,180.71],[187.3,188.3]]
		  		  ;,[97.99,98.99],[98.99,99.99],[100.4,101.4];[50.8,51.4],[51.1,51.6],[51.45,52.18],[52.36,53.36],[52.95,53.95],[54,55],
	cont_oh2o = [[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],$ ;[50.76,70,70,90],
				 [50.76,70,70,90],[50.76,70,70,90],[55,63,66.6,69],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],$
				 [50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[90,94,94,95.15],[90,94,94,95.15],$
				 [90,94,94,95.15],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],$
				 [103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[145,150,150,170],[145,150,150,170],[145,150,150,170],$
				 [145,150,150,170],[145,150,150,170],[170,180,180,191],[170,180,180,191],[170,180,180,191],[170,180,180,191],[170,180,180,190]]
				 ;[90,99,99,101.45],[90,99,99,101.45],[90,99,99,101.45],

	line_name_ph2o = ['p-H2O6_51-7_26','p-H2O7_71-7_62','p-H2O10_19-10_010','p-H2O4_31-3_22','p-H2O9_19-8_08','p-H2O4_22-3_13','p-H2O8_17-7_26','p-H2O6_42-7_17','p-H2O7_26-6_15','p-H2O8_26-7_35',$
					  'p-H2O7_62-8_35','p-H2O4_31-4_04','p-H2O4_40-5_15','p-H2O9_28-9_19','p-H2O8_08-7_17','p-H2O7_62-7_53','p-H2O3_31-2_20','p-H2O5_24-4_13','p-H2O7_17-6_06','p-H2O5_51-6_24',$
					  'p-H2O8_17-8_08','p-H2O9_37-9_28','p-H2O5_51-5_42','p-H2O7_53-7_44','p-H2O6_51-6_42','p-H2O6_15-5_24','p-H2O9_46-9_37','p-H2O8_53-8_44','p-H2O7_26-7_17','p-H2O8_35-7_44',$
					  'p-H2O6_06-5_15','p-H2O3_22-2_11','p-H2O7_44-7_35','p-H2O5_42-5_33','p-H2O6_42-6_33','p-H2O6_15-6_06','p-H2O5_24-5_15','p-H2O5_33-5_24','p-H2O9_46-8_53','p-H2O9_37-8_44',$
					  'p-H2O8_44-8_35','p-H2O4_04-3_13','p-H2O3_31-3_22','p-H2O7_53-8_26','p-H2O7_35-8_08','p-H2O3_13-2_02','p-H2O4_13-3_22','p-H2O4_31-4_22','p-H2O8_35-8_26',$;,'p-H2O8_44-7_53' too close to p-H2O3_13-2_02
					  'p-H2O5_42-6_15','p-H2O3_22-3_13','p-H2O3_31-4_04','p-H2O8_26-9_19','p-H2O6_24-6_15','p-H2O7_35-6_42','p-H2O6_33-6_24','p-H2O4_13-4_04']; 'p-H2O5_33-6_06'
					  ;,'p-H2O5_15-4_04','p-H2O4_40-4_31','p-H2O9_37-10_010','p-H2O8_26-8_17','p-H2O2_20-1_11','p-H2O6_24-5_33'
	line_center_ph2o = [55.85969505,55.98479901,56.02823528,56.32639972,56.77240026,57.63798074,57.71080360,58.37823620,59.98862729,60.16364998,$
						60.23082319,61.81015751,61.91771787,62.43310567,63.45961419,63.88176546,67.09081789,71.06907471,71.54145512,71.78954978,$
						72.03407279,73.61470814,75.78324339,75.81532388,76.42386012,78.93041796,80.22430608,80.55884341,81.21764901,81.69220469,$
						83.28605594,89.99060576,90.05205167,94.21192952,103.9189211,103.9427769,111.6307759,113.9508129,117.6869226,118.4082552,$
						122.5251943,125.3568310,126.7171092,130.3219860,137.6865162,138.5312718,144.5214416,146.9264272,148.7115604,$;,138.6441215
						148.7941027,156.1979172,158.3155136,159.4892632,167.0391189,169.7430470,170.1434151,187.1154299]; 174.6112595,
						;,95.62963569,95.88734568,98.33183389,99.98112364,100.9852988,101.2115812,
	range_ph2o = [[55.84,55.95],[55.86,56.02],[55.99,56.3],[56.03,56.7],[56.4,56.8],[57.4,57.7],[57.65,58.21],[57.87,58.65],[59.48,60.1],[60,60.2],$
				  [60.17,60.73],[61.4,61.9],[61.85,62.4],[61.95,62.85],[63.35,63.8],[63.5,63.9],[66.59,67.25],[70.8,71.56],[71.1,71.75],[71.6,71.9],$
				  [71.95,72.53],[73.11,74.11],[75.4,75.8],[75.8,75.83],[76,76.92],[78.75,79.3],[79.72,80.5],[80.3,81.15],[80.71,81.35],[81.45,82.19],$
				  [83,83.78],[89,90.1],[90,91],[93.71,94.6],[103.5,103.94],[103.92,104],[111.13,112.13],[113.6,114.4],[117.18,118.18],[117.9,118.9],$
				  [122,123],[124.85,125.85],[126.21,127.21],[129.82,130.82],[137.18,138.18],[138.03,138.6],[144.1,144.7],[146.42,147.42],[148.21,148.75],$;,[138.55,139]
				  [148.75,149.29],[155.69,156.25],[157.9,158.81],[159.45,160],[166.9,167.5],[169.24,170.1],[169.8,170.64],[186.61,187.7]] ;[174.11,174.9],
				  ;[95.12,95.85],[95.65,96.38],[97.83,98.45],[99.5,100.48],[100.95,101.15],[101,101.45],
	cont_ph2o = [[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],$
				 [50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],$
				 [50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],[50.76,70,70,90],$
				 [50.76,70,70,90],[85.1,89.85,90.25,92],[90,94,94,95.15],[90,94,94,95.15],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],$
				 [103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[103.5,110,110,139],[140,150,150,171],[140,150,150,171],[140,150,150,171],$
				 [140,150,150,171],[140,150,150,171],[140,150,150,171],[140,150,150,171],[140,150,150,171],[140,150,150,171],[140,150,150,171],[174,180,180,190]]
				 ;[90,99,99,101.45],[90,99,99,101.45],[90,99,99,101.45],[90,99,99,101.45],[90,99,99,101.45],[90,99,99,101.45], [174,180,180,190],

	line_name_co = ['CO40-39','CO39-38','CO38-37','CO37-36','CO36-35','CO35-34','CO34-33','CO33-32','CO32-31','CO31-30',$
					'CO30-29','CO29-28','CO28-27','CO25-24','CO24-23','CO23-22','CO22-21','CO21-20','CO20-19',$;'CO27-26',
					'CO19-18','CO18-17','CO17-16','CO16-15','CO15-14','CO14-13','CO41-40','CO42-41','CO43-42','CO44-43',$
					'CO45-44','CO46-45','CO47-46','CO48-47']
	line_center_co = [65.687911815,67.338144584,69.076142800,70.909022876,72.844686840,74.891943997,77.060638546,79.361807645,81.807868093,84.412840643,$
					  87.192614489,90.165270280,93.351471151,104.44757831,108.76554579,113.46045374,118.58370114,124.19647650,130.37220897,$;96.774942409,
					  137.19978120,144.78783174,153.27056228,162.81572308,173.63579573,186.00397423,64.11741289,62.62410181,61.20105869,59.84349455,$
					  58.54704610,57.30772955,56.12190020,54.98621712]
	range_co = [[65.19,66.19],[66.84,67.84],[68.57,69.57],[70.41,71.41],[72.34,73.34],[74.39,75.39],[76.56,77.56],[78.86,79.86],[81.31,82.31],[83.91,84.5],$
			    [86.69,87.69],[90.1,91],[92.84,93.84],[103.96,104.96],[108.26,109.26],[112.96,113.96],[118.08,119.08],[123.69,124.69],[129.87,130.87],$;[96.27,97.27],
			    [136.696,137.696],[144.28,145.28],[152.77,153.77],[162.31,163.31],[173.13,174.13],[184.499,186.499],[63.61,64.61],[62.12,63.12],[60.70,61.70],[59.34,60.34],$
			    [58.04,59.04],[56.70,57.70],[55.62,56.62],[54.48,55.48]]

	cont_co = [[62,65.19,66.19,66.84],[66.19,66.84,67.84,68.57],[67.84,68.57,69.57,70.41],[69.57,70.41,71.41,72.34],[71.41,72.34,73.34,74.39],[73.34,74.39,75.39,76.56],[75.39,76.56,77.56,78.86],[77.56,78.86,79.86,81.31],[79.8,81.31,82.31,83.91],[80,83.91,84.5,89],$
			   [85,86.69,87.69,89],[85,89.85,90.25,92],[90.9,93.2,93.45,96],[102,104.35,104.6,108],[105.5,108.65,108.9,110],[108,113.4,113.65,118],[113,118.45,118.7,118.95],[122.2,124.05,124.3,129],[125,130.25,130.5,135],$;[92,96.65,96.9,100],
			   [132,137.1,137.35,139],[140,144,145,145.5],[152.5,153.1,153.4,157],[158,162.7,162.95,168],[168,173.5,173.75,174.0],[180,185.9,186.1,186.5],[54,63.61,64.61,66],[54,62.12,63.12,66],[54,60.70,61.70,66],[54,59.34,60.34,66],$
			   [54,58.04,59.04,66],[54,56.70,57.70,66],[54,55.62,56.62,66],[54,54.48,55.48,66]]

	line_name_oh = ['OH19-14','OH18-15','OH13-9','OH12-8','OH14-10','OH15-11','OH5-1','OH4-0','OH9-3','OH8-2',$
				    'OH10-8','OH11-9','OH3-1','OH2-0','OH14-12','OH15-13','OH19-16','OH7-5','OH6-4'];,'OH18-17' too close to CII line ; , we think the wavelength is wrong from LAMDA
	line_center_oh = [55.89230701,55.95141064,65.13336752,65.28048087,71.17262181,71.21722533,79.11753556,79.18106327,84.42236779,84.59877137,$
					  115.1505737,115.3844118,119.2374049,119.4444962,134.8415187,135.9598052,154.7834879,163.12467358,163.4001337];,157.8098369; ,163.0192292
	range_oh = [[55.85,55.9],[55.9,56],[64.5,65.2],[65.2,66],[70.7,71.2],[71.2,72],[78.5,79.15],[79.15,80.5],[83.35,84.5],[84.5,85],$
				[114.5,115.3],[115.3,116],[118.81,119.4],[119.4,120.02],[134,135.5],[135.5,136.5],[154,155.5],[157,158.5],[162.5,163.3],[163.3,164.5]];
	cont_oh = [[55.85,60,60,70],[55.85,60,60,70],[55.85,60,60,70],[55.85,60,60,70],[65,75,75,80],[65,75,75,80],[65,75,75,80],[65,75,75,80],[80,84.35,84.7,87],[84.45,84.57,84.7,87],$
			   [115,115.15,115.38,119],[115,115.15,115.38,119],[118.9,119.1,119.6,121],[118.9,119.1,119.6,121],[134,150,150,165],[134,150,150,165],[134,150,150,165],[134,150,150,165],[134,150,150,165]];,[134,150,150,165];

	line_name_ch = ['CH+3-2','CH+5-4','CH+6-5'] ; 'CH+2-1','CH+4-3'
	line_center_ch = [119.85466040,72.13950405,60.24658501] ; 179.60534781,90.01483417
	range_ch = [[119,120.3],[71.5,73],[59.5,60.7]] ; [179,180],[89,90.5],
	cont_ch = [[115,119,120.3,125],[65,71.5,73,77],[55,59.5,60.7,65]] ; [175,179,180,185],[85,89,90.5,95],

	line_name_other = ['OI3P1-3P2','NII_122','OI3P0-3P1','CII2P3_2-2P1_2']; ,'OH_hf_61.4','OH_hf_163.12'
	line_center_other = [63.1836709,121.9,145.48055764,157.69228158] ; ,61.46556395
	range_other = [[62.73,63.73],[121.5,122.5],[145.13,146.13],[157.35,158.35]]; ,[61.35,61.45],[163.07,163.17]
	cont_other = [[62.9,63.1,63.3,63.6],[119,121.8,122.2,123],[144.95,145.45,145.65,152],[155,157.5,158.0,162]]; ,[60,61.35,61.45,63],[162,163.07,163.17,165]

	line_name = [line_name_oh2o, line_name_ph2o, line_name_co, line_name_oh, line_name_ch, line_name_other]
	line_center = [line_center_oh2o, line_center_ph2o, line_center_co, line_center_oh, line_center_ch, line_center_other]
	range = [[range_oh2o], [range_ph2o], [range_co], [range_oh], [range_ch], [range_other]]
	cont = [[cont_oh2o], [cont_ph2o], [cont_co], [cont_oh], [cont_ch], [cont_other]]

	; Read the instrument resolutions
  readcol, '~/programs/line_fitting/spectralresolution_order1.txt', format='D,D', wl1, res1,/silent
	readcol, '~/programs/line_fitting/spectralresolution_order2.txt', format='D,D', wl2, res2,/silent
	readcol, '~/programs/line_fitting/spectralresolution_order3.txt', format='D,D', wl3, res3,/silent
	fwhm1 = wl1/res1 & fwhm2 = wl2/res2 & fwhm3 = wl3/res3
	wl_ins = [wl2[where(wl2 lt min(wl1))], wl1]
	dl_ins = [fwhm2[where(wl2 lt min(wl1))], fwhm1]/2.354
	; Define the range of line center by setting the range within -2-2 times of the resolution elements of the line center
	; Since the [OI] 63 um lines are usually wider, we use -3-3 times of the resolution for this line.
	range = []
	line_name = line_name[sort(line_center)]
	line_center = line_center[sort(line_center)]
	cont = cont[*,sort(line_center)]
	for i = 0, n_elements(line_center)-1 do begin
		dl = interpol(dl_ins, wl_ins, line_center[i])
		if line_name[i] eq 'OI3P1-3P2' then range_factor=3
		if line_name[i] ne 'OI3P1-3P2' then range_factor=2
		if i eq 0 then begin
			lower = line_center[i]-(range_factor)*dl
			if (range_factor)*dl gt 0.5*(line_center[i+1]-line_center[i]) then begin
				upper = line_center[i]+0.5*(line_center[i+1]-line_center[i])
			endif else begin
				upper = line_center[i]+(range_factor)*dl
			endelse
			range = [[range], [[lower, upper]]]
		endif
		if (i ne 0) and (i ne n_elements(line_center)-1) then begin
			if range_factor*dl gt 0.5*(line_center[i]-line_center[i-1]) then begin
				lower = line_center[i]-0.5*(line_center[i]-line_center[i-1])
			endif else begin
				lower = line_center[i]-(range_factor)*dl
			endelse
			if (range_factor)*dl gt 0.5*(line_center[i+1]-line_center[i]) then begin
				upper = line_center[i]+0.5*(line_center[i+1]-line_center[i])
			endif else begin
				upper = line_center[i]+(range_factor)*dl
			endelse
			range = [[range], [[lower, upper]]]
		endif
		if i eq n_elements(line_center)-1 then begin
			if range_factor*dl gt 0.5*(line_center[i]-line_center[i-1]) then begin
				lower = line_center[i]-0.5*(line_center[i]-line_center[i-1])
			endif else begin
				lower = line_center[i]-(range_factor)*dl
			endelse
			upper = line_center[i]+(range_factor)*dl
			range = [[range], [[lower, upper]]]
		endif
	endfor

	; Create a wavelength array that every elements in this array can be selected as a valid point for baseline fitting
	base_mask = 0*wl
	for i = 0, n_elements(wl)-1 do begin
		valid=1
		for j = 0, n_elements(line_name)-1 do begin
			if (wl[i] ge range[0,j]) and (wl[i] le range[1,j]) then valid = valid*0
		endfor
		if valid eq 1 then base_mask[i] = 1
	endfor

	wl_basepool = wl[where(base_mask ne 0)] & flux_basepool = flux[where(base_mask ne 0)] & std_basepool = std[where(base_mask ne 0)]
	; Select different line list for line scan spectrum
	dl_min = interpol(dl_ins, wl_ins, min(wl))
	dl_max = interpol(dl_ins, wl_ins, max(wl))
	wl_seg1 = wl[where(wl lt 100)]
	wl_seg2 = wl[where(wl ge 100)]
	seg1 = where((line_center ge (min(wl_seg1)+5*dl_min)) and (line_center le (max(wl_seg1)-5*dl_max)))
	seg2 = where((line_center ge (min(wl_seg2)+5*dl_min)) and (line_center le (max(wl_seg2)-5*dl_max)))

	seg = []
	if seg1[0] ne -1 then seg = [seg,seg1]
	if seg2[0] ne -1 then seg = [seg,seg2]
	; Check if the spectrum has at least one side of PACS spectrum.
	if seg1[0] eq -1 and seg2[0] eq -1 then begin
		return
		end

	line_name = line_name[seg]
	line_center = line_center[seg]
	range = range[*,seg]
	cont = cont[*,seg]

	; Modified the line list for double Gaussian fitting
	line_name_dg = [['CO31-30','OH9-3'],['CO23-22','o-H2O4_14-3_03'],['p-H2O7_53-8_26','CO20-19'],['OH14-12','o-H2O5_14-5_05'],$
					['p-H2O3_22-3_13','o-H2O5_23-4_32'],['p-H2O6_51-7_26','OH19-14'],['OH18-15','p-H2O7_71-7_62'],$
					['p-H2O9_19-8_08','o-H2O9_09-8_18'],['OH13-9','o-H2O6_25-5_14'],['OH14-10','OH15-11'],$;,['p-H2O9_37-8_44','CO22-21']
					['o-H2O7_34-7_25','p-H2O6_24-6_15'],$; ,['CO16-15','OH7-5']  we think OH7-5 has the wrong wavelength
					['p-H2O4_13-3_22','CO18-17'],['p-H2O7_53-7_44','o-H2O6_52-6_43'],['OH5-1','OH4-0']];['OH3-1','OH2-0'],
					; lines are too close to get a well-constrained fit: ['CII2P3_2-2P1_2','OH18-17'],['p-H2O3_13-2_02','p-H2O8_44-7_53']
					; ['p-H2O5_33-6_06','o-H2O3_03-2_12'],
	line_center_dg = []
	range_dg = []
	line_dg = []
	excluded_line =[]
	for dg = 0, n_elements(line_name_dg[0,*])-1 do begin
		ind = where(line_name eq line_name_dg[0,dg] or line_name eq line_name_dg[1,dg])
		if n_elements(ind) eq 2 then begin
			range_dg = [[range_dg],[min(range[*,ind]), max(range[*,ind])]]
			excluded_line = [excluded_line,line_name_dg[0,dg],line_name_dg[1,dg]]
			line_center_dg = [line_center_dg,line_center[ind]]
			for k = 0, n_elements(ind)-1 do begin
				line_dg = [[line_dg], [line_center[ind[k]], range[0,ind[k]], range[1,ind[k]]]]
			endfor
		endif
	endfor

  ; The path to the output file for print out the fitting result.
	name = outdir+filename+'_lines'
	if keyword_set(linescan) then name = name+'_LS'
    openw, firstfit, name+'.txt', /get_lun
    if not keyword_set(current_pix) then begin
		printf, firstfit, format='((a18,2x),17(a18,2x))', $
    		'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Blend'
    endif else begin
    	printf, firstfit, format='((a18,2x),18(a18,2x))', $
    		'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel_No.','Blend'
    endelse

	; Using band 3 resolution for some of the WISH sources
	b3a = 0
	special_list = ['NGC1333-IRAS2A','Serpens-SMM1','G327-06','DR21(OH)','NGC7538-IRS1','NGC6334-I','G34.3+0.1','HOPS108']
	if (where(special_list eq object))[0] ne -1 then b3a = 1

    ; Do the fitting for every line in the list
    ; Single Gaussian fitting
    for i = 0, n_elements(line_name)-1 do begin
    	; Check if the line that about to fit is the one in the double Gaussian fitting list.
    	if (keyword_set(double_gauss)) and ((where(excluded_line eq line_name[i]))[0] ne -1) then continue
        ; select the baseline
        ; And also store the information of the edge wavelengths of the baseline
        dl = interpol(dl_ins, wl_ins, line_center[i])

		if not keyword_set(localbaseline) then indb = where((wl gt cont[0,i] and wl lt cont[1,i]) or (wl gt cont[2,i] and wl lt cont[3,i]))
		; Usually localbaseline = 10
		if keyword_set(localbaseline) then begin
			dlb = localbaseline*dl
			wl_diff = wl[1:-1]-wl[0:-2]
			numb = ceil(dlb/(wl_diff[where(wl ge line_center[i])])[0])
			if line_center[i] le 95.08 then begin
				left = where(wl_basepool lt range[0,i] and wl_basepool ge min(wl))
				right = where(wl_basepool gt range[1,i] and wl_basepool le 95.08)
			endif
			if line_center[i] ge 102 then begin
				left = where(wl_basepool lt range[0,i] and wl_basepool ge 102)
				right = where(wl_basepool gt range[1,i] and wl_basepool le max(wl))
			endif
			if n_elements(left) gt numb then left = left[n_elements(left)-1-numb:n_elements(left)-1]
			if n_elements(right) gt numb then right = right[0:numb-1]
            if left[0] ne -1 and right[0] ne -1 then begin
                wlb = [wl_basepool[left], wl_basepool[right]]
                fluxb = [flux_basepool[left], flux_basepool[right]]
                stdb = [std_basepool[left], std_basepool[right]]
                base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]], wl_basepool[right[0]], wl_basepool[right[n_elements(right)-1]]]
            endif
            if left[0] eq -1 and right[0] ne -1 then begin
                wlb = [wl_basepool[right]]
                fluxb = [flux_basepool[right]]
                stdb = [std_basepool[right]]
                base_range = [wl_basepool[right[0]], wl_basepool[right[0]],wl_basepool[right[0]],wl_basepool[right[n_elements(right)-1]]]
            endif
            if left[0] ne -1 and right[0] eq -1 then begin
                wlb = [wl_basepool[left]]
                fluxb = [flux_basepool[left]]
                stdb = [std_basepool[left]]
                base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]]]
            endif
            indl = where(wl gt base_range[0] and wl lt base_range[3])
			if base_range[0] eq base_range[1] then indl = where(wl gt min(wl) and wl lt base_range[3])
			if base_range[2] eq base_range[3] then indl = where(wl gt base_range[0] and wl lt max(wl))
			wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
        endif
        ; select the line+baseline
		if not keyword_set(localbaseline) then begin
        	if i le 39 then begin
        	    indl = where(wl gt cont[0,i] and wl lt cont[3,i])
        	    wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
       		endif else begin
        	    indl = where(wl gt range[0,i]-0.5 and wl lt range[1,i]+0.5)
        	    wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
        	endelse
		endif
        ; use the plot_base feature to plot the actual spectrum (with line) here
		plot_base = [[wll],[fluxl]]
		if n_elements(wlb) lt 3 then continue
        ; fit the baseline and return the baseline parameter in 'base_para'
        fit_line, filename, line_name[i], wlb, fluxb, std=stdb, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, /baseline, outdir=plotdir, no_plot=no_plot, plot_base=plot_base

		; extract the wave and flux for plottng that is for better visualization of the fitting results.
		ind_plot = where(wl gt base_range[0]-5*dl and wl lt base_range[3]+5*dl)
		plot_wl = wl[ind_plot] & plot_flux = flux[ind_plot] & plot_std = std[ind_plot]
		plot_base = [[wlb],[fluxb]]
        ; Subtract the baseline from the spectrum
        ; First, calculate the baseline
        ; base = base_para[0]*wll +base_para[1]                       ;use 1st order polynomial
        base = base_para[0]*wll^2+base_para[1]*wll+base_para[2]      ;use 2nd order polynomial
        ; Subtract
        fluxx = fluxl - base
        stdd = stdl
        line = [line_center[i],range[0,i],range[1,i]]                      ;[line_center, line profile lower limit, line profile upper limit]
        ; Fitting part
        ; Different fitting keyword for fixed width and test arguement

        if keyword_set(fixed_width) and keyword_set(opt_width) then begin
        	if line_name[i] eq 'OI3P1-3P2' then begin
        		if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, base_range=base_range, no_plot=no_plot,b3a=b3a
				if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
										       /single_gauss,outdir=plotdir, noiselevel=noiselevel, base_range=base_range, no_plot=no_plot,b3a=b3a
			endif else begin
				if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a
				if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
										       /single_gauss,outdir=plotdir, noiselevel=noiselevel, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a
			endelse
        endif else if keyword_set(fixed_width) and (not keyword_set(opt_width)) then begin
        		if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a
				if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
										       /single_gauss,outdir=plotdir, noiselevel=noiselevel, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a
        endif else begin
        	if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        						      /single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, base_range=base_range, no_plot=no_plot, b3a=b3a
			if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
										  /single_gauss,outdir=plotdir, noiselevel=noiselevel, base_range=base_range, no_plot=no_plot, b3a=b3a
        endelse
        ; if the global_noise keyword is not specified, then do the fitting again but take the evaluated noise as the error of the data
        if not keyword_set(global_noise) then begin
        	feedback = noise + fluxx*0
	        if keyword_set(fixed_width) and keyword_set(opt_width) then begin
	        	if line_name[i] eq 'OI3P1-3P2' then begin
	        		if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
	        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
					if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
											       /single_gauss,outdir=plotdir, noiselevel=noiselevel, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
				endif else begin
					if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
	        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
					if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
											       /single_gauss,outdir=plotdir, noiselevel=noiselevel, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
				endelse
	        endif else if keyword_set(fixed_width) and (not keyword_set(opt_width)) then begin
	        		if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
	        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
					if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
											       /single_gauss,outdir=plotdir, noiselevel=noiselevel, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
	        endif else begin
	        	if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
	        						      /single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, base_range=base_range, no_plot=no_plot, b3a=b3a, feedback=feedback
				if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
											  /single_gauss,outdir=plotdir, noiselevel=noiselevel, base_range=base_range, no_plot=no_plot, b3a=b3a, feedback=feedback
	        endelse
       	endif

        ; Print the fittng result into text file

        if status le 0 then begin
            printf, firstfit, format = '((a18,2X),(a50))', line_name[i], errmsg
        endif else begin
            ; The read_line_ref procedure read the g, A, E_u from another file
            read_line_ref, line_name[i], E_u, A, g
            ; The baseline are in the unit of W/cm2/um
            base_str = interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl)
            if not keyword_set(ra) then ra = 0
            if not keyword_set(dec) then dec = 0
            if (keyword_set(current_pix)) and ~(string(current_pix) eq 'c') then begin
            	ra = interpol(ra_tot, wl_coord, line_center[i])
            	dec = interpol(dec_tot, wl_coord, line_center[i])
            endif
            ; Blended lines classification
            blue_blend = 0 & red_blend = 0
            if i eq 0 then begin
            	if line_center[i+1]-cen_wl lt fwhm then red_blend = 1
            endif
            if i ne 0 and i ne n_elements(line_center)-1 then begin
            	if cen_wl-line_center[i-1] lt fwhm then blue_blend = 2
            	if line_center[i+1]-cen_wl lt fwhm then red_blend  = 1
            endif
            if i eq n_elements(line_center)-1 then begin
            	if cen_wl-line_center[i-1] lt fwhm then blue_blend = 2
            endif
            blend_flag = red_blend+blue_blend
            if blend_flag eq 0 then blend_msg = 'x'
            if blend_flag eq 1 then blend_msg = 'Red'
            if blend_flag eq 2 then begin
            	blend_msg = 'Blue'
            	blend_flag = 3
            endif
            if blend_flag eq 3 then begin
            	blend_msg = 'Red/Blue'
            	blend_flag = 2
            endif
            ; Throw away the bogus results due to the missing segment in the spectrum
            if finite(snr,/nan) eq 1 then continue
            ; blend flag = 0: no blend; blend_flag = 1: Red blend; blend_flag = 2: Red/Blue blend; blend_flag = 3: Blue blend.
            ;
            if not keyword_set(current_pix) then begin
            	printf, firstfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),(a18,2x))',$
            		line_name[i], line_center[i], cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, E_u, A, g, ra, dec, blend_msg
            endif else begin
            	printf, firstfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),2(a18,2x))',$
            		line_name[i], line_center[i], cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, E_u, A, g, ra, dec, current_pix, blend_msg
            endelse
        endelse
    endfor
    ; Double Gaussian fit
	if keyword_set(double_gauss) then begin
		for i = 0, n_elements(line_center_dg)/2-1 do begin
			mean_wl = (line_center_dg[2*i]+line_center_dg[2*i+1])/2
			if (min(wl) gt mean_wl) or (max(wl) lt mean_wl) then continue
			dlb = localbaseline*dl
			wl_diff = wl[1:-1]-wl[0:-2]
			numb = ceil(dlb/(wl_diff[where(wl ge line_center_dg[2*i])])[0])
			left = where(wl_basepool lt range_dg[0,i] and wl_basepool ge min(wl)) & right = where(wl_basepool gt range_dg[1,i] and wl_basepool le max(wl))
			if n_elements(left) gt numb then left = left[n_elements(left)-1-numb:n_elements(left)-1]
			if n_elements(right) gt numb then right = right[0:numb-1]
			if left[0] ne -1 and right[0] ne -1 then begin
            	wlb = [wl_basepool[left], wl_basepool[right]]
            	fluxb = [flux_basepool[left], flux_basepool[right]]
            	stdb = [std_basepool[left], std_basepool[right]]
				base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]], wl_basepool[right[0]], wl_basepool[right[n_elements(right)-1]]]
				indl = where(wl gt base_range[0] and wl lt base_range[3])
				wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
			endif
			if left[0] eq -1 and right[0] ne -1 then begin
                wlb = [wl_basepool[right]] & fluxb = [flux_basepool[right]] & stdb = [std_basepool[right]]
				base_range = [wl_basepool[right[0]], wl_basepool[right[0]],wl_basepool[right[0]],wl_basepool[right[n_elements(right)-1]]]
				indl = where(wl gt min(wl) and wl lt base_range[2])
				wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
			endif
			if left[0] ne -1 and right[0] eq -1 then begin
				wlb = [wl_basepool[left]] & fluxb = [flux_basepool[left]] & stdb = [std_basepool[left]]
				base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]]]
				indl = where(wl gt base_range[0] and wl lt max(wl))
				wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
			endif

			; use the plot_base feature to plot the actual spectrum (with line) here
			plot_base = [[wll],[fluxl]]
			fit_line, filename, line_name_dg[2*i]+'+'+line_name_dg[2*i+1], wlb, fluxb, std=stdb, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, /baseline, outdir=plotdir,no_plot=no_plot, plot_base=plot_base
			; extract the wave and flux for plottng that is for better visualization of the fitting results.
			ind_plot = where(wl gt base_range[0]-5*dl and wl lt base_range[3]+5*dl)
			plot_wl = wl[ind_plot] & plot_flux = flux[ind_plot] & plot_std = std[ind_plot]
			plot_base = [[wlb],[fluxb]]
			; Subtract the baseline from the spectrum
			; First, calculate the baseline
			; base = base_para[0]*wll +base_para[1]                       ;use 1st order polynomial
			base = base_para[0]*wll^2+base_para[1]*wll+base_para[2]       ;use 2nd order polynomial
			; Subtract
			fluxx = fluxl - base
			stdd = stdl
			; line = [cen1,ran1,ran1,cen2,ran2,ran2]
			line = [line_dg[*,2*i],line_dg[*,2*i+1]]
			; Fitting part
			; Different fitting keyword for fixed width and test arguement
			; Using band 3 resolution for some of WISH sources
			fit_line,filename,line_name_dg[2*i]+'+'+line_name_dg[2*i+1],wll,fluxx,std=stdd,status,errmsg,cen_wl,sig_cen_wl,str,sig_str,fwhm,sig_fwhm,base_para,snr,line,noise,/double_gauss,outdir=plotdir,$
				noiselevel=noiselevel,base_range=base_range,plot_base=plot_base,b3a=b3a,/fix_dg,/fixed_width

			; if the keyword global_noise is not specified, then do the fitting again but take the evaluated noise as the error of the data
			if not keyword_set(global_noise) then begin
				feedback = noise + fluxx*0
				fit_line,filename,line_name_dg[2*i]+'+'+line_name_dg[2*i+1],wll,fluxx,std=stdd,status,errmsg,cen_wl,sig_cen_wl,str,sig_str,fwhm,sig_fwhm,base_para,snr,line,noise,/double_gauss,outdir=plotdir,$
					noiselevel=noiselevel,base_range=base_range,plot_base=plot_base,b3a=b3a,/fix_dg,/fixed_width, feedback=feedback
			endif

			if status eq 0 then begin
				printf, firstfit, format = '((a18,2X),(a50))', line_name_dg[2*i]+'_'+line_name_dg[2*i+1], errmsg
			endif else begin
				; Making sure the line classification is correct
				i1 = where(line_name eq line_name_dg[2*i])
				i2 = where(line_name eq line_name_dg[2*i+1])
				if (abs(line_center[i1]-cen_wl[0]) gt abs(line_center[i1]-cen_wl[1])) and (abs(line_center[i2]-cen_wl[1]) gt abs(line_center[i2]-cen_wl[0])) then begin
					print, 'Line misplacement found in '+line_name_dg[2*i]+'+'+line_name_dg[2*i+1]
					cen_wl = reverse(cen_wl)
					sig_cen_wl = reverse(sig_cen_wl)
					str = reverse(str)
					sig_str = reverse(sig_str)
					fwhm = reverse(fwhm)
					sig_fwhm = reverse(sig_fwhm)
					snr = reverse(snr)
				endif
				read_line_ref, line_name_dg[2*i], E_u1, A1, g1
				read_line_ref, line_name_dg[2*i+1], E_u2, A2, g2
				if (keyword_set(current_pix)) and ~(string(current_pix) eq 'c') then begin
            		ra = interpol(ra_tot, wl_coord, line[0])
					dec = interpol(dec_tot, wl_coord, line[0])
				endif
				E_u = [E_u1,E_u2]
				A = [A1,A2]
				g = [g1,g2]
				base_str = [interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl[0]), $
				            interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl[1])]
				blend_msg = 'x'
				if (finite(snr,/nan))[0] eq 1 then continue
				if not keyword_set(current_pix) then begin
					printf, firstfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),(a18,2x))',$
						line_name_dg[2*i], line[0], cen_wl[0], sig_cen_wl[0], str[0], sig_str[0], fwhm[0], sig_fwhm[0], base_str[0], noise, snr[0], E_u[0], A[0], g[0], ra, dec, blend_msg
					printf, firstfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),(a18,2x))',$
						line_name_dg[2*i+1], line[3], cen_wl[1], sig_cen_wl[1], str[1], sig_str[1], fwhm[1], sig_fwhm[1], base_str[1], noise, snr[1], E_u[1], A[1], g[1], ra, dec, blend_msg
				endif else begin
					printf, firstfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),2(a18,2x))',$
						line_name_dg[2*i], line[0], cen_wl[0], sig_cen_wl[0], str[0], sig_str[0], fwhm[0], sig_fwhm[0], base_str[0], noise, snr[0], E_u[0], A[0], g[0], ra, dec, current_pix, blend_msg
					printf, firstfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),2(a18,2x))',$
						line_name_dg[2*i+1], line[3], cen_wl[1], sig_cen_wl[1], str[1], sig_str[1], fwhm[1], sig_fwhm[1], base_str[1], noise, snr[1], E_u[1], A[1], g[1], ra, dec, current_pix, blend_msg
				endelse
			endelse
		endfor
	endif
    free_lun, firstfit
    close, firstfit

    ; Blended lines labeling and pick out the most possible line
    if not keyword_set(current_pix) then begin
    	readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,I,D,D,A', $
    		line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, blend_flag_n, /silent, skipline=1
    endif else begin
    	readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,I,D,D,A,A', $
    		line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, pix_n, blend_flag_n, /silent, skipline=1
    endelse

	blend_group = []
	blend_subgroup = []
	blend_msg_all = []
	possible_all = []
	for line = 0, n_elements(line_name_n)-1 do begin
		if (keyword_set(double_gauss)) and ((where(line_name_dg eq line_name_n[line]))[0] ne -1) then begin
			blend_msg = 'DoubleGaussian'
			blend_msg_all = [blend_msg_all,blend_msg]
			continue
		endif
		; Blended lines classification
        blue_blend = 0 & red_blend = 0
        if line eq 0 then begin
            if abs(cen_wl_n[line+1]-cen_wl_n[line]) lt fwhm_n[line] then red_blend = 1
        endif
        if line ne 0 and line ne n_elements(line_name_n)-1 then begin
            if abs(cen_wl_n[line]-cen_wl_n[line-1]) lt fwhm_n[line] then blue_blend = 2
            if abs(cen_wl_n[line+1]-cen_wl_n[line]) lt fwhm_n[line] then red_blend  = 1
        endif
        if line eq n_elements(line_name_n)-1 then begin
            if abs(cen_wl_n[line]-cen_wl_n[line-1]) lt fwhm_n[line] then blue_blend = 2
        endif
        blend_flag = red_blend+blue_blend
        if blend_flag eq 0 then blend_msg = 'x'
        if blend_flag eq 1 then blend_msg = 'Red'
        if blend_flag eq 2 then begin
            blend_msg = 'Blue'
            blend_flag = 3
        endif
        if blend_flag eq 3 then begin
            blend_msg = 'Red/Blue'
			blend_flag = 2
        endif
        blend_msg_all = [blend_msg_all,blend_msg]
		if n_elements(blend_subgroup) eq 0 then group_flag = 0
		if blend_flag ge group_flag then begin
			if blend_flag eq 0 then continue
			blend_subgroup = [[blend_subgroup],[line_name_n[line],string(E_u_n[line])]]
			group_flag = blend_flag
		endif else begin
			possible_line = blend_subgroup[0,where(float(blend_subgroup[1,*]) eq min(float(blend_subgroup[1,*])))]
			if n_elements(possible_line) gt 1 then begin
				A_dum = A_n[where(line_name_n eq possible_line)]
				possible_line = possible_line[(where(line_name_n eq possible_line))[where(A_dum eq max(A_dum))]]
			endif
			blend_subgroup = []
			possible_all = [possible_all, possible_line]
			if blend_flag ne 0 then begin
				blend_subgroup = [[blend_subgroup],[line_name_n[line],string(E_u_n[line])]]
				group_flag = blend_flag
			endif
		endelse
	endfor
    openw, firstfit, name+'.txt', /get_lun
    if not keyword_set(current_pix) then begin
    	printf, firstfit, format='((a18,2x),17(a18,2x))', $
    		'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Blend','Validity'
    endif else begin
    	printf, firstfit, format='((a18,2x),18(a18,2x))', $
    		'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel_No.','Blend','Validity'
    endelse
    for line = 0, n_elements(line_name_n)-1 do begin
    	lowest = '0'
     	if (where(possible_all eq line_name_n[line]))[0] ne -1 then lowest = '1'
     	if (blend_msg_all[line] eq 'x') or (blend_msg_all[line] eq 'DoubleGaussian') then lowest = '1'
     	if finite(snr_n[line],/nan) eq 1 then lowest = '0'
     	; Reason for sig_str is that some sources have very poor spectra like EC82.  It will fit on the edge
     	if (sig_cen_wl_n[line] eq -999) or (sig_fwhm_n[line] eq -999) or (sig_str_n[line] eq -999)then lowest = '0'
     	if not keyword_set(current_pix) then begin
     		printf, firstfit, format = '( (a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),2(a18,2x) )',$
            	line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line],noise_n[line], snr_n[line],$
            	E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], blend_msg_all[line], lowest
			if keyword_set(print_all) and not keyword_set(global_noise) then begin
        		openw, gff, print_all+'.txt',/append,/get_lun
				printf, gff, format = '( 2(a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),2(a18,2x) )',$
            		object, line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line],noise_n[line], snr_n[line],$
					E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], blend_msg_all[line], lowest
				free_lun, gff
				close, gff
				; ASCII file that has everything
				openw, all, file_dirname(print_all+'.txt')+'/CDF_archive_lines.txt', /append, /get_lun
				printf, all, format = '( 2(a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),3(a18,2x) )',$
            		object, line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line],noise_n[line], snr_n[line],$
					E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], 'c', blend_msg_all[line], lowest
				free_lun, all
				close, all
			endif
     	endif else begin
     		printf, firstfit, format = '( (a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),3(a18,2x) )',$
            	line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line],noise_n[line], snr_n[line],$
            	E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], pix_n[line], blend_msg_all[line], lowest
			if keyword_set(print_all) and not keyword_set(global_noise) then begin
        		openw, gff, print_all+'.txt',/append,/get_lun
				printf, gff, format = '( 2(a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),3(a18,2x) )',$
            		object, line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line],noise_n[line], snr_n[line],$
					E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], pix_n[line], blend_msg_all[line], lowest
				free_lun, gff
				close, gff
				; ASCII file that has everything
				openw, all, file_dirname(print_all+'.txt')+'/CDF_archive_lines.txt', /append, /get_lun
				printf, all, format = '( 2(a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),3(a18,2x) )',$
            		object, line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line],noise_n[line], snr_n[line],$
					E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], pix_n[line], blend_msg_all[line], lowest
				free_lun, all
				close, all
			endif
     	endelse
    endfor
    free_lun, firstfit
    close, firstfit
    ; Plot the line subtracted spectrum
    if not keyword_set(global_noise) then begin
    	if not keyword_set(current_pix) then begin
    		readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,I,D,D,A,I', $
    			line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, blend_flag_n, lowest_E_n, /silent
    	endif else begin
    		readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,I,D,D,A,A,I', $
    			line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, pix_n, blend_flag_n, lowest_E_n, /silent
    	endelse
    	flux_sub = flux
    	for line = 0, n_elements(line_name_n)-1 do begin
    		if abs(snr_n[line]) ge noiselevel-1.0 then begin
				if (lowest_E_n[line] ne 1) then continue
    			ind = where((wl gt cen_wl_n[line]-2*fwhm_n[line]) and (wl lt cen_wl_n[line]+2*fwhm_n[line]))
    			wl_n = wl[ind]
    			line_profile = gauss(wl_n, [2.354*str_n[line]/fwhm_n[line]/(2*!PI)^0.5, cen_wl_n[line], fwhm_n[line]/2.354]);+base_str[line]
    			flux_sub[ind] = flux_sub[ind] - line_profile
    			if keyword_set(plot_subtraction) then begin
    				set_plot,'ps'
					!p.font=0
					loadct,12,/silent
					device, filename=plotdir+'line_subtracted_'+line_name[line]+'.eps',/helvetica,/portrait,/encapsulated,isolatin=1,font_size=12,decomposed=0,/color
					!p.thick=3 & !x.thick=3 & !y.thick=3

    				plot, wl_n, flux[ind], psym=10, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)', position=[0.15,0.1,0.95,0.95], $
    					yrange=[0.9*min([flux[ind],line_profile+base_str_n[line],flux_sub[line]]),1.1*max([flux[ind],line_profile+base_str_n[line],flux_sub[line]])]
					oplot, wl_n, line_profile+base_str_n[line], color=120, psym=10 ;purple
					oplot, wl_n, flux_sub[ind], color=200, psym=10 ;red
					al_legend, ['Data','Line+Baseline Fit','Subtraction'], textcolors=[0,120,200], /right
					device, /close_file, decomposed=1
					!p.multi=0
				endif
    		endif
    	endfor
    	set_plot, 'ps'
		!p.font = 0
		loadct,12,/silent
		msg = ''
		device, filename = plotdir+'spectrum_line_subtracted_'+filename+msg+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 10, decomposed = 0, /color
		!p.thick=2 & !x.thick=3 & !y.thick=3
		trim1 = where(wl lt 100) & trim2 = where(wl ge 100)
		plot, wl, flux/1e-22, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)',/nodata, position=[0.15,0.1,0.95,0.95]
		if trim1[0] ne -1 then begin
			oplot, wl[trim1], flux[trim1]/1e-22
			oplot, wl[trim1], flux_sub[trim1]/1e-22, color=200
		endif
		if trim2[0] ne -1 then begin
			oplot, wl[trim2], flux[trim2]/1e-22
			oplot, wl[trim2], flux_sub[trim2]/1e-22, color=200
		endif
		; oplot, wl, continuum/1e-22, color=50
		; al_legend,['Data','lines_subtracted','Data_smooth','(lines_subtracted)_smooth', 'flat/featureless'],textcolors=[0,200,50,100,10],/right
		al_legend,['Data','lines_subtracted'],textcolors=[0,200],/right
		al_legend,[object],textcolors=[0],/left
		device, /close_file, decomposed = 1
		!p.multi = 0
    endif

    ; Second fitting to use the results of the previous one to better estimate the noise
    if keyword_set(global_noise) then begin
    	print, '---> Re-calculating the noise level...'

    	; Read in the results of first fitting
    	if not keyword_set(current_pix) then begin
    		readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,I,D,D,A,I', $
    			line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, blend_flag_n, lowest_E_n, /silent
    	endif else begin
    		readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,I,D,D,A,A,I', $
    			line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, pix_n, blend_flag_n, lowest_E_n, /silent
    	endelse

    	; Line subtraction
    	flux_sub = flux
    	for line = 0, n_elements(line_name_n)-1 do begin
    		if abs(snr_n[line]) ge noiselevel-1.0 then begin
				if (lowest_E_n[line] ne 1) then continue
    			ind = where((wl gt cen_wl_n[line]-2*fwhm_n[line]) and (wl lt cen_wl_n[line]+2*fwhm_n[line]))
    			wl_n = wl[ind]
    			line_profile = gauss(wl_n, [2.354*str_n[line]/fwhm_n[line]/(2*!PI)^0.5, cen_wl_n[line], fwhm_n[line]/2.354]);+base_str[line]
    			flux_sub[ind] = flux_sub[ind] - line_profile
    			if keyword_set(plot_subtraction) then begin
    				set_plot,'ps'
					!p.font=0
					loadct,12,/silent
					device, filename=plotdir+'line_subtracted_'+line_name_n[line]+'.eps',/helvetica,/portrait,/encapsulated,isolatin=1,font_size=12,decomposed=0,/color
					!p.thick=3 & !x.thick=3 & !y.thick=3
    				plot, wl_n, flux[ind], psym=10, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)', position=[0.15,0.1,0.95,0.95], $
    					yrange=[0.9*min([flux[ind],line_profile+base_str_n[line],flux_sub[line]]),1.1*max([flux[ind],line_profile+base_str_n[line],flux_sub[line]])]
					oplot, wl_n, line_profile+base_str_n[line], color=120, psym=10 ;purple
					oplot, wl_n, flux_sub[ind], color=200, psym=10 ;red
					al_legend, ['Data','Line+Baseline Fit','Subtraction'], textcolors=[0,120,200], /right
					device, /close_file, decomposed=1
					!p.multi=0
				endif
    		endif
    	endfor

    	; Smooth the line subtracted spectrum
    	sbin=10
    	if keyword_set(linescan) then sbin=10
    	spec_continuum_smooth,wl,flux_sub,continuum_sub, continuum_sub_error,w1 = min(wl), w2 = max(wl), sbin=sbin,upper=0.9,lower=0.9
    	spec_continuum_smooth,wl,flux,continuum, continuum_error,w1 = min(wl), w2 = max(wl), sbin=sbin,upper=0.9, lower=0.9
    	flat_noise = flux_sub - continuum_sub

    	; Deal with the edge effect that can sabotage the SNR later
    	edge_low = where(wl lt 100 and wl gt max(wl[where(wl lt 100)])-0.5)
    	edge_hi = where(wl gt 100 and wl lt min(wl[where(wl gt 100)])+0.5)
    	flat_noise[edge_low] = flat_noise[edge_low-n_elements(edge_low)]
    	flat_noise[edge_hi] = flat_noise[edge_hi+n_elements(edge_hi)]

    	; Do I want to output the unceratinty with the continuum and flat spectrum?
    	if keyword_set(continuum) then begin
    		openw, sed, outdir+filename+'_continuum.txt', /get_lun
    		printf, sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)';,'Uncertainty (Jy)'
    		print_continuum_sub = continuum_sub*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
    		for k =0, n_elements(wl)-1 do printf, sed, format='(3(g16.6,2x))', wl[k],print_continuum_sub[k];,stdd[k]
    		free_lun, sed
    		close, sed
    	endif
    	if keyword_set(flat) then begin
    		openw, flat_sed, outdir+filename+'_flat_spectrum.txt',/get_lun
    		printf, flat_sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)';,'Uncertainty (Jy)'
    		flat = (flux-continuum_sub)*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
    		; stdd = std*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
    		for k =0, n_elements(wl)-1 do printf, flat_sed, format='(3(g16.6,2x))',wl[k],flat[k];,stdd[k]
    		free_lun, flat_sed
    		close,flat_sed
    	endif
	    openw, noise_sed, outdir+filename+'_residual_spectrum.txt',/get_lun
		printf, noise_sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)';,'Uncertainty (Jy)'
		print_flatnoise = flat_noise*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
		for k =0, n_elements(wl)-1 do printf, noise_sed, format='(3(g16.6,2x))',wl[k],print_flatnoise[k];,stdd[k]
		close,noise_sed

    set_plot, 'ps'
		!p.font = 0
		loadct,12,/silent
		msg = ''
		device, filename = plotdir+'spectrum_line_subtracted_'+filename+msg+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 12, decomposed = 0, /color
		!p.thick=2 & !x.thick=3 & !y.thick=3
		trim1 = where(wl lt 100) & trim2 = where(wl ge 100)
		plot, wl, flux/1e-22, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)',/nodata, position=[0.15,0.1,0.95,0.95]
		if trim1[0] ne -1 then begin
			oplot, wl[trim1], flux[trim1]/1e-22
			; oplot, wl[trim1], flux_sub[trim1]/1e-22, color=200
			oplot, wl[trim1], continuum_sub[trim1]/1e-22, color=100
			oplot, wl[trim1], flat_noise[trim1]/1e-22+min(flux)/1e-22, color=10
		endif
		if trim2[0] ne -1 then begin
			oplot, wl[trim2], flux[trim2]/1e-22
			; oplot, wl[trim2], flux_sub[trim2]/1e-22, color=200
			oplot, wl[trim2], continuum_sub[trim2]/1e-22, color=100
			oplot, wl[trim2], flat_noise[trim2]/1e-22+min(flux)/1e-22, color=10
		endif
		; oplot, wl, continuum/1e-22, color=50
		; al_legend,['Data','lines_subtracted','Data_smooth','(lines_subtracted)_smooth', 'flat/featureless'],textcolors=[0,200,50,100,10],/right
		; al_legend,['Data','lines_subtracted','(lines_subtracted)_smooth', 'flat/featureless'],textcolors=[0,200,100,10],/right
		al_legend,['data','continuum', 'flat/featureless'],textcolors=[0,100,10],/right
		al_legend,[object],textcolors=[0],/left
		device, /close_file, decomposed = 1
		!p.multi = 0

		; Do the same fitting again but using the global noise value
		; Define the name of the output data of fitting results
		openw, secondfit, name+'.txt', /get_lun
		if not keyword_set(current_pix) then begin
			printf, secondfit, format='((a18,2x),16(a18,2x))',$
				'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Blend'
		endif else begin
			printf, secondfit, format='((a18,2x),17(a18,2x))',$
				'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel_No.','Blend'
		endelse

    	for i = 0, n_elements(line_name)-1 do begin
    		if (keyword_set(double_gauss)) and ((where(excluded_line eq line_name[i]))[0] ne -1) then continue
			; select the baseline
			dl = interpol(dl_ins, wl_ins, line_center[i])

			if not keyword_set(localbaseline) then indb = where((wl gt cont[0,i] and wl lt cont[1,i]) or (wl gt cont[2,i] and wl lt cont[3,i]))

			if keyword_set(localbaseline) then begin
				dlb = localbaseline*dl
				wl_diff = wl[1:-1]-wl[0:-2]
				numb = ceil(dlb/(wl_diff[where(wl ge line_center[i])])[0])
				if line_center[i] le 95.08 then begin
					left = where(wl_basepool lt range[0,i] and wl_basepool ge min(wl))
					right = where(wl_basepool gt range[1,i] and wl_basepool le 95.08)
				endif
				if line_center[i] ge 102 then begin
					left = where(wl_basepool lt range[0,i] and wl_basepool ge 102)
					right = where(wl_basepool gt range[1,i] and wl_basepool le max(wl))
				endif
				if n_elements(left) gt numb then left = left[n_elements(left)-1-numb:n_elements(left)-1]
				if n_elements(right) gt numb then right = right[0:numb-1]
				if left[0] ne -1 and right[0] ne -1 then begin
                	wlb = [wl_basepool[left], wl_basepool[right]]
                	fluxb = [flux_basepool[left], flux_basepool[right]]
                	stdb = [std_basepool[left], std_basepool[right]]
					base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]], wl_basepool[right[0]], wl_basepool[right[n_elements(right)-1]]]
				endif
				if left[0] eq -1 and right[0] ne -1 then begin
                	wlb = [wl_basepool[right]]
                	fluxb = [flux_basepool[right]]
                	stdb = [std_basepool[right]]
					base_range = [wl_basepool[right[0]], wl_basepool[right[0]],wl_basepool[right[0]],wl_basepool[right[n_elements(right)-1]]]
				endif
				if left[0] ne -1 and right[0] eq -1 then begin
                	wlb = [wl_basepool[left]]
                	fluxb = [flux_basepool[left]]
                	stdb = [std_basepool[left]]
					base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]]]
				endif

	            indl = where(wl gt base_range[0] and wl lt base_range[3])
				if base_range[0] eq base_range[1] then indl = where(wl gt min(wl) and wl lt base_range[3])
				if base_range[2] eq base_range[3] then indl = where(wl gt base_range[0] and wl lt max(wl))
				wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
			endif
			; Select the line+baseline
			if not keyword_set(localbaseline) then begin
        		if i le 39 then begin
        	    	indl = where(wl gt cont[0,i] and wl lt cont[3,i])
					wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
				endif else begin
        	    	indl = where(wl gt range[0,i]-0.5 and wl lt range[1,i]+0.5)
					wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
				endelse
			endif
			; use the plot_base feature to plot the actual spectrum (with line) here
			plot_base = [[wll],[fluxl]]
			; Fit the baseline and return the baseline parameter in 'base_para'
			fit_line, filename, line_name[i], wlb, fluxb, std=stdb, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, /baseline, outdir=plotdir, no_plot=no_plot, plot_base=plot_base
			; Extract the wave and flux for plottng that is for better visualization of the fitting results.
			ind_plot = where(wl gt base_range[0]-5*dl and wl lt base_range[3]+5*dl)
			plot_wl = wl[ind_plot] & plot_flux = flux[ind_plot] & plot_std = std[ind_plot]
			plot_base = [[wlb],[fluxb]]
			; Substract the baseline from the spectrum
			; First, calculate the baseline
			; base = base_para[0]*wll +base_para[1]                       ;use 1st order polynomial
			base = base_para[0]*wll^2+base_para[1]*wll+base_para[2]      ;use 2nd order polynomial
			; Subtract
			fluxx = fluxl - base
			stdd =  stdl
			line = [line_center[i],range[0,i],range[1,i]]                      ;[line_center, line profile lower limit, line profile upper limit]

			; Calculate the noise level at the line using the flat noise spectrum
			limit_low = max([min(wl), range[0,i]-global_noise*dl]) & limit_hi = min([max(wl), range[1,i]+global_noise*dl])
			ind_n = where(wl gt limit_low and wl lt limit_hi)
			wl_n = wl[ind_n] & flux_n = flat_noise[ind_n] & std_n = std[ind_n]
			flat_noise_smooth = [[wl_n],[flux_n],[std_n]]

			;
			; Fitting part
			if keyword_set(fixed_width) and keyword_set(opt_width) then begin
        		if line_name[i] eq 'OI3P1-3P2'then begin
        			if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot,b3a=b3a
				    if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
										       /single_gauss,outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot,b3a=b3a
			    endif else begin
				    if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a
				    if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
										       /single_gauss,outdir=plotdir, noiselevel=noiselevel, /fixed_width, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot,b3a=b3a
			    endelse
			endif else if keyword_set(fixed_width) and (not keyword_set(opt_width)) then begin
					if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a
				    if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
										       /single_gauss,outdir=plotdir, noiselevel=noiselevel, /fixed_width, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot,b3a=b3a
			endif else begin
        		if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        											/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot
				if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
													/single_gauss,outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot
			endelse

			; A third fitting right after the noise being well-estimated.
			; Use the feedback keyword to feed in the noise level at certain wavelength and treat it as the local noise level.
			feedback = noise + fluxx*0

			if keyword_set(fixed_width) and keyword_set(opt_width) then begin
        		if line_name[i] eq 'OI3P1-3P2'then begin
        			if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
				    if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
										       /single_gauss,outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
			    endif else begin
				    if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
				    if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
										       /single_gauss,outdir=plotdir, noiselevel=noiselevel, /fixed_width, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
			    endelse
			endif else if keyword_set(fixed_width) and (not keyword_set(opt_width)) then begin
					if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        										/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, /fixed_width, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
				    if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
										       /single_gauss,outdir=plotdir, noiselevel=noiselevel, /fixed_width, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot,b3a=b3a, feedback=feedback
			endif else begin
        		if keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
        											/single_gauss, /test, outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot, feedback=feedback
				if not keyword_set(test) then fit_line, filename, line_name[i], wll, fluxx, std=stdd, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, line, noise, plot_base=plot_base,$
													/single_gauss,outdir=plotdir, noiselevel=noiselevel, global_noise=flat_noise_smooth, base_range=base_range, no_plot=no_plot, feedback=feedback
			endelse

			; Print the fittng result into text file

        	if status le 0 then begin
				printf, secondfit, format = '((a18,2X),(a50))', line_name[i], errmsg
			endif else begin
            	; The read_line_ref procedure read the g, A, E_u from another file
            	read_line_ref, line_name[i], E_u, A, g
				base_str = interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl)
            	if not keyword_set(ra) then ra = 0
            	if not keyword_set(dec) then dec = 0
				if (keyword_set(current_pix)) and ~(string(current_pix) eq 'c') then begin
            		ra = interpol(ra_tot, wl_coord, line_center[i])
					dec = interpol(dec_tot, wl_coord, line_center[i])
				endif
				; Blended lines classification
				blue_blend = 0 & red_blend = 0
				if i eq 0 then begin
            		if line_center[i+1]-cen_wl lt fwhm then red_blend = 1
				endif
				if i ne 0 and i ne n_elements(line_center)-1 then begin
            		if cen_wl-line_center[i-1] lt fwhm then blue_blend = 2
					if line_center[i+1]-cen_wl lt fwhm then red_blend  = 1
				endif
				if i eq n_elements(line_center)-1 then begin
            		if cen_wl-line_center[i-1] lt fwhm then blue_blend = 2
				endif
				blend_flag = red_blend+blue_blend
            	if blend_flag eq 0 then blend_msg = 'x'
				if blend_flag eq 1 then blend_msg = 'Red'
				if blend_flag eq 2 then begin
            		blend_msg = 'Blue'
					blend_flag = 3
				endif
				if blend_flag eq 3 then begin
            		blend_msg = 'Red/Blue'
					blend_flag = 2
				endif
				; blend flag = 0: no blend; blend_flag = 1: Red blend; blend_flag = 2: Red/Blue blend; blend_flag = 3: Blue blend.
				;
				; Throw away the bogus results due to the missing segment in the spectrum
				if finite(snr,/nan) eq 1 then continue
				if not keyword_set(current_pix) then begin
					printf, secondfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),(a18,2x))',$
            			line_name[i], line_center[i], cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, E_u, A, g, ra, dec, blend_msg
				endif else begin
					printf, secondfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),2(a18,2x))',$
            			line_name[i], line_center[i], cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_str, noise, snr, E_u, A, g, ra, dec, current_pix, blend_msg
				endelse
			endelse
		endfor
		; Double Gaussian fit
		if keyword_set(double_gauss) then begin
			for i = 0, n_elements(line_center_dg)/2-1 do begin
				mean_wl = (line_center_dg[2*i]+line_center_dg[2*i+1])/2
				if (min(wl) gt mean_wl) or (max(wl) lt mean_wl) then continue
				dlb = localbaseline*dl
				wl_diff = wl[1:-1]-wl[0:-2]
				numb = ceil(dlb/(wl_diff[where(wl ge line_center_dg[2*i])])[0])
				left = where(wl_basepool lt range_dg[0,i] and wl_basepool ge min(wl)) & right = where(wl_basepool gt range_dg[1,i] and wl_basepool le max(wl))
				if n_elements(left) gt numb then left = left[n_elements(left)-1-numb:n_elements(left)-1]
				if n_elements(right) gt numb then right = right[0:numb-1]
				if left[0] ne -1 and right[0] ne -1 then begin
            		wlb = [wl_basepool[left], wl_basepool[right]]
            		fluxb = [flux_basepool[left], flux_basepool[right]]
            		stdb = [std_basepool[left], std_basepool[right]]
					base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]], wl_basepool[right[0]], wl_basepool[right[n_elements(right)-1]]]
					indl = where(wl gt base_range[0] and wl lt base_range[3])
					wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
				endif
				if left[0] eq -1 and right[0] ne -1 then begin
                	wlb = [wl_basepool[right]]
                	fluxb = [flux_basepool[right]]
                	stdb = [std_basepool[right]]
					base_range = [wl_basepool[right[0]], wl_basepool[right[0]],wl_basepool[right[0]],wl_basepool[right[n_elements(right)-1]]]
					indl = where(wl gt min(wl) and wl lt base_range[2])
					wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
				endif
				if left[0] ne -1 and right[0] eq -1 then begin
                	wlb = [wl_basepool[left]]
                	fluxb = [flux_basepool[left]]
                	stdb = [std_basepool[left]]
					base_range = [wl_basepool[left[0]], wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]],wl_basepool[left[n_elements(left)-1]]]
					indl = where(wl gt base_range[0] and wl lt max(wl))
					wll = wl[indl] & fluxl = flux[indl] & stdl = std[indl]
				endif

				; use the plot_base feature to plot the actual spectrum (with line) here
				plot_base = [[wll],[fluxl]]
				fit_line, filename, line_name_dg[2*i]+'+'+line_name_dg[2*i+1], wlb, fluxb, std=stdb, status, errmsg, cen_wl, sig_cen_wl, str, sig_str, fwhm, sig_fwhm, base_para, snr, /baseline, outdir=plotdir,no_plot=no_plot, plot_base=plot_base
				; extract the wave and flux for plottng that is for better visualization of the fitting results.
				ind_plot = where(wl gt base_range[0]-5*dl and wl lt base_range[3]+5*dl)
				plot_wl = wl[ind_plot] & plot_flux = flux[ind_plot] & plot_std = std[ind_plot]
				plot_base = [[wlb],[fluxb]]
				; Calculate the gloe noise spectrum
				limit_low = max([min(wl), range_dg[0,i]-global_noise*dl]) & limit_hi = min([max(wl), range_dg[1,i]+global_noise*dl])
				ind_n = where(wl gt limit_low and wl lt limit_hi)
				wl_n = wl[ind_n] & flux_n = flat_noise[ind_n] & std_n = std[ind_n]
				flat_noise_smooth = [[wl_n],[flux_n],[std_n]]
				; Subtract the baseline from the spectrum
				; First, calculate the baseline
				; base = base_para[0]*wll +base_para[1]                       ;use 1st order polynomial
				base = base_para[0]*wll^2+base_para[1]*wll+base_para[2]      ;use 2nd order polynomial
				; Subtract
				fluxx = fluxl - base
				stdd = stdl
				line = [line_dg[*,2*i],line_dg[*,2*i+1]]
				; Fitting part
				; Different fitting keyword for fixed width and test arguement
				fit_line,filename,line_name_dg[2*i]+'+'+line_name_dg[2*i+1],wll,fluxx,std=stdd,status,errmsg,cen_wl,sig_cen_wl,str,sig_str,fwhm,sig_fwhm,base_para,snr,line,noise,/double_gauss,outdir=plotdir,$
					 noiselevel=noiselevel,base_range=base_range,plot_base=plot_base,global_noise=flat_noise_smooth,b3a=b3a,/fix_dg,/fixed_width

				; A third fitting to take the well-estimated noise as the error of the data into the fitting routine to get the best estimation of the unceratinty of the fitted parameters
				feedback = noise + fluxx*0
				fit_line,filename,line_name_dg[2*i]+'+'+line_name_dg[2*i+1],wll,fluxx,std=stdd,status,errmsg,cen_wl,sig_cen_wl,str,sig_str,fwhm,sig_fwhm,base_para,snr,line,noise,/double_gauss,outdir=plotdir,$
					 noiselevel=noiselevel,base_range=base_range,plot_base=plot_base,global_noise=flat_noise_smooth,b3a=b3a,/fix_dg,/fixed_width,feedback=feedback

				if status eq 0 then begin
					printf, secondfit, format = '((a18,2X),(a50))', line_name_dg[2*i]+'_'+line_name_dg[2*i+1], errmsg
				endif else begin
					; Making sure the line classification is correct
					i1 = where(line_name eq line_name_dg[2*i])
					i2 = where(line_name eq line_name_dg[2*i+1])
					if (abs(line_center[i1]-cen_wl[0]) gt abs(line_center[i1]-cen_wl[1])) and (abs(line_center[i2]-cen_wl[1]) gt abs(line_center[i2]-cen_wl[0])) then begin
						print, 'Line misplacement found in '+line_name_dg[2*i]+'+'+line_name_dg[2*i+1]
						cen_wl = reverse(cen_wl)
						sig_cen_wl = reverse(sig_cen_wl)
						str = reverse(str)
						sig_str = reverse(sig_str)
						fwhm = reverse(fwhm)
						sig_fwhm = reverse(sig_fwhm)
						snr = reverse(snr)
					endif
					read_line_ref, line_name_dg[2*i], E_u1, A1, g1
					read_line_ref, line_name_dg[2*i+1], E_u2, A2, g2
					if (keyword_set(current_pix)) and ~(string(current_pix) eq 'c') then begin
						ra = interpol(ra_tot, wl_coord, line[0])
						dec = interpol(dec_tot, wl_coord, line[0])
					endif
					E_u = [E_u1,E_u2]
					A = [A1,A2]
					g = [g1,g2]
					base_str = [interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl[0]), $
								interpol(base[where((wl[indl] le median(wl[indl])+10) and (wl[indl] ge median(wl[indl])-10))], wll, cen_wl[1])]
					blend_msg = 'x'
					; Throw away the bogus results due to the missing segment in the spectrum
					if (finite(snr,/nan))[0] eq 1 then continue
					if not keyword_set(current_pix) then begin
						printf, secondfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),(a18,2x))',$
							line_name_dg[2*i], line[0], cen_wl[0], sig_cen_wl[0], str[0], sig_str[0], fwhm[0], sig_fwhm[0], base_str[0],noise,snr[0], E_u[0], A[0], g[0], ra, dec, blend_msg
						printf, secondfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),(a18,2x))',$
							line_name_dg[2*i+1], line[3], cen_wl[1], sig_cen_wl[1], str[1], sig_str[1], fwhm[1], sig_fwhm[1], base_str[1],noise,snr[1], E_u[1], A[1], g[1], ra, dec, blend_msg
					endif else begin
						printf, secondfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),2(a18,2x))',$
							line_name_dg[2*i], line[0], cen_wl[0], sig_cen_wl[0], str[0], sig_str[0], fwhm[0], sig_fwhm[0], base_str[0],noise,snr[0], E_u[0], A[0], g[0], ra, dec, current_pix, blend_msg
						printf, secondfit, format = '((a18,2X),10(g18.10,2X),2(g18.10,2X),(i18,2x),2(g18.10,2X),2(a18,2x))',$
							line_name_dg[2*i+1], line[3], cen_wl[1], sig_cen_wl[1], str[1], sig_str[1], fwhm[1], sig_fwhm[1], base_str[1],noise,snr[1], E_u[1], A[1], g[1], ra, dec, current_pix, blend_msg
					endelse
				endelse
			endfor
		endif
		free_lun, secondfit
    	close, secondfit
    	; Identify the blended lines
		if not keyword_set(current_pix) then begin
			readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,I,D,D,A', $
				line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, blend_flag_n, /silent, skipline=1
		endif else begin
			readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,I,D,D,A,A', $
				line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, pix_n, blend_flag_n, /silent, skipline=1
		endelse

		blend_subgroup = []
		blend_msg_all = []
		possible_all = []
		for line = 0, n_elements(line_name_n)-1 do begin
			if (keyword_set(double_gauss)) and ((where(line_name_dg eq line_name_n[line]))[0] ne -1) then begin
				blend_msg = 'DoubleGaussian'
				blend_msg_all = [blend_msg_all,blend_msg]
			continue
			endif
			; Blended lines classification
			blue_blend = 0 & red_blend = 0
			if line eq 0 then begin
				if abs(cen_wl_n[line+1]-cen_wl_n[line]) lt fwhm_n[line] then red_blend = 1
			endif
			if line ne 0 and line ne n_elements(line_name_n)-1 then begin
            	if abs(cen_wl_n[line]-cen_wl_n[line-1]) lt fwhm_n[line] then blue_blend = 2
				if abs(cen_wl_n[line+1]-cen_wl_n[line]) lt fwhm_n[line] then red_blend  = 1
			endif
			if line eq n_elements(line_name_n)-1 then begin
				if abs(cen_wl_n[line]-cen_wl_n[line-1]) lt fwhm_n[line] then blue_blend = 2
			endif
			blend_flag = red_blend+blue_blend
			if blend_flag eq 0 then blend_msg = 'x'
			if blend_flag eq 1 then blend_msg = 'Red'
			if blend_flag eq 2 then begin
				blend_msg = 'Blue'
				blend_flag = 3
			endif
			if blend_flag eq 3 then begin
            	blend_msg = 'Red/Blue'
				blend_flag = 2
			endif
			blend_msg_all = [blend_msg_all,blend_msg]
			if n_elements(blend_subgroup) eq 0 then group_flag = 0
			if blend_flag ge group_flag then begin
				if blend_flag eq 0 then continue
				blend_subgroup = [[blend_subgroup],[line_name_n[line],string(E_u_n[line])]]
				group_flag = blend_flag
			endif else begin
				possible_line = blend_subgroup[0,where(float(blend_subgroup[1,*]) eq min(float(blend_subgroup[1,*])))]
				if n_elements(possible_line) gt 1 then begin
					A_dum = A_n[where(line_name_n eq possible_line)]
					possible_line = possible_line[(where(line_name_n eq possible_line))[where(A_dum eq max(A_dum))]]
				endif
				blend_subgroup = []
				possible_all = [possible_all, possible_line]
				if blend_flag ne 0 then begin
					blend_subgroup = [[blend_subgroup],[line_name_n[line],string(E_u_n[line])]]
					group_flag = blend_flag
				endif
			endelse
		endfor
		openw, secondfit, name+'.txt', /get_lun
		if not keyword_set(current_pix) then begin
			printf, secondfit, format='((a18,2x),17(a18,2x))', $
    			'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Blend','Validity'
		endif else begin
			printf, secondfit, format='((a18,2x),18(a18,2x))', $
    			'Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','Noise(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)','Pixel_No.','Blend','Validity'
		endelse
		for line = 0, n_elements(line_name_n)-1 do begin
    		lowest = '0'
			if (where(possible_all eq line_name_n[line]))[0] ne -1 then lowest = '1'
			if (blend_msg_all[line] eq 'x') or (blend_msg_all[line] eq 'DoubleGaussian') then lowest = '1'
			if finite(snr_n[line],/nan) eq 1 then lowest = '0'
			; Reason for sig_str is that some sources have very poor spectra like EC82.  It will fit on the edge
			if (sig_cen_wl_n[line] eq -999) or (sig_fwhm_n[line] eq -999) or (sig_str_n[line] eq -999)then lowest = '0'
			if not keyword_set(current_pix) then begin
				printf, secondfit, format = '( (a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),2(a18,2x) )',$
            		line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line], noise_n[line], snr_n[line],$
					E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], blend_msg_all[line], lowest
				if keyword_set(print_all) then begin
            		openw, gff, print_all+'.txt',/append,/get_lun
					printf, gff, format = '( 2(a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),2(a18,2x) )',$
            			object, line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line], noise_n[line], snr_n[line],$
						E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], blend_msg_all[line], lowest
					free_lun, gff
					close, gff
					; ASCII file that has everything
					openw, all, file_dirname(print_all+'.txt')+'/CDF_archive_lines.txt', /append, /get_lun
					printf, all, format = '( 2(a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),3(a18,2x) )',$
            			object, line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line], noise_n[line], snr_n[line],$
						E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], 'c', blend_msg_all[line], lowest
					free_lun, all
					close, all
				endif
			endif else begin
				printf, secondfit, format = '( (a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),3(a18,2x) )',$
            		line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line], noise_n[line], snr_n[line],$
					E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], pix_n[line], blend_msg_all[line], lowest
				if keyword_set(print_all) then begin
            		openw, gff, print_all+'.txt',/append,/get_lun
					printf, gff, format = '( 2(a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),3(a18,2x) )',$
            			object, line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line], noise_n[line], snr_n[line],$
						E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], pix_n[line], blend_msg_all[line], lowest
					free_lun, gff
					close, gff
					; ASCII file that has everything
					openw, all, file_dirname(print_all+'.txt')+'/CDF_archive_lines.txt', /append, /get_lun
					printf, all, format = '( 2(a18,2x),2(f18.5,2x),(f18.5,2x),2(e18.6,2x),2(f18.5,2x),2(e18.6,2x),(f18.6,2x),(f18.4,2x),(e18.5,2x),(i18,2x),2(f18.7,2x),3(a18,2x) )',$
            			object, line_name_n[line], lab_wl_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line], noise_n[line], snr_n[line],$
						E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line], pix_n[line], blend_msg_all[line], lowest
					free_lun, all
					close, all
				endif
			endelse
		endfor
		free_lun, secondfit
		close, secondfit

		; Calculate the line subtracted spectrum again
		if not keyword_set(current_pix) then begin
			readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,I,D,D,A,I',$
				line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, blend_flag_n, lowest_E_n, /silent
		endif else begin
			readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,D,I,D,D,A,A,I',$
				line_name_n, lab_wl_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, noise_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n, pix_n, blend_flag_n, lowest_E_n, /silent
		endelse

		flux_sub = flux
		for line = 0, n_elements(line_name_n)-1 do begin
			if snr_n[line] ge noiselevel then begin
				if lowest_E_n[line] ne 1 then continue
				ind = where((wl gt cen_wl_n[line]-5*fwhm_n[line]) and (wl lt cen_wl_n[line]+5*fwhm_n[line]))
				wl_n = wl[ind]
				line_profile = gauss(wl_n, [2.354*str_n[line]/fwhm_n[line]/(2*!PI)^0.5, cen_wl_n[line], fwhm_n[line]/2.354]);+base_str[line]
				flux_sub[ind] = flux_sub[ind] - line_profile
				if keyword_set(plot_subtraction) then begin
					set_plot,'ps'
					!p.font=0
					loadct,12,/silent
					device, filename=plotdir+'line_subtracted_'+filename+'_'+line_name_n[line]+'.eps',/helvetica,/portrait,/encapsulated,isolatin=1,font_size=12,decomposed=0,/color
					!p.thick=3 & !x.thick=3 & !y.thick=3
    				plot, wl_n, flux[ind], psym=10, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)', position=[0.15,0.1,0.95,0.95], $
    					yrange=[0.9*min([flux[ind],line_profile+base_str_n[line],flux_sub[line]]),1.1*max([flux[ind],line_profile+base_str_n[line],flux_sub[line]])]
					oplot, wl_n, (line_profile+base_str_n[line])/1e-22, color=120, psym=10 ;purple
					oplot, wl_n, flux_sub[ind]/1e-22, color=200, psym=10 ;red
					al_legend, ['Data','Line+Baseline Fit','Subtraction'], textcolors=[0,120,200], /right
					device, /close_file, decomposed=1
					!p.multi=0
				endif
			endif
		endfor
		; Smooth the line subtracted spectrum
		sbin=10
		spec_continuum_smooth,wl, flux_sub, continuum_sub, continuum_sub_error,w1 = min(wl), w2 = max(wl), sbin=sbin,upper=0.9,lower=0.9
		flat_noise = flux_sub - continuum_sub

    	; Deal with the edge effect that can sabotage the SNR later
    	edge_low = where(wl lt 100 and wl gt max(wl[where(wl lt 100)])-0.5)
    	edge_hi = where(wl gt 100 and wl lt min(wl[where(wl gt 100)])+0.5)
    	flat_noise[edge_low] = flat_noise[edge_low-n_elements(edge_low)]
    	flat_noise[edge_hi] = flat_noise[edge_hi+n_elements(edge_hi)]

		if keyword_set(continuum) then begin
    		openw, sed, outdir+filename+'_continuum.txt', /get_lun
    		printf, sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)';,'Uncertainty (Jy)'
    		print_continuum_sub = continuum_sub*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
    		for k =0, n_elements(wl)-1 do printf, sed, format='(3(g16.6,2x))', wl[k],print_continuum_sub[k];,stdd[k]
    		free_lun, sed
    		close, sed
    	endif
    	if keyword_set(flat) then begin
    		openw, flat_sed, outdir+filename+'_flat_spectrum.txt',/get_lun
    		printf, flat_sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)';,'Uncertainty (Jy)'
    		flat = (flux-continuum_sub) *1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
    		for k =0, n_elements(wl)-1 do printf, flat_sed, format='(3(g16.6,2x))',wl[k],flat[k];,stdd[k]
    		free_lun, flat_sed
    		close,flat_sed
    	endif
		openw, noise_sed, outdir+filename+'_residual_spectrum.txt',/get_lun
		printf, noise_sed, format='(2(a16,2x))','Wavelength(um)','Flux_Density(Jy)';,'Uncertainty (Jy)'
		print_flatnoise = flat_noise *1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
		; stdd = std*1e4*(wl*1e-4)^2/c/1e2*1e7/1e-23
		for k =0, n_elements(wl)-1 do printf, noise_sed, format='(3(g16.6,2x))',wl[k],print_flatnoise[k];,stdd[k]
		free_lun, noise_sed
		close,noise_sed

		; Plot the results
		set_plot, 'ps'
		!p.font = 0
		loadct,12,/silent
		msg = ''
		device, filename = plotdir+'spectrum_line_subtracted_'+filename+msg+'.eps', /helvetica, /portrait, /encapsulated, isolatin = 1, font_size = 12, decomposed = 0, /color
		!p.thick=2 & !x.thick=3 & !y.thick=3
		trim1 = where(wl lt 100) & trim2 = where(wl ge 100)
		plot, wl, flux/1e-22, xtitle = '!3Wavelength (!9m!3m)', ytitle = '!3Flux Density (10!u-22!n W/cm!u2!n/!9m!3m)',ystyle=2, /nodata, position=[0.15,0.1,0.95,0.95]
		if trim1[0] ne -1 then begin
			oplot, wl[trim1], flux[trim1]/1e-22
			oplot, wl[trim1], continuum_sub[trim1]/1e-22, color=100
			oplot, wl[trim1], flat_noise[trim1]/1e-22 + min(flux)/1e-22, color=10
		endif
		if trim2[0] ne -1 then begin
			oplot, wl[trim2], flux[trim2]/1e-22
			oplot, wl[trim2], continuum_sub[trim2]/1e-22, color=100
			oplot, wl[trim2], flat_noise[trim2]/1e-22 + min(flux)/1e-22, color=10
		endif
		;al_legend,['Data','lines_subtracted','(lines_subtracted)_smooth', 'flat/featureless'],textcolors=[0,200,100,10],/right
		al_legend,['data','continuum', 'flat/featureless'],textcolors=[0,100,10],/right
		al_legend,[object],textcolors= [0],/left
		device, /close_file, decomposed = 1
		!p.multi = 0

	endif
end


pro extract_pacs_linescan, indir=indir, aor_name=aor_name, slice=slice, outdir=outdir, plotdir=plotdir, pospath=pospath, noiselevel=noiselevel, test=test, ra=ra, dec=dec,$
localbaseline=localbaseline,global_noise=global_noise,fixed_width=fixed_width,linescan=linescan
file_mkdir, outdir
file_mkdir, plotdir
band = ['blue','blue','red','red']
reduction = ['_central9Spaxels_PointSourceCorrected_slice_0','_centralSpaxel_PointSourceCorrected_Corrected3x3NO_slice_0','_centralSpaxel_PointSourceCorrected_Corrected3x3YES_slice_0']
reduction = ['_sl']
openw, lun, 'linescan_TMC1_v13os4_norm_summed_5x5.txt', /get_lun
printf, lun, format='(15(a16,2x))','Line','LabWL(um)','ObsWL(um)','Sig_Cen(um)','Str(W/cm2)','Sig_str(W/cm2)','FWHM(um)','Sig_FWHM(um)','Base(W/cm2/um)','SNR','E_u(K)','A(s-1)','g','RA(deg)','Dec(deg)'
free_lun, lun
close, lun
for rec = 0, n_elements(reduction)-1 do begin
	for iband = 0, n_elements(band)-1 do begin
		for i_slice = 0, slice[iband] do begin
			filename = 'linescan_' + aor_name[iband] +'v13os4_'+ band[iband] +'norm'+ reduction[rec] + strtrim(string(i_slice),1) + '_summed_5x5'; + '_os7sf3'
			print, filename
			extract_pacs, indir=indir, filename=filename, outdir=outdir, plotdir=plotdir, noiselevel=3, test=test, ra=ra, dec=dec, localbaseline=localbaseline, linescan=linescan, global_noise=global_noise, fixed_width=fixed_width,/opt_width
			name = outdir+filename+'_lines'
			if keyword_set(linescan) then name = name+'_LS'
			if file_test(name+'.txt') eq 1 then begin
				readcol, name+'.txt', format='A,D,D,D,D,D,D,D,D,D,D,D,I,D,D', line_name_n, line_center_n, cen_wl_n, sig_cen_wl_n, str_n, sig_str_n, fwhm_n, sig_fwhm_n, base_str_n, snr_n, E_u_n, A_n, g_n, ra_n, dec_n,/silent
				openw, lun, outdir+'linescan_TMC1_v13os4_norm_summed_5x5.txt', /get_lun, /append
				for line = 0, n_elements(line_name_n)-1 do printf, lun, format = '((a16,2X),9(g16.10,2X),2(g16.10,2X),(i16,2x),2(g16.10,2X))',$
					line_name_n[line], line_center_n[line], cen_wl_n[line], sig_cen_wl_n[line], str_n[line], sig_str_n[line], fwhm_n[line], sig_fwhm_n[line], base_str_n[line],snr_n[line], $
					E_u_n[line], A_n[line], g_n[line], ra_n[line], dec_n[line]
				free_lun, lun
				close, lun
			endif
		endfor
	endfor
endfor
end
