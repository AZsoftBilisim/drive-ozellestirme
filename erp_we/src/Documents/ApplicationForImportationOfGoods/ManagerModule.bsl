#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String- list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("ImportAccounting");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ImportApplicationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ApplicationForImportationOfGoods") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableGoodsForRegistrationOfApplicationForImportFromEEUCountries(Query, QueryTexts, Registers);
		QueryTextTableGoodsForRegistrationOfImportDocuments(Query, QueryTexts, Registers);
		
		InitializeExchangeRates(Query);
		
		QueryTextTableExpenseBatchesToGoodsCost(Query, QueryTexts, Registers);
		QueryTextTableLotsVATForAllocation(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableVATInvoiced(Query, QueryTexts, Registers);
		QueryTextTableVATRegisterRecords(Query, QueryTexts, Registers);
		
		ImportApplicationLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region NonOperationalInterrogation

// We form a request to receive excise tax amounts for the document.
//
// Parameters:
//	DocumentRef - DocumentRef.ApplicationForImportationOfGoods - link to the document.
//
// Returns:
//	QueryResult - data on excise tax amounts.
//
Function GetExciseTaxData(DocumentRef) Export
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Period,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Department           AS Department
	|FROM
	|	Document.ApplicationForImportationOfGoods AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	QueryText =
	"SELECT
	|	CategoryTable.Products AS Products,
	|	CategoryTable.ConversionFactor_ AS ConversionFactor_,
	|	CategoryTable.ExcisableGoodsCategory AS ExcisableGoodsCategory
	|INTO TTCategoriesOfExcisableItems
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(
	|			&Period,
	|			Country = &RegistrationCountry
	|				AND Products IN
	|					(SELECT DISTINCT
	|						T.Products AS Products
	|					FROM
	|						Document.ApplicationForImportationOfGoods.Goods AS T
	|					WHERE
	|						T.Ref = &Ref)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods
	|
	|INDEX BY
	|	Products
	|;
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS ExcisePaymentBusinessUnit,
	|	DocumentGoods.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	DocumentGoods.Products AS Products,
	|	ExcisableGoodsCategories.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	VALUE(Enum.KindsOfTransactionsWithExcisableGoods.PurchaseEAEU) AS KindOfTransactionWithExcisableGoods,
	|	DocumentGoods.Count AS Count,
	|	CAST(DocumentGoods.Count * ExcisableGoodsCategories.ConversionFactor_ AS NUMBER(15, 3)) AS QuantityInExcisableCategoryUOM,
	|	CAST(&FactorOfConversionToCurrencyOfRegul * DocumentGoods.ExciseTaxAmount AS NUMBER(31, 2)) AS ExciseAmountInCurrencyLocal,
	|	CAST(&ConversionRateToManCurrency * DocumentGoods.ExciseTaxAmount AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|	DocumentGoods.RowID AS FinRecordID,
	|	&SettingUpBusinessOfOperation_AccrualOfExciseTaxes AS BusinessTransactionSetting
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS DocumentGoods
	|		INNER JOIN TTCategoriesOfExcisableItems AS ExcisableGoodsCategories
	|		ON DocumentGoods.Products = ExcisableGoodsCategories.Products
	|		LEFT JOIN Document.VendorInvoice AS VendorInvoice
	|			ON DocumentGoods.DocumentInflow = VendorInvoice.Ref
	|WHERE
	|	DocumentGoods.Ref = &Ref
	|	AND ExcisableGoodsCategories.ExcisableGoodsCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)
	|	AND (DocumentGoods.ExciseTaxAmount <> 0
	|		OR CAST(DocumentGoods.Count * ExcisableGoodsCategories.ConversionFactor_ AS NUMBER(15, 3)) <> 0)
	|";
	
	Query.Text = QueryText;
	
	InitializeExchangeRates(Query);
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	
	Query.SetParameter("RegistrationCountry",     RegistrationCountry);
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.ImportFromEAEU);
	Query.SetParameter("SettingUpBusinessOfOperation_AccrualOfExciseTaxes", Catalogs.BusinessTransactionsSettings.ExciseAccrual);
	
	QueryResult =  Query.Execute(); 
	
	
	Return QueryResult;
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
EndProcedure

// Adds a command to create a document "Statement on the import of goods from the EAEU".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ApplicationForImportationOfGoods) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ApplicationForImportationOfGoods.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ApplicationForImportationOfGoods);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseImportOfGoodsFromCustomsUnion";
	
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
//@skip-check module-empty-method
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Forms the submission of an application for the import of goods from the EAEU countries, taking into account the State of the event and the date of payment confirmation.
//
// Parameters:
//  Number - String - Import application number;
//  Date - Date - Date of application for importation;
//  Posted - Boolean - The State of the application for importation.
//  DateOfPaymentConfirmation - Date - Date of payment confirmation upon application from the Federal Tax Service.
//
// Returns:
//	String - Submission of an application for importation.
//
Function SubmissionOfApplicationForImportOfGoods(Number, Date, Posted, DateOfPaymentConfirmation) Export
	
	HeaderData_ = New Structure();
	HeaderData_.Insert("Number", Number);
	HeaderData_.Insert("Date", Date);
	
	SubstringsArray = New Array;
	SubstringsArray.Add(TMCommonUseClientServer.GenerateDocumentTitle(HeaderData_, NStr("vi = 'Giấy đề nghị nhập hàng';
																						|ru = 'Заявление о ввозе товаров';
																						|en = 'Application for goods import'; fa = 'Application for goods import';
																						|it = 'Dichiarazione di importazione merci';
																						|pl = 'Oświadczenie o imporcie towarów';
																						|tr = 'Malların ithalat beyannamesi'")));
	If ValueIsFilled(DateOfPaymentConfirmation) Then
		SubstringsArray.Add(StrTemplate(NStr("vi = '(được xác nhận %1 năm)';
											|ru = '(подтверждено %1 г.)';
											|en = '(confirmed %1)'; fa = '(confirmed %1)';
											|it = '(confermato %1)';
											|pl = '(potwierdzono %1 r.)';
											|tr = '(%1 onaylandı)'"), Format(DateOfPaymentConfirmation, "DLF=D")));
	EndIf;
	If Not Posted Then
		SubstringsArray.Add(NStr("vi = '(chưa kết chuyển)';
								|ru = '(не проведено)';
								|en = '(not posted)'; fa = '(not posted)';
								|it = '(non pubblicato)';
								|pl = '(nie zatwierdzono)';
								|tr = '(onaylanmadı)'"));
	EndIf;
	
	Presentation = StrConcat(SubstringsArray, " ");
	
	Return Presentation;
	
EndFunction

// The function finds applications for the import of goods of a given document-the basis.
//
// Parameters:
//	DocumentBasis - DocumentRef - The document for which it is necessary to find an application for the import of goods.
//	Organization - CatalogRef.Companies - The organization for which the application for the import of goods is formed.
//	Posted - Boolean - A sign that it is necessary to obtain the completed documents.
//
// Returns:
//	ValueTable - The table of found applications for the import of goods contains columns:
//		* Ref - DocumentRef.ApplicationForImportationOfGoods - link to the document application for the import of goods.
//		* Posted - Boolean - indicates whether the document is complete. 
//		* Number - String - the document number of the application for the import of goods.
//		* Date - Date - date of the application document for the import of goods.
//		* Organization - CatalogRef.Companies - organization of the application for the import of goods.
//		* Counterparty - CatalogRef.Counterparties - the counterparty of the application for the import of goods.
//		* DateOfPaymentConfirmation - Date - the date when the payment of the tax on this application was confirmed.
//		* DocumentBasis - DocumentRef.SigningOfLeaseContract, DocumentRef.SubcontractorReport2_5, DocumentRef.VendorInvoice, DocumentRef.VendorInvoiceServicesAndAssets - the document of receipt of goods.
//
Function ApplicationsForImportOfGoodsOnBasisOf(DocumentBasis, Organization = Undefined, Posted = True) Export
	
	Return ImportApplicationLocalization.ApplicationsForImportOfGoodsOnBasisOf(DocumentBasis, Organization, Posted);
	
EndFunction

// The function finds the original application for the import of goods of a given corrective application.
//
// Parameters:
//	CorrectiveApplicationForImportation - DocumentRef.ApplicationForImportationOfGoods - The document is an application for the import of goods.
//
// Returns:
// - Undefined - if the document is not found
// - DocumentRef.ApplicationForImportationOfGoods - The original application for the import of goods.
//
Function ApplicationsForImportOfGoodsForCorrection(CorrectiveApplicationForImportation) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	ApplicationForImportationOfGoodsGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ApplicationForImportationOfGoodsGoods.DocumentInflow AS DocumentInflow
	|INTO TTProducts_1
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS ApplicationForImportationOfGoodsGoods
	|		INNER JOIN Document.ApplicationForImportationOfGoods AS Operation
	|		ON ApplicationForImportationOfGoodsGoods.Ref = Operation.Ref
	|WHERE
	|	Operation.Ref = &Ref
	|	AND Operation.Patch
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT TOP 1
	|	Operation.Ref AS Ref,
	|	ApplicationForImportationOfGoodsGoods.DocumentInflow AS DocumentBasis
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS ApplicationForImportationOfGoodsGoods
	|		INNER JOIN Document.ApplicationForImportationOfGoods AS Operation
	|		ON ApplicationForImportationOfGoodsGoods.Ref = Operation.Ref
	|			AND (Operation.Posted)
	|			AND (Operation.Organization = &Organization
	|				OR &Organization = UNDEFINED)
	|			AND (NOT Operation.Patch)
	|		INNER JOIN TTProducts_1 AS TTProducts_1
	|		ON ApplicationForImportationOfGoodsGoods.ItemsLocationAttributes = TTProducts_1.ItemsLocationAttributes
	|			AND ApplicationForImportationOfGoodsGoods.DocumentInflow = TTProducts_1.DocumentInflow";
	
	Query.SetParameter("Ref", 		CorrectiveApplicationForImportation);
	Query.SetParameter("Organization",    Common.ObjectAttributeValue(CorrectiveApplicationForImportation, "Organization"));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	If Selection.Next() Then 
		Return Selection.Ref;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// The procedure generates a table of Balances of goods for processing applications for the import of goods according to the receipt document.
//
// Parameters:
//	DocumentInflow - DocumentRef.VendorInvoice, 
//						  Document link.Processer2_5 report,
//						  Document link.The conclusion of the lease agreement is a document of receipt, according to which
//						  the Balance of goods will be determined for processing applications for the import of goods.
//	FillingBasedOn - Boolean - indicates that the document was entered on the basis of the purchase of goods and services.
//	Execution_Period      - Date - Date of registration of the import application (used for registration of the application under lease Contracts).
//
// Returns:
//	ValueTable - Table of Balances of goods for processing applications.
//
Function TableOfBalancesOfGoodsForProcessingApplicationsForImportOfGoods(DocumentInflow, FillingBasedOn = False, Execution_Period = Undefined) Export
	
	SeparatePurchaseOperations = New Array;
	SeparatePurchaseOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	SeparatePurchaseOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	SeparatePurchaseOperations.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	SeparatePurchaseOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	SeparatePurchaseOperations.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	
	AttributesOfReceiptDocument =
		Common.ObjectAttributesValues(DocumentInflow, "Currency, Date, Organization");
	
	If TypeOf(DocumentInflow) = Type("DocumentRef.VendorInvoice")
		And SeparatePurchaseOperations.Find(Common.ObjectAttributeValue(DocumentInflow, "BusinessOperation")) <> Undefined Then
		
		UninvoicedReceiptDocumentIsUsed = True;
		
	Else
		UninvoicedReceiptDocumentIsUsed = False;
	EndIf;
	
	UseExcisableGoods = ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(
		AttributesOfReceiptDocument.Organization, AttributesOfReceiptDocument.Date);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("Period", AttributesOfReceiptDocument.Date);
	
	Organization = AttributesOfReceiptDocument.Organization;
	
	Query.SetParameter("DocumentInflow", DocumentInflow);
	Query.SetParameter("LeaseContracts", Undefined);
	If TypeOf(DocumentInflow) = Type("CatalogRef.LeaseContract") Then
		Query.SetParameter("DocumentInflow", Catalogs.LeaseContract.DocumentOfConclusionOfContractOfLease(DocumentInflow));
		Query.SetParameter("LeaseContracts", DocumentInflow);
	ElsIf TypeOf(DocumentInflow) = Type("DocumentRef.SigningOfLeaseContract") Then
		Query.SetParameter("DocumentInflow", DocumentInflow);
		Query.SetParameter("LeaseContracts", Common.ObjectAttributeValue(DocumentInflow, "Contract"));
	EndIf;
	USDollar = Catalogs.Currencies.FindByCode("840");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	ThisIsLeasing = TypeOf(DocumentInflow) = Type("CatalogRef.LeaseContract")
					Or TypeOf(DocumentInflow) = Type("DocumentRef.SigningOfLeaseContract");
	Query.SetParameter("Execution_Period", ?(Execution_Period = Undefined, Date(3999,12,31), Execution_Period));
	Query.SetParameter("AccountingRecordDate", AttributesOfReceiptDocument.Date);
	Query.SetParameter("USDollar", USDollar);
	Query.SetParameter("TransportKind", DetermineTypeOfTransportBasedOnStatistics(DocumentInflow));
	Query.SetParameter("FillingBasedOn", FillingBasedOn);
	Query.SetParameter("UninvoicedReceiptDocumentIsUsed", UninvoicedReceiptDocumentIsUsed);
	Query.SetParameter("BaseCurrency",LocalAccountingCurrency);
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	Query.SetParameter("TypeImportStatement",       Common.MetadataObjectID(FullObjectName()));
	Query.SetParameter("NewMechanics", ?(TypeOf(DocumentInflow) = Type("DocumentRef.VendorInvoice"), Common.ObjectAttributeValue(DocumentInflow, "NewWayToCreateApplicationForGoodsImportFromEAEU"), True));
	Query.SetParameter("FirmBet", Enums.TypesOfExcisableCategoryRates.FixedRate);
	
	SetPrivilegedMode(True);
	Query.Text = QueryTextGoodsForRegistrationOfApplicationForImportFromEEUCountries(Query, , UseExcisableGoods);
	Results = Query.ExecuteBatch();
	TableOfGoods = Results[Results.UBound() - 1].Unload();
	ResultOfExciseCalculation = Results[Results.UBound()];
	ExcisableGoodsAccounting.ProcessExciseTaxCalculationErrors(ResultOfExciseCalculation, AttributesOfReceiptDocument.Date);
	If ThisIsLeasing Then 
		TableOfGoods = AllocateAmountsForRentalServices(Query);
	EndIf;
	For Each RowOfProductsTable In TableOfGoods Do
		
		// We will calculate the tax base in rubles based on the invoice value as of the date of registration.
		If AttributesOfReceiptDocument.Currency <> LocalAccountingCurrency Then
			RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(AttributesOfReceiptDocument.Currency, RowOfProductsTable.AccountingRecordDate);
			If RateStructure.CourseDenominator = 0 Then
				RateStructure.CourseNumerator = 1;
				RateStructure.CourseDenominator = 1;
			EndIf;
			RowOfProductsTable.VATTaxBase = RowOfProductsTable.TaxInvoicedPrice * (RateStructure.CourseNumerator/RateStructure.CourseDenominator);
		Else
			RowOfProductsTable.VATTaxBase = RowOfProductsTable.TaxInvoicedPrice;
		EndIf;
		
		If UseExcisableGoods Then
			
			If RowOfProductsTable.ExcisableGoods And RowOfProductsTable.TaxBaseExcises = 0 Then
				RowOfProductsTable.TaxBaseExcises = RowOfProductsTable.VATTaxBase;
			EndIf;
			
			RowOfProductsTable.VATTaxBase =
				RowOfProductsTable.VATTaxBase + RowOfProductsTable.ExciseTaxAmount;
			
		EndIf;
		
		// We will calculate the amount of VAT based on the tax base and the rate.
		If RowOfProductsTable.VATTaxBase <> 0 Then
			RowOfProductsTable.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
				RowOfProductsTable.VATTaxBase,
				VATAccountingERPClientServer.ValueOfVATRate(RowOfProductsTable.VATRate),
				False);
		EndIf;
		
		// We will calculate the statistical value in dollars from the tax base in rubles on the date of registration.
		If USDollar <> Catalogs.Currencies.EmptyRef() Then
			RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(USDollar, RowOfProductsTable.AccountingRecordDate, LocalAccountingCurrency);
			RowOfProductsTable.StatValueUSDollars = RowOfProductsTable.VATTaxBase * (RateStructure.CourseDenominator/RateStructure.CourseNumerator);
		EndIf;
		
	EndDo;
	
	Return TableOfGoods;
	
EndFunction

// The procedure determines the type of transport most commonly used in the documents "Application for import of goods" 
// in the context of the organization and the counterparty of the receipt document.
//
// Parameters:
//	DocumentInflow - DocumentRef.VendorInvoice
//						  Document link.Purchasingservicesother assets
//						  Document link.Processer2_5 report
//						  Document link.The conclusion of the lease agreement.
//
// Returns:
//	String - representation of the mode of transport
//
Function DetermineTypeOfTransportBasedOnStatistics(DocumentInflow) Export
	
	AttributesOfReceiptDocument = Common.ObjectAttributesValues(DocumentInflow, "Counterparty, Organization");
	
	Query = New Query;
	Query.Text = "
		|SELECT ALLOWED TOP 3
		|	ApplicationForImportationOfGoodsGoods.TransportKind,
		|	ApplicationForImportationOfGoodsGoods.Ref.Date AS Period,
		|	1 AS Priority
		|INTO TT_Documents
		|FROM
		|	Document.ApplicationForImportationOfGoods.Goods AS ApplicationForImportationOfGoodsGoods
		|WHERE
		|	ApplicationForImportationOfGoodsGoods.Ref.Counterparty = &Counterparty
		|	AND ApplicationForImportationOfGoodsGoods.Ref.Organization = &Organization
		|
		|UNION ALL
		|
		|SELECT TOP 3
		|	ApplicationForImportationOfGoodsGoods.TransportKind,
		|	ApplicationForImportationOfGoodsGoods.Ref.Date,
		|	2
		|FROM
		|	Document.ApplicationForImportationOfGoods.Goods AS ApplicationForImportationOfGoodsGoods
		|WHERE
		|	ApplicationForImportationOfGoodsGoods.Ref.Organization = &Organization
		|
		|UNION ALL
		|
		|SELECT TOP 3
		|	ApplicationForImportationOfGoodsGoods.TransportKind,
		|	ApplicationForImportationOfGoodsGoods.Ref.Date,
		|	3
		|FROM
		|	Document.ApplicationForImportationOfGoods.Goods AS ApplicationForImportationOfGoodsGoods
		|
		|UNION ALL
		|
		|SELECT
		|	&RoadTransport,
		|	NULL,
		|	4
		|FROM
		|	Document.ApplicationForImportationOfGoods.Goods AS ApplicationForImportationOfGoodsGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	Subquery.TransportKind AS TransportKind
		|FROM
		|	(SELECT
		|		TT_Documents.TransportKind AS TransportKind,
		|		SUM(1) AS UsageFrequency,
		|		TT_Documents.Priority AS Priority
		|	FROM
		|		TT_Documents AS TT_Documents
		|	
		|	GROUP BY
		|		TT_Documents.TransportKind,
		|		TT_Documents.Priority) AS Subquery
		|
		|ORDER BY
		|	Subquery.Priority,
		|	Subquery.UsageFrequency DESC";
		
	Query.SetParameter("Counterparty", AttributesOfReceiptDocument.Counterparty);
	Query.SetParameter("Organization", AttributesOfReceiptDocument.Organization);
	Query.SetParameter("RoadTransport", 
			NStr("vi = '30 - Vận tải đường bộ, ngoại trừ các phương tiện được chỉ định theo mã 31, 32';
				|ru = '30 - Автодорожный транспорт, за исключением транспортных средств, указанных под кодами 31, 32';
				|en = '30 - Road transport, except for vehicles specified by codes 31, 32'; fa = '30 - Road transport, except for vehicles specified by codes 31, 32';
				|it = '30 - Trasporto stradale, ad esclusione dei mezzi di trasporto indicati nei codici 31, 32';
				|pl = '30 - Transport drogowy, z wyjątkiem pojazdów, podanych pod kodami 31, 32';
				|tr = '30 - Karayolu taşımacılığı, kod 31, 32 kapsamındaki araçlar hariç'"));
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.TransportKind;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	ImportApplicationLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Create printed forms of objects.
//
// Parameters:
//  ObjectsArray  - Array of DocumentRef.ApplicationForImportationOfGoods   - references to the objects that you want to print.
//  PrintParameters - Structure - additional print settings.
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList of DocumentRef.ApplicationForImportationOfGoods - value - the object reference;
//                                            view - name of the area where the object was output (output parameter).
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	ImportApplicationLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

//Returns the number of invoices to be processed.
//
// Parameters:
//	Parameters - Structure:
//	* CompanyArray - Array of CatalogRef.Companies - Array of organizations.
//	* EndOfPeriod - Date - upper limit on the date of the purchase document.
//	* NoPeriodLimit - Boolean - do not limit the date of the purchase document
//	* ByCompanies - Boolean - return an array of companies that have invoices for processing
//
// Returns:
//	Number - number of invoices to be processed;
//	Array from the Reference link.Companies.
//
Function ThereAreInvoicesForRegistration(Parameters) Export
		
	Query = New Query;
	Query.SetParameter("MetadataIdentifierImportStatement", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));

	If Parameters.Property("ByCompanies") Then
		QueryTextBasis1 = TextOfRequestGroundsForProcessingApplicationsForImportOfGoods(True);
		QueryText =
		"SELECT DISTINCT ALLOWED
		|	GoodsForRegistrationOfImportDocumentsBalance.DocumentInflow AS DocumentInflow,
		|	GoodsForRegistrationOfImportDocumentsBalance.Organization AS Organization
		|INTO TTOrdersForProcessingImportApplications
		|FROM
		|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(, &CompanyFilterCriteria
		|	AND ImportDocumentType = &MetadataIdentifierImportStatement) AS GoodsForRegistrationOfImportDocumentsBalance
		|WHERE
		|	GoodsForRegistrationOfImportDocumentsBalance.CountBalance > 0
		|
		|INDEX BY
		|	DocumentInflow
		|;
		|///////////////////////////////////////////////
		|SELECT DISTINCT
		|	OrderData_3.Organization AS Organization
		|FROM
		|	#QueryTextBasis1 AS OrderData_3";
		
		QueryText = StrReplace(QueryText, "#QueryTextBasis1", "(" + QueryTextBasis1 + ")");
	Else
		QueryTextBasis1 = TextOfRequestGroundsForProcessingApplicationsForImportOfGoods();
		
		QueryText =
		"SELECT DISTINCT ALLOWED
		|	GoodsForRegistrationOfImportDocumentsBalance.DocumentInflow AS DocumentInflow
		|INTO TTOrdersForProcessingImportApplications
		|FROM
		|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(, &CompanyFilterCriteria
		|	AND ImportDocumentType = &MetadataIdentifierImportStatement) AS GoodsForRegistrationOfImportDocumentsBalance
		|WHERE
		|	GoodsForRegistrationOfImportDocumentsBalance.CountBalance > 0
		|
		|INDEX BY
		|	DocumentInflow
		|;
		|///////////////////////////////////////////////
		|SELECT
		|	SUM(OrderData_3.NumberOfDocumentsForRegistration) AS NumberOfDocumentsForRegistration
		|FROM
		|	#QueryTextBasis1 AS OrderData_3";
		
		QueryText = StrReplace(QueryText, "#QueryTextBasis1", "(" + QueryTextBasis1 + ")");
	EndIf;
	
	If ValueIsFilled(Parameters.CompanyArray) Then
		CompanyFilterCriteria = "Organization IN (&CompanyArray)";
		QueryText = StrReplace(QueryText,"&CompanyFilterCriteria", CompanyFilterCriteria);
		Query.SetParameter("CompanyArray", Parameters.CompanyArray);
	Else
		QueryText = StrReplace(QueryText,"&CompanyFilterCriteria", "TRUE");
	EndIf;
	
	If Parameters.Property("NoPeriodLimit") Then
		QueryText = StrReplace(QueryText,"&PeriodSelectionCriteria", "TRUE");
		Query.SetParameter("EndOfPeriod", CurrentSessionDate());
	Else
		PeriodSelectionCriteria = "DocumentReferenceOrder.Date <= &EndOfPeriod";
		QueryText = StrReplace(QueryText,"&PeriodSelectionCriteria", PeriodSelectionCriteria);
		Query.SetParameter("EndOfPeriod", Parameters.EndOfPeriod);
	EndIf;
	Query.Text = QueryText;
	
	If Parameters.Property("ByCompanies") Then
		Return Query.Execute().Unload().UnloadColumn("Organization");
	EndIf;
	Selection = Query.Execute().Select();
	If Selection.Next() And Not Selection.NumberOfDocumentsForRegistration = NULL Then
		Return Selection.NumberOfDocumentsForRegistration;
	Else
		Return 0;
	EndIf;
	
EndFunction

//Returns the types of documents for which it is required to issue applications for the import of goods.
//
// Returns:
//	Array of String - array of strings (document types-bases) 
//
Function TypesOfDocumentsGroundsForRegistration() Export
	
	TypesArray = New Array;
	TypesArray.Add("VendorInvoice"); 
	TypesArray.Add("SubcontractorReport2_5");
	TypesArray.Add("SigningOfLeaseContract");
	Return TypesArray;
	
EndFunction

// Unloads the document and returns the properties of the upload file.
//
// Parameters:
// UUID - UUID- Unique identifier of the form of the application being uploaded.
//	Object		- DocumentRef.ApplicationForImportationOfGoods - Link to the document being uploaded.
//	IsCheckOnly - Boolean - the upload flag (= False) / verification of the upload option (= True).
//
// Returns:
//	- Undefined - if the upload file could not be generated.
//	- Array of Structure - structures with data of upload files, contains:
//		* UploadFileAddress - String - the address of the binary data of the upload file in the temporary storage (except for the document verification mode only).
//		* UploadFileName - String - the short name of the upload file (with the extension).
//
Function UploadApplicationForImportOfGoods(UUID, Object, IsCheckOnly = False) Export
	
	Return ImportApplicationLocalization.UploadApplicationForImportOfGoods(UUID, Object, IsCheckOnly);
	
EndFunction

// Unloads the document and returns the properties of the upload file.
//
// Parameters:
//	UUID - UUID- Unique identifier of the form of the application being uploaded.
//	Object		- DocumentRef.ApplicationForImportationOfGoods - Link to the document being uploaded.
//	IsCheckOnly - Boolean -  the upload flag (= False) / verification of the upload option (= True).
//
// Returns:
//	- Undefined - if the upload file could not be generated.
//	- Array of Structure - structures with data of upload files, contains:
//		* UploadFileAddress - String - the address of the binary data of the upload file in the temporary storage (except for the document verification mode only).
//		* UploadFileName - String - the short name of the upload file (with the extension).
//
Function UploadTrackingOfMovementOfGoods(UUID, Object, IsCheckOnly = False) Export
	
	Return ImportApplicationLocalization.UploadTrackingOfMovementOfGoods(UUID, Object, IsCheckOnly);
	
EndFunction

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	QueryText = "";
	ImportApplicationLocalization.GenerateReflectionTextInLocalAccounting(QueryText);
	Return QueryText;
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//		String - Query text
Function RequestTextTTReflectedInLocalAccounting() Export
	
	QueryText = "";
	ImportApplicationLocalization.GenerateRequestTextTTForReflectionInLocalAccounting(QueryText);
	Return QueryText;
	
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
	|	AND ValueAllowed(Counterparty.Partner)";

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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
//@skip-check module-empty-method
Procedure OnDefineObjectVersioningSettings(Settings) Export
	
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

Function FullObjectName()
	Return "Document.ApplicationForImportationOfGoods";
EndFunction

#Region Posting

// Returns the matching container for additional RegisteredRecorded data
//
// Parameters:
//  RegisterName - String - the name of the register in the configuration.
//
// Returns:
//  Map of KeyAndValue - True if you want to generate the specified table
//@skip-check function-return-types
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	
	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	ApplicationForImportationOfGoods.Ref,
	|	ApplicationForImportationOfGoods.Date,
	|	ApplicationForImportationOfGoods.Organization,
	|	ApplicationForImportationOfGoods.Counterparty,
	|	ApplicationForImportationOfGoods.Currency,
	|	ApplicationForImportationOfGoods.DocumentAmount,
	|	ApplicationForImportationOfGoods.ManualAdjustmentOfTaxInvoiceRegister,
	|	ISNULL(CatCounterparties.Partner, VALUE(Catalog.Partners.EmptyRef))    AS Vendor,
	|	ApplicationForImportationOfGoods.Number                    AS Number,
	|	ApplicationForImportationOfGoods.Contract                  AS Contract,
	|	ApplicationForImportationOfGoods.EmployeeResponsible            AS EmployeeResponsible,
	|	ApplicationForImportationOfGoods.Department            AS Department,
	|	ApplicationForImportationOfGoods.Comment              AS Comment,
	|	ApplicationForImportationOfGoods.Patch              AS Patch,
	|	ApplicationForImportationOfGoods.ReversedDocument     AS ReversedDocument,
	|	ApplicationForImportationOfGoods.CorrectedDocument     AS CorrectedDocument,
	|	ApplicationForImportationOfGoods.DeletionMark          AS DeletionMark,
	|	ApplicationForImportationOfGoods.Posted                 AS Posted,
	|	ApplicationForImportationOfGoods.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	ApplicationForImportationOfGoods.Organization.RegistrationCountry AS RegistrationCountry,
	|	ApplicationForImportationOfGoods.CorrectedDocument.Date AS AdjustmentPeriod_
	|FROM
	|	Document.ApplicationForImportationOfGoods AS ApplicationForImportationOfGoods
	|		LEFT JOIN Catalog.Counterparties AS CatCounterparties
	|		ON ApplicationForImportationOfGoods.Counterparty = CatCounterparties.Ref
	|WHERE
	|	ApplicationForImportationOfGoods.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("Period",                     Attributes.Date);
	Query.SetParameter("TransactionKindCode", 			"19"); // "19 Import of goods from the Eurasian Economic Union"
	
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	Query.SetParameter("NumberForPrinting",       	       ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number,True));
	Query.SetParameter("MetadataIdentifier",       Common.MetadataObjectID(FullObjectName()));
	Query.SetParameter("BusinessOperation",         Enums.BusinessTransactions.ImportFromEAEU);
	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.ImportFromEAEU);
	Query.SetParameter("BusinessTransactionSetting_IncludeVATInCostExpenses", Catalogs.BusinessTransactionsSettings.IncludeVATInCostExpenses);
	Query.SetParameter("SettingUpBusinessOfOperation_AccrualOfExciseTaxes", Catalogs.BusinessTransactionsSettings.ExciseAccrual);
	
	Query.SetParameter("VATAmount",                      DocumentRef.Goods.Total("VATAmount"));
	Query.SetParameter("VATTaxBase",              DocumentRef.Goods.Total("VATTaxBase"));
	Query.SetParameter("ManualAdjustmentOfTaxInvoiceRegister",  Attributes.ManualAdjustmentOfTaxInvoiceRegister);
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = NStr("vi = 'Theo hợp đồng ""%1""';
							|ru = 'По договору ""%1""';
							|en = 'Under the ""%1"" contract'; fa = 'Under the ""%1"" contract';
							|it = 'In base al contratto ""%1""';
							|pl = 'Wg kontraktu ""%1""';
							|tr = '""%1"" Sözleşmesi kapsamında'"); // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	Query.SetParameter("UseExcisableGoods",
		ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Attributes.Organization, Attributes.Date));
	If Not GetFunctionalOption("UseMultiCountryAccounting") Then
		Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.MainCountry());
	EndIf;
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	GoodsTable.ItemsLocationAttributes.Products AS Products,
	|	GoodsTable.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	&EmptyAssignment AS Purpose,
	|	GoodsTable.ItemsLocationAttributes.Series AS Series,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation AS StorageLocation
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS GoodsTable
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON GoodsTable.ItemsLocationAttributes.Products = Dimension.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = Dimension.Series
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND GoodsTable.ItemsLocationAttributes.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments";
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
EndProcedure

Procedure InitializeExchangeRates(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization),
		Constants.ManagementAccountingCurrency.Get(),
		Query.Parameters.Period,
		Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Function QueryTextTableGoodsForRegistrationOfApplicationForImportFromEEUCountries(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsForRegistrationOfApplicationForImportFromEEUCountries";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	ApplicationForImportationOfGoodsGoods.LineNumber           AS LineNumber,
	|	&Period                                            AS Period,
	|	VALUE(AccumulationRecordType.Expense)             AS RecordType,
	|	ApplicationForImportationOfGoodsGoods.DocumentInflow   AS DocumentInflow,
	|	ApplicationForImportationOfGoodsGoods.Products          AS Products,
	|	ApplicationForImportationOfGoodsGoods.Characteristic        AS Characteristic,
	|	ApplicationForImportationOfGoodsGoods.Series                 AS Series,
	|	ApplicationForImportationOfGoodsGoods.Warehouse                 AS Warehouse,
	|	ApplicationForImportationOfGoodsGoods.Count            AS ToRegister,
	|	ApplicationForImportationOfGoodsGoods.TaxInvoicedPrice    AS TaxInvoicedPrice
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS ApplicationForImportationOfGoodsGoods
	|		INNER JOIN Document.VendorInvoice AS VendorInvoice
	|		ON ApplicationForImportationOfGoodsGoods.DocumentInflow = VendorInvoice.Ref
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON ApplicationForImportationOfGoodsGoods.Products = CatProducts.Ref
	|WHERE
	|	ApplicationForImportationOfGoodsGoods.Ref = &Ref
	|	AND NOT VendorInvoice.NewWayToCreateApplicationForGoodsImportFromEAEU
	|	AND ApplicationForImportationOfGoodsGoods.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsForRegistrationOfImportDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsForRegistrationOfImportDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
		
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Vendor AS Vendor,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.DocumentInflow AS DocumentInflow,
	|	&MetadataIdentifier AS ImportDocumentType,
	|	GoodsTable.Count AS Count,
	|	0 AS QuantityByGBRN,
	|	GoodsTable.TaxInvoicedPrice AS Sum,
	|	GoodsTable.CDNumber AS CCDNumber,
	|	FALSE AS Primary,
	|	GoodsTable.RowID AS RowID
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS GoodsTable
	|	LEFT JOIN Document.VendorInvoice AS AcquisitionDocumentIsOldMechanic
	|		ON GoodsTable.DocumentInflow = AcquisitionDocumentIsOldMechanic.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND ISNULL(AcquisitionDocumentIsOldMechanic.NewWayToCreateApplicationForGoodsImportFromEAEU, TRUE)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Organization,
	|	&Vendor,
	|	NULL,
	|	NULL,
	|	GoodsTable.DocumentInflow,
	|	&MetadataIdentifier,
	|	0,
	|	0,
	|	SUM(GoodsTable.TaxInvoicedPrice),
	|	NULL,
	|	FALSE,
	|	MAX(GoodsTable.RowID)
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS GoodsTable
	|		INNER JOIN Document.SigningOfLeaseContract AS DocumentOfConclusionOfContractOfLease
	|		ON GoodsTable.DocumentInflow = DocumentOfConclusionOfContractOfLease.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|GROUP BY
	|	GoodsTable.DocumentInflow
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""Goods"" 											AS TabularSectionName,
	|	DocumentTable.LineNumber 						AS LineNumber,
	|	UNDEFINED										AS Vendor,
	|	DocumentData.Counterparty							AS Counterparty,
	|	DocumentTable.VATRate 							AS VATRate,
	|	DocumentTable.PurchaseForActivity				AS VATTaxation,
	|	VALUE(Enum.AssetKinds.CustomsUnion)	AS AssetTaxClass,
	|	0													AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS DocumentTable
	|	INNER JOIN Document.ApplicationForImportationOfGoods AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""GoodsReceipts"" 								AS TabularSectionName,
	|	DocumentTable.LineNumber 						AS LineNumber,
	|	ReceiptDocumentData.Partner					AS Vendor,
	|	ReceiptDocumentData.Counterparty				AS Counterparty,
	|	MIN(ReceiptDocumentTable.VATRate)		AS VATRate,
	|	ReceiptDocumentData.PurchaseForActivity	AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	0													AS RowCode
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS DocumentTable
	|	INNER JOIN Document.ApplicationForImportationOfGoods AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|	INNER JOIN Document.VendorInvoice.Goods AS ReceiptDocumentTable
	|		ON DocumentTable.DocumentInflow = ReceiptDocumentTable.Ref
	|		AND DocumentTable.Products = ReceiptDocumentTable.Products
	|		AND DocumentTable.Characteristic = ReceiptDocumentTable.Characteristic
	|	INNER JOIN Document.VendorInvoice AS ReceiptDocumentData
	|		ON DocumentTable.DocumentInflow = ReceiptDocumentData.Ref
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DocumentTable.Products
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|GROUP BY
	|	DocumentTable.LineNumber,
	|	ReceiptDocumentData.Partner,
	|	ReceiptDocumentData.Counterparty,
	|	ReceiptDocumentData.PurchaseForActivity,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|
	|HAVING
	|	COUNT(DISTINCT ReceiptDocumentTable.VATRate) = 1
	|
	|UNION ALL
	|
	|SELECT
	|	""GoodsReceipts"" 								AS TabularSectionName,
	|	DocumentTable.LineNumber 						AS LineNumber,
	|	ReceiptDocumentData.Partner					AS Vendor,
	|	ReceiptDocumentData.Counterparty				AS Counterparty,
	|	MIN(ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
	|		VALUE(Catalog.VATRates.EmptyRef))))	AS VATRate,
	|	ReceiptDocumentData.PurchaseForActivity	AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	0													AS RowCode
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS DocumentTable
	|	INNER JOIN Document.ApplicationForImportationOfGoods AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|	INNER JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS ReceiptDocumentTable
	|		ON DocumentTable.DocumentInflow = ReceiptDocumentTable.Ref
	|		AND DocumentTable.Products = ReceiptDocumentTable.Products
	|		AND DocumentTable.Characteristic = ReceiptDocumentTable.Characteristic
	|	INNER JOIN Document.SubcontractorReport2_5 AS ReceiptDocumentData
	|		ON DocumentTable.DocumentInflow = ReceiptDocumentData.Ref
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DocumentTable.Products
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ProductsVATRates.SliceLast(&Date,
	|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|	ON
	|		DocumentTable.Products = ProductsVATRates.Products
	|	
	|	LEFT JOIN
	|		InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
	|	ON
	|		TRUE
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|GROUP BY
	|	DocumentTable.LineNumber,
	|	ReceiptDocumentData.Partner,
	|	ReceiptDocumentData.Counterparty,
	|	ReceiptDocumentData.PurchaseForActivity,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|
	|HAVING
	|	COUNT(DISTINCT ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
	|		VALUE(Catalog.VATRates.EmptyRef)))) = 1
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableExpenseBatchesToGoodsCost(Query, QueryTexts, Registers)
	RegisterName = "ExpenseBatchesToGoodsCost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGoodsImportApplications", QueryTexts) Then
		QueryTextTTGoodsImportApplications(Query, QueryTexts)
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date							AS Period,
	|	VALUE(AccumulationRecordType.Receipt) 			AS RecordType,
	|	DocumentData.Organization 					AS Organization,
	|	DocumentGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	DocumentGoods.DocumentInflow				AS DocumentInflow,
	|	DocumentGoods.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	DocumentData.Ref 							AS ExpenseReceiptDocument,
	|	UNDEFINED 									AS ExpenseItem,
	|
	|	SUM(DocumentGoods.Count)				AS Count,
	|	SUM(DocumentGoods.Cost)                AS Cost,
	|	0										 		AS CostExcludingVAT,
	|	0										 		AS LocalCost,
	|	SUM(CASE 
	|			WHEN TableOfBatchAccountingAnalysts.VATTaxation = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|				THEN 0 
	|			ELSE DocumentGoods.VATAmount
	|		END)										AS VATLocal,
	|	DocumentGoods.Department					AS ExpensesBusinessUnit,
	|	0												AS PermanentDifference,
	|	0												AS CostTD
	|
	|FROM
	|	Document.ApplicationForImportationOfGoods AS DocumentData
	|	INNER JOIN TTGoodsImportApplications AS DocumentGoods
	|	ON DocumentGoods.Ref = DocumentData.Ref
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= DocumentGoods.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BatchAccountingVersion21
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	DocumentData.Organization,
	|	DocumentGoods.DocumentInflow,
	|	DocumentGoods.ItemsLocationAttributes,
	|	DocumentGoods.InventoryOwnerAttribute,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes,
	|	DocumentGoods.Department
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableLotsVATForAllocation(Query, QueryTexts, Registers)
	
	RegisterName = "LotsVATForAllocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGoodsImportApplications", QueryTexts) Then
		QueryTextTTGoodsImportApplications(Query, QueryTexts)
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentGoods.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	DocumentData.Counterparty AS Vendor,
	|	&Ref AS ExpenseReceiptDocument,
	|	TableOfBatchAccountingAnalysts.VATTaxation AS VATActivityType,
	|	VALUE(Enum.AssetKinds.CustomsUnion) AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes.VATRate AS VATRate,
	|
	|	0                        AS LocalCost,
	|	DocumentGoods.VATAmount AS VATLocal,
	|	DocumentGoods.VATManag   AS VATManag,
	|	
	|	DocumentGoods.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ApplicationForImportationOfGoods AS DocumentData
	|	INNER JOIN TTGoodsImportApplications AS DocumentGoods
	|	ON DocumentGoods.Ref = DocumentData.Ref
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= DocumentGoods.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|
	|WHERE
	|	DocumentData.Ref = &Ref 
	|	AND DocumentGoods.VATAmount <> 0
	|	AND TableOfBatchAccountingAnalysts.VATTaxation = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	Query.SetParameter("VAT_ImportedGoods", Catalogs.TaxContributionKinds.GetLinkOfPredefinedElement("VAT_ImportedGoods"));
	
	QueryText = 
	"SELECT
	|	DocumentData.Date                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                               AS RecordType,
	|	DocumentData.Organization                                          AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)               AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)            AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes)        AS AssetRef,
	|	&VAT_ImportedGoods                                                  AS Dimension,
	|	CAST(DocumentData.DocumentAmount 
	|					* &ConversionRateToManCurrency AS NUMBER(31,2))  AS Sum
	|FROM
	|	Document.ApplicationForImportationOfGoods AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGoodsImportApplications", QueryTexts) Then
		QueryTextTTGoodsImportApplications(Query, QueryTexts)
	EndIf;
	
	QueryText =
	"SELECT
	|	Operation.Date                                                    AS Period,
	|	VALUE(Enum.BusinessTransactions.ImportFromEAEU) AS BusinessOperation,
	|	Operation.Organization                                             AS Organization,
	|	PurchaseOfGoodsServicesGoods.Department                     AS Department,
	|	VendorInvoice.Manager                                AS Manager,
	|	DocumentGoods.ItemsLocationAttributes                       AS ItemsLocationAttributes,
	|	DocumentGoods.Warehouse                                            AS Warehouse,
	|	DocumentGoods.InventoryType                                       AS InventoryType,
	|	DocumentGoods.InventoryOwnerAttribute                                       AS InventoryOwnerAttribute,
	|	VendorInvoice.Partner                                 AS Partner,
	|	VendorInvoice.Counterparty                              AS Counterparty,
	|	VendorInvoice.Terms                              AS Terms,
	|	VendorInvoice.Contract                                 AS Contract,
	|	UNDEFINED AS OrderDocument,
	|
	|	DocumentGoods.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	VendorInvoice.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	0                                                          AS Count,
	|	DocumentGoods.Cost                                  AS Sum,
	|	0                                                          AS AmountExcludingVAT,
	|	DocumentGoods.VATAmount                                   AS SumCompl,
	|	0                                                          AS LocalAmountExcludingVAT,
	|	0                                                          AS DiscountAmount,
	|	DocumentGoods.Cost                                  AS Cost,
	|	0                                                          AS CostExcludingVAT,
	|	DocumentGoods.VATAmount                                   AS LocalCost,
	|	0                                                          AS AddExpensesForGoods,
	|	0                                                          AS AdditionalExpensesExcludingVAT,
	|
	|	&LocalAccountingCurrency                            AS DocumentCurrency,
	|	DocumentGoods.VATAmount                                   AS AmountInDocumentCurrency,
	|	0                                                          AS AmountExcludingVATInDocumentCurrency,
	|	&LocalAccountingCurrency                            AS ARAPCurrency,
	|	DocumentGoods.VATAmount                                   AS AmountInARAPCurrency,
	|	0                                                          AS AmountExcludingVATInARAPCurrency,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN DocumentGoods.InventoryOwnerAttribute
	|		ELSE DocumentGoods.Products
	|	END                                                      AS SourceOfProductFinancialAccountingGroup,
	|	PurchaseOfGoodsServicesGoods.ARAPObject              AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTGoodsImportApplications AS DocumentGoods
	|		INNER JOIN Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|			INNER JOIN Document.VendorInvoice AS VendorInvoice
	|			ON PurchaseOfGoodsServicesGoods.Ref = VendorInvoice.Ref
	|		ON DocumentGoods.DocumentInflow = PurchaseOfGoodsServicesGoods.Ref
	|		AND CASE 
	|			WHEN PurchaseOfGoodsServicesGoods.RowID <> """" THEN
	|				DocumentGoods.RowID = PurchaseOfGoodsServicesGoods.RowID
	|			ELSE
	|				DocumentGoods.ItemsLocationAttributes = PurchaseOfGoodsServicesGoods.ItemsLocationAttributes
	|			END
	|		INNER JOIN Document.ApplicationForImportationOfGoods AS Operation
	|		ON DocumentGoods.Ref = Operation.Ref
	|WHERE
	|	DocumentGoods.Ref = &Ref
	|	AND DocumentGoods.Products <> VALUE(Catalog.Products.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBases", QueryTexts) Then
		QueryTextTTBases(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	&BusinessOperation   AS BusinessOperation,
	|	UNDEFINED             AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	CASE
	|		WHEN DocumentData.NumberOfActivities = 1
	|			THEN DocumentData.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                    AS LineOfBusiness,
	|	CASE
	|		WHEN DocumentData.NumberOfStorageLocations = 1
	|			THEN DocumentData.StorageLocation
	|		ELSE UNDEFINED
	|	END                    AS StorageLocation,
	|	&Department           AS Department,
	|	&EmployeeResponsible           AS EmployeeResponsible,
	|	&Comment             AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&Period                  AS SourceDocumentDate,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	&Patch             AS ReverseTransactionCorrection,
	|	&ReversedDocument    AS ReversedDocument,
	|	&CorrectedDocument    AS CorrectedDocument,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTTGoodsImportApplications(Query, QueryTexts)
	
	RegisterName = "TTGoodsImportApplications";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	ImportApplicationLocalization.QueryTextTTGoodsImportApplications(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		
		QueryText = 
		"SELECT
		|	Rows.LineNumber AS LineNumber,
		|	Rows.Ref AS Ref,
		|	Rows.VATRate AS VATRate,
		|	Rows.VATAmount AS VATAmount,
		|	CASE
		|		WHEN &CompanyManagementAccounting
		|			THEN Rows.VATAmount * &ConversionRateToManCurrency
		|		ELSE 0
		|	END AS VATManag,
		|	&ConversionRateToManCurrency * Rows.VATAmount AS Cost,
		|	Rows.Count AS Count,
		|	CAST(&ConversionRateToManCurrency * Rows.ExciseTaxAmount AS NUMBER(31, 2)) AS AddExpensesForGoods,
		|	Rows.ExciseTaxAmount AS ExciseTaxAmount,	
		|	Rows.RowID AS RowID,
		|	Rows.VATTaxBase AS VATTaxBase,
		|	Rows.DocumentInflow AS DocumentInflow,
		|	Rows.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Rows.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Rows.Department AS Department,
		|	Rows.Warehouse AS Warehouse,
		|	Rows.Products AS Products,
		|	ISNULL(InventoryKinds.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) AS InventoryType,
		|	ISNULL(LinesOfBusiness.Ref, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness
		|INTO TTGoodsImportApplications
		|FROM
		|	Document.ApplicationForImportationOfGoods.Goods AS Rows
		|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON Rows.InventoryOwnerAttribute = InventoryKinds.Ref
		|		LEFT JOIN Catalog.Assignments AS Assignments
		|			LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
		|			ON Assignments.LineOfBusiness = LinesOfBusiness.Ref
		|		ON Rows.ItemsLocationAttributes = Assignments.Ref
		|WHERE
		|	Rows.Ref = &Ref
		|
		|INDEX BY
		|	LineNumber"; 
		
		QueryTexts.Add(QueryText, RegisterName);
		
	EndIf;
	
EndProcedure

Procedure QueryTextTTVATOnApplicationForImportation(Query, QueryTexts)
	
	RegisterName = "TTVATOnApplicationForImportation";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGoodsImportApplications", QueryTexts) Then
		QueryTextTTGoodsImportApplications(Query, QueryTexts)
	EndIf;
	
	VATAccountingERPInternal.SetParameterTypesOfTaxationVATReceipts(Query);
	Query.SetParameter("StartDateOfVATAccountingByLineOfBusiness", VATAccountingERP.AccountingSettings().StartDateOfVATAccountingByLineOfBusiness);
	
	QueryText = 
	"SELECT
	|	&Ref AS Recorder,
	|	Operation.Date AS Period,
	|	Operation.Organization  AS Organization,
	|	&Ref AS TaxInvoice,
	|	Operation.Counterparty  AS Vendor,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass AS AssetTaxClass,
	|	Rows.VATRate  AS VATRate,
	|	TableOfBatchAccountingAnalysts.VATTaxation AS VATActivityType,
	|	CASE WHEN Operation.Date >= &StartDateOfVATAccountingByLineOfBusiness THEN
	|		Rows.LineOfBusiness
	|	ELSE
	|		UNDEFINED
	|	END AS LineOfBusiness,
	|	0 AS AmountExcludingVAT,
	|	Rows.VATAmount AS VAT,
	|	Rows.VATManag AS VATManag,
	|	Rows.RowID AS RowID,
	|	Rows.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATIsAccruedByTaxAgent) AS BusinessTransactionSetting
	|INTO TTVATOnApplicationForImportation
	|FROM
	|	Document.ApplicationForImportationOfGoods AS Operation
	|	
	|	INNER JOIN
	|		TTGoodsImportApplications AS Rows
	|	ON
	|		Rows.Ref = Operation.Ref
	|		AND Rows.VATTaxBase <> 0
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= Rows.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|	
	|WHERE
	|	Operation.Ref = &Ref
	|	AND Operation.Organization <> VALUE(Catalog.Companies.ManagementCompany)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableVATInvoiced(Query, QueryTexts, Registers)
	
	RegisterName = "VATInvoiced";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTVATOnApplicationForImportation", QueryTexts) Then
		QueryTextTTVATOnApplicationForImportation(Query, QueryTexts)
	EndIf;
	
	QueryText = "
	|
	|SELECT
	|	VATOnApplicationForImport.Recorder AS Recorder,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	VATOnApplicationForImport.Period AS Period,
	|	VATOnApplicationForImport.Organization AS Organization,
	|	VATOnApplicationForImport.TaxInvoice AS TaxInvoice,
	|	VATOnApplicationForImport.Vendor AS Vendor,
	|	VATOnApplicationForImport.AssetTaxClass AS AssetTaxClass,
	|	VATOnApplicationForImport.VATRate AS VATRate,
	|	CASE 
	|		WHEN VATOnApplicationForImport.VATActivityType =
	|			VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			AND NOT &GenerateVATChargedWhenIncludingInCost
	|			OR VATOnApplicationForImport.VATActivityType =
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|		THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	ELSE
	|		VATOnApplicationForImport.VATActivityType
	|	END AS VATActivityType,
	|	UNDEFINED AS CorrectedTaxInvoice,
	|	UNDEFINED AS SaleExport,
	|	VATOnApplicationForImport.LineOfBusiness AS LineOfBusiness,
	|	VATOnApplicationForImport.AmountExcludingVAT AS AmountExcludingVAT,
	|	VATOnApplicationForImport.VAT AS VAT,
	|	VATOnApplicationForImport.VATManag AS VATManag,
	|	UNDEFINED AS Event,
	|	UNDEFINED AS CorVATActivityTypes,
	|	FALSE AS PeriodEndTransaction,
	|	"""" AS RowID,
	|	
	|	VATOnApplicationForImport.FinRecordID AS FinRecordID,
	|	VATOnApplicationForImport.BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	TTVATOnApplicationForImportation AS VATOnApplicationForImport
	|
	|UNION ALL
	|
	|SELECT
	|	VATOnApplicationForImport.Recorder AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	VATOnApplicationForImport.Period AS Period,
	|	VATOnApplicationForImport.Organization AS Organization,
	|	VATOnApplicationForImport.TaxInvoice AS TaxInvoice,
	|	VATOnApplicationForImport.Vendor AS Vendor,
	|	VATOnApplicationForImport.AssetTaxClass AS AssetTaxClass,
	|	VATOnApplicationForImport.VATRate AS VATRate,
	|	CASE 
	|		WHEN VATOnApplicationForImport.VATActivityType =
	|			VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			AND NOT &GenerateVATChargedWhenIncludingInCost
	|			OR VATOnApplicationForImport.VATActivityType =
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|		THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	ELSE
	|		VATOnApplicationForImport.VATActivityType
	|	END AS VATActivityType,
	|	UNDEFINED AS CorrectedTaxInvoice,
	|	UNDEFINED AS SaleExport,
	|	VATOnApplicationForImport.LineOfBusiness AS LineOfBusiness,
	|	VATOnApplicationForImport.AmountExcludingVAT AS AmountExcludingVAT,
	|	VATOnApplicationForImport.VAT AS VAT,
	|	VATOnApplicationForImport.VATManag AS VATManag,
	|	VALUE(Enum.EventsChargedVAT.IncludeVATInCostExpenses) AS Event,
	|	UNDEFINED AS CorVATActivityTypes,
	|	FALSE AS PeriodEndTransaction,
	|	VATOnApplicationForImport.RowID AS RowID,
	|	
	|	VATOnApplicationForImport.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting_IncludeVATInCostExpenses AS BusinessTransactionSetting
	|	
	|FROM
	|	TTVATOnApplicationForImportation AS VATOnApplicationForImport
	|WHERE
	|	VATOnApplicationForImport.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableVATRegisterRecords(Query, QueryTexts, Registers)
	
	RegisterName = "VATRegisterRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTVATOnApplicationForImportation", QueryTexts) Then
		QueryTextTTVATOnApplicationForImportation(Query, QueryTexts)
	EndIf;
	
	QueryText = 
	"SELECT
	|	VATOnApplicationForImport.Recorder AS Recorder,
	|	VATOnApplicationForImport.Period AS Period,
	|	VATOnApplicationForImport.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Outgoing) AS EntryType,
	|	VATOnApplicationForImport.Vendor AS Counterparty,
	|	VATOnApplicationForImport.TaxInvoice AS TaxInvoice,
	|	VATOnApplicationForImport.VATRate AS VATRate,
	|	VATOnApplicationForImport.AssetTaxClass AS AssetTaxClass,
	|	VATOnApplicationForImport.AmountExcludingVAT AS AmountExcludingVAT,
	|	VATOnApplicationForImport.VAT AS VAT,
	|	VATOnApplicationForImport.VATManag AS VATManag,
	|	FALSE AS PeriodEndTransaction,
	|	VATOnApplicationForImport.FinRecordID AS FinRecordID,
	|	VATOnApplicationForImport.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	TTVATOnApplicationForImportation AS VATOnApplicationForImport";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextGoodsForRegistrationOfApplicationForImportFromEEUCountries(Query, FillingBasedOn = False, UseExcisableGoods = False)
	
	PartsOfQueryText = New Array;
	
	QueryText =
	"SELECT
	|	VendorInvoice.Ref 					AS Ref,
	|	VendorInvoice.Counterparty 				AS Counterparty,
	|	VendorInvoice.Contract 					AS Contract,
	|	VendorInvoice.Currency 					AS Currency,
	|	VendorInvoice.PurchaseForActivity 	AS PurchaseForActivity,
	|	VendorInvoice.IncomingDocumentNumber 	AS IncomingDocumentNumber,
	|	VendorInvoice.IncomingDocumentDate 	AS IncomingDocumentDate
	|INTO TT_Operation
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|WHERE
	|	VendorInvoice.Ref = &DocumentInflow
	|
	|UNION ALL
	|
	|SELECT
	|	SubcontractorReport2_5.Ref,
	|	SubcontractorReport2_5.Counterparty,
	|	SubcontractorReport2_5.Contract,
	|	SubcontractorReport2_5.Currency,
	|	SubcontractorReport2_5.PurchaseForActivity,
	|	SubcontractorReport2_5.IncomingDocumentNumber,
	|	SubcontractorReport2_5.IncomingDocumentDate
	|FROM
	|	Document.SubcontractorReport2_5 AS SubcontractorReport2_5
	|WHERE
	|	SubcontractorReport2_5.Ref = &DocumentInflow
	|
	|UNION ALL
	|
	|SELECT
	|	SigningOfLeaseContract.Ref,
	|	SigningOfLeaseContract.Counterparty,
	|	SigningOfLeaseContract.Contract,
	|	SigningOfLeaseContract.Currency,
	|	SigningOfLeaseContract.PurchaseForActivity,
	|	SigningOfLeaseContract.IncomingDocumentNumber,
	|	SigningOfLeaseContract.IncomingDocumentDate
	|FROM
	|	Document.SigningOfLeaseContract AS SigningOfLeaseContract
	|WHERE
	|	SigningOfLeaseContract.Ref = &DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	PurchaseAdjustment.Ref AS Ref
	|INTO LastAdjustmentData
	|FROM
	|	Document.PurchaseAdjustment AS PurchaseAdjustment
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|	ON
	|		PurchaseAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|		AND RegisterOfDocumentsStornoCorrection.Posted
	|		AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|WHERE
	|	PurchaseAdjustment.Posted
	|	AND PurchaseAdjustment.DocumentBasis = &DocumentInflow
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|
	|ORDER BY
	|	PurchaseAdjustment.PointInTime DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AcquisitionGoods.Ref AS DocumentInflow,
	|	MIN(AcquisitionGoods.LineNumber) AS LineNumber,
	|	AcquisitionGoods.Products AS Products,
	|	AcquisitionGoods.PartnerProducts AS PartnerProducts,
	|	AcquisitionGoods.Characteristic AS Characteristic,
	|	AcquisitionGoods.Series AS Series,
	|	AcquisitionGoods.Warehouse AS Warehouse,
	|	ISNULL(AcquisitionGoods.Purpose.VATActivityType,
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)) AS VATActivityType,
	|	VendorInvoice.PurchaseForActivity AS PurchaseForActivity,
	|	AcquisitionGoods.CCDNumber.OriginCountry AS OriginCountry,
	|	AcquisitionGoods.CCDNumber AS CDNumber,
	|	AcquisitionGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AcquisitionGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &NewMechanics
	|			THEN """"
	|		ELSE AcquisitionGoods.RowID
	|	END AS RowID,
	|	AcquisitionGoods.Count AS QuantityForDistribution,
	|	AcquisitionGoods.Sum AS AmountToDistribution,
	|	"""" AS Content
	|INTO TT_ProductsWithoutGrouping
	|FROM
	|	Document.VendorInvoice.Goods AS AcquisitionGoods
	|		INNER JOIN Document.VendorInvoice AS VendorInvoice
	|		ON AcquisitionGoods.Ref = VendorInvoice.Ref
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON TRUE
	|WHERE
	|	AcquisitionGoods.Ref = &DocumentInflow
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|	AND LastAdjustmentData.Ref IS NULL 
	|
	|GROUP BY
	|	AcquisitionGoods.Ref,
	|	AcquisitionGoods.Products,
	|	AcquisitionGoods.PartnerProducts,
	|	AcquisitionGoods.Characteristic,
	|	AcquisitionGoods.Series,
	|	AcquisitionGoods.Warehouse,
	|	ISNULL(AcquisitionGoods.Purpose.VATActivityType,
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)),
	|	VendorInvoice.PurchaseForActivity,
	|	AcquisitionGoods.CCDNumber,
	|	AcquisitionGoods.ItemsLocationAttributes,
	|	AcquisitionGoods.InventoryOwnerAttribute,
	|	CASE
	|		WHEN &NewMechanics
	|			THEN """"
	|		ELSE AcquisitionGoods.RowID
	|	END,
	|	AcquisitionGoods.Count,
	|	AcquisitionGoods.Sum
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorInvoiceInventoryKinds.Ref,
	|	MIN(PurchaseOfGoodsServicesGoods.LineNumber),
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes.Products,
	|	PurchaseOfGoodsServicesGoods.PartnerProducts,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes.Characteristic,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes.Series,
	|	CASE
	|		WHEN
	|			VendorInvoiceInventoryKinds.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN VendorInvoiceInventoryKinds.ItemsLocationAttributes.StorageLocation
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END,
	|	ISNULL(VendorInvoiceInventoryKinds.ItemsLocationAttributes.Purpose.VATActivityType,
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)),
	|	VendorInvoice.PurchaseForActivity,
	|	VendorInvoiceInventoryKinds.CCDNumber.OriginCountry,
	|	VendorInvoiceInventoryKinds.CCDNumber,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes,
	|	VendorInvoiceInventoryKinds.InventoryOwnerAttribute,
	|	CASE
	|		WHEN &NewMechanics
	|			THEN """"
	|		ELSE VendorInvoiceInventoryKinds.RowID
	|	END,
	|	PurchaseOfGoodsServicesGoods.Count,
	|	PurchaseOfGoodsServicesGoods.Sum,
	|	""""
	|FROM
	|	Document.VendorInvoice.InventoryKinds AS VendorInvoiceInventoryKinds
	|
	|	INNER JOIN 
	|		Document.VendorInvoice AS VendorInvoice
	|	ON 
	|		VendorInvoiceInventoryKinds.Ref = VendorInvoice.Ref
	|
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON TRUE
	|
	|	LEFT JOIN 
	|		Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|	ON 
	|		VendorInvoiceInventoryKinds.Ref = PurchaseOfGoodsServicesGoods.Ref
	|		AND VendorInvoiceInventoryKinds.ItemsLocationAttributes.Products = PurchaseOfGoodsServicesGoods.ItemsLocationAttributes.Products
	|		AND VendorInvoiceInventoryKinds.ItemsLocationAttributes.Characteristic = PurchaseOfGoodsServicesGoods.ItemsLocationAttributes.Characteristic
	|WHERE
	|	&UninvoicedReceiptDocumentIsUsed
	|	AND VendorInvoiceInventoryKinds.Ref = &DocumentInflow
	|	AND LastAdjustmentData.Ref IS NULL
	|
	|GROUP BY
	|	VendorInvoiceInventoryKinds.Ref,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes.Products,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes.Characteristic,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes.Series,
	|	PurchaseOfGoodsServicesGoods.PartnerProducts,
	|	PurchaseOfGoodsServicesGoods.Count,
	|	PurchaseOfGoodsServicesGoods.Sum,
	|	CASE
	|		WHEN VendorInvoiceInventoryKinds.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN VendorInvoiceInventoryKinds.ItemsLocationAttributes.StorageLocation
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END,
	|	ISNULL(VendorInvoiceInventoryKinds.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)),
	|	VendorInvoice.PurchaseForActivity,
	|	VendorInvoiceInventoryKinds.CCDNumber,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes,
	|	VendorInvoiceInventoryKinds.InventoryOwnerAttribute,
	|	CASE
	|		WHEN &NewMechanics
	|			THEN """"
	|		ELSE VendorInvoiceInventoryKinds.RowID
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	PurchaseAdjustment.DocumentBasis,
	|	MIN(AdjustmentOfAcquisitionOfGoods.LineNumber),
	|	AdjustmentOfAcquisitionOfGoods.Products,
	|	AdjustmentOfAcquisitionOfGoods.PartnerProducts,
	|	AdjustmentOfAcquisitionOfGoods.Characteristic,
	|	AdjustmentOfAcquisitionOfGoods.Series,
	|	AdjustmentOfAcquisitionOfGoods.Warehouse,
	|	ISNULL(AdjustmentOfAcquisitionOfGoods.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)),
	|	PurchaseAdjustment.PurchaseForActivity,
	|	AdjustmentOfAcquisitionOfGoods.CCDNumber.OriginCountry,
	|	AdjustmentOfAcquisitionOfGoods.CCDNumber,
	|	UNDEFINED,
	|	UNDEFINED,
	|	"""",
	|	AdjustmentOfAcquisitionOfGoods.Count,
	|	AdjustmentOfAcquisitionOfGoods.Sum,
	|	""""
	|
	|FROM
	|	Document.PurchaseAdjustment.Goods AS AdjustmentOfAcquisitionOfGoods
	|
	|	INNER JOIN 
	|		Document.PurchaseAdjustment AS PurchaseAdjustment
	|	ON 
	|		AdjustmentOfAcquisitionOfGoods.Ref = PurchaseAdjustment.Ref
	|
	|	INNER JOIN 
	|		LastAdjustmentData AS LastAdjustmentData
	|	ON 
	|		AdjustmentOfAcquisitionOfGoods.Ref = LastAdjustmentData.Ref
	|
	|WHERE
	|	NOT &UninvoicedReceiptDocumentIsUsed
	|
	|GROUP BY
	|	PurchaseAdjustment.DocumentBasis,
	|	AdjustmentOfAcquisitionOfGoods.Products,
	|	AdjustmentOfAcquisitionOfGoods.PartnerProducts,
	|	AdjustmentOfAcquisitionOfGoods.Characteristic,
	|	AdjustmentOfAcquisitionOfGoods.Series,
	|	AdjustmentOfAcquisitionOfGoods.Warehouse,
	|	AdjustmentOfAcquisitionOfGoods.Purpose.VATActivityType,
	|	PurchaseAdjustment.PurchaseForActivity,
	|	AdjustmentOfAcquisitionOfGoods.CCDNumber,
	|	AdjustmentOfAcquisitionOfGoods.Count,
	|	AdjustmentOfAcquisitionOfGoods.Sum
	|
	|UNION ALL
	|
	|SELECT
	|	SubcontractorReport2_5.Ref,
	|	MIN(ReportOfProcessorTypesOfStocks.LineNumber),
	|	ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.Products,
	|	NULL,
	|	ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.Characteristic,
	|	ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.Series,
	|	CASE
	|		WHEN
	|			ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.StorageLocation
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END,
	|	ISNULL(ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.Purpose.VATActivityType,
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)),
	|	SubcontractorReport2_5.PurchaseForActivity,
	|	ReportOfProcessorTypesOfStocks.CCDNumber.OriginCountry,
	|	ReportOfProcessorTypesOfStocks.CCDNumber,
	|	UNDEFINED,
	|	UNDEFINED,
	|	"""",
	|	ReportOfProcessorTypesOfStocks.Count,
	|	ReportOfProcessorTypesOfStocks.Sum,
	|	""""
	|FROM
	|	Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS ReportOfProcessorTypesOfStocks
	|		INNER JOIN Document.SubcontractorReport2_5 AS SubcontractorReport2_5
	|		ON ReportOfProcessorTypesOfStocks.Ref = SubcontractorReport2_5.Ref
	|WHERE
	|	SubcontractorReport2_5.Ref = &DocumentInflow
	|
	|GROUP BY
	|	SubcontractorReport2_5.Ref,
	|	ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.Products,
	|	ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.Characteristic,
	|	ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.Series,
	|	CASE
	|		WHEN
	|			ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.StorageLocation
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END,
	|	ISNULL(ReportOfProcessorTypesOfStocks.ItemsLocationAttributes.Purpose.VATActivityType,
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)),
	|	SubcontractorReport2_5.PurchaseForActivity,
	|	ReportOfProcessorTypesOfStocks.CCDNumber,
	|	ReportOfProcessorTypesOfStocks.Count,
	|	ReportOfProcessorTypesOfStocks.Sum
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	SigningOfLeaseContract.Ref,
	|	SigningOfLeaseContractFA.LineNumber,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef),
	|	SigningOfLeaseContract.PurchaseForActivity,
	|	SigningOfLeaseContract.Counterparty.RegistrationCountry,
	|	UNDEFINED,
	|	UNDEFINED,
	|	NULL,
	|	"""",
	|	1,
	|	1,
	|	PRESENTATION(SigningOfLeaseContractFA.FixedAsset)
	|FROM
	|	Document.SigningOfLeaseContract.FA AS SigningOfLeaseContractFA
	|		INNER JOIN Document.SigningOfLeaseContract AS SigningOfLeaseContract
	|		ON SigningOfLeaseContractFA.Ref = SigningOfLeaseContract.Ref
	|WHERE
	|	SigningOfLeaseContract.Ref = &DocumentInflow
	|	AND SigningOfLeaseContract.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsWithoutGrouping.DocumentInflow AS DocumentInflow,
	|	MIN(ProductsWithoutGrouping.LineNumber) AS LineNumber,
	|	ProductsWithoutGrouping.Products AS Products,
	|	ProductsWithoutGrouping.PartnerProducts AS PartnerProducts,
	|	ProductsWithoutGrouping.Characteristic AS Characteristic,
	|	ProductsWithoutGrouping.Series AS Series,
	|	ProductsWithoutGrouping.Warehouse AS Warehouse,
	|	ProductsWithoutGrouping.VATActivityType AS VATActivityType,
	|	ProductsWithoutGrouping.PurchaseForActivity AS PurchaseForActivity,
	|	ProductsWithoutGrouping.OriginCountry AS OriginCountry,
	|	ProductsWithoutGrouping.CDNumber AS CDNumber,
	|	MAX(ProductsWithoutGrouping.ItemsLocationAttributes) AS ItemsLocationAttributes,
	|	MAX(ProductsWithoutGrouping.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
	|	ProductsWithoutGrouping.RowID AS RowID,
	|	SUM(ProductsWithoutGrouping.QuantityForDistribution) AS QuantityForDistribution,
	|	SUM(ProductsWithoutGrouping.AmountToDistribution) AS AmountToDistribution,
	|	ProductsWithoutGrouping.Content AS Content
	|INTO TT_Goods
	|FROM
	|	TT_ProductsWithoutGrouping AS ProductsWithoutGrouping
	|
	|GROUP BY
	|	ProductsWithoutGrouping.DocumentInflow,
	|	ProductsWithoutGrouping.Products,
	|	ProductsWithoutGrouping.PartnerProducts,
	|	ProductsWithoutGrouping.Characteristic,
	|	ProductsWithoutGrouping.Series,
	|	ProductsWithoutGrouping.Warehouse,
	|	ProductsWithoutGrouping.VATActivityType,
	|	ProductsWithoutGrouping.PurchaseForActivity,
	|	ProductsWithoutGrouping.OriginCountry,
	|	ProductsWithoutGrouping.CDNumber,
	|	ProductsWithoutGrouping.InventoryOwnerAttribute,
	|	ProductsWithoutGrouping.RowID,
	|	ProductsWithoutGrouping.Content
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForRegistration.DocumentInflow AS DocumentInflow,
	|	GoodsForRegistration.Products AS Products,
	|	GoodsForRegistration.Characteristic AS Characteristic,
	|	GoodsForRegistration.Series AS Series,
	|	GoodsForRegistration.Warehouse AS Warehouse,
	|	GoodsForRegistration.ToRegisterBalance AS ToRegister
	|INTO BalanceForDesignOfOldMechanics
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfApplicationForImportFromEEUCountries.Balance(, DocumentInflow = &DocumentInflow) AS
	|		GoodsForRegistration
	|WHERE
	|	GoodsForRegistration.ToRegisterBalance > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForRegistration.DocumentInflow AS DocumentInflow,
	|	GoodsForRegistration.Products AS Products,
	|	GoodsForRegistration.Characteristic AS Characteristic,
	|	GoodsForRegistration.Series AS Series,
	|	GoodsForRegistration.Warehouse AS Warehouse,
	|	GoodsForRegistration.TaxInvoicedPrice AS TaxInvoicedPrice,
	|	GoodsForRegistration.ToRegister AS ToRegister,
	|	GoodsForRegistration.RowID AS RowID
	|INTO ProductsForRegistrationOldMechanics
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfApplicationForImportFromEEUCountries AS GoodsForRegistration
	|		LEFT JOIN BalanceForDesignOfOldMechanics AS BalanceForDesignOfOldMechanics
	|		ON GoodsForRegistration.DocumentInflow = BalanceForDesignOfOldMechanics.DocumentInflow
	|		AND GoodsForRegistration.Products = BalanceForDesignOfOldMechanics.Products
	|		AND GoodsForRegistration.Characteristic = BalanceForDesignOfOldMechanics.Characteristic
	|		AND GoodsForRegistration.Series = BalanceForDesignOfOldMechanics.Series
	|		AND GoodsForRegistration.Warehouse = BalanceForDesignOfOldMechanics.Warehouse
	|WHERE
	|	GoodsForRegistration.Active
	|	AND GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND GoodsForRegistration.DocumentInflow = &DocumentInflow
	|	AND (NOT &FillingBasedOn
	|		OR NOT BalanceForDesignOfOldMechanics.DocumentInflow IS NULL)
	|	AND NOT &NewMechanics
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForRegistration.DocumentInflow AS DocumentInflow,
	|	GoodsForRegistration.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsForRegistration.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsForRegistration.CountBalance AS Count,
	|	GoodsForRegistration.SumBalance AS Sum,
	|	"""" AS RowID
	|INTO BalancesForRegistrationNewMechanics
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(
	|			&Execution_Period, 
	|			DocumentInflow = &DocumentInflow
	|			AND ImportDocumentType = &TypeImportStatement) AS GoodsForRegistration
	|WHERE
	|	(GoodsForRegistration.CountBalance > 0
	|		OR GoodsForRegistration.SumBalance > 0)
	|	AND &NewMechanics
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForRegistration.DocumentInflow AS DocumentInflow,
	|	GoodsForRegistration.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DimensionKeyOfProductAccounting.Products AS Products,
	|	DimensionKeyOfProductAccounting.Characteristic AS Characteristic,
	|	DimensionKeyOfProductAccounting.Series AS Series,
	|	DimensionKeyOfProductAccounting.StorageLocation AS Warehouse,
	|	GoodsForRegistration.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsForRegistration.CCDNumber AS CCDNumber,
	|	SUM(CASE
	|		WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN GoodsForRegistration.Count 
	|		ELSE
	|			-GoodsForRegistration.Count
	|	END) AS Count,
	|	SUM(CASE
	|		WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN GoodsForRegistration.Sum 
	|		ELSE
	|			-GoodsForRegistration.Sum
	|	END) AS Sum,
	|	"""" AS RowID
	|INTO ProductsForRegistrationNewMechanics
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments AS GoodsForRegistration
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeyOfProductAccounting
	|		ON GoodsForRegistration.ItemsLocationAttributes = DimensionKeyOfProductAccounting.Ref
	|		LEFT JOIN BalancesForRegistrationNewMechanics AS BalancesForRegistrationNewMechanics
	|		ON GoodsForRegistration.ItemsLocationAttributes = BalancesForRegistrationNewMechanics.ItemsLocationAttributes
	|			AND GoodsForRegistration.InventoryOwnerAttribute = BalancesForRegistrationNewMechanics.InventoryOwnerAttribute
	|			AND GoodsForRegistration.DocumentInflow = BalancesForRegistrationNewMechanics.DocumentInflow
	|		LEFT JOIN Document.ReversingEntry AS DocumentsStorno
	|		ON GoodsForRegistration.Recorder = DocumentsStorno.Ref
	|			AND VALUETYPE(DocumentsStorno.ReversedDocument) = TYPE(Document.ApplicationForImportationOfGoods)
	|			AND DocumentsStorno.Posted
	|WHERE
	|	GoodsForRegistration.Active
	|	AND GoodsForRegistration.DocumentInflow = &DocumentInflow
	|	AND GoodsForRegistration.ImportDocumentType = &TypeImportStatement
	|	AND VALUETYPE(GoodsForRegistration.Recorder) <> TYPE(Document.ApplicationForImportationOfGoods)
	|	AND DocumentsStorno.Ref IS NULL
	|	AND (NOT &FillingBasedOn
	|		OR NOT BalancesForRegistrationNewMechanics.DocumentInflow IS NULL)
	|	AND &NewMechanics
	|
	|GROUP BY
	|	GoodsForRegistration.DocumentInflow,
	|	GoodsForRegistration.ItemsLocationAttributes,
	|	DimensionKeyOfProductAccounting.Products,
	|	DimensionKeyOfProductAccounting.Characteristic,
	|	DimensionKeyOfProductAccounting.Series,
	|	DimensionKeyOfProductAccounting.StorageLocation,
	|	GoodsForRegistration.InventoryOwnerAttribute,
	|	GoodsForRegistration.CCDNumber
	|
	|HAVING
	|	SUM(CASE
	|		WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN GoodsForRegistration.Count 
	|		ELSE
	|			-GoodsForRegistration.Count
	|		END) > 0 
	|	OR SUM(CASE
	|		WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN GoodsForRegistration.Sum 
	|		ELSE
	|			-GoodsForRegistration.Sum
	|		END) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsForRegistration.DocumentInflow,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	CASE
	|		WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN GoodsForRegistration.Count 
	|		ELSE
	|			-GoodsForRegistration.Count
	|	END AS Count,
	|	CASE
	|		WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN GoodsForRegistration.Sum 
	|		ELSE
	|			-GoodsForRegistration.Sum
	|	END AS Sum,
	|	""""
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments AS GoodsForRegistration
	|		INNER JOIN Document.SigningOfLeaseContract AS SigningOfLeaseContract
	|		ON GoodsForRegistration.DocumentInflow = SigningOfLeaseContract.Ref
	|		LEFT JOIN BalancesForRegistrationNewMechanics AS BalancesForRegistrationNewMechanics
	|		ON GoodsForRegistration.ItemsLocationAttributes = BalancesForRegistrationNewMechanics.ItemsLocationAttributes
	|			AND GoodsForRegistration.InventoryOwnerAttribute = BalancesForRegistrationNewMechanics.InventoryOwnerAttribute
	|			AND GoodsForRegistration.DocumentInflow = BalancesForRegistrationNewMechanics.DocumentInflow
	|		LEFT JOIN Document.ReversingEntry AS DocumentsStorno
	|		ON GoodsForRegistration.Recorder = DocumentsStorno.Ref
	|			AND VALUETYPE(DocumentsStorno.ReversedDocument) = TYPE(Document.ApplicationForImportationOfGoods)
	|			AND DocumentsStorno.Posted
	|WHERE
	|	GoodsForRegistration.Active
	|	AND GoodsForRegistration.Period = &Execution_Period
	|	AND GoodsForRegistration.DocumentInflow = &DocumentInflow
	|	AND GoodsForRegistration.ImportDocumentType = &TypeImportStatement
	|	AND VALUETYPE(GoodsForRegistration.Recorder) <> TYPE(Document.ApplicationForImportationOfGoods)
	|	AND DocumentsStorno.Ref IS NULL
	|	AND (NOT &FillingBasedOn
	|			OR NOT BalancesForRegistrationNewMechanics.DocumentInflow IS NULL)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForRegistration.DocumentInflow AS DocumentInflow,
	|	GoodsForRegistration.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsForRegistration.Products AS Products,
	|	GoodsForRegistration.Characteristic AS Characteristic,
	|	GoodsForRegistration.Series AS Series,
	|	GoodsForRegistration.Warehouse AS Warehouse,
	|	GoodsForRegistration.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsForRegistration.CCDNumber AS CCDNumber,
	|	SUM(GoodsForRegistration.Count) AS Count,
	|	SUM(GoodsForRegistration.Sum) AS Sum,
	|	GoodsForRegistration.RowID AS RowID
	|INTO GoodsForRegistrationArePreliminary
	|FROM
	|	ProductsForRegistrationNewMechanics AS GoodsForRegistration
	|
	|GROUP BY
	|	GoodsForRegistration.DocumentInflow,
	|	GoodsForRegistration.ItemsLocationAttributes,
	|	GoodsForRegistration.Products,
	|	GoodsForRegistration.Characteristic,
	|	GoodsForRegistration.Series,
	|	GoodsForRegistration.Warehouse,
	|	GoodsForRegistration.InventoryOwnerAttribute,
	|	GoodsForRegistration.CCDNumber,
	|	GoodsForRegistration.RowID
	|
	|UNION ALL
	|
	|SELECT
	|	ProductsForRegistrationOldMechanics.DocumentInflow,
	|	PurchaseOfGoodsServicesGoods.ItemsLocationAttributes,
	|	ProductsForRegistrationOldMechanics.Products,
	|	ProductsForRegistrationOldMechanics.Characteristic,
	|	ProductsForRegistrationOldMechanics.Series,
	|	ProductsForRegistrationOldMechanics.Warehouse,
	|	PurchaseOfGoodsServicesGoods.InventoryOwnerAttribute,
	|	UNDEFINED,
	|	ProductsForRegistrationOldMechanics.ToRegister,
	|	ProductsForRegistrationOldMechanics.TaxInvoicedPrice,
	|	ProductsForRegistrationOldMechanics.RowID
	|FROM
	|	ProductsForRegistrationOldMechanics AS ProductsForRegistrationOldMechanics
	|		INNER JOIN TT_Goods AS PurchaseOfGoodsServicesGoods
	|		ON ProductsForRegistrationOldMechanics.DocumentInflow = PurchaseOfGoodsServicesGoods.DocumentInflow
	|		AND ProductsForRegistrationOldMechanics.Products = PurchaseOfGoodsServicesGoods.Products
	|		AND ProductsForRegistrationOldMechanics.Characteristic = PurchaseOfGoodsServicesGoods.Characteristic
	|		AND ProductsForRegistrationOldMechanics.Series = PurchaseOfGoodsServicesGoods.Series
	|		AND ProductsForRegistrationOldMechanics.Warehouse = PurchaseOfGoodsServicesGoods.Warehouse
	|		AND ProductsForRegistrationOldMechanics.RowID = PurchaseOfGoodsServicesGoods.RowID
	|WHERE
	|	ProductsForRegistrationOldMechanics.ToRegister > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForRegistration.DocumentInflow 			AS DocumentInflow,
	|	GoodsForRegistration.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	GoodsForRegistration.Products 					AS Products,
	|	GoodsForRegistration.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	GoodsForRegistration.CCDNumber 						AS CCDNumber,
	|	CatProducts.UnitOfMeasure 				AS UnitOfMeasure,
	|	CatProducts.FEACNCode 						AS FEACNCode,
	|	CatProducts.ItemsType 				AS ItemsType,
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
	|		VALUE(Catalog.VATRates.EmptyRef))) AS VATRate,
	|	GoodsForRegistration.Characteristic 				AS Characteristic,
	|	GoodsForRegistration.Series 						AS Series,
	|	GoodsForRegistration.Warehouse 						AS Warehouse,
	|	GoodsForRegistration.Sum 						AS Sum,
	|	GoodsForRegistration.Count					AS Count,
	|	GoodsForRegistration.RowID 			AS RowID
	|INTO GoodsForRegistration
	|FROM
	|	GoodsForRegistrationArePreliminary AS GoodsForRegistration
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON GoodsForRegistration.Products = CatProducts.Ref
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(
	|			&AccountingRecordDate,
	|			Country = &RegistrationCountry
	|				OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|		ON GoodsForRegistration.Products = ProductsVATRates.Products
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&AccountingRecordDate,
	|			Country = &RegistrationCountry) AS BasicVATRates
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForRegistration.DocumentInflow 			AS DocumentInflow,
	|	DocumentOfReceiptOfGoods.LineNumber AS LineNumber,
	|	GoodsForRegistration.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	GoodsForRegistration.Products 					AS Products,
	|	GoodsForRegistration.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	GoodsForRegistration.FEACNCode						AS FEACNCode,
	|	GoodsForRegistration.Characteristic 				AS Characteristic,
	|	GoodsForRegistration.Series 						AS Series,
	|	GoodsForRegistration.Warehouse 						AS Warehouse,
	|	GoodsForRegistration.UnitOfMeasure 				AS UnitOfMeasure,
	|	DocumentOfReceiptOfGoods.QuantityForDistribution AS BaseForDistribution_Quantity,
	|	DocumentOfReceiptOfGoods.AmountToDistribution AS BaseForDistribution_Amount,
	|	GoodsForRegistration.Count 					AS Count,
	|	GoodsForRegistration.Sum 						AS TaxInvoicedPrice,
	|	0 												AS VATTaxBase,
	|	GoodsForRegistration.VATRate						AS VATRate,
	|	ISNULL(DocumentOfReceiptOfGoods.OriginCountry, Operation.Counterparty.RegistrationCountry) AS
	|		OriginCountry,
	|	DocumentOfReceiptOfGoods.CDNumber 				AS CDNumber,
	|	Operation.Currency 								AS Currency,
	|	Operation.IncomingDocumentNumber 				AS SupportingDocumentSeriesNumber,
	|	Operation.IncomingDocumentDate 				AS SupportingDocumentDate,
	|	Operation.Contract 								AS Contract,
	|	CASE
	|		WHEN DocumentOfReceiptOfGoods.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN DocumentOfReceiptOfGoods.VATActivityType
	|		ELSE Operation.PurchaseForActivity
	|	END 											AS PurchaseForActivity,
	|	DocumentOfReceiptOfGoods.PartnerProducts 	AS PartnerProducts,
	|	DocumentOfReceiptOfGoods.RowID 	AS RowID,
	|	&AccountingRecordDate 							AS AccountingRecordDate,
	|	&TransportKind 									AS TransportKind
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|		INNER JOIN TT_Goods AS DocumentOfReceiptOfGoods
	|		ON GoodsForRegistration.DocumentInflow = DocumentOfReceiptOfGoods.DocumentInflow
	|			AND (GoodsForRegistration.Products = DocumentOfReceiptOfGoods.Products
	|				AND GoodsForRegistration.Characteristic = DocumentOfReceiptOfGoods.Characteristic
	|				OR GoodsForRegistration.ItemsLocationAttributes = UNDEFINED)
	|			AND GoodsForRegistration.CCDNumber = DocumentOfReceiptOfGoods.CDNumber
	|			AND GoodsForRegistration.RowID = DocumentOfReceiptOfGoods.RowID
	|
	|		INNER JOIN TT_Operation AS Operation
	|		ON (DocumentOfReceiptOfGoods.DocumentInflow = Operation.Ref)
	|
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|				&AccountingRecordDate, 
	|				Currency = &USDollar
	|				AND BaseCurrency = &BaseCurrency) AS CurrencyExchangeRateUSDollar
	|		ON (TRUE)
	|WHERE
	|	(GoodsForRegistration.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	OR GoodsForRegistration.ItemsLocationAttributes = UNDEFINED)
	|
	|TOTALS
	|	SUM(BaseForDistribution_Quantity),
	|	SUM(BaseForDistribution_Amount),
	|	MAX(Count),
	|	MAX(TaxInvoicedPrice)
	|BY
	|	DocumentInflow,
	|	ItemsLocationAttributes,
	|	CDNumber
	|";
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	SelectionByDocument = QueryResult.Select(QueryResultIteration.ByGroups);
	GoodsTable = QueryResult.Unload();
	GoodsTable.Clear();
	While SelectionByDocument.Next() Do
		
		SelectionByProductType_ = SelectionByDocument.Select(QueryResultIteration.ByGroups);
		While SelectionByProductType_.Next() Do 
			
			SamplingByCCD = SelectionByProductType_.Select(QueryResultIteration.ByGroups);
			While SamplingByCCD.Next() Do 
				
				Selection = SamplingByCCD.Select();
				If Selection.Count() > 1 Then
					
					QuantityForDistribution = SamplingByCCD.Count;
					AmountToDistribution = SamplingByCCD.TaxInvoicedPrice;
					
					While Selection.Next()
						And QuantityForDistribution > 0
						And AmountToDistribution > 0 Do 
						
						QuantityPerRow = Min(QuantityForDistribution, Selection.BaseForDistribution_Quantity);
						LineAmount_ = ?(QuantityPerRow = QuantityForDistribution, AmountToDistribution, Min(AmountToDistribution, Selection.BaseForDistribution_Amount));
						
						NewRow = GoodsTable.Add();
						FillPropertyValues(NewRow, Selection);
						NewRow.Count = QuantityPerRow;
						NewRow.TaxInvoicedPrice = LineAmount_;
						
						QuantityForDistribution = QuantityForDistribution - QuantityPerRow;
						AmountToDistribution = AmountToDistribution - LineAmount_;
						
					EndDo;
					
				Else
					
					NewRow = GoodsTable.Add();
					Selection.Next();
					FillPropertyValues(NewRow, Selection);
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	TextOfRequestPart = 
	"SELECT
	|	GoodsTable.DocumentInflow 			AS DocumentInflow,
	|	GoodsTable.LineNumber					AS LineNumber,
	|	GoodsTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	GoodsTable.Products 					AS Products,
	|	GoodsTable.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	CAST(GoodsTable.FEACNCode AS Catalog.FEACN)	AS FEACNCode,
	|	GoodsTable.Characteristic 				AS Characteristic,
	|	GoodsTable.Series 						AS Series,
	|	GoodsTable.Warehouse 						AS Warehouse,
	|	CAST(GoodsTable.UnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure) 	AS UnitOfMeasure,
	|	GoodsTable.Count 					AS Count,
	|	GoodsTable.TaxInvoicedPrice			AS TaxInvoicedPrice,
	|	GoodsTable.VATRate						AS VATRate,
	|	GoodsTable.OriginCountry			AS OriginCountry,
	|	GoodsTable.CDNumber 						AS CDNumber,
	|	GoodsTable.Currency 						AS Currency,
	|	GoodsTable.SupportingDocumentSeriesNumber 				AS SupportingDocumentSeriesNumber,
	|	GoodsTable.SupportingDocumentDate				 		AS SupportingDocumentDate,
	|	GoodsTable.Contract 						AS Contract,
	|	GoodsTable.PurchaseForActivity		AS PurchaseForActivity,
	|	GoodsTable.PartnerProducts 			AS PartnerProducts,
	|	GoodsTable.RowID 			AS RowID
	|INTO TTProductsStatementsPreliminary
	|FROM
	|	&GoodsTable AS GoodsTable";
	
	PartsOfQueryText.Add(TextOfRequestPart);
	
	TextOfRequestPart =
		ExcisableGoodsAccounting.QueryTextDataOfExcisableItems(UseExcisableGoods, "TTProductsStatementsPreliminary");
	PartsOfQueryText.Add(TextOfRequestPart);
		
	TextOfRequestPart =
	"SELECT
	|	TTProductsStatementsPreliminary.DocumentInflow 			AS DocumentInflow,
	|	TTProductsStatementsPreliminary.LineNumber					AS LineNumber,
	|	TTProductsStatementsPreliminary.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TTProductsStatementsPreliminary.Products 					AS Products,
	|	TTProductsStatementsPreliminary.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TTProductsStatementsPreliminary.FEACNCode						AS FEACNCode,
	|	TTProductsStatementsPreliminary.Characteristic 				AS Characteristic,
	|	TTProductsStatementsPreliminary.Series 							AS Series,
	|	TTProductsStatementsPreliminary.Warehouse 							AS Warehouse,
	|	TTProductsStatementsPreliminary.UnitOfMeasure 				AS UnitOfMeasure,
	|	TTProductsStatementsPreliminary.Count 					AS Count,
	|	TTProductsStatementsPreliminary.TaxInvoicedPrice 			AS TaxInvoicedPrice,
	|	0 																AS VATTaxBase,
	|	TTProductsStatementsPreliminary.VATRate						AS VATRate,
	|	0 																AS VATAmount,
	|	0																AS StatValueUSDollars,
	|	&QueryTextWeight * TTProductsStatementsPreliminary.Count  AS NetWeightKg,
	|	CASE
	|		WHEN TTProductsStatementsPreliminary.FEACNCode.UnitOfMeasure = TTProductsStatementsPreliminary.UnitOfMeasure
	|			THEN 1
	|		WHEN TTProductsStatementsPreliminary.UnitOfMeasure.UnitOfMeasure = TTProductsStatementsPreliminary.FEACNCode.UnitOfMeasure
	|		AND TTProductsStatementsPreliminary.UnitOfMeasure.Denominator <> 0
	|			THEN TTProductsStatementsPreliminary.UnitOfMeasure.Numerator / TTProductsStatementsPreliminary.UnitOfMeasure.Denominator
	|		WHEN TTProductsStatementsPreliminary.FEACNCode.UnitOfMeasure.Numerator = 0
	|			THEN 0
	|		ELSE CASE TTProductsStatementsPreliminary.FEACNCode.UnitOfMeasure.MeasuredValueType
	|			WHEN VALUE(Enum.TypesOfMeasuredValues.Weight)
	|				THEN &QueryTextWeight
	|			WHEN VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
	|				THEN &QueryTextVolumeM3
	|			WHEN VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
	|				THEN &QueryTextAreaTypeOfMeasurement
	|			WHEN VALUE(Enum.TypesOfMeasuredValues.Length)
	|				THEN &QueryTextLength
	|			WHEN VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
	|				THEN &QueryTextNumberOfPieces
	|			ELSE 0
	|		END * TTProductsStatementsPreliminary.FEACNCode.UnitOfMeasure.Denominator /
	|			TTProductsStatementsPreliminary.FEACNCode.UnitOfMeasure.Numerator
	|	END * TTProductsStatementsPreliminary.Count 			AS QuantityByFEACN,
	|	&BaseCurrency													AS ComplCurrency,
	|	ISNULL(Excisable_Items.ExcisableGoods, FALSE) 				AS ExcisableGoods,
	|	ISNULL(Excisable_Items.ConversionRatioOfUnits, 0)
	|		 * TTProductsStatementsPreliminary.Count 				AS TaxBaseExcises,
	|	ISNULL(Excisable_Items.Rate1, 0) 							AS FixedExciseDuty,
	|	ISNULL(Excisable_Items.LocalBid, 0) * ISNULL(Excisable_Items.ConversionRatioOfUnits, 0)
	|		 * TTProductsStatementsPreliminary.Count				AS ExciseTaxAmount,
	|	ISNULL(Excisable_Items.ExciseUnit, UNDEFINED) AS ExciseUnit,
	|	ISNULL(Excisable_Items.CurrencyOfExciseDuty, &BaseCurrency) 		AS CurrencyOfExciseDuty,
	|	ISNULL(Excisable_Items.RateType, UNDEFINED) 			AS RateType,
	|	TTProductsStatementsPreliminary.OriginCountry 			AS OriginCountry,
	|	TTProductsStatementsPreliminary.CDNumber 						AS CDNumber,
	|	TTProductsStatementsPreliminary.Currency 						AS Currency,
	|	TTProductsStatementsPreliminary.SupportingDocumentSeriesNumber 					AS SupportingDocumentSeriesNumber,
	|	TTProductsStatementsPreliminary.SupportingDocumentDate 						AS SupportingDocumentDate,
	|	TTProductsStatementsPreliminary.Contract 						AS Contract,
	|	TTProductsStatementsPreliminary.PurchaseForActivity			AS PurchaseForActivity,
	|	TTProductsStatementsPreliminary.PartnerProducts 			AS PartnerProducts,
	|	TTProductsStatementsPreliminary.RowID 			AS RowID,
	|	&AccountingRecordDate 											AS AccountingRecordDate,
	|	&TransportKind 													AS TransportKind
	|INTO TTProductsStatements
	|FROM
	|	TTProductsStatementsPreliminary AS TTProductsStatementsPreliminary
	|
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|				&AccountingRecordDate, 
	|				Currency = &USDollar
	|				AND BaseCurrency = &BaseCurrency) AS CurrencyExchangeRateUSDollar
	|		ON (TRUE)
	|
	|		LEFT JOIN Excisable_Items AS Excisable_Items
	|		ON TTProductsStatementsPreliminary.Products = Excisable_Items.Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProductsStatements.DocumentInflow 			AS DocumentInflow,
	|	TTProductsStatements.LineNumber 					AS LineNumber,
	|	TTProductsStatements.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TTProductsStatements.Products 					AS Products,
	|	TTProductsStatements.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TTProductsStatements.FEACNCode 						AS FEACNCode,
	|	TTProductsStatements.Characteristic 				AS Characteristic,
	|	TTProductsStatements.Series 						AS Series,
	|	TTProductsStatements.Warehouse 						AS Warehouse,
	|	TTProductsStatements.UnitOfMeasure 				AS UnitOfMeasure,
	|	TTProductsStatements.Count 					AS Count,
	|	TTProductsStatements.TaxInvoicedPrice 			AS TaxInvoicedPrice,
	|	TTProductsStatements.VATTaxBase 				AS VATTaxBase,
	|	TTProductsStatements.VATRate 					AS VATRate,
	|	TTProductsStatements.VATAmount 						AS VATAmount,
	|	TTProductsStatements.StatValueUSDollars 		AS StatValueUSDollars,
	|	TTProductsStatements.NetWeightKg 					AS NetWeightKg,
	|	TTProductsStatements.QuantityByFEACN 			AS QuantityByFEACN,
	|	TTProductsStatements.ComplCurrency 					AS ComplCurrency,
	|	TTProductsStatements.ExcisableGoods				AS ExcisableGoods,
	|	TTProductsStatements.TaxBaseExcises 			AS TaxBaseExcises,
	|	TTProductsStatements.FixedExciseDuty			AS FixedExciseDuty,
	|	TTProductsStatements.ExciseTaxAmount					AS ExciseTaxAmount,
	|	TTProductsStatements.ExciseUnit 		AS ExciseUnit,
	|	TTProductsStatements.CurrencyOfExciseDuty 					AS CurrencyOfExciseDuty,
	|	TTProductsStatements.RateType 					AS RateType,
	|	TTProductsStatements.OriginCountry 			AS OriginCountry,
	|	TTProductsStatements.CDNumber 						AS CDNumber,
	|	TTProductsStatements.Currency 						AS Currency,
	|	TTProductsStatements.SupportingDocumentSeriesNumber 				AS SupportingDocumentSeriesNumber,
	|	TTProductsStatements.SupportingDocumentDate 						AS SupportingDocumentDate,
	|	TTProductsStatements.Contract 						AS Contract,
	|	TTProductsStatements.PurchaseForActivity 		AS PurchaseForActivity,
	|	TTProductsStatements.PartnerProducts 			AS PartnerProducts,
	|	TTProductsStatements.RowID 			AS RowID,
	|	TTProductsStatements.AccountingRecordDate 			AS AccountingRecordDate,
	|	TTProductsStatements.TransportKind 				AS TransportKind
	|FROM
	|	TTProductsStatements AS TTProductsStatements
	|
	|ORDER BY
	|	DocumentInflow,
	|	LineNumber";
	PartsOfQueryText.Add(TextOfRequestPart);
	
	TextOfRequestPart = ExcisableGoodsAccounting.QueryTextErrorInExciseCalculation(UseExcisableGoods);
	PartsOfQueryText.Add(TextOfRequestPart);
	
	QueryText = StrConcat(PartsOfQueryText, Common.QueryBatchSeparator());
	
	QueryText = StrReplace(QueryText, "&QueryTextWeight", 
					Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
						"TTProductsStatementsPreliminary.UnitOfMeasure", 
						"TTProductsStatementsPreliminary.Products"));
	QueryText = StrReplace(QueryText, "&QueryTextVolumeM3", 
					Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
						"TTProductsStatementsPreliminary.UnitOfMeasure", 
						"TTProductsStatementsPreliminary.Products"));
	QueryText = StrReplace(QueryText, "&QueryTextAreaTypeOfMeasurement", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextPackingArea(
						"TTProductsStatementsPreliminary.UnitOfMeasure", 
						"TTProductsStatementsPreliminary.Products"));
	QueryText = StrReplace(QueryText, "&QueryTextLength", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextPackageLength(
						"TTProductsStatementsPreliminary.UnitOfMeasure", 
						"TTProductsStatementsPreliminary.Products"));
	QueryText = StrReplace(QueryText, "&QueryTextNumberOfPieces", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"TTProductsStatementsPreliminary.UnitOfMeasure", 
						"TTProductsStatementsPreliminary.Products"));
						
	Query.SetParameter("GoodsTable", GoodsTable);
						
	Return QueryText;
	
