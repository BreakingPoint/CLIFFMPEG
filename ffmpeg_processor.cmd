@echo off

rem --- MAIN ---

echo.
echo Simple FFMPEG Action Script - Version 2015.05.14.1

if "%~dpnx1" == "" goto help

set sources=
set result_file=
set path=%~dp0;%path%
set action_type=join
set workpath=%~dp0

set filter_params=
set audio_params=
set stream_params=
set video_params=
set result_filename=
set vidstab_logfile=

set param_s_audio_type=
set param_s_video_type=
set param_s_videoheight=
set param_s_crf=
set param_s_bitrate=
set param_s_fps=
set param_s_resize_mode=
set param_s_aspect=
set param_s_effects=_
set param_s_2pass=N
set param_start_at=
set param_duration=
set param_videochannel=0

rem --- Detect Action Type from parameters

set action_type=

set f1_isaudio=x
set f2_isaudio=x
if "%~dpnx2" == "" (
  set action_type=batch
) else (
  if "%~dpnx3" == "" (
    if /i not "%~x1" == ".wav" if /i not "%~x1" == ".mp3" if /i not "%~x1" == ".m4a" if /i not "%~x1" == ".ogg" set f1_isaudio=
    if /i not "%~x2" == ".wav" if /i not "%~x2" == ".mp3" if /i not "%~x2" == ".m4a" if /i not "%~x2" == ".ogg" set f2_isaudio=
  )
)
if "%f1_isaudio%%f2_isaudio%" == "x" set action_type=replace_audio

if not x%action_type% == x goto action_%action_type%

echo.
echo Do you want to join or batch-process?
echo [J]oin
echo [B]atch (default)
set /p actionselection=^>
set action_type=batch
if /i x%actionselection% == xj set action_type=join

goto action_%action_type%


rem --- JOIN VIDEOS INTO NEW RENDERING

:action_join

  set result_file="%~dpn1.joined_videos.mp4"
  
  title "%~n1"
  
  set maps=
  set maps_sw=
  set /a counter=0
  
  echo.
  echo Videos are joined in following order:
  echo - If you want a different order, sort the files diffently in the file explorer
  echo   and grab the first file in the order.
  
  echo.

  :collect_next_file
  
  echo * "%~nx1"
  set sources=%sources% -i %1
  set maps=%maps%[%counter%:0] [%counter%:1] 
  set maps_sw=%maps_sw%[%counter%:1] [%counter%:0] 
  set /a counter+=1
  shift
  
  if not "%~n1" == "" goto collect_next_file
  
  call :collect_base_params video audio
  
  echo.
  echo Switch Audio/Video channels?
  echo Use only, if you got an audio channel error the first try!
  echo [Y]es
  echo [N]o (default)
  set /p channel_sw=^>
  if /i x%channel_sw% == xy set maps=%maps_sw%
  
  call :render_filtercomplex_params  
  call :render_audio_params 
  call :render_video_params
  call :execute_ffmpeg %result_file%
  
  pause
  
  goto eob


rem --- BATCH-PROCESS VIDEOS INTO NEW RENDERING

