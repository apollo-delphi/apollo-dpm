unit Apollo_HTTP;
// v.0.0.1

interface

uses
  IdCompressorZLib,
  IdHTTP,
  IdSSLOpenSSL,
  System.Classes;

type
  THTTP = class
  private
    FIdCompressorZLib: TIdCompressorZLib;
    FIdHTTP: TIdHTTP;
    FIdSSLIOHandlerSocketOpenSSL: TIdSSLIOHandlerSocketOpenSSL;
    procedure DoRequest(const aURL: string; aIdHTTPMethod: TIdHTTPMethod;
      out aResponseText: string; aResponseStream: TMemoryStream);
    procedure FreeHTTP;
    procedure InitHTTP;
  public
    function Get(const aURL: string): string;
    function GetStream(const aURL: string): TMemoryStream;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils;

{ THTTP }

constructor THTTP.Create;
begin
  InitHTTP;
end;

destructor THTTP.Destroy;
begin
  FreeHTTP;

  inherited;
end;

procedure THTTP.DoRequest(const aURL: string; aIdHTTPMethod: TIdHTTPMethod;
  out aResponseText: string; aResponseStream: TMemoryStream);
begin
  aResponseText := '';

  if aIdHTTPMethod = aIdHTTPMethod then
    begin
      if aResponseStream = nil then
        aResponseText := FIdHTTP.Get(aURL)
      else
        FIdHTTP.Get(aURL, aResponseStream);
    end;
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
  DoRequest(aURL, Id_HTTPMethodGet, Result, nil);
end;

function THTTP.GetStream(const aURL: string): TMemoryStream;
var
  Bung: string;
begin
  Result := TMemoryStream.Create;
  DoRequest(aURL, Id_HTTPMethodGet, Bung, Result);
  Result.Position := 0;
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

  // to do - make headers control
  FIdHTTP.Request.CacheControl := 'no-cache';

  //temp
  FIdHTTP.Request.Username := 'a504f978ff703ac1c6d16f1d0703791c700d2291';

  FIdSSLIOHandlerSocketOpenSSL := TIdSSLIOHandlerSocketOpenSSL.Create;
  FIdSSLIOHandlerSocketOpenSSL.SSLOptions.SSLVersions := [sslvSSLv23];
  FIdHTTP.IOHandler := FIdSSLIOHandlerSocketOpenSSL;

  FIdCompressorZLib := TIdCompressorZLib.Create(nil);
  FIdHTTP.Compressor := FIdCompressorZLib;
end;

end.
