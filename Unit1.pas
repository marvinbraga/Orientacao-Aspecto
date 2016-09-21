unit Unit1;

interface

uses
  {do exemplo}
  REST.JSON, System.IOUtils, System.SysUtils, uValidation,
  {do form}
  System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Ani,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.StdCtrls, FMX.Layouts;

type
  TSettings = class
  private
    FServer: string;
    FPort: Integer;
    FDatabaseName: string;
    FUser: string;
    FPassword: string;
  public
    [MandatoryAttribute, IPAddressAttribute]
    property Server: string read FServer write FServer;
    [RangeAttribute(1024, 32000)]
    property Port: Integer read FPort write FPort;
    [MandatoryAttribute]
    property DatabaseName: string read FDatabaseName write FDatabaseName;
    [MandatoryAttribute]
    property User: string read FUser write FUser;
    [MandatoryAttribute, EncryptedAttribute]
    property Password: string read FPassword write FPassword;

    procedure Save;
    class function Load: TSettings;
    class function NewObject: TSettings;
  end;

  TForm1 = class(TForm)
    Memo1: TMemo;
    FloatAnimation1: TFloatAnimation;
    glayBotos: TGridLayout;
    btnTestar: TButton;
    procedure btnTestarClick(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure Test01;
    procedure Test02;
    procedure Test03;
    procedure Test04;
  public
    { Public declarations }
    procedure Test;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}
{ TSettings }

class function TSettings.Load: TSettings;
var
  LConfFile, LJsonStr: string;
begin
  { recupera o nome do arquivo de backup do objeto }
  LConfFile := ChangeFileExt(ParamStr(0), '.conf');
  { verifica se o arquivo existe }
  if TFile.Exists(LConfFile) then
  begin
    { recupera o texto do arquivo }
    LJsonStr := TFile.ReadAllText(LConfFile);
    { instacia um objeto com os valores guardados no arquivo }
    Result := TJson.JsonToObject<TSettings>(LJsonStr);
  end
  else
  begin
    { ou, devolve um objeto limpo }
    Result := TSettings.NewObject;
  end;
end;

class function TSettings.NewObject: TSettings;
begin
  { ou, devolve um objeto limpo }
  Result := TSettings.Create;
end;

procedure TSettings.Save;
begin
  { salva no arquivo as informações do objeto em formato Json }
  TFile.WriteAllText(ChangeFileExt(ParamStr(0), '.conf'),
    TJson.Format(TJson.ObjectToJsonObject(Self)));
end;

{ TForm1 }

procedure TForm1.btnTestarClick(Sender: TObject);
begin
  Self.Test;
end;

procedure TForm1.Test;

  procedure LAdicionarLinha;
  begin
    Memo1.Lines.Add('');
    Memo1.Lines.Add('=================================================');
    Memo1.Lines.Add('');
  end;

begin
  // Self.Test01;
  // LAdicionarLinha;
  // Self.Test02;
  // LAdicionarLinha;
  Self.Test03;
  LAdicionarLinha;
  Self.Test04;
  LAdicionarLinha;
end;

procedure TForm1.Test01;
var
  LSettings: TSettings;
begin
  { recupera um objeto novo }
  LSettings := TSettings.NewObject;
  try
    { exibe os dados }
    Memo1.Lines.Add(TJson.Format(TJson.ObjectToJsonObject(LSettings)));
    { valida os dados antes de salvar }
    if not TValidateObject.TryValidate(LSettings) then
    begin
      Memo1.Lines.Add('Objeto não é válido.');
    end
    else
    begin
      Memo1.Lines.Add('Objeto passou na validação!!!');
    end;
    { salva os dados }
    LSettings.Save;
  finally
    LSettings.Free;
  end;
end;

procedure TForm1.Test02;
var
  LSettings: TSettings;
begin
  { recupera o objeto salvo }
  LSettings := TSettings.Load;
  try
    { adiciona o dado }
    LSettings.Server := 'Meu servidor';
    { exibe os dados }
    Memo1.Lines.Add(TJson.Format(TJson.ObjectToJsonObject(LSettings)));

    { valida os dados antes de salvar }
    if not TValidateObject.TryValidate(LSettings) then
    begin
      Memo1.Lines.Add('Objeto não é válido.');
    end
    else
    begin
      Memo1.Lines.Add('Objeto passou na validação!!!');
    end;
    { salva os dados }
    LSettings.Save;
  finally
    LSettings.Free;
  end;
end;

procedure TForm1.Test03;
var
  LSettings: TSettings;
  LResult: TStrings;
begin
  { recupera o objeto salvo }
  LSettings := TSettings.Load;
  try
    { adiciona o dado }
    LSettings.Server := '192.168.0.1';
    { exibe os dados }
    Memo1.Lines.Add(TJson.Format(TJson.ObjectToJsonObject(LSettings)));

    LResult := TStringList.Create;
    try
      { valida os dados antes de salvar }
      if not TValidateObject.TryValidate(LSettings, LResult) then
      begin
        Memo1.Lines.Add('Objeto não é válido.' + sLineBreak + LResult.Text);
      end
      else
      begin
        Memo1.Lines.Add('Objeto passou na validação!!!');
      end;
    finally
      LResult.Free;
    end;
    { salva os dados }
    LSettings.Save;
  finally
    LSettings.Free;
  end;
end;

procedure TForm1.Test04;
var
  LSettings: TSettings;
begin
  { recupera o objeto salvo }
  LSettings := TSettings.Load;
  try
    { adiciona o dado }
    LSettings.Server := '192.168.0.1';
    LSettings.Password := 'admin8900*';
    { exibe os dados }
    Memo1.Lines.Add(TJson.Format(TJson.ObjectToJsonObject(LSettings)));
    { encripta }
    TValidateObject.TryTransform(LSettings, tdForward, '87654kdjj');
    { exibe os dados }
    Memo1.Lines.Add(TJson.Format(TJson.ObjectToJsonObject(LSettings)));
    { desencripta }
    TValidateObject.TryTransform(LSettings, tdBackward, '87654kdjj');
    { exibe os dados }
    Memo1.Lines.Add(TJson.Format(TJson.ObjectToJsonObject(LSettings)));

    { salva os dados }
    LSettings.Save;
  finally
    LSettings.Free;
  end;
end;

end.
