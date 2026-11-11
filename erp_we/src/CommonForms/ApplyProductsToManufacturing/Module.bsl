
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ConfigureRightsForm();
	
	// Initialization of constants
	BasisProducts = CheckFillInProducts(Parameters);
	FilterUseOfTheMaterial = "Used";
	FilterUsingTheWorkCenterView = "Used";
	
	ProductAttributes = Common.ObjectAttributesValues(BasisProducts, "UseVariants,Description,ItemsType");
	
	ItemVariantsAreUsed = (GetFunctionalOption("UseItemVariants")
		And ProductAttributes.UseVariants <> Enums.ItemVariantsUsageOptions.DontUse);
	If Not ItemVariantsAreUsed Then
		Items.SpecificationManagementGroupFeatureSpecification.ShowInHeader = False;
		Items.GroupSelectionCharacteristic.Visible = False;
	EndIf;
	
	If Parameters.Property("ProductSpecificationMode") Then
		Title = StrTemplate(NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất sản phẩm  %1';
								|ru = 'Спецификации изделия %1';
								|en = 'Product BOM %1'; fa = 'Product BOM %1';
								|it = 'Specifiche del prodotto %1';
								|pl = 'Specyfikacja wyrobu %1';
								|tr = '%1 nihai ürününün ürün reçetesi'"), ProductAttributes.Description);
		Items.ThePermissionsPageForAReplacement.Visible = False;
		Items.RouteMapsPage.Visible    = False;
		Items.ProductStructurePage.Visible   = False;
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
	Else
		Title = StrTemplate(NStr("vi = 'Sản xuất (mặt hàng: ""%1"")';
								|ru = 'Производство (Номенклатура: ""%1"")';
								|en = 'Apply products to manufacturing (Item: ""%1"")'; fa = 'Apply products to manufacturing (Item: ""%1"")';
								|it = 'Produzione (articolo: ""%1"")';
								|pl = 'Produkcja (Towary: ""%1"")';
								|tr = 'Üretim (Öğe: ""%1"")'"), ProductAttributes.Description);
	EndIf;
	
	DescriptionOfManufacturingProcessTypeIsAvailable = ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable();
	DynamicStructure = GetFunctionalOption("DynamicStructureOfProductionOrders");
	
	If AccessRight("Insert", Metadata.Catalogs.BillsOfMaterials) Then
		Items.ManageBillOfMaterialsToCreate.Visible = Not DescriptionOfManufacturingProcessTypeIsAvailable;
		Items.CreateManageBillOfMaterialsSubmenu.Visible = DescriptionOfManufacturingProcessTypeIsAvailable;
		Items.BOMManagementCreateARepair.Visible = Not DynamicStructure;
		Items.BOMManagementCreateRepairWork.Visible = DynamicStructure;
	EndIf;
	
	If ProductAttributes.ItemsType = Enums.ItemsTypes.Set Then
		Items.ThePermissionsPageForAReplacement.Visible = False;
		Items.RouteMapsPage.Visible    = False;
	EndIf;
	
	SetPropertiesOfDynamicListOfMaterialReplacementPermissions();
	PermitsToEstablishSelectionByProduct();
	
	If GetFunctionalOption("UseRouteSheets") Then
		SetPropertiesForDynamicListOfRouteMaps();
		RouteMapsSetSelectionByProductType(ThisObject);
	EndIf;

	SetPropertiesOfDynamicListOfPlannedCalculations22();
	
	Items.BOMManagementBillOfMaterialsType.Visible = ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable();
	InitializingSpecificationTree();
	CompleteSpecificationManagement();
	
	SetDynamicListPropertiesForUseInSpecifications();
	
	SetPropertiesOfDynamicListOfAvailableSpecifications();
	
	If Parameters.Property("CurrentSpecification") Then
		TheStructureOfTheSearch = New Structure("BillOfMaterials", Parameters.CurrentSpecification);
		StringsList = BOMManagement.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() <> 0 Then
			Items.BOMManagement.CurrentRow = StringsList[0].GetID();
		EndIf;
	EndIf;
	
	UpdateProductStructure = True;
	DynamicReading = True;
	
	Items.PlannedCalculationsPage.Visible   = GetFunctionalOption("UseProductionManagement");
	Items.PlannedCalculationsPage22.Visible = GetFunctionalOption("UseProductionManagement2_2");
	If GetFunctionalOption("EnabledOnlyProductionManagement22") Then
		Items.PlannedCalculationsPage22.Title = NStr("vi = 'Tính giá thành kế hoạch';
													|ru = 'Плановые калькуляции';
													|en = 'Product standard costs'; fa = 'بهای تمام‌شده استاندارد محصولات';
													|it = 'Stime dei costi';
													|pl = 'Planowane kalkulacje';
													|tr = 'Standart ürün maliyetleri'");
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_BillsOfMaterials" 
		Or EventName = "Write_MainRouteSheets" Then
		UpdateDataOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	ClearMessages();
	
	CurrentRow = Items.BOMsTree.CurrentRow;
	
	If ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.ChoiceFormByItems" Then
		
		ChangeSpecificationInCurLine(CurrentRow, ValueSelected);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(BasisProducts) Then
		
		WarningText = NStr("vi = 'Mẫu ""Sản xuất"" chỉ được sử dụng trong ngữ cảnh của mặt hàng.';
							|ru = 'Форма ""Производство"" используется только в контексте номенклатуры.';
							|en = '""Manufacturing"" form is used only within the context of inventory.'; fa = '""Manufacturing"" form is used only within the context of inventory.';
							|it = 'Modulo ""Produzione"" è usato solo nel contesto dell''articolo.';
							|pl = 'Formularz ""Produkcja"" jest używany tylko w kontekście nomenklatury.';
							|tr = '""Üretim"" formu sadece öğe bağlamında kullanılmaktadır.'");
		ShowMessageBox(,WarningText);
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SpecificationsDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateProductStructure = True;
	
	CompleteSpecificationManagement();
	
EndProcedure

&AtClient
Procedure BasisCharacteristicOnChange(Item)
	
	BaseCharacteristicWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure BaseCharacteristicWhenChangingOnServer()
	
	CompleteSpecificationManagement();
	SetDynamicListPropertiesForUseInSpecifications();
	
EndProcedure

&AtClient
Procedure SpecificationsStatusOnChange(Item)
	
	CompleteSpecificationManagement();
	
EndProcedure

&AtClient
Procedure FilterUseOfTheMaterialOnChange(Item)
	
	If IsBlankString(FilterUseOfTheMaterial) Then
		FilterUseOfTheMaterial = "Used";
	EndIf; 
	CompleteSpecificationManagement();
	
EndProcedure

&AtClient
Procedure FilterMaterialOnChange(Item)
	
	CompleteSpecificationManagement();
	
EndProcedure

&AtClient
Procedure FilterUsingTheWorkCenterViewOnChange(Item)
	
	If IsBlankString(FilterUsingTheWorkCenterView) Then
		FilterUsingTheWorkCenterView = "Used";
	EndIf;
	CompleteSpecificationManagement();
	
EndProcedure

&AtClient
Procedure FilterWorkCenterTypeOnChange(Item)
	
	CompleteSpecificationManagement();
	
EndProcedure

&AtClient
Procedure RouteMapsStatusOnChange(Item)
	RouteMapsSetSelectionByStatus(ThisObject);
EndProcedure

&AtClient
Procedure RouteMapsResponsibleOnChange(Item)
	RouteMapsSetSelectionByResponsiblePerson(ThisObject);
EndProcedure

&AtClient
Procedure RouteMapsDivisionOnChange(Item)
	RouteMapsSetSelectionByDivision(ThisObject);
EndProcedure

&AtClient
Procedure PermissionsStatusOnChange(Item)
	PermissionsToSetSelectionByStatus();
EndProcedure

&AtClient
Procedure PermissionsSpecificationOnChange(Item)
	PermissionsToSetSelectionBySpecification();
EndProcedure

&AtClient
Procedure PermissionsResponsibleOnChange(Item)
	PermissionsToSetSelectionByResponsible();
EndProcedure

&AtClient
Procedure CalculationStatusOnChange(Item)
	CalculationsSetSelectionByStatus(ThisObject);
EndProcedure

&AtClient
Procedure CalculationViewWhenChanging(Item)
	CalculationsSetSelectionByObject(ThisObject);
EndProcedure

&AtClient
Procedure CalculationsResponsibleOnChange(Item)
	CostingSetSelectionByResponsible(ThisObject);
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.ProductStructurePage
		And UpdateProductStructure Then
		
		CreateSpecificationTreeOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure TreeDateOnChange(Item)
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject);
	
	DateTreeWhenChangedOnServer();
	
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject);
	
EndProcedure

&AtServer
Procedure DateTreeWhenChangedOnServer()
	
	CompleteSpecificationManagement();
	
	HowToUpdateSpecificationOnServer();
	
	CreateSpecificationTreeOnServer();
	
EndProcedure

&AtClient
Procedure TreeOutputStagesOnChange(Item)
	TreeFilterParametersAreChanged();
EndProcedure

&AtClient
Procedure TreeOutputOutputItemsOnChange(Item)
	TreeFilterParametersAreChanged();
EndProcedure

&AtClient
Procedure TreeOutputMaterialsOnChange(Item)
	TreeFilterParametersAreChanged();
EndProcedure

&AtClient
Procedure TreeOutputLaborCostsOnChange(Item)
	TreeFilterParametersAreChanged();
EndProcedure

&AtClient
Procedure RouteMapsAreUsedAsOnChange(Item)
	
	RouteMapsSetSelectionByProductType(ThisObject);
	
EndProcedure

&AtClient
Procedure PermissionToAssignAnItemWhenChangingIt(Item)
	
	PermitsToEstablishSelectionByProduct();

EndProcedure

&AtClient
Procedure DestinationParameterActivityDirectionOnChange(Item)
	
	WhenChangingValueOfSpecificationAssignmentParameter();
	
EndProcedure

&AtClient
Procedure AssignmentParameterDivisionManagerOnChange(Item)
	
	WhenChangingValueOfSpecificationAssignmentParameter();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBOMManagement

&AtClient
Procedure BOMManagementBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure BOMManagementSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.BOMManagement.CurrentData;
	
	If CurrentData <> Undefined 
		And ValueIsFilled(CurrentData.SpecificationFeature) 
		And CurrentData.RowType = 0 Then
		
		StandardProcessing = False;
		ShowValue(,CurrentData.SpecificationFeature);
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRouteSheets

&AtServerNoContext
Procedure OperationsSheetListOnGetDataAtServer(TagName, Settings, Rows)
	
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
	
	DataParameter = Settings.DataParameters.FindParameterValue(New DataCompositionParameter("Products"));
	If DataParameter <> Undefined Then
		Query.SetParameter("Products", DataParameter.Value);
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

#Region FormTableItemsEventHandlersBOMsTree

&AtClient
Procedure BOMsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "BOMsTreeProducts" And ValueIsFilled(Item.CurrentData.Products) And 
		TypeOf(Item.CurrentData.Products) <> Type("String") Then
		
		StandardProcessing = False;
		ShowValue(,Item.CurrentData.Products);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BOMsTreeOnActivateRow(Item)
	AttachIdleHandler("HandleTreeRowActivation",0.2,True);
EndProcedure

&AtClient
Procedure BOMsTreeBillOfMaterialsStartChoice(Item, ChoiceData, StandardProcessing)
	
	ProductDataManagementClient.BOMsTreeBillOfMaterialsStartChoice(
		ThisObject, Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BOMsTreeBeforeExpand(Item, String, Cancel)
	
	ProductDataManagementClient.BOMsTreeBeforeExpand(ThisObject, String, Cancel);
	
EndProcedure

&AtClient
Procedure BOMsTreeBeforeCollapse(Item, String, Cancel)
	
	ProductDataManagementClient.BOMsTreeBeforeCollapse(ThisObject, String, Cancel);
	
EndProcedure

&AtClient
Procedure BOMsTreeBillOfMaterialsClearing(Item, StandardProcessing)
	
	CurrentRow = Items.BOMsTree.CurrentRow;
	ChangeSpecificationInCurLine(CurrentRow);
	
EndProcedure

&AtClient
Procedure BOMsTreeCharacteristicOnChange(Item)

	CurrentRow = Items.BOMsTree.CurrentRow;
	CurrentData = Items.BOMsTree.CurrentData;
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject, CurrentData);
	
	SpecificationTreeCharacteristicWhenModifiedOnServer(CurrentRow);
	
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject, CurrentData);

EndProcedure

&AtServer
Procedure SpecificationTreeCharacteristicWhenModifiedOnServer(CurrentRow)
	
	CurrentData = BOMsTree.FindByID(CurrentRow);
	
	Var_Key = ProductDataManagementClientServer.KeyParametersForSelectingTreeSpecifications(CurrentData);
	
	StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		ThisObject, CurrentData, BOMSelectionParameters[Var_Key]);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	HandleChangingTreeRowPropsOnServer(CurrentRow);
	
EndProcedure

&AtClient
Procedure BOMsTreePackageOnChange(Item)
	
	CurrentRow = Items.BOMsTree.CurrentRow;
	CurrentData = Items.BOMsTree.CurrentData;
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject, CurrentData);
	
	SpecificationTreePackagingWhenModifiedOnServer(CurrentRow);
	
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject, CurrentData);

