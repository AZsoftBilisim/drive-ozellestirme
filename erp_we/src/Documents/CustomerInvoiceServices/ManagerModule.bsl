#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("DocumentCorrection");
	
	CustomerInvoiceServicesLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CustomerInvoiceServices") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);

		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextBonusPoints(Query, QueryTexts, Registers, DocumentRef);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		CustomerInvoiceServicesLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	Documents.SaleAdjustment.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddCreateReportBasedOnPaymentInvoiceCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	CustomerInvoiceServicesLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds a command to create a document "Report of completed work".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddCreateBasedOnOrderCommand_(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerInvoiceServices) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateActOfCompletedWorksOnBasisOfOrder";
		CreateBasedOnCommand.Id = "CreateActOfCompletedWorksOnBasisOfOrder";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Biên bản nghiệm thu công việc';
												|ru = 'Акт выполненных работ';
												|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
												|it = 'Verbale di consegna dei lavori effettuati';
												|pl = 'Protokół wykonanych prac';
												|tr = 'Müşteri faturası - Hizmetler'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command to create a document "Report of completed work".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands.
// Returns:
//	 ValueTableRow, Undefined - the command to output to the submenu. 
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerInvoiceServices) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CustomerInvoiceServices.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CustomerInvoiceServices);
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.PriceAnalysis.AddReportCommand(ReportsCommands);
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	Reports.VariancesFromSalesTermsAndConditions.AddReportCommand(ReportsCommands);
	
	Reports.DiscountsAppliedInDocument.AddReportCommand(ReportsCommands);
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfActImplementationCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	// ListForm
	ReportCommand = Reports.PriceAnalysis.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ListForm";
		ReportCommand.Importance = "Important";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ListForm";
		ReportCommand.Order = 2;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ListForm";
		ReportCommand.Order = 3;
	EndIf;
	If AccessRight("View", Metadata.Reports.ActualProductCost) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager               = Metadata.Reports.ActualProductCost.FullName();
		ReportCommand.Presentation               = NStr("vi = 'Giá vốn sản phẩm thực tế';
														|ru = 'Фактическая себестоимость продукции';
														|en = 'Actual product cost'; fa = 'بهای واقعی محصول';
														|it = 'Costo di produzione effettivo';
														|pl = 'Faktyczne koszty własne produkcji';
														|tr = 'İmal edilen ürünlerin gerçek maliyeti'");
		ReportCommand.VariantKey 				 = "ActualCostOfProductionContext";
		ReportCommand.Order                     = 50;
		ReportCommand.MultipleChoice 		 = False;
		ReportCommand.Importance 					 = "Important";
				
	EndIf;
	CustomerInvoiceServicesLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// This function determines the details of the selected document
//
// Parameters:
//	DocumentRef - DocumentRef - Link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.InvoiceByOrders AS InvoiceByOrders,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		Date = Selection.Date;
		Organization = Selection.Organization;
		Partner = Selection.Partner;
		Counterparty = Selection.Counterparty;
		Contract = Selection.Contract;
		LineOfBusiness = Selection.LineOfBusiness;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		Currency = Selection.Currency;
		ARAPCurrency = Selection.ARAPCurrency;
		ByOrder = Selection.InvoiceByOrders;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		Rate = Selection.CourseNumerator;
		Repetition = Selection.CourseDenominator;
		
	Else
		
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		ByOrder = False;
		DocumentAmount = 0;
		AmountARAP = 0;
		Rate = 1;
		Repetition = 1;
		
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("ByOrder", ByOrder);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("BusinessOperation", Enums.BusinessTransactions.SaleToCustomer);
	AttributesStructure1.Insert("Rate", Rate);
	AttributesStructure1.Insert("Repetition", Repetition);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	
	Return AttributesStructure1;

EndFunction

// Fills in tables of services and discounts based on selection data or an array of orders
//
// Parameters:
//	SelectionData_             - Structure - fields that will be used to select order balances for filling in the document
//	Services                   - FormDataCollection - table of services which will be placed the remains of the orders
//	DiscountsMarkups            - FormDataCollection - discount table where discounts on orders will be placed
//	BonusPointAccrual - FormDataCollection - the table of bonus points, in which the accruals for orders will be placed
//	AnArrayOfOrders            - Array - orders for which balances will be selected
//	FillParameters      - Structure:
//		* DisplayMessage_1 - Boolean - indicates whether the message should be displayed.
//		* UseAdvancedFeaturesOfSalesOrder - Boolean
//		* CheckOrderOfCalculations - Boolean - True by default, this means that if Orders with DIFFERENT 
//		                                      payment orders are FOUND, a message will be displayed and no filling will be made.
Procedure FillByOrderBalances(SelectionData_,
	                                 Services,
	                                 DiscountsMarkups,
	                                 BonusPointAccrual,
	                                 AnArrayOfOrders = Undefined,
	                                 FillParameters) Export
	
	DisplayMessage_1 = True;
	
	If FillParameters.Property("DisplayMessage_1") Then 
		DisplayMessage_1 = FillParameters.DisplayMessage_1;
	EndIf;
	
	CheckOrderOfCalculations = True;
	
	If FillParameters.Property("CheckOrderOfCalculations") Then 
		CheckOrderOfCalculations = FillParameters.CheckOrderOfCalculations;
	EndIf;
	
	// Data on order service balances
	RequestResultForOrderBalances = GetQueryResultsForOrderBalances(
		SelectionData_,
		FillParameters,
		AnArrayOfOrders);
	
	If RequestResultForOrderBalances[1].IsEmpty() 
		And RequestResultForOrderBalances[2].IsEmpty() 
		And GetFunctionalOption("UseShipmentByRowsInSalesOrder")
		And DisplayMessage_1 Then
		
		ErrorText = SalesServer.ErrorTextNoProductsAvailableForShipment(Enums.SalesRegistrationOptions.CustomerInvoiceServices);
		Raise ErrorText;
		
	EndIf;
	
	ArrayOfCustomersOrders = New Array();
	ArrayOfARAPObjectsSettings = New Array();
	ServiceSelection = RequestResultForOrderBalances[1].Select();
	
	While ServiceSelection.Next() Do
		If ArrayOfCustomersOrders.Find(ServiceSelection.SalesOrder) = Undefined Then
			ArrayOfCustomersOrders.Add(ServiceSelection.SalesOrder);
		EndIf;
		If CheckOrderOfCalculations
			And ValueIsFilled(ServiceSelection.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(ServiceSelection.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(ServiceSelection.ARAPObjectSettings);
		EndIf;
	EndDo;
	
	If AnArrayOfOrders = Undefined
		And CheckOrderOfCalculations 
		And ArrayOfARAPObjectsSettings.Count() > 1 Then
		Common.MessageToUser(NStr("vi = 'Trong các đơn hàng đã tìm thấy, khác trường ""Trình tự hạch toán""';
									|ru = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|en = 'The ""Payment terms"" field data is different for the found orders'; fa = 'The ""Payment terms"" field data is different for the found orders';
									|it = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|pl = 'The ""Payment terms"" field data is different for the found orders';
									|tr = 'Bulunan siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		Return;
	EndIf;
	
	// Getting a discount/mark-up table
	QueryText =
	"SELECT
	|	DiscountsMarkups.Ref AS SalesOrder,
	|	DiscountsMarkups.ConnectionKey AS ConnectionKey,
	|	DiscountsMarkups.DiscountMarkup AS DiscountMarkup,
	|	DiscountsMarkups.Sum AS Sum
	|FROM
	|	Document.SalesOrder.DiscountsMarkups AS DiscountsMarkups
	|WHERE
	|	DiscountsMarkups.Ref IN (&ArrayOfCustomersOrders)
	|UNION ALL
	|SELECT
	|	DiscountsMarkups.Ref AS SalesOrder,
	|	DiscountsMarkups.ConnectionKey AS ConnectionKey,
	|	DiscountsMarkups.DiscountMarkup AS DiscountMarkup,
	|	DiscountsMarkups.Sum AS Sum
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.DiscountsMarkups AS DiscountsMarkups
	|WHERE
	|	DiscountsMarkups.Ref IN (&ArrayOfCustomersOrders)
	|";
	Query = New Query(QueryText);
	Query.SetParameter("ArrayOfCustomersOrders", ArrayOfCustomersOrders);
	DiscountsOrderMargins = Query.Execute().Unload();
	
	// Clearing the discount/mark-up table of the current object
	DiscountsMarkups.Clear();
	
	UseLoyaltyPrograms = GetFunctionalOption("UseLoyaltyPrograms");
	
	If UseLoyaltyPrograms Then
		
		// Getting a table of bonus points
		QueryText =
		"SELECT 
		|	TabularSection.Ref AS SalesOrder,
		|	TabularSection.ConnectionKey AS ConnectionKey,
		|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
		|	TabularSection.LoyaltyProgram.BonusConversionCurrency AS BonusConversionCurrency,
		|	TabularSection.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency AS ConversionRateOfBonusesIntoCurrency,
		|	DATEADD(TabularSection.AccrualDate, DAY,
		|		DATEDIFF(
		|			BEGINOFPERIOD(TabularSection.Ref.Date, DAY),
		|			BEGINOFPERIOD(&CurrentDate, DAY),
		|			DAY)
		|	) AS AccrualDate,
		|	CASE
		|		WHEN TabularSection.DateOfDeduction = DATETIME(1, 1, 1)
		|			THEN TabularSection.DateOfDeduction
		|		ELSE
		|			DATEADD(
		|				TabularSection.DateOfDeduction,
		|				DAY,
		|				DATEDIFF(
		|					BEGINOFPERIOD(TabularSection.Ref.Date, DAY),
		|					BEGINOFPERIOD(&CurrentDate, DAY),
		|					DAY))
		|	END AS DateOfDeduction,
		|	TabularSection.AmountOfBonusPoints AS AmountOfBonusPoints
		|FROM
		|	Document.SalesOrder.BonusPointAccrual AS TabularSection
		|WHERE
		|	TabularSection.Ref IN (&ArrayOfCustomersOrders)
		|UNION ALL
		|SELECT
		|	TabularSection.Ref,
		|	TabularSection.ConnectionKey,
		|	TabularSection.LoyaltyProgram,
		|	TabularSection.LoyaltyProgram.BonusConversionCurrency,
		|	TabularSection.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency,
		|	TabularSection.AccrualDate,
		|	TabularSection.DateOfDeduction,
		|	TabularSection.AmountOfBonusPoints
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.BonusPointAccrual AS TabularSection
		|WHERE
		|	TabularSection.Ref IN (&ArrayOfCustomersOrders)
		|";
		Query = New Query(QueryText);
		Query.SetParameter("ArrayOfCustomersOrders", ArrayOfCustomersOrders);
		Query.SetParameter("CurrentDate", CurrentSessionDate());
		AccrualOfBonusPointsOfOrder = Query.Execute().Unload();
		
		LoyaltyProgram = New Structure("LoyaltyProgram, 
			|BonusConversionCurrency, 
			|ConversionRateOfBonusesIntoCurrency,
			|StructureOfCurrencyConversionRates");
		
		LoyaltyPrograms = AccrualOfBonusPointsOfOrder.Copy();
		
		LoyaltyPrograms.GroupBy("LoyaltyProgram, 
			|BonusConversionCurrency, 
			|ConversionRateOfBonusesIntoCurrency");
		
		If LoyaltyPrograms.Count() > 1
			And DisplayMessage_1 Then
			
			ErrorText = NStr("vi = 'Đã tìm thấy các chương trình khách hàng thân thiết khác để tính điểm thưởng. Không thể giao các đơn hàng 
				| có chương trình tích điểm khác nhau vào một chứng từ.';
				|ru = 'Обнаружены разные программы лояльности для начисления бонусных баллов. Заказы 
				|с разными бонусными программами лояльности не могут быть отгружены в одном документе.';
				|en = 'Different loyalty programs are found for accrual of bonus points. Orders 
				| with different loyalty programs cannot be shipped within one document.'; fa = 'Different loyalty programs are found for accrual of bonus points. Orders 
				| with different loyalty programs cannot be shipped within one document.';
				|it = 'Sono stati rilevati programmi fedeltà per il calcolo di punti bonus. Gli ordini 
				|con diversi programmi bonus fedeltà non possono essere caricati in un documento.';
				|pl = 'Wykryto różne programy lojalnościowe do naliczenia punktów bonusowych. Zamówienia  
				|z różnymi lojalnościowymi programami bonusowymi nie mogą być wystawione w jednym dokumencie.';
				|tr = 'Bonus puan vermek için farklı sadakat programları tespit edilmiştir. Farklı sadakat programlarına sahip siparişler
				| aynı belge içinde gönderilemez.'");
			Raise ErrorText;
		ElsIf LoyaltyPrograms.Count() = 1 Then
			FillPropertyValues(LoyaltyProgram, LoyaltyPrograms[0]);
			
			LoyaltyProgram.StructureOfCurrencyConversionRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(LoyaltyProgram.BonusConversionCurrency, 
				CurrentSessionDate(),
				SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SelectionData_.Organization));
			
		EndIf;
		
	EndIf;
	
	// Clearing the bonus points table of the current object
	BonusPointAccrual.Clear();
	
	Query = New Query;
	Query.SetParameter("ArrayOfCustomersOrders", ArrayOfCustomersOrders);
	Query.SetParameter("DocumentCurrency",       SelectionData_.Currency);
		
	Query.Text =
	"SELECT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Ref                    AS SalesOrder,
	|	TheOrdersTable.Currency                    AS Currency,
	|	TheOrdersTable.PriceIncludesVAT           AS PriceIncludesVAT,
	|	CASE
	|		WHEN
	|			TheOrdersTable.Currency <> &DocumentCurrency
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ConvertToDocumentCurrency
	|FROM
	|	Document.SalesOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN (&ArrayOfCustomersOrders)
	|;
	|SELECT DISTINCT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Currency                    AS Currency,
	|	TheOrdersTable.Organization.LocalAccountingCurrency AS BaseCurrency
	|FROM
	|	Document.SalesOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN (&ArrayOfCustomersOrders)
	|	AND TheOrdersTable.Currency <> &DocumentCurrency
	|
	|";
	
	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[0]; // QueryResult
	OrderDetails_ = QueryResult.Select();
	
	TableOfExchangeRates = New ValueTable;
	TableOfExchangeRates.Columns.Add("Currency",    New TypeDescription("CatalogRef.Currencies"));
	TableOfExchangeRates.Columns.Add("Date",      New TypeDescription("Date"));
	TableOfExchangeRates.Columns.Add("CourseNumerator", New TypeDescription("Number"));
	TableOfExchangeRates.Columns.Add("CourseDenominator", New TypeDescription("Number"));
	
	QueryResult = QueryResultsArray[1]; // QueryResult
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		NewRow = TableOfExchangeRates.Add();
		FillPropertyValues(NewRow, Selection);
		
		Currency_Rates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Selection.Currency, Selection.Date, Selection.BaseCurrency);
		NewRow.CourseNumerator = Currency_Rates.CourseNumerator;
		NewRow.CourseDenominator = Currency_Rates.CourseDenominator;
		
	EndDo;
	
	If TableOfExchangeRates.Count() > 0 Then
		StructureOfNewCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(SelectionData_.Currency, CurrentSessionDate(),
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SelectionData_.Organization));
	EndIf;
	
	ServiceSelection.Reset();
	While ServiceSelection.Next() Do
		
		ProductVATRate = ServiceSelection.VATRate;
		
		RecalculateAmounts = (ServiceSelection.Count <> ServiceSelection.QuantityInOrder);
		
		ExcludeProperties_ = Undefined;
		If RecalculateAmounts Then
			// If it is necessary to recalculate the amounts, then the details listed in the details will be recalculated based on the amount of mutual settlements.
			ExcludeProperties_ = "Sum, VATAmount, DiscountMarkupAmount, ManualDiscount";
		EndIf;
		
		TabRow = Services.Add();
		FillPropertyValues(TabRow, ServiceSelection, , ExcludeProperties_);
		TabRow.VATRate = ProductVATRate;
		
		If RecalculateAmounts Then
			TabRow.AmountIncludingVAT = TabRow.AmountARAP;
		EndIf;
		
		TabRow.Count = ServiceSelection.Count;
		
		OrderDetails_.Reset();
		OrderFound = OrderDetails_.FindNext(TabRow.SalesOrder, "SalesOrder");
		
		FilterParameters = New Structure("Currency,Date", OrderDetails_.Currency, OrderDetails_.Date);
		CurrencyExchangeRate = TableOfExchangeRates.FindRows(FilterParameters);
		
		If OrderFound And OrderDetails_.ConvertToDocumentCurrency Then
			
			If CurrencyExchangeRate.Count() = 1 Then
			
				TabRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.Price,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				TabRow.AmountIncludingVAT = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.AmountIncludingVAT,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				RecalculateAmounts = True;
			EndIf;
			
		EndIf;

		DiscountConversionRate = ?(RecalculateAmounts, TabRow.Count / ServiceSelection.QuantityInOrder, 1);
		If DiscountConversionRate <> 1 Then
			TabRow.DiscountMarkupAmount = Round(ServiceSelection.DiscountMarkupAmount * DiscountConversionRate,2);
			TabRow.ManualDiscount = Round(ServiceSelection.ManualDiscount * DiscountConversionRate,2);

			TabRow.AmountOfBonusPointsToDeduction = Round(ServiceSelection.AmountOfBonusPointsToDeduction * DiscountConversionRate,2);
			TabRow.AmountOfBonusPointsToDeductionInCurrency = Round(ServiceSelection.AmountOfBonusPointsToDeductionInCurrency * DiscountConversionRate,2);
			TabRow.AmountOfEarnedBonusPointsInCurrency = Round(ServiceSelection.AmountOfEarnedBonusPointsInCurrency * DiscountConversionRate,2);
		EndIf;
		
		If RecalculateAmounts Then
			
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(
				TabRow, 
				OrderDetails_.PriceIncludesVAT, 
				TabRow.PercentRateOfAutomaticDiscountMarkup<>0,
				TabRow.PercentRateOfManualDiscount<>0,
				OrderDetails_.ConvertToDocumentCurrency, 
				"Count");
			
			If OrderFound And OrderDetails_.ConvertToDocumentCurrency And CurrencyExchangeRate.Count() = 1 Then
				TabRow.DiscountMarkupAmount = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.DiscountMarkupAmount,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				TabRow.ManualDiscount = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.ManualDiscount,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				TabRow.AmountOfBonusPointsToDeductionInCurrency = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.AmountOfBonusPointsToDeductionInCurrency,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				TabRow.AmountOfEarnedBonusPointsInCurrency = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.AmountOfEarnedBonusPointsInCurrency,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
			EndIf;

		EndIf;
		
		// Formation of the tabular part of discounts
		AmountForAllocation = TabRow.DiscountMarkupAmount;
		
		If TabRow.ConnectionKey <> 0 Then
			For Each OrderDiscountsRow In DiscountsOrderMargins.FindRows(New Structure("SalesOrder,ConnectionKey", TabRow.SalesOrder, TabRow.ConnectionKey)) Do
				
				DiscountsRow = DiscountsMarkups.Add();
				FillPropertyValues(DiscountsRow, OrderDiscountsRow);
				DiscountsRow.Sum = DiscountConversionRate * DiscountsRow.Sum;
				
				If OrderFound And OrderDetails_.ConvertToDocumentCurrency And CurrencyExchangeRate.Count() > 0 Then
					DiscountsRow.Sum = ProcessingOfExchangeRatesTM.ConvertAtRate(
						DiscountsRow.Sum,
						CurrencyExchangeRate[0],
						StructureOfNewCurrencyRates);
					AmountForAllocation = AmountForAllocation - DiscountsRow.Sum;
				EndIf;
				
			EndDo;
		EndIf;
		
		If OrderFound And OrderDetails_.ConvertToDocumentCurrency And AmountForAllocation <> 0 Then
			DiscountsRow.Sum = DiscountsRow.Sum + AmountForAllocation;
		EndIf;

		If UseLoyaltyPrograms Then
			
			// Formation of a tabular accrual of bonus points
			AmountForAllocation = TabRow.AmountOfEarnedBonusPointsInCurrency;
			If OrderFound
				And ValueIsFilled(LoyaltyProgram.BonusConversionCurrency)
				And SelectionData_.Currency <> LoyaltyProgram.BonusConversionCurrency Then
				
				AmountForAllocation = ProcessingOfExchangeRatesTM.ConvertAtRate(
					AmountForAllocation,
					StructureOfNewCurrencyRates,
					LoyaltyProgram.StructureOfCurrencyConversionRates);
					
			EndIf;
			
			If AmountForAllocation <> 0
				And ValueIsFilled(LoyaltyProgram.ConversionRateOfBonusesIntoCurrency) Then
				
				AmountForAllocation = AmountForAllocation / LoyaltyProgram.ConversionRateOfBonusesIntoCurrency;
			EndIf;
			
			If TabRow.ConnectionKey <> 0 Then
				For Each OrderBonusPointsLine In AccrualOfBonusPointsOfOrder.FindRows(New Structure("SalesOrder,ConnectionKey", TabRow.SalesOrder, TabRow.ConnectionKey)) Do
					
					BonusPointsLine = BonusPointAccrual.Add();
					FillPropertyValues(BonusPointsLine, OrderBonusPointsLine);
					BonusPointsLine.AmountOfBonusPoints = DiscountConversionRate * BonusPointsLine.AmountOfBonusPoints;
					
					AmountForAllocation = AmountForAllocation - BonusPointsLine.AmountOfBonusPoints;
					
				EndDo;
			EndIf;
			
			If OrderFound And AmountForAllocation <> 0 Then
				BonusPointsLine.AmountOfBonusPoints = BonusPointsLine.AmountOfBonusPoints + AmountForAllocation;
			EndIf;
			
		EndIf;
		
		If TMCommonUseClientServer.HasObjectAttribute(TabRow, "ProductsInSet") 
			And TMCommonUseClientServer.HasObjectAttribute(TabRow, "SetIndex")
			And ValueIsFilled(TabRow.ProductsInSet) Then
			TabRow.SetIndex = 1;
		EndIf;
		
	EndDo;
	
EndProcedure

// Initializes the status structure of the document
//
// Returns:
//	Structure - data on the status of document execution.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.DisplayCalculationsWithCustomersTable = 1;
	StructureState.DisplayShipmentTables = 2;
	StructureState.ThisIsAnInvoice = True;
	StructureState.ThereAreSummaryShipmentIndicators = True;
	StructureState.NameTSGoodsShipment = "Services";
	StructureState.RegisterNameShipmentOfServices = "ShipmentAndReturnReferences";
	StructureState.StructureOfAdditionalRequests = New Structure(
		"QueryTextTTGoodsOrderInvoiceShipped",
		QueryTextTTGoodsOrderInvoiceShipped());
	Return StructureState
	
EndFunction

// Returns the structure of document processing order parameters
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	
// Returns:
// Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = "Services";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Services", TableOfConditions);
	DocumentProcessingProcedure.NameOfFormElementIsSeparate = "ServicesWithAssignment";
	DocumentProcessingProcedure.NameOfGroupOfCommandElementsIsSeparate = "ServicesGroupTeamsSeparately";
	DocumentProcessingProcedure.OrderDetailsName = "InvoiceByOrders";
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.CustomerInvoiceServices, DocumentRef.CustomerInvoiceServices, FormDataStructure - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	If TypeOf(Object) = Type("DocumentObject.CustomerInvoiceServices")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.CustomerInvoiceServices") Then
		ObjectData = Common.ObjectAttributesValues(Object, "Organization,Date,Contract,LineOfBusiness,Department");
	EndIf;
	
	FillParameters.Organization = ObjectData.Organization;
	FillParameters.Date = ObjectData.Date;
	FillParameters.Contract = ObjectData.Contract;
	FillParameters.LineOfBusiness = ObjectData.LineOfBusiness;
	FillParameters.ImplementationOfWorksServices = True;
	FillParameters.Department = ObjectData.Department;
	
	Return FillParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"InvoiceByOrders,
			|Ref");
		OrderSales = StructureFillingData.InvoiceByOrders;
		ThereAreAdjustingEntries   = False;
		SalesServer.CheckForAdjustments(StructureFillingData.Ref, StructureFillingData.Ref, ThereAreAdjustingEntries);
	ElsIf FillingData = Undefined Then
		OrderSales = False;
		ThereAreAdjustingEntries   = False;
	Else
		OrderSales = FillingData.InvoiceByOrders;
		ThereAreAdjustingEntries   = False;
		SalesServer.CheckForAdjustments(FillingData.Ref, FillingData.Ref, ThereAreAdjustingEntries);
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";
	
	ParametersStructure.CourseNumerator                    = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                  = "Object.CourseDenominator";
	
	ParametersStructure.PathToTSData                    = "Object.Services";
	ParametersStructure.PropsNameTSOrder              = "SalesOrder";
	
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.InvoiceForOrders               = "Object.InvoiceByOrders";
	ParametersStructure.OrderBase                   = "Object.SalesOrder";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	
	ParametersStructure.FormItems.LabelCurrencies                    = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages                     = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations                   = "DecorationSettlementState";
	ParametersStructure.FormItems.PaymentSettlement                      = "CreditPaymentForm";
	ParametersStructure.FormItems.AmountOfTSSettlements            = "ServicesAmountARAP";
	ParametersStructure.FormItems.DebtLimitationText    = "DecorationDebtLimitation";
	ParametersStructure.FormItems.DebtLimitation = "ImageShipmentProhibited";
	ParametersStructure.FormItems.FinancialAccountingGroup           = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness          = "LineOfBusiness";
	
	ParametersStructure.CurrencyAndExchangeRateDocumentViewOnly             = ThereAreAdjustingEntries;
	ParametersStructure.DocumentCurrencyViewOnly                  = Not UserRightsCached.VarianceFromSalesTermsAndConditions() And OrderSales;
	ParametersStructure.MutualSettlementsCurrencyViewOnly             = Not UserRightsCached.VarianceFromSalesTermsAndConditions() And OrderSales;
	ParametersStructure.DonTShowCalculations                            = False;
	
	ParametersStructure.PathToTSDataPaymentSteps         			   = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText                             = "Form.PaymentStepsText";
	ParametersStructure.SourceOfAmountsTabularPart                     = True;
	ParametersStructure.DocumentAmountForm              			   = "Form.AmountTotal";
	ParametersStructure.PaymentStagesViewOnly                      = Not (UserRightsCached.VarianceFromSalesTermsAndConditions() Or Not OrderSales);
	ParametersStructure.InvoiceForSeveralOrdersIsPossible           = GetFunctionalOption("UseCustomerInvoicesForSeveralOrders");
	ParametersStructure.AmountOfDepositForContainerForm						   = "";
	ParametersStructure.AmountARAPByPackage        			   = "";
	
	ParametersStructure.ARAPObject                                 = "Object.Services.ARAPObject";
	
	Return ParametersStructure;
	
EndFunction

#Region BasisForPrint

// Returns the base structure based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.CustomerInvoice - The object of the document that you need to get the base text from.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation:
//     * Basis      - String - name of the foundation.
//     * BaseDocumentNumber - String - base number.
//     * ReferenceDocumentDateForPrintForms  - String - date of foundation.
//
Function StructureOfBaseForPrinting(Object) Export
	
	BaseStructure = BaseStructure(Object, Object.ARAPObjectSettings);
	
	Return BaseStructure;
	
EndFunction

// Returns a table of default values for the "Base" attribute"
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.CustomerInvoice - The document object to get the selection list from.
//
// Returns:
//	ValueTable - Table of values with Attributes of the bases:
//     * Basis      - String - name of the foundation.
//     * BaseDocumentNumber - String - base number.
//     * ReferenceDocumentDateForPrintForms  - String - date of foundation.
//
Function PrintBasisTable(Object) Export
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByCounterpartyContracts);
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		AddedRow.Basis = BaseStructure.Basis;
		
		If ValueIsFilled(BaseStructure.ReferenceDocumentDateForPrintForms) And ValueIsFilled(BaseStructure.BaseDocumentNumber) Then
			ExtendedText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 số %2 ngày %3';
						|ru = '%1 № %2 от %3';
						|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
						|it = '%1 № %2 dal %3';
						|pl = '%1 nr %2 z dnia %3.';
						|tr = '%2sayılı %3tarihli %1'"),
					BaseStructure.Basis, BaseStructure.BaseDocumentNumber, Format(BaseStructure.ReferenceDocumentDateForPrintForms, "DLF=DD"));
			
			AddedRow = TableOfBases_.Add();
			FillPropertyValues(AddedRow, BaseStructure);
			AddedRow.Basis = ExtendedText;
		EndIf;
	EndIf;
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByOrders);
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		AddedRow.Basis = BaseStructure.Basis;
	EndIf;
	
	Return TableOfBases_;
	
EndFunction

// Returns the base text based on the document data and the specified calculation order
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.CustomerInvoice - Object of the document to get the base text from
//	ARAPObjectSettings - EnumRef.ARAPObjectSettings - Procedure of settlements.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function BaseStructure(Object, ARAPObjectSettings)
	
	StructureBase = New Structure;
	StructureBase.Insert("Basis");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	
	If (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		And ValueIsFilled(Object.Contract) Then
		
		Query = New Query(
			"SELECT ALLOWED
			|	CounterpartyContracts.NameForPrinting AS Basis,
			|	CounterpartyContracts.Date AS ReferenceDocumentDateForPrintForms,
			|	CounterpartyContracts.Number AS BaseDocumentNumber
			|FROM
			|	Catalog.CounterpartyContracts AS CounterpartyContracts
			|WHERE
			|	CounterpartyContracts.Ref = &Ref");
		Query.SetParameter("Ref", Object.Contract);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			StructureBase.Basis = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
		
	ElsIf (ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		And Object.InvoiceByOrders Then
		
		AnArrayOfOrders = Undefined;
		If ValueIsFilled(Object.SalesOrder) Then
			AnArrayOfOrders = New Array;
			AnArrayOfOrders.Add(Object.SalesOrder);
		ElsIf Object.Services.Count() <> 0 Then 
			If TypeOf(Object) = Type("Structure") Then
				AnArrayOfOrders = Object.Services.UnloadColumn("SalesOrder");
			Else
				AnArrayOfOrders = Object.Services.Unload(,"SalesOrder").UnloadColumn("SalesOrder");
			EndIf;
		EndIf;
		
		If AnArrayOfOrders <> Undefined Then
		
			Query = New Query(
				"SELECT ALLOWED
				|	SalesOrders.NumberAccordingToCustomerData AS NumberAccordingToCustomerData,
				|	SalesOrders.DateAccordingToInformationFromCustomer  AS DateAccordingToInformationFromCustomer,
				|	SalesOrders.Number                AS Number,
				|	SalesOrders.Date                 AS Date,
				|	&SynonymForOrder                      AS Synonym
				|FROM
				|	Document.SalesOrder AS SalesOrders
				|WHERE
				|	SalesOrders.Ref IN(&AnArrayOfOrders)");
			
			Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
			Query.SetParameter("SynonymForOrder", NStr("vi = 'Đơn hàng của khách';
														|ru = 'Заказ клиента';
														|en = 'Sales order'; fa = 'سفارش فروش';
														|it = 'Ordine del cliente';
														|pl = 'Zamówienie klienta';
														|tr = 'Satış siparişi'"));
			Selection = Query.Execute().Select();
			
			TextForOrders = "";
			OneFoundation = Selection.Count() = 1;
			While Selection.Next() Do
				If ValueIsFilled(Selection.NumberAccordingToCustomerData) And ValueIsFilled(Selection.DateAccordingToInformationFromCustomer) Then
					TextForOrders = TextForOrders + ", " +
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = '%1 số %2 ngày %3';
								|ru = '%1 № %2 от %3';
								|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
								|it = '%1 № %2 dal %3';
								|pl = '%1 nr %2 z dnia %3.';
								|tr = '%2sayılı %3tarihli %1'"),
							Selection.Synonym, Selection.NumberAccordingToCustomerData, Format(Selection.DateAccordingToInformationFromCustomer, "DLF=DD"));
					DateForOrders  = Selection.DateAccordingToInformationFromCustomer;
					OrderNumber_1 = Selection.NumberAccordingToCustomerData;
				Else
					TextForOrders = TextForOrders + ", " + TMCommonUseClientServer.GenerateDocumentTitle(Selection, Selection.Synonym);
					DateForOrders  = Selection.Date;
					OrderNumber_1 = Selection.Number;
				EndIf;
			EndDo;
			StructureBase.Basis =  TrimAll(Mid(TextForOrders, 3));
			StructureBase.ReferenceDocumentDateForPrintForms = ?(OneFoundation, DateForOrders, "");
			StructureBase.BaseDocumentNumber = ?(OneFoundation,ObjectsPrefixesClientServer.NumberForPrinting(OrderNumber_1),"");
		EndIf;
		
	EndIf;
	
	Return StructureBase; // Returning the default value
	
EndFunction

#EndRegion

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CustomerInvoiceServicesLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - the text of the request to be reflected in the registration.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CustomerInvoiceServicesLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Partner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	ON ContactPersonsForPartners.Owner = ThisList.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region VATAccounting

// Initializes parameters for registering invoices (issued)
//
// Parameters:
//  Object		- DocumentObject.CustomerInvoiceServices, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Function ParametersForRegisteringInvoicesIssued(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	
	RegistrationParameters.Ref					= Object.Ref;
	RegistrationParameters.Date					= Object.Date;
	RegistrationParameters.Organization			= Object.Organization;
	RegistrationParameters.Counterparty				= Object.Counterparty;
	RegistrationParameters.VATTaxation		= Object.VATTaxation;
	
	RegistrationParameters.ImplementationOfWorksServices	= True;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
		
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, SalesOrder, Manager";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CashAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
EndProcedure

// Returns a structure with the name of the tabular parts of the document that store information about works.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Services - ValueTable, TabularSection, Undefined - data about services and works.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Services");
	
	Return DocumentTables;
	
EndFunction

// Forms a Presentation of the object in the main language.
// 
// Returns:
//  String - Presentation Of An Object In The Main Language
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Biên bản nghiệm thu công việc';
		|ru = 'Акт выполненных работ';
		|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
		|it = 'Verbale di consegna dei lavori effettuati';
		|pl = 'Protokół wykonanych prac';
		|tr = 'Müşteri faturası - Hizmetler'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction
#EndRegion

#Region Private

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT TOP 1
	|	DataOfServiceDocument.SalesOrder.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|INTO DataOfServiceDocument
	|FROM
	|	Document.CustomerInvoiceServices.Services AS DataOfServiceDocument
	|WHERE
	|	DataOfServiceDocument.Ref = &Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Date AS Period,
	|	DocumentData.SalesOrder AS SalesOrder,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Department AS Department,
	|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.InvoiceByOrders AS InvoiceByOrders,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Manager AS Manager,
	|	
	|	DocumentData.Contract.AllowableAmountPayable AS AllowableAmountPayable,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.DocumentAmount                 AS DocumentAmount,
	|	DocumentData.Number                          AS Number,
	|	DocumentData.Comment                    AS Comment,
	|	DocumentData.Author                          AS Author,
	|	DocumentData.DeletionMark                AS DeletionMark,
	|	DocumentData.Posted                       AS Posted,
	|	ISNULL(DataOfServiceDocument.ThisIsOrderAsInvoice, UNDEFINED) AS ThisIsOrderAsInvoice,
	|	DocumentData.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
	|		LEFT JOIN DataOfServiceDocument
	|		ON TRUE
	|WHERE
	|	DocumentData.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                                   Attributes.Period);
	Query.SetParameter("Currency",                                   Attributes.Currency);
	Query.SetParameter("Organization",                              Attributes.Organization);
	Query.SetParameter("LocalAccountingCurrency",           Attributes.LocalAccountingCurrency);
	Query.SetParameter("Partner",                                  Attributes.Partner);
	Query.SetParameter("Counterparty",                               Attributes.Counterparty);
	Query.SetParameter("SalesOrder",                             Attributes.SalesOrder);
	Query.SetParameter("Contract",                                  Attributes.Contract);
	Query.SetParameter("FinancialAccountingGroup",                   Attributes.FinancialAccountingGroup);
	Query.SetParameter("PriceIncludesVAT",                          ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("InvoiceByOrders",                             Attributes.InvoiceByOrders);
	Query.SetParameter("Department",                            Attributes.Department);
	Query.SetParameter("ARAPCurrency",                     Attributes.ARAPCurrency);
	Query.SetParameter("Terms",                               Attributes.Terms);
	Query.SetParameter("PaymentMethod",                              Attributes.PaymentMethod);
	Query.SetParameter("AllowableAmountPayable",             Attributes.AllowableAmountPayable);
	Query.SetParameter("VATTaxation",                       Attributes.VATTaxation);
	Query.SetParameter("Manager",                                 Attributes.Manager);
	Query.SetParameter("FinancialAccountingGroup",                   Attributes.FinancialAccountingGroup);
	Query.SetParameter("LineOfBusiness",                  Attributes.LineOfBusiness);
	Query.SetParameter("ListOfTypesWithUnitAnalytics",      SalesServer.TypesOfNomenclatureWithUnitAnalytics());
	Query.SetParameter("LoyaltyProgram",              Attributes.LoyaltyProgram);
	Query.SetParameter("CurrentDate",                              CurrentUniversalDate());
	
	Query.SetParameter("DocumentAmount",                Attributes.DocumentAmount);
	Query.SetParameter("Number",                         Attributes.Number);
	Query.SetParameter("Comment",                   Attributes.Comment);
	Query.SetParameter("DeletionMark",               Attributes.DeletionMark);
	Query.SetParameter("Posted",                      Attributes.Posted);
	Query.SetParameter("Author",                         Attributes.Author);
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 

	If Attributes.ThisIsOrderAsInvoice = Undefined Then
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
			GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	Else
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", Not Attributes.ThisIsOrderAsInvoice);
	EndIf;

	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Query.Parameters.Organization, Query.Parameters.Period);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.CustomerInvoiceServices"));
	ValuesOfHoldingParameters.Insert("BusinessOperation",  Enums.BusinessTransactions.SaleToCustomer);
	ValuesOfHoldingParameters.Insert("BusinessTransactionSetting",  Catalogs.BusinessTransactionsSettings.SaleToCustomer);
	
	ValuesOfHoldingParameters.Insert("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	ValuesOfHoldingParameters.Insert("UseAgentServiceSale",        GetFunctionalOption("UseAgentServiceSale"));
	ValuesOfHoldingParameters.Insert("UseAdvancedFeaturesOfSalesOrder",
		GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));

	If Attributes <> Undefined Then
		If ValueIsFilled(Attributes.Contract) Then
			StringPattern = "vi = 'Theo hợp đồng ""%1""';
							|ru = 'По договору ""%1""';
							|en = 'Under the ""%1"" contract';
							|it = 'In base al contratto ""%1""';
							|pl = 'Wg kontraktu ""%1""';
							|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
			ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
		EndIf;
		ValuesOfHoldingParameters.Insert("ContractInformation",          ContractInformation);
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	RequestTextForTheseDocuments = "
	|SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Currency AS DocumentCurrency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Date AS VATBasePeriod,
	|	DocumentData.Date AS DateOfCourse,
	|	
	|	TableServices.LineNumber AS LineNumber,
	|	TableServices.RowID AS RowID,
	|	
	|	TableServices.AmountIncludingVAT - TableServices.VATAmount AS AmountExcludingVAT,
	|	TableServices.VATRate AS VATRate,
	|	TableServices.VATAmount AS VATAmount,
	|	TableServices.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	TableServices.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.CustomerInvoiceServices.Services AS TableServices
	|		INNER JOIN Document.CustomerInvoiceServices AS DocumentData
	|		ON TableServices.Ref = DocumentData.Ref
	|		
	|		LEFT JOIN Document.CustomerInvoiceServices.InventoryKinds AS TableTypesOfStocks_
	|		ON TableServices.Ref = TableTypesOfStocks_.Ref
	|			AND TableServices.ItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|WHERE
	|	TableServices.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.Ref IS NULL
	|	
	|UNION ALL
	|	
	|SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Currency AS DocumentCurrency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Date AS VATBasePeriod,
	|	DocumentData.Date AS DateOfCourse,
	|	
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVAT,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.CustomerInvoiceServices.InventoryKinds AS TableTypesOfStocks_
	|		INNER JOIN Document.CustomerInvoiceServices AS DocumentData
	|			ON TableTypesOfStocks_.Ref = DocumentData.Ref
	|WHERE
	|	TableTypesOfStocks_.Ref IN(&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, RequestTextForTheseDocuments);
	
EndProcedure

Procedure InitializePartnerAccountingAnalytics(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	Query.SetParameter("AccountingDimensionByPartners",
		InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Query.Parameters));
	
EndProcedure

Procedure InitializeProductAnalysisKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;

	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series AS Series,
	|	Table.Purpose AS Purpose,
	|	Table.ProductCostElement AS ProductCostElement,
	|	Table.Warehouse AS Warehouse
	|FROM
	|	(
	|		SELECT
	|			TableServices.Products AS Products,
	|			TableServices.Characteristic AS Characteristic,
	|			VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|			VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|			VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|			CASE
	|				WHEN TableServices.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|					THEN VALUE(Catalog.Warehouses.EmptyRef)
	|				ELSE TableServices.Department
	|			END AS Warehouse
	|		FROM
	|			Document.CustomerInvoiceServices.Services AS TableServices
	|			LEFT JOIN Document.SalesOrder AS SalesOrders
	|			ON SalesOrders.Ref = TableServices.SalesOrder
	|		WHERE
	|			TableServices.Ref = &Ref
	|
	|		UNION ALL
	|
	|		SELECT
	|			TableServices.Products AS Products,
	|			TableServices.Characteristic AS Characteristic,
	|			VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|			TableServices.Purpose AS Purpose,
	|			VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|			TableServices.Department AS Warehouse
	|		FROM
	|			Document.CustomerInvoiceServices.Services AS TableServices
	|		WHERE
	|			TableServices.Ref = &Ref
	|			AND TableServices.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|		UNION ALL
	|
	|		SELECT
	|			Services.Products AS Products,
	|			Services.Characteristic AS Characteristic,
	|			VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|			VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|			VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|			ISNULL(Services.Characteristic.Principal, CatProducts.Principal) AS Warehouse
	|		FROM
	|			Document.CustomerInvoiceServices.Services AS Services
	|
	|			INNER JOIN Catalog.Products AS CatProducts
	|			ON CatProducts.Ref = Services.Products
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Services.Products = Dimension.Products
	|				AND Services.Characteristic = Dimension.Characteristic
	|				AND VALUE(Catalog.ItemsBatches.EmptyRef) = Dimension.Series
	|				AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|				AND ISNULL(Services.Characteristic.Principal, CatProducts.Principal) = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			Services.Ref = &Ref
	|			AND ISNULL(Services.Characteristic.Principal, CatProducts.Principal) <> UNDEFINED
	|			AND ISNULL(Services.Characteristic.Principal, CatProducts.Principal) <> &Organization
	|			AND Dimension.DimensionKey IS NULL
	|			AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	) AS Table
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Dimension.Products = Table.Products
	|		AND Dimension.Characteristic = Table.Characteristic
	|		AND Dimension.Series = Table.Series
	|		AND Dimension.Purpose = Table.Purpose
	|		AND Dimension.ProductCostElement = Table.ProductCostElement
	|		AND Dimension.StorageLocation = Table.Warehouse
	|WHERE
	|	Dimension.Products IS NULL
	|");
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
	//Sets
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	Keys.ProductsInSet AS ProductsInSet,
	|	Keys.ItemVariantOfSet AS ItemVariantOfSet
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|		INNER JOIN InformationRegister.SetAccountingDimension AS Keys
	|		ON Goods.SetAccountingDimension = Keys.DimensionKey
	|		
	|		LEFT JOIN InformationRegister.SetAccountingDimension AS Dimension
	|		ON Keys.ProductsInSet = Dimension.ProductsInSet
	|		AND Keys.ItemVariantOfSet = Dimension.ItemVariantOfSet
	|WHERE
	|	Dimension.ProductsInSet IS NULL
	|");
	
	QueryAnalyst.TempTablesManager = Query.TempTablesManager;
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.SetAccountingDimension.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
EndProcedure

Procedure InitializeExchangeRates(Query) Export
	
	If Query.Parameters.Property("ConversionRateToManCurrency") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
		Query.Parameters.ARAPCurrency, Query.Parameters.Period, Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure SetRequestParameterVATTaxTypesTaxable(Query) Export
	
	If Query.Parameters.Property("TypesOfVATTaxable") Then
		Return;
	EndIf;

	Query.SetParameter("TypesOfVATTaxable", VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement());
	
EndProcedure

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	TableServices.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	TableServices.SalesOrder AS ReferenceOrder,
	|	TableServices.Products AS Products,
	|	TableServices.Characteristic AS Characteristic,
	|	TableServices.RowCode AS RowCode,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	TableServices.Count AS Count,
	|	TableServices.AmountARAP AS Sum
	|FROM
	|	Document.CustomerInvoiceServices.Services AS TableServices
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|WHERE
	|	TableServices.Ref = &Ref
	|	AND &InvoiceByOrders
	|	AND &UseAdvancedFeaturesOfSalesOrder
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSuitableAgreements(QueryTexts)
	
	RegisterName = "TTSuitableAgreements";
	
	QueryText = "SELECT DISTINCT
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ISNULL(TermsOfPurchases.Ref, AgreementWithProviderWithoutServices.Ref) AS Ref,
	|	ISNULL(TermsOfPurchases.Ref.Status, AgreementWithProviderWithoutServices.Status) AS Status,
	|	ISNULL(TermsOfPurchases.Ref.ValidityEndDate,
	|		AgreementWithProviderWithoutServices.ValidityEndDate) AS ValidityEndDate
	|INTO TTSuitableAgreements_Services
	|FROM
	|	Document.CustomerInvoiceServices.Services AS ToRegister
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS TermsOfPurchases
	|		ON TermsOfPurchases.Ref.Partner = ISNULL(ToRegister.Characteristic.Principal,
	|			ToRegister.Products.Principal)
	|		AND TermsOfPurchases.Ref.Organization = &Organization
	|		AND TermsOfPurchases.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND TermsOfPurchases.Ref.Status IN (VALUE(Enum.StatusesOfTermsOfPurchase.Valid),
	|				VALUE(Enum.StatusesOfTermsOfPurchase.Closed))
	|		AND &Period >= TermsOfPurchases.Ref.ValidityStartDate
	|		AND (&Period <= TermsOfPurchases.Ref.ValidityEndDate
	|			OR TermsOfPurchases.Ref.ValidityEndDate = DATETIME(1, 1, 1))
	|		AND ToRegister.Products = TermsOfPurchases.Products
	|		AND ToRegister.Characteristic = TermsOfPurchases.Characteristic
	|		AND TermsOfPurchases.Ref.UseSpecifiedAgentServices
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS AgreementWithProviderWithoutServices
	|		ON AgreementWithProviderWithoutServices.Partner = ISNULL(ToRegister.Characteristic.Principal,
	|			ToRegister.Products.Principal)
	|		AND AgreementWithProviderWithoutServices.Organization = &Organization
	|		AND AgreementWithProviderWithoutServices.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND AgreementWithProviderWithoutServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|		AND &Period >= AgreementWithProviderWithoutServices.ValidityStartDate
	|		AND (&Period <= AgreementWithProviderWithoutServices.ValidityEndDate
	|			OR AgreementWithProviderWithoutServices.ValidityEndDate = DATETIME(1, 1, 1))
	|		AND NOT AgreementWithProviderWithoutServices.UseSpecifiedAgentServices
	|
	|WHERE
	|	ToRegister.Ref = &Ref
	|	AND ToRegister.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> &Organization
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> UNDEFINED
	|	AND &UseAgentServiceSale
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectedAgreements.Products AS Products,
	|	SelectedAgreements.Characteristic AS Characteristic,
	|	SelectedAgreements.Ref AS Ref,
	|	TermsOfPurchases.Status AS Status,
	|	TermsOfPurchases.Currency AS Currency
	|	INTO TTSuitableAgreements
	|FROM
	|	(SELECT
	|		DataByServices.Products AS Products,
	|		DataByServices.Characteristic AS Characteristic,
	|		DataByServices.Ref AS Ref
	|	FROM
	|		TTSuitableAgreements_Services AS DataByServices
	|	WHERE
	|		DataByServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataByServices.Products,
	|		DataByServices.Characteristic,
	|		MAX(DataByServices.Ref)
	|	FROM
	|		TTSuitableAgreements_Services AS DataByServices
	|	WHERE
	|		DataByServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|		AND (DataByServices.Products, DataByServices.Characteristic, DataByServices.ValidityEndDate) IN
	|				(SELECT
	|					Products,
	|					Characteristic,
	|					MAX(ValidityEndDate)
	|				FROM
	|					TTSuitableAgreements_Services
	|				WHERE
	|					DataByServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|				GROUP BY
	|					Products,
	|					Characteristic)
	|
	|	GROUP BY
	|		DataByServices.Products,
	|		DataByServices.Characteristic) AS SelectedAgreements
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
	|		ON SelectedAgreements.Ref = TermsOfPurchases.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAgencyServices(Query, QueryTexts)
	
	RegisterName = "TTAgencyServices";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSuitableAgreements", QueryTexts) Then
		QueryTextTTSuitableAgreements(QueryTexts);
	EndIf;
	
	QueryText = "SELECT DISTINCT
	|	CASE
	|		WHEN NOT ServiceAgreementInForce.Ref IS NULL
	|			THEN ServiceAgreementInForce.Ref
	|		ELSE ISNULL(ServiceAgreementClosed.Ref, UNDEFINED)
	|	END AS Terms,
	|	CASE
	|		WHEN NOT ServiceAgreementInForce.Ref IS NULL
	|			THEN ServiceAgreementInForce.Currency
	|		ELSE ISNULL(ServiceAgreementClosed.Currency, &Currency)
	|	END AS Currency,
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) AS Principal
	|INTO TTAgencyServices
	|FROM
	|	Document.CustomerInvoiceServices.Services AS ToRegister
	|
	|	LEFT JOIN TTSuitableAgreements AS ServiceAgreementInForce
	|		ON ToRegister.Products = ServiceAgreementInForce.Products
	|		AND ToRegister.Characteristic = ServiceAgreementInForce.Characteristic
	|		AND ServiceAgreementInForce.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|
	|	LEFT JOIN TTSuitableAgreements AS ServiceAgreementClosed
	|		ON ToRegister.Products = ServiceAgreementClosed.Products
	|		AND ToRegister.Characteristic = ServiceAgreementClosed.Characteristic
	|		AND ServiceAgreementClosed.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|		AND ServiceAgreementInForce.Ref IS NULL
	|
	|WHERE
	|	ToRegister.Ref = &Ref
	|	AND ToRegister.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> &Organization
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> UNDEFINED
	|	AND &UseAgentServiceSale";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAnalytics_(Query, QueryTexts)
	
	RegisterName = "TTAnalytics_";
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText = "
	|SELECT DISTINCT
	|	TableServices.SalesOrder AS SalesOrder,
	|	TableServices.Products AS Products,
	|	TableServices.Characteristic AS Characteristic,
	|	CASE
	|		WHEN TableServices.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE TableServices.Department
	|	END AS Warehouse,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	TableServices.Purpose AS Purpose
	|INTO TTAnalytics_
	|FROM
	|	Document.CustomerInvoiceServices.Services AS TableServices
	|
	|WHERE
	|	TableServices.Ref = &Ref
	|
	|INDEX BY
	|	SalesOrder,
	|	Products,
	|	Characteristic,
	|	Purpose";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextTTOperationServices(Query, QueryTexts)
	
	RegisterName = "TTOperationServices";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	SetRequestParameterVATTaxTypesTaxable(Query);
	InitializeProductAnalysisKeys(Query);
	InitializeExchangeRates(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAnalytics_", QueryTexts) Then
		QueryTextTTAnalytics_(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableServices.LineNumber AS LineNumber,
	|	DimensionKeys.DimensionKey AS ItemsLocationAttributes,
	|	AnalyticsKeysWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	DimensionKeys.StorageLocation AS Warehouse,
	|	TableServices.Purpose AS Purpose,
	|	CatProducts.ItemsType AS ItemsType,
	|	CatProducts.TracedGoods AS TracedGoods,
	|	TableServices.Products AS Products,
	|	TableServices.Characteristic AS Characteristic,
	|	TableServices.SalesOrder AS SalesOrder,
	|	TableServices.ARAPObject AS ARAPObject,
	|	CASE 
	|		WHEN TableServices.Products.ItemsType IN (&ListOfTypesWithUnitAnalytics) 
	|			THEN TableServices.Department
	|		ELSE
	|			&Department
	|	END AS Department,
	|
	|	TableServices.Count AS Count,
	|	TableServices.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableServices.VATAmount AS VATAmount,
	|	TableServices.ManualDiscount AS ManualDiscount,
	|	TableServices.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	TableServices.AmountARAP AS AmountARAP,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|
	|	AgentServices.Terms AS Terms,
	|	AgentServices.Currency AS Currency,
	|	ISNULL(PrincipalKeys.DimensionKey, UNDEFINED) AS PrincipalProductAnalysis,
	|	ISNULL(AgentServices.Principal, UNDEFINED) AS Principal,
	|	(CASE 
	|		WHEN TableServices.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE TableServices.VATRate
	|			WHEN &ExportVATRate THEN 
	|				VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		ELSE &VATTaxation END) AS VATTaxation,
	|	
	|	TableServices.RowID AS RowID,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND CatProducts.TracedGoods
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TraceableWork,
	|	TableServices.VATRate AS VATRate
	|	
	|INTO TTOperationServices
	|FROM
	|	Document.CustomerInvoiceServices.Services AS TableServices
	|
	|	LEFT JOIN TTAnalytics_ AS TTAnalytics_
	|	ON TTAnalytics_.SalesOrder = TableServices.SalesOrder
	|		AND TTAnalytics_.Products = TableServices.Products
	|		AND TTAnalytics_.Characteristic = TableServices.Characteristic
	|		AND TTAnalytics_.Purpose = TableServices.Purpose
	|		AND CASE
	|			WHEN TableServices.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|				THEN TRUE
	|			ELSE TTAnalytics_.Warehouse = TableServices.Department
	|		END
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionKeys
	|	ON TTAnalytics_.Products = DimensionKeys.Products
	|		AND TTAnalytics_.Characteristic = DimensionKeys.Characteristic
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = DimensionKeys.Series
	|		AND TTAnalytics_.Purpose = DimensionKeys.Purpose
	|		AND TTAnalytics_.Warehouse = DimensionKeys.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionKeys.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsKeysWithoutAssignment
	|	ON TTAnalytics_.Products = AnalyticsKeysWithoutAssignment.Products
	|		AND TTAnalytics_.Characteristic = AnalyticsKeysWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = AnalyticsKeysWithoutAssignment.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsKeysWithoutAssignment.Purpose
	|		AND TTAnalytics_.Warehouse = AnalyticsKeysWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsKeysWithoutAssignment.ProductCostElement
	|
	|	INNER JOIN Catalog.Products AS CatProducts
	|	ON CatProducts.Ref = TableServices.Products
	|
	|	LEFT JOIN TTAgencyServices AS AgentServices
	|	ON TableServices.Products = AgentServices.Products
	|		AND TableServices.Characteristic = AgentServices.Characteristic
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS PrincipalKeys
	|	ON PrincipalKeys.Products = AgentServices.Products
	|		AND PrincipalKeys.Characteristic = AgentServices.Characteristic
	|		AND PrincipalKeys.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND PrincipalKeys.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		AND PrincipalKeys.StorageLocation = AgentServices.Principal
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = PrincipalKeys.ProductCostElement
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON TableServices.Ref = Amounts.Ref
	|		AND TableServices.RowID = Amounts.RowID
	|WHERE
	|	TableServices.Ref = &Ref
	|	AND CatProducts.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|	
	|	AND TableServices.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS InventoryKinds)
	|	
	|UNION ALL
	|	
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsKeysWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	
	|	Dimension.StorageLocation AS Warehouse,
	|	Dimension.Purpose AS Purpose,
	|	TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem AS ItemsType,
	|	TableTypesOfStocks_.InventoryLocationAttributeOfItemOfItemThatIsBeingTracked AS TracedGoods,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	
	|	TableTypesOfStocks_.SalesOrder AS SalesOrder,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem IN (&ListOfTypesWithUnitAnalytics)
	|			THEN Dimension.StorageLocation
	|		ELSE &Department
	|	END AS Department,
	|	
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|	TableTypesOfStocks_.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|	
	|	UNDEFINED AS Terms,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS PrincipalProductAnalysis,
	|	UNDEFINED AS Principal,
	|	
	|	(CASE
	|		WHEN TableTypesOfStocks_.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE TableTypesOfStocks_.VATRate
	|			WHEN &ExportVATRate THEN 
	|				VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		ELSE &VATTaxation END) AS VATTaxation,
	|	
	|	TableTypesOfStocks_.RowID AS RowID,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND CatProducts.TracedGoods
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TraceableWork,
	|	TableTypesOfStocks_.VATRate AS VATRate
	|	
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS TableTypesOfStocks_
	|	
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsKeysWithoutAssignment
	|	ON Dimension.Products = AnalyticsKeysWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsKeysWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = AnalyticsKeysWithoutAssignment.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsKeysWithoutAssignment.Purpose
	|		AND Dimension.StorageLocation = AnalyticsKeysWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsKeysWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN Catalog.Products AS CatProducts
	|	ON CatProducts.Ref = Dimension.Products
	|	
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON TableTypesOfStocks_.Ref = Amounts.Ref
	|		AND TableTypesOfStocks_.RowID = Amounts.RowID
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextExchangeRates(Query, QueryTexts)
	
	RegisterName = "ExchangeRates";
	
	QueryText = "
	|SELECT
	|	ExchangeRates.Currency AS Currency,
	|
	|	(DocumentExchangeRate.CourseNumerator * ExchangeRates.CourseDenominator)
	|   / (DocumentExchangeRate.CourseDenominator * ExchangeRates.CourseNumerator) AS ConversionFactor_
	|
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period,
	|		Currency IN (
	|				SELECT DISTINCT
	|					Services.Currency AS Currency
	|				FROM
	|					TTAgencyServices AS Services
	|		) 
	|		AND BaseCurrency = &LocalAccountingCurrency) AS ExchangeRates
	|
	|	INNER JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(
	|					&Period,
	|					Currency = &Currency AND BaseCurrency = &LocalAccountingCurrency) AS DocumentExchangeRate
	|	ON
	|		TRUE
	|
	|WHERE
	|	DocumentExchangeRate.CourseDenominator <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializePartnerAccountingAnalytics(Query);
	InitializeExchangeRates(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableServices.LineNumber           AS LineNumber,
	|	&Period                             AS Period,
	|	&Department                      AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments THEN
	|		TableServices.ItemsLocationAttributes
	|	ELSE
	|		TableServices.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	&AccountingDimensionByPartners          AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN &InvoiceByOrders
	|			THEN TableServices.SalesOrder
	|		ELSE &Ref
	|	END AS SalesOrder,
	|	CASE
	|		WHEN TableServices.Principal <> UNDEFINED
	|		THEN VALUE(Enum.InventoryTypes.AgentService)
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END AS InventoryType,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN TableServices.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE UNDEFINED END) 		AS AccountingSection,
	|	TableServices.VATTaxation	AS VATActivityType,
	|	&Manager                           AS Manager,
	|	CASE
	|		WHEN TableServices.Principal <> UNDEFINED
	|		THEN TableServices.AmountIncludingVATMan
	|		ELSE 0
	|	END                               AS Cost,
	|	CASE
	|		WHEN TableServices.Principal <> UNDEFINED
	|		THEN TableServices.AmountExcludingVATMan
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN TableServices.Principal <> UNDEFINED
	|		THEN TableServices.AmountExcludingVATCompl
	|		ELSE 0
	|	END                               AS LocalCost,
	|	CASE
	|		WHEN TableServices.Principal <> UNDEFINED
	|		 AND &CompanyManagementAccounting
	|		THEN TableServices.AmountExcludingVATMan
	|		ELSE 0
	|	END AS CostMan,
	|	TableServices.Count            AS Count,
	|	TableServices.AmountIncludingVATMan          AS RevenueAmount,
	|	TableServices.AmountExcludingVATMan        AS RevenueAmountExcludingVAT,
	|	TableServices.AmountExcludingVATCompl       AS RevenueAmountExclVATLocal,
	|	TableServices.AmountExcludingVATCompl + TableServices.VATAmountCompl AS RevenueAmountIncludingVATLocal,
	|
	|	CAST(TableServices.ManualDiscount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS ManualDiscount,
	|
	|	CAST(TableServices.DiscountMarkupAmount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS DiscountMarkupAmount,
	|
	|	TableServices.Warehouse AS Warehouse,
	|	&Contract AS Contract,
	|	&Terms AS Terms,
	|
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	(CASE
	|		WHEN TableServices.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN &LineOfBusiness
	|		ELSE TableServices.Purpose.LineOfBusiness END) AS ProductLineOfBusiness,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableServices.AmountARAP AS AmountInARAPCurrency,
	|
	|	TableServices.AmountARAP - 
	|	CASE WHEN TableServices.AmountIncludingVAT <> 0 THEN
	|		CAST(TableServices.AmountARAP * TableServices.VATAmount / TableServices.AmountIncludingVAT AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	TableServices.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableServices.AmountIncludingVAT - TableServices.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	TableServices.VATTaxation AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	TableServices.Products AS SourceOfProductFinancialAccountingGroup,
	|	TableServices.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableServices.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TableServices.VATRate AS VATRate
	|	
	|FROM
	|	TTOperationServices AS TableServices
	|
	|WHERE
	|	NOT TableServices.TracedGoods
	|
	|UNION ALL
	|
	// Traceable works.
	|SELECT
	|	TableTypesOfStocks_.LineNumber			AS LineNumber,
	|	&Period									AS Period,
	|	&Department							AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments THEN
	|		TableTypesOfStocks_.ItemsLocationAttributes
	|	ELSE
	|		TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END									AS ItemsLocationAttributes,
	|	&AccountingDimensionByPartners				AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN &InvoiceByOrders
	|			THEN TableTypesOfStocks_.SalesOrder
	|		ELSE &Ref
	|	END									AS SalesOrder,
	|	CASE
	|		WHEN TableTypesOfStocks_.Principal <> UNDEFINED
	|		THEN VALUE(Enum.InventoryTypes.AgentService)
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END									AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
	|	TableTypesOfStocks_.VATTaxation	AS VATActivityType,
	|	&Manager								AS Manager,
	|	CASE
	|		WHEN TableTypesOfStocks_.Principal <> UNDEFINED
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END									AS Cost,
	|	CASE
	|		WHEN TableTypesOfStocks_.Principal <> UNDEFINED
	|		THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END 									AS CostExcludingVAT,
	|	CASE
	|		WHEN TableTypesOfStocks_.Principal <> UNDEFINED
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl
	|		ELSE 0
	|	END									AS LocalCost,
	|	CASE
	|		WHEN TableTypesOfStocks_.Principal <> UNDEFINED
	|		 AND &CompanyManagementAccounting
	|		THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END									AS CostMan,
	|	TableTypesOfStocks_.Count			AS Count,
	|	TableTypesOfStocks_.AmountIncludingVATMan			AS RevenueAmount,
	|	TableTypesOfStocks_.AmountExcludingVATMan		AS RevenueAmountExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl		AS RevenueAmountExclVATLocal,
	|	TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATLocal AS RevenueAmountIncludingVATLocal,
	|
	|	CAST(TableTypesOfStocks_.ManualDiscount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS ManualDiscount,
	|
	|	CAST(TableTypesOfStocks_.DiscountMarkupAmount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS DiscountMarkupAmount,
	|
	|	TableTypesOfStocks_.Warehouse				AS Warehouse,
	|	&Contract								AS Contract,
	|	&Terms								AS Terms,
	|
	|	&LineOfBusiness				AS CounterpartyLineOfBusiness,
	|	TableTypesOfStocks_.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|
	|	&ARAPCurrency					AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP	AS AmountInARAPCurrency,
	|
	|	TableTypesOfStocks_.AmountARAP - 
	|	CASE WHEN TableTypesOfStocks_.AmountIncludingVAT <> 0 THEN
	|		CAST(TableTypesOfStocks_.AmountARAP * TableTypesOfStocks_.VATAmount / TableTypesOfStocks_.AmountIncludingVAT AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END									AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency									AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT			AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	TableTypesOfStocks_.VATTaxation	AS VATTaxation,
	|	&BusinessOperation					AS BusinessOperation,
	|
	|	TableTypesOfStocks_.Products			AS SourceOfProductFinancialAccountingGroup,
	|	TableTypesOfStocks_.ARAPObject		AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableTypesOfStocks_.RowID	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate			AS VATRate
	|	
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.TraceableWork
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableServices.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Organization AS Organization,
	|	TableServices.Products,
	|	TableServices.Characteristic,
	|	TableServices.Department AS Department,
	|	TableServices.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableServices.Count AS Count,
	|	TableServices.VATTaxation AS VATTaxation,
	|	TableServices.Purpose AS Purpose
	|FROM
	|	TTOperationServices AS TableServices
	|WHERE
	|	TableServices.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableServices.TracedGoods
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfStocks";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	SetRequestParameterVATTaxTypesTaxable(Query);
	InitializeProductAnalysisKeys(Query);
	InitializeExchangeRates(Query);
	
	QueryText = 
	"SELECT
	|	InventoryKinds.LineNumber                  AS LineNumber,
	|	InventoryKinds.Ref                       AS Ref,
	|	Dimension.StorageLocation                  AS Warehouse,
	|	Dimension.StorageLocation.ShopFloorStockroom  AS ShopFloorStockroom,
	|	InventoryKinds.SalesOrder                 AS SalesOrder,
	|	&Organization                             AS Organization,
	|
	|	Dimension.Products                   AS Products,
	|	Dimension.Products.ItemsType   AS ItemsType,
	|	Dimension.Products.TracedGoods AS TracedGoods,
	|	Dimension.Characteristic                 AS Characteristic,
	|	Dimension.Purpose                     AS Purpose,
	|	Dimension.Department                  AS Department,
	|
	|	InventoryKinds.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttributeSaleOfAnotherCompanySInventory AS InventoryOwnerAttributeSaleOfAnotherCompanySInventory,
	|	InventoryKinds.InventoryOwnerAttributeInventoryOwnerAttributeOfOwnerCompany AS InventoryOwnerAttributeInventoryOwnerAttributeOfOwnerCompany,
	|	InventoryKinds.InventoryOwnerAttributeInventoryOwnerAttribute AS InventoryOwnerAttributeInventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttributeAgreement         AS InventoryOwnerAttributeAgreement,
	|	InventoryKinds.OwnerSInventoryOwnersAttributeInventoryOwnersAttributesCurrency AS OwnerSInventoryOwnersAttributeInventoryOwnersAttributesCurrency,
	|	InventoryKinds.InventoryOwnerAttributeInventoryOwnerAttributeTypeOfInventory AS InventoryOwnerAttributeInventoryOwnerAttributeTypeOfInventory,
	|
	|	InventoryKinds.ARAPObject               AS ARAPObject,
	|	InventoryKinds.ARAPObjectOfCompany    AS ARAPObjectOfCompany,
	|	InventoryKinds.ARAPObjectContract        AS ARAPObjectContract,
	|	InventoryKinds.ARAPObjectLineOfBusiness AS ARAPObjectLineOfBusiness,
	|	InventoryKinds.ARAPObjectIsUniqueIdentifier AS ARAPObjectIsUniqueIdentifier,
	|
	|	InventoryKinds.Count                   AS Count,
	|	InventoryKinds.QuantityByGBRN             AS QuantityByGBRN,
	|	InventoryKinds.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	InventoryKinds.VATAmount                     AS VATAmount,
	|	InventoryKinds.VATRate                    AS VATRate,
	|	InventoryKinds.CCDNumber                     AS CCDNumber,
	|
	|	InventoryKinds.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey     AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.SetAccountingDimension        AS SetAccountingDimension,
	|	InventoryKinds.RowID          AS RowID,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	CatAssignments.LineOfBusiness    AS LineOfBusiness,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)          AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)        AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)         AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)       AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)          AS VATLocal,
	|	InventoryKinds.ManualDiscount            AS ManualDiscount,
	|	InventoryKinds.DiscountMarkupAmount    AS DiscountMarkupAmount,
	|	InventoryKinds.AmountARAP          AS AmountARAP,
	|	CASE
	|		WHEN InventoryKinds.AmountIncludingVAT <> 0
	|			THEN CAST(InventoryKinds.AmountARAP * InventoryKinds.VATAmount / InventoryKinds.AmountIncludingVAT AS NUMBER(31,2))
	|		ELSE 0
	|	END                                    AS AmountOfVATSettlements,
	|	CAST(InventoryKinds.ManualDiscount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountOfManualManDiscount,
	|	CAST(InventoryKinds.DiscountMarkupAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountOfAutomaticManDiscount,
	|
	|	(CASE
	|		WHEN InventoryKinds.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END)                                   AS VATActivityType,
	|	ISNULL(AnalysisOfCalculations.DimensionKey, &AccountingDimensionByPartners) AS AccountingDimensionByPartners,
	|	(CASE 
	|		WHEN InventoryKinds.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE InventoryKinds.VATRate
	|			WHEN &ExportVATRate THEN 
	|				VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		ELSE &VATTaxation END) AS VATTaxation,
	|	ISNULL(AgentServices.Principal, UNDEFINED) AS Principal,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND CatProducts.TracedGoods
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TraceableWork
	|
	|INTO TTTableTypesOfStocks
	|
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS InventoryKinds
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON 
	|		InventoryKinds.Ref = Amounts.Ref
	|		AND InventoryKinds.RowID = Amounts.RowID
	|
	|	LEFT JOIN 
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		InventoryKinds.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON 
	|		Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|	ON AnalysisOfCalculations.Partner = &Partner
	|		AND AnalysisOfCalculations.Organization = &Organization
	|		AND AnalysisOfCalculations.Counterparty = &Counterparty
	|		AND AnalysisOfCalculations.Contract = InventoryKinds.ARAPObjectContract
	|		AND AnalysisOfCalculations.LineOfBusiness = InventoryKinds.ARAPObjectLineOfBusiness
	|
	|	LEFT JOIN Catalog.Products AS CatProducts
	|	ON Dimension.Products = CatProducts.Ref
	|
	|	LEFT JOIN Catalog.Assignments AS CatAssignments
	|	ON Dimension.Purpose = CatAssignments.Ref
	|
	|	LEFT JOIN TTAgencyServices AS AgentServices
	|	ON Dimension.Products = AgentServices.Products
	|		AND Dimension.Characteristic = AgentServices.Characteristic
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProductsOfOrganizations(Query, QueryTexts) Export
	
	TableName = "TTProductsOfOrganizations";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS ShipmentCompany,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.PartnerProducts AS PartnerProducts,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS CostOfProductBatchID,
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorInventoryOwnerAttribute
	|INTO TTProductsOfOrganizations
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductsOfOrganizations", QueryTexts) Then
		QueryTextTTProductsOfOrganizations(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	TTProductsOfOrganizations.RecordType AS RecordType,
	|	TTProductsOfOrganizations.Period AS Period,
	|	TTProductsOfOrganizations.ShipmentCompany AS ShipmentCompany,
	|	TTProductsOfOrganizations.Organization AS Organization,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsOfOrganizations.Products AS Products,
	|	TTProductsOfOrganizations.Characteristic AS Characteristic,
	|	TTProductsOfOrganizations.Warehouse AS Warehouse,
	|	TTProductsOfOrganizations.CCDNumber AS CCDNumber,
	|	TTProductsOfOrganizations.PartnerProducts AS PartnerProducts,
	|	TTProductsOfOrganizations.Count AS Count,
	|	TTProductsOfOrganizations.QuantityByGBRN AS QuantityByGBRN,
	|	TTProductsOfOrganizations.BusinessOperation AS BusinessOperation,
	|	TTProductsOfOrganizations.VATTaxation AS VATTaxation,
	|	TTProductsOfOrganizations.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TTProductsOfOrganizations.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|FROM
	|	TTProductsOfOrganizations AS TTProductsOfOrganizations
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers)
	
	RegisterName = "ServicesForRegistrationOfReportsToPrincipal";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("ExchangeRates", QueryTexts) Then
		QueryTextExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	ToRegister.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Period                                     AS Period,
	|	&Organization                                AS Organization,
	|	ToRegister.PrincipalProductAnalysis AS ItemsLocationAttributes,
	|	ToRegister.Terms                      AS Terms,
	|	ToRegister.Currency                          AS Currency,
	|	ToRegister.Count                      AS Count,
	|	ToRegister.AmountIncludingVAT 
	|		* ExchangeRates.ConversionFactor_       AS RevenueAmount,
	|	ToRegister.VATAmount 
	|		* ExchangeRates.ConversionFactor_       AS VATAmount,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ToRegister.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ToRegister.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountMan,
	|	&Counterparty AS Customer,
	|	&Ref AS DocumentSalesOfGoodsAndServices,
	|	ToRegister.RowID AS RowID,
	|	ToRegister.ARAPObject.UUID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTOperationServices AS ToRegister
	|
	|	LEFT JOIN ExchangeRates AS ExchangeRates
	|	ON ToRegister.Currency = ExchangeRates.Currency
	|WHERE
	|	ToRegister.PrincipalProductAnalysis <> UNDEFINED
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	UNDEFINED                            AS StorageLocation,
	|	&Department                          AS Department,
	|	&Manager                               AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	&DocumentAmount                         AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Author                                  AS Author,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextBonusPoints(Query, QueryTexts, Registers, Document)
	
	RegisterName = "BonusPoints";
	
	If Not BonusPointsServer.ItIsRequiredToAddRegisterRegisteredRecordsBonusPoints(Document) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBonusPoints", QueryTexts) Then
		QueryTextTTBonusPoints(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	BonusPoints.Period                      AS Period,
	|	BonusPoints.ValidityStartDate          AS ValidityStartDate,
	|	BonusPoints.DateToProcess              AS DateToProcess,
	|	BonusPoints.RecordType                 AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner                     AS Partner,
	|	SUM(BonusPoints.Accrued)            AS Accrued,
	|	SUM(BonusPoints.ToWriteOff)            AS ToWriteOff
	|FROM
	|	TTBonusPoints AS BonusPoints
	|
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.Period,
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.DateToProcess,
	|	BonusPoints.RecordType
	|HAVING
	|	SUM(BonusPoints.Accrued) <> 0 OR 
	|	SUM(BonusPoints.ToWriteOff) <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBonusPoints(Query, QueryTexts)
	
	RegisterName = "TTBonusPoints";
	QueryText = 
	"SELECT
	|	TabularSection.AccrualDate                            AS Period,
	|	CASE
	|		WHEN TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|			THEN TabularSection.AccrualDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS ValidityStartDate,
	|	CASE
	|		WHEN TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS DateToProcess,
	|	VALUE(AccumulationRecordType.Receipt)                   AS RecordType,
	|	TabularSection.LoyaltyProgram               AS LoyaltyProgram,
	|	&Partner                                                 AS Partner,
	|	TabularSection.AmountOfBonusPoints                       AS Accrued,
	|	0                                                        AS ToWriteOff
	|INTO TTBonusPoints
	|FROM
	|	Document.CustomerInvoiceServices.BonusPointAccrual AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.AccrualDate <> DATETIME(1,1,1)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.DateOfDeduction                              AS Period,
	|	TabularSection.AccrualDate                            AS ValidityStartDate,
	|	&CurrentDate                                             AS DateToProcess,
	|	VALUE(AccumulationRecordType.Receipt)                   AS RecordType,
	|	TabularSection.LoyaltyProgram               AS LoyaltyProgram,
	|	&Partner                                                 AS Partner,
	|	0                                                        AS Accrued,
	|	TabularSection.AmountOfBonusPoints                       AS ToWriteOff
	|FROM
	|	Document.CustomerInvoiceServices.BonusPointAccrual AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.DateOfDeduction <> DATETIME(1,1,1)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(&Period, DAY),
	|	DATETIME(1,1,1),
	|	&CurrentDate,
	|	VALUE(AccumulationRecordType.Expense),
	|	&LoyaltyProgram,
	|	&Partner,
	|	TabularSection.AmountOfBonusPointsToDeduction,
	|	0
	|FROM
	|	Document.CustomerInvoiceServices.Services AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.AmountOfBonusPointsToDeduction <> 0
	|";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInventoryOwnerAttributesOfWorks", QueryTexts) Then
		QueryTextTTInventoryOwnerAttributesOfWorks(Query, QueryTexts);
	EndIf;
		
	ServiceText =
	"SELECT
	|	Services.Ref.Date AS Period,
	|	Services.Ref AS Ref,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	Services.Ref.Counterparty AS Counterparty,
	|	UNDEFINED AS Shipper,
	|	UNDEFINED AS GoodsRecipient,
	|	Services.Ref.Contract AS Contract,
	|	Services.Ref.Organization AS Organization,
	|	Services.Ref.Department AS Department,
	|	UNDEFINED AS ConsignedGoodsCustomer,
	|	FALSE AS SalesViaCommissionAgent,
	|	Services.Ref AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS ImplementationAdjustmentDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	Services.ARAPObject AS ARAPObject,
	|	Services.Ref.VATTaxation AS VATTaxation,
	|	Services.Products AS Products,
	|	Services.Characteristic AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	Services.PartnerProducts AS PartnerProducts,	
	|	Services.ProductsInSet AS ProductsInSet,
	|	Services.ItemVariantOfSet AS ItemVariantOfSet,
	|	Services.Content AS Content,
	|	Services.Count AS Count,
	|	Services.Products.UnitOfMeasure AS UnitOfMeasure,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	Services.VATRate AS VATRate,
	|	UNDEFINED AS FEACNCode,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	Services.LineNumber AS LineNumber,
	|	Services.RowID AS RowID,
	|	Services.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.CustomerInvoiceServices.Services AS Services
	|		LEFT JOIN TTInventoryOwnerAttributesOfWorks AS InventoryKinds
	|		ON Services.Ref = InventoryKinds.Ref
	|			AND Services.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|	
	|WHERE
	|	Services.Ref IN (&Ref)
	|	AND InventoryKinds.Ref IS NULL
	|	
	|UNION ALL
	|	
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Ref AS Ref,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	DocumentData.Counterparty AS Counterparty,
	|	UNDEFINED AS Shipper,
	|	UNDEFINED AS GoodsRecipient,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	UNDEFINED AS ConsignedGoodsCustomer,
	|	FALSE AS SalesViaCommissionAgent,
	|	DocumentData.Ref AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS ImplementationAdjustmentDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	TableTypesOfStocks_.SetAccountingDimension.ProductsInSet AS ProductsInSet,
	|	TableTypesOfStocks_.SetAccountingDimension.ItemVariantOfSet AS ItemVariantOfSet,
	|	"""" AS Content,
	|	TableTypesOfStocks_.Count AS Count,
	|	CatalogProducts.UnitOfMeasure AS UnitOfMeasure,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	UNDEFINED AS FEACNCode,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
	|		INNER JOIN Document.CustomerInvoiceServices.InventoryKinds AS TableTypesOfStocks_
	|		ON DocumentData.Ref = TableTypesOfStocks_.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Dimension.Products = CatalogProducts.Ref
	|WHERE
	|	DocumentData.Ref IN(&Ref)
	|";
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, ServiceText);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("AccountingDimensionByPartners");
	
	If Query <> Undefined Then
		InitializePartnerAccountingAnalytics(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTOperationServices");
	AdditionalTables.Add("TTTableTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTOperationServices(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTTableTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Implementation_Services
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN &InvoiceByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 									AS Count,
	|	UNDEFINED													AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableTypesOfStocks_.TraceableWork
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	#Region Implementation_TraceableWorks
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN &InvoiceByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 									AS Count,
	|	UNDEFINED													AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.TraceableWork
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

Function DescriptionOfRevenueAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region SaleOfGoodsAndServices
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN &InvoiceByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 									AS Count,
	|	TableTypesOfStocks_.RowID							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If Not UserRightsCached.ThisIsPartner()
		 And GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Report of completed works
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificateOfCompletedWorksWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Biên bản nghiệm thu công việc';
										|ru = 'Акт выполненных работ';
										|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
										|it = 'Verbale di consegna dei lavori effettuati';
										|pl = 'Protokół wykonanych prac';
										|tr = 'Müşteri faturası - Hizmetler'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản nghiệm thu công việc';
												|ru = 'Акт выполненных работ';
												|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
												|it = 'Verbale di consegna dei lavori effettuati';
												|pl = 'Protokół wykonanych prac';
												|tr = 'Gerçekleştirilen işler raporu'");
	EndIf;

	If Users.IsFullUser() Then
		TemplateName = "PF_DOC_Act" + "_" + Common.DefaultLanguageCode();
		If Metadata.Documents.CustomerInvoiceServices.Templates.Find(TemplateName) <> Undefined Then
			// Certificate of completed works (Microsoft Word)
			PrintCommand = PrintCommands.Add();
			PrintCommand.Id = "MicrosoftWordAct";
			PrintCommand.Presentation = NStr("vi = 'Biên bản nghiệm thu công việc (Microsoft Word)';
											|ru = 'Акт выполненных работ (Microsoft Word)';
											|en = 'Customer invoice — Services (Microsoft Word)'; fa = 'Customer invoice — Services (Microsoft Word)';
											|it = 'Verbale di consegna dei lavori effettuati (Microsoft Word)';
											|pl = 'Zestawienie wykonanych prac (Microsoft Word)';
											|tr = 'Gerçekleştirilen işler raporu (Microsoft Word)'");
			PrintCommand.CheckPostingBeforePrint = True;
			PrintCommand.FileSystemExtensionIsRequired = True;
		EndIf;
	EndIf;

	If Not UserRightsCached.ThisIsPartner()
		 And GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Certificate of completed work (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificateOfCompletedWorksWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Biên bản nghiệm thu công việc (không hiển thị chiết khấu)';
										|ru = 'Акт выполненных работ (не выводить скидки)';
										|en = 'Customer invoice — Services (do not display discounts)'; fa = 'Customer invoice — Services (do not display discounts)';
										|it = 'Verbale di consegna dei lavori effettuati (non visualizzare gli sconti)';
										|pl = 'Protokół odbioru wykonania prac (nie wyprowadzać rabaty)';
										|tr = 'Gerçekleştirilen işler raporu (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản nghiệm thu công việc';
												|ru = 'Акт выполненных работ';
												|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
												|it = 'Verbale di consegna dei lavori effettuati';
												|pl = 'Protokół wykonanych prac';
												|tr = 'Gerçekleştirilen işler raporu'");
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;

	If Not UserRightsCached.ThisIsPartner()
		 And GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Certificate of completed works (display discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CustomerInvoiceServices";
		PrintCommand.Presentation = NStr("vi = 'Biên bản nghiệm thu công việc (hiển thị chiết khấu)';
										|ru = 'Акт выполненных работ (выводить скидки)';
										|en = 'Customer invoice — Services (display discounts)'; fa = 'Customer invoice — Services (display discounts)';
										|it = 'Verbale di consegna dei lavori effettuati (visualizzare gli sconti)';
										|pl = 'Protokół odbioru wykonania prac (wyprowadzać rabaty)';
										|tr = 'Gerçekleştirilen işler raporu (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản nghiệm thu công việc';
												|ru = 'Акт выполненных работ';
												|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
												|it = 'Verbale di consegna dei lavori effettuati';
												|pl = 'Protokół wykonanych prac';
												|tr = 'Gerçekleştirilen işler raporu'");
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;

	If UserRightsCached.ThisIsPartner() Then
		// Report of completed works
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificateOfCompletedWorksWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Biên bản nghiệm thu công việc';
										|ru = 'Акт выполненных работ';
										|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
										|it = 'Verbale di consegna dei lavori effettuati';
										|pl = 'Protokół wykonanych prac';
										|tr = 'Müşteri faturası - Hizmetler'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản nghiệm thu công việc';
												|ru = 'Акт выполненных работ';
												|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
												|it = 'Verbale di consegna dei lavori effettuati';
												|pl = 'Protokół wykonanych prac';
												|tr = 'Gerçekleştirilen işler raporu'");
	EndIf;

	If Not UserRightsCached.ThisIsPartner()
		 And GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption") Then
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "InvoiceForPaymentWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán';
										|ru = 'Счет на оплату';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Fattura di pagamento';
										|pl = 'Rachunek do zapłaty';
										|tr = 'Ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;

	If Not UserRightsCached.ThisIsPartner()
		 And GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption") Then
		// Invoice for payment (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "InvoiceForPaymentWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán (không hiển thị chiết khấu)';
										|ru = 'Счет на оплату (не выводить скидки)';
										|en = 'Commercial invoice (do not display discounts)'; fa = 'Commercial invoice (do not display discounts)';
										|it = 'Fattura di pagamento (non visualizzare gli sconti)';
										|pl = 'Rachunek do płatności (nie wyświetlać zniżki)';
										|tr = 'Ticari fatura (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;

	If Not UserRightsCached.ThisIsPartner()
		 And GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption") Then
		// Invoice for payment (withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoice";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán (hiển thị chiết khấu)';
										|ru = 'Счет на оплату (выводить скидки)';
										|en = 'Commercial invoice (display discounts)'; fa = 'Commercial invoice (display discounts)';
										|it = 'Fattura di pagamento (visualizzare gli sconti)';
										|pl = 'Rachunek do płatności (wyświetlać zniżki)';
										|tr = 'Ticari fatura (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If Not UserRightsCached.ThisIsPartner()
		 And GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption") Then
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceWithFacsimile";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax';
										|ru = 'Счет на оплату с факсимиле';
										|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
										|it = 'Fattura di pagamento in facsimile';
										|pl = 'Rachunek do płatności z faksymile';
										|tr = 'Kaşeli ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;

	If Not UserRightsCached.ThisIsPartner()
		 And GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption") Then
		// Invoice for payment (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "InvoiceWithFacsimileWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax(không hiển thị chiết khấu)';
										|ru = 'Счет на оплату с факсимиле (не выводить скидки)';
										|en = 'Commercial invoice with facsimile (do not display discounts)'; fa = 'Commercial invoice with facsimile (do not display discounts)';
										|it = 'Fattura di pagamento in facsimile (non visualizzare gli sconti)';
										|pl = 'Rachunek do płatności z faksymile (nie wyświetlać zniżki)';
										|tr = 'Kaşeli ticari fatura (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;

	If Not UserRightsCached.ThisIsPartner()
		 And GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption") Then
		// Invoice for payment (withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceWithFacsimile";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax (hiển thị chiết khấu)';
										|ru = 'Счет на оплату с факсимиле (выводить скидки)';
										|en = 'Commercial invoice with facsimile (display discounts)'; fa = 'Commercial invoice with facsimile (display discounts)';
										|it = 'Fattura di pagamento in facsimile (visualizzare gli sconti)';
										|pl = 'Rachunek do płatności z faksymile (wyświetlać zniżki)';
										|tr = 'Kaşeli ticari fatura (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;

	If Not GetFunctionalOption("UseCustomerCommercialInvoices")
		And Constants.UseInternationalPrintingForms.Get() Then
		
		// Proforma invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceEn";
		PrintCommand.Presentation = NStr("vi = 'Proforma invoice (en)';
										|ru = 'Proforma invoice (en)';
										|en = 'Proforma invoice (en)'; fa = 'Proforma invoice (en)';
										|it = 'Proforma invoice (en)';
										|pl = 'Proforma invoice (en)';
										|tr = 'Proforma invoice (en)'");
		PrintCommand.CheckPostingBeforePrint = True;
		
	EndIf;
	CustomerInvoiceServicesLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	SynonymForTemplateOfCompletedWorkReport = NStr("vi = 'Biên bản nghiệm thu công việc';
													|ru = 'Акт выполненных работ';
													|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
													|it = 'Verbale di consegna dei lavori effettuati';
													|pl = 'Protokół wykonanych prac';
													|tr = 'Müşteri faturası - Hizmetler'");
	If CommonClientServer.StructureProperty(PrintParameters, "UseSynonymForKit", False) Then
		SynonymForTemplateOfCompletedWorkReport = PrintParameters.SynonymForTemplateForKit;
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Act") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "Act", SynonymForTemplateOfCompletedWorkReport, FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CustomerInvoiceServices") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "CustomerInvoiceServices", SynonymForTemplateOfCompletedWorkReport, FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificateOfCompletedWorksWithoutDiscounts") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "CertificateOfCompletedWorksWithoutDiscounts", SynonymForTemplateOfCompletedWorkReport, FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "MicrosoftWordAct") Then
		PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "MicrosoftWordAct");
		If PrintForm <> Undefined Then
			
			TemplateName = "PF_DOC_Act" + "_" + Common.DefaultLanguageCode();
			ObjectTemplateAndData = PrintManagement.TemplatesAndObjectsDataToPrint("Document.CustomerInvoiceServices", 
				TemplateName, ObjectsArray);
			
			OfficeDocuments = New Map;
			
			Template = NStr("ru = '[Organization]-[Counterparty] Акт №[Number] от [Date]';
							|vi = '[Organization]-[Counterparty] Customer invoice — Services No. [Number] dated [Date]';
							|en = '[Organization]-[Counterparty] Customer invoice — Services No. [Number] dated [Date]'; fa = '[Organization]-[Counterparty] Customer invoice — Services No. [Number] dated [Date]';
							|it = '[Organization]-[Counterparty] Customer invoice — Services No. [Number] dated [Date]';
							|pl = '[Organization]-[Counterparty] Customer invoice — Services No. [Number] dated [Date]';
							|tr = '[Organization]-[Counterparty] Tutanak No:[Number], tarih: [Date] '");
			DocumentsAttributesValues = Common.ObjectsAttributesValues(ObjectsArray, 
				"Organization,Counterparty,Number,Date,Ref");
			For Each Ref In ObjectsArray Do
				
				DocumentAttributesValues = DocumentsAttributesValues[Ref];
				DocumentAttributesValues.Date = Format(DocumentAttributesValues.Date, "DLF=D");
				DocumentAttributesValues.Number = ObjectsPrefixesClientServer.NumberForPrinting(DocumentAttributesValues.Number);
				DocumentName = StringFunctionsClientServer.InsertParametersIntoString(Template, DocumentsAttributesValues[Ref]);
				
				OfficeDocumentStorageAddress = PrintManagementTMServer.PrintCertificateOfCompletedWorkMicrosoftWord(Ref, ObjectTemplateAndData, TemplateName);
				
				OfficeDocuments.Insert(OfficeDocumentStorageAddress, DocumentName);
				
			EndDo;
			
			PrintForm.TemplateSynonym    = NStr("vi = 'Biên bản nghiệm thu công việc';
												|ru = 'Акт выполненных работ';
												|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
												|it = 'Verbale di consegna dei lavori effettuati';
												|pl = 'Protokół wykonanych prac';
												|tr = 'Müşteri faturası - Hizmetler'");
			PrintForm.OfficeDocuments = OfficeDocuments;
			
		EndIf;
	EndIf;
	
	CustomerInvoiceServicesLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function GetPrintInfo(Val DocumentsArray, Val TemplatesNamesArray) Export
	
	Return New Structure("Data,Templates",
				GetObjectDataByTemplate(DocumentsArray, TemplatesNamesArray),
				GetTemplatesAndSectionDescriptions(TemplatesNamesArray));
	
EndFunction

Function GetObjectDataByTemplate(Val DocumentsArray, Val TemplatesNamesArray) Export
	
	DataByAllObjects = New Map;
	
	StructureOfResults_ = GetDataToPrint(DocumentsArray, Undefined);
		
	PrintData			= StructureOfResults_.HeaderResults.Select();
	SelectionByDocuments 	= StructureOfResults_.ResultForTabularPart.Select(QueryResultIteration.ByGroups);
	
	While PrintData.Next() Do
		ObjectDataByTemplates = New Structure;
		// We will find services in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// If there is an empty tabular part of the service in the document, let's move on to the next document
		If FollowingIsFound Then
			SampleByService = SelectionByDocuments.Select();
		Else
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong chứng từ %1 không có dịch vụ. Không cần in biên bản bàn giao dịch vụ.';
					|ru = 'В документе %1 отсутствуют услуги. Печать акта выполненных работ (услуг) не требуется.';
					|en = 'Services are missing in document %1. Printing of ""Customer invoice — Services"" is not required.'; fa = 'Services are missing in document %1. Printing of ""Customer invoice — Services"" is not required.';
					|it = 'Non ci sono servizi nel documento %1. La stampa del verbale di consegna dei lavori (servizi) effettuati non è richiesta.';
					|pl = 'W dokumencie %1 nie ma żadnych usług. Drukowanie zestawienia wykonanych prac (usług) nie jest wymagane.';
					|tr = '%1 Belgesinde herhangi bir hizmet bulunmamaktadır. Gerçekleştirilen işler (hizmet) raporu yazdırmaya gerek yoktur'"),
				PrintData.Ref);
				
			CommonClientServer.MessageToUser(
				Text,
				PrintData.Ref);
			
			Continue;
		EndIf;

		ObjectData = GetObjectDataFromSelection(PrintData, SampleByService);
		For Each TemplateName In TemplatesNamesArray Do
			ObjectDataByTemplates.Insert(TemplateName, ObjectData);
		EndDo;
		DataByAllObjects.Insert(PrintData.Ref, ObjectDataByTemplates);
	EndDo;
	
	Return DataByAllObjects;
	
EndFunction

Function GetTemplatesAndSectionDescriptions(Val TemplatesNamesArray) Export
	
	DescriptionOfSections = New Map;
	TemplatesBinaryData = New Map;
	
	For Each TemplateName In TemplatesNamesArray Do
		
		Template = Undefined;
		DescriptionOfTemplateSections = Undefined;
		
		If TemplateName = "PF_DOC_Act" + "_" + Common.DefaultLanguageCode()  Then
			DescriptionOfTemplateSections = GetDescriptionOfAreasAndCompletedWorks();
			Template = PrintManagement.PrintFormTemplate("Document.CustomerInvoiceServices.PF_DOC_Act");
		EndIf;
		
		If DescriptionOfTemplateSections <> Undefined And Template <> Undefined Then
			
			DescriptionOfSections.Insert(TemplateName, DescriptionOfTemplateSections);
			TemplatesBinaryData.Insert(TemplateName, Template);
			
		EndIf;
		
	EndDo;
	
	Return New Structure(
						"DescriptionOfSections,TemplatesBinaryData",
						DescriptionOfSections,
						TemplatesBinaryData);
	
EndFunction

// Returns data required for generating printed forms
// 
// Parameters:
// 	ObjectsArray  - Array    - references to objects that should be printed
// 	PrintParameters - Structure - advanced print settings
// 	
// Returns:
// 	Structure - Contains data on the header of the document and the tabular part:
// 	* HeaderResults          - QueryResult - 
// 	* ResultForTabularPart - QueryResult - 
//
Function GetDataToPrint(ObjectsArray, PrintParameters) Export
	
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayDiscounts_") Then
		DisplayDiscounts_ = PrintParameters.DisplayDiscounts_;
	Else
		DisplayDiscounts_ = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
			<> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	EndIf; 
	
	Query = New Query(
	"SELECT
	|	CustomerInvoiceServices.Ref AS Ref,
	|	CustomerInvoiceServices.Number AS Number,
	|	CustomerInvoiceServices.Date AS Date,
	|	CustomerInvoiceServices.Partner AS Partner,
	|	CustomerInvoiceServices.Counterparty AS Counterparty,
	|	CustomerInvoiceServices.Organization AS Organization,
	|	CustomerInvoiceServices.Organization.Prefix AS Prefix,
	|	CustomerInvoiceServices.Currency AS Currency,
	|	CustomerInvoiceServices.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN CustomerInvoiceServices.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	CustomerInvoiceServices.AdditionalInformation AS AdditionalInformation,
	|	CustomerInvoiceServices.AdditionalInformationOfHeader AS AdditionalInformationOfHeader,
	|	CustomerInvoiceServices.CompanyBankAccount AS BankAccountOfCompany,
	|	CustomerInvoiceServices.CounterpartyBankAccount AS AccountOfCounterparty
	|FROM
	|	Document.CustomerInvoiceServices AS CustomerInvoiceServices
	|WHERE
	|	CustomerInvoiceServices.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerInvoiceServices.Ref AS Ref,
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	CustomerInvoiceServices.ProductsInSet AS ProductsInSet,
	|	CustomerInvoiceServices.ItemVariantOfSet AS ItemVariantOfSet,
	|	CustomerInvoiceServices.Products AS Products,
	|	CustomerInvoiceServices.Content AS Content,
	|	1 AS ZoomRatio,
	|	CustomerInvoiceServices.PercentRateOfManualDiscount + CustomerInvoiceServices.PercentRateOfAutomaticDiscountMarkup AS DiscountPercentage,
	|	CustomerInvoiceServices.Characteristic AS Characteristic,
	|	CustomerInvoiceServices.VATRate AS VATRate,
	|	CASE
	|		WHEN &DisplayDiscounts_
	|			THEN CustomerInvoiceServices.Price
	|		ELSE CustomerInvoiceServices.Sum / CustomerInvoiceServices.Count
	|	END AS Price,
	|	CustomerInvoiceServices.Count AS Count,
	|	CustomerInvoiceServices.Count AS NumberOfPackages,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	CustomerInvoiceServices.Sum AS Sum,
	|	CASE
	|		WHEN &DisplayDiscounts_
	|			THEN CustomerInvoiceServices.ManualDiscount + CustomerInvoiceServices.DiscountMarkupAmount
	|		ELSE 0
	|	END AS DiscountAmount,
	|	CustomerInvoiceServices.Sum + CustomerInvoiceServices.ManualDiscount + CustomerInvoiceServices.DiscountMarkupAmount AS AmountWithoutADiscount,
	|	CustomerInvoiceServices.VATAmount AS VATAmount,
	|	CustomerInvoiceServices.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	Document.CustomerInvoiceServices.Services AS CustomerInvoiceServices
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON (ProductKitConfigurations.Owner = CustomerInvoiceServices.ProductsInSet)
	|			AND (ProductKitConfigurations.Characteristic = CustomerInvoiceServices.ItemVariantOfSet)
	|			AND (ProductKitConfigurations.Main)
	|WHERE
	|	CustomerInvoiceServices.Ref IN(&DocumentsArray)
	|	AND NOT CustomerInvoiceServices.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), 
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref AS Ref,
	|	TableOfGoods.ProductsInSet AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet AS ItemVariantOfSet,
	|	MIN(TableOfGoods.LineNumber) AS LineNumber,
	|	SUM(TableOfGoods.Sum) AS Sum,
	|	SUM(TableOfGoods.AmountWithoutADiscount) AS AmountWithoutADiscount,
	|	SUM(TableOfGoods.DiscountAmount) AS DiscountAmount,
	|	SUM(TableOfGoods.VATAmount) AS VATAmount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS TableOfGoods
	|WHERE
	|	TableOfGoods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.ItemKitConfiguration AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|				AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS MainComponent,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	FALSE,
	|	SUM(ConfigurationOptionsForProductRange.Count),
	|	0
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON (TRUE)
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN
	|			(SELECT DISTINCT
	|				T.ItemKitConfiguration
	|			FROM
	|				Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.ItemKitConfiguration AS ItemKitConfiguration,
	|	Table.SetPricingOption AS SetPricingOption,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref AS Ref,
	|	Result.ItemKitConfiguration AS ItemKitConfiguration,
	|	Result.SetPricingOption AS SetPricingOption,
	|	Result.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Result.ProductsInSet AS ProductsInSet,
	|	Result.ItemVariantOfSet AS ItemVariantOfSet,
	|	(CAST(MIN(CASE
	|				WHEN Result.DefaultQuantity <> 0
	|						AND Result.MainComponent
	|					THEN Result.Count / Result.DefaultQuantity
	|				ELSE NULL
	|			END) + 0.5 AS NUMBER(10, 0))) - 1 AS Count,
	|	MAX(CASE
	|			WHEN Result.DefaultQuantity <> 0
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE NULL
	|		END) AS CoefficientMaximum,
	|	(CAST(MIN(CASE
	|				WHEN Result.DefaultQuantity <> 0
	|					THEN Result.Count / Result.DefaultQuantity
	|				ELSE NULL
	|			END) + 0.5 AS NUMBER(10, 0))) - 1 AS MinimumRatio
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration AS ItemKitConfiguration,
	|	TemporaryTableSetsOptional.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	TemporaryTableSetsOptional.SetPricingOption AS SetPricingOption,
	|	Table.Ref AS Ref,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.LineNumber AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	CASE
	|		WHEN TemporaryTableSetsOptional.MinimumRatio = TemporaryTableSetsOptional.CoefficientMaximum
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS FullSet,
	|	Table.Sum AS Sum,
	|	Table.AmountWithoutADiscount AS AmountWithoutADiscount,
	|	Table.DiscountAmount AS DiscountAmount,
	|	Table.VATAmount AS VATAmount,
	|	Table.ProductsInSet.VATRate AS VATRate
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|			AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|			AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	NestedQuery.SetPricingOption AS SetPricingOption,
	|	NestedQuery.ProductsInSet AS ProductsInSet,
	|	NestedQuery.ItemVariantOfSet AS ItemVariantOfSet,
	|	NestedQuery.IsRecordsSet AS IsRecordsSet,
	|	NestedQuery.TheseAreComponents AS TheseAreComponents,
	|	NestedQuery.FullSet AS FullSet,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Content AS ServiceNameFull,
	|	NestedQuery.Products.Code AS Code,
	|	NestedQuery.Products.SKU AS SKU,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Characteristic.DescriptionFull AS CharacteristicFullName,
	|	NestedQuery.VATRate AS VATRate,
	|	NestedQuery.Price AS Price,
	|	NestedQuery.Count AS Count,
	|	NestedQuery.Sum AS Sum,
	|	NestedQuery.VATAmount AS VATAmount,
	|	NestedQuery.DiscountAmount AS DiscountAmount,
	|	NestedQuery.AmountWithoutADiscount AS AmountWithoutADiscount,
	|	NestedQuery.LineNumber AS LineNumber,
	|	NestedQuery.Products.UnitOfMeasure AS UnitOfMeasure,
	|	NestedQuery.Products.UnitOfMeasure.Description AS UnitOfMeasurementName,
	|	NestedQuery.Products.UnitOfMeasure.Code AS UnitOfMeasureCode
	|FROM
	|	(SELECT
	|		Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|		Table.SetPricingOption AS SetPricingOption,
	|		Table.Ref AS Ref,
	|		Table.ProductsInSet AS ProductsInSet,
	|		Table.ItemVariantOfSet AS ItemVariantOfSet,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.LineNumber
	|			ELSE Table.LineNumber
	|		END AS LineNumber,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.FullSet
	|			ELSE FALSE
	|		END AS FullSet,
	|		Table.Products AS Products,
	|		Table.Content AS Content,
	|		Table.Count AS Count,
	|		Table.NumberOfPackages AS NumberOfPackages,
	|		Table.Price AS Price,
	|		Table.Sum AS Sum,
	|		Table.VATRate AS VATRate,
	|		Table.VATAmount AS VATAmount,
	|		Table.Characteristic AS Characteristic,
	|		Table.Package AS Package,
	|		Table.DiscountAmount AS DiscountAmount,
	|		Table.AmountWithoutADiscount AS AmountWithoutADiscount
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON (TemporaryTableSets.ProductsInSet = Table.ProductsInSet)
	|				AND (TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet)
	|				AND (TemporaryTableSets.Ref = Table.Ref)
	|	WHERE
	|		(Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|				OR Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|					AND Table.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents), 
	|						VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption,
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE,
	|		TRUE,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.FullSet,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ProductsInSet.DescriptionFull,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE
	|			WHEN &DisplayDiscounts_
	|				THEN CASE
	|						WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0
	|							THEN TemporaryTableSets.AmountWithoutADiscount / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|						ELSE 0
	|					END
	|			ELSE CASE
	|					WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0
	|						THEN TemporaryTableSets.Sum / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|					ELSE 0
	|				END
	|		END,
	|		TemporaryTableSets.Sum,
	|		TemporaryTableSets.ProductsInSet.VATRate,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet), 
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber,
	|	IsRecordsSet DESC
	|TOTALS
	|	SUM(DiscountAmount)
	|BY
	|	Ref");
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	
	ResultsArray         = Query.ExecuteBatch();
	HeaderResults          = ResultsArray[0];
	ResultForTabularPart = ResultsArray[8];
	
	DataStructureForPrinting 	= New Structure("HeaderResults, ResultForTabularPart",
	                                               HeaderResults, ResultForTabularPart);
	
	Return DataStructureForPrinting;
	
EndFunction

Function GetObjectDataFromSelection(PrintData, SampleByService)
	
	ObjectData = New Structure;
	
	ObjectData.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'In biên bản / hóa đơn GTGT';
																								|ru = 'Акт';
																								|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
																								|it = 'Atto';
																								|pl = 'Protokół';
																								|tr = 'Tutanak'")));
	ObjectData.Insert("AdditionalInformationOfHeader", PrintData.AdditionalInformationOfHeader);
	
	InformationAboutPerformer = PrintFormGeneration.InformationAboutLegalEntity(
		PrintData.Organization, 
		PrintData.Date,
		,
		PrintData.BankAccountOfCompany);
	CustomerInformation 	 = PrintFormGeneration.InformationAboutLegalEntity(
		PrintData.Counterparty,
		PrintData.Date,
		,
		PrintData.AccountOfCounterparty);
	
	DiscountHeader = PrintFormGeneration.YouNeedToDisplayDiscounts(SampleByService, True);
	
	ObjectData.Insert("ArtistPresentation", InformationAboutPerformer.OfficialName);
	ObjectData.Insert("CustomerPresentation_0",   CustomerInformation.OfficialName);
	ObjectData.Insert("PerformerSLegalAddress",       InformationAboutPerformer.LegalAddress);
	ObjectData.Insert("CustomerSLegalAddress",         CustomerInformation.LegalAddress);
	ObjectData.Insert("TinOfPerformer",           InformationAboutPerformer.TIN);
	ObjectData.Insert("InnOfCustomer",             CustomerInformation.TIN);
	ObjectData.Insert("ContractorSCheckpoint",           InformationAboutPerformer.CRTR);
	ObjectData.Insert("CustomerSCheckpoint",             CustomerInformation.CRTR);
	ObjectData.Insert("ContractorSCurrentAccount", InformationAboutPerformer.AccountNumber);
	ObjectData.Insert("CustomerSCurrentAccount",   CustomerInformation.AccountNumber);
	ObjectData.Insert("ArtistSCorAccount",       InformationAboutPerformer.CorrAccount);
	ObjectData.Insert("CustomerSCorAccount",         CustomerInformation.CorrAccount);
	ObjectData.Insert("ContractorSBank",          InformationAboutPerformer.Bank);
	ObjectData.Insert("CustomerSBank",            CustomerInformation.Bank);
	ObjectData.Insert("PerformerSBIC",           InformationAboutPerformer.BIC);
	ObjectData.Insert("CustomerSBIC",             CustomerInformation.BIC);
	ObjectData.Insert("AdditionalInformation", PrintData.AdditionalInformation);
	ObjectData.Insert("ConsiderVAT",             PrintData.ConsiderVAT);
	ObjectData.Insert("ShowVAT",            Constants.DisplayAdditionalVATColumns.Get());
	ObjectData.Insert("ThereAreDiscounts",               DiscountHeader.ThereAreDiscounts);
	ObjectData.Insert("DiscountHeader",          DiscountHeader.Discount);
	ObjectData.Insert("HeaderAmountWithoutDiscount",  DiscountHeader.DiscountAmount);
	ObjectData.Insert("OnlyMarkUp",            DiscountHeader.OnlyMarkUp);

	If PrintData.ConsiderVAT Then
		ObjectData.Insert("VAT", ?(PrintData.PriceIncludesVAT, 
			NStr("vi = 'Trong đó thuế GTGT:';
				|ru = 'В том числе НДС:';
				|en = 'including VAT:'; fa = 'including VAT:';
				|it = 'IVA compresa:';
				|pl = 'W tym VAT';
				|tr = 'KDV dahil:'", Common.DefaultLanguageCode()), 
			NStr("vi = 'Thuế GTGT:';
				|ru = 'Сумма НДС:';
				|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
				|it = 'Importo IVA:';
				|pl = 'Wartość VAT';
				|tr = 'KDV tutarı:'", Common.DefaultLanguageCode())));
	Else
		ObjectData.Insert("VAT", NStr("vi = 'Không thuế (GTGT)';
										|ru = 'Без налога (НДС)';
										|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
										|it = 'senza imposta (IVA)';
										|pl = 'bez podatku (VAT)';
										|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode()));
	EndIf;

	ObjectData.Insert("Services", New Array);
	
	ObjectData.Insert("UseSets", False);
	SampleByService.Reset();
	SampleByService.Next();
	If TMCommonUseClientServer.HasObjectAttribute(SampleByService, "IsRecordsSet") Then
		ObjectData.UseSets = True;
	EndIf;
	BlankData = SetsServer.BlankData();
	
	Sum    	= 0;
	VATAmount 	= 0;
	LineNumber = 0;
	
	SampleByService.Reset();
	
	While SampleByService.Next() Do
		
		LineNumberPrint = "";
		If SetsServer.DisplayOnlyTitle(SampleByService, ObjectData.UseSets) Then
		Else
			LineNumber = LineNumber + 1;
			LineNumberPrint = LineNumber;
		EndIf;
		
		PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(SampleByService, ObjectData.UseSets);
		
		ServiceTableRow = New Structure;
		ServiceTableRow.Insert("LineNumber",      LineNumberPrint);
		ServiceTableRow.Insert("OwnGoods",          	 PrefixAndPostfix.Prefix + SampleByService.ServiceNameFull + PrefixAndPostfix.Postfix);
		ServiceTableRow.Insert("Count",       SampleByService.Count);
		ServiceTableRow.Insert("UnitOfMeasure", SampleByService.UnitOfMeasure);
		ServiceTableRow.Insert("Price",             Format(SampleByService.Price,"NFD=2; NDS=,"));
		ServiceTableRow.Insert("Discount",           Format(SampleByService.DiscountAmount,"NFD=2; NDS=,"));
		ServiceTableRow.Insert("Sum",            Format(SampleByService.Sum,"NFD=2; NDS=,"));
		ServiceTableRow.Insert("VATRate",        SampleByService.VATRate);
		ServiceTableRow.Insert("VATAmount",         Format(SampleByService.VATAmount,"NFD=2; NDS=,"));
		ServiceTableRow.Insert("AmountWithoutADiscount",   Format(SampleByService.AmountWithoutADiscount,"NFD=2; NDS=,"));
		ServiceTableRow.Insert("IsRecordsSet",             SampleByService.IsRecordsSet);
		ServiceTableRow.Insert("TheseAreComponents",     SampleByService.TheseAreComponents);
		ServiceTableRow.Insert("PresentationOptionInPrintForms", SampleByService.PresentationOptionInPrintForms);
		ServiceTableRow.Insert("SetPricingOption",                  SampleByService.SetPricingOption);
		If ObjectData.ThereAreDiscounts Then
			ServiceTableRow.Discount = ?(ObjectData.OnlyMarkUp,- ServiceTableRow.Discount,ServiceTableRow.Discount);
			ServiceTableRow.Discount = Format(ServiceTableRow.Discount,"NFD=2; NDS=,");
		EndIf; 
		
		If SetsServer.DisplayOnlyTitle(SampleByService, ObjectData.UseSets) Then
			FillPropertyValues(ServiceTableRow, BlankData);
		EndIf;
		
		ObjectData.Services.Add(ServiceTableRow);
		
		If Not SetsServer.UseScope(SampleByService, ObjectData.UseSets) Then
			Sum          = Sum          + SampleByService.Sum;
			VATAmount       = VATAmount       + SampleByService.VATAmount;
		EndIf;
		
	EndDo;
	
	ObjectData.Insert("Total",		Sum);
	ObjectData.Insert("TotalVAT",	VATAmount);
	
	AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
	
	TotalString = NStr("vi = 'Tổng số công việc đã thực hiện (dịch vụ đã cung cấp) %NumberOfTitles%, với số tiền %DocumentAmount%';
						|ru = 'Всего выполнено работ (оказано услуг) %NumberOfTitles%, на сумму %DocumentAmount%';
						|en = 'Total work performed (services rendered) %NumberOfTitles%, in the amount of %DocumentAmount%'; fa = 'Total work performed (services rendered) %NumberOfTitles%, in the amount of %DocumentAmount%';
						|it = 'Lavori (servizi) totali effettuati %NumberOfTitles%, per l''importo di %DocumentAmount%';
						|pl = 'Całkowita wykonanych prac (świadczonych usług) %NumberOfTitles% na wartość %DocumentAmount%';
						|tr = 'Gerçekleştirilen tüm işler (sağlanan hizmetler) %NumberOfTitles%, tutar %DocumentAmount%'", Common.DefaultLanguageCode());
	TotalString = StrReplace(TotalString, "%NumberOfTitles%", LineNumber);
	TotalString = StrReplace(TotalString, "%DocumentAmount%", PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
	
	ObjectData.Insert("TotalString", TotalString);
	ObjectData.Insert("AmountInWords",  ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
	
	Return ObjectData;
	
EndFunction

Function GetDescriptionOfAreasAndCompletedWorks()

	Sections_ = New Structure;
	
	PrintManagement.AddAreaDetails(Sections_, "Header",				"Header");
	PrintManagement.AddAreaDetails(Sections_, "Footer",				"Footer");
	PrintManagement.AddAreaDetails(Sections_, "DocumentTitle",				"Shared3");
	PrintManagement.AddAreaDetails(Sections_, "HeaderHeader",					"Shared3");
	PrintManagement.AddAreaDetails(Sections_, "AdditionalInformationOfHeader",	"Shared3");
	PrintManagement.AddAreaDetails(Sections_, "Proposal",					"Shared3");
	PrintManagement.AddAreaDetails(Sections_, "TableHeader",					"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "String",							"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "StringSet",					"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "StringComponents",			"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "StringItSEnd",		"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "TableHeaderWithDiscount",			"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "RowWithDiscount",					"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "RowWithDiscountSet",				"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "RowWithDiscountComponents",		"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "RowWithDiscountItSEnd",	"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "TableHeaderWithDiscountWithVAT",		"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "LineWithDiscountWithVAT",					"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "LineWithDiscountWithVATSet",				"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "LineWithDiscountWithVATComponents",		"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "LineWithDiscountWithVATItSEnd",	"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "HeaderOfTableWithVAT",				"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "StringWithVAT",						"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "StringWithVATSet",				"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "StringWithVATComponents",		"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "StringWithVATItSEnd",	"TableRow");
	PrintManagement.AddAreaDetails(Sections_, "InTotal",							"Shared3");
	PrintManagement.AddAreaDetails(Sections_, "TotalVAT_",						"Shared3");
	PrintManagement.AddAreaDetails(Sections_, "AmountInWords",					"Shared3");
	PrintManagement.AddAreaDetails(Sections_, "Signatures",						"Shared3");
	PrintManagement.AddAreaDetails(Sections_, "AdditionalInformation",		"Shared3");
	
	Return Sections_;

EndFunction

// The function receives data for generating a printed form " Notification"
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array - An array of references to documents, which is necessary to obtain the data.
//  LanguageCode - String - the language in which the printed form will be displayed.
//                         It consists of the language code according to ISO 639-1 and, optionally, the country code according to ISO 3166-1, separated
//                         by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_EN".
//
// Returns:
// 	Structure:
// 		* HeaderResults - QueryResult
// 		* ResultsByPaymentStages - QueryResult
// 		* ResultForTabularPart - QueryResult
//
Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayDiscounts_") Then
		DisplayDiscounts_ = PrintParameters.DisplayDiscounts_;
	Else
		DisplayDiscounts_ = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
			<> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	EndIf; 
	
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);	
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ManualBankDetailsChange THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE Documents.CompanyBankAccount.Bank.InternationalDescription END AS BankNameInt,
	|	CASE WHEN Documents.CompanyBankAccount.ManualBankDetailsChange THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE Documents.CompanyBankAccount.TransferBank.InternationalDescription END AS BankNameForPaymentsInt,
	|	CASE WHEN Documents.CompanyBankAccount.ManualBankDetailsChange THEN Documents.CompanyBankAccount.BankSWIFTCode
	|		ELSE Documents.CompanyBankAccount.Bank.SWIFTBIC END AS BankSWIFTCode,
	|	CASE WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit THEN Documents.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE Documents.CompanyBankAccount.TransferBank.SWIFTBIC END AS BankSWIFTCodeForPayments,
	|	CASE WHEN Documents.CompanyBankAccount.ManualBankDetailsChange THEN Documents.CompanyBankAccount.BankAddressInt
	|		ELSE Documents.CompanyBankAccount.Bank.InternationalAddress END AS BankAddress,
	|	CASE WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit THEN Documents.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE Documents.CompanyBankAccount.TransferBank.InternationalAddress END AS TransferBankAddress,
	|	
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual 						AS Manager,
	|	UNDEFINED											AS Shipper,
	|	UNDEFINED											AS GoodsRecipient,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.CustomerInvoiceServices AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	1 AS LineNumber,
	|	DocumentData.Date AS PaymentDate,
	|	100 AS PaymentPercentage,
	|	DocumentData.AmountARAP AS PaymentAmount,
	|	FALSE AS ThisIsDepositForPackage
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND DocumentData.AmountARAP > 0
	|
	|GROUP BY
	|	DocumentData.Ref
	|
	|HAVING
	|	DocumentData.AmountARAP > 0
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Services.Ref AS Ref,
	|	Services.LineNumber AS LineNumber,
	|	Services.Products AS Products,
	|	Services.Products.Code AS Code,
	|	Services.Products.SKU AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Services.Products.DescriptionFull) AS DescriptionFull,
	|	Services.Content AS Content,
	|	CASE 
	|		WHEN &ThisIsMainLanguageOfSystem THEN
	|			PRESENTATION(Services.Products.UnitOfMeasure)
	|		ELSE Services.Products.UnitOfMeasure.InternationalAbbreviation
	|	END AS UnitOfMeasure,
	|	Services.Count AS Count,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Services.Price
	|		ELSE Services.Sum/Services.Count
	|	END AS Price,
	|	Services.Sum AS Sum,
	|	Services.VATRate AS VATRate,
	|	Services.VATAmount AS VATAmount,
	|	FALSE AS ThisIsReusablePackage,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Services.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	UNDEFINED AS Package,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Services.ManualDiscount + Services.DiscountMarkupAmount
	|		ELSE 0 
	|	END AS DiscountAmount,
	|	Services.Sum + Services.ManualDiscount + Services.DiscountMarkupAmount AS AmountWithoutADiscount
	|FROM
	|	Document.CustomerInvoiceServices.Services AS Services
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Services.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Services.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|WHERE
	|	Services.Ref IN(&ObjectsArray)
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	Query.SetParameter("LanguageCode", LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[2]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export

	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");

EndProcedure

Function AddCommandsToPrintSetOfDocuments() Export
	Return Not UserRightsCached.ThisIsPartner();
EndFunction

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region Other

// Generates the query result for the undelivered part of orders
//
// Parameters:
//	SelectionData_        - Structure - the fields that will be selected remains orders
//	FillParameters - Structure
//	AnArrayOfOrders       - Array - orders for which balances will be selected.
//
// Returns:
//	QueryResult - the result of the request for the unloaded part of orders \ requests.
//
Function GetQueryResultsForOrderBalances(SelectionData_, FillParameters, AnArrayOfOrders = Undefined)
	
	Query = New Query;
	
	Query.SetParameter("AnArrayOfOrders",         AnArrayOfOrders);
	Query.SetParameter("Partner",               SelectionData_.Partner);
	Query.SetParameter("Counterparty",            SelectionData_.Counterparty);
	Query.SetParameter("Contract",               SelectionData_.Contract);
	Query.SetParameter("Organization",           SelectionData_.Organization);
	Query.SetParameter("SalesOpportunity",                SelectionData_.SalesOpportunity);
	Query.SetParameter("Terms",            SelectionData_.Terms);
	Query.SetParameter("ARAPCurrency",  SelectionData_.ARAPCurrency);
	Query.SetParameter("VATTaxation",    SelectionData_.VATTaxation);
	Query.SetParameter("PriceIncludesVAT",       SelectionData_.PriceIncludesVAT);
	Query.SetParameter("Recorder",           SelectionData_.Ref);
	Query.SetParameter("LineOfBusiness", SelectionData_.LineOfBusiness);
	Query.SetParameter("SelectByOrder_",      AnArrayOfOrders <> Undefined);
	Query.SetParameter("Department",         SelectionData_.Department);
	
	UseAdvancedFeaturesOfSalesOrder = Undefined;
	FillParameters.Property("UseAdvancedFeaturesOfSalesOrder",
		UseAdvancedFeaturesOfSalesOrder);
	If UseAdvancedFeaturesOfSalesOrder = Undefined Then
		UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	EndIf;
	Query.SetParameter("ThisIsOrderAsInvoice", Not UseAdvancedFeaturesOfSalesOrder);
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
		GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	
	Query.Text =
	"SELECT
	|	OrdersTable.SalesOrder AS SalesOrder,
	|	OrdersTable.Products AS Products,
	|	OrdersTable.Characteristic AS Characteristic,
	|	OrdersTable.RowCode AS RowCode,
	|	SUM(OrdersTable.ToRegister) AS Count,
	|	SUM(OrdersTable.Sum) AS Sum
	|INTO TableBalance
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|		TurnoversByOrders.Products AS Products,
	|		TurnoversByOrders.Characteristic AS Characteristic,
	|		TurnoversByOrders.RowCode AS RowCode,
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|			TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister,
	|		(TurnoversByOrders.AmountToBeProcessedTurnover -
	|			TurnoversByOrders.IssuedAmountTurnover) AS Sum
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|			TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|		OR (TurnoversByOrders.AmountToBeProcessedTurnover -
	|			TurnoversByOrders.IssuedAmountTurnover) <> 0
	|
	|	UNION ALL
	|	
	|	SELECT
	|		OrdersRegisterRecords.ReferenceOrder,
	|		OrdersRegisterRecords.Products,
	|		OrdersRegisterRecords.Characteristic,
	|		OrdersRegisterRecords.RowCode,
	|		-OrdersRegisterRecords.ForRegistrationQuantity + OrdersRegisterRecords.IssuedQuantity,
	|		-OrdersRegisterRecords.AmountToBeProcessed + OrdersRegisterRecords.IssuedAmount
	|	FROM
	|		#OrdersForShipmentRegisteredRecordsExpanded AS OrdersRegisterRecords
	|
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerOrderGoods.Ref,
	|		CustomerOrderGoods.Products,
	|		CustomerOrderGoods.Characteristic,
	|		CustomerOrderGoods.RowCode,
	|		CustomerOrderGoods.Count,
	|		CustomerOrderGoods.AmountIncludingVAT
	|	FROM
	|		Document.SalesOrder.Goods AS CustomerOrderGoods
	|	WHERE
	|		CASE
	|			WHEN &SelectByOrder_
	|				THEN CustomerOrderGoods.Ref IN (&AnArrayOfOrders)
	|			ELSE CustomerOrderGoods.Ref.Partner = &Partner
	|				AND CustomerOrderGoods.Ref.Counterparty = &Counterparty
	|				AND CustomerOrderGoods.Ref.Contract = &Contract
	|				AND CustomerOrderGoods.Ref.Organization = &Organization
	|				AND CustomerOrderGoods.Ref.BusinessOperation IN
	|						(VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|							VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
	|							VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))
	|				AND CustomerOrderGoods.Ref.Terms = &Terms
	|				AND CustomerOrderGoods.Ref.SalesOpportunity = &SalesOpportunity
	|				AND CustomerOrderGoods.Ref.Currency = &ARAPCurrency
	|				AND CASE
	|					WHEN CustomerOrderGoods.Ref.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|						THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|					ELSE CustomerOrderGoods.Ref.VATTaxation
	|				END = &VATTaxation
	|				AND CustomerOrderGoods.Ref.PriceIncludesVAT = &PriceIncludesVAT
	|				AND CustomerOrderGoods.Ref.LineOfBusiness = &LineOfBusiness
	|		END
	|		AND CustomerOrderGoods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
	|		AND NOT CustomerOrderGoods.Canceled
	|		AND NOT CustomerOrderGoods.Ref.DeletionMark
	|		AND CustomerOrderGoods.Ref.ThisIsOrderAsInvoice
	|		AND CustomerOrderGoods.Ref.ThisIsOrderAsInvoice = &ThisIsOrderAsInvoice
	|
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerOrderGoods.Ref,
	|		CustomerOrderGoods.Products,
	|		CustomerOrderGoods.Characteristic,
	|		CustomerOrderGoods.RowCode,
	|		CustomerOrderGoods.Count,
	|		CustomerOrderGoods.AmountIncludingVAT
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS CustomerOrderGoods
	|	WHERE
	|		CASE
	|			WHEN &SelectByOrder_
	|				THEN CustomerOrderGoods.Ref IN (&AnArrayOfOrders)
	|			ELSE CustomerOrderGoods.Ref.Partner = &Partner
	|				AND CustomerOrderGoods.Ref.Counterparty = &Counterparty
	|				AND CustomerOrderGoods.Ref.Contract = &Contract
	|				AND CustomerOrderGoods.Ref.Organization = &Organization
	|				AND CustomerOrderGoods.Ref.BusinessOperation IN
	|						(VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|							VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
	|							VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))
	|				AND CustomerOrderGoods.Ref.Terms = &Terms
	|				AND CustomerOrderGoods.Ref.SalesOpportunity = &SalesOpportunity
	|				AND CustomerOrderGoods.Ref.Currency = &ARAPCurrency
	|				AND CASE
	|					WHEN CustomerOrderGoods.Ref.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|						THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|					ELSE CustomerOrderGoods.Ref.VATTaxation
	|				END = &VATTaxation
	|				AND CustomerOrderGoods.Ref.PriceIncludesVAT = &PriceIncludesVAT
	|				AND CustomerOrderGoods.Ref.LineOfBusiness = &LineOfBusiness
	|		END
	|		AND CustomerOrderGoods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
	|		AND NOT CustomerOrderGoods.Canceled
	|		AND NOT CustomerOrderGoods.Ref.DeletionMark
	|		AND CustomerOrderGoods.Ref.ThisIsOrderAsInvoice
	|		AND CustomerOrderGoods.Ref.ThisIsOrderAsInvoice = &ThisIsOrderAsInvoice) AS OrdersTable
	|WHERE
	|	OrdersTable.SalesOrder.Department = &Department
	|
	|GROUP BY
	|	OrdersTable.SalesOrder,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.RowCode
	|
	|HAVING
	|	SUM(OrdersTable.ToRegister) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableBalance.SalesOrder AS SalesOrder,
	|	OrderingProducts.Ref.ARAPObjectSettings AS ARAPObjectSettings,
	|	TableBalance.Products AS Products,
	|	TableBalance.Characteristic AS Characteristic,
	|	TableBalance.RowCode AS RowCode,
	|	TableBalance.Count AS Count,
	|	TableBalance.Sum AS AmountARAP,
	|	OrderingProducts.PartnerProducts AS PartnerProducts,
	|	OrderingProducts.ProductsInSet AS ProductsInSet,
	|	OrderingProducts.ItemVariantOfSet AS ItemVariantOfSet,
	|	OrderingProducts.DateOfShipment AS DateOfShipment,
	|	OrderingProducts.LineNumber AS LineNumber,
	|	OrderingProducts.Ref.SalesOpportunity AS SalesOpportunity,
	|	OrderingProducts.PriceKind AS PriceKind,
	|	OrderingProducts.Count AS QuantityInOrder,
	|	OrderingProducts.Price AS Price,
	|	OrderingProducts.VATRate AS VATRate,
	|	OrderingProducts.Sum AS Sum,
	|	OrderingProducts.VATAmount AS VATAmount,
	|	OrderingProducts.AmountIncludingVAT AS AmountIncludingVAT,
	|	OrderingProducts.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	OrderingProducts.ManualDiscount AS ManualDiscount,
	|	OrderingProducts.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
	|	OrderingProducts.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	OrderingProducts.AmountOfBonusPointsToDeduction AS AmountOfBonusPointsToDeduction,
	|	OrderingProducts.AmountOfBonusPointsToDeductionInCurrency AS AmountOfBonusPointsToDeductionInCurrency,
	|	OrderingProducts.AmountOfEarnedBonusPointsInCurrency AS AmountOfEarnedBonusPointsInCurrency,
	|	OrderingProducts.Products.ItemsType AS ItemsType,
	|	OrderingProducts.Department AS Department,
	|	OrderingProducts.ConnectionKey AS ConnectionKey,
	|	CASE
	|		WHEN OrderingProducts.WithAssignment
	|			THEN TableBalance.SalesOrder.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	OrderingProducts.Content AS Content
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.SalesOrder.Goods AS OrderingProducts
	|		ON TableBalance.Products = OrderingProducts.Products
	|			AND TableBalance.Characteristic = OrderingProducts.Characteristic
	|			AND TableBalance.RowCode = OrderingProducts.RowCode
	|			AND TableBalance.SalesOrder = OrderingProducts.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	TableBalance.SalesOrder,
	|	OrderingProducts.Ref.ARAPObjectSettings,
	|	TableBalance.Products,
	|	TableBalance.Characteristic,
	|	TableBalance.RowCode,
	|	TableBalance.Count,
	|	TableBalance.Sum,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef),
	|	OrderingProducts.ProductsInSet AS ProductsInSet,
	|	OrderingProducts.ItemVariantOfSet AS ItemVariantOfSet,
	|	OrderingProducts.DateOfShipment,
	|	OrderingProducts.LineNumber,
	|	OrderingProducts.Ref.SalesOpportunity,
	|	OrderingProducts.PriceKind,
	|	OrderingProducts.Count,
	|	OrderingProducts.Price,
	|	OrderingProducts.VATRate,
	|	OrderingProducts.Sum,
	|	OrderingProducts.VATAmount,
	|	OrderingProducts.AmountIncludingVAT,
	|	OrderingProducts.PercentRateOfManualDiscount,
	|	OrderingProducts.ManualDiscount,
	|	OrderingProducts.PercentRateOfAutomaticDiscountMarkup,
	|	OrderingProducts.DiscountMarkupAmount,
	|	OrderingProducts.AmountOfBonusPointsToDeduction,
	|	OrderingProducts.AmountOfBonusPointsToDeductionInCurrency,
	|	OrderingProducts.AmountOfEarnedBonusPointsInCurrency,
	|	OrderingProducts.Products.ItemsType,
	|	OrderingProducts.Department,
	|	OrderingProducts.ConnectionKey,
	|	CASE
	|		WHEN OrderingProducts.WithAssignment
	|			THEN TableBalance.SalesOrder.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	OrderingProducts.Content
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS OrderingProducts
	|		ON TableBalance.Products = OrderingProducts.Products
	|			AND TableBalance.Characteristic = OrderingProducts.Characteristic
	|			AND TableBalance.RowCode = OrderingProducts.RowCode
	|			AND TableBalance.SalesOrder = OrderingProducts.Ref
	|
	|ORDER BY
	|	TableBalance.SalesOrder,
	|	OrderingProducts.LineNumber,
	|	TableBalance.Products,
	|	TableBalance.Characteristic,
	|	OrderingProducts.DateOfShipment;
	|
	|SELECT TOP 1
	|	CustomerOrderGoods.LineNumber
	|FROM
	|	Document.SalesOrder.Goods AS CustomerOrderGoods
	|WHERE
	|	CustomerOrderGoods.Ref IN (&AnArrayOfOrders)
	|	AND CustomerOrderGoods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
	|	AND CustomerOrderGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND NOT CustomerOrderGoods.Canceled
	|	AND CustomerOrderGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	CustomerOrderGoods.LineNumber
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS CustomerOrderGoods
	|WHERE
	|	CustomerOrderGoods.Ref IN (&AnArrayOfOrders)
	|	AND CustomerOrderGoods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
	|	AND CustomerOrderGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND NOT CustomerOrderGoods.Canceled
	|	AND CustomerOrderGoods.Ref.Posted
	|";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"CASE
		|			WHEN &SelectByOrder_
		|				THEN ReferenceOrder IN (&AnArrayOfOrders)
		|			ELSE ReferenceOrder.Partner = &Partner
		|				AND ReferenceOrder.Counterparty = &Counterparty
		|				AND ReferenceOrder.Contract = &Contract
		|				AND ReferenceOrder.Organization = &Organization
		|				AND ReferenceOrder.BusinessOperation IN
		|					(VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|					VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
		|					VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))
		|				AND ReferenceOrder.Terms = &Terms
		|				AND ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|				AND ReferenceOrder.Currency = &ARAPCurrency
		|				AND CASE
		|					WHEN ReferenceOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|						THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|					ELSE ReferenceOrder.VATTaxation
		|				END = &VATTaxation
		|				AND ReferenceOrder.PriceIncludesVAT = &PriceIncludesVAT
		|				AND ReferenceOrder.LineOfBusiness = &LineOfBusiness
		|		END
		|		AND ReferenceOrder.ThisIsOrderAsInvoice = &ThisIsOrderAsInvoice
		|		AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count, Sum";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"		Recorder = &Recorder
		|		AND CASE
		|				WHEN &SelectByOrder_
		|					THEN ReferenceOrder IN (&AnArrayOfOrders)
		|				ELSE ReferenceOrder.Partner = &Partner
		|						AND ReferenceOrder.Counterparty = &Counterparty
		|						AND ReferenceOrder.Contract = &Contract
		|						AND ReferenceOrder.Organization = &Organization
		|						AND ReferenceOrder.BusinessOperation IN
		|							(VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|							VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
		|							VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))
		|						AND ReferenceOrder.Terms = &Terms
		|						AND ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|						AND ReferenceOrder.Currency = &ARAPCurrency
		|						AND CASE
		|							WHEN ReferenceOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|								THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|							ELSE ReferenceOrder.VATTaxation
		|						END = &VATTaxation
		|						AND ReferenceOrder.PriceIncludesVAT = &PriceIncludesVAT
		|						AND ReferenceOrder.LineOfBusiness = &LineOfBusiness
		|			END
		|		AND Active
		|		AND ReferenceOrder.ThisIsOrderAsInvoice = &ThisIsOrderAsInvoice
		|		AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count, Sum";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#OrdersForShipmentRegisteredRecordsExpanded",
		OrdersForShipmentRegisteredRecordsExpanded);
	
	SetPrivilegedMode(True);
	
	Return Query.ExecuteBatch();

EndFunction

Function FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects, PrintParameters = Undefined)
	
	SetPrivilegedMode(True);
	
	ShowVAT = Constants.DisplayAdditionalVATColumns.Get();
	
	UseManualDiscounts         = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseAutomaticDiscounts = GetFunctionalOption("UseDiscountsMarkupsInSales");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_CustomerInvoiceServices_Act";
	
	StructureOfResults_ = GetDataToPrint(ObjectsArray, PrintParameters);
		
	PrintData			= StructureOfResults_.HeaderResults.Select();
	SelectionByDocuments 	= StructureOfResults_.ResultForTabularPart.Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		// We will find services in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// If there is an empty tabular part of the service in the document, let's move on to the next document
		If FollowingIsFound Then
			SampleByService = SelectionByDocuments.Select();
			DiscountHeader = PrintFormGeneration.YouNeedToDisplayDiscounts(SampleByService, UseManualDiscounts Or UseAutomaticDiscounts);
			ThereAreDiscounts = DiscountHeader.ThereAreDiscounts;
			ThereIsVAT = PrintData.ConsiderVAT;
			SampleByService.Reset();
		Else
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong chứng từ %1 không có dịch vụ. Không cần in biên bản bàn giao dịch vụ.';
					|ru = 'В документе %1 отсутствуют услуги. Печать акта выполненных работ (услуг) не требуется.';
					|en = 'Services are missing in document %1. Printing of ""Customer invoice — Services"" is not required.'; fa = 'Services are missing in document %1. Printing of ""Customer invoice — Services"" is not required.';
					|it = 'Non ci sono servizi nel documento %1. La stampa del verbale di consegna dei lavori (servizi) effettuati non è richiesta.';
					|pl = 'W dokumencie %1 nie ma żadnych usług. Drukowanie zestawienia wykonanych prac (usług) nie jest wymagane.';
					|tr = '%1 Belgesinde herhangi bir hizmet bulunmamaktadır. Gerçekleştirilen işler (hizmet) raporu yazdırmaya gerek yoktur'"),
				PrintData.Ref);
				
			CommonClientServer.MessageToUser(
				Text,
				PrintData.Ref);
			
			Continue;
		EndIf;
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		Template = PrintManagement.PrintFormTemplate("Document.CustomerInvoiceServices.PF_MXL_Act");
		
		// We display the header of the act
		
		TemplateArea = Template.GetArea("Title");
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'In biên bản / hóa đơn GTGT';
																												|ru = 'Акт';
																												|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
																												|it = 'Atto';
																												|pl = 'Protokół';
																												|tr = 'Tutanak'", Common.DefaultLanguageCode())));
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		SpreadsheetDocument.Put(TemplateArea);
		
		If Not PrintData.AdditionalInformationOfHeader="" Then
			TemplateArea = Template.GetArea("AdditionalInformationOfHeader");
			TemplateArea.Parameters.Fill(PrintData);
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		TemplateArea = Template.GetArea("HeaderText");
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Service table
		
		If ThereAreDiscounts Then
			If ThereIsVAT And ShowVAT Then
				AreaNameHeader               = "TableHeaderWithDiscountWithVAT";
				AreaNameString              = "LineWithDiscountWithVAT";
				AreaNameStringSet         = "LineWithDiscountWithVATSet";
				AreaNameStringComponents = "LineWithDiscountWithVATComponents";
			Else
				AreaNameHeader               = "TableHeaderWithDiscount";
				AreaNameString              = "RowWithDiscount";
				AreaNameStringSet         = "RowWithDiscountSet";
				AreaNameStringComponents = "RowWithDiscountComponents";	
			EndIf;
		Else
			If ThereIsVAT And ShowVAT Then
				AreaNameHeader               = "HeaderOfTableWithVAT";
				AreaNameString              = "StringWithVAT";
				AreaNameStringSet         = "StringWithVATSet";
				AreaNameStringComponents = "StringWithVATComponents";
			Else
				AreaNameHeader               = "TableHeader";
				AreaNameString              = "String";
				AreaNameStringSet         = "StringSet";
				AreaNameStringComponents = "StringComponents";	
			EndIf;
		EndIf;
		
		TemplateArea = Template.GetArea(AreaNameHeader);
		LineAreaStandard = Template.GetArea(AreaNameString);
		
		UseSets = False;
		If TMCommonUseClientServer.HasObjectAttribute(SelectionByDocuments, "IsRecordsSet") Then
			UseSets = True;
			RowAreaSet         = Template.GetArea(AreaNameStringSet);
			RowAreaComponents = Template.GetArea(AreaNameStringComponents);
		EndIf;
		
		BlankData = SetsServer.BlankData();
		
		If ThereAreDiscounts Then
			StructureOfDiscountHeader = New Structure("Discount, AmountWithoutADiscount", 
				DiscountHeader.Discount,
				DiscountHeader.DiscountAmount);
			TemplateArea.Parameters.Fill(StructureOfDiscountHeader);
		EndIf; 
		SpreadsheetDocument.Put(TemplateArea);
		
		Sum       = 0;
		VATAmount    = 0;
		LineNumber = 0;
		
		// Output the rows of the Services table
		
		While SampleByService.Next() Do
			
			If SetsServer.UseSetArea(SampleByService, UseSets) Then
				RowArea = RowAreaSet;
			ElsIf SetsServer.UseScope(SampleByService, UseSets) Then
				RowArea = RowAreaComponents;
			Else
				RowArea = LineAreaStandard;
			EndIf;
			
			LineNumberPrint = "";
			If SetsServer.DisplayOnlyTitle(SampleByService, UseSets) Then
			Else
				LineNumber = LineNumber + 1;
				LineNumberPrint = LineNumber;
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(SampleByService, UseSets) Then
				RowArea.Parameters.Fill(BlankData);
			Else
				RowArea.Parameters.Fill(SampleByService);
			EndIf;
			
			PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(SampleByService, UseSets);
			
			StringDataStructure = New Structure;
			StringDataStructure.Insert("LineNumber", LineNumberPrint);
			StringDataStructure.Insert("OwnGoods", PrefixAndPostfix.Prefix + SampleByService.ServiceNameFull + PrefixAndPostfix.Postfix );
			
			If ThereAreDiscounts Then
				
				StringDataStructure.Insert("Discount", ?(DiscountHeader.OnlyMarkUp,- SampleByService.DiscountAmount,SampleByService.DiscountAmount));
				StringDataStructure.Insert("AmountWithoutADiscount", PrintFormGeneration.SumFormat(SampleByService.Sum + SampleByService.DiscountAmount));
				
			EndIf;
			
			If Not SetsServer.UseScope(SampleByService, UseSets) Then
				Sum          = Sum          + SampleByService.Sum;
				VATAmount       = VATAmount       + SampleByService.VATAmount;
			EndIf;
			
			RowArea.Parameters.Fill(StringDataStructure);
			If SetsServer.DisplayOnlyTitle(SampleByService, UseSets) Then
				RowArea.Parameters.Fill(BlankData);
			EndIf;
			
			SpreadsheetDocument.Put(RowArea);
			
		EndDo;
		
		TemplateArea = Template.GetArea("InTotal");
		DataStructureTotal = New Structure("Total",PrintFormGeneration.SumFormat(Sum));
		TemplateArea.Parameters.Fill(DataStructureTotal);
		SpreadsheetDocument.Put(TemplateArea);
		
		If GetFunctionalOption("UseVATAccounting") Then
			TemplateArea = Template.GetArea("TotalVAT_");
			DataStructureTotalVAT = New Structure;
			DataStructureTotalVAT.Insert("TotalVAT", VATAmount);
			If ThereIsVAT Then
				DataStructureTotalVAT.Insert("VAT", ?(PrintData.PriceIncludesVAT, 
					NStr("vi = 'Trong đó thuế GTGT:';
						|ru = 'В том числе НДС:';
						|en = 'including VAT:'; fa = 'including VAT:';
						|it = 'IVA compresa:';
						|pl = 'W tym VAT';
						|tr = 'KDV dahil:'", Common.DefaultLanguageCode()), 
					NStr("vi = 'Thuế GTGT:';
						|ru = 'Сумма НДС:';
						|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
						|it = 'Importo IVA:';
						|pl = 'Wartość VAT';
						|tr = 'KDV tutarı:'", Common.DefaultLanguageCode())));
			Else
				DataStructureTotalVAT.Insert("VAT", NStr("vi = 'Không thuế (GTGT)';
														|ru = 'Без налога (НДС)';
														|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
														|it = 'senza imposta (IVA)';
														|pl = 'bez podatku (VAT)';
														|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode()));
			EndIf;
			TemplateArea.Parameters.Fill(DataStructureTotalVAT);
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
		TemplateArea = Template.GetArea("AmountInWords");
		DataStructureSumInWords = New Structure;
		
		TotalString = NStr("vi = 'Tổng số công việc đã thực hiện (dịch vụ đã cung cấp) %NumberOfTitles%, với số tiền %DocumentAmount%';
							|ru = 'Всего выполнено работ (оказано услуг) %NumberOfTitles%, на сумму %DocumentAmount%';
							|en = 'Total work performed (services rendered) %NumberOfTitles%, in the amount of %DocumentAmount%'; fa = 'Total work performed (services rendered) %NumberOfTitles%, in the amount of %DocumentAmount%';
							|it = 'Lavori (servizi) totali effettuati %NumberOfTitles%, per l''importo di %DocumentAmount%';
							|pl = 'Całkowita wykonanych prac (świadczonych usług) %NumberOfTitles% na wartość %DocumentAmount%';
							|tr = 'Gerçekleştirilen tüm işler (sağlanan hizmetler) %NumberOfTitles%, tutar %DocumentAmount%'", Common.DefaultLanguageCode());
		TotalString = StrReplace(TotalString, "%NumberOfTitles%", LineNumber);
		TotalString = StrReplace(TotalString, "%DocumentAmount%", PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
		
		DataStructureSumInWords.Insert("TotalString", TotalString);
		DataStructureSumInWords.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
		TemplateArea.Parameters.Fill(DataStructureSumInWords);
		SpreadsheetDocument.Put(TemplateArea);
		
		If Not PrintData.AdditionalInformation="" Then
			TemplateArea = Template.GetArea("AdditionalInformation");
			TemplateArea.Parameters.Fill(PrintData);
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		InformationAboutPerformer = PrintFormGeneration.InformationAboutLegalEntity(
			PrintData.Organization,
			PrintData.Date,
			,
			PrintData.BankAccountOfCompany,
			True);
			
		CustomerInformation 	 = PrintFormGeneration.InformationAboutLegalEntity(
			PrintData.Counterparty,
			PrintData.Date,
			,
			PrintData.AccountOfCounterparty);
		
		TemplateArea = Template.GetArea("Signatures");
		SignatureDataStructure = New Structure;
		SignatureDataStructure.Insert("ArtistPresentation", InformationAboutPerformer.OfficialName);
		SignatureDataStructure.Insert("CustomerPresentation_0", CustomerInformation.OfficialName);
		SignatureDataStructure.Insert("PerformerSLegalAddress", InformationAboutPerformer.LegalAddress);
		SignatureDataStructure.Insert("CustomerSLegalAddress", CustomerInformation.LegalAddress);
		SignatureDataStructure.Insert("ContractorSCurrentAccount", InformationAboutPerformer.AccountNumber);
		SignatureDataStructure.Insert("CustomerSCurrentAccount", CustomerInformation.AccountNumber);
		SignatureDataStructure.Insert("ArtistSCorAccount", InformationAboutPerformer.CorrAccount);
		SignatureDataStructure.Insert("CustomerSCorAccount", CustomerInformation.CorrAccount);
		SignatureDataStructure.Insert("ContractorSBank", InformationAboutPerformer.Bank);
		SignatureDataStructure.Insert("CustomerSBank", CustomerInformation.Bank);
		SignatureDataStructure.Insert("PerformerSBIC", InformationAboutPerformer.BIC);
		SignatureDataStructure.Insert("CustomerSBIC", CustomerInformation.BIC);
		InnkppOfCustomer = "";
		If CustomerInformation.Property("CRTR") And ValueIsFilled(CustomerInformation.CRTR) Then
			InnkppOfCustomer = NStr("vi = 'MST/MĐK:';
									|ru = 'ИНН/КПП:';
									|en = 'TIN/KPP:'; fa = 'TIN/KPP:';
									|it = 'Codice fiscale/ codice causale di registrazione fiscale';
									|pl = 'NIP/Kod przyczyny wpisu do ewidencji';
									|tr = 'VKN/KPP:'", Common.DefaultLanguageCode()) + " " + CustomerInformation.TIN + "/" + CustomerInformation.CRTR;
		Else
			InnkppOfCustomer = NStr("vi = 'MST:';
									|ru = 'ИНН:';
									|en = 'TIN:'; fa = 'شناسه مالیاتی:';
									|it = 'Codice fiscale:';
									|pl = 'NIP:';
									|tr = 'VKN:'", Common.DefaultLanguageCode()) + " " + CustomerInformation.TIN;
		EndIf;
		SignatureDataStructure.Insert("InnkppOfCustomer", InnkppOfCustomer);
		InnkppOfExecutor = "";
		If InformationAboutPerformer.Property("CRTR") And ValueIsFilled(InformationAboutPerformer.CRTR) Then
			InnkppOfExecutor = NStr("vi = 'MST/MĐK:';
									|ru = 'ИНН/КПП:';
									|en = 'TIN/KPP:'; fa = 'TIN/KPP:';
									|it = 'Codice fiscale/ codice causale di registrazione fiscale';
									|pl = 'NIP/Kod przyczyny wpisu do ewidencji';
									|tr = 'VKN/KPP:'", Common.DefaultLanguageCode()) + " " + InformationAboutPerformer.TIN + "/" + InformationAboutPerformer.CRTR;
		Else
			InnkppOfExecutor = NStr("vi = 'MST:';
									|ru = 'ИНН:';
									|en = 'TIN:'; fa = 'شناسه مالیاتی:';
									|it = 'Codice fiscale:';
									|pl = 'NIP:';
									|tr = 'VKN:'", Common.DefaultLanguageCode()) + " " + InformationAboutPerformer.TIN;
		EndIf;
		SignatureDataStructure.Insert("InnkppOfExecutor", InnkppOfExecutor);
		TemplateArea.Parameters.Fill(SignatureDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
			
		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
			Metadata.Documents.CustomerInvoiceServices.FullName(),
			ObjectsArray, Undefined);
		
	EndIf;
		
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"CustomerInvoiceServices");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormOfActOnProvisionOfServices(PrintKit.Objects, PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"CertificateOfCompletedWorksWithoutDiscounts");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormOfActOnProvisionOfServices(PrintKit.Objects, PrintObjects, New Structure("DisplayDiscounts_", False)));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoice");
	PrintParameters.Delete("DisplayDiscounts_");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoiceServices", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceForPaymentWithoutDiscounts");
	PrintParameters.Insert("DisplayDiscounts_", False);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoiceServices", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoiceWithFacsimile");
	PrintParameters.Delete("DisplayDiscounts_");
	PrintParameters.Insert("DisplayFacsimiles", True);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoiceServices", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceWithFacsimileWithoutDiscounts");
	PrintParameters.Insert("DisplayDiscounts_", False);
	PrintParameters.Insert("DisplayFacsimiles", True);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoiceServices", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoiceEn");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoiceServices", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.CreatePrintedProformaInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	CustomerInvoiceServicesLocalization.CreateSetOfPrintedForms(ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects,
		PrintFormsSet);
		
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.CustomerInvoiceServices",
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects);
	
EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	CustomerInvoiceServicesLocalization.PrintFormsSet(PrintFormsSet);
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "CustomerInvoiceServices", NStr("vi = 'Biên bản nghiệm thu công việc (hiển thị chiết khấu)';
																													|ru = 'Акт выполненных работ (выводить скидки)';
																													|en = 'Customer invoice — Services (display discounts)'; fa = 'Customer invoice — Services (display discounts)';
																													|it = 'Verbale di consegna dei lavori effettuati (visualizzare gli sconti)';
																													|pl = 'Protokół odbioru wykonania prac (wyprowadzać rabaty)';
																													|tr = 'Gerçekleştirilen işler raporu (indirimleri göster)'"),                     1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "CertificateOfCompletedWorksWithoutDiscounts", NStr("vi = 'Biên bản nghiệm thu công việc (không hiển thị chiết khấu)';
																																		|ru = 'Акт выполненных работ (не выводить скидки)';
																																		|en = 'Customer invoice — Services (do not display discounts)'; fa = 'Customer invoice — Services (do not display discounts)';
																																		|it = 'Verbale di consegna dei lavori effettuati (non visualizzare gli sconti)';
																																		|pl = 'Protokół odbioru wykonania prac (nie wyprowadzać rabaty)';
																																		|tr = 'Gerçekleştirilen işler raporu (indirimleri gösterme)'"),         0);
	Else
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "CertificateOfCompletedWorksWithoutDiscounts", NStr("vi = 'Biên bản nghiệm thu công việc';
																																		|ru = 'Акт выполненных работ';
																																		|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
																																		|it = 'Verbale di consegna dei lavori effettuati';
																																		|pl = 'Protokół wykonanych prac';
																																		|tr = 'Gerçekleştirilen işler raporu'"),                     1);
	EndIf;
	
	If GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoice", NStr("vi = 'Yêu cầu thanh toán (hiển thị chiết khấu)';
																											|ru = 'Счет на оплату (выводить скидки)';
																											|en = 'Commercial invoice (display discounts)'; fa = 'Commercial invoice (display discounts)';
																											|it = 'Fattura di pagamento (visualizzare gli sconti)';
																											|pl = 'Rachunek do płatności (wyświetlać zniżki)';
																											|tr = 'Ticari fatura (indirimleri göster)'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceForPaymentWithoutDiscounts", NStr("vi = 'Yêu cầu thanh toán (không hiển thị chiết khấu)';
																																|ru = 'Счет на оплату (не выводить скидки)';
																																|en = 'Commercial invoice (do not display discounts)'; fa = 'Commercial invoice (do not display discounts)';
																																|it = 'Fattura di pagamento (non visualizzare gli sconti)';
																																|pl = 'Rachunek do płatności (nie wyświetlać zniżki)';
																																|tr = 'Ticari fatura (indirimleri gösterme)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceWithFacsimile",  NStr("vi = 'Yêu cầu thanh toán ký qua fax (hiển thị chiết khấu)';
																															|ru = 'Счет на оплату с факсимиле (выводить скидки)';
																															|en = 'Commercial invoice with facsimile (display discounts)'; fa = 'Commercial invoice with facsimile (display discounts)';
																															|it = 'Fattura di pagamento in facsimile (visualizzare gli sconti)';
																															|pl = 'Rachunek do płatności z faksymile (wyświetlać zniżki)';
																															|tr = 'Kaşeli ticari fatura (indirimleri göster)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceWithFacsimileWithoutDiscounts",  NStr("vi = 'Yêu cầu thanh toán ký qua fax(không hiển thị chiết khấu)';
																																	|ru = 'Счет на оплату с факсимиле (не выводить скидки)';
																																	|en = 'Commercial invoice with facsimile (do not display discounts)'; fa = 'Commercial invoice with facsimile (do not display discounts)';
																																	|it = 'Fattura di pagamento in facsimile (non visualizzare gli sconti)';
																																	|pl = 'Rachunek do płatności z faksymile (nie wyświetlać zniżki)';
																																	|tr = 'Kaşeli ticari fatura (indirimleri gösterme)'"), 0);
	EndIf;
	
	If GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceForPaymentWithoutDiscounts", NStr("vi = 'Yêu cầu thanh toán';
																																|ru = 'Счет на оплату';
																																|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
																																|it = 'Fattura di pagamento';
																																|pl = 'Rachunek do zapłaty';
																																|tr = 'Ticari fatura'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceWithFacsimile", NStr("vi = 'Yêu cầu thanh toán ký qua fax';
																														|ru = 'Счет на оплату с факсимиле';
																														|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
																														|it = 'Fattura di pagamento in facsimile';
																														|pl = 'Rachunek do płatności z faksymile';
																														|tr = 'Kaşeli ticari fatura'"), 0);
	EndIf;
	If Constants.UseInternationalPrintingForms.Get() Then
		If Not GetFunctionalOption("UseCustomerCommercialInvoices") Then
			InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceEn", NStr("vi = 'Proforma invoice';
																													|ru = 'Proforma invoice';
																													|en = 'Proforma invoice'; fa = 'پیش‌فاکتور';
																													|it = 'Proforma invoice';
																													|pl = 'Proforma invoice';
																													|tr = 'Proforma invoice'"), 1);
		EndIf;
	EndIf;
	Return PrintFormsSet;
	
EndFunction

Function QueryTextTTGoodsOrderInvoiceShipped()
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	UNDEFINED AS Package,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.Count) AS NumberOfPackages,
	|	SUM(DocumentGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	UNDEFINED AS Series,
	|	UNDEFINED AS Warehouse,
	|	TTDocuments.DocumentRef AS Ref
	|INTO TTGoodsNotShipped
	|FROM
	|	Document.CustomerInvoiceServices.Services AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|WHERE
	|	TTDocuments.Posted
	|GROUP BY
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	TTDocuments.DocumentRef
	|;
	|";
	
	Return QueryText;
	
EndFunction

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.CustomerInvoiceServices - The document for which you want to get the data.
//  AttributesValues - Structure
// 
// Returns:
//  ValueTable - ValueTable:
// 		* OrderDocument - DocumentRef - OrderDocument
// 		* Date - Date - Document date
// 		* ApprovalDate - Date - Approval date (for orders)
// 		* DateOfShipment - Date - Scheduled shipment date
// 		* AmountARAP - Number - Amount Of Settlements By Line
// 		* AmountARAPByPackage - Number - The amount of settlements by container by line
Function OrderAmounts(ObjectReference_, AttributesValues = Undefined) Export
	
	Query = New Query;
	
	Query.Text = "SELECT
	|	Goods.SalesOrder        AS OrderDocument,
	|	CASE
	|		WHEN Goods.RowCode = 0
	|		AND &ByOrders
	|			THEN TRUE
	|		ELSE FALSE
	|	END                      AS ExceedingOrder,
	|	Goods.AmountIncludingVAT           AS PaymentAmount,
	|	Goods.AmountARAP AS AmountARAP,
	|	&OrderingCaps                AS OrderingCaps
	|INTO TTProducts_1
	|FROM
	|	&ValueTable AS Goods
	|WHERE &LinkCondition_
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE WHEN ISNULL(TTProducts_1.OrderDocument.Number, """") = """"
	|				THEN TTProducts_1.OrderingCaps
	|			ELSE TTProducts_1.OrderDocument
	|	END								AS OrderDocument,
	|	CASE WHEN ISNULL(TTProducts_1.OrderDocument.Number, """") = """"
	|				THEN ISNULL(TTProducts_1.OrderingCaps.DATE, DATETIME(1,1,1))
	|			ELSE ISNULL(TTProducts_1.OrderDocument.DATE, DATETIME(1,1,1))
	|	END								AS OrderDate,
	|	CASE WHEN ISNULL(TTProducts_1.OrderDocument.Number, """") = """"
	|				THEN ISNULL(TTProducts_1.OrderingCaps.ApprovalDate, DATETIME(1,1,1))
	|			ELSE ISNULL(TTProducts_1.OrderDocument.ApprovalDate, DATETIME(1,1,1))
	|	END								AS ApprovalDate,
	|	TTProducts_1.ExceedingOrder				AS ExceedingOrder,
	|	SUM(TTProducts_1.PaymentAmount) 		AS PaymentAmount,
	|	SUM(TTProducts_1.AmountARAP) AS AmountARAP,
	|	0 									AS PackageDepositValue,
	|	0 									AS AmountARAPByPackage
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|GROUP BY
	|	CASE WHEN ISNULL(TTProducts_1.OrderDocument.Number, """") = """"
	|				THEN TTProducts_1.OrderingCaps
	|			ELSE TTProducts_1.OrderDocument
	|	END,
	|	CASE WHEN ISNULL(TTProducts_1.OrderDocument.Number, """") = """"
	|				THEN ISNULL(TTProducts_1.OrderingCaps.DATE, DATETIME(1,1,1))
	|			ELSE ISNULL(TTProducts_1.OrderDocument.DATE, DATETIME(1,1,1))
	|	END,
	|	CASE WHEN ISNULL(TTProducts_1.OrderDocument.Number, """") = """"
	|				THEN ISNULL(TTProducts_1.OrderingCaps.ApprovalDate, DATETIME(1,1,1))
	|			ELSE ISNULL(TTProducts_1.OrderDocument.ApprovalDate, DATETIME(1,1,1))
	|	END,
	|	TTProducts_1.ExceedingOrder";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.CustomerInvoiceServices.Services");
		Query.Text = StrReplace(Query.Text, "&OrderingCaps", "Goods.Ref.SalesOrder");
		Query.Text = StrReplace(Query.Text, "&ByOrders", "Goods.Ref.InvoiceByOrders");
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Goods.Ref = &Ref");
		Query.SetParameter("Ref",ObjectReference_);
	Else
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

#Region InfobaseUpdate

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.CustomerInvoiceServices";
	                                                         
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RequestHasSource,
										RedefiningParameterCalculation);
	Else	
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RedefiningParameterCalculation);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Posting

Procedure GetDocumentData(Query, DocumentRef)

	ListOfRequests = New Array;

	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableOfInventoryOwnerAttributes(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader =
	
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	ISNULL(DocumentData.Counterparty.RegistrationCountry.EEUMember, FALSE) AS CounterpartyMemberOfEAEU,
	|	CASE
	|		WHEN ISNULL(DocumentData.Counterparty.LegalEntityIndividual,
	|			VALUE(Enum.LegalEntityIndividual.EmptyRef)) = VALUE(Enum.LegalEntityIndividual.LegalEntityNonResident)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CounterpartyNotResident,
	|	DocumentData.Date AS Date,
	|	DocumentData.SalesOrder AS SalesOrder,
	|	DocumentData.Currency AS Currency,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	DocumentData.Department AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.Date AS ReferenceDate,
	|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.InvoiceByOrders AS InvoiceByOrders,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.Contract AS Contract,
	|	ISNULL(DocumentData.Contract.ConductARAPAccountingThroughEndCustomers, FALSE) AS
	|		ConductARAPAccountingThroughEndCustomers,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.Manager AS Manager,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.SalesOpportunity AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	ISNULL(DocumentData.Contract.AllowableAmountPayable, 0) AS AllowableAmountPayable,
	|	DocumentData.Number AS Number,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Author AS Author,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings
	|INTO DocumentDataHeader
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableOfInventoryOwnerAttributes(ListOfRequests)
	
	QueryTextTableInventoryKinds =
	
	"SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.Ref AS Ref,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	TableTypesOfStocks_.SalesOrder AS SalesOrder,
	|	TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|	TableTypesOfStocks_.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	TableTypesOfStocks_.SetAccountingDimension AS SetAccountingDimension,
	|	TableTypesOfStocks_.Price AS Price,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS AnalysisOfAccountingForProductsProducts,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS AnalysisOfAccountingProductsCharacteristics,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS InventoryLocationAttributeAnalysisBatch,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.TracedGoods AS
	|		InventoryLocationAttributeOfItemOfItemThatIsBeingTracked,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType AS
	|		InventoriedLocationAttributesItemTypeOfItem,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.UnitOfMeasure AS
	|		InventoryLocationAttributeOfItemOfUnitOfMeasurement,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS TypeOfInventoryOwnerAttributeOwnerOfItem,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryOwnerAttributeIsTypeOfInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency AS StockTypeCurrency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeInventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS InventoryOwnerAttributeSaleOfAnotherCompanySInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType AS InventoryOwnerAttributeInventoryOwnerAttributeTypeOfInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization AS InventoryOwnerAttributeInventoryOwnerAttributeOfOwnerCompany,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Currency AS OwnerSInventoryOwnersAttributeInventoryOwnersAttributesCurrency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Terms AS InventoryOwnerAttributeAgreement,
	|	TableTypesOfStocks_.ARAPObject.Organization AS ARAPObjectOfCompany,
	|	TableTypesOfStocks_.ARAPObject.Contract AS ARAPObjectContract,
	|	TableTypesOfStocks_.ARAPObject.LineOfBusiness AS ARAPObjectLineOfBusiness,
	|	TableTypesOfStocks_.ARAPObject.UUID AS ARAPObjectIsUniqueIdentifier,
	|	TableTypesOfStocks_.SetAccountingDimension.ProductsInSet AS AnalyticsOfSetAccountingSetItem,
	|	TableTypesOfStocks_.SetAccountingDimension.ItemVariantOfSet AS AnalyticsOfSetAccountingSetCharacteristics
	|INTO DocumentDataTableOfInventoryOwnerAttributes
	|FROM
	|	Document.CustomerInvoiceServices.InventoryKinds AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|";
	
	ListOfRequests.Add(QueryTextTableInventoryKinds);
	
EndProcedure

Function QueryTextTTInventoryOwnerAttributesOfWorks(Query, QueryTexts)
	
	RegisterName = "TTInventoryOwnerAttributesOfWorks";
	
	QueryText =
	
	"SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|INTO TTInventoryOwnerAttributesOfWorks
	|FROM
	|	Document.CustomerInvoiceServices.InventoryKinds AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref IN(&Ref)
	|
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributes
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates

	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates =
	// Sale
	"SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	Table.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.CustomerInvoiceServices.PaymentScheduleSteps AS Table
	|		LEFT JOIN Document.CustomerInvoiceServices AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|WHERE
	|	Table.Ref IN (&Ref)
	|
	// ApplyingPrepayment
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	Table.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.CustomerInvoiceServices.ARAPDetails AS Table
	|		LEFT JOIN Document.CustomerInvoiceServices AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|WHERE
	|	Table.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	ARAPObjects.Ref AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.CustomerInvoiceServices.ARAPDetails AS Table
	|		LEFT JOIN Document.CustomerInvoiceServices AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = Table.Ref
	|			AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	Table.Ref IN (&Ref)
	|
	|UNION ALL
	|
	// Direction of activity
	|SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	Table.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.CustomerInvoiceServices.Services AS Table
	|		LEFT JOIN Document.CustomerInvoiceServices AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|WHERE
	|	Table.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	(CASE
	|		WHEN DocumentDataHeader.InvoiceByOrders
	|			THEN Table.SalesOrder.ARAPObject
	|		WHEN DocumentDataHeader.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
	|			THEN Table.ARAPObject.Contract.ARAPObject
	|		ELSE Table.ARAPObject
	|	END) AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.CustomerInvoiceServices.Services AS Table
	|		LEFT JOIN Document.CustomerInvoiceServices AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|WHERE
	|	Table.Ref IN (&Ref)";
	
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);

	#EndRegion
	
	#Region Sale
	
	TextSale = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS ARAPObject,
		|	Table.PaymentDate                                                   	 AS PaymentDate,
		|	Table.OrderDocument															 AS SalesOrder_,
		|	Table.Ref.InvoiceByOrders                                   			 AS InvoiceForOrders,
		|	Table.AmountARAP	                                             AS AmountARAP,
		|	0                                                                 		 AS AmountARAPByPackage,
		|	Table.PaymentAmount								 					 AS Sum,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Date														 AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.SaleToCustomer)           AS BusinessOperation,
		|	Table.Ref.Date														 AS DateOfCourse,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.PaymentOption                                                    AS PaymentOption,
		|	Table.ExceedingOrder                                                      AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|FROM
		|	Document.CustomerInvoiceServices.PaymentScheduleSteps AS Table
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SaleToCustomer)           AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.PaymentDate                                                      AS PaymentDate,
		|	Table.PaymentOption                                                    AS PaymentOption,
		|	Table.AmountARAP                                              AS AmountDue,
		|		
		|	CASE WHEN Table.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|			THEN FALSE
		|		ELSE TRUE
		|	END                                                                    AS ExcludeDuringControl,
		|	Table.Ref.InvoiceByOrders                                              AS InvoiceForOrders,
		|	Table.OrderDocument                                                            AS SalesOrder_,
		|	Table.ExceedingOrder                                                      AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument,
		|	Table.ARAPObject                                                   AS ARAPObject
		|	
		|FROM
		|	Document.CustomerInvoiceServices.PaymentScheduleSteps AS Table
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	ARAPObjects.Ref                                                   AS CalculationObjectReceiver,
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	Document.CustomerInvoiceServices.ARAPDetails AS Table
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON ARAPObjects.Object = Table.Ref
		|				AND NOT ARAPObjects.DeletionMark
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	#Region Goods
	
	TextProducts_1 = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS ARAPObject,
		|	Table.Ref.Date                                                      AS DateOfShipment,
		|	0                                                                        AS IncreaseToBeSHIPPED,
		|	Table.AmountARAP                                              AS ReduceShipping,
		|	0                                                                        AS IncreaseShipping,
		|	Table.AmountARAP                                              AS ReduceToBESHIPPED,
		|	Table.AmountARAP                                              AS AmountARAP,
		|
		|	Table.SalesOrder                                                     AS SalesOrder_,
		|	0                                                                        AS DepositForPackage,
		|	CASE WHEN Table.RowCode = 0
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                                                    AS ExceedingOrder,
		|	Table.Ref.InvoiceByOrders                                              AS InvoiceForOrders,
		|	
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.SaleToCustomer)           AS BusinessOperation,
		|	Table.Ref.Currency                                                    AS DocumentCurrency
		|FROM
		|	Document.CustomerInvoiceServices.Services AS Table
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset, TextProducts_1);
	
EndProcedure

#EndRegion

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Department AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.CustomerInvoiceServices.Services AS TabPart
		|WHERE
		|	(NOT TabPart.Ref.InvoiceByOrders OR TabPart.RowCode = 0
		|			OR ISNULL(TabPart.SalesOrder.ThisIsOrderAsInvoice, FALSE))
		|		AND TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

#EndRegion

#EndIf
