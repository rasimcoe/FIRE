FORWARD_FUNCTION fire_get ;; necessary because fire_get and grab_header_info call each other

;; **********************************************************************************************************************************************
FUNCTION get_val, data, _EXTRA = keys

	func_name = "get_val"

	;; Create the command format
	commands = [ "val = data.", "tag" ]
	val = -1 ;; not actually used
	cmd = fire_create_command(val, commands, func_name, TAG=tag, _EXTRA = keys)
	if size(cmd, /type) NE 7 then begin
		fire_siren, func_name + ": Creation of command string failed!  Returning non-sensical value!"
		RETURN, -1
	endif
	;; Check to make sure that the tag exists.  Exit otherwise
	if tag_exist( data, tag ) EQ 0 then begin
		fire_siren, func_name + ": ERROR!  A tag named " + tag + " does not exist for this structure!" + $
			"  (Did you remember to use the FULL tag name? -- no shortening allowed!)" + $
			"  Returning a non-sensical value!"	
		RETURN, -1
	endif
	
	result = EXECUTE( cmd )

	;; Make sure the execution succeeded
	if result NE 1 then begin
		fire_siren, func_name + ": WARNING: EXECUTE(command) failed!  Exiting with error."
		RETURN, -1
	endif

	RETURN, val

END


;; **********************************************************************************************************************************************
;; Warns the user of any changes made to the data by fire_get
FUNCTION announce_change, tag, old_val, new_val, ERROR=error, MESSAGE=message
	if NOT keyword_set(ERROR) then begin
		out =  "fire_get: Changing value of " + tag + " from " + fire_string(old_val) + " to " + fire_string(new_val)
	endif else begin
		if NOT keyword_set(MESSAGE) then begin
			extra = ''
		endif else begin
			extra = ': ' + message
			out = "fire_get: Warning: could not change the value of " + tag + " from " + fire_string(old_val) + " to " + fire_string(new_val) + extra
		endelse
	endelse
	if size(out,/type) NE 7 then begin
		fire_siren, "announce_change: ERROR! output string is not a string!"
		stop
	endif
	RETURN, out
END



;; **********************************************************************************************************************************************
PRO grab_header_info, data, old_val, new_val, announcement, ERROR=error, DONOTCALC=donotcalc, FITSFILE=fitsfile, HDR=hdr, EXPTYPE=exptype, OBJECT=object, AIRMASS=airmass, SLIT=slit, EXPTIME=exptime, JD=jd, RA_DEG=ra_deg, DEC_DEG=dec_deg


