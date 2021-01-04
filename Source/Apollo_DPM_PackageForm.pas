unit Apollo_DPM_PackageForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  System.Actions, Vcl.ActnList, Vcl.WinXCtrls, System.ImageList, Vcl.ImgList,
  Vcl.ComCtrls,
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
    aiRepoDataLoad: TActivityIndicator;
    leDescription: TLabeledEdit;
    pcAdjustment: TPageControl;
    tsFilterList: TTabSheet;
    tsPathMoves: TTabSheet;
    lbFilterList: TListBox;
    btnNewFilterLine: TSpeedButton;
    btnDeleteFilterLine: TSpeedButton;
    cbFilterListType: TComboBox;
    lblFilterListType: TLabel;
    btnEditFilterLine: TSpeedButton;
    alActions: TActionList;
    ilIcons: TImageList;
    actGoToURL: TAction;
    actNewFilterLine: TAction;
    actEditFilterLine: TAction;
    actDeleteFilterLine: TAction;
    btnNewPathMove: TSpeedButton;
    btnDeletePathMove: TSpeedButton;
    btnEditPathMove: TSpeedButton;
    lvPathMoves: TListView;
    actNewPathMove: TAction;
    actEditPathMove: TAction;
    actDeletePathMove: TAction;
    procedure btnOkClick(Sender: TObject);
    procedure cbFilterListTypeChange(Sender: TObject);
    procedure lbFilterListClick(Sender: TObject);
    procedure actGoToURLExecute(Sender: TObject);
    procedure actNewFilterLineExecute(Sender: TObject);
    procedure actEditFilterLineExecute(Sender: TObject);
    procedure actDeleteFilterLineExecute(Sender: TObject);
    procedure actNewPathMoveExecute(Sender: TObject);
    procedure lvPathMovesClick(Sender: TObject);
    procedure actEditPathMoveExecute(Sender: TObject);
    procedure actDeletePathMoveExecute(Sender: TObject);
  private
    FDPMEngine: TDPMEngine;
    FPackage: TInitialPackage;
    FRepoDataLoadError: string;
    function GetSelectedVisibility: TVisibility;
    function IsValid(const aValidationGroupName: string): Boolean;
    procedure FilterListItemSelected;
    procedure FilterListTypeChanged(const aFilterListType: TFilterListType);
    procedure PathMoveSelected;
    procedure ReadFromControls;
    procedure RenderPathMoveItem(const aSource, aDestination: string);
    procedure WriteToControls;
  public
    constructor Create(aDPMEngine: TDPMEngine; aPackage: TInitialPackage); reintroduce;
  end;

var
  PackageForm: TPackageForm;

implementation

{$R *.dfm}

uses
  Apollo_DPM_Consts,
  Apollo_DPM_EditItemForm,
  Apollo_DPM_Form,
  Apollo_DPM_UIHelper;

const
  cLoadRepoDataValidation = 'LoadRepoDataValidation';
  cOKClickValidation = 'OKClickValidation';

  cFilterListTypeNames: array [TFilterListType] of string = (
    'None',
    'Black List',
    'White List'
  );

  cPathOnGitHub = 'Path on GitHub';
  cSource = 'Source';
  cDestination = 'Destination';

{ TPackageForm }

procedure TPackageForm.actDeleteFilterLineExecute(Sender: TObject);
begin
  if MessageDlg('The filter line will be deleted. Continue?', mtConfirmation,
    [mbYes, mbCancel], 0) = mrYes
  then
  begin
    lbFilterList.Items.Delete(lbFilterList.ItemIndex);
    FilterListItemSelected;
  end;
end;

procedure TPackageForm.actDeletePathMoveExecute(Sender: TObject);
begin
  if MessageDlg('The path moving will be deleted. Continue?', mtConfirmation,
    [mbYes, mbCancel], 0) = mrYes
  then
  begin
    lvPathMoves.Selected.Delete;
    PathMoveSelected;
  end;
