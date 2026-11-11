#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UsePartnersAsCounterparties = (GetFunctionalOption("UsePartnersAsCounterparties"));
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Counterparty", Counterparty, QuickFilterStructure);
	
	If Parameters.Property("Partner")
		Or (UsePartnersAsCounterparties And Parameters.Property("Filter") And Parameters.Filter.Property("Counterparty")) Then
		
		If Parameters.Property("Partner") Then
			Partner = Parameters.Partner;
		Else
			Partner = Common.ObjectAttributeValue(Parameters.Filter.Counterparty, "Partner");
		EndIf;
		
		SetPartnerSelection_();
	Else
		List.Parameters.SetParameterValue("DefaultPartner", Catalogs.Partners.EmptyRef());
		Items.CounterpartySelection_.ChoiceParameterLinks = New FixedArray(New Array);
	EndIf;
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenCreatingOnServer(State, QuickFilterStructure) Then
		CommonClientServer.SetDynamicListFilterItem(
			List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Organization", Organization, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Counterparty", Counterparty, QuickFilterStructure, Settings);
		
	If UsePartnersAsCounterparties And ValueIsFilled(Counterparty) Then
		SetSelectionByPartnerCounterparty();
	EndIf;
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenLoadingFromSettings(
			State, QuickFilterStructure, Settings) Then
		CommonClientServer.SetDynamicListFilterItem(
			List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StateOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	
EndProcedure

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure CounterpartySelection_OnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Counterparty", Counterparty, DataCompositionComparisonType.Equal,, ValueIsFilled(Counterparty));
		
	If UsePartnersAsCounterparties Then
		SetSelectionByPartnerCounterparty();
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

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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

#Region Private

&AtServer
Procedure SetSelectionByPartnerCounterparty()
	
	Partner = Common.ObjectAttributeValue(Counterparty, "Partner");
	SetPartnerSelection_();
	
EndProcedure

&AtServer
Procedure SetPartnerSelection_()
	
	List.Parameters.SetParameterValue("DefaultPartner", Partner);
	CommonClientServer.SetDynamicListFilterItem(
		List, "DefaultPartner", Partner, DataCompositionComparisonType.Equal,, ValueIsFilled(Partner));
		
	PartnerList = New ValueList;
	PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner, PartnerList);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Partner", PartnerList, DataCompositionComparisonType.InList,, ValueIsFilled(Partner));

EndProcedure

#EndRegion
