#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns views of document cost groups.
//
// Returns:
//	Map - the correspondence of the cost group representation to its number.
//
Function PresentationOfCostGroups() Export
	
	PresentationOfCostGroups = New Map;
	
	CostGroups = Documents.SubcontractorReport2_5.CostGroupTable();
	Documents.SubcontractorReport2_5.UpdateCostGroups(ThisObject, CostGroups, 0);
	
	For Each CurGroup In CostGroups Do
		PresentationOfCostGroups.Insert(
			CurGroup.CostGroupNumber,
			ProcessingByThirdPartiesClientServer.CostGroupPresentation(
				CurGroup,
				ProcessingByThirdPartiesClientServer.ListOfCostGroupFieldsInProcessorSReport(GroupCosts)));
	EndDo;
	
	Return PresentationOfCostGroups;
	
EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.VendorInvoice - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	DocumentObject.AdditionalProperties.Insert(
		"ParametersForFillingInventoryTypes",
		ParametersForFillingInventoryTypes("Posting"));
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in tabular parts
// 'Output products', 'Side products', 'Materials and Works' and 'Services' of the document, and also fills in the tabular
// parts of 'Types of Supplies' and 'Types of supplies'.
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.SubcontractorReport2_5.CollectionOfTabularPartsOfGoods.
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

Procedure OnCopy(CopiedObject)
	
	MaximumNumberOfCostGroup  = 0;
	MaximumRowCodeProducts = 0;
	DocumentBasis = Undefined;
	
	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	If Not ByOrders Then
		For Each CurRow In ManufacturedProducts Do
			CurRow.RowCode = 0;
		EndDo;
	EndIf;
	
	SubcontractorReport2_5Localization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		If FillingData.Property("AnArrayOfOrders") Then
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
			If FillingData.ByOrders Then
				FillInBasedOnOrder(FillingData.AnArrayOfOrders[0]);
			Else
				FillInBasedOnAgreement(FillingData.HeaderAttributes.Contract);
			EndIf;
		EndIf;
	ElsIf FillInDataType = Type("DocumentRef.SubcontractOrder2_5") Then
		FillInBasedOnOrder(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
		FillInBasedOnReceiptFromProcessor(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		FillInBasedOnReportToGiver(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.CounterpartyContracts") Then
		FillInBasedOnAgreement(FillingData);
	EndIf;
	
	InitializeDocument(FillingData);
	
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	If Not ValueIsFilled(MethodOfAllocatingFinishedProductCosts)
		And (GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOM
			Or GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments
			Or GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping) Then
			MethodOfAllocatingFinishedProductCosts =
				Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.SubcontractorReport2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	SubcontractorReport2_5Localization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		
		ThereAreAdjustingEntries = False;
		ThereIsSF = False;
		
		PurchasesServer.CheckForAdjustmentsAndInvoices(Ref, Ref, ThereAreAdjustingEntries, ThereIsSF);
		If ThereAreAdjustingEntries Then
			PurchasesServer.ReportErrorsCancellationsAndAdjustments(Ref,Cancel);
		EndIf;
		
	EndIf;
	
	RoundingParameters = ProductsServer.ParametersForRoundingNumberOfUnitProducts();
	RoundingParameters.TSName = "ManufacturedProducts";
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	OrdersServer.SetKeyInRowsOfTablePart(
		ThisObject, "ManufacturedProducts", "MaximumRowCodeProducts", "RowCodeProducts");
	
	For Each CurRow In ManufacturedProducts Do
		If Not ValueIsFilled(CurRow.SubcontractOrder) Then
			CurRow.SubcontractOrder = SubcontractOrder;
		EndIf;
	EndDo;
	
	For Each CurRow In SideAndIntermediateRelease Do
		If Not ValueIsFilled(CurRow.SubcontractOrder) Then
			CurRow.SubcontractOrder = SubcontractOrder;
		EndIf;
	EndDo;
	
	For Each CurRow In Services Do
		If Not ValueIsFilled(CurRow.SubcontractOrder) Then
			CurRow.SubcontractOrder = SubcontractOrder;
		EndIf;
	EndDo;
	
	DocumentAmount = Services.Total("AmountIncludingVAT");
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	SeriesSpecificationParameters =
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SubcontractorReport2_5);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.ManufacturedProducts);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.SideAndIntermediateRelease);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.MaterialsAndWorks);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	RegistrationParameters = Documents.SubcontractorReport2_5.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	ItemsAndDimensionsSelectionParameters = Documents.SubcontractorReport2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TMCommonUse.FillInDocumentIDs(
		ThisObject,
		"ManufacturedProducts,SideAndIntermediateRelease,MaterialsAndWorks,Services");
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		InventoryOwnerAttributesMaterials.Clear();
		InventoryOwnerAttributesProducts.Clear();
	EndIf;
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
	GLAccountSettingsServer.BeforeWrite(ThisObject, Documents.SubcontractorReport2_5.AccountingAccountSettings_());
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());
	
	SubcontractorReport2_5Localization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	TMCommonUse.SyncKeys(ThisObject);	
	
	If Not Cancel
		And Not DeletionMark
		And Not GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Documents.SubcontractorReport2_5.FormProductionBatches(ThisObject);
	EndIf;
	
	SubcontractorReport2_5Localization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	NotCheckedAttributeArray = New Array;
	If Not Documents.SubcontractorReport2_5.ProductionEditingIsAvailable(ThisObject) Then
		NotCheckedAttributeArray.Add("ManufacturedProducts");
	EndIf;
	UseServices = (ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	
	#Region ComplianceOfProcessorSReportsWithOrderToProcessor
	
	ProcessingByThirdParties.CheckComplianceOfProcessorSReportsWithOrderToProcessor(ThisObject, Cancel);
	
	#EndRegion
	
	#Region TS_Characteristic_And_Count
	
	QuantityVerificationParameters = Documents.SubcontractorReport2_5.TSParametersForRounding();

	ProductsServer.CheckQuantityFilling(
		ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters["ManufacturedProducts"]);
	
	ProductsServer.CheckQuantityFilling(
		ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters["SideAndIntermediateRelease"]);
	
	ProductsServer.CheckQuantityFilling(
		ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters["MaterialsAndWorks"]);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "ManufacturedProducts";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "SideAndIntermediateRelease";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	CheckParameters.TSName = "MaterialsAndWorks";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	If UseServices Then
		CheckParameters.TSName = "Services";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	EndIf;
	
	#EndRegion

	#Region TS_Series
	
	SeriesSpecificationParameters =
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SubcontractorReport2_5);
	ParametersArray = New Array;
	ParametersArray.Add(SeriesSpecificationParameters.ManufacturedProducts);
	ParametersArray.Add(SeriesSpecificationParameters.SideAndIntermediateRelease);
	ParametersArray.Add(SeriesSpecificationParameters.MaterialsAndWorks);
	ProductsServer.CheckSeriesCompletion(ThisObject,
		ParametersArray,
		Cancel,
		NotCheckedAttributeArray);
	
	#EndRegion

	#Region TS_CostShare
	ProductionServer.CheckIfCostFractionsAreFilledInInTablePart(
		ThisObject, "ManufacturedProducts", NotCheckedAttributeArray, Cancel);
	#EndRegion

	#Region ReviewArticlesAndAnalytics

	ItemsAndDimensionsSelectionParameters = Documents.SubcontractorReport2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	#EndRegion
	
	#Region PM_CostGroups
	
	CheckCostGroups(Cancel, NotCheckedAttributeArray);
	
	#EndRegion
	
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts
		Or GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		Or GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments Then
		NotCheckedAttributeArray.Add("MethodOfAllocatingFinishedProductCosts");
	EndIf;
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(ManufacturedProducts, Date)
								Or AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(SideAndIntermediateRelease, Date);
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, ManufacturedProducts, Date);
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, SideAndIntermediateRelease, Date);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	ProductionServer.CheckRecipientSFillingInTablePart(ThisObject, "ManufacturedProducts"       , Cancel);
	ProductionServer.CheckRecipientSFillingInTablePart(ThisObject, "SideAndIntermediateRelease", Cancel);
	
	#Region VATAccounting
	
	CheckParameters = VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases();
	CheckParameters.TabularSectionName						= "ManufacturedProducts";
	CheckParameters.BankingDetailsNameExpenseItem			= "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName			= "DimensionOfExpenses";
	
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(
		ThisObject,
		VATTaxation,
		CheckParameters,
		Cancel);
	
	CheckParameters.TabularSectionName = "SideAndIntermediateRelease";
	
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(
		ThisObject,
		VATTaxation,
		CheckParameters,
		Cancel);
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName						= "ManufacturedProducts";
	CheckParameters.BankingDetailsNameExpenseItem			= "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName			= "DimensionOfExpenses";
	CheckParameters.DetailsNameItemOfAssetsLiabilities		= "ExpenseItem";
	CheckParameters.NameOfAssetLiabilityAnalystDetails	= "AssetsLiabilitiesDimension";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject,
		PurchaseForActivity,
		CheckParameters,
		Cancel);
	
	CheckParameters.TabularSectionName = "SideAndIntermediateRelease";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject,
		PurchaseForActivity,
		CheckParameters,
		Cancel);
	
	#EndRegion
	#Region CheckingGiverSAppointments
	
	DestinationVerificationParameters = TollingScheme.ParametersForCheckingSelectionOfGiverSDestination();
	DestinationVerificationParameters.TollBasedCostGroupings.Add(Enums.CostGroupingsInTollingOrder.ByProductionStages);
	TollingScheme.CheckCorrectnessOfChoiceOfGiverSAppointment(ThisObject, DestinationVerificationParameters, Cancel);
	
	#EndRegion
	SubcontractorReport2_5Localization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	FillParameters = ParametersForFillingInventoryTypes("Posting");
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.SubcontractorReport2_5.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
	SubcontractorReport2_5Localization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	FillParameters = ParametersForFillingInventoryTypes("Posting");
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.SubcontractorReport2_5.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
	SubcontractorReport2_5Localization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInBasedOnOrder(DocumentBasis) Export
	
	Documents.SubcontractorReport2_5.FillInBasedOnOrder(ThisObject, DocumentBasis);
	
EndProcedure

