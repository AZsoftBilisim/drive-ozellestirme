#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the sales conditions in the document of registration of surplus shipped goods.
//
// Parameters:
//	SalesTermsAndConditions - Structure - data to fill in.
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	LineOfBusiness = SalesTermsAndConditions.LineOfBusiness;
	
	If ValueIsFilled(SalesTermsAndConditions.ARAPCurrency) Then
		Currency = SalesTermsAndConditions.ARAPCurrency;
	EndIf;
	
	If SalesTermsAndConditions.Organization <> Organization
		And ValueIsFilled(SalesTermsAndConditions.Organization) Then
		
		Organization = SalesTermsAndConditions.Organization;
		
	EndIf;
	
	If Not SalesTermsAndConditions.Standard_ Then
		
		If ValueIsFilled(SalesTermsAndConditions.Counterparty)
			And SalesTermsAndConditions.Counterparty <> Counterparty Then
			
			Counterparty = SalesTermsAndConditions.Counterparty;
			
		EndIf;
		
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	Contract = SalesServer.GetDefaultContract(ThisObject,
														SalesTermsAndConditions.BusinessOperation,
														Currency,
														,
														SalesTermsAndConditions.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
	EndIf;
	
EndProcedure

// Fills in the sales conditions by default in the document of registration of surplus shipped goods.
//
Procedure FillInDefaultSalesConditions() Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If ValueIsFilled(Partner)
		Or Not ToUseTermsOfSales Then
		
		If BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor Then
			ContractBusinessTransaction = Enums.BusinessTransactions.TransferToCommissionAgent;
		ElsIf BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor Then
			ContractBusinessTransaction = Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
		Else
			ContractBusinessTransaction = Enums.BusinessTransactions.SaleToCustomer;
		EndIf;
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.RecognitionOfStockSurplusShippedToCustomer.EmptyRef());
		FilterParameters.Insert("BusinessTransactions", ContractBusinessTransaction);
		FilterParameters.Insert("ShipmentWithDeferredTransferOfTitle25",
								ContractBusinessTransaction = Enums.BusinessTransactions.SaleToCustomer);
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(Partner, FilterParameters);
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales
				Or (Terms <> DefaultSalesTerms.Terms
					And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				
				FillIn_TermsOfSales(DefaultSalesTerms);
				
			Else
				Terms = DefaultSalesTerms.Terms;
				
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
				
				Contract = SalesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction);
			EndIf;
			
		Else
			Terms = Undefined;
			
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the terms of sales by agreement in the document of registration of surplus shipped goods.
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms);
	
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(
								ThisObject,
								Documents.RecognitionOfStockSurplusShippedToCustomer);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	
	If ThisIsTraceableDocument
		Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers") Then
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer Then
		
		For CurIndex__ = 0 To Goods.Count() - 1 Do
			
			LineProducts_ = Goods[CurIndex__]; // LineOfATabularSection
			
			If Not ValueIsFilled(ReferenceOrder)
				And Not ValueIsFilled(LineProducts_.ReferenceOrder) Then
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Lệnh"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Распоряжение"" в строке %LineNumber% списка ""Товары""';
								|en = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list'; fa = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list';
								|it = 'Campo ""Disposizione"" non compilato nella riga %LineNumber% dell''elenco ""Articoli""';
								|pl = 'Pole ""Zamówienie"" w wierszu %LineNumber% listy ""Towary""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Emir"" alanı doldurulmamış'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", LineProducts_.LineNumber);
				ErrorField  = CommonClientServer.PathToTabularSection("Goods",
																				LineProducts_.LineNumber,
																				"ReferenceOrder");
				
				Common.MessageToUser(ErrorText, ThisObject, ErrorField, Undefined, Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	PartnersAndCounterparties.CheckPartnerContent(ThisObject, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.RecognitionOfStockSurplusShippedToCustomer.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes,
		ItemsAndDimensionsSelectionParameters);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FilledInBasedOnDocument = False;
	
	If TypeOf(FillingData) = Type("Structure") Then
	
		If FillingData.Property("DiscrepancyCertificate") Then
			FillInAccordingToDiscrepancyCertificate(FillingData);
			FilledInBasedOnDocument = True;
		
		ElsIf	FillingData.Property("DocumentBasis") Then
		
			DocumentBasis = FillingData.DocumentBasis;
			If TypeOf(DocumentBasis) = Type("Array") And ValueIsFilled(DocumentBasis) Then
				DocumentBasis = FillingData.DocumentBasis[0];
			EndIf;
			
			FilledInBasedOnDocument = True;
			BasisType = TypeOf(DocumentBasis);
			If  BasisType = Type("DocumentRef.SalesOrder") Then
				FillInOnTheCustomerSOrder(DocumentBasis);
			ElsIf BasisType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
				FillInRequestForReturnOfGoodsFromClient(DocumentBasis);
			Else
				FillInShipmentOfItemsToCustomer(DocumentBasis);
			EndIf;
		Else
			FillPropertyValues(ThisObject, FillingData);
		EndIf;
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsShipmentToCustomer") Then
		
		FillInShipmentOfItemsToCustomer(FillingData);
		FilledInBasedOnDocument = True;
		
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.RecognitionOfStockSurplusShippedToCustomer.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not FilledInBasedOnDocument Then
		
		InitializeDocument();
	
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
			Partner,
			New Structure("SelectedAgreement, EmptyDocumentLink", 
			Terms,
			Documents.RecognitionOfStockSurplusShippedToCustomer.EmptyRef()));
		
		If DefaultSalesTerms <> Undefined Then
			Currency = DefaultSalesTerms.Currency;
		EndIf;

	EndIf;
	
	ResponsiblePersonsServer.EmployeesInChargeOfFillingDocument(Ref, FillingData, StandardProcessing);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentAmount = Goods.Total("Sum");
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not BusinessOperation = Enums.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer Then
		ReferenceOrder = Undefined;
	EndIf;
	
	If ValueIsFilled(ReferenceOrder) Then
		For Each CurRow In Goods Do
			If Not ValueIsFilled(CurRow.ReferenceOrder) Then
				CurRow.ReferenceOrder = ReferenceOrder;
			EndIf;
		EndDo;
	EndIf;
	
	Sum = Goods.Total("Sum");
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(
		ThisObject,
		Documents.RecognitionOfStockSurplusShippedToCustomer);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods");
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillOutTypesOfDocumentInventory();
		
	EndIf;
	
	If IsNew()
		And Not ValueIsFilled(Number) Then
		
		SetNewNumber();
		
	EndIf;
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.RecognitionOfStockSurplusShippedToCustomer.AccountingAccountSettings_());
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.RecognitionOfStockSurplusShippedToCustomer.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", InventoriesServer.ParametersForFillingInventoryTypes());
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInAccordingToDiscrepancyCertificate(FillingData)

	DiscrepancyCertificate = FillingData.DiscrepancyCertificate;
	BaseDocumentForDiscrepancyReport = FillingData.BasisOfAct;

	QueryText =
	"SELECT
	|	DataHeader.Partner                 AS Partner,
	|	DataHeader.Counterparty              AS Counterparty,
	|	DataHeader.Terms              AS Terms,
	|	DataHeader.Contract                 AS Contract,
	|	VALUE(Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer) AS BusinessOperation,
	|	DataHeader.Organization             AS Organization,
	|	DataHeader.LineOfBusiness AS LineOfBusiness,
	|	DataHeader.Department           AS Department,
	|	DataHeader.SalesOpportunity                  AS SalesOpportunity,
	|	DataHeader.Currency                  AS Currency,
	|	DataHeader.Ref                  AS BaseDocumentForDiscrepancyReport
	|FROM
	|	Document.GoodsShipmentToCustomer AS DataHeader
	|WHERE
	|	DataHeader.Ref = &BaseDocumentForDiscrepancyReport
	|
	|UNION ALL
	|
	|SELECT
	|	DataHeader.Partner                 AS Partner,
	|	DataHeader.Counterparty              AS Counterparty,
	|	DataHeader.Terms              AS Terms,
	|	DataHeader.Contract                 AS Contract,
	|	VALUE(Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer) AS BusinessOperation,
	|	DataHeader.Organization             AS Organization,
	|	DataHeader.LineOfBusiness AS LineOfBusiness,
	|	DataHeader.Department           AS Department,
	|	DataHeader.SalesOpportunity                  AS SalesOpportunity,
	|	DataHeader.Currency                  AS Currency,
	|	DataHeader.Ref                  AS BaseDocumentForDiscrepancyReport
	|FROM
	|	Document.CustomerInvoice AS DataHeader
	|WHERE
	|	DataHeader.Ref = &BaseDocumentForDiscrepancyReport
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ActOfDiscrepancies.Products          AS Products,
	|	ActOfDiscrepancies.Characteristic        AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	ActOfDiscrepancies.Count - ActOfDiscrepancies.CountByDocument AS Count,
	|	CASE
	|		WHEN ActOfDiscrepancies.Count - ActOfDiscrepancies.CountByDocument <> 0
	|			AND ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.GoodsShipmentToCustomer
	|			THEN (ActOfDiscrepancies.Sum - ActOfDiscrepancies.SumByDocument) / (ActOfDiscrepancies.Count - ActOfDiscrepancies.CountByDocument)
	|		WHEN ActOfDiscrepancies.Count - ActOfDiscrepancies.CountByDocument <> 0
	|			THEN (ActOfDiscrepancies.AmountIncludingVAT - ActOfDiscrepancies.AmountIncludingVATByDocument) / (ActOfDiscrepancies.Count - ActOfDiscrepancies.CountByDocument)
	|		ELSE
	|			0
	|	END AS Price,
	|	CASE
	|		WHEN ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.GoodsShipmentToCustomer
	|			THEN ActOfDiscrepancies.Sum - ActOfDiscrepancies.SumByDocument
	|		ELSE
	|			ActOfDiscrepancies.AmountIncludingVAT - ActOfDiscrepancies.AmountIncludingVATByDocument
	|	END                                        AS Sum,
	|	ActOfDiscrepancies.Series                 AS Series,
	|	ActOfDiscrepancies.BatchesIndicationStatus   AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ActOfDiscrepancies.SalesOrder IN (
	|	                                VALUE(Document.SalesOrder.EmptyRef),
	|	                                VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                                VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                                VALUE(Document.SourceDocument.EmptyRef),
	|	                                UNDEFINED
	|	                                )
	|			THEN ActOfDiscrepancies.SaleOfGoodsAndServices
	|		ELSE
	|			ActOfDiscrepancies.SalesOrder
	|	END                                        AS ReferenceOrder
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS ActOfDiscrepancies
	|WHERE
	|	ActOfDiscrepancies.Ref = &DiscrepancyCertificate
	|	AND ActOfDiscrepancies.SaleOfGoodsAndServices = &BaseDocumentForDiscrepancyReport
	|	AND ActOfDiscrepancies.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit)
	|";

	Query = New Query(QueryText);
	Query.SetParameter("BaseDocumentForDiscrepancyReport", BaseDocumentForDiscrepancyReport);
	Query.SetParameter("DiscrepancyCertificate", DiscrepancyCertificate);
	
	QueryResults = Query.ExecuteBatch();
	
	HeaderAttributes = QueryResults[QueryResults.UBound() - 1].Select();
	GoodsTable = QueryResults[QueryResults.UBound()].Unload();
	
	HeaderAttributes.Next();
	FillPropertyValues(ThisObject, HeaderAttributes);
	
	Goods.Load(GoodsTable);

