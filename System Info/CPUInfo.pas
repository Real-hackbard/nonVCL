unit CPUInfo;

interface

uses windows;

Const
     InfoStrings: Array[0..1] of String = ('FDIV instruction is Flawed',
                                           'FDIV instruction is OK');

Const
  // Constants to be used with Feature Flag set of a CPU
  // eg. IF (Features and FPU_FLAG = FPU_FLAG) THEN CPU has Floating-Point unit on chip
  // However, Intel claims that in future models, a zero in the feature flags will
  // mean that the chip has that feature, however, the following flags will work for
  // any production 80x86 chip or clone.
  // eg. IF (Features and FPU_FLAG = 0) then CPU has Floating-Point unit on chip
  FPU_FLAG = $00000001; // Floating-Point unit on chip
  VME_FLAG = $00000002; // Virtual Mode Extention
   DE_FLAG = $00000004; // Debugging Extention
  PSE_FLAG = $00000008; // Page Size Extention
  TSC_FLAG = $00000010; // Time Stamp Counter
  MSR_FLAG = $00000020; // Model Specific Registers
  PAE_FLAG = $00000040; // Physical Address Extention
  MCE_FLAG = $00000080; // Machine Check Exception
  CX8_FLAG = $00000100; // CMPXCHG8 Instruction
 APIC_FLAG = $00000200; // Software-accessible local APIC on Chip
  BIT_10   = $00000400; // Reserved, do not count on value
  SEP_FLAG = $00000800; // Fast System Call
 MTRR_FLAG = $00001000; // Memory Type Range Registers
  PGE_FLAG = $00002000; // Page Global Enable
  MCA_FLAG = $00004000; // Machine Check Architecture
 CMOV_FLAG = $00008000; // Conditional Move Instruction
  BIT_16   = $00010000; // Reserved, do not count on value
  BIT_17   = $00020000; // Reserved, do not count on value
  BIT_18   = $00040000; // Reserved, do not count on value
  BIT_19   = $00080000; // Reserved, do not count on value
  BIT_20   = $00100000; // Reserved, do not count on value
  BIT_21   = $00200000; // Reserved, do not count on value
  BIT_22   = $00400000; // Reserved, do not count on value
  MMX_FLAG = $00800000; // MMX technology
  BIT_24   = $01000000; // Reserved, do not count on value
  BIT_25   = $02000000; // Reserved, do not count on value
  BIT_26   = $04000000; // Reserved, do not count on value
  BIT_27   = $08000000; // Reserved, do not count on value
  BIT_28   = $10000000; // Reserved, do not count on value
  BIT_29   = $20000000; // Reserved, do not count on value
  BIT_30   = $40000000; // Reserved, do not count on value
  BIT_31   = $80000000; // Reserved, do not count on value


type
  TCpu = Record
    VendorIDString: String;
    Manufacturer: String;
    CPU_Name: String;
    PType: Byte;
    Family: Byte;
    Model: Byte;
    Stepping: Byte;
    Features: Cardinal;
    MMX: Boolean;
    IDFDIVOK: Boolean;
  end;

type TCPUInfo = class
  private
    FCPUSpeed            : Extended;
    FCPUInfo             : TCPU;
    FCPUID               : TCPU;
    FTestFDIVInstruction : Boolean;
    FCPUType             : String;
    FVendorIDString      : String;
    FManufacturer        : String;
    FCPUName             : String;
    FPType               : Byte;
    FFamily              : Byte;
    FModel               : Byte;
    FStepping            : Byte;
    function GetCPUID: TCPU;
    procedure GetCPUInfo(var FCPUInfo: TCPU);
    procedure TestFDIVInstruction;

    procedure GetCPUSpeed;
    procedure GetCPUType;
    procedure GetVendorIDString;
    procedure GetManufacturer;
    procedure GetCPUName;
    procedure GetPType;
    procedure GetFamily;
    procedure GetModel;
    procedure GetStepping;
  public
    constructor create;
    property CPUSpeed: Extended read FCPUSpeed;
    property CPUType: String read FCPUType;
    property VendorIDString: String read FVendorIDString;
    property Manufacturer: String read FManufacturer;
    property CPUName: String read FCPUName;
    property PType: Byte read FPtype;
    property Family: Byte read FFamily;
    property Model: Byte read FModel;
    property Stepping: Byte read FStepping;
  end;

implementation

{$INCLUDE SysUtils.inc}