end;

procedure TPackageForm.actEditFilterLineExecute(Sender: TObject);
var
  OutItems: TEditItems;
begin
  if TItemEditForm.Open(Self, 'Edit Filter Line',
    [TEditItem.Create(cPathOnGitHub, lbFilterList.Items[lbFilterList.ItemIndex])], OutItems)
  then
  begin
    lbFilterList.Items[lbFilterList.ItemIndex] := OutItems.ValueByKey(cPathOnGitHub);
  end;
end;

procedure TPackageForm.actEditPathMoveExecute(Sender: TObject);
var
  OutItems: TEditItems;
begin
  if TItemEditForm.Open(Self, 'Edit Path Moving', [
    TEditItem.Create(cSource, lvPathMoves.Selected.Caption),
    TEditItem.Create(cDestination, lvPathMoves.Selected.SubItems[0])
  ], OutItems)
  then
  begin
    lvPathMoves.Selected.Caption := OutItems.ValueByKey(cSource);
    lvPathMoves.Selected.SubItems[0] := OutItems.ValueByKey(cDestination);
  end;
end;

procedure TPackageForm.actGoToURLExecute(Sender: TObject);
var
  IsSuccess: Boolean;
  RepoOwner: string;
  RepoName: string;
begin
  btnGoToURL.Enabled := False;

  AsyncLoad(aiRepoDataLoad,
    procedure()
    begin
      IsSuccess := FDPMEngine.LoadRepoData(leURL.Text, RepoOwner, RepoName, FRepoDataLoadError)
    end,
    procedure()
    begin
      if IsSuccess then
      begin
        leURL.Text := '';
        leRepoOwner.Text := RepoOwner;
        leRepoName.Text := RepoName;
      end;

      IsValid(cLoadRepoDataValidation);
      btnGoToURL.Enabled := True;
    end
  );
end;

procedure TPackageForm.actNewFilterLineExecute(Sender: TObject);
var
  OutItems: TEditItems;
begin
  if TItemEditForm.Open(Self, 'New Filter Line', [TEditItem.Create(cPathOnGitHub, '')], OutItems) then
  begin
    lbFilterList.Items.Add(OutItems.ValueByKey(cPathOnGitHub));
  end;
end;

procedure TPackageForm.actNewPathMoveExecute(Sender: TObject);
var
  OutItems: TEditItems;
begin
  if TItemEditForm.Open(Self, 'New Path Moving', [
    TEditItem.Create(cSource, ''),
    TEditItem.Create(cDestination, '')
  ], OutItems)
  then
    RenderPathMoveItem(OutItems.ValueByKey(cSource), OutItems.ValueByKey(cDestination));
end;

procedure TPackageForm.btnOkClick(Sender: TObject);
begin
  if IsValid(cOKClickValidation) then
  begin
    ReadFromControls;
    ModalResult := mrOk;
  end;
end;

procedure TPackageForm.cbFilterListTypeChange(Sender: TObject);
begin
  FilterListTypeChanged(TFilterListType(cbFilterListType.ItemIndex));
end;

constructor TPackageForm.Create(aDPMEngine: TDPMEngine; aPackage: TInitialPackage);
var
  i: Integer;
begin
  inherited Create(DPMForm);

  FDPMEngine := aDPMEngine;
  FPackage := aPackage;

  for i := 0 to Length(cFilterListTypeNames) - 1 do
    cbFilterListType.Items.Add(cFilterListTypeNames[TFilterListType(i)]);

  WriteToControls;
end;

procedure TPackageForm.FilterListItemSelected;
var
  Enable: Boolean;
begin
  if lbFilterList.Enabled and (lbFilterList.ItemIndex > -1) then
    Enable := True
  else
    Enable := False;

  SetControlsEnable(Enable, [
    btnEditFilterLine,
    btnDeleteFilterLine
  ]);
end;