EndProcedure

Procedure FillInShipmentOfItemsToCustomer(DocumentBasis)
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(
		DocumentBasis,
		CheckParameters);
	
	QueryText = 
	"SELECT
	|	DataHeader.Partner                 AS Partner,
	|	DataHeader.Counterparty              AS Counterparty,
	|	DataHeader.Terms              AS Terms,
	|	DataHeader.Contract                 AS Contract,
	|	VALUE(Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer) AS BusinessOperation,
	|	DataHeader.Organization             AS Organization,
	|	DataHeader.LineOfBusiness AS LineOfBusiness,
	|	DataHeader.Department           AS Department,
	|	DataHeader.SalesOpportunity                  AS SalesOpportunity,
	|	DataHeader.Currency                  AS Currency
	|FROM
	|	Document.GoodsShipmentToCustomer AS DataHeader
	|WHERE
	|	DataHeader.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TheseProducts.Products        AS Products,
	|	TheseProducts.Characteristic      AS Characteristic,
	|	CASE 
	|		WHEN TheseProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN TheseProducts.Price
	|		ELSE
	|			TheseProducts.Price / ISNULL(&QueryTextPackagingFactor, 1)
	|	END                            AS Price,
	|	TheseProducts.Series               AS Series,
	|	TheseProducts.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	CASE
	|		WHEN TheseProducts.SalesOrder IN (
	|	                       VALUE(Document.SalesOrder.EmptyRef),
	|	                       VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                       VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                       UNDEFINED
	|	                       )
	|				AND TheseProducts.Ref.Patch
	|			THEN TheseProducts.Ref.CorrectedDocument
	|		WHEN TheseProducts.SalesOrder IN (
	|	                       VALUE(Document.SalesOrder.EmptyRef),
	|	                       VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                       VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                       UNDEFINED
	|	                       )
	|			THEN TheseProducts.Ref
	|		WHEN CAST(TheseProducts.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|				AND TheseProducts.Ref.Patch
	|			THEN TheseProducts.Ref.CorrectedDocument
	|		WHEN CAST(TheseProducts.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|			THEN TheseProducts.Ref
	|		WHEN CAST(TheseProducts.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|				AND TheseProducts.Ref.Patch
	|			THEN TheseProducts.Ref.CorrectedDocument
	|		WHEN CAST(TheseProducts.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|			THEN TheseProducts.Ref
	|		ELSE
	|			TheseProducts.SalesOrder
	|	END                            AS ReferenceOrder
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS TheseProducts
	|WHERE
	|	TheseProducts.Ref = &DocumentBasis
	|";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TheseProducts.Package",
			"TheseProducts.Products"));
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResults = Query.ExecuteBatch();
	
	HeaderAttributes = QueryResults[QueryResults.UBound() - 1].Select();
	GoodsTable = QueryResults[QueryResults.UBound()].Unload();
	
	HeaderAttributes.Next();
	FillPropertyValues(ThisObject, HeaderAttributes);
	
	Goods.Load(GoodsTable);
	
EndProcedure

Procedure FillInOnTheCustomerSOrder(DocumentBasis)
	
	QueryText = 
	"SELECT
	|	DataHeader.Partner                 AS Partner,
	|	DataHeader.Counterparty              AS Counterparty,
	|	DataHeader.Terms              AS Terms,
	|	DataHeader.Contract                 AS Contract,
	|	VALUE(Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer) AS BusinessOperation,
	|	DataHeader.Organization             AS Organization,
	|	DataHeader.LineOfBusiness AS LineOfBusiness,
	|	DataHeader.Department           AS Department,
	|	DataHeader.SalesOpportunity                  AS SalesOpportunity,
	|	DataHeader.Currency                  AS Currency
	|FROM
	|	Document.SalesOrder AS DataHeader
	|WHERE
	|	DataHeader.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	Assignments.Ref                 AS Purpose,
	|	GoodsTable.Price                AS Price,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	SalesOrderTable.Ref        AS ReferenceOrder
	|FROM
	|	Document.SalesOrder.Goods AS GoodsTable
	|LEFT JOIN
	|	Document.SalesOrder AS SalesOrderTable
	|ON
	|	GoodsTable.Ref = SalesOrderTable.Ref
	|LEFT JOIN
	|	Catalog.Assignments AS Assignments
	|ON
	|	CAST(Assignments.OrderDocument AS Document.SalesOrder) = SalesOrderTable.Ref
	|	AND Assignments.LineOfBusiness = SalesOrderTable.LineOfBusiness
	|	AND Assignments.Partner = SalesOrderTable.Partner
	|	AND Assignments.Contract = SalesOrderTable.Contract
	|WHERE
	|	GoodsTable.Ref = &DocumentBasis
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResults = Query.ExecuteBatch();
	
	HeaderAttributes = QueryResults[QueryResults.UBound() - 1].Select();
	GoodsTable = QueryResults[QueryResults.UBound()].Unload();
	
	HeaderAttributes.Next();
	FillPropertyValues(ThisObject, HeaderAttributes);
	
	Goods.Load(GoodsTable);
	
EndProcedure

Procedure FillInRequestForReturnOfGoodsFromClient(DocumentBasis)
	
	QueryText = 
	"SELECT
	|	DataHeader.Partner                 AS Partner,
	|	DataHeader.Counterparty              AS Counterparty,
	|	DataHeader.Terms              AS Terms,
	|	DataHeader.Contract                 AS Contract,
	|	VALUE(Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer) AS BusinessOperation,
	|	DataHeader.Organization             AS Organization,
	|	DataHeader.LineOfBusiness AS LineOfBusiness,
	|	DataHeader.Department           AS Department,
	|	DataHeader.SalesOpportunity                  AS SalesOpportunity,
	|	DataHeader.Currency                  AS Currency
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DataHeader
	|WHERE
	|	DataHeader.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	Assignments.Ref                 AS Purpose,
	|	GoodsTable.Price                AS Price,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	ReturnRequestTable.Ref     AS ReferenceOrder
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS GoodsTable
	|	LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequestTable
	|		ON GoodsTable.Ref = ReturnRequestTable.Ref
	|	LEFT JOIN Catalog.Assignments AS Assignments
	|		ON CAST(Assignments.OrderDocument AS Document.RequestForReturnOfGoodsFromCustomer) = ReturnRequestTable.Ref
	|			AND Assignments.LineOfBusiness = ReturnRequestTable.LineOfBusiness
	|			AND Assignments.Partner = ReturnRequestTable.Partner
	|			AND Assignments.Contract = ReturnRequestTable.Contract
	|WHERE
	|	GoodsTable.Ref = &DocumentBasis
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResults = Query.ExecuteBatch();
	
	HeaderAttributes = QueryResults[QueryResults.UBound() - 1].Select();
	GoodsTable = QueryResults[QueryResults.UBound()].Unload();
	
	HeaderAttributes.Next();
	FillPropertyValues(ThisObject, HeaderAttributes);
	
	Goods.Load(GoodsTable);
	
EndProcedure

Procedure InitializeDocument()
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillInProductTrackingDataInTabularPartsOfProducts()
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
		Contract,
		Department,
		Partner,
		Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	
	If BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor Then
		FieldsNames.Purpose = "";
	EndIf;
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(Goods, PlacesOfAccounting, FieldsNames);
	
EndProcedure

Procedure FillOutTypesOfDocumentInventory()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTOriginalProductTable
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|///////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.EmptyRef) AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TaxationOfOrganization,
	|	UNDEFINED AS GoodsOwner,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef) AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TTOriginalProductTable AS TableOfGoods
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableOfGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|	OR InventoryKinds.Organization <> &Organization
	|	OR &RefillInventoryKinds
	|;
	|
	|///////////////////////////////////////////////////
	|DROP TTOriginalProductTable
	|";
	
	TempTablesManager = New TempTablesManager;
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("TableOfGoods",			Goods.Unload(, "LineNumber, Products, InventoryOwnerAttribute"));
	Query.SetParameter("Organization",			Organization);
	Query.SetParameter("Posted",				Posted);
	Query.SetParameter("BusinessOperation",	BusinessOperation);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	
	InventoriesServer.FillStockTypesByDefault(TempTablesManager, Goods);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
