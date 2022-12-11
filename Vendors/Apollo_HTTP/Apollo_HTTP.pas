unit Apollo_HTTP;

interface

uses
  IdCompressorZLib,
  IdCookie,
  IdCookieManager,
  IdHTTP,
  IdSSLOpenSSL,
  IdOpenSSLIOHandlerClient,
  System.Generics.Collections;

type

  THTTP = class
  private
    FCustomHeaders: TDictionary<string, string>;
    FIdCompressorZLib: TIdCompressorZLib;
    FIdCookieManager: TIdCookieManager;
    FIdHTTP: TIdHTTP;
    FIdOpenSSLIOHandlerClient: TIdOpenSSLIOHandlerClient;
    function GetCookies: TArray<TIdCookie>;
    procedure ApplyCustomHeaders;
    procedure FreeHTTP;
    procedure InitHTTP;
  public
    function Delete(const aURL: string): string;
    function Get(const aURL: string): string;
    function Post(const aURL: string; const aKeys, aValues: TArray<string>): string;
    procedure SetCustomHeader(const aKey, aValue: string);
    constructor Create;
    destructor Destroy; override;
    property Cookies: TArray<TIdCookie> read GetCookies;
  end;

  TRESTClient = class(THTTP)
  private
    FHost: string;
    FPort: Integer;
    function GetHostAddress: string;
  public
    function Delete(const aURI: string): string;
    function Get(const aURI: string): string;
    function Post(const aURI: string; const aKeys, aValues: TArray<string>): string;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort;
  end;

implementation

uses
  System.Classes,
  System.SysUtils;

{ THTTP }

procedure THTTP.ApplyCustomHeaders;
var
  Key: string;
begin
  FIdHTTP.Request.CustomHeaders.Clear;

  for Key in FCustomHeaders.Keys do
    FIdHTTP.Request.CustomHeaders.AddValue(Key, FCustomHeaders.Items[Key]);
end;

constructor THTTP.Create;
begin
  FCustomHeaders := TDictionary<string,string>.Create;

  InitHTTP;
end;

function THTTP.Delete(const aURL: string): string;
begin
  Result := FIdHTTP.Delete(aURL);
end;

destructor THTTP.Destroy;
begin
  FreeHTTP;

  FCustomHeaders.Free;

  inherited;
end;

procedure THTTP.FreeHTTP;
begin
  if Assigned(FIdHTTP) then
    FreeAndNil(FIdHTTP);

  if Assigned(FIdOpenSSLIOHandlerClient) then
    FreeAndNil(FIdOpenSSLIOHandlerClient);

  if Assigned(FIdCompressorZLib) then
    FreeAndNil(FIdCompressorZLib);

  if Assigned(FIdCookieManager) then
    FreeAndNil(FIdCookieManager);
end;

function THTTP.Get(const aURL: string): string;
begin
  Result := FIdHTTP.Get(aURL);
end;

function THTTP.GetCookies: TArray<TIdCookie>;
var
  i: Integer;
begin
  Result := [];

  for i := 0 to FIdCookieManager.CookieCollection.Count - 1 do
    Result := Result + [FIdCookieManager.CookieCollection.Cookies[i]];
end;

procedure THTTP.InitHTTP;
begin
  FreeHTTP;

  FIdHTTP := TIdHTTP.Create;
  FIdHTTP.HandleRedirects := False;
  FIdHTTP.Request.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36';
  FIdHTTP.Request.Connection := 'keep-alive';
  FIdHTTP.Request.Accept := 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9';
  FIdHTTP.Request.AcceptLanguage := 'en-US,en;q=0.9,ru;q=0.8,be;q=0.7,pl;q=0.6,uk;q=0.5';
  FIdHTTP.Request.AcceptEncoding := 'gzip, deflate, br';
  FIdHTTP.Request.CacheControl := 'no-cache';
  FIdHTTP.Request.Pragma := 'no-cache';

  FIdOpenSSLIOHandlerClient := TIdOpenSSLIOHandlerClient.Create;
  FIdOpenSSLIOHandlerClient.Options.VerifyServerCertificate := False;
  FIdHTTP.IOHandler := FIdOpenSSLIOHandlerClient;

  FIdCompressorZLib := TIdCompressorZLib.Create(nil);
  FIdHTTP.Compressor := FIdCompressorZLib;

  FIdCookieManager := TIdCookieManager.Create(nil);
  FIdHTTP.CookieManager := FIdCookieManager;
  FIdHTTP.AllowCookies := True;

  ApplyCustomHeaders;
end;

function THTTP.Post(const aURL: string; const aKeys,
  aValues: TArray<string>): string;
var
  i: Integer;
  StringList: TStringList;
begin
  StringList := TStringList.Create;
  try
    for i := 0 to Length(aKeys) - 1 do
      StringList.Values[aKeys[i]] := aValues[i];

    Result := FIdHTTP.Post(aURL, StringList);
  finally
    StringList.Free;
  end;
end;

procedure THTTP.SetCustomHeader(const aKey, aValue: string);
begin
  FCustomHeaders.AddOrSetValue(aKey, aValue);
  ApplyCustomHeaders;
end;

{ TRESTClient }

function TRESTClient.Delete(const aURI: string): string;
begin
  Result := inherited Delete(GetHostAddress + aURI);
end;

function TRESTClient.Get(const aURI: string): string;
begin
  Result := inherited Get(GetHostAddress + aURI);
end;

function TRESTClient.GetHostAddress: string;
begin
  Result := Format('http://%s:%d', [Host, Port]);
end;

function TRESTClient.Post(const aURI: string; const aKeys,
  aValues: TArray<string>): string;
begin
  Result := inherited Post(GetHostAddress + aURI, aKeys, aValues);
end;

end.
