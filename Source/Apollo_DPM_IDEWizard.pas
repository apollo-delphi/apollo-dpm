unit Apollo_DPM_IDEWizard;

interface

uses
  Apollo_DPM_Engine,
  ToolsAPI;

type
  TApolloWizard = class(TNotifierObject, IOTAWizard)
  private
    FDPMEngine: TDPMEngine;
  public
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    constructor Create;
    destructor Destroy; override;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterPackageWizard(TApolloWizard.Create);
end;

{ TApolloWizard }

constructor TApolloWizard.Create;
begin
  inherited Create;

  FDPMEngine := TDPMEngine.Create;
end;

destructor TApolloWizard.Destroy;
begin
  FDPMEngine.Free;

  inherited;
end;

procedure TApolloWizard.Execute;
begin
end;

function TApolloWizard.GetIDString: string;
begin
  Result := 'Apollo.IDE.Menu.Item';
end;

function TApolloWizard.GetName: string;
begin
  Result := cApolloMenuItemCaption;
end;

function TApolloWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

end.
