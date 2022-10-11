unit Apollo_DPM_Form;

interface

uses
  Apollo_DPM_Engine,
  Apollo_DPM_Package,
  Apollo_DPM_PackageFrame,
  Apollo_DPM_SettingsFrame,
  Apollo_DPM_TestFrame,
  Apollo_DPM_Types,
  Apollo_DPM_Version,
  System.Actions,
  System.Classes,
  System.ImageList,
  System.SysUtils,
  System.Variants,
  Vcl.ActnList,
  Vcl.Buttons,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
  Vcl.ImgList,
  Vcl.StdCtrls,
  Vcl.WinXCtrls,
  Winapi.Messages,
  Winapi.Windows;

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
    lblPackageName: TLabel;
    mmoDependencies: TMemo;
    lblDependencies: TLabel;
    aiLoadDep: TActivityIndicator;
    fodSelectFolder: TFileOpenDialog;
    edSearch: TEdit;
    imSearchIcon: TImage;
    pnlSearch: TPanel;
    btnClearSearch: TSpeedButton;
    actClearSearch: TAction;
    procedure pnlDetailsSwitcherClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure swPackageDetailsOpened(Sender: TObject);
    procedure swPackageDetailsClosed(Sender: TObject);
    procedure tvNavigationCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure actNewInitialPackageExecute(Sender: TObject);
    procedure tvNavigationChange(Sender: TObject; Node: TTreeNode);
    procedure sbFramesMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure sbFramesMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormResize(Sender: TObject);
    procedure edSearchKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure actClearSearchExecute(Sender: TObject);
    procedure actClearSearchUpdate(Sender: TObject);
  private
    FSearch: string;
    FDPMEngine: TDPMEngine;
    FPackageFrames: TArray<TPackageFrame>;
    FSettingsFrame: TSettingsFrame;
    FTestFrame: TTestFrame;
    function FindDependentPackage(const aPackageID: string): TPackage;
    function GetFrame(const aPackageID: string): TPackageFrame;
    function GetFrameIndex(aFrame: TPackageFrame): Integer;
    function GetSelectedNavigation: string;
    function ShowPackageForm(aPackage: TInitialPackage): Boolean;
    procedure ClearFrames;
    procedure DeleteFrame(aFrame: TPackageFrame);
    procedure DoRenderPackageList(aPackages: TArray<TPackage>);
    procedure FrameAction(const aFrameActionType: TFrameActionType; aPackage: TPackage;
      aVersion: TVersion);
    procedure FrameSelected(aFrame: TFrame; aPackage: TPackage);
    procedure RenderNavigation;
    procedure RenderPackageList(aPackageList: TPrivatePackageList); overload;
    procedure RenderPackageList(aPackageList: TDependentPackageList); overload;
    procedure RenderPackage(aPackage: TPackage; const aIndex: Integer);
    procedure RenderPackageDetail(aPackage: TPackage);
    procedure RenderPackages;
    procedure RenderSettings;
    procedure RenderTest;
    procedure UpdateFrame(aFrame: TPackageFrame; aPackage: TPackage);
    procedure UpdateFrames(aPackageHandles: TPackageHandles);
  public
    function GetFolder: string;
    procedure LockActions;
    procedure NotifyObserver(const aText: string);
    procedure UnlockActions;
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

procedure TDPMForm.actClearSearchExecute(Sender: TObject);
begin
  edSearch.Text := '';
  FSearch := '';
  RenderPackages;
end;

procedure TDPMForm.actClearSearchUpdate(Sender: TObject);
begin
  actClearSearch.Enabled := edSearch.Text <> '';
end;

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

  if Assigned(FTestFrame) then
    FreeAndNil(FTestFrame);
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

procedure TDPMForm.edSearchKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if edSearch.Modified and (edSearch.Text <> FSearch) then
  begin
    FSearch := edSearch.Text;
    RenderPackages;
  end;
end;

function TDPMForm.FindDependentPackage(const aPackageID: string): TPackage;
begin
  Result := FDPMEngine.Packages_GetProject.GetByID(aPackageID);
  if not Assigned(Result) then
    Result := FDPMEngine.Packages_GetIDE.GetByID(aPackageID);
