{$APPTYPE GUI}
{$ALIGN ON}
{$B-} //complete boolean eval off
{$C-} //assertions on
{$D-} //no debug info
{$G-} //imported data off
{$I+} //io checks on
{$J-} //writable constants off
{$L-} //local symbols off
{$H+} //longstrings on
{$O+} //optimization on
{$P+} //openstrings on
{$Q-} //overflow checking off
{$T-} //typed @ off{$M-}//type info off
{$Y-} //no reference informations
{$R-} //rangecheck off
{$U-} //pentium(tm) safe divide off
{$W-} //stackframes off
{$X+} //extended syntax on
{$V-} //var shortstring check off
{$HINTS OFF}
{$WARNINGS OFF}//warnings off
{$IMAGEBASE $00400000}
{$MINSTACKSIZE 1024}
{$MINENUMSIZE 4} //minimum enum type size = 1

// Version definitions
{$UNDEF DELPHI1}{$IFDEF VER80}{$DEFINE DELPHI1}{$ENDIF}
{$UNDEF DELPHI2}{$IFDEF VER90}{$DEFINE DELPHI2}{$ENDIF}
{$UNDEF DELPHI3}{$IFDEF VER100}{$DEFINE DELPHI3}{$ENDIF}
{$UNDEF DELPHI4}{$IFDEF VER120}{$DEFINE DELPHI4}{$ENDIF}
{$UNDEF DELPHI5}{$IFDEF VER130}{$DEFINE DELPHI5}{$ENDIF}
{$UNDEF DELPHI6}{$IFDEF VER140}{$DEFINE DELPHI6}{$ENDIF}
{$UNDEF DELPHI7}{$IFDEF VER150}{$DEFINE DELPHI7}{$ENDIF}

{$IFDEF DELPHI1}
{$DEFINE DELPHI}
{$DEFINE DELPHI1UP}
{$ENDIF}

{$IFDEF DELPHI2}
{$DEFINE DELPHI}
{$DEFINE DELPHI1UP}
{$DEFINE DELPHI2UP}
{$ENDIF}

{$IFDEF DELPHI3}
{$DEFINE DELPHI}
{$DEFINE DELPHI1UP}
{$DEFINE DELPHI2UP}
{$DEFINE DELPHI3UP}
{$ENDIF}

{$IFDEF DELPHI4}
{$DEFINE DELPHI}
{$DEFINE DELPHI1UP}
{$DEFINE DELPHI2UP}
{$DEFINE DELPHI3UP}
{$DEFINE DELPHI4UP}
{$ENDIF}

{$IFDEF DELPHI5}
{$DEFINE DELPHI}
{$DEFINE DELPHI1UP}
{$DEFINE DELPHI2UP}
{$DEFINE DELPHI3UP}
{$DEFINE DELPHI4UP}
{$DEFINE DELPHI5UP}
{$ENDIF}

{$IFDEF DELPHI6}
{$DEFINE DELPHI}
{$DEFINE DELPHI1UP}
{$DEFINE DELPHI2UP}
{$DEFINE DELPHI3UP}
{$DEFINE DELPHI4UP}
{$DEFINE DELPHI5UP}
{$DEFINE DELPHI6UP}
{$ENDIF}

{$IFDEF DELPHI7}
{$DEFINE DELPHI}
{$DEFINE DELPHI1UP}
{$DEFINE DELPHI2UP}
{$DEFINE DELPHI3UP}
{$DEFINE DELPHI4UP}
{$DEFINE DELPHI5UP}
{$DEFINE DELPHI6UP}
{$DEFINE DELPHI7UP}
{$ENDIF}

{$IFNDEF DELPHI}
'This applicaction requires Delphi version 1-7'
{$ENDIF}

