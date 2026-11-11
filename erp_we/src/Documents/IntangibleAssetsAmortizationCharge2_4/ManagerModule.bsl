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
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("ImpairmentFA");
	
	IntangibleAssetsAmortizationChargeLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.IntangibleAssetsAmortizationCharge2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);

		QueryTextTableIntangibleAssetsAmortizationCharge(Query, QueryTexts, Registers);
		QueryTextTableIACost(Query, QueryTexts, Registers);
		QueryTextTableImpairmentFA(QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers);
		
		IntangibleAssetsAmortizationChargeLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
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
	
	Reports.StatementCalculationOfIntangibleAssetsAmortization.AddReportCommandOnIADepreciationDocument(ReportsCommands);
	
	IntangibleAssetsAmortizationChargeLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	IntangibleAssetsAmortizationChargeLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	IntangibleAssetsAmortizationChargeLocalization.AddGenerationCommands(GenerationCommands, Parameters);

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
	Presentation = StrTemplate(NStr("vi = 'Khấu hao TSCĐ vô hình %1 cho %2';
									|ru = 'Амортизация НМА %1 за %2';
									|en = 'The %1 Intangible assets — Amortization charge for %2'; fa = 'The %1 Intangible assets — Amortization charge for %2';
									|it = 'Ammortamento attività immateriali %1 per %2';
									|pl = 'Amortyzacja wartości niematerialnych %1 za %2';
									|tr = '%2 için %1 GMA amortismanı'"), Data.Number, Format(Data.Date, NStr("vi = 'ДФ=''ММММ гггг''';
																																		|ru = 'ДФ=''ММММ гггг''';
																																		|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																																		|it = 'ДФ=''ММММ гггг''';
																																		|pl = 'DF=''MMMM yyyy''';
																																		|tr = 'DF=''MMMM yyyy'''")));
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Calculates the depreciation in a given month and records it with the help of the document "amortisation of intangible assets".
//
// Parameters:
//  InitialCalculationParameters - See IntangibleAssetAmortizationCalculation.ExecutionParameters
//  
// Returns:
//  Structure - calculation result:
//  	* NumberOfProcessedData - Number -
// 		* HasErrors - Boolean - True if there are errors 
// 		* ErrorText  - String - error text
//
Function CalculateDepreciation(InitialCalculationParameters) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactions.IntangibleAssetAmortizationAccrual");
	
	CalculationParameters = Common.CopyRecursive(InitialCalculationParameters); // IntangibleAssetAmortizationCalculation.ExecutionParameters
	NonCurrentAssetsInternal.AddAccountingParametersForNonCurrentAssets(CalculationParameters);
	
	If CalculationParameters.TempTablesManager = Undefined Then
		CalculationParameters.TempTablesManager = New TempTablesManager;
		InitialCalculationParameters.TempTablesManager = CalculationParameters.TempTablesManager;
	EndIf;
	
	Try
		
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
				Catalogs.MonthEndClosingOperations.IntangibleAssetAmortizationAccrual, 
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
	|	MAX(IntangibleAssetAmortizationPackages.PackageNumber) AS PackageNumber,
	|	ISNULL(COUNT(DISTINCT IntangibleAssetAmortizationPackages.PackageNumber), 0) AS NumberOfRooms
	|FROM
	|	InformationRegister.IntangibleAssetAmortizationPackages AS IntangibleAssetAmortizationPackages
	|WHERE
	|	IntangibleAssetAmortizationPackages.Organization = &Organization
	|
	|GROUP BY
	|	IntangibleAssetAmortizationPackages.Organization";
	
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
	
	QueryText = IntangibleAssetsAmortizationChargeLocalization.RequestTextTTAccruedDepreciation();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	CASE 
		|		WHEN AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
		|			THEN VALUE(Enum.KindsOfNonCurrentAssets.RD)
		|		ELSE VALUE(Enum.KindsOfNonCurrentAssets.IA)
		|	END AS VNAView,
		|	AccruedDepreciation.CalculationPeriod AS CalculationPeriod,
		|	AccruedDepreciation.CalculationPeriod AS AccrualPeriod,
		|	AccruedDepreciation.KindOfAccountingObject AS KindOfAccountingObject,
		|	AccruedDepreciation.Organization AS Organization,
		|	ISNULL(IntangibleAssetAmortizationPackages.PackageNumber, 0) AS PackageNumber,
		|	AccruedDepreciation.Department AS Department,
		|	AccruedDepreciation.DebitBusinessUnit AS DebitBusinessUnit,
		|	AccruedDepreciation.IntangibleAsset AS IntangibleAsset,
		|	AccruedDepreciation.CGU AS CGU,
		|	AccruedDepreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	AccruedDepreciation.LineOfBusiness AS LineOfBusiness,
		|	AccruedDepreciation.CorLineOfBusiness AS CorLineOfBusiness,
		|	AccruedDepreciation.ExpenseItem AS ExpenseItem,
		|	AccruedDepreciation.DimensionOfExpenses AS DimensionOfExpenses,
		|	FALSE AS TransferExpensesToAnotherCompany,
		|	VALUE(Catalog.Companies.EmptyRef) AS CompanyRecipientOfExpenses,
		|	AccruedDepreciation.ThisIsAnAdditionalAccrual AS ThisIsAnAdditionalAccrual,
		|	AccruedDepreciation.ThisIsAdditionalChargeAccounting AS ThisIsAdditionalChargeAccounting,
		|	FALSE AS ThisIsRecordingOfDifference,
		|	FALSE AS ThisIsAdjustmentOfDepreciationForPreviousPeriod,
		|	MAX(AccruedDepreciation.LifeSpentPastPeriod) AS LifeSpentPastPeriod,
		|	MAX(AccruedDepreciation.LifeSpentCurrentPeriod) AS LifeSpentCurrentPeriod,
		|	MAX(AccruedDepreciation.LifeSpentPastPeriodAccounting) AS LifeSpentPastPeriodAccounting,
		|	MAX(AccruedDepreciation.LifeSpentCurrentPeriodAccounting) AS LifeSpentCurrentPeriodAccounting,
		|	MAX(AccruedDepreciation.CostUsedToCalculateDepreciationManag) AS CostUsedToCalculateDepreciationManag,
		|	MAX(AccruedDepreciation.CostUsedToCalculateDepreciationLocal) AS CostUsedToCalculateDepreciationLocal,
		|	MAX(AccruedDepreciation.ImpairmentBalanceLocal) AS ImpairmentBalanceLocal,
		|	MAX(AccruedDepreciation.ImpairmentBalanceMan) AS ImpairmentBalanceMan,
		|	MAX(AccruedDepreciation.AccountingProcedureMA) AS AccountingProcedureMA,
		|	MAX(AccruedDepreciation.AccountingProcedureAC) AS AccountingProcedureAC,
		|	MAX(AccruedDepreciation.ProcedureForCalculatingDepreciationOfMa) AS ProcedureForCalculatingDepreciationOfMa,
		|	MAX(AccruedDepreciation.ProcedureForCalculatingDepreciationAC) AS ProcedureForCalculatingDepreciationAC,
		|	MAX(AccruedDepreciation.PostingOptionForImpairedFADepreciation) AS PostingOptionForImpairedFADepreciation,
		|	MAX(AccruedDepreciation.DepreciationMethodVersionMA) AS DepreciationMethodVersionMA,
		|	MAX(AccruedDepreciation.DepreciationMethodVersionLA) AS DepreciationMethodVersionLA,
		|
		|	FALSE AS AccrueDepreciation,
		|
		|	&TableRowID_ AS RowID,
		|
		|	SUM(AccruedDepreciation.AmountOfUU) AS AmountOfUU,
		|	SUM(AccruedDepreciation.AmountAccounting) AS AmountAccounting,
		|
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
		|		LEFT JOIN InformationRegister.IntangibleAssetAmortizationPackages AS IntangibleAssetAmortizationPackages
		|		ON IntangibleAssetAmortizationPackages.Organization = AccruedDepreciation.Organization
		|			AND IntangibleAssetAmortizationPackages.IntangibleAsset = AccruedDepreciation.IntangibleAsset
		|
		|GROUP BY
		|	CASE 
		|		WHEN AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
		|			THEN VALUE(Enum.KindsOfNonCurrentAssets.RD)
		|		ELSE VALUE(Enum.KindsOfNonCurrentAssets.IA)
		|	END,
		|	AccruedDepreciation.CalculationPeriod,
		|	AccruedDepreciation.KindOfAccountingObject,
		|	AccruedDepreciation.Organization,
		|	AccruedDepreciation.CGU,
		|	ISNULL(IntangibleAssetAmortizationPackages.PackageNumber, 0),
		|	AccruedDepreciation.Department,
		|	AccruedDepreciation.DebitBusinessUnit,
		|	AccruedDepreciation.FinancialAccountingGroup,
		|	AccruedDepreciation.LineOfBusiness,
		|	AccruedDepreciation.CorLineOfBusiness,
		|	AccruedDepreciation.IntangibleAsset,
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
	
	FullDocumentName = "Document.IntangibleAssetsAmortizationCharge2_4";
	
	RequestHasSource = True;
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	
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
	|	DocumentDataDetails.Period AS Period,
	|	DocumentDataDetails.Number AS Number,
	|	DocumentDataDetails.Organization AS Organization
	|FROM
	|	DocumentDataDetails AS DocumentDataDetails";
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
	|	Document.IntangibleAssetsAmortizationCharge2_4 AS DocumentsList
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
	|	Document.IntangibleAssetsAmortizationCharge2_4 AS DocumentData
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
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.IntangibleAssetsAmortizationCharge2_4"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.IntangibleAssetsAmortizationCharge);
	ValuesOfHoldingParameters.Insert("SettingUp_HO", Catalogs.BusinessTransactionsSettings.IntangibleAssetsAmortizationCharge);
	ValuesOfHoldingParameters.Insert("Ap_nmaArticle", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets);

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

Function QueryTextTableIntangibleAssetsAmortizationCharge(Query, QueryTexts, Registers)

	RegisterName = "IntangibleAssetsAmortizationCharge";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	MergeRequestTexts = New Array;
	
	#Region Depreciation // Dt 91 - Ct 04.am
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	AccruedDepreciation.CalculationPeriod            AS Period,
	|	AccruedDepreciation.Organization              AS Organization,
	|	AccruedDepreciation.Department            AS Department,
	|	AccruedDepreciation.IntangibleAsset      AS IntangibleAsset,
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
	|	AccruedDepreciation.CompanyRecipientOfExpenses AS CorCompany,
	|	AccruedDepreciation.DebitBusinessUnit              AS DebitBusinessUnit,
	|	AccruedDepreciation.CorLineOfBusiness    AS CorLineOfBusiness,
	|	AccruedDepreciation.ExpenseItem                AS CorExpenseItem,
	|	AccruedDepreciation.DimensionOfExpenses             AS CorExpenditureDimension,
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
	|	AccruedDepreciation.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|
	|	AccruedDepreciation.ThisIsAnAdditionalAccrual   AS ThisIsAnAdditionalAccrual,
	|	AccruedDepreciation.ThisIsAdditionalChargeAccounting AS ThisIsAdditionalChargeAccounting,
	|
	|	AccruedDepreciation.AccountingProcedureMA    AS AccountingProcedureMA,
	|	AccruedDepreciation.AccountingProcedureAC    AS AccountingProcedureAC,
	|	
	|	AccruedDepreciation.ProcedureForCalculatingDepreciationOfMa    AS ProcedureForCalculatingDepreciationOfMa,
	|	AccruedDepreciation.ProcedureForCalculatingDepreciationAC    AS ProcedureForCalculatingDepreciationAC,
	|	AccruedDepreciation.DepreciationMethodVersionMA          AS DepreciationMethodVersionMA,
	|	AccruedDepreciation.DepreciationMethodVersionLA          AS DepreciationMethodVersionLA,
	|	
	|	AccruedDepreciation.RowID AS FinRecordID,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN VALUE(Enum.BusinessTransactions.IntangibleAssetsAmortizationChargeToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.IntangibleAssetsAmortizationCharge)
	|	END AS BusinessOperation,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsAmortizationChargeToAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsAmortizationCharge)
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
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|
	|	AND (AccruedDepreciation.AmountOfUU <> 0
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
	
	#Region ImpairmentAdjustment // Dt 02.ob - Ct 04.am
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	AccruedDepreciation.CalculationPeriod            AS Period,
	|	AccruedDepreciation.Organization              AS Organization,
	|	AccruedDepreciation.Department            AS Department,
	|	AccruedDepreciation.IntangibleAsset      AS IntangibleAsset,
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
	|	AccruedDepreciation.CompanyRecipientOfExpenses AS CorCompany,
	|	AccruedDepreciation.DebitBusinessUnit              AS DebitBusinessUnit,
	|	AccruedDepreciation.CorLineOfBusiness    AS CorLineOfBusiness,
	|	AccruedDepreciation.ExpenseItem                AS CorExpenseItem,
	|	AccruedDepreciation.DimensionOfExpenses             AS CorExpenditureDimension,
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
	|	AccruedDepreciation.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|
	|	AccruedDepreciation.ThisIsAnAdditionalAccrual   AS ThisIsAnAdditionalAccrual,
	|	AccruedDepreciation.ThisIsAdditionalChargeAccounting AS ThisIsAdditionalChargeAccounting,
	|
	|	AccruedDepreciation.AccountingProcedureMA    AS AccountingProcedureMA,
	|	AccruedDepreciation.AccountingProcedureAC    AS AccountingProcedureAC,
	|	
	|	AccruedDepreciation.ProcedureForCalculatingDepreciationOfMa    AS ProcedureForCalculatingDepreciationOfMa,
	|	AccruedDepreciation.ProcedureForCalculatingDepreciationAC    AS ProcedureForCalculatingDepreciationAC,
	|	AccruedDepreciation.DepreciationMethodVersionMA          AS DepreciationMethodVersionMA,
	|	AccruedDepreciation.DepreciationMethodVersionLA          AS DepreciationMethodVersionLA,
	|	
	|	AccruedDepreciation.RowID AS FinRecordID,
	|
	|	VALUE(Enum.BusinessTransactions.AdjustmentForIAImpairment) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.AdjustmentForIAImpairment) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|
	|	AND AccruedDepreciation.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0
	|		OR AccruedDepreciation.ImpairmentOfCF <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(MergeRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableIACost(Query, QueryTexts, Registers)

	RegisterName = "IACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	MergeRequestTexts = New Array;
	
	#Region Depreciation // Dt 91 - Ct 04.R&D
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	AccruedDepreciation.CalculationPeriod            AS Period,
	|	AccruedDepreciation.Organization              AS Organization,
	|	AccruedDepreciation.Department            AS Department,
	|	AccruedDepreciation.IntangibleAsset      AS IntangibleAsset,
	|	AccruedDepreciation.LineOfBusiness  AS LineOfBusiness,
	|	AccruedDepreciation.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	AccruedDepreciation.AmountOfUU    AS Cost,
	|	AccruedDepreciation.AmountAccounting    AS LocalCost,
	|	AccruedDepreciation.AmountFA    AS CostInTaxAccounting,
	|	AccruedDepreciation.AmountPermanentDifferences    AS CostPermanentDifference,
	|	AccruedDepreciation.AmountTemporaryDifferences    AS CostTemporaryDifference,
	|	AccruedDepreciation.CFAmount    AS CostTargetFinancing,
	|	AccruedDepreciation.SumOfNUCF  AS CostTargetFinancingTA,
	|	AccruedDepreciation.PRCFAmount  AS CostTargetFinancingPD,
	|	AccruedDepreciation.AmountOfVRCF  AS CostTargetFinancingTD,
	|
	|	AccruedDepreciation.CompanyRecipientOfExpenses AS CorCompany,
	|	AccruedDepreciation.DebitBusinessUnit              AS DebitBusinessUnit,
	|	AccruedDepreciation.CorLineOfBusiness    AS CorLineOfBusiness,
	|	AccruedDepreciation.ExpenseItem                AS CorExpenseItem,
	|	AccruedDepreciation.DimensionOfExpenses             AS CorExpenditureDimension,
	|
	|	AccruedDepreciation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	AccruedDepreciation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	AccruedDepreciation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|	AccruedDepreciation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|	AccruedDepreciation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	AccruedDepreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|
	|	AccruedDepreciation.ThisIsAnAdditionalAccrual    AS ThisIsAnAdditionalAccrual,
	|	AccruedDepreciation.ThisIsAdditionalChargeAccounting  AS ThisIsAdditionalChargeAccounting,
	|	AccruedDepreciation.AccountingProcedureMA     AS AccountingProcedureMA,
	|	
	|	AccruedDepreciation.RowID AS FinRecordID,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN VALUE(Enum.BusinessTransactions.RecogniseAsRDExpensesToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.RecogniseAsRDExpenses)
	|	END AS BusinessOperation,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.RecogniseAsRDExpensesToAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.RecogniseAsRDExpenses)
	|	END AS BusinessTransactionSetting
	|	
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|
	|	AND (AccruedDepreciation.AmountOfUU <> 0
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
	
	#Region ImpairmentAdjustment // Dt 02.ob - Ct 04.R&D
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	AccruedDepreciation.CalculationPeriod            AS Period,
	|	AccruedDepreciation.Organization              AS Organization,
	|	AccruedDepreciation.Department            AS Department,
	|	AccruedDepreciation.IntangibleAsset      AS IntangibleAsset,
	|	AccruedDepreciation.LineOfBusiness  AS LineOfBusiness,
	|	AccruedDepreciation.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	AccruedDepreciation.ImpairmentMA            AS Cost,
	|	AccruedDepreciation.ImpairmentAC            AS LocalCost,
	|	0                                               AS CostInTaxAccounting,
	|	0                                               AS CostPermanentDifference,
	|	AccruedDepreciation.ImpairmentAC            AS CostTemporaryDifference,
	|	AccruedDepreciation.ImpairmentOfCF            AS CostTargetFinancing,
	|	0                                               AS CostTargetFinancingTA,
	|	0                                               AS CostTargetFinancingPD,
	|	AccruedDepreciation.ImpairmentOfCF            AS CostTargetFinancingTD,
	|
	|	AccruedDepreciation.CompanyRecipientOfExpenses AS CorCompany,
	|	AccruedDepreciation.DebitBusinessUnit              AS DebitBusinessUnit,
	|	AccruedDepreciation.CorLineOfBusiness    AS CorLineOfBusiness,
	|	AccruedDepreciation.ExpenseItem                AS CorExpenseItem,
	|	AccruedDepreciation.DimensionOfExpenses             AS CorExpenditureDimension,
	|
	|	AccruedDepreciation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	AccruedDepreciation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	AccruedDepreciation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|	AccruedDepreciation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|	AccruedDepreciation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	AccruedDepreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|
	|	AccruedDepreciation.ThisIsAnAdditionalAccrual    AS ThisIsAnAdditionalAccrual,
	|	AccruedDepreciation.ThisIsAdditionalChargeAccounting  AS ThisIsAdditionalChargeAccounting,
	|	AccruedDepreciation.AccountingProcedureMA     AS AccountingProcedureMA,
	|	
	|	AccruedDepreciation.RowID AS FinRecordID,
	|
	|	VALUE(Enum.BusinessTransactions.AdjustmentForIAImpairment) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.AdjustmentForIAImpairment) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
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
	
	#Region ReverseImpairment // Dt 91 - Ct 04.ob (reverse)
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	AccruedDepreciation.CalculationPeriod            AS Period,
	|	AccruedDepreciation.IntangibleAsset      AS NonCurrentAsset,
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
	|			THEN CASE
	|					WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|						THEN VALUE(Enum.BusinessTransactions.ReverseImpairmentOfIAToAnotherCompany)
	|					WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|						THEN VALUE(Enum.BusinessTransactions.ReverseRAndDImpairmentToAnotherCompany)
	|				END
	|		WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseImpairmentOfIA)
	|		WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseRAndDImpairment)
	|	END AS BusinessOperation,
	|
	|	CASE 
	|		WHEN AccruedDepreciation.TransferExpensesToAnotherCompany
	|				AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN CASE
	|					WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseImpairmentOfIAToAnotherCompany)
	|					WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseRAndDImpairmentToAnotherCompany)
	|				END
	|		WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseImpairmentOfIA)
	|		WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseRAndDImpairment)
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
	|		OR AccruedDepreciation.ImpairmentOfCF <> 0)";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region ImpairmentAdjustment // Dt 04.ob - Ct 04.am
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	AccruedDepreciation.CalculationPeriod            AS Period,
	|	AccruedDepreciation.IntangibleAsset      AS NonCurrentAsset,
	|	AccruedDepreciation.Organization              AS Organization,
	|	AccruedDepreciation.Department            AS Department,
	|	AccruedDepreciation.LineOfBusiness  AS LineOfBusiness,
	|	AccruedDepreciation.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	AccruedDepreciation.CGU                     AS CGU,
	|
	|	AccruedDepreciation.RowID      AS FinRecordID,
	|
	|	VALUE(Enum.BusinessTransactions.AdjustmentForIAImpairment) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.AdjustmentForIAImpairment) AS BusinessTransactionSetting,
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

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)

	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	ListOfMergeRequests = New Array;
	
	#Region Depreciation
	QueryText =
	"SELECT
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
	|	VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsAmortizationChargeToAnotherCompany) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|	AND (AccruedDepreciation.AmountAccounting <> 0
	|		OR AccruedDepreciation.AmountPermanentDifferences <> 0
	|		OR AccruedDepreciation.AmountTemporaryDifferences <> 0
	|		OR AccruedDepreciation.AmountOfUU <> 0)
	|
	|UNION ALL
	|
	|SELECT
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
	|	VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsAmortizationChargeFromAnotherCompany) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|	AND (AccruedDepreciation.AmountAccounting <> 0
	|		OR AccruedDepreciation.AmountPermanentDifferences <> 0
	|		OR AccruedDepreciation.AmountTemporaryDifferences <> 0
	|		OR AccruedDepreciation.AmountOfUU <> 0)
	|
	|UNION ALL
	|
	|SELECT
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
	|	VALUE(Catalog.BusinessTransactionsSettings.RecogniseAsRDExpensesToAnotherCompany) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|	AND (AccruedDepreciation.AmountAccounting <> 0
	|		OR AccruedDepreciation.AmountPermanentDifferences <> 0
	|		OR AccruedDepreciation.AmountTemporaryDifferences <> 0
	|		OR AccruedDepreciation.AmountOfUU <> 0)
	|
	|UNION ALL
	|
	|SELECT
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
	|	VALUE(Catalog.BusinessTransactionsSettings.RecogniseAsRDExpensesFromAnotherCompany) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
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
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseImpairmentOfIAToAnotherCompany) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|
	|	AND AccruedDepreciation.PostingOptionForImpairedFADepreciation = &ReverseImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0)
	|
	|UNION ALL
	|
	|SELECT
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
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseImpairmentOfIAFromAnotherCompany) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|
	|	AND AccruedDepreciation.PostingOptionForImpairedFADepreciation = &ReverseImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0)
	|
	|UNION ALL
	|
	|SELECT
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
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseRAndDImpairmentToAnotherCompany) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|
	|	AND AccruedDepreciation.PostingOptionForImpairedFADepreciation = &ReverseImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0)
	|
	|UNION ALL
	|
	|SELECT
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
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseRAndDImpairmentFromAnotherCompany) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS AccruedDepreciation
	|		ON AccruedDepreciation.Organization = DocumentData.Organization
	|			AND AccruedDepreciation.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	AccruedDepreciation.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|	AND AccruedDepreciation.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|
	|	AND AccruedDepreciation.PostingOptionForImpairedFADepreciation = &ReverseImpairmentAdjustment
	|
	|	AND (AccruedDepreciation.ImpairmentMA <> 0
	|		OR AccruedDepreciation.ImpairmentAC <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	MergeRequestTexts = New Array;
	
	#Region ReverseImpairment // Dt 91 - Ct 04.ob (reverse)
	QueryText =
	"SELECT
	|	AccruedDepreciation.CalculationPeriod AS Period,
	|	AccruedDepreciation.Organization AS Organization,
	|
	|	AccruedDepreciation.Department AS Department,
	|	AccruedDepreciation.LineOfBusiness AS LineOfBusiness,
	|	&Ap_nmaArticle AS AssetRef,
	|	AccruedDepreciation.IntangibleAsset AS AssetsLiabilitiesDimension,
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
	|			THEN CASE
	|					WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|						THEN VALUE(Enum.BusinessTransactions.ReverseImpairmentOfIAToAnotherCompany)
	|					WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|						THEN VALUE(Enum.BusinessTransactions.ReverseRAndDImpairmentToAnotherCompany)
	|				END
	|		WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseImpairmentOfIA)
	|		WHEN AccruedDepreciation.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseRAndDImpairment)
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
	|		OR AccruedDepreciation.ImpairmentOfCF <> 0)";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region ImpairmentAdjustment // Dt 04.ob - Ct 04.am
	QueryText =
	"SELECT
	|	AccruedDepreciation.CalculationPeriod AS Period,
	|	AccruedDepreciation.Organization AS Organization,
	|
	|	AccruedDepreciation.Department AS Department,
	|	AccruedDepreciation.LineOfBusiness AS LineOfBusiness,
	|	&Ap_nmaArticle AS AssetRef,
	|	AccruedDepreciation.IntangibleAsset AS AssetsLiabilitiesDimension,
	|	AccruedDepreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	AccruedDepreciation.Department AS DebitBusinessUnit,
	|	AccruedDepreciation.LineOfBusiness AS CorLineOfBusiness,
	|	&Ap_nmaArticle AS CorItem,
	|	UNDEFINED AS CorExpenditureDimension,
	|	AccruedDepreciation.IntangibleAsset AS CorDimensionOfAssetsLiabilities,
	|	AccruedDepreciation.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	AccruedDepreciation.ImpairmentMA AS Sum,
	|	AccruedDepreciation.ImpairmentMA AS SumMan,
	|	AccruedDepreciation.ImpairmentAC + AccruedDepreciation.ImpairmentOfCF AS SumCompl,
	|
	|	VALUE(Enum.BusinessTransactions.AdjustmentForIAImpairment) AS BusinessOperation
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
	QueryTexts.Add(QueryText, RegisterName, True);
	
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
	|	Document.IntangibleAssetsAmortizationCharge2_4 AS DocumentData
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

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return IntangibleAssetsAmortizationChargeLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return IntangibleAssetsAmortizationChargeLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region DepreciationCalculation

Procedure PrepareParametersForDepreciationCalculation(CalculationParameters)

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("IntangibleAssetsAmortizationCharge.CalculateDepreciation.PrepareParameters");
	
	ListOfRequests = New Array;

	QueryTextTTDataToBeCalculated(ListOfRequests);
	QueryTextListOfAllIA(ListOfRequests, CalculationParameters);
	QueryTextListOfAccountingObjects(ListOfRequests, CalculationParameters);
	
	QueryTextDepreciationCalculationParameters(ListOfRequests, CalculationParameters);
	QueryTextCheckingCalculationParameters(ListOfRequests, CalculationParameters);
	QueryTextNumberOfCalculationParameters(ListOfRequests, CalculationParameters);

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());

	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	IntangibleAssetAmortizationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	
	Query.SetParameter("Date", EndOfMonth(CalculationParameters.Period));
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());

	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);

	Selection = QueryResult.Select();
	Selection.Next();
	DataVolume = Selection.DataVolume;

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);

EndProcedure

