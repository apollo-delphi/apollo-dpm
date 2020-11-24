unit Apollo_DPM_UIHelper;

interface

uses
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls;

type
  TFormHelper = class helper for TForm
    procedure ControlValidation(aControl: TWinControl; const aStatement: Boolean;
      var aErrorMsg: string; aErrorMsgLabel: TLabel; var aResult: Boolean);
  end;

implementation

uses
  Vcl.ExtCtrls,
  Vcl.Graphics;

{ TFormHelper }

procedure TFormHelper.ControlValidation(aControl: TWinControl;
  const aStatement: Boolean; var aErrorMsg: string; aErrorMsgLabel: TLabel;
  var aResult: Boolean);
begin
  if not aResult then
    Exit;

  aErrorMsgLabel.Visible := False;
  aErrorMsgLabel.Caption := '';

  if aControl is TLabeledEdit then
    TLabeledEdit(aControl).Color := clWindow;

  if not aStatement then
  begin
    aErrorMsgLabel.Caption := aErrorMsg;
    aErrorMsgLabel.Visible := True;

    aResult := False;

    if aControl is TLabeledEdit then
      TLabeledEdit(aControl).Color := clRed;
  end;
end;

end.
