unit uValidation;

interface

uses
  System.Rtti, System.TypInfo,
  System.SysUtils, System.Classes;

type
  ValidationAttribute = class(TCustomAttribute)
  private
    function GetCustomMessage: string; virtual;
  public
    function Validate(AValue: TValue): Boolean; virtual;
    property CustomMessage: string read GetCustomMessage;
  end;

  ValidTypesAttribute = class(ValidationAttribute)
  private
    FTypeKinds: TTypeKinds;
    FCustomMessage: string;
    function GetCustomMessage: string; override;
  public
    constructor Create(const ATypeKinds: TTypeKinds); overload;
    function Validate(AValue: TValue): Boolean; override;
  end;

  [ValidTypesAttribute([tkInteger, tkChar, tkEnumeration, tkFloat, tkString,
    tkSet, tkClass, tkWChar, tkLString, tkWString, tkVariant, tkArray, tkInt64,
    tkDynArray, tkUString])]
  MandatoryAttribute = class(ValidationAttribute)
  private
    function GetCustomMessage: string; override;
  public
    function Validate(AValue: TValue): Boolean; override;
  end;

  IPAddressAttribute = class(ValidationAttribute)
  private
    function GetCustomMessage: string; override;
  public
    function Validate(AValue: TValue): Boolean; override;
  end;

  RangeAttribute = class(ValidationAttribute)
  private
    FMin: Integer;
    FMax: Integer;
    function GetCustomMessage: string; override;
  public
    constructor Create(const AMin: Integer; const AMax: Integer);
    function Validate(AValue: TValue): Boolean; override;
  end;

  TAttributeTransformDirection = (tdForward, tdBackward);

  TransformAttribute = class(TCustomAttribute)
  public
    function RunTransform(const AValue: TValue; out OutValue: TValue;
      ADirection: TAttributeTransformDirection): Boolean; overload;
  end;

  EncryptedAttribute = class(TransformAttribute)
  public
    function RunTransform(const AValue: TValue; out OutValue: TValue;
      ADirection: TAttributeTransformDirection; const AKey: string): Boolean; overload;
  end;

  { classe para validação }
  TValidateObject = class
  public
    class function TryValidate(AClass: TObject;
      AValidationResult: TStrings = nil): Boolean;
    class function TryTransform(AClass: TObject;
      ADirection: TAttributeTransformDirection): Boolean; overload;
    class function TryTransform(AClass: TObject;
      ADirection: TAttributeTransformDirection; const AKey: string): Boolean; overload;
  end;

implementation

uses
  DATA.DBXEncryption,
  IdCoderMIME,
  System.RegularExpressions;

{ ValidationAttribute }

function ValidationAttribute.GetCustomMessage: string;
begin
  Result := EmptyStr;
end;

function ValidationAttribute.Validate(AValue: TValue): Boolean;
begin
  Result := False;
end;

{ MandatoryAttribute }

function MandatoryAttribute.GetCustomMessage: string;
begin
  Result := 'Este membro está vazio';
end;

function MandatoryAttribute.Validate(AValue: TValue): Boolean;
begin
  // Result := False;
  // case AValue.Kind of
  // tkUnknown:
  // ;
  // tkInteger:
  // Result := (AValue.AsInteger <> 0);
  // tkEnumeration:
  // ;
  // tkFloat:
  // ;
  // tkString, tkWChar, tkLString, tkWString, tkUString, tkChar:
  // Result := (AValue.AsString <> EmptyStr);
  // tkSet:
  // ;
  // tkClass:
  // ;
  // tkMethod:
  // ;
  // tkVariant:
  // ;
  // tkArray:
  // ;
  // tkRecord:
  // ;
  // tkInterface:
  // ;
  // tkInt64:
  // ;
  // tkDynArray:
  // ;
  // tkClassRef:
  // ;
  // tkPointer:
  // ;
  // tkProcedure:
  // ;
  // end;
  Result := (AValue.AsString <> EmptyStr);
end;

{ TValidateObject }

class function TValidateObject.TryTransform(AClass: TObject;
  ADirection: TAttributeTransformDirection): Boolean;
var
  LContext: TRttiContext;
  LType: TRttiType;
  LAttr: TCustomAttribute;
  LProp: TRttiProperty;
  LOutValue: TValue;