:action_batch

  echo.
  if not "%~n2" == "" (
    echo Batch process files:
  ) else (
    echo Process single file:
    echo * "%~nx1"
  )
  
  echo.
  echo What do you want to render? 
  echo [V]ideo file (default)
  echo [A]udio file
  set /p action_batch_mode=^>
  
  if /i x%action_batch_mode% == xa goto action_batch_audio

  set action_batch_mode=v
  
  if not "%~n2" == "" (
    call :collect_base_params video twopass audio
  ) else (
    call :collect_base_params video twopass length audio 
  )
  
  goto render_next_file
  
  :action_batch_audio
  call :collect_base_params audio length
  
  :render_next_file
  
  set result_ext=
  
  if /i not "%action_batch_mode%" == "v" (
    set result_ext=.avi
    if /i x%param_s_audio_type% == xw set result_ext=.wav
    if /i x%param_s_audio_type% == xm set result_ext=.mp3
    if /i x%param_s_audio_type% == xa set result_ext=.m4a
    if /i x%param_s_audio_type% == xo set result_ext=.ogg
    if /i x%param_s_audio_type% == xf set result_ext=.flac
  ) else (
    set result_ext=.mp4
    if /i x%param_s_video_type% == xc set result_ext=%~x1
    if /i x%param_s_video_type% == xm set result_ext=.mpg
    if /i x%param_s_video_type% == xx set result_ext=.avi
    if /i x%param_s_video_type% == xj set result_ext=.jpg
    if /i x%param_s_video_type% == xw set result_ext=.webm
  )

  set result_file="%~dpn1%result_ext%"
  
  if exist %result_file% (
    if /i not "%action_batch_mode%" == "v" (
      set result_file="%~dpn1.audio_extract%result_ext%"
    ) else (
      set result_file="%~dpn1.new_video%result_ext%"
    )
  )
  
  title "%~n1"
  
  call :render_stream_params 
  call :render_audio_params 
  if /i x%action_batch_mode% == xv ( 
    call :render_video_params 
  ) else ( 
    set video_params=-vn 
  )
  
  set sources=%start_at% -i %1
  
  call :execute_ffmpeg %result_file%

  shift
  
  if not "%~n1" == "" goto render_next_file
  
  echo.
  
  pause
  
  goto eob


rem --- REPLACE AUDIO IN VIDEO

:action_replace_audio
  set boxtitle=
  
  rem Detect audio and video file + audio type:
  rem set param_s_audio_type=a
  set audiofileidx=1
  if /i not "%~x1" == ".wav" if /i not "%~x1" == ".mp3" if /i not "%~x1" == ".m4a" if /i not "%~x1" == ".aac" set audiofileidx=2
  
  if %audiofileidx% == 1 (
    set sources=-i "%~dpnx2" -i "%~dpnx1" 
    set result_file="%~dpn2.new_audio%~x2"
    set boxtitle="%~n2"
  ) else (
    set sources=-i "%~dpnx1" -i "%~dpnx2" 
    set result_file="%~dpn1.new_audio%~x1"
    set boxtitle="%~n1"
  )
  
  title %boxtitle%
  
  echo.
  echo Replace audio:
  
  set param_s_video_type=c
  call :collect_base_params audio videochannel

  set filter_params=-map 1:0 -map 0:%param_videochannel%
  call :render_audio_params 
  call :render_video_params 

  call :execute_ffmpeg %result_file%
  
  pause

  goto eob


rem --- SUBROUTINES