EndFunction

Function AllocateAmountsForRentalServices(LeaseRequest)
	
	LeaseRequest.Text = "SELECT
		|	TermsOfLeaseContractsSliceLast.EffectiveContractTerms AS EffectiveContractTerms
		|INTO TTIsDocumentSettingTermsOfLeaseContract
		|FROM
		|	InformationRegister.TermsOfLeaseContracts.SliceLast(&Execution_Period, Contract = &LeaseContracts) AS TermsOfLeaseContractsSliceLast
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SigningOfLeaseContractFA.FixedAsset AS FixedAsset,
		|	SigningOfLeaseContractFA.Cost AS FACost,
		|	OperationOfConcludingLeaseContract.LeaseItemsCost AS LeaseItemsCost
		|INTO TTOfFACost
		|FROM
		|	Document.SigningOfLeaseContract.FA AS SigningOfLeaseContractFA
		|		INNER JOIN Document.SigningOfLeaseContract AS OperationOfConcludingLeaseContract
		|		ON SigningOfLeaseContractFA.Ref = OperationOfConcludingLeaseContract.Ref
		|		INNER JOIN TTIsDocumentSettingTermsOfLeaseContract AS TTIsDocumentSettingTermsOfLeaseContract
		|		ON SigningOfLeaseContractFA.Ref = TTIsDocumentSettingTermsOfLeaseContract.EffectiveContractTerms
		|
		|UNION ALL
		|
		|SELECT
		|	LeaseTermAdjustmentFA.FixedAsset,
		|	LeaseTermAdjustmentFA.Cost,
		|	OperationOfChangingLeaseContract.LeaseItemsCost
		|FROM
		|	Document.LeaseTermAdjustment.FA AS LeaseTermAdjustmentFA
		|		INNER JOIN Document.LeaseTermAdjustment AS OperationOfChangingLeaseContract
		|		ON LeaseTermAdjustmentFA.Ref = OperationOfChangingLeaseContract.Ref
		|		INNER JOIN TTIsDocumentSettingTermsOfLeaseContract AS TTIsDocumentSettingTermsOfLeaseContract
		|		ON LeaseTermAdjustmentFA.Ref = TTIsDocumentSettingTermsOfLeaseContract.EffectiveContractTerms
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductsOfApplication.DocumentInflow AS DocumentInflow,
		|	ProductsOfApplication.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	ProductsOfApplication.Products AS Products,
		|	ProductsOfApplication.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	ProductsOfApplication.FEACNCode AS FEACNCode,
		|	ProductsOfApplication.Characteristic AS Characteristic,
		|	ProductsOfApplication.Series AS Series,
		|	ProductsOfApplication.Warehouse AS Warehouse,
		|	ProductsOfApplication.UnitOfMeasure AS UnitOfMeasure,
		|	1 AS Count,
		|	CASE
		|		WHEN ISNULL(TTOfFACost.LeaseItemsCost, 0) = 0
		|			THEN 0
		|		ELSE ProductsOfApplication.TaxInvoicedPrice * TTOfFACost.FACost / TTOfFACost.LeaseItemsCost
		|	END AS TaxInvoicedPrice,
		|	0 AS VATTaxBase,
		|	ProductsOfApplication.VATRate AS VATRate,
		|	0 AS VATAmount,
		|	0 AS StatValueUSDollars,
		|	ProductsOfApplication.NetWeightKg AS NetWeightKg,
		|	1 AS QuantityByFEACN,
		|	0 AS TaxBaseExcises,
		|	ProductsOfApplication.OriginCountry AS OriginCountry,
		|	ProductsOfApplication.CDNumber AS CDNumber,
		|	ProductsOfApplication.Currency AS Currency,
		|	ProductsOfApplication.SupportingDocumentSeriesNumber AS SupportingDocumentSeriesNumber,
		|	ProductsOfApplication.SupportingDocumentDate AS SupportingDocumentDate,
		|	ProductsOfApplication.Contract AS Contract,
		|	ProductsOfApplication.PurchaseForActivity AS PurchaseForActivity,
		|	ProductsOfApplication.PartnerProducts AS PartnerProducts,
		|	ProductsOfApplication.RowID AS RowID,
		|	ProductsOfApplication.AccountingRecordDate AS AccountingRecordDate,
		|	ProductsOfApplication.TransportKind AS TransportKind,
		|	ISNULL(PRESENTATION(TTOfFACost.FixedAsset), """") AS Content
		|FROM
		|	TTProductsStatements AS ProductsOfApplication
		|		LEFT JOIN TTOfFACost AS TTOfFACost
		|		ON (TRUE)";
	
	Return LeaseRequest.Execute().Unload();
	
EndFunction

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	&Ref                                                             AS Ref,
	|	MAX(
	|		ISNULL(GoodsTable.DocumentInflow.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
	|	MAX(
	|		ISNULL(GoodsTable.DocumentInflow.Warehouse,
	|			VALUE(Catalog.Warehouses.EmptyRef)))                  AS StorageLocation,
	|	COUNT(
	|		DISTINCT ISNULL(GoodsTable.DocumentInflow.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS NumberOfActivities,
	|	COUNT(
	|		DISTINCT ISNULL(GoodsTable.DocumentInflow.Warehouse,
	|			VALUE(Catalog.Warehouses.EmptyRef)))                  AS NumberOfStorageLocations
	|INTO TTBases
	|FROM
	|	Document.ApplicationForImportationOfGoods AS DocumentData
	|		LEFT JOIN Document.ApplicationForImportationOfGoods.Goods AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	&Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Deprecated. You should use the accounting of the PSUP.To form movements in registers().
//
// The procedure for forming movements in the register "Goods for processing import applications".
//
// Parameters:
//	AdditionalProperties - Structure - a list of tables of values for writing to registers.
//	RegisterRecords - RegisterRecordsCollection - Collection of document movements
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectGoodsForProcessingApplicationsForImportOfGoods(AdditionalProperties, RegisterRecords, Cancel) Export

	TableGoodsForProcessingImportApplications = AdditionalProperties.TablesForRegisteredRecords.TableGoodsForRegistrationOfApplicationForImportProductsFromEEUCountries;
	
	If Cancel Or TableGoodsForProcessingImportApplications.Count() = 0 Then
		Return;
	EndIf;
	
	MovementOfGoodsForRegistrationOfImportApplications = RegisterRecords.GoodsForRegistrationOfApplicationForImportFromEEUCountries;
	MovementOfGoodsForRegistrationOfImportApplications.Write = True;
	MovementOfGoodsForRegistrationOfImportApplications.Load(TableGoodsForProcessingImportApplications);
	
EndProcedure

// Returns the result of case-sensitive adaptation of the Query Text of the Registered Records.
// 
// Parameters:
//  RegisterName - String - the name of the register in the configuration.
// 
// Returns:
//  See InfobaseUpdateTM.ResultOfRequestAdaptation
//
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.ApplicationForImportationOfGoods";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("BusinessOperation", Enums.BusinessTransactions.ImportFromEAEU);
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", 	FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", 		RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("ConversionRateToManCurrency");
	AdditionalParameters.Add("FactorOfConversionToCurrencyOfRegul");
	AdditionalParameters.Add("TypesOfTaxationVATIsIncludedInCost");
	
	If Query <> Undefined Then
		InitializeExchangeRates(Query);
		InitializeProductAccountingAnalyticsKeys(Query);
		Query.SetParameter("TypesOfTaxationVATIsIncludedInCost",
			VATAccountingERP.ActivitiesVATIsIncludedInCost());
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableOfPartyAccountingAnalysts");
	AdditionalTables.Add("TTGoodsImportApplications");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable("TTGoodsImportApplications", QueryTexts) Then
			QueryTextTTGoodsImportApplications(Query, QueryTexts)
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region ExternalReceipt_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 					AS Period,
	|	DocumentTable.Ref 				AS Ref,
	|	TableTypesOfStocks_.DocumentInflow	AS DocumentSource,
	|	VendorInvoice.Date			AS SourceDocumentPeriod,
	|	UNDEFINED 							AS DocumentToBeCorrected,
	|	(CASE
	|		WHEN BEGINOFPERIOD(VendorInvoice.Date, MONTH) < BEGINOFPERIOD(DocumentTable.Date, MONTH)
	|			THEN VendorInvoice.Date
	|		ELSE &AdjustmentPeriod_ END)	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 										  AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 						  AS ItemsLocationAttributes,
	|	ISNULL(GoodsReceipts.InventoryOwnerAttribute, TableTypesOfStocks_.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.DocumentInflow 								  AS Lot,
	|	TableOfReceiptBatchAccountingAnalysts.VATTaxation			  AS VATActivityType,
	|	TableOfReceiptBatchAccountingAnalysts.VATTaxation			  AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableOfReceiptBatchAccountingAnalysts.LotVendorAttributes 	AS LotVendorAttributes,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableOfBatchAccountingAnalysts.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 														AS LotVendorAttributesCorr,
	|	UNDEFINED 					AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate 	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	VendorInvoice.SalesOpportunity			AS SalesOpportunity,
	|	VendorInvoice.Department 	AS Department,
	|	VendorInvoice.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	0 										AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	0 										AS Cost,
	|	0 										AS CostExcludingVAT,
	|	0 										AS LocalCost,
	|	CASE WHEN TableOfReceiptBatchAccountingAnalysts.VATTaxation = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0 
	|		ELSE TableTypesOfStocks_.VATAmount
	|	END	 								AS VATLocal,
	|	0 										AS CostMan,
	|	CASE WHEN TableOfReceiptBatchAccountingAnalysts.VATTaxation = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0 
	|		ELSE TableTypesOfStocks_.Cost
	|	END	 								AS VATManag,
	|	0 										AS OffBalanceCost,
	|	0 										AS OffBalanceCostLocal,
	|	TableTypesOfStocks_.Cost AS AddExpensesForGoods,
	|	0										AS AdditionalExpensesExcludingVAT,
	|	0										AS AddExpensesLocal,
	|	0										AS AddExpensesMan,
	|	0 										AS PermanentDifference,
	|	0 										AS CostTD,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	(CASE
	|		WHEN VendorInvoice.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
	|			THEN VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
	|		ELSE VALUE(Enum.BusinessTransactions.ImportFromEAEU) END) AS BusinessOperation,
	|	TableTypesOfStocks_.RowID   						 AS FinRecordID,
	|	&BusinessTransactionSetting_IncludeVATInCostExpenses			 AS BusinessTransactionSetting
	|
	|FROM
	|	TTGoodsImportApplications AS TableTypesOfStocks_
	|	LEFT JOIN Document.VendorInvoice.Goods AS GoodsReceipts
	|		ON GoodsReceipts.Ref = TableTypesOfStocks_.DocumentInflow
	|		AND CASE WHEN GoodsReceipts.RowID <> """"
	|			THEN GoodsReceipts.RowID = TableTypesOfStocks_.RowID
	|			ELSE GoodsReceipts.ItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|		  END
	|	INNER JOIN Document.ApplicationForImportationOfGoods AS DocumentTable
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|	INNER JOIN Document.VendorInvoice AS VendorInvoice
	|		ON TableTypesOfStocks_.DocumentInflow = VendorInvoice.Ref
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfReceiptBatchAccountingAnalysts
	|		ON TableOfReceiptBatchAccountingAnalysts.LineNumber 	   = TableTypesOfStocks_.LineNumber
	|		 AND TableOfReceiptBatchAccountingAnalysts.TabularSectionName = ""GoodsReceipts""
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 	    = TableTypesOfStocks_.LineNumber
	|		 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.VATAmount <> 0
	|	AND TableTypesOfStocks_.Products <> VALUE(Catalog.Products.EmptyRef)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	#Region ExternalReceipt_ProductsOfProcessor
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 					AS Period,
	|	DocumentTable.Ref 				AS Ref,
	|	TableTypesOfStocks_.DocumentInflow	AS DocumentSource,
	|	SubcontractorReport2_5.Date				AS SourceDocumentPeriod,
	|	UNDEFINED 							AS DocumentToBeCorrected,
	|	(CASE
	|		WHEN BEGINOFPERIOD(SubcontractorReport2_5.Date, MONTH) < BEGINOFPERIOD(DocumentTable.Date, MONTH)
	|			THEN SubcontractorReport2_5.Date
	|		ELSE &AdjustmentPeriod_ END)	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 										  AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 						  AS ItemsLocationAttributes,
	|	ISNULL(GoodsReceipts.InventoryOwnerAttribute, TableTypesOfStocks_.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.DocumentInflow 								  AS Lot,
	|	TableOfReceiptBatchAccountingAnalysts.VATTaxation			  AS VATActivityType,
	|	UNDEFINED									  					  AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableOfReceiptBatchAccountingAnalysts.LotVendorAttributes 	AS LotVendorAttributes,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableOfBatchAccountingAnalysts.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 														AS LotVendorAttributesCorr,
	|	UNDEFINED 					AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate 	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	SubcontractorReport2_5.SalesOpportunity			AS SalesOpportunity,
	|	SubcontractorReport2_5.Department 	AS Department,
	|	SubcontractorReport2_5.Manager 			AS Manager,
	|
	// Quantitative and summary indicators
	|	0 										AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	0 										AS Cost,
	|	0 										AS CostExcludingVAT,
	|	0 										AS LocalCost,
	|	CASE WHEN TableOfReceiptBatchAccountingAnalysts.VATTaxation = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0 
	|		ELSE TableTypesOfStocks_.VATAmount
	|	END	 								AS VATLocal,
	|	0 										AS CostMan,
	|	CASE WHEN TableOfReceiptBatchAccountingAnalysts.VATTaxation = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0 
	|		ELSE TableTypesOfStocks_.Cost
	|	END	 								AS VATManag,
	|	0 										AS OffBalanceCost,
	|	0 										AS OffBalanceCostLocal,
	|	TableTypesOfStocks_.Cost			AS AddExpensesForGoods,
	|	0										AS AdditionalExpensesExcludingVAT,
	|	0										AS AddExpensesLocal,
	|	0										AS AddExpensesMan,
	|	0 										AS PermanentDifference,
	|	0 										AS CostTD,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ImportFromEAEU) BusinessOperation,
	|	TableTypesOfStocks_.RowID   						 AS FinRecordID,
	|	&BusinessTransactionSetting_IncludeVATInCostExpenses			 AS BusinessTransactionSetting
	|
	|FROM
	|	TTGoodsImportApplications AS TableTypesOfStocks_
	|	LEFT JOIN Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS GoodsReceipts
	|		ON GoodsReceipts.Ref = TableTypesOfStocks_.DocumentInflow
	|		AND GoodsReceipts.ItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|	INNER JOIN Document.ApplicationForImportationOfGoods AS DocumentTable
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|	INNER JOIN Document.SubcontractorReport2_5 AS SubcontractorReport2_5
	|		ON TableTypesOfStocks_.DocumentInflow = SubcontractorReport2_5.Ref
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfReceiptBatchAccountingAnalysts
	|		ON TableOfReceiptBatchAccountingAnalysts.LineNumber 	   = TableTypesOfStocks_.LineNumber
	|		 AND TableOfReceiptBatchAccountingAnalysts.TabularSectionName = ""GoodsReceipts""
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 	    = TableTypesOfStocks_.LineNumber
	|		 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.VATAmount <> 0
	|	AND TableTypesOfStocks_.Products <> VALUE(Catalog.Products.EmptyRef)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	#Region ExternalReceipt_Item_InclusionOfExciseTaxInCost
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 					AS Period,
	|	DocumentTable.Ref 				AS Ref,
	|	TableTypesOfStocks_.DocumentInflow	AS DocumentSource,
	|	VendorInvoice.Date			AS SourceDocumentPeriod,
	|	UNDEFINED 							AS DocumentToBeCorrected,
	|	(CASE
	|		WHEN BEGINOFPERIOD(VendorInvoice.Date, MONTH) < BEGINOFPERIOD(DocumentTable.Date, MONTH)
	|			THEN VendorInvoice.Date
	|		ELSE &AdjustmentPeriod_ END)	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 										  AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 						  AS ItemsLocationAttributes,
	|	ISNULL(GoodsReceipts.InventoryOwnerAttribute, TableTypesOfStocks_.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.DocumentInflow 								  AS Lot,
	|	TableOfReceiptBatchAccountingAnalysts.VATTaxation			  AS VATActivityType,
	|	UNDEFINED									  					  AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableOfReceiptBatchAccountingAnalysts.LotVendorAttributes 	AS LotVendorAttributes,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableOfBatchAccountingAnalysts.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 														AS LotVendorAttributesCorr,
	|	UNDEFINED 					AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate 	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	VendorInvoice.SalesOpportunity			AS SalesOpportunity,
	|	VendorInvoice.Department 	AS Department,
	|	VendorInvoice.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	0 										AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	0 										AS Cost,
	|	0 										AS CostExcludingVAT,
	|	0 										AS LocalCost,
	|	0	 									AS VATLocal,
	|	0 										AS CostMan,
	|	0	 									AS VATManag,
	|	0 										AS OffBalanceCost,
	|	0 										AS OffBalanceCostLocal,
	|	TableTypesOfStocks_.AddExpensesForGoods           AS AddExpensesForGoods,
	|	TableTypesOfStocks_.AddExpensesForGoods			AS AdditionalExpensesExcludingVAT,
	|	TableTypesOfStocks_.ExciseTaxAmount			AS AddExpensesLocal,
	|	TableTypesOfStocks_.AddExpensesForGoods           AS AddExpensesMan,
	|	0 										AS PermanentDifference,
	|	0 										AS CostTD,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.LotRecordTypes.IncludeExciseInCost) AS EntryType,
	|	(CASE
	|		WHEN VendorInvoice.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
	|			THEN VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
	|		ELSE VALUE(Enum.BusinessTransactions.ImportFromEAEU) END) AS BusinessOperation,
	|	TableTypesOfStocks_.RowID   						 AS FinRecordID,
	|	&SettingUpBusinessOfOperation_AccrualOfExciseTaxes				 AS BusinessTransactionSetting
	|
	|FROM
	|	TTGoodsImportApplications AS TableTypesOfStocks_
	|	LEFT JOIN Document.VendorInvoice.Goods AS GoodsReceipts
	|		ON GoodsReceipts.Ref = TableTypesOfStocks_.DocumentInflow
	|		AND CASE WHEN GoodsReceipts.RowID <> """"
	|			THEN GoodsReceipts.RowID = TableTypesOfStocks_.RowID
	|			ELSE GoodsReceipts.ItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|		  END
	|	INNER JOIN Document.ApplicationForImportationOfGoods AS DocumentTable
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|	INNER JOIN Document.VendorInvoice AS VendorInvoice
	|		ON TableTypesOfStocks_.DocumentInflow = VendorInvoice.Ref
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfReceiptBatchAccountingAnalysts
	|		ON TableOfReceiptBatchAccountingAnalysts.LineNumber 	   = TableTypesOfStocks_.LineNumber
	|		 AND TableOfReceiptBatchAccountingAnalysts.TabularSectionName = ""GoodsReceipts""
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 	    = TableTypesOfStocks_.LineNumber
	|		 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ExciseTaxAmount <> 0
	|	AND TableTypesOfStocks_.Products <> VALUE(Catalog.Products.EmptyRef)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region CreatingHyperlinkInPurchaseLog

// Returns the hyperlink text for the transition from the document log to the design workspace.
//
// Parameters:
//  Parameters - Structure - parameters for forming the hyperlink text.
//
// Returns:
//  FormattedString, Undefined - hyperlink text.
//
Function CreateHyperlinkToDesign(Parameters) Export
	
	ThereIsRightToReadReceiptsOfGoodsServices = AccessRight("Read", Metadata.Documents.VendorInvoice);
	If Not (AccessRight("Read", Metadata.AccumulationRegisters.GoodsForRegistrationOfApplicationForImportFromEEUCountries)
		And ThereIsRightToReadReceiptsOfGoodsServices) Then
		Return Undefined;
	EndIf;
	
	Parameters.Insert("CompanyArray",?(ValueIsFilled(Parameters.Organization), 
											TMCommonUseClientServer.Array(Parameters.Organization),
											Undefined));
	Parameters.Insert("NoPeriodLimit");
	
	HyperlinkText = NStr("vi = 'Giấy đề nghị nhập hàng';
						|ru = 'Заявления о ввозе';
						|en = 'Import application'; fa = 'Import application';
						|it = 'Dichiarazione di importazione';
						|pl = 'Oświadczenia o imporcie';
						|tr = 'İthalat beyannamesi'");
	
	If ThereAreInvoicesForRegistration(Parameters) Then
		Return New FormattedString(HyperlinkText,,,,
			NameOfApplicationFormForImportOfGoods());
	Else
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			NameOfApplicationFormForImportOfGoods());
	EndIf;
	
EndFunction

// Returns the name of the workplace application form for importing goods.
//
// Returns:
//  String - the name of the workplace application form for the import of goods.
//
Function NameOfApplicationFormForImportOfGoods() Export
	
	Return "Document.ApplicationForImportationOfGoods.Form.WorkplaceForm";
	
EndFunction

Function TextOfRequestGroundsForProcessingApplicationsForImportOfGoods(ByCompanies = False)
	
	ArrayOfRequestTexts = New Array;
	
	QueryTemplate = "
	|SELECT
	|		COUNT(DISTINCT DocumentReferenceOrder.Ref) AS NumberOfDocumentsForRegistration
	|	FROM
	|		#DocumentReferenceOrder AS DocumentReferenceOrder
	|			INNER JOIN TTOrdersForProcessingImportApplications AS TTOrdersForProcessingImportApplications
	|			ON DocumentReferenceOrder.Ref = TTOrdersForProcessingImportApplications.DocumentInflow
	|	WHERE
	|		&PeriodSelectionCriteria
	|";
	
	TypesArray = TypesOfDocumentsGroundsForRegistration();
	
	QueryText = "";
	
	For Each TypeName In TypesArray Do
		
		If Not AccessRight("Read", Metadata.Documents[TypeName]) Then
			Continue;
		EndIf;
		
		RequestTextForType = StrReplace(QueryTemplate, "#DocumentReferenceOrder", "Document." + TypeName);
		ArrayOfRequestTexts.Add(RequestTextForType);
		
	EndDo;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	If ByCompanies Then
		QueryText = StrReplace(QueryText,
			"COUNT(DISTINCT DocumentReferenceOrder.Ref) AS NumberOfDocumentsForRegistration",
			"DISTINCT TTOrdersForProcessingImportApplications.Organization");
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
