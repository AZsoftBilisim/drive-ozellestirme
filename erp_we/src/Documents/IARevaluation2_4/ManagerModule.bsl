
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
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	
	IARevaluationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.IARevaluation2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
		QueryTexts = New ValueList;
		QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		IARevaluationLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
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
	NonCurrentAssetsInternal.RequestTextsForRevaluation(Query, QueryTexts, "IA", Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	IARevaluationLocalization.TablesOfDeferredMotionFormation(QueryTexts);

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
	
	IARevaluationLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "revaluation of IA".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.IARevaluation2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.IARevaluation2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.IARevaluation2_4);
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
	
	
	
	IARevaluationLocalization.AddReportCommands(ReportsCommands, Parameters);

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

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.IARevaluation2_4";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
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
	
	If RegisterName = "DocumentsRegistry" Then
		
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
	|	DocumentData.Number  AS Number
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
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	Document.IARevaluation2_4 AS DocumentsList
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
	|	DocumentData.Posted               AS Posted,
	|	DocumentData.DeletionMark        AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	VALUE(Enum.BusinessTransactions.IARevaluation) AS BusinessOperation,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Department          AS Department,
	|	DocumentData.IncomeItem          AS IncomeItem,
	|	DocumentData.DimensionOfRevenue       AS DimensionOfRevenue,
	|	DocumentData.IncomeBusinessUnit   AS IncomeBusinessUnit,
	|	DocumentData.LineOfBusinessIncome AS LineOfBusinessIncome,
	|	DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData AS IncomeBusinessUnitAndLineOfBusinessMatchAccountingData,
	|	DocumentData.ExpenseItem         AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses      AS DimensionOfExpenses,
	|	DocumentData.ExpensesBusinessUnit  AS ExpensesBusinessUnit,
	|	DocumentData.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData AS BusinessUnitAndLineOfBusinessMatchAccountingData,
	|	DocumentData.RevaluateAtFairValue AS RevaluateAtFairValue,
	|	ISNULL(DocumentData.ExpenseItem.EnteredInTaxAccounting, FALSE) AS EnteredInTaxAccounting,
	|	DocumentData.EmployeeResponsible          AS EmployeeResponsible,
	|	DocumentData.Comment            AS Comment
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.IARevaluation2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataIATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.IntangibleAsset AS AccountingObject,
	|	DocumentTable.IntangibleAsset AS IntangibleAsset,
	|	DocumentTable.CostInManagementAccounting AS CostInManagementAccounting,
	|	DocumentTable.CostInAccounting AS CostInAccounting
	|
	|INTO DocumentDataIATable
	|
	|FROM
	|	Document.IARevaluation2_4.IA AS DocumentTable
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
	|	IntangibleAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.IARevaluation2_4"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.IARevaluation);
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Đánh giá lại tài sản cố định vô hình';
															|ru = 'Переоценка НМА';
															|en = 'Revaluate intangible assets'; fa = 'تجدید ارزیابی دارایی‌های نامشهود';
															|it = 'Rivalutazione Beni Immateriali';
															|pl = 'Przeszacowanie wartości niematerialnych';
															|tr = 'Maddi olmayan varlıkların yeniden değerlemesi'"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("ArticleAP_AccountingObject", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets);
	
	ValuesOfHoldingParameters.Insert("BO_CostIncrease", Enums.BusinessTransactions.IntangibleAssetsCostAddition);
	ValuesOfHoldingParameters.Insert("BO_CostIncreaseDueToMarkdowns", Enums.BusinessTransactions.IncreaseIntangibleAssetCostAtDevaluationExpense);
	ValuesOfHoldingParameters.Insert("BO_CostReduction", Enums.BusinessTransactions.IntangibleAssetsCostDecrease);
	ValuesOfHoldingParameters.Insert("HO_CostReductionDueToAdditionalAssessment", Enums.BusinessTransactions.DecreaseIntangibleAssetCostAtFinalAppraisalExpense);

	ValuesOfHoldingParameters.Insert("BO_IncreasedDepreciation", Enums.BusinessTransactions.IncreaseInIntangibleAssetAmortization);
	ValuesOfHoldingParameters.Insert("BO_IncreaseInDepreciationDueToMarkdowns", Enums.BusinessTransactions.IncreaseIntangibleAssetAmortizationAtDevaluationExpense);
	ValuesOfHoldingParameters.Insert("BO_DecreaseInDepreciation", Enums.BusinessTransactions.DecreaseInIntangibleAssetAmortization);
	ValuesOfHoldingParameters.Insert("HO_ReductionOfDepreciationDueToAdditionalValuation", Enums.BusinessTransactions.DecreaseIntangibleAssetAmortizationAtFinalAppraisalExpense);

	ValuesOfHoldingParameters.Insert("SettingUpHO_CostIncrease", Catalogs.BusinessTransactionsSettings.IntangibleAssetsCostAddition);
	ValuesOfHoldingParameters.Insert("SettingUpBT_CostIncreaseDueToMarkdowns", Catalogs.BusinessTransactionsSettings.IncreaseIntangibleAssetCostAtDevaluationExpense);
	ValuesOfHoldingParameters.Insert("SettingUpHO_CostReduction", Catalogs.BusinessTransactionsSettings.IntangibleAssetsCostDecrease);
	ValuesOfHoldingParameters.Insert("SettingUpBT_CostReductionDueToAdditionalAssessment", Catalogs.BusinessTransactionsSettings.DecreaseIntangibleAssetCostAtFinalAppraisalExpense);
		
	ValuesOfHoldingParameters.Insert("SettingHO_IncreaseDepreciation", Catalogs.BusinessTransactionsSettings.IncreaseInIntangibleAssetAmortization);
	ValuesOfHoldingParameters.Insert("SettingUpBT_IncreaseDepreciationDueToMarkdowns", Catalogs.BusinessTransactionsSettings.IncreaseIntangibleAssetAmortizationAtDevaluationExpense);
	ValuesOfHoldingParameters.Insert("SettingHO_ReductionOfDepreciation", Catalogs.BusinessTransactionsSettings.DecreaseInIntangibleAssetAmortization);
	ValuesOfHoldingParameters.Insert("SettingUpBT_ReductionOfDepreciationDueToAdditionalAssessment", Catalogs.BusinessTransactionsSettings.DecreaseIntangibleAssetAmortizationAtFinalAppraisalExpense);
	
	ValuesOfHoldingParameters.Insert("BO_DepreciationReductionNetMethod", Enums.BusinessTransactions.DecreaseIntangibleAssetAmortizationCashMethod);
	ValuesOfHoldingParameters.Insert("SettingUpBT_DepreciationReductionBalanceMethod", Catalogs.BusinessTransactionsSettings.DecreaseIntangibleAssetAmortizationCashMethod);
	
	ValuesOfHoldingParameters.Insert("BO_RecoverImpairmentLoss", Enums.BusinessTransactions.RecoverImpairmentLoss);
	ValuesOfHoldingParameters.Insert("SettingUpBT_RecoveryOfImpairmentLoss", Catalogs.BusinessTransactionsSettings.RecoverImpairmentLoss);
	
	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0) AS RecNo,
	|	DocumentData.Ref                AS Ref,
	|	TableOfIA.IntangibleAsset        AS IntangibleAsset,
	|	&BusinessOperation                AS BusinessOperation,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Department         AS Department,
	|	DocumentData.Date                  AS Date,
	|	&MetadataIdentifier              AS RefType,
	|	DocumentData.Posted              AS Posted,
	|	DocumentData.RecordInManAccounting     AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting    AS RecordInLocalAccounting
	|
	|FROM
	|	Document.IARevaluation2_4 AS DocumentData
	|
	|		LEFT JOIN Document.IARevaluation2_4.IA AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
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
	|	DocumentData.Ref         AS Ref,
	|	DocumentData.Date           AS IBDocumentDate,
	|	DocumentData.Number          AS IBDocumentNumber,
	|	&MetadataIdentifier       AS RefType,
	|	DocumentData.Organization    AS Organization,
	|	&BusinessOperation         AS BusinessOperation,
	|	UNDEFINED                   AS LineOfBusiness,
	|	DocumentData.Department  AS Department,
	|	DocumentData.EmployeeResponsible  AS EmployeeResponsible,
	|	DocumentData.Comment    AS Comment,
	|	DocumentData.Posted       AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE                           AS AdditionalRecord,
	|	DocumentData.Date           AS SourceDocumentDate,
	|	&NumberForPrinting                 AS SourceDocumentNumber,
	|	FALSE                           AS ReverseTransactionCorrection,
	|	UNDEFINED                   AS ReversedDocument,
	|	UNDEFINED                   AS CorrectedDocument,
	|	DocumentData.Date           AS RecordingInAccountingDate,
	|	UNDEFINED                   AS Priority
	|
	|FROM
	|	Document.IARevaluation2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return IARevaluationLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return IARevaluationLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	IARevaluationLocalization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	// ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	// IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.IARevaluation2_4 - 
