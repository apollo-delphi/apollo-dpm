unit Apollo_DPM_PackageForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  System.Actions, Vcl.ActnList, Vcl.WinXCtrls, System.ImageList, Vcl.ImgList,
  Vcl.ComCtrls,
  Apollo_DPM_EditItemForm,
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  Apollo_DPM_Validation;

type
  TPackageForm = class(TForm)
    rbPrivate: TRadioButton;
    grpVisibility: TGroupBox;
    leName: TLabeledEdit;
    btnApply: TButton;
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
    cbPackageType: TComboBox;
    lblPackageType: TLabel;
    tsBpl: TTabSheet;
    lbBplProjects: TListBox;
    lbBplBinaries: TListBox;
    btnNewBplBinFile: TSpeedButton;
    btnEditBplBinFile: TSpeedButton;
    btnDeleteBplBinFile: TSpeedButton;
    btnNewBplPrjFile: TSpeedButton;
    btnEditBplPrjFile: TSpeedButton;
    btnDeleteBplPrjFile: TSpeedButton;
    lblBplProjectRefs: TLabel;
    lblBplBinaries: TLabel;
    actNewBplPrjFile: TAction;
    actEditBplPrjFile: TAction;
    actDeleteBplPrjFile: TAction;
    actNewBplBinFile: TAction;
    actEditBplBinFile: TAction;
    actDeleteBplBinFile: TAction;
    tsProjectOptions: TTabSheet;
    rbAddAllUnits: TRadioButton;
    rbAddNothing: TRadioButton;
    rbAddSpecified: TRadioButton;
    chkAddSearchPath: TCheckBox;
    lbAddingUnitRefs: TListBox;
    btnNewAddingUnit: TSpeedButton;
    btnEditAddingUnit: TSpeedButton;
    btnDeleteAddingUnit: TSpeedButton;
    actNewAddingUnit: TAction;
    actEditAddingUnit: TAction;
    actDeleteAddingUnit: TAction;
    procedure btnApplyClick(Sender: TObject);
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
    procedure cbPackageTypeChange(Sender: TObject);
    procedure actNewBplPrjFileExecute(Sender: TObject);
    procedure lbBplProjectsClick(Sender: TObject);
    procedure actEditBplPrjFileExecute(Sender: TObject);
    procedure actDeleteBplPrjFileExecute(Sender: TObject);
    procedure lbBplBinariesClick(Sender: TObject);
    procedure actNewBplBinFileExecute(Sender: TObject);
    procedure actEditBplBinFileExecute(Sender: TObject);
    procedure actDeleteBplBinFileExecute(Sender: TObject);
    procedure rbAddAllUnitsClick(Sender: TObject);
    procedure rbAddSpecifiedClick(Sender: TObject);
    procedure rbAddNothingClick(Sender: TObject);
    procedure actNewAddingUnitExecute(Sender: TObject);
    procedure actEditAddingUnitExecute(Sender: TObject);
    procedure lbAddingUnitRefsClick(Sender: TObject);
    procedure actDeleteAddingUnitExecute(Sender: TObject);
  private
    FDPMEngine: TDPMEngine;
    FPackage: TInitialPackage;
    FRepoDataLoadError: string;
    function GetRepoRelativePath: string;
    function GetSelectedPackageType: TPackageType;
    function GetSelectedVisibility: TVisibility;
    function GetPackageRelativePath: string;
    function IsBplPkgValid(const aOutItems: TEditItems; aOutput: TLabel): Boolean;
    function IsBplPrjValid(const aOutItems: TEditItems; aOutput: TLabel): Boolean;
    function IsValid(const aValidationGroupName: string): Boolean;
    procedure AddingUnitSelected;
    procedure AddUnitsOptionChanged(Sender: TRadioButton);
    procedure BplBinaryFileSelected;
    procedure BplProjectFileSelected;
    procedure EditLine(aControl: TListBox; const aCaption: string;
      const aEditItems: TEditItems; aValidFunc: TItemEditValidFunc);
    procedure FilterListItemSelected;
    procedure FilterListTypeChanged(const aFilterListType: TFilterListType);
    procedure NewLine(aControl: TListBox; const aCaption: string;
      const aEditItems: TEditItems; aValidFunc: TItemEditValidFunc);
    procedure PackageTypeChanged(const aPackageType: TPackageType);
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
  Apollo_DPM_Form,
  Apollo_DPM_UIHelper;

