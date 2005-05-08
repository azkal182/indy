{ $HDR$}
{**********************************************************************}
{ Unit archived using Team Coherence                                   }
{ Team Coherence is Copyright 2002 by Quality Software Components      }
{                                                                      }
{ For further information / comments, visit our WEB site at            }
{ http://www.TeamCoherence.com                                         }
{**********************************************************************}
{}
{ $Log:  21518: IdCmdTCPClient.pas
{
{   Rev 1.18    2/8/05 5:24:48 PM  RLebeau
{ Updated Disconnect() to not wait for the listening thread to terminate until
{ after the inherited Disconnect() is called, so that the socket is actually
{ disconnected and the thread can terminate properly.
}
{
{   Rev 1.17    2/1/05 12:38:30 AM  RLebeau
{ Removed unused CommandHandlersEnabled property
}
{
    Rev 1.16    6/11/2004 8:48:16 AM  DSiders
  Added "Do not Localize" comments.
}
{
{   Rev 1.15    5/18/04 9:12:26 AM  RLebeau
{ Bug fix for SetExceptionReply() property setter
}
{
{   Rev 1.14    5/16/04 5:18:04 PM  RLebeau
{ Added setter method to ExceptionReply property
}
{
    Rev 1.13    5/10/2004 6:10:38 PM  DSiders
  Removed unused member var FCommandHandlersInitialized.
}
{
{   Rev 1.12    2004.03.06 1:33:00 PM  czhower
{ -Change to disconnect
{ -Addition of DisconnectNotifyPeer
{ -WriteHeader now write bufers
}
{
{   Rev 1.11    2004.03.01 5:12:24 PM  czhower
{ -Bug fix for shutdown of servers when connections still existed (AV)
{ -Implicit HELP support in CMDserver
{ -Several command handler bugs
{ -Additional command handler functionality.
}
{
{   Rev 1.10    2004.02.03 4:17:10 PM  czhower
{ For unit name changes.
}
{
{   Rev 1.9    2004.01.20 10:03:22 PM  czhower
{ InitComponent
}
{
{   Rev 1.8    1/4/04 8:46:16 PM  RLebeau
{ Added OnBeforeCommandHandler and OnAfterCommandHandler events
}
{
    Rev 1.7    11/4/2003 10:25:40 PM  DSiders
  Removed duplicate FReplyClass member in TIdCmdTCPClient (See
  TIdTCPConnection).
}
{
{   Rev 1.6    10/21/2003 10:54:20 AM  JPMugaas
{ Fix for new API change.
}
{
{   Rev 1.5    2003.10.18 9:33:24 PM  czhower
{ Boatload of bug fixes to command handlers.
}
{
{   Rev 1.4    2003.10.02 10:16:26 AM  czhower
{ .Net
}
{
{   Rev 1.3    2003.09.19 11:54:26 AM  czhower
{ -Completed more features necessary for servers
{ -Fixed some bugs
}
{
    Rev 1.2    7/9/2003 10:55:24 PM  BGooijen
  Restored all features
}
{
{   Rev 1.1    7/9/2003 04:36:06 PM  JPMugaas
{ You now can override the TIdReply with your own type.  This should illiminate
{ some warnings about some serious issues.  TIdReply is ONLY a base class with
{ virtual methods.
}
{
{   Rev 1.0    7/7/2003 7:06:40 PM  SPerry
{ Component that uses command handlers
}
{
{   Rev 1.0    7/6/2003 4:47:26 PM  SPerry
{ Units that use Command handlers
}
{
  Original author: Sergio Perry
  Description: TCP client that uses CommandHandlers
}
unit IdCmdTCPClient;

interface

uses
  Classes,
  IdContext, IdGlobal, IdReply, IdThread, IdTCPClient, IdCommandHandlers;

type
  TIdCmdTCPClient = class;

  { Events }
  TIdCmdTCPClientAfterCommandHandlerEvent = procedure(ASender: TIdCmdTCPClient;
    AContext: TIdContext) of object;
  TIdCmdTCPClientBeforeCommandHandlerEvent = procedure(ASender: TIdCmdTCPClient;
    var AData: string; AContext: TIdContext) of object;

  { Listening Thread }
  TIdCmdTCPClientListeningThread = class(TIdThread)
  protected
    FContext: TIdContext;
    FClient: TIdCmdTCPClient;
    FRecvData: String;
    //
    procedure Run; override;
  public
    constructor Create(AClient: TIdCmdTCPClient); reintroduce;
    destructor Destroy; override;
    //
    property Client: TIdCmdTCPClient read FClient;
    property RecvData: String read FRecvData write FRecvData;
  end;

  { TIdCmdTCPClient }
  TIdCmdTCPClient = class(TIdTCPClient)
  protected
    FExceptionReply: TIdReply;
    FOnConnect: TNotifyEvent;
    FOnDisconnect: TNotifyEvent;
    FListeningThread: TIdCmdTCPClientListeningThread;
    FCommandHandlers: TIdCommandHandlers;
    FOnAfterCommandHandler: TIdCmdTCPClientAfterCommandHandlerEvent;
    FOnBeforeCommandHandler: TIdCmdTCPClientBeforeCommandHandlerEvent;
    //
    procedure DoAfterCommandHandler(ASender: TIdCommandHandlers; AContext: TIdContext);
    procedure DoBeforeCommandHandler(ASender: TIdCommandHandlers; var AData: string;
      AContext: TIdContext);
    procedure InitComponent; override;
    procedure SetExceptionReply(AValue: TIdReply);
  public
    procedure Connect; override;
    destructor Destroy; override;
    procedure Disconnect(AImmediate: Boolean); override;
  published
    property CommandHandlers: TIdCommandHandlers read FCommandHandlers write FCommandHandlers;
    property ExceptionReply: TIdReply read FExceptionReply write SetExceptionReply;
    //
    property OnAfterCommandHandler: TIdCmdTCPClientAfterCommandHandlerEvent
      read FOnAfterCommandHandler write FOnAfterCommandHandler;
    property OnBeforeCommandHandler: TIdCmdTCPClientBeforeCommandHandlerEvent
      read FOnBeforeCommandHandler write FOnBeforeCommandHandler;
    property OnConnect: TNotifyEvent read FOnConnect write FOnConnect;
    property OnDisconnect: TNotifyEvent read FOnDisconnect write FOnDisconnect;
  end;

implementation

uses IdReplyRFC, IdSys;

type

  TIdContextAccess = class(TIdContext)
  end;

{ Listening Thread }

constructor TIdCmdTCPClientListeningThread.Create(AClient: TIdCmdTCPClient);
begin
  inherited Create(False);
  //
  FContext := TIdContext.Create(AClient, nil, nil);
  TIdContextAccess(FContext).FOwnsConnection:=False;
  FClient := AClient;
  FreeOnTerminate := False;
end;

destructor TIdCmdTCPClientListeningThread.Destroy;
begin
  inherited Destroy;
  Sys.FreeAndNil(FContext);
end;

procedure TIdCmdTCPClientListeningThread.Run;
begin
  FRecvData := FClient.IOHandler.ReadLn;
  FClient.CommandHandlers.HandleCommand(FContext, FRecvData);
  //Synchronize(?);
  FClient.IOHandler.CheckForDisconnect;
end;

{ TIdCmdTCPClient }

destructor TIdCmdTCPClient.Destroy;
begin
  Sys.FreeAndNil(FExceptionReply);
  Sys.FreeAndNil(FCommandHandlers);
  inherited Destroy;
end;

procedure TIdCmdTCPClient.Connect;
begin
  inherited Connect;
  //
  if Assigned(FOnConnect) then
  begin
    OnConnect(Self);
  end;
  FListeningThread := TIdCmdTCPClientListeningThread.Create(Self);
end;

procedure TIdCmdTCPClient.Disconnect(AImmediate: Boolean);
begin
  if Assigned(FListeningThread) then begin
    FListeningThread.Terminate;
  end;
  //
  inherited;
  //
  if Assigned(FOnDisconnect) then begin
  	FOnDisconnect(Self);
  end;
  if Assigned(FListeningThread) then begin
    FListeningThread.WaitFor;
  end;
  Sys.FreeAndNil(FListeningThread);
end;

procedure TIdCmdTCPClient.DoAfterCommandHandler(ASender: TIdCommandHandlers;
  AContext: TIdContext);
begin
  if Assigned(OnAfterCommandHandler) then begin
    OnAfterCommandHandler(Self, AContext);
  end;
end;

procedure TIdCmdTCPClient.DoBeforeCommandHandler(ASender: TIdCommandHandlers;
  var AData: string; AContext: TIdContext);
begin
  if Assigned(OnBeforeCommandHandler) then begin
    OnBeforeCommandHandler(Self, AData, AContext);
  end;
end;

procedure TIdCmdTCPClient.InitComponent;
begin
  inherited;

  FExceptionReply := FReplyClass.Create(nil);
  ExceptionReply.SetReply(500, 'Unknown Internal Error'); {do not localize}

  FCommandHandlers := TIdCommandHandlers.Create(Self, FReplyClass, nil, ExceptionReply);
  FCommandHandlers.OnAfterCommandHandler := DoAfterCommandHandler;
  FCommandHandlers.OnBeforeCommandHandler := DoBeforeCommandHandler;
end;

procedure TIdCmdTCPClient.SetExceptionReply(AValue: TIdReply);
begin
  FExceptionReply.Assign(AValue);
end;

end.
