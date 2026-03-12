@echo OFF

call build-package.bat
call build-windows.bat ".\.love\win64\" ".\.package\fused\win64\"
