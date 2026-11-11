
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
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("ImportAccounting");
	
	LeaseTermAdjustmentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure:
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.LeaseTermAdjustment") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers);
		QueryTextTableFACost(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts, Registers);

		QueryTextTableLeasedAsset(QueryTexts, Registers);
		QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers);
		QueryTextTableLeaseServicesPaymentSchedule(QueryTexts, Registers);
		QueryTextTableLeaseServicesAccrualSchedule(QueryTexts, Registers);
		QueryTextTableLeaseInterestAccrualSchedule(QueryTexts, Registers);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers);
		
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
	
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		
		QueryTextTableGoodsForRegistrationOfImportDocuments(Query, QueryTexts, Registers);
		QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		LeaseTermAdjustmentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;

	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  DocumentRef - DocumentRef.LeaseTermAdjustment - The document for which the movements are formed.
//  TempTablesManager	- TempTablesManager - Contains auxiliary temporary tables that can be used for forming movements.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfDeferredMotionFormation(DocumentRef, TempTablesManager) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	FillInInitializationParameters(Query, DocumentRef, Undefined);
	
	QueryTexts = New ValueList;
	
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(Query, QueryTexts);
	QueryTextTableFACost(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts, Undefined);

	QueryTextTableTermsOfLeaseContracts(QueryTexts, Undefined);
	QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Undefined);
	
	QueryTextTableOtherExpenses(Query, QueryTexts, Undefined);
	
	QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Undefined);
	QueryTextTableItemisedExpensesLots(Query, QueryTexts, Undefined);
	
	QueryTextTableOtherIncome(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	LeaseTermAdjustmentLocalization.TablesOfDeferredMotionFormation(QueryTexts);

	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	Return MovementTables;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.FixedAssetsInitialRecognition2_4.AddGenerateCommand(GenerationCommands);
	Documents.DisposeFixedAssets2_4.AddGenerateCommand(GenerationCommands);
	Documents.VendorInvoiceLeasedAssets.AddGenerateCommand(GenerationCommands);
	Documents.ChangeRentalTerms.AddGenerateCommand(GenerationCommands);

EndProcedure

// Adds the command to create the document "Change the terms of the lease agreement".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Order - Number -
//
// Returns:
//	- ValueTableRow: See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//	- Undefined
//
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	
	If AccessRight("Insert", Metadata.Documents.LeaseTermAdjustment) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.LeaseTermAdjustment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.LeaseTermAdjustment);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.Order = Order;
	
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
	
EndProcedure

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
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings	 - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

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

#Region Other

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
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.ChangesPaymentPlan               = False;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;

	#Region OptionalParameters
	
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";
	ParametersStructure.LineOfBusiness          = "";
	ParametersStructure.ARAPObjectSettings                  = "";
	ParametersStructure.PathToTSData                    = "";
	ParametersStructure.Terms                       = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	ParametersStructure.PaymentID             = "";
	ParametersStructure.Contract                          = "";
	
	// The details for the object of calculations are used in conducting.
	ParametersStructure.FinancialAccountingGroup           = "";
	ParametersStructure.Department                    = "";
	ParametersStructure.CourseNumerator                    = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                  = "Object.CourseDenominator";
	
	ParametersStructure.FormItems.LabelCurrencies = "CurrencyDecoration";
	ParametersStructure.CurrencyAndExchangeRateDocumentViewOnly = False;
	ParametersStructure.DocumentCurrencyViewOnly = False;
	
	ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
	
	#EndRegion
	
	Return ParametersStructure;

EndFunction


// Returns a list of fixed assets that need to be checked for acceptance for accounting
//
// Parameters:
//  Object	 - DocumentObject.LeaseTermAdjustment - 
// 
// Returns:
//  Array of CatalogRef.Assets
//
Function ListOfFASystemsToBeChecked(Object) Export
	
	ListOfFA = New Array;
	
	For Each FAString In Object.FA Do
		If FAString.ActionWithRentalObject <> Enums.ActionsWithRentalObjects.Rent Then
			ListOfFA.Add(FAString.FixedAsset);
		EndIf;
	EndDo;
	
	Return ListOfFA;

EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Organization     AS Organization,
	|	DocumentData.NewPartner    AS Partner,
	|	DocumentData.NewCounterparty AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	Document.LeaseTermAdjustment AS DocumentData
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON DocumentData.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND &Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND &Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = RegisterAccountingAnalyticsForPartners.Contract
	|			AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.NewContract <> VALUE(Catalog.LeaseContract.EmptyRef)
	|	AND RegisterAccountingAnalyticsForPartners.DimensionKey IS NULL";
	
	QueryAnalyst = New Query(QueryText);
	For Each QueryParameter In Query.Parameters Do
		QueryAnalyst.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	QueryResult = QueryAnalyst.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);
	
EndProcedure

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.LeaseTermAdjustment";
	TemporaryTableQueryTexts = New Map();
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("Department", "DocumentData.Contract.Department");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	EndIf;
		
	If QueryText = Undefined Then
		
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
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "FixedAssetsDocuments" Then
		
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
										RedefiningParameterCalculation,
										TemporaryTableQueryTexts);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
	GetDocumentData(Query);
	
	Query.Text =
	"SELECT
	|	DocumentData.Ref                                     AS Ref,
	|	DocumentData.Date                                       AS Period,
	|	DocumentData.Number                                      AS Number,
	|	DocumentData.Organization                                AS Organization,
	|	CASE WHEN DocumentData.NewPartner = VALUE(Catalog.Partners.EmptyRef) THEN
	|		DocumentData.Partner
	|	ELSE 
	|		DocumentData.NewPartner
	|	END AS Partner,
	|	CASE WHEN DocumentData.NewCounterparty = VALUE(Catalog.Counterparties.EmptyRef) THEN
	|		DocumentData.Counterparty
	|	ELSE
	|		DocumentData.NewCounterparty 
	|	END AS Counterparty,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract
	|	ELSE
	|		DocumentData.NewContract
	|	END AS Contract,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.ContractType
	|	ELSE
	|		DocumentData.NewContract.ContractType
	|	END AS ContractType,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.AssetHolder
	|	ELSE
	|		DocumentData.NewContract.AssetHolder
	|	END AS AssetHolder,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.LineOfBusiness
	|	ELSE
	|		DocumentData.NewContract.LineOfBusiness
	|	END AS LineOfBusiness,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.RecognizeLeasedItemsInLocalAccounting
	|	ELSE
	|		DocumentData.NewContract.RecognizeLeasedItemsInLocalAccounting
	|	END AS RecognizeLeasedItemsInLocalAccounting,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.RecognizeLeasedAssetsInManagementAccounting
	|	ELSE
	|		DocumentData.NewContract.RecognizeLeasedAssetsInManagementAccounting
	|	END AS RecognizeLeasedAssetsInManagementAccounting,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.Department
	|	ELSE
	|		DocumentData.NewContract.Department
	|	END AS Department,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.ExpenseItemInterest
	|	ELSE
	|		DocumentData.NewContract.ExpenseItemInterest
	|	END AS ExpenseItemInterest,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.ExpensesDimensionInterest
	|	ELSE
	|		DocumentData.NewContract.ExpensesDimensionInterest
	|	END AS ExpensesDimensionInterest,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.BusinessUnitInterest
	|	ELSE
	|		DocumentData.NewContract.BusinessUnitInterest
	|	END AS BusinessUnitInterest,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.MethodForDeterminingCostOfAssets
	|	ELSE
	|		DocumentData.NewContract.MethodForDeterminingCostOfAssets
	|	END AS MethodForDeterminingCostOfAssets,
	|	DocumentData.Partner AS OldPartner,
	|	DocumentData.Counterparty AS OldCounterparty,
	|	DocumentData.Contract AS OldContract,
	|	ISNULL(CatLeaseContracts.RegisterImportApplications, FALSE) AS RegisterImportApplications,
	|	DocumentData.ARAPCurrency                       AS ARAPCurrency,
	|	DocumentData.AmountARAP                        AS AmountARAP,
	|	DocumentData.DocumentAmount                             AS DocumentAmount,
	|	DocumentData.Currency                                     AS Currency,
	|	DocumentData.EmployeeResponsible                              AS EmployeeResponsible,
	|	DocumentData.Comment                                AS Comment,
	|	DocumentData.Posted                                   AS Posted,
	|	DocumentData.DeletionMark                            AS DeletionMark,
	|	DocumentData.Sum                                      AS Sum,
	|	DocumentData.SecurityDepositAmount               AS SecurityDepositAmount,
	|	DocumentData.LeaseServicesAmount                         AS LeaseServicesAmount,
	|	DocumentData.AmountOfLeaseAssetsByuout                 AS AmountOfLeaseAssetsByuout,
	|	DocumentData.AmountOfVATRepurchaseOfRentalItems              AS AmountOfVATRepurchaseOfRentalItems,
	|	DocumentData.InterestAmount                             AS InterestAmount,
	|	DocumentData.AmountIncludingVAT                                  AS AmountIncludingVAT,
	|	DocumentData.VATAmount                                   AS VATAmount,
	|	DocumentData.VATRate                                  AS VATRate,
	|	DocumentData.TermYears                                    AS TermYears,
	|	DocumentData.TermMonths                                    AS TermMonths,
	|	DocumentData.TermDays                                   AS TermDays,
	|	DocumentData.LeaseStartDate                           AS LeaseStartDate,
	|	DocumentData.DateOfFirstPayment                         AS DateOfFirstPayment,
	|	DocumentData.DateOfFirstSecurityPayment         AS DateOfFirstSecurityPayment,
	|	DocumentData.BuyoutDate                                 AS BuyoutDate,
	|	DocumentData.InterestRate                           AS InterestRate,
	|	DocumentData.PaymentFrequency                         AS PaymentFrequency,
	|	DocumentData.AccrualFrequency                    AS AccrualFrequency,
	|	DocumentData.LeaseItemsCost                   AS LeaseItemsCost,
	|	DocumentData.PaymentForLeaseService                       AS PaymentForLeaseService,
	|	DocumentData.AccrualOfLeaseService                   AS AccrualOfLeaseService,
	|	DocumentData.DocumentID                     AS DocumentID,
	|	DocumentData.ExpenseItem                             AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses                          AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimensionExpenses            AS AssetsLiabilitiesDimensionExpenses,
	|	DocumentData.GlAccountSettingsExpenses                AS GlAccountSettingsExpenses,
	|	DocumentData.IncomeItem                              AS IncomeItem,
	|	DocumentData.DimensionOfRevenue                           AS DimensionOfRevenue,
	|	DocumentData.TheInterestAccrualScheduleIsEnteredManually     AS TheInterestAccrualScheduleIsEnteredManually,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.LeaseTermAdjustment AS DocumentData
	|		LEFT JOIN Catalog.LeaseContract AS CatLeaseContracts
	|		ON DocumentData.Contract = CatLeaseContracts.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	VALUE(Enum.BusinessTransactions.LeaseTermAdjustment) AS BusinessOperation,
	|	FALSE AS RevaluateAtFairValue,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS RecordInManAccounting
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.LeaseTermAdjustment AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.Cost AS Cost,
	|	DocumentTable.CostInAccounting AS CostInAccounting,
	|	DocumentTable.CostInTaxAccounting AS CostInTaxAccounting,
	|	DocumentTable.CostInManagementAccounting AS CostInManagementAccounting,
	|	DocumentTable.UsefulLifeManagementAccounting,
	|	DocumentTable.UsefulLifeAccounting,
	|	DocumentTable.UsefulLifeTaxAccounting,
	|	DocumentTable.ActionWithRentalObject AS ActionWithRentalObject
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.LeaseTermAdjustment.FA AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	LeasedAssetAccounting.SupplementValuesOfDocumentParameters(ValuesOfHoldingParameters);

	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.LeaseTermAdjustment"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.LeaseTermAdjustment);
	ValuesOfHoldingParameters.Insert("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	ValuesOfHoldingParameters.Insert("RecordInLocalAccounting", True);
	ValuesOfHoldingParameters.Insert("RecordInManAccounting", True);

	ValuesOfHoldingParameters.Insert("BO_DecreaseInDepreciation", Enums.BusinessTransactions.DecreaseInFixedAssetDepreciation);
	ValuesOfHoldingParameters.Insert("SettingHO_ReductionOfDepreciation", Catalogs.BusinessTransactionsSettings.DecreaseInFixedAssetDepreciation);
	ValuesOfHoldingParameters.Insert("IdApplicationForImportOfGoods", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));

	ValuesOfHoldingParameters.Insert("BO_GenerationOfLeasedFixedAssetsCost", Enums.BusinessTransactions.GenerationOfLeasedFixedAssetsCost);
	ValuesOfHoldingParameters.Insert("SettingUpHO_FORMINGCostOfLeasedFA", Catalogs.BusinessTransactionsSettings.GenerationOfLeasedFixedAssetsCost);

	ValuesOfHoldingParameters.Insert("BO_LeaseTermAdjustment", Enums.BusinessTransactions.LeaseTermAdjustment);
	ValuesOfHoldingParameters.Insert("SettingUpHO_LeaseTermAdjustment", Catalogs.BusinessTransactionsSettings.LeaseTermAdjustment);

	ValuesOfHoldingParameters.Insert("BO_RecordingLeaseLiabilitiesInIncome", Enums.BusinessTransactions.RecordingLeaseLiabilitiesInIncome);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReflectionOfLeaseObligationsInIncome", Catalogs.BusinessTransactionsSettings.RecordingLeaseLiabilitiesInIncome);

	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		ValuesOfHoldingParameters.Insert("BegOfMonth", BegOfMonth(Attributes.Period));
		ValuesOfHoldingParameters.Insert("EndOfMonth", EndOfMonth(Attributes.Period));
		ValuesOfHoldingParameters.Insert("BoundaryOfResidues", New Boundary(BegOfDay(Attributes.Period), BoundaryType.Excluding));
		
		ValuesOfHoldingParameters.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Attributes.Organization, Attributes.Period, True));
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Attributes.ARAPCurrency, Attributes.Period, Attributes.Organization);
		ValuesOfHoldingParameters.Insert("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
		ValuesOfHoldingParameters.Insert("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
		
		ConversionFactorFromManCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			ValuesOfHoldingParameters.ManagementAccountingCurrency, 
			Attributes.ARAPCurrency, 
			Attributes.Period);
		ValuesOfHoldingParameters.Insert("ConversionFactorFromManCurrency", ConversionFactorFromManCurrency);
		
		ConversionFactorFromLocalCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			Attributes.LocalAccountingCurrency, 
			Attributes.ARAPCurrency, 
			Attributes.Period);
		ValuesOfHoldingParameters.Insert("ConversionFactorFromLocalCurrency", ConversionFactorFromLocalCurrency);
		
		AccountingParametersForRentalItems = LeasedAssetAccountingClientServer.AccountingParametersForRentalItems(
			ValuesOfHoldingParameters.LeaseAccountingAccordingToFSB25_2018IsUsed, Attributes);
		
		ValuesOfHoldingParameters.Insert("ThereIsMaAccount", AccountingParametersForRentalItems.ThereIsMaAccount);
		ValuesOfHoldingParameters.Insert("ThereIsACAccounting", AccountingParametersForRentalItems.ThereIsACAccounting);
		ValuesOfHoldingParameters.Insert("ThereIsAccountingTa", AccountingParametersForRentalItems.ThereIsAccountingTa);
		
		ValuesOfHoldingParameters.Insert("CreatedForTransition", 
						LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Attributes.Period, Attributes.Organization));
			
		ValuesOfHoldingParameters.Insert("DocumentOfConclusionOfContractOfLease", Catalogs.LeaseContract.DocumentOfConclusionOfContractOfLease(Attributes.Contract));
		
		ValuesOfHoldingParameters.Insert("AmendmentOfContract", ?(Attributes.OldContract <> Attributes.Contract, True, False));
		
		// Small deviations in the calculation of the FA cost change are attributed to the error of rounding
		ValuesOfHoldingParameters.Insert("RoundingThreshold", ThresholdForRoundingChangesInPresentValue());
		
	EndIf;
	
	LeaseTermAdjustmentLocalization.SupplementValuesOfParameters(ValuesOfHoldingParameters, Attributes);
	
	Return ValuesOfHoldingParameters;
	
EndFunction

#Region RequestTextsForConducting

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts);
	QueryTextTableTTFACostAdjustment(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	&Ref                                                        AS Recorder,
	|	&Period                                                        AS Period,
	|	&Organization                                                   AS Organization,
	|	FATable.FixedAsset                                     AS FixedAsset,
	|
	|	RegisterData.AccelerationFactor                            AS AccelerationFactor,
	|	RegisterData.DepreciationMethod                      AS DepreciationMethod,
	|	RegisterData.ResidualValueMan                         AS ResidualValueMan,
	|	RegisterData.ResidualValueLocal                     AS ResidualValueLocal,
	|	RegisterData.LastChangeDate                         AS LastChangeDate,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits     AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	|	FATable.UsefulLifeManagementAccounting                                  AS UsefulLifeMonths,
	|
	|	CASE
	|		WHEN RegisterData.UsefulLifeMonths <> RegisterData.UsefulLifeForCalculatingDepreciationMonth
	|			THEN RegisterData.UsefulLifeForCalculatingDepreciationMonth + (FATable.UsefulLifeManagementAccounting - RegisterData.UsefulLifeMonths)
	|		ELSE FATable.UsefulLifeManagementAccounting
	|	END AS UsefulLifeForCalculatingDepreciationMonth,
	|
	|	FATable.CostInManagementAccounting AS CostUsedToCalculateDepreciationManag,
	|	CASE 
	|		WHEN &ComplianceCAAccountingIsKept
	|			THEN 0
	|		ELSE FATable.CostInAccounting
	|	END AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|		INNER JOIN TTOsuuDepreciationParameters AS RegisterData
	|		ON RegisterData.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTFACostAdjustment AS FACostAdjustment
	|		ON FATable.FixedAsset = FACostAdjustment.FixedAsset
	|			AND FATable.RowID = FACostAdjustment.RowID
	|WHERE
	|	FATable.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.RentalTermsAdjustment)
	|	AND (FATable.UsefulLifeManagementAccounting <> RegisterData.UsefulLifeMonths
	|		OR ISNULL(FACostAdjustment.LocalCost, 0) <> 0)";
	
	QueryTexts.Add(QueryText, RegisterName);

EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(Query, QueryTexts)
	
	RegisterName = "OSBUDepreciationParameters";
	
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts);
	QueryTextTableTTFACostAdjustment(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	&Ref                      AS Recorder,
	|	&Period                      AS Period,
	|	&Organization                 AS Organization,
	|	FATable.FixedAsset   AS FixedAsset,
	
	|	OSBUDepreciationParameters.CostForDepreciationCalculationTargetFinancing  AS CostForDepreciationCalculationTargetFinancing,
	|	OSBUDepreciationParameters.PermanentDifferencesUsedToCalculateDepreciation           AS PermanentDifferencesUsedToCalculateDepreciation,
	|	OSBUDepreciationParameters.LastChangeDate              AS LastChangeDate,
	|	OSBUDepreciationParameters.AnnualDepreciationRate             AS AnnualDepreciationRate,
	|	OSBUDepreciationParameters.AccelerationFactor                 AS AccelerationFactor,
	|	OSBUDepreciationParameters.DepreciationSchedule                    AS DepreciationSchedule,
	|	OSBUDepreciationParameters.SpecialFactor               AS SpecialFactor,
	|	OSBUDepreciationParameters.ResidualValueMan              AS ResidualValueMan,
	|
	|	OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	// UsefulLifeMonthsAC
	|	CASE
	|		WHEN OSBUDepreciationParameters.UsefulLifeMonthsAC <> 0
	|			THEN FATable.UsefulLifeAccounting
	|		ELSE 0
	|	END AS UsefulLifeMonthsAC,
	|
	// UsefulLifeMonthsTA
	|	CASE
	|		WHEN OSBUDepreciationParameters.UsefulLifeMonthsTA <> 0
	|			THEN FATable.UsefulLifeTaxAccounting
	|		ELSE 0
	|	END AS UsefulLifeMonthsTA,
	|
	// UsefulLifeForCalculatingDepreciationMonth
	|	CASE
	|		WHEN FATable.UsefulLifeAccounting = OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
	|			THEN OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
	|		WHEN OSBUDepreciationParameters.UsefulLifeMonthsAC <> OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
	|			THEN OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth + (FATable.UsefulLifeAccounting - OSBUDepreciationParameters.UsefulLifeMonthsAC)
	|		ELSE FATable.UsefulLifeAccounting
	|	END AS UsefulLifeForCalculatingDepreciationMonth,
	|
	// CostUsedToCalculateDepreciationManag
	|	FATable.CostInAccounting AS CostUsedToCalculateDepreciationManag
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|		INNER JOIN WDepreciationParametersOfOSBU AS OSBUDepreciationParameters
	|		ON (OSBUDepreciationParameters.Organization = &Organization)
	|			AND (OSBUDepreciationParameters.FixedAsset = FATable.FixedAsset)
	|
	|		LEFT JOIN TTFACostAdjustment AS FACostAdjustment
	|		ON FATable.FixedAsset = FACostAdjustment.FixedAsset
	|			AND FATable.RowID = FACostAdjustment.RowID
	|WHERE
	|	FATable.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.RentalTermsAdjustment)
	|	AND (FATable.UsefulLifeAccounting <> OSBUDepreciationParameters.UsefulLifeMonthsAC
	|		OR FATable.UsefulLifeTaxAccounting <> OSBUDepreciationParameters.UsefulLifeMonthsTA
	|		OR ISNULL(FACostAdjustment.LocalCost, 0) <> 0)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFACost(Query, QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	QueryTextTableTTCostIncrease(Query, QueryTexts);
	QueryTextTableTTCostReduction(Query, QueryTexts);
	
	QueryTextTableTTBookValueFA(QueryTexts);

	ListOfMergeRequests = New Array;
	
	#Region FixedAssetsCostAddition // Dt <01.03> - Ct <76.07.1>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)                AS RecordType,
	|	&Ref                                               AS Recorder,
	|	&Period                                               AS Period,
	|	&Organization                                          AS Organization,
	|	CostIncrease.FixedAsset                  AS FixedAsset,
	|	InformationAboutAccounting.FixedAssetsLocation                       AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup                AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness               AS LineOfBusiness,
	|	InformationAboutAccounting.Leaseholder                             AS Leaseholder,
	|                     
	|	CostIncrease.Cost                         AS Cost,
	|	CostIncrease.LocalCost                     AS LocalCost,
	|	CostIncrease.CostInTaxAccounting                       AS CostInTaxAccounting,
	|
	|	CostIncrease.LocalCost
	|	 - CostIncrease.CostInTaxAccounting                    AS CostTemporaryDifference,
	|
	|	CostIncrease.SecurityDepositValue                AS SecurityDepositValue,
	|	0                                                     AS DisregardedCostTA,
	|	
	|	CostIncrease.RowID               AS FinRecordID,
	|	&BO_LeasedFixedAssetsCostAddition                 AS BusinessOperation,
	|	&SettingUpHO_IncreasingCostOfRentedFA        AS BusinessTransactionSetting
	|	
	|FROM
	|	TTCostIncrease AS CostIncrease
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.FixedAsset = CostIncrease.FixedAsset
	|WHERE
	|	NOT CostIncrease.Sublease
	|";
	ListOfMergeRequests.Add(QueryText);

	#EndRegion
	
	#Region FixedAssetsCostDecrease // Dt <76.07.1> - Ct <01.03>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)                AS RecordType,
	|	&Ref                                               AS Recorder,
	|	&Period                                               AS Period,
	|	&Organization                                          AS Organization,
	|	CostReduction.FixedAsset                  AS FixedAsset,
	|	InformationAboutAccounting.FixedAssetsLocation                       AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup                AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness               AS LineOfBusiness,
	|	InformationAboutAccounting.Leaseholder                             AS Leaseholder,
	|	CASE
	|		WHEN BookValue.Ref IS NULL THEN
	|			CostReduction.Cost
	|		WHEN CostReduction.Cost < BookValue.BookValueOfMan THEN
	|			CostReduction.Cost
	|		ELSE
	|			ISNULL(BookValue.BookValueOfMan, 0)
	|		END                                            AS Cost,
	|	
	|	CASE
	|		WHEN BookValue.Ref IS NULL THEN
	|			CostReduction.LocalCost
	|		WHEN CostReduction.LocalCost < BookValue.LocalBookValue THEN
	|			CostReduction.LocalCost
	|		ELSE
	|			ISNULL(BookValue.LocalBookValue, 0)
	|		END                                             AS LocalCost,
	|	
	|	CostReduction.CostInTaxAccounting                       AS CostInTaxAccounting,
	|
	|	CASE
	|		WHEN BookValue.Ref IS NULL THEN
	|			CostReduction.LocalCost
	|			- CostReduction.CostInTaxAccounting
	|		WHEN CostReduction.LocalCost < BookValue.LocalBookValue THEN
	|			CostReduction.LocalCost
	|			- CostReduction.CostInTaxAccounting
	|		ELSE
	|			ISNULL(BookValue.LocalBookValue, 0)
	|			- CostReduction.CostInTaxAccounting
	|		END                                             AS CostTemporaryDifference,
	|
	|	CostReduction.SecurityDepositValue                AS SecurityDepositValue,
	|	0                                                     AS DisregardedCostTA,
	|	
	|	CostReduction.RowID               AS FinRecordID,
	|	&BO_DecreaseOfLeasedFixedAssetsCost                 AS BusinessOperation,
	|	&SettingUpHO_ReducingCostOfLeasedFA        AS BusinessTransactionSetting
	|	
	|FROM
	|	TTCostReduction AS CostReduction
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.FixedAsset = CostReduction.FixedAsset
	|
	|		LEFT JOIN TTBookValueFA AS BookValue
	|		ON CostReduction.FixedAsset = BookValue.FixedAsset
	|			AND BookValue.Ref = &Ref
	|WHERE
	|	NOT CostReduction.Sublease
	|";

	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts, Registers)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);
	InitializeTTTableFACostAdjustmentByShares(Query, QueryTexts);
	
	#Region ReductionOfDepreciationDuringTransitionToFSB25
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	&Period                                      AS Period,
	|	&Organization                                 AS Organization,
	|	TTAccountingInformation.FixedAssetsLocation            AS Department,
	|	Interests.FixedAsset                    AS FixedAsset,
	|	TTAccountingInformation.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	TTAccountingInformation.LineOfBusiness    AS LineOfBusiness,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInManAccounting
	|			THEN CASE
	|					WHEN ISNULL(TT_CostOfVNA.Cost, 0) > 0
	|						THEN (1 - (TT_CostOfVNA.Cost - Interests.AmountOfInterestMan) / TT_CostOfVNA.Cost) 
	|								* TT_DepreciationOfVNA.Depreciation
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS Depreciation,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInLocalAccounting
	|			THEN CASE
	|					WHEN TT_DepreciationOfVNA.AccrueDepreciation
	|						THEN 0
	|					ELSE CASE
	|							WHEN ISNULL(TT_CostOfVNA.LocalCost, 0) > 0
	|								THEN (1 - (TT_CostOfVNA.LocalCost - Interests.LocalInterestAmount) / TT_CostOfVNA.LocalCost) 
	|										* TT_DepreciationOfVNA.DepreciationLocal
	|							ELSE 0
	|						END
	|				END
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	|	0 AS DepreciationInTaxAccounting,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInLocalAccounting
	|			THEN CASE
	|					WHEN TT_DepreciationOfVNA.AccrueDepreciation
	|						THEN 0
	|					ELSE CASE
	|							WHEN TT_CostOfVNA.LocalCost IS NOT NULL 
	|								THEN (1 - (TT_CostOfVNA.LocalCost - Interests.LocalInterestAmount) / TT_CostOfVNA.LocalCost) 
	|										* TT_DepreciationOfVNA.DepreciationLocal
	|							ELSE 0
	|						END
	|				END
	|		ELSE 0
	|	END AS DepreciationTD,
	|
	|	Interests.RowID                  AS FinRecordID,
	|	&BO_DecreaseInDepreciation AS BusinessOperation,
	|	&SettingHO_ReductionOfDepreciation AS BusinessTransactionSetting
	|FROM
	|	TTFACostAdjustmentByShares AS Interests
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON Interests.FixedAsset = TT_CostOfVNA.AccountingObject
	|			AND (TT_CostOfVNA.Ref = &Ref)
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS TT_DepreciationOfVNA
	|		ON Interests.FixedAsset = TT_DepreciationOfVNA.AccountingObject
	|			AND (TT_DepreciationOfVNA.Ref = &Ref)
	|
	|		INNER JOIN TTAccountingInformation AS TTAccountingInformation
	|		ON Interests.FixedAsset = TTAccountingInformation.FixedAsset
	|WHERE
	|	&CreatedForTransition";
	
	#EndRegion
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableLeasedAsset(QueryTexts, Registers)

	RegisterName = "LeasedAsset";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTLeasedFA(QueryTexts);
	QueryTextTableTTFATable(QueryTexts);
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.Cost AS Cost,
	|	FATable.FairValue AS ParValue,
	|	&Organization AS Organization,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	CASE
	|		WHEN FATable.ActionWithRentalObject <> VALUE(Enum.ActionsWithRentalObjects.RentalTermination)
	|			THEN TTLeasedFA.State
	|		ELSE VALUE(Enum.FixedAssetsStates.TakenOffBooks)
	|	END AS State
	|FROM
	|	TTFATable AS FATable
	|		INNER JOIN TTLeasedFA AS TTLeasedFA
	|		ON TTLeasedFA.FixedAsset = FATable.FixedAsset
	|			AND TTLeasedFA.State <> VALUE(Enum.FixedAssetsStates.TakenOffBooks)
	|WHERE
	|	FATable.Ref = &Ref
	|	AND (FATable.Cost <> TTLeasedFA.Cost
	|	OR &AmendmentOfContract
	|	OR FATable.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.RentalTermination))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.Cost AS Cost,
	|	FATable.FairValue AS ParValue,
	|	&Organization AS Organization,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	VALUE(Enum.FixedAssetsStates.LeaseContractsSigned) AS State
	|FROM
	|	TTFATable AS FATable
	|WHERE
	|	FATable.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.Rent)";
	
	QueryTexts.Add(QueryText, RegisterName);
		
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers)

	RegisterName = "TermsOfLeaseContracts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                AS Recorder,
	|	&Period                                AS Period,
	|	&Contract                               AS Contract,
	|	&SecurityDepositAmount          AS SecurityDepositAmount,
	|	&LeaseServicesAmount                    AS LeaseServicesAmount,
	|	&AmountOfLeaseAssetsByuout            AS AmountOfLeaseAssetsByuout,
	|	&InterestAmount                        AS InterestAmount,
	|	&VATAmount                              AS VATAmount,
	|	&VATRate                             AS VATRate,
	|	&TermYears                               AS TermYears,
	|	&TermMonths                               AS TermMonths,
	|	&TermDays                              AS TermDays,
	|	&LeaseStartDate                      AS LeaseStartDate,
	|	&DateOfFirstPayment                    AS DateOfFirstPayment,
	|	&DateOfFirstSecurityPayment    AS DateOfFirstSecurityPayment,
	|	&BuyoutDate                            AS BuyoutDate,
	|	&InterestRate                      AS InterestRate,
	|	&PaymentFrequency                    AS PaymentFrequency,
	|	&AccrualFrequency               AS AccrualFrequency,
	|	&LeaseItemsCost              AS LeaseItemsCost,
	|	&PaymentForLeaseService                  AS PaymentForLeaseService,
	|	&AccrualOfLeaseService              AS AccrualOfLeaseService,
	|	&TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually,
	|	&Ref                                AS EffectiveContractTerms,
	|	VALUE(Enum.CounterpartyContractStates.Valid) AS State
	|FROM
	|	Document.LeaseTermAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL 
	|
	|SELECT
	|	&Ref AS Ref,
	|	DATEADD(BEGINOFPERIOD(&Period, DAY), SECOND, -1) AS Period,
	|	TermsOfLeaseContracts.Contract AS Contract,
	|	TermsOfLeaseContracts.SecurityDepositAmount AS SecurityDepositAmount,
	|	TermsOfLeaseContracts.LeaseServicesAmount AS LeaseServicesAmount,
	|	TermsOfLeaseContracts.AmountOfLeaseAssetsByuout AS AmountOfLeaseAssetsByuout,
	|	TermsOfLeaseContracts.InterestAmount AS InterestAmount,
	|	TermsOfLeaseContracts.VATAmount AS VATAmount,
	|	TermsOfLeaseContracts.VATRate AS VATRate,
	|	TermsOfLeaseContracts.TermYears AS TermYears,
	|	TermsOfLeaseContracts.TermMonths AS TermMonths,
	|	TermsOfLeaseContracts.TermDays AS TermDays,
	|	TermsOfLeaseContracts.LeaseStartDate AS LeaseStartDate,
	|	TermsOfLeaseContracts.DateOfFirstPayment AS DateOfFirstPayment,
	|	TermsOfLeaseContracts.DateOfFirstSecurityPayment AS DateOfFirstSecurityPayment,
	|	TermsOfLeaseContracts.BuyoutDate AS BuyoutDate,
	|	TermsOfLeaseContracts.InterestRate AS InterestRate,
	|	TermsOfLeaseContracts.PaymentFrequency AS PaymentFrequency,
	|	TermsOfLeaseContracts.AccrualFrequency AS AccrualFrequency,
	|	TermsOfLeaseContracts.LeaseItemsCost AS LeaseItemsCost,
	|	TermsOfLeaseContracts.PaymentForLeaseService AS PaymentForLeaseService,
	|	TermsOfLeaseContracts.AccrualOfLeaseService AS AccrualOfLeaseService,
	|	TermsOfLeaseContracts.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually,
	|	&Ref AS EffectiveContractTerms,
	|	VALUE(Enum.CounterpartyContractStates.Closed) AS State
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|			&Period,
	|			Contract = &OldContract
	|				AND Recorder <> &Ref) AS TermsOfLeaseContracts
	|WHERE
	|	&AmendmentOfContract";
	
	QueryTexts.Add(QueryText, RegisterName);
		
EndProcedure

Function QueryTextTableLeaseServicesPaymentSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseServicesPaymentSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextTableTTPreviousTermsAndConditions(QueryTexts);
	
	QueryText =
	"SELECT
	|	LeaseServicesPaymentSchedule.ChangeDate AS ChangeDate,
	|	LeaseServicesPaymentSchedule.Contract AS Contract,
	|	&Ref AS EffectiveContractTerms,
	|	LeaseServicesPaymentSchedule.Date AS Date,
	|	LeaseServicesPaymentSchedule.RentalService AS RentalService,
	|	LeaseServicesPaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|	LeaseServicesPaymentSchedule.DepositPayment AS DepositPayment,
	|	LeaseServicesPaymentSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	LeaseServicesPaymentSchedule.BuyoutValue AS BuyoutValue,
	|	LeaseServicesPaymentSchedule.BuyoutValuePrepayment AS BuyoutValuePrepayment,
	|	LeaseServicesPaymentSchedule.BuyoutValueVAT AS BuyoutValueVAT
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS LeaseServicesPaymentSchedule
	|WHERE
	|	LeaseServicesPaymentSchedule.EffectiveContractTerms IN
	|			(SELECT
	|				T.EffectiveContractTerms
	|			FROM
	|				TTPreviousTermsAndConditions AS T)
	|	AND LeaseServicesPaymentSchedule.Date < BEGINOFPERIOD(&Period, DAY)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	&Contract,
	|	&Ref,
	|	ChartTable.Date,
	|	ChartTable.RentalService,
	|	ChartTable.RentalServiceVAT,
	|	ChartTable.DepositPayment,
	|	ChartTable.SecurityPaymentVATAmount,
	|	CASE
	|		WHEN ChartTable.Date >= &BuyoutDate
	|			THEN ChartTable.BuyoutValue
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN ChartTable.Date < &BuyoutDate
	|			THEN ChartTable.BuyoutValue
	|		ELSE 0
	|	END,
	|	ChartTable.BuyoutValueVAT
	|FROM
	|	Document.LeaseTermAdjustment.ServicePaymentSchedule AS ChartTable
	|WHERE
	|	ChartTable.Ref = &Ref
	|	AND ChartTable.Date >= BEGINOFPERIOD(&Period, DAY)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLeaseServicesAccrualSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseServicesAccrualSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextTableTTPreviousTermsAndConditions(QueryTexts);
	
	QueryText =
	"SELECT
	|	LeaseServicesAccrualSchedule.ChangeDate AS ChangeDate,
	|	LeaseServicesAccrualSchedule.Contract AS Contract,
	|	&Ref AS EffectiveContractTerms,
	|	LeaseServicesAccrualSchedule.Date AS Date,
	|	LeaseServicesAccrualSchedule.RentalService AS RentalService,
	|	LeaseServicesAccrualSchedule.RentalServiceVAT AS RentalServiceVAT,
	|	LeaseServicesAccrualSchedule.DepositPayment AS DepositPayment,
	|	LeaseServicesAccrualSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	LeaseServicesAccrualSchedule.BuyoutValue AS BuyoutValue,
	|	LeaseServicesAccrualSchedule.BuyoutValueVAT AS BuyoutValueVAT
	|FROM
	|	InformationRegister.LeaseServicesAccrualSchedule AS LeaseServicesAccrualSchedule
	|WHERE
	|	LeaseServicesAccrualSchedule.EffectiveContractTerms IN
	|			(SELECT
	|				T.EffectiveContractTerms
	|			FROM
	|				TTPreviousTermsAndConditions AS T)
	|	AND LeaseServicesAccrualSchedule.Date < BEGINOFPERIOD(&Period, DAY)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	CASE
	|		WHEN NOT &AmendmentOfContract
	|			THEN &Contract
	|		ELSE CASE
	|				WHEN ChartTable.Date < BEGINOFPERIOD(&Period, DAY)
	|					THEN &OldContract
	|				ELSE &Contract
	|			END
	|	END,
	|	&Ref,
	|	ChartTable.Date,
	|	ChartTable.RentalService,
	|	ChartTable.RentalServiceVAT,
	|	ChartTable.DepositPayment,
	|	ChartTable.SecurityPaymentVATAmount,
	|	CASE
	|		WHEN &BuyoutDate = ChartTable.Date
	|			THEN &AmountOfLeaseAssetsByuout
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN &BuyoutDate = ChartTable.Date
	|			THEN &AmountOfVATRepurchaseOfRentalItems
	|		ELSE 0
	|	END
	|FROM
	|	Document.LeaseTermAdjustment.ServiceAccrualSchedule AS ChartTable
	|WHERE
	|	ChartTable.Ref = &Ref
	|	AND ChartTable.Date >= BEGINOFPERIOD(&Period, DAY)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	&Contract,
	|	&Ref,
	|	&BuyoutDate,
	|	0,
	|	0,
	|	0,
	|	0,
	|	&AmountOfLeaseAssetsByuout,
	|	&AmountOfVATRepurchaseOfRentalItems
	|FROM
	|	Document.LeaseTermAdjustment AS DocumentData
	|		LEFT JOIN Document.LeaseTermAdjustment.ServiceAccrualSchedule AS ChartTable
	|		ON (ChartTable.Ref = DocumentData.Ref)
	|			AND (ChartTable.Date = DocumentData.BuyoutDate)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND ChartTable.Ref IS NULL
	|	AND &AmountOfLeaseAssetsByuout <> 0
	|	AND &BuyoutDate >= BEGINOFPERIOD(&Period, DAY)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableLeaseInterestAccrualSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseInterestAccrualSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextTableTTPreviousTermsAndConditions(QueryTexts);
	
	QueryText =
	"SELECT
	|	LeaseInterestAccrualSchedule.ChangeDate AS ChangeDate,
	|	LeaseInterestAccrualSchedule.Contract AS Contract,
	|	&Ref AS EffectiveContractTerms,
	|	LeaseInterestAccrualSchedule.Date AS Date,
	|	LeaseInterestAccrualSchedule.Interests AS Interests
	|FROM
	|	InformationRegister.LeaseInterestAccrualSchedule AS LeaseInterestAccrualSchedule
	|WHERE
	|	LeaseInterestAccrualSchedule.EffectiveContractTerms IN
	|			(SELECT
	|				T.EffectiveContractTerms
	|			FROM
	|				TTPreviousTermsAndConditions AS T)
	|	AND LeaseInterestAccrualSchedule.Date < DATEADD(BEGINOFPERIOD(&Period, DAY), DAY, -1)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	CASE
	|		WHEN NOT &AmendmentOfContract
	|			THEN &Contract
	|		ELSE CASE
	|				WHEN ChartTable.Date < BEGINOFPERIOD(&Period, DAY)
	|					THEN &OldContract
	|				ELSE &Contract
	|			END
	|	END,
	|	&Ref,
	|	ChartTable.Date,
	|	ChartTable.Interests
	|FROM
	|	Document.LeaseTermAdjustment.InterestAccrualSchedule AS ChartTable
	|WHERE
	|	ChartTable.Ref = &Ref
	|	AND ChartTable.Date >= DATEADD(BEGINOFPERIOD(&Period, DAY), DAY, -1)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query);

	InitializeTTTableBalancesSettlementsOnFinancialInstruments(Query, QueryTexts);
	QueryTextTableTTFATable(QueryTexts);
	QueryTextTableTTIncomeInCaseOfPartialRepurchase(Query, QueryTexts);
	QueryTextTableTTCostIncrease(Query, QueryTexts);
	QueryTextTableTTCostReduction(Query, QueryTexts);
	QueryTextTableTTAdjustmentOfCalculations(QueryTexts);
	QueryTextTableTTUnnecessarilyAccruedInterest(QueryTexts);
	QueryTextTableTTNonAccruedInterest(QueryTexts);
	
	ListOfMergeRequests = New Array;

	#Region TransferOfLeaseObligations // Dr 76.07.1 - Cr 76.07.1
	QueryText = 
	"SELECT
	|	&Period																AS Period,
	|	VALUE(AccumulationRecordType.Receipt)								AS RecordType,
	|	TTBalancesSettlementsOnFinancialInstruments.AccountingDimensionByPartners 	AS AccountingDimensionByPartners,
	|	TTBalancesSettlementsOnFinancialInstruments.Contract					AS Contract,
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType					AS AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument			AS ARAPDocument,
	|	TTBalancesSettlementsOnFinancialInstruments.Currency						AS Currency,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumBalance				AS Sum,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumManBalance			AS SumMan,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumComplBalance			AS SumCompl,
	|	UNDEFINED														AS ScheduleType,
	|	UNDEFINED														AS DimensionItem,
	|	UNDEFINED														AS RowID,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID		AS FinRecordID,
	|	&BO_LeaseTermAdjustment									AS BusinessOperation,
	|	&SettingUpHO_LeaseTermAdjustment							AS BusinessTransactionSetting
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED),
	|	&Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations),
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument,
	|	&ARAPCurrency,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumBalance,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumManBalance,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumComplBalance,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID,
	|	&BO_LeaseTermAdjustment,
	|	&SettingUpHO_LeaseTermAdjustment
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON (DimensionByPartners.Organization = &Organization)
	|			AND (DimensionByPartners.Partner = &Partner)
	|			AND (DimensionByPartners.Counterparty = &Counterparty)
	|			AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|			AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region TransferOfCurrentLeasePayments // Dr 76.07.2 - Cr 76.07.2
	QueryText = 
	"SELECT
	|	&Period																AS Period,
	|	VALUE(AccumulationRecordType.Receipt)								AS RecordType,
	|	TTBalancesSettlementsOnFinancialInstruments.AccountingDimensionByPartners	AS AccountingDimensionByPartners,
	|	TTBalancesSettlementsOnFinancialInstruments.Contract					AS Contract,
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType					AS AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument			AS ARAPDocument,
	|	TTBalancesSettlementsOnFinancialInstruments.Currency						AS Currency,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumBalance				AS Sum,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumManBalance			AS SumMan,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumComplBalance			AS SumCompl,
	|	UNDEFINED														AS ScheduleType,
	|	UNDEFINED														AS DimensionItem,
	|	UNDEFINED														AS RowID,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID		AS FinRecordID,
	|	&BO_LeaseTermAdjustment									AS BusinessOperation,
	|	&SettingUpHO_LeaseTermAdjustment							AS BusinessTransactionSetting
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType IN (
	|		VALUE(Enum.TypesOfLeasePayments.RentalService),
	|		VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|		AND TTBalancesSettlementsOnFinancialInstruments.SumBalance < 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED),
	|	&Contract,
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument,
	|	&ARAPCurrency,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumBalance,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumManBalance,
	|	-TTBalancesSettlementsOnFinancialInstruments.SumComplBalance,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID,
	|	&BO_LeaseTermAdjustment,
	|	&SettingUpHO_LeaseTermAdjustment
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON (DimensionByPartners.Organization = &Organization)
	|			AND (DimensionByPartners.Partner = &Partner)
	|			AND (DimensionByPartners.Counterparty = &Counterparty)
	|			AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|			AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType IN (
	|		VALUE(Enum.TypesOfLeasePayments.RentalService),
	|		VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|		AND TTBalancesSettlementsOnFinancialInstruments.SumBalance < 0";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region TransferOfAdvancesOfCurrentLeasePayments // Dr 76.07.2 - Cr 76.07.2
	QueryText = 
	"SELECT
	|	&Period																AS Period,
	|	VALUE(AccumulationRecordType.Receipt)								AS RecordType,
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)			AS AccountingDimensionByPartners,
	|	&Contract															AS Contract,
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType					AS AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument			AS ARAPDocument,
	|	&ARAPCurrency												AS Currency,
	|	TTBalancesSettlementsOnFinancialInstruments.SumBalance				AS Sum,
	|	TTBalancesSettlementsOnFinancialInstruments.SumManBalance			AS SumMan,
	|	TTBalancesSettlementsOnFinancialInstruments.SumComplBalance			AS SumCompl,
	|	UNDEFINED														AS ScheduleType,
	|	UNDEFINED														AS DimensionItem,
	|	UNDEFINED														AS RowID,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID		AS FinRecordID,
	|	&BO_LeaseTermAdjustment									AS BusinessOperation,
	|	&SettingUpHO_LeaseTermAdjustment							AS BusinessTransactionSetting
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON (DimensionByPartners.Organization = &Organization)
	|			AND (DimensionByPartners.Partner = &Partner)
	|			AND (DimensionByPartners.Counterparty = &Counterparty)
	|			AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|			AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType IN (
	|		VALUE(Enum.TypesOfLeasePayments.RentalService),
	|		VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|	AND TTBalancesSettlementsOnFinancialInstruments.SumBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	TTBalancesSettlementsOnFinancialInstruments.AccountingDimensionByPartners,
	|	TTBalancesSettlementsOnFinancialInstruments.Contract,
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument,
	|	TTBalancesSettlementsOnFinancialInstruments.Currency,
	|	TTBalancesSettlementsOnFinancialInstruments.SumBalance,
	|	TTBalancesSettlementsOnFinancialInstruments.SumManBalance,
	|	TTBalancesSettlementsOnFinancialInstruments.SumComplBalance,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID,
	|	&BO_LeaseTermAdjustment,
	|	&SettingUpHO_LeaseTermAdjustment
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType IN (
	|		VALUE(Enum.TypesOfLeasePayments.RentalService),
	|		VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|	AND TTBalancesSettlementsOnFinancialInstruments.SumBalance > 0";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region TransferOfInitialLeaseAdvances // Dr 76.07.3 - Cr 76.07.3
	QueryText = 
	"SELECT
	|	&Period																AS Period,
	|	VALUE(AccumulationRecordType.Receipt)								AS RecordType,
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)			AS AccountingDimensionByPartners,
	|	&Contract															AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.DepositPayment)	AS AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument			AS ARAPDocument,
	|	&ARAPCurrency												AS Currency,
	|	TTBalancesSettlementsOnFinancialInstruments.SumBalance				AS Sum,
	|	TTBalancesSettlementsOnFinancialInstruments.SumManBalance			AS SumMan,
	|	TTBalancesSettlementsOnFinancialInstruments.SumComplBalance			AS SumCompl,
	|	UNDEFINED														AS ScheduleType,
	|	UNDEFINED														AS DimensionItem,
	|	UNDEFINED														AS RowID,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID		AS FinRecordID,
	|	&BO_LeaseTermAdjustment									AS BusinessOperation,
	|	&SettingUpHO_LeaseTermAdjustment							AS BusinessTransactionSetting
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON (DimensionByPartners.Organization = &Organization)
	|			AND (DimensionByPartners.Partner = &Partner)
	|			AND (DimensionByPartners.Counterparty = &Counterparty)
	|			AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|			AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	TTBalancesSettlementsOnFinancialInstruments.AccountingDimensionByPartners,
	|	TTBalancesSettlementsOnFinancialInstruments.Contract,
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument,
	|	TTBalancesSettlementsOnFinancialInstruments.Currency,
	|	TTBalancesSettlementsOnFinancialInstruments.SumBalance,
	|	TTBalancesSettlementsOnFinancialInstruments.SumManBalance,
	|	TTBalancesSettlementsOnFinancialInstruments.SumComplBalance,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID,
	|	&BO_LeaseTermAdjustment,
	|	&SettingUpHO_LeaseTermAdjustment
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion 

	#Region TransferOfAdvancesOnRedemptionPayments // Dr 76.07.4 - Cr 76.07.4
	QueryText = 
	"SELECT
	|	&Period																AS Period,
	|	VALUE(AccumulationRecordType.Receipt)								AS RecordType,
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)			AS AccountingDimensionByPartners,
	|	&Contract															AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)	AS AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument			AS ARAPDocument,
	|	&ARAPCurrency												AS Currency,
	|	TTBalancesSettlementsOnFinancialInstruments.SumBalance				AS Sum,
	|	TTBalancesSettlementsOnFinancialInstruments.SumManBalance			AS SumMan,
	|	TTBalancesSettlementsOnFinancialInstruments.SumComplBalance			AS SumCompl,
	|	UNDEFINED														AS ScheduleType,
	|	UNDEFINED														AS DimensionItem,
	|	UNDEFINED														AS RowID,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID		AS FinRecordID,
	|	&BO_LeaseTermAdjustment									AS BusinessOperation,
	|	&SettingUpHO_LeaseTermAdjustment							AS BusinessTransactionSetting
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON (DimensionByPartners.Organization = &Organization)
	|			AND (DimensionByPartners.Partner = &Partner)
	|			AND (DimensionByPartners.Counterparty = &Counterparty)
	|			AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|			AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType = VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	TTBalancesSettlementsOnFinancialInstruments.AccountingDimensionByPartners,
	|	TTBalancesSettlementsOnFinancialInstruments.Contract,
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument,
	|	TTBalancesSettlementsOnFinancialInstruments.Currency,
	|	TTBalancesSettlementsOnFinancialInstruments.SumBalance,
	|	TTBalancesSettlementsOnFinancialInstruments.SumManBalance,
	|	TTBalancesSettlementsOnFinancialInstruments.SumComplBalance,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID,
	|	&BO_LeaseTermAdjustment,
	|	&SettingUpHO_LeaseTermAdjustment
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType = VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region TransferOfInterestOnLeaseObligations // Dr 76.07.5 - Cr 76.07.5
	QueryText = 
	"SELECT
	|	&Period																AS Period,
	|	VALUE(AccumulationRecordType.Receipt)								AS RecordType,
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)			AS AccountingDimensionByPartners,
	|	&Contract															AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.Interests)				AS AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument			AS ARAPDocument,
	|	&ARAPCurrency												AS Currency,
	|	TTBalancesSettlementsOnFinancialInstruments.SumBalance				AS Sum,
	|	TTBalancesSettlementsOnFinancialInstruments.SumManBalance			AS SumMan,
	|	TTBalancesSettlementsOnFinancialInstruments.SumComplBalance			AS SumCompl,
	|	UNDEFINED														AS ScheduleType,
	|	UNDEFINED														AS DimensionItem,
	|	UNDEFINED														AS RowID,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID		AS FinRecordID,
	|	&BO_LeaseTermAdjustment									AS BusinessOperation,
	|	&SettingUpHO_LeaseTermAdjustment							AS BusinessTransactionSetting
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON (DimensionByPartners.Organization = &Organization)
	|			AND (DimensionByPartners.Partner = &Partner)
	|			AND (DimensionByPartners.Counterparty = &Counterparty)
	|			AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|			AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	TTBalancesSettlementsOnFinancialInstruments.AccountingDimensionByPartners,
	|	TTBalancesSettlementsOnFinancialInstruments.Contract,
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument,
	|	TTBalancesSettlementsOnFinancialInstruments.Currency,
	|	TTBalancesSettlementsOnFinancialInstruments.SumBalance,
	|	TTBalancesSettlementsOnFinancialInstruments.SumManBalance,
	|	TTBalancesSettlementsOnFinancialInstruments.SumComplBalance,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID,
	|	&BO_LeaseTermAdjustment,
	|	&SettingUpHO_LeaseTermAdjustment
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region TransferOfVATOnRentalObligations // Dr 76.07.5 - Cr 76.07.5
	QueryText = 
	"SELECT
	|	&Period																AS Period,
	|	VALUE(AccumulationRecordType.Receipt)								AS RecordType,
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)			AS AccountingDimensionByPartners,
	|	&Contract															AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.VAT)						AS AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument			AS ARAPDocument,
	|	&ARAPCurrency												AS Currency,
	|	TTBalancesSettlementsOnFinancialInstruments.SumBalance				AS Sum,
	|	TTBalancesSettlementsOnFinancialInstruments.SumManBalance			AS SumMan,
	|	TTBalancesSettlementsOnFinancialInstruments.SumComplBalance			AS SumCompl,
	|	UNDEFINED														AS ScheduleType,
	|	UNDEFINED														AS DimensionItem,
	|	UNDEFINED														AS RowID,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID		AS FinRecordID,
	|	&BO_LeaseTermAdjustment									AS BusinessOperation,
	|	&SettingUpHO_LeaseTermAdjustment							AS BusinessTransactionSetting
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON (DimensionByPartners.Organization = &Organization)
	|			AND (DimensionByPartners.Partner = &Partner)
	|			AND (DimensionByPartners.Counterparty = &Counterparty)
	|			AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|			AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	TTBalancesSettlementsOnFinancialInstruments.AccountingDimensionByPartners,
	|	TTBalancesSettlementsOnFinancialInstruments.Contract,
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType,
	|	TTBalancesSettlementsOnFinancialInstruments.ARAPDocument,
	|	TTBalancesSettlementsOnFinancialInstruments.Currency,
	|	TTBalancesSettlementsOnFinancialInstruments.SumBalance,
	|	TTBalancesSettlementsOnFinancialInstruments.SumManBalance,
	|	TTBalancesSettlementsOnFinancialInstruments.SumComplBalance,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TTBalancesSettlementsOnFinancialInstruments.FinRecordID,
	|	&BO_LeaseTermAdjustment,
	|	&SettingUpHO_LeaseTermAdjustment
	|FROM
	|	TTBalancesSettlementsOnFinancialInstruments AS TTBalancesSettlementsOnFinancialInstruments
	|WHERE
	|	TTBalancesSettlementsOnFinancialInstruments.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region GenerationOfLeasedFixedAssetsCost // Dr 08.04 - Cr 76.07.1
	QueryText = 
	"SELECT
	|	&Period                                                                      AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                       AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	&Contract                                                                     AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)            AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	&ARAPCurrency                                                        AS Currency,
	|	
	|	FATable.Cost AS Sum,
	|
	|	FATable.CostInManagementAccounting AS SumMan,
	|	FATable.CostInAccounting AS SumCompl,
	|	
	|	UNDEFINED                                                                 AS ScheduleType,
	|	UNDEFINED                                                                 AS DimensionItem,
	|	FATable.RowID                                                AS RowID,
	|	FATable.RowID                                                AS FinRecordID,
	|	&BO_GenerationOfLeasedFixedAssetsCost                                      AS BusinessOperation,
	|	&SettingUpHO_FORMINGCostOfLeasedFA                             AS BusinessTransactionSetting
	|FROM
	|	TTFATable AS FATable
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	FATable.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.Rent)
	|	AND (&ThereIsMaAccount OR &ThereIsACAccounting)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region FixedAssetsCostAddition // Dt <01.03> - Ct <76.07.1>
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	&Contract AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations) AS AmountType,
	|	UNDEFINED AS ARAPDocument,
	|	&ARAPCurrency AS Currency,
	|
	|	CASE
	|		WHEN CostIncrease.LocalCost <> 0
	|			THEN CostIncrease.LocalCost * CASE
	|				WHEN &ARAPCurrency = &LocalAccountingCurrency
	|					THEN 1
	|				ELSE &ConversionFactorFromLocalCurrency
	|			END
	|		WHEN CostIncrease.Cost <> 0
	|			THEN CostIncrease.Cost * CASE
	|				WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|					THEN 1
	|				ELSE &ConversionFactorFromManCurrency
	|			END
	|		ELSE 0
	|	END AS Sum,
	|
	|	CostIncrease.Cost AS SumMan,
	|	CostIncrease.LocalCost AS SumCompl,
	|	UNDEFINED AS ScheduleType,
	|	UNDEFINED AS DimensionItem,
	|	CostIncrease.RowID AS RowID,
	|	CostIncrease.RowID AS FinRecordID,
	|	CASE
	|		WHEN CostIncrease.Sublease THEN
	|			&BO_GenerationOfLeasedFixedAssetsCost
	|		ELSE
	|			&BO_LeasedFixedAssetsCostAddition
	|	END AS BusinessOperation,
	|	CASE
	|		WHEN CostIncrease.Sublease THEN
	|			&SettingUpHO_FORMINGCostOfLeasedFA
	|		ELSE
	|			&SettingUpHO_IncreasingCostOfRentedFA
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTCostIncrease AS CostIncrease
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|		AND DimensionByPartners.Partner = &Partner
	|		AND DimensionByPartners.Counterparty = &Counterparty
	|		AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	CostIncrease.Cost <> 0
	|	OR CostIncrease.LocalCost <> 0";

	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region FixedAssetsCostDecrease // Dt <76.07.1> - Ct <01.03>
	QueryText =
	"SELECT
	|	&Period                                                           AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                            AS RecordType,
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)        AS AccountingDimensionByPartners,
	|	&Contract                                                          AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations) AS AmountType,
	|	UNDEFINED                                                      AS ARAPDocument,
	|	&ARAPCurrency                                             AS Currency,
	|	
	|	CASE
	|		WHEN CostReduction.LocalCost <> 0
	|			THEN CostReduction.LocalCost
	|					* CASE
	|						WHEN &ARAPCurrency = &LocalAccountingCurrency
	|							THEN 1
	|						ELSE &ConversionFactorFromLocalCurrency
	|					END
	|		WHEN CostReduction.Cost <> 0
	|			THEN CostReduction.Cost
	|					* CASE
	|						WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|							THEN 1
	|						ELSE &ConversionFactorFromManCurrency
	|					END
	|		ELSE 0
	|	END AS Sum,
	|
	|	CostReduction.Cost                                     AS SumMan,
	|	CostReduction.LocalCost                                 AS SumCompl,
	|	
	|	UNDEFINED                                                      AS ScheduleType,
	|	UNDEFINED                                                      AS DimensionItem,
	|	CostReduction.RowID                           AS RowID,
	|	CostReduction.RowID                           AS FinRecordID,
	|	CASE
	|		WHEN CostReduction.Sublease THEN
	|			&BO_GenerationOfLeasedFixedAssetsCost
	|		ELSE
	|			&BO_DecreaseOfLeasedFixedAssetsCost
	|	END AS BusinessOperation,
	|	CASE
	|		WHEN CostReduction.Sublease THEN
	|			&SettingUpHO_FORMINGCostOfLeasedFA
	|		ELSE
	|			&SettingUpHO_ReducingCostOfLeasedFA
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTCostReduction AS CostReduction
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	(CostReduction.Cost <> 0
	|		OR CostReduction.LocalCost <> 0)";

	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region VATIncrease // Dt <76.07.9> - Ct <76.07.1>
	QueryText = 
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.VAT)                         AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	Calculations.VATAmount                                                        AS Sum,
	|	Calculations.VATAmountMan                                                     AS SumMan,
	|	Calculations.VATAmountCompl                                                    AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_IncreaseOfVATOnLease                                               AS BusinessOperation,
	|	&SettingUpHO_IncreaseInRentalVAT                                      AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfCalculations AS Calculations
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Calculations.VATAmount > 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)       AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	Calculations.VATAmount                                                        AS Sum,
	|	Calculations.VATAmountMan                                                     AS SumMan,
	|	Calculations.VATAmountCompl                                                    AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_IncreaseOfVATOnLease                                               AS BusinessOperation,
	|	&SettingUpHO_IncreaseInRentalVAT                                      AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfCalculations AS Calculations
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Calculations.VATAmount > 0";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region VATReduction // Dt <76.07.1> - Ct <76.07.9>
	QueryText = 
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)       AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	-Calculations.VATAmount                                                       AS Sum,
	|	-Calculations.VATAmountMan                                                    AS SumMan,
	|	-Calculations.VATAmountCompl                                                   AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_DecreaseOfVATOnLease                                               AS BusinessOperation,
	|	&SettingUpHO_ReductionOfVATForRent                                      AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfCalculations AS Calculations
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Calculations.VATAmount < 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.VAT)                         AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	-Calculations.VATAmount                                                       AS Sum,
	|	-Calculations.VATAmountMan                                                    AS SumMan,
	|	-Calculations.VATAmountCompl                                                   AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_DecreaseOfVATOnLease                                               AS BusinessOperation,
	|	&SettingUpHO_ReductionOfVATForRent                                      AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfCalculations AS Calculations
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Calculations.VATAmount < 0";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region IncreaseInInterest // Dt <76.07.5> - Ct <76.07.1>
	QueryText = 
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.Interests)                    AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	Calculations.InterestAmount                                                  AS Sum,
	|	Calculations.AmountOfInterestMan                                               AS SumMan,
	|	Calculations.LocalInterestAmount                                              AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_IncreaseOfLeaseInterest                                         AS BusinessOperation,
	|	&SettingUpHO_IncreaseInRentalInterest                                AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfCalculations AS Calculations
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Calculations.InterestAmount > 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)       AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	Calculations.InterestAmount                                                  AS Sum,
	|	Calculations.AmountOfInterestMan                                               AS SumMan,
	|	Calculations.LocalInterestAmount                                              AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_IncreaseOfLeaseInterest                                         AS BusinessOperation,
	|	&SettingUpHO_IncreaseInRentalInterest                                AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfCalculations AS Calculations
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Calculations.InterestAmount > 0";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region InterestReduction // Dt <76.07.1> - Ct <76.07.5>
	QueryText = 
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)       AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	-Calculations.InterestAmount                                                 AS Sum,
	|	-Calculations.AmountOfInterestMan                                              AS SumMan,
	|	-Calculations.LocalInterestAmount                                             AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_DecreaseOfLeaseInterest                                         AS BusinessOperation,
	|	&SettingUpHO_DecreaseInRentalInterest                                AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfCalculations AS Calculations
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Calculations.InterestAmount < 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.Interests)                    AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	-Calculations.InterestAmount                                                 AS Sum,
	|	-Calculations.AmountOfInterestMan                                              AS SumMan,
	|	-Calculations.LocalInterestAmount                                             AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_DecreaseOfLeaseInterest                                         AS BusinessOperation,
	|	&SettingUpHO_DecreaseInRentalInterest                                AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfCalculations AS Calculations
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Calculations.InterestAmount < 0";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region OverchargedInterest // Dt <76.07.5> - Ct <91.01>
	QueryText = 
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.Interests)                    AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	Calculations.Sum                                                           AS Sum,
	|	Calculations.SumMan                                                        AS SumMan,
	|	Calculations.SumCompl                                                       AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_OverchargedLeaseInterest                                  AS BusinessOperation,
	|	&SettingUpHO_UnnecessarilyAccruedRentalInterest                         AS BusinessTransactionSetting
	|FROM
	|	TTUnnecessarilyAccruedInterest AS Calculations
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	&CreatedForTransition";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region NonAccruedInterest // Dt <91.02> - Ct <76.07.5>
	QueryText = 
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.Interests)                    AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	Calculations.Sum                                                           AS Sum,
	|	Calculations.SumMan                                                        AS SumMan,
	|	Calculations.SumCompl                                                       AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_UnderchargedLeaseInterest                                     AS BusinessOperation,
	|	&SettingUpHO_NonAccruedRentalInterest                            AS BusinessTransactionSetting
	|FROM
	|	TTNonAccruedInterest AS Calculations
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	&CreatedForTransition";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region RecordingLeaseLiabilitiesInIncome // Dt <76.07.1> - Ct <Income>
	QueryText =
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)       AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	TableRevenue.Sum                                                     AS Sum,
	|	TableRevenue.SumMan                                                  AS SumMan,
	|	TableRevenue.SumCompl                                                 AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,
	|	TableRevenue.FinRecordID                                    AS FinRecordID,
	|	TableRevenue.BusinessOperation                                     AS BusinessOperation,
	|	TableRevenue.BusinessTransactionSetting                            AS BusinessTransactionSetting
	|FROM
	|	TTIncomeInCaseOfPartialRepurchase AS TableRevenue
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON (DimensionByPartners.Organization = &Organization)
	|			AND (DimensionByPartners.Partner = &Partner)
	|			AND (DimensionByPartners.Counterparty = &Counterparty)
	|			AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|			AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)

	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);
	InitializeTTTableFACostAdjustmentByShares(Query, QueryTexts);
	QueryTextTableTTNonAccruedInterest(QueryTexts);

	QueryText =
	"SELECT
	|	&Period                           AS Period,
	|	&Organization                      AS Organization,
	|	&BusinessUnitInterest            AS Department,
	|	&LineOfBusiness          AS LineOfBusiness,
	|	&ExpenseItem                   AS AssetRef,
	|	&AssetsLiabilitiesDimensionExpenses  AS Dimension,
	|	&GlAccountSettingsExpenses      AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInLocalAccounting
	|			THEN CASE
	|					WHEN TT_DepreciationOfVNA.AccrueDepreciation
	|						THEN 0
	|					ELSE CASE
	|							WHEN ISNULL(TT_CostOfVNA.LocalCost, 0) > 0
	|								THEN (1 - (TT_CostOfVNA.LocalCost - Interests.LocalInterestAmount) / TT_CostOfVNA.LocalCost) 
	|										* TT_DepreciationOfVNA.DepreciationLocal
	|							ELSE 0
	|						END
	|				END
	|		ELSE 0
	|	END AS SumCompl,
	|
	|	0 AS PermanentDifference,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInLocalAccounting
	|			THEN CASE
	|					WHEN TT_DepreciationOfVNA.AccrueDepreciation
	|						THEN 0
	|					ELSE CASE
	|							WHEN ISNULL(TT_CostOfVNA.LocalCost, 0) > 0
	|								THEN (1 - (TT_CostOfVNA.LocalCost - Interests.LocalInterestAmount) / TT_CostOfVNA.LocalCost) 
	|										* TT_DepreciationOfVNA.DepreciationLocal
	|							ELSE 0
	|						END
	|				END
	|		ELSE 0
	|	END AS CostTD,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInManAccounting
	|			THEN CASE
	|					WHEN ISNULL(TT_CostOfVNA.Cost, 0) > 0
	|						THEN (1 - (TT_CostOfVNA.Cost - Interests.AmountOfInterestMan) / TT_CostOfVNA.Cost) 
	|								* TT_DepreciationOfVNA.Depreciation
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInManAccounting
	|			THEN CASE
	|					WHEN ISNULL(TT_CostOfVNA.Cost, 0) > 0
	|						THEN (1 - (TT_CostOfVNA.Cost - Interests.AmountOfInterestMan) / TT_CostOfVNA.Cost) 
	|								* TT_DepreciationOfVNA.Depreciation
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS AmountIncludingVAT,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInManAccounting
	|			THEN CASE
	|					WHEN ISNULL(TT_CostOfVNA.Cost, 0) > 0
	|						THEN (1 - (TT_CostOfVNA.Cost - Interests.AmountOfInterestMan) / TT_CostOfVNA.Cost) 
	|								* TT_DepreciationOfVNA.Depreciation
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|
	|	Interests.RowID                      AS FinRecordID,
	|	&SettingHO_ReductionOfDepreciation     AS BusinessTransactionSetting
	|FROM
	|	TTFACostAdjustmentByShares AS Interests
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON Interests.FixedAsset = TT_CostOfVNA.AccountingObject
	|			AND (TT_CostOfVNA.Ref = &Ref)
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS TT_DepreciationOfVNA
	|		ON Interests.FixedAsset = TT_DepreciationOfVNA.AccountingObject
	|			AND (TT_DepreciationOfVNA.Ref = &Ref)
	|
	|		INNER JOIN TTAccountingInformation AS TTAccountingInformation
	|		ON TTAccountingInformation.FixedAsset = Interests.FixedAsset
	|WHERE
	|	VALUETYPE(&ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND &CreatedForTransition
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                           AS Period,
	|	&Organization                      AS Organization,
	|	&BusinessUnitInterest            AS Department,
	|	&LineOfBusiness          AS LineOfBusiness,
	|	&ExpenseItem                   AS AssetRef,
	|	&AssetsLiabilitiesDimensionExpenses  AS Dimension,
	|	&GlAccountSettingsExpenses      AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TableExpenses.SumCompl AS SumCompl,
	|
	|	0 AS PermanentDifference,
	|
	|	TableExpenses.SumCompl AS CostTD,
	|
	|	TableExpenses.SumMan AS SumMan,
	|	TableExpenses.SumMan AS AmountIncludingVAT,
	|	TableExpenses.SumMan AS AmountExcludingVAT,
	|
	|	&DocumentID AS FinRecordID,
	|	&SettingUpHO_NonAccruedRentalInterest AS BusinessTransactionSetting
	|FROM
	|	TTNonAccruedInterest AS TableExpenses
	|WHERE
	|	VALUETYPE(&ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND &CreatedForTransition";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers) Export
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherIncome(Query, QueryTexts, Registers)

	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	QueryTextTableTTUnnecessarilyAccruedInterest(QueryTexts);
	QueryTextTableTTIncomeInCaseOfPartialRepurchase(Query, QueryTexts);
	InitializeTTTableFACostAdjustmentByShares(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region OverchargedInterest
	QueryText =
	"SELECT
	|	&Period                                           AS Period,
	|	&Organization                                      AS Organization,
	|	&Department                                    AS Department,
	|	&LineOfBusiness                          AS LineOfBusiness,
	|	&IncomeItem                                    AS IncomeItem,
	|	&DimensionOfRevenue                                 AS DimensionOfRevenue,
	|
	|	TableRevenue.Sum                               AS Sum,
	|	TableRevenue.SumMan                            AS SumMan,
	|	TableRevenue.SumCompl                           AS SumCompl,
	|	0                                                 AS PermanentDifference,
	|	TableRevenue.SumCompl                           AS CostTD,
	|
	|	&DocumentID                           AS FinRecordID,
	|	&BO_OverchargedLeaseInterest            AS BusinessOperation,
	|	&SettingUpHO_UnnecessarilyAccruedRentalInterest   AS BusinessTransactionSetting
	|FROM
	|	TTUnnecessarilyAccruedInterest AS TableRevenue
	|WHERE
	|	VALUETYPE(&IncomeItem) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|	AND &CreatedForTransition";
	ListOfMergeRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ExcessOfPPAReductionOverBookValue
	QueryText =
	"SELECT
	|	&Period                                               AS Period,
	|	&Organization                                          AS Organization,
	|	&Department                                        AS Department,
	|	&LineOfBusiness                              AS LineOfBusiness,
	|	&IncomeItem                                        AS IncomeItem,
	|	&DimensionOfRevenue                                     AS DimensionOfRevenue,
	|
	|	CASE
	|		WHEN CostReduction.Cost > BookValue.BookValueOfMan THEN
	|			CostReduction.Cost - BookValue.BookValueOfMan
	|		ELSE 0
	|		END                                             AS Sum,
	|
	|	CASE
	|		WHEN CostReduction.Cost > BookValue.BookValueOfMan THEN
	|			CostReduction.Cost - BookValue.BookValueOfMan
	|		ELSE 0
	|		END                                             AS SumMan,
	|	
	|	CASE
	|		WHEN CostReduction.LocalCost > BookValue.LocalBookValue THEN
	|			CostReduction.LocalCost - BookValue.LocalBookValue
	|		ELSE 0
	|		END                                             AS SumCompl,
	|	0                                                     AS PermanentDifference,
	|	CASE
	|		WHEN CostReduction.LocalCost > BookValue.LocalBookValue THEN
	|			CostReduction.LocalCost - BookValue.LocalBookValue
	|		ELSE 0
	|	END                                                 AS CostTD,
	|	
	|	CostReduction.RowID               AS FinRecordID,
	|	&BO_DecreaseOfLeasedFixedAssetsCost                 AS BusinessOperation,
	|	&SettingUpHO_ReducingCostOfLeasedFA        AS BusinessTransactionSetting
	|	
	|FROM
	|	TTCostReduction AS CostReduction
	|		LEFT JOIN TTBookValueFA AS BookValue
	|		ON CostReduction.FixedAsset = BookValue.FixedAsset
	|WHERE
	|	NOT CostReduction.Sublease
	|	AND (CASE
	|		WHEN CostReduction.Cost > BookValue.BookValueOfMan THEN
	|			CostReduction.Cost - BookValue.BookValueOfMan
	|		ELSE 0
	|		END > 0
	|
	|	OR
	|
	|	CASE
	|		WHEN CostReduction.LocalCost > BookValue.LocalBookValue THEN
	|			CostReduction.LocalCost - BookValue.LocalBookValue
	|		ELSE 0
	|		END > 0)
	|";
	
	ListOfMergeRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ReductionOfDepreciationDuringTransitionToFSB25
	QueryText =
	"SELECT
	|	&Period                                  AS Period,
	|	&Organization                             AS Organization,
	|	TTAccountingInformation.FixedAssetsLocation        AS Department,
	|	&LineOfBusiness                 AS LineOfBusiness,
	|	&IncomeItem                           AS IncomeItem,
	|	&DimensionOfRevenue                        AS DimensionOfRevenue,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInManAccounting
	|			THEN CASE
	|					WHEN ISNULL(TT_CostOfVNA.Cost, 0) <> 0 
	|						THEN (1 - (TT_CostOfVNA.Cost - Interests.AmountOfInterestMan) / TT_CostOfVNA.Cost) 
	|								* TT_DepreciationOfVNA.Depreciation
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInManAccounting
	|			THEN CASE
	|					WHEN ISNULL(TT_CostOfVNA.Cost, 0) <> 0
	|						THEN (1 - (TT_CostOfVNA.Cost - Interests.AmountOfInterestMan) / TT_CostOfVNA.Cost) 
	|								* TT_DepreciationOfVNA.Depreciation
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN TTAccountingInformation.RecordInLocalAccounting
	|			THEN CASE
	|					WHEN TT_DepreciationOfVNA.AccrueDepreciation
	|						THEN 0
	|					ELSE CASE
	|							WHEN ISNULL(TT_CostOfVNA.LocalCost, 0) <> 0
	|								THEN (1 - (TT_CostOfVNA.LocalCost - Interests.LocalInterestAmount) / TT_CostOfVNA.LocalCost) 
	|										* TT_DepreciationOfVNA.DepreciationLocal
	|							ELSE 0
	|						END
	|				END
	|		ELSE 0
	|	END AS SumCompl,
	|	0 AS PermanentDifference,
	|	CASE
	|		WHEN TTAccountingInformation.RecordInLocalAccounting
	|			THEN CASE
	|					WHEN TT_DepreciationOfVNA.AccrueDepreciation
	|						THEN 0
	|					ELSE CASE
	|							WHEN ISNULL(TT_CostOfVNA.LocalCost, 0) <> 0
	|								THEN (1 - (TT_CostOfVNA.LocalCost - Interests.LocalInterestAmount) / TT_CostOfVNA.LocalCost) 
	|										* TT_DepreciationOfVNA.DepreciationLocal
	|							ELSE 0
	|						END
	|				END
	|		ELSE 0
	|	END AS CostTD,
	|
	|	Interests.RowID AS FinRecordID,
	|	&BO_DecreaseInDepreciation AS BusinessOperation,
	|	&SettingHO_ReductionOfDepreciation AS BusinessTransactionSetting
	|FROM
	|	TTFACostAdjustmentByShares AS Interests
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON Interests.FixedAsset = TT_CostOfVNA.AccountingObject
	|			AND (TT_CostOfVNA.Ref = &Ref)
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS TT_DepreciationOfVNA
	|		ON Interests.FixedAsset = TT_DepreciationOfVNA.AccountingObject
	|			AND (TT_DepreciationOfVNA.Ref = &Ref)
	|
	|		INNER JOIN TTAccountingInformation AS TTAccountingInformation
	|		ON Interests.FixedAsset = TTAccountingInformation.FixedAsset
	|WHERE
	|	VALUETYPE(&IncomeItem) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|	AND VALUETYPE(&ExpenseItem) <> TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND &CreatedForTransition";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region RecordingLeaseLiabilitiesInIncome // Dt <76.07.1> - Ct <Income>
	QueryText =
	"SELECT
	|	&Period												AS Period,
	|	&Organization										AS Organization,
	|	TTAccountingInformation.FixedAssetsLocation					AS Department,
	|	&LineOfBusiness							AS LineOfBusiness,
	|	&IncomeItem										AS IncomeItem,
	|	&DimensionOfRevenue									AS DimensionOfRevenue,
	|
	|	Income.Sum 										AS Sum,
	|	Income.SumMan 									AS SumMan,
	|	Income.SumCompl 									AS SumCompl,
	|	0                                                   AS PermanentDifference,
	|	Income.SumCompl                                    AS CostTD,
	|
	|	Income.FinRecordID						AS FinRecordID,
	|	&BO_RecordingLeaseLiabilitiesInIncome			AS BusinessOperation,
	|	&SettingUpHO_ReflectionOfLeaseObligationsInIncome	AS BusinessTransactionSetting
	|FROM
	|	TTIncomeInCaseOfPartialRepurchase AS Income
	|		INNER JOIN TTAccountingInformation AS TTAccountingInformation
	|		ON Income.FixedAsset = TTAccountingInformation.FixedAsset";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableGoodsForRegistrationOfImportDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsForRegistrationOfImportDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTPreviousTermsAndConditions(QueryTexts);  
	
	QueryText = 
	"SELECT
	|	ENDOFPERIOD(GoodsForRegistrationOfImportDocumentsBalanceAndTurnovers.Period, MONTH) AS Period,
	|	GoodsForRegistrationOfImportDocumentsBalanceAndTurnovers.SumClosingBalance AS SumClosingBalance
	|INTO TTGoodsForRegistrationOfImportDocumentsBalance
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.BalanceAndTurnovers(,, Month,,
	|		DocumentInflow = &DocumentOfConclusionOfContractOfLease
	|	AND ImportDocumentType = &IdApplicationForImportOfGoods) AS GoodsForRegistrationOfImportDocumentsBalanceAndTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ENDOFPERIOD(PreviousScheduleOfPaymentForRentalServices.Date, MONTH) AS Period,
	|	SUM(PreviousScheduleOfPaymentForRentalServices.RentalService) AS RentalService,
	|	SUM(PreviousScheduleOfPaymentForRentalServices.DepositPayment) AS DepositPayment,
	|	SUM(PreviousScheduleOfPaymentForRentalServices.BuyoutValue) AS BuyoutValue,
	|	SUM(PreviousScheduleOfPaymentForRentalServices.BuyoutValuePrepayment) AS BuyoutValuePrepayment
	|INTO TTPreviousScheduleOfPaymentForRentalServices
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS PreviousScheduleOfPaymentForRentalServices
	|		INNER JOIN TTPreviousTermsAndConditions AS TTPreviousTermsAndConditions
	|		ON PreviousScheduleOfPaymentForRentalServices.EffectiveContractTerms = TTPreviousTermsAndConditions.EffectiveContractTerms
	|WHERE
	|	&RegisterImportApplications
	|GROUP BY
	|	ENDOFPERIOD(PreviousScheduleOfPaymentForRentalServices.Date, MONTH)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ENDOFPERIOD(CurCurrentPaymentScheduleForRentalServices.Date, MONTH) AS Period,
	|	SUM(CurCurrentPaymentScheduleForRentalServices.RentalService) AS RentalService,
	|	SUM(CurCurrentPaymentScheduleForRentalServices.DepositPayment) AS DepositPayment,
	|	SUM(CurCurrentPaymentScheduleForRentalServices.BuyoutValue) AS BuyoutValue
	|INTO TTCurCurrentPaymentScheduleForRentalServices
	|FROM
	|	Document.LeaseTermAdjustment.ServicePaymentSchedule AS CurCurrentPaymentScheduleForRentalServices
	|WHERE
	|	CurCurrentPaymentScheduleForRentalServices.Ref = &Ref
	|	AND &RegisterImportApplications
	|GROUP BY
	|	ENDOFPERIOD(CurCurrentPaymentScheduleForRentalServices.Date, MONTH)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTCurCurrentPaymentScheduleForRentalServices.Period, TTPreviousScheduleOfPaymentForRentalServices.Period) AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Ref AS Recorder,
	|	&Organization AS Organization,
	|	&Partner AS Vendor,
	|	&DocumentOfConclusionOfContractOfLease AS DocumentInflow,
	|	&IdApplicationForImportOfGoods AS ImportDocumentType,
	|	0 AS Count,
	|	0 AS QuantityByGBRN,
	|	-(TTPreviousScheduleOfPaymentForRentalServices.RentalService + TTPreviousScheduleOfPaymentForRentalServices.DepositPayment +
	|		TTPreviousScheduleOfPaymentForRentalServices.BuyoutValue +
	|		TTPreviousScheduleOfPaymentForRentalServices.BuyoutValuePrepayment) AS Sum,
	|	TRUE AS Primary
	|FROM
	|	TTPreviousScheduleOfPaymentForRentalServices AS TTPreviousScheduleOfPaymentForRentalServices
	|		LEFT JOIN TTCurCurrentPaymentScheduleForRentalServices AS TTCurCurrentPaymentScheduleForRentalServices
	|		ON TTPreviousScheduleOfPaymentForRentalServices.Period = TTCurCurrentPaymentScheduleForRentalServices.Period
	|		LEFT JOIN TTGoodsForRegistrationOfImportDocumentsBalance AS TTGoodsForRegistrationOfImportDocumentsBalance
	|		ON TTPreviousScheduleOfPaymentForRentalServices.Period = TTGoodsForRegistrationOfImportDocumentsBalance.Period
	|WHERE
	|	(ISNULL(TTGoodsForRegistrationOfImportDocumentsBalance.SumClosingBalance, 0) <> 0
	|	OR TTGoodsForRegistrationOfImportDocumentsBalance.SumClosingBalance IS NULL)
	|	AND TTPreviousScheduleOfPaymentForRentalServices.RentalService + TTPreviousScheduleOfPaymentForRentalServices.DepositPayment
	|		+ TTPreviousScheduleOfPaymentForRentalServices.BuyoutValue +
	|		TTPreviousScheduleOfPaymentForRentalServices.BuyoutValuePrepayment <> ISNULL(TTCurCurrentPaymentScheduleForRentalServices.RentalService
	|		+ TTCurCurrentPaymentScheduleForRentalServices.DepositPayment + TTCurCurrentPaymentScheduleForRentalServices.BuyoutValue,
	|		0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTCurCurrentPaymentScheduleForRentalServices.Period,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Ref,
	|	&Organization,
	|	&Partner,
	|	&DocumentOfConclusionOfContractOfLease,
	|	&IdApplicationForImportOfGoods,
	|	0,
	|	0,
	|	TTCurCurrentPaymentScheduleForRentalServices.RentalService + TTCurCurrentPaymentScheduleForRentalServices.DepositPayment +
	|		TTCurCurrentPaymentScheduleForRentalServices.BuyoutValue,
	|	TRUE
	|FROM
	|	TTCurCurrentPaymentScheduleForRentalServices AS TTCurCurrentPaymentScheduleForRentalServices
	|		LEFT JOIN TTGoodsForRegistrationOfImportDocumentsBalance AS TTGoodsForRegistrationOfImportDocumentsBalance
	|		ON TTCurCurrentPaymentScheduleForRentalServices.Period = TTGoodsForRegistrationOfImportDocumentsBalance.Period
	|		LEFT JOIN TTPreviousScheduleOfPaymentForRentalServices AS TTPreviousScheduleOfPaymentForRentalServices
	|		ON TTCurCurrentPaymentScheduleForRentalServices.Period = TTPreviousScheduleOfPaymentForRentalServices.Period
	|WHERE
	|	(ISNULL(TTGoodsForRegistrationOfImportDocumentsBalance.SumClosingBalance, 0) <> 0
	|	OR TTGoodsForRegistrationOfImportDocumentsBalance.SumClosingBalance IS NULL)
	|	AND TTCurCurrentPaymentScheduleForRentalServices.RentalService + TTCurCurrentPaymentScheduleForRentalServices.DepositPayment +
	|		TTCurCurrentPaymentScheduleForRentalServices.BuyoutValue <> ISNULL(TTPreviousScheduleOfPaymentForRentalServices.RentalService
	|		+ TTPreviousScheduleOfPaymentForRentalServices.DepositPayment +
	|		TTPreviousScheduleOfPaymentForRentalServices.BuyoutValue +
	|		TTPreviousScheduleOfPaymentForRentalServices.BuyoutValuePrepayment, 0)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.IBDocumentDate AS IBDocumentDate,
	|	DocumentData.IBDocumentNumber AS IBDocumentNumber,
	|	DocumentData.RefType AS RefType,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Department AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.AdditionalRecord AS AdditionalRecord,
	|	DocumentData.SourceDocumentDate AS SourceDocumentDate,
	|	DocumentData.SourceDocumentNumber AS SourceDocumentNumber,
	|	DocumentData.Sum AS Sum,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.RecordingInAccountingDate AS RecordingInAccountingDate
	|FROM
	|	(SELECT
	|		DocumentData.Ref AS Ref,
	|		&Period AS IBDocumentDate,
	|		&Number AS IBDocumentNumber,
	|		&MetadataIdentifier AS RefType,
	|		&BusinessOperation AS BusinessOperation,
	|		&Organization AS Organization,
	|		DocumentData.Partner AS Partner,
	|		DocumentData.Counterparty AS Counterparty,
	|		DocumentData.Contract AS Contract,
	|		&Department AS Department,
	|		&EmployeeResponsible AS EmployeeResponsible,
	|		&Comment AS Comment,
	|		&Posted AS Posted,
	|		&DeletionMark AS DeletionMark,
	|		FALSE AS AdditionalRecord,
	|		&Period AS SourceDocumentDate,
	|		&NumberForPrinting AS SourceDocumentNumber,
	|		&DocumentAmount AS Sum,
	|		&Currency AS Currency,
	|		&Period AS RecordingInAccountingDate
	|	FROM
	|		Document.LeaseTermAdjustment AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref,
	|		&Period,
	|		&Number,
	|		&MetadataIdentifier,
	|		VALUE(Enum.BusinessTransactions.SigningOfLeaseContract),
	|		&Organization,
	|		DocumentData.NewPartner,
	|		DocumentData.NewCounterparty,
	|		DocumentData.NewContract,
	|		&Department,
	|		&EmployeeResponsible,
	|		&Comment,
	|		&Posted,
	|		&DeletionMark,
	|		TRUE,
	|		&Period,
	|		&NumberForPrinting,
	|		&DocumentAmount,
	|		&Currency,
	|		&Period
	|	FROM
	|		Document.LeaseTermAdjustment AS DocumentData
	|	WHERE
	|		DocumentData.NewContract <> VALUE(Catalog.LeaseContract.EmptyRef)
	|		AND DocumentData.Ref = &Ref) AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)    AS RecNo,
	|	&Ref                                 AS Ref,
	|	&Period                                 AS Date,
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	&Posted                               AS Posted,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	TRUE                                  AS RecordInManAccounting,
	|	FATable.FixedAsset              AS FixedAsset
	|FROM
	|	Document.LeaseTermAdjustment AS DocumentData
	|		LEFT JOIN TTFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                        AS Period,
	|	&Organization                   AS Organization,
	|	BEGINOFPERIOD(&Period, DAY)   AS DateRecord,
	|	&BusinessOperation         AS BusinessOperation";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region FormationOfTemporaryTablesForConducting

Procedure QueryTextTableTTFATable(QueryTexts)
	
	TableName = "TTFATable";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	FATable.Ref AS Ref,
	|	FATable.LineNumber AS LineNumber,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.ActionWithRentalObject AS ActionWithRentalObject,
	|	FATable.Sublease AS Sublease,
	|	FATable.Department AS Department,
	|	FATable.ExpenseItem AS ExpenseItem,
	|	FATable.Cost AS Cost,
	|	CASE
	|		WHEN &ThereIsMaAccount
	|			THEN FATable.Cost * CASE
	|					WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|						THEN 1
	|					ELSE &ConversionRateToManCurrency
	|				END
	|		ELSE 0
	|	END AS CostInManagementAccounting,
	|	CASE
	|		WHEN &ThereIsACAccounting
	|			THEN FATable.Cost * CASE
	|					WHEN &ARAPCurrency = &LocalAccountingCurrency
	|						THEN 1
	|					ELSE &FactorOfConversionToCurrencyOfRegul
	|				END
	|		ELSE 0
	|	END AS CostInAccounting,
	|	CASE
	|		WHEN &ThereIsAccountingTa
	|			THEN FATable.Cost * CASE
	|					WHEN &ARAPCurrency = &LocalAccountingCurrency
	|						THEN 1
	|					ELSE &FactorOfConversionToCurrencyOfRegul
	|				END
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|	FATable.FairValue AS FairValue,
	|	FATable.NonGuaranteedFinalCost AS NonGuaranteedFinalCost,
	|	FATable.BuyoutValue AS BuyoutValue,
	|	FATable.UsefulLifeAccounting AS UsefulLifeAccounting,
	|	FATable.UsefulLifeTaxAccounting AS UsefulLifeTaxAccounting,
	|	FATable.UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
	|	FATable.RowID AS RowID
	|INTO TTFATable
	|FROM
	|	Document.LeaseTermAdjustment.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|
	|INDEX BY
	|	RowID,
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	TableName = "TTOtherExpenses_";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	TableName = "TTInitialOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTNonAccruedInterest(QueryTexts);
	QueryTextTableTTFATable(QueryTexts);
	QueryTextTableTTFACostAdjustment(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses());
	
	#Region NonAccruedInterest // Dt <91.02> - Ct <76.07.5>
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	&Organization AS Organization,
	|	&BusinessUnitInterest AS Department,
	|	&ExpenseItem AS ExpenseItem,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	
	|	TableExpenses.SumMan AS AmountIncludingVAT,
	|	TableExpenses.SumMan AS AmountExcludingVAT,
	|	TableExpenses.SumMan AS AmountExcludingVATMan,
	|	TableExpenses.SumCompl AS AmountIncludingVATCompl,
	|	TableExpenses.SumCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	TableExpenses.SumCompl AS CostTD,
	|	
	|	&BO_UnderchargedLeaseInterest AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	&DocumentID AS FinRecordID,
	|	&SettingUpHO_NonAccruedRentalInterest AS BusinessTransactionSetting
	|FROM
	|	TTNonAccruedInterest AS TableExpenses
	|WHERE
	|	VALUETYPE(&ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND &CreatedForTransition";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region FormationOfCostOfRentalItems // Dr <08.04> - Cr <76.07.1>
	QueryText = LeaseTermAdjustmentLocalization.QueryTextTTTableInitialOtherExpensesCostGeneration();
	
	If QueryText = Undefined Then
		QueryText =
		"SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&Organization AS Organization,
		|	FATable.Department AS Department,
		|	FATable.ExpenseItem AS ExpenseItem,
		|	FATable.FixedAsset AS DimensionOfExpenses,
		|	&LineOfBusiness AS LineOfBusiness,
		|	UNDEFINED AS VATActivityType,
		|	FATable.CostInManagementAccounting AS AmountIncludingVAT,
		|	FATable.CostInManagementAccounting AS AmountExcludingVAT,
		|	FATable.CostInManagementAccounting AS AmountExcludingVATMan,
		|	FATable.CostInAccounting AS AmountIncludingVATCompl,
		|	FATable.CostInAccounting AS AmountExcludingVATCompl,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	&BO_GenerationOfLeasedFixedAssetsCost AS BusinessOperation,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	FATable.RowID AS FinRecordID,
		|	&SettingUpHO_FORMINGCostOfLeasedFA AS BusinessTransactionSetting
		|FROM
		|	TTFATable AS FATable
		|WHERE
		|	(&ThereIsMaAccount
		|			OR &ThereIsACAccounting)
		|	AND FATable.Ref = &Ref
		|	AND FATable.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.Rent)
		|
		|UNION ALL
		|
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&Organization AS Organization,
		|	FATable.Department AS Department,
		|	FATable.ExpenseItem AS ExpenseItem,
		|	FATable.FixedAsset AS DimensionOfExpenses,
		|	&LineOfBusiness AS LineOfBusiness,
		|	UNDEFINED AS VATActivityType,
		|	FATable.CostInManagementAccounting AS AmountIncludingVAT,
		|	FATable.CostInManagementAccounting AS AmountExcludingVAT,
		|	FATable.CostInManagementAccounting AS AmountExcludingVATMan,
		|	FATable.CostInAccounting AS AmountIncludingVATCompl,
		|	FATable.CostInAccounting AS AmountExcludingVATCompl,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	&BO_GenerationOfLeasedFixedAssetsCost AS BusinessOperation,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	FATable.RowID AS FinRecordID,
		|	&SettingUpHO_FORMINGCostOfLeasedFA AS BusinessTransactionSetting
		|FROM
		|	TTFATable AS FATable
		|WHERE
		|	(&ThereIsMaAccount
		|			OR &ThereIsACAccounting)
		|	AND FATable.Ref = &Ref
		|	AND FATable.Sublease";
		
	EndIf;
	
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, TableName, True);
	
EndProcedure

Procedure QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts)
	
	TableName = "TTLotsOfOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	TableName = "TTInitialBatchesOfOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextTableTTNonAccruedInterest(QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.ItemisedExpensesLots.TextDescriptionTTInitialBatchesOfOtherExpenses());

	#Region NonAccruedInterest
	QueryText =
	"SELECT
	|	&Period                                         AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	&Organization                                    AS Organization,
	|	&BusinessUnitInterest                          AS Department,
	|	&ExpenseItemInterest                         AS ExpenseItem,
	|	&ExpensesDimensionInterest                      AS DimensionOfExpenses,
	|	UNDEFINED                                    AS AssetsLiabilitiesDimension,
	|	&Ref                                         AS ExpenseReceiptDocument,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	&LineOfBusiness                        AS LineOfBusiness,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|	UNDEFINED                                    AS VATActivityType,
	|
	|	TableExpenses.SumMan                         AS Cost,
	|	TableExpenses.SumMan                         AS CostExcludingVAT,
	|	0                                               AS VATManag,
	|	TableExpenses.SumCompl                        AS LocalCost,
	|	0                                               AS VATLocal,
	|	0                                               AS PermanentDifference,
	|	TableExpenses.SumCompl                        AS CostTD,
	|
	|	&BO_UnderchargedLeaseInterest             AS BusinessOperation,
	|	&DocumentID                         AS FinRecordID,
	|	&SettingUpHO_NonAccruedRentalInterest    AS BusinessTransactionSetting
	|
	|FROM
	|	TTNonAccruedInterest AS TableExpenses
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS OtherItemsOfExpenditure
	|		ON &ExpenseItemInterest = OtherItemsOfExpenditure.Ref
	|WHERE
	|	OtherItemsOfExpenditure.CostAllocationOptionLocal IN (
	|		VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|	AND &CreatedForTransition";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTCostIncrease(Query, QueryTexts)

	TableName = "TTCostIncrease";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFACostAdjustment(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	CostAdjustment.FixedAsset     AS FixedAsset,
	|	CostAdjustment.Sublease            AS Sublease,
	|	CostAdjustment.RowID  AS RowID,
	|
	// Cost
	|	CASE 
	|		WHEN CostAdjustment.Cost > 0
	|			THEN CostAdjustment.Cost
	|		ELSE 0
	|	END AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN CostAdjustment.LocalCost > 0
	|			THEN CostAdjustment.LocalCost
	|		ELSE 0
	|	END AS LocalCost,
	|
	// CostInTaxAccounting
	|	CASE 
	|		WHEN CostAdjustment.CostInTaxAccounting > 0
	|			THEN CostAdjustment.CostInTaxAccounting
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	// SecurityDepositValue
	|	CASE 
	|		WHEN CostAdjustment.SecurityDepositValue > 0
	|			THEN CostAdjustment.SecurityDepositValue
	|		ELSE 0
	|	END AS SecurityDepositValue
	|
	|INTO TTCostIncrease
	|FROM
	|	TTFACostAdjustment AS CostAdjustment
	|WHERE
	|	CostAdjustment.Cost > 0
	|		OR CostAdjustment.LocalCost > 0
	|		OR CostAdjustment.CostInTaxAccounting > 0
	|		OR CostAdjustment.SecurityDepositValue > 0
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTCostReduction(Query, QueryTexts)

	TableName = "TTCostReduction";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFACostAdjustment(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	CostAdjustment.FixedAsset     AS FixedAsset,
	|	CostAdjustment.Sublease            AS Sublease,
	|	CostAdjustment.RowID  AS RowID,
	|
	// Cost
	|	CASE 
	|		WHEN CostAdjustment.Cost < 0
	|			THEN -CostAdjustment.Cost
	|		ELSE 0
	|	END                                       AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN CostAdjustment.LocalCost < 0
	|			THEN -CostAdjustment.LocalCost
	|		ELSE 0
	|	END                                       AS LocalCost,
	|
	// CostInTaxAccounting
	|	CASE 
	|		WHEN CostAdjustment.CostInTaxAccounting < 0
	|			THEN -CostAdjustment.CostInTaxAccounting
	|		ELSE 0
	|	END                                       AS CostInTaxAccounting,
	|
	// SecurityDepositValue
	|	CASE 
	|		WHEN CostAdjustment.SecurityDepositValue < 0
	|			THEN -CostAdjustment.SecurityDepositValue
	|		ELSE 0
	|	END                                       AS SecurityDepositValue
	|
	|INTO TTCostReduction
	|FROM
	|	TTFACostAdjustment AS CostAdjustment
	|WHERE
	|	CostAdjustment.Cost < 0
	|		OR CostAdjustment.LocalCost < 0
	|		OR CostAdjustment.CostInTaxAccounting < 0
	|		OR CostAdjustment.SecurityDepositValue < 0
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTAdjustmentOfCollateralCostFA(Query, QueryTexts)
	
	TableName = "TTAdjustmentOfCollateralCostFA";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.RowID AS RowID,
	|	0 AS CostInManagementAccounting,
	|	0 AS CostInAccounting,
	|	0 AS CostInTaxAccounting,
	|	FATable.Cost - ISNULL(FACost.SecurityDepositValue, 0) AS SecurityDepositValue
	|INTO TTAdjustmentOfCollateralCostFA
	|FROM
	|	Document.LeaseTermAdjustment.FA AS FATable
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON (FACost.AccountingObject = FATable.FixedAsset)
	|			AND (FACost.Ref = &Ref)
	|WHERE
	|	FATable.Ref = &Ref
	|	AND FATable.Cost <> ISNULL(FACost.SecurityDepositValue, 0)
	|	AND &AssetHolder = VALUE(Enum.LeasedAssetHolder.Lessor)
	|	AND NOT &LeaseAccountingAccordingToFSB25_2018IsUsed";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTFACostAdjustment(Query, QueryTexts)
	
	TableName = "TTFACostAdjustment";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	InitializeTTTableFACostAdjustmentByShares(Query, QueryTexts);
	QueryTextTableTTAdjustmentOfCollateralCostFA(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	AdjustmentOfFACostByShares.FixedAsset AS FixedAsset,
	|	AdjustmentOfFACostByShares.Sublease AS Sublease,
	|	AdjustmentOfFACostByShares.RowID AS RowID,
	|	AdjustmentOfFACostByShares.CostInManagementAccounting AS Cost,
	|	AdjustmentOfFACostByShares.CostInAccounting AS LocalCost,
	|	AdjustmentOfFACostByShares.CostInTaxAccounting AS CostInTaxAccounting,
	|	0 AS SecurityDepositValue
	|INTO TTFACostAdjustment
	|FROM
	|	TTFACostAdjustmentByShares AS AdjustmentOfFACostByShares
	|WHERE
	|	&MethodForDeterminingCostOfAssets IN (
	|		VALUE(Enum.MethodsOfDeterminingLeasedAssetCost.Discounting),
	|		VALUE(Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount))
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentOfFACostByShares.FixedAsset,
	|	FALSE AS Sublease,
	|	AdjustmentOfFACostByShares.RowID,
	|	-AdjustmentOfFACostByShares.AmountOfInterestMan,
	|	-AdjustmentOfFACostByShares.LocalInterestAmount,
	|	0,
	|	0
	|FROM
	|	TTFACostAdjustmentByShares AS AdjustmentOfFACostByShares
	|WHERE
	|	&CreatedForTransition
	|
	|UNION ALL
	|
	|SELECT
	|	TTAdjustmentOfCollateralCostFA.FixedAsset,
	|	FALSE AS Sublease,
	|	TTAdjustmentOfCollateralCostFA.RowID,
	|	TTAdjustmentOfCollateralCostFA.CostInManagementAccounting,
	|	TTAdjustmentOfCollateralCostFA.CostInAccounting,
	|	TTAdjustmentOfCollateralCostFA.CostInTaxAccounting,
	|	TTAdjustmentOfCollateralCostFA.SecurityDepositValue
	|FROM
	|	TTAdjustmentOfCollateralCostFA AS TTAdjustmentOfCollateralCostFA";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTUnnecessarilyAccruedInterest(QueryTexts)
	
	TableName = "TTUnnecessarilyAccruedInterest";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAdjustmentOfAccruedInterest(QueryTexts);

	QueryText =
	"SELECT
	|	-T.Sum AS Sum,
	|	-T.SumMan AS SumMan,
	|	-T.SumCompl AS SumCompl
	|
	|INTO TTUnnecessarilyAccruedInterest
	|FROM
	|	TTAdjustmentOfAccruedInterest AS T
	|WHERE
	|	T.Sum < 0
	|	AND &CreatedForTransition";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTNonAccruedInterest(QueryTexts)
	
	TableName = "TTNonAccruedInterest";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAdjustmentOfAccruedInterest(QueryTexts);
	
	QueryText =
	"SELECT
	|	T.Sum AS Sum,
	|	T.SumMan AS SumMan,
	|	T.SumCompl AS SumCompl
	|
	|INTO TTNonAccruedInterest
	|FROM
	|	TTAdjustmentOfAccruedInterest AS T
	|WHERE
	|	T.Sum > 0
	|	AND &CreatedForTransition";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTAdjustmentOfAccruedInterest(QueryTexts)
	
	TableName = "TTAdjustmentOfAccruedInterest";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTPreviousTermsAndConditions(QueryTexts);
	
	QueryText =
	"SELECT
	|	SUM(Schedules.Sum) AS Sum,
	|
	|	CASE
	|		WHEN NOT &ThereIsMaAccount
	|			THEN 0
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN SUM(Schedules.Sum)
	|		ELSE SUM(CAST(Schedules.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)))
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN NOT &ThereIsACAccounting
	|			THEN 0
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN SUM(Schedules.Sum)
	|		ELSE SUM(CAST(Schedules.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)))
	|	END AS SumCompl
	|
	|INTO TTAdjustmentOfAccruedInterest
	|FROM
	|	(SELECT
	|		CurSchedule.Interests AS Sum
	|	FROM
	|		Document.LeaseTermAdjustment.InterestAccrualSchedule AS CurSchedule
	|	WHERE
	|		CurSchedule.Ref = &Ref
	|		AND (CurSchedule.Date < &BegOfMonth
	|				OR &CreatedForTransition AND CurSchedule.Date <= ENDOFPERIOD(&Period, DAY))
	|
	|	UNION ALL
	|
	|	SELECT
	|		-PreviousChart.Interests
	|	FROM
	|		InformationRegister.LeaseInterestAccrualSchedule AS PreviousChart
	|	WHERE
	|		PreviousChart.Date < &BegOfMonth
	|		AND PreviousChart.Active
	|		AND PreviousChart.Contract = &Contract
	|		AND PreviousChart.EffectiveContractTerms IN (
	|			SELECT
	|				T.EffectiveContractTerms 
	|			FROM 
	|				TTPreviousTermsAndConditions AS T)
	|
	|	) AS Schedules";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTAdjustmentOfCalculations(QueryTexts)
	
	TableName = "TTAdjustmentOfCalculations";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTPreviousTermsAndConditions(QueryTexts);
	QueryTextTableTTInterestAmount(QueryTexts);
	QueryTextTableInterestBearingBalancesTT(QueryTexts);
	QueryTextTableVATBalancesTT(QueryTexts);
	
	QueryText =
	"SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	&VATAmount - VATBalancesTT.VATAmount AS VATAmount,
	|	CASE
	|		WHEN ISNULL(TTInterestAmount.Sum, 0) - InterestBearingBalancesTT.InterestAmount > 0
	|					AND ISNULL(TTInterestAmount.Sum, 0) - InterestBearingBalancesTT.InterestAmount >= &RoundingThreshold
	|				OR ISNULL(TTInterestAmount.Sum, 0) - InterestBearingBalancesTT.InterestAmount < 0
	|					AND ISNULL(TTInterestAmount.Sum, 0) - InterestBearingBalancesTT.InterestAmount <= -&RoundingThreshold
	|			THEN ISNULL(TTInterestAmount.Sum, 0) - InterestBearingBalancesTT.InterestAmount
	|		ELSE 0
	|	END AS InterestAmount
	|INTO TTAdjustmentOfCalculationsIsPreliminary
	|FROM
	|	TTPreviousTermsAndConditions AS TermsOfLeaseContracts
	|		LEFT JOIN InterestBearingBalancesTT AS InterestBearingBalancesTT
	|		ON (TRUE)
	|		LEFT JOIN VATBalancesTT AS VATBalancesTT
	|		ON (TRUE)
	|		LEFT JOIN TTInterestAmount AS TTInterestAmount
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdjustmentOfCalculations.EffectiveContractTerms AS EffectiveContractTerms,
	|	AdjustmentOfCalculations.VATAmount AS VATAmount,
	|	AdjustmentOfCalculations.InterestAmount AS InterestAmount,
	|	CASE
	|		WHEN NOT &ThereIsMaAccount
	|			THEN 0
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN AdjustmentOfCalculations.VATAmount
	|		ELSE CAST(AdjustmentOfCalculations.VATAmount * &ConversionRateToManCurrency AS NUMBER(31, 2))
	|	END AS VATAmountMan,
	|	CASE
	|		WHEN NOT &ThereIsACAccounting
	|			THEN 0
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN AdjustmentOfCalculations.VATAmount
	|		ELSE CAST(AdjustmentOfCalculations.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31, 2))
	|	END AS VATAmountCompl,
	|	CASE
	|		WHEN NOT &ThereIsMaAccount
	|			THEN 0
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN AdjustmentOfCalculations.InterestAmount
	|		ELSE CAST(AdjustmentOfCalculations.InterestAmount * &ConversionRateToManCurrency AS NUMBER(31, 2))
	|	END AS AmountOfInterestMan,
	|	CASE
	|		WHEN NOT &ThereIsACAccounting
	|			THEN 0
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN AdjustmentOfCalculations.InterestAmount
	|		ELSE CAST(AdjustmentOfCalculations.InterestAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31, 2))
	|	END AS LocalInterestAmount
	|INTO TTAdjustmentOfCalculations
	|FROM
	|	TTAdjustmentOfCalculationsIsPreliminary AS AdjustmentOfCalculations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTAdjustmentOfCalculationsIsPreliminary";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTPreviousTermsAndConditions(QueryTexts)
	
	TableName = "TTPreviousTermsAndConditions";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms,
	|	TermsOfLeaseContracts.VATAmount AS VATAmount,
	|	TermsOfLeaseContracts.InterestAmount AS InterestAmount
	|INTO TTPreviousTermsAndConditions
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(&Period, Contract = &OldContract AND Recorder <> &Ref) AS TermsOfLeaseContracts";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTInterestAmount(QueryTexts)

	TableName = "TTInterestAmount";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&InterestAmount AS Sum
	|INTO TTInterestAmount
	|WHERE
	|	NOT &CreatedForTransition
	|
	|UNION ALL
	|
	|SELECT
	|	SUM(CurSchedule.Interests)
	|FROM
	|	Document.LeaseTermAdjustment.InterestAccrualSchedule AS CurSchedule
	|WHERE
	|	CurSchedule.Ref = &Ref
	|	AND &CreatedForTransition";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure InitializeTTTableFACostAdjustmentByShares(Query, QueryTexts)

	TableName = "TTFACostAdjustmentByShares";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	// Prohibition of re-initialization.
	If Query.Parameters.Property("TTFACostAdjustmentBySharesInitialized") Then
		Return;
	EndIf;

	InitializationRequestTexts = New ValueList;

	QueryTextTableTTBalancesOnLeaseObligations(InitializationRequestTexts);
	QueryTextTableTTAdjustmentOfCalculations(InitializationRequestTexts);
	QueryTextTableTTFATable(InitializationRequestTexts);

	InitializationRequest = New Query;

	For Each QueryParameter In Query.Parameters Do
		InitializationRequest.Parameters.Insert(QueryParameter.Key,QueryParameter.Value);
	EndDo;

	// We will get the shares of each FA in the total fair value.
	QueryText = 
	"SELECT
	|	TTAdjustmentOfCalculations.InterestAmount AS InterestAmount,
	|	TTAdjustmentOfCalculations.AmountOfInterestMan AS AmountOfInterestMan,
	|	TTAdjustmentOfCalculations.LocalInterestAmount AS LocalInterestAmount
	|FROM
	|	TTAdjustmentOfCalculations AS TTAdjustmentOfCalculations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeaseTermAdjustment.PresentValue
	|		+ ISNULL(TTBalancesOnLeaseObligations.DepositPayment, 0) AS PresentValue
	|FROM
	|	Document.LeaseTermAdjustment AS LeaseTermAdjustment
	|		LEFT JOIN TTBalancesOnLeaseObligations AS TTBalancesOnLeaseObligations
	|		ON (TRUE)
	|WHERE
	|	LeaseTermAdjustment.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTBalancesOnLeaseObligations.LeaseItemsCost AS TotalCostBalance
	|FROM
	|	TTBalancesOnLeaseObligations AS TTBalancesOnLeaseObligations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FA.FixedAsset AS FixedAsset,
	|	FA.RowID AS RowID,
	|	FA.ActionWithRentalObject AS ActionWithRentalObject,
	|	FA.Sublease AS Sublease,
	|	0 AS Cost,
	|	0 AS InterestAmount,
	|	0 AS LocalInterestAmount,
	|	0 AS AmountOfInterestMan,
	|	CASE
	|		WHEN FA.ActionWithRentalObject <> VALUE(Enum.ActionsWithRentalObjects.Rent)
	|			THEN CASE
	|					WHEN &MethodForDeterminingCostOfAssets = VALUE(Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount)
	|						THEN FA.FairValue
	|					WHEN &ContractType = VALUE(Enum.TypesOfLeaseContracts.Leasing)
	|						THEN FA.Cost
	|					WHEN &ContractType = VALUE(Enum.TypesOfLeaseContracts.Lease)
	|						THEN FA.FairValue
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS BalanceDistributionCoefficient,
	|	CASE
	|		WHEN FA.ActionWithRentalObject <> VALUE(Enum.ActionsWithRentalObjects.RentalTermination)
	|				AND FA.ActionWithRentalObject <> VALUE(Enum.ActionsWithRentalObjects.EarlyRedemption)
	|			THEN CASE
	|					WHEN &MethodForDeterminingCostOfAssets = VALUE(Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount)
	|						THEN FA.FairValue
	|					WHEN &ContractType = VALUE(Enum.TypesOfLeaseContracts.Leasing)
	|						THEN FA.Cost
	|					WHEN &ContractType = VALUE(Enum.TypesOfLeaseContracts.Lease)
	|						THEN FA.FairValue
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS CostSharingRatio
	|FROM
	|	TTFATable AS FA
	|WHERE
	|	FA.Ref = &Ref";

	InitializationRequestTexts.Add(QueryText, "TextOfInitializationLog");

	InitializationRequest.Text = StrConcat(InitializationRequestTexts.UnloadValues(), 
	Common.QueryBatchSeparator());

	Results = InitializationRequest.ExecuteBatch(); 

	FATable = Results[Results.UBound()].Unload();
	
	Selection = Results[Results.UBound()-1].Select();
	Selection.Next();
	TotalCostBalance = Selection.TotalCostBalance;
	
	Selection = Results[Results.UBound()-2].Select();
	Selection.Next();
	PresentValue = Selection.PresentValue;
	
	Selection = Results[Results.UBound()-3].Select();
	Selection.Next();
	InterestAmount = Selection.InterestAmount;
	AmountOfInterestMan = Selection.AmountOfInterestMan;
	LocalInterestAmount = Selection.LocalInterestAmount;

	Coefficients = FATable.UnloadColumn("BalanceDistributionCoefficient");

	DistributionOfCostBalances = Common.DistributeAmountInProportionToCoefficients(
		TotalCostBalance, Coefficients);
	InterestDistribution = Common.DistributeAmountInProportionToCoefficients(
		InterestAmount, Coefficients);
	ManSInterestDistribution = Common.DistributeAmountInProportionToCoefficients(
		AmountOfInterestMan, Coefficients);
	LocalInterestDistribution = Common.DistributeAmountInProportionToCoefficients(
		LocalInterestAmount, Coefficients);

	Coefficients = FATable.UnloadColumn("CostSharingRatio");

	Allocation_Cost = Common.DistributeAmountInProportionToCoefficients(
		PresentValue, Coefficients);

	For RowIndex = 0 To FATable.Count()-1 Do
		
		RowData = FATable.Get(RowIndex);
		
		If Allocation_Cost <> Undefined Or DistributionOfCostBalances <> Undefined Then
			BalanceOfCostOfFA = ?(DistributionOfCostBalances <> Undefined, DistributionOfCostBalances[RowIndex], 0);
			FACost = ?(Allocation_Cost <> Undefined, Allocation_Cost[RowIndex], 0);
			RowData.Cost = FACost - BalanceOfCostOfFA;
		EndIf;
		
		If InterestDistribution <> Undefined Then
			RowData.InterestAmount = InterestDistribution[RowIndex];
		EndIf;
		If ManSInterestDistribution <> Undefined Then
			RowData.AmountOfInterestMan = ManSInterestDistribution[RowIndex];
		EndIf;
		If LocalInterestDistribution <> Undefined Then
			RowData.LocalInterestAmount = LocalInterestDistribution[RowIndex];
		EndIf;
		
	EndDo;

	Query.SetParameter("FATable", FATable);

	QueryText = 
	"SELECT
	|	TTChangeInFACost.FixedAsset AS FixedAsset,
	|	TTChangeInFACost.Sublease AS Sublease,
	|	TTChangeInFACost.RowID AS RowID,
	|	CASE
	|		WHEN TTChangeInFACost.Cost > 0
	|					AND TTChangeInFACost.Cost >= &RoundingThreshold
	|				OR TTChangeInFACost.Cost < 0
	|					AND TTChangeInFACost.Cost <= -&RoundingThreshold
	|			THEN TTChangeInFACost.Cost
	|		ELSE 0
	|	END AS Cost,
	|	TTChangeInFACost.InterestAmount AS InterestAmount,
	|	TTChangeInFACost.AmountOfInterestMan AS AmountOfInterestMan,
	|	TTChangeInFACost.LocalInterestAmount AS LocalInterestAmount
	|INTO TTFACostAdjustmentBySharesPreliminary
	|FROM
	|	&FATable AS TTChangeInFACost
	|WHERE
	|	TTChangeInFACost.ActionWithRentalObject <> VALUE(Enum.ActionsWithRentalObjects.Rent)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTChangeInFACost.FixedAsset AS FixedAsset,
	|	TTChangeInFACost.Sublease AS Sublease,
	|	TTChangeInFACost.RowID AS RowID,
	|	TTChangeInFACost.Cost AS Cost,
	|	CASE
	|		WHEN &ThereIsMaAccount
	|			THEN TTChangeInFACost.Cost * CASE
	|					WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|						THEN 1
	|					ELSE &ConversionRateToManCurrency
	|				END
	|		ELSE 0
	|	END AS CostInManagementAccounting,
	|	CASE
	|		WHEN &ThereIsACAccounting
	|			THEN TTChangeInFACost.Cost * CASE
	|					WHEN &ARAPCurrency = &LocalAccountingCurrency
	|						THEN 1
	|					ELSE &FactorOfConversionToCurrencyOfRegul
	|				END
	|		ELSE 0
	|	END AS CostInAccounting,
	|	CASE
	|		WHEN &ThereIsAccountingTa
	|			THEN TTChangeInFACost.Cost * CASE
	|					WHEN &ARAPCurrency = &LocalAccountingCurrency
	|						THEN 1
	|					ELSE &FactorOfConversionToCurrencyOfRegul
	|				END
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|	TTChangeInFACost.InterestAmount AS InterestAmount,
	|	TTChangeInFACost.AmountOfInterestMan AS AmountOfInterestMan,
	|	TTChangeInFACost.LocalInterestAmount AS LocalInterestAmount
	|INTO TTFACostAdjustmentByShares
	|FROM
	|	TTFACostAdjustmentBySharesPreliminary AS TTChangeInFACost
	|WHERE
	|	TTChangeInFACost.Cost <> 0
	|
	|INDEX BY
	|	RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTFACostAdjustmentBySharesPreliminary";
	
	Query.SetParameter("TTFACostAdjustmentBySharesInitialized", True);

	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure InitializeTTTableBalancesSettlementsOnFinancialInstruments(Query, QueryTexts)

	TableName = "TTBalancesSettlementsOnFinancialInstruments";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	// Prohibition of re-initialization.
	If Query.Parameters.Property("TTBalancesSettlementsOnFinancialInstrumentsInitialized") Then
		Return;
	EndIf;
	
	TempTableManager = New TempTablesManager;
	
	RequestForBalances = New Query;
	RequestForBalances.TempTablesManager = TempTableManager;
	
	For Each QueryParameter In Query.Parameters Do
		RequestForBalances.Parameters.Insert(QueryParameter.Key,QueryParameter.Value);
	EndDo;
	
	RequestForBalances.Text =
	"SELECT
	|	FinancialInstrumentsARAPBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	FinancialInstrumentsARAPBalance.Contract AS Contract,
	|	FinancialInstrumentsARAPBalance.AmountType AS AmountType,
	|	FinancialInstrumentsARAPBalance.ARAPDocument AS ARAPDocument,
	|	FinancialInstrumentsARAPBalance.Currency AS Currency,
	|	FinancialInstrumentsARAPBalance.SumBalance AS SumBalance,
	|	FinancialInstrumentsARAPBalance.SumManBalance AS SumManBalance,
	|	FinancialInstrumentsARAPBalance.SumComplBalance AS SumComplBalance
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(&BoundaryOfResidues, Contract = &OldContract) AS FinancialInstrumentsARAPBalance
	|WHERE
	|	&AmendmentOfContract";
	
	TableOfBalancesByFinancialInstruments = RequestForBalances.Execute().Unload();
	
	TMCommonUse.AddIdentifiersToValueTable(TableOfBalancesByFinancialInstruments);
	
	Query.SetParameter("TableOfBalancesByFinancialInstruments", TableOfBalancesByFinancialInstruments);
	
	QueryText =
	"SELECT
	|	FinancialInstrumentsARAPBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	FinancialInstrumentsARAPBalance.Contract AS Contract,
	|	FinancialInstrumentsARAPBalance.AmountType AS AmountType,
	|	FinancialInstrumentsARAPBalance.ARAPDocument AS ARAPDocument,
	|	FinancialInstrumentsARAPBalance.Currency AS Currency,
	|	FinancialInstrumentsARAPBalance.SumBalance AS SumBalance,
	|	FinancialInstrumentsARAPBalance.SumManBalance AS SumManBalance,
	|	FinancialInstrumentsARAPBalance.SumComplBalance AS SumComplBalance,
	|	FinancialInstrumentsARAPBalance.FinRecordID AS FinRecordID
	|INTO TTBalancesSettlementsOnFinancialInstruments
	|FROM
	|	&TableOfBalancesByFinancialInstruments AS FinancialInstrumentsARAPBalance
	|WHERE
	|	&AmendmentOfContract";
	
	Query.SetParameter("TTBalancesSettlementsOnFinancialInstrumentsInitialized", True);
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTBookValueFA(QueryTexts)
	TableName = "TTBookValueFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	TTCost.Ref                                                  AS Ref,
	|	TTCost.AccountingObject                                             AS FixedAsset,
	|
	|	TTCost.Cost 
	|		- ISNULL(TTDepreciation.Depreciation, 0)
	|		- ISNULL(TTImpairment.ImpairmenMan, 0)                     AS BookValueOfMan,
	|
	|	TTCost.LocalCost + TTCost.CostTargetFinancing 
	|		- ISNULL(TTDepreciation.DepreciationLocal, 0) - ISNULL(TTDepreciation.FixedAssetDepreciationTargetFinancing, 0) 
	|		- ISNULL(TTImpairment.ImpairmentLocalAssets, 0)                    AS LocalBookValue
	|
	|INTO TTBookValueFA
	|
	|FROM
	|	TT_CostOfVNA AS TTCost
	|		LEFT JOIN TT_DepreciationOfVNA AS TTDepreciation
	|		ON TTCost.AccountingObject = TTDepreciation.AccountingObject
	|			AND TTDepreciation.Ref = &Ref
	|		LEFT JOIN TT_ImpairmentFA AS TTImpairment
	|		ON TTCost.AccountingObject = TTImpairment.AccountingObject
	|WHERE
	|	TTCost.Ref = &Ref";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableInterestBearingBalancesTT(QueryTexts) Export
	
	TableName = "InterestBearingBalancesTT";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTPreviousTermsAndConditions(QueryTexts);
	
	QueryText = "SELECT
	|	SUM(ChartTable.Interests) AS AmountOfInterestUnderPreviousConditions
	|INTO TTCurrentInterestChart
	|FROM
	|	Document.LeaseTermAdjustment.InterestAccrualSchedule AS ChartTable
	|WHERE
	|	ChartTable.Ref = &Ref
	|	AND ChartTable.Date >= DATEADD(BEGINOFPERIOD(&Period, DAY), DAY, -1)
	|	AND ChartTable.Date < BEGINOFPERIOD(&Period, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(ISNULL(LeaseInterestAccrualSchedule.Interests, 0)) AS InterestAmount
	|INTO TTInterestBalancesPreliminary
	|FROM
	|	TTPreviousTermsAndConditions AS TTPreviousTermsAndConditions
	|		LEFT JOIN InformationRegister.LeaseInterestAccrualSchedule AS LeaseInterestAccrualSchedule
	|		ON TTPreviousTermsAndConditions.EffectiveContractTerms = LeaseInterestAccrualSchedule.EffectiveContractTerms
	|			AND (LeaseInterestAccrualSchedule.Date >= DATEADD(BEGINOFPERIOD(&Period, DAY), DAY, -1))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInterestBalancesPreliminary.InterestAmount
	|		- ISNULL(TTCurrentInterestChart.AmountOfInterestUnderPreviousConditions, 0) AS InterestAmount
	|INTO InterestBearingBalancesTT
	|FROM
	|	TTInterestBalancesPreliminary AS TTInterestBalancesPreliminary
	|		LEFT JOIN TTCurrentInterestChart AS TTCurrentInterestChart
	|		ON (TRUE)";

	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableVATBalancesTT(QueryTexts) Export
	
	TableName = "VATBalancesTT";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTPreviousTermsAndConditions(QueryTexts);
	
	QueryText = "SELECT
	|	SUM(LeaseServicesAccrualSchedule.RentalServiceVAT) + SUM(LeaseServicesAccrualSchedule.SecurityPaymentVATAmount) AS Sum,
	|	SUM(LeaseServicesAccrualSchedule.SecurityPaymentVATAmount) AS DepositPayment
	|INTO VATAccrualsTT
	|FROM
	|	InformationRegister.LeaseServicesAccrualSchedule AS LeaseServicesAccrualSchedule
	|		INNER JOIN TTPreviousTermsAndConditions AS TTPreviousTermsAndConditions
	|		ON LeaseServicesAccrualSchedule.EffectiveContractTerms = TTPreviousTermsAndConditions.EffectiveContractTerms
	|			AND (LeaseServicesAccrualSchedule.Date >= BEGINOFPERIOD(&Period, DAY))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(LeaseServicesPaymentSchedule.BuyoutValueVAT) AS Sum
	|INTO TTVATOfRedemptionCost
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS LeaseServicesPaymentSchedule
	|		INNER JOIN TTPreviousTermsAndConditions AS TTPreviousTermsAndConditions
	|		ON LeaseServicesPaymentSchedule.EffectiveContractTerms = TTPreviousTermsAndConditions.EffectiveContractTerms
	|			AND (LeaseServicesPaymentSchedule.Date >= BEGINOFPERIOD(&Period, DAY))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(VATAccrualsTT.Sum, 0) + ISNULL(TTVATOfRedemptionCost.Sum, 0) AS VATAmount,
	|	ISNULL(VATAccrualsTT.DepositPayment, 0) AS DepositPayment
	|INTO VATBalancesTT
	|FROM
	|	TTPreviousTermsAndConditions AS TTPreviousTermsAndConditions
	|		LEFT JOIN VATAccrualsTT AS VATAccrualsTT
	|		ON (TRUE)
	|		LEFT JOIN TTVATOfRedemptionCost AS TTVATOfRedemptionCost
	|		ON (TRUE)";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTBalancesOnLeaseObligations(QueryTexts) Export
	
	TableName = "TTBalancesOnLeaseObligations";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTPreviousTermsAndConditions(QueryTexts);
	QueryTextTableInterestBearingBalancesTT(QueryTexts);
	
	QueryText = "SELECT
	|	SUM(LeaseServicesPaymentSchedule.RentalService
	|		- LeaseServicesPaymentSchedule.RentalServiceVAT
	|		+ LeaseServicesPaymentSchedule.DepositPayment
	|		- LeaseServicesPaymentSchedule.SecurityPaymentVATAmount
	|		+ LeaseServicesPaymentSchedule.BuyoutValue
	|		+ LeaseServicesPaymentSchedule.BuyoutValuePrepayment
	|		- LeaseServicesPaymentSchedule.BuyoutValueVAT) AS Sum
	|INTO TTPayments
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS LeaseServicesPaymentSchedule
	|		INNER JOIN TTPreviousTermsAndConditions AS TTPreviousTermsAndConditions
	|		ON LeaseServicesPaymentSchedule.EffectiveContractTerms = TTPreviousTermsAndConditions.EffectiveContractTerms
	|			AND (LeaseServicesPaymentSchedule.Date >= BEGINOFPERIOD(&Period, DAY))
	|;
	|
	|SELECT
	|	SUM(LeaseServicesAccrualSchedule.DepositPayment
	|	- LeaseServicesAccrualSchedule.SecurityPaymentVATAmount) AS DepositPayment
	|INTO TTAccruals
	|FROM
	|	InformationRegister.LeaseServicesAccrualSchedule AS LeaseServicesAccrualSchedule
	|		INNER JOIN TTPreviousTermsAndConditions AS TTPreviousTermsAndConditions
	|		ON LeaseServicesAccrualSchedule.EffectiveContractTerms = TTPreviousTermsAndConditions.EffectiveContractTerms
	|			AND (LeaseServicesAccrualSchedule.Date >= BEGINOFPERIOD(&Period, DAY))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTPayments.Sum, 0)
	|	+ ISNULL(TTAccruals.DepositPayment, 0)
	|	- ISNULL(InterestBearingBalancesTT.InterestAmount, 0) AS LeaseItemsCost,
	|	ISNULL(TTAccruals.DepositPayment, 0) AS DepositPayment
	|INTO TTBalancesOnLeaseObligations
	|FROM
	|	TTPreviousTermsAndConditions AS TTPreviousTermsAndConditions
	|		LEFT JOIN TTPayments AS TTPayments
	|		ON (TRUE)
	|		LEFT JOIN TTAccruals AS TTAccruals
	|		ON (TRUE)
	|		LEFT JOIN InterestBearingBalancesTT AS InterestBearingBalancesTT
	|		ON (TRUE)";

	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTIncomeInCaseOfPartialRepurchase(Query, QueryTexts)

	TableName = "TTIncomeInCaseOfPartialRepurchase";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	InitializeTTTableFACostAdjustmentByShares(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	FA.FixedAsset AS FixedAsset,
	|	FA.RowID AS FinRecordID,
	|	-ISNULL(FACost.Cost,0) - FA.BuyoutValue AS Sum,
	|	CASE
	|		WHEN &ThereIsMaAccount THEN
	|			-ISNULL(FACost.CostInManagementAccounting,0) - FA.BuyoutValue * 
	|				CASE WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|					THEN 1
	|				ELSE &ConversionRateToManCurrency
	|				END
	|		ELSE 0
	|	END AS SumMan,
	|	CASE
	|		WHEN &ThereIsACAccounting THEN
	|			-ISNULL(FACost.CostInAccounting,0) - FA.BuyoutValue *
	|				CASE WHEN &ARAPCurrency = &LocalAccountingCurrency
	|					THEN 1
	|				ELSE &FactorOfConversionToCurrencyOfRegul
	|				END
	|		ELSE 0
	|	END AS SumCompl,
	|	&BO_RecordingLeaseLiabilitiesInIncome AS BusinessOperation,
	|	&SettingUpHO_ReflectionOfLeaseObligationsInIncome AS BusinessTransactionSetting
	|INTO TTIncomeInCaseOfPartialRepurchase
	|FROM
	|	TTFATable AS FA
	|		LEFT JOIN TTFACostAdjustmentByShares AS FACost
	|		ON FA.RowID = FACost.RowID
	|WHERE
	|	FA.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.EarlyRedemption)
	|	AND -ISNULL(FACost.Cost,0) - FA.BuyoutValue > 0";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