EndProcedure

&AtServer
Procedure SpecificationTreePackagingWhenModifiedOnServer(CurrentRow)
	
	CurrentData = BOMsTree.FindByID(CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	HandleChangingTreeRowPropsOnServer(CurrentRow);
	
EndProcedure

&AtClient
Procedure BOMsTreeNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.BOMsTree.CurrentRow;
	CurrentData = Items.BOMsTree.CurrentData;
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject, CurrentData);
	
	SpecificationTreeNumberOfPackagesWhenChangedOnServer(CurrentRow);
	
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject, CurrentData);
	
EndProcedure

&AtServer
Procedure SpecificationTreeNumberOfPackagesWhenChangedOnServer(CurrentRow)
	
	CurrentData = BOMsTree.FindByID(CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	HandleChangingTreeRowPropsOnServer(CurrentRow);
	
EndProcedure

&AtClient
Procedure BOMsTreeBeforeRowChange(Item, Cancel)
	
	ProductDataManagementClient.BOMsTreeBeforeRowChange(Item, Cancel);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfAvailableBillsOfResources

&AtClient
Procedure ListOfAvailableBillsOfResourcesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ListOfAvailableBillsOfResources.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(,CurrentData.BillOfMaterials);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region ListCommandManageSpecifications

&AtClient
Procedure EditSpecificationCommands(Command)
	
	CurrentData = Items.BOMManagement.CurrentData;
	If CurrentData = Undefined Or CurrentData.RowType <> 0 Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Key", CurrentData.BillOfMaterials);
	OpenForm("Catalog.BillsOfMaterials.ObjectForm", FormParameters);
	
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
	
	CreateBillOfMaterialsFromManageBillOfMaterialsList(PredefinedValue("Enum.ProductionProcessTypes.Assembly"));

EndProcedure

&AtClient
Procedure CreateARepair(Command)
	
	CreateBillOfMaterialsFromManageBillOfMaterialsList(PredefinedValue("Enum.ProductionProcessTypes.Repair"));
	
EndProcedure

&AtClient
Procedure CreateDisassembly(Command)
	
	CreateBillOfMaterialsFromManageBillOfMaterialsList(PredefinedValue("Enum.ProductionProcessTypes.Disassembly"));
	
EndProcedure

&AtClient
Procedure CreateRepairWork(Command)
	
	CreateBillOfMaterialsFromManageBillOfMaterialsList(PredefinedValue("Enum.ProductionProcessTypes.PerformRM"));
	
EndProcedure

&AtClient
Procedure CompareSpecificationsCommand(Command)
	
	ListOfSources = GetHighlightedSpecificationsInManageSpecificationsList();
	If ListOfSources.Count() <> 0 Then
		FormParameters = New Structure;
		FormParameters.Insert("ListOfSources", ListOfSources);
		OpenForm("DataProcessor.CompareBillsOfMaterials.Form", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure TheSpecificationTreeCommand(Command)
	
	CurrentData = Items.BOMManagement.CurrentData;
	If CurrentData = Undefined Or CurrentData.RowType <> 0 Then
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("BillOfMaterials", CurrentData.BillOfMaterials); 
	OpeningParameters.Insert("GenerateOnOpen", True); 
	OpeningParameters.Insert("ViewMode", "BillOfMaterials");
	OpenForm("DataProcessor.BillsOfMaterialsTree.Form", OpeningParameters);
	
EndProcedure

#EndRegion

&AtClient
Procedure UpdateDataCommand(Command)
	UpdateDataOnServer();
EndProcedure

&AtClient
Procedure GenerateTree(Command)
	
	ClearMessages();
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject);
	
	CreateSpecificationTreeOnServer();
	
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject);
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	CommandParameter = New Array;
	CommandParameter.Add(PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"));
	
	TemplatesNames = "BOMsTree";
	PrintParameters = SpecificationTreePrintingOptions();
	
	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.BillsOfMaterialsTree",
		TemplatesNames,
		CommandParameter,
		ThisObject,
		PrintParameters);
	
EndProcedure

&AtClient
Procedure TreeHideGroupingTitles(Command)
	
	TreeDisplayGroupingHeaders = Not TreeDisplayGroupingHeaders;
	
	SetUpAdditionalCommandTaggingTree(ThisObject);
	
	CreateSpecificationTreeOnServer();
	
EndProcedure

