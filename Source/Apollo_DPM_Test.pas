unit Apollo_DPM_Test;

interface

uses
  Apollo_DPM_Engine;

type
  ITest = interface
  ['{029DBA8F-B8CD-4CDB-83B6-532588499196}']
    function GetDescription: string;
    procedure Run;
  end;

function GetTests(aDPMEngine: TDPMEngine): TArray<ITest>;

implementation

type
  TTestCommon = class abstract(TInterfacedObject)
  protected
    FDPMEngine: TDPMEngine;
    function GetTestProjectName: string;
  public
    constructor Create(aDPMEngine: TDPMEngine);
  end;

  TTestInstallCodeSource = class(TTestCommon, ITest)
  private
    function GetDescription: string;
    procedure Run;
  end;

function GetTests(aDPMEngine: TDPMEngine): TArray<ITest>;
begin
  Result := [TTestInstallCodeSource.Create(aDPMEngine)];
end;

{ TTestInstallCodeSource }

function TTestInstallCodeSource.GetDescription: string;
begin
  Result := 'Install Code Source Package';
end;

procedure TTestInstallCodeSource.Run;
begin
  //1. Check if TestProject in the Group
  //2. If not add it
  //3. Make it active

  //??????1. create new test project on the group
  FDPMEngine.CreateNewProject(GetTestProjectName);
end;

{ TTestCommon }

constructor TTestCommon.Create(aDPMEngine: TDPMEngine);
begin
  FDPMEngine := aDPMEngine;
end;

function TTestCommon.GetTestProjectName: string;
begin
  Result := 'TestProject';
end;

end.