#EndRegion

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return LeaseTermAdjustmentLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return "";

EndFunction

#EndRegion

#Region FillType

// Fills in the document based on the lease agreement.
// 
// Parameters:
// 	Object - DocumentObject.LeaseTermAdjustment - 
Procedure FillInBasedOnLeaseAgreement(Object, Refresh = False) Export
	
	If Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	If Refresh Then
		
		FA = Object.FA.Unload();
		ServicePaymentSchedule = Object.ServicePaymentSchedule.Unload();
		ServiceAccrualSchedule = Object.ServiceAccrualSchedule.Unload();
		
	Else
		
		FA = Object.FA.Unload().CopyColumns();
		ServicePaymentSchedule = Object.ServicePaymentSchedule.Unload().CopyColumns();
		ServiceAccrualSchedule = Object.ServiceAccrualSchedule.Unload().CopyColumns();
		
	EndIf;
	
	Object.FA.Clear();
	Object.ServicePaymentSchedule.Clear();
	Object.ServiceAccrualSchedule.Clear();
	Object.InterestAccrualSchedule.Clear();
	
	QueryPackageTexts = New Array;
	
	QueryText = 
	"SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Cost AS Cost,
	|	LeasedAsset.FairValue AS ParValue,
	|	LeasedAsset.ActionWithRentalObject AS Action,
	|	LeasedAsset.Department AS Department,
	|	LeasedAsset.ExpenseItem AS ExpenseItem
	|INTO TTLeasedFAFromDocument
	|FROM
	|	&FA AS LeasedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Cost AS Cost,
	|	ISNULL(TTLeasedFAFromDocument.ParValue, LeasedAsset.ParValue) AS ParValue,
	|	ISNULL(TTLeasedFAFromDocument.Action, VALUE(Enum.ActionsWithRentalObjects.RentalTermsAdjustment)) AS Action,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem
	|INTO TTLeasedOS_Preliminary
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(&PeriodLimit, Recorder <> &Ref AND Contract = &Contract) AS LeasedAsset
	|		LEFT JOIN TTLeasedFAFromDocument AS TTLeasedFAFromDocument
	|		ON LeasedAsset.FixedAsset = TTLeasedFAFromDocument.FixedAsset
	|WHERE
	|	LeasedAsset.State IN (
	|		VALUE(Enum.FixedAssetsStates.LeaseContractsSigned),
	|		VALUE(Enum.FixedAssetsStates.InLease))
	|
	|UNION ALL
	|
	|SELECT
	|	LeasedAsset.FixedAsset,
	|	LeasedAsset.Cost,
	|	LeasedAsset.ParValue,
	|	LeasedAsset.Action,
	|	LeasedAsset.Department,
	|	LeasedAsset.ExpenseItem
	|FROM
	|	TTLeasedFAFromDocument  AS LeasedAsset
	|WHERE
	|	LeasedAsset.Action = VALUE(Enum.ActionsWithRentalObjects.Rent)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RentedOut.FixedAsset AS FixedAsset
	|INTO TTLeased
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(
	|			&PeriodLimit,
	|			FixedAsset IN
	|				(SELECT
	|					T.FixedAsset
	|				FROM
	|					TTLeasedOS_Preliminary AS T)) AS RentedOut
	|WHERE
	|	RentedOut.Contract.ContractType IN(&TypesOfContractsUnderFSB25)
	|	AND RentedOut.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Cost AS Cost,
	|	LeasedAsset.ParValue AS ParValue,
	|	LeasedAsset.Action AS Action,
	|	LeasedAsset.Department AS Department,
	|	LeasedAsset.ExpenseItem AS ExpenseItem,
	|	NOT RentedOut.FixedAsset IS NULL AS Sublease
	|INTO TTLeasedFA
	|FROM
	|	TTLeasedOS_Preliminary AS LeasedAsset
	|		LEFT JOIN TTLeased AS RentedOut
	|		ON RentedOut.FixedAsset = LeasedAsset.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfLeaseContracts.Contract.Organization AS Organization,
	|	TermsOfLeaseContracts.Contract.Partner AS Partner,
	|	TermsOfLeaseContracts.Contract.Counterparty AS Counterparty,
	|	TermsOfLeaseContracts.Contract.ARAPCurrency AS Currency,
	|	TermsOfLeaseContracts.Contract.ARAPCurrency AS ARAPCurrency,
	|	TermsOfLeaseContracts.VATRate AS VATRate,
	|	TermsOfLeaseContracts.SecurityDepositAmount AS SecurityDepositAmount,
	|	TermsOfLeaseContracts.LeaseServicesAmount AS LeaseServicesAmount,
	|	TermsOfLeaseContracts.AmountOfLeaseAssetsByuout AS AmountOfLeaseAssetsByuout,
	|	TermsOfLeaseContracts.InterestAmount AS InterestAmount,
	|	TermsOfLeaseContracts.LeaseItemsCost AS LeaseItemsCost,
	|	TermsOfLeaseContracts.VATAmount AS VATAmount,
	|	TermsOfLeaseContracts.TermYears AS TermYears,
	|	TermsOfLeaseContracts.TermMonths AS TermMonths,
	|	TermsOfLeaseContracts.TermDays AS TermDays,
	|	TermsOfLeaseContracts.LeaseStartDate AS LeaseStartDate,
	|	TermsOfLeaseContracts.DateOfFirstPayment AS DateOfFirstPayment,
	|	TermsOfLeaseContracts.DateOfFirstSecurityPayment AS DateOfFirstSecurityPayment,
	|	TermsOfLeaseContracts.BuyoutDate AS BuyoutDate,
	|	TermsOfLeaseContracts.InterestRate AS InterestRate,
	|	TermsOfLeaseContracts.PaymentFrequency AS PaymentFrequency,
	|	TermsOfLeaseContracts.AccrualFrequency AS AccrualFrequency,
	|	TermsOfLeaseContracts.PaymentForLeaseService AS PaymentForLeaseService,
	|	TermsOfLeaseContracts.AccrualOfLeaseService AS AccrualOfLeaseService,
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	CASE WHEN VALUETYPE(TermsOfLeaseContracts.EffectiveContractTerms)
	|		= TYPE(Document.LeaseTermAdjustment) THEN
	|		BEGINOFPERIOD(CAST(TermsOfLeaseContracts.EffectiveContractTerms AS Document.LeaseTermAdjustment).Date, DAY)
	|	ELSE
	|		TermsOfLeaseContracts.LeaseStartDate
	|	END AS DateOfChangeOfContract
	|INTO TTTermsOfLeaseAgreements
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|			&Date,
	|			Recorder <> &Ref
	|				AND Contract = &Contract) AS TermsOfLeaseContracts
	|;
	| 
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	ScheduleData.BuyoutValue AS BuyoutValue,
	|	ScheduleData.BuyoutValueVAT AS BuyoutValueVAT
	|INTO TTPaymentScheduleForServicesFromDocument
	|FROM
	|	&ServicePaymentSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.Date >= BEGINOFPERIOD(&Date, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount
	|INTO TTScheduleOfAccrualOfServicesFromDocument
	|FROM
	|	&ServiceAccrualSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.Date >= BEGINOFPERIOD(&Date, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	ScheduleData.BuyoutValue + ScheduleData.BuyoutValuePrepayment AS BuyoutValue,
	|	ScheduleData.BuyoutValueVAT AS BuyoutValueVAT
	|INTO TTServicePaymentSchedule
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.EffectiveContractTerms IN
	|			(SELECT
	|				T.EffectiveContractTerms
	|			FROM
	|				TTTermsOfLeaseAgreements AS T)
	|	AND ScheduleData.Active
	|	AND (ScheduleData.Date < BEGINOFPERIOD(&Date, DAY) OR &Refill)
	|
	|UNION ALL
	|
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	ScheduleData.BuyoutValue AS BuyoutValue,
	|	ScheduleData.BuyoutValueVAT AS BuyoutValueVAT
	|FROM
	|	TTPaymentScheduleForServicesFromDocument AS ScheduleData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount
	|INTO TTScheduleOfAccrualServices
	|FROM
	|	InformationRegister.LeaseServicesAccrualSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.EffectiveContractTerms IN
	|			(SELECT
	|				T.EffectiveContractTerms
	|			FROM
	|				TTTermsOfLeaseAgreements AS T)
	|	AND ScheduleData.Active
	|	AND (ScheduleData.RentalService <> 0
	|			OR ScheduleData.DepositPayment <> 0)
	|	AND (ScheduleData.Date < BEGINOFPERIOD(&Date, DAY) OR &Refill)
	|
	|UNION ALL
	|
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount
	|FROM
	|	TTScheduleOfAccrualOfServicesFromDocument AS ScheduleData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.Interests AS Interests
	|INTO TTInterestSchedule
	|FROM
	|	InformationRegister.LeaseInterestAccrualSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.EffectiveContractTerms IN
	|			(SELECT
	|				T.EffectiveContractTerms
	|			FROM
	|				TTTermsOfLeaseAgreements AS T)
	|	AND ScheduleData.Active
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(TTServicePaymentSchedule.RentalService) AS RentalService,
	|	SUM(TTServicePaymentSchedule.RentalServiceVAT) AS RentalServiceVAT,
	|	SUM(TTServicePaymentSchedule.DepositPayment) AS DepositPayment,
	|	SUM(TTServicePaymentSchedule.SecurityPaymentVATAmount) AS SecurityPaymentVATAmount,
	|	SUM(TTServicePaymentSchedule.BuyoutValue) AS BuyoutValue,
	|	SUM(TTServicePaymentSchedule.BuyoutValueVAT) AS BuyoutValueVAT
	|INTO PaymentScheduleForServicesTTBalances
	|FROM
	|	TTServicePaymentSchedule AS TTServicePaymentSchedule
	|		LEFT JOIN TTTermsOfLeaseAgreements AS TTTermsOfLeaseAgreements
	|		ON (TRUE)
	|WHERE
	|	TTServicePaymentSchedule.Date < BEGINOFPERIOD(&Date, DAY)
	|	AND TTServicePaymentSchedule.Date >= ISNULL(TTTermsOfLeaseAgreements.DateOfChangeOfContract, DATETIME(1,1,1))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(TTScheduleOfAccrualServices.RentalService) AS RentalService,
	|	SUM(TTScheduleOfAccrualServices.RentalServiceVAT) AS RentalServiceVAT,
	|	SUM(TTScheduleOfAccrualServices.DepositPayment) AS DepositPayment,
	|	SUM(TTScheduleOfAccrualServices.SecurityPaymentVATAmount) AS SecurityPaymentVATAmount
	|INTO TTScheduleOfAccrualServicesBalances
	|FROM
	|	TTScheduleOfAccrualServices AS TTScheduleOfAccrualServices
	|		LEFT JOIN TTTermsOfLeaseAgreements AS TTTermsOfLeaseAgreements
	|		ON (TRUE)
	|WHERE
	|	TTScheduleOfAccrualServices.Date < BEGINOFPERIOD(&Date, DAY)
	|	AND TTScheduleOfAccrualServices.Date >= ISNULL(TTTermsOfLeaseAgreements.DateOfChangeOfContract, DATETIME(1,1,1))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(TTInterestSchedule.Interests) AS Interests
	|INTO TTInterestAccrualScheduleBalances
	|FROM
	|	TTInterestSchedule AS TTInterestSchedule
	|		LEFT JOIN TTTermsOfLeaseAgreements AS TTTermsOfLeaseAgreements
	|		ON (TRUE)
	|WHERE
	|	TTInterestSchedule.Date < BEGINOFPERIOD(&Date, DAY)
	|	AND TTInterestSchedule.Date >= ISNULL(TTTermsOfLeaseAgreements.DateOfChangeOfContract, DATETIME(1,1,1))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(TTScheduleOfAccrualServices.RentalService) AS RentalService,
	|	SUM(TTScheduleOfAccrualServices.RentalServiceVAT) AS RentalServiceVAT
	|INTO TTScheduleOfAccrualServicesBalancesForEntirePeriod
	|FROM
	|	TTScheduleOfAccrualServices AS TTScheduleOfAccrualServices
	|WHERE
	|	TTScheduleOfAccrualServices.Date < BEGINOFPERIOD(&Date, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(TTServicePaymentSchedule.RentalService) AS RentalService,
	|	SUM(TTServicePaymentSchedule.RentalServiceVAT) AS RentalServiceVAT
	|INTO TTPaymentScheduleForServicesBalancesForEntirePeriod
	|FROM
	|	TTServicePaymentSchedule AS TTServicePaymentSchedule
	|WHERE
	|	TTServicePaymentSchedule.Date < BEGINOFPERIOD(&Date, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTPaymentScheduleForServicesBalancesForEntirePeriod.RentalService, 0)
	|		- ISNULL(TTScheduleOfAccrualServicesBalancesForEntirePeriod.RentalService, 0) AS PaymentsBalance,
	|	ISNULL(TTPaymentScheduleForServicesBalancesForEntirePeriod.RentalServiceVAT, 0)
	|		- ISNULL(TTScheduleOfAccrualServicesBalancesForEntirePeriod.RentalServiceVAT, 0) AS PaymentOfVATBalance
	|INTO PaymentBalanceDifferenceTT
	|FROM
	|	TTPaymentScheduleForServicesBalancesForEntirePeriod AS TTPaymentScheduleForServicesBalancesForEntirePeriod,
	|	TTScheduleOfAccrualServicesBalancesForEntirePeriod AS TTScheduleOfAccrualServicesBalancesForEntirePeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(TTServicePaymentSchedule.Date) AS Date
	|INTO PaymentScheduleForServicesTTFirstPayment
	|FROM
	|	TTServicePaymentSchedule AS TTServicePaymentSchedule
	|WHERE
	|	TTServicePaymentSchedule.Date >= BEGINOFPERIOD(&Date, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(TTServicePaymentSchedule.BuyoutValueVAT) AS BuyoutValueVAT
	|INTO TTPaymentScheduleForServicesRedemption
	|FROM
	|	TTServicePaymentSchedule AS TTServicePaymentSchedule
	|		LEFT JOIN TTTermsOfLeaseAgreements AS TTTermsOfLeaseAgreements
	|		ON (TRUE)
	|WHERE
	|	TTServicePaymentSchedule.Date >= BEGINOFPERIOD(&Date, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	&Date AS Date,
	|	TermsOfLeaseContracts.Organization AS Organization,
	|	TermsOfLeaseContracts.Partner AS Partner,
	|	TermsOfLeaseContracts.Counterparty AS Counterparty,
	|	TermsOfLeaseContracts.Currency AS Currency,
	|	TermsOfLeaseContracts.ARAPCurrency AS ARAPCurrency,
	|	TermsOfLeaseContracts.VATRate AS VATRate,
	|	TermsOfLeaseContracts.SecurityDepositAmount
	|		- ISNULL(TTScheduleOfAccrualServicesBalances.DepositPayment, 0) AS SecurityDepositAmount,
	|	TermsOfLeaseContracts.LeaseServicesAmount
	|		- ISNULL(PaymentScheduleForServicesTTBalances.RentalService, 0)
	|		+ ISNULL(PaymentBalanceDifferenceTT.PaymentsBalance, 0) AS LeaseServicesAmount,
	|	TermsOfLeaseContracts.AmountOfLeaseAssetsByuout
	|		- ISNULL(PaymentScheduleForServicesTTBalances.BuyoutValue, 0) AS AmountOfLeaseAssetsByuout,
	|	TermsOfLeaseContracts.InterestAmount
	|		- ISNULL(TTInterestAccrualScheduleBalances.Interests, 0) AS InterestAmount,
	|	TermsOfLeaseContracts.LeaseItemsCost AS LeaseItemsCost,
	|	TermsOfLeaseContracts.VATAmount - ISNULL(PaymentScheduleForServicesTTBalances.RentalServiceVAT, 0) 
	|		- ISNULL(PaymentScheduleForServicesTTBalances.BuyoutValueVAT, 0)
	|		- ISNULL(TTScheduleOfAccrualServicesBalances.SecurityPaymentVATAmount,0)
	|		+ ISNULL(PaymentBalanceDifferenceTT.PaymentOfVATBalance, 0) AS VATAmount,
	|	ISNULL(TTPaymentScheduleForServicesRedemption.BuyoutValueVAT, 0) AS AmountOfVATRepurchaseOfRentalItems,
	|	TermsOfLeaseContracts.TermYears AS TermYears,
	|	TermsOfLeaseContracts.TermMonths AS TermMonths,
	|	TermsOfLeaseContracts.TermDays AS TermDays,
	|	TermsOfLeaseContracts.LeaseStartDate AS LeaseStartDate,
	|	ISNULL(PaymentScheduleForServicesTTFirstPayment.Date, TermsOfLeaseContracts.DateOfFirstPayment) AS DateOfFirstPayment,
	|	TermsOfLeaseContracts.DateOfFirstSecurityPayment AS DateOfFirstSecurityPayment,
	|	TermsOfLeaseContracts.BuyoutDate AS BuyoutDate,
	|	TermsOfLeaseContracts.InterestRate AS InterestRate,
	|	TermsOfLeaseContracts.PaymentFrequency AS PaymentFrequency,
	|	TermsOfLeaseContracts.AccrualFrequency AS AccrualFrequency,
	|	TermsOfLeaseContracts.PaymentForLeaseService AS PaymentForLeaseService,
	|	TermsOfLeaseContracts.AccrualOfLeaseService AS AccrualOfLeaseService,
	|	TermsOfLeaseContracts.EffectiveContractTerms AS PreviousContractTerms
	|FROM
	|	TTTermsOfLeaseAgreements AS TermsOfLeaseContracts
	|		LEFT JOIN PaymentScheduleForServicesTTBalances AS PaymentScheduleForServicesTTBalances
	|		ON (TRUE)
	|		LEFT JOIN TTInterestAccrualScheduleBalances AS TTInterestAccrualScheduleBalances
	|		ON (TRUE)
	|		LEFT JOIN TTScheduleOfAccrualServicesBalances AS TTScheduleOfAccrualServicesBalances
	|		ON (TRUE)
	|		LEFT JOIN PaymentScheduleForServicesTTFirstPayment AS PaymentScheduleForServicesTTFirstPayment
	|		ON (TRUE)
	|		LEFT JOIN TTPaymentScheduleForServicesRedemption AS TTPaymentScheduleForServicesRedemption
	|		ON (TRUE)
	|		LEFT JOIN PaymentBalanceDifferenceTT AS PaymentBalanceDifferenceTT
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTServicePaymentSchedule.Date AS Date,
	|	TTServicePaymentSchedule.RentalService AS RentalService,
	|	TTServicePaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|	TTServicePaymentSchedule.DepositPayment AS DepositPayment,
	|	TTServicePaymentSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	TTServicePaymentSchedule.BuyoutValue AS BuyoutValue,
	|	TTServicePaymentSchedule.BuyoutValueVAT AS BuyoutValueVAT
	|FROM
	|	TTServicePaymentSchedule AS TTServicePaymentSchedule
	|
	|ORDER BY
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTScheduleOfAccrualServices.Date AS Date,
	|	TTScheduleOfAccrualServices.RentalService AS RentalService,
	|	TTScheduleOfAccrualServices.RentalServiceVAT AS RentalServiceVAT,
	|	TTScheduleOfAccrualServices.DepositPayment AS DepositPayment,
	|	TTScheduleOfAccrualServices.SecurityPaymentVATAmount AS SecurityPaymentVATAmount
	|FROM
	|	TTScheduleOfAccrualServices AS TTScheduleOfAccrualServices
	|
	|ORDER BY
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInterestSchedule.Date AS Date,
	|	TTInterestSchedule.Interests AS Interests
	|FROM
	|	TTInterestSchedule AS TTInterestSchedule
	|
	|ORDER BY
	|	Date";
	QueryPackageTexts.Add(QueryText);
	
	QueryText = LeaseTermAdjustmentLocalization.RequestTextFillingInTSByAgreement();
	
	If QueryText = Undefined Then
		QueryText =	
		"SELECT
		|	LeasedAsset.FixedAsset AS FixedAsset,
		|	CASE WHEN &CalculationOfActualCost THEN
		|		CASE WHEN FixedAssetsDepreciationCharge.DepreciationLocalBalance <> 0 THEN
		|			LeasedAsset.Cost + ISNULL(FixedAssetsDepreciationCharge.DepreciationLocalBalance, 0) * &LocalCoefficient
		|		WHEN FixedAssetsDepreciationCharge.DepreciationBalance <> 0 THEN
		|			LeasedAsset.Cost + ISNULL(FixedAssetsDepreciationCharge.DepreciationBalance, 0) * &ManSCoefficient
		|		ELSE
		|			LeasedAsset.Cost
		|		END
		|	ELSE
		|		LeasedAsset.ParValue
		|	END AS FairValue,
		|	CASE WHEN &CalculationOfActualCost THEN
		|		CASE WHEN FixedAssetsDepreciationCharge.DepreciationLocalBalance <> 0 THEN
		|			LeasedAsset.Cost + ISNULL(FixedAssetsDepreciationCharge.DepreciationLocalBalance, 0) * &LocalCoefficient
		|		WHEN FixedAssetsDepreciationCharge.DepreciationBalance <> 0 THEN
		|			LeasedAsset.Cost + ISNULL(FixedAssetsDepreciationCharge.DepreciationBalance, 0) * &ManSCoefficient
		|		ELSE
		|			LeasedAsset.Cost
		|		END
		|	ELSE
		|		0
		|	END AS Cost,
		|	LeasedAsset.Action AS ActionWithRentalObject,
		|	LeasedAsset.Department,
		|	LeasedAsset.ExpenseItem,
		|	ISNULL(FACost.CostBalance, 0) AS CostInManagementAccounting,
		|	ISNULL(FACost.LocalCostBalance, 0) AS CostInAccounting,
		|	ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsAC, 0) AS UsefulLifeAccounting,
		|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths, 0) AS UsefulLifeManagementAccounting
		|FROM
		|	TTLeasedFA AS LeasedAsset
		|
		|		LEFT JOIN AccumulationRegister.FACost.Balance(
		|			&PeriodLimit, 
		|			Organization = &Organization
		|				AND FixedAsset IN (
		|					SELECT 
		|						TTLeasedFA.FixedAsset 
		|					FROM 
		|						TTLeasedFA AS TTLeasedFA)) AS FACost
		|		ON FACost.FixedAsset = LeasedAsset.FixedAsset
		|
		|		LEFT JOIN InformationRegister.OSBUDepreciationParameters.SliceLast(
		|			&Date, 
		|			Recorder <> &Ref
		|				AND Organization = &Organization
		|				AND CorrectionDate = DATETIME(1,1,1)
		|				AND FixedAsset IN (
		|					SELECT 
		|						TTLeasedFA.FixedAsset 
		|					FROM 
		|						TTLeasedFA AS TTLeasedFA)) AS OSBUDepreciationParameters
		|		ON OSBUDepreciationParameters.FixedAsset = LeasedAsset.FixedAsset
		|
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
		|			&Date, 
		|			Recorder <> &Ref
		|				AND Organization = &Organization
		|				AND CorrectionDate = DATETIME(1, 1, 1)
		|				AND FixedAsset IN (
		|					SELECT 
		|						TTLeasedFA.FixedAsset 
		|					FROM 
		|						TTLeasedFA AS TTLeasedFA)) AS FixedAssetDepreciationParametersManagementAccounting
		|		ON FixedAssetDepreciationParametersManagementAccounting.FixedAsset = LeasedAsset.FixedAsset
		|
		|		LEFT JOIN AccumulationRegister.FixedAssetsDepreciationCharge.Balance(&BegOfMonth, Organization = &Organization
		|		AND FixedAsset IN
		|			(SELECT
		|				TTLeasedFA.FixedAsset
		|			FROM
		|				TTLeasedFA AS TTLeasedFA)) AS FixedAssetsDepreciationCharge
		|		ON FixedAssetsDepreciationCharge.FixedAsset = LeasedAsset.FixedAsset
		|		AND &CalculationOfActualCost
		|
		|ORDER BY
		|	LeasedAsset.FixedAsset.Description,
		|	LeasedAsset.FixedAsset.AssetID";
		
	EndIf;
	
	QueryPackageTexts.Add(QueryText);
	
	QueryText = StrConcat(QueryPackageTexts, Common.QueryBatchSeparator());
	
	DocDate = ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate());

	ContractDetails_ = LeasedAssetAccounting.DetailsOfLeaseAgreement(Object.Contract);
	CalculationOfActualCost = ContractDetails_.MethodForDeterminingCostOfAssets
			= Enums.MethodsOfDeterminingLeasedAssetCost.Manually;
	ConversionFactorFromLocalCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization),
		Object.Currency,
		DocDate);
	ConversionFactorFromManCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		SettingsValueCached.ManagementAccountingCurrency(),
		Object.Currency,
		DocDate);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("Date", DocDate);
	Query.SetParameter("PeriodLimit", New Boundary(New PointInTime(DocDate, Object.Ref), BoundaryType.Excluding));
	Query.SetParameter("Refill", Not Refresh);
	Query.SetParameter("ServicePaymentSchedule", ServicePaymentSchedule);
	Query.SetParameter("ServiceAccrualSchedule", ServiceAccrualSchedule);
	Query.SetParameter("FA", FA);
	Query.SetParameter("BegOfMonth", BegOfMonth(DocDate));
	Query.SetParameter("CalculationOfActualCost", CalculationOfActualCost);
	Query.SetParameter("LocalCoefficient", ConversionFactorFromLocalCurrency);
	Query.SetParameter("ManSCoefficient", ConversionFactorFromManCurrency);
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	
	Result = Query.ExecuteBatch();
	If Result[0].IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result[Result.UBound()-4].Select();
	Selection.Next();
	
	FillPropertyValues(Object, Selection);
	
	Object.ServicePaymentSchedule.Load(Result[Result.UBound()-3].Unload());
	Object.ServiceAccrualSchedule.Load(Result[Result.UBound()-2].Unload());
	Object.InterestAccrualSchedule.Load(Result[Result.UBound()-1].Unload());
	Object.FA.Load(Result[Result.UBound()].Unload());
	
	If Selection.AmountOfVATRepurchaseOfRentalItems = 0 Then
		CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(Object.VATRate);
		Object.AmountOfVATRepurchaseOfRentalItems = VATAccountingERPClientServer.CalculateVATAmount(Object.AmountOfLeaseAssetsByuout, CurPercentVAT, True);
	EndIf;
	
	LeasedAssetAccountingClientServer.RecalculateAmountOfRentalDocument(Object);
	LeasedAssetAccountingClientServer.RecalculateAmountOfNDSInLeaseDocument(Object);
	
EndProcedure

#EndRegion

#Region Print

Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = Catalogs.LeaseContract.AddCommandToDecryptPercentageCalculation(PrintCommands);
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(PrintCommand, "TheInterestAccrualScheduleIsEnteredManually", False);
	
EndProcedure

#EndRegion

#Region Other

// Parameters for selecting articles and analytics.
// 
// Parameters:
//  CreatedForTransition - Boolean - Created for transition.
// 
// Returns:
//  See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
Function ItemsAndDimensionsSelectionParameters(CreatedForTransition) Export

	ParametersList = New Array; // Structure
	
	#Region Expenses
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ItemTypeExpenses";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = CreatedForTransition;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimensionExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimensionExpenses");
	
	ParametersList.Add(ChoiceParameters);
	#EndRegion
	
	#Region Income
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";

	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	ParametersList.Add(ChoiceParameters);
	#EndRegion

	Return ParametersList;
	
EndFunction

Function AccountingAccountSettings_() Export
	
	ParametersList = New Array;

	#Region Expenses
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.Presentation = "PresentationOfTheReflectionInTheReglAccountingExpenses";
	SetupParameters.ArticleType = "ItemTypeExpenses";
	SetupParameters.GLAccountSettings = "GlAccountSettingsExpenses";
	
	SetupParameters.Organization = "Object.Organization";
	SetupParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimensionExpenses";

	SetupParameters.FormItems.Add("PresentationOfTheReflectionInTheReglAccountingExpenses");
	
	ParametersList.Add(SetupParameters);
	#EndRegion
	
	Return ParametersList;
	