&AtClient
Procedure TreeOutputOfOperationsAlongWithStages(Command)
	
	TreeOutputOfOperations = Not TreeOutputOfOperations;
	
	SetUpAdditionalCommandTaggingTree(ThisObject);
	
	CreateSpecificationTreeOnServer();
	
EndProcedure

#EndRegion

#Region Private

#Region Specifications

&AtClient
Procedure CopyResourceSpecificationToListOfSpecifications()

	CurrentData = Items.BOMList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf; 
	
	CallbackDescription = New CallbackDescription("CopyResourceSpecificationToListOfSpecificationsCompletion", ThisObject);
	ProductDataManagementClient.CopyResourceSpecification(CurrentData.Ref, CallbackDescription);

EndProcedure

&AtClient
Procedure CopyResourceSpecificationToListOfSpecificationsCompletion(Ref, AdditionalParameters) Export

	If Ref <> Undefined Then
		Items.BOMList.CurrentRow = Ref;
	EndIf; 

EndProcedure

&AtServer
Procedure CompleteSpecificationManagement(CurSpecificationFeature = Undefined)
	
	If Not RightToViewBillsOfMaterials Then
		Return
	EndIf;
	
	// Let's remember the current line in order to make it active later
	If CurSpecificationFeature = Undefined Then
		CurrentRow = Items.BOMManagement.CurrentRow;
		If CurrentRow <> Undefined Then
			CurrentData = BOMManagement.FindByID(CurrentRow);
			CurSpecificationFeature = CurrentData.SpecificationFeature;
		EndIf;
	EndIf;
	
	BOMManagement.Clear();

	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	0                             AS TheIndexOfTheData,
	|	&Products                 AS Products,
	|	&Characteristic               AS Characteristic,
	|	DATETIME(1,1,1)              AS ProductionStart,
	|	&LineOfBusiness      AS LineOfBusiness,
	|	&ProductionDispatcherBusinessUnit       AS ProductionDispatcherBusinessUnit,
	|
	|	TabularSection.Ref                              AS BillOfMaterials,
	|
	|	TabularSection.Ref.ValidOnDate               AS ValidOnDate,
	|	TabularSection.Ref.ValidToDate                AS ValidToDate,
	|	TabularSection.Ref.Code                          AS Code,
	|
	|	TabularSection.Ref.ProductionProcessType AS ProductionProcessType,
	|	TabularSection.Ref.Status                       AS Status,
	|	TabularSection.Ref.DeletionMark              AS DeletionMark,
	|
	|	TabularSection.Package                            AS Package,
	|
	|	TabularSection.Products   = VALUE(Catalog.Products.EmptyRef)               AS AnyProducts,
	|	TabularSection.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS AnyCharacteristic,
	|
	|	TabularSection.MethodOfProductsAutoselection   AS MethodOfProductsAutoselection,
	|	TabularSection.MethodOfItemVariantAutoselection AS MethodOfItemVariantAutoselection,
	|	TabularSection.Products                   AS SpecificationProducts,
	|	TabularSection.Characteristic                 AS SpecificationCharacteristic,
	|
	|	TabularSection.Ref.Status = VALUE(Enum.BOMStatuses.Valid)
	|		AND NOT TabularSection.Ref.ExcludeAutomaticSelection AS SelectedAutomatically
	|
	|INTO TTSpecifications
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS TabularSection
	|
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = &Products
	|
	|WHERE
	|	(TabularSection.Products = &Products
	|		OR TabularSection.Products = VALUE(Catalog.Products.EmptyRef)
	|			AND TabularSection.ProductKind = CatProducts.ProductKind)
	|	AND (TabularSection.Characteristic = &Characteristic
	|		OR &Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		OR TabularSection.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|	AND (TabularSection.Ref.Status = &SpecificationsStatus
	|		OR &SpecificationsStatus = VALUE(Enum.BOMStatuses.EmptyRef))
	|	AND TabularSection.Ref.ProductionProcessType IN (
	|		VALUE(Enum.ProductionProcessTypes.Assembly),
	|		VALUE(Enum.ProductionProcessTypes.PerformRM),
	|		VALUE(Enum.ProductionProcessTypes.Repair))
	|	AND (&ProductionStart = DATETIME(1, 1, 1) 
	|		OR TabularSection.Ref.ValidOnDate <= &ProductionStart)
	|	AND (TabularSection.Ref.ValidToDate = DATETIME(1, 1, 1)
	|		OR TabularSection.Ref.ValidToDate >= &ProductionStart)
	|	AND (TabularSection.LineNumber = 1
	|		OR TabularSection.Ref.ContainsResourcesParametrization = FALSE)
	|	AND &TextSelectionConditionForPackaging1
	|	AND &TextSelectionCriteriaForResourcesUsed
	|
	|UNION ALL
	|
	|SELECT
	|
	|	0                             AS TheIndexOfTheData,
	|	&Products                 AS Products,
	|	&Characteristic               AS Characteristic,
	|	DATETIME(1,1,1)              AS ProductionStart,
	|	&LineOfBusiness      AS LineOfBusiness,
	|	&ProductionDispatcherBusinessUnit       AS ProductionDispatcherBusinessUnit,
	|
	|	TabularSection.Ref                              AS BillOfMaterials,
	|
	|	TabularSection.Ref.ValidOnDate               AS ValidOnDate,
	|	TabularSection.Ref.ValidToDate                AS ValidToDate,
	|	TabularSection.Ref.Code                          AS Code,
	|
	|	TabularSection.Ref.ProductionProcessType AS ProductionProcessType,
	|	TabularSection.Ref.Status                       AS Status,
	|	TabularSection.Ref.DeletionMark              AS DeletionMark,
	|
	|	TabularSection.Package                            AS Package,
	|
	|	TabularSection.Products   = VALUE(Catalog.Products.EmptyRef)               AS AnyProducts,
	|	TabularSection.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS AnyCharacteristic,
	|
	|	TabularSection.MethodOfProductsAutoselection   AS MethodOfProductsAutoselection,
	|	TabularSection.MethodOfItemVariantAutoselection AS MethodOfItemVariantAutoselection,
	|	TabularSection.Products                   AS SpecificationProducts,
	|	TabularSection.Characteristic                 AS SpecificationCharacteristic,
	|
	|	FALSE AS SelectedAutomatically
	|
	|FROM
	|	Catalog.BillsOfMaterials.RecyclableWaste AS TabularSection
	|
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = &Products
	|
	|WHERE
	|	TabularSection.Products = &Products
	|	AND (TabularSection.Characteristic = &Characteristic
	|		OR &Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		OR TabularSection.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|	AND (TabularSection.Ref.Status = &SpecificationsStatus
	|		OR &SpecificationsStatus = VALUE(Enum.BOMStatuses.EmptyRef))
	|	AND TabularSection.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Assembly)
	|	AND (&ProductionStart = DATETIME(1, 1, 1) 
	|		OR TabularSection.Ref.ValidOnDate <= &ProductionStart)
	|	AND (TabularSection.Ref.ValidToDate = DATETIME(1, 1, 1)
	|		OR TabularSection.Ref.ValidToDate >= &ProductionStart)
	|	AND TabularSection.MethodOfProductsAutoselection = VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
	|	AND TabularSection.MethodOfItemVariantAutoselection = VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData)
	|	AND TabularSection.Ref.AllowSelectionForSideOutletProducts
	|	AND &TextSelectionConditionForPackaging1
	|	AND &TextSelectionCriteriaForResourcesUsed
	|
	|UNION ALL
	|
	|SELECT
	|	0                                           AS TheIndexOfTheData,
	|	&Products                               AS Products,
	|	&Characteristic                             AS Characteristic,
	|	DATETIME(1,1,1)                            AS ProductionStart,
	|	&LineOfBusiness                    AS LineOfBusiness,
	|	&ProductionDispatcherBusinessUnit                     AS ProductionDispatcherBusinessUnit,
	|
	|	TabularSection.Ref                       AS BillOfMaterials,
	|	TabularSection.ValidOnDate               AS ValidOnDate,
	|	TabularSection.ValidToDate                AS ValidToDate,
	|	TabularSection.Code                          AS Code,
	|
	|	TabularSection.ProductionProcessType AS ProductionProcessType,
	|	TabularSection.Status                       AS Status,
	|	TabularSection.DeletionMark              AS DeletionMark,
	|
	|	TabularSection.MainProductPackage      AS Package,
	|
	|	TabularSection.MainProductProducts = VALUE(Catalog.Products.EmptyRef)                 AS AnyProducts,
	|	TabularSection.MainProductCharacteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS AnyCharacteristic,
	|
	|	VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)     AS MethodOfProductsAutoselection,
	|	VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData)   AS MethodOfItemVariantAutoselection,
	|	TabularSection.MainProductProducts                               AS SpecificationProducts,
	|	TabularSection.MainProductCharacteristic                             AS SpecificationCharacteristic,
	|
	|	TabularSection.Status = VALUE(Enum.BOMStatuses.Valid)
	|		AND NOT TabularSection.ExcludeAutomaticSelection AS SelectedAutomatically
	|
	|FROM
	|	Catalog.BillsOfMaterials AS TabularSection
	|
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = &Products
	|
	|WHERE
	|	(TabularSection.MainProductProducts = &Products
	|		OR TabularSection.MainProductProducts = VALUE(Catalog.Products.EmptyRef)
	|			AND TabularSection.MainProductProductKind = CatProducts.ProductKind)
	|	AND (TabularSection.MainProductCharacteristic = &Characteristic
	|		OR &Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		OR TabularSection.MainProductCharacteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|	AND (TabularSection.Status = &SpecificationsStatus
	|		OR &SpecificationsStatus = VALUE(Enum.BOMStatuses.EmptyRef))
	|	AND TabularSection.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|	AND (&ProductionStart = DATETIME(1, 1, 1) 
	|		OR TabularSection.ValidOnDate <= &ProductionStart)
	|	AND (TabularSection.ValidToDate = DATETIME(1, 1, 1)
	|		OR TabularSection.ValidToDate >= &ProductionStart)
	|	AND &TextSelectionConditionForPackaging2
	|	AND &TextSelectionCriteriaForResourcesUsed
	|;
	|
	|";
	
	TextSelectionConditionForPackaging1 = ProductDataManagement.TextOfSelectionConditionForPackagingWhenSelectingSpecifications(
		"CatProducts.Ref", "TabularSection.Products", "TabularSection.Package");
	QueryText = StrReplace(QueryText, "AND &TextSelectionConditionForPackaging1", TextSelectionConditionForPackaging1);
	TextSelectionConditionForPackaging2 = ProductDataManagement.TextOfSelectionConditionForPackagingWhenSelectingSpecifications(
		"CatProducts.Ref", "TabularSection.MainProductProducts", "TabularSection.MainProductPackage");
	QueryText = StrReplace(QueryText, "AND &TextSelectionConditionForPackaging2", TextSelectionConditionForPackaging2);
	
	TextSelectionCriteriaForResourcesUsed = TextOfSelectionCriteriaForResourcesUsed();
	QueryText = StrReplace(QueryText, "AND &TextSelectionCriteriaForResourcesUsed", TextSelectionCriteriaForResourcesUsed);
	
	ListOfSpecificationSelectionOptions = ProductDataManagementClientServer.BOMSelectionParameters();
	ListOfSpecificationSelectionOptions.Insert("IgnoredDestinationParameters", New Array);
	ListOfSpecificationSelectionOptions.Insert("IgnoredApplicationRefinements", New Array);
	
	SpecificationRequestParameters = ProductDataManagement.ParametersOfRequestTextForManufacturedProductSpecifications();
	SpecificationRequestParameters.AllFieldsInResult = True;
	FillInDescriptionOfSourceOfAvailableSpecifications(SpecificationRequestParameters, ListOfSpecificationSelectionOptions);
	
	TableSourceSpecifications       = "TTSpecifications";
	ParametricSelectionsAreUsed = ValueIsFilled(DestinationParameterActivityDirection)
		Or ValueIsFilled(AssignmentParameterDivisionManager)
		Or ValueIsFilled(BasisCharacteristic);
	
	// If selection by destination parameters or characteristic is not set, then the available specifications are determined by the specification table.
	// If selection by assignment parameters or characteristic is set, then the list of specifications is additionally filtered through the interface of auto-selection of specifications,
	// while if any of the selections is empty, its value is ignored.
	If ParametricSelectionsAreUsed Then
		
		TableSourceSpecifications = "TTSpecificationsWithSelectionByDestinationParameters";
		
		If Not ValueIsFilled(DestinationParameterActivityDirection) Then
			ListOfSpecificationSelectionOptions.IgnoredDestinationParameters.Add(
				Enums.TypesOfBOMAssignmentParameters.LineOfBusiness);
		EndIf;
		If Not ValueIsFilled(AssignmentParameterDivisionManager) Then
			ListOfSpecificationSelectionOptions.IgnoredDestinationParameters.Add(
				Enums.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit);
		EndIf;
		If Not ValueIsFilled(BasisCharacteristic) Then
			ListOfSpecificationSelectionOptions.IgnoredApplicationRefinements.Add(
				ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey("Characteristic"));
		EndIf;
		
		SpecificationRequestParameters.OutputTableName = TableSourceSpecifications;
		QueryText = QueryText + ProductDataManagement.RequestTextForProductItemsSpecifications(
			SpecificationRequestParameters, ListOfSpecificationSelectionOptions);
			
		ProductDataManagement.SetParametersForRequestManufacturedProductSpecifications(Query, ListOfSpecificationSelectionOptions);
		
	EndIf;
	
	QueryText = QueryText + "
	|
	|SELECT
	|	Specifications.BillOfMaterials                              AS BillOfMaterials,
	|	Specifications.Status                                    AS Status,
	|	Specifications.ProductionProcessType              AS ProductionProcessType,
	|	Specifications.DeletionMark                           AS DeletionMark,
	|
	|	Specifications.SpecificationCharacteristic                AS Characteristic,
	|	Specifications.MethodOfItemVariantAutoselection            AS MethodOfItemVariantAutoselection,
	|
	|	PRESENTATION(Specifications.BillOfMaterials)               AS BillOfMaterialsPresentation,
	|	PRESENTATION(Specifications.SpecificationCharacteristic) AS CharacteristicPresentation
	|FROM
	|	&TableSourceSpecifications AS Specifications
	|
	|ORDER BY
	|	Specifications.SpecificationCharacteristic.Description,
	|	Specifications.BillOfMaterials.Description
	|
	|";
	
	Query.SetParameter("Products",            BasisProducts);
	Query.SetParameter("Characteristic",          BasisCharacteristic);
	Query.SetParameter("ProductionStart",      TreeDate);
	Query.SetParameter("LineOfBusiness", DestinationParameterActivityDirection);
	Query.SetParameter("ProductionDispatcherBusinessUnit",  AssignmentParameterDivisionManager);
	
	Query.SetParameter("SpecificationsStatus",      SpecificationsStatus);
	
	Query.SetParameter("Material",                FilterMaterial);
	Query.SetParameter("WorkCenterType",       FilterWorkCenterType);
	
	Query.Text = StrReplace(QueryText, "&TableSourceSpecifications", TableSourceSpecifications);
	Result = Query.ExecuteBatch(); 
	
	TableOfCharacteristicsAndSpecifications = Result[Result.Count()-1].Unload(); // ValueTable
	TableOfCharacteristicsAndSpecifications.Indexes.Add("BillOfMaterials");
	
	// The priority specification is determined by a separate request to the specification auto-selection interface,
	// while taking into account the values of all selections, including empty ones.
	SpecificationRequestParameters.OutputTableName = "";
	ListOfSpecificationSelectionOptions.IgnoredDestinationParameters.Clear();
	ListOfSpecificationSelectionOptions.IgnoredApplicationRefinements.Clear();
	Query.Text = ProductDataManagement.RequestTextForProductItemsSpecifications(SpecificationRequestParameters, ListOfSpecificationSelectionOptions);
	ProductDataManagement.SetParametersForRequestManufacturedProductSpecifications(Query, ListOfSpecificationSelectionOptions);
	PrioritySpecifications = Query.Execute().Unload();
	
	PrioritySpecification = Undefined;
	For IndexOf = 0 To PrioritySpecifications.Count()-1 Do
		String = PrioritySpecifications[IndexOf];
		If String.SelectedAutomatically = True
				And String.ProductionProcessType = Enums.ProductionProcessTypes.Assembly Then
			FoundRow = TableOfCharacteristicsAndSpecifications.Find(String.BillOfMaterials, "BillOfMaterials");
			If FoundRow = Undefined Then
				Break;
			EndIf;
			If FoundRow.MethodOfItemVariantAutoselection <> Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData Then
				Continue;
			EndIf;
			If ValueIsFilled(BasisCharacteristic)
					Or Not ValueIsFilled(FoundRow.Characteristic) Then
				PrioritySpecification = String.BillOfMaterials;
				Break;
			EndIf;
		EndIf;
	EndDo;

	// Fill in the list of specifications
	CharacteristicTable = TableOfCharacteristicsAndSpecifications.Copy();
	CharacteristicTable.GroupBy("Characteristic");
	For Each DataCharacteristics_ In CharacteristicTable Do
		If ItemVariantsAreUsed Then
			StringCharacteristic = BOMManagement.Add();
			StringCharacteristic.RowType = 1;
			StringCharacteristic.SpecificationFeature = DataCharacteristics_.Characteristic;
			StringCharacteristic.Characteristic = DataCharacteristics_.Characteristic;
		EndIf;
		TheStructureOfTheSearch = New Structure("Characteristic", DataCharacteristics_.Characteristic);
		StringsList = TableOfCharacteristicsAndSpecifications.FindRows(TheStructureOfTheSearch);
		For Each DataSpecification In StringsList Do
			StringSpecification = BOMManagement.Add();
			StringSpecification.RowType = 0;
			StringSpecification.SpecificationFeature = DataSpecification.BillOfMaterials;
			FillPropertyValues(StringSpecification, DataSpecification);
			If DataSpecification.BillOfMaterials = PrioritySpecification Then
				StringSpecification.Priority_2 = True;
			EndIf;
		EndDo;
	EndDo;
	
	SetManageSpecificationsLine(CurSpecificationFeature, ThisObject);
	
EndProcedure
  
&AtClient
Procedure CopyBillOfMaterialsInManageBillOfMaterialsList()

	CurrentData = Items.BOMManagement.CurrentData;
	If CurrentData = Undefined Or CurrentData.RowType <> 0 Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("CopyResourceSpecificationInManageSpecificationsListCompletion", ThisObject);
	ProductDataManagementClient.CopyResourceSpecification(CurrentData.BillOfMaterials, CallbackDescription);

EndProcedure

&AtClient
Procedure CopyResourceSpecificationInManageSpecificationsListCompletion(Ref, AdditionalParameters) Export

	CompleteSpecificationManagement(Ref);

EndProcedure

&AtClientAtServerNoContext
Procedure SetManageSpecificationsLine(CurSpecificationFeature, Form)

	If CurSpecificationFeature <> Undefined Then
		TheStructureOfTheSearch = New Structure("SpecificationFeature", CurSpecificationFeature);
  		StringsList = Form.BOMManagement.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() <> 0 Then
			Form.Items.BOMManagement.CurrentRow = StringsList[0].GetID();
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure SetSpecificationStatus(StatusValue, StatusPresentation)

	HighlightedLinks = GetHighlightedSpecificationsInManageSpecificationsList();
	ProductDataManagementClient.SetStatusOfSpecifications(StatusValue, StatusPresentation, HighlightedLinks);

EndProcedure

&AtClient
Function GetHighlightedSpecificationsInManageSpecificationsList()

	HighlightedLinks = New Array;
	For Each CurrentRow In Items.BOMManagement.SelectedRows Do
		CurrentData = BOMManagement.FindByID(CurrentRow);
		If CurrentData.RowType = 0 Then
			HighlightedLinks.Add(CurrentData.BillOfMaterials);
		EndIf; 
	EndDo; 

	Return HighlightedLinks;
	
EndFunction

&AtServer
Procedure FillInDescriptionOfSourceOfAvailableSpecifications(QueryOptions, BOMSelectionParameters)
	
	ProductDataManagementOverridable.SourceOfAvailableSpecificationsApplicationOfProductsInProduction(QueryOptions, BOMSelectionParameters);
	If ValueIsFilled(QueryOptions.SourceOfAvailableSpecifications) Then
		Return;
	EndIf;
	
	SourceOfAvailableSpecifications = ProductDataManagement.SourceOfAvailableSpecificationsConstructor();
	SourceOfAvailableSpecifications.NameOfTemporarySpecificationSourceTable = "TTSpecifications";
	
	QueryOptions.SourceOfAvailableSpecifications = SourceOfAvailableSpecifications;
	
EndProcedure

&AtServer
Function TextOfSelectionCriteriaForResourcesUsed()
	
	ArrayOfConditions = New Array;
	
	If ValueIsFilled(FilterMaterial) Then
		
		If FilterUseOfTheMaterial = "Used" Then
			
			Condition = "
			|	AND TRUE IN (
			|			SELECT TOP 1
			|				TRUE
			|			FROM
			|				Catalog.BillsOfMaterials.MaterialsAndServices AS TableMaterialsAndServices
			|			WHERE
			|				TableMaterialsAndServices.Ref = TabularSection.Ref
			|					AND &Material = TableMaterialsAndServices.Products)
			|";
			ArrayOfConditions.Add(Condition);
			
		Else
			
			Condition = "
			|	AND NOT TRUE IN (
			|			SELECT TOP 1
			|				TRUE
			|			FROM
			|				Catalog.BillsOfMaterials.MaterialsAndServices AS TableMaterialsAndServices
			|			WHERE
			|				TableMaterialsAndServices.Ref = TabularSection.Ref
			|					AND &Material = TableMaterialsAndServices.Products)
			|";
			ArrayOfConditions.Add(Condition);
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(FilterWorkCenterType) Then
		
		If FilterUsingTheWorkCenterView = "Used" Then
			
			Condition = "
			|	AND TRUE IN (
			|			SELECT TOP 1
			|				TRUE
			|			FROM
			|				Catalog.ProductionStages.WorkCenterTypes AS TypesOfWorkCentersStages
			|			WHERE
			|				TypesOfWorkCentersStages.Ref.Owner = TabularSection.Ref
			|					AND &WorkCenterType = TypesOfWorkCentersStages.WorkCenterType)
			|";
			ArrayOfConditions.Add(Condition);
			
		Else
			
			Condition = "
			|	AND NOT TRUE IN (
			|			SELECT TOP 1
			|				TRUE
			|			FROM
			|				Catalog.ProductionStages.WorkCenterTypes AS TypesOfWorkCentersStages
			|			WHERE
			|				TypesOfWorkCentersStages.Ref.Owner = TabularSection.Ref
			|					AND TypesOfWorkCentersStages.WorkCenterType = &WorkCenterType)
			|";
			ArrayOfConditions.Add(Condition);
			
		EndIf;
		
	EndIf;
	
	Return StrConcat(ArrayOfConditions);
	
EndFunction

&AtServer
Procedure SetDynamicListPropertiesForUseInSpecifications()
	
	CommonClientServer.SetDynamicListParameter(BOMList, "FilterProduct", BasisProducts);
	CommonClientServer.SetDynamicListParameter(BOMList, "FilterItemVariantOfProduct", BasisCharacteristic);
	
EndProcedure

#EndRegion

#Region RouteSheets

&AtClientAtServerNoContext
Procedure RouteMapsSetSelectionByStatus(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.OperationsSheetList, 
		"Status", 
		Form.RouteMapsStatus, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.RouteMapsStatus));

