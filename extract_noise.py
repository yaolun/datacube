def extract_noise(indir, obj, spire=False, pacs=False, noiselevel=3, cube=None):
	import numpy as np
	from astropy.io import ascii
	import astropy.constants as const
	import os

	# constant setup
	c = const.c.cgs.value

	# define Gaussian
	def gauss(x, height, width, center):
		return height * np.exp(-(x - center)**2/2/width**2)

	if pacs:
		suffix = '_centralSpaxel_PointSourceCorrected_CorrectedYES_trim_flat_spectrum.txt'
		if cube != None:
			suffix = '_pacs_pixel'+str(cube)+'_os8_sf7_flat_spectrum.txt'
		if os.path.exists(indir+obj+suffix) == False:
			print obj+' do not have smoothed continuum.  Skipped'
			return None
		[wl_flat,flux_flat,unc_flat] = np.genfromtxt(indir+obj+suffix,dtype='float',skip_header=1).T
	if spire:
		suffix = '_spire_corrected_flat_spectrum.txt'
		if cube != None:
			suffix = '_'+str(cube)+'_flat_spectrum.txt'
		if os.path.exists(indir+obj+suffix) == False:
			print obj+' do not have smoothed continuum.  Skipped'
			return None
		[wl_flat,flux_flat] = np.genfromtxt(indir+obj+suffix,dtype='float',skip_header=1).T

	# original unit: um and Jy
	# convert to um and erg/s/cm2/um
	flux_flat = flux_flat * c/(wl_flat*1e-4)**2*1e-4 *1e-23

	# spectra in unit of um and Jy

	# read fitting table
	fitting = ascii.read(indir+obj+suffix[0:-17]+'lines.txt')

	# iterate through lines
	flux_lines = np.zeros_like(flux_flat)
	size = 10
	for i in range(0, len(fitting['Line'])):
		if (fitting['SNR'][i] < noiselevel) or (fitting['Validity'][i] == 0):
			continue
		else:
			if (spire) & (cube != None):
				line_gauss = gauss(wl_flat[(wl_flat > fitting['ObsWL(um)'][i]-size*fitting['FWHM(um)'][i]) & (wl_flat < fitting['ObsWL(um)'][i]+size*fitting['FWHM(um)'][i])], \
					fitting['Str(W/cm2/as2)'][i]*1e7/(fitting['FWHM(um)'][i]/2.354)/(2*np.pi)**0.5,\
					fitting['FWHM(um)'][i]/2.354,\
					fitting['ObsWL(um)'][i])
			else:
				line_gauss = gauss(wl_flat[(wl_flat > fitting['ObsWL(um)'][i]-size*fitting['FWHM(um)'][i]) & (wl_flat < fitting['ObsWL(um)'][i]+size*fitting['FWHM(um)'][i])], \
					fitting['Str(W/cm2)'][i]*1e7/(fitting['FWHM(um)'][i]/2.354)/(2*np.pi)**0.5,\
					fitting['FWHM(um)'][i]/2.354,\
					fitting['ObsWL(um)'][i])

			flux_lines[(wl_flat > fitting['ObsWL(um)'][i]-size*fitting['FWHM(um)'][i]) & (wl_flat < fitting['ObsWL(um)'][i]+size*fitting['FWHM(um)'][i])] = \
			flux_lines[(wl_flat > fitting['ObsWL(um)'][i]-size*fitting['FWHM(um)'][i]) & (wl_flat < fitting['ObsWL(um)'][i]+size*fitting['FWHM(um)'][i])] + line_gauss

	# write out the noise spectrum
	foo = open(indir+obj+suffix[0:-17]+'noise.txt','w')
	foo.write('%16s \t %16s \n' % ('Wave (um)', 'Flux (Jy)'))
	for i in range(0, len(wl_flat)):
		foo.write('%16f \t %16f \n' % (wl_flat[i], (flux_flat[i]-flux_lines[i]) * (wl_flat[i]*1e-4)**2*1e4/c * 1e23))
	foo.close()

	# (wl_noise, flux_noise) = np.genfromtxt(indir+obj+suffix[0:-17]+'noise.txt', skip_header=1).T

	# import matplotlib.pyplot as plt
	# # plt.plot(wl_flat, flux_lines)
	# # plt.plot(wl_flat, flux_flat-flux_lines+5e-11, alpha=0.5)
	# plt.plot(wl_noise, flux_noise)
	# plt.plot(wl_flat, flux_flat * (wl_flat*1e-4)**2*1e4/c * 1e23, alpha=0.5)
	# plt.savefig('/Users/yaolun/test/noise.pdf', dpi=300, format='pdf', bbox_inches='tight')

# indir = '/Users/yaolun/bhr71/fitting/BHR71/'
# obj = 'BHR71'
# extract_noise(indir, obj, spire=True)