end;

procedure TDPMForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 //SaveLayout([Self, splHorizontal, splVertical, swPackageDetail]);
end;

procedure TDPMForm.FormResize(Sender: TObject);
begin
  Refresh;
end;

procedure TDPMForm.FrameAction(const aFrameActionType: TFrameActionType;
  aPackage: TPackage; aVersion: TVersion);
var
  PackageHandles: TPackageHandles;
begin
  case aFrameActionType of
    fatAdd:
      begin
        AsyncLoad(nil,
          procedure
          begin
            PackageHandles := FDPMEngine.Action_Add(aPackage as TInitialPackage, aVersion);
          end,
          procedure
          begin
            UpdateFrames(PackageHandles);
          end
        );
      end;
    fatInstall:
      begin
        AsyncLoad(nil,
          procedure
          begin
            PackageHandles := FDPMEngine.Action_Install(aPackage);
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
            PackageHandles := FDPMEngine.Action_Update(aPackage, aVersion);
          end,
          procedure
          begin
            UpdateFrames(PackageHandles);
          end
        );
      end;
    fatUninstall:
      begin
        AsyncLoad(nil,
          procedure
          begin
            PackageHandles := FDPMEngine.Action_Uninstall(aPackage);
          end,
          procedure
          begin
            UpdateFrames(PackageHandles);
          end
        );
      end;
    fatEditPackage:
    begin
      if ShowPackageForm(aPackage as TInitialPackage) then
      begin
        FDPMEngine.UpdatePrivatePackage(aPackage as TPrivatePackage);
        UpdateFrame(GetFrame(aPackage.ID), aPackage);
      end;
    end;
  end;
end;

procedure TDPMForm.FrameSelected(aFrame: TFrame; aPackage: TPackage);
var
  Frame: TPackageFrame;
begin
  TPackageFrame(aFrame).Selected := True;

  for Frame in FPackageFrames do
    if Frame <> aFrame then
      Frame.Selected := False;

  RenderPackageDetail(aPackage);
end;

function TDPMForm.GetFolder: string;
begin
  Result := '';

  if fodSelectFolder.Execute then
    Result := fodSelectFolder.FileName;
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

procedure TDPMForm.LockActions;
var
  Frame: TPackageFrame;
begin
  for Frame in FPackageFrames do
    Frame.LockActions;
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
{$IFDEF DEBUG}
  if FDPMEngine.Project_GetDPM(True{aMayReturnNil}) <> nil then
    tvNavigation.Items.Add(nil, cNavTest);
{$ENDIF DEBUG}
end;

procedure TDPMForm.RenderPackageList(aPackageList: TPrivatePackageList);
var
  Package: TPrivatePackage;
  Packages: TArray<TPackage>;
begin
  ClearFrames;
  Packages := [];
  FSearch := Trim(edSearch.Text);

  for Package in aPackageList do
    if Package.SearchMatched(FSearch) then
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
  PackageFrame.OnSelected := FrameSelected;

  PackageFrame.RenderPackage(aPackage);
  if FDPMEngine.AreActionsLocked then
    PackageFrame.LockActions;

  FPackageFrames := FPackageFrames + [PackageFrame];
end;

procedure TDPMForm.RenderPackageDetail(aPackage: TPackage);
var
  Dependencies: TDependentPackageList;
  //DependentPackage: TDependentPackage;
  InitialPackage: TInitialPackage;
  Version: TVersion;
begin
  if not swPackageDetails.Opened then
    Exit;

  InitialPackage := nil;
  //DependentPackage := nil;
  lblPackageName.Caption := aPackage.Name;

  if aPackage is TInitialPackage then
  begin
    InitialPackage := aPackage as TInitialPackage;
    Version := FDPMEngine.Package_GetVersions(InitialPackage)[0];
    //Version := FDPMEngine.DefineVersion(InitialPackage, Version);
  end
  else
  if aPackage is TDependentPackage then
  begin
    //DependentPackage := DependentPackage as TDependentPackage
  end
  else
    Exit;

  AsyncLoad(aiLoadDep,
    procedure()
    begin
      if Assigned(InitialPackage) then
        Dependencies := FDPMEngine.Package_LoadDependencies(InitialPackage, Version);
    end,
    procedure()
    var
      Dependency: TDependentPackage;
    begin
      for Dependency in Dependencies do
        mmoDependencies.Lines.Add(Dependency.Name);
    end
  );