constructor TCPUInfo.create;
begin
  GetCPUSpeed;
  TestFDIVInstruction;
  FCPUID := GetCPUID;
  GetCPUInfo(FCPUInfo);
  GetCPUType;
  GetVendorIDString;
  GetManufacturer;
  GetCPUName;
  GetPType;
  GetFamily;
  GetModel;
  GetStepping;
end;

procedure TCPUInfo.GetCPUType;
var
   systeminfo : tsysteminfo;
   s : string;
begin
  getsysteminfo(systeminfo);
  case systeminfo.dwprocessortype of
    386: s:='Intel 80386';
    486: s:='Intel 80486';
    586: s:='Pentium Klasse';
    860: s:='Intel 860';
    2000: s:='MIPS R2000';
    3000: s:='MIPS R3000';
    4000: s:='MIPS R4000';
    21064: s:='ALPHA 21064';
  else
   s:='Processor nicht klassifiziert';
  end;
  FCPUType := s;
end;

procedure TCPUInfo.GetVendorIDString;
begin
  FVendorIDString := FCPUInfo.VendorIDString;
end;

procedure TCPUInfo.GetManufacturer;
begin
  FManufacturer := FCPUInfo.Manufacturer;
end;

procedure TCPUInfo.GetCPUName;
begin
  FCPUName := FCPUInfo.CPU_Name;
end;

procedure TCPUInfo.GetPType;
begin
  FPType := FCPUInfo.PType;
end;

procedure TCPUInfo.GetFamily;
begin
  FFamily := FCPUInfo.Family;
end;

procedure TCPUInfo.GetModel;
begin
  FModel := FCPUInfo.Model;
end;

procedure TCPUInfo.GetStepping;
begin
  FStepping := FCPUInfo.Stepping;
end;

procedure TCPUInfo.GetCPUSpeed;
const
  TimeOfDelay = 500;
var
  TimerHigh,
  TimerLow: DWord;
begin
  SetPriorityClass(GetCurrentProcess, REALTIME_PRIORITY_CLASS);
  SetThreadPriority(GetCurrentThread,
  THREAD_PRIORITY_TIME_CRITICAL);
  asm
    dw 310Fh
    mov TimerLow, eax
    mov TimerHigh, edx
  end;
  Sleep(TimeOfDelay);
  asm
    dw 310Fh
    sub eax, TimerLow
    sub edx, TimerHigh
    mov TimerLow, eax
    mov TimerHigh, edx
  end;
  FCPUSpeed := TimerLow / (1000.0 * TimeOfDelay);
end;

procedure TCPUInfo.GetCPUInfo(var FCPUInfo: TCPU);
begin
  FCPUInfo := FCPUID;
  FCPUInfo.IDFDIVOK := FTestFDIVInstruction;
  if (FCPUInfo.Features and MMX_FLAG) = MMX_FLAG then
     FCPUInfo.MMX := True
  else
    FCPUInfo.MMX := False;
end;

function TCPUInfo.GetCPUID: TCPU;
type
  regconvert = record
    bits0_7: Byte;
    bits8_15: Byte;
    bits16_23: Byte;
    bits24_31: Byte;
  end;
var
   CPUInfoEx: TCpu;
   TEBX, TEDX, TECX: Cardinal;
   TString: String;
   VString: String;