begin
  Result := True;
  { recupera o tipo da classe do objeto enviado }
  LType := LContext.GetType(AClass.ClassInfo);
  { percorre aas propriedades }
  for LProp in LType.GetProperties do
    if LProp.ClassNameIs('TRttiInstancePropertyEx') then
    begin
      { recupera os atributos das propriedades }
      for LAttr in LProp.GetAttributes do
      begin
        { se for um atributo de transformação }
        if LAttr is TransformAttribute then
        begin
          { executa a validação }
          if TransformAttribute(LAttr).RunTransform(LProp.GetValue(AClass),
            LOutValue, ADirection) then
          begin
            LProp.SetValue(AClass, LOutValue);
          end
          else
          begin
            { não passou na validação }
            Result := False;
          end;
        end;
      end;
    end;
end;

class function TValidateObject.TryTransform(AClass: TObject;
  ADirection: TAttributeTransformDirection; const AKey: string): Boolean;
var
  LContext: TRttiContext;
  LType: TRttiType;
  LAttr: TCustomAttribute;
  LProp: TRttiProperty;
  LOutValue: TValue;
begin
  Result := True;
  { recupera o tipo da classe do objeto enviado }
  LType := LContext.GetType(AClass.ClassInfo);
  { percorre aas propriedades }
  for LProp in LType.GetProperties do
    if LProp.ClassNameIs('TRttiInstancePropertyEx') then
    begin
      { recupera os atributos das propriedades }
      for LAttr in LProp.GetAttributes do
      begin
        { se for um atributo de transformação }
        if LAttr is TransformAttribute then
        begin
          { executa a validação }
          if EncryptedAttribute(LAttr).RunTransform(LProp.GetValue(AClass),
            LOutValue, ADirection, AKey) then
          begin
            LProp.SetValue(AClass, LOutValue);
          end
          else
          begin
            { não passou na validação }
            Result := False;
          end;
        end;
      end;
    end;
end;

class function TValidateObject.TryValidate(AClass: TObject;
  AValidationResult: TStrings): Boolean;
var
  LContext: TRttiContext;
  LType, LTypeAttribute: TRttiType;
  LAttr, LInnerAttribute: TCustomAttribute;
  LProp: TRttiProperty;
  LMessage: string;
  LInnerValPassed: Boolean;
begin
  Result := True;
  { recupera o tipo da classe do objeto enviado }
  LType := LContext.GetType(AClass.ClassInfo);
  { percorre aas propriedades }
  for LProp in LType.GetProperties do
    if LProp.ClassNameIs('TRttiInstancePropertyEx') then
    begin
      { recupera os atributos das propriedades }
      for LAttr in LProp.GetAttributes do
      begin
        LInnerValPassed := True;
        LTypeAttribute := LContext.GetType(LAttr.ClassInfo);
        for LInnerAttribute in LTypeAttribute.GetAttributes do
        begin
          if LInnerAttribute is ValidationAttribute then
          begin
            if not ValidationAttribute(LInnerAttribute)
              .Validate(LProp.GetValue(AClass)) then
            begin
              Result := False;
              LMessage :=
                Format('A validação %S falhou no atributo %S da propriedade %S.%S (Hint: %S)',
                [LInnerAttribute.ClassName, LAttr.ClassName, AClass.ClassName,
                LProp.Name, ValidationAttribute(LInnerAttribute).CustomMessage])
                + sLineBreak;
              if AValidationResult <> nil then
              begin
                AValidationResult.Add(LMessage);
              end;
            end;
          end;
        end;

        if LInnerValPassed then
        begin
          { se for um atributo de validação }
          if LAttr is ValidationAttribute then
          begin
            { executa a validação }
            if not ValidationAttribute(LAttr).Validate(LProp.GetValue(AClass))
            then
            begin
              { não passou na validação }
              Result := False;
              { recupera a mensagem }
              LMessage :=
                Format('A validação %S falhou na propriedade %S.%S (Hint: %S)',
                [LAttr.ClassName, AClass.ClassName, LProp.Name,
                ValidationAttribute(LAttr).CustomMessage]);
              { vetifica se existe algum objeto para retorno da mensagem }
              if AValidationResult <> nil then
              begin
                AValidationResult.Add(LMessage);
              end;
            end;
          end;
        end;
      end;
    end;