Procedure FillInBasedOnAgreement(Contract)
	
	DetailsOfFoundation =
		Common.ObjectAttributesValues(Contract, "Organization, Partner");
	
	QueryTexts = New Array;
	QueryTexts.Add("
	|SELECT
	|	ContractDetails_.Organization             AS Organization,
	|	ContractDetails_.Department           AS Department,
	|	ContractDetails_.Partner                 AS Partner,
	|	ContractDetails_.Counterparty              AS Counterparty,
	|	ContractDetails_.Ref                  AS Contract,
	|	ContractDetails_.LineOfBusiness AS LineOfBusiness,
	|	ContractDetails_.ARAPCurrency    AS ARAPCurrency,
	|	ContractDetails_.ARAPCurrency    AS Currency
	|FROM
	|	Catalog.CounterpartyContracts AS ContractDetails_
	|
	|WHERE
	|	ContractDetails_.Ref = &Contract
	|");
	
	Filters = New Structure;
	
	FilterReservesOfGoods = New Map;
	TMCommonUse.AddSelectionItemToCollection(
		FilterReservesOfGoods,
		"StockBalance.ItemsLocationAttributes.StorageLocation",
		"&Contract",
		"=");
	Filters.Insert("FilterReservesOfGoods", FilterReservesOfGoods);
	
	QueryTexts.Add(Documents.SubcontractorReport2_5.RequestTextProductsWithoutOrderForCheckout(Filters));
	
	Query = New Query;
	If TMCommonUse.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Organization", DetailsOfFoundation.Organization);
	Query.SetParameter("Partner",     DetailsOfFoundation.Partner);
	Query.SetParameter("Contract",     Contract);
	
	Result = Query.ExecuteBatch();
	
	FillInBasedOnObjectWithoutOrder(Result);
	
EndProcedure

Procedure FillInBasedOnReceiptFromProcessor(DocumentBasis)
	
	DetailsOfFoundation =
		Common.ObjectAttributesValues(
			DocumentBasis,
			"Organization, Partner, Contract, ByReferences, ReferenceOrder");
	
	If DetailsOfFoundation.ByReferences
		And Not ValueIsFilled(DetailsOfFoundation.ReferenceOrder) Then
		
		Raise
			NStr("vi = 'Đã lập chứng từ tiếp nhận từ người nhận gia công theo nhiều đơn hàng. Không thể nhập trên cơ sở.
				|Hãy sử dụng chỗ làm việc ""Chuyển giao vào gia công"" - ""Chứng từ cần lập bảng kê"".';
				|ru = 'Поступление от переработчика оформлено по нескольким заказам. Ввод на основании невозможен.
				|Воспользуйтесь рабочим местом ""Передача в переработку"" - ""Документы к оформлению"".';
				|en = '""Goods receipt — External subcontracting"" is registered by several orders. Cannot generate any documents from it.
				|Use the ""Subcontracting - Unregistered documents"" workplace.'; fa = '""Goods receipt — External subcontracting"" is registered by several orders. Cannot generate any documents from it.
				|Use the ""Subcontracting - Unregistered documents"" workplace.';
				|it = 'La ricezione da parte dell''elaboratore è stata realizzata in base ad alcuni ordini. L''inserimento sulla base non è disponibile.
				|Utilizzare la postazione di lavoro ""Trasferimento all''elaboratore"" - ""Documenti per la formalizzazione"".';
				|pl = 'Wpływ od przetwórcy został utworzony według kilku zamówień. Wprowadzenie na podstawie jest niemożliwe.
				|Skorzystaj z miejsca pracy ""Przekazania do przetwarzania"" - ""Dokumenty do rejestracji"".';
				|tr = 'Birden fazla sipariş için fason üreticiden gelen ürünleri teslim alma belgesi  düzenlenmiştir. Buna dayalı giriş mümkün değildir.
				|""Fason üretim"" - ""Düzenlenecek Belgeler"" çalışma alanını kullanın.'",
				Common.DefaultLanguageCode());
		
	ElsIf DetailsOfFoundation.ByReferences
		And ValueIsFilled(DetailsOfFoundation.ReferenceOrder) Then
		FillInBasedOnOrder(DetailsOfFoundation.ReferenceOrder);
		Return;
	EndIf;
	
	QueryTexts = New Array;
	QueryTexts.Add("
	|SELECT
	|	ReceiptDetails.Ref                  AS DocumentBasis,
	|	ReceiptDetails.Organization             AS Organization,
	|	ReceiptDetails.Department           AS Department,
	|	ReceiptDetails.SalesOpportunity                  AS SalesOpportunity,
	|	ReceiptDetails.Partner                 AS Partner,
	|	ReceiptDetails.Counterparty              AS Counterparty,
	|	ReceiptDetails.Contract                 AS Contract,
	|	ReceiptDetails.LineOfBusiness AS LineOfBusiness,
	|	ReceiptDetails.Contract.ARAPCurrency AS ARAPCurrency,
	|	ReceiptDetails.Currency                  AS Currency,
	|	ReceiptDetails.PriceKind                 AS PriceKind
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian AS ReceiptDetails
	|
	|WHERE
	|	ReceiptDetails.Ref = &DocumentBasis
	|");
	
	// Selection by the nomenclature of the base
	QueryTexts.Add("
	|SELECT
	|	BaseGoods.Products   AS Products,
	|	BaseGoods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN BaseGoods.BatchesIndicationStatusOfGoodsTransferred IN (14, 18)
	|			THEN BaseGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                          AS Series
	|INTO BaseGoods
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS BaseGoods
	|WHERE
	|	BaseGoods.Ref = &DocumentBasis
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series
	|");
	
	Filters = New Structure;
	
	FilterReservesOfGoods = New Map;
	TMCommonUse.AddSelectionItemToCollection(
		FilterReservesOfGoods,
		"StockBalance.ItemsLocationAttributes.Products,
		|StockBalance.ItemsLocationAttributes.Characteristic,
		|StockBalance.ItemsLocationAttributes.Series",
		"SELECT
		|	BaseGoods.Products,
		|	BaseGoods.Characteristic,
		|	BaseGoods.Series
		|FROM
		|	BaseGoods AS BaseGoods");
	Filters.Insert("FilterReservesOfGoods", FilterReservesOfGoods);
	
	FilterPurchaseOrders = New Map;
	TMCommonUse.AddSelectionItemToCollection(
		FilterPurchaseOrders,
		"Products, Characteristic",
		"SELECT
		|	BaseGoods.Products,
		|	BaseGoods.Characteristic
		|FROM
		|	BaseGoods AS BaseGoods");
	Filters.Insert("FilterPurchaseOrders", FilterPurchaseOrders);
	
	QueryTexts.Add(Documents.SubcontractorReport2_5.RequestTextProductsWithoutOrderForCheckout(Filters));
	
	Query = New Query;
	If TMCommonUse.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("Organization",       DetailsOfFoundation.Organization);
	Query.SetParameter("Partner",           DetailsOfFoundation.Partner);
	Query.SetParameter("Contract",           DetailsOfFoundation.Contract);
	
	Result = Query.ExecuteBatch();
	
	FillInBasedOnObjectWithoutOrder(Result);
	
EndProcedure

Procedure FillInBasedOnObjectWithoutOrder(Result)
	
	DocumentAttributes = Result[0].Select();
	If DocumentAttributes.Next() Then
		FillPropertyValues(ThisObject, DocumentAttributes);
	EndIf;
	
	ManufacturedProducts.Load(Result[Result.UBound()].Unload());
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SubcontractorReport2_5);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.ManufacturedProducts);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.ManufacturedProducts);
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy",
		Organization,
		Date);
	
	UseTargetCost = False;
	If Not AccountingPolicyParameters = Undefined Then
		UseTargetCost = AccountingPolicyParameters.ProductCostingByPlannedCost;
	EndIf;
	
	If UseTargetCost Then
		
		ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(ThisObject, True);
		ActionParameters.Insert("PriceKind", PriceKind);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInSalePrice", ActionParameters);
		
		BatchProcessingOfTablePartServer.TreatTS(ManufacturedProducts, StructureOfActions, Undefined);
		
	EndIf;
	
	InitializeDocumentAfterAddingProducts();
	
	Documents.SubcontractorReport2_5.FillInByProductsMaterialsServicesAccordingToSpecification(ThisObject, ManufacturedProducts);
	
EndProcedure

#Region FillInBasedOnReportToGiver

Procedure FillInBasedOnReportToGiver(FillingData)
	
	DetailsOfFoundation = Common.ObjectAttributesValues(FillingData, "ReportOnOrders");
	
	Query = New Query;
	Query.SetParameter("Basis", FillingData);
	
	If DetailsOfFoundation.ReportOnOrders
		And GetFunctionalOption("UseSubcontractOrders2_5") Then
		ByOrders  = True;
		Query.Text = FillInQueryTextBasedOnReportToOrderGiver();
	Else
		Query.Text = FillInQueryTextBasedOnReportToGiverWithoutOrdering();
	EndIf;
	
	Result = Query.ExecuteBatch();
	HeaderAttributes = Result[Result.UBound() - 2].Select();
	GoodsTable  = Result[Result.UBound() - 1].Unload();
	OrdersTable  = Result[Result.UBound()].Unload();
	
	If HeaderAttributes.Next() Then
		
		If HeaderAttributes.MultipleSubcontractingPurchaseOrders Then
			Raise NStr("vi = 'Trong bảng kê dành cho người đặt ký gửi, đã chỉ ra đơn hàng của người đặt ký gửi mà có liên quan với các đơn hàng dành cho người nhận gia công khác nhau. Không thể nhập trên cơ sở của bảng kê dành cho người đặt ký gửi.';
						|ru = 'В отчете давальцу указаны заказы давальца, связанные с разными заказами переработчику. Ввод на основании отчета давальцу невозможен.';
						|en = 'The ""Consumption report — subcontracting services delivered"" includes subcontracting sales orders related to different subcontracting purchase orders. Cannot generate documents based on the ""Consumption report — subcontracting services delivered"".'; fa = 'The ""Consumption report — subcontracting services delivered"" includes subcontracting sales orders related to different subcontracting purchase orders. Cannot generate documents based on the ""Consumption report — subcontracting services delivered"".';
						|it = 'В отчете давальцу указаны заказы давальца, связанные с разными заказами переработчику. Ввод на основании отчета давальцу невозможен.';
						|pl = 'The ""Consumption report — subcontracting services delivered"" includes subcontracting sales orders related to different subcontracting purchase orders. Cannot generate documents based on the ""Consumption report — subcontracting services delivered"".';
						|tr = 'Tüketim raporu-Verilen fason hizmetleri''nde, fason satın alma siparişleriyle ilgili farklı siparişler belirtilmiştir. Tüketim raporu-Verilen fason hizmetleri  yeni belgeye aktaramazsınız.'");
		EndIf;
		
		FillPropertyValues(ThisObject, HeaderAttributes);
		
		PurchasesServerCall.FillInBankAccountsUnderAgreement(
			Contract,
			CompanyBankAccount,
			CounterpartyBankAccount);
		
		If GetFunctionalOption("UseReceiptForMultipleOrders") Then
			SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
		EndIf;
		
	EndIf;
	
	FillInSubcontractPurchaseOrderInGiverSGoods(GoodsTable, OrdersTable);
	
	ListOfGroups = New Array;
	
	For Each CurrentData In GoodsTable Do
		
		If CurrentData.SideAndIntermediateRelease Then
			FillPropertyValues(SideAndIntermediateRelease.Add(), CurrentData);
		Else
			
			FillPropertyValues(ManufacturedProducts.Add(), CurrentData);
			If ByOrders Then
				ListOfGroups.Add(CurrentData.CostGroupNumber);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages", BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	AccountingAccountParameters = Documents.SubcontractorReport2_5.AccountingAccountSettings_();
	GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting(
		StructureOfActions,
		AccountingAccountParameters,
		"Object.ManufacturedProducts");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(ManufacturedProducts, StructureOfActions, CachedValues);
	
	GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting(
		StructureOfActions,
		AccountingAccountParameters,
		"Object.SideAndIntermediateRelease");
	BatchProcessingOfTablePartServer.TreatTS(SideAndIntermediateRelease, StructureOfActions, CachedValues);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SubcontractorReport2_5));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.ManufacturedProducts);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.SideAndIntermediateRelease);
	
	If ByOrders Then
		Documents.SubcontractorReport2_5.FillInProductsMaterialsServicesOnRequest(ThisObject, ListOfGroups, "MaterialsAndWorks, Services");
	Else
		InitializeDocumentAfterAddingProducts();
	EndIf;
	
	DocumentAmount = Services.Total("AmountIncludingVAT");
	
EndProcedure

