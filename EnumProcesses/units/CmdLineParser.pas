unit CmdLineParser;

interface

uses
  Windows;

function GetCmdLineSwitch(const ASwitch: string; const IgnoreCase: Boolean = True): Boolean;
function GetCmdLineSwitchValue(out AValue: string; const ASwitch: string; const IgnoreCase: Boolean = True): Boolean;

implementation

// Helper functions...

type
  TSysCharSet = set of Char;

function CompareStr(const S1, S2: string): Integer; assembler;
asm
        PUSH    ESI
        PUSH    EDI
        MOV     ESI,EAX
        MOV     EDI,EDX
        OR      EAX,EAX
        JE      @@1
        MOV     EAX,[EAX-4]
@@1:    OR      EDX,EDX
        JE      @@2
        MOV     EDX,[EDX-4]
@@2:    MOV     ECX,EAX
        CMP     ECX,EDX
        JBE     @@3
        MOV     ECX,EDX
@@3:    CMP     ECX,ECX
        REPE    CMPSB
        JE      @@4
        MOVZX   EAX,BYTE PTR [ESI-1]
        MOVZX   EDX,BYTE PTR [EDI-1]
@@4:    SUB     EAX,EDX
        POP     EDI
        POP     ESI
end;

function CompareText(const S1, S2: string): Integer; assembler;
asm
        PUSH    ESI
        PUSH    EDI
        PUSH    EBX
        MOV     ESI,EAX
        MOV     EDI,EDX
        OR      EAX,EAX
        JE      @@0
        MOV     EAX,[EAX-4]
@@0:    OR      EDX,EDX
        JE      @@1
        MOV     EDX,[EDX-4]
@@1:    MOV     ECX,EAX
        CMP     ECX,EDX
        JBE     @@2
        MOV     ECX,EDX
@@2:    CMP     ECX,ECX
@@3:    REPE    CMPSB
        JE      @@6
        MOV     BL,BYTE PTR [ESI-1]
        CMP     BL,'a'
        JB      @@4
        CMP     BL,'z'
        JA      @@4
        SUB     BL,20H
@@4:    MOV     BH,BYTE PTR [EDI-1]
        CMP     BH,'a'
        JB      @@5
        CMP     BH,'z'
        JA      @@5
        SUB     BH,20H
@@5:    CMP     BL,BH
        JE      @@3
        MOVZX   EAX,BL
        MOVZX   EDX,BH
@@6:    SUB     EAX,EDX
        POP     EBX
        POP     EDI
        POP     ESI
end;

function AnsiCompareText(const S1, S2: string): Integer;
begin
  Result := CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE, PChar(S1),
    Length(S1), PChar(S2), Length(S2)) - 2;
end;

function AnsiCompareStr(const S1, S2: string): Integer;
begin
  Result := CompareString(LOCALE_USER_DEFAULT, 0, PChar(S1), Length(S1),
    PChar(S2), Length(S2)) - 2;
end;

function FindCmdLineSwitch(const Switch: string; const Chars: TSysCharSet;
  IgnoreCase: Boolean): Boolean;
var
  I: Integer;
  S: string;
begin
  for I := 1 to ParamCount do
  begin
    S := ParamStr(I);
    if (Chars = []) or (S[1] in Chars) then
      if IgnoreCase then
      begin
        if (AnsiCompareText(Copy(S, 2, Maxint), Switch) = 0) then
        begin
          Result := True;
          Exit;
        end;
      end
      else begin
        if (AnsiCompareStr(Copy(S, 2, Maxint), Switch) = 0) then
        begin
          Result := True;
          Exit;
        end;
      end;
  end;
  Result := False;
end;

function GetCmdLineSwitch(const ASwitch: string; const IgnoreCase: Boolean = True): Boolean;
begin
  Result := FindCmdLineSwitch(ASwitch, ['-', '/'], IgnoreCase);
end;

{**************************************************************************
* NAME:    FindCmdLineSwitchValue
* DESC:    Command-line parser for options of the form:    ['-'|'/']Name[':'|'=']Wert
*
* Example:
*   Kommandozeile "-a:WertA /b:WertB -c=WertC -d=WertD
*    FindCmdLineSwitchValue(Value,'a',False) ==> Result=True, Value=WertA
*    FindCmdLineSwitchValue(Value,'A',False) ==> Result=False
*    FindCmdLineSwitchValue(Value,'A',True) ==> Result=False, Value=WertA
* PARAMS:  out AValue: string; const ASwitch: string; const IgnoreCase: Boolean = True
* RESULT:  Boolean
* CHANGED:
*************************************************************************}

function GetCmdLineSwitchValue(out AValue: string; const ASwitch: string; const IgnoreCase: Boolean = True): Boolean;
const
  CompareFunction   : array[Boolean]

  of function(const s1, s2: string): Integer = (CompareStr, CompareText);
  var
    iCmdLine, iSplit: Integer;
    s, sName, sValue: string;
  begin
    Result := False;

    for iCmdLine := 1 to ParamCount do
    begin
      s := ParamStr(iCmdLine);

      if not (s[1] in ['-', '/']) then
        Continue;

      Delete(s, 1, 1);
      iSplit := Pos(':', s);
      if iSplit = 0 then
        iSplit := Pos('=', s);

      if iSplit = 0 then
        Continue;

      sName := Copy(s, 1, iSplit - 1);
      sValue := Copy(s, iSplit + 1, 666);

      if CompareFunction[IgnoreCase](ASwitch, sName) = 0 then
      begin
        AValue := sValue;
        Result := True;
        Break;
      end;
    end;
  end;

end.