EndProcedure

&AtClientAtServerNoContext
Procedure RouteMapsSetSelectionByDivision(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.OperationsSheetList, 
		"Department", 
		Form.RouteMapsDivision, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.RouteMapsDivision));

EndProcedure

&AtClientAtServerNoContext
Procedure RouteMapsSetSelectionByResponsiblePerson(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.OperationsSheetList, 
		"EmployeeResponsible", 
		Form.RouteMapsResponsible, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.RouteMapsResponsible));

EndProcedure

&AtClientAtServerNoContext
Procedure RouteMapsSetSelectionByProductType(Form)
	
	ProductDataManagementClientServer.SetSelectionByProductInRouteMapList(
		Form.OperationsSheetList,
		Form.BasisProducts,
		Form.RouteMapsAreUsedAs);
	
EndProcedure

&AtClient
Procedure CopyRouteMap()

	QueryText = NStr("vi = 'Sẽ tạo và ghi lại bản sao sơ đồ quy trình (bao gồm thao tác kỹ thuật).
								|Sao chép?';
								|ru = 'Будет создана и записана копия маршрутной карты (включая техоперации).
								|Скопировать?';
								|en = 'A copy of the route sheet will be created and saved (including manufacturing operations).
								|Continue?'; fa = 'A copy of the route sheet will be created and saved (including manufacturing operations).
								|Continue?';
								|it = 'Verrà creata e registrata una copia della scheda di lavorazione (incluse le operazioni tecniche)
								|Copiarla?';
								|pl = 'Zostanie utworzona i zapisana kopia karty technologicznej (łącznie z operacjami technicznymi).
								|Skopiować?';
								|tr = 'Rotanın bir kopyası oluşturulacak ve kaydedilecektir (teknolojik işlemler dahil).
								|Kopyalansın mı?'");
	ButtonsList = New ValueList;								
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Sao chép';
												|ru = 'Скопировать';
												|en = 'Copy'; fa = 'کپی';
												|it = 'Copiare';
												|pl = 'Copy';
												|tr = 'Kopyala'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	CallbackDescription = New CallbackDescription("QuestionCopyRouteMap", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	
EndProcedure

&AtClient
Procedure QuestionCopyRouteMap(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	CurrentData = Items.OperationsSheetList.CurrentData;
	
	Ref = CopyRouteMapOnServer(CurrentData.Ref);
	If Ref <> Undefined Then
		Items.OperationsSheetList.CurrentRow = Ref;
		
		NotifyChanged(Type("CatalogRef.RouteSheets"));
		Notify("Write_ManufacturingOperations");
		OpenForm("Catalog.RouteSheets.ObjectForm", New Structure("Key", Ref));
	Else
		ShowMessageBox(,NStr("vi = 'Không thể sao chép bản đồ lộ trình.';
							|ru = 'Не удалось скопировать маршрутную карту.';
							|en = 'Cannot copy the route sheet.'; fa = 'Cannot copy the route sheet.';
							|it = 'Non è stato possibile copiare la scheda di lavorazione.';
							|pl = 'Kopiowanie karty technologicznej nie powiodło się.';
							|tr = 'Rota kopyalanamadı.'"));
	EndIf; 

EndProcedure

&AtServerNoContext
Function CopyRouteMapOnServer(Source)

	BeginTransaction();
	
	Try
		Object = Source.Copy();
		Object.Write();
		
		If Not Catalogs.RouteSheets.FillInFromOperationsSheet(Object, Source, Object.Ref) Then
			RollbackTransaction();
			Return Undefined;
		EndIf;
		
		Object.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Return Undefined;
	EndTry;
	
	Return Object.Ref;
	
EndFunction

&AtServer
Procedure SetPropertiesForDynamicListOfRouteMaps()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = Catalogs.RouteSheets.RequestTextForDynamicListOfRouteMaps();
	ListProperties.QueryText = QueryText;
	
	ListProperties.MainTable = OperationsSheetList.MainTable;
	ListProperties.DynamicDataRead = True;
	
	Common.SetDynamicListProperties(Items.OperationsSheetList, ListProperties);
	
EndProcedure

#EndRegion

#Region Calculations_


&AtServer
Procedure SetPropertiesOfDynamicListOfPlannedCalculations22()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable              = "Document.StandardCosting2_2";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText                 = RequestTextForDynamicListOfPlannedCalculations22();
	Common.SetDynamicListProperties(Items.StandardCostingList22, ListProperties);
	
	TMCommonUse.RestoreDynamicListSettings(StandardCostingList22);
	
	CommonClientServer.SetDynamicListParameter(StandardCostingList22, "FilterProduct", BasisProducts);
	
EndProcedure

&AtServer
Function RequestTextForDynamicListOfPlannedCalculations22()
	
	QueryText = "
	|SELECT
	|	Calculations_.Ref AS Ref,
	|	Calculations_.DeletionMark AS DeletionMark,
	|	Calculations_.Number AS Number,
	|	Calculations_.Date AS Date,
	|	Calculations_.Posted AS Posted,
	|	Calculations_.Organization AS Organization,
	|	Calculations_.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
	|	Calculations_.CostObject AS CostObject,
	|	Calculations_.PriceKind AS PriceKind,
	|	(CalculationStates_3.State = VALUE(Enum.StatesOfStandardCostEstimateCalculation.CalculationError)) AS CalculationError,
	|	(CalculationStates_3.State = VALUE(Enum.StatesOfStandardCostEstimateCalculation.CalculateWithErrors)) AS CalculateWithErrors,
	|	ISNULL(CalculationStates_3.State, VALUE(Enum.StatesOfStandardCostEstimateCalculation.NotCalculated)) AS State,
	|	Calculations_.EmployeeResponsible AS EmployeeResponsible,
	|	Calculations_.Comment AS Comment,
	|	Calculations_.PointInTime AS PointInTime
	|FROM
	|	Document.StandardCosting2_2 AS Calculations_
	|		LEFT JOIN InformationRegister.StatesOfStandardCostEstimates AS CalculationStates_3
	|		ON Calculations_.Ref = CalculationStates_3.StandardCostEstimate
	|WHERE
	|	Calculations_.Ref IN
	|			(SELECT TOP 1
	|				Objects.Ref
	|			FROM
	|				Document.StandardCosting2_2.CostObjects AS Objects
	|			WHERE
	|				Objects.Ref = Calculations_.Ref
	|				AND Objects.Products = &FilterProduct)
	|";
	
	Return QueryText;
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculationsSetSelectionByStatus(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.StandardCostingList,
		"Status", 
		Form.CalculationStatus, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.CalculationStatus));

EndProcedure

&AtClientAtServerNoContext
Procedure CalculationsSetSelectionByObject(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.StandardCostingList,
		"CostObject", 
		Form.ObjectCalculations, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.ObjectCalculations));

EndProcedure

&AtClientAtServerNoContext
Procedure CostingSetSelectionByResponsible(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.StandardCostingList,
		"EmployeeResponsible", 
		Form.CalculationsResponsible, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.CalculationsResponsible));

EndProcedure

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(StandardCostingList22, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure DepartmentFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(StandardCostingList22, "ProductionDispatcherBusinessUnit", ProductionDispatcherBusinessUnit, DataCompositionComparisonType.Equal,, ValueIsFilled(ProductionDispatcherBusinessUnit));
	
EndProcedure

&AtClient
Procedure StateFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(StandardCostingList22, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	
EndProcedure

#EndRegion

#Region EngineeringChangeOrders

&AtServer
Procedure PermissionsToSetSelectionByStatus()
	
	CommonClientServer.SetDynamicListFilterItem(
		PermissionList,
		"Status",
		PermissionsStatus,
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(PermissionsStatus));
	
EndProcedure

&AtServer
Procedure PermissionsToSetSelectionBySpecification()
	
	CommonClientServer.SetDynamicListFilterItem(
		PermissionList,
		"Ref.AreasOfAction.BillOfMaterials",
		PermissionsSpecification,
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(PermissionsSpecification));
	
EndProcedure

&AtServer
Procedure PermissionsToSetSelectionByResponsible()
	
	CommonClientServer.SetDynamicListFilterItem(
		PermissionList,
		"EmployeeResponsible",
		PermissionsResponsible,
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(PermissionsResponsible));
	
EndProcedure

&AtServer
Procedure PermitsToEstablishSelectionByProduct()
	
	Documents.EngineeringChangeOrder.SetSelectionByProductInDynamicListOfMaterialReplacementPermits(
		PermissionList,
		BasisProducts,
		TheResolutionIsUsedAs);
	
EndProcedure

&AtServer
Procedure SetPropertiesOfDynamicListOfMaterialReplacementPermissions()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = Documents.EngineeringChangeOrder.RequestTextForDynamicListOfPermissionsToReplaceMaterials();
	ListProperties.QueryText = QueryText;
	
	ListProperties.MainTable = "Document.EngineeringChangeOrder";
	ListProperties.DynamicDataRead = True;
	
	Common.SetDynamicListProperties(Items.PermissionList, ListProperties);
	
EndProcedure

#EndRegion

#Region BOMsTree

&AtServer
Procedure InitializingSpecificationTree()

	TreeDate = CurrentSessionDate();
	
	ProductDataManagement.LoadSelectionSettingsOfSpecificationTree(ThisObject);
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(
		New Structure(), DataProcessors.BillsOfMaterialsTree);
	
	ProductDataManagement.ConfigureConditionalAppearanceOfSpecificationTree(ConditionalAppearance);
	
	ExpandedLevelsOfCacheTree = ProductDataManagementClientServer.ExpandedLevelsOfCacheConstructorTree();
	
	SetVisibilityOfSpecificationAssignmentParameterGroup();
	
	SetUpAdditionalCommandTaggingTree(ThisObject);
	
EndProcedure

&AtClient
Procedure HandleTreeRowActivation()
	
	CheckSetParametersForListOfAvailableSpecifications();
	
EndProcedure

&AtClient
Procedure CheckSetParametersForListOfAvailableSpecifications()
	
	CurrentData = Items.BOMsTree.CurrentData;
	
	NewFilter = ProductDataManagementClientServer.SelectionStructureOfListOfAvailableSpecifications();
	
	If CurrentData <> Undefined Then
		
		If TypeOf(CurrentData.Products) = Type("CatalogRef.Products") Then
			NewFilter.Products   = CurrentData.Products;
			NewFilter.Characteristic = CurrentData.Characteristic;
		EndIf;
		
	EndIf;
	
	If NewFilter.Products <> TreeCurrentFiltering.Products
		Or NewFilter.Characteristic <> TreeCurrentFiltering.Characteristic Then
		SetParametersForListOfAvailableSpecifications(NewFilter);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPropertiesOfDynamicListOfAvailableSpecifications()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = Catalogs.BillsOfMaterials.RequestTextForDynamicListOfAvailableSpecifications();
	
	ListProperties.QueryText                 = QueryText;
	ListProperties.MainTable              = "";
	ListProperties.DynamicDataRead = False;
	
	Common.SetDynamicListProperties(Items.ListOfAvailableBillsOfResources, ListProperties);
	
	TreeCurrentFiltering = ProductDataManagementClientServer.SelectionStructureOfListOfAvailableSpecifications();
	TreeCurrentFiltering.Products   = BasisProducts;
	TreeCurrentFiltering.Characteristic = BasisCharacteristic;
	
	SetParametersForListOfAvailableSpecifications(TreeCurrentFiltering);
	
EndProcedure

&AtServer
Procedure SetParametersForListOfAvailableSpecifications(NewFilter)
	
	TreeCurrentFiltering = NewFilter;
	AvailableSpecifications = New Array;
	CurrentRow = Items.BOMsTree.CurrentRow;
	
	If ValueIsFilled(NewFilter.Products) And CurrentRow <> Undefined Then
		
		CurrentData = BOMsTree.FindByID(CurrentRow);
		
		ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
		ProductData.Products            = NewFilter.Products;
		ProductData.Characteristic          = NewFilter.Characteristic;
		ProductData.ProductionStart      = TreeDate;
		ProductData.LineOfBusiness = DestinationParameterActivityDirection;
		ProductData.ProductionDispatcherBusinessUnit  = AssignmentParameterDivisionManager;
		
		Var_Key = ProductDataManagementClientServer.KeyParametersForSelectingTreeSpecifications(CurrentData);
		
		AvailableSpecifications = ProductDataManagement.ListOfSpecificationsByProduct(
			ProductData,
			BOMSelectionParameters[Var_Key]);
			
	EndIf; 
	
	CommonClientServer.SetDynamicListParameter(
									ListOfAvailableBillsOfResources, "BOMList", AvailableSpecifications);
	
EndProcedure

&AtServer
Function SpecificationTreeParameters()
	
	TreeParameters = ProductDataManagementClientServer.SpecificationTreeParameters();
	 
	TreeParameters.BOMSelectionParameters = BOMSelectionParameters;
	
	If BOMsTree.GetItems().Count() <> 0 Then
		String = BOMsTree.GetItems()[0];
		TreeParameters.Products               = String.Products;
		TreeParameters.ProductCharacteristic = String.Characteristic;
		TreeParameters.BillOfMaterials               = String.BillOfMaterials;
	Else
		TreeParameters.Products = BasisProducts;
		TreeParameters.BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef();
	EndIf;
	
	TreeParameters.Date                         = TreeDate;
	TreeParameters.ProductionDispatcherBusinessUnit       = AssignmentParameterDivisionManager;
	TreeParameters.LineOfBusiness      = DestinationParameterActivityDirection;
	
	TreeParameters.DynamicReading       = DynamicReading;
	TreeParameters.UnravelSemiFinishedProducts   = True;
	
	ProductDataManagement.FillInSelectionSettingsOfSpecificationTree(TreeParameters, ThisObject);
	
	Return TreeParameters;
	
EndFunction

&AtServer
Procedure CreateSpecificationTreeOnServer()
	
	UpdateProductStructure = False;
	
	If TreeFilterParametersAreChanged Then
		TreeSaveSelectionParameters();
	EndIf;
	
	TreeParameters = SpecificationTreeParameters();
	
	ProductDataManagement.BuildSpecificationTree(ThisObject, TreeParameters);
	
EndProcedure

&AtServer
Procedure HandleChangingTreeRowPropsOnServer(CurrentRow)

	CurrentData = BOMsTree.FindByID(CurrentRow);

	CurrentData.GetItems().Clear();
	
	CurrentData.ThereIsBOM = ValueIsFilled(CurrentData.BillOfMaterials);
	CurrentData.BOMIsRead = False;
	
	If CurrentData.ThereIsBOM Then
		
		TreeParameters = SpecificationTreeParameters();
		If TreeParameters.BillOfMaterials <> CurrentData.BillOfMaterials Then
			TreeParameters.BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef();
		EndIf;
		ProductDataManagement.ChangeSpecificationInTreeLine(ThisObject, TreeParameters, CurrentData);
		
	ElsIf DynamicReading Then
		
		ProductDataManagement.UpdateTreeRowDetailsInRepository(ThisObject, CurrentData);
		
	EndIf;

EndProcedure

&AtClient
Procedure ChangeSpecificationInCurLine(CurrentRow, NewSpecification = Undefined)
	
	CurrentData = BOMsTree.FindByID(CurrentRow);

	CurrentData.BillOfMaterials = NewSpecification;
	
	HandleChangingTreeRowPropsOnServer(CurrentRow);
	
	ExpandSpecificationTree(CurrentRow, CurrentData.Id);

EndProcedure

&AtClient
Procedure ExpandSpecificationTree(CurrentRow, Id)
	
	If Items.BOMsTree.CurrentRow <> CurrentRow Then
		
		CurrentData = FindStringByID_(BOMsTree.GetItems(), Id);
		If CurrentData <> Undefined Then
			Items.BOMsTree.CurrentRow = CurrentData.GetID();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function FindStringByID_(TreeItemsCollection, Id)
	
	For Each String In TreeItemsCollection Do
		
		If String.Id = Id Then
			Return String;
		Else
			Result = FindStringByID_(String.GetItems(), Id);
			If Result <> Undefined Then
				Return Result;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtServer
Function SpecificationTreePrintingOptions()
	
	Tree = ProductDataManagement.ReadSpecTree(ThisObject);
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage", PutToTempStorage(Tree, UUID));
	
	Return PrintParameters;
	
EndFunction

&AtClient
Procedure TreeFilterParametersAreChanged()
	
	TreeFilterParametersAreChanged = True;
	Items.BOMsTreePrint.Enabled = False;
	
EndProcedure

&AtServer
Procedure TreeSaveSelectionParameters()
	
	ProductDataManagement.SaveSelectionSettingsOfSpecificationTree(ThisObject);
	
	Items.BOMsTreePrint.Enabled = True;
	TreeFilterParametersAreChanged = False;
	
EndProcedure

&AtServer
Procedure HowToUpdateSpecificationOnServer()
	
	StringsList = BOMsTree.GetItems();
	If StringsList.Count() = 0 Then
		Return;
	EndIf;
	
	ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
	ProductData.Products            = StringsList[0].Products;
	ProductData.Characteristic          = StringsList[0].Characteristic;
	ProductData.ProductionStart      = TreeDate;
	ProductData.ProductionDispatcherBusinessUnit  = AssignmentParameterDivisionManager;
	ProductData.LineOfBusiness = DestinationParameterActivityDirection;
	ProductData.CurrentSpecification     = StringsList[0].BillOfMaterials;
	
	SpecificationData = ProductDataManagementServerCall.ProductSpecification(
		ProductData,
		ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly());
		
	If SpecificationData <> Undefined And StringsList[0].BillOfMaterials <> SpecificationData.BillOfMaterials Then
		StringsList[0].BillOfMaterials = SpecificationData.BillOfMaterials;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetUpAdditionalCommandTaggingTree(Form)
	
	Form.Items.TreeHideGroupingTitles.Check   = Not Form.TreeDisplayGroupingHeaders;
	Form.Items.TreeOutputOfOperationsAlongWithStages.Check = Form.TreeOutputOfOperations;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSpecificationAssignmentParameterGroup()
	
	GroupVisibility = False;
	
	SetVisibilityOfDestinationParameterElements("LineOfBusiness", GroupVisibility);
	SetVisibilityOfDestinationParameterElements("ProductionDispatcherBusinessUnit",  GroupVisibility);
	
	Items.GroupListOptionsPurposeOfSpecifications.Visible = GroupVisibility;
	Items.SpecificationAssignmentParametersGroup.Visible = GroupVisibility;
	Items.SpecificationAssignmentParametersGroup.Visible = GroupVisibility;
	If GroupVisibility Then
		UpdateHeaderOfSpecificationAssignmentParameterGroup(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfDestinationParameterElements(ParameterName, GroupVisibility)
	
	If Not ProductDataManagementCached.TypeOfDestinationParameterIsUsed(
			Enums.TypesOfBOMAssignmentParameters[ParameterName]) Then
		Return;
	EndIf;
	
	ItemArray = New Array;
	
	If ParameterName = "LineOfBusiness" Then
		ItemArray.Add("DestinationParameterActivityDirection");
		ItemArray.Add("ListOfDestinationParameterActivityDirection");
	EndIf;
	
	If ParameterName = "ProductionDispatcherBusinessUnit" Then
		ItemArray.Add("AssignmentParameterDivisionManager");
		ItemArray.Add("ListOfDestinationParameterDivisionManager");
	EndIf;
		
	For Each TagName In ItemArray Do
		Items[TagName].Visible = True;
	EndDo;
	
	GroupVisibility = True;
	
EndProcedure

&AtClient
Procedure WhenChangingValueOfSpecificationAssignmentParameter()
	
	UpdateHeaderOfSpecificationAssignmentParameterGroup(ThisObject);
	
	CompleteSpecificationManagement();
	
	If Items.GroupPages.CurrentPage <> Items.ProductStructurePage Then
		
		UpdateProductStructure = True;
		
	Else
	
		ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject);
		
		WhenChangingValueOfSpecificationAssignmentParameterOnServer();
		
		ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject);
	
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingValueOfSpecificationAssignmentParameterOnServer()
	
	HowToUpdateSpecificationOnServer();
	
	CreateSpecificationTreeOnServer();
	
	CurrentData = BOMsTree.FindByID(Items.BOMsTree.CurrentRow);
	If ValueIsFilled(TreeCurrentFiltering.Products) And CurrentData <> Undefined Then
		SetParametersForListOfAvailableSpecifications(TreeCurrentFiltering);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateHeaderOfSpecificationAssignmentParameterGroup(Form)
	
	QuantityFilled = 0;
	
	If ValueIsFilled(Form.AssignmentParameterDivisionManager) Then
		QuantityFilled = QuantityFilled + 1;
	EndIf;
	
	If ValueIsFilled(Form.DestinationParameterActivityDirection) Then
		QuantityFilled = QuantityFilled + 1;
	EndIf;
	
	Form.AssignmentParameterNumberOfFilledOnes = QuantityFilled;
	
EndProcedure

#EndRegion

#Region Other

&AtServerNoContext
Function CheckFillInProducts(Parameters)
	
	Result = Catalogs.Products.EmptyRef();
	
	If Parameters.Property("Products") Then
		
		Query = New Query(
		"SELECT
		|	T.Ref AS Products
		|FROM
		|	Catalog.Products AS T
		|WHERE
		|	T.Ref = &Products
		|	AND NOT T.IsFolder");
		Query.SetParameter("Products", Parameters.Products);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		If Selection.Next() Then
			Result = Selection.Products;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	Catalogs.BillsOfMaterials.SetConditionalAppearanceOfListOfResourceSpecifications(ConditionalAppearance, Items.BOMManagement.Name);
	
	BOMList.ConditionalAppearance.Items.Clear();
	Catalogs.BillsOfMaterials.SetConditionalAppearanceOfListOfResourceSpecifications(BOMList.ConditionalAppearance);

	OperationsSheetList.ConditionalAppearance.Items.Clear();
	Catalogs.RouteSheets.SetConditionalAppearanceOfRouteMapList(OperationsSheetList.ConditionalAppearance);
	
	ListOfAvailableBillsOfResources.ConditionalAppearance.Items.Clear();
	Catalogs.BillsOfMaterials.SetConditionalAppearanceOfListOfAvailableSpecifications(ListOfAvailableBillsOfResources.ConditionalAppearance);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BOMManagement.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BOMManagement.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	Item.Appearance.SetParameterValue("BackColor", StyleColors.ReportGroup1BackColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BOMManagementSpecificationFeature.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BOMManagement.SpecificationFeature");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đặc tính bất kỳ>';
													|ru = '<любая характеристика>';
													|en = '<any variant>'; fa = '<any variant>';
													|it = '<qualsiasi caratteristica>';
													|pl = '<dowolna charakterystyka>';
													|tr = '<herhangi bir varyant>'"));
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BOMManagementSpecificationFeature.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BOMManagement.SpecificationFeature");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đặc tính bất kỳ>';
													|ru = '<любая характеристика>';
													|en = '<any variant>'; fa = '<any variant>';
													|it = '<qualsiasi caratteristica>';
													|pl = '<dowolna charakterystyka>';
													|tr = '<herhangi bir varyant>'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BOMManagement.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BOMManagement.Priority_2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", New Font(,,True));
		
EndProcedure

&AtServer
Procedure ConfigureRightsForm()

	RightToViewBillsOfMaterials		= AccessRight("View", Metadata.Catalogs.BillsOfMaterials);
	AccessRightOfCalculation22		= AccessRight("View", Metadata.Documents.StandardCosting2_2);
	PermissionAccessRights			= AccessRight("View", Metadata.Documents.EngineeringChangeOrder);
	AccessRightsRouteMaps		= AccessRight("View", Metadata.Catalogs.RouteSheets);
	AccessRightSpecificationTree	= AccessRight("Use", Metadata.DataProcessors.BillsOfMaterialsTree);
	
	If Not RightToViewBillsOfMaterials 
			And Not AccessRightsRouteMaps
			And Not PermissionAccessRights
			And Not AccessRightSpecificationTree
			And Not AccessRightOfCalculation22 Then
		Return;
	EndIf;
	
	RightToEditSpecifications = AccessRight("Edit", Metadata.Catalogs.BillsOfMaterials);
	If Not RightToEditSpecifications Then
		Items.BOMManagement.ReadOnly = True;
		Items.BOMManagement.ChangeRowSet = False;
		Items.ListSetStatusUnderDevelopment.Visible = False;
		Items.ListSetStatusValid.Visible = False;
		Items.ListSetStatusClosed.Visible = False;
	EndIf; 
	
	If Not RightToViewBillsOfMaterials Then
		Items.TheSpecificationPageWhereTheItemIsTheItem.Visible = False;
		Items.TheSpecificationPageWhereTheItemIsMaterial.Visible = False;
	EndIf;
	
	
	Items.PlannedCalculationsPage22.Visible = AccessRightOfCalculation22;
	
	If Not PermissionAccessRights Then
		Items.ThePermissionsPageForAReplacement.Visible = False;
		Items.GroupSelectionsPermissions.Visible = False;
		Items.PermissionList.Visible = False;
	EndIf;
	
	If Not AccessRightsRouteMaps Then
		Items.RouteMapsPage.Visible = False;
		Items.GroupRouteMapSelections.Visible = False;
		Items.OperationsSheetList.Visible = False;
	EndIf;
	
	If Not AccessRightSpecificationTree Then
		Items.ProductStructurePage.Visible = False;
		Items.TheGroupStructureOfTheProductCap.Visible = False;
		Items.BOMsTree.Visible = False;
		Items.ListOfAvailableBillsOfResources.Visible = False;
	EndIf;

	If Not AccessRight("View", Metadata.DataProcessors.BillsOfMaterialsTree) Then
		Items.BOMManagementBOMTree.Visible = False;
	EndIf; 
		 
	If Not AccessRight("View", Metadata.DataProcessors.CompareBillsOfMaterials) Then
		Items.BOMManagementCompareBOMs.Visible = False;
	EndIf; 
		 
EndProcedure

&AtServer
Procedure UpdateDataOnServer()
	
	CompleteSpecificationManagement();
	Items.BOMList.Refresh();
	Items.PermissionList.Refresh();
	Items.OperationsSheetList.Refresh();
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)

	If Item.Name = "BOMManagement" Then
		
		Cancel = True;
		
		If Copy Then
			CopyBillOfMaterialsInManageBillOfMaterialsList();
			Return
		EndIf;
		
		CreateBillOfMaterialsFromManageBillOfMaterialsList();
		
	ElsIf Item.Name = "OperationsSheetList" Then
					
		If Var_Group Then
			Return;
		EndIf;
		
		If Copy Then
			
			Cancel = True;
			
			CopyRouteMap();
			
		ElsIf Not BasisProducts.IsEmpty() Then
			
			Cancel = True;
			
			FormParameters = New Structure;
			FormParameters.Insert("Basis", BasisProducts);
			OpenForm("Catalog.RouteSheets.ObjectForm", FormParameters);
			
		EndIf;
		 		
	ElsIf Item.Name = "BOMList" Then
		
		If Var_Group Then
			Return;
		EndIf;
		
		If Copy Then
			
			Cancel = True;
			
			CopyResourceSpecificationToListOfSpecifications();
			
		ElsIf Not BasisProducts.IsEmpty() Then
			
			Cancel = True;
			
			FormParameters = New Structure;
			FormParameters.Insert("Basis", BasisProducts);
			OpenForm("Catalog.BillsOfMaterials.ObjectForm", FormParameters);
			
		EndIf;
				
	ElsIf Item.Name = "PermissionList" Then

		If Not Copy And Not BasisProducts.IsEmpty() And PermissionsSpecification.IsEmpty() Then
			
			Cancel = True;
			
			Basis = New Structure;
			
			Basis.Insert("Material", BasisProducts);
			
			FormParameters = New Structure("Basis", Basis);
			
			OpenForm("Document.EngineeringChangeOrder.ObjectForm", FormParameters, , True);
			
		EndIf;

	
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateBillOfMaterialsFromManageBillOfMaterialsList(ProductionProcessType = Undefined)
	
	CurrentData = Items.BOMManagement.CurrentData;
	FillingValues = New Structure();
	
	If ProductionProcessType = Undefined Then 
		FillingValues.Insert("ProductionProcessType", PredefinedValue("Enum.ProductionProcessTypes.Assembly"));
	Else
		FillingValues.Insert("ProductionProcessType", ProductionProcessType);
	EndIf;
	
	FillingValues.Insert("Products", BasisProducts);
	FillingValues.Insert("Characteristic", ?(Not BasisCharacteristic.IsEmpty() Or CurrentData = Undefined, BasisCharacteristic, CurrentData.Characteristic));
	
	OpenForm("Catalog.BillsOfMaterials.ObjectForm", New Structure("FillingValues", FillingValues));
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_TreeDate" Then
		SpecificationsDateOnChange(Items.SpecificationsDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
