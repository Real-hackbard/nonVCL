unit MPuBruteForce;

interface

uses
  Math;

  function MaxKombinations(Len: integer; const Chars: string): Int64;
  function BruteForce(Nb: Int64; Chars: string): string;

implementation

{function MaxKombinations(Len: integer; const Chars: string): Int64;
begin
  Result := Trunc(Power(Length(chars), len));
end;}

function MaxKombinations(Len: integer; const Chars: string): Int64;
var
  Factor            : Int64;
begin
  Result := 0;
  Factor := 1;
  while Len > 0 do
  begin
    dec(Len);
    Result := Result + Factor;
    Factor := Factor * Length(Chars);
  end;
end;

function BruteForce(Nb: Int64; Chars: string): string;
begin
  Result := '';
  while Nb > Length(Chars) do
  begin
    dec(Nb);
    Result := Chars[Nb mod Length(Chars) + 1] + Result;
    Nb := Nb div Length(Chars);
  end;
  if Nb > 0 then
    Result := Chars[Nb] + Result;
end;

end.
 