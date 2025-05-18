@echo off

REM Copyright (C) 2025 Alpar Duman
REM This file is part of media-archiver.
REM 
REM media-archiver is free software: you can redistribute it and/or modify
REM it under the terms of the GNU General Public License version 3 as
REM published by the Free Software Foundation.
REM 
REM media-archiver is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
REM GNU General Public License for more details.
REM 
REM You should have received a copy of the GNU General Public License
REM along with media-archiver. If not, see
REM <https://github.com/AlparDuman/media-archiver/blob/main/LICENSE>
REM else <https://www.gnu.org/licenses/>.

setlocal enabledelayedexpansion


REM ===== Configuration ===== 


REM override auto detect of core number
set "parallel_processing_limit=8"


REM folder for converted media
set "folder_converted=_converter product"


REM folder for original media
set "folder_original=_converter original"


REM folder for failed media
set "folder_failed=_converter error"


REM filename suffix for archived media (optional)
set "suffix_archive=.archive"
REM set "suffix_archive="


REM Search for these file extensions to convert as image
set "convert_images_extension=.jpg .jpeg .png .bmp .tiff .webp"


REM Search for these file extensions to convert as video
set "convert_video_extension=.mp4 .mkv .mov .avi .webm .flv"


REM ===== Configuration ===== 


REM get library locations
if exist "ffmpeg/bin/ffmpeg.exe" (

	set "ffmpeg_path=ffmpeg/bin/ffmpeg.exe"
	
) else (

	set "ffmpeg_path=ffmpeg"
	
)

if exist "exiftool/exiftool.exe" (

	set "exiftool_path=exiftool/exiftool.exe"
	
) else (

	set "exiftool_path=exiftool"
	
)

REM check dependencies
where %ffmpeg_path% >nul 2>&1 && for /f "tokens=3" %%a in ('%ffmpeg_path% -version 2^>^&1 ^| findstr /i "ffmpeg"') do (

    set "ffmpegVersion=FFmpeg %%a"
	
) || (

    echo FFmpeg not found in PATH
	pause
    exit
	
)

where %exiftool_path% >nul 2>&1 && for /f "tokens=1 delims= " %%a in ('%exiftool_path% -ver 2^>nul') do (

    set "ExifToolVersion=ExifTool %%a"
	
) || (

    echo ExifTool not found in PATH
	pause
    exit
	
)

REM set limit for parallel convertion
where wmic >nul 2>&1 (

	for /f "skip=1" %%c in ('wmic cpu get NumberOfCores') do set parallel_processing_limit=%%c

)

REM Check if a file was passed (drag-and-drop)
if "%~1"=="" goto :no_file

REM file found process


echo "%~n1"
echo "%~x1"



endlocal
exit /b 2

:no_file



for %%f in (*.*) do (
	echo " %convert_images_extension% %convert_video_extension% " | findstr /i /c:" %%~xf " >nul && (
		call "%~f0" "%%f"
	)
)











pause
exit





REM create folders
if not exist "%folder_converted%" mkdir "%folder_converted%"
if not exist "%folder_original%" mkdir "%folder_original%"

REM Get next image file
for %%f in (*.*) do (

	
	
	
	
	
	
	
	
	
	
)

REM Get next video file
for %%f in (*.*) do (
	echo " %convert_video_extension% " | findstr /i /c:" %%~xf " >nul && 
		start "" /b /belownormal cmd /c call :process "%%f" "%ffmpeg_path%" "%exiftool_path%"
	)
)

REM Finished
endlocal
echo.
title Converting finished
set /p "a=Finished, press any key to close . . . " <nul
pause >nul
exit




:process

