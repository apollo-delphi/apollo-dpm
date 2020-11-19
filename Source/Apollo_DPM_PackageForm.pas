unit Apollo_DPM_PackageForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Apollo_DPM_Package;

type
  TPackageForm = class(TForm)
    rbPrivate: TRadioButton;
    grpVisibility: TGroupBox;
    leName: TLabeledEdit;
    btnOk: TButton;
    btnCancel: TButton;
    rbPublic: TRadioButton;
    lblValidationMsg: TLabel;
    procedure btnOkClick(Sender: TObject);
  private
    FPackage: TPackage;
    function AreControlsValid: Boolean;
    procedure ReadFromControls;
    procedure WriteToControls;
  public
    constructor Create(aOwner: TComponent; aPackage: TPackage); reintroduce;
  end;

var
  PackageForm: TPackageForm;

implementation

{$R *.dfm}

uses
  Apollo_DPM_Consts,
  Apollo_DPM_UIHelper;

{ TPackageForm }

function TPackageForm.AreControlsValid: Boolean;
begin
  Result := True;
  ControlValidation(leName, leName.Text <> '', cStrTheFieldCannotBeEmpty, lblValidationMsg, Result);
end;

procedure TPackageForm.btnOkClick(Sender: TObject);
begin
  if AreControlsValid then
  begin
    ReadFromControls;
    ModalResult := mrOk;
  end;
end;

constructor TPackageForm.Create(aOwner: TComponent; aPackage: TPackage);
begin
  inherited Create(aOwner);

  FPackage := aPackage;

  WriteToControls;
end;

procedure TPackageForm.ReadFromControls;
begin
  FPackage.Name := leName.Text;
end;

procedure TPackageForm.WriteToControls;
begin
  case FPackage.Visibility of
    vPrivate: rbPrivate.Checked := True;
    vPublic: rbPublic.Checked := True;
  end;
end;

end.
