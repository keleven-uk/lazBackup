unit formhelp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

type

  { TfrmHelp }

  TfrmHelp = class(TForm)
    btnhelpExit : TButton;
    lblComments : TLabel;
    lblCopyRight: TLabel;
    lblVersion  : TLabel;
    mmoHelp     : TMemo;
    Panel1      : TPanel;
    Panel2      : TPanel;

    procedure btnhelpExitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmHelp : TfrmHelp;

implementation

uses
  formBackup;

{$R *.lfm}

{ TfrmHelp }

procedure TfrmHelp.FormCreate(Sender: TObject);
begin
  mmoHelp.Append('Stub.');
  mmoHelp.Append('');
  mmoHelp.Append('');

  try
    mmoHelp.Lines.LoadFromFile('help.txt');
  except
    on Exception do begin
      mmoHelp.Append(' help file not found.');
      mmoHelp.Append('');
      mmoHelp.Append(' This file should include full and detailed help intructions.');
    end;
  end;

  lblComments.Caption  := format('%s :: %s', [userOptions.productName,userOptions.Comments]);
  lblCopyRight.Caption := userOptions.legalCopyright;
  lblVersion.Caption   := format('%s Version :: %s', [userOptions.productName, userOptions.fileVersion]);
end;

procedure TfrmHelp.btnhelpExitClick(Sender: TObject);
begin
  Close;
end;


end.

