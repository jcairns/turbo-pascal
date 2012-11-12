 PROGRAM Utter;

(* UTTER 2.03, Copyright (c) 2004, by Jody R. Cairns


   UTTER displays quotes that are stored in a separate ASCII data file, by
   default called UTTER.DAT, although a different file can be used if
   specified on the command-line. All quotes must end with a tilde (~).
   The quote file may be edited using the /E option. There are many more
   options (and more to come) including: display random quote, prompt
   user after quote is displayed, change video output, show number of
   quotes in quote file, etc.

   The source to this program (this file) is free to the public domain with
   the condition that I am notified of any modifications made to this
   program, and the executable of the MODIFIED program is NOT distributed
   without my permission (i.e. Don't pull a fast one like making a few
   changes to the source, compiling it, and saying you wrote it.).  Otherwise,
   the source and executable are free to those who want it.

   It would be very much appreciated if any code used from this program is
   credited to me (bearing in mind that I take absolutely no responsibility
   for the results or misuse of the execution or use of said code).

   Main Algorithm
   --------------
      1) Check if valid DOS version (must be >= 3.0).
      2) Get executable's filename and residing directory.
      3) Process command-line for options.
      4) Check if data file containing quotes exists.
      5) Check if index file for data file exists and is valid.
      6) Read index file to get old data file time-stamp.
      7) Compare old data file's time-stamp with current data file's time-stamp.
      8) Update index file if any discrepancies.
      9) Execute options if specified.
     10) Seek into proper location of data file for quote (determined
	 from location read from index file).
     11) Read and display quote.
     12) Update index file with next quote to be displayed location.
     13) Close files.

   See PROCEDURE DisplayHelp for more information about options available
   and the data file format.

   See PROCEDURE UpdateIndexFile for information on the format of the
   index file(s).

   NOTE: this program is not very modular due to the speed factor. I wanted
	 to make this as fast as possible without adding much assembly code
	 and still have sufficient error-checking.  Too many procedures
	 would have slowed it down (I timed it). So, please excuse this
	 programming oversight; it was done for speed. However, you will
	 notice I could have been LESS modular; code size was a factor, too.

   Version Changes (for those interested)
   ---------------
   UTTER 2.03- updated email address of author. (July 4, 2004)   
   
   UTTER 2.02- when output was re-directed and the /V option was used,
               the output was not correct.  This has been fixed.

   UTTER 2.01- fixed keyboard bug.  Previous versions only worked on
               enhanced keyboards.
             - string operations are much faster.

   UTTER 2.0 - all options may now be present in the UTTER environment
	       variable.  The syntax of the variable is exactly the same as
	       the command-line.  Thus, if the environment had
		 UTTER=quotes.dat /vr /w
	       It would be identical as executing UTTER on the command-line
	       like:
		 UTTER quotes.dat /vr /w
	       Any command-line options override any environment options if
	       they can be overridden. Thus, if /V was set in the environment,
	       and /D was specified on the command-line, /V would be ignored.
	       However, if /V was set in the environment and /R was specified
	       on the command-line, /V would NOT be ignored since neither
	       option is related to the other.
	     - the following options have been added:
		 /C  - Clears screen before quote is uttered. Thanks to Dawn
		       Torraville for the suggestion.
		 /T  - displays the value of the environment varaible UTTER.
		 /D  - utter quotes directly to video memory.  This is the
		       default output routine.  If options /V or /B were
		       specified in the environment variable, then /D
		       would take precedence.
                 /O  - displays UTTER's options.
		 /#  - utter # quotes, where # is greater than -1.  Thus, if
		       /10 was specifed, 10 quotes would be displayed.  If
		       # is greater than the number of quotes in the data file,
		       and the /R is not specified, then # is set to the number
		       of quotes in the data file.
                 /A  - if the data file is being updated and a no tilde (~)
                       is found at the end of the file, a tilde is appended
                       to the file.  Some editors add control characters at
                       the end of files, or you may forget to add a tilde to
                       the last quote.  This option adds it automatically.
                 /T  - as with the /A option, except the file is truncated
                       instead of a tilde being added.  The point of
                       truncation is the position where the last tilde was
                       found.  Thus, if your editor added some control
                       characters to the data file that you don't want, this
                       option will get rid of them.  Use this carefully,
                       making sure you are updating a quote data file, not
                       some other vital file, because the file is changed.
	     - due to how the environment variable is parsed, I changed how
	       the command-line was parsed.  Both are now parsed identically.
	     - replaced the following functions with my own (faster) versions:
		 - system.copy
		 - system.upcase
		 - system.delete
		 - DOS.dosversion
	     - quotes are now limited to a length of 2,048 Kb.

   UTTER 1.0 - original public-domain release.


   UTTER.PAS was written and compiled using TURBO PASCAL 6.0 and tested
   on a variety of Personal Computers, from 8086s to 80486s.

   If you find ANY bugs, or have any suggestions or ideas I'd be happy to
   hear from you.  Please don't hesitate to contact me for any information.
   I have more utilites in the works, all DOS-based. Here's my address:

   Jody R. Cairns

   e-mail: jcairns@gmail.com

									  *)

(* Compiler directives follow: *)

{$M 5120,0,0}    (* Memory requirements: 5 KB for stack, 0 KB for heap *)

{$I-}            (* I/O checking off                 *)
{$R-}            (* Range checking off               *)
{$S-}            (* Stack checking off               *)
{$X+}            (* Extended syntax on               *)
{$V-}            (* Strict VAR-string checking off   *)
{$B-}            (* Short-circuit boolean evaluation *)
{$D-}            (* Debug information off            *)
{$L-}            (* Local debug information off      *)
{$E-}            (* 8087 emulation off               *)
{$N-}            (* 8087/80287 code generation off   *)
{$G-}            (* 80286 code generation off        *)
{$F-}            (* Force far calls off              *)
{$A+}            (* Word align data                  *)
{$O-}            (* Overlays not allowed             *)


USES
  DOS, CRT;


LABEL
  EndLoop2;


