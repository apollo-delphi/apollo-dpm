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
    lbCopyErrorInfo: TLabel;
    procedure actRunTestsExecute(Sender: TObject);
    procedure lvTestsDblClick(Sender: TObject);
  private
    FTestsKeeper: TArray<ITest>;
    procedure RenderResult(aItem: TListItem; aTest: ITest);
    procedure RenderTests(aTests: TArray<ITest>);
  public
    constructor Create(aOwner: TComponent; aDPMEngine: TDPMEngine); reintroduce;
  end;

implementation

{$R *.dfm}

uses
  Apollo_DPM_UIHelper,
  Vcl.Clipbrd;

{ TTestFrame }

procedure TTestFrame.actRunTestsExecute(Sender: TObject);
var
  i: Integer;
  Test: ITest;
begin
  SetControlsEnable(False, [btnRun, lvTests]);

  for i := 0 to lvTests.Items.Count - 1 do
    RenderResult(lvTests.Items[i], nil);

  for i := 0 to lvTests.Items.Count - 1 do
  begin
    if lvTests.Items[i].Checked then
    begin
      Test := ITest(lvTests.Items[i].Data);
      Test.Run;

      RenderResult(lvTests.Items[i], Test);
    end;
  end;

  SetControlsEnable(True, [btnRun, lvTests]);
end;

constructor TTestFrame.Create(aOwner: TComponent; aDPMEngine: TDPMEngine);
begin
  inherited Create(aOwner);

  RenderTests(GetTests(aDPMEngine));
end;

procedure TTestFrame.lvTestsDblClick(Sender: TObject);
var
  Test: ITest;
begin
  if Assigned(lvTests.Selected) then
  begin
    Test := ITest(lvTests.Selected.Data);
    Clipboard.AsText := Test.Error;
  end;
end;

procedure TTestFrame.RenderResult(aItem: TListItem;  aTest: ITest);
begin
  aItem.SubItems.Clear;

  if not Assigned(aTest) then
    Exit;

  if aTest.Passed then
    aItem.SubItems.Add('Passed')
  else
  begin
    aItem.SubItems.Add('Failed');
    aItem.SubItems.Add(aTest.Error);
  end;
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
