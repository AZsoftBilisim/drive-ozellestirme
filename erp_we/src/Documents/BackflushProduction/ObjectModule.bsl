#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.BackflushProduction - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = ParametersForFillingInventoryTypes("Posting");
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in tabular parts
// 'Output products', 'Side products', 'Materials and works' and 'Services' of the document, and also fills in the tabular
// part of the 'Types of supplies'.
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.BackflushProduction.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	Else
		ParameterName = "DocumentTables";
		
		ExceptionText = NStr("vi = 'Để điền dạng vật tư, không chuyển tham số ""%1"".';
							|ru = 'Для заполнения видов запасов не передан параметр ""%1"".';
							|en = 'The ""%1"" parameter is not transferred to fill in the inventory owner attributes.'; fa = 'The ""%1"" parameter is not transferred to fill in the inventory owner attributes.';
							|it = 'Per la compilazione dei tipi di scorte non è indicato il parametro ""%1"".';
							|pl = 'Do wypełnienia rodzajów zapasów nie przekazano parametru ""%1"".';
							|tr = 'Stok sahibi özniteliklerinin doldurulması için ""%1"" parametresi belirtilmedi.'");
		ExceptionText = StrTemplate(ExceptionText, ParameterName);
		
		Raise ExceptionText;
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If DocumentsPosting.DocumentProperties(ThisObject).IsNew Then
		GetNewObjectRef();
	EndIf;
	
	If GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified Then
		SideAndIntermediateRelease.Clear();
		MaterialsAndWorks.Clear();
		LaborCosts.Clear();
	EndIf;
	
	RoundingParameters = Documents.BackflushProduction.TSParametersForRounding();
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters["ManufacturedProducts"]);
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters["SideAndIntermediateRelease"]);
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters["MaterialsAndWorks"]);
	
	SeriesSpecificationParameters =
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.BackflushProduction);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.ManufacturedProducts);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.SideAndIntermediateRelease);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.MaterialsAndWorks);
	
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject,
													"ManufacturedProducts",
													"MaximumRowCodeFinishedProducts");
	
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject,
													"LaborCosts",
													"MaximumRowCodeLaborCosts");
	
	FoundRows = ManufacturedProducts.FindRows(
		New Structure("DirectionOfProductionIssue",
		Enums.BusinessTransactions.GoodsConsumptionOnDemand));
	For Each String In FoundRows Do
		String.Purpose = Undefined;
	EndDo;
	
	FoundRows = SideAndIntermediateRelease.FindRows(
		New Structure("DirectionOfProductionIssue",
		Enums.BusinessTransactions.GoodsConsumptionOnDemand));
	For Each String In FoundRows Do
		String.Purpose = Undefined;
	EndDo;
	
	ItemsAndDimensionsSelectionParameters = Documents.BackflushProduction.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TSRow = "ManufacturedProducts,SideAndIntermediateRelease,MaterialsAndWorks";
	TMCommonUse.FillInDocumentIDs(ThisObject, TSRow);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryOwnerAttributesFinishedProducts.Clear();
			InventoryOwnerAttributesSideProducts.Clear();
			InventoryOwnerAttributesMaterialsAndWorks.Clear();
		EndIf;
		
	EndIf;
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.BackflushProduction.AccountingAccountSettings_());
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
	BackflushProductionLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	TMCommonUse.SyncKeys(ThisObject);
	
	If Not Cancel
		And Not DeletionMark Then
		Documents.BackflushProduction.FormProductionBatches(ThisObject);
	EndIf;
	
	BackflushProductionLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InitializeDocument();
	
	ReferenceOrderForLaborCosts             = True;
	InventoryOwnerAttributesAreSpecifiedManually              = False;
	
	InventoryOwnerAttributesMaterialsAndWorks.Clear();
	InventoryOwnerAttributesFinishedProducts.Clear();
	InventoryOwnerAttributesSideProducts.Clear();
	
	TSRow = "ManufacturedProducts,SideAndIntermediateRelease,MaterialsAndWorks";
	TMCommonUse.ClearDocumentIDs(ThisObject, TSRow);
	
	BackflushProductionLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef." + Metadata().Name)Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.BackflushProduction.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument();
	
	If Not ValueIsFilled(MethodOfAllocatingFinishedProductCosts)
		And (Not GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProducts
				And Not GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments
				And Not GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches
				And Not GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches
			Or Patch
				And CorrectionSavesProductionLots) Then
		MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	EndIf;
	
	BackflushProductionLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	#Region CheckingCostGroupFields
	
	If Not Patch
		Or Not CorrectionSavesProductionLots Then
		NotCheckedAttributeArray.Add("ManufacturedProducts.CostGroupNumber");
	EndIf;
	
	If GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument
		Or GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified Then
		
		NotCheckedAttributeArray.Add("ManufacturedProducts.BillOfMaterials");
		NotCheckedAttributeArray.Add("SideAndIntermediateRelease.CostGroupNumber");
		NotCheckedAttributeArray.Add("MaterialsAndWorks.CostGroupNumber");
		NotCheckedAttributeArray.Add("LaborCosts.CostGroupNumber");
		
	ElsIf GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProducts
		Or GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments
		Or GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches
		Or GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches Then
		NotCheckedAttributeArray.Add("ManufacturedProducts.BillOfMaterials");
	EndIf;
	
	NotCheckedAttributeArray.Add("ManufacturedProducts.Purpose");
	If GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		CheckAssignmentCompletion(Cancel);
	EndIf;
	
	CheckWhetherCostsAreLinkedToCostGroups(Cancel);
	
	#EndRegion

	#Region WarehouseInspection_

	NotCheckedAttributeArray.Add("MaterialsAndWorks.Warehouse");
	CheckWarehouses(Cancel);
	
	#EndRegion

	#Region CheckingCharacteristics

	ParametersForCheckingCharacteristics = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	
	ParametersForCheckingCharacteristics.TSName = "ManufacturedProducts";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,
														NotCheckedAttributeArray,
														Cancel,
														ParametersForCheckingCharacteristics);
	
	ParametersForCheckingCharacteristics.TSName = "SideAndIntermediateRelease";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,
														NotCheckedAttributeArray,
														Cancel,
														ParametersForCheckingCharacteristics);
	
	ParametersForCheckingCharacteristics.TSName = "MaterialsAndWorks";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,
														NotCheckedAttributeArray,
														Cancel,
														ParametersForCheckingCharacteristics);
	
	#EndRegion

	#Region CheckingSeries

	SeriesSpecificationParameters =
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.BackflushProduction);
	ParametersArray = New Array;
	ParametersArray.Add(SeriesSpecificationParameters.ManufacturedProducts);
	ParametersArray.Add(SeriesSpecificationParameters.SideAndIntermediateRelease);
	ParametersArray.Add(SeriesSpecificationParameters.MaterialsAndWorks);
	ProductsServer.CheckSeriesCompletion(ThisObject,
		ParametersArray,
		Cancel,
		NotCheckedAttributeArray);

	#EndRegion
	#Region CheckingGiverSAppointments

	DestinationVerificationParameters = TollingScheme.ParametersForCheckingSelectionOfGiverSDestination();
	
	DestinationVerificationParameters.GiveawayTypesOfAppointments.Add(Enums.AssignmentTypes.SuppliedProducts22);
	DestinationVerificationParameters.GiveawayTypesOfAppointments.Add(Enums.AssignmentTypes.ProvidedMaterials22);
	DestinationVerificationParameters.GiveawayTypesOfAppointments.Add(Enums.AssignmentTypes.ProvidedMaterialsForStage22);
	
	DestinationVerificationParameters.TollBasedCostGroupings.Clear();
	DestinationVerificationParameters.TollBasedCostGroupings.Add(Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified);
	DestinationVerificationParameters.TollBasedCostGroupings.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments);
	DestinationVerificationParameters.TollBasedCostGroupings.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches);
	DestinationVerificationParameters.TollBasedCostGroupings.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments);
	
	TollingScheme.CheckCorrectnessOfChoiceOfGiverSAppointment(ThisObject, DestinationVerificationParameters, Cancel);
	
	
	#EndRegion
	#Region CheckingQuantities

	QuantityVerificationParameters = Documents.BackflushProduction.TSParametersForRounding();
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters["ManufacturedProducts"]);
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters["SideAndIntermediateRelease"]);
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters["MaterialsAndWorks"]);
	
	#EndRegion

	#Region RecipientVerificationAndAnalytics
	
	ItemsAndDimensionsSelectionParameters = Documents.BackflushProduction.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	#EndRegion

	#Region VATVerification
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName						= "ManufacturedProducts";
	CheckParameters.BankingDetailsNameExpenseItem			= "Recipient";
	CheckParameters.ExpenseAnalystDetailsName			= "DimensionOfExpenses";
	CheckParameters.DetailsNameItemOfAssetsLiabilities		= "Recipient";
	CheckParameters.NameOfAssetLiabilityAnalystDetails	= "AssetsLiabilitiesDimension";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject,
		ProductionIssueForActivity,
		CheckParameters,
		Cancel);
	
	CheckParameters.TabularSectionName = "SideAndIntermediateRelease";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject,
		ProductionIssueForActivity,
		CheckParameters,
		Cancel);
	
	#EndRegion
	
	#Region CheckingImports
	
	CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
	CheckParameters.TSName = "ManufacturedProducts";
	CheckParameters.AllowTraceableItemWithoutCCDNumbers = True;
	
	InventoriesServer.CheckAvailabilityOfVTCHSProductsWithCCDSoftware(ThisObject, Cancel, CheckParameters);
	
	CheckParameters.TSName = "SideAndIntermediateRelease";
	InventoriesServer.CheckAvailabilityOfVTCHSProductsWithCCDSoftware(ThisObject, Cancel, CheckParameters);
	
	#EndRegion
	
	CheckCorrectnessOfIndicationOfExcisableItems(Cancel);
	#Region CheckingInternalProcessing
	
	CheckFieldsOfInternalProcessing(NotCheckedAttributeArray, Cancel);
	
	#EndRegion
	If Not ReferenceOrderForLaborCosts Then
		NotCheckedAttributeArray.Add("LaborCosts.Performer");
	EndIf;
	
	CheckCOSTShares(Cancel);
	
	If (GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProducts
			Or GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments
			Or GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches
			Or GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches)
		And (Not Patch
			Or Not CorrectionSavesProductionLots) Then
		NotCheckedAttributeArray.Add("MethodOfAllocatingFinishedProductCosts");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	BackflushProductionLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	BackflushProductionLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	BackflushProductionLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

#Region FillingStockTypes

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager = TemporaryDataTablesOutputProducts();
	
	RefillInventoryKinds =
		InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
		Or CheckChangeInInternalProcessing(TempTablesManager)
		Or CheckChangesToDocumentDetails();
	
	#Region InventoryOwnerAttributesFinishedProducts
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangeOfOutputProductTable(TempTablesManager) Then
		
		TableTypesOfInventoryItems = TableToFillInTypesOfStocksOutputItems(TempTablesManager);
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, TableTypesOfInventoryItems);
		InventoryOwnerAttributesFinishedProducts.Load(TableTypesOfInventoryItems);
		
	EndIf;
	
	#EndRegion
	
	#Region InventoryOwnerAttributesSideProducts
	
	TempTablesManager = TemporaryByProductDataTables();
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangeOfByProductTable(TempTablesManager) Then
		
		TableTypesOfInventoryItems = TableToFillInTypesOfStocksByProducts(TempTablesManager);
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, TableTypesOfInventoryItems);
		InventoryOwnerAttributesSideProducts.Load(TableTypesOfInventoryItems);
		
	EndIf;
	
	#EndRegion
	
	#Region InventoryOwnerAttributesMaterials
	
	TempTablesManager = TemporaryDataTablesMaterialsAndWorks();
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangeInMaterialsAndWorksTable(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes("MaterialsAndWorks");
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryOwnerAttributesMaterialsAndWorks.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber",
											"Count, QuantityByGBRN");
		
		If Not Cancel Then
			FillInAdditionalFieldsForInventoryTypesMaterialsAndWorks(TempTablesManager);
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	If Not Cancel Then
		TSRow = "InventoryOwnerAttributesFinishedProducts,InventoryOwnerAttributesSideProducts,InventoryOwnerAttributesMaterialsAndWorks";
		
		TMCommonUse.FillInDocumentIDs(ThisObject, TSRow);
	EndIf;
	
