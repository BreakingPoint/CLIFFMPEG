# CLIFFMPEG

Simple Windows CLI script FFMPEG wrapper to execute the most common tasks. The user defines the task via a Q&amp;A interface.

Tested with FFMPEG N-71839-g6197672. Other versions of FFMPEG might create errors when run with this script.

Drag'n'drop file(s) onto the script file to:
- Join videos into a single video.
- (Batch) process video(s) into new video(s)
- Generate JPEG gallery from a video
- Extract audio file(s) from video file(s).
- Rerender audio file(s)
- Replace audio track in a video file.
- Cut segment from video

Supported output video formats (incl. 2-pass encoding): MP4, XVid, MPEG2, WEBM, JPEG images, raw copy.
Supported output audio formats: WAV, MP3, MP2, AAC, OGG, FLAC, raw copy.

Available effects:
- Sharpening
- Resize via cropping/padding (black bars)/fitting
- Stabilizing
- Deinterlacing
- Add grain (for dithering blocky low quality sources)
- Fade in from black

Replacing audio is done by dropping one video and one music file onto the script file.

Needs ffmpeg.exe in the folder of the script file or the ffmpeg.exe folder in PATH.
http://www.ffmpeg.org/

Developed under Windows 7, 64Bit.
 
If you want the script as a context menu option for files, create a link to it in the SendTo folder. You then have access using the context menu option "Send To" when selecting one or many files in the Windows Explorer:

%appdata%\Microsoft\Windows\SendTo

<img src="http://i.imgur.com/CAJh9gs.gif">

<img src="http://i.imgur.com/9sGZ50I.gif">
