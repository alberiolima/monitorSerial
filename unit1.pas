unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Serial;

type

  { th }
  th = class(TThread)
    public
      constructor create( createsuspended:boolean );
      procedure AtualizaDados;

    protected
      procedure execute; override;

  end;

  { TForm1 }
  TForm1 = class(TForm)
    Button1: TButton;
    ComboBoxPort: TComboBox;
    EditEnviar: TEdit;
    MemoDadosRecebidos: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure ComboBoxPortChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EncontraPostas( sPath: String );
  private

  public

  end;

var
  Form1: TForm1;
  serialHandle: LongInt;
  Flags: TSerialFlags; { TSerialFlags = set of (RtsCtsFlowControl); }
  status: LongInt;
  myThread:th;

implementation

{$R *.lfm}

{ th }

constructor th.create(createsuspended: boolean);
begin
  FreeOnTerminate := True;
  inherited create(createsuspended);
end;

procedure th.AtualizaDados;
var
  s: Char;
begin
    status := SerRead( serialHandle, s, 1);
    if (status>0) then
    begin
       if s = #13 then
         Form1.MemoDadosRecebidos.Lines.Add('')
       else
         Form1.MemoDadosRecebidos.Lines[Form1.MemoDadosRecebidos.Lines.Count-1]:= Form1.MemoDadosRecebidos.Lines[Form1.MemoDadosRecebidos.Lines.Count-1] + s;
    end;
end;

procedure th.execute;

begin
  while (true) do
  begin
    Synchronize(@AtualizaDados);
  end;
end;

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
  {$IF defined(Windows)}
    serialHandle := SerOpen( ComboBoxPort.Text );
  {$ELSE}
    serialHandle := SerOpen('/dev/'+ComboBoxPort.Text);
  {$ENDIF}
  if ( serialHandle > 0 )then
  begin
     Flags := [ ]; // None
     SerSetParams(serialHandle,9600,8,NoneParity,1,Flags);
     SerSync(serialHandle);
     SerFlushOutput(serialHandle);
     myThread.Start;
  end
  else
  begin
     MemoDadosRecebidos.Lines.add( 'Não foi possível efetuar a conexão');
  end;

end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i:integer;
begin
  myThread := th.create(true);
  ComboBoxPort.Items.Clear();
  {$IF defined(Windows)}
    for  i := 1 to 99 do
    begin
      if FileExists( 'COM' + IntToStr(i) + ':' ) then
        ComboBoxPort.Items.Add( 'COM' + IntToStr(i) + ':'  );
    end;
  {$ELSE}
    EncontraPostas( 'ttyUSB*' );
    EncontraPostas( 'ttyACM*' );
    //EncontraPostas( 'ttyS*' );
  {$ENDIF}
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


end.

