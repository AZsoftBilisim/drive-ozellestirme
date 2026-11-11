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
	DocumentMechanisms.Add("ImpairmentFA");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");

	ChangeFixedAssetFinancialDetailsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ChangeFixedAssetFinancialDetails2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		
		NonCurrentAssetsInternal.QueryTextTableTTFAList(QueryTexts,, "ValidOnDate");
		
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(QueryTexts, Registers);
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableCGUComposition(Query, QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		ChangeFixedAssetFinancialDetailsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
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
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	QueryTexts = New ValueList;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAList(QueryTexts,, "ValidOnDate");
	
	QueryTextTableFACost(QueryTexts);
	QueryTextTableFixedAssetsDepreciationCharge(QueryTexts);
	QueryTextTableInvestmentInRent(QueryTexts);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	
	QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	ChangeFixedAssetFinancialDetailsLocalization.TablesOfDeferredMotionFormation(QueryTexts);

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
	
	Command = AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ListForm";
	EndIf;
	
	Documents.FixedAssetCostAndDepreciationAdjustment.AddGenerateCommand(GenerationCommands);
	
	ChangeFixedAssetFinancialDetailsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the "Change OS parameters" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export

	If AccessRight("Insert", Metadata.Documents.ChangeFixedAssetFinancialDetails2_4) Then

		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ChangeFixedAssetFinancialDetails2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ChangeFixedAssetFinancialDetails2_4);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ChangeFixedAssetFinancialDetailsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ChangeFixedAssetFinancialDetailsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

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

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ChangeFixedAssetFinancialDetails2_4";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("AdditionalRegistry", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(Query, QueryTexts, RegisterName);
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
	|	DocumentData.Number   AS Number,
	|	DocumentData.AdjustmentModeFromPreviousDate AS AdjustmentModeFromPreviousDate,
	|	DocumentData.ValidOnDate AS ValidOnDate
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
	|	Document.ChangeFixedAssetFinancialDetails2_4 AS DocumentsList
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
	|	DocumentData.Ref AS Ref,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Period,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.AdjustmentModeFromPreviousDate AS AdjustmentModeFromPreviousDate,
	|	ENDOFPERIOD(DocumentData.ValidOnDate, DAY) AS ValidOnDate,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|	DocumentData.Comment AS Comment,
	|	VALUE(Enum.BusinessTransactions.ChangeFixedAssetFinancialDetails) AS BusinessOperation,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|			THEN DocumentData.ValidOnDate
	|		ELSE DocumentData.Date
	|	END AS DateRecord,
	|
	|	DocumentData.DepreciationSchedule AS DepreciationSchedule,
	|	DocumentData.DepreciationScheduleFlag AS DepreciationScheduleFlag,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.FinancialAccountingGroupFlag AS FinancialAccountingGroupFlag,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.LineOfBusinessFlag AS LineOfBusinessFlag,
	|	DocumentData.AccelerationFactorManagementAccounting AS AccelerationFactorManagementAccounting,
	|	DocumentData.AccelerationFactorManagementAccountingFlag AS AccelerationFactorManagementAccountingFlag,
	|	DocumentData.ResidualValueMan AS ResidualValueMan,
	|	DocumentData.ResidualValueManFlag AS ResidualValueManFlag,
	|	DocumentData.ResidualValueLocal AS ResidualValueLocal,
	|	DocumentData.ResidualValueLocalFlag AS ResidualValueLocalFlag,
	|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationAccrualMethodManagementAccounting,
	|	DocumentData.DepreciationAccrualMethodManagementAccountingFlag AS DepreciationAccrualMethodManagementAccountingFlag,
	|	DocumentData.DepreciationAccrualManagementAccounting AS DepreciationAccrualManagementAccounting,
	|	DocumentData.DepreciationAccrualManagementAccountingFlag AS DepreciationAccrualManagementAccountingFlag,
	|	DocumentData.EstimatedRunningTime AS EstimatedRunningTime,
	|	DocumentData.EstimatedRunningTimeFlag AS EstimatedRunningTimeFlag,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Organization.LocalAccountingCurrency AS ComplCurrency,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.DepreciationExpenseRecordingIsChanged AS DepreciationExpenseRecordingIsChanged,
	|	DocumentData.RunningTimeValue AS RunningTimeValue,
	|	DocumentData.RunningTimeValueFlag AS RunningTimeValueFlag,
	|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
	|	DocumentData.UsefulLifeManagementAccountingFlag AS UsefulLifeManagementAccountingFlag,
	|	DocumentData.CGUFlag AS CGUFlag,
	|	DocumentData.CGU AS CGU,
	|	DocumentData.SpecifiedRemainingUsefulLifeAC AS SpecifiedRemainingUsefulLifeAC,
	|	DocumentData.SpecifiedRemainingUsefulLifeMA AS SpecifiedRemainingUsefulLifeMA,
	|	DocumentData.AnnualDepreciationRate AS AnnualDepreciationRate,
	|	DocumentData.AnnualDepreciationRateFlag AS AnnualDepreciationRateFlag,
	|	DocumentData.AccelerationFactorAccounting AS AccelerationFactorAccounting,
	|	DocumentData.AccelerationFactorAccountingFlag AS AccelerationFactorAccountingFlag,
	|	DocumentData.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
	|	DocumentData.DepreciationAccrualAccountingFlag AS DepreciationAccrualAccountingFlag,
	|	DocumentData.UsefulLifeAccounting AS UsefulLifeAccounting,
	|	DocumentData.UsefulLifeAccountingFlag AS UsefulLifeAccountingFlag,
	|	DocumentData.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	DocumentData.DepreciationMethodAccountingFlag AS DepreciationMethodAccountingFlag,
	|	DocumentData.ExpensesPostingMethod AS ExpensesPostingMethod,
	|
	|	&ChangingOSParameters_DocumentDetails
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4 AS DocumentData
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
	
	ChangeFixedAssetFinancialDetailsLocalization.AddDocumentDetailsToRequestText(QueryText, "DocumentData");
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.FixedAsset AS FixedAsset
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4.FA AS DocumentTable
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
	
	#Region DocumentDataTableDepreciation
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Department AS Department,
	|	DocumentTable.LineOfBusiness AS LineOfBusiness,
	|	DocumentTable.ExpenseItem AS ExpenseItem,
	|	DocumentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentTable.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DocumentTable.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
	|
	|INTO DocumentDataTableDepreciation
	|
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4.Depreciation AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
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

	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ChangeFixedAssetFinancialDetails2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Thay đổi cài đặt TSCĐ HH';
															|ru = 'Изменение параметров ОС';
															|en = 'Adjust fixed asset financial details'; fa = 'تعدیل جزئیات مالی دارایی ثابت';
															|it = 'Modifica dei parametri dei capitali fissi';
															|pl = 'Zmiana parametrów środków trwałych';
															|tr = 'Sabit kıymet finansal bilgi düzeltmesi'"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.ChangeFixedAssetFinancialDetails);
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	ValuesOfHoldingParameters.Insert("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		If Attributes.AdjustmentModeFromPreviousDate
			And ValueIsFilled(Attributes.ValidOnDate) Then
			ValuesOfHoldingParameters.Insert("AdditionalRegistry", StrTemplate(NStr("vi = 'Thay đổi các tham số từ ngày %1 trước đó';
																					|ru = 'Изменение параметров с прошлой даты %1';
																					|en = 'Parameter change from previous date %1'; fa = 'Parameter change from previous date %1';
																					|it = 'Parameter change from previous date %1';
																					|pl = 'Parameter change from previous date %1';
																					|tr = '%1 geçmiş tarihinden itibaren parametre değiştirme'"), Format(Attributes.ValidOnDate, "DLF=D;")));
		Else
			ValuesOfHoldingParameters.Insert("AdditionalRegistry", "");
		EndIf;

	EndIf;
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS IBDocumentDate,
	|	DocumentData.Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Organization             AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	DocumentData.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	DocumentData.Date                    AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	DocumentData.Date                    AS RecordingInAccountingDate,
	|	&AdditionalRegistry                    AS More,
	|	UNDEFINED                            AS Priority
	|
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)    AS RecNo,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Date,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Posted                AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.PostInAccounting             AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.RecordInTA             AS RecordInTA,
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	DocumentData.AdjustmentModeFromPreviousDate AS IsPatch,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|			THEN DocumentData.ValidOnDate
	|		ELSE DATETIME(1,1,1)
	|	END AS CorrectionPeriodStart,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|			THEN BEGINOFPERIOD(ENDOFPERIOD(DocumentData.Date, MONTH), DAY)
	|		ELSE DATETIME(1,1,1)
	|	END AS CorrectionPeriodEnd,
	|
	|	FATable.FixedAsset              AS FixedAsset
	|
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4 AS DocumentData
	|
	|		LEFT JOIN Document.ChangeFixedAssetFinancialDetails2_4.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DATETIME(1,1,1) AS CorrectionDate,
	|
	|	DocumentData.Organization AS Organization,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	FATable.FixedAsset AS FixedAsset,
	|
	|	CASE
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE FixedAssetsAccountingProcedure.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE FixedAssetsAccountingProcedure.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN DocumentData.RunningTimeValueFlag
	|			THEN DocumentData.RunningTimeValue
	|		ELSE FixedAssetsAccountingProcedure.RunningTimeValue
	|	END AS RunningTimeValue,
	|
	|	CASE
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|			THEN DocumentData.EstimatedRunningTime
	|		ELSE FixedAssetsAccountingProcedure.EstimatedRunningTime
	|	END AS EstimatedRunningTime
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS RegisterDataLast
	|		ON RegisterDataLast.Ref = FATable.Ref
	|			AND RegisterDataLast.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	(DocumentData.FinancialAccountingGroupFlag
	|			OR DocumentData.LineOfBusinessFlag
	|			OR DocumentData.RunningTimeValueFlag
	|			OR DocumentData.EstimatedRunningTimeFlag)
	|
	|	AND (NOT DocumentData.AdjustmentModeFromPreviousDate
	|		OR ISNULL(RegisterDataLast.Period, DATETIME(1,1,1)) < DocumentData.ValidOnDate)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Recorder,
	|	BEGINOFPERIOD(DocumentData.ValidOnDate, DAY) AS Period,
	|	DocumentData.Period AS CorrectionDate,
	|
	|	DocumentData.Organization AS Organization,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	FATable.FixedAsset AS FixedAsset,
	|
	|	CASE
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE FixedAssetsAccountingProcedure.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE FixedAssetsAccountingProcedure.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN DocumentData.RunningTimeValueFlag
	|			THEN DocumentData.RunningTimeValue
	|		ELSE FixedAssetsAccountingProcedure.RunningTimeValue
	|	END AS RunningTimeValue,
	|
	|	CASE
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|			THEN DocumentData.EstimatedRunningTime
	|		ELSE FixedAssetsAccountingProcedure.EstimatedRunningTime
	|	END AS EstimatedRunningTime
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	(DocumentData.FinancialAccountingGroupFlag
	|			OR DocumentData.LineOfBusinessFlag
	|			OR DocumentData.RunningTimeValueFlag
	|			OR DocumentData.EstimatedRunningTimeFlag)
	|
	|	AND DocumentData.AdjustmentModeFromPreviousDate
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts);

	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(
		QueryTexts,, "TueAccountingProcedureForOSBU_SubjectToCorrections", True);
	
	QueryText = ChangeFixedAssetFinancialDetailsLocalization.QueryTextTableAccountingProcedureForOSBU();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DATETIME(1,1,1) AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	AccountingProcedureForOSBU.BUState AS BUState,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationAccrualAccountingFlag
		|			THEN DocumentData.DepreciationAccrualAccounting
		|		ELSE AccountingProcedureForOSBU.DepreciationAccrualAccounting
		|	END AS DepreciationAccrualAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.DepreciationRecordMethodLA
		|		ELSE DocumentData.Ref
		|	END AS DepreciationRecordMethodLA,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpenseRecordMethodAC
		|		ELSE UNDEFINED
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpenseItemAccounting
		|		ELSE UNDEFINED
		|	END AS ExpenseItemAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpensesDimensionAccounting
		|		ELSE UNDEFINED
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.DepartmentACC
		|		ELSE UNDEFINED
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.LineOfBusinessBookkeeping
		|		ELSE UNDEFINED
		|	END AS LineOfBusinessBookkeeping,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN AccountingProcedureForOSBU.TransferExpensesToAnotherCompany
		|		ELSE FALSE
		|	END AS TransferExpensesToAnotherCompany,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN AccountingProcedureForOSBU.CompanyRecipientOfExpenses
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
		|		ON AccountingProcedureForOSBU.Ref = FATable.Ref
		|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU_SubjectToCorrections AS RegisterDataLast
		|		ON RegisterDataLast.Ref = FATable.Ref
		|			AND RegisterDataLast.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|	AND (DocumentData.DepreciationAccrualAccountingFlag
		|			OR DocumentData.DepreciationExpenseRecordingIsChanged)
		|
		|	AND (NOT DocumentData.AdjustmentModeFromPreviousDate
		|		OR ISNULL(RegisterDataLast.Period, DATETIME(1,1,1)) < DocumentData.ValidOnDate)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	BEGINOFPERIOD(DocumentData.ValidOnDate, DAY) AS Period,
		|	DocumentData.Period AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	AccountingProcedureForOSBU.BUState AS BUState,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationAccrualAccountingFlag
		|			THEN DocumentData.DepreciationAccrualAccounting
		|		ELSE AccountingProcedureForOSBU.DepreciationAccrualAccounting
		|	END AS DepreciationAccrualAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.DepreciationRecordMethodLA
		|		ELSE DocumentData.Ref
		|	END AS DepreciationRecordMethodLA,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpenseRecordMethodAC
		|		ELSE UNDEFINED
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpenseItemAccounting
		|		ELSE UNDEFINED
		|	END AS ExpenseItemAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpensesDimensionAccounting
		|		ELSE UNDEFINED
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.DepartmentACC
		|		ELSE UNDEFINED
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.LineOfBusinessBookkeeping
		|		ELSE UNDEFINED
		|	END AS LineOfBusinessBookkeeping,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN AccountingProcedureForOSBU.TransferExpensesToAnotherCompany
		|		ELSE FALSE
		|	END AS TransferExpensesToAnotherCompany,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN AccountingProcedureForOSBU.CompanyRecipientOfExpenses
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU_SubjectToCorrections AS AccountingProcedureForOSBU
		|		ON AccountingProcedureForOSBU.Ref = FATable.Ref
		|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|	AND (DocumentData.DepreciationAccrualAccountingFlag
		|			OR DocumentData.DepreciationExpenseRecordingIsChanged)
		|
		|	AND DocumentData.AdjustmentModeFromPreviousDate
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DATETIME(1,1,1) AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	AccountingProcedureForOSBU.BUState AS BUState,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationAccrualManagementAccountingFlag
		|			THEN DocumentData.DepreciationAccrualManagementAccounting
		|		ELSE AccountingProcedureForOSBU.DepreciationAccrualAccounting
		|	END AS DepreciationAccrualAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.DepreciationRecordMethodLA
		|		ELSE DocumentData.Ref
		|	END AS DepreciationRecordMethodLA,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpenseRecordMethodAC
		|		ELSE UNDEFINED
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpenseItemAccounting
		|		ELSE UNDEFINED
		|	END AS ExpenseItemAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpensesDimensionAccounting
		|		ELSE UNDEFINED
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.DepartmentACC
		|		ELSE UNDEFINED
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.LineOfBusinessBookkeeping
		|		ELSE UNDEFINED
		|	END AS LineOfBusinessBookkeeping,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN AccountingProcedureForOSBU.TransferExpensesToAnotherCompany
		|		ELSE FALSE
		|	END AS TransferExpensesToAnotherCompany,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN AccountingProcedureForOSBU.CompanyRecipientOfExpenses
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
		|		ON AccountingProcedureForOSBU.Ref = FATable.Ref
		|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU_SubjectToCorrections AS RegisterDataLast
		|		ON RegisterDataLast.Ref = FATable.Ref
		|			AND RegisterDataLast.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|	AND (DocumentData.DepreciationAccrualManagementAccountingFlag
		|			OR DocumentData.DepreciationExpenseRecordingIsChanged)
		|
		|	AND (NOT DocumentData.AdjustmentModeFromPreviousDate
		|		OR ISNULL(RegisterDataLast.Period, DATETIME(1,1,1)) < DocumentData.ValidOnDate)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	BEGINOFPERIOD(DocumentData.ValidOnDate, DAY) AS Period,
		|	DocumentData.Period AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	AccountingProcedureForOSBU.BUState AS BUState,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationAccrualManagementAccountingFlag
		|			THEN DocumentData.DepreciationAccrualManagementAccounting
		|		ELSE AccountingProcedureForOSBU.DepreciationAccrualAccounting
		|	END AS DepreciationAccrualAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.DepreciationRecordMethodLA
		|		ELSE DocumentData.Ref
		|	END AS DepreciationRecordMethodLA,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpenseRecordMethodAC
		|		ELSE UNDEFINED
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpenseItemAccounting
		|		ELSE UNDEFINED
		|	END AS ExpenseItemAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.ExpensesDimensionAccounting
		|		ELSE UNDEFINED
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.DepartmentACC
		|		ELSE UNDEFINED
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN AccountingProcedureForOSBU.LineOfBusinessBookkeeping
		|		ELSE UNDEFINED
		|	END AS LineOfBusinessBookkeeping,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN AccountingProcedureForOSBU.TransferExpensesToAnotherCompany
		|		ELSE FALSE
		|	END AS TransferExpensesToAnotherCompany,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN AccountingProcedureForOSBU.CompanyRecipientOfExpenses
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU_SubjectToCorrections AS AccountingProcedureForOSBU
		|		ON AccountingProcedureForOSBU.Ref = FATable.Ref
		|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|	AND (DocumentData.DepreciationAccrualAccountingFlag
		|			OR DocumentData.DepreciationExpenseRecordingIsChanged)
		|
		|	AND DocumentData.AdjustmentModeFromPreviousDate
		|";
				
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(
		QueryTexts,, "TTAccountingProcedureForOsuu_SubjectToCorrections", True);

	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DATETIME(1,1,1) AS CorrectionDate,
	|
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset,
	|	FixedAssetsAccountingProcedureManagementAccounting.State AS State,
	|
	|	CASE
	|		WHEN DocumentData.DepreciationAccrualManagementAccountingFlag
	|			THEN DocumentData.DepreciationAccrualManagementAccounting
	|		ELSE FixedAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization
	|	END AS AccrueDepreciationOrAmortization,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|				OR NOT DocumentData.RecordInManAccounting
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.DepreciationRecordMethod
	|		ELSE DocumentData.Ref
	|	END AS DepreciationRecordMethod,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|				OR NOT DocumentData.RecordInManAccounting
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.ExpensesPostingMethod
	|		ELSE UNDEFINED
	|	END AS ExpensesPostingMethod,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|				OR NOT DocumentData.RecordInManAccounting
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.ExpenseItem
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|				OR NOT DocumentData.RecordInManAccounting
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|				OR NOT DocumentData.RecordInManAccounting
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.Department
	|		ELSE UNDEFINED
	|	END AS Department,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|				OR NOT DocumentData.RecordInManAccounting
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.TransferExpensesToAnotherCompany
	|		ELSE FALSE
	|	END AS TransferExpensesToAnotherCompany,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.CompanyRecipientOfExpenses
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.Ref = FATable.Ref
	|			AND FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu_SubjectToCorrections AS RegisterDataLast
	|		ON RegisterDataLast.Ref = FATable.Ref
	|			AND RegisterDataLast.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND (DocumentData.DepreciationAccrualManagementAccountingFlag
	|			OR DocumentData.DepreciationExpenseRecordingIsChanged)
	|
	|	AND (NOT DocumentData.AdjustmentModeFromPreviousDate
	|		OR ISNULL(RegisterDataLast.Period, DATETIME(1,1,1)) < DocumentData.ValidOnDate)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Recorder,
	|	BEGINOFPERIOD(DocumentData.ValidOnDate, DAY) AS Period,
	|	DocumentData.Period AS CorrectionDate,
	|
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset,
	|	FixedAssetsAccountingProcedureManagementAccounting.State AS State,
	|
	|	CASE
	|		WHEN DocumentData.DepreciationAccrualManagementAccountingFlag
	|			THEN DocumentData.DepreciationAccrualManagementAccounting
	|		ELSE FixedAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization
	|	END AS AccrueDepreciationOrAmortization,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.DepreciationRecordMethod
	|		ELSE DocumentData.Ref
	|	END AS DepreciationRecordMethod,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.ExpensesPostingMethod
	|		ELSE UNDEFINED
	|	END AS ExpensesPostingMethod,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.ExpenseItem
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.Department
	|		ELSE UNDEFINED
	|	END AS Department,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.TransferExpensesToAnotherCompany
	|		ELSE FALSE
	|	END AS TransferExpensesToAnotherCompany,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.CompanyRecipientOfExpenses
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu_SubjectToCorrections AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.Ref = FATable.Ref
	|			AND FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND (DocumentData.DepreciationAccrualManagementAccountingFlag
	|			OR DocumentData.DepreciationExpenseRecordingIsChanged)
	|
	|	AND DocumentData.AdjustmentModeFromPreviousDate
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(QueryTexts, Registers)
	
	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(
		QueryTexts,, "WDepreciationParametersOfOSBU_SubjectToCorrections",, True);

	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(
		QueryTexts,, "TTAccountingFA_SubjectToCorrections", True);

	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(
		QueryTexts,, "TTInitialInformationFA_SubjectToCorrections", True);
			
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(
		QueryTexts,, "TTParametersOfDepreciationOfOSBU_AsOfPreviousDate", New Structure("Period", "ValidOnDate"), True);
			
	QueryText = ChangeFixedAssetFinancialDetailsLocalization.QueryTextTableOSBUDepreciationParameters();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DATETIME(1,1,1) AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	OSBUDepreciationParameters.LastChangeDate AS LastChangeDate,
		|	ISNULL(OSBUDepreciationParameters.CostUsedToCalculateDepreciationManag, 0) AS CostUsedToCalculateDepreciationManag,
		|
		// UsefulLifeMonthsAC
		|	CASE
		|		WHEN DocumentData.UsefulLifeAccountingFlag AND NOT DocumentData.SpecifiedRemainingUsefulLifeAC
		|
		|			THEN DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag AND DocumentData.SpecifiedRemainingUsefulLifeAC
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|				+ DocumentData.UsefulLifeAccounting
		|
		|		ELSE ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsAC, 0)
		|
		|	END AS UsefulLifeMonthsAC,
		|
		// AccelerationFactor
		|	CASE
		|		WHEN DocumentData.AccelerationFactorAccountingFlag
		|			THEN DocumentData.AccelerationFactorAccounting
		|		ELSE ISNULL(OSBUDepreciationParameters.AccelerationFactor, 0)
		|	END AS AccelerationFactor,
		|
		// UsefulLifeForCalculatingDepreciationMonth
		|	CASE
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeAC 
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeAC 
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|					+ DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeAC
		|				AND OSBUDepreciationParameters.UsefulLifeMonthsAC = OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|			THEN DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeAC
		|				AND OSBUDepreciationParameters.UsefulLifeMonthsAC = OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|					+ DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeAC
		|
		|			THEN OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth 
		|				+ (DocumentData.UsefulLifeAccounting - OSBUDepreciationParameters.UsefulLifeMonthsAC)
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeAC
		|
		|			THEN DocumentData.UsefulLifeAccounting
		|					+ DATEDIFF(OSBUDepreciationParameters.LastChangeDate, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH)
		|
		|		ELSE OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	CASE
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DocumentData.EstimatedRunningTime
		|
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|				AND FixedAssetsAccountingProcedure.EstimatedRunningTime = OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|
		|			THEN DocumentData.EstimatedRunningTime
		|
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|
		|			THEN OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits 
		|					+ (DocumentData.EstimatedRunningTime - FixedAssetsAccountingProcedure.EstimatedRunningTime)
		|
		|		ELSE OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		// ResidualValueMan
		|	CASE
		|		WHEN DocumentData.ResidualValueLocalFlag
		|			THEN DocumentData.ResidualValueLocal
		|		ELSE OSBUDepreciationParameters.ResidualValueMan
		|	END AS ResidualValueMan
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN WDepreciationParametersOfOSBU AS OSBUDepreciationParameters
		|		ON OSBUDepreciationParameters.Ref = FATable.Ref
		|			AND OSBUDepreciationParameters.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
		|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
		|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN WDepreciationParametersOfOSBU_SubjectToCorrections AS RegisterDataLast
		|		ON RegisterDataLast.Ref = FATable.Ref
		|			AND RegisterDataLast.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|	AND (DocumentData.UsefulLifeAccountingFlag
		|			OR DocumentData.AnnualDepreciationRateFlag
		|			OR DocumentData.EstimatedRunningTimeFlag
		|			OR DocumentData.ResidualValueLocalFlag)
		|
		|	AND (NOT DocumentData.AdjustmentModeFromPreviousDate
		|		OR ISNULL(RegisterDataLast.Period, DATETIME(1,1,1)) < DocumentData.ValidOnDate)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	BEGINOFPERIOD(DocumentData.ValidOnDate, DAY) AS Period,
		|	DocumentData.Period AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	OSBUDepreciationParameters.LastChangeDate AS LastChangeDate,
		|	ISNULL(OSBUDepreciationParameters.CostUsedToCalculateDepreciationManag, 0) AS CostUsedToCalculateDepreciationManag,
		|
		// UsefulLifeMonthsAC
		|	CASE
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeAC
		|
		|			THEN DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeAC
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|				+ DocumentData.UsefulLifeAccounting
		|
		|		ELSE ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsAC, 0)
		|
		|	END AS UsefulLifeMonthsAC,
		|
		// AccelerationFactor
		|	CASE
		|		WHEN DocumentData.AccelerationFactorAccountingFlag
		|			THEN DocumentData.AccelerationFactorAccounting
		|		ELSE ISNULL(OSBUDepreciationParameters.AccelerationFactor, 0)
		|	END AS AccelerationFactor,
		|
		// UsefulLifeForCalculatingDepreciationMonth
		|	CASE
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeAC 
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeAC 
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|					+ DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeAC
		|				AND OSBUDepreciationParameters.UsefulLifeMonthsAC = OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|			THEN DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeAC
		|				AND OSBUDepreciationParameters.UsefulLifeMonthsAC = OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|					+ DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeAC
		|
		|			THEN OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth 
		|					+ (DocumentData.UsefulLifeAccounting - OSBUDepreciationParameters.UsefulLifeMonthsAC)
		|
		|		WHEN DocumentData.UsefulLifeAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeAC
		|
		|			THEN DocumentData.UsefulLifeAccounting
		|					+ DATEDIFF(OSBUDepreciationParameters.LastChangeDate, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH)
		|
		|		ELSE OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	CASE
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DocumentData.EstimatedRunningTime
		|
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|				AND FixedAssetsAccountingProcedure.EstimatedRunningTime = OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|
		|			THEN DocumentData.EstimatedRunningTime
		|
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|			THEN OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits 
		|					+ (DocumentData.EstimatedRunningTime - FixedAssetsAccountingProcedure.EstimatedRunningTime)
		|
		|		ELSE OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		// ResidualValueMan
		|	CASE
		|		WHEN DocumentData.ResidualValueLocalFlag
		|			THEN DocumentData.ResidualValueLocal
		|		ELSE OSBUDepreciationParameters.ResidualValueMan
		|	END AS ResidualValueMan
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN WDepreciationParametersOfOSBU_SubjectToCorrections AS OSBUDepreciationParameters
		|		ON OSBUDepreciationParameters.Ref = FATable.Ref
		|			AND OSBUDepreciationParameters.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
		|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
		|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA_SubjectToCorrections AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|	AND (DocumentData.UsefulLifeAccountingFlag
		|			OR DocumentData.AnnualDepreciationRateFlag
		|			OR DocumentData.EstimatedRunningTimeFlag
		|			OR DocumentData.ResidualValueLocalFlag)
		|	AND DocumentData.AdjustmentModeFromPreviousDate
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DATETIME(1,1,1) AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	OSBUDepreciationParameters.LastChangeDate AS LastChangeDate,
		|	ISNULL(OSBUDepreciationParameters.CostUsedToCalculateDepreciationManag, 0) AS CostUsedToCalculateDepreciationManag,
		|
		// UsefulLifeMonthsAC
		|	CASE
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
		|			THEN DocumentData.UsefulLifeAccounting
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag AND DocumentData.SpecifiedRemainingUsefulLifeMA
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) + DocumentData.UsefulLifeManagementAccounting
		|		ELSE ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsAC, 0)
		|	END AS UsefulLifeMonthsAC,
		|
		// AccelerationFactor
		|	CASE
		|		WHEN DocumentData.AccelerationFactorManagementAccountingFlag
		|			THEN DocumentData.AccelerationFactorManagementAccounting
		|		ELSE ISNULL(OSBUDepreciationParameters.AccelerationFactor, 0)
		|	END AS AccelerationFactor,
		|
		// UsefulLifeForCalculatingDepreciationMonth
		|	CASE
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA 
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DocumentData.UsefulLifeManagementAccounting
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeMA 
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|					+ DocumentData.UsefulLifeManagementAccounting
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
		|				AND OSBUDepreciationParameters.UsefulLifeMonthsAC = OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|			THEN DocumentData.UsefulLifeManagementAccounting
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
		|				AND OSBUDepreciationParameters.UsefulLifeMonthsAC = OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|					+ DocumentData.UsefulLifeManagementAccounting
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
		|
		|			THEN OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth 
		|					+ (DocumentData.UsefulLifeManagementAccounting - OSBUDepreciationParameters.UsefulLifeMonthsAC)
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
		|
		|			THEN DocumentData.UsefulLifeManagementAccounting
		|					+ DATEDIFF(OSBUDepreciationParameters.LastChangeDate, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH)
		|
		|		ELSE OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	CASE
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DocumentData.EstimatedRunningTime
		|
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|				AND FixedAssetsAccountingProcedure.EstimatedRunningTime = OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|
		|			THEN DocumentData.EstimatedRunningTime
		|
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|
		|			THEN OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits 
		|					+ (DocumentData.EstimatedRunningTime - FixedAssetsAccountingProcedure.EstimatedRunningTime)
		|
		|		ELSE OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		// ResidualValueMan
		|	CASE
		|		WHEN DocumentData.ResidualValueLocalFlag
		|			THEN DocumentData.ResidualValueLocal
		|		ELSE OSBUDepreciationParameters.ResidualValueMan
		|	END AS ResidualValueMan
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN WDepreciationParametersOfOSBU AS OSBUDepreciationParameters
		|		ON OSBUDepreciationParameters.Ref = FATable.Ref
		|			AND OSBUDepreciationParameters.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
		|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
		|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN WDepreciationParametersOfOSBU_SubjectToCorrections AS RegisterDataLast
		|		ON RegisterDataLast.Ref = FATable.Ref
		|			AND RegisterDataLast.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|	AND (DocumentData.UsefulLifeManagementAccountingFlag
		|			OR DocumentData.AccelerationFactorManagementAccountingFlag
		|			OR DocumentData.EstimatedRunningTimeFlag
		|			OR DocumentData.ResidualValueLocalFlag)
		|
		|	AND (NOT DocumentData.AdjustmentModeFromPreviousDate
		|		OR ISNULL(RegisterDataLast.Period, DATETIME(1,1,1)) < DocumentData.ValidOnDate)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	BEGINOFPERIOD(DocumentData.ValidOnDate, DAY) AS Period,
		|	DocumentData.Period AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	OSBUDepreciationParameters.LastChangeDate AS LastChangeDate,
		|	ISNULL(OSBUDepreciationParameters.CostUsedToCalculateDepreciationManag, 0) AS CostUsedToCalculateDepreciationManag,
		|
		// UsefulLifeMonthsAC
		|	CASE
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeAC
		|
		|			THEN DocumentData.UsefulLifeAccounting
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|					+ DocumentData.UsefulLifeManagementAccounting
		|
		|		ELSE ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsAC, 0)
		|
		|	END AS UsefulLifeMonthsAC,
		|
		// AccelerationFactor
		|	CASE
		|		WHEN DocumentData.AccelerationFactorManagementAccountingFlag
		|			THEN DocumentData.AccelerationFactorManagementAccounting
		|		ELSE ISNULL(OSBUDepreciationParameters.AccelerationFactor, 0)
		|	END AS AccelerationFactor,
		|
		// UsefulLifeForCalculatingDepreciationMonth
		|	CASE
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA 
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DocumentData.UsefulLifeManagementAccounting
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeMA 
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|					+ DocumentData.UsefulLifeManagementAccounting
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
		|				AND OSBUDepreciationParameters.UsefulLifeMonthsAC = OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|			THEN DocumentData.UsefulLifeManagementAccounting
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
		|				AND OSBUDepreciationParameters.UsefulLifeMonthsAC = OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateAC, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
		|					+ DocumentData.UsefulLifeManagementAccounting
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
		|
		|			THEN OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth 
		|					+ (DocumentData.UsefulLifeManagementAccounting - OSBUDepreciationParameters.UsefulLifeMonthsAC)
		|
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
		|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
		|
		|			THEN DocumentData.UsefulLifeManagementAccounting
		|					+ DATEDIFF(OSBUDepreciationParameters.LastChangeDate, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH)
		|
		|		ELSE OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	CASE
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|				AND OSBUDepreciationParameters.FixedAsset IS NULL
		|
		|			THEN DocumentData.EstimatedRunningTime
		|
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|				AND FixedAssetsAccountingProcedure.EstimatedRunningTime = OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|
		|			THEN DocumentData.EstimatedRunningTime
		|
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|
		|			THEN OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits 
		|					+ (DocumentData.EstimatedRunningTime - FixedAssetsAccountingProcedure.EstimatedRunningTime)
		|
		|		ELSE OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		// ResidualValueMan
		|	CASE
		|		WHEN DocumentData.ResidualValueLocalFlag
		|			THEN DocumentData.ResidualValueLocal
		|		ELSE OSBUDepreciationParameters.ResidualValueMan
		|	END AS ResidualValueMan
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTParametersOfDepreciationOfOSBU_AsOfPreviousDate AS OSBUDepreciationParameters
		|		ON OSBUDepreciationParameters.Ref = FATable.Ref
		|			AND OSBUDepreciationParameters.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingFA_SubjectToCorrections AS FixedAssetsAccountingProcedure
		|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
		|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA_SubjectToCorrections AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|	AND (DocumentData.UsefulLifeManagementAccountingFlag
		|			OR DocumentData.AccelerationFactorManagementAccountingFlag
		|			OR DocumentData.EstimatedRunningTimeFlag
		|			OR DocumentData.ResidualValueLocalFlag)
		|
		|	AND DocumentData.AdjustmentModeFromPreviousDate
		|";
			
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers)
	
	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(
		QueryTexts,, "TTOsuuDepreciationParameters_SubjectToCorrections",, True);
	
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(
		QueryTexts,, "TTParametersOfDepreciationOfOSUU_ForLastDate", New Structure("Period", "ValidOnDate"), True);
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(
		QueryTexts,, "TTAccountingFA_SubjectToCorrections", True);

	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(
		QueryTexts,, "TTInitialInformationFA_SubjectToCorrections", True);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DATETIME(1,1,1) AS CorrectionDate,
	|
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, DATETIME(1, 1, 1)) AS LastChangeDate,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationManag, 0) AS CostUsedToCalculateDepreciationManag,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationLocal, 0) AS CostUsedToCalculateDepreciationLocal,
	|
	// UsefulLifeMonths
	|	CASE
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
	|
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
	|
	|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateMA, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
	|					+ DocumentData.UsefulLifeManagementAccounting
	|
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths, 0)
	|
	|	END AS UsefulLifeMonths,
	|
	// UsefulLifeForCalculatingDepreciationMonth 
	|	CASE
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA 
	|				AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset IS NULL
	|
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
	|				AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset IS NULL
	|
	|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateMA, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
	|					+ DocumentData.UsefulLifeManagementAccounting
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
	|				AND FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths = FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
	|				AND FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths = FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|
	|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateMA, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
	|					+ DocumentData.UsefulLifeManagementAccounting
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
	|
	|			THEN FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth 
	|					+ (DocumentData.UsefulLifeManagementAccounting - FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths)
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
	|
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|					+ DATEDIFF(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH)
	|
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|
	|	END AS UsefulLifeForCalculatingDepreciationMonth,
	|
	// AccelerationFactor
	|	CASE
	|		WHEN DocumentData.AccelerationFactorManagementAccountingFlag
	|			THEN DocumentData.AccelerationFactorManagementAccounting
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor, 0)
	|	END AS AccelerationFactor,
	|
	// DepreciationMethod
	|	CASE
	|		WHEN DocumentData.DepreciationAccrualMethodManagementAccountingFlag
	|			THEN DocumentData.DepreciationAccrualMethodManagementAccounting
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod, 0)
	|	END AS DepreciationMethod,
	|
	// ResidualValueMan 
	|	CASE
	|		WHEN DocumentData.ResidualValueManFlag
	|			THEN DocumentData.ResidualValueMan
	|		WHEN DocumentData.ResidualValueLocalFlag
	|				AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|				AND &CurrencyOfMan = DocumentData.ComplCurrency
	|			THEN DocumentData.ResidualValueLocal
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0)
	|	END AS ResidualValueMan,
	|
	// ResidualValueLocal 
	|	CASE
	|		WHEN DocumentData.ResidualValueLocalFlag
	|			THEN DocumentData.ResidualValueLocal
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal, 0)
	|	END AS ResidualValueLocal,
	|
	// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	CASE
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|				AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset IS NULL
	|
	|			THEN DocumentData.EstimatedRunningTime
	|
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|				AND FixedAssetsAccountingProcedure.EstimatedRunningTime = FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|
	|			THEN DocumentData.EstimatedRunningTime
	|
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|
	|			THEN FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits 
	|					+ (DocumentData.EstimatedRunningTime - FixedAssetsAccountingProcedure.EstimatedRunningTime)
	|
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|
	|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTOsuuDepreciationParameters AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.Ref = FATable.Ref
	|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
	|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
	|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTOsuuDepreciationParameters_SubjectToCorrections AS RegisterDataLast
	|		ON RegisterDataLast.Ref = FATable.Ref
	|			AND RegisterDataLast.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
	|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND (DocumentData.UsefulLifeManagementAccountingFlag
	|			OR DocumentData.AccelerationFactorManagementAccountingFlag
	|			OR DocumentData.DepreciationAccrualMethodManagementAccountingFlag
	|			OR DocumentData.ResidualValueManFlag
	|			OR DocumentData.ResidualValueLocalFlag
	|				AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|				AND &CurrencyOfMan = DocumentData.ComplCurrency
	|			OR DocumentData.EstimatedRunningTimeFlag)
	|
	|	AND (NOT DocumentData.AdjustmentModeFromPreviousDate
	|		OR ISNULL(RegisterDataLast.Period, DATETIME(1,1,1)) < DocumentData.ValidOnDate)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Recorder,
	|	BEGINOFPERIOD(DocumentData.ValidOnDate, DAY) AS Period,
	|	DocumentData.Period AS CorrectionDate,
	|
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, DATETIME(1, 1, 1)) AS LastChangeDate,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationManag, 0) AS CostUsedToCalculateDepreciationManag,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationLocal, 0) AS CostUsedToCalculateDepreciationLocal,
	|
	// UsefulLifeMonths
	|	CASE
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
	|
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
	|
	|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateMA, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
	|					+ DocumentData.UsefulLifeManagementAccounting
	|
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths, 0)
	|
	|	END AS UsefulLifeMonths,
	|
	// UsefulLifeForCalculatingDepreciationMonth 
	|	CASE
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA 
	|				AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset IS NULL
	|
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND DocumentData.SpecifiedRemainingUsefulLifeMA 
	|				AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset IS NULL
	|
	|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateMA, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
	|					+ DocumentData.UsefulLifeManagementAccounting
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
	|				AND FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths = FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
	|				AND FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths = FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|
	|			THEN DATEDIFF(InitialFixedAssetsInformation.CommissioningDateMA, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH) 
	|					+ DocumentData.UsefulLifeManagementAccounting
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND NOT DocumentData.SpecifiedRemainingUsefulLifeMA
	|
	|			THEN FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth 
	|					+ (DocumentData.UsefulLifeManagementAccounting - FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths)
	|
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag 
	|				AND DocumentData.SpecifiedRemainingUsefulLifeMA
	|
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|					+ DATEDIFF(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, BEGINOFPERIOD(DocumentData.DateRecord, DAY), MONTH)
	|
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|
	|	END AS UsefulLifeForCalculatingDepreciationMonth,
	|
	// AccelerationFactor
	|	CASE
	|		WHEN DocumentData.AccelerationFactorManagementAccountingFlag
	|			THEN DocumentData.AccelerationFactorManagementAccounting
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor, 0)
	|	END AS AccelerationFactor,
	|
	// DepreciationMethod
	|	CASE
	|		WHEN DocumentData.DepreciationAccrualMethodManagementAccountingFlag
	|			THEN DocumentData.DepreciationAccrualMethodManagementAccounting
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod, 0)
	|	END AS DepreciationMethod,
	|
	// ResidualValueMan 
	|	CASE
	|		WHEN DocumentData.ResidualValueManFlag
	|			THEN DocumentData.ResidualValueMan
	|		WHEN DocumentData.ResidualValueLocalFlag
	|				AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|				AND &CurrencyOfMan = DocumentData.ComplCurrency
	|			THEN DocumentData.ResidualValueLocal
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0)
	|	END AS ResidualValueMan,
	|
	// ResidualValueLocal 
	|	CASE
	|		WHEN DocumentData.ResidualValueLocalFlag
	|			THEN DocumentData.ResidualValueLocal
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal, 0)
	|	END AS ResidualValueLocal,
	|
	// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	CASE
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|				AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset IS NULL
	|
	|			THEN DocumentData.EstimatedRunningTime
	|
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|				AND FixedAssetsAccountingProcedure.EstimatedRunningTime = FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|
	|			THEN DocumentData.EstimatedRunningTime
	|
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|
	|			THEN FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits 
	|					+ (DocumentData.EstimatedRunningTime - FixedAssetsAccountingProcedure.EstimatedRunningTime)
	|
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|
	|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTParametersOfDepreciationOfOSUU_ForLastDate AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.Ref = FATable.Ref
	|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA_SubjectToCorrections AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTInitialInformationFA_SubjectToCorrections AS InitialFixedAssetsInformation
	|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
	|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
	|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND (DocumentData.UsefulLifeManagementAccountingFlag
	|			OR DocumentData.AccelerationFactorManagementAccountingFlag
	|			OR DocumentData.DepreciationAccrualMethodManagementAccountingFlag
	|			OR DocumentData.ResidualValueLocalFlag
	|				AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|				AND &CurrencyOfMan = DocumentData.ComplCurrency
	|			OR DocumentData.EstimatedRunningTimeFlag)
	|
	|	AND DocumentData.AdjustmentModeFromPreviousDate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(
		QueryTexts,, "TTInitialInformationFA_SubjectToCorrections", True);
	
	QueryText = ChangeFixedAssetFinancialDetailsLocalization.QueryTextTableInitialFixedAssetsInformation();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		QueryText =
		"SELECT
		|	DocumentData.Period AS Period,
		|	DATETIME(1,1,1) AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|	InitialFixedAssetsInformation.DeregistrationDocumentACC AS DeregistrationDocumentACC,
		|	InitialFixedAssetsInformation.DeregistrationDocumentMA AS DeregistrationDocumentMA,
		|
		|	DocumentData.DepreciationMethodAccounting AS DepreciationMethodAccounting
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA_SubjectToCorrections AS RegisterDataLast
		|		ON RegisterDataLast.Ref = FATable.Ref
		|			AND RegisterDataLast.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.DepreciationMethodAccountingFlag
		|
		|	AND (NOT DocumentData.AdjustmentModeFromPreviousDate
		|		OR ISNULL(RegisterDataLast.Period, DATETIME(1,1,1)) < DocumentData.ValidOnDate)
		|
		|UNION ALL
		|
		|SELECT
		|	BEGINOFPERIOD(DocumentData.ValidOnDate, DAY) AS Period,
		|	DocumentData.Period AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|	InitialFixedAssetsInformation.DeregistrationDocumentACC AS DeregistrationDocumentACC,
		|	InitialFixedAssetsInformation.DeregistrationDocumentMA AS DeregistrationDocumentMA,
		|
		|	DocumentData.DepreciationMethodAccounting AS DepreciationMethodAccounting
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTInitialInformationFA_SubjectToCorrections AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.DepreciationMethodAccountingFlag
		|	AND DocumentData.AdjustmentModeFromPreviousDate
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Period AS Period,
		|	DATETIME(1,1,1) AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|	InitialFixedAssetsInformation.DeregistrationDocumentACC AS DeregistrationDocumentACC,
		|	InitialFixedAssetsInformation.DeregistrationDocumentMA AS DeregistrationDocumentMA,
		|
		|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA_SubjectToCorrections AS RegisterDataLast
		|		ON RegisterDataLast.Ref = FATable.Ref
		|			AND RegisterDataLast.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.DepreciationAccrualMethodManagementAccountingFlag
		|
		|	AND (NOT DocumentData.AdjustmentModeFromPreviousDate
		|		OR ISNULL(RegisterDataLast.Period, DATETIME(1,1,1)) < DocumentData.ValidOnDate)
		|
		|UNION ALL
		|
		|SELECT
		|	BEGINOFPERIOD(DocumentData.ValidOnDate, DAY) AS Period,
		|	DocumentData.Period AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|	InitialFixedAssetsInformation.DeregistrationDocumentACC AS DeregistrationDocumentACC,
		|	InitialFixedAssetsInformation.DeregistrationDocumentMA AS DeregistrationDocumentMA,
		|
		|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTInitialInformationFA_SubjectToCorrections AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.DepreciationAccrualMethodManagementAccountingFlag
		|	AND DocumentData.AdjustmentModeFromPreviousDate
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFACost(QueryTexts)

	RegisterName = "FACost";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetsCostParameterChange) AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	FATable.FixedAsset                  AS FixedAsset,
	|	TTFAAccountingParameters.FixedAssetsLocation          AS Department,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	TTFAAccountingParameters.Leaseholder                AS Leaseholder,
	|	FACost.Cost                       AS Cost,
	|	FACost.LocalCost                   AS LocalCost,
	|	FACost.CostInTaxAccounting                     AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference                     AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference                     AS CostTemporaryDifference,
	|	FACost.CostTargetFinancing                     AS CostTargetFinancing,
	|	FACost.CostTargetFinancingTA                   AS CostTargetFinancingTA,
	|	FACost.CostTargetFinancingPD                   AS CostTargetFinancingPD,
	|	FACost.CostTargetFinancingTD                   AS CostTargetFinancingTD,
	|	FACost.DepreciationAllowance           AS DepreciationAllowance,
	|	FACost.TAExpenseAmountOfInvestmentTaxDeduction           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	FACost.SecurityDepositValue              AS SecurityDepositValue,
	|	FACost.PreliminaryCostMan        AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal    AS PreliminaryCostLocal,
	|	FACost.CostRevaluationReserve       AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal   AS CostRevaluationReserveLocal,
	|	0                                           AS CostGainMA,
	|	0                                           AS CostGainLocal,
	|	FACost.DisregardedCostTA        AS DisregardedCostTA,
	|	DocumentData.Organization                 AS CorCompany,
	|	TTFAAccountingParameters.FixedAssetsLocation          AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTFAAccountingParameters.LineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTFAAccountingParameters.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|	
	|	FATable.RowID           AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsCostParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetsCostParameterChange) AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	FATable.FixedAsset                  AS FixedAsset,
	|	TTFAAccountingParameters.FixedAssetsLocation          AS Department,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTFAAccountingParameters.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTFAAccountingParameters.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	TTFAAccountingParameters.Leaseholder                AS Leaseholder,
	|	FACost.Cost                       AS Cost,
	|	FACost.LocalCost                   AS LocalCost,
	|	FACost.CostInTaxAccounting                     AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference                     AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference                     AS CostTemporaryDifference,
	|	FACost.CostTargetFinancing                     AS CostTargetFinancing,
	|	FACost.CostTargetFinancingTA                   AS CostTargetFinancingTA,
	|	FACost.CostTargetFinancingPD                   AS CostTargetFinancingPD,
	|	FACost.CostTargetFinancingTD                   AS CostTargetFinancingTD,
	|	FACost.DepreciationAllowance           AS DepreciationAllowance,
	|	FACost.TAExpenseAmountOfInvestmentTaxDeduction           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	FACost.SecurityDepositValue              AS SecurityDepositValue,
	|	FACost.PreliminaryCostMan        AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal    AS PreliminaryCostLocal,
	|	FACost.CostRevaluationReserve       AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal   AS CostRevaluationReserveLocal,
	|	0                                           AS CostGainMA,
	|	0                                           AS CostGainLocal,
	|	FACost.DisregardedCostTA        AS DisregardedCostTA,
	|	DocumentData.Organization                 AS CorCompany,
	|	TTFAAccountingParameters.FixedAssetsLocation          AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|	
	|	FATable.RowID               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsCostParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	VALUE(Enum.BusinessTransactions.ChangeRevaluationReserveOfFixedAssetsCost) AS BusinessOperation,
	|	DocumentData.Organization             AS Organization,
	|	FATable.FixedAsset              AS FixedAsset,
	|	TTFAAccountingParameters.FixedAssetsLocation      AS Department,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                            AS Leaseholder,
	|
	|	0                                       AS Cost,
	|	0                                       AS LocalCost,
	|	0                                       AS CostInTaxAccounting,
	|	0                                       AS CostPermanentDifference,
	|	0                                       AS CostTemporaryDifference,
	|	0                                       AS CostTargetFinancing,
	|	0                                       AS CostTargetFinancingTA,
	|	0                                       AS CostTargetFinancingPD,
	|	0                                       AS CostTargetFinancingTD,
	|	0                                       AS DepreciationAllowance,
	|	0                                       AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                       AS SecurityDepositValue,
	|	0                                       AS PreliminaryCostMan,
	|	0                                       AS PreliminaryCostLocal,
	|	0                                       AS CostRevaluationReserve,
	|	0                                       AS CostRevaluationReserveLocal,
	|
	|	FACost.CostGainMA            AS CostGainMA,
	|	FACost.CostGainLocal        AS CostGainLocal,
	|
	|	0                                       AS DisregardedCostTA,
	|
	|	DocumentData.Organization             AS CorCompany,
	|	UNDEFINED                            AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTFAAccountingParameters.LineOfBusiness
	|	END  AS CorLineOfBusiness,
	|
	|	UNDEFINED                            AS CorExpenseItem,
	|	UNDEFINED                            AS CorExpenditureDimension,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTFAAccountingParameters.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|	
	|	FATable.RowID           AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ChangeRevaluationReserveOfFixedAssetsCost) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	(DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag)
	|
	|	AND (FACost.CostGainMA <> 0
	|		OR FACost.CostGainLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)  AS RecordType,
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	VALUE(Enum.BusinessTransactions.ChangeRevaluationReserveOfFixedAssetsCost) AS BusinessOperation,
	|	DocumentData.Organization             AS Organization,
	|	FATable.FixedAsset              AS FixedAsset,
	|	TTFAAccountingParameters.FixedAssetsLocation      AS Department,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTFAAccountingParameters.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTFAAccountingParameters.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                            AS Leaseholder,
	|
	|	0                                       AS Cost,
	|	0                                       AS LocalCost,
	|	0                                       AS CostInTaxAccounting,
	|	0                                       AS CostPermanentDifference,
	|	0                                       AS CostTemporaryDifference,
	|	0                                       AS CostTargetFinancing,
	|	0                                       AS CostTargetFinancingTA,
	|	0                                       AS CostTargetFinancingPD,
	|	0                                       AS CostTargetFinancingTD,
	|	0                                       AS DepreciationAllowance,
	|	0                                       AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                       AS SecurityDepositValue,
	|	0                                       AS PreliminaryCostMan,
	|	0                                       AS PreliminaryCostLocal,
	|	0                                       AS CostRevaluationReserve,
	|	0                                       AS CostRevaluationReserveLocal,
	|
	|	FACost.CostGainMA            AS CostGainMA,
	|	FACost.CostGainLocal        AS CostGainLocal,
	|
	|	0                                       AS DisregardedCostTA,
	|
	|	DocumentData.Organization             AS CorCompany,
	|	UNDEFINED                            AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	UNDEFINED                            AS CorExpenseItem,
	|	UNDEFINED                            AS CorExpenditureDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	
	|	FATable.RowID           AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ChangeRevaluationReserveOfFixedAssetsCost) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|WHERE
	|	(DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag)
	|
	|	AND (FACost.CostGainMA <> 0
	|		OR FACost.CostGainLocal <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetDepreciationParameterChange) AS BusinessOperation,
	|	DocumentData.Organization               AS Organization,
	|	FATable.FixedAsset                AS FixedAsset,
	|	TTFAAccountingParameters.FixedAssetsLocation        AS Department,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                              AS Counterparty,
	|	FixedAssetsDepreciationCharge.Depreciation                 AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal             AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationInTaxAccounting               AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences               AS DepreciationPermanentDifferences,
	|	FixedAssetsDepreciationCharge.DepreciationTD               AS DepreciationTD,
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing               AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing             AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD             AS DepreciationTargetFinancingPD,
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD             AS DepreciationOfTargetFinancingTD,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve AS DepreciationRevaluationReserve,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal AS DepreciationRevaluationReserveLocal,
	|	DocumentData.Organization               AS CorCompany,
	|	TTFAAccountingParameters.FixedAssetsLocation        AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTFAAccountingParameters.LineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	UNDEFINED                              AS CorExpenseItem,
	|	UNDEFINED                              AS CorExpenditureDimension,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTFAAccountingParameters.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|
	|	FixedAssetsDepreciationCharge.AccrueDepreciation              AS AccrueDepreciation,
	|	
	|	FATable.RowID             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetDepreciationParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetDepreciationParameterChange) AS BusinessOperation,
	|	DocumentData.Organization               AS Organization,
	|	FATable.FixedAsset                AS FixedAsset,
	|	TTFAAccountingParameters.FixedAssetsLocation        AS Department,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTFAAccountingParameters.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTFAAccountingParameters.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                              AS Counterparty,
	|	FixedAssetsDepreciationCharge.Depreciation                 AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal             AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationInTaxAccounting               AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences               AS DepreciationPermanentDifferences,
	|	FixedAssetsDepreciationCharge.DepreciationTD               AS DepreciationTD,
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing               AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing             AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD             AS DepreciationTargetFinancingPD,
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD             AS DepreciationOfTargetFinancingTD,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve AS DepreciationRevaluationReserve,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal AS DepreciationRevaluationReserveLocal,
	|	DocumentData.Organization               AS CorCompany,
	|	TTFAAccountingParameters.FixedAssetsLocation        AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	UNDEFINED                              AS CorExpenseItem,
	|	UNDEFINED                              AS CorExpenditureDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation              AS AccrueDepreciation,
	|	
	|	FATable.RowID             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetDepreciationParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableInvestmentInRent(QueryTexts)

	RegisterName = "InvestmentInRent";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	DocumentData.Organization               AS Organization,
	|	TTFAAccountingParameters.FixedAsset       AS FixedAsset,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	InvestmentInRent.Contract                 AS Contract,
	|	InvestmentInRent.Contract.ARAPCurrency AS Currency,
	|	InvestmentInRent.RentalPayments         AS RentalPayments,
	|	InvestmentInRent.RentalPaymentsLocal     AS RentalPaymentsLocal,
	|	InvestmentInRent.RentalPaymentsManag      AS RentalPaymentsManag,
	|	InvestmentInRent.NonGuaranteedResidualValueLocal                AS NonGuaranteedResidualValueLocal,
	|	InvestmentInRent.NonGuaranteedResidualValueManag                 AS NonGuaranteedResidualValueManag,
	|	InvestmentInRent.InterestDiscount       AS InterestDiscount,
	|	InvestmentInRent.InterestDiscountMan    AS InterestDiscountMan,
	|	InvestmentInRent.InterestDiscountLocal   AS InterestDiscountLocal,
	|	
	|	FATable.RowID             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsCostParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_InvestmentInRent AS InvestmentInRent
	|		ON InvestmentInRent.AccountingObject = FATable.FixedAsset
	|			AND InvestmentInRent.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	DocumentData.Organization               AS Organization,
	|	FATable.FixedAsset                AS FixedAsset,
	|	DocumentData.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	InvestmentInRent.Contract                 AS Contract,
	|	InvestmentInRent.Contract.ARAPCurrency AS Currency,
	|	InvestmentInRent.RentalPayments         AS RentalPayments,
	|	InvestmentInRent.RentalPaymentsLocal     AS RentalPaymentsLocal,
	|	InvestmentInRent.RentalPaymentsManag      AS RentalPaymentsManag,
	|	InvestmentInRent.NonGuaranteedResidualValueLocal                AS NonGuaranteedResidualValueLocal,
	|	InvestmentInRent.NonGuaranteedResidualValueManag                 AS NonGuaranteedResidualValueManag,
	|	InvestmentInRent.InterestDiscount       AS InterestDiscount,
	|	InvestmentInRent.InterestDiscountMan    AS InterestDiscountMan,
	|	InvestmentInRent.InterestDiscountLocal   AS InterestDiscountLocal,
	|	
	|	FATable.RowID             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsCostParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_InvestmentInRent AS InvestmentInRent
	|		ON InvestmentInRent.AccountingObject = FATable.FixedAsset
	|			AND InvestmentInRent.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts);
	
	QueryText =
	// Moving depreciation
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetDepreciationParameterChange) AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|
	|	TTFAAccountingParameters.FixedAssetsLocation           AS Department,
	|	TTFAAccountingParameters.LineOfBusiness   AS LineOfBusiness,
	|	&ArticleAP_OS                                 AS AssetRef,
	|	UNDEFINED                                 AS DimensionOfRevenue,
	|	UNDEFINED                                 AS DimensionOfExpenses,
	|	FATable.FixedAsset                   AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|
	|	TTFAAccountingParameters.FixedAssetsLocation           AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTFAAccountingParameters.LineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	&ArticleAP_OS                                 AS CorItem,
	|	UNDEFINED                                 AS CorIncomeDimension,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	FATable.FixedAsset                   AS CorDimensionOfAssetsLiabilities,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTFAAccountingParameters.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|
	|	FixedAssetsDepreciationCharge.Depreciation                    AS Sum,
	|	FixedAssetsDepreciationCharge.Depreciation                    AS SumMan,
	|	FixedAssetsDepreciationCharge.DepreciationLocal + FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|			AND FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|
	|UNION ALL
	|
	// Moving the cost
	|SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	VALUE(Enum.BusinessTransactions.FixedAssetsCostParameterChange) AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|
	|	TTFAAccountingParameters.FixedAssetsLocation           AS Department,
	|	TTFAAccountingParameters.LineOfBusiness   AS LineOfBusiness,
	|	&ArticleAP_OS                                 AS AssetRef,
	|	UNDEFINED                                 AS DimensionOfRevenue,
	|	UNDEFINED                                 AS DimensionOfExpenses,
	|	FATable.FixedAsset                   AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|
	|	TTFAAccountingParameters.FixedAssetsLocation           AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTFAAccountingParameters.LineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	&ArticleAP_OS                                 AS CorItem,
	|	UNDEFINED                                 AS CorIncomeDimension,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	FATable.FixedAsset                   AS CorDimensionOfAssetsLiabilities,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTFAAccountingParameters.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|
	|	FACost.Cost                        AS Sum,
	|	FACost.Cost                        AS SumMan,
	|	FACost.LocalCost + FACost.CostTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = FATable.Ref
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableCGUComposition(Query, QueryTexts, Registers)
	
	RegisterName = "CGUComposition";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.Period       AS Period,
	|	FATable.FixedAsset   AS NonCurrentAsset,
	|	DocumentData.Organization  AS Organization,
	|	DocumentData.CGU         AS CGU
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.CGUFlag";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return ChangeFixedAssetFinancialDetailsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return ChangeFixedAssetFinancialDetailsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
	// PM Depreciation
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Depreciation";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("DepreciationExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("DepreciationIsExpenseItemWithoutDivision");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DepreciationDimensionOfExpenses");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DepreciationExpenseAnalyticsWithoutPartitioning");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	// PM Depreciation Award
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.DepreciationAllowance";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("DepreciationAllowanceExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DepreciationAllowanceDimensionOfExpenses");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
