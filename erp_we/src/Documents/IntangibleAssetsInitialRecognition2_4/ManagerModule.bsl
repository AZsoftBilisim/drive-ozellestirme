
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
	DocumentMechanisms.Add("IntangibleAssets");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("ImpairmentFA");
	
	IntangibleAssetsInitialRecognitionLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.IntangibleAssetsInitialRecognition2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		AddlParameters.OnlyMarkedOnes = Registers <> Undefined;
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers);
		
		QueryTextTableIntangibleAssetsRegistrationPlace(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(Query, QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(Query, QueryTexts, Registers);
		QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Registers);
		QueryTextTableInitialIntangibleAssetsInformation(Query, QueryTexts, Registers);
		
		QueryTextTableIACost(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableCGUComposition(Query, QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		IntangibleAssetsInitialRecognitionLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

// Generates tables of movements when calculating the cost.
//
// Parameters:
//  TempTablesManager - TempTablesManager - Contains the necessary temporary tables.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesForCalculatingCost(TempTablesManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;

	GetDocumentData(Query);

	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 

	QueryTexts = New ValueList;

	QueryTextTableIACost(Query, QueryTexts, Undefined);
	QueryTextTableInitialIntangibleAssetsInformation(Query, QueryTexts, Undefined);
	QueryTextTableOtherExpenses(Query, QueryTexts, Undefined);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	IntangibleAssetsInitialRecognitionLocalization.TablesForCalculatingCost(Query, QueryTexts);
	
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
	
	Documents.ChangeIntangibleAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);
	Documents.IntangibleAssetsCostAndAmortizationAdjustment.AddGenerateCommand(GenerationCommands);
	
	Command = AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ListForm";
	EndIf;
	
	IntangibleAssetsInitialRecognitionLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "acceptance for accounting of IA".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.IntangibleAssetsInitialRecognition2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.IntangibleAssetsInitialRecognition2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.IntangibleAssetsInitialRecognition2_4);
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
	
EndProcedure

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

#EndRegion

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

#Region Internal

// 
// Parameters:
//  Object - DocumentObject.IntangibleAssetsInitialRecognition2_4 - 
Procedure FillInCost(Object) Export

	If Not CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(Object.Date) Then
		Return;
	EndIf; 
	
	If Not ValueIsFilled(Object.IntangibleAsset) Then
		Return;
	EndIf;

	DocumentDate = ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate());
	
	TempTablesManager = New TempTablesManager;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&RecordInLocalAccounting AS RecordInLocalAccounting,
	|	&RecordInManAccounting AS RecordInManAccounting,
	|	&IntangibleAsset AS AccountingObject,
	|	1 AS Priority
	|
	|INTO TTPortionOfDataToBeCalculated
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	1 AS LineNumber,
	|	&IntangibleAsset AS AccountingObject,
	|
	|	&CostGenerationProcedure AS CostGenerationProcedure,
	|
	|	FALSE AS ExpensesAreDistributedByObjects,
	|
	|	&IntangibleAsset AS ExpensesCapitalizationDimension,
	|
	|	FALSE AS ActualCost,
	|	FALSE AS AttributingDeviationsToCost,
	|	DATETIME(1,1,1) AS SourceDocumentDate,
	|
	|	&CostInManagementAccounting AS AmountOfUU,
	|	&CostInAccounting AS AmountAccounting,
	|	&CostInTaxAccounting AS AmountFA,
	|
	|	&TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|	&AmountOfTargetFunds AS AmountOfTargetFunds,
	|
	|	&RecordInLocalAccounting AS RecordInLocalAccounting,
	|	&RecordInManAccounting AS RecordInManAccounting,
	|	&PostInAccounting AS PostInAccounting,
	|	&RecordInTA AS RecordInTA,
	|	&PostInAccounting AS TakeIntoAccountPD,
	|
	|	UNDEFINED AS RowID
	|
	|INTO TTTableOfObjects
	|
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Date", DocumentDate);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("IntangibleAsset", Object.IntangibleAsset);
	Query.SetParameter("CostInManagementAccounting", Object.InitialCostMA);
	Query.SetParameter("CostInAccounting", Object.InitialCostLocalAccounting);
	Query.SetParameter("CostInTaxAccounting", Object.InitialCostTA);
	Query.SetParameter("AmountOfTargetFunds", Object.AmountOfTargetFunds);
	Query.SetParameter("AccountingProcedureMA", Object.AccountingProcedureMA);
	Query.SetParameter("AccountingProcedureAC", Object.AccountingProcedureAC);
	Query.SetParameter("BusinessOperation", Object.BusinessOperation);
	Query.SetParameter("CostGenerationProcedure", Object.CostGenerationProcedure);
	Query.SetParameter("TargetFinancingApplicationOption", Object.TargetFinancingApplicationOption);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	Query.SetParameter("PostInAccounting", Object.PostInAccounting);
	Query.SetParameter("RecordInTA", Object.RecordInTA);
	
	Result = Query.Execute();
	
	FACostCalculation.GenerateTTCurrentExpenses(DocumentDate, TempTablesManager);

	QueryText = 
	"SELECT
	|	TTCurExpenses.AccountingObject AS AccountingObject,
	|	SUM(TTCurExpenses.SumMan) AS SumMan,
	|	SUM(TTCurExpenses.SumCompl) AS SumCompl,
	|	SUM(TTCurExpenses.SumCompl - TTCurExpenses.PermanentDifference - TTCurExpenses.CostTD) AS AmountFA,
	|	SUM(TTCurExpenses.PermanentDifference) AS AmountPermanentDifferences
	|FROM
	|	TTCurExpenses AS TTCurExpenses
	|
	|GROUP BY
	|	TTCurExpenses.AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Result = Query.Execute();

	DocumentExpenses = Result.Unload();
	
	Object.InitialCostMA = 0;
	Object.InitialCostLocalAccounting = 0;
	Object.InitialCostTA = 0;
	Object.InitialCostPD = 0;
	
	If DocumentExpenses.Count() = 0 Then
		Return;
	EndIf;
	
	RowData = DocumentExpenses[0];
	
	If Object.RecordInManAccounting Then
		Object.InitialCostMA = RowData.SumMan;
	EndIf;
	
	If Object.PostInAccounting Then
		Object.InitialCostLocalAccounting = RowData.SumCompl;
	EndIf;
	
	If Object.RecordInTA Then
		Object.InitialCostTA = RowData.SumCompl;
	EndIf;

	If Object.PostInAccounting Or Object.RecordInTA Then
		Object.InitialCostPD = RowData.AmountPermanentDifferences;
	EndIf;

