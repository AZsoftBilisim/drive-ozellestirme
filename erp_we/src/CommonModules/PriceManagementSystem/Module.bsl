////////////////////////////////////////////////////////////////////////////////
// The Pricing module contains procedures and functions for verifying
// the correctness of price setting documents and for processing 
// the entered data by the user.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ItemsPrices);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ItemsPrices25);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ItemsPricesOfVendor);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.BonusPoints);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.PurchaseConditions);
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.BonusPoints;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
			
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of prices and discounts.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ItemsPrices");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ItemsPrices25");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ItemsPricesOfVendor");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "BonusPoints");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "PurchaseConditions");
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForServicingTypesOfPricesFilledInAccordingToInformationSecurityData

// Get the "Price list" type of price.
// 
// Parameters:
//  PriceIncludesVAT - Undefined, Boolean - Price includes VAT
// 
// Returns:
//  CatalogRef.TypesOfPrices - Type of price "Price list".
Function PriceTypePriceList_(PriceIncludesVAT = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	TypesOfPrices.Ref,
	|	TypesOfPrices.PriceIncludesVAT
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)");
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		If PriceIncludesVAT = Undefined Or Selection.PriceIncludesVAT = PriceIncludesVAT  Then
			Return Selection.Ref;
		Else
			Return Catalogs.TypesOfPrices.EmptyRef();
		EndIf;
		
	Else
		
		PriceTypePriceList_ = Catalogs.TypesOfPrices.CreateItem();
		PriceTypePriceList_.PriceCurrency = Constants.DefaultBaseCurrency.Get();
		PriceTypePriceList_.PriceIncludesVAT = True;
		PriceTypePriceList_.UseWhileSellingToCustomers = True;
		PriceTypePriceList_.PricingMethod = Enums.PriceSettingMethods.Manually;
		PriceTypePriceList_.DataCompositionSchema = "Typical";
		PriceTypePriceList_.Id = "PriceList";
		PriceTypePriceList_.Description = NStr("vi = 'Bảng giá';
												|ru = 'Прайс-лист';
												|en = 'Price list'; fa = 'فهرست قیمت';
												|it = 'Listino dei prezzi';
												|pl = 'Price list';
												|tr = 'Fiyat listesi'");
		PriceTypePriceList_.Status = Enums.StatusesOfPriceTypeValidity.Valid;
		PriceTypePriceList_.Write();
		
		Return PriceTypePriceList_.Ref;
		
	EndIf;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForCheckingCorrectnessOfFillingOutDocuments

// Checks whether the item price setting document is filled in correctly
// Called from the procedure of the document "report Processing".
//
// Parameters:
//  PriceSettingDocument  - DocumentObject.PriceSetup - document to check for correctness
//  PriceTree             - ValueTable - price table of the document item to check for correctness
//  TypesOfPrices               - Array - array of price types for checking the availability of previously set prices
//  UsePriceManagementSystem25 - Boolean - Flag for using new pricing
//  Cancel                 - Boolean - flag for refusing to carry out the document.
//
Procedure CheckCorrectnessOfProductPriceSettingDocument(PriceSettingDocument,
	                                                                       PriceTree,
	                                                                       TypesOfPrices,
	                                                                       UsePriceManagementSystem25 = False,
	                                                                       Cancel) Export
	
	// Let's form the text of the request for the necessary checks in accordance with the array of checks
	
	QueryText     = "";
	QueryOptions = New Structure();
	
	ChecksArray    = New Array();
	ChecksArray.Add("TemporaryPriceTable");
	ChecksArray.Add("TemporaryPriceTableWithoutDuplicates");
	ChecksArray.Add("CorrectnessOfProducts");
	ChecksArray.Add("AvailabilityOfDuplicateProducts");
	ChecksArray.Add("AvailabilityOfSetPrices");
	
	For Each CurItem In ChecksArray Do

		If CurItem = "TemporaryPriceTable" Then
			
			If UsePriceManagementSystem25 Then
				GenerateTemporaryPriceTableQueryForRegisteringPrices2_5(QueryText, QueryOptions, PriceTree);
			Else
				GenerateTemporaryPriceTableQueryForRegisteringPrices(QueryText, QueryOptions, PriceTree);
			EndIf;
			
		ElsIf CurItem = "TemporaryPriceTableWithoutDuplicates" Then
			
			If UsePriceManagementSystem25 Then
				CreateTemporaryPriceTableQueryWithoutDuplicatesForRegisteringPrices2_5(QueryText);
			Else
				CreateTemporaryPriceTableQueryWithoutDuplicatesForRegisteringPrices(QueryText);
			EndIf;
			
		ElsIf CurItem = "CorrectnessOfProducts" Then
			
			If UsePriceManagementSystem25 Then
				GenerateProductCorrectnessRequestForPriceRegistration2_5(QueryText);
			Else
				GenerateProductCorrectnessRequestForPriceRegistration(QueryText);
			EndIf;
			
		ElsIf CurItem = "AvailabilityOfDuplicateProducts" Then
			
			If UsePriceManagementSystem25 Then
				GenerateRequestForDuplicatesToRegisterPrices2_5(QueryText);
			Else
				GenerateRequestForDuplicatesToRegisterPrices(QueryText);
			EndIf;
			
		ElsIf CurItem = "AvailabilityOfSetPrices" Then
			
			If UsePriceManagementSystem25 Then
				GenerateRequestForAvailabilityOfSetPricesForPriceRegistration2_5(QueryText, QueryOptions, PriceSettingDocument, TypesOfPrices);
			Else
				GenerateRequestForAvailabilityOfSetPricesForPriceRegistration(QueryText, QueryOptions, PriceSettingDocument, TypesOfPrices);
			EndIf;
			
		EndIf;
			
	EndDo;
	
	If Not ValueIsFilled(QueryText) Then
		Return;
	EndIf;
	
	Query = New Query(QueryText);
	
	For Each QueryParameter In QueryOptions Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	
	ResultsArray = Query.ExecuteBatch(); 
	
	// We will inform the user about the verification results for each query result
	
	For CurIndex__ = 0 To ResultsArray.Count()-1 Do
	
		Selection = ResultsArray[CurIndex__].Select();
		
		If ChecksArray[CurIndex__] = "CorrectnessOfProducts" Then
			
			ReportErrorsCorrectnessOfProductsForPriceRegistration(Selection, PriceSettingDocument, UsePriceManagementSystem25, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "AvailabilityOfDuplicateProducts" Then
			
			ReportErrorsDuplicateProductsForPriceRegistration(Selection, PriceSettingDocument, UsePriceManagementSystem25, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "AvailabilityOfSetPrices" Then
			
			ReportErrorsAvailabilityOfSetPricesForPriceRegistration(Selection, PriceSettingDocument, UsePriceManagementSystem25, Cancel);
		
		EndIf;
	
	EndDo;
	
EndProcedure // Check the correctness of the filling of the document by installing the Partner's Nomenclature()

// Checks whether the item price setting document is filled in correctly.
// Called from the procedure of the document "report Processing".
//
// Parameters:
//  PriceSettingDocument	- DocumentObject.VendorPriceList - The document to be 
//								checked for.
//  PriceTree				- ValueTree - price tree
//  Cancel					- Boolean - flag for refusing to carry out the document.
//
Procedure CheckCorrectnessOfFillingInSupplierProductPriceSettingDocument(PriceSettingDocument,
	                                                                                 PriceTree,
	                                                                                 Cancel) Export
	
	QueryText     = "";
	QueryOptions = New Structure();
	
	ChecksArray    = New Array();
	ChecksArray.Add("TemporaryTableOfGoods_");
	ChecksArray.Add("CorrectnessOfProducts");
	
	If GetFunctionalOption("UsePartnersProducts") Then
		ChecksArray.Add("CorrectPartnerProducts");
	EndIf;
	
	// Let's form the text of the request for the necessary checks in accordance with the array of checks
	
	For Each CurItem In ChecksArray Do

		If CurItem = "TemporaryTableOfGoods_" Then
			
			GenerateTemporaryPriceTableQueryForRegisteringSupplierPrices(QueryText, QueryOptions, PriceTree);
			
		ElsIf CurItem = "CorrectnessOfProducts" Then
			
			GenerateProductCorrectnessRequestForRegisteringSupplierPrices(QueryText);
			
		ElsIf CurItem = "CorrectPartnerProducts" Then
			
			PartnersProductsServer.GenerateRequestForFillingInPartnerProductListCorrectly(QueryText, QueryOptions);
			
		EndIf;
		
	EndDo;
	
	Query = New Query(QueryText);
	
	For Each QueryParameter In QueryOptions Do
		Query.SetParameter(QueryParameter.Key,QueryParameter.Value);
	EndDo;
	
	ResultsArray = Query.ExecuteBatch(); 
	
	// We will inform the user about the verification results for each query result
	
	For CurIndex__ = 0 To ResultsArray.Count()-1 Do
	
		Selection = ResultsArray[CurIndex__].Select();
		
		If ChecksArray[CurIndex__] = "CorrectnessOfProducts" Then
			
			ReportErrorsCorrectnessOfProductsForRegisteringSupplierPrices(Selection, PriceSettingDocument, Cancel);
			
		ElsIf ChecksArray[CurIndex__] = "CorrectPartnerProducts" Then
			
			PartnersProductsServer.ReportErrorsCorrectFillingOfPartnerProducts(Selection, PriceSettingDocument, Cancel);
			
		EndIf;
	
	EndDo;
	
EndProcedure // Check the correctness of the filling in of the document of the installment of the supplier's Nomenclature()

#EndRegion

#Region ProceduresAndFunctionsForRecalculatingAmountsInTabularParts

// Calculates the discount amount depending on the discount percentage
//
// Parameters:
//  CurRow                         - LineOfATabularSection - Line in the table part of the Goods document
//  RecalculateAutomaticDiscount - Boolean - True if the document contains automatic discounts
//  ClearingAutomaticDiscount       - Boolean - True if you need to clear the percentage and amount of auto discounts
//  RecalculateManualDiscount         - Boolean - True if the document contains manual discounts
//  PriceIncludesVAT                   - Boolean - Indicates whether VAT is included in the price in the document.
//  QuantityName                     - String - Name of the quantity field.
//
Procedure RecalculateAmountsInRow(CurRow,
	                              Val RecalculateAutomaticDiscount,
	                              Val ClearingAutomaticDiscount,
	                              Val RecalculateManualDiscount,
	                              Val PriceIncludesVAT,
								  QuantityName = "NumberOfPackages") Export
	
	AmountWithoutADiscount = CurRow.Price * CurRow[QuantityName];
	DiscountedAmount = AmountWithoutADiscount;   
	
	If RecalculateManualDiscount Then
		If  CurRow.PercentRateOfManualDiscount <> 0 Then
			CurRow.ManualDiscount = AmountWithoutADiscount * CurRow.PercentRateOfManualDiscount / 100;
			DiscountedAmount              = DiscountedAmount - CurRow.ManualDiscount;
		EndIf;
	EndIf;
		
	If RecalculateAutomaticDiscount Then
		
		If ClearingAutomaticDiscount Then
			
			CurRow.PercentRateOfAutomaticDiscountMarkup = 0;
			CurRow.DiscountMarkupAmount   = 0;
			
		ElsIf CurRow.PercentRateOfAutomaticDiscountMarkup <> 0 Then
			
			CurRow.DiscountMarkupAmount = AmountWithoutADiscount * CurRow.PercentRateOfAutomaticDiscountMarkup / 100;
			DiscountedAmount                      = DiscountedAmount - CurRow.DiscountMarkupAmount;
			
		EndIf;
		
	EndIf;
	
	CurRow.Sum    = DiscountedAmount;
	CurRow.VATAmount = PriceManagementSystemClientServer.CalculateVATAmount(CurRow.Sum, CurRow.VATRate, PriceIncludesVAT);
	CurRow.AmountIncludingVAT = CurRow.Sum + ?(PriceIncludesVAT, 0, CurRow.VATAmount);
	
EndProcedure // Recalculate the sum of the line()

// Calculates the amount details of the row on the basis of the requisite "Commands"
//
// Parameters:
//  TableRow - LineOfATabularSection -  Line in the table part of the Goods document
//  PriceIncludesVAT - Boolean - Whether VAT is included in the price in the document
//  AutomaticDiscount - Boolean - True if the document contains automatic discounts
//  ManualDiscount - Boolean - True if the document contains manual discounts
//  RecalculatePrice - Boolean - True if you need to recalculate the price.
//  QuantityName - String - Name of the quantity field.
//  VATRate - CatalogRef.VATRates, Undefined - VAT rate. Used if the Attribute of the same name is not in the line.
//
Procedure RecalculateAmountsInRowWithVAT(
	TableRow,
	Val PriceIncludesVAT,
	Val AutomaticDiscount,
	Val ManualDiscount,
	Val RecalculatePrice = False,
	QuantityName = "NumberOfPackages",
	VATRate = Undefined) Export
	
	If ValueIsFilled(VATRate) Then
		VATRateByNumber = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
	Else
		VATRateByNumber = VATAccountingERPClientServer.ValueOfVATRate(TableRow.VATRate);
	EndIf;
	
	If ValueIsFilled(TableRow.AmountIncludingVAT) Then
		TableRow.VATAmount = Round(TableRow.AmountIncludingVAT * (VATRateByNumber/(100+VATRateByNumber)), 2);
		TableRow.Sum = TableRow.AmountIncludingVAT - ?(PriceIncludesVAT, 0, TableRow.VATAmount);
		
		TotalDiscountPercentage = ?(AutomaticDiscount,TableRow.PercentRateOfAutomaticDiscountMarkup, 0)
			+ ?(ManualDiscount, TableRow.PercentRateOfManualDiscount, 0);
		
		AmountWithoutADiscount = ?(TotalDiscountPercentage=0, TableRow.Sum, TableRow.Sum * 100 / (100-TotalDiscountPercentage));
	Else
		If TableRow.Count = 0 Then
			Return;
		EndIf;
		
		AmountWithoutADiscount = TableRow.Price*TableRow[QuantityName];
	EndIf;
	
	If AutomaticDiscount Then
		TableRow.DiscountMarkupAmount = Round(AmountWithoutADiscount*TableRow.PercentRateOfAutomaticDiscountMarkup/100, 2);
	EndIf;
	
	If ManualDiscount Then
		TableRow.ManualDiscount = Round(AmountWithoutADiscount*TableRow.PercentRateOfManualDiscount/100, 2);
	EndIf;
	
	If RecalculatePrice And TableRow[QuantityName] <> 0 Then
		TableRow.Price = AmountWithoutADiscount / TableRow[QuantityName];
	EndIf;
	
EndProcedure // Recalculate the sum of the rows of the Sums()

// Converts prices and amounts in PM Goods from currency to currency
//
// Parameters:
//  Document                           - DocumentObject - The document for which you want to convert
//  OldCurrency                       - CatalogRef.Currencies - The currency from which you want to recalculate the price 
//  NewCurrency                        - CatalogRef.Currencies - The currency in which you want to recalculate the price
//  StructureOfOldCurrencyRates        - Structure - The rate and multiplicity of the currency from which prices should be recalculated
//  StructureOfNewCurrencyRates         - Structure - Exchange rate and multiplicity of the currency to convert prices to
//  AmountsRecalculate                 - Boolean - Flag that specifies whether the Sum and Summands fields should be recalculated
//  RecalculateAutomaticDiscounts  - Boolean - Flag indicating whether automatic discounts should be recalculated
//  RecalculateManualDiscounts          - Boolean - Flag that specifies whether manual discounts should be recalculated.
//
Procedure ConvertAmountsToCurrencyProducts(Document,
	                                    Val OldCurrency,
	                                    Val NewCurrency,
	                                    Val StructureOfOldCurrencyRates,
	                                    Val StructureOfNewCurrencyRates,
	                                    Val AmountsRecalculate = True,
	                                    Val RecalculateAutomaticDiscounts = False,
	                                    Val RecalculateManualDiscounts = False
										) Export
	
	For Each CurRow In Document.Goods Do
		
		CurRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
			CurRow.Price,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates);
		
		If AmountsRecalculate Then
			RecalculateAmountsInRow(
				CurRow,
				RecalculateAutomaticDiscounts,
				False,
				RecalculateManualDiscounts,
				Document.PriceIncludesVAT);
		EndIf;
		
	EndDo;
	
EndProcedure // Recalculate the sum of the cryptocurrencies()

// Deprecated. Recalculates prices and amounts in TS of Goods from currency to currency.
// Use Pricing.Recalculate the sum of the table in the currency
//
// Parameters:
//  Table                            - TabularSection -  The table in which it is necessary to recalculate
//  PriceIncludesVAT                    - Boolean - True if the price includes VAT
//  OldCurrency                       - CatalogRef.Currencies - The currency from which you want to recalculate the price 
//  NewCurrency                        - CatalogRef.Currencies - The currency in which you want to recalculate the price
//  StructureOfOldCurrencyRates        - Structure - The rate and multiplicity of the currency from which prices should be recalculated
//  StructureOfNewCurrencyRates         - Structure - Exchange rate and multiplicity of the currency to convert prices to
//  RecalculateAutomaticDiscounts  - Boolean - Flag indicating whether automatic discounts should be recalculated
//  RecalculateManualDiscounts          - Boolean - Flag that specifies whether manual discounts should be recalculated.
//  QuantityName                      - String - Name of the quantity field.
//
Procedure ConvertTabularAmountsToCurrency(
	Table,
	PriceIncludesVAT,
	Val OldCurrency,
	Val NewCurrency,
	Val StructureOfOldCurrencyRates,
	Val StructureOfNewCurrencyRates,
	Val RecalculateAutomaticDiscounts = False,
	Val RecalculateManualDiscounts = False,
	QuantityName="NumberOfPackages") Export
	
	RecalculationParameters = ParametersForConvertingTableAmountsToCurrency(PriceIncludesVAT, OldCurrency, NewCurrency);
	RecalculationParameters.StructureOfOldCurrencyRates       = StructureOfOldCurrencyRates;
	RecalculationParameters.StructureOfNewCurrencyRates        = StructureOfNewCurrencyRates;
	RecalculationParameters.RecalculateAutomaticDiscounts = RecalculateAutomaticDiscounts;
	RecalculationParameters.RecalculateManualDiscounts         = RecalculateManualDiscounts;
	RecalculationParameters.QuantityName                     = QuantityName;
	
	ConvertTableAmountsToCurrency(Table, RecalculationParameters);
	
EndProcedure // Recalculate the sum of the table part of the currency()

// Converts prices and amounts in PM Goods from currency to currency
//
// Parameters:
//  Table            - TabularSection -  The table in which it is necessary to recalculate
//  RecalculationParameters - See ParametersForConvertingTableAmountsToCurrency
//
Procedure ConvertTableAmountsToCurrency(Table, RecalculationParameters) Export
	
	AmountForAllocation = ProcessingOfExchangeRatesTM.ConvertAtRate(
		Table.Total("AmountIncludingVAT"),
		RecalculationParameters.StructureOfOldCurrencyRates,
		RecalculationParameters.StructureOfNewCurrencyRates);
	
	ArrayOfAmounts = New Array;
	For N1 = 0 To Table.Count()-1 Do
		
		CurRow = Table[N1];
		CurRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
			CurRow.Price,
			RecalculationParameters.StructureOfOldCurrencyRates,
			RecalculationParameters.StructureOfNewCurrencyRates);
		ArrayOfAmounts.Add(
			ProcessingOfExchangeRatesTM.ConvertAtRate(
				CurRow.AmountIncludingVAT,
				RecalculationParameters.StructureOfOldCurrencyRates,
				RecalculationParameters.StructureOfNewCurrencyRates));
	EndDo;
	
	ArrayOfAmounts = Common.DistributeAmountInProportionToCoefficients(AmountForAllocation, ArrayOfAmounts);
	
	If ArrayOfAmounts <> Undefined Then
		
		For N1 = 0 To Table.Count()-1 Do
			
			CurRow = Table[N1];
			CurRow.AmountIncludingVAT = ArrayOfAmounts[N1];
			
			RecalculateAmountsInRowWithVAT(
				CurRow,
				RecalculationParameters.PriceIncludesVAT,
				RecalculationParameters.RecalculateAutomaticDiscounts,
				RecalculationParameters.RecalculateManualDiscounts,
				True,
				RecalculationParameters.QuantityName,
				RecalculationParameters.VATRate);
			
		EndDo;
		
	EndIf;
	
EndProcedure // Recalculate the sum of the table part of the currency()

// Recalculates prices and amounts in TS Goods after editing the exchange rate
//
// Parameters:
//  Table            - TabularSection -  The table in which it is necessary to recalculate
//  RecalculationParameters - See ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate
//
Procedure RecalculateTableAmountsONChangeOfExchangeRate(Table, RecalculationParameters) Export
	
	If Table.Total("AmountIncludingVAT") = 0 Then
		Return;
	EndIf;
	
	ConversionFactor_ = RecalculationParameters.NewAmountOfDocumentWithVAT / Table.Total("AmountIncludingVAT");
	
	ArrayOfAmounts = New Array;
	For N1 = 0 To Table.Count()-1 Do
		
		CurRow = Table[N1];
		CurRow.Price = Round(CurRow.Price * ConversionFactor_, 2);
		ArrayOfAmounts.Add(Round(CurRow.AmountIncludingVAT * ConversionFactor_, 2));
		
	EndDo;
	
	If Not RecalculationParameters.AmountsRecalculate Then
		Return
	EndIf;
	
	ArrayOfAmounts = Common.DistributeAmountInProportionToCoefficients(RecalculationParameters.NewAmountOfDocumentWithVAT, ArrayOfAmounts);
	
	If ArrayOfAmounts <> Undefined Then
		
		For N1 = 0 To Table.Count()-1 Do
			
			CurRow = Table[N1];
			CurRow.AmountIncludingVAT = ArrayOfAmounts[N1];
			
			RecalculateAmountsInRowWithVAT(
				CurRow,
				RecalculationParameters.PriceIncludesVAT,
				RecalculationParameters.RecalculateAutomaticDiscounts,
				RecalculationParameters.RecalculateManualDiscounts,
				True,
				RecalculationParameters.QuantityName,
				RecalculationParameters.VATRate);
			
		EndDo;
		
	EndIf;
	
EndProcedure // Recalculate the sum of the table part of the currency()

// Parameters for converting table amounts to currency.
// 
// Parameters:
//  PriceIncludesVAT - Boolean - True if the price includes VAT
//  OldCurrency    - CatalogRef.Currencies - The currency from which you want to recalculate the price
//  NewCurrency     - CatalogRef.Currencies - The currency in which you want to recalculate the price
//  DocumentDate   - Date - Document date
//  BaseCurrency     - CatalogRef.Currencies - The currency against which the exchange rate was received
// 
// Returns:
//  Structure - LongDesc:
// * PriceIncludesVAT                    - Boolean - True if the price includes VAT
// * OldCurrency                       - CatalogRef.Currencies - The currency from which you want to recalculate the price
// * NewCurrency                        - CatalogRef.Currencies - The currency in which you want to recalculate the price
// * RecalculateAutomaticDiscounts  - Boolean - Flag indicating whether automatic discounts should be recalculated
// * RecalculateManualDiscounts          - Boolean - Flag that specifies whether manual discounts should be recalculated
// * QuantityName                      - String - Field Name Quantity
// * VATRate                          - CatalogRef.VATRates - the VAT rate common to all rows in the table
// * StructureOfOldCurrencyRates        - Structure of See ProcessingOfExchangeRatesTM.CurrencyExchangeRateStructure - The rate and multiplicity of the currency from which prices should be recalculated
// * StructureOfNewCurrencyRates         - Structure of See ProcessingOfExchangeRatesTM.CurrencyExchangeRateStructure - Exchange rate and multiplicity of the currency to convert prices to
Function ParametersForConvertingTableAmountsToCurrency(PriceIncludesVAT, OldCurrency, NewCurrency, DocumentDate = Undefined, BaseCurrency = Undefined) Export
	
	RecalculationParameters = New Structure;
	RecalculationParameters.Insert("PriceIncludesVAT",                   PriceIncludesVAT);
	RecalculationParameters.Insert("OldCurrency",                      OldCurrency);
	RecalculationParameters.Insert("NewCurrency",                       NewCurrency);
	RecalculationParameters.Insert("RecalculateAutomaticDiscounts", False);
	RecalculationParameters.Insert("RecalculateManualDiscounts",         False);
	RecalculationParameters.Insert("QuantityName",                     "NumberOfPackages");
	RecalculationParameters.Insert("VATRate",                         Catalogs.VATRates.EmptyRef());
	
	If ValueIsFilled(DocumentDate) Then
		RecalculationParameters.Insert("StructureOfOldCurrencyRates", ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate, BaseCurrency));
		RecalculationParameters.Insert("StructureOfNewCurrencyRates",  ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate, BaseCurrency));
	Else
		RecalculationParameters.Insert("StructureOfOldCurrencyRates", New Structure);
		RecalculationParameters.Insert("StructureOfNewCurrencyRates",  New Structure);
	EndIf;
	
	Return RecalculationParameters;
	
