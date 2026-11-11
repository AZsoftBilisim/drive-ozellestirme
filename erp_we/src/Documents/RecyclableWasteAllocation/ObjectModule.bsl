#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.RecyclableWasteAllocation - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.SelectionOfStockTypes_.VATTaxation = ProductionIssueForActivity;
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
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
	
	// Updating the document amount
	Sum = Count * Price;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RecyclableWasteAllocation);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "ProductionLots,OtherExpenses");
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		SetPrivilegedMode(True);
		
		AnalyticsParameters = New Structure("Products, Characteristic, Series, Warehouse, Purpose");
		FillPropertyValues(AnalyticsParameters, ThisObject);
		AnalyticsParameters.Warehouse = Recipient;
		ItemsLocationAttributes = InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(AnalyticsParameters);
		
		SetPrivilegedMode(False);
		
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		InventoryKinds.Clear();
	EndIf;
	
	IncomeAndExpensesServer.BeforeWrite(ThisObject, 
		Documents.RecyclableWasteAllocation.ItemsAndDimensionsSelectionParameters());
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.RecyclableWasteAllocation.AccountingAccountSettings_());
	RecyclableWasteAllocationLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	InitializeDocument();
	RecyclableWasteAllocationLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	IncomeAndExpensesServer.Filling(ThisObject, 
		Documents.RecyclableWasteAllocation.ItemsAndDimensionsSelectionParameters());
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);

	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	#Region CheckingCharacteristics
	
	If GetFunctionalOption("UseItemVariants")
		And Not Catalogs.Products.ItemVariantsAreUsed(Products) Then
		NotCheckedAttributeArray.Add("Characteristic");
	EndIf;
	
	#EndRegion
	
	#Region CheckingSeries

	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RecyclableWasteAllocation);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												SeriesSpecificationParameters,
												Cancel,
												NotCheckedAttributeArray);
	
	#EndRegion

	#Region CheckingQuantities
	
	If Not Count = QuantityAccordingToRule + ProductionLots.Total("Count") + OtherExpenses.Total("Count") Then
		
		MessageText = NStr("vi = 'Số lượng chất thải có thể trả lại được phát hành và phân bổ không phù hợp.';
							|ru = 'Не совпадает количество выпущенных и распределенных возвратных отходов.';
							|en = 'Number of issued and allocated recyclable waste does not match.'; fa = 'Number of issued and allocated recyclable waste does not match.';
							|it = 'Non coincide il numero di scarti di lavorazione riutilizzabili prodotti e quelli distribuiti.';
							|pl = 'Ilość wydanych i przydzielonych odpadów zwrotnych jest niezgodna.';
							|tr = 'Üretilen ve dağıtılan geri dönüştürülebilir atık miktarı uyuşmamaktadır.'");
		CommonClientServer.MessageToUser(MessageText, ThisObject, "Count", "Object", Cancel);
		
	EndIf;
	
	#EndRegion
	
	#Region VerificationOfRecipient
	
	If Common.ObjectAttributeValue(Products, "ItemsType") = Enums.ItemsTypes.Work_5
		And Department = Recipient
		And Not QuantityAccordingToRule = 0 Then
		DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
		MessageText = NStr("vi = 'Khi được phân bổ theo các quy tắc, đơn vị công việc của người nhận không thể trùng với đơn vị phát hành.';
							|ru = 'При распределении по правилам подразделение-получатель работы не может совпадать с выпускающим подразделением.';
							|en = 'When allocating by rules, a business unit receiving works cannot be the same as a releasing business unit.'; fa = 'When allocating by rules, a business unit receiving works cannot be the same as a releasing business unit.';
							|it = 'Durante la distribuzione, in base alla regole, reparto-ricevente del lavoro non può coincidere con reparto di emissione.';
							|pl = 'Podczas przydzielenia zgodnie z zasadami dział-odbiorca nie może zbiegać się z działem wydającym.';
							|tr = 'Kural tabanlı bir dağıtımda, alıcı departmanı ile üreten departman aynı olamaz.'");
		CommonClientServer.MessageToUser(MessageText, DataKey , "Recipient", "Object", Cancel);
	EndIf;
	
	#EndRegion
	
	#Region RulesCheck
	
	If QuantityAccordingToRule = 0 Then
		NotCheckedAttributeArray.Add("AllocatedAccordingToRule");
		NotCheckedAttributeArray.Add("ProductCostElement");
	EndIf;
	
	If Not QuantityAccordingToRule = 0 And Not ValueIsFilled(AllocatedAccordingToRule) Then
		NotCheckedAttributeArray.Add("ProductCostElement");
	EndIf;
	
	#EndRegion
	
	#Region RecipientVerificationAndAnalytics
	
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, 
		Documents.RecyclableWasteAllocation.ItemsAndDimensionsSelectionParameters());
	
	#EndRegion
	
#Region VATVerification
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName						= "OtherExpenses";
	CheckParameters.BankingDetailsNameExpenseItem			= "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName			= "DimensionOfExpenses";
	CheckParameters.DetailsNameItemOfAssetsLiabilities		= "ExpenseItem";
	CheckParameters.NameOfAssetLiabilityAnalystDetails	= "AssetsLiabilitiesDimension";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject,
		ProductionIssueForActivity,
		CheckParameters,
		Cancel);