EndProcedure

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
	
	FullDocumentName = "Document.IntangibleAssetsInitialRecognition2_4";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	SynonymForDocumentTable = "";
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		
		QueryText = Undefined;
		
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
		Or RegisterName = "IntangibleAssetsDocuments" Then
		
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
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
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
	|	Document.IntangibleAssetsInitialRecognition2_4 AS DocumentsList
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
	|	DocumentData.Date                                AS Period,
	|	DocumentData.Ref                              AS Ref,
	|	DocumentData.DeletionMark                     AS DeletionMark,
	|	DocumentData.Number                               AS Number,
	|	DocumentData.Date                                AS Date,
	|	DocumentData.Posted                            AS Posted,
	|	DocumentData.BusinessOperation               AS BusinessOperation,
	|	DocumentData.KindOfAccountingObject                     AS KindOfAccountingObject,
	|	DocumentData.FinancialAccountingGroup              AS FinancialAccountingGroup,
	|	DocumentData.Comment                         AS Comment,
	|	DocumentData.DepreciationAccrualFactor                       AS DepreciationAccrualFactor,
	|	DocumentData.AccelerationFactorManagementAccounting              AS AccelerationFactorManagementAccounting,
	|	DocumentData.ResidualValueMan             AS ResidualValueMan,
	|	DocumentData.ResidualValueLocal         AS ResidualValueLocal,
	|	DocumentData.LineOfBusiness             AS LineOfBusiness,
	|	DocumentData.IntangibleAsset                 AS IntangibleAsset,
	|	DocumentData.EstimatedRunningTime                      AS EstimatedRunningTime,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Organization.ParentCompany     AS ParentCompany,
	|	DocumentData.EmployeeResponsible                       AS EmployeeResponsible,
	|	DocumentData.RecordInLocalAccounting                  AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                   AS RecordInManAccounting,
	|	DocumentData.PostInAccounting                         AS PostInAccounting,
	|	DocumentData.InitialCostLocalAccounting           AS InitialCostLocalAccounting,
	|	DocumentData.InitialCostMA           AS InitialCostMA,
	|	DocumentData.Department                       AS Department,
	|	DocumentData.Department                       AS FixedAssetsLocation,
	|	DocumentData.AccountingProcedureAC                      AS AccountingProcedureAC,
	|	DocumentData.AccountingProcedureMA                      AS AccountingProcedureMA,
	|	DocumentData.DepreciationMethodAccounting        AS DepreciationMethodAccounting,
	|	DocumentData.DepreciationAccrualMethodManagementAccounting        AS DepreciationAccrualMethodManagementAccounting,
	|	DocumentData.ReceiptMethod                   AS ReceiptMethod,
	|	DocumentData.UsefulLifeAccounting                 AS UsefulLifeAccounting,
	|	DocumentData.UsefulLifeManagementAccounting                 AS UsefulLifeManagementAccounting,
	|	DocumentData.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DocumentData.CompanyRecipientOfExpenses       AS CompanyRecipientOfExpenses,
	|	DocumentData.CGU                                AS CGU,
	|	DocumentData.ExpenseRecordMethodAC           AS ExpenseRecordMethodAC,
	|	DocumentData.ExpenseItemAccounting                    AS ExpenseItemAccounting,
	|	DocumentData.ExpensesDimensionAccounting                 AS ExpensesDimensionAccounting,
	|	DocumentData.DepartmentACC                     AS DepartmentACC,
	|	DocumentData.LineOfBusinessBookkeeping           AS LineOfBusinessBookkeeping,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping AS BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DeductionInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationIsAccrued))
	|
	|			THEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTaxAccounting
	|
	|		ELSE DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
	| 
	|	END AS BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.PostInAccounting
	|				AND DocumentData.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|
	|			THEN DocumentData.ExpenseRecordMethodAC
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInTA
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.IncludeInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrWriteOffAsExpenses))
	|
	|			THEN DocumentData.ExpenseRecordMethodTA
	|
	|		ELSE DocumentData.MethodForReflectingMaExpenses 
	|	END AS MethodForReflectingMaExpenses,
	|
	|	CASE 
	|		WHEN DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition)
	|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			
	|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.PostInAccounting
	|				AND DocumentData.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|
	|			THEN DocumentData.ExpenseItemAccounting
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInTA
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.IncludeInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrWriteOffAsExpenses))
	|
	|			THEN DocumentData.ExpenseItemTaxAccounting
	|
	|		ELSE DocumentData.ExpenseItemManagementAccounting 
	|	END AS ExpenseItemManagementAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition)
	|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			
	|			THEN UNDEFINED
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND DocumentData.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|
	|			THEN DocumentData.ExpensesDimensionAccounting
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.IncludeInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrWriteOffAsExpenses))
	|
	|			THEN DocumentData.ExpensesDimensionTaxAccounting
	|
	|		ELSE DocumentData.ExpensesDimensionManagementAccounting 
	|	END AS ExpensesDimensionManagementAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND DocumentData.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|
	|			THEN DocumentData.DepartmentACC
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.IncludeInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrWriteOffAsExpenses))
	|
	|			THEN DocumentData.BusinessUnitTaxAccounting
	|
	|		ELSE DocumentData.BusinessUnitManagementAccounting 
	|	END AS BusinessUnitManagementAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND DocumentData.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|
	|			THEN DocumentData.LineOfBusinessBookkeeping
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.IncludeInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrWriteOffAsExpenses))
	|
	|			THEN DocumentData.LineOfBusinessTaxAccounting
	|
	|		ELSE DocumentData.LineOfBusinessManagementAccounting 
	|	END AS LineOfBusinessManagementAccounting,
	|
	|	DocumentData.DocumentID AS DocumentID,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|
	|	DocumentData.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization) AS DepreciationAccrualAccounting,
	|	DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization) AS DepreciationAccrualManagementAccounting,
	|
	|	&AcceptanceForAccountingOfNMA_DocumentDetails
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
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
	
	IntangibleAssetsInitialRecognitionLocalization.AddDocumentDetailsToRequestText(QueryText, "DocumentData");
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	ValuesOfHoldingParameters = New Structure;
	NonCurrentAssetsInternal.ValuesOfParametersOfIAAcceptanceForAccounting(ValuesOfHoldingParameters);
	IntangibleAssetsInitialRecognitionLocalization.ValuesOfHoldingParameters(ValuesOfHoldingParameters);

	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.IntangibleAssetsInitialRecognition2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Bắt đầu hạch toán TSCĐ vô hình';
															|ru = 'Принятие к учету НМА';
															|en = 'Intangible assets — Initial recognition'; fa = 'دارایی‌های نامشهود — شناسایی اولیه';
															|it = 'Scrittura nei libri contabili dei beni immateriali';
															|pl = 'Przyjęcie do ewidencji wartości niematerialnych';
															|tr = 'Maddi olmayan varlıklar - İlk tahakkuk'"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
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
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department           AS Department,
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
	|	UNDEFINED                            AS Priority
	|
	|FROM
	|	Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	0                                       AS RecNo,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Date,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Department           AS Department,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.PostInAccounting             AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.RecordInTA             AS RecordInTA,
	|	DocumentData.IntangibleAsset     AS IntangibleAsset
	|
	|FROM
	|	Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableIntangibleAssetsRegistrationPlace(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsRegistrationPlace";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref               AS Recorder,
	|	DocumentData.Period               AS Period,
	|	DocumentData.IntangibleAsset  AS IntangibleAsset,
	|	DocumentData.Organization          AS Organization,
	|	DocumentData.Department        AS Department,
	|	DocumentData.RecordInManAccounting    AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting   AS RecordInLocalAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "IntangibleAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.IntangibleAsset     AS IntangibleAsset,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.EstimatedRunningTime          AS EstimatedRunningTime,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(Query, QueryTexts, Registers)

	RegisterName = "IABookkeepingProcedureBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = IntangibleAssetsInitialRecognitionLocalization.QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(Query, QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		QueryText = 
		"SELECT
		|	DocumentData.Ref                                 AS Recorder,
		|	DocumentData.Period                                 AS Period,
		|	DocumentData.IntangibleAsset                    AS IntangibleAsset,
		|	DocumentData.Organization                            AS Organization,
		|
		|	VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting) AS BUState,
		|
		|	DocumentData.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
		|
		|	DocumentData.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
		|	DocumentData.ExpenseItemAccounting AS ExpenseItemAccounting,
		|	DocumentData.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
		|	DocumentData.DepartmentACC AS DepartmentACC,
		|	DocumentData.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
		|
		|	DocumentData.TransferExpensesToAnotherCompany    AS TransferExpensesToAnotherCompany,
		|	DocumentData.CompanyRecipientOfExpenses          AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref                                 AS Recorder,
		|	DocumentData.Period                                 AS Period,
		|	DocumentData.IntangibleAsset                    AS IntangibleAsset,
		|	DocumentData.Organization                            AS Organization,
		|
		|	VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting) AS BUState,
		|
		|	DocumentData.DepreciationAccrualManagementAccounting AS DepreciationAccrualAccounting,
		|
		|	DocumentData.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
		|	DocumentData.ExpenseItemManagementAccounting AS ExpenseItemAccounting,
		|	DocumentData.ExpensesDimensionManagementAccounting AS ExpensesDimensionAccounting,
		|	DocumentData.BusinessUnitManagementAccounting AS DepartmentACC,
		|	DocumentData.LineOfBusinessManagementAccounting AS LineOfBusinessBookkeeping,
		|
		|	DocumentData.TransferExpensesToAnotherCompany    AS TransferExpensesToAnotherCompany,
		|	DocumentData.CompanyRecipientOfExpenses          AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "IntangibleAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.IntangibleAsset                    AS IntangibleAsset,
	|	DocumentData.Organization                            AS Organization,
	|	VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)       AS State,
	|	DocumentData.DepreciationAccrualManagementAccounting                 AS AccrueDepreciationOrAmortization,
	|	DocumentData.MethodForReflectingMaExpenses              AS ExpensesPostingMethod,
	|	DocumentData.ExpenseItemManagementAccounting                       AS ExpenseItem,
	|	DocumentData.ExpensesDimensionManagementAccounting                    AS DimensionOfExpenses,
	|	DocumentData.BusinessUnitManagementAccounting                        AS Department,
	|	DocumentData.LineOfBusinessManagementAccounting              AS LineOfBusiness,
	|	DocumentData.TransferExpensesToAnotherCompany    AS TransferExpensesToAnotherCompany,
	|	DocumentData.CompanyRecipientOfExpenses          AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "IADepreciationParametersBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersNMABU(QueryTexts, "DocumentDataDetails");

	QueryText = IntangibleAssetsInitialRecognitionLocalization.QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(Query, QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		QueryText = 
		"SELECT
		|	DocumentData.Ref                      AS Recorder,
		|	DocumentData.Period                      AS Period,
		|	DocumentData.Period                      AS LastChangeDate,
		|	DocumentData.IntangibleAsset         AS IntangibleAsset,
		|	DocumentData.Organization                 AS Organization,
		|	DocumentData.UsefulLifeAccounting         AS UsefulLifeMonthsAC,
		|	DocumentData.UsefulLifeAccounting         AS UsefulLifeForCalculatingDepreciationMonth,
		|	DocumentData.EstimatedRunningTime              AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|	DocumentData.DepreciationAccrualFactor               AS DepreciationAccrualFactor,
		|	DocumentData.ResidualValueLocal AS ResidualValueMan
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref                      AS Recorder,
		|	DocumentData.Period                      AS Period,
		|	DocumentData.Period                      AS LastChangeDate,
		|	DocumentData.IntangibleAsset         AS IntangibleAsset,
		|	DocumentData.Organization                 AS Organization,
		|	DocumentData.UsefulLifeManagementAccounting         AS UsefulLifeMonthsAC,
		|	DocumentData.UsefulLifeManagementAccounting         AS UsefulLifeForCalculatingDepreciationMonth,
		|	DocumentData.EstimatedRunningTime              AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|	DocumentData.AccelerationFactorManagementAccounting      AS DepreciationAccrualFactor,
		|	DocumentData.ResidualValueLocal AS ResidualValueMan
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetAmortizationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	DocumentData.Period                             AS LastChangeDate,
	|	DocumentData.IntangibleAsset                AS IntangibleAsset,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.UsefulLifeManagementAccounting                AS UsefulLifeMonths,
	|	DocumentData.UsefulLifeManagementAccounting                AS UsefulLifeForCalculatingDepreciationMonth,
	|	DocumentData.EstimatedRunningTime                     AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	DocumentData.DepreciationAccrualMethodManagementAccounting       AS DepreciationMethod,
	|	DocumentData.AccelerationFactorManagementAccounting             AS AccelerationFactor,
	|	DocumentData.ResidualValueMan            AS ResidualValueMan,
	|	DocumentData.ResidualValueLocal        AS ResidualValueLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableInitialIntangibleAssetsInformation(Query, QueryTexts, Registers)
	
	RegisterName = "InitialIntangibleAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);

	QueryText = IntangibleAssetsInitialRecognitionLocalization.QueryTextTableInitialIntangibleAssetsInformation(Query, QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTInitialInformationOfIA(QueryTexts, "DocumentDataDetails");
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
		
		QueryText = 
		"SELECT
		|	DocumentData.Ref              AS Recorder,
		|	DocumentData.Period              AS Period,
		|	DocumentData.IntangibleAsset AS IntangibleAsset,
		|	DocumentData.Organization         AS Organization,
		|
		|	CASE
		|		WHEN DocumentData.RecordInManAccounting
		|			THEN DocumentData.Period
		|		ELSE InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting
		|	END AS DateOfRecognitionManagementAccounting,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.Period
		|		ELSE InitialIntangibleAssetsInformation.DateOfRecognitionAccounting
		|	END AS DateOfRecognitionAccounting,
		|
		|	CASE
		|		WHEN DocumentData.RecordInManAccounting
		|			THEN DocumentData.Ref
		|		ELSE InitialIntangibleAssetsInformation.DocumentOfRecognitionManagementAccounting
		|	END AS DocumentOfRecognitionManagementAccounting,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.Ref
		|		ELSE InitialIntangibleAssetsInformation.DocumentOfRecognitionAccounting
		|	END AS DocumentOfRecognitionAccounting,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.DepreciationMethodAccounting
		|		ELSE InitialIntangibleAssetsInformation.DepreciationMethodAccounting
		|	END AS DepreciationMethodAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN ISNULL(CostCalculation.AmountOfUU, DocumentData.InitialCostMA)
		|		ELSE InitialIntangibleAssetsInformation.InitialCostMA
		|	END AS InitialCostMA,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting
		|			THEN ISNULL(CostCalculation.AmountAccounting, DocumentData.InitialCostLocalAccounting)
		|		ELSE InitialIntangibleAssetsInformation.InitialCostLocalAccounting
		|	END AS InitialCostLocalAccounting
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = DocumentData.Ref
		|			AND CostCalculation.AccountingObject = DocumentData.IntangibleAsset
		|
		|		LEFT JOIN TTInitialInformationOfIA AS InitialIntangibleAssetsInformation
		|		ON InitialIntangibleAssetsInformation.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref              AS Recorder,
		|	DocumentData.Period              AS Period,
		|	DocumentData.IntangibleAsset AS IntangibleAsset,
		|	DocumentData.Organization         AS Organization,
		|
		|	DocumentData.Period AS DateOfRecognitionManagementAccounting,
		|	DocumentData.Period AS DateOfRecognitionAccounting,
		|
		|	DocumentData.Ref AS DocumentOfRecognitionManagementAccounting,
		|	DocumentData.Ref AS DocumentOfRecognitionAccounting,
		|
		|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting,
		|
		|	ISNULL(CostCalculation.AmountOfUU, DocumentData.InitialCostMA) AS InitialCostMA,
		|	ISNULL(CostCalculation.AmountAccounting, DocumentData.InitialCostLocalAccounting) AS InitialCostLocalAccounting
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = DocumentData.Ref
		|			AND CostCalculation.AccountingObject = DocumentData.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|";
		
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableIACost(Query, QueryTexts, Registers)

	RegisterName = "IACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	
	QueryText = IntangibleAssetsInitialRecognitionLocalization.QueryTextTableIACost(Query, QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	DocumentData.Ref                       AS Recorder,
		|	DocumentData.Period                       AS Period,
		|	DocumentData.IntangibleAsset          AS IntangibleAsset,
		|	DocumentData.Organization                  AS Organization,
		|	DocumentData.Department                AS Department,
		|	DocumentData.FinancialAccountingGroup       AS FinancialAccountingGroup,
		|	DocumentData.LineOfBusiness      AS LineOfBusiness,
		|	
		|	CASE
		|		WHEN NOT DocumentData.RecordInManAccounting
		|			THEN 0
		|		ELSE ISNULL(CostCalculation.AmountOfUU, DocumentData.InitialCostMA)
		|	END AS Cost,
		|
		|	CASE
		|		WHEN NOT DocumentData.RecordInLocalAccounting
		|			THEN 0
		|		ELSE ISNULL(CostCalculation.AmountAccounting, DocumentData.InitialCostLocalAccounting)
		|	END AS LocalCost,
		|	
		|	0 AS PreliminaryCostMan,
		|	0 AS PreliminaryCostLocal,
		|
		|	0 AS CorAmountPD,
		|	0 AS CorAmountTD,
		|	
		|	DocumentData.BusinessOperation        AS BusinessOperation,
		|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
		|	
		|	ISNULL(CostCalculation.Department, UNDEFINED)                AS DebitBusinessUnit,
		|	ISNULL(CostCalculation.LineOfBusiness, UNDEFINED)      AS CorLineOfBusiness,
		|	ISNULL(CostCalculation.ExpenseItem, UNDEFINED)               AS CorExpenseItem,
		|	ISNULL(CostCalculation.DimensionOfExpenses, UNDEFINED)            AS CorExpenditureDimension,
		|	
		|	NOT CostCalculation.AccountingObject IS NULL AS CostCalculation,
		|	
		|	ISNULL(CostCalculation.RowID, &IDOfUnusedFinRecord) AS FinRecordID,
		|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTCostCalculation AS CostCalculation
		|		ON CostCalculation.Ref = DocumentData.Ref
		|			AND CostCalculation.AccountingObject = DocumentData.IntangibleAsset
		|
		|UNION ALL
		|
		// You need to write down the preliminary cost separately to calculate depreciation
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	DocumentData.Ref                       AS Recorder,
		|	DocumentData.Period                       AS Period,
		|	DocumentData.IntangibleAsset          AS IntangibleAsset,
		|	DocumentData.Organization                  AS Organization,
		|	DocumentData.Department                AS Department,
		|	DocumentData.FinancialAccountingGroup       AS FinancialAccountingGroup,
		|	DocumentData.LineOfBusiness      AS LineOfBusiness,
		|	
		|	0                                            AS Cost,
		|	0                                            AS LocalCost,
		|	
		|	DocumentData.InitialCostMA    AS PreliminaryCostMan,
		|	DocumentData.InitialCostLocalAccounting    AS PreliminaryCostLocal,
		|
		|	0                                            AS CorAmountPD,
		|	0                                            AS CorAmountTD,
		|	
		|	DocumentData.BusinessOperation        AS BusinessOperation,
		|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
		|	
		|	UNDEFINED                                 AS DebitBusinessUnit,
		|	UNDEFINED                                 AS CorLineOfBusiness,
		|	UNDEFINED                                 AS CorExpenseItem,
		|	UNDEFINED                                 AS CorExpenditureDimension,
		|	
		|	FALSE                                         AS CostCalculation,
		|	
		|	&IDOfUnusedFinRecord        AS FinRecordID,
		|	UNDEFINED                                 AS BusinessTransactionSetting
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|WHERE
		|	DocumentData.InitialCostMA <> 0
		|		OR DocumentData.InitialCostLocalAccounting <> 0
		|";
	
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOtherExpenses(Query, QueryTexts, Registers)

	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	Add_Fields = "Recorder,VariancePeriod";
	Add_Fields = "Recorder,VariancePeriod,AITAmount";
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	NonCurrentAssetsInternal.TextOfTrafficRequestIncomeExpensesOtherAssetsLiabilitiesAcceptanceForAccounting(ListOfMergeRequests);	
	
	IntangibleAssetsInitialRecognitionLocalization.AddRequestTextTrafficTableIncomeExpensesOtherAssetsLiabilities(ListOfMergeRequests);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableCGUComposition(Query, QueryTexts, Registers)

	RegisterName = "CGUComposition";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.IntangibleAsset AS NonCurrentAsset,
	|	DocumentData.CGU AS CGU
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|WHERE
	|	DocumentData.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, Add_Fields)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields)

	RegisterName = "TTInitialOtherExpenses";
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);

	QueryText = IntangibleAssetsInitialRecognitionLocalization.QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields);

	If QueryText = Undefined Then
		
		RegisterRequests = New Array;
		RegisterRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
		
		QueryText =
		"SELECT
		|	DocumentData.Period                       AS Period,
		|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
		|	DocumentData.Organization                  AS Organization,
		|	TTCostCalculation.Department              AS Department,
		|	TTCostCalculation.ExpenseItem             AS ExpenseItem,
		|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
		|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
		|	UNDEFINED                                 AS VATActivityType,
		|
		|	TTCostCalculation.Sum                      AS AmountIncludingVAT,
		|	TTCostCalculation.AmountExcludingVAT                AS AmountExcludingVAT,
		|	TTCostCalculation.AmountOfUU                    AS AmountExcludingVATMan,
		|
		|	TTCostCalculation.AmountAccounting                    AS AmountIncludingVATCompl,
		|	TTCostCalculation.AmountAccounting                    AS AmountExcludingVATCompl,
		|
		|	0                                            AS PermanentDifference,
		|	0                                            AS CostTD,
		|
		|	DocumentData.BusinessOperation        AS BusinessOperation,
		|	UNDEFINED                                 AS ItemsLocationAttributes,
		|
		|	TTCostCalculation.RowID          AS FinRecordID,
		|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting,
		|
		|	DocumentData.Ref AS Recorder,
		|	TTCostCalculation.VariancePeriod AS VariancePeriod
		|
		|	,0 AS AITAmount
		|
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTCostCalculation AS TTCostCalculation
		|		ON TTCostCalculation.Ref = DocumentData.Ref
		|			AND TTCostCalculation.AccountingObject = DocumentData.IntangibleAsset
		|";
		RegisterRequests.Add(QueryText);
		
		QueryText = StrConcat(RegisterRequests, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf;

	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return IntangibleAssetsInitialRecognitionLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return IntangibleAssetsInitialRecognitionLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	IntangibleAssetsInitialRecognitionLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	
	IntangibleAssetsInitialRecognitionLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

EndProcedure

#EndRegion

#Region Workplace

// Generates data for the workplace.
// 
// Parameters:
//  Parameters - Structure - Contains:
//  	* Organization - CatalogRef.Companies -
//  	* Date - Date -
// 
// Returns:
//  ValueTable - Workplace data.
Function WorkplaceData(Parameters) Export
	
	QueryText = 
	"SELECT ALLOWED
	|	AvailableArticles.Ref AS Ref
	|INTO AvailableArticles
	|
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS AvailableArticles
	|WHERE
	|	AvailableArticles.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|	AND (AvailableArticles.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR AvailableArticles.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR AvailableArticles.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|	AND AvailableArticles.IntangibleAssetsAndRDExpenses
	|	
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OtherExpenses.IntangibleAsset AS IntangibleAsset,
	|	OtherExpenses.Organization AS Organization,
	|	
	|	SUM(OtherExpenses.CostInManagementAccounting) AS CostInManagementAccounting,
	|	SUM(OtherExpenses.CostInAccounting) AS CostInAccounting,
	|	SUM(OtherExpenses.CostInTaxAccounting) AS CostInTaxAccounting
	|
	|INTO OtherExpenses
	|
	|FROM
	|	(SELECT
	|		OtherExpenses.DimensionOfExpenses AS IntangibleAsset,
	|		OtherExpenses.Organization AS Organization,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN OtherExpenses.SumManBalance
	|			ELSE 0
	|		END AS CostInManagementAccounting,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN OtherExpenses.SumComplBalance
	|			ELSE 0
	|		END AS CostInAccounting,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN OtherExpenses.SumComplBalance - OtherExpenses.PermanentDifferenceBalance -  OtherExpenses.CostTDBalance
	|			ELSE 0
	|		END AS CostInTaxAccounting
	|
	|	FROM
	|		AccumulationRegister.OtherExpenses.Balance(
	|			&BegOfMonth,
	|			(Organization = &Organization
	|					OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|				AND ExpenseItem IN (
	|					SELECT
	|						AvailableArticles.Ref
	|					FROM
	|				 		AvailableArticles)
	|			) AS OtherExpenses
	|
	|	UNION ALL
	|
	|	SELECT
	|		OtherExpenses.DimensionOfExpenses AS IntangibleAsset,
	|		OtherExpenses.Organization AS Organization,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN CASE 
	|						WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|							THEN OtherExpenses.SumMan
	|						ELSE -OtherExpenses.SumMan
	|					END
	|			ELSE 0
	|		END AS CostInManagementAccounting,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN CASE 
	|						WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|							THEN OtherExpenses.SumCompl
	|						ELSE -OtherExpenses.SumCompl
	|					END
	|			ELSE 0
	|		END AS CostInAccounting,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN CASE 
	|						WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|							THEN OtherExpenses.SumCompl
	|						ELSE -OtherExpenses.SumCompl
	|					END
	|			ELSE 0
	|		END AS CostInTaxAccounting
	|
	|	FROM
	|		AccumulationRegister.OtherExpenses AS OtherExpenses
	|	WHERE
	|		OtherExpenses.Period BETWEEN &BegOfMonth AND &Date
	|		AND OtherExpenses.Active
	|
	|		AND (OtherExpenses.Organization = &Organization
	|				OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|		AND OtherExpenses.ExpenseItem IN (
	|					SELECT
	|						AvailableArticles.Ref
	|					FROM
	|				 		AvailableArticles)
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.DimensionOfExpenses AS IntangibleAsset,
	|		DocumentData.Organization AS Organization,
	|	
	|		0 AS CostInManagementAccounting,
	|		0 AS CostInAccounting,
	|		0 AS CostInTaxAccounting
	|
	|	FROM
	|		Document.InventoryConsumption AS DocumentData
	|
	|			INNER JOIN Document.InventoryConsumption.Goods GoodsTable
	|			ON GoodsTable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BegOfMonth AND &Date
	|		AND DocumentData.Posted
	|
	|		AND (DocumentData.Organization = &Organization
	|				OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|		AND GoodsTable.ExpenseItem IN (
	|					SELECT
	|						AvailableArticles.Ref
	|					FROM
	|				 		AvailableArticles)
	|
	|	) AS OtherExpenses
	|
	|WHERE
	|	VALUETYPE(OtherExpenses.IntangibleAsset) = TYPE(Catalog.IntangibleAssets)
	|	AND CAST(OtherExpenses.IntangibleAsset AS Catalog.IntangibleAssets).KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|
	|GROUP BY
	|	OtherExpenses.IntangibleAsset,
	|	OtherExpenses.Organization
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.IntangibleAsset AS IntangibleAsset
	|
	|INTO ListOfIA
	|
	|FROM
	|	OtherExpenses AS OtherExpenses
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	MAX(ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting))) AS BUState,
	|	MAX(ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting))) AS StateTa,
	|	MAX(ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting))) AS StateOfTheUU
	|
	|INTO IAState
	|
	|FROM
	|	ListOfIA AS ListOfIA
	|
	|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&Date, 
	|			(Organization, IntangibleAsset) IN
	|				(SELECT
	|					ListOfIA.Organization,
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfIA AS ListOfIA)) AS IntangibleAssetsAccountingProcedureManagementAccounting
	|		ON IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = ListOfIA.IntangibleAsset
	|
	|		LEFT JOIN InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
	|			&Date, 
	|			(Organization, IntangibleAsset) IN
	|				(SELECT
	|					ListOfIA.Organization,
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfIA AS ListOfIA)) AS IABookkeepingProcedureBookkeepingAndTaxAccounting
	|		ON IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = ListOfIA.IntangibleAsset
	|
	|GROUP BY
	|	ListOfIA.Organization,
	|	ListOfIA.IntangibleAsset
	|
	|INDEX BY
	|	Organization,
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherExpenses.IntangibleAsset AS Ref,
	|
	|	OtherExpenses.Organization AS Organization,
	|
	|	ISNULL(IAState.StateOfTheUU, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS StateOfTheUU,
	|	ISNULL(IAState.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS BUState,
	|	ISNULL(IAState.StateTa, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS StateTa,
	|
	|	OtherExpenses.CostInManagementAccounting AS CostInManagementAccounting,
	|	OtherExpenses.CostInAccounting AS CostInAccounting,
	|	OtherExpenses.CostInTaxAccounting AS CostInTaxAccounting
	|
	|FROM
	|	OtherExpenses AS OtherExpenses
	|
	|		LEFT JOIN IAState AS IAState
	|		ON OtherExpenses.Organization = IAState.Organization
	|			AND OtherExpenses.IntangibleAsset = IAState.IntangibleAsset
	|
	|WHERE
	|	OtherExpenses.CostInManagementAccounting <> 0
	|	OR OtherExpenses.CostInAccounting <> 0
	|
	|ORDER BY
	|	Organization,
	|	Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("BegOfMonth", BegOfMonth(?(Parameters.Date <> '000101010000', Parameters.Date, CurrentSessionDate())));
	Query.SetParameter("Date", EndOfDay(?(Parameters.Date <> '000101010000', Parameters.Date, CurrentSessionDate())));
	Query.SetParameter("Organization", Parameters.Organization);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	IntangibleAssetsInitialRecognitionLocalization.AddOptionsForSelectingArticlesAndAnalytics(ArticleSelectionAndAnalyticsOptions);
	
	// ExpenseItemAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionAccounting");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	// ExpenseItemManagementAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemManagementAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionManagementAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemManagementAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionManagementAccounting");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "ExpenseRecordMethodAC", Parameters);
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "ExpenseRecordMethodTA", Parameters);
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "MethodForReflectingMaExpenses", Parameters);
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CostGenerationProcedure", Parameters);

EndProcedure

// 
// Parameters:
//  Object - DocumentObject.IntangibleAssetsInitialRecognition2_4 - 
//  ReportErrors - Boolean - 
//  ArrayOfLineNumbers - Array - 
// 
// Returns:
//  Boolean - 
Function FillInBasedOnInventory(Object, ReportErrors, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return True;
	EndIf;
	
	DataToFill = Documents.IntangibleAssetsPhysicalCount.FillingDataBasedOnInventory(
							Object.DocumentBasis, 
							Object.Date, 
							Enums.ActionsBasedOnPhysicalInventoryCount.Recognition, 
							ArrayOfLineNumbers);
							
	If DataToFill.Attributes = Undefined
		Or DataToFill.Attributes.Count() = 0
		Or DataToFill.TabularSection = Undefined 
		Or DataToFill.TabularSection.Count() = 0 Then
		
		If ReportErrors Then
			ErrorText = NStr("vi = 'Trong chứng từ %1 không có dòng nào yêu cầu tạo ghi nhận vào kế toán';
							|ru = 'В документе %1 отсутствуют строки требующие создания принятия к учету';
							|en = 'There are no lines which require recognition in the %1 document'; fa = 'There are no lines which require recognition in the %1 document';
							|it = 'There are no lines which require recognition in the %1 document';
							|pl = 'There are no lines which require recognition in the %1 document';
							|tr = '%1 belgesinde muhasebeleştirme oluşturulması gereken satır bulunmuyor'");
			ErrorText = StrTemplate(ErrorText, Object.DocumentBasis);
			Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		EndIf;
		
		Return False;
		
	EndIf;
	
	Selection = DataToFill.Attributes[0];
	FillPropertyValues(Object, Selection);
	

	Selection = DataToFill.TabularSection[0];
		
	FillPropertyValues(Object, Selection);
	
	If Object.PostInAccounting Then
		Object.InitialCostLocalAccounting = Selection.ActualCostAC;
	EndIf; 
	
	If Object.PostInAccounting Then
		Object.InitialCostTA = Selection.ActualCostTA;
	EndIf; 

	If Object.RecordInManAccounting Then
		Object.InitialCostMA = Selection.CostActualMan;
	EndIf; 

	If Selection.PostInAccounting Then
		Object.PostInAccounting = True;
	EndIf; 
	If Selection.RecordInTA Then
		Object.RecordInTA = True;
	EndIf; 
	If Selection.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf; 
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;
	
	Return True;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// Adds procedures to the list that handle updating information security
// data for all supported library versions or configurations.
// Called before the start of updating the information security data to build an update plan.
//
//  Handlers - Value tablesdescription of fields, see the procedure
//                Updating the information database.New Update processing table.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Monopoly Mode = False;
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.IntangibleAssetsInitialRecognition2_4.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("300f41e6-6029-451d-8f0e-b5a1f807c520");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.IntangibleAssetsInitialRecognition2_4.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Cập nhật các chứng từ ""Ghi nhận vào kế toán TSCĐVH"":
								  |- Điền mục tin ""Phương thức hình thành giá trị""
								  |- Điền mục tin ""Khấu trừ thuế đầu tư""';
								  |ru = 'Обновляет документы ""Принятие к учету НМА"":
								  |- Заполняет реквизит ""Порядок формирования стоимости""
								  |- Заполняет реквизит ""Инвестиционный налоговый вычет""';
								  |en = 'Updates the ""Intangible assets — Initial recognition"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.
								  |- Fills in the ""Investment tax deduction"" attribute.'; fa = 'Updates the ""Intangible assets — Initial recognition"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.
								  |- Fills in the ""Investment tax deduction"" attribute.';
								  |it = 'Updates the ""Intangible assets — Initial recognition"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.
								  |- Fills in the ""Investment tax deduction"" attribute.';
								  |pl = 'Updates the ""Intangible assets — Initial recognition"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.
								  |- Fills in the ""Investment tax deduction"" attribute.';
								  |tr = '""Maddi Olmayan Varlık Muhasebeleştirme"" belgelerini günceller: 
								  | - ""Maliyet oluşturma düzeni"" özniteliğini doldurur 
								  | - ""Yatırım vergi indirimi"" özniteliğini doldurur'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetsInitialRecognition2_4.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.IntangibleAssetsInitialRecognition2_4.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.IntangibleAssetsInitialRecognition2_4.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.IntangibleAssetsInitialRecognition2_4";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Ref.Date DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText =
	"SELECT
	|	DocumentData.Ref
	|FROM
	|	Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|WHERE
	|	DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.EmptyRef)
	|";
	Query = New Query(QueryText);

	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.IntangibleAssetsInitialRecognition2_4.ProcessDataForMigrationToNewVersion");

	FullObjectName = "Document.IntangibleAssetsInitialRecognition2_4";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;

	For Each Document In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Document.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.IntangibleAssetsInitialRecognition2_4
			If DocumentObject = Undefined Then
				CommitTransaction();
				Continue;
			EndIf;
			
			If Not ValueIsFilled(DocumentObject.CostGenerationProcedure) Then
				DocumentObject.CostGenerationProcedure = Enums.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeDocumentCreationDateInCost;
			EndIf;
			

			If DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(DocumentObject.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Document.Ref);
			
		EndTry;
		
	EndDo;
	
 	NonCurrentAssetsInternal.CheckHandlerExecution(
 		ObjectsWithIssuesCount, 
 		ObjectsProcessed, 
 		FullObjectName);
 		
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ObjectsProcessed);	
	
EndProcedure
 
#EndRegion


#EndRegion

#EndIf