;        if (n_elements(old_val) EQ 1) then stop
	
	;; If this tag does not contain header information, then exit
	if NOT keyword_set(FITSFILE) AND NOT keyword_set(HDR) AND NOT keyword_set(EXPTYPE) AND $
		NOT keyword_set(OBJECT) AND NOT keyword_set(AIRMASS) AND NOT keyword_set(SLIT) AND $
		NOT keyword_set(EXPTIME) AND NOT keyword_set(JD) AND NOT keyword_set(RA_DEG) AND $
		NOT keyword_set(DEC_DEG) then RETURN

	;; Determine if the currently stored value is the default.  (If so, exit).
	;; Also, determine the appropriate tag names:
	;; fitslabel: label in data's fits header
	;; tagname: name of tag in firestrct
	if keyword_set(FITSFILE) then begin
           if is_fits(strtrim(old_val,2)) EQ 1 then RETURN
           tagname = "FITSFILE"
           fitslabel = "FILE"
        endif else if keyword_set(EXPTYPE) then begin
		if is_empty(old_val) EQ 0 then RETURN
		tagname = "EXPTYPE"
		fitslabel = "EXPTYPE"	
	endif else if keyword_set(OBJECT) then begin
		if is_empty(old_val) EQ 0 then RETURN
		tagname = "OBJECT"
		fitslabel = "OBJECT"
	endif else if keyword_set(AIRMASS) then begin
		if old_val NE -1.0 then RETURN
		tagname = "AIRMASS"
		fitslabel = "AIRMASS"
	endif else if keyword_set(SLIT) then begin
		if is_empty(old_val) EQ 0 then RETURN
		tagname = "SLIT"
		fitslabel = "SLIT"
	endif else if keyword_set(EXPTIME) then begin
		if old_val NE 0.0 then RETURN
		tagname = "EXPTIME"
		fitslabel = "EXPTIME"	
	endif else if keyword_set(RA_DEG) then begin
		if old_val NE 999.0 then RETURN
		tagname = "RA_DEG"
		fitslabel = "RA"	
	endif else if keyword_set(DEC_DEG) then begin
		if old_val NE 999.0 then RETURN
		tagname = "DEC_DEG"
		fitslabel = "DEC"	
	endif
	
	;; If we've made it here, we know that we're dealing with a tag that has not been set yet.		
	;; Therefore, we'll try to set it.

	;; First, two usual cases:

	;; (1) Check if we're grabbing the actual header.  If so, do this and then exit.
	if keyword_set( HDR ) then begin
		if is_empty(old_val) EQ 1 then begin
			fitsname = fire_get(data, /FITSFILE, /DONOTCALC) ;; the /DONOTCALC is vital here: infinite loop otherwise
			if FILE_TEST( fitsname ) EQ 1 then begin
				new_val = xheadfits(fitsname)
			endif else begin
				error = 1
			endelse
			out = announce_change('HDR', old_val, new_val, ERROR=error, MESSAGE="Fitsfile " + $
				fitsname +" does not exist!  Could not read in header!")
			new_val = -1
		endif
		RETURN
	endif

	;; Grab the header.  Check if done successfully.
	h = fire_get(data, /HDR, DONOTCALC=donotcalc)
	if size(h, /type) NE 7 then begin
		error = 1
		RETURN
	endif

	;; (2) Check if we're dealing with the Julian date.  If so, do this and then exit.
	if keyword_set( JD ) then begin
		if old_val EQ 0.0 then begin
			;; Calculate the Julian date from the hdr
			new_val = fire_get_jd( h, /REDUCED )
			announcement = announce_change("JD", old_val, new_val, ERROR=error, MESSAGE="Could not read header!")
		endif
		RETURN
	endif

	;; The other cases are standard.  Perform the usual set of tasks...
	
	;; Read in the value stored in the header.
   new_val = sxpar(h, fitslabel, /SILENT)

	;; If reading in the FITSFILE, check to see if an error has occured.  If so, then don't update.
   if keyword_set(FITSFILE) then begin
   	if size(new_val, /type) EQ 2 then begin
   		new_val = old_val
   	endif
   endif

	announcement = announce_change(tagname, old_val, new_val, ERROR=error, MESSAGE="Could not read header!")

	RETURN

END