Procedure PerformDepreciationCalculation(CalculationParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("IntangibleAssetsAmortizationCharge.CalculateDepreciation.PerformTheCalculation");

	IntangibleAssetsAmortizationChargeLocalization.PerformDepreciationCalculation(CalculationParameters);

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
	IntangibleAssetAmortizationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	Query.Execute();
	
EndProcedure

Procedure CheckCalculationResults(CalculationParameters)

	IntangibleAssetsAmortizationChargeLocalization.CheckCalculationResults(CalculationParameters);

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
	|		DepreciationCalculation.IntangibleAsset AS AccountingObject,
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
	|		DepreciationCalculation.IntangibleAsset AS AccountingObject,
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

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("IntangibleAssetsAmortizationCharge.CalculateDepreciation.RegisterErrors");

	CalculationParameters.TablesToUse = CalculationParameters.TablesToUse + "," + "PackageNumbersWithErrors";
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(CalculationParameters.TempTablesManager);
	TTUsed.Add("PackageNumbersWithErrors");

	QueryText = IntangibleAssetsAmortizationChargeLocalization.QueryTextRegisterDepreciationCalculationErrors(CalculationParameters);
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	CheckingCalculationParameters.Organization AS Organization,
		|	CheckingCalculationParameters.AccountingObject AS AccountingObject,
		|	MAX(CheckingCalculationParameters.AmountOfOperatingTimeIsNotSpecified) AS AmountOfOperatingTimeIsNotSpecified,
		|	MAX(CheckingCalculationParameters.MAExpenseItemIsNotSpecified) AS MAExpenseItemIsNotSpecified,
		|	MAX(CheckingCalculationParameters.ACExpenseItemIsNotSpecified) AS ACExpenseItemIsNotSpecified
		|
		|INTO CheckingCalculationParameters
		|
		|FROM
		|	(SELECT
		|		CheckingCalculationParameters.Organization AS Organization,
		|		CheckingCalculationParameters.AccountingObject AS AccountingObject,
		|		CheckingCalculationParameters.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
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
		|		CheckingCalculationParameters.Organization,
		|		CheckingCalculationParameters.AccountingObject,
		|		CheckingCalculationParameters.AmountOfOperatingTimeIsNotSpecified,
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
		|		CheckingCalculation.Organization,
		|		CheckingCalculation.AccountingObject,
		|		FALSE,
		|		CheckingCalculation.ExpenseItemNotSpecified AS MAExpenseItemIsNotSpecified,
		|		FALSE AS ACExpenseItemIsNotSpecified
		|	FROM
		|		CheckingCalculationOf_Y AS CheckingCalculation
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CheckingCalculation.Organization,
		|		CheckingCalculation.AccountingObject,
		|		FALSE,
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
		|SELECT DISTINCT
		|	DepreciationPackages.Organization AS Organization,
		|	DepreciationPackages.PackageNumber AS PackageNumber
		|
		|INTO PackageNumbersWithErrors
		|
		|FROM
		|	CheckingCalculationParameters AS CheckingCalculationParameters
		|
		|			INNER JOIN InformationRegister.IntangibleAssetAmortizationPackages AS DepreciationPackages
		|			ON DepreciationPackages.Organization = CheckingCalculationParameters.Organization
		|				AND DepreciationPackages.IntangibleAsset = CheckingCalculationParameters.AccountingObject
		|
		|INDEX BY
		|	Organization,
		|	PackageNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CheckingCalculationParameters.Organization AS Organization,
		|	CheckingCalculationParameters.AccountingObject AS AccountingObject,
		|	CAST(CheckingCalculationParameters.AccountingObject AS Catalog.IntangibleAssets).Description AS AccountingObjectPresentation,
		|	CAST(CheckingCalculationParameters.AccountingObject AS Catalog.IntangibleAssets).Code AS Code,
		|	CheckingCalculationParameters.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified,
		|	CheckingCalculationParameters.MAExpenseItemIsNotSpecified AS MAExpenseItemIsNotSpecified,
		|	CheckingCalculationParameters.ACExpenseItemIsNotSpecified AS ACExpenseItemIsNotSpecified
		|
		|FROM
		|	CheckingCalculationParameters AS CheckingCalculationParameters
		|";
		
	EndIf; 
		
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("CompaniesList", CalculationParameters.CompaniesList);
	
	Result = Query.Execute();
	
	CalculationParameters.HasErrors = Not Result.IsEmpty() Or CalculationParameters.HasErrors;
	
	If CalculationParameters.RegisterErrors Then
	
		Selection = Result.Select();
		
		TemplateOperatingTime = NStr("vi = 'Đối với đối tượng kế toán ""%1"" (mã %2), lượng thời gian hoạt động (sản phẩm, công việc) ước tính không được chỉ định.';
									|ru = 'Для объекта учета ""%1"" (код %2) не указан предполагаемый объем наработки (продукции, работ).';
									|en = 'Estimated asset activity value (of products, works) is not specified for the ""%1"" accounting object (code %2).'; fa = 'Estimated asset activity value (of products, works) is not specified for the ""%1"" accounting object (code %2).';
									|it = 'Non è indicato il volume di produzione stimato (articoli, lavoro) per l''entità ""%1"" (codice %2).';
									|pl = 'Dla obiektu ewidencji ""%1"" (kod %2) nie wskazano prognozowanej ilości średniego czasu pracy (produkcji, prac).';
									|tr = '""%1"" muhasebe nesnesi (kod %2) için tahmini çalışma hacmi (ürünler, işler) belirtilmemiştir.'");
		TemplateDoesNotSpecifyExpenseItemMA = NStr("vi = 'Đối với đối tượng kế toán ""%1"" (mã số %2) trong kế toán quản trị, chưa xác định dạng chi phí phản ánh khấu hao.';
													|ru = 'Для объекта учета ""%1"" (код №%2) в управленческом учете не определена статья расходов отражения амортизации.';
													|en = 'The amortization recording expense item is not specified for the ""%1"" accounting object (code No. %2) in the management accounting.'; fa = 'The amortization recording expense item is not specified for the ""%1"" accounting object (code No. %2) in the management accounting.';
													|it = 'Для объекта учета ""%1"" (код №%2) в управленческом учете не определена статья расходов отражения амортизации.';
													|pl = 'The amortization recording expense item is not specified for the ""%1"" accounting object (code No. %2) in the management accounting.';
													|tr = '""%1"" muhasebe nesnesi için (Kod No. %2), yönetim muhasebesinde amortismanı yansıtan gider kalemi tanımlanmamıştır.'");
		TemplateDoesNotSpecifyACExpenseItem = NStr("vi = 'Đối với đối tượng kế toán ""%1"" (mã số %2) trong kế toán doanh nghiệp, chưa xác định dạng chi phí phản ánh khấu hao.';
													|ru = 'Для объекта учета ""%1"" (код №%2) в бухгалтерском учете не определена статья расходов отражения амортизации.';
													|en = 'The expense item is not specified to record amortization, for the ""%1"" (code No. %2) accounting object in local accounting.'; fa = 'The expense item is not specified to record amortization, for the ""%1"" (code No. %2) accounting object in local accounting.';
													|it = 'Для объекта учета ""%1"" (код №%2) в бухгалтерском учете не определена статья расходов отражения амортизации.';
													|pl = 'The expense item is not specified to record amortization, for the ""%1"" (code No. %2) accounting object in local accounting.';
													|tr = '""%1"" muhasebe nesnesi için (Kod No. %2), yerel muhasebede amortismanı yansıtan gider kalemi tanımlanmamıştır.'");
		
		While Selection.Next() Do
			
			If Selection.AmountOfOperatingTimeIsNotSpecified Then
				
				ErrorText = StrTemplate(TemplateOperatingTime, Selection.AccountingObjectPresentation, Selection.Code);
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.IntangibleAssetAmortizationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
			
			If Selection.MAExpenseItemIsNotSpecified Then
				
				ErrorText = StrTemplate(TemplateDoesNotSpecifyExpenseItemMA, Selection.AccountingObjectPresentation, Selection.Code);
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
			
			If Selection.ACExpenseItemIsNotSpecified Then
				
				ErrorText = StrTemplate(TemplateDoesNotSpecifyACExpenseItem, Selection.AccountingObjectPresentation, Selection.Code);
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CalculationParameters.Period,
					Selection.Organization,
					ErrorText,,
					Selection.AccountingObject,
					CalculationParameters.HasErrors);
					
			EndIf; 
	
			IntangibleAssetsAmortizationChargeLocalization.RegisterDepreciationCalculationErrors(Selection, CalculationParameters);
		
		EndDo;
	
	EndIf;
	
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
		
			MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("IntangibleAssetsAmortizationCharge.CalculateDepreciation.RecordCalculation");
		
			// You need to block documents so as not to create duplicates
			Block = New DataLock;
			
			LockItem = Block.Add("Document.IntangibleAssetsAmortizationCharge2_4");
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
			|			ELSE VALUE(Document.IntangibleAssetsAmortizationCharge2_4.EmptyRef)
			|		END) AS LinkHeld,
			|
			|	MAX(CASE
			|			WHEN RegulatoryDocument.Posted = FALSE
			|				THEN RegulatoryDocument.Ref
			|			ELSE VALUE(Document.IntangibleAssetsAmortizationCharge2_4.EmptyRef)
			|		END) AS LinkNotFound,
			|
			|	MAX(CASE
			|			WHEN RegulatoryDocument.DeletionMark = TRUE
			|				THEN RegulatoryDocument.Ref
			|			ELSE VALUE(Document.IntangibleAssetsAmortizationCharge2_4.EmptyRef)
			|		END) AS LinkRemoved
			|
			|FROM
			|	Document.IntangibleAssetsAmortizationCharge2_4 AS RegulatoryDocument
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
					
					DocumentObject = CalculationParameters.Ref.GetObject(); // DocumentObject.IntangibleAssetsAmortizationCharge2_4
					DocumentObject.Comment = CalculationParameters.Comment;
					EmployeeResponsible = CalculationParameters.EmployeeResponsible;
					
				Else 
					
					DocumentObject = NonCurrentAssetsInternal.GetRegulatoryDocument(
						SampleDocument.LinkHeld, 
						Undefined, 
						Undefined, 
						Documents.IntangibleAssetsAmortizationCharge2_4);
						
				EndIf;
				
			Else	
				
				DocumentObject = NonCurrentAssetsInternal.GetRegulatoryDocument(
					SampleDocument.LinkHeld, 
					SampleDocument.LinkNotFound, 
					SampleDocument.LinkRemoved, 
					Documents.IntangibleAssetsAmortizationCharge2_4);
					
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
					InformationRegisters.JobsForCalculatingIntangibleAssetAmortization.CreateRegisterEntry(
						CalculationParameters.Period, Undefined, Selection.Organization, Selection.PackageNumber);
					
				Else
					
					DepreciationPackages = CalculationParameters.DepreciationPackages.Copy(CommonClientServer.ValueInArray(Selection));
					
					InformationRegisters.JobsForCalculatingIntangibleAssetAmortization.FixCalculation(
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
	|	Depreciation.KindOfAccountingObject AS KindOfAccountingObject,
	|	Depreciation.CalculationPeriod AS CalculationPeriod,
	|	Depreciation.Organization AS Organization,
	|	Depreciation.IntangibleAsset AS IntangibleAsset,
	|	Depreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Depreciation.Department AS Department,
	|	Depreciation.LineOfBusiness AS LineOfBusiness,
	|
	|	ISNULL(WaysToReflectDepreciation.ExpenseItem, Depreciation.ExpenseItem) AS ExpenseItem,
	|	ISNULL(WaysToReflectDepreciation.DimensionOfExpenses, Depreciation.DimensionOfExpenses) AS DimensionOfExpenses,
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
	|	ISNULL(WaysToReflectDepreciation.TransferExpensesToAnotherCompany, Depreciation.TransferExpensesToAnotherCompany) AS TransferExpensesToAnotherCompany,
	|	ISNULL(WaysToReflectDepreciation.CompanyRecipientOfExpenses, Depreciation.CompanyRecipientOfExpenses) AS CompanyRecipientOfExpenses,
	|	Depreciation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	Depreciation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	Depreciation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	Depreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
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
	|		DepreciationCalculation.KindOfAccountingObject AS KindOfAccountingObject,
	|		DepreciationCalculation.Period AS CalculationPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
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
	|		DepreciationCalculation.VersionOfAccrualMethod AS VersionOfAccrualMethod,
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
	|		END AS CostUsedToCalculateDepreciationLocal
	|
	|	FROM
	|		CalculationOfDepreciation_ForLastMonth_Unchanged_Y AS DepreciationCalculation
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DepreciationCalculation.KindOfAccountingObject AS KindOfAccountingObject,
	|		DepreciationCalculation.Period AS CalculationPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
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
	|		DepreciationCalculation.VersionOfAccrualMethod AS VersionOfAccrualMethod,
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
	|		END AS CostUsedToCalculateDepreciationLocal
	|
	|	FROM
	|		CalculationOfDepreciation_ForLastMonth_TakingIntoAccountChangesInMA AS DepreciationCalculation
	|
	|	) AS Depreciation
	|
	|		LEFT JOIN WaysToReflectDepreciation AS WaysToReflectDepreciation
	|		ON (WaysToReflectDepreciation.DepreciationRecordMethod = Depreciation.DepreciationRecordMethod)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
	|	SUM(DepreciationCalculation.AmountOfUU) AS AmountOfUU,
	|	SUM(DepreciationCalculation.AmountAccounting) AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForLastMonthUU_Grouped
	|
	|FROM
	|	CalculationOfDepreciation_ForLastMonthMA AS DepreciationCalculation
	|
	|GROUP BY
	|	DepreciationCalculation.IntangibleAsset
	|
	|INDEX BY
	|	IntangibleAsset
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
	IntangibleAssetAmortizationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	
	Query.Execute();
	
	TMCommonUse.DestroyTemporaryTables(CalculationParameters.TempTablesManager,, TTUsed);
	
EndProcedure

Procedure CalculateDepreciation_ForLastMonth_UnchangedMA(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	ListOfIA.Period AS Period,
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.Department AS Department,
	|	ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness AS LineOfBusiness,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.ExpenseItem AS ExpenseItem,
	|	ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned AS ResourceAssigned,
	|	ListOfIA.DepreciationMethod AS DepreciationMethod,
	|	ListOfIA.Cost AS Cost,
	|	ListOfIA.LocalCost AS LocalCost,
	|	ListOfIA.Depreciation AS Depreciation,
	|	ListOfIA.DepreciationLocal AS DepreciationLocal,
	|	ListOfIA.NetBookValueLocal AS NetBookValueLocal,
	|	ListOfIA.NetBookValue AS NetBookValue,
	|	ListOfIA.ResidualValueMan AS ResidualValueMan,
	|	ListOfIA.ResidualValueLocal AS ResidualValueLocal,
	|	ListOfIA.AccelerationFactor AS AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	ListOfIA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfIA.PreliminaryCostExceedsActualMA AS PreliminaryCostExceedsActualMA,
	|	ListOfIA.PreliminaryCostExceedsActualAC AS PreliminaryCostExceedsActualAC,
	|
	|	CASE
	|		WHEN ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|				AND ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)
	|			THEN 1
	|		ELSE 0
	|	END AS VersionOfAccrualMethod,
	|
	|	CASE
	|		WHEN (ListOfIA.NetBookValue - (&AmountOfMaDepreciation)) > ListOfIA.ResidualValueMan
	|			THEN &AmountOfMaDepreciation
	|		WHEN (ListOfIA.NetBookValue - ListOfIA.ResidualValueMan) > 0
	|			THEN (ListOfIA.NetBookValue - ListOfIA.ResidualValueMan)
	|		ELSE 0
	|	END AS AmountOfUU,
	|
	|	CASE
	|		WHEN (ListOfIA.NetBookValueLocal - (&AmountOfACDepreciation)) > ListOfIA.ResidualValueLocal
	|			THEN &AmountOfACDepreciation
	|		WHEN (ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal) > 0
	|			THEN (ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal)
	|		ELSE 0
	|	END AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForLastMonth_Unchanged_Y
	|
	|FROM
	|	ListOfNMAsParameters_UU AS ListOfIA
	|
	|		LEFT JOIN CheckingCalculationParameters_Y AS CheckingCalculationParameters
	|		ON CheckingCalculationParameters.AccountingObject = ListOfIA.IntangibleAsset
	|
	|WHERE
	|	ListOfIA.ThisIsAnAdditionalAccrual
	|	AND CheckingCalculationParameters.AccountingObject IS NULL
	|";
	
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	RequestTextParameters.TextCost = "ListOfIA.Cost";
	RequestTextParameters.TextDepreciation = "ListOfIA.Depreciation";
	RequestTextParameters.TextResidualValue = "ListOfIA.NetBookValue";
	RequestTextParameters.TextInitialCost = "ListOfIA.InitialCost";
	RequestTextParameters.TextLiquidationValue = "0";
	RequestTextParameters.TextImpairment = "0";
	RequestTextParameters.TextAmountOfAdditionalCharge = "0";

	TextAmountOfDepreciationOfMa = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfMaDepreciation", TextAmountOfDepreciationOfMa);
		
	//
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	RequestTextParameters.TextCost = "ListOfIA.LocalCost";
	RequestTextParameters.TextDepreciation = "ListOfIA.DepreciationLocal";
	RequestTextParameters.TextResidualValue = "ListOfIA.NetBookValueLocal";
	RequestTextParameters.TextInitialCost = "ListOfIA.InitialCostOfLocal";
	RequestTextParameters.TextLiquidationValue = "0";
	RequestTextParameters.TextImpairment = "0";
	RequestTextParameters.TextAmountOfAdditionalCharge = "0";
	
	TextACDepreciationAmount = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfACDepreciation", TextACDepreciationAmount);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	IntangibleAssetAmortizationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	Query.Execute();
	
EndProcedure

Procedure CalculateDepreciation_ForLastMonth_TakingIntoAccountChangesInMA(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	1 AS Priority,
	|	DATETIME(1,1,1) AS Period,
	|	UNDEFINED AS Recorder,
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.Department AS Department,
	|	ListOfIA.FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	CAST(ListOfIA.IntangibleAsset AS Catalog.IntangibleAssets).Code AS IntangibleAssetCode,
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.ExpenseItem AS ExpenseItem,
	|	ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	ListOfIA.AmountOfUU AS AmountOfUU,
	|	ListOfIA.AmountAccounting AS AmountAccounting,
	|	0 AS ImpairmentMA,
	|	0 AS ImpairmentAC,
	|	1 AS ZoomRatio,
	|	ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned,
	|	ListOfIA.DepreciationMethod,
	|	ListOfIA.NetBookValue,
	|	ListOfIA.NetBookValueLocal,
	|	ListOfIA.ResidualValueMan,
	|	ListOfIA.ResidualValueLocal,
	|	0 AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
	|	ListOfIA.AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization,
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	0 AS CostUsedToCalculateDepreciationLocal,
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostUpdate,
	|	0 AS LocalCostUpdate,
	|	0 AS Depreciation,
	|	0 AS DepreciationLocal,
	|	0 AS DepreciationUpdate,
	|	0 AS DepreciationLocalUpdate,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfIA.PreliminaryCostExceedsActualMA AS PreliminaryCostExceedsActualMA,
	|	ListOfIA.PreliminaryCostExceedsActualAC AS PreliminaryCostExceedsActualAC,
	|	FALSE AS MACostAdjustment,
	|	FALSE AS ACCostAdjustment,
	|	FALSE AS MADepreciationAdjustment,
	|	FALSE AS ACDepreciationAdjustment,
	|	UNDEFINED AS RevaluationMethod,
	|	FALSE AS RevaluateAtFairValue,
	|	FALSE AS TheseAreChanges
	|
	|FROM
	|	CalculationOfDepreciation_ForLastMonth_Unchanged_Y AS ListOfIA
	|
	|WHERE
	|	ListOfIA.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfNMAsWithModifiedParameters_Y AS ListOfIA)
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS Priority,
	|	ListOfIA.Period,
	|	ListOfIA.Recorder,
	|	ListOfIA.Organization,
	|	ListOfIA.Department,
	|	ListOfIA.FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness,
	|	ListOfIA.IntangibleAsset,
	|	CAST(ListOfIA.IntangibleAsset AS Catalog.IntangibleAssets).Code,
	|	ListOfIA.KindOfAccountingObject,
	|	ListOfIA.ExpenseItem,
	|	ListOfIA.DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod,
	|	0,
	|	0,
	|	0,
	|	0,
	|	1,
	|	ListOfIA.TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned,
	|	ListOfIA.DepreciationMethod,
	|	ListOfIA.NetBookValue,
	|	ListOfIA.NetBookValueLocal,
	|	ListOfIA.ResidualValueMan,
	|	ListOfIA.ResidualValueLocal,
	|	0,
	|	0,
	|	ListOfIA.AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization,
	|	0,
	|	0,
	|	ListOfIA.Cost,
	|	ListOfIA.LocalCost,
	|	ListOfIA.CostUpdate,
	|	ListOfIA.LocalCostUpdate,
	|	ListOfIA.Depreciation,
	|	ListOfIA.DepreciationLocal,
	|	ListOfIA.DepreciationUpdate,
	|	ListOfIA.DepreciationLocalUpdate,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfIA.PreliminaryCostExceedsActualMA AS PreliminaryCostExceedsActualMA,
	|	ListOfIA.PreliminaryCostExceedsActualAC AS PreliminaryCostExceedsActualAC,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MACostAdjustment,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInLocalAccounting, FALSE) AS ACCostAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MADepreciationAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInLocalAccounting, FALSE) AS ACDepreciationAdjustment,
	|
	|	ListOfIA.RevaluationMethod AS RevaluationMethod,
	|	ISNULL(Revaluation.RevaluateAtFairValue, FALSE) AS RevaluateAtFairValue,
	|
	|	TRUE
	|
	|FROM
	|	ListOfNMAsWithModifiedParameters_Y AS ListOfIA
	|
	|		LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment AS Adjusting
	|		ON Adjusting.Ref = ListOfIA.Recorder
	|
	|		LEFT JOIN Document.IARevaluation2_4 AS Revaluation
	|		ON Revaluation.Ref = ListOfIA.Recorder
	|
	|WHERE
	|	ListOfIA.ThisIsAnAdditionalAccrual
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	QueryResult = Query.Execute();

	AmortizationOfChanges = CalculateDepreciationWhenParametersChange(QueryResult.Unload());
	
	QueryText = 
	"SELECT
	|	DepreciationCalculation.KindOfAccountingObject AS KindOfAccountingObject,
	|	DepreciationCalculation.Period AS Period,
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.Department AS Department,
	|	DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|	DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
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
	|	DepreciationCalculation.PreliminaryCostExceedsActualMA AS PreliminaryCostExceedsActualMA,
	|	DepreciationCalculation.PreliminaryCostExceedsActualAC AS PreliminaryCostExceedsActualAC,
	|
	|	CASE
	|		WHEN DepreciationCalculation.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)
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
	|	Depreciation.KindOfAccountingObject AS KindOfAccountingObject,
	|	Depreciation.CalculationPeriod AS CalculationPeriod,
	|	Depreciation.Organization AS Organization,
	|	Depreciation.IntangibleAsset AS IntangibleAsset,
	|	Depreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Depreciation.Department AS Department,
	|	Depreciation.LineOfBusiness AS LineOfBusiness,
	|
	|	ISNULL(WaysToReflectDepreciation.ExpenseItem, Depreciation.ExpenseItem) AS ExpenseItem,
	|	ISNULL(WaysToReflectDepreciation.DimensionOfExpenses, Depreciation.DimensionOfExpenses) AS DimensionOfExpenses,
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
	|	ISNULL(WaysToReflectDepreciation.TransferExpensesToAnotherCompany, Depreciation.TransferExpensesToAnotherCompany) AS TransferExpensesToAnotherCompany,
	|	ISNULL(WaysToReflectDepreciation.CompanyRecipientOfExpenses, Depreciation.CompanyRecipientOfExpenses) AS CompanyRecipientOfExpenses,
	|	Depreciation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	Depreciation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	Depreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
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
	|		DepreciationCalculation.KindOfAccountingObject AS KindOfAccountingObject,
	|		DepreciationCalculation.Period AS CalculationPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
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
	|		DepreciationCalculation.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|				THEN -DepreciationCalculation.CostUsedToCalculateDepreciationLocal
	|			ELSE DepreciationCalculation.CostUsedToCalculateDepreciationLocal 
	|		END AS CostUsedToCalculateDepreciationLocal
	|
	|	FROM
	|		CalculationOfDepreciationForLastMonth_Unchanged_BU_M AS DepreciationCalculation
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DepreciationCalculation.KindOfAccountingObject AS KindOfAccountingObject,
	|		DepreciationCalculation.Period AS CalculationPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
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
	|		DepreciationCalculation.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|
	|		CASE
	|			WHEN DepreciationCalculation.PreliminaryCostExceedsActual
	|				THEN -DepreciationCalculation.CostUsedToCalculateDepreciationLocal
	|			ELSE DepreciationCalculation.CostUsedToCalculateDepreciationLocal 
	|		END AS CostUsedToCalculateDepreciationManag
	|
	|	FROM
	|		CalculationOfDepreciation_ForLastMonth_TakingIntoAccountChangesInBU_MU AS DepreciationCalculation
	|
	|	) AS Depreciation
	|
	|		LEFT JOIN WaysToReflectDepreciation AS WaysToReflectDepreciation
	|		ON (WaysToReflectDepreciation.DepreciationRecordMethod = Depreciation.DepreciationRecordMethod)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
	|	SUM(DepreciationCalculation.AmountAccounting) AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForLastMonthBU_MU_Grouped
	|
	|FROM
	|	CalculationOfDepreciation_ForLastMonthBU_MU AS DepreciationCalculation
	|
	|GROUP BY
	|	DepreciationCalculation.IntangibleAsset
	|
	|INDEX BY
	|	IntangibleAsset
	|";
	
	QueryText = StrReplace(
		QueryText, "&DistributionOfACAmount", 
		NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.AmountAccounting"));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	IntangibleAssetAmortizationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	Query.Execute();
	
	TMCommonUse.DestroyTemporaryTables(CalculationParameters.TempTablesManager,, TTUsed);
	
EndProcedure

Procedure CalculateDepreciation_ForLastMonth_UnchangedAC(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	ListOfIA.Period AS Period,
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.Department AS Department,
	|	ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness AS LineOfBusiness,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.ExpenseItem AS ExpenseItem,
	|	ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned AS ResourceAssigned,
	|	ListOfIA.DepreciationMethod AS DepreciationMethod,
	|	ListOfIA.LocalCost AS LocalCost,
	|	ListOfIA.DepreciationLocal AS DepreciationLocal,
	|	ListOfIA.NetBookValueLocal AS NetBookValueLocal,
	|	ListOfIA.ResidualValueLocal AS ResidualValueLocal,
	|	ListOfIA.AccelerationFactor AS AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfIA.PreliminaryCostExceedsActual AS PreliminaryCostExceedsActual,
	|
	|	CASE
	|		WHEN ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)
	|			THEN 1
	|		ELSE 0
	|	END AS VersionOfAccrualMethod,
	|
	|	CASE
	|		WHEN (ListOfIA.NetBookValueLocal - (&AmountOfACDepreciation)) > ListOfIA.ResidualValueLocal
	|			THEN &AmountOfACDepreciation
	|		WHEN (ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal) > 0
	|			THEN (ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal)
	|		ELSE 0
	|	END AS AmountAccounting
	|
	|INTO CalculationOfDepreciationForLastMonth_Unchanged_BU_M
	|
	|FROM
	|	ListOfNMASWithParameters_BU_MU AS ListOfIA
	|
	|		LEFT JOIN CheckingCalculationParametersOf_BU_M AS CheckingCalculationParameters
	|		ON CheckingCalculationParameters.AccountingObject = ListOfIA.IntangibleAsset
	|
	|WHERE
	|	ListOfIA.ThisIsAnAdditionalAccrual
	|	AND CheckingCalculationParameters.AccountingObject IS NULL
	|";
	
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	RequestTextParameters.TextCost = "ListOfIA.LocalCost";
	RequestTextParameters.TextDepreciation = "ListOfIA.DepreciationLocal";
	RequestTextParameters.TextResidualValue = "ListOfIA.NetBookValueLocal";
	RequestTextParameters.TextInitialCost = "ListOfIA.InitialCostOfLocal";
	RequestTextParameters.TextLiquidationValue = "0";
	RequestTextParameters.TextImpairment = "0";
	RequestTextParameters.TextAmountOfAdditionalCharge = "0";
	
	TextACDepreciationAmount = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfACDepreciation", TextACDepreciationAmount);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	IntangibleAssetAmortizationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	
	Query.Execute();
	
EndProcedure

Procedure CalculateDepreciation_ForLastMonth_TakingIntoAccountChangesInAC(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	1 AS Priority,
	|	DATETIME(1,1,1) AS Period,
	|	UNDEFINED AS Recorder,
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.Department AS Department,
	|	ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness AS LineOfBusiness,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	CAST(ListOfIA.IntangibleAsset AS Catalog.IntangibleAssets).Code AS IntangibleAssetCode,
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.ExpenseItem AS ExpenseItem,
	|	ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	0 AS AmountOfUU,
	|	ListOfIA.AmountAccounting AS AmountAccounting,
	|	0 AS ImpairmentMA,
	|	0 AS ImpairmentAC,
	|	1 AS ZoomRatio,
	|	ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned AS ResourceAssigned,
	|	ListOfIA.DepreciationMethod AS DepreciationMethod,
	|	0 AS NetBookValue,
	|	ListOfIA.NetBookValueLocal AS NetBookValueLocal,
	|	0 AS ResidualValueMan,
	|	ListOfIA.ResidualValueLocal AS ResidualValueLocal,
	|	0 AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
	|	ListOfIA.AccelerationFactor AS AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	0 AS CostUsedToCalculateDepreciationLocal,
	|	0 AS LocalCost,
	|	0 AS CostUpdate,
	|	0 AS LocalCostUpdate,
	|	0 AS Depreciation,
	|	0 AS DepreciationLocal,
	|	0 AS DepreciationUpdate,
	|	0 AS DepreciationLocalUpdate,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	FALSE AS PreliminaryCostExceedsActual,
	|	FALSE AS ACCostAdjustment,
	|	FALSE AS ACDepreciationAdjustment,
	|	UNDEFINED AS RevaluationMethod,
	|	FALSE AS RevaluateAtFairValue,
	|	FALSE AS TheseAreChanges
	|
	|FROM
	|	CalculationOfDepreciationForLastMonth_Unchanged_BU_M AS ListOfIA
	|
	|WHERE
	|	ListOfIA.IntangibleAsset IN
	|		(SELECT
	|			ListOfIA.IntangibleAsset
	|		FROM
	|			ListOfNMASWithChangedParameters_BU_MU AS ListOfIA)
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS Priority,
	|	ListOfIA.Period AS Period,
	|	ListOfIA.Recorder AS Recorder,
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.Department AS Department,
	|	ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness AS LineOfBusiness,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	CAST(ListOfIA.IntangibleAsset AS Catalog.IntangibleAssets).Code AS IntangibleAssetCode,
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.ExpenseItem AS ExpenseItem,
	|	ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	0 AS AmountOfUU,
	|	0 AS AmountAccounting,
	|	0 AS ImpairmentMA,
	|	0 AS ImpairmentAC,
	|	1 AS ZoomRatio,
	|	ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned AS ResourceAssigned,
	|	ListOfIA.DepreciationMethod AS DepreciationMethod,
	|	0 AS NetBookValue,
	|	ListOfIA.NetBookValueLocal AS NetBookValueLocal,
	|	0 AS ResidualValueMan,
	|	ListOfIA.ResidualValueLocal AS ResidualValueLocal,
	|	0 AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
	|	ListOfIA.AccelerationFactor AS AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	0 AS CostUsedToCalculateDepreciationLocal,
	|	ListOfIA.LocalCost,
	|	0 AS CostUpdate,
	|	ListOfIA.LocalCostUpdate AS LocalCostUpdate,
	|	0,
	|	ListOfIA.DepreciationLocal,
	|	0 AS DepreciationUpdate,
	|	ListOfIA.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfIA.PreliminaryCostExceedsActual AS PreliminaryCostExceedsActual,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInLocalAccounting, FALSE) AS ACCostAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInLocalAccounting, FALSE) AS ACDepreciationAdjustment,
	|
	|	ListOfIA.RevaluationMethod AS RevaluationMethod,
	|	ISNULL(Revaluation.RevaluateAtFairValue, FALSE) AS RevaluateAtFairValue,
	|
	|	TRUE AS TheseAreChanges
	|
	|FROM
	|	ListOfNMASWithChangedParameters_BU_MU AS ListOfIA
	|
	|		LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment AS Adjusting
	|		ON Adjusting.Ref = ListOfIA.Recorder
	|
	|		LEFT JOIN Document.IARevaluation2_4 AS Revaluation
	|		ON Revaluation.Ref = ListOfIA.Recorder
	|
	|WHERE
	|	ListOfIA.ThisIsAnAdditionalAccrual
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;

	QueryResult = Query.Execute();
	
	AmortizationOfChanges = CalculateDepreciationWhenParametersChange(QueryResult.Unload());
	
	QueryText =
	"SELECT
	|	DepreciationCalculation.KindOfAccountingObject AS KindOfAccountingObject,
	|	DepreciationCalculation.Period AS Period,
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.Department AS Department,
	|	DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|	DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
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
	|	DepreciationCalculation.PreliminaryCostExceedsActual AS PreliminaryCostExceedsActual,
	|
	|	CASE
	|		WHEN DepreciationCalculation.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)
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
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.Period AS Period,
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.Department AS Department,
	|	ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness AS LineOfBusiness,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	ListOfIA.ExpenseItem AS ExpenseItem,
	|	ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned AS ResourceAssigned,
	|	ListOfIA.DepreciationMethod AS DepreciationMethod,
	|	ListOfIA.Cost AS Cost,
	|	ListOfIA.LocalCost AS LocalCost,
	|	ListOfIA.Depreciation AS Depreciation,
	|	ListOfIA.DepreciationLocal AS DepreciationLocal,
	|	ListOfIA.NetBookValue AS NetBookValue,
	|	ListOfIA.NetBookValueLocal AS NetBookValueLocal,
	|	ListOfIA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	ListOfIA.ResidualValueMan AS ResidualValueMan,
	|	ListOfIA.ResidualValueLocal AS ResidualValueLocal,
	|	ListOfIA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|	ListOfIA.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|	ListOfIA.AccelerationFactor AS AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	ListOfIA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfIA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|
	|	ListOfIA.ImpairmentMA AS ImpairmentMA,
	|	ListOfIA.ImpairmentAC AS ImpairmentAC,
	|
	|	CASE 
	|		WHEN (ListOfIA.NetBookValue - ListOfIA.ResidualValueMan - ListOfIA.ImpairmentMA - ListOfIA.AmountOfUU) < &MinimumResidualValueOfUpr
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|			THEN ListOfIA.NetBookValue - ListOfIA.ResidualValueMan - ListOfIA.ImpairmentMA
	|
	|		WHEN (ListOfIA.NetBookValue - ListOfIA.ResidualValueMan - ListOfIA.AmountOfUU) < &MinimumResidualValueOfUpr
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|			THEN ListOfIA.NetBookValue - ListOfIA.ResidualValueMan - ListOfIA.ImpairmentMA
	|
	|		ELSE ListOfIA.AmountOfUU
	|
	|	END AS AmountOfUU,
	|
	|	CASE 
	|		WHEN (ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal - ListOfIA.ImpairmentAC - ListOfIA.AmountAccounting) < &MinimumResidualValueOfRegl 
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|			THEN ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal - ListOfIA.ImpairmentAC
	|
	|		WHEN (ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal - ListOfIA.AmountAccounting) < &MinimumResidualValueOfRegl
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|			THEN ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal
	|
	|		ELSE ListOfIA.AmountAccounting
	|
	|	END AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForCurrentMonth_UnchangedMA
	|
	|FROM
	|	(SELECT
	|		ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|		ListOfIA.Period AS Period,
	|		ListOfIA.Organization AS Organization,
	|		ListOfIA.Department AS Department,
	|		ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfIA.LineOfBusiness AS LineOfBusiness,
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|		ListOfIA.ExpenseItem AS ExpenseItem,
	|		ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfIA.ResourceAssigned AS ResourceAssigned,
	|		ListOfIA.DepreciationMethod AS DepreciationMethod,
	|		ListOfIA.Cost AS Cost,
	|		ListOfIA.LocalCost AS LocalCost,
	|		ListOfIA.Depreciation AS Depreciation,
	|		ListOfIA.DepreciationLocal AS DepreciationLocal,
	|		ListOfIA.NetBookValue - ISNULL(AdditionalCharges.AmountOfUU, 0) AS NetBookValue,
	|		ListOfIA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) AS NetBookValueLocal,
	|
	|		CASE
	|			WHEN ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|				THEN ListOfIA.NetBookValue - ISNULL(AdditionalCharges.AmountOfUU, 0)
	|			ELSE ListOfIA.CostUsedToCalculateDepreciationManag
	|		END AS CostUsedToCalculateDepreciationManag,
	|
	|		CASE
	|			WHEN ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|				THEN ListOfIA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|			ELSE ListOfIA.CostUsedToCalculateDepreciationLocal
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		ListOfIA.ResidualValueMan AS ResidualValueMan,
	|		ListOfIA.ResidualValueLocal AS ResidualValueLocal,
	|		ListOfIA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfIA.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|		ListOfIA.AccelerationFactor AS AccelerationFactor,
	|		ListOfIA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|		ListOfIA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|		ListOfIA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|		ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	|		CASE
	|			WHEN ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|					AND ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)
	|				THEN 1
	|			ELSE 0
	|		END AS VersionOfAccrualMethod,
	|
	|		CASE
	|			WHEN &ImpairmentMA > ListOfIA.ImpairmentBalanceMan
	|					OR ListOfIA.ImpairmentBalanceMan - &ImpairmentMA < &MinimumResidualValueOfUpr
	|				THEN ListOfIA.ImpairmentBalanceMan
	|
	|			ELSE &ImpairmentMA
	|		END AS ImpairmentMA,
	|
	|		CASE
	|			WHEN &ImpairmentAC > ListOfIA.ImpairmentBalanceLocal
	|					OR ListOfIA.ImpairmentBalanceLocal - &ImpairmentAC < &MinimumResidualValueOfRegl
	|				THEN ListOfIA.ImpairmentBalanceLocal
	|
	|			ELSE &ImpairmentAC
	|		END AS ImpairmentAC,
	|
	|		CASE 
	|			WHEN (ListOfIA.NetBookValue - ListOfIA.ImpairmentBalanceMan - ListOfIA.ResidualValueMan - ISNULL(AdditionalCharges.AmountOfUU, 0) - (&AmountOfMaDepreciation)) < &MinimumResidualValueOfUpr
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|				THEN ListOfIA.NetBookValue - ListOfIA.ImpairmentBalanceMan - ListOfIA.ResidualValueMan - ISNULL(AdditionalCharges.AmountOfUU, 0)
	|
	|			WHEN (ListOfIA.NetBookValue - ListOfIA.ResidualValueMan - ISNULL(AdditionalCharges.AmountOfUU, 0) - (&AmountOfMaDepreciation)) < &MinimumResidualValueOfUpr
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|				THEN ListOfIA.NetBookValue - ListOfIA.ResidualValueMan - ISNULL(AdditionalCharges.AmountOfUU, 0)
	|
	|			ELSE &AmountOfMaDepreciation
	|
	|		END AS AmountOfUU,
	|
	|		CASE 
	|			WHEN (ListOfIA.NetBookValueLocal - ListOfIA.ImpairmentBalanceLocal - ListOfIA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) - (&AmountOfACDepreciation)) < &MinimumResidualValueOfRegl
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|				THEN ListOfIA.NetBookValueLocal - ListOfIA.ImpairmentBalanceLocal - ListOfIA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|
	|			WHEN (ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) - (&AmountOfACDepreciation)) < &MinimumResidualValueOfRegl
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|				THEN ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|
	|			ELSE &AmountOfACDepreciation
	|
	|		END AS AmountAccounting
	|
	|	FROM
	|		ListOfNMAsParameters_UU AS ListOfIA
	|
	|			LEFT JOIN CalculationOfDepreciation_ForLastMonthUU_Grouped AS AdditionalCharges
	|			ON AdditionalCharges.IntangibleAsset = ListOfIA.IntangibleAsset
	|
	|			LEFT JOIN CheckingCalculationParameters_Y AS CheckingCalculationParameters
	|			ON CheckingCalculationParameters.AccountingObject = ListOfIA.IntangibleAsset
	|				AND CheckingCalculationParameters.Organization = ListOfIA.Organization
	|
	|	WHERE
	|		NOT ListOfIA.ThisIsAnAdditionalAccrual
	|		AND CheckingCalculationParameters.AccountingObject IS NULL
	|
	|	) AS ListOfIA
	|";
	
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	RequestTextParameters.TextCost = "ListOfIA.Cost";
	RequestTextParameters.TextDepreciation = "ListOfIA.Depreciation";
	RequestTextParameters.TextResidualValue = "ListOfIA.NetBookValue";
	RequestTextParameters.TextInitialCost = "ListOfIA.InitialCost";
	RequestTextParameters.TextLiquidationValue = "ListOfIA.ResidualValueMan";
	RequestTextParameters.TextImpairment = "ListOfIA.ImpairmentBalanceMan";
	RequestTextParameters.TextAmountOfAdditionalCharge = "ISNULL(AdditionalCharges.AmountOfUU, 0)";

	TextAmountOfDepreciationOfMa = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfMaDepreciation", TextAmountOfDepreciationOfMa);
	
	//
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	RequestTextParameters.TextCost = "ListOfIA.LocalCost";
	RequestTextParameters.TextDepreciation = "ListOfIA.DepreciationLocal";
	RequestTextParameters.TextResidualValue = "ListOfIA.NetBookValueLocal";
	RequestTextParameters.TextInitialCost = "ListOfIA.InitialCostOfLocal";
	RequestTextParameters.TextLiquidationValue = "ListOfIA.ResidualValueLocal";
	RequestTextParameters.TextImpairment = "ListOfIA.ImpairmentBalanceLocal";
	RequestTextParameters.TextAmountOfAdditionalCharge = "ISNULL(AdditionalCharges.AmountAccounting, 0)";
	
	TextACDepreciationAmount = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfACDepreciation", TextACDepreciationAmount);
	
	//
	TextMaImpairment = QueryTextAmountOfImpairment("ListOfIA.ImpairmentBalanceMan");
	QueryText = StrReplace(QueryText, "&ImpairmentMA", TextMaImpairment);
	
	//
	TextACImpairment = QueryTextAmountOfImpairment("ListOfIA.ImpairmentBalanceLocal");
	QueryText = StrReplace(QueryText, "&ImpairmentAC", TextACImpairment);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	IntangibleAssetAmortizationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	Query.Execute();
	
EndProcedure

