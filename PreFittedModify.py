def PreFittingModify(indir, outdir, obs):
    # to avoid X server error
    import matplotlib as mpl
    mpl.use('Agg')
    from astropy.io import ascii
    import matplotlib.pyplot as plt
    import numpy as np
    import os

    # modify outdir
    # outdir = outdir+obs[0]+'/data/'
    if not os.path.isdir(outdir):
        os.makedirs(outdir)


    if not os.path.isfile(indir+obs[3]+'_spire_sect.txt'):
        print(obs[0]+' is not found.')
        return None
    # read in the spectrum
    spire_spec = ascii.read(indir+obs[3]+'_spire_sect.txt', data_start=4)
    # convert it to the usual format
    spire_wl = np.hstack((spire_spec['wave_segm1_0'][spire_spec['wave_segm1_0'] >= 310].data,
                spire_spec['wave_segm2_0'][(spire_spec['wave_segm2_0'] < 310) & (spire_spec['wave_segm2_0'] > 195)].data))
    spire_flux = np.hstack((spire_spec['flux_segm1_0'][spire_spec['wave_segm1_0'] >= 310].data,
                spire_spec['flux_segm2_0'][(spire_spec['wave_segm2_0'] < 310) & (spire_spec['wave_segm2_0'] > 195)].data))

    sorter = np.argsort(spire_wl)
    spire_wl = spire_wl[sorter].data
    spire_flux = spire_flux[sorter].data

    # Write to file
    foo = open(outdir+obs[0]+'_spire_corrected.txt','w')
    foo.write('%s \t %s \n' % ('Wavelength(um)', 'Flux_Density(Jy)'))
    for i in range(len(spire_wl)):
        foo.write('%f \t %f \n' % (spire_wl[i], spire_flux[i]))
    foo.close()

    # read in the photometry
    # spire_phot = ascii.read(outdir+obs[0]+'phot_sect.txt', data_start=4)

    fig = plt.figure(figsize=(8,6))
    ax = fig.add_subplot(111)

    ax.plot(spire_wl, spire_flux)
    # ax.errorbar(spire_phot['wavelength(um)'], spire_phot['flux(Jy)'], yerr=spire_phot['uncertainty(Jy)'],
    #              fmt='s', color='m', linestyle='None')
    ax.set_xlabel(r'$\rm{Wavelength\,[\mu m]}$',fontsize=20)
    ax.set_ylabel(r'$\rm{Flux\,Density\,[Jy]}$',fontsize=20)
    [ax.spines[axis].set_linewidth(1.5) for axis in ['top','bottom','left','right']]
    ax.minorticks_on()
    ax.tick_params('both',labelsize=18,width=1.5,which='major',pad=15,length=5)
    ax.tick_params('both',labelsize=18,width=1.5,which='minor',pad=15,length=2.5)

    # fix the tick label font
    ticks_font = mpl.font_manager.FontProperties(family='STIXGeneral',size=18)
    for label in ax.get_xticklabels():
        label.set_fontproperties(ticks_font)
    for label in ax.get_yticklabels():
        label.set_fontproperties(ticks_font)

    fig.savefig(outdir+obs[0]+'_spire_corrected.pdf', format='pdf', dpi=300, bbox_inches='tight')
    fig.clf()

def SPIRE1d_fit(indir, objname, global_dir, wl_shift=0):
    import os
    from astropy.io import ascii
    if not os.path.isfile(indir+'data/'+objname+'_spire_corrected.txt'):
        print(objname+' is not found.')
        return None

    # read RA/Dec
    radec_slw = ascii.read(indir+'/data/cube/'+objname+'_radec_slw.txt')

    import pidly
    idl = pidly.IDL('/opt/local/exelis/idl83/bin/idl')
    idl('.r /home/bettyjo/yaolun/programs/line_fitting/gauss.pro')
    idl('.r /home/bettyjo/yaolun/programs/line_fitting/extract_spire.pro')
    idl.pro('extract_spire', indir=indir+'data/', filename=objname+'_spire_corrected',
            outdir=indir+'advanced_products/', plotdir=indir+'advanced_products/plots/', noiselevel=3,
            ra=radec_slw['RA(deg)'][radec_slw['Pixel'] == 'SLWC3'], dec=radec_slw['Dec(deg)'][radec_slw['Pixel'] == 'SLWC3'],
            global_noise=20, localbaseline=10, continuum=1, flat=1, object=objname, double_gauss=1, fx=1, current_pix=1,
            print_all=global_dir+'_lines', wl_shift=wl_shift)

