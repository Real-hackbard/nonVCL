@echo off

del *.res
brcc32 VistaOpFav-en.rc -foVistaOpFav-en.res
brcc32 VistaOpFav-de.rc -foVistaOpFav-de.res
brcc32 manifest.rc