;; **********************************************************************************************************************************************
PRO grab_file_name, data, old_val, new_val, announcement, ONEARC=onearc, STD=std, OH=oh, THAR=thar, DONOTSET=donotset, ILLUMFLATFILE=illumflatfile, PIXFLATFILE=pixflatfile, ORDERFILE=orderfile, ORDR_STR_FILE=ordr_str_file, PIXIMGFILE=piximgfile, ARCFITS=arcfits, ARCIMGFITS=arcimgfits, ECHEXTFILE=echextfile, OBJSTRFILE=objstrfile, TARCFITS=tarcfits, TARCIMGFITS=tarcimgfits, TECHEXTFILE=techextfile, TOBJSTRFILE=tobjstrfile, ERROR=error

	func_name = 'grab_file_name()'

	;; Exit if none of the file flags are set.
	if NOT keyword_set(ILLUMFLATFILE) AND NOT keyword_set(PIXFLATFILE) AND NOT keyword_set(ORDERFILE) AND $
			NOT keyword_set(ORDR_STR_FILE) AND NOT keyword_set(PIXIMGFILE) AND NOT keyword_set(ARCFITS) AND $
			NOT keyword_set(PIXIMGFILE) AND NOT keyword_set(ARCFITS) AND NOT keyword_set(ARCIMGFITS) AND $
			NOT keyword_set(ECHEXTFILE) AND NOT keyword_set(OBJSTRFILE) AND NOT keyword_set(TARCFITS) AND $
			NOT keyword_set(TARCIMGFITS) AND NOT keyword_set(TECHEXTFILE) AND NOT keyword_set(TOBJSTRFILE) then begin
		RETURN
	endif

	;; grab_file_name only supports scalars.  Exit with error if data is actually an array.
	if n_elements(data) NE 1 then begin
		fire_siren, func_name + ": ERROR.  This function only allows for one structure (or object reference) at a time." + $
			" No ARRAYS!  (You most likely input an array of firestrcts to fire_get)." + $
			"  Exiting without performing requested task: no unstored file names will be determined."		
		RETURN
	endif

	;; If the input value is already a file name, then do not
	;; bother determining the file name
	if is_fits(old_val) EQ 1 OR is_fits(old_val, /GZ) EQ 1 then RETURN

	;; Determine the flats, illumflats, or arcs
	if keyword_set(ILLUMFLATFILE) then begin
		files = fire_get( data, /ILLUMS )
	endif
	
	if keyword_set(PIXFLATFILE) OR keyword_set(PIXIMGFILE) OR keyword_set(ORDERFILE) OR $
			keyword_set(ORDR_STR_FILE) then begin
		files = fire_get( data, /FLATS )
	endif
        
	if keyword_set(ARCFITS) OR keyword_set(ARCIMGFITS) OR keyword_set(ARC1D) OR $
			keyword_set(ARC2D) OR keyword_set(ARC_SOL) then begin
		files = fire_get( data, /WAVECALFILE, ONEARC=onearc, STD=std, OH=oh, THAR=thar )
	endif else if keyword_set(TARCFITS) OR keyword_set(TARCIMGFITS) then begin
		files = fire_get( data, /WAVECALFILE, ONEARC=onearc, STD=std, OH=oh, THAR=thar )	
	endif

	if keyword_set(ECHEXTFILE) OR keyword_set(OBJSTRFILE) then begin
		files = fire_get( data, /FITSFILE, STD=std )
	endif else if keyword_set(TECHEXTFILE) OR keyword_set(TOBJSTRFILE) then begin
		files = fire_get( data, /TFILES, STD=std )
	endif

	if size( files, /type) EQ 7 then begin
		if is_empty( files ) EQ 0 then begin
			new_val = FIRE_GET_FILE_NAMES( files, ILLUMFLAT=illumflatfile, PIXFLATFILE=pixflatfile, ORDERFILE=orderfile, ORDR_STR_FILE=ordr_str_file, PIXIMGFILE=piximgfile, ARCFITS=arcfits, TARCFITS=tarcfits, ARCIMGFITS=arcimgfits, TARCIMGFITS=tarcimgfits, ECHEXTFILE=echextfile, OBJSTRFILE=objstrfile, TECHEXTFILE=techextfile, TOBJSTRFILE=tobjstrfile )
		endif else begin
			error = 1
			new_val = ' '
		endelse
	endif else begin
	   error = 1
	   new_val = ' '
	endelse

	;; Determine the tag name
	;; (only used to print to screen).
	if keyword_set(ILLUMFLATFILE) then begin
		tagname = "ILLUMFLAT"
	endif else if keyword_set(PIXFLATFILE) then begin
		tagname = "PIXFLATFILE"
	endif else if keyword_set(ORDERFILE) then begin
		tagname = "ORDERFILE"	
	endif else if keyword_set(ORDR_STR_FILE) then begin
		tagname = "ORDR_STR_FILE"	
	endif else if keyword_set(PIXIMGFILE) then begin
		tagname = "PIXIMGFILE"
	endif else if keyword_set(ARCFITS) then begin
		tagname = "ARCFITS"	
	endif else if keyword_set(ARCIMGFITS) then begin
		tagname = "ARCIMGFITS"	
	endif else if keyword_set(ECHEXTFILE) then begin
		tagname = "ECHEXTFILE"	
	endif else if keyword_set(OBJSTRFILE) then begin
		tagname = "OBJSTFILE"	
	endif else if keyword_set(TARCFITS) then begin
			tagname = "TARCFITS"	
	endif else if keyword_set(TARCIMGFITS) then begin
			tagname = "TARCIMGFITS"
	endif else if keyword_set(TECHEXTFILE) then begin
			tagname = "TECHEXTFILE"	
	endif else if keyword_set(TOBJSTRFILE) then begin
			tagname = "TOBJSTFILE"
	endif else begin
		tagname = "(Unknown file)"
		fire_siren, func_name + ": Warning: file type tagname not deteremined!"	
	endelse
	
	if keyword_set(STD) AND strmatch(tagname, "t*", /FOLD_CASE) EQ 0 then tagname = "T" + tagname
  
	if (keyword_set(ECHEXTFILE) AND keyword_set(STD)) OR keyword_set(TECHEXTFILE) OR $
			(keyword_set(OBJSTRFILE) AND keyword_set(STD)) OR keyword_set(TOBJSTRFILE) then begin
		DONOTSET = 1
	endif
  
	announcement = announce_change(tagname, old_val, new_val, ERROR=error, $ 
		MESSAGE="Names of flat or arc files not stored in structure!")

	RETURN

