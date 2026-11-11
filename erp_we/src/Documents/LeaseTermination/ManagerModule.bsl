
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
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("ImportAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("FinancialInstruments");
	
	LeaseTerminationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Defines additional data sources for movements.
// 
// Parameters:
//  RegisterName - String - register name.
// 
// Returns:
//  Map - Additional data sources for movements
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

// Generates the text of the request for movements by case.
// 
// Parameters:
//  RegisterName - String - register name.
// 
// Returns:
//  Structure - Adapted Case-Sensitive Query Text:
// 		* QueryText - String - 
// 		* ParameterValues - Structure -
Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.LeaseTermination";
	TemporaryTableQueryTexts = New Map();
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("Department", "DocumentData.Contract.Department");
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
	
	If TypeOf(Document) = Type("DocumentObject.LeaseTermination") Then
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
		
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableLeasedAsset(QueryTexts, Registers);
		QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers);
		
		QueryTextTableGoodsForRegistrationOfImportDocuments(QueryTexts, Registers);
		QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		LeaseTerminationLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  DocumentRef - DocumentRef.LeaseTermination - The document for which the movements are formed.
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
		
	GenerateExtendedFATable(Query, QueryTexts);
	
	QueryTextTableFACost(Query, QueryTexts);
	QueryTextTableFixedAssetsDepreciationCharge(QueryTexts);
	QueryTextTableImpairmentFA(QueryTexts);
	QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Undefined);
	
	QueryTextTableOtherExpenses(Query, QueryTexts, Undefined);
	QueryTextTableItemisedExpensesLots(Query, QueryTexts, Undefined);
	QueryTextTableOtherIncome(Query, QueryTexts, Undefined);

	QueryTextTableInitialFixedAssetsInformation(QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableLeasedAsset(QueryTexts, Undefined);
	QueryTextTableTermsOfLeaseContracts(QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	LeaseTerminationLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
	TablesForRegisteredRecords = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, Undefined);
	
	Return TablesForRegisteredRecords;
	
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

// Adds the command to create the document "termination of the lease agreement".
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
	
	If AccessRight("Insert", Metadata.Documents.LeaseTermination) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.LeaseTermination.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.LeaseTermination);
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