{ TPackageForm }

procedure TPackageForm.actDeleteAddingUnitExecute(Sender: TObject);
begin
  if MessageDlg('The unit reference will be deleted. Continue?', mtConfirmation,
    [mbYes, mbCancel], 0) = mrYes
  then
  begin
    lbAddingUnitRefs.Items.Delete(lbAddingUnitRefs.ItemIndex);
    AddingUnitSelected;
  end;
end;

procedure TPackageForm.actDeleteBplBinFileExecute(Sender: TObject);
begin
  if MessageDlg('The package reference will be deleted. Continue?', mtConfirmation,
    [mbYes, mbCancel], 0) = mrYes
  then
  begin
    lbBplBinaries.Items.Delete(lbBplBinaries.ItemIndex);
    BplBinaryFileSelected;
  end;
end;

procedure TPackageForm.actDeleteBplPrjFileExecute(Sender: TObject);
begin
  if MessageDlg('The project reference will be deleted. Continue?', mtConfirmation,
    [mbYes, mbCancel], 0) = mrYes
  then
  begin
    lbBplProjects.Items.Delete(lbBplProjects.ItemIndex);
    BplProjectFileSelected;
  end;
end;

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

procedure TPackageForm.actEditAddingUnitExecute(Sender: TObject);
begin
  EditLine(lbAddingUnitRefs, 'Edit Unit Reference',
    [TEditItem.Create(GetRepoRelativePath, lbAddingUnitRefs.GetSelectedText)], nil);
end;

procedure TPackageForm.actEditBplBinFileExecute(Sender: TObject);
begin
  EditLine(lbBplBinaries, 'Edit Package Reference',
    [TEditItem.Create(cStrPackage, lbBplBinaries.GetSelectedText)], IsBplPkgValid);
end;

procedure TPackageForm.actEditBplPrjFileExecute(Sender: TObject);
begin
  EditLine(lbBplProjects, 'Edit Project Reference',
    [TEditItem.Create(cStrProject, lbBplProjects.GetSelectedText)], IsBplPrjValid);
end;

procedure TPackageForm.actEditFilterLineExecute(Sender: TObject);
begin
  EditLine(lbFilterList, 'Edit Filter Line',
    [TEditItem.Create(GetRepoRelativePath, lbFilterList.GetSelectedText)], nil);
end;

procedure TPackageForm.actEditPathMoveExecute(Sender: TObject);
var
  OutItems: TEditItems;
begin
  if TItemEditForm.Open(Self, 'Edit Path Moving', [
    TEditItem.Create(GetRepoRelativePath, lvPathMoves.Selected.Caption),
    TEditItem.Create(GetPackageRelativePath, lvPathMoves.Selected.SubItems[0])
  ], nil, OutItems)
  then
  begin
    lvPathMoves.Selected.Caption := OutItems.ValueByKey(GetRepoRelativePath);
    lvPathMoves.Selected.SubItems[0] := OutItems.ValueByKey(GetPackageRelativePath);
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

      IsValid(cValidationLoadRepoData);
      btnGoToURL.Enabled := True;
    end
  );
end;

procedure TPackageForm.actNewAddingUnitExecute(Sender: TObject);
begin
  NewLine(lbAddingUnitRefs, 'New Unit Reference',
    [TEditItem.Create(GetRepoRelativePath, '')], nil);
end;

procedure TPackageForm.actNewBplBinFileExecute(Sender: TObject);
begin
  NewLine(lbBplBinaries, 'New Package Reference',
    [TEditItem.Create(cStrPackage, '')], IsBplPkgValid);
end;

procedure TPackageForm.actNewBplPrjFileExecute(Sender: TObject);
begin
  NewLine(lbBplProjects, 'New Project Reference',
    [TEditItem.Create(cStrProject, '')], IsBplPrjValid);
end;

procedure TPackageForm.actNewFilterLineExecute(Sender: TObject);
begin
  NewLine(lbFilterList, 'New Filter Line', [TEditItem.Create(GetRepoRelativePath, '')], nil);
end;

