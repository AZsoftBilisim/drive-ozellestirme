
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
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("ImpairmentFA");
	
	PreparingForFixedAssetSaleLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.PreparingForFixedAssetSale2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableAssetsLeasedOut(QueryTexts, Registers);	
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		PreparingForFixedAssetSaleLocalization.AddRequestTexts(Query, QueryTexts, Registers);

	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  TempTablesManager - TempTablesManager - Contains temporary tables that are used in the formation of Registered Records.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfDeferredMotionFormation(TempTablesManager) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	GetDocumentData(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	QueryTexts = New ValueList;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	
	QueryTextTableFACost(Query, QueryTexts);
	QueryTextTableFixedAssetsDepreciationCharge(QueryTexts);
	QueryTextTableImpairmentFA(QueryTexts);
	QueryTextTableAssetsLeasedOut(QueryTexts, Undefined);
	QueryTextTableOtherExpenses(QueryTexts);
	QueryTextTableOtherAssetsLiabilities(QueryTexts);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	PreparingForFixedAssetSaleLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
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
	
	Documents.CustomerInvoiceServicesAndAssets.AddGenerateCommand(GenerationCommands);
	
	PreparingForFixedAssetSaleLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command creation of the document "preparations for the transfer of the OS".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.PreparingForFixedAssetSale2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PreparingForFixedAssetSale2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PreparingForFixedAssetSale2_4);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
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
	
	PreparingForFixedAssetSaleLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#EndRegion

#Region VATAccounting

// Initializes parameters for filling in sales VAT taxation
//
// Parameters:
//  Object - DocumentObject.PreparingForFixedAssetSale2_4, DocumentRef.PreparingForFixedAssetSale2_4, FormDataStructure - the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.OtherAssetSale = True;

	Return FillParameters;
	
EndFunction

#EndRegion

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
	
	FullDocumentName = "Document.PreparingForFixedAssetSale2_4";
	
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
	|	DocumentData.Period AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData";
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");
	
EndProcedure

Procedure CreateTTTableWithListOfDocuments(Query)
	
	Query.Text =
	"SELECT
	|	DocumentsList.Ref AS Ref,
	|	DocumentsList.Organization AS Organization,
	|	DocumentsList.Date AS Period
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	Document.PreparingForFixedAssetSale2_4 AS DocumentsList
	|
	|WHERE
	|	DocumentsList.Ref = &Ref
	|
	|INDEX BY
	|	Ref
	|";
	
	Query.Execute();
	