EndFunction

// Calculate the rate, cost, interest.
// 
// Parameters:
//  Object - DocumentObject.LeaseTermAdjustment
//  ContractDetails_ - Structure
Procedure CalculateRateCostInterest(Object, ContractDetails_) Export

	CalculationParameters = LeasedAssetAccounting.InterestRateCalculationParameters(Object, ContractDetails_);
	CalculationParameters.FATable = Object.FA;
	CalculationParameters.LeaseStartDate = Object.LeaseStartDate;
	
	CalculationParameters.Insert("CreatedForTransition", LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Object.Date, Object.Organization));
	
	PreviousConditions = LeasedAssetAccounting.CostAccordingToPreviousConditions(Object, True);
	CalculationParameters.Insert("PresentValueUnderPreviousConditions", PreviousConditions.PresentValue);
	CalculationParameters.Insert("PrevChangeData", PreviousConditions.ChangeDate);
	If PreviousConditions.InterestGraph <> Undefined Then
		CalculationParameters.Insert("InterestScheduleForPreviousConditions", PreviousConditions.InterestGraph);
	EndIf;
	
	CalculationParameters.LeaseItemsCost
		= LeasedAssetAccountingClientServer.LeaseItemsCost(Object, ContractDetails_, "FA");

	// The calculation is based on data from the tabular parts of the document.
	// The filling of the tabular parts depends on the mode of transition to FSBU25.
	LeasedAssetAccounting.CalculateRateCostInterest(CalculationParameters);
	
	Object.InterestRate = CalculationParameters.InterestRate;
	Object.InterestAmount = CalculationParameters.InterestAmount;
	Object.PresentValue = CalculationParameters.PresentValue;
	
