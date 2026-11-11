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
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");

	ChangeRentalTermsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ChangeRentalTerms") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableScheduleOfPaymentsForIncomeRentalServices(QueryTexts, Registers);
		QueryTextTableScheduleOfChargesForIncomeRentalServices(QueryTexts, Registers);
		QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts, Registers);
		
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		ChangeRentalTermsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

// Generates Registered Records of tables of operations "Calculating the cost of an investment in a lease".
//
// Parameters:
//  DocumentRef - DocumentRef.ProvideAssetsToLeasee2_4 - Document for which movements are generated
//  TempTablesManager	- TempTablesManager - Contains auxiliary temporary tables that can be used for forming movements.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfRegisteredRecordsWhenCalculatingCostOfInvestmentInLease(DocumentRef, TempTablesManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInInitializationParameters(Query, DocumentRef, Undefined);
	
	CalculateRentalInvestmentCost.SetRequestParameters(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");
	
	QueryTexts = New ValueList;
	
	CalculateRentalInvestmentCost.QueryTextTableOtherExpenses(QueryTexts);
	CalculateRentalInvestmentCost.QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts);
	QueryTextTableInvestmentInRent(Query, QueryTexts, Undefined);
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.TempTablesManager = TempTablesManager;
	AddlParameters.OnlyMarkedOnes = True;
	
	TablesForRegisteredRecords = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return TablesForRegisteredRecords;
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
EndProcedure

// Adds a command to create a document "the transfer of the asset in the lease."
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	
	If AccessRight("Insert", Metadata.Documents.ChangeRentalTerms) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ChangeRentalTerms.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ChangeRentalTerms);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "TransferToRentalSubleaseBasedOnRussianGAAPFSBU25";
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

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

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

#EndRegion


#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ChangeRentalTerms";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
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
										RedefiningParameterCalculation);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);

	CreateTTTableWithListOfDocuments(Query);
	GetDocumentData(Query);
	
	Query.Text =
	"SELECT
	|	DocumentData.Period  AS Period,
	|	DocumentData.Number   AS Number
	|FROM
	|	DocumentDataDetails AS DocumentData";
	
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

