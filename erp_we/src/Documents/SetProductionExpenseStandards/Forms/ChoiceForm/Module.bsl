#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	#Region Filters
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Department", Department, QuickFilterStructure);
	
	#EndRegion
	
	#Region UniversalMechanisms
	
	ToDoListOverridable.OnCreateAtServer(ThisForm, List);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	#EndRegion
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ToDoListOverridable.BeforeLoadDataFromSettingsAtServer(ThisForm, Settings);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Var FiltersStructure;
	
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		
		If FiltersStructure.Property("Department") Then
			Settings.Insert("Department", FiltersStructure.Department)
		EndIf;
		
		If FiltersStructure.Property("Organization") Then
			Settings.Insert("Organization", FiltersStructure.Organization)
		EndIf;
		
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Department", Department, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Organization", Organization, QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Department", Department, DataCompositionComparisonType.Equal,, ValueIsFilled(Department));
	
EndProcedure

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

#EndRegion

#Region ListEventHandlers_

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region Universal_

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
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

&AtClient
Procedure ProductionExpenseStandards(Command)
	
	CurrentData = Items.List.CurrentData;
	EndOfPeriod = CurrentData.ValidityEndDate;
	If Not ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod = EndOfYear(CurrentData.ValidityStartDate);
	EndIf;
	
	PeriodParameter = New StandardPeriod(CurrentData.ValidityStartDate, EndOfPeriod);
	
	Filter = New Structure;
	Filter.Insert("StandardPeriod", PeriodParameter);
	Filter.Insert("Organization", CurrentData.Organization);
	Filter.Insert("Department", CurrentData.Department);
	
	FormParameters = New Structure("VariantKey, PurposeUseKey, Filter, GenerateOnOpen, ReportOptionsCommandsVisibility");
	FormParameters.Insert("PurposeUseKey",		Undefined);
	FormParameters.Insert("Filter",							Filter);
	FormParameters.Insert("GenerateOnOpen",			True);
	FormParameters.Insert("ReportOptionsCommandsVisibility",	False);
	
	OpenForm("Report.PlannedAndActualProductionExpenseStandards.Form", FormParameters);

EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List", "Date");

EndProcedure

#EndRegion
