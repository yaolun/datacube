def cdfPacs1d(obsid, datadir, outdir, objname, aper_size=31.8, suffix='hsa',
              auto_match=False, threshold=0.05, aper_step=10, max_iter=20, print_all_path=0):
    """
    obsid  = [obsid1, obsid2]
    outdir: The output directory for the source.  e.g. /CDF_archive/BHR71/
    suffix: 'hsa' for data directly acquired from HSA.  Should probably get rid of it in the end.
            But now it distinguishes the recent results from old CDF reduction.
    """
    import numpy as np
    # to avoid X server error
    import matplotlib as mpl
    mpl.use('Agg')
    from astropy.io import ascii, fits
    import matplotlib.pyplot as plt
    import sys
    import os
    sys.path.append(os.path.expanduser('~')+'/programs/spectra_analysis/')
    sys.path.append(os.path.expanduser('~')+'/programs/misc/')
    from pacs_weight import pacs_weight
    from PacsSpire_SpecMatch import PacsSpire_SpecMatch

    # get the cubefiles
    cubefile = [datadir+obsid[0]+'/herschel.pacs.signal.PacsRebinnedCube/hpacs'+obsid[0]+'_20hps3drbs_00.fits',
                datadir+obsid[0]+'/herschel.pacs.signal.PacsRebinnedCube/hpacs'+obsid[0]+'_20hps3drrs_00.fits',
                datadir+obsid[1]+'/herschel.pacs.signal.PacsRebinnedCube/hpacs'+obsid[1]+'_20hps3drbs_00.fits',
                datadir+obsid[1]+'/herschel.pacs.signal.PacsRebinnedCube/hpacs'+obsid[1]+'_20hps3drrs_00.fits']

    # extract the cube file
    # the main purpose is getting the coordinates, which can be done in python as well
    import pidly
    if 'bettyjo' in os.path.expanduser('~'):
        # bettyjo
        idl = pidly.IDL('/opt/local/exelis/idl83/bin/idl')
    else:
        # grad13yy
        idl = pidly.IDL('/Applications/exelis/idl83/bin/idl')

    idl('.r '+os.path.expanduser('~')+'/programs/line_fitting/get_pacs.pro')
    idl.pro('get_pacs', outdir=outdir+'pacs/data/', objname=objname, filename=cubefile,
            suffix=suffix, separate=1)

    wl = np.array([])
    flux = np.array([])
    for cube in cubefile:
        hdu_dum = fits.open(cube)
        wl_min = hdu_dum[8].data.min()
        if wl_min < 60.:
            band = 'b2a'
        elif (wl_min > 60.) & (wl_min < 100):
            band = 'b2b'
        elif (wl_min > 100) & (wl_min < 130):
            band = 'r1s'
        elif wl_min > 130.:
            band = 'r1l'
        wl_dum, flux_dum = pacs_weight(outdir+'pacs/data/cube/', objname, aper_size,
                                       outdir+'pacs/data/', cube, suffix=suffix+'_'+band)

        if band == 'b2a':
            trimmer = (wl_dum >= 54.8) & (wl_dum < 72.3)
        elif band == 'b2b':
            trimmer = (wl_dum >= 72.3) & (wl_dum < 95.05)
        elif band == 'r1s':
            trimmer = (wl_dum >= 103) & (wl_dum < 143)
        elif band == 'r1l':
            trimmer = (wl_dum >= 143) & (wl_dum < 190.31)

        wl = np.hstack((wl, wl_dum[trimmer]))
        flux = np.hstack((flux, flux_dum[trimmer]))
    sorter = np.argsort(wl)
    wl = wl[sorter]
    flux = flux[sorter]

    # write out
    foo = open(outdir+'pacs/data/'+objname+'_pacs_weighted.txt','w')
    foo.write('{} \t {}\n'.format('Wavelength(um)', 'Flux_Density(Jy)'))
    for i in range(len(wl)):
        if flux[i] != 0:
            foo.write('{} \t {}\n'.format(wl[i], flux[i]))
    foo.close()

    # compare the mismatch between PACS and SPIRE
    if auto_match:
        if not os.path.exists(outdir+'/spire/data/'+objname+'_spire_corrected.txt'):
            spire_path = raw_input('Where does the spire corrected spectrum located?')
        else:
            spire_path = outdir+'spire/data/'+objname+'_spire_corrected.txt'
        spire = ascii.read(spire_path)
        pacs = ascii.read(outdir+'pacs/data/'+objname+'_pacs_weighted.txt')
        current_status = PacsSpire_SpecMatch(pacs, spire, threshold)
        print(current_status)

        used_aperture = [aper_size]

        iter_num = 0
        while current_status != 0:
            print('iteration ', iter_num)
            # check if it is a u-turn in aperture size
            if len(used_aperture) > 1:
                if previous_status*current_status < 0:
                    aper_step = aper_step/2
            # store the comparison result for next iteration
            previous_status = PacsSpire_SpecMatch(pacs, spire, threshold)

            aper_size = aper_size + previous_status*aper_step
            used_aperture.append(aper_size)

            # routine for calculating weighted spectrum
            wl = np.array([])
            flux = np.array([])
            for cube in cubefile:
                hdu_dum = fits.open(cube)
                wl_min = hdu_dum[8].data.min()
                if wl_min < 60.:
                    band = 'b2a'
                elif (wl_min > 60.) & (wl_min < 100):
                    band = 'b2b'
                elif (wl_min > 100) & (wl_min < 130):
                    band = 'r1s'
                elif wl_min > 130.:
                    band = 'r1l'
                wl_dum, flux_dum = pacs_weight(outdir+'pacs/data/cube/', objname, aper_size,
                                               outdir+'pacs/data/', cube, suffix=suffix+'_'+band)

                if band == 'b2a':
                    trimmer = (wl_dum >= 54.8) & (wl_dum < 72.3)
                elif band == 'b2b':
                    trimmer = (wl_dum >= 72.3) & (wl_dum < 95.05)
                elif band == 'r1s':
                    trimmer = (wl_dum >= 103) & (wl_dum < 143)
                elif band == 'r1l':
                    trimmer = (wl_dum >= 143) & (wl_dum < 190.31)

                wl = np.hstack((wl, wl_dum[trimmer]))
                flux = np.hstack((flux, flux_dum[trimmer]))
            sorter = np.argsort(wl)
            wl = wl[sorter]
            flux = flux[sorter]

            # write out
            foo = open(outdir+'pacs/data/'+objname+'_pacs_weighted.txt','w')
            foo.write('{} \t {}\n'.format('Wavelength(um)', 'Flux_Density(Jy)'))
            for i in range(len(wl)):
                if flux[i] != 0:
                    foo.write('{} \t {}\n'.format(wl[i], flux[i]))
            foo.close()

            spire = ascii.read(spire_path)
            pacs = ascii.read(outdir+'pacs/data/'+objname+'_pacs_weighted.txt')
            current_status = PacsSpire_SpecMatch(pacs, spire, threshold)
            iter_num += 1
            if iter_num == max_iter:
                print('Maximum iterations reached.')
                break

        print(used_aperture)

    # make an overall plot of spectrum
    # need to incorporate with photometry in the near future
    wl = wl[flux != 0]
    flux = flux[flux != 0]

    fig = plt.figure(figsize=(8,6))
    ax = fig.add_subplot(111)

    e1 = (wl < 72.3)
    e2 = ((wl >= 72.3) & (wl < 95.05))
    e3 = ((wl >= 103) & (wl < 143))
    e4 = ((wl >= 143) & (wl < 190.31))

    spec, = ax.plot(wl[e1], flux[e1], color='b')
    ax.plot(wl[e2], flux[e2], color='b')
    ax.plot(wl[e3], flux[e3], color='b')
    ax.plot(wl[e4], flux[e4], color='b')

    ax.set_xlabel(r'$\rm{Wavelength\,[\mu m]}$', fontsize=18)
    ax.set_ylabel(r'$\rm{Flux\,Density\,[Jy]}$', fontsize=18)
    [ax.spines[axis].set_linewidth(1.5) for axis in ['top','bottom','left','right']]
    ax.minorticks_on()
    ax.tick_params('both',labelsize=18,width=1.5,which='major',pad=10,length=5)
    ax.tick_params('both',labelsize=18,width=1.5,which='minor',pad=10,length=2.5)

    # fix the tick label font
    ticks_font = mpl.font_manager.FontProperties(family='STIXGeneral',size=18)
    for label in ax.get_xticklabels():
        label.set_fontproperties(ticks_font)
    for label in ax.get_yticklabels():
        label.set_fontproperties(ticks_font)

    fig.savefig(outdir+'pacs/data/'+objname+'_pacs_weighted.pdf', format='pdf', dpi=300, bbox_inches='tight')
    fig.clf()

    # line fitting
    idl('.r '+os.path.expanduser('~')+'/programs/line_fitting/extract_pacs.pro')
    idl('.r '+os.path.expanduser('~')+'/programs/line_fitting/gauss.pro')
    # fit the cube
    # first, load the coordinate file
    for i in range(1,26):
        coord_dum = ascii.read(outdir+'pacs/data/cube/'+objname+'_pacs_pixel'+str(i)+'_'+suffix+'_coord.txt')
        ra_dum = np.mean(coord_dum['RA(deg)'])
        dec_dum = np.mean(coord_dum['Dec(deg)'])
        idl.pro('extract_pacs', indir=outdir+'pacs/data/cube/', filename=objname+'_pacs_pixel'+str(i)+'_'+suffix,
                outdir=outdir+'pacs/advanced_products/cube/', plotdir=outdir+'pacs/advanced_products/cube/plots/',
                noiselevel=3, ra=ra_dum, dec=dec_dum, global_noise=20, localbaseline=10, opt_width=1, current_pix=str(i),
                continuum=1, flat=1, object=objname, double_gauss=1, fixed_width=1, print_all=print_all_path)

    # make contour plots
    idl.pro('plot_contour', noise=3, indir=outdir+'/pacs/advanced_products/cube/',
            plotdir=outdir+'/pacs/advanced_products/contours/', objname=objname,
            pacs=1, brightness=1)


    # fit the 1-D weighted spectrum
    coord = ascii.read(outdir+'pacs/data/cube/'+objname+'_pacs_pixel13_'+suffix+'_coord.txt')
    ra_cen = np.mean(coord['RA(deg)'])
    dec_cen = np.mean(coord['Dec(deg)'])
    idl.pro('extract_pacs', indir=outdir+'pacs/data/', filename=objname+'_pacs_weighted',
            outdir=outdir+'pacs/advanced_products/', plotdir=outdir+'pacs/advanced_products/plots/',
            noiselevel=3, ra=ra_cen, dec=dec_cen, global_noise=20, localbaseline=10, opt_width=1, current_pix='c',
            continuum=1, flat=1, object=objname, double_gauss=1, fixed_width=1, print_all=print_all_path)
    return aper_size

