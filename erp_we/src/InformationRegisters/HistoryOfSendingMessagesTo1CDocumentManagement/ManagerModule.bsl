#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Moves the message from the queue to be sent to the message history register.
//
// Parameters:
//   PointInTime - Number - a moment in time.
//   Id - UUID - message ID.
//
Procedure MoveMessageToHistory(PointInTime, Id) Export
	
	QueueRecordManager = InformationRegisters.QueueOfMessagesIn1CDocumentManagement.CreateRecordManager();
	QueueRecordManager.PointInTime = PointInTime;
	QueueRecordManager.Id = Id;
	QueueRecordManager.Read();
	
	If Not QueueRecordManager.Selected() Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		HistoryRecordManager = CreateRecordManager();
		FillPropertyValues(HistoryRecordManager, QueueRecordManager);
		HistoryRecordManager.DateSent = CurrentSessionDate();
		HistoryRecordManager.Write(True);
		
		ControlOverSendingFiles = QueueRecordManager.ControlOverSendingFiles.Get(); // See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
		For Each String In ControlOverSendingFiles Do
			InformationRegisters.ControlOverSendingFilesTo1CDocumentManagement.SaveHashSumOfFileVersion(
				String.Source,
				String.FileName,
				String.SpreadsheetDocument)
		EndDo;
		
		QueueRecordManager.Delete();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf