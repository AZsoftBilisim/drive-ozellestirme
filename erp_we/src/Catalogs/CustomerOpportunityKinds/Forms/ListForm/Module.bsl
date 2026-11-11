#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not GetFunctionalOption("UseBusinessProcessesAndTasks") Then
		
		FilterList = New ValueList;
		FilterList.Add(Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities);
		FilterList.Add(Enums.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement);
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"SalesOpportunityType",
			FilterList,
			DataCompositionComparisonType.InList,
			,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
	EndIf;
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.CustomerOpportunityKinds);
	Items.FormChangeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
		
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
