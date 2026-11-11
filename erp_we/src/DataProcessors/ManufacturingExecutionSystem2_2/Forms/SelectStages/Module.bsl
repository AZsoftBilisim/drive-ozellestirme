
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
	
	DataCorrect = StagesAreFilledInCorrectly();
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
	
	Department = Parameters.Department;
	References.LoadValues(Parameters.References);
	
	If ValueIsFilled(References) Then 
		CommunicationDivision = New ChoiceParameterLink("Filter.Department", "Department");
		CommunicationOfOrder = New ChoiceParameterLink("Filter.ReferenceOrder", "References");
		NewArray = New Array();
		NewArray.Add(CommunicationDivision);
		NewArray.Add(CommunicationOfOrder);
		NewLinks = New FixedArray(NewArray);
		Items.StageListStage.ChoiceParameterLinks = NewLinks;
	EndIf;
	
	For Each Stage In Parameters.Stages Do
		
		ValuesRow = StageList.Add();
		ValuesRow.Stage = Stage;
		
	EndDo;		
	
EndProcedure

&AtClient
Function StagesAreFilledInCorrectly()
	
	Result = True;
	Errors = Undefined;
	
	For Each String In StageList Do
		If Not ValueIsFilled(String.Stage) Then
			
			Result = False;
			
			FieldName = NStr("vi = 'Công đoạn sản xuất';
							|ru = 'Этап производства';
							|en = 'Production stage'; fa = 'مرحله تولید';
							|it = 'Fase di produzione';
							|pl = 'Etap produkcji';
							|tr = 'Üretim aşaması'");
			LineNumber = StageList.IndexOf(String);
			ErrorText = CommonClientServer.FillingErrorText("Field", "FillType", FieldName, LineNumber);
			
			Field = "StageList[%1].Stage";
			CommonClientServer.AddUserError(Errors, Field, ErrorText, Undefined, LineNumber);
			
		EndIf;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors);
	
	Return Result;
	
EndFunction

&AtServer
Function ResultOfClosingForm()
	
	Result = New Array;
	For Each String In StageList Do
		If Result.Find(String.Stage) = Undefined Then
			Result.Add(String.Stage);
		EndIf;
	EndDo;
	Return Result;
	
EndFunction


#EndRegion
