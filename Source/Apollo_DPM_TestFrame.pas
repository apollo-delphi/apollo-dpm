unit Apollo_DPM_TestFrame;

interface

uses
  Apollo_DPM_Engine,
  Apollo_DPM_Test,
  System.Actions,
  System.Classes,
  System.ImageList,
  System.SysUtils,
  System.Variants,
  Vcl.ActnList,
  Vcl.Buttons,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.StdCtrls,
  Winapi.Messages,
  Winapi.Windows;

type
  TTestFrame = class(TFrame)
    lvTests: TListView;
    btnRun: TSpeedButton;
    alActions: TActionList;
    actRunTests: TAction;
    ilIcons: TImageList;
    procedure actRunTestsExecute(Sender: TObject);
  private
    FTestsKeeper: TArray<ITest>;
    procedure RenderTests(aTests: TArray<ITest>);
  public
    constructor Create(aOwner: TComponent; aDPMEngine: TDPMEngine); reintroduce;
  end;

implementation

{$R *.dfm}

{ TTestFrame }

procedure TTestFrame.actRunTestsExecute(Sender: TObject);
var
  i: Integer;
  Test: ITest;
begin
  for i := 0 to lvTests.Items.Count - 1 do
  begin
    if lvTests.Items[i].Checked then
    begin
      Test := ITest(lvTests.Items[i].Data);
      Test.Run;
    end;
  end;
end;

constructor TTestFrame.Create(aOwner: TComponent; aDPMEngine: TDPMEngine);
begin
  inherited Create(aOwner);

  RenderTests(GetTests(aDPMEngine));
end;

procedure TTestFrame.RenderTests(aTests: TArray<ITest>);
var
  Item: TListItem;
  Test: ITest;
begin
  FTestsKeeper := aTests;

  for Test in aTests do
  begin
    Item := lvTests.Items.Add;
    Item.Caption := Test.GetDescription;
    Item.Checked := True;
    Item.Data := Test;
  end;
end;

end.
