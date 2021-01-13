unit Apollo_DPM_ConflictForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Apollo_DPM_ConflictFrame,
  Apollo_DPM_Types;

type
  TConflictForm = class(TForm)
    btnApply: TButton;
    btnCancel: TButton;
    sbVersionConflicts: TScrollBox;
    lblCaption: TLabel;
    pnlHeader: TPanel;
    lblValidationMsg: TLabel;
    procedure btnApplyClick(Sender: TObject);
  private
    FFrames: TArray<TConflictFrame>;
    function IsValid: Boolean;
    procedure RenderVersionConflict(const aVersionConflict: TVersionConflict; const aIndex: Integer);
    procedure RenderVersionConflicts(const aVersionConflicts: TVersionConflicts);
  public
    function GetResult: TVersionConflicts;
    constructor Create(const aCaption: string; aOwner: TComponent;
      const aVersionConflicts: TVersionConflicts); reintroduce;
  end;

implementation

{$R *.dfm}

uses
  Apollo_DPM_Consts,
  Apollo_DPM_Validation;

{ TConflictForm }

procedure TConflictForm.btnApplyClick(Sender: TObject);
begin
  if IsValid then
    ModalResult := mrOk;
end;

constructor TConflictForm.Create(const aCaption: string; aOwner: TComponent;
  const aVersionConflicts: TVersionConflicts);
begin
  inherited Create(aOwner);

  Caption := aCaption;
  RenderVersionConflicts(aVersionConflicts);
end;

function TConflictForm.GetResult: TVersionConflicts;
var
  ConflictFrame: TConflictFrame;
begin
  Result := [];

  for ConflictFrame in FFrames do
    Result := Result + [ConflictFrame.GetVersionConflictWithSelection];
end;

function TConflictForm.IsValid: Boolean;
var
  ConflictFrame: TConflictFrame;
begin
  Result := True;
  Validation.SetOutputLabel(lblValidationMsg);
  Validation.Start(Self);

  for ConflictFrame in FFrames do
  begin
    Validation.Assert(True, ConflictFrame, ConflictFrame.GetSelection <> nil,
      cStrVersionNotSelected, Result);
  end;
end;

procedure TConflictForm.RenderVersionConflict(
  const aVersionConflict: TVersionConflict; const aIndex: Integer);
var
  ConflictFrame: TConflictFrame;
begin
  ConflictFrame := TConflictFrame.Create(sbVersionConflicts, aIndex);
  ConflictFrame.RenderVersionConflict(aVersionConflict);

  FFrames := FFrames + [ConflictFrame];
end;

procedure TConflictForm.RenderVersionConflicts(const aVersionConflicts: TVersionConflicts);
var
  i: Integer;
begin
  FFrames := [];
  for i := 0 to Length(aVersionConflicts) - 1 do
    RenderVersionConflict(aVersionConflicts[i], i);
end;

end.