#EndRegion
	
	InventoriesServer.CheckAvailabilityOfProductsInHeaderTakingIntoAccountCCD(ThisObject, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	RecyclableWasteAllocationLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RecyclableWasteAllocationLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RecyclableWasteAllocationLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	RecyclableWasteAllocationLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InventoryKinds.Clear();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "ProductionLots,OtherExpenses");
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure InitializeDocument(FillingData = Undefined)
	
	Date           = CurrentSessionDate();
	PriceKind        = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory(PriceKind);
	Currency         = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind).PriceCurrency);
	Author          = Users.CurrentUser();
	
	FillParameters = Documents.RecyclableWasteAllocation.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(ProductionIssueForActivity, FillParameters);
	
EndProcedure

#EndRegion

#Region FillingStockTypes

Procedure FillStockTypes(Cancel)
	
	If Common.ObjectAttributeValue(Products, "ItemsType") = Enums.ItemsTypes.Work_5 Then
		InventoryKinds.Clear();
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	RefillInventoryKinds =
		InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
		Or CheckChangesToDocumentDetails();
	
	TempTablesManager = TemporaryDataTables();
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangeInProductTable(TempTablesManager) Then
		
		TableTypesOfInventoryItems = TableToFillInTypesOfProductStocks(TempTablesManager);
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, TableTypesOfInventoryItems);
		InventoryKinds.Load(TableTypesOfInventoryItems);
		
		Coefficients = InventoryKinds.UnloadColumn("Count");
		Amounts = Common.DistributeAmountInProportionToCoefficients(Sum, Coefficients);
		If Not Amounts = Undefined Then
			IndexOf = 0;
			For Each TechSum In Amounts Do
				InventoryKinds[IndexOf].Sum = TechSum;
				IndexOf = IndexOf + 1;
			EndDo;
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails()
	
	AttributesNames = "Organization, Date, ProductionIssueForActivity, Sum";
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.Text =
	"SELECT
	|	&Organization			AS Organization,
	|	&Date					AS Date,
	|	&Sum					AS Sum,
	|	&ProductionIssueForActivity	AS ProductionIssueForActivity
	|INTO DocumentDataTable
	|";
	
	Query.SetParameter("Organization",			Organization);
	Query.SetParameter("Date",					Date);
	Query.SetParameter("Sum",					Sum);
	Query.SetParameter("ProductionIssueForActivity",	ProductionIssueForActivity);
	
	Query.Execute();
	
	Return InventoriesServer.CheckChangesToDocumentDetails(Query.TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckChangeInProductTable(TempTablesManager)
	
	Query = New Query(
		"SELECT
		|	TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
		|	TableOfGoods.Department					AS Department,
		|	TableOfGoods.Recipient						AS Recipient,
		|	TableOfGoods.ProductionLot				AS ProductionLot,
		|	TableOfGoods.ProductCostElement				AS ProductCostElement,
		|	TableOfGoods.ExpenseItem					AS ExpenseItem,
		|	TableOfGoods.DimensionOfExpenses				AS DimensionOfExpenses,
		|	TableOfGoods.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
		|	TableOfGoods.RowID				AS RowID,
		|	TableOfGoods.GLAccountSettings				AS GLAccountSettings
		|FROM
		|	(SELECT
		|		TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
		|		TableOfGoods.Department					AS Department,
		|		TableOfGoods.Recipient						AS Recipient,
		|		TableOfGoods.ProductionLot				AS ProductionLot,
		|		TableOfGoods.ProductCostElement				AS ProductCostElement,
		|		TableOfGoods.ExpenseItem					AS ExpenseItem,
		|		TableOfGoods.DimensionOfExpenses				AS DimensionOfExpenses,
		|		TableOfGoods.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
		|		TableOfGoods.RowID				AS RowID,
		|		TableOfGoods.GLAccountSettings				AS GLAccountSettings,
		|		TableOfGoods.Count						AS Count
		|	FROM
		|		TableOfGoods AS TableOfGoods
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
		|		TableTypesOfStocks_.Department					AS Department,
		|		TableTypesOfStocks_.Recipient						AS Recipient,
		|		TableTypesOfStocks_.ProductionLot				AS ProductionLot,
		|		TableTypesOfStocks_.ProductCostElement				AS ProductCostElement,
		|		TableTypesOfStocks_.ExpenseItem					AS ExpenseItem,
		|		TableTypesOfStocks_.DimensionOfExpenses				AS DimensionOfExpenses,
		|		TableTypesOfStocks_.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
		|		TableTypesOfStocks_.RowID				AS RowID,
		|		TableTypesOfStocks_.GLAccountSettings				AS GLAccountSettings,
		|		-TableTypesOfStocks_.Count						AS Count
		|	FROM
		|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
		|
		|GROUP BY
		|	TableOfGoods.ItemsLocationAttributes,
		|	TableOfGoods.Department,
		|	TableOfGoods.Recipient,
		|	TableOfGoods.ProductionLot,
		|	TableOfGoods.ProductCostElement,
		|	TableOfGoods.ExpenseItem,
		|	TableOfGoods.DimensionOfExpenses,
		|	TableOfGoods.AssetsLiabilitiesDimension,
		|	TableOfGoods.RowID,
		|	TableOfGoods.GLAccountSettings
		|
		|HAVING
		|	NOT SUM(TableOfGoods.Count) = 0");
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function TemporaryDataTables()
	
	Query = New Query(
	"SELECT
	|	TableOfGoods.LineNumber + 1		AS LineNumber,
	|	&Products						AS Products,
	|	&Characteristic						AS Characteristic,
	|	&Purpose							AS Purpose,
	|	&ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	TableOfGoods.Department		AS Department,
	|	&Recipient							AS Recipient,
	|	TableOfGoods.ProductionLot	AS ProductionLot,
	|	TableOfGoods.ProductCostElement	AS ProductCostElement,
	|	TableOfGoods.RowID	AS RowID,
	|	TableOfGoods.Count			AS Count
	|INTO ProductionBatchTable
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfOtherExpenses.LineNumber + &QuantityOfBatches + 1 AS LineNumber,
	|	&Products									AS Products,
	|	&Characteristic									AS Characteristic,
	|	&Purpose										AS Purpose,
	|	&ItemsLocationAttributes						AS ItemsLocationAttributes,
	|	TableOfOtherExpenses.Department				AS Department,
	|	&Recipient										AS Recipient,
	|	TableOfOtherExpenses.ExpenseItem			AS ExpenseItem,
	|	TableOfOtherExpenses.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TableOfOtherExpenses.AssetsLiabilitiesDimension	AS AssetsLiabilitiesDimension,
	|	TableOfOtherExpenses.GLAccountSettings		AS GLAccountSettings,
	|	TableOfOtherExpenses.RowID		AS RowID,
	|	TableOfOtherExpenses.Count				AS Count
	|INTO TableOfOtherExpenses
	|FROM
	|	&TableOfOtherExpenses AS TableOfOtherExpenses
	|;
	|
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.Department				AS Department,
	|	TableOfGoods.Recipient					AS Recipient,
	|	TableOfGoods.ProductionLot			AS ProductionLot,
	|	TableOfGoods.ProductCostElement			AS ProductCostElement,
	|	UNDEFINED								AS ExpenseItem,
	|	UNDEFINED								AS DimensionOfExpenses,
	|	UNDEFINED								AS AssetsLiabilitiesDimension,
	|	UNDEFINED								AS GLAccountSettings,
	|	TableOfGoods.RowID			AS RowID,
	|	TableOfGoods.Count					AS Count,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	ProductionBatchTable AS TableOfGoods
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfOtherExpenses.LineNumber						AS LineNumber,
	|	TableOfOtherExpenses.Products						AS Products,
	|	TableOfOtherExpenses.Characteristic					AS Characteristic,
	|	TableOfOtherExpenses.Purpose						AS Purpose,
	|	TableOfOtherExpenses.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableOfOtherExpenses.Department						AS Department,
	|	TableOfOtherExpenses.Recipient						AS Recipient,
	|	VALUE(Catalog.ProductionLots.EmptyRef)	AS ProductionLot,
	|	VALUE(Catalog.ProductCostElements.EmptyRef)		AS ProductCostElement,
	|	TableOfOtherExpenses.ExpenseItem					AS ExpenseItem,
	|	TableOfOtherExpenses.DimensionOfExpenses					AS DimensionOfExpenses,
	|	TableOfOtherExpenses.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	TableOfOtherExpenses.GLAccountSettings				AS GLAccountSettings,
	|	TableOfOtherExpenses.RowID				AS RowID,
	|	TableOfOtherExpenses.Count						AS Count,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)				AS CCDNumber
	|FROM
	|	TableOfOtherExpenses AS TableOfOtherExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	0														AS LineNumber,
	|	&Products											AS Products,
	|	&Characteristic											AS Characteristic,
	|	&Purpose												AS Purpose,
	|	&ItemsLocationAttributes								AS ItemsLocationAttributes,
	|	&Department											AS Department,
	|	&Recipient												AS Recipient,
	|	VALUE(Catalog.ProductionLots.EmptyRef)	AS ProductionLot,
	|	&ProductCostElement										AS ProductCostElement,
	|	UNDEFINED											AS ExpenseItem,
	|	UNDEFINED											AS DimensionOfExpenses,
	|	UNDEFINED											AS AssetsLiabilitiesDimension,
	|	UNDEFINED											AS GLAccountSettings,
	|	UNDEFINED											AS RowID,
	|	&QuantityAccordingToRule									AS Count,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)				AS CCDNumber
	|WHERE
	|	NOT &QuantityAccordingToRule = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Department				AS Department,
	|	TableTypesOfStocks_.Recipient					AS Recipient,
	|	TableTypesOfStocks_.ProductionLot			AS ProductionLot,
	|	TableTypesOfStocks_.ProductCostElement			AS ProductCostElement,
	|	TableTypesOfStocks_.ExpenseItem				AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)		AS CCDNumber,
	|	TableTypesOfStocks_.GLAccountSettings			AS GLAccountSettings,
	|	TableTypesOfStocks_.Count					AS Count
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Department				AS Department,
	|	TableTypesOfStocks_.Recipient					AS Recipient,
	|	TableTypesOfStocks_.ProductionLot			AS ProductionLot,
	|	TableTypesOfStocks_.ProductCostElement			AS ProductCostElement,
	|	TableTypesOfStocks_.ExpenseItem				AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)		AS CCDNumber,
	|	TableTypesOfStocks_.GLAccountSettings			AS GLAccountSettings,
	|	TableTypesOfStocks_.Count					AS Count
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|");
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("TableOfGoods",				ProductionLots);
	Query.SetParameter("QuantityOfBatches",			ProductionLots.Count());
	Query.SetParameter("TableOfOtherExpenses",		OtherExpenses);
	Query.SetParameter("TableTypesOfStocks_",			InventoryKinds);
	Query.SetParameter("Products",				Products);
	Query.SetParameter("Characteristic",				Characteristic);
	Query.SetParameter("Purpose",					Purpose);
	Query.SetParameter("ItemsLocationAttributes",	ItemsLocationAttributes);
	Query.SetParameter("Department",				Department);
	Query.SetParameter("Recipient",					Recipient);
	Query.SetParameter("ProductCostElement",			ProductCostElement);
	Query.SetParameter("QuantityAccordingToRule",		QuantityAccordingToRule);
	
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
Function TableToFillInTypesOfProductStocks(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	&Organization												AS Organization,
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
	|		WHEN TRUE
	|			THEN &Organization
	|	END														AS GoodsOwner,
	|	ISNULL(TableOfGoods.Purpose.Contract.Counterparty, UNDEFINED) AS Counterparty,
	|	ISNULL(TableOfGoods.Purpose.Contract, UNDEFINED)	AS Contract,
	|	TableOfGoods.Recipient									AS Recipient,
	|	TableOfGoods.ItemsLocationAttributes					AS ItemsLocationAttributes,
	|	TableOfGoods.ProductionLot							AS ProductionLot,
	|	TableOfGoods.ExpenseItem								AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses							AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension						AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ProductCostElement							AS ProductCostElement,
	|	TableOfGoods.GLAccountSettings							AS GLAccountSettings,
	|	TableOfGoods.RowID							AS RowID,
	|	TableOfGoods.CCDNumber										AS CCDNumber,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)				AS CurViewOfStocks,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)				AS InventoryOwnerAttribute,
	|	SUM(TableOfGoods.Count)							AS Count,
	|	FALSE														AS ThisIsReusablePackage
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	NOT TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|GROUP BY
	|	TableOfGoods.BusinessOperation,
	|	TableOfGoods.Department,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose,
	|	CASE
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
	|		WHEN TRUE
	|			THEN &Organization
	|	END,
	|	ISNULL(TableOfGoods.Purpose.Contract.Counterparty, UNDEFINED),
	|	ISNULL(TableOfGoods.Purpose.Contract, UNDEFINED),
	|	TableOfGoods.Recipient,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ProductionLot,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.GLAccountSettings,
	|	TableOfGoods.RowID,
	|	TableOfGoods.CCDNumber
	|";
	
	Query.SetParameter("Organization",				Organization);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("TaxationOfOrganization",	VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Result = Query.ExecuteBatchWithIntermediateData();
	Return Result[0].Unload();
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