EndProcedure

Function ParametersForFillingInventoryTypes(TSName)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ConsignedGoods);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	If GetFunctionalOption("UseExcisableGoods") Then
		FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
	EndIf;
	If TSName = "MaterialsAndWorks" Then
		
		NameTSTypesOfStocks ="InventoryOwnerAttributesMaterialsAndWorks";
		
		FillParameters.NameTSTypesOfStocks = NameTSTypesOfStocks;
		FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
		
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "ByBusinessTransaction");
		
		ActionOnBusinessTransaction = New Map();
		ActionOnBusinessTransaction.Insert(Enums.BusinessTransactions.MaterialTransferToProduction, "Always");
		ActionOnBusinessTransaction.Insert(Enums.BusinessTransactions.ExpensingToProductionLots, "AccordingToSettingsOfProductionContract");
		
		ActionsForBusinessTransaction = New Map;
		ActionsForBusinessTransaction.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, ActionOnBusinessTransaction);
		
		FillParameters.ActionsOfSelectionOfGoodsAcceptedForResponsibleStorageOnEconomicOperation =
			ActionsForBusinessTransaction;
		
		FillParameters.ThereIsTableOfInventoryTypes = True;
		FillParameters.NameOfInventoryTypeTable  = "TTIncomingTypesOfProductInventory";
		
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
		If GetFunctionalOption("UseInternalSubcontracting") Then
			GiverSCompanies = ManufacturedProducts.UnloadColumn("MaterialProviderCompany");
			GiverSCompanies = CommonClientServer.CollapseArray(GiverSCompanies);
			FillParameters.SelectionOfStockTypes_.MaterialProviderCompany = GiverSCompanies;
		EndIf;
	ElsIf Not TSName = "Posting" Then
		
		ExceptionText = NStr("vi = 'Tên không xác định cho phần bảng của loại hàng tồn kho: ""%TSName%""';
							|ru = 'Неизвестное имя табличной части видов запасов: ""%TSName%""';
							|en = 'Unknown name of table of inventory owner attributes: ""%TSName%""'; fa = 'Unknown name of table of inventory owner attributes: ""%TSName%""';
							|it = 'Nome della tabella di tipi di scorte sconosciuto ""%TSName%""';
							|pl = 'Nieznana nazwa sekcji tabelarycznej rodzajów zapasów: ""%TSName%""';
							|tr = 'Stok türlerinin tablo bölümünün bilinmeyen adı: ""%TSName%""'");
		ExceptionText = StrReplace(ExceptionText, "%TSName%", TSName);
		Return ExceptionText;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

Procedure FillInAdditionalFieldsForInventoryTypesMaterialsAndWorks(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableOfGoods.MaterialProviderCompany                  AS MaterialProviderCompany,
	|	TableOfGoods.ItemsLocationAttributes          AS ItemsLocationAttributes,
	|	TableOfGoods.ProductCostElement                   AS ProductCostElement,
	|	TableOfGoods.Department                       AS Department,
	|	TableOfGoods.CostGroupNumber                   AS CostGroupNumber,
	|	TableOfGoods.Products.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TableOfGoods.Package                            AS Package,
	|	SUM(TableOfGoods.Count)                   AS Count,
	|	SUM(TableOfGoods.NumberOfPackages)           AS NumberOfPackages
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.MaterialProviderCompany,
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.Department,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Package,
	|	TableOfGoods.Products.FinancialAccountingGroup
	|
	|ORDER BY
	|	MaterialProviderCompany,
	|	ItemsLocationAttributes,
	|	ProductCostElement,
	|	Department,
	|	CostGroupNumber,
	|	Package,
	|	Count DESC";
	
	VZArray = InventoryOwnerAttributesMaterialsAndWorks.Unload(, "InventoryOwnerAttribute").UnloadColumn("InventoryOwnerAttribute");
	AttributesOfInventoryTypes = Common.ObjectsAttributesValues(VZArray, "Organization, InventoryType");
	
	SampleProducts_ = Query.Execute().Select();
	
	FilterOfProducts_ = New Structure("ItemsLocationAttributes");
	TableOfTypesOfStocksOfMaterials = InventoryOwnerAttributesMaterialsAndWorks.UnloadColumns();
	
	While SampleProducts_.Next() Do
		
		GoodsQuantity         = SampleProducts_.Count;
		NumberOfPackagesOfGoods = SampleProducts_.NumberOfPackages;
		
		FillPropertyValues(FilterOfProducts_, SampleProducts_);
		If ValueIsFilled(SampleProducts_.MaterialProviderCompany) Then
			For Each InventoryLine In InventoryOwnerAttributesMaterialsAndWorks.FindRows(FilterOfProducts_) Do
				
				If InventoryLine.Count = 0
					Or Not AttributesOfInventoryTypes[InventoryLine.InventoryOwnerAttribute].Organization = SampleProducts_.MaterialProviderCompany
					Or False Then
					Continue;
				EndIf;
				
				FillInLineOfInventoryOwnerAttributeOfMaterials(
					TableOfTypesOfStocksOfMaterials, SampleProducts_, InventoryLine, AttributesOfInventoryTypes, GoodsQuantity, NumberOfPackagesOfGoods);
				
				If GoodsQuantity = 0 Then
					Break;
				EndIf;
				
			EndDo;
		EndIf;
		
		If Not GoodsQuantity = 0 Then
			
			For Each InventoryLine In InventoryOwnerAttributesMaterialsAndWorks.FindRows(FilterOfProducts_) Do
				
				If InventoryLine.Count = 0
					Or Not AttributesOfInventoryTypes[InventoryLine.InventoryOwnerAttribute].Organization = Organization Then
					Continue;
				EndIf;
				
				FillInLineOfInventoryOwnerAttributeOfMaterials(
					TableOfTypesOfStocksOfMaterials, SampleProducts_, InventoryLine, AttributesOfInventoryTypes, GoodsQuantity, NumberOfPackagesOfGoods);
				
				If GoodsQuantity = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
	EndDo;
	
	InventoryOwnerAttributesMaterialsAndWorks.Load(TableOfTypesOfStocksOfMaterials);
	
EndProcedure

Procedure FillInLineOfInventoryOwnerAttributeOfMaterials(TableOfTypesOfStocksOfMaterials, SampleProducts_, InventoryLine, AttributesOfInventoryTypes, GoodsQuantity, NumberOfPackagesOfGoods)
	
	Count         = Min(GoodsQuantity, InventoryLine.Count);
	
	NewRow = TableOfTypesOfStocksOfMaterials.Add();
	FillPropertyValues(NewRow, InventoryLine);
	
	If AttributesOfInventoryTypes[InventoryLine.InventoryOwnerAttribute].InventoryType = Enums.InventoryTypes.ConsignedGoods Then
		NewRow.RecipientInventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(Organization, Undefined, SampleProducts_);
	Else
		NewRow.RecipientInventoryOwnerAttribute = NewRow.InventoryOwnerAttribute;
	EndIf;
	
	NewRow.ProductCostElement	= SampleProducts_.ProductCostElement;
	NewRow.Department		= SampleProducts_.Department;
	NewRow.CostGroupNumber	= SampleProducts_.CostGroupNumber;
	NewRow.Package			= SampleProducts_.Package;
	NewRow.Count			= Count;
	NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
	NewRow.NumberOfPackages	= Count * NumberOfPackagesOfGoods / GoodsQuantity;
	
	InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
	InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
	
	GoodsQuantity         = GoodsQuantity - NewRow.Count;
	NumberOfPackagesOfGoods = NumberOfPackagesOfGoods - NewRow.NumberOfPackages;
	
EndProcedure

Function CheckChangesToDocumentDetails()
	
	AttributesNames = "Organization, Date, Department, ProductionIssueForActivity";
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.Text =
	"SELECT
	|	&Organization			AS Organization,
	|	&Date					AS Date,
	|	&Department			AS Department,
	|	&ProductionIssueForActivity	AS ProductionIssueForActivity
	|INTO DocumentDataTable
	|";
	
	Query.SetParameter("Organization",			Organization);
	Query.SetParameter("Date",					Date);
	Query.SetParameter("Department",			Department);
	Query.SetParameter("ProductionIssueForActivity",	ProductionIssueForActivity);
	
	Query.Execute();
	
	Return InventoriesServer.CheckChangesToDocumentDetails(Query.TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckChangeInInternalProcessing(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT TOP 1
	|	TableOfGoods.CostGroupNumber		AS CostGroupNumber,
	|	TableOfGoods.InternalSubcontracting	AS InternalSubcontracting,
	|	TableOfGoods.MaterialProviderCompany		AS MaterialProviderCompany
	|FROM
	|	(SELECT
	|		TableOfGoods.CostGroupNumber		AS CostGroupNumber,
	|		TableOfGoods.InternalSubcontracting	AS InternalSubcontracting,
	|		TableOfGoods.MaterialProviderCompany		AS MaterialProviderCompany,
	|		TableOfGoods.Count				AS Count,
	|		TableOfGoods.CostShare			AS CostShare,
	|		TableOfGoods.Sum					AS Sum
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableOfGoods.CostGroupNumber		AS CostGroupNumber,
	|		TableOfGoods.InternalSubcontracting	AS InternalSubcontracting,
	|		TableOfGoods.MaterialProviderCompany		AS MaterialProviderCompany,
	|		-TableOfGoods.Count				AS Count,
	|		-TableOfGoods.CostShare			AS CostShare,
	|		-TableOfGoods.Sum					AS Sum
	|	FROM
	|		Document.BackflushProduction.ManufacturedProducts AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Ref = &Ref
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.InternalSubcontracting,
	|	TableOfGoods.MaterialProviderCompany
	|
	|HAVING
	|	NOT SUM(TableOfGoods.Count) = 0
	|		OR NOT SUM(TableOfGoods.CostShare) = 0
	|		OR NOT SUM(TableOfGoods.Sum) = 0
	|";
	
	Query.SetParameter("Ref", Ref);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction
Function CheckChangeOfOutputProductTable(TempTablesManager)
	
	Query = New Query(
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.DirectionOfProductionIssue			AS DirectionOfProductionIssue,
	|	TableOfGoods.Recipient					AS Recipient,
	|	TableOfGoods.BillOfMaterials					AS BillOfMaterials,
	|	TableOfGoods.Department				AS Department,
	|	TableOfGoods.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TableOfGoods.RowID			AS RowID,
	|	TableOfGoods.RowCode					AS RowCode,
	|	TableOfGoods.CostGroupNumber			AS CostGroupNumber,
	|	TableOfGoods.GLAccountSettings			AS GLAccountSettings
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TableOfGoods.DirectionOfProductionIssue			AS DirectionOfProductionIssue,
	|		TableOfGoods.Recipient					AS Recipient,
	|		TableOfGoods.BillOfMaterials					AS BillOfMaterials,
	|		TableOfGoods.Department				AS Department,
	|		TableOfGoods.DimensionOfExpenses			AS DimensionOfExpenses,
	|		TableOfGoods.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|		TableOfGoods.RowID			AS RowID,
	|		TableOfGoods.CostGroupNumber			AS CostGroupNumber,
	|		TableOfGoods.RowCode					AS RowCode,
	|		TableOfGoods.GLAccountSettings			AS GLAccountSettings,
	|		TableOfGoods.CostShare				AS CostShare,
	|		TableOfGoods.Count					AS Count,
	|		TableOfGoods.Sum						AS Sum
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.DirectionOfProductionIssue			AS DirectionOfProductionIssue,
	|		TableTypesOfStocks_.Recipient					AS Recipient,
	|		TableTypesOfStocks_.BillOfMaterials					AS BillOfMaterials,
	|		TableTypesOfStocks_.Department				AS Department,
	|		TableTypesOfStocks_.DimensionOfExpenses			AS DimensionOfExpenses,
	|		TableTypesOfStocks_.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|		TableTypesOfStocks_.RowID			AS RowID,
	|		TableTypesOfStocks_.CostGroupNumber			AS CostGroupNumber,
	|		TableTypesOfStocks_.RowCode					AS RowCode,
	|		TableTypesOfStocks_.GLAccountSettings			AS GLAccountSettings,
	|		-TableTypesOfStocks_.CostShare				AS CostShare,
	|		-TableTypesOfStocks_.Count					AS Count,
	|		-TableTypesOfStocks_.Sum						AS Sum
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.DirectionOfProductionIssue,
	|	TableOfGoods.Recipient,
	|	TableOfGoods.BillOfMaterials,
	|	TableOfGoods.Department,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.RowID,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.RowCode,
	|	TableOfGoods.GLAccountSettings
	|
	|HAVING
	|	NOT SUM(TableOfGoods.Count) = 0
	|	OR NOT SUM(TableOfGoods.CostShare) = 0
	|	OR NOT SUM(TableOfGoods.Sum) = 0
	|");
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function CheckChangeOfByProductTable(TempTablesManager)
	
	Query = New Query(
		"SELECT
		|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	TableOfGoods.Department				AS Department,
		|	TableOfGoods.DirectionOfProductionIssue			AS DirectionOfProductionIssue,
		|	TableOfGoods.ReceivingBusinessUnit		AS ReceivingBusinessUnit,
		|	TableOfGoods.Recipient					AS Recipient,
		|	TableOfGoods.DimensionOfExpenses			AS DimensionOfExpenses,
		|	TableOfGoods.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
		|	TableOfGoods.RowID			AS RowID,
		|	TableOfGoods.ProductCostElement			AS ProductCostElement,
		|	TableOfGoods.CostGroupNumber			AS CostGroupNumber,
		|	TableOfGoods.ProductOwner				AS ProductOwner,
		|	TableOfGoods.GLAccountSettings			AS GLAccountSettings
		|FROM
		|	(SELECT
		|		TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|		TableOfGoods.Department				AS Department,
		|		TableOfGoods.DirectionOfProductionIssue			AS DirectionOfProductionIssue,
		|		TableOfGoods.ReceivingBusinessUnit		AS ReceivingBusinessUnit,
		|		TableOfGoods.Recipient					AS Recipient,
		|		TableOfGoods.DimensionOfExpenses			AS DimensionOfExpenses,
		|		TableOfGoods.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
		|		TableOfGoods.RowID			AS RowID,
		|		TableOfGoods.ProductCostElement			AS ProductCostElement,
		|		TableOfGoods.ProductOwner				AS ProductOwner,
		|		TableOfGoods.CostGroupNumber			AS CostGroupNumber,
		|		TableOfGoods.GLAccountSettings			AS GLAccountSettings,
		|		TableOfGoods.Count					AS Count,
		|		TableOfGoods.Sum						AS Sum
		|	FROM
		|		TableOfGoods AS TableOfGoods
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|		TableTypesOfStocks_.Department				AS Department,
		|		TableTypesOfStocks_.DirectionOfProductionIssue			AS DirectionOfProductionIssue,
		|		TableTypesOfStocks_.ReceivingBusinessUnit		AS ReceivingBusinessUnit,
		|		TableTypesOfStocks_.Recipient					AS Recipient,
		|		TableTypesOfStocks_.DimensionOfExpenses			AS DimensionOfExpenses,
		|		TableTypesOfStocks_.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
		|		TableTypesOfStocks_.RowID			AS RowID,
		|		TableTypesOfStocks_.ProductCostElement			AS ProductCostElement,
		|		TableTypesOfStocks_.ProductOwner				AS ProductOwner,
		|		TableTypesOfStocks_.CostGroupNumber			AS CostGroupNumber,
		|		TableTypesOfStocks_.GLAccountSettings			AS GLAccountSettings,
		|		-TableTypesOfStocks_.Count					AS Count,
		|		-TableTypesOfStocks_.Sum						AS Sum
		|	FROM
		|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
		|
		|GROUP BY
		|	TableOfGoods.ItemsLocationAttributes,
		|	TableOfGoods.Department,
		|	TableOfGoods.DirectionOfProductionIssue,
		|	TableOfGoods.ReceivingBusinessUnit,
		|	TableOfGoods.Recipient,
		|	TableOfGoods.DimensionOfExpenses,
		|	TableOfGoods.AssetsLiabilitiesDimension,
		|	TableOfGoods.RowID,
		|	TableOfGoods.ProductCostElement,
		|	TableOfGoods.ProductOwner,
		|	TableOfGoods.CostGroupNumber,
		|	TableOfGoods.GLAccountSettings
		|
		|HAVING
		|	NOT SUM(TableOfGoods.Count) = 0
		|	OR NOT SUM(TableOfGoods.Sum) = 0
		|");
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function CheckChangeInMaterialsAndWorksTable(TempTablesManager)
	
	Query = New Query(
		"SELECT
		|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
		|FROM
		|	(SELECT
		|		TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|		TableOfGoods.ProductCostElement			AS ProductCostElement,
		|		TableOfGoods.CostGroupNumber			AS CostGroupNumber,
		|		TableOfGoods.Warehouse						AS Warehouse,
		|		TableOfGoods.Department				AS Department,
		|		TableOfGoods.Package						AS Package,
		|		TableOfGoods.NumberOfPackages			AS NumberOfPackages,
		|		TableOfGoods.Count					AS Count
		|	FROM
		|		TableOfGoods AS TableOfGoods
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|		TableTypesOfStocks_.ProductCostElement			AS ProductCostElement,
		|		TableTypesOfStocks_.CostGroupNumber			AS CostGroupNumber,
		|		TableTypesOfStocks_.OriginWarehouse				AS OriginWarehouse,
		|		TableTypesOfStocks_.Department				AS Department,
		|		TableTypesOfStocks_.Package						AS Package,
		|		-TableTypesOfStocks_.NumberOfPackages			AS NumberOfPackages,
		|		-TableTypesOfStocks_.Count					AS Count
		|	FROM
		|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
		|
		|GROUP BY
		|	TableOfGoods.ItemsLocationAttributes,
		|	TableOfGoods.ProductCostElement,
		|	TableOfGoods.Department,
		|	TableOfGoods.CostGroupNumber,
		|	TableOfGoods.Warehouse,
		|	TableOfGoods.Package
		|
		|HAVING
		|	NOT SUM(TableOfGoods.Count) = 0
		|	OR NOT SUM(TableOfGoods.NumberOfPackages) = 0
		|");
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function TemporaryDataTablesOutputProducts()
	
	Query = New Query(
	"SELECT
	|	TableOfGoods.LineNumber										AS LineNumber,
	|	TableOfGoods.Products										AS Products,
	|	TableOfGoods.Characteristic									AS Characteristic,
	|	TableOfGoods.Purpose										AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes						AS ItemsLocationAttributes,
	|	TableOfGoods.DirectionOfProductionIssue								AS DirectionOfProductionIssue,
	|	TableOfGoods.Recipient										AS Recipient,
	|	TableOfGoods.CostGroupNumber								AS CostGroupNumber,
	|	TableOfGoods.BillOfMaterials										AS BillOfMaterials,
	|	TableOfGoods.Department									AS Department,
	|	TableOfGoods.DimensionOfExpenses								AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension							AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings								AS GLAccountSettings,
	|	TableOfGoods.RowID								AS RowID,
	|	TableOfGoods.RowCode										AS RowCode,
	|	TableOfGoods.InternalSubcontracting							AS InternalSubcontracting,
	|	TableOfGoods.MaterialProviderCompany								AS MaterialProviderCompany,
	|	CASE
	|		WHEN TableOfGoods.InternalSubcontracting
	|			THEN TableOfGoods.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN &Organization
	|	END															AS Organization,
	|	TableOfGoods.Count										AS Count,
	|	TableOfGoods.CostShare									AS CostShare,
	|	TableOfGoods.Sum											AS Sum
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Count > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber										AS LineNumber,
	|	TableOfGoods.Products										AS Products,
	|	TableOfGoods.Characteristic									AS Characteristic,
	|	TableOfGoods.Purpose										AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes						AS ItemsLocationAttributes,
	|	TableOfGoods.DirectionOfProductionIssue								AS DirectionOfProductionIssue,
	|	TableOfGoods.Recipient										AS Recipient,
	|	TableOfGoods.CostGroupNumber								AS CostGroupNumber,
	|	TableOfGoods.BillOfMaterials										AS BillOfMaterials,
	|	TableOfGoods.Department									AS Department,
	|	TableOfGoods.DimensionOfExpenses								AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension							AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings								AS GLAccountSettings,
	|	TableOfGoods.RowID								AS RowID,
	|	TableOfGoods.RowCode										AS RowCode,
	|	TableOfGoods.InternalSubcontracting							AS InternalSubcontracting,
	|	TableOfGoods.MaterialProviderCompany								AS MaterialProviderCompany,
	|	TableOfGoods.Count										AS Count,
	|	TableOfGoods.Sum											AS Sum,
	|	TableOfGoods.CostShare									AS CostShare,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease)	AS BusinessOperation,
	|	ManufacturersOfExcisableItems.Country							AS Country,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)						AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|		
	|		LEFT JOIN TTManufacturersOfExcisableItems AS ManufacturersOfExcisableItems
	|		ON TableOfGoods.Organization = ManufacturersOfExcisableItems.Organization
	|
	|WHERE
	|	NOT CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND CatProducts.TracedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.DirectionOfProductionIssue				AS DirectionOfProductionIssue,
	|	TableTypesOfStocks_.Recipient						AS Recipient,
	|	TableTypesOfStocks_.CostGroupNumber				AS CostGroupNumber,
	|	TableTypesOfStocks_.BillOfMaterials						AS BillOfMaterials,
	|	TableTypesOfStocks_.Department					AS Department,
	|	TableTypesOfStocks_.DimensionOfExpenses				AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.GLAccountSettings				AS GLAccountSettings,
	|	TableTypesOfStocks_.RowID				AS RowID,
	|	TableTypesOfStocks_.RowCode						AS RowCode,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.Count						AS Count,
	|	TableTypesOfStocks_.Sum							AS Sum,
	|	TableTypesOfStocks_.CostShare					AS CostShare
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.DirectionOfProductionIssue			AS DirectionOfProductionIssue,
	|	TableTypesOfStocks_.Recipient					AS Recipient,
	|	TableTypesOfStocks_.CostGroupNumber			AS CostGroupNumber,
	|	TableTypesOfStocks_.BillOfMaterials					AS BillOfMaterials,
	|	TableTypesOfStocks_.Department				AS Department,
	|	TableTypesOfStocks_.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.GLAccountSettings				AS GLAccountSettings,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	TableTypesOfStocks_.RowCode					AS RowCode,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.Sum						AS Sum,
	|	TableTypesOfStocks_.CostShare				AS CostShare
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|");
	
	UseInternalSubcontracting = False;
	UseInternalSubcontracting = GetFunctionalOption("UseInternalSubcontracting");
	TempTablesManager = New TempTablesManager;
	ExcisableGoodsAccounting.ManufacturersOfExcisableItems(ThisObject,
															TempTablesManager,
															UseInternalSubcontracting);
	
	Query.TempTablesManager = TempTablesManager;
	
	If AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
			And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined Then
		DocumentTables = AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange;
	Else
		DocumentTables = Documents.BackflushProduction.CollectionOfTabularPartsOfGoods();
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	Query.SetParameter("Organization",		Organization);
	Query.SetParameter("TableOfGoods",		DocumentTables.ManufacturedProducts);
	Query.SetParameter("TableTypesOfStocks_",	InventoryOwnerAttributesFinishedProducts);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Function TemporaryByProductDataTables()
	
	Query = New Query("
	|SELECT DISTINCT
	|	TableOfGoods.CostGroupNumber		AS CostGroupNumber,
	|	TableOfGoods.InternalSubcontracting	AS InternalSubcontracting,
	|	TableOfGoods.MaterialProviderCompany		AS MaterialProviderCompany
	|INTO CostGroups
	|FROM
	|	&ManufacturedProducts AS TableOfGoods
	|
	|INDEX BY
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.Department				AS Department,
	|	TableOfGoods.DirectionOfProductionIssue			AS DirectionOfProductionIssue,
	|	TableOfGoods.ReceivingBusinessUnit		AS ReceivingBusinessUnit,
	|	TableOfGoods.Recipient					AS Recipient,
	|	TableOfGoods.CostGroupNumber			AS CostGroupNumber,
	|	TableOfGoods.ProductOwner				AS ProductOwner,
	|	CASE
	|		WHEN TableOfGoods.ProductOwner <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN TableOfGoods.ProductOwner
	|		WHEN TRUE
	|			THEN &Organization
	|	END										AS Organization,
	|	TableOfGoods.ProductCostElement			AS ProductCostElement,
	|	TableOfGoods.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings			AS GLAccountSettings,
	|	TableOfGoods.RowID			AS RowID,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.Sum						AS Sum
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Count > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.Department				AS Department,
	|	TableOfGoods.DirectionOfProductionIssue			AS DirectionOfProductionIssue,
	|	TableOfGoods.ReceivingBusinessUnit		AS ReceivingBusinessUnit,
	|	TableOfGoods.Recipient					AS Recipient,
	|	TableOfGoods.CostGroupNumber			AS CostGroupNumber,
	|	CostGroups.InternalSubcontracting			AS InternalSubcontracting,
	|	CostGroups.MaterialProviderCompany				AS MaterialProviderCompany,
	|	TableOfGoods.ProductOwner				AS ProductOwner,
	|	TableOfGoods.ProductCostElement			AS ProductCostElement,
	|	TableOfGoods.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings			AS GLAccountSettings,
	|	TableOfGoods.RowID			AS RowID,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.Sum						AS Sum,
	|	ManufacturersOfExcisableItems.Country		AS Country,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|		
	|		INNER JOIN CostGroups AS CostGroups
	|		ON CostGroups.CostGroupNumber = TableOfGoods.CostGroupNumber
	|		
	|		LEFT JOIN TTManufacturersOfExcisableItems AS ManufacturersOfExcisableItems
	|		ON TableOfGoods.Organization = ManufacturersOfExcisableItems.Organization
	|
	|WHERE
	|	NOT CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND CatProducts.TracedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Department					AS Department,
	|	TableTypesOfStocks_.DirectionOfProductionIssue				AS DirectionOfProductionIssue,
	|	TableTypesOfStocks_.ReceivingBusinessUnit			AS ReceivingBusinessUnit,
	|	TableTypesOfStocks_.Recipient						AS Recipient,
	|	TableTypesOfStocks_.CostGroupNumber				AS CostGroupNumber,
	|	TableTypesOfStocks_.ProductOwner				AS ProductOwner,
	|	TableTypesOfStocks_.ProductCostElement				AS ProductCostElement,
	|	TableTypesOfStocks_.DimensionOfExpenses				AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.RowID				AS RowID,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.GLAccountSettings				AS GLAccountSettings,
	|	TableTypesOfStocks_.Count						AS Count,
	|	TableTypesOfStocks_.Sum							AS Sum
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Department				AS Department,
	|	TableTypesOfStocks_.DirectionOfProductionIssue			AS DirectionOfProductionIssue,
	|	TableTypesOfStocks_.ReceivingBusinessUnit		AS ReceivingBusinessUnit,
	|	TableTypesOfStocks_.Recipient					AS Recipient,
	|	TableTypesOfStocks_.CostGroupNumber			AS CostGroupNumber,
	|	TableTypesOfStocks_.ProductOwner				AS ProductOwner,
	|	TableTypesOfStocks_.ProductCostElement			AS ProductCostElement,
	|	TableTypesOfStocks_.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.GLAccountSettings				AS GLAccountSettings,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.Sum						AS Sum
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|");
	
	UseInternalSubcontracting = False;
	UseInternalSubcontracting = GetFunctionalOption("UseInternalSubcontracting");
	TempTablesManager = New TempTablesManager;
	ExcisableGoodsAccounting.ManufacturersOfExcisableItems(ThisObject,
															TempTablesManager,
															UseInternalSubcontracting);
	
	Query.TempTablesManager = TempTablesManager;
	
	If AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
			And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined Then
		DocumentTables = AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange;
	Else
		DocumentTables = Documents.BackflushProduction.CollectionOfTabularPartsOfGoods();
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	Query.SetParameter("Organization",		Organization);
	Query.SetParameter("TableOfGoods",		DocumentTables.SideAndIntermediateRelease);
	Query.SetParameter("ManufacturedProducts",	DocumentTables.ManufacturedProducts);
	Query.SetParameter("TableTypesOfStocks_",	InventoryOwnerAttributesSideProducts);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Function TemporaryDataTablesMaterialsAndWorks()
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	TableOfGoods.CostGroupNumber     AS CostGroupNumber,
	|	TableOfGoods.InternalSubcontracting AS InternalSubcontracting,
	|	TableOfGoods.MaterialProviderCompany    AS MaterialProviderCompany
	|INTO CostGroups
	|FROM
	|	&ManufacturedProducts AS TableOfGoods
	|
	|INDEX BY
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Date               AS Date,
	|	&Organization        AS Organization,
	|	UNDEFINED        AS Partner,
	|	UNDEFINED        AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)	AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)		AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef)					AS Currency,
	|	&ProductionIssueForActivity AS ProductionIssueForActivity,
	|	&ProductionIssueForActivity AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)	AS BusinessOperation,
	|	FALSE			AS ThereAreTransactionsInTablePart,
	|	&Department	AS Department,
	|	VALUE(Catalog.Users.EmptyRef)	AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.Warehouse						AS Warehouse,
	|	TableOfGoods.Department				AS Department,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.ProductCostElement			AS ProductCostElement,
	|	TableOfGoods.CostGroupNumber			AS CostGroupNumber,
	|	CASE
	|		WHEN &PackagingUnitsInInventoryOwnerAttributes
	|			THEN TableOfGoods.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END										AS Package,
	|	CASE
	|		WHEN &PackagingUnitsInInventoryOwnerAttributes
	|			THEN TableOfGoods.NumberOfPackages
	|		ELSE 0
	|	END										AS NumberOfPackages,
	|	TableOfGoods.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END										AS QuantityByGBRN,
	|	&FieldTextTableOfGoodsCCDNumber_			AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|WHERE
	|	TableOfGoods.Count > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.Warehouse						AS Warehouse,
	|	TableOfGoods.Department				AS Department,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.ProductCostElement			AS ProductCostElement,
	|	TableOfGoods.CostGroupNumber			AS CostGroupNumber,
	|	CostGroups.InternalSubcontracting			AS InternalSubcontracting,
	|	CostGroups.MaterialProviderCompany				AS MaterialProviderCompany,
	|	TableOfGoods.Package						AS Package,
	|	TableOfGoods.NumberOfPackages			AS NumberOfPackages,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.QuantityByGBRN				AS QuantityByGBRN,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)	AS ProductsGroup,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	VALUE(Catalog.VATRates.EmptyRef)	AS VATRate,
	|	0											AS AmountIncludingVAT,
	|	0											AS VATAmount,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	TRUE										AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber						AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|	
	|	LEFT JOIN Catalog.Products AS CatProducts
	|	ON TableOfGoods.Products = CatProducts.Ref
	|	
	|	INNER JOIN CostGroups AS CostGroups
	|	ON CostGroups.CostGroupNumber = TableOfGoods.CostGroupNumber
	|
	|WHERE
	|	NOT CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.Department				AS Warehouse,
	|	TableOfGoods.Department				AS Department,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.ProductCostElement			AS ProductCostElement,
	|	TableOfGoods.CostGroupNumber			AS CostGroupNumber,
	|	CostGroups.InternalSubcontracting			AS InternalSubcontracting,
	|	CostGroups.MaterialProviderCompany				AS MaterialProviderCompany,
	|	TableOfGoods.Package						AS Package,
	|	TableOfGoods.NumberOfPackages			AS NumberOfPackages,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.QuantityByGBRN				AS QuantityByGBRN,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)	AS ProductsGroup,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	VALUE(Catalog.VATRates.EmptyRef)	AS VATRate,
	|	0											AS AmountIncludingVAT,
	|	0											AS VATAmount,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	TRUE										AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber						AS CCDNumber
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|		INNER JOIN CostGroups AS CostGroups
	|		ON CostGroups.CostGroupNumber = TableOfGoods.CostGroupNumber
	|
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatProducts.TracedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ProductCostElement			AS ProductCostElement,
	|	TableTypesOfStocks_.Department				AS Department,
	|	TableTypesOfStocks_.CostGroupNumber			AS CostGroupNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.Package						AS Package,
	|	TableTypesOfStocks_.NumberOfPackages			AS NumberOfPackages,
	|	TableTypesOfStocks_.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	FALSE											AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ProductCostElement			AS ProductCostElement,
	|	TableTypesOfStocks_.Department				AS Department,
	|	TableTypesOfStocks_.CostGroupNumber			AS CostGroupNumber,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.Package						AS Package,
	|	TableTypesOfStocks_.NumberOfPackages			AS NumberOfPackages,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	Dimension.StorageLocation							AS OriginWarehouse,
	|	TableTypesOfStocks_.SalesOpportunity						AS SalesOpportunity,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually	AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTypesOfProductStocks.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TTTypesOfProductStocks.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|	TTTypesOfProductStocks.CCDNumber			AS CCDNumber,
	|	TTTypesOfProductStocks.Count			AS Count
	|INTO InventoryOwnerAttributesFinishedProducts
	|FROM
	|	&InventoryOwnerAttributesFinishedProducts AS TTTypesOfProductStocks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTypesOfProductStocks.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TTTypesOfProductStocks.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|	TTTypesOfProductStocks.CCDNumber			AS CCDNumber,
	|	TTTypesOfProductStocks.Count			AS Count
	|INTO InventoryOwnerAttributesSideProducts
	|FROM
	|	&InventoryOwnerAttributesSideProducts AS TTTypesOfProductStocks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ENDOFPERIOD(&Date, MONTH)						AS Period,
	|	&Organization									AS Organization,
	|	TTTypesOfProductStocks.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TTTypesOfProductStocks.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TTTypesOfProductStocks.CCDNumber					AS CCDNumber,
	|	SUM(TTTypesOfProductStocks.Count)			AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE SUM(TTTypesOfProductStocks.QuantityByGBRN)
	|	END											AS QuantityByGBRN
	|INTO TTIncomingTypesOfProductInventory
	|FROM
	|	(SELECT
	|		TTTypesOfProductStocks.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TTTypesOfProductStocks.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|		TTTypesOfProductStocks.CCDNumber			AS CCDNumber,
	|		TTTypesOfProductStocks.Count			AS Count,
	|		0										AS QuantityByGBRN
	|	FROM
	|		InventoryOwnerAttributesFinishedProducts AS TTTypesOfProductStocks
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|			ON TTTypesOfProductStocks.ItemsLocationAttributes = DimensionKeys.Ref
	|			
	|			LEFT JOIN Catalog.Products AS CatalogProducts
	|			ON DimensionKeys.Products = CatalogProducts.Ref
	|	WHERE
	|		NOT (&UseTraceableImportedGoodsAccounting
	|			AND ISNULL(CatalogProducts.TracedGoods, FALSE)
	|			AND TTTypesOfProductStocks.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|		)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTTypesOfProductStocks.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TTTypesOfProductStocks.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|		TTTypesOfProductStocks.CCDNumber			AS CCDNumber,
	|		TTTypesOfProductStocks.Count			AS Count,
	|		0										AS QuantityByGBRN
	|	FROM
	|		InventoryOwnerAttributesSideProducts AS TTTypesOfProductStocks
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|			ON TTTypesOfProductStocks.ItemsLocationAttributes = DimensionKeys.Ref
	|			
	|			LEFT JOIN Catalog.Products AS CatalogProducts
	|			ON DimensionKeys.Products = CatalogProducts.Ref
	|	WHERE
	|		NOT (&UseTraceableImportedGoodsAccounting
	|			AND ISNULL(CatalogProducts.TracedGoods, FALSE)
	|			AND TTTypesOfProductStocks.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|		)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InventoryOwnerAttributesMaterialsAndWorks.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		InventoryOwnerAttributesMaterialsAndWorks.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		InventoryOwnerAttributesMaterialsAndWorks.CCDNumber					AS CCDNumber,
	|		InventoryOwnerAttributesMaterialsAndWorks.Count					AS Count,
	|		InventoryOwnerAttributesMaterialsAndWorks.QuantityByGBRN			AS QuantityByGBRN
	|	FROM
	|		Document.BackflushProduction.InventoryOwnerAttributesMaterialsAndWorks AS InventoryOwnerAttributesMaterialsAndWorks
	|	WHERE
	|		InventoryOwnerAttributesMaterialsAndWorks.Ref = &ReversedDocument
	|	) AS TTTypesOfProductStocks
	|
	|GROUP BY
	|	TTTypesOfProductStocks.ItemsLocationAttributes,
	|	TTTypesOfProductStocks.InventoryOwnerAttribute,
	|	TTTypesOfProductStocks.CCDNumber
	|";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	If AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
			And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined Then
		
		DocumentTables = AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange;
		
	Else
		DocumentTables = Documents.BackflushProduction.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	Query.SetParameter("Date",					Date);
	Query.SetParameter("Organization",			Organization);
	Query.SetParameter("Department",			Department);
	Query.SetParameter("ProductionIssueForActivity",	ProductionIssueForActivity);
	Query.SetParameter("TableOfGoods",			DocumentTables.MaterialsAndWorks);
	Query.SetParameter("ManufacturedProducts",		DocumentTables.ManufacturedProducts);
	Query.SetParameter("TableTypesOfStocks_",		InventoryOwnerAttributesMaterialsAndWorks);
	Query.SetParameter("PackagingUnitsInInventoryOwnerAttributes",	PackagingUnitsInInventoryOwnerAttributes);
	Query.SetParameter("ReversedDocument",	ReversedDocument);
	Query.SetParameter(
		"UseSeparateAccountingByTaxation",
		AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(Organization, Date));
	
	TSAttributes = "ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, Count";
	Query.SetParameter("InventoryOwnerAttributesFinishedProducts",		InventoryOwnerAttributesFinishedProducts.Unload(, TSAttributes));
	Query.SetParameter("InventoryOwnerAttributesSideProducts",		InventoryOwnerAttributesSideProducts.Unload(, TSAttributes));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		DocumentTables.MaterialsAndWorks,
		Query.Text,
		"&FieldTextTableOfGoodsQuantityByGBRN_",
		"TableOfGoods",
		"QuantityByGBRN",
		"TableOfGoods.QuantityByGBRN",
		"0");
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		DocumentTables.MaterialsAndWorks,
		Query.Text,
		"&FieldTextTableOfGoodsCCDNumber_",
		"TableOfGoods",
		"CCDNumber",
		"TableOfGoods.CCDNumber",
		"VALUE(Catalog.CCDNumbers.EmptyRef)");
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// Tables for filling in the types of inventory of the product.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - temporary table Manager
// 
// Returns:
//  ValueTable - Tables to fill in types of product inventory
//
Function TableToFillInTypesOfStocksOutputItems(TempTablesManager)
	
	QueryTexts = New Array;
	
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.CountryWH = True;
	
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters));
	
	PartOfTheRequestText = 
	"SELECT
	|	CASE
	|		WHEN TableOfGoods.InternalSubcontracting
	|			THEN TableOfGoods.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN &Organization
	|	END														AS Organization,
	|	&Currency														AS Currency,
	|	&TaxationOfOrganization									AS TaxationOfOrganization,
	|	UNDEFINED												AS Terms,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)	AS VATTaxation,
	|	TableOfGoods.BusinessOperation						AS BusinessOperation,
	|	TableOfGoods.Department								AS Department,
	|	MAX(TableOfGoods.LineNumber)						AS LineNumber,
	|	TableOfGoods.Products									AS Products,
	|	TableOfGoods.Characteristic								AS Characteristic,
	|	TableOfGoods.Purpose									AS Purpose,
	|	CASE
	|		WHEN TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND TableOfGoods.Products.TracedGoods
	|			THEN VALUE(Enum.InventoryTypes.Work_5)
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		WHEN TRUE
	|			THEN VALUE(Enum.InventoryTypes.OwnGoods)
	|	END														AS InventoryType,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN TableOfGoods.Purpose.Partner
	|		WHEN TableOfGoods.InternalSubcontracting
	|			THEN TableOfGoods.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN &Organization
	|	END														AS GoodsOwner,
	|	ISNULL(TableOfGoods.Purpose.Contract.Counterparty, UNDEFINED) AS Counterparty,
	|	ISNULL(TableOfGoods.Purpose.Contract, UNDEFINED)	AS Contract,
	|	TableOfGoods.Recipient									AS Recipient,
	|	TableOfGoods.CostGroupNumber							AS CostGroupNumber,
	|	TableOfGoods.BillOfMaterials									AS BillOfMaterials,
	|	TableOfGoods.ItemsLocationAttributes					AS ItemsLocationAttributes,
	|	TableOfGoods.DirectionOfProductionIssue							AS DirectionOfProductionIssue,
	|	TableOfGoods.DimensionOfExpenses							AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension						AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings							AS GLAccountSettings,
	|	TableOfGoods.RowCode									AS RowCode,
	|	TableOfGoods.RowID							AS RowID,
	|	TableOfGoods.CCDNumber										AS CCDNumber,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)				AS CurViewOfStocks,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)				AS InventoryOwnerAttribute,
	|	SUM(TableOfGoods.Count)							AS Count,
	|	SUM(TableOfGoods.CostShare)							AS CostShare,
	|	SUM(TableOfGoods.Sum)									AS Sum,
	|	FALSE														AS ThisIsReusablePackage,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN FALSE
	|		WHEN TRUE
	|			THEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|	END														AS SubjectToExcise,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END														AS BusinessUnitProduction
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON TableOfGoods.Products = Category_Data.Products
	|			AND TableOfGoods.Country = Category_Data.Country
	|
	|WHERE
	|	NOT TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	OR TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND TableOfGoods.Products.TracedGoods
	|
	|GROUP BY
	|	CASE
	|		WHEN TableOfGoods.InternalSubcontracting
	|			THEN TableOfGoods.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN &Organization
	|	END,
	|	TableOfGoods.BusinessOperation,
	|	TableOfGoods.Department,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose,
	|	CASE
	|		WHEN TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND TableOfGoods.Products.TracedGoods
	|			THEN VALUE(Enum.InventoryTypes.Work_5)
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		WHEN TRUE
	|			THEN VALUE(Enum.InventoryTypes.OwnGoods)
	|	END,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN TableOfGoods.Purpose.Partner
	|		WHEN TableOfGoods.InternalSubcontracting
	|			THEN TableOfGoods.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN &Organization
	|	END,
	|	ISNULL(TableOfGoods.Purpose.Contract.Counterparty, UNDEFINED),
	|	ISNULL(TableOfGoods.Purpose.Contract, UNDEFINED),
	|	TableOfGoods.Recipient,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.BillOfMaterials,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.DirectionOfProductionIssue,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings,
	|	TableOfGoods.RowCode,
	|	TableOfGoods.RowID,
	|	TableOfGoods.CCDNumber,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN FALSE
	|		WHEN TRUE
	|			THEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|	END,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END";
	QueryTexts.Add(PartOfTheRequestText);
	
	TaxationOfOrganization	=
		VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales;
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Date",							Date);
	Query.SetParameter("Organization",					Organization);
	Query.SetParameter("Department",					Department);
	Query.SetParameter("Currency",							Currency);
	Query.SetParameter("TaxationOfOrganization",		TaxationOfOrganization);
	Query.SetParameter("UseExcisableGoods",	UseExcisableGoods);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Result = Query.ExecuteBatchWithIntermediateData();
	
	Return Result[Result.UBound()].Unload();
	
