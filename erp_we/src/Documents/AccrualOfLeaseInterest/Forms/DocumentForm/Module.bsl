
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnReadCreateAtServer();

	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_AccrualOfLeaseInterest", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure
	
#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RegistrationPeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("RegistrationPeriodPresentationStartChoiceCompletion", ThisObject);
	
	PeriodSelectionFormParameters = New Structure("Value, PeriodSelectionMode", Object.Date, "MONTH");
	OpenForm("CommonForm.PeriodSelection",
		PeriodSelectionFormParameters, 
		ThisObject, 
		UUID,,, 
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationTuning(Item, Direction, StandardProcessing)
	
	Modified = True;
	
	RegistrationPeriod = BegOfMonth(Object.Date);
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(Direction,
		StandardProcessing,
		RegistrationPeriod,
		RegistrationPeriodPresentation);
		
	Object.Date = RegistrationPeriod;
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

#Region StandardSubsystems

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	RegistrationPeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);

EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		Modified = True;
		Object.Date = EndOfMonth(SelectedPeriod);
		RegistrationPeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

#EndRegion