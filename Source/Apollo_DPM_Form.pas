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
  Apollo_DPM_SettingsFrame,
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
    FPackageFrames: TArray<TPackageFrame>;
    FSettingsFrame: TSettingsFrame;
    function GetFrame(const aPackageID: string): TPackageFrame;
    function GetFrameIndex(aFrame: TPackageFrame): Integer;
    function GetSelectedNavigation: string;
    function ShowPackageForm(aPackage: TInitialPackage): Boolean;
    procedure ClearFrames;
    procedure DeleteFrame(aFrame: TPackageFrame);
    procedure DoRenderPackageList(aPackages: TArray<TPackage>);
    procedure FrameAction(const aFrameActionType: TFrameActionType; aPackage: TPackage;
      aVersion: TVersion);
    procedure RenderNavigation;
    procedure RenderPackageList(aPackageList: TPrivatePackageList); overload;
    procedure RenderPackageList(aPackageList: TDependentPackageList); overload;
    procedure RenderPackage(aPackage: TPackage; const aIndex: Integer);
    procedure RenderPackages;
    procedure RenderSettings;
    procedure UpdateFrame(aFrame: TPackageFrame);
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
  Apollo_DPM_PackageForm,
  Apollo_DPM_UIHelper;

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
  for Frame in FPackageFrames do
    Frame.Free;

  FPackageFrames := [];

  if Assigned(FSettingsFrame) then
    FreeAndNil(FSettingsFrame);
end;

constructor TDPMForm.Create(aDPMEngine: TDPMEngine);
begin
  inherited Create(nil);

  FDPMEngine := aDPMEngine;

  RenderNavigation;
end;

procedure TDPMForm.DeleteFrame(aFrame: TPackageFrame);
var
  Frame: TPackageFrame;
  Top: Integer;
begin
  if not Assigned(aFrame) then
    Exit;

  Delete(FPackageFrames, GetFrameIndex(aFrame), 1);
  Top := aFrame.Top;
  aFrame.Free;

  for Frame in FPackageFrames do
    if Frame.Top > Top then
      Frame.Top := Frame.Top - Frame.Height;
end;

procedure TDPMForm.DoRenderPackageList(aPackages: TArray<TPackage>);
var
  i: Integer;
begin
  for i := 0 to Length(aPackages) - 1 do
    RenderPackage(aPackages[i], i);
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
        AsyncLoad(nil,
          procedure
          begin
            PackageHandles := FDPMEngine.Install(aPackage as TInitialPackage, aVersion);
          end,
          procedure
          begin
            UpdateFrames(PackageHandles);
          end
        );
      end;
    fatUpdate:
      begin
        AsyncLoad(nil,
          procedure
          begin
            PackageHandles := FDPMEngine.Update(aPackage, aVersion);
          end,
          procedure
          begin
            UpdateFrames(PackageHandles);
          end
        );
      end;
    fatUninstall:
      begin
        PackageHandles := FDPMEngine.Uninstall(aPackage);
        UpdateFrames(PackageHandles);
      end;
    fatEditPackage:
    begin
      if ShowPackageForm(aPackage as TInitialPackage) then
      begin
        FDPMEngine.UpdatePrivatePackage(aPackage as TPrivatePackage);
        UpdateFrame(GetFrame(aPackage.ID));
      end;
    end;
  end;
end;

function TDPMForm.GetFrame(const aPackageID: string): TPackageFrame;
var
  Frame: TPackageFrame;
begin
  Result := nil;

  for Frame in FPackageFrames do
    if Frame.IsShowingPackage(aPackageID) then
      Exit(Frame);
end;

function TDPMForm.GetFrameIndex(aFrame: TPackageFrame): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := 0 to Length(FPackageFrames) - 1 do
    if FPackageFrames[i] = aFrame then
      Exit(i);
end;

function TDPMForm.GetSelectedNavigation: string;
begin
  Result := '';

  if tvNavigation.Selected <> nil then
    Result := tvNavigation.Selected.Text;
end;

procedure TDPMForm.NotifyObserver(const aText: string);
begin
  TThread.Synchronize(nil, procedure()
    begin
      reActionLog.Lines.Add(aText);
      reActionLog.Perform(WM_VSCROLL, SB_BOTTOM, 0);
    end
  );
end;

procedure TDPMForm.pnlDetailsSwitcherClick(Sender: TObject);
begin
  swPackageDetails.Opened := swPackageDetails.Opened <> True;
end;

procedure TDPMForm.RenderNavigation;
begin
  tvNavigation.Items.Add(nil, cNavProjectDependencies);
  tvNavigation.Items.Add(nil, cNavInstalledToIDE);
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

procedure TDPMForm.RenderPackage(aPackage: TPackage; const aIndex: Integer);
var
  PackageFrame: TPackageFrame;
begin
  PackageFrame := TPackageFrame.Create(sbFrames, FDPMEngine, aIndex);
  PackageFrame.OnAction := FrameAction;
  PackageFrame.OnAllowAction := FDPMEngine.AllowAction;

  PackageFrame.RenderPackage(aPackage);

  FPackageFrames := FPackageFrames + [PackageFrame];
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
    RenderPackageList(FDPMEngine.GetProjectPackages)
  else
  if GetSelectedNavigation = cNavInstalledToIDE then
    RenderPackageList(FDPMEngine.GetIDEPackages);
end;

procedure TDPMForm.RenderSettings;
begin
  ClearFrames;

  FSettingsFrame := TSettingsFrame.Create(sbFrames, FDPMEngine);
  FSettingsFrame.Parent := sbFrames;
  FSettingsFrame.Align := alClient;
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
  if GetSelectedNavigation = cNavSettings then
    RenderSettings
  else
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

procedure TDPMForm.UpdateFrame(aFrame: TPackageFrame);
begin
  if Assigned(aFrame) then
    aFrame.ReRenderPackage;
end;

procedure TDPMForm.UpdateFrames(aPackageHandles: TPackageHandles);
var
  Frame: TPackageFrame;
  PackageHandle: TPackageHandle;
begin
  for PackageHandle in aPackageHandles do
  begin
    Frame := GetFrame(PackageHandle.PackageID);

    if not Assigned(Frame) then
    begin
      if GetSelectedNavigation = cNavProjectDependencies then
        RenderPackage(FDPMEngine.GetProjectPackages.GetByID(PackageHandle.PackageID), Length(FPackageFrames));

      Continue;
    end;

    if Frame.PackageClass = TPrivatePackage then
      case PackageHandle.PackageAction of
        paInstall: UpdateFrame(Frame);
        paUninstall: UpdateFrame(Frame);
      end
    else
    if Frame.PackageClass = TDependentPackage then
      case PackageHandle.PackageAction of
        paInstall: UpdateFrame(Frame);
        paUninstall: DeleteFrame(Frame);
      end;
  end;
end;

{procedure SaveLayout(const aControls: TArray<TWinControl>);


procedure TDPMForm.SaveLayout(const aControls: TArray<TWinControl>);
begin
end;
}

end.
