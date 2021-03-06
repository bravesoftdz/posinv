unit modul;

interface

uses
  SysUtils, Classes, IBXDB, {WSocket,} Forms,  Controls,
   NxGrid, NxColumns,NxColumnClasses, NxCustomGridControl, Dialogs,
   DB, Graphics, Variants, ImgList;

type
  TAccountLogin = record
    userID,
    ShiftID,
    groupID,
    groupName,
    NameID,
    passwd,
    passwdMD5,
    IPAddress   : string;
    timeLogin   : TDateTime;
  end;
  TTagsComparator = (tcLessThan, tcEqual, tcMoreThan);
  TDM = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
    FDBHost : string;
    FDBPort : word;
    FDBName : string;
    FDBUsername : string;
    FDBPasswd : string;
    Posisi : integer;


    procedure CreateDefaultSetting;

  public
    { Public declarations }
    isDebug : Boolean;
    TaxPPN  : Single;
    RootPasswd : string;
    DepositLogAktif : String;
    DBConn : TIBXDB;
    SKIN   : string;
    PDBName : string;
    Header1 : String;
    Header2 : String;
    Header3 : String;
    Footer1 : String;
    Footer2 : String;
    Footer3 : String;

    DirGambar : String;
    MesinID  : String;
    DrawerStatus : smallint;
    PoleDisplayStatus : smallint;
    PrinterID : String;
    PrinterStatus : smallint;
    ScreenHeight,ScreenWidth : SmallInt;

    AccountLogin  : TAccountLogin;
    procedure LoadSettings;
    function CheckInputText(const ParentControl: TWinControl; const AllowClass: array of TClass): Boolean;
    procedure SendDatagram(const Host, Port: string; Data: string;
      BroadCast: Boolean);
    procedure ChangeControlState(const ParentControl: TWinControl; const AllowClass: array of TClass; const SetEnabled: Boolean; const CheckByTags: Integer = 0; const TagsComparator: TTagsComparator = tcEqual);
    Function AwalanRp(Data1:double):string;
    Function Terbilang(Data:double):string;
    Procedure DoRecordList(SQLQuery: string; Params: Array of Variant; ResultList: TStrings;
                            const KeyField, ValueField: string);
    Function DoRecordValue(SQLQuery: string; Params: Array of Variant; var StrResult: String): integer;
     procedure DoDataGrid(SQLQuery: string; Params: Array of Variant; Grid : TNexTGrid);
  end;

const
  PAGEVIEW = 25;
  PASSWD_TIME_EXPIRE = 30; // Password Expired in 30 days

  GridColorSelection = clHighlight;
  FormHeaderColor = $00C35416;
  TextHeaderColor= clWhite;
  FormColor = $00FFF2ED;
  GridRowColor1 = clWhite;
  GridRowColor2 = $00EBEBEB;
  GridHeaderColor = $00FFD3C4;


  PanelTopColor = $00000099;
  PanelMiddleColor = $00CCCCFF;
  PanelBottomColor = $00A8A8FF;

var
  DM: TDM;

implementation

{$R *.dfm}

uses IniFiles, AbstractDB, StdCtrls,ActnList;

type
  THackControl = class(TControl);


procedure TDM.ChangeControlState(const ParentControl: TWinControl; const AllowClass: array of TClass; const SetEnabled: Boolean; const CheckByTags: Integer = 0; const TagsComparator: TTagsComparator = tcEqual);

  function IsAllowedClass(AControl: TComponent): Boolean;
  var I: Integer;
  begin
    for I:= 0 to High(AllowClass) do
      if AControl is AllowClass[I] then begin
        Result:= True;
        Exit;
      end;

    Result:= False;
  end;

const ColorStates: array [Boolean] of TColor = (clBtnFace, clWindow);

var I: Integer;
    AControl: TComponent;
