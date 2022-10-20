Date sent:        Fri, 30 Jun 95 11:56:30 -0700
From:             "Jody R. Cairns" <jodyc@cs.mun.ca>
Organization:     Dept. of Fisheries and Oceans
To:               cwhite@teleport.com
Subject:          grep-like algorithm

unit Bmh;
{
BMH 1.0, Copyright (c) 1995, by Jody R. Cairns (jodyc@cs.mun.ca)

This unit implements the Boyer-Moore-Horspool pattern searching
algorithm as taken from the 'Handbook of Algorithms and Data Structures
in Pascal and C', Second Edition, by G.H Gonnet and R. Baeza-Yates.

The algorithm searches for a pattern within a buffer.  I have added
functions to implement the searches with files of any type.

Implementation:  I designed this unit for two types of users - those
  who want complete control of their code (Non-lazy), and those who
  don't (Lazy).  "Non-lazy" users have to manually set some
  variables that are essential for the algorithm.  "Lazy" users
  don't have to do anything except call a function.

1) Lazy:  the following function returns the offset in which
the specified string is found with the specified file.  A value
of -1 is returned if the string is not found:
function GetStringOffset (StrToFind: string; const FileName: TFileName): 
longint;
  Example
    if GetStringOffset('PATH','C:\AUTOEXEC.BAT') <> -1 then
      Text1.Caption := 'Found expression'
    else
      Test1.Caption := 'Expression not found';

2) Non-lazy:  you should see the function GetStringOffset for everything
that needs to be done before FindString is called, which is the main
function that opens the file for searching.  GetStringOffset creates
a buffer each time it is called.  However, you need only they do this
once.  Also, the procedure MakeBMHTable must be called for each DIFFERENT
string to be searched for.  You needn't call MakeBMTable everytime the
same string is searched for.
REQUIREMENTS:
  a)  Call CreateBuffer which allocates memory for the buffer to
      be used whe reading files.  The buffer is a global variable called
      Buffer of type TSearchBuffer.  CreateBuffer returns the amount of
      memory allocated for Buffer.
  b)  Call BMHTable(MyString) to create the index table for the string
      to be searched for (MyString).  This MUST be called for every
      DIFFERENT string to be searched for.  However, it need only be
      called ONCE for each different string.  The index table is a
      global variable called BMHTable of type TBMHTable.
  c)  Call FindString(MyString, MyFile) to search for MyString within the
      file MyFile.  FindString returns the offset position of MyString
      within MyFile if it is found; otherwise it returns -1.
  d)  Call DestroyBuffer to free the memory that Buffer points to.

Note that I only do (a) and (b) ONCE.  Once I search for a different
string, then I MUST do (b) again.  And (d) need only be called once
after ALL searching is completed.


NOTES:

- if you have ANY questions or problems, please feel free to contact me.
  E-mail: jodyc@cs.mun.ca

- the pattern searching is case-insensitive.  Case-sensitive searching
  is easy to implement.  Let me know if you need help.

- minimal error-checking is performed.  I would add more to suit your
  own particular needs.

- all the routines in this unit could be gathered into an object of
  some sort.  I may do that later.

- to search Read-Only files, you should set system.filemode := 0 before
  FindString is called; otherwise, FindString will fail.


This unit is FreeWare.  You may use it freely at your own risk.  Being
FreeWare, this unit is not to be sold at any charge, whether it is used
alone or incorporated into any program.

Please feel free to add any enhancements or modifications.  If you do,
just add your credits along with mine.  And I'd be interested in any
modifications you do make.  Any enhancement/modification must also be
released as Freeware.
}

{$Q-,I+,R-,S-,B-,V-,D-,L-}

interface

uses
  SysUtils;

const
  MaxBufferSize = 1024 * 63;  { Maximum size of buffer }

type
  TBMHTable = array[0..255] of byte;
  TSearchBuffer = ^TSearchBufferArray;
  TSearchBufferArray = array[1..MaxBufferSize] of char;

  function CreateBuffer: word;
  procedure DestroyBuffer;
  procedure MakeBMHTable (const StrToFind: string);
  function FindString (const StrToFind: string; const FileName: 
TFileName): longint;
  function GetStringOffset (StrToFind: string; const FileName: 
TFileName): longint;

var
  BMHTable: TBMHTable;    { Index table required for B-M-H algorithm }
  Buffer: TSearchBuffer;  { Buffer used when reading file }


implementation
{ NOTES:
  - I use no local variables within procedures and functions.  Local
    variables tend to slow execution too much for my taste, since
    most local variables have to be created on the system stack each
    time a function is called.
}

uses
   WinProcs, WinTypes, Dialogs;

var
  FileToSearch: file;  { file to search for given string }
  OldFileMode: byte;   { saves the file mode access code }
  K: integer;
  I,J,
  BytesRead,           { number of bytes read into buffer for blockread }
  OldErrorCode: word;  { saves Windows critical error-handling mode }


function GetError (const ErrorCode: integer): string;
{ Returns a string pertaining to the type of error.  ErrorCode can be
  taken from IOResult if IO-checking is off, or from an exception 
handler.
  The strings listed below are taken from Borland's 'Object Pascal
  Language Guide' for Delphi Version 1.0, pages 273-275.
}
begin
  case ErrorCode of
     2: Result := 'File not found.';
     3: Result := 'Path not found.';
     4: Result := 'Too many open files.';
     5: Result := 'File access denied.';
     6: Result := 'Invalid file handle.';
    12: Result := 'Invalid file access code.';
   100: Result := 'Disk read error.';
   101: Result := 'Disk write error.'
  else
    Result := ''
  end
