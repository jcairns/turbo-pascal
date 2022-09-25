(* PROGRAM Seek;

   SEEK 2.03, Copyright (c) 2004, Jody R. Cairns

   SEEK is a DOS utility which searches for files specified on the command-
   line.  There are many options, including: search files by size; search
   files by attribute; search specific or all drives; run file if found;
   search for a specific string within files; and run a command on any found
   files. More than one file can be specified on the command-line and options
   can appear in any order.  See procedures DisplayOptions and DisplayHelp for
   more information.

   The source to this program (this file) is available for a small fee with
   the condition that I am notified of any modifications made to this
   program, and the executable of the MODIFIED program is NOT distributed
   without my permission (i.e. Don't pull a fast one like making a few
   changes to the source, compiling it, and saying you wrote it.).

   It would be very much appreciated if any code used from this program is
   credited to me (bearing in mind that I take absolutely no responsibility
   for the results or misuse of the execution or use of said code).

   NOTE: this program is not very modular due to the speed factor. I wanted
         to make this as fast as possible without adding much assembly code
         and still have sufficient error-checking.  Too many procedures
         would have slowed it down (I timed it). So, please excuse this
         programming oversight; it was done for speed. However, you will
         notice I could have been LESS modular; code size was a factor, too.


Version changes (for those interested)
===============

SEEK 2.03:
---------
 1) Updated email address and copyright notice.

SEEK 2.02:
---------
 1) Incorrectly detected DOS versions.  This has been fixed.

SEEK 2.01:
---------
 1) Fixed non-enhanced keyboard bug.

 2) String operations optimized with my own string functions.


SEEK 2.0:
--------
 1) Optimized to be much faster than previous versions and most (if not
    all) other file searching utilities (that include as many features).

 2) GREP-like string searching is now available.  The string is simply
    placed between quotes anywhere on the command-line.  However, unlike
    GREP, the string is not displayed; but the offset where it was found
    can be displayed.  The search algorithm is very fast.

 3) New options:
   /B  ---------- begin searching in the current directory.  By default,
                  SEEK begins from the root directory.
   /C  ---------- change to the directory of the first matching file.
                  Execution is also halted with this option.
   /F  ---------- seek only files.  Directory entries are ignored.  To
                  seek only directories, specify the /AD option.
   /L  ---------- ignore letter-case during string search.
   /O  ---------- display the offset where a found string was found
                  within file.  The offset is displayed in hexadecimal.
   /Q  ---------- quit seeking when the first matching file is found.
   /T  ---------- as with option /O, except the offset is displayed in
                  decimal.

 4) All numbers greater than 999 are now displayed with a thousands comma
    separator.  Thanks to Ivan Hofsajer for the original suggestion.

 5) SEEK should recgonize networks.  A user of a previous version of SEEK
    informed me that the /D option (scan all drives) did not recgonize
    all the drives on his network.  This has been fixed, I think.  If the
    network drives are not scanned with the /D option now, please let me
    know.

 6) Pressing <Esc> or <Ctrl-Break> halts execution cleanly.

 7) The directories . and .. (representing the current and parent direc-
    tories, respectively) are no longer displayed.

 8) Made major changes to how the command-line parameters are
    processed due to string search addition. Previously, the command-
    line was scanned twice separately using FOR loops.  The first loop
    processed any options, and the second loop checked for the files
    to seek.  Now, the command-line is scanned once, processing the
    options at that time, checking for a search string, and storing any
    files to seek in an array.  This now limits the number of files
    can be seeked.

 9) Replaced the following functions with my own (faster) versions:
     - CRT.keypressed,
     - DOS.dosverion,
     - system.copy,
     - system.upcase,
     - system.fillchar,
     - system.delete,
     - improved the /A option processing. Previously, each attribute
       had a boolean varaible associated with it so that a long IF
       statement was used to compare whether that attribute should
       be considered.  Now, the file attributes specified by the user
       are simply stored in a word type and only that is compared
       to the current seeked file attribute. Much simpler and faster.

10) Any drives specified on the command-line are all scanned.  In previous
    versions of SEEK, the drives preceding the file name were the only
    drives scanned for that file.  Now all drives specifed are scanned -
    the drives are acumalative.  Thus, for
      SEEK a: tmp b:*.bak
    drives A and B are both scanned for files TMP and *.BAK.

11) The /D option no longer takes precedence.  If any drives are specified
    on the command-line, the /D option is disabled.

12) Any procedure called by the recursive procedure SeekFile do not contain
    any local variables, except SeekFile itself.  This reduces the chance
    of stack overflow error since variables won't be allocated on the stack,
    and makes SEEK faster, too.

13) Files being seeked, the drives being scanned, and any string being
    searched for are now displayed.


SEEK 1.1:
--------
 1) Replaced system.pos with ChPos and CRT.readkey with my own simpler
    versions.

 2) In SEEK 1.0, if the following was executed:
      SEEK acd:tmp1 tmp2
    then for TMP1, drives A, C and D would be searched, but for
    TMP2, only drives C and D would be searched.  This was a bug.
    Now, TMP2 will be searched for on the current drive using the
    above example. In other words, the drives you specified to be
    search on one file will NOT be carried over onto any other
    files specified on the command-line. Thus, for:
      SEEK acd:tmp1 c:tmp2
    drives A, C and D for TMP1, and only drive C for TMP2 will be
    searched (not drives A and D, too).

 3) With systems that viewed A: and B: as the same logical drive,
    SEEK 1.0 with the /D option (search all drives) would force
    the drive to be assumed as B:.  Now, the drive is forced to be
    drive A: instead (which is logical), skipping over drive B:.


   SEEK was written and compiled using Turbo Pascal 6.0 and tested on a variety
   of Personal Computers, from 8086s to 80486s.

   If you find ANY bugs, or have any suggestions or ideas I'd be happy to
   hear from you.  Please don't hesitate to contact me for any information.
   I have more utilites in the works, all DOS-based. Here's my address:

   Jody R. Cairns
   jcairns@gmail.com

*)


(* Compiler directives follow: *)

{$M 65520, 0, 0}  (* Memory requirements: 64 KB for stack, 0 KB for heap    *)

{$I-}             (* I/O checking off                 *)
{$R-}             (* Range checking off               *)
{$S-}             (* Stack checking off               *)
{$X+}             (* Extended syntax off              *)
{$V-}             (* Strict VAR-string checking off   *)
{$B-}             (* Short-circuit boolean evaluation *)
{$D-}             (* Debug information off            *)
{$L-}             (* Local debug information off      *)
{$E-}             (* 8087 emulation off               *)
{$N-}             (* 8087/80287 code generation off   *)
{$G-}             (* 80286 code generation off        *)
{$F-}             (* Force far calls off              *)
{$A+}             (* Word align data                  *)
{$O-}             (* Overlays not allowed             *)


USES
  CRT, DOS;       (* CRT.TPU and DOS.TPU required *)


LABEL
  NextDrive,
  Okay,
  NextParam;      (* Used for goto statements     *)


CONST
  Title        = 'SEEK 2.03, Copyright (c) 2004, Jody R. Cairns';

  MaxFileSize  = maxlongint;  (* Maximum size of a file           *)
  MinFileSize  = 0;           (* Minimum size of a file           *)
  Esc          = #27;         (* ASCII code of <Esc> key          *)
  MaxFiles     = 12;
  MaxBufSize   = 1024 * 60;
  MaxDirLength = 67;          (* Maximum length of adirectory     *)
  MaxStrLength = 125;         (* Maximum length of search string  *)
  CtrlBreakInt = $1B;         (* Ctrl-Break interrupt number      *)


TYPE
  NumStr       = string[80];

  HexStr       = string[11];

  DriveStr     = string[26];

  AttrStr      = string[4];

  FindStr      = string[MaxStrLength];

  FileSizeFunc = FUNCTION (FileSize: longint): boolean;

  OffsetFunc   = FUNCTION (StrOffset: longint): NumStr;

  CaseFunc     = FUNCTION (Ch: char): char;

  WriteProc    = PROCEDURE (Str: string);

  DigitArray   = ARRAY[$00..$0F] OF char;

  BufferArray  = ARRAY[1..MaxBufSize] OF char;

  BMTable      = ARRAY[0..255] OF byte;

  FileList     = ARRAY[1..MaxFiles] OF ComStr;

  DriveRec     = RECORD
		   Number: byte;
		   Letter: DriveStr
	         END;