Function FillInQueryTextBasedOnReportToOrderGiver()
	
	QueryText =
	"SELECT ALLOWED
	|	OrdersToSubcontractPurchaseOrder.Ref AS MaterialProviderOrder
	|INTO GiverSOrders
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TableOfGoods
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5 AS DocumentOrders
	|	ON DocumentOrders.Ref = TableOfGoods.MaterialProviderOrder
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5 AS OrdersToSubcontractPurchaseOrder
	|	ON OrdersToSubcontractPurchaseOrder.Basis = DocumentOrders.Basis
	|	
	|WHERE
	|	TableOfGoods.Ref = &Basis
	|
	|GROUP BY
	|	OrdersToSubcontractPurchaseOrder.Ref
	|
	|INDEX BY
	|	MaterialProviderOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OrdersToProcessor.Ref                    AS SubcontractOrder,
	|	OrdersToProcessor.Organization               AS Organization,
	|	OrdersToProcessor.Department             AS Department,
	|	OrdersToProcessor.SalesOpportunity                    AS SalesOpportunity,
	|	OrdersToProcessor.GroupCosts         AS GroupCosts,
	|	OrdersToProcessor.ProcessingServices       AS ProcessingServices,
	|	OrdersToProcessor.Partner                   AS Partner,
	|	OrdersToProcessor.Counterparty                AS Counterparty,
	|	OrdersToProcessor.Contract                   AS Contract,
	|	OrdersToProcessor.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
	|	OrdersToProcessor.LineOfBusiness   AS LineOfBusiness,
	|	OrdersToProcessor.Contract.ARAPCurrency AS ARAPCurrency,
	|	OrdersToProcessor.Currency                    AS Currency,
	|	OrdersToProcessor.PriceIncludesVAT           AS PriceIncludesVAT,
	|	OrdersToProcessor.VATTaxation        AS VATTaxation,
	|	OrdersToProcessor.PurchaseForActivity    AS PurchaseForActivity,
	|	OrdersToProcessor.PriceKind                   AS PriceKind,
	|	OrdersToProcessor.RegisterVendorPrices AS RegisterVendorPrices,
	|	OrdersToProcessor.PaymentMethod               AS PaymentMethod,
	|	OrdersToProcessor.ARAPObjectSettings           AS ARAPObjectSettings,
	|	OrdersToProcessor.ForeignCurrencyTransaction             AS ForeignCurrencyTransaction,
	|	OrdersToProcessor.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	OrdersToProcessor.BankAccount            AS CompanyBankAccount
	|INTO OrdersToProcessor
	|FROM
	|	Document.MaterialProviderOrder2_5 AS OrderData
	|	
	|	INNER JOIN Document.SubcontractOrder2_5 AS OrdersToProcessor
	|	ON OrdersToProcessor.Ref = OrderData.Basis
	|
	|WHERE
	|	OrderData.Ref IN
	|		(SELECT
	|			GiverSOrders.MaterialProviderOrder AS MaterialProviderOrder
	|		FROM
	|			GiverSOrders AS GiverSOrders)
	|	AND OrdersToProcessor.Posted
	|	AND OrdersToProcessor.Status IN(
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed))
	|
	|GROUP BY
	|	OrdersToProcessor.Ref,
	|	OrdersToProcessor.Organization,
	|	OrdersToProcessor.Department,
	|	OrdersToProcessor.SalesOpportunity,
	|	OrdersToProcessor.GroupCosts,
	|	OrdersToProcessor.ProcessingServices,
	|	OrdersToProcessor.Partner,
	|	OrdersToProcessor.Counterparty,
	|	OrdersToProcessor.Contract,
	|	OrdersToProcessor.MethodOfAllocatingFinishedProductCosts,
	|	OrdersToProcessor.LineOfBusiness,
	|	OrdersToProcessor.Contract.ARAPCurrency,
	|	OrdersToProcessor.Currency,
	|	OrdersToProcessor.PriceIncludesVAT,
	|	OrdersToProcessor.VATTaxation,
	|	OrdersToProcessor.PurchaseForActivity,
	|	OrdersToProcessor.PriceKind,
	|	OrdersToProcessor.RegisterVendorPrices,
	|	OrdersToProcessor.PaymentMethod,
	|	OrdersToProcessor.ARAPObjectSettings,
	|	OrdersToProcessor.ForeignCurrencyTransaction,
	|	OrdersToProcessor.FinancialAccountingGroup,
	|	OrdersToProcessor.BankAccount
	|
	|INDEX BY
	|	SubcontractOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Output Products of the Order
	|SELECT ALLOWED
	|	TableOfGoods.Ref                   AS SubcontractOrder,
	|	TableOfGoods.RowCode                AS RowCode,
	|	TableOfGoods.Products             AS Products,
	|	TableOfGoods.Characteristic           AS Characteristic,
	|	TableOfGoods.Purpose               AS Purpose,
	|	TableOfGoods.CostGroupNumber        AS CostGroupNumber,
	|	UNDEFINED                            AS ProductionStage,
	|	TableOfGoods.BillOfMaterials             AS BillOfMaterials,
	|	TableOfGoods.Recipient               AS Recipient,
	|	TableOfGoods.ToExpenseAs         AS ToExpenseAs,
	|	TableOfGoods.ExpenseItem           AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses        AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	UNDEFINED                            AS GLAccountSettings,
	|	CASE
	|		WHEN TableOfGoods.CostSharePerUnit = 0
	|			THEN CAST(TableOfGoods.CostShare / TableOfGoods.Count AS NUMBER(15,3))
	|		ELSE TableOfGoods.CostSharePerUnit
	|	END                                   AS CostSharePerUnit,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	0                                       AS Price,
	|	FALSE                                    AS SideAndIntermediateRelease
	|INTO Products_1
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref IN
	|		(SELECT
	|			OrdersToProcessor.SubcontractOrder
	|		FROM
	|			OrdersToProcessor AS OrdersToProcessor)
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.RowCode,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.BillOfMaterials,
	|	TableOfGoods.Recipient,
	|	TableOfGoods.ToExpenseAs,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN TableOfGoods.CostSharePerUnit = 0
	|			THEN CAST(TableOfGoods.CostShare / TableOfGoods.Count AS NUMBER(15,3))
	|		ELSE TableOfGoods.CostSharePerUnit
	|	END
	|
	|UNION ALL
	|
	// Output Stage Products
	|SELECT
	|	Data_Stage.SubcontractOrder          AS SubcontractOrder,
	|	TableOfGoods.RowCode                AS RowCode,
	|	TableOfGoods.Products             AS Products,
	|	TableOfGoods.Characteristic           AS Characteristic,
	|	TableOfGoods.Purpose               AS Purpose,
	|	OrderReferences.CostGroupNumber    AS CostGroupNumber,
	|	TableOfGoods.Ref                   AS ProductionStage,
	|	Data_Stage.BillOfMaterials                AS BillOfMaterials,
	|	TableOfGoods.Recipient               AS Recipient,
	|	TableOfGoods.ToExpenseAs         AS ToExpenseAs,
	|	TableOfGoods.ExpenseItem           AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses        AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings     AS GLAccountSettings,
	|	CASE
	|		WHEN TableOfGoods.CostSharePerUnit = 0
	|			THEN CAST(TableOfGoods.CostShare / TableOfGoods.Count AS NUMBER(15,3))
	|		ELSE TableOfGoods.CostSharePerUnit
	|	END                                   AS CostSharePerUnit,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	0                                       AS Price,
	|	FALSE                                    AS SideAndIntermediateRelease
	|FROM
	|	Document.ProductionStage2_2 AS Data_Stage
	|	
	|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS TableOfGoods
	|	ON TableOfGoods.Ref = Data_Stage.Ref
	|
	|	INNER JOIN Document.SubcontractOrder2_5.References AS OrderReferences
	|	ON OrderReferences.ReferenceOrder = Data_Stage.Ref
	|
	|WHERE
	|	Data_Stage.SubcontractOrder IN
	|		(SELECT
	|			OrdersToProcessor.SubcontractOrder
	|		FROM
	|			OrdersToProcessor AS OrdersToProcessor)
	|
	|GROUP BY
	|	Data_Stage.SubcontractOrder,
	|	TableOfGoods.RowCode,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose,
	|	OrderReferences.CostGroupNumber,
	|	TableOfGoods.Ref,
	|	Data_Stage.BillOfMaterials,
	|	TableOfGoods.Recipient,
	|	TableOfGoods.ToExpenseAs,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings,
	|	CASE
	|		WHEN TableOfGoods.CostSharePerUnit = 0
	|			THEN CAST(TableOfGoods.CostShare / TableOfGoods.Count AS NUMBER(15,3))
	|		ELSE TableOfGoods.CostSharePerUnit
	|	END
	|
	|UNION ALL
	|
	// By-Products of the Order
	|SELECT
	|	TableOfGoods.Ref                   AS SubcontractOrder,
	|	TableOfGoods.RowCode                AS RowCode,
	|	TableOfGoods.Products             AS Products,
	|	TableOfGoods.Characteristic           AS Characteristic,
	|	TableOfGoods.Purpose               AS Purpose,
	|	TableOfGoods.CostGroupNumber        AS CostGroupNumber,
	|	UNDEFINED                            AS ProductionStage,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
	|	TableOfGoods.Recipient               AS Recipient,
	|	TableOfGoods.ToExpenseAs         AS ToExpenseAs,
	|	TableOfGoods.ExpenseItem           AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses        AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	UNDEFINED                            AS GLAccountSettings,
	|	0                                       AS CostSharePerUnit,
	|	TableOfGoods.ProductCostElement        AS ProductCostElement,
	|	TableOfGoods.Price                     AS Price,
	|	TRUE                                  AS SideAndIntermediateRelease
	|FROM
	|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref IN
	|		(SELECT
	|			OrdersToProcessor.SubcontractOrder
	|		FROM
	|			OrdersToProcessor AS OrdersToProcessor)
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.RowCode,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.Recipient,
	|	TableOfGoods.ToExpenseAs,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.Price
	|
	|UNION ALL
	|
	// Stage By-Products
	|SELECT
	|	Data_Stage.SubcontractOrder          AS SubcontractOrder,
	|	TableOfGoods.RowCode                AS RowCode,
	|	TableOfGoods.Products             AS Products,
	|	TableOfGoods.Characteristic           AS Characteristic,
	|	TableOfGoods.Purpose               AS Purpose,
	|	OrderReferences.CostGroupNumber    AS CostGroupNumber,
	|	TableOfGoods.Ref                   AS ProductionStage,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
	|	TableOfGoods.Recipient               AS Recipient,
	|	TableOfGoods.ToExpenseAs         AS ToExpenseAs,
	|	TableOfGoods.ExpenseItem           AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses        AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings     AS GLAccountSettings,
	|	0                                       AS CostSharePerUnit,
	|	TableOfGoods.ProductCostElement        AS ProductCostElement,
	|	TableOfGoods.Price                     AS Price,
	|	TRUE                                  AS SideAndIntermediateRelease
	|FROM
	|	Document.ProductionStage2_2 AS Data_Stage
	|	
	|	INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS TableOfGoods
	|	ON TableOfGoods.Ref = Data_Stage.Ref
	|
	|	INNER JOIN Document.SubcontractOrder2_5.References AS OrderReferences
	|	ON OrderReferences.ReferenceOrder = Data_Stage.Ref
	|
	|WHERE
	|	Data_Stage.SubcontractOrder IN
	|		(SELECT
	|			OrdersToProcessor.SubcontractOrder
	|		FROM
	|			OrdersToProcessor AS OrdersToProcessor)
	|
	|GROUP BY
	|	Data_Stage.SubcontractOrder,
	|	TableOfGoods.RowCode,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose,
	|	OrderReferences.CostGroupNumber,
	|	TableOfGoods.Ref,
	|	Data_Stage.BillOfMaterials,
	|	TableOfGoods.Recipient,
	|	TableOfGoods.ToExpenseAs,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings,
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.Price
	|
	|
	|INDEX BY
	|	SubcontractOrder,
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(OrdersToProcessor.SubcontractOrder)           AS SubcontractOrder,
	|	MIN(OrdersToProcessor.Organization)                  AS Organization,
	|	MIN(OrdersToProcessor.Counterparty)                   AS Counterparty,
	|	MIN(OrdersToProcessor.Partner)                      AS Partner,
	|	MIN(OrdersToProcessor.Contract)                      AS Contract,
	|	MIN(OrdersToProcessor.Contract.ARAPCurrency) AS ARAPCurrency,
	|	MIN(OrdersToProcessor.Department)                AS Department,
	|	MIN(OrdersToProcessor.SalesOpportunity)                       AS SalesOpportunity,
	|	MIN(OrdersToProcessor.GroupCosts)            AS GroupCosts,
	|	MIN(OrdersToProcessor.ProcessingServices)          AS ProcessingServices,
	|	MIN(OrdersToProcessor.MethodOfAllocatingFinishedProductCosts) AS MethodOfAllocatingFinishedProductCosts,
	|	MIN(OrdersToProcessor.LineOfBusiness)      AS LineOfBusiness,
	|	MIN(OrdersToProcessor.Currency)                       AS Currency,
	|	MIN(OrdersToProcessor.PriceIncludesVAT)              AS PriceIncludesVAT,
	|	MIN(OrdersToProcessor.VATTaxation)           AS VATTaxation,
	|	MIN(OrdersToProcessor.PurchaseForActivity)       AS PurchaseForActivity,
	|	MIN(OrdersToProcessor.PriceKind)                      AS PriceKind,
	|	MIN(OrdersToProcessor.RegisterVendorPrices) AS RegisterVendorPrices,
	|	MIN(OrdersToProcessor.PaymentMethod)                  AS PaymentMethod,
	|	MIN(OrdersToProcessor.ARAPObjectSettings)              AS ARAPObjectSettings,
	|	MIN(OrdersToProcessor.ForeignCurrencyTransaction)                AS ForeignCurrencyTransaction,
	|	MIN(OrdersToProcessor.FinancialAccountingGroup)       AS FinancialAccountingGroup,
	|	MIN(OrdersToProcessor.CompanyBankAccount)    AS CompanyBankAccount,
	|	COUNT(DISTINCT OrdersToProcessor.SubcontractOrder) > 1 AS MultipleSubcontractingPurchaseOrders,
	|	&Basis                                                AS DocumentBasis
	|FROM
	|	OrdersToProcessor AS OrdersToProcessor
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfGoods.Products            AS Products,
	|	TableOfGoods.Characteristic          AS Characteristic,
	|	TableOfGoods.Series                   AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef)            AS Purpose,
	|	VALUE(Document.SubcontractOrder2_5.EmptyRef)   AS SubcontractOrder,
	|	0                                      AS CostGroupNumber,
	|	EmptyTable.ProductionStage         AS ProductionStage,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)  AS Recipient,
	|	FALSE                                   AS ToExpenseAs,
	|	EmptyTable.ExpenseItem           AS ExpenseItem,
	|	EmptyTable.DimensionOfExpenses        AS DimensionOfExpenses,
	|	EmptyTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	0                                      AS CostSharePerUnit,
	|	0                                      AS CostShare,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	0                                      AS Price,
	|	0                                      AS Sum,
	|	0                                      AS RowCode,
	|	FALSE                                   AS SideAndIntermediateRelease,
	|	SUM(TableOfGoods.Count)       AS Count
	|FROM
	|	(
	// Goods of the report to the giver
	|	SELECT
	|		TableOfGoods.Products   AS Products,
	|		TableOfGoods.Characteristic AS Characteristic,
	|		TableOfGoods.Series          AS Series,
	|		TableOfGoods.Count     AS Count
	|	FROM
	|		Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TableOfGoods
	|	WHERE
	|		TableOfGoods.MaterialProviderOrder IN
	|			(SELECT
	|				GiverSOrders.MaterialProviderOrder AS SubcontractOrder
	|			FROM
	|				GiverSOrders AS GiverSOrders)
	|		AND TableOfGoods.Ref.Posted
	|	
	|	UNION ALL
	|	
	// Output items of the re-processor report
	|	SELECT
	|		TableOfGoods.Products   AS Products,
	|		TableOfGoods.Characteristic AS Characteristic,
	|		TableOfGoods.Series          AS Series,
	|		-TableOfGoods.Count    AS Count
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Ref.Posted
	|		AND TableOfGoods.Ref.SubcontractOrder IN
	|			(SELECT
	|				OrdersToProcessor.SubcontractOrder
	|			FROM
	|				OrdersToProcessor AS OrdersToProcessor)
	|	
	|	UNION ALL
	|	
	// By-products of the reworker's report
	|	SELECT
	|		TableOfGoods.Products   AS Products,
	|		TableOfGoods.Characteristic AS Characteristic,
	|		TableOfGoods.Series          AS Series,
	|		-TableOfGoods.Count    AS Count
	|	FROM
	|		Document.SubcontractorReport2_5.SideAndIntermediateRelease AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Ref.Posted
	|		AND TableOfGoods.Ref.SubcontractOrder IN
	|			(SELECT
	|				OrdersToProcessor.SubcontractOrder
	|			FROM
	|				OrdersToProcessor AS OrdersToProcessor)
	|	) AS TableOfGoods
	|
	|	LEFT JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS EmptyTable
	|	ON FALSE
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	EmptyTable.ProductionStage,
	|	EmptyTable.ExpenseItem,
	|	EmptyTable.DimensionOfExpenses,
	|	EmptyTable.AssetsLiabilitiesDimension
	|
	|HAVING
	|	SUM(TableOfGoods.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	StockBalance.PurchaseOrder    AS SubcontractOrder,
	|	StockBalance.Products       AS Products,
	|	StockBalance.Characteristic     AS Characteristic,
	|	Products_1.Purpose                AS Purpose,
	|	Products_1.CostGroupNumber         AS CostGroupNumber,
	|	Products_1.ProductionStage          AS ProductionStage,
	|	Products_1.BillOfMaterials              AS BillOfMaterials,
	|	Products_1.Recipient                AS Recipient,
	|	Products_1.ToExpenseAs          AS ToExpenseAs,
	|	Products_1.ExpenseItem            AS ExpenseItem,
	|	Products_1.DimensionOfExpenses         AS DimensionOfExpenses,
	|	Products_1.AssetsLiabilitiesDimension  AS AssetsLiabilitiesDimension,
	|	Products_1.GLAccountSettings      AS GLAccountSettings,
	|	Products_1.ProductCostElement         AS ProductCostElement,
	|	Products_1.CostSharePerUnit    AS CostSharePerUnit,
	|	Products_1.Price                      AS Price,
	|	Products_1.SideAndIntermediateRelease           AS SideAndIntermediateRelease,
	|	StockBalance.RowCode          AS RowCode,
	|	StockBalance.ToRegisterBalance AS Count
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(,
	|		PurchaseOrder IN
	|			(SELECT
	|				OrdersToProcessor.SubcontractOrder
	|			FROM
	|				OrdersToProcessor AS OrdersToProcessor)
	|	) AS StockBalance
	|	
	|	INNER JOIN Products_1 AS Products_1
	|	ON Products_1.SubcontractOrder = StockBalance.PurchaseOrder
	|	AND Products_1.RowCode = StockBalance.RowCode
	|	
	|	INNER JOIN Document.SubcontractOrder2_5 AS OrderData
	|	ON OrderData.Ref = StockBalance.PurchaseOrder
	|
	|	LEFT JOIN Catalog.Priorities AS CatPriorities
	|	ON CatPriorities.Ref = OrderData.Priority
	|
	|ORDER BY
	|	ISNULL(CatPriorities.AddlOrderingAttribute, 0)
	|";
	
	Return QueryText;
	
EndFunction

Function FillInQueryTextBasedOnReportToGiverWithoutOrdering()
	
	QueryText =
	"SELECT ALLOWED
	|	CatCompanies.Ref            AS Organization,
	|	CatCounterparties.Ref            AS Counterparty,
	|	CatCounterparties.Partner           AS Partner,
	|	CatContracts.Ref               AS Contract,
	|	CASE
	|		WHEN CatContracts.LineOfBusiness IS NULL
	|			THEN ReportToMaterialProvider2_5.LineOfBusiness
	|		ELSE CatContracts.LineOfBusiness
	|	END                            AS LineOfBusiness,
	|	CatContracts.Department        AS Department,
	|	CatContracts.ARAPCurrency AS ARAPCurrency,
	|	ReportToMaterialProvider2_5.Currency          AS Currency,
	|	ReportToMaterialProvider2_5.SalesOpportunity          AS SalesOpportunity,
	|	ReportToMaterialProvider2_5.Number           AS IncomingDocumentNumber,
	|	ReportToMaterialProvider2_5.Date            AS IncomingDocumentDate,
	|	FALSE                             AS MultipleSubcontractingPurchaseOrders,
	|	ReportToMaterialProvider2_5.Ref  AS DocumentBasis
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS ReportToMaterialProvider2_5
	|	
	|	LEFT JOIN Catalog.Counterparties AS MaterialProvider
	|	ON MaterialProvider.Ref = ReportToMaterialProvider2_5.Counterparty
	|	
	|	LEFT JOIN Catalog.Companies AS CatCompanies
	|	ON CatCompanies.TIN = MaterialProvider.TIN
	|	AND CatCompanies.CRTR = MaterialProvider.CRTR
	|	AND NOT CatCompanies.DeletionMark
	|	
	|	LEFT JOIN Catalog.Companies AS Toller
	|	ON Toller.Ref = ReportToMaterialProvider2_5.Organization
	|	
	|	LEFT JOIN Catalog.Counterparties AS CatCounterparties
	|	ON CatCounterparties.TIN = Toller.TIN
	|	AND CatCounterparties.CRTR = Toller.CRTR
	|	AND NOT CatCounterparties.DeletionMark
	|	
	|	LEFT JOIN Catalog.CounterpartyContracts AS MaterialProviderContract
	|	ON MaterialProviderContract.Ref = ReportToMaterialProvider2_5.Contract
	|
	|	LEFT JOIN Catalog.CounterpartyContracts AS CatContracts
	|	ON CatContracts.Organization = CatCompanies.Ref
	|	AND CatContracts.Counterparty = CatCounterparties.Ref
	|	AND CatContracts.Number = MaterialProviderContract.Number
	|	AND CatContracts.Date = MaterialProviderContract.Date
	|	AND CatContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND NOT CatContracts.DeletionMark
	|
	|WHERE
	|	ReportToMaterialProvider2_5.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfGoods.Products      AS Products,
	|	TableOfGoods.Characteristic    AS Characteristic,
	|	TableOfGoods.Series             AS Series,
	|	FALSE                             AS SideAndIntermediateRelease,
	|	SUM(TableOfGoods.Count) AS Count
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref = &Basis
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	StockBalance.PurchaseOrder     AS SubcontractOrder,
	|	StockBalance.Products        AS Products,
	|	StockBalance.Characteristic      AS Characteristic,
	|	StockBalance.RowCode           AS RowCode,
	|	StockBalance.ToRegisterBalance AS Count
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(, FALSE) AS StockBalance
	|";
	
	Return QueryText;
	
EndFunction

Procedure FillInSubcontractPurchaseOrderInGiverSGoods(GoodsTable, OrdersTable)
	
	If OrdersTable.Count() = 0 Then
		Return;
	EndIf;
	
	GoodsTable.Indexes.Add("Products, Characteristic, RowCode");
	
	For Each SubcontractPurchaseOrderLineForProcessor In OrdersTable Do
		
		QuantityOfSubcontractPurchaseOrderToProcessor = SubcontractPurchaseOrderLineForProcessor.Count;
		
		Filter =
			New Structure(
				"Products, Characteristic, RowCode",
				SubcontractPurchaseOrderLineForProcessor.Products,
				SubcontractPurchaseOrderLineForProcessor.Characteristic,
				0);
		
		For Each CurrentData In GoodsTable.FindRows(Filter) Do
			
			If CurrentData.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(QuantityOfSubcontractPurchaseOrderToProcessor, CurrentData.Count);
			
			NewRow = GoodsTable.Add();
			FillPropertyValues(NewRow, CurrentData);
			FillPropertyValues(NewRow, SubcontractPurchaseOrderLineForProcessor);
			
			NewRow.Count    = Count;
			NewRow.Sum         = NewRow.Count * NewRow.Price;
			NewRow.CostShare = NewRow.Count * NewRow.CostSharePerUnit;
			
			CurrentData.Count = CurrentData.Count - Count;
			
			QuantityOfSubcontractPurchaseOrderToProcessor    = QuantityOfSubcontractPurchaseOrderToProcessor - NewRow.Count;
			
			If QuantityOfSubcontractPurchaseOrderToProcessor = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	GoodsTable.Indexes.Clear();
	
	Filter = New Structure("Count", 0);
	For Each CurrentData In GoodsTable.FindRows(Filter) Do
		GoodsTable.Delete(CurrentData);
	EndDo;
	
EndProcedure

#EndRegion

Procedure InitializeDocumentBeforeFillingItOut()
	
	BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5;
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	ProcessingServices =
		?(ValueIsFilled(ProcessingServices),
			ProcessingServices,
			Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Currency               = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	ARAPCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(ARAPCurrency);
	
	SelectionOfPriceType = New Structure;
	SelectionOfPriceType.Insert("PriceIncludesVAT",                 PriceIncludesVAT);
	SelectionOfPriceType.Insert("UseForIssuingProductsWorksAndServicesAtFixedCost", True);
	PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(PriceKind, SelectionOfPriceType);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	
	If Not ValueIsFilled(CompanyBankAccount) Or Not ValueIsFilled(CounterpartyBankAccount) Then
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract,
			?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
			?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount= CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	MaximumRowCodeProducts = 0;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	GroupCosts =
		?(ValueIsFilled(GroupCosts),
			GroupCosts,
			Enums.CostGroupingsInTollingOrder.NoGrouping);
	
	FillParameters = Documents.SubcontractorReport2_5.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	FillParameters = Documents.SubcontractorReport2_5.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Services, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Services,
		CachedValues);
	
	ContractDetails_ = "ContractType, PurchaseRegistrationOption";
	ContractDetails_ = Common.ObjectAttributesValues(Contract, ContractDetails_);
	BusinessOperation = Catalogs.CounterpartyContracts.BusinessOperation(ContractDetails_.ContractType, ContractDetails_.PurchaseRegistrationOption);
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5;
	EndIf;
	
EndProcedure

Procedure InitializeDocumentAfterAddingProducts()
	
	Assignments = ManufacturedProducts.FindRows(New Structure("Purpose", Catalogs.Assignments.EmptyRef()));
	If Not Assignments.Count() = ManufacturedProducts.Count()
		And GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments;
	Else
		GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts;
	EndIf;
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(ThisObject, Documents.SubcontractorReport2_5);
	
	ProductData_2 = New Array;
	For Each StringOutputProducts In ManufacturedProducts Do
		
		MaximumNumberOfCostGroup = MaximumNumberOfCostGroup + 1;
		StringOutputProducts.CostGroupNumber = MaximumNumberOfCostGroup;
		
		ProductData =
			ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
				ThisObject,
				StringOutputProducts,
				BOMSelectionParameters);
		
		ProductData.Insert("CurrentSpecification", StringOutputProducts.BillOfMaterials);
			
		ProductData_2.Add(ProductData);
		
	EndDo;
	
	ProductDataManagement.FillInSpecificationInLines(
		ManufacturedProducts,
		ProductData_2,
		BOMSelectionParameters);
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	RefillInventoryKinds =
		InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
		Or CheckChangesToDocumentDetails();
	
	DistributeGTD = False;
	
	#Region InventoryOwnerAttributesProducts
	
	TempTablesManager = TemporaryProductTables();
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckProductChanges(TempTablesManager) Then
		
		TableTypesOfInventoryItems = TableToFillInTypesOfProductStocks(TempTablesManager);
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, TableTypesOfInventoryItems);
		InventoryOwnerAttributesProducts.Load(TableTypesOfInventoryItems);
		
		DistributeGTD = True;
		
	EndIf;
	
	#EndRegion
	
	#Region InventoryOwnerAttributesMaterials
	
	TempTablesManager = TemporaryMaterialTables();
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangingMaterials(TempTablesManager) Then

		FillParameters = ParametersForFillingInventoryTypes("UsedMaterials");
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(
			ThisObject,
			TempTablesManager,
			Cancel,
			FillParameters);
		
		InventoryOwnerAttributesMaterials.GroupBy(
			"ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber",
			"Count, QuantityByGBRN");
		
		FillInAdditionalColumnsOfTypesOfStocksOfMaterials(TempTablesManager);
		
		DistributeGTD = True;
		
	EndIf;
	
	#EndRegion
	
	If Not Cancel Then
		
		If DistributeGTD Then
			DistributeCCDNumbers(Cancel);
		EndIf;
		
		TMCommonUse.FillInDocumentIDs(
			ThisObject,
			"InventoryOwnerAttributesProducts,InventoryOwnerAttributesMaterials");
		
	EndIf;
	