EndFunction

// Tables for filling in the types of inventory of the product.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - temporary table Manager
// 
// Returns:
//  ValueTable - Tables to fill in types of product inventory
//
Function TableToFillInTypesOfStocksByProducts(TempTablesManager)
	
	QueryTexts = New Array;
	
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.CountryWH = True;
	
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters));
	
	PartOfTheRequestText = 
	"SELECT
	|	CASE
	|		WHEN NOT TableOfGoods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN TableOfGoods.ProductOwner
	|		WHEN TableOfGoods.InternalSubcontracting
	|			THEN TableOfGoods.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN &Organization
	|	END														AS Organization,
	|	&Currency														AS Currency,
	|	&TaxationOfOrganization									AS TaxationOfOrganization,
	|	UNDEFINED												AS Terms,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)	AS VATTaxation,
	|	TableOfGoods.BusinessOperation						AS BusinessOperation,
	|	TableOfGoods.Department								AS Department,
	|	MAX(TableOfGoods.LineNumber)						AS LineNumber,
	|	TableOfGoods.Products									AS Products,
	|	TableOfGoods.Characteristic								AS Characteristic,
	|	TableOfGoods.Purpose									AS Purpose,
	|	CASE
	|		WHEN TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND TableOfGoods.Products.TracedGoods
	|			THEN VALUE(Enum.InventoryTypes.Work_5)
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		WHEN TRUE
	|			THEN VALUE(Enum.InventoryTypes.OwnGoods)
	|	END														AS InventoryType,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN TableOfGoods.Purpose.Partner
	|		WHEN NOT TableOfGoods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN TableOfGoods.ProductOwner
	|		WHEN TRUE
	|			THEN &Organization
	|	END														AS GoodsOwner,
	|	ISNULL(TableOfGoods.Purpose.Contract.Counterparty, UNDEFINED) AS Counterparty,
	|	ISNULL(TableOfGoods.Purpose.Contract, UNDEFINED)	AS Contract,
	|	TableOfGoods.Recipient									AS Recipient,
	|	TableOfGoods.ReceivingBusinessUnit						AS ReceivingBusinessUnit,
	|	TableOfGoods.ProductCostElement							AS ProductCostElement,
	|	TableOfGoods.ProductOwner								AS ProductOwner,
	|	TableOfGoods.CostGroupNumber							AS CostGroupNumber,
	|	TableOfGoods.ItemsLocationAttributes					AS ItemsLocationAttributes,
	|	TableOfGoods.DirectionOfProductionIssue							AS DirectionOfProductionIssue,
	|	TableOfGoods.DimensionOfExpenses							AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension						AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings							AS GLAccountSettings,
	|	TableOfGoods.RowID							AS RowID,
	|	TableOfGoods.CCDNumber										AS CCDNumber,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)				AS CurViewOfStocks,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)				AS InventoryOwnerAttribute,
	|	SUM(TableOfGoods.Count)							AS Count,
	|	SUM(TableOfGoods.Sum)									AS Sum,
	|	FALSE														AS ThisIsReusablePackage,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN FALSE
	|		WHEN TRUE
	|			THEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|	END														AS SubjectToExcise,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END														AS BusinessUnitProduction
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON TableOfGoods.Products = Category_Data.Products
	|
	|WHERE
	|	NOT TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	OR TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND TableOfGoods.Products.TracedGoods
	|
	|GROUP BY
	|	CASE
	|		WHEN NOT TableOfGoods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN TableOfGoods.ProductOwner
	|		WHEN TableOfGoods.InternalSubcontracting
	|			THEN TableOfGoods.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN &Organization
	|	END,
	|	TableOfGoods.BusinessOperation,
	|	TableOfGoods.Department,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose,
	|	CASE
	|		WHEN TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND TableOfGoods.Products.TracedGoods
	|			THEN VALUE(Enum.InventoryTypes.Work_5)
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		WHEN TRUE
	|			THEN VALUE(Enum.InventoryTypes.OwnGoods)
	|	END,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN TableOfGoods.Purpose.Partner
	|		WHEN NOT TableOfGoods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN TableOfGoods.ProductOwner
	|		WHEN TRUE
	|			THEN &Organization
	|	END,
	|	ISNULL(TableOfGoods.Purpose.Contract.Counterparty, UNDEFINED),
	|	ISNULL(TableOfGoods.Purpose.Contract, UNDEFINED),
	|	TableOfGoods.Recipient,
	|	TableOfGoods.ReceivingBusinessUnit,
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.ProductOwner,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.DirectionOfProductionIssue,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings,
	|	TableOfGoods.RowID,
	|	TableOfGoods.CCDNumber,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN FALSE
	|		WHEN TRUE
	|			THEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|	END,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|					VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|					VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END
	|";
	QueryTexts.Add(PartOfTheRequestText);
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	TaxationOfOrganization	=
		VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales;
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Date",							Date);
	Query.SetParameter("Organization",					Organization);
	Query.SetParameter("Country",							RegistrationCountry);
	Query.SetParameter("Department",					Department);
	Query.SetParameter("Currency",							Currency);
	Query.SetParameter("TaxationOfOrganization",		TaxationOfOrganization);
	Query.SetParameter("UseExcisableGoods",	UseExcisableGoods);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Result = Query.ExecuteBatchWithIntermediateData();
	
	Return Result[Result.UBound()].Unload();
	
