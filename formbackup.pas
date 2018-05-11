unit formBackup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, Menus, EditBtn, StdCtrls, formAbout, formhelp, formOptions,
  formLicence, uOptions, windows;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    lblDeleteFiles: TLabel;
    Panel1              : TPanel;
    Bevel1              : TBevel;
    Bevel2              : TBevel;
    Bevel3              : TBevel;
    Bevel4              : TBevel;
    btnAnalyse          : TButton;
    btnCopy             : TButton;
    drctryEdtStub       : TDirectoryEdit;
    drctryEdtSource     : TDirectoryEdit;
    DrctryEdtDestination: TDirectoryEdit;
    Label1              : TLabel;
    Label2              : TLabel;
    lblDestination      : TLabel;
    lblSource           : TLabel;
    lblNewFiles         : TLabel;
    lstBxSource         : TListBox;
    lstBxDifferance     : TListBox;
    lstBxDestination    : TListBox;
    mnuLicence          : TMenuItem;
    mnuItmOptions       : TMenuItem;
    mnuItmHelp          : TMenuItem;
    mnuItmAbout         : TMenuItem;
    mnuItmExit          : TMenuItem;
    mnuhelp             : TMenuItem;
    mnuFile             : TMenuItem;
    mnuMain             : TMainMenu;
    PrgrssBrAnalyse     : TProgressBar;
    stsBrInfo           : TStatusBar;
    Timer1              : TTimer;

    procedure btnAnalyseClick(Sender: TObject);
    procedure DrctryEdtDestinationChange(Sender: TObject);
    procedure drctryEdtSourceChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure mnuItmAboutClick(Sender: TObject);
    procedure mnuItmExitClick(Sender: TObject);
    procedure mnuItmHelpClick(Sender: TObject);
    procedure mnuItmOptionsClick(Sender: TObject);
    procedure mnuLicenceClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
    procedure walkDirectory(dir: string; mode: string);
    procedure destinationFileFound(FileIterator: TFileIterator);
    procedure sourceFileFound(FileIterator: TFileIterator);
    procedure directoryFound(FileIterator: TFileIterator);
    procedure FindSourceFiles();
    procedure FindDestinationFiles();
    function fileSizeToHumanReadableString(fileSize: Int64): string;
  public
    noOfTicks : integer ;
  end; 

var
  frmMain     : TfrmMain;
  userOptions : Options;
  debugFle    : text;
  debug       : Boolean;
  appStartTime: int64;          //  used by formAbout to determine how long the app has been running.
  filesSize   : int64;          //  used to hold the total size of all files.
  noOfFiles   : longint;        //  used to hold the total number of files.
  noOfDirs    : longint;        //  used to hold the total number of directories
  source      : boolean;        //  true if source files been walked.
  destination : boolean;        //  true if destination files have been walked.

const
  OneKB = Int64(1024);          //  constants used in TfrmMain.FileSizeToHumanReadableString
  OneMB = Int64(1024) * OneKB;
  OneGB = Int64(1024) * OneMB;
  OneTB = Int64(1024) * OneGB;
  OnePB = Int64(1024) * OneTB;
  fmt = '#.###';

implementation

{$R *.lfm}

{ TfrmMain }


procedure TfrmMain.FormCreate(Sender: TObject);
VAR
  DebugFleName : String;
begin
  appStartTime := GetTickCount64;  //  tick count when application starts.
  debug := true ;

  if debug then begin
    DebugFleName := 'lazBackup.log';
    assignfile(debugFle, DebugFleName);
    rewrite(debugFle);
    writeLn(debugFle, format ('%s : %s Created', [timeToStr(now), DebugFleName]));
  end;

  userOptions := Options.Create;  // create options file as c:\Users\<user>\AppData\Local\lazbackup\Options.xml

  frmMain.Top  := UserOptions.formTop;
  frmmain.Left := UserOptions.formLeft;

  source      := false;
  destination := false;
end;


procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if debug then begin
    writeLn(debugFle, format ('%s : log file Closed', [timeToStr(now)]));
    CloseFile(debugFle);
  end;

   UserOptions.formTop := frmMain.Top;
   UserOptions.formLeft := frmmain.Left;

  userOptions.writeCurrentOptions;  // write out options file.
end;
//
// ****************************** Directory Edits ******************************
//
procedure TfrmMain.drctryEdtSourceChange(Sender: TObject);
begin
  walkDirectory(drctryEdtSource.Directory, 'S');
end;

procedure TfrmMain.DrctryEdtDestinationChange(Sender: TObject);
begin
  walkDirectory(drctryEdtDestination.Directory, 'D');
end;
//
// ****************************** Menu Items ***********************************
//
procedure TfrmMain.mnuItmAboutClick(Sender: TObject);
begin
  frmAbout.ShowModal;
end;

procedure TfrmMain.mnuItmExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.mnuItmHelpClick(Sender: TObject);
begin
  frmhelp.ShowModal;
end;

procedure TfrmMain.mnuItmOptionsClick(Sender: TObject);
begin
  frmOptions.ShowModal;
end;

procedure TfrmMain.mnuLicenceClick(Sender: TObject);
begin
  frmLicence.Show;
end;
//
// ****************************** Timer ****************************************
//
procedure TfrmMain.Timer1Timer(Sender: TObject);
begin
  stsBrInfo.Panels.Items[0].Text := TimeToStr(Time) ;
  stsBrInfo.Panels.Items[1].Text := FormatDateTime('DD MMM YYYY', Now);
end;
//
// ****************************** Analyse **************************************
//
procedure TfrmMain.btnAnalyseClick(Sender: TObject);

begin
  btnAnalyse.Enabled := false;

  FindSourceFiles;
  FindDestinationFiles;

  PrgrssBrAnalyse.Position := 0;
  Label2.Enabled           := true;
end;

procedure TfrmMain.FindSourceFiles();
VAR
  f       : integer;
  srcFile : string;
  indpos  : integer;
  newFiles: integer;
begin
  newFiles := 0;

  PrgrssBrAnalyse.min      := 0;
  PrgrssBrAnalyse.Max      := lstBxSource.Count;
  PrgrssBrAnalyse.Position := 0;

  for f := 0 to lstBxSource.Count -1 do
  begin
    // process all user events, like clicking on the button
    Application.ProcessMessages;
    if Application.Terminated then close;  //  exit clicked


    srcFile := drctryEdtStub.Directory.ToLower + '\' + lstBxSource.Items.Strings[f].Replace(':', '');
    indpos  := lstBxDestination.Items.IndexOf(srcFile);

    if indpos = -1 then
    begin
      lstBxDifferance.Items.Add('NEW : ' + lstBxSource.Items.Strings[f]);
      newFiles += 1;
      lblNewFiles.Caption := format('%d NEW files', [newFiles]);;
    end;  //  if indpos = -1 then

    PrgrssBrAnalyse.Position := PrgrssBrAnalyse.Position + 1;
  end;    //  for f := 0 to lstBxSource.Count -1 do

end;

procedure TfrmMain.FindDestinationFiles();
VAR
  f       : integer;
  dstFile : string;
  indpos  : integer;
  delFiles: integer;
  dstlen  : integer;
begin
  delFiles := 0;

  PrgrssBrAnalyse.min      := 0;
  PrgrssBrAnalyse.Max      := lstBxDestination.Count;
  PrgrssBrAnalyse.Position := 0;

  for f := 0 to lstBxDestination.Count -1 do
  begin
    // process all user events, like clicking on the button
    Application.ProcessMessages;
    if Application.Terminated then close;  //  exit clicked

    dstFile := lstBxDestination.Items.Strings[f];
    dstlen  :=  length(drctryEdtStub.Directory.ToLower ) + 1;
    delete(dstFile, 1, dstlen);                          //  Must remember, string start at position 1.
    Insert(':', dstFile, 2);                             //  Insert the : we removed earlier.
    indpos := lstBxsource.Items.IndexOf(dstFile);

    if indpos = -1 then
    begin
      lstBxDifferance.Items.Add('DELETE : ' + dstFile);
      delFiles += 1;
      lblDeleteFiles.Caption := format('%d DELETE files', [delFiles]);;
    end;  //  if indpos = -1 then

    PrgrssBrAnalyse.Position := PrgrssBrAnalyse.Position + 1;
  end;    //  for f := 0 to lstBxDestination.Count -1 do

