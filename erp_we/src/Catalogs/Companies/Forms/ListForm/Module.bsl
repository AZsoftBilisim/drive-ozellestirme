
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SetDynamicListParameters();
	
	If Not GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		Items.BranchOffice.Visible = False;
	EndIf;
	
	Items.GroupCreateOrganization.Visible = AccessRight("Insert", Metadata.Catalogs.Companies);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem


	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Return;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
	Return;
	
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

&AtClient
Procedure CreateIndividualEntrepreneur(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("CompanyType", "IndividualEntrepreneur");
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("FillingValues", FillingValues);
		
	OpenForm("Catalog.Companies.ObjectForm", ParametersStructure, ThisForm);

EndProcedure

&AtClient
Procedure CreateBranchOffice(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("CompanyType", "BranchOffice");
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("FillingValues", FillingValues);
		
	OpenForm("Catalog.Companies.ObjectForm", ParametersStructure, ThisForm);

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure SetDynamicListParameters()
	
	UseManagementCompany = GetFunctionalOption("UseManagementCompany");
	If Not UseManagementCompany Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Ref",
			Catalogs.Companies.ManagementCompany,
			DataCompositionComparisonType.NotEqual);
	EndIf;
	
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