procedure TPackageForm.actNewPathMoveExecute(Sender: TObject);
var
  OutItems: TEditItems;
begin
  if TItemEditForm.Open(Self, 'New Path Moving', [
    TEditItem.Create(GetRepoRelativePath, ''),
    TEditItem.Create(GetPackageRelativePath, '')
  ], nil, OutItems)
  then
    RenderPathMoveItem(OutItems.ValueByKey(GetRepoRelativePath), OutItems.ValueByKey(GetPackageRelativePath));
end;

procedure TPackageForm.AddingUnitSelected;
var
  bEnable: Boolean;
begin
  bEnable := lbAddingUnitRefs.Enabled and (lbAddingUnitRefs.ItemIndex > -1);

  SetControlsEnable(bEnable, [
    btnEditAddingUnit,
    btnDeleteAddingUnit
  ]);
end;

procedure TPackageForm.AddUnitsOptionChanged(Sender: TRadioButton);
var
  bEnable: Boolean;
begin
  if Sender = rbAddAllUnits then
    chkAddSearchPath.Checked := not rbAddAllUnits.Checked;

  bEnable := not rbAddAllUnits.Checked and rbAddAllUnits.Enabled;
  SetControlsEnable(bEnable, [chkAddSearchPath]);

  bEnable := rbAddSpecified.Checked and rbAddAllUnits.Enabled;
  SetControlsEnable(bEnable, [btnNewAddingUnit, lbAddingUnitRefs]);

  AddingUnitSelected;
end;

procedure TPackageForm.BplBinaryFileSelected;
var
  bEnable: Boolean;
begin
  bEnable := lbBplBinaries.Enabled and (lbBplBinaries.ItemIndex > -1);

  SetControlsEnable(bEnable, [
    btnEditBplBinFile,
    btnDeleteBplBinFile
  ]);
end;

procedure TPackageForm.BplProjectFileSelected;
var
  bEnable: Boolean;
begin
  bEnable := lbBplProjects.Enabled and (lbBplProjects.ItemIndex > -1);

  SetControlsEnable(bEnable, [
    btnEditBplPrjFile,
    btnDeleteBplPrjFile
  ]);
end;

procedure TPackageForm.btnApplyClick(Sender: TObject);
begin
  if IsValid(cValidationOKClick) then
  begin
    ReadFromControls;
    ModalResult := mrOk;
  end;
end;

procedure TPackageForm.cbFilterListTypeChange(Sender: TObject);
begin
  FilterListTypeChanged(TFilterListType(cbFilterListType.ItemIndex));
end;

procedure TPackageForm.cbPackageTypeChange(Sender: TObject);
begin
  PackageTypeChanged(GetSelectedPackageType);
end;

constructor TPackageForm.Create(aDPMEngine: TDPMEngine; aPackage: TInitialPackage);
begin
  inherited Create(DPMForm);

  FDPMEngine := aDPMEngine;
  FPackage := aPackage;

  FillComboBox(cbFilterListType, cFilterListTypeNames);
  FillComboBox(cbPackageType, cPackageTypeNames);

  WriteToControls;
end;

procedure TPackageForm.EditLine(aControl: TListBox; const aCaption: string;
  const aEditItems: TEditItems; aValidFunc: TItemEditValidFunc);
var
  EditItem: TEditItem;
  OutItems: TEditItems;
begin
  if TItemEditForm.Open(Self, aCaption, aEditItems, aValidFunc, OutItems)
  then
  begin
    for EditItem in OutItems do
      aControl.Items[aControl.ItemIndex] := EditItem.Value;
  end;
end;

procedure TPackageForm.FilterListItemSelected;
var
  bEnable: Boolean;
begin
  bEnable := lbFilterList.Enabled and (lbFilterList.ItemIndex > -1);

  SetControlsEnable(bEnable, [
    btnEditFilterLine,
    btnDeleteFilterLine
  ]);
end;

procedure TPackageForm.FilterListTypeChanged(
  const aFilterListType: TFilterListType);
var
  bEnable: Boolean;
begin
  if aFilterListType = fltNone then
  begin
    lbFilterList.ItemIndex := -1;
    bEnable := False
  end
  else
    bEnable := True;

  SetControlsEnable(bEnable, [
    btnNewFilterLine,
    lbFilterList
  ]);

  FilterListItemSelected;
