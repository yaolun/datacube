pro refine_full,outdir=outdir

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
end