EndProcedure

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref                 AS Ref,
	|	DocumentData.Date                   AS Period,
	|	DocumentData.Number                  AS Number,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Department          AS Department,
	|	DocumentData.FixedAssetsEvent              AS FixedAssetsEvent,
	|	DocumentData.EmployeeResponsible          AS EmployeeResponsible,
	|	DocumentData.Comment            AS Comment,
	|	DocumentData.Posted               AS Posted,
	|	DocumentData.DeletionMark        AS DeletionMark,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.PostInAccounting            AS PostInAccounting,
	|	DocumentData.RecordInTA            AS RecordInTA,
	|	DocumentData.RetirementItem  AS RetirementItem,
	|
	|	VALUE(Enum.BusinessTransactions.PreparingForFixedAssetSale) AS BusinessOperation
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.PreparingForFixedAssetSale2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
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
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAsset AS AccountingObject
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.PreparingForFixedAssetSale2_4.FA AS DocumentTable
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
	NonCurrentAssets.AddValuesOfPaymentParametersWhenDebitingFA(ValuesOfHoldingParameters);

	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.PreparingForFixedAssetSale2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Chuẩn bị chuyển giao TSCĐ hữu hình';
															|ru = 'Подготовка к передаче ОС';
															|en = 'Prepare for sale of fixed assets'; fa = 'آماده‌سازی برای فروش دارایی‌های ثابت';
															|it = 'preparazione al trasferimento del capitale fisso';
															|pl = 'Przygotowanie do przekazania środków trwałych';
															|tr = 'sabit kıymet satışına hazırlık'"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.PreparingForFixedAssetSale);
	ValuesOfHoldingParameters.Insert("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.PreparingForFixedAssetSale);
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")); 
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());

	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	DocumentData.Ref               AS Ref,
	|	DocumentData.Date                 AS Date,
	|	DocumentData.Organization          AS Organization,
	|	DocumentData.Department        AS Department,
	|	&MetadataIdentifier             AS RefType,
	|	&BusinessOperation               AS BusinessOperation,
	|	DocumentData.Posted             AS Posted,
	|	DocumentData.PostInAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting    AS RecordInManAccounting,
	|	DocumentData.RecordInTA          AS RecordInTA,
	|	DocumentData.FixedAssetsEvent            AS FixedAssetsEvent,
	|	FATable.FixedAsset           AS FixedAsset
	|
	|FROM
	|	Document.PreparingForFixedAssetSale2_4 AS DocumentData
	|
	|		LEFT JOIN Document.PreparingForFixedAssetSale2_4.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
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
	|	DocumentData.Ref          AS Ref,
	|	DocumentData.Date            AS IBDocumentDate,
	|	DocumentData.Number           AS IBDocumentNumber,
	|	&MetadataIdentifier        AS RefType,
	|	DocumentData.Organization     AS Organization,
	|	&BusinessOperation          AS BusinessOperation,
	|	UNDEFINED                    AS LineOfBusiness,
	|	DocumentData.Department   AS Department,
	|	DocumentData.EmployeeResponsible   AS EmployeeResponsible,
	|	DocumentData.Comment     AS Comment,
	|	DocumentData.Posted        AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE                            AS AdditionalRecord,
	|	DocumentData.Date            AS SourceDocumentDate,
	|	&NumberForPrinting                  AS SourceDocumentNumber,
	|	FALSE                            AS ReverseTransactionCorrection,
	|	UNDEFINED                    AS ReversedDocument,
	|	UNDEFINED                    AS CorrectedDocument,
	|	DocumentData.Date            AS RecordingInAccountingDate,
	|	UNDEFINED                    AS Priority
	|
	|FROM
	|	Document.PreparingForFixedAssetSale2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts, "TTExtendedFATable");
	
	QueryText = PreparingForFixedAssetSaleLocalization.QueryTextTableInitialFixedAssetsInformation();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DocumentData.Organization AS Organization,
		|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	InitialFixedAssetsInformation.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.DeregistrationDocumentACC
		|
		|	END AS DeregistrationDocumentACC,
		|
		|	CASE
		|		WHEN DocumentData.RecordInManAccounting
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.DeregistrationDocumentMA
		|	END AS DeregistrationDocumentMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = DocumentData.Ref
		|";
	
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                                         AS Recorder,
	|	DocumentData.Period                                         AS Period,
	|	DocumentData.Organization                                    AS Organization,
	|	AccountingProcedureForOSBU.FixedAsset                              AS FixedAsset,
	|
	|	AccountingProcedureForOSBU.ExpenseItemAccounting                              AS ExpenseItemAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionAccounting                           AS ExpensesDimensionAccounting,
	|	AccountingProcedureForOSBU.ExpenseItemTaxAccounting                              AS ExpenseItemTaxAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionTaxAccounting                           AS ExpensesDimensionTaxAccounting,
	|	AccountingProcedureForOSBU.ExpenseItemOfDepreciationAllowance           AS ExpenseItemOfDepreciationAllowance,
	|	AccountingProcedureForOSBU.DepreciationAllowanceExpensesDimension        AS DepreciationAllowanceExpensesDimension,
	|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany           AS TransferExpensesToAnotherCompany,
	|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses                 AS CompanyRecipientOfExpenses,
	|	AccountingProcedureForOSBU.DepreciationRecordMethodLA                  AS DepreciationRecordMethodLA,
	|	AccountingProcedureForOSBU.DepreciationRecordMethodTA                  AS DepreciationRecordMethodTA,
	|	AccountingProcedureForOSBU.BonusDepreciationRecordMethod          AS BonusDepreciationRecordMethod,
	|	AccountingProcedureForOSBU.DepreciationGroup                         AS DepreciationGroup,
	|	AccountingProcedureForOSBU.RealEstate                           AS RealEstate,
	|	AccountingProcedureForOSBU.VATTaxation                            AS VATTaxation,
	|	AccountingProcedureForOSBU.InvestmentTaxDeduction                  AS InvestmentTaxDeduction,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|			THEN VALUE(Enum.FixedAssetsStates.TakenOffBooks)
	|		ELSE AccountingProcedureForOSBU.BUState
	|	END AS BUState,
	|
	|	CASE
	|		WHEN DocumentData.RecordInTA
	|			THEN VALUE(Enum.FixedAssetsStates.TakenOffBooks)
	|		ELSE AccountingProcedureForOSBU.StateTa
	|	END AS StateTa,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|			THEN FALSE
	|		ELSE AccountingProcedureForOSBU.DepreciationAccrualAccounting
	|	END AS DepreciationAccrualAccounting,
	|
	|	CASE
	|		WHEN DocumentData.RecordInTA
	|			THEN FALSE
	|		ELSE AccountingProcedureForOSBU.DepreciationAccrualTaxAccounting
	|	END AS DepreciationAccrualTaxAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.Organization       AS Organization,
	|	FixedAssetsAccountingProcedureManagementAccounting.FixedAsset AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks) AS State,
	|	FALSE                              AS AccrueDepreciationOrAmortization
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTAccountingProcedureForOsuu AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAssetsLeasedOut(QueryTexts, Registers)

	RegisterName = "AssetsLeasedOut";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTLeasedToFA(QueryTexts, FullObjectName());

	QueryText =
	"SELECT
	|	DocumentData.Ref      AS Recorder,
	|	DocumentData.Period      AS Period,
	|	DocumentData.Organization AS Organization,
	|	AssetsLeasedOut.FixedAsset AS FixedAsset
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTLeasedToFA AS AssetsLeasedOut
	|		ON AssetsLeasedOut.Ref = DocumentData.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure	

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
	
	QueryText = NonCurrentAssetsInternal.TextOfRequestToDeductCostOfFA(QueryTexts, Query);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableOtherExpenses(QueryTexts, Registers = Undefined)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	Add_Fields = "Recorder";

	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableOtherAssetsLiabilities(QueryTexts)

	RegisterName = "OtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableTTDepreciationWriteOffFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTWriteOffOfCostOfFA(QueryTexts);
	
	QueryText =
	"// The revaluation reserve depreciation
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_WriteOffRevaluationReserveOfFixedAssetDepreciation  AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	FATable.LineOfBusiness           AS LineOfBusiness,
	|
	|	&ArticleAP_OS                                AS AssetRef,
	|	FATable.FixedAsset                  AS Dimension,
	|
	|	FATable.DepreciationRevaluationReserve       AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffFA AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|WHERE
	|	FATable.DepreciationRevaluationReserve <> 0
	|	AND DocumentData.RecordInManAccounting
	|
	|UNION ALL
	|
	|// Revaluation reserve
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_WriteOffRevaluationReserveOfFixedAssetsCost    AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	FATable.LineOfBusiness           AS LineOfBusiness,
	|
	|	&ArticleAP_OS                                AS AssetRef,
	|	FATable.FixedAsset                  AS Dimension,
	|
	|	FATable.CostRevaluationReserve         AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfCostOfFA AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|WHERE
	|	FATable.CostRevaluationReserve <> 0
	|	AND DocumentData.RecordInManAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts)

	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
		
	QueryText = NonCurrentAssetsInternal.TextOfRequestForDisposalFARegisteredRecordsOnOtherAssetsLiabilities(QueryTexts);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";

	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	
	QueryText = NonCurrentAssetsInternal.RequestTextDisposalsFARegisteredRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	QueryTexts.Add(QueryText, RegisterName);	
	
