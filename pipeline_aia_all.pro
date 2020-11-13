pro pipeline_aia_all, config_file = config_file, work_dir = work_dir, cache_dir = cache_dir, presets_file = presets_file $
                    , fps = fps, no_load = no_load, no_cut = no_cut, no_save_empty = no_save_empty, remote_cutout= remote_cutout

if n_elements(fps) eq 0 then fps =30

; use remote cutout by default
if n_elements(remote_cutout) eq 0 then remote_cutout = 1

pipeline_aia_read_down_config, config, config_file = config_file 
if not keyword_set(work_dir) then cd, current = work_dir
pipeline_aia_dir_tree, work_dir, config, aia_dir_cache, aia_dir_wave_sel, obj_dir, vis_data_dir, vis_data_dir_wave, cache_dir = cache_dir

foreach wave, config.waves, i do begin
    if keyword_set(remote_cutout) and ~keyword_set(no_load) then begin
      save_dir = work_dir + path_sep() + aia_dir_wave_sel[i]
      pipeline_aia_download_aia_cutout, wave, save_dir, config_file = config_file
    endif else begin
      if ~keyword_set(no_load) then pipeline_aia_download_aia_full, wave, aia_dir_cache, config_file = config_file
      if ~keyword_set(no_cut) then pipeline_aia_cutout, aia_dir_cache, work_dir, wave, aia_dir_wave_sel[i], config_file = config_file, nofits = nofits, sav = sav
    endelse
    pipeline_aia_find_candidates, work_dir, aia_dir_wave_sel[i], wave, obj_dir, config_file = config_file, presets_file = presets_file
    pipeline_aia_movie_prep_pict, work_dir, obj_dir, wave, aia_dir_wave_sel[i], vis_data_dir_wave[i], details, config_file = config_file, no_save_empty = no_save_empty
    pipeline_aia_make_movie, wave, vis_data_dir_wave[i], vis_data_dir, details, work_dir, config_file = config_file, fps = fps
endforeach

print, '******** PROGRAM FINISHED SUCCESSFULLY ********'

end