procedure TPackageForm.FilterListTypeChanged(
  const aFilterListType: TFilterListType);
var
  Enable: Boolean;
begin
  if aFilterListType = fltNone then
  begin
    lbFilterList.ItemIndex := -1;
    Enable := False
  end
  else
    Enable := True;

  SetControlsEnable(Enable, [
    btnNewFilterLine,
    lbFilterList
  ]);

  FilterListItemSelected;
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
  Result := True;
  Validation.SetOutputLabel(lblValidationMsg);
  Validation.Start(Self);

  Validation.Assert(aValidationGroupName = cLoadRepoDataValidation, leURL,
    FRepoDataLoadError = '', FRepoDataLoadError, Result);

  Validation.Assert(aValidationGroupName = cOKClickValidation, leRepoName,
    leRepoName.Text <> '', cStrARepositoryNameIsEmpty, Result);

  Validation.Assert(aValidationGroupName = cOKClickValidation, leName,
    leName.Text <> '', cStrTheFieldCannotBeEmpty, Result);

  Validation.Assert(aValidationGroupName = cOKClickValidation, leName,
    Validation.ValidatePackageNameUniq(FPackage.ID, leName.Text, GetSelectedVisibility),
    cStrAPackageWithThisNameAlreadyExists, Result);
end;

procedure TPackageForm.lbFilterListClick(Sender: TObject);
begin
  FilterListItemSelected;
end;

procedure TPackageForm.lvPathMovesClick(Sender: TObject);
begin
  PathMoveSelected;
end;

procedure TPackageForm.PathMoveSelected;
var
  Enable: Boolean;
begin
  if lvPathMoves.Selected <> nil then
    Enable := True
  else
    Enable := False;

  SetControlsEnable(Enable, [
    btnEditPathMove,
    btnDeletePathMove
  ]);
end;

procedure TPackageForm.ReadFromControls;
var
  i: Integer;
  PathMove: TPathMove;
begin
  FPackage.Name := leName.Text;
  FPackage.Description := leDescription.Text;
  FPackage.RepoOwner := leRepoOwner.Text;
  FPackage.RepoName := leRepoName.Text;

  FPackage.FilterListType := TFilterListType(cbFilterListType.ItemIndex);

  FPackage.FilterList := [];
  for i := 0 to lbFilterList.Items.Count - 1 do
    FPackage.FilterList := FPackage.FilterList + [lbFilterList.Items[i]];

  FPackage.PathMoves := [];
  for i := 0 to lvPathMoves.Items.Count - 1 do
  begin
    PathMove.Source := lvPathMoves.Items[i].Caption;
    PathMove.Destination := lvPathMoves.Items[i].SubItems[0];
    FPackage.PathMoves := FPackage.PathMoves + [PathMove];
  end;
end;

procedure TPackageForm.RenderPathMoveItem(const aSource, aDestination: string);
var
  lvItem: TListItem;
begin
  lvItem := lvPathMoves.Items.Add;
  lvItem.Caption := aSource;
  lvItem.SubItems.Add(aDestination);
end;

procedure TPackageForm.WriteToControls;
var
  FilterItem: string;
  PathMove: TPathMove;
begin
  case FPackage.Visibility of
    vPrivate: rbPrivate.Checked := True;
    vPublic: rbPublic.Checked := True;
  end;

  leName.Text := FPackage.Name;
  leDescription.Text := FPackage.Description;
  leRepoOwner.Text := FPackage.RepoOwner;
  leRepoName.Text := FPackage.RepoName;

  cbFilterListType.ItemIndex := Ord(FPackage.FilterListType);
  FilterListTypeChanged(FPackage.FilterListType);

  for FilterItem in FPackage.FilterList do
    lbFilterList.Items.Add(FilterItem);

  for PathMove in FPackage.PathMoves do
    RenderPathMoveItem(PathMove.Source, PathMove.Destination);
  PathMoveSelected;
end;

end.