EndFunction

#EndRegion

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.BackflushProduction.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.BackflushProduction.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
#Region FillingInProductAccountingAnalyticsKeys
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.ProductsRelease,
					Department,
					Department,
					Undefined);
	
	//ManufacturedProducts
	CustomWarehouse =
	"CASE
	|	WHEN Collection.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|		THEN UNDEFINED
	|	ELSE Collection.Recipient
	|END";
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	
	FieldsNames.Insert("Purpose", "Purpose");
	FieldsNames.Insert("Series", "Series");
	FieldsNames.Insert("BatchesIndicationStatus", "BatchesIndicationStatus");
	
	FieldsNames.Insert("OwnGoods", New Structure("FieldText", CustomWarehouse));
	FieldsNames.Insert("ReusablePackage", New Structure("FieldText", CustomWarehouse));
	FieldsNames.Insert("Work_5", New Structure("FieldText", CustomWarehouse));
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(DocumentTables.ManufacturedProducts,
																	PlacesOfAccounting,
																	FieldsNames);
	
	//SideAndIntermediateRelease
	CustomWarehouse =
	"CASE
	|	WHEN Collection.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|		THEN Collection.Department
	|	ELSE Collection.Recipient
	|END";
	
	FieldsNames.Insert("OwnGoods", New Structure("FieldText", CustomWarehouse));
	FieldsNames.Insert("ReusablePackage", New Structure("FieldText", CustomWarehouse));
	FieldsNames.Insert("Work_5", New Structure("FieldText", CustomWarehouse));
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(DocumentTables.SideAndIntermediateRelease,
																	PlacesOfAccounting,
																	FieldsNames);
	
	//MaterialsAndWorks
	FieldsNames.Insert("OwnGoods", "Warehouse");
	FieldsNames.Insert("ReusablePackage", "Warehouse");
	FieldsNames.Insert("Work_5", "Department");
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(DocumentTables.MaterialsAndWorks,
																	PlacesOfAccounting,
																	FieldsNames);
	
