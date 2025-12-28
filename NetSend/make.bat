@rcstamp res\resource.rc 2.*.*.+
@brcc32 res\resource.rc -fores\resource.res
@dcc32 NetSend.dpr
@upx -9 ..\NetSend.exe
pause