end;

procedure TDPMForm.RenderPackageList(aPackageList: TDependentPackageList);
var
  Package: TDependentPackage;
  Packages: TArray<TPackage>;
begin
  ClearFrames;
  Packages := [];

  if FDPMEngine.Settings.ShowIndirectPackages then
    for Package in aPackageList do
      Packages := Packages + [Package]
  else
    for Package in aPackageList.GetDirectPackages do
      Packages := Packages + [Package];

  DoRenderPackageList(Packages);
end;

procedure TDPMForm.RenderPackages;
begin
  if GetSelectedNavigation = cNavPrivatePackages then
    RenderPackageList(FDPMEngine.Packages_GetPrivate)
  else
  if GetSelectedNavigation = cNavProjectDependencies then
    RenderPackageList(FDPMEngine.Packages_GetProject)
  else
  if GetSelectedNavigation = cNavInstalledToIDE then
    RenderPackageList(FDPMEngine.Packages_GetIDE);
end;

procedure TDPMForm.RenderSettings;
begin
  ClearFrames;

  FSettingsFrame := TSettingsFrame.Create(sbFrames, FDPMEngine);
  FSettingsFrame.Parent := sbFrames;
  FSettingsFrame.Align := alClient;
end;

procedure TDPMForm.RenderTest;
begin
  ClearFrames;

  FTestFrame := TTestFrame.Create(sbFrames, FDPMEngine);
  FTestFrame.Parent := sbFrames;
  FTestFrame.Align := alClient;
end;

procedure TDPMForm.sbFramesMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  sbFrames.VertScrollBar.Position := sbFrames.VertScrollBar.Position + 8;
end;

procedure TDPMForm.sbFramesMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  sbFrames.VertScrollBar.Position := sbFrames.VertScrollBar.Position - 8;
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
  edSearch.Text := '';

  if GetSelectedNavigation = cNavSettings then
    RenderSettings
  else
  if GetSelectedNavigation = cNavTest then
    RenderTest
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

procedure TDPMForm.UnlockActions;
var
  Frame: TPackageFrame;
begin
  for Frame in FPackageFrames do
    Frame.UnlockActions;
end;

procedure TDPMForm.UpdateFrame(aFrame: TPackageFrame; aPackage: TPackage);
begin
  if Assigned(aFrame) then
    aFrame.RenderPackage(aPackage);
end;

procedure TDPMForm.UpdateFrames(aPackageHandles: TPackageHandles);
var
  Frame: TPackageFrame;
  Package: TPackage;
  PackageHandle: TPackageHandle;
begin
  for PackageHandle in aPackageHandles do
  begin
    Frame := GetFrame(PackageHandle.PackageID);

    if not Assigned(Frame) then
    begin
      if (PackageHandle.PackageAction = paInstall) and (GetSelectedNavigation = cNavProjectDependencies) then
      begin
        Package := FindDependentPackage(PackageHandle.PackageID);
        RenderPackage(Package, Length(FPackageFrames));
      end;

      Continue;
    end;

    if Frame.PackageClass = TPrivatePackage then
    begin
      Package := FDPMEngine.Packages_GetPrivate.GetByID(PackageHandle.PackageID);

      case PackageHandle.PackageAction of
        paInstall: UpdateFrame(Frame, Package);
        paUninstall: UpdateFrame(Frame, Package);
      end;
    end
    else
    if Frame.PackageClass = TDependentPackage then
    begin
      case PackageHandle.PackageAction of
        paInstall:
          begin
            Package := FindDependentPackage(PackageHandle.PackageID);
            UpdateFrame(Frame, Package);
          end;
        paUninstall: DeleteFrame(Frame);
      end;
    end
    else
      raise Exception.Create('TDPMForm.UpdateFrames: not implemented PackageClass');
  end;
end;

{procedure SaveLayout(const aControls: TArray<TWinControl>);

procedure TDPMForm.SaveLayout(const aControls: TArray<TWinControl>);
begin
end;
}

end.