begin
     asm
        MOV  [CPUInfoEx.PType], 0
        MOV  [CPUInfoEx.Model], 0
        MOV  [CPUInfoEx.Stepping], 0
        MOV  [CPUInfoEx.Features], 0

        push eax
        push ebp
        push ebx
        push ecx
        push edi
        push edx
        push esi

     @@Check_80486:
        MOV  [CPUInfoEx.Family], 4
        MOV  TEBX, 0
        MOV  TEDX, 0
        MOV  TECX, 0
        PUSHFD
        POP  EAX
        MOV  ECX,  EAX
        XOR  EAX,  200000H
        PUSH EAX
        POPFD
        PUSHFD
        POP  EAX
        XOR  EAX,  ECX
        JE   @@DONE_CPU_TYPE

     @@Has_CPUID_Instruction:
        MOV  EAX,  0
        DB   0FH
        DB   0A2H

        MOV  TEBX, EBX
        MOV  TEDX, EDX
        MOV  TECX, ECX

        MOV  EAX,  1
        DB   0FH
        DB   0A2H

        MOV  [CPUInfoEx.Features], EDX

        MOV  ECX,  EAX

        AND  EAX,  3000H
        SHR  EAX,  12
        MOV  [CPUInfoEx.PType], AL

        MOV  EAX,  ECX

        AND  EAX,  0F00H
        SHR  EAX,  8
        MOV  [CPUInfoEx.Family], AL

        MOV  EAX,  ECX

        AND  EAX,  00F0H
        SHR  EAX,  4
        MOV  [CPUInfoEx.MODEL], AL

        MOV  EAX,  ECX

        AND  EAX,  000FH
        MOV  [CPUInfoEx.Stepping], AL

     @@DONE_CPU_TYPE:

        pop  esi
        pop  edx
        pop  edi
        pop  ecx
        pop  ebx
        pop  ebp
        pop  eax
     end;

     If (TEBX = 0) and (TEDX = 0) and (TECX = 0) and (CPUInfoEx.Family = 4) then
     begin
          CPUInfoEx.VendorIDString := 'unknown';
          CPUInfoEx.Manufacturer := 'unknown';
          CPUInfoEx.CPU_Name := 'Generic 486';
     end
     else
     begin
          With regconvert(TEBX) do
          begin
               TString := CHR(bits0_7) + CHR(bits8_15) + CHR(bits16_23) + CHR(bits24_31);
          end;
          With regconvert(TEDX) do
          begin
               TString := TString + CHR(bits0_7) + CHR(bits8_15) + CHR(bits16_23) + CHR(bits24_31);
          end;
          With regconvert(TECX) do
          begin
               TString := TString + CHR(bits0_7) + CHR(bits8_15) + CHR(bits16_23) + CHR(bits24_31);
          end;
          VString := TString;
          CPUInfoEx.VendorIDString := TString;
          If (CPUInfoEx.VendorIDString = 'GenuineIntel') then
          begin
               CPUInfoEx.Manufacturer := 'Intel';
               Case CPUInfoEx.Family of
               4: Case CPUInfoEx.Model of
                  1: CPUInfoEx.CPU_Name := 'Intel 486DX Processor';
                  2: CPUInfoEx.CPU_Name := 'Intel 486SX Processor';
                  3: CPUInfoEx.CPU_Name := 'Intel DX2 Processor';
                  4: CPUInfoEx.CPU_Name := 'Intel 486 Processor';
                  5: CPUInfoEx.CPU_Name := 'Intel SX2 Processor';
                  7: CPUInfoEx.CPU_Name := 'Write-Back Enhanced Intel DX2 Processor';
                  8: CPUInfoEx.CPU_Name := 'Intel DX4 Processor';
                  else CPUInfoEx.CPU_Name := 'Intel 486 Processor';
                  end;
               5: CPUInfoEx.CPU_Name := 'Pentium';
               6: Case CPUInfoEx.Model of
                  1: CPUInfoEx.CPU_Name := 'Pentium Pro';
                  3: CPUInfoEx.CPU_Name := 'Pentium II (Model 3)';
                  5: CPUInfoEx.CPU_Name := 'Pentium II (Model 5)';
                  6: CPUInfoEx.CPU_Name := 'Intel Celeron (Model 6)';
                  7: CPUInfoEx.CPU_Name := 'Pentium II (Model 7)';
                  8: CPUInfoEx.CPU_Name := 'Pentium III (Model 8)';
                  else CPUInfoEx.CPU_Name := Format('P6 (Model %d)', [CPUInfoEx.Model]);
                  end;
               15: CPUInfoEx.CPU_Name := 'Pentium IV';
               else CPUInfoEx.CPU_Name := Format('P %d', [CPUInfoEx.Family]);
               end;
          end
          else if (CPUInfoEx.VendorIDString = 'CyrixInstead') then
          begin
                CPUInfoEx.Manufacturer := 'Cyrix';
                Case CPUInfoEx.Family of
                5: CPUInfoEx.CPU_Name := 'Cyrix 6x86';
                6: CPUInfoEx.CPU_Name := 'Cyrix M2';
                else CPUInfoEx.CPU_Name := Format('%dx86', [CPUInfoEx.Family]);
                end;
          end
          else if (CPUInfoEx.VendorIDString = 'AuthenticAMD') then
          begin
               CPUInfoEx.Manufacturer := 'AMD';
               Case CPUInfoEx.Family of
               4: CPUInfoEx.CPU_Name := 'Am486 or Am5x86';
               5: Case CPUInfoEx.Model of
                  0: CPUInfoEx.CPU_Name := 'AMD-K5 (Model 0)';
                  1: CPUInfoEx.CPU_Name := 'AMD-K5 (Model 1)';
                  2: CPUInfoEx.CPU_Name := 'AMD-K5 (Model 2)';
                  3: CPUInfoEx.CPU_Name := 'AMD-K5 (Model 3)';
                  6: CPUInfoEx.CPU_Name := 'AMD-K6';
                  7: CPUInfoEx.CPU_Name := 'AMD-K6 (Model 7)';
                  8: CPUInfoEx.CPU_Name := 'AMD-K6-2 (Model 8)';
                  9: CPUInfoEx.CPU_Name := 'AMD-K6-III (Model 9)';
                  else CPUInfoEx.CPU_Name := 'Unknown AMD Model';
                  end;
               6: Case CPUInfoEx.Model of
                  1: CPUInfoEx.CPU_Name := 'AMD Athlon (Model 1)';
                  2: CPUInfoEx.CPU_Name := 'AMD Athlon (Model 2)';
                  3: CPUInfoEx.CPU_Name := 'AMD Duron';
                  4: CPUInfoEx.CPU_Name := 'AMD Athlon (Model 4)';
                  6: CPUInfoEx.CPU_Name := 'AMD Athlon XP';
                  10: CPUInfoEx.CPU_Name := 'AMD Athlon XP';
                  else CPUInfoEx.CPU_Name := 'unknown AMD-Prozessor';
                  end;
               end;
          end
          else
          begin
               CPUInfoEx.VendorIDString := TString;
               CPUInfoEx.Manufacturer := 'Unknown';
               CPUInfoEx.CPU_Name := 'Unknown';
          end;
     end;
     result := CPUInfoEx;
end;

procedure TCPUInfo.TestFDIVInstruction;
var
   TopNum:    Double;
   BottomNum: Double;
   One:       Double;
   ISOK:      Boolean;
begin
     { The following code was found in Borlands
       fdiv.asm file in the Delphi 3\Source\RTL\SYS
       directory, ( I made some minor modifications )
       therefor I cannot take credit for it }

     TopNum     := 2658955;
     BottomNum  := PI;
     One        := 1;

     asm
        PUSH    EAX
        FLD     [TopNum]
        FDIV    [BottomNum]
        FMUL    [BottomNum]
        FSUBR   [TopNum]
        FCOMP   [One]
        FSTSW   AX
        SHR     EAX, 8
        AND     EAX, 01H
        MOV     ISOK, AL
        POP     EAX
     end;
     FTestFDIVInstruction := ISOK;
end;

//procedure GetCPUInfo(Var CPUInfo: TCpu);
//begin
//  CPUInfo := FCPUID;
//  CPUInfo.IDFDIVOK := TestFDIVInstruction;
//  if (CPUInfo.Features and MMX_FLAG) = MMX_FLAG then
//     CPUInfo.MMX := True
//  else
//    CPUInfo.MMX := False;
//end;

function getprocessortype:string;
var
   systeminfo:tsysteminfo;
   zw:string;
begin
     getsysteminfo(systeminfo);
     case systeminfo.dwprocessortype of
          386:zw:='Intel 80386';
          486:zw:='Intel 80486';
          586:zw:='Intel Pentium';
          860:zw:='Intel 860';
          2000:zw:='MIPS R2000';
          3000:zw:='MIPS R3000';
          4000:zw:='MIPS R4000';
         21064:zw:='ALPHA 21064';
     else ZW:='Processor nicht klassifiziert';
     end;

     result:=zw;
end;

function GetProcessorCount:integer;
var
systeminfo:tsysteminfo;
begin
     getsysteminfo(systeminfo);
     result:=systeminfo.dwnumberofprocessors;
end;

function GetCPUSpeed: string;
const
     TimeOfDelay = 500;
var
   TimerHigh,
   TimerLow: DWord;
   //s : string;
   //f : real;
begin
     SetPriorityClass(GetCurrentProcess, REALTIME_PRIORITY_CLASS);
     SetThreadPriority(GetCurrentThread,
     THREAD_PRIORITY_TIME_CRITICAL);
     asm
        dw 310Fh
        mov TimerLow, eax
        mov TimerHigh, edx
     end;
     Sleep(TimeOfDelay);
     asm
        dw 310Fh
        sub eax, TimerLow
        sub edx, TimerHigh
        mov TimerLow, eax
        mov TimerHigh, edx
     end;
     Result := format('%.0f', [TimerLow / (1000.0 * TimeOfDelay)])+ ' MHz';
end;

end.
