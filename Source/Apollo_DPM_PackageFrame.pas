unit Apollo_DPM_PackageFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.Menus, Vcl.Buttons, Vcl.ComCtrls, Vcl.ToolWin, Vcl.WinXCtrls,
  Vcl.ExtCtrls,
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  Apollo_DPM_Types;

type
  TVersionComboItem = class
  private
    FVersion: TVersion;
    constructor Create(const aVersion: TVersion); overload;
    constructor Create(const aGetVersionOption: string); overload;
    property Version: TVersion read FVersion;
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
    procedure mniEditPackageClick(Sender: TObject);
    procedure cbVersionsDropDown(Sender: TObject);
    procedure mniInstallClick(Sender: TObject);
    procedure btnActionDropDownClick(Sender: TObject);
  private
    FDPMEngine: TDPMEngine;
    FOnAction: TFrameActionProc;
    FOnAllowAction: TFrameAllowActionFunc;
    FPackage: TPackage;
    function GetFirstActionMenuItem: TMenuItem;
    function GetSelectedVersion: TVersion;
    function GetVersionIndex(const aVersion: TVersion): Integer;
    procedure ClearVersionsCombo;
    procedure FillVersionsCombo;
    procedure SetActionBtnMenuItem(aMenuItem: TMenuItem);
    procedure SetAllowedActions;
  public
    procedure Init;
    constructor Create(aOwner: TComponent; aPackage: TPackage; aDPMEngine: TDPMEngine); reintroduce;
    destructor Destroy; override;
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

procedure TfrmPackage.cbVersionsDropDown(Sender: TObject);
begin
  AsyncLoad(aiVersionLoad,
    procedure
    begin
      FDPMEngine.LoadRepoVersions(FPackage);
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
begin
  for i := 0 to cbVersions.Items.Count - 1 do
    cbVersions.Items.Objects[i].Free;
  cbVersions.Items.Clear;
end;

constructor TfrmPackage.Create(aOwner: TComponent; aPackage: TPackage; aDPMEngine: TDPMEngine);
begin
  inherited Create(aOwner);

  FDPMEngine := aDPMEngine;
  FPackage := aPackage;
  lblName.Caption := aPackage.Name;
  lblDescription.Caption := aPackage.Description;
end;

destructor TfrmPackage.Destroy;
begin
  ClearVersionsCombo;
  inherited;
end;

procedure TfrmPackage.FillVersionsCombo;
var
  Version: TVersion;
begin
  ClearVersionsCombo;

  if not FPackage.AreVersionsLoaded then
    cbVersions.Items.AddObject(cStrLatestVersionOrCommit, TVersionComboItem.Create(cStrLatestVersionOrCommit))
  else
    cbVersions.Items.AddObject(cStrLatestCommit, TVersionComboItem.Create(cStrLatestCommit));

  for Version in FPackage.Versions do
    cbVersions.Items.AddObject(Version.GetDisplayName, TVersionComboItem.Create(Version));
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
  VersionComboItem := cbVersions.Items.Objects[cbVersions.ItemIndex] as TVersionComboItem;
  Result := VersionComboItem.Version;
end;

function TfrmPackage.GetVersionIndex(const aVersion: TVersion): Integer;
var
  i: Integer;
  VersionComboItem: TVersionComboItem;
begin
  Result := -1;

  for i := 0 to cbVersions.Items.Count - 1 do
  begin
    VersionComboItem := cbVersions.Items.Objects[i] as TVersionComboItem;
    if VersionComboItem.Version.SHA = aVersion.SHA then
      Exit(i);
  end;
end;

procedure TfrmPackage.Init;
begin
  SetAllowedActions;
  SetActionBtnMenuItem(GetFirstActionMenuItem);
  FillVersionsCombo;

  if not FPackage.Version.IsEmpty then
    cbVersions.ItemIndex := GetVersionIndex(FPackage.Version)
  else
    cbVersions.ItemIndex := 0;
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

procedure TfrmPackage.SetActionBtnMenuItem(aMenuItem: TMenuItem);
begin
  btnAction.Caption := aMenuItem.Caption;
  btnAction.OnClick := aMenuItem.OnClick;
end;

procedure TfrmPackage.SetAllowedActions;
begin
  mniInstall.Visible := FOnAllowAction(fatInstall);
  mniEditPackage.Visible := FOnAllowAction(fatEditPackage);
end;

{ TVersionComboItem }

constructor TVersionComboItem.Create(const aGetVersionOption: string);
begin
  FVersion.Name := aGetVersionOption;
  FVersion.SHA := '';
end;

constructor TVersionComboItem.Create(const aVersion: TVersion);
begin
  FVersion := aVersion;
end;

end.