#Region Other

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
		Data, Presentation, StandardProcessing, "LeaseTermination");
	
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
	|	Document.LeaseTermination AS DocumentData
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

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
	GetDocumentData(Query);
	
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Period,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Contract.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Contract.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Contract.Department AS Department,
	|	ISNULL(CatLeaseContracts.RegisterImportApplications, FALSE) AS RegisterImportApplications,
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.IncomeItem AS IncomeItem,
	|	DocumentData.DimensionOfRevenue AS DimensionOfRevenue,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.DocumentID AS DocumentID,
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED) AS DimensionByPartners
	|FROM
	|	Document.LeaseTermination AS DocumentData
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = DocumentData.Organization
	|			AND DimensionByPartners.Partner = DocumentData.Partner
	|			AND DimensionByPartners.Counterparty = DocumentData.Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = DocumentData.Contract.LineOfBusiness
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
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.FAWriteOffExpenses) AS RetirementItem,
	|	TRUE AS RecordInManAccounting,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS PostInAccounting,
	|	TRUE AS RecordInTA
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.LeaseTermination AS DocumentData
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
	|	Document.LeaseTermination.FA AS DocumentTable
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
	NonCurrentAssets.AddValuesOfPaymentParametersWhenDebitingFA(ValuesOfHoldingParameters);

	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Chấm dứt hợp đồng thuê';
															|ru = 'Прекращение договора аренды';
															|en = 'Rental termination'; fa = 'فسخ اجاره';
															|it = 'Risoluzione del contratto di affitto';
															|pl = 'Wygaśnięcie umowy dzierżawy';
															|tr = 'kira feshi'"));
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.LeaseTermination"));
	ValuesOfHoldingParameters.Insert("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("RecordInManAccounting", True);
	ValuesOfHoldingParameters.Insert("RecordInLocalAccounting", True);
	ValuesOfHoldingParameters.Insert("PostInAccounting", True);
	ValuesOfHoldingParameters.Insert("RecordInTA", True);

	ValuesOfHoldingParameters.Insert("BO_WriteOffFixedAssetsCost", Enums.BusinessTransactions.WriteOffOfLeasedAssetsCost);
	ValuesOfHoldingParameters.Insert("SettingUpHO_WriteOffOfCostOfLeasedOperatingSystems", Catalogs.BusinessTransactionsSettings.WriteOffOfLeasedAssetsCost);

	ValuesOfHoldingParameters.Insert("HO_WriteOffOfCollateralValueOfFA", Enums.BusinessTransactions.WritingOffCollateralValueOfLeasedFixedAssets);
	ValuesOfHoldingParameters.Insert("ConfiguringHO_WriteOffOfFACollateralValue", Catalogs.BusinessTransactionsSettings.WritingOffCollateralValueOfLeasedFixedAssets);
	
	ValuesOfHoldingParameters.Insert("IdApplicationForImportOfGoods", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));

	If Attributes <> Undefined Then
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.ARAPCurrency, Undefined, Attributes.Period, Attributes.Organization);
		ValuesOfHoldingParameters.Insert("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
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
		
		If Attributes <> Undefined Then
			ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		EndIf;
		
		ValuesOfHoldingParameters.Insert("DocumentOfConclusionOfContractOfLease", Catalogs.LeaseContract.DocumentOfConclusionOfContractOfLease(Attributes.Contract));
		 
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
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
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
	|	FATable.FixedAsset              AS FixedAsset
	|FROM
	|	Document.LeaseTermination AS DocumentData
	|		LEFT JOIN Document.LeaseTermination.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);

	QueryText = NonCurrentAssetsInternal.RequestTextForDepreciationWriteOffFA(QueryTexts);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableImpairmentFA(QueryTexts)

	RegisterName = "ImpairmentFA";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);

	QueryText = NonCurrentAssetsInternal.TextOfRequestToWriteOffImpairmentOfFA(QueryTexts);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFACost(Query, QueryTexts)

	RegisterName = "FACost";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTLeasedFA(QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(NonCurrentAssetsInternal.TextOfRequestToDeductCostOfFA(QueryTexts, Query));

	#Region DebitingFromOffBalance
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Ref                                AS Recorder,
	|	&Period                                AS Period,
	|	&Organization                           AS Organization,
	|	FATable.FixedAssetsLocation              AS Department,
	|	FATable.FixedAsset             AS FixedAsset,
	|
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	0                                      AS CostInTaxAccounting,
	|	0                                      AS CostPermanentDifference,
	|	0                                      AS CostTemporaryDifference,
	|	0                                      AS CostTargetFinancing,
	|	0                                      AS CostTargetFinancingTA,
	|	0                                      AS CostTargetFinancingPD,
	|	0                                      AS CostTargetFinancingTD,
	|
	|	0                                      AS PreliminaryCostMan,
	|	0                                      AS PreliminaryCostLocal,
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|	0                                      AS DisregardedCostTA,
	|
	|	FACost.SecurityDepositValue         AS SecurityDepositValue,
	|	
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness      AS LineOfBusiness,
	|	FATable.Leaseholder                    AS Leaseholder,
	|
	|	TTLeasedFA.Counterparty            AS CorCounterparty,
	|
	|	&HO_WriteOffOfCollateralValueOfFA       AS BusinessOperation,
	|	&RecordInLocalAccounting                    AS RecordInLocalAccounting,
	|	&RecordInManAccounting                     AS RecordInManAccounting,
	|	
	|	FATable.RowID          AS FinRecordID,
	|	&ConfiguringHO_WriteOffOfFACollateralValue AS BusinessTransactionSetting
	|	
	|FROM
	|	TTFATable AS FATable
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FATable.FixedAsset = FACost.AccountingObject
	|			AND FACost.Ref = &Ref
	|
	|		LEFT JOIN TTLeasedFA AS TTLeasedFA
	|		ON TTLeasedFA.FixedAsset = FATable.FixedAsset
	|WHERE
	|	FACost.SecurityDepositValue <> 0";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region Debiting01K
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Ref                                AS Recorder,
	|	&Period                                AS Period,
	|	&Organization                           AS Organization,
	|	FATable.FixedAssetsLocation              AS Department,
	|	FATable.FixedAsset             AS FixedAsset,
	|
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	0                                      AS CostInTaxAccounting,
	|	0                                      AS CostPermanentDifference,
	|	0                                      AS CostTemporaryDifference,
	|	0                                      AS CostTargetFinancing,
	|	0                                      AS CostTargetFinancingTA,
	|	0                                      AS CostTargetFinancingPD,
	|	0                                      AS CostTargetFinancingTD,
	|
	|	0                                      AS PreliminaryCostMan,
	|	0                                      AS PreliminaryCostLocal,
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|
	|	FACost.DisregardedCostTA   AS DisregardedCostTA,
	|	0                                      AS SecurityDepositValue,
	|	
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness      AS LineOfBusiness,
	|	FATable.Leaseholder                    AS Leaseholder,
	|
	|	UNDEFINED                           AS CorCounterparty,
	|
	|	&BO_WriteOffOfDisregardedCostTA   AS BusinessOperation,
	|	&RecordInLocalAccounting                    AS RecordInLocalAccounting,
	|	&RecordInManAccounting                     AS RecordInManAccounting,
	|	
	|	FATable.RowID          AS FinRecordID,
	|	&SettingUpHO_WriteOffUnrecordedValueTa AS BusinessTransactionSetting
	|	
	|FROM
	|	TTFATable AS FATable
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FATable.FixedAsset = FACost.AccountingObject
	|			AND FACost.Ref = &Ref
	|WHERE
	|	FACost.DisregardedCostTA <> 0";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
	
	QueryText = LeaseTerminationLocalization.QueryTextTableInitialFixedAssetsInformation();
	If QueryText = Undefined Then
		QueryText =
		"SELECT
		|	&Period                                   AS Period,
		|	&Organization                              AS Organization,
		|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|
		|	CASE
		|		WHEN InitialFixedAssetsInformation.CommissioningDateAC <> DATETIME(1,1,1)
		|			THEN &Ref 
		|		ELSE InitialFixedAssetsInformation.DeregistrationDocumentACC
		|	END AS DeregistrationDocumentACC,
		|
		|	CASE
		|		WHEN InitialFixedAssetsInformation.CommissioningDateMA <> DATETIME(1,1,1)
		|			THEN &Ref 
		|		ELSE InitialFixedAssetsInformation.DeregistrationDocumentMA
		|	END AS DeregistrationDocumentMA
		|
		|FROM
		|	TTInitialInformationFA AS InitialFixedAssetsInformation";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts);
	
	QueryText =
	"SELECT
	|	&Period                                           AS Period,
	|	&Organization                                      AS Organization,
	|	AccountingProcedure.FixedAsset                     AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks)    AS BUState,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks)    AS StateTa,
	|	FALSE                                              AS DepreciationAccrualAccounting,
	|	FALSE                                              AS DepreciationAccrualTaxAccounting,
	|	AccountingProcedure.DepreciationGroup                AS DepreciationGroup,
	|	AccountingProcedure.RealEstate                  AS RealEstate
	|FROM
	|	TueAccountingProcedureForOSBU AS AccountingProcedure";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(QueryTexts);
	
	QueryText =
	"SELECT
	|	&Period                       AS Period,
	|	&Organization                  AS Organization,
	|	AccountingProcedure.FixedAsset AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks) AS State,
	|	FALSE                          AS AccrueDepreciationOrAmortization
	|FROM
	|	TTAccountingProcedureForOsuu AS AccountingProcedure";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

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
	|	Document.LeaseTermination.FA AS FATable
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
	|	Document.LeaseTermination.FA AS FATable
	|		INNER JOIN TTUnitsDepreciationComponents AS NodesComponents
	|		ON FATable.FixedAsset = NodesComponents.FixedAsset
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
	|	TTTermsOfLeaseAgreements AS TermsOfLeaseContracts";
	
	QueryTexts.Add(QueryText, RegisterName);
		