end;

function TPackageForm.GetPackageRelativePath: string;
begin
  Result := leName.Text + '\';
end;

function TPackageForm.GetRepoRelativePath: string;
begin
  Result := leRepoName.Text + '/';
end;

function TPackageForm.GetSelectedPackageType: TPackageType;
begin
  Result := TPackageType(cbPackageType.ItemIndex);
end;

function TPackageForm.GetSelectedVisibility: TVisibility;
begin
  if rbPrivate.Checked then
    Result := vPrivate
  else
    Result := vPublic;
end;

function TPackageForm.IsBplPkgValid(const aOutItems: TEditItems;
  aOutput: TLabel): Boolean;
var
  Value: string;
begin
  Result := True;
  Validation.SetOutputLabel(aOutput);
  Validation.Start(Self);

  Value := aOutItems.ValueByKey(cStrPackage);
  Validation.Assert(True, nil, Value.EndsWith('.bpl'), cStrMustHaveBplExtension, Result);
end;

function TPackageForm.IsBplPrjValid(const aOutItems: TEditItems; aOutput: TLabel): Boolean;
var
  Value: string;
begin
  Result := True;
  Validation.SetOutputLabel(aOutput);
  Validation.Start(Self);

  Value := aOutItems.ValueByKey(cStrProject);
  Validation.Assert(True, nil, Value.EndsWith('.dproj'), cStrMustHaveDprojExtension, Result);
end;

function TPackageForm.IsValid(const aValidationGroupName: string): Boolean;
begin
  Result := True;
  Validation.SetOutputLabel(lblValidationMsg);
  Validation.Start(Self);

  Validation.Assert(aValidationGroupName = cValidationLoadRepoData, leURL,
    FRepoDataLoadError = '', FRepoDataLoadError, Result);

  Validation.Assert(aValidationGroupName = cValidationOKClick, leRepoName,
    leRepoName.Text <> '', cStrARepositoryNameIsEmpty, Result);

  Validation.Assert(aValidationGroupName = cValidationOKClick, leName,
    leName.Text <> '', cStrTheFieldCantBeEmpty, Result);

  Validation.Assert(aValidationGroupName = cValidationOKClick, leName,
    Validation.ValidatePackageNameUniq(FPackage.ID, leName.Text, GetSelectedVisibility),
    cStrAPackageWithThisNameAlreadyExists, Result);

  Validation.Assert(aValidationGroupName = cValidationOKClick, lbBplProjects,
    (GetSelectedPackageType <> ptBplSource) or ((GetSelectedPackageType = ptBplSource) and (lbBplProjects.Count > 0)),
    cStrAtLeastOneProjectShouldBeAdded, Result);

  Validation.Assert(aValidationGroupName = cValidationOKClick, lbBplBinaries,
    (GetSelectedPackageType <> ptBplBinary) or ((GetSelectedPackageType = ptBplBinary) and (lbBplBinaries.Count > 0)),
    cStrAtLeastOnePackageShouldBeAdded, Result);
end;

procedure TPackageForm.lbAddingUnitRefsClick(Sender: TObject);
begin
  AddingUnitSelected;
end;

procedure TPackageForm.lbBplBinariesClick(Sender: TObject);
begin
  BplBinaryFileSelected;
end;

procedure TPackageForm.lbBplProjectsClick(Sender: TObject);
begin
  BplProjectFileSelected;
end;

procedure TPackageForm.lbFilterListClick(Sender: TObject);
begin
  FilterListItemSelected;
end;

procedure TPackageForm.lvPathMovesClick(Sender: TObject);
begin
  PathMoveSelected;
end;

procedure TPackageForm.NewLine(aControl: TListBox; const aCaption: string;
  const aEditItems: TEditItems; aValidFunc: TItemEditValidFunc);
var
  EditItem: TEditItem;
  OutItems: TEditItems;
begin
  if TItemEditForm.Open(Self, aCaption, aEditItems, aValidFunc, OutItems) then
  begin
    for EditItem in OutItems do
      aControl.Items.Add(EditItem.Value);
  end;
end;

procedure TPackageForm.PackageTypeChanged(const aPackageType: TPackageType);
var
  bEnable: Boolean;
