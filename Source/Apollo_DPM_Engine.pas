unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_GitHubAPI,
  Apollo_DPM_Package,
  System.SysUtils,
  ToolsAPI,
  Vcl.Menus;

type
  TUINotifyProc = procedure(const aMsg: string) of object;

  TDPMEngine = class;

  TCompileNotifier = class(TInterfacedObject, IOTACompileNotifier)
  private
    FDPMEngine: TDPMEngine;
  protected
    procedure ProjectCompileStarted(const Project: IOTAProject; Mode: TOTACompileMode);
    procedure ProjectCompileFinished(const Project: IOTAProject; Result: TOTACompileResult);
    procedure ProjectGroupCompileStarted(Mode: TOTACompileMode);
    procedure ProjectGroupCompileFinished(Result: TOTACompileResult);
  end;

  TDPMEngine = class
  private
    FCompileServices: IOTACompileServices;
    FGHAPI: TGHAPI;
    FNotifierIndex: Integer;
    FNTAServices: INTAServices;
    FProjectPackages: TPackageList;
    FPublicPackages: TPackageList;
    FUINotifyProc: TUINotifyProc;
    function CreatePackageList(const aJSONString: string): TPackageList;
    function GetActiveProject: IOTAProject;
    function GetActiveProjectPath: string;
    function GetApolloMenuItem: TMenuItem;
    function GetFileSize(const aPath: string): Int64;
    function GetIDEMainMenu: TMainMenu;
    function GetPackagePath(aPackage: TPackage): string;
    function GetPackagesJSONString(aPackageList: TPackageList): string;
    function GetProjectPackagesFilePath: string;
    function GetVendorsPath: string;
    function SaveContent(const aVendorPath, aRepoPath, aContent: string): string;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure BuildBIN(const aTargetPath: string);
    procedure BuildMenu;
    procedure DPMMenuItemClick(Sender: TObject);
    procedure WriteFile(const aFilePath: string; aBytes: TBytes);
  public
    function GetProjectPackageList: TPackageList;
    function GetPublicPackages: TPackageList;
    function GetPackageVersions(aPackage: TPackage): TArray<TVersion>;
    function IsProjectOpened: Boolean;
    function LoadRepoData(const aRepoURL: string; out aOwner, aRepo, aError: string): Boolean;
    procedure InstallPackage(aVersionName: string; aPackage: TPackage);
    procedure SavePackage(aPackage: TPackage; const aPath: string);
    procedure SavePackages(aPackageList: TPackageList; const aPath: string);
    constructor Create(aBorlandIDEServices: IBorlandIDEServices);
    destructor Destroy; override;
  end;

const
  cApolloDPMPublicPackagesPath = '/master/Public/PublicPackages.json';
  cApolloDPMPrivatePackagesPath = 'PrivatePackages.json';
  cApolloDPMProjectPackagesPath = 'ProjectPackages.json';
  cApolloDPMRepo = 'apollo-dpm';
  cApolloLibOwner = 'apollo-delphi';
  cApolloMenuItemCaption = 'Apollo';
  cApolloMenuItemName = 'miApollo';
  cDPMMenuItemCaption = 'DPM - Delphi Package Manager...';

  cEmptyPackagesFileContent = '{"packages": []}';

  cCustomRevision = 'rev.';
  cLatestVersion = 'latest version';
  cLatestRevision = 'latest revision';

implementation

uses
  Apollo_DPM_Form,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.NetEncoding;

{ TDPMEngine }

procedure TDPMEngine.AddApolloMenuItem;
var
  ApolloItem: TMenuItem;
begin
  ApolloItem := TMenuItem.Create(nil);
  ApolloItem.Name := cApolloMenuItemName;
  ApolloItem.Caption := cApolloMenuItemCaption;

  GetIDEMainMenu.Items.Insert(GetIDEMainMenu.Items.Count - 1, ApolloItem);
end;

procedure TDPMEngine.AddDPMMenuItem;
var
  DPMMenuItem: TMenuItem;
begin
  DPMMenuItem := TMenuItem.Create(nil);
  DPMMenuItem.Caption := cDPMMenuItemCaption;
  DPMMenuItem.OnClick := DPMMenuItemClick;

  GetApolloMenuItem.Add(DPMMenuItem);
end;

procedure TDPMEngine.BuildBIN(const aTargetPath: string);
var
  Directories: TArray<string>;
  Directory: string;
  Files: TArray<string>;
  Package: TPackage;
  ProjectPackages: TPackageList;
  sFile: string;
  sTargetFile: string;