:collect_base_params

  if "%1" == "" goto eob
  
  goto collect_base_params__%1
  
  :collect_base_params__video
  
  echo.
  echo Select processing of the video data:
  echo [C]opy source video
  echo [H]264 encoding (default)
  echo [X]Vid encoding
  echo [M]PEG2 encoding
  echo [W]EBM encoding
  echo [J]PEG images sequence
  set /p param_s_video_type=^>
  if /i x%param_s_video_type% == x set param_s_video_type=h
  if /i x%param_s_video_type% == xc goto collect_base_params__next
  if /i x%param_s_video_type% == xj goto collect_base_params__bitrate_end

  echo.
  echo Set video encoding quality by:
  echo [Q]uality (default)
  echo [A]bsolute bitrate
  echo [C]omputed bitrate
  set choice_bitrate=
  set /p choice_bitrate=^>
  if x%choice_bitrate% == x set choice_bitrate=q
  
  if /i x%choice_bitrate% == xa goto collect_base_params__bitrate_a
  if /i x%choice_bitrate% == xc goto collect_base_params__bitrate_c

  echo.
  echo Set video encoding quality 
  echo Values: 0 - 50
  echo 0 is lossless, 50 is very bad quality
  echo empty: 21
  set param_s_bitrate=
  set param_s_crf=
  set /p param_s_crf=^>
  if x%param_s_crf% == x set param_s_crf=21
  goto collect_base_params__bitrate_end
  
  :collect_base_params__bitrate_a
  
  echo.
  echo Enter video encoding bitrate in kilobit
  echo Examples for kilobit values: "150", "3500", "6000"
  echo Empty input causes the using of 1500 kilobit.
  set param_s_bitrate=
  set /p param_s_bitrate=^>
  if x%param_s_bitrate% == x set param_s_bitrate=1500
  goto collect_base_params__bitrate_end

  :collect_base_params__bitrate_c
  
  echo.
  echo Enter size for videodata in kilobytes
  echo Examples: "200.000" (200 MBytes), "500", "1.500.000" (1.5GBytes)
  set _param_destsize=
  set /p _param_destsize=^>
  set _param_destsize=%_param_destsize:.=%

  echo.
  echo Enter length of video in Minutes:Seconds
  echo Examples: "60", "1:30", "120:25"
  set _param_destlength=
  set /p _param_destlength=^>
  set _param_destlength_orig=%_param_destlength%
  set _param_destlength=%_param_destlength::=*60+%
  rem Minutes only? Convert to seconds:
  if  "%_param_destlength%" == "%_param_destlength_orig%" set _param_destlength=%_param_destlength%*60

  rem kb-size / length in seconds = kbytes per second * 8 = kbit per second
  set /a param_s_bitrate = %_param_destsize% / (%_param_destlength%) * 8
  
  echo.
  echo Computed bitrate: %param_s_bitrate%
  
  :collect_base_params__bitrate_end
  
  if "%action_type%" == "join" goto collect_base_params__after_ratio
  
  echo.
  echo Set line height of video
  echo Examples: "360", "480", "720", "1080"
  echo Empty input causes the using of the original videos height.
  set /p param_s_videoheight=^>

  echo.
  echo Set the aspect ratio of the video.
  echo Examples: "4:3", "5:4", "14:9", "16:9", "21:9"
  if x%param_s_videoheight% == x echo Empty input causes the using of the original videos aspect ratio.
  if not x%param_s_videoheight% == x echo Empty input causes the using of ratio 16:9
  set /p param_s_aspect=^>
  if not x%param_s_videoheight% == x if x%param_s_aspect% == x set param_s_aspect=16:9
  
  if "%param_s_aspect%" == "" goto collect_base_params__after_ratio

  echo.
  echo How should the original video be fit into the new videos size?
  echo [C]rop the original video image (cut from left+right or top+bottom)
  echo [P]ad the original video with black bars (default)
  echo [R]esize/stretch the image to the new ratio
  set /p param_s_resize_mode=^>
  if x%param_s_resize_mode% == x set param_s_resize_mode=p

  :collect_base_params__after_ratio
  
  echo.
  echo Set the frames per second (FPS)
  echo Examples: "25", "29.970029", "30", "60", "ntsc", "pal", "film"
  echo Empty input causes the using of the original videos FPS.
  set /p param_s_fps=^>
  
  if "%action_type%" == "join" goto collect_base_params__after_effects
  
  echo.
  echo Additional effects (combine tags as needed):
  echo [1] Weak sharpening
  echo [2] Medium sharpening
  echo [3] Strong sharpening
  echo [G] Add film grain (recomm. only for high bitr. with low quality source)
  echo [F] Fade in (3 secs from black)
  echo [I] De-Interlace
  echo [S] Stabilize
  echo Examples: "2", "1G", "F"
  set /p param_s_effects=^>
  if x%param_s_effects% == x set param_s_effects=_

  :collect_base_params__after_effects
  
  goto collect_base_params__next
  
  :collect_base_params__length
  
  echo.
  echo Skip time from the beginning of the original video.
  echo Format: "hh:mm:ss[.xxx]" or "ss[.xxx]"
  echo Empty input causes a start from the beginning of the original video.
  set /p param_start_at=^>
  
  echo.
  echo Set duration of the new video 
  echo Format: "hh:mm:ss[.xxx]" or "ss[.xxx]"
  echo Empty input causes the processes the original video until its end.
  set /p param_duration=^>
  
  goto collect_base_params__next
  
  :collect_base_params__audio
  
  set default_audio_type=m
  if /i x%param_s_video_type% == xh set default_audio_type=a
  if /i x%param_s_video_type% == xm set default_audio_type=2
  if /i x%param_s_video_type% == xc set default_audio_type=c
  if /i x%param_s_video_type% == xw set default_audio_type=o
  
  if /i x%param_s_video_type% == xj (
    set param_s_audio_type=n
    goto collect_base_params__next
  )
  
  echo.
  echo Set audio encoder:
  if x%default_audio_type% == xn ( echo [N]o audio ^(default^)  ) else ( echo [N]o audio )
  if x%default_audio_type% == xc ( echo [C]opy from source file ^(default^)  ) else ( echo [C]opy from source file )
  echo [W]AV
  echo [F]LAC
  if x%default_audio_type% == xm ( echo [M]P3 - libmp3lame ^(default^)       ) else ( echo [M]P3 - libmp3lame )
  if x%default_audio_type% == xo ( echo [O]GG - libvorbis ^(default^)        ) else ( echo [O]GG - libvorbis )
  if x%default_audio_type% == xa ( echo [A]AC - experimental aac ^(default^) ) else ( echo [A]AC - experimental aac )
  if x%default_audio_type% == x2 ( echo MP[2] - mp2 ^(default^)              ) else ( echo MP[2] - mp2 )
  set /p param_s_audio_type=^>
  if x%param_s_audio_type% == x set param_s_audio_type=%default_audio_type%
  set param_audiobitrate=
  if /i x%param_s_audio_type% == xw goto collect_base_params__next
  if /i x%param_s_audio_type% == xf goto collect_base_params__next
  if /i x%param_s_audio_type% == xc goto collect_base_params__next
  
  set default_audio_bitrate=192
  if /i x%param_s_audio_type% == xa set default_audio_bitrate=192
  if /i x%param_s_audio_type% == x2 set default_audio_bitrate=256
  if /i x%param_s_audio_type% == xo set default_audio_bitrate=128
  
  if /i x%param_s_audio_type% == xn (
    set default_audio_bitrate=0
    goto collect_base_params__next
  )
  
  echo.
  echo Enter audio bitrate in kilobit
  echo Examples: "128", "192", "320"
  echo Empty input causes the using of %default_audio_bitrate% kilobit.
  set /p param_audiobitrate=^>
  if x%param_audiobitrate% == x set param_audiobitrate=%default_audio_bitrate%

  goto collect_base_params__next

  :collect_base_params__videochannel

  echo.
  echo Channel for videostream in video file
  echo Examples: "0", "1", "2", ...
  echo Empty input causes the using of channel 0 (usually the right one).
  set /p param_videochannel=^>
  if x%param_videochannel% == x set param_videochannel=0
  
  goto collect_base_params__next
  
  :collect_base_params__twopass
  
  if not "%param_s_crf%" == "" goto collect_base_params__next
  if /i x%param_s_video_type% == xc goto collect_base_params__next
  if /i x%param_s_video_type% == xj goto collect_base_params__next
  
  echo.
  echo Two-Pass encoding?
  echo [Y]es
  echo [N]o (default)
  set /p param_s_2pass=^>
  if x%param_s_2pass% == x set param_s_2pass=N
  
  goto collect_base_params__next

  :collect_base_params__next
  
  shift
  goto collect_base_params

  goto eob