END


FUNCTION fire_convert_val_to_list, data, val, ONEARC=onearc, STD=std, FITSFILE=fitsfile, $
	ARCS=arcs, FLATS=flats, ILLUMS=illums, TFILES=tfiles, TARCS=tarcs, TFLATS=tflats

	func_name = 'fire_convert_to_list()'

	if keyword_set(ARCS) OR keyword_set(FLATS) OR keyword_set(ILLUMS) OR $
			keyword_set(TFILES) OR keyword_set(TARCS) OR keyword_set(TFLATS) then begin

		;; Make sure that only one structure or object reference was input.
		if n_elements(data) NE 1 then begin
			fire_siren, func_name + ": ERROR.  This function only allows for one structure (or object reference) at a time." + $
				" No ARRAYS!  (You most likely input an array of firestrcts to fire_get).  Returning non-sensical value!"		
			RETURN, -1		
		endif


		;; Determine the path
		thepath = fire_get(data, /RAWPATH)
		val = list_to_names( val, PATH=thepath )
		
		if ( keyword_set(TFILES) OR keyword_set(FITSFILE) ) AND keyword_set(STD) then begin
			;; The input standard is the telluric file number input with first element 1 (not 0)
			nvals = n_elements(val)
			if STD LE nvals then begin
				val = val[STD-1]
			endif else begin
				fire_siren, func_name + ": Error! Input value for STD (= " + fire_string(STD) + $
					") exceeds the number of file names (= " + fire_string(nvals) + $
					")!  Returning non-sensical value!"
				RETURN, -1
			endelse
		endif
		
		if (keyword_set(ARCS) OR keyword_set(TARCS)) AND keyword_set(ONEARC) then begin
			val = val[0]
		endif
	
	endif

	RETURN, val

END


PRO grab_other_vals, data, old_val, new_val, out, RAWPATH=rawpath

	func_name = 'grab_other_vals()'

	;; If not provided, guess that the Raw path is ../Raw
	if keyword_set( RAWPATH ) then begin
		if (is_empty( old_val ) EQ 1) then begin
			new_val = '../Raw/'
			error = 1 - FILE_TEST( new_val, /directory )
			out = announce_change('RAWPATH', old_val, new_val, ERROR=error,  MESSAGE= "Directory " + new_val + " does not exist!" )  
		endif
	endif

	RETURN
	
END