def SPIRE1D_run(obsid=None, indir=None, outdir=None, global_dir=None, wl_shift=0):
    if obsid == None:
        # observation info
        obsid = [['AB_Aur','1342217842','1342217843','0'],\
                 ['AS205','1342215737','1342215738','0'],\
                 ['B1-a','1342216182','1342216183','1342249475'],\
                 ['B1-c','1342216213','1342216214','1342249476'],\
                 ['B335','1342208889','1342208888','1342253652'],\
                 ['BHR71','1342212230','1342212231','1342248249'],\
                 ['Ced110','0','0','1342248246'],\
                 ['DG_Tau','1342225730','1342225731','0'],\
                 ['EC82','1342192975','1342219435','0'],\
                 ['Elias29','1342228519','1342228520','0'],\
                 ['FUOri','1342250907','1342250908','1342230412'],\
                 ['GSS30-IRS1','1342215678','1342215679','1342251286'],\
                 ['HD100453','1342211695','1342211696','0'],\
                 ['HD100546','1342188037','1342188038','0'],\
                 ['HD104237','1342207819','1342207820','0'],\
                 ['HD135344B-1','1342213921','1342213922','0'],\
                 ['HD139614','1342215683','1342215684','0'],\
                 ['HD141569','1342213913','0','0'],\
                 ['HD142527','1342216174','1342216175','0'],\
                 ['HD142666','1342213916','0','0'],\
                 ['HD144432','1342213919','0','0'],\
                 ['HD144668','1342215641','1342215642','0'],\
                 ['HD150193','1342227068','0','0'],\
                 ['HD163296','1342217819','1342217820','0'],\
                 ['HD169142','1342206987','1342206988','0'],\
                 ['HD179218','1342208884','1342208885','0'],\
                 ['HD203024','1342206975','0','0'],\
                 ['HD245906','1342228528','0','0'],\
                 ['HD35187','1342217846','0','0'],\
                 ['HD36112','1342228247','1342228248','0'],\
                 ['HD38120','1342226212','1342226213','0'],\
                 ['HD50138','1342206991','1342206992','0'],\
                 ['HD97048','1342199412','1342199413','0'],\
                 ['HD98922','1342210385','0','0'],\
                 ['HH46','0','0','1342245084'],\
                 ['HH100','0','0','1342252897'],\
                 ['HT_Lup','1342213920','0','0'],\
                 ['IRAM04191','1342216654','1342216655','0'],\
                 ['IRAS03245','1342214677','1342214676','1342249053'],\
                 ['IRAS03301','1342215668','1342216181','1342249477'],\
                 ['DKCha','1342188039','1342188040','1342254037'],\
                 ['IRAS15398','0','0','1342250515'],\
                 ['IRS46','1342228474','1342228475','1342251289'],\
                 ['IRS48','1342227069','1342227070','0'],\
                 ['IRS63','1342228473','1342228472','0'],\
                 ['L1014','1342208911','1342208912','1342245857'],\
                 ['L1157','1342208909','1342208908','1342247625'],\
                 ['L1448-MM','1342213683','1342214675','0'],\
                 ['L1455-IRS3','1342204122','1342204123','1342249474'],\
                 ['L1489','1342216216','1342216215','0'],\
                 ['L1527','1342192981','1342192982','0'],\
                 ['L1551-IRS5','1342192805','1342229711','1342249470'],\
                 ['L483','0','0','1342253649'],\
                 ['L723-MM','0','0','1342245094'],\
                 ['RCrA-IRS5A','1342207806','1342207805','1342253646'],\
                 ['RCrA-IRS7B','1342207807','1342207808','1342242620'],\
                 ['RCrA-IRS7C','1342206990','1342206989','1342242621'],\
                 ['RNO90','1342228206','0','0'],\
                 ['RNO91','0','0','1342251285'],\
                 ['RU_Lup','1342215682','0','0'],\
                 ['RY_Lup','1342216171','0','0'],\
                 ['S_Cra','1342207809','1342207810','0'],\
                 ['SR21','1342227209','1342227210','0'],\
                 ['Serpens-SMM3','1342193216','1342193214','0'],\
                 ['Serpens-SMM4','1342193217','1342193215','0'],\
                 ['TMC1','1342225803','1342225804','1342250512'],\
                 ['TMC1A','1342192987','1342192988','1342250510'],\
                 ['TMR1','1342192985','1342192986','1342250509'],\
                 ['V1057_Cyg','1342235853','1342235852','1342221695'],\
                 ['V1331_Cyg','1342233446','1342233445','1342221694'],\
                 ['V1515_Cyg','1342235691','1342235690','1342221685'],\
                 ['V1735_Cyg','1342235849','1342235848','1342219560'],\
                 ['VLA1623','1342213918','1342213917','1342251287'],\
                 ['WL12','1342228187','1342228188','1342251290']]

    if indir == None:
        indir = '/home/bettyjo/yaolun/CDF_SPIRE_reduction/'
    if outdir == None:
        outdir = '/home/bettyjo/yaolun/CDF_archive/'
    if global_dir == None:
        global_dir = outdir

    for obs in obsid:
        if obs[3] == '0':
            continue
        # exclude HH100
        if obs[0] == 'HH100':
            continue
        PreFittingModify(outdir+obs[0]+'/spire/data/', outdir+obs[0]+'/spire/data/', obs)

        SPIRE1d_fit(outdir+obs[0]+'/spire/', obs[0], global_dir, wl_shift=wl_shift)
