
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	List.Parameters.SetParameterValue("AllowSelectionOfInvalid", Parameters.AllowSelectionOfInvalid);
	List.Parameters.SetParameterValue("DocumentDate", ?(ValueIsFilled(Parameters.DocumentDate), BegOfDay(Parameters.DocumentDate), BegOfDay(CurrentSessionDate())));
	If Parameters.Filter.Property("Partner") Then
		Partner = Parameters.Filter.Partner;
	EndIf;
	If Parameters.Filter.Property("BusinessOperation") Then
		BusinessOperation = Parameters.Filter.BusinessOperation;
	Else
		CommonClientServer.SetDynamicListFilterItem(List, 
			"BusinessOperation", 
			Enums.BusinessTransactions.AgentServicesDelivery, 
			DataCompositionComparisonType.NotEqual,, 
			True);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Manager      = Settings.Get("Manager");
	Organization   = Settings.Get("Organization");
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
	CompanyArray = New Array();
	CompanyArray.Add(Organization);
	CompanyArray.Add(PredefinedValue("Catalog.Companies.EmptyRef"));
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", CompanyArray, DataCompositionComparisonType.InList,, ValueIsFilled(Organization));
	
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

#Region EventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	CompanyArray = New Array();
	CompanyArray.Add(Organization);
	CompanyArray.Add(PredefinedValue("Catalog.Companies.EmptyRef"));
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", CompanyArray, DataCompositionComparisonType.InList,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Copy Then
		Return;
	EndIf;

	Cancel = True;
	
	FilterParameters = New Structure();
	FilterParameters.Insert("Organization", Organization);
	FilterParameters.Insert("Partner", Partner);
	If ValueIsFilled(BusinessOperation) Then
		FilterParameters.Insert("BusinessOperation", BusinessOperation);
	EndIf;
	
	OpenForm(
		"Catalog.TermsOfPurchaseFromVendors.ObjectForm",
		New Structure("FillingValues", FilterParameters),
		,
		,);
	
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

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

