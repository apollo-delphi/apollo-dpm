unit Apollo_DPM_Form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.WinXCtrls,
  Apollo_DPM_Engine,
  Apollo_DPM_Package;

type
  TLoadRepoVersionsProc = procedure(aPackage: TPackage) of object;
  TActionProc = procedure(const aActionType: TActionType;
    const aDisplayVersionName: string; aPackage: TPackage) of object;
  TAllowActionFunc = function(aPackage: TPackage; const aActionType: TActionType): Boolean of object;

  TDPMForm = class(TForm)
    pnlMain: TPanel;
    sbPackages: TScrollBox;
    tvStructure: TTreeView;
    splStruct2Grid: TSplitter;
    aiPabPkgLoad: TActivityIndicator;
    mmoActionLog: TMemo;
    splMain2Log: TSplitter;
    pnlButtons: TPanel;
    pnlContent: TPanel;
    btnRegisterPackage: TButton;
    fodSelectProjectFolder: TFileOpenDialog;
    procedure tvStructureCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure tvStructureChange(Sender: TObject; Node: TTreeNode);
    procedure btnRegisterPackageClick(Sender: TObject);
  private
    { Private declarations }
    FDPMEngine: TDPMEngine;
    FPackageFrames: TArray<TFrame>;
    function AllowAction(aPackage: TPackage; const aActionType: TActionType): Boolean;
    function GetFrameByPackage(aPackage: TPackage): TFrame;
    procedure ActionProc(const aActionType: TActionType;
      const aDisplayVersionName: string; aPackage: TPackage);
    procedure AsyncLoadPublicPackages;
    procedure ClearPackageFrames;
    procedure LoadRepoVersions(aPackage: TPackage);
    procedure RenderPackageList(aPackageList: TPackageList);
    procedure RenderPackages;
    procedure RenderStructureTree;
    procedure SetPackageSettings(aPackage: TPackage);
  public
    { Public declarations }
    function GetFolder: string;
    function SelectedStructure: string;
    procedure NotifyListener(const aMsg: string);
    procedure UpdateListener(aPackage: TPackage; aActionType: TActionType);
    constructor Create(aDPMEngine: TDPMEngine); reintroduce;
  end;

const
  cProjectDependencies = 'Project Dependencies';
  cIDEDependencies = 'IDE Dependencies';
  cPublicPackages = 'Public Packages';

var
  DPMForm: TDPMForm;

implementation

{$R *.dfm}

uses
  Apollo_DPM_PackageForm,
  Apollo_DPM_PackageFrame,
  System.Threading;

{ TDPMForm }

procedure TDPMForm.ActionProc(const aActionType: TActionType;
  const aDisplayVersionName: string; aPackage: TPackage);
begin
  case aActionType of
    atAdd:  FDPMEngine.AddPackage(aDisplayVersionName, aPackage);
    atRemove: FDPMEngine.RemovePackage(aPackage);
    atPackageSettings: SetPackageSettings(aPackage);
  end;
end;

function TDPMForm.AllowAction(aPackage: TPackage;
  const aActionType: TActionType): Boolean;
begin
  Result := FDPMEngine.AllowAction(aPackage, aActionType);
end;

procedure TDPMForm.AsyncLoadPublicPackages;
var
  AsyncTask: ITask;
  PublicPackages: TPackageList;
begin
  AsyncTask := TTask.Create(procedure()
    begin
      PublicPackages := FDPMEngine.GetPublicPackages;

      TThread.Synchronize(nil, procedure()
        begin
          aiPabPkgLoad.Animate := False;
          RenderPackageList(PublicPackages);
        end
      );
    end
  );
  AsyncTask.Start;
end;

procedure TDPMForm.btnRegisterPackageClick(Sender: TObject);
begin
  SetPackageSettings(nil);
end;

procedure TDPMForm.ClearPackageFrames;
var
  i: Integer;
begin
  for i := 0 to Length(FPackageFrames) - 1 do
    FPackageFrames[i].Free;

  FPackageFrames := [];
end;

constructor TDPMForm.Create(aDPMEngine: TDPMEngine);
begin
  inherited Create(nil);

  FDPMEngine := aDPMEngine;

  FPackageFrames := [];
  RenderStructureTree;