#EndRegion
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Date          = CurrentSessionDate();
	Author = Users.CurrentUser();
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	PriceKind       = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory(PriceKind);
	PriceCurrency    = Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind).PriceCurrency;
	Currency        = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(PriceCurrency);
	GroupCosts = ?(ValueIsFilled(GroupCosts), GroupCosts, Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified);
	
	ReferenceOrderForLaborCosts = True;
	
	// If this is a correction, then the Correction flag saves the production party inherited from the document being corrected.
	// If not, then set this flag to True for all new documents.
	If Not Patch Then
		CorrectionSavesProductionLots = True;
	EndIf;
	
	FillParameters = Documents.BackflushProduction.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(ProductionIssueForActivity, FillParameters);
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckCOSTShares(Cancel)
	
	PresentationOfTS = Metadata().TabularSections.ManufacturedProducts.Synonym;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TableOfGoods.CostGroupNumber	AS CostGroupNumber,
		|	TableOfGoods.LineNumber			AS LineNumber,
		|	TableOfGoods.Products			AS Products,
		|	TableOfGoods.Characteristic		AS Characteristic,
		|	TableOfGoods.CostShare		AS CostShare
		|INTO TableOfGoods
		|FROM
		|	&TableOfGoods AS TableOfGoods
		|WHERE
		|	NOT &GroupCosts IN(
		|			VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProducts),
		|			VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments),
		|			VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches),
		|			VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches))
		|	OR &Patch
		|		AND &CorrectionSavesProductionLots
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfGoods.CostGroupNumber AS CostGroupNumber,
		|	COUNT(DISTINCT TableOfGoods.Products) AS QuantityProducts,
		|	COUNT(DISTINCT TableOfGoods.Characteristic) AS QuantityCharacteristic,
		|	COUNT(DISTINCT TableOfGoods.CostShare) AS QuantityShareOfCost
		|INTO ResultsForCostGroup
		|FROM
		|	TableOfGoods AS TableOfGoods
		|
		|GROUP BY
		|	TableOfGoods.CostGroupNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfGoods.LineNumber AS LineNumber
		|FROM
		|	TableOfGoods AS TableOfGoods
		|		INNER JOIN ResultsForCostGroup AS ResultsForCostGroup
		|		ON TableOfGoods.CostGroupNumber = ResultsForCostGroup.CostGroupNumber
		|WHERE
		|	TableOfGoods.CostShare = 0
		|	AND (ResultsForCostGroup.QuantityProducts > 1
		|	OR ResultsForCostGroup.QuantityCharacteristic > 1
		|	OR ResultsForCostGroup.QuantityShareOfCost > 1)";
	
	Query.SetParameter("TableOfGoods",                         ManufacturedProducts.Unload());
	Query.SetParameter("GroupCosts",                      GroupCosts);
	Query.SetParameter("Patch",                            Patch);
	Query.SetParameter("CorrectionSavesProductionLots", CorrectionSavesProductionLots);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Trong dòng %LineNumber% của danh sách %PresentationOfTS% không có phần nào của giá trị được chỉ định.';
							|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" не указана доля стоимости.';
							|en = 'Cost share is not specified in line %LineNumber% of the ""%PresentationOfTS%"" list.'; fa = 'Cost share is not specified in line %LineNumber% of the ""%PresentationOfTS%"" list.';
							|it = 'Nella riga %LineNumber% dell''elenco ""%PresentationOfTS%"" non è specificata la parte del costo.';
							|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" nie jest podane przeznaczenie.';
							|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında maliyet payı belirtilmedi.'");
		
		MessageText = StrReplace(MessageText, "%LineNumber%", Selection.LineNumber);
		MessageText = StrReplace(MessageText, "%PresentationOfTS%", PresentationOfTS);
		
		Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", Selection.LineNumber, "CostShare");
		
		Common.MessageToUser(MessageText, ThisObject , Field,, Cancel);
		
	EndDo;
	