EndFunction

// Parameters for recalculation of table amounts on change of the exchange rate.
// 
// Parameters:
//  PriceIncludesVAT         - Boolean - True if the price includes VAT.
//  NewAmountOfDocumentWithVAT - Number  - The calculated amount in the document currency.
//  QuantityName           - String - Name of the quantity field.
//  AmountsRecalculate      - Boolean - Flag that specifies whether to recalculate the Sum and SummaNDS fields.
// 
// Returns:
//  Structure:
// * PriceIncludesVAT                   - Boolean - True if the price includes VAT.
// * NewAmountOfDocumentWithVAT           - Number  - The calculated amount in the document currency.
// * AmountsRecalculate                - Boolean - Flag that specifies whether to recalculate the Sum and SummaNDS fields.
// * RecalculateAutomaticDiscounts - Boolean - Flag that specifies whether automatic discounts should be recalculated.
// * RecalculateManualDiscounts         - Boolean - Flag that specifies whether manual discounts should be recalculated.
// * QuantityName                     - String - Name of the quantity field.
// * VATRate                         - CatalogRef.VATRates - the VAT rate common to all rows in the table.
Function ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(PriceIncludesVAT, NewAmountOfDocumentWithVAT, QuantityName = "NumberOfPackages", AmountsRecalculate = True) Export
	
	RecalculationParameters = New Structure;
	RecalculationParameters.Insert("PriceIncludesVAT",                   PriceIncludesVAT);
	RecalculationParameters.Insert("NewAmountOfDocumentWithVAT",           NewAmountOfDocumentWithVAT);
	RecalculationParameters.Insert("RecalculateAutomaticDiscounts", False);
	RecalculationParameters.Insert("RecalculateManualDiscounts",         False);
	RecalculationParameters.Insert("QuantityName",                     QuantityName);
	RecalculationParameters.Insert("VATRate",                         Catalogs.VATRates.EmptyRef());
	RecalculationParameters.Insert("AmountsRecalculate",                AmountsRecalculate);
	
	Return RecalculationParameters;
	