echo " %convert_images_extension% %convert_video_extension% " | findstr /i /c:" %%~xf " >nul && (
	
	REM check if file is locked by another process
	set "filename=%%~nf"
	if "!filename:.testlock=!"=="%%~nf" if not exist "%%~nf.testlock%%~xf" (
	
		ren "%%f" "%%~nf.testlock%%~xf" 2>nul
		
		if not exist "%%f" (
		
			if exist "%%~nf.testlock%%~xf" (
			
				ren "%%~nf.testlock%%~xf" "%%f" 2>nul
				title Converting %%f
				
				set "filename=!filename:%suffix_archive%=!"
				
				REM Try converting image, downscale if exceeds safe dimensions & safe without metadata in best jpg quality
				echo " %convert_images_extension% " | findstr /i /c:" %%~xf " >nul && start /b /belownormal /wait ^
				%ffmpeg_path% -hide_banner -y -i "%%f" ^
				-v quiet ^
				-stats ^
				-frames:v 1 ^
				-vf "scale='min(iw,16384)':'min(ih,16384)':force_original_aspect_ratio=decrease:flags=lanczos" ^
				-map_metadata -1 ^
				-q:v 1 ^
				"%folder_converted%\!filename!%suffix_archive%.jpg" && (
					
					REM Get safe metadata
					start /b /belownormal /wait ^
					%exiftool_path% -q -q -tagsFromFile "%%f" ^
					-exif:all ^
					-iptc:all ^
					-xmp:all ^
					-comment ^
					-DateTimeOriginal ^
					-CreateDate ^
					"-FileCreateDate<DateTimeOriginal" ^
					"-FileModifyDate<DateTimeOriginal" ^
					-Orientation= ^
					-overwrite_original ^
					-Software="com.github.alparduman.convert-media-for-archive / %ffmpegVersion% / %ExifToolVersion%" ^
					"%folder_converted%\!filename!%suffix_archive%.jpg" && (
					
						REM Convertion & Metadata successful
						start /b "" cmd /c move "%%f" "%folder_original%\%%f" >nul 2>&1
						REM converted
						exit /b 0
						
					) || (
					
						REM Metadata incompatible
						del "%folder_converted%\!filename!%suffix_archive%.jpg"
						if not exist "%folder_failed%" mkdir "%folder_failed%"
						start /b "" cmd /c move "%%f" "%folder_failed%\%%f" >nul 2>&1
						REM metadata incompatible
						exit /b 1
						
					)
					
				REM Try converting vide & safe without metadata in best x264 quality
				) || echo " %convert_video_extension% " | findstr /i /c:" %%~xf " >nul && start /b /belownormal /wait ^
				%ffmpeg_path% -hide_banner -y -i "%%f" ^
				-v quiet ^
				-stats ^
				-c:v libx264 ^
				-threads 0 ^
				-preset placebo ^
				-crf 18 ^
				-fps_mode vfr ^
				-pix_fmt yuv420p ^
				-refs 4 ^
				-c:a aac ^
				-b:a 192k ^
				-ar 48000 ^
				-ac 2 ^
				-movflags +faststart ^
				-map 0:v ^
				-map 0:a ^
				-map_metadata -1 ^
				"%folder_converted%/!filename!%suffix_archive%.mp4" && (
					
					REM Get safe metadata
					start /b /belownormal /wait ^
					%exiftool_path% -tagsFromFile "%%f" ^
					-exif:all ^
					-iptc:all ^
					-xmp:all ^
					-comment ^
					-DateTimeOriginal ^
					-CreateDate ^
					"-FileCreateDate<DateTimeOriginal" ^
					"-FileModifyDate<DateTimeOriginal" ^
					-overwrite_original ^
					-EncodedBy="com.github.alparduman.convert-media-for-archive / %ffmpegVersion% / %ExifToolVersion%" ^
					"%folder_converted%\!filename!%suffix_archive%.mp4" && (
					
						REM Convertion & Metadata successful
						start /b "" cmd /c move "%%f" "%folder_original%\%%f" >nul 2>&1
						REM converted
						exit /b 0
						
					) || (
					
						REM Metadata incompatible
						del "%folder_converted%\!filename!%suffix_archive%.mp4"
						if not exist "%folder_failed%" mkdir "%folder_failed%"
						start /b "" cmd /c move "%%f" "%folder_failed%\%%f" >nul 2>&1
						REM metadata incompatible
						exit /b 1
						
					)
					
				) || (
					
					set "suffixName="
					
					echo " %convert_images_extension% " | findstr /i /c:" %%~xf " >nul && (
					
						REM try to suggest new image dimensions for user to manually update, so ffmpeg & ffprobe can handle the file
						for /f "tokens=1,2 delims=x" %%a in ('exiftool -s3 -ImageSize "%%f"') do (
						
							set "width=%%a"
							set "height=%%b"
							
						)

						echo !width!| findstr "^[0-9][0-9]*$" >nul || set width=INVALID
						echo !height!| findstr "^[0-9][0-9]*$" >nul || set height=INVALID
						
						if not "!width!"=="INVALID" if not "!height!"=="INVALID" (
						
							set /a "iX=!width!*8+1024"
							set /a "iY=!height!+128"
							
							set /a "iX2=2147483647/!iX!*!width!/!iY!"
							set /a "iY2=2147483647/!iX!*!height!/!iY!"
							
							set "suffixName= (rescale to !iX2!x!iY2!)"
							
						)
					
					)
					
					REM move incompatible file
					del "%folder_converted%\!filename!%suffix_archive%.jpg"
					if not exist "_error incompatible" mkdir "_error incompatible"
					start /b "" cmd /c move "%%f" "_error incompatible\%%~nf!suffixName!%%~xf" >nul 2>&1
					REM conversion incompatible
					exit /b 1
					
				)
				
			) else (
			
				REM locked by another process
				exit /b 2
				
			)
			
		) else (
		
			REM locked by another process
			exit /b 2
			
		)
		
	) else (
	
		REM filename for process lock already exists
		exit /b 3
		
	)
	
)

REM file is not a recognized image or video
exit /b 4
