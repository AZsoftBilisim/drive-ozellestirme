#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("RepeatedStart") Then
		Title = NStr("vi = 'Khởi động lại quy trình thống nhất';
					|ru = 'Повторный запуск согласования';
					|en = 'Restart approval'; fa = 'Restart approval';
					|it = 'Nuovo avvio omologazione';
					|pl = 'Ponowne uruchomienie uzgodnienia';
					|tr = 'Anlaşmanın tekrar başlatılması'");
		Items.WarningGroup.CurrentPage = Items.GroupWarningRestart;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetApprovalSheetRequest");
	Query.object = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Parameters.SubjectOf.type);
	Query.object.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Parameters.SubjectOf.ID,
		Parameters.SubjectOf.type);
	Query.object.name = Parameters.SubjectOf.name;
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	For Each Point In Response.items Do
		If Point.result = "Approved" Then
			SheetLine = ApprovalForm.Add();
			SheetLine.LastFirstName = Point.name;
			SheetLine.JobTitle = Point.position;
			SheetLine.Date = Point.date;
			SheetLine.Result = Point.result;
			SheetLine.Note = Point.comment;
		EndIf;
	EndDo;
	
	If ApprovalForm.Count() = 0 Then
		Cancel = True;
		Return;
	EndIf;
	
	ApprovalForm.Sort("Date, LASTFIRSTNAME");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AbortCommand(Command)
	
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion