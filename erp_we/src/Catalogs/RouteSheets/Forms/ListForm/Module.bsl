
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetDynamicListPropertiesList();
	
	If Parameters.Property("Product") Then // The form opens from the nomenclature card
		
		DoNotImportSettings = True;
		FilterProducts = Parameters.Product;
		SetSelectionByProductRange(ThisForm);
		
	EndIf;
	
	CustomizeFormElements();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ProductionServer.AddWarningRouteMapsAreOutdated(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_MainRouteSheets" Then
		Items.List.Refresh();
	EndIf; 
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If DoNotImportSettings Then
		Settings.Delete("FilterStatus");
		Settings.Delete("FilterEmployeeResponsible");
		Settings.Delete("FilterDepartment");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If DoNotImportSettings Then
		Return;
	EndIf;
	
	SetSelectionByStatus(ThisForm);
	SetSelectionByDivision(ThisForm);
	SetSelectionByResponsible(ThisForm);
	
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
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	SetSelectionByResponsible(ThisForm);
	
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

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Var_Group Then
		Return;
	EndIf;
	
	If Copy Then
		
		Cancel = True;
		
		CopyRouteMap();
		
	ElsIf Not FilterProducts.IsEmpty() Then
		
		Cancel = True;
		
		FormParameters = New Structure;
		FormParameters.Insert("Basis", FilterProducts);
		OpenForm("Catalog.RouteSheets.ObjectForm", FormParameters);
		
	EndIf; 
	
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

#Region FormCommandsEventHandlers

&AtClient
Procedure TheSetStatusInDevelopmentCommand(Command)
	
	SetStatus("UnderDevelopment", NStr("vi = 'Đang phát triển';
										|ru = 'В разработке';
										|en = 'Under development'; fa = 'در حال توسعه';
										|it = 'In elaborazione';
										|pl = 'W opracowaniu';
										|tr = 'Geliştirme aşamasında'"));
	
EndProcedure

&AtClient
Procedure TheSetStatusCommandIsActive(Command)
	
	SetStatus("Valid", NStr("vi = 'Có hiệu lực';
							|ru = 'Действует';
							|en = 'Valid'; fa = 'معتبر';
							|it = 'In vigore';
							|pl = 'Aktualne';
							|tr = 'Aktif'"));
	
EndProcedure

&AtClient
Procedure TheSetStatusClosedCommand(Command)
	
	SetStatus("Closed_", NStr("vi = 'Đã đóng';
								|ru = 'Закрыта';
								|en = 'Closed'; fa = 'بسته‌شده';
								|it = 'Chiusa';
								|pl = 'Zamknięta';
								|tr = 'Kapalı'"));
	
EndProcedure

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
Procedure SetSelectionByResponsible(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List, 
		"EmployeeResponsible", 
		Form.FilterEmployeeResponsible, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterEmployeeResponsible));
	
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

&AtClient
Procedure SetStatus(StatusValue, StatusPresentation)

	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	ProductDataManagementClient.SetRouteMapStatus(StatusValue, StatusPresentation, HighlightedLinks);

EndProcedure

&AtClient
Procedure CopyRouteMap()
	
	CallbackDescription = New CallbackDescription("QuestionCopyRouteMap", ThisForm);
	ProductDataManagementClient.ShowCopyRouteMapWithOperationsQuestion(CallbackDescription);
	
EndProcedure

&AtClient
Procedure QuestionCopyRouteMap(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Ref = CopyRouteMapOnServer(Items.List.CurrentData.Ref);
	
	If Ref <> Undefined Then
		
		Items.List.CurrentRow = Ref;
		
		ProductDataManagementClient.NotifyAboutCopyingRouteMapWithOperations();
		
		OpenForm("Catalog.RouteSheets.ObjectForm", New Structure("Key", Ref));
	
	EndIf; 

EndProcedure
 
&AtServerNoContext
Function CopyRouteMapOnServer(Source)
	
	Return Catalogs.RouteSheets.CopyRouteMapWithOperations(Source);
	
EndFunction

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
