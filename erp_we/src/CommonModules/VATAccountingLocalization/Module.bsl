#Region Internal

#Region GettingVATAccountingSettingsAndParameters

// Parameters:
//  AccountingSettings - See VATAccountingERPServerCall.AccountingSettings
//
Procedure AddAccountingSettings(AccountingSettings) Export
	
	
EndProcedure

// Parameters:
//  AccountingParameters - See VATAccountingERP.AccountingParametersForOrganization
//  Organization - See VATAccountingERP.AccountingParametersForOrganization
//  Date - See VATAccountingERP.AccountingParametersForOrganization
//  Warehouse - See VATAccountingERP.AccountingParametersForOrganization
//  Department - See VATAccountingERP.AccountingParametersForOrganization
//
Procedure AddCompanyAccountingParameters(AccountingParameters, Organization, Date, Warehouse, Department) Export
	
	
EndProcedure

// Add text for organizations that use the Unified Tax System with General VAT rates.
// 
// Parameters:
//  QueryTextAccountingPolicy - String
Procedure AddGeneralVATRatesToUSNSText(QueryTextAccountingPolicy) Export


EndProcedure

// Add the VAT rate Query Text.
// 
// Parameters:
//  QueryText - String - a fragment of the Query Text.
//  ExpressionProducts - String, Undefined - Expression for getting the item in the request. 
//                                                 If filled in, the VAT Rate for the sales tax type is levied From the item.
//                                                 If Undefined, the default VAT rate is used for the sales tax type.
Procedure CompleteQueryTextVATRate(QueryText,ExpressionProducts) Export
	
	
EndProcedure

// Returns a list of available organizations that have Sales taxed on the Date of the Sale
// 
// Parameters:
//  QueryText - String
// 
Procedure AddToListOfOrganizationsWithoutVAT(QueryText) Export
	
	
EndProcedure

// Parameters:
//  SettingsDescription - See InformationRegisters.VATAccountingSettings.DefaultValues
//
Procedure AddDescriptionOfVATAccountingSettingsForOrganization(SettingsDescription) Export
	
	
EndProcedure 

// Returns the request text based on the register data.
//
// Parameters:
//  QueryText - String - query text.
//  AddCondition - Boolean - True if you need to add a condition to the request text.
//
Procedure AddCurrentVATParametersToQueryText(QueryText, AddCondition = False) Export
	
	
EndProcedure

// Add a description of the VAT accounting settings.
// 
// Parameters:
//  Organization - CatalogRef.Companies
//  ValidityDate - Date - Validity Date
//  SettingsDescriptionString - String - A line with a description of the settings
Procedure AddDescriptionOfVATAccountingSettings(Organization, ValidityDate,SettingsDescriptionString) Export
EndProcedure

// Parameters:
//  ArrayOfDescriptionStrings - Array of String
//  CurrentSettings_ - See InformationRegisters.VATAccountingSettings.DescriptionOfActiveParameters
//  All - Boolean - if True, it returns a description of all settings.
//
Procedure AddDescriptionOfCurrentVATAccountingSettings(ArrayOfDescriptionStrings, CurrentSettings_, All = False) Export
	
	
EndProcedure

// Parameters:
//  TypesOfTaxation - ValueList of EnumRef.VATTaxationTypes
//  AccountingSettings - See VATAccountingERPInternal.ApplicableTypesOfVATTaxation
//  Sales - Boolean
//  Purchases - Boolean
//
Procedure SupplementApplicableTypesOfVATTaxation(TypesOfTaxation, AccountingSettings, Sales, Purchases) Export
	
	
EndProcedure

// Parameters:
//  VATActivities - See VATAccountingERPInternal.ApplicableVATActivities
//  AccountingSettings - See VATAccountingERPInternal.ApplicableVATActivities
//
Procedure SupplementApplicableActivitiesWithVAT(VATActivities, AccountingSettings) Export
	
	
EndProcedure

// Parameters:
//  Array - See VATAccountingERP.ActivitiesVATIsIncludedInCost
//
Procedure SupplementActivitiesVATIsIncludedInCost(Array) Export
	
	
EndProcedure

// Parameters:
//  Array - See VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement
//
Procedure SupplementActivitiesVATIsAcceptedForReimbursement(Array) Export
	
	
EndProcedure

// Parameters:
//  TypesOfTaxation - See VATAccountingERP.TypesOfVATTaxationNonTaxable
//   ForAdvances - Boolean
//
Procedure SupplementTypesOfVATTaxationNonTaxable(TypesOfTaxation, ForAdvances = False) Export
EndProcedure

