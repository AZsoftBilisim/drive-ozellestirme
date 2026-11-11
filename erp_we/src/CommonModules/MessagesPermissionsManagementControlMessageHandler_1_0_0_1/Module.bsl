////////////////////////////////////////////////////////////////////////////////
// MESSAGE CHANNEL HANDLER FOR VERSION 1.0.3.5 OF THE MESSAGE INTERFACE
//  REMOTE ADMINISTRATION
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the namespace of the message interface version.
//
// Returns:
//	String - 
Function Package() Export
	
	Return "http://www.1c.ru/1cFresh/Application/Permissions/Control/" + Version(); // @Non-NLS-1
	
EndFunction

// Returns the version of the message interface served by the handler.
//
// Returns:
//	String - 
Function Version() Export
	
	Return "1.0.0.1";
	
EndFunction

// Returns the base type for version messages.
//
// Returns:
//	XDTOObjectType - 
Function BaseType() Export
	
	Return MessagesSaaSCached.TypeBody();
	
EndFunction

// Processes incoming messages from the service model
//
// Parameters:
//  Message - XDTODataObject - incoming message,
//  Sender - ExchangePlanRef.MessagesExchange - exchange plan node corresponding to the message sender
//  MessageProcessed - Boolean - flag for successful message processing. The value of this parameter must
//    be set to True if the message was successfully read in this handler.
//
Procedure ProcessSaaSMessage(Val Message, Val Sender, MessageProcessed) Export
	
	MessageProcessed = True;
	
	Dictionary = MessagesPermissionsManagementControlInterface;
	MessageType = Message.Body.Type();
	
	If MessageType = Dictionary.MessageInformationBasePermissionRequestProcessed(Package()) Then
		UnsharedSessionRequestProcessed(Message, Sender);
	ElsIf MessageType = Dictionary.MessageProcessedRequestForDataAreaPermissions(Package()) Then
		SplitSessionRequestProcessed(Message, Sender);
	Else
		MessageProcessed = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure UnsharedSessionRequestProcessed(Val Message, Val Sender)
	
	BeginTransaction();
	
	Try
		
		For Each RequestProcessingResult In Message.Body.ProcessingResultList.ProcessingResult Do
			
			MessagesPermissionsManagementControlImplementation.UnsharedSessionRequestProcessed(
				RequestProcessingResult.RequestUUID,
				MessagesPermissionsManagementControlInterface.DictionaryOfQueryResultTypes()[RequestProcessingResult.ProcessingResultType],
				RequestProcessingResult.RejectReason);
				
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

Procedure SplitSessionRequestProcessed(Val Message, Val Sender)
	
	BeginTransaction();
	
	Try
		
		For Each RequestProcessingResult In Message.Body.ProcessingResultList.ProcessingResult Do
			
			MessagesPermissionsManagementControlImplementation.SplitSessionRequestProcessed(
				RequestProcessingResult.RequestUUID,
				MessagesPermissionsManagementControlInterface.DictionaryOfQueryResultTypes()[RequestProcessingResult.ProcessingResultType],
				RequestProcessingResult.RejectReason);
				
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion
