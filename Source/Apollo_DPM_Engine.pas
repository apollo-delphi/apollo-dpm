unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_Package,
  System.SysUtils,
  Vcl.Menus;

type
  TDPMEngine = class
  private
    FPrivatePackages: TPackageList;
    function GetApolloMenuItem: TMenuItem;
    function GetIDEMainMenu: TMainMenu;
    function GetPrivatePackagesPath: string;
    procedure BuildMenu;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure DPMMenuItemClick(Sender: TObject);
    procedure SavePackage(aPackage: TPackage);
    procedure WriteFile(const aPath: string; const aBytes: TBytes);
  public
    function GetPrivatePackages: TPackageList;
    procedure AddNewPrivatePackage(aPackage: TPackage);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Apollo_DPM_Consts,
  Apollo_DPM_Form,
  Apollo_DPM_Validation,
  System.Classes,
  System.IOUtils,
  ToolsAPI;

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

procedure TDPMEngine.AddNewPrivatePackage(aPackage: TPackage);
begin
  SavePackage(aPackage);
  GetPrivatePackages.Add(aPackage);
end;

procedure TDPMEngine.BuildMenu;
begin
  if GetApolloMenuItem = nil then
    AddApolloMenuItem;

  AddDPMMenuItem;
end;

constructor TDPMEngine.Create;
begin
  FPrivatePackages := nil;

  BuildMenu;

  Validation := TValidation.Create(Self);
end;

destructor TDPMEngine.Destroy;
begin
  Validation.Free;

  if Assigned(FPrivatePackages) then
    FPrivatePackages.Free;

  if GetApolloMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetApolloMenuItem);

  inherited;
end;

procedure TDPMEngine.DPMMenuItemClick(Sender: TObject);
begin
  DPMForm := TDPMForm.Create(Self);
  try
    DPMForm.ShowModal;
  finally
    DPMForm.Free;
  end;
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
  Result := (BorlandIDEServices as INTAServices).MainMenu;
end;

function TDPMEngine.GetPrivatePackages: TPackageList;
var
  FileArr: TArray<string>;
  FileItem: string;
  JSONStrings: TArray<string>;
begin
  if FPrivatePackages = nil then
  begin
    if TDirectory.Exists(GetPrivatePackagesPath) then
    begin
      FileArr := TDirectory.GetFiles(GetPrivatePackagesPath, '*.json');
      JSONStrings := [];
      for FileItem in FileArr do
        JSONStrings := JSONStrings + [TFile.ReadAllText(FileItem, TEncoding.ANSI)];

      if Length(JSONStrings) > 0 then
        FPrivatePackages := TPackageList.Create(JSONStrings);
    end;
  end;

  if FPrivatePackages = nil then
    FPrivatePackages := TPackageList.Create(True);
  Result := FPrivatePackages;
end;

function TDPMEngine.GetPrivatePackagesPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPrivatePackagesPath);
end;

procedure TDPMEngine.SavePackage(aPackage: TPackage);
var
  Bytes: TBytes;
  Path: string;
begin
  Bytes := TEncoding.ANSI.GetBytes(aPackage.GetJSONString);
  Path := TPath.Combine(GetPrivatePackagesPath, aPackage.Name + '.json');

  WriteFile(Path, Bytes);
end;

procedure TDPMEngine.WriteFile(const aPath: string; const aBytes: TBytes);
var
  FS: TFileStream;
begin
  ForceDirectories(TDirectory.GetParent(aPath));

  FS := TFile.Create(aPath);
  try
    FS.Position := FS.Size;
    FS.Write(aBytes[0], Length(aBytes));
  finally
    FS.Free;
  end;
end;

end.
