![Delphi-7 Pro](https://github.com/user-attachments/assets/2d892a9f-737d-4a45-9fe0-37aab408ca81)# nonVCL:

</br>

![Compiler](https://github.com/user-attachments/assets/a916143d-3f1b-4e1f-b1e0-1067ef9e0401) ![Delphi-All Compiler Versions](https://github.com/user-attachments/assets/55096613-6860-412e-b4cd-860934e109b6)  
![Components](https://github.com/user-attachments/assets/d6a7a7a4-f10e-4df1-9c4f-b4a1a8db7f0e) ![None](https://github.com/user-attachments/assets/30ebe930-c928-4aaf-a8e1-5f68ec1ff349)  
![Discription](https://github.com/user-attachments/assets/4a778202-1072-463a-bfa3-842226e300af) ![nonVCL Collection](https://github.com/user-attachments/assets/9946689b-ec70-4032-8c86-361ee7ec722e)  
![Last Update](https://github.com/user-attachments/assets/e1d05f21-2a01-4ecf-94f3-b7bdff4d44dd) ![122025](https://github.com/user-attachments/assets/2123510b-f411-4624-a2fc-695ffb3c4b70)  
![License](https://github.com/user-attachments/assets/ff71a38b-8813-4a79-8774-09a2f3893b48) ![Freeware](https://github.com/user-attachments/assets/1fea2bbf-b296-4152-badd-e1cdae115c43)  

</br>

Recommended compiler for this section:  

![Delphi-7 Pro](https://github.com/user-attachments/assets/d694645a-9959-47bd-be32-6707d06b2f0c)  ![Delphi-7 Enterprise](https://github.com/user-attachments/assets/576fc937-5c99-40ef-9c19-3957c686bf35)  ![Delphi-7 Science Edition 2020](https://github.com/user-attachments/assets/7e21dfba-f9a4-4871-aff0-a4f2ebe8941c)

</br>

### Why is an empty Delphi application almost 300 KB - 3 MB in size?

Because the [VCL](https://de.wikipedia.org/wiki/Visual_Component_Library) provides a generic interface for all sorts of functions of the [Win32 API](https://en.wikipedia.org/wiki/Windows_API). Take [OLE](https://en.wikipedia.org/wiki/OLE_Automation), for example. Most people hardly ever need an OLE interface in their application. However, Delphi, or rather Smart Compiling, doesn't allow these unnecessary parts to be omitted. This has led to XCL and other such feats.

The fact that objects ([classes](https://docwiki.embarcadero.com/RADStudio/Sydney/en/Classes_and_Objects_(Delphi))) also store various pieces of information that are not vital to the actual program adds to the problem.

Of course, EXE files can be compressed or otherwise reduced in size, but the file size is generally still too large because the VCL library is also reduced in size.

There's a big difference between creating an empty form that's ```3 megabytes``` in size and creating the same form in ```50 KB```, which is essentially the same without needing to compress it. The answer is simply ```nonVCL```.

The problem is that a ```nonVCL``` window has to be programmed completely by hand, which is seen in certain circles as the most difficult form of programming.

Let's look at some basics.

To understand the window principle, we first need to move beyond TForms. Windows, in fact, gave the system its name. Every window has various properties that describe it. Windows recognizes two basic structures: the basic structure and the extended structure.

### Let's consider the basic structure.

</br>

```pascal
tagWNDCLASSA = packed record
  style: UINT;
  lpfnWndProc: TFNWndProc;
  cbClsExtra: Integer;
  cbWndExtra: Integer;
  hInstance: HINST;
  hIcon: HICON;
  hCursor: HCURSOR;
  hbrBackground: HBRUSH;
  lpszMenuName: PAnsiChar;
  lpszClassName: PAnsiChar;
end;
```

</br>

For simplicity, only the ANSI version is shown here. On NT platforms, corresponding Unicode (Wide) counterparts can be found. The structure is declared as ```TWndClass```.  
The extended structure (“…Ex”), in which ```WINDOWS.PAS``` is declared as ```TWndClassEx```, can be seen here.

</br>

```pascal
tagWNDCLASSEXA = packed record
  cbSize: UINT;
  style: UINT;
  lpfnWndProc: TFNWndProc;
  cbClsExtra: Integer;
  cbWndExtra: Integer;
  hInstance: HINST;
  hIcon: HICON;
  hCursor: HCURSOR;
  hbrBackground: HBRUSH;
  lpszMenuName: PAnsiChar;
  lpszClassName: PAnsiChar;
  hIconSm: HICON;
end;
```

</br>

As you can see, the two versions differ only in that the extended version requires the size of the structure to be specified and allows for the inclusion of a small icon.

Both structures describe a window class (not a class in the OOP sense) 😉
To use the class, it must have at least a name ```lpszClassName```, the instance of the calling module usually ```hInstance``` in Delphi, and, in the extended version, the size of the structure.

</br>

```pascal
procedure initacomctl;
var
  wc: TWndClassEx;
begin
  wc.style := CS_HREDRAW OR CS_VREDRAW OR CS_GLOBALCLASS;
  wc.cbSize := sizeof(TWNDCLASSEX);
  wc.lpfnWndProc := @HyperlinkWndProc;
  wc.cbClsExtra := 0;
  wc.cbWndExtra := 0;
  wc.hInstance := hInstance;
  wc.hbrBackground := COLOR_WINDOW;
  wc.lpszMenuName := NIL;
  wc.lpszClassName := AHyperlink;
  wc.hIcon := 0;
  wc.hIconSm := 0;
  wc.hCursor := 0;
  RegisterClassEx(wc);
end; {HLinkTest Example}
```

</br>

The final call to ```RegisterClassEx()``` or ```RegisterClass()``` registers the window class for the program instance and enables the call to ```CreateWindowEx()``` or ```CreateWindow()```.

The above procedure is the initialization routine for a demonstration program I created. The goal is to show how to...

1.Dialog templates are used.
2.Custom window classes are integrated via dialog templates.
3.Custom window classes are built.

A typical window procedure:

```pascal
function WndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM;
 lParam: LPARAM): LRESULT; stdcall;
```

</br>

A typical dialogue procedure:

```pascal
function DlgProc(hWnd: HWND; uMsg: dword; wParam: WPARAM;
 lParam: LPARAM): BOOL; stdcall;
```

Note: ```STDCALL``` must always be defined!

Comparing the two statements, the only real difference lies in the return type. In fact, both perform a similar task: evaluating and processing window messages.

Window messages are simple integer values ​​that signal a specific event related to the window. This could be a simple mouse click, but just as easily a Winsock event.

Messages that are not handled by the respective window procedure should be handled by a default handler. The dialog procedure signals ```FALSE``` to indicate that the default handler still needs to be called. And the "real" window procedure itself calls the default handler.

```pascal
Result:=DefWindowProc(hWnd, uMsg, wParam, lParam);
```

# Create a Window in 50 Kb:
From all these assumptions, the following small program framework can be developed.

This example creates a main window and a button within it. It also demonstrates how to intercept when the button is pressed. All of this is accomplished without using any dialog resources.

```pascal
program Window;

uses 
   windows,messages;

{$WARNINGS OFF}
{$HINTS OFF}

const
  windowleft: integer = 100;
  windowtop: integer = 100;
  windowwidth: integer = 265;
  windowheight: integer = 202;
  ClassName = 'ATestWndClassEx';

function WndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM;
lParam: LPARAM): LRESULT; stdcall;
var IDOK: DWORD;
begin
  Result := 0;
  case uMsg OF
    WM_CREATE:
      begin
        IDOK := createwindow('BUTTON', 'OK-Button',
        WS_VISIBLE OR WS_CHILD, 100, 100, 100, 30, hwnd, 0, hInstance,
        NIL);
        if IDOK = INVALID_HANDLE_VALUE then
          MessageBox(hwnd, 'Button nicht erzeugt', 'Meldung', 0);
      end;
    WM_DESTROY:
      begin
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      if hiword(wparam) = BN_CLICKED then
        if loword(wparam) = IDOK then
          MessageBox(hwnd, 'OK Button gedrückt', 'Meldung', 0);
  else
    Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

var wc: TWndClassEx = (
    cbSize: SizeOf(TWndClassEx);
    style: CS_OWNDC OR CS_HREDRAW OR CS_VREDRAW;
    cbClsExtra: 0;
    cbWndExtra: 0;
    hbrBackground: COLOR_WINDOW;
    lpszMenuName: NIL;
    lpszClassName: ClassName;
    hIconSm: 0; );
{    mainwnd:DWORD;}   //not needed
  msg: TMSG;
  rect: trect;
  deskh, deskw: integer;

(* In Delphi, tagNONCLIENTMETRICS is the internal Windows API
   name for the TNonClientMetrics record (defined in the Winapi.Windows
   unit). It is used to retrieve or set the scalable metrics (sizes
   and fonts) of the non-client area of non-minimized windows, such
   as title bars, menus, and borders.*)

  //ncm: tagNONCLIENTMETRICS;
begin
  wc.hInstance := HInstance;
  wc.hIcon := LoadIcon(HInstance, MAKEINTRESOURCE(1));
  wc.hCursor := LoadCursor(0, IDC_ARROW);
  wc.lpfnWndProc := @WndProc;
  systemparametersinfo(SPI_GETWORKAREA, 0, @rect, 0);
  deskw := rect.Right - rect.Left;
  deskh := rect.Bottom - rect.Top;

  // this section is for older compiler versions of delphi
  //ncm.cbSize := sizeof(ncm);
  //systemparametersinfo(SPI_GETNONCLIENTMETRICS, sizeof(ncm), @ncm, 0);
  //windowwidth := windowleft + windowwidth;
  //windowheight := windowtop + windowheight + ncm.iMenuHeight +
  //ncm.iCaptionHeight;
  //Windowleft := (deskw DIV 2) - (windowwidth DIV 2);
  //Windowtop := (deskh DIV 2) - (windowheight DIV 2);
  RegisterClassEx(wc);
    {mainwnd:=} CreateWindowEx(WS_EX_WINDOWEDGE OR WS_EX_CONTROLPARENT
    OR WS_EX_APPWINDOW,
    ClassName,
    'Window',
    WS_OVERLAPPED
    OR WS_CAPTION
    OR WS_SYSMENU
    OR WS_MINIMIZEBOX
    OR WS_VISIBLE,
    windowleft,
    windowtop,
    windowwidth,
    windowheight,
    0,
    0,
    hInstance,
    NIL);
  while True do begin
    if not GetMessage(msg, 0, 0, 0) then break; //oops :o)
    translatemessage(msg);
    dispatchmessage(msg);
  end;
  ExitCode := GetLastError;
end.
````

This code creates an EXE file that is 54 kb under Delphi v22, without compression.

</br>

# Integrate dialog windows:
If we now take a simple example of a program that has exactly the same function, but is based on a dialog template, the source code looks correspondingly simpler:

```pascal
program Dialog;
uses windows, messages;

{$WARNINGS OFF}
{$HINTS OFF}
{$R main.res} // The template goes here

var
  hdlg: DWORD = 0;

function dlgfunc(hwnd: hwnd; umsg: dword; wparam: wparam;
 lparam: lparam): bool; stdcall;
begin
  result := true;
  CASE umsg OF
    WM_CLOSE:
      EndDialog(hWnd, 0);
    WM_DESTROY:
      PostQuitMessage(0);
    WM_COMMAND:
      IF hiword(wparam) = BN_CLICKED THEN BEGIN
        CASE loword(wparam) OF
          IDOK:
            sendmessage(hwnd, WM_CLOSE, 0, 0);
        end;
      end;
  else result := false;
  end;
end;

begin
  // The only new call to action here is:	
  hdlg := DialogBoxParam(HInstance, MAKEINTRESOURCE(100), 0, @DlgFunc, 0);
end.
```

</br>

This creates the dialog from the resource with ID 100. A window procedure is assigned, and the message loop is automatically started.

What you can see fairly clearly here is the inclusion of the dialog template. This is done by including MAIN.RES. This compiled resource file is compiled from a "resource script" using the resource compiler ```BRCC32.EXE```.

In our case, the script looks like this:
```pascal
LANGUAGE LANG_NEUTRAL, SUBLANG_NEUTRAL
````

# Update Program list:
* [Window](https://github.com/Real-hackbard/nonVCL/tree/main/Window)
* [Euro Calculator](https://github.com/Real-hackbard/nonVCL/tree/main/Euro%20Calculator)
* [FileCrypter](https://github.com/Real-hackbard/nonVCL/tree/main/FileCrypter)
