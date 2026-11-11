#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ProductionCostAllocation);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	FillNumberToDistributionOfSeriesByRule();
	
	AnalyticsParameters = New Structure("Products,Characteristic,Series,Warehouse,ProductCostElement,Purpose");
	FillPropertyValues(AnalyticsParameters, ThisObject, , "ProductCostElement");
	
	ItemsType = Common.ObjectAttributeValue(Products, "ItemsType");
	If Not NewProduction Or ItemsType = Enums.ItemsTypes.Work_5 Then
		AnalyticsParameters.Warehouse = ThisObject.Department;
	EndIf;
	
	ItemsLocationAttributes = InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(AnalyticsParameters);
	
	StageQuantityManually = ProductionLots.Total("Count");
	QuantityForExpenseItems = OtherExpenses.Total("Count");
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "OtherExpenses,ProductionLots,InventoryKinds");
	
	FillInRecipientProductTrackingAnalysis();
	
	If NewProduction Then
		If WriteMode = DocumentWriteMode.Posting Then
			FillStockTypes(Cancel);
		ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	ProductionCostAllocationLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.ProductionCostAllocation.AccountingAccountSettings_());
	
	IncomeAndExpensesServer.BeforeWrite(ThisObject, 
		Documents.ProductionCostAllocation.ItemsAndDimensionsSelectionParameters());
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf; 
	
	EmployeeResponsible = Users.CurrentUser();
	
	ProductionCostAllocationLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	IncomeAndExpensesServer.Filling(ThisObject, 
		Documents.ProductionCostAllocation.ItemsAndDimensionsSelectionParameters());
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If NewProduction Then
		CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	EndIf;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "ProductionIssueWithoutReferences";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel, CheckParameters);
	
	If GetFunctionalOption("UseItemVariants")
		And Not Catalogs.Products.ItemVariantsAreUsed(Products) Then
		NotCheckedAttributeArray.Add("Characteristic");
	EndIf;
	
	If QuantityToAllocateAccordingToRule = 0 Then
		NotCheckedAttributeArray.Add("AllocatedAccordingToRule");
		NotCheckedAttributeArray.Add("ProductCostElement");
	EndIf;
	If QuantityToAllocateAccordingToRule <> 0 And Not ValueIsFilled(AllocatedAccordingToRule) Then
		NotCheckedAttributeArray.Add("ProductCostElement");
	EndIf;
	
	NotCheckedAttributeArray.Add("Warehouse");
	If ValueIsFilled(Purpose) Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ProductionLots.LineNumber AS LineNumber,
		|	ProductionLots.ProductionLot AS ProductionLot
		|INTO ProductionBatchesArePreliminary
		|FROM
		|	&ProductionLots AS ProductionLots
		|
		|INDEX BY
		|	ProductionLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductionLots.LineNumber,
		|	CASE
		|		WHEN ISNULL(ProductionLots.ProductionLot.Purpose.AssignmentType,
		|				VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
		|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
		|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
		|			THEN TRUE
		|		WHEN NOT ISNULL(OrderDocument.Partner, VALUE(Catalog.Partners.EmptyRef)) = VALUE(Catalog.Partners.EmptyRef)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS Giveaway,
		|	CASE
		|		WHEN NOT ProductionLots.ProductionLot.Purpose.Partner IS NULL
		|			THEN ProductionLots.ProductionLot.Purpose.Partner
		|		WHEN NOT ISNULL(OrderDocument.Partner, VALUE(Catalog.Partners.EmptyRef)) = VALUE(Catalog.Partners.EmptyRef)
		|			THEN OrderDocument.Partner
		|		ELSE VALUE(Catalog.Partners.EmptyRef)
		|	END AS MaterialProvider
		|
		|INTO ProductionLots
		|FROM
		|	ProductionBatchesArePreliminary AS ProductionLots
		|
		|	LEFT JOIN Document.ProductionOrder2_2 AS OrderDocument
		|	ON OrderDocument.Ref = ProductionLots.ProductionLot.Document
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductionLots.LineNumber AS LineNumber
		|FROM
		|	ProductionLots AS ProductionLots
		|	
		|	INNER JOIN Catalog.Assignments AS CatAssignments
		|	ON CatAssignments.Ref = &Purpose
		|	AND CatAssignments.AssignmentType IN(
		|			VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
		|			VALUE(Enum.AssignmentTypes.Giveaway2_5))
		|WHERE
		|	NOT ProductionLots.Giveaway
		|
		|UNION ALL
		|
		|SELECT
		|	ProductionLots.LineNumber AS LineNumber
		|FROM
		|	ProductionLots AS ProductionLots
		|	
		|	INNER JOIN Catalog.Assignments AS CatAssignments
		|	ON CatAssignments.Ref = &Purpose
		|	AND CatAssignments.AssignmentType IN(
		|			VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
		|			VALUE(Enum.AssignmentTypes.Giveaway2_5))
		|WHERE
		|	ProductionLots.Giveaway
		|	AND NOT ProductionLots.MaterialProvider = CatAssignments.Partner
		|";
		
		Query.SetParameter("ProductionLots", ProductionLots.Unload(, "LineNumber, ProductionLot"));
		Query.SetParameter("Purpose",         Purpose);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			ErrorText = NStr("vi = 'Cho phép ghi giảm nguyên vật liệu/sản phẩm gia công vào lô sản xuất thành phẩm của người đặt gia công chúng.';
							|ru = 'Давальческие материалы/продукцию разрешено списывать на партии производства продукции их владельца.';
							|en = 'You can write off provided materials/manufactured products to production lots of products of their owner.'; fa = 'You can write off provided materials/manufactured products to production lots of products of their owner.';
							|it = 'I materiali/prodotti del fornitore possono essere stornati nei lotti di produzione del loro proprietario.';
							|pl = 'Materiały/produkcję powierzone można rozchodować na partie wyprodukowania produkcji ich właściciela.';
							|tr = 'Tedarikçi tarafından sağlanan malzemelerin/imal edilen ürünlerin, sahiplerinin ürün üretim lotlarından silinmesine izin verildi.'");
			RowPath = CommonClientServer.PathToTabularSection("ProductionLots", Selection.LineNumber, "ProductionLot");
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				RowPath,,
				Cancel);
			
		EndDo;
		
	EndIf;
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ProductionCostAllocation);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, 
		Documents.ProductionCostAllocation.ItemsAndDimensionsSelectionParameters());
	
	ProductionCostAllocationLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes",  ParametersForFillingInventoryTypes());
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	// Registration of a task for calculating the cost price.
	InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(Date, Ref, Organization);
	
	ProductionCostAllocationLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes",  ParametersForFillingInventoryTypes());
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ProductionCostAllocationLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	SetOfSeries.Clear();
	InventoryKinds.Clear();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "OtherExpenses,ProductionLots,InventoryKinds");
	
	ProductionCostAllocationLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ProductionCostAllocationLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillNumberToDistributionOfSeriesByRule()
	
	Coefficients = SetOfSeries.UnloadColumn("Count");
	
	Allocation = Common.DistributeAmountInProportionToCoefficients(QuantityToAllocateAccordingToRule, Coefficients, 3);
	
	If Allocation = Undefined Then
		Return;
	EndIf;
	
	IndexOf = 0;
	If Coefficients.Count() > 0 Then
		
		For Each String In SetOfSeries Do
			String.QuantityToAllocateAccordingToRule = Allocation[IndexOf];
			IndexOf = IndexOf + 1;
		EndDo;
		
	EndIf;
	