Procedure CreateTTTableWithListOfDocuments(Query)
	
	Query.Text =
	"SELECT
	|	DocumentsList.Ref AS Ref,
	|	DocumentsList.Organization AS Organization,
	|	DocumentsList.Date AS Period
	|INTO TTListOfDocuments
	|FROM
	|	Document.ChangeRentalTerms AS DocumentsList
	|WHERE
	|	DocumentsList.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	Query.Execute();
	
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
	|	DocumentData.Leaseholder AS Leaseholder,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Contract.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	VALUE(Enum.BusinessTransactions.ChangeRentalTerms) AS BusinessOperation
	|INTO DocumentDataDetails
	|FROM
	|	Document.ChangeRentalTerms AS DocumentData
	|WHERE
	|	DocumentData.Ref IN
	|			(SELECT
	|				TTListOfDocuments.Ref
	|			FROM
	|				TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.RentalPayments AS RentalPayments,
	|	DocumentTable.NonGuaranteedResidualValueLocal AS NonGuaranteedResidualValueLocal,
	|	DocumentTable.NonGuaranteedResidualValueManag AS NonGuaranteedResidualValueManag
	|INTO DocumentDataFATable
	|FROM
	|	Document.ChangeRentalTerms.FA AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN
	|			(SELECT
	|				TTListOfDocuments.Ref
	|			FROM
	|				TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableServicePaymentSchedule
	QueryText =
	"SELECT
	|	DocumentTable.Ref					AS Ref,
	|	DocumentTable.Date					AS Date,
	|	DocumentTable.FixedAsset		AS FixedAsset,
	|	DocumentTable.RentalService			AS RentalService,
	|	DocumentTable.RentalServiceVAT		AS RentalServiceVAT
	|
	|INTO DocumentDataTableServicePaymentSchedule
	|
	|FROM
	|	Document.ChangeRentalTerms.ServicePaymentSchedule AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableScheduleOfAccrualOfServices
	QueryText =
	"SELECT
	|	DocumentTable.Ref					AS Ref,
	|	DocumentTable.Date					AS Date,
	|	DocumentTable.FixedAsset		AS FixedAsset,
	|	DocumentTable.RentalService			AS RentalService,
	|	DocumentTable.RentalServiceVAT		AS RentalServiceVAT
	|
	|INTO DocumentDataTableScheduleOfAccrualOfServices
	|
	|FROM
	|	Document.ChangeRentalTerms.ServiceAccrualSchedule AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableScheduleOfAccrualOfInterest
	QueryText =
	"SELECT
	|	DocumentTable.Ref					AS Ref,
	|	DocumentTable.Date					AS Date,
	|	DocumentTable.FixedAsset		AS FixedAsset,
	|	DocumentTable.Interests				AS Interests
	|
	|INTO DocumentDataTableScheduleOfAccrualOfInterest
	|
	|FROM
	|	Document.ChangeRentalTerms.InterestAccrualSchedule AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
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
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ChangeRentalTerms"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Thay đổi điều kiện chuyển giao cho thuê';
															|ru = 'Изменение условий передачи в аренду';
															|en = 'Change rental terms'; fa = 'تغییر شرایط اجاره';
															|it = 'Изменение условий передачи в аренду';
															|pl = 'Change rental terms';
															|tr = 'Kira devir şartlarının değiştirilmesi'"));
	
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherIncomeExpenses",GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherAssetsAndLiabilities",GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	ValuesOfHoldingParameters.Insert("UseTraceableImportedGoodsAccounting",GetFunctionalOption("UseTraceableImportedGoodsAccounting"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());

	ValuesOfHoldingParameters.Insert("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());

	ValuesOfHoldingParameters.Insert("BO_ChangeRentalTerms",
		Enums.BusinessTransactions.ChangeRentalTerms);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ChangingTransferConditionsForRent",
		Catalogs.BusinessTransactionsSettings.ChangeRentalTerms);
		
	ValuesOfHoldingParameters.Insert("SettingUpHO_EnteringBalancesOfInvestmentInRent",
		Catalogs.BusinessTransactionsSettings.EnterRentalInvestmentBalance);
	ValuesOfHoldingParameters.Insert("BO_EnterRentalInvestmentBalance",
		Enums.BusinessTransactions.EnterRentalInvestmentBalance);
		
	ValuesOfHoldingParameters.Insert("SettingUpHO_SelectionOfNGLV", Catalogs.BusinessTransactionsSettings.DefineNonGuaranteedResidualValue);
	ValuesOfHoldingParameters.Insert("SettingUpHO_AccrualOfInterestOnProfitableLeases",
		Catalogs.BusinessTransactionsSettings.AccrueProfitableRentalInterest);

	ValuesOfHoldingParameters.Insert("HO_RevaluationOfFI", Enums.BusinessTransactions.RevaluationOfFinancialInstruments);
	ValuesOfHoldingParameters.Insert("SettingUpHO_RevaluationOfFI", Catalogs.BusinessTransactionsSettings.RevaluationOfFinancialInstruments);
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

#Region RequestTextsForConducting

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	DocumentData.Date             AS Date,
	|	DocumentData.Ref           AS Ref,
	|	DocumentData.Organization      AS Organization,
	|	DocumentData.Posted         AS Posted,
	|	VALUE(Enum.BusinessTransactions.ChangeRentalTerms) AS BusinessOperation,
	|	&MetadataIdentifier         AS RefType,
	|	FATable.FixedAsset       AS FixedAsset,
	|	FALSE                             AS AdditionalRecord
	|
	|FROM
	|	Document.ChangeRentalTerms AS DocumentData
	|
	|		LEFT JOIN Document.ChangeRentalTerms.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Leaseholder AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	VALUE(Enum.BusinessTransactions.ChangeRentalTerms) AS BusinessOperation,
	|	UNDEFINED AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	DocumentData.Date AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	DocumentData.Date   AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|
	|FROM
	|	Document.ChangeRentalTerms AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableScheduleOfPaymentsForIncomeRentalServices(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfPaymentsForIncomeRentalServices";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Period              AS ChangeDate,
	|	DocumentData.Contract             AS Contract,
	|	DocumentData.Ref              AS EffectiveContractTerms,
	|	ChartTable.Date                 AS Date,
	|	ChartTable.FixedAsset     AS FixedAsset,
	|	ChartTable.RentalService       AS RentalService,
	|	ChartTable.RentalServiceVAT    AS RentalServiceVAT
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataTableServicePaymentSchedule AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableScheduleOfChargesForIncomeRentalServices(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfChargesForIncomeRentalServices";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Period              AS ChangeDate,
	|	DocumentData.Contract             AS Contract,
	|	DocumentData.Ref              AS EffectiveContractTerms,
	|	ChartTable.Date                 AS Date,
	|	ChartTable.FixedAsset     AS FixedAsset,
	|	ChartTable.RentalService       AS RentalService,
	|	ChartTable.RentalServiceVAT    AS RentalServiceVAT
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataTableScheduleOfAccrualOfServices AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfInterestChargesOnIncomeRental";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Period              AS ChangeDate,
	|	DocumentData.Contract             AS Contract,
	|	DocumentData.Ref              AS EffectiveContractTerms,
	|	ChartTable.Date                 AS Date,
	|	ChartTable.FixedAsset     AS FixedAsset,
	|	ChartTable.Interests             AS Interests
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataTableScheduleOfAccrualOfInterest AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableInvestmentInRent(Query, QueryTexts, Registers)
	
	RegisterName = "InvestmentInRent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	QueryTextTableTTChangeOfPercentages(QueryTexts);
	
	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region AssignmentOfRentalInvestmentsToCHIA // Dr <58.AP> - Cr <58.VA>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Contract                AS Contract,
	|	DocumentData.ARAPCurrency   AS Currency,
	|	FATable.FixedAsset             AS FixedAsset,
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	0                                      AS RentalPayments,
	|	ExpenseAmount.LocalExpenses              AS RentalPaymentsLocal,
	|	ExpenseAmount.ManSExpenses               AS RentalPaymentsManag,
	|	0                                      AS NonGuaranteedResidualValueLocal,
	|	0                                      AS NonGuaranteedResidualValueManag,
	|	0                                      AS InterestDiscount,
	|	0                                      AS InterestDiscountLocal,
	|	0                                      AS InterestDiscountMan,
	|	&SettingUpHO_ChangingTransferConditionsForRent AS BusinessTransactionSetting,
	|	FATable.RowID                AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN ExpenseAmount AS ExpenseAmount
	|		ON FATable.FixedAsset = ExpenseAmount.FixedAsset
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region RecalculationOfInterestOnNewTerms // Dr <58.AP> - Cr <58.%>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Contract                AS Contract,
	|	DocumentData.ARAPCurrency   AS Currency,
	|	FATable.FixedAsset             AS FixedAsset,
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	0                                      AS RentalPayments,
	|	0                                      AS RentalPaymentsLocal,
	|	0                                      AS RentalPaymentsManag,
	|	0                                      AS NonGuaranteedResidualValueLocal,
	|	0                                      AS NonGuaranteedResidualValueManag,
	|	InterestChange.Sum               AS InterestDiscount,
	|	InterestChange.SumCompl           AS InterestDiscountLocal,
	|	InterestChange.SumMan            AS InterestDiscountMan,
	|	&SettingUpHO_AccrualOfInterestOnProfitableLeases AS BusinessTransactionSetting,
	|	FATable.RowID          AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTChangeOfPercentages AS InterestChange
	|		ON FATable.FixedAsset = InterestChange.FixedAsset
	|		AND DocumentData.Ref = InterestChange.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = &BO_ChangeRentalTerms
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Contract                AS Contract,
	|	DocumentData.ARAPCurrency   AS Currency,
	|	FATable.FixedAsset             AS FixedAsset,
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	DataFA.ChangeInLeasePayments     AS RentalPayments,
	|	InterestChange.SumCompl           AS RentalPaymentsLocal,
	|	InterestChange.SumMan            AS RentalPaymentsManag,
	|	0                                      AS NonGuaranteedResidualValueLocal,
	|	0                                      AS NonGuaranteedResidualValueManag,
	|	0                                      AS InterestDiscount,
	|	0                                      AS InterestDiscountLocal,
	|	0                                      AS InterestDiscountMan,
	|	&SettingUpHO_AccrualOfInterestOnProfitableLeases AS BusinessTransactionSetting,
	|	FATable.RowID          AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTChangeOfPercentages AS InterestChange
	|		ON FATable.FixedAsset = InterestChange.FixedAsset
	|		AND DocumentData.Ref = InterestChange.Ref
	|
	|		INNER JOIN DataFA AS DataFA
	|		ON FATable.FixedAsset = DataFA.FixedAsset
	|		AND DocumentData.Ref = DataFA.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = &BO_ChangeRentalTerms
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region DefineNonGuaranteedResidualValue // Dr <58.NGLS> - Cr <58.AP>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	DocumentData.Ref                              AS Recorder,
	|	DocumentData.Period                              AS Period,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Contract                             AS Contract,
	|	DocumentData.ARAPCurrency                AS Currency,
	|	FATable.FixedAsset                          AS FixedAsset,
	|	FATable.FinancialAccountingGroup                    AS FinancialAccountingGroup,
	|	0                                                   AS RentalPayments,
	|	ISNULL(DataFA.NonGuaranteedResidualValueLocal, 0)                      AS RentalPaymentsLocal,
	|	ISNULL(DataFA.NonGuaranteedResidualValueManag, 0)                       AS RentalPaymentsManag,
	|	0                                                   AS NonGuaranteedResidualValueLocal,
	|	0                                                   AS NonGuaranteedResidualValueManag,
	|	0                                                   AS InterestDiscount,
	|	0                                                   AS InterestDiscountMan,
	|	0                                                   AS InterestDiscountLocal,
	|	&SettingUpHO_SelectionOfNGLV                          AS BusinessTransactionSetting,
	|	FATable.RowID                       AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|	INNER JOIN TTFATable AS FATable
	|	 ON FATable.Ref = DocumentData.Ref
	|
	|	LEFT JOIN DataFA AS DataFA
	|	 ON FATable.FixedAsset = DataFA.FixedAsset
	|	 AND DocumentData.Ref = DataFA.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = &BO_ChangeRentalTerms
	|	AND (ISNULL(DataFA.NonGuaranteedResidualValueLocal, 0) <> 0
	|		OR ISNULL(DataFA.NonGuaranteedResidualValueManag, 0) <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	DocumentData.Ref                              AS Recorder,
	|	DocumentData.Period                              AS Period,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Contract                             AS Contract,
	|	DocumentData.ARAPCurrency                AS Currency,
	|	FATable.FixedAsset                          AS FixedAsset,
	|	FATable.FinancialAccountingGroup                    AS FinancialAccountingGroup,
	|	0                                                   AS RentalPayments,
	|	0                                                   AS RentalPaymentsLocal,
	|	0                                                   AS RentalPaymentsManag,
	|	ISNULL(DataFA.NonGuaranteedResidualValueLocal, 0)                      AS NonGuaranteedResidualValueLocal,
	|	ISNULL(DataFA.NonGuaranteedResidualValueManag, 0)                       AS NonGuaranteedResidualValueManag,
	|	0                                                   AS InterestDiscount,
	|	0                                                   AS InterestDiscountMan,
	|	0                                                   AS InterestDiscountLocal,
	|	&SettingUpHO_SelectionOfNGLV                          AS BusinessTransactionSetting,
	|	FATable.RowID                       AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|	INNER JOIN TTFATable AS FATable
	|	 ON FATable.Ref = DocumentData.Ref
	|
	|	LEFT JOIN DataFA AS DataFA
	|	 ON FATable.FixedAsset = DataFA.FixedAsset
	|	 AND DocumentData.Ref = DataFA.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = &BO_ChangeRentalTerms
	|	AND (ISNULL(DataFA.NonGuaranteedResidualValueLocal, 0) <> 0
	|		OR ISNULL(DataFA.NonGuaranteedResidualValueManag, 0) <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

#EndRegion

#Region GenerationOfTemporaryTablesForPosting

Procedure QueryTextTableTTFATable(QueryTexts)
	
	TableName = "TTFATable";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	QueryTextTableTTCurrencyConversionFactors(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	FAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.NonGuaranteedResidualValueLocal AS NonGuaranteedResidualValueLocal,
	|	FATable.NonGuaranteedResidualValueManag AS NonGuaranteedResidualValueManag,
	|	FATable.RentalPayments AS RentalPayments,
	|	CAST(FATable.RentalPayments * ISNULL(Coefficients.LocalConversionRatio, 0) AS NUMBER(31, 2)) AS RentalPaymentsLocal,
	|	CAST(FATable.RentalPayments * ISNULL(Coefficients.ManConversionFactor, 0) AS NUMBER(31, 2)) AS RentalPaymentsManag,
	|	FATable.RowID AS RowID
	|INTO TTFATable
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|		INNER JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON DocumentData.Ref = FAAccountingParameters.Ref
	|		AND FATable.FixedAsset = FAAccountingParameters.FixedAsset
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON (Coefficients.Date = DocumentData.Period)
	|			AND (Coefficients.Organization = DocumentData.Organization)
	|			AND (Coefficients.ARAPCurrency = DocumentData.ARAPCurrency)
	|
	|INDEX BY
	|	Ref,
	|	RowID,
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTInterestOnSchedule(QueryTexts)
	
	TableName = "TTInterestOnSchedule";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Period AS Period,
	|	InterestAccrualSchedule.FixedAsset AS FixedAsset,
	|	SUM(InterestAccrualSchedule.Interests) AS Sum
	|INTO TTInterestOnSchedule
	|FROM
	|	TableScheduleOfAccrualOfInterest AS InterestAccrualSchedule
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON (DocumentData.Ref = InterestAccrualSchedule.Ref)
	|			AND (DocumentData.Period <= InterestAccrualSchedule.Date)
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Organization,
	|	DocumentData.Period,
	|	InterestAccrualSchedule.FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTChangeOfPercentages(QueryTexts)
	
	TableName = "TTChangeOfPercentages";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTCurrencyConversionFactors(QueryTexts);
	QueryTextTableTTInterestOnSchedule(QueryTexts);
	
	QueryText =
	"SELECT
	|	TTInterestOnSchedule.Ref AS Ref,
	|	TTInterestOnSchedule.FixedAsset AS FixedAsset,
	|	TTInterestOnSchedule.Sum - ISNULL(TTInterestBalances.InterestDiscount, 0) AS Sum,
	|	(TTInterestOnSchedule.Sum - ISNULL(TTInterestBalances.InterestDiscount, 0))
	|		* ISNULL(Coefficients.LocalConversionRatio, 0) AS SumCompl,
	|	(TTInterestOnSchedule.Sum - ISNULL(TTInterestBalances.InterestDiscount, 0))
	|		* ISNULL(Coefficients.ManConversionFactor, 0) AS SumMan
	|INTO TTChangeOfPercentages
	|FROM
	|	TTInterestOnSchedule AS TTInterestOnSchedule
	|		LEFT JOIN InterestBeforeChange AS TTInterestBalances
	|		ON TTInterestOnSchedule.FixedAsset = TTInterestBalances.FixedAsset
	|			AND TTInterestOnSchedule.Ref = TTInterestBalances.Ref
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON Coefficients.Organization = TTInterestOnSchedule.Organization
	|			AND Coefficients.Date = TTInterestOnSchedule.Period
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset";

	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTCurrencyConversionFactors(QueryTexts)

	TableName = "TTCurrencyConversionFactors";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Period AS Date
	|INTO PeriodsTable
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|INDEX BY
	|	Organization,
	|	ARAPCurrency,
	|	Date";
	QueryTexts.Add(QueryText, "PeriodsTable");
	
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts, TableName, True);

EndProcedure

#EndRegion

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return ChangeRentalTermsLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

Function TextOfReflectionInLocalAccounting() Export
	
	Return ChangeRentalTermsLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

#EndRegion

#Region Print

// Adds print commands.
// 
// Parameters:
// 	PrintCommands - See PrintManagement.CreatePrintCommandsCollection
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#Region Other

// Filling in based on the Contract of the counterparty
//
// Parameters:
//  Object - DocumentObject.ChangeRentalTerms
//  Contract - CatalogRef.CounterpartyContracts
//
Procedure FillInBasedOnAgreement(Object, Contract) Export
	
	QueryPackageTexts = New Array;

	QueryText = 
	"SELECT
	|	AssetsLeasedOut.FixedAsset AS FixedAsset
	|INTO TTLeased
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(
	|			&PeriodLimit,
	|			Organization = &Organization) AS AssetsLeasedOut
	|WHERE
	|	AssetsLeasedOut.Contract = &Contract
	|	AND AssetsLeasedOut.State IN (VALUE(Enum.FixedAssetsStates.LeasedOut))
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvestmentInRentBalance.FixedAsset AS FixedAsset,
	|	InvestmentInRentBalance.NonGuaranteedResidualValueLocalBalance AS NonGuaranteedResidualValueLocalBalance,
	|	InvestmentInRentBalance.NonGuaranteedResidualValueManagBalance AS NonGuaranteedResidualValueManagBalance
	|INTO TTInvestmentsBalance
	|FROM
	|	AccumulationRegister.InvestmentInRent.Balance(
	|			&PeriodLimit,
	|			Organization = &Organization
	|				AND Contract = &Contract
	|				AND FixedAsset IN
	|					(SELECT
	|						TTLeased.FixedAsset AS FixedAsset
	|					FROM
	|						TTLeased AS TTLeased)) AS InvestmentInRentBalance
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedule.EffectiveContractTerms AS EffectiveContractTerms,
	|	PaymentSchedule.FixedAsset AS FixedAsset,
	|	PaymentSchedule.Date AS Date,
	|	PaymentSchedule.RentalService AS RentalService,
	|	PaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|	PaymentSchedule.ChangeDate AS ChangeDate
	|INTO TTPaymentsSchedule
	|FROM
	|	InformationRegister.ScheduleOfPaymentsForIncomeRentalServices AS PaymentSchedule
	|WHERE
	|	PaymentSchedule.Contract = &Contract
	|	AND PaymentSchedule.FixedAsset IN
	|			(SELECT
	|				TTLeased.FixedAsset AS FixedAsset
	|			FROM
	|				TTLeased AS TTLeased)
	|	AND PaymentSchedule.ChangeDate < &Date
	|	AND PaymentSchedule.Active
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentsSchedule.FixedAsset AS FixedAsset,
	|	MAX(TTPaymentsSchedule.ChangeDate) AS ChangeDate
	|INTO TTPaymentSchedulePeriod
	|FROM
	|	TTPaymentsSchedule AS TTPaymentsSchedule
	|
	|GROUP BY
	|	TTPaymentsSchedule.FixedAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentsSchedule.EffectiveContractTerms AS EffectiveContractTerms,
	|	TTPaymentsSchedule.FixedAsset AS FixedAsset,
	|	TTPaymentsSchedule.Date AS Date,
	|	TTPaymentsSchedule.RentalService AS RentalService,
	|	TTPaymentsSchedule.RentalServiceVAT AS RentalServiceVAT
	|INTO TTCurrentPaymentSchedule
	|
	|FROM
	|	TTPaymentsSchedule AS TTPaymentsSchedule
	|		INNER JOIN TTPaymentSchedulePeriod AS TTPaymentSchedulePeriod
	|		ON TTPaymentsSchedule.FixedAsset = TTPaymentSchedulePeriod.FixedAsset
	|			AND TTPaymentsSchedule.ChangeDate = TTPaymentSchedulePeriod.ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentsSchedule.EffectiveContractTerms AS EffectiveContractTerms,
	|	TTPaymentsSchedule.FixedAsset AS FixedAsset
	|INTO CurrentTermsOfContractTT
	|
	|FROM
	|	TTCurrentPaymentSchedule AS TTPaymentsSchedule
	|
	|GROUP BY
	|	TTPaymentsSchedule.EffectiveContractTerms,
	|	TTPaymentsSchedule.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RentalDates.FixedAsset AS FixedAsset,
	|	MAX(RentalDates.RentalEndDate) AS RentalEndDate
	|INTO TTOfRentalDate
	|FROM
	|	(SELECT
	|		ProvideAssetsToLeasee2_4FA.FixedAsset AS FixedAsset,
	|		ProvideAssetsToLeasee2_4FA.RentalEndDate AS RentalEndDate
	|	FROM
	|		Document.ProvideAssetsToLeasee2_4.FA AS ProvideAssetsToLeasee2_4FA
	|	WHERE
	|		(ProvideAssetsToLeasee2_4FA.Ref, ProvideAssetsToLeasee2_4FA.FixedAsset) IN
	|				(SELECT
	|					CurrentTermsOfContractTT.EffectiveContractTerms AS EffectiveContractTerms,
	|					CurrentTermsOfContractTT.FixedAsset AS FixedAsset
	|				FROM
	|					CurrentTermsOfContractTT AS CurrentTermsOfContractTT)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ChangeRentalTermsFA.FixedAsset,
	|		ChangeRentalTermsFA.RentalEndDate
	|	FROM
	|		Document.ChangeRentalTerms.FA AS ChangeRentalTermsFA
	|	WHERE
	|		(ChangeRentalTermsFA.Ref, ChangeRentalTermsFA.FixedAsset) IN
	|				(SELECT
	|					CurrentTermsOfContractTT.EffectiveContractTerms AS EffectiveContractTerms,
	|					CurrentTermsOfContractTT.FixedAsset AS FixedAsset
	|				FROM
	|					CurrentTermsOfContractTT AS CurrentTermsOfContractTT)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		EnterRentalInvestmentBalanceFA.FixedAsset,
	|		EnterRentalInvestmentBalanceFA.RentalEndDate
	|	FROM
	|		Document.EnterRentalInvestmentBalance.FA AS EnterRentalInvestmentBalanceFA
	|	WHERE
	|		(EnterRentalInvestmentBalanceFA.Ref, EnterRentalInvestmentBalanceFA.FixedAsset) IN
	|				(SELECT
	|					CurrentTermsOfContractTT.EffectiveContractTerms AS EffectiveContractTerms,
	|					CurrentTermsOfContractTT.FixedAsset AS FixedAsset
	|				FROM
	|					CurrentTermsOfContractTT AS CurrentTermsOfContractTT)) AS RentalDates
	|
	|GROUP BY
	|	RentalDates.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleOfAccrual.FixedAsset AS FixedAsset,
	|	ScheduleOfAccrual.Date AS Date,
	|	ScheduleOfAccrual.RentalService AS RentalService,
	|	ScheduleOfAccrual.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleOfAccrual.ChangeDate AS ChangeDate
	|INTO TTAccrualSchedule
	|FROM
	|	InformationRegister.ScheduleOfChargesForIncomeRentalServices AS ScheduleOfAccrual
	|WHERE
	|	ScheduleOfAccrual.Contract = &Contract
	|	AND ScheduleOfAccrual.FixedAsset IN
	|			(SELECT
	|				TTLeased.FixedAsset AS FixedAsset
	|			FROM
	|				TTLeased AS TTLeased)
	|	AND ScheduleOfAccrual.ChangeDate < &Date
	|	AND ScheduleOfAccrual.Active
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccrualSchedule.FixedAsset AS FixedAsset,
	|	MAX(TTAccrualSchedule.ChangeDate) AS ChangeDate
	|INTO AccrualScheduleIsTTForPeriod
	|FROM
	|	TTAccrualSchedule AS TTAccrualSchedule
	|
	|GROUP BY
	|	TTAccrualSchedule.FixedAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InterestGraph.FixedAsset AS FixedAsset,
	|	InterestGraph.Date AS Date,
	|	InterestGraph.Interests AS Interests,
	|	InterestGraph.ChangeDate AS ChangeDate
	|INTO TTInterestGraph
	|FROM
	|	InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS InterestGraph
	|WHERE
	|	InterestGraph.Contract = &Contract
	|	AND InterestGraph.FixedAsset IN
	|			(SELECT
	|				TTLeased.FixedAsset AS FixedAsset
	|			FROM
	|				TTLeased AS TTLeased)
	|	AND InterestGraph.ChangeDate < &Date
	|	AND InterestGraph.Active
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInterestGraph.FixedAsset AS FixedAsset,
	|	MAX(TTInterestGraph.ChangeDate) AS ChangeDate
	|INTO TTInterestChartPeriod
	|FROM
	|	TTInterestGraph AS TTInterestGraph
	|
	|GROUP BY
	|	TTInterestGraph.FixedAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTLeased.FixedAsset AS FixedAsset,
	|	ISNULL(TTOfRentalDate.RentalEndDate, DATETIME(1,1,1)) AS RentalEndDate,
	|	ISNULL(TTInvestmentsBalance.NonGuaranteedResidualValueLocalBalance, 0) AS NonGuaranteedResidualValueLocal,
	|	ISNULL(TTInvestmentsBalance.NonGuaranteedResidualValueManagBalance, 0) AS NonGuaranteedResidualValueManag
	|FROM
	|	TTLeased AS TTLeased
	|		LEFT JOIN TTInvestmentsBalance AS TTInvestmentsBalance
	|		ON TTLeased.FixedAsset = TTInvestmentsBalance.FixedAsset
	|		LEFT JOIN TTOfRentalDate AS TTOfRentalDate
	|		ON TTLeased.FixedAsset = TTOfRentalDate.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentsSchedule.FixedAsset AS FixedAsset,
	|	TTPaymentsSchedule.Date AS Date,
	|	TTPaymentsSchedule.RentalService AS RentalService,
	|	TTPaymentsSchedule.RentalServiceVAT AS RentalServiceVAT
	|FROM
	|	TTCurrentPaymentSchedule AS TTPaymentsSchedule
	|
	|ORDER BY
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccrualSchedule.FixedAsset AS FixedAsset,
	|	TTAccrualSchedule.Date AS Date,
	|	TTAccrualSchedule.RentalService AS RentalService,
	|	TTAccrualSchedule.RentalServiceVAT AS RentalServiceVAT
	|FROM
	|	TTAccrualSchedule AS TTAccrualSchedule
	|		INNER JOIN AccrualScheduleIsTTForPeriod AS AccrualScheduleIsTTForPeriod
	|		ON TTAccrualSchedule.FixedAsset = AccrualScheduleIsTTForPeriod.FixedAsset
	|			AND TTAccrualSchedule.ChangeDate = AccrualScheduleIsTTForPeriod.ChangeDate
	|
	|ORDER BY
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInterestGraph.FixedAsset AS FixedAsset,
	|	TTInterestGraph.Date AS Date,
	|	TTInterestGraph.Interests AS Interests
	|FROM
	|	TTInterestGraph AS TTInterestGraph
	|		INNER JOIN TTInterestChartPeriod AS TTInterestChartPeriod
	|		ON TTInterestGraph.FixedAsset = TTInterestChartPeriod.FixedAsset
	|			AND TTInterestGraph.ChangeDate = TTInterestChartPeriod.ChangeDate
	|
	|ORDER BY
	|	Date";
	QueryPackageTexts.Add(QueryText);
	
	DocDate = ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate());
	PeriodLimit = New Boundary(New PointInTime(DocDate, Object.Ref), BoundaryType.Excluding);
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("Date", BegOfDay(DocDate));
	Query.SetParameter("PeriodLimit", PeriodLimit);
	
	Result = Query.ExecuteBatch();
	If Result[0].IsEmpty() Then
		Return;
	EndIf;
	
	Object.FA.Load(Result[Result.UBound()-3].Unload());
	Object.ServicePaymentSchedule.Load(Result[Result.UBound()-2].Unload());
	Object.ServiceAccrualSchedule.Load(Result[Result.UBound()-1].Unload());
	Object.InterestAccrualSchedule.Load(Result[Result.UBound()].Unload());
	
EndProcedure

// Filling in on the basis of the document Change of the terms and conditions of the lease agreement
//
// Parameters:
//  Object - DocumentObject.ChangeRentalTerms
//  Basis - DocumentRef.LeaseTermAdjustment
//
Procedure FillInOnBasisOfRentalTermsADJUSTMENTChanges(Object, Basis) Export
	
	Object.DocumentBasis = Basis;
	Object.FA.Clear();
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1 ALLOWED
		|	CounterpartyContracts.Ref AS Contract,
		|	CounterpartyContracts.Organization AS Organization,
		|	CounterpartyContracts.Department AS Department,
		|	CounterpartyContracts.Counterparty AS Leaseholder
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.LeaseContracts = &LeaseContracts
		|	AND CounterpartyContracts.Organization = &Organization
		|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|	AND NOT CounterpartyContracts.DeletionMark";
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "Contract, Organization");
	Query.SetParameter("LeaseContracts", DetailsOfFoundation.Contract);
	Query.SetParameter("Organization", DetailsOfFoundation.Organization);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		FillPropertyValues(Object, Selection);
		Documents.ChangeRentalTerms.FillInBasedOnAgreement(Object, Selection.Contract);
	EndIf;
	
EndProcedure

// Deletes rows before the date of the lease change
//
// Parameters:
//  FATable - FormDataCollection
//  ServicePaymentSchedule - FormDataCollection
//  ServiceAccrualSchedule - FormDataCollection
//  InterestAccrualSchedule - FormDataCollection
//  Date - Date
//
Procedure DeleteIrrelevantGraphLines(FATable, ServicePaymentSchedule, ServiceAccrualSchedule, InterestAccrualSchedule, Date) Export
	
	Query = New Query;
	Query.SetParameter("FAArray", FATable.Unload().UnloadColumn("FixedAsset"));
	Query.SetParameter("ServicePaymentSchedule", ServicePaymentSchedule.Unload());
	Query.SetParameter("ServiceAccrualSchedule", ServiceAccrualSchedule.Unload());
	Query.SetParameter("InterestAccrualSchedule", InterestAccrualSchedule.Unload());
	Query.SetParameter("Period", BegOfDay(Date));

	Query.Text =
	"SELECT
	|	ServicePaymentSchedule.Date AS Date,
	|	ServicePaymentSchedule.FixedAsset AS FixedAsset
	|INTO TTLinesOfPaymentSchedule
	|FROM
	|	&ServicePaymentSchedule AS ServicePaymentSchedule
	|WHERE
	|	(NOT ServicePaymentSchedule.FixedAsset IN (&FAArray)
	|			OR ServicePaymentSchedule.Date < &Period)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServiceAccrualSchedule.Date AS Date,
	|	ServiceAccrualSchedule.FixedAsset AS FixedAsset
	|INTO AccrualTTLinesOfSchedule
	|FROM
	|	&ServiceAccrualSchedule AS ServiceAccrualSchedule
	|WHERE
	|	(NOT ServiceAccrualSchedule.FixedAsset IN (&FAArray)
	|			OR ServiceAccrualSchedule.Date < &Period)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InterestAccrualSchedule.Date AS Date,
	|	InterestAccrualSchedule.FixedAsset AS FixedAsset
	|INTO TTLinesOfPercentGraph
	|FROM
	|	&InterestAccrualSchedule AS InterestAccrualSchedule
	|WHERE
	|	(NOT InterestAccrualSchedule.FixedAsset IN (&FAArray)
	|			OR InterestAccrualSchedule.Date <= ENDOFPERIOD(&Period, MONTH))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentScheduleRows.Date AS Date,
	|	PaymentScheduleRows.FixedAsset AS FixedAsset
	|FROM
	|	TTLinesOfPaymentSchedule AS PaymentScheduleRows
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualScheduleLines.Date AS Date,
	|	AccrualScheduleLines.FixedAsset AS FixedAsset
	|FROM
	|	AccrualTTLinesOfSchedule AS AccrualScheduleLines
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LinesOfPercentGraph.Date AS Date,
	|	LinesOfPercentGraph.FixedAsset AS FixedAsset
	|FROM
	|	TTLinesOfPercentGraph AS LinesOfPercentGraph";

	QueryResults = Query.ExecuteBatch();

	FilterStructure1 = New Structure("FixedAsset, Date");

	PaymentResult = QueryResults[QueryResults.UBound()-2];
	If Not PaymentResult.IsEmpty() Then
		Selection = PaymentResult.Select();
		While Selection.Next() Do
			FillPropertyValues(FilterStructure1, Selection);
			FoundGraphLines = ServicePaymentSchedule.FindRows(FilterStructure1);
			For Each PlotLine In FoundGraphLines Do
				ServicePaymentSchedule.Delete(PlotLine);
			EndDo;
		EndDo;
	EndIf;

	AccrualResult = QueryResults[QueryResults.UBound()-1];
	If Not AccrualResult.IsEmpty() Then
		Selection = AccrualResult.Select();
		While Selection.Next() Do
			FillPropertyValues(FilterStructure1, Selection);
			FoundGraphLines = ServiceAccrualSchedule.FindRows(FilterStructure1);
			For Each PlotLine In FoundGraphLines Do
				ServiceAccrualSchedule.Delete(PlotLine);
			EndDo;
		EndDo;
	EndIf;

	ResultPercentages = QueryResults[QueryResults.UBound()];
	If Not ResultPercentages.IsEmpty() Then
		Selection = ResultPercentages.Select();
		While Selection.Next() Do
			FillPropertyValues(FilterStructure1, Selection);
			FoundGraphLines = InterestAccrualSchedule.FindRows(FilterStructure1);
			For Each PlotLine In FoundGraphLines Do
				InterestAccrualSchedule.Delete(PlotLine);
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

// Fills in the lines of the charts before the date of the lease change under the previous conditions
//
// Parameters:
//  FATable - FormDataCollection
//  ServicePaymentSchedule - FormDataCollection
//  ServiceAccrualSchedule - FormDataCollection
//  InterestAccrualSchedule - FormDataCollection
//  Contract - CatalogRef.CounterpartyContracts
//  Date - Date
//
Procedure AddChartsBasedOnPreviousConditions(FATable, ServicePaymentSchedule, ServiceAccrualSchedule, InterestAccrualSchedule, Contract, Date) Export
	
	Query = New Query;
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("FAArray", FATable.Unload().UnloadColumn("FixedAsset"));
	Query.SetParameter("Date", BegOfDay(Date));
	
	Query.Text = 
	"SELECT
	|	PaymentSchedule.FixedAsset AS FixedAsset,
	|	PaymentSchedule.Date AS Date,
	|	PaymentSchedule.RentalService AS RentalService,
	|	PaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|	PaymentSchedule.ChangeDate AS ChangeDate
	|INTO TTPaymentsSchedule
	|FROM
	|	InformationRegister.ScheduleOfPaymentsForIncomeRentalServices AS PaymentSchedule
	|WHERE
	|	PaymentSchedule.Contract = &Contract
	|	AND PaymentSchedule.FixedAsset IN (&FAArray)
	|	AND PaymentSchedule.Date < &Date
	|	AND PaymentSchedule.ChangeDate < &Date
	|	AND PaymentSchedule.Active
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentsSchedule.FixedAsset AS FixedAsset,
	|	MAX(TTPaymentsSchedule.ChangeDate) AS ChangeDate
	|INTO TTPaymentSchedulePeriod
	|FROM
	|	TTPaymentsSchedule AS TTPaymentsSchedule
	|
	|GROUP BY
	|	TTPaymentsSchedule.FixedAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleOfAccrual.FixedAsset AS FixedAsset,
	|	ScheduleOfAccrual.Date AS Date,
	|	ScheduleOfAccrual.RentalService AS RentalService,
	|	ScheduleOfAccrual.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleOfAccrual.ChangeDate AS ChangeDate
	|INTO TTAccrualSchedule
	|FROM
	|	InformationRegister.ScheduleOfChargesForIncomeRentalServices AS ScheduleOfAccrual
	|WHERE
	|	ScheduleOfAccrual.Contract = &Contract
	|	AND ScheduleOfAccrual.FixedAsset IN (&FAArray)
	|	AND ScheduleOfAccrual.Date < &Date
	|	AND ScheduleOfAccrual.ChangeDate < &Date
	|	AND ScheduleOfAccrual.Active
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccrualSchedule.FixedAsset AS FixedAsset,
	|	MAX(TTAccrualSchedule.ChangeDate) AS ChangeDate
	|INTO AccrualScheduleIsTTForPeriod
	|FROM
	|	TTAccrualSchedule AS TTAccrualSchedule
	|
	|GROUP BY
	|	TTAccrualSchedule.FixedAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InterestGraph.FixedAsset AS FixedAsset,
	|	InterestGraph.Date AS Date,
	|	InterestGraph.Interests AS Interests,
	|	InterestGraph.ChangeDate AS ChangeDate
	|INTO TTInterestGraph
	|FROM
	|	InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS InterestGraph
	|WHERE
	|	InterestGraph.Contract = &Contract
	|	AND InterestGraph.FixedAsset IN (&FAArray)
	|	AND InterestGraph.Date <= ENDOFPERIOD(&Date, MONTH)
	|	AND InterestGraph.ChangeDate < &Date
	|	AND InterestGraph.Active
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInterestGraph.FixedAsset AS FixedAsset,
	|	MAX(TTInterestGraph.ChangeDate) AS ChangeDate
	|INTO TTInterestChartPeriod
	|FROM
	|	TTInterestGraph AS TTInterestGraph
	|
	|GROUP BY
	|	TTInterestGraph.FixedAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentsSchedule.FixedAsset AS FixedAsset,
	|	TTPaymentsSchedule.Date AS Date,
	|	TTPaymentsSchedule.RentalService AS RentalService,
	|	TTPaymentsSchedule.RentalServiceVAT AS RentalServiceVAT
	|FROM
	|	TTPaymentsSchedule AS TTPaymentsSchedule
	|		INNER JOIN TTPaymentSchedulePeriod AS TTPaymentSchedulePeriod
	|		ON TTPaymentsSchedule.FixedAsset = TTPaymentSchedulePeriod.FixedAsset
	|			AND TTPaymentsSchedule.ChangeDate = TTPaymentSchedulePeriod.ChangeDate
	|
	|ORDER BY
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccrualSchedule.FixedAsset AS FixedAsset,
	|	TTAccrualSchedule.Date AS Date,
	|	TTAccrualSchedule.RentalService AS RentalService,
	|	TTAccrualSchedule.RentalServiceVAT AS RentalServiceVAT
	|FROM
	|	TTAccrualSchedule AS TTAccrualSchedule
	|		INNER JOIN AccrualScheduleIsTTForPeriod AS AccrualScheduleIsTTForPeriod
	|		ON TTAccrualSchedule.FixedAsset = AccrualScheduleIsTTForPeriod.FixedAsset
	|			AND TTAccrualSchedule.ChangeDate = AccrualScheduleIsTTForPeriod.ChangeDate
	|
	|ORDER BY
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInterestGraph.FixedAsset AS FixedAsset,
	|	TTInterestGraph.Date AS Date,
	|	TTInterestGraph.Interests AS Interests
	|FROM
	|	TTInterestGraph AS TTInterestGraph
	|		INNER JOIN TTInterestChartPeriod AS TTInterestChartPeriod
	|		ON TTInterestGraph.FixedAsset = TTInterestChartPeriod.FixedAsset
	|			AND TTInterestGraph.ChangeDate = TTInterestChartPeriod.ChangeDate
	|
	|ORDER BY
	|	Date";
	
	QueryResults = Query.ExecuteBatch();
	
	PaymentResult = QueryResults[QueryResults.UBound()-2];
	If Not PaymentResult.IsEmpty() Then
		Selection = PaymentResult.Select();
		While Selection.Next() Do
			PlotLine = ServicePaymentSchedule.Add();
			FillPropertyValues(PlotLine, Selection);
		EndDo;
		ServicePaymentSchedule.Sort("FixedAsset, Date");
	EndIf;
	
	AccrualResult = QueryResults[QueryResults.UBound()-1];
	If Not AccrualResult.IsEmpty() Then
		Selection = AccrualResult.Select();
		While Selection.Next() Do
			PlotLine = ServiceAccrualSchedule.Add();
			FillPropertyValues(PlotLine, Selection);
		EndDo;
		ServiceAccrualSchedule.Sort("FixedAsset, Date");
	EndIf;
	
	ResultPercentages = QueryResults[QueryResults.UBound()];
	If Not ResultPercentages.IsEmpty() Then
		Selection = ResultPercentages.Select();
		While Selection.Next() Do
			PlotLine = InterestAccrualSchedule.Add();
			FillPropertyValues(PlotLine, Selection);
		EndDo;
		InterestAccrualSchedule.Sort("FixedAsset, Date");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