EndFunction

// Converts amounts in PM stages of payment Graphy from currency to currency
//
// Parameters:
//  Document - DocumentObject - The document for which you want to convert
//  AmountToDistributePayment - Number - The amount of the document to be distributed to the payment stages
//  AmountForDistributionOfCollateral - Number - The amount of the Deposit according to the document that must be distributed to the payment stages.
//
Procedure DistributeAmountByPaymentStages(Document, Val AmountToDistributePayment, Val AmountForDistributionOfCollateral) Export
	
	NumberOfPaymentStages    = Document.PaymentScheduleSteps.Count();
	PercentageOfPaymentByStages     = Document.PaymentScheduleSteps.Total("PaymentPercentage");
	If Document.PaymentScheduleSteps.Unload().Columns.Find("PackageDepositPercentage") <> Undefined Then
		PercentageOfCollateralByStages = Document.PaymentScheduleSteps.Total("PackageDepositPercentage");
	Else
		PercentageOfCollateralByStages = 0
	EndIf;
	StageNumber                = 1;
	DistributedPaymentAmount = 0;
	DistributedAmountOfCollateral = 0;
	
	If NumberOfPaymentStages = 0 Or PercentageOfPaymentByStages = 0 Or PercentageOfCollateralByStages = 0 Then
		Return;
	EndIf;
	
	For Each CurStage In Document.PaymentScheduleSteps Do
		
		ThisIsLastStage = PercentageOfPaymentByStages = 100 And PercentageOfCollateralByStages = 100 And NumberOfPaymentStages = StageNumber;
		
		If ThisIsLastStage Then
			CurStage.PaymentAmount      = AmountToDistributePayment - DistributedPaymentAmount;
			CurStage.PackageDepositValue = AmountForDistributionOfCollateral - DistributedAmountOfCollateral;
		Else
			CurStage.PaymentAmount       = Round(AmountToDistributePayment * CurStage.PaymentPercentage / 100, 2, RoundMode.Round15as20);
			CurStage.PackageDepositValue  = Round(AmountForDistributionOfCollateral * CurStage.PackageDepositPercentage / 100, 2, RoundMode.Round15as20);
			DistributedPaymentAmount  = DistributedPaymentAmount + CurStage.PaymentAmount;
			DistributedAmountOfCollateral  = DistributedAmountOfCollateral + CurStage.PackageDepositValue;
			StageNumber                 = StageNumber + 1;
		EndIf;
		
	EndDo;
	
