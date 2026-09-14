unit TechStore.Authorization;

interface

uses
  System.SysUtils;

type
  TTechStoreAction = (tsaRead, tsaPrepare, tsaConfirmCritical);

  ETechStoreAuthorization = class(Exception);

  TTechStoreAuthorization = class
  public
    procedure RequireAllowed(const AActor, ACapability: string;
      const AAction: TTechStoreAction);
  end;

implementation

procedure TTechStoreAuthorization.RequireAllowed(const AActor, ACapability: string;
  const AAction: TTechStoreAction);
begin
  if AActor.Trim = '' then
    raise ETechStoreAuthorization.Create('Identidade do solicitante é obrigatória.');
  if AAction = tsaConfirmCritical then
    raise ETechStoreAuthorization.Create(
      'Ações críticas exigem fluxo de aprovação humana e não são confirmadas por este servidor.');
end;

end.
