@echo off

rem Paths used in the ml command below.
rem IMPORTANT: You will need to update this if you installed VS in a different location.
SET visualStudioDir=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.27.29110
SET crtLibPath=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.17763.0\ucrt\x86
SET uuidPath=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.17763.0\um\x86

rem Process special command line arguments.  No param means we want to show the usage while passing in /? will 
rem display MASM's help.  It currently doesn't display the help for the linker.
IF [%1] == [] GOTO NoParam
IF [%1] == [/?] GOTO Help

rem If we get here, we treat the command line arguments as a list of files and call ml.exe on them.  This will 
rem assemble and link the files into a final EXE.
"%visualStudioDir%\bin\Hostx86\x86\ml.exe" %1 /link /SUBSYSTEM:CONSOLE /LIBPATH:"%visualStudioDir%\lib\x86" /LIBPATH:"%crtLibPath%" /LIBPATH:"%uuidPath%

rem We're done, so jump to the end.
GOTO End

rem No parameters
:NoParam
	echo Usage: masm file1.asm [file2.asm]
	echo Pass in /? for help
	GOTO End
	
rem Help case
:Help
	echo MASM Assembler:
	"%visualStudioDir%\bin\Hostx86\x86\ml.exe" /?
	echo Linker:
	"%visualStudioDir%\bin\Hostx86\x86\link.exe" /?
	GOTO End

:End
