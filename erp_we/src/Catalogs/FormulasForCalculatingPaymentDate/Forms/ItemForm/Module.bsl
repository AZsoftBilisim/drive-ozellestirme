#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	Items.EditFormula.Enabled = AccessRight("Edit",Metadata.Catalogs.FormulasForCalculatingPaymentDate);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, ThisObject.Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	AttachableCommandsClient.AfterWrite(ThisObject, ThisObject.Object, WriteParameters);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EditFormula(Command)
	
	UsageInstances = PlacesWhereFormulaIsUsed();
	If UsageInstances.Count() > 0 Then 
		QueryText = StrTemplate(NStr("ru = 'Объектов, использующих формулу: %1. Продолжить редактирование?';
									|vi = 'Objects using the formula: %1. Continue editing?';
									|en = 'Objects using the formula: %1. Continue editing?'; fa = 'Objects using the formula: %1. Continue editing?';
									|it = 'Objects using the formula: %1. Continue editing?';
									|pl = 'Objects using the formula: %1. Continue editing?';
									|tr = 'Formülü kullanan nesne sayısı: %1. Düzenlemeye devam edilsin mi?'"),UsageInstances.Count());
		ShowQueryBox(New CallbackDescription("EditFormulaCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
	Else
		ContinueEditing();
	EndIf;
		
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure EditFormulaCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ContinueEditing();
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueEditing()
	
	EditParameters = OptionsOfFormulaEditing();
	
	ConstructorParameters = New Structure;
	ConstructorParameters.Insert("Formula", Object.Formula);
	ConstructorParameters.Insert("ResultType", New TypeDescription("Date"));
	ConstructorParameters.Insert("OperandsTree", EditParameters.OperandsTree);
	ConstructorParameters.Insert("Operators", EditParameters.Operators);
	
	CallbackDescription = New CallbackDescription("ChangingFormulaCompletion", ThisObject);
	
	OpenForm(
		"CommonForm.FormulasConstructor",
		ConstructorParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChangingFormulaCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Result = TrimAll(Result);
		If Object.Formula <> Result Then
			Modified = True;
			Object.Formula = Result;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function OptionsOfFormulaEditing()
	EditParameters = New Structure;
	
	OperandTreeForFormula = PaymentStepsServer.OperandTreeForFormula();
	StorageAddressOperandTree = PutToTempStorage(OperandTreeForFormula, New UUID);
	EditParameters.Insert("OperandsTree",StorageAddressOperandTree);
	
	OperatorParameters = New Structure;
	OperatorParameters.Insert("StandardOperators",True);
	OperatorParameters.Insert("BooleanOperators",True);
	OperatorParameters.Insert("Functions",True);
	
	StorageAddressOperators = ProcessingOfFormulas.BuildTreeOfOperators(OperatorParameters, New UUID);
	EditParameters.Insert("Operators",StorageAddressOperators);
	
	Return EditParameters
	
EndFunction

&AtServer
Function PlacesWhereFormulaIsUsed()
	
	If Not ValueIsFilled(Object.Ref) Then
		Return New Array;
	EndIf;
	
	Return FilterCriteria.UseFormulas.Find(Object.Ref);
	
EndFunction

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, ThisObject.Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, ThisObject.Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, ThisObject.Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
