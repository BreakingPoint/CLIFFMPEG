# CLIFFMPEG

Simple Windows CLI script FFMPEG wrapper to execute the most common task. The user defines the task via a Q&amp;A interface.

Drag'n'drop files onto the batch file to:
- Join videos into a single video.
- Batch process videos into new videos (or a single video)
- Extract audio file(s) from video file(s).
- Rerender audio files
- Replace audio track in a video file.
- Cut segment from video

Features optional 2-pass-encoding for videos.

Available effects:
- Sharpening
- Resize via cropping/padding (black bars)/resizing
- Stabilizing
- Deinterlacing
- Add grain (for dithering blocky low quality sources)
- Fade in

Replacing audio is done by dropping one video and one music file onto the batch file.

Needs ffmpeg.exe in the folder of the batch file or the ffmpeg.exe folder in PATH.
http://www.ffmpeg.org/

Developed under Windows 7, 64Bit.
 
If you want the batch as a context menu option for files, create a link to it in the SendTo folder. You then have access using the context menu option "Send To" when selecting one or many files in the Windows Explorer:

%appdata%\Microsoft\Windows\SendTo

<img src="http://i.imgur.com/CAJh9gs.gif">