end;


function DoBMHSearch(const StrToFind: string): longint;
{ Performs the Boyer-Moore-Horspool string searching algorithm, returning
  the offset in file where the string was found.  If not found, then
  -1 is returned.  Adapted from the 'Handbook of Algorithms and Data
  Structures in Pascal and C', Second Edition, by G.H Gonnet and
  R. Baeza-Yates.
  The index position within Buffer is returned if StrToFind is found
  within Buffer; otherwise, -1 is returned.
}
begin
  Result := -1;
  J := length(StrToFind);
  while (J <= BytesRead) do
    begin
      I := J;
      K := length(StrToFind);
      while (K >= 1) do
        if upcase(Buffer^[I]) <> StrToFind[K] then
          K := -1
        else
          begin
            dec (K);
            dec (I)
          end;
      if (K = 0) then
        begin
          Result := (BytesRead - I);
          exit
        end;
      inc(J,BMHTable[ord(upcase(Buffer^[J]))])
    end { while }
end;


procedure MakeBMHTable (const StrToFind: string);
{ Creates a Boyer-Moore-Horspool index table for the search string
  StrToFind in the table BMHTable.  This MUST be called before
  the string is searched for.  But it only needs to be called once
  for each different string.
}
  begin
    fillchar (BMHTable,sizeof(BMHTable),length(StrToFind));
    for K := 1 to length(StrToFind)-1 do
      BMHTable[ord(StrToFind[K])] := length(StrToFind)-K
  end;


function CreateBuffer: word;
{ Creates a buffer for the FindString function.  The buffer is
  divisable by 1024 because most disk clusters are divisible by
  1024, which makes for faster reads.  The size of the buffer created
  is returned.  Zero (0) is returned if the buffer was not created.
}
begin
  if MaxAvail >= MaxBufferSize then
    Result := MaxBufferSize
  else
    Result := (MaxAvail div 1024) * 1024;
  try { allocate memory }
    getmem (Buffer, Result)
  except
    Result := 0
  end { allocate memory }
end;

procedure DestroyBuffer;
{ Free the memory that Buffer points to }
begin
  freemem(Buffer,sizeof(Buffer^))
end;


function FindString (const StrToFind: string; const FileName: TFileName): 
longint;
{ Opens file to initiate Boyer-Moore-Horspool search algorithm, reading
  blocks of data from file until string is found or all bytes are read.
  The offset within FileName is returned if StrToFind is found; 
otherwise,
  -1 is returned.  Note that the offset is zero-based.  The first byte
  in a file is at offset 0.  The second byte is at offset 1.  Etc.
  **** BEFORE FUNCTION IS CALLED ****:
  1) a variable called Buffer of type TSearchBuffer MUST exist with a 
size
     greater than zero (0). NO error-checking is done on this.
  2) a variable called BMHTable of type TBMHTable must exist and be
     initialized for the string StrToFind using procedure MakeBMHTable.
}
begin
  Result := -1;
  assignfile (FileToSearch,FileName);
  try { to open file to search }
    reset(FileToSearch,1);
    try { searching for string }
      repeat
        blockread(FileToSearch,Buffer^,sizeof(Buffer^),BytesRead);
        { Search for string within buffer }
        Result := DoBMHSearch(StrToFind);
        { Calculate offset position in file if found }
        if Result <> -1 then
          Result := filepos(FileToSearch) - Result
        else
          { If Buffer is full, skip back length(StrToFind) bytes in file.
            This ensures any pattern isn't "cut-off" during readblock.
          }
          if BytesRead = sizeof(Buffer^) then
            seek(FileToSearch,filepos(FileToSearch)-length(StrToFind))
      until (BytesRead = 0) or (Result <> -1);
    finally
      closefile(FileToSearch)
    end; { searching for string }
  except
    on E: EInOutError do
      begin
        MessageDlg('Cannot scan ' + uppercase(FileName) + '.'#13 + 
GetError(E.ErrorCode),mterror,[mbOK],0);
        Result := -1
      end
  end { opening file to search }
end;


function GetStringOffset (StrToFind: string; const FileName: TFileName): 
longint;
{ This is for you lazy programmers.  This function does all 
initialization
  routines to find StrToFind within FileName.  If StrToFind is found, the
  offset location within FileName is returned; otherwise, -1 is returned,
  indicating an unsuccessful search.
}
begin
  { try to create buffer for blockread procedure }
  if CreateBuffer = 0 then
    begin
      MessageDlg('Not enough memory to perform 
search.',mtWarning,[mbOK],0);
      Result := -1;
      exit
    end;

  { Convert to uppercase for case-insensitive searching }
  StrToFind := uppercase(StrToFind);

  { This must be done for every string }
  MakeBMHTable(StrToFind);

  { Enable reading of read-only files }
  OldFileMode := system.filemode;
  system.filemode := 0;

  { Turn off critical windows handling }
  olderrorcode := SetErrorMode(SEM_FAILCRITICALERRORS);

  try { to search file for string }
    Result := FindString (StrToFind, FileName)
  finally { clean-up }
    DestroyBuffer;
    system.filemode := OldFileMode;
    SetErrorMode(OldErrorCode)
  end { searching }
end;

end. { bmh }



