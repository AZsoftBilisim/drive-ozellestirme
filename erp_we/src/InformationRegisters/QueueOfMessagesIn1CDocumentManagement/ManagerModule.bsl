#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a message to the queue.
//
// Parameters:
//   BinaryMessageData - BinaryData - Message data.
//   ControlOverSendingFiles - See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
//   MessageAttributes - See InformationRegisters.QueueOfMessagesIn1CDocumentManagement.MessageAttributes
//
Procedure AddAMessage(BinaryMessageData, ControlOverSendingFiles, MessageAttributes = Undefined) Export
	
	If MessageAttributes = Undefined Then
		MessageAttributes = MessageAttributes();
	EndIf;
	
	Manager = CreateRecordManager();
	
	Manager.PointInTime = MessageAttributes.PointInTime;
	Manager.Id = MessageAttributes.Id;
	Manager.Data = New ValueStorage(BinaryMessageData, New Deflation(9));
	Manager.ControlOverSendingFiles = New ValueStorage(ControlOverSendingFiles);
	Manager.CreationDate = CurrentSessionDate();
	Manager.NumberOfSendingAttempts = MessageAttributes.NumberOfSendingAttempts;
	Manager.ErrorMessageText = MessageAttributes.ErrorMessageText;
	
	Manager.Write(True);
	
EndProcedure

// Constructor for the structure of message Attributes.
//
// Returns:
//   Structure:
//     * PointInTime - Number - The current universal date in milliseconds.
//     * Id - UUID - message ID.
//     * NumberOfSendingAttempts - Number - the number of attempts to send a message.
//     * ErrorMessageText - String - the text of the error message about sending the message.
//
Function MessageAttributes() Export
	
	MessageAttributes = New Structure;
	MessageAttributes.Insert("PointInTime", CurrentUniversalDateInMilliseconds());
	MessageAttributes.Insert("Id", New UUID);
	MessageAttributes.Insert("NumberOfSendingAttempts", 0);
	MessageAttributes.Insert("ErrorMessageText", "");
	
	Return MessageAttributes;
	
EndFunction

#EndRegion

#EndIf