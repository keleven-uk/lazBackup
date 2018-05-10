unit formBackup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, Menus, formAbout, formhelp, formOptions, formLicence, uOptions;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    mnuLicence   : TMenuItem;
    mnuItmOptions: TMenuItem;
    mnuItmHelp   : TMenuItem;
    mnuItmAbout  : TMenuItem;
    mnuItmExit   : TMenuItem;
    mnuhelp      : TMenuItem;
    mnuFile      : TMenuItem;
    mnuMain      : TMainMenu;
    stsBrInfo    : TStatusBar;
    Timer1       : TTimer;

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
  public
    noOfTicks : integer ;
  end; 

var
  frmMain     : TfrmMain;
  userOptions : Options;
  debugFle    : text;
  debug       : Boolean;
  appStartTime: int64;          //  used by formAbout to determine how long the app has been running.
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
    DebugFleName := 'lazbaCKUP.log';
    assignfile(debugFle, DebugFleName);
    rewrite(debugFle);
    writeLn(debugFle, format ('%s : %s Created', [timeToStr(now), DebugFleName]));
  end;

  userOptions := Options.Create;  // create options file as c:\Users\<user>\AppData\Local\lazbackup\Options.xml

  frmMain.Top := UserOptions.formTop;
  frmmain.Left := UserOptions.formLeft;
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

procedure TfrmMain.Timer1Timer(Sender: TObject);
begin
  stsBrInfo.Panels.Items[0].Text := TimeToStr(Time) ;
  stsBrInfo.Panels.Items[1].Text := FormatDateTime('DD MMM YYYY', Now);
end;

end.

