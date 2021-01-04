unit Apollo_DPM_Form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.WinXCtrls, Vcl.Buttons, System.Actions, Vcl.ActnList, System.ImageList,
  Vcl.ImgList,
  Apollo_DPM_Engine,
  Apollo_DPM_PackageFrame,
  Apollo_DPM_Package,
  Apollo_DPM_Types,
  Apollo_DPM_Version;

type
  TDPMForm = class(TForm)
    pnlMainContainer: TPanel;
    splHorizontal: TSplitter;
    reActionLog: TRichEdit;
    pnlMain: TPanel;
    splVertical: TSplitter;
    tvNavigation: TTreeView;
    pnlFrames: TPanel;
    pnlButtons: TPanel;
    sbFrames: TScrollBox;
    swPackageDetails: TSplitView;
    pnlDetailsSwitcher: TPanel;
    btnSwitcher: TSpeedButton;
    ilIcons: TImageList;
    alActions: TActionList;
    actSwitchPackageDetails: TAction;
    btnNewPackage: TSpeedButton;
    actNewInitialPackage: TAction;
    procedure pnlDetailsSwitcherClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure swPackageDetailsOpened(Sender: TObject);
    procedure swPackageDetailsClosed(Sender: TObject);
    procedure tvNavigationCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure actNewInitialPackageExecute(Sender: TObject);
    procedure tvNavigationChange(Sender: TObject; Node: TTreeNode);
  private
    FDPMEngine: TDPMEngine;
    FFrames: TArray<TfrmPackage>;
    function GetSelectedNavigation: string;
    function ShowPackageForm(aPackage: TInitialPackage): Boolean;
    procedure ClearFrames;
    procedure DoRenderPackageList(aPackages: TArray<TPackage>);
    procedure FrameAction(const aFrameActionType: TFrameActionType; aPackage: TPackage;
      aVersion: TVersion);
    procedure RenderNavigation;
    procedure RenderPackageList(aPackageList: TPrivatePackageList); overload;
    procedure RenderPackageList(aPackageList: TDependentPackageList); overload;
    procedure RenderPackages;
    procedure UpdateFrame(aPackage: TPackage);
    procedure UpdateFrames(aPackageHandles: TPackageHandles);
  public
    procedure NotifyObserver(const aText: string);
    constructor Create(aDPMEngine: TDPMEngine); reintroduce;
  end;

var
  DPMForm: TDPMForm;

implementation

{$R *.dfm}

uses
  Apollo_DPM_Consts,
  Apollo_DPM_PackageForm;

{ TDPMForm }

procedure TDPMForm.actNewInitialPackageExecute(Sender: TObject);
var
  Package: TInitialPackage;
begin
  Package := TInitialPackage.Create;
  if ShowPackageForm(Package) then
  begin
    FDPMEngine.AddNewPrivatePackage(Package);
    RenderPackages;
  end
  else
    Package.Free;
end;

procedure TDPMForm.ClearFrames;
var
  Frame: TFrame;
begin
  for Frame in FFrames do
    Frame.Free;

  FFrames := [];
end;

constructor TDPMForm.Create(aDPMEngine: TDPMEngine);
begin
  inherited Create(nil);

  FDPMEngine := aDPMEngine;

  RenderNavigation;
end;

procedure TDPMForm.DoRenderPackageList(aPackages: TArray<TPackage>);
var
  i: Integer;
  Package: TPackage;
  PackageFrame: TfrmPackage;
  Top: Integer;
begin
  i := 0;
  Top := 0;

  for Package in aPackages do
  begin
    PackageFrame := TfrmPackage.Create(sbFrames, FDPMEngine, i);
    PackageFrame.OnAction := FrameAction;
    PackageFrame.OnAllowAction := FDPMEngine.AllowAction;
    PackageFrame.Top := Top;
    if not Odd(i) then
      PackageFrame.Color := clBtnFace;

    PackageFrame.RenderPackage(Package);

    Inc(i);
    Top := Top + PackageFrame.Height + 1;
    FFrames := FFrames + [PackageFrame];
  end;
end;

procedure TDPMForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 //SaveLayout([Self, splHorizontal, splVertical, swPackageDetail]);
end;

procedure TDPMForm.FrameAction(const aFrameActionType: TFrameActionType;
  aPackage: TPackage; aVersion: TVersion);
var
  PackageHandles: TPackageHandles;
begin
  case aFrameActionType of
    fatInstall:
      begin
        PackageHandles := FDPMEngine.Install(aPackage as TInitialPackage, aVersion);
        UpdateFrames(PackageHandles);
      end;
    fatUninstall:
      begin
        FDPMEngine.Uninstall(aPackage);
        {if aPackage.PackageSide = psInitial then
          UpdateFrame(aPackage)
        else
          RenderPackages;}
      end;
    fatEditPackage:
    begin
      if ShowPackageForm(aPackage as TInitialPackage) then
      begin
        FDPMEngine.UpdatePrivatePackage(aPackage as TPrivatePackage);
        UpdateFrame(aPackage);
      end;
    end;
  end;
