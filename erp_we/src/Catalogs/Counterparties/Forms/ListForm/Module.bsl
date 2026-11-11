
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	PartnersAndCounterpartiesLocalization.SetPropertiesOfDynamicListOfCounterparties(ThisForm);
		
	CommonClientServer.SetDynamicListParameter(
		List,
		"RepresentationOfASeparateDivision",
		NStr("vi = 'Chi nhánh, văn phòng đại diện';
			|ru = 'Обособленное подразделение';
			|en = 'Branch office'; fa = 'شعبه';
			|it = 'Reparto esterno';
			|pl = 'Odrębny dział';
			|tr = 'Ayrı departman'"));
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	AvailableToAddPartners = AccessRight("Insert", Metadata.Catalogs.Partners);
	
	If UsePartnersAsCounterparties Then
		ReadOnly = True;
	EndIf;
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.Counterparties);
	Items.FormChangeSelectedItems.Visible                 = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	

	PartnersAndCounterpartiesLocalization.WhenCreatingCounterpartyListFormOnServer(ThisForm, Cancel, StandardProcessing);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If CanBeEdited
		And Field = Items.MainCounterparty Then
		
		CurrentData = Item.CurrentData;
		If CurrentData.BranchOffice And Not ValueIsFilled(CurrentData.MainCounterparty) Then
			
			StandardProcessing = False;
			
			FillParameters = New Structure;
			PartnersAndCounterpartiesLocalizationClientServer.AddParametersForHeadCounterparty(FillParameters, CurrentData);
			FillParameters.Insert("Counterparty", CurrentData.Ref);
			FillParameters.Insert("Partner",    CurrentData.Partner);
			FillParameters.Insert("UsePartnersAsCounterparties", UsePartnersAsCounterparties);
			
			Notification = New CallbackDescription("FillInTheHeadCounterpartyCompletion", ThisObject);
			PartnersAndCounterpartiesClient.FillInTheHeadCounterparty(ThisObject, FillParameters, True, Notification);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
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


&AtClient
Procedure MarkSelectedOnesWithDuplicates(Command)
	SearchAndReplaceDuplicatesMasterDataClient.MarkSelectedOnesWithDuplicates(Items.List);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	PartnersAndCounterparties.SetRegistrationOfHeadCounterpartyInList(ThisForm);

EndProcedure

&AtClient
Procedure FillInTheHeadCounterpartyCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected <> Undefined Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region Localization


// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion