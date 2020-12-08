unit Apollo_DPM_PackageForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  System.Actions, Vcl.ActnList, Vcl.WinXCtrls, System.ImageList, Vcl.ImgList,
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  Apollo_DPM_Validation;

type
  TPackageForm = class(TForm)
    rbPrivate: TRadioButton;
    grpVisibility: TGroupBox;
    leName: TLabeledEdit;
    btnOk: TButton;
    btnCancel: TButton;
    rbPublic: TRadioButton;
    lblValidationMsg: TLabel;
    grpGitHub: TGroupBox;
    leURL: TLabeledEdit;
    leRepoOwner: TLabeledEdit;
    leRepoName: TLabeledEdit;
    btnGoToURL: TSpeedButton;
    alActions: TActionList;
    actGoToURL: TAction;
    aiRepoDataLoad: TActivityIndicator;
    ilIcons: TImageList;
    procedure btnOkClick(Sender: TObject);
    procedure actGoToURLExecute(Sender: TObject);
  private
    FDPMEngine: TDPMEngine;
    FPackage: TPackage;
    FRepoDataLoadError: string;
    function GetSelectedVisibility: TVisibility;
    function IsValid(const aValidationGroupName: string): Boolean;
    procedure ReadFromControls;
    procedure WriteToControls;
  public
    constructor Create(aDPMEngine: TDPMEngine; aPackage: TPackage); reintroduce;
  end;

var
  PackageForm: TPackageForm;

implementation

{$R *.dfm}

uses
  Apollo_DPM_Consts,
  Apollo_DPM_Form,
  Apollo_DPM_UIHelper;

const
  cLoadRepoDataValidation = 'LoadRepoDataValidation';
  cOKClickValidation = 'OKClickValidation';

{ TPackageForm }

procedure TPackageForm.actGoToURLExecute(Sender: TObject);
var
  IsSuccess: Boolean;
  RepoOwner: string;
  RepoName: string;
begin
  AsyncLoad(aiRepoDataLoad,
    procedure()
    begin
      actGoToURL.Enabled := False;

      IsSuccess := FDPMEngine.LoadRepoData(leURL.Text, RepoOwner, RepoName, FRepoDataLoadError);
    end,
    procedure()
    begin
      if IsSuccess then
      begin
        leURL.Text := '';
        leRepoOwner.Text := RepoOwner;
        leRepoName.Text := RepoName;
      end;

      actGoToURL.Enabled := True;
      IsValid(cLoadRepoDataValidation);
    end
  );
end;

procedure TPackageForm.btnOkClick(Sender: TObject);
begin
  if IsValid(cOKClickValidation) then
  begin
    ReadFromControls;
    ModalResult := mrOk;
  end;
end;

constructor TPackageForm.Create(aDPMEngine: TDPMEngine; aPackage: TPackage);
begin
  inherited Create(DPMForm);

  FDPMEngine := aDPMEngine;
  FPackage := aPackage;

  WriteToControls;
end;

function TPackageForm.GetSelectedVisibility: TVisibility;
begin
  if rbPrivate.Checked then
    Result := vPrivate
  else
    Result := vPublic;
end;

function TPackageForm.IsValid(const aValidationGroupName: string): Boolean;
begin
  Validation.SetOutputLabel(lblValidationMsg);
  Result := True;

  Validation.Assert(aValidationGroupName = cLoadRepoDataValidation, leURL,
    FRepoDataLoadError = '', FRepoDataLoadError, Result);

  Validation.Assert(aValidationGroupName = cOKClickValidation, leRepoName,
    leRepoName.Text <> '', cStrARepositoryNameIsEmpty, Result);

  Validation.Assert(aValidationGroupName = cOKClickValidation, leName,
    leName.Text <> '', cStrTheFieldCannotBeEmpty, Result);

  Validation.Assert(aValidationGroupName = cOKClickValidation, leName,
    Validation.ValidatePackageNameUniq(leName.Text, GetSelectedVisibility),
    cStrAPackageWithThisNameAlreadyExists, Result);
end;

procedure TPackageForm.ReadFromControls;
begin
  FPackage.Name := leName.Text;
  FPackage.RepoOwner := leRepoOwner.Text;
  FPackage.RepoName := leRepoName.Text;
end;

procedure TPackageForm.WriteToControls;
begin
  case FPackage.Visibility of
    vPrivate: rbPrivate.Checked := True;
    vPublic: rbPublic.Checked := True;
  end;

  leName.Text := FPackage.Name;
end;

end.
