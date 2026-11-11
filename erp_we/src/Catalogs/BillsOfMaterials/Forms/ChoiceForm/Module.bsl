
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("FilterStatus",             FilterStatus);
	Parameters.Property("FilterProduct",            FilterProducts);
	Parameters.Property("FilterUsedAs",    FilterUsedAs);
	Parameters.Property("FilterBOMList", FilterBOMList);
	
	Parameters.Property("GetProductBOM", GetProductBOM);
	
	ArrayOfSpecifications = New Array;
	If Parameters.Property("ArrayOfSpecifications", ArrayOfSpecifications) Then
		BOMList.LoadValues(ArrayOfSpecifications);
	EndIf;
	
	SetDynamicListProperties();
	
	SetSelectionByProductRange();
	SetSelectionByStatus(ThisObject);
	SetSelectionByListOfSpecifications(ThisObject);
	
	CustomizeFormElements();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterProductsOnChange(Item)
	
	SetSelectionByProductRange();
	
	ConfigureDependentFormElements(ThisObject, "Products");
	
EndProcedure

&AtClient
Procedure FilterUsedAsOnChange(Item)
	
	SetSelectionByProductRange();
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SetSelectionByStatus(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterBOMListOnChange(Item)
	
	SetSelectionByListOfSpecifications(ThisObject);

	ConfigureDependentFormElements(ThisObject, "FilterBOMList");
	
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
Procedure UpdateData1(Command)
	
	SetSelectionByProductRange();
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

#Region List

&AtServer
Procedure SetDynamicListProperties()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = Catalogs.BillsOfMaterials.RequestTextForDynamicListOfResourceSpecifications();
	ListProperties.QueryText = QueryText;
	
	ListProperties.MainTable = List.MainTable;
	ListProperties.DynamicDataRead = True;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
EndProcedure

#EndRegion

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

&AtServer
Procedure SetSelectionByProductRange()

	ProductDataManagement.SetSelectionByProductInListOfSpecifications(List, FilterProducts, FilterUsedAs);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByListOfSpecifications(Form)
	
	BOMList = Form.BOMList.UnloadValues();
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Ref",
		BOMList,
		DataCompositionComparisonType.InList,
		,
		Form.FilterBOMList);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Catalogs.BillsOfMaterials.SetConditionalAppearanceOfListOfResourceSpecifications(List.ConditionalAppearance);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	Items.FilterBOMList.Visible = FilterBOMList;
	
	If GetProductBOM Then
		Items.QuickFilters.Visible = False;
		AutoTitle = False;
		Title = StrTemplate(NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất %1';
								|ru = 'Ресурсные спецификации %1';
								|en = 'Bills of materials %1'; fa = 'Bills of materials %1';
								|it = 'Specifiche delle risorse (%1)';
								|pl = 'Specyfikacje zasobów %1';
								|tr = 'Ürün reçeteleri %1'"), FilterProducts);
	EndIf;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Products")
		Or Initialize Then
		
		Items.FilterUsedAs.ReadOnly = Not ValueIsFilled(Form.FilterProducts);
		
	EndIf;
	
	If AttributesStructure1.Property("FilterBOMList")
		Or Initialize Then
		
		Items.List.Representation = ?(
			Form.FilterBOMList Or Form.GetProductBOM,
			TableRepresentation.List,
			TableRepresentation.HierarchicalList);
		
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

#EndRegion