// Parameters:
//  Array - See VATAccountingERP.SalesTaxationVATIsNotIncludedInCost
//
Procedure SupplementSalesTaxationVATIsNotIncludedInCost(Array) Export
	
	
EndProcedure

// Determines whether Preferential VAT taxation is applied 
//
// Parameters:
//  Organization - CatalogRef.Companies- The organization for which you need to get an accounting policy.
//	Date - Date - The period for which you need to get an accounting policy.
//	
// Returns:
// 	Boolean- True - preferential taxation is applied for the period under review for this organization.
Function PreferentialVATTaxationIsApplied(Organization, Date) Export
	PreferentialVATTaxationIsApplied = False;
	Return PreferentialVATTaxationIsApplied;
EndFunction

// Returns the Query Text of the temporary table of the VAT account settings for counterparties.
//
// Returns:
//	String - query text.
//
Function QueryTextTTCounterpartyVATAccountingSettings() Export
	
	QueryText = "";
	
	
	Return QueryText;
	
EndFunction

// Returns the Query Text of the temporary table of VAT accounting settings for organizations.
//
// Returns:
//	String - query text.
//
Function QueryTextTTVATAccountingSettingsOrganizations() Export
	
	QueryText = "";
	
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region VATRates

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "VATAccountingLocalization.CreateVATRateElements";
	Handler.Version = "2.5.26.17";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("313711b2-73a3-429e-9073-1247e4528a7e");
	Handler.UpdateDataFillingProcedure = "VATAccountingLocalization.CreateElementsOfBidNDS_RegisterDataForProcessingToUpgradeToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Tạo các phần tử mới trong danh mục ""Thuế suất thuế GTGT"" 22% và 22/122"".';
							|ru = 'Создает новые элементы справочника ""Ставки НДС"" 22% и 22/122"".';
							|en = 'Creates new items of the ""VAT rates"" catalog: 22% and 22/122.'; fa = 'Creates new items of the ""VAT rates"" catalog: 22% and 22/122.';
							|it = 'Creates new items of the ""VAT rates"" catalog: 22% and 22/122.';
							|pl = 'Creates new items of the ""VAT rates"" catalog: 22% and 22/122.';
							|tr = '""KDV oranları"" %22 ve 22/122"" kataloğunun yeni öğelerini oluşturur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.VATRates.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.VATRates.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");  
	

EndProcedure

Procedure CreateElementsOfBidNDS_RegisterDataForProcessingToUpgradeToNewVersion(Parameters) Export
	
	// Registration is not required
	Return;
	
EndProcedure

// Handler for creating new VAT rates
// 
// Parameters:
//  Parameters - See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure CreateVATRateElements(Parameters) Export 
	
	RewritableBids = New ValueList();
	
	
	FillInCatalogOfVATRates(RewritableBids);
	
	Parameters.ProcessingCompleted = True;
	
EndProcedure

// See Catalogs.VATRates.CreateInitialFillItems
// 
// Parameters:
//  RewritableBids - Undefined, ValueList of Undefined - list of VAT rates.
// 
//	 - EnumRef.VATTaxationTypes - StavkaNDS, the data for which needs to be updated.
Procedure FillInCatalogOfVATRates(RewritableBids = Undefined) Export
	
EndProcedure

// Parameters:
//  BidReceiptParameters - See VATAccountingERP.ParametersForGettingVATRate
//	VATRate - CatalogRef.VATRates
Procedure FillInVATRateForProductsAndTaxation(BidReceiptParameters, VATRate) Export
	
EndProcedure

// Parameters:
//  VATRate - See VATAccountingERP.DefaultVATRate
//  Date - See VATAccountingERP.DefaultVATRate
//  CalculatedRate - Boolean - indicates the need to get the estimated VAT rate X/(100 + X).
//  VATTaxation - See VATAccountingERP.DefaultVATRate
//  Organization - CatalogRef.Companies - The organization for which you need to determine the default bid.
//
Procedure SetDefaultVATRate(VATRate, Val Date, Val CalculatedRate, Val VATTaxation, Val Organization) Export
	
	
EndProcedure

// Parameters:
//  VATRate - See VATAccountingERP.FillInVATRateForPayments_
//  VATTaxation - See VATAccountingERP.FillInVATRateForPayments_
//  Organization - See VATAccountingERP.FillInVATRateForPayments_
//  Date - See VATAccountingERP.FillInVATRateForPayments_
//
Procedure FillInVATRateForPayments(VATRate, Val VATTaxation, Val Organization, Val Date) Export
	
	
EndProcedure

Procedure CompleteQueryTextVATRateForItemList(StructureOfActions, QueryDetails) Export
	
	QueryText = ExcisableGoodsAccounting.QueryTextTTExcisableItems("TTDataSource");
	If QueryDetails.QueriesTexts.FindByValue(QueryText) = Undefined Then
		QueryDetails.QueriesTexts.Add(QueryText, "TTExcisableItems");
	EndIf;
	
	QueryText = 
	"SELECT
	|	Goods.IdOfTTRow AS IdOfTTRow,
	|	Goods.Products AS Products,
	|	ISNULL(TTExcisableItems.ExcisableGoods, FALSE) AS ExcisableGoods,
	|	ISNULL(CatalogProducts.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType
	|FROM
	|	TTDataSource AS Goods
	|	LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|	LEFT JOIN TTExcisableItems AS TTExcisableItems
	|		ON Goods.Products = TTExcisableItems.Products";
	
	QueryDetails.QueriesTexts.Add(QueryText, "ItemDetailsVATRate");
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the StavkaNDS field based on data
// from the information register "VAT accounting settings for USN Committees" when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddQueryTextToVATRateForSettingUpAccountingForCommitteeSUSN(StructureOfActions, QueryDetails, CachedValues) Export
	
	
EndProcedure

// Refills the parameter StavkaNDS of operations by the nomenclature and type of VAT taxation. It is used for batch
// processing of rows of table parts.
// 
// Parameters:
//   BidReceiptParameters - See VATAccountingERP.ParametersForGettingVATRate
//   CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//   VATRate - CatalogRef.VATRates
//
Procedure FillInVATRateByItemAndTaxationInBatch(BidReceiptParameters, CachedValues, VATRate) Export
	
	
EndProcedure

// Verification of the document's services at the committee's rate.
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  TSName - String - The string is the name of the table part.
//  AccountingDate - Date - Date of receipt of the VAT rate.
//
Procedure CheckServicesAtCommitteeSVATRate(Object, Cancel, TSName = "Goods", AccountingDate = Undefined) Export
	

EndProcedure

// Description of collection string handlers:
// 
// Parameters:
//  StringHandlers - ValueList of String - Contains the correspondence of the action on the string and the method.
//
Procedure WhenAddingCollectionLineHandlers(StringHandlers) Export
	
	
EndProcedure

// Setting up form elements - Settings for filling in VAT rates
// 
// Parameters:
//   Form - ClientApplicationForm - processing form
//   ValidityDate - Date - date of action.
//
Procedure SetUpFormForFillingInVATRates(Form, ValidityDate) Export
	
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
	Form.CatalogVATRate = Catalogs.VATRates.EmptyRef();
	
	
EndProcedure

// Getting the VAT rate by country of the price type. 
//
// Parameters:
//  CalculationParameters - Structure - Structure of calculation parameters
//  
// Returns:
//  Map - Matching the price type and the VAT rate:
//   * Key - CatalogRef.TypesOfPrices - Type of price.
//   * Value - CatalogRef.VATRates - VAT rate.
Function GetVATRateByPriceType(CalculationParameters) Export
	
	MatchingPriceTypes = New Map();
	
	// StavkiNDS: BezNDS
	If CalculationParameters.VATRate = Catalogs.VATRates.EXCLUDINGVAT Then
		For Each ArrayElement In CalculationParameters.SelectedTypesOfPrices Do
			MatchingPriceTypes.Insert(ArrayElement, Catalogs.VATRates.EXCLUDINGVAT);
		EndDo;

		Return MatchingPriceTypes;
	EndIf;
		
	
	Return MatchingPriceTypes;
	
EndFunction

// The procedure for the formation of Registered Records for independent registers of VAT accounting settings.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	Document - DocumentRef - link to the document
//	TempTablesManager - TempTablesManager - Manager temporary tables in the document
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure RecordVATAccountingSettingsDataForCommitteeSUSN(TablesForRegisteredRecords, Document, TempTablesManager, Cancel) Export
	
	
EndProcedure

// Returns an array of excluded VAT rate transfers
// 
// Returns:
//  Array - contains VAT rate transfers.
//
Function ExcludedTransfersVATRates() Export
	
	Array = New Array;

		
	Return Array;
	
EndFunction


#Region MethodsForUpdatingInformationSecurity

// Receiving element of the reference Stalkings by transfer of Stalkings
//
// Parameters:
//  PaymentVATRate - EnumRef - Value of the VAT rate transfer for which you need to get 
//                                                    the corresponding value of the VAT rate reference.
//	VATTaxationType - EnumRef.VATTaxationTypes - VAT taxation, within which you need 
//																		to find the rate.
//	CalculatedRate       - Boolean - the Attribute value of the calculation setting. if it is undefined, the bid is received without taking into account this Attribute.
// Returns:
//  - Undefined - if not localization
//  - CatalogRef.VATRates - Reference link.StavkiNDS - The VAT rate corresponding to the transfer.
// 
Function VATRateForTransfers(PaymentVATRate, VATTaxationType = Undefined, CalculatedRate = Undefined) Export 
	
	Value = Undefined;
	Return Value;
	
EndFunction

// Fills in the RS.mainstavinds with initial data
//
Procedure BasicBidsNDS_CreateInitialFillItems() Export
	
	
EndProcedure

//Getting the main country
//
// Returns:
//  - CatalogRef.WorldCountries - main country
//
Function GetMainCountry() Export
	
	Value = SettingsValueClientServerCached.MainCountry();
	

	Return Value;
	
EndFunction

#EndRegion

#EndRegion

#Region AccountingForIncomingVAT

// Parameters:
//  UnavailableTaxTypes - Array of EnumRef.VATTaxationTypes
//  FillParameters - See VATAccountingERPInternal.VATFreePurchases
//
Procedure AddPurchaseTaxTypesThatAreNotAvailableForTransaction(UnavailableTaxTypes, FillParameters) Export
	
	
EndProcedure

// See VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation
Procedure CheckCompletionOfPurchaseDocumentForVATTaxation(Object, VATTaxation, CheckParameters, Cancel) Export
	
	
EndProcedure

// See VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases
Procedure SupplementConditionalAppearanceOfVATAmountsForTaxationOfPurchases(Form, NameOfVATRateField, NameOfVATAmountField, NameOfFieldWithVATAmount, PathToTaxationField) Export
	
	
EndProcedure

// Parameters:
//  AvailableVATActivities - Structure
//  UnavailableVATActivities - Array of EnumRef.VATTaxationTypes
//  FillParameters - See VATAccountingERPInternal.AvailableVATActivities
//
Procedure AddAvailableUnavailableVATActivitiesByParameters(AvailableVATActivities, UnavailableVATActivities, FillParameters) Export
	
	
EndProcedure

// Parameters:
//  NewVATActivity - See VATAccountingERP.FillInTypeOfActivityVAT
//  CurVATActivity - See VATAccountingERP.FillInTypeOfActivityVAT
//  FillParameters - See VATAccountingERP.FillInTypeOfActivityVAT
//
Procedure FillInVATActivityTypeByParameters(NewVATActivity, CurVATActivity, FillParameters) Export
	
EndProcedure

// See VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity
Procedure CheckCompletionOfDocumentByTypeOfVATActivity(Object, VATActivityType, CheckParameters, Cancel) Export
	
	
EndProcedure

// Returns the value view from the input document.
//
// Parameters:
// 	TaxInvoice - DefinedType.TaxInvoice -  VAT accounting document.
//
// Returns:
// EnumRef.AssetKinds
Function TypeOfValueEnteringBalances(TaxInvoice) Export
	
	Value = Undefined;
	Return Value;
	
EndFunction

// Sets the price flag to include VAT based on VAT taxation
//
// Parameters:
//	PriceIncludesVAT - Boolean
//	VATTaxation - EnumRef.VATTaxationTypes
//
// Returns:
//	Boolean - The flag value has been changed
Function SetPriceIncludesVATOnVATTaxation(PriceIncludesVAT, Val VATTaxation) Export
	
	
	Return False;
	
EndFunction

// Sets the availability of the price element includingnds based on VAT taxation
//
// Parameters:
//	FormElementPriceIncludesVAT - TextBox
//	VATTaxation - EnumRef.VATTaxationTypes
Procedure SetAvailabilityPriceIncludesVATOnVATTaxation(FormElementPriceIncludesVAT, Val VATTaxation) Export
	
	
EndProcedure

// Returns the sign of mutual settlements are included based on VAT taxation
//
// Parameters:
//	VATTaxation - EnumRef.VATTaxationTypes
//
// Returns:
//	Boolean - The sign of mutual settlement does not include
Function SettlementsDoNotIncludeVAT(Val VATTaxation) Export
	
	
	Return False;
	
EndFunction

#EndRegion

#Region AccountingForOutgoingVAT

// Parameters:
//  AvailableVATTaxes - See VATAccountingERPInternal.AvailableSalesVATTaxation
//  UnavailableVATTaxes - See VATAccountingERPInternal.AvailableSalesVATTaxation
//  FillParameters - See VATAccountingERPInternal.AvailableSalesVATTaxation
//
Procedure SupplementAvailableSalesThatAreNotAvailableForVATTaxationByParameters(AvailableVATTaxes, UnavailableVATTaxes, FillParameters) Export
	
	
EndProcedure

// Parameters:
//  NewVATTaxation - See VATAccountingERP.FillInSalesVATTaxation
//  CurVATTaxation - See VATAccountingERP.FillInSalesVATTaxation
//  FillParameters - See VATAccountingERP.FillInSalesVATTaxation
//
Procedure FillInVATTaxationOfSalesByParameters(NewVATTaxation, CurVATTaxation, FillParameters) Export
	
	
EndProcedure

// See VATAccountingERP.ParametersForFillingTypesOfStocksForTaxation
Procedure SupplementParametersForFillingTypesOfStocksForTaxation(SelectionOfStockTypes_, Organization, Date, VATTaxation) Export
	
	
EndProcedure

// See VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation
Procedure SupplementConditionalAppearanceOfVATAmountsForSalesTaxation(Form, NameOfVATRateField, NameOfVATAmountField, NameOfFieldWithVATAmount) Export
	
	
EndProcedure

// Parameters:
//  VATActivityType - See VATAccountingERP.TypeOfVATTaxationActivity
//  VATTaxation - See VATAccountingERP.TypeOfVATTaxationActivity
//  Organization - See VATAccountingERP.TypeOfVATTaxationActivity
//  Date - See VATAccountingERP.TypeOfVATTaxationActivity
//
Procedure EstablishTypeOfVATTaxationActivity(VATActivityType, Val VATTaxation, Organization, Date) Export
	
	
EndProcedure

// Parameters:
//  QueryText - See VATAccountingERP.TextOfRequestCorrectnessOfSelectionOfProductsForTaxationOfVATSales
//  QueryOptions - See VATAccountingERP.TextOfRequestCorrectnessOfSelectionOfProductsForTaxationOfVATSales
//
Procedure CompleteTextOfRequestCorrectnessOfSelectionOfProductsForTaxationOfVATSales(QueryText, QueryOptions) Export
	
	
EndProcedure

// Parameters:
//  Selection - See VATAccountingERP.ReportErrorsCorrectSelectionOfProductsForVATSales
//  DocumentSales - See VATAccountingERP.ReportErrorsCorrectSelectionOfProductsForVATSales
//  TSName - See VATAccountingERP.ReportErrorsCorrectSelectionOfProductsForVATSales
//  PresentationOfTS - See VATAccountingERP.ReportErrorsCorrectSelectionOfProductsForVATSales
//  Cancel - See VATAccountingERP.ReportErrorsCorrectSelectionOfProductsForVATSales
//
Procedure ReportErrorsCorrectSelectionOfProductsForVATSales(Selection, DocumentSales, TSName, PresentationOfTS, Cancel) Export
	
	
EndProcedure

// Parameters:
//  Restrictions - See VATAccountingERP.RestrictionOfGoodsOnTaxation
//  VATTaxation - See VATAccountingERP.RestrictionOfGoodsOnTaxation
//
Procedure SupplementRestrictionOfGoodsOnTaxation(Restrictions, Val VATTaxation) Export
	
	
EndProcedure

// See VATAccountingERP.SetParametersForFillingInventoryTypesForCommissionSales
Procedure SetParametersForFillingInventoryTypesForCommissionSales(FillParameters) Export
	
	
EndProcedure

#EndRegion

#Region Posting

#Region ConnectionToMechanismOfConducting

// Parameters:
//  Parameters - See VATAccountingERP.ParametersForHoldingDocument
//  Document - See VATAccountingERP.ParametersForHoldingDocument
//  Properties - See VATAccountingERP.ParametersForHoldingDocument
//
Procedure AddParametersForDocument(Parameters, Document, Properties) Export
	
EndProcedure

// See VATAccountingERP.TextsOfCancellationRequests
// Parameters:
//  QueriesTexts - See VATAccountingERP.TextsOfCancellationRequests
//  MetadataOfDocument - See VATAccountingERP.TextsOfCancellationRequests
//
Procedure AddTextsOfCancellationRequests(QueriesTexts, MetadataOfDocument) Export
	
	
EndProcedure

// See VATAccountingERP.ReflectRegisteredRecords
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	
EndProcedure

// See VATAccountingERP.InitializeChangeControlData
Procedure AddChangeControlRequest(Query, QueryTexts, Document) Export
	
	
EndProcedure

// See VATAccountingERP.ReportChangeControlResults
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	
EndProcedure

#EndRegion

#Region LocalizationOfOperations

// See VATAccountingERP.ReflectEntryOfBalancesOfOwnGoods
Procedure ReflectEntryOfBalancesOfOwnGoods(Query, QueryTexts, Registers, TextProducts_1) Export
	
	
EndProcedure

// See VATAccountingERP.ReflectPurchaseFromSupplier
Procedure ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_) Export
	
	
EndProcedure