end;

function TDPMForm.GetSelectedNavigation: string;
begin
  Result := '';

  if tvNavigation.Selected <> nil then
    Result := tvNavigation.Selected.Text;
end;

procedure TDPMForm.NotifyObserver(const aText: string);
begin
  reActionLog.Lines.Add(aText);

  reActionLog.Perform(WM_VSCROLL, SB_BOTTOM, 0);
  Application.ProcessMessages;
end;

procedure TDPMForm.pnlDetailsSwitcherClick(Sender: TObject);
begin
  swPackageDetails.Opened := swPackageDetails.Opened <> True;
end;

procedure TDPMForm.RenderNavigation;
begin
  tvNavigation.Items.Add(nil, cNavProjectDependencies);
  tvNavigation.Items.Add(nil, cNavPrivatePackages);
  tvNavigation.Items.Add(nil, cNavSettings);
end;

procedure TDPMForm.RenderPackageList(aPackageList: TPrivatePackageList);
var
  Package: TPrivatePackage;
  Packages: TArray<TPackage>;
begin
  Packages := [];

  for Package in aPackageList do
    Packages := Packages + [Package];

  DoRenderPackageList(Packages);
end;

procedure TDPMForm.RenderPackageList(aPackageList: TDependentPackageList);
var
  Package: TDependentPackage;
  Packages: TArray<TPackage>;
begin
  Packages := [];

  for Package in aPackageList do
    Packages := Packages + [Package];

  DoRenderPackageList(Packages);
end;

procedure TDPMForm.RenderPackages;
begin
  ClearFrames;

  if GetSelectedNavigation = cNavPrivatePackages then
    RenderPackageList(FDPMEngine.GetPrivatePackages)
  else
  if GetSelectedNavigation = cNavProjectDependencies then
    RenderPackageList(FDPMEngine.GetProjectPackages);
end;

function TDPMForm.ShowPackageForm(aPackage: TInitialPackage): Boolean;
begin
  PackageForm := TPackageForm.Create(FDPMEngine, aPackage);
  try
    if PackageForm.ShowModal = mrOk then
      Result := True
    else
      Result := False
  finally
    PackageForm.Free;
  end;
end;

procedure TDPMForm.swPackageDetailsClosed(Sender: TObject);
begin
  actSwitchPackageDetails.ImageIndex := cSwitchToLeftIconIndex;
end;

procedure TDPMForm.swPackageDetailsOpened(Sender: TObject);
begin
  actSwitchPackageDetails.ImageIndex := cSwitchToRightIconIndex;
end;

procedure TDPMForm.tvNavigationChange(Sender: TObject; Node: TTreeNode);
begin
  RenderPackages;
end;

procedure TDPMForm.tvNavigationCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Rect: TRect;
begin
  DefaultDraw := False;

  if cdsSelected in State then
    begin
      Sender.Canvas.Brush.Color := clHighlight;
      Sender.Canvas.Font.Color := clHighlightText;
    end
  else
    begin
      Sender.Canvas.Brush.Color := clWindow;
      Sender.Canvas.Font.Color := clWindowText;
    end;

  Rect := Node.DisplayRect(False);
  Sender.Canvas.FillRect(Rect);

  Rect := Node.DisplayRect(True);
  Sender.Canvas.TextOut(Rect.Left, Rect.Top, Node.Text);
end;

procedure TDPMForm.UpdateFrame(aPackage: TPackage);
var
  Frame: TfrmPackage;
begin
  for Frame in FFrames do
    if Frame.IsShowingPackage(aPackage) then
      Frame.ReRenderPackage;
end;

procedure TDPMForm.UpdateFrames(aPackageHandles: TPackageHandles);
var
  PackageHandle: TPackageHandle;
begin
  for PackageHandle in aPackageHandles do
    UpdateFrame(PackageHandle.InitialPackage);
end;

{
    procedure tvNavigationChange(Sender: TObject; Node: TTreeNode);
    procedure SaveLayout(const aControls: TArray<TWinControl>);

procedure TDPMForm.RenderSettings;
var
  SettingsFrame: TfrmSettings;
begin
  SettingsFrame := TfrmSettings.Create(Self);
  SettingsFrame.Parent := sbFrames;
  SettingsFrame.Align := alClient;

  FFrames := FFrames + [SettingsFrame];
end;

procedure TDPMForm.SaveLayout(const aControls: TArray<TWinControl>);
begin
end;
}

end.