begin
  bEnable := aPackageType = ptCodeSource;
  SetControlsEnable(bEnable, [rbAddAllUnits, rbAddSpecified, rbAddNothing, chkAddSearchPath]);
  AddUnitsOptionChanged(nil);

  bEnable := aPackageType = ptBplSource;
  SetControlsEnable(bEnable, [lbBplProjects, btnNewBplPrjFile, lblBplProjectRefs]);
  BplProjectFileSelected;

  bEnable := aPackageType = ptBplBinary;
  SetControlsEnable(bEnable, [lbBplBinaries, btnNewBplBinFile, lblBplBinaries]);
  BplBinaryFileSelected;
end;

procedure TPackageForm.PathMoveSelected;
var
  bEnable: Boolean;
begin
  if lvPathMoves.Selected <> nil then
    bEnable := True
  else
    bEnable := False;

  SetControlsEnable(bEnable, [
    btnEditPathMove,
    btnDeletePathMove
  ]);
end;

procedure TPackageForm.rbAddAllUnitsClick(Sender: TObject);
begin
  AddUnitsOptionChanged(Sender as TRadioButton);
end;

procedure TPackageForm.rbAddNothingClick(Sender: TObject);
begin
  AddUnitsOptionChanged(Sender as TRadioButton);
end;

procedure TPackageForm.rbAddSpecifiedClick(Sender: TObject);
begin
  AddUnitsOptionChanged(Sender as TRadioButton);
end;

procedure TPackageForm.ReadFromControls;
var
  i: Integer;
  PathMove: TRoute;
begin
  FPackage.PackageType := TPackageType(cbPackageType.ItemIndex);
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

  FPackage.ProjectFileRefs := [];
  for i := 0 to lbBplProjects.Items.Count - 1 do
    FPackage.ProjectFileRefs := FPackage.ProjectFileRefs + [lbBplProjects.Items[i]];

  FPackage.BinaryFileRefs := [];
  for i := 0 to lbBplBinaries.Items.Count - 1 do
    FPackage.BinaryFileRefs := FPackage.BinaryFileRefs + [lbBplBinaries.Items[i]];

  if rbAddAllUnits.Checked then
    FPackage.AddingUnitsOption := auAll
  else
  if rbAddSpecified.Checked then
    FPackage.AddingUnitsOption := auSpecified
  else
  if rbAddNothing.Checked then
    FPackage.AddingUnitsOption := auNothing;

  FPackage.AddSearchPath := chkAddSearchPath.Checked;

  FPackage.AddingUnitRefs := [];
  for i := 0 to lbAddingUnitRefs.Items.Count - 1 do
    FPackage.AddingUnitRefs := FPackage.AddingUnitRefs +[lbAddingUnitRefs.Items[i]];
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
  PathMove: TRoute;
  Value: string;
begin
  case FPackage.Visibility of
    vPrivate: rbPrivate.Checked := True;
    vPublic: rbPublic.Checked := True;
  end;

  cbPackageType.ItemIndex := Ord(FPackage.PackageType);

  leName.Text := FPackage.Name;
  leDescription.Text := FPackage.Description;
  leRepoOwner.Text := FPackage.RepoOwner;
  leRepoName.Text := FPackage.RepoName;

  cbFilterListType.ItemIndex := Ord(FPackage.FilterListType);
  FilterListTypeChanged(FPackage.FilterListType);

  for Value in FPackage.FilterList do
    lbFilterList.Items.Add(Value);

  for PathMove in FPackage.PathMoves do
    RenderPathMoveItem(PathMove.Source, PathMove.Destination);
  PathMoveSelected;

  case FPackage.AddingUnitsOption of
    auAll: rbAddAllUnits.Checked := True;
    auSpecified: rbAddSpecified.Checked := True;
    auNothing: rbAddNothing.Checked := True;
  end;
  chkAddSearchPath.Checked := FPackage.AddSearchPath;

  for Value in FPackage.ProjectFileRefs do
    lbBplProjects.Items.Add(Value);
  for Value in FPackage.BinaryFileRefs do
    lbBplBinaries.Items.Add(Value);
  PackageTypeChanged(FPackage.PackageType);

  for Value in FPackage.AddingUnitRefs do
    lbAddingUnitRefs.Items.Add(Value);
end;

end.