//  ReportErrors - Boolean - 
//  ArrayOfLineNumbers - Array, Undefined - 
Procedure FillInBasedOnInventory(Object, ReportErrors, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return;
	EndIf;
	
	DataToFill = Documents.IntangibleAssetsPhysicalCount.FillingDataBasedOnInventory(
							Object.DocumentBasis, 
							Object.Date, 
							Enums.ActionsBasedOnPhysicalInventoryCount.Revaluation, 
							ArrayOfLineNumbers);
		
	If DataToFill.Attributes = Undefined
		Or DataToFill.Attributes.Count() = 0
		Or DataToFill.TabularSection = Undefined 
		Or DataToFill.TabularSection.Count() = 0 Then
		
		If ReportErrors Then
			ErrorText = NStr("vi = 'Trong chứng từ %1 không có dòng nào yêu cầu đánh giá lại';
							|ru = 'В документе %1 отсутствуют строки требующие создания переоценки';
							|en = 'No lines that require creating revaluation in the %1 document'; fa = 'No lines that require creating revaluation in the %1 document';
							|it = 'No lines that require creating revaluation in the %1 document';
							|pl = 'No lines that require creating revaluation in the %1 document';
							|tr = '%1 belgesinde yeniden değerleme oluşturulması gereken satır bulunmuyor'");
			ErrorText = StrTemplate(ErrorText, Object.DocumentBasis);
			Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		EndIf;
		
		Return;
		
	EndIf;
	
	Selection = DataToFill.Attributes[0];
	FillPropertyValues(Object, Selection);
	Object.RevaluateAtFairValue = False;
	
	RecordInLocalAccounting = False;
	RecordInManAccounting = False;
	
	For Each Selection In DataToFill.TabularSection Do
		
		If Not Selection.PostInAccounting And Not Selection.RecordInManAccounting Then
			Continue;
		EndIf;
		
		RowData = Object.IA.Add();
		RowData.IntangibleAsset = Selection.IntangibleAsset;
		
		If Selection.PostInAccounting Then
			RowData.CostInAccounting = Selection.ActualCostAC;
			RecordInLocalAccounting = True;
		EndIf; 
		
		If Selection.RecordInManAccounting Then
			RowData.CostInManagementAccounting = Selection.CostActualMan;
			RecordInManAccounting = True;
		EndIf; 
		
	EndDo;
	
	If Object.IA.Count() <> 0 Then
		Object.RecordInLocalAccounting = RecordInLocalAccounting;
		Object.RecordInManAccounting = RecordInManAccounting;
	EndIf;
	
EndProcedure

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization,EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization,EmployeeResponsible";

	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "RevaluateAtFairValue", Parameters);

EndProcedure

#EndRegion

#EndRegion

#EndIf
