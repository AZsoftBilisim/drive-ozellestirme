
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InitializingFormWhenCreatingItOnServer();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	DataCorrect = OrdersFilledInCorrectly();
	If DataCorrect Then
		
		Result = ResultOfClosingForm();
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()
	
	For Each ReferenceOrder In Parameters.References Do
		
		ValuesRow = ListOfOrders_.Add();
		ValuesRow.ReferenceOrder = ReferenceOrder;
		
	EndDo;
	
EndProcedure

&AtClient
Function OrdersFilledInCorrectly()
	
	Result = True;
	Errors = Undefined;
	
	For Each String In ListOfOrders_ Do
		If Not ValueIsFilled(String.ReferenceOrder) Then
			
			Result = False;
			
			FieldName = NStr("vi = 'Lệnh';
							|ru = 'Распоряжение';
							|en = 'Reference'; fa = 'مرجع';
							|it = 'Disposizione';
							|pl = 'Zamówienie';
							|tr = 'Talimat'");
			LineNumber = ListOfOrders_.IndexOf(String);
			ErrorText = CommonClientServer.FillingErrorText("Field", "FillType", FieldName, LineNumber);
			
			Field = "ListOfOrders_[%1].ReferenceOrder";
			CommonClientServer.AddUserError(Errors, Field, ErrorText, Undefined, LineNumber);
			
		EndIf;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors);
	
	Return Result;
	
EndFunction

&AtServer
Function ResultOfClosingForm()
	
	Result = New Array;
	For Each String In ListOfOrders_ Do
		If Result.Find(String.ReferenceOrder) = Undefined Then
			Result.Add(String.ReferenceOrder);
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

#EndRegion