end;

function TDPMForm.GetFolder: string;
begin
  Result := '';

  if fodSelectProjectFolder.Execute then
    Result := fodSelectProjectFolder.FileName;
end;

function TDPMForm.GetFrameByPackage(aPackage: TPackage): TFrame;
var
  i: Integer;
  PackageFrame: TfrmPackage;
begin
  Result := nil;

  for i := 0 to Length(FPackageFrames) - 1 do
    begin
      PackageFrame := FPackageFrames[i] as TfrmPackage;

      if PackageFrame.IsShowThisPackage(aPackage) then
        Exit(PackageFrame);
    end;
end;

procedure TDPMForm.LoadRepoVersions(aPackage: TPackage);
begin
  FDPMEngine.LoadRepoVersions(aPackage);
end;

procedure TDPMForm.NotifyListener(const aMsg: string);
begin
  mmoActionLog.Lines.Add(aMsg);
end;

procedure TDPMForm.RenderPackageList(aPackageList: TPackageList);
var
  i: Integer;
  Package: TPackage;
  PackageCopy: TPackage;
  PackageFrame: TfrmPackage;
  ProjectPackages: TPackageList;
  Top: Integer;
begin
  i := 0;
  Top := 0;
  ProjectPackages := FDPMEngine.GetProjectPackages(True);

  for Package in aPackageList do
    begin
      PackageCopy := TPackage.Create(Package);

      if PackageCopy.InstalledVersion.IsEmpty and
         Assigned(ProjectPackages)
      then
        ProjectPackages.SyncToSidePackage(PackageCopy);

      PackageFrame := TfrmPackage.Create(sbPackages, PackageCopy, ActionProc,
        LoadRepoVersions, AllowAction
      );
      PackageFrame.Name := Format('PackageFrame%d', [i]);
      PackageFrame.Parent := sbPackages;
      PackageFrame.Top := Top;
      PackageFrame.Left := 0;
      if not Odd(i) then
        PackageFrame.Color := clBtnFace;

      Inc(i);
      Top := Top + PackageFrame.Height + 1;
      FPackageFrames := FPackageFrames + [PackageFrame];
    end;
end;

procedure TDPMForm.RenderPackages;
begin
  ClearPackageFrames;

  if SelectedStructure = cPublicPackages then
    begin
      aiPabPkgLoad.Animate := True;
      AsyncLoadPublicPackages;
    end
  else
  if FDPMEngine.IsProjectOpened and (SelectedStructure = cProjectDependencies) then
    RenderPackageList(FDPMEngine.GetProjectPackages(True));

  btnRegisterPackage.Visible := SelectedStructure = cPublicPackages;
end;

procedure TDPMForm.RenderStructureTree;
begin
  tvStructure.Items.Add(nil, cProjectDependencies);
  tvStructure.Items.Add(nil, cIDEDependencies);
  tvStructure.Items.Add(nil, cPublicPackages);
end;

function TDPMForm.SelectedStructure: string;
begin
  Result := '';

  if tvStructure.Selected <> nil then
    Result := tvStructure.Selected.Text;
end;

procedure TDPMForm.SetPackageSettings(aPackage: TPackage);
var
  Package: TPackage;
  PackageForm: TPackageForm;
begin
  if aPackage = nil then
    Package := TPackage.Create
  else
    Package := aPackage;

  PackageForm := TPackageForm.Create(FDPMEngine, Package);
  try
    PackageForm.ShowModal;
  finally
    PackageForm.Free;
  end;

  if aPackage = nil then
    Package.Free;
end;

procedure TDPMForm.tvStructureChange(Sender: TObject; Node: TTreeNode);
begin
  RenderPackages;
end;

procedure TDPMForm.tvStructureCustomDrawItem(Sender: TCustomTreeView;
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

procedure TDPMForm.UpdateListener(aPackage: TPackage; aActionType: TActionType);
var
  PackageFrame: TfrmPackage;
begin
  case aActionType of
    atRemove:
      begin
        if SelectedStructure = cProjectDependencies then
          begin
            RenderPackages;
            Exit;
          end;
      end;
  end;

  PackageFrame := GetFrameByPackage(aPackage) as TfrmPackage;
  PackageFrame.Refresh;
end;

end.