begin
  ProjectPackages := GetProjectPackageList;

  for Package in ProjectPackages do
    begin
      Directories := TDirectory.GetDirectories(GetPackagePath(Package), 'BIN', TSearchOption.soAllDirectories);
      for Directory in Directories do
        begin
          Files := TDirectory.GetFiles(Directory, '*', TSearchOption.soAllDirectories);
          for sFile in Files do
            begin
              sTargetFile := aTargetPath + '\' + TPath.GetFileName(sFile);
              if (not TFile.Exists(sTargetFile)) or
                 (TFile.Exists(sTargetFile) and (GetFileSize(sTargetFile) <> GetFileSize(sFile)))
              then
                TFile.Copy(sFile, sTargetFile, True);
            end;
        end;
    end;
end;

procedure TDPMEngine.BuildMenu;
begin
  if GetApolloMenuItem = nil then
    AddApolloMenuItem;

  AddDPMMenuItem;
end;

constructor TDPMEngine.Create(aBorlandIDEServices: IBorlandIDEServices);
var
  CompileNotifier: TCompileNotifier;
begin
  FNTAServices := aBorlandIDEServices as INTAServices;

  FCompileServices := BorlandIDEServices as IOTACompileServices;
  CompileNotifier := TCompileNotifier.Create;
  CompileNotifier.FDPMEngine := Self;
  FNotifierIndex := FCompileServices.AddNotifier(CompileNotifier);

  FGHAPI := TGHAPI.Create;
  FPublicPackages := nil;
  FProjectPackages := nil;

  if FNTAServices = nil then
    Exit;

  BuildMenu;
end;

function TDPMEngine.LoadRepoData(const aRepoURL: string; out aOwner, aRepo, aError: string): Boolean;
var
  RepoURL: string;
  SHA: string;
  URLWords: TArray<string>;
begin
  Result := False;
  RepoURL := aRepoURL;
  aOwner := '';
  aRepo := '';
  aError := '';

  if RepoURL.Contains('://') then
    RepoURL := RepoURL.Substring(RepoURL.IndexOf('://') + 3, RepoURL.Length);
  URLWords := RepoURL.Split(['/']);

  if (not (Length(URLWords) >= 3)) or
   ((Length(URLWords) > 0) and (URLWords[0].ToLower <> 'github.com'))
  then
    begin
      aError := 'The repo URL is invalid!';
      Exit;
    end;

  try
    SHA := FGHAPI.GetMasterBranchSHA(URLWords[1], URLWords[2]);
  except
    aError := 'Can`t load the repo URL!';
    Exit;
  end;

  if SHA.IsEmpty then
    Exit;

  Result := True;
  aOwner := URLWords[1];
  aRepo := URLWords[2];
end;

destructor TDPMEngine.Destroy;
begin
  FCompileServices.RemoveNotifier(FNotifierIndex);

  if GetApolloMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetApolloMenuItem);

  FGHAPI.Free;

  if Assigned(FPublicPackages) then
    FreeAndNil(FPublicPackages);

  if Assigned(FProjectPackages) then
    FreeAndNil(FProjectPackages);

  inherited;
end;

procedure TDPMEngine.DPMMenuItemClick(Sender: TObject);
var
  DPMForm: TDPMForm;
begin
  DPMForm := TDPMForm.Create(Self);
  try
    FUINotifyProc := DPMForm.NotifyListener;
    DPMForm.ShowModal;
  finally
    FUINotifyProc := nil;
    DPMForm.Free;
  end;
end;

function TDPMEngine.GetActiveProject: IOTAProject;
var
  i: Integer;
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  Project: IOTAProject;
  ProjectGroup: IOTAProjectGroup;
begin
  Result := nil;

  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  for i := 0 to ModuleServices.ModuleCount - 1 do
  begin
    Module := ModuleServices.Modules[i];
    if Supports(Module, IOTAProjectGroup, ProjectGroup) then
      Exit(ProjectGroup.ActiveProject)
    else
    if Supports(Module, IOTAProject, Project) then
      Exit(Project);
  end;
end;

function TDPMEngine.GetActiveProjectPath: string;
begin
  Result := TDirectory.GetParent(GetActiveProject.FileName);
end;

function TDPMEngine.GetApolloMenuItem: TMenuItem;
var
  MenuItem: TMenuItem;
begin
  Result := nil;

  for MenuItem in GetIDEMainMenu.Items do
    if MenuItem.Name = cApolloMenuItemName then
      Exit(MenuItem);
