
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
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("ImportAccounting");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("FinancialInstruments");
	
	VendorInvoiceLeasedAssetsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);

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
	
	If TypeOf(Document) = Type("DocumentObject.VendorInvoiceLeasedAssets") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		GenerateExtendedFATable(Query, QueryTexts);
		
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		
		QueryTextTableFixedAssetsAccountingProcedure(Query, QueryTexts, Registers);
		QueryTextTableLeasedAsset(QueryTexts, Registers);
		QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers);
		
		RequestTextTableOfVATReflection(Query, QueryTexts, Registers);
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableGoodsForRegistrationOfImportDocuments(QueryTexts, Registers);
		QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		VendorInvoiceLeasedAssetsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  DocumentRef			 - DocumentRef.VendorInvoiceLeasedAssets - Document for which movements are generated
//  TempTablesManager	 - TempTablesManager - Contains auxiliary temporary tables that can be used for forming movements.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfDeferredMotionFormation(DocumentRef, TempTablesManager) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	FillInInitializationParameters(Query, DocumentRef, Undefined);
	
	QueryTexts = New ValueList;
	
	GenerateExtendedFATable(Query, QueryTexts);
	
	QueryTextTableFACost(Query, QueryTexts);
	QueryTextTableFixedAssetsDepreciationCharge(QueryTexts);
	QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Undefined);
	
	QueryTextTableOtherExpenses(Query, QueryTexts, Undefined);
	QueryTextTableItemisedExpensesLots(Query, QueryTexts, Undefined);
	QueryTextTableOtherIncome(Query, QueryTexts, Undefined);
	
	QueryTextTableFixedAssetsAccountingProcedure(Query, QueryTexts, Undefined);
	QueryTextTableLeasedAsset(QueryTexts, Undefined);
	QueryTextTableTermsOfLeaseContracts(QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	VendorInvoiceLeasedAssetsLocalization.AddTablesOfDeferredFormationOfRegisteredRecords(Query, QueryTexts);
	
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
	
	Documents.ChangeFixedAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);

EndProcedure

// Adds the command to create the document "Purchase of leased assets".
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
	
	If AccessRight("Insert", Metadata.Documents.VendorInvoiceLeasedAssets) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.VendorInvoiceLeasedAssets.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.VendorInvoiceLeasedAssets);
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

#Region AccountingMechanisms

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization, Department", Parameters);
	
EndProcedure

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'In biên bản / hóa đơn GTGT';
							|ru = 'Акт';
							|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
							|it = 'Atto';
							|pl = 'Customer invoice — Services';
							|tr = 'Tutanak'"));
	Return ArrayOfNames
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

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "VendorInvoiceLeasedAssets");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

#Region Posting

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	RegisterName = "DocumentAmountsInAccountingCurrency";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable("DocumentAmountsInAccountingCurrency", QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(QueryTexts);
	
	Text = "
	|////////////////////////////////////////////////////////////////////////////////
	|// Table DocumentAmountsInAccountingCurrency
	|"+
	"SELECT
	|	*
	|FROM
	|	TTAmountsOfDocumentsInAccountingCurrencies";
	
	QueryTexts.Add(Text, RegisterName);
	
EndProcedure

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Organization                    AS Organization,
	|	DocumentData.Partner                        AS Partner,
	|	DocumentData.Counterparty                     AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	Document.VendorInvoiceLeasedAssets AS DocumentData
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON DocumentData.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND DocumentData.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND DocumentData.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = RegisterAccountingAnalyticsForPartners.Contract
	|			AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND RegisterAccountingAnalyticsForPartners.DimensionKey IS NULL";
	
	QueryAnalyst = New Query(QueryText);
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
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
	
	FullDocumentName = "Document.VendorInvoiceLeasedAssets";
	TemporaryTableQueryTexts = New Map();
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("LineOfBusiness", "DocumentData.Contract.LineOfBusiness");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		RequestHasSource = False;
		
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
	|	DocumentData.Date AS Period,
	|	DocumentData.Number,
	|	DocumentData.DeletionMark,
	|	DocumentData.Posted,
	|	DocumentData.Ref,
	|	DocumentData.Organization,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	DocumentData.Contract,
	|	DocumentData.Contract.AssetHolder AS AssetHolder,
	|	DocumentData.Contract.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Contract.ForeignCurrencyTransaction AS CurrencyContract,
	|	ISNULL(CatLeaseContracts.RegisterImportApplications, FALSE) AS RegisterImportApplications,
	|	DocumentData.Currency,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.DocumentAmount,
	|	DocumentData.AmountARAP,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition,
	|	DocumentData.ExpenseItemTaxBuyout,
	|	DocumentData.IncomeDimensionInCaseOfEarlyRedemption,
	|	DocumentData.IncomeItemBuyout,
	|	DocumentData.ExpensesDimensionInCaseOfEarlyBuyout,
	|	DocumentData.DepreciationGroup,
	|	DocumentData.AccountingProcedureTA,
	|	DocumentData.DepreciationAccrualTaxAccounting,
	|	DocumentData.SpecialFactorTaxAccounting,
	|	DocumentData.UsefulLifeTaxAccounting,
	|	DocumentData.ExpenseRecordMethodTA,
	|	DocumentData.ExpenseItemTaxAccounting,
	|	DocumentData.ExpensesDimensionTaxAccounting,
	|	DocumentData.BusinessUnitTaxAccounting,
	|	DocumentData.LineOfBusinessTaxAccounting,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTaxAccounting,
	|	DocumentData.ExpenseItemForTax,
	|	DocumentData.ExpensesDimensionTax,
	|	DocumentData.ToIncludeDepreciationAllowanceInExpenses,
	|	DocumentData.MethodOfRecordingBonusDepreciationExpenses,
	|	DocumentData.ExpenseItemOfDepreciationAllowance,
	|	DocumentData.DepreciationAllowanceExpensesDimension,
	|	DocumentData.BusinessUnitBonusDepreciation,
	|	DocumentData.LineOfBusinessBonusDepreciation,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciation,
	|	DocumentData.BonusDepreciationPercentage,
	|	DocumentData.Department,
	|	DocumentData.PurchaseForActivity,
	|	DocumentData.VATTaxation,
	|	DocumentData.IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate,
	|	DocumentData.ExternalDocumentName,
	|	DocumentData.FixedAssetsEvent,
	|	DocumentData.BusinessOperation,
	|	DocumentData.EmployeeResponsible,
	|	DocumentData.Comment,
	|	DocumentData.DocumentID,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Organization.LocalAccountingCurrency AS ComplCurrency,
	|	DocumentData.GeneratedDocument
	|FROM
	|	Document.VendorInvoiceLeasedAssets AS DocumentData
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
	|	DocumentData.Contract AS Contract,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	TRUE AS RecordInManAccounting,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS PostInAccounting,
	|	TRUE AS RecordInTA
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.VendorInvoiceLeasedAssets AS DocumentData
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
	|	DocumentTable.FixedAsset AS AccountingObject
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS DocumentTable
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
	
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.VendorInvoiceLeasedAssets"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Mua lại TSCĐ đã thuê';
															|ru = 'Выкуп арендованных ОС';
															|en = 'Vendor invoice — Leased assets'; fa = 'فاکتور تأمین‌کننده — دارایی‌های اجاره‌ای';
															|it = 'Rimborso immobilizzazioni in affitto';
															|pl = 'Wykup wynajmowanych środków trwałych';
															|tr = 'Kiralanan sabit kıymetlerin itfası'"));
	ValuesOfHoldingParameters.Insert("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	ValuesOfHoldingParameters.Insert("CurrencyOfMan", ValuesOfHoldingParameters.ManagementAccountingCurrency);
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	ValuesOfHoldingParameters.Insert("BO_GenerationOfLeasedFixedAssetsCost", Enums.BusinessTransactions.GenerationOfLeasedFixedAssetsCost);
	ValuesOfHoldingParameters.Insert("SettingUpHO_FORMINGCostOfLeasedFA", Catalogs.BusinessTransactionsSettings.GenerationOfLeasedFixedAssetsCost);
	
	ValuesOfHoldingParameters.Insert("BO_WriteOffFixedAssetsCost", Enums.BusinessTransactions.WriteOffFixedAssetsCost);
	ValuesOfHoldingParameters.Insert("ConfiguringHO_ChargingCostOfFA", Catalogs.BusinessTransactionsSettings.WriteOffFixedAssetsCost);

	ValuesOfHoldingParameters.Insert("IdApplicationForImportOfGoods", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Attributes.Organization, Attributes.Period));
	
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Undefined, Attributes.Period, Attributes.Organization);
		ValuesOfHoldingParameters.Insert("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
		ValuesOfHoldingParameters.Insert("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
		
		ConversionFactorFromManCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			ValuesOfHoldingParameters.ManagementAccountingCurrency, 
			Attributes.ARAPCurrency, 
			Attributes.Period,
			Attributes.LocalAccountingCurrency);
		ValuesOfHoldingParameters.Insert("ConversionFactorFromManCurrency", ConversionFactorFromManCurrency);
		
		ConversionFactorFromLocalCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			Attributes.ComplCurrency, 
			Attributes.ARAPCurrency, 
			Attributes.Period,
			Attributes.ComplCurrency);
		ValuesOfHoldingParameters.Insert("ConversionFactorFromLocalCurrency", ConversionFactorFromLocalCurrency);
		
		ValuesOfHoldingParameters.Insert("DocumentOfConclusionOfContractOfLease", Catalogs.LeaseContract.DocumentOfConclusionOfContractOfLease(Attributes.Contract));
	
		ValuesOfHoldingParameters.Insert("EarlyPartialRedemption", Attributes.GeneratedDocument);
	
	EndIf;
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Procedure GenerateExtendedFATable(Query, QueryTexts)

	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);