CONST
  ExecuteCommand: boolean  = FALSE;  (* execute a command of found files  *)
  RunFile       : boolean  = FALSE;  (* run files if found                *)
  BeginCurDir   : boolean  = FALSE;
  ChangeDir     : boolean  = FALSE;
  IgnoreCase    : boolean  = FALSE;
  DisplayOffset : boolean  = FALSE;
  ShowInfo      : boolean  = FALSE;  (* show file information             *)
  AllDrives     : boolean  = FALSE;  (* search all drives                 *)
  QuitWhenFound : boolean  = FALSE;
  SeekSize      : boolean  = FALSE;  (* seek files by size                *)
  FindString    : boolean  = FALSE;  (* search files for specified string *)
  SeekAttr      : boolean  = FALSE;  (* seek files by their attributes    *)
  NotInHelp     : boolean  = TRUE;   (* help information is displayed     *)
  EscPressed    : boolean  = FALSE;
  SeekFileOnly  : boolean  = FALSE;
  CtrlBreak     : boolean  = FALSE;
  DriveBForced  : boolean  = FALSE;
  FilesFound    : longint  = 0;      (* # of files found                  *)
  DirFiles      : longint  = 0;
  DirSize       : longint  = 0;
  SumSizes      : longint  = 0;
  SeekNumber    : byte     = 0;
  NumFiles      : byte     = 0;
  FileAttr      : byte     = 0;
  CurrRow       : byte     = 1;      (* current row being output to       *)
  StartDrive    : byte     = 1;      (* assume system has drive a: (1)    *)
  DriveError    : byte     = 0;
  Drives        : DriveStr = '';
  Dir           : DirStr   = '\';

  Drive         : DriveRec   = (Number: 0;
                                Letter: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
  Digits        : DigitArray = ('0', '1', '2', '3', '4' ,'5', '6', '7',
                                '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');

VAR
  Found: boolean;
  NumRows,                      (* # of rows on output screen        *)
  PC,                           (* # of parameters on command-line   *)
  ColonPos      : byte;         (* used for ChPos function           *)
  BytesRead,
  Tmp,                          (* temporary storage                 *)
  K, I, J       : word;         (* indices                           *)
  Int           : integer;      (* temporary storage                 *)
  TmpLong,                      (* temporary storage                 *)
  StringOffset,                 (* Offset of string embedded in file *)
  MinSize,                      (* minimum size of file to find      *)
  MaxSize       : longint;      (* maximum size of a file to find    *)
  Ch            : char;
  Attr          : AttrStr;      (* attributes of a file              *)
  Ext           : ExtStr;       (* extension of a file               *)
  Name          : NameStr;      (* name of a file                    *)
  CurrDir       : DirStr;       (* current directory                 *)
  TmpStr,                       (* temporary storage                 *)
  Param,                        (* parameters to run with files      *)
  SizeStr,                      (* size of files to find             *)
  Command       : ComStr;       (* command to run on found files     *)
  StrToFind     : FindStr;
  Comspec       : string;
  Error         : string[160];
  FileDate      : DateTime;     (* file date and time                *)
  ValidFileSize : FileSizeFunc; (* function to determine file size   *)
  Offset        : OffsetFunc;
  ChCase        : CaseFunc;
  Writeln       : WriteProc;    (* output procedure                  *)
  BMT           : BMTable;
  Buffer        : BufferArray;
  Seek          : FileList;
  FoundFile     : file;
  OldBreakVector: pointer;

(****************************************************************************)
(****************************************************************************)

(* Assembler routines *)
(* ================== *)

FUNCTION KeyPressed: boolean; assembler;
(* Returns TRUE if a key is pressed.                     *)
  ASM
    mov ah, 01h     (* Report whether character is ready *)
    int 16h         (* Call Keyboard function            *)
    mov al, 00h     (* Assume FALSE                      *)
    jz  @Done       (* Zero flag set? Yes, then no input *)
    inc al          (* Key was pressed; return TRUE      *)
  @Done:
  END;

(****************************************************************************)

FUNCTION ReadKey: char; assembler;
(* Returns ASCII code of key pressed, unless it's special key. *)
  ASM
    xor ah, ah      (* Read character pressed on keyboard      *)
    int 16h         (* Call Keyboard function                  *)
  END;

(****************************************************************************)

FUNCTION ChPos (Ch: char; Str : ComStr) : byte; assembler;
(* This is a much faster version of the system.pos function except that
   this function searches only for a character, not a sub-string.    *)
  ASM
    cld                  (* Forward string-ops                       *)
    les   di, Str        (* Load string address                      *)
    mov   cx, es:[di]       (* Load string length                       *)
    jcxz  @1             (* Exit if string length = 0                *)
    mov   bl, cl         (* Save string length                       *)
    xor   ch, ch         (* Only want lower word                     *)
    inc   di             (* Start index at beginning of Str          *)
    mov   al, &Ch        (* Load character to find                   *)
    repne scasb          (* Scan Str for character                   *)
    jne   @1             (* Jump if we didn't find                   *)
    sub   bl, cl         (* Subtract index from Str length for index *)
    mov   al, bl         (* Return position found                    *)
    jmp   @2             (* Get outta here                           *)
  @1:
    xor   al, al         (* Character wasn't found                   *)
  @2:
END; (* ChPos *)

(****************************************************************************)

PROCEDURE Delete (VAR Str: string; Index, Count: word); assembler;
(* Same as the standard system.delete except much faster.          *)
  ASM
    mov  bx, ds       (* Save ds                                   *)
    mov  cx, Count    (* cx = Count                                *)
    mov  ax, Index    (* ax = Index                                *)
    dec  ax           (* Index = Index - 1; adjust for length byte *)
    cwd               (* dx = FFFFh if ax < 0, else dx = 0         *)
    and  dx, ax       (* dx = Index, or 0                          *)
    sub  ax, dx       (* Adjusted Index = 0 (or index)             *)
    add  dx, cx       (* Adjusted Count = Index + Count (or Count) *)
    jle  @End         (* Exit if new count <= 0                    *)
    lds  si, Str      (* Load source string                        *)
    mov  cl, ds:[si]  (* cl = length (string)                      *)
    xor  ch, ch       (* Clear msb of string length                *)
    sub  cx, ax       (* Length = length - index + 1               *)
    jle  @End         (* Exit if Length <= 0                       *)
    sub  cx, dx       (* # chars to move = length-count-index+1    *)
    jg   @MoveChar    (* Continue if # of chars > 0                *)
    mov  ds:[si], al  (* Else new length = index - 1               *)
    jmp  @End         (* Exit                                      *)
  @MoveChar:
    cld               (* Forward string-ops                        *)
    mov  di, ds       (* Set segemnt registers equal               *)
    mov  es, di       (* to each other (both address string)       *)
    sub  ds:[si], dl  (* New length = length - deleted chars       *)
    add  si, ax       (* Char at index                             *)
    inc  si           (* becomes destination                       *)
    mov  di, si       (* of move                                   *)
    add  si, dx       (* Char behind the last that will be deleted *)
    shr cx, 01        (* Convert # bytes to word                   *)
    jnc @Even         (* Odd number of bytes?                      *)
    movsb             (* Yes, then store one byte                  *)
  @Even:
    rep movsw         (* Even number of bytes, so store words      *)
  @End:
    mov  ds, bx       (* Restore ds                                *)

  END; (* Delete *)

PROCEDURE Del1 (VAR Str: string); assembler;
(* Deletes the first character from Str *)
  ASM
    mov  bx, ds        (* Save ds register *)
    lds  si, &Str      (* Load string  *)
    xor  ch, ch        (* Only want low byte *)
    mov  cl, ds:[si]   (* Load length (Str) *)
    jcxz @End          (* Length (Str) = 0 then exit *)
    dec  cl            (* Decrement length *)
    mov  ds:[si], cl   (* Load new length *)
    cld                (* Forward string-ops *)
    mov  di, ds        (* Set segment registers equal               *)
    mov  es, di        (* to each other (both address string)       *)
    inc  si            (* Point source to destination *)
    mov  di, si        (* Load destination *)
    inc  si            (* Skip length byte *)
    shr  cx, 1         (* Convert # of bytes to word *)
    jnc  @Even         (* Odd number of bytes? *)
    movsb              (* Yes, then store one byte *)
  @Even:
    rep  movsw         (* Even number of bytes, so store words *)
  @End:
    mov  ds, bx         (* Restore ds *)
  END; (* Del1 *)

(****************************************************************************)

PROCEDURE ChInsert (Ch: char; VAR Str: string; Index: integer); assembler;
(* Inserts Ch into Str and position Index.  Note that this is NOT a
   replacement for system.insert.  It just inserts a characters, not a
   string.                                                                *)
  ASM
    mov  bx, ds         (* Save ds                                        *)
    lds  si, &Str       (* Load source string                             *)
    xor  ah, ah         (* Zero out msb                                   *)
    mov  al, ds:[si]    (* al = length (Str)                              *)
    mov  cx, Index      (* cx = Index                                     *)
    jcxz @End           (* Exit if Index = 0                              *)
    cmp  cx, ax         (* Is Index > length (Str)?                       *)
    jle  @Okay          (* No, then continue                              *)
    mov  cx, ax         (* Yes, so                                        *)
    inc  cx             (* Index = Length (Str) + 1                       *)
  @Okay:
    cmp  al, 255        (* Is length (Str) = 255?                         *)
    jae  @End           (* Yes, then exit                                 *)
    inc  al             (* Increment length for insertion                 *)
    mov  ds:[si], al    (* Store new length                               *)
    mov  di, ds         (* Set segment registers equal                    *)
    mov  es, di         (* to each other (both address string)            *)
    add  si, ax         (* Set si = insertion position                    *)
    mov  di, si         (* Source = Destination                           *)
    inc  di             (* Moving string "up" one                         *)
    sub  ax, cx         (* Characters to move = length (Str) - Index      *)
    mov  cx, ax         (* Set counter register to # characters to move   *)
    inc  cx             (* Increment by one for extra insertion character *)
    std                 (* Backward string-ops                            *)
    rep  movsb          (* Move source bytes to destination bytes         *)
    mov  al, &Ch        (* Insertion character                            *)
    stosb               (* Insert character in "hole"                     *)
  @End:
    mov  ds, bx         (* Restore ds                                     *)
  END;

(****************************************************************************)

FUNCTION Copy (Str: string; Index, Count: word): string; assembler;
(* Same as the standard system.copy function except much faster.  Adapted
   from code by Norbert Juffa.                                            *)
  ASM
    push ds                (* Save ds               *)
    les  di, @Result       (* Load result address *)
    lds  si, Str           (* Load source address                        *)
    mov  ax, Count         (* Load Count *)
    mov  bx, Index         (* Load Index                                          *)
    cwd                    (* DX = FFFF if count negative, else DX=0*)
    not  dx                (* DX = FFFF if count positive, else DX=0  *)
    and  ax, dx            (* Max (count, 0)                            *)
    dec  bx                (* index - 1                                   *)
    cmp  bh, 80h           (* index-1 < 0 ?                                 *)
    sbb  dx, dx            (* DX = FFFF if index-1 pos., else DX = 0          *)
    and  bx, dx            (* Max (index-1, 0)                                  *)
    mov  cl, ds:[si]       (* source length                                       *)
    inc  si                (* pointer to 1st char of source                         *)
    xor  ch, ch            (* zero-extend source length to word                       *)
    sub  bx, cx            (* index - 1 - length                                        *)
    sbb  dx, dx            (* DX=0, if index-1 > length, else DX=FFFF                     *)
    and  bx, dx            (* - max # of chars that could be copied                         *)
    neg  bx                (* maxcount                                                        *)
    sub  ax, bx            (* count - maxcount*)
    sbb  dx, dx            (* DX=0, if count > maxcount, else DX=FFFF*)
    and  ax, dx            (* count - maxcount = 0, if count>maxcount  *)
    add  ax, bx            (* AX = Min (Count, MaxCount)                 *)
    sub  cx, bx            (* CX = Min (Index-1, Length)                   *)
    add  si, cx            (* pointer to first char to copy                  *)
    cld
    stosb                     (* store length of result                           *)
    mov  cx, ax            (* need it in CX for string instruction               *)
    shr  cx, 01             (* number of chars odd ?                                *)
    jnc  @Even             (* no, even                                               *)
    movsb                     (* move single char                                         *)
@Even:
    rep  movsw             (* copy chars two at a time                                   *)
    pop  ds                (* restore caller's data segment                                *)
 END;

PROCEDURE StrMov (VAR Dest: string; Str: string); assembler;
  ASM
    mov dx, ds
    lds si, &Str
    xor ah, ah
    mov al, ds:[si]
    mov cx, ax
    inc cx
    les di, &Dest
    cld
    shr cx, 1
    jnc @Even
    movsb
  @Even:
    rep movsw
    mov ds, dx
  END;

PROCEDURE StrCat (VAR Dest: string; Str: string; MaxLen: byte); assembler;
(* This is the correct one *)
  ASM
    push ds
    xor  ax, ax
    lds  si, &Str
    cld
    lodsb
    mov  cx, ax
    jcxz @End
    les  di, Dest
    mov  bx, di
    mov  al, es:[di]
    mov  dx, ax
    add  bx, ax
    mov  al, MaxLen
    sub  dx, ax
    jnl  @End
    add  dx, cx
    jnl  @1
    add  ax, dx
    jmp  @2
  @1:
    add  cx, dx
  @2:
    stosb
    mov  di, bx
    inc di
    shr cx, 1
    jnc @Even
    movsb
  @Even:
    rep movsw
  @End:
    pop  ds
  END;

FUNCTION GetEnv (Str: string): string; assembler;
  ASM
    push ds
    cld
    mov es, [PrefixSeg]
    mov es, es:[2Ch]
    xor di, di
    lds si, &Str
    lodsb
    or al, al
    jz @RetNul
    mov ah, al
    mov dx, si
    xor al, al
  @Compare:
    mov ch, al
    mov si, dx
    mov cl, ah
    mov si, dx
    repe cmpsb
    jne @Skip
    cmp byte ptr es:[di], '='
    jne @NoEqual
  @Found:
    mov ax, es
    mov ds, ax
    mov si, di
    inc si
    les bx, @Result
    mov di, bx
    inc di
    mov cl, 255
  @CopyLoop:
    lodsb
    or al, al
    jz @Done
    stosb
    loop @CopyLoop
  @Done:
    not cl
    mov es:[bx], cl
    jmp @End
  @Skip:
    dec di
  @NoEqual:
    mov cx, 7FFFh
    sub cx, di
    jbe @RetNul
    repne scasb
    jcxz @RetNul
    cmp byte ptr es:[di], al
    jne @Compare
  @RetNul:
    les di, @Result
    stosb
  @End:
    pop ds
  END;

(****************************************************************************)

FUNCTION NoCase (Ch: char): char; far; assembler;
(* This function does... nothing!  It merely returns Ch unchanged.  It's
   used for the BMSearch function and the ChCase function.                  *)
  ASM
    mov al, &Ch     (* Return Ch *)
  END;

(****************************************************************************)

FUNCTION UpCase (Ch: char): char; far; assembler;
(* Returns Ch as in uppercase letter if it as a lowercase letter; otherwise,
   Ch is returned unchanged.                                                *)
  ASM
    mov al, &Ch         (* al = Ch                           *)
    cmp al, 'a'         (* Skip if not 'a'..'z'              *)
    jb  @Done
    cmp al, 'z'
    ja  @Done
    sub al, 'a'-'A'     (* Convert Ch to an uppercase letter *)
  @Done:
  END;

(****************************************************************************)

FUNCTION UpCaseStr (Str: ComStr): ComStr; assembler;
(* Convert Str into uppercase letters and return it.  Code adapted from
   Turbo Pascal 6.0 Programmer's Guide by Borland, pages 305-306.     *)
  ASM
    mov   bx, ds            (* Save DS register        *)
    cld                     (* Forward string-ops      *)
    lds   si, Str           (* Load string address     *)
    les   di, @Result       (* Load result address     *)
    lodsb                   (* Load string length      *)
    stosb                   (* Copy to result          *)
    xor   ah, ah            (* String length to cx     *)
    mov   cx, ax
    jcxz  @3                (* Skip if empty string    *)
  @1:
    lodsb                   (* Load character          *)
    cmp   al, 'a'           (* Skip if not 'a'..'z'    *)
    jb    @2
    cmp   al, 'z'
    ja    @2
    sub   al, 20h           (* Convert to uppercase    *)
  @2:
    stosb                   (* Store in result         *)
    loop  @1                (* Loop for all characters *)
  @3:
    mov   ds, bx            (* Restore DS register     *)
  END; (* UpCaseStr *)

(****************************************************************************)

FUNCTION HexString (HexNumber: longint): NumStr; far; assembler;
(* Returns HexNumber as a string in hexadecimal preceded by a '$' and ending
   with a ': '.  Adapted from code by Helge Helgesen, Norway.               *)
  ASM
    cld                                 (* Forward string-ops *)
    les  di, @Result                    (* Load result address *)
    mov  ax, 240Bh                      (* Result length (11) and '$' *)
    stosw                               (* Store length and '$' *)
    lea  bx, Digits                     (* Load Digit table *)
    mov  dx, word ptr (HexNumber + 2)   (* Start with high word *)
    mov  cx, 02                         (* Process 2 words *)
  @1:
    mov  al, dh                         (* Convert current byte *)
    shr  al, 01                         (* Divide byte by 16 *)
    shr  al, 01
    shr  al, 01
    shr  al, 01
    xlat                                (* Look up hex character and *)
    stosb                               (* store it in destination *)
    mov  al, dh                         (* Get next byte *)
    and  al, 0Fh
    xlat
    stosb
    mov  al, dl
    shr  al, 01
    shr  al, 01
    shr  al, 01
    shr  al, 01
    xlat
    stosb
    mov  al, dl
    and  al, 0Fh
    xlat
    stosb
    mov  dx, word ptr HexNumber
    loop @1
    mov  ax, ' :'
    stosw
  END; (* HexString *)

(****************************************************************************)

PROCEDURE BMTFill (VAR Buffer; Ch: byte); assembler;
(* Same as the standard procedure system.@fillchar except a @tad faster since
    this isn't a far procedure.                                             *)
  ASM
    les di, Buffer       (* Load Buffer           *)
    mov cx, 128          (* Load Count            *)
    mov al, &Ch          (* Load Ch as word       *)
    mov ah, al
    cld                  (* Forward string-ops    *)
    rep stosw            (* Store words in Buffer *)
  END;

(****************************************************************************)

FUNCTION ABDrive: boolean; assembler;
(* Returns TRUE if system has one drive acting as A and B. This requires
   DOS 3.2+.                                                             *)
  ASM
    mov  ax, 440Eh        (* IOCTL function (44h) and subfunction 0Eh    *)
    mov  bl, 01h          (* Checking drive A                            *)
    int  21h              (* Execute DOS function                        *)
    jc   @Error           (* If Carry Flag is set then there's trouble   *)
    cmp  al, 00h          (* See if A/B are one drive                    *)
    jne  @Okay            (* Yes they are, so jump                       *)
  @Error:
    xor  al, al           (* No they are not, or there was an error      *)
    jmp  @Done
  @Okay:
    mov  al, 01h          (* Set function result to TRUE                 *)
  @Done:
  END;

(****************************************************************************)

PROCEDURE ForceDrive (Drive: byte); assembler;
(* Force drive B: to be assumed as A:.  This requires DOS 3.2+.         *)
  ASM
    mov  ax, 440Fh  (* IOCTL function (44h) and set logical drive (0Fh) *)
    mov  bl, Drive  (* Drive A: = 1, B: = 2                             *)
    int  21h
    mov  DriveBForced, TRUE
  END;

(****************************************************************************)

FUNCTION NumDrives: byte; assembler;
(* Returns the last drive on the system.  DOS function 0Eh is used,
   which returns the "number of potentially valid drive letters", as
   stated in Ralf Brown's interrupt list.                           *)
  ASM
    mov ah, 19h        (* Get default drive function                *)
    int 21h
    mov ah, 0Eh        (* Set default drive function                *)
    mov dl, al         (* Set default drive to default drive        *)
    int 21h
    cmp al, 26         (* # of drives > 26 ?                        *)
    jg  @Invalid       (* Yes, then it's invalid                    *)
    cmp al, 01         (* Drive < 1 ?                               *)
    jge @Okay          (* No, then it's okay                        *)
  @Invalid:
    mov al, 26         (* Set LastDrive to 'Z'                      *)
  @Okay:
  END;

(****************************************************************************)

FUNCTION DOSVersion: word; assembler;
(* Returns the DOS version number in register AX. The major version number
   is in AL and the minor version number is in AH.  Sure I could have
   used the function from the DOS unit, but this reduces code.          *)
  ASM
    mov ah, 30h
    int 21h
  END;

(****************************************************************************)
(* End of assembler routines *)
(* ========================= *)
(****************************************************************************)


PROCEDURE NewCtrlBreakkVector; interrupt;
(* <Ctrl-Break> interrupt handler, so that pressing <Ctrl-Break> doesn't
   rudely halt execution.                            *)
  BEGIN
    inline ($FA);       (* cli - disable interrupts  *)

    (* Clear Ctrl-Break flag *)
    mem[$0040:$0071] := (mem[$0040:$0071] AND $0E);

    CtrlBreak := TRUE;  (* <Ctrl-Break> was pressed  *)

    inline ($FB)        (* sti - enable interrupts   *)
  END;

(****************************************************************************)

FUNCTION Num2Str (Num: integer): NumStr;
(* Converts Num to a string type                                            *)
  BEGIN
    system.str (Num:1, TmpStr);
    Num2Str := TmpStr
  END;

(****************************************************************************)

FUNCTION Comma (VAR Num: longint; Width: byte): NumStr;
(* Converts Num to a string type adding a thousands separator               *)
  BEGIN
    system.str (Num:Width, TmpStr);
    Int := (length (TmpStr) - 2);
    PC := 0;
    WHILE (Int > 1) AND (TmpStr[Int-1] <> ' ') DO
      BEGIN
        ChInsert (',', TmpStr, Int);
        dec (Int, 3);
        inc (PC)
      END;
    FOR Int := 1 TO PC DO
      IF (TmpStr[1] = ' ') THEN
        Del1 (TmpStr);
    Comma := TmpStr
  END;

(****************************************************************************)

FUNCTION Decimal (Number: longint): NumStr; far;
  BEGIN
    system.str (Number:10, TmpStr);
    PC := 1;
    WHILE (TmpStr[PC] = ' ') DO
      BEGIN
        TmpStr[PC] := '0';
        inc (PC)
      END;
    Decimal := TmpStr + ': '
  END;

(****************************************************************************)

PROCEDURE HaltProgram (ErrorCode: byte);
(* Halts program execution, displaying total files found.                   *)
  BEGIN
    IF NotInHelp THEN
      BEGIN
        IF EscPressed THEN
          Writeln ('Execution halted -- <Esc> key pressed')
        ELSE IF CtrlBreak THEN
          Writeln ('Execution halted -- <Ctrl-Break> pressed');

        IF ShowInfo AND (FilesFound > 0) THEN
          BEGIN
            Writeln ('--------------------------------------------------------------------');
            Writeln ('Total sizes: ' + Comma (SumSizes, 1) + ' bytes')
          END
        ELSE
          Writeln ('----------------------------------------');

        Writeln ('Total found: ' + Comma (FilesFound, 1));

        IF DriveBForced THEN
          ForceDrive (1)

      END;

    setintvec (CtrlBreakInt, OldBreakVector);

    halt (ErrorCode)
  END;

(****************************************************************************)

PROCEDURE NormWrite (Str: string); far;
(* This procedure reduces the size of compiled code and can even (in some
   cases) reduce execution time of program.  Really!                       *)
  BEGIN
    system.writeln (Str)
  END;

(****************************************************************************)

PROCEDURE PauseWrite (Str: string); far;
(* The current row on the screen being displayed is kept track off so
   before the screen scrolls up, the user is prompted to continue.       *)
  BEGIN
    inc (CurrRow);               (* increment # of rows displayed so far *)

    NormWrite (Str);             (* output string                        *)

    IF (CurrRow = NumRows) THEN  (* time to prompt user?                 *)
      BEGIN
	write ('Press any key to continue...'#13);
	Ch := ReadKey;
	clreol;
	IF (Ch = Esc) OR (CtrlBreak) THEN
          BEGIN
            EscPressed := (Ch = Esc);
            HaltProgram (0)
          END;
	CurrRow := 0
      END
  END; (* Wrtln *)

(****************************************************************************)

PROCEDURE DisplayOptions;
(* Display program options. *)
  BEGIN

    Writeln   := PauseWrite;
    NumRows   := hi (CRT.windmax);

    (* Need the following statement because if PauseWrite detects that
       <Esc> was pressed, then HaltProgram is called which displays
       the total # of files found, which obviously is zero since help is
       being displayed.  Thus, the statement below is for the benefit of
       the procedure HaltProgram.  Phew.                                   *)

    NotinHelp := FALSE;

    Writeln ('Syntax:  SEEK  [options]  ["search string"]  [drives:]  files...');
    Writeln ('');
    Writeln ('Options:  /B  -------------- Begin seeking in current directory');
    Writeln ('          /C  -------------- Change to directory of found file');
    Writeln ('          /D  -------------- scan all Drives for files');
    Writeln ('          /F  -------------- seek only Files; ignore directories');
    Writeln ('          /I  -------------- show file Info: size, attribute(s), & date');
    Writeln ('          /L  -------------- ignore Letter-case during string search');
    Writeln ('          /O  -------------- display Offset where search string is found');
    Writeln ('                             in hexadecimal');
    Writeln ('          /P  -------------- Pause after screenful of information');
    Writeln ('          /Q  -------------- Quit seeking when first file is found');
    Writeln ('          /R  -------------- Run files if found (must have COM, EXE,');
    Writeln ('                             or BAT extension)');
    Writeln ('          /T  -------------- display offset where search string is found');
    Writeln ('                             in decimal');
    Writeln ('          /V  -------------- use DOS routines for Video output (slower)');
    Writeln ('          /A(AHRSD)  ------- seek files by specified Attribute(s)');
    Writeln ('          /Ecommand  ------- Execute specified command on files');
    Writeln ('          /S[-]size[-]  ---- seek files by Size specified or by range');
    Writeln ('          /?, /H  ---------- for more information and syntax examples')
  END;

(****************************************************************************)

PROCEDURE DisplayHelp;
(* Display detailed help information *)
  BEGIN
    DisplayOptions;
    Writeln ('');
    Writeln ('');
    Writeln ('- SEEK searches for all the files specified on the command-line and');
    Writeln ('  displays their full path name if found.');
    Writeln ('');
    Writeln ('- To search for any string within seeked files, specify the string be-');
    Writeln ('  tween two (2) quotes (").  If your string contains a quote symbol, use');
    Writeln ('  2 quotes to represent 1 quote within the quoted string.  The search');
    Writeln ('  string can appear anywhere on the command-line.');
    Writeln ('');
    Writeln ('- You can search across different drives.  Just specify the drives you');
    Writeln ('  want to search followed by a colon.  The /D option (scan all drives)');
    Writeln ('  is disabled if any drives are specified.');
    Writeln ('');
    Writeln ('- If you don''t want SEEK to scan entire disks, specify the path from');
    Writeln ('  which to start searching.  Note that only the last file specification');
    Writeln ('  with a full path name will be considered.  Previous paths are ignored.');
    Writeln ('');
    Writeln ('- Pressing <Esc> or <Ctrl-Break> at any time halts execution.');
    Writeln ('');
    Writeln ('- Options can be combined and can appear in any order on the command-');
    Writeln ('  line.  If an option is specified more than once, the right-most one');
    Writeln ('  takes precedence.');
    Writeln ('');
    Writeln ('Explanation of options (examples follow)');
    Writeln ('======================');
    Writeln ('  /B  ---------- begin searching in the current directory.  By default,');
    Writeln ('                 SEEK begins from the root directory.');
    Writeln ('  /C  ---------- change to the directory of the first matching file.');
    Writeln ('                 Execution is also halted with this option.');
    Writeln ('  /D  ---------- scan all drives for files.  This option is overridden');
    Writeln ('                 if any drives are specified.');
    Writeln ('  /F  ---------- seek only files.  Directory entries are ignored.  To');
    Writeln ('                 seek only directories, specify the /AD option.');
    Writeln ('  /I  ---------- display information of found files: size, date, time,');
    Writeln ('                 and file attributes.');
    Writeln ('  /L  ---------- ignore letter-case during string search.');
    Writeln ('  /O  ---------- display the offset where a found string was found');
    Writeln ('                 within file.  The offset is displayed in hexadecimal.');
    Writeln ('  /P  ---------- pause after each screenful of information.');
    Writeln ('  /Q  ---------- quit seeking when the first matching file is found.');
    Writeln ('  /R  ---------- run the files if they are found (they of course must');
    Writeln ('                 have a COM, EXE, or BAT extension).');
    Writeln ('  /T  ---------- as with option /O, except the offset is displayed in');
    Writeln ('                 decimal.');
    Writeln ('  /V  ---------- use DOS routines for output. This is slower but it');
    Writeln ('                 allows any output to be redirected, if desired.');
    Writeln ('  /A(AHRSD) ---- seek files by specified attributes. Attributes can be');
    Writeln ('                 combined in any order as long as the first attribute is');
    Writeln ('                 preceded by /A. The attributes are: A = Archive, H =');
    Writeln ('                 Hidden, R = Read-only, S = System, and D = Directory.');
    Writeln ('                 When combined, an OR comparison is performed on the');
    Writeln ('                 files.  For example, if the option /AHD was specified,');
    Writeln ('                 any files with a Hidden OR a Directory attribute are');
    Writeln ('                 sought for.');
    Writeln ('  /Ecommand ---- the command specified after this option will be ex-');
    Writeln ('                 ecuted on found files. The command specified can be any');
    Writeln ('                 DOS command or executable program (which must be in');
    Writeln ('                 your PATH).');
    Writeln ('  /S[-]size[-] - seek files by specified size. There are four seek');
    Writeln ('                 possibilities:');
    Writeln ('                  1) /Ssize  ====== find file sizes equal to specified');
    Writeln ('                                    size.');
    Writeln ('                  2) /S-size ====== find file sizes less than or equal');
    Writeln ('                                    to specified size.');
    Writeln ('                  3) /Ssize- ====== find file sizes greater than or');
    Writeln ('                                    equal to specified size.');
    Writeln ('                  4) /Ssize-size1 = find file sizes between the range');
    Writeln ('                                    specified by size and size1.');
    Writeln ('Examples');
    Writeln ('========');
    Writeln ('1) SEEK  a:*.bak  /vi  c:  /d');
    Writeln ('   - searches for all *.BAK files on drives A and C, displaying all');
    Writeln ('     file details and using DOS output routines.  Note that the /d');
    Writeln ('     option (scan all drives) is ignored since drives were specified.');
    Writeln ('');
    Writeln ('2) SEEK  /deTYPE  *.tmp  *.$$$  /eDEL');
    Writeln ('   - searches all drives for *.TMP and *.$$$ files, executing the DEL');
    Writeln ('     command on any files found.  Note that the command TYPE is not');
    Writeln ('     executed since /eDEL appears after it.');
    Writeln ('');
    Writeln ('3) SEEK  /pt  *.*  /id  "A ""quote"""  /o');
    Writeln ('   - scans all drives for *.* files which contain the string ''A "quote"''');
    Writeln ('     displaying file information and the offset in hexadecimal where');
    Writeln ('     the string was found, pausing with each screenful.  Note that the');
    Writeln ('     /t option (show offset in decimal) is overridden since /o appears');
    Writeln ('     to the right of it.');
    Writeln ('');
    Writeln ('4) SEEK  /ad  /arh  *.*  /s0-100  /b');
    Writeln ('   - searches current drive starting in the current directory for *.*');
    Writeln ('     files that have either a directory, read-only or hidden attribute,');
    Writeln ('     and that are between 0 and 100 bytes, inclusive.');
    Writeln ('');
    Writeln ('5) SEEK  a:  /q  cf:\help.exe  /ri  d:*.zip');
    Writeln ('   - searches drives A, C, D, and F for the files HELP.EXE and *.ZIP,');
    Writeln ('     displaying file information, running HELP.EXE if found, and');
    Writeln ('     quiting as soon as one file is found.');
    Writeln ('');
    Writeln ('');
    Writeln (' Copyright Information');
    Writeln (' =====================');
    Writeln ('- This software may be freely distributed without cost, provided it is');
    Writeln ('  not changed in any way.  If you find this program useful, donations');
    Writeln ('  to the address listed below would be most appreciated.');
    Writeln ('');
    Writeln ('- I take no responsibility for any liability, loss, or damage caused or');
    Writeln ('  alleged to be caused directly or indirectly from the use of this');
    Writeln ('  program.');
    Writeln ('');
    Writeln ('- SEEK was written in Turbo Pascal 6.0.');
    Writeln ('');
    Writeln ('- If you discover any bugs, or have any ideas or suggestions, please');
    Writeln ('  feel free to contact me:');
    Writeln ('     Jody R. Cairns');
    Writeln ('     jcairns@gmail.com');
    HaltProgram (0)
  END;

(****************************************************************************)

PROCEDURE CheckError (ErrorCode: word);
(* Displays the error associated with ErrorCode. ErrorCodes between 21 and 50
   are command-line errors.                                                 *)
  BEGIN
    CASE ErrorCode OF
       00: exit;
       03: StrMov (Error, 'Path not found.');
       15: StrMov (Error, Drive.Letter[J] + ' is an invalid drive letter.');
       21: Error := 'Invalid command-line option: "' + Param[J] + '"';
       22: Error := 'Invalid file attribute for /A option: "' + TmpStr[Tmp] + '"';
       23: Error := 'File size must be >= 0 and <= 2,147,483,647.';
       24: Error := 'Missing command for /E option.';
       25: Error := 'No option(s) specified after "/" switch.';
       26: Error := 'Missing file attribute(s) for /A option.';
       27: Error := 'Missing file size for /S option.';
       28: Error := 'Search string must be between two (2) quotes.';
       29: Error := 'No search string specified.';
       51: Error := 'No file(s) specified.';
       52: Error := 'Maximum # of files is ' + Num2Str (MaxFiles) + '.';
       53: Error := 'Invalid DOS version. Requires DOS 3.2 or greater.';
       54: Error := 'Could not to change to directory ' + TmpStr;
       55: Error := 'COMSPEC environment variable is not set.';
      152: StrMov (Error, 'Drive ' + Drive.Letter[J] + ': not ready.');
      153: StrMov (Error, 'Invalid directory path.');
      154: StrMov (Error, 'CRC error in disk data.');
      155: StrMov (Error, 'Bad disk request structure length.');
      156: StrMov (Error, 'Disk seek error.');
      157: StrMov (Error, 'Drive ' + Drive.Letter[J] + ': has a non-DOS disk.');
      158: StrMov (Error, 'Disk sector not found.');
      161: StrMov (Error, 'Device read fault.');
      162: StrMov (Error, 'Hardware failure.')
      ELSE
	Error := 'Please report to author error #' + Num2Str (ErrorCode) + '.'
    END;

    IF (ErrorCode >= 153) THEN
      StrCat (Error, ' Disk in drive ' + Drive.Letter[J] + ': could be corrupt.', sizeof (Error) - 1);

    Writeln ('ERROR: ' + Error);

    IF (ErrorCode >= 21) AND (ErrorCode <= 100) THEN
      BEGIN
        IF (ErrorCode <= 50) THEN
          DisplayOptions;
        NotInHelp := FALSE;
	HaltProgram (ErrorCode)
      END
  END;

(****************************************************************************)

(* The following 4 functions are for the /S option: find file by size.      *)

FUNCTION Equal (FileSize: longint): boolean; far;
(* Returns TRUE if the current file size (FileSize) is equal to the
   specified file size.                                                     *)
  BEGIN
    Equal := (FileSize = MinSize)
  END;

FUNCTION GreaterThan (FileSize: longint): boolean; far;
(* Returns TRUE if the current file size (FileSize) is greater than or
   equal to the specified file size.                                        *)
  BEGIN
    GreaterThan := (FileSize >= MinSize)
  END;

FUNCTION LessThan (FileSize: longint): boolean; far;
(* Returns TRUE if the current file size (FileSize) is less than or
   equal to the specified file size.                                        *)
  BEGIN
    LessThan := (FileSize <= MinSize)
  END;

FUNCTION Between (FileSize: longint): boolean; far;
(* Returns TRUE if the current file size (FileSize) is greater than or
   equal to the minimum file specification OR less than or equal to the
   specified file size.                                                     *)
  BEGIN
    Between := (FileSize >= MinSize) AND (FileSize <= MaxSize)
  END;

(****************************************************************************)

FUNCTION Date (Num : word) : NumStr;
(* Returns N as a string with leading zeros. *)
  BEGIN
    system.str (Num:0, TmpStr);
    IF (length (TmpStr) = 1) THEN
      ChInsert ('0', TmpStr, 1);
    Date := TmpStr;
  END;


(****************************************************************************)

PROCEDURE GetKeyPressed;
(* Processes the key pressed by user, halting program if necessary.         *)
  BEGIN
    Ch := ReadKey;
    IF (Ch = Esc) OR (CtrlBreak) THEN
      BEGIN
        EscPressed := (Ch = Esc);
        HaltProgram (0)
      END;
  END; (* GetKeyPressed *)

(****************************************************************************)

PROCEDURE MakeBMTable;
(* Initializes table for Boyer-Moore-Horspool string search algorithm.      *)
  BEGIN
    BMTFill (BMT, length (StrToFind));
    FOR K := 1 TO (length (StrToFind) - 1) DO
      BMT[ord(StrToFind[K])] := (length (StrToFind) - K)
  END;

(****************************************************************************)

FUNCTION BMSearch: longint;
(* Performs the Boyer-Moore-Horspool string searching algorithm, returning
   the offset in file where the string was found.  If not found, then
   -1 is returned.  Adapted from the 'Handbbok of Algorithms and Data
   Structures in Pacsal and C', Second Edition, by G.H Gonnet and
   R. Baeza-Yates.                                                          *)
  BEGIN
    BMSearch := -1;
    K := length (StrToFind);
    WHILE (K <= BytesRead) DO
      BEGIN
        Tmp := K;
        Int := length (StrToFind);
        WHILE (Int >= 1) DO
          IF (ChCase(Buffer[Tmp]) <> StrToFind[Int]) THEN
            Int := -1
          ELSE
            BEGIN
              dec (Int);
              dec (Tmp)
            END;
        IF (Int = 0) THEN
          BEGIN
            BMSearch := (filepos (FoundFile) - (BytesRead - Tmp));
            exit
          END;
        inc (K, BMT[ord(ChCase(Buffer[K]))])
      END (* WHILE *)
  END; (* BMSearch *)

(****************************************************************************)

PROCEDURE DisplayError (VAR FileName: PathStr);
  BEGIN
    CheckError (Tmp);
    Writeln ('       String scanning aborted in ' + FileName + '.');
    StringOffset := -1
  END;

(****************************************************************************)

PROCEDURE SearchFile (FileName: PathStr);
(* Opens file to initiate Boyer-Moore-Horspool search algorithm, reading
   blocks of data from file until string is found or all bytes are read.    *)
  LABEL
    EndProc,
    CloseFile;
  BEGIN
    filemode := 0;                (* Set file mode to read access only      *)

    assign (FoundFile, FileName);
    reset  (FoundFile, 1);        (* Open file and check for errors         *)
    Tmp := IOResult;
    IF (Tmp <> 0) THEN
      BEGIN
        DisplayError (FileName);
        goto EndProc
      END;

    REPEAT
      IF KeyPressed THEN
        GetKeyPressed;

      blockread  (FoundFile, Buffer, sizeof (Buffer), BytesRead);
      Tmp := IOResult;
      IF (Tmp <> 0) THEN
        BEGIN
          DisplayError (FileName);
          goto CloseFile
       END;

      StringOffset := BMSearch;   (* Search current buffer                  *)

      IF (BytesRead = sizeof (Buffer)) AND (StringOffset = -1) THEN
        BEGIN
          system.seek (FoundFile, filepos (FoundFile) - length (StrToFind));
          Tmp := IOResult;
          IF (Tmp <> 0) THEN
            BEGIN
              DisplayError (FileName);
              goto CloseFile
            END
        END

    UNTIL (BytesRead = 0) OR (StringOffset <> -1);

  CloseFile:
    close (FoundFile);
    CheckError (IOResult);
  EndProc:
  END; (* SearchFile *)

(****************************************************************************)

PROCEDURE SeekFile (Path: PathStr);
(* This is the main search procedure.  Path determines which directory to
   start searching in.  This is a recursive procedure.                      *)

  LABEL
    Next, Found1, Found2;   (* goto labels                                  *)

  VAR
    DirNotShown: boolean;   (* determines if directory was displayed or not *)
    F          : SearchRec; (* used for findfirst and findnext procedures   *)

  BEGIN

    (* Check if <Esc> key or <Ctrl-Break> was pressed *)
    IF KeyPressed THEN
      GetKeyPressed;

    (* The following statement is a safeguard. The maximum length of a
       directory is compared to length of Path.  If Path is longer then
       the disk directory structure is probably corrupt in some way.        *)

    IF (length (Path) > MaxDirLength) THEN
      CheckError (153);

    DirNotShown := TRUE;

    FOR I := 1 TO SeekNumber DO
      BEGIN
        StrMov (Param, Seek[I]);

        (* Find first file *)
        findfirst (Path + Param, (AnyFile-VolumeID), F);

        WHILE (DOSError = 0) DO  (* If found then continue...             *)
          BEGIN
            IF (F.Name[1] = '.') OR (SeekFileOnly AND
               ((F.Attr AND (Directory + VolumeID)) <> 0)) THEN
              goto Next;

            (* Seek file by size? *)
    	    IF (SeekSize) THEN
	      IF ValidFileSize (F.Size) AND
                 ((F.Attr AND (Directory + VolumeID)) = 0) THEN
	        goto Found1
	      ELSE
	        goto Next;

	    Found1:

            (* Seek file by attribute? *)
	    IF (SeekAttr) THEN
	      IF ((F.Attr AND FileAttr) <> 0) THEN
	        goto Found2
	      ELSE
	        goto Next;

	    Found2:

            (* Find string in file? *)
            IF (FindString) THEN
              IF ((F.Attr AND (Directory + VolumeID)) <> 0) THEN
                goto Next
              ELSE
                BEGIN
                  SearchFile (Path + F.Name);
                  IF (StringOffset = -1) THEN
                    goto Next
                END;

            (* Show file information? *)
	    IF (ShowInfo) THEN
	      BEGIN
	        IF DirNotShown THEN
	          BEGIN
		    Writeln ('');
		    Writeln (Path);
		    DirNotShown := FALSE
	          END;

	        StrMov (Attr, '....');
	        IF ((F.Attr AND Archive)  <> 0) THEN
	          Attr[1] := 'A';
	        IF ((F.Attr AND ReadOnly) <> 0) THEN
	          Attr[2] := 'R';
	        IF ((F.Attr AND Hidden)   <> 0) THEN
	          Attr[3] := 'H';
	        IF ((F.Attr AND SysFile)  <> 0) THEN
	          Attr[4] := 'S';

                IF (FindString) AND (DisplayOffset) THEN
                  Writeln (Offset (StringOffset));

	        write (F.Name:20);
	        IF (F.Attr AND Directory <> 0) THEN
	          write ('<DIR>           ':23)
	        ELSE
	          write (Comma (F.Size,14), ' bytes   ');

	        unpacktime (F.Time, FileDate);
	        WITH FileDate DO
	          Writeln (Date (Day) + '-' + Date(Month) + '-' + Num2Str (Year) +
                           '  ' + Date(Hour) + ':' + Date(Min) +
                           '    ' + Attr);
                inc (DirSize, F.Size);
                inc (SumSizes, F.Size);
                inc (DirFiles)
	      END (* IF *)

            (* Display without information. *)

	    ELSE IF (FindString) AND (DisplayOffset) THEN
              Writeln (OffSet (StringOffset) + Path + F.Name)

            ELSE
  	      Writeln (Path + F.Name);

	    inc (FilesFound);

            (* Execute file? *)
   	    IF (RunFile) THEN
	      BEGIN
	        fsplit (F.Name, TmpStr, Name, Ext);
	        IF (Ext = '.COM') OR (Ext = '.EXE') OR (Ext = '.BAT') THEN
	          BEGIN
		    swapvectors;
		    exec (Comspec, '/C ' + Path + F.Name);
		    swapvectors
	          END
	      END;

            (* Execute command of file? *)
	    IF (ExecuteCommand) THEN
	      BEGIN
	        swapvectors;
	        exec (Comspec, '/C ' + Command + ' ' + Path + F.Name);
	        swapvectors
	      END;

            IF QuitWhenFound THEN
              BEGIN
                IF ChangeDir THEN
                  BEGIN
                    IF (length (Path) <> 3) THEN
                      StrMov (TmpStr, Copy (Path, 1, (length (Path) - 1)))
                    ELSE
                      StrMov (TmpStr, Path);
                    chdir (TmpStr);
                    IF (IOResult <> 0) THEN
                      BEGIN
                        chdir (CurrDir);
                        CheckError (54)
                      END
                  END;
                HaltProgram (0)
              END;
      Next:
	    findnext (F)
          END (* WHILE *)

      END; (* FOR *)

    IF (DirFiles > 0) THEN
      BEGIN
        IF (DirFiles = 1) THEN
          write (Comma (DirFiles, 14), ' entry,')
        ELSE
          write (Comma (DirFiles, 12), ' entries,');

        IF (DirSize <> 0) AND (FileAttr <> Directory) THEN
          Writeln (Comma (DirSize, 13) + ' bytes')
        ELSE
          Writeln ('');

        DirFiles := 0;
        DirSize  := 0
      END;

    (* Continue with search... *)
    findfirst (Path + '*.*', (AnyFile-VolumeID), F);
    WHILE (DOSError = 0) DO
      BEGIN
	IF ((F.Attr AND Directory) <> 0) AND (F.Name[1] <> '.') THEN
	  SeekFile (Path + F.Name + '\');
	findnext (F)
      END
  END; (* SeekFile *)

(****************************************************************************)

PROCEDURE GetSearchString;
(* Parses command-line for string specified between 2 quotes (").  This
   string is the string to find within any seeked files.                    *)
  VAR
    Okay: boolean;
    QuotePos: byte;
  BEGIN
    Okay := TRUE;
    StrToFind := '';

    Del1 (Param);

    WHILE (I <= PC) AND (Okay) DO
      BEGIN
        QuotePos := ChPos ('"', Param);
        IF (QuotePos <> 0) THEN
          BEGIN
            IF (QuotePos < length (Param)) AND (Param[QuotePos+1] = '"') THEN
              BEGIN
                StrCat (StrToFind, Copy (Param, 1, QuotePos), sizeof (StrToFind)-1);
                Delete (Param, 1, QuotePos+1)
              END
            ELSE
              BEGIN
                StrCat (StrToFind, Copy (Param, 1, QuotePos-1),sizeof (StrToFind)-1);
                Okay := FALSE
              END
          END
        ELSE
          BEGIN
            inc (I);
            StrCat (StrToFind, Param + ' ', sizeof (StrToFind)-1);
            StrMov (Param, paramstr (I))
          END;
      END;

    IF (I > PC) THEN
      CheckError (28)

    ELSE IF (length (StrToFind) = 0) THEN
      CheckError (29)

    ELSE IF (IgnoreCase) THEN
      StrMov (StrToFind, UpCaseStr (StrToFind))

  END; (* GetSearchString *)


(****************************************************************************)
(****************************************************************************)


BEGIN (* main program *)

  getintvec (CtrlBreakInt, OldBreakVector);
  setintvec (CtrlBreakInt, @NewCtrlBreakkVector);

  Writeln := NormWrite;
  ChCase  := NoCase;

  Writeln (Title);

  (* Needs at least DOS 3.2 for ABDrive and ForceDrive procedures           *)

  ASM
    mov  ah, 30h        (* Check DOS version        *)
    int  21h
    cmp  al, 03h        (* Major version >= 3?      *)
    ja   @Okay          (* Yes, then okay           *)
    cmp  ah, 14h        (* Minor version >= 20?     *)
    jnb  @Okay          (* Yes, then okay           *)
    mov  ax, 53         (* Nope, so CheckError (53) *)
    push ax
    call CheckError
  @Okay:
  END;

  PC := paramcount;   (* Since the parameter count is accessed a lot,
                         this reduces code.                                 *)

  IF (PC = 0) THEN    (* Why not put a halt(0) after this instead of adding *)
    DisplayOptions    (* the ELSE?  This method reduces code.               *)

  ELSE
    BEGIN
      (* Get the current directory. *)
      getdir (0, CurrDir);

      FOR I := 1 TO PC DO    (* Scan command-line for options *)
	BEGIN
	  StrMov (Param, paramstr (I));
	  IF (Param[1] = '/') THEN
	    BEGIN
	      IF (length (Param) = 1) THEN
		CheckError (25);

	      FOR J := 2 TO length (Param) DO
		CASE (Upcase (Param[J])) OF
		  'R': BEGIN
                         RunFile  := TRUE;   (* Run file                 *)
                         StrMov (Comspec, GetEnv ('COMSPEC'));
                         IF (Comspec = '') THEN
                           CheckError (55)
                       END;
		  'I': ShowInfo := TRUE;   (* Show file info           *)
                  'O': BEGIN
                         DisplayOffset := TRUE;
                         Offset := HexString
                       END;
                  'T': BEGIN
                         DisplayOffset := TRUE;
                         Offset := Decimal
                       END;
                  'F': SeekFileOnly  := TRUE;
                  'Q': QuitWhenFound := TRUE;
                  'B': BEGIN
                         StrMov (Dir, Copy (CurrDir, 3, length (CurrDir)) + '\');
                         BeginCurDir   := TRUE
                       END;
                  'C': BEGIN
                         ChangeDir := TRUE;
                         QuitWhenFound := TRUE
                       END;
                  'L': BEGIN
                         IgnoreCase  := TRUE;
                         ChCase := UpCase;
                         IF (length (StrToFind) <> 0) THEN
                           BEGIN
                             StrMov (StrToFind, UpCaseStr (StrToFind));
                             MakeBMTable
                           END
                       END;
		  'V': BEGIN               (* Use standard output and input *)
			 assign  (output, '');
			 assign  (input , '');
			 rewrite (output);
			 reset   (input)
		       END;
		  'E': BEGIN               (* Execute a command on file     *)
			 StrMov (Command, UpCaseStr (copy (Param, J+1, length (Param))));
			 ExecuteCommand := TRUE;
			 IF (length (Command) = 0) THEN
			   CheckError (24);
                         StrMov (Comspec, GetEnv ('COMSPEC'));
                         IF (Comspec = '') THEN
                           CheckError (55);
                         goto NextParam
		       END;
		  'P': BEGIN               (* Pause with each screenfull    *)
			 Writeln := PauseWrite;
			 NumRows := hi (CRT.windmax)
		       END;
		  'D': IF (Drive.Number = 0) THEN
                         BEGIN
			   Drive.Number := NumDrives;
			   AllDrives    := TRUE;
                           IF ABDrive THEN
                             BEGIN           (* Force drive A to be B       *)
                               ForceDrive (2);
                               Drive.Letter[2] := 'B';
                               StartDrive := 2
                             END;
		         END;
		  'S': BEGIN               (* Search by file size           *)
			 StrMov (TmpStr, copy (Param, J+1, length (Param)));
			 SeekSize := TRUE;
			 IF (Length (TmpStr) = 0) THEN
			   CheckError (27);
			 IF (TmpStr[1] = '-') THEN
			   BEGIN
			     Del1 (TmpStr);
			     ValidFileSize := LessThan
			   END
			 ELSE IF (TmpStr[length(TmpStr)] = '-') THEN
			   BEGIN
                             dec (TmpStr[0]);
			     ValidFileSize := GreaterThan
			   END
			 ELSE
			   ValidFileSize := Equal;
			 val (TmpStr, MinSize, Tmp);
			 IF (Tmp <> 0) THEN
			   BEGIN
			     ColonPos := ChPos ('-', TmpStr);
			     val ((Copy (TmpStr, 1, ColonPos - 1)), MinSize, Tmp);
			     IF (Tmp <> 0) THEN
			       CheckError (23);
			     val ((Copy (TmpStr, ColonPos + 1, length (TmpStr))), MaxSize, Tmp);
			     IF (Tmp <> 0) THEN
			       CheckError (23);
			     IF (MinSize > MaxSize) THEN
			       BEGIN
				 TmpLong := MinSize;
				 MinSize := MaxSize;
				 MaxSize := TmpLong
			       END;
			     ValidFileSize := Between
			   END;
			 IF (MinSize < MinFileSize) THEN
			   CheckError (23);
                         goto NextParam
		       END;
		  'A': BEGIN               (* Search file by attribute      *)
			 StrMov (TmpStr, Copy (Param, (J+1), length(Param)));
			 SeekAttr := TRUE;
			 IF (length (TmpStr) = 0) THEN
			   CheckError (26);
			 FOR Tmp := 1 TO length (TmpStr) DO
			   CASE Upcase (TmpStr[Tmp]) OF
			     'A': IF (FileAttr <= (AnyFile - Archive))   THEN
                                    inc (FileAttr, Archive);
			     'R': IF (FileAttr <= (AnyFile - ReadOnly))  THEN
                                    inc (FileAttr, ReadOnly);
			     'S': IF (FileAttr <= (AnyFile - SysFile))   THEN
                                    inc (FileAttr, SysFile);
			     'H': IF (FileAttr <= (AnyFile - Hidden))    THEN
                                    inc (FileAttr, Hidden);
			     'D': IF (FileAttr <= (AnyFile - Directory)) THEN
                                    inc (FileAttr, Directory);
			     ELSE
			       CheckError (22)
			   END; (* CASE *)
                         goto NextParam
		       END;
		  '?',
		  'H': DisplayHelp;
		  ELSE
		    CheckError (21)
	        END (* CASE *)
	    END (* IF *)

          ELSE IF (Param[1] = '"') THEN
            BEGIN
              GetSearchString;
              MakeBMTable;
              FindString := TRUE
            END

          ELSE
            BEGIN
              StrMov (Param, UpCaseStr (Param));
              IF (ChPos (':', Param) <> 0) THEN
                BEGIN
                  IF (AllDrives) THEN
                    BEGIN
                      Drive.Number := 0;
                      StartDrive   := 1;
                      AllDrives := FALSE
                    END;

                  ColonPos := ChPos (':', Param);

		  FOR K := 1 TO (ColonPos-1) DO
                    WITH Drive DO
                      IF (ChPos (Param[K], Drives) = 0) THEN
                        BEGIN
                          IF ABDrive THEN
                            IF (Param[K] = 'A') THEN
                              BEGIN
                                IF (ChPos ('B', Drives) <> 0) THEN
                                  goto NextDrive;
                                ForceDrive (1)
                              END
                            ELSE IF (Param[K] = 'B') THEN
                              BEGIN
                                IF (ChPos ('A', Drives) <> 0) THEN
                                  goto NextDrive;
                                ForceDrive (2)
                              END;

  		          inc (Number);
  		          Letter[Number] := Param[K];
                          Drives := Drives + Letter[Number];

	                  chdir (Letter[Number] + ':\');
	                  Tmp := IOResult;
	                  chdir (CurrDir);
	                  CheckError (IOResult);
	                  IF (Tmp <> 0) THEN
                            BEGIN
                              J := Number;
	                      CheckError (Tmp);
                              inc (DriveError);
                              dec (Number);
                              IF (Number = 0) AND (ColonPos <> length (Param))
                                              AND (K = (ColonPos - 1)) THEN
                                inc (NumFiles)
                            END;
                        NextDrive:
                        END; (* IF *)

                  IF (ColonPos = length (Param)) THEN (* No file specified.  *)
		    goto NextParam;

	          Delete (Param, 1, ColonPos)
                END;

              IF (SeekNumber = MaxFiles) THEN
                CheckError (52);

              FOR J := 1 TO SeekNumber DO
                IF (Seek[J] = Param) THEN
                  goto NextParam;

              IF (ChPos ('\', Param) <> 0) THEN
                BEGIN
                  fsplit (Param, TmpStr, Name, Ext);
                  IF (NOT BeginCurDir) THEN
                    StrMov (Dir, TmpStr);
                  Delete (Param, 1, length (TmpStr))
                END;

              inc (SeekNumber);
              StrMov (Seek[SeekNumber],  Param);

            END; (* ELSE *)
  NextParam:
	END; (* FOR *)

      IF (SeekNumber = 0) THEN   (* If no files specified, then error *)
	  CheckError (51);

      IF (DriveError <> 0) AND (Drive.Number = 0) THEN
        HaltProgram (0);

      WITH Drive DO
        IF (Number = 0) THEN
          BEGIN
  	    Letter[1] := CurrDir[1];
            inc (Number)
          END;

      write ('Seeking ');
      FOR I := 1 TO SeekNumber DO
        write (Seek[I], ' ');

      write ('on drive(s) ');

      WITH Drive DO
        IF (AllDrives) THEN
          write ('A to ', Letter[Number], ' ')
        ELSE
          FOR I := 1 To Number DO
            write (Letter[I], ' ');

      IF FindString THEN
        write ('for the string "', StrToFind, '" ');

      Writeln ('...');

      (* Start searching drive(s). *)
      FOR J := StartDrive TO Drive.Number DO
        SeekFile (Drive.Letter[J] + ':' + Dir)

    END; (* ELSE *)

  HaltProgram (0)

END. (* main program *)