EndProcedure // Distribute the sum of these Self-payments()

// Deprecated.
// Performs recalculation on the filled-in fields of "Summation of settlements" in the specified tabular part.
//
// Parameters:
//	Document          - DocumentObject - The document object for which the settlement amounts 
//											in the product part are recalculated.
//	TabularSectionName - String         - Name of the table part of the document object.
//	RateStructure    - Structure      - Currency exchange rate data.
//	Date              - Date           - The date on which the calculation is performed.
//	VATIsUsed   - Boolean         - The truth is a Sign, in the presence of the commodity the amount of details, including VAT.
//
Procedure CalculateAmountsOfSettlementsInTablePart(Document,
							TabularSectionName,
							RateStructure = Undefined,
							Date = Undefined,
							VATIsUsed = True) Export
	
	TabularSection = Document[TabularSectionName];
	
	DocumentCurrency = Document.Currency;
	OrderCurrency = Document.ARAPCurrency;
	
	If DocumentCurrency = OrderCurrency Then
		
		For IndexOf = 0 To TabularSection.Count()-1 Do
			If VATIsUsed Then
				If Not ValueIsFilled(TabularSection[IndexOf].AmountARAP)
					Or TabularSection[IndexOf].AmountARAP <> TabularSection[IndexOf].AmountIncludingVAT Then
					
					TabularSection[IndexOf].AmountARAP = TabularSection[IndexOf].AmountIncludingVAT;
					
				EndIf;
			Else
				If Not ValueIsFilled(TabularSection[IndexOf].AmountARAP)
					Or TabularSection[IndexOf].AmountARAP <> TabularSection[IndexOf].Sum Then
					
					TabularSection[IndexOf].AmountARAP = TabularSection[IndexOf].Sum;
					
				EndIf;
			EndIf;
		EndDo;
		
	Else
		
		AmountOfMutualSettlementsForTS = TabularSection.Total("AmountARAP");
		
		If TabularSection.FindRows(New Structure("AmountARAP", 0)).Count() = 0
			And (Document.AmountARAP = AmountOfMutualSettlementsForTS
				Or (Document.AmountARAP < AmountOfMutualSettlementsForTS And AmountOfMutualSettlementsForTS > 0)) Then
			Return;
		EndIf;
		
		If Not ValueIsFilled(Date) Then
			Date = ?(ValueIsFilled(Document.Date), Document.Date,CurrentSessionDate());
		EndIf;
		
		// Getting the conversion factor into the order currency
		ConversionFactorToOrderCurrency = 1;
		If ValueIsFilled(RateStructure) And TypeOf(RateStructure) = Type("Structure") And RateStructure.Rate > 0 Then
			ComplAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Document.Organization);
			
			If Not OrderCurrency = ComplAccountingCurrency And DocumentCurrency = ComplAccountingCurrency Then
				ConversionFactorToOrderCurrency = RateStructure.CourseDenominator/RateStructure.CourseNumerator;
			Else
				ConversionFactorToOrderCurrency = RateStructure.CourseNumerator*RateStructure.CourseDenominator;
			EndIf;
			
		Else
			Query = New Query(
			"SELECT
			|	ISNULL(DocumentExchangeRate.CourseNumerator, 1) *
			|	ISNULL(OrderCurrencyRate.CourseDenominator, 1) /
			|	(ISNULL(OrderCurrencyRate.CourseNumerator, 1) *
			|	ISNULL(DocumentExchangeRate.CourseDenominator, 1)) AS ConversionFactor_
			|FROM
			|	InformationRegister.RelativeExchangeRates.SliceLast(&OnDate, Currency = &DocumentCurrency AND BaseCurrency = &BaseCurrency) AS DocumentExchangeRate
			|		LEFT JOIN RelativeExchangeRates.ExchangeRates.SliceLast(&OnDate, Currency = &OrderCurrency AND BaseCurrency = &BaseCurrency) AS OrderCurrencyRate
			|		ON (TRUE)");
			Query.SetParameter("DocumentCurrency", DocumentCurrency);
			Query.SetParameter("OrderCurrency", OrderCurrency);
			Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Document.Organization));
			Query.SetParameter("OnDate", Date);
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				ConversionFactorToOrderCurrency = Selection.ConversionFactor_;
			EndIf;
		EndIf;
		
		// The amount that should be distributed over the tabular part
		// 		will be obtained from the difference between the total amount of settlements
		// 		and the total for the filled values of the column "Sum of settlements".
		AmountForAllocation = Document.AmountARAP - AmountOfMutualSettlementsForTS;
		ArrayOfAmounts = New Array;
		For IndexOf = 0 To TabularSection.Count()-1 Do
			If Not ValueIsFilled(TabularSection[IndexOf].AmountARAP) Then
				If VATIsUsed Then
					ArrayOfAmounts.Add(Round(TabularSection[IndexOf].AmountIncludingVAT * ConversionFactorToOrderCurrency, 2));
				Else
					ArrayOfAmounts.Add(Round(TabularSection[IndexOf].Sum * ConversionFactorToOrderCurrency, 2));
				EndIf;
			EndIf;
		EndDo;
		
		ArrayOfAmounts = Common.DistributeAmountInProportionToCoefficients(AmountForAllocation, ArrayOfAmounts);
		
		IndexOfSumArray = 0;
		If ArrayOfAmounts <> Undefined Then
			For IndexOf=0 To TabularSection.Count()-1 Do
				If Not ValueIsFilled(TabularSection[IndexOf].AmountARAP) Then
					TabularSection[IndexOf].AmountARAP = ArrayOfAmounts[IndexOfSumArray];
					IndexOfSumArray = IndexOfSumArray + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForServicingTypesOfPricesFilledInAccordingToInformationSecurityData