// See VATAccountingERP.ReflectReturnOfGoodsFromBuyer
Procedure ReflectReturnOfGoodsFromBuyer(Query, QueryTexts, Registers, ValueText_) Export
	
	
EndProcedure

// See VATAccountingERP.ReflectImplementationToClient
Procedure ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_) Export
	
	
EndProcedure

// See VATAccountingERP.ReflectShipmentToCustomer
Procedure ReflectShipmentToCustomer(Query, QueryTexts, Registers, ValueText_) Export
	
	
EndProcedure

// See VATAccountingERP.ReflectReturnOfGoodsToSupplier
Procedure ReflectReturnOfGoodsToSupplier(Query, QueryTexts, Registers, TextProducts_1) Export

	
EndProcedure

// See VATAccountingERP.ReflectCommissionAgentSReport
Procedure ReflectCommissionAgentSReport(Query, QueryTexts, Registers, TextProducts_1) Export
	
	
EndProcedure

// See VATAccountingERP.ReflectReportToCommittee
Procedure ReflectReportToCommittee(Query, QueryTexts, Registers, TextProducts_1) Export
	
	
EndProcedure

// See VATAccountingERP.ReflectReportToPurchasingCommittee
Procedure ReflectReportToPurchasingCommittee(Query, QueryTexts, Registers, TextProducts_1) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#Region JobGeneration

