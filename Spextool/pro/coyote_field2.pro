;+
; NAME:
;   COYOTE_FIELD
;
; PURPOSE:
;
;   The purpose of this compound widget is to provide an alternative
;   to the CW_FIELD widget offered in the IDL distribution. What has
;   always annoyed me about CW_FIELD is that the text widgets do not
;   look editable to the users on Windows platforms. This program
;   corrects that deficiency and adds some features that I think
;   would be helpful. For example, you can now assign an event handler
;   to the compound widget.
;
; AUTHOR:
;   FANNING SOFTWARE CONSULTING
;   David Fanning, Ph.D.
;   2642 Bradbury Court
;   Fort Collins, CO 80521 USA
;   Phone: 970-221-0438
;   E-mail: davidf@dfanning.com
;   Coyote's Guide to IDL Programming: http://www.dfanning.com/
;
; CATEGORY:
;
;   General programming.
;
; CALLING SEQUENCE:
;
;   fieldID = COYOTE_Field(parent, Title='X Size: ", Value=256, /IntegerValue)
;
; INPUT PARAMETERS:
;
;   parent -- The parent widget ID of the compound widget. Required.
;
; INPUT KEYWORDS:
;
;   Column -- Set this keyword to have the Label Widget above the Text Widget.
;   CR_Only -- Set this keyword if you only want Carriage Return events. If
;              this keyword is not set, all events are returned. No events
;              are returned unless the EVENT_PRO or EVENT_FUNC keywords are used.
;   DoubleValue -- Set this keyword if you want DOUBLE values returned.
;   Decimal -- Set this keyword to the number of digits to the right of the decimal
;              point in FLOATVALUE and DOUBLEVALUE numbers.
;   Digits -- Set this keyword to the number of digits permitted in INTERGERVALUE and LONGVALUE numbers.
;   Event_Func -- Set this keyword to the name of an Event Function. If this
;                 keyword is undefined and the Event_Pro keyword is undefined,
;                 all compound widget events are handled internally and not
;                 passed on to the parent widget.
;   Event_Pro -- Set this keyword to the name of an Event Procedure. If this
;                keyword is undefined and the Event_Func keyword is undefined,
;                all compound widget events are handled internally and not
;                passed on to the parent widget.
;   FieldFont -- The font name for the text in the Text Widget.
;   FloatValue -- Set this keyword for FLOAT values.
;   Frame -- Set this keyword to put a frame around the compound widget.
;   IntegerValue -- Set this keyword for INTEGER values.
;   LabelFont -- The font name for the text in the Label Widget.
;   LabelSize -- The X screen size of the Label Widget.
;   LongValue -- Set this keyword for LONG values.
;   Row=row -- Set this keyword to have the Label beside the Text Widget. (The default.)
;   Scr_XSize -- The X screen size of the compound widget.
;   Scr_YSize -- The Y screen size of the compound widget.
;   StringValue -- Set this keyword for STRING values. (The default.)
;   Title -- The text to go on the Label Widget.
;   UValue -- A user value for any purpose.
;   Value -- The "value" of the compound widget.
;   XSize -- The X size of the Text Widget.
;
; COMMON BLOCKS:
;
;   None.
;
; RESTRICTIONS:
;
;   None.
;
; EVENT STRUCTURE:
;
;   All events are handled internally unless either the Event_Pro or Event_Func
;   keywords are used to assign an event handler to the compound widget. By
;   default all events generated by the text widget are passed to the assigned
;   event handler. If you wish to receive only Carriage Return events, set the
;   CR_Only keyword.
;
;   event = { COYOTE_FIELD, $      ; The name of the event structure.
;             ID: 0L, $            ; The ID of the compound widget's top-level base.
;             TOP: 0L, $           ; The widget ID of the top-level base of the hierarchy.
;             HANDLER: 0L, $       ; The event handler ID. Filled out by IDL.
;             Value: Ptr_New(), $  ; A pointer to the widget value.
;             Type:""              ; A string indicating the type of data in the VALUE field.
;           }                      ; Values are "INT", "LONG", "FLOAT", "DOUBLE", or "STRING".
;
; EXAMPLE:
;
;   An example program is provided at the end of the COYOTE_FIELD code. To run it,
;   type these commands:
;
;      IDL> .Compile COYOTE_Field
;      IDL> Example
;
; MODIFICATION HISTORY:
;
;   Written by: David Fanning, 17 NOV 1999.
;   Added check to make float and double values finite. 18 NOV 1999. DWF.
;   Fixed a bug when selecting and deleting all numerical text. 19 NOV 1999. DWF.
;   Added DECIMAL and DIGITS keywords. 2 Jan 2000. DWF.
;   Added the POSITIVE keyword. 12 Jan 2000. DWF.
;   Fixed a few minor bugs with delete and digits. 12 Jan 2000. DWF.
;   Made GET_VALUE function return pointer to data, instead of data. 12 Jan 2000. DWF.
;   Fixed a small typo: "aveDecimal" to "haveDecimal". 10 March 2000. DWF.
;-
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright � 2000 Fanning Software Consulting.
;
; This software is provided "as-is", without any express or
; implied warranty. In no event will the authors be held liable
; for any damages arising from the use of this software.
;
; Permission is granted to anyone to use this software for any
; purpose, including commercial applications, and to alter it and
; redistribute it freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must
;    not claim you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation
;    would be appreciated, but is not required.
;
; 2. Altered source versions must be plainly marked as such, and must
;    not be misrepresented as being the original software.
;
; 3. This notice may not be removed or altered from any source distribution.
;
; For more information on Open Source Software, visit the Open Source
; web site: http://www.opensource.org.
;
;###########################################################################


Function COYOTE_Field_ReturnValue, inputValue, dataType

; This utility routine takes a string and turns it into a number,
; depending upon the required data type.

ON_IOERROR, CatchIt

IF (Byte(inputValue))[0] EQ 32B THEN RETURN, ""

CASE dataType OF
   'INT': IF inputValue EQ "" OR inputValue EQ "-" OR inputValue EQ "+" THEN $
      retValue = 'NULLVALUE' ELSE retValue = Fix(inputValue)
   'LONG': IF inputValue EQ "" OR inputValue EQ "-" OR inputValue EQ "+" THEN $
      retValue = 'NULLVALUE' ELSE retValue = Long(inputValue)
   'FLOAT' : IF inputValue EQ "" OR inputValue EQ "-" OR inputValue EQ "+" THEN $
      retValue = 'NULLVALUE' ELSE retValue = Float(inputValue)
   'DOUBLE': IF inputValue EQ "" OR inputValue EQ "-" OR inputValue EQ "+" THEN $
      retValue = 'NULLVALUE' ELSE retValue = Double(inputValue)
   'STRING' : retValue = inputValue
ENDCASE
RETURN, retValue

CatchIt:
   retValue = 'NULLVALUE'
   RETURN, retValue
END ;----------------------------------------------------------------------------



Function COYOTE_Field_Validate, value, dataType, Decimal=decimal, Digits=digits, $
   Positive=positive

; This function eliminates illegal characters from a string that represents
; a number. The return value is a properly formatted string that can be turned into
; an INT, LONG, FLOAT, or DOUBLE value.
;
; + 43B
; - 45B
; . 46B
; 0 - 9 48B -57B
; 'eEdD' [101B, 69B, 100B, 68B]

   ; A null string should be returned at once.

IF N_Elements(value) EQ 0 THEN value = ""
value = value[0]
IF value EQ "" THEN RETURN, String(value)

   ; No leading or trainnig blank characters to evaluate.

value = StrTrim(value, 2)

IF N_Elements(dataType) EQ 0 THEN dataType = 'STRING'

   ; A string value should be returned at once. Nothing to check.

IF StrUpCase(dataType) EQ 'STRING' THEN RETURN, value

   ; Check integers and longs. A "-" or "+" in the first character is allowed. Otherwise,
   ; only number between 0 and 9, or 43B to 57B.

IF StrUpCase(dataType) EQ 'INT' OR StrUpCase(dataType) EQ 'LONG' THEN BEGIN

   returnValue = Ptr_New(/Allocate_Heap)
   asBytes = Byte(value)
   IF positive THEN BEGIN
      IF (asBytes[0] EQ 43B) OR $
         (asBytes[0] GE 48B AND asBytes[0] LE 57B) THEN *returnValue = [asBytes[0]]
   ENDIF ELSE BEGIN
      IF (asBytes[0] EQ 45B) OR (asBytes[0] EQ 43B) OR $
         (asBytes[0] GE 48B AND asBytes[0] LE 57B) THEN *returnValue = [asBytes[0]]
   ENDELSE
   length = StrLen(asBytes)
   IF length EQ 1 THEN BEGIN
      IF N_Elements(*returnValue) EQ 0 THEN  *returnValue = [32B] ELSE $
            *returnValue = [asBytes[0]]
   ENDIF ELSE BEGIN
      FOR j=1,length-1 DO BEGIN
         IF (asBytes[j] GE 48B AND asBytes[j] LE 57B) THEN BEGIN
            IF N_Elements(*returnValue) EQ 0 THEN  *returnValue = [asBytes[j]] ELSE $
               *returnValue = [*returnValue, asBytes[j]]
         ENDIF
      ENDFOR
  ENDELSE
  IF N_Elements(*returnValue) NE 0 THEN retValue = String(*returnValue) ELSE retValue = ""
  Ptr_Free, returnValue

      ; Check for digit restrictions.

  IF digits GT 0 THEN BEGIN
      retValue = StrTrim(retValue, 2)
      IF StrMid(retValue, 0, 1) EQ "-" THEN digits = digits + 1
      retValue = StrMid(retValue, 0, digits)
  ENDIF

  RETURN, retValue

ENDIF

   ; Check floating and double values. (+,-) in first character or after 'eEdD'.
   ; Only numbers, signs, decimal points, and 'eEdD' allowed.

IF StrUpCase(dataType) EQ 'FLOAT' OR StrUpCase(dataType) EQ 'DOUBLE' THEN BEGIN
   returnValue = Ptr_New(/Allocate_Heap)
   asBytes = Byte(value)
   IF positive THEN BEGIN
      IF (asBytes[0] EQ 43B) OR $
         (asBytes[0] GE 48B AND asBytes[0] LE 57B) OR $
         (asBytes[0] EQ 46B) THEN *returnValue = [asBytes[0]]
      IF (asBytes[0] EQ 46B) THEN haveDecimal = 1 ELSE haveDecimal = 0
   ENDIF ELSE BEGIN
      IF (asBytes[0] EQ 45B) OR (asBytes[0] EQ 43B) OR $
         (asBytes[0] GE 48B AND asBytes[0] LE 57B) OR $
         (asBytes[0] EQ 46B) THEN *returnValue = [asBytes[0]]
      IF (asBytes[0] EQ 46B) THEN haveDecimal = 1 ELSE haveDecimal = 0
   ENDELSE
   haveExponent = 0
   length = StrLen(asBytes)
   prevByte = asBytes[0]
   exponents = Byte('eEdD')
   IF length EQ 1 THEN BEGIN
      IF N_Elements(*returnValue) EQ 0 THEN  *returnValue = [32B] ELSE $
            *returnValue = [asBytes[0]]
   ENDIF ELSE BEGIN
      FOR j=1,length-1 DO BEGIN
         IF (asBytes[j] GE 48B AND asBytes[j] LE 57B) THEN BEGIN
            IF N_Elements(*returnValue) EQ 0 THEN  *returnValue = [asBytes[j]] ELSE $
               *returnValue = [*returnValue, asBytes[j]]
            prevByte = asBytes[j]
         ENDIF ELSE BEGIN

            ; What kind of thing is it?

            IF (asBytes[j] EQ 46B) THEN BEGIN ; A decimal point.
               IF haveDecimal EQ 0 THEN BEGIN
                  *returnValue = [*returnValue, asBytes[j]]
                  haveDecimal = 1
                  prevByte = asBytes[j]
               ENDIF
            ENDIF

            IF (asBytes[j] EQ 45B) OR (asBytes[j] EQ 43B) THEN BEGIN ; A + or - sign.
               index = Where(exponents EQ prevByte, count)
               IF count EQ 1 AND haveExponent THEN BEGIN
                  *returnValue = [*returnValue, asBytes[j]]
                  haveDecimal = 1
                  prevByte = asBytes[j]
               ENDIF
            ENDIF

            index = Where(exponents EQ asBytes[j], count)
            IF count EQ 1 AND haveExponent EQ 0 THEN BEGIN ; An exponent
               *returnValue = [*returnValue, asBytes[j]]
               haveExponent = 1
               prevByte = asBytes[j]
            ENDIF
         ENDELSE
      ENDFOR
   ENDELSE
   IF N_Elements(*returnValue) NE 0 THEN BEGIN

      retValue = String(*returnValue)
      retValue = StrTrim(retValue, 2)

               ; Check for decimal restrictions

      IF decimal GE 0 THEN BEGIN
         theDecimalPt = StrPos(retValue, '.')
         IF theDecimalPt NE -1 THEN retValue = StrMid(retValue, 0, theDecimalPt + decimal + 1)
      ENDIF

   ENDIF ELSE retValue = ""
   Ptr_Free, returnValue

      ; Is this a representable number?

   testValue = COYOTE_Field_ReturnValue(retValue, dataType)
   IF String(testValue) NE 'NULLVALUE' THEN numCheck = Finite(testValue) ELSE numCheck = 1
   IF numCheck THEN BEGIN
      RETURN, retValue
   ENDIF ELSE BEGIN
      Message, 'The requested number is not representable.', /Informational
      RETURN, ""
   ENDELSE
ENDIF

END ;----------------------------------------------------------------------------



Pro COYOTE_Field__Define

; The COYOTE_Field Event Structure.

   event = { COYOTE_FIELD, $      ; The name of the event structure.
             ID: 0L, $            ; The ID of the compound widget's top-level base.
             TOP: 0L, $           ; The widget ID of the top-level base of the hierarchy.
             HANDLER: 0L, $       ; The event handler ID. Filled out by IDL.
             Value: Ptr_New(), $  ; A pointer to the widget value.
             Type:"" $            ; A string indicating the type of data in the VALUE field.
           }                      ; Values are "INT", "LONG", "FLOAT", "DOUBLE", or "STRING".

END ;----------------------------------------------------------------------------



Pro COYOTE_Field_Kill_Notify, ID

; This routine cleans up the pointer when the compound widget is destroyed.

Widget_Control, ID, Get_UValue=info, /No_Copy
Ptr_Free, info.theValue
END ;----------------------------------------------------------------------------



Pro COYOTE_Field_Set_Value, cw_tlb, value

; This procedure sets a value for the compound widget. The value
; is a value appropriate for the data type or a string.

   ; Get info structure.

info_carrier = Widget_Info(cw_tlb, Find_by_UName='INFO_CARRIER')
Widget_Control, info_carrier, Get_UValue=info, /No_Copy

   ; Validate the value.

theText = Strtrim(value, 2)
theText = COYOTE_Field_Validate(theText, info.dataType, Decimal=info.decimal, $
   Digits=info.digits, Positive=info.positive)

   ; Load the value in the widget.

Widget_Control, info.textID, Set_Value=theText, Set_Text_Select=[StrLen(theText),0]
info.theText = theText

   ; Set the actual value of the compound widget.

*info.theValue = COYOTE_Field_ReturnValue(info.theText, info.dataType)
Widget_Control, info_carrier, Set_UValue=info, /No_Copy
END ;----------------------------------------------------------------------------



Function COYOTE_Field_Get_Value, cw_tlb

; This function returns the numerical or string value of the
; compound widget.

info_carrier = Widget_Info(cw_tlb, Find_by_UName='INFO_CARRIER')
Widget_Control, info_carrier, Get_UValue=info, /No_Copy
value = info.theValue
Widget_Control, info_carrier, Set_UValue=info, /No_Copy
RETURN, value
END ;----------------------------------------------------------------------------




PRO COYOTE_Field_Event_Handler, event

; The main event handler for the compound widget.

   ; Get the info structure. Get the previous text, the current
   ; cursor location in the text widget, and indicate this is not
   ; a Carriage Return event.

Widget_Control, event.ID, Get_UValue=info, /No_Copy
previousText = info.theText
textLocation = Widget_Info(event.id, /Text_Select)
cr_event = 0

   ; What kind of event is this?

possibleTypes = ['INSERT SINGLE CHARACTER', 'INSERT MULTIPLE CHARACTERS', 'DELETE TEXT', 'SELECT TEXT']
thisType = possibleTypes[event.type]

   ; Branch on event type.

CASE thisType OF

   'INSERT SINGLE CHARACTER': BEGIN

            ; Get the current contents of text widget. Validate it.

         Widget_Control, info.textID, Get_Value=newText
         newText = newText[0]
         validText = COYOTE_Field_Validate(newText, info.dataType, Decimal=info.decimal, $
               Digits=info.digits, Positive=info.positive)

            ; If it is valid, leave it alone. If not, go back to previous text.

         IF validText NE newText THEN BEGIN
            Widget_Control, info.textID, Set_Value=previousText, Set_Text_Select=[textLocation[0]-1,0]
         ENDIF ELSE BEGIN
            info.theText = validText
            testValue  = COYOTE_Field_ReturnValue(validText, info.dataType)
            IF String(testValue) EQ "NULLVALUE" THEN BEGIN
               Ptr_Free, info.theValue
               info.theValue = Ptr_New(/Allocate_Heap)
            ENDIF ELSE *info.theValue = testValue
         ENDELSE

            ; Is this a Carriage Return event?

         IF event.ch EQ 10B then cr_event = 1
      ENDCASE

   'INSERT MULTIPLE CHARACTERS': BEGIN

            ; Same thing as above, but for all the characters you are inserting.

         Widget_Control, info.textID, Get_Value=newText
         newText = newText[0]
         validText = COYOTE_Field_Validate(newText, info.dataType, Decimal=info.decimal, $
            Digits=info.digits, Positive=info.positive)
         IF validText NE newText THEN BEGIN
            Widget_Control, info.textID, Set_Value=previousText, Set_Text_Select=[textLocation[0]-1,0]
         ENDIF ELSE BEGIN
            info.theText = validText
            testValue  = COYOTE_Field_ReturnValue(validText, info.dataType)
            IF String(testValue) EQ "NULLVALUE" THEN BEGIN
               Ptr_Free, info.theValue
               info.theValue = Ptr_New(/Allocate_Heap)
            ENDIF ELSE *info.theValue = testValue
         ENDELSE
      ENDCASE

   'DELETE TEXT': BEGIN

            ; Just get the new text and update the info stucture.

         Widget_Control, info.textID, Get_Value=theText
         theText = theText[0]
         validText = COYOTE_Field_Validate(theText, info.dataType, Decimal=info.decimal, $
            Digits=info.digits, Positive=info.positive)

           ; Load the valid text.

        Widget_Control, info.textID, Set_Value=validText, Set_Text_Select=[textLocation[0],0]
        info.theText = validText
        testValue  = COYOTE_Field_ReturnValue(info.theText, info.dataType)
        IF String(testValue) EQ "NULLVALUE" THEN BEGIN
            Ptr_Free, info.theValue
            info.theValue = Ptr_New(/Allocate_Heap)
        ENDIF ELSE *info.theValue = testValue
      ENDCASE

   'SELECT TEXT': ; Nothing to do.

ENDCASE

   ; Do you report all events, or only Carriage Return events?

IF info.cr_only THEN BEGIN
   IF info.event_func NE "" THEN BEGIN
      thisEvent = {COYOTE_Field, info.cw_tlb, event.top, 0L, info.theValue, info.dataType}
      IF cr_event THEN Widget_Control, info.cw_tlb, Send_Event=thisEvent
   ENDIF

   IF info.event_pro NE "" THEN BEGIN
      thisEvent = {COYOTE_Field, info.cw_tlb, event.top, 0L, info.theValue, info.dataType}
      IF cr_event THEN Widget_Control, info.cw_tlb, Send_Event=thisEvent
   ENDIF
ENDIF ELSE BEGIN
   IF info.event_func NE "" THEN BEGIN
      thisEvent = {COYOTE_Field, info.cw_tlb, event.top, 0L, info.theValue, info.dataType}
      Widget_Control, info.cw_tlb, Send_Event=thisEvent
   ENDIF

   IF info.event_pro NE "" THEN BEGIN
      thisEvent = {COYOTE_Field, info.cw_tlb, event.top, 0L, info.theValue, info.dataType}
      Widget_Control, info.cw_tlb, Send_Event=thisEvent
   ENDIF
ENDELSE

   ; Out of here.

Widget_Control, event.ID, Set_UValue=info, /No_Copy
END ;----------------------------------------------------------------------------



Function COYOTE_Field2, $          ; The compound widget COYOTE_Field.
   parent, $                      ; The parent widget. Required for all compound widgets.
   Column=column, $               ; Set this keyword to have Label above Text Widget.
   CR_Only=cr_only, $             ; Set this keyword if you only want Carriage Return events.
   Digits=digits, $               ; Set this keyword to number of allowed digits in INT and LONG values.
   Decimal=decimal, $             ; Set to the number of digits to right of decimal point.
   DoubleValue=doublevalue, $     ; Set this keyword if you want DOUBLE values returned.
   Event_Func=event_func, $       ; Set this keyword to the name of an Event Function.
   Event_Pro=event_pro, $         ; Set this keyword to the name of an Event Procedure.
   FieldFont=fieldfont, $         ; The font name for the text in the Text Widget.
   FloatValue=floatvalue, $       ; Set this keyword for FLOAT values.
   Frame=frame, $                 ; Set this keyword to put a frame around the compound widget.
   IntegerValue=integervalue, $   ; Set this keyword for INTEGER values.
   LabelFont=labelfont, $         ; The fon name for the text in the Label Widget.
   LabelSize=labelsize, $         ; The X screen size of the Label Widget.
   LongValue=longvalue, $         ; Set this keyword for LONG values.
   Positive=positive, $           ; Set this keyword to only allow positive number values.
   Row=row, $                     ; Set this keyword to have the Label beside the Text Widget. (The default.)
   Scr_XSize=scr_xsize, $         ; The X screen size of the compound widget.
   Scr_YSize=scr_ysize, $         ; The Y screen size of the compound widget.
   StringValue=stringvalue, $     ; Set this keyword for STRING values. (The default.)
   Title=title, $                 ; The text to go on the Label Widget.
   UValue=uvalue, $               ; A user value for any purpose.
   Value=value, $                 ; The "value" of the compound widget.
   XSize=xsize,$                    ; The X size of the Text Widget.
   textID=textID

   ; A parent is required.

IF N_Elements(parent) EQ 0 THEN BEGIN
   Message, 'A PARENT argument is required. Returning...', /Informational
   RETURN, -1L
ENDIF

   ; Check keyword values.

IF N_Elements(column) EQ 0 THEN column = 0
IF N_Elements(digits) EQ 0 THEN digits = 0 ELSE digits = Fix(digits)
IF N_Elements(decimal) EQ 0 THEN decimal = -1 ELSE decimal = Fix(decimal)
IF N_Elements(event_func) EQ 0 THEN event_func = ""
IF N_Elements(event_pro) EQ 0 THEN event_pro = ""
IF N_Elements(fieldfont) EQ 0 THEN fieldfont = ""
IF N_Elements(frame) EQ 0 THEN frame = 0
IF N_Elements(labelfont) EQ 0 THEN labelfont = ""
IF N_Elements(labelsize) EQ 0 THEN labelsize = 0
IF N_Elements(scr_xsize) EQ 0 THEN scr_xsize = 0
IF N_Elements(scr_ysize) EQ 0 THEN scr_ysize = 0
IF N_Elements(title) EQ 0 THEN title = "Input Value: "
IF N_Elements(uvalue) EQ 0 THEN uvalue = ""
IF N_Elements(value) EQ 0 THEN value = "" ELSE value = StrTrim(value,2)
IF N_Elements(xsize) EQ 0 THEN xsize = 0
IF N_Elements(row) EQ 0 AND column EQ 0 THEN row = 1 ELSE row = 0
positive = Keyword_Set(positive)

   ; What data type are we looking for?

dataType = 'STRING'
IF Keyword_Set(stringvalue) THEN dataType = 'STRING'
IF Keyword_Set(integervalue) THEN dataType = 'INT'
IF Keyword_Set(longvalue) THEN dataType = 'LONG'
IF Keyword_Set(floatvalue) THEN dataType = 'FLOAT'
IF Keyword_Set(doublevalue) THEN dataType = 'DOUBLE'

   ; Validate the input value.

value = COYOTE_Field_Validate(value, dataType, Decimal=decimal, Digits=digits, Positive=positive)

   ; Create the widgets.

cw_tlb = Widget_Base( parent, $               ; The top-level base of the compound widget.
   Pro_Set_Value='COYOTE_Field_Set_Value', $
   Func_Get_Value='COYOTE_Field_Get_Value', $
   Frame=frame, $
   Row=row, $
   Column=Keyword_Set(column), $
   Base_Align_Center=1, $
   UValue=uvalue, $
   Event_Pro=event_pro, $
   Event_Func=event_func )

labelID = Widget_Label( cw_tlb, Value=title, Font=labelfont, $ ; The Label Widget.
  Scr_XSize=labelsize)

textID = Widget_Text( cw_tlb, $  ; The Text Widget.
   Value=value, $
   XSize=xsize, $
   YSize=1, $
   Scr_XSize=scr_xsize, $
   Scr_YSize=scr_ysize, $
   Font=fieldfont, $
   All_Events=1, $
   Event_Pro='COYOTE_Field_Event_Handler', $
   UName='INFO_CARRIER', $
   Kill_Notify='COYOTE_Field_Kill_Notify', $
   Editable=1 )

   ; Set the actual return value of the compound widget.

theValue = COYOTE_Field_ReturnValue(value, dataType)

   ; The info structure.

info = { theText:value, $                  ; The text in the Text Widget.
         theValue:Ptr_New(theValue), $     ; The real value of the Text Widget.
         cw_tlb:cw_tlb, $                  ; The top-level base of the compound widget.
         event_func:event_func, $          ; The name of the event handler function.
         event_pro:event_pro, $            ; The name of the event handler procedure.
         cr_only:Keyword_Set(cr_only), $   ; A flag to return events only on CR events.
         dataType:dataType, $              ; The type of data wanted in the compound widget.
         decimal:decimal, $                ; The number of digits in decimal numbers.
         digits:digits, $                  ; The number of digits in integer numbers.
         positive:positive, $              ; Flag to indicate positive number values.
         textID:textID }                   ; The widget identifier of the Text Widget.

    ; Store info structure in Text Widget.

Widget_Control, textID, Set_UValue=info, /No_Copy
RETURN, cw_tlb
END ;----------------------------------------------------------------------------



PRO Example_Event, event

; An example event handler for COYOTE_Field.

Widget_Control, event.top, Get_UValue=info
Widget_Control, event.id, Get_UValue=thisEvent
CASE thisEvent OF
   'Field 1 Event': BEGIN
      Print, ''
      Print, 'Field 1 Event Value: ', *event.value
      END
   'Field 2 Event': BEGIN
      Print, ''
      IF N_Elements(*event.value) EQ 0 THEN Print,'Field 2 is Undefined' ELSE $
         Print, 'Field 2 Event Value: ', *event.value
      END
   'Print It': BEGIN
      Widget_Control, info.field3, Get_Value=theValue
      Print, ''
      Print, 'Field 3 Value: ', theValue
      END
   'PrintFloat': BEGIN
      Widget_Control, info.field2, Get_Value=theValue
      IF N_Elements(*theValue) EQ 0 THEN Print, 'Field 2 Value is Undefined' ELSE $
         Print, 'Field 2 Value: ', *theValue
      END
   'Set It': BEGIN
      Widget_Control, info.field3, Set_Value='Coyote Rules!'
      END
   'Quit': Widget_Control, event.top, /Destroy
ENDCASE
END ;----------------------------------------------------------------------------



PRO Example

; An example program to exercise some of the features of COYOTE_FIELD.
; All events are returned for Field 1, which only allows INTEGER values.
; Only Carriage Return events are returned for Field 2, which allows FLOAT values.
; Field 3 allows you to obtain and set values through the normal WIDGET_CONTROL mechanism.

tlb = Widget_Base(Column=1)
field1 = COYOTE_Field(tlb, Title='Integer:', LabelSize=50, digits=4, $
   Value=5, /IntegerValue, Event_Pro='Example_Event', UValue='Field 1 Event')
field2 = COYOTE_Field(tlb, Title='Float:', LabelSize=50, Value=45.6, $
   /FloatValue, Event_Pro='Example_Event', /CR_Only, UValue='Field 2 Event', Decimal=3, /Positive)
field3 = COYOTE_Field(tlb, Title='String:', LabelSize=50, Value='Coyote Rules!')
button = Widget_Button(tlb, Value='Print Value of String', UValue="Print It")
button = Widget_Button(tlb, Value='Set Value of String', UValue='Set It')
button = Widget_Button(tlb, Value='Print Floating Value', UValue='PrintFloat')
button = Widget_Button(tlb, Value='Quit', UValue='Quit')
Widget_Control, tlb, /Realize, Set_UValue={field1:field1, field2:field2, field3:field3}
XManager, 'example', tlb, /No_Block
END
