unit Apollo_HTTP;

interface

uses
  IdCompressorZLib,
  IdHTTP,
  IdSSLOpenSSL,
  System.Generics.Collections;

type
  THTTP = class
  private
    FCustomHeaders: TDictionary<string,string>;
    FIdCompressorZLib: TIdCompressorZLib;
    FIdHTTP: TIdHTTP;
    FIdSSLIOHandlerSocketOpenSSL: TIdSSLIOHandlerSocketOpenSSL;
    procedure ApplyCustomHeaders;
    procedure FreeHTTP;
    procedure InitHTTP;
  public
    function Get(const aURL: string): string;
    procedure SetCustomHeader(const aKey, aValue: string);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
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

  if Assigned(FIdSSLIOHandlerSocketOpenSSL) then
    FreeAndNil(FIdSSLIOHandlerSocketOpenSSL);

  if Assigned(FIdCompressorZLib) then
    FreeAndNil(FIdCompressorZLib);
end;

function THTTP.Get(const aURL: string): string;
begin
  Result := FIdHTTP.Get(aURL);
end;

procedure THTTP.InitHTTP;
begin
  FreeHTTP;

  FIdHTTP := TIdHTTP.Create;
  FIdHTTP.HandleRedirects := True;

  FIdHTTP.Request.UserAgent := 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36';
  FIdHTTP.Request.Connection := 'keep-alive';
  FIdHTTP.Request.Accept := 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8';
  FIdHTTP.Request.AcceptLanguage := 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7,be;q=0.6,pl;q=0.5';
  FIdHTTP.Request.AcceptEncoding := 'gzip, deflate, br';
  FIdHTTP.Request.CacheControl := 'no-cache';

  FIdSSLIOHandlerSocketOpenSSL := TIdSSLIOHandlerSocketOpenSSL.Create;
  FIdSSLIOHandlerSocketOpenSSL.SSLOptions.Mode := sslmClient;
  FIdSSLIOHandlerSocketOpenSSL.SSLOptions.Method := sslvTLSv1_2;
  FIdHTTP.IOHandler := FIdSSLIOHandlerSocketOpenSSL;

  FIdCompressorZLib := TIdCompressorZLib.Create(nil);
  FIdHTTP.Compressor := FIdCompressorZLib;

  ApplyCustomHeaders;
end;

procedure THTTP.SetCustomHeader(const aKey, aValue: string);
begin
  FCustomHeaders.AddOrSetValue(aKey, aValue);
  ApplyCustomHeaders;
end;

end.
