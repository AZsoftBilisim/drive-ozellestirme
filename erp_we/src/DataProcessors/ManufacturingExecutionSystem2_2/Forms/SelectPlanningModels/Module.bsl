
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("UUID") Then
		CalledFormID = Parameters.UUID;
	Else
		CalledFormID = New UUID;
	EndIf;
	If Parameters.Property("AddressOfPlanningModel") Then
		ReadPlanningModels(Parameters.AddressOfPlanningModel);
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	DataCorrect = ModelsAreFilledInCorrectly();
	If DataCorrect Then
		
		Result = ResultOfClosingForm();
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ReadPlanningModels(AddressOfPlanningModel)
	
	If IsTempStorageURL(AddressOfPlanningModel) Then
		SourceOfFilling = GetFromTempStorage(AddressOfPlanningModel);
		If TypeOf(SourceOfFilling) = Type("ValueTable") Then
			PlanningModels.Load(SourceOfFilling);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function ModelsAreFilledInCorrectly()
	
	Result = True;
	Errors = Undefined;
	SelectedModels = New Array;
	
	For Each String In PlanningModels Do
		If Not ValueIsFilled(String.PlanningModel) Then
			
			Result = False;
			
			FieldName = NStr("vi = 'Mô hình kế hoạch';
							|ru = 'Модель планирования';
							|en = 'Planning model'; fa = 'مدل برنامه‌ریزی';
							|it = 'Modello di pianificazione';
							|pl = 'Model planowania';
							|tr = 'Planlama modeli'");
			LineNumber = PlanningModels.IndexOf(String);
			ErrorText = CommonClientServer.FillingErrorText("Field", "FillType", FieldName, LineNumber);
			
			Field = "PlanningModels[%1].PlanningModel";
			CommonClientServer.AddUserError(Errors, Field, ErrorText, Undefined, LineNumber);
			
		ElsIf Not SelectedModels.Find(String.PlanningModel) = Undefined Then
			
			Result = False;
			
			FieldName = NStr("vi = 'Mô hình kế hoạch';
							|ru = 'Модель планирования';
							|en = 'Planning model'; fa = 'مدل برنامه‌ریزی';
							|it = 'Modello di pianificazione';
							|pl = 'Model planowania';
							|tr = 'Planlama modeli'");
			LineNumber = PlanningModels.IndexOf(String);
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Mô hình ''''%1'''' được chọn nhiều lần.';
					|ru = 'Модель ""%1"" выбрана более одного раза.';
					|en = 'The ""%1"" model is selected more than once.'; fa = 'The ""%1"" model is selected more than once.';
					|it = 'Il modello ""%1"" è selezionato più di una volta.';
					|pl = 'Model ""%1"" została wybrana więcej jednego razu.';
					|tr = '""%1"" modeli bir kereden fazla seçildi.'"), String.PlanningModel);
			ErrorText = CommonClientServer.FillingErrorText("Field", "Correctness", FieldName, LineNumber,, MessageText);
			
			Field = "PlanningModels[%1].PlanningModel";
			CommonClientServer.AddUserError(Errors, Field, ErrorText, String.PlanningModel, LineNumber, ErrorText);
			
		Else
			
			SelectedModels.Add(String.PlanningModel);
			
		EndIf;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors);
	
	Return Result;
	
EndFunction

&AtServer
Function ResultOfClosingForm()
	
	ModelTable__ = PlanningModels.Unload();
	Result = PutToTempStorage(ModelTable__, CalledFormID);
	Return Result;
	
EndFunction

#EndRegion