;; **********************************************************************************************************************************************
;; Returns the value of the tagname input via keyword.  If not already
;; set, it (sets and) returns a default value based upon other fields in the structure already populated (unless /DONOTCALC is given).
;; The input data may be either a firestrct structure (such as those created by data = {firestrct} and data=create_struct(name='firestrct')) or an object reference (such as those created by obj_new('firestrct'))

FUNCTION fire_get, data, ONEARC=onearc, STD=std, SCIIMG=sciimg, $
	SCIIVAR=sciivar, PIXIMAGE=piximage, WAVEIMG=waveimg, TWAVEIMG=twaveimg, TSET_SLITS=tset_slits, DONOTCALC=donotcalc, $
	VERBOSE=verbose, DONOTSET=donotset, QUIET=quiet, FILEREAD=fileread, $
	WAVECALFILE=wavecalfile, Oh=oh, THAR=thar, $
	_EXTRA = keys

	prog_name = "fire_get"

	if keyword_set(HELP) then begin
		print, "fire_get: help menu."
		print, "Usage:"
		print, prog_name + "no help available yet."
		RETURN, -1
	endif



	;; *****************************************************************
	;; fire_get accepts either firestrct structures or object references.
	;; Determine if the input is a structure (set obj_or_not=0) or 
	;; object reference (set obj_or_not=1) (or neither: not allowed!)
	;; *****************************************************************	

	obj_or_not = is_obj( data )
	if obj_or_not EQ -1 then RETURN, -1



	;; *****************************************************************
	;; fire_get contains a few specialty flags which convert some keywords
	;; to other keywords.  Here, we make these conversions if such
	;; specialty keywords have been passed.
	;; *****************************************************************	

	;; Alter the input keywords when WAVECALFILE or STD are input
	fire_getset_alter_keys, STD=std, WAVECALFILE=wavecalfile, OH=oh, THAR=thar, keys=keys



	;; *****************************************************************
	;; fire_get may be used to read in certain previously created
	;; structures, or run quick processing functions like fire_proc.
	;; For these flags, we perform the relevent work here, and then exit
	;; *****************************************************************	

	if keyword_set(TSET_SLITS) then begin
		fileread = fire_get(data,/orderfile)
		if FILE_TEST(fileread) then begin
			if keyword_set(VERBOSE) then print, prog_name + ": Extracting tset_slits file " + fileread
			RETURN, mrdfits( fileread, 1 )
		endif else begin
			fire_siren, prog_name + ": Cannot read in tset_slits structure: order file " + fileread + " does not exist!  Returning non-sensical value..."
			RETURN, 1
		endelse
	endif
	if keyword_set(SCIIMG) OR keyword_set(SCIIVAR) then begin
		;; Determine the file name
		fileread = fire_get(data, /FITSFILE, STD=std)
		;; Determine the names of the pixel and illumination flat files
		pixflatfile = fire_get(data, /PIXFLATFILE)
		illumflatfile = fire_get(data, /ILLUMFLATFILE)
		if keyword_set(VERBOSE) then print, prog_name + ": Running fire_proc on file " + $
			 fileread + "; illumflat = " + illumflatfile + ", pixflat = " + pixflatfile
		fire_proc, fileread, sciimg, sciivar, hdr=hdr $
			, pixflatfile=pixflatfile, illumflatfile=illumflatfile
		RETURN, sciimg
	endif
	if keyword_set(PIXIMAGE) then begin
		fileread = fire_get(data, /PIXIMGFILE)
		if FILE_TEST(fileread) then begin
			if keyword_set(VERBOSE) then print, prog_name, ": Extracting pixel image from file ", fileread
			RETURN, xmrdfits( fileread )
		endif else begin
			fire_siren, prog_name + ": Cannot read in pixel image: file " + fileread + " does not exist!  Returning non-sensical value..."
			RETURN, 1
		endelse
	endif
	if keyword_set(WAVEIMG) OR keyword_set(TWAVEIMG) then begin
		if keyword_set(WAVEIMG) then begin
			fileread = fire_get(data, /ARCIMGFITS, STD=std)
		endif else if keyword_set(TWAVEIMG) then begin
			fileread = fire_get(data, /TARCIMGFITS, STD=std)		
		endif
		if FILE_TEST(fileread) then begin
			if keyword_set(VERBOSE) then print, prog_name, ": Extracting arc image from file ", fileread
			RETURN, xmrdfits( fileread )
		endif else begin
			fire_siren, prog_name + ": Cannot read in arc image: file " + fileread + " does not exist!  Returning non-sensical value..."
			RETURN, 1
		endelse
	endif




	;; *****************************************************************
	;; Grab the current value of whatever property is desired
	;; *****************************************************************	

	skip_get = 0 ;; no reasons to skip provided yet...
	if skip_get EQ 0 then begin
		if obj_or_not EQ 1 then begin ;; data is an object reference
			val = data->get( _EXTRA = keys )
		endif else begin ;; data is a structure
			val = get_val( data, _EXTRA = keys )
		endelse
	endif else begin
		val = ' '
	endelse

	;; *****************************************************************
	;; If the desired output is a list of file names (such as with /FLATS),
	;; then the values stored must be converted from a semi-colon delineated
	;; string scalar (as is stored in firestrct) to a string array of
	;; file names. 
	;; *****************************************************************	

	val = fire_convert_val_to_list( data, val, STD=std, ONEARC=onearc, _EXTRA = keys )



	;; If /donotcalc is passed, then just return this value.
	if keyword_set(DONOTCALC) then RETURN, strtrim(val,2)



	;; *****************************************************************
	;; fire_get has the ability to calculate values of requested information
	;; in certain circumstances when none is currently stored based upon
	;; other information in the firestrct structure.  
	;; *****************************************************************	

	out = '' ;; message to user about any changes
        new_val = 0
	error = 0



	;; Methods of determining information:
	;; (I) creates filenames based upon flats, arcs, etc.
	;; (II) grabs information from the data file's header
	;; (III) other (all other ways) 



	;; (I) File names
	;; *****************************************************************
	;; If information stored in the initial fits header of the data file
	;; (or the header itself) is desired, but has not been stored, then
	;; it should be possible to simply open up the header and retrieve
	;; the information.  We attempt that here.
	;; *****************************************************************	