EndProcedure

Function ParametersForFillingInventoryTypes(TSName, TempTablesManager = Undefined)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.SelectTypesOfStocksForIntercampany = False;
	FillParameters.WithoutSelectionByCCDNumbers              = True;
	
	FilterInventoryType = FillParameters.SelectionOfStockTypes_.InventoryType;
	FilterInventoryType.Clear();
	FilterInventoryType.Add(Enums.InventoryTypes.OwnGoods);
	FilterInventoryType.Add(Enums.InventoryTypes.Work_5);
	FilterInventoryType.Add(Enums.InventoryTypes.SubcontractorProducts);
	FilterInventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	FilterInventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	FilterInventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	FilterInventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	If TSName = "UsedMaterials" Then
		
		FillParameters.NameTSTypesOfStocks = "InventoryOwnerAttributesMaterials";
		
		FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
		
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "AccordingToSettingsOfProductionContract");
		
		FillParameters.ThereIsTableOfInventoryTypes = True;
		FillParameters.NameOfInventoryTypeTable  = "TTIncomingTypesOfProductInventory";
		
	ElsIf Not TSName = "Posting" Then
		
		ExceptionText = NStr("vi = 'Sai tên phần bảng dạng vật tư: ""%TSName%""';
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

Function TemporaryProductTables()
	
	Query = New Query(
	"SELECT
	|	TableOfGoods.LineNumber + &OrderOfManufactureOfProduct AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	0 AS QuantityByGBRN,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs,
	|	TableOfGoods.Recipient AS Recipient,
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings AS GLAccountSettings,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.CostGroupNumber AS CostGroupNumber,
	|	TableOfGoods.ProductionStage AS ProductionStage,
	|	TableOfGoods.RowCodeProducts AS RowCodeProducts,
	|	TableOfGoods.CostShare AS CostShare,
	|	TableOfGoods.Sum AS Sum,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber
	|INTO TTTableOutputProducts
	|FROM
	|	&OutputProductTable AS TableOfGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber + &OrderByProducts AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	0 AS QuantityByGBRN,
	|	TableOfGoods.ProductCostElement AS ProductCostElement,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs,
	|	TableOfGoods.Recipient AS Recipient,
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings AS GLAccountSettings,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.CostGroupNumber AS CostGroupNumber,
	|	TableOfGoods.ProductionStage AS ProductionStage,
	|	TableOfGoods.Sum AS Sum,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber
	|INTO TTTableByProducts
	|FROM
	|	&TableOfByProducts AS TableOfGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.BusinessOperation AS BusinessOperation,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs,
	|	TableOfGoods.Recipient AS Recipient,
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings AS GLAccountSettings,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.CostGroupNumber AS CostGroupNumber,
	|	TableOfGoods.ProductionStage AS ProductionStage,
	|	TableOfGoods.RowCodeProducts AS RowCodeProducts,
	|	TableOfGoods.CostShare AS CostShare,
	|	TableOfGoods.Sum AS Sum,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOutputProducts AS TableOfGoods
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.BusinessOperation AS BusinessOperation,
	|	TableOfGoods.ProductCostElement AS ProductCostElement,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs,
	|	TableOfGoods.Recipient AS Recipient,
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings AS GLAccountSettings,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.CostGroupNumber AS CostGroupNumber,
	|	TableOfGoods.ProductionStage AS ProductionStage,
	|	0 AS RowCodeProducts,
	|	0 AS CostShare,
	|	TableOfGoods.Sum AS Sum,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|FROM
	|	TTTableByProducts AS TableOfGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.ProductCostElement AS ProductCostElement,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs,
	|	TableTypesOfStocks_.Recipient AS Recipient,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.CostGroupNumber AS CostGroupNumber,
	|	TableTypesOfStocks_.ProductionStage AS ProductionStage,
	|	TableTypesOfStocks_.RowCodeProducts AS RowCodeProducts,
	|	TableTypesOfStocks_.CostShare AS CostShare,
	|	TableTypesOfStocks_.Sum AS Sum
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.ProductCostElement AS ProductCostElement,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs,
	|	TableTypesOfStocks_.Recipient AS Recipient,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.CostGroupNumber AS CostGroupNumber,
	|	TableTypesOfStocks_.ProductionStage AS ProductionStage,
	|	TableTypesOfStocks_.RowCodeProducts AS RowCodeProducts,
	|	TableTypesOfStocks_.CostShare AS CostShare,
	|	TableTypesOfStocks_.Sum AS Sum
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTableOutputProducts
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTableByProducts
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTypesOfStocks");
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	DocumentTables = DocumentTables();
	
	Query.SetParameter("Date",					Date);
	Query.SetParameter("OutputProductTable",	DocumentTables.ManufacturedProducts);
	Query.SetParameter("TableOfByProducts",	DocumentTables.SideAndIntermediateRelease);
	Query.SetParameter("TableTypesOfStocks_",		InventoryOwnerAttributesProducts);
	Query.SetParameter("OrderOfManufactureOfProduct",	OrderOfTS("ManufacturedProducts"));
	Query.SetParameter("OrderByProducts",	OrderOfTS("SideAndIntermediateRelease"));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Function TemporaryMaterialTables()
	
	Query = New Query(
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	UNDEFINED AS Terms,
	|	UNDEFINED AS TransferAgreement,
	|	&Contract AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	TableOfGoods.ProductCostElement AS ProductCostElement,
	|	TableOfGoods.CostGroupNumber AS CostGroupNumber,
	|	TableOfGoods.ProductionStage AS ProductionStage,
	|	TableOfGoods.RowID AS RowID,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfMaterials AS TableOfGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.ProductCostElement AS ProductCostElement,
	|	TableOfGoods.CostGroupNumber AS CostGroupNumber,
	|	TableOfGoods.ProductionStage AS ProductionStage,
	|	TableOfGoods.RowID AS RowID,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	&Contract AS Warehouse,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	NOT ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.ProductCostElement AS ProductCostElement,
	|	TableOfGoods.CostGroupNumber AS CostGroupNumber,
	|	TableOfGoods.ProductionStage AS ProductionStage,
	|	TableOfGoods.RowID AS RowID,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	Dimension.StorageLocation AS Warehouse,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END                                         AS QuantityByGBRN,
	|	TableTypesOfStocks_.ProductCostElement          AS ProductCostElement,
	|	TableTypesOfStocks_.CostGroupNumber          AS CostGroupNumber,
	|	TableTypesOfStocks_.ProductionStage           AS ProductionStage,
	|	TableTypesOfStocks_.RowID        AS RowID
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesAndMaterials AS TableTypesOfStocks_
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products                        AS Products,
	|	Dimension.Characteristic                      AS Characteristic,
	|	Dimension.Series                               AS Series,
	|	UNDEFINED                                  AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED                                  AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	VALUE(Catalog.VATRates.EmptyRef)   AS VATRate,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
	|	TableTypesOfStocks_.ProductCostElement          AS ProductCostElement,
	|	TableTypesOfStocks_.CostGroupNumber          AS CostGroupNumber,
	|	TableTypesOfStocks_.ProductionStage           AS ProductionStage,
	|	TableTypesOfStocks_.RowID        AS RowID,
	|	0                                             AS AmountIncludingVAT,
	|	0                                             AS VATAmount,
	|	0                                             AS CommissionAmount,
	|	0                                             AS AmountVATRemuneration,
	|	CASE
	|		WHEN ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN Dimension.StorageLocation
	|		ELSE &Contract
	|	END                                         AS OriginWarehouse,
	|	CASE
	|		WHEN ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN Dimension.StorageLocation
	|		ELSE &Contract
	|	END                                         AS Warehouse,
	|	FALSE                                          AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON Dimension.Products = ProductData_1.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTypesOfProductStocks.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTTypesOfProductStocks.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTTypesOfProductStocks.CCDNumber AS CCDNumber,
	|	TTTypesOfProductStocks.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TTTypesOfProductStocks.QuantityByGBRN
	|	END AS QuantityByGBRN
	|INTO TTTypesOfProductStocks
	|FROM
	|	&TableTypesOfProductStocks AS TTTypesOfProductStocks
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ENDOFPERIOD(&Date, MONTH)                   AS Period,
	|	&Organization                                 AS Organization,
	|	TTTypesOfProductStocks.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTTypesOfProductStocks.InventoryOwnerAttribute              AS InventoryOwnerAttribute,
	|	TTTypesOfProductStocks.CCDNumber                AS CCDNumber,
	|	SUM(TTTypesOfProductStocks.Count)       AS Count,
	|	SUM(TTTypesOfProductStocks.QuantityByGBRN) AS QuantityByGBRN
	|INTO TTIncomingTypesOfProductInventory
	|FROM
	|	TTTypesOfProductStocks AS TTTypesOfProductStocks
	|GROUP BY
	|	TTTypesOfProductStocks.ItemsLocationAttributes,
	|	TTTypesOfProductStocks.InventoryOwnerAttribute,
	|	TTTypesOfProductStocks.CCDNumber
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTableOfGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTypesOfStocks
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTypesOfProductStocks
	|");
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	DocumentTables = DocumentTables();
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("TableOfMaterials", DocumentTables.MaterialsAndWorks);
	Query.SetParameter("TableTypesOfProductStocks", InventoryOwnerAttributesProducts);
	Query.SetParameter("TableTypesAndMaterials", InventoryOwnerAttributesMaterials);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
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
	|			THEN VALUE(Enum.InventoryTypes.SubcontractorProducts)
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
	|	TableOfGoods.ProductCostElement							AS ProductCostElement,
	|	TableOfGoods.CostGroupNumber							AS CostGroupNumber,
	|	TableOfGoods.ToExpenseAs								AS ToExpenseAs,
	|	TableOfGoods.ProductionStage								AS ProductionStage,
	|	TableOfGoods.RowCodeProducts							AS RowCodeProducts,
	|	TableOfGoods.ExpenseItem								AS ExpenseItem,
	|	TableOfGoods.ItemsLocationAttributes					AS ItemsLocationAttributes,
	|	TableOfGoods.DimensionOfExpenses							AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension						AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings							AS GLAccountSettings,
	|	TableOfGoods.RowID							AS RowID,
	|	TableOfGoods.CCDNumber										AS CCDNumber,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)				AS CurViewOfStocks,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)				AS InventoryOwnerAttribute,
	|	SUM(TableOfGoods.Count)							AS Count,
	|	SUM(TableOfGoods.QuantityByGBRN)						AS QuantityByGBRN,
	|	SUM(TableOfGoods.CostShare)							AS CostShare,
	|	SUM(TableOfGoods.Sum)									AS Sum,
	|	FALSE														AS ThisIsReusablePackage
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	NOT TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|GROUP BY
	|	TableOfGoods.BusinessOperation,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose,
	|	CASE
	|		WHEN ISNULL(TableOfGoods.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		WHEN TRUE
	|			THEN VALUE(Enum.InventoryTypes.SubcontractorProducts)
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
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.ToExpenseAs,
	|	TableOfGoods.ProductionStage,
	|	TableOfGoods.RowCodeProducts,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings,
	|	TableOfGoods.RowID,
	|	TableOfGoods.CCDNumber
	|
	|UNION ALL
	|
	|SELECT
	|	&Organization												AS Organization,
	|	&Currency														AS Currency,
	|	&TaxationOfOrganization									AS TaxationOfOrganization,
	|	UNDEFINED												AS Terms,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)	AS VATTaxation,
	|	TableOfGoods.BusinessOperation						AS BusinessOperation,
	|	MAX(TableOfGoods.LineNumber)						AS LineNumber,
	|	TableOfGoods.Products									AS Products,
	|	TableOfGoods.Characteristic								AS Characteristic,
	|	TableOfGoods.Purpose									AS Purpose,
	|	VALUE(Enum.InventoryTypes.Work_5)					AS InventoryType,
	|	UNDEFINED												AS GoodsOwner,
	|	UNDEFINED												AS Counterparty,
	|	UNDEFINED												AS Contract,
	|	TableOfGoods.Recipient									AS Recipient,
	|	TableOfGoods.ProductCostElement							AS ProductCostElement,
	|	TableOfGoods.CostGroupNumber							AS CostGroupNumber,
	|	TableOfGoods.ToExpenseAs								AS ToExpenseAs,
	|	TableOfGoods.ProductionStage								AS ProductionStage,
	|	TableOfGoods.RowCodeProducts							AS RowCodeProducts,
	|	TableOfGoods.ExpenseItem								AS ExpenseItem,
	|	TableOfGoods.ItemsLocationAttributes					AS ItemsLocationAttributes,
	|	TableOfGoods.DimensionOfExpenses							AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension						AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings							AS GLAccountSettings,
	|	TableOfGoods.RowID							AS RowID,
	|	TableOfGoods.CCDNumber										AS CCDNumber,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)				AS CurViewOfStocks,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)				AS InventoryOwnerAttribute,
	|	SUM(TableOfGoods.Count)							AS Count,
	|	SUM(TableOfGoods.QuantityByGBRN)						AS QuantityByGBRN,
	|	SUM(TableOfGoods.CostShare)							AS CostShare,
	|	SUM(TableOfGoods.Sum)									AS Sum,
	|	FALSE														AS ThisIsReusablePackage
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableOfGoods.Products.TracedGoods
	|
	|GROUP BY
	|	TableOfGoods.BusinessOperation,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.Recipient,
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.ToExpenseAs,
	|	TableOfGoods.ProductionStage,
	|	TableOfGoods.RowCodeProducts,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings,
	|	TableOfGoods.RowID,
	|	TableOfGoods.CCDNumber
	|";
	
	Query.SetParameter("Date",						Date);
	Query.SetParameter("Organization",				Organization);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("TaxationOfOrganization",	VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Result = Query.ExecuteBatchWithIntermediateData();
	
	Return Result[0].Unload();
	
EndFunction

Function CheckChangesToDocumentDetails()
	
	AttributesNames = "Date, Organization, Partner, Contract";
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.Text =
	"SELECT
	|	&Organization	AS Organization,
	|	&Date			AS Date,
	|	&Partner		AS Partner,
	|	&Contract		AS Contract
	|INTO DocumentDataTable
	|";
	
	Query.SetParameter("Organization",	Organization);
	Query.SetParameter("Date",			Date);
	Query.SetParameter("Partner",		Partner);
	Query.SetParameter("Contract",		Contract);
	
	Query.Execute();
	
	Return InventoriesServer.CheckChangesToDocumentDetails(Query.TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges(TempTablesManager)
	
	Query = New Query(
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.BusinessOperation		AS BusinessOperation,
	|	TableOfGoods.ProductCostElement			AS ProductCostElement,
	|	TableOfGoods.ToExpenseAs				AS ToExpenseAs,
	|	TableOfGoods.Recipient					AS Recipient,
	|	TableOfGoods.ExpenseItem				AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|	TableOfGoods.RowID			AS RowID,
	|	TableOfGoods.CostGroupNumber			AS CostGroupNumber,
	|	TableOfGoods.ProductionStage				AS ProductionStage,
	|	TableOfGoods.RowCodeProducts			AS RowCodeProducts
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TableOfGoods.BusinessOperation		AS BusinessOperation,
	|		TableOfGoods.ProductCostElement			AS ProductCostElement,
	|		TableOfGoods.ToExpenseAs				AS ToExpenseAs,
	|		TableOfGoods.Recipient					AS Recipient,
	|		TableOfGoods.ExpenseItem				AS ExpenseItem,
	|		TableOfGoods.DimensionOfExpenses			AS DimensionOfExpenses,
	|		TableOfGoods.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|		TableOfGoods.RowID			AS RowID,
	|		TableOfGoods.CostGroupNumber			AS CostGroupNumber,
	|		TableOfGoods.ProductionStage				AS ProductionStage,
	|		TableOfGoods.RowCodeProducts			AS RowCodeProducts,
	|		TableOfGoods.Count					AS Count,
	|		TableOfGoods.CostShare				AS CostShare,
	|		TableOfGoods.Sum						AS Sum
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.BusinessOperation		AS BusinessOperation,
	|		TableTypesOfStocks_.ProductCostElement			AS ProductCostElement,
	|		TableTypesOfStocks_.ToExpenseAs				AS ToExpenseAs,
	|		TableTypesOfStocks_.Recipient					AS Recipient,
	|		TableTypesOfStocks_.ExpenseItem				AS ExpenseItem,
	|		TableTypesOfStocks_.DimensionOfExpenses			AS DimensionOfExpenses,
	|		TableTypesOfStocks_.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension,
	|		TableTypesOfStocks_.RowID			AS RowID,
	|		TableTypesOfStocks_.CostGroupNumber			AS CostGroupNumber,
	|		TableTypesOfStocks_.ProductionStage				AS ProductionStage,
	|		TableTypesOfStocks_.RowCodeProducts			AS RowCodeProducts,
	|		-TableTypesOfStocks_.Count					AS Count,
	|		-TableTypesOfStocks_.CostShare				AS CostShare,
	|		-TableTypesOfStocks_.Sum						AS Sum
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.BusinessOperation,
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.ToExpenseAs,
	|	TableOfGoods.Recipient,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.RowID,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.ProductionStage,
	|	TableOfGoods.RowCodeProducts
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.CostShare) <> 0
	|	OR SUM(TableOfGoods.Sum) <> 0
	|");
	
	Query.TempTablesManager = TempTablesManager;
	Result_Query = Query.Execute();
	
	Return Not Result_Query.IsEmpty();
	
EndFunction

Function CheckChangingMaterials(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ProductCostElement AS ProductCostElement,
	|	TableOfGoods.CostGroupNumber AS CostGroupNumber,
	|	TableOfGoods.ProductionStage AS ProductionStage,
	|	TableOfGoods.RowID AS RowID
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.ProductCostElement AS ProductCostElement,
	|		TableOfGoods.CostGroupNumber AS CostGroupNumber,
	|		TableOfGoods.ProductionStage AS ProductionStage,
	|		TableOfGoods.RowID AS RowID,
	|		TableOfGoods.Count AS Count
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ProductCostElement AS ProductCostElement,
	|		TableTypesOfStocks_.CostGroupNumber AS CostGroupNumber,
	|		TableTypesOfStocks_.ProductionStage AS ProductionStage,
	|		TableTypesOfStocks_.RowID AS RowID,
	|		-TableTypesOfStocks_.Count AS Count
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.ProductionStage,
	|	TableOfGoods.RowID
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|");
	
	Query.TempTablesManager = TempTablesManager;
	Result_Query = Query.Execute();
	
	Return Not Result_Query.IsEmpty();
	
EndFunction

Procedure FillInAdditionalColumnsOfTypesOfStocksOfMaterials(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.CostGroupNumber			AS CostGroupNumber,
	|	TableOfGoods.ProductCostElement			AS ProductCostElement,
	|	TableOfGoods.ProductionStage				AS ProductionStage,
	|	TableOfGoods.RowID			AS RowID,
	|	SUM(TableOfGoods.Count)			AS Count
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.CostGroupNumber,
	|	TableOfGoods.ProductionStage,
	|	TableOfGoods.ProductCostElement,
	|	TableOfGoods.RowID
	|
	|ORDER BY
	|	ItemsLocationAttributes
	|";
	
	SampleProducts_ = Query.Execute().Select();
	
	FilterOfProducts_ = New Structure("ItemsLocationAttributes");
	
	While SampleProducts_.Next() Do
		
		GoodsQuantity = SampleProducts_.Count;
		
		FillPropertyValues(FilterOfProducts_, SampleProducts_);
		
		For Each InventoryLine In InventoryOwnerAttributesMaterials.FindRows(FilterOfProducts_) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryOwnerAttributesMaterials.Add();
			FillPropertyValues(NewRow, SampleProducts_);
			FillPropertyValues(NewRow, InventoryLine, "InventoryOwnerAttribute, CCDNumber");
			
			NewRow.Count       = Count;
			NewRow.QuantityByGBRN = Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	RowFilter = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryOwnerAttributesMaterials.FindRows(RowFilter);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryOwnerAttributesMaterials.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure DistributeCCDNumbers(Cancel)
	
	// 1. Distribution of traceable CCD numbers.
	Result = DistributeCCDTraceableNumbers(Cancel);
	// 2. Distribution of untraceable CCD numbers.
	CCDNumbersAreSimpleToDistribute(Result.SpentCostGroupsAndGoodsMaterials,
		Result.SpentCostGroupsAndGoodsProducts, Cancel);
	
EndProcedure

Procedure CCDNumbersAreSimpleToDistribute(SpentCostGroupsAndGoodsMaterials, SpentCostGroupsAndGoodsProducts, Cancel)
	
	IndexFields = "CostGroupNumber,Products,Characteristic";
	
	QueryTexts = New Array;
	QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "MaterialsAndWorks", False, IndexFields));
	QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "InventoryOwnerAttributesProducts", False));
	QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "InventoryOwnerAttributesMaterials", False));
	
	QueryTexts.Add(
	"SELECT
	|	UsedProducts.CostGroupNumber,
	|	UsedProducts.ItemsLocationAttributes
	|INTO TTExcludedProducts
	|FROM
	|	&UsedProducts AS UsedProducts
	|INDEX BY
	|	CostGroupNumber,
	|	ItemsLocationAttributes");
	
	QueryTexts.Add(
	"SELECT
	|	InventoryOwnerAttributesProducts.CostGroupNumber							AS CostGroupNumber,
	|	InventoryOwnerAttributesProducts.ItemsLocationAttributes.Products		AS Products,
	|	InventoryOwnerAttributesProducts.ItemsLocationAttributes.Characteristic	AS Characteristic,
	|	SUM(InventoryOwnerAttributesProducts.Count)							AS Count
	|INTO TTInventoryTypesImportedProductsGrouped
	|FROM
	|	InventoryOwnerAttributesProducts AS InventoryOwnerAttributesProducts
	|
	|WHERE
	|	InventoryOwnerAttributesProducts.ItemsLocationAttributes.Products.KeepRecordsByCCD
	|	AND InventoryOwnerAttributesProducts.ItemsLocationAttributes.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	InventoryOwnerAttributesProducts.CostGroupNumber,
	|	InventoryOwnerAttributesProducts.ItemsLocationAttributes.Products,
	|	InventoryOwnerAttributesProducts.ItemsLocationAttributes.CHARACTERISTIC
	|
	|INDEX BY
	|	CostGroupNumber,
	|	Products,
	|	Characteristic
	|");
	
	QueryTexts.Add(
	"SELECT
	|	InventoryOwnerAttributesMaterials.CostGroupNumber	AS CostGroupNumber,
	|	InventoryOwnerAttributesMaterials.CCDNumber			AS CCDNumber,
	|	SUM(InventoryOwnerAttributesMaterials.Count)	AS Count
	|FROM
	|	InventoryOwnerAttributesMaterials AS InventoryOwnerAttributesMaterials
	|
	|WHERE
	|	InventoryOwnerAttributesMaterials.ItemsLocationAttributes.Products.KeepRecordsByCCD
	|	AND NOT InventoryOwnerAttributesMaterials.ItemsLocationAttributes.Products.TracedGoods
	|	AND InventoryOwnerAttributesMaterials.ItemsLocationAttributes.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND InventoryOwnerAttributesMaterials.CostGroupNumber IN
	|		(SELECT
	|			InventoryOwnerAttributesProducts.CostGroupNumber AS CostGroupNumber
	|		FROM
	|			InventoryOwnerAttributesProducts AS InventoryOwnerAttributesProducts
	|		WHERE
	|			InventoryOwnerAttributesProducts.ItemsLocationAttributes.Products.KeepRecordsByCCD
	|			AND NOT InventoryOwnerAttributesProducts.ItemsLocationAttributes.Products.TracedGoods
	|			AND InventoryOwnerAttributesProducts.ItemsLocationAttributes.Products.ItemsType IN
	|				(VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage)))
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			MaterialsAndWorks AS MaterialsAndWorks
	|		WHERE
	|			MaterialsAndWorks.CostGroupNumber = InventoryOwnerAttributesMaterials.CostGroupNumber
	|			AND MaterialsAndWorks.Products = InventoryOwnerAttributesMaterials.ItemsLocationAttributes.Products
	|			AND MaterialsAndWorks.Characteristic = InventoryOwnerAttributesMaterials.ItemsLocationAttributes.CHARACTERISTIC
	|			AND MaterialsAndWorks.Main
	|		)
	|
	|GROUP BY
	|	InventoryOwnerAttributesMaterials.CostGroupNumber,
	|	InventoryOwnerAttributesMaterials.CCDNumber
	|");
	
	QueryTexts.Add(
	"SELECT
	|	InventoryKinds.LineNumber									AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes.Products		AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic	AS Characteristic,
	|	TypesOfStocksGrouped.Count					AS QuantityByCostGroup,
	|	CASE
	|		WHEN InventoryKinds.ItemsLocationAttributes.Products.KeepRecordsByCCD
	|				AND NOT InventoryKinds.ItemsLocationAttributes.Products.TracedGoods
	|			THEN TRUE
	|		ELSE FALSE
	|	END													AS CCDAccounting,
	|	NOT ExcludedProducts.CostGroupNumber IS NULL		AS LineWasProcessedEarlier
	|FROM
	|	InventoryOwnerAttributesProducts AS InventoryKinds
	|		LEFT JOIN TTInventoryTypesImportedProductsGrouped AS TypesOfStocksGrouped
	|		ON InventoryKinds.CostGroupNumber = TypesOfStocksGrouped.CostGroupNumber
	|			AND InventoryKinds.ItemsLocationAttributes.Products = TypesOfStocksGrouped.Products
	|			AND InventoryKinds.ItemsLocationAttributes.CHARACTERISTIC = TypesOfStocksGrouped.Characteristic
	|		
	|		LEFT JOIN TTExcludedProducts AS ExcludedProducts
	|		ON InventoryKinds.CostGroupNumber = ExcludedProducts.CostGroupNumber
	|			AND InventoryKinds.ItemsLocationAttributes = ExcludedProducts.ItemsLocationAttributes
	|
	|ORDER BY
	|	LineNumber
	|");
	
	Query = New Query;
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("MaterialsAndWorks",		MaterialsAndWorks.Unload());
	Query.SetParameter("InventoryOwnerAttributesProducts",		InventoryOwnerAttributesProducts.Unload());
	Query.SetParameter("InventoryOwnerAttributesMaterials",	InventoryOwnerAttributesMaterials.Unload());
	Query.SetParameter("UsedProducts", SpentCostGroupsAndGoodsProducts);
	
	QueryResult		= Query.ExecuteBatch();
	ImportedMaterials		= QueryResult[QueryResult.UBound() - 1].Unload();
	OutputProductData	= QueryResult[QueryResult.UBound()].Unload();
	
	IndexOf = InventoryOwnerAttributesProducts.Count() - 1;
	
	RestrictGoodsReceiptWithoutCCDNumbers =
		AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(ManufacturedProducts, Date)
		Or AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(SideAndIntermediateRelease, Date)
		Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	
	ImportedProductsWithoutCCDNumber = New Map;
	
	While IndexOf >= 0 Do
		ProductStock_	= InventoryOwnerAttributesProducts[IndexOf]; // LineOfATabularSection
		AnalyticsData	= OutputProductData[ProductStock_.LineNumber - 1];
		
		If AnalyticsData.LineWasProcessedEarlier Then
			IndexOf = IndexOf - 1;
			
			Continue;
		ElsIf Not AnalyticsData.CCDAccounting
			Or ProductStock_.ToExpenseAs Then
			
			ProductStock_.CCDNumber = Undefined;
			
			IndexOf = IndexOf - 1;
			
			Continue;
			
		EndIf;
		
		RowFilter			= New Structure("CostGroupNumber", ProductStock_.CostGroupNumber);
		ContentLines	= ImportedMaterials.FindRows(RowFilter);
		
		QuantityIsAllocated	= 0;
		RemainsToAllocate	= ProductStock_.Count;
		
		ProductQuantityByStockType	= ProductStock_.Count;
		QuantityOfProductByCostGroup	= AnalyticsData.QuantityByCostGroup;
		
		For Each MaterialString In ContentLines Do
			ProductStock_.CCDNumber	= MaterialString.CCDNumber;
			ProductStock_.Count	 = MaterialString.Count * ProductQuantityByStockType
										/ QuantityOfProductByCostGroup;
			
			RemainsToAllocate = RemainsToAllocate - ProductStock_.Count;
			
			If RemainsToAllocate > 0 Then
				NewRow = InventoryOwnerAttributesProducts.Insert(IndexOf);
				FillPropertyValues(NewRow, ProductStock_);
				
				QuantityIsAllocated = QuantityIsAllocated + ProductStock_.Count;
			Else
				Break;
			EndIf;
		EndDo;
		
		If ProductQuantityByStockType - QuantityIsAllocated > 0 Then
			ProductStock_.Count = ProductQuantityByStockType - QuantityIsAllocated;
		EndIf;
		
		If RestrictGoodsReceiptWithoutCCDNumbers
			And Not ValueIsFilled(ProductStock_.CCDNumber) Then
			
			ProductWithoutCCDNumber = New Structure("CostGroupNumber, Products, Characteristic");
			ProductWithoutCCDNumber.CostGroupNumber = ProductStock_.CostGroupNumber;
			
			FillPropertyValues(ProductWithoutCCDNumber, AnalyticsData);
			
			ImportedProductsWithoutCCDNumber.Insert(ProductWithoutCCDNumber);
			
		EndIf;
		
		IndexOf = IndexOf - 1;
	EndDo;
	
	If ImportedProductsWithoutCCDNumber.Count() Then
		
		MessageTemplate = NStr("vi = 'Không thể chọn ""Số tờ khai hải quan"" đối với sản phẩm ""%1"" của nhóm chi phí ""%2"".';
								|ru = 'Не удалось подобрать ""Номер ГТД"" для изделия ""%1"" группы затрат ""%2"".';
								|en = 'Cannot pick ""CCD number"" for finished product ""%1"" of cost group ""%2"".'; fa = 'Cannot pick ""CCD number"" for finished product ""%1"" of cost group ""%2"".';
								|it = 'Non è stato possibile selezionare un ""Numero di Dichiarazione Doganale di Carico"" per il prodotto ""%1"" del gruppo di spesa ""%2"".';
								|pl = 'Nie udało się wybrać ""Numer zgłoszenia celnego"" dla wyrobu ""%1"" grupy kosztów ""%2"".';
								|tr = '""%2"" maliyet grubunun ""%1"" nihai ürünü için ""Kargo Gümrük Beyannamesi Numarası"" seçilemedi.'");
		PresentationOfCostGroups = PresentationOfCostGroups();
		
		For Each KeyAndValue In ImportedProductsWithoutCCDNumber Do
			
			Var_Key = KeyAndValue.Key;
			ProductPresentation =
				ProductsClientServer.ProductPresentation(
					Var_Key.Products,
					Var_Key.Characteristic);
			
			MessageText =
				StrTemplate(
					MessageTemplate,
					ProductPresentation,
					PresentationOfCostGroups[Var_Key.CostGroupNumber]);
			
			Common.MessageToUser(MessageText, Undefined, "", "Object", Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function DistributeCCDTraceableNumbers(Cancel)
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	CAST(InventoryOwnerAttributesMaterials.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	CAST(InventoryOwnerAttributesMaterials.CCDNumber AS Catalog.CCDNumbers) AS CCDNumber,
	|	CAST(InventoryOwnerAttributesMaterials.QuantityByGBRN AS NUMBER(15, 11)) AS QuantityByGBRN,
	|	CAST(InventoryOwnerAttributesMaterials.Count AS NUMBER(15, 3)) AS Count,
	|	InventoryOwnerAttributesMaterials.CostGroupNumber AS CostGroupNumber,
	|	InventoryOwnerAttributesMaterials.RowID AS RowID
	|INTO TTMaterials
	|FROM
	|	&InventoryOwnerAttributesMaterials AS InventoryOwnerAttributesMaterials
	|;
	|
	|SELECT
	|	CAST(InventoryOwnerAttributesProducts.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	CAST(InventoryOwnerAttributesProducts.QuantityByGBRN AS NUMBER(15, 11)) AS QuantityByGBRN,
	|	CAST(InventoryOwnerAttributesProducts.Count AS NUMBER(15, 3)) AS Count,
	|	InventoryOwnerAttributesProducts.CostGroupNumber AS CostGroupNumber,
	|	InventoryOwnerAttributesProducts.RowID AS RowID,
	|	InventoryOwnerAttributesProducts.ToExpenseAs AS ToExpenseAs
	|INTO TTWares
	|FROM
	|	&InventoryOwnerAttributesProducts AS InventoryOwnerAttributesProducts
	|;
	|
	|SELECT
	|	UsedMaterials.ItemsLocationAttributes,
	|	UsedMaterials.ItemsLocationAttributes.Products AS Products,
	|	CAST(UsedMaterials.CCDNumber AS Catalog.CCDNumbers) AS CCDNumber,
	|	UsedMaterials.CostGroupNumber,
	|	UsedMaterials.RowID,
	|	UsedMaterials.QuantityByGBRN,
	|	UsedMaterials.Count,
	|	UsedMaterials.ItemsLocationAttributes.Products.TracedGoods AS ThisIsTraceableItem,
	|	UsedMaterials.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.CCDNumber) AS ThisIsCCDNumber,
	|	UsedMaterials.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber) AS ThisIsRNPTNumber,
	|	UsedMaterials.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.KitRNPT) AS ThisIsCompositeTraceableRPNTNumber
	|INTO TTMaterialsWithFollowingAttributes
	|FROM
	|	TTMaterials AS UsedMaterials
	|;
	|
	|SELECT
	|	UsedMaterials.CostGroupNumber,
	|	SUM(CASE WHEN UsedMaterials.ItemsLocationAttributes.Products.TracedGoods THEN 1 ELSE 0 END) AS OfTraceableGoods
	|INTO TTMaterialsProductsFeatured
	|FROM
	|	(SELECT
	|		UsedMaterials.CostGroupNumber,
	|		UsedMaterials.ItemsLocationAttributes
	|	FROM
	|		TTMaterials AS UsedMaterials
	|	GROUP BY
	|		UsedMaterials.CostGroupNumber,
	|		UsedMaterials.ItemsLocationAttributes
	|	) AS UsedMaterials
	|
	|GROUP BY
	|	UsedMaterials.CostGroupNumber
	|INDEX BY
	|	CostGroupNumber
	|;
	|
	|SELECT
	|	UsedMaterials.CostGroupNumber,
	|	SUM(CASE WHEN UsedMaterials.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.CCDNumber) THEN 1 ELSE 0 END) AS SimpleCCDNumbers,
	|	SUM(CASE WHEN UsedMaterials.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber) THEN 1 ELSE 0 END) AS SimpleRNPTNumbers,
	|	SUM(CASE WHEN UsedMaterials.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.KitRNPT) THEN 1 ELSE 0 END) AS CompositeRNPTNumbers
	|INTO TTNumberMaterialsGTDSSigns
	|FROM
	|	(SELECT
	|		UsedMaterials.CostGroupNumber,
	|		UsedMaterials.CCDNumber
	|	FROM
	|		TTMaterials AS UsedMaterials
	|	GROUP BY
	|		UsedMaterials.CostGroupNumber,
	|		UsedMaterials.CCDNumber
	|	) AS UsedMaterials
	|
	|GROUP BY
	|	UsedMaterials.CostGroupNumber
	|INDEX BY
	|	CostGroupNumber
	|;
	|
	|SELECT
	|	UsedMaterials.CostGroupNumber AS CostGroupNumber,
	|	UsedMaterials.OfTraceableGoods AS OfTraceableGoods,
	|	MaterialsOfCCDRoom.SimpleCCDNumbers AS SimpleCCDNumbers,
	|	MaterialsOfCCDRoom.SimpleRNPTNumbers AS SimpleRNPTNumbers,
	|	MaterialsOfCCDRoom.CompositeRNPTNumbers AS CompositeRNPTNumbers
	|INTO TTMaterialsAreSummarized
	|FROM
	|	TTMaterialsProductsFeatured AS UsedMaterials
	|		INNER JOIN TTNumberMaterialsGTDSSigns AS MaterialsOfCCDRoom
	|		ON UsedMaterials.CostGroupNumber = MaterialsOfCCDRoom.CostGroupNumber
	|INDEX BY
	|	CostGroupNumber
	|;
	|
	|SELECT
	|	Products_1.ItemsLocationAttributes,
	|	Products_1.ItemsLocationAttributes.Products AS Products,
	|	Products_1.CostGroupNumber,
	|	Products_1.RowID,
	|	Products_1.QuantityByGBRN,
	|	Products_1.Count,
	|	Products_1.ItemsLocationAttributes.Products.TracedGoods AS ThisIsTraceableItem
	|INTO TTProductsWithSigns
	|FROM
	|	TTWares AS Products_1
	|WHERE
	|	NOT Products_1.ToExpenseAs
	|;
	|
	|SELECT
	|	Products_1.CostGroupNumber AS CostGroupNumber,
	|	SUM(CASE WHEN Products_1.ThisIsTraceableItem THEN 1 ELSE 0 END) AS OfTraceableGoods
	|INTO TTOfProductIsSummarized
	|FROM
	|	TTProductsWithSigns AS Products_1
	|GROUP BY
	|	Products_1.CostGroupNumber
	|INDEX BY
	|	CostGroupNumber
	|;
	|
	|SELECT
	|	MaterialsAreSummarized.CostGroupNumber,
	// The set of traceable materials (non-composite) to the set of traceable products is a simple transfer of CCD (ProductBatchID).
	|	MAX(ProductsAreSummarized.OfTraceableGoods > 1 AND MaterialsAreSummarized.OfTraceableGoods >= 1
	|		AND MaterialsAreSummarized.CompositeRNPTNumbers = 0 AND MaterialsAreSummarized.SimpleRNPTNumbers >= 1) AS TransferOfRNPTIsRequired,
	// 1 or more traceable materials (non-composite) to 1 traceable product - Assembly.
	|	MAX(ProductsAreSummarized.OfTraceableGoods = 1 AND MaterialsAreSummarized.OfTraceableGoods >= 1
	|		AND MaterialsAreSummarized.CompositeRNPTNumbers = 0 AND MaterialsAreSummarized.SimpleRNPTNumbers >= 1) AS AssemblyRequired,
	// 1 or more traceable composite materials (only composite) to 1 or more products - Disassembly.
	|	MAX(ProductsAreSummarized.OfTraceableGoods >= 1 AND MaterialsAreSummarized.OfTraceableGoods >= 1
	|		AND MaterialsAreSummarized.CompositeRNPTNumbers >= 1 AND MaterialsAreSummarized.SimpleRNPTNumbers = 0) AS DisassemblyIsRequired,
	|
	// An error is a traceable product on only one side.
	|	MAX(ProductsAreSummarized.OfTraceableGoods = 0 AND MaterialsAreSummarized.OfTraceableGoods > 0) AS ErrorThereAreNoTraceableItems,
	|	MAX(ProductsAreSummarized.OfTraceableGoods > 0 AND MaterialsAreSummarized.OfTraceableGoods = 0) AS ErrorThereAreNoTraceableMaterials,
	// Error - materials simultaneously contain composite and conventional RNPT.
	|	MAX(MaterialsAreSummarized.CompositeRNPTNumbers > 0 AND MaterialsAreSummarized.SimpleRNPTNumbers > 0) AS ErrorDifferentTypesOfRNPTMaterials,
	// Error - attempt to assemble more than 1 product.
	|	MAX(ProductsAreSummarized.OfTraceableGoods > 1 AND MaterialsAreSummarized.OfTraceableGoods > 1
	|		AND MaterialsAreSummarized.CompositeRNPTNumbers = 0 AND MaterialsAreSummarized.SimpleRNPTNumbers > 1) AS ErrorAttemptedAssemblyWithAssignmentToSeveralProducts
	|FROM
	|	TTMaterialsAreSummarized AS MaterialsAreSummarized
	|		INNER JOIN TTOfProductIsSummarized AS ProductsAreSummarized
	|		ON ProductsAreSummarized.CostGroupNumber = MaterialsAreSummarized.CostGroupNumber
	|GROUP BY
	|	MaterialsAreSummarized.CostGroupNumber
	|HAVING
	|	MAX(ProductsAreSummarized.OfTraceableGoods) > 0
	|	OR MAX(MaterialsAreSummarized.OfTraceableGoods) > 0
	|;
	|
	|SELECT
	|	UsedMaterials.CostGroupNumber,
	|	UsedMaterials.RowID,
	|	UsedMaterials.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	UsedMaterials.Products AS Products,
	|	UsedMaterials.CCDNumber AS CCDNumber,
	|	UsedMaterials.QuantityByGBRN AS QuantityByGBRN,
	|	UsedMaterials.Count AS Count,
	|	UsedMaterials.ThisIsCompositeTraceableRPNTNumber
	|FROM
	|	TTMaterialsWithFollowingAttributes AS UsedMaterials
	|WHERE
	|	UsedMaterials.ThisIsTraceableItem
	|;
	|
	|SELECT
	|	Products_1.CostGroupNumber,
	|	Products_1.RowID,
	|	Products_1.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Products_1.Products AS Products,
	|	Products_1.QuantityByGBRN AS QuantityByGBRN,
	|	Products_1.Count AS Count
	|FROM
	|	TTProductsWithSigns AS Products_1
	|WHERE
	|	Products_1.ThisIsTraceableItem
	|";
	
	Query.SetParameter("InventoryOwnerAttributesMaterials", InventoryOwnerAttributesMaterials.Unload());
	Query.SetParameter("InventoryOwnerAttributesProducts", InventoryOwnerAttributesProducts.Unload());
	
	QueryResult = Query.ExecuteBatch();
	CostGroupNumbers = QueryResult[QueryResult.UBound() - 2].Select();
	UsedMaterials = QueryResult[QueryResult.UBound() - 1].Unload();
	Products_1 = QueryResult[QueryResult.UBound()].Unload();
	
	SpentCostGroupsAndGoodsMaterials = New ValueTable();
	SpentCostGroupsAndGoodsMaterials.Columns.Add("CostGroupNumber", New TypeDescription("Number"));
	SpentCostGroupsAndGoodsMaterials.Columns.Add("ItemsLocationAttributes", New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
	
	SpentCostGroupsAndGoodsProducts = SpentCostGroupsAndGoodsMaterials.Copy();
	
	PresentationOfCostGroups = PresentationOfCostGroups();
	
	GroupingByProducts = GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts
		Or GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments;
	
	While CostGroupNumbers.Next() Do
		
		RowFilter = New Structure("CostGroupNumber", CostGroupNumbers.CostGroupNumber);
		DataForSearchingForMaterials = UsedMaterials.FindRows(RowFilter);
		ProductSearchData = Products_1.FindRows(RowFilter);
		
		FoundWriteOffLines = New Array();
		SelectionOfLinesMaterials = New Structure("CostGroupNumber, RowID");
		For Each String In DataForSearchingForMaterials Do
			FillPropertyValues(SelectionOfLinesMaterials, String);
			WriteOffLines = InventoryOwnerAttributesMaterials.FindRows(SelectionOfLinesMaterials);
			CommonClientServer.SupplementArray(FoundWriteOffLines, WriteOffLines);
		EndDo;
		
		FoundLoggingLines = New Array();
		FilterProductLines = New Structure("CostGroupNumber, RowID");
		For Each String In ProductSearchData Do
			FillPropertyValues(FilterProductLines, String);
			LoginStrings = InventoryOwnerAttributesProducts.FindRows(FilterProductLines);
			CommonClientServer.SupplementArray(FoundLoggingLines, LoginStrings);
		EndDo;
		
		FoundWriteOffLines = CommonClientServer.CollapseArray(FoundWriteOffLines);
		FoundLoggingLines = CommonClientServer.CollapseArray(FoundLoggingLines);
		
		CommonClientServer.SupplementTable(FoundWriteOffLines, SpentCostGroupsAndGoodsMaterials);
		CommonClientServer.SupplementTable(FoundLoggingLines, SpentCostGroupsAndGoodsProducts);
		
		MessageTemplateGroupingNotByProducts = NStr("vi = 'Đã tìm thấy kết hợp không chính xác giữa nguyên vật liệu và sản phẩm: chi phí của hàng hóa có nguồn gốc xuất xứ không thể được phân bổ chính xác.
		|Hãy chỉ ra gom nhóm chi phí ""Theo sản phẩm"" hoặc ""Theo sản phẩm và mục đích"". Trong trường hợp này, có đảm bảo tính đơn trị của hàng hóa theo từng nhóm chi phí.';
		|ru = 'Обнаружена некорректная комбинация материалов и изделий: затраты прослеживаемых товаров не могут быть корректно распределены.
		|Укажите группировку затрат ""По продукции"" или ""По продукции и назначению"". В этом случае обеспечивается уникальность товарных позиций в разрезе групп затрат.';
		|en = 'Incorrect combination of materials and finished products is found: costs of traceable goods cannot be allocated correctly.
		|Specify the ""By products"" or ""By products and assignments"" cost grouping. In this case, goods broken down by cost groups are unique.'; fa = 'Incorrect combination of materials and finished products is found: costs of traceable goods cannot be allocated correctly.
		|Specify the ""By products"" or ""By products and assignments"" cost grouping. In this case, goods broken down by cost groups are unique.';
		|it = 'Rilevata una combinazione scorretta di materiali e prodotti: le spese di prodotti tracciabili non possono essere imputate correttamente. 
		|Indicare il raggruppamento di spese ""Per prodotto"" o ""Per prodotto e assegnazione"". In questo caso si garantisce l''unicità delle voci commerciali nel dettaglio dei gruppi di spese.';
		|pl = 'Wykryto niepoprawną kombinację materiałów i wyrobów: koszty identyfikowalnych towarów nie mogą być poprawnie podzielone.
		|Podaj grupowanie kosztów ""Według produkcji"" lub ""Według produkcji i przeznaczenia"". W tym przypadku jest zapewniana unikalność pozycji towarowych w przekroju kosztów.';
		|tr = 'Yanlış malzeme ve nihai ürün kombinasyonu tespit edildi: İzlenebilir ürünlerin giderleri doğru bir şekilde dağıtılamadı.
		|Maliyet grubunu ""İmal Edilen Ürüne Göre"" veya ""İmal Edilen Ürüne ve Atamaya Göre"" belirtin. Bu durumda, maliyet grupları kesitinden ürün pozisyonlarının benzersizliği sağlanır.'");
		
		MessageTemplateErrorAttemptedAssemblyWithAssignmentToSeveralProducts = NStr("vi = 'Đối với nhóm chi phí ""%1"" đã tìm thấy sự kết hợp không chính xác giữa nguyên vật liệu và sản phẩm:
			|Đồng thời có nhiều hơn một sản phẩm có nguồn gốc xuất xứ và hơn một nguyên vật liệu có nguồn gốc xuất xứ (không phải bộ đóng gói hoàn chỉnh).
			|Cần thay đổi thành phần nhóm chi phí sao cho còn lại một sản phẩm có nguồn gốc xuất xứ với một hoặc nhiều nguyên vật liệu có nguồn gốc xuất xứ hoặc một nguyên vật liệu có nguồn gốc xuất xứ với một hoặc nhiều sản phẩm có nguồn gốc xuất xứ.';
			|ru = 'Для группы затрат ""%1"" обнаружена некорректная комбинация материалов и изделий:
			|Одновременно имеются более одного прослеживаемого изделия и более одного прослеживаемого материала (не составного комплекта).
			|Требуется изменить состав группы затрат таким образом, чтобы осталось либо одно прослеживаемое изделие при одном и более прослеживаемом материале, либо один прослеживаемый материал при одном и более прослеживаемом изделии.';
			|en = 'Incorrect combination of materials and finished products is found for the ""%1"" cost group:
			|There is more than one traceable finished product and more than one traceable material (not a composite kit) at the same time.
			|Change the cost group so that either one traceable finished product remains with one or more traceable materials, or one traceable material remains with one or more traceable finished products.'; fa = 'Incorrect combination of materials and finished products is found for the ""%1"" cost group:
			|There is more than one traceable finished product and more than one traceable material (not a composite kit) at the same time.
			|Change the cost group so that either one traceable finished product remains with one or more traceable materials, or one traceable material remains with one or more traceable finished products.';
			|it = 'Для группы затрат ""%1"" обнаружена некорректная комбинация материалов и изделий:
			|Одновременно имеются более одного прослеживаемого изделия и более одного прослеживаемого материала (не составного комплекта).
			|Требуется изменить состав группы затрат таким образом, чтобы осталось либо одно прослеживаемое изделие при одном и более прослеживаемом материале, либо один прослеживаемый материал при одном и более прослеживаемом изделии.';
			|pl = 'Incorrect combination of materials and finished products is found for the ""%1"" cost group:
			|There is more than one traceable finished product and more than one traceable material (not a composite kit) at the same time.
			|Change the cost group so that either one traceable finished product remains with one or more traceable materials, or one traceable material remains with one or more traceable finished products.';
			|tr = '""%1"" maliyet grubunda yanlış malzeme ve nihai ürün kombinasyonu tespit edildi:
			|Aynı anda birden fazla izlenebilir nihai ürün ve birden fazla izlenebilir malzeme (bileşik küme değil) mevcuttur.
			|Maliyet grubunun içeriğini, izlenebilir bir nihai ürünün bir veya daha fazla izlenebilir malzemede kalması ya da bir veya daha fazla izlenebilir nihai üründe izlenebilir bir malzeme kalması için değiştirmeniz gerekmektedir.'");
		
		ErrorMessageTemplateDifferentTypesOfRNPTMaterials = NStr("vi = 'Đối với nhóm chi phí ""%1"" đã tìm thấy sự kết hợp không chính xác giữa các nguyên vật liệu:
			|Đối với nguyên vật liệu có nguồn gốc xuất xứ, đồng thời chọn số tờ khai hải quan (số đăng ký lô hàng) của hai kiểu - bộ đóng gói và số đăng ký lô hàng.
			|Cần thay đổi thành phần nhóm chi phí sao cho trong đó chỉ có một trong các kiểu số tờ khai hải quan.';
			|ru = 'Для группы затрат ""%1"" обнаружена некорректная комбинация материалов:
			|Для прослеживаемых материалов одновременно подобраны номера ГТД (РНПТ) двух типов - составной комплект и РНПТ.
			|Требуется изменить состав группы затрат таким образом, чтобы в нее попал только один из этих типов номеров ГТД.';
			|en = 'Incorrect combination of materials is found for the ""%1"" cost group:
			|For traceable materials, two types of CCD (RNPT) numbers are simultaneously picked: a composite kit and RNPT.
			|Change the cost group so that only one of these CCD number types falls into it.'; fa = 'Incorrect combination of materials is found for the ""%1"" cost group:
			|For traceable materials, two types of CCD (RNPT) numbers are simultaneously picked: a composite kit and RNPT.
			|Change the cost group so that only one of these CCD number types falls into it.';
			|it = 'Для группы затрат ""%1"" обнаружена некорректная комбинация материалов:
			|Для прослеживаемых материалов одновременно подобраны номера ГТД (РНПТ) двух типов - составной комплект и РНПТ.
			|Требуется изменить состав группы затрат таким образом, чтобы в нее попал только один из этих типов номеров ГТД.';
			|pl = 'Incorrect combination of materials is found for the ""%1"" cost group:
			|For traceable materials, two types of CCD (RNPT) numbers are simultaneously picked: a composite kit and RNPT.
			|Change the cost group so that only one of these CCD number types falls into it.';
			|tr = '""%1"" maliyet grubunda yanlış malzeme ve nihai ürün kombinasyonu tespit edildi:
			|İzlenebilir malzemeler için aynı anda iki tür GKB (RNPT) numarası seçildi; bileşik küme ve RNPT.
			|Maliyet grubunun içeriğini, bu tür GKB numaralarından sadece birinin içine gireceği şekilde değiştirmeniz gerekmektedir.'");
		
		MessageTemplateErrorNoTraceableItems = NStr("vi = 'Đối với nhóm chi phí ""%1"" đã tìm thấy thanh lý các nguyên vật liệu có nguồn gốc:
			|Khi sử dụng nguyên vật liệu có nguồn gốc theo số đăng ký lô hàng, để lưu số đăng ký lô hàng trên số dư, cần chỉ ra sản phẩm có nguồn gốc.
			|Có thể thực hiện điều đó bằng cách thay đổi thành phần nhóm chi phí sao cho, hàng hóa có nguồn gốc có trong cả nguyên vật liệu, cũng như sản phẩm.';
			|ru = 'Для группы затрат ""%1"" обнаружено выбытие прослеживаемых материалов:
			|При использовании прослеживаемого по РНПТ материала, для сохранения РНПТ на остатках нужно указать прослеживаемое изделие.
			|Это можно сделать, изменив состав группы затрат так, чтобы прослеживаемые товары были как в материалах, так и в изделиях.';
			|en = 'The retirement of traceable materials was detected for the ""%1"" cost group:
			|When using a traceable material by RNPT, to keep the RNPT in stock, specify the traceable finished product.
			|To do it, change the cost group so that traceable goods were both in materials and finished products.'; fa = 'The retirement of traceable materials was detected for the ""%1"" cost group:
			|When using a traceable material by RNPT, to keep the RNPT in stock, specify the traceable finished product.
			|To do it, change the cost group so that traceable goods were both in materials and finished products.';
			|it = 'Для группы затрат ""%1"" обнаружено выбытие прослеживаемых материалов:
			|При использовании прослеживаемого по РНПТ материала, для сохранения РНПТ на остатках нужно указать прослеживаемое изделие.
			|Это можно сделать, изменив состав группы затрат так, чтобы прослеживаемые товары были как в материалах, так и в изделиях.';
			|pl = 'The retirement of traceable materials was detected for the ""%1"" cost group:
			|When using a traceable material by RNPT, to keep the RNPT in stock, specify the traceable finished product.
			|To do it, change the cost group so that traceable goods were both in materials and finished products.';
			|tr = '""%1"" maliyet grubunda izlenebilir malzemelerin çekildiği tespit edildi:
			|Lot Kayıt Numarasına göre izlenebilir malzeme kullanılırken, Lot Kayıt Numarasını bakiyelerde saklamak için izlenebilir nihai ürün belirtilmelidir.
			|Bu, izlenebilir nihai ürünlerin hem malzeme hem de ürünlerde yer alması için maliyet grubunun içeriğini değiştirerek yapılabilir.'");
		
		MessageTemplateErrorNoTraceableMaterials = NStr("vi = 'Đối với nhóm chi phí ""%1"" đã tìm thấy sự kết hợp không chính xác giữa nguyên vật liệu và sản phẩm:
			|Khi sử dụng sản phẩm có nguồn gốc theo số đăng ký lô hàng, cần chỉ ra nguyên vật liệu có nguồn gốc.
			|Cần thay đổi thành phần nhóm chi phí sao cho hàng hóa có nguồn gốc xuất hiện trong nguyên vật liệu, cũng như sản phẩm.
			|Hãy chắc chắn rằng, đối với nguyên vật liệu có nguồn gốc trong số dư có số tờ khai hải quan có kiểu ""Số đăng ký lô hàng"".';
			|ru = 'Для группы затрат ""%1"" обнаружена некорректная комбинация материалов и изделий:
			|При использовании прослеживаемого по РНПТ изделия, требуется указать прослеживаемые материалы.
			|Требуется изменить состав группы затрат таким образом, чтобы прослеживаемые товары были как в материалах, так и в изделиях.
			|Убедитесь, что для прослеживаемых материалов на остатках имеются номера ГТД с типом ""РНПТ"".';
			|en = 'Incorrect combination of materials and finished products is found for the ""%1"" cost group:
			|When using a traceable material by RNPT, specify traceable materials.
			|Change the cost group so that traceable goods are both in materials and finished products.
			|Make sure that for traceable materials on the balance there are CCD numbers with the RNPT type.'; fa = 'Incorrect combination of materials and finished products is found for the ""%1"" cost group:
			|When using a traceable material by RNPT, specify traceable materials.
			|Change the cost group so that traceable goods are both in materials and finished products.
			|Make sure that for traceable materials on the balance there are CCD numbers with the RNPT type.';
			|it = 'Для группы затрат ""%1"" обнаружена некорректная комбинация материалов и изделий:
			|При использовании прослеживаемого по РНПТ изделия, требуется указать прослеживаемые материалы.
			|Требуется изменить состав группы затрат таким образом, чтобы прослеживаемые товары были как в материалах, так и в изделиях.
			|Убедитесь, что для прослеживаемых материалов на остатках имеются номера ГТД с типом ""РНПТ"".';
			|pl = 'Incorrect combination of materials and finished products is found for the ""%1"" cost group:
			|When using a traceable material by RNPT, specify traceable materials.
			|Change the cost group so that traceable goods are both in materials and finished products.
			|Make sure that for traceable materials on the balance there are CCD numbers with the RNPT type.';
			|tr = '""%1"" maliyet grubunda yanlış malzeme ve nihai ürün kombinasyonu tespit edildi:
			|RNPT''ye göre izlenebilir nihai ürün kullanılırken, izlenebilir malzemeleri belirtmeniz gerekmektedir.
			|Maliyet grubunun içeriğini, izlenebilir ürünlerin hem malzemelerde hem de nihai ürünlerde olacak şekilde değiştirmeniz gerekmektedir.
			|İzlenebilir malzemeler için bakiyelerde ""RNPT"" türünde GKB numaralarının bulunduğundan emin olun.'");
		
		If CostGroupNumbers.ErrorAttemptedAssemblyWithAssignmentToSeveralProducts Then
			MessageText = ?(GroupingByProducts,
				StrTemplate(MessageTemplateErrorAttemptedAssemblyWithAssignmentToSeveralProducts, PresentationOfCostGroups[CostGroupNumbers.CostGroupNumber]),
				MessageTemplateGroupingNotByProducts);
			Common.MessageToUser(MessageText, Undefined, "", "Object", Cancel);
		ElsIf CostGroupNumbers.ErrorDifferentTypesOfRNPTMaterials Then
			MessageText = ?(GroupingByProducts,
				StrTemplate(ErrorMessageTemplateDifferentTypesOfRNPTMaterials, PresentationOfCostGroups[CostGroupNumbers.CostGroupNumber]),
				MessageTemplateGroupingNotByProducts);
			Common.MessageToUser(MessageText, Undefined, "", "Object", Cancel);
		ElsIf CostGroupNumbers.ErrorThereAreNoTraceableItems Then
			MessageText = ?(GroupingByProducts,
				StrTemplate(MessageTemplateErrorNoTraceableItems, PresentationOfCostGroups[CostGroupNumbers.CostGroupNumber]),
				MessageTemplateGroupingNotByProducts);
			// The failure is not missed in this case, since the scenario of disposal of traceable components is possible.
			Common.MessageToUser(MessageText, Undefined, "", "Object");
		ElsIf CostGroupNumbers.ErrorThereAreNoTraceableMaterials Then
			MessageText = ?(GroupingByProducts,
				StrTemplate(MessageTemplateErrorNoTraceableMaterials, PresentationOfCostGroups[CostGroupNumbers.CostGroupNumber]),
				MessageTemplateGroupingNotByProducts);
			Common.MessageToUser(MessageText, Undefined, "", "Object", Cancel);
		ElsIf CostGroupNumbers.TransferOfRNPTIsRequired Then
			DistributeCCDNumbersTraceableToTransfer(FoundWriteOffLines, FoundLoggingLines);
		ElsIf CostGroupNumbers.AssemblyRequired Then
			DistributeCCDTraceableAssemblyNumbers(FoundWriteOffLines, FoundLoggingLines, Cancel);
		ElsIf CostGroupNumbers.DisassemblyIsRequired Then
			DistributeCCDTraceableDisassemblyNumbers(FoundWriteOffLines, FoundLoggingLines, Cancel);
		EndIf;
		
	EndDo;
	
	ReturnValue = New Structure("SpentCostGroupsAndGoodsMaterials, SpentCostGroupsAndGoodsProducts",
		SpentCostGroupsAndGoodsMaterials, SpentCostGroupsAndGoodsProducts);
		
	Return ReturnValue;
	
EndFunction

Procedure DistributeCCDNumbersTraceableToTransfer(FoundLinesAreDebited, FoundRowsLoggingIn)
	
	// There is expected to be one written-off RPT number, but it can be specified for several lines.
	
	If FoundLinesAreDebited.Count() > 0 Then
		For Each LineToLogIn In FoundRowsLoggingIn Do
			LineToLogIn.QuantityByGBRN = 0;
		EndDo;
	EndIf;
	
	For Each LineToBeDebited In FoundLinesAreDebited Do
		NumberOfLoginLines = FoundRowsLoggingIn.Count();
		
		ShareToDistribution = LineToBeDebited.QuantityByGBRN / NumberOfLoginLines;
		BalanceOfDistribution = LineToBeDebited.QuantityByGBRN - (ShareToDistribution * NumberOfLoginLines);
		
		For Each LineToLogIn In FoundRowsLoggingIn Do
			LineToLogIn.CCDNumber = LineToBeDebited.CCDNumber;
			LineToLogIn.QuantityByGBRN = LineToLogIn.QuantityByGBRN + ShareToDistribution;
		EndDo;
		LineToLogIn.QuantityByGBRN = LineToLogIn.QuantityByGBRN + BalanceOfDistribution;
	EndDo;
	
EndProcedure

Procedure DistributeCCDTraceableAssemblyNumbers(FoundLinesAreDebited, FoundRowsLoggingIn, Cancel)
	
	TypesOfStocksForCreatingCompositeCCDNumbers = InventoryOwnerAttributesMaterials.Unload(FoundLinesAreDebited);
	
	// When assembling into inventory types, one line corresponding to the set is selected (one to one).
	StockLogging = FoundRowsLoggingIn[0];
	LogInAnalytics = Common.ObjectAttributesValues(StockLogging.ItemsLocationAttributes, "Products, Characteristic, Series");
	
	CreationParameters = PurchasesServer.ParametersForSearchingOrCreatingCompositeTraceableSets();
	CreationParameters.ExtractProductFromObjectInColumn = TypesOfStocksForCreatingCompositeCCDNumbers.Columns.ItemsLocationAttributes.Name;
	CreationParameters.ExtractCharacteristicFromObjectInColumn = TypesOfStocksForCreatingCompositeCCDNumbers.Columns.ItemsLocationAttributes.Name;
	CreationParameters.ExtractBatchFromObjectInColumn = TypesOfStocksForCreatingCompositeCCDNumbers.Columns.ItemsLocationAttributes.Name;
	CreationParameters.ItemOfHeader = LogInAnalytics.Products;
	CreationParameters.CharacteristicsOfCap = LogInAnalytics.Characteristic;
	CreationParameters.CapsBatch = LogInAnalytics.Series;
	
	CompositeTraceableCCDNumbers = PurchasesServer.FindOrCreateCompositeTraceableCCDNumbers(TypesOfStocksForCreatingCompositeCCDNumbers,
		StockLogging.Count,
		Date,
		Cancel,
		CreationParameters);
	
	QuantityByGBRN = StockLogging.QuantityByGBRN;
	If QuantityByGBRN = 0 Then
		QuantityByGBRN = StockLogging.Count;
	EndIf;
	
	If CompositeTraceableCCDNumbers.ResidualCompositeNumberOfCCD = Undefined Then
		StockLogging.CCDNumber = CompositeTraceableCCDNumbers.MainCompositeNumberOfCCD;
		StockLogging.QuantityByGBRN = QuantityByGBRN;
	Else
		RNPTUnit = StockLogging.Count / QuantityByGBRN;
		StockLogging.CCDNumber = CompositeTraceableCCDNumbers.MainCompositeNumberOfCCD;
		StockLogging.Count = StockLogging.Count - 1;
		StockLogging.QuantityByGBRN = QuantityByGBRN - RNPTUnit;
		
		NewRow = InventoryOwnerAttributesProducts.Add();
		FillPropertyValues(NewRow, StockLogging);
		NewRow.CCDNumber = CompositeTraceableCCDNumbers.ResidualCompositeNumberOfCCD;
		NewRow.Count = 1;
		NewRow.QuantityByGBRN = RNPTUnit;
	EndIf;
	
EndProcedure

Procedure DistributeCCDTraceableDisassemblyNumbers(FoundLinesAreDebited, FoundRowsLoggingIn, Cancel)
	
	TypesOfStocksForCreatingCompositeCCDNumbersWriteOff = InventoryOwnerAttributesMaterials.Unload(FoundLinesAreDebited);
	TypesOfStocksForCreatingCompositeCCDRegistrationNumbers = InventoryOwnerAttributesProducts.Unload(FoundRowsLoggingIn);
	
	FieldsFromObject = New Array();
	FieldsFromObject.Add("BusinessOperation");
	FieldsFromObject.Add("ProductCostElement");
	FieldsFromObject.Add("ToExpenseAs");
	FieldsFromObject.Add("Recipient");
	FieldsFromObject.Add("ExpenseItem");
	FieldsFromObject.Add("DimensionOfExpenses");
	FieldsFromObject.Add("AssetsLiabilitiesDimension");
	FieldsFromObject.Add("RowID");
	FieldsFromObject.Add("CostGroupNumber");
	FieldsFromObject.Add("ProductionStage");
	FieldsFromObject.Add("RowCodeProducts");
	FieldsFromObject.Add("FinRecordID");
	FieldsFromObject.Add("GLAccountSettings");
	
	FieldsNumeric = New Array();
	FieldsNumeric.Add("CostShare");
	FieldsNumeric.Add("Sum");
	
	Result = PurchasesServer.DisassembleCompositeTraceableCCDNumbers(
		TypesOfStocksForCreatingCompositeCCDNumbersWriteOff,
		TypesOfStocksForCreatingCompositeCCDRegistrationNumbers,
		FieldsFromObject,
		FieldsNumeric,
		Cancel);
	
	For Each RowToDelete In FoundRowsLoggingIn Do
		InventoryOwnerAttributesProducts.Delete(RowToDelete);
	EndDo;
	CommonClientServer.SupplementTable(Result, InventoryOwnerAttributesProducts);
	
EndProcedure

Function OrderOfTS(TSName)
	
	DocumentTables = DocumentTables();
	
	NumberOfRowsInAllTs = DocumentTables.ManufacturedProducts.Count()
								+ DocumentTables.SideAndIntermediateRelease.Count();
	
	If TSName = "ManufacturedProducts" Then
		Return 0;
	ElsIf TSName = "SideAndIntermediateRelease" Then
		Return NumberOfRowsInAllTs;
	Else
		ExceptionText = NStr("vi = 'Chưa đặt trình tự cho phần bảng ""%TSName%""';
							|ru = 'Табличной части ""%TSName%"" не поставлен порядок';
							|en = 'The order is not set for the ""%TSName%"" table'; fa = 'The order is not set for the ""%TSName%"" table';
							|it = 'Parte tabellare ""%TSName%"" non ordinata';
							|pl = 'Dla sekcji tabelarycznej ""%TSName%"" nie ustawiono kolejności';
							|tr = '""%TSName%"" tablo bölümü sıralı değil'");
		ExceptionText = StrReplace(ExceptionText, "%TSName%", TSName);
		
		Raise ExceptionText;
	EndIf;
	
EndFunction

#EndRegion

#Region Checks

Procedure CheckCostGroups(Cancel, NotCheckedAttributeArray)
	
	NotCheckedAttributeArray.Add("ManufacturedProducts.CostGroupNumber");
	NotCheckedAttributeArray.Add("ManufacturedProducts.Purpose");
	NotCheckedAttributeArray.Add("SideAndIntermediateRelease.CostGroupNumber");
	NotCheckedAttributeArray.Add("MaterialsAndWorks.CostGroupNumber");
	NotCheckedAttributeArray.Add("Services.CostGroupNumber");
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		NotCheckedAttributeArray.Add("ManufacturedProducts");
	EndIf;
	NotCheckedAttributeArray.Add("MaterialsAndWorks");
	NotCheckedAttributeArray.Add("Services");
	
	QueryTexts			= New Array;
	VerificationRequestTexts	= New Array;
	
	QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "ManufacturedProducts", False, "CostGroupNumber"));
	QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "SideAndIntermediateRelease", False, "CostGroupNumber"));
	QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "MaterialsAndWorks", False, "CostGroupNumber"));
	QueryTexts.Add(TMCommonUse.RequestTextObjectTSData(Ref, "Services", False, "CostGroupNumber"));
	QueryTexts.Add(Documents.SubcontractorReport2_5.RequestTextForDocumentSCostGroup());
	QueryTexts.Add(ProcessingByThirdParties.QueryTextTTImportedProducts());
	QueryTexts.Add(Documents.SubcontractorReport2_5.QueryTextTTImportedDocumentMaterials());
	
	If ByOrders Then
		
		QueryTexts.Add(Documents.SubcontractOrder2_5.RequestTextForDocumentSCostGroup(SubcontractOrder, "OrderCostGroupNumbers"));
		QueryTexts.Add(
		"SELECT
		|	CostGroupNumbers.CostGroupNumber AS CostGroupNumber
		|INTO CostGroupNumbersNotIncludedInOrder
		|FROM
		|	CostGroupNumbers AS CostGroupNumbers
		|	
		|	LEFT JOIN OrderCostGroupNumbers AS OrderCostGroupNumbers
		|	ON OrderCostGroupNumbers.CostGroupNumber = CostGroupNumbers.CostGroupNumber
		|
		|WHERE
		|	OrderCostGroupNumbers.CostGroupNumber IS NULL
		|
		|INDEX BY
		|	CostGroupNumber
		|");
		
		// Cost groups do not match the order
		VerificationRequestTexts.Add(
			ProcessingByThirdParties.VerificationTextDoesNotMatchOrder(
				"ManufacturedProducts",
				"TableNameOutputProducts",
				"SynonymForTSOutputProducts"));
		
		VerificationRequestTexts.Add(
			ProcessingByThirdParties.VerificationTextDoesNotMatchOrder(
				"SideAndIntermediateRelease",
				"NameOfByProductTable",
				"SynonymOfTSByProducts"));
		
		VerificationRequestTexts.Add(
			ProcessingByThirdParties.VerificationTextDoesNotMatchOrder(
				"MaterialsAndWorks",
				"NameOfMaterialsAndWorksTable",
				"SynonymTSMaterialsAndWorks"));
		
		VerificationRequestTexts.Add(
			ProcessingByThirdParties.VerificationTextDoesNotMatchOrder(
				"Services",
				"ServiceTableName",
				"SynonymForTSServices"));
		
	EndIf;
	
	// The cost group is not filled in
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.CheckTextNotFilledInCostGroupTSDocument(
			"ManufacturedProducts",
			"TableNameOutputProducts",
			"SynonymForTSOutputProducts"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.CheckTextNotFilledInCostGroupTSDocument(
			"SideAndIntermediateRelease",
			"NameOfByProductTable",
			"SynonymOfTSByProducts"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.CheckTextNotFilledInCostGroupTSDocument(
			"MaterialsAndWorks",
			"NameOfMaterialsAndWorksTable",
			"SynonymTSMaterialsAndWorks"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.CheckTextNotFilledInCostGroupTSDocument(
			"Services",
			"ServiceTableName",
			"SynonymForTSServices"));
	
	// A non-existent cost group is specified
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.VerificationTextNonExistentCostGroupTSDocument(
			"ManufacturedProducts",
			"TableNameOutputProducts",
			"SynonymForTSOutputProducts"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.VerificationTextNonExistentCostGroupTSDocument(
			"SideAndIntermediateRelease",
			"NameOfByProductTable",
			"SynonymOfTSByProducts"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.VerificationTextNonExistentCostGroupTSDocument(
			"MaterialsAndWorks",
			"NameOfMaterialsAndWorksTable",
			"SynonymTSMaterialsAndWorks"));
	
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.VerificationTextNonExistentCostGroupTSDocument(
			"Services",
			"ServiceTableName",
			"SynonymForTSServices"));
	
	// Purpose not specified
	VerificationRequestTexts.Add(ProcessingByThirdParties.VerificationTextNoDestinationSpecified());
	
	// Materials are not specified
	VerificationRequestTexts.Add(
		ProcessingByThirdParties.VerificationTextMaterialsNotSpecified(
			"MaterialsAndWorks",
			"NameOfMaterialsAndWorksTable",
			"SynonymTSMaterialsAndWorks"));
	
	// The service is not specified
	VerificationRequestTexts.Add(ProcessingByThirdParties.VerificationTextServicesNotSpecified());
	
	// Products Not Specified
	VerificationRequestTexts.Add(ProcessingByThirdParties.TextOfCheckDoesNotSpecifyProducts());
	
	// Wrong type of cost
	VerificationRequestTexts.Add(Documents.SubcontractorReport2_5.ValidationTextIsNotCorrectValueType());
	// Several imported products are indicated
	VerificationRequestTexts.Add(ProcessingByThirdParties.TextCheckMultipleImportedProducts());
	
	// Imported material is not specified
	VerificationRequestTexts.Add(Documents.SubcontractorReport2_5.VerificationTextOmittedImportedMaterial());
	
	ProcessingByThirdPartiesLocalization.AddTextForRNPTVerification(VerificationRequestTexts, Date);
	
	QueryTexts.Add(StrConcat(VerificationRequestTexts, TMCommonUse.QuerySeparatorInJoin()));
	
	Query = New Query;
	If TMCommonUse.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	TabularSections = Metadata.Documents.SubcontractorReport2_5.TabularSections;
	
	Query.SetParameter("Date",                Date);
	Query.SetParameter("ManufacturedProducts",     ManufacturedProducts.Unload());
	Query.SetParameter("SideAndIntermediateRelease",     SideAndIntermediateRelease.Unload());
	Query.SetParameter("MaterialsAndWorks",    MaterialsAndWorks.Unload());
	Query.SetParameter("Services",              Services.Unload());
	Query.SetParameter("GroupCosts",   GroupCosts);
	Query.SetParameter("ProcessingServices", ProcessingServices);
	Query.SetParameter("SubcontractOrder",  SubcontractOrder);
	
	Query.SetParameter("TableNameOutputProducts",  TabularSections.ManufacturedProducts.Name);
	Query.SetParameter("NameOfByProductTable",  TabularSections.SideAndIntermediateRelease.Name);
	Query.SetParameter("NameOfMaterialsAndWorksTable", TabularSections.MaterialsAndWorks.Name);
	Query.SetParameter("ServiceTableName",           TabularSections.Services.Name);
	
	Query.SetParameter("NameOfManufacturedProductsPage",      "OutputProductsPage");
	
	Query.SetParameter("SynonymForTSOutputProducts",  TabularSections.ManufacturedProducts.Synonym);
	Query.SetParameter("SynonymOfTSByProducts",  TabularSections.SideAndIntermediateRelease.Synonym);
	Query.SetParameter("SynonymTSMaterialsAndWorks", TabularSections.MaterialsAndWorks.Synonym);
	Query.SetParameter("SynonymForTSServices",           TabularSections.Services.Synonym);
	
	Query.SetParameter("UseImportedGoods", GetFunctionalOption("UseImportedGoods"));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Selection = Query.Execute().Select();
	If Not Selection.Count() = 0 Then
		
		PresentationOfCostGroups = PresentationOfCostGroups();
		
		ProcessingByThirdParties.ReportErrorsFillingCostGroups(
			Selection,
			PresentationOfCostGroups,
			Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.SubcontractorReport2_5.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.SubcontractorReport2_5.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
#Region FillingInProductAccountingAnalyticsKeys
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Undefined,
																		Department,
																		Undefined,
																		Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Work_5 = "Recipient";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(DocumentTables.ManufacturedProducts,
																	PlacesOfAccounting,
																	FieldsNames);
	InformationRegisters.ItemsLocationAttributes.FillInCollection(DocumentTables.SideAndIntermediateRelease,
																	PlacesOfAccounting,
																	FieldsNames);
	
	CurrentTabularSection = DocumentTables.MaterialsAndWorks;
	FieldsNames.Work_5 = "";
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		
		CurrentTabularSection = DocumentTables.MaterialsAndWorks.Unload();
		
		ItemListOfTS = CurrentTabularSection.UnloadColumn("Products");
		ItemListOfTS = CommonClientServer.CollapseArray(ItemListOfTS);
		ItemsTypes = Common.ObjectsAttributeValue(ItemListOfTS, "ItemsType");
		
		TSStages = CurrentTabularSection.UnloadColumn("ProductionStage");
		TSStages = CommonClientServer.CollapseArray(TSStages);
		StageAssignments = Common.ObjectsAttributeValue(TSStages, "Purpose");
		
		CurrentTabularSection.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
		CurrentTabularSection.Columns.Add("StageAssignment", New TypeDescription("CatalogRef.Assignments"));
		
		For Each CurrentData In CurrentTabularSection Do
			CurrentData.ItemsType = ItemsTypes.Get(CurrentData.Products);
			CurrentData.StageAssignment = StageAssignments.Get(CurrentData.ProductionStage);
		EndDo;
		
		FieldsNames.Purpose = New Structure("FieldText");
		FieldsNames.Purpose.FieldText =
			"CASE
			|	WHEN Collection.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
			|		THEN Collection.StageAssignment
			|	ELSE Collection.Purpose
			|END";
	EndIf;
	InformationRegisters.ItemsLocationAttributes.FillInCollection(CurrentTabularSection, PlacesOfAccounting, FieldsNames);
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		DocumentTables.MaterialsAndWorks.Load(CurrentTabularSection);
	EndIf;
	If Not ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.RegisteredSeparately Then
		
		FieldsNames.ProductCostElement   = "ProductCostElement";
		FieldsNames.BatchesIndicationStatus = 0;
		FieldsNames.Purpose          = "";
		
		// The WIP for processing is taken into account in the context of contracts, not divisions.
		PlacesOfAccounting.Delete("Work_5");
		
		InformationRegisters.ItemsLocationAttributes.FillInCollection(DocumentTables.Services, PlacesOfAccounting, FieldsNames);
		
	EndIf;
	
#EndRegion
	
EndProcedure

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.ProductionLots", "DeletionMark");
	
	Return Result;
	
EndFunction

// Returns the data of the document tables.
//
// Returns:
//	See Documents.SubcontractorReport2_5.CollectionOfTabularPartsOfGoods
//
Function DocumentTables()
	
	If AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
			And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined Then
		
		DocumentTables = AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange;
		
	Else
		DocumentTables = Documents.SubcontractorReport2_5.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