EndProcedure

Procedure CheckAssignmentCompletion(Cancel)
	
	PresentationOfTS = Metadata().TabularSections.ManufacturedProducts.Synonym;
	
	For Each CurProduct In ManufacturedProducts Do
		If (GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments
				Or GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches
				Or GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments)
			And Not ValueIsFilled(CurProduct.Purpose)
			And Not CurProduct.DirectionOfProductionIssue = Enums.BusinessTransactions.GoodsConsumptionOnDemand Then
			
			MessageText = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""%PresentationOfTS%"", giá trị không được điền.';
								|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" не заполнено назначение.';
								|en = 'Assignment is required in line %LineNumber% of the ""%PresentationOfTS%"" list.'; fa = 'Assignment is required in line %LineNumber% of the ""%PresentationOfTS%"" list.';
								|it = 'Nella riga %LineNumber% dell''elenco ""%PresentationOfTS%"" non è compilata la destinazione.';
								|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" nie jest podane przeznaczenie.';
								|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında atama doldurulmadı.'");
			MessageText = StrReplace(MessageText, "%LineNumber%", CurProduct.LineNumber);
			MessageText = StrReplace(MessageText, "%PresentationOfTS%", PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurProduct.LineNumber, "Purpose");
			
			Common.MessageToUser(MessageText, ThisObject , Field,, Cancel);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckWarehouses(Cancel)
	
	PresentationOfTS = Metadata().TabularSections.MaterialsAndWorks.Synonym;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TableOfGoods.LineNumber AS LineNumber,
		|	TableOfGoods.Warehouse AS Warehouse,
		|	TableOfGoods.Products AS Products
		|INTO TableOfGoods
		|FROM
		|	&TableOfGoods AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfGoods.LineNumber
		|FROM
		|	TableOfGoods AS TableOfGoods
		|	LEFT JOIN Catalog.Products AS CatProducts
		|	ON CatProducts.Ref = TableOfGoods.Products
		|WHERE
		|	TableOfGoods.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|	AND NOT CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	Query.SetParameter("TableOfGoods", MaterialsAndWorks.Unload(, "LineNumber, Warehouse, Products"));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""%PresentationOfTS%"", kho không được chỉ định.';
							|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" не указан склад.';
							|en = 'Warehouse is not specified in line %LineNumber% of the ""%PresentationOfTS%"" list.'; fa = 'Warehouse is not specified in line %LineNumber% of the ""%PresentationOfTS%"" list.';
							|it = 'Nella riga %LineNumber% dell''elenco ""%PresentationOfTS%"" non è specificato il magazzino.';
							|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" nie jest podany magazyn.';
							|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında ambar belirtilmedi.'");
		
		MessageText = StrReplace(MessageText, "%LineNumber%", Selection.LineNumber);
		MessageText = StrReplace(MessageText, "%PresentationOfTS%", PresentationOfTS);
		
		Field = CommonClientServer.PathToTabularSection("MaterialsAndWorks", Selection.LineNumber, "Warehouse");
		
		Common.MessageToUser(MessageText, ThisObject , Field,, Cancel);
		
	EndDo;
	
EndProcedure