EndProcedure

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query);

	QueryTextTableTTFATable(QueryTexts);
	QueryTextTableTTChangeInLeaseLiabilities(QueryTexts);
	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);
	LeasedAssetAccounting.QueryTextTableTTCostsUponTerminationOfLease(Query, QueryTexts);
	LeasedAssetAccounting.QueryTextTableTTIncomeUponTerminationOfLease(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTResidualValueOfFA(QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region WriteOffOfLeaseInterest // Dt <76.07.1> - Ct <70.07.5>
	QueryText =
	"SELECT
	|	&Period                                             AS Period,
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
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
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
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
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
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
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
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
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
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
	|	&BO_VATWriteOffOnLease                             AS BusinessOperation,
	|	&SettingsHO_DeductionOfVATForRent                    AS BusinessTransactionSetting
	|FROM
	|	TT_FinancialInstrumentsARAP AS CalculationsBalance
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	CalculationsBalance.Ref = &Ref
	|	AND CalculationsBalance.Contract = &Contract
	|	AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|	AND (CalculationsBalance.Sum <> 0
	|		OR CalculationsBalance.SumMan <> 0
	|		OR CalculationsBalance.SumCompl <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                             AS Period,
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
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
	|	&BO_VATWriteOffOnLease                             AS BusinessOperation,
	|	&SettingsHO_DeductionOfVATForRent                    AS BusinessTransactionSetting
	|FROM
	|	TT_FinancialInstrumentsARAP AS CalculationsBalance
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|			ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	CalculationsBalance.Ref = &Ref
	|	AND CalculationsBalance.Contract = &Contract
	|	AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|	AND (CalculationsBalance.Sum <> 0
	|		OR CalculationsBalance.SumMan <> 0
	|		OR CalculationsBalance.SumCompl <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region WriteOffOfResidualValueOfOS // Dt <76.07.1> - Ct <01.09>
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
	|	CASE
	|		WHEN (FATable.LocalCost + FATable.CostTargetFinancing) <> 0
	|			THEN (FATable.LocalCost + FATable.CostTargetFinancing)
	|					* CASE
	|						WHEN &ARAPCurrency = &LocalAccountingCurrency
	|							THEN 1
	|						ELSE &ConversionFactorFromLocalCurrency
	|					END
	|		WHEN FATable.Cost <> 0
	|			THEN FATable.Cost
	|					* CASE
	|						WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|							THEN 1
	|						ELSE &ConversionFactorFromManCurrency
	|					END
	|		ELSE 0
	|	END AS Sum,
	|
	|	FATable.Cost                                                     AS SumMan,
	|	FATable.LocalCost + FATable.CostTargetFinancing                         AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,	
	|	FATable.RowID                                           AS FinRecordID,
	|
	|	&BO_WriteOffFixedAssetsCost                                                 AS BusinessOperation,
	|	&SettingUpHO_WriteOffOfCostOfLeasedOperatingSystems                            AS BusinessTransactionSetting
	|FROM
	|	TTResidualValueOfFA AS FATable
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	(FATable.Cost <> 0
	|		OR FATable.LocalCost <> 0
	|		OR FATable.CostTargetFinancing <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region WriteOffOfDisregardedCostTA // Dt <76.07.1> - Ct <01.K>
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
	|	0                                                                       AS Sum,
	|	0                                                                       AS SumMan,
	|	0                                                                       AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	UNDEFINED                                                            AS RowID,	
	|	FATable.RowID                                           AS FinRecordID,
	|
	|	&BO_WriteOffOfDisregardedCostTA                                    AS BusinessOperation,
	|	&SettingUpHO_WriteOffUnrecordedValueTa                           AS BusinessTransactionSetting
	|FROM
	|	TTFATable AS FATable
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FATable.FixedAsset = FACost.AccountingObject
	|			AND FACost.Ref = &Ref
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	FACost.DisregardedCostTA <> 0";
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
	|	TTCostsUponTerminationOfLease AS TableExpenses
	|";
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
	|	TTIncomeUponTerminationOfLease AS TableRevenue";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	Add_Fields = "Recorder";

	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields);
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
	
	QueryText =
	"SELECT
	|	&Period                                        AS Period,
	|	&Organization                                   AS Organization,
	|	&Department                                 AS Department,
	|	&LineOfBusiness                       AS LineOfBusiness,
	|	&IncomeItem                                 AS IncomeItem,
	|	&DimensionOfRevenue                              AS DimensionOfRevenue,
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
	|	TTIncomeUponTerminationOfLease AS TableRevenue";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

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

Procedure QueryTextTableTTFATable(QueryTexts)
	
	TableName = "TTFATable";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTUnitsDepreciationComponents(QueryTexts);
	
	QueryText = 
	"SELECT
	|	FATable.Ref                       AS Ref,
	|	FATable.FixedAsset             AS FixedAsset,
	|	VALUE(Catalog.Assets.EmptyRef) AS FAOwner,
	|
	|	AccountingProcedure.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	AccountingProcedure.LineOfBusiness   AS LineOfBusiness,
	|	AccountingProcedure.RunningTimeValue       AS RunningTimeValue,
	|	AccountingProcedure.EstimatedRunningTime            AS EstimatedRunningTime,
	|
	|	FALocation.Organization          AS Organization,
	|	FALocation.FinanciallyLiablePerson                  AS FinanciallyLiablePerson,
	|	FALocation.FixedAssetsLocation      AS FixedAssetsLocation,
	|	FALocation.LocationAddress AS LocationAddress,
	|	FALocation.Leaseholder            AS Leaseholder,
	|
	|	FALSE                                   AS AccrueDepreciation,
	|
	|	UNDEFINED                           AS IncomeItem,
	|	UNDEFINED                           AS DimensionOfRevenue,
	|
	|	0                                      AS AmountManagementAccounting,
	|	0                                      AS ChargeAmountAccounting,
	|	0                                      AS AmountTaxAccounting,
	|	0                                      AS AmountPermanentDifference,
	|	0                                      AS AmountTemporaryDifference,
	|	
	|	FATable.RowID 		   AS RowID
	|	
	|INTO TTFATable
	|FROM
	|	Document.LeaseTermination.FA AS FATable
	|		LEFT JOIN TTAccountingFA AS AccountingProcedure
	|		ON FATable.FixedAsset = AccountingProcedure.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FATable.FixedAsset = FALocation.FixedAsset
	|
	|WHERE
	|	FATable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.Ref                       AS Ref,
	|	NodesComponents.SubAssetComponent           AS FixedAsset,
	|	FATable.FixedAsset             AS FAOwner,
	|
	|	AccountingProcedure.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	AccountingProcedure.LineOfBusiness   AS LineOfBusiness,
	|	AccountingProcedure.RunningTimeValue       AS RunningTimeValue,
	|	AccountingProcedure.EstimatedRunningTime            AS EstimatedRunningTime,
	|
	|	FALocation.Organization          AS Organization,
	|	FALocation.FinanciallyLiablePerson                  AS FinanciallyLiablePerson,
	|	FALocation.FixedAssetsLocation      AS FixedAssetsLocation,
	|	FALocation.LocationAddress AS LocationAddress,
	|	FALocation.Leaseholder            AS Leaseholder,
	|
	|	FALSE                                   AS AccrueDepreciation,
	|
	|	UNDEFINED                           AS IncomeItem,
	|	UNDEFINED                           AS DimensionOfRevenue,
	|
	|	0                                      AS AmountManagementAccounting,
	|	0                                      AS ChargeAmountAccounting,
	|	0                                      AS AmountTaxAccounting,
	|	0                                      AS AmountPermanentDifference,
	|	0                                      AS AmountTemporaryDifference,
	|	
	|	NodesComponents.RowID     AS RowID
	|FROM
	|	Document.LeaseTermination.FA AS FATable
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS NodesComponents
	|		ON FATable.FixedAsset = NodesComponents.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS AccountingProcedure
	|		ON NodesComponents.SubAssetComponent = AccountingProcedure.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON NodesComponents.SubAssetComponent = FALocation.FixedAsset
	|WHERE
	|	FATable.Ref = &Ref
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTChangeInLeaseLiabilities(QueryTexts)
	
	TableName = "TTChangeInLeaseLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTResidualValueOfFA(QueryTexts);

	QueryText =
	"SELECT
	|	SUM(Table.Sum) AS Sum,
	|	SUM(Table.SumCompl) AS SumCompl,
	|	SUM(Table.SumMan) AS SumMan
	|INTO TTChangeInLeaseLiabilities
	|FROM
	|	(SELECT
	|		CalculationsBalance.Sum AS Sum,
	|		CalculationsBalance.SumCompl AS SumCompl,
	|		CalculationsBalance.SumMan AS SumMan
	|	FROM
	|		TT_FinancialInstrumentsARAP AS CalculationsBalance
	|	WHERE
	|		CalculationsBalance.Ref = &Ref
	|		AND CalculationsBalance.Contract = &Contract
	|		AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|		AND (CalculationsBalance.Sum <> 0
	|				OR CalculationsBalance.SumMan <> 0
	|				OR CalculationsBalance.SumCompl <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationsBalance.Sum,
	|		CalculationsBalance.SumCompl,
	|		CalculationsBalance.SumMan
	|	FROM
	|		TT_FinancialInstrumentsARAP AS CalculationsBalance
	|	WHERE
	|		CalculationsBalance.Ref = &Ref
	|		AND CalculationsBalance.Contract = &Contract
	|		AND CalculationsBalance.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|		AND (CalculationsBalance.Sum <> 0
	|				OR CalculationsBalance.SumMan <> 0
	|				OR CalculationsBalance.SumCompl <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CAST(CASE
	|			WHEN FATable.LocalCost <> 0
	|				THEN FATable.LocalCost
	|					* CASE
	|						WHEN &ARAPCurrency = &LocalAccountingCurrency
	|							THEN 1
	|						ELSE &ConversionFactorFromLocalCurrency
	|					END
	|			WHEN FATable.Cost <> 0
	|				THEN FATable.Cost
	|					* CASE
	|						WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|							THEN 1
	|						ELSE &ConversionFactorFromManCurrency
	|					END
	|			ELSE 0
	|		END AS NUMBER (31,2)),
	|
	|		FATable.LocalCost,
	|
	|		FATable.Cost
	|	FROM
	|		TTResidualValueOfFA AS FATable
	|	WHERE
	|		(FATable.Cost <> 0
	|			OR FATable.LocalCost <> 0)
	|
	|	) AS Table";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, Add_Fields)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields);
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields)
	
	RegisterName = "TTInitialOtherExpenses";
	
	LeasedAssetAccounting.QueryTextTableTTCostsUponTerminationOfLease(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTResidualValueOfFA(QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
	
	#Region WriteOffOfCostAndDepreciation // Dt <01.09> - Ct <01.01>; Dt <02.01> - Ct <01.09> 
	QueryText = NonCurrentAssetsInternal.QueryTextTableTTInitialOtherExpensesAtDisposalOfFA(QueryTexts);
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region WriteOffOfResidualValueOfOS // Dt <76.07.1> - Ct <01.09>
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	
	|	&Organization AS Organization,
	|	FATable.FixedAssetsLocation AS Department,
	|	FATable.RetirementItem AS ExpenseItem,
	|
	|	CASE
	|		WHEN OwnerRow.FAOwner = VALUE(Catalog.Assets.EmptyRef)
	|			THEN FATable.FixedAsset
	|		ELSE OwnerRow.FAOwner
	|	END AS DimensionOfExpenses,
	|
	|	FATable.LineOfBusiness AS LineOfBusiness,
	|
	|	UNDEFINED AS VATActivityType,
	|	
	|	FATable.Cost AS AmountIncludingVAT,
	|	FATable.Cost AS AmountExcludingVAT,
	|	FATable.Cost AS AmountExcludingVATMan,
	|	FATable.LocalCost + FATable.CostTargetFinancing AS AmountIncludingVATCompl,
	|	FATable.LocalCost + FATable.CostTargetFinancing AS AmountExcludingVATCompl,
	|	FATable.CostPermanentDifference + FATable.CostTargetFinancingPD AS PermanentDifference,
	|	FATable.CostTemporaryDifference + FATable.CostTargetFinancingTD AS CostTD,
	|	
	|	&BO_WriteOffFixedAssetsCost AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	FATable.RowID AS FinRecordID,
	|	&SettingUpHO_WriteOffOfCostOfLeasedOperatingSystems AS BusinessTransactionSetting
	|
	|	,&Ref AS Recorder
	|
	|FROM
	|	TTResidualValueOfFA AS FATable
	|
	|		LEFT JOIN TTFATable AS OwnerRow
	|		ON FATable.FixedAsset = OwnerRow.FixedAsset
	|
	|WHERE
	|	(FATable.Cost <> 0
	|		OR FATable.LocalCost <> 0
	|		OR FATable.CostTargetFinancing <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region ExpensesUponTerminationOfLeaseAgreement // Dt <Expenses> - Ct <76.07.1>
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&ExpenseItem AS ExpenseItem,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
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
	|
	|	,&Ref AS Recorder
	|FROM
	|	TTCostsUponTerminationOfLease AS TableExpenses";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
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
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.TextDescriptionTTInitialBatchesOfOtherExpenses();
	QueryText = QueryText + TMCommonUse.QuerySeparatorInJoin() +
	"SELECT
	|	&Period                                         AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	&Organization                                    AS Organization,
	|	&Department                                  AS Department,
	|	&ExpenseItem                                 AS ExpenseItem,
	|	&DimensionOfExpenses                              AS DimensionOfExpenses,
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
	|	TableExpenses.SumCompl                        AS PermanentDifference,
	|	0                                               AS CostTD,
	|
	|	TableExpenses.BusinessOperation            AS BusinessOperation,
	|	TableExpenses.FinRecordID           AS FinRecordID,
	|	TableExpenses.BusinessTransactionSetting   AS BusinessTransactionSetting
	|
	|FROM
	|	TTCostsUponTerminationOfLease AS TableExpenses
	|
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS OtherItemsOfExpenditure
	|		ON &ExpenseItem = OtherItemsOfExpenditure.Ref
	|WHERE
	|	OtherItemsOfExpenditure.CostAllocationOptionLocal IN (VALUE(Enum.CostAllocationOptions.ToInventoryCost))";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return LeaseTerminationLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return "";

EndFunction

#EndRegion

#Region FillType

// Fills in the document based on the lease agreement.
// 
// Parameters:
// 	Object - DocumentObject.LeaseTermination - 
Procedure FillInBasedOnLeaseAgreement(Object) Export
	
	If Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	Object.FA.Clear();
	
	QueryText = 
	"SELECT
	|	TermsOfLeaseContracts.Contract.Organization AS Organization,
	|	TermsOfLeaseContracts.Contract.Partner AS Partner,
	|	TermsOfLeaseContracts.Contract.Counterparty AS Counterparty
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|		&Date, 
	|		Recorder <> &Ref
	|			AND Contract = &Contract) AS TermsOfLeaseContracts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(&Date) AS LeasedAsset
	|WHERE
	|	LeasedAsset.Contract = &Contract
	|	AND LeasedAsset.State = VALUE(Enum.FixedAssetsStates.InLease)
	|
	|ORDER BY
	|	LeasedAsset.FixedAsset.Description,
	|	LeasedAsset.FixedAsset.AssetID";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("Date", ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));
	
	Result = Query.ExecuteBatch();
	
	If Result[Result.UBound()].IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result[0].Select();
	Selection.Next();
	
	FillPropertyValues(Object, Selection);
	
	Object.FA.Load(Result[Result.UBound()].Unload());
	
EndProcedure

// Fills in the document based on the FA inventory
//
// Parameters:
//  Object - DocumentObject.LeaseTermination - 
//  ReportErrors - Boolean - 
//  ArrayOfLineNumbers - Array	- 
//
Procedure FillInBasedOnInventory(Object, ReportErrors, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return;
	EndIf;
	
	DataToFill = Documents.FixedAssetsPhysicalCount.FillingDataBasedOnInventory24(
							Object.DocumentBasis,
							Object.Date, 
							Enums.ActionsBasedOnPhysicalInventoryCount.LeaseTermination, 
							ArrayOfLineNumbers);
							
	If DataToFill.Attributes = Undefined
		Or DataToFill.Attributes.Count() = 0
		Or DataToFill.TabularSection = Undefined 
		Or DataToFill.TabularSection.Count() = 0 Then
		
		If ReportErrors Then
			ErrorText = NStr("vi = 'Trong chứng từ %1 không có TSCĐ thuê nào cần phải chấm dứt hợp đồng thuê';
							|ru = 'В документе %1 отсутствуют арендованные ОС, для которых требуется прекратить договор аренды';
							|en = 'The document %1 does not contain leased fixed assets that require termination of the lease agreement'; fa = 'The document %1 does not contain leased fixed assets that require termination of the lease agreement';
							|it = 'The document %1 does not contain leased fixed assets that require termination of the lease agreement';
							|pl = 'The document %1 does not contain leased fixed assets that require termination of the lease agreement';
							|tr = '%1 belgesinde kira sözleşmesinin feshedilmesi gereken kiralanmış sabit kıymet bulunmuyor'");
			ErrorText = StrTemplate(ErrorText, Object.DocumentBasis);
			Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		EndIf;
		
		Return;
		
	EndIf;
	
	ManagedToFillIn = False;
	
	QueryText = 
	"SELECT TOP 1
	|	LeasedAsset.Contract
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(&Date, FixedAsset IN (&ListOfFA)) AS LeasedAsset
	|WHERE
	|	LeasedAsset.State IN (
	|		VALUE(Enum.FixedAssetsStates.LeaseContractsSigned),
	|		VALUE(Enum.FixedAssetsStates.InLease))";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("ListOfFA", DataToFill.TabularSection.UnloadColumn("FixedAsset"));
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
	
		Selection = Result.Select();
		Selection.Next();
		
		Object.Contract = Selection.Contract;
		
		Documents.LeaseTermination.FillInBasedOnLeaseAgreement(Object);
		ManagedToFillIn = (Object.FA.Count() <> 0);
		
	EndIf;
		
	If Not ManagedToFillIn And ReportErrors Then
		ErrorText = NStr("vi = 'Trong chứng từ %1 không có TSCĐ thuê nào cần phải chấm dứt hợp đồng thuê';
						|ru = 'В документе %1 отсутствуют арендованные ОС, для которых требуется прекратить договор аренды';
						|en = 'The document %1 does not contain leased fixed assets that require termination of the lease agreement'; fa = 'The document %1 does not contain leased fixed assets that require termination of the lease agreement';
						|it = 'The document %1 does not contain leased fixed assets that require termination of the lease agreement';
						|pl = 'The document %1 does not contain leased fixed assets that require termination of the lease agreement';
						|tr = '%1 belgesinde kira sözleşmesinin feshedilmesi gereken kiralanmış sabit kıymet bulunmuyor'");
		ErrorText = StrTemplate(ErrorText, Object.DocumentBasis);
		Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export

	ParametersList = New Array;
	
	#Region Expenses
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
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

#EndRegion

#EndRegion

#EndIf
