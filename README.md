# CLIFFMPEG

Simple Windows CLI script FFMPEG wrapper to execute the most common tasks. The user defines the task via a Q&amp;A interface.

Drag'n'drop file(s) onto the script file to:
- Join videos into a single video.
- (Batch) process video(s) into new video(s)
- Generate JPEG/PNG gallery from a video
- Generate GIF animation from video
- Generate video from image and audio file
- Extract audio file(s) from video file(s).
- Rerender audio file(s)
- Replace audio track in a video file.
- Cut segment from audio or video
- Encode multichannel sound (5.1) to 2 channel Dolby Pro Logic II.

Supported output video formats (some include optional 2-pass encoding): MP4, XVid, MPEG2, WEBM, JPEG images, GIF, raw copy.
Supported output audio formats (some with fixed or variable bitrates): WAV, MP3, MP2, AAC, AC3, OGG, FLAC, raw copy.

Available effects:
- Sharpening
- Resize via cropping/padding (black bars)/fitting
- Stabilizing
- Deinterlacing
- Frame interpolation
- Add grain (for dithering blocky low quality sources)
- Fade in from black
- Normalize/Compress audio
- Change speed of audio/video

Replacing audio is done by dropping one video and one music file onto the script file. 

For access as context menu option put a link to it in the send-to folder, so you can execute the script from the context menu on one or more marked files in the file explorer. Folder: C:\Users\\$(username)\AppData\Roaming\Microsoft\Windows\SendTo

Needs ffmpeg.exe in the folder of the script file or the ffmpeg.exe folder in PATH.
http://www.ffmpeg.org/

Developed under Windows 7, 64Bit.

<img src="http://i.imgur.com/CAJh9gs.gif">
 
If you want the script as a context menu option for files, the script creates a link to it in the SendTo folder. You then have access using the context menu option "Send To" when selecting one or many files in the Windows Explorer:

<img src="http://i.imgur.com/9sGZ50I.gif">