EndProcedure

#Region FillingStockTypes

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckChangesToProductTable(TempTablesManager) Then
		
		ParametersForFillingInventoryTypes = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																ParametersForFillingInventoryTypes);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, BusinessOperation", "Count, QuantityByGBRN");
		
		If Not Cancel Then
			FillOutAnalysisOfRecipientSInventoryTypes(TempTablesManager);
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	EndIf;
	
EndProcedure

Function TemporaryDataTables() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	&Date                                                     AS Date,
	|	&Organization                                              AS Organization,
	|	UNDEFINED                                              AS Partner,
	|	UNDEFINED                                              AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)    AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef)                  AS Currency,
	|	&TaxationOfOrganization                               AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand) AS BusinessOperation,
	|	FALSE                                                      AS ThereAreTransactionsInTablePart,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END                                                     AS Department,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END                                                     AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)        AS SalesOpportunity,
	|	VALUE(Enum.InventoryTypes.OwnGoods)                  AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Department
	|
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductData_1.Ref	AS Products,
	|	CASE
	|		WHEN ProductData_1.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN TRUE
	|		WHEN ProductData_1.TracedGoods
	|				AND &UseTraceableImportedGoodsAccounting
	|				AND ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END						AS UseItForInventorySelection
	|INTO ItemDataForSelection
	|FROM
	|	Catalog.Products AS ProductData_1
	|
	|WHERE
	|	ProductData_1.Ref = &Products
	|
	|INDEX BY
	|	Products
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ToExpenses.LineNumber              AS LineNumber,
	|	&Products                      AS Products,
	|	&Characteristic                    AS Characteristic,
	|	&Warehouse                             AS Warehouse,
	|	&ItemsLocationAttributes        AS ItemsLocationAttributes,
	|	&Purpose                        AS Purpose,
	|	&Series                             AS Series,
	|	&BatchesIndicationStatus               AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ToExpenses.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN &Department
	|		ELSE ToExpenses.Department
	|	END                              AS Department,
	|	ToExpenses.Count               AS Count,
	|	VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand) AS BusinessOperation,
	|	ToExpenses.ExpenseItem           AS ExpenseItem,
	|	ToExpenses.DimensionOfExpenses        AS DimensionOfExpenses,
	|	ToExpenses.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	ToExpenses.GLAccountSettings     AS GLAccountSettings,
	|	ToExpenses.RowID      AS RowID
	|INTO TTForExpenses
	|FROM
	|	&OtherExpenses AS ToExpenses
	|
	|INDEX BY
	|	Products
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionLots.LineNumber						AS LineNumber,
	|	&Products										AS Products,
	|	&Characteristic										AS Characteristic,
	|	&Warehouse												AS Warehouse,
	|	&ItemsLocationAttributes							AS ItemsLocationAttributes,
	|	ProductionLots.ItemsLocationAttributes		AS AnalysisOfAccountingForRecipientProducts,
	|	&Purpose											AS Purpose,
	|	&Series												AS Series,
	|	&BatchesIndicationStatus								AS BatchesIndicationStatus,
	|	&Department										AS Department,
	|	ProductionLots.Count						AS Count,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	ProductionLots.ProductionLot				AS ProductionLot,
	|	ProductionLots.Stage								AS Stage,
	|	ProductionLots.ProductCostElement				AS ProductCostElement,
	|	ProductionLots.RowID				AS RowID
	|INTO TTPerBatchOfProduction
	|FROM
	|	&ProductionLots AS ProductionLots
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1                                  AS LineNumber,
	|	&Products                      AS Products,
	|	&Characteristic                    AS Characteristic,
	|	&Warehouse                             AS Warehouse,
	|	&ItemsLocationAttributes        AS ItemsLocationAttributes,
	|	&Purpose                        AS Purpose,
	|	&Series                             AS Series,
	|	&BatchesIndicationStatus               AS BatchesIndicationStatus,
	|	&Department                     AS Department,
	|	&QuantityToAllocateAccordingToRule AS Count,
	|	&ProductCostElement                 AS ProductCostElement,
	|	VALUE(Document.CustomerInvoice.EmptyRef) AS DocumentSalesOfGoodsAndServices,
	|	VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots) AS BusinessOperation,
	|	""""                               AS RowID
	|INTO TTByRule
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BatchProductionNumberOfRows + TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products                   AS Products,
	|	TableOfGoods.Characteristic                 AS Characteristic,
	|	TableOfGoods.Series                          AS Series,
	|	TableOfGoods.BatchesIndicationStatus            AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes     AS ItemsLocationAttributes,
	|	UNDEFINED                                  AS AnalysisOfAccountingForRecipientProducts,
	|	TableOfGoods.Count                     AS Count,
	|	TableOfGoods.Warehouse                          AS Warehouse,
	|	TableOfGoods.Department                  AS Department,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.VATRates.EmptyRef)   AS VATRate,
	|	0                                             AS AmountIncludingVAT,
	|	0                                             AS VATAmount,
	|	0                                             AS CommissionAmount,
	|	0                                             AS AmountVATRemuneration,
	|	TableOfGoods.Purpose                     AS Purpose,
	|	VALUE(Catalog.InventoryAccountingGroups.EmptyRef) AS ProductsGroup,
	|	TableOfGoods.BusinessOperation          AS BusinessOperation,
	|	TableOfGoods.ExpenseItem                 AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses              AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension       AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings           AS GLAccountSettings,
	|	VALUE(Catalog.ProductionLots.EmptyRef) AS ProductionLot,
	|	UNDEFINED                                  AS Stage,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	TRUE                                        AS SelectTypesOfStocks,
	|	TableOfGoods.RowID            AS RowID,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)   AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTForExpenses AS TableOfGoods
	|		INNER JOIN ItemDataForSelection AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Products
	|
	|WHERE
	|	TableOfGoods.Count > 0
	|	AND ProductData_1.UseItForInventorySelection
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber                    AS LineNumber,
	|	TableOfGoods.Products                   AS Products,
	|	TableOfGoods.Characteristic                 AS Characteristic,
	|	TableOfGoods.Series                          AS Series,
	|	TableOfGoods.BatchesIndicationStatus            AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes     AS ItemsLocationAttributes,
	|	TableOfGoods.AnalysisOfAccountingForRecipientProducts AS AnalysisOfAccountingForRecipientProducts,
	|	TableOfGoods.Count                     AS Count,
	|	TableOfGoods.Warehouse                          AS Warehouse,
	|	TableOfGoods.Department                  AS Department,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.VATRates.EmptyRef)   AS VATRate,
	|	0                                             AS AmountIncludingVAT,
	|	0                                             AS VATAmount,
	|	0                                             AS CommissionAmount,
	|	0                                             AS AmountVATRemuneration,
	|	TableOfGoods.Purpose                     AS Purpose,
	|	VALUE(Catalog.InventoryAccountingGroups.EmptyRef) AS ProductsGroup,
	|	TableOfGoods.BusinessOperation          AS BusinessOperation,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED                                  AS DimensionOfExpenses,
	|	UNDEFINED                                  AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                  AS GLAccountSettings,
	|	TableOfGoods.ProductionLot             AS ProductionLot,
	|	TableOfGoods.Stage                           AS Stage,
	|	TableOfGoods.ProductCostElement              AS ProductCostElement,
	|	TRUE                                        AS SelectTypesOfStocks,
	|	TableOfGoods.RowID            AS RowID,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)   AS CCDNumber
	|FROM
	|	TTPerBatchOfProduction AS TableOfGoods
	|		INNER JOIN ItemDataForSelection AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Products
	|
	|WHERE
	|	TableOfGoods.Count > 0
	|	AND ProductData_1.UseItForInventorySelection
	|
	|UNION ALL
	|
	|SELECT
	|	&BatchProductionNumberOfRows + &TotalNumberOfRows_ + TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products                   AS Products,
	|	TableOfGoods.Characteristic                 AS Characteristic,
	|	TableOfGoods.Series                          AS Series,
	|	TableOfGoods.BatchesIndicationStatus            AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes     AS ItemsLocationAttributes,
	|	UNDEFINED                                  AS AnalysisOfAccountingForRecipientProducts,
	|	TableOfGoods.Count                     AS Count,
	|	TableOfGoods.Warehouse                          AS Warehouse,
	|	TableOfGoods.Department                  AS Department,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0                                             AS AmountIncludingVAT,
	|	0                                             AS VATAmount,
	|	0                                             AS CommissionAmount,
	|	0                                             AS AmountVATRemuneration,
	|	TableOfGoods.Purpose                     AS Purpose,
	|	VALUE(Catalog.InventoryAccountingGroups.EmptyRef) AS ProductsGroup,
	|	TableOfGoods.BusinessOperation          AS BusinessOperation,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED                                  AS DimensionOfExpenses,
	|	UNDEFINED                                  AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                  AS GLAccountSettings,
	|	VALUE(Catalog.ProductionLots.EmptyRef) AS ProductionLot,
	|	UNDEFINED                                  AS Stage,
	|	TableOfGoods.ProductCostElement              AS ProductCostElement,
	|	TRUE                                        AS SelectTypesOfStocks,
	|	TableOfGoods.RowID            AS RowID,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)   AS CCDNumber
	|FROM
	|	TTByRule AS TableOfGoods
	|		INNER JOIN ItemDataForSelection AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Products
	|
	|WHERE
	|	TableOfGoods.Count > 0
	|	AND ProductData_1.UseItForInventorySelection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber                     AS LineNumber,
	|	TableTypesOfStocks_.BusinessOperation           AS BusinessOperation,
	|	TableTypesOfStocks_.ItemsLocationAttributes      AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                        AS CCDNumber,
	|	TableTypesOfStocks_.CorItemsLocationAttributes   AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.Count                      AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END                                              AS QuantityByGBRN,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableTypesOfStocks_.ExpenseItem                  AS ExpenseItem,
	|	TableTypesOfStocks_.Department                   AS Department,
	|	TableTypesOfStocks_.DimensionOfExpenses               AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension        AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ProductionLot              AS ProductionLot,
	|	FALSE                                               AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber                 AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	&Products                                  AS Products,
	|	&Characteristic                                AS Characteristic,
	|	&Series                                         AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                  AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                    AS CCDNumber,
	|	TableTypesOfStocks_.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.Count                  AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN            AS QuantityByGBRN,
	|	&Warehouse                                         AS OriginWarehouse,
	|	TableTypesOfStocks_.BusinessOperation       AS BusinessOperation,
	|	TableTypesOfStocks_.SalesOpportunity                      AS SalesOpportunity,
	|	TableTypesOfStocks_.ExpenseItem              AS ExpenseItem,
	|	TableTypesOfStocks_.Department               AS Department,
	|	TableTypesOfStocks_.DimensionOfExpenses           AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension    AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ProductionLot          AS ProductionLot,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually   AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ItemDataForSelection";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Ref",                     Ref);
	Query.SetParameter("Date",                       Date);
	Query.SetParameter("Organization",                Organization);
	Query.SetParameter("Manager",                   EmployeeResponsible);
	Query.SetParameter("Department",              Department);
	Query.SetParameter("Products",               Products);
	Query.SetParameter("Characteristic",             Characteristic);
	Query.SetParameter("Series",                      Series);
	Query.SetParameter("BatchesIndicationStatus",        BatchesIndicationStatus);
	Query.SetParameter("Purpose",                 Purpose);
	Query.SetParameter("ProductCostElement",          ProductCostElement);
	Query.SetParameter("Warehouse",                      Warehouse);
	Query.SetParameter("ItemsLocationAttributes", ItemsLocationAttributes);
	Query.SetParameter("Count",                 Count);
	Query.SetParameter("QuantityToAllocateAccordingToRule", QuantityToAllocateAccordingToRule);
	
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities", GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	
	Query.SetParameter("ProductionLots",					ProductionLots);
	Query.SetParameter("BatchProductionNumberOfRows",	ProductionLots.Count());
	
	Query.SetParameter("OtherExpenses",              OtherExpenses);
	Query.SetParameter("TotalNumberOfRows_",     OtherExpenses.Count());
	
	Query.SetParameter("TableTypesOfStocks_",         InventoryKinds);
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Organization, Date);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Date AS Date,
	|	CASE WHEN DocumentData.Department.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|		AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|	THEN
	|		DocumentData.Department
	|	ELSE
	|		VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|
	|	CASE WHEN DocumentData.Department.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|		AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|	THEN
	|		DocumentData.EmployeeResponsible
	|	ELSE
	|		VALUE(Catalog.Users.EmptyRef)
	|	END AS Manager,
	|
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity
	|
	|INTO SavedDocumentData
	|FROM
	|	Document.ProductionCostAllocation AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE WHEN DocumentData.Organization <> SavedData.Organization THEN
	|		TRUE
	|	WHEN DocumentData.Date <> SavedData.Date THEN
	|		TRUE
	|	WHEN DocumentData.Department <> SavedData.Department THEN
	|		TRUE
	|	WHEN DocumentData.Manager <> SavedData.Manager THEN
	|		TRUE
	|	WHEN DocumentData.SalesOpportunity <> SavedData.SalesOpportunity THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS DetailsChanged_
	|FROM
	|	DocumentDataTable AS DocumentData
	|
	|	LEFT JOIN
	|		SavedDocumentData AS SavedData
	|	ON
	|		TRUE
	|");
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities", GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.TempTablesManager = TempTablesManager;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		DetailsChanged_ = Selection.DetailsChanged_;
	Else
		DetailsChanged_ = False;
	EndIf;
	
	Return DetailsChanged_;
	
EndFunction

Function CheckChangesToProductTable(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ExpenseItem             AS ExpenseItem,
	|	TableOfGoods.Department              AS Department,
	|	TableOfGoods.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	TableOfGoods.BusinessOperation      AS BusinessOperation,
	|	TableOfGoods.ProductionLot         AS ProductionLot,
	|	SUM(TableOfGoods.Count)          AS Count
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.ExpenseItem             AS ExpenseItem,
	|		TableOfGoods.Department              AS Department,
	|		TableOfGoods.DimensionOfExpenses          AS DimensionOfExpenses,
	|		TableOfGoods.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|		TableOfGoods.ProductionLot         AS ProductionLot,
	|		TableOfGoods.BusinessOperation      AS BusinessOperation,
	|		TableOfGoods.Count                 AS Count
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes,
	|		TableTypesOfStocks_.ExpenseItem,
	|		TableTypesOfStocks_.Department,
	|		TableTypesOfStocks_.DimensionOfExpenses,
	|		TableTypesOfStocks_.AssetsLiabilitiesDimension,
	|		TableTypesOfStocks_.ProductionLot,
	|		TableTypesOfStocks_.BusinessOperation,
	|		-TableTypesOfStocks_.Count
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.Department,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.BusinessOperation,
	|	TableOfGoods.ProductionLot
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillOutAnalysisOfRecipientSInventoryTypes(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.AnalysisOfAccountingForRecipientProducts AS CorItemsLocationAttributes,
	|	TableOfGoods.Products               AS Products,
	|	TableOfGoods.Products.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TableOfGoods.Products.ItemsType AS ItemsType,
	|	TableOfGoods.Characteristic             AS Characteristic,
	|	TableOfGoods.Series                      AS Series,
	|	TableOfGoods.Department              AS Warehouse,
	|	CatProductionLots.Purpose          AS Purpose,
	|	TableOfGoods.Department              AS Department,
	|	TableOfGoods.ExpenseItem             AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings       AS GLAccountSettings,
	|	TableOfGoods.BusinessOperation      AS BusinessOperation,
	|	TableOfGoods.ProductionLot         AS ProductionLot,
	|	TableOfGoods.ProductCostElement          AS ProductCostElement,
	|	TableOfGoods.RowID        AS RowID,
	|	SUM(TableOfGoods.Count)          AS Count
	|FROM
	|	TableOfGoods AS TableOfGoods
	|	
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Ref = TableOfGoods.ProductionLot
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.AnalysisOfAccountingForRecipientProducts,
	|	TableOfGoods.Products,
	|	TableOfGoods.Products.FinancialAccountingGroup,
	|	TableOfGoods.Products.ItemsType,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.Department,
	|	CatProductionLots.Purpose,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings,
	|	TableOfGoods.BusinessOperation,
	|	TableOfGoods.ProductionLot,
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.RowID
	|
	|ORDER BY
	|	ItemsLocationAttributes,
	|	Count DESC";
	
	SampleProducts_ = Query.Execute().Select();
	
	FilterOfProducts_ = New Structure("ItemsLocationAttributes, BusinessOperation");
	
	InventoryTypes = Common.ObjectsAttributeValue(InventoryKinds.Unload(, "InventoryOwnerAttribute").UnloadColumn("InventoryOwnerAttribute"), "InventoryType");
	
	While SampleProducts_.Next() Do
		
		GoodsQuantity = SampleProducts_.Count;
		
		FillPropertyValues(FilterOfProducts_, SampleProducts_);
		
		For Each InventoryLine In InventoryKinds.FindRows(FilterOfProducts_) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, SampleProducts_, "CorItemsLocationAttributes, BusinessOperation, ExpenseItem,
																|Department, DimensionOfExpenses, AssetsLiabilitiesDimension,
																|GLAccountSettings, ProductionLot, RowID");
			
			If InventoryTypes[InventoryLine.InventoryOwnerAttribute] = Enums.InventoryTypes.ConsignedGoods Then
				NewRow.RecipientInventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(Organization, , SampleProducts_);
			Else
				NewRow.RecipientInventoryOwnerAttribute = NewRow.InventoryOwnerAttribute;
			EndIf;
			
			NewRow.Count = Min(GoodsQuantity, InventoryLine.Count);
			NewRow.QuantityByGBRN = NewRow.Count * InventoryLine.QuantityByGBRN
											/ InventoryLine.Count;
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "ByBusinessTransaction");
	
	ActionOnBusinessTransaction = New Map();
	ActionOnBusinessTransaction.Insert(Enums.BusinessTransactions.GoodsConsumptionOnDemand,               "Never");
	ActionOnBusinessTransaction.Insert(Enums.BusinessTransactions.ExpensingToProductionLots,      "AccordingToSettingsOfProductionContract");
	ActionOnBusinessTransaction.Insert(Enums.BusinessTransactions.AllocationOfExpensesForProductionLots, "AccordingToSettingsOfProductionContract");
	
	ActionsForBusinessTransaction = New Map;
	ActionsForBusinessTransaction.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, ActionOnBusinessTransaction);
	
	FillParameters.ActionsOfSelectionOfGoodsAcceptedForResponsibleStorageOnEconomicOperation =
		ActionsForBusinessTransaction;
	
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
	
	If GetFunctionalOption("UseExcisableGoods") Then
		FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
	EndIf;
	
	Return FillParameters;
	
EndFunction

#EndRegion

Procedure FillInRecipientProductTrackingAnalysis()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ProductionLots.LineNumber                      AS LineNumber,
	|	&Products                                       AS Products,
	|	&Characteristic                                     AS Characteristic,
	|	&Series                                              AS Series,
	|	ProductionLots.Department                    AS Warehouse,
	|	ProductionLots.ProductionLot               AS ProductionLot,
	|	ProductionLots.Stage                             AS Stage,
	|	ProductionLots.ProductCostElement                AS ProductCostElement
	|INTO TTParty
	|FROM
	|	&ProductionLots AS ProductionLots
	|
	|;
	|
	|SELECT
	|	TTParty.LineNumber             AS LineNumber,
	|	TTParty.Products            AS Products,
	|	TTParty.Characteristic          AS Characteristic,
	|	TTParty.Series                   AS Series,
	|	TTParty.Warehouse                   AS Warehouse,
	|	TTParty.ProductCostElement       AS ProductCostElement,
	|	ISNULL(Assignments.Ref, ISNULL(LinesOfBusiness.Purpose,
	|		VALUE(Catalog.Assignments.EmptyRef))) AS Purpose
	|FROM
	|	TTParty AS TTParty
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|			LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
	|			ON CatProductionLots.LineOfBusiness = LinesOfBusiness.Ref
	|			LEFT JOIN Catalog.Assignments AS Assignments
	|			ON CatProductionLots.Purpose = Assignments.Ref
	|		ON CatProductionLots.Ref = TTParty.ProductionLot
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("ProductionLots",   ProductionLots.Unload());
	Query.SetParameter("Products",         Products);
	Query.SetParameter("Characteristic",       Characteristic);
	Query.SetParameter("Purpose",           Purpose);
	Query.SetParameter("Series",                Series);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	FilterStructure1 = New Structure("LineNumber");
	
	For Each String In ProductionLots Do
		
		FilterStructure1.LineNumber = String.LineNumber;
		If Selection.FindNext(FilterStructure1) Then
			String.ItemsLocationAttributes = InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(Selection);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
#EndIf
