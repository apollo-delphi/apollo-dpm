unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_GitHubAPI,
  Apollo_DPM_Package,
  ToolsAPI,
  Vcl.Menus;

type
  TUINotifyProc = procedure(const aMsg: string) of object;

  TDPMEngine = class
  private
    FGHAPI: TGHAPI;
    FNTAServices: INTAServices;
    FProjectPackages: TPackageList;
    FPublishedPackages: TPackageList;
    FUINotifyProc: TUINotifyProc;
    function CreatePackageList(const aJSONString: string): TPackageList;
    function GetActiveProject: IOTAProject;
    function GetActiveProjectPath: string;
    function GetApolloMenuItem: TMenuItem;
    function GetIDEMainMenu: TMainMenu;
    function GetPackagesJSONString(aPackageList: TPackageList): string;
    function GetProjectPackagesFilePath: string;
    function GetVendorsPath: string;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure BuildMenu;
    procedure DPMMenuItemClick(Sender: TObject);
    procedure SaveContent(const aVendorPath, aRepoPath, aContent: string);
    procedure SaveProjectPackages(aPackageList: TPackageList);
    procedure WriteFile(const aFilePath, aContent: string);
  public
    function GetProjectPackageList: TPackageList;
    function GetPublishedPackages: TPackageList;
    function GetPackageVersions(aPackage: TPackage): TArray<TVersion>;
    procedure InstallPackage(const aVersionName: string; aPublishedPackage: TPackage);
    constructor Create(aNTAServices: INTAServices);
    destructor Destroy; override;
  end;

const
  cApolloDPMPablishedPackagePath = '/master/Published/packages.json';
  cApolloDPMProjectPackagePath = 'packages.json';
  cApolloDPMRepo = 'apollo-dpm';
  cApolloLibOwner = 'apollo-delphi';
  cApolloMenuItemCaption = 'Apollo';
  cApolloMenuItemName = 'miApollo';
  cDPMMenuItemCaption = 'DPM - Delphi Package Manager...';

  cEmptyPackagesFileContent = '{"packages": []}';
  cPackageCurrentRevision = 'current revision';

implementation

uses
  Apollo_DPM_Form,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.NetEncoding,
  System.SysUtils;

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

procedure TDPMEngine.BuildMenu;
begin
  if GetApolloMenuItem = nil then
    AddApolloMenuItem;

  AddDPMMenuItem;
end;

constructor TDPMEngine.Create(aNTAServices: INTAServices);
begin
  FNTAServices := aNTAServices;
  FGHAPI := TGHAPI.Create;
  FPublishedPackages := nil;
  FProjectPackages := nil;

  if FNTAServices = nil then
    Exit;

  BuildMenu;
end;

destructor TDPMEngine.Destroy;
begin
  if GetApolloMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetApolloMenuItem);

  FGHAPI.Free;

  if Assigned(FPublishedPackages) then
    FreeAndNil(FPublishedPackages);

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
  //Result := [cPackageCurrentRevision];

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
  Result := GetActiveProjectPath + '\' + cApolloDPMProjectPackagePath;
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
    sPackagesJSON := TFile.ReadAllText(GetProjectPackagesFilePath, TEncoding.Unicode);

  Result := CreatePackageList(sPackagesJSON);
  FProjectPackages := Result;
end;

function TDPMEngine.GetPublishedPackages: TPackageList;
var
  sPackagesJSON: string;
begin
  if FPublishedPackages = nil then
    begin
      sPackagesJSON := FGHAPI.GetTextFileContent(
        cApolloLibOwner,
        cApolloDPMRepo,
        cApolloDPMPablishedPackagePath
      );

      Result := CreatePackageList(sPackagesJSON);

      FPublishedPackages := Result;
    end
  else
    Result := FPublishedPackages;
end;

function TDPMEngine.GetVendorsPath: string;
begin
  Result := GetActiveProjectPath + '\Vendors';
end;

procedure TDPMEngine.InstallPackage(const aVersionName: string; aPublishedPackage: TPackage);
var
  Blob: TBlob;
  Content: string;
  InstalledPackage: TPackage;
  ProjectPackageList: TPackageList;
  RepoTree: TTree;
  TreeNode: TTreeNode;
  VendorPath: string;
  VersionSHA: string;
begin
  FUINotifyProc(Format(#13#10 + 'Installing Package %s...', [aPublishedPackage.Name]));

  VersionSHA := aPublishedPackage.Version[aVersionName].SHA;
  VendorPath := GetVendorsPath + '\' + aPublishedPackage.Name;

  RepoTree := FGHAPI.GetRepoTree(aPublishedPackage.Owner, aPublishedPackage.Repo, VersionSHA);

  for TreeNode in RepoTree do
    begin
      if TreeNode.FileType <> 'blob' then
        Continue;

      if not aPublishedPackage.IsIgnorePath(TreeNode.Path) then
        begin
          Blob := FGHAPI.GetRepoBlob(TreeNode.URL);
          Content := TNetEncoding.Base64.Decode(Blob.Content);

          SaveContent(VendorPath, TreeNode.Path, Content);
        end;
    end;

  ProjectPackageList := GetProjectPackageList;
  InstalledPackage := TPackage.Create(aPublishedPackage);
  ProjectPackageList.Add(InstalledPackage);
  SaveProjectPackages(ProjectPackageList);

  FUINotifyProc('Success');
end;

procedure TDPMEngine.SaveContent(const aVendorPath, aRepoPath,
  aContent: string);
var
  Path: string;
  RepoPathPart: string;
  RepoPathParts: TArray<string>;
begin
  Path := aVendorPath;
  RepoPathParts := aRepoPath.Split(['/']);

  for RepoPathPart in RepoPathParts do
    Path := Path + '\' + RepoPathPart;

  FUINotifyProc('write ' + Path);

  WriteFile(Path, aContent);
end;

procedure TDPMEngine.SaveProjectPackages(aPackageList: TPackageList);
var
  sJSONObj: string;
begin
  sJSONObj := GetPackagesJSONString(aPackageList);

  WriteFile(GetProjectPackagesFilePath, sJSONObj);
end;

procedure TDPMEngine.WriteFile(const aFilePath, aContent: string);
var
  FS: TFileStream;
begin
  ForceDirectories(TDirectory.GetParent(aFilePath));

  FS := TFile.Create(aFilePath);
  try
    FS.Position := FS.Size;
    FS.Write(aContent[1], Length(aContent) * SizeOf(Char));
  finally
    FS.Free;
  end;
end;

end.
