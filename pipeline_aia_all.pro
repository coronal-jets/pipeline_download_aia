; Main entry to Jet Analyzer

function pipeline_aia_all, config_file = config_file, work_dir = work_dir, cache_dir = cache_dir, presets_file = presets_file $
                    , fps = fps, no_load = no_load, no_cut = no_cut, no_save_empty = no_save_empty, remote_cutout= remote_cutout $
                    , method = method, graphtype = graphtype, maxtime = maxtime, waves = waves $
                    , warc = warc, harc = harc, use_jpg = use_jpg, use_contour = use_contour 

cand_report = list()
tt = systime(/seconds)
if n_elements(remote_cutout) eq 0 then remote_cutout = 1 ; use remote cutout by default
if n_elements(method) eq 0 then method = 1
if n_elements(use_jpg) eq 0 then use_jpg = 0

pipeline_aia_read_down_config, config, config_file = config_file, waves = waves, warc = warc, harc = harc 
if not keyword_set(work_dir) then cd, current = work_dir
pipeline_aia_dir_tree, work_dir, config, aia_dir_cache, event_rel, aia_dir_wave_sel, obj_dir, vis_data_dir, vis_data_dir_wave, cache_dir = cache_dir, method = method

if ~pipeline_aia_check_dates(config, work_dir+path_sep()+event_rel, maxtime = maxtime) then begin
    print, '******** PROGRAM FINISHED ABNORMALLY, CHECK TIMES IN CONFIG! ********'
    message, 'Incorrect times in config'
    return, cand_report
endif

foreach wave, config.waves, i do begin
    t0 = systime(/seconds)
    if keyword_set(remote_cutout) && ~keyword_set(no_load) then begin
      save_dir = work_dir + path_sep() + aia_dir_wave_sel[i]
      pipeline_aia_download_aia_cutout, wave, save_dir, config
    endif else begin
      if ~keyword_set(no_load) then pipeline_aia_download_aia_full, wave, aia_dir_cache, config
      if ~keyword_set(no_cut) then pipeline_aia_cutout, aia_dir_cache, work_dir, wave, aia_dir_wave_sel[i], config, nofits = nofits, sav = sav
    endelse
    ;message, strcompress(string(systime(/seconds)-t0,format="('******** DOWNLOAD/CUTOFF performed in ',g0,' seconds')")), /cont
    message, '******** DOWNLOAD/CUTOFF performed in ' + asu_sec2hms(systime(/seconds)-t0, /issecs), /info
    if ~keyword_set(method) then begin
        ncand = pipeline_aia_find_candidates_m0(work_dir, aia_dir_wave_sel[i], wave, obj_dir, config, files_in, presets_file = presets_file)
    endif else begin    
        ncand = pipeline_aia_find_candidates(work_dir, aia_dir_wave_sel[i], wave, obj_dir, config, files_in, presets_file = presets_file)
    endelse
    cand_report.Add, {wave:wave, ncand:ncand}    
    t0 = systime(/seconds)
    pipeline_aia_movie_prep_pict, work_dir, obj_dir, wave, aia_dir_wave_sel[i], vis_data_dir_wave[i], details, config, files_in.ToArray() $
                                , use_jpg = use_jpg, use_contour = use_contour, no_save_empty = no_save_empty, graphtype = graphtype
    ;message, strcompress(string(systime(/seconds)-t0,format="('******** PICTURES prepared in ',g0,' seconds')")), /cont
    message, '******** PICTURES prepared in ' + asu_sec2hms(systime(/seconds)-t0, /issecs), /info
    pipeline_aia_make_movie, wave, vis_data_dir_wave[i], vis_data_dir, details, work_dir, config, use_jpg = use_jpg, fps = fps
endforeach

print, '******** PROGRAM FINISHED SUCCESSFULLY, found: ', pipeline_aia_cand_report(cand_report), ' in ', asu_sec2hms(systime(/seconds)-t0, /issecs), ' ********'

return, cand_report

end