:render_filtercomplex_params
  set filter_params=-filter_complex "%maps% concat=n=%counter%:v=1:a=1 [v] [a]" -map "[v]" -map "[a]"
  goto eob

         
:render_audio_params 
  set audiobitrate=
  set afilter_fade=
  set audio_params=

  if "%param_s_audio_type%" == "" set param_s_audio_type=m

  if /i "%param_s_audio_type%" == "c" (
    set audio_params=-c:a copy
    goto eob
  )

  if /i "%param_s_audio_type%" == "n" (
    set audio_params=-an
    goto eob
  )

  if not "%param_s_effects%" == "%param_s_effects:f=_%" set afilter_fade=,afade=in:curve=esin:d=1.5

  if /i "%param_s_audio_type%" == "w" (
    set audio_params=-acodec pcm_s16le -ac 2 -ar 44100
    goto eob
  )

  if /i "%param_s_audio_type%" == "f" (
    set audio_params=-acodec flac -ac 2 -compression_level 8
    goto eob
  )

  set audiobitrate=-ab %param_audiobitrate%k

  if /i "%param_s_audio_type%" == "a" set audio_params=-strict -2 -acodec aac -ac 2 -ar 48000 %audiobitrate% -bsf:a aac_adtstoasc
  if /i "%param_s_audio_type%" == "m" set audio_params=-acodec libmp3lame -ac 2 -ar 44100 %audiobitrate%
  if /i "%param_s_audio_type%" == "2" set audio_params=-acodec mp2 -ac 2 -ar 44100 %audiobitrate%
  if /i "%param_s_audio_type%" == "o" set audio_params=-acodec libvorbis -ac 2 -ar 44100 %audiobitrate%
  
  if not "%action_type%" == "join" set audio_params=%audio_params% -af "anull %afilter_fade%"
  
  goto eob


