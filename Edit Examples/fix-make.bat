@echo off

del *.exe
del *.~*
del *.cfg
del *.dof
del "es_password.res"

brcc32 -dXPPatch es_password.rc -foes_password.res
dcc32 es_password.dpr

