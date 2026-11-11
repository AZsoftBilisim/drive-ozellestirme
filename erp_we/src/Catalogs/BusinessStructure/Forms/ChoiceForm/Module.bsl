
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("BusinessUnitIsProductionDispatcherOrProductionShopfloor") Then
		OrGroup = List.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		OrGroup.Use = True;
		CommonClientServer.SetFilterItem(OrGroup, "ProductionDispatcherBusinessUnit", True, DataCompositionComparisonType.Equal,, True);
		CommonClientServer.SetFilterItem(OrGroup, "ProductionBusinessUnit", True, DataCompositionComparisonType.Equal,, True);
	EndIf;
	
	If Parameters.Property("LinkIsNotInList") Then
		CommonClientServer.SetDynamicListFilterItem(List, "Ref", Parameters.LinkIsNotInList, DataCompositionComparisonType.NotInList, "LinkIsNotInList", True);
	EndIf;
	
	ConfigureListDisplay();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject,
		Items.CommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	Status = Settings.Get("StatusForSelection");
	If ValueIsFilled(Status) Then
		StatusSwitch = String(Status);
	EndIf;
	SetSelectionByStatus();
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	Settings.Insert("StatusForSelection", Status);
EndProcedure
#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure StatusSwitchOnChange(Item)
	SetSelectionByStatus();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServer
Procedure ListOnLoadUserSettingsAtServer(Item, Settings)
	
	ConfigureListDisplay();
	
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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure ConfigureListDisplay()
	
	If Items.List.Representation = TableRepresentation.List Then
		Return;
	EndIf;
	
	PermittedDivisions = AccessManagement.AllowedDynamicListValues(List.MainTable, Type("CatalogRef.BusinessStructure"));
	If PermittedDivisions <> Undefined Then
		Items.List.Representation = TableRepresentation.List;
	EndIf;
	
	If Parameters.Property("Filter")
		And (Parameters.Filter.Property("OptionOfAssignedAccountingOfGoods")
			Or Parameters.Filter.Property("ProductionBusinessUnit")
			Or Parameters.Filter.Property("ProductionByOrders")
			Or Parameters.Filter.Property("BackflushProduction_")
			Or Parameters.Filter.Property("RecordingExpensesOnProcustCostIsUsed")
			Or Parameters.Filter.Property("UseOperationManagement")
			Or Parameters.Filter.Property("UseManufacturingExecutionSystem")
			Or Parameters.Filter.Property("ProductionDispatcherBusinessUnit")
			Or Parameters.Filter.Property("BusinessUnitIsProductionDispatcherOrProductionShopfloor")
			Or Parameters.Filter.Property("UseShiftTasks")
			Or Parameters.Filter.Property("UseProductionSites")) Then
		// If selection is set, the list should not be hierarchical
		Items.List.Representation = TableRepresentation.List;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListSelectionCompletion(Response, ValueSelected) Export
	If Response = DialogReturnCode.Yes Then
		NotifyChoice(ValueSelected);
	EndIf;
EndProcedure

&AtServer
Procedure SetSelectionByStatus()
	If IsBlankString(StatusSwitch) Or StatusSwitch = "All" Then
		Status = Enums.BusinessUnitCompanyStatuses.EmptyRef();
	ElsIf StatusSwitch = "NotValid" Then
		Status = Enums.BusinessUnitCompanyStatuses.NotValid;
		Items.List.Representation = TableRepresentation.List;
	Else
		Status = Enums.BusinessUnitCompanyStatuses.Valid;
	EndIf;

	CommonClientServer.SetDynamicListFilterItem(List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
EndProcedure


#EndRegion