#Region JobsForMonthEndClosing

Procedure AdditionalChecksForVATDistribution(HandlerParameters) Export
EndProcedure

// See VATAccountingERP.BeforeWritingTaskToEndOfMonth
Procedure BeforeWritingTaskToEndOfMonth(Month, Operation, Organization, Document) Export
	
	
EndProcedure

// Parameters:
//  MatchingQueryTexts - See VATAccountingERPInternal.MatchingRequestsToControlRegisters
//  Query - See VATAccountingERPInternal.MatchingRequestsToControlRegisters
//
Procedure AddMatchingRequestsToControlRegisters(MatchingQueryTexts, Query) Export
	
	
EndProcedure

Procedure SupplementTextOfMovementRequestCounterpartyIncomeExpenses(QueryText) Export
	
	
EndProcedure

Procedure RequestTextOtherRevenue(QueryText) Export
	
	
EndProcedure

Procedure AddTextOfRequestRevenueAndCostOfSales(QueryText, Query) Export

	
EndProcedure

#EndRegion

#Region JobsForGeneratingVATRecords

// Parameters:
//  Type - See VATAccountingERP.GenerateTasksBasedOnDocuments
//  ReferencesArrray - See VATAccountingERP.GenerateTasksBasedOnDocuments
Procedure GenerateTasksBasedOnDocuments(Type, ReferencesArrray) Export
	
	
EndProcedure

