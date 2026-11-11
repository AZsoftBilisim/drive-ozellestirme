#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Id = String(Record.Id);
	
	Query = New Query(
		"SELECT
		|	HistoryOfSendingMessagesTo1CDocumentManagement.Data AS Data
		|FROM
		|	InformationRegister.HistoryOfSendingMessagesTo1CDocumentManagement AS HistoryOfSendingMessagesTo1CDocumentManagement
		|WHERE
		|	HistoryOfSendingMessagesTo1CDocumentManagement.Id = &Id");
	Query.SetParameter("Id", Record.Id);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Data = Selection.Data.Get(); // BinaryData
		If StrLen(Data) <> 0 Then
			TempFileName = GetTempFileName("xml");
			Data.Write(TempFileName);
			
			FileWithData = New File(TempFileName);
			Size = FileWithData.Size() / 1024;	// KB
			
			TextDocument = New TextDocument;
			TextDocument.Read(TempFileName);
			MessageText = TextDocument.GetText();
			DeleteFiles(TempFileName);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion