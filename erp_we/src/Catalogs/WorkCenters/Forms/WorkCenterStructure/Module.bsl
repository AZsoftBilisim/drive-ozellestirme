
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	LoadSettings();
	
	If Not Parameters.Department.IsEmpty() Then
		Department = Parameters.Department;
	EndIf;
	If Parameters.EditSections Then
		OperationModeByAreas = True;
	EndIf;
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.WorkCenters);
	Items.WorkCentersChangeSelectedItems.Visible = CanBeEdited;
	Items.WorkCentersContextMenuChangeSelectedItems.Visible = CanBeEdited;
	
	WorkCenterTypesFirstActivation = True;
	AreasFirstActivation = True;
	
	FillInByDivision(ThisForm);
	
	ConfigureDependentFormElements(ThisForm);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription("CatalogRef.WorkCenters");
	PlacementParameters.CommandBar = Items.WorkCenters.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_WorkCenters" Then
		// Let's update the counter of the number of RC
		Items.WorkCenterTypes.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentOnChange(Item)
	
	ShouldSaveSettings(ThisObject);
	
	FillInByDivision(ThisForm);
	
	ConfigureDependentFormElements(ThisForm, "Department,OperationModeByAreas");
	
EndProcedure

&AtClient
Procedure HeaderLeadingListURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	OperationModeByAreas = Not OperationModeByAreas;
	
	ShouldSaveSettings(ThisObject);
	
	ConfigureDependentFormElements(ThisForm, "OperationModeByAreas");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWorkCenterTypes

&AtClient
Procedure WorkCenterTypesOnActivateRow(Item)
	
	If FilterByAreaKind Then
		
		If WorkCenterTypesFirstActivation Then
			ConfigureDependentFormElements(ThisForm, "WorkCenterTypes");
		Else
			AttachIdleHandler("TypesOfWorkCentersWhenActivatingDeferredLine", 0.2, True);
		EndIf;
		
	EndIf; 
	
	WorkCenterTypesFirstActivation = False;
	
EndProcedure

&AtClient
Procedure TypesOfWorkCentersWhenActivatingDeferredLine()
	
	ConfigureDependentFormElements(ThisForm, "WorkCenterTypes");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAreas

&AtClient
Procedure AreasOnActivateRow(Item)
	
	If FilterByAreaKind Then
		
		If AreasFirstActivation Then
			ConfigureDependentFormElements(ThisForm, "Areas");
		Else
			AttachIdleHandler("SectionsWhenActivatingDeferredLine", 0.2, True);
		EndIf;
		
	EndIf; 
	
	AreasFirstActivation = False;
	
EndProcedure

&AtClient
Procedure SectionsWhenActivatingDeferredLine()
	
	ConfigureDependentFormElements(ThisForm, "Areas");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWorkCenters

&AtClient
Procedure WorkCentersOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure WorkCentersBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder)
	
	If IsFolder Or Copy Then
		Return;
	EndIf;
	
	FillingValues = New Structure;
	
	If OperationModeByAreas Then
		
		CurrentRow = Items.Areas.CurrentRow;
		If FilterByAreaKind And CurrentRow <> Undefined Then
			
			If TypeOf(CurrentRow) = Type("DynamicListGroupRow") Then
				FillingValues.Insert("Department", CurrentRow.Key);
			Else
				FillingValues.Insert("ProductionArea", CurrentRow);
			EndIf;
			
		EndIf;
		
	Else
		
		CurrentRow = Items.WorkCenterTypes.CurrentRow;
		If FilterByAreaKind	And CurrentRow <> Undefined Then
			FillingValues.Insert("WorkCenterType", CurrentRow);
		EndIf;
		
	EndIf;
	
	If FillingValues.Count() = 0 And Not Department.IsEmpty() Then
		FillingValues.Insert("Department", Department);
	EndIf;
	
	If FillingValues.Count() > 0 Then
		
		Cancel = True;
		
		OpenForm("Catalog.WorkCenters.ObjectForm",
			New Structure("FillingValues", FillingValues));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WorkCentersOnLoadUserSettingsAtServer(Item, Settings)
	
	ConfigureDependentFormElements(ThisForm, "WorkCenters_UserSettings");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region StandardSubsystems

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.WorkCenters);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.WorkCenters, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.WorkCenters);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