end;

function TDPMEngine.GetFileSize(const aPath: string): Int64;
var
  FS: TFileStream;
begin
  FS := TFile.Open(aPath, TFileMode.fmOpen);
  try
    Result := FS.Size;
  finally
    FS.Free;
  end;
end;

function TDPMEngine.GetIDEMainMenu: TMainMenu;
begin
  Result := FNTAServices.MainMenu;
end;

function TDPMEngine.CreatePackageList(const aJSONString: string): TPackageList;
var
  jsnPackageVal: TJSONValue;
  jsnPackagerArr: TJSONArray;
  jsnPackagesObj: TJSONObject;
  Package: TPackage;
begin
  Result := TPackageList.Create;

  jsnPackagesObj := TJSONObject.ParseJSONValue(aJSONString) as TJSONObject;
  try
    jsnPackagerArr := jsnPackagesObj.GetValue('packages') as TJSONArray;
    for jsnPackageVal in jsnPackagerArr do
      begin
        Package := TPackage.Create(jsnPackageVal as TJSONObject);
        Result.Add(Package);
      end;
  finally
    jsnPackagesObj.Free;
  end;
end;

function TDPMEngine.GetPackagePath(aPackage: TPackage): string;
begin
  Result := GetVendorsPath + '\' + aPackage.Name;
end;

function TDPMEngine.GetPackagesJSONString(aPackageList: TPackageList): string;
var
  jsnPackageObj: TJSONObject;
  jsnPackagesObj: TJSONObject;
  jsnPackagerArr: TJSONArray;
  Package: TPackage;
begin
  jsnPackagesObj := TJSONObject.Create;
  try
    jsnPackagerArr := TJSONArray.Create;
    jsnPackagesObj.AddPair('packages', jsnPackagerArr);

    for Package in aPackageList do
      begin
        jsnPackageObj := Package.CreateJSON;
        jsnPackagerArr.AddElement(jsnPackageObj);
      end;

    Result := jsnPackagesObj.ToJSON;
  finally
    jsnPackagesObj.Free;
  end;
end;

function TDPMEngine.GetPackageVersions(aPackage: TPackage): TArray<TVersion>;
var
  Tag: TTag;
  Tags: TArray<TTag>;
  Version: TVersion;
begin
  Result := [];

  Tags := FGHAPI.GetRepoTags(aPackage.Owner, aPackage.Repo);

  for Tag in Tags do
    begin
      Version.Name := Tag.Name;
      Version.SHA := Tag.SHA;

      Result := Result + [Version];
    end;

  aPackage.Versions := Result;
end;

function TDPMEngine.GetProjectPackagesFilePath: string;
begin
  Result := GetActiveProjectPath + '\' + cApolloDPMProjectPackagesPath;
end;

function TDPMEngine.GetProjectPackageList: TPackageList;
var
  sPackagesJSON: string;
begin
  if Assigned(FProjectPackages) then
    FreeAndNil(FProjectPackages);

  if not TFile.Exists(GetProjectPackagesFilePath) then
    sPackagesJSON := cEmptyPackagesFileContent
  else
    sPackagesJSON := TFile.ReadAllText(GetProjectPackagesFilePath, TEncoding.ANSI);

  Result := CreatePackageList(sPackagesJSON);
  FProjectPackages := Result;
end;

function TDPMEngine.GetPublicPackages: TPackageList;
var
  sPackagesJSON: string;
begin
  if FPublicPackages = nil then
    begin
      sPackagesJSON := FGHAPI.GetTextFileContent(
        cApolloLibOwner,
        cApolloDPMRepo,
        cApolloDPMPublicPackagesPath
      );

      Result := CreatePackageList(sPackagesJSON);

      FPublicPackages := Result;
    end
  else
    Result := FPublicPackages;
end;

function TDPMEngine.GetVendorsPath: string;
begin
  Result := TDirectory.GetParent(GetActiveProjectPath) + '\Vendors';
end;

procedure TDPMEngine.InstallPackage(aVersionName: string; aPackage: TPackage);
var
  Blob: TBlob;
  Extension: string;
  FilePath: string;
  InstalledPackage: TPackage;
  InstalledVersion: TVersion;
  NodePath: string;
  ProjectPackageList: TPackageList;
  RepoTree: TTree;
  TreeNode: TTreeNode;
  VersionSHA: string;
