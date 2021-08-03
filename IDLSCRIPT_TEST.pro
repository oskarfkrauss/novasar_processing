;;;;
;; function to run all the steps in batch ot to generate the equivalent batch file .sav when the BATCH_FILE_INPUT keywor is specified .
;; @param temp_dir name of temporary direcrtory where are written some auxiliary working files
;; @param BATCH_FILE_INPUT=batch_file_input KEYWORD the name of save file to generate with the same steps of script 
;; @param START_STEP=start_step KEYWORD the first step to run 
;; @param LAST_STEP=last_step KEYWORD the last step step to run 
;; @return 1 if all the steps are sucess , 0 otherwise
;;;
function  IDLSCRIPT_TEST, $
     workdir,$
     temp_dir,$
     BATCH_FILE_INPUT=batch_file_input,$
     START_STEP=start_step,$
     LAST_STEP=last_step,$
     _EXTRA=_extra

  COMPILE_OPT IDL2

  CATCH, error
  if error ne 0 then begin
    print, !error_state.msg
    return,0
  endif

  aTmp = temp_dir
  ; FILE_MKDIR,aTmp

   ; 1) SARscape batch initialization and temporary directory setting
   SARscape_Batch_Init,Temp_Directory=aTmp
   if (n_elements(start_step) ne 0) then begin
       act_step = start_step
   endif else begin
       act_step = 1
   endelse
   if (n_elements(last_step) ne 0) then begin
      end_step = last_step
   endif else begin
      end_step = 10000L;
   endelse
   preferencesToUse = 'Sentinel TOPSAR (IW - EW)'

   res = fsars_new_restore_default_file(FILE_DEFAULT_NAME=preferencesToUse) 
   if (res ne 'OK') then begin
     print, 'Error restore Preferences : '+preferencesToUse  
     return, 0
   endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create : Import NovaSAR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Note : please change the values set to 'USER_PARAMETER_TO_FILL' with the appropriate value.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; workdir='C:/Users/Oskar.Fraserkrauss/Documents/novasar_processing'

CD, workdir
result = FILE_BASENAME(FILE_SEARCH(workdir + '/input/NovaSAR_01*'))
res_sz = N_ELEMENTS(result)

print, result

FOR I=0, res_sz-1 DO BEGIN

  TIC

  CD, workdir + '/output'
  FILE_MKDIR, result[I]
  
  img_dir=workdir +'/input/'+result[I]
  CD, img_dir
  
  act_step = 1
  print, I
  image1 = img_dir+'/metadata.xml'
  
  output = workdir + '/output'

