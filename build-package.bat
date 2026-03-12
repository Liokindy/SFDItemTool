SET "NAME=DeluxeBench"

SET "ARCHIVE_PATH=.\.package\archive\"
SET "SOURCE_PATH=.\source\"

if not exist %ARCHIVE_PATH% mkdir %ARCHIVE_PATH%

start /wait powershell Compress-Archive -Path %SOURCE_PATH%* -DestinationPath %ARCHIVE_PATH%%NAME%
ren %ARCHIVE_PATH%%NAME%.zip %NAME%.love
