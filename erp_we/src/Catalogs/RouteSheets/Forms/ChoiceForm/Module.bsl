
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetDynamicListPropertiesList();
	
	If Parameters.Property("Filter") Then
		// It is necessary to fill in the quick selection fields
		// so that their values match the selection in the list.
		FilterStructure1 = Parameters.Filter;
		If FilterStructure1.Property("Department", FilterDepartment) Then
			If FilterDepartment.IsEmpty() Then
				Parameters.Filter.Delete("Department");
			EndIf;
		EndIf;
		If FilterStructure1.Property("Status", FilterStatus) Then
			If FilterStatus.IsEmpty() Then
				Parameters.Filter.Delete("Status");
			EndIf;
		EndIf;
	EndIf;
	
	If Parameters.Property("DisableSelection") Then
		CommonClientServer.SetDynamicListFilterItem(
			List, 
			"Ref", 
			Parameters.DisableSelection, 
			DataCompositionComparisonType.NotEqual,
			, 
			ValueIsFilled(Parameters.DisableSelection));
	EndIf;
	
	CustomizeFormElements();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region QuickFilters

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SetSelectionByStatus(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SetSelectionByDivision(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterProductsOnChange(Item)
	
	SetSelectionByProductRange(ThisForm);
	
	ConfigureDependentFormElements(ThisForm, "Products");
	
EndProcedure

&AtClient
Procedure FilterUsedAsOnChange(Item)
	
	SetSelectionByProductRange(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	KeysList = Rows.GetKeys();
	If KeysList.UBound() = -1 Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT DISTINCT
	|	Table.RouteSheet AS Ref
	|FROM
	|	InformationRegister.MainRouteSheets AS Table
	|WHERE
	|	Table.RouteSheet IN (&RouteSheets)
	|	AND (Table.Products = &Products
	|		OR &Products = VALUE(Catalog.Products.EmptyRef)
	|	) AND Table.RouteSheet.Status = VALUE(Enum.StatusesOfRouteSheets.Valid)
	|");
	Query.SetParameter("RouteSheets", KeysList);
	
	If Settings.AdditionalProperties.Property("Products") Then
		Query.SetParameter("Products", Settings.AdditionalProperties.Products);
	Else
		Query.SetParameter("Products", Catalogs.Products.EmptyRef());
	EndIf;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ListLine = Rows[Selection.Ref];
		For Each Appearance In ListLine.Appearance Do
			Appearance.Value.SetParameterValue("Font", New Font(,,True));
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

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

#Region Private

#Region Filters

&AtClientAtServerNoContext
Procedure SetSelectionByStatus(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List, 
		"Status", 
		Form.FilterStatus, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterStatus));

EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByDivision(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List, 
		"Department", 
		Form.FilterDepartment, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterDepartment));

EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByProductRange(Form)
	
	ProductDataManagementClientServer.SetSelectionByProductInRouteMapList(
		Form.List,
		Form.FilterProducts,
		Form.FilterUsedAs);

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	Catalogs.RouteSheets.SetConditionalAppearanceOfRouteMapList(List.ConditionalAppearance);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Products")
		Or Initialize Then
		
		Form.Items.FilterUsedAs.ReadOnly = Not ValueIsFilled(Form.FilterProducts);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDynamicListPropertiesList()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = Catalogs.RouteSheets.RequestTextForDynamicListOfRouteMaps();
	ListProperties.QueryText = QueryText;
	
	ListProperties.MainTable = List.MainTable;
	ListProperties.DynamicDataRead = True;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
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

#EndRegion