if (act_step eq  1)and(act_step le end_step) then begin

   module_to_call = 'ImportNovaSARFormat'

   OB = obj_new('SARscapeBatch',Module=module_to_call)
   IF (~OBJ_VALID(OB)) THEN BEGIN
      print, 'Create object fail : '+module_to_call
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF

   OB->SetParam , 'GENERAL_PARAMETERS_CMD.AVAILABLE_MEMORY_SIZE_GB' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.PFA_MAX_ITERATION' , '15.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_RG_POLY_DEGREE' , '3.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_DEGREE' , '2.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_NUMBER' , '50.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.LOAD_IMAGES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DELETE_TEMPORARY_FILES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAKE_TIFF' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.QUICK_LOOK_FORMAT' , 'ql_png'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SATURATION_DEFAULT' , '0.33330000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SARSCAPE_TRACE_LEVEL' , '10.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.RENAME_THE_FILE_USING_PARAMETERS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.INSERT_GEO_POINTS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.GEOCODE_SCENE_LIMIT_INCREMENT' , '1000.0000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAX_INCIDENCE_ANGLE_DIFF_IN_A_SWATH' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_TRACE' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_STEP' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_BAR' , 'OK'
   OB->SetParam , 'MAIN_BASIC_IMPORT_NOVASAR.SARSCAPEENVIRONMENT' , 'IDL_ENVI_ENV'
   temp_value = []
   temp_value = [temp_value, image1]
   OB->SetParam , 'MAIN_BASIC_IMPORT_NOVASAR.INPUT_FILE_LIST' , temp_value
   temp_value = []
   output1 = output +'/'+ result[I] + '/' + result[I]
   temp_value = [temp_value, output1]
   OB->SetParam , 'MAIN_BASIC_IMPORT_NOVASAR.OUTPUT_FILE_LIST' , temp_value
   OB->SetParam , 'MAIN_BASIC_IMPORT_NOVASAR.APPLY_CALIBRATION_CONSTANT_FLAG' , 'NotOK'

   ; Verify the parameters
   ok = OB->VerifyParams(Silent=0)
   IF ~ok THEN BEGIN
      print, 'Module can not be executed; Some parameters need to be filled  ['+module_to_call+'] FAIL!'
      continue
      SARscape_Batch_Exit
      RETURN, 0
      
   ENDIF
   ; Process execution
   if (n_elements(batch_file_input) gt 0) then begin
     temp_res =   SARscape_add_in_batch(OB, BATCH_FILE_INPUT=batch_file_input)
   endif else begin
      OK = OB->Execute();
      IF OK THEN BEGIN
          print, 'Success execution ['+module_to_call+'] !'
      ENDIF else begin
         aErrCode = ''
         aOutMsg = get_SARscape_error_string('NotOK',ERROR_CODE=aErrCode)
         aOutMsg = get_SARscape_error_string('OK',ERROR_CODE=aErrCode)
         print, 'FAIL Execution ['+module_to_call+'] EC ['+aErrCode+'] : ['+aOutMsg+']'
        SARscape_Batch_Exit
        continue
        RETURN, 0
      ENDELSE
   endelse
   act_step = (act_step+1);
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create : Basic Multilooking
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Note : please change the values set to 'USER_PARAMETER_TO_FILL' with the appropriate value.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if (act_step eq  2)and(act_step le end_step) then begin

   module_to_call = 'BaseMultilooking'

   OB = obj_new('SARscapeBatch',Module=module_to_call)
   IF (~OBJ_VALID(OB)) THEN BEGIN
      print, 'Create object fail : '+module_to_call
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF

   OB->SetParam , 'GENERAL_PARAMETERS_CMD.AVAILABLE_MEMORY_SIZE_GB' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.PFA_MAX_ITERATION' , '15.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_RG_POLY_DEGREE' , '3.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_DEGREE' , '2.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_NUMBER' , '50.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.LOAD_IMAGES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DELETE_TEMPORARY_FILES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAKE_TIFF' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.QUICK_LOOK_FORMAT' , 'ql_png'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SATURATION_DEFAULT' , '0.33330000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SARSCAPE_TRACE_LEVEL' , '10.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.RENAME_THE_FILE_USING_PARAMETERS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.INSERT_GEO_POINTS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.GEOCODE_SCENE_LIMIT_INCREMENT' , '1000.0000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAX_INCIDENCE_ANGLE_DIFF_IN_A_SWATH' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_TRACE' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_STEP' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_BAR' , 'OK'
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.SARSCAPEENVIRONMENT' , 'IDL_ENVI_ENV'
   temp_value = []
   input1 = output1 + '_HH_slc'
   temp_value = [temp_value, input1]
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.INPUT_FILE_LIST' , temp_value
   temp_value = []
   output2 = input1 + '_pwr'
   temp_value = [temp_value, output2]
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.OUTPUT_FILE_LIST' , temp_value
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.MULTILOOK_METHOD' , 'time_domain'
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.KAISER_WIN_COEFF' , '2.0000000'
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.RANGE_MULTILOOK' , '1.0000000'
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.AZIMUTH_MULTILOOK' , '3.0000000'
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.CUT_DUMMY_MIN_PIXEL' , '-1.0000000'
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.GRID_SIZE_FOR_SUGGESTED_LOOKS' , '15.000000'
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.FILL_DUMMY_FLAG' , 'OK'
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.FILL_DUMMY_METHOD' , 'mean_image_value'
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.ROWS_WINDOW_NUMBER' , '3.0000000'
   OB->SetParam , 'MAIN_BASIC_MULTILOOKING.COLS_WINDOW_NUMBER' , '3.0000000'

   ; Verify the parameters
   ok = OB->VerifyParams(Silent=0)
   IF ~ok THEN BEGIN
      print, 'Module can not be executed; Some parameters need to be filled  ['+module_to_call+'] FAIL!'
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF
   ; Process execution
   if (n_elements(batch_file_input) gt 0) then begin
     temp_res =   SARscape_add_in_batch(OB, BATCH_FILE_INPUT=batch_file_input)
   endif else begin
      OK = OB->Execute();
      IF OK THEN BEGIN
          print, 'Success execution ['+module_to_call+'] !'
      ENDIF else begin
         aErrCode = ''
         aOutMsg = get_SARscape_error_string('NotOK',ERROR_CODE=aErrCode)
         aOutMsg = get_SARscape_error_string('OK',ERROR_CODE=aErrCode)
         print, 'FAIL Execution ['+module_to_call+'] EC ['+aErrCode+'] : ['+aOutMsg+']'
         continue
        SARscape_Batch_Exit
        RETURN, 0
      ENDELSE
   endelse
   act_step = (act_step+1);
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create : Filtering  Single Image Conventional
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Note : please change the values set to 'USER_PARAMETER_TO_FILL' with the appropriate value.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if (act_step eq  3)and(act_step le end_step) then begin

   module_to_call = 'DespeckleConventionalSingle'

   OB = obj_new('SARscapeBatch',Module=module_to_call)
   IF (~OBJ_VALID(OB)) THEN BEGIN
      print, 'Create object fail : '+module_to_call
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF

   OB->SetParam , 'GENERAL_PARAMETERS_CMD.AVAILABLE_MEMORY_SIZE_GB' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.PFA_MAX_ITERATION' , '15.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_RG_POLY_DEGREE' , '3.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_DEGREE' , '2.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_NUMBER' , '50.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.LOAD_IMAGES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DELETE_TEMPORARY_FILES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAKE_TIFF' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.QUICK_LOOK_FORMAT' , 'ql_png'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SATURATION_DEFAULT' , '0.33330000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SARSCAPE_TRACE_LEVEL' , '10.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.RENAME_THE_FILE_USING_PARAMETERS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.INSERT_GEO_POINTS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.GEOCODE_SCENE_LIMIT_INCREMENT' , '1000.0000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAX_INCIDENCE_ANGLE_DIFF_IN_A_SWATH' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_TRACE' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_STEP' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_BAR' , 'OK'
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.SARSCAPEENVIRONMENT' , 'IDL_ENVI_ENV'
   temp_value = []
   temp_value = [temp_value, output2]
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.INPUT_FILE_LIST' , temp_value
   temp_value = []
   output3 = output2 + '_fil'
   temp_value = [temp_value, output3]
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.OUTPUT_FILE_LIST' , temp_value
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.FILT_TYPE' , 'Refined Lee'
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.ROWS_WINDOW_NUMBER' , '5.0000000'
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.COLS_WINDOW_NUMBER' , '5.0000000'
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.WIN_MODE_SIZE' , '5.0000000'
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.EQUIVALENT_LOOKS' , '-1.0000000'
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.ITER_NUMBER_EPS' , '2.0000000'
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.DIR_NUMBER_EPS' , '12.000000'
   OB->SetParam , 'MAIN_BASIC_DESPECKLE_CONVENTIONAL_CMD.DETAILS_EPS_FLAG' , 'NotOK'

   ; Verify the parameters
   ok = OB->VerifyParams(Silent=0)
   IF ~ok THEN BEGIN
      print, 'Module can not be executed; Some parameters need to be filled  ['+module_to_call+'] FAIL!'
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF
   ; Process execution
   if (n_elements(batch_file_input) gt 0) then begin
     temp_res =   SARscape_add_in_batch(OB, BATCH_FILE_INPUT=batch_file_input)
   endif else begin
      OK = OB->Execute();
      IF OK THEN BEGIN
          print, 'Success execution ['+module_to_call+'] !'
      ENDIF else begin
         aErrCode = ''
         aOutMsg = get_SARscape_error_string('NotOK',ERROR_CODE=aErrCode)
         aOutMsg = get_SARscape_error_string('OK',ERROR_CODE=aErrCode)
         print, 'FAIL Execution ['+module_to_call+'] EC ['+aErrCode+'] : ['+aOutMsg+']'
         continue
        SARscape_Batch_Exit
        RETURN, 0
      ENDELSE
   endelse
   act_step = (act_step+1);
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create : Digital Elevation Model Extraction SRTM3 V4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Note : please change the values set to 'USER_PARAMETER_TO_FILL' with the appropriate value.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if (act_step eq  4)and(act_step le end_step) then begin

   module_to_call = 'ToolsDEMExtractionSRTM4'

   OB = obj_new('SARscapeBatch',Module=module_to_call)
   IF (~OBJ_VALID(OB)) THEN BEGIN
      print, 'Create object fail : '+module_to_call
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF

   OB->SetParam , 'GENERAL_PARAMETERS_CMD.AVAILABLE_MEMORY_SIZE_GB' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.PFA_MAX_ITERATION' , '15.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_RG_POLY_DEGREE' , '3.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_DEGREE' , '2.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_NUMBER' , '50.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.LOAD_IMAGES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DELETE_TEMPORARY_FILES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAKE_TIFF' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.QUICK_LOOK_FORMAT' , 'ql_png'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SATURATION_DEFAULT' , '0.33330000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SARSCAPE_TRACE_LEVEL' , '10.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.RENAME_THE_FILE_USING_PARAMETERS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.INSERT_GEO_POINTS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.GEOCODE_SCENE_LIMIT_INCREMENT' , '1000.0000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAX_INCIDENCE_ANGLE_DIFF_IN_A_SWATH' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_TRACE' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_STEP' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_BAR' , 'OK'
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_STATE' , 'GEO-GLOBAL'
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_HEMISPHERE' , ''
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_PROJECTION' , 'GEO'
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_ZONE' , ''
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_ELLIPSOID' , 'WGS84'
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_DATUM_SHIFT' , ''
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_REFERENCE_HEIGHT' , '0.0000000'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_PROJECTION_DATUM_FALSE_NORTHING' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_PROJECTION_DATUM_FALSE_EASTING' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_CENTRAL_OF_PROJ_LATITUDE' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_CENTRAL_OF_PROJ_LONGITUDE' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_LATITUDE_OF_TRUE_SCALE' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_SCALE_FACTOR' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_STANDARD_PARALLEL1' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_STANDARD_PARALLEL2' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_SPHERE_RADIUS' , 'USER_OPTIONAL_PARAMETER'
   OB->SetParam , 'DEM_FTP_ADDRESSES.GTOPO_30_FTP_ADDRESS' , 'edcftp.cr.usgs.gov'
   OB->SetParam , 'DEM_FTP_ADDRESSES.GTOPO_30_FTP_LOCAL_PATH' , 'pub/data/gtopo30/global/'
   OB->SetParam , 'DEM_FTP_ADDRESSES.SRTM_VERSION2_FTP_ADDRESS' , 'https://dds.cr.usgs.gov'
   OB->SetParam , 'DEM_FTP_ADDRESSES.SRTM_VERSION2_FTP_LOCAL_PATH_EURASIA' , 'srtm/version2_1/SRTM3/Eurasia/'
   OB->SetParam , 'DEM_FTP_ADDRESSES.SRTM_VERSION2_FTP_LOCAL_PATH_NA' , 'srtm/version2_1/SRTM3/North_America/'
   OB->SetParam , 'DEM_FTP_ADDRESSES.SRTM_VERSION2_FTP_LOCAL_PATH_SA' , 'srtm/version2_1/SRTM3/South_America/'
   OB->SetParam , 'DEM_FTP_ADDRESSES.SRTM_VERSION2_FTP_LOCAL_PATH_AFRICA' , 'srtm/version2_1/SRTM3/Africa/'
   OB->SetParam , 'DEM_FTP_ADDRESSES.SRTM_VERSION2_FTP_LOCAL_PATH_AUSTRALIA' , 'srtm/version2_1/SRTM3/Australia/'
   OB->SetParam , 'DEM_FTP_ADDRESSES.SRTM_VERSION2_FTP_LOCAL_PATH_ISLANDS' , 'srtm/version2_1/SRTM3/Islands/'
   OB->SetParam , 'DEM_FTP_ADDRESSES.SRTM_VERSION4_FTP_ADDRESS' , 'https://srtm.csi.cgiar.org'
   OB->SetParam , 'DEM_FTP_ADDRESSES.SRTM_VERSION4_FTP_LOCAL_PATH' , 'wp-content/uploads/files/srtm_5x5/TIFF/'
   OB->SetParam , 'DEM_FTP_ADDRESSES.RAMP_FTP_ADDRESS' , 'sidads.colorado.edu'
   OB->SetParam , 'DEM_FTP_ADDRESSES.RAMP_FTP_LOCAL_PATH' , 'pub/DATASETS/RAMP/DEM_V2/200M/BINARY/'
   OB->SetParam , 'DEM_FTP_ADDRESSES.AW3D30_FTP_ADDRESS' , 'https://www.eorc.jaxa.jp/ALOS/aw3d30/data/release_v2003/'
   OB->SetParam , 'DEM_FTP_ADDRESSES.AW3D30_HTTP_LOGIN_ADDRESS' , 'https://www.eorc.jaxa.jp/ALOS/en/aw3d30/data/index.htm'
   OB->SetParam , 'SARSNT_PROXY.PROXY_URL' , ''
   OB->SetParam , 'SARSNT_PROXY.PROXY_USERNAME' , ''
   OB->SetParam , 'SARSNT_PROXY.PROXY_PASSWORD' , ''
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.SARSCAPEENVIRONMENT' , 'IDL_ENVI_ENV'
   dem = output3 + '_dem'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.OUTPUT_FILE_DEM_VAL' , dem
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.INT_TYPE_VAL' , '4th_order_cc'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.SLOPE_FLAG_VAL' , 'NotOK'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.EAST_START_VAL' , '0.0000000'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.EAST_END_VAL' , '0.0000000'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.NORTH_START_VAL' , '0.0000000'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.NORTH_END_VAL' , '0.0000000'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.GRID_SIZE_X_VAL' , '90.000000'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.GRID_SIZE_Y_VAL' , '90.000000'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.REPLACE_DUMMY_WITH_MIN_VAL' , 'OK'
   temp_value = []
   temp_value = [temp_value, output3]
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.REFERENCE_SR_IMAGE_VAL' , temp_value
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.SOURCE_DEM_TYPE_VAL' , 'TIF-SRTM-3'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.INTERPOL_WIN_SIZE_VAL' , '7.0000000'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.SUBTRACT_GEOID' , 'OK'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.RELAX_FLAG' , 'NotOK'
   OB->SetParam , 'MAIN_TOOLS_DEM_EXTRACTION_SRTM3_V4_CMD.MAX_FORWARD_BACKWARD_ADMITTED' , '25.000000'

   ; Verify the parameters
   ok = OB->VerifyParams(Silent=0)
   IF ~ok THEN BEGIN
      print, 'Module can not be executed; Some parameters need to be filled  ['+module_to_call+'] FAIL!'
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF
   ; Process execution
   if (n_elements(batch_file_input) gt 0) then begin
     temp_res =   SARscape_add_in_batch(OB, BATCH_FILE_INPUT=batch_file_input)
   endif else begin
      OK = OB->Execute();
      IF OK THEN BEGIN
          print, 'Success execution ['+module_to_call+'] !'
      ENDIF else begin
         aErrCode = ''
         aOutMsg = get_SARscape_error_string('NotOK',ERROR_CODE=aErrCode)
         aOutMsg = get_SARscape_error_string('OK',ERROR_CODE=aErrCode)
         print, 'FAIL Execution ['+module_to_call+'] EC ['+aErrCode+'] : ['+aOutMsg+']'
         continue
        SARscape_Batch_Exit
        RETURN, 0
      ENDELSE
   endelse
   act_step = (act_step+1);
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create : Geocoding and Radiometric Calibration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Note : please change the values set to 'USER_PARAMETER_TO_FILL' with the appropriate value.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if (act_step eq  5)and(act_step le end_step) then begin

   module_to_call = 'BasicGeocoding'

   OB = obj_new('SARscapeBatch',Module=module_to_call)
   IF (~OBJ_VALID(OB)) THEN BEGIN
      print, 'Create object fail : '+module_to_call
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF

   OB->SetParam , 'GENERAL_PARAMETERS_CMD.AVAILABLE_MEMORY_SIZE_GB' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.PFA_MAX_ITERATION' , '15.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_RG_POLY_DEGREE' , '3.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_DEGREE' , '2.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_NUMBER' , '50.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.LOAD_IMAGES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DELETE_TEMPORARY_FILES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAKE_TIFF' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.QUICK_LOOK_FORMAT' , 'ql_png'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SATURATION_DEFAULT' , '0.33330000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SARSCAPE_TRACE_LEVEL' , '10.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.RENAME_THE_FILE_USING_PARAMETERS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.INSERT_GEO_POINTS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.GEOCODE_SCENE_LIMIT_INCREMENT' , '1000.0000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAX_INCIDENCE_ANGLE_DIFF_IN_A_SWATH' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_TRACE' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_STEP' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_BAR' , 'OK'
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_STATE' , 'GEO-GLOBAL'
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_HEMISPHERE' , ''
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_PROJECTION' , 'GEO'
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_ZONE' , ''
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_ELLIPSOID' , 'WGS84'
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_DATUM_SHIFT' , ''
   OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_REFERENCE_HEIGHT' , '0.0000000'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_PROJECTION_DATUM_FALSE_NORTHING' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_PROJECTION_DATUM_FALSE_EASTING' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_CENTRAL_OF_PROJ_LATITUDE' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_CENTRAL_OF_PROJ_LONGITUDE' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_LATITUDE_OF_TRUE_SCALE' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_SCALE_FACTOR' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_STANDARD_PARALLEL1' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_STANDARD_PARALLEL2' , 'USER_OPTIONAL_PARAMETER'
   ;OB->SetParam , 'OUT_CARTOGRAPHIC_SYSTEM.OCS_SPHERE_RADIUS' , 'USER_OPTIONAL_PARAMETER'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.SARSCAPEENVIRONMENT' , 'IDL_ENVI_ENV'
   temp_value = []
   temp_value = [temp_value, output3]
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.INPUT_FILE_LIST' , temp_value
   temp_value = []
   output4 = output3 + '_geo'
   temp_value = [temp_value, output4]
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.OUTPUT_FILE_LIST' , temp_value
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.DEM_FILE_NAME' , dem
   ;OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GCP_FILE_NAME' , 'USER_OPTIONAL_PARAMETER'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_GRID_SIZE_X' , '15.000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_GRID_SIZE_Y' , '15.000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.CALIBRATION_FLAG' , 'NotOK'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEO_SCATTERING_AREA_METHOD' , 'sine_area_estimation'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.TRUE_AREA_EXPONENT' , '1.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.USER_TRUE_AREA_REF_INCIDENCE_ANGLE' , '-1.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.INTERPOLATION_BOX_NBR' , '7.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.MEAN_BOX_NBR' , '5.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.MEDIAN_BOX_NBR' , '5.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.RAD_NORMALIZATION_FLAG' , 'NotOK'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEO_NORM_METHOD_CORRECTION' , 'norm_cosine_correction'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_RESAMPLING_TYPE' , '4th_order_cc'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_ORBIT_INTERPOL' , '10.000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_BLOCK_SIZE' , '30000.000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_OVERLAP_SIZE' , '50.000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_RAD_NORM_DEG' , '2.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_RAD_NORM_ANG' , '-1.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.LINEAR_REGRESSIN_NORMALIZATION_ITER_NBR' , '1.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.LINEAR_REGRESSIN_COL_RESAMPLING' , '10.000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.LINEAR_REGRESSIN_ROW_RESAMPLING' , '100.00000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.LINEAR_REGRESSIN_MIN_DB_VALUE' , '-21.000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.LINEAR_REGRESSIN_MAX_DB_VALUE' , '-1.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.RG_MULT_FACTOR_NEWTON_RESAMPLING' , '3.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.AZ_MULT_FACTOR_NEWTON_RESAMPLING' , '1.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.DEM_ROW_NUMBER_NEWTON_RESAMPLING' , '5000.0000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GENERATE_LIA_FLAG' , 'NotOK'
   ;OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GENERATE_K_FLAG' , 'USER_OPTIONAL_PARAMETER'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GENERATE_LAYOVERSHADOW_FLAG' , 'NotOK'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.USE_LIA_TIME_FLAG' , 'NotOK'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_SIGMA_FLAG' , 'OK'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_GAMMA_FLAG' , 'NotOK'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.GEOCODE_BETA_FLAG' , 'NotOK'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.SLANT_RANGE_PRODUCT_FLAG' , 'NotOK'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.OUTPUT_TYPE' , 'output_type_linear_and_db'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.DB_OUT_MIN_VALUE' , '-9999.0000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.DB_OUT_SCALE_VALUE' , '-9999.0000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.MAX_VALUE_IN_CALIBRATION' , '5.0000000'
   OB->SetParam , 'MAIN_BASIC_CALIBRATION_AND_GEO_CMD.DUMMY_REMOVAL_FLAG' , 'NotOK'

   ; Verify the parameters
   ok = OB->VerifyParams(Silent=0)
   IF ~ok THEN BEGIN
      print, 'Module can not be executed; Some parameters need to be filled  ['+module_to_call+'] FAIL!'
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF
   ; Process execution
   if (n_elements(batch_file_input) gt 0) then begin
     temp_res =   SARscape_add_in_batch(OB, BATCH_FILE_INPUT=batch_file_input)
   endif else begin
      OK = OB->Execute();
      IF OK THEN BEGIN
          print, 'Success execution ['+module_to_call+'] !'
      ENDIF else begin
         aErrCode = ''
         aOutMsg = get_SARscape_error_string('NotOK',ERROR_CODE=aErrCode)
         aOutMsg = get_SARscape_error_string('OK',ERROR_CODE=aErrCode)
         print, 'FAIL Execution ['+module_to_call+'] EC ['+aErrCode+'] : ['+aOutMsg+']'
         continue
        SARscape_Batch_Exit
        RETURN, 0
      ENDELSE
   endelse
   act_step = (act_step+1);
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create : Ship Detection
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Note : please change the values set to 'USER_PARAMETER_TO_FILL' with the appropriate value.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if (act_step eq  6)and(act_step le end_step) then begin

   module_to_call = 'BasicFeShipDetection'

   OB = obj_new('SARscapeBatch',Module=module_to_call)
   IF (~OBJ_VALID(OB)) THEN BEGIN
      print, 'Create object fail : '+module_to_call
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF

   OB->SetParam , 'GENERAL_PARAMETERS_CMD.AVAILABLE_MEMORY_SIZE_GB' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.PFA_MAX_ITERATION' , '15.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_RG_POLY_DEGREE' , '3.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_DEGREE' , '2.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DOPPLER_AZ_POLY_NUMBER' , '50.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.LOAD_IMAGES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.DELETE_TEMPORARY_FILES' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAKE_TIFF' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.QUICK_LOOK_FORMAT' , 'ql_png'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SATURATION_DEFAULT' , '0.33330000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.SARSCAPE_TRACE_LEVEL' , '10.000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.RENAME_THE_FILE_USING_PARAMETERS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.INSERT_GEO_POINTS_FLAG' , 'NotOK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_NAME' , 'Value taken from Preferences'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_PLATFORM_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.OPENCL_DEVICE_ID' , '-1.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.GEOCODE_SCENE_LIMIT_INCREMENT' , '1000.0000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.MAX_INCIDENCE_ANGLE_DIFF_IN_A_SWATH' , '8.0000000'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_TRACE' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_STEP' , 'OK'
   OB->SetParam , 'GENERAL_PARAMETERS_CMD.VERBOSE_BAR' , 'OK'
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.SARSCAPEENVIRONMENT' , 'IDL_ENVI_ENV'
   temp_value = []
   temp_value = [temp_value,output4]
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.INPUT_FILE_LIST' , temp_value
   temp_value = []
   output5 = output4 + '_ships'
   temp_value = [temp_value, output5]
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.OUTPUT_FILE_LIST' , temp_value
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.TARGET_WINDOW_SIZE' , '10.000000'
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.GUARD_WINDOW_SIZE' , '400.00000'
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.BACKGROUND_WINDOW_SIZE' , '1000.0000'
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.PROBABILITY_OF_FALSE_ALARM' , '1.0000000e-13'
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.MINIMUM_MEAN_SIGMA0_DB' , '-2.0000000'
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.MINIMUM_SHIP_PIXELS' , '2.0000000'
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.GENERATE_KML_FLAG' , 'OK'
   Land = 'C:/Users/Oskar.Fraserkrauss/Documents/novasar_processing/Land/ne_10m_land.shp'
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.LAND_MASK_SHAPE_FILE_NAME' , Land
   OB->SetParam , 'MAIN_BASIC_FE_SHIP_DETECTION_CMD.LAND_MASK_BUFFER_METER' , '500.0000'

   ; Verify the parameters
   ok = OB->VerifyParams(Silent=0)
   IF ~ok THEN BEGIN
      print, 'Module can not be executed; Some parameters need to be filled  ['+module_to_call+'] FAIL!'
      continue
      SARscape_Batch_Exit
      RETURN, 0
   ENDIF
   ; Process execution
   if (n_elements(batch_file_input) gt 0) then begin
     temp_res =   SARscape_add_in_batch(OB, BATCH_FILE_INPUT=batch_file_input)
   endif else begin
      OK = OB->Execute();
      IF OK THEN BEGIN
          print, 'Success execution ['+module_to_call+'] !'
      ENDIF else begin
         aErrCode = ''
         aOutMsg = get_SARscape_error_string('NotOK',ERROR_CODE=aErrCode)
         aOutMsg = get_SARscape_error_string('OK',ERROR_CODE=aErrCode)
         print, 'FAIL Execution ['+module_to_call+'] EC ['+aErrCode+'] : ['+aOutMsg+']'
         continue
        SARscape_Batch_Exit
        RETURN, 0
      ENDELSE
   endelse
   act_step = (act_step+1);
endif

  TOC

ENDFOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


   return, 1

end