&AtClient
Procedure FilterByType(Command)
	
	FilterByAreaKind = Not FilterByAreaKind;
	
	ShouldSaveSettings(ThisObject);
	
	ConfigureDependentFormElements(ThisForm, "FilterByAreaKind,WorkCenterTypes");
	
EndProcedure

&AtClient
Procedure FilterByArea(Command)
	
	FilterByAreaKind = Not FilterByAreaKind;
	
	ShouldSaveSettings(ThisObject);
	
	ConfigureDependentFormElements(ThisForm, "FilterByAreaKind,Areas");
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.WorkCenters);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure FillInByDivision(Form)
	
	FOParameters = New Structure(
		"Department",
		?(ValueIsFilled(Form.Department), Form.Department, Undefined));
	
	Form.SetFormFunctionalOptionParameters(FOParameters);
	
	Form.ThereAreAreas = Form.GetFormFunctionalOption("UseProductionSites");
	
	If Not Form.ThereAreAreas And Form.OperationModeByAreas Then
		
		Form.OperationModeByAreas = False;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	// Setting by operating mode - types of RC/sites
	If AttributesStructure1.Property("OperationModeByAreas")
		Or Initialize Then
		
		Items.WorkCentersFilterByType.Visible = Not Form.OperationModeByAreas;
		Items.WorkCentersFilterByArea.Visible = Form.OperationModeByAreas;
		
		Items.PagesLeadingList.CurrentPage = ?(Form.OperationModeByAreas,
			Items.LandPlotsPage,
			Items.PageTypesOfWorkCenters);
		
		RowsArray = New Array;
		
		If Form.ThereAreAreas Then
			
			If Form.OperationModeByAreas Then
				RowsArray.Add(New FormattedString(NStr("vi = 'Khu vực';
														|ru = 'Участки';
														|en = 'Sites'; fa = 'سایت‌ها';
														|it = 'Lotti';
														|pl = 'Sites';
														|tr = 'Sahalar'")));
			Else
				RowsArray.Add(New FormattedString(NStr("vi = 'Khu vực';
														|ru = 'Участки';
														|en = 'Sites'; fa = 'سایت‌ها';
														|it = 'Lotti';
														|pl = 'Sites';
														|tr = 'Sahalar'"),,,,"#Areas"));
			EndIf;
			
			RowsArray.Add("  ");
			
		EndIf;
		
		If Form.OperationModeByAreas Then
			RowsArray.Add(New FormattedString(NStr("vi = 'Dạng nguồn lực sản xuất';
													|ru = 'Виды рабочих центров';
													|en = 'Work center types'; fa = 'انواع مرکز کاری';
													|it = 'Tipi di centri operativi';
													|pl = 'Rodzaj centrów wykonania pracy';
													|tr = 'İş merkezi türleri'"),,,,"#TypesOfRC"));
		Else
			RowsArray.Add(New FormattedString(NStr("vi = 'Dạng nguồn lực sản xuất';
													|ru = 'Виды рабочих центров';
													|en = 'Work center types'; fa = 'انواع مرکز کاری';
													|it = 'Tipi di centri operativi';
													|pl = 'Rodzaj centrów wykonania pracy';
													|tr = 'İş merkezi türleri'")));
		EndIf;
	
		Form.HeaderLeadingList = New FormattedString(RowsArray);
		
	EndIf;
	
	// Selection by type of RC
	If AttributesStructure1.Property("WorkCenterTypes")
		Or AttributesStructure1.Property("OperationModeByAreas") Then
		
		FilterValue = ?(Items.WorkCenterTypes.CurrentRow <> Undefined,
			Items.WorkCenterTypes.CurrentRow,
			PredefinedValue("Catalog.WorkCenterTypes.EmptyRef"));
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.WorkCenters, 
			"WorkCenterType",
			FilterValue,
			DataCompositionComparisonType.InHierarchy,
			, 
			Form.FilterByAreaKind And Not Form.OperationModeByAreas);
		
	EndIf;
	
	// The selection on the site
	If AttributesStructure1.Property("Areas")
		Or AttributesStructure1.Property("OperationModeByAreas") Then
		
		SetFilter = False;
		FilterValue = Undefined;
		
		If TypeOf(Items.Areas.CurrentRow) <> Type("DynamicListGroupRow") Then
			
			SetFilter = True;
			
			FilterValue = ?(Items.Areas.CurrentRow <> Undefined,
				Items.Areas.CurrentRow,
				PredefinedValue("Catalog.ProductionSites.EmptyRef"));
			
		EndIf;
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.WorkCenters, 
			"ProductionArea",
			FilterValue, 
			DataCompositionComparisonType.Equal,
			,
			SetFilter And Form.FilterByAreaKind And Form.OperationModeByAreas);
		
	EndIf;
	
	// Selection of work centers by division (in pm, selection by grouping line)
	If AttributesStructure1.Property("Department")
		Or AttributesStructure1.Property("Areas")
		Or AttributesStructure1.Property("OperationModeByAreas") Then
		
		SetFilter = False;
		FilterValue = Undefined;
		
		If ValueIsFilled(Form.Department) Then
			
			SetFilter = True;
			FilterValue = Form.Department;
			
		ElsIf Form.FilterByAreaKind
			And Form.OperationModeByAreas
			And TypeOf(Items.Areas.CurrentRow) = Type("DynamicListGroupRow") Then
			
			SetFilter = True;
			FilterValue = Items.Areas.CurrentRow.Key;
			
		EndIf;
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.WorkCenters, 
			"WorkCenterType.Department", 
			FilterValue,
			DataCompositionComparisonType.Equal,
			, 
			SetFilter);
		
	EndIf;
	
	// Selection of work centers by division (initialization)
	If Initialize Then
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.WorkCenters, 
			"WorkCenterType.Department", 
			Form.Department, 
			DataCompositionComparisonType.Equal,
			, 
			ValueIsFilled(Form.Department));
			
	EndIf;
	
	// selection by division
	If AttributesStructure1.Property("Department")
		Or Initialize Then
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.WorkCenterTypes, 
			"Department", 
			Form.Department, 
			DataCompositionComparisonType.Equal,
			, 
			ValueIsFilled(Form.Department));
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.Areas, 
			"Owner", 
			Form.Department, 
			DataCompositionComparisonType.Equal,
			, 
			ValueIsFilled(Form.Department));
		
	EndIf;
	
	// Displaying a list of RC
	If AttributesStructure1.Property("FilterByAreaKind")
		Or AttributesStructure1.Property("Department")
		Or AttributesStructure1.Property("WorkCenters_UserSettings")
		Or Initialize Then
		
		If Form.FilterByAreaKind Or Not Form.Department.IsEmpty() Then
			
			// Enabled selection
			If Form.DisplayWorkCenterList = Undefined
				Or AttributesStructure1.Property("WorkCenters_UserSettings") Then
				
				Form.DisplayWorkCenterList = Items.WorkCenters.Representation;
				
			EndIf;
			
			If Items.WorkCenters.Representation <> TableRepresentation.List Then
				
				Items.WorkCenters.Representation = TableRepresentation.List;
				
			EndIf;
			
		ElsIf Form.DisplayWorkCenterList <> Undefined Then
			
			// Disabled selection
			Items.WorkCenters.Representation = Form.DisplayWorkCenterList;
			DisplayWorkCenterList = Undefined;
			
		EndIf;
		
	EndIf;
	
	// Marking the selection buttons to the stage
	If AttributesStructure1.Property("FilterByAreaKind") 
		Or Initialize Then
		
		Items.WorkCentersFilterByType.Check = Form.FilterByAreaKind;
		Items.WorkCentersFilterByArea.Check = Form.FilterByAreaKind;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadSettings()
	
	Settings = Common.CommonSettingsStorageLoad(
		"Catalog.WorkCenters.WorkCenterStructure",
		Undefined);
	
	If TypeOf(Settings) = Type("Structure") Then
		
		Settings.Property("Department",         Department);
		Settings.Property("FilterByAreaKind",    FilterByAreaKind);
		Settings.Property("OperationModeByAreas", OperationModeByAreas);
		
	Else
		
		// Settings were not saved, setting default values
		FilterByAreaKind = True;
		OperationModeByAreas = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ShouldSaveSettings(Form)
	
	Settings = New Structure;
	
	Settings.Insert("Department",         Form.Department);
	Settings.Insert("FilterByAreaKind",    Form.FilterByAreaKind);
	Settings.Insert("OperationModeByAreas", Form.OperationModeByAreas);
	
	WriteSettingsToStorage(Settings);
	
EndProcedure

&AtServerNoContext
Procedure WriteSettingsToStorage(Settings)
	
	Common.CommonSettingsStorageSave(
		"Catalog.WorkCenters.WorkCenterStructure",
		Undefined,
		Settings);
	
EndProcedure

#EndRegion