begin
  for I:= 0 to Pred(ParentControl.ControlCount) do begin
    AControl:= ParentControl.Controls[I];

    if (AControl is TWinControl) then
      ChangeControlState(AControl as TWinControl, AllowClass, SetEnabled, CheckByTags, TagsComparator);

    if IsAllowedClass(AControl) then begin
      if (CheckByTags <> 0) and (AControl.Tag <> 0) then begin
        case TagsComparator of
        tcLessThan: if AControl.Tag > CheckByTags then Continue;
        tcEqual: if AControl.Tag <> CheckByTags then Continue;
        tcMoreThan: if AControl.Tag < CheckByTags then Continue;
        end;
      end else if (CheckByTags <> 0) and (AControl.Tag = 0) then Continue;

      if (AControl is TControl) then begin
        if not (AControl is TButtonControl) and not (AControl is TGraphicControl) then
          THackControl(AControl).Color:= ColorStates[SetEnabled];
        try
          THackControl(AControl).Enabled:= SetEnabled;
        except
        end;
      end;
    end;
  end;

  for I:= 0 to Pred(ParentControl.ComponentCount) do begin
    AControl:= ParentControl.Components[I];

    if IsAllowedClass(AControl) then begin
      if (CheckByTags <> 0) and (AControl.Tag <> 0) then begin
        case TagsComparator of
        tcLessThan: if AControl.Tag > CheckByTags then Continue;
        tcEqual: if AControl.Tag <> CheckByTags then Continue;
        tcMoreThan: if AControl.Tag < CheckByTags then Continue;
        end;
      end else if (CheckByTags <> 0) and (AControl.Tag = 0) then Continue;

      if AControl is TCustomAction then
      try
        TCustomAction(AControl).Enabled:= SetEnabled;
      except
      end;
    end;
  end;
end;


function TDM.CheckInputText(const ParentControl: TWinControl;
  const AllowClass: array of TClass): Boolean;

  function IsAllowedClass(AControl: TComponent): Boolean;
  var I: Integer;
  begin
    for I:= 0 to High(AllowClass) do
      if AControl is AllowClass[I] then begin
        Result:= True;
        Exit;
      end;

    Result:= False;
  end;

const ColorStates: array [Boolean] of TColor = (clBtnFace, clWindow);
var I: Integer;
    AControl: TComponent;
