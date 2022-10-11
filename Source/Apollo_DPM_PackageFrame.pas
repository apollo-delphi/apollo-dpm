unit Apollo_DPM_PackageFrame;

interface

uses
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  Apollo_DPM_Types,
  Apollo_DPM_Version,
  System.Classes,
  System.SysUtils,
  System.Variants,
  Vcl.Buttons,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Menus,
  Vcl.StdCtrls,
  Vcl.ToolWin,
  Vcl.WinXCtrls,
  Winapi.Messages,
  Winapi.Windows;

type
  TPackageFrame = class(TFrame)
    lblName: TLabel;
    lblDescription: TLabel;
    pmActions: TPopupMenu;
    mniEditPackage: TMenuItem;
    cbVersions: TComboBox;
    lblVersion: TLabel;
    aiVersionLoad: TActivityIndicator;
    mniAdd: TMenuItem;
    btnAction: TSpeedButton;
    pnlActions: TPanel;
    btnActionDropDown: TSpeedButton;
    lblInstalled: TLabel;
    mniUninstall: TMenuItem;
    mniUpdate: TMenuItem;
    mniInstall: TMenuItem;
    procedure mniEditPackageClick(Sender: TObject);
    procedure cbVersionsDropDown(Sender: TObject);
    procedure mniAddClick(Sender: TObject);
    procedure btnActionDropDownClick(Sender: TObject);
    procedure mniUninstallClick(Sender: TObject);
    procedure cbVersionsChange(Sender: TObject);
    procedure cbVersionsCloseUp(Sender: TObject);
    procedure cbVersionsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure mniUpdateClick(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure FrameClick(Sender: TObject);
    procedure mniInstallClick(Sender: TObject);
  private
    FDPMEngine: TDPMEngine;
    FForLock: TArray<TMenuItem>;
    FInstalledVersion: TVersion;
    FOnAction: TFrameActionProc;
    FOnAllowAction: TFrameAllowActionFunc;
    FOnSelected: TFrameSelectedProc;
    FPackage: TPackage;
    FPackageID: string;
    FPackageClass: TPackageClass;
    FSelected: Boolean;
    function GetFirstActionMenuItem: TMenuItem;
    function GetSelectedVersion: TVersion;
    function GetVersionIndex(const aVersion: TVersion): Integer;
    procedure ActionWrapper(const aFrameActionType: TFrameActionType; aPackage: TPackage;
      aVersion: TVersion);
    procedure ClearVersionsCombo;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure DoLockUnlock(const aLock: Boolean);
    procedure FillVersionsCombo;
    procedure SetActionBtnMenuItem(aMenuItem: TMenuItem);
    procedure SetAllowedActions;
    procedure SetupInstalledLabel(aDependentPackage: TDependentPackage);
    procedure SetSelected(const aValue: Boolean);
  public
    function IsShowingPackage(const aPackageID: string): Boolean;
    procedure LockActions;
    procedure RenderPackage(aPackage: TPackage);
    procedure UnlockActions;
    constructor Create(aOwner: TWinControl; aDPMEngine: TDPMEngine;
      const aIndex: Integer); reintroduce;
    destructor Destroy; override;
    property PackageClass: TPackageClass read FPackageClass;
    property OnAction: TFrameActionProc read FOnAction write FOnAction;
    property OnAllowAction: TFrameAllowActionFunc read FOnAllowAction write FOnAllowAction;
    property OnSelected: TFrameSelectedProc read FOnSelected write FOnSelected;
    property Selected: Boolean read FSelected write SetSelected;
  end;

implementation

{$R *.dfm}

uses
  Apollo_DPM_Consts,
  Apollo_DPM_UIHelper,
  System.Math;

type
  TVersionComboItem = class
  private
    FVersion: TVersion;
    FIsOption: Boolean;
  public
    constructor Create(aVersion: TVersion); overload;
    constructor Create; overload;
    destructor Destroy; override;
  end;

{ TfrmPackage }

procedure TPackageFrame.ActionWrapper(const aFrameActionType: TFrameActionType;
  aPackage: TPackage; aVersion: TVersion);
begin
  OnSelected(Self, aPackage);
  FOnAction(aFrameActionType, aPackage, aVersion);
end;

procedure TPackageFrame.btnActionDropDownClick(Sender: TObject);
var
  LowerLeft: TPoint;
begin
  OnSelected(Self, FPackage);

  LowerLeft := Point(btnAction.Left, btnAction.Top + btnAction.Height + 2);
  LowerLeft := pnlActions.ClientToScreen(LowerLeft);
  pmActions.Popup(LowerLeft.X, LowerLeft.Y);
end;

procedure TPackageFrame.cbVersionsChange(Sender: TObject);
begin
  SetAllowedActions;
  SetActionBtnMenuItem(GetFirstActionMenuItem);
end;

procedure TPackageFrame.cbVersionsCloseUp(Sender: TObject);
begin
  if cbVersions.ItemIndex < 0 then
  begin
    cbVersions.ItemIndex := 0;
    cbVersionsChange(cbVersions);
  end;
end;

procedure TPackageFrame.cbVersionsDrawItem(Control: TWinControl; Index: Integer;
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

procedure TPackageFrame.cbVersionsDropDown(Sender: TObject);
begin
  OnSelected(Self, FPackage);

  AsyncLoad(aiVersionLoad,
    procedure
    begin
      FDPMEngine.Package_GetVersions(FPackage);
    end,
    procedure
    begin
      FillVersionsCombo;
    end
  );
end;

procedure TPackageFrame.ClearVersionsCombo;
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

procedure TPackageFrame.CMMouseEnter(var Message: TMessage);
begin
  Color := clGradientInactiveCaption;
end;

procedure TPackageFrame.CMMouseLeave(var Message: TMessage);
begin
  if not FSelected then
    Color := clWindow;
end;

constructor TPackageFrame.Create(aOwner: TWinControl; aDPMEngine: TDPMEngine;
  const aIndex: Integer);
begin
  inherited Create(aOwner);
  Parent := aOwner;

  Name := Format('PackageFrame%d', [aIndex]);
  Left := 0;
  Top := (Height + 2) * aIndex;

  FDPMEngine := aDPMEngine;

  FForLock := [mniAdd, mniUninstall, mniUpdate];
end;

destructor TPackageFrame.Destroy;
begin
  ClearVersionsCombo;
  inherited;
end;

procedure TPackageFrame.DoLockUnlock(const aLock: Boolean);
var
  MeniItem: TMenuItem;
begin
  for MeniItem in FForLock do
  begin
    MeniItem.Enabled := not aLock;

    if btnAction.Caption = MeniItem.Caption then
      btnAction.Enabled := MeniItem.Enabled;
  end;
end;

procedure TPackageFrame.FillVersionsCombo;
var
  Version: TVersion;
  Versions: TArray<TVersion>;
begin
  ClearVersionsCombo;

  Versions := FDPMEngine.Package_GetVersions(FPackage, True{aCachedOnly});

  if Length(Versions) = 0 then
    cbVersions.Items.AddObject(cStrLatestVersionOrCommit, TVersionComboItem.Create);

  for Version in Versions do
    cbVersions.Items.AddObject(Version.DisplayName, TVersionComboItem.Create(Version));
end;

procedure TPackageFrame.FrameClick(Sender: TObject);
begin
  OnSelected(Self, FPackage);
end;

procedure TPackageFrame.FrameResize(Sender: TObject);
begin
  if Assigned(Parent) then
    Width := Parent.Width;
end;

function TPackageFrame.GetFirstActionMenuItem: TMenuItem;
var
  MenuItem: TMenuItem;
begin
  Result := nil;
  for MenuItem in pmActions.Items do
    if MenuItem.Visible then
      Exit(MenuItem);
end;

procedure TPackageFrame.SetupInstalledLabel(aDependentPackage: TDependentPackage);
begin
  if aDependentPackage.Installed then
  begin
    if aDependentPackage.IsDirect then
    begin
      lblInstalled.Caption := 'installed';
      lblInstalled.Font.Color := clGreen;
    end
    else
    begin
      lblInstalled.Caption := 'indirect';
      lblInstalled.Font.Color := clMaroon;
    end;

    lblInstalled.Visible := True;
  end;

  {if FDPMEngine.Packages_GetProject.GetByID(aDependentPackage.ID) = nil then
  begin
    lblInstalled.Caption := 'ide only';
    lblInstalled.Font.Color := clGreen;
  end
  else
  if aDependentPackage.IsDirect then
  begin
    lblInstalled.Caption := 'installed';
    lblInstalled.Font.Color := clGreen;
  end
  else
  begin
    lblInstalled.Caption := 'indirect';
    lblInstalled.Font.Color := clMaroon;
  end;

  lblInstalled.Visible := True;}
end;

procedure TPackageFrame.UnlockActions;
begin
  DoLockUnlock(False);
end;

function TPackageFrame.GetSelectedVersion: TVersion;
var
  VersionComboItem: TVersionComboItem;
begin
  if cbVersions.ItemIndex < 0 then
    Exit(nil);

  VersionComboItem := cbVersions.Items.Objects[cbVersions.ItemIndex] as TVersionComboItem;
  Result := VersionComboItem.FVersion;
end;

function TPackageFrame.GetVersionIndex(const aVersion: TVersion): Integer;
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
    if Assigned(VersionComboItem) and (VersionComboItem.FVersion.SHA = aVersion.SHA) then
      Exit(i);
  end;
end;

function TPackageFrame.IsShowingPackage(const aPackageID: string): Boolean;
begin
  Result := aPackageID = FPackageID;
end;

procedure TPackageFrame.LockActions;
begin
  DoLockUnlock(True);
end;

procedure TPackageFrame.RenderPackage(aPackage: TPackage);
begin
  FPackage := aPackage;
  FPackageID := aPackage.ID;
  FPackageClass := TPackageClass(aPackage.ClassType);

  lblName.Caption := aPackage.Name;
  lblDescription.Caption := aPackage.Description;

  FillVersionsCombo;

  lblInstalled.Visible := False;
  FInstalledVersion := nil;
  if FPackage.InheritsFrom(TDependentPackage) then
  begin
    FInstalledVersion := (FPackage as TDependentPackage).Version;
    SetupInstalledLabel((FPackage as TDependentPackage));
  end
  else
  if FPackage.InheritsFrom(TInitialPackage) then
  begin
    if Assigned((FPackage as TInitialPackage).DependentPackage) then
    begin
      FInstalledVersion := (FPackage as TInitialPackage).DependentPackage.Version;
      SetupInstalledLabel((FPackage as TInitialPackage).DependentPackage);
    end;
  end;

  if Assigned(FInstalledVersion) then
    cbVersions.ItemIndex := GetVersionIndex(FInstalledVersion)
  else
    cbVersions.ItemIndex := 0;

  SetAllowedActions;
  SetActionBtnMenuItem(GetFirstActionMenuItem);
end;

procedure TPackageFrame.mniEditPackageClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniEditPackage);
  ActionWrapper(fatEditPackage, FPackage, GetSelectedVersion);
end;

procedure TPackageFrame.mniInstallClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniInstall);
  ActionWrapper(fatInstall, FPackage, GetSelectedVersion);