Procedure CalculateDepreciation_ForCurrentMonth_TakingIntoAccountMAChanges(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	1 AS Priority,
	|	DATETIME(1,1,1) AS Period,
	|	UNDEFINED AS Recorder,
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.Department AS Department,
	|	ListOfIA.FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	ListOfIA.ExpenseItem AS ExpenseItem,
	|	ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	ListOfIA.AmountOfUU AS AmountOfUU,
	|	ListOfIA.AmountAccounting AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|	ListOfIA.ImpairmentMA AS ImpairmentMA,
	|	ListOfIA.ImpairmentAC AS ImpairmentAC,
	|	1 AS ZoomRatio,
	|	ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned,
	|	ListOfIA.DepreciationMethod,
	|	ListOfIA.ResidualValueMan,
	|	ListOfIA.ResidualValueLocal,
	|	ListOfIA.AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization,
	|
	|	ListOfIA.Cost AS Cost,
	|	ListOfIA.LocalCost AS LocalCost,
	|	0 AS CostPermanentDifference,
	|
	|	ListOfIA.ImpairmentBalanceLocal AS ImpairmentLocalAssets,
	|	ListOfIA.ImpairmentBalanceMan AS ImpairmenMan,
	|
	|	0 AS CostUpdate,
	|	0 AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|
	|	0 AS DepreciationUpdate,
	|	0 AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|
	|	CASE 
	|		WHEN BEGINOFPERIOD(ListOfIA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfIA.Depreciation + ISNULL(AdditionalCharges.AmountOfUU, 0) 
	|		ELSE ListOfIA.Depreciation
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN BEGINOFPERIOD(ListOfIA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfIA.DepreciationLocal + ISNULL(AdditionalCharges.AmountAccounting, 0) 
	|		ELSE ListOfIA.DepreciationLocal
	|	END AS DepreciationLocal,
	|
	|	0 AS DepreciationPermanentDifferences,
	|
	|	ListOfIA.Cost - ListOfIA.Depreciation AS CostUsedToCalculateDepreciationManag,
	|	ListOfIA.LocalCost - ListOfIA.DepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	FALSE AS MACostAdjustment,
	|	FALSE AS ACCostAdjustment,
	|	FALSE AS MADepreciationAdjustment,
	|	FALSE AS ACDepreciationAdjustment,
	|	UNDEFINED AS RevaluationMethod,
	|	FALSE AS RevaluateAtFairValue,
	|	FALSE AS TheseAreChanges
	|
	|FROM
	|	CalculationOfDepreciation_ForCurrentMonth_UnchangedMA AS ListOfIA
	|
	|		LEFT JOIN CalculationOfDepreciation_ForLastMonthUU_Grouped AS AdditionalCharges
	|		ON AdditionalCharges.IntangibleAsset = ListOfIA.IntangibleAsset
	|
	|WHERE
	|	ListOfIA.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfNMAsWithModifiedParameters_Y AS ListOfIA)
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS Priority,
	|	ListOfIA.Period,
	|	ListOfIA.Recorder,
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.Organization,
	|	ListOfIA.Department,
	|	ListOfIA.FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness,
	|	ListOfIA.IntangibleAsset,
	|	ListOfIA.ExpenseItem,
	|	ListOfIA.DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	1,
	|	ListOfIA.TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned,
	|	ListOfIA.DepreciationMethod,
	|	ListOfIA.ResidualValueMan,
	|	ListOfIA.ResidualValueLocal,
	|	ListOfIA.AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization,
	|
	|	ListOfIA.Cost AS Cost,
	|	ListOfIA.LocalCost AS LocalCost,
	|	0 AS CostPermanentDifference,
	|
	|	ListOfIA.ImpairmentBalanceLocal AS ImpairmentLocalAssets,
	|	ListOfIA.ImpairmentBalanceMan AS ImpairmenMan,
	|
	|	ListOfIA.CostUpdate AS CostUpdate,
	|	ListOfIA.LocalCostUpdate AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|
	|	ListOfIA.DepreciationUpdate AS DepreciationUpdate,
	|	ListOfIA.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|
	|	CASE 
	|		WHEN BEGINOFPERIOD(ListOfIA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfIA.Depreciation + ISNULL(AdditionalCharges.AmountOfUU, 0) 
	|		ELSE ListOfIA.Depreciation
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN BEGINOFPERIOD(ListOfIA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfIA.DepreciationLocal + ISNULL(AdditionalCharges.AmountAccounting, 0) 
	|		ELSE ListOfIA.DepreciationLocal
	|	END AS DepreciationLocal,
	|
	|	ListOfIA.Cost - ListOfIA.Depreciation,
	|	ListOfIA.LocalCost - ListOfIA.DepreciationLocal,
	|	0 AS DepreciationPermanentDifferences,
	|
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MACostAdjustment,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInLocalAccounting, FALSE) AS ACCostAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInManAccounting, FALSE) AS MADepreciationAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInLocalAccounting, FALSE) AS ACDepreciationAdjustment,
	|
	|	ListOfIA.RevaluationMethod AS RevaluationMethod,
	|	ISNULL(Revaluation.RevaluateAtFairValue, FALSE) AS RevaluateAtFairValue,
	|
	|	TRUE
	|FROM
	|	ListOfNMAsWithModifiedParameters_Y AS ListOfIA
	|
	|		LEFT JOIN CalculationOfDepreciation_ForLastMonthUU_Grouped AS AdditionalCharges
	|		ON AdditionalCharges.IntangibleAsset = ListOfIA.IntangibleAsset
	|
	|		LEFT JOIN CheckingParametersForCalculatingChangesIn_Y AS CheckingCalculationParameters
	|		ON CheckingCalculationParameters.AccountingObject = ListOfIA.IntangibleAsset
	|			AND CheckingCalculationParameters.Organization = ListOfIA.Organization
	|
	|		LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment AS Adjusting
	|		ON Adjusting.Ref = ListOfIA.Recorder
	|
	|		LEFT JOIN Document.IARevaluation2_4 AS Revaluation
	|		ON Revaluation.Ref = ListOfIA.Recorder
	|
	|WHERE
	|	NOT ListOfIA.ThisIsAnAdditionalAccrual
	|	AND CheckingCalculationParameters.AccountingObject IS NULL
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	IntangibleAssetAmortizationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	QueryResult = Query.Execute();
	
	AmortizationOfChanges = CalculateDepreciationWhenParametersChange(QueryResult.Unload());
	
	QueryText = 
	"SELECT
	|	DepreciationCalculation.KindOfAccountingObject AS KindOfAccountingObject,
	|	DepreciationCalculation.Period AS Period,
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.Department AS Department,
	|	DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|	DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
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
	|
	|	CASE
	|		WHEN DepreciationCalculation.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)
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
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.Period AS Period,
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.Department AS Department,
	|	ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness AS LineOfBusiness,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	ListOfIA.ExpenseItem AS ExpenseItem,
	|	ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned AS ResourceAssigned,
	|	ListOfIA.DepreciationMethod AS DepreciationMethod,
	|	ListOfIA.LocalCost AS LocalCost,
	|	ListOfIA.DepreciationLocal AS DepreciationLocal,
	|	ListOfIA.NetBookValueLocal AS NetBookValueLocal,
	|	ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	ListOfIA.ResidualValueLocal AS ResidualValueLocal,
	|	ListOfIA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|	ListOfIA.AccelerationFactor AS AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	ListOfIA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	ListOfIA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|
	|	ListOfIA.ImpairmentAC AS ImpairmentAC,
	|
	|	CASE 
	|		WHEN (ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal - ListOfIA.ImpairmentAC - ListOfIA.AmountAccounting) < &MinimumResidualValueOfRegl
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|			THEN ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal - ListOfIA.ImpairmentAC
	|
	|		WHEN (ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal - ListOfIA.AmountAccounting) < &MinimumResidualValueOfRegl
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|			THEN ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal
	|
	|		ELSE ListOfIA.AmountAccounting
	|
	|	END AS AmountAccounting
	|
	|INTO CalculationOfDepreciation_ForCurrentMonth_UnchangedBU_MU
	|
	|FROM
	|	(SELECT
	|		ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|		ListOfIA.Period AS Period,
	|		ListOfIA.Organization AS Organization,
	|		ListOfIA.Department AS Department,
	|		ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfIA.LineOfBusiness AS LineOfBusiness,
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|		ListOfIA.ExpenseItem AS ExpenseItem,
	|		ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfIA.ResourceAssigned AS ResourceAssigned,
	|		ListOfIA.DepreciationMethod AS DepreciationMethod,
	|		ListOfIA.LocalCost AS LocalCost,
	|		ListOfIA.DepreciationLocal AS DepreciationLocal,
	|		ListOfIA.NetBookValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) AS NetBookValueLocal,
	|		ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		ListOfIA.ResidualValueLocal AS ResidualValueLocal,
	|		ListOfIA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfIA.AccelerationFactor AS AccelerationFactor,
	|		ListOfIA.WorkedMonthsFullYears AS WorkedMonthsFullYears,
	|		ListOfIA.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|		ListOfIA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	|		CASE
	|			WHEN ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|					AND ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)
	|				THEN 1
	|			ELSE 0
	|		END AS VersionOfAccrualMethod,
	|
	|		CASE
	|			WHEN &ImpairmentAC > ListOfIA.ImpairmentBalanceLocal
	|					OR ListOfIA.ImpairmentBalanceLocal - &ImpairmentAC < &MinimumResidualValueOfRegl
	|				THEN ListOfIA.ImpairmentBalanceLocal
	|
	|			ELSE &ImpairmentAC
	|
	|		END AS ImpairmentAC,
	|
	|		CASE 
	|			WHEN (ListOfIA.NetBookValueLocal - ListOfIA.ImpairmentBalanceLocal - ListOfIA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) - (&AmountOfACDepreciation)) < &MinimumResidualValueOfRegl
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment
	|
	|				THEN ListOfIA.NetBookValueLocal - ListOfIA.ImpairmentBalanceLocal - ListOfIA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|
	|			WHEN (ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0) - (&AmountOfACDepreciation)) < &MinimumResidualValueOfRegl
	|				AND ListOfIA.PostingOptionForImpairedFADepreciation <> &AddImpairmentAdjustment
	|
	|				THEN ListOfIA.NetBookValueLocal - ListOfIA.ResidualValueLocal - ISNULL(AdditionalCharges.AmountAccounting, 0)
	|
	|			ELSE &AmountOfACDepreciation
	|
	|		END AS AmountAccounting
	|
	|	FROM
	|		ListOfNMASWithParameters_BU_MU AS ListOfIA
	|
	|			LEFT JOIN CalculationOfDepreciation_ForLastMonthBU_MU_Grouped AS AdditionalCharges
	|			ON AdditionalCharges.IntangibleAsset = ListOfIA.IntangibleAsset
	|
	|			LEFT JOIN CheckingCalculationParametersOf_BU_M AS CheckingCalculationParameters
	|			ON CheckingCalculationParameters.AccountingObject = ListOfIA.IntangibleAsset
	|				AND CheckingCalculationParameters.Organization = ListOfIA.Organization
	|
	|	WHERE
	|		NOT ListOfIA.ThisIsAnAdditionalAccrual
	|		AND CheckingCalculationParameters.AccountingObject IS NULL
	|
	|	) AS ListOfIA
	|";
	
	RequestTextParameters = QueryTextParametersAmountOfMaDepreciation();
	RequestTextParameters.TextCost = "ListOfIA.LocalCost";
	RequestTextParameters.TextDepreciation = "ListOfIA.DepreciationLocal";
	RequestTextParameters.TextResidualValue = "ListOfIA.NetBookValueLocal";
	RequestTextParameters.TextInitialCost = "ListOfIA.InitialCostOfLocal";
	RequestTextParameters.TextLiquidationValue = "ListOfIA.ResidualValueLocal";
	RequestTextParameters.TextImpairment = "ListOfIA.ImpairmentBalanceLocal";
	RequestTextParameters.TextAmountOfAdditionalCharge = "ISNULL(AdditionalCharges.AmountAccounting, 0)";
	
	TextACDepreciationAmount = QueryTextAmountOfMaDepreciation(RequestTextParameters);
	QueryText = StrReplace(QueryText, "&AmountOfACDepreciation", TextACDepreciationAmount);
	
	TextACImpairment = QueryTextAmountOfImpairment("ListOfIA.ImpairmentBalanceLocal");
	QueryText = StrReplace(QueryText, "&ImpairmentAC", TextACImpairment);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	IntangibleAssetAmortizationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);

	Query.Execute();
	
EndProcedure

Procedure CalculateDepreciation_ForCurrentMonth_TakingIntoAccountChangesInAC(CalculationParameters)
	
	QueryText = 
	"SELECT
	|	1 AS Priority,
	|	DATETIME(1,1,1) AS Period,
	|	UNDEFINED AS Recorder,
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.Department AS Department,
	|	ListOfIA.FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	ListOfIA.ExpenseItem AS ExpenseItem,
	|	ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	0 AS AmountOfUU,
	|	ListOfIA.AmountAccounting AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|
	|	0 AS ImpairmentMA,
	|	ListOfIA.ImpairmentAC AS ImpairmentAC,
	|
	|	1 AS ZoomRatio,
	|	ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned,
	|	ListOfIA.DepreciationMethod,
	|	0 AS ResidualValueMan,
	|	ListOfIA.ResidualValueLocal,
	|	ListOfIA.AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization,
	|
	|	ListOfIA.LocalCost AS LocalCost,
	|
	|	ListOfIA.ImpairmentBalanceLocal AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
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
	|
	|	CASE 
	|		WHEN BEGINOFPERIOD(ListOfIA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfIA.DepreciationLocal + ISNULL(AdditionalCharges.AmountAccounting, 0) 
	|		ELSE ListOfIA.DepreciationLocal
	|	END AS DepreciationLocal,
	|
	|	0 AS DepreciationPermanentDifferences,
	|
	|	0 AS CostUsedToCalculateDepreciationManag,
	|	ListOfIA.LocalCost - ListOfIA.DepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|	FALSE AS ACCostAdjustment,
	|	FALSE AS ACDepreciationAdjustment,
	|	UNDEFINED AS RevaluationMethod,
	|	FALSE AS RevaluateAtFairValue,
	|	FALSE AS TheseAreChanges
	|FROM
	|	CalculationOfDepreciation_ForCurrentMonth_UnchangedBU_MU AS ListOfIA
	|
	|		LEFT JOIN CalculationOfDepreciation_ForLastMonthBU_MU_Grouped AS AdditionalCharges
	|		ON AdditionalCharges.IntangibleAsset = ListOfIA.IntangibleAsset
	|
	|WHERE
	|	ListOfIA.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfNMASWithChangedParameters_BU_MU AS ListOfIA)
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS Priority,
	|	ListOfIA.Period,
	|	ListOfIA.Recorder,
	|	ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.Organization,
	|	ListOfIA.Department,
	|	ListOfIA.FinancialAccountingGroup,
	|	ListOfIA.LineOfBusiness,
	|	ListOfIA.IntangibleAsset,
	|	ListOfIA.ExpenseItem,
	|	ListOfIA.DimensionOfExpenses,
	|	ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	ListOfIA.DepreciationRecordMethod,
	|
	|	0 AS AmountOfUU,
	|	0 AS AmountAccounting,
	|	0 AS AmountPermanentDifferences,
	|
	|	0 AS ImpairmentMA,
	|	0 AS ImpairmentAC,
	|
	|	1 AS ZoomRatio,
	|	ListOfIA.TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses,
	|	ListOfIA.LifeSpentPastPeriod,
	|	ListOfIA.LifeSpentCurrentPeriod,
	|	ListOfIA.ResourceAssigned,
	|	ListOfIA.DepreciationMethod,
	|	0,
	|	ListOfIA.ResidualValueLocal,
	|	ListOfIA.AccelerationFactor,
	|	ListOfIA.WorkedMonthsFullYears,
	|	ListOfIA.AccrueDepreciationOrAmortization,
	|
	|	ListOfIA.LocalCost AS LocalCost,
	|
	|	ListOfIA.ImpairmentBalanceLocal AS ImpairmentLocalAssets,
	|	0 AS ImpairmenMan,
	|
	|	0 AS CostUpdate,
	|	ListOfIA.LocalCostUpdate AS LocalCostUpdate,
	|	0 AS CostPermanentDifferenceUpdate,
	|
	|	0 AS DepreciationUpdate,
	|	ListOfIA.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|	0 AS DepreciationPermanentDifferencesUpdate,
	|
	|	0 AS Depreciation,
	|
	|	CASE 
	|		WHEN BEGINOFPERIOD(ListOfIA.Period, MONTH) = &BegOfMonth
	|			THEN ListOfIA.DepreciationLocal + ISNULL(AdditionalCharges.AmountAccounting, 0) 
	|		ELSE ListOfIA.DepreciationLocal
	|	END AS DepreciationLocal,
	|
	|	0 AS DepreciationPermanentDifferences,
	|
	|	0,
	|	ListOfIA.LocalCost - ListOfIA.DepreciationLocal,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	|	ISNULL(Adjusting.CostAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInLocalAccounting, FALSE) AS ACCostAdjustment,
	|
	|	ISNULL(Adjusting.DepreciationAdjustment, FALSE)
	|		AND ISNULL(Adjusting.RecordInLocalAccounting, FALSE) AS ACDepreciationAdjustment,
	|
	|	ListOfIA.RevaluationMethod AS RevaluationMethod,
	|	ISNULL(Revaluation.RevaluateAtFairValue, FALSE) AS RevaluateAtFairValue,
	|
	|	TRUE AS TheseAreChanges
	|
	|FROM
	|	ListOfNMASWithChangedParameters_BU_MU AS ListOfIA
	|
	|		LEFT JOIN CalculationOfDepreciation_ForLastMonthBU_MU_Grouped AS AdditionalCharges
	|		ON AdditionalCharges.IntangibleAsset = ListOfIA.IntangibleAsset
	|
	|		LEFT JOIN CheckingParametersOfCalculationOfChangeOf_BU_M AS CheckingCalculationParameters
	|		ON CheckingCalculationParameters.AccountingObject = ListOfIA.IntangibleAsset
	|			AND CheckingCalculationParameters.Organization = ListOfIA.Organization
	|
	|		LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment AS Adjusting
	|		ON Adjusting.Ref = ListOfIA.Recorder
	|
	|		LEFT JOIN Document.IARevaluation2_4 AS Revaluation
	|		ON Revaluation.Ref = ListOfIA.Recorder
	|
	|WHERE
	|	NOT ListOfIA.ThisIsAnAdditionalAccrual
	|	AND CheckingCalculationParameters.AccountingObject IS NULL
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	IntangibleAssetAmortizationCalculation.SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters);
	
	QueryResult = Query.Execute();
	
	AmortizationOfChanges = CalculateDepreciationWhenParametersChange(QueryResult.Unload());
	
	QueryText = 
	"SELECT
	|	DepreciationCalculation.KindOfAccountingObject AS KindOfAccountingObject,
	|	DepreciationCalculation.Period AS Period,
	|	DepreciationCalculation.Organization AS Organization,
	|	DepreciationCalculation.Department AS Department,
	|	DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|	DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
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
	|
	|	CASE
	|		WHEN DepreciationCalculation.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)
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
	|	DepreciationCalculation.TheseAreChanges";

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
// 	
// Returns:
// 	ValueTable - 
Function CalculateDepreciationWhenParametersChange(AmortizationOfChanges) Export

	If AmortizationOfChanges.Count() = 0 Then
		Return AmortizationOfChanges;
	EndIf;
	
	AmortizationOfChanges.Sort("TheseAreChanges,Period,Priority");
	
	// Stores the calculation parameters that were used in the previous calculation.
	ValuesOfParametersForCalculatingChanges = New Map;
	
	ThereIsMA = AmortizationOfChanges.Columns.Find("Cost") <> Undefined;
	ThereIsAC = AmortizationOfChanges.Columns.Find("LocalCost") <> Undefined;
	HasTA = AmortizationOfChanges.Columns.Find("CostInTaxAccounting") <> Undefined;
	ThereIsPD = AmortizationOfChanges.Columns.Find("CostPermanentDifference") <> Undefined;
	
	For Each RowData In AmortizationOfChanges Do
		
		ParameterValues = ValuesOfParametersForCalculatingChanges.Get(RowData.IntangibleAsset);
		
		If ParameterValues = Undefined Then
			
			ParameterValues = New Structure;
			
			// Cost and depreciation as of the settlement date.
			// It may change during revaluation, write-off, etc.
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
			
			ValuesOfParametersForCalculatingChanges.Insert(RowData.IntangibleAsset, ParameterValues);
			
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
		
		If RowData.TheseAreChanges Then

			If TypeOf(RowData.Recorder) = Type("DocumentRef.IARevaluation2_4") Then
				
				// It is necessary to calculate the residual value as this is done by revaluation.
				
				If ThereIsMA Then
					
					RevaluationResult = NonCurrentAssetsInternal.RevaluationResult(
						ParameterValues.Cost, 
						ParameterValues.Depreciation + ParameterValues.DepreciationForPeriodOfMan, 
						ParameterValues.ImpairmenMan, 
						RowData.CostUpdate, 
						RowData.RevaluationMethod, 
						RowData.RevaluateAtFairValue);
					
					ParameterValues.Cost = ParameterValues.Cost + RevaluationResult.ChangeInValue;
					ParameterValues.Depreciation = ParameterValues.Depreciation + RevaluationResult.ChangeInDepreciation;
					ParameterValues.ImpairmenMan = ParameterValues.ImpairmenMan + RevaluationResult.ChangeOfImpairment;
					
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
				
				EndIf;

			ElsIf TypeOf(RowData.Recorder) = Type("DocumentRef.DisposeIntangibleAssets2_4") Then
				
				If RowData.AccrueDepreciationOrAmortization Then
					
					// Depreciation reduction is proportional to the written-off cost.
					If ThereIsMA And ParameterValues.Cost <> 0 Then
						
						PercentageOfWriteOffs = Round(-RowData.CostUpdate / ParameterValues.Cost, 12);
						DepreciationUpdate = Round((ParameterValues.Depreciation + ParameterValues.DepreciationForPeriodOfMan) * PercentageOfWriteOffs, 2);
						
						ParameterValues.Depreciation = ParameterValues.Depreciation - DepreciationUpdate;
						ParameterValues.DepreciationUpdate = -DepreciationUpdate;
						
					EndIf; 
						
					If ThereIsAC And ParameterValues.LocalCost <> 0 Then
						
						PercentageOfWriteOffs = Round(-RowData.LocalCostUpdate / ParameterValues.LocalCost, 12);
						DepreciationUpdate = Round((ParameterValues.DepreciationLocal + ParameterValues.DepreciationForPeriodOfLocal) * PercentageOfWriteOffs, 2);
						
						ParameterValues.DepreciationLocal = ParameterValues.DepreciationLocal - DepreciationUpdate;
						ParameterValues.DepreciationLocalUpdate = -DepreciationUpdate;
						
					EndIf; 
					
					If HasTA And ParameterValues.CostInTaxAccounting <> 0 Then
						
						PercentageOfWriteOffs = Round(-RowData.CostInTaxAccountingUpdate / ParameterValues.CostInTaxAccounting, 12);
						DepreciationUpdate = Round((ParameterValues.DepreciationInTaxAccounting + ParameterValues.DepreciationForPeriodTA) * PercentageOfWriteOffs, 2);
						
						ParameterValues.DepreciationInTaxAccounting = ParameterValues.DepreciationInTaxAccounting - DepreciationUpdate;
						ParameterValues.DepreciationInTaxAccountingUpdate = -DepreciationUpdate;
						
					EndIf; 
					
					If ThereIsPD And ParameterValues.CostPermanentDifference <> 0 Then
						
						PercentageOfWriteOffs = Round(-RowData.CostPermanentDifferenceUpdate / ParameterValues.CostPermanentDifference, 12);
						DepreciationUpdate = Round((ParameterValues.DepreciationPermanentDifferences + ParameterValues.DepreciationForPeriodOfPD) * PercentageOfWriteOffs, 2);
						
						ParameterValues.DepreciationPermanentDifferences = ParameterValues.DepreciationPermanentDifferences - DepreciationUpdate;
						ParameterValues.DepreciationPermanentDifferencesUpdate = -DepreciationUpdate;
						
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
					
			ElsIf TypeOf(RowData.Recorder) = Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment") Then
				
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
		
				If ThereIsPD
					And (RowData.ACCostAdjustment
						Or RowData.CostPermanentDifferenceUpdate <> 0) Then
					
					ParameterValues.CostPermanentDifference = RowData.CostPermanentDifferenceUpdate;
					
				EndIf;
		
				If ThereIsMA
					And (RowData.MADepreciationAdjustment
						Or RowData.DepreciationUpdate <> 0) Then
					
					ParameterValues.Depreciation = RowData.DepreciationUpdate;
					
					ParameterValues.DepreciationForPeriodOfMan = 0;
					
				EndIf;
				
				If ThereIsAC
					And (RowData.ACDepreciationAdjustment
						Or RowData.DepreciationLocalUpdate <> 0) Then
					
					ParameterValues.DepreciationLocal = RowData.DepreciationLocalUpdate;
					
					ParameterValues.DepreciationForPeriodOfLocal = 0;
					
				EndIf;
				
				If ThereIsAC
					And (RowData.ACDepreciationAdjustment
						Or RowData.DepreciationPermanentDifferencesUpdate <> 0) Then
					
					ParameterValues.DepreciationPermanentDifferences = RowData.DepreciationPermanentDifferencesUpdate;
					
					ParameterValues.DepreciationForPeriodOfPD = 0;
					
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
			
			// The cost that is used to calculate depreciation.
			RowData.CostUsedToCalculateDepreciationManag = ParameterValues.Cost - ParameterValues.Depreciation;
			RowData.CostUsedToCalculateDepreciationLocal = ParameterValues.LocalCost - ParameterValues.DepreciationLocal;
			
			// Calculation of the depreciation amount according to the formula.
			
			ImpairmentMA = ?(
				RowData.PostingOptionForImpairedFADepreciation = Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment, 
				ParameterValues.ImpairmenMan, 
				0);
			
			ImpairmentAC = ?(
				RowData.PostingOptionForImpairedFADepreciation = Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment, 
				ParameterValues.ImpairmentLocalAssets, 
				0);
			
			RowData.AmountOfUU = CalculateAmountOfDepreciationOfMa(
										RowData, 
										RowData.CostUsedToCalculateDepreciationManag, 
										RowData.ResidualValueMan, 
										ImpairmentMA, 
										ParameterValues.DepreciationForPeriodOfMan,
										NonCurrentAssetsInternal.MinimumResidualValueOfUpr());
			
			RowData.AmountAccounting = CalculateAmountOfDepreciationOfMa(
										RowData, 
										RowData.CostUsedToCalculateDepreciationLocal, 
										RowData.ResidualValueLocal, 
										ImpairmentAC, 
										ParameterValues.DepreciationForPeriodOfLocal,
										NonCurrentAssetsInternal.MinimumResidualValueOfRegl());
										
			// Calculation of the amount of impairment according to the formula.
			RowData.ImpairmentMA = CalculateAmountOfImpairment(
										RowData, 
										ParameterValues.ImpairmenMan,
										ParameterValues.ImpairmentForMonthOfMan,
										NonCurrentAssetsInternal.MinimumResidualValueOfUpr());
			
			RowData.ImpairmentAC = CalculateAmountOfImpairment(
										RowData, 
										ParameterValues.ImpairmentLocalAssets,
										ParameterValues.ImpairmentForMonthLocal,
										NonCurrentAssetsInternal.MinimumResidualValueOfRegl());
										
			// Calculation of PD
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

Function CalculateAmountOfDepreciationOfMa(RowData, NetBookValue, ResidualValueMan, ImpairmentBalance, AccruedDepreciationForMonth, MinimumResidualValue)

	AmountOfUU = 0;
	
	ResidualValueAfterDepreciation =
		(NetBookValue
			- AccruedDepreciationForMonth 
			- ResidualValueMan);
				
	If Not RowData.AccrueDepreciationOrAmortization 
		Or ResidualValueAfterDepreciation <= 0
		Or RowData.ResourceAssigned <= 0 Then
		
		AmountOfUU = 0;
		
	ElsIf (RowData.LifeSpentPastPeriod + RowData.LifeSpentCurrentPeriod) >= RowData.ResourceAssigned Then
		
		AmountOfUU = NetBookValue - ImpairmentBalance - ResidualValueMan;
		
	ElsIf RowData.DepreciationMethod = Enums.AccrualMethodOfIntangibleAssetDepreciation.Linear
		Or RowData.DepreciationMethod = Enums.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction Then
		
		AmountOfUU = (NetBookValue - ResidualValueMan - ImpairmentBalance)
					* (RowData.LifeSpentCurrentPeriod)
					/ (RowData.ResourceAssigned - RowData.LifeSpentPastPeriod);
		
	ElsIf RowData.DepreciationMethod = Enums.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance Then
		
		ZoomRatio = RowData.ResourceAssigned - RowData.LifeSpentPastPeriod + RowData.AccelerationFactor - 1;
							
		If ZoomRatio <> 0 Then
			
			AmountOfUU = (NetBookValue - ResidualValueMan - ImpairmentBalance)
						* RowData.LifeSpentCurrentPeriod
						* RowData.AccelerationFactor
						/ ZoomRatio;
					
		EndIf;
		
	EndIf; 
	
	If AmountOfUU > ResidualValueAfterDepreciation
		Or (ResidualValueAfterDepreciation - AmountOfUU) < MinimumResidualValue Then
		AmountOfUU = Max(ResidualValueAfterDepreciation, 0);
	EndIf; 
	
	Return Round(AmountOfUU, 2);
	
EndFunction

Function CalculateAmountOfImpairment(RowData, BalanceImpairment, AccruedImpairmentForMonth, MinimumResidualValue)

	AmountOfImpairment = 0;
	
	ImpairmentBalanceAfterAccrual = BalanceImpairment - AccruedImpairmentForMonth;
	
	If Not RowData.AccrueDepreciationOrAmortization 
		Or ImpairmentBalanceAfterAccrual <= 0
		Or BalanceImpairment <= 0 Then
		
		AmountOfImpairment = 0;
		
	ElsIf (RowData.LifeSpentPastPeriod + RowData.LifeSpentCurrentPeriod) >= RowData.ResourceAssigned Then
		
		AmountOfImpairment = BalanceImpairment;
		
	ElsIf RowData.DepreciationMethod = Enums.AccrualMethodOfIntangibleAssetDepreciation.Linear
		Or RowData.DepreciationMethod = Enums.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction Then
		
		AmountOfImpairment = BalanceImpairment
					* (RowData.LifeSpentCurrentPeriod)
					/ (RowData.ResourceAssigned - RowData.LifeSpentPastPeriod);
		
	ElsIf RowData.DepreciationMethod = Enums.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance Then
		
		ZoomRatio = RowData.ResourceAssigned - RowData.LifeSpentPastPeriod + RowData.AccelerationFactor - 1;
		
		If ZoomRatio <> 0 Then
			
			AmountOfImpairment = 
				BalanceImpairment
				* RowData.LifeSpentCurrentPeriod
				* RowData.AccelerationFactor
				/ ZoomRatio;
			
		EndIf;
		
	EndIf; 
	
	If AmountOfImpairment > ImpairmentBalanceAfterAccrual
		Or (ImpairmentBalanceAfterAccrual - AmountOfImpairment) < MinimumResidualValue Then
		AmountOfImpairment = Max(ImpairmentBalanceAfterAccrual, 0);
	EndIf; 
	
	Return Round(AmountOfImpairment, 2);
	