begin
  Result := True;
  for I:= 0 to Pred(ParentControl.ControlCount) do begin
    AControl:= ParentControl.Controls[I];

    if (AControl is TWinControl) then
      if not CheckInputText(AControl as TWinControl, AllowClass) then begin
        Result := False;
        Exit;
      end;

    if IsAllowedClass(AControl) then begin
      if (AControl is TControl) then begin
        try
          if (Pos('''',THackControl(AControl).Text) <> 0) {or
            (Pos('"',THackControl(AControl).Text) <> 0) or
            (Pos('\',THackControl(AControl).Text) <> 0) or
            (Pos('%',THackControl(AControl).Text) <> 0) or
            (Pos('_',THackControl(AControl).Text) <> 0) }then begin
            Result := False;
            MessageDlg('Dilarang menggunakan tanda ''',mtWarning,[mbOK],0);
            Exit;
          end;
        except
        end;
      end;
    end;
  end;
end;

procedure TDM.CreateDefaultSetting;
var TS : TStrings;
    DefaultDB : String;
begin
  DefaultDB := ExtractFilePath(Application.ExeName)+'Databases\PosInventoryDB.FDB';
  TS := TStringList.Create;
  try
    TS.Clear;
    TS.Add(';--------------------------------------------------------');
    TS.Add('; Default Settings ');
    TS.Add('');
    TS.Add('[DATABASE]');
    TS.Add('DBHost = localhost');
    TS.Add('DBName = '+DefaultDB);
    TS.Add('DBUsername = SYSDBA');
    TS.Add('DBPassword = masterkey');
    TS.Add('');
    TS.Add('[SKIN_INFO]');
    TS.Add('SkinName = Office2007 Black');
    TS.Add('');
    TS.Add('[HEADER]');
    TS.Add('Header1 = KFC Fried Chicken ');
    TS.Add('Header2 = Mall Olimpic Garden Lt 5 - 14');
    TS.Add('Header3 = M A L A N G');
    TS.Add('');
    TS.Add('[FOOTER]');
    TS.Add('Footer1 = Barang yang sudah dibeli tidak dapat ditukarkan ');
    TS.Add('Footer2 = TERIMA KASIH ATAS KUNJUNGAN ANDA');
    TS.Add('Footer3 = M A L A N G');
    TS.Add('');
    TS.Add('[MESIN]');
    TS.Add('MesinID = 01');
    TS.Add('DrawerStatus = 0');
    TS.Add('PoleDisplayStatus = 0');
    TS.Add('PrinterID = EPSON TMU200');
    TS.Add('PrinterStatus = 0');
    TS.Add('');
    TS.Add('[LAYAR]');
    TS.Add('Height = 768');
    TS.Add('Width = 1024');


    TS.SaveToFile(ChangeFileExt(Application.ExeName, '.ini'));
  finally
    TS.Free;
  end;
end;

procedure TDM.DataModuleCreate(Sender: TObject);
var sDataset : TDataset;
begin
  DBConn := TIBXDB.Create(self);
  LoadSettings;
  with DBConn do
  begin
     DBHost := FDBHost;
     DBPort := FDBPort;
     DBName := FDBName;
     DBUserName := FDBUsername;
     DBPassword := FDBPasswd;
     Connect;
  end;

  // Debug Mode - gak muncul Login -
  sDataset := DBConn.CreateSQLDataSet('select id_setting, value_txt from setting_app',[]);
  try
    while not sDataset.Eof do
    begin
      if sDataset.FieldByName('id_setting').AsString='IS_DEBUG' then
         isDebug := sDataset.FieldByName('VALUE_TXT').AsString='1'
         else
         if sDataset.FieldByName('id_setting').AsString='FOLDER_GAMBAR' then
            DirGambar := ExtractFilePath(Application.ExeName)+sDataset.FieldByName('VALUE_TXT').AsString+'\'
            else
            if sDataset.FieldByName('id_setting').AsString='ROOT_USER' then
               RootPasswd := sDataset.FieldByName('VALUE_TXT').AsString
               else
                 if sDataset.FieldByName('id_setting').AsString='TAX_PPN' then
                 TaxPPN := sDataset.FieldByName('VALUE_TXT').AsSingle;

      sDataset.Next;
    end;

  finally
     sDataset.Free;
  end;


  DirGambar := ExtractFilePath(Application.ExeName)+'Gambar\';
end;

procedure TDM.DataModuleDestroy(Sender: TObject);
begin
  DBConn.Free;
end;

procedure TDM.DoDataGrid(SQLQuery: string; Params: Array of Variant; Grid: TNexTGrid);
var
  i       : Integer;
  DBSet   : TDataset;
  sTitle  : string;
begin
  DBSet    := DBConn.CreateSQLDataSet(SqlQuery,Params,True);
  try
    if DBSet.Fields.Count>Grid.Columns.Count then
    repeat
       sTitle := DBSet.Fields[Grid.Columns.Count].FieldName;
       Grid.Columns.Add(TNxTextColumn,sTitle);
    until DBSet.Fields.Count<=Grid.Columns.Count;

    Grid.InactiveSelectionColor := GridColorSelection;
    Grid.SelectionColor     := GridColorSelection;
    Grid.AppearanceOptions  := [aoHighlightSlideCells];
    Grid.ClearRows;
    Grid.BeginUpdate;
    while not DBSet.Eof do begin
      Grid.AddRow;
      for i := 0 to DBSet.FieldCount-1 do begin
        if Grid.Columns.Item[i].SortType = stBoolean then
          //if VarToStr(DBSet.FieldValues[i]) = '1' then
          if DBSet.Fields[i].AsString = '1' then
            Grid.Cells[i,Grid.RowCount-1] := 'TRUE'
          else
            Grid.Cells[i,Grid.RowCount-1] := 'FALSE'
        else
          if DBSet.Fields[i].AsString = '' then
            Grid.Cells[i,Grid.RowCount-1] := '.'
          else
            Grid.Cells[i,Grid.RowCount-1] := DBSet.Fields[i].AsString;

        if Grid.RowCount mod 2 = 1 then
          Grid.Cell[i,Grid.RowCount-1].Color := GridRowColor1
        else
          Grid.Cell[i,Grid.RowCount-1].Color := GridRowColor2;
      end;
      DBSet.Next;
    end;
    Grid.EndUpdate;
  finally
    FreeAndNil(DBSet);
  end;
end;

procedure TDM.DoRecordList(SQLQuery: string; Params: Array of Variant; ResultList: TStrings;
  const KeyField, ValueField: string);
var
  DBSet           : TDataset;
begin
  DBSet := DBConn.CreateSQLDataSet(SQLQuery,Params, True);
  try
    ResultList.BeginUpdate;
    try
      ResultList.Clear;

      while not DBSet.EOF do
      begin
        ResultList.Add(Format('%s=%s', [DBSet.FieldByName(KeyField).AsString, DBSet.FieldByName(ValueField).AsString]));
        DBSet.Next;
      end;
    finally
      ResultList.EndUpdate;
    end;
  finally
     FreeAndNil(DBSet);
  end;
end;


function TDM.DoRecordValue(SQLQuery: string; Params: array of Variant;
  var StrResult: String): integer;
var
  DBSet           : TDataset;
begin
  DBSet := DBConn.CreateSQLDataSet(SQLQuery,Params, True);
  try
    if DBSet.IsEmpty then begin
      Result := 0;
      exit;
    end;
    // Ambil Record Pertama - Field Pertama saja
    StrResult := DBSet.Fields[0].AsString;
    Result := DBSet.RecordCount;
  finally
     FreeAndNil(DBSet);
  end;

end;

procedure TDM.LoadSettings;
var configFile : TInifile;
    fileName : string;
begin
  fileName := ChangeFileExt(Application.ExeName,'.ini');
  if not FileExists(fileName) then CreateDefaultSetting;
  configFile := TInifile.Create(Filename);
  try
    FDBHost := configFile.ReadString('DATABASE','DBHost','localhost');
    FDBPort := configFile.ReadInteger('DATABASE','DBPort',3050);
    FDBName := configFile.ReadString('DATABASE','DBName','D:\DATABASES\INVENTORYDB.FDB');
    PDBName := configFile.ReadString('DATABASE','DBName','D:\DATABASES\INVENTORYDB.FDB');
    FDBUsername := configFile.ReadString('DATABASE','DBUsername','SYSDBA');
    FDBPasswd := configFile.ReadString('DATABASE','DBPassword','masterkey');
    SKIN    := configFile.ReadString('SKIN_INFO','SkinName','Office2007 Black');
    Header1 := configFile.ReadString('HEADER','Header1','KFC Fried Chicken');
    Header2 := configFile.ReadString('HEADER','Header2','Mall Olimpic Garden Lt 5-14');
    Header3 := configFile.ReadString('HEADER','Header3','M a l a n g');
    Footer1 := configFile.ReadString('FOOTER','Footer1','');
    Footer2 := configFile.ReadString('FOOTER','Footer2','');
    Footer3 := configFile.ReadString('FOOTER','Footer3','');

    MesinID := configFile.ReadString('MESIN','MesinID','01');
    DrawerStatus:= configFile.ReadInteger('MESIN','DrawerStatus',0);
    PoleDisplayStatus:= configFile.ReadInteger('MESIN','PoleDisplayStatus',0);
    PrinterID:= configFile.ReadString('MESIN','PrinterID','OFF');
    PrinterStatus := configFile.ReadInteger('MESIN','PrinterStatus',0);
    ScreenHeight  := configFile.ReadInteger('LAYAR','Height',768);
    ScreenWidth   := configFile.ReadInteger('LAYAR','Width',1024);
  finally
    configFile.Free;
  end;
end;

procedure TDM.SendDatagram(const Host, Port: string;
  Data: string; BroadCast: Boolean);
//var Cli: TWSocket;
begin
{
  Cli:= TWSocket.Create(nil);
  try
    Cli.Proto:= 'udp';

    if BroadCast or (Host = '') then Cli.Addr:= '255.255.255.255'
    else Cli.Addr:= Host;

    Cli.Port:= Port;

    Cli.Connect;

    while not (Cli.State in [wsConnected, wsClosed]) do
      Cli.ProcessMessage;

    if Cli.State = wsConnected then begin
      Cli.SendStr(Data);

      while not Cli.AllSent do
        Cli.ProcessMessage;

      Cli.Close;
      while Cli.State <> wsClosed do
        Cli.ProcessMessage;
    end;
  finally
    FreeAndNil(Cli);
  end;
  }
end;

function TDM.AwalanRp(Data1: double): string;
Var S:String;
Begin
      S:=copy(floattostr(data1),posisi,1);
      If S='1' then S:='Satu' else
      If S='2' then S:='Dua' else
      If S='3' then S:='Tiga' else
      If S='4' then S:='Empat' else
      If S='5' then S:='Lima' else
      If S='6' then S:='Enam' else
      If S='7' then S:='Tujuh' else
      If S='8' then S:='Delapan' else
      If S='9' then S:='Sembilan' else
      If S='0' then S:='';
   Result:=S;

end;


function TDM.Terbilang(Data: double): string;
Var St,St1,Hasil,Bil:string;
    i:word;
Begin
   Hasil:='';
   Posisi:=length(floattostr(data));
   For i:=length(floattostr(data)) downto 1 do
   Begin
      St:=AwalanRp(data);
      If i=length(floattostr(data)) then Bil:=' rupiah ';
      If i=length(floattostr(data))-1 then Bil:=' puluh ';
      If i=length(floattostr(data))-2 then Bil:=' ratus ';
      If i=length(floattostr(data))-3 then Bil:=' ribu ';
      If i=length(floattostr(data))-4 then Bil:=' puluh ';
      If i=length(floattostr(data))-5 then Bil:=' ratus ';
      If i=length(floattostr(data))-6 then Bil:=' juta ';
      If i=length(floattostr(data))-7 then Bil:=' puluh ';
      If i=length(floattostr(data))-8 then Bil:=' ratus ';
      If i=length(floattostr(data))-9 then Bil:=' milyar ';
      If i=length(floattostr(data))-10 then Bil:=' puluh ';
      If i=length(floattostr(data))-11 then Bil:=' ratus ';
      If (St='Satu') and ((posisi=length(floattostr(data))-2) or (posisi=length(floattostr(data))-5) or (posisi=length(floattostr(data))-8) or (posisi=length(floattostr(data))-11)) then
         Begin
         St:='Se';Bil:='ratus ';
         end;
      If (posisi=length(floattostr(data))) or (posisi=length(floattostr(data))-3) or (posisi=length(floattostr(data))-6) or (posisi=length(floattostr(data))-9) then
         Begin
            If Copy(floattostr(Data),posisi-1,1)='1' then
               Begin
                  St1:=St;St:='';
               end;
         end;
      If (St='Satu') and ((posisi=length(floattostr(data))-1) or (posisi=length(floattostr(data))-4) or (posisi=length(floattostr(data))-7) or (posisi=length(floattostr(data))-10)) then
         Begin
         If St1='Satu' then
            Begin
               St:='Se';Bil:='belas ';
            end else
         If St1='' then
            Begin
               St:='Se';Bil:='puluh ';
            end else
            Begin
               St:=St1;Bil:=' belas ';
            end;
         end;
      If (St='') and ((posisi=length(floattostr(data))-2) or (posisi=length(floattostr(data))-5) or (posisi=length(floattostr(data))-8) or (posisi=length(floattostr(data))-11)) then
         Bil:='';
      If (St='') and ((posisi=length(floattostr(data))-1) or (posisi=length(floattostr(data))-4) or (posisi=length(floattostr(data))-7) or (posisi=length(floattostr(data))-10)) then
         Bil:='';
      If (Posisi=length(floattostr(data))-3) and ((Copy(floattostr(Data),length(floattostr(data))-3,1)='0')and(Copy(floattostr(Data),length(floattostr(data))-4,1)='0')and(Copy(floattostr(Data),length(floattostr(data))-5,1)='0')) then
         Bil:='';
      If (Posisi=length(floattostr(data))-6) and ((Copy(floattostr(Data),length(floattostr(data))-6,1)='0')and(Copy(floattostr(Data),length(floattostr(data))-7,1)='0')and(Copy(floattostr(Data),length(floattostr(data))-8,1)='0')) then
         Bil:='';
      If ((St='Satu')or(St='')) and ((posisi=1) and (length(floattostr(data))=4)) then
         Begin
         St:='Se';Bil:='ribu ';
         end;
      If (St='') and ((posisi=1) and (length(floattostr(data))=7)) then
         Begin
         St:='Satu';Bil:=' juta ';
         end;
      If (St='') and ((posisi=1) and (length(floattostr(data))=10)) then
         Begin
         St:='Satu';Bil:=' milyar ';
         end;
      St:=St+Bil;
      Hasil:=St+Hasil;
      dec(Posisi);
   end;
   Terbilang:=Lowercase(Hasil);
end;

end.
