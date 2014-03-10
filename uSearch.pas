unit uSearch;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, NxScrollControl, NxCustomGridControl,
  NxCustomGrid, NxGrid, NxColumns, NxColumnClasses, Buttons;

type
  TfrmSearch = class(TForm)
    pnl1: TPanel;
    lbl1: TLabel;
    lbl2: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Label1: TLabel;
    cbbFilter: TComboBox;
    edFilter: TEdit;
    Button1: TButton;
    Grid1: TNextGrid;
    NxTextColumn1: TNxTextColumn;
    NxTextColumn2: TNxTextColumn;
    NxTextColumn3: TNxTextColumn;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    nxCol1: TNxTextColumn;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Grid1KeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
    SQL : String;
    SFilter2 : String;
  end;

var
  frmSearch: TfrmSearch;

implementation

uses modul;

{$R *.dfm}

procedure TfrmSearch.Button1Click(Sender: TObject);
var sFilter : string;
begin
  sFilter :='';
  if edFilter.Text<>'' then begin
     if cbbFilter.ItemIndex=1 then
        sFilter :=' and upper(NAMA) like upper('+quotedstr('%'+edFilter.Text+'%')+')'
     else
        sFilter :=SFilter2+quotedStr(edFilter.Text);
  end;

  DM.DoDataGrid(SQL+sFilter,[],Grid1);
  grid1.SelectLastRow;
  grid1.SetFocus;
end;

procedure TfrmSearch.FormShow(Sender: TObject);
begin
  Button1.SetFocus;
end;

procedure TfrmSearch.Grid1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then modalResult:=mrOK;

end;

end.