EndProcedure

Procedure CheckRelevanceOfLeaseContract(Ref, Contract, NewContract, Date, Cancel = False) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PRESENTATION(TermsOfLeaseContractsAsOfDate.EffectiveContractTerms) AS PresentationOfDocument,
		|	TermsOfLeaseContractsAsOfDate.State AS State,
		|	TermsOfLeaseContractsAsOfDate.LeaseStartDate AS LeaseStartDate
		|FROM
		|	InformationRegister.TermsOfLeaseContracts.SliceLast(
		|			&Date,
		|			Recorder <> &Ref
		|				AND Contract = &Contract) AS TermsOfLeaseContractsAsOfDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 10
		|	PRESENTATION(TermsOfLeaseContracts.Recorder) AS PresentationOfDocument,
		|	TermsOfLeaseContracts.Recorder AS DocumentReference
		|FROM
		|	InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
		|WHERE
		|	(TermsOfLeaseContracts.Recorder REFS Document.LeaseTermAdjustment
		|	OR TermsOfLeaseContracts.Recorder REFS Document.SigningOfLeaseContract)
		|	AND BEGINOFPERIOD(TermsOfLeaseContracts.Period, DAY) = BEGINOFPERIOD(&Date, DAY)
		|	AND TermsOfLeaseContracts.Contract = &Contract
		|	AND TermsOfLeaseContracts.Recorder <> &Ref
		|ORDER BY
		|	TermsOfLeaseContracts.Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 10
		|	PRESENTATION(TermsOfLeaseContracts.Recorder) AS PresentationOfDocument,
		|	TermsOfLeaseContracts.Recorder AS DocumentReference
		|FROM
		|	InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
		|WHERE
		|	TermsOfLeaseContracts.Period >= &Date
		|	AND TermsOfLeaseContracts.Contract IN (&Contract, &NewContract)
		|	AND TermsOfLeaseContracts.Recorder <> &Ref
		|ORDER BY
		|	TermsOfLeaseContracts.Period";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("NewContract", NewContract);
	Query.SetParameter("Ref", Ref);
	
	QueryResults = Query.ExecuteBatch();
	
	DocumentReference = Ref;
	If QueryResults[0].IsEmpty() Then
		ErrorText = StrTemplate(NStr("vi = 'Chưa ký kết hợp đồng vào ngày %1';
									|ru = 'Не оформлено заключение договора на дату %1';
									|en = 'Contract conclusion is not registered as of %1'; fa = 'Contract conclusion is not registered as of %1';
									|it = 'Не оформлено заключение договора на дату %1';
									|pl = 'Contract conclusion is not registered as of %1';
									|tr = 'Sözleşmenin imzalanması %1 tarihinde tamamlanmadı'"), Date);
	EndIf;
	
	Selection = QueryResults[0].Select();
	Selection.Next();
	
	If Not ValueIsFilled(ErrorText) And Selection.State <> Enums.CounterpartyContractStates.Valid Then
		ErrorText = StrTemplate(NStr("vi = 'Hợp đồng thuê không còn hiệu lực vào ngày %1';
									|ru = 'Договор аренды не действует на дату %1';
									|en = 'The rental contract is not valid as of %1'; fa = 'The rental contract is not valid as of %1';
									|it = 'Договор аренды не действует на дату %1';
									|pl = 'The rental contract is not valid as of %1';
									|tr = 'Kira sözleşmesi %1 tarihi itibarıyla yürürlükte değildir'"), Date);
		ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Xem chứng từ: %1';
															|ru = 'См. документ: %1';
															|en = 'See the document: %1'; fa = 'See the document: %1';
															|it = 'См. документ: %1';
															|pl = 'See the document: %1';
															|tr = 'Bk. belge: %1'"), Selection.PresentationOfDocument);
	EndIf; 
	
	If Not ValueIsFilled(ErrorText) And Selection.LeaseStartDate >= Date Then
		ErrorText = StrTemplate(NStr("vi = 'Ngày chứng từ cần lớn hơn ngày bắt đầu thuê %1';
									|ru = 'Дата документа должна быть больше даты начала аренды %1';
									|en = 'The document date must be later than the rental start date %1'; fa = 'The document date must be later than the rental start date %1';
									|it = 'Дата документа должна быть больше даты начала аренды %1';
									|pl = 'The document date must be later than the rental start date %1';
									|tr = 'Belge tarihi, kira başlangıç %1 ​​tarihinden sonra olmalıdır'"), Selection.LeaseStartDate);
		ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Xem chứng từ: %1';
															|ru = 'См. документ: %1';
															|en = 'See the document: %1'; fa = 'See the document: %1';
															|it = 'См. документ: %1';
															|pl = 'See the document: %1';
															|tr = 'Bk. belge: %1'"), Selection.PresentationOfDocument);
	EndIf;
	
	If Not ValueIsFilled(ErrorText) And Not QueryResults[1].IsEmpty() Then
		ErrorText = NStr("vi = 'Vào một ngày, không thể tạo nhiều chứng từ thay đổi điều kiện thuê theo một hợp đồng. Sẽ không cho phép kết chuyển chứng từ.';
						|ru = 'В один день не может быть оформлено несколько документов изменений условий аренды по одному договору. Проведение документа будет недоступно.';
						|en = 'You cannot create several rental term adjustment documents under one contract within one day. You will not be able to post the document.'; fa = 'You cannot create several rental term adjustment documents under one contract within one day. You will not be able to post the document.';
						|it = 'В один день не может быть оформлено несколько документов изменений условий аренды по одному договору. Проведение документа будет недоступно.';
						|pl = 'You cannot create several rental term adjustment documents under one contract within one day. You will not be able to post the document.';
						|tr = 'Aynı sözleşme için aynı gün birden fazla kira değişikliği belgesi düzenlenemez. Belgenin kaydedilmesi mümkün olmayacaktır.'");
		Selection = QueryResults[1].Select();
		FirstDocument = True;
		While Selection.Next() Do
			If FirstDocument Then
				DocumentReference = Selection.DocumentReference;
				FirstDocument = False;
			EndIf;
			ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Xem chứng từ: %1';
																|ru = 'См. документ: %1';
																|en = 'See the document: %1'; fa = 'See the document: %1';
																|it = 'См. документ: %1';
																|pl = 'See the document: %1';
																|tr = 'Bk. belge: %1'"), Selection.PresentationOfDocument);
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(ErrorText) And Not QueryResults[2].IsEmpty() Then
		ErrorText = NStr("vi = 'Đã tạo nhiều chứng từ sau này thay đổi điều kiện hợp đồng. Sẽ không cho phép kết chuyển chứng từ.';
						|ru = 'Оформлены более поздние документы изменения условий договора. Проведение документа будет недоступно.';
						|en = 'More recent contract term adjustment documents were issued. You will not be able to post the document.'; fa = 'More recent contract term adjustment documents were issued. You will not be able to post the document.';
						|it = 'Оформлены более поздние документы изменения условий договора. Проведение документа будет недоступно.';
						|pl = 'More recent contract term adjustment documents were issued. You will not be able to post the document.';
						|tr = 'Daha sonraki sözleşme değişiklik belgeleri düzenlenmiştir. Belgenin kaydedilmesi mümkün olmayacaktır.'");
		Selection = QueryResults[2].Select();
		FirstDocument = True;
		While Selection.Next() Do
			If FirstDocument Then
				DocumentReference = Selection.DocumentReference;
				FirstDocument = False;
			EndIf;
			ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Xem chứng từ: %1';
																|ru = 'См. документ: %1';
																|en = 'See the document: %1'; fa = 'See the document: %1';
																|it = 'См. документ: %1';
																|pl = 'See the document: %1';
																|tr = 'Bk. belge: %1'"), Selection.PresentationOfDocument);
		EndDo;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		Common.MessageToUser(ErrorText, DocumentReference, "Object.Date",, Cancel);
	EndIf;
	
EndProcedure

Function PreviousTermsOfLeaseContract(Ref, Contract, Date) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TermsOfLeaseContractsAsOfDate.EffectiveContractTerms AS TermsOfAgreement_,
		|	TermsOfLeaseContractsAsOfDate.State AS State
		|FROM
		|	InformationRegister.TermsOfLeaseContracts.SliceLast(&Date, Recorder <> &Ref AND Contract = &Contract) AS TermsOfLeaseContractsAsOfDate";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		If Selection.State = Enums.CounterpartyContractStates.Valid Then
			Return Selection.TermsOfAgreement_;
		Else
			Return Undefined;
		EndIf;
	Else
		Return Undefined;
	EndIf;

EndFunction 

Procedure FillInChartsForPreviousConditionsTakingIntoAccountChanges(Object) Export
	
	If Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	ServicePaymentSchedule = Object.ServicePaymentSchedule.Unload();
	ServiceAccrualSchedule = Object.ServiceAccrualSchedule.Unload();
	InterestAccrualSchedule = Object.InterestAccrualSchedule.Unload();

	Object.ServicePaymentSchedule.Clear();
	Object.ServiceAccrualSchedule.Clear();
	Object.InterestAccrualSchedule.Clear();
	
	QueryText = "SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms
	|INTO TTTermsOfLeaseAgreements
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|			&Date,
	|			Recorder <> &Ref
	|				AND Contract = &Contract) AS TermsOfLeaseContracts
	|;
	| 
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	ScheduleData.BuyoutValue AS BuyoutValue,
	|	ScheduleData.BuyoutValueVAT AS BuyoutValueVAT
	|INTO TTPaymentScheduleForServicesFromDocument
	|FROM
	|	&ServicePaymentSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.Date >= BEGINOFPERIOD(&Date, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount
	|INTO TTScheduleOfAccrualOfServicesFromDocument
	|FROM
	|	&ServiceAccrualSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.Date >= BEGINOFPERIOD(&Date, DAY)
	|; 
	|
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.Interests AS Interests
	|INTO TTScheduleOfAccrualOfInterestFromDocument
	|FROM
	|	&InterestAccrualSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.Date >= BEGINOFPERIOD(&Date, DAY)
	|; 
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	ScheduleData.BuyoutValue + ScheduleData.BuyoutValuePrepayment AS BuyoutValue,
	|	ScheduleData.BuyoutValueVAT AS BuyoutValueVAT
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.EffectiveContractTerms IN
	|			(SELECT
	|				T.EffectiveContractTerms
	|			FROM
	|				TTTermsOfLeaseAgreements AS T)
	|	AND ScheduleData.Contract = &Contract
	|	AND ScheduleData.Active
	|	AND (ScheduleData.Date < BEGINOFPERIOD(&Date, DAY))
	|
	|UNION ALL
	|
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	ScheduleData.BuyoutValue AS BuyoutValue,
	|	ScheduleData.BuyoutValueVAT AS BuyoutValueVAT
	|FROM
	|	TTPaymentScheduleForServicesFromDocument AS ScheduleData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount
	|FROM
	|	InformationRegister.LeaseServicesAccrualSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.EffectiveContractTerms IN
	|			(SELECT
	|				T.EffectiveContractTerms
	|			FROM
	|				TTTermsOfLeaseAgreements AS T)
	|	AND ScheduleData.Contract = &Contract
	|	AND ScheduleData.Active
	|	AND (ScheduleData.RentalService <> 0
	|			OR ScheduleData.DepositPayment <> 0)
	|	AND (ScheduleData.Date < BEGINOFPERIOD(&Date, DAY))
	|
	|UNION ALL
	|
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount
	|FROM
	|	TTScheduleOfAccrualOfServicesFromDocument AS ScheduleData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.Interests AS Interests
	|FROM
	|	InformationRegister.LeaseInterestAccrualSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.EffectiveContractTerms IN
	|			(SELECT
	|				T.EffectiveContractTerms
	|			FROM
	|				TTTermsOfLeaseAgreements AS T)
	|	AND ScheduleData.Contract = &Contract
	|	AND ScheduleData.Active
	|
	|UNION ALL
	|
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.Interests AS Interests
	|FROM
	|	TTScheduleOfAccrualOfInterestFromDocument AS ScheduleData";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("ServicePaymentSchedule", ServicePaymentSchedule);
	Query.SetParameter("ServiceAccrualSchedule", ServiceAccrualSchedule);
	Query.SetParameter("InterestAccrualSchedule", InterestAccrualSchedule);
	
	Result = Query.ExecuteBatch();
	If Result[0].IsEmpty() Then
		Return;
	EndIf;

	Object.ServicePaymentSchedule.Load(Result[Result.UBound()-2].Unload());
	Object.ServiceAccrualSchedule.Load(Result[Result.UBound()-1].Unload());
	Object.InterestAccrualSchedule.Load(Result[Result.UBound()].Unload());
	
EndProcedure

// The value of the change in the present cost, at which the change is not fixed in the movements
// and is considered a rounding error.
// 
// Returns:
//  Number - Threshold For Rounding Changes In Present Value
Function ThresholdForRoundingChangesInPresentValue() Export
	
	Return 0.015;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