// Returns the names and types of fields that must be present.
// in the SKD used for filling in prices based on information security data.
//
// Returns:
//	 Map - The keys contain the names of the fields. In values - field types.
//
Function GetRequiredDataLayoutSchemaFields(UsePriceManagementSystem25 = False) Export
	
	Fields = New Map;
	
	Fields.Insert("Products", New TypeDescription("CatalogRef.Products"));
	
	If UsePriceManagementSystem25 Then
		
		If GetFunctionalOption("UseItemVariants") Then
			Fields.Insert("PricingVariant", 	New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));
		EndIf;
		
		If GetFunctionalOption("UseItemPackages") Then
			Fields.Insert("TsoPackagingForCommunication", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
			Fields.Insert("Package", 			New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
			Fields.Insert("ZoomRatio", 		New TypeDescription("Number"));
		EndIf;
		
		If GetFunctionalOption("UseItemsBatch") Then
			Fields.Insert("TSOSeriesForCommunication", 	New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
		EndIf;
		
	Else
		
		If GetFunctionalOption("UseItemVariants") Then
			Fields.Insert("Characteristic", 	New TypeDescription("CatalogRef.ItemsCharacteristics"));
		EndIf;
		
		If GetFunctionalOption("UseItemPackages") Then
			Fields.Insert("Package", 			New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
			Fields.Insert("ZoomRatio", 		New TypeDescription("Number"));
		EndIf;
		
	EndIf;
	
	Fields.Insert("Price",   New TypeDescription("Number"));
	Fields.Insert("Currency", New TypeDescription("CatalogRef.Currencies"));
	
	Return Fields;
	
EndFunction

// Checks the data layout scheme for compliance with the restrictions required
// for its use in calculating prices.
//
// Parameters:
//  DataCompositionSchema - DataCompositionSchema - The schema to check.
//  ErrorMessage     - String - contains the introductory part of the error message.
//  OutputMessages   - Boolean - True - do not output messages to the user, only checking.
//
// Returns:
//  Boolean - True if the check is passed successfully.
//
Function CheckDataLayoutScheme(DataCompositionSchema, ErrorMessage = Undefined, OutputMessages = True) Export
	
	Fields = GetRequiredDataLayoutSchemaFields();
	
	Return CheckDataLayoutSchemeForRequiredFields(DataCompositionSchema, Fields, ErrorMessage, OutputMessages);
	
EndFunction

// Checks the data layout scheme for compliance with the restrictions required
// for its use in calculating prices.
//
// Parameters:
//  DataCompositionSchema - DataCompositionSchema - The schema to check.
//  ErrorMessage     - String - contains the introductory part of the error message.
//  OutputMessages   - Boolean - True - do not output messages to the user, only checking.
//
// Returns:
//  Boolean - True if the check is passed successfully.
//
Function CheckDataLayoutScheme2_5(DataCompositionSchema, ErrorMessage = Undefined, OutputMessages = True) Export
	
	Fields = GetRequiredDataLayoutSchemaFields(True);
	
	Return CheckDataLayoutSchemeForRequiredFields(DataCompositionSchema, Fields, ErrorMessage, OutputMessages);
	
EndFunction

// Checks the data layout scheme for compliance with the restrictions required
// for its use in calculating prices.
//
// Parameters:
//  DataCompositionSchema - DataCompositionSchema - The schema to check.
//  Fields - See GetRequiredDataLayoutSchemaFields
//  ErrorMessage     - String - A string that contains the introductory part of the error message.
//  OutputMessages   - Boolean - True - do not output messages to the user, only checking.
//
// Returns:
//  Boolean - True if the check is passed successfully.
//
Function CheckDataLayoutSchemeForRequiredFields(DataCompositionSchema, Fields, ErrorMessage = Undefined, OutputMessages = True) Export
	
	Result = True;
	
	If DataCompositionSchema <> Undefined And TypeOf(DataCompositionSchema) = Type("DataCompositionSchema") And DataCompositionSchema.DataSets.Count() = 1 Then
		
		WorkingDataset = DataCompositionSchema.DataSets[0];
		
		For Each Field In Fields Do
			If Not CheckDCSDataSetField(WorkingDataset, Field.Key, Field.Value, ErrorMessage, OutputMessages) Then
				Result = False;
			EndIf;
		EndDo;
		
	ElsIf OutputMessages Then 
		
		CommonClientServer.MessageToUser(?(ValueIsFilled(ErrorMessage), ErrorMessage + ": ", "") 
			+ NStr("vi = 'Sơ đồ dàn dựng dữ liệu để điền đơn giá phải có một tập hợp dữ liệu.';
					|ru = 'Схема компоновки данных для заполнения цен должна содержать один набор данных.';
					|en = 'Data composition schema used to fill in prices should contain one data set.'; fa = 'Data composition schema used to fill in prices should contain one data set.';
					|it = 'Lo schema di composizione dei dati per la compilazione dei prezzi deve contenere un set di dati.';
					|pl = 'Schemat składu danych do wypełniania cen powinien zawierać jeden zestaw danych.';
					|tr = 'Fiyatların doldurulması için veri inşa edilme şemasının tek bir veri kümesi içermesi gerekmektedir.'"));
		Result = False;
	Else
		
		Result = False;
		
	EndIf;
	
	Return Result;
	
EndFunction


// Allows you to check the correctness of the price types scheme, correct errors if necessary,
// and fill in a list of critical errors that the user will need to correct.
//
// Parameters:
//   DataCompositionSchema - DataCompositionSchema - Scheme of price types.
//   SchemeContainsCriticalErrors - Boolean - a flag for critical errors that must
//   				be raised so that the user cannot apply the schema until the errors are fixed.
//   ListOfCriticalErrors - ValueList - A list containing the texts of critical error messages.
//   ListOfOtherMessages - ValueList - A list containing the texts of messages about fixed errors and other comments.
//   				This list of messages is displayed to the user once.
//
Procedure CheckingCorrectnessOfPriceTypeScheme(DataCompositionSchema, SchemeContainsCriticalErrors,
					ListOfCriticalErrors, ListOfOtherMessages) Export

	Fields = GetRequiredDataLayoutSchemaFields();
	
	ErrorMessage = "";
	OutputMessages = False;
	
	Result = CheckDataLayoutSchemeForRequiredFields(DataCompositionSchema, Fields, ErrorMessage, OutputMessages);
	
	If Not Result Then
		SchemeContainsCriticalErrors = True;
		ErrorText = NStr("vi = 'Sơ đồ bị lỗi và không thể áp dụng.';
						|ru = 'Схема содержит ошибки и не может быть применена.';
						|en = 'The schema contains errors and cannot be applied.'; fa = 'The schema contains errors and cannot be applied.';
						|it = 'Lo schema contiene errori e non può essere applicato.';
						|pl = 'Schemata zawiera błędy i nie może być zastosowany.';
						|tr = 'Şema hatalar içermektedir ve uygulanamaz.'");
		ListOfCriticalErrors.Add(ErrorText);
		If Not IsBlankString(ErrorMessage) Then
			ListOfCriticalErrors.Add(ErrorMessage);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ProceduresForGeneratingRequestsCheckingPriceRegistration

// Generates a request for creating a temporary price table
//
// Parameters:
//  QueryText - String - text string to which you want to add the query text
//  QueryOptions - Structure - structure containing request parameters
//  PriceTree - ValueTable - the price table that you need to create a request for.
//
Procedure GenerateTemporaryPriceTableQueryForRegisteringPrices(QueryText,
	                                                             QueryOptions,
	                                                             PriceTree)
	
	QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.LineNumber      AS LineNumber,
		|	TemporaryTableOfGoods_.Products     AS Products,
		|	TemporaryTableOfGoods_.Characteristic   AS Characteristic,
		|	TemporaryTableOfGoods_.IsFolder        AS IsFolder
		|INTO
		|	TemporaryTableOfGoods_
		|FROM
		|	&PriceTree AS TemporaryTableOfGoods_
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|";
		
	QueryOptions.Insert("PriceTree", PriceTree);
	
EndProcedure // Form a timestamp table for registration()

// Generates a query for creating a temporary price table without duplicate rows
//
// Parameters:
//  QueryText - String - text string to which you want to add the query text
//
Procedure CreateTemporaryPriceTableQueryWithoutDuplicatesForRegisteringPrices(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	MAX(TemporaryTableOfGoods_.LineNumber) AS LineNumber,
		|	TemporaryTableOfGoods_.Products          AS Products,
		|	TemporaryTableOfGoods_.Characteristic        AS Characteristic
		|INTO
		|	TemporaryTableProductsWithoutDuplicates
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|GROUP BY
		|	Products,
		|	CHARACTERISTIC
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|";
	
EndProcedure // Form a timestamp table for registration()

// Generates a request to check whether there is an empty item in the price table
//
// Parameters:
//  QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateProductCorrectnessRequestForPriceRegistration(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	DocumentGoods.LineNumber    AS LineNumber,
		|	DocumentGoods.Products   AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.IsFolder      AS IsFolder,
		|	CASE
		|		WHEN
		|			DocumentGoods.Products = VALUE(Catalog.Products.EmptyRef)
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsInFillingInProductList,
		|	CASE
		|		WHEN
		|			DocumentGoods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|			AND NOT DocumentGoods.IsFolder
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsFillingInCharacteristics
		|FROM
		|	TemporaryTableOfGoods_ AS DocumentGoods
		|WHERE
		|	DocumentGoods.Products = VALUE(Catalog.Products.EmptyRef)
		|	OR (DocumentGoods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|	AND NOT DocumentGoods.IsFolder)
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
	
EndProcedure // Formationprojection of goods for registration()

// Generates a request to check whether there are duplicates of filling in the price table
//
// Parameters:
//  QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForDuplicatesToRegisterPrices(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	MAX(DocumentGoods.LineNumber)    AS LineNumber,
		|	DocumentGoods.Products             AS Products,
		|	DocumentGoods.Characteristic           AS Characteristic
		|FROM
		|	TemporaryTableOfGoods_ AS DocumentGoods
		|WHERE
		|	DocumentGoods.Products <> VALUE(Catalog.Products.EmptyRef)
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic
		|HAVING
		|	COUNT (*) > 1
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
	
EndProcedure // To form a request for a payment for a registration()

// Generates a request to check the availability of previously registered prices
//
// Parameters:
//  QueryText          - String - text string to which you want to add the query text
//  QueryOptions      - Structure - structure containing request parameters
//  PriceSettingDocument  - DocumentObject.PriceSetup - document to make a request for
//  TypesOfPrices               - Array - array of price types for checking the availability of previously set prices.
//
Procedure GenerateRequestForAvailabilityOfSetPricesForPriceRegistration(QueryText,
	                                                                 QueryOptions,
	                                                                 PriceSettingDocument,
	                                                                 TypesOfPrices)
	
	Text =
	"SELECT
	|	DATEDIFF(BEGINOFPERIOD(ItemsPrices.Period, DAY), ItemsPrices.Period, SECOND)+1 AS RoomWithinADay,
	|	TemporaryTableOfGoods_.LineNumber  AS LineNumber,
	|	ItemsPrices.Products       AS Products,
	|	ItemsPrices.Characteristic     AS Characteristic,
	|	&PriceTypeField                        AS PriceKind
	|FROM
	|	&Table AS ItemsPrices
	|LEFT JOIN
	|	TemporaryTableProductsWithoutDuplicates AS TemporaryTableOfGoods_
	|ON
	|	ItemsPrices.Products = TemporaryTableOfGoods_.Products
	|	AND ItemsPrices.Characteristic = TemporaryTableOfGoods_.Characteristic
	|
	|WHERE
	|	ItemsPrices.Period = &DocumentDate
	|	AND ItemsPrices.Recorder <> &SettingPrices
	|	AND (ItemsPrices.Products, ItemsPrices.Characteristic) IN
	|		(SELECT DISTINCT
	|			DocumentGoods.Products   AS Products,
	|			DocumentGoods.Characteristic AS Characteristic
	|		FROM
	|			TemporaryTableOfGoods_ AS DocumentGoods)
	|	AND &PriceTypeField IN (&TypesOfPrices)
	|;
	|";
	
	If TypeOf(PriceSettingDocument.Ref) = Type("DocumentRef.PriceSetup") Then
		Text = StrReplace(Text, "&Table", "InformationRegister.ItemsPrices");
		Text = StrReplace(Text, "&PriceTypeField", "ItemsPrices.PriceKind");
	Else
		Text = StrReplace(Text, "&Table", "InformationRegister.ItemsPricesOfVendor");
		Text = StrReplace(Text, "&PriceTypeField", "ItemsPrices.VendorPriceKind");
	EndIf;
	
	QueryText = QueryText + Text;
	
	QueryOptions.Insert("SettingPrices",  PriceSettingDocument.Ref);
	QueryOptions.Insert("DocumentDate", PriceSettingDocument.Date);
	QueryOptions.Insert("TypesOfPrices",       TypesOfPrices);
	
EndProcedure

#EndRegion

#Region ProceduresForGeneratingRequestsCheckingPriceRegistration2_5

// Generates a request for creating a temporary price table
//
// Parameters:
//  QueryText - String - text string to which you want to add the query text
//  QueryOptions - Structure - structure containing request parameters
//  PriceTree - ValueTable - the price table that you need to create a request for.
//
Procedure GenerateTemporaryPriceTableQueryForRegisteringPrices2_5(QueryText,
	                                                             QueryOptions,
	                                                             PriceTree)
	
	QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.LineNumber      AS LineNumber,
		|	TemporaryTableOfGoods_.Products     AS Products,
		|	TemporaryTableOfGoods_.PricingVariant AS PricingVariant,
		|	TemporaryTableOfGoods_.IsFolder        AS IsFolder
		|INTO
		|	TemporaryTableOfGoods_
		|FROM
		|	&PriceTree AS TemporaryTableOfGoods_
		|INDEX BY
		|	Products,
		|	PricingVariant
		|;
		|";
		
	QueryOptions.Insert("PriceTree", PriceTree);
	
EndProcedure // Form a timestamp table for registration()

// Generates a query for creating a temporary price table without duplicate rows
//
// Parameters:
//  QueryText - String - text string to which you want to add the query text
//
Procedure CreateTemporaryPriceTableQueryWithoutDuplicatesForRegisteringPrices2_5(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	MAX(TemporaryTableOfGoods_.LineNumber) AS LineNumber,
		|	TemporaryTableOfGoods_.Products          AS Products,
		|	TemporaryTableOfGoods_.PricingVariant      AS PricingVariant
		|INTO
		|	TemporaryTableProductsWithoutDuplicates
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|GROUP BY
		|	Products,
		|	PricingVariant
		|INDEX BY
		|	Products,
		|	PricingVariant
		|;
		|";
	
EndProcedure // Form a timestamp table for registration()

// Generates a request to check whether there is an empty item in the price table
//
// Parameters:
//  QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateProductCorrectnessRequestForPriceRegistration2_5(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	DocumentGoods.LineNumber    AS LineNumber,
		|	DocumentGoods.Products   AS Products,
		|	DocumentGoods.PricingVariant AS PricingVariant,
		|	DocumentGoods.IsFolder      AS IsFolder,
		|	CASE
		|		WHEN
		|			DocumentGoods.Products = VALUE(Catalog.Products.EmptyRef)
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsInFillingInProductList,
		|	CASE
		|		WHEN
		|			DocumentGoods.PricingVariant = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|			AND NOT DocumentGoods.IsFolder
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsFillingInCharacteristics
		|FROM
		|	TemporaryTableOfGoods_ AS DocumentGoods
		|WHERE
		|	DocumentGoods.Products = VALUE(Catalog.Products.EmptyRef)
		|	OR (DocumentGoods.PricingVariant = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|	AND NOT DocumentGoods.IsFolder)
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
	
EndProcedure // Formationprojection of goods for registration()

// Generates a request to check whether there are duplicates of filling in the price table
//
// Parameters:
//  QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateRequestForDuplicatesToRegisterPrices2_5(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	MAX(DocumentGoods.LineNumber)    AS LineNumber,
		|	DocumentGoods.Products             AS Products,
		|	DocumentGoods.PricingVariant         AS PricingVariant
		|FROM
		|	TemporaryTableOfGoods_ AS DocumentGoods
		|WHERE
		|	DocumentGoods.Products <> VALUE(Catalog.Products.EmptyRef)
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.PricingVariant
		|HAVING
		|	COUNT (*) > 1
		|ORDER BY
		|	LineNumber ASC
		|;
		|";
	
EndProcedure // To form a request for a payment for a registration()

// Generates a request to check the availability of previously registered prices
//
// Parameters:
//  QueryText          - String - text string to which you want to add the query text
//  QueryOptions      - Structure - structure containing request parameters
//  PriceSettingDocument  - DocumentObject.PriceSetup - document to make a request for
//  TypesOfPrices               - Array - array of price types for checking the availability of previously set prices.
//
Procedure GenerateRequestForAvailabilityOfSetPricesForPriceRegistration2_5(QueryText,
	                                                                 QueryOptions,
	                                                                 PriceSettingDocument,
	                                                                 TypesOfPrices)
	
	Text =
	"SELECT
	|	DATEDIFF(BEGINOFPERIOD(ItemsPrices.Period, DAY), ItemsPrices.Period, SECOND)+1 AS RoomWithinADay,
	|	TemporaryTableOfGoods_.LineNumber  AS LineNumber,
	|	ItemsPrices.Products       AS Products,
	|	ItemsPrices.PricingVariant   AS PricingVariant,
	|	&PriceTypeField                        AS PriceKind
	|FROM
	|	&Table AS ItemsPrices
	|LEFT JOIN
	|	TemporaryTableProductsWithoutDuplicates AS TemporaryTableOfGoods_
	|ON
	|	ItemsPrices.Products = TemporaryTableOfGoods_.Products
	|	AND ItemsPrices.PricingVariant = TemporaryTableOfGoods_.PricingVariant
	|
	|WHERE
	|	ItemsPrices.Period = &DocumentDate
	|	AND ItemsPrices.Recorder <> &SettingPrices
	|	AND (ItemsPrices.Products, ItemsPrices.PricingVariant) IN
	|		(SELECT DISTINCT
	|			DocumentGoods.Products   AS Products,
	|			DocumentGoods.PricingVariant AS PricingVariant
	|		FROM
	|			TemporaryTableOfGoods_ AS DocumentGoods)
	|	AND &PriceTypeField IN (&TypesOfPrices)
	|;
	|";
	
	If TypeOf(PriceSettingDocument.Ref) = Type("DocumentRef.PriceSetup") Then
		Text = StrReplace(Text, "&Table", "InformationRegister.ItemsPrices25");
		Text = StrReplace(Text, "&PriceTypeField", "ItemsPrices.PriceKind");
	Else
		Text = StrReplace(Text, "&Table", "InformationRegister.ItemsPricesOfVendor");
		Text = StrReplace(Text, "&PriceTypeField", "ItemsPrices.VendorPriceKind");
	EndIf;
	
	QueryText = QueryText + Text;
	
	QueryOptions.Insert("SettingPrices",  PriceSettingDocument.Ref);
	QueryOptions.Insert("DocumentDate", PriceSettingDocument.Date);
	QueryOptions.Insert("TypesOfPrices",       TypesOfPrices);
	
EndProcedure

#EndRegion

#Region ProceduresForDisplayingPriceRegistrationErrorMessages

// Displays error messages in the PM Products document Ustanovlennuyu
//
// Parameters:
//  Selection               - QueryResultSelection - 
//  PriceSettingDocument  - DocumentObject.PriceSetup - the document to display
//                                                                    error messages for.
//  UsePriceManagementSystem25  - Boolean - flag for using the new pricing.
//  Cancel                 - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsCorrectnessOfProductsForPriceRegistration(Selection,
	                                                            PriceSettingDocument,
	                                                            UsePriceManagementSystem25,
	                                                            Cancel)
	
	While Selection.Next() Do
		
		If UsePriceManagementSystem25 Then
			Characteristic = "PricingVariant";
		Else
			Characteristic = "Characteristic";
		EndIf;
		
		If Selection.ThereAreErrorsInFillingInProductList Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Mặt hàng"" tại dòng ""%LineNumber%"" của danh sách ""Bảng đơn giá""';
							|ru = 'Не заполнена колонка ""Номенклатура"" в строке ""%LineNumber%"" списка ""Таблица цен""';
							|en = 'Column ""Items"" in line ""%LineNumber%"" of the ""Price table"" list is not filled in'; fa = 'Column ""Items"" in line ""%LineNumber%"" of the ""Price table"" list is not filled in';
							|it = 'Colonna ""Articolo"" nella riga ""%LineNumber%"" dell''elenco ""Tabella dei prezzi"" non compilata';
							|pl = 'Kolumna ""Nomenklatura"" w wierszu ""%LineNumber%"" listy ""Tabela cen"" nie jest wypełniona';
							|tr = '""Fiyat Tablosu"" listesinin ""%LineNumber%"" satırında ""Öğe"" sütunu doldurulmadı'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", Selection.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				PriceSettingDocument.Ref,
				CommonClientServer.PathToTabularSection("PriceTree", Selection.LineNumber, "Products"),
				,
				Cancel);
			
		EndIf;
			
		If Selection.ThereAreErrorsFillingInCharacteristics Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Đặc tính"" tại dòng ""%LineNumber%"" của danh sách ""Bảng đơn giá""';
							|ru = 'Не заполнена колонка ""Характеристика"" в строке ""%LineNumber%"" списка ""Таблица цен""';
							|en = 'Column ""Variant"" in line ""%LineNumber%"" of the ""Price table"" list is not filled in'; fa = 'Column ""Variant"" in line ""%LineNumber%"" of the ""Price table"" list is not filled in';
							|it = 'Colonna ""Caratteristica"" nella riga ""%LineNumber%"" dell''elenco ""Tabella dei prezzi"" non compilata';
							|pl = 'Kolumna ""Charakterystyka"" w wierszu ""%LineNumber%"" listy ""Tabela cen"" nie jest wypełniona';
							|tr = '""Fiyat Tablosu"" listesinin ""%LineNumber%"" satırında ""Varyant"" sütunu doldurulmadı'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", Selection.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				PriceSettingDocument.Ref,
				CommonClientServer.PathToTabularSection("PriceTree", Selection.LineNumber, Characteristic),
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure // Report the error of the correctness of the goods for registration()

// Displays error messages in the PM Products document Ustanovlennuyu
//
// Parameters:
//  Selection               - QueryResultSelection - 
//  PriceSettingDocument  - DocumentObject.PriceSetup - the document to display
//                                                                    error messages for.
//  UsePriceManagementSystem25  - Boolean - flag for using the new pricing.
//  Cancel                 - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsDuplicateProductsForPriceRegistration(Selection,
	                                                             PriceSettingDocument,
	                                                             UsePriceManagementSystem25,
	                                                             Cancel)
	
	While Selection.Next() Do
		
		If UsePriceManagementSystem25 Then
			Characteristic = Selection.PricingVariant;
		Else
			Characteristic = Selection.Characteristic;
		EndIf;
		
		If ValueIsFilled(Characteristic) Then
			
			ErrorText = NStr("vi = 'Mặt hàng ""%Products%"" có đặc tính ""%Characteristic%"" bị lặp lại';
							|ru = 'Номенклатура ""%Products%"" с характеристикой ""%Characteristic%"" повторяется';
							|en = 'Variant ""%Characteristic%"" of item ""%Products%"" is duplicated'; fa = 'Variant ""%Characteristic%"" of item ""%Products%"" is duplicated';
							|it = 'L''articolo ""%Products%"" con la caratteristica ""%Characteristic%"" si ripete';
							|pl = 'Pozycja ""%Products%"" z charakterystyką ""%Characteristic%"" jest powtarzana';
							|tr = '""%Characteristic%"" varyantına sahip ""%Products%"" öğesi tekrarlanmaktadır'");
			ErrorText = StrReplace(ErrorText, "%Products%",   Selection.Products);
			ErrorText = StrReplace(ErrorText, "%Characteristic%", Characteristic);
			
		Else
			
			ErrorText = NStr("vi = 'Mặt hàng ""%Products%"" bị lặp lại';
							|ru = 'Номенклатура ""%Products%"" повторяется';
							|en = 'Items ""%Products%"" are repeated'; fa = 'Items ""%Products%"" are repeated';
							|it = 'L''articolo ""%Products%"" si ripete';
							|pl = 'Nomenklatura ""%Products%"" powtarza się';
							|tr = '""%Products%"" öğe tekrarlanmaktadır'");
			ErrorText = StrReplace(ErrorText, "%Products%", Selection.Products);
			
		EndIf;
			
		CommonClientServer.MessageToUser(
			ErrorText,
			PriceSettingDocument.Ref,
			CommonClientServer.PathToTabularSection("PriceTree", Selection.LineNumber, "Products"),
			,
			Cancel);
		
	EndDo;
	
EndProcedure // Report the error of the payment of the goods for the registration of the order()

// Displays error messages in the PM Products document Ustanovlennuyu
//
// Parameters:
//  Selection                         - QueryResultSelection - 
//  PriceSettingDocument            - DocumentObject.PriceSetup - the document for which you want to withdraw
//  UsePriceManagementSystem25  - Boolean - flag for using the new pricing.
//  Cancel                 - Boolean  - flag for refusing to carry out the document.
//
Procedure ReportErrorsAvailabilityOfSetPricesForPriceRegistration(Selection,
	                                                                PriceSettingDocument,
	                                                                UsePriceManagementSystem25,
	                                                                Cancel)

	While Selection.Next() Do
		
		If UsePriceManagementSystem25 Then
			Characteristic = Selection.PricingVariant;
		Else
			Characteristic = Selection.Characteristic;
		EndIf;
		
		If ValueIsFilled(Characteristic) Then
			
			ErrorText = NStr("vi = 'Đơn giá mặt hàng ""%Products%"" có đặc tính ""%Characteristic%"" theo dạng giá ""%PricesKind%"" vào ngày %DocumentDate%, số trong phạm vi ngày %RoomWithinADay% đã thiết lập';
							|ru = 'Цена на номенклатуру ""%Products%"" с характеристикой ""%Characteristic%"" по виду цен ""%PricesKind%"" на дату %DocumentDate%, номер в пределах дня %RoomWithinADay% уже установлена';
							|en = 'Price for variant ""%Characteristic%"" of item ""%Products%"" by price type ""%PricesKind%"" on the date %DocumentDate%, number within the day %RoomWithinADay% is already set'; fa = 'Price for variant ""%Characteristic%"" of item ""%Products%"" by price type ""%PricesKind%"" on the date %DocumentDate%, number within the day %RoomWithinADay% is already set';
							|it = 'Prezzo dell''articolo ""%Products%"" con caratteristica  ""%Characteristic%"" per tipo di prezzo ""%PricesKind%"" in data %DocumentDate%, numero all''interno del giorno  %RoomWithinADay% già impostato';
							|pl = 'Cena na pozycję ""%Products%"" z cechą ""%Characteristic%"" według rodzaju cen ""%PricesKind%"", na datę %DocumentDate%, numer w ramach dnia %RoomWithinADay% jest już ustawiony';
							|tr = '%RoomWithinADay% gün içindeki %DocumentDate% tarihli ""%PricesKind%"" fiyat türüne göre ""%Characteristic%"" varyantına sahip ""%Products%"" ürün fiyatına ilişkin numara zaten yapılandırıldı'");
			ErrorText = StrReplace(ErrorText, "%Products%",   Selection.Products);
			ErrorText = StrReplace(ErrorText, "%Characteristic%", Characteristic);
			ErrorText = StrReplace(ErrorText, "%PricesKind%",         Selection.PriceKind);
			ErrorText = StrReplace(ErrorText, "%DocumentDate%",     Format(PriceSettingDocument.Date, "DF=MM/dd/yy"));
			ErrorText = StrReplace(ErrorText, "%RoomWithinADay%", Selection.RoomWithinADay);
			
		Else
			
			ErrorText = NStr("vi = 'Đơn giá mặt hàng ""%Products%"" theo dạng giá ""%PricesKind%"" vào ngày %DocumentDate%, số trong phạm vi ngày %RoomWithinADay% đã được thiết lập';
							|ru = 'Цена на номенклатуру ""%Products%"" по виду цен ""%PricesKind%"" на дату %DocumentDate%, номер в пределах дня %RoomWithinADay% уже установлена';
							|en = 'Price of item ""%Products%"" by price type ""%PricesKind%"" on the date %DocumentDate%, number within the day %RoomWithinADay% is already set'; fa = 'Price of item ""%Products%"" by price type ""%PricesKind%"" on the date %DocumentDate%, number within the day %RoomWithinADay% is already set';
							|it = 'Prezzo dell''articolo  ""%Products%"" per tipo di prezzo ""%PricesKind%"" in data %DocumentDate%, numero all''interno del giorno %RoomWithinADay% già impostato';
							|pl = 'Cena na nomenklaturę ""%Products%"" według rodzaju cen ""%PricesKind%"", na datę %DocumentDate%, numer w ciągu dnia %RoomWithinADay% jest już ustawiony';
							|tr = '%RoomWithinADay% gün içindeki %DocumentDate% tarihli ""%PricesKind%"" fiyat türüne göre ""%Products%"" ürün fiyatına ilişkin numara zaten yapılandırıldı'");
			ErrorText = StrReplace(ErrorText, "%Products%",   Selection.Products);
			ErrorText = StrReplace(ErrorText, "%PricesKind%",         Selection.PriceKind);
			ErrorText = StrReplace(ErrorText, "%DocumentDate%",     Format(PriceSettingDocument.Date, "DF=MM/dd/yy"));
			ErrorText = StrReplace(ErrorText, "%RoomWithinADay%", Selection.RoomWithinADay);
			
		EndIf;
			
		CommonClientServer.MessageToUser(
			ErrorText,
			PriceSettingDocument.Ref,
			CommonClientServer.PathToTabularSection("PriceTree", Selection.LineNumber, "Products"),
			,
			Cancel);
		
	EndDo;

EndProcedure // Report the error of the cash register for the registration()

#EndRegion

#Region ProceduresForGeneratingRequestsCheckingRegistrationOfSupplierPrices

// Generates a request for creating a temporary price table
//
// Parameters:
//  QueryText     - String          - text string to which you want to add the query text
//  QueryOptions - Structure       - structure containing request parameters
//  Goods           - ValueTable - table with products
//
Procedure GenerateTemporaryPriceTableQueryForRegisteringSupplierPrices(QueryText,
	                                                                       QueryOptions,
	                                                                       Goods)
	
	QueryText = QueryText + "
		|SELECT
		|	TemporaryTableOfGoods_.LineNumber            AS LineNumber,
		|	TemporaryTableOfGoods_.PartnerProducts   AS ProductCrossReference,
		|	TemporaryTableOfGoods_.Products           AS Products,
		|	TemporaryTableOfGoods_.Characteristic         AS Characteristic,
		|	TemporaryTableOfGoods_.PriceKind                AS VendorPriceKind,
		|	TemporaryTableOfGoods_.Package               AS Package
		|INTO
		|	TemporaryTableOfGoods_
		|FROM
		|	&Goods AS TemporaryTableOfGoods_
		|;
		|";
		
	QueryOptions.Insert("Goods", Goods);
	
EndProcedure // Form a temporary table for the registration of the supplier()

// Generates a request to check the correctness of filling in the PM Goods document of the partner's price list Setting.
//
//
// Parameters:
//  QueryText - String - text string to which you want to add the query text.
//
Procedure GenerateProductCorrectnessRequestForRegisteringSupplierPrices(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	MAX(DocumentGoods.LineNumber) AS LineNumber,
		|	DocumentGoods.Products          AS Products,
		|	DocumentGoods.Characteristic        AS Characteristic,
		|	DocumentGoods.VendorPriceKind     AS VendorPriceKind
		|FROM
		|	TemporaryTableOfGoods_ AS DocumentGoods
		|WHERE
		|	DocumentGoods.Products <> VALUE(Catalog.Products.EmptyRef)
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.VendorPriceKind
		|HAVING
		|	COUNT (*) > 1
		|;
		|";
	
EndProcedure // To form a product reference for the registration of the supplier()

#EndRegion

#Region ProceduresForDisplayingSupplierPriceRegistrationErrorMessages

Procedure InformUserAboutErrorInRegisteringSupplierPrices(ErrorText, PriceSettingDocument, LineNumber, Field, Cancel)
	
	If TypeOf(PriceSettingDocument) = Type("FormDataStructure") Then
		
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			CommonClientServer.PathToTabularSection("PriceTree", LineNumber, Field),
			,
			Cancel);
		
	Else
		
		CommonClientServer.MessageToUser(
			ErrorText,
			PriceSettingDocument,
			CommonClientServer.PathToTabularSection("Goods", LineNumber, Field),
			,
			Cancel);
		
	EndIf;
	
EndProcedure

// Displays error messages in the PM Products document of the supplier's price nomenclature Setting.
//
// Parameters:
//  Selection               - QueryResultSelection - 
//  PriceSettingDocument  - DocumentObject.VendorPriceList - the document to
//                                                                                display error messages for.
//  Cancel                 - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsCorrectnessOfProductsForRegisteringSupplierPrices(Selection,
	                                                                      PriceSettingDocument,
	                                                                      Cancel)
	
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.VendorPriceKind) Then
			
			If ValueIsFilled(Selection.Characteristic) Then
				
				ErrorText = NStr("vi = 'Mặt hàng ""%Products%"" với đặc tính ""%Characteristic%"" có dạng giá ""%VendorPriceKind%"" bị lặp lại';
								|ru = 'Номенклатура ""%Products%"" с характеристикой ""%Characteristic%"" с видом цены ""%VendorPriceKind%"" повторяется';
								|en = 'Variant ""%Characteristic%"" of item ""%Products%"" with price type ""%VendorPriceKind%"" is duplicated'; fa = 'Variant ""%Characteristic%"" of item ""%Products%"" with price type ""%VendorPriceKind%"" is duplicated';
								|it = 'L''articolo ""%Products%""con caratteristica ""%Characteristic%"" con tipo di prezzo ""%VendorPriceKind%"" si ripete';
								|pl = 'Pozycja ""%Products%"" z cechą ""%Characteristic%"" z widokiem ceny ""%VendorPriceKind%"" powtarza się';
								|tr = '""%VendorPriceKind%"" fiyat türü olan ""%Characteristic%"" varyantına sahip ""%Products%"" öğesi tekrarlanmaktadır'");
				ErrorText = StrReplace(ErrorText, "%Products%",      Selection.Products);
				ErrorText = StrReplace(ErrorText, "%Characteristic%",    Selection.Characteristic);
				ErrorText = StrReplace(ErrorText, "%VendorPriceKind%", Selection.VendorPriceKind);
				
			Else
				
				ErrorText = NStr("vi = 'Mặt hàng ""%Products%"" với dạng giá ""%VendorPriceKind%"" bị lặp lại';
								|ru = 'Номенклатура ""%Products%"" с видом цены ""%VendorPriceKind%"" повторяется';
								|en = 'Item ""%Products%"" with price type ""%VendorPriceKind%"" is duplicated'; fa = 'Item ""%Products%"" with price type ""%VendorPriceKind%"" is duplicated';
								|it = 'L''articolo ""%Products%"" con tipo di prezzo ""%VendorPriceKind%""  si ripete';
								|pl = 'Nomenklatura ""%Products%"" z widokiem ceny ""%VendorPriceKind%"" powtarza się';
								|tr = '%VendorPriceKind% fiyat türüne sahip ""%Products%"" öğesi tekrarlanmaktadır'");
				ErrorText = StrReplace(ErrorText, "%Products%",      Selection.Products);
				ErrorText = StrReplace(ErrorText, "%VendorPriceKind%", Selection.VendorPriceKind);
				
			EndIf;
			
		Else
			
			If ValueIsFilled(Selection.Characteristic) Then
				
				ErrorText = NStr("vi = 'Mặt hàng ""%Products%"" có đặc tính ""%Characteristic%"" bị lặp lại';
								|ru = 'Номенклатура ""%Products%"" с характеристикой ""%Characteristic%"" повторяется';
								|en = 'Variant ""%Characteristic%"" of item ""%Products%"" is duplicated'; fa = 'Variant ""%Characteristic%"" of item ""%Products%"" is duplicated';
								|it = 'L''articolo ""%Products%"" con la caratteristica ""%Characteristic%"" si ripete';
								|pl = 'Pozycja ""%Products%"" z charakterystyką ""%Characteristic%"" jest powtarzana';
								|tr = '""%Characteristic%"" varyantına sahip ""%Products%"" öğesi tekrarlanmaktadır'");
				ErrorText = StrReplace(ErrorText, "%Products%",   Selection.Products);
				ErrorText = StrReplace(ErrorText, "%Characteristic%", Selection.Characteristic);
				
			Else
				
				ErrorText = NStr("vi = 'Mặt hàng ""%Products%"" bị lặp lại';
								|ru = 'Номенклатура ""%Products%"" повторяется';
								|en = 'Items ""%Products%"" are repeated'; fa = 'Items ""%Products%"" are repeated';
								|it = 'L''articolo ""%Products%"" si ripete';
								|pl = 'Nomenklatura ""%Products%"" powtarza się';
								|tr = '""%Products%"" öğe tekrarlanmaktadır'");
				ErrorText = StrReplace(ErrorText, "%Products%", Selection.Products);
				
			EndIf;
			
		EndIf;
		
		InformUserAboutErrorInRegisteringSupplierPrices(ErrorText, PriceSettingDocument, Selection.LineNumber, "Products", Cancel);
		
	EndDo;
	
EndProcedure // Report the error of the correctness of the goods for the registration of the supplier()

#EndRegion

#Region ProceduresAndFunctionsForServicingTypesOfPricesFilledInAccordingToInformationSecurityData

// Checks the SCD data set that it contains the specified field of the appropriate type
//
// Parameters:
//  DataSet         - DataCompositionSchemaDataSets - the dataset that you want to check
//  FieldName             - String - containing the field name
//  ValueType         - TypeDescription - the type that the SKD field should have
//  ErrorMessage   - String - contains the introductory part of the error message.
//  OutputMessages   - Boolean - True - do not output messages to the user, only checking.
//
// Returns:
//  Boolean - True if the dataset contains the required field.
//
Function CheckDCSDataSetField(DataSet, FieldName, ValueType, ErrorMessage = Undefined, OutputMessages = True)
	
	Field = DataSet.Fields.Find(FieldName);
	
	If Field = Undefined Then
		Result = False;
	Else
		FieldTypes       = Field.ValueType.Types();
		AllowedTypes = ValueType.Types();
		
		Result = True;
		If Field <> Undefined And FieldTypes.Count() = AllowedTypes.Count() Then
			
			For Each Type In AllowedTypes Do
				If FieldTypes.Find(Type) = Undefined Then
					Result = False;
					Break;
				EndIf;
			EndDo;
			
		Else
			Result = False;
		EndIf;
	EndIf;
	
	If Not Result And OutputMessages Then
		CommonClientServer.MessageToUser(?(ValueIsFilled(ErrorMessage), ErrorMessage + ": ", "") 
			+ StrReplace(StrReplace(NStr("vi = 'Sơ đồ dàn dựng dữ liệu để điền giá phải có trường ""%FieldName%"" có kiểu giá trị ""%ValueType%"".';
										|ru = 'Схема компоновки данных для заполнения цен должна содержать поле ""%FieldName%"" с типом значения ""%ValueType%"".';
										|en = 'Data composition schema used to fill in prices should contain the ""%FieldName%"" field with the ""%ValueType%"" value type.'; fa = 'Data composition schema used to fill in prices should contain the ""%FieldName%"" field with the ""%ValueType%"" value type.';
										|it = 'Lo schema di composizione dei dati per la compilazione dei prezzi deve contenere il campo ""%FieldName%""con tipo di valore ""%ValueType%"".';
										|pl = 'Schemat układu danych do wypełnienia cen musi zawierać pole ""%FieldName%"" typ wartości ""%ValueType%"".';
										|tr = 'Fiyatların doldurulması için veri inşa edilme şeması, değer türü ""%ValueType%"" olan bir ""%FieldName%"" alanı içermelidir.'"), "%FieldName%", FieldName), "%ValueType%", ValueType));
	EndIf;
		
	Return Result;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions_

// Setting the service parameter for using the pricing option.
//
// Parameters:
//  SettingObject1 - DataCompositionSettingsComposer, DataCompositionNestedObjectSettings - where to get the settings.
//
// Returns:
//   Boolean - indicates whether the pricing option parameter is being used.
//
Function SetVSKDPricingOption(SettingObject1) Export
	
	UsePriceManagementSystem25  = DataCompositionClientServer.GetParameter(
		SettingObject1.Settings, 
		"UsePriceManagementSystem25");
	
	If UsePriceManagementSystem25 = Undefined Then
		Return False;
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingObject1, "UsePriceManagementSystem25", PriceManagementSystemServerCall.UsePriceManagementSystem25());
	
	Return True;
	
EndFunction

#EndRegion

#EndRegion