end;

{ IPAddressAttribute }

function IPAddressAttribute.GetCustomMessage: string;
begin
  Result := 'Este endereço IP não é válido.';
end;

function IPAddressAttribute.Validate(AValue: TValue): Boolean;
begin
  { máscara de IP V4 }
  Result := TRegEx.IsMatch(AValue.AsString,
    '\b' + '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' +
    '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' +
    '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.' +
    '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b');
end;

{ RangeAttribute }

constructor RangeAttribute.Create(const AMin, AMax: Integer);
begin
  inherited Create;
  FMin := AMin;
  FMax := AMax;
end;

function RangeAttribute.GetCustomMessage: string;
begin
  Result := Format('Os valores devem estar entre [%d - %d]', [FMin, FMax]);
end;

function RangeAttribute.Validate(AValue: TValue): Boolean;
begin
  Result := ((AValue.AsInteger >= FMin) and (AValue.AsInteger <= FMax));
end;

{ ValidTypesAttribute }

constructor ValidTypesAttribute.Create(const ATypeKinds: TTypeKinds);
begin
  FTypeKinds := ATypeKinds;
  FCustomMessage := 'Você deve passar um tipo válido para esta propriedade.';
end;

function ValidTypesAttribute.GetCustomMessage: string;
var
  LKind: TTypeKind;
begin
  Result := EmptyStr;
  if FTypeKinds <> [] then
  begin
    for LKind in FTypeKinds do
    begin
      if Result <> '' then
      begin
        Result := Result + ', ';
      end;
      Result := Result + TRttiEnumerationType.GetName<TTypeKind>(LKind);
    end;
    Result := FCustomMessage + '[' + Result + ']';
  end
  else
  begin
    Result := FCustomMessage;
  end;
end;

function ValidTypesAttribute.Validate(AValue: TValue): Boolean;
begin
  Result := (AValue.Kind in FTypeKinds);
end;

{ TransformAttribute }

function TransformAttribute.RunTransform(const AValue: TValue;
  out OutValue: TValue; ADirection: TAttributeTransformDirection): Boolean;
begin
  Result := True;
  OutValue := AValue;
end;

{ EncryptedAttribute }

function EncryptedAttribute.RunTransform(const AValue: TValue;
  out OutValue: TValue; ADirection: TAttributeTransformDirection;
  const AKey: string): Boolean;
var
  LCypher: TPC1Cypher;
  LCont: Integer;
  LData: TArray<Byte>;
  LStream: TMemoryStream;
begin
  { encryption }
  if (ADirection = tdForward) then
  begin
    { recupera e trata a string }
    LData := TEncoding.UTF8.GetBytes(AValue.AsString);
    { cria o objeto para encriptar }
    LCypher := TPC1Cypher.Create(AKey);
    try
      { percorre o dado }
      for LCont := 0 to Length(LData) - 1 do
      begin
        { encripta }
        LData[LCont] := LCypher.Cypher(LData[LCont]);
      end;
    finally
      LCypher.Free;
    end;
    { codifica a string encritada }
    LStream := TMemoryStream.Create;
    try
      LStream.WriteData(LData, Length(LData));
      LStream.Position := 0;
      OutValue := TValue.From<string>(TIdEncoderMIME.EncodeStream(LStream));
    finally
      LStream.Free;
    end;
  end
  { decryption }
  else
  begin
    { recupera o valor }
    LStream := TMemoryStream.Create;
    try
      TIdDecoderMIME.DecodeStream(AValue.AsString, LStream);
      SetLength(LData, LStream.Size);
      LStream.Position := 0;
      LStream.ReadBuffer(LData[0], Length(LData));
    finally
      LStream.Free;
    end;
    { desencripta }
    LCypher := TPC1Cypher.Create(AKey);
    try
      for LCont := 0 to Length(LData) - 1 do
      begin
        LData[LCont] := LCypher.Decypher(LData[LCont]);
      end;
    finally
      LCypher.Free;
    end;
    OutValue := TEncoding.UTF8.GetString(LData);
  end;
  Result := True;
end;

end.
