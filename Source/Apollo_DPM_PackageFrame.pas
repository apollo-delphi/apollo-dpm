unit Apollo_DPM_PackageFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.WinXCtrls,
  Vcl.Menus,
  Apollo_DPM_Form,
  Apollo_DPM_Package;

type
  TfrmPackage = class(TFrame)
    lblPackageDescription: TLabel;
    btnInstall: TButton;
    cbbVersions: TComboBox;
    lblVersion: TLabel;
    aiVerListLoad: TActivityIndicator;
    pmActions: TPopupMenu;
    mniAdd: TMenuItem;
    mniPackageSettings: TMenuItem;
    mniRemove: TMenuItem;
    mniUpgrade: TMenuItem;
    lblInstalled: TLabel;
    lblVersionlDescribe: TLabel;
    procedure cbbVersionsDropDown(Sender: TObject);
    procedure mniAddClick(Sender: TObject);
    procedure mniPackageSettingsClick(Sender: TObject);
    procedure mniRemoveClick(Sender: TObject);
    procedure cbbVersionsChange(Sender: TObject);
  private
    { Private declarations }
    FActionProc: TActionProc;
    FAllowAction: TAllowActionFunc;
    FFilledVersions: TArray<TVersion>;
    FGetVersionsFunc: TGetVersionsFunc;
    FPackage: TPackage;
    function GetIndexByVersion(aVersion: TVersion): Integer;
    function GetVersionByIndex(const aIndex: Integer): TVersion;
    procedure FillVersions;
    procedure InitActions;
    procedure SetVersionDescribe;
  public
    { Public declarations }
    function IsShowThisPackage(aPackage: TPackage): Boolean;
    procedure InitState;
    constructor Create(AOwner: TComponent; aPackage: TPackage;
      aActionProc: TActionProc; aGetVersionsFunc: TGetVersionsFunc;
      aAllowAction: TAllowActionFunc); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  Apollo_DPM_Engine,
  System.Threading;

{$R *.dfm}

{ TfrmPackage }

procedure TfrmPackage.cbbVersionsChange(Sender: TObject);
begin
  InitState;
end;

procedure TfrmPackage.cbbVersionsDropDown(Sender: TObject);
var
  AsyncTask: ITask;
  Versions: TArray<TVersion>;
begin
  aiVerListLoad.Animate := True;

  AsyncTask := TTask.Create(procedure()
    begin
      Versions := FGetVersionsFunc(FPackage);

      TThread.Synchronize(nil, procedure()
        begin
          aiVerListLoad.Animate := False;

          FillVersions;
        end
      );
    end
  );
  AsyncTask.Start;
end;

constructor TfrmPackage.Create(AOwner: TComponent; aPackage: TPackage;
      aActionProc: TActionProc; aGetVersionsFunc: TGetVersionsFunc;
      aAllowAction: TAllowActionFunc);
begin
  inherited Create(AOwner);

  FPackage := TPackage.Create(aPackage);
  FActionProc := aActionProc;
  FAllowAction := aAllowAction;
  FGetVersionsFunc := aGetVersionsFunc;

  lblPackageDescription.Caption := FPackage.Description;

  FillVersions;
  InitState;
end;

destructor TfrmPackage.Destroy;
begin
  FPackage.Free;

  inherited;
end;

procedure TfrmPackage.FillVersions;
var
  i: Integer;
  VersionIndex: Integer;
begin
  FFilledVersions := [];
  cbbVersions.Items.Clear;
  for i := 0 to Length(FPackage.Versions) - 1 do
    begin
      cbbVersions.Items.Add(FPackage.Versions[i].DisplayName);
      FFilledVersions := FFilledVersions + [FPackage.Versions[i]];
    end;

  cbbVersions.Items.Add(cLatestCommit);

  VersionIndex := GetIndexByVersion(FPackage.InstalledVersion);
  if VersionIndex >= 0 then
    cbbVersions.ItemIndex := VersionIndex;
end;

function TfrmPackage.GetIndexByVersion(aVersion: TVersion): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := 0 to Length(FFilledVersions) - 1 do
    if FFilledVersions[i].SHA = aVersion.SHA then
      Exit(i);
end;

function TfrmPackage.GetVersionByIndex(const aIndex: Integer): TVersion;
var
  i: Integer;
begin
  Result.Init;

  for i := 0 to Length(FFilledVersions) do
    if i = aIndex then
      Exit(FFilledVersions[i]);
end;

procedure TfrmPackage.InitActions;
begin
  mniAdd.Visible := FAllowAction(FPackage, atAdd);
  mniRemove.Visible := FAllowAction(FPackage, atRemove);
  mniUpgrade.Visible := FAllowAction(FPackage, atUpgrade);
  mniPackageSettings.Visible := FAllowAction(FPackage, atPackageSettings);
end;

procedure TfrmPackage.InitState;
begin
  InitActions;
  SetVersionDescribe;
end;

function TfrmPackage.IsShowThisPackage(aPackage: TPackage): Boolean;
begin
  Result := aPackage.Name = FPackage.Name;
end;

procedure TfrmPackage.mniAddClick(Sender: TObject);
begin
  FActionProc(atAdd, cbbVersions.Text, FPackage);
end;

procedure TfrmPackage.mniPackageSettingsClick(Sender: TObject);
begin
  FActionProc(atPackageSettings, cbbVersions.Text, FPackage);
end;

procedure TfrmPackage.mniRemoveClick(Sender: TObject);
begin
  FActionProc(atRemove, cbbVersions.Text, FPackage);
end;

procedure TfrmPackage.SetVersionDescribe;
var
  Version: TVersion;
begin
  lblVersionlDescribe.Caption := '';
  lblVersionlDescribe.Font.Color := clWindowText;
  Version := GetVersionByIndex(cbbVersions.ItemIndex);

  if (not FPackage.InstalledVersion.IsEmpty) and
     (FPackage.InstalledVersion.SHA = Version.SHA)
  then
    begin
      lblVersionlDescribe.Caption := Format('was installed at %s',
        [FormatDateTime('hh:mm:ss ddddd', Version.InstallTime)]);
      lblVersionlDescribe.Font.Color := clGreen;
    end;
end;

end.
