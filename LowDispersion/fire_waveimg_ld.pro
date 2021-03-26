;+
; NAME:
;   long_waveimg
;
; PURPOSE:
;   Determine the positions of the slits on the image, and return tracesets
;
; CALLING SEQUENCE:
;   waveimg = long_waveimg(arcimg, 
;
; INPUTS:
;   arcimg       - 2D arc image
;   arcivar      - inverse variance of arc image
;   tset_slits   - slit trace set structure
;   linlist      - LRIS line list
;   archive_file - save file for archived arc for this setup
; OPTIONAL INPUTS:
;   mxshift    - Maximum shift for cross correlation of arc 
;                default to 200 (grism spectra?)
;   sigrej     - Sigma for rejection of arc lines in polynomial fitting; 
;                default is 2
;   box_rad    - boxcar radius for extracting 1-d arc (default is 5)
;   qafile     - QA file for diagnostics
;                
; OUTPUTS:
;   waveimg    - 2-d wavelength map. 
;
; OPTIONAL OUTPUTS:
;   piximg     - Pixel wavelength solution.
;   
;   fwhmset    - Fit to fwhm from arc lines for each slit as an array of 
;                traceset structures
;   
; COMMENTS:
;   The algorithm for determining the wavelength solution is in ARC_PAIRS().
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;   arc_pairs()
;   copy_struct_inx
;   djs_median()
;   long_slits2mask()
;   long_xcorr()
;   splog
;   trace_crude()
;   trace_fweight()
;   traceset2xy
;   xy2traceset
;
; REVISION HISTORY:
;   10-Mar-2005  Written by S. Burles (MIT), David Schlegel (LBL), and 
;                Joe Hennawi (UC Berkeley)
;-
;------------------------------------------------------------------------------
function fire_waveimg_ld, arcimg, arcivar, tset_slits, wstruct, savefile $
                       , xfit = xfit, fwhmset = fwhmset, qafile = qafile $
                       , pixset = pixset, piximg = piximg $
                       , NO_AUTO = NO_AUTO, TRCCHK = TRCCHK $
                       , box_rad = box_rad, FWCOEFF = FWCOEFF1

IF NOT KEYWORD_SET(FORDR) THEN FORDR = 9L
if NOT keyword_set(box_rad) then box_rad = 5L
if (keyword_set(maxsep1)) then maxsep = maxsep1 else maxsep = 10L
if (keyword_set(fwcoeff1)) then fwcoeff = fwcoeff1 else fwcoeff = 3L

;;---------
;; set parameters from wavestruct
linelist_ap = wstruct.linelist_ap
linelist = wstruct.linelist
REID = wstruct.REID
AUTOID = wstruct.AUTOID
RADIUS = wstruct.RADIUS
SIG_WPIX = wstruct.SIG_WPIX

badpix = WHERE(finite(arcimg) NE 1 OR finite(arcivar) NE 1, nbad)
IF nbad NE 0 THEN arcivar[badpix] = 0.0D

dims = size(arcimg, /dimens)
nx = dims[0]
ny = dims[1]
nyby2 = ny/2L

;; ------
;; Expand slit set to get left and right edge
traceset2xy, tset_slits[0], rows, left_edge
traceset2xy, tset_slits[1], rows, right_edge


if (size(left_edge, /n_dimen) EQ 1) then nslit = 1 $
else nslit = (size(left_edge, /dimens))[1]
trace = (left_edge + right_edge)/2.0D
;; Open line lists
x_arclist, linelist, lines

arc1d = fltarr(ny, nslit)
for islit = 0L, nslit-1L do begin
    splog, 'Working on slit #', islit+1, ' (', islit+1, ' of ', nslit, ')'
    ;; iteratively compute mean arc spectrum which is robust against cosmics
    FOR j = 0L, ny-1L DO BEGIN
        left  = floor(trace[j, islit] - BOX_RAD)
        right = ceil(trace[j, islit] + BOX_RAD)
        sub_arc  = arcimg[left:right, j]
        sub_ivar = arcivar[left:right, j]
        sub_var = 1.0/(sub_ivar + (sub_ivar EQ 0.0))
        djs_iterstat, sub_arc, invvar = sub_ivar $
                      , mean = mean, sigrej = 3.0, mask = mask, median = median
        arc1d[j, islit] = mean
;        arc1d[j, islit] = arcimg[(left+right)/2,j]
        IF total(mask) NE 0 THEN var = total(sub_var*mask)/total(mask)^2 $
        ELSE var = total(sub_var)
    ENDFOR
;    CONTINUE ;; uncomment this continue here if you want to dump out the
;    arc1d for calibrating. 
;    stop
    IF KEYWORD_SET(AUTOID) THEN $
       fin_fit = long_autoid(arc1d[*, islit], lines, wstruct $
                             , gdfit = gdfit, rejpt = rejpt $
                             , fit_flag = fit_flag) $
    ELSE IF KEYWORD_SET(REID) THEN begin
       fin_fit = fire_reidentify(arc1d[*, islit], lines, wstruct $
                                 , gdfit = gdfit, rejpt = rejpt $
                                 , MXSHIFT = wstruct.mxshift $
                                 , fit_flag = fit_flag, /ARC_INTER) 
    endif $
    ELSE message, 'Wavelength setup not supported or error with flags'
    ;; Polynomial fit for the full-width half max and third-width 
    ;; half max of each of the good arc lines. 
    IF gdfit[0] EQ - 1 THEN ngd = 0 $
    ELSE ngd = n_elements(gdfit)
    IF ngd EQ 0 THEN BEGIN
        fwhm = 0.0
        line_str =  lines[0]
        struct_assign, {junk:0}, line_str
    ENDIF ELSE BEGIN
        fwhm = fltarr(ngd)
        line_str = lines[gdfit]
    ENDELSE
    FOR j = 0L, ngd-1L DO $
      fwhm[j] = long_arc_fwhm(arc1d[*, islit], lines[gdfit[j]].pix, maxsep)
    inmask = fwhm GT 0.0 
    ;;IF ngd LT 8 THEN fwcoeff_now = fwcoeff-1L $
    ;;ELSE fwcoeff_now = fwcoeff
    ;; Now fit a polynomial to the fwhm and reject outliers
    fwhmset_temp1 = jfh_fit_reject(line_str.pix, fwhm, fwcoeff $
                                   , TOL = FWTOL $
                                   , outmask = fwhmmask, inmask = inmask $
                                   , FUNC = 'poly', YFIT = FWFIT $
                                   , XMIN = 0, XMAX = ny-1L)
    good_lines = WHERE(fwhmmask GT 0, ngline)
    IF ngline NE 0 THEN fwhm_med = djs_median(fwhm[good_lines]) $
    ELSE fwhm_med = 0.0
    fwhmset_temp = struct_addtags(fwhmset_temp1 $
                                  , create_struct('MEDIAN', fwhm_med))
    ;; --------------
    ;; Output some QA
    IF keyword_set(QAFILE) THEN BEGIN 
       dfpsplot, qafile, /color
       long_waveqa, line_str, fin_fit, arc1d[*, islit], rejpt, islit $
                     , fwhm, fwhmset_temp, fwhmmask, QAFILE $
                     , PANIC =  (ngd LT wstruct.npanic) $
                     , BADFIT = (FIT_FLAG EQ 0)
        !p.multi = 0
        dfpsclose
    ENDIF
    IF NOT KEYWORD_SET(XFIT) THEN BEGIN
        xfit = replicate(fin_fit, nslit)
        fwhmset = replicate(fwhmset_temp, nslit)
        struct_assign, {junk:0}, xfit
        struct_assign, {junk:0}, fwhmset ; Zero-out all elements
    ENDIF
    copy_struct_inx, fin_fit, xfit, index_to = islit
    copy_struct_inx, fwhmset_temp, fwhmset, index_to = islit
 ENDFOR
; save, arc1d, xfit, file = savefile

;; uncomment the stop and save if you want to dump out the arc1d for 
;; calibrating. 



return, xfit
end
;------------------------------------------------------------------------------
