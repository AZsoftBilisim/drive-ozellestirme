
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AvailableFilterIsUsedInOrders = False;
	AvailableFilterIsUsedInOrders = (AccessRight("Read", Metadata.Documents.ProductionOrder2_2)
										And AccessRight("Read", Metadata.Documents.ProductionStage2_2));
	If Parameters.Property("Product") Then
		// The form opens from the nomenclature card
		FilterProducts = Parameters.Product;
		DoNotImportSettings = True;
	EndIf;
	
	SetPropertiesAndSelectionsInListOfSpecifications();
	
	SetSelectionByProductRange();
	SetSelectionByStatus(ThisForm);
	
	If Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
	EndIf;
	
	CustomizeFormElements();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	InformationRegisters.JobsOfStandardProductionDurationCalculation.RunJob();
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If DoNotImportSettings Then
		Settings.Delete("FilterStatus");
		Settings.Delete("FilterProducts");
		Settings.Delete("FilterWorkCenterType");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If DoNotImportSettings Then
		Return;
	EndIf;
	
	SetPropertiesAndSelectionsInListOfSpecifications();
	
	SetSelectionByStatus(ThisForm);
	SetSelectionByProductRange();
	
	ConfigureDependentFormElements(ThisForm, "Products");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SetSelectionByStatus(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterProductsOnChange(Item)
	
	SetSelectionByProductRange();
	ConfigureDependentFormElements(ThisForm, "Products");
	
EndProcedure

&AtClient
Procedure FilterUsedAsOnChange(Item)
	
	SetSelectionByProductRange();
	
EndProcedure

&AtClient
Procedure FilterWorkCenterTypeOnChange(Item)
	EstablishSelectionByTypeOfWorkCenter();
	ConfigureDependentFormElements(ThisForm, "WorkCenterType");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure FilterSetupSettingsOnChange(Item)
	SetSelectionByAdjustmentOption();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure FilterUsedInOrdersOnChange(Item)
	SetSelectionByUsageInOrders();
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If TypeOf(RowSelected) = Type("DynamicListGroupRow") Then
		StandardProcessing = False;
		ShowValue(, RowSelected.Key);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Var_Group Then
		Return;
	EndIf;
	
	If Copy Then
		
		Cancel = True;
		CopyResourceSpecification();
		
	ElsIf Not FilterProducts.IsEmpty()
		And (Not ValueIsFilled(FilterUsedAs) Or FilterUsedAs = PredefinedValue("Enum.UseOfItemsInProductionMasterData.Product")) Then
		
		Cancel = True;
		
		FormParameters = New Structure;
		FormParameters.Insert("Basis", FilterProducts);
		OpenForm("Catalog.BillsOfMaterials.ObjectForm", FormParameters);
		
	EndIf; 
	
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
Procedure UpdateData1(Command)
	
	SetSelectionByProductRange();
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure TheSetStatusInDevelopmentCommand(Command)
	
	SetSpecificationStatus("UnderDevelopment", NStr("vi = 'Đang phát triển';
													|ru = 'В разработке';
													|en = 'Under development'; fa = 'در حال توسعه';
													|it = 'In elaborazione';
													|pl = 'W opracowaniu';
													|tr = 'Geliştirme aşamasında'"));
	
EndProcedure

&AtClient
Procedure TheSetStatusCommandIsActive(Command)
	
	SetSpecificationStatus("Valid", NStr("vi = 'Có hiệu lực';
										|ru = 'Действует';
										|en = 'Valid'; fa = 'معتبر';
										|it = 'In vigore';
										|pl = 'Aktualne';
										|tr = 'Aktif'"));
	
EndProcedure

&AtClient
Procedure TheSetStatusClosedCommand(Command)
	
	SetSpecificationStatus("Closed_", NStr("vi = 'Đã đóng';
											|ru = 'Закрыта';
											|en = 'Closed'; fa = 'بسته‌شده';
											|it = 'Chiusa';
											|pl = 'Zamknięta';
											|tr = 'Kapalı'"));
	
EndProcedure

&AtClient
Procedure CreateKits(Command)
	
	CreateItemFromList(PredefinedValue("Enum.ProductionProcessTypes.Assembly"));

EndProcedure

&AtClient
Procedure CreateARepair(Command)
	
	CreateItemFromList(PredefinedValue("Enum.ProductionProcessTypes.Repair"));
	
EndProcedure

&AtClient
Procedure CreateDisassembly(Command)
	
	CreateItemFromList(PredefinedValue("Enum.ProductionProcessTypes.Disassembly"));
	
EndProcedure

&AtClient
Procedure CreateRepairWork(Command)
	
	CreateItemFromList(PredefinedValue("Enum.ProductionProcessTypes.PerformRM"));
	
EndProcedure

&AtClient
Procedure OpenProductSpecificationsCommand(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Or TypeOf(CurrentData) = Type("DynamicListGroupRow") Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng chỉ định.';
								|ru = 'Команда не может быть выполнена для указанного объекта.';
								|en = 'Cannot execute the command for the object.'; fa = 'Cannot execute the command for the object.';
								|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
								|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
								|tr = 'Belirtilen nesne için komut gerçekleştirilemez.'"));
		Return;
	EndIf;
	
	If TypeOf(CurrentData.MainProduct) = Type("CatalogRef.ItemKinds") Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với bảng kê chi tiết theo dạng mặt hàng.';
								|ru = 'Команда не может быть выполнена для спецификации на вид номенклатуры.';
								|en = 'Cannot execute the command for the bill of materials for the item kind.'; fa = 'Cannot execute the command for the bill of materials for the item kind.';
								|it = 'Il comando non può essere eseguito per le specifiche sul tipo di nomenclatura.';
								|pl = 'Polecenie nie może być wykonane dla specyfikacji na rodzaj produktu.';
								|tr = 'Ürün türüne yönelik ürün reçetesi için komut gerçekleştirilemez.'"));
		Return;
	EndIf;
	
	FormParameters = New Structure("Products,ProductSpecificationMode,CurrentSpecification",
								CurrentData.MainProduct, "Full", CurrentData.Ref);
	OpenForm("CommonForm.ApplyProductsToManufacturing", FormParameters,, CurrentData.MainProduct);
	
	Return; // empty handler
	
EndProcedure

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
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

#EndRegion

#Region Private

#Region List

&AtServer
Function ListOfExtendedSpecListSelections()
	
	FiltersList = New Array();
	UseSelectionByTypeOfWorkCenter = (ValueIsFilled(FilterWorkCenterType) Or ValueIsFilled(FilterSetupSettings));
	
	FilterParameters = New Structure;
	FilterParameters.Insert("WorkCenterType", FilterWorkCenterType);
	FilterParameters.Insert("SetupSettings", FilterSetupSettings);
	
	QueryText =
	"SELECT DISTINCT
	|	WorkCenterTypes.Ref.Owner AS Ref
	|FROM
	|	Catalog.ProductionStages.WorkCenterTypes AS WorkCenterTypes
	|WHERE
	|	WorkCenterTypes.Ref.Owner = &Ref
	|	AND (&WorkCenterType <> VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			OR &SetupSettings <> VALUE(Catalog.SetupOptions.EmptyRef))
	|	AND (WorkCenterTypes.WorkCenterType = &WorkCenterType
	|			OR &WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef))
	|	AND (WorkCenterTypes.SetupSettings = &SetupSettings
	|			OR &SetupSettings = VALUE(Catalog.SetupOptions.EmptyRef))";
	
	ProductionServer.AddSelectionToSelectionList(FiltersList, "WorkCenterType", QueryText, FilterParameters, UseSelectionByTypeOfWorkCenter);
	QueryText = 
	"
	|
	|SELECT TOP 1
	|	FilterTable.BillOfMaterials AS BillOfMaterials
	|FROM
	|	Document.ProductionOrder2_2.ManufacturedProduct AS FilterTable
	|		LEFT JOIN Constant.UseProductionManagement2_2 AS UseProduction22
	|		ON (TRUE)
	|WHERE
	|	FilterTable.BillOfMaterials = &Ref
	|	AND FilterTable.Ref.Status <> VALUE(Enum.ProductionOrderStatuses2_2.Closed)
	|	AND NOT FilterTable.Ref.DeletionMark
	|	AND UseProduction22.Value
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	FilterTable.BillOfMaterials AS BillOfMaterials
	|FROM
	|	Document.ProductionStage2_2 AS FilterTable
	|		LEFT JOIN Constant.UseProductionManagement2_2 AS UseProduction22
	|		ON (TRUE)
	|WHERE
	|	FilterTable.BillOfMaterials = &Ref
	|	AND FilterTable.ReferenceOrder.Status <> VALUE(Enum.ProductionOrderStatuses2_2.Closed)
	|	AND NOT FilterTable.Ref.DeletionMark
	|	AND UseProduction22.Value
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	FilterTable.BillOfMaterials AS BillOfMaterials
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS FilterTable
	|		LEFT JOIN Constant.UseProductionManagement2_2 AS UseProduction22
	|		ON (TRUE)
	|WHERE
	|	FilterTable.BillOfMaterials = &Ref
	|	AND FilterTable.Ref.ReferenceOrder.Status <> VALUE(Enum.ProductionOrderStatuses2_2.Closed)
	|	AND NOT FilterTable.Ref.DeletionMark
	|	AND UseProduction22.Value";
	
	If FilterUsedInOrders = "Used" Then
		ProductionServer.AddSelectionToSelectionList(
			FiltersList,
			"UsedInOrders",
			QueryText,
			FilterUsedInOrders,
			True,
			"LinkInList");
	ElsIf FilterUsedInOrders = "NotUsed" Then
		ProductionServer.AddSelectionToSelectionList(
			FiltersList,
			"UsedInOrders",
			QueryText,
			FilterUsedInOrders,
			True,
			"LinkIsNotInList");
	EndIf;
	Return FiltersList;
	
EndFunction

&AtServer
Procedure SetPropertiesAndSelectionsInListOfSpecifications()
	
	QueryText = Catalogs.BillsOfMaterials.RequestTextForDynamicListOfResourceSpecifications();
	
	FiltersList = ListOfExtendedSpecListSelections();
	ProductionServer.SubstitutingSelectionsInDynamicListQueryText(QueryText, FiltersList, "CatalogBillsOfMaterials");
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	ListProperties.QueryText = QueryText;
	ListProperties.MainTable = List.MainTable;
	ListProperties.DynamicDataRead = True;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	ProductionServer.SetDynamicListSelectionParameters(List, FiltersList);
	
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

&AtServer
Procedure EstablishSelectionByTypeOfWorkCenter()
	
	SetPropertiesAndSelectionsInListOfSpecifications();
	
EndProcedure

&AtServer
Procedure SetSelectionByAdjustmentOption()
	
	SetPropertiesAndSelectionsInListOfSpecifications();
	
EndProcedure

&AtServerNoContext
Function SetupSettingsAreUsed(Val SetupSettings)

	Return Common.ObjectAttributeValue(SetupSettings, "SetupSettingsAreUsed");

EndFunction

&AtServer
Procedure SetSelectionByUsageInOrders()
	
	SetPropertiesAndSelectionsInListOfSpecifications();
	
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
	
	Items.FilterUsedInOrders.Visible = AvailableFilterIsUsedInOrders;
	
	DescriptionOfManufacturingProcessTypeIsAvailable = ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable();
	DynamicStructure = False;
	DynamicStructure = GetFunctionalOption("DynamicStructureOfProductionOrders");
	Items.ProductionProcessType.Visible = DescriptionOfManufacturingProcessTypeIsAvailable;
	
	If AccessRight("Insert", Metadata.Catalogs.BillsOfMaterials) Then
		Items.CreateSubmenu.Visible = DescriptionOfManufacturingProcessTypeIsAvailable;
		Items.ListCreate.Visible = Not DescriptionOfManufacturingProcessTypeIsAvailable;
		Items.ListCreateARepair.Visible = Not DynamicStructure;
		Items.ListCreateRepairWork.Visible = DynamicStructure;
	EndIf;
	
	RightToEditSpecifications = AccessRight("Edit", Metadata.Catalogs.BillsOfMaterials);
	If Not RightToEditSpecifications Then
		Items.ListSetStatusUnderDevelopment.Visible = False;
		Items.ListSetStatusValid.Visible = False;
		Items.ListSetStatusClosed.Visible = False;
	EndIf; 
	If Not AccessRight("View", Metadata.CommonForms.ApplyProductsToManufacturing) Then
		Items.ListOpenProductBOR.Visible = False;
	EndIf;
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Catalogs.BillsOfMaterials);
	Items.ListChangeSelectedItems.Visible          = ChangeSelectedAvailable;
	Items.ContextMenuChangeSelected.Visible = ChangeSelectedAvailable;
	
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
	If AttributesStructure1.Property("WorkCenterType")
		Or Initialize Then
		
		If Not Form.FilterWorkCenterType.IsEmpty() Then
			SetupSettingsAreUsed = SetupSettingsAreUsed(Form.FilterWorkCenterType);
		Else
			SetupSettingsAreUsed = False;
		EndIf;
		
		Items.FilterSetupSettings.ReadOnly = Not SetupSettingsAreUsed;
		
	EndIf;
EndProcedure

&AtClient
Procedure CopyResourceSpecification()

	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Or TypeOf(CurrentData) = Type("DynamicListGroupRow") Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("CopyResourceSpecificationCompletion", ThisObject);
	ProductDataManagementClient.CopyResourceSpecification(CurrentData.Ref, CallbackDescription);

EndProcedure

&AtClient
Procedure CopyResourceSpecificationCompletion(Ref, AdditionalParameters) Export

	If Ref <> Undefined Then
		Items.List.CurrentRow = Ref;
	EndIf; 

EndProcedure

&AtClient
Procedure SetSpecificationStatus(StatusValue, StatusPresentation)

	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	ProductDataManagementClient.SetStatusOfSpecifications(StatusValue, StatusPresentation, HighlightedLinks);

EndProcedure

&AtClient
Procedure CreateItemFromList(ProductionProcessType)
	
	CurrentData   = Items.List.CurrentData;
	CurrentParent = PredefinedValue("Catalog.BillsOfMaterials.EmptyRef");
	
	If Items.List.Representation = TableRepresentation.HierarchicalList Then
		CurrentParent = Items.List.CurrentParent;
	ElsIf Items.List.Representation = TableRepresentation.Tree And CurrentData <> Undefined Then
		If CurrentData.IsFolder Then
			CurrentParent = CurrentData.Ref;
		Else
			CurrentParent = CurrentData.Parent;
		EndIf;
	EndIf;
	
	FillingValues = New Structure("ProductionProcessType,Parent",
		ProductionProcessType,
		CurrentParent);
	
	OpenForm("Catalog.BillsOfMaterials.ObjectForm", New Structure("FillingValues", FillingValues));
	
EndProcedure

#EndRegion

#EndRegion

