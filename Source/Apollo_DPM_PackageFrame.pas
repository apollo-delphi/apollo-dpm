unit Apollo_DPM_PackageFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.Menus, Vcl.Buttons, Vcl.ComCtrls, Vcl.ToolWin, Vcl.WinXCtrls,
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  Apollo_DPM_Types, Vcl.ExtCtrls;

type
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
    FPackage: TPackage;
    procedure FillVersionsCombo;
    procedure SetActionBtnMenuItem(aMenuItem: TMenuItem);
  public
    constructor Create(aOwner: TComponent; aPackage: TPackage; aDPMEngine: TDPMEngine); reintroduce;
    property OnAction: TFrameActionProc read FOnAction write FOnAction;
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

constructor TfrmPackage.Create(aOwner: TComponent; aPackage: TPackage; aDPMEngine: TDPMEngine);
begin
  inherited Create(aOwner);

  FDPMEngine := aDPMEngine;
  FPackage := aPackage;
  lblName.Caption := aPackage.Name;
  lblDescription.Caption := aPackage.Description;

  SetActionBtnMenuItem(mniInstall);
  FillVersionsCombo;
end;

procedure TfrmPackage.FillVersionsCombo;
var
  Version: TVersion;
begin
  cbVersions.Items.Clear;

  if not FPackage.AreVersionsLoaded then
    cbVersions.Items.Add(cStrLatestVersionOrCommit)
  else
    cbVersions.Items.Add(cStrLatestCommit);

  for Version in FPackage.Versions do
    cbVersions.Items.Add(Version.Name);

  cbVersions.ItemIndex := 0;
end;

procedure TfrmPackage.mniEditPackageClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniEditPackage);
  FOnAction(fatEditPackage, FPackage);
end;

procedure TfrmPackage.mniInstallClick(Sender: TObject);
begin
  SetActionBtnMenuItem(mniInstall);
  FOnAction(fatInstall, FPackage);
end;

procedure TfrmPackage.SetActionBtnMenuItem(aMenuItem: TMenuItem);
begin
  btnAction.Caption := aMenuItem.Caption;
  btnAction.OnClick := aMenuItem.OnClick;
end;

end.