end;

procedure TPackageFrame.mniAddClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniAdd);
  ActionWrapper(fatAdd, FPackage, GetSelectedVersion);
end;

procedure TPackageFrame.mniUninstallClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniUninstall);
  ActionWrapper(fatUninstall, FPackage, GetSelectedVersion);
end;

procedure TPackageFrame.mniUpdateClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniUpdate);
  ActionWrapper(fatUpdate, FPackage, GetSelectedVersion);
end;

procedure TPackageFrame.SetActionBtnMenuItem(aMenuItem: TMenuItem);
begin
  btnAction.Caption := aMenuItem.Caption;
  btnAction.Enabled := aMenuItem.Enabled;
  btnAction.OnClick := aMenuItem.OnClick;
end;

procedure TPackageFrame.SetAllowedActions;
begin
  mniAdd.Visible := FOnAllowAction(fatAdd, FPackage, GetSelectedVersion);
  mniUpdate.Visible := FOnAllowAction(fatUpdate, FPackage, GetSelectedVersion);
  mniUninstall.Visible := FOnAllowAction(fatUninstall, FPackage, GetSelectedVersion);
  mniInstall.Visible := FOnAllowAction(fatInstall, FPackage, GetSelectedVersion);
  mniEditPackage.Visible := FOnAllowAction(fatEditPackage, FPackage, nil);
end;

procedure TPackageFrame.SetSelected(const aValue: Boolean);
begin
  if aValue then
    Color := clGradientInactiveCaption
  else
    Color := clWindow;

  FSelected := aValue;
end;

{ TVersionComboItem }

constructor TVersionComboItem.Create;
begin
  FIsOption := True;
  FVersion := TVersion.CreateAsLatestVersionOption;
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