#EndRegion

#Region OtherTaskGenerationInterface

// Performs the formation of VAT accounting tasks based on the results of changes in batch registers.
//
// Parameters:
//	TempTablesManager - TempTablesManager - The manager that contains the temporary table in the change of parties, it should contain the fields:
//	   * Period - Date - The period of the party movement.
//	   * Organization - CatalogRef.Companies - Organization of party accounting.
//	   * CorVATActivityTypes - EnumRef.VATTaxationTypes - a new activity type of separate VAT accounting.
//
Procedure GenerateTasksForVATDistribution(TempTablesManager) Export
	
	
EndProcedure

// Performs the formation of VAT accounting tasks based on the results of changes in batch registers.
// 
// Parameters:
//	TempTablesManager - TempTablesManager - The manager that contains the temporary table in the change of parties, it should contain the fields: 
//	   * Period - Date - The period of the party movement.
//	   * Organization - CatalogRef.Companies - Organization of party accounting.
//	   * TaxInvoice - DefinedType.TaxInvoice - Purchase document (incoming VAT accounting document).
//	   * VATActivityType - EnumRef.VATTaxationTypes - The initial type of activity of separate VAT accounting
//	   * CorVATActivityTypes - EnumRef.VATTaxationTypes - A new type of activity of separate VAT accounting 
//
Procedure CreateTasksForCreatingBookOfPurchasesSales(TempTablesManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Lots.Period, MONTH)     AS Month,
	|	Lots.Organization                      AS Organization,
	|	Lots.TaxInvoice                      AS TaxInvoice
	|FROM
	|	TTBatchChange AS Lots
	|WHERE
	|	Lots.CorVATActivityTypes <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	AND VALUETYPE(Lots.TaxInvoice) IN (&TypesOfInvoices)
	|	AND (Lots.CorVATActivityTypes <> Lots.VATActivityType
	|		OR Lots.VATActivityType = VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle)
	|		OR Lots.VATActivityType = VALUE(Enum.VATTaxationTypes.ExportSale)
	|		OR Lots.VATActivityType = VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|		OR Lots.VATActivityType = VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|		OR Lots.VATActivityType = VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|";
	
	TypesOfInvoices = Metadata.DefinedTypes.TaxInvoice.Type.Types();
	CommonClientServer.SupplementArray(TypesOfInvoices, Metadata.DefinedTypes.BasisForVATRecords.Type.Types(), True);
	Query.SetParameter("TypesOfInvoices", TypesOfInvoices);
	InformationRegisters.JobsForGeneratingVATRecords.CreateRegisterEntriesBasedOnSampleData(
		Query.Execute().Select(), , False);
	
