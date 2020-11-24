unit Apollo_DPM_Form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.WinXCtrls, Vcl.Buttons, System.Actions, Vcl.ActnList, System.ImageList,
  Vcl.ImgList,
  Apollo_DPM_Engine,
  Apollo_DPM_Package;

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
    actNewPackage: TAction;
    procedure pnlDetailsSwitcherClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure swPackageDetailsOpened(Sender: TObject);
    procedure swPackageDetailsClosed(Sender: TObject);
    procedure tvNavigationCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure actNewPackageExecute(Sender: TObject);
    procedure tvNavigationChange(Sender: TObject; Node: TTreeNode);
  private
    FDPMEngine: TDPMEngine;
    FFrames: TArray<TFrame>;
    function GetSelectedNavigation: string;
    procedure ClearFrames;
    procedure RenderNavigation;
    procedure RenderPackageList(aPackageList: TPackageList);
    procedure RenderPackages;
  public
    constructor Create(aDPMEngine: TDPMEngine); reintroduce;
  end;

var
  DPMForm: TDPMForm;

implementation

{$R *.dfm}

uses
  Apollo_DPM_Consts,
  Apollo_DPM_PackageForm,
  Apollo_DPM_PackageFrame;

{ TDPMForm }

procedure TDPMForm.actNewPackageExecute(Sender: TObject);
var
  Package: TPackage;
begin
  Package := TPackage.Create;
  PackageForm := TPackageForm.Create(Self, Package);
  try
    if PackageForm.ShowModal = mrOk then
    begin
      FDPMEngine.AddNewPrivatePackage(Package);
      RenderPackages;
    end
    else
      Package.Free;
  finally
    PackageForm.Free;
  end;
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

procedure TDPMForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 //SaveLayout([Self, splHorizontal, splVertical, swPackageDetail]);
end;

function TDPMForm.GetSelectedNavigation: string;
begin
  Result := '';

  if tvNavigation.Selected <> nil then
    Result := tvNavigation.Selected.Text;
end;

procedure TDPMForm.pnlDetailsSwitcherClick(Sender: TObject);
begin
  swPackageDetails.Opened := swPackageDetails.Opened <> True;
end;

procedure TDPMForm.RenderNavigation;
begin
  tvNavigation.Items.Add(nil, cNavPrivatePackages);
  tvNavigation.Items.Add(nil, cNavSettings);
end;

procedure TDPMForm.RenderPackageList(aPackageList: TPackageList);
var
  i: Integer;
  Package: TPackage;
  PackageFrame: TfrmPackage;
  Top: Integer;
begin
  i := 0;
  Top := 0;

  for Package in aPackageList do
  begin
    PackageFrame := TfrmPackage.Create(sbFrames, Package);
    PackageFrame.Name := Format('PackageFrame%d', [i]);
    PackageFrame.Parent := sbFrames;
    PackageFrame.Top := Top;
    PackageFrame.Left := 0;
    if not Odd(i) then
      PackageFrame.Color := clBtnFace;

    Inc(i);
    Top := Top + PackageFrame.Height + 1;
    FFrames := FFrames + [PackageFrame];
  end;
end;

procedure TDPMForm.RenderPackages;
begin
  ClearFrames;

  if GetSelectedNavigation = cNavPrivatePackages then
    RenderPackageList(FDPMEngine.GetPrivatePackages);
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