end;
//
// ****************************** Walk Directory *******************************
//
procedure TfrmMain.walkDirectory(dir: string; mode: string);
{  Walk a directory passed into procedure.
   Does not check if directory exists.
}
VAR
  fileSearch  : TFileSearcher;
begin
  filesSize := 0;
  noOfFiles := 0;
  noOfDirs  := 0;

  //  actual search
  fileSearch := TFileSearcher.Create;
  if mode = 'S' then
    fileSearch.OnFileFound := @sourceFileFound
  else
    fileSearch.OnFileFound := @destinationFileFound;
  fileSearch.OnDirectoryFound := @directoryFound;
  fileSearch.Search(dir, '*.*', True);
  fileSearch.Free;
  //  search finished.

  if mode = 'S' then
    source := true                //  Source has been walked.
  else
    destination := true;          //  Destination has been walked.

  if source and destination then  //  Only enable Analyse button if both
    begin                         //  source and destination have been walked.
      btnAnalyse.Enabled := true;
      Label1.Enabled     := true;

      drctryEdtSource.Enabled      := false;
      DrctryEdtDestination.Enabled := false;
      drctryEdtStub.Enabled        := false;
    end;

end;

procedure TfrmMain.sourceFileFound(FileIterator: TFileIterator);
begin
  // process all user events, like clicking on the button
  Application.ProcessMessages;
  if Application.Terminated then close;  //  exit clicked

  noOfFiles += 1;
  filesSize := filesSize + FileIterator.FileInfo.Size ;

  lstBxSource.Items.Add(FileIterator.FileName.ToLower);

  lblSource.Caption := format('%d files [%s bytes]   %d directories',
               [noOfFiles, FileSizeToHumanReadableString(filesSize), noOfDirs]);
end;

procedure TfrmMain.destinationFileFound(FileIterator: TFileIterator);
begin
  // process all user events, like clicking on the button
  Application.ProcessMessages;
  if Application.Terminated then close;  //  exit clicked

  noOfFiles += 1;
  filesSize := filesSize + FileIterator.FileInfo.Size ;

  lstBxDestination.Items.Add(FileIterator.FileName.ToLower);

  lblDestination.Caption := format('%d files [%s bytes]   %d directories',
               [noOfFiles, FileSizeToHumanReadableString(filesSize), noOfDirs]);
end;

procedure TfrmMain.directoryFound(FileIterator: TFileIterator);
begin
  noOfDirs += 1;
end;

function TfrmMain.fileSizeToHumanReadableString(fileSize: Int64): string;
{  Returns filesize in a human readable form.
   Does not use ther silly ISO standard unit of Pib, TiB, GiB, MiB & KiB.
   Used the gold old fashion units of Pib, TB, GB, MB & KB.
}

begin
  if fileSize > OnePB then
    result := FormatFloat(fmt + 'PB', fileSize / OnePB)
  else
    if fileSize > OneTB then
      result := FormatFloat(fmt + 'TB', fileSize / OneTB)
    else
      if fileSize > OneGB then
        result := FormatFloat(fmt + 'GB', fileSize / OneGB)
      else
        if fileSize > OneMB then
          result := FormatFloat(fmt + 'MB', fileSize / OneMB)
        else
          if fileSize > OneKB then
            result := FormatFloat(fmt + 'KB', fileSize / OneKB)
          else
            if fileSize > 0 then
              result := FormatFloat(fmt + 'bytes', fileSize)
            else
              result := ''

end;

end.

