
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser());
		
	If Partner = Undefined Or Partner.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
	
	SelfServiceServer.ListFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	SelfServiceServer.FillInContactPersonSelectionList(Items.ContactPersonFilter.ChoiceList, Partner, ContactPerson);
	SetItemsVisibility();
	List.Parameters.SetParameterValue("Partner",          Partner);
	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);

	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ContactPersonFilter  = Settings.Get("ContactPersonFilter");
	SelfServiceClientServer.SetListSelectionByContactPerson(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ContactPersonFilterOnChange(Item)
	
	SelfServiceClientServer.SetListSelectionByContactPerson(ThisObject);
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Status <> PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon") Then
		Cancel = True;
		Print();
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Copy Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetItemsVisibility()
	
	Items.ListState.Visible = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
EndProcedure

&AtClient
Procedure Print()

	ReferencesArrray = New Array;
	For Each Ref In Items.List.SelectedRows Do
		ReferencesArrray.Add(Ref);
	EndDo;
	
	SelfServiceClient.PrintDocumentRequestForRefund(ReferencesArrray);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