CONST
  Title         = 'UTTER 2.03, Copyright (c) 2004, Jody R. Cairns';

  EndOfQuote    = '~';        (* End of quote indicator                  *)
  IndexExt      = '.IDX';     (* extension of index file                 *)
  Esc           = #27;        (* ASCII code for <ESC> key                *)
  BufferSize    = 1024 * 2;   (* Maximum size of buffer                  *)
  MaxWord       = 65535;      (* Largest possible word value             *)
  MaxSeconds    = 60;         (* Maximum # of seconds for /P option      *)


TYPE
  NumStr     = string[14];                    (* Longint type converted to string *)
  IDXFile    = file of longint;               (* Format of index file             *)
  BufferType = ARRAY[1..BufferSize] OF char;  (* Buffer used for reading quotes   *)


CONST
  UpdateFile   : boolean = FALSE;  (* Update index file                    *)
  AddTilde     : boolean = FALSE;
  TruncateFile : boolean = FALSE;
  ShowNumber   : boolean = FALSE;  (* Show number of quotes in quote file  *)
  GetRandom    : boolean = FALSE;  (* Get random quote from quote file     *)
  BiosVideo    : boolean = FALSE;
  DOSVideo     : boolean = FALSE;
  TitleNotShown: boolean = TRUE;   (* Program name has been displayed      *)
  InvokeEditor : boolean = FALSE;  (* Invoke editor to edit file of quotes *)
  DoPrompts    : boolean = TRUE;   (* Display warning prompts              *)
  KeyPause     : boolean = FALSE;  (* Pause with key prompt after quote    *)
  MousePause   : boolean = FALSE;  (* Pause with mouse prompt after quote  *)
  Pause        : boolean = FALSE;  (* Pause for some seconds after quote   *)
  Index        : boolean = FALSE;
  Editor       : PathStr = 'EDIT'; (* Default editor name                  *)
  CurrRow      : byte    = 0;      (* Current row number of screen         *)
  PauseMilSecs : word    = 2000;   (* # of milliseconds to pause for /P    *)
  NumQuotes    : longint = 1;
  Prompt       : ComStr  = #13#10'Press any key to continue...';


VAR
  DataFile  : file;       (* File containing quotes                          *)
  IndexFile : IDXFile;    (* Index file for DataFile                         *)
  Buffer    : BufferType; (* Buffer used for reading in quotes               *)
  Dir       : DirStr;     (* Directory that contains UTTER.EXE               *)
  Name      : NameStr;    (* Name of executing program                       *)
  Ext       : ExtStr;     (* Extension of file that contains quotes          *)
  EditorPath,             (* Full path name of editor                        *)
  DataPath  : PathStr;    (* Full PATH location of file containing quotes *)
  Error,
  TmpStr,
  CmdLine: string;
  LongIntVar,             (* Used for the /P option in val procedure         *)
  DataTime,               (* Current time stamp of file containing quotes    *)
  OldDataTime,            (* Old time stamp of file containing quotes        *)
  StartPos  : longint;    (* Index of quotes in Datafile                     *)
  RecsRead,               (* # of records (chars) read into Buffer           *)
  I, J,                   (* Indices and other stuff                         *)
  Code      : word;       (* Temporary storage                               *)
  NextParam : integer;
  Ch        : char;       (* Character pressed during prompt                 *)
  B,
  NumRows   : byte;       (* Number of rows on screen                        *)


(*****************************************************************************)
(*****************************************************************************)

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
    mov ah, 00h     (* Read character pressed on keyboard      *)
    int 16h         (* Call Keyboard function                  *)
  END;

(****************************************************************************)

FUNCTION SpacePos (Str : string) : byte; assembler;
(* This is a much faster version of the system.pos function except that
   this function searches only for a character, not a sub-string.    *)
  ASM
    cld                  (* Forward string-ops                       *)
    les   di, Str        (* Load string address                      *)
    xor   ch, ch         (* Only want lower word                     *)
    mov   cl, es:[di]    (* Load string length                       *)
    jcxz  @1             (* Exit if string length = 0                *)
    mov   bl, cl         (* Save string length                       *)
    inc   di             (* Start index at beginning of Str          *)
    mov   al, ' '        (* Load character to find                   *)
    repne scasb          (* Scan Str for character                   *)
    jne   @1             (* Jump if we didn't find                   *)
    sub   bl, cl         (* Subtract index from Str length for index *)
    mov   al, bl         (* Return position found                    *)
    jmp   @2             (* Get outta here                           *)
  @1:
    xor   al, al         (* Character wasn't found                   *)
  @2:
END; (* SpacePos *)

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
    jnc  @1                (* no, even                                               *)
    movsb                     (* move single char                                         *)
@1:
    rep  movsw             (* copy chars two at a time                                   *)
    pop  ds                (* restore caller's data segment                                *)
 END;

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
    jle  @2           (* Exit if new count <= 0                    *)
    lds  si, Str      (* Load source string                        *)
    mov  cl, ds:[si]  (* cl = length (string)                      *)
    xor  ch, ch       (* Clear msb of string length                *)
    sub  cx, ax       (* Length = length - index + 1               *)
    jle  @2           (* Exit if Length <= 0                       *)
    sub  cx, dx       (* # chars to move = length-count-index+1    *)
    jg   @1           (* Continue if # of chars > 0                *)
    mov  ds:[si], al  (* Else new length = index - 1               *)
    jmp  @2           (* Exit                                      *)
  @1:
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
  @2:
    mov  ds, bx       (* Restore ds                                *)
  END; (* Delete *)

(****************************************************************************)

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
    mov  di, ds        (* Set segemnt registers equal               *)
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

PROCEDURE TrimLeft (VAR Str: string); assembler;
(* Removes all spaces from left side of string *)
  ASM
    mov  dx, ds
    lds  si, &Str
    xor  cx, cx
    add  cl, ds:[si]
    je   @End
    cld
    mov  di, ds
    mov  es, di
    mov  di, si
    inc  di
    mov  al, ' '
    mov  bx, cx
    inc  cx
    rep  scasb
    cmp  bx, cx
    je   @End
    mov  ax, cx
    xchg di, si
    stosb
    dec  si
    rep  movsb
  @End:
    mov  ds, dx
  END;

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
    rep  movsb
    mov  al, &Ch        (* Insertion character                            *)
    stosb               (* Insert character in "hole"                     *)
  @End:
    mov  ds, bx         (* Restore ds                                     *)
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

(****************************************************************************)

FUNCTION UpCase (Ch: char): char; assembler;
(* Returns Ch as in uppercase letter if it as a lowercase letter; otherwise,
   Ch is returned unchanged.                                                *)
  ASM
    mov al, &Ch         (* al = Ch                           *)
    cmp al, 'a'         (* Skip if not 'a'..'z'              *)
    jb  @1
    cmp al, 'z'
    ja  @1
    sub al, 'a'-'A'     (* Convert Ch to an uppercase letter *)
  @1:
  END;

(****************************************************************************)

FUNCTION UpCaseStr (Str: ComStr): ComStr; assembler;
(* Convert Str into uppercase letters and return it.  Code adapted from
   Turbo Pascal 6.0 Programmer's Guide by Borland, pages 305-306.     *)
  ASM
    mov  dx, ds             (* Save DS register        *)
    cld                     (* Forward string-ops      *)
    lds  si, Str            (* Load string address     *)
    les  di, @Result        (* Load result address     *)
    lodsb                   (* Load string length      *)
    stosb                   (* Copy to result          *)
    xor  ah, ah             (* String length to cx     *)
    mov  cx, ax
    jcxz @3                 (* Skip if empty string    *)
  @1:
    lodsb                   (* Load character          *)
    cmp  al, 'a'            (* Skip if not 'a'..'z'    *)
    jb   @2
    cmp  al, 'z'
    ja   @2
    sub  al, 20h            (* Convert to uppercase    *)
  @2:
    stosb                   (* Store in result         *)
    loop @1                 (* Loop for all characters *)
  @3:
    mov  ds,dx              (* Restore DS register     *)
  END; (* UpCaseStr *)

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

FUNCTION ButtonPressed: boolean; assembler;
(* The mouse button status is returned in register bx; bl = 0 means no buttons
   are being pressed, 1 means left button, 2 = right button, and 3 means
   both buttons. We don't care which buttons here.                          *)
  ASM
    mov  ax, 0003h   (* Get mouse status       *)
    int  33h         (* Call mouse function    *)
    mov  al, bl      (* Return result          *)
  END;

(****************************************************************************)

FUNCTION NoMouse: boolean; assembler;
(* Returns TRUE if there is no mouse driver installed; otherwise, FALSE.
   To check if a mouse alone is installed takes too long, even though
   it's simply one function call.
   First, we see if there is a vector address for Int 33h, the mouse
   interrupt. Then, if there is, we have to make sure that the code
   there isn't just the instruction IRET (CFh in op-code).  Adapted from
   Allen L. Wyatt, Sr.'s Advanced Assembly Language, pages 373-374.         *)
  ASM
    mov  ah, 35h                   (* Get interrupt vector           *)
    mov  al, 33h                   (* Mouse interrupt                *)
    int  21h                       (* Call function                  *)
    or   ax, bx                    (* Was an address returned?       *)
    jz   @No_Mouse                 (* No, so there's no mouse        *)
    cmp  byte ptr es:[bx], 0CFh    (* Is IRET at address?            *)
    je   @No_Mouse                 (* Yes, so no driver installed    *)
    xor  al, al                    (* Return FALSE - mouse installed *)
    jmp  @Done                     (* We're done                     *)
  @No_Mouse:                       (* There's no mouse               *)
    mov  al, 1                     (* Return TRUE - no mouse         *)
  @Done:
  END; (* NoMouse *)

(****************************************************************************)
(* End of assembler routines *)
(* ========================= *)
(****************************************************************************)

FUNCTION Comma (Num: longint): NumStr;
(* Converts Num to a string type adding a thousands separator               *)
  VAR
    I: integer;
    J: byte;
  BEGIN
    str (Num:1, TmpStr);
    I := (length (TmpStr) - 2);
    J := 0;
    WHILE (I > 1) AND (TmpStr[I-1] <> ' ') DO
      BEGIN
        ChInsert (',', TmpStr, I);
        dec (I, 3);
        inc (J)
      END;
    FOR I := 1 TO J DO
      IF (TmpStr[1] = ' ') THEN
        Del1 (TmpStr);
    Comma := TmpStr
  END;

PROCEDURE Writeln (Str: string);
(* This procedure reduces the size of compiled code and can even (in some
   cases) reduce execution time of program. Really! *)
  BEGIN
    system.writeln (Str)
  END;

(****************************************************************************)

PROCEDURE PWrite (Str: string);
(* Used for all output to screen except quote display. The current row on the
   screen being displayed is kept track off so before the screen scrolls up,
   the user is prompted to continue.                                     *)
  VAR
    Ch: char;                    (* character pressed by user            *)
  BEGIN
    inc     (CurrRow);           (* increment # of rows displayed so far *)
    Writeln (Str);               (* output string                        *)

    IF (CurrRow = NumRows) THEN  (* time to prompt user?                 *)
      BEGIN
	write ('Press any key to continue, or <Esc> to quit...'#13);
	Ch := ReadKey;
	clreol;
	IF (Ch = Esc) THEN       (* halt program if <Esc> key pressed    *)
	  BEGIN
	    Writeln (#13#10'Execution halted: <Esc> pressed.');
	    halt (0)
	  END;
	CurrRow := 0
      END

  END; (* PWrite *)

(****************************************************************************)

PROCEDURE DisplayTitle;
(* Display program's title if it isn't already displayed. *)
  BEGIN
    IF TitleNotShown THEN
      BEGIN
	NumRows := hi (CRT.windmax);
	PWrite (Title);
	TitleNotShown := FALSE
      END
  END;

(****************************************************************************)

PROCEDURE DisplayOptions;
(* Display command-line options. *)
  BEGIN
    DisplayTitle;
    PWrite ('Syntax: UTTER  [option(s)]  [datafile path]');
    PWrite ('');
    PWrite ('Options: /N  ---------- show Number of quotes in data file');
    PWrite ('         /R  ---------- utter Random quote');
    PWrite ('         /W  ---------- disable all Warning prompts');
    PWrite ('         /D  ---------- utter quotes Directly to video memory (default)');
    PWrite ('         /B  ---------- use BIOS routines for video output (slower)');
    PWrite ('         /V  ---------- use DOS routines for Video output (slowest)');
    PWrite ('         /S  ---------- enable video Snow-checking (for CGA monitors)');
    PWrite ('         /C  ---------- Clear the screen before quote is uttered');
    PWrite ('         /K  ---------- prompt user to press a Key after quote');
    PWrite ('         /M  ---------- prompt user to click Mouse button after quote');
    PWrite ('         /O  ---------- display these Options');
    PWrite ('         /G  ---------- display UTTER environment variable settinG');
    PWrite ('         /#  ---------- utter # quotes, where # is a minimum of 0');
    PWrite ('         /P[x]  ------- Pause for approximately x seconds after quote');
    PWrite ('                        (default is 2 seconds, maximum is 60)');
    PWrite ('         /U[A|T]  ----- Update index file, Adding tilde (~) or Truncating');
    PWrite ('                        data file if tilde is missing');
    PWrite ('         /E[editor]  -- invoke Editor (' + Editor + ' is default)');
    PWrite ('         /?, /H  ------ for more information')
  END;

(****************************************************************************)

PROCEDURE DisplayHelp;
(* Display detailed explanation of user options. *)
  BEGIN
    DisplayOptions;

    PWrite ('');
    PWrite ('- UTTER displays a quote from an ASCII text data file, called UTTER.DAT');
    PWrite ('  by default, which is assumed to be in the same directory as UTTER.EXE.');
    PWrite ('');
    PWrite ('- All quotes in the data file must end with a tilde (~).  The length of');
    PWrite ('  each quote is limited to ' + Comma (sizeof (Buffer)) + ' bytes.');
    PWrite ('');
    PWrite ('- To use a different data file just specify its full path name on the');
    PWrite ('  command-line.  If the default data file is in a different directory');
    PWrite ('  than the executable file, then specify the directory name on the');
    PWrite ('  command-line, making sure it ends with a `\'' character.');
    PWrite ('');
    PWrite ('- An index file is associated with each different data file, having the');
    PWrite ('  same name as the data file except with an ' + IndexExt + ' extension.');
    PWrite ('');
    PWrite ('- Each index file must be in the same directory as its corresponding data');
    PWrite ('  file.  Index files are created automatically if they do not exist in the');
    PWrite ('  same directory as its data file or if they are corrupt in some way.');
    PWrite ('');
    PWrite ('- All options may be preset in the UTTER environment variable, having the');
    PWrite ('  same syntax as the command-line.  Options specifed on the command-line');
    PWrite ('  override any applicable options in the environment variable.');
    PWrite ('');
    PWrite ('- Options can appear in any order and can be combined.');
    PWrite ('');
    PWrite (' Explanation of options (examples follow)');
    PWrite (' ======================');
    PWrite ('   /N  --------- display the number of quotes in the current data file.');
    PWrite ('   /R  --------- utter a random quote from the current data file.');
    PWrite ('   /W  --------- disable any warning prompts when creating index file.');
    PWrite ('   /D  --------- write output directly to video memory. This is the');
    PWrite ('                 default output method.');
    PWrite ('   /B  --------- use BIOS routines for output, which is slower. If your');
    PWrite ('                 monitor acts up and the /S option does not fix it, try');
    PWrite ('                 this option.');
    PWrite ('   /V  --------- use DOS routines for output.  This is the slowest but it');
    PWrite ('                 allows any output to be re-directed, if desired.');
    PWrite ('   /S  --------- enable video snow-checking, which CGA screens may');
    PWrite ('                 require.');
    PWrite ('   /C  --------- clear the screen before a quote is uttered.');
    PWrite ('   /K  --------- prompt the user after a quote is uttered with the');
    PWrite ('                 following: "Press any key to continue...".');
    PWrite ('   /M  --------- prompt the user after a quote is uttered with the');
    PWrite ('                 following: "Click mouse button to continue...".  If the');
    PWrite ('                 /K option is enabled in addition to this one, the prompt');
    PWrite ('                 is: "Press any key or click mouse button to continue..."');
    PWrite ('   /O  --------- display UTTER''s options.');
    PWrite ('   /G  --------- display UTTER environment variable setting, if it is set.');
    PWrite ('   /#  --------- utter the number of quotes specified by #, which must be');
    PWrite ('                 greater than or equal to 0.  If # is greater than the');
    PWrite ('                 number of quotes in the data file and the /R option is');
    PWrite ('                 not specified then # is set to the number of quotes in');
    PWrite ('                 the data file.');
    PWrite ('   /P[x]  ------ after a quote is uttered, pause for the specified');
    PWrite ('                 number of seconds, or for 2 seconds by default.  Seconds');
    PWrite ('                 must be >= 0 and <= 60.  If x is specified, the /#');
    PWrite ('                 option cannnot immediately follow x.  Ex: "/P62" ->');
    PWrite ('                 wrong, "/P6 /2" -> right, "/2P6" -> right.  If the /K or');
    PWrite ('                 /M options are specified too, the /P[x] option will be');
    PWrite ('                 executed first.');
    PWrite ('   /U[A|T]  ---- update current data file, creating an index file for it.');
    PWrite ('                 If a tilde (~) is missing at the end of the data file,');
    PWrite ('                 the /A option adds a tilde to the end of the data file.');
    PWrite ('                 The /T option truncates the data file to where the last');
    PWrite ('                 tilde was if a tilde is missing.  If the /W option is');
    PWrite ('                 specified and /A and /T are not, then the data file is');
    PWrite ('                 unchanged.  Note that the /A and /T options do not have');
    PWrite ('                 to follow /U; they can appear anywhere on the command-');
    PWrite ('                 line.');
    PWrite ('   /E[editor]  - execute, by default, the editor EDIT using either the');
    PWrite ('                 default data file UTTER.DAT or the file specified on the');
    PWrite ('                 command-line.  To use a different editor, specify the');
    PWrite ('                 editor''s name immediately after the /E option.');
    PWrite ('');
    PWrite (' Examples');
    PWrite (' ========');
    PWrite ('1) UTTER  /11  quotes.txt  /vr  /k');
    PWrite ('   - displays eleven (11) random quotes from the file QUOTES.TXT using');
    PWrite ('     DOS output routines and prompts user to press a key afterwards.');
    PWrite ('');
    PWrite ('2) UTTER  /wu  /eMyEdit  /t');
    PWrite ('   - executes the editor MYEDIT on the default data file UTTER.DAT, then');
    PWrite ('     updates the index file automatically after MYEDIT execution halts.');
    PWrite ('     If the data file contains a quote that does not end with a tilde,');
    PWrite ('     then that quote is deleted ("/t" option) from the data file.');
    PWrite ('');
    PWrite ('3) UTTER  /sp5  \utils\  /r');
    PWrite ('   - displays a random quote from the default data file UTTER.DAT located');
    PWrite ('     in the \UTILS\ directory using snow-checking, pausing for five');
    PWrite ('     seconds afterwards.');
    PWrite ('');
    PWrite ('4) UTTER  /r5p1vw  /u');
    PWrite ('   - displays five (5) random quotes from the default data file,');
    PWrite ('     updating it automatically first, pausing for one second afterwards.');
    PWrite ('     This cryptic example could have been specified a number of ways,');
    PWrite ('     including "UTTER /r /5 /p1 /v /w /u", or "UTTER /uvp1r5w", etc.');
    PWrite ('');
    PWrite (' Copyright Information');
    PWrite (' =====================');
    PWrite ('- This software may be freely distributed without cost, provided it is');
    PWrite ('  not changed in any way.  If you find this program useful, donations to');
    PWrite ('  the address listed below would be most appreciated.');
    PWrite ('');
    PWrite ('- I take no responsibility for any liability, loss, or damage caused or');
    PWrite ('  alleged to be caused directly or indirectly from the use of this');
    PWrite ('  program.');
    PWrite ('');
    PWrite ('- UTTER was written in Turbo Pascal 6.0.  Source code is available for a');
    PWrite ('  small fee.  Future versions are forthcoming.');
    PWrite ('');
    PWrite ('- If you discover any bugs, or have any ideas or suggestions, please feel');
    PWrite ('  free to contact me:');
    PWrite ('    Jody R. Cairns');
    PWrite ('    jcairns@gmail.com');
    halt (0)
  END;

(****************************************************************************)

PROCEDURE CheckError (ErrorCode: word);
(* Display error message and halt program if an error occurs. *)
  BEGIN
    CASE ErrorCode OF
       00: exit;
       02: Error := 'Could not find quote file ' + fexpand (DataPath);
       03: Error := 'Path not found.';
       04: Error := 'Too many open files.';
       05: Error := 'File access denied to ';
       06: Error := 'Invalid file handle.';
       08: Error := 'Not enough memory to run ' + EditorPath;
       20: Error := 'Invalid DOS version. Requires DOS 3.0 or greater.';
       21: Error := 'Quote file cannot have ' + IndexExt + ' extension. Rename quote file.';
       22: Error := 'No option specified.';
       23: Error := 'Number of quotes must be > 0 and <= ' + Comma (maxlongint) + '.';
       24: Error := 'Invalid editor name. ' + Editor + ' is not executable.';
       25: Error := 'No editor filename specified.';
       26: Error := 'Could not find editor ' + Editor + Ext;
       27: Error := 'Invalid command-line option: "' + CmdLine[J] + '"';
       28: Error := 'Pause seconds must be >= 0 and <= 60.';
       30: Error := 'No mouse driver installed on system.';
       31: Error := 'Quote to long or missing ~.  Maximum length is ' + Comma (sizeof(Buffer)) + ' bytes.';
       32: Error := 'Index file not updated or created.';
       33: Error := 'Data file contains no quotes.  Index file deleted.';
      100: Error := 'Disk read error. Index file may be corrupt.' +
		    #13#10'       Recommend updating file using /U option.';
      101: Error := 'Disk write error. Disk is probably full.';
      106: Error := 'Invalid numeric format. Index file may be corrupt.' +
		    #13#10'       Recommend updating file using /U option.';
      150: Error := 'Disk is write-protected.';
      151: Error := 'Unknown disk unit ID.';
      152: Error := 'Drive not ready.';
      154: Error := 'CRC error in data.';
      155: Error := 'Bad drive request structure length.';
      156: Error := 'Disk seek error.';
      157: Error := 'Unknown media type.';
      158: Error := 'Sector not found.';
      160: Error := 'Device write fault.';
      161: Error := 'Device read fault.';
      162: Error := 'Hardware failure.'
      ELSE
	Error := '#' + Comma (ErrorCode) + '. Please report this to author.'
    END; (* CASE *)

    IF (ErrorCode = 5) THEN
      BEGIN
        DataPath := Dir + Name;
        IF Index THEN
          DataPath := DataPath + IndexExt
        ELSE
          DataPath := DataPath + Ext;
        Error := Error + fexpand (DataPath) + '.'
      END;

    DisplayTitle;
    PWrite ('ERROR: ' + Error);

    IF (ErrorCode >= 22) AND (ErrorCode <= 30) THEN (* command-line error *)
      DisplayOptions;

    halt (ErrorCode)

  END; (* CheckError *)

(****************************************************************************)

FUNCTION Continue (Str: string): boolean;
(* Prompt user if they want to continue or not. Return TRUE if they want to;
   otherwise, return FALSE. *)
  VAR
    Ch : char;    (* Character pressed by user *)
  BEGIN
    write (Str, '. '#13#10'Continue (Y/N/)? ');
    REPEAT
      Ch := Upcase (ReadKey);
      IF (Ch = Esc) THEN
	BEGIN
	  Writeln ('');
	  CheckError (32)
	END;

    UNTIL (Ch = 'Y') OR (Ch = 'N');

    Writeln (Ch);
    Continue := (Ch = 'Y')
  END; (* Continue *)

(****************************************************************************)

PROCEDURE RunEditor;
(* Search for editor to be used for editing quote file and execute it *)
  VAR
    Dir    : DirStr;    (* Directory location of editor *)
    Name   : NameStr;   (* Filename of editor           *)
    OrigExt: ExtStr;    (* Extension of editor          *)
    Path   : string;    (* Copy of environment's PATH   *)
  BEGIN
    DisplayTitle;

    Path := Dir + ';' + GetEnv ('PATH');

    fsplit (Editor, Dir, Name, OrigExt);

    (* see if Name is valid *)
    IF (length (Name) = 0) THEN
      CheckError (25);

    (* Check if user put on extension on editor name *)
    IF (length (OrigExt) = 0) THEN
      StrMov (Ext, '.COM')

    (* Must be executable file *)
    ELSE IF (OrigExt <> '.COM') AND (OrigExt <> '.EXE') AND (OrigExt <> '.BAT') THEN
      CheckError (24)

    ELSE
      StrMov (Ext, OrigExt);

    StrMov (Editor, Dir + Name);

    (* Search for user's editor. Here, it either has a COM extension or
       no extension. *)
    StrMov (EditorPath, fsearch (Editor + Ext, Path));

    (* Search for editor *)
    IF (length (EditorPath) = 0) THEN  (* didn't find COM editor or users *)

      IF (length (OrigExt) = 0) THEN
	BEGIN
	  StrMov (EditorPath, fsearch (Editor + '.EXE', Path));

	  IF (length (EditorPath) = 0) THEN (* didn't find EXE editor *)
	    BEGIN
	      StrMov (EditorPath, fsearch (Editor + '.BAT', Path));

	      IF (length (EditorPath) = 0) THEN (* didn't find BAT editor *)
		BEGIN
		  StrMov (Ext, OrigExt);
		  CheckError (26)
		END
	    END
	END
      ELSE
	CheckError (26);

    StrMov (EditorPath, fexpand (EditorPath));

    (* execute editor *)
    swapvectors;
    exec (GetEnv ('COMSPEC'), '/C ' + Editor + ' ' + DataPath);
    swapvectors;
    CheckError (DOSError)

  END; (* RunEditor *)

(****************************************************************************)

PROCEDURE CheckIOError (Error: word);
(* This procedure is only used by UpdateIndexFile to check for
   Input/Output errors when reading and writing is done to the data file
   and index file. *)
  BEGIN
    IF (Error <> 0) THEN
      BEGIN
	Writeln ('');
	CheckError (Error)
      END
  END; (* CheckIOError *)

(****************************************************************************)

PROCEDURE CheckWriteError (Error: word);
  BEGIN
    IF (Error <> 0) THEN
      IF (Error = 5) THEN
        BEGIN
          write ('NOTE: File access denied. Could not ');
          IF TruncateFile THEN
            Writeln ('truncate data file.')
          ELSE
            Writeln ('add tilde character.')
        END
      ELSE
        CheckError (Error)
  END;

PROCEDURE AddTildeToFile (VAR NumberOfQuotes: longint);
  BEGIN
    Index     := FALSE;
    AddTilde  := TRUE;
    Buffer[1] := EndOfQuote;
    seek (DataFile, filesize (DataFile));
    blockwrite (DataFile, Buffer, 1);
    CheckWriteError (IOResult);
    Writeln ('Tilde character has been appended to end of data file.');
    I := wherex;
    J := wherey;
    gotoxy (19, (wherey - 2));
    Write (Comma (NumberOfQuotes + 1));
    gotoxy (I, J)
  END;

PROCEDURE TruncateFileNow (VAR QuoteLength: word);
  BEGIN
    Index := FALSE;
    TruncateFile := TRUE;
    seek (DataFile, StartPos);
    truncate (DataFile);
    CheckWriteError (IOResult);
    Writeln ('Last ' + Comma (QuoteLength) + ' character(s) have been truncated from data file.')
  END;

PROCEDURE FixTildeMissing (VAR QuoteLength: word; VAR NumberOfQuotes: longint);
  BEGIN
    IF AddTilde THEN
      AddTildeToFile (NumberOfQuotes)

    ELSE IF TruncateFile THEN
      TruncateFileNow (QuoteLength)

    ELSE
      BEGIN
        write ('WARNING: Last ');
        IF (QuoteLength = 1) THEN
          write ('character does')
        ELSE
          write (Comma (QuoteLength) + ' characters do');
        Writeln (' not end with a tilde (~) in the');
        write   ('         data file.  ');
        IF DoPrompts THEN
          BEGIN
            Writeln ('Add tilde marker to end of file, Truncate');
            write   ('         file, or Neither (A/T/N)? ');
            REPEAT
              Ch := ReadKey;
              IF (Ch = Esc) THEN
                Ch := 'N'
            UNTIL (UpCase (Ch) = 'A') OR (UpCase (Ch) = 'T') OR (UpCase (Ch) = 'N');
            Writeln (Ch);

            CASE UpCase (Ch) OF
              'A': AddTildeToFile  (NumberOfQuotes);
              'T': TruncateFileNow (QuoteLength);
              'N': Writeln ('No changes made to data file.')
            END
          END (* IF *)
        ELSE
          Writeln ('Warning prompt is off, so no changes made.')
      END (* ELSE *)
  END;


PROCEDURE UpdateIndexFile (Code: word);
(* Update the index file for the particular quote file in use.
   The quote file (DataFile) is scanned for the end of quote marker (EndOfQuote),
   and each position of EndOfQuote is written to IndexFile. The complete
   format of IndexFile is as follows (records are longint):

     1st record (OldDataTime):
     --- last recorded date and time of DataFile. This is compared with
	 the current date and time of DataFile to see if DataFile has
	 been altered in any way. If it has, then IndexFile is updated.

     2nd record (StartPos):
     --- seek position into DataFile where next quote that is to be
	 displayed is located. For example: Let StartPos := 274
	 Then before a quote is displayed, we "seek (DataFile, StartPos)",
	 which moves the file pointer for DataFile to position 274 in
	 DataFile, which is where the quote to be displayed is located.

     3rd and remaining records:
     --- these records are similar to the 2nd record above except that they
	 are the sequential positions the each quote in DataFile. Thus, the
	 3rd record is always equal to zero, since that marks the beginning
	 of the first quote in DataFile. The 4th record indicates the next
	 location of the 2nd quote in DataFile, and so on.
	 These records are ONLY used by the UTTER /R option, or the Random
	 option.  If that option is chosen, UTTER "seek"s to a random
	 record in IndexFile from the 3rd to last record. Then, StartPos
	 is read from IndexFile to indicate where the quote in DataFile is
	 located.
									   *)
  VAR
    QuoteLength   : word;
    ZeroLength,
    NumberOfQuotes: longint;
    DoPrompt,
    Warning       : boolean;

  BEGIN
    DisplayTitle;

    IF DoPrompts AND (NOT Continue ('About to create a new index file for ' + fexpand (DataPath))) THEN
      CheckError (Code);

    IF (UpCaseStr (Ext) = IndexExt) THEN  (* Datafile can't have .IDX extension *)
      CheckError (21);

    UpDateFile     := TRUE;
    DoPrompt       := TRUE;
    ZeroLength     := 0;
    NumberOfQuotes := 0;
    QuoteLength    := 0;

    writeln ('Creating ' +  fexpand (Dir + Name) +  IndexExt);

    rewrite    (IndexFile);
    CheckError (IOResult);

    write (#13'Number of quotes: ', NumberOfQuotes:1);

    write (IndexFile, DataTime, NumberOfQuotes, NumberOfQuotes);
    CheckIOError (IOResult);

    REPEAT
      blockread (DataFile, Buffer, sizeof (Buffer), RecsRead);
      CheckIOError (IOResult);

      FOR I := 1 TO RecsRead DO
	IF (Buffer[I] = EndOfQuote) THEN
	  BEGIN
            inc (NumberOfQuotes);

	    write (#13'Number of quotes: ', Comma (NumberOfQuotes));

            StartPos := (filepos (DataFile) - (RecsRead - I));

            IF (StartPos <> filesize (DataFile)) THEN
              write (IndexFile, StartPos);

	    CheckIOError (IOResult);
            QuoteLength := 0
	  END (* IF *)
        ELSE
          BEGIN
            inc (QuoteLength);
            IF (QuoteLength = sizeof (Buffer)) THEN
              BEGIN
                close (IndexFile);
                close (DataFile);
                Writeln ('');
                CheckError (31)
              END
          END
    UNTIL (RecsRead = 0);

    Writeln ('');

    IF (QuoteLength <> 0) THEN
      BEGIN
        FixTildeMissing (QuoteLength, NumberOfQuotes);
        IF AddTilde OR TruncateFile THEN
          BEGIN
            close (DataFile);
            reset (DataFile,1);
            CheckError (IOResult);
            Index := TRUE;
            getftime (DataFile, DataTime);
            seek (IndexFile, 0);
            write (IndexFile, DataTime);
            CheckError (IOResult)
          END
      END;

    IF (NumberOfQuotes = 0) THEN
      BEGIN
        close (IndexFile);
        erase (IndexFile);
        I := IOResult;
        CheckError (33)
      END;

    OldDataTime := DataTime;
    StartPos    := 0;
    seek (IndexFile, 0)

  END; (* UpdateIndexFile *)

(****************************************************************************)

PROCEDURE ProcessOptions;
  BEGIN
    FOR J := 2 TO NextParam DO
      CASE Upcase (CmdLine[J]) OF
	'R': BEGIN
	       GetRandom := TRUE;
	       randomize
	     END;
	'V': BEGIN (* Use standard DOS output *)
	       DosVideo := TRUE;
	       assign   (output, '');
	       rewrite  (output)
	     END;
	'B': IF DOSVideo THEN
	       BEGIN
		 BiosVideo := TRUE;
		 assigncrt (output);
		 rewrite   (output)
	       END
	     ELSE
	       DirectVideo := FALSE;
	'D': IF (BiosVideo) THEN
	       DirectVideo := TRUE
	     ELSE IF (DOSVideo) THEN
	       BEGIN
		 assigncrt (output);
		 rewrite   (output)
	       END;
	'C': clrscr;
	'S': CheckSnow   := TRUE;
	'W': DoPrompts   := FALSE;
	'P': BEGIN (* Pause after quote is displayed *)
	       Pause  := TRUE;
	       StrMov (TmpStr, Copy (CmdLine, J+1, (NextParam-J+1)));
               (* See if seconds are specified *)
	       IF (length (TmpStr) <> 0) AND (((TmpStr[1] >= '0') AND (TmpStr[1] <= '9')) OR (TmpStr[1] = '-')) THEN
                 BEGIN
                   (* Convert seconds to number *)
		   val (TmpStr, LongIntVar, Code);
		   IF (Code <> 0) THEN
                     BEGIN
                       (* Options follow seconds, so get rid of them *)
                       StrMov (TmpStr, Copy (TmpStr, 1, (Code-1)));
                       (* Try to convert again *)
                       val (TmpStr, LongIntVar, Code)
                     END;
                   IF (Code <> 0) OR (LongIntVar > MaxSeconds) OR (LongIntVar < 0) THEN
		     CheckError (28);
                   inc (J, (length (TmpStr)));
                   PauseMilSecs := LongIntVar * 1000
                 END;
	     END;
	'K': BEGIN (* Prompt user after quote is displayed *)
	       KeyPause := TRUE;
	       IF MousePause THEN
		 StrMov (Prompt, #13#10'Press any key or click mouse button to continue...')
	     END;
	'M': BEGIN (* Prompt user after quote is displayed *)
	       IF NoMouse THEN
		 CheckError (30);
	       MousePause := TRUE;
	       IF KeyPause THEN
		 StrMov (Prompt, #13#10'Press any key or click mouse button to continue...')
	       ELSE
		 StrMov (Prompt, #13#10'Click mouse button to continue...')
	     END;
	'E': BEGIN (* Invoke editor *)
	       InvokeEditor := TRUE;
	       IF (J <> NextParam) THEN  (* Get specified editor *)
		 BEGIN
		   StrMov (Editor, UpCaseStr (Copy (CmdLine, J+1, (NextParam-J))));
		   exit
		 END
	     END;
	'G': BEGIN
	       DisplayTitle;
	       StrMov (TmpStr, GetEnv ('UTTER'));
	       IF (TmpStr = '') THEN
		 Writeln ('UTTER environment variable is not set.')
	       ELSE
		 Writeln ('UTTER=' + TmpStr)
	     END;
	'N': ShowNumber  := TRUE;
	'U': UpdateFile  := TRUE;
        'A': BEGIN
              AddTilde     := TRUE;
              IF TruncateFile THEN
                TruncateFile := FALSE
             END;
        'T': BEGIN
               TruncateFile := TRUE;
               IF AddTilde THEN
                 AddTilde := FALSE
             END;
        'O': BEGIN
               DisplayOptions;
               halt (0)
            END;
	'?',
	'H': DisplayHelp
	ELSE  (* See if number was specified *)
	  BEGIN
	    StrMov (TmpStr, Copy (CmdLine, J, (NextParam-J+1)));
	    val (TmpStr, LongIntVar, Code);
	    IF (Code <> 0) THEN
	      BEGIN
		IF (Code = 1) THEN
		  CheckError (27);
		IF (Code <> 0) THEN
		  BEGIN
		    StrMov (TmpStr, Copy (TmpStr, 1, (Code-1)));
		    val (TmpStr, LongIntVar, Code);
		    IF (Code <> 0) THEN
		      CheckError (23)
		  END
	      END;
	    IF (LongIntVar < 0) THEN
	      CheckError (23);
	    NumQuotes := LongIntVar;
            IF (NumQuotes = 0) THEN
              DisplayTitle;
            inc (J, (length (TmpStr)-1))
	  END
      END (* CASE *)

  END; (* ProcessOptions *)

(****************************************************************************)

PROCEDURE ProcessParams;
  BEGIN
    (* Trim spaces from right side of string *)
    WHILE (CmdLine[length(CmdLine)] <= #32) AND (length (CmdLine) > 0) DO
      dec (CmdLine[0]);

    IF (CmdLine <> '') THEN
      REPEAT

        (* Trim spaces from left side of string *)
	TrimLeft (CmdLine);

	NextParam := (SpacePos (CmdLine) - 1);

	IF (NextParam < 0) THEN
	  NextParam := length (CmdLine);

	IF (CmdLine[1] = '/') THEN
	  BEGIN
	    IF (length (CmdLine) = 1) THEN
	      CheckError (22);
	    ProcessOptions
	  END

	ELSE
	  BEGIN
	    StrMov (TmpStr, Copy (CmdLine, 1, NextParam));
	    IF (CmdLine[1] = '?') THEN
	      DisplayHelp;
	    IF (CmdLine[NextParam] = '\') THEN  (* different directory *)
	      StrMov (Dir, TmpStr)
	    ELSE
	      fsplit (TmpStr, Dir, Name, Ext)       (* different data file *)
	  END;

	Delete (CmdLine, 1, NextParam+1)

      UNTIL (CmdLine = '')
  END;


(****************************************************************************)
(****************************************************************************)


BEGIN (* main program *)

  (* See if valid DOS version *)
  ASM
    mov  ah, 30h         (* Check DOS version        *)
    int  21h
    cmp  al, 03h         (* Version >= DOS 3.0?      *)
    jae  @Okay           (* Yes, then okay           *)
    mov  ax, 20          (* Nope, so CheckError (20) *)
    push ax
    call CheckError
  @Okay:
  END;

  (* Turn off snow checking   *)
  CheckSnow := FALSE;

  (* Get directory where UTTER is residing *)
  fsplit (fexpand (paramstr(0)), Dir, Name, Ext);

  StrMov (Ext, '.DAT');    (* Default quote file extension *)

  (* Get environment variable *)
  StrMov (CmdLine ,GetEnv ('UTTER'));

  IF (CmdLine <> '') THEN  (* Process any env. variable options *)
    ProcessParams;

  (* Get command-line *)
  StrMov (CmdLine, ComStr (ptr (prefixseg, $0080)^));

  IF (CmdLine <> '') THEN   (* Process any options *)
    ProcessParams;

  StrMov (DataPath, (Dir + Name + Ext));  (* Quote data file's full path name  *)

  (* Open data file and see if it is valid *)
  assign (DataFile, DataPath);
  reset  (DataFile, 1);
  CheckError (IOResult);

  IF InvokeEditor THEN  (* Run editor on data file if requested now *)
    BEGIN
      close (DataFile);
      CheckError (IOResult);
      RunEditor;
      reset (DataFile, 1);
      CheckError (IOResult)
    END;

  (* Get current data file's time *)
  getftime (DataFile, DataTime);

  Index := TRUE;

  (* Open index file for data file and see if it is valid *)
  assign (IndexFile, Dir + Name + IndexExt);
  reset  (IndexFile);
  Code := IOResult;

  (* Check if any errors occured when index file was opened or if user  *)
  (* requested to automatically update index file                       *)

  IF (Code <> 0) OR UpdateFile THEN
    BEGIN

      (* Code = 2 means 'file not found'. Anything else we can't deal with. *)
      IF (Code <> 2) AND (NOT UpdateFile) THEN
	CheckError (Code);

      IF UpdateFile THEN   (* Code = 32 -> index file not created *)
	Code := 32;

      (* Create new index file *)
      UpdateIndexFile (Code)

    END; (* IF *)

  (* Read old data file's time and seek position of quote to be displayed *)
  read (IndexFile, OldDataTime, StartPos);
  Code := IOResult;
  IF (Code <> 0) THEN
    BEGIN

      (* Code = 106 means 'invalid numereic format' and                    *)
      (* Code = 100 means 'disk read error' which both probably indicates  *)
      (* that the index file is corrupt, which we can deal with.   *)

      IF (Code <> 106) AND (Code <> 100) THEN
	CheckError (Code);

      DisplayTitle;
      writeln ('Something is amiss...');

      UpdateIndexFile (Code)

    END; (* IF *)

  (* Compare old and new times, and update index file if different *)
  IF (OldDataTime <> DataTime) THEN
    BEGIN
      DisplayTitle;
      writeln ('Something is amiss...');

      UpdateIndexFile (32)

    END; (* IF *)

  (* Display number of quotes in data file? *)
  IF ShowNumber AND (NOT UpDateFile) THEN
    BEGIN
      DisplayTitle;
      writeln ('Number of quotes in ' + fexpand (DataPath) + ': ' + Comma (filesize (IndexFile) - 2))
    END;

  IF (NumQuotes > 1) AND (NOT GetRandom) THEN
    BEGIN
      LongIntVar := (filesize (IndexFile) - 2);
      IF (NumQuotes > LongIntVar) THEN
	NumQuotes := LongIntVar
    END;

  FOR J := 1 TO NumQuotes DO
    BEGIN
      (* Get random quote? *)
      IF GetRandom THEN
	BEGIN
	  StartPos := (filesize (IndexFile) - 1);

	  (* StartPos in this case must be <= a word-range because of the  *)
	  (* function 'random', which accepts nothing larger than a word.  *)

	  IF (StartPos > MaxWord) THEN
	    StartPos := MaxWord
	  ELSE
	    dec (StartPos);

	  IF (StartPos <= 0) THEN
	    UpDateIndexFile (32);

	  seek (IndexFile, (random (StartPos) + 2));
	  CheckError (IOResult);
	  read (IndexFile, StartPos);
	  CheckError (IOResult)

	END; (* GetRandom *)

      (* Seek into data file for the position of the quote to be displayed  *)
      seek (DataFile, StartPos);

      (* Display quote *)
      blockread  (DataFile, Buffer, sizeof (Buffer), RecsRead);
      CheckError (IOResult);

      FOR I := 1 TO RecsRead DO
	IF (Buffer[I] <> EndOfQuote) THEN
	  write (Buffer[I])
	ELSE
	  goto EndLoop2;

      IF (I = sizeof (Buffer)) THEN
        BEGIN
          Writeln ('');
          CheckError (31)
        END;

  EndLoop2:

      system.writeln;

      inc (StartPos, I);
      IF  (StartPos >= filesize (DataFile)) THEN
        StartPos := 0

    END; (* FOR *)

  (* Prepare to write next quote to be displayed position *)
  seek (IndexFile, 1);

  (* Write next quote position in index file *)
  write      (IndexFile, StartPos);
  CheckError (IOResult);

  (* Close files *)
  close      (IndexFile);
  CheckError (IOResult);
  close      (DataFile);
  CheckError (IOResult);

  IF Pause THEN
    delay (PauseMilSecs);

  IF KeyPause OR MousePause THEN
    BEGIN
      Writeln (Prompt);                    (* Display prompt *)

      IF KeyPause THEN
        BEGIN
          IF MousePause THEN
            REPEAT
            UNTIL KeyPressed OR ButtonPressed
          ELSE
	    REPEAT
   	    UNTIL KeyPressed;
          IF (KeyPressed) THEN
            halt (ord (UpCase (ReadKey)))
        END (* IF *)
      ELSE
	REPEAT
	UNTIL ButtonPressed;

      halt (255)
    END  (* IF *)

END. (* main program *)