Procedure CheckWhetherCostsAreLinkedToCostGroups(Cancel)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ManufacturedProducts.LineNumber       AS LineNumber,
	|	ManufacturedProducts.CostGroupNumber AS CostGroupNumber
	|INTO TTOutputProducts
	|FROM
	|	&ManufacturedProducts AS ManufacturedProducts
	|
	|INDEX BY
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SideAndIntermediateRelease.LineNumber       AS LineNumber,
	|	SideAndIntermediateRelease.CostGroupNumber AS CostGroupNumber
	|INTO TTByProducts
	|FROM
	|	&SideAndIntermediateRelease AS SideAndIntermediateRelease
	|
	|INDEX BY
	|	CostGroupNumber
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialsAndWorks.LineNumber       AS LineNumber,
	|	MaterialsAndWorks.CostGroupNumber AS CostGroupNumber
	|INTO TTMaterialsAndWorks
	|FROM
	|	&MaterialsAndWorks AS MaterialsAndWorks
	|
	|INDEX BY
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LaborCosts.LineNumber       AS LineNumber,
	|	LaborCosts.CostGroupNumber AS CostGroupNumber
	|INTO TTLaborCosts
	|FROM
	|	&LaborCosts AS LaborCosts
	|
	|INDEX BY
	|	CostGroupNumber
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&NameTSByProducts           AS TSName,
	|	&PresentationOfTSByProducts AS PresentationOfTS,
	|	SideAndIntermediateRelease.LineNumber     AS LineNumber,
	|	TRUE                          AS ThereIsNoCostGroup
	|
	|FROM
	|	TTByProducts AS SideAndIntermediateRelease
	|	
	|	LEFT JOIN TTOutputProducts AS ManufacturedProducts
	|	ON ManufacturedProducts.CostGroupNumber = SideAndIntermediateRelease.CostGroupNumber
	|
	|WHERE
	|	ManufacturedProducts.CostGroupNumber IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	&NameTSMaterialsAndWorks           AS TSName,
	|	&PresentationOfTSMaterialsAndWorks AS PresentationOfTS,
	|	MaterialsAndWorks.LineNumber     AS LineNumber,
	|	TRUE                           AS ThereIsNoCostGroup
	|FROM
	|	TTMaterialsAndWorks AS MaterialsAndWorks
	|	
	|	LEFT JOIN TTOutputProducts AS ManufacturedProducts
	|	ON ManufacturedProducts.CostGroupNumber = MaterialsAndWorks.CostGroupNumber
	|
	|WHERE
	|	ManufacturedProducts.CostGroupNumber IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	&NameTSLaborCosts           AS TSName,
	|	&PresentationOfTSLaborCosts AS PresentationOfTS,
	|	LaborCosts.LineNumber     AS LineNumber,
	|	TRUE                       AS ThereIsNoCostGroup
	|FROM
	|	TTLaborCosts AS LaborCosts
	|	
	|	LEFT JOIN TTOutputProducts AS ManufacturedProducts
	|	ON ManufacturedProducts.CostGroupNumber = LaborCosts.CostGroupNumber
	|
	|WHERE
	|	ManufacturedProducts.CostGroupNumber IS NULL
	|";
	
	Query.SetParameter("GroupCosts", GroupCosts);
	Query.SetParameter("ManufacturedProducts",   ManufacturedProducts.Unload(,  "LineNumber, CostGroupNumber"));
	Query.SetParameter("SideAndIntermediateRelease",   SideAndIntermediateRelease.Unload(,  "LineNumber, CostGroupNumber"));
	Query.SetParameter("MaterialsAndWorks",  MaterialsAndWorks.Unload(, "LineNumber, CostGroupNumber"));
	Query.SetParameter("LaborCosts",      LaborCosts.Unload(,     "LineNumber, CostGroupNumber"));
	
	DescriptionOfTS = Metadata().TabularSections;
	
	Query.SetParameter("NameTSByProducts",  DescriptionOfTS.SideAndIntermediateRelease.Name);
	Query.SetParameter("NameTSMaterialsAndWorks", DescriptionOfTS.MaterialsAndWorks.Name);
	Query.SetParameter("NameTSLaborCosts",     DescriptionOfTS.LaborCosts.Name);
	
	Query.SetParameter("PresentationOfTSByProducts",  DescriptionOfTS.SideAndIntermediateRelease.Synonym);
	Query.SetParameter("PresentationOfTSMaterialsAndWorks", DescriptionOfTS.MaterialsAndWorks.Synonym);
	Query.SetParameter("PresentationOfTSLaborCosts",     DescriptionOfTS.LaborCosts.Synonym);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.ThereIsNoCostGroup Then
			
			MessageText = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""%PresentationOfTS%"" đã chỉ ra nhóm chi phí không tồn tại trong chứng từ.';
								|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" указана группа затрат, несуществующая в документе.';
								|en = 'Line %LineNumber% of ""%PresentationOfTS%"" list contains a cost group absent in the document.'; fa = 'Line %LineNumber% of ""%PresentationOfTS%"" list contains a cost group absent in the document.';
								|it = 'Nella riga %LineNumber% dell''elenco ""%PresentationOfTS%"" è indicato il gruppo di spese inesistente nel documento.';
								|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" podana jest grupa kosztów, która nie istnieje w dokumencie.';
								|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında belgede olmayan bir maliyet grubu belirtildi.'");
			MessageText = StrReplace(MessageText, "%LineNumber%", Selection.LineNumber);
			MessageText = StrReplace(MessageText, "%PresentationOfTS%", Selection.PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(Selection.TSName, Selection.LineNumber, "ExpenseGroup");
			
			Common.MessageToUser(MessageText, ThisObject , Field,, Cancel);
		
		EndIf;
		
	EndDo;
	
EndProcedure
Procedure CheckFieldsOfInternalProcessing(NotCheckedAttributeArray, Cancel)
	
	If Not InternalSubcontracting Then
		NotCheckedAttributeArray.Add("MaterialProviderCompany");
	EndIf;
	
	If InternalSubcontracting Then
	
		If ValueIsFilled(MaterialProviderCompany)
			And MaterialProviderCompany = Organization Then
			
			MessageText = NStr("vi = 'Doanh nghiệp-người đặt gia công trùng với doanh nghiệp-người nhận gia công.';
								|ru = 'Организация-давалец совпадает с организацией-переработчиком.';
								|en = 'Material provider company and the subcontractor company are the same.'; fa = 'Material provider company and the subcontractor company are the same.';
								|it = 'Организация-давалец совпадает с организацией-переработчиком.';
								|pl = 'Material provider company and the subcontractor company are the same.';
								|tr = 'Tedarikçi iş yeri, fason üretici iş yeri ile aynıdır.'");
			Common.MessageToUser(MessageText, ThisObject, "MaterialProviderCompany",, Cancel);
			
		EndIf;
		
		If ValueIsFilled(MaterialProviderCompany)
			And Not MaterialProviderCompany = Organization
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Organization, MaterialProviderCompany) Then
			
			MessageText = NStr("vi = 'Doanh nghiệp đặt gia công không được phép có quan hệ với doanh nghiệp nhận gia công theo cấu trúc tổ chức.';
								|ru = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
								|en = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.'; fa = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
								|it = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
								|pl = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
								|tr = 'Tedarikçi iş yeri, iş yeri yapısı bakımından fason üretici iş yeri ile bağlantılı olmamalıdır.'");
			Common.MessageToUser(MessageText, ThisObject, "MaterialProviderCompany",, Cancel);
			
		EndIf;
		
		CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Organization, MaterialProviderCompany);
		
		If Not CheckStructure.CurrenciesDoNotMatch Then
			MessageText = NStr("vi = 'Tiền tệ của kế toán tài chính ""%1"" và ""%2"" cần trùng nhau.';
								|ru = 'Валюты регламентированного учета ""%1"" и ""%2"" должны совпадать.';
								|en = 'The %1 and %2 local accounting currencies must be the same.'; fa = 'The %1 and %2 local accounting currencies must be the same.';
								|it = 'Валюты регламентированного учета ""%1"" и ""%2"" должны совпадать.';
								|pl = 'The %1 and %2 local accounting currencies must be the same.';
								|tr = '""%1"" ve ""%2"" yerel muhasebe para birimleri eşleşmelidir.'");
			MessageText = StrTemplate(MessageText, Organization, MaterialProviderCompany);
			Common.MessageToUser(MessageText, ThisObject, "MaterialProviderCompany",, Cancel);
		EndIf;
		
		If Not CheckStructure.CountriesMatch Then
			MessageText = NStr("vi = 'Trang đăng ký ""%1"" và ""%2"" phải trùng nhau.';
								|ru = 'Страны регистрации ""%1"" и ""%2"" должны совпадать.';
								|en = 'The %1 and %2 countries of residence must be the same.'; fa = 'The %1 and %2 countries of residence must be the same.';
								|it = 'Страны регистрации ""%1"" и ""%2"" должны совпадать.';
								|pl = 'The %1 and %2 countries of residence must be the same.';
								|tr = '""%1"" ve ""%2"" kayıt ülkeleri eşleşmelidir.'");
			MessageText = StrTemplate(MessageText, Organization, MaterialProviderCompany);
			Common.MessageToUser(MessageText, ThisObject, "MaterialProviderCompany",, Cancel);
		EndIf;
		
	EndIf;
	
	NotCheckedAttributeArray.Add("ManufacturedProducts.MaterialProviderCompany");
	NotCheckedAttributeArray.Add("SideAndIntermediateRelease.ProductOwner");
	
	InternalProcessingGroups = New Map;
	
	For Each CurrentData In ManufacturedProducts Do
		
		If CurrentData.InternalSubcontracting Then
			
			InternalProcessingGroups.Insert(CurrentData.CostGroupNumber);
			
			If Not ValueIsFilled(CurrentData.MaterialProviderCompany) Then
				
				MessageText = NStr("vi = 'Trong dòng %1 của danh sách ""Sản phẩm"" chưa điền doanh nghiệp đặt gia công.';
									|ru = 'В строке %1 списка ""Продукция"" не заполнена организация-давалец.';
									|en = 'In line %1 of the ""Products"" list, the material provider company is required.'; fa = 'In line %1 of the ""Products"" list, the material provider company is required.';
									|it = 'В строке %1 списка ""Продукция"" не заполнена организация-давалец.';
									|pl = 'In line %1 of the ""Products"" list, the material provider company is required.';
									|tr = '""İmal edilen ürünler"" listesinin %1 satırında tedarikçi iş yeri doldurulmadı.'");
				MessageText = StrTemplate(MessageText, CurrentData.LineNumber);
				
				Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurrentData.LineNumber, "MaterialProviderCompany");
				
				Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
				
			EndIf;
			
			If Not InternalSubcontracting Then
				
				If ValueIsFilled(CurrentData.MaterialProviderCompany)
					And CurrentData.MaterialProviderCompany = Organization Then
					
					MessageText = NStr("vi = 'Trong dòng %1 của danh sách ""Sản phẩm"" doanh nghiệp đặt gia công trùng với doanh nghiệp nhận gia công.';
										|ru = 'В строке %1 списка ""Продукция"" организация-давалец совпадает с организацией-переработчиком.';
										|en = 'In line %1 of the Products list, the material provider company and the subcontractor company are the same.'; fa = 'In line %1 of the Products list, the material provider company and the subcontractor company are the same.';
										|it = 'В строке %1 списка ""Продукция"" организация-давалец совпадает с организацией-переработчиком.';
										|pl = 'In line %1 of the Products list, the material provider company and the subcontractor company are the same.';
										|tr = '""İmal edilen ürünler"" listesin %1 satırında, tedarikçi iş yeri ile fason üretici iş yeri aynıdır.'");
					MessageText = StrTemplate(MessageText, CurrentData.LineNumber);
					
					Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurrentData.LineNumber, "MaterialProviderCompany");
					
					Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
					
				EndIf;
				
				If ValueIsFilled(CurrentData.MaterialProviderCompany)
					And Not CurrentData.MaterialProviderCompany = Organization
					And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Organization, CurrentData.MaterialProviderCompany) Then
					
					MessageText = NStr("vi = 'Trong dòng %1 của danh sách ""Sản phẩm"", doanh nghiệp đặt gia công có quan hệ với doanh nghiệp nhận gia công về cơ cấu tổ chức.';
										|ru = 'В строке %1 списка ""Продукция"" организация-давалец взаимосвязана с организацией-переработчиком по организационной структуре.';
										|en = 'In line %1 of the Products list, the material provider company is interrelated to the subcontractor company by the organizational structure.'; fa = 'In line %1 of the Products list, the material provider company is interrelated to the subcontractor company by the organizational structure.';
										|it = 'В строке %1 списка ""Продукция"" организация-давалец взаимосвязана с организацией-переработчиком по организационной структуре.';
										|pl = 'In line %1 of the Products list, the material provider company is interrelated to the subcontractor company by the organizational structure.';
										|tr = '""İmal edilen ürünler"" listesinin %1 satırında, tedarikçi iş yeri iş yeri yapısı bakımından fason üretici iş yeri ile bağlantılıdır.'");
					MessageText = StrTemplate(MessageText, CurrentData.LineNumber);
					
					Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurrentData.LineNumber, "MaterialProviderCompany");
					
					Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
					
				EndIf;
				
				CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Organization, CurrentData.MaterialProviderCompany);
				
				If Not CheckStructure.CurrenciesDoNotMatch Then
					
					MessageText = NStr("vi = 'Tiền tệ của kế toán tài chính ""%1"" và ""%2"" cần trùng nhau.';
										|ru = 'Валюты регламентированного учета ""%1"" и ""%2"" должны совпадать.';
										|en = 'The %1 and %2 local accounting currencies must be the same.'; fa = 'The %1 and %2 local accounting currencies must be the same.';
										|it = 'Валюты регламентированного учета ""%1"" и ""%2"" должны совпадать.';
										|pl = 'The %1 and %2 local accounting currencies must be the same.';
										|tr = '""%1"" ve ""%2"" yerel muhasebe para birimleri eşleşmelidir.'");
					MessageText = StrTemplate(MessageText, Organization, CurrentData.MaterialProviderCompany);
					
					Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurrentData.LineNumber, "MaterialProviderCompany");
					Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
					
				EndIf;
				
				If Not CheckStructure.CountriesMatch Then
					
					MessageText = NStr("vi = 'Trang đăng ký ""%1"" và ""%2"" phải trùng nhau.';
										|ru = 'Страны регистрации ""%1"" и ""%2"" должны совпадать.';
										|en = 'The %1 and %2 countries of residence must be the same.'; fa = 'The %1 and %2 countries of residence must be the same.';
										|it = 'Страны регистрации ""%1"" и ""%2"" должны совпадать.';
										|pl = 'The %1 and %2 countries of residence must be the same.';
										|tr = '""%1"" ve ""%2"" kayıt ülkeleri eşleşmelidir.'");
					MessageText = StrTemplate(MessageText, Organization, CurrentData.MaterialProviderCompany);
					
					Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurrentData.LineNumber, "MaterialProviderCompany");
					Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Assignments = SideAndIntermediateRelease.UnloadColumn("Purpose");
	Assignments = CommonClientServer.CollapseArray(Assignments);
	AssignmentProperties = Catalogs.Assignments.AssignmentProperties(Assignments);
	
	For Each CurrentData In SideAndIntermediateRelease Do
		
		DestinationProperties = AssignmentProperties.Get(CurrentData.Purpose);
		If Not InternalProcessingGroups.Get(CurrentData.CostGroupNumber) = Undefined
			And (DestinationProperties = Undefined
				Or Not DestinationProperties.ThisIsAppointmentOfGiver2_5
					And True)
			And Not ValueIsFilled(CurrentData.ProductOwner) Then
			
			MessageText = NStr("vi = 'Trong dòng %1 của danh sách ""Sản phẩm phụ và xuất xưởng trung gian"" chưa điền đối tượng chủ của sản phẩm.';
								|ru = 'В строке %1 списка ""Побочный и промежуточный выпуск"" не заполнен владелец изделия.';
								|en = 'In line %1 of the ""Side and intermediate release"" list, the product owner is required.'; fa = 'In line %1 of the ""Side and intermediate release"" list, the product owner is required.';
								|it = 'В строке %1 списка ""Побочный и промежуточный выпуск"" не заполнен владелец изделия.';
								|pl = 'In line %1 of the ""Side and intermediate release"" list, the product owner is required.';
								|tr = '""Ara ve yan ürün çıkışı"" listesinin %1 satırında nihai ürünün sahibi doldurulmadı.'");
			MessageText = StrTemplate(MessageText, CurrentData.LineNumber);
			
			Field = CommonClientServer.PathToTabularSection("SideAndIntermediateRelease", CurrentData.LineNumber, "ProductOwner");
			
			Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure
Procedure CheckCorrectnessOfIndicationOfExcisableItems(Cancel)
	
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	If Not UseExcisableGoods Then
		Return;
	EndIf;
	
	QueryTexts = New Array;
	
	PartOfTheRequestText = 
	"SELECT
	|	&NameOfTSOutputProducts		AS TSName,
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.Products	AS Products,
	|	TableOfGoods.Purpose	AS Purpose,
	|	CASE
	|		WHEN TableOfGoods.InternalSubcontracting
	|			THEN TableOfGoods.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN &Organization
	|	END						AS Organization,
	|	TableOfGoods.Recipient	AS Recipient
	|INTO TTOutputProducts
	|FROM
	|	&ManufacturedProducts AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&NameTSByProducts		AS TSName,
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.Products	AS Products,
	|	TableOfGoods.Purpose	AS Purpose,
	|	CASE
	|		WHEN TableOfGoods.ProductOwner <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN TableOfGoods.ProductOwner
	|		WHEN TRUE
	|			THEN &Organization
	|	END						AS Organization,
	|	TableOfGoods.Recipient	AS Recipient
	|INTO TTByProducts
	|FROM
	|	&SideAndIntermediateRelease AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.TSName		AS TSName,
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.Products	AS Products,
	|	TableOfGoods.Organization	AS Organization,
	|	TableOfGoods.Recipient	AS Recipient,
	|	ManufacturersOfExcisableItems.Country AS Country,
	|	ISNULL(ManufacturersOfExcisableItems.ProducesExcisableGoods, FALSE) AS ProducesExcisableGoods
	|INTO TableOfGoods
	|FROM
	|	TTOutputProducts AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.Assignments AS CatalogAssignments
	|		ON TableOfGoods.Purpose = CatalogAssignments.Ref
	|		
	|		LEFT JOIN TTManufacturersOfExcisableItems AS ManufacturersOfExcisableItems
	|		ON TableOfGoods.Organization = ManufacturersOfExcisableItems.Organization
	|
	|WHERE
	|	CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND NOT (ISNULL(CatalogAssignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.TSName		AS TSName,
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.Products	AS Products,
	|	TableOfGoods.Organization	AS Organization,
	|	TableOfGoods.Recipient	AS Recipient,
	|	ManufacturersOfExcisableItems.Country AS Country,
	|	ISNULL(ManufacturersOfExcisableItems.ProducesExcisableGoods, FALSE) AS ProducesExcisableGoods
	|FROM
	|	TTByProducts AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.Assignments AS CatalogAssignments
	|		ON TableOfGoods.Purpose = CatalogAssignments.Ref
	|		
	|		LEFT JOIN TTManufacturersOfExcisableItems AS ManufacturersOfExcisableItems
	|		ON TableOfGoods.Organization = ManufacturersOfExcisableItems.Organization
	|
	|WHERE
	|	CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND NOT (ISNULL(CatalogAssignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|	)
	|
	|INDEX BY
	|	Products,
	|	Country";
	QueryTexts.Add(PartOfTheRequestText);
	
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.CountryWH = True;
	
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters));
	
	PartOfTheRequestText = 
	"SELECT
	|	ErrorsTable.TSName						AS TSName,
	|	ErrorsTable.LineNumber				AS LineNumber,
	|	ErrorsTable.Organization				AS Organization,
	|	ErrorsTable.ExcisableItemIsSpecified	AS ExcisableItemIsSpecified,
	|	ErrorsTable.RetailWarehouseIsSpecified		AS RetailWarehouseIsSpecified
	|FROM
	|	(SELECT
	|		TableOfGoods.TSName		AS TSName,
	|		TableOfGoods.LineNumber	AS LineNumber,
	|		TableOfGoods.Organization	AS Organization,
	|		CASE
	|			WHEN NOT TableOfGoods.ProducesExcisableGoods
	|					AND ISNULL(Category_Data.ExcisableGoods, FALSE)
	|				THEN TRUE
	|			ELSE FALSE
	|		END						AS ExcisableItemIsSpecified,
	|		CASE
	|			WHEN TableOfGoods.ProducesExcisableGoods
	|					AND ISNULL(Category_Data.ExcisableGoods, FALSE)
	|					AND ISNULL(CatalogWarehouses.WarehouseStore, UNDEFINED) = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|				THEN TRUE
	|			ELSE FALSE
	|		END						AS RetailWarehouseIsSpecified
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|			LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|			ON TableOfGoods.Products = Category_Data.Products
	|				AND TableOfGoods.Country = Category_Data.Country
	|			
	|			LEFT JOIN Catalog.Warehouses AS CatalogWarehouses
	|			ON TableOfGoods.Recipient = CatalogWarehouses.Ref
	|	
	|	) AS ErrorsTable
	|
	|WHERE
	|	(ErrorsTable.ExcisableItemIsSpecified
	|		OR ErrorsTable.RetailWarehouseIsSpecified
	|	)
	|
	|ORDER BY
	|	TSName = &NameOfTSOutputProducts,
	|	LineNumber";
	QueryTexts.Add(PartOfTheRequestText);
	
	UseInternalSubcontracting = False;
	UseInternalSubcontracting = GetFunctionalOption("UseInternalSubcontracting");
	TempTablesManager = New TempTablesManager;
	ExcisableGoodsAccounting.ManufacturersOfExcisableItems(ThisObject,
															TempTablesManager,
															UseInternalSubcontracting);
	
	TabularSectionsDetails = Metadata().TabularSections;
	
	UnloadedColumns =
		"LineNumber,
		|Purpose,
		|Products,
		|Recipient";
	
	ColumnsOutputProducts = UnloadedColumns;
	ColumnsByProducts = UnloadedColumns;
	ColumnsOutputProducts = UnloadedColumns + ", InternalSubcontracting, MaterialProviderCompany";
	ColumnsByProducts = UnloadedColumns + ", ProductOwner";
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Date",					Date);
	Query.SetParameter("Organization",			Organization);
	Query.SetParameter("NameOfTSOutputProducts",	TabularSectionsDetails.ManufacturedProducts.Name);
	Query.SetParameter("NameTSByProducts",	TabularSectionsDetails.SideAndIntermediateRelease.Name);
	Query.SetParameter("ManufacturedProducts",		ManufacturedProducts.Unload(, ColumnsOutputProducts));
	Query.SetParameter("SideAndIntermediateRelease",		SideAndIntermediateRelease.Unload(, ColumnsByProducts));
	Query.SetParameter("UseExcisableGoods",
								UseExcisableGoods);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	MessageTemplateIndicatesExcisableItem = NStr("vi = 'Trong dòng %1 danh sách ""%2"" có chỉ định sản phẩm chịu thuế TTĐB.
		|Cấm chọn mặt hàng này, vì chính sách kế toán tài chính của doanh nghiệp ""%3"" không cho phép sản xuất sản phẩm chịu thuế TTĐB.';
		|ru = 'В строке %1 списка ""%2"" указана подакцизная продукция.
		|Выбор такой номенклатуры запрещен, так как учетная политика финансового учета организации ""%3"" не предусматривает производство подакцизной продукции.';
		|en = 'Excisable products are specified in line %1 of the ""%2"" list.
		|Cannot select this item, as the financial accounting policy of the ""%3"" company does not allow producing excisable products.'; fa = 'Excisable products are specified in line %1 of the ""%2"" list.
		|Cannot select this item, as the financial accounting policy of the ""%3"" company does not allow producing excisable products.';
		|it = 'Excisable products are specified in line %1 of the ""%2"" list.
		|Cannot select this item, as the financial accounting policy of the ""%3"" company does not allow producing excisable products.';
		|pl = 'Excisable products are specified in line %1 of the ""%2"" list.
		|Cannot select this item, as the financial accounting policy of the ""%3"" company does not allow producing excisable products.';
		|tr = '""%2"" listesinin %1 satırında tüketim vergisine tabi imal edilen ürünler belirtildi.
		|""%3"" iş yerinin mali muhasebe bölümünün muhasebe politikasında tüketim vergisine tabi ürünlerin üretimi öngörülmediğinden, bu tür bir öğenin seçilmesi yasaktır.'");
	
	MessageTemplateIndicatesRetailWarehouse = NStr("vi = 'Trong dòng %1 danh sách ""%2"" có chỉ định kho bán lẻ là nơi nhận.
		|Cấm xuất xưởng sản phẩm chịu thuế TTĐB vào kho bán lẻ.';
		|ru = 'В строке %1 списка ""%2"" в качестве получателя указан розничный склад.
		|Выпуск подакцизной продукции на розничный склад запрещен.';
		|en = 'In line %1 of the ""%2"" list, the recipient is a retail warehouse.
		|Cannot release excisable goods to a retail warehouse.'; fa = 'In line %1 of the ""%2"" list, the recipient is a retail warehouse.
		|Cannot release excisable goods to a retail warehouse.';
		|it = 'In line %1 of the ""%2"" list, the recipient is a retail warehouse.
		|Cannot release excisable goods to a retail warehouse.';
		|pl = 'In line %1 of the ""%2"" list, the recipient is a retail warehouse.
		|Cannot release excisable goods to a retail warehouse.';
		|tr = '""%2"" listesinin %1 satırında alıcı olarak perakende ambarı belirtildi.
		|Tüketim vergisine tabi imal edilen ürünlerin perakende ambarına verilmesi yasaktır.'");
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		FieldName			= "";
		MessageText	= "";
		
		If Selection.ExcisableItemIsSpecified Then
			FieldName			= "Products";
			MessageText	= StrTemplate(MessageTemplateIndicatesExcisableItem,
										Selection.LineNumber,
										TabularSectionsDetails[Selection.TSName].Synonym,
										Selection.Organization);
		ElsIf Selection.RetailWarehouseIsSpecified Then
			FieldName			= "Recipient";
			MessageText	= StrTemplate(MessageTemplateIndicatesRetailWarehouse,
										Selection.LineNumber,
										TabularSectionsDetails[Selection.TSName].Synonym);
		EndIf;
		
		If Not IsBlankString(MessageText) Then
			Field = CommonClientServer.PathToTabularSection(Selection.TSName, Selection.LineNumber, FieldName);
			
			Common.MessageToUser(MessageText, ThisObject , Field, "", Cancel);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.ProductionLots", "DeletionMark");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
#EndIf