EndProcedure

Procedure QueryTextTableTTFATable(QueryTexts)
	
	TableName = "TTFATable";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = PreparingForFixedAssetSaleLocalization.QueryTextTableTTFATable(QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts, "TTExtendedFATable");
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
		|	FALSE AS AccrueDepreciation,
		|
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|
		|	0 AS AmountManagementAccounting,
		|	0 AS ChargeAmountAccounting,
		|	0 AS AmountTaxAccounting,
		|	0 AS AmountPermanentDifference,
		|	0 AS AmountTemporaryDifference,
		|	
		|	FATable.RowID          AS RowID
		|	
		|INTO TTFATable
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		LEFT JOIN TTAccountingFA AS AccountingProcedure
		|		ON AccountingProcedure.Ref = FATable.Ref
		|			AND FATable.FixedAsset = AccountingProcedure.FixedAsset
		|
		|		LEFT JOIN TTLocationOfFA AS FALocation
		|		ON FALocation.Ref = FATable.Ref
		|			AND FATable.FixedAsset = FALocation.FixedAsset
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
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN TTUnitsDepreciationComponents AS NodesComponents
		|		ON NodesComponents.Ref = FATable.Ref 
		|			AND NodesComponents.FixedAsset = FATable.FixedAsset
		|		
		|		LEFT JOIN TTAccountingFA AS AccountingProcedure
		|		ON AccountingProcedure.Ref = NodesComponents.Ref 
		|			AND AccountingProcedure.FixedAsset = NodesComponents.SubAssetComponent
		|
		|		LEFT JOIN TTLocationOfFA AS FALocation
		|		ON FALocation.Ref = NodesComponents.Ref 
		|			AND FALocation.FixedAsset = NodesComponents.SubAssetComponent
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = NodesComponents.Ref 
		|			AND InitialFixedAssetsInformation.FixedAsset = NodesComponents.SubAssetComponent
		|
		|INDEX BY
		|	Ref
		|";
		
	EndIf; 
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return "";
	EndIf;
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));

	QueryText = NonCurrentAssetsInternal.QueryTextTableTTInitialOtherExpensesAtDisposalOfFA(QueryTexts);
	ListOfMergeRequests.Add(QueryText);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(QueryTexts, Add_Fields)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function FullObjectName()

	Return "Document.PreparingForFixedAssetSale2_4";