EndProcedure

// See VATAccountingERP.ReflectChangesInSettlementsWithSuppliersInVATAccounting
Procedure ReflectChangesInSettlementsWithSuppliersInVATAccounting(ChangesTable) Export
	
	
EndProcedure

// See VATAccountingERP.ReflectChangesInSettlementsWithCustomersInVATAccounting
Procedure ReflectChangesInSettlementsWithCustomersInVATAccounting(ChangesTable) Export
	
	
EndProcedure

// See VATAccountingERP.ReflectInVATAccountingChangesInSettlementsOnFinancialInstruments
Procedure ReflectInVATAccountingChangesInSettlementsOnFinancialInstruments(ChangesTable) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#Region KBSPConnection

// Parameters:
//  Objects - Array of MetadataObject
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	

EndProcedure

// Parameters:
//  Settings - See VATAccountingERP.CustomizeReportsOptions
//
Procedure CustomizeReportsOptions(Settings) Export
	
	
EndProcedure

// Parameters:
//  DataSources - See VATAccountingERP.FillDataSourcesForPeriodClosingCheck
//
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export


EndProcedure

// Parameters:
//  FormSettings - See VATAccountingERP.OnDefineCommandsAttachedToObject
//  Sources - See VATAccountingERP.OnDefineCommandsAttachedToObject
//  AttachedReportsAndDataProcessors - See VATAccountingERP.OnDefineCommandsAttachedToObject
//  Commands - See VATAccountingERP.OnDefineCommandsAttachedToObject
//
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	
EndProcedure

// Parameters:
//  Objects - Array of MetadataObject
//
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export
	
	
EndProcedure

// See PrintManagementOverridable.OnDefinePrintSettings
Procedure OnDefinePrintSettings(Settings) Export
	
	ListOfObjects = Settings.PrintObjects;
	
EndProcedure

// See VATAccountingERP.OnDefineObjectsWithPrintCommands
Procedure OnDefineObjectsWithPrintCommands(ListOfObjects) Export
EndProcedure

// See VATAccountingERP.BeforeAddPrintCommands
Procedure BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing) Export
	
	
EndProcedure

// Parameters:
//  Lists - See VATAccountingERP.OnFillListsWithAccessRestriction
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
EndProcedure

#EndRegion

#Region DescriptionOfDocumentsForJournals

