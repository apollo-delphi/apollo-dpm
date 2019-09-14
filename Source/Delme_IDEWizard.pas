unit Delme_IDEWizard;

interface

uses
  ToolsAPI,
  Vcl.Menus;

type
  TDelmeIDEWizard = class(TNotifierObject, IOTAWizard)
  private
    function GetDelmeMenuItem: TMenuItem;
    function GetIDEMainMenu: TMainMenu;
  protected
    procedure AddDelmeMenuItem;
  public
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    constructor Create;
    destructor Destroy; override;
  end;

procedure Register;

const
  cDelmeMenuItemName = 'miDelme';

implementation

procedure Register;
begin
  RegisterPackageWizard(TDelmeIDEWizard.Create);
end;

{ TDelmeIDEWizard }

procedure TDelmeIDEWizard.AddDelmeMenuItem;
var
  DelmeMenuItem: TMenuItem;
begin
  DelmeMenuItem := TMenuItem.Create(nil);
  DelmeMenuItem.Name := cDelmeMenuItemName;
  DelmeMenuItem.Caption := 'Delme';

  GetIDEMainMenu.Items.Insert(GetIDEMainMenu.Items.Count - 2, DelmeMenuItem);
end;

constructor TDelmeIDEWizard.Create;
begin
  inherited Create;

  if GetDelmeMenuItem = nil then
    AddDelmeMenuItem;
end;

destructor TDelmeIDEWizard.Destroy;
begin
  if GetDelmeMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetDelmeMenuItem);

  inherited;
end;

procedure TDelmeIDEWizard.Execute;
begin
end;

function TDelmeIDEWizard.GetDelmeMenuItem: TMenuItem;
var
  MenuItem: TMenuItem;
begin
  Result := nil;

  for MenuItem in GetIDEMainMenu.Items do
    if MenuItem.Name = cDelmeMenuItemName then
      Exit(MenuItem);
end;

function TDelmeIDEWizard.GetIDEMainMenu: TMainMenu;
begin
  Result := (BorlandIDEServices as INTAServices).MainMenu;
end;

function TDelmeIDEWizard.GetIDString: string;
begin
  Result := 'Delme.IDE.Menu.Item';
end;

function TDelmeIDEWizard.GetName: string;
begin
  Result := 'Delme';
end;

function TDelmeIDEWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

end.
