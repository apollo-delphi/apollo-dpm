unit Apollo_DPM_PackageFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.Menus, Vcl.Buttons, Vcl.ComCtrls, Vcl.ToolWin, Vcl.WinXCtrls,
  Vcl.ExtCtrls,
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  Apollo_DPM_Types,
  Apollo_DPM_Version;

type
  TVersionComboItem = class
  private
    FVersion: TVersion;
    FIsOption: Boolean;
  public
    constructor Create(aVersion: TVersion); overload;
    constructor Create(const aGetVersionOption: string); overload;
    destructor Destroy; override;
  end;

  TfrmPackage = class(TFrame)
    lblName: TLabel;
    lblDescription: TLabel;
    pmActions: TPopupMenu;
    mniEditPackage: TMenuItem;
    cbVersions: TComboBox;
    lblVersion: TLabel;
    aiVersionLoad: TActivityIndicator;
    mniInstall: TMenuItem;
    btnAction: TSpeedButton;
    pnlActions: TPanel;
    btnActionDropDown: TSpeedButton;
    lblInstalled: TLabel;
    mniUninstall: TMenuItem;
    mniUpdate: TMenuItem;
    procedure mniEditPackageClick(Sender: TObject);
    procedure cbVersionsDropDown(Sender: TObject);
    procedure mniInstallClick(Sender: TObject);
    procedure btnActionDropDownClick(Sender: TObject);
    procedure mniUninstallClick(Sender: TObject);
    procedure cbVersionsChange(Sender: TObject);
    procedure cbVersionsCloseUp(Sender: TObject);
    procedure cbVersionsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure mniUpdateClick(Sender: TObject);
  private
    FDPMEngine: TDPMEngine;
    FInstalledVersion: TVersion;
    FOnAction: TFrameActionProc;
    FOnAllowAction: TFrameAllowActionFunc;
    FPackage: TPackage;
    FPackageID: string;
    FPackageClass: TPackageClass;
    function GetFirstActionMenuItem: TMenuItem;
    function GetSelectedVersion: TVersion;
    function GetVersionIndex(const aVersion: TVersion): Integer;
    procedure ClearVersionsCombo;
    procedure FillVersionsCombo;
    procedure SetActionBtnMenuItem(aMenuItem: TMenuItem);
    procedure SetAllowedActions;
  public
    function IsShowingPackage(const aPackageID: string): Boolean;
    procedure RenderPackage(aPackage: TPackage);
    procedure ReRenderPackage;
    constructor Create(aOwner: TWinControl; aDPMEngine: TDPMEngine;
      const aIndex: Integer); reintroduce;
    destructor Destroy; override;
    property PackageClass: TPackageClass read FPackageClass;
    property OnAction: TFrameActionProc read FOnAction write FOnAction;
    property OnAllowAction: TFrameAllowActionFunc read FOnAllowAction write FOnAllowAction;
  end;

implementation

uses
  Apollo_DPM_Consts,
  Apollo_DPM_UIHelper,
  System.Math;

{$R *.dfm}

{ TfrmPackage }

procedure TfrmPackage.btnActionDropDownClick(Sender: TObject);
var
  LowerLeft: TPoint;
begin
  LowerLeft := Point(btnAction.Left, btnAction.Top + btnAction.Height + 2);
  LowerLeft := pnlActions.ClientToScreen(LowerLeft);
  pmActions.Popup(LowerLeft.X, LowerLeft.Y);
end;

procedure TfrmPackage.cbVersionsChange(Sender: TObject);
begin
  SetAllowedActions;
  SetActionBtnMenuItem(GetFirstActionMenuItem);
end;

procedure TfrmPackage.cbVersionsCloseUp(Sender: TObject);
begin
  if cbVersions.ItemIndex < 0 then
  begin
    cbVersions.ItemIndex := 0;
    cbVersionsChange(cbVersions);
  end;
end;

procedure TfrmPackage.cbVersionsDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  VersionComboItem: TVersionComboItem;
begin
  VersionComboItem := cbVersions.Items.Objects[Index] as TVersionComboItem;

  if GetVersionIndex(FInstalledVersion) = Index then
    cbVersions.Canvas.Font.Style := [fsBold]
  else
    cbVersions.Canvas.Font.Style := [];

  cbVersions.Canvas.FillRect(Rect);
  cbVersions.Canvas.TextOut(Rect.Left + 1, Rect.Top + 1, VersionComboItem.FVersion.DisplayName);
end;

procedure TfrmPackage.cbVersionsDropDown(Sender: TObject);
begin
  AsyncLoad(aiVersionLoad,
    procedure
    begin
      FDPMEngine.GetVersions(FPackage);
    end,
    procedure
    begin
      FillVersionsCombo;
    end
  );
end;

procedure TfrmPackage.ClearVersionsCombo;
var
  i: Integer;
  VersionComboItem: TVersionComboItem;
begin
  for i := 0 to cbVersions.Items.Count - 1 do
  begin
    VersionComboItem := cbVersions.Items.Objects[i] as TVersionComboItem;
    VersionComboItem.Free;
  end;

  cbVersions.Items.Clear;
end;

constructor TfrmPackage.Create(aOwner: TWinControl; aDPMEngine: TDPMEngine;
  const aIndex: Integer);