// Parameters:
//  BusinessTransactionsAndDocuments - See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Procedure CompleteDescriptionOfOperationsAndDocumentTypesForProcurementDocumentLog(BusinessTransactionsAndDocuments) Export
	
	
EndProcedure

// Parameters:
//  VTBusinessTransactionsAndDocumentTypes - See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Procedure CompleteDescriptionOfOperationsAndDocumentTypesForSalesDocumentLog(VTBusinessTransactionsAndDocumentTypes) Export
	
	
EndProcedure

//Parameters:
// VTBusinessTransactionsAndDocumentTypes - See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Procedure CompleteDescriptionOfOperationsAndDocumentTypesForProcessingDocumentLog(VTBusinessTransactionsAndDocumentTypes) Export
	
	
EndProcedure

//Parameters:
// VTBusinessTransactionsAndDocumentTypes - See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Procedure CompleteDescriptionOfOperationsAndDocumentTypesForJournalOfDocumentsTransferredToProcessing2_5(VTBusinessTransactionsAndDocumentTypes) Export
	
	
EndProcedure

//Parameters:
// VTBusinessTransactionsAndDocumentTypes - See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Procedure ToCompleteDescriptionOfOperationsAndTypesOfDocumentsForJournalOfDocumentsAcceptedForProcessing2_5(VTBusinessTransactionsAndDocumentTypes) Export
	
	
EndProcedure
#EndRegion

#Region RoutineVATOperation

// Parameters:
//  EndOfPeriod - See VATAccountingERP.ExecuteGenerationRegisteredRecordsForVAT
//  CompanyArray - See VATAccountingERP.ExecuteGenerationRegisteredRecordsForVAT
//
Procedure ExecuteGenerationRegisteredRecordsForVAT(EndOfPeriod, CompanyArray) Export
	
	
EndProcedure

// Parameters:
//  Invoices_ - See VATAccountingERP.ReflectDocumentsInVATAccounting
//  ReferencesArrray - See VATAccountingERP.ReflectDocumentsInVATAccounting
//
Procedure AddInvoicesToVATRecords(Invoices_, ReferencesArrray) Export
	
	
EndProcedure

// Parameters:
//  IncomingData - Array of MetadataObject
//
Procedure SupplementIncomingDataForRoutineOperation(IncomingData) Export
	
	
EndProcedure

Procedure FixResult(CalculationParameters) Export
	
	
EndProcedure

Procedure GetBatches_(CalculationParameters) Export
	
	
EndProcedure

Procedure GetInvoicesDocuments(CalculationParameters) Export
	
	
EndProcedure

Procedure GetCorrectedInvoiceDocuments(CalculationParameters) Export
	
	
EndProcedure

Procedure GetAdjustmentInvoicesDocuments(CalculationParameters) Export
	
	
EndProcedure

Procedure GetSectionsOfVATDeduction(CalculationParameters) Export
	
	
EndProcedure

Procedure GetSalesTaxBase0(CalculationParameters) Export
	
	
EndProcedure

Procedure GetVATLocks(CalculationParameters) Export
	
	
EndProcedure

Procedure CalculateRecordsOfVATPresentedRecoveryUnderTypeOfActivity(CalculationParameters) Export
	
	
EndProcedure

Procedure GetReAdmittedToVATDeduction(CalculationParameters) Export
	
	
EndProcedure

Procedure GetOffsetsOfAdvancesReceivedByInvoices(TempTablesManager, CalculationParameters) Export
	
	
EndProcedure

Procedure GetOffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction(TempTablesManager, CalculationParameters) Export
	
	
EndProcedure

Procedure PerformTheCalculation(CalculationParameters) Export
	
	
EndProcedure

#EndRegion

#Region RegulatedReporting


#EndRegion

// Parameters:
//  TablesOfConduct - Array of String
Procedure SupplementPostingTables(TablesOfConduct) Export
	
	
EndProcedure

//Parameters:
// VATRegisters - See VATAccountingERP.VATRegisters_
Procedure AddVATRegisters(VATRegisters) Export
	
	
EndProcedure

// Generation of navigation links for creating and viewing a list of DPP.
// Parameters:
//  Object - DocumentObject - the document being processed.
//  SumByDocument - Number - The amount of the document.
// 
// Returns:
//  FormattedString, String - Event Documents On Preliminary Deliveries
Function EventDocumentsOnPreliminaryDeliveries(Object, SumByDocument = 0) Export
	
	Presentation = "";
	
	Return Presentation;
	
EndFunction

#EndRegion

#Region Private


#EndRegion