EndFunction

#EndRegion

#Region ConductingLocalAccounting_

Function TextOfReflectionInLocalAccounting() Export

	Return PreparingForFixedAssetSaleLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return PreparingForFixedAssetSaleLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Print

Procedure AddPrintCommands(PrintCommands) Export
	
	PreparingForFixedAssetSaleLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Function GetDataForPrintedFormOS1(PrintParameters, ObjectsArray) Export

	Return PreparingForFixedAssetSaleLocalization.GetDataForPrintedFormOS1(PrintParameters, ObjectsArray);

EndFunction

#EndRegion

#Region Other

// Fills in the disposal item.
// 
// Parameters:
//  Organization - CatalogRef.Companies - 
//  Date - Date - 
//  TabularSection - TabularSection - 
//  RetirementItem  - ChartOfCharacteristicTypesRef.ExpenseItems - 
Procedure FillInExpenseItemRetirement(Organization, Date, TabularSection, RetirementItem) Export
	
	ListOfFA = New Array;
	
	For Each RowData In TabularSection Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	If ListOfFA.Count() = 0 Then
		Return;
	EndIf;

	QueryText = 
	"SELECT DISTINCT
	|	ISNULL(FixedAssetsAccountingProcedure.FinancialAccountingGroup.AssetKind, UNDEFINED) AS AssetKind
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
	|		&Date,
	|		CorrectionDate = DATETIME(1,1,1)
	|			AND Organization = &Organization
	|			AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedure
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Result = Query.Execute();
	
	AvailableArticles = New Array;
	
	Selection = Result.Select();
	If Selection.Next() Then
		
		If Selection.AssetKind = Enums.KindsOfNonCurrentAssets.FixedAssetsProvidedToLessee Then
			NewArticle = ChartsOfCharacteristicTypes.ExpenseItems.TangibleAssetSale;
		Else
			NewArticle = ChartsOfCharacteristicTypes.ExpenseItems.FASellingExpenses;
		EndIf;
		
		If AvailableArticles.Find(NewArticle) = Undefined Then
			AvailableArticles.Add(NewArticle);
		EndIf;
		
	EndIf;

	If AvailableArticles.Count() = 0 Then
		Return;
	EndIf;
	
	If AvailableArticles.Count() = 1
		Or Not ValueIsFilled(RetirementItem) Then
			
		RetirementItem = AvailableArticles[0];
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
