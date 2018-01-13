unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Serial;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    ComboBoxPort: TComboBox;
    EditEnviar: TEdit;
    MemoDadosRecebidos: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure ComboBoxPortChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EncontraPostas( sPath: String );
    procedure Timer1Timer(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  serialHandle: LongInt;
  Flags: TSerialFlags; { TSerialFlags = set of (RtsCtsFlowControl); }
  status: LongInt;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
  s:String;
  writecount:integer;
begin
   s := EditEnviar.Text + #13+#10; { CR + LF }
   writecount := length(s);
   status := SerWrite( serialHandle, s[1], writecount );
end;

procedure TForm1.ComboBoxPortChange(Sender: TObject);
begin
  if ( serialHandle > 0 ) then
  begin
       SerSync(serialHandle);
       SerFlushOutput(serialHandle);
       SerClose(serialHandle);
  end;
  serialHandle := SerOpen('/dev/'+ComboBoxPort.Text);
  if ( serialHandle > 0 )then
  begin
     SerSync(serialHandle);
     SerFlushOutput(serialHandle);
     Flags := [ ]; // None
     SerSetParams(serialHandle,9600,8,NoneParity,1,Flags);
     Timer1.Enabled := true;
  end
  else
  begin
     MemoDadosRecebidos.Lines.add( 'Não foi possível efetuar a conexão');
  end;

end;

procedure TForm1.FormCreate(Sender: TObject);

begin
  ComboBoxPort.Items.Clear();
   ComboBoxPort.Items.Add('A');
  EncontraPostas( 'ttyUSB*' );
  EncontraPostas( 'ttyACM*' );
  //EncontraPostas( 'ttyS*' );
  ComboBoxPort.ItemIndex := 0;
end;

procedure TForm1.EncontraPostas( sPath: String );
var
  SearchResult : TSearchRec;
begin
  if FindFirst( '/dev/' + sPath, (faAnyFile And Not faDirectory), SearchResult) = 0 then
    begin
       repeat
             ComboBoxPort.Items.Add( SearchResult.Name );
       until FindNext (SearchResult) <> 0;
    end;
    FindClose (SearchResult);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  s:String[1];
begin
  s := '';
  status := SerRead( serialHandle, s[1], 1);
  //if (s[1]=#13) then status:=-1; { CR => end serial read }
  if (status>0) then MemoDadosRecebidos.Lines[MemoDadosRecebidos.Lines.Count-1]:= MemoDadosRecebidos.Lines[MemoDadosRecebidos.Lines.Count-1] + s[1];
end;

end.