begin
  inherited Create(aOwner);

  Name := Format('PackageFrame%d', [aIndex]);
  Parent := aOwner;
  Left := 0;
  Width := aOwner.Width - 15;

  FDPMEngine := aDPMEngine;
end;

destructor TfrmPackage.Destroy;
begin
  ClearVersionsCombo;
  inherited;
end;

procedure TfrmPackage.FillVersionsCombo;
var
  Version: TVersion;
  Versions: TArray<TVersion>;
begin
  ClearVersionsCombo;

  if not FDPMEngine.AreVersionsLoaded(FPackage.ID) then
    cbVersions.Items.AddObject(cStrLatestVersionOrCommit, TVersionComboItem.Create(cStrLatestVersionOrCommit))
  else
    cbVersions.Items.AddObject(cStrLatestCommit, TVersionComboItem.Create(cStrLatestCommit));

  Versions := FDPMEngine.GetVersions(FPackage, True);
  for Version in Versions do
    cbVersions.Items.AddObject(Version.DisplayName, TVersionComboItem.Create(Version));
end;

function TfrmPackage.GetFirstActionMenuItem: TMenuItem;
var
  MenuItem: TMenuItem;
begin
  Result := nil;
  for MenuItem in pmActions.Items do
    if MenuItem.Visible then
      Exit(MenuItem);
end;

function TfrmPackage.GetSelectedVersion: TVersion;
var
  VersionComboItem: TVersionComboItem;
begin
  if cbVersions.ItemIndex < 0 then
    Exit(nil);

  VersionComboItem := cbVersions.Items.Objects[cbVersions.ItemIndex] as TVersionComboItem;
  Result := VersionComboItem.FVersion;
end;

function TfrmPackage.GetVersionIndex(const aVersion: TVersion): Integer;
var
  i: Integer;
  VersionComboItem: TVersionComboItem;
begin
  Result := -1;
  if not Assigned(aVersion) then
    Exit;

  for i := 0 to cbVersions.Items.Count - 1 do
  begin
    VersionComboItem := cbVersions.Items.Objects[i] as TVersionComboItem;
    if VersionComboItem.FVersion.SHA = aVersion.SHA then
      Exit(i);
  end;
end;

function TfrmPackage.IsShowingPackage(const aPackageID: string): Boolean;
begin
  Result := aPackageID = FPackageID;
end;

procedure TfrmPackage.RenderPackage(aPackage: TPackage);
begin
  FPackage := aPackage;
  FPackageID := aPackage.ID;
  FPackageClass := TPackageClass(aPackage.ClassType);

  lblName.Caption := aPackage.Name;
  lblDescription.Caption := aPackage.Description;

  FillVersionsCombo;

  FInstalledVersion := nil;
  if FPackage is TDependentPackage then
    FInstalledVersion := (FPackage as TDependentPackage).Version
  else
  if FPackage is TInitialPackage then
  begin
    if Assigned((FPackage as TInitialPackage).DependentPackage) then
      FInstalledVersion := (FPackage as TInitialPackage).DependentPackage.Version;
  end;

  if Assigned(FInstalledVersion) then
  begin
    cbVersions.ItemIndex := GetVersionIndex(FInstalledVersion);
    lblInstalled.Visible := True;
  end
  else
  begin
    cbVersions.ItemIndex := 0;
    lblInstalled.Visible := False;
  end;

  SetAllowedActions;
  SetActionBtnMenuItem(GetFirstActionMenuItem);
end;

procedure TfrmPackage.ReRenderPackage;
begin
  RenderPackage(FPackage);
end;

procedure TfrmPackage.mniEditPackageClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniEditPackage);
  FOnAction(fatEditPackage, FPackage, GetSelectedVersion);
end;

procedure TfrmPackage.mniInstallClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniInstall);
  FOnAction(fatInstall, FPackage, GetSelectedVersion);
end;

procedure TfrmPackage.mniUninstallClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniUninstall);
  FOnAction(fatUninstall, FPackage, GetSelectedVersion);
end;

procedure TfrmPackage.mniUpdateClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniUpdate);
  FOnAction(fatUpdate, FPackage, GetSelectedVersion);
end;

procedure TfrmPackage.SetActionBtnMenuItem(aMenuItem: TMenuItem);
begin
  btnAction.Caption := aMenuItem.Caption;
  btnAction.OnClick := aMenuItem.OnClick;
end;

procedure TfrmPackage.SetAllowedActions;
begin
  mniInstall.Visible := FOnAllowAction(fatInstall, FPackage, GetSelectedVersion);
  mniUpdate.Visible := FOnAllowAction(fatUpdate, FPackage, GetSelectedVersion);
  mniUninstall.Visible := FOnAllowAction(fatUninstall, FPackage, GetSelectedVersion);
  mniEditPackage.Visible := FOnAllowAction(fatEditPackage, FPackage, nil);
end;

{ TVersionComboItem }

constructor TVersionComboItem.Create(const aGetVersionOption: string);
begin
  FIsOption := True;
  FVersion := TVersion.Create;

  FVersion.Name := aGetVersionOption;
  FVersion.SHA := '';
end;

destructor TVersionComboItem.Destroy;
begin
  if FIsOption then
    FVersion.Free;

  inherited;
end;

constructor TVersionComboItem.Create(aVersion: TVersion);
begin
  FIsOption := False;
  FVersion := aVersion;
end;

end.