;        if (keyword_set(WAVECALFILE)) then stop

	grab_header_info, data, val, new_val, out, ERROR=error, DONOTCALC=donotcalc, _EXTRA = keys

	;; (II) Headers
	;; *****************************************************************
	;; If a file name is desired, but it has not been stored in the
	;; firestrct structure yet, then determine the correct name of the 
	;; file using other information stored in the structure (flats, arcs, etc.)
	;; *****************************************************************	

;        if (keyword_set(WAVECALFILE)) then stop

	grab_file_name, data, val, new_val, out, ONEARC=onearc, STD=std, $ 
		OH=oh, THAR=thar, DONOTSET=donotset, ERROR=error, _EXTRA = keys

	;; (III) Other
	;; *****************************************************************
	;; Certain other tags may also allow for default values to be 
	;; determined if none are stored.  We take care of that here.
	;; --determines rawpath
	;; --appends path to FITSFILE, if desired.
	;; *****************************************************************	

;        if (keyword_set(WAVECALFILE)) then stop

	grab_other_vals, data, val, new_val, out, _EXTRA = keys

;        if (keyword_set(WAVECALFILE)) then stop


	;; If a change has been made, then institute this change
	if is_empty( out ) EQ 0 then begin
;	if is_empty( out ) EQ 0 AND new_val NE 0 then begin

		if error EQ 0 then begin
			;; Store the new value, if desired
			if NOT keyword_set(DONOTSET) then begin
				fire_set, data, new_val, _EXTRA = keys
			endif
			;; Change the returned value
			val = new_val  ;; change the returned value
		endif

		;; warn the user of the change
		if NOT keyword_set(DONOTSET) AND NOT keyword_set(QUIET) then print, out

	endif


	;; return the determined value
	RETURN, strtrim(val,2)

END