EndProcedure

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
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
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&DocumentAmount                         AS Sum,
	|	&Currency                                 AS Currency,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Department                          AS Department,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&IncomingDocumentDate                 AS SourceDocumentDate,
	|	&IncomingDocumentNumber                AS SourceDocumentNumber,
	|	&ExternalDocumentName         AS SourceDocumentName,
	|	&Period                                 AS RecordingInAccountingDate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
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
	|	TRUE                                  AS RecordInTA,
	|	&FixedAssetsEvent                              AS FixedAssetsEvent,
	|	FATable.FixedAsset              AS FixedAsset,
	|	FALSE                                    AS AdditionalRecord
	|FROM
	|	Document.VendorInvoiceLeasedAssets AS DocumentData
	|		LEFT JOIN Document.VendorInvoiceLeasedAssets.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";	
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFACost(Query, QueryTexts)

	RegisterName = "FACost";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	ListOfMergeRequests = New Array;
	
	#Region TransferCost
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	&Ref                                     AS Recorder,
	|	&Period                                     AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetsCostParameterChange) AS BusinessOperation,
	|	&Organization                                AS Organization,
	|	FATable.FixedAsset                  AS FixedAsset,
	|	InformationAboutAccounting.FixedAssetsLocation             AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|	InformationAboutAccounting.Leaseholder                   AS Leaseholder,
	|
	|	FACost.Cost                       AS Cost,
	|	FACost.LocalCost                   AS LocalCost,
	|
	|	FACost.CostInTaxAccounting - ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0) AS CostInTaxAccounting,
	|
	|	FACost.CostPermanentDifference                     AS CostPermanentDifference,
	|
	|	FACost.CostTemporaryDifference + ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0) AS CostTemporaryDifference,
	|
	|	FACost.CostTargetFinancing                     AS CostTargetFinancing,
	|
	|	FACost.CostTargetFinancingTA - ISNULL(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing, 0) AS CostTargetFinancingTA,
	|
	|	FACost.CostTargetFinancingPD                   AS CostTargetFinancingPD,
	|
	|	FACost.CostTargetFinancingTD + ISNULL(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing, 0) AS CostTargetFinancingTD,
	|
	|	0                                           AS DisregardedCostTA,
	|	FACost.DepreciationAllowance           AS DepreciationAllowance,
	|	FACost.SecurityDepositValue              AS SecurityDepositValue,
	|	FACost.PreliminaryCostMan        AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal    AS PreliminaryCostLocal,
	|	FACost.CostRevaluationReserve       AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal   AS CostRevaluationReserveLocal,
	|	0                                           AS CostGainMA,
	|	0                                           AS CostGainLocal,
	|
	|	&Organization                                AS CorCompany,
	|	InformationAboutAccounting.FixedAssetsLocation             AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness     AS CorLineOfBusiness,
	|	FATable.FinancialAccountingGroup            AS CorFinancialAccountingGroup,
	|
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	
	|	FATable.RowID               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsCostParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS FATable
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = &Ref
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|			AND FixedAssetsDepreciationCharge.Ref = &Ref
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND FATable.FinancialAccountingGroup <> InformationAboutAccounting.FinancialAccountingGroup
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Ref                                     AS Recorder,
	|	&Period                                     AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetsCostParameterChange) AS BusinessOperation,
	|	&Organization                                AS Organization,
	|	FATable.FixedAsset                  AS FixedAsset,
	|	InformationAboutAccounting.FixedAssetsLocation             AS Department,
	|	FATable.FinancialAccountingGroup            AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|	InformationAboutAccounting.Leaseholder                   AS Leaseholder,
	|
	|	FACost.Cost                       AS Cost,
	|	FACost.LocalCost                   AS LocalCost,
	|
	|	FACost.CostInTaxAccounting - ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0) AS CostInTaxAccounting,
	|
	|	FACost.CostPermanentDifference                     AS CostPermanentDifference,
	|
	|	FACost.CostTemporaryDifference + ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0) AS CostTemporaryDifference,
	|
	|	FACost.CostTargetFinancing                     AS CostTargetFinancing,
	|
	|	FACost.CostTargetFinancingTA - ISNULL(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing, 0) AS CostTargetFinancingTA,
	|
	|	FACost.CostTargetFinancingPD                   AS CostTargetFinancingPD,
	|
	|	FACost.CostTargetFinancingTD + ISNULL(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing, 0) AS CostTargetFinancingTD,
	|
	|	0                                           AS DisregardedCostTA,
	|	FACost.DepreciationAllowance           AS DepreciationAllowance,
	|	FACost.SecurityDepositValue              AS SecurityDepositValue,
	|	FACost.PreliminaryCostMan        AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal    AS PreliminaryCostLocal,
	|	FACost.CostRevaluationReserve       AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal   AS CostRevaluationReserveLocal,
	|	0                                           AS CostGainMA,
	|	0                                           AS CostGainLocal,
	|
	|	&Organization                                AS CorCompany,
	|	InformationAboutAccounting.FixedAssetsLocation             AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness     AS CorLineOfBusiness,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	
	|	FATable.RowID               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsCostParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS FATable
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = &Ref
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|			AND FixedAssetsDepreciationCharge.Ref = &Ref
	|WHERE
	|	FATable.Ref = &Ref
	|	AND FATable.FinancialAccountingGroup <> InformationAboutAccounting.FinancialAccountingGroup";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region MovingValuationReserve
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Ref                                     AS Recorder,
	|	&Period                                     AS Period,
	|	VALUE(Enum.BusinessTransactions.ChangeRevaluationReserveOfFixedAssetsCost) AS BusinessOperation,
	|	&Organization                                AS Organization,
	|	FATable.FixedAsset                  AS FixedAsset,
	|	InformationAboutAccounting.FixedAssetsLocation             AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|	UNDEFINED                                AS Leaseholder,
	|
	|	0                                           AS Cost,
	|	0                                           AS LocalCost,
	|	0                                           AS CostInTaxAccounting,
	|	0                                           AS CostPermanentDifference,
	|	0                                           AS CostTemporaryDifference,
	|	0                                           AS CostTargetFinancing,
	|	0                                           AS CostTargetFinancingTA,
	|	0                                           AS CostTargetFinancingPD,
	|	0                                           AS CostTargetFinancingTD,
	|	0                                           AS DisregardedCostTA,
	|	0                                           AS DepreciationAllowance,
	|	0                                           AS SecurityDepositValue,
	|	0                                           AS PreliminaryCostMan,
	|	0                                           AS PreliminaryCostLocal,
	|	0                                           AS CostRevaluationReserve,
	|	0                                           AS CostRevaluationReserveLocal,
	|
	|	FACost.CostGainMA                AS CostGainMA,
	|	FACost.CostGainLocal            AS CostGainLocal,
	|
	|	UNDEFINED                                AS CorCompany,
	|	UNDEFINED                                AS DebitBusinessUnit,
	|	UNDEFINED                                AS CorLineOfBusiness,
	|	UNDEFINED                                AS CorFinancialAccountingGroup,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	
	|	FATable.RowID               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ChangeRevaluationReserveOfFixedAssetsCost) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS FATable
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = &Ref
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND FATable.FinancialAccountingGroup <> InformationAboutAccounting.FinancialAccountingGroup
	|	AND (FACost.CostGainMA <> 0 OR FACost.CostGainLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	&Ref                                     AS Recorder,
	|	&Period                                     AS Period,
	|	VALUE(Enum.BusinessTransactions.ChangeRevaluationReserveOfFixedAssetsCost) AS BusinessOperation,
	|	&Organization                                AS Organization,
	|	FATable.FixedAsset                  AS FixedAsset,
	|	InformationAboutAccounting.FixedAssetsLocation             AS Department,
	|	FATable.FinancialAccountingGroup            AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|	UNDEFINED                   AS Leaseholder,
	|
	|	0                                           AS Cost,
	|	0                                           AS LocalCost,
	|	0                                           AS CostInTaxAccounting,
	|	0                                           AS CostPermanentDifference,
	|	0                                           AS CostTemporaryDifference,
	|	0                                           AS CostTargetFinancing,
	|	0                                           AS CostTargetFinancingTA,
	|	0                                           AS CostTargetFinancingPD,
	|	0                                           AS CostTargetFinancingTD,
	|	0                                           AS DisregardedCostTA,
	|	0                                           AS DepreciationAllowance,
	|	0                                           AS SecurityDepositValue,
	|	0                                           AS PreliminaryCostMan,
	|	0                                           AS PreliminaryCostLocal,
	|	0                                           AS CostRevaluationReserve,
	|	0                                           AS CostRevaluationReserveLocal,
	|
	|	FACost.CostGainMA                AS CostGainMA,
	|	FACost.CostGainLocal            AS CostGainLocal,
	|
	|	UNDEFINED                                AS CorCompany,
	|	UNDEFINED                                AS DebitBusinessUnit,
	|	UNDEFINED                                AS CorLineOfBusiness,
	|	UNDEFINED                                AS CorFinancialAccountingGroup,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	
	|	FATable.RowID               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ChangeRevaluationReserveOfFixedAssetsCost) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS FATable
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = &Ref
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND FATable.FinancialAccountingGroup <> InformationAboutAccounting.FinancialAccountingGroup
	|	AND (FACost.CostGainMA <> 0 OR FACost.CostGainLocal <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	VendorInvoiceLeasedAssetsLocalization.AddRequestTextFACostTable(Query, QueryTexts, ListOfMergeRequests);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)           AS RecordType,
	|	&Ref                                          AS Recorder,
	|	&Period                                          AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetDepreciationParameterChange) AS BusinessOperation,
	|	&Organization                                     AS Organization,
	|	FATable.FixedAsset                       AS FixedAsset,
	|	InformationAboutAccounting.FixedAssetsLocation                  AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness          AS LineOfBusiness,
	|
	|	FixedAssetsDepreciationCharge.Depreciation                        AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal                    AS DepreciationLocal,
	|	0                                                AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences                      AS DepreciationPermanentDifferences,
	|
	|	FixedAssetsDepreciationCharge.DepreciationTD 
	|		+ FixedAssetsDepreciationCharge.DepreciationInTaxAccounting                AS DepreciationTD,
	|
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing                      AS FixedAssetDepreciationTargetFinancing,
	|	0                                                AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD                    AS DepreciationTargetFinancingPD,
	|
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD 
	|		+ FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing              AS DepreciationOfTargetFinancingTD,
	|
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve        AS DepreciationRevaluationReserve,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal    AS DepreciationRevaluationReserveLocal,
	|
	|	&Organization                                     AS CorCompany,
	|	InformationAboutAccounting.FixedAssetsLocation                  AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness          AS CorLineOfBusiness,
	|	FATable.FinancialAccountingGroup                 AS CorFinancialAccountingGroup,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation                     AS AccrueDepreciation,
	|	
	|	FATable.RowID                    AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetDepreciationParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS FATable
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|			AND FixedAssetsDepreciationCharge.Ref = &Ref
	|WHERE
	|	FATable.Ref = &Ref
	|	AND FATable.FinancialAccountingGroup <> InformationAboutAccounting.FinancialAccountingGroup
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)           AS RecordType,
	|	&Ref                                          AS Recorder,
	|	&Period                                          AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetDepreciationParameterChange) AS BusinessOperation,
	|	&Organization                                     AS Organization,
	|	FATable.FixedAsset                       AS FixedAsset,
	|	InformationAboutAccounting.FixedAssetsLocation                  AS Department,
	|	FATable.FinancialAccountingGroup                 AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness          AS LineOfBusiness,
	|
	|	FixedAssetsDepreciationCharge.Depreciation                        AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal                    AS DepreciationLocal,
	|	0                                                AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences                      AS DepreciationPermanentDifferences,
	|
	|	FixedAssetsDepreciationCharge.DepreciationTD 
	|		+ FixedAssetsDepreciationCharge.DepreciationInTaxAccounting                AS DepreciationTD,
	|
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing                      AS FixedAssetDepreciationTargetFinancing,
	|	0                                                AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD                    AS DepreciationTargetFinancingPD,
	|
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD 
	|		+ FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing              AS DepreciationOfTargetFinancingTD,
	|
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve        AS DepreciationRevaluationReserve,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal    AS DepreciationRevaluationReserveLocal,
	|
	|	&Organization                                     AS CorCompany,
	|	InformationAboutAccounting.FixedAssetsLocation                  AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness          AS CorLineOfBusiness,
	|	InformationAboutAccounting.FinancialAccountingGroup           AS CorFinancialAccountingGroup,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation                     AS AccrueDepreciation,
	|	
	|	FATable.RowID                    AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetDepreciationParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS FATable
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|			AND FixedAssetsDepreciationCharge.Ref = &Ref
	|WHERE
	|	FATable.Ref = &Ref
	|	AND FATable.FinancialAccountingGroup <> InformationAboutAccounting.FinancialAccountingGroup
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)           AS RecordType,
	|	&Ref                                          AS Recorder,
	|	&Period                                          AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetDepreciationWriteOff) AS BusinessOperation,
	|	&Organization                                     AS Organization,
	|	FATable.FixedAsset                       AS FixedAsset,
	|	InformationAboutAccounting.FixedAssetsLocation                  AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness          AS LineOfBusiness,
	|
	|	0                                                AS Depreciation,
	|	0                                                AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationInTaxAccounting                      AS DepreciationInTaxAccounting,
	|	0                                                AS DepreciationPermanentDifferences,
	|	-FixedAssetsDepreciationCharge.DepreciationInTaxAccounting                     AS DepreciationTD,
	|	0                                                AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing                    AS DepreciationTaxAccountingTargetFinancing,
	|	0                                                AS DepreciationTargetFinancingPD,
	|	-FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing                   AS DepreciationOfTargetFinancingTD,
	|
	|	0                                                AS DepreciationRevaluationReserve,
	|	0                                                AS DepreciationRevaluationReserveLocal,
	|
	|	UNDEFINED                                     AS CorCompany,
	|	UNDEFINED                                     AS DebitBusinessUnit,
	|	UNDEFINED                                     AS CorLineOfBusiness,
	|	UNDEFINED                                     AS CorFinancialAccountingGroup,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation                     AS AccrueDepreciation,
	|	
	|	FATable.RowID                    AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetDepreciationWriteOff) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS FATable
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|			AND FixedAssetsDepreciationCharge.Ref = &Ref
	|WHERE
	|	FATable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedure(Query, QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTUnitsDepreciationComponents(QueryTexts);

	QueryText =
	"SELECT
	|	&Period                                   AS Period,
	|	&Organization                              AS Organization,
	|	TRUE                                    AS RecordInLocalAccounting,
	|	TRUE                                    AS RecordInManAccounting,
	|	FATable.FixedAsset                AS FixedAsset,
	|
	|	FATable.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness    AS LineOfBusiness,
	|	FixedAssetsAccountingProcedure.RunningTimeValue        AS RunningTimeValue,
	|	FixedAssetsAccountingProcedure.EstimatedRunningTime             AS EstimatedRunningTime
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS FATable
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON (FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset)
	|WHERE
	|	FATable.Ref = &Ref
	|	AND FATable.FinancialAccountingGroup <> FixedAssetsAccountingProcedure.FinancialAccountingGroup";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query);

	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);
	QueryTextTableTTAccrualsTotal(QueryTexts);
	QueryTextTableTTChangeInLeaseLiabilities(QueryTexts);
	QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(QueryTexts);
	LeasedAssetAccounting.QueryTextTableTTCostsUponTerminationOfLease(Query, QueryTexts);
	LeasedAssetAccounting.QueryTextTableTTIncomeUponTerminationOfLease(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region ServiceWithoutVAT // Dt <76.07.1> - Ct <70.07.4>
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
	|	TTAccrualsTotal.AmountARAP - TTAccrualsTotal.AmountVATARAP AS Sum,
	|	TTAccrualsTotal.SumMan - TTAccrualsTotal.VATAmountMan              AS SumMan,
	|	TTAccrualsTotal.SumCompl - TTAccrualsTotal.VATAmountCompl            AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,	
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_VendorInvoiceLeasedAssets                                                 AS BusinessOperation,
	|	&SettingUpHO_BuyoutOfLeasedFA                                        AS BusinessTransactionSetting
	|FROM
	|	TTAccrualsTotal AS TTAccrualsTotal
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.BuyoutValue)           AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	TTAccrualsTotal.AmountARAP - TTAccrualsTotal.AmountVATARAP AS Sum,
	|	TTAccrualsTotal.SumMan - TTAccrualsTotal.VATAmountMan              AS SumMan,
	|	TTAccrualsTotal.SumCompl - TTAccrualsTotal.VATAmountCompl            AS SumCompl,
	|	
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)    AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,	
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_VendorInvoiceLeasedAssets                                                 AS BusinessOperation,
	|	&SettingUpHO_BuyoutOfLeasedFA                                        AS BusinessTransactionSetting
	|FROM
	|	TTAccrualsTotal AS TTAccrualsTotal
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region VATService // Dt <76.07.1> - Ct <76.07.9>
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
	|	TTAccrualsTotal.AmountVATARAP                                AS Sum,
	|	TTAccrualsTotal.VATAmountMan                                           AS SumMan,
	|	TTAccrualsTotal.VATAmountCompl                                          AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,	
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_AccrualOfVATInPartOfBuyoutValue                                AS BusinessOperation,
	|	&SettingUpHO_AccrualOfNdsvPartOfRedemptionValue                       AS BusinessTransactionSetting
	|FROM
	|	TTAccrualsTotal AS TTAccrualsTotal
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|WHERE
	|	NOT &EarlyPartialRedemption
	|	AND (TTAccrualsTotal.AmountVATARAP <> 0
	|		OR TTAccrualsTotal.VATAmountMan <> 0
	|		OR TTAccrualsTotal.VATAmountCompl <> 0)
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
	|	TTAccrualsTotal.AmountVATARAP                                AS Sum,
	|	TTAccrualsTotal.VATAmountMan                                           AS SumMan,
	|	TTAccrualsTotal.VATAmountCompl                                          AS SumCompl,
	|	
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)    AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,	
	|	&DocumentID                                                 AS FinRecordID,
	|	&BO_AccrualOfVATInPartOfBuyoutValue                                AS BusinessOperation,
	|	&SettingUpHO_AccrualOfNdsvPartOfRedemptionValue                       AS BusinessTransactionSetting
	|FROM
	|	TTAccrualsTotal AS TTAccrualsTotal
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|WHERE
	|	NOT &EarlyPartialRedemption
	|	AND (TTAccrualsTotal.AmountVATARAP <> 0
	|		OR TTAccrualsTotal.VATAmountMan <> 0
	|		OR TTAccrualsTotal.VATAmountCompl <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region VATService // Dt <19.XX> - Ct <70.07.4>
	QueryText =
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|
	|	VALUE(Enum.TypesOfLeasePayments.BuyoutValue)           AS AmountType,
	|
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	SumTable.AmountVATARAP                                     AS Sum,
	|	SumTable.VATAmountMan                                                AS SumMan,
	|	SumTable.VATAmountCompl                                               AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,	
	|	AccrualTable.RowID                                   AS FinRecordID,
	|	&BO_ReceiptOfVATInPartOfBuyoutValue                               AS BusinessOperation,
	|	&SetupHO_ReceiptOfNDSVPartOfRedemptionValue                      AS BusinessTransactionSetting	
	|
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS AccrualTable
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
	|		ON SumTable.RowID = AccrualTable.RowID
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|WHERE
	|	AccrualTable.Ref = &Ref
	|
	|	AND (SumTable.AmountVATARAP <> 0
	|		OR SumTable.VATAmountMan <> 0
	|		OR SumTable.VATAmountCompl <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region PrepaymentsSettlement // Dt <70.07.4> - Ct <70.07.2, 70.07.3, 70.07.4>
	QueryText = 
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.BuyoutValue)           AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	AccrualTable.AmountARAP                                   AS Sum,
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN AccrualTable.AmountARAP
	|		ELSE CAST(AccrualTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN AccrualTable.AmountARAP
	|		ELSE CAST(AccrualTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,	
	|	AccrualTable.RowID                                   AS FinRecordID,
	|
	|	CASE AccrualTable.PaymentType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &BO_OffsettingLeaseServicePaymentsAgainstBuyoutPayables
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &BO_OffsettingLeaseServicePaymentsAgainstBuyoutPayables
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &BO_SettlementOfDepositPaymentAgainstBuyoutValue
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
	|			THEN &BO_SettlementOfPrepaymentForLeaseAssetBuyout
	|	END AS BusinessOperation,
	|
	|	CASE AccrualTable.PaymentType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &SetupHO_OffsetPaymentForRentalServicesAtExpenseOfPurchasePrice
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &SetupHO_OffsetPaymentForRentalServicesAtExpenseOfPurchasePrice
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &SettingUpHO_SETTINGSecurityPaymentAgainstPurchasePrice
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
	|			THEN &SettingUpHO_OffsettingAdvanceOfRedemptionValueAgainstRedemptionValue
	|	END AS BusinessTransactionSetting	
	|FROM
	|	Document.VendorInvoiceLeasedAssets.PrepaymentsSettlement AS AccrualTable
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	AccrualTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	AccrualTable.PaymentType                                            AS AmountType,
	|	AccrualTable.ARAPDocument                                     AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	AccrualTable.AmountARAP                                   AS Sum,
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN AccrualTable.AmountARAP
	|		ELSE CAST(AccrualTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN AccrualTable.AmountARAP
	|		ELSE CAST(AccrualTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,	
	|	AccrualTable.RowID                                   AS FinRecordID,
	|
	|	CASE AccrualTable.PaymentType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &BO_OffsettingLeaseServicePaymentsAgainstBuyoutPayables
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &BO_OffsettingLeaseServicePaymentsAgainstBuyoutPayables
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &BO_SettlementOfDepositPaymentAgainstBuyoutValue
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
	|			THEN &BO_SettlementOfPrepaymentForLeaseAssetBuyout
	|	END AS BusinessOperation,
	|
	|	CASE AccrualTable.PaymentType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &SetupHO_OffsetPaymentForRentalServicesAtExpenseOfPurchasePrice
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &SetupHO_OffsetPaymentForRentalServicesAtExpenseOfPurchasePrice
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &SettingUpHO_SETTINGSecurityPaymentAgainstPurchasePrice
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
	|			THEN &SettingUpHO_OffsettingAdvanceOfRedemptionValueAgainstRedemptionValue
	|	END AS BusinessTransactionSetting	
	|FROM
	|	Document.VendorInvoiceLeasedAssets.PrepaymentsSettlement AS AccrualTable
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	AccrualTable.Ref = &Ref";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region WriteOffOfLeaseInterest // Dt <76.07.1> - Ct <70.07.5>
	QueryText =
	"SELECT
	|	&Period                                             AS Period,
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	
	|	CalculationsBalance.AccountingDimensionByPartners            AS AccountingDimensionByPartners,
	|	&Contract                                            AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations) AS AmountType,
	|	UNDEFINED                                        AS ARAPDocument,
	|	CalculationsBalance.Currency                               AS Currency,
	|	
	|	CalculationsBalance.Sum                                AS Sum,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN CalculationsBalance.SumMan
	|		ELSE CalculationsBalance.Sum * &ConversionRateToManCurrency
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN CalculationsBalance.SumCompl
	|		ELSE CalculationsBalance.Sum * &FactorOfConversionToCurrencyOfRegul
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                        AS ScheduleType,
	|	UNDEFINED                                        AS DimensionItem,
	|	UNDEFINED                                        AS RowID,	
	|	&DocumentID                             AS FinRecordID,
	|
	|	&BO_WriteOffOfLeaseInterest                       AS BusinessOperation,
	|	&SettingUpHO_WriteOffRentalInterest              AS BusinessTransactionSetting
	|FROM
	|	TT_FinancialInstrumentsARAP AS CalculationsBalance
	|WHERE
	|	NOT &EarlyPartialRedemption AND
	|	CalculationsBalance.Ref = &Ref
	|	AND CalculationsBalance.Contract = &Contract
	|	AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|
	|	AND (CalculationsBalance.Sum <> 0
	|		OR CASE
	|				WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|					THEN CalculationsBalance.SumMan
	|				ELSE CalculationsBalance.Sum * &ConversionRateToManCurrency
	|			END <> 0
	|
	|		OR CASE
	|				WHEN &ARAPCurrency = &LocalAccountingCurrency
	|					THEN CalculationsBalance.SumCompl
	|				ELSE CalculationsBalance.Sum * &FactorOfConversionToCurrencyOfRegul
	|			END <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                             AS Period,
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	
	|	CalculationsBalance.AccountingDimensionByPartners            AS AccountingDimensionByPartners,
	|	&Contract                                            AS Contract,
	|	CalculationsBalance.AmountType                             AS AmountType,
	|	CalculationsBalance.ARAPDocument                    AS ARAPDocument,
	|	CalculationsBalance.Currency                               AS Currency,
	|	
	|	CalculationsBalance.Sum                                AS Sum,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN CalculationsBalance.SumMan
	|		ELSE CalculationsBalance.Sum * &ConversionRateToManCurrency
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN CalculationsBalance.SumCompl
	|		ELSE CalculationsBalance.Sum * &FactorOfConversionToCurrencyOfRegul
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                        AS ScheduleType,
	|	UNDEFINED                                        AS DimensionItem,
	|	UNDEFINED                                        AS RowID,	
	|	&DocumentID                             AS FinRecordID,
	|
	|	&BO_WriteOffOfLeaseInterest                       AS BusinessOperation,
	|	&SettingUpHO_WriteOffRentalInterest              AS BusinessTransactionSetting
	|FROM
	|	TT_FinancialInstrumentsARAP AS CalculationsBalance
	|WHERE
	|	NOT &EarlyPartialRedemption AND
	|	CalculationsBalance.Ref = &Ref
	|	AND CalculationsBalance.Contract = &Contract
	|	AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|
	|	AND (CalculationsBalance.Sum <> 0
	|		OR CASE
	|				WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|					THEN CalculationsBalance.SumMan
	|				ELSE CalculationsBalance.Sum * &ConversionRateToManCurrency
	|			END <> 0
	|
	|		OR CASE
	|				WHEN &ARAPCurrency = &LocalAccountingCurrency
	|					THEN CalculationsBalance.SumCompl
	|				ELSE CalculationsBalance.Sum * &FactorOfConversionToCurrencyOfRegul
	|			END <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region VATWriteOffOnLease // Dt <76.07.1> - Ct <76.07.9>
	QueryText =
	"SELECT
	|	&Period                                             AS Period,
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	
	|	CalculationsBalance.AccountingDimensionByPartners            AS AccountingDimensionByPartners,
	|	&Contract                                            AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations) AS AmountType,
	|	UNDEFINED                                        AS ARAPDocument,
	|	CalculationsBalance.Currency                               AS Currency,
	|	
	|	CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP AS Sum,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN CalculationsBalance.SumMan - TTAccrualsTotal.VATAmountMan
	|		ELSE (CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) * &ConversionRateToManCurrency
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN CalculationsBalance.SumCompl - TTAccrualsTotal.VATAmountCompl
	|		ELSE (CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) * &FactorOfConversionToCurrencyOfRegul
	|	END AS SumCompl,
	|
	|	UNDEFINED                                        AS ScheduleType,
	|	UNDEFINED                                        AS DimensionItem,
	|	UNDEFINED                                        AS RowID,	
	|	&DocumentID                             AS FinRecordID,
	|
	|	&BO_VATWriteOffOnLease                             AS BusinessOperation,
	|	&SettingsHO_DeductionOfVATForRent                    AS BusinessTransactionSetting
	|FROM
	|	TT_FinancialInstrumentsARAP AS CalculationsBalance
	|
	|		INNER JOIN TTAccrualsTotal AS TTAccrualsTotal
	|		ON TRUE
	|
	|WHERE
	|	NOT &EarlyPartialRedemption 
	|	AND CalculationsBalance.Ref = &Ref
	|	AND CalculationsBalance.Contract = &Contract
	|	AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|
	|	AND ((CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) <> 0
	|
	|		OR CASE
	|				WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|					THEN CalculationsBalance.SumMan - TTAccrualsTotal.VATAmountMan
	|				ELSE (CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) * &ConversionRateToManCurrency
	|			END <> 0
	|
	|		OR CASE
	|				WHEN &ARAPCurrency = &LocalAccountingCurrency
	|					THEN CalculationsBalance.SumCompl - TTAccrualsTotal.VATAmountCompl
	|				ELSE (CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) * &FactorOfConversionToCurrencyOfRegul
	|			END <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                             AS Period,
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	
	|	CalculationsBalance.AccountingDimensionByPartners            AS AccountingDimensionByPartners,
	|	&Contract                                            AS Contract,
	|	CalculationsBalance.AmountType                             AS AmountType,
	|	CalculationsBalance.ARAPDocument                    AS ARAPDocument,
	|	CalculationsBalance.Currency                               AS Currency,
	|	
	|	CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP  AS Sum,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN CalculationsBalance.SumMan - TTAccrualsTotal.VATAmountMan
	|		ELSE (CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) * &ConversionRateToManCurrency
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN CalculationsBalance.SumCompl - TTAccrualsTotal.VATAmountCompl
	|		ELSE (CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) * &FactorOfConversionToCurrencyOfRegul
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                        AS ScheduleType,
	|	UNDEFINED                                        AS DimensionItem,
	|	UNDEFINED                                        AS RowID,	
	|	&DocumentID                             AS FinRecordID,
	|
	|	&BO_VATWriteOffOnLease                             AS BusinessOperation,
	|	&SettingsHO_DeductionOfVATForRent                    AS BusinessTransactionSetting
	|FROM
	|	TT_FinancialInstrumentsARAP AS CalculationsBalance
	|
	|		INNER JOIN TTAccrualsTotal AS TTAccrualsTotal
	|		ON TRUE
	|WHERE
	|	NOT &EarlyPartialRedemption 
	|	AND CalculationsBalance.Ref = &Ref
	|	AND CalculationsBalance.Contract = &Contract
	|	AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|
	|	AND ((CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) <> 0
	|
	|		OR CASE
	|				WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|					THEN CalculationsBalance.SumMan - TTAccrualsTotal.VATAmountMan
	|				ELSE (CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) * &ConversionRateToManCurrency
	|			END <> 0
	|
	|		OR CASE
	|				WHEN &ARAPCurrency = &LocalAccountingCurrency
	|					THEN CalculationsBalance.SumCompl - TTAccrualsTotal.VATAmountCompl
	|				ELSE (CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) * &FactorOfConversionToCurrencyOfRegul
	|			END <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region RecordingLeaseLiabilitiesInExpenses // Dt <Expenses> - Ct <76.07.1>
	QueryText =
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	TableExpenses.AccountingDimensionByPartners                                AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)       AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	TableExpenses.Sum                                                    AS Sum,
	|	TableExpenses.SumMan                                                 AS SumMan,
	|	TableExpenses.SumCompl                                                AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,	
	|	TableExpenses.FinRecordID                                   AS FinRecordID,
	|	TableExpenses.BusinessOperation                                    AS BusinessOperation,
	|	TableExpenses.BusinessTransactionSetting                           AS BusinessTransactionSetting
	|FROM
	|	TTCostsUponTerminationOfLease AS TableExpenses";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region RecordingLeaseLiabilitiesInIncome // Dt <76.07.1> - Ct <Income>
	QueryText =
	"SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	TableRevenue.AccountingDimensionByPartners                                 AS AccountingDimensionByPartners,
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
	|	TTIncomeUponTerminationOfLease AS TableRevenue
	|WHERE NOT &EarlyPartialRedemption";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	VendorInvoiceLeasedAssetsLocalization.AddRequestTextTableSettlementsOnFinancialInstruments(ListOfMergeRequests);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure RequestTextTableOfVATReflection(Query, QueryTexts, Registers)
	
	QueryTextTableTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	
	ValueText_ =
	"SELECT
	|	Accruals.Ref.Date AS Period,
	|	Accruals.Ref AS Ref,
	|	Accruals.Ref.Organization AS Organization,
	|	Accruals.Ref.Department AS Department,
	|	Accruals.Ref.Counterparty AS Counterparty,
	|	Accruals.Ref.Contract AS Contract,
	|	UNDEFINED AS Shipper,
	|	Accruals.Ref AS DocumentAcquisitions,
	|	Accruals.Ref AS OriginalTradeDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS ReduceAmountVATDeduction,
	|	UNDEFINED AS PurchaseAdjustmentDocument,
	|	Accruals.Ref.VATTaxation AS VATTaxation,
	|	Accruals.Ref.PurchaseForActivity AS VATActivityType,
	|	Accruals.VATRate AS VATRate,
	|	UNDEFINED AS Products,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|	UNDEFINED AS CCDNumber,
	|	Accruals.Ref.Department AS AccountingDivision,
	|	Accruals.Ref.Contract.LineOfBusiness AS LineOfBusiness,
	|	FALSE AS PurchasePerBatchOfProduction,
	|	UNDEFINED AS LineOfBusinessOfProductionParty,
	|	UNDEFINED AS ToExpenseAs,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS ItemOfOtherAssets,
	|	UNDEFINED AS AnalyticsOfOtherAssets,
	|	UNDEFINED AS Purpose,
	|	Accruals.RowID AS RowID,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	Accruals.RowID AS FinRecordID,
	|	&SetupHO_ReceiptOfNDSVPartOfRedemptionValue AS BusinessTransactionSetting
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS Accruals
	|		LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber = Accruals.LineNumber
	|WHERE
	|	Accruals.Ref = &Ref";
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers) Export
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)

	RegisterName = "OtherIncome";
	
	LeasedAssetAccounting.QueryTextTableTTIncomeUponTerminationOfLease(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	QueryText =
	"SELECT
	|	&Period                                        AS Period,
	|	&Organization                                   AS Organization,
	|	&Department                                 AS Department,
	|	&LineOfBusiness                       AS LineOfBusiness,
	|	&IncomeItemBuyout                            AS IncomeItem,
	|	&IncomeDimensionInCaseOfEarlyRedemption                         AS DimensionOfRevenue,
	|
	|	TableRevenue.SumMan                         AS Sum,
	|	TableRevenue.SumMan                         AS SumMan,
	|	TableRevenue.SumCompl                        AS SumCompl,
	|	0                                              AS PermanentDifference,
	|	TableRevenue.SumCompl                        AS CostTD,
	|
	|	TableRevenue.FinRecordID           AS FinRecordID,
	|	TableRevenue.BusinessOperation            AS BusinessOperation,
	|	TableRevenue.BusinessTransactionSetting   AS BusinessTransactionSetting
	|	
	|FROM
	|	TTIncomeUponTerminationOfLease AS TableRevenue
	|WHERE
	|	NOT &EarlyPartialRedemption";
	ListOfMergeRequests.Add(QueryText);
	
	VendorInvoiceLeasedAssetsLocalization.AddQueryTextToOtherIncomeTable(QueryTexts, ListOfMergeRequests);

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Procedure QueryTextTableLeasedAsset(QueryTexts, Registers)

	RegisterName = "LeasedAsset";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTUnitsDepreciationComponents(QueryTexts);
	
	QueryText =
	"SELECT
	|	&Ref                       AS Recorder,
	|	&Period                       AS Period,
	|	FATable.FixedAsset    AS FixedAsset,
	|	&Organization                  AS Organization,
	|	&Partner                      AS Partner,
	|	&Counterparty                   AS Counterparty,
	|	&Contract                      AS Contract,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks) AS State
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref                       AS Recorder,
	|	&Period                       AS Period,
	|	NodesComponents.SubAssetComponent  AS FixedAsset,
	|	&Organization                  AS Organization,
	|	&Partner                      AS Partner,
	|	&Counterparty                   AS Counterparty,
	|	&Contract                      AS Contract,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks) AS State
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS FATable
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS NodesComponents
	|		ON FATable.FixedAsset = NodesComponents.FixedAsset
	|
	|WHERE
	|	FATable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
		
EndProcedure

Procedure QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers)

	RegisterName = "TermsOfLeaseContracts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTTermsOfLeaseAgreements(QueryTexts);
	
	QueryText =
	"SELECT
	|	&Ref                                                      AS Recorder,
	|	&Period                                                      AS Period,
	|	&Contract                                                     AS Contract,
	|	TermsOfLeaseContracts.SecurityDepositAmount          AS SecurityDepositAmount,
	|	TermsOfLeaseContracts.LeaseServicesAmount                    AS LeaseServicesAmount,
	|	TermsOfLeaseContracts.AmountOfLeaseAssetsByuout            AS AmountOfLeaseAssetsByuout,
	|	TermsOfLeaseContracts.InterestAmount                        AS InterestAmount,
	|	TermsOfLeaseContracts.VATAmount                              AS VATAmount,
	|	TermsOfLeaseContracts.VATRate                             AS VATRate,
	|	TermsOfLeaseContracts.TermYears                               AS TermYears,
	|	TermsOfLeaseContracts.TermMonths                               AS TermMonths,
	|	TermsOfLeaseContracts.TermDays                              AS TermDays,
	|	TermsOfLeaseContracts.LeaseStartDate                      AS LeaseStartDate,
	|	TermsOfLeaseContracts.DateOfFirstPayment                    AS DateOfFirstPayment,
	|	TermsOfLeaseContracts.DateOfFirstSecurityPayment    AS DateOfFirstSecurityPayment,
	|	TermsOfLeaseContracts.BuyoutDate                            AS BuyoutDate,
	|	TermsOfLeaseContracts.InterestRate                      AS InterestRate,
	|	TermsOfLeaseContracts.PaymentFrequency                    AS PaymentFrequency,
	|	TermsOfLeaseContracts.AccrualFrequency               AS AccrualFrequency,
	|	TermsOfLeaseContracts.LeaseItemsCost              AS LeaseItemsCost,
	|	TermsOfLeaseContracts.PaymentForLeaseService                  AS PaymentForLeaseService,
	|	TermsOfLeaseContracts.AccrualOfLeaseService              AS AccrualOfLeaseService,
	|	TermsOfLeaseContracts.EffectiveContractTerms             AS EffectiveContractTerms,
	|	VALUE(Enum.CounterpartyContractStates.Closed) AS State
	|FROM
	|	TTTermsOfLeaseAgreements AS TermsOfLeaseContracts
	|WHERE
	|	NOT &EarlyPartialRedemption";
	
	QueryTexts.Add(QueryText, RegisterName);
		
EndProcedure

Procedure QueryTextTableGoodsForRegistrationOfImportDocuments(QueryTexts, Registers)
	
	RegisterName = "GoodsForRegistrationOfImportDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	ENDOFPERIOD(GoodsForRegistrationOfImportDocumentsBalanceAndTurnovers.Period, MONTH) AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Ref AS Recorder,
	|	&Organization AS Organization,
	|	&Partner AS Vendor,
	|	GoodsForRegistrationOfImportDocumentsBalanceAndTurnovers.DocumentInflow AS DocumentInflow,
	|	GoodsForRegistrationOfImportDocumentsBalanceAndTurnovers.ImportDocumentType AS ImportDocumentType,
	|	0 AS Count,
	|	GoodsForRegistrationOfImportDocumentsBalanceAndTurnovers.SumTurnover AS Sum
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.BalanceAndTurnovers(
	|			,
	|			,
	|			Month,
	|			,
	|			DocumentInflow = &DocumentOfConclusionOfContractOfLease
	|				AND ImportDocumentType = &IdApplicationForImportOfGoods) AS GoodsForRegistrationOfImportDocumentsBalanceAndTurnovers
	|WHERE
	|	&RegisterImportApplications
	|	AND GoodsForRegistrationOfImportDocumentsBalanceAndTurnovers.SumTurnover > 0
	|	AND ENDOFPERIOD(GoodsForRegistrationOfImportDocumentsBalanceAndTurnovers.Period, MONTH) > ENDOFPERIOD(&Period, MONTH)"; 
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

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

#Region FormationOfTemporaryTablesForConducting

Procedure QueryTextTableTTAccrualsTotal(QueryTexts)
	
	TableName = "TTAccrualsTotal";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryText =
	"SELECT
	|	SUM(Accruals.AmountARAP) AS AmountARAP,
	|	SUM(Accruals.AmountVATARAP) AS AmountVATARAP,
	|
	|	SUM(CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN Accruals.AmountARAP
	|		ELSE CAST(Accruals.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END) AS SumCompl,
	|
	|	SUM(CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Accruals.AmountARAP
	|		ELSE CAST(Accruals.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END) AS SumMan,
	|
	|	SUM(CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN Accruals.AmountVATARAP
	|		ELSE CAST(Accruals.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END) AS VATAmountCompl,
	|
	|	SUM(CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Accruals.AmountVATARAP
	|		ELSE CAST(Accruals.AmountVATARAP * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END) AS VATAmountMan
	|
	|INTO TTAccrualsTotal
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS Accruals
	|WHERE
	|	Accruals.Ref = &Ref";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTChangeInLeaseLiabilities(QueryTexts)
	
	TableName = "TTChangeInLeaseLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAccrualsTotal(QueryTexts);
	
	QueryText =
	"SELECT
	|	SUM(Table.Sum) AS Sum,
	|	SUM(Table.SumCompl) AS SumCompl,
	|	SUM(Table.SumMan) AS SumMan
	|INTO TTChangeInLeaseLiabilities
	|FROM
	|	(SELECT
	|		TTAccrualsTotal.AmountARAP   AS Sum,
	|		TTAccrualsTotal.SumMan              AS SumMan,
	|		TTAccrualsTotal.SumCompl             AS SumCompl
	|	FROM
	|		TTAccrualsTotal AS TTAccrualsTotal
	|
	|	UNION ALL
	|
	|	SELECT
	|		CalculationsBalance.Sum                    AS Sum,
	|		CalculationsBalance.SumMan                 AS SumMan,
	|		CalculationsBalance.SumCompl                AS SumCompl
	|	FROM
	|		TT_FinancialInstrumentsARAP AS CalculationsBalance
	|	WHERE
	|		CalculationsBalance.Ref = &Ref
	|		AND CalculationsBalance.Contract = &Contract
	|		AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|		AND (CalculationsBalance.Sum <> 0
	|			OR CalculationsBalance.SumMan <> 0
	|			OR CalculationsBalance.SumCompl <> 0)
	|
	|	UNION ALL
	|
	|	SELECT
	|		CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP  AS Sum,
	|		CalculationsBalance.SumMan - TTAccrualsTotal.VATAmountMan          AS SumMan,
	|		CalculationsBalance.SumCompl - TTAccrualsTotal.VATAmountCompl        AS SumCompl
	|	FROM
	|		TT_FinancialInstrumentsARAP AS CalculationsBalance
	|
	|			INNER JOIN TTAccrualsTotal AS TTAccrualsTotal
	|			ON TRUE
	|
	|	WHERE
	|		CalculationsBalance.Ref = &Ref
	|		AND CalculationsBalance.Contract = &Contract
	|		AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|		AND ((CalculationsBalance.Sum - TTAccrualsTotal.AmountVATARAP) <> 0
	|			OR (CalculationsBalance.SumMan - TTAccrualsTotal.VATAmountMan) <> 0
	|			OR (CalculationsBalance.SumCompl - TTAccrualsTotal.VATAmountCompl) <> 0)
	|
	|	) AS Table";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Function QueryTextTableTTTableOfPartyAccountingAnalysts(Query, QueryTexts) Export
	
	If DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		Return "";
	EndIf; 
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""FA"" 							        AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	UNDEFINED							AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	DocumentData.PurchaseForActivity  AS VATTaxation,
	|	VALUE(Enum.AssetKinds.OtherWorksAndServices) AS AssetTaxClass,
	|	0										AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS DocumentTable
	|	INNER JOIN Document.VendorInvoiceLeasedAssets AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|// Table TTTableOfPartyAccountingAnalysts
	|" + QueryText;
	
	QueryTexts[QueryTexts.Count() - 1].Value = QueryText;
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTAdvanceData(QueryTexts)
	
	TableName = "TTAdvanceData";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	&ARAPCurrency AS ARAPCurrency,
	|	AdvanceData.AmountARAP AS AmountARAP,
	|	CASE
	|		WHEN AdvanceData.ARAPDocument REFS Document.BankAccountIssue
	|			THEN CAST(AdvanceData.ARAPDocument AS Document.BankAccountIssue).Date
	|		WHEN AdvanceData.ARAPDocument REFS Document.CashVoucher
	|			THEN CAST(AdvanceData.ARAPDocument AS Document.CashVoucher).Date
	|		WHEN AdvanceData.ARAPDocument REFS Document.SourceDocument
	|			THEN CAST(AdvanceData.ARAPDocument AS Document.SourceDocument).Date
	|	END AS Date
	|INTO TTAdvanceData
	|FROM
	|	Document.VendorInvoiceLeasedAssets.PrepaymentsSettlement AS AdvanceData
	|WHERE
	|	AdvanceData.Ref = &Ref
	|
	|INDEX BY
	|	Date";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTCurrencyConversionFactors(QueryTexts)

	TableName = "TTCurrencyConversionFactors";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAdvanceData(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DatesOfDocuments.ARAPCurrency AS ARAPCurrency,
	|	DatesOfDocuments.Date AS Date
	|INTO PeriodsTable
	|FROM
	|	(SELECT
	|		DocumentData.ARAPCurrency AS ARAPCurrency,
	|		DocumentData.Date AS Date
	|	FROM
	|		Document.VendorInvoiceLeasedAssets AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AdvanceData.ARAPCurrency,
	|		AdvanceData.Date
	|	FROM
	|		TTAdvanceData AS AdvanceData) AS DatesOfDocuments
	|
	|GROUP BY
	|	DatesOfDocuments.ARAPCurrency,
	|	DatesOfDocuments.Date
	|
	|INDEX BY
	|	ARAPCurrency,
	|	Date";
	QueryTexts.Add(QueryText, "PeriodsTable");
	
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts, TableName);

EndProcedure

Procedure QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(QueryTexts) Export
	
	TableName = "TTAmountsOfDocumentsInAccountingCurrencies";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	// For foreign currency lease Contracts, VAT is calculated as follows:
	//    Advances are calculated at the exchange rate on the date of the advance. We get the base for calculating VAT on advances, 
	//    this amount is deducted from the redemption value at the exchange rate on the date of redemption - we get the base for calculating VAT 
	//    on the Balance of the redemption value.
	//    Both bases are summed up and VAT is calculated at the rate.
	// For lease Contracts in the U.S., VAT is calculated as follows:
	//    Advances are calculated at the exchange rate on the date of the advance, we sum it up with the amount of advances at the exchange rate on the date of redemption, divide it in half -
	//    we get the base for calculating VAT on advances, 
	//    this amount is deducted from the redemption value at the exchange rate on the date of redemption - we get the base for calculating VAT 
	//    on the Balance of the redemption value.
	//    Both bases are summed up and VAT is calculated at the rate.
	// We are forming the final VTSUM of the accounting documents.

	QueryTextTableTTAdvanceData(QueryTexts);
	QueryTextTableTTCurrencyConversionFactors(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DataFA.RowID AS RowID,
	|	DataFA.AmountARAP AS AmountARAP,
	|	DataFA.AmountVATARAP AS AmountVATARAP,
	|	DataFA.VATRate AS VATRate,
	|	CAST(DataFA.VATRate AS Catalog.VATRates).Rate1 AS VATRateValue
	|INTO DataFA
	|FROM
	|	Document.VendorInvoiceLeasedAssets.FA AS DataFA
	|WHERE
	|	DataFA.Ref = &Ref
	|
	|INDEX BY
	|	RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(DataFA.AmountARAP) AS AmountARAP
	|INTO FADataInTotal
	|FROM
	|	DataFA AS DataFA
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataFA.RowID AS RowID,
	|	AdvanceData.Date AS Date,
	|	CASE
	|		WHEN FADataInTotal.AmountARAP <> 0
	|			THEN CAST(AdvanceData.AmountARAP * DataFA.AmountARAP / FADataInTotal.AmountARAP AS NUMBER(31, 2))
	|		ELSE 0
	|	END AS AmountARAP,
	|	CASE
	|		WHEN FADataInTotal.AmountARAP <> 0
	|			THEN CAST(AdvanceData.AmountARAP * DataFA.AmountARAP / FADataInTotal.AmountARAP
	|				* DataFA.VATRateValue / (DataFA.VATRateValue + 100) AS NUMBER(31, 2))
	|		ELSE 0
	|	END AS AmountVATARAP
	|INTO FAAdvances
	|FROM
	|	DataFA AS DataFA
	|		LEFT JOIN TTAdvanceData AS AdvanceData
	|		ON (TRUE)
	|		LEFT JOIN FADataInTotal AS FADataInTotal
	|		ON (TRUE)
	|WHERE
	|	NOT AdvanceData.AmountARAP IS NULL
	|
	|INDEX BY
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FAAdvances.RowID AS RowID,
	|	SUM(FAAdvances.AmountARAP) AS AmountARAP,
	|	SUM(FAAdvances.AmountVATARAP) AS AmountVATARAP
	|INTO FAAdvancesInTotal
	|FROM
	|	FAAdvances AS FAAdvances
	|
	|GROUP BY
	|	FAAdvances.RowID
	|
	|INDEX BY
	|	RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataFA.RowID AS RowID,
	|	CASE
	|		WHEN DataFA.AmountARAP - ISNULL(FAAdvancesInTotal.AmountARAP, 0) > 0
	|			THEN DataFA.AmountARAP - ISNULL(FAAdvancesInTotal.AmountARAP, 0)
	|		ELSE 0
	|	END AS Sum,
	|	CASE
	|		WHEN DataFA.AmountVATARAP - ISNULL(FAAdvancesInTotal.AmountVATARAP, 0) > 0
	|			THEN DataFA.AmountVATARAP - ISNULL(FAAdvancesInTotal.AmountVATARAP, 0)
	|		ELSE 0
	|	END AS VATAmount
	|INTO BalancesOfSettlements
	|FROM
	|	DataFA AS DataFA
	|		LEFT JOIN FAAdvancesInTotal AS FAAdvancesInTotal
	|		ON DataFA.RowID = FAAdvancesInTotal.RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.RowID AS RowID,
	|	SUM(NestedQuery.AmountARAP) AS AmountARAP,
	|	SUM(NestedQuery.AmountVATARAP) AS AmountVATARAP,
	|	SUM(NestedQuery.SumCompl) AS SumCompl,
	|	SUM(NestedQuery.VATAmountCompl) AS VATAmountCompl,
	|	SUM(NestedQuery.SumMan) AS SumMan,
	|	SUM(NestedQuery.VATAmountMan) AS VATAmountMan
	|INTO PaymentData
	|FROM
	|	(SELECT
	|		FAAdvances.RowID AS RowID,
	|		FAAdvances.AmountARAP AS AmountARAP,
	|		FAAdvances.AmountVATARAP AS AmountVATARAP,
	|		CASE
	|			WHEN &CurrencyContract
	|				THEN FAAdvances.AmountARAP * ISNULL(ExchangeRates.LocalConversionRatio, 0)
	|			ELSE CAST((FAAdvances.AmountARAP * ISNULL(ExchangeRates.LocalConversionRatio, 0)
	|					+ FAAdvances.AmountARAP * ISNULL(RatesAsOfRedemptionDate.LocalConversionRatio, 0)) / 2 AS NUMBER(31, 2))
	|		END AS SumCompl,
	|		CASE
	|			WHEN &CurrencyContract
	|				THEN FAAdvances.AmountVATARAP * ISNULL(ExchangeRates.LocalConversionRatio, 0)
	|			ELSE CAST((FAAdvances.AmountVATARAP * ISNULL(ExchangeRates.LocalConversionRatio, 0)
	|					+ FAAdvances.AmountVATARAP * ISNULL(RatesAsOfRedemptionDate.LocalConversionRatio, 0)) / 2 AS NUMBER(31, 2))
	|		END AS VATAmountCompl,
	|		CASE
	|			WHEN &CurrencyContract
	|				THEN FAAdvances.AmountARAP * ISNULL(ExchangeRates.ManConversionFactor, 0)
	|			ELSE CAST((FAAdvances.AmountARAP * ISNULL(ExchangeRates.ManConversionFactor, 0)
	|					+ FAAdvances.AmountARAP * ISNULL(RatesAsOfRedemptionDate.ManConversionFactor, 0)) / 2 AS NUMBER(31, 2))
	|		END AS SumMan,
	|		CASE
	|			WHEN &CurrencyContract
	|				THEN FAAdvances.AmountVATARAP * ISNULL(ExchangeRates.ManConversionFactor, 0)
	|			ELSE CAST((FAAdvances.AmountVATARAP * ISNULL(ExchangeRates.ManConversionFactor, 0)
	|					+ FAAdvances.AmountVATARAP * ISNULL(RatesAsOfRedemptionDate.ManConversionFactor, 0)) / 2 AS NUMBER(31, 2))
	|		END AS VATAmountMan
	|	FROM
	|		FAAdvances AS FAAdvances
	|			LEFT JOIN TTCurrencyConversionFactors AS ExchangeRates
	|			ON FAAdvances.Date = ExchangeRates.Date
	|			LEFT JOIN TTCurrencyConversionFactors AS RatesAsOfRedemptionDate
	|			ON (RatesAsOfRedemptionDate.Date = &Period)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesOfSettlements.RowID,
	|		BalancesOfSettlements.Sum,
	|		BalancesOfSettlements.VATAmount,
	|		BalancesOfSettlements.Sum * ISNULL(RatesAsOfRedemptionDate.LocalConversionRatio, 0),
	|		BalancesOfSettlements.VATAmount * ISNULL(RatesAsOfRedemptionDate.LocalConversionRatio, 0),
	|		BalancesOfSettlements.Sum * ISNULL(RatesAsOfRedemptionDate.ManConversionFactor, 0),
	|		BalancesOfSettlements.VATAmount * ISNULL(RatesAsOfRedemptionDate.ManConversionFactor, 0)
	|	FROM
	|		BalancesOfSettlements AS BalancesOfSettlements
	|			LEFT JOIN TTCurrencyConversionFactors AS RatesAsOfRedemptionDate
	|			ON (RatesAsOfRedemptionDate.Date = &Period)) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.RowID
	|
	|INDEX BY
	|	RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataFA.RowID AS RowID,
	|	&Ref AS Ref,
	|	&Period AS Period,
	|	&Currency AS Currency,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&Period AS VATBasePeriod,
	|	UNDEFINED AS ARAPObject,
	|	PaymentData.AmountARAP AS AmountIncludingVAT,
	|	PaymentData.AmountARAP - PaymentData.AmountVATARAP AS AmountExcludingVAT,
	|	PaymentData.AmountVATARAP AS VATAmount,
	|	DataFA.VATRate AS VATRate,
	|	PaymentData.SumCompl - PaymentData.VATAmountCompl AS AmountExcludingVATCompl,
	|	PaymentData.SumCompl - PaymentData.VATAmountCompl AS VATBaseLocal,
	|	PaymentData.VATAmountCompl AS VATAmountCompl,
	|	PaymentData.SumMan - PaymentData.VATAmountMan AS AmountExcludingVATMan,
	|	PaymentData.VATAmountMan AS VATAmountMan,
	|	PaymentData.AmountARAP AS AmountARAP,
	|	PaymentData.AmountARAP - PaymentData.AmountVATARAP AS AmountWithoutVATOfSettlements,
	|	PaymentData.AmountVATARAP AS AmountVATARAP
	|INTO TTAmountsOfDocumentsInAccountingCurrencies
	|FROM
	|	DataFA AS DataFA
	|		LEFT JOIN PaymentData AS PaymentData
	|		ON DataFA.RowID = PaymentData.RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DataFA
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FADataInTotal
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FAAdvances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FAAdvancesInTotal
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP BalancesOfSettlements
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP PaymentData";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	LeasedAssetAccounting.QueryTextTableTTCostsUponTerminationOfLease(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses());
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&ExpenseItemTaxBuyout AS ExpenseItem,
	|	&ExpensesDimensionInCaseOfEarlyBuyout AS DimensionOfExpenses,
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	
	|	TableExpenses.SumMan AS AmountIncludingVAT,
	|	TableExpenses.SumMan AS AmountExcludingVAT,
	|	TableExpenses.SumMan AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVATCompl,
	|	TableExpenses.SumCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	TableExpenses.SumCompl AS CostTD,
	|	
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TableExpenses.FinRecordID AS FinRecordID,
	|	TableExpenses.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTCostsUponTerminationOfLease AS TableExpenses";
	ListOfMergeRequests.Add(QueryText);
	
	VendorInvoiceLeasedAssetsLocalization.AddRequestTextTableTTInitialOtherExpenses(Query, QueryTexts, ListOfMergeRequests);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	LeasedAssetAccounting.QueryTextTableTTCostsUponTerminationOfLease(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.ItemisedExpensesLots.TextDescriptionTTInitialBatchesOfOtherExpenses());

	QueryText =
	"SELECT
	|	&Period                                         AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	&Organization                                    AS Organization,
	|	&Department                                  AS Department,
	|	&ExpenseItemTaxBuyout                            AS ExpenseItem,
	|	&ExpensesDimensionInCaseOfEarlyBuyout                         AS DimensionOfExpenses,
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
	|	0                                               AS CostTD,
	|
	|	TableExpenses.BusinessOperation            AS BusinessOperation,
	|	TableExpenses.FinRecordID           AS FinRecordID,
	|	TableExpenses.BusinessTransactionSetting   AS BusinessTransactionSetting
	|
	|FROM
	|	TTCostsUponTerminationOfLease AS TableExpenses
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS OtherItemsOfExpenditure
	|		ON &ExpenseItemTaxBuyout = OtherItemsOfExpenditure.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.EarlyBuyoutOfLeasedAssets)
	|	AND OtherItemsOfExpenditure.CostAllocationOptionLocal IN (VALUE(Enum.CostAllocationOptions.ToInventoryCost))";
	ListOfMergeRequests.Add(QueryText);
	
	VendorInvoiceLeasedAssetsLocalization.AddRequestTextOtherExpensesBatchTable(Query, QueryTexts, ListOfMergeRequests);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return "";

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return VendorInvoiceLeasedAssetsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region AccountingMechanisms

Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	VendorInvoiceLeasedAssetsLocalization.AddOptionsForSelectingArticlesAndAnalytics(ArticleSelectionAndAnalyticsOptions);
	
	#Region Expenses
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemTaxBuyout";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionInCaseOfEarlyBuyout";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemTaxBuyout");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionInCaseOfEarlyBuyout");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	#EndRegion
	
	#Region Income
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeItemBuyout";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "IncomeDimensionInCaseOfEarlyRedemption";

	ChoiceParameters.FormItems.AssetRef.Add("IncomeItemBuyout");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("IncomeDimensionInCaseOfEarlyRedemption");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	#EndRegion
	
	Return ArticleSelectionAndAnalyticsOptions;
	
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
			"Contract");
		Contract = StructureFillingData.Contract;
	ElsIf FillingData = Undefined Then
		Contract = Undefined;
	Else
		Contract = FillingData.Contract;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.ChangesPaymentPlan               = False;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;

	#Region OptionalParameters
	
	// Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";
	ParametersStructure.LineOfBusiness          = "";
	ParametersStructure.ARAPObjectSettings                  = "";
	ParametersStructure.PathToTSData                    = "Object.FA";
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

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.VendorInvoiceLeasedAssets, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "LineOfBusiness,AssetHolder");
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = ContractDetails_.LineOfBusiness;
	FillParameters.PurchaseOnArticles = True;
	FillParameters.LeasingPropertyOnBalanceSheet =
		(ContractDetails_.AssetHolder = Enums.LeasedAssetHolder.Leaseholder);
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for filling in VAT taxation for purchases
//
// Parameters:
//  Object		- DocumentObject.VendorInvoiceLeasedAssets, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract;
	FillParameters.Period  = Object.Date;
	
	FillParameters.RentalService = True;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for checking the completion of VAT taxation for purchases
//
// Parameters:
//  Object		- DocumentObject.VendorInvoiceLeasedAssets, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  Structure - See VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases
//
Function VerificationParametersFillingInDocumentOnVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases();
	FillParameters.TabularSectionName = "FA";
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for checking the filling in of the document by type of activity VAT
//
// Parameters:
//  Object		- DocumentObject.VendorInvoiceLeasedAssets, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  Structure - See VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity
//
Function ParametersForCheckingDocumentFillingByTypeOfActivity(Object) Export
	
	FillParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	FillParameters.TabularSectionName = "FA";
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.VendorInvoiceLeasedAssets, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	RegistrationParameters.Ref = Object.Ref;
	RegistrationParameters.Date = Object.Date;
	RegistrationParameters.Organization = Object.Organization;
	RegistrationParameters.Counterparty = Object.Counterparty;
	RegistrationParameters.VATTaxation = Object.VATTaxation;
	RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region FillType

// Fills in the document based on the lease agreement.
// 
// Parameters:
// 	Object - DocumentObject.VendorInvoiceLeasedAssets, FormDataStructure -
//  OutputMessages - Boolean -
Procedure FillInBasedOnLeaseAgreement(Object, OutputMessages = False) Export
	
	If Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;

	Object.FA.Clear();

	QueryText =
	"SELECT
	|	TermsOfLeaseContracts.Contract.Organization AS Organization,
	|	TermsOfLeaseContracts.Contract.Partner AS Partner,
	|	TermsOfLeaseContracts.Contract.Counterparty AS Counterparty,
	|	TermsOfLeaseContracts.Contract.ARAPCurrency AS ARAPCurrency,
	|	TermsOfLeaseContracts.VATRate AS VATRate,
	|	TermsOfLeaseContracts.AmountOfLeaseAssetsByuout AS AmountOfLeaseAssetsByuout,
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract.ThereIsPrepaymentOfBuyoutValue AS ThereIsAdvancePayment
	|INTO TTContractTermsAndConditions
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|			&Date,
	|			Recorder <> &Ref
	|				AND Contract = &Contract) AS TermsOfLeaseContracts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(LeaseServicesPaymentSchedule.BuyoutValuePrepayment + LeaseServicesPaymentSchedule.BuyoutValue) AS RedemptionAmount
	|INTO TTOfAmountAccordingToSchedule
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS LeaseServicesPaymentSchedule
	|WHERE
	|	LeaseServicesPaymentSchedule.EffectiveContractTerms IN
	|			(SELECT
	|				TTContractTermsAndConditions.EffectiveContractTerms AS EffectiveContractTerms
	|			FROM
	|				TTContractTermsAndConditions AS TTContractTermsAndConditions)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTContractTermsAndConditions.Organization AS Organization,
	|	TTContractTermsAndConditions.Partner AS Partner,
	|	TTContractTermsAndConditions.Counterparty AS Counterparty,
	|	TTContractTermsAndConditions.ARAPCurrency AS Currency,
	|	TTContractTermsAndConditions.ARAPCurrency AS ARAPCurrency,
	|	TTContractTermsAndConditions.VATRate AS VATRate,
	|	ISNULL(TTOfAmountAccordingToSchedule.RedemptionAmount, 0) AS AmountOfLeaseAssetsByuout
	|FROM
	|	TTContractTermsAndConditions AS TTContractTermsAndConditions
	|		LEFT JOIN TTOfAmountAccordingToSchedule AS TTOfAmountAccordingToSchedule
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(&Date, Recorder <> &Ref) AS LeasedAsset
	|WHERE
	|	LeasedAsset.Contract = &Contract
	|	AND LeasedAsset.State = VALUE(Enum.FixedAssetsStates.InLease)
	|
	|ORDER BY
	|	LeasedAsset.FixedAsset.Presentation,
	|	LeasedAsset.FixedAsset.AssetID";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("Date", ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));
	
	Result = Query.ExecuteBatch();
	
	If Result[Result.UBound()].IsEmpty() 
		And OutputMessages Then
		
		MessageText = NStr("vi = 'Theo hợp đồng không có tài sản cố định đã tiếp nhận vào kế toán.
							  |Có thể là tài sản cố định đã được mua lại hoặc đã chấm dứt hợp đồng thuê hoặc tài sản cố định chưa được tiếp nhận vào kế toán.';
							  |ru = 'По договору нет принятых к учету основных средств.
							  |Возможно, основные средства уже выкуплены или оформлено прекращение договора аренды, или основные средства не принимались к учету.';
							  |en = 'There are no recognized fixed assets under the contract.
							  |The fixed assets may have already been redeemed, or the rental termination may have been registered, or the fixed assets have not been recognized.'; fa = 'There are no recognized fixed assets under the contract.
							  |The fixed assets may have already been redeemed, or the rental termination may have been registered, or the fixed assets have not been recognized.';
							  |it = 'In base all''accordo non vi sono immobilizzazioni registrate in contabilità.
							  |Probabilmente le immobilizzazioni sono state già rimborsate o è stato terminato il contratto di affitto, oppure le immobilizzazioni non sono state registrate in contabilità.';
							  |pl = 'Zgodnie z umową nie ma przyjętych do ewidencji środków trwałych.
							  |Możliwe, że środki trwałe są już wykupione lub jest utworzone zawieszenie umowy dzierżawy, lub środki trwałe nie były przyjęte do ewidencji.';
							  |tr = 'Sözleşme kapsamında muhasebeleştirilen herhangi bir sabit kıymet bulunmamaktadır. 
							  | Sabit kıymetler geri alınmış veya kiralama sözleşmesi feshedilmiş olabilir ya da sabit kıymetler muhasebeleştirilmemiş olabilir.'");
		Common.MessageToUser(MessageText);
		Return;
	EndIf;
	
	Selection = Result[Result.UBound()-1].Select();
	Selection.Next();
	
	FillPropertyValues(Object, Selection);
	
	Object.PriceIncludesVAT = True;
	
	DocumentOfConclusionOfContractOfLease = Catalogs.LeaseContract.DocumentOfConclusionOfContractOfLease(Object.Contract);
	If ValueIsFilled(DocumentOfConclusionOfContractOfLease) Then 
		Object.PurchaseForActivity = Common.ObjectAttributeValue(DocumentOfConclusionOfContractOfLease, "PurchaseForActivity");
	EndIf;
	
	Object.FA.Load(Result[Result.UBound()].Unload());
	
	If Object.FA.Count() = 1 Then
		
		RowData = Object.FA[0];
		RowData.Sum = Selection.AmountOfLeaseAssetsByuout;
		RowData.VATRate = Selection.VATRate;
		
		RowData.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
			RowData.Sum,
			VATAccountingERPClientServer.ValueOfVATRate(RowData.VATRate),
			Object.PriceIncludesVAT,
			Object.VATTaxation);
		
		RowData.AmountIncludingVAT = RowData.Sum;
		RowData.AmountARAP = RowData.Sum;
		RowData.AmountVATARAP = RowData.VATAmount;
	
	EndIf;
	
EndProcedure

// Fills in the document based on the document Changing the terms of the lease Contract.
// 
// Parameters:
// 	Object - DocumentObject.VendorInvoiceLeasedAssets, FormDataStructure -
//  Basis - DocumentRef.LeaseTermAdjustment -
// Returns:
//  String, Undefined - text of the error message.
Function FillInOnBasisOfRentalTermsADJUSTMENTChanges(Object, Basis) Export
	
	If Not ValueIsFilled(Basis) Then
		Object.DocumentBasis = Undefined;
		Object.GeneratedDocument = False;
		Return Undefined;
	EndIf;
	
	Object.DocumentBasis = Basis;
	Object.GeneratedDocument = True;

	QueryText = 
	"SELECT
	|	LeaseTermAdjustment.Organization AS Organization,
	|	LeaseTermAdjustment.Partner AS Partner,
	|	LeaseTermAdjustment.Counterparty AS Counterparty,
	|	LeaseTermAdjustment.Contract AS Contract,
	|	LeaseTermAdjustment.ARAPCurrency AS Currency,
	|	LeaseTermAdjustment.ARAPCurrency AS ARAPCurrency,
	|	LeaseTermAdjustment.VATRate AS VATRate,
	|	VALUE(Enum.BusinessTransactions.EarlyBuyoutOfLeasedAssets) AS BusinessOperation,
	|	TRUE AS PriceIncludesVAT
	|FROM
	|	Document.LeaseTermAdjustment AS LeaseTermAdjustment
	|WHERE
	|	LeaseTermAdjustment.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeaseTermAdjustmentFA.FixedAsset AS FixedAsset,
	|	LeaseTermAdjustmentFA.BuyoutValue AS Sum,
	|	LeaseTermAdjustmentFA.BuyoutValue AS AmountIncludingVAT,
	|	LeaseTermAdjustmentFA.Ref.VATRate AS VATRate
	|FROM
	|	Document.LeaseTermAdjustment.FA AS LeaseTermAdjustmentFA
	|WHERE
	|	LeaseTermAdjustmentFA.Ref = &Basis
	|	AND LeaseTermAdjustmentFA.ActionWithRentalObject 
	|		= VALUE(Enum.ActionsWithRentalObjects.EarlyRedemption)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", Object.DocumentBasis);
	Result = Query.ExecuteBatch();
	
	If Result[0].IsEmpty() Then
		Return Undefined;
	EndIf;
	
	If Result[1].IsEmpty() Then
		ErrorText = NStr("vi = 'Trong chứng từ không có tài sản cố định hữu hình mà được mua lại trước hạn';
						|ru = 'В документе нет основных средств, выкупаемых досрочно';
						|en = 'The document contains no fixed assets for early redemption'; fa = 'The document contains no fixed assets for early redemption';
						|it = 'В документе нет основных средств, выкупаемых досрочно';
						|pl = 'The document contains no fixed assets for early redemption';
						|tr = 'Belgede erken itfa edilebilir sabit kıymet bulunmamaktadır'");
		Return ErrorText;
	EndIf;
	
	Selection = Result[0].Select();
	Selection.Next();
	
	FillPropertyValues(Object, Selection);
	
	Object.FA.Clear();
	
	Selection = Result[1].Select();

	While Selection.Next() Do
		
		RowData = Object.FA.Add();
		FillPropertyValues(RowData, Selection);
		RowData.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
			RowData.Sum,
			VATAccountingERPClientServer.ValueOfVATRate(RowData.VATRate),
			Object.PriceIncludesVAT,
			Object.VATTaxation);
		RowData.AmountVATARAP = RowData.VATAmount;
		
	EndDo;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
