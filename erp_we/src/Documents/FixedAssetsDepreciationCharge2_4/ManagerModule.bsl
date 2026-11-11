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
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("ImpairmentFA");
	
	FixedAssetsDepreciationChargeLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.FixedAssetsDepreciationCharge2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts, Registers);
		QueryTextTableImpairmentFA(QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers);
		
		FixedAssetsDepreciationChargeLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.StatementCalculationOfAssetsDepreciation.AddReportCommandOnFADepreciationDocument(ReportsCommands);
	
	FixedAssetsDepreciationChargeLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	FixedAssetsDepreciationChargeLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	FixedAssetsDepreciationChargeLocalization.AddGenerationCommands(GenerationCommands, Parameters);

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

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	Presentation = StrTemplate(NStr("vi = 'Khấu hao TSCĐ hữu hình %1 cho %2';
									|ru = 'Амортизация ОС %1 за %2';
									|en = 'The %1 Fixed assets — Depreciation charge for %2'; fa = 'The %1 Fixed assets — Depreciation charge for %2';
									|it = 'Ammortamento di immobilizzazioni materiali %1 per %2';
									|pl = 'Amortyzacja środków trwałych %1 za %2';
									|tr = '%2 için %1 SV amortismanı'"), Data.Number, Format(Data.Date, NStr("vi = 'ДФ=''ММММ гггг''';
																																	|ru = 'ДФ=''ММММ гггг''';
																																	|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																																	|it = 'ДФ=''ММММ гггг''';
																																	|pl = 'DF=''MMMM yyyy''';
																																	|tr = 'DF=''MMMM yyyy'''")));
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Performs depreciation calculation in the specified month and records it using the document "depreciation of fixed assets".
// 
// Parameters:
//  InitialCalculationParameters - See FixedAssetDepreciationCalculation.ExecutionParameters
// 
// Returns:
//  Structure - calculation result:
//  	* NumberOfProcessedData - Number -
// 		* HasErrors - Boolean - True if there are errors 
// 		* ErrorText  - String - error text
//
Function CalculateDepreciation(InitialCalculationParameters) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FixedAssetsDepreciationCharge.CalculateDepreciation");
	
	CalculationParameters = Common.CopyRecursive(InitialCalculationParameters); // FixedAssetDepreciationCalculation.ExecutionParameters
	NonCurrentAssetsInternal.AddAccountingParametersForNonCurrentAssets(CalculationParameters);
	
	If CalculationParameters.TempTablesManager = Undefined Then
		CalculationParameters.TempTablesManager = New TempTablesManager;
		InitialCalculationParameters.TempTablesManager = CalculationParameters.TempTablesManager;
	EndIf;
	
	Try
		
		PrepareListOfObjects(CalculationParameters);
		DepreciationAdjustmentForPreviousPeriod(CalculationParameters);
		PrepareParametersForDepreciationCalculation(CalculationParameters);
		PerformDepreciationCalculation(CalculationParameters);
		
		RegisterDepreciationCalculationErrors(CalculationParameters);
	
		TMCommonUse.DestroyTemporaryTables(CalculationParameters.TempTablesManager,, CalculationParameters.TablesToUse);
		
		RecordDepreciationCalculation(CalculationParameters);
	
	Except
		
		ErrorInfo = ErrorInfo();
		
		CalculationParameters.HasErrors = True;
		CalculationParameters.ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		
		If CalculationParameters.RegisterErrors Then
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
				CalculationParameters.Period, 
				CalculationParameters.DepreciationPackages.UnloadColumn("Organization"),
				CalculationParameters.ErrorText);
			
		EndIf;
		
	EndTry; 
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, CalculationParameters.NumberOfProcessedData);
	
	CalculationResult2 = New Structure;
	CalculationResult2.Insert("NumberOfProcessedData", CalculationParameters.NumberOfProcessedData);
	CalculationResult2.Insert("HasErrors", CalculationParameters.HasErrors);
	CalculationResult2.Insert("ErrorText", CalculationParameters.ErrorText);
	
	Return CalculationResult2;
	
EndFunction

// Specifies the number of the depreciation package.
//
// Parameters:
//  Organization	 - CatalogRef.Companies - Organization.
//
// Returns:
//  Number - Package number.
//
Function DefaultPackageNumber(Organization) Export

	If Not ValueIsFilled(Organization) Then
		Return 0;
	EndIf;
	
	QueryText = 
	"SELECT
	|	MAX(FixedAssetDepreciationPackages.PackageNumber) AS PackageNumber,
	|	ISNULL(COUNT(DISTINCT FixedAssetDepreciationPackages.PackageNumber), 0) AS NumberOfRooms
	|FROM
	|	InformationRegister.FixedAssetDepreciationPackages AS FixedAssetDepreciationPackages
	|WHERE
	|	FixedAssetDepreciationPackages.Organization = &Organization
	|
	|GROUP BY
	|	FixedAssetDepreciationPackages.Organization";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	PackageNumber = 0;
	If Selection.Next() Then
		If Selection.NumberOfRooms = 1 Then
			PackageNumber = Selection.PackageNumber;
		EndIf; 
	EndIf;

	Return PackageNumber;
	
EndFunction

// Adds the formation of a temporary table of accrued Amortization to the list of requests.
//  It is used for universal depreciation.
//  The created temporary table can be used to generate movements by registers.
//
// Parameters:
//  ListOfRequests - Array, ValueList - List of requests.
//  SubqueryText	- String - The text of the query that contains the result of calculating depreciation.
//  CarryingOutDocument - Boolean - True if the procedure is called when the document is being held.
//
Procedure RequestTextTTAccruedDepreciation(ListOfRequests, SubqueryText, CarryingOutDocument = False) Export
	
	TableName = "AccruedDepreciation";
	
	QueryText = FixedAssetsDepreciationChargeLocalization.RequestTextTTAccruedDepreciation();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset) AS VNAView,
		|	AccruedDepreciation.Ref AS Ref,
		|	AccruedDepreciation.CalculationPeriod AS CalculationPeriod,
		|	AccruedDepreciation.AccrualPeriod AS AccrualPeriod,
		|	AccruedDepreciation.Organization AS Organization,
		|	ISNULL(FixedAssetDepreciationPackages.PackageNumber, 0) AS PackageNumber,
		|	AccruedDepreciation.Department AS Department,
		|	AccruedDepreciation.DebitBusinessUnit AS DebitBusinessUnit,
		|	AccruedDepreciation.FixedAsset AS FixedAsset,
		|	AccruedDepreciation.CGU AS CGU,
		|	AccruedDepreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	AccruedDepreciation.LineOfBusiness AS LineOfBusiness,
		|	AccruedDepreciation.CorLineOfBusiness AS CorLineOfBusiness,
		|	AccruedDepreciation.ExpenseItem AS ExpenseItem,
		|	AccruedDepreciation.DimensionOfExpenses AS DimensionOfExpenses,
		|	FALSE AS TransferExpensesToAnotherCompany,
		|	VALUE(Catalog.Companies.EmptyRef) AS CompanyRecipientOfExpenses,
		|	FALSE AS AccrueDepreciation,
		|	AccruedDepreciation.ThisIsAnAdditionalAccrual AS ThisIsAnAdditionalAccrual,
		|	AccruedDepreciation.ThisIsAdditionalChargeAccounting AS ThisIsAdditionalChargeAccounting,
		|	FALSE AS ThisIsDepreciationPremium,
		|	MAX(AccruedDepreciation.ThisIsRecordingOfDifference) AS ThisIsRecordingOfDifference,
		|	MAX(AccruedDepreciation.ThisIsAdjustmentOfDepreciationForPreviousPeriod) AS ThisIsAdjustmentOfDepreciationForPreviousPeriod,
		|	MAX(AccruedDepreciation.LifeSpentPastPeriod) AS LifeSpentPastPeriod,
		|	MAX(AccruedDepreciation.LifeSpentCurrentPeriod) AS LifeSpentCurrentPeriod,
		|	MAX(AccruedDepreciation.LifeSpentPastPeriodAccounting) AS LifeSpentPastPeriodAccounting,
		|	MAX(AccruedDepreciation.LifeSpentCurrentPeriodAccounting) AS LifeSpentCurrentPeriodAccounting,
		|	MAX(AccruedDepreciation.CostUsedToCalculateDepreciationManag) AS CostUsedToCalculateDepreciationManag,
		|	MAX(AccruedDepreciation.CostUsedToCalculateDepreciationLocal) AS CostUsedToCalculateDepreciationLocal,
		|	MAX(AccruedDepreciation.ImpairmentBalanceLocal) AS ImpairmentBalanceLocal,
		|	MAX(AccruedDepreciation.ImpairmentBalanceMan) AS ImpairmentBalanceMan,
		|	MAX(AccruedDepreciation.AccountingProcedureMA) AS AccountingProcedureMA,
		|	UNDEFINED AS AccountingProcedureAC,
		|	MAX(AccruedDepreciation.ProcedureForCalculatingDepreciationOfMa) AS ProcedureForCalculatingDepreciationOfMa,
		|	MAX(AccruedDepreciation.ProcedureForCalculatingDepreciationAC) AS ProcedureForCalculatingDepreciationAC,
		|	MAX(AccruedDepreciation.PostingOptionForImpairedFADepreciation) AS PostingOptionForImpairedFADepreciation,
		|	MAX(AccruedDepreciation.DepreciationMethodVersionMA) AS DepreciationMethodVersionMA,
		|	MAX(AccruedDepreciation.DepreciationMethodVersionLA) AS DepreciationMethodVersionLA,
		|
		|	&TableRowID_ AS RowID,
		|
		|	SUM(AccruedDepreciation.AmountOfUU) AS AmountOfUU,
		|	SUM(AccruedDepreciation.AmountAccounting) AS AmountAccounting,
		|	0 AS AmountFA,
		|	0 AS AmountPermanentDifferences,
		|	0 AS AmountTemporaryDifferences,
		|	0 AS CFAmount,
		|	0 AS SumOfNUCF,
		|	0 AS PRCFAmount,
		|	0 AS AmountOfVRCF,
		|
		|	SUM(AccruedDepreciation.ImpairmentMA) AS ImpairmentMA,
		|	SUM(AccruedDepreciation.ImpairmentAC) AS ImpairmentAC,
		|	0 AS ImpairmentOfCF
		|
		|INTO AccruedDepreciation
		|
		|FROM
		|	&SubqueryText AS AccruedDepreciation
		|
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS FixedAssetDepreciationPackages
		|		ON FixedAssetDepreciationPackages.Organization = AccruedDepreciation.Organization
		|			AND FixedAssetDepreciationPackages.FixedAsset = AccruedDepreciation.FixedAsset
		|
		|GROUP BY
		|	AccruedDepreciation.Ref,
		|	AccruedDepreciation.CalculationPeriod,
		|	AccruedDepreciation.AccrualPeriod,
		|	AccruedDepreciation.Organization,
		|	AccruedDepreciation.CGU,
		|	ISNULL(FixedAssetDepreciationPackages.PackageNumber, 0),
		|	AccruedDepreciation.Department,
		|	AccruedDepreciation.DebitBusinessUnit,
		|	AccruedDepreciation.FinancialAccountingGroup,
		|	AccruedDepreciation.LineOfBusiness,
		|	AccruedDepreciation.CorLineOfBusiness,
		|	AccruedDepreciation.FixedAsset,
		|	AccruedDepreciation.ExpenseItem,
		|	AccruedDepreciation.DimensionOfExpenses,
		|	AccruedDepreciation.ThisIsAnAdditionalAccrual,
		|	AccruedDepreciation.ThisIsAdditionalChargeAccounting,
		|	&GroupingID_";
	
	EndIf; 
	
	If CarryingOutDocument Then
		QueryText = StrReplace(QueryText, "&TableRowID_", "AccruedDepreciation.RowID");
		QueryText = StrReplace(QueryText, "&GroupingID_",  "AccruedDepreciation.RowID");
	Else
		QueryText = StrReplace(QueryText, "&TableRowID_", "RECORDAUTONUMBER()");
		QueryText = StrReplace(QueryText, "&GroupingID_",  "TRUE");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SubqueryText", "(" + SubqueryText + ")");
	
	If TypeOf(ListOfRequests) = Type("ValueList") Then
		ListOfRequests.Add(QueryText, TableName);
	Else
		ListOfRequests.Add(QueryText);
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
	
	FullDocumentName = "Document.FixedAssetsDepreciationCharge2_4";
	
	RequestHasSource = True;
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
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
	|	Document.FixedAssetsDepreciationCharge2_4 AS DocumentsList
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
	|	DocumentData.Ref           AS Ref,
	|	DocumentData.Date             AS Period,
	|	DocumentData.Number            AS Number,
	|	DocumentData.Posted         AS Posted,
	|	DocumentData.DeletionMark  AS DeletionMark,
	|	DocumentData.Comment      AS Comment,
	|	DocumentData.EmployeeResponsible    AS EmployeeResponsible,
	|	DocumentData.Organization      AS Organization,
	|	DocumentData.PackageNumber      AS PackageNumber
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.FixedAssetsDepreciationCharge2_4 AS DocumentData
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
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.FixedAssetsDepreciationCharge2_4"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.FixedAssetsDepreciationCharge);
	ValuesOfHoldingParameters.Insert("SettingUp_HO", Catalogs.BusinessTransactionsSettings.FixedAssetsDepreciationCharge);
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);

	ValuesOfHoldingParameters.Insert(
		"AddImpairmentAdjustment", 
		Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment);
	
	ValuesOfHoldingParameters.Insert(
		"ReverseImpairmentAdjustment", 
		Enums.PostingOptionsForImpairedFADepreciation.ReverseImpairmentAdjustment);

	ValuesOfHoldingParameters.Insert(
		"UseAccountingOfOtherIncomeExpenses",
		GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	
	ValuesOfHoldingParameters.Insert(
		"IDOfUnusedFinRecord",
		DocumentsPosting.IDOfUnusedFinRecord());

	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts, Registers)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	MergeRequestTexts = New Array;
	
	#Region Depreciation // Dt 91 - Ct 02.am
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	AccruedDepreciation.CalculationPeriod            AS Period,
	|	AccruedDepreciation.Organization              AS Organization,
	|	AccruedDepreciation.Department            AS Department,
	|	AccruedDepreciation.FixedAsset         AS FixedAsset,
	|	AccruedDepreciation.LineOfBusiness  AS LineOfBusiness,
	|	AccruedDepreciation.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	AccruedDepreciation.AmountOfUU    AS Depreciation,
	|	AccruedDepreciation.AmountAccounting    AS DepreciationLocal,
	|	AccruedDepreciation.AmountFA    AS DepreciationInTaxAccounting,
	|	AccruedDepreciation.AmountPermanentDifferences    AS DepreciationPermanentDifferences,
	|	AccruedDepreciation.AmountTemporaryDifferences    AS DepreciationTD,
	|	AccruedDepreciation.CFAmount    AS FixedAssetDepreciationTargetFinancing,
	|	AccruedDepreciation.SumOfNUCF  AS DepreciationTaxAccountingTargetFinancing,
	|	AccruedDepreciation.PRCFAmount  AS DepreciationTargetFinancingPD,
	|	AccruedDepreciation.AmountOfVRCF  AS DepreciationOfTargetFinancingTD,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN AccruedDepreciation.CompanyRecipientOfExpenses
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END AS CorCompany,
	|	AccruedDepreciation.DebitBusinessUnit              AS DebitBusinessUnit,
	|	AccruedDepreciation.CorLineOfBusiness    AS CorLineOfBusiness,
	|	AccruedDepreciation.ExpenseItem                AS CorExpenseItem,
	|	AccruedDepreciation.DimensionOfExpenses             AS CorExpenditureDimension,
	|	AccruedDepreciation.AccrueDepreciation                AS AccrueDepreciation,
	|
	|	AccruedDepreciation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	AccruedDepreciation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	AccruedDepreciation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|	AccruedDepreciation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|
	|	AccruedDepreciation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	AccruedDepreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|
	|	AccruedDepreciation.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|	AccruedDepreciation.ImpairmentBalanceMan  AS ImpairmentBalanceMan,
	|
	|	AccruedDepreciation.ThisIsAnAdditionalAccrual                   AS ThisIsAnAdditionalAccrual,
	|	AccruedDepreciation.ThisIsAdditionalChargeAccounting                 AS ThisIsAdditionalChargeAccounting,
	|	AccruedDepreciation.ThisIsRecordingOfDifference               AS ThisIsRecordingOfDifference,
	|
	|	AccruedDepreciation.AccountingProcedureMA                    AS AccountingProcedureMA,
	|	AccruedDepreciation.AccountingProcedureAC                    AS AccountingProcedureAC,
	|	
	|	AccruedDepreciation.ProcedureForCalculatingDepreciationOfMa    AS ProcedureForCalculatingDepreciationOfMa,
	|	AccruedDepreciation.ProcedureForCalculatingDepreciationAC    AS ProcedureForCalculatingDepreciationAC,
	|	
	|	AccruedDepreciation.AccrualPeriod                  AS AccrualPeriod,
	|	AccruedDepreciation.DepreciationMethodVersionMA          AS DepreciationMethodVersionMA,
	|	AccruedDepreciation.DepreciationMethodVersionLA          AS DepreciationMethodVersionLA,
	|	AccruedDepreciation.RowID               AS FinRecordID,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN VALUE(Enum.BusinessTransactions.FixedAssetsDepreciationChargeToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.FixedAssetsDepreciationCharge)
	|	END AS BusinessOperation,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsDepreciationChargeToAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsDepreciationCharge)
	|	END AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	(AccruedDepreciation.AmountOfUU <> 0
	|		OR AccruedDepreciation.AmountAccounting <> 0
	|		OR AccruedDepreciation.AmountFA <> 0
	|		OR AccruedDepreciation.AmountPermanentDifferences <> 0
	|		OR AccruedDepreciation.AmountTemporaryDifferences <> 0
	|		OR AccruedDepreciation.CFAmount <> 0
	|		OR AccruedDepreciation.SumOfNUCF <> 0
	|		OR AccruedDepreciation.PRCFAmount <> 0
	|		OR AccruedDepreciation.AmountOfVRCF <> 0)";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region ImpairmentAdjustment // Dt 02.ob - Ct 02.am
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	AccruedDepreciation.CalculationPeriod            AS Period,
	|	AccruedDepreciation.Organization              AS Organization,
	|	AccruedDepreciation.Department            AS Department,
	|	AccruedDepreciation.FixedAsset         AS FixedAsset,
	|	AccruedDepreciation.LineOfBusiness  AS LineOfBusiness,
	|	AccruedDepreciation.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	AccruedDepreciation.ImpairmentMA            AS Depreciation,
	|	AccruedDepreciation.ImpairmentAC            AS DepreciationLocal,
	|	0                                               AS DepreciationInTaxAccounting,
	|	0                                               AS DepreciationPermanentDifferences,
	|	AccruedDepreciation.ImpairmentAC            AS DepreciationTD,
	|	AccruedDepreciation.ImpairmentOfCF            AS FixedAssetDepreciationTargetFinancing,
	|	0                                               AS DepreciationTaxAccountingTargetFinancing,
	|	0                                               AS DepreciationTargetFinancingPD,
	|	AccruedDepreciation.ImpairmentOfCF            AS DepreciationOfTargetFinancingTD,
	|
	|	VALUE(Catalog.Companies.EmptyRef)        AS CorCompany,
	|	AccruedDepreciation.DebitBusinessUnit              AS DebitBusinessUnit,
	|	AccruedDepreciation.CorLineOfBusiness    AS CorLineOfBusiness,
	|	AccruedDepreciation.ExpenseItem                AS CorExpenseItem,
	|	AccruedDepreciation.DimensionOfExpenses             AS CorExpenditureDimension,
	|	AccruedDepreciation.AccrueDepreciation                AS AccrueDepreciation,
	|
	|	AccruedDepreciation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	AccruedDepreciation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	AccruedDepreciation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|	AccruedDepreciation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|
	|	AccruedDepreciation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	AccruedDepreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|
	|	AccruedDepreciation.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|	AccruedDepreciation.ImpairmentBalanceMan  AS ImpairmentBalanceMan,
	|
	|	AccruedDepreciation.ThisIsAnAdditionalAccrual                   AS ThisIsAnAdditionalAccrual,
	|	AccruedDepreciation.ThisIsAdditionalChargeAccounting                 AS ThisIsAdditionalChargeAccounting,
	|	AccruedDepreciation.ThisIsRecordingOfDifference               AS ThisIsRecordingOfDifference,
	|
	|	AccruedDepreciation.AccountingProcedureMA                    AS AccountingProcedureMA,
	|	AccruedDepreciation.AccountingProcedureAC                    AS AccountingProcedureAC,
	|	
	|	AccruedDepreciation.ProcedureForCalculatingDepreciationOfMa    AS ProcedureForCalculatingDepreciationOfMa,
	|	AccruedDepreciation.ProcedureForCalculatingDepreciationAC    AS ProcedureForCalculatingDepreciationAC,
	|	
	|	AccruedDepreciation.AccrualPeriod                  AS AccrualPeriod,
	|	AccruedDepreciation.DepreciationMethodVersionMA          AS DepreciationMethodVersionMA,
	|	AccruedDepreciation.DepreciationMethodVersionLA          AS DepreciationMethodVersionLA,
	|	AccruedDepreciation.RowID               AS FinRecordID,
	|
	|	VALUE(Enum.BusinessTransactions.AdjustmentForFAImpairment) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.AdjustmentForFAImpairment) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0
	|		OR AccruedDepreciation.ImpairmentOfCF <> 0)";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(MergeRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Procedure QueryTextTableImpairmentFA(QueryTexts, Registers)

	RegisterName = "ImpairmentFA";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	MergeRequestTexts = New Array;
	
	#Region ReverseImpairment // Dt 91 - Ct 02.ob (reverse)
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	AccruedDepreciation.CalculationPeriod            AS Period,
	|	AccruedDepreciation.FixedAsset         AS NonCurrentAsset,
	|	AccruedDepreciation.Organization              AS Organization,
	|	AccruedDepreciation.Department            AS Department,
	|	AccruedDepreciation.LineOfBusiness  AS LineOfBusiness,
	|	AccruedDepreciation.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	AccruedDepreciation.CGU                     AS CGU,
	|	AccruedDepreciation.RowID      AS FinRecordID,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseImpairmentOfOSVToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.ReverseFAImpairment)
	|	END AS BusinessOperation,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseImpairmentOfOSVToAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseFAImpairment)
	|	END AS BusinessTransactionSetting,
	|
	|	-(AccruedDepreciation.ImpairmentAC + AccruedDepreciation.ImpairmentOfCF) AS ImpairmentLocalAssets,
	|	-AccruedDepreciation.ImpairmentMA AS ImpairmenMan
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.PostingOptionForImpairedFADepreciation = &ReverseImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0
	|		OR AccruedDepreciation.ImpairmentOfCF <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region ImpairmentAdjustment // Dt 02.ob - Ct 02.am
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	AccruedDepreciation.CalculationPeriod            AS Period,
	|	AccruedDepreciation.FixedAsset         AS NonCurrentAsset,
	|	AccruedDepreciation.Organization              AS Organization,
	|	AccruedDepreciation.Department            AS Department,
	|	AccruedDepreciation.LineOfBusiness  AS LineOfBusiness,
	|	AccruedDepreciation.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	AccruedDepreciation.CGU                     AS CGU,
	|	AccruedDepreciation.RowID      AS FinRecordID,
	|
	|	VALUE(Enum.BusinessTransactions.AdjustmentForFAImpairment) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.AdjustmentForFAImpairment) AS BusinessTransactionSetting,
	|
	|	AccruedDepreciation.ImpairmentAC + AccruedDepreciation.ImpairmentOfCF AS ImpairmentLocalAssets,
	|	AccruedDepreciation.ImpairmentMA AS ImpairmenMan
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0
	|		OR AccruedDepreciation.ImpairmentOfCF <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(MergeRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	AdditionalFields = "Recorder,VariancePeriod";
	AdditionalFields = "Recorder,VariancePeriod,AITAmount";
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, AdditionalFields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(AdditionalFields);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
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
	|	UNDEFINED                            AS Priority
	|
	|FROM
	|	Document.FixedAssetsDepreciationCharge2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, AdditionalFields)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, AdditionalFields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(AdditionalFields);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, AdditionalFields)
	
	RegisterName = "TTInitialOtherExpenses";
	
	ListOfMergeRequests = New Array;
	
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(AdditionalFields));
	ListOfMergeRequests.Add(NonCurrentAssetsInternal.RequestTextTableReflectionOfAccruedDepreciationInOtherExpenses(AdditionalFields));
	ListOfMergeRequests.Add(NonCurrentAssetsInternal.RequestTextTableRecognitionOfImpairmentInOtherExpenses(AdditionalFields));
	
	FixedAssetsDepreciationChargeLocalization.AddRequestTextTableTTInitialOtherExpenses(ListOfMergeRequests, AdditionalFields);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

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
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.ItemisedExpensesLots.TextDescriptionTTInitialBatchesOfOtherExpenses());
	ListOfMergeRequests.Add(NonCurrentAssetsInternal.RequestTextTableReflectionOfAccruedDepreciationInBatchesOfOtherExpenses());
	ListOfMergeRequests.Add(NonCurrentAssetsInternal.RequestTextTableRecognitionOfImpairmentInLotsOtherExpenses());
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	ListOfMergeRequests = New Array;
	
	#Region Depreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                               AS Recorder,
	|	AccruedDepreciation.CalculationPeriod                 AS Period,
	|	AccruedDepreciation.Organization                   AS Organization,
	|	AccruedDepreciation.Department                 AS Department,
	|	AccruedDepreciation.LineOfBusiness       AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	AccruedDepreciation.CompanyRecipientOfExpenses AS Dimension,
	|	UNDEFINED                                         AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	AccruedDepreciation.AmountAccounting AS SumCompl,
	|	AccruedDepreciation.AmountPermanentDifferences AS PermanentDifference,
	|	AccruedDepreciation.AmountTemporaryDifferences AS CostTD,
	|	AccruedDepreciation.AmountOfUU AS SumMan,
	|	AccruedDepreciation.AmountOfUU AS AmountIncludingVAT,
	|	AccruedDepreciation.AmountOfUU AS AmountExcludingVAT,
	|
	|	AccruedDepreciation.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsDepreciationChargeToAnotherCompany) AS BusinessTransactionSetting
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.TransferExpensesToAnotherCompany
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|	AND NOT AccruedDepreciation.AccrueDepreciation
	|
	|	AND (AccruedDepreciation.AmountAccounting <> 0
	|		OR AccruedDepreciation.AmountPermanentDifferences <> 0
	|		OR AccruedDepreciation.AmountTemporaryDifferences <> 0
	|		OR AccruedDepreciation.AmountOfUU <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                                AS Recorder,
	|	AccruedDepreciation.CalculationPeriod                  AS Period,
	|	AccruedDepreciation.CompanyRecipientOfExpenses  AS Organization,
	|	AccruedDepreciation.DebitBusinessUnit               AS Department,
	|	AccruedDepreciation.CorLineOfBusiness     AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	AccruedDepreciation.Organization                    AS Dimension,
	|	UNDEFINED                                          AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	AccruedDepreciation.AmountAccounting AS SumCompl,
	|	AccruedDepreciation.AmountPermanentDifferences AS PermanentDifference,
	|	AccruedDepreciation.AmountTemporaryDifferences AS CostTD,
	|	AccruedDepreciation.AmountOfUU AS SumMan,
	|	AccruedDepreciation.AmountOfUU AS AmountIncludingVAT,
	|	AccruedDepreciation.AmountOfUU AS AmountExcludingVAT,
	|
	|	AccruedDepreciation.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsDepreciationChargeFromAnotherCompany) AS BusinessTransactionSetting
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.TransferExpensesToAnotherCompany
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|	AND NOT AccruedDepreciation.AccrueDepreciation
	|
	|	AND (AccruedDepreciation.AmountAccounting <> 0
	|		OR AccruedDepreciation.AmountPermanentDifferences <> 0
	|		OR AccruedDepreciation.AmountTemporaryDifferences <> 0
	|		OR AccruedDepreciation.AmountOfUU <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region ReverseImpairment
	QueryText =
	"SELECT
	|	DocumentData.Ref                               AS Recorder,
	|	AccruedDepreciation.CalculationPeriod                 AS Period,
	|	AccruedDepreciation.Organization                   AS Organization,
	|	AccruedDepreciation.Department                 AS Department,
	|	AccruedDepreciation.LineOfBusiness       AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	AccruedDepreciation.CompanyRecipientOfExpenses AS Dimension,
	|	UNDEFINED                                         AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	-AccruedDepreciation.ImpairmentAC AS SumCompl,
	|	0 AS PermanentDifference,
	|	-AccruedDepreciation.ImpairmentAC AS CostTD,
	|	-AccruedDepreciation.ImpairmentMA AS SumMan,
	|	-AccruedDepreciation.ImpairmentMA AS AmountIncludingVAT,
	|	-AccruedDepreciation.ImpairmentMA AS AmountExcludingVAT,
	|
	|	AccruedDepreciation.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseImpairmentOfOSVToAnotherCompany) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.TransferExpensesToAnotherCompany
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|	AND NOT AccruedDepreciation.AccrueDepreciation
	|
	|	AND AccruedDepreciation.PostingOptionForImpairedFADepreciation = &ReverseImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                                AS Recorder,
	|	AccruedDepreciation.CalculationPeriod                  AS Period,
	|	AccruedDepreciation.CompanyRecipientOfExpenses  AS Organization,
	|	AccruedDepreciation.DebitBusinessUnit               AS Department,
	|	AccruedDepreciation.CorLineOfBusiness     AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	AccruedDepreciation.Organization                    AS Dimension,
	|	UNDEFINED                                          AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	-AccruedDepreciation.ImpairmentAC AS SumCompl,
	|	0 AS PermanentDifference,
	|	-AccruedDepreciation.ImpairmentAC AS CostTD,
	|	-AccruedDepreciation.ImpairmentMA AS SumMan,
	|	-AccruedDepreciation.ImpairmentMA AS AmountIncludingVAT,
	|	-AccruedDepreciation.ImpairmentMA AS AmountExcludingVAT,
	|
	|	AccruedDepreciation.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseFAImpairmentFromAnotherCompany) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.TransferExpensesToAnotherCompany
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|	AND NOT AccruedDepreciation.AccrueDepreciation
	|
	|	AND AccruedDepreciation.PostingOptionForImpairedFADepreciation = &ReverseImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	FixedAssetsDepreciationChargeLocalization.QueryTextTableOtherAssetsAndLiabilitiesRecords(ListOfMergeRequests);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;

EndFunction

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	MergeRequestTexts = New Array;
	
	#Region ReverseImpairment // Dt 91 - Ct 02.ob (reverse)
	QueryText =
	"SELECT
	|	AccruedDepreciation.CalculationPeriod AS Period,
	|	AccruedDepreciation.Organization AS Organization,
	|
	|	AccruedDepreciation.Department AS Department,
	|	AccruedDepreciation.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS AS AssetRef,
	|	AccruedDepreciation.FixedAsset AS AssetsLiabilitiesDimension,
	|	AccruedDepreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	AccruedDepreciation.DebitBusinessUnit AS DebitBusinessUnit,
	|	AccruedDepreciation.CorLineOfBusiness AS CorLineOfBusiness,
	|	AccruedDepreciation.ExpenseItem AS CorItem,
	|	AccruedDepreciation.DimensionOfExpenses AS CorExpenditureDimension,
	|	UNDEFINED AS CorDimensionOfAssetsLiabilities,
	|	UNDEFINED AS CorFinancialAccountingGroup,
	|
	|	-AccruedDepreciation.ImpairmentMA AS Sum,
	|	-AccruedDepreciation.ImpairmentMA AS SumMan,
	|	-(AccruedDepreciation.ImpairmentAC + AccruedDepreciation.ImpairmentOfCF) AS SumCompl,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseImpairmentOfOSVToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.ReverseFAImpairment)
	|	END AS BusinessOperation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.PostingOptionForImpairedFADepreciation = &ReverseImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0
	|		OR AccruedDepreciation.ImpairmentOfCF <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region ImpairmentAdjustment // Dt 02.ob - Ct 02.am
	QueryText =
	"SELECT
	|	AccruedDepreciation.CalculationPeriod AS Period,
	|	AccruedDepreciation.Organization AS Organization,
	|
	|	AccruedDepreciation.Department AS Department,
	|	AccruedDepreciation.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS AS AssetRef,
	|	AccruedDepreciation.FixedAsset AS AssetsLiabilitiesDimension,
	|	AccruedDepreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	AccruedDepreciation.Department AS DebitBusinessUnit,
	|	AccruedDepreciation.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS AS CorItem,
	|	UNDEFINED AS CorExpenditureDimension,
	|	AccruedDepreciation.FixedAsset AS CorDimensionOfAssetsLiabilities,
	|	AccruedDepreciation.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	AccruedDepreciation.ImpairmentMA AS Sum,
	|	AccruedDepreciation.ImpairmentMA AS SumMan,
	|	AccruedDepreciation.ImpairmentAC + AccruedDepreciation.ImpairmentOfCF AS SumCompl,
	|
	|	VALUE(Enum.BusinessTransactions.AdjustmentForFAImpairment) AS BusinessOperation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0
	|		OR AccruedDepreciation.ImpairmentOfCF <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(MergeRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return FixedAssetsDepreciationChargeLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return FixedAssetsDepreciationChargeLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region DepreciationCalculation

Procedure PrepareListOfObjects(CalculationParameters)

	ListOfRequests = New Array;

	QueryTextTTDataToBeCalculated(ListOfRequests);
	QueryTextListOfAllFA(ListOfRequests, CalculationParameters);
	QueryTextListOfAccountingObjects(ListOfRequests, CalculationParameters);

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());

	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);

EndProcedure

Procedure PrepareParametersForDepreciationCalculation(CalculationParameters)

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FixedAssetsDepreciationCharge.CalculateDepreciation.PrepareParameters");

	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	
	Query.SetParameter("Date", EndOfMonth(CalculationParameters.Period));
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());

	ListOfRequests = New Array;

	QueryTextDepreciationCalculationParameters(ListOfRequests, CalculationParameters);
	QueryTextCheckingCalculationParameters(ListOfRequests, CalculationParameters);
	QueryTextNumberOfCalculationParameters(ListOfRequests, CalculationParameters);

	SetPrivilegedMode(True);
	QueryResult = NonCurrentAssetsInternal.ExecuteQuery(Query, ListOfRequests);
	SetPrivilegedMode(False);
	
	Selection = QueryResult.Select();
	Selection.Next();
	DataVolume = Selection.DataVolume;

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);

EndProcedure

Procedure PerformDepreciationCalculation(CalculationParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FixedAssetsDepreciationCharge.CalculateDepreciation.PerformTheCalculation");

	FixedAssetsDepreciationChargeLocalization.PerformDepreciationCalculation(CalculationParameters);

	CalculateDepreciation_ForLastMonthMA(CalculationParameters);
	CalculateDepreciation_ForLastMonthAC(CalculationParameters);
	
	CalculateDepreciation_ForCurrentMonthMA(CalculationParameters);
	CalculateDepreciation_ForCurrentMonthAC(CalculationParameters);
	
	CombineCalculationResults(CalculationParameters);
	
	CheckCalculationResults(CalculationParameters);
	
	GetAmountOfProcessedData(CalculationParameters);
	
	TMCommonUse.AddIDsToTemporaryTable("AccruedDepreciation", CalculationParameters.TempTablesManager);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, CalculationParameters.NumberOfProcessedData);

EndProcedure

Procedure CombineCalculationResults(CalculationParameters)
	
	ListOfRequests = New Array;
	
	QueryTextCalculationOfDepreciation_Y(ListOfRequests, CalculationParameters);
	QueryTextCalculationOfDepreciation_BU_MU(ListOfRequests, CalculationParameters);
	QueryTextAccruedDepreciation(ListOfRequests, CalculationParameters);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	
	Query.Execute();
	
EndProcedure

Procedure CheckCalculationResults(CalculationParameters)

	FixedAssetsDepreciationChargeLocalization.CheckCalculationResults(CalculationParameters);

	ListOfRequests = New Array;
	
	#Region CheckingCalculationOf_Y
	QueryText =
	"SELECT
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.AccountingObject AS AccountingObject,
	|	DepreciationCalculation.ExpenseItemNotSpecified AS ExpenseItemNotSpecified
	|
	|INTO CheckingCalculationOf_Y
	|
	|FROM
	|	(SELECT
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.FixedAsset AS AccountingObject,
	|
			// ExpenseItemNotSpecified
	|		DepreciationCalculation.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemNotSpecified
	|
	|	FROM
	|		CalculationOfDepreciation_Y AS DepreciationCalculation
	|
	|	WHERE
	|		(DepreciationCalculation.AmountOfUU <> 0
	|			OR DepreciationCalculation.AmountAccounting <> 0)
	|
	|	) AS DepreciationCalculation
	|
	|WHERE
	|	DepreciationCalculation.ExpenseItemNotSpecified
	|
	|INDEX BY
	|	AccountingObject";
	
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region CheckingCalculationOf_BU_M
	QueryText =
	"SELECT
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.AccountingObject AS AccountingObject,
	|	DepreciationCalculation.ExpenseItemNotSpecified AS ExpenseItemNotSpecified
	|
	|INTO CheckingCalculationOf_BU_M
	|
	|FROM
	|	(SELECT
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.FixedAsset AS AccountingObject,
	|
			// ExpenseItemNotSpecified
	|		DepreciationCalculation.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemNotSpecified
	|
	|	FROM
	|		CalculationOfDepreciation_BU_MU AS DepreciationCalculation
	|
	|	WHERE
	|		DepreciationCalculation.AmountAccounting <> 0
	|
	|	) AS DepreciationCalculation
	|
	|WHERE
	|	DepreciationCalculation.ExpenseItemNotSpecified
	|
	|INDEX BY
	|	AccountingObject";
	
	ListOfRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Query.Execute();
	
EndProcedure

Procedure GetAmountOfProcessedData(CalculationParameters)
	
	QueryText = QueryTextNumberOfProcessedData(CalculationParameters);

	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	Selection.Next();
	CalculationParameters.NumberOfProcessedData = Selection.DataVolume;
	
EndProcedure

Procedure RegisterDepreciationCalculationErrors(CalculationParameters)
		
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FixedAssetsDepreciationCharge.CalculateDepreciation.RegisterErrors");
	
	CalculationParameters.TablesToUse = CalculationParameters.TablesToUse + "," + "PackageNumbersWithErrors";
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(CalculationParameters.TempTablesManager);
	TTUsed.Add("PackageNumbersWithErrors");
	
	QueryText =
	"SELECT
	|	FixedAssetsDocuments.RefType AS RefType,
	|	FixedAssetsDocuments.Ref AS Ref,
	|	FixedAssetsDocuments.Date AS Date,
	|	FixedAssetsDocuments.Organization AS Organization,
	|	FixedAssetsDocuments.Organization.ParentCompany AS ParentCompany,
	|	FixedAssetsDocuments.FixedAsset AS FixedAsset
	|
	|INTO TTFADocuments
	|
	|FROM
	|	InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|
	|WHERE
	|	FixedAssetsDocuments.RefType IN (&DocumentIDs)
	|	AND FixedAssetsDocuments.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND FixedAssetsDocuments.Posted
	|
	|	AND FixedAssetsDocuments.FixedAsset IN
	|			(SELECT
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|INDEX BY
	|	RefType,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckingCalculationParameters.AccountingObject AS AccountingObject,
	|	CheckingCalculationParameters.Organization AS Organization,
	|	MAX(CheckingCalculationParameters.MaUsagePeriodIsNotSpecified) AS MaUsagePeriodIsNotSpecified,
	|	MAX(CheckingCalculationParameters.PeriodOfUseOfBUIsNotSpecified) AS PeriodOfUseOfBUIsNotSpecified,
	|	MAX(CheckingCalculationParameters.ResourceNotSpecified) AS ResourceNotSpecified,
	|	MAX(CheckingCalculationParameters.AmountOfOperatingTimeDeveloped) AS AmountOfOperatingTimeDeveloped,
	|	MAX(CheckingCalculationParameters.AmountOfOperatingTimeIsNotSpecified) AS AmountOfOperatingTimeIsNotSpecified,
	|	MAX(CheckingCalculationParameters.IncorrectDisassemblyDate) AS IncorrectDisassemblyDate,
	|	MAX(CheckingCalculationParameters.DisassemblyAndPreliminaryCost) AS DisassemblyAndPreliminaryCost,
	|	MAX(CheckingCalculationParameters.PoolingAndPreCost) AS PoolingAndPreCost,
	|	MAX(CheckingCalculationParameters.MAExpenseItemIsNotSpecified) AS MAExpenseItemIsNotSpecified,
	|	MAX(CheckingCalculationParameters.ACExpenseItemIsNotSpecified) AS ACExpenseItemIsNotSpecified
	|
	|INTO CheckingAllParametersOfCalculationMA
	|
	|FROM
	|	(SELECT
	|		CheckingCalculationParameters.Organization AS Organization,
	|		CheckingCalculationParameters.AccountingObject AS AccountingObject,
	|		CheckingCalculationParameters.MaUsagePeriodIsNotSpecified AS MaUsagePeriodIsNotSpecified,
	|		FALSE AS PeriodOfUseOfBUIsNotSpecified,
	|		FALSE AS ResourceNotSpecified,
	|		CheckingCalculationParameters.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
	|		CheckingCalculationParameters.AmountOfOperatingTimeDeveloped AS AmountOfOperatingTimeDeveloped,
	|		FALSE AS IncorrectDisassemblyDate,
	|		FALSE AS DisassemblyAndPreliminaryCost,
	|		FALSE AS PoolingAndPreCost,
	|		FALSE AS MAExpenseItemIsNotSpecified,
	|		FALSE AS ACExpenseItemIsNotSpecified
	|	FROM
	|		CheckingCalculationParameters_Y AS CheckingCalculationParameters
	|	WHERE
	|		CheckingCalculationParameters.Organization IN(&CompaniesList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CheckingCalculationParameters.Organization AS Organization,
	|		CheckingCalculationParameters.AccountingObject AS AccountingObject,
	|		FALSE AS MaUsagePeriodIsNotSpecified,
	|		CheckingCalculationParameters.PeriodOfUseIsNotSpecified AS PeriodOfUseOfBUIsNotSpecified,
	|		FALSE AS ResourceNotSpecified,
	|		CheckingCalculationParameters.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
	|		CheckingCalculationParameters.AmountOfOperatingTimeDeveloped AS AmountOfOperatingTimeDeveloped,
	|		FALSE AS IncorrectDisassemblyDate,
	|		FALSE AS DisassemblyAndPreliminaryCost,
	|		FALSE AS PoolingAndPreCost,
	|		FALSE AS MAExpenseItemIsNotSpecified,
	|		FALSE AS ACExpenseItemIsNotSpecified
	|	FROM
	|		CheckingCalculationParametersOf_BU_M AS CheckingCalculationParameters
	|	WHERE
	|		CheckingCalculationParameters.Organization IN(&CompaniesList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CheckingCalculationParameters.Organization AS Organization,
	|		CheckingCalculationParameters.AccountingObject AS AccountingObject,
	|		CheckingCalculationParameters.MaUsagePeriodIsNotSpecified AS MaUsagePeriodIsNotSpecified,
	|		FALSE AS PeriodOfUseOfBUIsNotSpecified,
	|		CheckingCalculationParameters.ResourceNotSpecified AS ResourceNotSpecified,
	|		CheckingCalculationParameters.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
	|		FALSE AS AmountOfOperatingTimeDeveloped,
	|		FALSE AS IncorrectDisassemblyDate,
	|		FALSE AS DisassemblyAndPreliminaryCost,
	|		FALSE AS PoolingAndPreCost,
	|		FALSE AS MAExpenseItemIsNotSpecified,
	|		FALSE AS ACExpenseItemIsNotSpecified
	|	FROM
	|		CheckingParametersForCalculatingChangesIn_Y AS CheckingCalculationParameters
	|	WHERE
	|		CheckingCalculationParameters.Organization IN(&CompaniesList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CheckingCalculationParameters.Organization AS Organization,
	|		CheckingCalculationParameters.AccountingObject AS AccountingObject,
	|		FALSE AS MaUsagePeriodIsNotSpecified,
	|		CheckingCalculationParameters.PeriodOfUseIsNotSpecified AS PeriodOfUseOfBUIsNotSpecified,
	|		CheckingCalculationParameters.ResourceNotSpecified AS ResourceNotSpecified,
	|		CheckingCalculationParameters.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
	|		FALSE AS AmountOfOperatingTimeDeveloped,
	|		FALSE AS IncorrectDisassemblyDate,
	|		FALSE AS DisassemblyAndPreliminaryCost,
	|		FALSE AS PoolingAndPreCost,
	|		FALSE AS MAExpenseItemIsNotSpecified,
	|		FALSE AS ACExpenseItemIsNotSpecified
	|	FROM
	|		CheckingParametersOfCalculationOfChangeOf_BU_M AS CheckingCalculationParameters
	|	WHERE
	|		CheckingCalculationParameters.Organization IN(&CompaniesList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SplitFixedAssets.Organization AS Organization,
	|		SplitFixedAssets.FixedAsset AS AccountingObject,
	|		FALSE AS MaUsagePeriodIsNotSpecified,
	|		FALSE AS PeriodOfUseOfBUIsNotSpecified,
	|		FALSE AS ResourceNotSpecified,
	|		FALSE AS AmountOfOperatingTimeIsNotSpecified,
	|		FALSE AS AmountOfOperatingTimeDeveloped,
	|		TRUE AS IncorrectDisassemblyDate,
	|		FALSE AS DisassemblyAndPreliminaryCost,
	|		FALSE AS PoolingAndPreCost,
	|		FALSE AS MAExpenseItemIsNotSpecified,
	|		FALSE AS ACExpenseItemIsNotSpecified
	|	FROM
	|		TTFADocuments AS SplitFixedAssets
	|
	|			INNER JOIN TTFADocuments AS MergeOfFixedAssets
	|			ON MergeOfFixedAssets.RefType = &IDOfMergingFixedAssets
	|				AND MergeOfFixedAssets.FixedAsset = SplitFixedAssets.FixedAsset
	|
	|			LEFT JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(&EndOfMonth) AS AccountingPolicy
	|			ON AccountingPolicy.Organization = SplitFixedAssets.ParentCompany
	|
	|	WHERE
	|		ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
	|
	|		AND SplitFixedAssets.RefType = &IDSplitFixedAssets
	|		AND SplitFixedAssets.Date >= MergeOfFixedAssets.Date
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SplitFixedAssets.Organization AS Organization,
	|		SplitFixedAssets.FixedAsset AS AccountingObject,
	|		FALSE AS MaUsagePeriodIsNotSpecified,
	|		FALSE AS PeriodOfUseOfBUIsNotSpecified,
	|		FALSE AS ResourceNotSpecified,
	|		FALSE AS AmountOfOperatingTimeIsNotSpecified,
	|		FALSE AS AmountOfOperatingTimeDeveloped,
	|		FALSE AS IncorrectDisassemblyDate,
	|		TRUE AS DisassemblyAndPreliminaryCost,
	|		FALSE AS PoolingAndPreCost,
	|		FALSE AS MAExpenseItemIsNotSpecified,
	|		FALSE AS ACExpenseItemIsNotSpecified
	|	FROM
	|		TTFADocuments AS SplitFixedAssets
	|
	|			LEFT JOIN TTFADocuments AS FixedAssetsInitialRecognition
	|			ON FixedAssetsInitialRecognition.RefType = &IDFixedAssetsInitialRecognition
	|				AND FixedAssetsInitialRecognition.FixedAsset = SplitFixedAssets.FixedAsset
	|
	|			LEFT JOIN TTFADocuments AS FixedAssetsCostAdditions
	|			ON FixedAssetsCostAdditions.RefType = &IDOfFixedAssetCostedAddition
	|				AND FixedAssetsCostAdditions.FixedAsset = SplitFixedAssets.FixedAsset
	|
	|			LEFT JOIN TTFADocuments AS AllocateVariancesToFixedAssetCost
	|			ON AllocateVariancesToFixedAssetCost.RefType = &IdAttributingDeviationsToFACost
	|				AND AllocateVariancesToFixedAssetCost.FixedAsset = SplitFixedAssets.FixedAsset
	|
	|			LEFT JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(&EndOfMonth) AS AccountingPolicy
	|			ON AccountingPolicy.Organization = SplitFixedAssets.ParentCompany
	|	WHERE
	|		ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
	|
	|		AND SplitFixedAssets.RefType = &IDSplitFixedAssets
	|
	|		AND (NOT FixedAssetsInitialRecognition.Ref IS NULL
	|			OR NOT FixedAssetsCostAdditions.Ref IS NULL
	|			OR NOT AllocateVariancesToFixedAssetCost.Ref IS NULL)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		MergeOfFixedAssets.Organization AS Organization,
	|		MergeOfFixedAssets.FixedAsset AS AccountingObject,
	|		FALSE AS MaUsagePeriodIsNotSpecified,
	|		FALSE AS PeriodOfUseOfBUIsNotSpecified,
	|		FALSE AS ResourceNotSpecified,
	|		FALSE AS AmountOfOperatingTimeIsNotSpecified,
	|		FALSE AS AmountOfOperatingTimeDeveloped,
	|		FALSE AS IncorrectDisassemblyDate,
	|		FALSE AS DisassemblyAndPreliminaryCost,
	|		TRUE AS PoolingAndPreCost,
	|		FALSE AS MAExpenseItemIsNotSpecified,
	|		FALSE AS ACExpenseItemIsNotSpecified
	|	FROM
	|		TTFADocuments AS MergeOfFixedAssets
	|
	|			LEFT JOIN TTFADocuments AS FixedAssetsInitialRecognition
	|			ON FixedAssetsInitialRecognition.RefType = &IDFixedAssetsInitialRecognition
	|				AND FixedAssetsInitialRecognition.FixedAsset = MergeOfFixedAssets.FixedAsset
	|
	|			LEFT JOIN TTFADocuments AS FixedAssetsCostAdditions
	|			ON FixedAssetsCostAdditions.RefType = &IDOfFixedAssetCostedAddition
	|				AND FixedAssetsCostAdditions.FixedAsset = MergeOfFixedAssets.FixedAsset
	|
	|			LEFT JOIN TTFADocuments AS AllocateVariancesToFixedAssetCost
	|			ON AllocateVariancesToFixedAssetCost.RefType = &IdAttributingDeviationsToFACost
	|				AND AllocateVariancesToFixedAssetCost.FixedAsset = MergeOfFixedAssets.FixedAsset
	|
	|			LEFT JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(&EndOfMonth) AS AccountingPolicy
	|			ON AccountingPolicy.Organization = MergeOfFixedAssets.ParentCompany
	|	WHERE
	|		ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
	|
	|		AND MergeOfFixedAssets.RefType = &IDOfMergingFixedAssets
	|
	|		AND (NOT FixedAssetsInitialRecognition.Ref IS NULL
	|			OR NOT FixedAssetsCostAdditions.Ref IS NULL
	|			OR NOT AllocateVariancesToFixedAssetCost.Ref IS NULL)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		CheckingCalculation.Organization AS Organization,
	|		CheckingCalculation.AccountingObject AS AccountingObject,
	|		FALSE AS MaUsagePeriodIsNotSpecified,
	|		FALSE AS PeriodOfUseOfBUIsNotSpecified,
	|		FALSE AS ResourceNotSpecified,
	|		FALSE AS AmountOfOperatingTimeIsNotSpecified,
	|		FALSE AS AmountOfOperatingTimeDeveloped,
	|		FALSE AS IncorrectDisassemblyDate,
	|		FALSE AS DisassemblyAndPreliminaryCost,
	|		FALSE AS PoolingAndPreCost,
	|		CheckingCalculation.ExpenseItemNotSpecified AS MAExpenseItemIsNotSpecified,
	|		FALSE AS ACExpenseItemIsNotSpecified
	|	FROM
	|		CheckingCalculationOf_Y AS CheckingCalculation
	|
	|	UNION ALL
	|	
	|	SELECT
	|		CheckingCalculation.Organization AS Organization,
	|		CheckingCalculation.AccountingObject AS AccountingObject,
	|		FALSE AS MaUsagePeriodIsNotSpecified,
	|		FALSE AS PeriodOfUseOfBUIsNotSpecified,
	|		FALSE AS ResourceNotSpecified,
	|		FALSE AS AmountOfOperatingTimeIsNotSpecified,
	|		FALSE AS AmountOfOperatingTimeDeveloped,
	|		FALSE AS IncorrectDisassemblyDate,
	|		FALSE AS DisassemblyAndPreliminaryCost,
	|		FALSE AS PoolingAndPreCost,
	|		FALSE AS MAExpenseItemIsNotSpecified,
	|		CheckingCalculation.ExpenseItemNotSpecified AS ACExpenseItemIsNotSpecified
	|	FROM
	|		CheckingCalculationOf_BU_M AS CheckingCalculation
	|
	|	) AS CheckingCalculationParameters
	|
	|GROUP BY
	|	CheckingCalculationParameters.AccountingObject,
	|	CheckingCalculationParameters.Organization
	|
	|INDEX BY
	|	Organization,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckingCalculationParameters.AccountingObject AS AccountingObject,
	|	CheckingCalculationParameters.Organization AS Organization,
	|	CAST(CheckingCalculationParameters.AccountingObject AS Catalog.Assets).Description AS AccountingObjectPresentation,
	|	CAST(CheckingCalculationParameters.AccountingObject AS Catalog.Assets).AssetID AS AssetID,
	|	CheckingCalculationParameters.MaUsagePeriodIsNotSpecified AS MaUsagePeriodIsNotSpecified,
	|	CheckingCalculationParameters.PeriodOfUseOfBUIsNotSpecified AS PeriodOfUseOfBUIsNotSpecified,
	|	CheckingCalculationParameters.ResourceNotSpecified AS ResourceNotSpecified,
	|	CheckingCalculationParameters.AmountOfOperatingTimeDeveloped AS AmountOfOperatingTimeDeveloped,
	|	CheckingCalculationParameters.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
	|	CheckingCalculationParameters.IncorrectDisassemblyDate AS IncorrectDisassemblyDate,
	|	CheckingCalculationParameters.DisassemblyAndPreliminaryCost AS DisassemblyAndPreliminaryCost,
	|	CheckingCalculationParameters.PoolingAndPreCost AS PoolingAndPreCost,
	|	CheckingCalculationParameters.MAExpenseItemIsNotSpecified AS MAExpenseItemIsNotSpecified,
	|	CheckingCalculationParameters.ACExpenseItemIsNotSpecified AS ACExpenseItemIsNotSpecified
	|
	|FROM
	|	CheckingAllParametersOfCalculationMA AS CheckingCalculationParameters
	|";
		
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("CompaniesList", CalculationParameters.CompaniesList);
	Query.SetParameter("IDSplitFixedAssets", Common.MetadataObjectID(Metadata.Documents.SplitFixedAssets));
	Query.SetParameter("IDOfMergingFixedAssets", Common.MetadataObjectID(Metadata.Documents.MergeOfFixedAssets));
	Query.SetParameter("IDFixedAssetsInitialRecognition", Common.MetadataObjectID(Metadata.Documents.FixedAssetsInitialRecognition2_4));
	Query.SetParameter("IDOfFixedAssetCostedAddition", Common.MetadataObjectID(Metadata.Documents.FixedAssetsCostAdditions2_4));
	Query.SetParameter("IdAttributingDeviationsToFACost", Common.MetadataObjectID(Metadata.Documents.AllocateVariancesToFixedAssetCost));
	
	DocumentIDs = New Array;
	DocumentIDs.Add(Query.Parameters.IDSplitFixedAssets);
	DocumentIDs.Add(Query.Parameters.IDOfMergingFixedAssets);
	DocumentIDs.Add(Query.Parameters.IDFixedAssetsInitialRecognition);
	DocumentIDs.Add(Query.Parameters.IDOfFixedAssetCostedAddition);
	DocumentIDs.Add(Query.Parameters.IdAttributingDeviationsToFACost);
	Query.SetParameter("DocumentIDs", DocumentIDs);
	
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	
	Result = Query.Execute();
	
	CalculationParameters.HasErrors = Not Result.IsEmpty() Or CalculationParameters.HasErrors;
	
	If CalculationParameters.RegisterErrors Then
	
		Selection = Result.Select();
		
		TemplateOperatingTime = NStr("vi = 'Đối với tài sản cố định ""%1"" (số %2) trong kế toán quản trị, lượng thời gian hoạt động (sản xuất, công việc) ước tính không được xác định.';
									|ru = 'Для основного средства ""%1"" (инв. №%2) в управленческом учете не определен предполагаемый объем наработки (продукции, работ).';
									|en = 'Estimated asset activity value (of products, works) is not defined for the fixed asset ""%1"" (inv. No.%2) in management accounting.'; fa = 'Estimated asset activity value (of products, works) is not defined for the fixed asset ""%1"" (inv. No.%2) in management accounting.';
									|it = 'Per il Capitale fisso ""%1"" (inventario №%2) in contabilità gestionale non è stato definito il volume di produzione stimato (prodotti, lavori).';
									|pl = 'Dla środka trwałego ""%1"" (nr inwentarzowy%2) w ewidencji zarządczej nie określono prognozowanej ilości średniego czasu pracy (produkcji, prac).';
									|tr = 'Sabit kıymet ""%1"" (Env. No. %2) için tahmini çalışma hacmi (ürünler, işler) yönetim muhasebesinde tanımlanmamıştır.'");
		
		TemplateAmountOfOperatingTimeWorkedOut = NStr("vi = 'Đối với tài sản cố định ""%1"" (số kiểm kê %2) lượng thời gian hoạt động ước tính đã sử dụng hết.
											 |Nếu quá trình nâng cấp diễn ra sau khi hết hoàn toàn tài nguyên thì cần lập chứng từ ""Thay đổi tham số TSCĐ"" và tăng lượng thời gian hoạt động ước tính hoặc dừng tính khấu hao trong kế toán quản trị.';
											 |ru = 'Для основного средства ""%1"" (инв. №%2) в управленческом учете предполагаемый объем наработки полностью выработан.
											 |Если была произведена модернизация после полной выработки ресурса, то необходимо оформить документ ""Изменение параметров ОС"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации в управленческом учете.';
											 |en = 'Estimated asset activity is fully generated for the fixed asset ""%1"" (inv. No.%2) in management accounting.
											 |If appreciation has been performed after the resource has been fully generated, then it is necessary to register a document ""Adjust fixed asset financial details"" and increase the estimated running time or suspend depreciation charge in management accounting.'; fa = 'Estimated asset activity is fully generated for the fixed asset ""%1"" (inv. No.%2) in management accounting.
											 |If appreciation has been performed after the resource has been fully generated, then it is necessary to register a document ""Adjust fixed asset financial details"" and increase the estimated running time or suspend depreciation charge in management accounting.';
											 |it = 'Для основного средства ""%1"" (инв. №%2) в управленческом учете предполагаемый объем наработки полностью выработан.
											 |Если была произведена модернизация после полной выработки ресурса, то необходимо оформить документ ""Изменение параметров ОС"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации в управленческом учете.';
											 |pl = 'Estimated asset activity is fully generated for the fixed asset ""%1"" (inv. No.%2) in management accounting.
											 |If appreciation has been performed after the resource has been fully generated, then it is necessary to register a document ""Adjust fixed asset financial details"" and increase the estimated running time or suspend depreciation charge in management accounting.';
											 |tr = 'Sabit kıymet ""%1"" (Env. No. %2) için tahmini çalışma hacmi yönetim muhasebesinde tamamen tükenmiştir. 
											 |Modernizasyon, kaynak tamamen tükendikten sonra yapılmışsa, ""Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesini yürütmek ve tahmini çalışma hacmi miktarını artırmak veya yönetim muhasebesinde amortisman tahakkukunu askıya almak gerekir.'");
	
		TemplateMaUsagePeriod = NStr("vi = 'Đối với tài sản cố định ""%1"" (số kiểm kê %2) trong kế toán quản trị chưa xác định thời hạn sử dụng cần thiết để tính khấu hao.
	
										 |Nếu đã tiến hành nâng cấp sau khi kết thúc thời hạn sử dụng thì cần lập chứng từ ""Thay đổi tham số TSCĐ"" và chỉ ra thời hạn mới (thời hạn ban đầu + thời hạn mà sẽ tăng lên sau khi nâng cấp) hoặc dừng tính khấu hao.';
										 |ru = 'Для основного средства ""%1"" (инв. №%2) в управленческом учете не определен срок использования, необходимый для вычисления амортизации.
										 |Если была произведена модернизация после окончания срока использования, то следует оформить документ ""Изменение параметров ОС"" и указать новый срок (первоначальный + срок, на который произошло увеличение после модернизации) или приостановить начисление амортизации.';
										 |en = 'Useful life necessary to depreciation calculation for the fixed asset ""%1"" (inv. No.%2) is not defined in management accounting.
										 |If appreciation has been performed after the end of the useful life, then you should register a document ""Adjust fixed asset financial details"" and indicate a new due date (initial + due date for which the increase occurred after the renovation) or suspend depreciation charge.';
										 |it = 'Per il Capitale fisso ""%1"" (inventario №%2) in contabilità gestionale non è stata definita vita utile necessaria per il calcolo dell''ammortamento. 
										 | Qualora dopo il termine della vita utile ci fosse stato un ammodernamento, è necessario registrare il documento ""Modifica dei parametri di Capitale fisso"" e indicare il nuovo termine di scadenza (termine iniziale + periodo per cui è stato prolungato dopo l''ammodernamento) o sospendere il calcolo dell''ammortamento.';
										 |pl = 'Dla środka trwałego  ""%1"" (nr. inw.%2) w ewidencji zarządczej nie określono okresu użytkowania, koniecznego do obliczenia amortyzacji.
										 |Jeśli została wykonana amortyzacja po zakończeniu okresu używania, należy utworzyć dokument ""Zmiana parametrów ŚT"" i podać nowy okres (początkowy + okres zwiększenia po modernizacji) lub wstrzymać naliczenie amortyzacji.';
										 |tr = 'Sabit kıymet ""%1"" (Env. No. %2) için, yönetim muhasebesi amortisman hesaplaması için gerekli kullanım süresini tanımlamaz. 
										 |Kullanım süresinin bitiminden sonra modernizasyon yapılmışsa, ""Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesinin yürütülmesi ve yeni bir dönem (orijinal dönem + modernizasyondan sonra artış olan dönem) belirtilmesi veya amortismanın tahakkuku gerekir.'");
		
		TemplateResourceGenerated = NStr("vi = 'Đối với tài sản cố định ""%1"" (số %2), không thể xác định tài nguyên đã cạn kiệt trong kế toán quản trị.';
										|ru = 'Для основного средства ""%1"" (инв. №%2) не удалось определить выработанный ресурс в управленческом учете.';
										|en = 'Cannot define the generated resource in management accounting for the fixed asset ""%1"" (inv. No. %2).'; fa = 'Cannot define the generated resource in management accounting for the fixed asset ""%1"" (inv. No. %2).';
										|it = 'Non è stata la vita utile nella contabilità gestionale per l''immobilizzazione materiale ""%1"" (inv. N.%2).';
										|pl = 'Dla środka trwałego ""%1"" (nr inwentarzowy%2) nie udało się określić wyprodukowany zasób w ewidencji zarządczej.';
										|tr = 'Sabit kıymet ""%1"" (Env. No. %2) için yönetim muhasebesinde tükenen kaynağı belirlemek mümkün değildi.'");
		
		TemplateInvalidDateOfDisassembly = NStr("vi = 'Đối với tài sản cố định ""%1"" (hàng tồn kho số %2), ngày và thời gian tháo dỡ phải sớm hơn ngày và thời gian sáp nhập.';
												|ru = 'Для основного средства ""%1"" (инв. №%2) дата и время разукомплектации должны быть раньше, чем дата и время объединения.';
												|en = 'For the fixed asset ""%1"" (Inv. No.%2), the date and time of splitting must be before the date and time of the combining.'; fa = 'For the fixed asset ""%1"" (Inv. No.%2), the date and time of splitting must be before the date and time of the combining.';
												|it = 'Per capitale fisso ""%1"" (inv. №%2) data e ora di scomposizione devono essere precedenti alla data e all''ora dell''unione..';
												|pl = 'Dla środka trwałego ""%1"" (№ inw.%2) data i czas zdekompletowania powinne być wcześniej, niż data i czas połączenia.';
												|tr = 'Sabit kıymet ""%1"" (Env. No. %2) için ayrıştırma tarih ve saati konsolidasyon tarih ve saatinden önce olmalıdır.'");
		
		TemplatePoolingAndPreCost = NStr("vi = 'Không hỗ trợ đóng bộ tài sản cố định ""%1"" (số kiểm kê %2), bởi vì trong tháng này đã lập chứng từ tiếp nhận vào kế toán (nâng cấp, phân bổ các khoản chênh lệch vào giá trị).
	                                                       |Để bỏ qua giới hạn, có thể lập chứng từ đóng bộ vào tháng sau.';
	                                                       |ru = 'Не поддерживается объединение основного средства ""%1"" (инв. №%2), т.к. в этом же месяце оформлено принятие к учету (модернизация, отнесение отклонений в стоимость).
	                                                       |Для обхода ограничения можно оформить объединение в следующем месяце.';
	                                                       |en = 'Merging the ""%1"" fixed asset (Inv. No.%2) is not supported as it was recognized (modernized) or the variances were allocated to cost in the same month.
	                                                       |To circumvent the restriction, register the merge in the next month.'; fa = 'Merging the ""%1"" fixed asset (Inv. No.%2) is not supported as it was recognized (modernized) or the variances were allocated to cost in the same month.
	                                                       |To circumvent the restriction, register the merge in the next month.';
	                                                       |it = 'Merging the ""%1"" fixed asset (Inv. No.%2) is not supported as it was recognized (modernized) or the variances were allocated to cost in the same month.
	                                                       |To circumvent the restriction, register the merge in the next month.';
	                                                       |pl = 'Merging the ""%1"" fixed asset (Inv. No.%2) is not supported as it was recognized (modernized) or the variances were allocated to cost in the same month.
	                                                       |To circumvent the restriction, register the merge in the next month.';
	                                                       |tr = 'Aynı ay içinde muhasebeleştirme (modernizasyon, farkların maliyete yüklenmesi) işlemi yapıldığı için ""%1"" sabit kıymetinin (Fat. no:%2) birleştirilmesi desteklenmemektedir. 
	                                                       | Bu kısıtlamayı aşmak için birleştirme işlemi bir sonraki ay yapılabilir.'");
		
		TemplateDisassemblyAndPreliminaryCost = NStr("vi = 'Không hỗ trợ tháo dỡ tài sản cố định ""%1"" (số kiểm kê %2), bởi vì trong tháng này đã lập chứng từ tiếp nhận vào kế toán (nâng cấp, phân bổ các khoản chênh lệch vào giá trị).
	                                                       |Để bỏ qua giới hạn, có thể lập chứng từ đóng bộ vào tháng sau.';
	                                                       |ru = 'Не поддерживается разукомплектация основного средства ""%1"" (инв. №%2), т.к. в этом же месяце оформлено принятие к учету (модернизация, отнесение отклонений в стоимость).
	                                                       |Для обхода ограничения можно оформить разукомплектацию в следующем месяце.';
	                                                       |en = 'Splitting the ""%1"" fixed asset (Inv. No.%2) is not supported as it was recognized (modernized) or the variances were allocated to cost in the same month.
	                                                       |To circumvent the restriction, register the split in the next month.'; fa = 'Splitting the ""%1"" fixed asset (Inv. No.%2) is not supported as it was recognized (modernized) or the variances were allocated to cost in the same month.
	                                                       |To circumvent the restriction, register the split in the next month.';
	                                                       |it = 'Splitting the ""%1"" fixed asset (Inv. No.%2) is not supported as it was recognized (modernized) or the variances were allocated to cost in the same month.
	                                                       |To circumvent the restriction, register the split in the next month.';
	                                                       |pl = 'Splitting the ""%1"" fixed asset (Inv. No.%2) is not supported as it was recognized (modernized) or the variances were allocated to cost in the same month.
	                                                       |To circumvent the restriction, register the split in the next month.';
	                                                       |tr = 'Aynı ay içinde muhasebeleştirme (modernizasyon, farkların maliyete yüklenmesi) işlemi yapıldığı için ""%1"" sabit kıymetinin (demirbaş no:%2) parçalara ayrılması desteklenmemektedir. 
	                                                       | Bu kısıtlamayı aşmak için parçalara ayırma işlemi bir sonraki ay yapılabilir.'");
		
		TemplateDoesNotSpecifyExpenseItemMA = NStr("vi = 'Đối với tài sản cố định ""%1"" (số kiểm kê %2) trong kế toán quản trị, chưa xác định dạng chi phí phản ánh khấu hao.';
													|ru = 'Для основного средства ""%1"" (инв. №%2) в управленческом учете не определена статья расходов отражения амортизации.';
													|en = 'The expense item is not specified to record depreciation for the ""%1"" ( inventory No. %2) fixed asset in management accounting.'; fa = 'The expense item is not specified to record depreciation for the ""%1"" ( inventory No. %2) fixed asset in management accounting.';
													|it = 'Для основного средства ""%1"" (инв. №%2) в управленческом учете не определена статья расходов отражения амортизации.';
													|pl = 'The expense item is not specified to record depreciation for the ""%1"" ( inventory No. %2) fixed asset in management accounting.';
													|tr = '""%1"" sabit kıymeti için (Env. No. %2), yönetim muhasebesinde amortismanı yansıtan gider kalemi tanımlanmamıştır.'");
		TemplateDoesNotSpecifyACExpenseItem = NStr("vi = 'Đối với tài sản cố định ""%1"" (số kiểm kê %2) trong kế toán doanh nghiệp, chưa xác định dạng chi phí phản ánh khấu hao.';
													|ru = 'Для основного средства ""%1"" (инв. №%2) в бухгалтерском учете не определена статья расходов отражения амортизации.';
													|en = 'The expense item is not specified to record depreciation for the ""%1"" (inventory No. %2) fixed asset in local accounting.'; fa = 'The expense item is not specified to record depreciation for the ""%1"" (inventory No. %2) fixed asset in local accounting.';
													|it = 'Для основного средства ""%1"" (инв. №%2) в бухгалтерском учете не определена статья расходов отражения амортизации.';
													|pl = 'The expense item is not specified to record depreciation for the ""%1"" (inventory No. %2) fixed asset in local accounting.';
													|tr = '""%1"" sabit kıymeti için (Env. No. %2), yerel muhasebede amortismanı yansıtan gider kalemi tanımlanmamıştır.'");
		
		While Selection.Next() Do
			
			If Selection.AmountOfOperatingTimeIsNotSpecified Then
				
				ErrorText = StrTemplate(TemplateOperatingTime, Selection.AccountingObjectPresentation, TrimAll(Selection.AssetID));
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
			
			If Selection.AmountOfOperatingTimeDeveloped Then
				
				ErrorText = StrTemplate(TemplateAmountOfOperatingTimeWorkedOut, Selection.AccountingObjectPresentation, TrimAll(Selection.AssetID));
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
			
			If Selection.ResourceNotSpecified Then
				
				ErrorText = StrTemplate(TemplateResourceGenerated, Selection.AccountingObjectPresentation, TrimAll(Selection.AssetID));
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
			
			If Selection.MaUsagePeriodIsNotSpecified Then
				
				ErrorText = StrTemplate(TemplateMaUsagePeriod, Selection.AccountingObjectPresentation, TrimAll(Selection.AssetID));
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
		
			If Selection.IncorrectDisassemblyDate Then
				
				ErrorText = StrTemplate(TemplateInvalidDateOfDisassembly, Selection.AccountingObjectPresentation, TrimAll(Selection.AssetID));
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
			
			If Selection.PoolingAndPreCost Then
				
				ErrorText = StrTemplate(TemplatePoolingAndPreCost, Selection.AccountingObjectPresentation, TrimAll(Selection.AssetID));
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
			
			If Selection.DisassemblyAndPreliminaryCost Then
				
				ErrorText = StrTemplate(TemplateDisassemblyAndPreliminaryCost, Selection.AccountingObjectPresentation, TrimAll(Selection.AssetID));
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
			
			If Selection.MAExpenseItemIsNotSpecified Then
				
				ErrorText = StrTemplate(TemplateDoesNotSpecifyExpenseItemMA, Selection.AccountingObjectPresentation, TrimAll(Selection.AssetID));
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
			
			If Selection.ACExpenseItemIsNotSpecified Then
				
				ErrorText = StrTemplate(TemplateDoesNotSpecifyACExpenseItem, Selection.AccountingObjectPresentation, TrimAll(Selection.AssetID));
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
			
		EndDo;
	
	EndIf;

	QueryText =
	"SELECT
	|	COUNT(DISTINCT DepreciationAdjustmentForPreviousPeriod.Ref) AS DocumentsCount,
	|	DepreciationAdjustmentForPreviousPeriod.Organization AS Organization,
	|	DepreciationAdjustmentForPreviousPeriod.FixedAsset AS AccountingObject
	|
	|INTO CheckingDepreciationAdjustmentForPreviousPeriod 
	|
	|FROM
	|	DepreciationAdjustmentForPreviousPeriod AS DepreciationAdjustmentForPreviousPeriod
	|
	|GROUP BY
	|	DepreciationAdjustmentForPreviousPeriod.Organization,
	|	DepreciationAdjustmentForPreviousPeriod.FixedAsset
	|
	|HAVING
	|	COUNT(DISTINCT DepreciationAdjustmentForPreviousPeriod.Ref) > 1
	|
	|INDEX BY
	|	Organization,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckingDepreciationAdjustmentForPreviousPeriod.Organization AS Organization,
	|	CheckingDepreciationAdjustmentForPreviousPeriod.AccountingObject AS AccountingObject,
	|	CAST(CheckingDepreciationAdjustmentForPreviousPeriod.AccountingObject AS Catalog.Assets).Description AS AccountingObjectPresentation,
	|	CAST(CheckingDepreciationAdjustmentForPreviousPeriod.AccountingObject AS Catalog.Assets).AssetID AS AssetID
	|FROM
	|	CheckingDepreciationAdjustmentForPreviousPeriod AS CheckingDepreciationAdjustmentForPreviousPeriod
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Result = Query.Execute();
	
	CalculationParameters.HasErrors = Not Result.IsEmpty() Or CalculationParameters.HasErrors;
	
	If CalculationParameters.RegisterErrors Then
	
		MessageTemplate = NStr("vi = 'Đối với tài sản cố định ""%1"" (số kiểm kê %2), có nhiều chứng từ được lập trong cùng một tháng với tự động trích bổ sung khấu hao.
							   |Cần thực hiện trích bổ sung thủ công bằng cách lập một chứng từ điều chỉnh khấu hao.';
							   |ru = 'Для основного средства ""%1"" (инв. №%2) в одном месяце оформлено несколько документов с автоматическим доначислением амортизации.
							   |Доначисление необходимо выполнить вручную, оформив один документ корректировки амортизации.';
							   |en = 'For the ""%1"" fixed asset (inv. No. %2), several documents were issued in one month with automatic additional depreciation.
							   |Additional depreciation must be accrued manually by registering one depreciation adjustment document.'; fa = 'For the ""%1"" fixed asset (inv. No. %2), several documents were issued in one month with automatic additional depreciation.
							   |Additional depreciation must be accrued manually by registering one depreciation adjustment document.';
							   |it = 'For the ""%1"" fixed asset (inv. No. %2), several documents were issued in one month with automatic additional depreciation.
							   |Additional depreciation must be accrued manually by registering one depreciation adjustment document.';
							   |pl = 'For the ""%1"" fixed asset (inv. No. %2), several documents were issued in one month with automatic additional depreciation.
							   |Additional depreciation must be accrued manually by registering one depreciation adjustment document.';
							   |tr = '""%1"" sabit kıymeti (demirbaş no:%2) için aynı ay içinde otomatik amortisman ek tahakkuku içeren birden fazla belge oluşturulmuş. 
							   | Ek tahakkuk işleminin tek bir amortisman düzeltme belgesi oluşturularak manuel yapılması gerekir.'");

		Selection = Result.Select();
		While Selection.Next() Do
			
			ErrorText = StrTemplate(MessageTemplate, Selection.AccountingObjectPresentation, TrimAll(Selection.AssetID));
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
				CalculationParameters.Period,
				Selection.Organization,
				ErrorText,,
				Selection.AccountingObject,
				CalculationParameters.HasErrors);
				
		EndDo;
		
	EndIf;
	
	FixedAssetsDepreciationChargeLocalization.RegisterDepreciationCalculationErrors(CalculationParameters);
	
	QueryText =
	"SELECT DISTINCT
	|	DepreciationPackages.Organization AS Organization,
	|	DepreciationPackages.PackageNumber AS PackageNumber
	|
	|INTO PackageNumbersWithErrors
	|
	|FROM
	|	(SELECT DISTINCT
	|		DepreciationPackages.Organization AS Organization,
	|		DepreciationPackages.PackageNumber AS PackageNumber
	|	FROM
	|		CheckingAllParametersOfCalculationMA AS CheckingCalculationParameters
	|
	|			INNER JOIN InformationRegister.FixedAssetDepreciationPackages AS DepreciationPackages
	|			ON DepreciationPackages.Organization = CheckingCalculationParameters.Organization
	|				AND DepreciationPackages.FixedAsset = CheckingCalculationParameters.AccountingObject
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		DepreciationPackages.Organization AS Organization,
	|		DepreciationPackages.PackageNumber AS PackageNumber
	|
	|	FROM
	|		CheckingDepreciationAdjustmentForPreviousPeriod AS CheckingDepreciationAdjustmentForPreviousPeriod
	|
	|			INNER JOIN InformationRegister.FixedAssetDepreciationPackages AS DepreciationPackages
	|			ON DepreciationPackages.Organization = CheckingDepreciationAdjustmentForPreviousPeriod.Organization
	|				AND DepreciationPackages.FixedAsset = CheckingDepreciationAdjustmentForPreviousPeriod.AccountingObject
	|
	|	) AS DepreciationPackages
	|
	|INDEX BY
	|	Organization,
	|	PackageNumber
	|";
	

	Query.Text = QueryText;
	Query.Execute();
	
	TMCommonUse.DestroyTemporaryTables(CalculationParameters.TempTablesManager,, TTUsed);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

Procedure RecordDepreciationCalculation(CalculationParameters)

	If Not CalculationParameters.WriteData Then
		Return;
	EndIf;
	
	For Each Selection In CalculationParameters.DepreciationPackages Do
			
		BeginTransaction();
	
		Try
		
			MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FixedAssetsDepreciationCharge.CalculateDepreciation.RecordCalculation");
		
			// You need to block documents so as not to create duplicates
			Block = New DataLock;
			
			LockItem = Block.Add("Document.FixedAssetsDepreciationCharge2_4");
			LockItem.SetValue("Date", New Range(BegOfMonth(CalculationParameters.Period),EndOfMonth(CalculationParameters.Period)));
			LockItem.SetValue("Organization", Selection.Organization);
			LockItem.SetValue("PackageNumber", Selection.PackageNumber);
			
			Block.Lock(); 
			
			QueryText =
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	AccruedDepreciation AS AccruedDepreciation
			|WHERE
			|	AccruedDepreciation.Organization = &Organization
			|	AND AccruedDepreciation.PackageNumber = &PackageNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	PackageNumbersWithErrors AS PackageNumbersWithErrors
			|WHERE
			|	PackageNumbersWithErrors.Organization = &Organization
			|	AND PackageNumbersWithErrors.PackageNumber = &PackageNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MAX(CASE
			|			WHEN RegulatoryDocument.Posted = TRUE
			|				THEN RegulatoryDocument.Ref
			|			ELSE VALUE(Document.FixedAssetsDepreciationCharge2_4.EmptyRef)
			|		END) AS LinkHeld,
			|
			|	MAX(CASE
			|			WHEN RegulatoryDocument.Posted = FALSE
			|				THEN RegulatoryDocument.Ref
			|			ELSE VALUE(Document.FixedAssetsDepreciationCharge2_4.EmptyRef)
			|		END) AS LinkNotFound,
			|
			|	MAX(CASE
			|			WHEN RegulatoryDocument.DeletionMark = TRUE
			|				THEN RegulatoryDocument.Ref
			|			ELSE VALUE(Document.FixedAssetsDepreciationCharge2_4.EmptyRef)
			|		END) AS LinkRemoved
			|FROM
			|	Document.FixedAssetsDepreciationCharge2_4 AS RegulatoryDocument
			|
			|WHERE
			|	RegulatoryDocument.Organization = &Organization
			|	AND RegulatoryDocument.PackageNumber = &PackageNumber
			|	AND RegulatoryDocument.Date BETWEEN &BegOfMonth AND &EndOfMonth
			|";
			
			Query = New Query(QueryText);
			Query.TempTablesManager = CalculationParameters.TempTablesManager;
			Query.SetParameter("BegOfMonth", BegOfMonth(CalculationParameters.Period));
			Query.SetParameter("EndOfMonth", EndOfMonth(CalculationParameters.Period));
			Query.SetParameter("Organization", Selection.Organization);
			Query.SetParameter("PackageNumber", Selection.PackageNumber);
			
			//@skip-check query-in-loop
			Result = Query.ExecuteBatch();
			
			ThereIsAccruedDepreciation = Not Result[Result.UBound()-2].IsEmpty();
			HasErrors = Not Result[Result.UBound()-1].IsEmpty();
			
			SampleDocument = Result[Result.UBound()].Select();
			SampleDocument.Next();
			
			EmployeeResponsible = Users.CurrentUser();
			
			If Selection.PackageNumber = CalculationParameters.PackageNumber Then
				
				// The calculation is performed from the document form.
				If ValueIsFilled(CalculationParameters.Ref) Then
					
					DocumentObject = CalculationParameters.Ref.GetObject();
					DocumentObject.Comment = CalculationParameters.Comment;
					EmployeeResponsible = CalculationParameters.EmployeeResponsible;
					
				Else 
					
					DocumentObject = NonCurrentAssetsInternal.GetRegulatoryDocument(
						SampleDocument.LinkHeld, 
						Undefined, 
						Undefined, 
						Documents.FixedAssetsDepreciationCharge2_4);
						
				EndIf;
				
			Else	
				
				DocumentObject = NonCurrentAssetsInternal.GetRegulatoryDocument(
					SampleDocument.LinkHeld, 
					SampleDocument.LinkNotFound, 
					SampleDocument.LinkRemoved, 
					Documents.FixedAssetsDepreciationCharge2_4);
					
			EndIf; 
				
			If ThereIsAccruedDepreciation
				Or ValueIsFilled(CalculationParameters.Ref) Then
			
				DocumentObject.Date = EndOfMonth(CalculationParameters.Period);
				DocumentObject.PackageNumber = Selection.PackageNumber;
				DocumentObject.Organization = Selection.Organization;
				DocumentObject.EmployeeResponsible = EmployeeResponsible;
				DocumentObject.DeletionMark = False;

				DocumentObject.AdditionalProperties.Insert("TempTablesManager", CalculationParameters.TempTablesManager);
				
				DocumentObject.Write(DocumentWriteMode.Posting);
				
			ElsIf Not DocumentObject.DeletionMark
				And Not DocumentObject.IsNew() Then
				
				DocumentObject.SetDeletionMark(True);
				
			EndIf;
	
			NonCurrentAssetsInternal.DestroyTemporaryTablesAfterRecordingDepreciationCalculation(
				CalculationParameters.TempTablesManager, CalculationParameters);
	
			If CalculationParameters.FixCalculation Then

				If HasErrors Then
					
					// You need to create a task with a new number, because tasks with old numbers can be deleted
					InformationRegisters.JobsForCalculatingFixedAssetDepreciation.CreateRegisterEntry(
						CalculationParameters.Period, Undefined, Selection.Organization, Selection.PackageNumber);
					
				Else
					
					DepreciationPackages = CalculationParameters.DepreciationPackages.Copy(CommonClientServer.ValueInArray(Selection));
					
					InformationRegisters.JobsForCalculatingFixedAssetDepreciation.FixCalculation(
						CalculationParameters.Period, 
						CommonClientServer.ValueInArray(Selection.Organization), 
						CalculationParameters.NumberBeforeSettlement, 
						DepreciationPackages);
				
				EndIf;
				
			EndIf;
	
			PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, CalculationParameters.NumberOfProcessedData);
			
			CommitTransaction();
		
		Except
		
			RollbackTransaction();
			
			ErrorInfo = ErrorInfo();
			
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo);
			
			Raise ErrorText;
		
		EndTry;
		 
	EndDo; 
	
EndProcedure

#Region LastMonthSCalculation

Procedure CalculateDepreciation_ForLastMonthMA(CalculationParameters)
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(CalculationParameters.TempTablesManager);
	TTUsed.Add("CalculationOfDepreciation_ForLastMonthMA");
	TTUsed.Add("CalculationOfDepreciation_ForLastMonthUU_Grouped");
	
	CalculateDepreciation_ForLastMonth_UnchangedMA(CalculationParameters);
	CalculateDepreciation_ForLastMonth_TakingIntoAccountChangesInMA(CalculationParameters);
	
	QueryText = 
	"SELECT
	|	Depreciation.CalculationPeriod AS CalculationPeriod,
	|	Depreciation.Organization AS Organization,
	|	Depreciation.FixedAsset AS FixedAsset,
	|	Depreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Depreciation.Department AS Department,
	|	Depreciation.LineOfBusiness AS LineOfBusiness,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.ExpenseItem IS NULL
	|				AND WaysToReflectDepreciation.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND WaysToReflectDepreciation.ExpenseItem <> UNDEFINED
	|			THEN WaysToReflectDepreciation.ExpenseItem
	|		ELSE Depreciation.ExpenseItem
	|	END AS ExpenseItem,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.ExpenseItem IS NULL
	|				AND WaysToReflectDepreciation.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND WaysToReflectDepreciation.ExpenseItem <> UNDEFINED
	|			THEN WaysToReflectDepreciation.DimensionOfExpenses
	|		ELSE Depreciation.DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|
	|	CASE 
	|		WHEN ISNULL(WaysToReflectDepreciation.BusinessUnitAndLineOfBusinessMatchAccountingData, FALSE)
	|				OR ISNULL(WaysToReflectDepreciation.Department, Depreciation.ExpensesBusinessUnit) = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Depreciation.Department
	|		ELSE ISNULL(WaysToReflectDepreciation.Department, Depreciation.ExpensesBusinessUnit) 
	|	END AS ExpensesBusinessUnit,
	|
	|	CASE 
	|		WHEN ISNULL(WaysToReflectDepreciation.BusinessUnitAndLineOfBusinessMatchAccountingData, FALSE)
	|			THEN Depreciation.LineOfBusiness
	|		ELSE ISNULL(WaysToReflectDepreciation.LineOfBusiness, Depreciation.ExpenseLineOfBusiness) 
	|	END AS ExpenseLineOfBusiness,
	|
	|	Depreciation.DepreciationRecordMethod,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.CompanyRecipientOfExpenses IS NULL
	|				AND WaysToReflectDepreciation.TransferExpensesToAnotherCompany
	|				AND WaysToReflectDepreciation.CompanyRecipientOfExpenses <> Depreciation.Organization
	|			THEN TRUE
	|		ELSE Depreciation.TransferExpensesToAnotherCompany
	|	END AS TransferExpensesToAnotherCompany,
	|
	|	ISNULL(WaysToReflectDepreciation.CompanyRecipientOfExpenses, Depreciation.CompanyRecipientOfExpenses) AS CompanyRecipientOfExpenses,
	|
	|	Depreciation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	Depreciation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	Depreciation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	Depreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	Depreciation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	Depreciation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	Depreciation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	Depreciation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	Depreciation.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|
	|	CASE
	|		WHEN NOT Depreciation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|			THEN &DistributionOfSumOfMa
	|		ELSE Depreciation.AmountOfUU
	|	END AS AmountOfUU,
	|
	|	CASE
	|		WHEN NOT Depreciation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|			THEN &DistributionOfACAmount
	|		ELSE Depreciation.AmountAccounting
	|	END AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForLastMonthMA
	|
	|FROM
	|	(SELECT
	|		DepreciationCalculation.Period AS CalculationPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.FixedAsset AS FixedAsset,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualMA
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN DepreciationCalculation.ExpenseItem
	|			ELSE DepreciationCalculation.ExpenseItem 
	|		END AS ExpenseItem,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualMA
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN DepreciationCalculation.DimensionOfExpenses
	|			ELSE DepreciationCalculation.DimensionOfExpenses 
	|		END AS DimensionOfExpenses,
	|
	|		DepreciationCalculation.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		DepreciationCalculation.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualMA
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN UNDEFINED
	|			ELSE DepreciationCalculation.DepreciationRecordMethod 
	|		END AS DepreciationRecordMethod,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualMA
	|				THEN -DepreciationCalculation.AmountOfUU
	|			ELSE DepreciationCalculation.AmountOfUU 
	|		END AS AmountOfUU,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualAC
	|				THEN -DepreciationCalculation.AmountAccounting
	|			ELSE DepreciationCalculation.AmountAccounting 
	|		END AS AmountAccounting,
	|
	|		DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualMA
	|				THEN -DepreciationCalculation.CostUsedToCalculateDepreciationManag
	|			ELSE DepreciationCalculation.CostUsedToCalculateDepreciationManag 
	|		END AS CostUsedToCalculateDepreciationManag,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualAC
	|				THEN -DepreciationCalculation.CostUsedToCalculateDepreciationLocal
	|			ELSE DepreciationCalculation.CostUsedToCalculateDepreciationLocal 
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|		DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|		DepreciationCalculation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		DepreciationCalculation.VersionOfAccrualMethod AS VersionOfAccrualMethod
	|
	|	FROM
	|		CalculationOfDepreciation_ForLastMonth_Unchanged_Y AS DepreciationCalculation
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DepreciationCalculation.Period AS CalculationPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup, 
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.FixedAsset AS FixedAsset,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualMA
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN DepreciationCalculation.ExpenseItem
	|			ELSE DepreciationCalculation.ExpenseItem 
	|		END AS ExpenseItem,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualMA
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN DepreciationCalculation.DimensionOfExpenses
	|			ELSE DepreciationCalculation.DimensionOfExpenses 
	|		END AS DimensionOfExpenses,
	|
	|		DepreciationCalculation.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		DepreciationCalculation.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualMA
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN UNDEFINED
	|			ELSE DepreciationCalculation.DepreciationRecordMethod 
	|		END AS DepreciationRecordMethod,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualMA
	|				THEN -DepreciationCalculation.AmountOfUU
	|			ELSE DepreciationCalculation.AmountOfUU 
	|		END AS AmountOfUU,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualAC
	|				THEN -DepreciationCalculation.AmountAccounting
	|			ELSE DepreciationCalculation.AmountAccounting 
	|		END AS AmountAccounting,
	|
	|		DepreciationCalculation.TransferExpensesToAnotherCompany,
	|		DepreciationCalculation.CompanyRecipientOfExpenses,
	|		DepreciationCalculation.LifeSpentPastPeriod,
	|		DepreciationCalculation.LifeSpentCurrentPeriod,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualMA
	|				THEN -DepreciationCalculation.CostUsedToCalculateDepreciationManag
	|			ELSE DepreciationCalculation.CostUsedToCalculateDepreciationManag 
	|		END AS CostUsedToCalculateDepreciationManag,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActualAC
	|				THEN -DepreciationCalculation.CostUsedToCalculateDepreciationLocal
	|			ELSE DepreciationCalculation.CostUsedToCalculateDepreciationLocal 
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa,
	|		DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|		DepreciationCalculation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		DepreciationCalculation.VersionOfAccrualMethod AS VersionOfAccrualMethod
	|
	|	FROM
	|		CalculationOfDepreciation_ForLastMonth_TakingIntoAccountChangesInMA AS DepreciationCalculation
	|
	|	) AS Depreciation
	|
	|		LEFT JOIN WaysToReflectMADepreciation AS WaysToReflectDepreciation
	|		ON (WaysToReflectDepreciation.DepreciationRecordMethod = Depreciation.DepreciationRecordMethod)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepreciationCalculation.FixedAsset AS FixedAsset,
	|	SUM(DepreciationCalculation.AmountOfUU) AS AmountOfUU,
	|	SUM(DepreciationCalculation.AmountAccounting) AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForLastMonthUU_Grouped
	|
	|FROM
	|	CalculationOfDepreciation_ForLastMonthMA AS DepreciationCalculation
	|
	|GROUP BY
	|	DepreciationCalculation.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|";
	
	QueryText = StrReplace(
		QueryText, 
		"&DistributionOfSumOfMa", 
		NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.AmountOfUU"));
	
	QueryText = StrReplace(
		QueryText, 
		"&DistributionOfACAmount", 
		NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.AmountAccounting"));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	Query.Execute();
	
	TMCommonUse.DestroyTemporaryTables(CalculationParameters.TempTablesManager,, TTUsed);

EndProcedure

Procedure CalculateDepreciation_ForLastMonth_UnchangedMA(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	ListOfFA.Period AS Period,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.FixedAssetsLocation AS Department,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	ListOfFA.ExpenseItemManagementAccounting AS ExpenseItem,
	|	ListOfFA.ExpensesDimensionManagementAccounting AS DimensionOfExpenses,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.MethodOfReflectingDepreciationOfMA AS DepreciationRecordMethod,
	|	ListOfFA.TransferExpensesToAnotherMaOrganization AS TransferExpensesToAnotherCompany,
	|	ListOfFA.OrganizationRecipientOfMaExpenses AS CompanyRecipientOfExpenses,
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	ListOfFA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|	ListOfFA.ResidualValueMan AS ResidualValueMan,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	ListOfFA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ListOfFA.PreliminaryCostExceedsActualMA AS PreliminaryCostExceedsActualMA,
	|	ListOfFA.PreliminaryCostExceedsActualAC AS PreliminaryCostExceedsActualAC,
	|
	|	CASE
	|		WHEN ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
	|			THEN 1
	|		ELSE 0
	|	END AS VersionOfAccrualMethod,
	|
	|	CASE
	|		WHEN (ListOfFA.NetBookValue - (&AmountOfMaDepreciation)) > ListOfFA.ResidualValueMan
	|			THEN &AmountOfMaDepreciation
	|		WHEN (ListOfFA.NetBookValue - ListOfFA.ResidualValueMan) > 0
	|			THEN ListOfFA.NetBookValue - ListOfFA.ResidualValueMan
	|		ELSE 0
	|	END AS AmountOfUU,
	|
	|	CASE
	|		WHEN (ListOfFA.NetBookValueLocal - (&AmountOfACDepreciation)) > ListOfFA.ResidualValueLocal
	|			THEN &AmountOfACDepreciation
	|		WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal) > 0
	|			THEN ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal
	|		ELSE 0
	|	END AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForLastMonth_Unchanged_Y
	|
	|FROM
	|	ListOfOSSParameters_UU AS ListOfFA
	|
	|		LEFT JOIN CheckingCalculationParameters_Y AS CheckingCalculationParameters
	|		ON CheckingCalculationParameters.AccountingObject = ListOfFA.FixedAsset
	|			AND CheckingCalculationParameters.Organization = ListOfFA.Organization
	|WHERE
	|	ListOfFA.ThisIsAnAdditionalAccrual
	|	AND CheckingCalculationParameters.AccountingObject IS NULL
	|";
	
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	
	RequestTextParameters.TextCostToCalculateDepreciation = "ListOfFA.CostUsedToCalculateDepreciationManag";
	RequestTextParameters.TextResidualValue = "ListOfFA.NetBookValue";
	RequestTextParameters.TextLiquidationValue = "0";
	RequestTextParameters.TextCostAtBeginningOfYear = "ListOfFA.CostAtBeginningOfYear";
	RequestTextParameters.TextImpairment = "0";
	RequestTextParameters.TextAmountOfAdditionalCharge = "0";

	TextAmountOfDepreciationOfMa = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfMaDepreciation", TextAmountOfDepreciationOfMa);
	
	//	
	RequestTextParameters.TextCostToCalculateDepreciation = "ListOfFA.CostUsedToCalculateDepreciationLocal";
	RequestTextParameters.TextResidualValue = "ListOfFA.NetBookValueLocal";
	RequestTextParameters.TextLiquidationValue = "0";
	RequestTextParameters.TextCostAtBeginningOfYear = "ListOfFA.LocalCostAtBeginningOfYear";
	RequestTextParameters.TextImpairment = "0";
	RequestTextParameters.TextAmountOfAdditionalCharge = "0";

	TextACDepreciationAmount = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfACDepreciation", TextACDepreciationAmount);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	Query.Execute();
		
EndProcedure

Procedure CalculateDepreciation_ForLastMonth_TakingIntoAccountChangesInMA(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	1 AS Priority,
	|	DATETIME(1,1,1) AS Period,
	|	UNDEFINED AS Recorder,
	|	UNDEFINED AS BusinessOperation,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.Department AS Department,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	CAST(ListOfFA.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
	|	ListOfFA.ExpenseItem AS ExpenseItem,
	|	ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	ListOfFA.AmountOfUU AS AmountOfUU,
	|	ListOfFA.AmountAccounting AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|
	|	0 AS ImpairmentMA,
	|	0 AS ImpairmentAC,
	|
	|	1 AS ZoomRatio,
	|	ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|
	|	ListOfFA.ResidualValueMan AS ResidualValueMan,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|
	|	0 AS NetBookValueLocal,
	|	0 AS NetBookValueOfTF,
	|	0 AS PDResidualValue,
	|	0 AS PDSPFResidualValue,
	|
	|	0 AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
	|
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	FALSE AS ObtainedByDisassemblyCombining,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostTargetFinancing,
	|	0 AS CostPermanentDifference,
	|
	|	0 AS CostUpdate,
	|	0 AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|
	|	0 AS DepreciationUpdate,
	|	0 AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|
	|	0 AS Depreciation,
	|	0 AS DepreciationLocal,
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationPermanentDifferences,
	|
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	0 AS CostUsedToCalculateDepreciationLocal,
	|	0 AS CostForCalculatingDepreciationPD,
	|
	|	0 AS CFBUCoefficient,
	|
	|	ListOfFA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ListOfFA.PreliminaryCostExceedsActualMA AS PreliminaryCostExceedsActualMA,
	|	ListOfFA.PreliminaryCostExceedsActualAC AS PreliminaryCostExceedsActualAC,
	|
	|	FALSE AS MACostAdjustment,
	|	FALSE AS ACCostAdjustment,
	|	FALSE AS MADepreciationAdjustment,
	|	FALSE AS ACDepreciationAdjustment,
	|
	|	UNDEFINED AS RevaluationMethod,
	|	FALSE AS RevaluateAtFairValue,
	|
	|	FALSE AS TheseAreChanges
	|
	|FROM
	|	CalculationOfDepreciation_ForLastMonth_Unchanged_Y AS ListOfFA
	|
	|WHERE
	|	ListOfFA.FixedAsset IN
	|		(SELECT
	|			ListOfFA.FixedAsset
	|		FROM
	|			ListOfOSSWithChangedParameters_Y AS ListOfFA)
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS Priority,
	|	ListOfFA.Period AS Period,
	|	ListOfFA.Recorder AS Recorder,
	|	ListOfFA.BusinessOperation AS BusinessOperation,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.FixedAssetsLocation AS FixedAssetsLocation,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	CAST(ListOfFA.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
	|	ListOfFA.ExpenseItemManagementAccounting AS ExpenseItemManagementAccounting,
	|	ListOfFA.ExpensesDimensionManagementAccounting AS ExpensesDimensionManagementAccounting,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.MethodOfReflectingDepreciationOfMA AS MethodOfReflectingDepreciationOfMA,
	|
	|	0 AS AmountOfUU,
	|	0 AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|
	|	0 AS ImpairmentMA,
	|	0 AS ImpairmentAC,
	|
	|	1 AS ZoomRatio,
	|	ListOfFA.TransferExpensesToAnotherMaOrganization AS TransferExpensesToAnotherMaOrganization,
	|	ListOfFA.OrganizationRecipientOfMaExpenses AS OrganizationRecipientOfMaExpenses,
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|
	|	ListOfFA.ResidualValueMan AS ResidualValueMan,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|
	|	0 AS NetBookValueLocal,
	|	0 AS NetBookValueOfTF,
	|	0 AS PDResidualValue,
	|	0 AS PDSPFResidualValue,
	|
	|	0 AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
	|
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	FALSE AS ObtainedByDisassemblyCombining,
	|
	|	ListOfFA.Cost AS Cost,
	|	ListOfFA.LocalCost AS LocalCost,
	|	0 AS CostTargetFinancing,
	|	0 AS CostPermanentDifference,
	|
	|	ListOfFA.CostUpdate AS CostUpdate,
	|	ListOfFA.LocalCostUpdate AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|
	|	ListOfFA.DepreciationUpdate AS DepreciationUpdate,
	|	ListOfFA.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|
	|	ListOfFA.Depreciation AS Depreciation,
	|	ListOfFA.DepreciationLocal AS DepreciationLocal,
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationPermanentDifferences,
	|
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	0 AS CostUsedToCalculateDepreciationLocal,
	|	0 AS CostForCalculatingDepreciationPD,
	|
	|	0 AS CFBUCoefficient,
	|
	|	ListOfFA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ListOfFA.PreliminaryCostExceedsActualMA AS PreliminaryCostExceedsActualMA,
	|	ListOfFA.PreliminaryCostExceedsActualAC AS PreliminaryCostExceedsActualAC,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MACostAdjustment,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) AS ACCostAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MADepreciationAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) AS ACDepreciationAdjustment,
	|
	|	ListOfFA.RevaluationMethod AS RevaluationMethod,
	|	ISNULL(Revaluation.RevaluateAtFairValue, FALSE) AS RevaluateAtFairValue,
	|
	|	TRUE AS TheseAreChanges
	|
	|FROM
	|	ListOfOSSWithChangedParameters_Y AS ListOfFA
	|
	|		LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|		ON Adjusting.Ref = ListOfFA.Recorder
	|
	|		LEFT JOIN Document.FARevaluation2_4 AS Revaluation
	|		ON Revaluation.Ref = ListOfFA.Recorder
	|
	|WHERE
	|	ListOfFA.ThisIsAnAdditionalAccrual
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;

	QueryResult = Query.Execute();
	
	AmortizationOfChanges = CalculateDepreciationWhenParametersChange(QueryResult.Unload(), Undefined);
	
	QueryText =
	"SELECT
	|	DepreciationCalculation.Period AS Period,
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.Department AS Department,
	|	DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|	DepreciationCalculation.FixedAsset AS FixedAsset,
	|	DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|	DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|	DepreciationCalculation.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	DepreciationCalculation.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DepreciationCalculation.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	DepreciationCalculation.AmountOfUU AS AmountOfUU,
	|	DepreciationCalculation.AmountAccounting AS AmountAccounting,
	|	DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	DepreciationCalculation.ResourceAssigned AS ResourceAssigned,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	DepreciationCalculation.ImpairmentLocalAssets AS ImpairmentBalanceLocal,
	|	DepreciationCalculation.ImpairmenMan AS ImpairmentBalanceMan,
	|	DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	DepreciationCalculation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	DepreciationCalculation.PreliminaryCostExceedsActualMA AS PreliminaryCostExceedsActualMA,
	|	DepreciationCalculation.PreliminaryCostExceedsActualAC AS PreliminaryCostExceedsActualAC,
	|
	|	CASE
	|		WHEN DepreciationCalculation.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
	|			THEN 1
	|		ELSE 0
	|	END AS VersionOfAccrualMethod
	|
	|INTO CalculationOfDepreciation_ForLastMonth_TakingIntoAccountChangesInMA
	|
	|FROM
	|	&AmortizationOfChanges AS DepreciationCalculation
	|
	|WHERE
	|	DepreciationCalculation.TheseAreChanges
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("AmortizationOfChanges", AmortizationOfChanges);

	Query.Execute();
		
EndProcedure

Procedure CalculateDepreciation_ForLastMonthAC(CalculationParameters)
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(CalculationParameters.TempTablesManager);
	TTUsed.Add("CalculationOfDepreciation_ForLastMonthBU_MU");
	TTUsed.Add("CalculationOfDepreciation_ForLastMonthBU_MU_Grouped");

	CalculateDepreciation_ForLastMonth_UnchangedAC(CalculationParameters);
	CalculateDepreciation_ForLastMonth_TakingIntoAccountChangesInAC(CalculationParameters);

	QueryText = 
	"SELECT
	|	Depreciation.CalculationPeriod AS CalculationPeriod,
	|	Depreciation.Organization AS Organization,
	|	Depreciation.FixedAsset AS FixedAsset,
	|	Depreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Depreciation.Department AS Department,
	|	Depreciation.LineOfBusiness AS LineOfBusiness,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.ExpenseItem IS NULL
	|				AND WaysToReflectDepreciation.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND WaysToReflectDepreciation.ExpenseItem <> UNDEFINED
	|			THEN WaysToReflectDepreciation.ExpenseItem
	|		ELSE Depreciation.ExpenseItem
	|	END AS ExpenseItem,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.ExpenseItem IS NULL
	|				AND WaysToReflectDepreciation.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND WaysToReflectDepreciation.ExpenseItem <> UNDEFINED
	|			THEN WaysToReflectDepreciation.DimensionOfExpenses
	|		ELSE Depreciation.DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|
	|	CASE 
	|		WHEN ISNULL(WaysToReflectDepreciation.BusinessUnitAndLineOfBusinessMatchAccountingData, FALSE)
	|				OR ISNULL(WaysToReflectDepreciation.Department, Depreciation.ExpensesBusinessUnit) = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Depreciation.Department
	|		ELSE ISNULL(WaysToReflectDepreciation.Department, Depreciation.ExpensesBusinessUnit) 
	|	END AS ExpensesBusinessUnit,
	|
	|	CASE 
	|		WHEN ISNULL(WaysToReflectDepreciation.BusinessUnitAndLineOfBusinessMatchAccountingData, FALSE)
	|			THEN Depreciation.LineOfBusiness
	|		ELSE ISNULL(WaysToReflectDepreciation.LineOfBusiness, Depreciation.ExpenseLineOfBusiness) 
	|	END AS ExpenseLineOfBusiness,
	|
	|	Depreciation.DepreciationRecordMethod,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.CompanyRecipientOfExpenses IS NULL
	|				AND WaysToReflectDepreciation.TransferExpensesToAnotherCompany
	|				AND WaysToReflectDepreciation.CompanyRecipientOfExpenses <> Depreciation.Organization
	|			THEN TRUE
	|		ELSE Depreciation.TransferExpensesToAnotherCompany
	|	END AS TransferExpensesToAnotherCompany,
	|
	|	ISNULL(WaysToReflectDepreciation.CompanyRecipientOfExpenses, Depreciation.CompanyRecipientOfExpenses) AS CompanyRecipientOfExpenses,
	|
	|	Depreciation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	Depreciation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	Depreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	Depreciation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	Depreciation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	Depreciation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	Depreciation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	Depreciation.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|
	|	CASE
	|		WHEN NOT Depreciation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|			THEN &DistributionOfACAmount
	|		ELSE Depreciation.AmountAccounting
	|	END AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForLastMonthBU_MU
	|
	|FROM
	|	(SELECT
	|		DepreciationCalculation.Period AS CalculationPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.FixedAsset AS FixedAsset,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN DepreciationCalculation.ExpenseItem
	|			ELSE DepreciationCalculation.ExpenseItem 
	|		END AS ExpenseItem,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN DepreciationCalculation.DimensionOfExpenses
	|			ELSE DepreciationCalculation.DimensionOfExpenses 
	|		END AS DimensionOfExpenses,
	|
	|		DepreciationCalculation.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		DepreciationCalculation.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN UNDEFINED
	|			ELSE DepreciationCalculation.DepreciationRecordMethod 
	|		END AS DepreciationRecordMethod,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|				THEN -DepreciationCalculation.AmountAccounting
	|			ELSE DepreciationCalculation.AmountAccounting 
	|		END AS AmountAccounting,
	|
	|		DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|				THEN -DepreciationCalculation.CostUsedToCalculateDepreciationLocal
	|			ELSE DepreciationCalculation.CostUsedToCalculateDepreciationLocal 
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|		DepreciationCalculation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		DepreciationCalculation.VersionOfAccrualMethod AS VersionOfAccrualMethod
	|
	|	FROM
	|		CalculationOfDepreciationForLastMonth_Unchanged_BU_M AS DepreciationCalculation
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DepreciationCalculation.Period AS CalculationPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.FixedAsset AS FixedAsset,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN DepreciationCalculation.ExpenseItem
	|			ELSE DepreciationCalculation.ExpenseItem 
	|		END AS ExpenseItem,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN DepreciationCalculation.DimensionOfExpenses
	|			ELSE DepreciationCalculation.DimensionOfExpenses 
	|		END AS DimensionOfExpenses,
	|
	|		DepreciationCalculation.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		DepreciationCalculation.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|					AND BEGINOFPERIOD(DepreciationCalculation.Period, MONTH) = BEGINOFPERIOD(DepreciationCalculation.Period, YEAR) 
	|				THEN UNDEFINED
	|			ELSE DepreciationCalculation.DepreciationRecordMethod 
	|		END AS DepreciationRecordMethod,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|				THEN -DepreciationCalculation.AmountAccounting
	|			ELSE DepreciationCalculation.AmountAccounting 
	|		END AS AmountAccounting,
	|
	|		DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|				THEN -DepreciationCalculation.CostUsedToCalculateDepreciationLocal
	|			ELSE DepreciationCalculation.CostUsedToCalculateDepreciationLocal 
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|		DepreciationCalculation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		DepreciationCalculation.VersionOfAccrualMethod AS VersionOfAccrualMethod
	|
	|	FROM
	|		CalculationOfDepreciation_ForLastMonth_TakingIntoAccountChangesInBU_MU AS DepreciationCalculation
	|
	|	) AS Depreciation
	|
	|		LEFT JOIN WaysToReflectMADepreciation AS WaysToReflectDepreciation
	|		ON (WaysToReflectDepreciation.DepreciationRecordMethod = Depreciation.DepreciationRecordMethod)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepreciationCalculation.FixedAsset AS FixedAsset,
	|	SUM(DepreciationCalculation.AmountAccounting) AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForLastMonthBU_MU_Grouped
	|
	|FROM
	|	CalculationOfDepreciation_ForLastMonthBU_MU AS DepreciationCalculation
	|
	|GROUP BY
	|	DepreciationCalculation.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|";
	
	QueryText = StrReplace(QueryText, "&DistributionOfACAmount", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.AmountAccounting"));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	Query.Execute();
	
	TMCommonUse.DestroyTemporaryTables(CalculationParameters.TempTablesManager,, TTUsed);
	
EndProcedure

Procedure CalculateDepreciation_ForLastMonth_UnchangedAC(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	ListOfFA.Period AS Period,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.FixedAssetsLocation AS Department,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	ListOfFA.ExpenseItem AS ExpenseItem,
	|	ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	ListOfFA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ListOfFA.PreliminaryCostExceedsActual AS PreliminaryCostExceedsActual,
	|
	|	CASE
	|		WHEN ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|				AND ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
	|			THEN 1
	|		ELSE 0
	|	END AS VersionOfAccrualMethod,
	|
	|	CASE
	|		WHEN (ListOfFA.NetBookValueLocal - (&AmountOfACDepreciation)) > ListOfFA.ResidualValueLocal
	|			THEN &AmountOfACDepreciation
	|		WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal) > 0
	|			THEN ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal
	|		ELSE 0
	|	END AS AmountAccounting
	|
	|INTO CalculationOfDepreciationForLastMonth_Unchanged_BU_M
	|
	|FROM
	|	ListOfOSSWithParameters_BU_MU AS ListOfFA
	|
	|		LEFT JOIN CheckingCalculationParametersOf_BU_M AS CheckingCalculationParameters
	|		ON CheckingCalculationParameters.AccountingObject = ListOfFA.FixedAsset
	|			AND CheckingCalculationParameters.Organization = ListOfFA.Organization
	|WHERE
	|	ListOfFA.ThisIsAnAdditionalAccrual
	|	AND CheckingCalculationParameters.AccountingObject IS NULL
	|";
	
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	
	RequestTextParameters.TextCostToCalculateDepreciation = "ListOfFA.CostUsedToCalculateDepreciationLocal";
	RequestTextParameters.TextResidualValue = "ListOfFA.NetBookValueLocal";
	RequestTextParameters.TextLiquidationValue = "0";
	RequestTextParameters.TextCostAtBeginningOfYear = "ListOfFA.LocalCostAtBeginningOfYear";
	RequestTextParameters.TextImpairment = "0";
	RequestTextParameters.TextAmountOfAdditionalCharge = "0";

	TextACDepreciationAmount = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfACDepreciation", TextACDepreciationAmount);

	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	
	Query.Execute();
	
EndProcedure

Procedure CalculateDepreciation_ForLastMonth_TakingIntoAccountChangesInAC(CalculationParameters)

	QueryText = 
	"SELECT
	|	1 AS Priority,
	|	DATETIME(1,1,1) AS Period,
	|	UNDEFINED AS Recorder,
	|	UNDEFINED AS BusinessOperation,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.Department AS Department,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	CAST(ListOfFA.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
	|	ListOfFA.ExpenseItem AS ExpenseItem,
	|	ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	0 AS AmountOfUU,
	|	ListOfFA.AmountAccounting AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|
	|	0 AS ImpairmentMA,
	|	0 AS ImpairmentAC,
	|
	|	1 AS ZoomRatio,
	|	ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|
	|	0 AS ResidualValueMan,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|
	|	0 AS NetBookValueLocal,
	|	0 AS NetBookValueOfTF,
	|	0 AS PDResidualValue,
	|	0 AS PDSPFResidualValue,
	|
	|	0 AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
	|
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	FALSE AS ObtainedByDisassemblyCombining,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostTargetFinancing,
	|	0 AS CostPermanentDifference,
	|
	|	0 AS CostUpdate,
	|	0 AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|
	|	0 AS DepreciationUpdate,
	|	0 AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|
	|	0 AS Depreciation,
	|	0 AS DepreciationLocal,
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationPermanentDifferences,
	|
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	0 AS CostUsedToCalculateDepreciationLocal,
	|	0 AS CostForCalculatingDepreciationPD,
	|
	|	0 AS CFBUCoefficient,
	|
	|	ListOfFA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	FALSE AS PreliminaryCostExceedsActual,
	|
	|	FALSE AS MACostAdjustment,
	|	FALSE AS ACCostAdjustment,
	|	FALSE AS MADepreciationAdjustment,
	|	FALSE AS ACDepreciationAdjustment,
	|
	|	UNDEFINED AS RevaluationMethod,
	|	FALSE AS RevaluateAtFairValue,
	|
	|	FALSE AS TheseAreChanges
	|
	|FROM
	|	CalculationOfDepreciationForLastMonth_Unchanged_BU_M AS ListOfFA
	|
	|WHERE
	|	ListOfFA.FixedAsset IN
	|		(SELECT
	|			ListOfFA.FixedAsset
	|		FROM
	|			ListOfOSSWithChangedParameters_Y AS ListOfFA)
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS Priority,
	|	ListOfFA.Period AS Period,
	|	ListOfFA.Recorder AS Recorder,
	|	ListOfFA.BusinessOperation AS BusinessOperation,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.FixedAssetsLocation AS FixedAssetsLocation,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	CAST(ListOfFA.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
	|	ListOfFA.ExpenseItem AS ExpenseItem,
	|	ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	0 AS AmountOfUU,
	|	0 AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|
	|	0 AS ImpairmentMA,
	|	0 AS ImpairmentAC,
	|
	|	1 AS ZoomRatio,
	|	ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|
	|	0 AS ResidualValueMan,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|
	|	0 AS NetBookValueLocal,
	|	0 AS NetBookValueOfTF,
	|	0 AS PDResidualValue,
	|	0 AS PDSPFResidualValue,
	|
	|	0 AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
	|
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	FALSE AS ObtainedByDisassemblyCombining,
	|
	|	0 AS Cost,
	|	ListOfFA.LocalCost AS LocalCost,
	|	0 AS CostTargetFinancing,
	|	0 AS CostPermanentDifference,
	|
	|	0 AS CostUpdate,
	|	ListOfFA.LocalCostUpdate AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|
	|	0 AS DepreciationUpdate,
	|	ListOfFA.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|
	|	0 AS Depreciation,
	|	ListOfFA.DepreciationLocal AS DepreciationLocal,
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationPermanentDifferences,
	|
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	0 AS CostUsedToCalculateDepreciationLocal,
	|	0 AS CostForCalculatingDepreciationPD,
	|
	|	0 AS CFBUCoefficient,
	|
	|	ListOfFA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ListOfFA.PreliminaryCostExceedsActual AS PreliminaryCostExceedsActual,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MACostAdjustment,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) AS ACCostAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MADepreciationAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) AS ACDepreciationAdjustment,
	|
	|	ListOfFA.RevaluationMethod AS RevaluationMethod,
	|	ISNULL(Revaluation.RevaluateAtFairValue, FALSE) AS RevaluateAtFairValue,
	|
	|	TRUE AS TheseAreChanges
	|
	|FROM
	|	ListOfOSSWithChangedParameters_BU_MU AS ListOfFA
	|
	|		LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|		ON Adjusting.Ref = ListOfFA.Recorder
	|
	|		LEFT JOIN Document.FARevaluation2_4 AS Revaluation
	|		ON Revaluation.Ref = ListOfFA.Recorder
	|WHERE
	|	ListOfFA.ThisIsAnAdditionalAccrual
	|";

	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;

	QueryResult = Query.Execute();
	
	AmortizationOfChanges = CalculateDepreciationWhenParametersChange(QueryResult.Unload(), Undefined);
	
	QueryText =
	"SELECT
	|	DepreciationCalculation.Period AS Period,
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.Department AS Department,
	|	DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|	DepreciationCalculation.FixedAsset AS FixedAsset,
	|	DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|	DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|	DepreciationCalculation.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	DepreciationCalculation.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DepreciationCalculation.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	DepreciationCalculation.AmountAccounting AS AmountAccounting,
	|	DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	DepreciationCalculation.ResourceAssigned AS ResourceAssigned,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	DepreciationCalculation.ImpairmentLocalAssets AS ImpairmentBalanceLocal,
	|	DepreciationCalculation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	DepreciationCalculation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	DepreciationCalculation.PreliminaryCostExceedsActual AS PreliminaryCostExceedsActual,
	|
	|	CASE
	|		WHEN DepreciationCalculation.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
	|			THEN 1
	|		ELSE 0
	|	END AS VersionOfAccrualMethod
	|
	|INTO CalculationOfDepreciation_ForLastMonth_TakingIntoAccountChangesInBU_MU
	|
	|FROM
	|	&AmortizationOfChanges AS DepreciationCalculation
	|
	|WHERE
	|	DepreciationCalculation.TheseAreChanges
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("AmortizationOfChanges", AmortizationOfChanges);

	Query.Execute();
	
EndProcedure

#EndRegion

#Region CalculationForCurrentMonth

Procedure CalculateDepreciation_ForCurrentMonthMA(CalculationParameters)
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(CalculationParameters.TempTablesManager);
	TTUsed.Add("CalculationOfDepreciation_ForCurrentMonth_UnchangedMA");
	TTUsed.Add("CalculationOfDepreciation_ForCurrentMonth_TakingIntoAccountChangesInMA");

	CalculateDepreciation_ForCurrentMonth_UnchangedMA(CalculationParameters);
	CalculateDepreciation_ForCurrentMonth_TakingIntoAccountMAChanges(CalculationParameters);

	TMCommonUse.DestroyTemporaryTables(CalculationParameters.TempTablesManager,, TTUsed);
	
EndProcedure

Procedure CalculateDepreciation_ForCurrentMonth_UnchangedMA(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	ListOfFA.Period AS Period,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.Department AS Department,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	ListOfFA.ExpenseItem AS ExpenseItem,
	|	ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|	ListOfFA.Cost AS Cost,
	|	ListOfFA.LocalCost AS LocalCost,
	|	ListOfFA.Depreciation AS Depreciation,
	|	ListOfFA.DepreciationLocal AS DepreciationLocal,
	|	ListOfFA.NetBookValue AS NetBookValue,
	|	ListOfFA.NetBookValueLocal AS NetBookValueLocal,
	|	ListOfFA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	ListOfFA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	ListOfFA.ResidualValueMan AS ResidualValueMan,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|	ListOfFA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|	ListOfFA.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	ListOfFA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ListOfFA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|
	|	ListOfFA.ImpairmentMA AS ImpairmentMA,
	|	ListOfFA.ImpairmentAC AS ImpairmentAC,
	|
	|	CASE 
	|		WHEN ListOfFA.NetBookValue < 0
	|
	|			THEN 
	|				CASE
	|					WHEN (ListOfFA.NetBookValue - ListOfFA.AmountOfUU) > -&MinimumResidualValueOfUpr
	|
	|						THEN ListOfFA.NetBookValue
	|
	|					ELSE ListOfFA.AmountOfUU
	|				END
	|
	|		WHEN (ListOfFA.NetBookValue - ListOfFA.ResidualValueMan - ListOfFA.AmountOfUU - ListOfFA.ImpairmentMA) < &MinimumResidualValueOfUpr
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|			THEN ListOfFA.NetBookValue - ListOfFA.ResidualValueMan - ListOfFA.ImpairmentMA
	|
	|		WHEN (ListOfFA.NetBookValue - ListOfFA.ResidualValueMan - ListOfFA.AmountOfUU) < &MinimumResidualValueOfUpr
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|			THEN ListOfFA.NetBookValue - ListOfFA.ResidualValueMan
	|
	|		ELSE ListOfFA.AmountOfUU
	|
	|	END AS AmountOfUU,
	|
	|	CASE 
	|		WHEN ListOfFA.NetBookValueLocal < 0
	|			THEN 
	|				CASE
	|					WHEN (ListOfFA.NetBookValueLocal - ListOfFA.AmountAccounting) > -&MinimumResidualValueOfRegl
	|
	|						THEN ListOfFA.NetBookValueLocal
	|
	|					ELSE ListOfFA.AmountAccounting
	|				END
	|
	|		WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal - ListOfFA.ImpairmentAC - ListOfFA.AmountAccounting) < &MinimumResidualValueOfRegl
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|			THEN ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal - ListOfFA.ImpairmentAC
	|
	|		WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal - ListOfFA.AmountAccounting) < &MinimumResidualValueOfRegl
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|			THEN ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal
	|
	|		ELSE ListOfFA.AmountAccounting
	|
	|	END AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForCurrentMonth_UnchangedMA
	|
	|FROM
	|	(SELECT
	|		ListOfFA.Period AS Period,
	|		ListOfFA.Organization AS Organization,
	|		ListOfFA.FixedAssetsLocation AS Department,
	|		ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfFA.LineOfBusiness AS LineOfBusiness,
	|		ListOfFA.FixedAsset AS FixedAsset,
	|		ListOfFA.ExpenseItemManagementAccounting AS ExpenseItem,
	|		ListOfFA.ExpensesDimensionManagementAccounting AS DimensionOfExpenses,
	|		ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfFA.MethodOfReflectingDepreciationOfMA AS DepreciationRecordMethod,
	|		ListOfFA.TransferExpensesToAnotherMaOrganization AS TransferExpensesToAnotherCompany,
	|		ListOfFA.OrganizationRecipientOfMaExpenses AS CompanyRecipientOfExpenses,
	|		ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfFA.ResourceAssigned AS ResourceAssigned,
	|		ListOfFA.DepreciationMethod AS DepreciationMethod,
	|		ListOfFA.Cost AS Cost,
	|		ListOfFA.LocalCost AS LocalCost,
	|		ListOfFA.Depreciation AS Depreciation,
	|		ListOfFA.DepreciationLocal AS DepreciationLocal,
	|		ListOfFA.NetBookValue - ISNULL(AdditionalCharges.AmountOfUU, 0) AS NetBookValue,
	|		ListOfFA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) AS NetBookValueLocal,
	|
	|		CASE
	|			WHEN ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|				THEN ListOfFA.NetBookValue - ISNULL(AdditionalCharges.AmountOfUU, 0)
	|			ELSE ListOfFA.CostUsedToCalculateDepreciationManag
	|		END AS CostUsedToCalculateDepreciationManag,
	|
	|		CASE
	|			WHEN ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|				THEN ListOfFA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|			ELSE ListOfFA.CostUsedToCalculateDepreciationLocal
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		ListOfFA.ResidualValueMan AS ResidualValueMan,
	|		ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|		ListOfFA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfFA.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|		ListOfFA.AccelerationFactor AS AccelerationFactor,
	|		ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|		ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|		ListOfFA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|		ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|		CASE
	|			WHEN ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|					AND ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
	|				THEN 1
	|			ELSE 0
	|		END AS VersionOfAccrualMethod,
	|
	|		CASE
	|			WHEN &ImpairmentMA > ListOfFA.ImpairmentBalanceMan
	|					OR ListOfFA.ImpairmentBalanceMan - &ImpairmentMA < &MinimumResidualValueOfUpr
	|
	|				THEN ListOfFA.ImpairmentBalanceMan
	|
	|			ELSE &ImpairmentMA
	|
	|		END AS ImpairmentMA,
	|
	|		CASE
	|			WHEN (&ImpairmentAC) > ListOfFA.ImpairmentBalanceLocal
	|					OR ListOfFA.ImpairmentBalanceLocal - (&ImpairmentAC) < &MinimumResidualValueOfRegl
	|
	|				THEN ListOfFA.ImpairmentBalanceLocal
	|
	|			ELSE &ImpairmentAC
	|
	|		END AS ImpairmentAC,
	|
	|		CASE 
	|			WHEN (ListOfFA.NetBookValue - ISNULL(AdditionalCharges.AmountOfUU, 0)) < 0
	|
	|				THEN 
	|					CASE
	|						WHEN (ListOfFA.NetBookValue - ISNULL(AdditionalCharges.AmountOfUU, 0) - (&AmountOfMaDepreciation)) > -&MinimumResidualValueOfUpr
	|
	|							THEN ListOfFA.NetBookValue - ISNULL(AdditionalCharges.AmountOfUU, 0)
	|
	|						ELSE &AmountOfMaDepreciation
	|					END
	|
	|			WHEN (ListOfFA.NetBookValue - ListOfFA.ImpairmentBalanceMan - ListOfFA.ResidualValueMan - ISNULL(AdditionalCharges.AmountOfUU, 0) - (&AmountOfMaDepreciation)) < &MinimumResidualValueOfUpr
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|				THEN ListOfFA.NetBookValue - ListOfFA.ImpairmentBalanceMan - ListOfFA.ResidualValueMan - ISNULL(AdditionalCharges.AmountOfUU, 0)
	|
	|			WHEN (ListOfFA.NetBookValue - ListOfFA.ResidualValueMan - ISNULL(AdditionalCharges.AmountOfUU, 0) - (&AmountOfMaDepreciation)) < &MinimumResidualValueOfUpr
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|				THEN ListOfFA.NetBookValue - ListOfFA.ResidualValueMan - ISNULL(AdditionalCharges.AmountOfUU, 0)
	|
	|			ELSE &AmountOfMaDepreciation
	|
	|		END AS AmountOfUU,
	|
	|		CASE 
	|			WHEN (ListOfFA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)) < 0
	|
	|				THEN 
	|					CASE
	|						WHEN (ListOfFA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) - (&AmountOfACDepreciation)) > -&MinimumResidualValueOfRegl
	|
	|							THEN ListOfFA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|
	|						ELSE &AmountOfACDepreciation
	|					END
	|
	|			WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ImpairmentBalanceLocal - ListOfFA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) - (&AmountOfACDepreciation)) < &MinimumResidualValueOfRegl
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|				THEN ListOfFA.NetBookValueLocal - ListOfFA.ImpairmentBalanceLocal - ListOfFA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|
	|			WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) - (&AmountOfACDepreciation)) < &MinimumResidualValueOfRegl
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|				THEN ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|
	|			ELSE &AmountOfACDepreciation
	|
	|		END AS AmountAccounting
	|
	|	FROM
	|		ListOfOSSParameters_UU AS ListOfFA
	|
	|			LEFT JOIN CalculationOfDepreciation_ForLastMonthUU_Grouped AS AdditionalCharges
	|			ON AdditionalCharges.FixedAsset = ListOfFA.FixedAsset
	|
	|			LEFT JOIN CheckingCalculationParameters_Y AS CheckingCalculationParameters
	|			ON CheckingCalculationParameters.AccountingObject = ListOfFA.FixedAsset
	|				AND CheckingCalculationParameters.Organization = ListOfFA.Organization
	|
	|	WHERE
	|		NOT ListOfFA.ThisIsAnAdditionalAccrual
	|		AND CheckingCalculationParameters.AccountingObject IS NULL
	|
	|	) AS ListOfFA
	|";
	
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	RequestTextParameters.TextCostToCalculateDepreciation = "ListOfFA.CostUsedToCalculateDepreciationManag";
	RequestTextParameters.TextResidualValue = "ListOfFA.NetBookValue";
	RequestTextParameters.TextLiquidationValue = "ListOfFA.ResidualValueMan";
	RequestTextParameters.TextCostAtBeginningOfYear = "ListOfFA.CostAtBeginningOfYear";
	RequestTextParameters.TextImpairment = "ListOfFA.ImpairmentBalanceMan";
	RequestTextParameters.TextAmountOfAdditionalCharge = "ISNULL(AdditionalCharges.AmountOfUU, 0)";

	TextAmountOfDepreciationOfMa = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfMaDepreciation", TextAmountOfDepreciationOfMa);
	
	//
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	RequestTextParameters.TextCostToCalculateDepreciation = "ListOfFA.CostUsedToCalculateDepreciationLocal";
	RequestTextParameters.TextResidualValue = "ListOfFA.NetBookValueLocal";
	RequestTextParameters.TextLiquidationValue = "ListOfFA.ResidualValueLocal";
	RequestTextParameters.TextCostAtBeginningOfYear = "ListOfFA.LocalCostAtBeginningOfYear";
	RequestTextParameters.TextImpairment = "ListOfFA.ImpairmentBalanceLocal";
	RequestTextParameters.TextAmountOfAdditionalCharge = "ISNULL(AdditionalCharges.AmountAccounting, 0)";
	
	TextACDepreciationAmount = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfACDepreciation", TextACDepreciationAmount);
	
	//
	TextMaImpairment = QueryTextAmountOfImpairment("ListOfFA.ImpairmentBalanceMan");
	QueryText = StrReplace(QueryText, "&ImpairmentMA", TextMaImpairment);
	
	//
	TextACImpairment = QueryTextAmountOfImpairment("ListOfFA.ImpairmentBalanceLocal");
	QueryText = StrReplace(QueryText, "&ImpairmentAC", TextACImpairment);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	Query.Execute();
	
EndProcedure

Procedure CalculateDepreciation_ForCurrentMonth_TakingIntoAccountMAChanges(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	MergeOfFixedAssets.Ref AS Ref,
	|	MergeOfFixedAssets.FixedAsset AS PrincipalMeansRecipient,
	|	TabularSection.FixedAsset AS MainMeansSource
	|
	|INTO MergeOfFixedAssets
	|
	|FROM
	|	Document.MergeOfFixedAssets AS MergeOfFixedAssets
	|
	|		INNER JOIN Document.MergeOfFixedAssets.FA AS TabularSection
	|		ON (TabularSection.Ref = MergeOfFixedAssets.Ref)
	|
	|WHERE
	|	MergeOfFixedAssets.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND MergeOfFixedAssets.Posted
	|	AND MergeOfFixedAssets.RecordInManAccounting
	|
	|	AND (MergeOfFixedAssets.Organization, TabularSection.FixedAsset) IN
	|		(SELECT
	|			TTDataToBeCalculated.Organization,
	|			TTDataToBeCalculated.AccountingObject
	|		FROM
	|			TTDataToBeCalculated AS TTDataToBeCalculated)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfFA.FixedAsset AS FixedAsset
	|
	|INTO FilterFA
	|
	|FROM
	|	ListOfOSSWithChangedParameters_Y AS ListOfFA
	|
	|UNION ALL
	|
	|SELECT
	|	ListOfFA.MainMeansSource
	|FROM
	|	MergeOfFixedAssets AS ListOfFA
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.FixedAsset AS MainMeansSource,
	|	TabularSection.FixedAsset AS PrincipalMeansRecipient,
	|
	|	DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit),
	|		VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)) AS ThisIsPartialWriteOff,
	|
	|	TabularSection.CostInManagementAccounting AS CostOfWritingOffMan,
	|	TabularSection.CostInAccounting AS CostOfLocalTaxDeduction,
	|	0 AS CostOfWritingOffPD
	|
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
	|
	|		INNER JOIN Document.SplitFixedAssets.FA AS TabularSection
	|		ON (TabularSection.Ref = DocumentData.Ref)
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.Posted
	|	AND DocumentData.RecordInManAccounting
	|
	|	AND (DocumentData.Organization, TabularSection.FixedAsset) IN
	|		(SELECT
	|			TTDataToBeCalculated.Organization,
	|			TTDataToBeCalculated.AccountingObject
	|		FROM
	|			TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.MainMeansSource AS MainMeansSource,
	|	DocumentData.PrincipalMeansRecipient AS PrincipalMeansRecipient,
	|	FALSE AS ThisIsPartialWriteOff,
	|	0 AS CostOfWritingOffMan,
	|	0 AS CostOfLocalTaxDeduction,
	|	0 AS CostOfWritingOffPD
	|
	|FROM
	|	MergeOfFixedAssets AS DocumentData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS Priority,
	|	DATETIME(1,1,1) AS Period,
	|	UNDEFINED AS Recorder,
	|	UNDEFINED AS BusinessOperation,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.Department AS Department,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	CAST(ListOfFA.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
	|	ListOfFA.ExpenseItem AS ExpenseItem,
	|	ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	ListOfFA.AmountOfUU AS AmountOfUU,
	|	ListOfFA.AmountAccounting AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|
	|	ListOfFA.ImpairmentMA AS ImpairmentMA,
	|	ListOfFA.ImpairmentAC AS ImpairmentAC,
	|
	|	1 AS ZoomRatio,
	|	ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|	ListOfFA.ResidualValueMan AS ResidualValueMan,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	FALSE AS ObtainedByDisassemblyCombining,
	|
	|	ListOfFA.Cost AS Cost,
	|	ListOfFA.LocalCost AS LocalCost,
	|	0 AS CostTargetFinancing,
	|	0 AS CostPermanentDifference,
	|
	|	0 AS NetBookValueLocal,
	|	0 AS NetBookValueOfTF,
	|	0 AS PDResidualValue,
	|	0 AS PDSPFResidualValue,
	| 
	|	ListOfFA.ImpairmentBalanceLocal AS ImpairmentLocalAssets,
	|	ListOfFA.ImpairmentBalanceMan AS ImpairmenMan,
	|
	|	0 AS CostUpdate,
	|	0 AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|	0 AS CostInTaxAccountingUpdate,
	|
	|	0 AS DepreciationUpdate,
	|	0 AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|	0 AS DepreciationInTaxAccountingUpdate,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(ListOfFA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfFA.Depreciation + ISNULL(AdditionalCharges.AmountOfUU, 0)
	|		ELSE ListOfFA.Depreciation
	|	END AS Depreciation,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(ListOfFA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfFA.DepreciationLocal + ISNULL(AdditionalCharges.AmountAccounting, 0)
	|		ELSE ListOfFA.DepreciationLocal
	|	END AS DepreciationLocal,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationPermanentDifferences,
	|
	|	ListOfFA.Cost - ListOfFA.Depreciation AS CostUsedToCalculateDepreciationManag,
	|	ListOfFA.LocalCost - ListOfFA.DepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	0 AS CostForCalculatingDepreciationPD,
	|	0 AS CostForCalculatingPD,
	|
	|	0 AS CFBUCoefficient,
	|
	|	ListOfFA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	FALSE AS MACostAdjustment,
	|	FALSE AS ACCostAdjustment,
	|	FALSE AS MADepreciationAdjustment,
	|	FALSE AS ACDepreciationAdjustment,
	|
	|	UNDEFINED AS RevaluationMethod,
	|	FALSE AS RevaluateAtFairValue,
	|
	|	FALSE AS TheseAreChanges
	|
	|FROM
	|	CalculationOfDepreciation_ForCurrentMonth_UnchangedMA AS ListOfFA
	|
	|		LEFT JOIN CalculationOfDepreciation_ForLastMonthUU_Grouped AS AdditionalCharges
	|		ON AdditionalCharges.FixedAsset = ListOfFA.FixedAsset
	|WHERE
	|	ListOfFA.FixedAsset IN
	|		(SELECT
	|			ListOfFA.FixedAsset
	|		FROM
	|			FilterFA AS ListOfFA)
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN VALUETYPE(ListOfFA.Recorder) = TYPE(Document.SplitFixedAssets)
	|		AND NOT ListOfFA.ObtainedByDisassemblyCombining
	|			THEN 3
	|		WHEN ListOfFA.ObtainedByDisassemblyCombining
	|			THEN 2
	|		ELSE 1
	|	END AS Priority,
	|	ListOfFA.Period AS Period,
	|	ListOfFA.Recorder AS Recorder,
	|	ListOfFA.BusinessOperation AS BusinessOperation,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.FixedAssetsLocation AS FixedAssetsLocation,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	CAST(ListOfFA.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
	|	ListOfFA.ExpenseItemManagementAccounting AS ExpenseItemManagementAccounting,
	|	ListOfFA.ExpensesDimensionManagementAccounting AS ExpensesDimensionManagementAccounting,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.MethodOfReflectingDepreciationOfMA AS MethodOfReflectingDepreciationOfMA,
	|
	|	0 AS AmountOfUU,
	|	0 AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|
	|	0 AS ImpairmentMA,
	|	0 AS ImpairmentAC,
	|
	|	1 AS ZoomRatio,
	|	ListOfFA.TransferExpensesToAnotherMaOrganization AS TransferExpensesToAnotherMaOrganization,
	|	ListOfFA.OrganizationRecipientOfMaExpenses AS OrganizationRecipientOfMaExpenses,
	|
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|	ListOfFA.ResidualValueMan AS ResidualValueMan,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	ListOfFA.ObtainedByDisassemblyCombining AS ObtainedByDisassemblyCombining,
	|
	|	ListOfFA.Cost AS Cost,
	|	ListOfFA.LocalCost AS LocalCost,
	|	0 AS CostTargetFinancing,
	|	0 AS CostPermanentDifference,
	|
	|	0 AS NetBookValueLocal,
	|	0 AS NetBookValueOfTF,
	|	0 AS PDResidualValue,
	|	0 AS PDSPFResidualValue,
	|
	|	ListOfFA.ImpairmentBalanceLocal AS ImpairmentLocalAssets,
	|	ListOfFA.ImpairmentBalanceMan AS ImpairmenMan,
	|
	|	ListOfFA.CostUpdate AS CostUpdate,
	|	ListOfFA.LocalCostUpdate AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|	0 AS CostInTaxAccountingUpdate,
	|
	|	ListOfFA.DepreciationUpdate AS DepreciationUpdate,
	|	ListOfFA.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|	0 AS DepreciationInTaxAccountingUpdate,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(ListOfFA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfFA.Depreciation + ISNULL(AdditionalCharges.AmountOfUU, 0)
	|		ELSE ListOfFA.Depreciation
	|	END AS Depreciation,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(ListOfFA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfFA.DepreciationLocal + ISNULL(AdditionalCharges.AmountAccounting, 0)
	|		ELSE ListOfFA.DepreciationLocal
	|	END AS DepreciationLocal,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationPermanentDifferences,
	|
	|	ListOfFA.Cost - ListOfFA.Depreciation AS CostUsedToCalculateDepreciationManag,
	|	ListOfFA.LocalCost - ListOfFA.DepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	0 AS CostForCalculatingDepreciationPD,
	|	0 AS CostForCalculatingPD,
	|
	|	0 AS CFBUCoefficient,
	|
	|	ListOfFA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MACostAdjustment,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) AS ACCostAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MADepreciationAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) AS ACDepreciationAdjustment,
	|
	|	ListOfFA.RevaluationMethod AS RevaluationMethod,
	|	ISNULL(Revaluation.RevaluateAtFairValue, FALSE) AS RevaluateAtFairValue,
	|
	|	TRUE AS TheseAreChanges
	|
	|FROM
	|	ListOfOSSWithChangedParameters_Y AS ListOfFA
	|
	|		LEFT JOIN CalculationOfDepreciation_ForLastMonthUU_Grouped AS AdditionalCharges
	|		ON AdditionalCharges.FixedAsset = ListOfFA.FixedAsset
	|
	|		LEFT JOIN CheckingParametersForCalculatingChangesIn_Y AS CheckingCalculationParameters
	|		ON CheckingCalculationParameters.AccountingObject = ListOfFA.FixedAsset
	|			AND CheckingCalculationParameters.Organization = ListOfFA.Organization
	|
	|		LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|		ON Adjusting.Ref = ListOfFA.Recorder
	|
	|		LEFT JOIN Document.FARevaluation2_4 AS Revaluation
	|		ON Revaluation.Ref = ListOfFA.Recorder
	|
	|WHERE
	|	NOT ListOfFA.ThisIsAnAdditionalAccrual
	|	AND CheckingCalculationParameters.AccountingObject IS NULL
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	QueryResult = Query.ExecuteBatch();
	
	AmortizationOfChanges = CalculateDepreciationWhenParametersChange(
								QueryResult[QueryResult.UBound()].Unload(), 
								QueryResult[QueryResult.UBound()-1].Unload());
	
	QueryText = 
	"SELECT
	|	DepreciationCalculation.Period AS Period,
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.Department AS Department,
	|	DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|	DepreciationCalculation.FixedAsset AS FixedAsset,
	|	DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|	DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|	DepreciationCalculation.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	DepreciationCalculation.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DepreciationCalculation.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	DepreciationCalculation.AmountOfUU AS AmountOfUU,
	|	DepreciationCalculation.AmountAccounting AS AmountAccounting,
	|	DepreciationCalculation.ImpairmentMA AS ImpairmentMA,
	|	DepreciationCalculation.ImpairmentAC AS ImpairmentAC,
	|	DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	DepreciationCalculation.ResourceAssigned AS ResourceAssigned,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	DepreciationCalculation.ImpairmentLocalAssets AS ImpairmentBalanceLocal,
	|	DepreciationCalculation.ImpairmenMan AS ImpairmentBalanceMan,
	|	DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	DepreciationCalculation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	|	CASE
	|		WHEN DepreciationCalculation.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
	|			THEN 1
	|		ELSE 0
	|	END AS VersionOfAccrualMethod
	|
	|INTO CalculationOfDepreciation_ForCurrentMonth_TakingIntoAccountChangesInMA
	|
	|FROM
	|	&AmortizationOfChanges AS DepreciationCalculation
	|
	|WHERE
	|	DepreciationCalculation.TheseAreChanges";

	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("AmortizationOfChanges", AmortizationOfChanges);

	Query.Execute();
	
EndProcedure

Procedure CalculateDepreciation_ForCurrentMonthAC(CalculationParameters)
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(CalculationParameters.TempTablesManager);
	TTUsed.Add("CalculationOfDepreciation_ForCurrentMonth_UnchangedBU_MU");
	TTUsed.Add("CalculationOfDepreciation_ForCurrentMonth_TakingIntoAccountChangesInBU_MU");

	CalculateDepreciation_ForCurrentMonth_UnchangedAC(CalculationParameters);
	CalculateDepreciation_ForCurrentMonth_TakingIntoAccountChangesInAC(CalculationParameters);

	TMCommonUse.DestroyTemporaryTables(CalculationParameters.TempTablesManager,, TTUsed);

EndProcedure

Procedure CalculateDepreciation_ForCurrentMonth_UnchangedAC(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	ListOfFA.Period AS Period,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.Department AS Department,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	ListOfFA.ExpenseItem AS ExpenseItem,
	|	ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|	ListOfFA.LocalCost AS LocalCost,
	|	ListOfFA.DepreciationLocal AS DepreciationLocal,
	|	ListOfFA.NetBookValueLocal AS NetBookValueLocal,
	|	ListOfFA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|	ListOfFA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	ListOfFA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	ListOfFA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|
	|	ListOfFA.ImpairmentAC AS ImpairmentAC,
	|
	|	CASE
	|		WHEN ListOfFA.NetBookValueLocal < 0
	|			THEN 
	|				CASE
	|					WHEN (ListOfFA.NetBookValueLocal - ListOfFA.AmountAccounting) > -&MinimumResidualValueOfRegl
	|
	|						THEN ListOfFA.NetBookValueLocal
	|
	|					ELSE ListOfFA.AmountAccounting
	|				END
	|
	|		WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal - ListOfFA.ImpairmentAC - ListOfFA.AmountAccounting) < &MinimumResidualValueOfRegl 
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|			THEN ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal - ListOfFA.ImpairmentAC
	|
	|		WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal - ListOfFA.AmountAccounting) < &MinimumResidualValueOfRegl
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|			THEN ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal
	|
	|		ELSE ListOfFA.AmountAccounting
	|
	|	END AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForCurrentMonth_UnchangedBU_MU
	|
	|FROM
	|	(SELECT
	|		ListOfFA.Period AS Period,
	|		ListOfFA.Organization AS Organization,
	|		ListOfFA.FixedAssetsLocation AS Department,
	|		ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfFA.LineOfBusiness AS LineOfBusiness,
	|		ListOfFA.FixedAsset AS FixedAsset,
	|		ListOfFA.ExpenseItem AS ExpenseItem,
	|		ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfFA.ResourceAssigned AS ResourceAssigned,
	|		ListOfFA.DepreciationMethod AS DepreciationMethod,
	|		ListOfFA.LocalCost AS LocalCost,
	|		ListOfFA.DepreciationLocal AS DepreciationLocal,
	|		ListOfFA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) AS NetBookValueLocal,
	|		ListOfFA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|		ListOfFA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfFA.AccelerationFactor AS AccelerationFactor,
	|		ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|		ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|		ListOfFA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|		CASE
	|			WHEN ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|					AND ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
	|				THEN 1
	|			ELSE 0
	|		END AS VersionOfAccrualMethod,
	|
	|		CASE
	|			WHEN &ImpairmentAC > ListOfFA.ImpairmentBalanceLocal
	|					OR ListOfFA.ImpairmentBalanceLocal - &ImpairmentAC < &MinimumResidualValueOfRegl
	|
	|				THEN ListOfFA.ImpairmentBalanceLocal
	|
	|			ELSE &ImpairmentAC
	|
	|		END AS ImpairmentAC,
	|
	|		CASE
	|			WHEN (ListOfFA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)) < 0
	|				THEN 
	|					CASE
	|						WHEN (ListOfFA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) - (&AmountOfACDepreciation)) > -&MinimumResidualValueOfRegl
	|
	|							THEN ListOfFA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|
	|						ELSE &AmountOfACDepreciation
	|					END
	|
	|			WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ImpairmentBalanceLocal - ListOfFA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) - (&AmountOfACDepreciation)) < &MinimumResidualValueOfRegl
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|				THEN ListOfFA.NetBookValueLocal - ListOfFA.ImpairmentBalanceLocal - ListOfFA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|
	|			WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) - (&AmountOfACDepreciation)) < &MinimumResidualValueOfRegl
	|				AND ListOfFA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|				THEN ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|
	|			ELSE &AmountOfACDepreciation
	|
	|		END AS AmountAccounting
	|
	|	FROM
	|		ListOfOSSWithParameters_BU_MU AS ListOfFA
	|
	|			LEFT JOIN CalculationOfDepreciation_ForLastMonthBU_MU_Grouped AS AdditionalCharges
	|			ON AdditionalCharges.FixedAsset = ListOfFA.FixedAsset
	|
	|			LEFT JOIN CheckingCalculationParametersOf_BU_M AS CheckingCalculationParameters
	|			ON CheckingCalculationParameters.AccountingObject = ListOfFA.FixedAsset
	|				AND CheckingCalculationParameters.Organization = ListOfFA.Organization
	|
	|	WHERE
	|		NOT ListOfFA.ThisIsAnAdditionalAccrual
	|		AND CheckingCalculationParameters.AccountingObject IS NULL
	|
	|	) AS ListOfFA
	|";
	
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	RequestTextParameters.TextCostToCalculateDepreciation = "ListOfFA.CostUsedToCalculateDepreciationLocal";
	RequestTextParameters.TextResidualValue = "ListOfFA.NetBookValueLocal";
	RequestTextParameters.TextLiquidationValue = "ListOfFA.ResidualValueLocal";
	RequestTextParameters.TextCostAtBeginningOfYear = "ListOfFA.LocalCostAtBeginningOfYear";
	RequestTextParameters.TextImpairment = "ListOfFA.ImpairmentBalanceLocal";
	RequestTextParameters.TextAmountOfAdditionalCharge = "ISNULL(AdditionalCharges.AmountAccounting, 0)";
	
	TextACDepreciationAmount = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfACDepreciation", TextACDepreciationAmount);
	
	TextACImpairment = QueryTextAmountOfImpairment("ListOfFA.ImpairmentBalanceLocal");
	QueryText = StrReplace(QueryText, "&ImpairmentAC", TextACImpairment);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	Query.Execute();
	
EndProcedure

Procedure CalculateDepreciation_ForCurrentMonth_TakingIntoAccountChangesInAC(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	MergeOfFixedAssets.Ref AS Ref,
	|	MergeOfFixedAssets.FixedAsset AS PrincipalMeansRecipient,
	|	TabularSection.FixedAsset AS MainMeansSource
	|
	|INTO CombiningOS_BU_MU
	|
	|FROM
	|	Document.MergeOfFixedAssets AS MergeOfFixedAssets
	|
	|		INNER JOIN Document.MergeOfFixedAssets.FA AS TabularSection
	|		ON (TabularSection.Ref = MergeOfFixedAssets.Ref)
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND MergeOfFixedAssets.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND MergeOfFixedAssets.Posted
	|	AND MergeOfFixedAssets.RecordInLocalAccounting
	|
	|	AND (MergeOfFixedAssets.Organization, TabularSection.FixedAsset) IN
	|		(SELECT
	|			TTDataToBeCalculated.Organization,
	|			TTDataToBeCalculated.AccountingObject
	|		FROM
	|			TTDataToBeCalculated AS TTDataToBeCalculated)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfFA.FixedAsset AS FixedAsset
	|
	|INTO OS_BU_MUSelection
	|
	|FROM
	|	ListOfOSSWithChangedParameters_BU_MU AS ListOfFA
	|
	|UNION ALL
	|
	|SELECT
	|	ListOfFA.MainMeansSource
	|FROM
	|	CombiningOS_BU_MU AS ListOfFA
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.FixedAsset AS MainMeansSource,
	|	TabularSection.FixedAsset AS PrincipalMeansRecipient,
	|
	|	DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit),
	|		VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)) AS ThisIsPartialWriteOff,
	|
	|	0 AS CostOfWritingOffMan,
	|	TabularSection.CostInAccounting AS CostOfLocalTaxDeduction,
	|	0 AS CostOfWritingOffPD
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
	|
	|		INNER JOIN Document.SplitFixedAssets.FA AS TabularSection
	|		ON (TabularSection.Ref = DocumentData.Ref)
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.Posted
	|	AND DocumentData.RecordInLocalAccounting
	|
	|	AND (DocumentData.Organization, TabularSection.FixedAsset) IN
	|		(SELECT
	|			TTDataToBeCalculated.Organization,
	|			TTDataToBeCalculated.AccountingObject
	|		FROM
	|			TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.MainMeansSource AS MainMeansSource,
	|	DocumentData.PrincipalMeansRecipient AS PrincipalMeansRecipient,
	|	FALSE AS ThisIsPartialWriteOff,
	|	0 AS CostOfWritingOffMan,
	|	0 AS CostOfLocalTaxDeduction,
	|	0 AS CostOfWritingOffPD
	|
	|FROM
	|	CombiningOS_BU_MU AS DocumentData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS Priority,
	|	DATETIME(1,1,1) AS Period,
	|	UNDEFINED AS Recorder,
	|	UNDEFINED AS BusinessOperation,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.Department AS Department,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	CAST(ListOfFA.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
	|	ListOfFA.ExpenseItem AS ExpenseItem,
	|	ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	0 AS AmountOfUU,
	|	ListOfFA.AmountAccounting AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|
	|	0 AS ImpairmentMA,
	|	ListOfFA.ImpairmentAC AS ImpairmentAC,
	|
	|	1 AS ZoomRatio,
	|	ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|
	|	0 AS ResidualValueMan,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	FALSE AS ObtainedByDisassemblyCombining,
	|
	|	0 AS Cost,
	|	ListOfFA.LocalCost AS LocalCost,
	|	0 AS CostTargetFinancing,
	|	0 AS CostPermanentDifference,
	|
	|	0 AS NetBookValueLocal,
	|	0 AS NetBookValueOfTF,
	|	0 AS PDResidualValue,
	|	0 AS PDSPFResidualValue,
	|
	|	ListOfFA.ImpairmentBalanceLocal AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
	|
	|	0 AS CostUpdate,
	|	0 AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|	0 AS CostInTaxAccountingUpdate,
	|
	|	0 AS DepreciationUpdate,
	|	0 AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|	0 AS DepreciationInTaxAccountingUpdate,
	|
	|	0 AS Depreciation,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(ListOfFA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfFA.DepreciationLocal + ISNULL(AdditionalCharges.AmountAccounting, 0)
	|		ELSE ListOfFA.DepreciationLocal
	|	END AS DepreciationLocal,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationPermanentDifferences,
	|
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	ListOfFA.LocalCost - ListOfFA.DepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	0 AS CostForCalculatingDepreciationPD,
	|	0 AS CostForCalculatingPD,
	|
	|	0 AS CFBUCoefficient,
	|
	|	ListOfFA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	FALSE AS MACostAdjustment,
	|	FALSE AS ACCostAdjustment,
	|	FALSE AS MADepreciationAdjustment,
	|	FALSE AS ACDepreciationAdjustment,
	|
	|	UNDEFINED AS RevaluationMethod,
	|	FALSE AS RevaluateAtFairValue,
	|
	|	FALSE AS TheseAreChanges
	|
	|FROM
	|	CalculationOfDepreciation_ForCurrentMonth_UnchangedBU_MU AS ListOfFA
	|
	|		LEFT JOIN CalculationOfDepreciation_ForLastMonthBU_MU_Grouped AS AdditionalCharges
	|		ON AdditionalCharges.FixedAsset = ListOfFA.FixedAsset
	|
	|WHERE
	|	ListOfFA.FixedAsset IN
	|		(SELECT
	|			ListOfFA.FixedAsset
	|		FROM
	|			OS_BU_MUSelection AS ListOfFA)
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN VALUETYPE(ListOfFA.Recorder) = TYPE(Document.SplitFixedAssets)
	|		AND NOT ListOfFA.ObtainedByDisassemblyCombining
	|			THEN 3
	|		WHEN ListOfFA.ObtainedByDisassemblyCombining
	|			THEN 2
	|		ELSE 1
	|	END AS Priority,
	|
	|	ListOfFA.Period AS Period,
	|	ListOfFA.Recorder AS Recorder,
	|	ListOfFA.BusinessOperation AS BusinessOperation,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.FixedAssetsLocation AS FixedAssetsLocation,
	|	ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfFA.LineOfBusiness AS LineOfBusiness,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	CAST(ListOfFA.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
	|	ListOfFA.ExpenseItem AS ExpenseItem,
	|	ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	0 AS AmountOfUU,
	|	0 AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|
	|	0 AS ImpairmentMA,
	|	0 AS ImpairmentAC,
	|
	|	1 AS ZoomRatio,
	|	ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfFA.ResourceAssigned AS ResourceAssigned,
	|	ListOfFA.DepreciationMethod AS DepreciationMethod,
	|
	|	0 AS ResidualValueMan,
	|	ListOfFA.ResidualValueLocal AS ResidualValueLocal,
	|
	|	ListOfFA.AccelerationFactor AS AccelerationFactor,
	|	ListOfFA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfFA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	ListOfFA.ObtainedByDisassemblyCombining AS ObtainedByDisassemblyCombining,
	|
	|	0 AS Cost,
	|	ListOfFA.LocalCost AS LocalCost,
	|	0 AS CostTargetFinancing,
	|	0 AS CostPermanentDifference,
	|
	|	0 AS NetBookValueLocal,
	|	0 AS NetBookValueOfTF,
	|	0 AS PDResidualValue,
	|	0 AS PDSPFResidualValue,
	|
	|	ListOfFA.ImpairmentBalanceLocal AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
	|
	|	0 AS CostUpdate,
	|	ListOfFA.LocalCostUpdate AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|	0 AS CostInTaxAccountingUpdate,
	|
	|	0 AS DepreciationUpdate,
	|	ListOfFA.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|	0 AS DepreciationInTaxAccountingUpdate,
	|
	|	0 AS Depreciation,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(ListOfFA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfFA.DepreciationLocal + ISNULL(AdditionalCharges.AmountAccounting, 0)
	|		ELSE ListOfFA.DepreciationLocal
	|	END AS DepreciationLocal,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationPermanentDifferences,
	|	
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	ListOfFA.LocalCost - ListOfFA.DepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	0 AS CostForCalculatingDepreciationPD,
	|	0 AS CostForCalculatingPD,
	|
	|	0 AS CFBUCoefficient,
	|
	|	ListOfFA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MACostAdjustment,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) AS ACCostAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MADepreciationAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) AS ACDepreciationAdjustment,
	|
	|	ListOfFA.RevaluationMethod AS RevaluationMethod,
	|	ISNULL(Revaluation.RevaluateAtFairValue, FALSE) AS RevaluateAtFairValue,
	|
	|	TRUE AS TheseAreChanges
	|
	|FROM
	|	ListOfOSSWithChangedParameters_BU_MU AS ListOfFA
	|
	|		LEFT JOIN CalculationOfDepreciation_ForLastMonthBU_MU_Grouped AS AdditionalCharges
	|		ON AdditionalCharges.FixedAsset = ListOfFA.FixedAsset
	|
	|		LEFT JOIN CheckingParametersOfCalculationOfChangeOf_BU_M AS CheckingCalculationParameters
	|		ON CheckingCalculationParameters.AccountingObject = ListOfFA.FixedAsset
	|			AND CheckingCalculationParameters.Organization = ListOfFA.Organization
	|
	|		LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|		ON Adjusting.Ref = ListOfFA.Recorder
	|
	|		LEFT JOIN Document.FARevaluation2_4 AS Revaluation
	|		ON Revaluation.Ref = ListOfFA.Recorder
	|
	|WHERE
	|	NOT ListOfFA.ThisIsAnAdditionalAccrual
	|	AND CheckingCalculationParameters.AccountingObject IS NULL
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	QueryResult = Query.ExecuteBatch();

	AmortizationOfChanges = CalculateDepreciationWhenParametersChange(
								QueryResult[QueryResult.UBound()].Unload(), 
								QueryResult[QueryResult.UBound()-1].Unload());
	
	QueryText = 
	"SELECT
	|	DepreciationCalculation.Period AS Period,
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.Department AS Department,
	|	DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|	DepreciationCalculation.FixedAsset AS FixedAsset,
	|	DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|	DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|	DepreciationCalculation.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	DepreciationCalculation.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DepreciationCalculation.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	DepreciationCalculation.AmountAccounting AS AmountAccounting,
	|	DepreciationCalculation.ImpairmentAC AS ImpairmentAC,
	|	DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	DepreciationCalculation.ResourceAssigned AS ResourceAssigned,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	DepreciationCalculation.ImpairmentLocalAssets AS ImpairmentBalanceLocal,
	|	DepreciationCalculation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	DepreciationCalculation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	|	CASE
	|		WHEN DepreciationCalculation.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
	|			THEN 1
	|		ELSE 0
	|	END AS VersionOfAccrualMethod
	|
	|INTO CalculationOfDepreciation_ForCurrentMonth_TakingIntoAccountChangesInBU_MU
	|
	|FROM
	|	&AmortizationOfChanges AS DepreciationCalculation
	|
	|WHERE
	|	DepreciationCalculation.TheseAreChanges
	|";

	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("AmortizationOfChanges", AmortizationOfChanges);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region CalculationONChangeOfParameters

// Calculates depreciation when parameters are changed as of the date they were changed.
// 
// Parameters:
// 	AmortizationOfChanges - ValueTable - 
// 	SourceAndDestinationTable - ValueTable - 
// 	
// Returns:
// 	ValueTable - 
Function CalculateDepreciationWhenParametersChange(AmortizationOfChanges, SourceAndDestinationTable) Export

	If AmortizationOfChanges.Count() = 0 Then
		Return AmortizationOfChanges;
	EndIf;
	
	AmortizationOfChanges.Sort("TheseAreChanges,Period,Priority");
	
	If SourceAndDestinationTable <> Undefined Then
		SourceAndDestinationTable.Indexes.Add("PrincipalMeansRecipient,Ref");
	EndIf; 
	
	// Stores the calculation parameters that were used in the previous calculation.
	ValuesOfParametersForCalculatingChanges = New Map;
	
	ThereIsMA = AmortizationOfChanges.Columns.Find("Cost") <> Undefined;
	ThereIsAC = AmortizationOfChanges.Columns.Find("LocalCost") <> Undefined;
	ThereIsPD = AmortizationOfChanges.Columns.Find("CostPermanentDifference") <> Undefined;
	
	For Each RowData In AmortizationOfChanges Do
		
		ParameterValues = CalculateCostOfDepreciationAccordingToDocument(
			RowData, ValuesOfParametersForCalculatingChanges, SourceAndDestinationTable);
			
		If RowData.TheseAreChanges Then
			
			If ThereIsMA Then

				RowData.CostUsedToCalculateDepreciationManag = 
					ParameterValues.Cost 
					- ParameterValues.Depreciation 
					- ParameterValues.DepreciationForPeriodOfMan;
				
				ImpairmentMA = ?(
					RowData.PostingOptionForImpairedFADepreciation = Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment, 
					ParameterValues.ImpairmenMan - ParameterValues.ImpairmentForMonthOfMan, 
					0);
			
				RowData.AmountOfUU = CalculateAmountOfDepreciationOfMa(
											RowData, 
											RowData.CostUsedToCalculateDepreciationManag, 
											RowData.ResidualValueMan, 
											ImpairmentMA, 
											NonCurrentAssetsInternal.MinimumResidualValueOfUpr());
											
				RowData.ImpairmentMA = CalculateAmountOfImpairment(
											RowData, 
											ParameterValues.ImpairmenMan,
											NonCurrentAssetsInternal.MinimumResidualValueOfUpr());
			
			EndIf;
			
			If ThereIsAC Then
			
				RowData.CostUsedToCalculateDepreciationLocal = 
					ParameterValues.LocalCost + ParameterValues.CostTargetFinancing 
					- ParameterValues.DepreciationLocal - ParameterValues.FixedAssetDepreciationTargetFinancing
					- ParameterValues.DepreciationForPeriodOfLocal;
					
				ImpairmentAC = ?(
					RowData.PostingOptionForImpairedFADepreciation = Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment, 
					ParameterValues.ImpairmentLocalAssets - ParameterValues.ImpairmentForMonthLocal, 
					0);
					
				RowData.AmountAccounting = CalculateAmountOfDepreciationOfMa(
											RowData, 
											RowData.CostUsedToCalculateDepreciationLocal, 
											RowData.ResidualValueLocal, 
											ImpairmentAC, 
											NonCurrentAssetsInternal.MinimumResidualValueOfRegl());
										
				RowData.ImpairmentAC = CalculateAmountOfImpairment(
											RowData, 
											ParameterValues.ImpairmentLocalAssets,
											NonCurrentAssetsInternal.MinimumResidualValueOfRegl());
											
			EndIf;
										
			If ThereIsPD Then
				
				RowData.CostForCalculatingDepreciationPD = 
					ParameterValues.CostPermanentDifference - ParameterValues.DepreciationPermanentDifferences;

				If (ParameterValues.CostPermanentDifference - ParameterValues.DepreciationPermanentDifferences) = 0
					Or RowData.CostUsedToCalculateDepreciationLocal <= 0
					Or RowData.PostingOptionForImpairedFADepreciation = Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment
						And RowData.AmountAccounting + RowData.ImpairmentAC = 0
					Or RowData.PostingOptionForImpairedFADepreciation <> Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment
						And RowData.AmountAccounting = 0 Then
						
					RowData.AmountPermanentDifferences = 0;
					
				ElsIf RowData.PostingOptionForImpairedFADepreciation = Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment
							And RowData.AmountAccounting + RowData.ImpairmentAC = RowData.CostUsedToCalculateDepreciationLocal
						Or RowData.PostingOptionForImpairedFADepreciation <> Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment
							And RowData.AmountAccounting = RowData.CostUsedToCalculateDepreciationLocal Then
					
					RowData.AmountPermanentDifferences = ParameterValues.CostPermanentDifference - ParameterValues.DepreciationPermanentDifferences;
					
				Else
					
					If RowData.PostingOptionForImpairedFADepreciation = Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment Then
						
						DepreciationRatio = 
							Round((RowData.AmountAccounting - Round(RowData.AmountAccounting * RowData.CFBUCoefficient, 2) + RowData.ImpairmentAC) 
									/ (ParameterValues.LocalCost - ParameterValues.DepreciationLocal), 12);
									
					Else
						
						DepreciationRatio = 
							Round((RowData.AmountAccounting - Round(RowData.AmountAccounting * RowData.CFBUCoefficient, 2)) 
									/ (ParameterValues.LocalCost - ParameterValues.DepreciationLocal), 12);
									
					EndIf;
					
					RowData.AmountPermanentDifferences = (ParameterValues.CostPermanentDifference - ParameterValues.DepreciationPermanentDifferences) * DepreciationRatio;
							
					RowData.AmountPermanentDifferences = Round(RowData.AmountPermanentDifferences, 2);
					
				EndIf;
			
			EndIf;
			
		EndIf;
		
		If ThereIsMA Then
			ParameterValues.DepreciationForPeriodOfMan = ParameterValues.DepreciationForPeriodOfMan + RowData.AmountOfUU;
			ParameterValues.ImpairmentForMonthOfMan = ParameterValues.ImpairmentForMonthOfMan + RowData.ImpairmentMA;
		EndIf;
	
		If ThereIsAC Then
			ParameterValues.DepreciationForPeriodOfLocal = ParameterValues.DepreciationForPeriodOfLocal + RowData.AmountAccounting;
			ParameterValues.ImpairmentForMonthLocal = ParameterValues.ImpairmentForMonthLocal + RowData.ImpairmentAC;
		EndIf;

		If ThereIsPD Then
			ParameterValues.DepreciationForPeriodOfPD = ParameterValues.DepreciationForPeriodOfPD + RowData.AmountPermanentDifferences;
		EndIf;
		
	EndDo; 
	
	Return AmortizationOfChanges;

EndFunction

Procedure IncreaseCostAndDepreciationWhenDecommissioningAndCombining(RowData, ValuesOfParametersForCalculatingChanges, SourceAndDestinationTable)

	If SourceAndDestinationTable = Undefined
		Or Not RowData.ObtainedByDisassemblyCombining Then
		Return;
	EndIf; 
	
	TheStructureOfTheSearch = New Structure("PrincipalMeansRecipient,Ref", RowData.FixedAsset, RowData.Recorder);
	SourceFA = SourceAndDestinationTable.FindRows(TheStructureOfTheSearch);
	
	If SourceFA.Count() = 0 Then
		Return;
	EndIf;
	
	ThereIsMA = CommonClientServer.HasAttributeOrObjectProperty(RowData, "Cost");
	
	ThereIsAC = CommonClientServer.HasAttributeOrObjectProperty(RowData, "CostInAccounting")
				Or CommonClientServer.HasAttributeOrObjectProperty(RowData, "LocalCost");
				
	HasTA = CommonClientServer.HasAttributeOrObjectProperty(RowData, "CostInTaxAccounting");
	ThereIsPD = CommonClientServer.HasAttributeOrObjectProperty(RowData, "CostPermanentDifference");

	DepreciationUpdate = 0;
	DepreciationLocalUpdate = 0;
	DepreciationInTaxAccountingUpdate = 0;
	DepreciationPermanentDifferencesUpdate = 0;

	ParameterValues = ValuesOfParametersForCalculatingChanges.Get(RowData.FixedAsset);
	
	For Each StringSourceFA In SourceFA Do
	
		ValuesOfSourceParameters = ValuesOfParametersForCalculatingChanges.Get(StringSourceFA.MainMeansSource);
		
		If ValuesOfSourceParameters = Undefined Then
			Continue;
		EndIf; 
		
		IncreasingCostOfMan = 0;
		LocalCostIncrease = 0;
		IncreaseInCostOfPD = 0;
		IncreaseInManDepreciation = 0;
		IncreasingLocalDepreciation = 0;
		IncreaseInDepreciationPD = 0;

		// MA
		If ThereIsMA And StringSourceFA.CostOfWritingOffMan <> 0 Then
			
			IncreasingCostOfMan  = StringSourceFA.CostOfWritingOffMan;
			
			If RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				
				If ValuesOfSourceParameters.Cost <> 0 Then
					
					IncreaseInManDepreciation = 
						(ValuesOfSourceParameters.Depreciation + ValuesOfSourceParameters.DepreciationForPeriodOfMan)
							* StringSourceFA.CostOfWritingOffMan 
							/ ValuesOfSourceParameters.Cost;
						
					IncreaseInManDepreciation = Round(IncreaseInManDepreciation, 2);
					
				Else
					IncreaseInManDepreciation = 0;
				EndIf;
			
			EndIf;
			
		ElsIf ThereIsMA Then
			
			IncreasingCostOfMan = ValuesOfSourceParameters.Cost;
			
			If RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				IncreaseInManDepreciation = ValuesOfSourceParameters.Depreciation + ValuesOfSourceParameters.DepreciationForPeriodOfMan;
			EndIf;
			
		EndIf;
		
		// ACC
		If ThereIsAC And StringSourceFA.CostOfLocalTaxDeduction <> 0 Then
			
			LocalCostIncrease = StringSourceFA.CostOfLocalTaxDeduction;
			
			If RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				
				If ValuesOfSourceParameters.LocalCost <> 0 Then
					
					IncreasingLocalDepreciation = 
						(ValuesOfSourceParameters.DepreciationLocal + ValuesOfSourceParameters.DepreciationForPeriodOfLocal)
							* StringSourceFA.CostOfLocalTaxDeduction 
							/ ValuesOfSourceParameters.LocalCost;
							
					IncreasingLocalDepreciation = Round(IncreasingLocalDepreciation, 2);
					
				Else
					IncreasingLocalDepreciation = 0;
				EndIf;
				
			EndIf;
		
		ElsIf ThereIsAC Then
			
			LocalCostIncrease = ValuesOfSourceParameters.LocalCost;
			
			If RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				IncreasingLocalDepreciation = ValuesOfSourceParameters.DepreciationLocal + ValuesOfSourceParameters.DepreciationForPeriodOfLocal;
			EndIf;
			
		EndIf;
		
		// TA
		If HasTA And StringSourceFA.COSTOfWriteOffIsTA <> 0 Then
			
			IncreasingCostOfTA = StringSourceFA.COSTOfWriteOffIsTA;
			
			If RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				
				If ValuesOfSourceParameters.CostInTaxAccounting <> 0 Then
					
					IncreaseInDepreciationTA = 
						(ValuesOfSourceParameters.DepreciationInTaxAccounting + ValuesOfSourceParameters.DepreciationForPeriodTA)
							* StringSourceFA.COSTOfWriteOffIsTA 
							/ ValuesOfSourceParameters.CostInTaxAccounting;
							
					IncreaseInDepreciationTA = Round(IncreaseInDepreciationTA, 2);
					
				Else
					IncreaseInDepreciationTA = 0;
				EndIf;
				
			EndIf;
		
		ElsIf HasTA Then
			
			IncreasingCostOfTA = ValuesOfSourceParameters.CostInTaxAccounting;
			
			If RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				IncreaseInDepreciationTA = ValuesOfSourceParameters.DepreciationInTaxAccounting + ValuesOfSourceParameters.DepreciationForPeriodTA;
			EndIf;
			
		EndIf;
		
		// PD
		If ThereIsPD And StringSourceFA.CostOfWritingOffPD <> 0 Then
			
			IncreaseInCostOfPD = StringSourceFA.CostOfWritingOffPD;
			
			If RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				
				If ValuesOfSourceParameters.CostPermanentDifference <> 0 Then
					
					IncreaseInDepreciationPD = 
						(ValuesOfSourceParameters.DepreciationPermanentDifferences + ValuesOfSourceParameters.DepreciationForPeriodOfPD)
							* StringSourceFA.CostOfWritingOffPD 
							/ ValuesOfSourceParameters.CostPermanentDifference;
							
					IncreaseInDepreciationPD = Round(IncreaseInDepreciationPD, 2);
					
				Else
					IncreaseInDepreciationPD = 0;
				EndIf;
			
			EndIf;
		
		ElsIf ThereIsPD Then
			
			IncreaseInCostOfPD = ValuesOfSourceParameters.CostPermanentDifference;
			
			If RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				IncreaseInDepreciationPD = ValuesOfSourceParameters.DepreciationPermanentDifferences + ValuesOfSourceParameters.DepreciationForPeriodOfPD;
			EndIf;
			
		EndIf;

		If ThereIsMA Then
			ParameterValues.Cost = ParameterValues.Cost + IncreasingCostOfMan;
			ParameterValues.Depreciation = ParameterValues.Depreciation + IncreaseInManDepreciation;
			DepreciationUpdate = DepreciationUpdate + IncreaseInManDepreciation;
		EndIf;
		
		If ThereIsAC Then
			ParameterValues.LocalCost = ParameterValues.LocalCost + LocalCostIncrease;
			ParameterValues.DepreciationLocal = ParameterValues.DepreciationLocal + IncreasingLocalDepreciation;
			DepreciationLocalUpdate = DepreciationLocalUpdate + IncreasingLocalDepreciation;
		EndIf;
		
		If HasTA Then
			ParameterValues.CostInTaxAccounting = ParameterValues.CostInTaxAccounting + IncreasingCostOfTA;
			ParameterValues.DepreciationInTaxAccounting = ParameterValues.DepreciationInTaxAccounting + IncreaseInDepreciationTA;
			DepreciationInTaxAccountingUpdate = DepreciationInTaxAccountingUpdate + IncreaseInDepreciationTA;
		EndIf;
		
		If ThereIsPD Then
			ParameterValues.CostPermanentDifference = ParameterValues.CostPermanentDifference + IncreaseInCostOfPD;
			ParameterValues.DepreciationPermanentDifferences = ParameterValues.DepreciationPermanentDifferences + IncreaseInDepreciationPD;
			DepreciationPermanentDifferencesUpdate = DepreciationPermanentDifferencesUpdate + IncreaseInDepreciationPD;
			RowData.PDResidualValue = RowData.CostPermanentDifference - RowData.DepreciationPermanentDifferences;
			RowData.CostForCalculatingPD = RowData.CostPermanentDifference;
		EndIf;
		
	EndDo; 
	
	If ThereIsMA Then
		RowData.Cost = ParameterValues.Cost;
		ParameterValues.DepreciationUpdate = DepreciationUpdate;
		ParameterValues.Depreciation = ParameterValues.Depreciation + ParameterValues.DepreciationForPeriodOfMan;
		ParameterValues.DepreciationForPeriodOfMan = 0;
	EndIf;
	
	If ThereIsAC Then
		RowData.LocalCost = ParameterValues.LocalCost;
		ParameterValues.DepreciationLocalUpdate = DepreciationLocalUpdate;
		ParameterValues.DepreciationLocal = ParameterValues.DepreciationLocal + ParameterValues.DepreciationForPeriodOfLocal;
		ParameterValues.DepreciationForPeriodOfLocal = 0;
	EndIf;

	If HasTA Then
		RowData.CostInTaxAccounting = ParameterValues.CostInTaxAccounting;
		ParameterValues.DepreciationInTaxAccountingUpdate = DepreciationInTaxAccountingUpdate;
		ParameterValues.DepreciationInTaxAccounting = ParameterValues.DepreciationInTaxAccounting + ParameterValues.DepreciationForPeriodTA;
		ParameterValues.DepreciationForPeriodTA = 0;
	EndIf;
	
	If ThereIsPD Then
		RowData.CostPermanentDifference = ParameterValues.CostPermanentDifference;
		ParameterValues.DepreciationPermanentDifferencesUpdate = DepreciationPermanentDifferencesUpdate;
		ParameterValues.DepreciationPermanentDifferences = ParameterValues.DepreciationPermanentDifferences + ParameterValues.DepreciationForPeriodOfPD;
		ParameterValues.DepreciationForPeriodOfPD = 0;
	EndIf;
	
EndProcedure
 
Function CalculateAmountOfDepreciationOfMa(RowData, NetBookValue, ResidualValueMan, Impairment, MinimumResidualValue)

	AmountOfUU = 0;
	
	ResidualValueAfterDepreciation = NetBookValue - ResidualValueMan;
				
	If Not RowData.AccrueDepreciationOrAmortization 
		Or RowData.ResourceAssigned <= 0
		Or ResidualValueAfterDepreciation = 0
		Or ResidualValueAfterDepreciation < 0
			And Not RowData.ConsiderResidualLiabilityValue Then
		
		AmountOfUU = 0;
		
	ElsIf (RowData.LifeSpentPastPeriod + RowData.LifeSpentCurrentPeriod) >= RowData.ResourceAssigned Then
		
		AmountOfUU = NetBookValue - Impairment - ResidualValueMan;
		
	ElsIf RowData.DepreciationMethod = Enums.AccrualMethodOfFixedAssetsDepreciation.Linear
		Or RowData.DepreciationMethod = Enums.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction Then
		
		If (NetBookValue - Impairment) < 0
			And RowData.ConsiderResidualLiabilityValue Then
			
			AmountOfUU = (NetBookValue - Impairment)
						* (RowData.LifeSpentCurrentPeriod)
						/ (RowData.ResourceAssigned - RowData.LifeSpentPastPeriod);
						
		Else
			
			AmountOfUU = (NetBookValue - ResidualValueMan - Impairment)
						* (RowData.LifeSpentCurrentPeriod)
						/ (RowData.ResourceAssigned - RowData.LifeSpentPastPeriod);
		
		EndIf;
		
	ElsIf RowData.DepreciationMethod = Enums.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance Then
		
		ZoomRatio = RowData.ResourceAssigned - RowData.LifeSpentPastPeriod + RowData.AccelerationFactor - 1;
							
		If ZoomRatio <> 0 Then
			
			AmountOfUU = (NetBookValue - ResidualValueMan - Impairment)
						* RowData.LifeSpentCurrentPeriod
						* RowData.AccelerationFactor
						/ ZoomRatio;
					
		EndIf;
							
	EndIf; 
	
	If (AmountOfUU > ResidualValueAfterDepreciation
			Or (ResidualValueAfterDepreciation - AmountOfUU) < MinimumResidualValue)
		And Not RowData.ConsiderResidualLiabilityValue Then
			
		AmountOfUU = Max(ResidualValueAfterDepreciation, 0);
		
	EndIf;

	Return Round(AmountOfUU, 2);
	
EndFunction

Function CalculateAmountOfImpairment(RowData, BalanceImpairment, MinimumResidualValue)

	AmountOfImpairment = 0;
	
	If Not RowData.AccrueDepreciationOrAmortization 
		Or BalanceImpairment <= 0
		Or RowData.ResourceAssigned <= 0 Then
		
		AmountOfImpairment = 0;
		
	ElsIf (RowData.LifeSpentPastPeriod + RowData.LifeSpentCurrentPeriod) >= RowData.ResourceAssigned Then
		
		AmountOfImpairment = BalanceImpairment;
		
	ElsIf RowData.DepreciationMethod = Enums.AccrualMethodOfFixedAssetsDepreciation.Linear
		Or RowData.DepreciationMethod = Enums.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction Then
		
		AmountOfImpairment = BalanceImpairment
					* (RowData.LifeSpentCurrentPeriod)
					/ (RowData.ResourceAssigned - RowData.LifeSpentPastPeriod);
		
	ElsIf RowData.DepreciationMethod = Enums.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance Then
		
		ZoomRatio = RowData.ResourceAssigned - RowData.LifeSpentPastPeriod + RowData.AccelerationFactor - 1;
		
		If ZoomRatio <> 0 Then
			
			AmountOfImpairment = 
				BalanceImpairment
				* RowData.LifeSpentCurrentPeriod
				* RowData.AccelerationFactor
				/ ZoomRatio;
			
		EndIf;
		
	EndIf; 
	
	If AmountOfImpairment > BalanceImpairment
		Or (BalanceImpairment - AmountOfImpairment) < MinimumResidualValue Then
		AmountOfImpairment = Max(BalanceImpairment, 0);
	EndIf;

	Return Round(AmountOfImpairment, 2);
	
EndFunction

Function CalculateCostOfDepreciationAccordingToDocument(RowData, ValuesOfParametersForCalculatingChanges, SourceAndDestinationTable) Export

	ParameterValues = ValuesOfParametersForCalculatingChanges.Get(RowData.FixedAsset);
	
	If ParameterValues = Undefined Then
		
		ParameterValues = New Structure;
		
		// Cost and depreciation at the settlement date.
		// It may change during reassessment, disassembly, etc.
		ParameterValues.Insert("Cost", 0);
		ParameterValues.Insert("LocalCost", 0);
		ParameterValues.Insert("CostInTaxAccounting", 0);
		ParameterValues.Insert("CostTargetFinancing", 0);
		ParameterValues.Insert("CostPermanentDifference", 0);
		ParameterValues.Insert("CostTargetFinancingPD", 0);
		ParameterValues.Insert("Depreciation", 0);
		ParameterValues.Insert("DepreciationLocal", 0);
		ParameterValues.Insert("DepreciationInTaxAccounting", 0);
		ParameterValues.Insert("FixedAssetDepreciationTargetFinancing", 0);
		ParameterValues.Insert("DepreciationPermanentDifferences", 0);
		ParameterValues.Insert("ImpairmenMan", 0);
		ParameterValues.Insert("ImpairmentLocalAssets", 0);
		
		// Accumulated depreciation from the beginning of the month to the settlement date.
		ParameterValues.Insert("DepreciationForPeriodOfMan", 0);  
		ParameterValues.Insert("DepreciationForPeriodOfLocal", 0);
		ParameterValues.Insert("DepreciationForPeriodTA", 0);
		ParameterValues.Insert("DepreciationForPeriodOfPD", 0);
		ParameterValues.Insert("DepreciationForTFPeriod", 0);
		ParameterValues.Insert("DepreciationForPRTFPeriod", 0);
		
		// Accumulated impairment from the beginning of the month to the settlement date.
		ParameterValues.Insert("ImpairmentForMonthOfMan", 0);  
		ParameterValues.Insert("ImpairmentForMonthLocal", 0);
		
		FillPropertyValues(ParameterValues, RowData);
		
		ValuesOfParametersForCalculatingChanges.Insert(RowData.FixedAsset, ParameterValues);
		
	EndIf;
	
	// Change in cost and depreciation according to the document
	ParameterValues.Insert("CostUpdate", 0);
	ParameterValues.Insert("LocalCostUpdate", 0);
	ParameterValues.Insert("CostInTaxAccountingUpdate", 0);
	ParameterValues.Insert("CostPermanentDifferenceUpdate", 0);
	ParameterValues.Insert("DepreciationUpdate", 0);
	ParameterValues.Insert("DepreciationLocalUpdate", 0);
	ParameterValues.Insert("DepreciationInTaxAccountingUpdate", 0);
	ParameterValues.Insert("DepreciationPermanentDifferencesUpdate", 0);
	
	IncreaseCostAndDepreciationWhenDecommissioningAndCombining(
		RowData, 
		ValuesOfParametersForCalculatingChanges, 
		SourceAndDestinationTable);
	
	If Not RowData.TheseAreChanges Then
		Return ParameterValues;
	EndIf;

	ThereIsMA = CommonClientServer.HasAttributeOrObjectProperty(RowData, "Cost");
	ThereIsAC = CommonClientServer.HasAttributeOrObjectProperty(RowData, "LocalCost");
	HasTA = CommonClientServer.HasAttributeOrObjectProperty(RowData, "CostInTaxAccounting");
	ThereIsPD = CommonClientServer.HasAttributeOrObjectProperty(RowData, "CostPermanentDifference");
	
	If TypeOf(RowData.Recorder) = Type("DocumentRef.FARevaluation2_4") Then
		
		// It is necessary to calculate the cost and depreciation as the document does.
		
		If ThereIsMA Then
			
			RevaluationResult = NonCurrentAssetsInternal.RevaluationResult(
				ParameterValues.Cost, 
				ParameterValues.Depreciation + ParameterValues.DepreciationForPeriodOfMan, 
				ParameterValues.ImpairmenMan, 
				RowData.CostUpdate, 
				RowData.RevaluationMethod, 
				RowData.RevaluateAtFairValue);
			
			ParameterValues.Cost = 
				ParameterValues.Cost 
				+ RevaluationResult.ChangeInValue;
			
			ParameterValues.Depreciation = 
				ParameterValues.Depreciation 
				+ ParameterValues.DepreciationForPeriodOfMan 
				+ RevaluationResult.ChangeInDepreciation;
			
			ParameterValues.ImpairmenMan = 
				ParameterValues.ImpairmenMan 
				+ RevaluationResult.ChangeOfImpairment;
			
			ParameterValues.CostUpdate = RevaluationResult.ChangeInValue;
			ParameterValues.DepreciationUpdate = RevaluationResult.ChangeInDepreciation;
			ParameterValues.DepreciationForPeriodOfMan = 0;
		
		EndIf;
		
		If ThereIsAC Then
			
			RevaluationResult = NonCurrentAssetsInternal.RevaluationResult(
				ParameterValues.LocalCost, 
				ParameterValues.DepreciationLocal + ParameterValues.DepreciationForPeriodOfLocal, 
				ParameterValues.ImpairmentLocalAssets, 
				RowData.LocalCostUpdate, 
				RowData.RevaluationMethod, 
				RowData.RevaluateAtFairValue);
			
			ParameterValues.LocalCost = 
				ParameterValues.LocalCost 
				+ RevaluationResult.ChangeInValue;
			
			ParameterValues.DepreciationLocal = 
				ParameterValues.DepreciationLocal 
				+ RevaluationResult.ChangeInDepreciation;
			
			ParameterValues.ImpairmentLocalAssets = 
				ParameterValues.ImpairmentLocalAssets 
				+ RevaluationResult.ChangeOfImpairment;
				
			ParameterValues.LocalCostUpdate = RevaluationResult.ChangeInValue;
			ParameterValues.DepreciationLocalUpdate = RevaluationResult.ChangeInDepreciation;
			
		EndIf;

	ElsIf TypeOf(RowData.Recorder) = Type("DocumentRef.LeaseTermAdjustment") Then
		
		// It is necessary to calculate the cost as the document does.
		
		If ThereIsMA And RowData.Cost <> 0 Then
			ParameterValues.Cost = RowData.CostUpdate;
		EndIf; 

		If ThereIsAC And RowData.LocalCost <> 0 Then
			ParameterValues.LocalCost = RowData.LocalCostUpdate;
		EndIf; 
		
	ElsIf TypeOf(RowData.Recorder) = Type("DocumentRef.DisposeFixedAssets2_4")
		Or TypeOf(RowData.Recorder) = Type("DocumentRef.SplitFixedAssets")
			And Not RowData.ObtainedByDisassemblyCombining Then
		
		If RowData.AccrueDepreciationOrAmortization Then
			
			// If depreciation is charged, then this is a partial decommissioning or partial write-off.
			
			// Depreciation reduction is proportional to the written-off cost.
			If ThereIsMA 
				And ParameterValues.Cost <> 0
				And RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				
				PercentageOfWriteOffs = Round(-RowData.CostUpdate / ParameterValues.Cost, 12);
				DepreciationUpdate = Round((ParameterValues.Depreciation + ParameterValues.DepreciationForPeriodOfMan) * PercentageOfWriteOffs, 2);
				
				ParameterValues.Depreciation = 
					ParameterValues.Depreciation 
					+ ParameterValues.DepreciationForPeriodOfMan 
					- DepreciationUpdate;
					
				ParameterValues.DepreciationUpdate = -DepreciationUpdate;
				ParameterValues.DepreciationForPeriodOfMan = 0;
				
			EndIf; 
				
			If ThereIsAC 
				And ParameterValues.LocalCost <> 0
				And RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				
				PercentageOfWriteOffs = Round(-RowData.LocalCostUpdate / ParameterValues.LocalCost, 12);
				DepreciationUpdate = Round((ParameterValues.DepreciationLocal + ParameterValues.DepreciationForPeriodOfLocal) * PercentageOfWriteOffs, 2);
				
				ParameterValues.DepreciationLocal = 
					ParameterValues.DepreciationLocal 
					+ ParameterValues.DepreciationForPeriodOfLocal 
					- DepreciationUpdate;
					
				ParameterValues.DepreciationLocalUpdate = -DepreciationUpdate;
				ParameterValues.DepreciationForPeriodOfLocal = 0;
				
			EndIf; 
			
			If HasTA 
				And ParameterValues.CostInTaxAccounting <> 0 
				And RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				
				PercentageOfWriteOffs = Round(-RowData.CostInTaxAccountingUpdate / ParameterValues.CostInTaxAccounting, 12);
				DepreciationUpdate = Round((ParameterValues.DepreciationInTaxAccounting + ParameterValues.DepreciationForPeriodTA) * PercentageOfWriteOffs, 2);
				
				ParameterValues.DepreciationInTaxAccounting = 
					ParameterValues.DepreciationInTaxAccounting 
					+ ParameterValues.DepreciationForPeriodTA 
					- DepreciationUpdate;
					
				ParameterValues.DepreciationInTaxAccountingUpdate = -DepreciationUpdate;
				ParameterValues.DepreciationForPeriodTA = 0;
				
			EndIf; 
			
			If ThereIsPD 
				And ParameterValues.CostPermanentDifference <> 0
				And RowData.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
				
				PercentageOfWriteOffs = Round(-RowData.CostPermanentDifferenceUpdate / ParameterValues.CostPermanentDifference, 12);
				DepreciationUpdate = Round((ParameterValues.DepreciationPermanentDifferences + ParameterValues.DepreciationForPeriodOfPD) * PercentageOfWriteOffs, 2);
				
				ParameterValues.DepreciationPermanentDifferences = 
					ParameterValues.DepreciationPermanentDifferences 
					+ ParameterValues.DepreciationForPeriodOfPD 
					- DepreciationUpdate;
					
				ParameterValues.DepreciationPermanentDifferencesUpdate = -DepreciationUpdate;
				ParameterValues.DepreciationForPeriodOfPD = 0;
				
			EndIf; 
			
			// Reduction of the cost by the amount of the write-off.
			If ThereIsMA Then
				ParameterValues.Cost  = ParameterValues.Cost + RowData.CostUpdate;
				ParameterValues.CostUpdate = RowData.CostUpdate;
			EndIf;
			
			If ThereIsAC Then
				ParameterValues.LocalCost = ParameterValues.LocalCost + RowData.LocalCostUpdate;
				ParameterValues.LocalCostUpdate = RowData.LocalCostUpdate;
			EndIf;
			
			If HasTA Then
				ParameterValues.CostInTaxAccounting = ParameterValues.CostInTaxAccounting + RowData.CostInTaxAccountingUpdate;
				ParameterValues.CostInTaxAccountingUpdate = RowData.CostInTaxAccountingUpdate;
			EndIf;
			
			If ThereIsPD Then
				ParameterValues.CostPermanentDifference = ParameterValues.CostPermanentDifference + RowData.CostPermanentDifferenceUpdate;
				ParameterValues.CostPermanentDifferenceUpdate = RowData.CostPermanentDifferenceUpdate;
			EndIf;
			
		Else	
			
			// Complete disassembly or full write-off.
			ParameterValues.Cost = 0;
			ParameterValues.LocalCost = 0;
			ParameterValues.CostInTaxAccounting = 0;
			ParameterValues.CostPermanentDifference = 0;
			ParameterValues.Depreciation = 0;
			ParameterValues.DepreciationLocal = 0;
			ParameterValues.DepreciationInTaxAccounting = 0;
			ParameterValues.DepreciationPermanentDifferences = 0;
			ParameterValues.ImpairmenMan = 0;
			ParameterValues.ImpairmentLocalAssets = 0;
			
		EndIf; 
			
	ElsIf TypeOf(RowData.Recorder) = Type("DocumentRef.FixedAssetCostAndDepreciationAdjustment") Then
		
		If ThereIsMA
			And (RowData.MACostAdjustment
				Or RowData.CostUpdate <> 0) Then
			
			ParameterValues.Cost = RowData.CostUpdate;
			
		EndIf;
		
		If ThereIsAC
			And (RowData.ACCostAdjustment
				Or RowData.LocalCostUpdate <> 0) Then
			
			ParameterValues.LocalCost = RowData.LocalCostUpdate;
			
		EndIf;

		If HasTA
			And (RowData.CostAdjustmentTA
				Or RowData.CostInTaxAccountingUpdate <> 0) Then
			
			ParameterValues.CostInTaxAccounting = RowData.CostInTaxAccountingUpdate;
			
		EndIf;

		If ThereIsPD
			And (RowData.ACCostAdjustment
				Or RowData.CostPermanentDifferenceUpdate <> 0) Then
			
			ParameterValues.CostPermanentDifference = RowData.CostPermanentDifferenceUpdate;
			
		EndIf;

		If ThereIsMA
			And (RowData.MADepreciationAdjustment
				Or RowData.DepreciationUpdate <> 0) Then
			
			DepreciationUpdate = RowData.DepreciationUpdate - ParameterValues.Depreciation - ParameterValues.DepreciationForPeriodOfMan;
			DepreciationUpdate = Round(DepreciationUpdate, 2);

			ParameterValues.Depreciation = RowData.DepreciationUpdate;
			
			ParameterValues.DepreciationForPeriodOfMan = 0;
			ParameterValues.DepreciationUpdate = DepreciationUpdate;
			
		EndIf;
		
		If ThereIsAC
			And (RowData.ACDepreciationAdjustment
				Or RowData.DepreciationLocalUpdate <> 0) Then
			
			DepreciationUpdate = RowData.DepreciationLocalUpdate - ParameterValues.DepreciationLocal - ParameterValues.DepreciationForPeriodOfLocal;
			DepreciationUpdate = Round(DepreciationUpdate, 2);

			ParameterValues.DepreciationLocal = RowData.DepreciationLocalUpdate;
			
			ParameterValues.DepreciationForPeriodOfLocal = 0;
			ParameterValues.DepreciationLocalUpdate = DepreciationUpdate;
			
		EndIf;
		
		If HasTA
			And (RowData.DepreciationAdjustmentTA
				Or RowData.DepreciationInTaxAccountingUpdate <> 0) Then
			
			DepreciationUpdate = RowData.DepreciationInTaxAccountingUpdate - ParameterValues.DepreciationInTaxAccounting - ParameterValues.DepreciationForPeriodTA;
			DepreciationUpdate = Round(DepreciationUpdate, 2);
			
			ParameterValues.DepreciationInTaxAccounting = RowData.DepreciationInTaxAccountingUpdate;
			
			ParameterValues.DepreciationForPeriodTA = 0;
			ParameterValues.DepreciationInTaxAccountingUpdate = DepreciationUpdate;
			
		EndIf;
		
		If ThereIsPD
			And (RowData.ACDepreciationAdjustment
				Or RowData.DepreciationPermanentDifferencesUpdate <> 0) Then
			
			DepreciationUpdate = RowData.DepreciationPermanentDifferencesUpdate - ParameterValues.DepreciationPermanentDifferences - ParameterValues.DepreciationForPeriodOfPD;
			DepreciationUpdate = Round(DepreciationUpdate, 2);

			ParameterValues.DepreciationPermanentDifferences = RowData.DepreciationPermanentDifferencesUpdate;
			
			ParameterValues.DepreciationForPeriodOfPD = 0;
			ParameterValues.DepreciationPermanentDifferencesUpdate = DepreciationUpdate;
			
		EndIf;
		
	Else
		
		If ThereIsMA Then
			ParameterValues.Cost = ParameterValues.Cost + RowData.CostUpdate;
			ParameterValues.CostUpdate = RowData.CostUpdate;
		EndIf;
		
		If ThereIsAC Then
			ParameterValues.LocalCost = ParameterValues.LocalCost + RowData.LocalCostUpdate;
			ParameterValues.LocalCostUpdate = RowData.LocalCostUpdate;
		EndIf;
		
		If HasTA Then
			ParameterValues.CostInTaxAccounting = ParameterValues.CostInTaxAccounting + RowData.CostInTaxAccountingUpdate;
			ParameterValues.CostInTaxAccountingUpdate = RowData.CostInTaxAccountingUpdate;
		EndIf;
		
		If ThereIsPD Then
			ParameterValues.CostPermanentDifference = ParameterValues.CostPermanentDifference + RowData.CostPermanentDifferenceUpdate;
			ParameterValues.CostPermanentDifferenceUpdate = RowData.CostPermanentDifferenceUpdate;
		EndIf;
		
	EndIf; 
	
	Return ParameterValues;
	
EndFunction

#EndRegion
 
#Region DepreciationAdjustmentForPreviousPeriod

Procedure DepreciationAdjustmentForPreviousPeriod(CalculationParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FixedAssetsDepreciationCharge.CalculateDepreciation.DepreciationAdjustmentForPreviousPeriod");
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(CalculationParameters.TempTablesManager);
	TTUsed.Add("DepreciationAdjustmentForPreviousPeriod");
		
	#Region DescriptionOfDepreciationCalculationTable
	
	RegisterMetadata = Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge;

	DepreciationCalculation = New ValueTable();
	DepreciationCalculation.Columns.Add("Ref", New TypeDescription("DocumentRef.FixedAssetsInitialRecognition2_4,DocumentRef.FixedAssetsCostAdditions2_4,DocumentRef.AllocateVariancesToFixedAssetCost"));
	DepreciationCalculation.Columns.Add("Period", Common.DateTypeDetails(DateFractions.Date));
	DepreciationCalculation.Columns.Add("FixedAsset", RegisterMetadata.Dimensions.FixedAsset.Type);
	DepreciationCalculation.Columns.Add("AmountOfUU", RegisterMetadata.Resources.Depreciation.Type);
	DepreciationCalculation.Columns.Add("AmountAccounting", RegisterMetadata.Resources.DepreciationLocal.Type);
	DepreciationCalculation.Columns.Add("AmountFA", RegisterMetadata.Resources.DepreciationInTaxAccounting.Type);
	DepreciationCalculation.Columns.Add("AmountPermanentDifferences", RegisterMetadata.Resources.DepreciationPermanentDifferences.Type);
	DepreciationCalculation.Columns.Add("CFAmount", RegisterMetadata.Resources.FixedAssetDepreciationTargetFinancing.Type);
	DepreciationCalculation.Columns.Add("PRCFAmount", RegisterMetadata.Resources.DepreciationTargetFinancingPD.Type);
	DepreciationCalculation.Columns.Add("DepreciationMAChange", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
	DepreciationCalculation.Columns.Add("DepreciationACChange", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
	DepreciationCalculation.Columns.Add("DepreciationChangeTA", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
	DepreciationCalculation.Columns.Add("DepreciationPDChange", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
	DepreciationCalculation.Columns.Add("DepreciationTFChange", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
	DepreciationCalculation.Columns.Add("DepreciationChangeInPRTF", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
	DepreciationCalculation.Columns.Add("ResourceDevelopedOverPastPeriodMA", RegisterMetadata.Attributes.LifeSpentPastPeriod.Type);
	DepreciationCalculation.Columns.Add("LifeSpentPastPeriodAccounting", RegisterMetadata.Attributes.LifeSpentPastPeriodAccounting.Type);
	DepreciationCalculation.Columns.Add("ResourceDevelopedForCurPeriodMA", RegisterMetadata.Attributes.LifeSpentCurrentPeriod.Type);
	DepreciationCalculation.Columns.Add("LifeSpentCurrentPeriodAccounting", RegisterMetadata.Attributes.LifeSpentCurrentPeriodAccounting.Type);
	DepreciationCalculation.Columns.Add("CostUsedToCalculateDepreciationInManagementAccounting", RegisterMetadata.Attributes.CostUsedToCalculateDepreciationManag.Type);
	DepreciationCalculation.Columns.Add("CostUsedToCalculateDepreciationInAccounting", RegisterMetadata.Attributes.CostUsedToCalculateDepreciationLocal.Type);
	DepreciationCalculation.Columns.Add("ProcedureForCalculatingDepreciationOfMa", RegisterMetadata.Attributes.ProcedureForCalculatingDepreciationOfMa.Type);
	DepreciationCalculation.Columns.Add("ProcedureForCalculatingDepreciationAC", RegisterMetadata.Attributes.ProcedureForCalculatingDepreciationAC.Type);
	DepreciationCalculation.Columns.Add("DepreciationMethodVersionMA", RegisterMetadata.Attributes.DepreciationMethodVersionMA.Type);
	DepreciationCalculation.Columns.Add("DepreciationMethodVersionLA", RegisterMetadata.Attributes.DepreciationMethodVersionLA.Type);
	DepreciationCalculation.Columns.Add("AccountingProcedureMA", RegisterMetadata.Attributes.AccountingProcedureMA.Type);
	DepreciationCalculation.Columns.Add("AccountingProcedureAC", RegisterMetadata.Attributes.AccountingProcedureAC.Type);
	DepreciationCalculation.Columns.Add("ExpenseItem", RegisterMetadata.Attributes.CorExpenseItem.Type);
	DepreciationCalculation.Columns.Add("DimensionOfExpenses", RegisterMetadata.Attributes.CorExpenditureDimension.Type);
	DepreciationCalculation.Columns.Add("ExpensesBusinessUnit", RegisterMetadata.Attributes.DebitBusinessUnit.Type);
	DepreciationCalculation.Columns.Add("ExpenseLineOfBusiness", RegisterMetadata.Attributes.CorLineOfBusiness.Type);
	DepreciationCalculation.Columns.Add("TransferExpensesToAnotherCompany", New TypeDescription("Boolean"));
	DepreciationCalculation.Columns.Add("CompanyRecipientOfExpenses", RegisterMetadata.Dimensions.Organization.Type);
	DepreciationCalculation.Columns.Add("DepreciationRecordMethod", New TypeDescription("DocumentRef.ChangeFixedAssetFinancialDetails2_4"));
	DepreciationCalculation.Columns.Add("ThisIsMA", New TypeDescription("Boolean"));
	DepreciationCalculation.Columns.Add("ThisIsAC", New TypeDescription("Boolean"));
	DepreciationCalculation.Columns.Add("ThisIsTA", New TypeDescription("Boolean"));

	#EndRegion
		
	#Region PreparingParameters
	
	ListOfRequests = New Array;
	
	#Region FATable

	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.FixedAssetsLocation AS Department,
	|	BEGINOFPERIOD(DocumentData.DateOfRecognition, MONTH) AS BeginningOfAdditionalChargePeriod,
	|	ENDOFPERIOD(DATEADD(BEGINOFPERIOD(DocumentData.Date, MONTH), DAY, -1), MONTH) AS EndOfAdditionalChargePeriod,
	|	FALSE AS DepreciationAdjustmentForPeriod,
	|
	|	DocumentData.PostInAccounting 
	|		AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses) AS FillInBU,
	|
	|	DocumentData.RecordInTA 
	|		AND DocumentData.AccountingProcedureTA <> VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DoNotTakeIntoAccountIncludeInExpenses) AS FillInTA,
	|
	|	DocumentData.RecordInManAccounting 
	|		AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses) AS FillInUU,
	|
	|	FATable.LineNumber AS LineNumber,
	|	FATable.FixedAsset AS FixedAsset
	|
	|INTO FATable
	|
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|
	|		INNER JOIN Document.FixedAssetsInitialRecognition2_4.FA FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.DepreciationAdjustmentOption = VALUE(Enum.AdditionalDepreciationAccrualOptions.Automatically)
	|	AND DocumentData.AdjustmentModeFromPreviousDate
	|	AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.Posted
	|
	|	AND DocumentData.Organization IN (
	|			SELECT
	|				TTDataToBeCalculated.Organization
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|	AND FATable.FixedAsset IN (
	|			SELECT
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Department AS Department,
	|	BEGINOFPERIOD(DocumentData.RenovationDate, MONTH) AS BeginningOfAdditionalChargePeriod,
	|	ENDOFPERIOD(DocumentData.Date, MONTH) AS EndOfAdditionalChargePeriod,
	|	TRUE AS DepreciationAdjustmentForPeriod,
	|
	|	DocumentData.PostInAccounting AS FillInBU,
	|
	|	DocumentData.RecordInTA 
	|		AND DocumentData.AccountingProcedureTA <> VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DoNotTakeIntoAccountIncludeInExpenses) AS FillInTA,
	|
	|	DocumentData.RecordInManAccounting AS FillInUU,
	|
	|	FATable.LineNumber AS LineNumber,
	|	FATable.FixedAsset AS FixedAsset
	|
	|FROM
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|
	|		INNER JOIN Document.FixedAssetsCostAdditions2_4.FA FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.DepreciationAdjustmentOption = VALUE(Enum.AdditionalDepreciationAccrualOptions.Automatically)
	|	AND NOT DocumentData.WriteOffAppreciationCosts
	|	AND DocumentData.AdjustmentModeFromPreviousDate
	|	AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.Posted
	|
	|	AND DocumentData.Organization IN (
	|			SELECT
	|				TTDataToBeCalculated.Organization
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|	AND FATable.FixedAsset IN (
	|			SELECT
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Department AS Department,
	|
	|	CASE
	|		WHEN ISNULL(FixedAssetsInitialRecognition.AdjustmentModeFromPreviousDate, FALSE)
	|			THEN BEGINOFPERIOD(FixedAssetsInitialRecognition.DateOfRecognition, DAY)
	|
	|		WHEN ISNULL(FixedAssetsCostAdditions.AdjustmentModeFromPreviousDate, FALSE)
	|			THEN BEGINOFPERIOD(FixedAssetsCostAdditions.RenovationDate, DAY)
	|
	|		ELSE ISNULL(BEGINOFPERIOD(DocumentData.SourceDocument.Date, DAY), DATETIME(1,1,1)) 
	|	END AS BeginningOfAdditionalChargePeriod,
	|
	|	ENDOFPERIOD(DocumentData.Date, MONTH) AS EndOfAdditionalChargePeriod,
	|	TRUE AS DepreciationAdjustmentForPeriod,
	|
	|	DocumentData.PostInAccounting AS FillInBU,
	|
	|	DocumentData.RecordInTA 
	|		AND DocumentData.AccountingProcedureTA <> VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DoNotTakeIntoAccountIncludeInExpenses) AS FillInTA,
	|
	|	DocumentData.RecordInManAccounting AS FillInUU,
	|
	|	FATable.LineNumber AS LineNumber,
	|	FATable.FixedAsset AS FixedAsset
	|
	|FROM
	|	Document.AllocateVariancesToFixedAssetCost AS DocumentData
	|
	|		INNER JOIN Document.AllocateVariancesToFixedAssetCost.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS FixedAssetsInitialRecognition
	|		ON FixedAssetsInitialRecognition.Ref = DocumentData.SourceDocument
	|
	|		LEFT JOIN Document.FixedAssetsCostAdditions2_4 AS FixedAssetsCostAdditions
	|		ON FixedAssetsCostAdditions.Ref = DocumentData.SourceDocument
	|
	|WHERE
	|	DocumentData.DepreciationAdjustmentOption = VALUE(Enum.AdditionalDepreciationAccrualOptions.Automatically)
	|	AND NOT DocumentData.WriteOffVariancesAsExpenses
	|	AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.Posted
	|
	|	AND DocumentData.Organization IN (
	|			SELECT
	|				TTDataToBeCalculated.Organization
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|	AND FATable.FixedAsset IN (
	|			SELECT
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|INDEX BY
	|	Ref
	|";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
		
	#Region ListOfAccountingObjects_Adjustment
	
	QueryText =
	"SELECT DISTINCT
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.Organization AS Organization,
	|	FATable.ParentCompany AS ParentCompany,
	|
	|	CASE
	|		WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FATable.FixedAsset AND LeasedAsset.BegOfMonth = &BegOfMonth)
	|			THEN ISNULL(AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|		ELSE ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|	END = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|INTO ListOfAccountingObjects_Adjustment
	|
	|FROM
	|	FATable AS FATable
	|
	|		LEFT JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(&EndOfMonth) AS AccountingPolicy
	|		ON AccountingPolicy.Organization = FATable.ParentCompany
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 0
	|	UNDEFINED AS FixedAsset,
	|	UNDEFINED AS Organization
	|
	|INTO ListOfAccountingObjects_Adjusting_AdditionalCharges_All
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.FixedAsset AS FixedAsset
	|
	|INTO ListOfAccountingObjects_AdjustmentFromDateOfAcceptanceForAccounting
	|
	|FROM
	|	ListOfAccountingObjects_Adjustment AS ListOfFA
	|
	|WHERE
	|	ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|INDEX BY
	|	FixedAsset
	|";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region AccountingProcedure
	
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"FixedAssetsAccountingProcedure", "", "FixedAsset", ListOfRequests, "ListOfAccountingObjects_Adjustment");
		
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"FixedAssetsAccountingProcedureManagementAccounting", "", "FixedAsset", ListOfRequests, "ListOfAccountingObjects_Adjustment");
		
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"AccountingProcedureForOSBU", "", "FixedAsset", ListOfRequests, "ListOfAccountingObjects_Adjustment");
	
	QueryText =
	"SELECT 
	|	AccountingProcedureForOSBU.DepreciationRecordMethodLA AS Ref
	|
	|INTO AllWaysToReflectDepreciation
	|
	|FROM 
	|	AccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|
	|WHERE
	|	NOT AccountingProcedureForOSBU.DepreciationRecordMethodLA IN (&EmptyWaysToReflectDepreciation)
	|
	|UNION ALL
	|
	|SELECT 
	|	AccountingProcedureForOSBU.DepreciationRecordMethodTA AS Ref
	|
	|FROM 
	|	AccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|
	|WHERE
	|	NOT AccountingProcedureForOSBU.DepreciationRecordMethodTA IN (&EmptyWaysToReflectDepreciation)
	|
	|UNION ALL
	|
	|SELECT 
	|	FixedAssetsAccountingProcedureManagementAccounting.DepreciationRecordMethod AS Ref
	|
	|FROM 
	|	FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedureManagementAccounting
	|
	|WHERE
	|	NOT FixedAssetsAccountingProcedureManagementAccounting.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableDepreciation.Ref                               AS DepreciationRecordMethod,
	|	TableDepreciation.ExpenseItem                       AS ExpenseItem,
	|	TableDepreciation.DimensionOfExpenses                    AS DimensionOfExpenses,
	|	TableDepreciation.Department                        AS Department,
	|	TableDepreciation.LineOfBusiness              AS LineOfBusiness,
	|	TableDepreciation.BusinessUnitAndLineOfBusinessMatchAccountingData AS BusinessUnitAndLineOfBusinessMatchAccountingData,
	|	TableDepreciation.TransferExpensesToAnotherCompany  AS TransferExpensesToAnotherCompany,
	|	TableDepreciation.CompanyRecipientOfExpenses        AS CompanyRecipientOfExpenses,
	|	TableDepreciation.ZoomRatio                          AS Base,
	|	TableDepreciation.AmountOfPreviousRowsFactors    AS BaseAccumulated,
	|	TableDepreciation.Ref.DepreciationFactorAmount AS BaseAmount
	|
	|INTO WaysToReflectDepreciation
	|
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4.Depreciation AS TableDepreciation
	|
	|WHERE
	|	TableDepreciation.Ref IN (
	|		SELECT 
	|			AllWaysToReflectDepreciation.Ref 
	|		FROM 
	|			AllWaysToReflectDepreciation AS AllWaysToReflectDepreciation)
	|
	|INDEX BY
	|	DepreciationRecordMethod
	|";
	
	ListOfRequests.Add(QueryText);

	#EndRegion
	
	#Region TT_DepreciationForPeriod
	
	QueryText =
	"SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	MIN(BEGINOFPERIOD(FATable.BeginningOfAdditionalChargePeriod, MONTH)) AS BeginOfPeriod,
	|	MAX(BEGINOFPERIOD(FATable.Date, MONTH)) AS EndOfPeriod
	|
	|INTO TTIsAdjustmentPeriod
	|
	|FROM
	|	FATable AS FATable
	|
	|WHERE
	|	FATable.DepreciationAdjustmentForPeriod
	|
	|GROUP BY
	|	FATable.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepreciationForPeriod.EndOfMonth AS EndOfMonth,
	|	DepreciationForPeriod.FixedAsset AS FixedAsset,
	|
	|	SUM(DepreciationForPeriod.Depreciation) AS Depreciation,
	|	SUM(DepreciationForPeriod.DepreciationLocal) AS DepreciationLocal,
	|	SUM(DepreciationForPeriod.DepreciationInTaxAccounting) AS DepreciationInTaxAccounting,
	|	SUM(DepreciationForPeriod.DepreciationPermanentDifferences) AS DepreciationPermanentDifferences,
	|	SUM(DepreciationForPeriod.FixedAssetDepreciationTargetFinancing) AS FixedAssetDepreciationTargetFinancing,
	|	SUM(DepreciationForPeriod.DepreciationTargetFinancingPD) AS DepreciationTargetFinancingPD
	|
	|INTO TT_DepreciationForPeriod
	|
	|FROM
	|	(SELECT
	|		DepreciationOfVNA.FixedAsset AS FixedAsset,
	|
	|		CASE
	|			WHEN DepreciationOfVNA.AccrualPeriod <> DATETIME(1,1,1)
	|				THEN ENDOFPERIOD(DepreciationOfVNA.AccrualPeriod, MONTH) 
	|			ELSE ENDOFPERIOD(DepreciationOfVNA.Period, MONTH) 
	|		END AS EndOfMonth,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.Depreciation 
	|			ELSE -DepreciationOfVNA.Depreciation 
	|		END AS Depreciation,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.DepreciationLocal 
	|			ELSE -DepreciationOfVNA.DepreciationLocal 
	|		END AS DepreciationLocal,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.DepreciationInTaxAccounting 
	|			ELSE -DepreciationOfVNA.DepreciationInTaxAccounting 
	|		END AS DepreciationInTaxAccounting,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.DepreciationPermanentDifferences 
	|			ELSE -DepreciationOfVNA.DepreciationPermanentDifferences 
	|		END AS DepreciationPermanentDifferences,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.FixedAssetDepreciationTargetFinancing 
	|			ELSE -DepreciationOfVNA.FixedAssetDepreciationTargetFinancing 
	|		END AS FixedAssetDepreciationTargetFinancing,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.DepreciationTargetFinancingPD 
	|			ELSE -DepreciationOfVNA.DepreciationTargetFinancingPD 
	|		END AS DepreciationTargetFinancingPD
	|
	|	FROM
	|		TTIsAdjustmentPeriod AS TTIsAdjustmentPeriod
	|
	|			INNER JOIN AccumulationRegister.FixedAssetsDepreciationCharge AS DepreciationOfVNA
	|			ON DepreciationOfVNA.FixedAsset = TTIsAdjustmentPeriod.FixedAsset
	|				AND DepreciationOfVNA.Period >= TTIsAdjustmentPeriod.BeginOfPeriod
	|				AND DepreciationOfVNA.Period < TTIsAdjustmentPeriod.EndOfPeriod
	|				AND DepreciationOfVNA.Active
	|
	|			LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|			ON Adjusting.Ref = DepreciationOfVNA.Recorder
	|
	|		WHERE
	|			Adjusting.Ref IS NULL
	|				OR Adjusting.DocumentBasis = UNDEFINED
	|					AND NOT Adjusting.DocumentBasis REFS Document.MergeOfFixedAssets
	|					AND NOT Adjusting.DocumentBasis REFS Document.SplitFixedAssets
	|					AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsCostAdditions2_4
	|					AND NOT Adjusting.DocumentBasis REFS Document.AllocateVariancesToFixedAssetCost
	|					AND NOT Adjusting.DocumentBasis REFS Document.FARevaluation2_4
	|					AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsInitialRecognition2_4
	|
	|	) AS DepreciationForPeriod
	|
	|GROUP BY
	|	DepreciationForPeriod.FixedAsset,
	|	DepreciationForPeriod.EndOfMonth
	|
	|INDEX BY
	|	FixedAsset,
	|	EndOfMonth
	|";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion

	#Region Selection
	
	QueryText =
	"SELECT
	|	FATable.Ref AS Ref,
	|	FATable.Date AS Date,
	|	FATable.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.BeginningOfAdditionalChargePeriod AS BeginningOfAdditionalChargePeriod,
	|	FATable.EndOfAdditionalChargePeriod AS EndOfAdditionalChargePeriod,
	|	FATable.DepreciationAdjustmentForPeriod AS DepreciationAdjustmentForPeriod,
	|	FATable.FillInUU AS FillInUU,
	|	FATable.FillInBU AS FillInBU,
	|	FATable.FillInTA AS FillInTA,
	|	NOT TT_LeasedAsset.FixedAsset IS NULL AS TheseAreRentedFA,
	|	AccountingProcedureForOSBU.ExpenseItemAccounting AS ExpenseItemAccounting,
	|	AccountingProcedureForOSBU.ExpenseItemTaxAccounting AS ExpenseItemTaxAccounting,
	|	FixedAssetsAccountingProcedureManagementAccounting.ExpenseItem AS ExpenseItemManagementAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionTaxAccounting AS ExpensesDimensionTaxAccounting,
	|	FixedAssetsAccountingProcedureManagementAccounting.DimensionOfExpenses AS ExpensesDimensionManagementAccounting,
	|	AccountingProcedureForOSBU.DepartmentACC AS DepartmentACC,
	|	AccountingProcedureForOSBU.BusinessUnitTaxAccounting AS BusinessUnitTaxAccounting,
	|	FixedAssetsAccountingProcedureManagementAccounting.Department AS BusinessUnitManagementAccounting,
	|	AccountingProcedureForOSBU.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
	|	AccountingProcedureForOSBU.LineOfBusinessTaxAccounting AS LineOfBusinessTaxAccounting,
	|	FixedAssetsAccountingProcedureManagementAccounting.LineOfBusiness AS LineOfBusinessManagementAccounting,
	|	AccountingProcedureForOSBU.DepreciationRecordMethodLA AS DepreciationRecordMethodLA,
	|	AccountingProcedureForOSBU.DepreciationRecordMethodTA AS DepreciationRecordMethodTA,
	|	FixedAssetsAccountingProcedureManagementAccounting.DepreciationRecordMethod AS MethodOfReflectingDepreciationOfMA,
	|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompanyAC,
	|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompanyTA,
	|	FixedAssetsAccountingProcedureManagementAccounting.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherMaOrganization,
	|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses AS CompanyRecipientOfExpensesAC,
	|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses AS CompanyIsRecipientOfExpensesTA,
	|	FixedAssetsAccountingProcedureManagementAccounting.CompanyRecipientOfExpenses AS OrganizationRecipientOfMaExpenses
	|
	|FROM
	|	FATable AS FATable
	|
	|		LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Organization = FATable.Organization
	|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
	|			AND AccountingProcedureForOSBU.BegOfMonth = &BegOfMonth
	|			AND AccountingProcedureForOSBU.ParameterPeriod = &EndOfPreviousMonth
	|
	|		LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.Organization = FATable.Organization
	|			AND FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FATable.FixedAsset
	|			AND FixedAssetsAccountingProcedureManagementAccounting.BegOfMonth = &BegOfMonth
	|			AND FixedAssetsAccountingProcedureManagementAccounting.ParameterPeriod = &EndOfPreviousMonth
	|
	|		LEFT JOIN TT_LeasedAsset AS TT_LeasedAsset
	|		ON TT_LeasedAsset.FixedAsset = FATable.FixedAsset
	|			AND TT_LeasedAsset.BegOfMonth = &BegOfMonth
	|";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	
	Result = Query.Execute();
	FATable = Result.Unload();
	
	#EndRegion

	#Region CalculationOfDepreciationAccordingToDocuments
	
	//@skip-check query-in-loop
	For Each Selection In FATable Do
		
		#Region GettingCalculationParameters
		
		FALocalAccountingIsConductedIndependently = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(
			Selection.Organization, EndOfMonth(Selection.Date));
		
		Parameters = New Structure;
		Parameters.Insert("Ref", Documents.FixedAssetCostAndDepreciationAdjustment.EmptyRef());
		Parameters.Insert("Organization", Selection.Organization);
		Parameters.Insert("FixedAsset", Selection.FixedAsset);
		Parameters.Insert("Date", Selection.Date);
		Parameters.Insert("BeginOfPeriod", BegOfMonth(Selection.BeginningOfAdditionalChargePeriod));
		Parameters.Insert("EndOfPeriod", EndOfMonth(Selection.EndOfAdditionalChargePeriod));
		Parameters.Insert("EndOfMAPeriod", EndOfMonth(Selection.EndOfAdditionalChargePeriod));
		Parameters.Insert("EndOfACPeriod", EndOfMonth(Selection.EndOfAdditionalChargePeriod));
		Parameters.Insert("EndOfPeriodTA", EndOfMonth(Selection.EndOfAdditionalChargePeriod));
		Parameters.Insert("DepreciationAllowance", 0);
		Parameters.Insert("FillInUU", Selection.FillInUU);
		Parameters.Insert("FillInBU", Selection.FillInBU And FALocalAccountingIsConductedIndependently);
		Parameters.Insert("FillInTA", Selection.FillInTA);
		
		ParametersForCalculation = ParametersForCalculatingDepreciationAccordingToTable(Parameters);

		#EndRegion
		
		#Region DepreciationCalculation
		
		Parameters = New Structure;
		Parameters.Insert("Organization", Selection.Organization);
		Parameters.Insert("FixedAsset", Selection.FixedAsset);
		Parameters.Insert("TheseAreRentedFA", Selection.TheseAreRentedFA);
		
		If Selection.FillInUU Then
			Parameters.Insert("CommissioningDateMA", ParametersForCalculation.CommissioningDateMA);
			Parameters.Insert("CostAtBeginningOfYear", ParametersForCalculation.CostAtBeginningOfYear);
			Parameters.Insert("LocalCostAtBeginningOfYear", ParametersForCalculation.LocalCostAtBeginningOfYear);
			Parameters.Insert("DepreciationAsOfTheYearStart", ParametersForCalculation.DepreciationAsOfTheYearStart);
			Parameters.Insert("LocalDepreciationAsOfTheYearStart", ParametersForCalculation.LocalDepreciationAsOfTheYearStart);
			Parameters.Insert("DepreciationAsOfThePeriodStart", ParametersForCalculation.DepreciationAsOfThePeriodStart);
			Parameters.Insert("LocalDepreciationAtBeginningOfPeriod", ParametersForCalculation.LocalDepreciationAtBeginningOfPeriod);
		EndIf;
		
		If Selection.FillInBU And FALocalAccountingIsConductedIndependently Then
			Parameters.Insert("CommissioningDateAC", ParametersForCalculation.CommissioningDateAC);
			Parameters.Insert("LocalCostAtBeginningOfYear", ParametersForCalculation.LocalCostAtBeginningOfYear);
			Parameters.Insert("LocalDepreciationAsOfTheYearStart", ParametersForCalculation.LocalDepreciationAsOfTheYearStart);
			Parameters.Insert("LocalDepreciationAtBeginningOfPeriod", ParametersForCalculation.LocalDepreciationAtBeginningOfPeriod);
			Parameters.Insert("TargetFundsInDepreciation", ParametersForCalculation.TargetFundsInDepreciation);
			Parameters.Insert("PermanentDifferencesInDepreciation", ParametersForCalculation.PermanentDifferencesInDepreciation);
			Parameters.Insert("PermanentDifferencesOfTargetFundsInDepreciation", ParametersForCalculation.PermanentDifferencesOfTargetFundsInDepreciation);
		EndIf;
		
		If Selection.FillInTA Then
			Parameters.Insert("DepreciationInTaxAccountingBeginOfPeriod", ParametersForCalculation.DepreciationInTaxAccountingBeginOfPeriod);
			Parameters.Insert("CommissioningDateTA", ParametersForCalculation.CommissioningDateTA);
			Parameters.Insert("DepreciationInTaxAccountingBeginOfPeriod", ParametersForCalculation.DepreciationInTaxAccountingBeginOfPeriod);
			Parameters.Insert("DepreciationBefore2009", ParametersForCalculation.DepreciationBefore2009);
			Parameters.Insert("ActualUsefulLifeBefore2009", ParametersForCalculation.ActualUsefulLifeBefore2009);
		EndIf;

		CalculationTables = New Structure;
		
		If Selection.FillInUU Then
			CalculationTables.Insert("ParametersForMAPeriod", ParametersForCalculation.ParametersForMAPeriod.Copy());
			For LineNumber = 1 To CalculationTables.ParametersForMAPeriod.Count() Do
				CalculationTables.ParametersForMAPeriod[LineNumber-1].LineNumber = LineNumber;
			EndDo;
		EndIf;
		
		If Selection.FillInBU And FALocalAccountingIsConductedIndependently Then
			CalculationTables.Insert("FinancialDetailsForThePeriodAC", ParametersForCalculation.FinancialDetailsForThePeriodAC.Copy());
			For LineNumber = 1 To CalculationTables.FinancialDetailsForThePeriodAC.Count() Do
				CalculationTables.FinancialDetailsForThePeriodAC[LineNumber-1].LineNumber = LineNumber;
			EndDo;
		EndIf;
		
		If Selection.FillInTA Then
			CalculationTables.Insert("FinancialDetailsForThePeriodTA", ParametersForCalculation.FinancialDetailsForThePeriodTA.Copy());
			For LineNumber = 1 To CalculationTables.FinancialDetailsForThePeriodTA.Count() Do
				CalculationTables.FinancialDetailsForThePeriodTA[LineNumber-1].LineNumber = LineNumber;
			EndDo;
		EndIf;
		
		CalculationResult2 = CalculateDepreciationAccordingToTable(CalculationTables, Parameters);
		
		#EndRegion
		
		#Region AddingCalculationToTable
		
		If CalculationResult2.Property("MaCalculationResult") Then
			
			For Each RowData In CalculationResult2.MaCalculationResult Do
				
				NewRow = DepreciationCalculation.Add();
				FillPropertyValues(NewRow, RowData);
				
				NewRow.ThisIsMA = True;
				NewRow.AmountOfUU = RowData.Depreciation;
				NewRow.AmountAccounting = RowData.DepreciationLocal;
				NewRow.Ref = Selection.Ref;
				NewRow.FixedAsset = Selection.FixedAsset;
				
				NewRow.ExpenseItem = Selection.ExpenseItemManagementAccounting;
				NewRow.DimensionOfExpenses = Selection.ExpensesDimensionManagementAccounting;
				NewRow.ExpensesBusinessUnit = Selection.BusinessUnitManagementAccounting;
				NewRow.ExpenseLineOfBusiness = Selection.LineOfBusinessManagementAccounting;
				NewRow.TransferExpensesToAnotherCompany = Selection.TransferExpensesToAnotherMaOrganization;
				NewRow.CompanyRecipientOfExpenses = Selection.OrganizationRecipientOfMaExpenses;
				NewRow.DepreciationRecordMethod = Selection.MethodOfReflectingDepreciationOfMA;
				
				FinancialDetailsForThePeriod = CalculationTables.ParametersForMAPeriod.Find(RowData.LineNumber, "LineNumber");
				NewRow.DepreciationMAChange = FinancialDetailsForThePeriod.DepreciationUpdate;
				NewRow.DepreciationACChange = FinancialDetailsForThePeriod.DepreciationLocalUpdate;
				
				If Selection.DepreciationAdjustmentForPeriod
					And BegOfMonth(RowData.Period) < BegOfMonth(CalculationParameters.Period) Then
					
					NewRow.Period = EndOfMonth(NewRow.Period);
					
				Else
					
					NewRow.CostUsedToCalculateDepreciationInManagementAccounting = RowData.CostUsedToCalculateDepreciationManag;
					NewRow.CostUsedToCalculateDepreciationInAccounting = RowData.CostUsedToCalculateDepreciationLocal;
					NewRow.ResourceDevelopedForCurPeriodMA = RowData.LifeSpentCurrentPeriod;
					NewRow.ResourceDevelopedOverPastPeriodMA = RowData.LifeSpentPastPeriod;
					NewRow.ProcedureForCalculatingDepreciationOfMa = RowData.DepreciationProcedure;
					NewRow.AccountingProcedureMA = RowData.AccountingProcedure;
					NewRow.AccountingProcedureAC = RowData.AccountingProcedure;
					NewRow.DepreciationMethodVersionMA = RowData.VersionOfAccrualMethod;
					
				EndIf;
				
			EndDo;

		EndIf;

		If CalculationResult2.Property("ResultOfCalculationOfBU") Then
		
			For Each RowData In CalculationResult2.ResultOfCalculationOfBU Do
			
				NewRow = DepreciationCalculation.Add();
				FillPropertyValues(NewRow, RowData);
				
				NewRow.ThisIsAC = True;
				NewRow.AmountAccounting = RowData.DepreciationInAccounting;
				NewRow.AmountPermanentDifferences = RowData.DepreciationPermanentDifferences;
				NewRow.CFAmount = RowData.FixedAssetDepreciationTargetFinancing;
				NewRow.Ref = Selection.Ref;
				NewRow.FixedAsset = Selection.FixedAsset;
				
				NewRow.ExpenseItem = Selection.ExpenseItemAccounting;
				NewRow.DimensionOfExpenses = Selection.ExpensesDimensionAccounting;
				NewRow.ExpensesBusinessUnit = Selection.DepartmentACC;
				NewRow.ExpenseLineOfBusiness = Selection.LineOfBusinessBookkeeping;
				NewRow.TransferExpensesToAnotherCompany = Selection.TransferExpensesToAnotherCompanyAC;
				NewRow.CompanyRecipientOfExpenses = Selection.CompanyRecipientOfExpensesAC;
				NewRow.DepreciationRecordMethod = Selection.DepreciationRecordMethodLA;
				
				FinancialDetailsForThePeriod = CalculationTables.FinancialDetailsForThePeriodAC.Find(RowData.LineNumber, "LineNumber");
				NewRow.DepreciationACChange = FinancialDetailsForThePeriod.DepreciationLocalUpdate;
				NewRow.DepreciationPDChange = FinancialDetailsForThePeriod.DepreciationPermanentDifferencesUpdate;
				NewRow.DepreciationTFChange = FinancialDetailsForThePeriod.FixedAssetDepreciationTargetFinancingUpdate;
				NewRow.DepreciationChangeInPRTF = FinancialDetailsForThePeriod.DepreciationTargetFinancingPDUpdate;

				If Selection.DepreciationAdjustmentForPeriod
					And BegOfMonth(RowData.Period) < BegOfMonth(CalculationParameters.Period) Then
					
					NewRow.Period = EndOfMonth(NewRow.Period);
					
				Else
					
					NewRow.CostUsedToCalculateDepreciationInAccounting = RowData.CostUsedToCalculateDepreciationLocal;
					NewRow.LifeSpentCurrentPeriodAccounting = RowData.LifeSpentCurrentPeriod;
					NewRow.LifeSpentPastPeriodAccounting = RowData.LifeSpentPastPeriod;
					NewRow.ProcedureForCalculatingDepreciationAC = RowData.DepreciationProcedure;
					NewRow.AccountingProcedureAC = RowData.AccountingProcedure;
					NewRow.DepreciationMethodVersionLA = RowData.VersionOfAccrualMethod;
					
				EndIf;
				
			EndDo;
		
		EndIf;
		
		If CalculationResult2.Property("ResultOfCalculationIsTA") Then

			For Each RowData In CalculationResult2.ResultOfCalculationIsTA Do
				
				NewRow = DepreciationCalculation.Add();
				FillPropertyValues(NewRow, RowData);
				
				NewRow.ThisIsTA = True;
				NewRow.AmountFA = RowData.DepreciationInTaxAccounting;
				NewRow.Ref = Selection.Ref;
				NewRow.FixedAsset = Selection.FixedAsset;
				
				NewRow.ExpenseItem = Selection.ExpenseItemTaxAccounting;
				NewRow.DimensionOfExpenses = Selection.ExpensesDimensionTaxAccounting;
				NewRow.ExpensesBusinessUnit = Selection.BusinessUnitTaxAccounting;
				NewRow.ExpenseLineOfBusiness = Selection.LineOfBusinessTaxAccounting;
				NewRow.TransferExpensesToAnotherCompany = Selection.TransferExpensesToAnotherCompanyTA;
				NewRow.CompanyRecipientOfExpenses = Selection.CompanyIsRecipientOfExpensesTA;
				NewRow.DepreciationRecordMethod = Selection.DepreciationRecordMethodTA;
				
				FinancialDetailsForThePeriod = CalculationTables.FinancialDetailsForThePeriodTA.Find(RowData.LineNumber, "LineNumber");
				NewRow.DepreciationChangeTA = FinancialDetailsForThePeriod.DepreciationInTaxAccountingUpdate;

				If Selection.DepreciationAdjustmentForPeriod Then
					
					NewRow.Period = EndOfMonth(NewRow.Period);
					
				EndIf;
				
			EndDo;
		
		EndIf;
		
		#EndRegion
		
	EndDo;

	#EndRegion
	
	#Region FormationOfDepreciationAdjustmentTableForPreviousPeriod
	
	QueryText = 
	"SELECT
	|	DepreciationCalculation.Ref AS Ref,
	|	DepreciationCalculation.Period AS Period,
	|	DepreciationCalculation.FixedAsset AS FixedAsset,
	|	DepreciationCalculation.ResourceDevelopedOverPastPeriodMA AS ResourceDevelopedOverPastPeriodMA,
	|	DepreciationCalculation.ResourceDevelopedForCurPeriodMA AS ResourceDevelopedForCurPeriodMA,
	|	DepreciationCalculation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|	DepreciationCalculation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationInManagementAccounting AS CostUsedToCalculateDepreciationInManagementAccounting,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationInAccounting AS CostUsedToCalculateDepreciationInAccounting,
	|	DepreciationCalculation.AccountingProcedureMA AS AccountingProcedureMA,
	|	DepreciationCalculation.AccountingProcedureAC AS AccountingProcedureAC,
	|	DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	DepreciationCalculation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	DepreciationCalculation.DepreciationMethodVersionMA AS DepreciationMethodVersionMA,
	|	DepreciationCalculation.DepreciationMethodVersionLA AS DepreciationMethodVersionLA,
	|	DepreciationCalculation.ThisIsMA AS ThisIsMA,
	|	DepreciationCalculation.ThisIsAC AS ThisIsAC,
	|	DepreciationCalculation.ThisIsTA AS ThisIsTA,
	|
	|	DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|	DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|	DepreciationCalculation.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	DepreciationCalculation.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	DepreciationCalculation.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	DepreciationCalculation.AmountOfUU AS AmountOfUU,
	|	DepreciationCalculation.AmountAccounting AS AmountAccounting,
	|	DepreciationCalculation.AmountFA AS AmountFA,
	|	DepreciationCalculation.AmountPermanentDifferences AS AmountPermanentDifferences,
	|	DepreciationCalculation.CFAmount AS CFAmount,
	|	DepreciationCalculation.PRCFAmount AS PRCFAmount,
	|
	|	DepreciationCalculation.DepreciationMAChange AS DepreciationMAChange,
	|	DepreciationCalculation.DepreciationACChange AS DepreciationACChange,
	|	DepreciationCalculation.DepreciationChangeTA AS DepreciationChangeTA,
	|	DepreciationCalculation.DepreciationPDChange AS DepreciationPDChange,
	|	DepreciationCalculation.DepreciationTFChange AS DepreciationTFChange,
	|	DepreciationCalculation.DepreciationChangeInPRTF AS DepreciationChangeInPRTF
	|
	|INTO DepreciationCalculationTable
	|
	|FROM
	|	&DepreciationCalculation AS DepreciationCalculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepreciationCalculation.Ref AS Ref,
	|	DepreciationCalculation.Period AS Period,
	|	ENDOFPERIOD(DepreciationCalculation.Period, MONTH) AS EndOfMonth,
	|	DepreciationCalculation.FixedAsset AS FixedAsset,
	|
	|	DepreciationCalculation.ThisIsMA AS ThisIsMA,
	|	DepreciationCalculation.ThisIsAC AS ThisIsAC,
	|	DepreciationCalculation.ThisIsTA AS ThisIsTA,
	|
	|	DepreciationCalculation.ResourceDevelopedOverPastPeriodMA AS ResourceDevelopedOverPastPeriodMA,
	|	DepreciationCalculation.ResourceDevelopedForCurPeriodMA AS ResourceDevelopedForCurPeriodMA,
	|	DepreciationCalculation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|	DepreciationCalculation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationInManagementAccounting AS CostUsedToCalculateDepreciationInManagementAccounting,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationInAccounting AS CostUsedToCalculateDepreciationInAccounting,
	|
	|	MAX(DepreciationCalculation.AccountingProcedureMA) AS AccountingProcedureMA,
	|	MAX(DepreciationCalculation.AccountingProcedureAC) AS AccountingProcedureAC,
	|	MAX(DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa) AS ProcedureForCalculatingDepreciationOfMa,
	|	MAX(DepreciationCalculation.ProcedureForCalculatingDepreciationAC) AS ProcedureForCalculatingDepreciationAC,
	|	MAX(DepreciationCalculation.DepreciationMethodVersionMA) AS DepreciationMethodVersionMA,
	|	MAX(DepreciationCalculation.DepreciationMethodVersionLA) AS DepreciationMethodVersionLA,
	|
	|	MAX(DepreciationCalculation.ExpenseItem) AS ExpenseItem,
	|	MAX(DepreciationCalculation.DimensionOfExpenses) AS DimensionOfExpenses,
	|	MAX(DepreciationCalculation.ExpensesBusinessUnit) AS ExpensesBusinessUnit,
	|	MAX(DepreciationCalculation.ExpenseLineOfBusiness) AS ExpenseLineOfBusiness,
	|	MAX(DepreciationCalculation.TransferExpensesToAnotherCompany) AS TransferExpensesToAnotherCompany,
	|	MAX(DepreciationCalculation.CompanyRecipientOfExpenses) AS CompanyRecipientOfExpenses,
	|	MAX(DepreciationCalculation.DepreciationRecordMethod) AS DepreciationRecordMethod,
	|
	|	SUM(DepreciationCalculation.AmountOfUU) AS AmountOfUU,
	|	SUM(DepreciationCalculation.AmountAccounting) AS AmountAccounting,
	|	SUM(DepreciationCalculation.AmountFA) AS AmountFA,
	|	SUM(DepreciationCalculation.AmountPermanentDifferences) AS AmountPermanentDifferences,
	|	SUM(DepreciationCalculation.CFAmount) AS CFAmount,
	|	SUM(DepreciationCalculation.PRCFAmount) AS PRCFAmount,
	|
	|	SUM(DepreciationCalculation.DepreciationMAChange) AS DepreciationMAChange,
	|	SUM(DepreciationCalculation.DepreciationACChange) AS DepreciationACChange,
	|	SUM(DepreciationCalculation.DepreciationChangeTA) AS DepreciationChangeTA,
	|	SUM(DepreciationCalculation.DepreciationPDChange) AS DepreciationPDChange,
	|	SUM(DepreciationCalculation.DepreciationTFChange) AS DepreciationTFChange,
	|	SUM(DepreciationCalculation.DepreciationChangeInPRTF) AS DepreciationChangeInPRTF
	|
	|INTO DepreciationCalculation
	|
	|FROM
	|	DepreciationCalculationTable AS DepreciationCalculation
	|
	|GROUP BY
	|	DepreciationCalculation.Ref,
	|	DepreciationCalculation.Period,
	|	ENDOFPERIOD(DepreciationCalculation.Period, MONTH),
	|	DepreciationCalculation.FixedAsset,
	|	DepreciationCalculation.ThisIsMA,
	|	DepreciationCalculation.ThisIsAC,
	|	DepreciationCalculation.ThisIsTA,
	|	DepreciationCalculation.ResourceDevelopedOverPastPeriodMA,
	|	DepreciationCalculation.ResourceDevelopedForCurPeriodMA,
	|	DepreciationCalculation.LifeSpentPastPeriodAccounting,
	|	DepreciationCalculation.LifeSpentCurrentPeriodAccounting,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationInManagementAccounting,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationInAccounting
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&EndOfMonth AS CalculationPeriod,
	|	DepreciationCalculation.AccrualPeriod AS AccrualPeriod,
	|	DepreciationCalculation.Ref AS Ref,
	|
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.FixedAsset AS FixedAsset,
	|	DepreciationCalculation.Department AS Department,
	|	DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|
	|	DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|	DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|	DepreciationCalculation.DebitBusinessUnit AS DebitBusinessUnit,
	|	DepreciationCalculation.CorLineOfBusiness AS CorLineOfBusiness,
	|
	|	DepreciationCalculation.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|
	|	DepreciationCalculation.ResourceDevelopedOverPastPeriodMA AS ResourceDevelopedOverPastPeriodMA,
	|	DepreciationCalculation.ResourceDevelopedForCurPeriodMA AS ResourceDevelopedForCurPeriodMA,
	|	DepreciationCalculation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|	DepreciationCalculation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	DepreciationCalculation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	DepreciationCalculation.AccountingProcedureMA AS AccountingProcedureMA,
	|	DepreciationCalculation.AccountingProcedureAC AS AccountingProcedureAC,
	|	DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	DepreciationCalculation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	DepreciationCalculation.DepreciationMethodVersionMA AS DepreciationMethodVersionMA,
	|	DepreciationCalculation.DepreciationMethodVersionLA AS DepreciationMethodVersionLA,
	|	DepreciationCalculation.ThisIsRecordingOfDifference AS ThisIsRecordingOfDifference,
	|
	|	CASE
	|		WHEN NOT DepreciationCalculation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfSumOfMa
	|		ELSE DepreciationCalculation.AmountOfUU
	|	END AS AmountOfUU,
	|
	|	CASE
	|		WHEN NOT DepreciationCalculation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfACAmount
	|		ELSE DepreciationCalculation.AmountAccounting
	|	END AS AmountAccounting,
	|
	|	CASE
	|		WHEN NOT DepreciationCalculation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfSumTA
	|		ELSE DepreciationCalculation.AmountFA
	|	END AS AmountFA,
	|
	|	CASE
	|		WHEN NOT DepreciationCalculation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfPDAmount
	|		ELSE DepreciationCalculation.AmountPermanentDifferences
	|	END AS AmountPermanentDifferences,
	|
	|	CASE
	|		WHEN NOT DepreciationCalculation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfTFAmount
	|		ELSE DepreciationCalculation.CFAmount
	|	END AS CFAmount,
	|
	|	CASE
	|		WHEN NOT DepreciationCalculation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfPRTFAmount
	|		ELSE DepreciationCalculation.PRCFAmount
	|	END AS PRCFAmount
	|
	|INTO DepreciationAdjustmentForPreviousPeriod
	|
	|FROM
	|	(SELECT
	|		DepreciationCalculation.Ref AS Ref,
	|		DepreciationCalculation.Period AS AccrualPeriod,
	|
	|		FATable.Organization AS Organization,
	|		FATable.FixedAsset AS FixedAsset,
	|		FATable.Department AS Department,
	|		FixedAssetsAccountingProcedure.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		FixedAssetsAccountingProcedure.LineOfBusiness AS LineOfBusiness,
	|
	|		DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|		DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|		CASE
	|			WHEN DepreciationCalculation.ExpensesBusinessUnit <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|				THEN DepreciationCalculation.ExpensesBusinessUnit 
	|			ELSE FATable.Department
	|		END AS DebitBusinessUnit,
	|
	|		CASE
	|			WHEN DepreciationCalculation.ExpensesBusinessUnit <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|				THEN DepreciationCalculation.ExpenseLineOfBusiness 
	|			ELSE FixedAssetsAccountingProcedure.LineOfBusiness
	|		END AS CorLineOfBusiness,
	|
	|		DepreciationCalculation.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|
	|		DepreciationCalculation.ResourceDevelopedOverPastPeriodMA AS ResourceDevelopedOverPastPeriodMA,
	|		DepreciationCalculation.ResourceDevelopedForCurPeriodMA AS ResourceDevelopedForCurPeriodMA,
	|		DepreciationCalculation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|		DepreciationCalculation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|		DepreciationCalculation.CostUsedToCalculateDepreciationInManagementAccounting AS CostUsedToCalculateDepreciationManag,
	|		DepreciationCalculation.CostUsedToCalculateDepreciationInAccounting AS CostUsedToCalculateDepreciationLocal,
	|		DepreciationCalculation.AccountingProcedureMA AS AccountingProcedureMA,
	|		DepreciationCalculation.AccountingProcedureAC AS AccountingProcedureAC,
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		DepreciationCalculation.DepreciationMethodVersionMA AS DepreciationMethodVersionMA,
	|		DepreciationCalculation.DepreciationMethodVersionLA AS DepreciationMethodVersionLA,
	|
	|		CASE
	|			WHEN ENDOFPERIOD(DepreciationCalculation.Period, MONTH) = &EndOfMonth
	|				THEN FALSE
	|			ELSE FATable.DepreciationAdjustmentForPeriod 
	|		END AS ThisIsRecordingOfDifference,
	|
	|		CASE
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|					AND NOT DepreciationCalculation.ThisIsMA
	|				THEN 0
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|					AND ENDOFPERIOD(DepreciationCalculation.Period, MONTH) <> &EndOfMonth
	|				THEN DepreciationCalculation.AmountOfUU + DepreciationCalculation.DepreciationMAChange - ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)
	|			ELSE DepreciationCalculation.AmountOfUU
	|		END AS AmountOfUU,
	|
	|		CASE
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|					AND NOT DepreciationCalculation.ThisIsAC
	|				THEN 0
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|					AND ENDOFPERIOD(DepreciationCalculation.Period, MONTH) <> &EndOfMonth
	|				THEN DepreciationCalculation.AmountAccounting + DepreciationCalculation.DepreciationACChange - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|			ELSE DepreciationCalculation.AmountAccounting
	|		END AS AmountAccounting,
	|
	|		CASE
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|					AND NOT DepreciationCalculation.ThisIsTA
	|				THEN 0
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|					AND ENDOFPERIOD(DepreciationCalculation.Period, MONTH) <> &EndOfMonth
	|				THEN DepreciationCalculation.AmountFA + DepreciationCalculation.DepreciationChangeTA - ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0)
	|			ELSE DepreciationCalculation.AmountFA
	|		END AS AmountFA,
	|
	|		CASE
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|					AND NOT DepreciationCalculation.ThisIsAC
	|				THEN 0
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|				THEN DepreciationCalculation.AmountPermanentDifferences + DepreciationCalculation.DepreciationPDChange - ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0)
	|			ELSE DepreciationCalculation.AmountPermanentDifferences
	|		END AS AmountPermanentDifferences,
	|
	|		CASE
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|					AND NOT DepreciationCalculation.ThisIsAC
	|				THEN 0
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|				THEN DepreciationCalculation.CFAmount + DepreciationCalculation.DepreciationTFChange - ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)
	|			ELSE DepreciationCalculation.CFAmount
	|		END AS CFAmount,
	|
	|		CASE
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|					AND NOT DepreciationCalculation.ThisIsAC
	|				THEN 0
	|			WHEN FATable.DepreciationAdjustmentForPeriod
	|					AND ENDOFPERIOD(DepreciationCalculation.Period, MONTH) <> &EndOfMonth
	|				THEN DepreciationCalculation.PRCFAmount + DepreciationCalculation.DepreciationChangeInPRTF - ISNULL(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD, 0)
	|			ELSE DepreciationCalculation.PRCFAmount
	|		END AS PRCFAmount
	|
	|	FROM
	|		DepreciationCalculation AS DepreciationCalculation
	|
	|			INNER JOIN FATable AS FATable
	|			ON FATable.Ref = DepreciationCalculation.Ref
	|				AND FATable.FixedAsset = DepreciationCalculation.FixedAsset
	|
	|			LEFT JOIN TT_DepreciationForPeriod AS FixedAssetsDepreciationCharge
	|			ON FixedAssetsDepreciationCharge.FixedAsset = DepreciationCalculation.FixedAsset
	|				AND FixedAssetsDepreciationCharge.EndOfMonth = DepreciationCalculation.EndOfMonth
	|				AND ENDOFPERIOD(DepreciationCalculation.Period, MONTH) <> &EndOfMonth
	|				AND FATable.DepreciationAdjustmentForPeriod
	|
	|			LEFT JOIN FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure
	|			ON FixedAssetsAccountingProcedure.FixedAsset = DepreciationCalculation.FixedAsset
	|				AND FixedAssetsAccountingProcedure.BegOfMonth = &BegOfMonth
	|				AND FixedAssetsAccountingProcedure.ParameterPeriod = &EndOfPreviousMonth
	|
	|	) AS DepreciationCalculation
	|
	|		LEFT JOIN WaysToReflectDepreciation AS WaysToReflectDepreciation
	|		ON WaysToReflectDepreciation.DepreciationRecordMethod = DepreciationCalculation.DepreciationRecordMethod
	|
	|WHERE
	|	(DepreciationCalculation.AmountOfUU <> 0
	|		OR DepreciationCalculation.AmountAccounting <> 0
	|		OR DepreciationCalculation.AmountFA <> 0
	|		OR DepreciationCalculation.AmountPermanentDifferences <> 0
	|		OR DepreciationCalculation.CFAmount <> 0
	|		OR DepreciationCalculation.PRCFAmount <> 0)
	|";
	
	QueryText = StrReplace(QueryText, "&DistributionOfSumOfMa", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("DepreciationCalculation.AmountOfUU"));
	QueryText = StrReplace(QueryText, "&DistributionOfACAmount", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("DepreciationCalculation.AmountAccounting"));
	QueryText = StrReplace(QueryText, "&DistributionOfSumTA", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("DepreciationCalculation.AmountFA"));
	QueryText = StrReplace(QueryText, "&DistributionOfTFAmount", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("DepreciationCalculation.CFAmount"));
	QueryText = StrReplace(QueryText, "&DistributionOfPRTFAmount", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("DepreciationCalculation.PRCFAmount"));
	QueryText = StrReplace(QueryText, "&DistributionOfPDAmount", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("DepreciationCalculation.AmountPermanentDifferences"));
	
	Query.Text = QueryText;
	Query.SetParameter("DepreciationCalculation", DepreciationCalculation);
	
	Query.Execute();
	
	#EndRegion
	
	TMCommonUse.DestroyTemporaryTables(CalculationParameters.TempTablesManager,, TTUsed);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DepreciationCalculation.Count());
	
EndProcedure

#EndRegion

#Region QueryTextsForCalculatingDepreciation

Procedure QueryTextTTDataToBeCalculated(ListOfRequests)

	QueryText = 
	"SELECT
	|	DepreciationPackages.Organization AS Organization,
	|	DepreciationPackages.PackageNumber AS PackageNumber
	|
	|INTO PackagesNumbers
	|
	|FROM
	|	&DepreciationPackages AS DepreciationPackages
	|
	|INDEX BY
	|	PackageNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepreciationPackages.Organization AS Organization,
	|	DepreciationPackages.FixedAsset AS AccountingObject
	|
	|INTO ObjectsOfDepreciationPackages
	|
	|FROM
	|	InformationRegister.FixedAssetDepreciationPackages AS DepreciationPackages
	|
	|WHERE
	|	(DepreciationPackages.Organization, DepreciationPackages.PackageNumber) IN 
	|		(SELECT
	|			PackagesNumbers.Organization,
	|			PackagesNumbers.PackageNumber
	|		FROM
	|			PackagesNumbers AS PackagesNumbers)
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataForCalculation.Organization AS Organization,
	|	CAST(DataForCalculation.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
	|	DataForCalculation.AccountingObject AS AccountingObject
	|
	|INTO TTDataToBeCalculated
	|
	|FROM
	|	(SELECT
	|		ObjectsOfDepreciationPackages.Organization AS Organization,
	|		ObjectsOfDepreciationPackages.AccountingObject AS AccountingObject
	|	FROM
	|		ObjectsOfDepreciationPackages
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Organization AS Organization,
	|		DocumentData.FixedAsset AS AccountingObject
	|	FROM
	|		Document.SplitFixedAssets AS DocumentData
	|
	|			INNER JOIN Document.SplitFixedAssets.FA AS FATable
	|			ON (FATable.Ref = DocumentData.Ref)
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BeginningOfPreviousMonth AND &EndOfMonth
	|		AND DocumentData.Posted
	|
	|		AND FATable.FixedAsset IN
	|				(SELECT
	|					ObjectsOfDepreciationPackages.AccountingObject
	|				FROM
	|					ObjectsOfDepreciationPackages AS ObjectsOfDepreciationPackages)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Organization,
	|		FATable.FixedAsset
	|	FROM
	|		Document.MergeOfFixedAssets AS DocumentData
	|
	|			INNER JOIN Document.MergeOfFixedAssets.FA AS FATable
	|			ON (FATable.Ref = DocumentData.Ref)
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BeginningOfPreviousMonth AND &EndOfMonth
	|		AND DocumentData.Posted
	|
	|		AND DocumentData.FixedAsset IN
	|				(SELECT
	|					ObjectsOfDepreciationPackages.AccountingObject
	|				FROM
	|					ObjectsOfDepreciationPackages AS ObjectsOfDepreciationPackages)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Organization,
	|		FATable.FixedAsset
	|	FROM
	|		Document.FATransfer2_4 AS DocumentData
	|
	|			INNER JOIN Document.FATransfer2_4.FA AS FATable
	|			ON (FATable.Ref = DocumentData.Ref)
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BeginningOfPreviousMonth AND &EndOfMonth
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|		AND DocumentData.Posted
	|
	|		AND (DocumentData.CompanyRecipient, FATable.FixedAsset) IN
	|				(SELECT
	|					ObjectsOfDepreciationPackages.Organization,
	|					ObjectsOfDepreciationPackages.AccountingObject
	|				FROM
	|					ObjectsOfDepreciationPackages AS ObjectsOfDepreciationPackages)
	|
	|	) AS DataForCalculation
	|
	|INDEX BY
	|	AccountingObject,
	|	Organization
	|";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextListOfAccountingObjects(ListOfRequests, CalculationParameters)

	QueryText = FixedAssetsDepreciationChargeLocalization.QueryTextListOfAccountingObjects(CalculationParameters);
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT DISTINCT
		|	ListOfFA.BegOfMonth                        AS BegOfMonth,
		|	ListOfFA.EndOfMonth                         AS EndOfMonth,
		|	ListOfFA.Organization                         AS Organization,
		|	ListOfFA.FixedAsset                    AS FixedAsset,
		|	ISNULL(FixedAssetDepreciationPackages.PackageNumber, 0) AS PackageNumber,
		|
		|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
		|	ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting,
		|
		|	TRUE AS DepreciationIsCalculatedAccordingToINTStandards,
		|	TRUE AS DepreciationIsCalculatedAccordingToMU_UUStandards
		|
		|INTO ListOfAccountingObjects
		|
		|FROM
		|	ListOfAccountingObjects_ AS ListOfFA
		|
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS FixedAssetDepreciationPackages
		|		ON FixedAssetDepreciationPackages.Organization = ListOfFA.Organization
		|			AND FixedAssetDepreciationPackages.FixedAsset = ListOfFA.FixedAsset
		|
		|UNION
		|
		|SELECT DISTINCT
		|	ListOfFA.BegOfMonth                        AS BegOfMonth,
		|	ListOfFA.EndOfMonth                         AS EndOfMonth,
		|	ListOfFA.Organization                         AS Organization,
		|	ListOfFA.FixedAsset                    AS FixedAsset,
		|	ISNULL(FixedAssetDepreciationPackages.PackageNumber, 0) AS PackageNumber,
		|
		|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
		|	ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting,
		|
		|	TRUE AS DepreciationIsCalculatedAccordingToINTStandards,
		|	TRUE AS DepreciationIsCalculatedAccordingToMU_UUStandards
		|
		|FROM
		|	ListOfAccountingObjects_BU_MU AS ListOfFA
		|
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS FixedAssetDepreciationPackages
		|		ON FixedAssetDepreciationPackages.Organization = ListOfFA.Organization
		|			AND FixedAssetDepreciationPackages.FixedAsset = ListOfFA.FixedAsset
		|
		|INDEX BY
		|	FixedAsset,
		|	Organization";
		
	EndIf; 
	
	ListOfRequests.Add(QueryText);
	
	QueryText =
	"SELECT DISTINCT
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.FixedAsset AS FixedAsset
	|
	|INTO ListOfAccountingItemsFromDateOfAcceptanceForAccounting
	|
	|FROM
	|	ListOfAccountingObjects AS ListOfFA
	|
	|WHERE
	|	ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization";

	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextListOfAllFA(ListOfRequests, CalculationParameters)

	#Region TT_LeasedAsset
	QueryText = 
	"SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	RegisterTable.FixedAsset AS FixedAsset
	|
	|INTO TT_LeasedAsset
	|
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(
	|		&EndOfPreviousMonth,
	|		FixedAsset IN
	|			(SELECT
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)) AS RegisterTable
	|WHERE
	|	RegisterTable.State = VALUE(Enum.FixedAssetsStates.InLease)
	|
	|UNION ALL
	|
	|SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	RegisterTable.FixedAsset AS FixedAsset
	|FROM
	|	InformationRegister.LeasedAsset AS RegisterTable
	|
	|WHERE
	|	RegisterTable.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND RegisterTable.Active
	|
	|	AND VALUETYPE(RegisterTable.Recorder) IN (&TypeAcceptanceForAccounting)
	|	AND RegisterTable.State = VALUE(Enum.FixedAssetsStates.InLease)
	|
	|	AND RegisterTable.FixedAsset IN
	|			(SELECT
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	RegisterTable.FixedAsset AS FixedAsset
	|
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(
	|		&EndOfMonthBeforeLast,
	|		FixedAsset IN
	|			(SELECT
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)) AS RegisterTable
	|WHERE
	|	RegisterTable.State = VALUE(Enum.FixedAssetsStates.InLease)
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	RegisterTable.FixedAsset AS FixedAsset
	|FROM
	|	InformationRegister.LeasedAsset AS RegisterTable
	|
	|WHERE
	|	RegisterTable.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterTable.Active
	|
	|	AND VALUETYPE(RegisterTable.Recorder) IN (&TypeAcceptanceForAccounting)
	|	AND RegisterTable.State = VALUE(Enum.FixedAssetsStates.InLease)
	|
	|	AND RegisterTable.FixedAsset IN
	|			(SELECT
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|INDEX BY
	|	FixedAsset,
	|	BegOfMonth";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ObjectsThatDoNotNeedToBeDepreciated
	QueryText = 
	"SELECT
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	ObjectsTable.FixedAsset AS AccountingObject
	|
	|INTO ObjectsThatDoNotNeedToBeDepreciated
	|
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|	
	|		INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS ObjectsTable
	|		ON ObjectsTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.IncludesDepreciationOfCurrentMonth
	|	AND DocumentData.Posted
	|
	|	AND ObjectsTable.FixedAsset IN
	|				(SELECT
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	ObjectsTable.FixedAsset AS AccountingObject
	|
	|FROM
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|	
	|		INNER JOIN Document.FixedAssetsCostAdditions2_4.FA AS ObjectsTable
	|		ON ObjectsTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.DepreciationAdjustmentOption = VALUE(Enum.AdditionalDepreciationAccrualOptions.Automatically)
	|	AND DocumentData.Posted
	|
	|	AND ObjectsTable.FixedAsset IN
	|				(SELECT
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	ObjectsTable.FixedAsset AS AccountingObject
	|
	|FROM
	|	Document.AllocateVariancesToFixedAssetCost AS DocumentData
	|	
	|		INNER JOIN Document.AllocateVariancesToFixedAssetCost.FA AS ObjectsTable
	|		ON ObjectsTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.DepreciationAdjustmentOption = VALUE(Enum.AdditionalDepreciationAccrualOptions.Automatically)
	|	AND DocumentData.Posted
	|
	|	AND ObjectsTable.FixedAsset IN
	|				(SELECT
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|INDEX BY
	|	AccountingObject
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region FinancialAccountingPolicy
	
	QueryText =
	"SELECT
	|	&EndOfPreviousMonth AS Period,
	|	AccountingPolicy.Organization AS Organization,
	|	AccountingPolicy.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	AccountingPolicy.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge AS ProcedureOfFixedAssetDepreciationCharge,
	|	AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal AS ProcedureOfFixedAssetDepreciationChargeLocal,
	|	AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag AS LeasedAssetDepreciationChargeProcedureManag,
	|	AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal AS LeasedFixedAssetDepreciationChargeProcedureLocal,
	|	AccountingPolicy.FixedAssetRevaluationMethod AS FixedAssetRevaluationMethod,
	|	AccountingPolicy.MonthOfFiscalYearBeginning AS MonthOfFiscalYearBeginning
	|
	|INTO TTAccountingPolicyOfFinancialAccounting
	|
	|FROM
	|	InformationRegister.FinancialAccountingPolicy.SliceLast(&EndOfPreviousMonth) AS AccountingPolicy
	|
	|UNION ALL
	|
	|SELECT
	|	&EndOfMonth AS Period,
	|	AccountingPolicy.Organization AS Organization,
	|	AccountingPolicy.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	AccountingPolicy.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge AS ProcedureOfFixedAssetDepreciationCharge,
	|	AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal AS ProcedureOfFixedAssetDepreciationChargeLocal,
	|	AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag AS LeasedAssetDepreciationChargeProcedureManag,
	|	AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal AS LeasedFixedAssetDepreciationChargeProcedureLocal,
	|	AccountingPolicy.FixedAssetRevaluationMethod AS FixedAssetRevaluationMethod,
	|	AccountingPolicy.MonthOfFiscalYearBeginning AS MonthOfFiscalYearBeginning
	|
	|FROM
	|	InformationRegister.FinancialAccountingPolicy.SliceLast(&EndOfMonth) AS AccountingPolicy
	|
	|INDEX BY
	|	Period,
	|	Organization
	|";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	FixedAssetsDepreciationChargeLocalization.AddListOfAllFAToRequestText(ListOfRequests, CalculationParameters);
	
	#Region ListOfAccountingItems_AdditionalCharges_u
	
	QueryText = 
	"SELECT
	|	FACost.Organization      AS Organization,
	|	FACost.FixedAsset AS FixedAsset,
	|	MIN(FACost.Period)  AS Period
	|
	|INTO ListOfAccountingItems_AdditionalCharges_u
	|
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = FACost.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfPreviousMonth
	|
	|WHERE
	|	FACost.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND FACost.Active
	|
	|	AND FACost.RecordInManAccounting
	|	AND (ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards))
	|
	|	AND CASE
	|		WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FACost.FixedAsset AND LeasedAsset.BegOfMonth = &BeginningOfPreviousMonth)
	|			THEN ISNULL(AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|		ELSE ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|	END = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|
	|	AND FACost.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.FixedAssetsInitialRecognition), 
	|			VALUE(Enum.BusinessTransactions.RecognitionOfLeaseItems),
	|			VALUE(Enum.BusinessTransactions.RecognizeSubAssetsComponentsOfDepreciation),
	|			VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions),
	|			VALUE(Enum.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost),
	|			VALUE(Enum.BusinessTransactions.AllocateVariancesToFixedAssetCost))
	|
	|	AND (FACost.Organization, FACost.FixedAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = FACost.FixedAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInManAccounting)
	|
	|GROUP BY
	|	FACost.Organization,
	|	FACost.FixedAsset
	|
	|HAVING
	|	SUM(FACost.Cost - FACost.PreliminaryCostMan) <> 0
	|		OR &ThisIsInternationalVersion
	|			AND MAX(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|			AND SUM(FACost.LocalCost - FACost.PreliminaryCostLocal) <> 0
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfAccountingObjects_AdditionalCharge_BU_MU
	
	QueryText = 
	"SELECT
	|	FACost.Organization      AS Organization,
	|	FACost.FixedAsset AS FixedAsset,
	|	MIN(FACost.Period)  AS Period
	|
	|INTO ListOfAccountingObjects_AdditionalCharge_BU_MU
	|
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = FACost.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfPreviousMonth
	|
	|WHERE
	|	FACost.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND FACost.Active
	|	AND FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|	AND FACost.RecordInLocalAccounting
	|	AND &ThisIsInternationalVersion
	|	AND (ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent))
	|
	|	AND CASE
	|		WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FACost.FixedAsset AND LeasedAsset.BegOfMonth = &BeginningOfPreviousMonth)
	|			THEN ISNULL(AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|		ELSE ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|	END = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|
	|	AND FACost.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.FixedAssetsInitialRecognition), 
	|			VALUE(Enum.BusinessTransactions.RecognitionOfLeaseItems),
	|			VALUE(Enum.BusinessTransactions.RecognizeSubAssetsComponentsOfDepreciation),
	|			VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions),
	|			VALUE(Enum.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost),
	|			VALUE(Enum.BusinessTransactions.AllocateVariancesToFixedAssetCost))
	|
	|	AND (FACost.Organization, FACost.FixedAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = FACost.FixedAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.PostInAccounting)
	|
	|GROUP BY
	|	FACost.Organization,
	|	FACost.FixedAsset
	|
	|HAVING
	|	SUM(FACost.LocalCost - FACost.PreliminaryCostLocal) <> 0
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfAccountingObjects_
	
	QueryText = 
	"SELECT
	|	&EndOfMonth                    AS AccrualPeriod,
	|	&BegOfMonth                   AS BegOfMonth,
	|	&EndOfMonth                    AS EndOfMonth,
	|	&EndOfPreviousMonth         AS Period,
	|	&EndOfPreviousMonth         AS ParameterPeriod,
	|	FALSE                            AS ThisIsAnAdditionalAccrual,
	|	FALSE                            AS ObtainedByDisassemblyCombining,
	|	FixedAssetsAccountingProcedure.Organization      AS Organization,
	|	FixedAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	FixedAssetsAccountingProcedure.FixedAsset AS FixedAsset,
	|
	|	ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) AS MonthOfFiscalYearBeginning,
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS AccountingPolicyForFixedAssets,
	|	ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ISNULL(AccountingPolicy.FixedAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	CASE
	|		WHEN MONTH(&BegOfMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 13)
	|		ELSE DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1) 
	|	END AS BeginningOfFiscalYear,
	|	
	|	CASE
	|		WHEN MONTH(&BegOfMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1)
	|		ELSE DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) + 11) 
	|	END AS EndOfFiscalYear,
	|
	|	(ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) 
	|		= VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS DepreciationIsCalculatedAccordingToINTStandards,
	|
	|	CASE
	|		WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset AND LeasedAsset.BegOfMonth = &BegOfMonth)
	|			THEN ISNULL(AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|		ELSE ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|	END = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|INTO ListOfAccountingObjects_
	|
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&EndOfPreviousMonth,
	|			CorrectionDate = DATETIME(1,1,1)
	|			AND (Organization, FixedAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)) AS FixedAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = FixedAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfMonth
	|
	|WHERE
	|	NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = FixedAssetsAccountingProcedure.FixedAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInManAccounting)
	|
	|UNION
	|
	|SELECT
	|	&EndOfMonth                    AS AccrualPeriod,
	|	&BegOfMonth                   AS BegOfMonth,
	|	&EndOfMonth                    AS EndOfMonth,
	|	BEGINOFPERIOD(FixedAssetsAccountingProcedure.Period, DAY) AS Period,
	|
	|	CASE
	|		WHEN ISNULL(FixedAssetsInitialRecognition.AdjustmentModeFromPreviousDate, FALSE)
	|			THEN &EndOfPreviousMonth
	|		ELSE BEGINOFPERIOD(FixedAssetsAccountingProcedure.Period, DAY)
	|	END AS ParameterPeriod,
	|
	|	FALSE                            AS ThisIsAnAdditionalAccrual,
	|	VALUETYPE(FixedAssetsAccountingProcedure.Recorder) IN (TYPE(Document.SplitFixedAssets), TYPE(Document.MergeOfFixedAssets)) AS ObtainedByDisassemblyCombining,
	|	FixedAssetsAccountingProcedure.Organization      AS Organization,
	|	FixedAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	FixedAssetsAccountingProcedure.FixedAsset AS FixedAsset,
	|
	|	ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) AS MonthOfFiscalYearBeginning,
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS AccountingPolicyForFixedAssets,
	|	ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ISNULL(AccountingPolicy.FixedAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	CASE
	|		WHEN MONTH(&BegOfMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 13)
	|		ELSE DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1) 
	|	END AS BeginningOfFiscalYear,
	|	
	|	CASE
	|		WHEN MONTH(&BegOfMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1)
	|		ELSE DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) + 11) 
	|	END AS EndOfFiscalYear,
	|
	|	(ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) 
	|		= VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS DepreciationIsCalculatedAccordingToINTStandards,
	|
	|	CASE
	|		WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset AND LeasedAsset.BegOfMonth = &BegOfMonth)
	|			THEN ISNULL(AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|		ELSE ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|	END = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedure
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS FixedAssetsInitialRecognition
	|		ON FixedAssetsInitialRecognition.Ref = FixedAssetsAccountingProcedure.Recorder
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = FixedAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfMonth
	|
	|WHERE
	|	FixedAssetsAccountingProcedure.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND FixedAssetsAccountingProcedure.State = VALUE(Enum.FixedAssetsStates.Recognized_)
	|	AND FixedAssetsAccountingProcedure.Active
	|
	|	AND (ISNULL(FixedAssetsInitialRecognition.AdjustmentModeFromPreviousDate, FALSE)
	|			AND ISNULL(FixedAssetsInitialRecognition.RecordInManAccounting, FALSE)
	|		OR ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
	|			AND CASE
	|				WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset AND LeasedAsset.BegOfMonth = &BegOfMonth)
	|					THEN ISNULL(AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|				ELSE ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|			END = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|
	|	AND VALUETYPE(FixedAssetsAccountingProcedure.Recorder) IN (
	|				TYPE(Document.FixedAssetsInitialRecognition2_4),
	|				TYPE(Document.RecognizeSubAssetsComponentsOfDepreciation),
	|				TYPE(Document.SplitFixedAssets),
	|				TYPE(Document.MergeOfFixedAssets))
	|
	|	AND (FixedAssetsAccountingProcedure.Organization, FixedAssetsAccountingProcedure.FixedAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = FixedAssetsAccountingProcedure.FixedAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInManAccounting)
	|
	|UNION
	|
	|SELECT
	|	&EndOfMonth                    AS AccrualPeriod,
	|	&BeginningOfPreviousMonth        AS BegOfMonth,
	|	&EndOfPreviousMonth         AS EndOfMonth,
	|	BEGINOFPERIOD(FixedAssetsAccountingProcedure.Period, DAY) AS Period,
	|	BEGINOFPERIOD(FixedAssetsAccountingProcedure.Period, DAY) AS ParameterPeriod,
	|	TRUE                          AS ThisIsAnAdditionalAccrual,
	|	FALSE                            AS ObtainedByDisassemblyCombining,
	|	FixedAssetsAccountingProcedure.Organization      AS Organization,
	|	FixedAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	FixedAssetsAccountingProcedure.FixedAsset AS FixedAsset,
	|
	|	ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) AS MonthOfFiscalYearBeginning,
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS AccountingPolicyForFixedAssets,
	|	ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ISNULL(AccountingPolicy.FixedAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	CASE
	|		WHEN MONTH(&BeginningOfPreviousMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BeginningOfPreviousMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 13)
	|		ELSE DATEADD(BEGINOFPERIOD(&BeginningOfPreviousMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1) 
	|	END AS BeginningOfFiscalYear,
	|	
	|	CASE
	|		WHEN MONTH(&BeginningOfPreviousMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BeginningOfPreviousMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1)
	|		ELSE DATEADD(BEGINOFPERIOD(&BeginningOfPreviousMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) + 11) 
	|	END AS EndOfFiscalYear,
	|
	|	TRUE AS DepreciationIsCalculatedAccordingToINTStandards,
	|	TRUE AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = FixedAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfPreviousMonth
	|
	|WHERE
	|	FixedAssetsAccountingProcedure.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND FixedAssetsAccountingProcedure.State = VALUE(Enum.FixedAssetsStates.Recognized_)
	|	AND FixedAssetsAccountingProcedure.Active
	|
	|	AND ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
	|
	|	AND CASE
	|		WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset AND LeasedAsset.BegOfMonth = &BeginningOfPreviousMonth)
	|			THEN ISNULL(AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|		ELSE ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|	END = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|
	|	AND VALUETYPE(FixedAssetsAccountingProcedure.Recorder) IN (
	|				TYPE(Document.FixedAssetsInitialRecognition2_4),
	|				TYPE(Document.RecognizeSubAssetsComponentsOfDepreciation),
	|				TYPE(Document.FixedAssetsCostAdditions2_4),
	|				TYPE(Document.AllocateVariancesToFixedAssetCost),
	|				TYPE(Document.SplitFixedAssets))
	|
	|	AND (FixedAssetsAccountingProcedure.Organization, FixedAssetsAccountingProcedure.FixedAsset) IN
	|				(SELECT
	|					ListOfFA.Organization,
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfAccountingItems_AdditionalCharges_u AS ListOfFA)
	|
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = FixedAssetsAccountingProcedure.FixedAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInManAccounting)
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization,
	|	BegOfMonth,
	|	ParameterPeriod
	|";
	
	ListOfRequests.Add(QueryText);

	#EndRegion
	
	#Region ListOfAccountingObjects_BU_MU
	
	QueryText = 
	"SELECT
	|	&EndOfMonth                    AS AccrualPeriod,
	|	&BegOfMonth                   AS BegOfMonth,
	|	&EndOfMonth                    AS EndOfMonth,
	|	&EndOfPreviousMonth         AS Period,
	|	&EndOfPreviousMonth         AS ParameterPeriod,
	|	FALSE                            AS ThisIsAnAdditionalAccrual,
	|	FALSE                            AS ObtainedByDisassemblyCombining,
	|	FixedAssetsAccountingProcedure.Organization      AS Organization,
	|	FixedAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	FixedAssetsAccountingProcedure.FixedAsset AS FixedAsset,
	|
	|	ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) AS MonthOfFiscalYearBeginning,
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS AccountingPolicyForFixedAssets,
	|	ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ISNULL(AccountingPolicy.FixedAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	CASE
	|		WHEN MONTH(&BegOfMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 13)
	|		ELSE DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1) 
	|	END AS BeginningOfFiscalYear,
	|	
	|	CASE
	|		WHEN MONTH(&BegOfMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1)
	|		ELSE DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) + 11) 
	|	END AS EndOfFiscalYear,
	|
	|	CASE
	|		WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset AND LeasedAsset.BegOfMonth = &BegOfMonth)
	|			THEN ISNULL(AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|		ELSE ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|	END = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|INTO ListOfAccountingObjects_BU_MU
	|
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&EndOfPreviousMonth,
	|			&ThisIsInternationalVersion
	|			AND CorrectionDate = DATETIME(1,1,1)
	|			AND (Organization, FixedAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)) AS FixedAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = FixedAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfMonth
	|
	|WHERE 
	|	&ThisIsInternationalVersion
	|	AND ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = FixedAssetsAccountingProcedure.FixedAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.PostInAccounting)
	|
	|UNION
	|
	|SELECT
	|	&EndOfMonth                    AS AccrualPeriod,
	|	&BegOfMonth                   AS BegOfMonth,
	|	&EndOfMonth                    AS EndOfMonth,
	|	BEGINOFPERIOD(FixedAssetsAccountingProcedure.Period, DAY) AS Period,
	|	BEGINOFPERIOD(FixedAssetsAccountingProcedure.Period, DAY) AS ParameterPeriod,
	|	FALSE                            AS ThisIsAnAdditionalAccrual,
	|	VALUETYPE(FixedAssetsAccountingProcedure.Recorder) IN (TYPE(Document.SplitFixedAssets), TYPE(Document.MergeOfFixedAssets)) AS ObtainedByDisassemblyCombining,
	|	FixedAssetsAccountingProcedure.Organization      AS Organization,
	|	FixedAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	FixedAssetsAccountingProcedure.FixedAsset AS FixedAsset,
	|
	|	ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) AS MonthOfFiscalYearBeginning,
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS AccountingPolicyForFixedAssets,
	|	ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ISNULL(AccountingPolicy.FixedAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	CASE
	|		WHEN MONTH(&BegOfMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 13)
	|		ELSE DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1) 
	|	END AS BeginningOfFiscalYear,
	|	
	|	CASE
	|		WHEN MONTH(&BegOfMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1)
	|		ELSE DATEADD(BEGINOFPERIOD(&BegOfMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) + 11) 
	|	END AS EndOfFiscalYear,
	|
	|	TRUE AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU AS FixedAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = FixedAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfMonth
	|
	|WHERE
	|	FixedAssetsAccountingProcedure.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND FixedAssetsAccountingProcedure.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
	|	AND FixedAssetsAccountingProcedure.Active
	|
	|	AND CASE
	|		WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset AND LeasedAsset.BegOfMonth = &BegOfMonth)
	|			THEN ISNULL(AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|		ELSE ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|	END = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|
	|	AND &ThisIsInternationalVersion
	|	AND ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|
	|	AND VALUETYPE(FixedAssetsAccountingProcedure.Recorder) IN (
	|				TYPE(Document.FixedAssetsInitialRecognition2_4),
	|				TYPE(Document.RecognizeSubAssetsComponentsOfDepreciation),
	|				TYPE(Document.SplitFixedAssets),
	|				TYPE(Document.MergeOfFixedAssets))
	|
	|	AND (FixedAssetsAccountingProcedure.Organization, FixedAssetsAccountingProcedure.FixedAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = FixedAssetsAccountingProcedure.FixedAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.PostInAccounting)
	|
	|UNION
	|
	|SELECT
	|	&EndOfMonth                    AS AccrualPeriod,
	|	&BeginningOfPreviousMonth        AS BegOfMonth,
	|	&EndOfPreviousMonth         AS EndOfMonth,
	|	BEGINOFPERIOD(FixedAssetsAccountingProcedure.Period, DAY) AS Period,
	|	BEGINOFPERIOD(FixedAssetsAccountingProcedure.Period, DAY) AS ParameterPeriod,
	|	TRUE                          AS ThisIsAnAdditionalAccrual,
	|	FALSE                            AS ObtainedByDisassemblyCombining,
	|	FixedAssetsAccountingProcedure.Organization      AS Organization,
	|	FixedAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	FixedAssetsAccountingProcedure.FixedAsset AS FixedAsset,
	|
	|	ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) AS MonthOfFiscalYearBeginning,
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS AccountingPolicyForFixedAssets,
	|	ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ISNULL(AccountingPolicy.FixedAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	CASE
	|		WHEN MONTH(&BeginningOfPreviousMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BeginningOfPreviousMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 13)
	|		ELSE DATEADD(BEGINOFPERIOD(&BeginningOfPreviousMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1) 
	|	END AS BeginningOfFiscalYear,
	|	
	|	CASE
	|		WHEN MONTH(&BeginningOfPreviousMonth) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(&BeginningOfPreviousMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 1)
	|		ELSE DATEADD(BEGINOFPERIOD(&BeginningOfPreviousMonth, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) + 11) 
	|	END AS EndOfFiscalYear,
	|
	|	TRUE AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU AS FixedAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = FixedAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfPreviousMonth
	|
	|WHERE
	|	FixedAssetsAccountingProcedure.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND FixedAssetsAccountingProcedure.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
	|
	|	AND CASE
	|		WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset AND LeasedAsset.BegOfMonth = &BeginningOfPreviousMonth)
	|			THEN ISNULL(AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|		ELSE ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|	END = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|
	|	AND &ThisIsInternationalVersion
	|	AND ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|
	|	AND VALUETYPE(FixedAssetsAccountingProcedure.Recorder) IN (
	|				TYPE(Document.FixedAssetsInitialRecognition2_4),
	|				TYPE(Document.RecognizeSubAssetsComponentsOfDepreciation),
	|				TYPE(Document.FixedAssetsCostAdditions2_4),
	|				TYPE(Document.AllocateVariancesToFixedAssetCost),
	|				TYPE(Document.SplitFixedAssets))
	|
	|	AND (FixedAssetsAccountingProcedure.Organization, FixedAssetsAccountingProcedure.FixedAsset) IN
	|				(SELECT
	|					ListOfFA.Organization,
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfAccountingObjects_AdditionalCharge_BU_MU AS ListOfFA)
	|
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = FixedAssetsAccountingProcedure.FixedAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.PostInAccounting)
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization,
	|	BegOfMonth,
	|	ParameterPeriod
	|";
	
	ListOfRequests.Add(QueryText);

	#EndRegion
	
	#Region ListOfAccountingItems_AdditionalCharges_All
	QueryText = FixedAssetsDepreciationChargeLocalization.RequestTextListOfAccountingObjectsAdditionalChargesAll();
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	ListOfAccountingObjects.Organization      AS Organization,
		|	ListOfAccountingObjects.FixedAsset AS FixedAsset,
		|	ListOfAccountingObjects.Period           AS Period
		|
		|INTO ListOfAccountingItems_AdditionalCharges_All
		|FROM
		|	ListOfAccountingItems_AdditionalCharges_u AS ListOfAccountingObjects
		|
		|UNION ALL
		|
		|SELECT
		|	ListOfAccountingObjects.Organization      AS Organization,
		|	ListOfAccountingObjects.FixedAsset AS FixedAsset,
		|	ListOfAccountingObjects.Period           AS Period
		|
		|FROM
		|	ListOfAccountingObjects_AdditionalCharge_BU_MU AS ListOfAccountingObjects
		|
		|INDEX BY
		|	FixedAsset,
		|	Organization";
	
	EndIf;
	 
	ListOfRequests.Add(QueryText);
	#EndRegion

EndProcedure

// Gets all the necessary parameters for the calculation.
// 
// Parameters:
//  ListOfRequests - Array of String - List of requests
//  CalculationParameters - Structure - Calculation parameters
Procedure QueryTextDepreciationCalculationParameters(ListOfRequests, CalculationParameters)

	AccountingObject = "FixedAsset";
	
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"FALocation", "", AccountingObject, ListOfRequests);
	
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"OSBUDepreciationParameters", "", AccountingObject, ListOfRequests);
		
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"FixedAssetsAccountingProcedureManagementAccounting", "", AccountingObject, ListOfRequests);
		
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"AccountingProcedureForOSBU", "", AccountingObject, ListOfRequests);
		
	If Not CalculationParameters.CalculationParametersRedefined Then
		
		NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
			"InitialFixedAssetsInformation", "", AccountingObject, ListOfRequests);
		
		NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
			"FixedAssetsAccountingProcedure", "", AccountingObject, ListOfRequests);
		
		NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
			"FixedAssetDepreciationParametersManagementAccounting", "", AccountingObject, ListOfRequests);
			
	EndIf;
	
	#Region DatesWhenMaWasLastModified
	QueryText =
	"SELECT
	|	NestedQuery.BegOfMonth AS BegOfMonth,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.FixedAsset AS FixedAsset,
	|	
	|	MAX(NestedQuery.Date) AS Date,
	|	MAX(NestedQuery.EndOfFiscalYear) AS EndOfFiscalYear,
	|	MAX(NestedQuery.AdjustmentModeFromPreviousDate) AS AdjustmentModeFromPreviousDate,
	|	MAX(NestedQuery.DateOfDocumentOfAcceptanceForAccounting) AS DateOfDocumentOfAcceptanceForAccounting
	|
	|INTO DatesWhenMaWasLastModified
	|
	|FROM
	|	(SELECT
	|		FixedAssetDepreciationParametersManagementAccounting.BegOfMonth AS BegOfMonth,
	|		FixedAssetDepreciationParametersManagementAccounting.Organization AS Organization,
	|		FixedAssetDepreciationParametersManagementAccounting.FixedAsset AS FixedAsset,
	|	
	|		CASE
	|			WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = FixedAssetDepreciationParametersManagementAccounting.FixedAsset AND LeasedAsset.BegOfMonth = &BegOfMonth)
	|				THEN CASE 
	|						WHEN ISNULL(AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|							THEN FixedAssetDepreciationParametersManagementAccounting.LastChangeDate
	|						ELSE BEGINOFPERIOD(DATEADD(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, MONTH, 1), MONTH)
	|					END
	|
	|			WHEN ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|				THEN FixedAssetDepreciationParametersManagementAccounting.LastChangeDate
	|
	|			ELSE BEGINOFPERIOD(DATEADD(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, MONTH, 1), MONTH)
	|
	|		END AS Date,
	|
	|		CASE
	|			WHEN ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
	|				THEN
	|					CASE 
	|						WHEN MONTH(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 0)
	|							THEN ENDOFPERIOD(DATEADD(BEGINOFPERIOD(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 2), MONTH)
	|						ELSE ENDOFPERIOD(DATEADD(BEGINOFPERIOD(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) + 10), MONTH)
	|					END
	|			ELSE CASE 
	|						WHEN MONTH(BEGINOFPERIOD(DATEADD(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, MONTH, 1), MONTH)) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 0)
	|							THEN ENDOFPERIOD(DATEADD(BEGINOFPERIOD(BEGINOFPERIOD(DATEADD(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, MONTH, 1), MONTH), YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 2), MONTH)
	|						ELSE ENDOFPERIOD(DATEADD(BEGINOFPERIOD(BEGINOFPERIOD(DATEADD(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, MONTH, 1), MONTH), YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) + 10), MONTH)
	|					END
	|		END AS EndOfFiscalYear,
	|
	|		ISNULL(FixedAssetsInitialRecognition.AdjustmentModeFromPreviousDate, FALSE)
	|			AND ISNULL(FixedAssetsInitialRecognition.RecordInManAccounting, FALSE) AS AdjustmentModeFromPreviousDate,
	|
	|		ISNULL(InitialFixedAssetsInformation.CommissioningDocumentMA.DATE, DATETIME(1,1,1)) AS DateOfDocumentOfAcceptanceForAccounting
	|
	|	FROM
	|		FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
	|
	|			LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|			ON (InitialFixedAssetsInformation.Organization = FixedAssetDepreciationParametersManagementAccounting.Organization)
	|				AND (InitialFixedAssetsInformation.FixedAsset = FixedAssetDepreciationParametersManagementAccounting.FixedAsset)
	|				AND (InitialFixedAssetsInformation.BegOfMonth = FixedAssetDepreciationParametersManagementAccounting.BegOfMonth)
	|
	|			LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS FixedAssetsInitialRecognition
	|			ON (FixedAssetsInitialRecognition.Ref = InitialFixedAssetsInformation.CommissioningDocumentMA)
	|
	|			LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|			ON AccountingPolicy.Organization = FixedAssetDepreciationParametersManagementAccounting.Organization.ParentCompany
	|				AND AccountingPolicy.Period = &EndOfMonth
	|
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.BegOfMonth,
	|	NestedQuery.Organization,
	|	NestedQuery.FixedAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization,
	|	BegOfMonth
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DatesOfLastModificationOfBU_MU
	QueryText =
	"SELECT
	|	NestedQuery.BegOfMonth AS BegOfMonth,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.FixedAsset AS FixedAsset,
	|	
	|	MAX(NestedQuery.Date) AS Date,
	|	MAX(NestedQuery.EndOfFiscalYear) AS EndOfFiscalYear,
	|	MAX(NestedQuery.AdjustmentModeFromPreviousDate) AS AdjustmentModeFromPreviousDate,
	|	MAX(NestedQuery.DateOfDocumentOfAcceptanceForAccounting) AS DateOfDocumentOfAcceptanceForAccounting
	|
	|INTO DatesOfLastModificationOfBU_MU
	|
	|FROM
	|	(SELECT
	|		OSBUDepreciationParameters.BegOfMonth AS BegOfMonth,
	|		OSBUDepreciationParameters.Organization AS Organization,
	|		OSBUDepreciationParameters.FixedAsset AS FixedAsset,
	|	
	|		CASE
	|			WHEN TRUE IN (SELECT TOP 1 TRUE FROM TT_LeasedAsset AS LeasedAsset WHERE LeasedAsset.FixedAsset = OSBUDepreciationParameters.FixedAsset AND LeasedAsset.BegOfMonth = &BegOfMonth)
	|				THEN CASE 
	|						WHEN ISNULL(AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|							THEN OSBUDepreciationParameters.LastChangeDate
	|						ELSE BEGINOFPERIOD(DATEADD(OSBUDepreciationParameters.LastChangeDate, MONTH, 1), MONTH)
	|					END
	|
	|			WHEN ISNULL(AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|				THEN OSBUDepreciationParameters.LastChangeDate
	|
	|			ELSE BEGINOFPERIOD(DATEADD(OSBUDepreciationParameters.LastChangeDate, MONTH, 1), MONTH)
	|
	|		END AS Date,
	|
	|		CASE 
	|			WHEN MONTH(OSBUDepreciationParameters.LastChangeDate) < ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 0)
	|				THEN ENDOFPERIOD(DATEADD(BEGINOFPERIOD(OSBUDepreciationParameters.LastChangeDate, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) - 2), MONTH)
	|			ELSE ENDOFPERIOD(DATEADD(BEGINOFPERIOD(OSBUDepreciationParameters.LastChangeDate, YEAR), MONTH, ISNULL(AccountingPolicy.MonthOfFiscalYearBeginning, 1) + 10), MONTH)
	|		END AS EndOfFiscalYear,
	|
	|		ISNULL(FixedAssetsInitialRecognition.AdjustmentModeFromPreviousDate, FALSE)
	|			AND ISNULL(FixedAssetsInitialRecognition.RecordInLocalAccounting, FALSE) AS AdjustmentModeFromPreviousDate,
	|
	|		ISNULL(InitialFixedAssetsInformation.CommissioningDocumentAC.DATE, DATETIME(1,1,1)) AS DateOfDocumentOfAcceptanceForAccounting
	|
	|	FROM
	|		OSBUDepreciationParameters AS OSBUDepreciationParameters
	|
	|			LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|			ON (InitialFixedAssetsInformation.Organization = OSBUDepreciationParameters.Organization)
	|				AND (InitialFixedAssetsInformation.FixedAsset = OSBUDepreciationParameters.FixedAsset)
	|				AND (InitialFixedAssetsInformation.BegOfMonth = OSBUDepreciationParameters.BegOfMonth)
	|
	|			LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS FixedAssetsInitialRecognition
	|			ON (FixedAssetsInitialRecognition.Ref = InitialFixedAssetsInformation.CommissioningDocumentAC)
	|
	|			LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|			ON AccountingPolicy.Organization = OSBUDepreciationParameters.Organization.ParentCompany
	|				AND AccountingPolicy.Period = &EndOfMonth
	|
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.BegOfMonth,
	|	NestedQuery.Organization,
	|	NestedQuery.FixedAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization,
	|	BegOfMonth
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CostOfFAAtBeginningOfMonth
	
	QueryText = 
	"SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	FACost.FixedAsset AS FixedAsset,
	|	FACost.CostBalance AS Cost,
	|	FACost.LocalCostBalance AS LocalCost,
	|	FACost.CostInTaxAccountingBalance AS CostInTaxAccounting,
	|	FACost.CostPermanentDifferenceBalance AS CostPermanentDifference,
	|	FACost.CostTemporaryDifferenceBalance AS CostTemporaryDifference,
	|	FACost.CostTargetFinancingBalance AS CostTargetFinancing,
	|	FACost.CostTargetFinancingTABalance AS CostTargetFinancingTA,
	|	FACost.CostTargetFinancingPDBalance AS CostTargetFinancingPD,
	|	FACost.CostTargetFinancingTDBalance AS CostTargetFinancingTD,
	|	FACost.DepreciationAllowanceBalance AS DepreciationAllowance
	|
	|INTO OS_CostAtBeginningOfMonth
	|
	|	FROM
	|		AccumulationRegister.FACost.Balance(
	|				&EndOfPreviousMonthBorder,
	|				(Organization, FixedAsset) IN
	|					(SELECT
	|						ListOfFA.Organization,
	|						ListOfFA.FixedAsset
	|					FROM
	|						ListOfAccountingObjects AS ListOfFA)) AS FACost
	|
	|INDEX BY
	|	FixedAsset";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region CostAndDepreciationAtBeginningOfYear
	
	QueryText = FixedAssetsDepreciationChargeLocalization.QueryTextTTFAListOfReducedBalance(CalculationParameters);
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	ListOfFA.FixedAsset
		|INTO TTFAListOfReducedBalance
		|FROM
		|	InitialFixedAssetsInformation AS ListOfFA
		|WHERE
		|	ListOfFA.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
		|
		|UNION
		|
		|SELECT
		|	ListOfFA.FixedAsset
		|FROM
		|	FixedAssetDepreciationParametersManagementAccounting AS ListOfFA
		|WHERE
		|	ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
		|
		|INDEX BY
		|	FixedAsset";
		
	EndIf; 
	
	ListOfRequests.Add(QueryText);
	
	QueryText = FixedAssetsDepreciationChargeLocalization.QueryTextCostAndDepreciationAtBeginningOfYear(CalculationParameters);
	
	If QueryText = Undefined Then
	
		QueryText = 
		"SELECT
		|	&BegOfMonth                            AS BegOfMonth,
		|	FACost.FixedAsset             AS FixedAsset,
		|	FACost.CostBalance             AS Cost,
		|	FACost.LocalCostBalance         AS LocalCost,
		|	FACost.CostTargetFinancingBalance           AS CostTargetFinancing
		|INTO OS_CostAtBeginningOfYear
		|FROM
		|	AccumulationRegister.FACost.Balance(
		|			&BegOfYear,
		|			FixedAsset IN
		|				(SELECT ListOfFA.FixedAsset FROM TTFAListOfReducedBalance AS ListOfFA)) AS FACost
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&BegOfMonth                          AS BegOfMonth,
		|	FixedAssetsDepreciationCharge.FixedAsset         AS FixedAsset,
		|	-FixedAssetsDepreciationCharge.DepreciationBalance      AS Depreciation,
		|	-FixedAssetsDepreciationCharge.DepreciationLocalBalance  AS DepreciationLocal,
		|	-FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancingBalance    AS FixedAssetDepreciationTargetFinancing
		|INTO OS_DepreciationAtBeginningOfYear
		|FROM
		|	AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
		|			&BegOfYear,
		|			FixedAsset IN
		|				(SELECT ListOfFA.FixedAsset FROM TTFAListOfReducedBalance AS ListOfFA)) AS FixedAssetsDepreciationCharge
		|
		|INDEX BY
		|	FixedAsset";
		
	EndIf;
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region PreliminaryCostOfFA
	
	QueryText = 
	"SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	FACost.FixedAsset AS FixedAsset,
	|
	|	MAX(ISNULL(FixedAssetsInitialRecognition.CostInManagementAccounting, 
	|				ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInManagementAccounting, 
	|					ISNULL(FixedAssetsCostAdditions.CostInManagementAccounting, 
	|						ISNULL(AllocateVariancesToFixedAssetCost.AmountOfUU, 0))))) AS CostInManagementAccounting,
	|
	|	MAX(ISNULL(FixedAssetsInitialRecognition.CostInAccounting, 
	|				ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInAccounting, 
	|					ISNULL(FixedAssetsCostAdditions.CostInAccounting, 
	|						ISNULL(AllocateVariancesToFixedAssetCost.AmountAccounting, 0))))) AS CostInAccounting,
	|
	|
	|	CASE
	|		WHEN MAX(ISNULL(FixedAssetsInitialRecognition.CostInAccounting, ISNULL(FixedAssetsCostAdditions.CostInAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountAccounting, 0)))) <> 0
	|			THEN CAST(MAX(ISNULL(FixedAssetsInitialRecognition.AmountOfTargetFunds, ISNULL(FixedAssetsCostAdditions.AmountOfTargetFunds, ISNULL(AllocateVariancesToFixedAssetCost.AmountOfTargetFunds, 0)))) 
	|							/ MAX(ISNULL(FixedAssetsInitialRecognition.CostInAccounting, ISNULL(FixedAssetsCostAdditions.CostInAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountAccounting, 0)))) AS NUMBER (23, 10))
	|		ELSE 0
	|	END AS CFShare,
	|
	|	FALSE PreliminaryCostExceedsActualMA,
	|	FALSE PreliminaryCostExceedsActualAC,
	|	FALSE PreliminaryCostExceedsActualPD
	|
	|INTO PreliminaryCostOfFA
	|
	|FROM
	|	AccumulationRegister.FACost AS FACost                     
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4.FA AS FixedAssetsInitialRecognition
	|		ON FixedAssetsInitialRecognition.Ref = FACost.Recorder
	|			AND FixedAssetsInitialRecognition.FixedAsset = FACost.FixedAsset
	|
	|		LEFT JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS RecognizeSubAssetsComponentsOfDepreciation
	|		ON RecognizeSubAssetsComponentsOfDepreciation.Ref = FACost.Recorder
	|			AND RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponent = FACost.FixedAsset
	|
	|		LEFT JOIN Document.FixedAssetsCostAdditions2_4.FA AS FixedAssetsCostAdditions
	|		ON FixedAssetsCostAdditions.Ref = FACost.Recorder
	|			AND FixedAssetsCostAdditions.FixedAsset = FACost.FixedAsset
	|
	|		LEFT JOIN Document.AllocateVariancesToFixedAssetCost.FA AS AllocateVariancesToFixedAssetCost
	|		ON AllocateVariancesToFixedAssetCost.Ref = FACost.Recorder
	|			AND AllocateVariancesToFixedAssetCost.FixedAsset = FACost.FixedAsset
	|
	|
	|WHERE
	|	FACost.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND FACost.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.FixedAssetsInitialRecognition), 
	|			VALUE(Enum.BusinessTransactions.RecognitionOfLeaseItems), 
	|			VALUE(Enum.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount),
	|			VALUE(Enum.BusinessTransactions.RecognizeSubAssetsComponentsOfDepreciation),
	|			VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions),
	|			VALUE(Enum.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost),
	|			VALUE(Enum.BusinessTransactions.AllocateVariancesToFixedAssetCost))
	|
	|	AND FACost.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects AS ListOfFA)
	|
	|GROUP BY
	|	FACost.FixedAsset	
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	FACost.FixedAsset AS FixedAsset,
	|
	|	CASE 
	|		WHEN (SUM(FACost.Cost) - MAX(ISNULL(FixedAssetsInitialRecognition.CostInManagementAccounting, ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInManagementAccounting, ISNULL(FixedAssetsCostAdditions.CostInManagementAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountOfUU, 0)))))) > 0 
	|			THEN SUM(FACost.Cost) - MAX(ISNULL(FixedAssetsInitialRecognition.CostInManagementAccounting, ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInManagementAccounting, ISNULL(FixedAssetsCostAdditions.CostInManagementAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountOfUU, 0))))) 
	|		WHEN (SUM(FACost.Cost) - MAX(ISNULL(FixedAssetsInitialRecognition.CostInManagementAccounting, ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInManagementAccounting, ISNULL(FixedAssetsCostAdditions.CostInManagementAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountOfUU, 0)))))) < 0 
	|			THEN -SUM(FACost.Cost) + MAX(ISNULL(FixedAssetsInitialRecognition.CostInManagementAccounting, ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInManagementAccounting, ISNULL(FixedAssetsCostAdditions.CostInManagementAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountOfUU, 0))))) 
	|		ELSE 0 
	|	END AS CostInManagementAccounting,
	|
	|	CASE
	|		WHEN (SUM(FACost.LocalCost) + SUM(FACost.CostTargetFinancing) - MAX(ISNULL(FixedAssetsInitialRecognition.CostInAccounting, ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInAccounting, ISNULL(FixedAssetsCostAdditions.CostInAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountAccounting, 0)))))) > 0
	|			THEN SUM(FACost.LocalCost) + SUM(FACost.CostTargetFinancing) - MAX(ISNULL(FixedAssetsInitialRecognition.CostInAccounting, ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInAccounting, ISNULL(FixedAssetsCostAdditions.CostInAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountAccounting, 0))))) 
	|		WHEN (SUM(FACost.LocalCost) + SUM(FACost.CostTargetFinancing) - MAX(ISNULL(FixedAssetsInitialRecognition.CostInAccounting, ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInAccounting, ISNULL(FixedAssetsCostAdditions.CostInAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountAccounting, 0)))))) < 0
	|			THEN -SUM(FACost.LocalCost) - SUM(FACost.CostTargetFinancing) + MAX(ISNULL(FixedAssetsInitialRecognition.CostInAccounting, ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInAccounting, ISNULL(FixedAssetsCostAdditions.CostInAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountAccounting, 0))))) 
	|		ELSE 0
	|	END AS CostInAccounting,
	|
	|
	|	CASE
	|		WHEN SUM(FACost.LocalCost) <> 0
	|			THEN CAST(MAX(ISNULL(FixedAssetsInitialRecognition.AmountOfTargetFunds, ISNULL(FixedAssetsCostAdditions.AmountOfTargetFunds, ISNULL(AllocateVariancesToFixedAssetCost.AmountOfTargetFunds, 0)))) 
	|							/ SUM(FACost.LocalCost) AS NUMBER (23, 10)) 
	|		ELSE 0
	|	END AS CFShare,
	|
	|	CASE 
	|		WHEN (SUM(FACost.Cost) - MAX(ISNULL(FixedAssetsInitialRecognition.CostInManagementAccounting, ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInManagementAccounting, ISNULL(FixedAssetsCostAdditions.CostInManagementAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountOfUU, 0)))))) < 0 
	|				AND SUM(FACost.Cost) <> 0
	|			THEN TRUE 
	|		ELSE FALSE
	|	END AS PreliminaryCostExceedsActualMA,
	|
	|	CASE 
	|		WHEN (SUM(FACost.LocalCost) + SUM(FACost.CostTargetFinancing) - MAX(ISNULL(FixedAssetsInitialRecognition.CostInAccounting, ISNULL(RecognizeSubAssetsComponentsOfDepreciation.CostInAccounting, ISNULL(FixedAssetsCostAdditions.CostInAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountAccounting, 0)))))) < 0 
	|				AND SUM(FACost.LocalCost) <> 0
	|			THEN TRUE 
	|		ELSE FALSE
	|	END AS PreliminaryCostExceedsActualAC,
	|
	|	CASE 
	|		WHEN (SUM(FACost.CostPermanentDifference) + SUM(FACost.CostTargetFinancingPD) - MAX(ISNULL(FixedAssetsInitialRecognition.CostPermanentDifference, ISNULL(FixedAssetsCostAdditions.CostPermanentDifference, ISNULL(AllocateVariancesToFixedAssetCost.AmountPermanentDifferences, 0))))) < 0 
	|				AND SUM(FACost.CostPermanentDifference) <> 0
	|			THEN TRUE 
	|		ELSE FALSE
	|	END AS PreliminaryCostExceedsActualPD
	|
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4.FA AS FixedAssetsInitialRecognition
	|		ON FixedAssetsInitialRecognition.Ref = FACost.Recorder
	|			AND FixedAssetsInitialRecognition.FixedAsset = FACost.FixedAsset
	|
	|		LEFT JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS RecognizeSubAssetsComponentsOfDepreciation
	|		ON RecognizeSubAssetsComponentsOfDepreciation.Ref = FACost.Recorder
	|			AND RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponent = FACost.FixedAsset
	|
	|		LEFT JOIN Document.FixedAssetsCostAdditions2_4.FA AS FixedAssetsCostAdditions
	|		ON FixedAssetsCostAdditions.Ref = FACost.Recorder
	|			AND FixedAssetsCostAdditions.FixedAsset = FACost.FixedAsset
	|
	|		LEFT JOIN Document.AllocateVariancesToFixedAssetCost.FA AS AllocateVariancesToFixedAssetCost
	|		ON AllocateVariancesToFixedAssetCost.Ref = FACost.Recorder
	|			AND AllocateVariancesToFixedAssetCost.FixedAsset = FACost.FixedAsset
	|
	|WHERE
	|	FACost.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|
	|	AND FACost.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.FixedAssetsInitialRecognition), 
	|		VALUE(Enum.BusinessTransactions.RecognitionOfLeaseItems), 
	|		VALUE(Enum.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount),
	|		VALUE(Enum.BusinessTransactions.RecognizeSubAssetsComponentsOfDepreciation),
	|		VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions),
	|		VALUE(Enum.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost),
	|		VALUE(Enum.BusinessTransactions.AllocateVariancesToFixedAssetCost))
	|
	|	AND FACost.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingItems_AdditionalCharges_All AS ListOfFA)
	|
	|GROUP BY
	|	FACost.FixedAsset
	|
	|HAVING 
	|	(SUM(FACost.Cost) - MAX(ISNULL(FixedAssetsInitialRecognition.CostInManagementAccounting, ISNULL(FixedAssetsCostAdditions.CostInManagementAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountOfUU, 0))))) <> 0
	|		OR (SUM(FACost.LocalCost) + SUM(FACost.CostTargetFinancing) - MAX(ISNULL(FixedAssetsInitialRecognition.CostInAccounting, ISNULL(FixedAssetsCostAdditions.CostInAccounting, ISNULL(AllocateVariancesToFixedAssetCost.AmountAccounting, 0))))) <> 0
	|
	|INDEX BY
	|	FixedAsset
	|";
		
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region MADepreciationAdjustment
	
	QueryText = 
	"SELECT
	|	&BegOfMonth               AS BegOfMonth,
	|	FATable.Organization       AS Organization,
	|	FATable.FixedAsset  AS FixedAsset,
	|
	|	SUM(FATable.Depreciation)     AS Depreciation,
	|	SUM(FATable.DepreciationLocal) AS DepreciationLocal
	|
	|INTO MADepreciationAdjustment
	|
	|FROM
	|	(SELECT
	|		Adjusting.Organization   AS Organization,
	|		FATable.FixedAsset  AS FixedAsset,
	|
	|		FATable.DepreciationManagementAccounting AS Depreciation,
	|		FATable.DepreciationInAccounting + FATable.FixedAssetDepreciationTargetFinancing AS DepreciationLocal
	|
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|			ON (FATable.Ref = Adjusting.Ref)
	|
	|	WHERE
	|		Adjusting.Posted
	|		AND Adjusting.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND Adjusting.RecordInManAccounting
	|		AND Adjusting.AdjustmentModeFromPreviousDate
	|
	|		AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					DatesWhenMaWasLastModified AS LastModifiedDates
	|				WHERE
	|					LastModifiedDates.BegOfMonth = &BegOfMonth
	|					AND LastModifiedDates.Organization = Adjusting.Organization
	|					AND LastModifiedDates.FixedAsset = FATable.FixedAsset
	|					AND LastModifiedDates.AdjustmentModeFromPreviousDate
	|					AND BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, DAY) = BEGINOFPERIOD(Adjusting.Date, DAY))
	|
	|	UNION ALL
	|
	|	SELECT
	|		FATable.Organization       AS Organization,
	|		FATable.FixedAsset  AS FixedAsset,
	|
	|		CASE
	|			WHEN FATable.AmountOfUU > 0
	|				THEN FATable.AmountOfUU 
	|			ELSE 0
	|		END AS Depreciation,
	|
	|		CASE
	|			WHEN (FATable.AmountAccounting + FATable.CFAmount) > 0
	|				THEN FATable.AmountAccounting + FATable.CFAmount 
	|			ELSE 0
	|		END AS DepreciationLocal
	|
	|	FROM
	|		DepreciationAdjustmentForPreviousPeriod FATable
	|
	|	WHERE
	|		FATable.AmountOfUU > 0
	|			OR (FATable.AmountAccounting + FATable.CFAmount) > 0
	|
	|	) AS FATable
	|
	|GROUP BY
	|	FATable.Organization,
	|	FATable.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region FADepreciationAtBeginningOfMonth
	
	QueryText = 
	"SELECT
	|	&BegOfMonth                          AS BegOfMonth,
	|	FixedAssetsDepreciationCharge.Organization              AS Organization,
	|	FixedAssetsDepreciationCharge.FixedAsset         AS FixedAsset,
	|	-FixedAssetsDepreciationCharge.DepreciationBalance      AS Depreciation,
	|	-FixedAssetsDepreciationCharge.DepreciationLocalBalance  AS DepreciationLocal,
	|	-FixedAssetsDepreciationCharge.DepreciationInTaxAccountingBalance    AS DepreciationInTaxAccounting,
	|	-FixedAssetsDepreciationCharge.DepreciationPermanentDifferencesBalance    AS DepreciationPermanentDifferences,
	|	-FixedAssetsDepreciationCharge.DepreciationTDBalance    AS DepreciationTD,
	|	-FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancingBalance    AS FixedAssetDepreciationTargetFinancing,
	|	-FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancingBalance  AS DepreciationTaxAccountingTargetFinancing,
	|	-FixedAssetsDepreciationCharge.DepreciationTargetFinancingPDBalance  AS DepreciationTargetFinancingPD,
	|	-FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTDBalance  AS DepreciationOfTargetFinancingTD
	|INTO OS_DepreciationAtBeginningOfMonth
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
	|			&EndOfPreviousMonthBorder,
	|			(Organization, FixedAsset) IN
	|				(SELECT
	|					ListOfFA.Organization,
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfAccountingObjects AS ListOfFA)) AS FixedAssetsDepreciationCharge
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ImpairmentFA
	// In the calculation of depreciation and impairment adjustments, only those HPA
	// for which the CGU has not changed at the end of the month of depreciation calculation participate.
	// For VNA objects that have changed the EGDS, the impairment balance is restored,
	// which is produced by the document that changed the EGDS, and this is calculated after 
	// performing the depreciation calculation operation.
	
	QueryText = 
	"SELECT
	|	CompositionOfEGD_AtEndOfCalculationMonth.Organization AS Organization,
	|	CompositionOfEGD_AtEndOfCalculationMonth.NonCurrentAsset AS NonCurrentAsset,
	|	CompositionOfEGD_AtEndOfCalculationMonth.CGU AS CGUAtEndOfMonth
	|INTO EGDSVNAAtEndOfMonthOfCalculation
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(
	|		&EndOfMonth, 
	|		&UseFixedAssetImpairment
	|		AND (Organization, NonCurrentAsset) IN
	|			(SELECT
	|				ListOfFA.Organization,
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects AS ListOfFA)) AS CompositionOfEGD_AtEndOfCalculationMonth
	|
	|INDEX BY
	|	NonCurrentAsset,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	ImpairmentFA.Organization AS Organization,
	|	ImpairmentFA.NonCurrentAsset AS FixedAsset,
	|
	|	-SUM(ImpairmentFA.ImpairmentLocalAssetsClosingBalance) AS ImpairmentBalanceLocal,
	|	-SUM(ImpairmentFA.ImpairmenManClosingBalance) AS ImpairmentBalanceMan,
	|
	|	MAX(ImpairmentFA.CGU) AS CGU,
	|	MAX(ISNULL(EGDSVNAAtEndOfMonthOfCalculation.CGUAtEndOfMonth, VALUE(Catalog.CashGeneratingUnits.EmptyRef))) AS CGUAtEndOfMonth
	|
	|INTO ImpairmentOfVNA_WithChangedCGU
	|
	|FROM
	|	AccumulationRegister.ImpairmentFA.BalanceAndTurnovers(
	|			&EndOfPreviousMonthBorder, 
	|			&EndOfPreviousMonthBorder,,
	|			RegisterRecordsAndPeriodBoundaries, 
	|			&UseFixedAssetImpairment
	|			AND (Organization, NonCurrentAsset) IN
	|					(SELECT
	|						ListOfFA.Organization,
	|						ListOfFA.FixedAsset
	|					FROM
	|						ListOfAccountingObjects AS ListOfFA)) AS ImpairmentFA
	|
	|		LEFT JOIN EGDSVNAAtEndOfMonthOfCalculation AS EGDSVNAAtEndOfMonthOfCalculation
	|		ON ImpairmentFA.Organization = EGDSVNAAtEndOfMonthOfCalculation.Organization
	|			AND ImpairmentFA.NonCurrentAsset = EGDSVNAAtEndOfMonthOfCalculation.NonCurrentAsset
	|
	|GROUP BY
	|	ImpairmentFA.Organization,
	|	ImpairmentFA.NonCurrentAsset
	|
	|INDEX BY
	|	FixedAsset,
	|	CGUAtEndOfMonth,
	|	CGU
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ImpairmentOfVNA_WithChangedCGU.BegOfMonth AS BegOfMonth,
	|	ImpairmentOfVNA_WithChangedCGU.Organization AS Organization,
	|	ImpairmentOfVNA_WithChangedCGU.FixedAsset AS FixedAsset,
	|	ImpairmentOfVNA_WithChangedCGU.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|	ImpairmentOfVNA_WithChangedCGU.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|	ImpairmentOfVNA_WithChangedCGU.CGU AS CGU
	|
	|INTO ImpairmentFA
	|
	|FROM
	|	ImpairmentOfVNA_WithChangedCGU AS ImpairmentOfVNA_WithChangedCGU
	|
	|WHERE
	|	ImpairmentOfVNA_WithChangedCGU.CGUAtEndOfMonth = ImpairmentOfVNA_WithChangedCGU.CGU
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP EGDSVNAAtEndOfMonthOfCalculation
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ImpairmentOfVNA_WithChangedCGU
	|";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region InvestmentInRent
	QueryText =
	"SELECT
	|	ReturnAssetsFromLeasee.Ref AS Ref,
	|	ReturnAssetsFromLeasee.Date AS Date,
	|	ReturnAssetsFromLeasee.Organization AS Organization,
	|	ReturnAssetsFromLeasee.RecordInManAccounting,
	|	ReturnAssetsFromLeasee.RecordInLocalAccounting,
	|	FATable.FixedAsset AS FixedAsset
	|
	|INTO TTReturnFromFinRental
	|
	|FROM
	|	Document.ReturnAssetsFromLeasee2_4 AS ReturnAssetsFromLeasee
	|
	|		INNER JOIN Document.ReturnAssetsFromLeasee2_4.FA AS FATable
	|		ON (FATable.Ref = ReturnAssetsFromLeasee.Ref)
	|
	|WHERE
	|	ReturnAssetsFromLeasee.Posted
	|	AND ReturnAssetsFromLeasee.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
	|
	|	AND FATable.FixedAsset IN
	|		(SELECT
	|			ListOfFA.FixedAsset
	|		FROM
	|			ListOfAccountingObjects AS ListOfFA
	|		WHERE
	|			ListOfFA.BegOfMonth = &BegOfMonth
	|			AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvestmentInRent.FixedAsset AS FixedAsset,
	|
	|	InvestmentInRent.RentalPaymentsManagBalance 
	|		+ InvestmentInRent.InterestDiscountManBalance
	|		+ InvestmentInRent.NonGuaranteedResidualValueManagBalance AS Cost,
	|
	|	InvestmentInRent.RentalPaymentsLocalBalance
	|		+ InvestmentInRent.InterestDiscountLocalBalance
	|		+ InvestmentInRent.NonGuaranteedResidualValueLocalBalance AS LocalCost
	|
	|INTO InvestmentInRentBalance
	|
	|FROM
	|	AccumulationRegister.InvestmentInRent.Balance(
	|			&BegOfMonth,
	|			FixedAsset IN (SELECT TTReturnFromFinRental.FixedAsset FROM TTReturnFromFinRental AS TTReturnFromFinRental)
	|			AND CAST(Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)) AS InvestmentInRent
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvestmentInRent.Period,
	|	InvestmentInRent.Ref,
	|	InvestmentInRent.Organization,
	|	InvestmentInRent.FixedAsset,
	|	InvestmentInRent.RecordInManAccounting,
	|	InvestmentInRent.RecordInLocalAccounting,
	|
	|	SUM(InvestmentInRent.Cost) AS Cost,
	|	SUM(InvestmentInRent.LocalCost) AS LocalCost
	|
	|INTO InvestmentInRent
	|	
	|FROM
	|	(SELECT
	|		TTReturnFromFinRental.Date AS Period,
	|		TTReturnFromFinRental.Ref AS Ref,
	|		TTReturnFromFinRental.Organization AS Organization,
	|		TTReturnFromFinRental.FixedAsset AS FixedAsset,
	|		TTReturnFromFinRental.RecordInManAccounting,
	|		TTReturnFromFinRental.RecordInLocalAccounting,
	|
	|		InvestmentInRent.Cost AS Cost,
	|		InvestmentInRent.LocalCost AS LocalCost
	|
	|	FROM
	|		TTReturnFromFinRental AS TTReturnFromFinRental
	|
	|			INNER JOIN InvestmentInRentBalance AS InvestmentInRent
	|			ON InvestmentInRent.FixedAsset = TTReturnFromFinRental.FixedAsset
	|
	|	UNION ALL
	|
	|	SELECT
	|		TTReturnFromFinRental.Date AS Period,
	|		TTReturnFromFinRental.Ref AS Ref,
	|		TTReturnFromFinRental.Organization AS Organization,
	|		TTReturnFromFinRental.FixedAsset AS FixedAsset,
	|		TTReturnFromFinRental.RecordInManAccounting,
	|		TTReturnFromFinRental.RecordInLocalAccounting,
	|
	|		CASE WHEN InvestmentInRent.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN InvestmentInRent.RentalPaymentsManag
	|					+ InvestmentInRent.InterestDiscountMan
	|					+ InvestmentInRent.NonGuaranteedResidualValueManag
	|			ELSE -InvestmentInRent.RentalPaymentsManag
	|					- InvestmentInRent.InterestDiscountMan
	|					- InvestmentInRent.NonGuaranteedResidualValueManag
	|		END AS Cost,
	|
	|		CASE WHEN InvestmentInRent.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN InvestmentInRent.RentalPaymentsLocal
	|					+ InvestmentInRent.InterestDiscountLocal
	|					+ InvestmentInRent.NonGuaranteedResidualValueLocal
	|			ELSE -InvestmentInRent.RentalPaymentsLocal
	|					- InvestmentInRent.InterestDiscountLocal
	|					- InvestmentInRent.NonGuaranteedResidualValueLocal
	|		END AS LocalCost
	|
	|	FROM
	|		TTReturnFromFinRental AS TTReturnFromFinRental
	|
	|			INNER JOIN AccumulationRegister.InvestmentInRent AS InvestmentInRent
	|			ON InvestmentInRent.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|				AND InvestmentInRent.FixedAsset = TTReturnFromFinRental.FixedAsset
	|				AND CAST(InvestmentInRent.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
	|				AND InvestmentInRent.Recorder <> TTReturnFromFinRental.Ref
	|				AND (InvestmentInRent.Period <= TTReturnFromFinRental.Date
	|					OR VALUETYPE(InvestmentInRent.Recorder) = TYPE(Document.AccrualOfLeaseInterest))
	|				AND InvestmentInRent.Active
	|
	|	) AS InvestmentInRent
	|
	|GROUP BY
	|	InvestmentInRent.Ref,
	|	InvestmentInRent.Period,
	|	InvestmentInRent.Organization,
	|	InvestmentInRent.FixedAsset,
	|	InvestmentInRent.RecordInManAccounting,
	|	InvestmentInRent.RecordInLocalAccounting
	|
	|HAVING
	|	SUM(InvestmentInRent.Cost) <> 0
	|	OR SUM(InvestmentInRent.LocalCost) <> 0
	|
	|INDEX BY
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region FAGeneration
	
	QueryText =
	"SELECT DISTINCT
	|	ListOfFA.FixedAsset AS FixedAsset,
	|
	|	CASE
	|		WHEN InitialFixedAssetsInformation.CommissioningDateMA <> FixedAssetDepreciationParametersManagementAccounting.LastChangeDate
	|				AND InitialFixedAssetsInformation.CommissioningDateMA <> DATETIME(1,1,1)
	|			THEN ISNULL(ENDOFPERIOD(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, MONTH), DATETIME(1,1,1))
	|		ELSE DATETIME(1,1,1)
	|	END AS DateOfLastChangeMA,
	|
	|	CASE
	|		WHEN InitialFixedAssetsInformation.CommissioningDateAC <> OSBUDepreciationParameters.LastChangeDate
	|				AND InitialFixedAssetsInformation.CommissioningDateAC <> DATETIME(1,1,1)
	|			THEN ISNULL(ENDOFPERIOD(OSBUDepreciationParameters.LastChangeDate, MONTH), DATETIME(1,1,1))
	|		ELSE DATETIME(1,1,1)
	|	END AS LastModifiedDateAC,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(DATEADD(&BegOfMonth, MONTH, -1), MONTH) = BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateAC, MONTH) 
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TakenIntoAccountLastMonth
	|
	|INTO ListOfOS_Production
	|
	|FROM
	|	ListOfAccountingObjects AS ListOfFA
	|
	|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|		ON (InitialFixedAssetsInformation.Organization = ListOfFA.Organization)
	|			AND (InitialFixedAssetsInformation.FixedAsset = ListOfFA.FixedAsset)
	|			AND (InitialFixedAssetsInformation.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
	|		ON (FixedAssetDepreciationParametersManagementAccounting.Organization = ListOfFA.Organization)
	|			AND (FixedAssetDepreciationParametersManagementAccounting.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FixedAssetDepreciationParametersManagementAccounting.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN OSBUDepreciationParameters AS OSBUDepreciationParameters
	|		ON (OSBUDepreciationParameters.Organization = ListOfFA.Organization)
	|			AND (OSBUDepreciationParameters.FixedAsset = ListOfFA.FixedAsset)
	|			AND (OSBUDepreciationParameters.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FAGeneration.Asset AS FixedAsset,
	|	FAGeneration.RunningTimeValue AS RunningTimeValue,
	|	MAX(FAGeneration.Period) AS Period
	|
	|INTO FAGeneration_AsOfLastMAChangeDate_Period
	|
	|FROM
	|	ListOfOS_Production AS ListOfFA
	|
	|		INNER JOIN InformationRegister.AssetActivityRecords AS FAGeneration
	|		ON FAGeneration.Asset = ListOfFA.FixedAsset
	|			AND FAGeneration.Period <= ListOfFA.DateOfLastChangeMA
	|
	|GROUP BY
	|	FAGeneration.Asset,
	|	FAGeneration.RunningTimeValue
	|
	|INDEX BY
	|	FixedAsset,
	|	RunningTimeValue,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FAGeneration.Asset AS FixedAsset,
	|	FAGeneration.RunningTimeValue AS RunningTimeValue,
	|	MAX(FAGeneration.Period) AS Period
	|
	|INTO FAGeneration_AsOfLastACChangeDate_Period
	|
	|FROM
	|	ListOfOS_Production AS ListOfFA
	|
	|		INNER JOIN InformationRegister.AssetActivityRecords AS FAGeneration
	|		ON FAGeneration.Asset = ListOfFA.FixedAsset
	|			AND FAGeneration.Period <= ListOfFA.LastModifiedDateAC
	|
	|GROUP BY
	|	FAGeneration.Asset,
	|	FAGeneration.RunningTimeValue
	|
	|INDEX BY
	|	FixedAsset,
	|	RunningTimeValue,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FAGeneration.Asset AS FixedAsset,
	|	FAGeneration.RunningTimeValue AS RunningTimeValue,
	|	FAGeneration.Value AS OutputVolume
	|
	|INTO FAGeneration_AsOfLastMAChangeDate
	|
	|FROM
	|	FAGeneration_AsOfLastMAChangeDate_Period AS ListOfFA
	|
	|		INNER JOIN InformationRegister.AssetActivityRecords AS FAGeneration
	|		ON FAGeneration.Asset = ListOfFA.FixedAsset
	|			AND FAGeneration.RunningTimeValue = ListOfFA.RunningTimeValue
	|			AND FAGeneration.Period = ListOfFA.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FAGeneration.Asset AS FixedAsset,
	|	FAGeneration.RunningTimeValue AS RunningTimeValue,
	|	FAGeneration.Value AS OutputVolume
	|
	|INTO FAGeneration_AsOfLastACChangeDate
	|
	|FROM
	|	FAGeneration_AsOfLastACChangeDate_Period AS ListOfFA
	|
	|		INNER JOIN InformationRegister.AssetActivityRecords AS FAGeneration
	|		ON FAGeneration.Asset = ListOfFA.FixedAsset
	|			AND FAGeneration.RunningTimeValue = ListOfFA.RunningTimeValue
	|			AND FAGeneration.Period = ListOfFA.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FAGeneration_AsOfLastMAChangeDate_Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FAGeneration_AsOfLastACChangeDate_Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FAGeneration.Asset AS FixedAsset,
	|	FAGeneration.RunningTimeValue AS RunningTimeValue,
	|	FAGeneration.Value AS OutputVolume
	|
	|INTO OS_OutputAtBeginningOfMonth
	|
	|FROM
	|	InformationRegister.AssetActivityRecords.SliceLast(
	|			&EndOfPreviousMonth,
	|			Asset IN
	|				(SELECT
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfOS_Production AS ListOfFA)) AS FAGeneration
	|
	|INDEX BY
	|	FixedAsset,
	|	RunningTimeValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FAGeneration.Asset AS FixedAsset,
	|	FAGeneration.RunningTimeValue AS RunningTimeValue,
	|	FAGeneration.Value AS OutputVolume,
	|	ListOfFA.TakenIntoAccountLastMonth AS TakenIntoAccountLastMonth
	|
	|INTO OS_OutputAtEndOfMonth
	|
	|FROM
	|	InformationRegister.AssetActivityRecords.SliceLast(
	|			&EndOfMonth,
	|			Asset IN
	|				(SELECT
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfOS_Production AS ListOfFA)) AS FAGeneration
	|
	|		LEFT JOIN ListOfOS_Production AS ListOfFA
	|		ON (ListOfFA.FixedAsset = FAGeneration.Asset)
	|
	|INDEX BY
	|	FixedAsset,
	|	RunningTimeValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	FAGeneration.FixedAsset AS FixedAsset,
	|	FAGeneration.RunningTimeValue AS RunningTimeValue,
	|
	|	SUM(FAGeneration.OutputVolumePerMonth) AS OutputVolumePerMonth,
	|	SUM(FAGeneration.VolumeOfOutputForPreviousPeriod) AS VolumeOfOutputForPreviousPeriod
	|
	|INTO FAGeneration
	|
	|FROM
	|	(SELECT
	|		FAGeneration.FixedAsset AS FixedAsset,
	|		FAGeneration.RunningTimeValue AS RunningTimeValue,
	|
	|		-FAGeneration.OutputVolume AS OutputVolumePerMonth,
	|		FAGeneration.OutputVolume AS VolumeOfOutputForPreviousPeriod
	|	FROM
	|		OS_OutputAtBeginningOfMonth AS FAGeneration
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		FAGeneration.FixedAsset,
	|		FAGeneration.RunningTimeValue AS RunningTimeValue,
	|
	|		FAGeneration.OutputVolume AS OutputVolumePerMonth,
	|		0 AS VolumeOfOutputForPreviousPeriod
	|	FROM
	|		OS_OutputAtEndOfMonth AS FAGeneration
	|
	|	) AS FAGeneration
	|
	|GROUP BY
	|	FAGeneration.FixedAsset,
	|	FAGeneration.RunningTimeValue
	|
	|INDEX BY
	|	FixedAsset,
	|	RunningTimeValue";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangesTo_Y
			
	#Region ChangingParameters
	QueryText =
	// FixedAssetsAccountingProcedure
	"SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.LastChangeDate AS LastChangeDate,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeMonths,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS EstimatedRunningTime,
	|	RegisterData.AccelerationFactor,
	|	RegisterData.DepreciationMethod,
	|	RegisterData.ResidualValueMan,
	|	RegisterData.ResidualValueLocal
	|
	|INTO DepreciationParametersOfOSUU_Changes
	|
	|FROM
	|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|	AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation
	|
	|	AND RegisterData.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.LastChangeDate AS LastChangeDate,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeMonths,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS EstimatedRunningTime,
	|	RegisterData.AccelerationFactor,
	|	RegisterData.DepreciationMethod,
	|	RegisterData.ResidualValueMan,
	|	RegisterData.ResidualValueLocal
	|FROM
	|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting AS RegisterData
	|
	|		INNER JOIN ListOfAccountingItems_AdditionalCharges_u AS AdditionalCharges
	|		ON RegisterData.FixedAsset = AdditionalCharges.FixedAsset
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// FixedAssetsAccountingProcedure
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.RunningTimeValue,
	|	RegisterData.EstimatedRunningTime
	|
	|INTO AccountingProcedureForOS_MaChanges
	|
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|	AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation
	|
	|	AND RegisterData.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.RunningTimeValue,
	|	RegisterData.EstimatedRunningTime
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure AS RegisterData
	|
	|		INNER JOIN ListOfAccountingItems_AdditionalCharges_u AS AdditionalCharges
	|		ON RegisterData.FixedAsset = AdditionalCharges.FixedAsset
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// FixedAssetsAccountingProcedureManagementAccounting
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.State,
	|	RegisterData.AccrueDepreciationOrAmortization,
	|	RegisterData.DepreciationRecordMethod,
	|	RegisterData.ExpenseItem,
	|	RegisterData.DimensionOfExpenses,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.TransferExpensesToAnotherCompany,
	|	RegisterData.CompanyRecipientOfExpenses
	|
	|INTO AccountingProcedureForOSUU_Changes
	|
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|	AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation
	|
	|	AND RegisterData.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.State,
	|	RegisterData.AccrueDepreciationOrAmortization,
	|	RegisterData.DepreciationRecordMethod,
	|	RegisterData.ExpenseItem,
	|	RegisterData.DimensionOfExpenses,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.TransferExpensesToAnotherCompany,
	|	RegisterData.CompanyRecipientOfExpenses
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS RegisterData
	|
	|		INNER JOIN ListOfAccountingItems_AdditionalCharges_u AS AdditionalCharges
	|		ON RegisterData.FixedAsset = AdditionalCharges.FixedAsset
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// FALocation
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.FixedAssetsLocation
	|
	|INTO LocationOfOS_MaChanges
	|
	|FROM
	|	InformationRegister.FALocation AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|	AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation
	|
	|	AND RegisterData.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangeInValue
	QueryText =
	"SELECT
	|	FACost.BegOfMonth AS BegOfMonth,
	|	FACost.ParameterPeriod AS ParameterPeriod,
	|	FACost.Period AS Period,
	|	FACost.Recorder AS Recorder,
	|	FACost.FixedAsset AS FixedAsset,
	|	FACost.Organization AS Organization,
	|
	|	SUM(FACost.Cost) AS Cost,
	|	SUM(FACost.LocalCost) AS LocalCost
	|
	|INTO CostOfOS_MaChanges
	|
	|FROM
	|	(SELECT
	|		&BegOfMonth AS BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date AS Period,
	|		DocumentData.Ref AS Recorder,
	|		FATable.FixedAsset AS FixedAsset,
	|		DocumentData.Organization AS Organization,
	|		FATable.CostInManagementAccounting AS Cost,
	|		FATable.CostInAccounting AS LocalCost
	|	FROM
	|		Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|
	|			INNER JOIN Document.FixedAssetsCostAdditions2_4.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInManAccounting
	|		AND NOT DocumentData.WriteOffAppreciationCosts
	|
	|		AND FATable.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth AS BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date AS Period,
	|		DocumentData.Ref AS Recorder,
	|		FATable.FixedAsset AS FixedAsset,
	|		DocumentData.Organization AS Organization,
	|		FATable.AmountOfUU AS Cost,
	|		FATable.AmountAccounting AS LocalCost
	|	FROM
	|		Document.AllocateVariancesToFixedAssetCost AS DocumentData
	|
	|			INNER JOIN Document.AllocateVariancesToFixedAssetCost.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInManAccounting
	|		AND NOT DocumentData.WriteOffVariancesAsExpenses
	|
	|		AND FATable.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		FATable.FixedAsset,
	|		DocumentData.Organization,
	|		-FATable.AmountManagementAccounting,
	|		-FATable.ChargeAmountAccounting
	|	FROM
	|		Document.DisposeFixedAssets2_4 AS DocumentData
	|
	|			INNER JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInManAccounting
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|		AND FATable.AmountManagementAccounting <> 0
	|
	|		AND FATable.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		DocumentData.FixedAsset,
	|		DocumentData.Organization,
	|		-SUM(FATable.CostInManagementAccounting),
	|		-SUM(FATable.CostInAccounting)
	|	FROM
	|		Document.SplitFixedAssets AS DocumentData
	|
	|			INNER JOIN Document.SplitFixedAssets.FA AS FATable
	|			ON (FATable.Ref = DocumentData.Ref)
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInManAccounting
	|		AND DocumentData.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit), 
	|				VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation))
	|
	|		AND FATable.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	GROUP BY
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		DocumentData.FixedAsset,
	|		DocumentData.Organization
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		FATable.FixedAsset,
	|		DocumentData.Organization,
	|		FATable.CostInManagementAccounting,
	|		FATable.CostInAccounting
	|	FROM
	|		Document.FARevaluation2_4 AS DocumentData
	|
	|			INNER JOIN Document.FARevaluation2_4.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInManAccounting
	|		AND FATable.CostInManagementAccounting <> 0
	|
	|		AND FATable.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		FATable.FixedAsset,
	|		DocumentData.Organization,
	|		FATable.CostInManagementAccounting,
	|		FATable.CostInAccounting
	|	FROM
	|		Document.LeaseTermAdjustment AS DocumentData
	|
	|			INNER JOIN Document.LeaseTermAdjustment.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND FATable.CostInManagementAccounting <> 0
	|
	|		AND FATable.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		FATable.FixedAsset,
	|		DocumentData.Organization,
	|		FATable.CostInManagementAccounting,
	|		FATable.CostInAccounting
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInManAccounting
	|		AND FATable.CostInManagementAccounting <> 0
	|
	|		AND FATable.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		FACost.Period,
	|		FACost.Recorder,
	|		FACost.FixedAsset,
	|		FACost.Organization,
	|		FACost.Cost,
	|		FACost.LocalCost
	|	FROM
	|		AccumulationRegister.FACost AS FACost
	|
	|	WHERE
	|		FACost.Active
	|		AND FACost.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND FACost.Recorder REFS Document.FutureExpenseCommitmentsAccrualWriteOff
	|		AND FACost.Cost <> 0
	|
	|		AND (FACost.Organization, FACost.FixedAsset) IN
	|			(SELECT
	|				ListOfFA.Organization,
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		InvestmentInRent.Period,
	|		InvestmentInRent.Ref,
	|		InvestmentInRent.FixedAsset,
	|		InvestmentInRent.Organization,
	|		InvestmentInRent.Cost,
	|		InvestmentInRent.LocalCost
	|	FROM
	|		InvestmentInRent AS InvestmentInRent
	|
	|	WHERE
	|		InvestmentInRent.RecordInManAccounting
	|		AND InvestmentInRent.Cost <> 0
	|
	|		AND InvestmentInRent.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	) AS FACost
	|
	|GROUP BY
	|	FACost.BegOfMonth,
	|	FACost.ParameterPeriod,
	|	FACost.Period,
	|	FACost.Recorder,
	|	FACost.FixedAsset,
	|	FACost.Organization
	|
	|HAVING
	|	(SUM(FACost.Cost) <> 0
	|		OR SUM(FACost.LocalCost) <> 0)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangeInDepreciation
	QueryText =
	"SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	Adjusting.Date AS Period,
	|	Adjusting.Ref AS Recorder,
	|	Adjusting.Organization AS Organization,
	|	Adjusting.FixedAsset AS FixedAsset,
	|
	|	SUM(Adjusting.DepreciationManagementAccounting) AS Depreciation,
	|	SUM(Adjusting.DepreciationInAccounting) AS DepreciationLocal
	|
	|INTO DepreciationOfOS_MaChanges
	|
	|FROM
	|	(SELECT
	|		Adjusting.Date AS Date,
	|		Adjusting.Ref AS Ref,
	|		Adjusting.Organization AS Organization,
	|		FATable.FixedAsset AS FixedAsset,
	|
	|		FATable.DepreciationManagementAccounting AS DepreciationManagementAccounting,
	|		FATable.DepreciationInAccounting AS DepreciationInAccounting
	|
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|			ON (FATable.Ref = Adjusting.Ref)
	|
	|	WHERE
	|		Adjusting.Posted
	|		AND Adjusting.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND Adjusting.RecordInManAccounting
	|
	|		AND FATable.DepreciationManagementAccounting <> 0
	|
	|		AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					ListOfAccountingObjects_ AS ListOfFA
	|				WHERE
	|					ListOfFA.BegOfMonth = &BegOfMonth
	|					AND ListOfFA.FixedAsset = FATable.FixedAsset
	|					AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&BegOfMonth AS Date,
	|		VALUE(Document.FixedAssetCostAndDepreciationAdjustment.EmptyRef) AS Ref,
	|		DepreciationAdjustmentForPreviousPeriod.Organization AS Organization,
	|		DepreciationAdjustmentForPreviousPeriod.FixedAsset AS FixedAsset,
	|
	|		CASE
	|			WHEN DepreciationAdjustmentForPreviousPeriod.AmountOfUU > 0
	|				THEN DepreciationAdjustmentForPreviousPeriod.AmountOfUU 
	|			ELSE 0
	|		END AS DepreciationManagementAccounting,
	|
	|		CASE
	|			WHEN (DepreciationAdjustmentForPreviousPeriod.AmountAccounting + DepreciationAdjustmentForPreviousPeriod.CFAmount) > 0
	|				THEN DepreciationAdjustmentForPreviousPeriod.AmountAccounting + DepreciationAdjustmentForPreviousPeriod.CFAmount 
	|			ELSE 0
	|		END AS DepreciationInAccounting
	|
	|	FROM
	|		DepreciationAdjustmentForPreviousPeriod AS DepreciationAdjustmentForPreviousPeriod
	|
	|	WHERE
	|		DepreciationAdjustmentForPreviousPeriod.AmountOfUU > 0
	|			OR (DepreciationAdjustmentForPreviousPeriod.AmountAccounting + DepreciationAdjustmentForPreviousPeriod.CFAmount) > 0
	|
	|	) AS Adjusting
	|
	|GROUP BY
	|	Adjusting.Date,
	|	Adjusting.Ref,
	|	Adjusting.FixedAsset,
	|	Adjusting.Organization
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region MergingAllChanges
	QueryText =
	"SELECT
	|	ChangesTable.BegOfMonth AS BegOfMonth,
	|	ChangesTable.ParameterPeriod AS ParameterPeriod,
	|	ChangesTable.Recorder AS Recorder,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.FixedAsset AS FixedAsset,
	|	MAX(ChangesTable.Period) AS Period,
	|	MAX(BEGINOFPERIOD(DATEADD(ChangesTable.Period, MONTH, 1), MONTH)) AS BeginningOfNextMonth,
	|	MAX(OrderOfAccountingOfOS_Last.Period) AS AccountingProcedureOS_LatestPeriod,
	|	MAX(OrderOfAccountingOSUU_Last.Period) AS AccountingProcedureForOSUU_LatestPeriod,
	|	MAX(ParametersOfDepreciationOfOSUU_Latest.Period) AS ParametersOfDepreciationOSUU_LastPeriod,
	|	MAX(LocationOfOS_Last.Period) AS OS_LocationLastPeriod
	|
	|INTO ChangesTableMA
	|
	|FROM
	|	(SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period AS Period,
	|		ChangesTable.FixedAsset AS FixedAsset,
	|		ChangesTable.Organization AS Organization
	|	FROM
	|		DepreciationParametersOfOSUU_Changes AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		AccountingProcedureForOS_MaChanges AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		AccountingProcedureForOSUU_Changes AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		LocationOfOS_MaChanges AS ChangesTable
	|
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		CostOfOS_MaChanges AS ChangesTable
	|
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		DepreciationOfOS_MaChanges AS ChangesTable
	|
	|	) AS ChangesTable
	|
	|		LEFT JOIN DepreciationParametersOfOSUU_Changes AS ParametersOfDepreciationOfOSUU_Latest
	|		ON (ParametersOfDepreciationOfOSUU_Latest.Organization = ChangesTable.Organization)
	|			AND (ParametersOfDepreciationOfOSUU_Latest.FixedAsset = ChangesTable.FixedAsset)
	|			AND (ParametersOfDepreciationOfOSUU_Latest.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (ParametersOfDepreciationOfOSUU_Latest.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN AccountingProcedureForOS_MaChanges AS OrderOfAccountingOfOS_Last
	|		ON (OrderOfAccountingOfOS_Last.FixedAsset = ChangesTable.FixedAsset)
	|			AND (OrderOfAccountingOfOS_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (OrderOfAccountingOfOS_Last.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN AccountingProcedureForOSUU_Changes AS OrderOfAccountingOSUU_Last
	|		ON (OrderOfAccountingOSUU_Last.Organization = ChangesTable.Organization)
	|			AND (OrderOfAccountingOSUU_Last.FixedAsset = ChangesTable.FixedAsset)
	|			AND (OrderOfAccountingOSUU_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (OrderOfAccountingOSUU_Last.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN LocationOfOS_MaChanges AS LocationOfOS_Last
	|		ON (LocationOfOS_Last.Organization = ChangesTable.Organization)
	|			AND (LocationOfOS_Last.FixedAsset = ChangesTable.FixedAsset)
	|			AND (LocationOfOS_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (LocationOfOS_Last.Period <= ChangesTable.Period)
	|
	|GROUP BY
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.ParameterPeriod,
	|	ChangesTable.Recorder,
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset,
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.Recorder,
	|	MIN(TableOfChangesIsAsFollows.Period) AS PeriodFollowing
	|
	|INTO TableOfChangesIsAsFollows
	|
	|FROM
	|	ChangesTableMA AS ChangesTable
	|
	|		LEFT JOIN ChangesTableMA AS TableOfChangesIsAsFollows
	|		ON (TableOfChangesIsAsFollows.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesIsAsFollows.FixedAsset = ChangesTable.FixedAsset)
	|			AND (TableOfChangesIsAsFollows.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (TableOfChangesIsAsFollows.Period > ChangesTable.Period
	|				OR TableOfChangesIsAsFollows.Period = ChangesTable.Period
	|						AND TableOfChangesIsAsFollows.Recorder > ChangesTable.Recorder)
	|
	|GROUP BY
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.Recorder,
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset,
	|	MIN(ChangesTable.Period) AS PeriodFollowing
	|
	|INTO TableOfChangesThisMonth
	|
	|FROM
	|	ChangesTableMA AS ChangesTable
	|WHERE
	|	(ChangesTable.BegOfMonth = &BegOfMonth)
	|
	|GROUP BY
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangesTo_Y
	QueryText =
	"SELECT
	|	ChangesTable.BegOfMonth AS BegOfMonth,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, MONTH) = ChangesTable.BegOfMonth
	|				AND NOT LastModifiedDates.AdjustmentModeFromPreviousDate
	|			THEN BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, DAY)
	|		ELSE ChangesTable.ParameterPeriod 
	|	END AS ParameterPeriod,
	|
	|	ENDOFPERIOD(ChangesTable.BegOfMonth, MONTH) AS EndOfMonth,
	|	ENDOFPERIOD(ChangesTable.Period, DAY) AS ChangesDate,
	|	ChangesTable.Recorder AS Recorder,
	|	ISNULL(DocumentsRegistry.BusinessOperation, UNDEFINED) AS BusinessOperation,
	|
	|	(NOT MergeOfFixedAssets.Ref IS NULL
	|		OR NOT SplitFixedAssets.Ref IS NULL) AS ObtainedByDisassemblyCombining,
	|
	|	CASE 
	|		WHEN ChangesTable.BegOfMonth = &BeginningOfPreviousMonth
	|
	|			THEN CASE
	|					WHEN BEGINOFPERIOD(ISNULL(TableOfChangesThisMonth.PeriodFollowing, &EndOfMonth), DAY) = &BegOfMonth
	|						THEN &BegOfMonth 
	|					ELSE ISNULL(DATEADD(TableOfChangesThisMonth.PeriodFollowing, DAY, -1), &EndOfMonth)
	|				END
	| 
	|		WHEN BEGINOFPERIOD(ISNULL(TableOfChangesIsAsFollows.PeriodFollowing, &EndOfMonth), DAY) = &BegOfMonth
	|
	|			THEN &BegOfMonth
	| 
	|		ELSE ISNULL(DATEADD(TableOfChangesIsAsFollows.PeriodFollowing, DAY, -1), &EndOfMonth)
	| 
	|	END AS Period,
	|
	|	DATEDIFF(ChangesTable.Period, ISNULL(TableOfChangesIsAsFollows.PeriodFollowing, ChangesTable.BeginningOfNextMonth), DAY) AS ValidityPeriod,
	|	ChangesTable.FixedAsset AS FixedAsset,
	|	ChangesTable.Organization AS Organization,
	|	ISNULL(CostFAChanges.Cost, 0) AS CostUpdate, // Change in the cost of the document
	|	ISNULL(CostFAChanges.LocalCost, 0) AS LocalCostUpdate, // Change in the cost of the document
	|	ISNULL(FADepreciationChanges.Depreciation, 0) AS DepreciationUpdate, // Change in depreciation by document
	|	ISNULL(FADepreciationChanges.DepreciationLocal, 0) AS DepreciationLocalUpdate, // Change in depreciation by document
	|	ParametersOfDepreciationOfOSUU_Latest.LastChangeDate AS LastChangeDate,
	|	ParametersOfDepreciationOfOSUU_Latest.UsefulLifeMonths AS UsefulLifeMonths,
	|	ParametersOfDepreciationOfOSUU_Latest.EstimatedRunningTime AS EstimatedRunningTime,
	|	ParametersOfDepreciationOfOSUU_Latest.AccelerationFactor AS AccelerationFactor,
	|	ParametersOfDepreciationOfOSUU_Latest.DepreciationMethod AS DepreciationMethod,
	|	ParametersOfDepreciationOfOSUU_Latest.ResidualValueMan AS ResidualValueMan,
	|	ParametersOfDepreciationOfOSUU_Latest.ResidualValueLocal AS ResidualValueLocal,
	|	OrderOfAccountingOfOS_Last.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	OrderOfAccountingOfOS_Last.LineOfBusiness AS LineOfBusiness,
	|	OrderOfAccountingOfOS_Last.RunningTimeValue AS RunningTimeValue,
	|	OrderOfAccountingOSUU_Last.State,
	|	OrderOfAccountingOSUU_Last.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|
	|	CASE
	|		WHEN ChangesTable.FixedAsset.OSType = VALUE(Enum.FATypes.GroupFA)
	|				AND ISNULL(OrderOfAccountingOSUU_Last.DepreciationRecordMethod, UNDEFINED) IN (&EmptyWaysToReflectDepreciation)
	|			THEN ChangesTable.FixedAsset
	|		ELSE OrderOfAccountingOSUU_Last.DepreciationRecordMethod
	|	END AS DepreciationRecordMethod,
	|
	|	OrderOfAccountingOSUU_Last.ExpenseItem AS ExpenseItem,
	|	OrderOfAccountingOSUU_Last.DimensionOfExpenses AS DimensionOfExpenses,
	|	OrderOfAccountingOSUU_Last.Department AS ExpensesBusinessUnit,
	|	OrderOfAccountingOSUU_Last.LineOfBusiness AS ExpenseLineOfBusiness,
	|	OrderOfAccountingOSUU_Last.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	OrderOfAccountingOSUU_Last.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	LocationOfOS_Last.FixedAssetsLocation AS FixedAssetsLocation
	|
	|INTO ChangesTo_Y
	|
	|FROM
	|	ChangesTableMA AS ChangesTable
	|
	|		LEFT JOIN TableOfChangesIsAsFollows AS TableOfChangesIsAsFollows
	|		ON (TableOfChangesIsAsFollows.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesIsAsFollows.FixedAsset = ChangesTable.FixedAsset)
	|			AND (TableOfChangesIsAsFollows.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (TableOfChangesIsAsFollows.Recorder = ChangesTable.Recorder)
	|
	|		LEFT JOIN TableOfChangesThisMonth AS TableOfChangesThisMonth
	|		ON (TableOfChangesThisMonth.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesThisMonth.FixedAsset = ChangesTable.FixedAsset)
	|
	|		LEFT JOIN DatesWhenMaWasLastModified AS LastModifiedDates
	|		ON (LastModifiedDates.Organization = ChangesTable.Organization)
	|			AND (LastModifiedDates.FixedAsset = ChangesTable.FixedAsset)
	|			AND (LastModifiedDates.BegOfMonth = ChangesTable.BegOfMonth)
	|
	|		LEFT JOIN DepreciationParametersOfOSUU_Changes AS ParametersOfDepreciationOfOSUU_Latest
	|			LEFT JOIN DepreciationParametersOfOSUU_Changes AS OsuuDepreciationParametersAreAsFollows
	|			ON (OsuuDepreciationParametersAreAsFollows.Organization = ParametersOfDepreciationOfOSUU_Latest.Organization)
	|				AND (OsuuDepreciationParametersAreAsFollows.FixedAsset = ParametersOfDepreciationOfOSUU_Latest.FixedAsset)
	|				AND (OsuuDepreciationParametersAreAsFollows.BegOfMonth = ParametersOfDepreciationOfOSUU_Latest.BegOfMonth)
	|				AND (OsuuDepreciationParametersAreAsFollows.Period = ParametersOfDepreciationOfOSUU_Latest.Period)
	|				AND (OsuuDepreciationParametersAreAsFollows.PointInTime > ParametersOfDepreciationOfOSUU_Latest.PointInTime)
	|		ON (ParametersOfDepreciationOfOSUU_Latest.Organization = ChangesTable.Organization)
	|			AND (ParametersOfDepreciationOfOSUU_Latest.FixedAsset = ChangesTable.FixedAsset)
	|			AND (ParametersOfDepreciationOfOSUU_Latest.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (ParametersOfDepreciationOfOSUU_Latest.Period = ChangesTable.ParametersOfDepreciationOSUU_LastPeriod)
	|			AND (OsuuDepreciationParametersAreAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN AccountingProcedureForOS_MaChanges AS OrderOfAccountingOfOS_Last
	|			LEFT JOIN AccountingProcedureForOS_MaChanges AS AccountingProcedureForFAChangesIsAsFollows
	|			ON (AccountingProcedureForFAChangesIsAsFollows.Organization = OrderOfAccountingOfOS_Last.Organization)
	|				AND (AccountingProcedureForFAChangesIsAsFollows.FixedAsset = OrderOfAccountingOfOS_Last.FixedAsset)
	|				AND (AccountingProcedureForFAChangesIsAsFollows.BegOfMonth = OrderOfAccountingOfOS_Last.BegOfMonth)
	|				AND (AccountingProcedureForFAChangesIsAsFollows.Period = OrderOfAccountingOfOS_Last.Period)
	|				AND (AccountingProcedureForFAChangesIsAsFollows.PointInTime > OrderOfAccountingOfOS_Last.PointInTime)
	|		ON (OrderOfAccountingOfOS_Last.FixedAsset = ChangesTable.FixedAsset)
	|			AND (OrderOfAccountingOfOS_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (OrderOfAccountingOfOS_Last.Period = ChangesTable.AccountingProcedureOS_LatestPeriod)
	|			AND (AccountingProcedureForFAChangesIsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN AccountingProcedureForOSUU_Changes AS OrderOfAccountingOSUU_Last
	|			LEFT JOIN AccountingProcedureForOSUU_Changes AS OrderOfAccountingForOsuuChangesIsAsFollows
	|			ON (OrderOfAccountingForOsuuChangesIsAsFollows.Organization = OrderOfAccountingOSUU_Last.Organization)
	|				AND (OrderOfAccountingForOsuuChangesIsAsFollows.FixedAsset = OrderOfAccountingOSUU_Last.FixedAsset)
	|				AND (OrderOfAccountingForOsuuChangesIsAsFollows.BegOfMonth = OrderOfAccountingOSUU_Last.BegOfMonth)
	|				AND (OrderOfAccountingForOsuuChangesIsAsFollows.Period = OrderOfAccountingOSUU_Last.Period)
	|				AND (OrderOfAccountingForOsuuChangesIsAsFollows.PointInTime > OrderOfAccountingOSUU_Last.PointInTime)
	|		ON (OrderOfAccountingOSUU_Last.Organization = ChangesTable.Organization)
	|			AND (OrderOfAccountingOSUU_Last.FixedAsset = ChangesTable.FixedAsset)
	|			AND (OrderOfAccountingOSUU_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (OrderOfAccountingOSUU_Last.Period = ChangesTable.AccountingProcedureForOSUU_LatestPeriod)
	|			AND (OrderOfAccountingForOsuuChangesIsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN LocationOfOS_MaChanges AS LocationOfOS_Last
	|			LEFT JOIN LocationOfOS_MaChanges AS FALocationIsAsFollows
	|			ON (FALocationIsAsFollows.Organization = LocationOfOS_Last.Organization)
	|				AND (FALocationIsAsFollows.FixedAsset = LocationOfOS_Last.FixedAsset)
	|				AND (FALocationIsAsFollows.BegOfMonth = LocationOfOS_Last.BegOfMonth)
	|				AND (FALocationIsAsFollows.Period = LocationOfOS_Last.Period)
	|				AND (FALocationIsAsFollows.PointInTime > LocationOfOS_Last.PointInTime)
	|		ON (LocationOfOS_Last.Organization = ChangesTable.Organization)
	|			AND (LocationOfOS_Last.FixedAsset = ChangesTable.FixedAsset)
	|			AND (LocationOfOS_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (LocationOfOS_Last.Period = ChangesTable.OS_LocationLastPeriod)
	|			AND (FALocationIsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN CostOfOS_MaChanges AS CostFAChanges
	|		ON (CostFAChanges.Organization = ChangesTable.Organization)
	|			AND (CostFAChanges.FixedAsset = ChangesTable.FixedAsset)
	|			AND (CostFAChanges.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (CostFAChanges.Recorder = ChangesTable.Recorder)
	|
	|		LEFT JOIN DepreciationOfOS_MaChanges AS FADepreciationChanges
	|		ON (FADepreciationChanges.Organization = ChangesTable.Organization)
	|			AND (FADepreciationChanges.FixedAsset = ChangesTable.FixedAsset)
	|			AND (FADepreciationChanges.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (FADepreciationChanges.Recorder = ChangesTable.Recorder)
	|
	|		LEFT JOIN Document.MergeOfFixedAssets AS MergeOfFixedAssets
	|		ON (MergeOfFixedAssets.Ref = ChangesTable.Recorder)
	|			AND (MergeOfFixedAssets.FixedAsset = ChangesTable.FixedAsset)
	|
	|		LEFT JOIN Document.SplitFixedAssets.FA AS SplitFixedAssets
	|		ON (SplitFixedAssets.Ref = ChangesTable.Recorder)
	|			AND (SplitFixedAssets.FixedAsset = ChangesTable.FixedAsset)
	|
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON (DocumentsRegistry.Ref = ChangesTable.Recorder)
	|			AND (NOT DocumentsRegistry.AdditionalRecord)
	|";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#EndRegion
	
	#Region ChangesTo_BU_M
		
	#Region ChangingParameters
	QueryText =
	// OSBUDepreciationParameters
	"SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime AS PointInTime,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.FixedAsset AS FixedAsset,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.LastChangeDate AS LastChangeDate,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeMonths,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS EstimatedRunningTime,
	|	RegisterData.AccelerationFactor AS AccelerationFactor,
	|	RegisterData.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
	|	RegisterData.ResidualValueMan AS ResidualValueMan
	|
	|INTO OSBU_ChangeDepreciationParameters_BU_M
	|
	|FROM
	|	InformationRegister.OSBUDepreciationParameters AS RegisterData
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1, 1, 1)
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|	AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation
	|
	|	AND RegisterData.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime AS PointInTime,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.FixedAsset AS FixedAsset,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.LastChangeDate AS LastChangeDate,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeMonths,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS EstimatedRunningTime,
	|	RegisterData.AccelerationFactor AS AccelerationFactor,
	|	RegisterData.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
	|	RegisterData.ResidualValueMan AS ResidualValueMan
	|FROM
	|	InformationRegister.OSBUDepreciationParameters AS RegisterData
	|
	|		INNER JOIN ListOfAccountingObjects_AdditionalCharge_BU_MU AS AdditionalCharges
	|		ON RegisterData.FixedAsset = AdditionalCharges.FixedAsset
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// FixedAssetsAccountingProcedure
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.RunningTimeValue,
	|	RegisterData.EstimatedRunningTime
	|
	|INTO AccountingProcedureForOS_Changes_BU_M
	|
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|	AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|
	|	AND RegisterData.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.RunningTimeValue,
	|	RegisterData.EstimatedRunningTime
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure AS RegisterData
	|
	|		INNER JOIN ListOfAccountingObjects_AdditionalCharge_BU_MU AS AdditionalCharges
	|		ON RegisterData.FixedAsset = AdditionalCharges.FixedAsset
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// AccountingProcedureForOSBU
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.BUState,
	|	RegisterData.DepreciationAccrualAccounting,
	|	RegisterData.DepreciationRecordMethodLA,
	|	RegisterData.ExpenseItemAccounting,
	|	RegisterData.ExpensesDimensionAccounting,
	|	RegisterData.DepartmentACC,
	|	RegisterData.LineOfBusinessBookkeeping,
	|	RegisterData.TransferExpensesToAnotherCompany,
	|	RegisterData.CompanyRecipientOfExpenses
	|
	|INTO AccountingProcedureForOSBU_Changes_BU_M
	|
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU AS RegisterData
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|	AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation
	|
	|	AND RegisterData.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.BUState,
	|	RegisterData.DepreciationAccrualAccounting,
	|	RegisterData.DepreciationRecordMethodLA,
	|	RegisterData.ExpenseItemAccounting,
	|	RegisterData.ExpensesDimensionAccounting,
	|	RegisterData.DepartmentACC,
	|	RegisterData.LineOfBusinessBookkeeping,
	|	RegisterData.TransferExpensesToAnotherCompany,
	|	RegisterData.CompanyRecipientOfExpenses
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU AS RegisterData
	|
	|		INNER JOIN ListOfAccountingObjects_AdditionalCharge_BU_MU AS AdditionalCharges
	|		ON RegisterData.FixedAsset = AdditionalCharges.FixedAsset
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// InitialFixedAssetsInformation
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.DepreciationMethodAccounting
	|
	|INTO InitialInformationOS_Changes_BU_M
	|
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation AS RegisterData
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|	AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation
	|
	|	AND RegisterData.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.DepreciationMethodAccounting
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation AS RegisterData
	|
	|		INNER JOIN ListOfAccountingObjects_AdditionalCharge_BU_MU AS AdditionalCharges
	|		ON RegisterData.FixedAsset = AdditionalCharges.FixedAsset
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// FALocation
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	RegisterData.Period AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.FixedAsset,
	|	RegisterData.Organization,
	|	RegisterData.FixedAssetsLocation
	|
	|INTO LocationOfOS_Changes_BU_M
	|
	|FROM
	|	InformationRegister.FALocation AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|	AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation
	|	AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|
	|	AND RegisterData.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangeInValue
	QueryText =
	"SELECT
	|	FACost.BegOfMonth AS BegOfMonth,
	|	FACost.ParameterPeriod AS ParameterPeriod,
	|	FACost.Period AS Period,
	|	FACost.Recorder AS Recorder,
	|	FACost.FixedAsset AS FixedAsset,
	|	FACost.Organization AS Organization,
	|	SUM(FACost.LocalCost) AS LocalCost
	|
	|INTO CostOfOS_Change_BU_M
	|
	|FROM
	|	(SELECT
	|		&BegOfMonth AS BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date AS Period,
	|		DocumentData.Ref AS Recorder,
	|		FATable.FixedAsset AS FixedAsset,
	|		DocumentData.Organization AS Organization,
	|		FATable.CostInAccounting AS LocalCost
	|	FROM
	|		Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|
	|			INNER JOIN Document.FixedAssetsCostAdditions2_4.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		&ThisIsInternationalVersion
	|		AND DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInLocalAccounting
	|		AND NOT DocumentData.WriteOffAppreciationCosts
	|
	|		AND FATable.FixedAsset IN
	|				(SELECT
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfAccountingObjects_BU_MU AS ListOfFA
	|				WHERE
	|					ListOfFA.BegOfMonth = &BegOfMonth
	|					AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth AS BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date AS Period,
	|		DocumentData.Ref AS Recorder,
	|		FATable.FixedAsset AS FixedAsset,
	|		DocumentData.Organization AS Organization,
	|		FATable.AmountAccounting AS LocalCost
	|	FROM
	|		Document.AllocateVariancesToFixedAssetCost AS DocumentData
	|
	|			INNER JOIN Document.AllocateVariancesToFixedAssetCost.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		&ThisIsInternationalVersion
	|		AND DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInLocalAccounting
	|		AND NOT DocumentData.WriteOffVariancesAsExpenses
	|
	|		AND FATable.FixedAsset IN
	|				(SELECT
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfAccountingObjects_BU_MU AS ListOfFA
	|				WHERE
	|					ListOfFA.BegOfMonth = &BegOfMonth
	|					AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		FATable.FixedAsset,
	|		DocumentData.Organization,
	|		-FATable.ChargeAmountAccounting
	|	FROM
	|		Document.DisposeFixedAssets2_4 AS DocumentData
	|
	|			INNER JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|	WHERE
	|		&ThisIsInternationalVersion
	|		AND DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInLocalAccounting
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|		AND FATable.AmountManagementAccounting <> 0
	|
	|		AND FATable.FixedAsset IN
	|				(SELECT
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfAccountingObjects_BU_MU AS ListOfFA
	|				WHERE
	|					ListOfFA.BegOfMonth = &BegOfMonth
	|					AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		DocumentData.FixedAsset,
	|		DocumentData.Organization,
	|		-SUM(FATable.CostInAccounting)
	|	FROM
	|		Document.SplitFixedAssets AS DocumentData
	|
	|			INNER JOIN Document.SplitFixedAssets.FA AS FATable
	|			ON (FATable.Ref = DocumentData.Ref)
	|	WHERE
	|		&ThisIsInternationalVersion
	|		AND DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInLocalAccounting
	|
	|		AND DocumentData.BusinessOperation IN(
	|			VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit),
	|			VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation))
	|
	|		AND FATable.FixedAsset IN
	|				(SELECT
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfAccountingObjects_BU_MU AS ListOfFA
	|				WHERE
	|					ListOfFA.BegOfMonth = &BegOfMonth
	|					AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	GROUP BY
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		DocumentData.FixedAsset,
	|		DocumentData.Organization
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		FATable.FixedAsset,
	|		DocumentData.Organization,
	|		FATable.CostInAccounting
	|	FROM
	|		Document.FARevaluation2_4 AS DocumentData
	|
	|			INNER JOIN Document.FARevaluation2_4.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|	WHERE
	|		&ThisIsInternationalVersion
	|		AND DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.RecordInLocalAccounting
	|		AND FATable.CostInManagementAccounting <> 0
	|
	|		AND FATable.FixedAsset IN
	|				(SELECT
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfAccountingObjects_BU_MU AS ListOfFA
	|				WHERE
	|					ListOfFA.BegOfMonth = &BegOfMonth
	|					AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		DocumentData.Date,
	|		DocumentData.Ref,
	|		FATable.FixedAsset,
	|		DocumentData.Organization,
	|		FATable.CostInAccounting
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|	WHERE
	|		&ThisIsInternationalVersion
	|		AND DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.PostInAccounting
	|		AND FATable.CostInManagementAccounting <> 0
	|
	|		AND FATable.FixedAsset IN
	|				(SELECT
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfAccountingObjects_BU_MU AS ListOfFA
	|				WHERE
	|					ListOfFA.BegOfMonth = &BegOfMonth
	|					AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		FACost.Period,
	|		FACost.Recorder,
	|		FACost.FixedAsset,
	|		FACost.Organization,
	|		FACost.LocalCost
	|	FROM
	|		AccumulationRegister.FACost AS FACost
	|
	|	WHERE
	|		&ThisIsInternationalVersion
	|		AND FACost.Active
	|		AND FACost.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND FACost.Recorder REFS Document.FutureExpenseCommitmentsAccrualWriteOff
	|		AND FACost.LocalCost <> 0
	|
	|		AND (FACost.Organization, FACost.FixedAsset) IN
	|			(SELECT
	|				ListOfFA.Organization,
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&BegOfMonth,
	|		&EndOfPreviousMonth AS ParameterPeriod,
	|		InvestmentInRent.Period,
	|		InvestmentInRent.Ref,
	|		InvestmentInRent.FixedAsset,
	|		InvestmentInRent.Organization,
	|		InvestmentInRent.LocalCost
	|	FROM
	|		InvestmentInRent AS InvestmentInRent
	|	WHERE
	|		InvestmentInRent.RecordInLocalAccounting
	|		AND InvestmentInRent.LocalCost <> 0
	|
	|		AND InvestmentInRent.FixedAsset IN
	|				(SELECT
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfAccountingObjects_BU_MU AS ListOfFA
	|				WHERE
	|					ListOfFA.BegOfMonth = &BegOfMonth
	|					AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	) AS FACost
	|
	|GROUP BY
	|	FACost.BegOfMonth,
	|	FACost.ParameterPeriod,
	|	FACost.Period,
	|	FACost.Recorder,
	|	FACost.FixedAsset,
	|	FACost.Organization
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangeInDepreciation
	QueryText =
	"SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	Adjusting.Date AS Period,
	|	Adjusting.Ref AS Recorder,
	|	FATable.FixedAsset AS FixedAsset,
	|	Adjusting.Organization AS Organization,
	|	FATable.DepreciationInAccounting AS DepreciationLocal
	|
	|INTO DepreciationOfOS_Changes_BU_M
	|
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|
	|		INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|		ON (FATable.Ref = Adjusting.Ref)
	|
	|WHERE
	|	Adjusting.Posted
	|	AND Adjusting.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND Adjusting.PostInAccounting
	|	AND FATable.DepreciationInAccounting <> 0
	|
	|	AND FATable.FixedAsset IN
	|			(SELECT
	|				ListOfFA.FixedAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfFA
	|			WHERE
	|				ListOfFA.BegOfMonth = &BegOfMonth
	|				AND ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region MergingAllChanges
	QueryText =
	"SELECT
	|	ChangesTable.BegOfMonth AS BegOfMonth,
	|	ChangesTable.ParameterPeriod AS ParameterPeriod,
	|	ChangesTable.Recorder,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.FixedAsset AS FixedAsset,
	|	MAX(ChangesTable.Period) AS Period,
	|	MAX(BEGINOFPERIOD(DATEADD(ChangesTable.Period, MONTH, 1), MONTH)) AS BeginningOfNextMonth,
	|	MAX(OrderOfAccountingOfOS_Last.Period) AS AccountingProcedureOS_LatestPeriod,
	|	MAX(AccountingProcedureForOSBU_Latest.Period) AS AccountingProcedureOSBU_LatestPeriod,
	|	MAX(OSBUDepreciationParametersLast.Period) AS OSBUDepreciationParameters_LastPeriod,
	|	MAX(LocationOfOS_Last.Period) AS OS_LocationLastPeriod,
	|	MAX(InitialInformationOS_Latest.Period) AS InitialInformationOS_LatestPeriod
	|
	|INTO TableOfChangesBU_MU
	|
	|FROM
	|	(SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period AS Period,
	|		ChangesTable.FixedAsset AS FixedAsset,
	|		ChangesTable.Organization AS Organization
	|	FROM
	|		OSBU_ChangeDepreciationParameters_BU_M AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		AccountingProcedureForOS_Changes_BU_M AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		AccountingProcedureForOSBU_Changes_BU_M AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		LocationOfOS_Changes_BU_M AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		InitialInformationOS_Changes_BU_M AS ChangesTable
	|
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		CostOfOS_Change_BU_M AS ChangesTable
	|
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.FixedAsset,
	|		ChangesTable.Organization
	|	FROM
	|		DepreciationOfOS_Changes_BU_M AS ChangesTable
	|
	|	) AS ChangesTable
	|
	|		LEFT JOIN OSBU_ChangeDepreciationParameters_BU_M AS OSBUDepreciationParametersLast
	|		ON (OSBUDepreciationParametersLast.Organization = ChangesTable.Organization)
	|			AND (OSBUDepreciationParametersLast.FixedAsset = ChangesTable.FixedAsset)
	|			AND (OSBUDepreciationParametersLast.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (OSBUDepreciationParametersLast.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN AccountingProcedureForOS_MaChanges AS OrderOfAccountingOfOS_Last
	|		ON (OrderOfAccountingOfOS_Last.FixedAsset = ChangesTable.FixedAsset)
	|			AND (OrderOfAccountingOfOS_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (OrderOfAccountingOfOS_Last.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN AccountingProcedureForOSBU_Changes_BU_M AS AccountingProcedureForOSBU_Latest
	|		ON (AccountingProcedureForOSBU_Latest.Organization = ChangesTable.Organization)
	|			AND (AccountingProcedureForOSBU_Latest.FixedAsset = ChangesTable.FixedAsset)
	|			AND (AccountingProcedureForOSBU_Latest.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (AccountingProcedureForOSBU_Latest.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN InitialInformationOS_Changes_BU_M AS InitialInformationOS_Latest
	|		ON (InitialInformationOS_Latest.Organization = ChangesTable.Organization)
	|			AND (InitialInformationOS_Latest.FixedAsset = ChangesTable.FixedAsset)
	|			AND (InitialInformationOS_Latest.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (InitialInformationOS_Latest.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN LocationOfOS_MaChanges AS LocationOfOS_Last
	|		ON (LocationOfOS_Last.Organization = ChangesTable.Organization)
	|			AND (LocationOfOS_Last.FixedAsset = ChangesTable.FixedAsset)
	|			AND (LocationOfOS_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (LocationOfOS_Last.Period <= ChangesTable.Period)
	|
	|GROUP BY
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.ParameterPeriod,
	|	ChangesTable.Recorder,
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset,
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.Recorder,
	|	MIN(TableOfChangesIsAsFollows.Period) AS PeriodFollowing
	|
	|INTO TableOfChangesIsFollowing_BU_M
	|
	|FROM
	|	TableOfChangesBU_MU AS ChangesTable
	|
	|		LEFT JOIN TableOfChangesBU_MU AS TableOfChangesIsAsFollows
	|		ON (TableOfChangesIsAsFollows.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesIsAsFollows.FixedAsset = ChangesTable.FixedAsset)
	|			AND (TableOfChangesIsAsFollows.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (TableOfChangesIsAsFollows.Period > ChangesTable.Period
	|				OR TableOfChangesIsAsFollows.Period = ChangesTable.Period
	|						AND TableOfChangesIsAsFollows.Recorder > ChangesTable.Recorder)
	|
	|GROUP BY
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.Recorder,
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset,
	|	MIN(ChangesTable.Period) AS PeriodFollowing
	|
	|INTO TableOfChangesInThisMonthBU_MU
	|
	|FROM
	|	TableOfChangesBU_MU AS ChangesTable
	|WHERE
	|	(ChangesTable.BegOfMonth = &BegOfMonth)
	|
	|GROUP BY
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangesTo_BU_M
	QueryText =
	"SELECT
	|	ChangesTable.BegOfMonth AS BegOfMonth,
	|	ENDOFPERIOD(ChangesTable.BegOfMonth, MONTH) AS EndOfMonth,
	|	ENDOFPERIOD(ChangesTable.Period, DAY) AS ChangesDate,
	|	ChangesTable.FixedAsset AS FixedAsset,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.Recorder AS Recorder,
	|	ISNULL(DocumentsRegistry.BusinessOperation, UNDEFINED) AS BusinessOperation,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, MONTH) = ChangesTable.BegOfMonth
	|				AND NOT LastModifiedDates.AdjustmentModeFromPreviousDate
	|			THEN BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, DAY)
	|		ELSE ChangesTable.ParameterPeriod 
	|	END AS ParameterPeriod,
	|
	|	(NOT MergeOfFixedAssets.Ref IS NULL
	|		OR NOT SplitFixedAssets.Ref IS NULL) AS ObtainedByDisassemblyCombining,
	|
	|	CASE 
	|		WHEN ChangesTable.BegOfMonth = &BeginningOfPreviousMonth
	|
	|			THEN CASE
	|					WHEN BEGINOFPERIOD(ISNULL(TableOfChangesThisMonth.PeriodFollowing, &EndOfMonth), DAY) = &BegOfMonth
	|						THEN &BegOfMonth 
	|					ELSE ISNULL(DATEADD(TableOfChangesThisMonth.PeriodFollowing, DAY, -1), &EndOfMonth)
	|				END
	| 
	|		WHEN BEGINOFPERIOD(ISNULL(TableOfChangesIsAsFollows.PeriodFollowing, &EndOfMonth), DAY) = &BegOfMonth
	|
	|			THEN &BegOfMonth
	| 
	|		ELSE ISNULL(DATEADD(TableOfChangesIsAsFollows.PeriodFollowing, DAY, -1), &EndOfMonth)
	| 
	|	END AS Period,
	|
	|	DATEDIFF(ChangesTable.Period, ISNULL(TableOfChangesIsAsFollows.PeriodFollowing, ChangesTable.BeginningOfNextMonth), DAY) AS ValidityPeriod,
	|
	|	ISNULL(FACost.LocalCost, 0) AS LocalCostUpdate, // Change in the cost of the document
	|
	|	ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) AS DepreciationLocalUpdate, // Change in depreciation by document
	|
	|	OSBUDepreciationParametersLast.LastChangeDate AS LastChangeDate,
	|	OSBUDepreciationParametersLast.UsefulLifeMonthsAC AS UsefulLifeMonths,
	|	OSBUDepreciationParametersLast.EstimatedRunningTime AS EstimatedRunningTime,
	|	OSBUDepreciationParametersLast.AccelerationFactor AS AccelerationFactor,
	|	InitialInformationOS_Latest.DepreciationMethodAccounting AS DepreciationMethod,
	|	OSBUDepreciationParametersLast.ResidualValueMan AS ResidualValueMan,
	|	OrderOfAccountingOfOS_Last.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	OrderOfAccountingOfOS_Last.LineOfBusiness AS LineOfBusiness,
	|	OrderOfAccountingOfOS_Last.RunningTimeValue AS RunningTimeValue,
	|	AccountingProcedureForOSBU_Latest.BUState AS State,
	|	AccountingProcedureForOSBU_Latest.DepreciationAccrualAccounting AS AccrueDepreciationOrAmortization,
	|
	|	CASE
	|		WHEN CAST(ChangesTable.FixedAsset AS Catalog.Assets).OSType = VALUE(Enum.FATypes.GroupFA)
	|				AND ISNULL(AccountingProcedureForOSBU_Latest.DepreciationRecordMethodLA, UNDEFINED) IN (&EmptyWaysToReflectDepreciation)
	|			THEN ChangesTable.FixedAsset
	|		ELSE AccountingProcedureForOSBU_Latest.DepreciationRecordMethodLA
	|	END AS DepreciationRecordMethod,
	|
	|	AccountingProcedureForOSBU_Latest.ExpenseItemAccounting AS ExpenseItem,
	|	AccountingProcedureForOSBU_Latest.ExpensesDimensionAccounting AS DimensionOfExpenses,
	|	AccountingProcedureForOSBU_Latest.DepartmentACC AS ExpensesBusinessUnit,
	|	AccountingProcedureForOSBU_Latest.LineOfBusinessBookkeeping AS ExpenseLineOfBusiness,
	|	AccountingProcedureForOSBU_Latest.TransferExpensesToAnotherCompany,
	|	AccountingProcedureForOSBU_Latest.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	LocationOfOS_Last.FixedAssetsLocation AS FixedAssetsLocation
	|
	|INTO ChangesTo_BU_M
	|
	|FROM
	|	TableOfChangesBU_MU AS ChangesTable
	|
	|		LEFT JOIN TableOfChangesIsFollowing_BU_M AS TableOfChangesIsAsFollows
	|		ON (TableOfChangesIsAsFollows.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesIsAsFollows.FixedAsset = ChangesTable.FixedAsset)
	|			AND (TableOfChangesIsAsFollows.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (TableOfChangesIsAsFollows.Recorder = ChangesTable.Recorder)
	|
	|		LEFT JOIN TableOfChangesInThisMonthBU_MU AS TableOfChangesThisMonth
	|		ON (TableOfChangesThisMonth.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesThisMonth.FixedAsset = ChangesTable.FixedAsset)
	|
	|		LEFT JOIN DatesOfLastModificationOfBU_MU AS LastModifiedDates
	|		ON (LastModifiedDates.Organization = ChangesTable.Organization)
	|			AND (LastModifiedDates.FixedAsset = ChangesTable.FixedAsset)
	|			AND (LastModifiedDates.BegOfMonth = ChangesTable.BegOfMonth)
	|
	|		LEFT JOIN AccountingProcedureForOS_MaChanges AS OrderOfAccountingOfOS_Last
	|			LEFT JOIN AccountingProcedureForOS_MaChanges AS AccountingProcedureForOS_IsAsFollows
	|			ON (AccountingProcedureForOS_IsAsFollows.Organization = OrderOfAccountingOfOS_Last.Organization)
	|				AND (AccountingProcedureForOS_IsAsFollows.FixedAsset = OrderOfAccountingOfOS_Last.FixedAsset)
	|				AND (AccountingProcedureForOS_IsAsFollows.BegOfMonth = OrderOfAccountingOfOS_Last.BegOfMonth)
	|				AND (AccountingProcedureForOS_IsAsFollows.Period = OrderOfAccountingOfOS_Last.Period)
	|				AND (AccountingProcedureForOS_IsAsFollows.PointInTime > OrderOfAccountingOfOS_Last.PointInTime)
	|		ON (OrderOfAccountingOfOS_Last.FixedAsset = ChangesTable.FixedAsset)
	|			AND (OrderOfAccountingOfOS_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (OrderOfAccountingOfOS_Last.Period = ChangesTable.AccountingProcedureOS_LatestPeriod)
	|			AND (AccountingProcedureForOS_IsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN OSBU_ChangeDepreciationParameters_BU_M AS OSBUDepreciationParametersLast
	|			LEFT JOIN OSBU_ChangeDepreciationParameters_BU_M AS OSBU_DepreciationParametersAreAsFollows
	|			ON (OSBU_DepreciationParametersAreAsFollows.Organization = OSBUDepreciationParametersLast.Organization)
	|				AND (OSBU_DepreciationParametersAreAsFollows.FixedAsset = OSBUDepreciationParametersLast.FixedAsset)
	|				AND (OSBU_DepreciationParametersAreAsFollows.BegOfMonth = OSBUDepreciationParametersLast.BegOfMonth)
	|				AND (OSBU_DepreciationParametersAreAsFollows.Period = OSBUDepreciationParametersLast.Period)
	|				AND (OSBU_DepreciationParametersAreAsFollows.PointInTime > OSBUDepreciationParametersLast.PointInTime)
	|		ON (OSBUDepreciationParametersLast.Organization = ChangesTable.Organization)
	|			AND (OSBUDepreciationParametersLast.FixedAsset = ChangesTable.FixedAsset)
	|			AND (OSBUDepreciationParametersLast.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (OSBUDepreciationParametersLast.Period = ChangesTable.OSBUDepreciationParameters_LastPeriod)
	|			AND (OSBU_DepreciationParametersAreAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN AccountingProcedureForOSBU_Changes_BU_M AS AccountingProcedureForOSBU_Latest
	|			LEFT JOIN AccountingProcedureForOSBU_Changes_BU_M AS AccountingProcedureForOSBU_IsAsFollows
	|			ON (AccountingProcedureForOSBU_IsAsFollows.Organization = AccountingProcedureForOSBU_Latest.Organization)
	|				AND (AccountingProcedureForOSBU_IsAsFollows.FixedAsset = AccountingProcedureForOSBU_Latest.FixedAsset)
	|				AND (AccountingProcedureForOSBU_IsAsFollows.BegOfMonth = AccountingProcedureForOSBU_Latest.BegOfMonth)
	|				AND (AccountingProcedureForOSBU_IsAsFollows.Period = AccountingProcedureForOSBU_Latest.Period)
	|				AND (AccountingProcedureForOSBU_IsAsFollows.PointInTime > AccountingProcedureForOSBU_Latest.PointInTime)
	|		ON (AccountingProcedureForOSBU_Latest.Organization = ChangesTable.Organization)
	|			AND (AccountingProcedureForOSBU_Latest.FixedAsset = ChangesTable.FixedAsset)
	|			AND (AccountingProcedureForOSBU_Latest.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (AccountingProcedureForOSBU_Latest.Period = ChangesTable.AccountingProcedureOSBU_LatestPeriod)
	|			AND (AccountingProcedureForOSBU_IsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN InitialInformationOS_Changes_BU_M AS InitialInformationOS_Latest
	|			LEFT JOIN InitialInformationOS_Changes_BU_M AS InitialOS_InformationIsAsFollows
	|			ON (InitialOS_InformationIsAsFollows.Organization = InitialInformationOS_Latest.Organization)
	|				AND (InitialOS_InformationIsAsFollows.FixedAsset = InitialInformationOS_Latest.FixedAsset)
	|				AND (InitialOS_InformationIsAsFollows.BegOfMonth = InitialInformationOS_Latest.BegOfMonth)
	|				AND (InitialOS_InformationIsAsFollows.Period = InitialInformationOS_Latest.Period)
	|				AND (InitialOS_InformationIsAsFollows.PointInTime > InitialInformationOS_Latest.PointInTime)
	|		ON (InitialInformationOS_Latest.Organization = ChangesTable.Organization)
	|			AND (InitialInformationOS_Latest.FixedAsset = ChangesTable.FixedAsset)
	|			AND (InitialInformationOS_Latest.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (InitialInformationOS_Latest.Period = ChangesTable.AccountingProcedureOSBU_LatestPeriod)
	|			AND (InitialOS_InformationIsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN LocationOfOS_MaChanges AS LocationOfOS_Last
	|			LEFT JOIN LocationOfOS_MaChanges AS LocationOfOS_IsAsFollows
	|			ON (LocationOfOS_IsAsFollows.Organization = LocationOfOS_Last.Organization)
	|				AND (LocationOfOS_IsAsFollows.FixedAsset = LocationOfOS_Last.FixedAsset)
	|				AND (LocationOfOS_IsAsFollows.BegOfMonth = LocationOfOS_Last.BegOfMonth)
	|				AND (LocationOfOS_IsAsFollows.Period = LocationOfOS_Last.Period)
	|				AND (LocationOfOS_IsAsFollows.PointInTime > LocationOfOS_Last.PointInTime)
	|		ON (LocationOfOS_Last.Organization = ChangesTable.Organization)
	|			AND (LocationOfOS_Last.FixedAsset = ChangesTable.FixedAsset)
	|			AND (LocationOfOS_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (LocationOfOS_Last.Period = ChangesTable.OS_LocationLastPeriod)
	|			AND (LocationOfOS_IsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN CostOfOS_Change_BU_M AS FACost
	|		ON (FACost.Organization = ChangesTable.Organization)
	|			AND (FACost.FixedAsset = ChangesTable.FixedAsset)
	|			AND (FACost.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (FACost.Recorder = ChangesTable.Recorder)
	|
	|		LEFT JOIN DepreciationOfOS_Changes_BU_M AS FixedAssetsDepreciationCharge
	|		ON (FixedAssetsDepreciationCharge.Organization = ChangesTable.Organization)
	|			AND (FixedAssetsDepreciationCharge.FixedAsset = ChangesTable.FixedAsset)
	|			AND (FixedAssetsDepreciationCharge.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (FixedAssetsDepreciationCharge.Recorder = ChangesTable.Recorder)
	|
	|		LEFT JOIN Document.MergeOfFixedAssets AS MergeOfFixedAssets
	|		ON (MergeOfFixedAssets.Ref = ChangesTable.Recorder)
	|			AND (MergeOfFixedAssets.FixedAsset = ChangesTable.FixedAsset)
	|
	|		LEFT JOIN Document.SplitFixedAssets.FA AS SplitFixedAssets
	|		ON (SplitFixedAssets.Ref = ChangesTable.Recorder)
	|			AND (SplitFixedAssets.FixedAsset = ChangesTable.FixedAsset)
	|
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON (DocumentsRegistry.Ref = ChangesTable.Recorder)
	|			AND (NOT DocumentsRegistry.AdditionalRecord)
	|";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#EndRegion
	
	#Region PeriodOfChange_Y
	
	QueryText =
	"SELECT
	|	ChangesTo_Y.BegOfMonth           AS BegOfMonth,
	|	ChangesTo_Y.FixedAsset       AS FixedAsset,
	|	ChangesTo_Y.Organization            AS Organization,
	|	MIN(ChangesTo_Y.ChangesDate) AS Period
	|
	|INTO PeriodOfChange_Y
	|
	|FROM
	|	ChangesTo_Y AS ChangesTo_Y
	|
	|GROUP BY
	|	ChangesTo_Y.BegOfMonth,
	|	ChangesTo_Y.FixedAsset,
	|	ChangesTo_Y.Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region PeriodOfChangeOf_BU_M
	
	QueryText =
	"SELECT
	|	ChangesTo_BU_M.BegOfMonth           AS BegOfMonth,
	|	ChangesTo_BU_M.FixedAsset       AS FixedAsset,
	|	ChangesTo_BU_M.Organization            AS Organization,
	|	MIN(ChangesTo_BU_M.ChangesDate) AS Period
	|
	|INTO PeriodOfChangeOf_BU_M
	|
	|FROM
	|	ChangesTo_BU_M AS ChangesTo_BU_M
	|
	|GROUP BY
	|	ChangesTo_BU_M.BegOfMonth,
	|	ChangesTo_BU_M.FixedAsset,
	|	ChangesTo_BU_M.Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfOSSParameters_UU
	
	QueryText = 
	"SELECT
	|	CASE 
	|		WHEN CurMonthChangePeriod.Period IS NULL
	|			THEN ListOfFA.AccrualPeriod
	|		WHEN BEGINOFPERIOD(CurMonthChangePeriod.Period, DAY) = BEGINOFPERIOD(CurMonthChangePeriod.Period, MONTH)
	|			THEN CurMonthChangePeriod.Period
	|		ELSE DATEADD(CurMonthChangePeriod.Period, DAY, -1)
	|	END AS Period,
	|
	|	ListOfFA.ThisIsAnAdditionalAccrual AS ThisIsAnAdditionalAccrual,
	|	ISNULL(PreliminaryCostOfFA.PreliminaryCostExceedsActualMA, FALSE) AS PreliminaryCostExceedsActualMA,
	|	ISNULL(PreliminaryCostOfFA.PreliminaryCostExceedsActualAC, FALSE) AS PreliminaryCostExceedsActualAC,
	|	ListOfFA.DepreciationIsCalculatedAccordingToINTStandards AS DepreciationIsCalculatedAccordingToINTStandards,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	CASE
	|		WHEN ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|			THEN VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|		ELSE VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|	END AS ProcedureForCalculatingDepreciationOfMa,
	|
	|	ListOfFA.BeginningOfFiscalYear AS BeginningOfFiscalYear,
	|	ListOfFA.EndOfFiscalYear AS EndOfFiscalYear,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	ListOfFA.Organization AS Organization,
	|
	|	CAST(ListOfFA.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
	|
	|	CASE
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|			THEN FAAccountingProcedureAtBeginningOfMonth.FinancialAccountingGroup
	|		ELSE FixedAssetsAccountingProcedure.FinancialAccountingGroup 
	|	END AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|			THEN FAAccountingProcedureAtBeginningOfMonth.LineOfBusiness
	|		ELSE FixedAssetsAccountingProcedure.LineOfBusiness 
	|	END AS LineOfBusiness,
	|
	|	FixedAssetsAccountingProcedure.RunningTimeValue AS RunningTimeValue,
	|	FixedAssetsAccountingProcedure.EstimatedRunningTime AS EstimatedRunningTime,
	|
	// ResourceAssigned
	|	CASE 
	|		WHEN FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits, 0)
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth, 0)
	|	END AS ResourceAssigned,
	|
	// CostUsedToCalculateDepreciationManag
	|	CASE 
	|		WHEN NOT ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|
	|			THEN FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationManag
	|
	|		WHEN VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.OBEntrySubAssetsAndComponentsOfDepreciation)
	|				AND (ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|					OR LastModifiedDates.AdjustmentModeFromPreviousDate
	|						AND BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, MONTH) = ListOfFA.BegOfMonth
	|					OR ListOfFA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfFA.CostInManagementAccounting, 0) - ISNULL(DepreciationAdjustment.Depreciation, 0)
	|
	|		ELSE ISNULL(FACost.Cost, 0) - ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)
	|
	|	END AS CostUsedToCalculateDepreciationManag,
	|
	// CostUsedToCalculateDepreciationLocal
	|	CASE 
	|		WHEN NOT ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|
	|			THEN FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationLocal
	|
	|		WHEN VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.OBEntrySubAssetsAndComponentsOfDepreciation)
	|				AND (ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|					OR LastModifiedDates.AdjustmentModeFromPreviousDate
	|						AND BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, MONTH) = ListOfFA.BegOfMonth
	|					OR ListOfFA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfFA.CostInAccounting, 0) - ISNULL(DepreciationAdjustment.DepreciationLocal, 0)
	|
	|		ELSE ISNULL(FACost.LocalCost, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|
	|	END AS CostUsedToCalculateDepreciationLocal,
	|
	// CostAtBeginningOfYear
	|	ISNULL(CostOfFAAtBeginningOfYear.Cost, 0)
	|		- ISNULL(FADepreciationAtBeginningOfYear.Depreciation, 0) AS CostAtBeginningOfYear,
	|
	// LocalCostAtBeginningOfYear
	|	ISNULL(CostOfFAAtBeginningOfYear.LocalCost, 0)
	|		- ISNULL(FADepreciationAtBeginningOfYear.DepreciationLocal, 0) AS LocalCostAtBeginningOfYear,
	|
	// LifeSpentCurrentPeriod
	|	CASE 
	|		WHEN LastModifiedDates.Date = BEGINOFPERIOD(PeriodOfChange_Y.Period, DAY)
	|
	|			THEN 0
	|
	|		WHEN FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|
	|			THEN CAST(CASE 
	|					WHEN NOT PeriodOfChange_Y.Period IS NULL
	|						THEN CASE 
	|								WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|									THEN (DATEDIFF(LastModifiedDates.Date, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfFA.EndOfMonth), DAY) + 1)
	|									ELSE (DATEDIFF(ListOfFA.BegOfMonth, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfFA.EndOfMonth), DAY) + 1)
	|							END / DAY(ListOfFA.EndOfMonth)
	|					ELSE 1
	|				END * CASE
	|							WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|								THEN ISNULL(FAGeneration.VolumeOfOutputForPreviousPeriod, 0)
	|							WHEN NOT ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|									AND BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateMA, MONTH) = &BeginningOfPreviousMonth
	|								THEN ISNULL(FAGeneration.OutputVolumePerMonth, 0) + ISNULL(FAGeneration.VolumeOfOutputForPreviousPeriod, 0)
	|							ELSE ISNULL(FAGeneration.OutputVolumePerMonth, 0)
	|						END AS NUMBER(20,8))
	|
			// If the calculation is performed in the month of acceptance for accounting, then the day of acceptance / All-day month
	|		WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|			THEN CAST(CAST(DATEDIFF(LastModifiedDates.Date, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfFA.EndOfMonth), DAY) + 1 AS NUMBER(15,9))
	|					/ CAST(DAY(ListOfFA.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9))
	|	
			// If this is an additional charge, then the date of the document is / In today's month
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|
	|			THEN CAST(CAST(DATEDIFF(ListOfFA.Period, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfFA.EndOfMonth), DAY) + 1 AS NUMBER(15,9))
	|					/ CAST(DAY(ListOfFA.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9))
	|
			// In other cases, the number of days before the first parameter changes / In today's month
	|		ELSE CAST(CAST(DATEDIFF(ListOfFA.BegOfMonth, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfFA.EndOfMonth), DAY) + 1 AS NUMBER(15,9))
	|					/ CAST(DAY(ListOfFA.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9))
	|
	|	END AS LifeSpentCurrentPeriod,
	|	  
	// LifeSpentPastPeriod
	|	CASE 
	|		WHEN FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|
	|			THEN CASE
	|					WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|						THEN CAST(0 AS NUMBER(20,8))
	|					WHEN NOT ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|							AND BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateMA, MONTH) = &BeginningOfPreviousMonth
	|						THEN CAST(0 AS NUMBER(20,8))
	|					ELSE CAST(ISNULL(FAGeneration.VolumeOfOutputForPreviousPeriod, 0) 
	|									- ISNULL(FAGeneration_AsOfDateOfLastChange.OutputVolume, 0) AS NUMBER(20,8))
	|				END
	|
	|		WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|				OR LastModifiedDates.Date IS NULL
	|
	|			THEN CAST(0 AS NUMBER(20,8))
	|
			// In the next month after acceptance for accounting: [number of days worked per month of acceptance] / [total days per month of acceptance]
	|		WHEN ENDOFPERIOD(LastModifiedDates.Date, MONTH) = ENDOFPERIOD(DATEADD(ListOfFA.BegOfMonth, MONTH, -1), MONTH)
	|
	|			THEN CAST(CAST(DATEDIFF(LastModifiedDates.Date, ENDOFPERIOD(LastModifiedDates.Date, MONTH), DAY) + 1 AS NUMBER(15,9)) 
	|					/ CAST(DAY(ENDOFPERIOD(LastModifiedDates.Date, MONTH)) AS NUMBER(15,9)) AS NUMBER(31,9))
	
			// In later months: [number of days worked per month of acceptance] / [total days per month of acceptance] + [number of months after acceptance before the beginning of the month]
	|		ELSE
	|			CAST(CAST(DATEDIFF(LastModifiedDates.Date, ENDOFPERIOD(LastModifiedDates.Date, MONTH), DAY) + 1 AS NUMBER(15,9)) 
	|				/ CAST(DAY(ENDOFPERIOD(LastModifiedDates.Date, MONTH)) AS NUMBER(15,9))
	|				+ DATEDIFF(BEGINOFPERIOD(DATEADD(LastModifiedDates.Date, MONTH, 1), MONTH), ListOfFA.EndOfMonth, MONTH) AS NUMBER(31,9))
	|
	|	END AS LifeSpentPastPeriod,
	|
	// WorkedMonthsFullYears
	|	CASE
	|		WHEN LastModifiedDates.Date < ListOfFA.BeginningOfFiscalYear
	| 			THEN 
	|				// number of months of the first year
	|				DATEDIFF(BEGINOFPERIOD(LastModifiedDates.Date, MONTH), LastModifiedDates.EndOfFiscalYear, MONTH) + 1
	|
	|				// number of months of the next full years
	|				+ CASE
	|					WHEN (CAST((DATEDIFF(LastModifiedDates.EndOfFiscalYear, ListOfFA.BegOfMonth, MONTH) - 1) / 12 AS NUMBER(10, 0))) > (DATEDIFF(LastModifiedDates.EndOfFiscalYear, ListOfFA.BegOfMonth, MONTH)-1) / 12
	|						THEN (CAST((DATEDIFF(LastModifiedDates.EndOfFiscalYear, ListOfFA.BegOfMonth, MONTH) - 1) / 12 AS NUMBER(10, 0))) - 1
	|					ELSE CAST((DATEDIFF(LastModifiedDates.EndOfFiscalYear, ListOfFA.BegOfMonth, MONTH) - 1) / 12 AS NUMBER(10, 0))
	|				END * 12
	|
	|		ELSE 0
	|	END AS WorkedMonthsFullYears,
	|
	|	ISNULL(FixedAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization, FALSE) AS AccrueDepreciationOrAmortization,
	|	FixedAssetsAccountingProcedureManagementAccounting.ExpenseItem AS ExpenseItemManagementAccounting,
	|	FixedAssetsAccountingProcedureManagementAccounting.DimensionOfExpenses AS ExpensesDimensionManagementAccounting,
	|
	|	CASE
	|		WHEN FixedAssetsAccountingProcedureManagementAccounting.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.Department 
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|			THEN FALocationAtBeginningOfMonth.FixedAssetsLocation
	|		ELSE FALocation.FixedAssetsLocation 
	|	END AS ExpensesBusinessUnit,
	|
	|	CASE
	|		WHEN FixedAssetsAccountingProcedureManagementAccounting.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.LineOfBusiness 
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|			THEN FAAccountingProcedureAtBeginningOfMonth.LineOfBusiness
	|		ELSE FixedAssetsAccountingProcedure.LineOfBusiness 
	|	END AS ExpenseLineOfBusiness,
	|
	|	CASE
	|		WHEN CAST(ListOfFA.FixedAsset AS Catalog.Assets).OSType = VALUE(Enum.FATypes.GroupFA)
	|				AND FixedAssetsAccountingProcedureManagementAccounting.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND FixedAssetsAccountingProcedureManagementAccounting.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ListOfFA.FixedAsset
	|		ELSE FixedAssetsAccountingProcedureManagementAccounting.DepreciationRecordMethod
	|	END AS MethodOfReflectingDepreciationOfMA,
	|
	|	FixedAssetsAccountingProcedureManagementAccounting.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherMaOrganization,
	|	FixedAssetsAccountingProcedureManagementAccounting.CompanyRecipientOfExpenses AS OrganizationRecipientOfMaExpenses,
	|
	// NetBookValue
	|	CASE 
	|		WHEN VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.OBEntrySubAssetsAndComponentsOfDepreciation)
	|				AND (ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|					OR LastModifiedDates.AdjustmentModeFromPreviousDate
	|						AND BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, MONTH) = ListOfFA.BegOfMonth
	|					OR ListOfFA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfFA.CostInManagementAccounting, 0) - ISNULL(DepreciationAdjustment.Depreciation, 0)
	|
	|		ELSE ISNULL(FACost.Cost, 0) - ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)
	|
	|	END AS NetBookValue,
	|
	// NetBookValueLocal
	|	CASE 
	|		WHEN VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.OBEntrySubAssetsAndComponentsOfDepreciation)
	|				AND (ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|					OR LastModifiedDates.AdjustmentModeFromPreviousDate
	|						AND BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, MONTH) = ListOfFA.BegOfMonth
	|					OR ListOfFA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfFA.CostInAccounting, 0) - ISNULL(DepreciationAdjustment.DepreciationLocal, 0)
	|
	|		ELSE ISNULL(FACost.LocalCost, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|
	|	END AS NetBookValueLocal,
	|
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0) AS ResidualValueMan,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal, 0) AS ResidualValueLocal,
	|
	// Cost
	|	CASE 
	|		WHEN VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.OBEntrySubAssetsAndComponentsOfDepreciation)
	|				AND (ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|					OR LastModifiedDates.AdjustmentModeFromPreviousDate
	|						AND BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, MONTH) = ListOfFA.BegOfMonth
	|					OR ListOfFA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfFA.CostInManagementAccounting, 0)
	|
	|		ELSE ISNULL(FACost.Cost, 0)
	|	END AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND VALUETYPE(FixedAssetDepreciationParametersManagementAccounting.Recorder) <> TYPE(Document.OBEntrySubAssetsAndComponentsOfDepreciation)
	|				AND (ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|					OR LastModifiedDates.AdjustmentModeFromPreviousDate
	|						AND BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, MONTH) = ListOfFA.BegOfMonth
	|					OR ListOfFA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfFA.CostInAccounting, 0)
	|
	|		ELSE ISNULL(FACost.LocalCost, 0)
	|
	|	END AS LocalCost,
	|
	|	ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)               AS Depreciation,
	|	ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)           AS DepreciationLocal,
	|
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceLocal, 0) AS ImpairmentBalanceLocal,
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceMan, 0)  AS ImpairmentBalanceMan,
	|
	|	CASE
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|			THEN FALocationAtBeginningOfMonth.FixedAssetsLocation
	|		ELSE FALocation.FixedAssetsLocation 
	|	END AS FixedAssetsLocation,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths           AS UsefulLifeManagementAccounting,
	|	FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor        AS AccelerationFactor,
	|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod  AS DepreciationMethod,
	|	LastModifiedDates.Date                         AS LastChangeDate
	|
	|INTO ListOfOSSParameters_UU
	|
	|FROM
	|	ListOfAccountingObjects_ AS ListOfFA
	|
	|		LEFT JOIN PeriodOfChange_Y AS PeriodOfChange_Y
	|		ON (PeriodOfChange_Y.Organization = ListOfFA.Organization)
	|			AND (PeriodOfChange_Y.FixedAsset = ListOfFA.FixedAsset)
	|			AND (PeriodOfChange_Y.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN PeriodOfChange_Y AS CurMonthChangePeriod
	|		ON (CurMonthChangePeriod.Organization = ListOfFA.Organization)
	|			AND (CurMonthChangePeriod.FixedAsset = ListOfFA.FixedAsset)
	|			AND (CurMonthChangePeriod.BegOfMonth = &BegOfMonth)
	|
	|		LEFT JOIN DatesWhenMaWasLastModified AS LastModifiedDates
	|		ON (LastModifiedDates.Organization = ListOfFA.Organization)
	|			AND (LastModifiedDates.FixedAsset = ListOfFA.FixedAsset)
	|			AND (LastModifiedDates.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure
	|		ON (FixedAssetsAccountingProcedure.Organization = UNDEFINED)
	|			AND (FixedAssetsAccountingProcedure.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FixedAssetsAccountingProcedure.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (FixedAssetsAccountingProcedure.ParameterPeriod = ListOfFA.ParameterPeriod)
	|
	|		LEFT JOIN FixedAssetsAccountingProcedure AS FAAccountingProcedureAtBeginningOfMonth
	|		ON (FAAccountingProcedureAtBeginningOfMonth.Organization = UNDEFINED)
	|			AND (FAAccountingProcedureAtBeginningOfMonth.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FAAccountingProcedureAtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (FAAccountingProcedureAtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN OS_CostAtBeginningOfMonth AS FACost
	|		ON (FACost.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FACost.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN OS_CostAtBeginningOfYear AS CostOfFAAtBeginningOfYear
	|		ON (CostOfFAAtBeginningOfYear.FixedAsset = ListOfFA.FixedAsset)
	|
	|		LEFT JOIN OS_DepreciationAtBeginningOfYear AS FADepreciationAtBeginningOfYear
	|		ON (FADepreciationAtBeginningOfYear.FixedAsset = ListOfFA.FixedAsset)
	|
	|		LEFT JOIN PreliminaryCostOfFA AS PreliminaryCostOfFA
	|		ON (PreliminaryCostOfFA.FixedAsset = ListOfFA.FixedAsset)
	|			AND (PreliminaryCostOfFA.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN MADepreciationAdjustment AS DepreciationAdjustment
	|		ON (DepreciationAdjustment.Organization = ListOfFA.Organization)
	|			AND (DepreciationAdjustment.FixedAsset = ListOfFA.FixedAsset)
	|			AND (DepreciationAdjustment.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (LastModifiedDates.AdjustmentModeFromPreviousDate)
	|
	|		LEFT JOIN OS_DepreciationAtBeginningOfMonth AS FixedAssetsDepreciationCharge
	|		ON (FixedAssetsDepreciationCharge.Organization = ListOfFA.Organization)
	|			AND (FixedAssetsDepreciationCharge.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FixedAssetsDepreciationCharge.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentAtBeginningOfMonth
	|		ON (ImpairmentAtBeginningOfMonth.Organization = ListOfFA.Organization)
	|			AND (ImpairmentAtBeginningOfMonth.FixedAsset = ListOfFA.FixedAsset)
	|			AND (ImpairmentAtBeginningOfMonth.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN FALocation AS FALocation
	|		ON (FALocation.Organization = UNDEFINED)
	|			AND (FALocation.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FALocation.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (FALocation.ParameterPeriod = ListOfFA.ParameterPeriod)
	|
	|		LEFT JOIN FALocation AS FALocationAtBeginningOfMonth
	|		ON (FALocationAtBeginningOfMonth.Organization = UNDEFINED)
	|			AND (FALocationAtBeginningOfMonth.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FALocationAtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (FALocationAtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|		ON (InitialFixedAssetsInformation.Organization = ListOfFA.Organization)
	|			AND (InitialFixedAssetsInformation.FixedAsset = ListOfFA.FixedAsset)
	|			AND (InitialFixedAssetsInformation.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (InitialFixedAssetsInformation.ParameterPeriod = ListOfFA.ParameterPeriod)
	|
	|		LEFT JOIN FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
	|		ON (FixedAssetDepreciationParametersManagementAccounting.Organization = ListOfFA.Organization)
	|			AND (FixedAssetDepreciationParametersManagementAccounting.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FixedAssetDepreciationParametersManagementAccounting.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (FixedAssetDepreciationParametersManagementAccounting.ParameterPeriod = ListOfFA.ParameterPeriod)
	|
	|		LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON (FixedAssetsAccountingProcedureManagementAccounting.Organization = ListOfFA.Organization)
	|			AND (FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FixedAssetsAccountingProcedureManagementAccounting.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (FixedAssetsAccountingProcedureManagementAccounting.ParameterPeriod = ListOfFA.ParameterPeriod)
	|
	|		LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS OrderOfAccountingOfOSUU_AtBeginningOfMonth
	|		ON (OrderOfAccountingOfOSUU_AtBeginningOfMonth.Organization = ListOfFA.Organization)
	|			AND (OrderOfAccountingOfOSUU_AtBeginningOfMonth.FixedAsset = ListOfFA.FixedAsset)
	|			AND (OrderOfAccountingOfOSUU_AtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (OrderOfAccountingOfOSUU_AtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN FAGeneration AS FAGeneration
	|		ON (FAGeneration.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset)
	|			AND (FAGeneration.RunningTimeValue = FixedAssetsAccountingProcedure.RunningTimeValue)
	|			AND (FAGeneration.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN FAGeneration_AsOfLastMAChangeDate AS FAGeneration_AsOfDateOfLastChange
	|		ON (FAGeneration_AsOfDateOfLastChange.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset)
	|			AND (FAGeneration_AsOfDateOfLastChange.RunningTimeValue = FixedAssetsAccountingProcedure.RunningTimeValue)
	|
	|WHERE
	|	(NOT ListOfFA.ThisIsAnAdditionalAccrual
	|		OR ISNULL(OrderOfAccountingOfOSUU_AtBeginningOfMonth.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) = VALUE(Enum.FixedAssetsStates.Recognized_))
	|	AND ISNULL(FixedAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization, FALSE)
	|	AND NOT ListOfFA.ObtainedByDisassemblyCombining
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfOSSWithParameters_BU_MU
	
	QueryText = 
	"SELECT
	|	CASE 
	|		WHEN CurMonthChangePeriod.Period IS NULL
	|			THEN ListOfFA.AccrualPeriod
	|		WHEN BEGINOFPERIOD(CurMonthChangePeriod.Period, DAY) = BEGINOFPERIOD(CurMonthChangePeriod.Period, MONTH)
	|			THEN CurMonthChangePeriod.Period
	|		ELSE DATEADD(CurMonthChangePeriod.Period, DAY, -1)
	|	END AS Period,
	|
	|	ListOfFA.ThisIsAnAdditionalAccrual AS ThisIsAnAdditionalAccrual,
	|	ISNULL(PreliminaryCostOfFA.PreliminaryCostExceedsActualAC, FALSE) AS PreliminaryCostExceedsActual,
	|	TRUE AS DepreciationIsCalculatedAccordingToINTStandards,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	CASE
	|		WHEN ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|			THEN VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|		ELSE VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|	END AS ProcedureForCalculatingDepreciationAC,
	|
	|	ListOfFA.BeginningOfFiscalYear AS BeginningOfFiscalYear,
	|	ListOfFA.EndOfFiscalYear AS EndOfFiscalYear,
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	ListOfFA.Organization AS Organization,
	|
	|	CAST(ListOfFA.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
	|
	|	CASE
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|			THEN FAAccountingProcedureAtBeginningOfMonth.FinancialAccountingGroup
	|		ELSE FixedAssetsAccountingProcedure.FinancialAccountingGroup 
	|	END AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|			THEN FAAccountingProcedureAtBeginningOfMonth.LineOfBusiness
	|		ELSE FixedAssetsAccountingProcedure.LineOfBusiness 
	|	END AS LineOfBusiness,
	|
	|	FixedAssetsAccountingProcedure.RunningTimeValue AS RunningTimeValue,
	|	FixedAssetsAccountingProcedure.EstimatedRunningTime AS EstimatedRunningTime,
	|
	// ResourceAssigned
	|	CASE 
	|		WHEN InitialFixedAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits, 0)
	|		ELSE ISNULL(OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth, 0)
	|	END AS ResourceAssigned,
	|
	// CostUsedToCalculateDepreciationLocal
	|	CASE 
	|		WHEN ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|				AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|				AND VALUETYPE(OSBUDepreciationParameters.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND VALUETYPE(OSBUDepreciationParameters.Recorder) <> TYPE(Document.OBEntrySubAssetsAndComponentsOfDepreciation)
	|
	|			THEN ISNULL(PreliminaryCostOfFA.CostInAccounting, 0) - ISNULL(DepreciationAdjustment.DepreciationLocal, 0)
	|
	|		ELSE ISNULL(FACost.LocalCost, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|
	|	END AS CostUsedToCalculateDepreciationLocal,
	|
	// LocalCostAtBeginningOfYear
	|	ISNULL(CostOfFAAtBeginningOfYear.LocalCost, 0)
	|		- ISNULL(FADepreciationAtBeginningOfYear.DepreciationLocal, 0) AS LocalCostAtBeginningOfYear,
	|
	// LifeSpentCurrentPeriod
	|	CASE 
	|		WHEN InitialFixedAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			THEN CAST(CASE 
	|					WHEN NOT PeriodOfChangeOf_BU_M.Period IS NULL
	|						THEN CASE 
	|								WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|									THEN (DATEDIFF(LastModifiedDates.Date, ISNULL(DATEADD(PeriodOfChangeOf_BU_M.Period, DAY, -1), ListOfFA.EndOfMonth), DAY) + 1)
	|									ELSE (DATEDIFF(ListOfFA.BegOfMonth, ISNULL(DATEADD(PeriodOfChangeOf_BU_M.Period, DAY, -1), ListOfFA.EndOfMonth), DAY) + 1)
	|							END / DAY(ListOfFA.EndOfMonth)
	|					ELSE 1
	|				END * CASE
	|							WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|								THEN ISNULL(FAGeneration.VolumeOfOutputForPreviousPeriod, 0)
	|							ELSE ISNULL(FAGeneration.OutputVolumePerMonth, 0)
	|						END AS NUMBER(31,9))
	|
			// If the calculation is performed in the month of acceptance for accounting, then the day of acceptance/Every month
	|		WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|			THEN CAST(CAST(DATEDIFF(LastModifiedDates.Date, ISNULL(DATEADD(PeriodOfChangeOf_BU_M.Period, DAY, -1), ListOfFA.EndOfMonth), DAY) + 1 AS NUMBER(15,9))
	|					/ CAST(DAY(ListOfFA.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9))
	|	
			// In other cases, the number of days is the first modification of the parameters/Every month
	|		ELSE CAST(CAST(DATEDIFF(ListOfFA.BegOfMonth, ISNULL(DATEADD(PeriodOfChangeOf_BU_M.Period, DAY, -1), ListOfFA.EndOfMonth), DAY) + 1 AS NUMBER(15,9))
	|					/ CAST(DAY(ListOfFA.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9))
	|	END AS LifeSpentCurrentPeriod,
	|	  
	// LifeSpentPastPeriod
	|	CASE 
	|		WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|				OR LastModifiedDates.Date IS NULL
	|
	|			THEN CAST(0 AS NUMBER(31,9))
	|
	|		WHEN InitialFixedAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|
	|			THEN CASE
	|					WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|						THEN CAST(0 AS NUMBER(31,9))
	|					ELSE CAST(ISNULL(FAGeneration.VolumeOfOutputForPreviousPeriod, 0)
	|									- ISNULL(FAGeneration_AsOfDateOfLastChange.OutputVolume, 0) AS NUMBER(31,9))
	|				END
	|
	|		WHEN ENDOFPERIOD(LastModifiedDates.Date, MONTH) = ENDOFPERIOD(DATEADD(ListOfFA.BegOfMonth, MONTH, -1), MONTH)
	|
	|			THEN CAST(CAST(DATEDIFF(LastModifiedDates.Date, ENDOFPERIOD(LastModifiedDates.Date, MONTH), DAY) + 1 AS NUMBER(15,9)) 
	|					/ CAST(DAY(ENDOFPERIOD(LastModifiedDates.Date, MONTH)) AS NUMBER(15,9)) AS NUMBER(31,9))
	
			// Explanation of the formula: [number of days worked per month of acceptance] / [total days per month of acceptance] + [number of months after acceptance before the beginning of the month]
	|		ELSE
	|			CAST(CAST(DATEDIFF(LastModifiedDates.Date, ENDOFPERIOD(LastModifiedDates.Date, MONTH), DAY) + 1 AS NUMBER(15,9)) 
	|				/ CAST(DAY(ENDOFPERIOD(LastModifiedDates.Date, MONTH)) AS NUMBER(15,9))
	|				+ DATEDIFF(BEGINOFPERIOD(DATEADD(LastModifiedDates.Date, MONTH, 1), MONTH), ListOfFA.EndOfMonth, MONTH) AS NUMBER(31,9))
	|
	|	END AS LifeSpentPastPeriod,
	|
	// WorkedMonthsFullYears
	|	CASE
	|		WHEN LastModifiedDates.Date < ListOfFA.BeginningOfFiscalYear
	| 			THEN 
	|				// number of months of the first year
	|				DATEDIFF(BEGINOFPERIOD(LastModifiedDates.Date, MONTH), LastModifiedDates.EndOfFiscalYear, MONTH) + 1
	|
	|				// number of months of the next full years
	|				+ CASE
	|					WHEN (CAST((DATEDIFF(LastModifiedDates.EndOfFiscalYear, ListOfFA.BegOfMonth, MONTH) - 1) / 12 AS NUMBER(10, 0))) > (DATEDIFF(LastModifiedDates.EndOfFiscalYear, ListOfFA.BegOfMonth, MONTH)-1) / 12
	|						THEN (CAST((DATEDIFF(LastModifiedDates.EndOfFiscalYear, ListOfFA.BegOfMonth, MONTH) - 1) / 12 AS NUMBER(10, 0))) - 1
	|					ELSE CAST((DATEDIFF(LastModifiedDates.EndOfFiscalYear, ListOfFA.BegOfMonth, MONTH) - 1) / 12 AS NUMBER(10, 0))
	|				END * 12
	|
	|		ELSE 0
	|	END AS WorkedMonthsFullYears,
	|
	|	ISNULL(AccountingProcedureForOSBU.DepreciationAccrualAccounting, FALSE) AS AccrueDepreciationOrAmortization,
	|	AccountingProcedureForOSBU.ExpenseItemAccounting AS ExpenseItem,
	|	AccountingProcedureForOSBU.ExpensesDimensionAccounting AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN AccountingProcedureForOSBU.DepartmentACC <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN AccountingProcedureForOSBU.DepartmentACC 
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|			THEN FALocationAtBeginningOfMonth.FixedAssetsLocation
	|		ELSE FALocation.FixedAssetsLocation 
	|	END AS ExpensesBusinessUnit,
	|
	|	CASE
	|		WHEN AccountingProcedureForOSBU.DepartmentACC <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN AccountingProcedureForOSBU.LineOfBusinessBookkeeping 
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|			THEN FAAccountingProcedureAtBeginningOfMonth.LineOfBusiness
	|		ELSE FixedAssetsAccountingProcedure.LineOfBusiness 
	|	END AS ExpenseLineOfBusiness,
	|
	|	CASE
	|		WHEN CAST(ListOfFA.FixedAsset AS Catalog.Assets).OSType = VALUE(Enum.FATypes.GroupFA)
	|				AND AccountingProcedureForOSBU.DepreciationRecordMethodLA IN (&EmptyWaysToReflectDepreciation)
	|				AND AccountingProcedureForOSBU.DepartmentACC = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ListOfFA.FixedAsset
	|		ELSE AccountingProcedureForOSBU.DepreciationRecordMethodLA
	|	END AS DepreciationRecordMethod,
	|
	|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|
	// NetBookValueLocal
	|	CASE 
	|		WHEN ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|				AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|				AND VALUETYPE(OSBUDepreciationParameters.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND VALUETYPE(OSBUDepreciationParameters.Recorder) <> TYPE(Document.OBEntrySubAssetsAndComponentsOfDepreciation)
	|
	|			THEN ISNULL(PreliminaryCostOfFA.CostInAccounting, 0) - ISNULL(DepreciationAdjustment.DepreciationLocal, 0)
	|
	|		ELSE ISNULL(FACost.LocalCost, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|
	|	END AS NetBookValueLocal,
	|
	|	ISNULL(OSBUDepreciationParameters.ResidualValueMan, 0) AS ResidualValueLocal,
	|
	// LocalCost
	|	CASE 
	|		WHEN ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|				AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfFA.BegOfMonth
	|				AND VALUETYPE(OSBUDepreciationParameters.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND VALUETYPE(OSBUDepreciationParameters.Recorder) <> TYPE(Document.OBEntrySubAssetsAndComponentsOfDepreciation)
	|
	|			THEN ISNULL(PreliminaryCostOfFA.CostInAccounting, 0)
	|
	|		ELSE ISNULL(FACost.LocalCost, 0)
	|
	|	END AS LocalCost,
	|
	|	ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)           AS DepreciationLocal,
	|
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceLocal, 0) AS ImpairmentBalanceLocal,
	|
	|	CASE
	|		WHEN ListOfFA.ThisIsAnAdditionalAccrual
	|			THEN FALocationAtBeginningOfMonth.FixedAssetsLocation
	|		ELSE FALocation.FixedAssetsLocation 
	|	END AS FixedAssetsLocation,
	|
	|	OSBUDepreciationParameters.UsefulLifeMonthsAC AS UsefulLifeMonths,
	|	OSBUDepreciationParameters.AccelerationFactor        AS AccelerationFactor,
	|	InitialFixedAssetsInformation.DepreciationMethodAccounting AS DepreciationMethod,
	|	LastModifiedDates.Date                         AS LastChangeDate
	|
	|INTO ListOfOSSWithParameters_BU_MU
	|
	|FROM
	|	ListOfAccountingObjects_BU_MU AS ListOfFA
	|
	|		LEFT JOIN PeriodOfChangeOf_BU_M AS PeriodOfChangeOf_BU_M
	|		ON (PeriodOfChangeOf_BU_M.Organization = ListOfFA.Organization)
	|			AND (PeriodOfChangeOf_BU_M.FixedAsset = ListOfFA.FixedAsset)
	|			AND (PeriodOfChangeOf_BU_M.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN PeriodOfChangeOf_BU_M AS CurMonthChangePeriod
	|		ON (CurMonthChangePeriod.Organization = ListOfFA.Organization)
	|			AND (CurMonthChangePeriod.FixedAsset = ListOfFA.FixedAsset)
	|			AND (CurMonthChangePeriod.BegOfMonth = &BegOfMonth)
	|
	|		LEFT JOIN FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure
	|		ON (FixedAssetsAccountingProcedure.Organization = UNDEFINED)
	|			AND (FixedAssetsAccountingProcedure.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FixedAssetsAccountingProcedure.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (FixedAssetsAccountingProcedure.ParameterPeriod = ListOfFA.ParameterPeriod)
	|
	|		LEFT JOIN FixedAssetsAccountingProcedure AS FAAccountingProcedureAtBeginningOfMonth
	|		ON (FAAccountingProcedureAtBeginningOfMonth.Organization = UNDEFINED)
	|			AND (FAAccountingProcedureAtBeginningOfMonth.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FAAccountingProcedureAtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (FAAccountingProcedureAtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN OS_CostAtBeginningOfMonth AS FACost
	|		ON (FACost.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FACost.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN OS_CostAtBeginningOfYear AS CostOfFAAtBeginningOfYear
	|		ON (CostOfFAAtBeginningOfYear.FixedAsset = ListOfFA.FixedAsset)
	|
	|		LEFT JOIN OS_DepreciationAtBeginningOfYear AS FADepreciationAtBeginningOfYear
	|		ON (FADepreciationAtBeginningOfYear.FixedAsset = ListOfFA.FixedAsset)
	|
	|		LEFT JOIN PreliminaryCostOfFA AS PreliminaryCostOfFA
	|		ON (PreliminaryCostOfFA.FixedAsset = ListOfFA.FixedAsset)
	|			AND (PreliminaryCostOfFA.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN MADepreciationAdjustment AS DepreciationAdjustment
	|		ON (DepreciationAdjustment.FixedAsset = ListOfFA.FixedAsset)
	|			AND (DepreciationAdjustment.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN OS_DepreciationAtBeginningOfMonth AS FixedAssetsDepreciationCharge
	|		ON (FixedAssetsDepreciationCharge.Organization = ListOfFA.Organization)
	|			AND (FixedAssetsDepreciationCharge.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FixedAssetsDepreciationCharge.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentAtBeginningOfMonth
	|		ON (ImpairmentAtBeginningOfMonth.Organization = ListOfFA.Organization)
	|			AND (ImpairmentAtBeginningOfMonth.FixedAsset = ListOfFA.FixedAsset)
	|			AND (ImpairmentAtBeginningOfMonth.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN FALocation AS FALocation
	|		ON (FALocation.Organization = UNDEFINED)
	|			AND (FALocation.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FALocation.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (FALocation.ParameterPeriod = ListOfFA.ParameterPeriod)
	|
	|		LEFT JOIN FALocation AS FALocationAtBeginningOfMonth
	|		ON (FALocationAtBeginningOfMonth.Organization = UNDEFINED)
	|			AND (FALocationAtBeginningOfMonth.FixedAsset = ListOfFA.FixedAsset)
	|			AND (FALocationAtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (FALocationAtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|		ON (InitialFixedAssetsInformation.Organization = ListOfFA.Organization)
	|			AND (InitialFixedAssetsInformation.FixedAsset = ListOfFA.FixedAsset)
	|			AND (InitialFixedAssetsInformation.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (InitialFixedAssetsInformation.ParameterPeriod = ListOfFA.ParameterPeriod)
	|
	|		LEFT JOIN OSBUDepreciationParameters AS OSBUDepreciationParameters
	|		ON (OSBUDepreciationParameters.Organization = ListOfFA.Organization)
	|			AND (OSBUDepreciationParameters.FixedAsset = ListOfFA.FixedAsset)
	|			AND (OSBUDepreciationParameters.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (OSBUDepreciationParameters.ParameterPeriod = ListOfFA.ParameterPeriod)
	|
	|		LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON (AccountingProcedureForOSBU.Organization = ListOfFA.Organization)
	|			AND (AccountingProcedureForOSBU.FixedAsset = ListOfFA.FixedAsset)
	|			AND (AccountingProcedureForOSBU.BegOfMonth = ListOfFA.BegOfMonth)
	|			AND (AccountingProcedureForOSBU.ParameterPeriod = ListOfFA.ParameterPeriod)
	|
	|		LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForOSBU_AtBeginningOfMonth
	|		ON (AccountingProcedureForOSBU_AtBeginningOfMonth.Organization = ListOfFA.Organization)
	|			AND (AccountingProcedureForOSBU_AtBeginningOfMonth.FixedAsset = ListOfFA.FixedAsset)
	|			AND (AccountingProcedureForOSBU_AtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (AccountingProcedureForOSBU_AtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN FAGeneration AS FAGeneration
	|		ON (FAGeneration.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset)
	|			AND (FAGeneration.RunningTimeValue = FixedAssetsAccountingProcedure.RunningTimeValue)
	|			AND (FAGeneration.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|		LEFT JOIN FAGeneration_AsOfLastACChangeDate AS FAGeneration_AsOfDateOfLastChange
	|		ON (FAGeneration_AsOfDateOfLastChange.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset)
	|			AND (FAGeneration_AsOfDateOfLastChange.RunningTimeValue = FixedAssetsAccountingProcedure.RunningTimeValue)
	|
	|		LEFT JOIN DatesOfLastModificationOfBU_MU AS LastModifiedDates
	|		ON (LastModifiedDates.Organization = ListOfFA.Organization)
	|			AND (LastModifiedDates.FixedAsset = ListOfFA.FixedAsset)
	|			AND (LastModifiedDates.BegOfMonth = ListOfFA.BegOfMonth)
	|
	|WHERE
	|	(NOT ListOfFA.ThisIsAnAdditionalAccrual
	|		OR ISNULL(AccountingProcedureForOSBU_AtBeginningOfMonth.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) = VALUE(Enum.FixedAssetsStates.Recognized_))
	|	AND ISNULL(AccountingProcedureForOSBU.DepreciationAccrualAccounting, FALSE)
	|	AND NOT ListOfFA.ObtainedByDisassemblyCombining
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfOSSWithChangedParameters_Y
	
	QueryText = 
	"SELECT
	|	ChangesTo_Y.Period AS Period,
	|	ChangesTo_Y.Recorder AS Recorder,
	|	ChangesTo_Y.BusinessOperation AS BusinessOperation,
	|	ChangesTo_Y.FixedAsset AS FixedAsset,
	|	ChangesTo_Y.Organization AS Organization,
	|	(ChangesTo_Y.BegOfMonth = &BeginningOfPreviousMonth) AS ThisIsAnAdditionalAccrual,
	|	ISNULL(PreliminaryCostOfFA.PreliminaryCostExceedsActualMA, FALSE) AS PreliminaryCostExceedsActualMA,
	|	ISNULL(PreliminaryCostOfFA.PreliminaryCostExceedsActualAC, FALSE) AS PreliminaryCostExceedsActualAC,
	|
	|	CASE
	|		WHEN MONTH(ChangesTo_Y.Period) < ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(ChangesTo_Y.Period, YEAR), MONTH, ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1) - 13)
	|		ELSE DATEADD(BEGINOFPERIOD(ChangesTo_Y.Period, YEAR), MONTH, ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1) - 1) 
	|	END AS BeginningOfFiscalYear,
	|	
	|	CASE
	|		WHEN MONTH(ChangesTo_Y.Period) < ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(ChangesTo_Y.Period, YEAR), MONTH, ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1) - 1)
	|		ELSE DATEADD(BEGINOFPERIOD(ChangesTo_Y.Period, YEAR), MONTH, ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1) + 11) 
	|	END AS EndOfFiscalYear,
	|
	|	ListOfFA.RevaluationMethod AS RevaluationMethod,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS ProcedureForCalculatingDepreciationOfMa,
	|
	|	ChangesTo_Y.ObtainedByDisassemblyCombining AS ObtainedByDisassemblyCombining, 
	|
	// NetBookValue
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateMA, MONTH) = ChangesTo_Y.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfFA.CostInManagementAccounting, 0)
	|		ELSE ISNULL(FACost.Cost, 0) - ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)
	|	END AS NetBookValue,
	|
	// Cost
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateMA, MONTH) = ChangesTo_Y.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfFA.CostInManagementAccounting, 0)
	|		WHEN ChangesTo_Y.BegOfMonth = &BeginningOfPreviousMonth
	|			THEN 0
	|		ELSE ISNULL(FACost.Cost, 0)
	|	END AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateMA, MONTH) = ChangesTo_Y.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfFA.CostInAccounting, 0)
	|		WHEN ChangesTo_Y.BegOfMonth = &BeginningOfPreviousMonth
	|			THEN 0
	|		ELSE ISNULL(FACost.LocalCost, 0)
	|	END AS LocalCost,
	|
	|	ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0) AS Depreciation,
	|	ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) AS DepreciationLocal,
	|
	|	ChangesTo_Y.CostUpdate AS CostUpdate,
	|	ChangesTo_Y.LocalCostUpdate AS LocalCostUpdate,
	|	ChangesTo_Y.DepreciationUpdate AS DepreciationUpdate,
	|	ChangesTo_Y.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|
	|	ISNULL(ChangesTo_Y.FinancialAccountingGroup, FixedAssetsAccountingProcedure.FinancialAccountingGroup) AS FinancialAccountingGroup,
	|	ISNULL(ChangesTo_Y.LineOfBusiness, FixedAssetsAccountingProcedure.LineOfBusiness) AS LineOfBusiness,
	|	ISNULL(ChangesTo_Y.RunningTimeValue, FixedAssetsAccountingProcedure.RunningTimeValue) AS RunningTimeValue,
	|
	// ResourceAssigned
	|	CASE 
	|		WHEN ISNULL(ChangesTo_Y.DepreciationMethod, FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod) = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(ChangesTo_Y.EstimatedRunningTime, ISNULL(FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits, 0))
	|		ELSE ISNULL(ChangesTo_Y.UsefulLifeMonths, ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth, 0))
	|	END AS ResourceAssigned,
	|
	// LifeSpentCurrentPeriod
	|	CAST(CAST(CASE 
	|		WHEN ISNULL(ChangesTo_Y.DepreciationMethod, FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod) = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			THEN CASE
	|					WHEN ChangesTo_Y.BegOfMonth = &BeginningOfPreviousMonth
	|						THEN ISNULL(FAGeneration.VolumeOfOutputForPreviousPeriod, 0)
	|					ELSE ISNULL(FAGeneration.OutputVolumePerMonth, 0)
	|				END
	|		ELSE 1
	|	END AS NUMBER(15,9)) * CAST(ChangesTo_Y.ValidityPeriod AS NUMBER(15,9)) / CAST(DAY(ChangesTo_Y.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9)) AS LifeSpentCurrentPeriod,
	|	  
	// LifeSpentPastPeriod
	|	CASE 
	|		WHEN BEGINOFPERIOD(ISNULL(ChangesTo_Y.LastChangeDate, LastModifiedDates.Date), MONTH) = ChangesTo_Y.BegOfMonth
	|				OR ISNULL(ChangesTo_Y.LastChangeDate, LastModifiedDates.Date) IS NULL
	|
	|			THEN CAST(0 AS NUMBER(20,8))
	|
	|		WHEN ISNULL(ChangesTo_Y.DepreciationMethod, FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod) = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|
	|			THEN CASE
	|					WHEN ChangesTo_Y.BegOfMonth = &BeginningOfPreviousMonth
	|						THEN CAST(0 AS NUMBER(20,8))
	|					WHEN NOT ListOfFA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|							AND BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateMA, MONTH) = &BeginningOfPreviousMonth
	|						THEN 0
	|					ELSE CAST(ISNULL(FAGeneration.VolumeOfOutputForPreviousPeriod, 0) 
	|									- ISNULL(FAGeneration_AsOfDateOfLastChange.OutputVolume, 0) AS NUMBER(20,8))
	|				END
	|
			// In the next month after acceptance for accounting: [number of days worked per month of acceptance] / [total days per month of acceptance]
	|		WHEN ENDOFPERIOD(ISNULL(ChangesTo_Y.LastChangeDate, LastModifiedDates.Date), MONTH) = ENDOFPERIOD(DATEADD(ChangesTo_Y.BegOfMonth, MONTH, -1), MONTH)
	|
	|			THEN CAST((DATEDIFF(ISNULL(ChangesTo_Y.LastChangeDate, LastModifiedDates.Date), ENDOFPERIOD(ISNULL(ChangesTo_Y.LastChangeDate, LastModifiedDates.Date), MONTH), DAY) + 1) 
	|					/ DAY(ENDOFPERIOD(ISNULL(ChangesTo_Y.LastChangeDate, LastModifiedDates.Date), MONTH)) AS NUMBER(20,8))
	
			// In later months: [number of days worked per month of acceptance] / [total days per month of acceptance] + [number of months after acceptance before the beginning of the month]
	|		ELSE
	|			CAST((DATEDIFF(ISNULL(ChangesTo_Y.LastChangeDate, LastModifiedDates.Date), ENDOFPERIOD(ISNULL(ChangesTo_Y.LastChangeDate, LastModifiedDates.Date), MONTH), DAY) + 1) 
	|				/ DAY(ENDOFPERIOD(ISNULL(ChangesTo_Y.LastChangeDate, LastModifiedDates.Date), MONTH))
	|				+ DATEDIFF(BEGINOFPERIOD(DATEADD(ISNULL(ChangesTo_Y.LastChangeDate, LastModifiedDates.Date), MONTH, 1), MONTH), ChangesTo_Y.EndOfMonth, MONTH) AS NUMBER(20,8))
	|
	|	END AS LifeSpentPastPeriod,
	|
	|
	// WorkedMonthsFullYears
	|	CASE
	|		WHEN YEAR(ISNULL(ChangesTo_Y.LastChangeDate, FixedAssetDepreciationParametersManagementAccounting.LastChangeDate)) <> YEAR(ChangesTo_Y.BegOfMonth) THEN
	|			13 - MONTH(ISNULL(ChangesTo_Y.LastChangeDate, FixedAssetDepreciationParametersManagementAccounting.LastChangeDate))
	|				+ 12 * (YEAR(ChangesTo_Y.BegOfMonth) - YEAR(ISNULL(ChangesTo_Y.LastChangeDate, FixedAssetDepreciationParametersManagementAccounting.LastChangeDate)) - 1)
	|		ELSE 0
	|	END AS WorkedMonthsFullYears,
	|
	|	ISNULL(ChangesTo_Y.AccrueDepreciationOrAmortization, ISNULL(FixedAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization, FALSE)) AS AccrueDepreciationOrAmortization,
	|	ISNULL(ChangesTo_Y.ExpenseItem, FixedAssetsAccountingProcedureManagementAccounting.ExpenseItem) AS ExpenseItemManagementAccounting,
	|	ISNULL(ChangesTo_Y.DimensionOfExpenses, FixedAssetsAccountingProcedureManagementAccounting.DimensionOfExpenses) AS ExpensesDimensionManagementAccounting,
	|
	|	CASE
	|		WHEN ISNULL(ChangesTo_Y.ExpensesBusinessUnit, FixedAssetsAccountingProcedureManagementAccounting.Department) <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ISNULL(ChangesTo_Y.ExpensesBusinessUnit, FixedAssetsAccountingProcedureManagementAccounting.Department) 
	|		ELSE ISNULL(ChangesTo_Y.FixedAssetsLocation, FALocation.FixedAssetsLocation) 
	|	END AS ExpensesBusinessUnit,
	|
	|	CASE
	|		WHEN ISNULL(ChangesTo_Y.ExpensesBusinessUnit, FixedAssetsAccountingProcedureManagementAccounting.Department) <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ISNULL(ChangesTo_Y.ExpenseLineOfBusiness, FixedAssetsAccountingProcedureManagementAccounting.LineOfBusiness) 
	|		ELSE ISNULL(ChangesTo_Y.LineOfBusiness, FixedAssetsAccountingProcedure.LineOfBusiness) 
	|	END AS ExpenseLineOfBusiness,
	|
	|	ISNULL(ChangesTo_Y.DepreciationRecordMethod, FixedAssetsAccountingProcedureManagementAccounting.DepreciationRecordMethod) AS MethodOfReflectingDepreciationOfMA,
	|	ISNULL(ChangesTo_Y.TransferExpensesToAnotherCompany, ISNULL(FixedAssetsAccountingProcedureManagementAccounting.TransferExpensesToAnotherCompany, FALSE)) AS TransferExpensesToAnotherMaOrganization,
	|	ISNULL(ChangesTo_Y.CompanyRecipientOfExpenses, FixedAssetsAccountingProcedureManagementAccounting.CompanyRecipientOfExpenses) AS OrganizationRecipientOfMaExpenses,
	|
	|	ISNULL(ChangesTo_Y.ResidualValueMan, ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0)) AS ResidualValueMan,
	|	ISNULL(ChangesTo_Y.ResidualValueLocal, ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal, 0)) AS ResidualValueLocal,
	|
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceLocal, 0) AS ImpairmentBalanceLocal,
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceMan, 0) AS ImpairmentBalanceMan,
	|
	|	ISNULL(ChangesTo_Y.FixedAssetsLocation, FALocation.FixedAssetsLocation) AS FixedAssetsLocation,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths AS UsefulLifeManagementAccounting,
	|	ISNULL(ChangesTo_Y.AccelerationFactor, ISNULL(FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor, 0)) AS AccelerationFactor,
	|	ISNULL(ChangesTo_Y.DepreciationMethod, FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod) AS DepreciationMethod
	|
	|INTO ListOfOSSWithChangedParameters_Y
	|
	|FROM
	|	ChangesTo_Y AS ChangesTo_Y
	|
	|		LEFT JOIN ListOfAccountingObjects_ AS ListOfFA
	|		ON (ListOfFA.Organization = ChangesTo_Y.Organization)
	|			AND (ListOfFA.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (ListOfFA.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure
	|		ON (FixedAssetsAccountingProcedure.Organization = UNDEFINED)
	|			AND (FixedAssetsAccountingProcedure.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (FixedAssetsAccountingProcedure.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|			AND (FixedAssetsAccountingProcedure.ParameterPeriod = ChangesTo_Y.ParameterPeriod)
	|
	|		LEFT JOIN OS_CostAtBeginningOfMonth AS FACost
	|		ON (FACost.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (FACost.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentAtBeginningOfMonth
	|		ON (ImpairmentAtBeginningOfMonth.Organization = ChangesTo_Y.Organization)
	|			AND (ImpairmentAtBeginningOfMonth.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (ImpairmentAtBeginningOfMonth.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN PreliminaryCostOfFA AS PreliminaryCostOfFA
	|		ON (PreliminaryCostOfFA.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (PreliminaryCostOfFA.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN OS_DepreciationAtBeginningOfMonth AS FixedAssetsDepreciationCharge
	|		ON (FixedAssetsDepreciationCharge.Organization = ChangesTo_Y.Organization)
	|			AND (FixedAssetsDepreciationCharge.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (FixedAssetsDepreciationCharge.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN FALocation AS FALocation
	|		ON (FALocation.Organization = UNDEFINED)
	|			AND (FALocation.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (FALocation.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|			AND (FALocation.ParameterPeriod = ChangesTo_Y.ParameterPeriod)
	|
	|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|		ON (InitialFixedAssetsInformation.Organization = ChangesTo_Y.Organization)
	|			AND (InitialFixedAssetsInformation.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (InitialFixedAssetsInformation.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|			AND (InitialFixedAssetsInformation.ParameterPeriod = ChangesTo_Y.ParameterPeriod)
	|
	|		LEFT JOIN FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
	|		ON (FixedAssetDepreciationParametersManagementAccounting.Organization = ChangesTo_Y.Organization)
	|			AND (FixedAssetDepreciationParametersManagementAccounting.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (FixedAssetDepreciationParametersManagementAccounting.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|			AND (FixedAssetDepreciationParametersManagementAccounting.ParameterPeriod = ChangesTo_Y.ParameterPeriod)
	|
	|		LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON (FixedAssetsAccountingProcedureManagementAccounting.Organization = ChangesTo_Y.Organization)
	|			AND (FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (FixedAssetsAccountingProcedureManagementAccounting.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|			AND (FixedAssetsAccountingProcedureManagementAccounting.ParameterPeriod = ChangesTo_Y.ParameterPeriod)
	|
	|		LEFT JOIN FAGeneration AS FAGeneration
	|		ON (FAGeneration.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset)
	|			AND (FAGeneration.RunningTimeValue = ISNULL(ChangesTo_Y.RunningTimeValue, FixedAssetsAccountingProcedure.RunningTimeValue))
	|			AND (FAGeneration.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN FAGeneration_AsOfLastMAChangeDate AS FAGeneration_AsOfDateOfLastChange
	|		ON (FAGeneration_AsOfDateOfLastChange.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset)
	|			AND (FAGeneration_AsOfDateOfLastChange.RunningTimeValue = ISNULL(ChangesTo_Y.RunningTimeValue, FixedAssetsAccountingProcedure.RunningTimeValue))
	|
	|		LEFT JOIN DatesWhenMaWasLastModified AS LastModifiedDates
	|		ON (LastModifiedDates.Organization = ChangesTo_Y.Organization)
	|			AND (LastModifiedDates.FixedAsset = ChangesTo_Y.FixedAsset)
	|			AND (LastModifiedDates.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|INDEX BY
	|	ThisIsAnAdditionalAccrual, 
	|	FixedAsset";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfOSSWithChangedParameters_BU_MU
	
	QueryText = 
	"SELECT
	|	ChangesTo_BU_M.Period AS Period,
	|	ChangesTo_BU_M.Recorder AS Recorder,
	|	ChangesTo_BU_M.BusinessOperation AS BusinessOperation,
	|	ChangesTo_BU_M.FixedAsset AS FixedAsset,
	|	ChangesTo_BU_M.Organization AS Organization,
	|	(ChangesTo_BU_M.BegOfMonth = &BeginningOfPreviousMonth) AS ThisIsAnAdditionalAccrual,
	|	ISNULL(PreliminaryCostOfFA.PreliminaryCostExceedsActualAC, FALSE) AS PreliminaryCostExceedsActual,
	|
	|	CASE
	|		WHEN MONTH(ChangesTo_BU_M.Period) < ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(ChangesTo_BU_M.Period, YEAR), MONTH, ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1) - 13)
	|		ELSE DATEADD(BEGINOFPERIOD(ChangesTo_BU_M.Period, YEAR), MONTH, ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1) - 1) 
	|	END AS BeginningOfFiscalYear,
	|	
	|	CASE
	|		WHEN MONTH(ChangesTo_BU_M.Period) < ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(ChangesTo_BU_M.Period, YEAR), MONTH, ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1) - 1)
	|		ELSE DATEADD(BEGINOFPERIOD(ChangesTo_BU_M.Period, YEAR), MONTH, ISNULL(ListOfFA.MonthOfFiscalYearBeginning, 1) + 11) 
	|	END AS EndOfFiscalYear,
	|
	|	ListOfFA.RevaluationMethod AS RevaluationMethod,
	|	ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	|	VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS ProcedureForCalculatingDepreciationAC,
	|	ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	ChangesTo_BU_M.ObtainedByDisassemblyCombining AS ObtainedByDisassemblyCombining, 
	|
	// NetBookValueLocal
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateMA, MONTH) = ChangesTo_BU_M.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfFA.CostInAccounting, 0)
	|		ELSE ISNULL(FACost.LocalCost, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|	END AS NetBookValueLocal,
	|
	// LocalCost
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateMA, MONTH) = ChangesTo_BU_M.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfFA.CostInAccounting, 0)
	|		WHEN ChangesTo_BU_M.BegOfMonth = &BeginningOfPreviousMonth
	|			THEN 0
	|		ELSE ISNULL(FACost.LocalCost, 0)
	|	END AS LocalCost,
	|
	|	ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) AS DepreciationLocal,
	|
	|	ChangesTo_BU_M.LocalCostUpdate AS LocalCostUpdate,
	|	ChangesTo_BU_M.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|
	|	ISNULL(ChangesTo_BU_M.FinancialAccountingGroup, FixedAssetsAccountingProcedure.FinancialAccountingGroup) AS FinancialAccountingGroup,
	|	ISNULL(ChangesTo_BU_M.LineOfBusiness, FixedAssetsAccountingProcedure.LineOfBusiness) AS LineOfBusiness,
	|	ISNULL(ChangesTo_BU_M.RunningTimeValue, FixedAssetsAccountingProcedure.RunningTimeValue) AS RunningTimeValue,
	|
	// ResourceAssigned
	|	CASE 
	|		WHEN ISNULL(ChangesTo_BU_M.DepreciationMethod, InitialFixedAssetsInformation.DepreciationMethodAccounting) = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(ChangesTo_BU_M.EstimatedRunningTime, ISNULL(OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits, 0))
	|		ELSE ISNULL(ChangesTo_BU_M.UsefulLifeMonths, ISNULL(OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth, 0))
	|	END AS ResourceAssigned,
	|
	// LifeSpentCurrentPeriod
	|	CAST(CAST(CASE 
	|		WHEN ISNULL(ChangesTo_BU_M.DepreciationMethod, InitialFixedAssetsInformation.DepreciationMethodAccounting) = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			THEN CASE
	|					WHEN ChangesTo_BU_M.BegOfMonth = &BeginningOfPreviousMonth
	|						THEN ISNULL(FAGeneration.VolumeOfOutputForPreviousPeriod, 0)
	|					ELSE ISNULL(FAGeneration.OutputVolumePerMonth, 0)
	|				END
	|		ELSE 1
	|	END AS NUMBER(15,9)) * CAST(ChangesTo_BU_M.ValidityPeriod AS NUMBER(15,9)) / CAST(DAY(ChangesTo_BU_M.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(20,8)) AS LifeSpentCurrentPeriod,
	|	  
	// LifeSpentPastPeriod
	|	CASE 
	|		WHEN OSBUDepreciationParameters.FixedAsset IS NULL
	|			THEN CAST(0 AS NUMBER(20,8))
	|
	|		WHEN BEGINOFPERIOD(ISNULL(ChangesTo_BU_M.LastChangeDate, OSBUDepreciationParameters.LastChangeDate), MONTH) = ChangesTo_BU_M.BegOfMonth
	|			THEN CAST(0 AS NUMBER(20,8))
	|	
	|		WHEN ISNULL(ChangesTo_BU_M.DepreciationMethod, InitialFixedAssetsInformation.DepreciationMethodAccounting) = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			THEN CASE
	|					WHEN ChangesTo_BU_M.BegOfMonth = &BeginningOfPreviousMonth
	|						THEN CAST(0 AS NUMBER(20,8))
	|					ELSE CAST(ISNULL(FAGeneration.VolumeOfOutputForPreviousPeriod, 0) 
	|									- ISNULL(FAGeneration_AsOfDateOfLastChange.OutputVolume, 0) AS NUMBER(20,8))
	|				END
	|
	|		ELSE
	|			CAST((DATEDIFF(ISNULL(ChangesTo_BU_M.LastChangeDate, OSBUDepreciationParameters.LastChangeDate), ENDOFPERIOD(ISNULL(ChangesTo_BU_M.LastChangeDate, OSBUDepreciationParameters.LastChangeDate), MONTH), DAY) + 1) 
	|						/ DAY(ENDOFPERIOD(ISNULL(ChangesTo_BU_M.LastChangeDate, OSBUDepreciationParameters.LastChangeDate), MONTH))
	|						+ DATEDIFF(BEGINOFPERIOD(DATEADD(ISNULL(ChangesTo_BU_M.LastChangeDate, OSBUDepreciationParameters.LastChangeDate), MONTH, 1), MONTH), ChangesTo_BU_M.EndOfMonth, MONTH) AS NUMBER(20,8))
	|	END AS LifeSpentPastPeriod,
	|
	// WorkedMonthsFullYears
	|	CASE
	|		WHEN YEAR(ISNULL(ChangesTo_BU_M.LastChangeDate, OSBUDepreciationParameters.LastChangeDate)) <> YEAR(ChangesTo_BU_M.BegOfMonth) THEN
	|			13 - MONTH(ISNULL(ChangesTo_BU_M.LastChangeDate, OSBUDepreciationParameters.LastChangeDate))
	|				+ 12 * (YEAR(ChangesTo_BU_M.BegOfMonth) - YEAR(ISNULL(ChangesTo_BU_M.LastChangeDate, OSBUDepreciationParameters.LastChangeDate)) - 1)
	|		ELSE 0
	|	END AS WorkedMonthsFullYears,
	|
	|	ISNULL(ChangesTo_BU_M.AccrueDepreciationOrAmortization, ISNULL(AccountingProcedureForOSBU.DepreciationAccrualAccounting, FALSE)) AS AccrueDepreciationOrAmortization,
	|	ISNULL(ChangesTo_BU_M.ExpenseItem, AccountingProcedureForOSBU.ExpenseItemAccounting) AS ExpenseItem,
	|	ISNULL(ChangesTo_BU_M.DimensionOfExpenses, AccountingProcedureForOSBU.ExpensesDimensionAccounting) AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN ISNULL(ChangesTo_BU_M.ExpensesBusinessUnit, AccountingProcedureForOSBU.DepartmentACC) <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ISNULL(ChangesTo_BU_M.ExpensesBusinessUnit, AccountingProcedureForOSBU.DepartmentACC) 
	|		ELSE ISNULL(ChangesTo_BU_M.FixedAssetsLocation, FALocation.FixedAssetsLocation) 
	|	END AS ExpensesBusinessUnit,
	|
	|	CASE
	|		WHEN ISNULL(ChangesTo_BU_M.ExpensesBusinessUnit, AccountingProcedureForOSBU.DepartmentACC) <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ISNULL(ChangesTo_BU_M.ExpenseLineOfBusiness, AccountingProcedureForOSBU.LineOfBusinessBookkeeping) 
	|		ELSE ISNULL(ChangesTo_BU_M.LineOfBusiness, FixedAssetsAccountingProcedure.LineOfBusiness) 
	|	END AS ExpenseLineOfBusiness,
	|
	|	ISNULL(ChangesTo_BU_M.DepreciationRecordMethod, AccountingProcedureForOSBU.DepreciationRecordMethodLA) AS DepreciationRecordMethod,
	|	ISNULL(ChangesTo_BU_M.TransferExpensesToAnotherCompany, ISNULL(AccountingProcedureForOSBU.TransferExpensesToAnotherCompany, FALSE)) AS TransferExpensesToAnotherCompany,
	|	ISNULL(ChangesTo_BU_M.CompanyRecipientOfExpenses, AccountingProcedureForOSBU.CompanyRecipientOfExpenses) AS CompanyRecipientOfExpenses,
	|
	|	ISNULL(ChangesTo_BU_M.ResidualValueMan, ISNULL(OSBUDepreciationParameters.ResidualValueMan, 0)) AS ResidualValueLocal,
	|
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceLocal, 0) AS ImpairmentBalanceLocal,
	|
	|	ISNULL(ChangesTo_BU_M.FixedAssetsLocation, FALocation.FixedAssetsLocation) AS FixedAssetsLocation,
	|
	|	ISNULL(ChangesTo_BU_M.AccelerationFactor, ISNULL(OSBUDepreciationParameters.AccelerationFactor, 0)) AS AccelerationFactor,
	|	ISNULL(ChangesTo_BU_M.DepreciationMethod, InitialFixedAssetsInformation.DepreciationMethodAccounting) AS DepreciationMethod
	|
	|INTO ListOfOSSWithChangedParameters_BU_MU
	|
	|FROM
	|	ChangesTo_BU_M AS ChangesTo_BU_M
	|
	|		LEFT JOIN ListOfAccountingObjects_BU_MU AS ListOfFA
	|		ON (ListOfFA.Organization = ChangesTo_BU_M.Organization)
	|			AND (ListOfFA.FixedAsset = ChangesTo_BU_M.FixedAsset)
	|			AND (ListOfFA.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure
	|		ON (FixedAssetsAccountingProcedure.Organization = UNDEFINED)
	|			AND (FixedAssetsAccountingProcedure.FixedAsset = ChangesTo_BU_M.FixedAsset)
	|			AND (FixedAssetsAccountingProcedure.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|			AND (FixedAssetsAccountingProcedure.ParameterPeriod = ChangesTo_BU_M.ParameterPeriod)
	|
	|		LEFT JOIN OS_CostAtBeginningOfMonth AS FACost
	|		ON (FACost.FixedAsset = ChangesTo_BU_M.FixedAsset)
	|			AND (FACost.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentAtBeginningOfMonth
	|		ON (ImpairmentAtBeginningOfMonth.Organization = ChangesTo_BU_M.Organization)
	|			AND (ImpairmentAtBeginningOfMonth.FixedAsset = ChangesTo_BU_M.FixedAsset)
	|			AND (ImpairmentAtBeginningOfMonth.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN PreliminaryCostOfFA AS PreliminaryCostOfFA
	|		ON (PreliminaryCostOfFA.FixedAsset = ChangesTo_BU_M.FixedAsset)
	|			AND (PreliminaryCostOfFA.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN OS_DepreciationAtBeginningOfMonth AS FixedAssetsDepreciationCharge
	|		ON (FixedAssetsDepreciationCharge.Organization = ChangesTo_BU_M.Organization)
	|			AND (FixedAssetsDepreciationCharge.FixedAsset = ChangesTo_BU_M.FixedAsset)
	|			AND (FixedAssetsDepreciationCharge.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN FALocation AS FALocation
	|		ON (FALocation.Organization = UNDEFINED)
	|			AND (FALocation.FixedAsset = ChangesTo_BU_M.FixedAsset)
	|			AND (FALocation.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|			AND (FALocation.ParameterPeriod = ChangesTo_BU_M.ParameterPeriod)
	|
	|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|		ON (InitialFixedAssetsInformation.Organization = ChangesTo_BU_M.Organization)
	|			AND (InitialFixedAssetsInformation.FixedAsset = ChangesTo_BU_M.FixedAsset)
	|			AND (InitialFixedAssetsInformation.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|			AND (InitialFixedAssetsInformation.ParameterPeriod = ChangesTo_BU_M.ParameterPeriod)
	|
	|		LEFT JOIN OSBUDepreciationParameters AS OSBUDepreciationParameters
	|		ON (OSBUDepreciationParameters.Organization = ChangesTo_BU_M.Organization)
	|			AND (OSBUDepreciationParameters.FixedAsset = ChangesTo_BU_M.FixedAsset)
	|			AND (OSBUDepreciationParameters.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|			AND (OSBUDepreciationParameters.ParameterPeriod = ChangesTo_BU_M.ParameterPeriod)
	|
	|		LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON (AccountingProcedureForOSBU.Organization = ChangesTo_BU_M.Organization)
	|			AND (AccountingProcedureForOSBU.FixedAsset = ChangesTo_BU_M.FixedAsset)
	|			AND (AccountingProcedureForOSBU.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|			AND (AccountingProcedureForOSBU.ParameterPeriod = ChangesTo_BU_M.ParameterPeriod)
	|
	|		LEFT JOIN FAGeneration AS FAGeneration
	|		ON (FAGeneration.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset)
	|			AND (FAGeneration.RunningTimeValue = ISNULL(ChangesTo_BU_M.RunningTimeValue, FixedAssetsAccountingProcedure.RunningTimeValue))
	|			AND (FAGeneration.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN FAGeneration_AsOfLastACChangeDate AS FAGeneration_AsOfDateOfLastChange
	|		ON (FAGeneration_AsOfDateOfLastChange.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset)
	|			AND (FAGeneration_AsOfDateOfLastChange.RunningTimeValue = ISNULL(ChangesTo_BU_M.RunningTimeValue, FixedAssetsAccountingProcedure.RunningTimeValue))
	|
	|INDEX BY
	|	ThisIsAnAdditionalAccrual, 
	|	FixedAsset";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region InventoryInOperation
	QueryText = 
	"SELECT DISTINCT
	|	ListOfAccountingObjects.FixedAsset AS FixedAsset
	|INTO GroupOS
	|FROM
	|	ListOfAccountingObjects AS ListOfAccountingObjects
	|WHERE
	|	ListOfAccountingObjects.FixedAsset.OSType = VALUE(Enum.FATypes.GroupFA)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LotsOfGoodsAndMaterials.Ref AS Ref
	|INTO LotsOfGoodsAndMaterials
	|FROM
	|	Catalog.LotsOfInventoryInOperation AS LotsOfGoodsAndMaterials
	|WHERE
	|	LotsOfGoodsAndMaterials.FixedAsset IN (
	|		SELECT
	|			GroupOS.FixedAsset
	|		FROM
	|			GroupOS AS GroupOS)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryInOperation.Lot.FixedAsset   AS FixedAsset,
	|
	|	InventoryInOperation.Organization               AS Organization,
	|	InventoryInOperation.Department             AS Department,
	|	InventoryInOperation.LineOfBusiness   AS LineOfBusiness,
	|
	|	InventoryInOperation.Products              AS Products,
	|	InventoryInOperation.Characteristic            AS Characteristic,
	|	InventoryInOperation.Series                     AS Series,
	|	InventoryInOperation.AssetID          AS AssetID,
	|	InventoryInOperation.Lot                    AS Lot,
	|	InventoryInOperation.CountBalance         AS Count,
	|
	|	RECORDAUTONUMBER()                          AS LineNumber
	|
	|INTO InventoryInOperation
	|
	|FROM
	|	AccumulationRegister.InventoryInOperation.Balance(
	|		&BeginningOfNextMonth,
	|		Lot IN (SELECT LotsOfGoodsAndMaterials.Ref FROM LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)) AS InventoryInOperation
	|
	|INDEX BY
	|	Organization,
	|	Products,
	|	Characteristic,
	|	Series,
	|	AssetID,
	|	Lot
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region InventoryInOperation_Price
	QueryText =
	"SELECT 
	|	Cost_Inventory.Organization AS Organization,
	|	Cost_Inventory.Products AS Products,
	|	Cost_Inventory.Characteristic AS Characteristic,
	|	Cost_Inventory.Series AS Series,
	|	Cost_Inventory.AssetID AS AssetID,
	|	Cost_Inventory.Lot AS Lot,
	|
	|	CASE
	|		WHEN SUM(Cost_Inventory.Count) <> 0
	|			THEN SUM(Cost_Inventory.CostMan) / SUM(Cost_Inventory.Count)
	|		ELSE 0
	|	END AS Price
	|
	|INTO InventoryInOperation_Price
	|
	|FROM
	|	InformationRegister.CostOfInventoryInOperation AS Cost_Inventory
	|
	|WHERE
	|	Cost_Inventory.Active
	|
	|	AND (Organization, Products, Characteristic, Series, AssetID, Lot) IN 
	|		(SELECT
	|			InventoryInOperation.Organization,
	|			InventoryInOperation.Products, 
	|			InventoryInOperation.Characteristic, 
	|			InventoryInOperation.Series, 
	|			InventoryInOperation.AssetID, 
	|			InventoryInOperation.Lot
	|		FROM
	|			InventoryInOperation AS InventoryInOperation)
	|
	|GROUP BY
	|	Cost_Inventory.Organization,
	|	Cost_Inventory.Products,
	|	Cost_Inventory.Characteristic,
	|	Cost_Inventory.Series,
	|	Cost_Inventory.AssetID,
	|	Cost_Inventory.Lot
	|
	|INDEX BY
	|	Organization,
	|	Products,
	|	Characteristic,
	|	Series,
	|	AssetID,
	|	Lot
	|";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region TMTSVOperation_Cost
	QueryText =
	"SELECT
	|	InventoryInOperation.FixedAsset         AS FixedAsset,
	|	InventoryInOperation.Organization              AS Organization,
	|	InventoryInOperation.Department            AS Department,
	|	InventoryInOperation.LineOfBusiness  AS LineOfBusiness,
	|	InventoryInOperation.LineNumber              AS LineNumber,
	|	InventoryInOperation.Count               AS Count,
	|	InventoryInOperation.Count * ISNULL(InventoryInOperation_Price.Price, 0) AS Cost
	|
	|INTO TMTSVOperation_Cost
	|
	|FROM
	|	InventoryInOperation AS InventoryInOperation
	|		
	|		LEFT JOIN InventoryInOperation_Price AS InventoryInOperation_Price
	|		ON InventoryInOperation_Price.Organization = InventoryInOperation.Organization
	|			AND InventoryInOperation_Price.Products = InventoryInOperation.Products
	|			AND InventoryInOperation_Price.Characteristic = InventoryInOperation.Characteristic
	|			AND InventoryInOperation_Price.Series = InventoryInOperation.Series
	|			AND InventoryInOperation_Price.AssetID = InventoryInOperation.AssetID
	|			AND InventoryInOperation_Price.Lot = InventoryInOperation.Lot";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region TMTSVOperation_Distribution
	QueryText =
	"SELECT
	|	TMTSVOperation_Cost.FixedAsset         AS FixedAsset,
	|	TMTSVOperation_Cost.Organization              AS Organization,
	|	TMTSVOperation_Cost.Department            AS Department,
	|	TMTSVOperation_Cost.LineOfBusiness  AS LineOfBusiness,
	|	SUM(TMTSVOperation_Cost.Cost)         AS Base,
	|	MAX(TMTSVOperation_Cost.LineNumber)    AS LineNumber
	|
	|INTO TMTSVOperation_Base
	|
	|FROM
	|	TMTSVOperation_Cost AS TMTSVOperation_Cost
	|
	|GROUP BY	
	|	TMTSVOperation_Cost.FixedAsset,
	|	TMTSVOperation_Cost.Organization,
	|	TMTSVOperation_Cost.Department,
	|	TMTSVOperation_Cost.LineOfBusiness
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TMTSVOperation_Base.FixedAsset         AS FixedAsset,
	|	SUM(TMTSVOperation_Base.Base)              AS BaseAmount
	|
	|INTO TMTSVOperation_AmountOfBase
	|
	|FROM
	|	TMTSVOperation_Base AS TMTSVOperation_Base
	|
	|GROUP BY	
	|	TMTSVOperation_Base.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TMTSVOperation_Base.FixedAsset         AS FixedAsset,
	|	TMTSVOperation_Base.LineNumber              AS LineNumber,
	|	SUM(TMTSVOperation_Base.Base)              AS BaseAccumulated
	|
	|INTO TMTSVOfOperation_AccumulatedDatabase
	|
	|FROM
	|	TMTSVOperation_Base AS TMTSVOperation_Base
	|
	|		LEFT JOIN TMTSVOperation_Base AS TMTSVOperation_Previous
	|		ON TMTSVOperation_Previous.FixedAsset = TMTSVOperation_Base.FixedAsset
	|			AND TMTSVOperation_Previous.LineNumber < TMTSVOperation_Base.LineNumber
	|
	|GROUP BY	
	|	TMTSVOperation_Base.FixedAsset,
	|	TMTSVOperation_Base.LineNumber
	|
	|INDEX BY
	|	FixedAsset,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TMTSVOperation_Base.FixedAsset           AS FixedAsset,
	|	TMTSVOperation_Base.Department              AS Department,
	|	TMTSVOperation_Base.LineOfBusiness    AS LineOfBusiness,
	|	TMTSVOperation_Base.Organization                AS Organization,
	|	TMTSVOperation_Base.Base                       AS Base,
	|	TMTSVOfOperation_AccumulatedDatabase.BaseAccumulated AS BaseAccumulated,
	|	TMTSVOperation_AmountOfBase.BaseAmount             AS BaseAmount
	|
	|INTO TMTSVOperation_Distribution
	|
	|FROM
	|	TMTSVOperation_Base AS TMTSVOperation_Base
	|		
	|		INNER JOIN TMTSVOfOperation_AccumulatedDatabase AS TMTSVOfOperation_AccumulatedDatabase
	|		ON TMTSVOfOperation_AccumulatedDatabase.FixedAsset = TMTSVOperation_Base.FixedAsset
	|			AND TMTSVOfOperation_AccumulatedDatabase.LineNumber = TMTSVOperation_Base.LineNumber
	|		
	|		INNER JOIN TMTSVOperation_AmountOfBase AS TMTSVOperation_AmountOfBase
	|		ON TMTSVOperation_AmountOfBase.FixedAsset = TMTSVOperation_Base.FixedAsset";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region WaysToReflectMADepreciation
	QueryText =
	"SELECT 
	|	ListOfFA.MethodOfReflectingDepreciationOfMA AS Ref
	|
	|INTO TTWaysToReflectDepreciationOfMA
	|
	|FROM 
	|	ListOfOSSParameters_UU AS ListOfFA
	|
	|WHERE 
	|	NOT ListOfFA.MethodOfReflectingDepreciationOfMA IN (&EmptyWaysToReflectDepreciation)
	|
	|UNION ALL
	|
	|SELECT 
	|	ListOfFA.DepreciationRecordMethod
	|
	|FROM 
	|	ListOfOSSWithParameters_BU_MU AS ListOfFA
	|
	|WHERE 
	|	NOT ListOfFA.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|
	|UNION ALL
	|
	|SELECT 
	|	ListOfFA.MethodOfReflectingDepreciationOfMA
	|
	|FROM 
	|	ListOfOSSWithChangedParameters_Y AS ListOfFA
	|
	|WHERE 
	|	NOT ListOfFA.MethodOfReflectingDepreciationOfMA IN (&EmptyWaysToReflectDepreciation)
	|
	|UNION ALL
	|
	|SELECT 
	|	ListOfFA.DepreciationRecordMethod
	|
	|FROM 
	|	ListOfOSSWithChangedParameters_BU_MU AS ListOfFA
	|
	|WHERE 
	|	NOT ListOfFA.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableDepreciation.Ref                               AS DepreciationRecordMethod,
	|	TableDepreciation.ExpenseItem                       AS ExpenseItem,
	|	TableDepreciation.DimensionOfExpenses                    AS DimensionOfExpenses,
	|	TableDepreciation.Department                        AS Department,
	|	TableDepreciation.LineOfBusiness              AS LineOfBusiness,
	|	TableDepreciation.BusinessUnitAndLineOfBusinessMatchAccountingData AS BusinessUnitAndLineOfBusinessMatchAccountingData,
	|	TableDepreciation.TransferExpensesToAnotherCompany  AS TransferExpensesToAnotherCompany,
	|	TableDepreciation.CompanyRecipientOfExpenses        AS CompanyRecipientOfExpenses,
	|	TableDepreciation.ZoomRatio                          AS Base,
	|	TableDepreciation.AmountOfPreviousRowsFactors    AS BaseAccumulated,
	|	TableDepreciation.Ref.DepreciationFactorAmount AS BaseAmount
	|
	|INTO WaysToReflectMADepreciation
	|
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4.Depreciation AS TableDepreciation
	|
	|WHERE
	|	TableDepreciation.Ref IN (SELECT WaysToReflectDepreciation.Ref FROM TTWaysToReflectDepreciationOfMA AS WaysToReflectDepreciation)
	|
	|UNION ALL
	|
	|SELECT
	|	TMTSVOperation_Distribution.FixedAsset         AS DepreciationRecordMethod,
	|	UNDEFINED                                            AS ExpenseItem,
	|	UNDEFINED                                            AS DimensionOfExpenses,
	|	TMTSVOperation_Distribution.Department            AS Department,
	|	TMTSVOperation_Distribution.LineOfBusiness  AS LineOfBusiness,
	|	FALSE                                                    AS BusinessUnitAndLineOfBusinessMatchAccountingData,
	|	TRUE                                                  AS TransferExpensesToAnotherCompany,
	|	TMTSVOperation_Distribution.Organization              AS CompanyRecipientOfExpenses,
	|	TMTSVOperation_Distribution.Base                     AS Base,
	|	TMTSVOperation_Distribution.BaseAccumulated          AS BaseAccumulated,
	|	TMTSVOperation_Distribution.BaseAmount                AS BaseAmount
	|FROM
	|	TMTSVOperation_Distribution AS TMTSVOperation_Distribution
	|
	|INDEX BY
	|	DepreciationRecordMethod";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	FixedAssetsDepreciationChargeLocalization.AddRequestTextParametersForCalculatingDepreciation_(ListOfRequests, CalculationParameters);
	
EndProcedure

Procedure QueryTextCheckingCalculationParameters(ListOfRequests, CalculationParameters)

	#Region CheckingCalculationParameters_Y
	QueryText =
	"SELECT
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.AccountingObject AS AccountingObject,
	|	ListOfFA.MaUsagePeriodIsNotSpecified AS MaUsagePeriodIsNotSpecified,
	|	ListOfFA.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
	|	ListOfFA.AmountOfOperatingTimeDeveloped AS AmountOfOperatingTimeDeveloped
	|
	|INTO CheckingCalculationParameters_Y
	|
	|FROM
	|	(SELECT
	|		ListOfFA.Organization AS Organization,
	|		ListOfFA.FixedAsset AS AccountingObject,
	|
			// MaUsagePeriodIsNotSpecified
	|		ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.Linear)
	|			AND ListOfFA.ResourceAssigned = 0
	|			AND (NOT ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|				OR ListOfFA.LifeSpentCurrentPeriod > 0) AS MaUsagePeriodIsNotSpecified,
	|
			// AmountOfOperatingTimeIsNotSpecified
	|		ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			AND ListOfFA.EstimatedRunningTime = 0
	|			AND (NOT ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|				OR ListOfFA.LifeSpentCurrentPeriod > 0) AS AmountOfOperatingTimeIsNotSpecified,
	|
			// AmountOfOperatingTimeDeveloped
	|		ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			AND ListOfFA.ResourceAssigned < (ListOfFA.LifeSpentPastPeriod + ListOfFA.LifeSpentCurrentPeriod)
	|			AND ListOfFA.ResourceAssigned <> 0
	|			AND ListOfFA.LifeSpentCurrentPeriod > 0 AS AmountOfOperatingTimeDeveloped
	|
	|	FROM
	|		ListOfOSSParameters_UU AS ListOfFA
	|
	|	WHERE
	|		ListOfFA.AccrueDepreciationOrAmortization
	|		AND ListOfFA.NetBookValue > 0
	|
	|	) AS ListOfFA
	|
	|WHERE
	|	(ListOfFA.MaUsagePeriodIsNotSpecified
	|		OR ListOfFA.AmountOfOperatingTimeIsNotSpecified
	|		OR ListOfFA.AmountOfOperatingTimeDeveloped)
	|
	|INDEX BY
	|	AccountingObject,
	|	Organization
	|";
	
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region CheckingCalculationParametersOf_BU_M
	QueryText =
	"SELECT
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.AccountingObject AS AccountingObject,
	|	ListOfFA.PeriodOfUseIsNotSpecified AS PeriodOfUseIsNotSpecified,
	|	ListOfFA.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
	|	ListOfFA.AmountOfOperatingTimeDeveloped AS AmountOfOperatingTimeDeveloped
	|
	|INTO CheckingCalculationParametersOf_BU_M
	|
	|FROM
	|	(SELECT
	|		ListOfFA.Organization AS Organization,
	|		ListOfFA.FixedAsset AS AccountingObject,
	|
			// PeriodOfUseIsNotSpecified
	|		ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.Linear)
	|			AND ListOfFA.ResourceAssigned = 0
	|			AND (NOT ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|				OR ListOfFA.LifeSpentCurrentPeriod > 0) AS PeriodOfUseIsNotSpecified,
	|
			// AmountOfOperatingTimeIsNotSpecified
	|		ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			AND ListOfFA.EstimatedRunningTime = 0
	|			AND ListOfFA.LifeSpentCurrentPeriod > 0 AS AmountOfOperatingTimeIsNotSpecified,
	|
			// AmountOfOperatingTimeDeveloped
	|		ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			AND ListOfFA.ResourceAssigned < (ListOfFA.LifeSpentPastPeriod + ListOfFA.LifeSpentCurrentPeriod)
	|			AND ListOfFA.EstimatedRunningTime <> 0
	|			AND ListOfFA.LifeSpentCurrentPeriod > 0 AS AmountOfOperatingTimeDeveloped
	|
	|	FROM
	|		ListOfOSSWithParameters_BU_MU AS ListOfFA
	|
	|	WHERE
	|		ListOfFA.AccrueDepreciationOrAmortization
	|		AND ListOfFA.NetBookValueLocal > 0
	|
	|	) AS ListOfFA
	|
	|WHERE
	|	(ListOfFA.PeriodOfUseIsNotSpecified
	|		OR ListOfFA.AmountOfOperatingTimeIsNotSpecified
	|		OR ListOfFA.AmountOfOperatingTimeDeveloped)
	|
	|INDEX BY
	|	AccountingObject,
	|	Organization
	|";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CheckingParametersForCalculatingChangesIn_Y
	
	QueryText =
	"SELECT
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.AccountingObject AS AccountingObject,
	|	ListOfFA.MaUsagePeriodIsNotSpecified AS MaUsagePeriodIsNotSpecified,
	|	ListOfFA.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
	|	ListOfFA.ResourceNotSpecified AS ResourceNotSpecified
	|
	|INTO CheckingParametersForCalculatingChangesIn_Y
	|
	|FROM
	|	(SELECT
	|		ListOfFA.Organization AS Organization,
	|		ListOfFA.FixedAsset AS AccountingObject,
	|
			// MaUsagePeriodIsNotSpecified
	|		ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.Linear)
	|			AND ISNULL(ListOfFA.ResourceAssigned, 0) = 0
	|			AND ListOfFA.LifeSpentCurrentPeriod > 0 AS MaUsagePeriodIsNotSpecified,
	|
			// AmountOfOperatingTimeIsNotSpecified
	|		ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			AND ISNULL(ListOfFA.ResourceAssigned, 0) = 0
	|			AND ListOfFA.LifeSpentCurrentPeriod > 0 AS AmountOfOperatingTimeIsNotSpecified,
	|
			// ResourceNotSpecified
	|		ListOfFA.LifeSpentCurrentPeriod IS NULL
	|			OR ListOfFA.LifeSpentPastPeriod IS NULL AS ResourceNotSpecified
	|
	|	FROM
	|		ListOfOSSWithChangedParameters_Y AS ListOfFA
	|
	|	WHERE
	|		ListOfFA.AccrueDepreciationOrAmortization
	|		AND (ListOfFA.NetBookValue + ListOfFA.CostUpdate) > 0
	|	
	|	) AS ListOfFA
	|
	|WHERE 
	|	(ListOfFA.MaUsagePeriodIsNotSpecified
	|		OR ListOfFA.AmountOfOperatingTimeIsNotSpecified
	|		OR ListOfFA.ResourceNotSpecified)
	|
	|INDEX BY
	|	AccountingObject";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CheckingParametersOfCalculationOfChangeOf_BU_M
	
	QueryText =
	"SELECT
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.AccountingObject AS AccountingObject,
	|	ListOfFA.PeriodOfUseIsNotSpecified AS PeriodOfUseIsNotSpecified,
	|	ListOfFA.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
	|	ListOfFA.ResourceNotSpecified AS ResourceNotSpecified
	|
	|INTO CheckingParametersOfCalculationOfChangeOf_BU_M
	|
	|FROM
	|	(SELECT
	|		ListOfFA.Organization AS Organization,
	|		ListOfFA.FixedAsset AS AccountingObject,
	|
			// MaUsagePeriodIsNotSpecified
	|		ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.Linear)
	|			AND ISNULL(ListOfFA.ResourceAssigned, 0) = 0
	|			AND ListOfFA.LifeSpentCurrentPeriod > 0 AS PeriodOfUseIsNotSpecified,
	|
			// AmountOfOperatingTimeIsNotSpecified
	|		ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|			AND ISNULL(ListOfFA.ResourceAssigned, 0) = 0
	|			AND ListOfFA.LifeSpentCurrentPeriod > 0 AS AmountOfOperatingTimeIsNotSpecified,
	|
			// ResourceNotSpecified
	|		ListOfFA.LifeSpentCurrentPeriod IS NULL
	|			OR ListOfFA.LifeSpentPastPeriod IS NULL AS ResourceNotSpecified
	|
	|	FROM
	|		ListOfOSSWithChangedParameters_BU_MU AS ListOfFA
	|
	|			LEFT JOIN WaysToReflectMADepreciation AS WaysToReflectDepreciation
	|			ON (WaysToReflectDepreciation.DepreciationRecordMethod = ListOfFA.DepreciationRecordMethod)
	|
	|	WHERE
	|		ListOfFA.AccrueDepreciationOrAmortization
	|		AND (ListOfFA.NetBookValueLocal + ListOfFA.LocalCostUpdate) > 0
	|	
	|	) AS ListOfFA
	|
	|WHERE 
	|	(ListOfFA.PeriodOfUseIsNotSpecified
	|		OR ListOfFA.AmountOfOperatingTimeIsNotSpecified
	|		OR ListOfFA.ResourceNotSpecified)
	|
	|INDEX BY
	|	AccountingObject";
	
	ListOfRequests.Add(QueryText);
	#EndRegion

	FixedAssetsDepreciationChargeLocalization.AddRequestTextCheckingCalculationParameters(ListOfRequests, CalculationParameters);
	
EndProcedure

Procedure QueryTextNumberOfCalculationParameters(ListOfRequests, CalculationParameters)
	
	QueryText =
	"SELECT
	|	ISNULL(COUNT(DISTINCT ListOfAccountingObjects.FixedAsset), 0) AS DataVolume
	|FROM
	|	ListOfAccountingObjects AS ListOfAccountingObjects
	|";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextCalculationOfDepreciation_Y(ListOfRequests, CalculationParameters)

	QueryText = 
	"SELECT
	|	Depreciation.CalculationPeriod AS CalculationPeriod,
	|	Depreciation.Organization AS Organization,
	|	Depreciation.Department AS Department,
	|	Depreciation.FixedAsset AS FixedAsset,
	|	ImpairmentFA.CGU AS CGU,
	|	Depreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Depreciation.LineOfBusiness AS LineOfBusiness,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.ExpenseItem IS NULL
	|				AND WaysToReflectDepreciation.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND WaysToReflectDepreciation.ExpenseItem <> UNDEFINED
	|			THEN WaysToReflectDepreciation.ExpenseItem
	|		ELSE Depreciation.ExpenseItem
	|	END AS ExpenseItem,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.ExpenseItem IS NULL
	|				AND WaysToReflectDepreciation.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND WaysToReflectDepreciation.ExpenseItem <> UNDEFINED
	|			THEN WaysToReflectDepreciation.DimensionOfExpenses
	|		ELSE Depreciation.DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|
	|	CASE 
	|		WHEN ISNULL(WaysToReflectDepreciation.BusinessUnitAndLineOfBusinessMatchAccountingData, FALSE)
	|				OR ISNULL(WaysToReflectDepreciation.Department, Depreciation.ExpensesBusinessUnit) = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Depreciation.Department
	|		ELSE ISNULL(WaysToReflectDepreciation.Department, Depreciation.ExpensesBusinessUnit) 
	|	END AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN ISNULL(WaysToReflectDepreciation.BusinessUnitAndLineOfBusinessMatchAccountingData, FALSE)
	|			THEN Depreciation.LineOfBusiness
	|		ELSE ISNULL(WaysToReflectDepreciation.LineOfBusiness, Depreciation.ExpenseLineOfBusiness) 
	|	END AS CorLineOfBusiness,
	|
	|	Depreciation.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.CompanyRecipientOfExpenses IS NULL
	|				AND WaysToReflectDepreciation.TransferExpensesToAnotherCompany
	|				AND WaysToReflectDepreciation.CompanyRecipientOfExpenses <> Depreciation.Organization
	|			THEN TRUE
	|		ELSE Depreciation.TransferExpensesToAnotherCompany
	|	END AS TransferExpensesToAnotherCompany,
	|
	|	ISNULL(WaysToReflectDepreciation.CompanyRecipientOfExpenses, Depreciation.CompanyRecipientOfExpenses) AS CompanyRecipientOfExpenses,
	|
	|	Depreciation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	Depreciation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	Depreciation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	Depreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	Depreciation.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|	Depreciation.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|
	|	Depreciation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	Depreciation.ThisIsAnAdditionalAccrual AS ThisIsAnAdditionalAccrual,
	|	Depreciation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	Depreciation.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|	Depreciation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	Depreciation.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|
	|	CASE
	|		WHEN NOT Depreciation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfSumOfMa
	|		ELSE Depreciation.AmountOfUU
	|	END AS AmountOfUU,
	|
	|	CASE
	|		WHEN NOT Depreciation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfACAmount
	|		ELSE Depreciation.AmountAccounting
	|	END AS AmountAccounting,
	|
	|	CASE
	|		WHEN NOT Depreciation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfMaImpairment
	|		ELSE Depreciation.ImpairmentMA
	|	END AS ImpairmentMA,
	|
	|	CASE
	|		WHEN NOT Depreciation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfACImpairment
	|		ELSE Depreciation.ImpairmentAC
	|	END AS ImpairmentAC
	|
	|INTO CalculationOfDepreciation_Y
	|
	|FROM
	|	(SELECT
	|		ListOfFA.Period AS CalculationPeriod,
	|		ListOfFA.Organization AS Organization,
	|		CAST(ListOfFA.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
	|		ListOfFA.Department AS Department,
	|		ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfFA.LineOfBusiness AS LineOfBusiness,
	|		ListOfFA.FixedAsset AS FixedAsset,
	|		ListOfFA.ExpenseItem AS ExpenseItem,
	|		ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfFA.AmountOfUU AS AmountOfUU,
	|
	|		CASE
	|			WHEN ListOfFA.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN ListOfFA.AmountAccounting
	|			ELSE NULL
	|		END AS AmountAccounting,
	|
	|		ListOfFA.ImpairmentMA AS ImpairmentMA,
	|		ListOfFA.ImpairmentAC AS ImpairmentAC,
	|		ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfFA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|
	|		CASE
	|			WHEN ListOfFA.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN ListOfFA.CostUsedToCalculateDepreciationLocal
	|			ELSE NULL
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		ListOfFA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfFA.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|		ListOfFA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|		ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|		ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		ListOfFA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		FALSE AS ThisIsAnAdditionalAccrual
	|
	|	FROM
	|		CalculationOfDepreciation_ForCurrentMonth_UnchangedMA AS ListOfFA
	|
	|	WHERE
	|		(ListOfFA.AmountOfUU <> 0
	|			OR ListOfFA.AmountAccounting <> 0
	|				AND ListOfFA.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ListOfFA.Period,
	|		ListOfFA.Organization,
	|		CAST(ListOfFA.Organization AS Catalog.Companies).ParentCompany,
	|		ListOfFA.Department,
	|		ListOfFA.FinancialAccountingGroup,
	|		ListOfFA.LineOfBusiness,
	|		ListOfFA.FixedAsset,
	|		ListOfFA.ExpenseItem,
	|		ListOfFA.DimensionOfExpenses,
	|		ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfFA.DepreciationRecordMethod,
	|		ListOfFA.AmountOfUU,
	|
	|		CASE
	|			WHEN ListOfFA.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN ListOfFA.AmountAccounting
	|			ELSE NULL
	|		END AS AmountAccounting,
	|
	|		ListOfFA.ImpairmentMA AS ImpairmentMA,
	|		ListOfFA.ImpairmentAC AS ImpairmentAC,
	|		ListOfFA.TransferExpensesToAnotherCompany,
	|		ListOfFA.CompanyRecipientOfExpenses,
	|		ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|
	|		ListOfFA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|
	|		CASE
	|			WHEN ListOfFA.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN ListOfFA.CostUsedToCalculateDepreciationLocal
	|			ELSE NULL
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		ListOfFA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfFA.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|		ListOfFA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|		ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|		ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		ListOfFA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		FALSE AS ThisIsAnAdditionalAccrual
	|
	|	FROM
	|		CalculationOfDepreciation_ForCurrentMonth_TakingIntoAccountChangesInMA AS ListOfFA
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ListOfFA.CalculationPeriod AS CalculationPeriod,
	|		ListOfFA.Organization AS Organization,
	|		CAST(ListOfFA.Organization AS Catalog.Companies).ParentCompany,
	|		ListOfFA.Department AS Department,
	|		ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfFA.LineOfBusiness AS LineOfBusiness,
	|		ListOfFA.FixedAsset AS FixedAsset,
	|		ListOfFA.ExpenseItem AS ExpenseItem,
	|		ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfFA.AmountOfUU AS AmountOfUU,
	|
	|		CASE
	|			WHEN ListOfFA.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN ListOfFA.AmountAccounting
	|			ELSE NULL
	|		END AS AmountAccounting,
	|
	|		0 AS ImpairmentMA,
	|		0 AS ImpairmentAC,
	|		ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfFA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|
	|		CASE
	|			WHEN ListOfFA.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN ListOfFA.CostUsedToCalculateDepreciationLocal
	|			ELSE NULL
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		0 AS ImpairmentBalanceLocal,
	|		0 AS ImpairmentBalanceMan,
	|		ListOfFA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|		ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		ListOfFA.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting,
	|		ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		ListOfFA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		TRUE AS ThisIsAnAdditionalAccrual
	|	FROM
	|		CalculationOfDepreciation_ForLastMonthMA AS ListOfFA
	|
	|	) AS Depreciation
	|
	|		LEFT JOIN WaysToReflectMADepreciation AS WaysToReflectDepreciation
	|		ON (WaysToReflectDepreciation.DepreciationRecordMethod = Depreciation.DepreciationRecordMethod)
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Organization = Depreciation.Organization
	|			AND ImpairmentFA.FixedAsset = Depreciation.FixedAsset
	|";
	
	QueryText = StrReplace(
		QueryText, 
		"&DistributionOfSumOfMa", 
		NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.AmountOfUU"));
	
	QueryText = StrReplace(
		QueryText, 
		"&DistributionOfACAmount", 
		NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.AmountAccounting"));
	
	QueryText = StrReplace(
		QueryText, 
		"&DistributionOfMaImpairment", 
		NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.ImpairmentMA"));
	
	QueryText = StrReplace(
		QueryText, 
		"&DistributionOfACImpairment", 
		NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.ImpairmentAC"));
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextCalculationOfDepreciation_BU_MU(ListOfRequests, CalculationParameters)

	QueryText = 
	"SELECT
	|	Depreciation.CalculationPeriod AS CalculationPeriod,
	|	Depreciation.Organization AS Organization,
	|	Depreciation.Department AS Department,
	|	Depreciation.FixedAsset AS FixedAsset,
	|	ImpairmentFA.CGU AS CGU,
	|	Depreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Depreciation.LineOfBusiness AS LineOfBusiness,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.ExpenseItem IS NULL
	|				AND WaysToReflectDepreciation.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND WaysToReflectDepreciation.ExpenseItem <> UNDEFINED
	|			THEN WaysToReflectDepreciation.ExpenseItem
	|		ELSE Depreciation.ExpenseItem
	|	END AS ExpenseItem,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.ExpenseItem IS NULL
	|				AND WaysToReflectDepreciation.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND WaysToReflectDepreciation.ExpenseItem <> UNDEFINED
	|			THEN WaysToReflectDepreciation.DimensionOfExpenses
	|		ELSE Depreciation.DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|
	|	CASE 
	|		WHEN ISNULL(WaysToReflectDepreciation.BusinessUnitAndLineOfBusinessMatchAccountingData, FALSE)
	|				OR ISNULL(WaysToReflectDepreciation.Department, Depreciation.ExpensesBusinessUnit) = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Depreciation.Department
	|		ELSE ISNULL(WaysToReflectDepreciation.Department, Depreciation.ExpensesBusinessUnit) 
	|	END AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN ISNULL(WaysToReflectDepreciation.BusinessUnitAndLineOfBusinessMatchAccountingData, FALSE)
	|			THEN Depreciation.LineOfBusiness
	|		ELSE ISNULL(WaysToReflectDepreciation.LineOfBusiness, Depreciation.ExpenseLineOfBusiness) 
	|	END AS CorLineOfBusiness,
	|
	|	Depreciation.DepreciationRecordMethod,
	|
	|	CASE
	|		WHEN NOT WaysToReflectDepreciation.CompanyRecipientOfExpenses IS NULL
	|				AND WaysToReflectDepreciation.TransferExpensesToAnotherCompany
	|				AND WaysToReflectDepreciation.CompanyRecipientOfExpenses <> Depreciation.Organization
	|			THEN TRUE
	|		ELSE Depreciation.TransferExpensesToAnotherCompany
	|	END AS TransferExpensesToAnotherCompany,
	|
	|	ISNULL(WaysToReflectDepreciation.CompanyRecipientOfExpenses, Depreciation.CompanyRecipientOfExpenses) AS CompanyRecipientOfExpenses,
	|
	|	Depreciation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	Depreciation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	Depreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	Depreciation.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|
	|	Depreciation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	Depreciation.ThisIsAnAdditionalAccrual AS ThisIsAnAdditionalAccrual,
	|	Depreciation.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|	Depreciation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	Depreciation.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|
	|	CASE
	|		WHEN NOT Depreciation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfACAmount
	|		ELSE Depreciation.AmountAccounting
	|	END AS AmountAccounting,
	|
	|	CASE
	|		WHEN NOT Depreciation.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|				AND NOT WaysToReflectDepreciation.DepreciationRecordMethod IS NULL
	|			THEN &DistributionOfACImpairment
	|		ELSE Depreciation.ImpairmentAC
	|	END AS ImpairmentAC
	|
	|INTO CalculationOfDepreciation_BU_MU
	|
	|FROM
	|	(SELECT
	|		ListOfFA.Period AS CalculationPeriod,
	|		ListOfFA.Organization AS Organization,
	|		CAST(ListOfFA.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
	|		ListOfFA.Department AS Department,
	|		ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfFA.LineOfBusiness AS LineOfBusiness,
	|		ListOfFA.FixedAsset AS FixedAsset,
	|		ListOfFA.ExpenseItem AS ExpenseItem,
	|		ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfFA.AmountAccounting AS AmountAccounting,
	|		ListOfFA.ImpairmentAC AS ImpairmentAC,
	|		ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfFA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		ListOfFA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfFA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		ListOfFA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		FALSE AS ThisIsAnAdditionalAccrual
	|	FROM
	|		CalculationOfDepreciation_ForCurrentMonth_UnchangedBU_MU AS ListOfFA
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ListOfFA.Period,
	|		ListOfFA.Organization,
	|		CAST(ListOfFA.Organization AS Catalog.Companies).ParentCompany,
	|		ListOfFA.Department,
	|		ListOfFA.FinancialAccountingGroup,
	|		ListOfFA.LineOfBusiness,
	|		ListOfFA.FixedAsset,
	|		ListOfFA.ExpenseItem,
	|		ListOfFA.DimensionOfExpenses,
	|		ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfFA.DepreciationRecordMethod,
	|		ListOfFA.AmountAccounting,
	|		ListOfFA.ImpairmentAC AS ImpairmentAC,
	|		ListOfFA.TransferExpensesToAnotherCompany,
	|		ListOfFA.CompanyRecipientOfExpenses,
	|		ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfFA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		ListOfFA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfFA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		ListOfFA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		FALSE AS ThisIsAnAdditionalAccrual
	|	FROM
	|		CalculationOfDepreciation_ForCurrentMonth_TakingIntoAccountChangesInBU_MU AS ListOfFA
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ListOfFA.CalculationPeriod AS CalculationPeriod,
	|		ListOfFA.Organization AS Organization,
	|		CAST(ListOfFA.Organization AS Catalog.Companies).ParentCompany,
	|		ListOfFA.Department AS Department,
	|		ListOfFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfFA.LineOfBusiness AS LineOfBusiness,
	|		ListOfFA.FixedAsset AS FixedAsset,
	|		ListOfFA.ExpenseItem AS ExpenseItem,
	|		ListOfFA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfFA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfFA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfFA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfFA.AmountAccounting AS AmountAccounting,
	|		0 AS ImpairmentAC,
	|		ListOfFA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfFA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfFA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		0 AS ImpairmentBalanceLocal,
	|		ListOfFA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		ListOfFA.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|		ListOfFA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		ListOfFA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		TRUE AS ThisIsAnAdditionalAccrual
	|	FROM
	|		CalculationOfDepreciation_ForLastMonthBU_MU AS ListOfFA
	|
	|	) AS Depreciation
	|
	|		LEFT JOIN WaysToReflectMADepreciation AS WaysToReflectDepreciation
	|		ON (WaysToReflectDepreciation.DepreciationRecordMethod = Depreciation.DepreciationRecordMethod)
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.FixedAsset = Depreciation.FixedAsset
	|";
	
	QueryText = StrReplace(
		QueryText, 
		"&DistributionOfACAmount", 
		NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.AmountAccounting"));
	
	QueryText = StrReplace(
		QueryText, 
		"&DistributionOfACImpairment", 
		NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.ImpairmentAC"));
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextAccruedDepreciation(ListOfRequests, CalculationParameters)

	ListOfSubqueries = New Array;
	
	SubqueryText =  
	"	SELECT
	|		UNDEFINED AS Ref,
	|		DepreciationCalculation.CalculationPeriod AS CalculationPeriod,
	|		DepreciationCalculation.CalculationPeriod AS AccrualPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.DebitBusinessUnit AS DebitBusinessUnit,
	|		DepreciationCalculation.FixedAsset AS FixedAsset,
	|		DepreciationCalculation.CGU AS CGU,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.CorLineOfBusiness AS CorLineOfBusiness,
	|		DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|		DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|		DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		FALSE AS AccrueDepreciation,
	|
	|		DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.LifeSpentPastPeriod
	|			ELSE NULL
	|		END AS LifeSpentPastPeriodAccounting,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.LifeSpentCurrentPeriod
	|			ELSE NULL
	|		END AS LifeSpentCurrentPeriodAccounting,
	|
	|		DepreciationCalculation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.CostUsedToCalculateDepreciationLocal
	|			ELSE NULL
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.ImpairmentBalanceLocal
	|			ELSE NULL
	|		END AS ImpairmentBalanceLocal,
	|
	|		DepreciationCalculation.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|
	|		DepreciationCalculation.ThisIsAnAdditionalAccrual AS ThisIsAnAdditionalAccrual,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.ThisIsAnAdditionalAccrual
	|			ELSE NULL
	|		END AS ThisIsAdditionalChargeAccounting,
	|
	|		FALSE AS ThisIsRecordingOfDifference,
	|		FALSE AS ThisIsAdjustmentOfDepreciationForPreviousPeriod,
	|		DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingProcedureMA,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.AccountingPolicyForFixedAssets
	|			ELSE NULL
	|		END AS AccountingProcedureAC,
	|
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa
	|			ELSE NULL
	|		END AS ProcedureForCalculatingDepreciationAC,
	|
	|		DepreciationCalculation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		DepreciationCalculation.VersionOfAccrualMethod AS DepreciationMethodVersionMA,
	|		DepreciationCalculation.VersionOfAccrualMethod AS DepreciationMethodVersionLA,
	|
	|		DepreciationCalculation.AmountOfUU AS AmountOfUU,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.AmountAccounting
	|			ELSE 0
	|		END AS AmountAccounting,
	|
	|		0 AS AmountFA,
	|		0 AS AmountPermanentDifferences,
	|		0 AS AmountTemporaryDifferences,
	|		0 AS CFAmount,
	|		0 AS SumOfNUCF,
	|		0 AS PRCFAmount,
	|		0 AS AmountOfVRCF,
	|
	|		DepreciationCalculation.ImpairmentMA AS ImpairmentMA,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.ImpairmentAC
	|			ELSE 0
	|		END AS ImpairmentAC,
	|		
	|		0 AS ImpairmentOfCF
	|
	|	FROM
	|		CalculationOfDepreciation_Y AS DepreciationCalculation
	|
	|	UNION ALL
	|
	|	SELECT
	|		UNDEFINED AS Ref,
	|		DepreciationCalculation.CalculationPeriod AS CalculationPeriod,
	|		DepreciationCalculation.CalculationPeriod AS AccrualPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.DebitBusinessUnit AS DebitBusinessUnit,
	|		DepreciationCalculation.FixedAsset AS FixedAsset,
	|		DepreciationCalculation.CGU AS CGU,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.CorLineOfBusiness AS CorLineOfBusiness,
	|		DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|		DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|		DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		FALSE AS AccrueDepreciation,
	|
	|		0 AS LifeSpentPastPeriod,
	|		0 AS LifeSpentCurrentPeriod,
	|
	|		DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriodAccounting,
	|		DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriodAccounting,
	|
	|		0 AS CostUsedToCalculateDepreciationManag,
	|		DepreciationCalculation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		DepreciationCalculation.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		0 AS ImpairmentBalanceMan,
	|		FALSE AS ThisIsAnAdditionalAccrual,
	|		DepreciationCalculation.ThisIsAnAdditionalAccrual AS ThisIsAdditionalChargeAccounting,
	|		FALSE AS ThisIsRecordingOfDifference,
	|		FALSE AS ThisIsAdjustmentOfDepreciationForPreviousPeriod,
	|		UNDEFINED AS AccountingProcedureMA,
	|		DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingProcedureAC,
	|		UNDEFINED AS ProcedureForCalculatingDepreciationOfMa,
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		DepreciationCalculation.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|		0 AS DepreciationMethodVersionMA,
	|		DepreciationCalculation.VersionOfAccrualMethod AS DepreciationMethodVersionLA,
	|
	|		0 AS AmountOfUU,
	|
	|		DepreciationCalculation.AmountAccounting AS AmountAccounting,
	|
	|		0 AS AmountFA,
	|		0 AS AmountPermanentDifferences,
	|		0 AS AmountTemporaryDifferences,
	|		0 AS CFAmount,
	|		0 AS SumOfNUCF,
	|		0 AS PRCFAmount,
	|		0 AS AmountOfVRCF,
	|
	|		0 AS ImpairmentMA,
	|
	|		CASE 
	|			WHEN NOT &ComplianceCAAccountingIsKept
	|				THEN DepreciationCalculation.ImpairmentAC
	|			ELSE 0
	|		END AS ImpairmentAC,
	|		
	|		0 AS ImpairmentOfCF
	|
	|	FROM
	|		CalculationOfDepreciation_BU_MU AS DepreciationCalculation
	|
	|	UNION ALL
	|
	|	SELECT
	|		UNDEFINED AS Ref,
	|		DepreciationCalculation.CalculationPeriod AS CalculationPeriod,
	|		DepreciationCalculation.AccrualPeriod AS AccrualPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.DebitBusinessUnit AS DebitBusinessUnit,
	|		DepreciationCalculation.FixedAsset AS FixedAsset,
	|		VALUE(Catalog.CashGeneratingUnits.EmptyRef) AS CGU,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.CorLineOfBusiness AS CorLineOfBusiness,
	|		DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|		DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|		DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		FALSE AS AccrueDepreciation,
	|		DepreciationCalculation.ResourceDevelopedOverPastPeriodMA AS LifeSpentPastPeriod,
	|		DepreciationCalculation.ResourceDevelopedForCurPeriodMA AS LifeSpentCurrentPeriod,
	|		DepreciationCalculation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|		DepreciationCalculation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|		DepreciationCalculation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|		DepreciationCalculation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		0 AS ImpairmentBalanceLocal,
	|		0 AS ImpairmentBalanceMan,
	|
	|		CASE
	|			WHEN BEGINOFPERIOD(DepreciationCalculation.AccrualPeriod, MONTH) < BEGINOFPERIOD(DepreciationCalculation.CalculationPeriod, MONTH)
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ThisIsAnAdditionalAccrual,
	|
	|		CASE
	|			WHEN BEGINOFPERIOD(DepreciationCalculation.AccrualPeriod, MONTH) < BEGINOFPERIOD(DepreciationCalculation.CalculationPeriod, MONTH)
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ThisIsAdditionalChargeAccounting,
	|
	|		DepreciationCalculation.ThisIsRecordingOfDifference AS ThisIsRecordingOfDifference,
	|
	|		CASE
	|			WHEN BEGINOFPERIOD(DepreciationCalculation.AccrualPeriod, MONTH) < BEGINOFPERIOD(DepreciationCalculation.CalculationPeriod, MONTH)
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ThisIsAdjustmentOfDepreciationForPreviousPeriod,
	|
	|		DepreciationCalculation.AccountingProcedureMA AS AccountingProcedureMA,
	|		DepreciationCalculation.AccountingProcedureAC AS AccountingProcedureAC,
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		UNDEFINED AS PostingOptionForImpairedFADepreciation,
	|		DepreciationCalculation.DepreciationMethodVersionMA AS DepreciationMethodVersionMA,
	|		DepreciationCalculation.DepreciationMethodVersionLA AS DepreciationMethodVersionLA,
	|
	|		CASE
	|			WHEN DepreciationCalculation.AmountOfUU > 0
	|				THEN DepreciationCalculation.AmountOfUU 
	|			ELSE 0
	|		END AS AmountOfUU,
	|
	|		CASE
	|			WHEN DepreciationCalculation.AmountAccounting > 0
	|				THEN DepreciationCalculation.AmountAccounting 
	|			ELSE 0
	|		END AS AmountAccounting,
	|
	|		CASE
	|			WHEN DepreciationCalculation.AmountFA > 0
	|				THEN DepreciationCalculation.AmountFA 
	|			ELSE 0
	|		END AS AmountFA,
	|
	|		CASE
	|			WHEN DepreciationCalculation.AmountAccounting > 0
	|				THEN DepreciationCalculation.AmountPermanentDifferences 
	|			ELSE 0
	|		END AS AmountPermanentDifferences,
	|
	|		CASE
	|			WHEN DepreciationCalculation.AmountAccounting > 0
	|				THEN DepreciationCalculation.AmountAccounting - DepreciationCalculation.AmountPermanentDifferences
	|			ELSE 0
	|		END
	|			- CASE
	|			WHEN DepreciationCalculation.AmountFA > 0
	|				THEN DepreciationCalculation.AmountFA 
	|			ELSE 0
	|		END AS AmountTemporaryDifferences,
	|
	|		CASE
	|			WHEN DepreciationCalculation.CFAmount > 0
	|				THEN DepreciationCalculation.CFAmount 
	|			ELSE 0
	|		END AS CFAmount,
	|
	|		0 AS SumOfNUCF,
	|
	|		CASE
	|			WHEN DepreciationCalculation.CFAmount > 0
	|				THEN DepreciationCalculation.PRCFAmount 
	|			ELSE 0
	|		END AS PRCFAmount,
	|
	|		CASE
	|			WHEN DepreciationCalculation.CFAmount > 0
	|				THEN DepreciationCalculation.CFAmount - DepreciationCalculation.PRCFAmount
	|			ELSE 0
	|		END AS AmountOfVRCF,
	|
	|		0 AS ImpairmentMA,
	|		0 AS ImpairmentAC,
	|		0 AS ImpairmentOfCF
	|
	|	FROM
	|		DepreciationAdjustmentForPreviousPeriod AS DepreciationCalculation
	|
	|	WHERE
	|		DepreciationCalculation.AmountOfUU > 0
	|			OR DepreciationCalculation.AmountAccounting > 0
	|			OR DepreciationCalculation.AmountFA > 0
	|			OR DepreciationCalculation.CFAmount > 0
	|";
	ListOfSubqueries.Add(SubqueryText);
	
	FixedAssetsDepreciationChargeLocalization.AddTextOfSubqueryAccruedDepreciation(ListOfSubqueries, CalculationParameters);
	
	SubqueryText = StrConcat(ListOfSubqueries, TMCommonUse.QuerySeparatorInJoin());
	
	RequestTextTTAccruedDepreciation(ListOfRequests, SubqueryText);
	
EndProcedure

Function QueryTextNumberOfProcessedData(CalculationParameters)

	QueryText = FixedAssetsDepreciationChargeLocalization.QueryTextNumberOfProcessedData(CalculationParameters); 
	
	If QueryText = Undefined Then
		
		QueryText =  
		"SELECT
		|	ISNULL(COUNT(DepreciationCalculation.FixedAsset), 0) AS DataVolume
		|FROM
		|	(SELECT
		|		DepreciationCalculation.FixedAsset AS FixedAsset
		|	FROM
		|		CalculationOfDepreciation_Y AS DepreciationCalculation
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DepreciationCalculation.FixedAsset
		|	FROM
		|		CalculationOfDepreciation_BU_MU AS DepreciationCalculation) AS DepreciationCalculation";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// 
// Parameters:
//  RequestTextParameters - See QueryTextParametersAmountOfMaDepreciation
//  CalculationParameters - See FixedAssetDepreciationCalculation.ExecutionParameters
// 
// Returns:
//  String - Query text
Function QueryTextAmountOfMaDepreciation(RequestTextParameters, CalculationParameters = Undefined) Export
	
	QueryText = 
	"CASE 
	|	WHEN NOT ListOfFA.AccrueDepreciationOrAmortization 
	|			OR (&NetBookValue - &AmountOfAdditionalCharge - &ResidualValueMan - &ImpairmentBalance) = 0
	|			OR (&NetBookValue - &AmountOfAdditionalCharge - &ResidualValueMan - &ImpairmentBalance) <= 0
	|				AND (&NetBookValue - &AmountOfAdditionalCharge - &ImpairmentBalance) >= 0
	|			OR (&NetBookValue - &AmountOfAdditionalCharge - &ImpairmentBalance) < 0
	|				AND (NOT ListOfFA.ConsiderResidualLiabilityValue
	|					OR NOT ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|					OR ListOfFA.DepreciationMethod <> VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.Linear)
	|						AND ListOfFA.DepreciationMethod <> VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction))
	|			OR ListOfFA.LifeSpentCurrentPeriod <= 0 
	|
	|		THEN 0
	|";
	
	If CalculationParameters = Undefined
		Or CalculationParameters.AccountingProcedureForVNAAccordingToIntStandardsIsApplied Then

		QueryText = QueryText +
		"	WHEN ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
		|				AND (ListOfFA.LifeSpentPastPeriod + ListOfFA.LifeSpentCurrentPeriod) >= ListOfFA.ResourceAssigned
		|
		|		THEN &NetBookValue - &AmountOfAdditionalCharge - &ResidualValueMan - &ImpairmentBalance
		|
			// Linear, proportional to the volume of production
		|	WHEN ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
		|			AND ListOfFA.DepreciationMethod IN (
		|						VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.Linear),
		|						VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)) 
		|
		|		THEN CASE 
		|			WHEN ListOfFA.ThisIsAnAdditionalAccrual
		|				THEN CAST(CAST(&CostUsedToCalculateDepreciationManag - &AmountOfAdditionalCharge AS NUMBER(20,8))
		|								* CAST(ListOfFA.LifeSpentCurrentPeriod AS NUMBER(20,8)) 
		|								/ CAST(ListOfFA.ResourceAssigned - ListOfFA.LifeSpentPastPeriod AS NUMBER(20,8)) AS NUMBER(31,2))
		|
		|			WHEN (&NetBookValue - &AmountOfAdditionalCharge - &ImpairmentBalance) < 0
		|					AND ListOfFA.ConsiderResidualLiabilityValue
		|
		|				THEN CAST(CAST(&CostUsedToCalculateDepreciationManag - &AmountOfAdditionalCharge - &ImpairmentBalance AS NUMBER(20,8)) 
		|								* CAST(ListOfFA.LifeSpentCurrentPeriod AS NUMBER(20,8))
		|								/ CAST(ListOfFA.ResourceAssigned - ListOfFA.LifeSpentPastPeriod AS NUMBER(20,8)) AS NUMBER(31,2))
		|
		|			ELSE CAST(CAST(&CostUsedToCalculateDepreciationManag - &AmountOfAdditionalCharge - &ResidualValueMan - &ImpairmentBalance AS NUMBER(20,8)) 
		|								* CAST(ListOfFA.LifeSpentCurrentPeriod AS NUMBER(20,8))
		|								/ CAST(ListOfFA.ResourceAssigned - ListOfFA.LifeSpentPastPeriod AS NUMBER(20,8)) AS NUMBER(31,2))
		|		END
		|
			// ReducedBalance
		|	WHEN ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
		|			AND ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance) 
		|   
		|		THEN CASE
		|				WHEN (ListOfFA.ResourceAssigned - ListOfFA.LifeSpentPastPeriod + ListOfFA.AccelerationFactor - 1) <> 0
		|					THEN CAST(CAST(&CostUsedToCalculateDepreciationManag - &AmountOfAdditionalCharge - &ResidualValueMan - &ImpairmentBalance AS NUMBER(20,8))
		|									* CAST(ListOfFA.LifeSpentCurrentPeriod AS NUMBER(20,8))
		|									* CAST(ListOfFA.AccelerationFactor AS NUMBER(20,8))
		|									/ CAST(ListOfFA.ResourceAssigned - ListOfFA.LifeSpentPastPeriod + ListOfFA.AccelerationFactor - 1 AS NUMBER(20,8)) AS NUMBER(31,2))
		|				ELSE 0
		|			END
		|";
		
	EndIf;
	
	If CalculationParameters = Undefined
		Or CalculationParameters.NotAccountingProcedureForVNAAccordingToIntStandardsIsApplied Then
			
		QueryText = QueryText + 
			// Linear
		"	WHEN NOT ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
		|			AND ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.Linear)
		| 
		|		THEN CASE 
		|			WHEN ListOfFA.ResourceAssigned = 0
		|				THEN 0
		|			ELSE
		|				CAST(CAST(&CostUsedToCalculateDepreciationManag AS NUMBER(20,8))
		|							/ CAST(ListOfFA.ResourceAssigned AS NUMBER(20,8)) AS NUMBER(31,2))
		|		END
		|   
			// ByUnitsOfProduction
		|	WHEN NOT ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
		|			AND ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
		| 
		|		THEN CASE 
		|			WHEN ListOfFA.LifeSpentCurrentPeriod <> 0 AND ListOfFA.ResourceAssigned <> 0 
		|				THEN CAST(CAST(&CostUsedToCalculateDepreciationManag AS NUMBER(20,8))
		|								* CAST(ListOfFA.LifeSpentCurrentPeriod AS NUMBER(20,8))
		|								/ CAST(ListOfFA.ResourceAssigned AS NUMBER(20,8)) AS NUMBER(31,2))
		|			ELSE 0
		|		END
		|	
			// ReducedBalance
		|	WHEN NOT ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
		|			AND ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
		| 
		|		THEN CASE 
		|			WHEN ListOfFA.ResourceAssigned = 0
		|				THEN 0
		|			ELSE
		|				CASE
		|					WHEN ListOfFA.LastChangeDate >= ListOfFA.BeginningOfFiscalYear
		|							AND ListOfFA.LastChangeDate <= ListOfFA.EndOfFiscalYear
		| 
		|						THEN CAST(&CostUsedToCalculateDepreciationManag 
		|										/ CAST(ListOfFA.ResourceAssigned AS NUMBER(20,8)) 
		|										* ListOfFA.AccelerationFactor AS NUMBER(31,2))
		|					ELSE
		|						CAST(&CostAtBeginningOfYear 
		|									/ CAST(ListOfFA.ResourceAssigned AS NUMBER(20,8)) 
		|									* ListOfFA.AccelerationFactor AS NUMBER(31,2))
		|				END
		|		END 
		|";
		 
	EndIf;
	
	QueryText = QueryText + "END";

	QueryText = StrReplace(QueryText, "&CostUsedToCalculateDepreciationManag", RequestTextParameters.TextCostToCalculateDepreciation);
	QueryText = StrReplace(QueryText, "&ResidualValueMan", RequestTextParameters.TextLiquidationValue);
	QueryText = StrReplace(QueryText, "&NetBookValue", RequestTextParameters.TextResidualValue);
	QueryText = StrReplace(QueryText, "&CostAtBeginningOfYear", RequestTextParameters.TextCostAtBeginningOfYear);
	QueryText = StrReplace(QueryText, "&AmountOfAdditionalCharge", RequestTextParameters.TextAmountOfAdditionalCharge);
	
	TextImpairment = 
		StrReplace(
			"(CASE WHEN ListOfFA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment THEN &ImpairmentBalance ELSE 0 END)", 
			"&ImpairmentBalance",
			RequestTextParameters.TextImpairment);			
	QueryText = StrReplace(QueryText, "&ImpairmentBalance", TextImpairment);
	
	Return QueryText;
	
EndFunction

Function QueryTextAmountOfImpairment(TextBalanceImpairment)
	
	QueryText = 
	"CASE 
	|	WHEN NOT ListOfFA.AccrueDepreciationOrAmortization 
	|		OR &ImpairmentBalance <= 0
	|		OR NOT ListOfFA.DepreciationIsCalculatedAccordingToINTStandards
	|
	|		THEN 0
	|
	|	WHEN (ListOfFA.LifeSpentPastPeriod + ListOfFA.LifeSpentCurrentPeriod) >= ListOfFA.ResourceAssigned
	|
	|		THEN &ImpairmentBalance
	|
		// Linear, proportional to the volume of production
	|	WHEN ListOfFA.DepreciationMethod IN (
	|						VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.Linear),
	|						VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)) 
	|
	|		THEN CAST(&ImpairmentBalance 
	|							* (CAST(ListOfFA.LifeSpentCurrentPeriod AS NUMBER(20,8))
	|							/ CAST(ListOfFA.ResourceAssigned - ListOfFA.LifeSpentPastPeriod AS NUMBER(20,8))) AS NUMBER(31,2))
	|
		// Reduced Balance
	|	WHEN ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance) 
	|
	|		THEN CAST(CAST(&ImpairmentBalance AS NUMBER(20,8))
	|					* CAST(ListOfFA.LifeSpentCurrentPeriod AS NUMBER(20,8))
	|					* CAST(ListOfFA.AccelerationFactor AS NUMBER(20,8))
	|					/ CAST(ListOfFA.ResourceAssigned - ListOfFA.LifeSpentPastPeriod + ListOfFA.AccelerationFactor - 1 AS NUMBER(20,8)) AS NUMBER(31,2))
	|	ELSE 0
	|
	|END";
	
	QueryText = StrReplace(QueryText, "&ImpairmentBalance", TextBalanceImpairment);
	
	Return QueryText;
	
EndFunction

// 
// Returns:
//  Structure - Query text parameters amount of Ma depreciation:
// * TextCostToCalculateDepreciation - String - 
// * TextResidualValue - String -
// * TextLiquidationValue - String -
// * TextCostAtBeginningOfYear - String -
// * TextAmountOfAdditionalCharge - String -
// * TextImpairment - String -
Function QueryTextParametersAmountOfMaDepreciation() Export
	
	RequestTextParameters = New Structure;
	RequestTextParameters.Insert("TextCostToCalculateDepreciation", "0");
	RequestTextParameters.Insert("TextResidualValue", "0");
	RequestTextParameters.Insert("TextLiquidationValue", "0");
	RequestTextParameters.Insert("TextCostAtBeginningOfYear", "0");
	RequestTextParameters.Insert("TextAmountOfAdditionalCharge", "0");
	RequestTextParameters.Insert("TextImpairment", "0");
	
	Return RequestTextParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region CalculationOfDepreciationAccordingToTable

// Returns parameters for calculating depreciation from the table.
// 
// Parameters:
//  CalculationParameters - Structure - Calculation parameters
// 
// Returns:
//  Structure - Parameters For Calculating Depreciation According To The Table:
//  	* ParametersForMAPeriod - ValueTable -
//  	* FinancialDetailsForThePeriodAC - ValueTable -
//  	* FinancialDetailsForThePeriodTA - ValueTable -
//
Function ParametersForCalculatingDepreciationAccordingToTable(CalculationParameters) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FixedAssetsDepreciationCharge.ParametersForCalculatingDepreciationAccordingToTable");
	
	#Region GettingCalculationParameters
	
	AccountingPolicyForFixedAssets = AccountingPoliciesTaxSettingsCached.AccountingPolicyForFixedAssets(
		CalculationParameters.Organization, CalculationParameters.EndOfPeriod);
	
	ProcedureForCalculatingManSDepreciation = AccountingPoliciesTaxSettingsCached.DepreciationProcedureFAMan(
		CalculationParameters.Organization, CalculationParameters.EndOfPeriod);
	
	DepreciationChargeProcedureLocal = AccountingPoliciesTaxSettingsCached.ProcedureOfFixedAssetDepreciationChargeLocal(
		CalculationParameters.Organization, CalculationParameters.EndOfPeriod);
	
	FALocalAccountingIsConductedIndependently = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(
		CalculationParameters.Organization, CalculationParameters.EndOfPeriod);
	
	StandardDates = New ValueTable();
	StandardDates.Columns.Add("Date", Common.DateTypeDetails(DateFractions.Date));
	
	Period = BegOfDay(EndOfMonth(CalculationParameters.BeginOfPeriod));
	While Period <= CalculationParameters.EndOfPeriod Do
		StringParameters_ = StandardDates.Add();
		StringParameters_.Date = Period;
		Period = BegOfDay(EndOfMonth(AddMonth(Period, 1)));
	EndDo;

	If StandardDates.Find(BegOfDay(CalculationParameters.EndOfPeriod), "Date") = Undefined Then
		StringParameters_ = StandardDates.Add();
		StringParameters_.Date = BegOfDay(CalculationParameters.EndOfPeriod);
	EndIf;
	
	SlicePeriod = CalculationParameters.BeginOfPeriod - 1;
	
	Parameters = New Structure;
	Parameters.Insert("TempTablesManager", New TempTablesManager());
	Parameters.Insert("Ref", CalculationParameters.Ref);
	Parameters.Insert("Date", EndOfDay(CalculationParameters.Date));
	Parameters.Insert("Organization", CalculationParameters.Organization);
	Parameters.Insert("ParentCompany", Common.ObjectAttributeValue(CalculationParameters.Organization, "ParentCompany"));
	Parameters.Insert("FixedAsset", CalculationParameters.FixedAsset);
	Parameters.Insert("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Parameters.Insert("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Parameters.Insert("EndOfCurrentPeriod", ?(CalculationParameters.EndOfPeriod < CalculationParameters.Date, EndOfDay(CalculationParameters.Date), CalculationParameters.EndOfPeriod));
	Parameters.Insert("EndOfMAPeriod", CalculationParameters.EndOfMAPeriod);
	Parameters.Insert("EndOfACPeriod", CalculationParameters.EndOfACPeriod);
	Parameters.Insert("EndOfPeriodTA", CalculationParameters.EndOfPeriodTA);
	Parameters.Insert("SlicePeriod", SlicePeriod);
	Parameters.Insert("ByFinancialAccountingStandards", AccountingPolicyForFixedAssets = Enums.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards);
	Parameters.Insert("ProcedureForCalculatingManSDepreciation", ProcedureForCalculatingManSDepreciation);
	Parameters.Insert("DepreciationChargeProcedureLocal", DepreciationChargeProcedureLocal);
	Parameters.Insert("FALocalAccountingIsConductedIndependently", FALocalAccountingIsConductedIndependently);
	Parameters.Insert("DepreciationAllowance", CalculationParameters.DepreciationAllowance);
	Parameters.Insert("FillInUU", CalculationParameters.FillInUU);
	Parameters.Insert("FillInBU", CalculationParameters.FillInBU);
	Parameters.Insert("FillInTA", CalculationParameters.FillInTA);
	Parameters.Insert("StandardDates", StandardDates);
	
	InitialInformation = Catalogs.Assets.InitialInformation(CalculationParameters.FixedAsset, CalculationParameters.Date);
	Parameters.Insert("CommissioningDateAC", InitialInformation.CommissioningDateAC);
	Parameters.Insert("CommissioningDateTA", InitialInformation.CommissioningDateTA);
	Parameters.Insert("CommissioningDateMA", InitialInformation.CommissioningDateMA);
	Parameters.Insert("CommissioningDocumentAC", InitialInformation.CommissioningDocumentAC);
	Parameters.Insert("CommissioningDocumentTA", InitialInformation.CommissioningDocumentTA);
	Parameters.Insert("CommissioningDocumentMA", InitialInformation.CommissioningDocumentMA);
	#EndRegion
	
	#Region FormationOfTemporaryTables

	ListOfRequests = New Array;
	
	RegistersList = New Array;
	RegistersList.Add(Metadata.InformationRegisters.FixedAssetsAccountingProcedure.Name);
	RegistersList.Add(Metadata.InformationRegisters.AccountingProcedureForOSBU.Name);
	RegistersList.Add(Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting.Name);
	RegistersList.Add(Metadata.InformationRegisters.OSBUDepreciationParameters.Name);
	RegistersList.Add(Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting.Name);
	RegistersList.Add(Metadata.InformationRegisters.FALocation.Name);
	RegistersList.Add(Metadata.InformationRegisters.InitialFixedAssetsInformation.Name);

	For Each RegisterName In RegistersList Do
		ListOfRequests.Add(NonCurrentAssets.RequestTextCaseSensitiveWithCorrections(RegisterName));
		ListOfRequests.Add(NonCurrentAssets.CaseRecordRequestTextWithCorrections(RegisterName));
	EndDo;
	
	#Region InitialOS_RecordInformation
	QueryText = 
	"SELECT
	|	FALSE AS TheseAreChanges,
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.InitialCostMA AS InitialCostMA,
	|	RegisterData.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|	RegisterData.InitialCostTA AS InitialCostTA,
	|	RegisterData.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	RegisterData.DepreciationMethodTaxAccounting AS DepreciationMethodTaxAccounting,
	|	RegisterData.CommissioningDateAC AS CommissioningDateAC,
	|	RegisterData.CommissioningDateTA AS CommissioningDateTA,
	|	RegisterData.CommissioningDateMA AS CommissioningDateMA,
	|	RegisterData.CommissioningDocumentMA AS CommissioningDocumentMA,
	|	RegisterData.CommissioningDocumentAC AS CommissioningDocumentAC,
	|	RegisterData.CommissioningDocumentTA AS CommissioningDocumentTA
	|
	|INTO InitialOS_RecordInformation
	|
	|FROM
	|	InitialInformationOfOS_SliceOfLatterTakingIntoAccountCorrections AS RegisterData
	|
	|UNION ALL
	|
	|SELECT
	|	(NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|		AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|		AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|		AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation) AS TheseAreChanges,
	|
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.InitialCostMA AS InitialCostMA,
	|	RegisterData.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|	RegisterData.InitialCostTA AS InitialCostTA,
	|	RegisterData.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	RegisterData.DepreciationMethodTaxAccounting AS DepreciationMethodTaxAccounting,
	|	RegisterData.CommissioningDateAC AS CommissioningDateAC,
	|	RegisterData.CommissioningDateTA AS CommissioningDateTA,
	|	RegisterData.CommissioningDateMA AS CommissioningDateMA,
	|	RegisterData.CommissioningDocumentMA AS CommissioningDocumentMA,
	|	RegisterData.CommissioningDocumentAC AS CommissioningDocumentAC,
	|	RegisterData.CommissioningDocumentTA AS CommissioningDocumentTA
	|
	|FROM
	|	InitialInformationOfOS_RecordTakingIntoAccountCorrections AS RegisterData
	|
	|		LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|		ON FixedAssetsDocuments.Ref = RegisterData.Recorder
	|			AND FixedAssetsDocuments.RecNo = 0
	|			AND FixedAssetsDocuments.AdditionalRecord = FALSE
	|
	|WHERE
	|	RegisterData.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RegisterData.FixedAsset = &FixedAsset
	|	AND RegisterData.Recorder <> &Ref
	|	AND (NOT ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|		OR BEGINOFPERIOD(RegisterData.Period, DAY) = FixedAssetsDocuments.CorrectionPeriodStart)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region AccountingProcedureForOS_Records
	QueryText = 
	"SELECT
	|	FALSE AS TheseAreChanges,
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.RunningTimeValue AS RunningTimeValue,
	|	RegisterData.EstimatedRunningTime AS EstimatedRunningTime
	|
	|INTO AccountingProcedureForOS_Records
	|
	|FROM
	|	AccountingProcedureForOS_SlicesWithCorrections AS RegisterData
	|
	|UNION ALL
	|
	|SELECT
	|	(NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|		AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|		AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|		AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation) AS TheseAreChanges,
	|
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.RunningTimeValue AS RunningTimeValue,
	|	RegisterData.EstimatedRunningTime AS EstimatedRunningTime
	|
	|FROM
	|	AccountingProcedureForOS_RecordsWithCorrections AS RegisterData
	|
	|		LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|		ON FixedAssetsDocuments.Ref = RegisterData.Recorder
	|			AND FixedAssetsDocuments.RecNo = 0
	|			AND FixedAssetsDocuments.AdditionalRecord = FALSE
	|
	|WHERE
	|	RegisterData.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RegisterData.FixedAsset = &FixedAsset
	|	AND RegisterData.Recorder <> &Ref
	|	AND (NOT ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|		OR BEGINOFPERIOD(RegisterData.Period, DAY) = FixedAssetsDocuments.CorrectionPeriodStart)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region AccountingProcedureForOSUU_Records
	QueryText = 
	"SELECT
	|	FALSE AS TheseAreChanges,
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization
	|
	|INTO AccountingProcedureForOSUU_Records
	|
	|FROM
	|	AccountingProcedureForOSUU_SlicesWithCorrections AS RegisterData
	|
	|UNION ALL
	|
	|SELECT
	|	(NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|		AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|		AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|		AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation) AS TheseAreChanges,
	|
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.AccrueDepreciationOrAmortization AS DepreciationAccrualManagementAccounting
	|
	|FROM
	|	AccountingProcedureForOSUU_RecordsWithCorrections AS RegisterData
	|
	|		LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|		ON FixedAssetsDocuments.Ref = RegisterData.Recorder
	|			AND FixedAssetsDocuments.RecNo = 0
	|			AND FixedAssetsDocuments.AdditionalRecord = FALSE
	|
	|WHERE
	|	RegisterData.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RegisterData.FixedAsset = &FixedAsset
	|	AND RegisterData.Recorder <> &Ref
	|	AND (NOT ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|		OR BEGINOFPERIOD(RegisterData.Period, DAY) = FixedAssetsDocuments.CorrectionPeriodStart)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region AccountingProcedureForOSBU_Records
	QueryText = 
	"SELECT
	|	FALSE AS TheseAreChanges,
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.DepreciationGroup AS DepreciationGroup,
	|	RegisterData.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
	|	RegisterData.DepreciationAccrualTaxAccounting AS DepreciationAccrualTaxAccounting
	|
	|INTO AccountingProcedureForOSBU_Records
	|
	|FROM
	|	AccountingProcedureForOSBU_CutOfLatterTakingIntoAccountCorrections AS RegisterData
	|
	|UNION ALL
	|
	|SELECT
	|	(NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|		AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|		AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|		AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation) AS TheseAreChanges,
	|
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.DepreciationGroup AS DepreciationGroup,
	|	RegisterData.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
	|	RegisterData.DepreciationAccrualTaxAccounting AS DepreciationAccrualTaxAccounting
	|
	|FROM
	|	AccountingProcedureForOSBU_RecordsTakingIntoAccountCorrections AS RegisterData
	|
	|		LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|		ON FixedAssetsDocuments.Ref = RegisterData.Recorder
	|			AND FixedAssetsDocuments.RecNo = 0
	|			AND FixedAssetsDocuments.AdditionalRecord = FALSE
	|
	|WHERE
	|	RegisterData.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RegisterData.FixedAsset = &FixedAsset
	|	AND RegisterData.Recorder <> &Ref
	|	AND (NOT ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|		OR BEGINOFPERIOD(RegisterData.Period, DAY) = FixedAssetsDocuments.CorrectionPeriodStart)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DepreciationParametersOSUU_Records
	QueryText = 
	"SELECT
	|	FALSE AS TheseAreChanges,
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	RegisterData.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	RegisterData.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	RegisterData.AccelerationFactor AS AccelerationFactor,
	|	RegisterData.DepreciationMethod AS DepreciationMethod,
	|	RegisterData.ResidualValueMan AS ResidualValueMan,
	|	RegisterData.ResidualValueLocal AS ResidualValueLocal,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	RegisterData.LastChangeDate AS LastChangeDate
	|
	|INTO DepreciationParametersOSUU_Records
	|
	|FROM
	|	DepreciationParametersOfFAMan_SectionOfLatterTakingIntoAccountCorrections AS RegisterData
	|
	|UNION ALL
	|
	|SELECT
	|	(NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|		AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|		AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|		AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation) AS TheseAreChanges,
	|
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	RegisterData.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	RegisterData.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	RegisterData.AccelerationFactor AS AccelerationFactor,
	|	RegisterData.DepreciationMethod AS DepreciationMethod,
	|	RegisterData.ResidualValueMan AS ResidualValueMan,
	|	RegisterData.ResidualValueLocal AS ResidualValueLocal,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	RegisterData.LastChangeDate AS LastChangeDate
	|
	|FROM
	|	DepreciationParametersOfFAMan_RecordTakingIntoAccountCorrections AS RegisterData
	|
	|		LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|		ON FixedAssetsDocuments.Ref = RegisterData.Recorder
	|			AND FixedAssetsDocuments.RecNo = 0
	|			AND FixedAssetsDocuments.AdditionalRecord = FALSE
	|
	|WHERE
	|	RegisterData.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RegisterData.FixedAsset = &FixedAsset
	|	AND RegisterData.Recorder <> &Ref
	|	AND (NOT ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|		OR BEGINOFPERIOD(RegisterData.Period, DAY) = FixedAssetsDocuments.CorrectionPeriodStart)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DepreciationParametersOfOSBU_Records
	QueryText = 
	"SELECT
	|	FALSE AS TheseAreChanges,
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.AccelerationFactor AS AccelerationFactor,
	|	RegisterData.UsefulLifeMonthsTA AS UsefulLifeMonthsTA,
	|	RegisterData.SpecialFactor AS SpecialFactor,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	RegisterData.AnnualDepreciationRate AS AnnualDepreciationRate,
	|	RegisterData.PermanentDifferencesUsedToCalculateDepreciation AS PermanentDifferencesUsedToCalculateDepreciation,
	|	RegisterData.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	RegisterData.CostForDepreciationCalculationTargetFinancing AS CostForDepreciationCalculationTargetFinancing,
	|	RegisterData.DepreciationSchedule AS DepreciationSchedule,
	|	RegisterData.ResidualValueMan AS ResidualValueMan,
	|	RegisterData.LastChangeDate AS LastChangeDate
	|
	|INTO DepreciationParametersOfOSBU_Records
	|
	|FROM
	|	DepreciationParametersOfOSBU_SliceOfLatterTakingIntoAccountCorrections AS RegisterData
	|
	|UNION ALL
	|
	|SELECT
	|	(NOT RegisterData.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|		AND NOT RegisterData.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|		AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|		AND NOT RegisterData.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation) AS TheseAreChanges,
	|
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.AccelerationFactor AS AccelerationFactor,
	|	RegisterData.UsefulLifeMonthsTA AS UsefulLifeMonthsTA,
	|	RegisterData.SpecialFactor AS SpecialFactor,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	RegisterData.AnnualDepreciationRate AS AnnualDepreciationRate,
	|	RegisterData.PermanentDifferencesUsedToCalculateDepreciation AS PermanentDifferencesUsedToCalculateDepreciation,
	|	RegisterData.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	RegisterData.CostForDepreciationCalculationTargetFinancing AS CostForDepreciationCalculationTargetFinancing,
	|	RegisterData.DepreciationSchedule AS DepreciationSchedule,
	|	RegisterData.ResidualValueMan AS ResidualValueMan,
	|	RegisterData.LastChangeDate AS LastChangeDate
	|
	|FROM
	|	DepreciationParametersOfOSBU_RecordTakingIntoAccountCorrections AS RegisterData
	|
	|		LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|		ON FixedAssetsDocuments.Ref = RegisterData.Recorder
	|			AND FixedAssetsDocuments.RecNo = 0
	|			AND FixedAssetsDocuments.AdditionalRecord = FALSE
	|
	|WHERE
	|	RegisterData.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RegisterData.FixedAsset = &FixedAsset
	|	AND RegisterData.Recorder <> &Ref
	|	AND (NOT ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|		OR BEGINOFPERIOD(RegisterData.Period, DAY) = FixedAssetsDocuments.CorrectionPeriodStart)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region LocationOfOS_Record
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization
	|
	|INTO LocationOfOS_Record
	|
	|FROM
	|	FALocation_SliceLastTakingIntoAccountCorrections AS RegisterData
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Organization AS Organization
	|
	|FROM
	|	LocationOfOS_RecordWithCorrections AS RegisterData
	|
	|WHERE
	|	RegisterData.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RegisterData.FixedAsset = &FixedAsset
	|	AND RegisterData.Recorder <> &Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region OS_RecordGeneration
	QueryText = 
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.RunningTimeValue AS RunningTimeValue,
	|	RegisterData.Value AS OutputVolume
	|
	|INTO OS_RecordGeneration
	|
	|FROM
	|	InformationRegister.AssetActivityRecords.SliceLast(
	|			&EndOfPreviousMonth,
	|			Asset = &FixedAsset) AS RegisterData
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.RunningTimeValue AS RunningTimeValue,
	|	RegisterData.Value AS OutputVolume
	|
	|FROM
	|	InformationRegister.AssetActivityRecords AS RegisterData
	|
	|WHERE
	|	RegisterData.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RegisterData.Asset = &FixedAsset
	|	AND RegisterData.Active";	
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region SourceAndDestinationTable
	QueryText = 
	"SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.FixedAsset AS MainMeansSource,
	|	TabularSection.FixedAsset AS PrincipalMeansRecipient,
	|
	|	DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit),
	|		VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)) AS ThisIsPartialWriteOff,
	|
	|	TabularSection.CostInManagementAccounting AS CostOfWritingOffMan,
	|	TabularSection.CostInAccounting AS CostOfLocalTaxDeduction,
	|	TabularSection.CostInTaxAccounting AS COSTOfWriteOffIsTA,
	|	TabularSection.CostPermanentDifference AS CostOfWritingOffPD
	|
	|INTO SourceAndDestinationTable
	|
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
	|
	|		INNER JOIN Document.SplitFixedAssets.FA AS TabularSection
	|		ON TabularSection.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND TabularSection.FixedAsset = &FixedAsset
	|	AND DocumentData.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Ref AS Ref,
	|	TabularSection.FixedAsset AS MainMeansSource,
	|	DocumentData.FixedAsset AS PrincipalMeansRecipient,
	|
	|	FALSE AS ThisIsPartialWriteOff,
	|
	|	0 AS CostOfWritingOffMan,
	|	0 AS CostOfLocalTaxDeduction,
	|	0 AS COSTOfWriteOffIsTA,
	|	0 AS CostOfWritingOffPD
	|
	|FROM
	|	Document.MergeOfFixedAssets AS DocumentData
	|
	|		INNER JOIN Document.MergeOfFixedAssets.FA AS TabularSection
	|		ON TabularSection.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DocumentData.FixedAsset = &FixedAsset
	|	AND DocumentData.Posted
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region OS_WriteCost
	QueryText = 
	"SELECT
	|	FACost.Period AS Period,
	|	FACost.Recorder AS Recorder,
	|
	|	MIN(FACost.RecordPeriod) AS RecordPeriod,
	|	SUM(FACost.Cost) AS Cost,
	|	SUM(FACost.LocalCost) AS LocalCost,
	|	SUM(FACost.CostInTaxAccounting) AS CostInTaxAccounting,
	|	SUM(FACost.CostPermanentDifference) AS CostPermanentDifference,
	|	SUM(FACost.CostTargetFinancing) AS CostTargetFinancing,
	|	SUM(FACost.CostTargetFinancingPD) AS CostTargetFinancingPD,
	|	SUM(FACost.PreliminaryCostMan) AS PreliminaryCostMan,
	|	SUM(FACost.PreliminaryCostLocal) AS PreliminaryCostLocal,
	|	SUM(FACost.DepreciationAllowance) AS DepreciationAllowance
	|
	|INTO OS_WriteCost
	|
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|
	|				THEN FixedAssetsDocuments.CorrectionPeriodStart
	|
	|			WHEN FACost.Recorder REFS Document.FixedAssetsDepreciationCharge2_4
	|					AND FACost.BusinessOperation = VALUE(Enum.BusinessTransactions.IncludeDepreciationAllowanceInExpenses)
	|
	|				THEN DATEADD(BEGINOFPERIOD(FACost.Period, MONTH), SECOND, -1)
	|
	|			ELSE FACost.Period 
	|
	|		END AS Period,
	|
	|		FACost.Period AS RecordPeriod,
	|		FACost.Recorder AS Recorder,
	|		FACost.Organization AS Organization,
	|		FACost.FixedAsset AS FixedAsset,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.Cost
	|			ELSE -FACost.Cost
	|		END AS Cost,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.LocalCost
	|			ELSE -FACost.LocalCost
	|		END AS LocalCost,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.CostInTaxAccounting
	|			ELSE -FACost.CostInTaxAccounting
	|		END AS CostInTaxAccounting,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.CostPermanentDifference
	|			ELSE -FACost.CostPermanentDifference
	|		END AS CostPermanentDifference,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.CostTargetFinancing
	|			ELSE -FACost.CostTargetFinancing
	|		END AS CostTargetFinancing,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.CostTargetFinancingPD
	|			ELSE -FACost.CostTargetFinancingPD
	|		END AS CostTargetFinancingPD,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.PreliminaryCostMan
	|			ELSE -FACost.PreliminaryCostMan
	|		END AS PreliminaryCostMan,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.PreliminaryCostLocal
	|			ELSE -FACost.PreliminaryCostLocal
	|		END AS PreliminaryCostLocal,
	|
	|		0 AS DepreciationAllowance
	|
	|	FROM
	|		AccumulationRegister.FACost AS FACost
	|
	|			LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|			ON FixedAssetsDocuments.Ref = FACost.Recorder
	|				AND FixedAssetsDocuments.RecNo = 0
	|				AND FixedAssetsDocuments.AdditionalRecord = FALSE
	|
	|			LEFT JOIN Document.SplitFixedAssets AS SplitFixedAssets
	|			ON SplitFixedAssets.Ref = FACost.Recorder
	|
	|			LEFT JOIN Document.MergeOfFixedAssets AS MergeOfFixedAssets
	|			ON MergeOfFixedAssets.Ref = FACost.Recorder
	|
	|	WHERE
	|		FACost.Period BETWEEN &BeginOfPeriod AND &EndOfCurrentPeriod
	|		AND (NOT ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|			OR FixedAssetsDocuments.CorrectionPeriodStart BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|		AND FACost.FixedAsset = &FixedAsset
	|		AND FACost.Recorder <> &Ref
	|		AND FACost.Active
	|
	|		AND NOT FACost.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|		AND NOT FACost.Recorder REFS Document.RecognizeSubAssetsComponentsOfDepreciation
	|		AND NOT FACost.Recorder REFS Document.ImpairmentFA
	|		AND NOT FACost.Recorder REFS Document.FARevaluation2_4
	|		AND NOT FACost.Recorder REFS Document.FixedAssetCostAndDepreciationAdjustment
	|
	|		AND (NOT FACost.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|			OR FACost.BusinessOperation = VALUE(Enum.BusinessTransactions.IncludeDepreciationAllowanceInExpenses))
	|
	|		AND (NOT FACost.Recorder REFS Document.SplitFixedAssets
	|			OR FACost.FixedAsset = SplitFixedAssets.FixedAsset)
	|
	|		AND (NOT FACost.Recorder REFS Document.MergeOfFixedAssets
	|			OR FACost.FixedAsset <> MergeOfFixedAssets.FixedAsset)
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE
	|			WHEN ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|					AND FACost.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|
	|				THEN DATEADD(ENDOFPERIOD(FixedAssetsDocuments.CorrectionPeriodStart, MONTH), SECOND, 1)
	|
	|			WHEN ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|
	|				THEN FixedAssetsDocuments.CorrectionPeriodStart
	|
	|			ELSE FACost.Period 
	|		END AS Period,
	|
	|		FACost.Period AS RecordPeriod,
	|		FACost.Recorder AS Recorder,
	|		FACost.Organization AS Organization,
	|		FACost.FixedAsset AS FixedAsset,
	|
	|		0 AS Cost,
	|		0 AS LocalCost,
	|		0 AS CostInTaxAccounting,
	|		0 AS CostPermanentDifference,
	|		0 AS CostTargetFinancing,
	|		0 AS CostTargetFinancingPD,
	|		0 AS PreliminaryCostMan,
	|		0 AS PreliminaryCostLocal,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -FACost.DepreciationAllowance
	|			ELSE FACost.DepreciationAllowance
	|		END AS DepreciationAllowance
	|
	|	FROM
	|		AccumulationRegister.FACost AS FACost
	|
	|			LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|			ON FixedAssetsDocuments.Ref = FACost.Recorder
	|				AND FixedAssetsDocuments.RecNo = 0
	|				AND FixedAssetsDocuments.AdditionalRecord = FALSE
	|
	|			LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|			ON Adjusting.Ref = FACost.Recorder
	|
	|	WHERE
	|		FACost.Period BETWEEN &BeginOfPeriod AND &EndOfCurrentPeriod
	|		AND (NOT ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|			OR FixedAssetsDocuments.CorrectionPeriodStart BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|		AND FACost.FixedAsset = &FixedAsset
	|		AND FACost.Recorder <> &Ref
	|		AND FACost.Active
	|
	|		AND FACost.DepreciationAllowance <> 0
	|
	|		AND FACost.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.IncludeDepreciationAllowanceInExpenses),
	|				VALUE(Enum.BusinessTransactions.DecreaseInBonusDepreciation))
	|
	|	UNION ALL
	|
	|	SELECT
	|		Adjusting.Date AS Period,
	|		Adjusting.Date AS RecordPeriod,
	|		Adjusting.Ref AS Recorder,
	|		Adjusting.Organization AS Organization,
	|		FATable.FixedAsset AS FixedAsset,
	|
	|		FATable.CostInManagementAccounting AS Cost,
	|		FATable.CostInAccounting AS LocalCost,
	|		FATable.CostInTaxAccounting AS CostInTaxAccounting,
	|		FATable.CostPermanentDifference AS CostPermanentDifference,
	|		FATable.CostTargetFinancing AS CostTargetFinancing,
	|		FATable.CostTargetFinancing AS CostTargetFinancingPD,
	|
	|		0 AS PreliminaryCostMan,
	|		0 AS PreliminaryCostLocal,
	|		0 AS DepreciationAllowance
	|
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|			ON FATable.Ref = Adjusting.Ref
	|				AND FATable.FixedAsset = &FixedAsset
	|
	|	WHERE
	|		Adjusting.Posted
	|		AND Adjusting.Date BETWEEN &BeginOfPeriod AND &EndOfCurrentPeriod
	|		AND Adjusting.CostAdjustment
	|		AND Adjusting.Ref <> &Ref
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE
	|			WHEN ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|				THEN FixedAssetsDocuments.CorrectionPeriodStart
	|			ELSE DocumentData.Date 
	|		END AS Period,
	|
	|		DocumentData.Date AS RecordPeriod,
	|		DocumentData.Ref AS Recorder,
	|		DocumentData.Organization AS Organization,
	|		FATable.FixedAsset AS FixedAsset,
	|
	|		FATable.CostInManagementAccounting AS Cost,
	|		FATable.CostInAccounting AS LocalCost,
	|
	|		0 AS CostInTaxAccounting,
	|		0 AS CostPermanentDifference,
	|		0 AS CostTargetFinancing,
	|		0 AS CostTargetFinancingPD,
	|		0 AS PreliminaryCostMan,
	|		0 AS PreliminaryCostLocal,
	|		0 AS DepreciationAllowance
	|
	|	FROM
	|		Document.FARevaluation2_4 AS DocumentData
	|
	|			INNER JOIN Document.FARevaluation2_4.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|			LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|			ON FixedAssetsDocuments.Ref = FATable.Ref
	|				AND FixedAssetsDocuments.FixedAsset = FATable.FixedAsset
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND (NOT ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|			OR FixedAssetsDocuments.CorrectionPeriodStart BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|		AND FATable.FixedAsset = &FixedAsset
	|		AND DocumentData.Posted
	|
	|	) AS FACost
	|
	|GROUP BY
	|	FACost.Period,
	|	FACost.Recorder
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DepreciationOfOS_Records
	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge.Period AS Period,
	|	FixedAssetsDepreciationCharge.Recorder AS Recorder,
	|
	|	SUM(FixedAssetsDepreciationCharge.Depreciation) AS Depreciation,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationLocal) AS DepreciationLocal,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting) AS DepreciationInTaxAccounting,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences) AS DepreciationPermanentDifferences,
	|	SUM(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing) AS FixedAssetDepreciationTargetFinancing,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD) AS DepreciationTargetFinancingPD
	|
	|INTO DepreciationOfOS_Records
	|
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|				THEN FixedAssetsDocuments.CorrectionPeriodStart
	|			ELSE FixedAssetsDepreciationCharge.Period 
	|		END AS Period,
	|
	|		FixedAssetsDepreciationCharge.Recorder AS Recorder,
	|		FixedAssetsDepreciationCharge.Organization AS Organization,
	|		FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FixedAssetsDepreciationCharge.Depreciation
	|			ELSE -FixedAssetsDepreciationCharge.Depreciation
	|		END AS Depreciation,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FixedAssetsDepreciationCharge.DepreciationLocal
	|			ELSE -FixedAssetsDepreciationCharge.DepreciationLocal
	|		END AS DepreciationLocal,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
	|			ELSE -FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
	|		END AS DepreciationInTaxAccounting,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
	|			ELSE -FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
	|		END AS DepreciationPermanentDifferences,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
	|			ELSE -FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
	|		END AS FixedAssetDepreciationTargetFinancing,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD
	|			ELSE -FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD
	|		END AS DepreciationTargetFinancingPD
	|
	|	FROM
	|
	|		AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
	|
	|			LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|			ON FixedAssetsDocuments.Ref = FixedAssetsDepreciationCharge.Recorder
	|				AND FixedAssetsDocuments.FixedAsset = FixedAssetsDepreciationCharge.FixedAsset
	|
	|			LEFT JOIN Document.SplitFixedAssets AS SplitFixedAssets
	|			ON SplitFixedAssets.Ref = FixedAssetsDepreciationCharge.Recorder
	|
	|	WHERE
	|		FixedAssetsDepreciationCharge.Period BETWEEN &BeginOfPeriod AND &EndOfCurrentPeriod
	|		AND (NOT ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|			OR FixedAssetsDocuments.CorrectionPeriodStart BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|		AND FixedAssetsDepreciationCharge.FixedAsset = &FixedAsset
	|		AND FixedAssetsDepreciationCharge.Recorder <> &Ref
	|		AND FixedAssetsDepreciationCharge.Active
	|
	|		AND NOT FixedAssetsDepreciationCharge.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|		AND NOT FixedAssetsDepreciationCharge.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|		AND NOT FixedAssetsDepreciationCharge.Recorder REFS Document.FixedAssetsDepreciationCharge2_4
	|		AND NOT FixedAssetsDepreciationCharge.Recorder REFS Document.ImpairmentFA
	|		AND NOT FixedAssetsDepreciationCharge.Recorder REFS Document.SplitFixedAssets
	|		AND NOT FixedAssetsDepreciationCharge.Recorder REFS Document.MergeOfFixedAssets
	|		AND NOT FixedAssetsDepreciationCharge.Recorder REFS Document.FARevaluation2_4
	|		AND NOT FixedAssetsDepreciationCharge.Recorder REFS Document.FixedAssetCostAndDepreciationAdjustment
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE
	|			WHEN Adjusting.IncludesDepreciationOfCurrentMonth
	|				THEN ENDOFPERIOD(Adjusting.Date, MONTH)
	|			ELSE Adjusting.Date 
	|		END AS Period,
	|
	|		Adjusting.Ref AS Recorder,
	|		Adjusting.Organization AS Organization,
	|		FATable.FixedAsset AS FixedAsset,
	|
	|		FATable.DepreciationManagementAccounting AS Depreciation,
	|		FATable.DepreciationInAccounting AS DepreciationLocal,
	|		FATable.DepreciationInTaxAccounting AS DepreciationInTaxAccounting,
	|		FATable.DepreciationPermanentDifferences AS DepreciationPermanentDifferences,
	|		FATable.FixedAssetDepreciationTargetFinancing AS FixedAssetDepreciationTargetFinancing,
	|		FATable.FixedAssetDepreciationTargetFinancing AS DepreciationTargetFinancingPD
	|
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|			ON FATable.Ref = Adjusting.Ref
	|				AND FATable.FixedAsset = &FixedAsset
	|
	|	WHERE
	|		Adjusting.Posted
	|		AND Adjusting.Date BETWEEN &BeginOfPeriod AND &EndOfCurrentPeriod
	|		AND Adjusting.DepreciationAdjustment
	|		AND NOT Adjusting.DepreciationAdjustmentForPeriod
	|		AND Adjusting.Ref <> &Ref
	|
	|		AND Adjusting.DocumentBasis = UNDEFINED
	|		AND NOT Adjusting.DocumentBasis REFS Document.MergeOfFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.SplitFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsCostAdditions2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.AllocateVariancesToFixedAssetCost
	|		AND NOT Adjusting.DocumentBasis REFS Document.FARevaluation2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsInitialRecognition2_4
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE
	|			WHEN Adjusting.IncludesDepreciationOfCurrentMonth
	|				THEN ENDOFPERIOD(Adjusting.Date, MONTH)
	|			ELSE Adjusting.Date 
	|		END AS Period,
	|
	|		Adjusting.Ref AS Recorder,
	|		Adjusting.Organization AS Organization,
	|		FATable.FixedAsset AS FixedAsset,
	|
	|		TableDepreciation.Depreciation + TableDepreciation.DepreciationUpdate AS Depreciation,
	|		0 AS DepreciationLocal,
	|		0 AS DepreciationInTaxAccounting,
	|		0 AS DepreciationPermanentDifferences,
	|		0 AS FixedAssetDepreciationTargetFinancing,
	|		0 AS DepreciationTargetFinancingPD
	|
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|			ON FATable.Ref = Adjusting.Ref
	|				AND FATable.FixedAsset = &FixedAsset
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FinancialDetailsForThePeriod AS TableDepreciation
	|			ON TableDepreciation.Ref = FATable.Ref
	|
	|	WHERE
	|		Adjusting.Posted
	|		AND Adjusting.Date BETWEEN &BeginOfPeriod AND &EndOfCurrentPeriod
	|		AND Adjusting.RecordInManAccounting
	|		AND Adjusting.DepreciationAdjustment
	|		AND Adjusting.DepreciationAdjustmentForPeriod
	|		AND Adjusting.Ref <> &Ref
	|
	|		AND Adjusting.DocumentBasis = UNDEFINED
	|		AND NOT Adjusting.DocumentBasis REFS Document.MergeOfFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.SplitFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsCostAdditions2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.AllocateVariancesToFixedAssetCost
	|		AND NOT Adjusting.DocumentBasis REFS Document.FARevaluation2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsInitialRecognition2_4
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE
	|			WHEN Adjusting.IncludesDepreciationOfCurrentMonth
	|				THEN ENDOFPERIOD(Adjusting.Date, MONTH)
	|			ELSE Adjusting.Date 
	|		END AS Period,
	|
	|		Adjusting.Ref AS Recorder,
	|		Adjusting.Organization AS Organization,
	|		FATable.FixedAsset AS FixedAsset,
	|
	|		0 AS Depreciation,
	|		TableDepreciation.DepreciationInAccounting + TableDepreciation.DepreciationLocalUpdate AS DepreciationLocal,
	|		0 AS DepreciationInTaxAccounting,
	|		TableDepreciation.DepreciationPermanentDifferences + TableDepreciation.DepreciationPermanentDifferencesUpdate AS DepreciationPermanentDifferences,
	|		TableDepreciation.FixedAssetDepreciationTargetFinancing + TableDepreciation.FixedAssetDepreciationTargetFinancingUpdate AS FixedAssetDepreciationTargetFinancing,
	|		TableDepreciation.FixedAssetDepreciationTargetFinancing + TableDepreciation.FixedAssetDepreciationTargetFinancingUpdate AS DepreciationTargetFinancingPD
	|
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|			ON FATable.Ref = Adjusting.Ref
	|				AND FATable.FixedAsset = &FixedAsset
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FinancialDetailsForThePeriodAC AS TableDepreciation
	|			ON TableDepreciation.Ref = FATable.Ref
	|
	|	WHERE
	|		Adjusting.Posted
	|		AND Adjusting.Date BETWEEN &BeginOfPeriod AND &EndOfCurrentPeriod
	|		AND Adjusting.PostInAccounting
	|		AND Adjusting.DepreciationAdjustment
	|		AND Adjusting.DepreciationAdjustmentForPeriod
	|		AND Adjusting.Ref <> &Ref
	|
	|		AND Adjusting.DocumentBasis = UNDEFINED
	|		AND NOT Adjusting.DocumentBasis REFS Document.MergeOfFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.SplitFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsCostAdditions2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.AllocateVariancesToFixedAssetCost
	|		AND NOT Adjusting.DocumentBasis REFS Document.FARevaluation2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsInitialRecognition2_4
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE
	|			WHEN Adjusting.IncludesDepreciationOfCurrentMonth
	|				THEN ENDOFPERIOD(Adjusting.Date, MONTH)
	|			ELSE Adjusting.Date 
	|		END AS Period,
	|
	|		Adjusting.Ref AS Recorder,
	|		Adjusting.Organization AS Organization,
	|		FATable.FixedAsset AS FixedAsset,
	|
	|		0 AS Depreciation,
	|		0 AS DepreciationLocal,
	|		TableDepreciation.DepreciationInTaxAccounting + TableDepreciation.DepreciationInTaxAccountingUpdate AS DepreciationInTaxAccounting,
	|		0 AS DepreciationPermanentDifferences,
	|		0 AS FixedAssetDepreciationTargetFinancing,
	|		0 AS DepreciationTargetFinancingPD
	|
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|			ON FATable.Ref = Adjusting.Ref
	|				AND FATable.FixedAsset = &FixedAsset
	|
	|			INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FinancialDetailsForThePeriodTA AS TableDepreciation
	|			ON TableDepreciation.Ref = FATable.Ref
	|
	|	WHERE
	|		Adjusting.Posted
	|		AND Adjusting.Date BETWEEN &BeginOfPeriod AND &EndOfCurrentPeriod
	|		AND Adjusting.RecordInTA
	|		AND Adjusting.DepreciationAdjustment
	|		AND Adjusting.DepreciationAdjustmentForPeriod
	|		AND Adjusting.Ref <> &Ref
	|
	|		AND Adjusting.DocumentBasis = UNDEFINED
	|		AND NOT Adjusting.DocumentBasis REFS Document.MergeOfFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.SplitFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsCostAdditions2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.AllocateVariancesToFixedAssetCost
	|		AND NOT Adjusting.DocumentBasis REFS Document.FARevaluation2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsInitialRecognition2_4
	|
	|	) AS FixedAssetsDepreciationCharge
	|
	|GROUP BY
	|	FixedAssetsDepreciationCharge.Period,
	|	FixedAssetsDepreciationCharge.Recorder
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region StandardDates
	QueryText = 
	"SELECT
	|	ENDOFPERIOD(StandardDates.Date, DAY) AS Date,
	|	BEGINOFPERIOD(StandardDates.Date, MONTH) AS BegOfMonth,
	|	ENDOFPERIOD(StandardDates.Date, MONTH) AS EndOfMonth
	|
	|INTO StandardDates
	|
	|FROM
	|	&StandardDates AS StandardDates";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region AllRegisterEntries
	QueryText = 
	"SELECT
	|	TableOfDates.Date AS Date,
	|	TableOfDates.Recorder AS Recorder,
	|	ISNULL(FixedAssetsDocuments.BusinessOperation, UNDEFINED) AS BusinessOperation,
	|	TableOfDates.TheseAreChanges AS TheseAreChanges,
	|	ISNULL(FixedAssetsDocuments.Date, TableOfDates.Date) AS Order,
	|	ISNULL(FixedAssetsDocuments.RecordInManAccounting, TRUE) AS RecordInManAccounting,
	|	ISNULL(FixedAssetsDocuments.RecordInLocalAccounting, TRUE) AS PostInAccounting,
	|	ISNULL(FixedAssetsDocuments.RecordInTA, TRUE) AS RecordInTA
	|
	|INTO AllRegisterEntries
	|
	|FROM
	|	(SELECT
	|		StandardDates.Date AS Date,
	|		UNDEFINED AS Recorder,
	|		FALSE AS TheseAreChanges
	|	FROM
	|		StandardDates AS StandardDates
	|
	|	UNION ALL
	|
	|	SELECT
	|		RegisterData.Period AS Date,
	|		RegisterData.Recorder AS Recorder,
	|		RegisterData.TheseAreChanges AS TheseAreChanges
	|	FROM
	|		InitialOS_RecordInformation AS RegisterData
	|	WHERE
	|		RegisterData.TheseAreChanges
	|
	|	UNION ALL
	|
	|	SELECT
	|		RegisterData.Period AS Date,
	|		RegisterData.Recorder AS Recorder,
	|		RegisterData.TheseAreChanges AS TheseAreChanges
	|	FROM
	|		AccountingProcedureForOSUU_Records AS RegisterData
	|	WHERE
	|		RegisterData.TheseAreChanges
	|
	|	UNION ALL
	|
	|	SELECT
	|		RegisterData.Period AS Date,
	|		RegisterData.Recorder AS Recorder,
	|		RegisterData.TheseAreChanges AS TheseAreChanges
	|	FROM
	|		AccountingProcedureForOSBU_Records AS RegisterData
	|	WHERE
	|		RegisterData.TheseAreChanges
	|
	|	UNION ALL
	|
	|	SELECT
	|		RegisterData.Period AS Date,
	|		RegisterData.Recorder AS Recorder,
	|		RegisterData.TheseAreChanges AS TheseAreChanges
	|	FROM
	|		DepreciationParametersOSUU_Records AS RegisterData
	|	WHERE
	|		RegisterData.TheseAreChanges
	|
	|	UNION ALL
	|
	|	SELECT
	|		RegisterData.Period AS Date,
	|		RegisterData.Recorder AS Recorder,
	|		RegisterData.TheseAreChanges AS TheseAreChanges
	|	FROM
	|		DepreciationParametersOfOSBU_Records AS RegisterData
	|	WHERE
	|		RegisterData.TheseAreChanges
	|
	|	UNION ALL
	|
	|	SELECT
	|		RegisterData.Period AS Date,
	|		RegisterData.Recorder AS Recorder,
	|		RegisterData.TheseAreChanges AS TheseAreChanges
	|	FROM
	|		AccountingProcedureForOS_Records AS RegisterData
	|	WHERE
	|		RegisterData.TheseAreChanges
	|
	|	UNION ALL
	|
	|	SELECT
	|		RegisterData.Period AS Date,
	|		RegisterData.Recorder AS Recorder,
	|		TRUE AS TheseAreChanges
	|	FROM
	|		OS_WriteCost AS RegisterData
	|
	|	UNION ALL
	|
	|	SELECT
	|		RegisterData.Period AS Date,
	|		RegisterData.Recorder AS Recorder,
	|		TRUE AS TheseAreChanges
	|	FROM
	|		DepreciationOfOS_Records AS RegisterData
	|
	|	) AS TableOfDates
	|
	|		LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|		ON FixedAssetsDocuments.Ref = TableOfDates.Recorder
	|			AND FixedAssetsDocuments.RecNo = 0
	|			AND FixedAssetsDocuments.AdditionalRecord = FALSE
	|	
	|GROUP BY
	|	TableOfDates.Date,
	|	TableOfDates.TheseAreChanges,
	|	TableOfDates.Recorder, 
	|	ISNULL(FixedAssetsDocuments.BusinessOperation, UNDEFINED),
	|	ISNULL(FixedAssetsDocuments.Date, TableOfDates.Date),
	|	ISNULL(FixedAssetsDocuments.RecordInManAccounting, TRUE),
	|	ISNULL(FixedAssetsDocuments.RecordInLocalAccounting, TRUE),
	|	ISNULL(FixedAssetsDocuments.RecordInTA, TRUE)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
				
	#Region ListOfAllFA
	QueryText =
	"SELECT DISTINCT
	|	ListOfAllFA.Period AS Period,
	|	ListOfAllFA.Recorder AS Recorder,
	|	ListOfAllFA.FixedAsset AS FixedAsset
	|
	|INTO ListOfAllFA
	|
	|FROM
	|	(SELECT
	|		AllRegisterEntries.Date AS Period,
	|		AllRegisterEntries.Recorder AS Recorder,
	|		&FixedAsset AS FixedAsset
	|	FROM
	|		AllRegisterEntries AS AllRegisterEntries
	|
	|	UNION ALL
	|
	|	SELECT
	|		SourceAndDestinationTable.Date AS Period,
	|		SourceAndDestinationTable.Ref AS Recorder,
	|		SourceAndDestinationTable.MainMeansSource AS FixedAsset
	|	FROM
	|		SourceAndDestinationTable AS SourceAndDestinationTable
	|
	|	) AS ListOfAllFA
	|
	|INDEX BY
	|	FixedAsset,
	|	Period
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
		
	#Region CostAtBeginningOfYear
	QueryText = 
	"SELECT
	|	FACost.CostBalance AS Cost,
	|	FACost.LocalCostBalance AS LocalCost
	|INTO CostAtBeginningOfYear
	|FROM
	|	AccumulationRegister.FACost.Balance(&EndOfPreviousYearBorder, FixedAsset = &FixedAsset) AS FACost";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region DepreciationAsOfTheYearStart
	QueryText = 
	"SELECT
	|	-FixedAssetsDepreciationCharge.DepreciationBalance AS Depreciation,
	|	-FixedAssetsDepreciationCharge.DepreciationLocalBalance AS DepreciationLocal
	|INTO DepreciationAsOfTheYearStart
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge.Balance(&EndOfPreviousYearBorder, FixedAsset = &FixedAsset) AS FixedAssetsDepreciationCharge";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region CostAtBeginningOfPeriod
	QueryText = 
	"SELECT
	|	FACost.FixedAsset AS FixedAsset,
	|	SUM(FACost.Cost) AS Cost,
	|	SUM(FACost.LocalCost) AS LocalCost,
	|	SUM(FACost.CostInTaxAccounting) AS CostInTaxAccounting,
	|	SUM(FACost.CostPermanentDifference) AS CostPermanentDifference,
	|	SUM(FACost.CostTargetFinancing) AS CostTargetFinancing,
	|	SUM(FACost.CostTargetFinancingPD) AS CostTargetFinancingPD,
	|	SUM(FACost.PreliminaryCostMan) AS PreliminaryCostMan,
	|	SUM(FACost.PreliminaryCostLocal) AS PreliminaryCostLocal,
	|	SUM(FACost.DepreciationAllowance) AS DepreciationAllowance
	|
	|INTO CostAtBeginningOfPeriod
	|
	|FROM
	|	(SELECT
	|		FACost.FixedAsset AS FixedAsset,
	|		FACost.CostBalance AS Cost,
	|		FACost.LocalCostBalance AS LocalCost,
	|		FACost.CostInTaxAccountingBalance AS CostInTaxAccounting,
	|		FACost.CostPermanentDifferenceBalance AS CostPermanentDifference,
	|		FACost.CostTargetFinancingBalance AS CostTargetFinancing,
	|		FACost.CostTargetFinancingPDBalance AS CostTargetFinancingPD,
	|		FACost.PreliminaryCostManBalance AS PreliminaryCostMan,
	|		FACost.PreliminaryCostLocalBalance AS PreliminaryCostLocal,
	|		FACost.DepreciationAllowanceBalance AS DepreciationAllowance
	|
	|	FROM
	|		AccumulationRegister.FACost.Balance(
	|			&EndOfPreviousMonthBorder, 
	|			FixedAsset IN (
	|				SELECT 
	|					ListOfAllFA.FixedAsset
	|				FROM 
	|					ListOfAllFA AS ListOfAllFA)) AS FACost
	|
	|	UNION ALL
	|
	|	SELECT
	|		FACost.FixedAsset AS FixedAsset,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.Cost
	|			ELSE -FACost.Cost
	|		END AS Cost,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.LocalCost
	|			ELSE -FACost.LocalCost
	|		END AS LocalCost,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.CostInTaxAccounting
	|			ELSE -FACost.CostInTaxAccounting
	|		END AS CostInTaxAccounting,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.CostPermanentDifference
	|			ELSE -FACost.CostPermanentDifference
	|		END AS CostPermanentDifference,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.CostTargetFinancing
	|			ELSE -FACost.CostTargetFinancing
	|		END AS CostTargetFinancing,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.CostTargetFinancingPD
	|			ELSE -FACost.CostTargetFinancingPD
	|		END AS CostTargetFinancingPD,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.PreliminaryCostMan
	|			ELSE -FACost.PreliminaryCostMan
	|		END AS PreliminaryCostMan,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.PreliminaryCostLocal
	|			ELSE -FACost.PreliminaryCostLocal
	|		END AS PreliminaryCostLocal,
	|
	|		CASE 
	|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.DepreciationAllowance
	|			ELSE -FACost.DepreciationAllowance
	|		END AS DepreciationAllowance
	|
	|	FROM
	|		AccumulationRegister.FACost AS FACost
	|
	|			LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|			ON FixedAssetsDocuments.Ref = FACost.Recorder
	|				AND FixedAssetsDocuments.RecNo = 0
	|				AND FixedAssetsDocuments.AdditionalRecord = FALSE
	|
	|	WHERE
	|		FACost.Active
	|		AND FACost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND FACost.FixedAsset = &FixedAsset
	|
	|		AND ISNULL(FixedAssetsDocuments.IsPatch, FALSE)
	|		AND ISNULL(FixedAssetsDocuments.CorrectionPeriodStart, DATETIME(1,1,1)) < &BeginOfPeriod
	|
	|		AND VALUETYPE(FACost.Recorder) IN (
	|				TYPE(Document.FixedAssetsInitialRecognition2_4),
	|				TYPE(Document.FixedAssetsCostAdditions2_4),
	|				TYPE(Document.AllocateVariancesToFixedAssetCost))
	|
	|	) AS FACost
	|
	|GROUP BY
	|	FACost.FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DepreciationAsOfThePeriodStart
	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|	SUM(FixedAssetsDepreciationCharge.Depreciation) AS Depreciation,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationLocal) AS DepreciationLocal,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting) AS DepreciationInTaxAccounting,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences) AS DepreciationPermanentDifferences,
	|	SUM(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing) AS FixedAssetDepreciationTargetFinancing,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD) AS DepreciationTargetFinancingPD
	|
	|INTO DepreciationAsOfThePeriodStart
	|
	|FROM
	|	(SELECT
	|		FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|		-FixedAssetsDepreciationCharge.DepreciationBalance AS Depreciation,
	|		-FixedAssetsDepreciationCharge.DepreciationLocalBalance AS DepreciationLocal,
	|		-FixedAssetsDepreciationCharge.DepreciationInTaxAccountingBalance AS DepreciationInTaxAccounting,
	|		-FixedAssetsDepreciationCharge.DepreciationPermanentDifferencesBalance AS DepreciationPermanentDifferences,
	|		-FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancingBalance AS FixedAssetDepreciationTargetFinancing,
	|		-FixedAssetsDepreciationCharge.DepreciationTargetFinancingPDBalance AS DepreciationTargetFinancingPD
	|
	|	FROM
	|		AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
	|			&EndOfPreviousMonthBorder, 
	|			FixedAsset = &FixedAsset) AS FixedAssetsDepreciationCharge
	|
	|	UNION ALL
	|
	|	SELECT
	|		FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN FixedAssetsDepreciationCharge.Depreciation
	|			ELSE -FixedAssetsDepreciationCharge.Depreciation
	|		END AS Depreciation,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN FixedAssetsDepreciationCharge.DepreciationLocal
	|			ELSE -FixedAssetsDepreciationCharge.DepreciationLocal
	|		END AS DepreciationLocal,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
	|			ELSE -FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
	|		END AS DepreciationInTaxAccounting,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
	|			ELSE -FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
	|		END AS DepreciationPermanentDifferences,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
	|			ELSE -FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
	|		END AS FixedAssetDepreciationTargetFinancing,
	|
	|		CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD
	|			ELSE -FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD
	|		END AS DepreciationTargetFinancingPD
	|
	|	FROM
	|		AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
	|
	|	WHERE
	|		FixedAssetsDepreciationCharge.Active
	|		AND FixedAssetsDepreciationCharge.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND FixedAssetsDepreciationCharge.FixedAsset = &FixedAsset
	|		AND FixedAssetsDepreciationCharge.AccrualPeriod < &BeginOfPeriod
	|		AND FixedAssetsDepreciationCharge.AccrualPeriod <> DATETIME(1,1,1)
	|
	|	UNION ALL
	|
	|	SELECT
	|		FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|		-FixedAssetsDepreciationCharge.DepreciationBalance AS Depreciation,
	|		-FixedAssetsDepreciationCharge.DepreciationLocalBalance AS DepreciationLocal,
	|		-FixedAssetsDepreciationCharge.DepreciationInTaxAccountingBalance AS DepreciationInTaxAccounting,
	|		-FixedAssetsDepreciationCharge.DepreciationPermanentDifferencesBalance AS DepreciationPermanentDifferences,
	|		-FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancingBalance AS FixedAssetDepreciationTargetFinancing,
	|		-FixedAssetsDepreciationCharge.DepreciationTargetFinancingPDBalance AS DepreciationTargetFinancingPD
	|
	|	FROM
	|		AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
	|			&EndOfPreviousMonthBorder, 
	|			FixedAsset IN (
	|				SELECT 
	|					Table.MainMeansSource 
	|				FROM 
	|					SourceAndDestinationTable AS Table)) AS FixedAssetsDepreciationCharge
	|
	|	) AS FixedAssetsDepreciationCharge
	|
	|GROUP BY
	|	FixedAssetsDepreciationCharge.FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region InitialCost
	QueryText = 
	"SELECT
	|	FACost.FixedAsset AS FixedAsset,
	|	SUM(FACost.Cost) AS Cost,
	|	SUM(FACost.LocalCost) AS LocalCost,
	|	SUM(FACost.CostInTaxAccounting) AS CostInTaxAccounting,
	|	SUM(FACost.CostPermanentDifference) AS CostPermanentDifference,
	|	SUM(FACost.CostTargetFinancing) AS CostTargetFinancing,
	|	SUM(FACost.CostTargetFinancingPD) AS CostTargetFinancingPD,
	|	SUM(FACost.PreliminaryCostMan) AS PreliminaryCostMan,
	|	SUM(FACost.PreliminaryCostLocal) AS PreliminaryCostLocal,
	|	SUM(FACost.PreliminaryCostTA) AS PreliminaryCostTA,
	|	SUM(FACost.PreliminaryCostPD) AS PreliminaryCostPD,
	|	SUM(FACost.DepreciationAllowance) AS DepreciationAllowance
	|
	|INTO InitialCost
	|
	|FROM
	|	(SELECT
	|		FACost.FixedAsset AS FixedAsset,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.Cost
	|			ELSE -FACost.Cost
	|		END AS Cost,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.LocalCost
	|			ELSE -FACost.LocalCost
	|		END AS LocalCost,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.CostInTaxAccounting
	|			ELSE -FACost.CostInTaxAccounting
	|		END AS CostInTaxAccounting,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN FACost.CostPermanentDifference
	|			ELSE -FACost.CostPermanentDifference
	|		END AS CostPermanentDifference,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.CostTemporaryDifference
	|			ELSE -FACost.CostTemporaryDifference
	|		END AS CostTemporaryDifference,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.CostTargetFinancing
	|			ELSE -FACost.CostTargetFinancing
	|		END AS CostTargetFinancing,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.CostTargetFinancingTA
	|			ELSE -FACost.CostTargetFinancingTA
	|		END AS CostTargetFinancingTA,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.CostTargetFinancingPD
	|			ELSE -FACost.CostTargetFinancingPD
	|		END AS CostTargetFinancingPD,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.CostTargetFinancingTD
	|			ELSE -FACost.CostTargetFinancingTD
	|		END AS CostTargetFinancingTD,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.DisregardedCostTA
	|			ELSE -FACost.DisregardedCostTA
	|		END AS DisregardedCostTA,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.DepreciationAllowance
	|			ELSE -FACost.DepreciationAllowance
	|		END AS DepreciationAllowance,
	|
	|		CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN FACost.SecurityDepositValue
	|			ELSE -FACost.SecurityDepositValue
	|		END AS SecurityDepositValue,
	|
	|		0 AS PreliminaryCostMan,
	|		0 AS PreliminaryCostLocal,
	|		0 AS PreliminaryCostTA,
	|		0 AS PreliminaryCostPD
	|
	|	FROM
	|		AccumulationRegister.FACost AS FACost
	|	WHERE
	|		FACost.Active
	|		AND FACost.FixedAsset = &FixedAsset
	|		AND FACost.Recorder IN (&ListOfCommissioningDocuments)
	|		AND FACost.BusinessOperation <> VALUE(Enum.BusinessTransactions.IncludeDepreciationAllowanceInExpenses)
	|
	|	UNION ALL
	|
	|	SELECT
	|		FACost.FixedAsset AS FixedAsset,
	|
	|		0 AS Cost,
	|		0 AS LocalCost,
	|		0 AS CostInTaxAccounting,
	|		0 AS CostPermanentDifference,
	|		0 AS CostTemporaryDifference,
	|		0 AS CostTargetFinancing,
	|		0 AS CostTargetFinancingTA,
	|		0 AS CostTargetFinancingPD,
	|		0 AS CostTargetFinancingTD,
	|		0 AS DisregardedCostTA,
	|		0 AS DepreciationAllowance,
	|		0 AS SecurityDepositValue,
	|
	|		FACost.CostInManagementAccounting AS PreliminaryCostMan,
	|		FACost.CostInAccounting AS PreliminaryCostLocal,
	|		FACost.CostInTaxAccounting AS PreliminaryCostTA,
	|		FACost.CostPermanentDifference AS PreliminaryCostPD
	|
	|	FROM
	|		Document.FixedAssetsInitialRecognition2_4.FA AS FACost
	|	WHERE
	|		FACost.FixedAsset = &FixedAsset
	|		AND FACost.Ref IN (&ListOfCommissioningDocuments)
	|
	|	UNION ALL
	|
	|	SELECT
	|		FACost.DepreciationComponent AS FixedAsset,
	|
	|		0 AS Cost,
	|		0 AS LocalCost,
	|		0 AS CostInTaxAccounting,
	|		0 AS CostPermanentDifference,
	|		0 AS CostTemporaryDifference,
	|		0 AS CostTargetFinancing,
	|		0 AS CostTargetFinancingTA,
	|		0 AS CostTargetFinancingPD,
	|		0 AS CostTargetFinancingTD,
	|		0 AS DisregardedCostTA,
	|		0 AS DepreciationAllowance,
	|		0 AS SecurityDepositValue,
	|
	|		FACost.CostInManagementAccounting AS PreliminaryCostMan,
	|		FACost.CostInAccounting AS PreliminaryCostLocal,
	|		0 AS PreliminaryCostTA,
	|		0 AS PreliminaryCostPD
	|
	|	FROM
	|		Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS FACost
	|	WHERE
	|		FACost.FixedAsset = &FixedAsset
	|		AND FACost.Ref IN (&ListOfCommissioningDocuments)
	|
	|	UNION ALL
	|
	|	SELECT
	|		FACost.FixedAsset AS FixedAsset,
	|
	|		0 AS Cost,
	|		0 AS LocalCost,
	|		0 AS CostInTaxAccounting,
	|		0 AS CostPermanentDifference,
	|		0 AS CostTemporaryDifference,
	|		0 AS CostTargetFinancing,
	|		0 AS CostTargetFinancingTA,
	|		0 AS CostTargetFinancingPD,
	|		0 AS CostTargetFinancingTD,
	|		0 AS DisregardedCostTA,
	|		0 AS DepreciationAllowance,
	|		0 AS SecurityDepositValue,
	|
	|		FACost.CostInManagementAccounting AS PreliminaryCostMan,
	|		FACost.CostInAccounting AS PreliminaryCostLocal,
	|		FACost.CostInTaxAccounting AS PreliminaryCostTA,
	|		FACost.CostPermanentDifference AS PreliminaryCostPD
	|
	|	FROM
	|		Document.SplitFixedAssets.FA AS FACost
	|	WHERE
	|		FACost.FixedAsset = &FixedAsset
	|		AND FACost.Ref IN (&ListOfCommissioningDocuments)
	|
	|	) AS FACost
	|
	|GROUP BY
	|	FACost.FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CostAsOfDate
	QueryText = 
	"SELECT
	|	FACost.Organization AS Organization,
	|	FACost.FixedAsset AS FixedAsset,
	|	FACost.CostBalance AS Cost,
	|	FACost.LocalCostBalance AS LocalCost,
	|	FACost.CostInTaxAccountingBalance AS CostInTaxAccounting,
	|	FACost.CostPermanentDifferenceBalance AS CostPermanentDifference,
	|	FACost.CostTargetFinancingBalance AS CostTargetFinancing,
	|	FACost.CostTargetFinancingPDBalance AS CostTargetFinancingPD,
	|	FACost.PreliminaryCostManBalance AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocalBalance AS PreliminaryCostLocal,
	|	FACost.DepreciationAllowanceBalance AS DepreciationAllowance
	|
	|INTO CostBalance
	|
	|FROM
	|	AccumulationRegister.FACost.Balance(
	|		&EndOfPreviousMonthBorder, 
	|		FixedAsset IN (
	|			SELECT 
	|				ListOfAllFA.FixedAsset 
	|			FROM 
	|				ListOfAllFA AS ListOfAllFA)) AS FACost
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FACost.Period AS Period,
	|	FACost.Recorder AS Recorder,
	|	FACost.Organization AS Organization,
	|	FACost.FixedAsset AS FixedAsset,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.Cost
	|		ELSE -FACost.Cost
	|	END AS Cost,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.LocalCost
	|		ELSE -FACost.LocalCost
	|	END AS LocalCost,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostInTaxAccounting
	|		ELSE -FACost.CostInTaxAccounting
	|	END AS CostInTaxAccounting,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostPermanentDifference
	|		ELSE -FACost.CostPermanentDifference
	|	END AS CostPermanentDifference,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTemporaryDifference
	|		ELSE -FACost.CostTemporaryDifference
	|	END AS CostTemporaryDifference,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTargetFinancing
	|		ELSE -FACost.CostTargetFinancing
	|	END AS CostTargetFinancing,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTargetFinancingTA
	|		ELSE -FACost.CostTargetFinancingTA
	|	END AS CostTargetFinancingTA,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTargetFinancingPD
	|		ELSE -FACost.CostTargetFinancingPD
	|	END AS CostTargetFinancingPD,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTargetFinancingTD
	|		ELSE -FACost.CostTargetFinancingTD
	|	END AS CostTargetFinancingTD,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.DisregardedCostTA
	|		ELSE -FACost.DisregardedCostTA
	|	END AS DisregardedCostTA,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.DepreciationAllowance
	|		ELSE -FACost.DepreciationAllowance
	|	END AS DepreciationAllowance,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.SecurityDepositValue
	|		ELSE -FACost.SecurityDepositValue
	|	END AS SecurityDepositValue,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.PreliminaryCostMan
	|		ELSE -FACost.PreliminaryCostMan
	|	END AS PreliminaryCostMan,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.PreliminaryCostLocal
	|		ELSE -FACost.PreliminaryCostLocal
	|	END AS PreliminaryCostLocal,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostRevaluationReserve
	|		ELSE -FACost.CostRevaluationReserve
	|	END AS CostRevaluationReserve,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostRevaluationReserveLocal
	|		ELSE -FACost.CostRevaluationReserveLocal
	|	END AS CostRevaluationReserveLocal,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FACost.CostGainMA
	|		ELSE FACost.CostGainMA
	|	END AS CostGainMA,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FACost.CostGainLocal
	|		ELSE FACost.CostGainLocal
	|	END AS CostGainLocal
	|
	|INTO CostOfRegisteringRecords
	|
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|
	|WHERE
	|	FACost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND FACost.Active
	|
	|	AND FACost.FixedAsset IN
	|			(SELECT 
	|				ListOfAllFA.FixedAsset 
	|			FROM 
	|				ListOfAllFA AS ListOfAllFA)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FACost.Period AS Period,
	|	FACost.Recorder AS Recorder,
	|	FACost.Organization AS Organization,
	|	FACost.FixedAsset AS FixedAsset,
	|
	|	SUM(FACost.Cost) AS Cost,
	|	SUM(FACost.LocalCost) AS LocalCost,
	|	SUM(FACost.CostInTaxAccounting) AS CostInTaxAccounting,
	|	SUM(FACost.CostPermanentDifference) AS CostPermanentDifference,
	|	SUM(FACost.CostTargetFinancing) AS CostTargetFinancing,
	|	SUM(FACost.CostTargetFinancingPD) AS CostTargetFinancingPD,
	|	SUM(FACost.PreliminaryCostMan) AS PreliminaryCostMan,
	|	SUM(FACost.PreliminaryCostLocal) AS PreliminaryCostLocal,
	|	SUM(FACost.DepreciationAllowance) AS DepreciationAllowance
	|
	|INTO CostAsOfDate
	|
	|FROM
	|	(SELECT
	|		ListOfAllFA.Period AS Period,
	|		ListOfAllFA.Recorder AS Recorder,
	|		FACost.Organization AS Organization,
	|		FACost.FixedAsset AS FixedAsset,
	|		FACost.Cost AS Cost,
	|		FACost.LocalCost AS LocalCost,
	|		FACost.CostInTaxAccounting AS CostInTaxAccounting,
	|		FACost.CostPermanentDifference AS CostPermanentDifference,
	|		FACost.CostTargetFinancing AS CostTargetFinancing,
	|		FACost.CostTargetFinancingPD AS CostTargetFinancingPD,
	|		FACost.PreliminaryCostMan AS PreliminaryCostMan,
	|		FACost.PreliminaryCostLocal AS PreliminaryCostLocal,
	|		FACost.DepreciationAllowance AS DepreciationAllowance
	|	FROM
	|		ListOfAllFA AS ListOfAllFA
	|
	|			INNER JOIN CostBalance AS FACost
	|			ON FACost.FixedAsset = ListOfAllFA.FixedAsset
	|
	|	UNION ALL
	|
	|	SELECT
	|		ListOfAllFA.Period AS Period,
	|		ListOfAllFA.Recorder AS Recorder,
	|		FACost.Organization AS Organization,
	|		FACost.FixedAsset AS FixedAsset,
	|		FACost.Cost AS Cost,
	|		FACost.LocalCost AS LocalCost,
	|		FACost.CostInTaxAccounting AS CostInTaxAccounting,
	|		FACost.CostPermanentDifference AS CostPermanentDifference,
	|		FACost.CostTargetFinancing AS CostTargetFinancing,
	|		FACost.CostTargetFinancingPD AS CostTargetFinancingPD,
	|		FACost.PreliminaryCostMan AS PreliminaryCostMan,
	|		FACost.PreliminaryCostLocal AS PreliminaryCostLocal,
	|		FACost.DepreciationAllowance AS DepreciationAllowance
	|
	|FROM
	|		ListOfAllFA AS ListOfAllFA
	|
	|			INNER JOIN CostOfRegisteringRecords AS FACost
	|			ON FACost.FixedAsset = ListOfAllFA.FixedAsset
	|				AND (FACost.Period <= ListOfAllFA.Period
	|					OR VALUETYPE(FACost.Recorder) IN (&TypesOfDocumentsThatChangeValueAtEndOfMonth))
	|				AND (FACost.Recorder <> ListOfAllFA.Recorder)
	|
	|	) AS FACost
	|
	|GROUP BY
	|	FACost.Period,
	|	FACost.Recorder,
	|	FACost.FixedAsset,
	|	FACost.Organization
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region DepreciationAsOfDate
	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge.Organization AS Organization,
	|	FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|
	|	-FixedAssetsDepreciationCharge.DepreciationBalance AS Depreciation,
	|	-FixedAssetsDepreciationCharge.DepreciationLocalBalance AS DepreciationLocal,
	|	-FixedAssetsDepreciationCharge.DepreciationInTaxAccountingBalance AS DepreciationInTaxAccounting,
	|	-FixedAssetsDepreciationCharge.DepreciationPermanentDifferencesBalance AS DepreciationPermanentDifferences,
	|	-FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancingBalance AS FixedAssetDepreciationTargetFinancing,
	|	-FixedAssetsDepreciationCharge.DepreciationTargetFinancingPDBalance AS DepreciationTargetFinancingPD
	|
	|INTO DepreciationBalance
	|
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
	|		&EndOfPreviousMonthBorder, 
	|		FixedAsset IN (
	|			SELECT 
	|				ListOfAllFA.FixedAsset 
	|			FROM 
	|				ListOfAllFA AS ListOfAllFA)) AS FixedAssetsDepreciationCharge
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FixedAssetsDepreciationCharge.Period AS Period,
	|	FixedAssetsDepreciationCharge.Recorder AS Recorder,
	|	FixedAssetsDepreciationCharge.Organization AS Organization,
	|	FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|	FixedAssetsDepreciationCharge.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	FixedAssetsDepreciationCharge.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|
	|	CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.Depreciation
	|		ELSE FixedAssetsDepreciationCharge.Depreciation
	|	END AS Depreciation,
	|
	|	CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.DepreciationLocal
	|		ELSE FixedAssetsDepreciationCharge.DepreciationLocal
	|	END AS DepreciationLocal,
	|
	|	CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
	|		ELSE FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
	|	END AS DepreciationInTaxAccounting,
	|
	|	CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
	|		ELSE FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
	|	END AS DepreciationPermanentDifferences,
	|
	|	CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.DepreciationTD
	|		ELSE FixedAssetsDepreciationCharge.DepreciationTD
	|	END AS DepreciationTD,
	|
	|	CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
	|		ELSE FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD
	|		ELSE FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD
	|	END AS DepreciationTargetFinancingPD
	|
	|INTO DepreciationOfRegisteredRecorded
	|
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
	|
	|WHERE
	|	FixedAssetsDepreciationCharge.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND FixedAssetsDepreciationCharge.Active
	|
	|	AND FixedAssetsDepreciationCharge.FixedAsset IN
	|			(SELECT 
	|				ListOfAllFA.FixedAsset 
	|			FROM 
	|				ListOfAllFA AS ListOfAllFA)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FixedAssetsDepreciationCharge.Period AS Period,
	|	FixedAssetsDepreciationCharge.Recorder AS Recorder,
	|	FixedAssetsDepreciationCharge.Organization AS Organization,
	|	FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|
	|	SUM(FixedAssetsDepreciationCharge.Depreciation) AS Depreciation,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationLocal) AS DepreciationLocal,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting) AS DepreciationInTaxAccounting,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences) AS DepreciationPermanentDifferences,
	|	SUM(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing) AS FixedAssetDepreciationTargetFinancing,
	|	SUM(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD) AS DepreciationTargetFinancingPD
	|
	|INTO DepreciationAsOfDate
	|
	|FROM
	|	(SELECT
	|		ListOfAllFA.Period AS Period,
	|		ListOfAllFA.Recorder AS Recorder,
	|		FixedAssetsDepreciationCharge.Organization AS Organization,
	|		FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|		FixedAssetsDepreciationCharge.Depreciation AS Depreciation,
	|		FixedAssetsDepreciationCharge.DepreciationLocal AS DepreciationLocal,
	|		FixedAssetsDepreciationCharge.DepreciationInTaxAccounting AS DepreciationInTaxAccounting,
	|		FixedAssetsDepreciationCharge.DepreciationPermanentDifferences AS DepreciationPermanentDifferences,
	|		FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing AS FixedAssetDepreciationTargetFinancing,
	|		FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD AS DepreciationTargetFinancingPD
	|	FROM
	|		ListOfAllFA AS ListOfAllFA
	|
	|			INNER JOIN DepreciationBalance AS FixedAssetsDepreciationCharge
	|			ON FixedAssetsDepreciationCharge.FixedAsset = ListOfAllFA.FixedAsset
	|
	|	UNION ALL
	|
	|	SELECT
	|		ListOfAllFA.Period AS Period,
	|		ListOfAllFA.Recorder AS Recorder,
	|		FixedAssetsDepreciationCharge.Organization AS Organization,
	|		FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|
	|		CASE
	|			WHEN FixedAssetsDepreciationCharge.ProcedureForCalculatingDepreciationOfMa <> VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|					OR FixedAssetsDepreciationCharge.Period <= ListOfAllFA.Period
	|				THEN FixedAssetsDepreciationCharge.Depreciation
	|			ELSE 0
	|		END AS Depreciation,
	|
	|		CASE
	|			WHEN FixedAssetsDepreciationCharge.ProcedureForCalculatingDepreciationAC <> VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|					OR FixedAssetsDepreciationCharge.Period <= ListOfAllFA.Period
	|				THEN FixedAssetsDepreciationCharge.DepreciationLocal
	|			ELSE 0
	|		END AS DepreciationLocal,
	|
	|		FixedAssetsDepreciationCharge.DepreciationInTaxAccounting AS DepreciationInTaxAccounting,
	|
	|		CASE
	|			WHEN FixedAssetsDepreciationCharge.ProcedureForCalculatingDepreciationAC <> VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|					OR FixedAssetsDepreciationCharge.Period <= ListOfAllFA.Period
	|				THEN FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
	|			ELSE 0
	|		END AS DepreciationPermanentDifferences,
	|
	|		CASE
	|			WHEN FixedAssetsDepreciationCharge.ProcedureForCalculatingDepreciationAC <> VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|					OR FixedAssetsDepreciationCharge.Period <= ListOfAllFA.Period
	|				THEN FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
	|			ELSE 0
	|		END AS FixedAssetDepreciationTargetFinancing,
	|
	|		CASE
	|			WHEN FixedAssetsDepreciationCharge.ProcedureForCalculatingDepreciationAC <> VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|					OR FixedAssetsDepreciationCharge.Period <= ListOfAllFA.Period
	|				THEN FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD
	|			ELSE 0
	|		END AS DepreciationTargetFinancingPD
	|
	|	FROM
	|		ListOfAllFA AS ListOfAllFA
	|
	|			INNER JOIN DepreciationOfRegisteredRecorded AS FixedAssetsDepreciationCharge
	|			ON FixedAssetsDepreciationCharge.FixedAsset = ListOfAllFA.FixedAsset
	|				AND (FixedAssetsDepreciationCharge.Period <= ListOfAllFA.Period
	|					OR VALUETYPE(FixedAssetsDepreciationCharge.Recorder) = TYPE(Document.FixedAssetsDepreciationCharge2_4))
	|				AND (FixedAssetsDepreciationCharge.Recorder <> ListOfAllFA.Recorder)
	|
	|	) AS FixedAssetsDepreciationCharge
	|
	|GROUP BY
	|	FixedAssetsDepreciationCharge.Period,
	|	FixedAssetsDepreciationCharge.Recorder,
	|	FixedAssetsDepreciationCharge.FixedAsset,
	|	FixedAssetsDepreciationCharge.Organization
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());

	NonCurrentAssets.ReplaceNameOfRegisterTableWithSliceOfLatestOnesTakingIntoAccountCorrections(
		"InitialInformationOfOS_SliceOfLatterTakingIntoAccountCorrections", Metadata.InformationRegisters.InitialFixedAssetsInformation.Name, QueryText);

	NonCurrentAssets.ReplaceNameOfRecordRegisterTableWithCorrections(
		"InitialInformationOfOS_RecordTakingIntoAccountCorrections", Metadata.InformationRegisters.InitialFixedAssetsInformation.Name, QueryText);

	NonCurrentAssets.ReplaceNameOfRegisterTableWithSliceOfLatestOnesTakingIntoAccountCorrections(
		"AccountingProcedureForOS_SlicesWithCorrections", Metadata.InformationRegisters.FixedAssetsAccountingProcedure.Name, QueryText);
	
	NonCurrentAssets.ReplaceNameOfRecordRegisterTableWithCorrections(
		"AccountingProcedureForOS_RecordsWithCorrections", Metadata.InformationRegisters.FixedAssetsAccountingProcedure.Name, QueryText);
	
	NonCurrentAssets.ReplaceNameOfRegisterTableWithSliceOfLatestOnesTakingIntoAccountCorrections(
		"AccountingProcedureForOSUU_SlicesWithCorrections", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting.Name, QueryText);

	NonCurrentAssets.ReplaceNameOfRecordRegisterTableWithCorrections(
		"AccountingProcedureForOSUU_RecordsWithCorrections", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting.Name, QueryText);

	NonCurrentAssets.ReplaceNameOfRegisterTableWithSliceOfLatestOnesTakingIntoAccountCorrections(
		"AccountingProcedureForOSBU_CutOfLatterTakingIntoAccountCorrections", Metadata.InformationRegisters.AccountingProcedureForOSBU.Name, QueryText);

	NonCurrentAssets.ReplaceNameOfRecordRegisterTableWithCorrections(
		"AccountingProcedureForOSBU_RecordsTakingIntoAccountCorrections", Metadata.InformationRegisters.AccountingProcedureForOSBU.Name, QueryText);

	NonCurrentAssets.ReplaceNameOfRecordRegisterTableWithCorrections(
		"DepreciationParametersOfFAMan_RecordTakingIntoAccountCorrections", Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting.Name, QueryText);

	NonCurrentAssets.ReplaceNameOfRegisterTableWithSliceOfLatestOnesTakingIntoAccountCorrections(
		"DepreciationParametersOfFAMan_SectionOfLatterTakingIntoAccountCorrections", Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting.Name, QueryText);

	NonCurrentAssets.ReplaceNameOfRecordRegisterTableWithCorrections(
		"DepreciationParametersOfOSBU_RecordTakingIntoAccountCorrections", Metadata.InformationRegisters.OSBUDepreciationParameters.Name, QueryText);

	NonCurrentAssets.ReplaceNameOfRegisterTableWithSliceOfLatestOnesTakingIntoAccountCorrections(
		"DepreciationParametersOfOSBU_SliceOfLatterTakingIntoAccountCorrections", Metadata.InformationRegisters.OSBUDepreciationParameters.Name, QueryText);

	NonCurrentAssets.ReplaceNameOfRegisterTableWithSliceOfLatestOnesTakingIntoAccountCorrections(
		"FALocation_SliceLastTakingIntoAccountCorrections", Metadata.InformationRegisters.FALocation.Name, QueryText);
	
	NonCurrentAssets.ReplaceNameOfRecordRegisterTableWithCorrections(
		"LocationOfOS_RecordWithCorrections", Metadata.InformationRegisters.FALocation.Name, QueryText);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = Parameters.TempTablesManager;
	Query.SetParameter("Ref", Parameters.Ref);
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("FixedAsset", Parameters.FixedAsset);
	Query.SetParameter("ListOfFA", Parameters.FixedAsset);
	Query.SetParameter("WithoutFASelection", False);
	Query.SetParameter("DocumentDate", Parameters.Date);
	Query.SetParameter("Date", Parameters.SlicePeriod);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", Parameters.EndOfPeriod);
	Query.SetParameter("EndOfCurrentPeriod", Parameters.EndOfCurrentPeriod);
	Query.SetParameter("EndOfPreviousMonth", Parameters.BeginOfPeriod-1);
	Query.SetParameter("EndOfPreviousMonthBorder", New Boundary(Parameters.BeginOfPeriod-1, BoundaryType.Including));
	Query.SetParameter("EndOfPreviousYearBorder", New Boundary(BegOfYear(Parameters.BeginOfPeriod)-1, BoundaryType.Including));
	Query.SetParameter("TypesOfDocumentsThatChangeValueAtEndOfMonth", DeferredFARecordGeneration.TypesOfDocumentsThatChangeValueAtEndOfMonth());
	Query.SetParameter("StandardDates", Parameters.StandardDates);
	
	ListOfCommissioningDocuments = New Array;
	ListOfCommissioningDocuments.Add(Parameters.CommissioningDocumentAC);
	ListOfCommissioningDocuments.Add(Parameters.CommissioningDocumentTA);
	ListOfCommissioningDocuments.Add(Parameters.CommissioningDocumentMA);
	Query.SetParameter("ListOfCommissioningDocuments", ListOfCommissioningDocuments);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Execute();
	
	#EndRegion

	ParametersForCalculation = New Structure;
	
	FillInParametersForPeriodOfYY(ParametersForCalculation, Parameters);
	FillInParametersForBUPeriod(ParametersForCalculation, Parameters);
	
	FixedAssetsDepreciationChargeLocalization.ParametersForCalculatingDepreciationAccordingToTable(ParametersForCalculation, Parameters);
	
	DataVolume = 0;
	If ParametersForCalculation.Property("ParametersForMAPeriod") Then
		DataVolume = DataVolume + ParametersForCalculation.ParametersForMAPeriod.Count();
	EndIf;
	If ParametersForCalculation.Property("FinancialDetailsForThePeriodAC") Then
		DataVolume = DataVolume + ParametersForCalculation.FinancialDetailsForThePeriodAC.Count();
	EndIf;
	If ParametersForCalculation.Property("FinancialDetailsForThePeriodTA") Then
		DataVolume = DataVolume + ParametersForCalculation.FinancialDetailsForThePeriodTA.Count();
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);

	Return ParametersForCalculation;
	
EndFunction

// Performs the calculation of depreciation according to the parameters specified in the table.
// 
// Parameters:
//  CalculationTables - Structure - Calculation Tables
//  CalculationParameters - Structure - Calculation parameters
//  LineNumber - Number - The number of the line to perform the calculation for
// 
// Returns:
//  Structure - contains depreciation calculation:
//		* MaCalculationResult - ValueTable -
//		* ResultOfCalculationOfBU - ValueTable -
//		* ResultOfCalculationIsTA - ValueTable -
Function CalculateDepreciationAccordingToTable(CalculationTables, CalculationParameters, LineNumber = Undefined) Export
	
	CalculationResult2 = New Structure;
	
	StartCalculatingDepreciationAccordingToSpecifiedParametersOfBU(CalculationResult2, CalculationTables, CalculationParameters, LineNumber);
	StartCalculatingDepreciationAccordingToSpecifiedParametersOfUU(CalculationResult2, CalculationTables, CalculationParameters, LineNumber);
	
	FixedAssetsDepreciationChargeLocalization.CalculateDepreciationAccordingToTable(CalculationResult2, CalculationTables, CalculationParameters, LineNumber);
	
	Return CalculationResult2;
	
EndFunction

Procedure StartCalculatingDepreciationAccordingToSpecifiedParametersOfBU(CalculationResult2, CalculationTables, CalculationParameters, LineNumber)
	
	FinancialDetailsForThePeriod = Undefined;
	
	If Not CalculationTables.Property("FinancialDetailsForThePeriodAC", FinancialDetailsForThePeriod) Then
		Return;
	EndIf;
	
	DepreciationIsCalculated = FixedAssetsDepreciationChargeLocalization.StartCalculatingDepreciationAccordingToSpecifiedParametersOfBU(
		CalculationResult2, CalculationTables, CalculationParameters, LineNumber);
	
	If DepreciationIsCalculated Then
		Return;
	EndIf;
		
	QueryText = 
	"SELECT
	|	FinancialDetailsForThePeriod.Date AS Period,
	|	FinancialDetailsForThePeriod.LineNumber AS LineNumber,
	|	FinancialDetailsForThePeriod.DoNotCalculateDepreciationAC AS DoNotCalculateDepreciation,
	|
	|	0 AS Depreciation,
	|	FinancialDetailsForThePeriod.DepreciationInAccounting AS DepreciationLocal,
	|	0 AS Cost,
	|	FinancialDetailsForThePeriod.CostInAccounting AS LocalCost,
	|	0 AS DepreciationUpdate,
	|	FinancialDetailsForThePeriod.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|
	|	FinancialDetailsForThePeriod.AccelerationFactorAccounting AS AccelerationFactor,
	|	0 AS ResidualValueMan,
	|	FinancialDetailsForThePeriod.ResidualValueMan AS ResidualValueLocal,
	|	FinancialDetailsForThePeriod.DepreciationMethodAccounting AS DepreciationAccrualMethodManagementAccounting,
	|	FinancialDetailsForThePeriod.DepreciationAccrualAccounting AS DepreciationAccrualManagementAccounting,
	|	FinancialDetailsForThePeriod.OutputVolume AS OutputVolume,
	|	FinancialDetailsForThePeriod.OutputAtBeginningOfMonth AS OutputAtBeginningOfMonth,
	|	FinancialDetailsForThePeriod.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	FinancialDetailsForThePeriod.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	FinancialDetailsForThePeriod.DateOfDepreciationParametersChangeAccounting AS DateParametersWereChanged,
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	FinancialDetailsForThePeriod.CostUsedToCalculateDepreciationInAccounting AS CostUsedToCalculateDepreciationLocal,
	|
	|	&TheseAreRentedFA AS TheseAreRentedFA,
	|	&Organization AS Organization,
	|	&FixedAsset AS FixedAsset,
	|	&CommissioningDateAC AS CommissioningDateMA,
	|	0 AS CostAtBeginningOfYear,
	|	&LocalCostAtBeginningOfYear AS LocalCostAtBeginningOfYear,
	|	0 AS DepreciationAsOfTheYearStart,
	|	&LocalDepreciationAsOfTheYearStart AS LocalDepreciationAsOfTheYearStart,
	|	0 AS DepreciationAsOfThePeriodStart,
	|	&LocalDepreciationAtBeginningOfPeriod AS LocalDepreciationAtBeginningOfPeriod
	|
	|INTO ParameterValues
	|
	|FROM
	|	&FinancialDetailsForThePeriodAC AS FinancialDetailsForThePeriod";
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("FinancialDetailsForThePeriodAC", FinancialDetailsForThePeriod);
	Query.SetParameter("Organization", CalculationParameters.Organization);
	Query.SetParameter("FixedAsset", CalculationParameters.FixedAsset);
	Query.SetParameter("CommissioningDateAC", CalculationParameters.CommissioningDateAC);
	Query.SetParameter("LocalCostAtBeginningOfYear", CalculationParameters.LocalCostAtBeginningOfYear);
	Query.SetParameter("LocalDepreciationAsOfTheYearStart", CalculationParameters.LocalDepreciationAsOfTheYearStart);
	Query.SetParameter("LocalDepreciationAtBeginningOfPeriod", CalculationParameters.LocalDepreciationAtBeginningOfPeriod);
	Query.SetParameter("TheseAreRentedFA", CalculationParameters.TheseAreRentedFA);
	
	Query.Execute();
		
	ResultOfCalculationOfBU = CalculateDepreciationAccordingToGivenParameters("ACC", TempTablesManager, LineNumber);
	ResultOfCalculationOfBU.Columns.DepreciationLocal.Name = "DepreciationInAccounting";
	ResultOfCalculationOfBU.Columns.Add("DepreciationPermanentDifferences", TMCommonUse.MoneyFieldTypeDescription());
	ResultOfCalculationOfBU.Columns.Add("FixedAssetDepreciationTargetFinancing", TMCommonUse.MoneyFieldTypeDescription());
	
	CalculationResult2.Insert("ResultOfCalculationOfBU", ResultOfCalculationOfBU);
	
EndProcedure

Procedure StartCalculatingDepreciationAccordingToSpecifiedParametersOfUU(CalculationResult2, CalculationTables, CalculationParameters, LineNumber)
	
	FinancialDetailsForThePeriod = Undefined;
	
	If Not CalculationTables.Property("ParametersForMAPeriod", FinancialDetailsForThePeriod) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	FinancialDetailsForThePeriod.Date AS Period,
	|	FinancialDetailsForThePeriod.LineNumber AS LineNumber,
	|	FinancialDetailsForThePeriod.DoNotCalculateDepreciation AS DoNotCalculateDepreciation,
	|
	|	FinancialDetailsForThePeriod.Depreciation AS Depreciation,
	|	FinancialDetailsForThePeriod.DepreciationLocal AS DepreciationLocal,
	|	FinancialDetailsForThePeriod.Cost AS Cost,
	|	FinancialDetailsForThePeriod.LocalCost AS LocalCost,
	|	FinancialDetailsForThePeriod.DepreciationUpdate AS DepreciationUpdate,
	|	FinancialDetailsForThePeriod.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|
	|	FinancialDetailsForThePeriod.AccelerationFactor AS AccelerationFactor,
	|	FinancialDetailsForThePeriod.ResidualValueMan AS ResidualValueMan,
	|	FinancialDetailsForThePeriod.ResidualValueLocal AS ResidualValueLocal,
	|	FinancialDetailsForThePeriod.DepreciationAccrualMethodManagementAccounting AS DepreciationAccrualMethodManagementAccounting,
	|	FinancialDetailsForThePeriod.DepreciationAccrualManagementAccounting AS DepreciationAccrualManagementAccounting,
	|	FinancialDetailsForThePeriod.OutputVolume AS OutputVolume,
	|	FinancialDetailsForThePeriod.OutputAtBeginningOfMonth AS OutputAtBeginningOfMonth,
	|	FinancialDetailsForThePeriod.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	FinancialDetailsForThePeriod.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	FinancialDetailsForThePeriod.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	FinancialDetailsForThePeriod.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	FinancialDetailsForThePeriod.DateOfDepreciationParametersChangeManagementAccounting AS DateParametersWereChanged,
	|
	|	&TheseAreRentedFA AS TheseAreRentedFA,
	|	&Organization AS Organization,
	|	&FixedAsset AS FixedAsset,
	|	&CommissioningDateMA AS CommissioningDateMA,
	|	&CostAtBeginningOfYear AS CostAtBeginningOfYear,
	|	&LocalCostAtBeginningOfYear AS LocalCostAtBeginningOfYear,
	|	&DepreciationAsOfTheYearStart AS DepreciationAsOfTheYearStart,
	|	&LocalDepreciationAsOfTheYearStart AS LocalDepreciationAsOfTheYearStart,
	|	&DepreciationAsOfThePeriodStart AS DepreciationAsOfThePeriodStart,
	|	&LocalDepreciationAtBeginningOfPeriod AS LocalDepreciationAtBeginningOfPeriod
	|
	|INTO ParameterValues
	|
	|FROM
	|	&FinancialDetailsForThePeriod AS FinancialDetailsForThePeriod";
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("FinancialDetailsForThePeriod", FinancialDetailsForThePeriod);
	
	Query.SetParameter("Organization", CalculationParameters.Organization);
	Query.SetParameter("FixedAsset", CalculationParameters.FixedAsset);
	Query.SetParameter("CommissioningDateMA", CalculationParameters.CommissioningDateMA);
	Query.SetParameter("CostAtBeginningOfYear", CalculationParameters.CostAtBeginningOfYear);
	Query.SetParameter("LocalCostAtBeginningOfYear", CalculationParameters.LocalCostAtBeginningOfYear);
	Query.SetParameter("DepreciationAsOfTheYearStart", CalculationParameters.DepreciationAsOfTheYearStart);
	Query.SetParameter("LocalDepreciationAsOfTheYearStart", CalculationParameters.LocalDepreciationAsOfTheYearStart);
	Query.SetParameter("DepreciationAsOfThePeriodStart", CalculationParameters.DepreciationAsOfThePeriodStart);
	Query.SetParameter("LocalDepreciationAtBeginningOfPeriod", CalculationParameters.LocalDepreciationAtBeginningOfPeriod);
	Query.SetParameter("TheseAreRentedFA", CalculationParameters.TheseAreRentedFA);
	
	Query.Execute();

	MaCalculationResult = CalculateDepreciationAccordingToGivenParameters("MA", TempTablesManager, LineNumber);
	
	CalculationResult2.Insert("MaCalculationResult", MaCalculationResult);
	
EndProcedure

Function CalculateDepreciationAccordingToGivenParameters(AccountingKind, TempTablesManager, LineNumber)
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	
	RegisterMetadata = Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge;
	
	CalculationResult2 = New ValueTable();
	CalculationResult2.Columns.Add("Period", Common.DateTypeDetails(DateFractions.DateTime));
	CalculationResult2.Columns.Add("LineNumber", Common.TypeDescriptionNumber(10));
	CalculationResult2.Columns.Add("Depreciation", TMCommonUse.MoneyFieldTypeDescription());
	CalculationResult2.Columns.Add("DepreciationLocal", TMCommonUse.MoneyFieldTypeDescription());
	CalculationResult2.Columns.Add("LifeSpentPastPeriod", RegisterMetadata.Attributes.LifeSpentPastPeriod.Type);
	CalculationResult2.Columns.Add("LifeSpentCurrentPeriod", RegisterMetadata.Attributes.LifeSpentCurrentPeriod.Type);
	CalculationResult2.Columns.Add("CostUsedToCalculateDepreciationManag", RegisterMetadata.Attributes.CostUsedToCalculateDepreciationManag.Type);
	CalculationResult2.Columns.Add("CostUsedToCalculateDepreciationLocal", RegisterMetadata.Attributes.CostUsedToCalculateDepreciationLocal.Type);
	CalculationResult2.Columns.Add("DepreciationProcedure", RegisterMetadata.Attributes.ProcedureForCalculatingDepreciationOfMa.Type);
	CalculationResult2.Columns.Add("AccountingProcedure", RegisterMetadata.Attributes.AccountingProcedureMA.Type);
	CalculationResult2.Columns.Add("VersionOfAccrualMethod", RegisterMetadata.Attributes.DepreciationMethodVersionMA.Type);
	
	ListOfRequests = New Array;
	
	#Region AccountingPolicyOfMa
	QueryText =
	"SELECT
	|	AccountingPolicy_Period.Period AS Period,
	|	AccountingPolicy_Period.Organization AS Organization,
	|
	|	AccountingPolicy.AccountingPolicyForFixedAssets AS AccountingPolicyForFixedAssets,
	|
	|	CASE
	|		WHEN AccountingPolicy_Period.TheseAreRentedFA
	|			THEN AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag 
	|		ELSE AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge
	|	END AS DepreciationProcedure,
	|
	|	AccountingPolicy.MonthOfFiscalYearBeginning AS MonthOfFiscalYearBeginning
	|
	|INTO AccountingPolicyOfMa
	|
	|FROM
	|	(SELECT
	|		ParameterValues.Period AS Period,
	|		ParameterValues.Organization AS Organization,
	|		ParameterValues.TheseAreRentedFA AS TheseAreRentedFA,
	|		Companies.ParentCompany AS ParentCompany,
	|		MAX(AccountingPolicy.Period) AS PeriodAccountingPolicy
	|	FROM
	|		ParameterValues AS ParameterValues
	|
	|			INNER JOIN Catalog.Companies AS Companies
	|			ON Companies.Ref = ParameterValues.Organization
	|
	|			INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
	|			ON AccountingPolicy.Organization = Companies.ParentCompany
	|				AND AccountingPolicy.Period <= ParameterValues.Period
	|
	|	GROUP BY
	|		ParameterValues.Period,
	|		ParameterValues.Organization,
	|		ParameterValues.TheseAreRentedFA,
	|		Companies.ParentCompany
	|
	|	) AS AccountingPolicy_Period
	|
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
	|		ON AccountingPolicy.Organization = AccountingPolicy_Period.ParentCompany
	|			AND AccountingPolicy.Period = AccountingPolicy_Period.PeriodAccountingPolicy
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region AccountingPolicyOfBU
	QueryText =
	"SELECT
	|	AccountingPolicy_Period.Period AS Period,
	|	AccountingPolicy_Period.Organization AS Organization,
	|
	|	VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards) AS AccountingPolicyForFixedAssets,
	|
	|	CASE
	|		WHEN &AccountingKind = ""MA""
	|			THEN AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting 
	|		ELSE VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|	END AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	CASE
	|		WHEN &AccountingKind = ""ACC"" AND AccountingPolicy_Period.TheseAreRentedFA
	|			THEN AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal 
	|		WHEN &AccountingKind = ""ACC"" AND NOT AccountingPolicy_Period.TheseAreRentedFA
	|			THEN AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal 
	|		WHEN AccountingPolicy_Period.TheseAreRentedFA
	|			THEN AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag 
	|		ELSE AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge
	|	END AS DepreciationProcedure
	|
	|INTO AccountingPolicyOfBU
	|
	|FROM
	|	(SELECT
	|		ParameterValues.Period AS Period,
	|		ParameterValues.Organization AS Organization,
	|		ParameterValues.TheseAreRentedFA AS TheseAreRentedFA,
	|		Companies.ParentCompany AS ParentCompany,
	|		MAX(AccountingPolicy.Period) AS PeriodAccountingPolicy
	|	FROM
	|		ParameterValues AS ParameterValues
	|
	|			INNER JOIN Catalog.Companies AS Companies
	|			ON Companies.Ref = ParameterValues.Organization
	|
	|			INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
	|			ON AccountingPolicy.Organization = Companies.ParentCompany
	|				AND AccountingPolicy.Period <= ParameterValues.Period
	|
	|	GROUP BY
	|		ParameterValues.Period,
	|		ParameterValues.Organization,
	|		ParameterValues.TheseAreRentedFA,
	|		Companies.ParentCompany
	|
	|	) AS AccountingPolicy_Period
	|
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
	|		ON AccountingPolicy.Organization = AccountingPolicy_Period.ParentCompany
	|			AND AccountingPolicy.Period = AccountingPolicy_Period.PeriodAccountingPolicy
	|";
	
	
	ListOfRequests.Add(QueryText);
	#EndRegion	

	#Region SelectingRows
	QueryText =
	"SELECT
	|	ParameterValues.LineNumber AS LineNumber,
	|	ParameterValues.Period AS Period,
	|
	|	ParameterValues.Depreciation AS Depreciation,
	|	ParameterValues.DepreciationLocal AS DepreciationLocal,
	|
	|	ParameterValues.DepreciationUpdate AS DepreciationUpdate,
	|	ParameterValues.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|
	|	CASE
	|		WHEN &AccountingKind = ""ACC""
	|			THEN ISNULL(AccountingPolicyOfBU.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards))
	|		ELSE ISNULL(AccountingPolicyOfMa.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards))
	|	END AS AccountingPolicyForFixedAssets,
	|
	|	ISNULL(AccountingPolicyOfBU.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)) AS FixedAssetAccountingProcedureInLocalAccounting,
	|
	|	CASE
	|		WHEN &AccountingKind = ""ACC""
	|			THEN ISNULL(AccountingPolicyOfBU.DepreciationProcedure, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|		ELSE ISNULL(AccountingPolicyOfMa.DepreciationProcedure, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|	END AS DepreciationProcedure,
	|
	|	CASE
	|		WHEN MONTH(ParameterValues.Period) < ISNULL(AccountingPolicyOfMa.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(ParameterValues.Period, YEAR), MONTH, ISNULL(AccountingPolicyOfMa.MonthOfFiscalYearBeginning, 1) - 13)
	|		ELSE DATEADD(BEGINOFPERIOD(ParameterValues.Period, YEAR), MONTH, ISNULL(AccountingPolicyOfMa.MonthOfFiscalYearBeginning, 1) - 1) 
	|	END AS BeginningOfFiscalYear,
	|	
	|	CASE
	|		WHEN MONTH(ParameterValues.Period) < ISNULL(AccountingPolicyOfMa.MonthOfFiscalYearBeginning, 1)
	|			THEN DATEADD(BEGINOFPERIOD(ParameterValues.Period, YEAR), MONTH, ISNULL(AccountingPolicyOfMa.MonthOfFiscalYearBeginning, 1) - 1)
	|		ELSE DATEADD(BEGINOFPERIOD(ParameterValues.Period, YEAR), MONTH, ISNULL(AccountingPolicyOfMa.MonthOfFiscalYearBeginning, 1) + 11) 
	|	END AS EndOfFiscalYear
	|
	|FROM	
	|	ParameterValues AS ParameterValues
	|
	|		LEFT JOIN AccountingPolicyOfMa AS AccountingPolicyOfMa
	|		ON AccountingPolicyOfMa.Period = ParameterValues.Period
	|			AND AccountingPolicyOfMa.Organization = ParameterValues.Organization
	|
	|		LEFT JOIN AccountingPolicyOfBU AS AccountingPolicyOfBU
	|		ON AccountingPolicyOfBU.Period = ParameterValues.Period
	|			AND AccountingPolicyOfBU.Organization = ParameterValues.Organization
	|
	|WHERE 
	|	&LineNumber = UNDEFINED 
	|		OR ParameterValues.LineNumber <= &LineNumber
	|
	|ORDER BY
	|	LineNumber
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion	
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("AccountingKind", AccountingKind);
	Query.SetParameter("LineNumber", LineNumber);
	FixedAssetDepreciationCalculation.SetQueryParametersForCalculatingDepreciation(Query);
	
	DepreciationForPeriod = 0;
	DepreciationForPeriodOfLocal = 0;
	MonthlyDepreciation = 0;
	DepreciationPerMonthLocal = 0;
	CurrentMonth = 0;
	
	Result = Query.Execute();
	SelectingRows = Result.Select();

	//@skip-check query-in-loop
	While SelectingRows.Next() Do
		
		If Month(SelectingRows.Period) <> CurrentMonth Then
			
			DepreciationForPeriod = DepreciationForPeriod + MonthlyDepreciation;
			DepreciationForPeriodOfLocal = DepreciationForPeriodOfLocal + DepreciationPerMonthLocal;
			
			MonthlyDepreciation = 0;
			DepreciationPerMonthLocal = 0;
			
			CurrentMonth = Month(SelectingRows.Period);
			
		EndIf;
		
		If LineNumber <> Undefined
			And SelectingRows.LineNumber < LineNumber Then
			
			// The calculation has already been performed, you can use the original data
			MonthlyDepreciation = MonthlyDepreciation + SelectingRows.Depreciation + SelectingRows.DepreciationUpdate;
			DepreciationPerMonthLocal = DepreciationPerMonthLocal + SelectingRows.DepreciationLocal + SelectingRows.DepreciationLocalUpdate;
			
			Continue;
		EndIf;
		
		Query.SetParameter("LineNumber", SelectingRows.LineNumber);
		Query.SetParameter("BegOfMonth", BegOfMonth(SelectingRows.Period));
		Query.SetParameter("EndOfMonth", EndOfMonth(SelectingRows.Period));
		Query.SetParameter("DepreciationForPeriod", DepreciationForPeriod);
		Query.SetParameter("DepreciationForPeriodOfLocal", DepreciationForPeriodOfLocal);
		Query.SetParameter("MonthlyDepreciation", MonthlyDepreciation);
		Query.SetParameter("DepreciationPerMonthLocal", DepreciationPerMonthLocal);
		Query.SetParameter("AccountingPolicyForFixedAssets", SelectingRows.AccountingPolicyForFixedAssets);
		Query.SetParameter("FixedAssetAccountingProcedureInLocalAccounting", SelectingRows.FixedAssetAccountingProcedureInLocalAccounting);
		Query.SetParameter("DepreciationProcedure", SelectingRows.DepreciationProcedure);
		Query.SetParameter("BeginningOfFiscalYear", SelectingRows.BeginningOfFiscalYear);
		Query.SetParameter("EndOfFiscalYear", SelectingRows.EndOfFiscalYear);
		
		#Region PreparingParameters
		QueryText = 
		"SELECT
		|	BEGINOFPERIOD(ParameterValues.Period, MONTH) AS BegOfMonth,
		|	ENDOFPERIOD(ParameterValues.Period, MONTH) AS EndOfMonth,
		|	BEGINOFPERIOD(ParameterValues.Period, DAY) AS BegOfDay,
		|	ParameterValues.Period AS Period,
		|	ParameterValues.LineNumber AS LineNumber,
		|	ParameterValues.Organization AS Organization,
		|	ParameterValues.FixedAsset AS FixedAsset,
		|	ParameterValues.DoNotCalculateDepreciation AS DoNotCalculateDepreciation,
		|	ParameterValues.ResidualValueMan AS ResidualValueMan,
		|	ParameterValues.ResidualValueLocal AS ResidualValueLocal,
		|	ParameterValues.DepreciationAccrualManagementAccounting AS DepreciationAccrualManagementAccounting,
		|	ParameterValues.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
		|	ParameterValues.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
		|	ParameterValues.DepreciationAccrualMethodManagementAccounting AS DepreciationAccrualMethodManagementAccounting,
		|	ParameterValues.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|	ParameterValues.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	ParameterValues.Cost AS Cost,
		|	ParameterValues.LocalCost AS LocalCost,
		|
		|	ParameterValues.Depreciation AS Depreciation,
		|	ParameterValues.DepreciationLocal AS DepreciationLocal,
		|	ParameterValues.DepreciationUpdate AS DepreciationUpdate,
		|	ParameterValues.DepreciationLocalUpdate AS DepreciationLocalUpdate,
		|
		|	ParameterValues.CostAtBeginningOfYear AS CostAtBeginningOfYear,
		|	ParameterValues.LocalCostAtBeginningOfYear AS LocalCostAtBeginningOfYear,
		|
		|	ParameterValues.DepreciationAsOfTheYearStart AS DepreciationAsOfTheYearStart,
		|	ParameterValues.LocalDepreciationAsOfTheYearStart AS LocalDepreciationAsOfTheYearStart,
		|
		|	ParameterValues.OutputVolume AS OutputVolume,
		|	ParameterValues.AccelerationFactor AS AccelerationFactor,
		|	ParameterValues.DepreciationAsOfThePeriodStart AS DepreciationAsOfThePeriodStart,
		|	ParameterValues.LocalDepreciationAtBeginningOfPeriod AS LocalDepreciationAtBeginningOfPeriod,
		|	ParameterValues.OutputAtBeginningOfMonth AS OutputAtBeginningOfMonth,
		|	
		|	CASE
		|		WHEN &DepreciationProcedure = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
		|			THEN ParameterValues.DateParametersWereChanged
		|		ELSE BEGINOFPERIOD(DATEADD(ParameterValues.DateParametersWereChanged, MONTH, 1), MONTH)
		|	END AS LastChangeDate
		|
		|INTO ParameterValuesForMonth
		|
		|FROM
		|	ParameterValues AS ParameterValues
		|
		|WHERE
		|	ParameterValues.Period BETWEEN &BegOfMonth AND &EndOfMonth
		|;
		|	
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ParameterValues.BegOfMonth AS BegOfMonth,
		|	ParameterValues.Period AS Period,
		|	ParameterValues.LineNumber AS LineNumber,
		|	ISNULL(MAX(ParameterValuesPrevious.Period), DATETIME(1,1,1)) AS PeriodPrevious
		|
		|INTO ParameterValuesPrevious
		|
		|FROM
		|	ParameterValuesForMonth AS ParameterValues
		|
		|		LEFT JOIN ParameterValuesForMonth AS ParameterValuesPrevious
		|		ON ParameterValuesPrevious.BegOfMonth = ParameterValues.BegOfMonth
		|			AND ParameterValuesPrevious.BegOfDay < ParameterValues.BegOfDay
		|
		|GROUP BY
		|	ParameterValues.BegOfMonth,
		|	ParameterValues.Period,
		|	ParameterValues.LineNumber
		|;
		|	
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ParameterValues.BegOfMonth AS BegOfMonth,
		|	ParameterValues.Period AS Period,
		|	ParameterValues.LineNumber AS LineNumber,
		|	ISNULL(MIN(ValuesOfParametersOfThisDay.Period), DATETIME(1,1,1)) AS PeriodFollowing
		|
		|INTO ValuesOfParametersOfThisDay
		|
		|FROM
		|	ParameterValuesForMonth AS ParameterValues
		|
		|		LEFT JOIN ParameterValuesForMonth AS ValuesOfParametersOfThisDay
		|		ON ValuesOfParametersOfThisDay.BegOfMonth = ParameterValues.BegOfMonth
		|			AND ValuesOfParametersOfThisDay.BegOfDay = ParameterValues.BegOfDay
		|			AND ValuesOfParametersOfThisDay.LineNumber > ParameterValues.LineNumber
		|
		|GROUP BY
		|	ParameterValues.BegOfMonth,
		|	ParameterValues.Period,
		|	ParameterValues.LineNumber
		|;
		|	
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ParameterValues.BegOfMonth AS BegOfMonth,
		|	ParameterValues.Period AS Period,
		|	ParameterValues.LineNumber AS LineNumber,
		|
		|	CASE
		|		WHEN ISNULL(ValuesOfParametersOfThisDay.PeriodFollowing, DATETIME(1,1,1)) <> DATETIME(1,1,1)
		|
		|			THEN 0
		|
		|		WHEN &AccountingPolicyForFixedAssets <> VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
		|				OR &DepreciationProcedure <> VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
		|
		|			THEN CASE
		|					WHEN ISNULL(ParameterValuesPrevious.PeriodPrevious, DATETIME(1,1,1)) = DATETIME(1,1,1)
		|						THEN DATEDIFF(ParameterValues.BegOfMonth, ParameterValues.EndOfMonth, DAY) + 1
		|					ELSE 0
		|				END
		|
		|		WHEN ISNULL(ParameterValuesPrevious.PeriodPrevious, DATETIME(1,1,1)) <> DATETIME(1,1,1)
		|
		|			THEN DATEDIFF(ParameterValuesPrevious.PeriodPrevious, ParameterValues.Period, DAY)
		|
		|		WHEN BEGINOFPERIOD(ParameterValues.Period, MONTH) = BEGINOFPERIOD(ParameterValues.LastChangeDate, MONTH)
		|
		|			THEN DATEDIFF(ParameterValues.LastChangeDate, ParameterValues.Period, DAY) + 1
		|
		|		ELSE DATEDIFF(ParameterValues.BegOfMonth, ParameterValues.Period, DAY) + 1
		|
		|	END AS Count
		|
		|INTO NumberOfDaysOfUse
		|
		|FROM
		|	ParameterValuesForMonth AS ParameterValues
		|
		|		LEFT JOIN ParameterValuesPrevious AS ParameterValuesPrevious
		|		ON ParameterValuesPrevious.Period = ParameterValues.Period
		|			AND ParameterValuesPrevious.LineNumber = ParameterValues.LineNumber
		|
		|		LEFT JOIN ValuesOfParametersOfThisDay AS ValuesOfParametersOfThisDay
		|		ON ValuesOfParametersOfThisDay.BegOfMonth = ParameterValues.BegOfMonth
		|			AND ValuesOfParametersOfThisDay.LineNumber = ParameterValues.LineNumber
		|;
		|	
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ParameterValues.Period AS Period,
		|	ParameterValues.LineNumber AS LineNumber,
		|	ParameterValues.Organization AS Organization,
		|	ParameterValues.FixedAsset AS FixedAsset,
		|	CAST(ParameterValues.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue,
		|
		|	&AccountingPolicyForFixedAssets = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards) AS DepreciationIsCalculatedAccordingToINTStandards,
		|	UNDEFINED AS PostingOptionForImpairedFADepreciation,
		|	&BeginningOfFiscalYear AS BeginningOfFiscalYear,
		|	&EndOfFiscalYear AS EndOfFiscalYear,
		|
		|	ParameterValues.DoNotCalculateDepreciation AS DoNotCalculateDepreciation,
		|	ParameterValues.Depreciation AS Depreciation,
		|	ParameterValues.DepreciationLocal AS DepreciationLocal,
		|
		|	ParameterValues.DepreciationUpdate AS DepreciationUpdate,
		|	ParameterValues.DepreciationLocalUpdate AS DepreciationLocalUpdate,
		|
		|	CASE
		|		WHEN &DepreciationProcedure = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
		|			THEN ParameterValues.Cost
		|					- ParameterValues.DepreciationAsOfThePeriodStart
		|					- ParameterValues.DepreciationUpdate
		|					- &DepreciationForPeriod
		|					- &MonthlyDepreciation
		|		ELSE ParameterValues.Cost
		|				- ParameterValues.DepreciationAsOfThePeriodStart
		|				- &DepreciationForPeriod
		|	END AS NetBookValue,
		|	
		|	CASE
		|		WHEN &DepreciationProcedure = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
		|			THEN ParameterValues.LocalCost
		|					- ParameterValues.LocalDepreciationAtBeginningOfPeriod
		|					- ParameterValues.DepreciationLocalUpdate
		|					- &DepreciationForPeriodOfLocal
		|					- &DepreciationPerMonthLocal
		|		ELSE ParameterValues.LocalCost
		|					- ParameterValues.LocalDepreciationAtBeginningOfPeriod
		|					- &DepreciationForPeriodOfLocal
		|	END AS NetBookValueLocal,
		|
		|	ParameterValues.ResidualValueMan AS ResidualValueMan,
		|	ParameterValues.ResidualValueLocal AS ResidualValueLocal,
		|
		|	ParameterValues.DepreciationAccrualManagementAccounting AS AccrueDepreciationOrAmortization,
		|	ParameterValues.DepreciationAccrualMethodManagementAccounting AS DepreciationMethod,
		|
		|	ParameterValues.AccelerationFactor AS AccelerationFactor,
		|	ParameterValues.LastChangeDate AS LastChangeDate,
		|
		|	FALSE AS ThisIsAnAdditionalAccrual,
		|
		// ResourceAssigned
		|	CASE 
		|		WHEN ParameterValues.DepreciationAccrualMethodManagementAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
		|			THEN ParameterValues.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|		ELSE ParameterValues.UsefulLifeForCalculatingDepreciationMonth
		|	END AS ResourceAssigned,
		|
		// LifeSpentCurrentPeriod
		|	CASE 
		|		WHEN ParameterValues.DepreciationAccrualMethodManagementAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
		|
		|			THEN CAST(CAST(NumberOfDaysOfUse.Count AS NUMBER(15,9)) / CAST(DAY(ParameterValues.EndOfMonth) AS NUMBER(15,9)) * ParameterValues.OutputVolume AS NUMBER(31,9)) 
		|	
		|		ELSE CAST(CAST(NumberOfDaysOfUse.Count AS NUMBER(15,9)) / CAST(DAY(ParameterValues.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9)) 
		|
		|	END AS LifeSpentCurrentPeriod,
		|	
		// LifeSpentPastPeriod
		|	CASE 
		|		WHEN ParameterValues.DepreciationAccrualMethodManagementAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
		|
		|			THEN ParameterValues.OutputAtBeginningOfMonth
		|
				// In the month of acceptance for accounting
		|		WHEN BEGINOFPERIOD(ParameterValues.LastChangeDate, MONTH) = ParameterValues.BegOfMonth
		|
		|			THEN CAST(0 AS NUMBER(31,9))
		|
				// In the next month after being accepted for accounting
		|		WHEN ENDOFPERIOD(ParameterValues.LastChangeDate, MONTH) = ENDOFPERIOD(DATEADD(ParameterValues.BegOfMonth, MONTH, -1), MONTH)
		|
		|			THEN CAST(CAST(DATEDIFF(ParameterValues.LastChangeDate, ENDOFPERIOD(DATEADD(ParameterValues.BegOfMonth, MONTH, -1), MONTH), DAY) + 1 AS NUMBER(15,9))
		|					/ CAST(DAY(ENDOFPERIOD(ParameterValues.LastChangeDate, MONTH)) AS NUMBER(15,9)) AS NUMBER(31,9))
		|	
				// Explanation of the formula: [number of days worked per month of acceptance] / [total days per month of acceptance] + [number of months after acceptance before the beginning of the month]
		|		ELSE
		|
		|			CAST(CAST(DATEDIFF(ParameterValues.LastChangeDate, ENDOFPERIOD(ParameterValues.LastChangeDate, MONTH), DAY) + 1 AS NUMBER(15,9))
		|					/ CAST(DAY(ENDOFPERIOD(ParameterValues.LastChangeDate, MONTH)) AS NUMBER(15,9))
		|				+ DATEDIFF(BEGINOFPERIOD(DATEADD(ParameterValues.LastChangeDate, MONTH, 1), MONTH), ParameterValues.EndOfMonth, MONTH) AS NUMBER(31,9))
		|
		|	END AS LifeSpentPastPeriod,
		|
		// CostUsedToCalculateDepreciationManag
		|	CASE 
		|		WHEN &AccountingPolicyForFixedAssets = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
		|			THEN ParameterValues.CostUsedToCalculateDepreciationManag
		|		WHEN &DepreciationProcedure = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
		|			THEN ParameterValues.Cost 
		|					- ParameterValues.DepreciationAsOfThePeriodStart
		|					- ParameterValues.DepreciationUpdate
		|					- &DepreciationForPeriod
		|		ELSE ParameterValues.Cost 
		|				- ParameterValues.DepreciationAsOfThePeriodStart
		|				- &DepreciationForPeriod
		|	END AS CostUsedToCalculateDepreciationManag,
		|	
		// CostUsedToCalculateDepreciationLocal
		|	CASE 
		|		WHEN &AccountingPolicyForFixedAssets = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
		|			THEN ParameterValues.CostUsedToCalculateDepreciationLocal
		|		WHEN &DepreciationProcedure = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
		|			THEN ParameterValues.LocalCost 
		|					- ParameterValues.LocalDepreciationAtBeginningOfPeriod
		|					- ParameterValues.DepreciationLocalUpdate
		|					- &DepreciationForPeriodOfLocal
		|		ELSE ParameterValues.LocalCost 
		|				- ParameterValues.LocalDepreciationAtBeginningOfPeriod
		|				- &DepreciationForPeriodOfLocal
		|	END AS CostUsedToCalculateDepreciationLocal,
		|	
		// CostAtBeginningOfYear
		|	ParameterValues.CostAtBeginningOfYear
		|		- ParameterValues.DepreciationAsOfTheYearStart AS CostAtBeginningOfYear,
		|	
		// LocalCostAtBeginningOfYear
		|	ParameterValues.LocalCostAtBeginningOfYear
		|		- ParameterValues.LocalDepreciationAsOfTheYearStart AS LocalCostAtBeginningOfYear,
		|
		// WorkedMonthsFullYears
		|	CASE
		|		WHEN YEAR(ParameterValues.LastChangeDate) <> YEAR(ParameterValues.BegOfMonth) THEN
		|			13 - MONTH(ParameterValues.LastChangeDate)
		|				+ 12 * (YEAR(ParameterValues.BegOfMonth) - YEAR(ParameterValues.LastChangeDate) - 1)
		|		ELSE 0
		|	END AS WorkedMonthsFullYears
		|
		|INTO VT_ListOfOSSParameters_UU
		|
		|FROM
		|	ParameterValuesForMonth AS ParameterValues
		|
		|		INNER JOIN NumberOfDaysOfUse AS NumberOfDaysOfUse
		|		ON (NumberOfDaysOfUse.Period = ParameterValues.Period)
		|			AND (NumberOfDaysOfUse.LineNumber = ParameterValues.LineNumber)
		|
		|WHERE
		|	ParameterValues.LineNumber = &LineNumber
		|";
		
		Query.Text = QueryText;
		Query.Execute();
		#EndRegion
		
		#Region DepreciationCalculation
		QueryText =
		"SELECT
		|	ListOfFA.Period AS Period,
		|	ListOfFA.LineNumber AS LineNumber,
		|
		|	ListOfFA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
		|	ListOfFA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
		|	ListOfFA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
		|	ListOfFA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
		|	&DepreciationProcedure AS DepreciationProcedure,
		|	&AccountingPolicyForFixedAssets AS AccountingProcedure,
		|
		|	CASE
		|		WHEN ListOfFA.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
		|			THEN 1
		|		ELSE 0
		|	END AS VersionOfAccrualMethod,
		|
		|	ListOfFA.DepreciationUpdate AS DepreciationUpdate,
		|	ListOfFA.DepreciationLocalUpdate AS DepreciationLocalUpdate,
		|
		|	CASE
		|		WHEN ListOfFA.DoNotCalculateDepreciation
		|
		|			THEN ListOfFA.Depreciation
		|	
		|		WHEN (ListOfFA.NetBookValue - (&AmountOfMaDepreciation)) > ListOfFA.ResidualValueMan
		|			THEN 
		|				CASE
		|					WHEN (ListOfFA.NetBookValue - (&AmountOfMaDepreciation) - ListOfFA.ResidualValueMan) < &MinimumResidualValueOfUpr
		|
		|						THEN ListOfFA.NetBookValue - ListOfFA.ResidualValueMan
		|
		|					ELSE &AmountOfMaDepreciation
		|				END
		|
		|		WHEN (ListOfFA.NetBookValue - ListOfFA.ResidualValueMan) > 0
		|			THEN (ListOfFA.NetBookValue -ListOfFA.ResidualValueMan)
		|
		|		ELSE 0
		|	END AS AmountOfUU,
		|
		|	CASE 
		|		WHEN &AccountingKind = ""MA""
		|				AND &FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|			THEN 0
		|		WHEN ListOfFA.DoNotCalculateDepreciation
		|
		|			THEN ListOfFA.DepreciationLocal
		|	
		|		WHEN (ListOfFA.NetBookValueLocal - (&AmountOfACDepreciation)) > ListOfFA.ResidualValueLocal
		|			THEN 
		|				CASE
		|					WHEN (ListOfFA.NetBookValueLocal - (&AmountOfACDepreciation) - ListOfFA.ResidualValueLocal) < &MinimumResidualValueOfRegl
		|
		|						THEN ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal
		|
		|					ELSE &AmountOfACDepreciation
		|				END
		|
		|		WHEN (ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal) > 0
		|			THEN (ListOfFA.NetBookValueLocal - ListOfFA.ResidualValueLocal)
		|
		|		ELSE 0
		|	END AS AmountAccounting
		|
		|FROM
		|	VT_ListOfOSSParameters_UU AS ListOfFA
		|
		|ORDER BY
		|	LineNumber
		|";
		
		ReplaceParametersOfRequestTextForCalculatingDepreciation(QueryText);
		
		Query.Text = QueryText;
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			
			LineDepreciation = CalculationResult2.Add();
			LineDepreciation.Period = Selection.Period;
			LineDepreciation.LineNumber = Selection.LineNumber;
			
			LineDepreciation.Depreciation = Selection.AmountOfUU;
			LineDepreciation.DepreciationLocal = Selection.AmountAccounting;
			
			MonthlyDepreciation = MonthlyDepreciation + LineDepreciation.Depreciation + Selection.DepreciationUpdate;
			DepreciationPerMonthLocal = DepreciationPerMonthLocal + LineDepreciation.DepreciationLocal + Selection.DepreciationLocalUpdate;
			
			LineDepreciation.LifeSpentPastPeriod = Selection.LifeSpentPastPeriod;
			LineDepreciation.LifeSpentCurrentPeriod = Selection.LifeSpentCurrentPeriod;
			LineDepreciation.CostUsedToCalculateDepreciationManag = Selection.CostUsedToCalculateDepreciationManag;
			LineDepreciation.CostUsedToCalculateDepreciationLocal = Selection.CostUsedToCalculateDepreciationLocal;
			LineDepreciation.DepreciationProcedure = Selection.DepreciationProcedure;
			LineDepreciation.AccountingProcedure = Selection.AccountingProcedure;
			LineDepreciation.VersionOfAccrualMethod = Selection.VersionOfAccrualMethod;
			
		EndDo;
		#EndRegion
		
		TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
		
	EndDo;
	
	Return CalculationResult2;
	
EndFunction

Procedure ReplaceParametersOfRequestTextForCalculatingDepreciation(QueryText)
	
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();

	RequestTextParameters.TextCostToCalculateDepreciation = "ListOfFA.CostUsedToCalculateDepreciationManag";
	RequestTextParameters.TextResidualValue = "ListOfFA.NetBookValue";
	RequestTextParameters.TextLiquidationValue = "ListOfFA.ResidualValueMan";
	RequestTextParameters.TextCostAtBeginningOfYear = "ListOfFA.CostAtBeginningOfYear";
	TextAmountOfDepreciationOfMa = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	
	//
	RequestTextParameters.TextCostToCalculateDepreciation = "ListOfFA.CostUsedToCalculateDepreciationLocal";
	RequestTextParameters.TextResidualValue = "ListOfFA.NetBookValueLocal";
	RequestTextParameters.TextLiquidationValue = "ListOfFA.ResidualValueLocal";
	RequestTextParameters.TextCostAtBeginningOfYear = "ListOfFA.LocalCostAtBeginningOfYear";
	TextACDepreciationAmount = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	
	QueryText = StrReplace(QueryText, "&AmountOfMaDepreciation", TextAmountOfDepreciationOfMa);
	QueryText = StrReplace(QueryText, "&AmountOfACDepreciation", TextACDepreciationAmount);
	
EndProcedure

Procedure FillInParametersForPeriodOfYY(ParametersForCalculation, Parameters)
	
	If Not Parameters.FillInUU Then
		Return;
	EndIf;
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(Parameters.TempTablesManager);
	
	ParametersForCalculation.Insert("CommissioningDateMA", '00010101');
	ParametersForCalculation.Insert("LocalCostAtBeginningOfYear", 0);
	ParametersForCalculation.Insert("CostAtBeginningOfYear", 0);
	ParametersForCalculation.Insert("LocalDepreciationAsOfTheYearStart", 0);
	ParametersForCalculation.Insert("DepreciationAsOfTheYearStart", 0);
	ParametersForCalculation.Insert("LocalDepreciationAtBeginningOfPeriod", 0);
	ParametersForCalculation.Insert("DepreciationAsOfThePeriodStart", 0);
	
	ListOfRequests = New Array;
			
	#Region UUDateTable
	QueryText = 
	"SELECT
	|	AllRegisterEntries.Date AS Date,
	|	AllRegisterEntries.Recorder AS Recorder,
	|	AllRegisterEntries.TheseAreChanges AS TheseAreChanges,
	|
	|	MIN(FollowingRegisterEntries.Date) AS NextDate
	|
	|INTO FollowingRegisterEntries
	|
	|FROM
	|	AllRegisterEntries AS AllRegisterEntries
	|
	|		INNER JOIN AllRegisterEntries AS FollowingRegisterEntries
	|		ON FollowingRegisterEntries.Date <= &EndOfMAPeriod
	|			AND FollowingRegisterEntries.TheseAreChanges
	|			AND FollowingRegisterEntries.RecordInManAccounting
	|			AND FollowingRegisterEntries.Date >= BEGINOFPERIOD(AllRegisterEntries.Date, MONTH)
	|			AND FollowingRegisterEntries.Date <= ENDOFPERIOD(AllRegisterEntries.Date, MONTH)
	|			AND (NOT AllRegisterEntries.TheseAreChanges
	|				OR FollowingRegisterEntries.Date > AllRegisterEntries.Date
	|				OR FollowingRegisterEntries.Date = AllRegisterEntries.Date
	|					AND FollowingRegisterEntries.Order >= AllRegisterEntries.Order
	|					AND FollowingRegisterEntries.Recorder > AllRegisterEntries.Recorder)
	|
	|WHERE
	|	AllRegisterEntries.Date <= &EndOfMAPeriod
	|	AND AllRegisterEntries.RecordInManAccounting
	|
	|GROUP BY
	|	AllRegisterEntries.Date,
	|	AllRegisterEntries.Recorder,
	|	AllRegisterEntries.TheseAreChanges
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllRegisterEntries.Date AS Period,
	|	AllRegisterEntries.Recorder AS Recorder,
	|	AllRegisterEntries.BusinessOperation AS BusinessOperation,
	|	AllRegisterEntries.TheseAreChanges AS TheseAreChanges,
	|	AllRegisterEntries.Order AS Order,
	|	BEGINOFPERIOD(AllRegisterEntries.Date, MONTH) AS BegOfMonth,
	|
	|	CASE 
	|		WHEN NOT AllRegisterEntries.TheseAreChanges
	|			AND &ProcedureForCalculatingManSDepreciation = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|			THEN BEGINOFPERIOD(AllRegisterEntries.Date, MONTH)
	|
	|		WHEN FollowingRegisterEntries.NextDate IS NULL
	|
	|			THEN CASE 
	|					WHEN ENDOFPERIOD(AllRegisterEntries.Date, MONTH) > &EndOfMAPeriod 
	|						THEN &EndOfMAPeriod
	|					ELSE ENDOFPERIOD(AllRegisterEntries.Date, MONTH) 
	|				END
	|
	|		WHEN BEGINOFPERIOD(FollowingRegisterEntries.NextDate, DAY) = BEGINOFPERIOD(FollowingRegisterEntries.NextDate, MONTH)
	|
	|			THEN FollowingRegisterEntries.NextDate
	|
	|		WHEN BEGINOFPERIOD(FollowingRegisterEntries.NextDate, DAY) = BEGINOFPERIOD(AllRegisterEntries.Date, DAY)
	|			AND AllRegisterEntries.TheseAreChanges
	|
	|			THEN AllRegisterEntries.Date
	|
	|		ELSE DATEADD(FollowingRegisterEntries.NextDate, DAY, -1)
	|
	|	END AS Date,
	|
	|	CASE 
	|		WHEN &ByFinancialAccountingStandards 
	|			AND &ProcedureForCalculatingManSDepreciation = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|			
	|			THEN CASE 
	|					WHEN FollowingRegisterEntries.NextDate IS NULL
	|
	|						THEN ENDOFPERIOD(AllRegisterEntries.Date, MONTH)
	|
	|					WHEN BEGINOFPERIOD(FollowingRegisterEntries.NextDate, DAY) = BEGINOFPERIOD(FollowingRegisterEntries.NextDate, MONTH)
	|
	|						THEN FollowingRegisterEntries.NextDate
	|
	|					WHEN BEGINOFPERIOD(FollowingRegisterEntries.NextDate, DAY) = BEGINOFPERIOD(AllRegisterEntries.Date, DAY)
	|						AND AllRegisterEntries.TheseAreChanges
	|
	|						THEN FollowingRegisterEntries.NextDate
	|
	|					ELSE DATEADD(FollowingRegisterEntries.NextDate, DAY, -1)
	|
	|				END
	|
	|		ELSE DATEADD(BEGINOFPERIOD(AllRegisterEntries.Date, MONTH), SECOND, -1)
	|
	|	END AS DateOfParameters
	|
	|INTO ChangesTableMA
	|
	|FROM
	|	AllRegisterEntries AS AllRegisterEntries
	|
	|		LEFT JOIN FollowingRegisterEntries AS FollowingRegisterEntries
	|		ON FollowingRegisterEntries.Date = AllRegisterEntries.Date
	|			AND FollowingRegisterEntries.Recorder = AllRegisterEntries.Recorder
	|
	|WHERE
	|	AllRegisterEntries.Date <= &EndOfMAPeriod
	|	AND AllRegisterEntries.RecordInManAccounting
	|	AND (&ProcedureForCalculatingManSDepreciation = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|		OR AllRegisterEntries.TheseAreChanges
	|		OR BEGINOFPERIOD(ISNULL(FollowingRegisterEntries.NextDate,DATETIME(1,1,1)), DAY) <> BEGINOFPERIOD(AllRegisterEntries.Date, MONTH))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Period AS Period,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	RegisterDataRegistrarRecords.BusinessOperation AS BusinessOperation,
	|	RegisterDataRegistrarRecords.DateOfParameters AS DateOfParameters,
	|	RegisterDataRegistrarRecords.TheseAreChanges AS TheseAreChanges,
	|	RegisterDataRegistrarRecords.Order AS Order,
	|	LocationOfOS_Record.Organization AS Organization
	|
	|INTO UUDateTable
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Period AS Period,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.BusinessOperation AS BusinessOperation,
	|		RegisterDataRecordingPeriod.DateOfParameters AS DateOfParameters,
	|		RegisterDataRecordingPeriod.TheseAreChanges AS TheseAreChanges,
	|		RegisterDataRecordingPeriod.Order AS Order,
	|		RegisterDataRecordingPeriod.RecordPeriod AS RecordPeriod,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			ChangesTable.Date AS Date,
	|			ChangesTable.Period AS Period,
	|			ChangesTable.Recorder AS Recorder,
	|			ChangesTable.BusinessOperation AS BusinessOperation,
	|			ChangesTable.DateOfParameters AS DateOfParameters,
	|			ChangesTable.TheseAreChanges AS TheseAreChanges,
	|			ChangesTable.Order AS Order,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			ChangesTableMA AS ChangesTable
	|
	|				LEFT JOIN LocationOfOS_Record AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= ChangesTable.DateOfParameters
	|				
	|		GROUP BY
	|			ChangesTable.Date,
	|			ChangesTable.Period,
	|			ChangesTable.Recorder,
	|			ChangesTable.BusinessOperation,
	|			ChangesTable.DateOfParameters,
	|			ChangesTable.TheseAreChanges,
	|			ChangesTable.Order
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		LEFT JOIN LocationOfOS_Record AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|				
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Period,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.BusinessOperation,
	|		RegisterDataRecordingPeriod.RecordPeriod,
	|		RegisterDataRecordingPeriod.DateOfParameters,
	|		RegisterDataRecordingPeriod.TheseAreChanges,
	|		RegisterDataRecordingPeriod.Order
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	LEFT JOIN LocationOfOS_Record AS LocationOfOS_Record
	|	ON LocationOfOS_Record.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND LocationOfOS_Record.Period = RegisterDataRegistrarRecords.RecordPeriod";
	ListOfRequests.Add(QueryText);
	#EndRegion
			
	#Region InitialInformationOfOSUU
	QueryText = 
	"SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	InitialOS_RecordInformation.CommissioningDateMA AS CommissioningDateMA,
	|	InitialOS_RecordInformation.CommissioningDateAC AS CommissioningDateAC,
	|	InitialOS_RecordInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|	InitialOS_RecordInformation.InitialCostMA AS InitialCostMA,
	|	ISNULL(AcceptanceOfACForAccounting.Ref.Date, DATETIME(1,1,1)) AS DateOfDocumentOfAcceptanceForAccountingAC,
	|	ISNULL(AcceptanceOfACForAccounting.Ref.AdjustmentModeFromPreviousDate, FALSE) AS CorrectionModeFromLastACDate,
	|	ISNULL(AcceptanceOfMAForAccounting.Ref.Date, DATETIME(1,1,1)) AS DateOfDocumentOfAcceptanceForAccountingMA,
	|	ISNULL(AcceptanceOfMAForAccounting.Ref.AdjustmentModeFromPreviousDate, FALSE) AS CorrectionModeFromLastDateMA,
	|	ISNULL(AcceptanceOfACForAccounting.CostInAccounting, 0) AS PreliminaryCostOfAC,
	|	ISNULL(AcceptanceOfMAForAccounting.CostInManagementAccounting, 0) AS PreliminaryCostOfMa
	|
	|INTO InitialInformationOfOSUU
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.Organization AS Organization,
	|		RegisterDataRecordingPeriod.RecordPeriod AS RecordPeriod,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			UUDateTable.Date AS Date,
	|			UUDateTable.Recorder AS Recorder,
	|			UUDateTable.Organization AS Organization,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			UUDateTable AS UUDateTable
	|
	|				INNER JOIN InitialOS_RecordInformation AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= UUDateTable.DateOfParameters
	|					AND RegisterDataRecordingPeriod.Organization = UUDateTable.Organization
	|				
	|		GROUP BY
	|			UUDateTable.Date,
	|			UUDateTable.Recorder,
	|			UUDateTable.Organization
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN InitialOS_RecordInformation AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|			AND RegisterDataRegistrarRecords.Organization = RegisterDataRecordingPeriod.Organization
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RecordPeriod,
	|		RegisterDataRecordingPeriod.Organization
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN InitialOS_RecordInformation AS InitialOS_RecordInformation
	|	ON InitialOS_RecordInformation.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND InitialOS_RecordInformation.Period = RegisterDataRegistrarRecords.RecordPeriod
	|		AND InitialOS_RecordInformation.Organization = RegisterDataRegistrarRecords.Organization
	|
	|	LEFT JOIN Document.FixedAssetsInitialRecognition2_4.FA AS AcceptanceOfACForAccounting
	|	ON AcceptanceOfACForAccounting.Ref = InitialOS_RecordInformation.CommissioningDocumentAC
	|		AND AcceptanceOfACForAccounting.FixedAsset = &FixedAsset
	|
	|	LEFT JOIN Document.FixedAssetsInitialRecognition2_4.FA AS AcceptanceOfMAForAccounting
	|	ON AcceptanceOfMAForAccounting.Ref = InitialOS_RecordInformation.CommissioningDocumentMA
	|		AND AcceptanceOfMAForAccounting.FixedAsset = &FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region FixedAssetsAccountingProcedureManagementAccounting
	QueryText = 
	"SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	AccountingProcedureForOSUU_Records.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization
	|
	|INTO FixedAssetsAccountingProcedureManagementAccounting
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.Organization AS Organization,
	|		RegisterDataRecordingPeriod.RecordPeriod AS RecordPeriod,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			UUDateTable.Date AS Date,
	|			UUDateTable.Recorder AS Recorder,
	|			UUDateTable.Organization AS Organization,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			UUDateTable AS UUDateTable
	|
	|				INNER JOIN AccountingProcedureForOSUU_Records AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= UUDateTable.DateOfParameters
	|					AND RegisterDataRecordingPeriod.Organization = UUDateTable.Organization
	|				
	|		GROUP BY
	|			UUDateTable.Date,
	|			UUDateTable.Recorder,
	|			UUDateTable.Organization
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN AccountingProcedureForOSUU_Records AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|			AND RegisterDataRegistrarRecords.Organization = RegisterDataRecordingPeriod.Organization
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RecordPeriod,
	|		RegisterDataRecordingPeriod.Organization
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN AccountingProcedureForOSUU_Records AS AccountingProcedureForOSUU_Records
	|	ON AccountingProcedureForOSUU_Records.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND AccountingProcedureForOSUU_Records.Period = RegisterDataRegistrarRecords.RecordPeriod
	|		AND AccountingProcedureForOSUU_Records.Organization = RegisterDataRegistrarRecords.Organization";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region FixedAssetDepreciationParametersManagementAccounting
	QueryText = 
	"SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	DepreciationParametersOSUU_Records.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	DepreciationParametersOSUU_Records.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	DepreciationParametersOSUU_Records.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	DepreciationParametersOSUU_Records.AccelerationFactor AS AccelerationFactor,
	|	DepreciationParametersOSUU_Records.DepreciationMethod AS DepreciationMethod,
	|	DepreciationParametersOSUU_Records.ResidualValueMan AS ResidualValueMan,
	|	DepreciationParametersOSUU_Records.ResidualValueLocal AS ResidualValueLocal,
	|	DepreciationParametersOSUU_Records.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	DepreciationParametersOSUU_Records.LastChangeDate AS LastChangeDate
	|
	|INTO FixedAssetDepreciationParametersManagementAccounting
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.Organization AS Organization,
	|		RegisterDataRecordingPeriod.RecordPeriod AS RecordPeriod,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			UUDateTable.Date AS Date,
	|			UUDateTable.Recorder AS Recorder,
	|			UUDateTable.Organization AS Organization,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			UUDateTable AS UUDateTable
	|
	|				INNER JOIN DepreciationParametersOSUU_Records AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= UUDateTable.DateOfParameters
	|					AND RegisterDataRecordingPeriod.Organization = UUDateTable.Organization
	|				
	|		GROUP BY
	|			UUDateTable.Date,
	|			UUDateTable.Recorder,
	|			UUDateTable.Organization
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN DepreciationParametersOSUU_Records AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|			AND RegisterDataRegistrarRecords.Organization = RegisterDataRecordingPeriod.Organization
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RecordPeriod,
	|		RegisterDataRecordingPeriod.Organization
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN DepreciationParametersOSUU_Records AS DepreciationParametersOSUU_Records
	|	ON DepreciationParametersOSUU_Records.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND DepreciationParametersOSUU_Records.Period = RegisterDataRegistrarRecords.RecordPeriod
	|		AND DepreciationParametersOSUU_Records.Organization = RegisterDataRegistrarRecords.Organization";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region FixedAssetsAccountingProcedure
	QueryText = 
	"SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	AccountingProcedureForOS_Records.RunningTimeValue AS RunningTimeValue,
	|	AccountingProcedureForOS_Records.EstimatedRunningTime AS EstimatedRunningTime
	|
	|INTO FixedAssetsAccountingProcedure
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.RecordPeriod AS RecordPeriod,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			UUDateTable.Date AS Date,
	|			UUDateTable.Recorder AS Recorder,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			UUDateTable AS UUDateTable
	|
	|				INNER JOIN AccountingProcedureForOS_Records AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= UUDateTable.DateOfParameters
	|				
	|		GROUP BY
	|			UUDateTable.Date,
	|			UUDateTable.Recorder
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN AccountingProcedureForOS_Records AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RecordPeriod
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN AccountingProcedureForOS_Records AS AccountingProcedureForOS_Records
	|	ON AccountingProcedureForOS_Records.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND AccountingProcedureForOS_Records.Period = RegisterDataRegistrarRecords.RecordPeriod";
	ListOfRequests.Add(QueryText);
	#EndRegion
			
	#Region DevelopmentOfUU
	QueryText = 
	"SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	OS_RecordGeneration.RunningTimeValue AS RunningTimeValue,
	|	OS_RecordGeneration.OutputVolume AS OutputVolume
	|
	|INTO ProductionOfOS_AtBeginningOfMonthUU
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.RunningTimeValue AS RunningTimeValue,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			UUDateTable.Date AS Date,
	|			UUDateTable.Recorder AS Recorder,
	|			RegisterDataRecordingPeriod.RunningTimeValue AS RunningTimeValue,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			UUDateTable AS UUDateTable
	|
	|				INNER JOIN OS_RecordGeneration AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period < BEGINOFPERIOD(UUDateTable.Date, MONTH)
	|				
	|		GROUP BY
	|			UUDateTable.Date,
	|			UUDateTable.Recorder,
	|			RegisterDataRecordingPeriod.RunningTimeValue
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN OS_RecordGeneration AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|			AND RegisterDataRegistrarRecords.RunningTimeValue = RegisterDataRecordingPeriod.RunningTimeValue
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RunningTimeValue
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN OS_RecordGeneration AS OS_RecordGeneration
	|	ON OS_RecordGeneration.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND OS_RecordGeneration.RunningTimeValue = RegisterDataRegistrarRecords.RunningTimeValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	RegisterDataRegistrarRecords.RunningTimeValue AS RunningTimeValue,
	|	OS_RecordGeneration.OutputVolume AS OutputVolume
	|
	|INTO ProductionOfOS_AtEndOfMonthUU
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.RunningTimeValue AS RunningTimeValue,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			UUDateTable.Date AS Date,
	|			UUDateTable.Recorder AS Recorder,
	|			RegisterDataRecordingPeriod.RunningTimeValue AS RunningTimeValue,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			UUDateTable AS UUDateTable
	|
	|				INNER JOIN OS_RecordGeneration AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= ENDOFPERIOD(UUDateTable.Date, MONTH)
	|			
	|		GROUP BY
	|			UUDateTable.Date,
	|			UUDateTable.Recorder,
	|			RegisterDataRecordingPeriod.RunningTimeValue
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN OS_RecordGeneration AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|			AND RegisterDataRegistrarRecords.RunningTimeValue = RegisterDataRecordingPeriod.RunningTimeValue
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RunningTimeValue
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN OS_RecordGeneration AS OS_RecordGeneration
	|	ON OS_RecordGeneration.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND OS_RecordGeneration.RunningTimeValue = RegisterDataRegistrarRecords.RunningTimeValue";
	ListOfRequests.Add(QueryText);
	#EndRegion
		
	#Region FinancialAccountingPolicy
	QueryText = 
	"SELECT
	|	RegisterDataRecordingPeriod.Date AS Date,
	|	RegisterDataRecordingPeriod.Recorder AS Recorder,
	|	RegisterData.FixedAssetRevaluationMethod AS FixedAssetRevaluationMethod
	|
	|INTO FinancialAccountingPolicy
	|
	|FROM
	|	(SELECT
	|		UUDateTable.Date AS Date,
	|		UUDateTable.Recorder AS Recorder,
	|		MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|	FROM
	|		UUDateTable AS UUDateTable
	|
	|			INNER JOIN InformationRegister.FinancialAccountingPolicy AS RegisterDataRecordingPeriod
	|			ON RegisterDataRecordingPeriod.Period <= UUDateTable.DateOfParameters
	|				AND RegisterDataRecordingPeriod.Organization = &ParentCompany
	|				
	|	GROUP BY
	|		UUDateTable.Date,
	|		UUDateTable.Recorder
	|
	|	) AS RegisterDataRecordingPeriod
	|
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy AS RegisterData
	|	ON RegisterData.Period = RegisterDataRecordingPeriod.RecordPeriod
	|		AND RegisterData.Organization = &ParentCompany
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CostDepreciationOfOriginalFA
	QueryText =
	"SELECT
	|	SourceAndDestinationTable.Ref AS Ref,
	|	SourceAndDestinationTable.MainMeansSource AS FixedAsset,
	|	ISNULL(CostAsOfDate.Cost, 0) AS Cost,
	|	ISNULL(CostAsOfDate.LocalCost, 0) AS LocalCost,
	|	ISNULL(CostAsOfDate.CostInTaxAccounting, 0) AS CostInTaxAccounting,
	|	ISNULL(CostAsOfDate.CostPermanentDifference, 0) AS CostPermanentDifference,
	|	ISNULL(CostAsOfDate.CostTargetFinancing, 0) AS CostTargetFinancing,
	|	ISNULL(CostAsOfDate.CostTargetFinancingPD, 0) AS CostTargetFinancingPD,
	|	ISNULL(DepreciationAsOfDate.Depreciation, 0) AS Depreciation,
	|	ISNULL(DepreciationAsOfDate.DepreciationLocal, 0) AS DepreciationLocal,
	|	ISNULL(DepreciationAsOfDate.FixedAssetDepreciationTargetFinancing, 0) AS FixedAssetDepreciationTargetFinancing,
	|	ISNULL(DepreciationAsOfDate.DepreciationPermanentDifferences, 0) AS DepreciationPermanentDifferences
	|
	|FROM
	|	SourceAndDestinationTable AS SourceAndDestinationTable
	|
	|		LEFT JOIN CostAsOfDate AS CostAsOfDate
	|		ON CostAsOfDate.Recorder = SourceAndDestinationTable.Ref
	|			AND CostAsOfDate.FixedAsset = SourceAndDestinationTable.MainMeansSource
	|
	|		LEFT JOIN DepreciationAsOfDate AS DepreciationAsOfDate
	|		ON DepreciationAsOfDate.Recorder = SourceAndDestinationTable.Ref
	|			AND DepreciationAsOfDate.FixedAsset = SourceAndDestinationTable.MainMeansSource
	|
	|WHERE
	|	SourceAndDestinationTable.MainMeansSource <> &FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region SourceAndDestinationTable
	QueryText = 
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.MainMeansSource AS MainMeansSource,
	|	Table.PrincipalMeansRecipient AS PrincipalMeansRecipient,
	|	Table.ThisIsPartialWriteOff AS ThisIsPartialWriteOff,
	|	Table.CostOfWritingOffMan AS CostOfWritingOffMan,
	|	Table.CostOfLocalTaxDeduction AS CostOfLocalTaxDeduction,
	|	Table.CostOfWritingOffPD AS CostOfWritingOffPD
	|
	|FROM
	|	SourceAndDestinationTable AS Table
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CostAtBeginningOfYear
	QueryText = 
	"SELECT
	|	FACost.Cost AS Cost,
	|	FACost.LocalCost AS LocalCost
	|FROM
	|	CostAtBeginningOfYear AS FACost";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region DepreciationAsOfTheYearStart
	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge.Depreciation AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal AS DepreciationLocal
	|FROM
	|	DepreciationAsOfTheYearStart AS FixedAssetsDepreciationCharge";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DepreciationAsOfThePeriodStart
	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge.Depreciation AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal AS DepreciationLocal
	|FROM
	|	DepreciationAsOfThePeriodStart AS FixedAssetsDepreciationCharge
	|WHERE
	|	FixedAssetsDepreciationCharge.FixedAsset = &FixedAsset";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region CommissioningDateMA
	QueryText = 
	"SELECT
	|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation.SliceLast(
	|			&Date,
	|			CorrectionDate = DATETIME(1,1,1)
	|				AND Recorder <> &Ref
	|				AND Organization = &Organization
	|				AND FixedAsset = &FixedAsset) AS InitialFixedAssetsInformation";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region SamplingParametersOfUU
	QueryText = 
	"SELECT
	|	0 AS LineNumber,
	|	TableOfDates.Recorder AS Recorder,
	|	TableOfDates.BusinessOperation AS BusinessOperation,
	|	TableOfDates.TheseAreChanges AS TheseAreChanges,
	|	&FixedAsset AS FixedAsset,
	|	TableOfDates.Date AS Date,
	|	TableOfDates.Order AS Order,
	|
	|	(NOT MergeOfFixedAssets.Ref IS NULL
	|		OR NOT SplitFixedAssets.Ref IS NULL) AS ObtainedByDisassemblyCombining,
	|
	|	CASE 
	|		WHEN NOT MergeOfFixedAssets.Ref IS NULL
	|				OR NOT SplitFixedAssets.Ref IS NULL
	|
	|			THEN 0
	|
	|		WHEN BEGINOFPERIOD(TableOfDates.Date, MONTH) = BEGINOFPERIOD(&CommissioningDateMA, MONTH)
	|
	|			THEN CASE
	|					WHEN BEGINOFPERIOD(ISNULL(CommissioningDocumentMA.IBDocumentDate, DATETIME(1,1,1)), MONTH) = BEGINOFPERIOD(&Date, MONTH)
	|						THEN ISNULL(InitialCost.PreliminaryCostMan, 0)
	|					ELSE ISNULL(InitialCost.Cost, 0)
	|				END
	|
	|		ELSE ISNULL(CostAtBeginningOfPeriod.Cost, 0)
	|
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN NOT MergeOfFixedAssets.Ref IS NULL
	|				OR NOT SplitFixedAssets.Ref IS NULL
	|
	|			THEN 0
	|
	|		WHEN BEGINOFPERIOD(TableOfDates.Date, MONTH) = BEGINOFPERIOD(&CommissioningDateAC, MONTH)
	|
	|			THEN CASE
	|					WHEN BEGINOFPERIOD(ISNULL(CommissioningDocumentAC.IBDocumentDate, DATETIME(1,1,1)), MONTH) = BEGINOFPERIOD(&Date, MONTH)
	|						THEN ISNULL(InitialCost.PreliminaryCostLocal, 0)
	|					ELSE ISNULL(InitialCost.LocalCost, 0)
	|				END
	|
	|		ELSE ISNULL(CostAtBeginningOfPeriod.LocalCost, 0)
	|
	|	END AS LocalCost,
	|
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor, 0) AS AccelerationFactor,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0) AS ResidualValueMan,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal, 0) AS ResidualValueLocal,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod, VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.EmptyRef)) AS DepreciationAccrualMethodManagementAccounting,
	|
	|	ISNULL(FixedAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization, FALSE) AS DepreciationAccrualManagementAccounting,
	|	ISNULL(FixedAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization, FALSE) AS AccrueDepreciationOrAmortization,
	|
	|	ISNULL(ProductionOfOS_AtEndOfMonthUU.OutputVolume, 0)
	|		-ISNULL(ProductionOfOS_AtBeginningOfMonthUU.OutputVolume, 0) AS OutputVolume,
	|
	|	ISNULL(ProductionOfOS_AtBeginningOfMonthUU.OutputVolume, 0) AS OutputAtBeginningOfMonth,
	|
	|	CASE
	|		WHEN &ByFinancialAccountingStandards AND &ProcedureForCalculatingManSDepreciation = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|			THEN ISNULL(FixedAssetsAccountingProcedure.EstimatedRunningTime, 0)
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits, 0)
	|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	|	ISNULL(FixedAssetsAccountingProcedure.RunningTimeValue, VALUE(Catalog.RunningTimeValues.EmptyRef)) AS RunningTimeValue,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth, 0) AS UsefulLifeForCalculatingDepreciationMonth,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, DATETIME(1,1,1)) AS DateOfDepreciationParametersChangeManagementAccounting,
	|
	|	CASE
	|		WHEN &ByFinancialAccountingStandards
	|			THEN 0
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationManag, 0)
	|	END AS CostUsedToCalculateDepreciationManag,
	|
	|	CASE
	|		WHEN &ByFinancialAccountingStandards
	|			THEN 0
	|		ELSE ISNULL(FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationLocal, 0)
	|	END AS CostUsedToCalculateDepreciationLocal,
	|	
	|	0 AS Depreciation,
	|	0 AS DepreciationLocal,
	|
	|	CASE
	|		WHEN TableOfDates.TheseAreChanges
	|				AND BEGINOFPERIOD(OS_WriteCost.RecordPeriod, MONTH) = BEGINOFPERIOD(&Date, MONTH)
	|				AND ISNULL(OS_WriteCost.PreliminaryCostMan, 0) <> 0
	|				AND VALUETYPE(TableOfDates.Recorder) IN (
	|						TYPE(Document.FixedAssetsInitialRecognition2_4),
	|						TYPE(Document.FixedAssetsCostAdditions2_4),
	|						TYPE(Document.AllocateVariancesToFixedAssetCost))
	|			THEN ISNULL(OS_WriteCost.PreliminaryCostMan, 0)
	|		WHEN TableOfDates.TheseAreChanges
	|			THEN ISNULL(OS_WriteCost.Cost, 0)
	|		ELSE 0
	|	END AS CostUpdate,
	|
	|	CASE
	|		WHEN TableOfDates.TheseAreChanges
	|				AND BEGINOFPERIOD(OS_WriteCost.RecordPeriod, MONTH) = BEGINOFPERIOD(&Date, MONTH)
	|				AND ISNULL(OS_WriteCost.PreliminaryCostLocal, 0) <> 0
	|				AND VALUETYPE(TableOfDates.Recorder) IN (
	|						TYPE(Document.FixedAssetsInitialRecognition2_4),
	|						TYPE(Document.FixedAssetsCostAdditions2_4),
	|						TYPE(Document.AllocateVariancesToFixedAssetCost))
	|			THEN ISNULL(OS_WriteCost.PreliminaryCostLocal, 0)
	|		WHEN TableOfDates.TheseAreChanges
	|			THEN ISNULL(OS_WriteCost.LocalCost, 0)
	|		ELSE 0
	|	END AS LocalCostUpdate,
	|
	|	CASE
	|		WHEN TableOfDates.TheseAreChanges
	|			THEN ISNULL(DepreciationOfOS_Records.Depreciation, 0)
	|		ELSE 0
	|	END AS DepreciationUpdate,
	|
	|	CASE
	|		WHEN TableOfDates.TheseAreChanges
	|			THEN ISNULL(DepreciationOfOS_Records.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS DepreciationLocalUpdate,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MACostAdjustment,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) AS ACCostAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) 
	|		AND Adjusting.DocumentBasis = UNDEFINED
	|		AND NOT Adjusting.DocumentBasis REFS Document.MergeOfFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.SplitFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsCostAdditions2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.AllocateVariancesToFixedAssetCost
	|		AND NOT Adjusting.DocumentBasis REFS Document.FARevaluation2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsInitialRecognition2_4 AS MADepreciationAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) 
	|		AND Adjusting.DocumentBasis = UNDEFINED
	|		AND NOT Adjusting.DocumentBasis REFS Document.MergeOfFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.SplitFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsCostAdditions2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.AllocateVariancesToFixedAssetCost
	|		AND NOT Adjusting.DocumentBasis REFS Document.FARevaluation2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsInitialRecognition2_4 AS ACDepreciationAdjustment,
	|
	|	ISNULL(Adjusting.IncludesDepreciationOfCurrentMonth, FALSE) AS IncludesDepreciationOfCurrentMonth,
	|
	|	ISNULL(Revaluation.RevaluateAtFairValue, FALSE) AS RevaluateAtFairValue,
	|	ISNULL(FinancialAccountingPolicy.FixedAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	FALSE AS DoNotCalculateDepreciation
	|
	|FROM
	|	UUDateTable AS TableOfDates
	|
	|		LEFT JOIN InitialInformationOfOSUU AS InitialFixedAssetsInformation
	|		ON InitialFixedAssetsInformation.Date = TableOfDates.Date
	|			AND InitialFixedAssetsInformation.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.Date = TableOfDates.Date
	|			AND FixedAssetsAccountingProcedureManagementAccounting.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.Date = TableOfDates.Date
	|			AND FixedAssetDepreciationParametersManagementAccounting.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Date = TableOfDates.Date
	|			AND FixedAssetsAccountingProcedure.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN ProductionOfOS_AtBeginningOfMonthUU AS ProductionOfOS_AtBeginningOfMonthUU
	|		ON ProductionOfOS_AtBeginningOfMonthUU.Date = FixedAssetsAccountingProcedure.Date
	|			AND ProductionOfOS_AtBeginningOfMonthUU.Recorder = FixedAssetsAccountingProcedure.Recorder
	|			AND ProductionOfOS_AtBeginningOfMonthUU.RunningTimeValue = FixedAssetsAccountingProcedure.RunningTimeValue
	|
	|		LEFT JOIN ProductionOfOS_AtEndOfMonthUU AS ProductionOfOS_AtEndOfMonthUU
	|		ON ProductionOfOS_AtEndOfMonthUU.Date = FixedAssetsAccountingProcedure.Date
	|			AND ProductionOfOS_AtEndOfMonthUU.Recorder = FixedAssetsAccountingProcedure.Recorder
	|			AND ProductionOfOS_AtEndOfMonthUU.RunningTimeValue = FixedAssetsAccountingProcedure.RunningTimeValue
	|
	|		LEFT JOIN CostAtBeginningOfPeriod AS CostAtBeginningOfPeriod
	|		ON CostAtBeginningOfPeriod.FixedAsset = &FixedAsset
	|
	|		LEFT JOIN InitialCost AS InitialCost
	|		ON InitialCost.FixedAsset = &FixedAsset
	|
	|		LEFT JOIN FinancialAccountingPolicy AS FinancialAccountingPolicy
	|		ON FinancialAccountingPolicy.Date = TableOfDates.Date
	|			AND FinancialAccountingPolicy.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN OS_WriteCost AS OS_WriteCost
	|		ON OS_WriteCost.Recorder = TableOfDates.Recorder
	|			AND OS_WriteCost.Period = TableOfDates.Period
	|
	|		LEFT JOIN DepreciationOfOS_Records AS DepreciationOfOS_Records
	|		ON DepreciationOfOS_Records.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|		ON Adjusting.Ref = TableOfDates.Recorder
	|
	|		LEFT JOIN Document.FARevaluation2_4 AS Revaluation
	|		ON Revaluation.Ref = TableOfDates.Recorder
	|
	|		LEFT JOIN Document.MergeOfFixedAssets AS MergeOfFixedAssets
	|		ON MergeOfFixedAssets.Ref = TableOfDates.Recorder
	|			AND MergeOfFixedAssets.FixedAsset = &FixedAsset
	|
	|		LEFT JOIN Document.SplitFixedAssets.FA AS SplitFixedAssets
	|		ON SplitFixedAssets.Ref = TableOfDates.Recorder
	|			AND SplitFixedAssets.FixedAsset = &FixedAsset
	|
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS CommissioningDocumentAC
	|		ON CommissioningDocumentAC.Ref = &CommissioningDocumentAC
	|			AND NOT CommissioningDocumentAC.AdditionalRecord
	|
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS CommissioningDocumentMA
	|		ON CommissioningDocumentMA.Ref = &CommissioningDocumentMA
	|			AND NOT CommissioningDocumentMA.AdditionalRecord
	|
	|ORDER BY
	|	Date,
	|	TheseAreChanges,
	|	Order,
	|	Recorder
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = Parameters.TempTablesManager;
	Query.SetParameter("Ref", Parameters.Ref);
	Query.SetParameter("Date", Parameters.Date);
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("ParentCompany", Parameters.ParentCompany);
	Query.SetParameter("FixedAsset", Parameters.FixedAsset);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", Parameters.EndOfPeriod);
	Query.SetParameter("EndOfMAPeriod", EndOfDay(Parameters.EndOfMAPeriod));
	Query.SetParameter("EndOfACPeriod", EndOfDay(Parameters.EndOfACPeriod));
	Query.SetParameter("ByFinancialAccountingStandards", Parameters.ByFinancialAccountingStandards);
	Query.SetParameter("ProcedureForCalculatingManSDepreciation", Parameters.ProcedureForCalculatingManSDepreciation);
	Query.SetParameter("CommissioningDateAC", Parameters.CommissioningDateAC);
	Query.SetParameter("CommissioningDateMA", Parameters.CommissioningDateMA);
	Query.SetParameter("CommissioningDocumentAC", Parameters.CommissioningDocumentAC);
	Query.SetParameter("CommissioningDocumentMA", Parameters.CommissioningDocumentMA);

	Result = Query.ExecuteBatch();
	
	SourceAndDestinationTable = Result[Result.UBound()-5].Unload();
	
	Selection = Result[Result.UBound()-4].Select();
	If Selection.Next() Then
		
		If Not Parameters.FALocalAccountingIsConductedIndependently Then
			ParametersForCalculation.LocalCostAtBeginningOfYear = Selection.LocalCost;
		EndIf;
		
		ParametersForCalculation.CostAtBeginningOfYear = Selection.Cost;
		
	Else
		
		If Not Parameters.FALocalAccountingIsConductedIndependently Then
			ParametersForCalculation.LocalCostAtBeginningOfYear = 0;
		EndIf;
		
		ParametersForCalculation.CostAtBeginningOfYear = 0;
		
	EndIf;

	Selection = Result[Result.UBound()-3].Select();
	If Selection.Next() Then
		
		If Not Parameters.FALocalAccountingIsConductedIndependently Then
			ParametersForCalculation.LocalDepreciationAsOfTheYearStart = Selection.DepreciationLocal;
		EndIf;
		
		ParametersForCalculation.DepreciationAsOfTheYearStart = Selection.Depreciation;
		
	Else
		
		If Not Parameters.FALocalAccountingIsConductedIndependently Then
			ParametersForCalculation.LocalDepreciationAsOfTheYearStart = 0;
		EndIf;
		
		ParametersForCalculation.DepreciationAsOfTheYearStart = 0;
		
	EndIf;

	Selection = Result[Result.UBound()-2].Select();
	If Selection.Next() Then
		
		If Not Parameters.FALocalAccountingIsConductedIndependently Then
			ParametersForCalculation.LocalDepreciationAtBeginningOfPeriod = Selection.DepreciationLocal;
		EndIf;
		
		ParametersForCalculation.DepreciationAsOfThePeriodStart = Selection.Depreciation;
		
	Else
		
		If Not Parameters.FALocalAccountingIsConductedIndependently Then
			ParametersForCalculation.LocalDepreciationAtBeginningOfPeriod = 0;
		EndIf;
		
		ParametersForCalculation.DepreciationAsOfThePeriodStart = 0;
		
	EndIf;
	
	Selection = Result[Result.UBound()-1].Select();
	If Selection.Next() Then
		
		ParametersForCalculation.CommissioningDateMA = Selection.CommissioningDateMA;
		
	EndIf;
	
	ParametersForMAPeriod = Result[Result.UBound()].Unload();
	
	LineNumber = 1;
	For Each RowData In ParametersForMAPeriod Do
		RowData.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("Organization", Parameters.Organization);
	CalculationParameters.Insert("FixedAsset", Parameters.FixedAsset);
	CalculationParameters.Insert("CommissioningDateMA", ParametersForCalculation.CommissioningDateMA);
	CalculationParameters.Insert("CommissioningDateAC", ParametersForCalculation.CommissioningDateMA);
	CalculationParameters.Insert("CostAtBeginningOfYear", ParametersForCalculation.CostAtBeginningOfYear);
	CalculationParameters.Insert("LocalCostAtBeginningOfYear", ParametersForCalculation.LocalCostAtBeginningOfYear);
	CalculationParameters.Insert("DepreciationAsOfTheYearStart", ParametersForCalculation.DepreciationAsOfTheYearStart);
	CalculationParameters.Insert("LocalDepreciationAsOfTheYearStart", ParametersForCalculation.LocalDepreciationAsOfTheYearStart);
	CalculationParameters.Insert("DepreciationAsOfThePeriodStart", ParametersForCalculation.DepreciationAsOfThePeriodStart);
	CalculationParameters.Insert("LocalDepreciationAtBeginningOfPeriod", ParametersForCalculation.LocalDepreciationAtBeginningOfPeriod);
	CalculationParameters.Insert("TheseAreRentedFA", LeasedAssetAccounting.FixedAssetsAreLeased(Parameters.FixedAsset, Parameters.Date));

	CalculationTables = New Structure;
	CalculationTables.Insert("ParametersForMAPeriod", ParametersForMAPeriod);

	ValuesOfParametersForCalculatingChanges = New Map;

	Selection = Result[Result.UBound()-6].Select();
	While Selection.Next() Do
		
		// The cost of the original FA during disassembly and integration
		ParameterValues = New Structure;
		ParameterValues.Insert("Cost", 0);
		ParameterValues.Insert("LocalCost", 0);
		ParameterValues.Insert("CostTargetFinancing", 0);
		ParameterValues.Insert("CostPermanentDifference", 0);
		ParameterValues.Insert("Depreciation", 0);
		ParameterValues.Insert("DepreciationLocal", 0);
		ParameterValues.Insert("FixedAssetDepreciationTargetFinancing", 0);
		ParameterValues.Insert("DepreciationPermanentDifferences", 0);
		ParameterValues.Insert("ImpairmenMan", 0);
		ParameterValues.Insert("ImpairmentLocalAssets", 0);
		ParameterValues.Insert("DepreciationForPeriodOfMan", 0);  
		ParameterValues.Insert("DepreciationForPeriodOfLocal", 0);
		ParameterValues.Insert("DepreciationForPeriodOfPD", 0);
		
		FillPropertyValues(ParameterValues, Selection);
		
		ValuesOfParametersForCalculatingChanges.Insert(Selection.FixedAsset, ParameterValues);
		
	EndDo;
	
	DepreciationForPeriodOfMan = 0;
	DepreciationForPeriodOfLocal = 0;
	
	For Each RowData In ParametersForMAPeriod Do
		
		If Not RowData.DoNotCalculateDepreciation Then
			
			RowData.Depreciation = CalculationParameters.DepreciationAsOfThePeriodStart + DepreciationForPeriodOfMan;
			RowData.DepreciationLocal = CalculationParameters.LocalDepreciationAtBeginningOfPeriod + DepreciationForPeriodOfLocal;
			
			ParameterValues = CalculateCostOfDepreciationAccordingToDocument(
				RowData, ValuesOfParametersForCalculatingChanges, SourceAndDestinationTable);
			
			RowData.Cost = ParameterValues.Cost;
			RowData.LocalCost = ParameterValues.LocalCost;
		
			RowData.DepreciationUpdate = ParameterValues.DepreciationUpdate;
			RowData.DepreciationLocalUpdate = ParameterValues.DepreciationLocalUpdate;
			
			If Not RowData.TheseAreChanges
				Or Parameters.ByFinancialAccountingStandards
					And Parameters.ProcedureForCalculatingManSDepreciation = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting Then
			
				Result = CalculateDepreciationAccordingToTable(CalculationTables, CalculationParameters, RowData.LineNumber);
				
				LineDepreciation = Result.MaCalculationResult[0];
				
				RowData.Depreciation = LineDepreciation.Depreciation;
				RowData.DepreciationLocal = LineDepreciation.DepreciationLocal;
				
			Else
				
				RowData.Depreciation = 0;
				RowData.DepreciationLocal = 0;
				
			EndIf;
		
			ParameterValues.DepreciationForPeriodOfMan = ParameterValues.DepreciationForPeriodOfMan + RowData.Depreciation;
			ParameterValues.DepreciationForPeriodOfLocal = ParameterValues.DepreciationForPeriodOfLocal + RowData.DepreciationLocal;
				
		EndIf;
		
		DepreciationForPeriodOfMan = DepreciationForPeriodOfMan + RowData.Depreciation;
		DepreciationForPeriodOfLocal = DepreciationForPeriodOfLocal + RowData.DepreciationLocal;
		
	EndDo;

	TotalingColumns = New Array;
	TotalingColumns.Add("Depreciation");
	TotalingColumns.Add("DepreciationLocal");
	TotalingColumns.Add("DepreciationUpdate");
	TotalingColumns.Add("DepreciationLocalUpdate");

	GroupParametersForPeriod(
		ParametersForMAPeriod, 
		TotalingColumns, 
		Parameters.ByFinancialAccountingStandards And Parameters.ProcedureForCalculatingManSDepreciation = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);	
	
	ParametersForCalculation.Insert("ParametersForMAPeriod", ParametersForMAPeriod);
	
	TMCommonUse.DestroyTemporaryTables(Parameters.TempTablesManager,, TTUsed);
	
EndProcedure

Procedure FillInParametersForBUPeriod(ParametersForCalculation, Parameters)
	
	If Not Parameters.FillInBU
		Or Not Parameters.FALocalAccountingIsConductedIndependently Then
		Return;
	EndIf;
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(Parameters.TempTablesManager);

	ParametersForCalculation.Insert("CommissioningDateAC", '00010101');
	ParametersForCalculation.Insert("LocalCostAtBeginningOfYear", 0);
	ParametersForCalculation.Insert("LocalDepreciationAsOfTheYearStart", 0);
	ParametersForCalculation.Insert("LocalDepreciationAtBeginningOfPeriod", 0);
	ParametersForCalculation.Insert("PermanentDifferencesInDepreciation", 0);
	ParametersForCalculation.Insert("TargetFundsInDepreciation", 0);
	ParametersForCalculation.Insert("PermanentDifferencesOfTargetFundsInDepreciation", 0);

	FSB6IsApplied = AccountingPoliciesTaxSettingsCached.FSB6IsApplied(Parameters.Organization, EndOfMonth(Parameters.EndOfPeriod));
		
	ListOfRequests = New Array;
	
	#Region BUDateTable
	QueryText = 
	"SELECT
	|	AllRegisterEntries.Date AS Date,
	|	AllRegisterEntries.Recorder AS Recorder,
	|
	|	MIN(FollowingRegisterEntries.Date) AS NextDate
	|
	|INTO FollowingRegisterEntries
	|
	|FROM
	|	AllRegisterEntries AS AllRegisterEntries
	|
	|		INNER JOIN AllRegisterEntries AS FollowingRegisterEntries
	|		ON FollowingRegisterEntries.Date <= &EndOfACPeriod
	|			AND FollowingRegisterEntries.TheseAreChanges
	|			AND FollowingRegisterEntries.PostInAccounting
	|			AND FollowingRegisterEntries.Date >= BEGINOFPERIOD(AllRegisterEntries.Date, MONTH)
	|			AND FollowingRegisterEntries.Date <= ENDOFPERIOD(AllRegisterEntries.Date, MONTH)
	|			AND (NOT AllRegisterEntries.TheseAreChanges
	|				OR FollowingRegisterEntries.Date > AllRegisterEntries.Date
	|				OR FollowingRegisterEntries.Date = AllRegisterEntries.Date
	|					AND FollowingRegisterEntries.Order >= AllRegisterEntries.Order
	|					AND FollowingRegisterEntries.Recorder > AllRegisterEntries.Recorder)
	|
	|WHERE
	|	AllRegisterEntries.Date <= &EndOfACPeriod
	|	AND AllRegisterEntries.PostInAccounting
	|
	|GROUP BY
	|	AllRegisterEntries.Date,
	|	AllRegisterEntries.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllRegisterEntries.Date AS Period,
	|	AllRegisterEntries.Recorder AS Recorder,
	|	AllRegisterEntries.BusinessOperation AS BusinessOperation,
	|	AllRegisterEntries.TheseAreChanges AS TheseAreChanges,
	|	AllRegisterEntries.Order AS Order,
	|	BEGINOFPERIOD(AllRegisterEntries.Date, MONTH) AS BegOfMonth,
	|
	|	CASE 
	|		WHEN NOT AllRegisterEntries.TheseAreChanges
	|			AND &DepreciationChargeProcedureLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|			THEN BEGINOFPERIOD(AllRegisterEntries.Date, MONTH)
	|
	|		WHEN FollowingRegisterEntries.NextDate IS NULL
	|
	|			THEN CASE 
	|					WHEN ENDOFPERIOD(AllRegisterEntries.Date, MONTH) > &EndOfACPeriod 
	|						THEN &EndOfACPeriod
	|					ELSE ENDOFPERIOD(AllRegisterEntries.Date, MONTH) 
	|				END
	|
	|		WHEN BEGINOFPERIOD(FollowingRegisterEntries.NextDate, DAY) = BEGINOFPERIOD(FollowingRegisterEntries.NextDate, MONTH)
	|
	|			THEN FollowingRegisterEntries.NextDate
	|
	|		WHEN BEGINOFPERIOD(FollowingRegisterEntries.NextDate, DAY) = BEGINOFPERIOD(AllRegisterEntries.Date, DAY)
	|			AND AllRegisterEntries.TheseAreChanges
	|
	|			THEN AllRegisterEntries.Date
	|
	|		ELSE DATEADD(FollowingRegisterEntries.NextDate, DAY, -1)
	|
	|	END AS Date,
	|
	|	CASE 
	|		WHEN NOT AllRegisterEntries.TheseAreChanges
	|			AND &DepreciationChargeProcedureLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|			THEN BEGINOFPERIOD(AllRegisterEntries.Date, MONTH)
	|
	|		WHEN &DepreciationChargeProcedureLocal = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|			
	|			THEN CASE 
	|					WHEN FollowingRegisterEntries.NextDate IS NULL
	|
	|						THEN ENDOFPERIOD(AllRegisterEntries.Date, MONTH)
	|
	|					WHEN BEGINOFPERIOD(FollowingRegisterEntries.NextDate, DAY) = BEGINOFPERIOD(FollowingRegisterEntries.NextDate, MONTH)
	|
	|						THEN FollowingRegisterEntries.NextDate
	|
	|					WHEN BEGINOFPERIOD(FollowingRegisterEntries.NextDate, DAY) = BEGINOFPERIOD(AllRegisterEntries.Date, DAY)
	|						AND AllRegisterEntries.TheseAreChanges
	|
	|						THEN FollowingRegisterEntries.NextDate
	|
	|					ELSE DATEADD(FollowingRegisterEntries.NextDate, DAY, -1)
	|
	|				END
	|
	|		ELSE DATEADD(BEGINOFPERIOD(AllRegisterEntries.Date, MONTH), SECOND, -1)
	|
	|	END AS DateOfParameters
	|
	|INTO ChangesTable
	|
	|FROM
	|	AllRegisterEntries AS AllRegisterEntries
	|
	|		LEFT JOIN FollowingRegisterEntries AS FollowingRegisterEntries
	|		ON FollowingRegisterEntries.Date = AllRegisterEntries.Date
	|			AND FollowingRegisterEntries.Recorder = AllRegisterEntries.Recorder
	|
	|WHERE
	|	AllRegisterEntries.Date <= &EndOfACPeriod
	|	AND AllRegisterEntries.PostInAccounting
	|	AND (&DepreciationChargeProcedureLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|		OR AllRegisterEntries.TheseAreChanges
	|		OR BEGINOFPERIOD(ISNULL(FollowingRegisterEntries.NextDate,DATETIME(1,1,1)), DAY) <> BEGINOFPERIOD(AllRegisterEntries.Date, MONTH))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Period AS Period,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	RegisterDataRegistrarRecords.BusinessOperation AS BusinessOperation,
	|	RegisterDataRegistrarRecords.DateOfParameters AS DateOfParameters,
	|	RegisterDataRegistrarRecords.TheseAreChanges AS TheseAreChanges,
	|	RegisterDataRegistrarRecords.Order AS Order,
	|	LocationOfOS_Record.Organization AS Organization
	|
	|INTO BUDateTable
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Period AS Period,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.BusinessOperation AS BusinessOperation,
	|		RegisterDataRecordingPeriod.DateOfParameters AS DateOfParameters,
	|		RegisterDataRecordingPeriod.TheseAreChanges AS TheseAreChanges,
	|		RegisterDataRecordingPeriod.Order AS Order,
	|		RegisterDataRecordingPeriod.RecordPeriod AS RecordPeriod,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			ChangesTable.Date AS Date,
	|			ChangesTable.Period AS Period,
	|			ChangesTable.Recorder AS Recorder,
	|			ChangesTable.BusinessOperation AS BusinessOperation,
	|			ChangesTable.DateOfParameters AS DateOfParameters,
	|			ChangesTable.TheseAreChanges AS TheseAreChanges,
	|			ChangesTable.Order AS Order,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			ChangesTable AS ChangesTable
	|
	|				LEFT JOIN LocationOfOS_Record AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= ChangesTable.DateOfParameters
	|				
	|		GROUP BY
	|			ChangesTable.Date,
	|			ChangesTable.Period,
	|			ChangesTable.Recorder,
	|			ChangesTable.BusinessOperation,
	|			ChangesTable.DateOfParameters,
	|			ChangesTable.TheseAreChanges,
	|			ChangesTable.Order
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		LEFT JOIN LocationOfOS_Record AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|				
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Period,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.BusinessOperation,
	|		RegisterDataRecordingPeriod.RecordPeriod,
	|		RegisterDataRecordingPeriod.DateOfParameters,
	|		RegisterDataRecordingPeriod.TheseAreChanges,
	|		RegisterDataRecordingPeriod.Order
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	LEFT JOIN LocationOfOS_Record AS LocationOfOS_Record
	|	ON LocationOfOS_Record.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND LocationOfOS_Record.Period = RegisterDataRegistrarRecords.RecordPeriod";
	ListOfRequests.Add(QueryText);
	#EndRegion
		
	#Region InitialFixedAssetsInformation
	QueryText = 
	"SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	InitialOS_RecordInformation.CommissioningDateAC AS CommissioningDateAC,
	|	InitialOS_RecordInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|	InitialOS_RecordInformation.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	ISNULL(AcceptanceOfACForAccounting.Ref.Date, DATETIME(1,1,1)) AS DateOfDocumentOfAcceptanceForAccounting,
	|	ISNULL(AcceptanceOfACForAccounting.Ref.AdjustmentModeFromPreviousDate, FALSE) AS AdjustmentModeFromPreviousDate,
	|	ISNULL(AcceptanceOfACForAccounting.CostInAccounting, 0) AS PreliminaryCostOfAC
	|
	|INTO InitialFixedAssetsInformation
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.Organization AS Organization,
	|		RegisterDataRecordingPeriod.RecordPeriod AS RecordPeriod,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			BUDateTable.Date AS Date,
	|			BUDateTable.Recorder AS Recorder,
	|			BUDateTable.Organization AS Organization,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			BUDateTable AS BUDateTable
	|
	|				INNER JOIN InitialOS_RecordInformation AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= BUDateTable.DateOfParameters
	|					AND RegisterDataRecordingPeriod.Organization = BUDateTable.Organization
	|				
	|		GROUP BY
	|			BUDateTable.Date,
	|			BUDateTable.Recorder,
	|			BUDateTable.Organization
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN InitialOS_RecordInformation AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|			AND RegisterDataRegistrarRecords.Organization = RegisterDataRecordingPeriod.Organization
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RecordPeriod,
	|		RegisterDataRecordingPeriod.Organization
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN InitialOS_RecordInformation AS InitialOS_RecordInformation
	|	ON InitialOS_RecordInformation.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND InitialOS_RecordInformation.Period = RegisterDataRegistrarRecords.RecordPeriod
	|		AND InitialOS_RecordInformation.Organization = RegisterDataRegistrarRecords.Organization
	|
	|	LEFT JOIN Document.FixedAssetsInitialRecognition2_4.FA AS AcceptanceOfACForAccounting
	|	ON AcceptanceOfACForAccounting.Ref = InitialOS_RecordInformation.CommissioningDocumentAC
	|		AND AcceptanceOfACForAccounting.FixedAsset = &FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region AccountingProcedureForOSBU
	QueryText = 
	"SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	AccountingProcedureForOSBU_Records.DepreciationAccrualAccounting AS DepreciationAccrualAccounting
	|
	|INTO AccountingProcedureForOSBU
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.Organization AS Organization,
	|		RegisterDataRecordingPeriod.RecordPeriod AS RecordPeriod,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			BUDateTable.Date AS Date,
	|			BUDateTable.Recorder AS Recorder,
	|			BUDateTable.Organization AS Organization,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			BUDateTable AS BUDateTable
	|
	|				INNER JOIN AccountingProcedureForOSBU_Records AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= BUDateTable.DateOfParameters
	|					AND RegisterDataRecordingPeriod.Organization = BUDateTable.Organization
	|				
	|		GROUP BY
	|			BUDateTable.Date,
	|			BUDateTable.Recorder,
	|			BUDateTable.Organization
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN AccountingProcedureForOSBU_Records AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|			AND RegisterDataRegistrarRecords.Organization = RegisterDataRecordingPeriod.Organization
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RecordPeriod,
	|		RegisterDataRecordingPeriod.Organization
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN AccountingProcedureForOSBU_Records AS AccountingProcedureForOSBU_Records
	|	ON AccountingProcedureForOSBU_Records.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND AccountingProcedureForOSBU_Records.Period = RegisterDataRegistrarRecords.RecordPeriod
	|		AND AccountingProcedureForOSBU_Records.Organization = RegisterDataRegistrarRecords.Organization";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region OSBUDepreciationParameters
	QueryText = 
	"SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	DepreciationParametersOfOSBU_Records.AccelerationFactor AS AccelerationFactor,
	|	DepreciationParametersOfOSBU_Records.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	DepreciationParametersOfOSBU_Records.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	DepreciationParametersOfOSBU_Records.AnnualDepreciationRate AS AnnualDepreciationRate,
	|	DepreciationParametersOfOSBU_Records.PermanentDifferencesUsedToCalculateDepreciation AS PermanentDifferencesUsedToCalculateDepreciation,
	|	DepreciationParametersOfOSBU_Records.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	DepreciationParametersOfOSBU_Records.DepreciationSchedule AS DepreciationSchedule,
	|	DepreciationParametersOfOSBU_Records.CostForDepreciationCalculationTargetFinancing AS CostForDepreciationCalculationTargetFinancing,
	|	DepreciationParametersOfOSBU_Records.ResidualValueMan AS ResidualValueMan,
	|	DepreciationParametersOfOSBU_Records.LastChangeDate AS LastChangeDate
	|
	|INTO OSBUDepreciationParameters
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.Organization AS Organization,
	|		RegisterDataRecordingPeriod.RecordPeriod AS RecordPeriod,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			BUDateTable.Date AS Date,
	|			BUDateTable.Recorder AS Recorder,
	|			BUDateTable.Organization AS Organization,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			BUDateTable AS BUDateTable
	|
	|				INNER JOIN DepreciationParametersOfOSBU_Records AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= BUDateTable.DateOfParameters
	|					AND RegisterDataRecordingPeriod.Organization = BUDateTable.Organization
	|				
	|		GROUP BY
	|			BUDateTable.Date,
	|			BUDateTable.Recorder,
	|			BUDateTable.Organization
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN DepreciationParametersOfOSBU_Records AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|			AND RegisterDataRegistrarRecords.Organization = RegisterDataRecordingPeriod.Organization
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RecordPeriod,
	|		RegisterDataRecordingPeriod.Organization
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN DepreciationParametersOfOSBU_Records AS DepreciationParametersOfOSBU_Records
	|	ON DepreciationParametersOfOSBU_Records.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND DepreciationParametersOfOSBU_Records.Period = RegisterDataRegistrarRecords.RecordPeriod
	|		AND DepreciationParametersOfOSBU_Records.Organization = RegisterDataRegistrarRecords.Organization";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region FixedAssetsAccountingProcedure
	QueryText = 
	"SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	AccountingProcedureForOS_Records.RunningTimeValue AS RunningTimeValue,
	|	AccountingProcedureForOS_Records.EstimatedRunningTime AS EstimatedRunningTime
	|
	|INTO FixedAssetsAccountingProcedure
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.RecordPeriod AS RecordPeriod,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			BUDateTable.Date AS Date,
	|			BUDateTable.Recorder AS Recorder,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			BUDateTable AS BUDateTable
	|
	|				INNER JOIN AccountingProcedureForOS_Records AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= BUDateTable.DateOfParameters
	|				
	|		GROUP BY
	|			BUDateTable.Date,
	|			BUDateTable.Recorder
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN AccountingProcedureForOS_Records AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RecordPeriod
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN AccountingProcedureForOS_Records AS AccountingProcedureForOS_Records
	|	ON AccountingProcedureForOS_Records.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND AccountingProcedureForOS_Records.Period = RegisterDataRegistrarRecords.RecordPeriod";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ACProduction
	QueryText = 
	"SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	OS_RecordGeneration.RunningTimeValue AS RunningTimeValue,
	|	OS_RecordGeneration.OutputVolume AS OutputVolume
	|
	|INTO ProductionOfOS_AtBeginningOfMonthBU
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.RunningTimeValue AS RunningTimeValue,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			BUDateTable.Date AS Date,
	|			BUDateTable.Recorder AS Recorder,
	|			RegisterDataRecordingPeriod.RunningTimeValue AS RunningTimeValue,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			BUDateTable AS BUDateTable
	|
	|				INNER JOIN OS_RecordGeneration AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period < BEGINOFPERIOD(BUDateTable.Date, MONTH)
	|				
	|		GROUP BY
	|			BUDateTable.Date,
	|			BUDateTable.Recorder,
	|			RegisterDataRecordingPeriod.RunningTimeValue
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN OS_RecordGeneration AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|			AND RegisterDataRegistrarRecords.RunningTimeValue = RegisterDataRecordingPeriod.RunningTimeValue
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RunningTimeValue
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN OS_RecordGeneration AS OS_RecordGeneration
	|	ON OS_RecordGeneration.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND OS_RecordGeneration.RunningTimeValue = RegisterDataRegistrarRecords.RunningTimeValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterDataRegistrarRecords.Date AS Date,
	|	RegisterDataRegistrarRecords.Recorder AS Recorder,
	|	RegisterDataRegistrarRecords.RunningTimeValue AS RunningTimeValue,
	|	OS_RecordGeneration.OutputVolume AS OutputVolume
	|
	|INTO ProductionOfOS_AtEndOfMonthBU
	|
	|FROM
	|	(SELECT
	|		RegisterDataRecordingPeriod.Date AS Date,
	|		RegisterDataRecordingPeriod.Recorder AS Recorder,
	|		RegisterDataRecordingPeriod.RunningTimeValue AS RunningTimeValue,
	|		MAX(RegisterDataRegistrarRecords.Recorder) AS LoggerRecords
	|	FROM
	|		(SELECT
	|			BUDateTable.Date AS Date,
	|			BUDateTable.Recorder AS Recorder,
	|			RegisterDataRecordingPeriod.RunningTimeValue AS RunningTimeValue,
	|			MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|		FROM
	|			BUDateTable AS BUDateTable
	|
	|				INNER JOIN OS_RecordGeneration AS RegisterDataRecordingPeriod
	|				ON RegisterDataRecordingPeriod.Period <= ENDOFPERIOD(BUDateTable.Date, MONTH)
	|			
	|		GROUP BY
	|			BUDateTable.Date,
	|			BUDateTable.Recorder,
	|			RegisterDataRecordingPeriod.RunningTimeValue
	|
	|		) AS RegisterDataRecordingPeriod
	|
	|		INNER JOIN OS_RecordGeneration AS RegisterDataRegistrarRecords
	|		ON RegisterDataRegistrarRecords.Period = RegisterDataRecordingPeriod.RecordPeriod
	|			AND RegisterDataRegistrarRecords.RunningTimeValue = RegisterDataRecordingPeriod.RunningTimeValue
	|
	|	GROUP BY
	|		RegisterDataRecordingPeriod.Date,
	|		RegisterDataRecordingPeriod.Recorder,
	|		RegisterDataRecordingPeriod.RunningTimeValue
	|
	|	) AS RegisterDataRegistrarRecords
	|
	|	INNER JOIN OS_RecordGeneration AS OS_RecordGeneration
	|	ON OS_RecordGeneration.Recorder = RegisterDataRegistrarRecords.LoggerRecords
	|		AND OS_RecordGeneration.RunningTimeValue = RegisterDataRegistrarRecords.RunningTimeValue";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region AccountingPolicyBuhAccounting
	
	QueryText = 
	"SELECT
	|	RegisterDataRecordingPeriod.Date AS Date,
	|	RegisterDataRecordingPeriod.Recorder AS Recorder,
	|	RegisterData.FixedAssetRevaluationMethod AS FixedAssetRevaluationMethod
	|
	|INTO AccountingPolicyBuhAccounting
	|
	|FROM
	|	(SELECT
	|		BUDateTable.Date AS Date,
	|		BUDateTable.Recorder AS Recorder,
	|		MAX(RegisterDataRecordingPeriod.Period) AS RecordPeriod
	|	FROM
	|		BUDateTable AS BUDateTable
	|
	|			INNER JOIN InformationRegister.FinancialAccountingPolicy AS RegisterDataRecordingPeriod
	|			ON RegisterDataRecordingPeriod.Period <= BUDateTable.DateOfParameters
	|				AND RegisterDataRecordingPeriod.Organization = &ParentCompany
	|				
	|	GROUP BY
	|		BUDateTable.Date,
	|		BUDateTable.Recorder
	|
	|	) AS RegisterDataRecordingPeriod
	|
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy AS RegisterData
	|	ON RegisterData.Period = RegisterDataRecordingPeriod.RecordPeriod
	|		AND RegisterData.Organization = &ParentCompany
	|";

	
	ListOfRequests.Add(QueryText);
	
	#EndRegion

	#Region CostDepreciationOfOriginalFA
	QueryText =
	"SELECT
	|	SourceAndDestinationTable.Ref AS Ref,
	|	SourceAndDestinationTable.MainMeansSource AS FixedAsset,
	|	ISNULL(CostAsOfDate.Cost, 0) AS Cost,
	|	ISNULL(CostAsOfDate.LocalCost, 0) AS LocalCost,
	|	ISNULL(CostAsOfDate.CostInTaxAccounting, 0) AS CostInTaxAccounting,
	|	ISNULL(CostAsOfDate.CostPermanentDifference, 0) AS CostPermanentDifference,
	|	ISNULL(CostAsOfDate.CostTargetFinancing, 0) AS CostTargetFinancing,
	|	ISNULL(CostAsOfDate.CostTargetFinancingPD, 0) AS CostTargetFinancingPD,
	|	ISNULL(DepreciationAsOfDate.Depreciation, 0) AS Depreciation,
	|	ISNULL(DepreciationAsOfDate.DepreciationLocal, 0) AS DepreciationLocal,
	|	ISNULL(DepreciationAsOfDate.FixedAssetDepreciationTargetFinancing, 0) AS FixedAssetDepreciationTargetFinancing,
	|	ISNULL(DepreciationAsOfDate.DepreciationPermanentDifferences, 0) AS DepreciationPermanentDifferences
	|
	|FROM
	|	SourceAndDestinationTable AS SourceAndDestinationTable
	|
	|		LEFT JOIN CostAsOfDate AS CostAsOfDate
	|		ON CostAsOfDate.Recorder = SourceAndDestinationTable.Ref
	|			AND CostAsOfDate.FixedAsset = SourceAndDestinationTable.MainMeansSource
	|
	|		LEFT JOIN DepreciationAsOfDate AS DepreciationAsOfDate
	|		ON DepreciationAsOfDate.Recorder = SourceAndDestinationTable.Ref
	|			AND DepreciationAsOfDate.FixedAsset = SourceAndDestinationTable.MainMeansSource
	|
	|WHERE
	|	SourceAndDestinationTable.MainMeansSource <> &FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region SourceAndDestinationTable
	QueryText = 
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.MainMeansSource AS MainMeansSource,
	|	Table.PrincipalMeansRecipient AS PrincipalMeansRecipient,
	|	Table.ThisIsPartialWriteOff AS ThisIsPartialWriteOff,
	|	Table.CostOfWritingOffMan AS CostOfWritingOffMan,
	|	Table.CostOfLocalTaxDeduction AS CostOfLocalTaxDeduction,
	|	Table.CostOfWritingOffPD AS CostOfWritingOffPD
	|
	|FROM
	|	SourceAndDestinationTable AS Table
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
		
	#Region CostAtBeginningOfYear
	QueryText = 
	"SELECT
	|	FACost.Cost AS Cost,
	|	FACost.LocalCost AS LocalCost
	|FROM
	|	CostAtBeginningOfYear AS FACost";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region DepreciationAsOfTheYearStart
	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge.DepreciationLocal AS DepreciationLocal
	|FROM
	|	DepreciationAsOfTheYearStart AS FixedAssetsDepreciationCharge";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DepreciationAsOfThePeriodStart
	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge.DepreciationLocal AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences AS DepreciationPermanentDifferences,
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD AS DepreciationTargetFinancingPD
	|FROM
	|	DepreciationAsOfThePeriodStart AS FixedAssetsDepreciationCharge
	|WHERE
	|	FixedAssetsDepreciationCharge.FixedAsset = &FixedAsset";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region CommissioningDateAC
	QueryText = 
	"SELECT
	|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation.SliceLast(
	|			&Date,
	|			CorrectionDate = DATETIME(1,1,1)
	|				AND Organization = &Organization
	|				AND FixedAsset = &FixedAsset) AS InitialFixedAssetsInformation";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region SelectionOfBUParameters
	QueryText = 
	"SELECT
	|	0 AS LineNumber,
	|	TableOfDates.Recorder AS Recorder,
	|	TableOfDates.BusinessOperation AS BusinessOperation,
	|	TableOfDates.TheseAreChanges AS TheseAreChanges,
	|	&FixedAsset AS FixedAsset,
	|	TableOfDates.Date AS Date,
	|	TableOfDates.Order AS Order,
	|
	|	(NOT MergeOfFixedAssets.Ref IS NULL
	|		OR NOT SplitFixedAssets.Ref IS NULL) AS ObtainedByDisassemblyCombining,
	|
	|	0 AS CostInAccounting,
	|
	|	CASE 
	|		WHEN NOT MergeOfFixedAssets.Ref IS NULL
	|				OR NOT SplitFixedAssets.Ref IS NULL
	|
	|			THEN 0
	|
	|		WHEN BEGINOFPERIOD(TableOfDates.Date, MONTH) = BEGINOFPERIOD(&CommissioningDateAC, MONTH)
	|
	|			THEN CASE
	|					WHEN BEGINOFPERIOD(ISNULL(CommissioningDocumentAC.IBDocumentDate, DATETIME(1,1,1)), MONTH) = BEGINOFPERIOD(&Date, MONTH)
	|						THEN ISNULL(InitialCost.PreliminaryCostLocal, 0)
	|					ELSE ISNULL(InitialCost.LocalCost, 0)
	|				END
	|
	|		ELSE ISNULL(CostAtBeginningOfPeriod.LocalCost, 0)
	|
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN NOT MergeOfFixedAssets.Ref IS NULL
	|				OR NOT SplitFixedAssets.Ref IS NULL
	|
	|			THEN 0
	|
	|		WHEN BEGINOFPERIOD(TableOfDates.Date, MONTH) = BEGINOFPERIOD(&CommissioningDateAC, MONTH)
	|
	|			THEN CASE
	|					WHEN BEGINOFPERIOD(ISNULL(CommissioningDocumentAC.IBDocumentDate, DATETIME(1,1,1)), MONTH) = BEGINOFPERIOD(&Date, MONTH)
	|						THEN ISNULL(InitialCost.PreliminaryCostPD, 0)
	|					ELSE ISNULL(InitialCost.CostPermanentDifference, 0)
	|				END
	|
	|		ELSE ISNULL(CostAtBeginningOfPeriod.CostPermanentDifference, 0)
	|
	|	END AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN NOT MergeOfFixedAssets.Ref IS NULL
	|				OR NOT SplitFixedAssets.Ref IS NULL
	|
	|			THEN 0
	|
	|		WHEN BEGINOFPERIOD(TableOfDates.Date, MONTH) = BEGINOFPERIOD(&CommissioningDateAC, MONTH)
	|
	|			THEN ISNULL(InitialCost.CostTargetFinancing, 0)
	|
	|		ELSE ISNULL(CostAtBeginningOfPeriod.CostTargetFinancing, 0)
	|
	|	END AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN NOT MergeOfFixedAssets.Ref IS NULL
	|				OR NOT SplitFixedAssets.Ref IS NULL
	|
	|			THEN 0
	|
	|		WHEN BEGINOFPERIOD(TableOfDates.Date, MONTH) = BEGINOFPERIOD(&CommissioningDateAC, MONTH)
	|
	|			THEN ISNULL(InitialCost.CostTargetFinancingPD, 0)
	|
	|		ELSE ISNULL(CostAtBeginningOfPeriod.CostTargetFinancingPD, 0)
	|
	|	END AS CostTargetFinancingPD,
	|
	|	ISNULL(OSBUDepreciationParameters.DepreciationSchedule, VALUE(Catalog.FixedAssetDepreciationSchedules.EmptyRef)) AS DepreciationSchedule,
	|	ISNULL(OSBUDepreciationParameters.AnnualDepreciationRate, 0) AS AnnualDepreciationRateAccounting,
	|	ISNULL(OSBUDepreciationParameters.AccelerationFactor, 0) AS AccelerationFactorAccounting,
	|	ISNULL(OSBUDepreciationParameters.ResidualValueMan, 0) AS ResidualValueMan,
	|	ISNULL(InitialFixedAssetsInformation.DepreciationMethodAccounting, VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.EmptyRef)) AS DepreciationMethodAccounting,
	|
	|	ISNULL(AccountingProcedureForOSBU.DepreciationAccrualAccounting, FALSE) AS AccrueDepreciationOrAmortization,
	|	ISNULL(AccountingProcedureForOSBU.DepreciationAccrualAccounting, FALSE) AS DepreciationAccrualAccounting,
	|
	|	ISNULL(ProductionOfOS_AtEndOfMonthBU.OutputVolume, 0)
	|		-ISNULL(ProductionOfOS_AtBeginningOfMonthBU.OutputVolume, 0) AS OutputVolume,
	|
	|	ISNULL(ProductionOfOS_AtBeginningOfMonthBU.OutputVolume, 0) AS OutputAtBeginningOfMonth,
	|
	|	ISNULL(OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits, 0) AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	|	ISNULL(FixedAssetsAccountingProcedure.RunningTimeValue, VALUE(Catalog.RunningTimeValues.EmptyRef)) AS RunningTimeValue,
	|
	|	ISNULL(OSBUDepreciationParameters.PermanentDifferencesUsedToCalculateDepreciation, 0) AS PermanentDifferencesUsedToCalculateDepreciation,
	|	
	|	ISNULL(OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth, 0) AS UsefulLifeForCalculatingDepreciationMonth,
	|
	|	ISNULL(OSBUDepreciationParameters.CostUsedToCalculateDepreciationManag, 0) AS CostUsedToCalculateDepreciationInAccounting,
	|	ISNULL(OSBUDepreciationParameters.CostForDepreciationCalculationTargetFinancing, 0) AS CostForDepreciationCalculationTargetFinancing,
	|	ISNULL(OSBUDepreciationParameters.LastChangeDate, DATETIME(1,1,1)) AS DateOfDepreciationParametersChangeAccounting,
	|
	|	0 AS DepreciationLocal,
	|	0 AS DepreciationInAccounting,
	|	0 AS DepreciationPermanentDifferences,
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|
	|	CASE
	|		WHEN TableOfDates.TheseAreChanges
	|				AND BEGINOFPERIOD(OS_WriteCost.RecordPeriod, MONTH) = BEGINOFPERIOD(&Date, MONTH)
	|				AND ISNULL(OS_WriteCost.PreliminaryCostLocal, 0) <> 0
	|				AND VALUETYPE(TableOfDates.Recorder) IN (
	|						TYPE(Document.FixedAssetsInitialRecognition2_4),
	|						TYPE(Document.FixedAssetsCostAdditions2_4),
	|						TYPE(Document.AllocateVariancesToFixedAssetCost))
	|			THEN ISNULL(OS_WriteCost.PreliminaryCostLocal, 0)
	|		WHEN TableOfDates.TheseAreChanges
	|			THEN ISNULL(OS_WriteCost.LocalCost, 0)
	|		ELSE 0
	|	END AS LocalCostUpdate,
	|
	|	CASE
	|		WHEN TableOfDates.TheseAreChanges
	|			THEN ISNULL(OS_WriteCost.CostPermanentDifference, 0)
	|		ELSE 0
	|	END AS CostPermanentDifferenceUpdate,
	|
	|	CASE
	|		WHEN TableOfDates.TheseAreChanges
	|			THEN ISNULL(DepreciationOfOS_Records.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS DepreciationLocalUpdate,
	|
	|	CASE
	|		WHEN TableOfDates.TheseAreChanges
	|			THEN ISNULL(DepreciationOfOS_Records.DepreciationPermanentDifferences, 0)
	|		ELSE 0
	|	END AS DepreciationPermanentDifferencesUpdate,
	|
	|	CASE
	|		WHEN TableOfDates.TheseAreChanges
	|			THEN ISNULL(DepreciationOfOS_Records.FixedAssetDepreciationTargetFinancing, 0)
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancingUpdate,
	|
	|	CASE
	|		WHEN TableOfDates.TheseAreChanges
	|			THEN ISNULL(DepreciationOfOS_Records.DepreciationTargetFinancingPD, 0)
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPDUpdate,
	|
	|	0 AS PDResidualValue,
	|	0 AS CostForCalculatingPD,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MACostAdjustment,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) AS ACCostAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) 
	|		AND Adjusting.DocumentBasis = UNDEFINED
	|		AND NOT Adjusting.DocumentBasis REFS Document.MergeOfFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.SplitFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsCostAdditions2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.AllocateVariancesToFixedAssetCost
	|		AND NOT Adjusting.DocumentBasis REFS Document.FARevaluation2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsInitialRecognition2_4 AS MADepreciationAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.PostInAccounting, FALSE) 
	|		AND Adjusting.DocumentBasis = UNDEFINED
	|		AND NOT Adjusting.DocumentBasis REFS Document.MergeOfFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.SplitFixedAssets
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsCostAdditions2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.AllocateVariancesToFixedAssetCost
	|		AND NOT Adjusting.DocumentBasis REFS Document.FARevaluation2_4
	|		AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsInitialRecognition2_4 AS ACDepreciationAdjustment,
	|
	|	ISNULL(Adjusting.IncludesDepreciationOfCurrentMonth, FALSE) AS IncludesDepreciationOfCurrentMonth,
	|
	|	ISNULL(Revaluation.RevaluateAtFairValue, FALSE) AS RevaluateAtFairValue,
	|	ISNULL(AccountingPolicyBuhAccounting.FixedAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	FALSE AS DoNotCalculateDepreciationAC
	|
	|FROM
	|	BUDateTable AS TableOfDates
	|
	|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|		ON InitialFixedAssetsInformation.Date = TableOfDates.Date
	|			AND InitialFixedAssetsInformation.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Date = TableOfDates.Date
	|			AND AccountingProcedureForOSBU.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN OSBUDepreciationParameters AS OSBUDepreciationParameters
	|		ON OSBUDepreciationParameters.Date = TableOfDates.Date
	|			AND OSBUDepreciationParameters.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Date = TableOfDates.Date
	|			AND FixedAssetsAccountingProcedure.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN ProductionOfOS_AtBeginningOfMonthBU AS ProductionOfOS_AtBeginningOfMonthBU
	|		ON ProductionOfOS_AtBeginningOfMonthBU.Date = FixedAssetsAccountingProcedure.Date
	|			AND ProductionOfOS_AtBeginningOfMonthBU.Recorder = FixedAssetsAccountingProcedure.Recorder
	|			AND ProductionOfOS_AtBeginningOfMonthBU.RunningTimeValue = FixedAssetsAccountingProcedure.RunningTimeValue
	|
	|		LEFT JOIN ProductionOfOS_AtEndOfMonthBU AS ProductionOfOS_AtEndOfMonthBU
	|		ON ProductionOfOS_AtEndOfMonthBU.Date = FixedAssetsAccountingProcedure.Date
	|			AND ProductionOfOS_AtEndOfMonthBU.Recorder = FixedAssetsAccountingProcedure.Recorder
	|			AND ProductionOfOS_AtEndOfMonthBU.RunningTimeValue = FixedAssetsAccountingProcedure.RunningTimeValue
	|
	|		LEFT JOIN CostAtBeginningOfPeriod AS CostAtBeginningOfPeriod
	|		ON CostAtBeginningOfPeriod.FixedAsset = &FixedAsset
	|
	|		LEFT JOIN InitialCost AS InitialCost
	|		ON InitialCost.FixedAsset = &FixedAsset
	|
	|		LEFT JOIN AccountingPolicyBuhAccounting AS AccountingPolicyBuhAccounting
	|		ON AccountingPolicyBuhAccounting.Date = TableOfDates.Date
	|			AND AccountingPolicyBuhAccounting.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN OS_WriteCost AS OS_WriteCost
	|		ON OS_WriteCost.Recorder = TableOfDates.Recorder
	|			AND OS_WriteCost.Period = TableOfDates.Period
	|
	|		LEFT JOIN DepreciationOfOS_Records AS DepreciationOfOS_Records
	|		ON DepreciationOfOS_Records.Recorder = TableOfDates.Recorder
	|
	|		LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|		ON Adjusting.Ref = TableOfDates.Recorder
	|
	|		LEFT JOIN Document.FARevaluation2_4 AS Revaluation
	|		ON Revaluation.Ref = TableOfDates.Recorder
	|
	|		LEFT JOIN Document.MergeOfFixedAssets AS MergeOfFixedAssets
	|		ON MergeOfFixedAssets.Ref = TableOfDates.Recorder
	|			AND MergeOfFixedAssets.FixedAsset = &FixedAsset
	|
	|		LEFT JOIN Document.SplitFixedAssets.FA AS SplitFixedAssets
	|		ON SplitFixedAssets.Ref = TableOfDates.Recorder
	|			AND SplitFixedAssets.FixedAsset = &FixedAsset
	|
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS CommissioningDocumentAC
	|		ON CommissioningDocumentAC.Ref = &CommissioningDocumentAC
	|			AND NOT CommissioningDocumentAC.AdditionalRecord
	|
	|ORDER BY
	|	Date,
	|	TheseAreChanges,
	|	Order,
	|	Recorder
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = Parameters.TempTablesManager;
	Query.SetParameter("Date", Parameters.Date);
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("ParentCompany", Parameters.ParentCompany);
	Query.SetParameter("FixedAsset", Parameters.FixedAsset);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", Parameters.EndOfPeriod);
	Query.SetParameter("EndOfACPeriod", EndOfDay(Parameters.EndOfACPeriod));
	Query.SetParameter("ByFinancialAccountingStandards", FSB6IsApplied);
	Query.SetParameter("DepreciationChargeProcedureLocal", Parameters.DepreciationChargeProcedureLocal);
	Query.SetParameter("FALocalAccountingIsConductedIndependently", True);
	Query.SetParameter("CommissioningDateAC", Parameters.CommissioningDateAC);
	Query.SetParameter("CommissioningDocumentAC", Parameters.CommissioningDocumentAC);
	
	Result = Query.ExecuteBatch();

	SourceAndDestinationTable = Result[Result.UBound()-5].Unload();
	
	Selection = Result[Result.UBound()-4].Select();
	If Selection.Next() Then
		ParametersForCalculation.LocalCostAtBeginningOfYear = Selection.LocalCost;
	Else
		ParametersForCalculation.LocalCostAtBeginningOfYear = 0;
	EndIf;

	Selection = Result[Result.UBound()-3].Select();
	If Selection.Next() Then
		ParametersForCalculation.LocalDepreciationAsOfTheYearStart = Selection.DepreciationLocal;
	Else
		ParametersForCalculation.LocalDepreciationAsOfTheYearStart = 0;
	EndIf;

	Selection = Result[Result.UBound()-2].Select();
	If Selection.Next() Then
		
		ParametersForCalculation.LocalDepreciationAtBeginningOfPeriod = Selection.DepreciationLocal;
		ParametersForCalculation.PermanentDifferencesInDepreciation = Selection.DepreciationPermanentDifferences;
		ParametersForCalculation.TargetFundsInDepreciation = Selection.FixedAssetDepreciationTargetFinancing;
		ParametersForCalculation.PermanentDifferencesOfTargetFundsInDepreciation = Selection.DepreciationTargetFinancingPD;
		
	Else
		
		ParametersForCalculation.LocalDepreciationAtBeginningOfPeriod = 0;
		ParametersForCalculation.PermanentDifferencesInDepreciation = 0;
		ParametersForCalculation.TargetFundsInDepreciation = 0;
		ParametersForCalculation.PermanentDifferencesOfTargetFundsInDepreciation = 0;
		
	EndIf;
	
	Selection = Result[Result.UBound()-1].Select();
	If Selection.Next() Then
		
		ParametersForCalculation.CommissioningDateAC = Selection.CommissioningDateAC;
		
	EndIf;
	
	FinancialDetailsForThePeriodAC = Result[Result.UBound()].Unload();
	
	LineNumber = 1;
	For Each RowData In FinancialDetailsForThePeriodAC Do
		RowData.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("Organization", Parameters.Organization);
	CalculationParameters.Insert("FixedAsset", Parameters.FixedAsset);
	CalculationParameters.Insert("CommissioningDateAC", ParametersForCalculation.CommissioningDateAC);
	CalculationParameters.Insert("CostAtBeginningOfYear", 0);
	CalculationParameters.Insert("LocalCostAtBeginningOfYear", ParametersForCalculation.LocalCostAtBeginningOfYear);
	CalculationParameters.Insert("DepreciationAsOfTheYearStart", 0);
	CalculationParameters.Insert("LocalDepreciationAsOfTheYearStart", ParametersForCalculation.LocalDepreciationAsOfTheYearStart);
	CalculationParameters.Insert("DepreciationAsOfThePeriodStart", 0);
	CalculationParameters.Insert("LocalDepreciationAtBeginningOfPeriod", ParametersForCalculation.LocalDepreciationAtBeginningOfPeriod);
	CalculationParameters.Insert("PermanentDifferencesInDepreciation", ParametersForCalculation.PermanentDifferencesInDepreciation);
	CalculationParameters.Insert("TargetFundsInDepreciation", ParametersForCalculation.TargetFundsInDepreciation);
	CalculationParameters.Insert("PermanentDifferencesOfTargetFundsInDepreciation", ParametersForCalculation.PermanentDifferencesOfTargetFundsInDepreciation);
	CalculationParameters.Insert("TheseAreRentedFA", LeasedAssetAccounting.FixedAssetsAreLeased(Parameters.FixedAsset, Parameters.Date));

	CalculationTables = New Structure;
	CalculationTables.Insert("FinancialDetailsForThePeriodAC", FinancialDetailsForThePeriodAC);
	
	ValuesOfParametersForCalculatingChanges = New Map;

	Selection = Result[Result.UBound()-6].Select();
	While Selection.Next() Do
		
		// The cost of the original FA during disassembly and integration
		ParameterValues = New Structure;
		ParameterValues.Insert("Cost", 0);
		ParameterValues.Insert("LocalCost", 0);
		ParameterValues.Insert("CostPermanentDifference", 0);
		ParameterValues.Insert("CostTargetFinancing", 0);
		ParameterValues.Insert("CostTargetFinancingPD", 0);
		ParameterValues.Insert("Depreciation", 0);
		ParameterValues.Insert("DepreciationLocal", 0);
		ParameterValues.Insert("DepreciationPermanentDifferences", 0);
		ParameterValues.Insert("FixedAssetDepreciationTargetFinancing", 0);
		ParameterValues.Insert("DepreciationTargetFinancingPD", 0);
		ParameterValues.Insert("ImpairmenMan", 0);
		ParameterValues.Insert("ImpairmentLocalAssets", 0);
		ParameterValues.Insert("DepreciationForPeriodOfMan", 0);  
		ParameterValues.Insert("DepreciationForPeriodOfLocal", 0);
		ParameterValues.Insert("DepreciationForPeriodOfPD", 0);
		ParameterValues.Insert("DepreciationForTFPeriod", 0);
		ParameterValues.Insert("DepreciationForPRTFPeriod", 0);
		
		FillPropertyValues(ParameterValues, Selection);
		
		ValuesOfParametersForCalculatingChanges.Insert(Selection.FixedAsset, ParameterValues);
		
	EndDo;
	
	DepreciationForPeriodOfLocal = 0;
	DepreciationForPeriodOfPD = 0;
	DepreciationForTFPeriod = 0;
	DepreciationForPRTFPeriod = 0;
	
	For Each RowData In FinancialDetailsForThePeriodAC Do
		
		If Not RowData.DoNotCalculateDepreciationAC Then
			
			RowData.DepreciationLocal = CalculationParameters.LocalDepreciationAtBeginningOfPeriod + DepreciationForPeriodOfLocal;
			RowData.DepreciationPermanentDifferences = CalculationParameters.PermanentDifferencesInDepreciation + DepreciationForPeriodOfPD;
			RowData.FixedAssetDepreciationTargetFinancing = CalculationParameters.TargetFundsInDepreciation + DepreciationForTFPeriod;
			RowData.DepreciationTargetFinancingPD = CalculationParameters.PermanentDifferencesOfTargetFundsInDepreciation + DepreciationForPRTFPeriod;
			
			ParameterValues = CalculateCostOfDepreciationAccordingToDocument(
				RowData, ValuesOfParametersForCalculatingChanges, SourceAndDestinationTable);
			
			RowData.LocalCost = ParameterValues.LocalCost;
			RowData.CostInAccounting = ParameterValues.LocalCost;
			RowData.CostPermanentDifference = ParameterValues.CostPermanentDifference;
			RowData.CostTargetFinancing = ParameterValues.CostTargetFinancing;
			RowData.CostTargetFinancingPD = ParameterValues.CostTargetFinancingPD;
		
			RowData.DepreciationLocalUpdate = ParameterValues.DepreciationLocalUpdate;
			
			If Not RowData.TheseAreChanges
				Or FSB6IsApplied
					And Parameters.DepreciationChargeProcedureLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting Then
					
				Result = CalculateDepreciationAccordingToTable(CalculationTables, CalculationParameters, RowData.LineNumber);
				
				LineDepreciation = Result.ResultOfCalculationOfBU[0];
				
				RowData.DepreciationInAccounting = LineDepreciation.DepreciationInAccounting;
				RowData.DepreciationLocal = LineDepreciation.DepreciationInAccounting;
				RowData.DepreciationPermanentDifferences = LineDepreciation.DepreciationPermanentDifferences;
				RowData.FixedAssetDepreciationTargetFinancing = LineDepreciation.FixedAssetDepreciationTargetFinancing;
				
			Else
				
				RowData.DepreciationInAccounting = 0;
				RowData.DepreciationLocal = 0;
				RowData.DepreciationPermanentDifferences = 0;
				RowData.FixedAssetDepreciationTargetFinancing = 0;
	
			EndIf;
			
			ParameterValues.DepreciationForPeriodOfLocal = ParameterValues.DepreciationForPeriodOfLocal + RowData.DepreciationLocal;
			ParameterValues.DepreciationForPeriodOfPD = ParameterValues.DepreciationForPeriodOfPD + RowData.DepreciationPermanentDifferences;
			ParameterValues.DepreciationForTFPeriod = ParameterValues.DepreciationForTFPeriod + RowData.FixedAssetDepreciationTargetFinancing;
			ParameterValues.DepreciationForPRTFPeriod = ParameterValues.DepreciationForPRTFPeriod + RowData.DepreciationTargetFinancingPD;
				
		EndIf;
		
		DepreciationForPeriodOfLocal = DepreciationForPeriodOfLocal + RowData.DepreciationLocal;
		DepreciationForPeriodOfPD = DepreciationForPeriodOfPD + RowData.DepreciationPermanentDifferences;
		DepreciationForTFPeriod = DepreciationForTFPeriod + RowData.FixedAssetDepreciationTargetFinancing;
		DepreciationForPRTFPeriod = DepreciationForPRTFPeriod + RowData.DepreciationTargetFinancingPD;
		
	EndDo;
	
	TotalingColumns = New Array;
	TotalingColumns.Add("DepreciationInAccounting");
	TotalingColumns.Add("DepreciationPermanentDifferences");
	TotalingColumns.Add("FixedAssetDepreciationTargetFinancing");
	TotalingColumns.Add("DepreciationLocalUpdate");
	TotalingColumns.Add("DepreciationPermanentDifferencesUpdate");
	TotalingColumns.Add("FixedAssetDepreciationTargetFinancingUpdate");
	TotalingColumns.Add("DepreciationTargetFinancingPDUpdate");
	
	GroupParametersForPeriod(
		FinancialDetailsForThePeriodAC, 
		TotalingColumns, 
		FSB6IsApplied And Parameters.DepreciationChargeProcedureLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting);	
	
	ParametersForCalculation.Insert("FinancialDetailsForThePeriodAC", FinancialDetailsForThePeriodAC);
	
	TMCommonUse.DestroyTemporaryTables(Parameters.TempTablesManager,, TTUsed);
	
EndProcedure

Procedure GroupParametersForPeriod(FinancialDetailsForThePeriod, TotalingColumns, FromDateOfRecognitionInAccounting) Export
	
	LinesToDelete = New Array;
	
	TotalRows = FinancialDetailsForThePeriod.Count();
		
	If FromDateOfRecognitionInAccounting Then
			
		// You need to leave only the last line of the day
		 
		For Cnt = 1 To TotalRows Do

			RowData = FinancialDetailsForThePeriod[Cnt - 1];
			
			If Cnt < TotalRows 
				And BegOfDay(RowData.Date) = BegOfDay(FinancialDetailsForThePeriod[Cnt].Date) Then
				
				For Each ColumnName In TotalingColumns Do
					FinancialDetailsForThePeriod[Cnt][ColumnName] = FinancialDetailsForThePeriod[Cnt][ColumnName] + RowData[ColumnName];
				EndDo;
				
				LinesToDelete.Add(RowData);
			EndIf;
			
			RowData.Date = EndOfDay(RowData.Date);
			
		EndDo;
		
	Else
			
		// You need to leave only the first line of the month 
		
		For Cnt = -TotalRows To -1 Do
			
			RowData = FinancialDetailsForThePeriod[-Cnt - 1];
			
			If Cnt < -1 
				And Month(RowData.Date) = Month(FinancialDetailsForThePeriod[-Cnt-2].Date) Then
				
				For Each ColumnName In TotalingColumns Do
					FinancialDetailsForThePeriod[-Cnt-2][ColumnName] = FinancialDetailsForThePeriod[-Cnt-2][ColumnName] + RowData[ColumnName];
				EndDo;
				
				LinesToDelete.Add(RowData);
			EndIf;
			
			RowData.Date = EndOfMonth(RowData.Date);
			
		EndDo;
		
	EndIf;
		
	For Each Item In LinesToDelete Do
		FinancialDetailsForThePeriod.Delete(Item);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
