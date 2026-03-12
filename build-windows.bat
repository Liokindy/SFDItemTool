SET "NAME=DeluxeBench"

SET "LOVE_PATH=%1"
SET "FUSED_PATH=%2"
SET "ARCHIVE_PATH=.\.package\archive\"
SET "SOURCE_PATH=.\source\"

if not exist %FUSED_PATH% mkdir %FUSED_PATH%
if exist %FUSED_PATH%%NAME%.exe del /F %FUSED_PATH%%NAME%.exe

if not exist "%LOVE_PATH%license.txt" %FUSED_PATH% copy "%LOVE_PATH%license.txt" %FUSED_PATH%
if not exist "%LOVE_PATH%love.dll" %FUSED_PATH% copy "%LOVE_PATH%love.dll" %FUSED_PATH%
if not exist "%LOVE_PATH%lua51.dll" %FUSED_PATH% copy "%LOVE_PATH%lua51.dll" %FUSED_PATH%
if not exist "%LOVE_PATH%mpg123.dll" %FUSED_PATH% copy "%LOVE_PATH%mpg123.dll" %FUSED_PATH%
if not exist "%LOVE_PATH%msvcp120.dll" %FUSED_PATH% copy "%LOVE_PATH%msvcp120.dll" %FUSED_PATH%
if not exist "%LOVE_PATH%msvcr120.dll" %FUSED_PATH% copy "%LOVE_PATH%msvcr120.dll" %FUSED_PATH%
if not exist "%LOVE_PATH%OpenAL32.dll" %FUSED_PATH% copy "%LOVE_PATH%OpenAL32.dll" %FUSED_PATH%
if not exist "%LOVE_PATH%SDL2.dll" %FUSED_PATH% copy "%LOVE_PATH%SDL2.dll" %FUSED_PATH%
copy /b "%LOVE_PATH%love.exe"+%ARCHIVE_PATH%%NAME%.love %FUSED_PATH%%NAME%.exe
