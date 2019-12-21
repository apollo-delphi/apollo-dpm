unit Apollo_DPM_Form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.WinXCtrls,
  Apollo_DPM_Engine,
  Apollo_DPM_Package;

type
  TGetVersionsFunc = function(aPackage: TPackage): TArray<TVersion> of object;
  TActionProc = procedure(const aVersionName: string; aPackage: TPackage) of object;

  TDPMForm = class(TForm)
    pnlMain: TPanel;
    sbPackages: TScrollBox;
    tvStructure: TTreeView;
    splStruct2Grid: TSplitter;
    aiPabPkgLoad: TActivityIndicator;
    mmoActionLog: TMemo;
    splMain2Log: TSplitter;
    procedure tvStructureCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure tvStructureChange(Sender: TObject; Node: TTreeNode);
  private
    { Private declarations }
    FDPMEngine: TDPMEngine;
    FPackageFrames: TArray<TFrame>;
    function GetVersionsFunc(aPackage: TPackage): TArray<TVersion>;
    procedure ActionProc(const aVersionName: string; aPackage: TPackage);
    procedure AsyncLoadPublishedPackages;
    procedure ClearPackageFrames;
    procedure RenderPackageList(aPackageList: TPackageList);
    procedure RenderStructureTree;
  public
    { Public declarations }
    procedure NotifyListener(const aMsg: string);
    constructor Create(aDPMEngine: TDPMEngine); reintroduce;
  end;

const
  cProjectDependencies = 'Project Dependencies';
  cIDEDependencies = 'IDE Dependencies';
  cPublishedPackages = 'Published Packages';

var
  DPMForm: TDPMForm;

implementation

{$R *.dfm}

uses
  Apollo_DPM_PackageFrame,
  System.Threading;

{ TDPMForm }

procedure TDPMForm.ActionProc(const aVersionName: string; aPackage: TPackage);
begin
  FDPMEngine.InstallPackage(aVersionName, aPackage);
end;

procedure TDPMForm.AsyncLoadPublishedPackages;
var
  AsyncTask: ITask;
  PublishedPackages: TPackageList;
begin
  AsyncTask := TTask.Create(procedure()
    begin
      PublishedPackages := FDPMEngine.GetPublishedPackages;

      TThread.Synchronize(nil, procedure()
        begin
          aiPabPkgLoad.Animate := False;
          RenderPackageList(PublishedPackages);
        end
      );
    end
  );
  AsyncTask.Start;
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

function TDPMForm.GetVersionsFunc(aPackage: TPackage): TArray<TVersion>;
begin
  Result := FDPMEngine.GetPackageVersions(aPackage);
end;

procedure TDPMForm.NotifyListener(const aMsg: string);
begin
  mmoActionLog.Lines.Add(aMsg);
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
      PackageFrame := TfrmPackage.Create(sbPackages, Package);
      PackageFrame.Name := Format('PackageFrame%d', [i]);
      PackageFrame.Parent := sbPackages;
      PackageFrame.Top := Top;
      PackageFrame.Left := 0;
      PackageFrame.GetVersionsFunc := GetVersionsFunc;
      PackageFrame.ActionProc := ActionProc;

      Inc(i);
      Top := Top + PackageFrame.Height + 1;
      FPackageFrames := FPackageFrames + [PackageFrame];
    end;
end;

procedure TDPMForm.RenderStructureTree;
begin
  tvStructure.Items.Add(nil, cProjectDependencies);
  tvStructure.Items.Add(nil, cIDEDependencies);
  tvStructure.Items.Add(nil, cPublishedPackages);
end;

procedure TDPMForm.tvStructureChange(Sender: TObject; Node: TTreeNode);
begin
  ClearPackageFrames;

  if Node.Text = cPublishedPackages then
    begin
      aiPabPkgLoad.Animate := True;
      AsyncLoadPublishedPackages;
    end
  else
  if Node.Text = cProjectDependencies then
    RenderPackageList(FDPMEngine.GetProjectPackageList);
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

end.