# observation info
# obsid = [['AB_Aur','1342217842','1342217843','0'],\
#          ['AS205','1342215737','1342215738','0'],\
#          ['B1-a','1342216182','1342216183','1342249475'],\
#          ['B1-c','1342216213','1342216214','1342249476'],\
#          ['B335','1342208889','1342208888','1342253652'],\
#          ['BHR71','1342212230','1342212231','1342248249'],\
#          ['Ced110','0','0','1342248246'],\
#          ['DG_Tau','1342225730','1342225731','0'],\
#          ['EC82','1342192975','1342219435','0'],\
#          ['Elias29','1342228519','1342228520','0'],\
#          ['FUOri','1342250907','1342250908','1342230412'],\
#          ['GSS30-IRS1','1342215678','1342215679','0'],\
#          ['GSS30','0','0','1342251286'],\
#          ['HD100453','1342211695','1342211696','0'],\
#          ['HD100546','1342188037','1342188038','0'],\
#          ['HD104237','1342207819','1342207820','0'],\
#          ['HD135344B-1','1342213921','1342213922','0'],\
#          ['HD139614','1342215683','1342215684','0'],\
#          ['HD141569','1342213913','0','0'],\
#          ['HD142527','1342216174','1342216175','0'],\
#          ['HD142666','1342213916','0','0'],\
#          ['HD144432','1342213919','0','0'],\
#          ['HD144668','1342215641','1342215642','0'],\
#          ['HD150193','1342227068','0','0'],\
#          ['HD163296','1342217819','1342217820','0'],\
#          ['HD169142','1342206987','1342206988','0'],\
#          ['HD179218','1342208884','1342208885','0'],\
#          ['HD203024','1342206975','0','0'],\
#          ['HD245906','1342228528','0','0'],\
#          ['HD35187','1342217846','0','0'],\
#          ['HD36112','1342228247','1342228248','0'],\
#          ['HD38120','1342226212','1342226213','0'],\
#          ['HD50138','1342206991','1342206992','0'],\
#          ['HD97048','1342199412','1342199413','0'],\
#          ['HD98922','1342210385','0','0'],\
#          ['HH46','0','0','1342245084'],\
#          ['HH100','0','0','1342252897'],\
#          ['HT_Lup','1342213920','0','0'],\
#          ['IRAM04191','1342216654','1342216655','0'],\
#         #  ['IRAS03245','1342214677','1342214676','1342249053'],\
#         #  ['IRAS03301','1342215668','1342216181','1342249477'],\
#          ['DKCha','1342188039','1342188040','1342254037'],\
#          ['IRAS15398','0','0','1342250515'],\
#          ['IRS46','1342228474','1342228475','1342251289'],\
#          ['IRS48','1342227069','1342227070','0'],\
#          ['IRS63','1342228473','1342228472','0'],\
#          ['L1014','1342208911','1342208912','1342245857'],\
#          ['L1157','1342208909','1342208908','1342247625'],\
#          ['L1448-MM','1342213683','1342214675','0'],\
#         #  ['L1455-IRS3','1342204122','1342204123','1342249474'],\
#          ['L1489','1342216216','1342216215','0'],\
#          ['L1527','1342192981','1342192982','0'],\
#          ['L1551-IRS5','1342192805','1342229711','1342249470'],\
#          ['L483','0','0','1342253649'],\
#          ['L723-MM','0','0','1342245094'],\
#          ['RCrA-IRS5A','1342207806','1342207805','1342253646'],\
#          ['RCrA-IRS7B','1342207807','1342207808','1342242620'],\
#          ['RCrA-IRS7C','1342206990','1342206989','1342242621'],\
#          ['RNO90','1342228206','0','0'],\
#          ['RNO91','0','0','1342251285'],\
#          ['RU_Lup','1342215682','0','0'],\
#          ['RY_Lup','1342216171','0','0'],\
#          ['S_Cra','1342207809','1342207810','0'],\
#          ['SR21','1342227209','1342227210','0'],\
#          ['Serpens-SMM3','1342193216','1342193214','0'],\
#          ['Serpens-SMM4','1342193217','1342193215','0'],\
#          ['TMC1','1342225803','1342225804','1342250512'],\
#          ['TMC1A','1342192987','1342192988','1342250510'],\
#          ['TMR1','1342192985','1342192986','1342250509'],\
#         #  ['V1057_Cyg','1342235853','1342235852','1342221695'],\
#         #  ['V1331_Cyg','1342233446','1342233445','1342221694'],\
#         #  ['V1515_Cyg','1342235691','1342235690','1342221685'],\
#         #  ['V1735_Cyg','1342235849','1342235848','1342219560'],\
#         #  ['VLA1623','1342213918','1342213917','1342251287'],\
#          ['WL12','1342228187','1342228188','1342251290']]

# datadir = '/scratch/CDF_PACS_HSA/'
# outdir = '/home/bettyjo/yaolun/CDF_archive_test/'
#
# import os
# from astropy.io import ascii
#
# for obs in obsid:
#     if obs[3] == '0':
#         continue
#     if obs[1] == '0':
#         continue
#     # load aperture from SPIRE SECT reduction
#     if os.path.exists('/home/bettyjo/yaolun/CDF_SPIRE_reduction/photometry/'+str(obs[0])+'_spire_phot.txt'):
#         spire_phot = ascii.read('/home/bettyjo/yaolun/CDF_SPIRE_reduction/photometry/'+str(obs[0])+'_spire_phot.txt', data_start=4)
#         aper_size = spire_phot['aperture(arcsec)'][spire_phot['wavelength(um)'] == spire_phot['wavelength(um)'].min()][0]
#     else:
#         aper_size = 31.8
#     print obs[0], aper_size
#     if obs[0] != 'BHR71':
#         continue
#     cdfPacs1d(obs[1:3], datadir, outdir+obs[0]+'/', obs[0], auto_match=True, aper_size=aper_size)