:render_stream_params
  set duration=
  set start_at=      

  if not "%param_duration%" == "" set duration=-to %param_duration%
  if not "%param_start_at%" == "" set start_at=-accurate_seek -ss %param_start_at%
  
  set stream_params=%duration%

  goto eob


:render_video_params
  if /i "%param_s_video_type%" == "c" (
    set video_params=-c:v copy
    goto eob
  )         
  
  set crf=
  set aspect=
  set vfiltergraph=
  set fps=        
  set bitrate=
  set videowidth=
  set encoder=
  set vfilter_deshake=
  set vfilter_unsharp=
  set vfilter_scale=
  set vfilter_resizemode=
  set vfilter_noise=
  set vfilter_fade=
  set vfilter_deinterl=
  
  set vidstab_logfile=vidstab_%random%%random%%random%.trf

  if not "%param_s_crf%" == "" set crf=-crf %param_s_crf%
  if not "%param_s_bitrate%" == "" set bitrate=-b:v %param_s_bitrate%k
  if not "%param_s_fps%" == "" set fps=-r %param_s_fps%
  
  set encoder=-vcodec libx264
  if /i "%param_s_video_type%" == "m" set encoder=-vcodec mpeg2video
  if /i "%param_s_video_type%" == "x" set encoder=-vcodec libxvid
  if /i "%param_s_video_type%" == "j" set encoder=-f image2
  if /i "%param_s_video_type%" == "w" set encoder=-vcodec libvpx
  
  if /i not "%param_s_video_type%" == "c" if not "%param_s_aspect%" == "" (
    set aspect=-aspect %param_s_aspect%

    if /i "%param_s_resize_mode%" == "c" set vfilter_resizemode=,crop=min^(iw\,ih*^(%param_s_aspect::=/%^)^):ow/^(%param_s_aspect::=/%^)
    if /i "%param_s_resize_mode%" == "p" set vfilter_resizemode=,pad=max^(iw\,ih*^(%param_s_aspect::=/%^)^):ow/^(%param_s_aspect::=/%^):^(ow-iw^)/2:^(oh-ih^)/2

    if not "%param_s_videoheight%" == "" (
      FOR /F "delims=: tokens=1,2" %%a IN ("%param_s_aspect%") do set /a videowidth=%param_s_videoheight% / %%b * %%a
    )
  )
  
  if not x%videowidth% == x set vfilter_scale=,scale=%videowidth%:%param_s_videoheight%
  
  if not "%param_s_effects%" == "%param_s_effects:s=_%" set vfilter_deshake=,vidstabtransform=smoothing=20:optzoom=0:zoom=5:optalgo=avg:relative=1:input=%vidstab_logfile%
  if not "%param_s_effects%" == "%param_s_effects:f=_%" set vfilter_fade=,fade=in:st=0.5:d=2.5
  if not "%param_s_effects%" == "%param_s_effects:1=_%" set vfilter_unsharp=,unsharp=5:5:1.0:5:5:1.0
  if not "%param_s_effects%" == "%param_s_effects:2=_%" set vfilter_unsharp=,unsharp=5:5:2.0:5:5:2.0
  if not "%param_s_effects%" == "%param_s_effects:3=_%" set vfilter_unsharp=,unsharp=5:5:3.0:5:5:3.0
  if not "%param_s_effects%" == "%param_s_effects:g=_%" set vfilter_noise=,noise=c0s=17:c0f=a+t
  if not "%param_s_effects%" == "%param_s_effects:i=_%" set vfilter_deinterl=,kerndeint
  
  if /i "%param_s_video_type%" == "j" (
    set param_s_2pass=n
    set bitrate=-qscale:v 2
    set crf=
  )
  
  if not "%action_type%" == "join" set vfiltergraph=-vf "null %vfilter_deinterl% %vfilter_deshake% %vfilter_fade% %vfilter_resizemode% %vfilter_scale% %vfilter_unsharp% %vfilter_noise%"

  set video_params=%vfiltergraph% %encoder% %crf% %fps% %aspect% %bitrate%
  
  goto eob      