EndFunction

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
	|	DepreciationPackages.IntangibleAsset AS AccountingObject
	|
	|INTO ObjectsOfDepreciationPackages
	|
	|FROM
	|	InformationRegister.IntangibleAssetAmortizationPackages AS DepreciationPackages
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
	|		DocumentData.Organization,
	|		TableOfIA.IntangibleAsset
	|	FROM
	|		Document.IATransfer2_4 AS DocumentData
	|
	|			INNER JOIN Document.IATransfer2_4.IA AS TableOfIA
	|			ON (TableOfIA.Ref = DocumentData.Ref)
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BeginningOfPreviousMonth AND &EndOfMonth
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|		AND DocumentData.Posted
	|
	|		AND (DocumentData.CompanyRecipient, TableOfIA.IntangibleAsset) IN
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

	QueryText = IntangibleAssetsAmortizationChargeLocalization.QueryTextListOfAccountingObjects(CalculationParameters);
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT DISTINCT
		|	ListOfIA.BegOfMonth                        AS BegOfMonth,
		|	ListOfIA.EndOfMonth                         AS EndOfMonth,
		|	ListOfIA.Organization                         AS Organization,
		|	ListOfIA.IntangibleAsset                 AS IntangibleAsset,
		|	ListOfIA.DepreciationRecordMethod          AS DepreciationRecordMethod,
		|	ISNULL(IntangibleAssetAmortizationPackages.PackageNumber, 0) AS PackageNumber,
		|
		|	ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting,
		|	TRUE AS DepreciationIsCalculatedAccordingToINTStandards
		|
		|INTO ListOfAccountingObjects
		|
		|FROM
		|	ListOfAccountingObjects_ AS ListOfIA
		|
		|		LEFT JOIN InformationRegister.IntangibleAssetAmortizationPackages AS IntangibleAssetAmortizationPackages
		|		ON IntangibleAssetAmortizationPackages.Organization = ListOfIA.Organization
		|			AND IntangibleAssetAmortizationPackages.IntangibleAsset = ListOfIA.IntangibleAsset
		|
		|UNION
		|
		|SELECT DISTINCT
		|	ListOfIA.BegOfMonth                        AS BegOfMonth,
		|	ListOfIA.EndOfMonth                         AS EndOfMonth,
		|	ListOfIA.Organization                         AS Organization,
		|	ListOfIA.IntangibleAsset                 AS IntangibleAsset,
		|	ListOfIA.DepreciationRecordMethod          AS DepreciationRecordMethod,
		|	ISNULL(IntangibleAssetAmortizationPackages.PackageNumber, 0) AS PackageNumber,
		|
		|	ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting,
		|	TRUE AS DepreciationIsCalculatedAccordingToINTStandards
		|
		|FROM
		|	ListOfAccountingObjects_BU_MU AS ListOfIA
		|
		|		LEFT JOIN InformationRegister.IntangibleAssetAmortizationPackages AS IntangibleAssetAmortizationPackages
		|		ON IntangibleAssetAmortizationPackages.Organization = ListOfIA.Organization
		|			AND IntangibleAssetAmortizationPackages.IntangibleAsset = ListOfIA.IntangibleAsset
		|
		|INDEX BY
		|	IntangibleAsset,
		|	Organization";
		
	EndIf; 
	
	ListOfRequests.Add(QueryText);
	
	QueryText =
	"SELECT DISTINCT
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset
	|
	|INTO ListOfAccountingItemsFromDateOfAcceptanceForAccounting
	|
	|FROM
	|	ListOfAccountingObjects AS ListOfIA
	|
	|WHERE
	|	ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization";

	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextListOfAllIA(ListOfRequests, CalculationParameters)

	#Region ObjectsThatDoNotNeedToBeDepreciated
	QueryText = 
	"SELECT
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	ObjectsTable.IntangibleAsset AS AccountingObject
	|
	|INTO ObjectsThatDoNotNeedToBeDepreciated
	|
	|FROM
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment AS DocumentData
	|	
	|		INNER JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment.IA AS ObjectsTable
	|		ON ObjectsTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.IncludesDepreciationOfCurrentMonth
	|	AND DocumentData.Posted
	|
	|	AND (DocumentData.Organization, ObjectsTable.IntangibleAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
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
	|	AccountingPolicy.IntangibleAssetRevaluationMethod AS IntangibleAssetRevaluationMethod,
	|	AccountingPolicy.ProcedureOfIntangibleAssetAmortizationCharge AS ProcedureOfIntangibleAssetAmortizationCharge,
	|	AccountingPolicy.ProcedureOfIntangibleAssetAmortizationChargeLocal AS ProcedureOfIntangibleAssetAmortizationChargeLocal
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
	|	AccountingPolicy.IntangibleAssetRevaluationMethod AS IntangibleAssetRevaluationMethod,
	|	AccountingPolicy.ProcedureOfIntangibleAssetAmortizationCharge AS ProcedureOfIntangibleAssetAmortizationCharge,
	|	AccountingPolicy.ProcedureOfIntangibleAssetAmortizationChargeLocal AS ProcedureOfIntangibleAssetAmortizationChargeLocal
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
	
	IntangibleAssetsAmortizationChargeLocalization.AddListOfAllIAToRequestText(ListOfRequests, CalculationParameters);
	
	#Region ListOfAccountingItems_AdditionalCharges_u
	
	QueryText = 
	"SELECT
	|	IACost.Organization      AS Organization,
	|	IACost.IntangibleAsset AS IntangibleAsset,
	|	MIN(IACost.Period)  AS Period
	|
	|INTO ListOfAccountingItems_AdditionalCharges_u
	|
	|FROM
	|	AccumulationRegister.IACost AS IACost
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = IACost.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfPreviousMonth
	|
	|WHERE
	|	IACost.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND IACost.Active
	|	AND IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|	AND IACost.RecordInManAccounting
	|	AND ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
	|	AND ISNULL(AccountingPolicy.ProcedureOfIntangibleAssetAmortizationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|
	|	AND IACost.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetsInitialRecognition),
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetImprovement),
	|			VALUE(Enum.BusinessTransactions.IncludeAdditionalExpensesInIntangibleAssetCost))
	|
	|	AND (IACost.Organization, IACost.IntangibleAsset) IN
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
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = IACost.IntangibleAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInManAccounting)
	|
	|GROUP BY
	|	IACost.Organization,
	|	IACost.IntangibleAsset
	|
	|HAVING
	|	SUM(IACost.Cost - IACost.PreliminaryCostMan) <> 0
	|		OR &ThisIsInternationalVersion 
	|			AND SUM(IACost.LocalCost - IACost.PreliminaryCostLocal) <> 0
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfAccountingObjects_AdditionalCharge_BU_MU
	
	QueryText = 
	"SELECT
	|	IACost.Organization      AS Organization,
	|	IACost.IntangibleAsset AS IntangibleAsset,
	|	MIN(IACost.Period)  AS Period
	|
	|INTO ListOfAccountingObjects_AdditionalCharge_BU_MU
	|
	|FROM
	|	AccumulationRegister.IACost AS IACost
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = IACost.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfPreviousMonth
	|
	|WHERE
	|	IACost.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND IACost.Active
	|	AND IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|	AND IACost.RecordInLocalAccounting
	|	AND &ThisIsInternationalVersion
	|	AND ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|	AND ISNULL(AccountingPolicy.ProcedureOfIntangibleAssetAmortizationChargeLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|
	|	AND IACost.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetsInitialRecognition),
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetImprovement),
	|			VALUE(Enum.BusinessTransactions.IncludeAdditionalExpensesInIntangibleAssetCost))
	|
	|	AND (IACost.Organization, IACost.IntangibleAsset) IN
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
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = IACost.IntangibleAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInLocalAccounting)
	|
	|GROUP BY
	|	IACost.Organization,
	|	IACost.IntangibleAsset
	|
	|HAVING
	|	SUM(IACost.LocalCost - IACost.PreliminaryCostLocal) <> 0
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfAccountingObjects_
		
	QueryText = 
	"SELECT
	|	&EndOfMonth                        AS AccrualPeriod,
	|	&BegOfMonth                       AS BegOfMonth,
	|	&EndOfMonth                        AS EndOfMonth,
	|	&EndOfPreviousMonth             AS Period,
	|	&EndOfPreviousMonth             AS ParameterPeriod,
	|	FALSE                                AS ThisIsAnAdditionalAccrual,
	|	IntangibleAssetsAccountingProcedure.Organization         AS Organization,
	|	IntangibleAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS IntangibleAsset,
	|
	|	IntangibleAssetsAccountingProcedure.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|
	|	IntangibleAssetsAccountingProcedure.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	IntangibleAssetsAccountingProcedure.ExpenseItem    AS ExpenseItem,
	|	IntangibleAssetsAccountingProcedure.DimensionOfExpenses AS DimensionOfExpenses,
	|	IntangibleAssetsAccountingProcedure.Department AS ExpensesBusinessUnit,
	|	IntangibleAssetsAccountingProcedure.LineOfBusiness AS ExpenseLineOfBusiness,
	|
	|	IntangibleAssetsAccountingProcedure.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	IntangibleAssetsAccountingProcedure.CompanyRecipientOfExpenses       AS CompanyRecipientOfExpenses,
	|
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.IntangibleAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	(ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) 
	|		= VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS DepreciationIsCalculatedAccordingToINTStandards,
	|
	|	(ISNULL(AccountingPolicy.ProcedureOfIntangibleAssetAmortizationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) 
	|		= VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|INTO ListOfAccountingObjects_
	|
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&EndOfPreviousMonth,
	|			(Organization, IntangibleAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)) AS IntangibleAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = IntangibleAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfMonth
	|
	|WHERE
	|	NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = IntangibleAssetsAccountingProcedure.IntangibleAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInManAccounting)
	|
	|UNION
	|
	|SELECT
	|	&EndOfMonth                        AS AccrualPeriod,
	|	&BegOfMonth                       AS BegOfMonth,
	|	&EndOfMonth                        AS EndOfMonth,
	|	BEGINOFPERIOD(IntangibleAssetsAccountingProcedure.Period, DAY) AS Period,
	|	BEGINOFPERIOD(IntangibleAssetsAccountingProcedure.Period, DAY) AS ParameterPeriod,
	|	FALSE                                AS ThisIsAnAdditionalAccrual,
	|	IntangibleAssetsAccountingProcedure.Organization         AS Organization,
	|	IntangibleAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS IntangibleAsset,
	|
	|	IntangibleAssetsAccountingProcedure.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|
	|	IntangibleAssetsAccountingProcedure.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	IntangibleAssetsAccountingProcedure.ExpenseItem    AS ExpenseItem,
	|	IntangibleAssetsAccountingProcedure.DimensionOfExpenses AS DimensionOfExpenses,
	|	IntangibleAssetsAccountingProcedure.Department AS ExpensesBusinessUnit,
	|	IntangibleAssetsAccountingProcedure.LineOfBusiness AS ExpenseLineOfBusiness,
	|
	|	IntangibleAssetsAccountingProcedure.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	IntangibleAssetsAccountingProcedure.CompanyRecipientOfExpenses       AS CompanyRecipientOfExpenses,
	|
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.IntangibleAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	(ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) 
	|		= VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS DepreciationIsCalculatedAccordingToINTStandards,
	|
	|	(ISNULL(AccountingPolicy.ProcedureOfIntangibleAssetAmortizationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) 
	|		= VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS IntangibleAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = IntangibleAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfMonth
	|
	|WHERE
	|	IntangibleAssetsAccountingProcedure.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND IntangibleAssetsAccountingProcedure.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|
	|	AND (IntangibleAssetsAccountingProcedure.Organization, IntangibleAssetsAccountingProcedure.IntangibleAsset) IN
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
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = IntangibleAssetsAccountingProcedure.IntangibleAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInManAccounting)
	|
	|UNION
	|
	|SELECT
	|	&EndOfMonth                        AS AccrualPeriod,
	|	&BeginningOfPreviousMonth            AS BegOfMonth,
	|	&EndOfPreviousMonth             AS EndOfMonth,
	|	BEGINOFPERIOD(IntangibleAssetsAccountingProcedure.Period, DAY) AS Period,
	|	BEGINOFPERIOD(IntangibleAssetsAccountingProcedure.Period, DAY) AS ParameterPeriod,
	|	TRUE                              AS ThisIsAnAdditionalAccrual,
	|	IntangibleAssetsAccountingProcedure.Organization         AS Organization,
	|	IntangibleAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS IntangibleAsset,
	|
	|	IntangibleAssetsAccountingProcedure.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|
	|	IntangibleAssetsAccountingProcedure.DepreciationRecordMethod AS DepreciationRecordMethod,
	|
	|	IntangibleAssetsAccountingProcedure.ExpenseItem    AS ExpenseItem,
	|	IntangibleAssetsAccountingProcedure.DimensionOfExpenses AS DimensionOfExpenses,
	|	IntangibleAssetsAccountingProcedure.Department AS ExpensesBusinessUnit,
	|	IntangibleAssetsAccountingProcedure.LineOfBusiness AS ExpenseLineOfBusiness,
	|
	|	IntangibleAssetsAccountingProcedure.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	IntangibleAssetsAccountingProcedure.CompanyRecipientOfExpenses       AS CompanyRecipientOfExpenses,
	|
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.IntangibleAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	(ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) 
	|		= VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS DepreciationIsCalculatedAccordingToINTStandards,
	|
	|	(ISNULL(AccountingPolicy.ProcedureOfIntangibleAssetAmortizationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) 
	|		= VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS IntangibleAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = IntangibleAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfPreviousMonth
	|
	|WHERE
	|	IntangibleAssetsAccountingProcedure.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|
	|	AND VALUETYPE(IntangibleAssetsAccountingProcedure.Recorder) IN (
	|				TYPE(Document.IntangibleAssetsInitialRecognition2_4),
	|				TYPE(Document.IntangibleAssetImprovement))
	|
	|	AND (IntangibleAssetsAccountingProcedure.Organization, IntangibleAssetsAccountingProcedure.IntangibleAsset) IN
	|				(SELECT
	|					ListOfIA.Organization,
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfAccountingItems_AdditionalCharges_u AS ListOfIA)
	|
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = IntangibleAssetsAccountingProcedure.IntangibleAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInManAccounting)
	|
	|INDEX BY
	|	IntangibleAsset, 
	|	Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfAccountingObjects_BU_MU
		
	QueryText = 
	"SELECT
	|	&EndOfMonth                        AS AccrualPeriod,
	|	&BegOfMonth                       AS BegOfMonth,
	|	&EndOfMonth                        AS EndOfMonth,
	|	&EndOfPreviousMonth             AS Period,
	|	&EndOfPreviousMonth             AS ParameterPeriod,
	|	FALSE                                AS ThisIsAnAdditionalAccrual,
	|	IntangibleAssetsAccountingProcedure.Organization         AS Organization,
	|	IntangibleAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS IntangibleAsset,
	|
	|	IntangibleAssetsAccountingProcedure.DepreciationAccrualAccounting AS AccrueDepreciationOrAmortization,
	|
	|	IntangibleAssetsAccountingProcedure.DepreciationRecordMethodLA AS DepreciationRecordMethod,
	|
	|	IntangibleAssetsAccountingProcedure.ExpenseItemAccounting    AS ExpenseItem,
	|	IntangibleAssetsAccountingProcedure.ExpensesDimensionAccounting AS DimensionOfExpenses,
	|	IntangibleAssetsAccountingProcedure.DepartmentACC AS ExpensesBusinessUnit,
	|	IntangibleAssetsAccountingProcedure.LineOfBusinessBookkeeping AS ExpenseLineOfBusiness,
	|
	|	IntangibleAssetsAccountingProcedure.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	IntangibleAssetsAccountingProcedure.CompanyRecipientOfExpenses       AS CompanyRecipientOfExpenses,
	|
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.IntangibleAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	TRUE AS DepreciationIsCalculatedAccordingToINTStandards,
	|
	|	(ISNULL(AccountingPolicy.ProcedureOfIntangibleAssetAmortizationChargeLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) 
	|		= VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|INTO ListOfAccountingObjects_BU_MU
	|
	|FROM
	|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
	|			&EndOfPreviousMonth,
	|			(Organization, IntangibleAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)) AS IntangibleAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = IntangibleAssetsAccountingProcedure.Organization.ParentCompany
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
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = IntangibleAssetsAccountingProcedure.IntangibleAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInLocalAccounting)
	|
	|UNION
	|
	|SELECT
	|	&EndOfMonth                        AS AccrualPeriod,
	|	&BegOfMonth                       AS BegOfMonth,
	|	&EndOfMonth                        AS EndOfMonth,
	|	BEGINOFPERIOD(IntangibleAssetsAccountingProcedure.Period, DAY) AS Period,
	|	BEGINOFPERIOD(IntangibleAssetsAccountingProcedure.Period, DAY) AS ParameterPeriod,
	|	FALSE                                AS ThisIsAnAdditionalAccrual,
	|	IntangibleAssetsAccountingProcedure.Organization         AS Organization,
	|	IntangibleAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS IntangibleAsset,
	|
	|	IntangibleAssetsAccountingProcedure.DepreciationAccrualAccounting AS AccrueDepreciationOrAmortization,
	|
	|	IntangibleAssetsAccountingProcedure.DepreciationRecordMethodLA AS DepreciationRecordMethod,
	|
	|	IntangibleAssetsAccountingProcedure.ExpenseItemAccounting    AS ExpenseItem,
	|	IntangibleAssetsAccountingProcedure.ExpensesDimensionAccounting AS DimensionOfExpenses,
	|	IntangibleAssetsAccountingProcedure.DepartmentACC     AS ExpensesBusinessUnit,
	|	IntangibleAssetsAccountingProcedure.LineOfBusinessBookkeeping AS ExpenseLineOfBusiness,
	|
	|	IntangibleAssetsAccountingProcedure.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	IntangibleAssetsAccountingProcedure.CompanyRecipientOfExpenses       AS CompanyRecipientOfExpenses,
	|
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.IntangibleAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	TRUE AS DepreciationIsCalculatedAccordingToINTStandards,
	|	TRUE AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|FROM
	|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS IntangibleAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = IntangibleAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfMonth
	|
	|WHERE
	|	IntangibleAssetsAccountingProcedure.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND &ThisIsInternationalVersion
	|	AND ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|	AND ISNULL(AccountingPolicy.ProcedureOfIntangibleAssetAmortizationChargeLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|
	|	AND IntangibleAssetsAccountingProcedure.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND (IntangibleAssetsAccountingProcedure.Organization, IntangibleAssetsAccountingProcedure.IntangibleAsset) IN
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
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = IntangibleAssetsAccountingProcedure.IntangibleAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInLocalAccounting)
	|
	|UNION
	|
	|SELECT
	|	&EndOfMonth                        AS AccrualPeriod,
	|	&BeginningOfPreviousMonth            AS BegOfMonth,
	|	&EndOfPreviousMonth             AS EndOfMonth,
	|	BEGINOFPERIOD(IntangibleAssetsAccountingProcedure.Period, DAY) AS Period,
	|	BEGINOFPERIOD(IntangibleAssetsAccountingProcedure.Period, DAY) AS ParameterPeriod,
	|	TRUE                              AS ThisIsAnAdditionalAccrual,
	|	IntangibleAssetsAccountingProcedure.Organization         AS Organization,
	|	IntangibleAssetsAccountingProcedure.Organization.ParentCompany AS ParentCompany,
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS IntangibleAsset,
	|
	|	IntangibleAssetsAccountingProcedure.DepreciationAccrualAccounting AS AccrueDepreciationOrAmortization,
	|
	|	IntangibleAssetsAccountingProcedure.DepreciationRecordMethodLA AS DepreciationRecordMethod,
	|
	|	IntangibleAssetsAccountingProcedure.ExpenseItemAccounting    AS ExpenseItem,
	|	IntangibleAssetsAccountingProcedure.ExpensesDimensionAccounting AS DimensionOfExpenses,
	|	IntangibleAssetsAccountingProcedure.DepartmentACC     AS ExpensesBusinessUnit,
	|	IntangibleAssetsAccountingProcedure.LineOfBusinessBookkeeping AS ExpenseLineOfBusiness,
	|
	|	IntangibleAssetsAccountingProcedure.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	IntangibleAssetsAccountingProcedure.CompanyRecipientOfExpenses       AS CompanyRecipientOfExpenses,
	|
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
	|	ISNULL(AccountingPolicy.IntangibleAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)) AS RevaluationMethod,
	|
	|	TRUE AS DepreciationIsCalculatedAccordingToINTStandards,
	|	TRUE AS DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|
	|FROM
	|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS IntangibleAssetsAccountingProcedure
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = IntangibleAssetsAccountingProcedure.Organization.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfPreviousMonth
	|
	|WHERE
	|	IntangibleAssetsAccountingProcedure.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|
	|	AND &ThisIsInternationalVersion
	|	AND ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|
	|	AND VALUETYPE(IntangibleAssetsAccountingProcedure.Recorder) IN (
	|				TYPE(Document.IntangibleAssetsInitialRecognition2_4),
	|				TYPE(Document.IntangibleAssetImprovement))
	|
	|	AND (IntangibleAssetsAccountingProcedure.Organization, IntangibleAssetsAccountingProcedure.IntangibleAsset) IN
	|				(SELECT
	|					ListOfIA.Organization,
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfAccountingObjects_AdditionalCharge_BU_MU AS ListOfIA)
	|
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE 
	|		FROM 
	|			ObjectsThatDoNotNeedToBeDepreciated AS ObjectsThatDoNotNeedToBeDepreciated
	|		WHERE
	|			ObjectsThatDoNotNeedToBeDepreciated.AccountingObject = IntangibleAssetsAccountingProcedure.IntangibleAsset
	|			AND ObjectsThatDoNotNeedToBeDepreciated.RecordInLocalAccounting)
	|
	|INDEX BY
	|	IntangibleAsset, 
	|	Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfAccountingItems_AdditionalCharges_All
	QueryText = IntangibleAssetsAmortizationChargeLocalization.RequestTextListOfAccountingObjectsAdditionalChargesAll();
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	ListOfAccountingObjects.Organization      AS Organization,
		|	ListOfAccountingObjects.IntangibleAsset AS IntangibleAsset,
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
		|	ListOfAccountingObjects.IntangibleAsset AS IntangibleAsset,
		|	ListOfAccountingObjects.Period           AS Period
		|
		|FROM
		|	ListOfAccountingObjects_AdditionalCharge_BU_MU AS ListOfAccountingObjects
		|
		|INDEX BY
		|	IntangibleAsset,
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

	AccountingObject = "IntangibleAsset";
	
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"IntangibleAssetsRegistrationPlace", "", AccountingObject, ListOfRequests);
	
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"InitialIntangibleAssetsInformation", "", AccountingObject, ListOfRequests);
	
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"IntangibleAssetsAccountingProcedure", "", AccountingObject, ListOfRequests);
	
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"IntangibleAssetsAccountingProcedureManagementAccounting", "", AccountingObject, ListOfRequests);
		
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"IABookkeepingProcedureBookkeepingAndTaxAccounting", "", AccountingObject, ListOfRequests);
		
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"IntangibleAssetAmortizationParametersManagementAccounting", "", AccountingObject, ListOfRequests);
		
	NonCurrentAssetsInternal.QueryTextDepreciationCalculationParameters(
		"IADepreciationParametersBookkeepingAndTaxAccounting", "", AccountingObject, ListOfRequests);
	
	#Region DatesWhenMaWasLastModified
	QueryText =
	"SELECT
	|	NestedQuery.BegOfMonth AS BegOfMonth,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.IntangibleAsset AS IntangibleAsset,
	|	
	|	MAX(NestedQuery.Date) AS Date,
	|	MAX(NestedQuery.DateOfDocumentOfAcceptanceForAccounting) AS DateOfDocumentOfAcceptanceForAccounting
	|
	|INTO DatesWhenMaWasLastModified
	|
	|FROM
	|	(SELECT
	|		IntangibleAssetAmortizationParametersManagementAccounting.BegOfMonth AS BegOfMonth,
	|		IntangibleAssetAmortizationParametersManagementAccounting.Organization AS Organization,
	|		IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset AS IntangibleAsset,
	|	
	|		CASE
	|			WHEN ISNULL(AccountingPolicy.ProcedureOfIntangibleAssetAmortizationCharge, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|				THEN IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate
	|
	|			ELSE BEGINOFPERIOD(DATEADD(IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate, MONTH, 1), MONTH)
	|
	|		END AS Date,
	|
	|		ISNULL(InitialIntangibleAssetsInformation.DocumentOfRecognitionManagementAccounting.DATE, DATETIME(1,1,1)) AS DateOfDocumentOfAcceptanceForAccounting
	|
	|	FROM
	|		IntangibleAssetAmortizationParametersManagementAccounting AS IntangibleAssetAmortizationParametersManagementAccounting
	|
	|			LEFT JOIN InitialIntangibleAssetsInformation AS InitialIntangibleAssetsInformation
	|			ON (InitialIntangibleAssetsInformation.Organization = IntangibleAssetAmortizationParametersManagementAccounting.Organization)
	|				AND (InitialIntangibleAssetsInformation.IntangibleAsset = IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset)
	|				AND (InitialIntangibleAssetsInformation.BegOfMonth = IntangibleAssetAmortizationParametersManagementAccounting.BegOfMonth)
	|
	|			LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|			ON AccountingPolicy.Organization = IntangibleAssetAmortizationParametersManagementAccounting.Organization.ParentCompany
	|				AND AccountingPolicy.Period = &EndOfMonth
	|
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.BegOfMonth,
	|	NestedQuery.Organization,
	|	NestedQuery.IntangibleAsset
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization,
	|	BegOfMonth";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DatesOfLastModifiedBy_BU_M
	QueryText =
	"SELECT
	|	NestedQuery.BegOfMonth AS BegOfMonth,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.IntangibleAsset AS IntangibleAsset,
	|	
	|	MAX(NestedQuery.Date) AS Date,
	|	MAX(NestedQuery.DateOfDocumentOfAcceptanceForAccounting) AS DateOfDocumentOfAcceptanceForAccounting
	|
	|INTO DatesOfLastModifiedBy_BU_M
	|
	|FROM
	|	(SELECT
	|		IADepreciationParametersBookkeepingAndTaxAccounting.BegOfMonth AS BegOfMonth,
	|		IADepreciationParametersBookkeepingAndTaxAccounting.Organization AS Organization,
	|		IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset AS IntangibleAsset,
	|	
	|		CASE
	|			WHEN ISNULL(AccountingPolicy.ProcedureOfIntangibleAssetAmortizationChargeLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|				THEN IADepreciationParametersBookkeepingAndTaxAccounting.LastChangeDate
	|
	|			ELSE BEGINOFPERIOD(DATEADD(IADepreciationParametersBookkeepingAndTaxAccounting.LastChangeDate, MONTH, 1), MONTH)
	|
	|		END AS Date,
	|
	|		ISNULL(InitialIntangibleAssetsInformation.DocumentOfRecognitionAccounting.DATE, DATETIME(1,1,1)) AS DateOfDocumentOfAcceptanceForAccounting
	|
	|	FROM
	|		IADepreciationParametersBookkeepingAndTaxAccounting AS IADepreciationParametersBookkeepingAndTaxAccounting
	|
	|			LEFT JOIN InitialIntangibleAssetsInformation AS InitialIntangibleAssetsInformation
	|			ON (InitialIntangibleAssetsInformation.Organization = IADepreciationParametersBookkeepingAndTaxAccounting.Organization)
	|				AND (InitialIntangibleAssetsInformation.IntangibleAsset = IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset)
	|				AND (InitialIntangibleAssetsInformation.BegOfMonth = IADepreciationParametersBookkeepingAndTaxAccounting.BegOfMonth)
	|
	|			LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|			ON AccountingPolicy.Organization = IADepreciationParametersBookkeepingAndTaxAccounting.Organization.ParentCompany
	|				AND AccountingPolicy.Period = &EndOfMonth
	|
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.BegOfMonth,
	|	NestedQuery.Organization,
	|	NestedQuery.IntangibleAsset
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization,
	|	BegOfMonth";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CostOfIAAtBeginningOfMonth
	
	QueryText = 
	"SELECT
	|	&BegOfMonth                             AS BegOfMonth,
	|	IACost.IntangibleAsset          AS IntangibleAsset,
	|	IACost.CostBalance             AS Cost,
	|	IACost.LocalCostBalance         AS LocalCost,
	|	IACost.CostInTaxAccountingBalance           AS CostInTaxAccounting,
	|	IACost.CostPermanentDifferenceBalance           AS CostPermanentDifference,
	|	IACost.CostTemporaryDifferenceBalance           AS CostTemporaryDifference,
	|	IACost.CostTargetFinancingBalance           AS CostTargetFinancing,
	|	IACost.CostTargetFinancingTABalance         AS CostTargetFinancingTA,
	|	IACost.CostTargetFinancingPDBalance         AS CostTargetFinancingPD,
	|	IACost.CostTargetFinancingTDBalance         AS CostTargetFinancingTD
	|
	|INTO CostOfNMA_AtBeginningOfMonth
	|
	|FROM
	|	AccumulationRegister.IACost.Balance(
	|			&EndOfPreviousMonthBorder,
	|			(Organization, IntangibleAsset) IN
	|				(SELECT
	|					ListOfIA.Organization,
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfAccountingObjects AS ListOfIA)) AS IACost
	|
	|INDEX BY
	|	IntangibleAsset";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
		
	#Region PreliminaryCostOfIa
	
	QueryText = 
	"SELECT
	|	&BegOfMonth                    AS BegOfMonth,
	|	IACost.IntangibleAsset AS IntangibleAsset,
	|
	|	MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostMA, ISNULL(IntangibleAssetImprovement.CostInManagementAccounting, 0))) AS CostInManagementAccounting,
	|	MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostLocalAccounting, ISNULL(IntangibleAssetImprovement.CostInAccounting, 0))) AS CostInAccounting,
	|	MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostPD, ISNULL(IntangibleAssetImprovement.CostPermanentDifference, 0))) AS CostPermanentDifference,
	|
	|	CASE
	|		WHEN MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostLocalAccounting, 0)) <> 0
	|			THEN CAST(MAX(ISNULL(IntangibleAssetsInitialRecognition.AmountOfTargetFunds, 0)) / MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostLocalAccounting, 0)) AS NUMBER (23, 10))
	|		ELSE 0
	|	END AS CFShare,
	|
	|	FALSE PreliminaryCostExceedsActualMA,
	|	FALSE PreliminaryCostExceedsActualAC,
	|	FALSE PreliminaryCostExceedsActualPD
	|
	|INTO PreliminaryCostOfIa
	|
	|FROM
	|	AccumulationRegister.IACost AS IACost
	|
	|		LEFT JOIN Document.IntangibleAssetsInitialRecognition2_4 AS IntangibleAssetsInitialRecognition
	|		ON IntangibleAssetsInitialRecognition.Ref = IACost.Recorder
	|
	|		LEFT JOIN Document.IntangibleAssetImprovement.IA AS IntangibleAssetImprovement
	|		ON IntangibleAssetImprovement.Ref = IACost.Recorder
	|			AND IntangibleAssetImprovement.IntangibleAsset = IACost.IntangibleAsset
	|
	|WHERE
	|	IACost.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND IACost.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.IntangibleAssetsInitialRecognition),
	|		VALUE(Enum.BusinessTransactions.IntangibleAssetsInitialRecognitionByInventoryCount),
	|		VALUE(Enum.BusinessTransactions.IntangibleAssetImprovement),
	|		VALUE(Enum.BusinessTransactions.IncludeAdditionalExpensesInIntangibleAssetCost))
	|
	|	AND IACost.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects AS ListOfIA)
	|
	|GROUP BY
	|	IACost.IntangibleAsset
	|	
	|UNION ALL
	|
	|SELECT
	|	&BeginningOfPreviousMonth              AS BegOfMonth,
	|	IACost.IntangibleAsset      AS IntangibleAsset,
	|
	|	CASE
	|		WHEN (SUM(IACost.Cost) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostMA, ISNULL(IntangibleAssetImprovement.CostInManagementAccounting, 0)))) > 0
	|			THEN SUM(IACost.Cost) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostMA, ISNULL(IntangibleAssetImprovement.CostInManagementAccounting, 0)))
	|		WHEN (SUM(IACost.Cost) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostMA, ISNULL(IntangibleAssetImprovement.CostInManagementAccounting, 0)))) < 0
	|			THEN -SUM(IACost.Cost) + MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostMA, ISNULL(IntangibleAssetImprovement.CostInManagementAccounting, 0)))
	|		ELSE 0
	|	END AS CostInManagementAccounting,
	|
	|	CASE
	|		WHEN (SUM(IACost.LocalCost) + SUM(IACost.CostTargetFinancing) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostLocalAccounting, ISNULL(IntangibleAssetImprovement.CostInAccounting, 0)))) > 0
	|			THEN SUM(IACost.LocalCost) + SUM(IACost.CostTargetFinancing) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostLocalAccounting, ISNULL(IntangibleAssetImprovement.CostInAccounting, 0)))
	|		WHEN (SUM(IACost.LocalCost) + SUM(IACost.CostTargetFinancing) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostLocalAccounting, ISNULL(IntangibleAssetImprovement.CostInAccounting, 0)))) < 0
	|			THEN -SUM(IACost.LocalCost) - SUM(IACost.CostTargetFinancing) + MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostLocalAccounting, ISNULL(IntangibleAssetImprovement.CostInAccounting, 0)))
	|		ELSE 0
	|	END AS CostInAccounting,
	|
	|	CASE
	|		WHEN (SUM(IACost.CostPermanentDifference) + SUM(IACost.CostTargetFinancingPD) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostPD, ISNULL(IntangibleAssetImprovement.CostPermanentDifference, 0)))) > 0
	|			THEN SUM(IACost.CostPermanentDifference) + SUM(IACost.CostTargetFinancingPD) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostPD, ISNULL(IntangibleAssetImprovement.CostPermanentDifference, 0)))
	|		WHEN (SUM(IACost.CostPermanentDifference) + SUM(IACost.CostTargetFinancingPD) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostPD, ISNULL(IntangibleAssetImprovement.CostPermanentDifference, 0)))) < 0
	|			THEN -SUM(IACost.CostPermanentDifference) - SUM(IACost.CostTargetFinancingPD) + MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostPD, ISNULL(IntangibleAssetImprovement.CostPermanentDifference, 0)))
	|		ELSE 0
	|	END AS CostPermanentDifference,
	|
	|	CASE
	|		WHEN SUM(IACost.LocalCost) <> 0
	|			THEN CAST(MAX(ISNULL(IntangibleAssetsInitialRecognition.AmountOfTargetFunds, 0)) / SUM(IACost.LocalCost) AS NUMBER (23, 10)) 
	|		ELSE 0
	|	END AS CFShare,
	|
	|	CASE 
	|		WHEN (SUM(IACost.Cost) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostMA, ISNULL(IntangibleAssetImprovement.CostInManagementAccounting, 0)))) < 0 
	|				AND SUM(IACost.Cost) <> 0
	|			THEN TRUE 
	|		ELSE FALSE
	|	END AS PreliminaryCostExceedsActualMA,
	|
	|	CASE 
	|		WHEN (SUM(IACost.LocalCost) + SUM(IACost.CostTargetFinancing) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostLocalAccounting, ISNULL(IntangibleAssetImprovement.CostInAccounting, 0)))) < 0 
	|				AND SUM(IACost.LocalCost) <> 0
	|			THEN TRUE 
	|		ELSE FALSE
	|	END AS PreliminaryCostExceedsActualAC,
	|
	|	CASE 
	|		WHEN (SUM(IACost.CostPermanentDifference) + SUM(IACost.CostTargetFinancingPD) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostPD, ISNULL(IntangibleAssetImprovement.CostPermanentDifference, 0)))) < 0 
	|				AND SUM(IACost.CostPermanentDifference) <> 0
	|			THEN TRUE 
	|		ELSE FALSE
	|	END AS PreliminaryCostExceedsActualPD
	|
	|FROM
	|	AccumulationRegister.IACost AS IACost
	|
	|		LEFT JOIN Document.IntangibleAssetsInitialRecognition2_4 AS IntangibleAssetsInitialRecognition
	|		ON IntangibleAssetsInitialRecognition.Ref = IACost.Recorder
	|
	|		LEFT JOIN Document.IntangibleAssetImprovement.IA AS IntangibleAssetImprovement
	|		ON IntangibleAssetImprovement.Ref = IACost.Recorder
	|			AND IntangibleAssetImprovement.IntangibleAsset = IACost.IntangibleAsset
	|
	|WHERE
	|	IACost.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|
	|	AND IACost.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.IntangibleAssetsInitialRecognition),
	|		VALUE(Enum.BusinessTransactions.IntangibleAssetsInitialRecognitionByInventoryCount),
	|		VALUE(Enum.BusinessTransactions.IntangibleAssetImprovement),
	|		VALUE(Enum.BusinessTransactions.IncludeAdditionalExpensesInIntangibleAssetCost))
	|
	|	AND IACost.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingItems_AdditionalCharges_All AS ListOfIA)
	|
	|GROUP BY
	|	IACost.IntangibleAsset
	|
	|HAVING 
	|	(SUM(IACost.Cost) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostMA, ISNULL(IntangibleAssetImprovement.CostInManagementAccounting, 0)))) <> 0
	|		OR (SUM(IACost.LocalCost) + SUM(IACost.CostTargetFinancing) - MAX(ISNULL(IntangibleAssetsInitialRecognition.InitialCostLocalAccounting, ISNULL(IntangibleAssetImprovement.CostInAccounting, 0)))) <> 0
	|
	|INDEX BY
	|	IntangibleAsset
	|";
		
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region IADepreciationAtBeginningOfMonth
	
	QueryText = 
	"SELECT
	|	&BegOfMonth                           AS BegOfMonth,
	|	IntangibleAssetsAmortizationCharge.Organization              AS Organization,
	|	IntangibleAssetsAmortizationCharge.IntangibleAsset      AS IntangibleAsset,
	|	-IntangibleAssetsAmortizationCharge.DepreciationBalance      AS Depreciation,
	|	-IntangibleAssetsAmortizationCharge.DepreciationLocalBalance  AS DepreciationLocal,
	|	-IntangibleAssetsAmortizationCharge.DepreciationInTaxAccountingBalance    AS DepreciationInTaxAccounting,
	|	-IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferencesBalance    AS DepreciationPermanentDifferences,
	|	-IntangibleAssetsAmortizationCharge.DepreciationTDBalance    AS DepreciationTD,
	|	-IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancingBalance    AS FixedAssetDepreciationTargetFinancing,
	|	-IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancingBalance  AS DepreciationTaxAccountingTargetFinancing,
	|	-IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPDBalance  AS DepreciationTargetFinancingPD,
	|	-IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTDBalance  AS DepreciationOfTargetFinancingTD
	|
	|INTO AmortizationOfNMA_AtBeginningOfMonth
	|
	|FROM
	|	AccumulationRegister.IntangibleAssetsAmortizationCharge.Balance(
	|			&EndOfPreviousMonthBorder,
	|			(Organization, IntangibleAsset) IN
	|				(SELECT
	|					ListOfIA.Organization,
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfAccountingObjects AS ListOfIA)) AS IntangibleAssetsAmortizationCharge
	|
	|INDEX BY
	|	IntangibleAsset,
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
	|	CompositionOfEGD_AtEndOfCalculationMonth.NonCurrentAsset AS NonCurrentAsset,
	|	CompositionOfEGD_AtEndOfCalculationMonth.CGU AS CGUAtEndOfMonth
	|INTO EGDSVNAAtEndOfMonthOfCalculation
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(
	|		ENDOFPERIOD(&BegOfMonth, MONTH), 
	|		(Organization, NonCurrentAsset) IN
	|				(SELECT
	|					ListOfIA.Organization,
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfAccountingObjects AS ListOfIA)
	|		) AS CompositionOfEGD_AtEndOfCalculationMonth
	|
	|INDEX BY
	|	NonCurrentAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	ImpairmentFA.NonCurrentAsset AS IntangibleAsset,
	|
	|	-SUM(ImpairmentFA.ImpairmentLocalAssetsClosingBalance) AS ImpairmentBalanceLocal,
	|	-SUM(ImpairmentFA.ImpairmenManClosingBalance) AS ImpairmentBalanceMan,
	|
	|	MAX(ImpairmentFA.CGU) AS CGU,
	|	MAX(ISNULL(EGDSVNAAtEndOfMonthOfCalculation.CGUAtEndOfMonth,
	|		VALUE(Catalog.CashGeneratingUnits.EmptyRef))) AS CGUAtEndOfMonth
	|
	|INTO ImpairmentOfVNA_WithChangedCGU
	|FROM
	|	AccumulationRegister.ImpairmentFA.BalanceAndTurnovers(
	|		&EndOfPreviousMonthBorder,
	|		&EndOfPreviousMonthBorder,,
	|		RegisterRecordsAndPeriodBoundaries,
	|		(Organization, NonCurrentAsset) IN
	|			(SELECT
	|				ListOfIA.Organization,
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects AS ListOfIA)) AS ImpairmentFA
	|
	|		LEFT JOIN EGDSVNAAtEndOfMonthOfCalculation AS EGDSVNAAtEndOfMonthOfCalculation
	|		ON ImpairmentFA.NonCurrentAsset = EGDSVNAAtEndOfMonthOfCalculation.NonCurrentAsset
	|
	|GROUP BY
	|	ImpairmentFA.NonCurrentAsset
	|
	|INDEX BY
	|	IntangibleAsset,
	|	CGUAtEndOfMonth,
	|	CGU
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ImpairmentOfVNA_WithChangedCGU.BegOfMonth AS BegOfMonth,
	|	ImpairmentOfVNA_WithChangedCGU.IntangibleAsset AS IntangibleAsset,
	|	ImpairmentOfVNA_WithChangedCGU.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|	ImpairmentOfVNA_WithChangedCGU.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|	ImpairmentOfVNA_WithChangedCGU.CGU AS CGU
	|INTO ImpairmentFA
	|FROM
	|	ImpairmentOfVNA_WithChangedCGU AS ImpairmentOfVNA_WithChangedCGU
	|WHERE
	|	ImpairmentOfVNA_WithChangedCGU.CGUAtEndOfMonth = ImpairmentOfVNA_WithChangedCGU.CGU
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ImpairmentOfVNA_WithChangedCGU";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
				
	#Region IntangibleAssetsOperatingTime
	
	QueryText =
	"SELECT DISTINCT
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|
	|	CASE
	|		WHEN InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting <> IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate
	|				AND InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting <> DATETIME(1,1,1)
	|			THEN ISNULL(BEGINOFPERIOD(IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate, MONTH), DATETIME(1,1,1))
	|		ELSE DATETIME(1,1,1)
	|	END AS DateOfLastChangeMA,
	|
	|	CASE
	|		WHEN InitialIntangibleAssetsInformation.DateOfRecognitionAccounting <> IADepreciationParametersBookkeepingAndTaxAccounting.LastChangeDate
	|				AND InitialIntangibleAssetsInformation.DateOfRecognitionAccounting <> DATETIME(1,1,1)
	|			THEN ISNULL(BEGINOFPERIOD(IADepreciationParametersBookkeepingAndTaxAccounting.LastChangeDate, MONTH), DATETIME(1,1,1))
	|		ELSE DATETIME(1,1,1)
	|	END AS LastModifiedDateAC,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(DATEADD(&BegOfMonth, MONTH, -1), MONTH) = BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, MONTH)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TakenIntoAccountLastMonth
	|
	|INTO ListOfIA_Development
	|
	|FROM
	|	ListOfAccountingObjects AS ListOfIA
	|
	|		LEFT JOIN InitialIntangibleAssetsInformation AS InitialIntangibleAssetsInformation
	|		ON (InitialIntangibleAssetsInformation.Organization = ListOfIA.Organization)
	|			AND (InitialIntangibleAssetsInformation.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (InitialIntangibleAssetsInformation.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN IntangibleAssetsAccountingProcedure AS IntangibleAssetsAccountingProcedure
	|		ON (IntangibleAssetsAccountingProcedure.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IntangibleAssetsAccountingProcedure.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN IntangibleAssetAmortizationParametersManagementAccounting AS IntangibleAssetAmortizationParametersManagementAccounting
	|		ON (IntangibleAssetAmortizationParametersManagementAccounting.Organization = ListOfIA.Organization)
	|			AND (IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IntangibleAssetAmortizationParametersManagementAccounting.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN IADepreciationParametersBookkeepingAndTaxAccounting AS IADepreciationParametersBookkeepingAndTaxAccounting
	|		ON (IADepreciationParametersBookkeepingAndTaxAccounting.Organization = ListOfIA.Organization)
	|			AND (IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IADepreciationParametersBookkeepingAndTaxAccounting.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Development_1.IntangibleAsset AS IntangibleAsset,
	|	SUM(Development_1.VolumeOfMaProduction) AS VolumeOfMaProduction,
	|	SUM(Development_1.VolumeOfACOutput) AS VolumeOfACOutput
	|
	|INTO IntangibleAssetsOperatingTime_AsOfDateOfLastChange
	|
	|FROM
	|	(SELECT
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|		ISNULL(DevelopmentOfUU.Count, 0) AS VolumeOfMaProduction,
	|		0 AS VolumeOfACOutput
	|
	|	FROM
	|		ListOfIA_Development AS ListOfIA
	|
	|			INNER JOIN AccumulationRegister.IntangibleAssetsOperatingTime AS DevelopmentOfUU
	|			ON DevelopmentOfUU.IntangibleAsset = ListOfIA.IntangibleAsset
	|				AND DevelopmentOfUU.Period < ListOfIA.DateOfLastChangeMA
	|
	|	UNION ALL
	|
	|	SELECT
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|		0 AS VolumeOfMaProduction,
	|		ISNULL(ACProduction.Count, 0) AS VolumeOfACOutput
	|	FROM
	|		ListOfIA_Development AS ListOfIA
	|
	|			INNER JOIN AccumulationRegister.IntangibleAssetsOperatingTime AS ACProduction
	|			ON ACProduction.IntangibleAsset = ListOfIA.IntangibleAsset
	|				AND ACProduction.Period < ListOfIA.LastModifiedDateAC
	|
	|	) AS Development_1
	|
	|GROUP BY
	|	Development_1.IntangibleAsset
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetsOperatingTime.CountTurnover AS OutputVolume
	|
	|INTO OutputOfNma_AtBeginningOfMonth
	|
	|FROM
	|	AccumulationRegister.IntangibleAssetsOperatingTime.Turnovers(
	|		,
	|		&EndOfPreviousMonth,,
	|		IntangibleAsset IN
	|				(SELECT
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfIA_Development AS ListOfIA)) AS IntangibleAssetsOperatingTime
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetsOperatingTime.CountTurnover AS OutputVolume,
	|	ListOfIA.TakenIntoAccountLastMonth AS TakenIntoAccountLastMonth
	|
	|INTO Nma_OutputAtEndOfMonth
	|
	|FROM
	|	AccumulationRegister.IntangibleAssetsOperatingTime.Turnovers(
	|		,
	|		&EndOfMonth,,
	|		IntangibleAsset IN
	|				(SELECT
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfIA_Development AS ListOfIA)) AS IntangibleAssetsOperatingTime
	|
	|		LEFT JOIN ListOfIA_Development AS ListOfIA
	|		ON (ListOfIA.IntangibleAsset = IntangibleAssetsOperatingTime.IntangibleAsset)
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfIA.IntangibleAsset
	|
	|INTO ListOfIA_TakenIntoAccountLastMonth
	|
	|FROM
	|	ListOfIA_Development AS ListOfIA
	|WHERE
	|	ListOfIA.TakenIntoAccountLastMonth
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetsOperatingTime.CountTurnover AS OutputVolume
	|
	|INTO OutputOfNma_AtBeginningOfPreviousMonth
	|
	|FROM
	|	AccumulationRegister.IntangibleAssetsOperatingTime.Turnovers(
	|		,
	|		&EndOfMonthBeforeLast,,
	|		IntangibleAsset IN
	|				(SELECT
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfIA_TakenIntoAccountLastMonth AS ListOfIA)) AS IntangibleAssetsOperatingTime
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|
	|	SUM(IntangibleAssetsOperatingTime.OutputVolume) AS OutputVolume,
	|	SUM(IntangibleAssetsOperatingTime.OutputForPastMonth) AS OutputForPastMonth,
	|	SUM(IntangibleAssetsOperatingTime.OutputAtBeginningOfMonth) AS OutputAtBeginningOfMonth,
	|	SUM(IntangibleAssetsOperatingTime.OutputAtBeginningOfPreviousMonth) AS OutputAtBeginningOfPreviousMonth
	|
	|INTO IntangibleAssetsOperatingTime
	|
	|FROM
	|	(SELECT
	|		IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|		-IntangibleAssetsOperatingTime.OutputVolume AS OutputVolume,
	|		IntangibleAssetsOperatingTime.OutputVolume AS OutputForPastMonth,
	|		IntangibleAssetsOperatingTime.OutputVolume AS OutputAtBeginningOfMonth,
	|		0 AS OutputAtBeginningOfPreviousMonth
	|	FROM
	|		OutputOfNma_AtBeginningOfMonth AS IntangibleAssetsOperatingTime
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		IntangibleAssetsOperatingTime.IntangibleAsset,
	|		IntangibleAssetsOperatingTime.OutputVolume,
	|		0,
	|		0,
	|		0
	|	FROM
	|		Nma_OutputAtEndOfMonth AS IntangibleAssetsOperatingTime
	|
	|	UNION ALL
	|	
	|	SELECT
	|		IntangibleAssetsOperatingTime.IntangibleAsset,
	|		0,
	|		0,
	|		-IntangibleAssetsOperatingTime.OutputVolume,
	|		IntangibleAssetsOperatingTime.OutputVolume
	|	FROM
	|		OutputOfNma_AtBeginningOfPreviousMonth AS IntangibleAssetsOperatingTime
	|
	|	) AS IntangibleAssetsOperatingTime
	|
	|GROUP BY
	|	IntangibleAssetsOperatingTime.IntangibleAsset
	|
	|INDEX BY
	|	IntangibleAsset";
		
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ChangesTo_Y
		
	#Region ChangingParameters
	QueryText =
	// IntangibleAssetAmortizationParametersManagementAccounting
	"SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|
	|	RegisterData.LastChangeDate AS LastChangeDate,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeMonths,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS EstimatedRunningTime,
	|	RegisterData.AccelerationFactor AS AccelerationFactor,
	|	RegisterData.DepreciationMethod,
	|	RegisterData.ResidualValueMan,
	|	RegisterData.ResidualValueLocal
	|
	|INTO ParametersOfDepreciationNMAUU_Changes
	|
	|FROM
	|	InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|
	|	RegisterData.LastChangeDate AS LastChangeDate,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeMonths,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS EstimatedRunningTime,
	|	RegisterData.AccelerationFactor AS AccelerationFactor,
	|	RegisterData.DepreciationMethod,
	|	RegisterData.ResidualValueMan,
	|	RegisterData.ResidualValueLocal
	|
	|FROM
	|	InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting AS RegisterData
	|
	|		INNER JOIN ListOfAccountingItems_AdditionalCharges_u AS AdditionalCharges
	|		ON RegisterData.IntangibleAsset = AdditionalCharges.IntangibleAsset
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// IntangibleAssetsAccountingProcedure
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|
	|	RegisterData.FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.EstimatedRunningTime
	|
	|INTO AccountingProcedureForNMA_ChangesInMA
	|
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedure AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.EstimatedRunningTime
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedure AS RegisterData
	|
	|		INNER JOIN ListOfAccountingItems_AdditionalCharges_u AS AdditionalCharges
	|		ON RegisterData.IntangibleAsset = AdditionalCharges.IntangibleAsset
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// IntangibleAssetsAccountingProcedureManagementAccounting
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.State,
	|	RegisterData.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	RegisterData.DepreciationRecordMethod,
	|	RegisterData.ExpenseItem,
	|	RegisterData.DimensionOfExpenses,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|	RegisterData.TransferExpensesToAnotherCompany,
	|	RegisterData.CompanyRecipientOfExpenses
	|
	|INTO AccountingProcedureForNMAUU_Changes
	|
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsAmortizationCharge2_4
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.State,
	|	RegisterData.AccrueDepreciationOrAmortization,
	|	RegisterData.DepreciationRecordMethod,
	|	RegisterData.ExpenseItem,
	|	RegisterData.DimensionOfExpenses,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusiness AS LineOfBusiness,
	|	RegisterData.TransferExpensesToAnotherCompany,
	|	RegisterData.CompanyRecipientOfExpenses
	|
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS RegisterData
	|
	|		INNER JOIN ListOfAccountingItems_AdditionalCharges_u AS AdditionalCharges
	|		ON RegisterData.IntangibleAsset = AdditionalCharges.IntangibleAsset
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// IntangibleAssetsRegistrationPlace
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.Department
	|
	|INTO PlaceOfRegistrationOfNMA_ChangesInMA
	|
	|FROM
	|	InformationRegister.IntangibleAssetsRegistrationPlace AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// InitialIntangibleAssetsInformation
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.DepreciationMethodAccounting,
	|	RegisterData.DepreciationMethodTaxAccounting
	|
	|INTO InitialInformation_Changes
	|
	|FROM
	|	InformationRegister.InitialIntangibleAssetsInformation AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.DepreciationMethodAccounting,
	|	RegisterData.DepreciationMethodTaxAccounting
	|FROM
	|	InformationRegister.InitialIntangibleAssetsInformation AS RegisterData
	|
	|		INNER JOIN ListOfAccountingItems_AdditionalCharges_u AS AdditionalCharges
	|		ON RegisterData.IntangibleAsset = AdditionalCharges.IntangibleAsset
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangeInValue
	QueryText =
	"SELECT
	|	IACost.BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	IACost.Period AS Period,
	|	IACost.Recorder AS Recorder,
	|	IACost.IntangibleAsset AS IntangibleAsset,
	|	IACost.Organization AS Organization,
	|
	|	SUM(IACost.Cost) AS Cost,
	|	SUM(IACost.LocalCost) AS LocalCost
	|
	|INTO CostOfNMA_MAChanges
	|
	|FROM
	|	(SELECT
	|		&BegOfMonth AS BegOfMonth,
	|		IACost.Period AS Period,
	|		IACost.Recorder AS Recorder,
	|		IACost.IntangibleAsset AS IntangibleAsset,
	|		IACost.Organization AS Organization,
	|
	|		IACost.PreliminaryCostMan AS Cost,
	|		IACost.PreliminaryCostLocal AS LocalCost
	|	FROM
	|		AccumulationRegister.IACost AS IACost
	|
	|	WHERE
	|		IACost.Active
	|		AND IACost.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND IACost.RecordInManAccounting
	|		AND IACost.Recorder REFS Document.IntangibleAssetImprovement
	|
	|		AND IACost.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	UNION ALL
	|
	|	SELECT
	|		&BegOfMonth AS BegOfMonth,
	|		DisposeIntangibleAssets2_4.Date AS Period,
	|		DisposeIntangibleAssets2_4.Ref AS Recorder,
	|		TableOfIA.IntangibleAsset AS IntangibleAsset,
	|		DisposeIntangibleAssets2_4.Organization AS Organization,
	|
	|		-TableOfIA.AmountManagementAccounting AS Cost,
	|		-TableOfIA.ChargeAmountAccounting AS LocalCost
	|	FROM
	|		Document.DisposeIntangibleAssets2_4 AS DisposeIntangibleAssets2_4
	|
	|			INNER JOIN Document.DisposeIntangibleAssets2_4.IA AS TableOfIA
	|			ON (TableOfIA.Ref = DisposeIntangibleAssets2_4.Ref)
	|	WHERE
	|		DisposeIntangibleAssets2_4.Posted
	|		AND DisposeIntangibleAssets2_4.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DisposeIntangibleAssets2_4.RecordInManAccounting
	|		AND DisposeIntangibleAssets2_4.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|		AND TableOfIA.AmountManagementAccounting <> 0
	|
	|		AND TableOfIA.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		IARevaluation.Date,
	|		IARevaluation.Ref,
	|		TableOfIA.IntangibleAsset,
	|		IARevaluation.Organization,
	|
	|		TableOfIA.CostInManagementAccounting,
	|		TableOfIA.CostInAccounting
	|	FROM
	|		Document.IARevaluation2_4 AS IARevaluation
	|
	|			INNER JOIN Document.IARevaluation2_4.IA AS TableOfIA
	|			ON (TableOfIA.Ref = IARevaluation.Ref)
	|	WHERE
	|		IARevaluation.Posted
	|		AND IARevaluation.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND IARevaluation.RecordInManAccounting
	|		AND TableOfIA.CostInManagementAccounting <> 0
	|
	|		AND TableOfIA.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		Adjusting.Date,
	|		Adjusting.Ref,
	|		TableOfIA.IntangibleAsset,
	|		Adjusting.Organization,
	|
	|		TableOfIA.CostInManagementAccounting,
	|		TableOfIA.CostInAccounting
	|	FROM
	|		Document.IntangibleAssetsCostAndAmortizationAdjustment AS Adjusting
	|
	|			INNER JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment.IA AS TableOfIA
	|			ON (TableOfIA.Ref = Adjusting.Ref)
	|	WHERE
	|		Adjusting.Posted
	|		AND Adjusting.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND Adjusting.RecordInManAccounting
	|		AND TableOfIA.CostInManagementAccounting <> 0
	|
	|		AND TableOfIA.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_ AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	) AS IACost
	|
	|GROUP BY
	|	IACost.BegOfMonth,
	|	IACost.Period,
	|	IACost.Recorder,
	|	IACost.IntangibleAsset,
	|	IACost.Organization
	|
	|HAVING
	|	(SUM(IACost.Cost) <> 0
	|		OR SUM(IACost.LocalCost) <> 0)
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
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|	Adjusting.Organization AS Organization,
	|
	|	TableOfIA.DepreciationManagementAccounting AS Depreciation,
	|	TableOfIA.DepreciationInAccounting AS DepreciationLocal
	|
	|INTO DepreciationOfNMA_MAChanges
	|
	|FROM
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment AS Adjusting
	|
	|		INNER JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment.IA AS TableOfIA
	|		ON (TableOfIA.Ref = Adjusting.Ref)
	|
	|WHERE
	|	Adjusting.Posted
	|	AND Adjusting.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND Adjusting.RecordInManAccounting
	|
	|	AND TableOfIA.DepreciationManagementAccounting <> 0
	|
	|	AND TableOfIA.IntangibleAsset IN
	|		(SELECT
	|			ListOfIA.IntangibleAsset
	|		FROM
	|			ListOfAccountingObjects_ AS ListOfIA
	|		WHERE
	|			ListOfIA.BegOfMonth = &BegOfMonth
	|			AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
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
	|	ChangesTable.IntangibleAsset AS IntangibleAsset,
	|	MAX(ChangesTable.Period) AS Period,
	|	MAX(BEGINOFPERIOD(DATEADD(ChangesTable.Period, MONTH, 1), MONTH)) AS BeginningOfNextMonth,
	|	MAX(AccountingProcedureForNMA_Last.Period) AS AccountingProcedureForNMA_LastPeriod,
	|	MAX(AccountingProcedureNMAUU_Last.Period) AS AccountingProcedureNMAUU_LatestPeriod,
	|	MAX(ParametersOfDepreciationNMAUU_Latest.Period) AS ParametersOfDepreciationNMAUU_LastPeriod,
	|	MAX(LastPlaceOfAccountingForNMA_.Period) AS PlaceOfAccountingForNMA_LastPeriod,
	|	MAX(InitialInformationOfNMA_Last.Period) AS InitialIntangibleAssetsInformation_LastPeriod
	|
	|INTO ChangesTable
	|
	|FROM
	|	(SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period AS Period,
	|		ChangesTable.IntangibleAsset AS IntangibleAsset,
	|		ChangesTable.Organization AS Organization
	|	FROM
	|		ParametersOfDepreciationNMAUU_Changes AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		AccountingProcedureForNMA_ChangesInMA AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		AccountingProcedureForNMAUU_Changes AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		PlaceOfRegistrationOfNMA_ChangesInMA AS ChangesTable
	|
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		InitialInformation_Changes AS ChangesTable
	|
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		CostOfNMA_MAChanges AS ChangesTable
	|
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		DepreciationOfNMA_MAChanges AS ChangesTable
	|
	|	) AS ChangesTable
	|
	|		LEFT JOIN ParametersOfDepreciationNMAUU_Changes AS ParametersOfDepreciationNMAUU_Latest
	|		ON (ParametersOfDepreciationNMAUU_Latest.Organization = ChangesTable.Organization)
	|			AND (ParametersOfDepreciationNMAUU_Latest.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (ParametersOfDepreciationNMAUU_Latest.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (ParametersOfDepreciationNMAUU_Latest.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN AccountingProcedureForNMA_ChangesInMA AS AccountingProcedureForNMA_Last
	|		ON (AccountingProcedureForNMA_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (AccountingProcedureForNMA_Last.Organization = ChangesTable.Organization)
	|			AND (AccountingProcedureForNMA_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (AccountingProcedureForNMA_Last.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN AccountingProcedureForNMAUU_Changes AS AccountingProcedureNMAUU_Last
	|		ON (AccountingProcedureNMAUU_Last.Organization = ChangesTable.Organization)
	|			AND (AccountingProcedureNMAUU_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (AccountingProcedureNMAUU_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (AccountingProcedureNMAUU_Last.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN PlaceOfRegistrationOfNMA_ChangesInMA AS LastPlaceOfAccountingForNMA_
	|		ON (LastPlaceOfAccountingForNMA_.Organization = ChangesTable.Organization)
	|			AND (LastPlaceOfAccountingForNMA_.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (LastPlaceOfAccountingForNMA_.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (LastPlaceOfAccountingForNMA_.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN InitialInformation_Changes AS InitialInformationOfNMA_Last
	|		ON (InitialInformationOfNMA_Last.Organization = ChangesTable.Organization)
	|			AND (InitialInformationOfNMA_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (InitialInformationOfNMA_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (InitialInformationOfNMA_Last.Period <= ChangesTable.Period)
	|
	|GROUP BY
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.ParameterPeriod,
	|	ChangesTable.Recorder,
	|	ChangesTable.IntangibleAsset,
	|	ChangesTable.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangesTable.Organization,
	|	ChangesTable.IntangibleAsset,
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.Recorder,
	|	MIN(TableOfChangesIsAsFollows.Period) AS PeriodFollowing
	|
	|INTO TableOfChangesIsAsFollows
	|
	|FROM
	|	ChangesTable AS ChangesTable
	|
	|		LEFT JOIN ChangesTable AS TableOfChangesIsAsFollows
	|		ON (TableOfChangesIsAsFollows.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesIsAsFollows.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (TableOfChangesIsAsFollows.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (TableOfChangesIsAsFollows.Period > ChangesTable.Period
	|				OR TableOfChangesIsAsFollows.Period = ChangesTable.Period
	|						AND TableOfChangesIsAsFollows.Recorder > ChangesTable.Recorder)
	|
	|GROUP BY
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.Recorder,
	|	ChangesTable.Organization,
	|	ChangesTable.IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangesTable.Organization,
	|	ChangesTable.IntangibleAsset,
	|	MIN(ChangesTable.Period) AS PeriodFollowing
	|
	|INTO TableOfChangesThisMonth
	|
	|FROM
	|	ChangesTable AS ChangesTable
	|WHERE
	|	(ChangesTable.BegOfMonth = &BegOfMonth)
	|
	|GROUP BY
	|	ChangesTable.Organization,
	|	ChangesTable.IntangibleAsset";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangesTo_Y
	QueryText =
	"SELECT
	|	ChangesTable.BegOfMonth AS BegOfMonth,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, MONTH) = ChangesTable.BegOfMonth
	|			THEN BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, DAY)
	|		ELSE ChangesTable.ParameterPeriod 
	|	END AS ParameterPeriod,
	|
	|	ChangesTable.Recorder AS Recorder,
	|	ENDOFPERIOD(ChangesTable.BegOfMonth, MONTH) AS EndOfMonth,
	|	ENDOFPERIOD(ChangesTable.Period, DAY) AS ChangesDate,
	|
	|	CASE 
	|		WHEN ChangesTable.BegOfMonth = &BeginningOfPreviousMonth
	|				AND BEGINOFPERIOD(ISNULL(TableOfChangesThisMonth.PeriodFollowing, &EndOfMonth), DAY) = &BegOfMonth
	|			THEN &BegOfMonth 
	|		WHEN ChangesTable.BegOfMonth = &BeginningOfPreviousMonth
	|			THEN ISNULL(DATEADD(TableOfChangesThisMonth.PeriodFollowing, DAY, -1), &EndOfMonth) 
	|		ELSE ISNULL(DATEADD(TableOfChangesIsAsFollows.PeriodFollowing, DAY, -1), &EndOfMonth) 
	|	END AS Period,
	|
	|	DATEDIFF(ChangesTable.Period, ISNULL(TableOfChangesIsAsFollows.PeriodFollowing, ChangesTable.BeginningOfNextMonth), DAY) AS ValidityPeriod,
	|	ChangesTable.IntangibleAsset AS IntangibleAsset,
	|	ChangesTable.Organization AS Organization,
	|
	|	ISNULL(CostOfIAChange_1.Cost, 0) AS CostUpdate, // Change in the cost of the document
	|	ISNULL(CostOfIAChange_1.LocalCost, 0) AS LocalCostUpdate, // Change in the cost of the document
	|	ISNULL(DepreciationOfIAChanges.Depreciation, 0) AS DepreciationUpdate, // Change in depreciation by document
	|	ISNULL(DepreciationOfIAChanges.DepreciationLocal, 0) AS DepreciationLocalUpdate, // Change in depreciation by document
	|
	|	ParametersOfDepreciationNMAUU_Latest.LastChangeDate AS LastChangeDate,
	|	ParametersOfDepreciationNMAUU_Latest.UsefulLifeMonths,
	|	ParametersOfDepreciationNMAUU_Latest.EstimatedRunningTime,
	|	ParametersOfDepreciationNMAUU_Latest.AccelerationFactor,
	|	ParametersOfDepreciationNMAUU_Latest.DepreciationMethod,
	|	ParametersOfDepreciationNMAUU_Latest.ResidualValueMan,
	|	ParametersOfDepreciationNMAUU_Latest.ResidualValueLocal,
	|	AccountingProcedureForNMA_Last.FinancialAccountingGroup,
	|	AccountingProcedureForNMA_Last.LineOfBusiness,
	|	AccountingProcedureNMAUU_Last.State,
	|	AccountingProcedureNMAUU_Last.AccrueDepreciationOrAmortization,
	|	AccountingProcedureNMAUU_Last.DepreciationRecordMethod,
	|	AccountingProcedureNMAUU_Last.ExpenseItem AS ExpenseItem,
	|	AccountingProcedureNMAUU_Last.DimensionOfExpenses AS DimensionOfExpenses,
	|	AccountingProcedureNMAUU_Last.Department AS ExpensesBusinessUnit,
	|	AccountingProcedureNMAUU_Last.LineOfBusiness AS ExpenseLineOfBusiness,
	|	AccountingProcedureNMAUU_Last.TransferExpensesToAnotherCompany,
	|	AccountingProcedureNMAUU_Last.CompanyRecipientOfExpenses,
	|	LastPlaceOfAccountingForNMA_.Department AS Department
	|
	|INTO ChangesTo_Y
	|
	|FROM
	|	ChangesTable AS ChangesTable
	|
	|		LEFT JOIN TableOfChangesIsAsFollows AS TableOfChangesIsAsFollows
	|		ON (TableOfChangesIsAsFollows.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesIsAsFollows.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (TableOfChangesIsAsFollows.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (TableOfChangesIsAsFollows.Recorder = ChangesTable.Recorder)
	|
	|		LEFT JOIN TableOfChangesThisMonth AS TableOfChangesThisMonth
	|		ON (TableOfChangesThisMonth.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesThisMonth.IntangibleAsset = ChangesTable.IntangibleAsset)
	|
	|		LEFT JOIN DatesWhenMaWasLastModified AS LastModifiedDates
	|		ON (LastModifiedDates.Organization = ChangesTable.Organization)
	|			AND (LastModifiedDates.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (LastModifiedDates.BegOfMonth = ChangesTable.BegOfMonth)
	|
	|		LEFT JOIN ParametersOfDepreciationNMAUU_Changes AS ParametersOfDepreciationNMAUU_Latest
	|			LEFT JOIN ParametersOfDepreciationNMAUU_Changes AS DepreciationParametersOfNMAUU_AreAsFollows
	|			ON (DepreciationParametersOfNMAUU_AreAsFollows.Organization = ParametersOfDepreciationNMAUU_Latest.Organization)
	|				AND (DepreciationParametersOfNMAUU_AreAsFollows.IntangibleAsset = ParametersOfDepreciationNMAUU_Latest.IntangibleAsset)
	|				AND (DepreciationParametersOfNMAUU_AreAsFollows.BegOfMonth = ParametersOfDepreciationNMAUU_Latest.BegOfMonth)
	|				AND (DepreciationParametersOfNMAUU_AreAsFollows.Period = ParametersOfDepreciationNMAUU_Latest.Period)
	|				AND (DepreciationParametersOfNMAUU_AreAsFollows.PointInTime > ParametersOfDepreciationNMAUU_Latest.PointInTime)
	|		ON (ParametersOfDepreciationNMAUU_Latest.Organization = ChangesTable.Organization)
	|			AND (ParametersOfDepreciationNMAUU_Latest.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (ParametersOfDepreciationNMAUU_Latest.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (ParametersOfDepreciationNMAUU_Latest.Period = ChangesTable.ParametersOfDepreciationNMAUU_LastPeriod)
	|			AND (DepreciationParametersOfNMAUU_AreAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN AccountingProcedureForNMA_ChangesInMA AS AccountingProcedureForNMA_Last
	|			LEFT JOIN AccountingProcedureForNMA_ChangesInMA AS AccountingProcedureForNMA_IsAsFollows
	|			ON (AccountingProcedureForNMA_IsAsFollows.Organization = AccountingProcedureForNMA_Last.Organization)
	|				AND (AccountingProcedureForNMA_IsAsFollows.IntangibleAsset = AccountingProcedureForNMA_Last.IntangibleAsset)
	|				AND (AccountingProcedureForNMA_IsAsFollows.BegOfMonth = AccountingProcedureForNMA_Last.BegOfMonth)
	|				AND (AccountingProcedureForNMA_IsAsFollows.Period = AccountingProcedureForNMA_Last.Period)
	|				AND (AccountingProcedureForNMA_IsAsFollows.PointInTime > AccountingProcedureForNMA_Last.PointInTime)
	|		ON (AccountingProcedureForNMA_Last.Organization = ChangesTable.Organization)
	|			AND (AccountingProcedureForNMA_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (AccountingProcedureForNMA_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (AccountingProcedureForNMA_Last.Period = ChangesTable.AccountingProcedureForNMA_LastPeriod)
	|			AND (AccountingProcedureForNMA_IsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN AccountingProcedureForNMAUU_Changes AS AccountingProcedureNMAUU_Last
	|			LEFT JOIN AccountingProcedureForNMAUU_Changes AS AccountingProcedureForNMAUU_IsAsFollows
	|			ON (AccountingProcedureForNMAUU_IsAsFollows.Organization = AccountingProcedureNMAUU_Last.Organization)
	|				AND (AccountingProcedureForNMAUU_IsAsFollows.IntangibleAsset = AccountingProcedureNMAUU_Last.IntangibleAsset)
	|				AND (AccountingProcedureForNMAUU_IsAsFollows.BegOfMonth = AccountingProcedureNMAUU_Last.BegOfMonth)
	|				AND (AccountingProcedureForNMAUU_IsAsFollows.Period = AccountingProcedureNMAUU_Last.Period)
	|				AND (AccountingProcedureForNMAUU_IsAsFollows.PointInTime > AccountingProcedureNMAUU_Last.PointInTime)
	|		ON (AccountingProcedureNMAUU_Last.Organization = ChangesTable.Organization)
	|			AND (AccountingProcedureNMAUU_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (AccountingProcedureNMAUU_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (AccountingProcedureNMAUU_Last.Period = ChangesTable.AccountingProcedureNMAUU_LatestPeriod)
	|			AND (AccountingProcedureForNMAUU_IsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN PlaceOfRegistrationOfNMA_ChangesInMA AS LastPlaceOfAccountingForNMA_
	|			LEFT JOIN PlaceOfRegistrationOfNMA_ChangesInMA AS PlaceOfRegistrationOfNMA_IsAsFollows
	|			ON (PlaceOfRegistrationOfNMA_IsAsFollows.Organization = LastPlaceOfAccountingForNMA_.Organization)
	|				AND (PlaceOfRegistrationOfNMA_IsAsFollows.IntangibleAsset = LastPlaceOfAccountingForNMA_.IntangibleAsset)
	|				AND (PlaceOfRegistrationOfNMA_IsAsFollows.BegOfMonth = LastPlaceOfAccountingForNMA_.BegOfMonth)
	|				AND (PlaceOfRegistrationOfNMA_IsAsFollows.Period = LastPlaceOfAccountingForNMA_.Period)
	|				AND (PlaceOfRegistrationOfNMA_IsAsFollows.PointInTime > LastPlaceOfAccountingForNMA_.PointInTime)
	|		ON (LastPlaceOfAccountingForNMA_.Organization = ChangesTable.Organization)
	|			AND (LastPlaceOfAccountingForNMA_.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (LastPlaceOfAccountingForNMA_.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (LastPlaceOfAccountingForNMA_.Period = ChangesTable.PlaceOfAccountingForNMA_LastPeriod)
	|			AND (PlaceOfRegistrationOfNMA_IsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN CostOfNMA_MAChanges AS CostOfIAChange_1
	|		ON (CostOfIAChange_1.Organization = ChangesTable.Organization)
	|			AND (CostOfIAChange_1.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (CostOfIAChange_1.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (CostOfIAChange_1.Recorder = ChangesTable.Recorder)
	|
	|		LEFT JOIN DepreciationOfNMA_MAChanges AS DepreciationOfIAChanges
	|		ON (DepreciationOfIAChanges.Organization = ChangesTable.Organization)
	|			AND (DepreciationOfIAChanges.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (DepreciationOfIAChanges.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (DepreciationOfIAChanges.Recorder = ChangesTable.Recorder)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
		
	#EndRegion

	#Region ChangesTo_BU_M
		
	#Region ChangingParameters
	QueryText =
	// IADepreciationParametersBookkeepingAndTaxAccounting
	"SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeMonths,
	|	RegisterData.DepreciationAccrualFactor AS ZoomRatio,
	|	RegisterData.ResidualValueMan
	|
	|INTO ParametersOfDepreciationNMABU_Changes_BU_M
	|
	|FROM
	|	InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting AS RegisterData
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeMonths,
	|	RegisterData.DepreciationAccrualFactor AS ZoomRatio,
	|	RegisterData.ResidualValueMan
	|FROM
	|	InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting AS RegisterData
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_AdditionalCharge_BU_MU AS ListOfIA)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// IntangibleAssetsAccountingProcedure
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|
	|	RegisterData.FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.EstimatedRunningTime
	|
	|INTO AccountingProcedureForNMA_Changes_BU_M
	|
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedure AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.FinancialAccountingGroup,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.EstimatedRunningTime
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedure AS RegisterData
	|
	|		INNER JOIN ListOfAccountingObjects_AdditionalCharge_BU_MU AS AdditionalCharges
	|		ON RegisterData.IntangibleAsset = AdditionalCharges.IntangibleAsset
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime AS PointInTime,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.IntangibleAsset AS IntangibleAsset,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.BUState AS BUState,
	|	RegisterData.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
	|	RegisterData.DepreciationRecordMethodLA AS DepreciationRecordMethodLA,
	|	RegisterData.ExpenseItemAccounting AS ExpenseItemAccounting,
	|	RegisterData.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
	|	RegisterData.DepartmentACC AS DepartmentACC,
	|	RegisterData.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
	|	RegisterData.TransferExpensesToAnotherCompany,
	|	RegisterData.CompanyRecipientOfExpenses
	|
	|INTO AccountingProcedureForNMABU_Changes_BU_M
	|
	|FROM
	|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS RegisterData
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.BUState,
	|	RegisterData.DepreciationAccrualAccounting,
	|	RegisterData.DepreciationRecordMethodLA,
	|	RegisterData.ExpenseItemAccounting,
	|	RegisterData.ExpensesDimensionAccounting,
	|	RegisterData.DepartmentACC AS DepartmentACC,
	|	RegisterData.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
	|	RegisterData.TransferExpensesToAnotherCompany,
	|	RegisterData.CompanyRecipientOfExpenses
	|FROM
	|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS RegisterData
	|
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|
	|	AND (RegisterData.Organization, RegisterData.IntangibleAsset) IN
	|			(SELECT
	|				ListOfIA.Organization,
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_AdditionalCharge_BU_MU AS ListOfIA)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// IntangibleAssetsRegistrationPlace
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.Department
	|
	|INTO PlaceOfRegistrationOfNMA_Changes_BU_M
	|
	|FROM
	|	InformationRegister.IntangibleAssetsRegistrationPlace AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// InitialIntangibleAssetsInformation
	|SELECT DISTINCT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.DepreciationMethodAccounting,
	|	RegisterData.DepreciationMethodTaxAccounting
	|
	|INTO InitialInformationOfNMA_Changes_BU_M
	|
	|FROM
	|	InformationRegister.InitialIntangibleAssetsInformation AS RegisterData
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|
	|	AND NOT RegisterData.Recorder REFS Document.IntangibleAssetsInitialRecognition2_4
	|	AND NOT RegisterData.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|
	|	AND RegisterData.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	&EndOfMonthBeforeLast AS ParameterPeriod,
	|	BEGINOFPERIOD(RegisterData.Period, DAY) AS Period,
	|	RegisterData.PointInTime,
	|	RegisterData.Recorder,
	|	RegisterData.IntangibleAsset,
	|	RegisterData.Organization,
	|	RegisterData.DepreciationMethodAccounting,
	|	RegisterData.DepreciationMethodTaxAccounting
	|FROM
	|	InformationRegister.InitialIntangibleAssetsInformation AS RegisterData
	|
	|		INNER JOIN ListOfAccountingObjects_AdditionalCharge_BU_MU AS AdditionalCharges
	|		ON RegisterData.IntangibleAsset = AdditionalCharges.IntangibleAsset
	|
	|WHERE
	|	RegisterData.Active
	|	AND RegisterData.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|	AND RegisterData.Period >= AdditionalCharges.Period
	|	AND VALUETYPE(RegisterData.Recorder) IN (&TypesOfDocumentsCountedAfterAdditionalCharges)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangeInValue
	QueryText =
	"SELECT
	|	IACost.BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	IACost.Period AS Period,
	|	IACost.Recorder AS Recorder,
	|	IACost.IntangibleAsset AS IntangibleAsset,
	|	IACost.Organization AS Organization,
	|	SUM(IACost.LocalCost) AS LocalCost
	|
	|INTO CostOfNMA_Change_BU_M
	|
	|FROM
	|	(SELECT
	|		&BegOfMonth AS BegOfMonth,
	|		DisposeIntangibleAssets2_4.Date AS Period,
	|		DisposeIntangibleAssets2_4.Ref AS Recorder,
	|		TableOfIA.IntangibleAsset AS IntangibleAsset,
	|		DisposeIntangibleAssets2_4.Organization AS Organization,
	|
	|		-TableOfIA.ChargeAmountAccounting AS LocalCost
	|	FROM
	|		Document.DisposeIntangibleAssets2_4 AS DisposeIntangibleAssets2_4
	|
	|			INNER JOIN Document.DisposeIntangibleAssets2_4.IA AS TableOfIA
	|			ON (TableOfIA.Ref = DisposeIntangibleAssets2_4.Ref)
	|	WHERE
	|		&ThisIsInternationalVersion
	|		AND DisposeIntangibleAssets2_4.Posted
	|		AND DisposeIntangibleAssets2_4.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DisposeIntangibleAssets2_4.RecordInLocalAccounting
	|		AND DisposeIntangibleAssets2_4.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|		AND TableOfIA.ChargeAmountAccounting <> 0
	|
	|		AND TableOfIA.IntangibleAsset IN
	|				(SELECT
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfAccountingObjects_BU_MU AS ListOfIA
	|				WHERE
	|					ListOfIA.BegOfMonth = &BegOfMonth
	|					AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		IARevaluation.Date,
	|		IARevaluation.Ref,
	|		TableOfIA.IntangibleAsset,
	|		IARevaluation.Organization,
	|
	|		TableOfIA.CostInAccounting
	|	FROM
	|		Document.IARevaluation2_4 AS IARevaluation
	|
	|			INNER JOIN Document.IARevaluation2_4.IA AS TableOfIA
	|			ON (TableOfIA.Ref = IARevaluation.Ref)
	|	WHERE
	|		&ThisIsInternationalVersion
	|		AND IARevaluation.Posted
	|		AND IARevaluation.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND IARevaluation.RecordInLocalAccounting
	|		AND TableOfIA.CostInAccounting <> 0
	|
	|		AND TableOfIA.IntangibleAsset IN
	|				(SELECT
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfAccountingObjects_BU_MU AS ListOfIA
	|				WHERE
	|					ListOfIA.BegOfMonth = &BegOfMonth
	|					AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&BegOfMonth,
	|		Adjusting.Date,
	|		Adjusting.Ref,
	|		TableOfIA.IntangibleAsset,
	|		Adjusting.Organization,
	|
	|		TableOfIA.CostInAccounting
	|	FROM
	|		Document.IntangibleAssetsCostAndAmortizationAdjustment AS Adjusting
	|
	|			INNER JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment.IA AS TableOfIA
	|			ON (TableOfIA.Ref = Adjusting.Ref)
	|	WHERE
	|		&ThisIsInternationalVersion
	|		AND Adjusting.Posted
	|		AND Adjusting.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND Adjusting.RecordInLocalAccounting
	|		AND TableOfIA.CostInAccounting <> 0
	|
	|		AND TableOfIA.IntangibleAsset IN
	|				(SELECT
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					ListOfAccountingObjects_BU_MU AS ListOfIA
	|				WHERE
	|					ListOfIA.BegOfMonth = &BegOfMonth
	|					AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
	|	
	|	) AS IACost
	|
	|GROUP BY
	|	IACost.BegOfMonth,
	|	IACost.Period,
	|	IACost.Recorder,
	|	IACost.IntangibleAsset,
	|	IACost.Organization";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangeInDepreciation
	QueryText =
	"SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	&EndOfPreviousMonth AS ParameterPeriod,
	|	Adjusting.Date AS Period,
	|	Adjusting.Ref AS Recorder,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|	Adjusting.Organization AS Organization,
	|	TableOfIA.DepreciationInAccounting AS DepreciationLocal
	|
	|INTO DepreciationOfNMA_Changes_BU_M
	|
	|FROM
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment AS Adjusting
	|
	|		INNER JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment.IA AS TableOfIA
	|		ON (TableOfIA.Ref = Adjusting.Ref)
	|WHERE
	|	&ThisIsInternationalVersion
	|	AND Adjusting.Posted
	|	AND Adjusting.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND Adjusting.RecordInLocalAccounting
	|	AND TableOfIA.DepreciationInAccounting <> 0
	|
	|	AND TableOfIA.IntangibleAsset IN
	|			(SELECT
	|				ListOfIA.IntangibleAsset
	|			FROM
	|				ListOfAccountingObjects_BU_MU AS ListOfIA
	|			WHERE
	|				ListOfIA.BegOfMonth = &BegOfMonth
	|				AND ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting)
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
	|	ChangesTable.IntangibleAsset AS IntangibleAsset,
	|	MAX(ChangesTable.Period) AS Period,
	|	MAX(BEGINOFPERIOD(DATEADD(ChangesTable.Period, MONTH, 1), MONTH)) AS BeginningOfNextMonth,
	|	MAX(AccountingProcedureForNMA_Last.Period) AS AccountingProcedureForNMA_LastPeriod,
	|	MAX(AccountingProcedureForNMABU_Last.Period) AS AccountingProcedureForNMABU_LastPeriod,
	|	MAX(DepreciationParametersNMABU_Last.Period) AS DepreciationParametersNMABU_LastPeriod,
	|	MAX(LastPlaceOfAccountingForNMA_.Period) AS PlaceOfAccountingForNMA_LastPeriod,
	|	MAX(InitialInformationOfNMA_Last.Period) AS InitialIntangibleAssetsInformation_LastPeriod
	|
	|INTO TableOfChangesBU_MU
	|
	|FROM
	|	(SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period AS Period,
	|		ChangesTable.IntangibleAsset AS IntangibleAsset,
	|		ChangesTable.Organization AS Organization
	|	FROM
	|		ParametersOfDepreciationNMABU_Changes_BU_M AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		AccountingProcedureForNMA_Changes_BU_M AS ChangesTable
	|	WHERE
	|		&ThisIsInternationalVersion
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		AccountingProcedureForNMABU_Changes_BU_M AS ChangesTable
	|	
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		PlaceOfRegistrationOfNMA_Changes_BU_M AS ChangesTable
	|	WHERE
	|		&ThisIsInternationalVersion
	|
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth AS BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		InitialInformationOfNMA_Changes_BU_M AS ChangesTable
	|	WHERE
	|		&ThisIsInternationalVersion
	|
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		CostOfNMA_Change_BU_M AS ChangesTable
	|
	|	UNION
	|	
	|	SELECT
	|		ChangesTable.BegOfMonth,
	|		ChangesTable.ParameterPeriod AS ParameterPeriod,
	|		ChangesTable.Recorder,
	|		ChangesTable.Period,
	|		ChangesTable.IntangibleAsset,
	|		ChangesTable.Organization
	|	FROM
	|		DepreciationOfNMA_Changes_BU_M AS ChangesTable
	|
	|	) AS ChangesTable
	|
	|		LEFT JOIN ParametersOfDepreciationNMABU_Changes_BU_M AS DepreciationParametersNMABU_Last
	|		ON (DepreciationParametersNMABU_Last.Organization = ChangesTable.Organization)
	|			AND (DepreciationParametersNMABU_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (DepreciationParametersNMABU_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (DepreciationParametersNMABU_Last.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN AccountingProcedureForNMA_Changes_BU_M AS AccountingProcedureForNMA_Last
	|		ON (AccountingProcedureForNMA_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (AccountingProcedureForNMA_Last.Organization = ChangesTable.Organization)
	|			AND (AccountingProcedureForNMA_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (AccountingProcedureForNMA_Last.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN AccountingProcedureForNMABU_Changes_BU_M AS AccountingProcedureForNMABU_Last
	|		ON (AccountingProcedureForNMABU_Last.Organization = ChangesTable.Organization)
	|			AND (AccountingProcedureForNMABU_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (AccountingProcedureForNMABU_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (AccountingProcedureForNMABU_Last.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN PlaceOfRegistrationOfNMA_Changes_BU_M AS LastPlaceOfAccountingForNMA_
	|		ON (LastPlaceOfAccountingForNMA_.Organization = ChangesTable.Organization)
	|			AND (LastPlaceOfAccountingForNMA_.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (LastPlaceOfAccountingForNMA_.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (LastPlaceOfAccountingForNMA_.Period <= ChangesTable.Period)
	|
	|		LEFT JOIN InitialInformation_Changes AS InitialInformationOfNMA_Last
	|		ON (InitialInformationOfNMA_Last.Organization = ChangesTable.Organization)
	|			AND (InitialInformationOfNMA_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (InitialInformationOfNMA_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (InitialInformationOfNMA_Last.Period <= ChangesTable.Period)
	|
	|GROUP BY
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.ParameterPeriod,
	|	ChangesTable.Recorder,
	|	ChangesTable.IntangibleAsset,
	|	ChangesTable.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangesTable.Organization,
	|	ChangesTable.IntangibleAsset,
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
	|			AND (TableOfChangesIsAsFollows.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (TableOfChangesIsAsFollows.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (TableOfChangesIsAsFollows.Period > ChangesTable.Period
	|				OR TableOfChangesIsAsFollows.Period = ChangesTable.Period
	|						AND TableOfChangesIsAsFollows.Recorder > ChangesTable.Recorder)
	|
	|GROUP BY
	|	ChangesTable.BegOfMonth,
	|	ChangesTable.Recorder,
	|	ChangesTable.Organization,
	|	ChangesTable.IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangesTable.Organization,
	|	ChangesTable.IntangibleAsset,
	|	MIN(ChangesTable.Period) AS PeriodFollowing
	|
	|INTO TableOfChangesInThisMonth_BU_MU
	|
	|FROM
	|	TableOfChangesBU_MU AS ChangesTable
	|
	|WHERE
	|	(ChangesTable.BegOfMonth = &BegOfMonth)
	|
	|GROUP BY
	|	ChangesTable.Organization,
	|	ChangesTable.IntangibleAsset";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ChangesTo_BU_M
	QueryText =
	"SELECT
	|	ChangesTable.BegOfMonth AS BegOfMonth,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, MONTH) = ChangesTable.BegOfMonth
	|			THEN BEGINOFPERIOD(LastModifiedDates.DateOfDocumentOfAcceptanceForAccounting, DAY)
	|		ELSE ChangesTable.ParameterPeriod 
	|	END AS ParameterPeriod,
	|
	|	ChangesTable.Recorder AS Recorder,
	|	ENDOFPERIOD(ChangesTable.BegOfMonth, MONTH) AS EndOfMonth,
	|	ENDOFPERIOD(ChangesTable.Period, DAY) AS ChangesDate,
	|
	|	CASE 
	|		WHEN ChangesTable.BegOfMonth = &BeginningOfPreviousMonth
	|				AND BEGINOFPERIOD(ISNULL(TableOfChangesThisMonth.PeriodFollowing, &EndOfMonth), DAY) = &BegOfMonth
	|			THEN &BegOfMonth 
	|		WHEN ChangesTable.BegOfMonth = &BeginningOfPreviousMonth
	|			THEN ISNULL(DATEADD(TableOfChangesThisMonth.PeriodFollowing, DAY, -1), &EndOfMonth) 
	|		ELSE ISNULL(DATEADD(TableOfChangesIsAsFollows.PeriodFollowing, DAY, -1), &EndOfMonth) 
	|	END AS Period,
	|
	|	DATEDIFF(ChangesTable.Period, ISNULL(TableOfChangesIsAsFollows.PeriodFollowing, ChangesTable.BeginningOfNextMonth), DAY) AS ValidityPeriod,
	|	ChangesTable.IntangibleAsset AS IntangibleAsset,
	|	ChangesTable.Organization AS Organization,
	|
	|	ISNULL(CostOfNMA_Changes.LocalCost, 0) AS LocalCostUpdate, // Change in the cost of the document
	|	ISNULL(DepreciationOfNMA_Changes.DepreciationLocal, 0) AS DepreciationLocalUpdate, // Change in depreciation by document
	|
	|	InitialInformationOfNMA_Last.DepreciationMethodAccounting AS DepreciationMethod,
	|
	|	DepreciationParametersNMABU_Last.UsefulLifeMonths,
	|	DepreciationParametersNMABU_Last.ZoomRatio,
	|	DepreciationParametersNMABU_Last.ResidualValueMan,
	|
	|	AccountingProcedureForNMA_Last.FinancialAccountingGroup,
	|	AccountingProcedureForNMA_Last.LineOfBusiness,
	|	AccountingProcedureForNMA_Last.EstimatedRunningTime,
	|
	|	AccountingProcedureForNMABU_Last.BUState,
	|	AccountingProcedureForNMABU_Last.DepreciationAccrualAccounting AS AccrueDepreciationOrAmortization,
	|	AccountingProcedureForNMABU_Last.DepreciationRecordMethodLA AS DepreciationRecordMethod,
	|	AccountingProcedureForNMABU_Last.ExpenseItemAccounting AS ExpenseItem,
	|	AccountingProcedureForNMABU_Last.ExpensesDimensionAccounting AS DimensionOfExpenses,
	|	AccountingProcedureForNMABU_Last.DepartmentACC AS ExpensesBusinessUnit,
	|	AccountingProcedureForNMABU_Last.LineOfBusinessBookkeeping AS ExpenseLineOfBusiness,
	|	AccountingProcedureForNMABU_Last.TransferExpensesToAnotherCompany,
	|	AccountingProcedureForNMABU_Last.CompanyRecipientOfExpenses,
	|
	|	LastPlaceOfAccountingForNMA_.Department
	|
	|INTO ChangesTo_BU_M
	|
	|FROM
	|	TableOfChangesBU_MU AS ChangesTable
	|
	|		LEFT JOIN TableOfChangesIsFollowing_BU_M AS TableOfChangesIsAsFollows
	|		ON (TableOfChangesIsAsFollows.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesIsAsFollows.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (TableOfChangesIsAsFollows.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (TableOfChangesIsAsFollows.Recorder = ChangesTable.Recorder)
	|
	|		LEFT JOIN TableOfChangesInThisMonth_BU_MU AS TableOfChangesThisMonth
	|		ON (TableOfChangesThisMonth.Organization = ChangesTable.Organization)
	|			AND (TableOfChangesThisMonth.IntangibleAsset = ChangesTable.IntangibleAsset)
	|
	|		LEFT JOIN DatesOfLastModifiedBy_BU_M AS LastModifiedDates
	|		ON (LastModifiedDates.Organization = ChangesTable.Organization)
	|			AND (LastModifiedDates.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (LastModifiedDates.BegOfMonth = ChangesTable.BegOfMonth)
	|
	|		LEFT JOIN InitialInformationOfNMA_Changes_BU_M AS InitialInformationOfNMA_Last
	|			LEFT JOIN InitialInformationOfNMA_Changes_BU_M AS InitialInformationOfNMA_IsAsFollows
	|			ON (InitialInformationOfNMA_IsAsFollows.Organization = InitialInformationOfNMA_Last.Organization)
	|				AND (InitialInformationOfNMA_IsAsFollows.IntangibleAsset = InitialInformationOfNMA_Last.IntangibleAsset)
	|				AND (InitialInformationOfNMA_IsAsFollows.BegOfMonth = InitialInformationOfNMA_Last.BegOfMonth)
	|				AND (InitialInformationOfNMA_IsAsFollows.Period = InitialInformationOfNMA_Last.Period)
	|				AND (InitialInformationOfNMA_IsAsFollows.PointInTime > InitialInformationOfNMA_Last.PointInTime)
	|		ON (InitialInformationOfNMA_Last.Organization = ChangesTable.Organization)
	|			AND (InitialInformationOfNMA_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (InitialInformationOfNMA_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (InitialInformationOfNMA_Last.Period = ChangesTable.InitialIntangibleAssetsInformation_LastPeriod)
	|			AND (InitialInformationOfNMA_IsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN ParametersOfDepreciationNMABU_Changes_BU_M AS DepreciationParametersNMABU_Last
	|			LEFT JOIN ParametersOfDepreciationNMABU_Changes_BU_M AS NMABUDepreciationParametersAreAsFollows
	|			ON (NMABUDepreciationParametersAreAsFollows.Organization = DepreciationParametersNMABU_Last.Organization)
	|				AND (NMABUDepreciationParametersAreAsFollows.IntangibleAsset = DepreciationParametersNMABU_Last.IntangibleAsset)
	|				AND (NMABUDepreciationParametersAreAsFollows.BegOfMonth = DepreciationParametersNMABU_Last.BegOfMonth)
	|				AND (NMABUDepreciationParametersAreAsFollows.Period = DepreciationParametersNMABU_Last.Period)
	|				AND (NMABUDepreciationParametersAreAsFollows.PointInTime > DepreciationParametersNMABU_Last.PointInTime)
	|		ON (DepreciationParametersNMABU_Last.Organization = ChangesTable.Organization)
	|			AND (DepreciationParametersNMABU_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (DepreciationParametersNMABU_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (DepreciationParametersNMABU_Last.Period = ChangesTable.DepreciationParametersNMABU_LastPeriod)
	|			AND (NMABUDepreciationParametersAreAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN AccountingProcedureForNMA_Changes_BU_M AS AccountingProcedureForNMA_Last
	|			LEFT JOIN AccountingProcedureForNMA_Changes_BU_M AS AccountingProcedureForNMA_IsAsFollows
	|			ON (AccountingProcedureForNMA_IsAsFollows.IntangibleAsset = AccountingProcedureForNMA_Last.IntangibleAsset)
	|				AND (AccountingProcedureForNMA_IsAsFollows.BegOfMonth = AccountingProcedureForNMA_Last.BegOfMonth)
	|				AND (AccountingProcedureForNMA_IsAsFollows.Period = AccountingProcedureForNMA_Last.Period)
	|				AND (AccountingProcedureForNMA_IsAsFollows.PointInTime > AccountingProcedureForNMA_Last.PointInTime)
	|		ON (AccountingProcedureForNMA_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (AccountingProcedureForNMA_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (AccountingProcedureForNMA_Last.Period = ChangesTable.AccountingProcedureForNMA_LastPeriod)
	|			AND (AccountingProcedureForNMA_IsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN AccountingProcedureForNMABU_Changes_BU_M AS AccountingProcedureForNMABU_Last
	|			LEFT JOIN AccountingProcedureForNMABU_Changes_BU_M AS AccountingProcedureForNMABU_IsAsFollows
	|			ON (AccountingProcedureForNMABU_IsAsFollows.Organization = AccountingProcedureForNMABU_Last.Organization)
	|				AND (AccountingProcedureForNMABU_IsAsFollows.IntangibleAsset = AccountingProcedureForNMABU_Last.IntangibleAsset)
	|				AND (AccountingProcedureForNMABU_IsAsFollows.BegOfMonth = AccountingProcedureForNMABU_Last.BegOfMonth)
	|				AND (AccountingProcedureForNMABU_IsAsFollows.Period = AccountingProcedureForNMABU_Last.Period)
	|				AND (AccountingProcedureForNMABU_IsAsFollows.PointInTime > AccountingProcedureForNMABU_Last.PointInTime)
	|		ON (AccountingProcedureForNMABU_Last.Organization = ChangesTable.Organization)
	|			AND (AccountingProcedureForNMABU_Last.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (AccountingProcedureForNMABU_Last.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (AccountingProcedureForNMABU_Last.Period = ChangesTable.AccountingProcedureForNMABU_LastPeriod)
	|			AND (AccountingProcedureForNMABU_IsAsFollows.Recorder IS NULL)
	|
	|		LEFT JOIN PlaceOfRegistrationOfNMA_Changes_BU_M AS LastPlaceOfAccountingForNMA_
	|			LEFT JOIN PlaceOfRegistrationOfNMA_Changes_BU_M AS PlaceOfRegistrationOfNMA_IsAsFollows
	|			ON (PlaceOfRegistrationOfNMA_IsAsFollows.Organization = LastPlaceOfAccountingForNMA_.Organization)
	|				AND (PlaceOfRegistrationOfNMA_IsAsFollows.IntangibleAsset = LastPlaceOfAccountingForNMA_.IntangibleAsset)
	|				AND (PlaceOfRegistrationOfNMA_IsAsFollows.BegOfMonth = LastPlaceOfAccountingForNMA_.BegOfMonth)
	|				AND (PlaceOfRegistrationOfNMA_IsAsFollows.Period = LastPlaceOfAccountingForNMA_.Period)
	|				AND (PlaceOfRegistrationOfNMA_IsAsFollows.PointInTime > LastPlaceOfAccountingForNMA_.PointInTime)
	|		ON (LastPlaceOfAccountingForNMA_.Organization = ChangesTable.Organization)
	|			AND (LastPlaceOfAccountingForNMA_.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (LastPlaceOfAccountingForNMA_.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (LastPlaceOfAccountingForNMA_.Period = ChangesTable.PlaceOfAccountingForNMA_LastPeriod)
	|			AND (LastPlaceOfAccountingForNMA_.Recorder IS NULL)
	|
	|		LEFT JOIN CostOfNMA_Change_BU_M AS CostOfNMA_Changes
	|		ON (CostOfNMA_Changes.Organization = ChangesTable.Organization)
	|			AND (CostOfNMA_Changes.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (CostOfNMA_Changes.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (CostOfNMA_Changes.Recorder = ChangesTable.Recorder)
	|
	|		LEFT JOIN DepreciationOfNMA_Changes_BU_M AS DepreciationOfNMA_Changes
	|		ON (DepreciationOfNMA_Changes.Organization = ChangesTable.Organization)
	|			AND (DepreciationOfNMA_Changes.IntangibleAsset = ChangesTable.IntangibleAsset)
	|			AND (DepreciationOfNMA_Changes.BegOfMonth = ChangesTable.BegOfMonth)
	|			AND (DepreciationOfNMA_Changes.Recorder = ChangesTable.Recorder)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#EndRegion
	
	#Region PeriodOfChange_Y
	
	QueryText =
	"SELECT
	|	ChangesTo_Y.BegOfMonth           AS BegOfMonth,
	|	ChangesTo_Y.IntangibleAsset    AS IntangibleAsset,
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
	|	ChangesTo_Y.IntangibleAsset,
	|	ChangesTo_Y.Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
		
	#Region ListOfNMAsParameters_UU
	
	QueryText = 
	"SELECT
	|	CASE 
	|		WHEN CurMonthChangePeriod.Period IS NULL
	|			THEN ListOfIA.AccrualPeriod
	|		WHEN BEGINOFPERIOD(CurMonthChangePeriod.Period, DAY) = BEGINOFPERIOD(CurMonthChangePeriod.Period, MONTH)
	|			THEN CurMonthChangePeriod.Period
	|		ELSE DATEADD(CurMonthChangePeriod.Period, DAY, -1)
	|	END AS Period,
	|
	|	ListOfIA.ThisIsAnAdditionalAccrual,
	|	ISNULL(PreliminaryCostOfIa.PreliminaryCostExceedsActualMA, FALSE) AS PreliminaryCostExceedsActualMA,
	|	ISNULL(PreliminaryCostOfIa.PreliminaryCostExceedsActualAC, FALSE) AS PreliminaryCostExceedsActualAC,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	CAST(ListOfIA.IntangibleAsset AS Catalog.IntangibleAssets).KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.Organization,
	|
	|	CASE
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|			THEN AccountingProcedureForIAAtBeginningOfMonth.FinancialAccountingGroup
	|		ELSE IntangibleAssetsAccountingProcedure.FinancialAccountingGroup 
	|	END AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|			THEN AccountingProcedureForIAAtBeginningOfMonth.LineOfBusiness
	|		ELSE IntangibleAssetsAccountingProcedure.LineOfBusiness 
	|	END AS LineOfBusiness,
	|
	|	ListOfIA.DepreciationIsCalculatedAccordingToINTStandards AS DepreciationIsCalculatedAccordingToINTStandards,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	|	CASE
	|		WHEN ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|			THEN VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|		ELSE VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|	END AS ProcedureForCalculatingDepreciationOfMa,
	|
	// CostUsedToCalculateDepreciationManag
	|	CASE 
	|		WHEN NOT ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|
	|			THEN InitialIntangibleAssetsInformation.InitialCostMA
	|
	|		WHEN ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|					AND BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ListOfIA.BegOfMonth
	|				OR ListOfIA.ThisIsAnAdditionalAccrual
	|
	|			THEN ISNULL(PreliminaryCostOfIa.CostInManagementAccounting, 0)
	|
	|		ELSE ISNULL(IACost.Cost, 0) - ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0)
	|
	|	END AS CostUsedToCalculateDepreciationManag,
	|
	// CostUsedToCalculateDepreciationLocal
	|	CASE 
	|		WHEN NOT ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|
	|			THEN InitialIntangibleAssetsInformation.InitialCostLocalAccounting
	|
	|		WHEN ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|					AND BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ListOfIA.BegOfMonth
	|				OR ListOfIA.ThisIsAnAdditionalAccrual
	|
	|			THEN ISNULL(PreliminaryCostOfIa.CostInAccounting, 0)
	|
	|		ELSE ISNULL(IACost.LocalCost, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|
	|	END AS CostUsedToCalculateDepreciationLocal,
	|
	// ResourceAssigned
	|	CASE 
	|		WHEN IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits, 0)
	|		ELSE ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth, 0)
	|	END AS ResourceAssigned,
	|
	// LifeSpentCurrentPeriod
	|	CASE 
	|		WHEN LastModifiedDates.Date = BEGINOFPERIOD(PeriodOfChange_Y.Period, DAY)
	|			THEN 0
	|
	|		WHEN IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			THEN CAST(CASE 
	|					WHEN NOT PeriodOfChange_Y.Period IS NULL
	|						THEN CASE 
	|								WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfIA.BegOfMonth
	|									THEN (DATEDIFF(LastModifiedDates.Date, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfIA.EndOfMonth), DAY) + 1)
	|									ELSE (DATEDIFF(ListOfIA.BegOfMonth, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfIA.EndOfMonth), DAY) + 1)
	|							END / DAY(ListOfIA.EndOfMonth)
	|					ELSE 1
	|				END * CASE
	|							WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|								THEN ISNULL(IntangibleAssetsOperatingTime.OutputForPastMonth, 0)
	|							WHEN NOT ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|									AND BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = &BeginningOfPreviousMonth
	|								THEN ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0) + ISNULL(IntangibleAssetsOperatingTime.OutputForPastMonth, 0)
	|							ELSE ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0)
	|						END AS NUMBER(20,8))
	
			// If the calculation is performed in the month of acceptance for accounting, then the day of acceptance/Every month
	|		WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfIA.BegOfMonth
	|			THEN CAST(CAST(DATEDIFF(LastModifiedDates.Date, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfIA.EndOfMonth), DAY) + 1 AS NUMBER(15,9))
	|					/ CAST(DAY(ListOfIA.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9))
	|	
			// If this is an additional charge, then the date of the document is / In today's month
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|
	|			THEN CAST(CAST(DATEDIFF(ListOfIA.Period, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfIA.EndOfMonth), DAY) + 1 AS NUMBER(15,9))
	|					/ CAST(DAY(ListOfIA.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9))
	|
			// In other cases, the number of days is the first modification of the parameters/Every month
	|		ELSE CAST(CAST(DATEDIFF(ListOfIA.BegOfMonth, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfIA.EndOfMonth), DAY) + 1 AS NUMBER(15,9))
	|					/ CAST(DAY(ListOfIA.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9))
	|
	|	END AS LifeSpentCurrentPeriod,
	|	  
	// LifeSpentPastPeriod
	|	CASE 
	|		WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfIA.BegOfMonth
	|				OR LastModifiedDates.Date IS NULL
	|
	|			THEN CAST(0 AS NUMBER(20,8))
	|
	|		WHEN IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|
	|			THEN CASE
	|					WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|						THEN CAST(ISNULL(IntangibleAssetsOperatingTime.OutputAtBeginningOfPreviousMonth, 0) AS NUMBER(20,8))
	|					WHEN NOT ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|							AND BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = &BeginningOfPreviousMonth
	|						THEN 0
	|					ELSE CAST(ISNULL(IntangibleAssetsOperatingTime.OutputAtBeginningOfMonth, 0)
	|									- ISNULL(IntangibleAssetsOperatingTime_AsOfDateOfLastChange.VolumeOfMaProduction, 0) AS NUMBER(20,8))
	|				END
	|
			// In the next month after acceptance for accounting: [number of days worked per month of acceptance] / [total days per month of acceptance]
	|		WHEN ENDOFPERIOD(LastModifiedDates.Date, MONTH) = ENDOFPERIOD(DATEADD(ListOfIA.BegOfMonth, MONTH, -1), MONTH)
	|
	|			THEN CAST(CAST(DATEDIFF(LastModifiedDates.Date, ENDOFPERIOD(LastModifiedDates.Date, MONTH), DAY) + 1 AS NUMBER(15,9)) 
	|					/ CAST(DAY(ENDOFPERIOD(LastModifiedDates.Date, MONTH)) AS NUMBER(15,9)) AS NUMBER(31,9))
	
			// In later months: [number of days worked per month of acceptance] / [total days per month of acceptance] + [number of months after acceptance before the beginning of the month]
	|		ELSE
	|			CAST(CAST(DATEDIFF(LastModifiedDates.Date, ENDOFPERIOD(LastModifiedDates.Date, MONTH), DAY) + 1 AS NUMBER(15,9)) 
	|				/ CAST(DAY(ENDOFPERIOD(LastModifiedDates.Date, MONTH)) AS NUMBER(15,9))
	|				+ DATEDIFF(BEGINOFPERIOD(DATEADD(LastModifiedDates.Date, MONTH, 1), MONTH), ListOfIA.EndOfMonth, MONTH) AS NUMBER(31,9))
	|
	|	END AS LifeSpentPastPeriod,
	|
	|	CASE
	|		WHEN YEAR(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting) <> YEAR(ListOfIA.BegOfMonth) THEN
	|			13 - MONTH(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting)
	|				+ 12 * (YEAR(ListOfIA.BegOfMonth) - YEAR(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting) - 1)
	|		ELSE 0
	|	END AS WorkedMonthsFullYears,
	|
	|	ListOfIA.AccrueDepreciationOrAmortization,
	|	ListOfIA.ExpenseItem AS ExpenseItem,
	|	ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN ListOfIA.ExpensesBusinessUnit <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ListOfIA.ExpensesBusinessUnit 
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|			THEN PlaceOfRegistrationOfIAAtBeginningOfMonth.Department
	|		ELSE IntangibleAssetsRegistrationPlace.Department 
	|	END AS ExpensesBusinessUnit,
	|
	|	CASE
	|		WHEN ListOfIA.ExpensesBusinessUnit <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ListOfIA.ExpenseLineOfBusiness 
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|			THEN AccountingProcedureForIAAtBeginningOfMonth.LineOfBusiness
	|		ELSE IntangibleAssetsAccountingProcedure.LineOfBusiness 
	|	END AS ExpenseLineOfBusiness,
	|
	|	ListOfIA.DepreciationRecordMethod,
	|	ListOfIA.TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses,
	|
	// NetBookValue
	|	CASE 
	|		WHEN ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|					AND BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ListOfIA.BegOfMonth
	|				OR ListOfIA.ThisIsAnAdditionalAccrual
	|
	|			THEN ISNULL(PreliminaryCostOfIa.CostInManagementAccounting, 0)
	|
	|		ELSE ISNULL(IACost.Cost, 0) - ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0)
	|
	|	END AS NetBookValue,
	|
	// NetBookValueLocal
	|	CASE 
	|		WHEN VALUETYPE(IntangibleAssetAmortizationParametersManagementAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND (ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ListOfIA.BegOfMonth
	|					OR ListOfIA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfIa.CostInAccounting, 0)
	|
	|		ELSE ISNULL(IACost.LocalCost, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|
	|	END AS NetBookValueLocal,
	|
	|	InitialIntangibleAssetsInformation.InitialCostMA AS InitialCost,
	|	InitialIntangibleAssetsInformation.InitialCostLocalAccounting AS InitialCostOfLocal,
	|	&ActualUsefulLife AS ActualUsefulLife,
	|
	|	ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueMan, 0) AS ResidualValueMan,
	|	ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueLocal, 0) AS ResidualValueLocal,
	|
	|	0 AS CostAtBeginningOfYear,
	|
	|	CASE 
	|		WHEN VALUETYPE(IntangibleAssetAmortizationParametersManagementAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND (ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfIA.BegOfMonth
	|					OR ListOfIA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfIa.CostInManagementAccounting, 0)
	|
	|		ELSE ISNULL(IACost.Cost, 0)
	|
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN VALUETYPE(IntangibleAssetAmortizationParametersManagementAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND (ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfIA.BegOfMonth
	|					OR ListOfIA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfIa.CostInAccounting, 0)
	|
	|		ELSE ISNULL(IACost.LocalCost, 0)
	|
	|	END AS LocalCost,
	|
	|	ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0) AS Depreciation,
	|	ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0) AS DepreciationLocal,
	|
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceLocal, 0) AS ImpairmentBalanceLocal,
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceMan, 0)  AS ImpairmentBalanceMan,
	|
	|	CASE
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|			THEN PlaceOfRegistrationOfIAAtBeginningOfMonth.Department
	|		ELSE IntangibleAssetsRegistrationPlace.Department 
	|	END AS Department,
	|
	|	ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0) AS OutputVolume,
	|
	|	IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths AS UsefulLifeMonths,
	|	IntangibleAssetAmortizationParametersManagementAccounting.AccelerationFactor AS AccelerationFactor,
	|	IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod AS DepreciationMethod
	|
	|INTO ListOfNMAsParameters_UU
	|
	|FROM
	|	ListOfAccountingObjects_ AS ListOfIA
	|
	|		LEFT JOIN PeriodOfChange_Y AS PeriodOfChange_Y
	|		ON (PeriodOfChange_Y.Organization = ListOfIA.Organization)
	|			AND (PeriodOfChange_Y.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (PeriodOfChange_Y.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN PeriodOfChange_Y AS CurMonthChangePeriod
	|		ON (CurMonthChangePeriod.Organization = ListOfIA.Organization)
	|			AND (CurMonthChangePeriod.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (CurMonthChangePeriod.BegOfMonth = &BegOfMonth)
	|
	|		LEFT JOIN DatesWhenMaWasLastModified AS LastModifiedDates
	|		ON (LastModifiedDates.Organization = ListOfIA.Organization)
	|			AND (LastModifiedDates.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (LastModifiedDates.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN IntangibleAssetsAccountingProcedure AS IntangibleAssetsAccountingProcedure
	|		ON (IntangibleAssetsAccountingProcedure.Organization = ListOfIA.Organization)
	|			AND (IntangibleAssetsAccountingProcedure.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IntangibleAssetsAccountingProcedure.BegOfMonth = ListOfIA.BegOfMonth)
	|			AND (IntangibleAssetsAccountingProcedure.ParameterPeriod = ListOfIA.ParameterPeriod)
	|
	|		LEFT JOIN IntangibleAssetsAccountingProcedure AS AccountingProcedureForIAAtBeginningOfMonth
	|		ON (AccountingProcedureForIAAtBeginningOfMonth.Organization = ListOfIA.Organization)
	|			AND (AccountingProcedureForIAAtBeginningOfMonth.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (AccountingProcedureForIAAtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (AccountingProcedureForIAAtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN CostOfNMA_AtBeginningOfMonth AS IACost
	|		ON (IACost.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IACost.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN PreliminaryCostOfIa AS PreliminaryCostOfIa
	|		ON (PreliminaryCostOfIa.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (PreliminaryCostOfIa.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN AmortizationOfNMA_AtBeginningOfMonth AS IntangibleAssetsAmortizationCharge
	|		ON (IntangibleAssetsAmortizationCharge.Organization = ListOfIA.Organization)
	|			AND (IntangibleAssetsAmortizationCharge.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IntangibleAssetsAmortizationCharge.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentAtBeginningOfMonth
	|		ON (ImpairmentAtBeginningOfMonth.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (ImpairmentAtBeginningOfMonth.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN IntangibleAssetsRegistrationPlace AS IntangibleAssetsRegistrationPlace
	|		ON (IntangibleAssetsRegistrationPlace.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IntangibleAssetsRegistrationPlace.BegOfMonth = ListOfIA.BegOfMonth)
	|			AND (IntangibleAssetsRegistrationPlace.ParameterPeriod = ListOfIA.ParameterPeriod)
	|
	|		LEFT JOIN IntangibleAssetsRegistrationPlace AS PlaceOfRegistrationOfIAAtBeginningOfMonth
	|		ON (PlaceOfRegistrationOfIAAtBeginningOfMonth.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (PlaceOfRegistrationOfIAAtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (PlaceOfRegistrationOfIAAtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN InitialIntangibleAssetsInformation AS InitialIntangibleAssetsInformation
	|		ON (InitialIntangibleAssetsInformation.Organization = ListOfIA.Organization)
	|			AND (InitialIntangibleAssetsInformation.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (InitialIntangibleAssetsInformation.BegOfMonth = ListOfIA.BegOfMonth)
	|			AND (InitialIntangibleAssetsInformation.ParameterPeriod = ListOfIA.ParameterPeriod)
	|
	|		LEFT JOIN IntangibleAssetAmortizationParametersManagementAccounting AS IntangibleAssetAmortizationParametersManagementAccounting
	|		ON (IntangibleAssetAmortizationParametersManagementAccounting.Organization = ListOfIA.Organization)
	|			AND (IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IntangibleAssetAmortizationParametersManagementAccounting.BegOfMonth = ListOfIA.BegOfMonth)
	|			AND (IntangibleAssetAmortizationParametersManagementAccounting.ParameterPeriod = ListOfIA.ParameterPeriod)
	|
	|		LEFT JOIN IntangibleAssetsAccountingProcedureManagementAccounting AS IntangibleAssetsAccountingProcedureManagementAccounting
	|		ON (IntangibleAssetsAccountingProcedureManagementAccounting.Organization = ListOfIA.Organization)
	|			AND (IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IntangibleAssetsAccountingProcedureManagementAccounting.BegOfMonth = ListOfIA.BegOfMonth)
	|			AND (IntangibleAssetsAccountingProcedureManagementAccounting.ParameterPeriod = ListOfIA.ParameterPeriod)
	|
	|		LEFT JOIN IntangibleAssetsAccountingProcedureManagementAccounting AS AccountingProcedureForNMAUU_AtBeginningOfMonth
	|		ON (AccountingProcedureForNMAUU_AtBeginningOfMonth.Organization = ListOfIA.Organization)
	|			AND (AccountingProcedureForNMAUU_AtBeginningOfMonth.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (AccountingProcedureForNMAUU_AtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (AccountingProcedureForNMAUU_AtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN IntangibleAssetsOperatingTime AS IntangibleAssetsOperatingTime
	|		ON (IntangibleAssetsOperatingTime.IntangibleAsset = IntangibleAssetsAccountingProcedure.IntangibleAsset)
	|
	|		LEFT JOIN IntangibleAssetsOperatingTime_AsOfDateOfLastChange AS IntangibleAssetsOperatingTime_AsOfDateOfLastChange
	|		ON (IntangibleAssetsOperatingTime_AsOfDateOfLastChange.IntangibleAsset = IntangibleAssetsAccountingProcedure.IntangibleAsset)
	|
	|WHERE
	|	ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization, FALSE)
	|
	|	AND (NOT ListOfIA.ThisIsAnAdditionalAccrual
	|		OR ISNULL(AccountingProcedureForNMAUU_AtBeginningOfMonth.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting))
	|";	
	
	QueryText = StrReplace(
		QueryText, 
		"&ActualUsefulLife", 
		NonCurrentAssetsInternal.FieldTextActualUsefulLife("InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting"));
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion

	#Region ListOfNMASWithParameters_BU_MU
	
	QueryText = 
	"SELECT
	|	CASE 
	|		WHEN CurMonthChangePeriod.Period IS NULL
	|			THEN ListOfIA.AccrualPeriod
	|		WHEN BEGINOFPERIOD(CurMonthChangePeriod.Period, DAY) = BEGINOFPERIOD(CurMonthChangePeriod.Period, MONTH)
	|			THEN CurMonthChangePeriod.Period
	|		ELSE DATEADD(CurMonthChangePeriod.Period, DAY, -1)
	|	END AS Period,
	|
	|	ListOfIA.ThisIsAnAdditionalAccrual AS ThisIsAnAdditionalAccrual,
	|	ISNULL(PreliminaryCostOfIa.PreliminaryCostExceedsActualAC, FALSE) AS PreliminaryCostExceedsActual,
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	CAST(ListOfIA.IntangibleAsset AS Catalog.IntangibleAssets).KindOfAccountingObject AS KindOfAccountingObject,
	|	ListOfIA.Organization,
	|
	|	CASE
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|			THEN AccountingProcedureForIAAtBeginningOfMonth.FinancialAccountingGroup
	|		ELSE IntangibleAssetsAccountingProcedure.FinancialAccountingGroup 
	|	END AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|			THEN AccountingProcedureForIAAtBeginningOfMonth.LineOfBusiness
	|		ELSE IntangibleAssetsAccountingProcedure.LineOfBusiness 
	|	END AS LineOfBusiness,
	|
	|	TRUE AS DepreciationIsCalculatedAccordingToINTStandards,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	|	CASE
	|		WHEN ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|			THEN VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|		ELSE VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|	END AS ProcedureForCalculatingDepreciationAC,
	|
	// CostUsedToCalculateDepreciationLocal
	|	CASE 
	|		WHEN ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|					AND BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ListOfIA.BegOfMonth
	|				OR ListOfIA.ThisIsAnAdditionalAccrual
	|
	|			THEN ISNULL(PreliminaryCostOfIa.CostInAccounting, 0)
	|
	|		ELSE ISNULL(IACost.LocalCost, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|
	|	END AS CostUsedToCalculateDepreciationLocal,
	|
	// ResourceAssigned
	|	CASE 
	|		WHEN InitialIntangibleAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits, 0)
	|		ELSE ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeForCalculatingDepreciationMonth, 0)
	|	END AS ResourceAssigned,
	|
	// LifeSpentCurrentPeriod
	|	CASE 
	|		WHEN LastModifiedDates.Date = BEGINOFPERIOD(PeriodOfChange_Y.Period, DAY)
	|			THEN 0
	|
	|		WHEN InitialIntangibleAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			THEN CAST(CASE 
	|					WHEN NOT PeriodOfChange_Y.Period IS NULL
	|						THEN CASE 
	|								WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfIA.BegOfMonth
	|									THEN (DATEDIFF(LastModifiedDates.Date, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfIA.EndOfMonth), DAY) + 1)
	|									ELSE (DATEDIFF(ListOfIA.BegOfMonth, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfIA.EndOfMonth), DAY) + 1)
	|							END / DAY(ListOfIA.EndOfMonth)
	|					ELSE 1
	|				END * CASE
	|							WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|								THEN ISNULL(IntangibleAssetsOperatingTime.OutputForPastMonth, 0)
	|							WHEN NOT ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|									AND BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = &BeginningOfPreviousMonth
	|								THEN ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0) + ISNULL(IntangibleAssetsOperatingTime.OutputForPastMonth, 0)
	|							ELSE ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0)
	|						END AS NUMBER(31,9))
	
			// If the calculation is performed in the month of acceptance for accounting, then the day of acceptance/Every month
	|		WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfIA.BegOfMonth
	|			THEN CAST(CAST(DATEDIFF(LastModifiedDates.Date, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfIA.EndOfMonth), DAY) + 1 AS NUMBER(15,9))
	|					/ CAST(DAY(ListOfIA.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9))
	|	
			// In other cases, the number of days is the first modification of the parameters/Every month
	|		ELSE CAST(CAST(DATEDIFF(ListOfIA.BegOfMonth, ISNULL(DATEADD(PeriodOfChange_Y.Period, DAY, -1), ListOfIA.EndOfMonth), DAY) + 1 AS NUMBER(15,9))
	|					/ CAST(DAY(ListOfIA.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9))
	|
	|	END AS LifeSpentCurrentPeriod,
	|	  
	// LifeSpentPastPeriod
	|	CASE 
	|		WHEN BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfIA.BegOfMonth
	|				OR LastModifiedDates.Date IS NULL
	|
	|			THEN CAST(0 AS NUMBER(31,9))
	|
	|		WHEN InitialIntangibleAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|
	|			THEN CASE
	|					WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|						THEN CAST(ISNULL(IntangibleAssetsOperatingTime.OutputAtBeginningOfPreviousMonth, 0) AS NUMBER(31,9))
	|					ELSE CAST(ISNULL(IntangibleAssetsOperatingTime.OutputAtBeginningOfMonth, 0) 
	|									- ISNULL(IntangibleAssetsOperatingTime_AsOfDateOfLastChange.VolumeOfACOutput, 0) AS NUMBER(31,9))
	|				END
	|
			// In the next month after acceptance for accounting: [number of days worked per month of acceptance] / [total days per month of acceptance]
	|		WHEN ENDOFPERIOD(LastModifiedDates.Date, MONTH) = ENDOFPERIOD(DATEADD(ListOfIA.BegOfMonth, MONTH, -1), MONTH)
	|
	|			THEN CAST(CAST(DATEDIFF(LastModifiedDates.Date, ENDOFPERIOD(LastModifiedDates.Date, MONTH), DAY) + 1 AS NUMBER(15,9)) 
	|					/ CAST(DAY(ENDOFPERIOD(LastModifiedDates.Date, MONTH)) AS NUMBER(15,9)) AS NUMBER(31,9))
	
			// In later months: [number of days worked per month of acceptance] / [total days per month of acceptance] + [number of months after acceptance before the beginning of the month]
	|		ELSE
	|			CAST(CAST(DATEDIFF(LastModifiedDates.Date, ENDOFPERIOD(LastModifiedDates.Date, MONTH), DAY) + 1 AS NUMBER(15,9)) 
	|				/ CAST(DAY(ENDOFPERIOD(LastModifiedDates.Date, MONTH)) AS NUMBER(15,9))
	|				+ DATEDIFF(BEGINOFPERIOD(DATEADD(LastModifiedDates.Date, MONTH, 1), MONTH), ListOfIA.EndOfMonth, MONTH) AS NUMBER(31,9))
	|
	|	END AS LifeSpentPastPeriod,
	|
	|	CASE
	|		WHEN YEAR(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting) <> YEAR(ListOfIA.BegOfMonth) THEN
	|			13 - MONTH(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting)
	|				+ 12 * (YEAR(ListOfIA.BegOfMonth) - YEAR(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting) - 1)
	|		ELSE 0
	|	END AS WorkedMonthsFullYears,
	|
	|	ListOfIA.AccrueDepreciationOrAmortization,
	|	ListOfIA.ExpenseItem,
	|	ListOfIA.DimensionOfExpenses,
	|
	|	CASE
	|		WHEN ListOfIA.ExpensesBusinessUnit <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ListOfIA.ExpensesBusinessUnit 
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|			THEN PlaceOfRegistrationOfIAAtBeginningOfMonth.Department
	|		ELSE IntangibleAssetsRegistrationPlace.Department 
	|	END AS ExpensesBusinessUnit,
	|
	|	CASE
	|		WHEN ListOfIA.ExpensesBusinessUnit <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ListOfIA.ExpenseLineOfBusiness 
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|			THEN AccountingProcedureForIAAtBeginningOfMonth.LineOfBusiness
	|		ELSE IntangibleAssetsAccountingProcedure.LineOfBusiness 
	|	END AS ExpenseLineOfBusiness,
	|
	|	ListOfIA.DepreciationRecordMethod,
	|	ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|
	// NetBookValueLocal
	|	CASE 
	|		WHEN VALUETYPE(IADepreciationParametersBookkeepingAndTaxAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND (ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, MONTH) = ListOfIA.BegOfMonth
	|					OR ListOfIA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfIa.CostInAccounting, 0)
	|
	|		ELSE ISNULL(IACost.LocalCost, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|
	|	END AS NetBookValueLocal,
	|
	|	InitialIntangibleAssetsInformation.InitialCostLocalAccounting AS InitialCostOfLocal,
	|	&ActualUsefulLife AS ActualUsefulLife,
	|
	|	ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan, 0) AS ResidualValueLocal,
	|
	|	0 AS CostAtBeginningOfYear,
	|
	|	CASE 
	|		WHEN VALUETYPE(IADepreciationParametersBookkeepingAndTaxAccounting.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|				AND (ListOfIA.DepreciationIsAccruedFromDateOfAcceptanceForAccounting
	|						AND BEGINOFPERIOD(LastModifiedDates.Date, MONTH) = ListOfIA.BegOfMonth
	|					OR ListOfIA.ThisIsAnAdditionalAccrual)
	|
	|			THEN ISNULL(PreliminaryCostOfIa.CostInAccounting, 0)
	|
	|		ELSE ISNULL(IACost.LocalCost, 0)
	|
	|	END AS LocalCost,
	|
	|	ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0) AS DepreciationLocal,
	|
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceLocal, 0) AS ImpairmentBalanceLocal,
	|
	|	CASE
	|		WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|			THEN PlaceOfRegistrationOfIAAtBeginningOfMonth.Department
	|		ELSE IntangibleAssetsRegistrationPlace.Department 
	|	END AS Department,
	|
	|	ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0) AS OutputVolume,
	|
	|	IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC AS UsefulLifeMonths,
	|	IADepreciationParametersBookkeepingAndTaxAccounting.DepreciationAccrualFactor AS AccelerationFactor,
	|	InitialIntangibleAssetsInformation.DepreciationMethodAccounting AS DepreciationMethod
	|
	|INTO ListOfNMASWithParameters_BU_MU
	|
	|FROM
	|	ListOfAccountingObjects_BU_MU AS ListOfIA
	|
	|		LEFT JOIN PeriodOfChange_Y AS PeriodOfChange_Y
	|		ON (PeriodOfChange_Y.Organization = ListOfIA.Organization)
	|			AND (PeriodOfChange_Y.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (PeriodOfChange_Y.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN PeriodOfChange_Y AS CurMonthChangePeriod
	|		ON (CurMonthChangePeriod.Organization = ListOfIA.Organization)
	|			AND (CurMonthChangePeriod.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (CurMonthChangePeriod.BegOfMonth = &BegOfMonth)
	|
	|		LEFT JOIN DatesOfLastModifiedBy_BU_M AS LastModifiedDates
	|		ON (LastModifiedDates.Organization = ListOfIA.Organization)
	|			AND (LastModifiedDates.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (LastModifiedDates.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN IntangibleAssetsAccountingProcedure AS IntangibleAssetsAccountingProcedure
	|		ON (IntangibleAssetsAccountingProcedure.Organization = ListOfIA.Organization)
	|			AND (IntangibleAssetsAccountingProcedure.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IntangibleAssetsAccountingProcedure.BegOfMonth = ListOfIA.BegOfMonth)
	|			AND (IntangibleAssetsAccountingProcedure.ParameterPeriod = ListOfIA.ParameterPeriod)
	|
	|		LEFT JOIN IntangibleAssetsAccountingProcedure AS AccountingProcedureForIAAtBeginningOfMonth
	|		ON (AccountingProcedureForIAAtBeginningOfMonth.Organization = ListOfIA.Organization)
	|			AND (AccountingProcedureForIAAtBeginningOfMonth.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (AccountingProcedureForIAAtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (AccountingProcedureForIAAtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN CostOfNMA_AtBeginningOfMonth AS IACost
	|		ON (IACost.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IACost.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN PreliminaryCostOfIa AS PreliminaryCostOfIa
	|		ON (PreliminaryCostOfIa.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (PreliminaryCostOfIa.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN AmortizationOfNMA_AtBeginningOfMonth AS IntangibleAssetsAmortizationCharge
	|		ON (IntangibleAssetsAmortizationCharge.Organization = ListOfIA.Organization)
	|			AND (IntangibleAssetsAmortizationCharge.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IntangibleAssetsAmortizationCharge.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentAtBeginningOfMonth
	|		ON (ImpairmentAtBeginningOfMonth.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (ImpairmentAtBeginningOfMonth.BegOfMonth = ListOfIA.BegOfMonth)
	|
	|		LEFT JOIN IntangibleAssetsRegistrationPlace AS IntangibleAssetsRegistrationPlace
	|		ON (IntangibleAssetsRegistrationPlace.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IntangibleAssetsRegistrationPlace.BegOfMonth = ListOfIA.BegOfMonth)
	|			AND (IntangibleAssetsRegistrationPlace.ParameterPeriod = ListOfIA.ParameterPeriod)
	|
	|		LEFT JOIN IntangibleAssetsRegistrationPlace AS PlaceOfRegistrationOfIAAtBeginningOfMonth
	|		ON (PlaceOfRegistrationOfIAAtBeginningOfMonth.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (PlaceOfRegistrationOfIAAtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (PlaceOfRegistrationOfIAAtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN InitialIntangibleAssetsInformation AS InitialIntangibleAssetsInformation
	|		ON (InitialIntangibleAssetsInformation.Organization = ListOfIA.Organization)
	|			AND (InitialIntangibleAssetsInformation.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (InitialIntangibleAssetsInformation.BegOfMonth = ListOfIA.BegOfMonth)
	|			AND (InitialIntangibleAssetsInformation.ParameterPeriod = ListOfIA.ParameterPeriod)
	|
	|		LEFT JOIN IADepreciationParametersBookkeepingAndTaxAccounting AS IADepreciationParametersBookkeepingAndTaxAccounting
	|		ON (IADepreciationParametersBookkeepingAndTaxAccounting.Organization = ListOfIA.Organization)
	|			AND (IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IADepreciationParametersBookkeepingAndTaxAccounting.BegOfMonth = ListOfIA.BegOfMonth)
	|			AND (IADepreciationParametersBookkeepingAndTaxAccounting.ParameterPeriod = ListOfIA.ParameterPeriod)
	|
	|		LEFT JOIN IABookkeepingProcedureBookkeepingAndTaxAccounting AS IABookkeepingProcedureBookkeepingAndTaxAccounting
	|		ON (IABookkeepingProcedureBookkeepingAndTaxAccounting.Organization = ListOfIA.Organization)
	|			AND (IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IABookkeepingProcedureBookkeepingAndTaxAccounting.BegOfMonth = ListOfIA.BegOfMonth)
	|			AND (IABookkeepingProcedureBookkeepingAndTaxAccounting.ParameterPeriod = ListOfIA.ParameterPeriod)
	|
	|		LEFT JOIN IABookkeepingProcedureBookkeepingAndTaxAccounting AS AccountingProcedureForNMABU_AtBeginningOfMonth
	|		ON (AccountingProcedureForNMABU_AtBeginningOfMonth.Organization = ListOfIA.Organization)
	|			AND (AccountingProcedureForNMABU_AtBeginningOfMonth.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (AccountingProcedureForNMABU_AtBeginningOfMonth.BegOfMonth = &BegOfMonth)
	|			AND (AccountingProcedureForNMABU_AtBeginningOfMonth.ParameterPeriod = &EndOfPreviousMonth)
	|
	|		LEFT JOIN IntangibleAssetsOperatingTime AS IntangibleAssetsOperatingTime
	|		ON (IntangibleAssetsOperatingTime.IntangibleAsset = IntangibleAssetsAccountingProcedure.IntangibleAsset)
	|
	|		LEFT JOIN IntangibleAssetsOperatingTime_AsOfDateOfLastChange AS IntangibleAssetsOperatingTime_AsOfDateOfLastChange
	|		ON (IntangibleAssetsOperatingTime_AsOfDateOfLastChange.IntangibleAsset = IntangibleAssetsAccountingProcedure.IntangibleAsset)
	|
	|WHERE
	|	ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.DepreciationAccrualAccounting, FALSE)
	|
	|	AND (NOT ListOfIA.ThisIsAnAdditionalAccrual
	|		OR ISNULL(AccountingProcedureForNMABU_AtBeginningOfMonth.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting))
	|";	
	
	QueryText = StrReplace(
		QueryText, 
		"&ActualUsefulLife", 
		NonCurrentAssetsInternal.FieldTextActualUsefulLife("InitialIntangibleAssetsInformation.DateOfRecognitionAccounting"));
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfNMAsWithModifiedParameters_Y
	
	QueryText = 
	"SELECT
	|	ChangesTo_Y.Period AS Period,
	|	ChangesTo_Y.Recorder AS Recorder,
	|	ChangesTo_Y.IntangibleAsset AS IntangibleAsset,
	|	ChangesTo_Y.Organization AS Organization,
	|	(ChangesTo_Y.BegOfMonth = &BeginningOfPreviousMonth) AS ThisIsAnAdditionalAccrual,
	|	CAST(ChangesTo_Y.IntangibleAsset AS Catalog.IntangibleAssets).KindOfAccountingObject AS KindOfAccountingObject,
	|	ISNULL(PreliminaryCostOfIa.PreliminaryCostExceedsActualMA, FALSE) AS PreliminaryCostExceedsActualMA,
	|	ISNULL(PreliminaryCostOfIa.PreliminaryCostExceedsActualAC, FALSE) AS PreliminaryCostExceedsActualAC,
	|
	|	ISNULL(ChangesTo_Y.FinancialAccountingGroup,  IntangibleAssetsAccountingProcedure.FinancialAccountingGroup)  AS FinancialAccountingGroup,
	|	ISNULL(ChangesTo_Y.LineOfBusiness, IntangibleAssetsAccountingProcedure.LineOfBusiness) AS LineOfBusiness,
	|
	|	ListOfIA.RevaluationMethod AS RevaluationMethod,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	// ResourceAssigned
	|	CASE 
	|		WHEN ISNULL(ChangesTo_Y.DepreciationMethod, IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod) = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(ChangesTo_Y.EstimatedRunningTime, IntangibleAssetsAccountingProcedure.EstimatedRunningTime)
	|		ELSE ISNULL(ChangesTo_Y.UsefulLifeMonths, IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth)
	|	END AS ResourceAssigned,
	|
	// LifeSpentCurrentPeriod
	|	CAST(CAST(CASE 
	|		WHEN ISNULL(ChangesTo_Y.DepreciationMethod, IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod) = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0)
	|		ELSE 1
	|	END AS NUMBER(15,9)) * CAST(ChangesTo_Y.ValidityPeriod AS NUMBER(15,9)) / CAST(DAY(ChangesTo_Y.EndOfMonth) AS NUMBER(15,9)) AS NUMBER(31,9)) AS LifeSpentCurrentPeriod,
	|	  
	// LifeSpentPastPeriod
	|	CASE 
	|		WHEN BEGINOFPERIOD(ISNULL(ChangesTo_Y.LastChangeDate, IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate), MONTH) = ChangesTo_Y.BegOfMonth
	|			THEN CAST(0 AS NUMBER(20,8))
	|	
	|		WHEN ISNULL(ChangesTo_Y.LastChangeDate, IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate) IS NULL
	|			THEN CAST(0 AS NUMBER(20,8))
	|
	|		WHEN ISNULL(ChangesTo_Y.DepreciationMethod, IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod) = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			THEN CASE
	|					WHEN ChangesTo_Y.BegOfMonth = &BeginningOfPreviousMonth
	|						THEN CAST(ISNULL(IntangibleAssetsOperatingTime.OutputAtBeginningOfPreviousMonth, 0) AS NUMBER(20,8))
	|					ELSE CAST(ISNULL(IntangibleAssetsOperatingTime.OutputAtBeginningOfMonth, 0)
	|									- ISNULL(IntangibleAssetsOperatingTime_AsOfDateOfLastChange.VolumeOfMaProduction, 0) AS NUMBER(20,8))
	|				END
	|
	|		ELSE
	|			CAST((DATEDIFF(ISNULL(ChangesTo_Y.LastChangeDate, IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate), ENDOFPERIOD(ISNULL(ChangesTo_Y.LastChangeDate, IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate), MONTH), DAY) + 1) / DAY(ENDOFPERIOD(ISNULL(ChangesTo_Y.LastChangeDate, IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate), MONTH))
	|			+ DATEDIFF(BEGINOFPERIOD(DATEADD(ISNULL(ChangesTo_Y.LastChangeDate, IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate), MONTH, 1), MONTH), ChangesTo_Y.EndOfMonth, MONTH) AS NUMBER(31,9))
	|	END AS LifeSpentPastPeriod,
	|
	// WorkedMonthsFullYears
	|	CASE
	|		WHEN YEAR(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting) <> YEAR(ChangesTo_Y.BegOfMonth) THEN
	|			13 - MONTH(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting)
	|				+ 12 * (YEAR(ChangesTo_Y.BegOfMonth) - YEAR(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting) - 1)
	|		ELSE 0
	|	END AS WorkedMonthsFullYears,
	|
	|	ISNULL(ChangesTo_Y.AccrueDepreciationOrAmortization, ISNULL(ListOfIA.AccrueDepreciationOrAmortization, FALSE)) AS AccrueDepreciationOrAmortization,
	|	ISNULL(ChangesTo_Y.ExpenseItem, ListOfIA.ExpenseItem) AS ExpenseItem,
	|	ISNULL(ChangesTo_Y.DimensionOfExpenses, ListOfIA.DimensionOfExpenses) AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN ISNULL(ChangesTo_Y.ExpensesBusinessUnit, ListOfIA.ExpensesBusinessUnit) <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ISNULL(ChangesTo_Y.ExpensesBusinessUnit, ListOfIA.ExpensesBusinessUnit) 
	|		ELSE ISNULL(ChangesTo_Y.Department, IntangibleAssetsRegistrationPlace.Department) 
	|	END AS ExpensesBusinessUnit,
	|
	|	CASE
	|		WHEN ISNULL(ChangesTo_Y.ExpensesBusinessUnit, ListOfIA.ExpensesBusinessUnit) <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ISNULL(ChangesTo_Y.ExpenseLineOfBusiness, ListOfIA.ExpenseLineOfBusiness) 
	|		ELSE ISNULL(ChangesTo_Y.LineOfBusiness, IntangibleAssetsAccountingProcedure.LineOfBusiness) 
	|	END AS ExpenseLineOfBusiness,
	|
	|	ISNULL(ChangesTo_Y.DepreciationRecordMethod, ListOfIA.DepreciationRecordMethod) AS DepreciationRecordMethod,
	|	ISNULL(ChangesTo_Y.TransferExpensesToAnotherCompany, ISNULL(ListOfIA.TransferExpensesToAnotherCompany, FALSE)) AS TransferExpensesToAnotherCompany,
	|	ISNULL(ChangesTo_Y.CompanyRecipientOfExpenses, ListOfIA.CompanyRecipientOfExpenses) AS CompanyRecipientOfExpenses,
	|
	// NetBookValue
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ChangesTo_Y.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfIa.CostInManagementAccounting, 0)
	|		ELSE ISNULL(IACost.Cost, 0) - ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0)
	|	END AS NetBookValue,	
	|
	// NetBookValueLocal
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ChangesTo_Y.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfIa.CostInAccounting, 0)
	|		ELSE ISNULL(IACost.LocalCost, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|	END AS NetBookValueLocal,	
	|
	|	0 AS CostAtBeginningOfYear,
	|
	// Cost
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ChangesTo_Y.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfIa.CostInManagementAccounting, 0)
	|		WHEN ChangesTo_Y.BegOfMonth = &BeginningOfPreviousMonth
	|			THEN 0
	|		ELSE ISNULL(IACost.Cost, 0)
	|	END AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ChangesTo_Y.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfIa.CostInAccounting, 0)
	|		WHEN ChangesTo_Y.BegOfMonth = &BeginningOfPreviousMonth
	|			THEN 0
	|		ELSE ISNULL(IACost.LocalCost, 0)
	|	END AS LocalCost,
	|
	|	ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0) AS Depreciation,
	|	ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0) AS DepreciationLocal,
	|
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceLocal, 0) AS ImpairmentBalanceLocal,
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceMan, 0) AS ImpairmentBalanceMan,
	|
	|	ChangesTo_Y.CostUpdate AS CostUpdate,
	|	ChangesTo_Y.LocalCostUpdate AS LocalCostUpdate,
	|	ChangesTo_Y.DepreciationUpdate AS DepreciationUpdate,
	|	ChangesTo_Y.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|
	|	ISNULL(ChangesTo_Y.Department, IntangibleAssetsRegistrationPlace.Department) AS Department,
	|
	|	ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0) AS OutputVolume,
	|
	|	ISNULL(ChangesTo_Y.UsefulLifeMonths, ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths, 0)) AS UsefulLifeMonths,
	|	ISNULL(ChangesTo_Y.AccelerationFactor, ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.AccelerationFactor, 0)) AS AccelerationFactor,
	|	ISNULL(ChangesTo_Y.ResidualValueMan, ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueMan, 0)) AS ResidualValueMan,
	|	ISNULL(ChangesTo_Y.ResidualValueLocal, ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueLocal, 0)) AS ResidualValueLocal,
	|	ISNULL(ChangesTo_Y.DepreciationMethod, IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod) AS DepreciationMethod
	|
	|INTO ListOfNMAsWithModifiedParameters_Y
	|
	|FROM
	|	ChangesTo_Y AS ChangesTo_Y
	|
	|		LEFT JOIN ListOfAccountingObjects_ AS ListOfIA
	|		ON (ListOfIA.Organization = ChangesTo_Y.Organization)
	|			AND (ListOfIA.IntangibleAsset = ChangesTo_Y.IntangibleAsset)
	|			AND (ListOfIA.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN IntangibleAssetsAccountingProcedure AS IntangibleAssetsAccountingProcedure
	|		ON (IntangibleAssetsAccountingProcedure.IntangibleAsset = ChangesTo_Y.IntangibleAsset)
	|			AND (IntangibleAssetsAccountingProcedure.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|			AND (IntangibleAssetsAccountingProcedure.ParameterPeriod = ChangesTo_Y.ParameterPeriod)
	|
	|		LEFT JOIN CostOfNMA_AtBeginningOfMonth AS IACost
	|		ON (IACost.IntangibleAsset = ChangesTo_Y.IntangibleAsset)
	|			AND (IACost.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN PreliminaryCostOfIa AS PreliminaryCostOfIa
	|		ON (PreliminaryCostOfIa.IntangibleAsset = ChangesTo_Y.IntangibleAsset)
	|			AND (PreliminaryCostOfIa.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN AmortizationOfNMA_AtBeginningOfMonth AS IntangibleAssetsAmortizationCharge
	|		ON (IntangibleAssetsAmortizationCharge.Organization = ChangesTo_Y.Organization)
	|			AND (IntangibleAssetsAmortizationCharge.IntangibleAsset = ChangesTo_Y.IntangibleAsset)
	|			AND (IntangibleAssetsAmortizationCharge.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentAtBeginningOfMonth
	|		ON (ImpairmentAtBeginningOfMonth.IntangibleAsset = ChangesTo_Y.IntangibleAsset)
	|			AND (ImpairmentAtBeginningOfMonth.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|
	|		LEFT JOIN IntangibleAssetsRegistrationPlace AS IntangibleAssetsRegistrationPlace
	|		ON (IntangibleAssetsRegistrationPlace.IntangibleAsset = ChangesTo_Y.IntangibleAsset)
	|			AND (IntangibleAssetsRegistrationPlace.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|			AND (IntangibleAssetsRegistrationPlace.ParameterPeriod = ChangesTo_Y.ParameterPeriod)
	|
	|		LEFT JOIN InitialIntangibleAssetsInformation AS InitialIntangibleAssetsInformation
	|		ON (InitialIntangibleAssetsInformation.Organization = ChangesTo_Y.Organization)
	|			AND (InitialIntangibleAssetsInformation.IntangibleAsset = ChangesTo_Y.IntangibleAsset)
	|			AND (InitialIntangibleAssetsInformation.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|			AND (InitialIntangibleAssetsInformation.ParameterPeriod = ChangesTo_Y.ParameterPeriod)
	|
	|		LEFT JOIN IntangibleAssetAmortizationParametersManagementAccounting AS IntangibleAssetAmortizationParametersManagementAccounting
	|		ON (IntangibleAssetAmortizationParametersManagementAccounting.Organization = ChangesTo_Y.Organization)
	|			AND (IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = ChangesTo_Y.IntangibleAsset)
	|			AND (IntangibleAssetAmortizationParametersManagementAccounting.BegOfMonth = ChangesTo_Y.BegOfMonth)
	|			AND (IntangibleAssetAmortizationParametersManagementAccounting.ParameterPeriod = ChangesTo_Y.ParameterPeriod)
	|
	|		LEFT JOIN IntangibleAssetsOperatingTime AS IntangibleAssetsOperatingTime
	|		ON (IntangibleAssetsOperatingTime.IntangibleAsset = IntangibleAssetsAccountingProcedure.IntangibleAsset)
	|
	|		LEFT JOIN IntangibleAssetsOperatingTime_AsOfDateOfLastChange AS IntangibleAssetsOperatingTime_AsOfDateOfLastChange
	|		ON (IntangibleAssetsOperatingTime_AsOfDateOfLastChange.IntangibleAsset = IntangibleAssetsAccountingProcedure.IntangibleAsset)
	|
	|INDEX BY
	|	ThisIsAnAdditionalAccrual,
	|	IntangibleAsset";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region ListOfNMASWithChangedParameters_BU_MU
	
	QueryText = 
	"SELECT
	|	ChangesTo_BU_M.Period,
	|	ChangesTo_BU_M.Recorder,
	|	ChangesTo_BU_M.IntangibleAsset AS IntangibleAsset,
	|	ChangesTo_BU_M.Organization,
	|	(ChangesTo_BU_M.BegOfMonth = &BeginningOfPreviousMonth) AS ThisIsAnAdditionalAccrual,
	|	CAST(ChangesTo_BU_M.IntangibleAsset AS Catalog.IntangibleAssets).KindOfAccountingObject AS KindOfAccountingObject,
	|	ISNULL(PreliminaryCostOfIa.PreliminaryCostExceedsActualAC, FALSE) AS PreliminaryCostExceedsActual,
	|
	|	ListOfIA.RevaluationMethod AS RevaluationMethod,
	|	ListOfIA.PostingOptionForImpairedFADepreciation AS PostingOptionForImpairedFADepreciation,
	|
	|	ISNULL(ChangesTo_BU_M.FinancialAccountingGroup,  IntangibleAssetsAccountingProcedure.FinancialAccountingGroup)  AS FinancialAccountingGroup,
	|	ISNULL(ChangesTo_BU_M.LineOfBusiness, IntangibleAssetsAccountingProcedure.LineOfBusiness) AS LineOfBusiness,
	|
	// ResourceAssigned
	|	CASE 
	|		WHEN InitialIntangibleAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(ChangesTo_BU_M.EstimatedRunningTime, IntangibleAssetsAccountingProcedure.EstimatedRunningTime)
	|		ELSE ISNULL(ChangesTo_BU_M.UsefulLifeMonths, IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC)
	|	END AS ResourceAssigned,
	|
	// LifeSpentCurrentPeriod
	|	CAST(CASE 
	|		WHEN InitialIntangibleAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0)
	|		ELSE 1
	|	END * ChangesTo_BU_M.ValidityPeriod / DAY(ChangesTo_BU_M.EndOfMonth) AS NUMBER(20, 8)) AS LifeSpentCurrentPeriod,
	|	  
	// LifeSpentPastPeriod
	|	CAST(CASE 
	|		WHEN InitialIntangibleAssetsInformation.DateOfRecognitionAccounting IS NULL
	|			THEN 0
	|		WHEN BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, MONTH) = ChangesTo_BU_M.BegOfMonth
	|			THEN 0
	|		WHEN InitialIntangibleAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			THEN ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0) - ISNULL(IntangibleAssetsOperatingTime_AsOfDateOfLastChange.VolumeOfACOutput, 0)
	// 		Explanation of the formula: [Number of days worked per month of acceptance] / [total days per month.acceptance] + [number of months after acceptance before the beginning of the month of calculation].
	|		ELSE
	|			(DATEDIFF(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, ENDOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, MONTH), DAY) + 1) / DAY(ENDOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, MONTH))
	|			+ DATEDIFF(BEGINOFPERIOD(DATEADD(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, MONTH, 1), MONTH), ChangesTo_BU_M.EndOfMonth, MONTH)
	|	END AS NUMBER(20,8)) AS LifeSpentPastPeriod,
	|
	// WorkedMonthsFullYears
	|	CASE
	|		WHEN YEAR(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting) <> YEAR(ChangesTo_BU_M.BegOfMonth) THEN
	|			13 - MONTH(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting)
	|				+ 12 * (YEAR(ChangesTo_BU_M.BegOfMonth) - YEAR(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting) - 1)
	|		ELSE 0
	|	END AS WorkedMonthsFullYears,
	|
	|	ISNULL(ChangesTo_BU_M.AccrueDepreciationOrAmortization, ISNULL(ListOfIA.AccrueDepreciationOrAmortization, FALSE)) AS AccrueDepreciationOrAmortization,
	|	ISNULL(ChangesTo_BU_M.ExpenseItem, ListOfIA.ExpenseItem) AS ExpenseItem,
	|	ISNULL(ChangesTo_BU_M.DimensionOfExpenses, ListOfIA.DimensionOfExpenses) AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN ISNULL(ChangesTo_BU_M.ExpensesBusinessUnit, ListOfIA.ExpensesBusinessUnit) <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ISNULL(ChangesTo_BU_M.ExpensesBusinessUnit, ListOfIA.ExpensesBusinessUnit) 
	|		ELSE ISNULL(ChangesTo_BU_M.Department, IntangibleAssetsRegistrationPlace.Department) 
	|	END AS ExpensesBusinessUnit,
	|
	|	CASE
	|		WHEN ISNULL(ChangesTo_BU_M.ExpensesBusinessUnit, ListOfIA.ExpensesBusinessUnit) <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN ISNULL(ChangesTo_BU_M.ExpenseLineOfBusiness, ListOfIA.ExpenseLineOfBusiness) 
	|		ELSE ISNULL(ChangesTo_BU_M.LineOfBusiness, IntangibleAssetsAccountingProcedure.LineOfBusiness) 
	|	END AS ExpenseLineOfBusiness,
	|
	|	ISNULL(ChangesTo_BU_M.DepreciationRecordMethod, ListOfIA.DepreciationRecordMethod) AS DepreciationRecordMethod,
	|	ISNULL(ChangesTo_BU_M.TransferExpensesToAnotherCompany, ISNULL(ListOfIA.TransferExpensesToAnotherCompany, FALSE)) AS TransferExpensesToAnotherCompany,
	|	ISNULL(ChangesTo_BU_M.CompanyRecipientOfExpenses, ListOfIA.CompanyRecipientOfExpenses) AS CompanyRecipientOfExpenses,
	|
	// NetBookValue
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ChangesTo_BU_M.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfIa.CostInManagementAccounting, 0)
	|		ELSE ISNULL(IACost.Cost, 0) - ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0)
	|	END - CASE 
	|				WHEN NOT ChangesTo_BU_M.ResidualValueMan IS NULL
	|					THEN ChangesTo_BU_M.ResidualValueMan
	|				WHEN NOT IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan IS NULL
	|					THEN IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan
	|				ELSE 0
	|			END AS NetBookValue,	
	|
	// NetBookValueLocal
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ChangesTo_BU_M.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfIa.CostInAccounting, 0)
	|		ELSE ISNULL(IACost.LocalCost, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|	END - CASE 
	|				WHEN NOT ChangesTo_BU_M.ResidualValueMan IS NULL
	|					THEN ChangesTo_BU_M.ResidualValueMan
	|				WHEN NOT IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan IS NULL
	|					THEN IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan
	|				ELSE 0
	|			END AS NetBookValueLocal,	
	|
	|	0 AS CostAtBeginningOfYear,
	|
	// LocalCost
	|	CASE 
	|		WHEN BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH) = ChangesTo_BU_M.BegOfMonth
	|			THEN ISNULL(PreliminaryCostOfIa.CostInAccounting, 0)
	|		WHEN ChangesTo_BU_M.BegOfMonth = &BeginningOfPreviousMonth
	|			THEN 0
	|		ELSE ISNULL(IACost.LocalCost, 0)
	|	END AS LocalCost,
	|
	|	ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0) AS DepreciationLocal,
	|
	|	ISNULL(ImpairmentAtBeginningOfMonth.ImpairmentBalanceLocal, 0) AS ImpairmentBalanceLocal,
	|
	|	ChangesTo_BU_M.LocalCostUpdate AS LocalCostUpdate,
	|	ChangesTo_BU_M.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|
	|	ISNULL(ChangesTo_BU_M.Department, IntangibleAssetsRegistrationPlace.Department) AS Department,
	|
	|	ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0) AS OutputVolume,
	|
	|	ISNULL(ChangesTo_BU_M.UsefulLifeMonths, ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC, 0)) AS UsefulLifeMonths,
	|	ISNULL(ChangesTo_BU_M.ZoomRatio, ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.DepreciationAccrualFactor, 0)) AS AccelerationFactor,
	|	ISNULL(ChangesTo_BU_M.ResidualValueMan, ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan, 0)) AS ResidualValueLocal,
	|	ISNULL(ChangesTo_BU_M.DepreciationMethod, InitialIntangibleAssetsInformation.DepreciationMethodAccounting) AS DepreciationMethod
	|
	|INTO ListOfNMASWithChangedParameters_BU_MU
	|
	|FROM
	|	ChangesTo_BU_M AS ChangesTo_BU_M
	|
	|		LEFT JOIN ListOfAccountingObjects_BU_MU AS ListOfIA
	|		ON (ListOfIA.Organization = ChangesTo_BU_M.Organization)
	|			AND (ListOfIA.IntangibleAsset = ChangesTo_BU_M.IntangibleAsset)
	|			AND (ListOfIA.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN IntangibleAssetsAccountingProcedure AS IntangibleAssetsAccountingProcedure
	|		ON (IntangibleAssetsAccountingProcedure.IntangibleAsset = ChangesTo_BU_M.IntangibleAsset)
	|			AND (IntangibleAssetsAccountingProcedure.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|			AND (IntangibleAssetsAccountingProcedure.ParameterPeriod = ChangesTo_BU_M.ParameterPeriod)
	|
	|		LEFT JOIN CostOfNMA_AtBeginningOfMonth AS IACost
	|		ON (IACost.IntangibleAsset = ChangesTo_BU_M.IntangibleAsset)
	|			AND (IACost.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN PreliminaryCostOfIa AS PreliminaryCostOfIa
	|		ON (PreliminaryCostOfIa.IntangibleAsset = ChangesTo_BU_M.IntangibleAsset)
	|			AND (PreliminaryCostOfIa.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN AmortizationOfNMA_AtBeginningOfMonth AS IntangibleAssetsAmortizationCharge
	|		ON (IntangibleAssetsAmortizationCharge.Organization = ChangesTo_BU_M.Organization)
	|			AND (IntangibleAssetsAmortizationCharge.IntangibleAsset = ChangesTo_BU_M.IntangibleAsset)
	|			AND (IntangibleAssetsAmortizationCharge.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentAtBeginningOfMonth
	|		ON (ImpairmentAtBeginningOfMonth.IntangibleAsset = ChangesTo_BU_M.IntangibleAsset)
	|			AND (ImpairmentAtBeginningOfMonth.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|
	|		LEFT JOIN IntangibleAssetsRegistrationPlace AS IntangibleAssetsRegistrationPlace
	|		ON (IntangibleAssetsRegistrationPlace.IntangibleAsset = ChangesTo_BU_M.IntangibleAsset)
	|			AND (IntangibleAssetsRegistrationPlace.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|			AND (IntangibleAssetsRegistrationPlace.ParameterPeriod = ChangesTo_BU_M.ParameterPeriod)
	|
	|		LEFT JOIN InitialIntangibleAssetsInformation AS InitialIntangibleAssetsInformation
	|		ON (InitialIntangibleAssetsInformation.Organization = ChangesTo_BU_M.Organization)
	|			AND (InitialIntangibleAssetsInformation.IntangibleAsset = ChangesTo_BU_M.IntangibleAsset)
	|			AND (InitialIntangibleAssetsInformation.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|			AND (InitialIntangibleAssetsInformation.ParameterPeriod = ChangesTo_BU_M.ParameterPeriod)
	|
	|		LEFT JOIN IADepreciationParametersBookkeepingAndTaxAccounting AS IADepreciationParametersBookkeepingAndTaxAccounting
	|		ON (IADepreciationParametersBookkeepingAndTaxAccounting.Organization = ChangesTo_BU_M.Organization)
	|			AND (IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset = ChangesTo_BU_M.IntangibleAsset)
	|			AND (IADepreciationParametersBookkeepingAndTaxAccounting.BegOfMonth = ChangesTo_BU_M.BegOfMonth)
	|			AND (IADepreciationParametersBookkeepingAndTaxAccounting.ParameterPeriod = ChangesTo_BU_M.ParameterPeriod)
	|
	|		LEFT JOIN IntangibleAssetsOperatingTime AS IntangibleAssetsOperatingTime
	|		ON (IntangibleAssetsOperatingTime.IntangibleAsset = IntangibleAssetsAccountingProcedure.IntangibleAsset)
	|
	|		LEFT JOIN IntangibleAssetsOperatingTime_AsOfDateOfLastChange AS IntangibleAssetsOperatingTime_AsOfDateOfLastChange
	|		ON (IntangibleAssetsOperatingTime_AsOfDateOfLastChange.IntangibleAsset = IntangibleAssetsAccountingProcedure.IntangibleAsset)
	|
	|INDEX BY
	|	ThisIsAnAdditionalAccrual,
	|	IntangibleAsset";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region WaysToReflectDepreciation
	
	QueryText =
	"SELECT
	|	ListOfAllIA.DepreciationRecordMethod AS Ref
	|INTO TTWaysToReflectDepreciation
	|FROM
	|	ListOfAccountingObjects AS ListOfAllIA
	|WHERE
	|	NOT ListOfAllIA.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|
	|UNION ALL
	|
	|SELECT
	|	ChangesTo_Y.DepreciationRecordMethod
	|FROM
	|	ChangesTo_Y AS ChangesTo_Y
	|WHERE
	|	NOT ChangesTo_Y.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
	|
	|UNION ALL
	|
	|SELECT 
	|	ChangesTo_BU_M.DepreciationRecordMethod
	|FROM 
	|	ChangesTo_BU_M AS ChangesTo_BU_M
	|WHERE 
	|	NOT ChangesTo_BU_M.DepreciationRecordMethod IN (&EmptyWaysToReflectDepreciation)
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
	|INTO WaysToReflectDepreciation
	|FROM
	|	Document.ChangeIntangibleAssetFinancialDetails2_4.Depreciation AS TableDepreciation
	|WHERE
	|	TableDepreciation.Ref IN (SELECT WaysToReflectDepreciation.Ref FROM TTWaysToReflectDepreciation AS WaysToReflectDepreciation)
	|
	|INDEX BY
	|	DepreciationRecordMethod";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	IntangibleAssetsAmortizationChargeLocalization.AddRequestTextParametersForCalculatingDepreciation_(ListOfRequests, CalculationParameters);
	
EndProcedure

Procedure QueryTextCheckingCalculationParameters(ListOfRequests, CalculationParameters)

	#Region CheckingCalculationParameters_Y
	QueryText =
	"SELECT
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.IntangibleAsset AS AccountingObject,
	|	ListOfIA.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified
	|
	|INTO CheckingCalculationParameters_Y
	|
	|
	|FROM
	|	(SELECT
	|		ListOfIA.Organization AS Organization,
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|
			// AmountOfOperatingTimeIsNotSpecified
	|	 	ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			AND ListOfIA.ResourceAssigned = 0 AS AmountOfOperatingTimeIsNotSpecified
	|
	|	FROM
	|		ListOfNMAsParameters_UU AS ListOfIA
	|
	|	WHERE
	|		ListOfIA.AccrueDepreciationOrAmortization
	|		AND ListOfIA.NetBookValue > 0
	|
	|	) AS ListOfIA
	|
	|WHERE
	|	ListOfIA.AmountOfOperatingTimeIsNotSpecified
	|
	|INDEX BY
	|	AccountingObject
	|";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CheckingCalculationParametersOf_BU_M
	QueryText =
	"SELECT
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.IntangibleAsset AS AccountingObject,
	|	ListOfIA.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified
	|
	|INTO CheckingCalculationParametersOf_BU_M
	|
	|FROM
	|	(SELECT
	|		ListOfIA.Organization AS Organization,
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|
			// AmountOfOperatingTimeIsNotSpecified
	|		 ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			AND ListOfIA.ResourceAssigned = 0 AS AmountOfOperatingTimeIsNotSpecified
	|
	|	FROM
	|		ListOfNMASWithParameters_BU_MU AS ListOfIA
	|
	|			LEFT JOIN WaysToReflectDepreciation AS WaysToReflectDepreciation
	|			ON (WaysToReflectDepreciation.DepreciationRecordMethod = ListOfIA.DepreciationRecordMethod)
	|
	|	WHERE
	|		ListOfIA.AccrueDepreciationOrAmortization
	|		AND ListOfIA.NetBookValueLocal > 0
	|
	|	) AS ListOfIA
	|
	|WHERE
	|	ListOfIA.AmountOfOperatingTimeIsNotSpecified
	|	
	|INDEX BY
	|	AccountingObject";
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CheckingParametersForCalculatingChangesIn_Y
	QueryText =
	"SELECT
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.IntangibleAsset AS AccountingObject,
	|	ListOfIA.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified
	|
	|INTO CheckingParametersForCalculatingChangesIn_Y
	|
	|FROM
	|	(SELECT
	|		ListOfIA.Organization AS Organization,
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|
			// AmountOfOperatingTimeIsNotSpecified
	|		 ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			AND ListOfIA.ResourceAssigned = 0 AS AmountOfOperatingTimeIsNotSpecified
	|
	|	FROM
	|		ListOfNMAsWithModifiedParameters_Y AS ListOfIA
	|
	|	WHERE
	|		ListOfIA.AccrueDepreciationOrAmortization
	|		AND ListOfIA.NetBookValue > 0
	|
	|	) AS ListOfIA
	| 
	|WHERE
	|	ListOfIA.AmountOfOperatingTimeIsNotSpecified
	|
	|INDEX BY
	|	AccountingObject";
	
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region CheckingParametersOfCalculationOfChangeOf_BU_M
	QueryText =
	"SELECT
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.IntangibleAsset AS AccountingObject,
	|	ListOfIA.AmountOfOperatingTimeIsNotSpecified AS AmountOfOperatingTimeIsNotSpecified
	|
	|INTO CheckingParametersOfCalculationOfChangeOf_BU_M
	|
	|FROM
	|	(SELECT
	|		ListOfIA.Organization AS Organization,
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|
			// AmountOfOperatingTimeIsNotSpecified
	|		 ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			AND ListOfIA.ResourceAssigned = 0 AS AmountOfOperatingTimeIsNotSpecified
	|
	|	FROM
	|		ListOfNMASWithChangedParameters_BU_MU AS ListOfIA
	|
	|			LEFT JOIN WaysToReflectDepreciation AS WaysToReflectDepreciation
	|			ON (WaysToReflectDepreciation.DepreciationRecordMethod = ListOfIA.DepreciationRecordMethod)
	|
	|	WHERE
	|		ListOfIA.AccrueDepreciationOrAmortization 
	|		AND ListOfIA.NetBookValueLocal > 0
	|
	|	) AS ListOfIA
	|
	|WHERE
	|	ListOfIA.AmountOfOperatingTimeIsNotSpecified
	|
	|INDEX BY
	|	AccountingObject";
	
	ListOfRequests.Add(QueryText);
	#EndRegion

	IntangibleAssetsAmortizationChargeLocalization.AddRequestTextCheckingCalculationParameters(ListOfRequests, CalculationParameters);
	
EndProcedure

Procedure QueryTextNumberOfCalculationParameters(ListOfRequests, CalculationParameters)
	
	QueryText =
	"SELECT
	|	ISNULL(COUNT(DISTINCT ListOfAccountingObjects.IntangibleAsset), 0) AS DataVolume
	|FROM
	|	ListOfAccountingObjects AS ListOfAccountingObjects
	|";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextCalculationOfDepreciation_Y(ListOfRequests, CalculationParameters)

	QueryText = 
	"SELECT
	|	Depreciation.KindOfAccountingObject AS KindOfAccountingObject,
	|	Depreciation.CalculationPeriod AS CalculationPeriod,
	|	Depreciation.Organization AS Organization,
	|	Depreciation.Department AS Department,
	|	Depreciation.IntangibleAsset AS IntangibleAsset,
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
	|	Depreciation.DepreciationRecordMethod,
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
	|	ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS AccountingPolicyForFixedAssets,
	|	ISNULL(AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting, VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)) AS FixedAssetAccountingProcedureInLocalAccounting,
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
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
	|		ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|		ListOfIA.Period AS CalculationPeriod,
	|		ListOfIA.Organization AS Organization,
	|		CAST(ListOfIA.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
	|		ListOfIA.Department AS Department,
	|		ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfIA.LineOfBusiness AS LineOfBusiness,
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|		ListOfIA.ExpenseItem AS ExpenseItem,
	|		ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfIA.AmountOfUU AS AmountOfUU,
	|		ListOfIA.AmountAccounting AS AmountAccounting,
	|		ListOfIA.ImpairmentMA AS ImpairmentMA,
	|		ListOfIA.ImpairmentAC AS ImpairmentAC,
	|		ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfIA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|		ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		ListOfIA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfIA.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|		ListOfIA.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|		ListOfIA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		FALSE AS ThisIsAnAdditionalAccrual
	|	FROM
	|		CalculationOfDepreciation_ForCurrentMonth_UnchangedMA AS ListOfIA
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|		ListOfIA.Period,
	|		ListOfIA.Organization,
	|		CAST(ListOfIA.Organization AS Catalog.Companies).ParentCompany,
	|		ListOfIA.Department,
	|		ListOfIA.FinancialAccountingGroup,
	|		ListOfIA.LineOfBusiness,
	|		ListOfIA.IntangibleAsset,
	|		ListOfIA.ExpenseItem,
	|		ListOfIA.DimensionOfExpenses,
	|		ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfIA.DepreciationRecordMethod,
	|		ListOfIA.AmountOfUU,
	|		ListOfIA.AmountAccounting,
	|		ListOfIA.ImpairmentMA AS ImpairmentMA,
	|		ListOfIA.ImpairmentAC AS ImpairmentAC,
	|		ListOfIA.TransferExpensesToAnotherCompany,
	|		ListOfIA.CompanyRecipientOfExpenses,
	|		ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfIA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|		ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		ListOfIA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfIA.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|		VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS ProcedureForCalculatingDepreciationAC,
	|		ListOfIA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		FALSE AS ThisIsAnAdditionalAccrual
	|	FROM
	|		CalculationOfDepreciation_ForCurrentMonth_TakingIntoAccountChangesInMA AS ListOfIA
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|		ListOfIA.CalculationPeriod AS CalculationPeriod,
	|		ListOfIA.Organization AS Organization,
	|		CAST(ListOfIA.Organization AS Catalog.Companies).ParentCompany,
	|		ListOfIA.Department AS Department,
	|		ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfIA.LineOfBusiness AS LineOfBusiness,
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|		ListOfIA.ExpenseItem AS ExpenseItem,
	|		ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfIA.AmountOfUU AS AmountOfUU,
	|		ListOfIA.AmountAccounting AS AmountAccounting,
	|		0 AS ImpairmentMA,
	|		0 AS ImpairmentAC,
	|		ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfIA.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|		ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		0 AS ImpairmentBalanceLocal,
	|		0 AS ImpairmentBalanceMan,
	|		VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS ProcedureForCalculatingDepreciationAC,
	|		ListOfIA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		TRUE AS ThisIsAnAdditionalAccrual
	|	FROM
	|		CalculationOfDepreciation_ForLastMonthMA AS ListOfIA
	|
	|	) AS Depreciation
	|
	|		LEFT JOIN WaysToReflectDepreciation AS WaysToReflectDepreciation
	|		ON (WaysToReflectDepreciation.DepreciationRecordMethod = Depreciation.DepreciationRecordMethod)
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = Depreciation.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfMonth
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.IntangibleAsset = Depreciation.IntangibleAsset
	|";
	
	QueryText = StrReplace(QueryText, "&DistributionOfSumOfMa", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.AmountOfUU"));
	QueryText = StrReplace(QueryText, "&DistributionOfACAmount", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.AmountAccounting"));
	
	QueryText = StrReplace(QueryText, "&DistributionOfMaImpairment", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.ImpairmentMA"));
	QueryText = StrReplace(QueryText, "&DistributionOfACImpairment", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.ImpairmentAC"));
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextCalculationOfDepreciation_BU_MU(ListOfRequests, CalculationParameters)

	QueryText = 
	"SELECT
	|	Depreciation.KindOfAccountingObject AS KindOfAccountingObject,
	|	Depreciation.CalculationPeriod AS CalculationPeriod,
	|	Depreciation.Organization AS Organization,
	|	Depreciation.Department AS Department,
	|	Depreciation.IntangibleAsset AS IntangibleAsset,
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
	|	ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) AS AccountingPolicyForFixedAssets,
	|	ISNULL(AccountingPolicy.PostingOptionForImpairedFADepreciation, VALUE(Enum.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment)) AS PostingOptionForImpairedFADepreciation,
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
	|		ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|		ListOfIA.Period AS CalculationPeriod,
	|		ListOfIA.Organization AS Organization,
	|		CAST(ListOfIA.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
	|		ListOfIA.Department AS Department,
	|		ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfIA.LineOfBusiness AS LineOfBusiness,
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|		ListOfIA.ExpenseItem AS ExpenseItem,
	|		ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfIA.AmountAccounting AS AmountAccounting,
	|		ListOfIA.ImpairmentAC AS ImpairmentAC,
	|		ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		ListOfIA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		ListOfIA.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|		ListOfIA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		FALSE AS ThisIsAnAdditionalAccrual
	|	FROM
	|		CalculationOfDepreciation_ForCurrentMonth_UnchangedBU_MU AS ListOfIA
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|		ListOfIA.Period,
	|		ListOfIA.Organization,
	|		CAST(ListOfIA.Organization AS Catalog.Companies).ParentCompany,
	|		ListOfIA.Department,
	|		ListOfIA.FinancialAccountingGroup,
	|		ListOfIA.LineOfBusiness,
	|		ListOfIA.IntangibleAsset,
	|		ListOfIA.ExpenseItem,
	|		ListOfIA.DimensionOfExpenses,
	|		ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfIA.DepreciationRecordMethod,
	|		ListOfIA.AmountAccounting,
	|		ListOfIA.ImpairmentAC AS ImpairmentAC,
	|		ListOfIA.TransferExpensesToAnotherCompany,
	|		ListOfIA.CompanyRecipientOfExpenses,
	|		ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		ListOfIA.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS ProcedureForCalculatingDepreciationAC,
	|		ListOfIA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		FALSE AS ThisIsAnAdditionalAccrual
	|	FROM
	|		CalculationOfDepreciation_ForCurrentMonth_TakingIntoAccountChangesInBU_MU AS ListOfIA
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ListOfIA.KindOfAccountingObject AS KindOfAccountingObject,
	|		ListOfIA.CalculationPeriod AS CalculationPeriod,
	|		ListOfIA.Organization AS Organization,
	|		CAST(ListOfIA.Organization AS Catalog.Companies).ParentCompany,
	|		ListOfIA.Department AS Department,
	|		ListOfIA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		ListOfIA.LineOfBusiness AS LineOfBusiness,
	|		ListOfIA.IntangibleAsset AS IntangibleAsset,
	|		ListOfIA.ExpenseItem AS ExpenseItem,
	|		ListOfIA.DimensionOfExpenses AS DimensionOfExpenses,
	|		ListOfIA.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|		ListOfIA.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|		ListOfIA.DepreciationRecordMethod AS DepreciationRecordMethod,
	|		ListOfIA.AmountAccounting AS AmountAccounting,
	|		0 AS ImpairmentAC,
	|		ListOfIA.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		ListOfIA.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		ListOfIA.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		ListOfIA.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|		ListOfIA.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		0 AS ImpairmentBalanceLocal,
	|		VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS ProcedureForCalculatingDepreciationAC,
	|		ListOfIA.VersionOfAccrualMethod AS VersionOfAccrualMethod,
	|		TRUE AS ThisIsAnAdditionalAccrual
	|	FROM
	|		CalculationOfDepreciation_ForLastMonthBU_MU AS ListOfIA
	|
	|	) AS Depreciation
	|
	|		LEFT JOIN WaysToReflectDepreciation AS WaysToReflectDepreciation
	|		ON (WaysToReflectDepreciation.DepreciationRecordMethod = Depreciation.DepreciationRecordMethod)
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Organization = Depreciation.ParentCompany
	|			AND AccountingPolicy.Period = &EndOfMonth
	|
	|		LEFT JOIN ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.IntangibleAsset = Depreciation.IntangibleAsset
	|";
	
	QueryText = StrReplace(QueryText, "&DistributionOfACAmount", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.AmountAccounting"));
	
	QueryText = StrReplace(QueryText, "&DistributionOfACImpairment", NonCurrentAssetsInternal.TextOfDepreciationAmountDistribution("Depreciation.ImpairmentAC"));
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextAccruedDepreciation(ListOfRequests, CalculationParameters)

	ListOfSubqueries = New Array;
	
	SubqueryText =  
	"	SELECT
	|		DepreciationCalculation.KindOfAccountingObject AS KindOfAccountingObject,
	|		DepreciationCalculation.CalculationPeriod AS CalculationPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.DebitBusinessUnit AS DebitBusinessUnit,
	|		DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
	|		DepreciationCalculation.CGU AS CGU,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.CorLineOfBusiness AS CorLineOfBusiness,
	|		DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|		DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|		DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|
	|		DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriod,
	|		DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriod,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.LifeSpentPastPeriod
	|			ELSE 0
	|		END AS LifeSpentPastPeriodAccounting,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.LifeSpentCurrentPeriod
	|			ELSE 0
	|		END AS LifeSpentCurrentPeriodAccounting,
	|
	|		DepreciationCalculation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.CostUsedToCalculateDepreciationLocal
	|			ELSE 0
	|		END AS CostUsedToCalculateDepreciationLocal,
	|
	|		DepreciationCalculation.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		DepreciationCalculation.ImpairmentBalanceMan AS ImpairmentBalanceMan,
	|
	|		DepreciationCalculation.ThisIsAnAdditionalAccrual AS ThisIsAnAdditionalAccrual,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.ThisIsAnAdditionalAccrual
	|			ELSE FALSE
	|		END AS ThisIsAdditionalChargeAccounting,
	|
	|		DepreciationCalculation.AccountingPolicyForFixedAssets AS AccountingProcedureMA,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.AccountingPolicyForFixedAssets
	|			ELSE UNDEFINED
	|		END AS AccountingProcedureAC,
	|
	|		DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|
	|		CASE 
	|			WHEN DepreciationCalculation.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting)
	|				THEN DepreciationCalculation.ProcedureForCalculatingDepreciationOfMa
	|			ELSE UNDEFINED
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
	|		DepreciationCalculation.KindOfAccountingObject AS KindOfAccountingObject,
	|		DepreciationCalculation.CalculationPeriod AS CalculationPeriod,
	|		DepreciationCalculation.Organization AS Organization,
	|		DepreciationCalculation.Department AS Department,
	|		DepreciationCalculation.DebitBusinessUnit AS DebitBusinessUnit,
	|		DepreciationCalculation.IntangibleAsset AS IntangibleAsset,
	|		DepreciationCalculation.CGU AS CGU,
	|		DepreciationCalculation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		DepreciationCalculation.LineOfBusiness AS LineOfBusiness,
	|		DepreciationCalculation.CorLineOfBusiness AS CorLineOfBusiness,
	|		DepreciationCalculation.ExpenseItem AS ExpenseItem,
	|		DepreciationCalculation.DimensionOfExpenses AS DimensionOfExpenses,
	|		DepreciationCalculation.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|		DepreciationCalculation.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|		0 AS LifeSpentPastPeriod,
	|		0 AS LifeSpentCurrentPeriod,
	|		DepreciationCalculation.LifeSpentPastPeriod AS LifeSpentPastPeriodAccounting,
	|		DepreciationCalculation.LifeSpentCurrentPeriod AS LifeSpentCurrentPeriodAccounting,
	|		0 AS CostUsedToCalculateDepreciationManag,
	|		DepreciationCalculation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal,
	|		DepreciationCalculation.ImpairmentBalanceLocal AS ImpairmentBalanceLocal,
	|		0 AS ImpairmentBalanceMan,
	|		FALSE AS ThisIsAnAdditionalAccrual,
	|		DepreciationCalculation.ThisIsAnAdditionalAccrual AS ThisIsAdditionalChargeAccounting,
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
	|		CalculationOfDepreciation_BU_MU AS DepreciationCalculation";
	ListOfSubqueries.Add(SubqueryText);
	
	IntangibleAssetsAmortizationChargeLocalization.AddTextOfSubqueryAccruedDepreciation(ListOfSubqueries, CalculationParameters);
	
	SubqueryText = StrConcat(ListOfSubqueries, TMCommonUse.QuerySeparatorInJoin());
	
	RequestTextTTAccruedDepreciation(ListOfRequests, SubqueryText);
	
EndProcedure

Function QueryTextNumberOfProcessedData(CalculationParameters)

	QueryText = IntangibleAssetsAmortizationChargeLocalization.QueryTextNumberOfProcessedData(CalculationParameters); 
	
	If QueryText = Undefined Then
		
		QueryText =  
		"SELECT
		|	ISNULL(COUNT(DepreciationCalculation.IntangibleAsset), 0) AS DataVolume
		|FROM
		|	(SELECT
		|		DepreciationCalculation.IntangibleAsset AS IntangibleAsset
		|	FROM
		|		CalculationOfDepreciation_Y AS DepreciationCalculation
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DepreciationCalculation.IntangibleAsset
		|	FROM
		|		CalculationOfDepreciation_BU_MU AS DepreciationCalculation) AS DepreciationCalculation";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// 
// Parameters:
//  RequestTextParameters - See QueryTextParametersAmountOfMaDepreciation
// 
// Returns:
//  String - Query text
Function QueryTextAmountOfMaDepreciation(RequestTextParameters)
	
	QueryText =
	"CASE 
	|	WHEN NOT ListOfIA.AccrueDepreciationOrAmortization 
	|			OR (&NetBookValue - &AmountOfAdditionalCharge - &ResidualValueMan - &ImpairmentBalance) <= 0
	|				AND ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|			OR &NetBookValue <= 0
	|				AND NOT ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|			OR ListOfIA.LifeSpentCurrentPeriod <= 0 
	|
	|		THEN 0
	|
	|	WHEN ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|				AND (ListOfIA.LifeSpentPastPeriod + ListOfIA.LifeSpentCurrentPeriod) >= ListOfIA.ResourceAssigned
	|
	|		THEN &NetBookValue - &AmountOfAdditionalCharge - &ResidualValueMan - &ImpairmentBalance
	|
		// Linear, proportional to the volume of production
	|	WHEN ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|			AND ListOfIA.DepreciationMethod IN (
	|					VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear),
	|					VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction))
	|	 
	|		THEN CASE 
	|			WHEN ListOfIA.ThisIsAnAdditionalAccrual
	|				THEN CAST(CAST(&NetBookValue - &AmountOfAdditionalCharge AS NUMBER(20,8))
	|								* CAST(ListOfIA.LifeSpentCurrentPeriod AS NUMBER(20,8))
	|								/ CAST(ListOfIA.ResourceAssigned - ListOfIA.LifeSpentPastPeriod AS NUMBER(20,8)) AS NUMBER(31,2))
	| 
	|			ELSE CAST(CAST(&NetBookValue - &AmountOfAdditionalCharge - &ResidualValueMan - &ImpairmentBalance AS NUMBER(20,8)) 
	|							* CAST(ListOfIA.LifeSpentCurrentPeriod AS NUMBER(20,8))
	|							/ CAST(ListOfIA.ResourceAssigned - ListOfIA.LifeSpentPastPeriod AS NUMBER(20,8)) AS NUMBER(31,2))
	|		END
	|
		// ReducedBalance
	|	WHEN ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|			AND ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance) 
	|   
	|		THEN CAST(CAST(&NetBookValue - &AmountOfAdditionalCharge - &ResidualValueMan - &ImpairmentBalance AS NUMBER(20,8))
	|					* CAST(ListOfIA.LifeSpentCurrentPeriod AS NUMBER(20,8))
	|					* CAST(ListOfIA.AccelerationFactor AS NUMBER(20,8))
	|					/ CAST(ListOfIA.ResourceAssigned - ListOfIA.LifeSpentPastPeriod + ListOfIA.AccelerationFactor - 1 AS NUMBER(20,8)) AS NUMBER(31,2))
	|
		// Linear
	|	WHEN NOT ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|			AND ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear) 
	|
	|		THEN CAST(CAST(&InitialCost AS NUMBER(20,8)) 
	|						/ CAST(ListOfIA.ResourceAssigned AS NUMBER(20,8)) AS NUMBER(31,2))
	|   
		// ByUnitsOfProduction
	|	WHEN NOT ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|			AND ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction) 
	|		THEN CASE 
	|			WHEN ListOfIA.ResourceAssigned <> 0 THEN
	|				CAST(CAST(&InitialCost AS NUMBER(20,8))
	|							* CAST(ListOfIA.LifeSpentCurrentPeriod AS NUMBER(20,8)) 
	|							/ CAST(ListOfIA.ResourceAssigned AS NUMBER(20,8)) AS NUMBER(31,2))
	|			ELSE 0
	|		END
	|
		// ReducedBalance
	|	WHEN NOT ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|			AND ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance) 
	|		THEN CASE 
	|			WHEN (ListOfIA.ResourceAssigned - ListOfIA.ActualUsefulLife + 1) > 0 THEN
	|				CAST(CAST(&Cost - &Depreciation AS NUMBER(20,8))
	|							* CAST(ListOfIA.AccelerationFactor AS NUMBER(20,8)) 
	|							/ CAST(ListOfIA.ResourceAssigned - ListOfIA.ActualUsefulLife + 1 AS NUMBER(20,8)) AS NUMBER(31,2))
	|			ELSE 0
	|			
	|		END
	|END";				

	QueryText = StrReplace(QueryText, "&Cost", RequestTextParameters.TextCost);
	QueryText = StrReplace(QueryText, "&Depreciation", RequestTextParameters.TextDepreciation);
	QueryText = StrReplace(QueryText, "&NetBookValue", RequestTextParameters.TextResidualValue);
	QueryText = StrReplace(QueryText, "&InitialCost", RequestTextParameters.TextInitialCost);
	QueryText = StrReplace(QueryText, "&ResidualValueMan", RequestTextParameters.TextLiquidationValue);
	QueryText = StrReplace(QueryText, "&AmountOfAdditionalCharge", RequestTextParameters.TextAmountOfAdditionalCharge);
	
	TextImpairment = 
		StrReplace(
			"(CASE WHEN ListOfIA.PostingOptionForImpairedFADepreciation = &AddImpairmentAdjustment THEN &ImpairmentBalance ELSE 0 END)", 
			"&ImpairmentBalance",
			RequestTextParameters.TextImpairment);			
	QueryText = StrReplace(QueryText, "&ImpairmentBalance", TextImpairment);
	
	Return QueryText;
	
EndFunction

Function QueryTextAmountOfImpairment(TextBalanceImpairment)
	
	QueryText = 
	"CASE 
	|	WHEN NOT ListOfIA.AccrueDepreciationOrAmortization 
	|		OR &ImpairmentBalance <= 0
	|		OR NOT ListOfIA.DepreciationIsCalculatedAccordingToINTStandards
	|
	|		THEN 0
	|
	|	WHEN (ListOfIA.LifeSpentPastPeriod + ListOfIA.LifeSpentCurrentPeriod) >= ListOfIA.ResourceAssigned
	|
	|		THEN &ImpairmentBalance
	|
		// Linear, proportional to the volume of production
	|	WHEN ListOfIA.DepreciationMethod IN (
	|						VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear),
	|						VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)) 
	|
	|		THEN CAST(&ImpairmentBalance 
	|							* (CAST(ListOfIA.LifeSpentCurrentPeriod AS NUMBER(20,8))
	|							/ CAST(ListOfIA.ResourceAssigned - ListOfIA.LifeSpentPastPeriod AS NUMBER(20,8))) AS NUMBER(31,2))
	|
		// Reduced Balance
	|	WHEN ListOfIA.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance) 
	|
	|		THEN CAST(CAST(&ImpairmentBalance AS NUMBER(20,8))
	|					* CAST(ListOfIA.LifeSpentCurrentPeriod AS NUMBER(20,8))
	|					* CAST(ListOfIA.AccelerationFactor AS NUMBER(20,8))
	|					/ CAST(ListOfIA.ResourceAssigned - ListOfIA.LifeSpentPastPeriod + ListOfIA.AccelerationFactor - 1 AS NUMBER(20,8)) AS NUMBER(31,2))
	|
	|	ELSE 0
	|
	|END";
	
	QueryText = StrReplace(QueryText, "&ImpairmentBalance", TextBalanceImpairment);
	
	Return QueryText;
	
EndFunction

// 
// Returns:
//  Structure - Query text parameters amount of Ma depreciation:
// * TextCost - String - 
// * TextDepreciation - String - 
// * TextResidualValue - String -
// * TextInitialCost - String -
// * TextLiquidationValue - String -
// * TextAmountOfAdditionalCharge - String -
// * TextImpairment - String -
Function QueryTextParametersAmountOfMaDepreciation()
	
	RequestTextParameters = New Structure;
	RequestTextParameters.Insert("TextCost", "0");
	RequestTextParameters.Insert("TextDepreciation", "0");
	RequestTextParameters.Insert("TextResidualValue", "0");
	RequestTextParameters.Insert("TextInitialCost", "0");
	RequestTextParameters.Insert("TextLiquidationValue", "0");
	RequestTextParameters.Insert("TextAmountOfAdditionalCharge", "0");
	RequestTextParameters.Insert("TextImpairment", "0");
	
	Return RequestTextParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf
