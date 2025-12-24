# nonVCL:

### Why is an empty Delphi application almost 300 KB - 3 MB in size?

Because the VCL provides a generic interface for all sorts of functions of the Win32 API. Take OLE, for example. Most people hardly ever need an OLE interface in their application. However, Delphi, or rather Smart Compiling, doesn't allow these unnecessary parts to be omitted. This has led to XCL and other such feats.

The fact that objects (classes) also store various pieces of information that are not vital to the actual program adds to the problem.

Of course, EXE files can be compressed or otherwise reduced in size, but the file size is generally still too large because the VCL library is also reduced in size.

There's a big difference between creating an empty form that's 3 megabytes in size and creating the same form in 50 KB, which is essentially the same without needing to compress it. The answer is simply nonVCL.

The problem is that a nonVCL window has to be programmed completely by hand, which is seen in certain circles as the most difficult form of programming.

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