begin
  FUINotifyProc(Format(#13#10 + 'Installing Package %s...', [aPackage.Name]));

  if aVersionName = cLatestVersion then
    begin
      GetPackageVersions(aPackage);
      if Length(aPackage.Versions) > 0 then
        begin
          VersionSHA := aPackage.Versions[0].SHA;
          aVersionName := aPackage.Versions[0].Name;
        end
      else
        aVersionName := cLatestRevision;
    end;

  if aVersionName = cLatestRevision then
    begin
      VersionSHA := FGHAPI.GetMasterBranchSHA(aPackage.Owner, aPackage.Repo);
      aVersionName := cCustomRevision;
    end
  else
    begin
      VersionSHA := aPackage.Version[aVersionName].SHA;
      aVersionName := aPackage.Version[aVersionName].Name;
    end;

  RepoTree := FGHAPI.GetRepoTree(aPackage.Owner, aPackage.Repo, VersionSHA);

  for TreeNode in RepoTree do
    begin
      if TreeNode.FileType <> 'blob' then
        Continue;

      if aPackage.AllowPath(TreeNode.Path) then
        begin
          Blob := FGHAPI.GetRepoBlob(TreeNode.URL);

          NodePath := aPackage.ApplyMoves(TreeNode.Path);
          FilePath := SaveContent(GetPackagePath(aPackage), NodePath, Blob.Content);
          Extension := TPath.GetExtension(FilePath);

          if Extension = '.pas' then
            GetActiveProject.AddFile(FilePath, True);
        end;
    end;

  InstalledPackage := TPackage.Create(aPackage);
  InstalledVersion.Name := aVersionName;
  InstalledVersion.SHA := VersionSHA;
  InstalledPackage.InstalledVersion := InstalledVersion;

  ProjectPackageList := GetProjectPackageList;
  ProjectPackageList.Add(InstalledPackage);
  SavePackages(ProjectPackageList, cApolloDPMProjectPackagesPath);

  GetActiveProject.Save(False, True);

  FUINotifyProc('Success');
end;

function TDPMEngine.IsProjectOpened: Boolean;
begin
  Result := GetActiveProject <> nil;
end;

function TDPMEngine.SaveContent(const aVendorPath, aRepoPath,
  aContent: string): string;
var
  Bytes: TBytes;
  RepoPathPart: string;
  RepoPathParts: TArray<string>;
begin
  Result := aVendorPath;
  RepoPathParts := aRepoPath.Split(['/']);

  for RepoPathPart in RepoPathParts do
    Result := Result + '\' + RepoPathPart;

  Bytes := TNetEncoding.Base64.DecodeStringToBytes(aContent);

  FUINotifyProc('write ' + Result);

  WriteFile(Result, Bytes);
end;

procedure TDPMEngine.SavePackage(aPackage: TPackage; const aPath: string);
var
  Bytes: TBytes;
  jsnPackageObj: TJSONObject;
begin
  jsnPackageObj := aPackage.CreateJSON;
  try
    Bytes := TEncoding.ANSI.GetBytes(jsnPackageObj.ToJSON);

    WriteFile(aPath, Bytes);
  finally
    jsnPackageObj.Free;
  end;
end;

procedure TDPMEngine.SavePackages(aPackageList: TPackageList;
  const aPath: string);
var
  Bytes: TBytes;
  sJSONObj: string;
begin
  sJSONObj := GetPackagesJSONString(aPackageList);

  Bytes := TEncoding.ANSI.GetBytes(sJSONObj);

  WriteFile(aPath, Bytes);
end;

procedure TDPMEngine.WriteFile(const aFilePath: string; aBytes: TBytes);
var
  FS: TFileStream;
begin
  ForceDirectories(TDirectory.GetParent(aFilePath));

  FS := TFile.Create(aFilePath);
  try
    FS.Position := FS.Size;
    FS.Write(aBytes[0], Length(aBytes));
  finally
    FS.Free;
  end;
end;

{ TCompileNotifier }

procedure TCompileNotifier.ProjectCompileFinished(const Project: IOTAProject;
  Result: TOTACompileResult);
begin
end;

procedure TCompileNotifier.ProjectCompileStarted(const Project: IOTAProject;
  Mode: TOTACompileMode);
begin
  FDPMEngine.BuildBIN(TDirectory.GetParent(Project.ProjectOptions.TargetName));
end;

procedure TCompileNotifier.ProjectGroupCompileFinished(
  Result: TOTACompileResult);
begin
end;

procedure TCompileNotifier.ProjectGroupCompileStarted(Mode: TOTACompileMode);
begin
end;

end.
