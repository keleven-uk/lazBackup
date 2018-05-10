unit formOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, INIFiles;

type

  { TfrmOptions }

  TfrmOptions = class(TForm)
    btnExit: TButton;
    Panel1 : TPanel;
    Panel2 : TPanel;

    procedure btnExitClick(Sender: TObject);
  private

  public
    { public declarations }
  end; 

var
  frmOptions : TfrmOptions;


implementation

{$R *.lfm}

{ TfrmOptions }

procedure TfrmOptions.btnExitClick(Sender: TObject);
begin
  Close;
end;


end.