:execute_ffmpeg
  set result_filename_pre=%~dpn1
  set result_filename_post=%~x1
  set result_filename=%result_filename_pre%%result_filename_post%
  set result_2passlog_pre=%result_filename_pre%
  
  if /i "%param_s_video_type%" == "j" set result_filename=%result_filename_pre%.%%12d%result_filename_post%

  if not exist "%result_filename%" goto execute_ffmpeg__run
  
  set /a result_filenamecounter=0
  :execute_ffmpeg__findfilename
  set /a result_filenamecounter+=1
  set result_filename=%result_filename_pre%.%result_filenamecounter%%result_filename_post%
  if exist "%result_filename%" goto execute_ffmpeg__findfilename

  :execute_ffmpeg__run
  
  echo.
  set param_s_
  
  echo.
  
  if "%param_s_effects%" == "%param_s_effects:s=_%" goto execute_ffmpeg__start_encoding
  
  @echo on 
  ffmpeg.exe -y %sources% -an %stream_params% -vf "vidstabdetect=shakiness=10:stepsize=12:result=%vidstab_logfile%" -vcodec rawvideo -f null -
  @echo off
  
  :execute_ffmpeg__start_encoding

  if /i x%param_s_2pass% == xy goto execute_ffmpeg__twopass
  
  @echo on
  ffmpeg.exe -y %sources% %filter_params% %audio_params% %stream_params% %video_params% "%result_filename%"
  @echo off

  goto execute_ffmpeg__finalize

  :execute_ffmpeg__twopass
  
  @echo on
  ffmpeg.exe -y %sources% %filter_params% %audio_params% %stream_params% %video_params% -pass 1 -passlogfile "%result_2passlog_pre%" -f null -
  @echo off
  ffmpeg.exe -y %sources% %filter_params% %audio_params% %stream_params% %video_params% -pass 2 -passlogfile "%result_2passlog_pre%" "%result_filename%"

  del /f /q "%result_2passlog_pre%*log*"

  goto execute_ffmpeg__finalize
  
  :execute_ffmpeg__finalize

  if not "%vidstab_logfile%" == "" del /f /q "%~dp0%vidstab_logfile%"
  
  goto eob
  
  
:help
  echo.
  echo Drag'n'drop files onto the batch file to:
  echo - Join videos into a single video.
  echo - Batch process videos into new videos.
  echo - Extract audio file^(s^) from video file^(s^).
  echo - Replace audio track in a video file.
  echo.
  echo Replacing audio is done by dropping one video and one music file onto the
  echo batch file.
  echo.
  echo Needs ffmpeg.exe in the folder of the batch file or the ffmpeg.exe folder
  echo in PATH.
  echo.
  echo Tested with ffmpeg version N-71839-g6197672.
  echo http://www.ffmpeg.org/
  echo.
  echo Developed under Windows 7, 64Bit.
  echo. 
  echo If you want the batch as a context menu option for files, create a link to
  echo it in the SendTo folder. You then have access using the context menu option 
  echo "Send To" when selecting one or many files in the Windows Explorer:
  echo %appdata%\Microsoft\Windows\SendTo
  echo.
  
  pause
  
  goto eob
  

:eob


