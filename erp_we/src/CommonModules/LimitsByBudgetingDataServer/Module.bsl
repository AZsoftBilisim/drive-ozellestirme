#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		If Not Document.AdditionalProperties.Property("DeferredPosting")
			Or Document.AdditionalProperties.DeferredPosting = False Then
			Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.LimitsByBudgetingData);
		EndIf;
		
		If TypeOf(Document) = Type("DocumentObject.PaymentRequest")
			Or TypeOf(Document) = Type("DocumentObject.ApplicationForBusinessTrip")
			Or TypeOf(Document) = Type("DocumentObject.PurchaseRequest")
			Or TypeOf(Document) = Type("DocumentObject.ApplicationForCollateral")
			Or TypeOf(Document) = Type("DocumentObject.CashVoucher")
			Or TypeOf(Document) = Type("DocumentObject.BankAccountIssue") Then
			Parameters.ThereAreDerivedMotions = True;
		EndIf;
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map of KeyAndValue - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of budgeting.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "LimitsByBudgetingData");
	
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export

EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export

EndProcedure

// Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export

	If RegisterOfBudgetingLimitsIsUsed()
		And Document.AdditionalProperties.Property("IgnoreLimitControlBasedOnBudgetingData")
		And Document.AdditionalProperties.IgnoreLimitControlBasedOnBudgetingData Then
		Document.RegisterRecords.LimitsByBudgetingData.Write = False;
	EndIf;
	
EndProcedure

// Occurs after execution of the write registers of the instrument.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	If GetFunctionalOption("UseBudgetingCashFlowLimits")
		Or UseBDRLimits() Then
	
		If ControlOverBudgetingLimitsIsRequired(Document) Then
			
			If TypeOf(Document) = Type("DocumentObject.CashVoucher")
				Or TypeOf(Document) = Type("DocumentObject.BankAccountIssue") Then
				
				InformationRegisters.JobsOfRecordingLimitsByBudgetingData.AddJob(Document.Ref);
				InformationRegisters.JobsOfRecordingLimitsByBudgetingData.RunJob();
				
			Else
				
				Parameters = ControlParametersForBudgetingLimits(Document.Ref);
				PerformControlOverBudgetingLimits(Parameters);
				
				If ValueIsFilled(Parameters.Errors) Then
					CommonClientServer.ReportErrorsToUser(Parameters.Errors);
					If Not Parameters.OnlyInformationLimitsAreViolated Then
						Cancel = True;
					EndIf;
				EndIf;
				
				If Not Cancel And Parameters.TablesForRegisteredRecords.Count() > 0 Then
					ReflectRegisteredRecords(Parameters.TablesForRegisteredRecords, Document.RegisterRecords, Cancel);
				EndIf;
				
			EndIf;
			
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region CacheOfLimitSettings

// Returns a flag for using budget items in cached limit settings based on budgeting data
//
// Parameters:
//  BudgetFlowItem - CatalogRef.BudgetFlowItems - Budget flow item to be checked
//  CheckLimitRules - Boolean - True if checked according to the limits rules
//     False if you check according to the rules for obtaining actual data to control limits.
//
// Returns:
//  Boolean - True if the budget flow item is used in the limit settings based on budgeting data
//
Function BudgetFlowItemIsUsedInLimitSettings(BudgetFlowItem, CheckLimitRules = True) Export
	
	If Not UseBDRLimits()
		And Not GetFunctionalOption("UseBudgetingCashFlowLimits") Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("BudgetFlowItem", BudgetFlowItem);
	
	If CheckLimitRules Then
		Query.Text = 
		"SELECT TOP 1
		|	BudgetingLimits.Ref AS Ref
		|FROM
		|	Catalog.BudgetingLimits AS BudgetingLimits
		|WHERE
		|	BudgetingLimits.BudgetFlowOrBalanceItem = &BudgetFlowItem
		|	AND NOT BudgetingLimits.DeletionMark";
	Else
		Query.Text = 
		"SELECT TOP 1
		|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Ref
		|FROM
		|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
		|WHERE
		|	ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem = &BudgetFlowItem
		|	AND ActualDataQueryRulesByBudgetFlowItems.RuleType <> VALUE(Enum.ActualBudgetingDataQueryRuleType.ActualData)
		|	AND NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark";
	EndIf;
	
	SetPrivilegedMode(True);
	Used = Not Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return Used;
	
EndFunction

// Returns a flag for using the budgeting model in the rules for limits based on budgeting data
//
// Parameters:
//  BudgetingModel - CatalogRef.BudgetingModels - verifiable budgeting model
//
// Returns:
//  Boolean - True if the model is used in the rules for limits based on budgeting data
//
Function BudgetingModelIsUsedInLimitSettings(BudgetingModel) Export
	
	If Not UseBDRLimits()
		And Not GetFunctionalOption("UseBudgetingCashFlowLimits") Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("BudgetingModel", BudgetingModel);
	
	Query.Text = 
	"SELECT TOP 1
	|	BudgetingLimits.Ref AS Ref
	|FROM
	|	Catalog.BudgetingLimits AS BudgetingLimits
	|WHERE
	|	BudgetingLimits.Owner = &BudgetingModel
	|	AND NOT BudgetingLimits.DeletionMark";
	
	SetPrivilegedMode(True);
	Used = Not Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return Used;
	
EndFunction

#EndRegion

// An application for a business trip and an Application for domestic consumption is executed when carrying out documents.
// The relevance of the rules of limits on budget items for the dates of planned expenditures is checked.
//
// Parameters:
//  DocumentObject - DocumentObject.ApplicationForBusinessTrip
//                   Document object.Application Support - controlled document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure CheckRelevanceOfRulesForLimitsOnBudgetItems(DocumentObject, Cancel) Export
	
	If Not UseBDRLimits() Then
		Return;
	EndIf;
	
	If TypeOf(DocumentObject) = Type("DocumentObject.ApplicationForBusinessTrip") Then
		ExpensesTable = DocumentObject.Expenses.Unload(, "PlannedExpenseDate, BudgetFlowItem");
	Else
		ExpensesTable = DocumentObject.Goods.Unload(, "BudgetFlowItem"); // -ValueTable
		ExpensesTable.Columns.Add("PlannedExpenseDate", Common.DateTypeDetails(DateFractions.Date));
		ExpensesTable.FillValues(DocumentObject.Date, "PlannedExpenseDate");
	EndIf;
	ExpensesTable.GroupBy("PlannedExpenseDate, BudgetFlowItem");
	
	If Not ExpensesTable.Count() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("ExpensesTable", ExpensesTable);
	Query.Text = 
	"SELECT
	|	CAST(ExpensesTable.PlannedExpenseDate AS DATE) AS DateOfExpenses,
	|	CAST(ExpensesTable.BudgetFlowItem AS Catalog.BudgetFlowItems) AS BudgetFlowItem
	|INTO ExpensesTable
	|FROM
	|	&ExpensesTable AS ExpensesTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BudgetingLimits.Ref AS LimitsRule,
	|	BudgetingLimits.BudgetFlowOrBalanceItem AS BudgetFlowItem,
	|	BudgetingModels.ValidOnDate AS ValidOnDate,
	|	CASE
	|		WHEN BudgetingModels.ValidToDate = DATETIME(1, 1, 1)
	|			THEN DATETIME(3999, 12, 31)
	|		ELSE BudgetingModels.ValidToDate
	|	END AS ValidToDate
	|INTO ActualLimitRules
	|FROM
	|	Catalog.BudgetingModels AS BudgetingModels
	|		INNER JOIN Catalog.BudgetingLimits AS BudgetingLimits
	|		ON (BudgetingLimits.Owner = BudgetingModels.Ref)
	|			AND (BudgetingLimits.LimitedTransaction = VALUE(Enum.LimitedTransactions.Expenses))
	|		INNER JOIN ExpensesTable AS ExpensesTable
	|		ON (BudgetingLimits.BudgetFlowOrBalanceItem = ExpensesTable.BudgetFlowItem)
	|WHERE
	|	CASE
	|			WHEN BudgetingModels.ValidToDate = DATETIME(1, 1, 1)
	|				THEN BudgetingModels.Status = VALUE(Enum.BudgetingModelStatuses.Valid)
	|			ELSE TRUE
	|		END
	|	AND NOT BudgetingLimits.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpensesTable.BudgetFlowItem AS BudgetFlowItem,
	|	ExpensesTable.DateOfExpenses AS DateOfExpenses,
	|	MAX(ActualLimitRules.LimitsRule) AS LimitsRule
	|FROM
	|	ExpensesTable AS ExpensesTable
	|		LEFT JOIN ActualLimitRules AS ActualLimitRules
	|		ON ExpensesTable.BudgetFlowItem = ActualLimitRules.BudgetFlowItem
	|			AND ExpensesTable.DateOfExpenses >= ActualLimitRules.ValidOnDate
	|			AND ExpensesTable.DateOfExpenses <= ActualLimitRules.ValidToDate
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.BudgetingLimits AS BudgetingLimits
	|			WHERE
	|				ExpensesTable.BudgetFlowItem = BudgetingLimits.BudgetFlowOrBalanceItem
	|				AND NOT BudgetingLimits.DeletionMark)
	|
	|GROUP BY
	|	ExpensesTable.BudgetFlowItem,
	|	ExpensesTable.DateOfExpenses";
	
	ErrorTextTemplate = NStr("vi = 'Đối với khoản mục ngân sách %1 không tìm thấy quy tắc hạn mức có hiệu lực cho %2';
							|ru = 'Для статьи бюджетов %1 не найдено актуальных правил лимитов на %2';
							|en = 'No relevant limit rules are found for the %1 budget flow item as of %2'; fa = 'No relevant limit rules are found for the %1 budget flow item as of %2';
							|it = 'No relevant limit rules are found for the %1 budget flow item as of %2';
							|pl = 'No relevant limit rules are found for the %1 budget flow item as of %2';
							|tr = '%1 bütçe kalemi için %2''de geçerli limit kuralı bulunamadı.'");
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Not ValueIsFilled(Selection.LimitsRule) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate,
				Selection.BudgetFlowItem, Format(Selection.DateOfExpenses, "DLF=D;"));
			Common.MessageToUser(ErrorText, , , , Cancel);
		EndIf;
	EndDo;
	
EndProcedure

// Called from the Report.Limits on spending of monetary funds for budgeting.Object Modul
// Planned and actual state of the limits on the expenditure of the DS.
// 
// Parameters:
//  Parameters - Structure - structure of parameters for calculating limits:
//	 *CheckDate - Date - the date on which the status of limits is checked.
//	 *Document     - DocumentRef.PaymentRequest - a document for which temporary movements are generated by the DS registers.
//	               - Undefined - default.
//	 *Currency - CatalogRef.Currencies - the currency in which to get the fact plan.
//	               - Undefined - default.
//	 *DocumentKind - CatalogRef.MetadataObjectIDs - type of document
//	 *BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document
//	FilterDecryptions - Structure - Selection imposed by the decryption of the report (field values higher than the cell being decrypted).
//	                               When deciphering, the comparison is only for equality:
//	 *UseFilter1 - Boolean - flag for using selection.
//	 *DecryptionByRegistrar - Boolean - Flag for using decryption by registrar. Decryption by the registrar can be performed
//	                                       only if the selection is set, and the selection includes selection according to the rule of obtaining a fact.
//	 *BudgetingModel - CatalogRef.BudgetingModels - selection based on the budgeting model (if the selection is set).
//	 *LimitsRule - CatalogRef.BudgetingLimits - selection according to the limit rule (if the selection is set).
//	 *SelectionByPlanAnalysts - Array of Structure - selection by higher-level analysts of the plan (if specified):
//	   **DimensionNameAnalyticsNumber - String - The name of the dimension or the path to the numbered analytics (of the form "Analytica1", here the number is the one specified in the budget item).
//	   **Value - Characteristic.BudgetFlowItemDimensions - The value of measurement or analytics.
//	 *SelectionByAnalystsReal - Array of Structure - selection by higher-level fact analysts (if specified):
//	   **DimensionNameAnalyticsNumber - String - The name of the dimension or the path to the numbered analytics (of the form "Analytica1", here the number is the one specified in the budget item).
//	   **Value - Characteristic.BudgetFlowItemDimensions - The value of measurement or analytics.
//
// Returns:
//	ValueTable - data on the planned and actual state of the limits on the expenditure of DS.
// 
Function LimitReductionPlan(Parameters, FilterDecryptions = Undefined) Export
	
	Document = Parameters.Document;
	PlanInAbsenceOfFact = Not ValueIsFilled(Document);
	
	SetPrivilegedMode(True);
	
	ContinueCalculation = True;
	
	NumberOfFormallyValidLimits = 0;
	NumberOfTriggeredLimits = 0;
	
	#Region RequestParameters
	
	ControlParameters = New Structure("DocumentAttributes", Parameters);
	
	DocumentControlIsPossible = Not Document = Undefined And Document.Posted;
	
	AccordingToCorrespondenceTable = GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters");
	
	#EndRegion 
	
	AdmissionAccordingToRulesOfLimitation = SelectionAccordingToRulesOfDecodingReport(FilterDecryptions);
	
	#Region Stage1_DefinitionOfFormallyValidLimits
	
	If ContinueCalculation Then
		
		CurrentLimits = CurrentLimits(Parameters,,, AdmissionAccordingToRulesOfLimitation);
		If CurrentLimits.LimitRules.Count() = 0 Then
			ContinueCalculation = False;
		EndIf;
	EndIf;
	
	#EndRegion 
	
	#Region Stage2_FactCalculationByDocument
	
	If ContinueCalculation Then
		If DocumentControlIsPossible Then
			ParametersForGettingFactForControllingLimits = ParametersForGettingFactForControllingLimits(Parameters,
				CurrentLimits, True, FilterDecryptions);
			
			FactAccordingToDocument = BudgetingServer.FactByBudgetType(
				ParametersForGettingFactForControllingLimits.FactGettingParameters,
				ParametersForGettingFactForControllingLimits.DataSources,
				Parameters.Currency,
				Enums.BudgetingDataReceiptMode.All);
			
			If FactAccordingToDocument.Count() = 0 Then
				ContinueCalculation = False;
			EndIf;
		EndIf;
	EndIf;
		
	#EndRegion 
	
	#Region Stage3_DeterminationOfLimitsThatWorkedOnDocument
	If ContinueCalculation Then
		If DocumentControlIsPossible Then
			TriggeredLimits = CurrentLimits(Parameters, FactAccordingToDocument.UnloadColumn("BudgetFlowItem"), , AdmissionAccordingToRulesOfLimitation);
			If TriggeredLimits.LimitRules.Count() = 0 Then
				ContinueCalculation = False;
			EndIf;
		Else
			TriggeredLimits = CurrentLimits;
		EndIf;
	EndIf;
	#EndRegion 
	
	#Region Stage4_GettingFactForTriggeredLimits
	If ContinueCalculation Then
		
		If AccordingToCorrespondenceTable Then
			
			RulesForTriggeredLimits = TriggeredLimits.ActualDataQueryRules_.Copy(
				New Structure("DataSourceSection",
				Enums.SectionsOfBudgetingDataSources.OperationalAccounting), "Rule, TypeOfAccountingDataExpense");
			
			If RulesForTriggeredLimits.Count() > 0 Then
				// We reflect the documents in budgeting "on the fly", that is, in the transaction of the application
				DocumentsKinds = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
					DataSourcesCached.TypesOfDocumentsForControllingLimits(RulesForTriggeredLimits[0].TypeOfAccountingDataExpense));
				For Each LineLimit In TriggeredLimits.LimitRules Do
					If InformationRegisters.JobsForPostingInBudgeting.RequiredReflectionInBudgetingForReportForPeriod(
						LineLimit.BeginOfPeriod, LineLimit.EndOfPeriod, , True, DocumentsKinds) Then
						ActualBudgetingDataServer.ReflectDocumentsInBudgeting(LineLimit.BeginOfPeriod,
						LineLimit.EndOfPeriod, DocumentsKinds);
					EndIf;
				EndDo;
			EndIf;
			
		EndIf;

		ParametersForGettingFactForControllingLimits = ParametersForGettingFactForControllingLimits(Parameters,
			TriggeredLimits, False, FilterDecryptions);
		
		FactAccordingToDocuments = BudgetingServer.FactByBudgetType(
			ParametersForGettingFactForControllingLimits.FactGettingParameters,
			ParametersForGettingFactForControllingLimits.DataSources,
			Parameters.Currency,
			Enums.BudgetingDataReceiptMode.All);
			
		If AccordingToCorrespondenceTable And DocumentControlIsPossible Then
			CommonClientServer.SupplementTable(FactAccordingToDocument, FactAccordingToDocuments);
		EndIf;
		
		If AccordingToCorrespondenceTable And RulesForTriggeredLimits.Count() > 0 Then
			
			ParametersForGettingStoredFact = ParametersForGettingFactForControllingLimits.FactGettingParameters;
			ParametersForGettingStoredFact.Insert("DataReceiptMode",
				Enums.BudgetingDataReceiptMode.All);

			Filter_Settings = New DataCompositionSettings;
			FinancialReportingServer.NewFilter(Filter_Settings.Filter, "Rule.RuleType",
				Enums.ActualBudgetingDataQueryRuleType.ActualData, , DataCompositionComparisonType.NotInList);
			FinancialReportingServer.NewFilter(Filter_Settings.Filter, "Rule",
				RulesForTriggeredLimits.UnloadColumn("Rule"), , DataCompositionComparisonType.InList);
			If DocumentControlIsPossible Then
				FinancialReportingServer.NewFilter(Filter_Settings.Filter, "Recorder",
					Document, , DataCompositionComparisonType.NotEqual);
			EndIf;
			ParametersForGettingStoredFact.Insert("AdditionalSelection", Filter_Settings);

			ParametersForGettingStoredFact.Insert("FunctionalCurrency", Undefined);
			ParametersForGettingStoredFact.Insert("ReturnManAndLocalAmounts", False);
			ParametersForGettingStoredFact.Insert("ReportCurrency", Parameters.Currency);
			ParametersForGettingStoredFact.Insert("CurrentLimits",
				TriggeredLimits.LimitRules.Copy( , "BudgetFlowItem,BeginOfPeriod,EndOfPeriod"));
			CommonClientServer.SupplementStructure(
				ParametersForGettingFactForControllingLimits.FactGettingParameters, ParametersForGettingStoredFact,
				True);

			StoredFactAccordingToDocuments = BudgetingServer.FactOfBudgetItemIsStored(
				ParametersForGettingFactForControllingLimits.FactGettingParameters);
			StoredFactAccordingToDocuments.Columns.Sum.Name = "SumReceipt";
			StoredFactAccordingToDocuments.Columns.AmountInCurrency.Name = "SumCurrReceipt";
			CommonClientServer.SupplementTable(StoredFactAccordingToDocuments, FactAccordingToDocuments);
			
		EndIf;
		
	EndIf;
	#EndRegion 
	
	#Region Stage5_planFactualAnalysisOfTriggeredLimits
	
	PlanFactByRules = New ValueTable;
	If ContinueCalculation Then
		FactAccordingToDocuments.Columns.SumCurrReceipt.Name = "SumReal";
		
		// The fact for all applications is obtained in excess for control purposes, because different analysts (measurements) can spend the same limit analysts.
		// Let's add a column - a sign of the participation of analysts (measurements) in the original application - so as not to control unnecessary analysts.
		FactAccordingToDocuments.Columns.Add("InTheInitialRequest", New TypeDescription("Boolean"));
		
		If DocumentControlIsPossible Then
			RequestSearchColumns = "BudgetFlowItem, BeginOfPeriod, EndOfPeriod";
			MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
			For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
				RequestSearchColumns = RequestSearchColumns + ", Dimension" + DimensionNumber;
			EndDo;
			
			If FactAccordingToDocuments.Columns.Find("Organization") <> Undefined Then
				RequestSearchColumns = RequestSearchColumns + ", Organization";
			EndIf;
			If FactAccordingToDocuments.Columns.Find("Department") <> Undefined Then
				RequestSearchColumns = RequestSearchColumns + ", Department";
			EndIf;
			
			FactAccordingToDocuments.Indexes.Add(RequestSearchColumns);
			FactSearchStructure = New Structure(RequestSearchColumns);
			ThereAreLinesOfOriginalApplication = False;
			For Each LineOfOriginalApplication In FactAccordingToDocument Do
				FillPropertyValues(FactSearchStructure, LineOfOriginalApplication);
				LinesOfGeneralFact = FactAccordingToDocuments.FindRows(FactSearchStructure);
				For Each GeneralFactLine In LinesOfGeneralFact Do
					GeneralFactLine.InTheInitialRequest = True;
					ThereAreLinesOfOriginalApplication = True;
				EndDo;
			EndDo;
			If Not ThereAreLinesOfOriginalApplication
				And Not FilterDecryptions = Undefined
				And FilterDecryptions.UseFilter1 Then
				// Other plan analysts have different fact analysts.
				// The selection is set for fact analysts who do not match the application analysts
				For Each RequestFactString In FactAccordingToDocument Do
					FactAddition = FactAccordingToDocuments.Add();
					FillPropertyValues(FactAddition, RequestFactString,, "SumReceipt, SumExpense, SumCurrExpense");
					FactAddition.SumReal = 0;
					FactAddition.InTheInitialRequest = True;
				EndDo;
			EndIf;
		EndIf;
		
		If PlanInAbsenceOfFact And NumberOfFormallyValidLimits <> NumberOfTriggeredLimits Then
			NotTriggeredLimits = CurrentLimits(
				Parameters, 
				FactAccordingToDocuments.UnloadColumn("BudgetFlowItem"),
				True,
				AdmissionAccordingToRulesOfLimitation);
			
			TMCommonUseClientServer.SupplementTable(
				NotTriggeredLimits.LimitRules,
				FactAccordingToDocuments);
		EndIf;
		
		// Collecting a request for a plan-fact analysis
		PlanFactByRules = ActionPlanForLimitRules(ParametersForGettingFactForControllingLimits, ControlParameters, FactAccordingToDocuments, TriggeredLimits, True, FilterDecryptions);
		
	EndIf;
	
	#EndRegion 
	
	Return PlanFactByRules;
	
EndFunction

// Returns a flag for using the "Limits based on budgeting data" register
//
// Returns:
//  Boolean - True if the register is used.
//
Function RegisterOfBudgetingLimitsIsUsed() Export
	
	Return GetFunctionalOption("UseIEBLimitsOnPurchases")
		Or GetFunctionalOption("UseIEBLimitsOnConsumption")
		Or GetFunctionalOption("UseBudgetingCashFlowLimits")
		And Not GetFunctionalOption("ControllingLimitsBasedOnBudgetingData2_4");
	
EndFunction

// Returns an indication of whether the BDR limits are being used
//
// Returns:
//  Boolean - True if the BDR limits are used.
//
Function UseBDRLimits() Export
	
	Return UseIEBLimitsOnPurchases()
		Or GetFunctionalOption("UseIEBLimitsOnConsumption");

EndFunction

// Returns a flag for whether BDR limits are used for purchases
//
// Returns:
//  Boolean - True if the BDR limits are used.
//
Function UseIEBLimitsOnPurchases() Export
	
	Return GetFunctionalOption("UseIEBLimitsOnPurchases");

EndFunction
	
// Returns limited operations of operations used according to the program settings.
//
// Returns:
//  Array of EnumRef.LimitedTransactions
//
Function UsedLimitedOFOperations() Export
	
	LimitedTransactions = New Array;
	
	If GetFunctionalOption("UseBudgetingCashFlowLimits") Then
		LimitedTransactions.Add(Enums.LimitedTransactions.FlowOfCash);
	EndIf;
	If UseBDRLimits() Then
		LimitedTransactions.Add(Enums.LimitedTransactions.Expenses);
	EndIf;
	
	Return LimitedTransactions;
	
EndFunction

#EndRegion

#Region Private

Procedure SetOptionToControlLimitsBasedOnBudgetingData(Parameters, StorageAddress) Export
	
	ByRegisterOfLimits = Parameters.Property("ControllingLimitsBasedOnBudgetingData2_5");
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		
		Catalogs.ActualDataQueryRulesByBudgetFlowItems.ProcessRulesForGettingFact_BudgetExecution(
				ByRegisterOfLimits);
		If ByRegisterOfLimits Then
			GenerateRegisteredRecordsLimitsBasedOnBudgetingDataBasedOnDocuments();
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		MessageText = StrTemplate(NStr("vi = 'Không thể thay đổi phương án kiểm soát hạn mức theo dữ liệu lập ngân sách theo nguyên nhân: %1';
										|ru = 'Не удалось изменить вариант контроля лимитов по данным бюджетирования по причине: %1';
										|en = 'Cannot change the option of controlling budgeting limits due to: %1'; fa = 'Cannot change the option of controlling budgeting limits due to: %1';
										|it = 'Не удалось изменить вариант контроля лимитов по данным бюджетирования по причине: %1';
										|pl = 'Cannot change the option of controlling budgeting limits due to: %1';
										|tr = 'Bütçeleme verileri üzerindeki limitlerin kontrol seçeneği şu nedenden dolayı değiştirilemedi: %1'"),
		ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
		NStr("vi = 'Thay đổi phương án kiểm soát hạn mức theo dữ liệu lập ngân sách.';
			|ru = 'Изменение варианта контроля лимитов по данным бюджетирования.';
			|en = 'Changing the option of controlling budgeting limits.'; fa = 'Changing the option of controlling budgeting limits.';
			|it = 'Изменение варианта контроля лимитов по данным бюджетирования.';
			|pl = 'Changing the option of controlling budgeting limits.';
			|tr = 'Bütçeleme verileri üzerindeki limitlerin kontrol seçeneğinin değiştirilmesi.'", Common.DefaultLanguageCode()), 
		EventLogLevel.Error, , , MessageText);
		
		Raise MessageText;
		
	EndTry;
	
	PutToTempStorage(Parameters, StorageAddress);
	
EndProcedure

Procedure GenerateRegisteredRecordsLimitsBasedOnBudgetingDataBasedOnDocuments()
	
	// Planned limit values
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	BudgetingLimits.BudgetFlowOrBalanceItem AS BudgetFlowOrBalanceItem
	|INTO LimitedBudgetItems
	|FROM
	|	Catalog.BudgetingLimits AS BudgetingLimits
	|WHERE
	|	NOT BudgetingLimits.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TurnoversAndTurnovers.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.BudgetTurnovers.Turnovers(
	|			,
	|			,
	|			Recorder,
	|			BudgetFlowItem IN
	|					(SELECT
	|						LimitedBudgetItems.BudgetFlowOrBalanceItem
	|					FROM
	|						LimitedBudgetItems AS LimitedBudgetItems)
	|				AND Status = VALUE(Enum.PlanStatuses.Upholded)) AS TurnoversAndTurnovers
	|WHERE
	|	TurnoversAndTurnovers.Recorder REFS Document.BudgetEntryForm";
	
	RegisterRecords = New Structure("LimitsByBudgetingData");
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		CurrentDocument = Selection.Recorder;
		TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(CurrentDocument, "LimitsByBudgetingData");
		
		SetOfLimitsBasedOnBudgetingData = AccumulationRegisters.LimitsByBudgetingData.CreateRecordSet();
		SetOfLimitsBasedOnBudgetingData.Filter.Recorder.Set(CurrentDocument);
		RegisterRecords.LimitsByBudgetingData = SetOfLimitsBasedOnBudgetingData;
		
		ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, False);
		
		SetOfLimitsBasedOnBudgetingData = RegisterRecords.LimitsByBudgetingData; // AccumulationRegisterRecordSet.LimitsByBudgetingData -
		SetOfLimitsBasedOnBudgetingData.Write(True);
		
	EndDo;
	
	// Actual consumption limits
	Query.Text = 
	"SELECT DISTINCT
	|	CashToBePaid.Recorder AS Recorder,
	|	CashToBePaid.Period AS Period
	|FROM
	|	AccumulationRegister.CashToBePaid AS CashToBePaid
	|WHERE
	|	CashToBePaid.Recorder REFS Document.ApplicationForBusinessTrip
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CashToBePaid.Recorder,
	|	CashToBePaid.Period
	|FROM
	|	AccumulationRegister.CashToBePaid AS CashToBePaid
	|WHERE
	|	CashToBePaid.Recorder REFS Document.PaymentRequest
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CashAccountBalance.Recorder,
	|	CashAccountBalance.Period
	|FROM
	|	AccumulationRegister.CashAccountBalance AS CashAccountBalance
	|WHERE
	|	CashAccountBalance.Recorder REFS Document.CashVoucher
	|	AND CashAccountBalance.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BankAccountCash.Recorder,
	|	BankAccountCash.Period
	|FROM
	|	AccumulationRegister.BankAccountCash AS BankAccountCash
	|WHERE
	|	BankAccountCash.Recorder REFS Document.BankAccountIssue
	|	AND BankAccountCash.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|ORDER BY
	|	Period";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If TypeOf(Selection.Recorder) = Type("DocumentRef.CashVoucher")
			Or TypeOf(Selection.Recorder) = Type("DocumentRef.BankAccountIssue") Then
			InformationRegisters.JobsOfRecordingLimitsByBudgetingData.AddJob(Selection.Recorder);
			Continue;
		EndIf;
		
		Block = New DataLock;
		If TypeOf(Selection.Recorder) = Type("DocumentRef.PaymentRequest") Then
			LockItem = Block.Add("Document.PaymentRequest");
		Else
			LockItem = Block.Add("Document.ApplicationForBusinessTrip");
		EndIf;
		LockItem.SetValue("Ref", Selection.Recorder);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Parameters = ControlParametersForBudgetingLimits(Selection.Recorder);
		Parameters.Insert("FindingErrors", False);

		PerformControlOverBudgetingLimits(Parameters);
		
		If Parameters.TablesForRegisteredRecords.Count() > 0 Then
			SetOfLimitsBasedOnBudgetingData = AccumulationRegisters.LimitsByBudgetingData.CreateRecordSet();
			SetOfLimitsBasedOnBudgetingData.Filter.Recorder.Set(Selection.Recorder);
			SetOfLimitsBasedOnBudgetingData.Load(Parameters.TablesForRegisteredRecords.TableLimitsBasedOnBudgetingData);
			SetOfLimitsBasedOnBudgetingData.Write(True);
		EndIf;
		
	EndDo;
	
	InformationRegisters.JobsOfRecordingLimitsByBudgetingData.RunJob();
	
EndProcedure

Function ControlOverBudgetingLimitsIsRequired(DocumentObject)

	If TypeOf(DocumentObject) = Type("DocumentObject.PurchaseRequest") Then
		UseBDRLimits = Documents.PurchaseRequest.MonitorBDRLimits(DocumentObject);
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.ApplicationForCollateral") Then
		UseBDRLimits = GetFunctionalOption("UseIEBLimitsOnConsumption")
			Or GetFunctionalOption("UseIEBLimitsOnPurchases") And DocumentObject.SuppliedByPurchase;
	Else
		UseBDRLimits = UseBDRLimits();
	EndIf;
	UseBDDLimits = GetFunctionalOption("UseBudgetingCashFlowLimits");
	UseBDDLimits2_4 = GetFunctionalOption("ControllingLimitsBasedOnBudgetingData2_4");
	
	If (UseBDRLimits Or UseBDDLimits And Not UseBDDLimits2_4)
		And DocumentObject.AdditionalProperties.Property("IgnoreLimitControlBasedOnBudgetingData")
		And DocumentObject.AdditionalProperties.IgnoreLimitControlBasedOnBudgetingData Then
		Return False;
	EndIf;
	
	VerificationRequired = False;
	
	If TypeOf(DocumentObject) = Type("DocumentObject.PaymentRequest") Then
	
		VerificationRequired = (DocumentObject.Status <> Enums.StatusesOfPaymentRequests.IsRejected
			And UseBDDLimits And (Not UseBDDLimits2_4 Or Not DocumentObject.OverLimits));
	
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.ApplicationForBusinessTrip") Then
	
		VerificationRequired = (DocumentObject.Status <> Enums.EmployeeApplicationStatuses.IsRejected
			And DocumentObject.Status <> Enums.EmployeeApplicationStatuses.Withdrawn
			And (UseBDDLimits And DocumentObject.FundsIssueToAdvanceHolder.Count()
			And (Not UseBDDLimits2_4 Or Not DocumentObject.OverLimits)
			Or UseBDRLimits And DocumentObject.Expenses.Count()));
		
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.PurchaseRequest") Then
		
		VerificationRequired = UseBDRLimits And DocumentObject.Goods.Count();
		
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.ApplicationForCollateral") Then
		
		VerificationRequired = (DocumentObject.Status <> Enums.ProvisionRequestStatuses.RolledBack
			And DocumentObject.Status <> Enums.ProvisionRequestStatuses.Draft
			And UseBDRLimits And DocumentObject.Goods.Count());
		
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.BankAccountIssue") Then
	
		VerificationRequired = (UseBDDLimits And Not UseBDDLimits2_4 And DocumentObject.ProcessedByBank);
	
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.CashVoucher") Then
	
		VerificationRequired = (UseBDDLimits And Not UseBDDLimits2_4);
	
	EndIf;
	
	Return VerificationRequired;

EndFunction

Function ControlParametersForBudgetingLimits(Document) Export
	
	ControlParameters = New Structure;
	ControlParameters.Insert("Errors");
	ControlParameters.Insert("OnlyInformationLimitsAreViolated", False);
	ControlParameters.Insert("ByRegisterOfLimits", RegisterOfBudgetingLimitsIsUsed());
	ControlParameters.Insert("AccordingToCorrespondenceTable", GetFunctionalOption(
		"SettingUpRulesForObtainingFactsFromCorrespondingRegisters"));
	
	LimitedTransactions = New Array;
	AttributeNameDateOfVerification = "";
	If TypeOf(Document) = Type("DocumentRef.PaymentRequest") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document,
			"Currency, PaymentDate, OverLimits, DocumentAmount, BusinessOperation, PayrollTransaction");
		If ValueIsFilled(DocumentAttributes.PayrollTransaction) Then
			DocumentAttributes.Insert("BusinessOperation", DocumentAttributes.PayrollTransaction);
		EndIf;
		DocumentAttributes.Delete("PayrollTransaction");
		AttributeNameDateOfVerification = "PaymentDate";
		LimitedTransactions.Add(Enums.LimitedTransactions.FlowOfCash);
	ElsIf TypeOf(Document) = Type("DocumentRef.ApplicationForBusinessTrip") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document,
			"Currency, RequiredPaymentDate, OverLimits, DocumentAmount, ExpectedExpenseAmount");
		DocumentAttributes.Insert("BusinessOperation", Enums.BusinessTransactions.IssueCashToAdvanceHolder);
		If ValueIsFilled(DocumentAttributes.DocumentAmount) Then
			AttributeNameDateOfVerification = "RequiredPaymentDate";
		EndIf;
		LimitedTransactions = UsedLimitedOFOperations();
	ElsIf TypeOf(Document) = Type("DocumentRef.PurchaseRequest")
		Or TypeOf(Document) = Type("DocumentRef.ApplicationForCollateral") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, "Currency, Date, DocumentAmount");
		If Not ValueIsFilled(DocumentAttributes.Currency) Then
			DocumentAttributes.Insert("Currency", SettingsValueCached.ManagementAccountingCurrency());
		EndIf;
		DocumentAttributes.Insert("ExpectedExpenseAmount", DocumentAttributes.DocumentAmount);
		DocumentAttributes.DocumentAmount = 0;
		DocumentAttributes.Insert("BusinessOperation", Enums.BusinessTransactions.GoodsConsumptionOnDemand);
		LimitedTransactions.Add(Enums.LimitedTransactions.Expenses);
	Else
		DocumentAttributes = Common.ObjectAttributesValues(Document, "Currency, Date, DocumentAmount, BusinessOperation");
		DocumentAttributes.Insert("OverLimits", True);
		AttributeNameDateOfVerification = "Date";
		LimitedTransactions.Add(Enums.LimitedTransactions.FlowOfCash);
	EndIf;
	
	Query = New Query;
	QueriesTexts = New Array;
	If ValueIsFilled(AttributeNameDateOfVerification) Then
		QueriesTexts.Add("
			|SELECT
			|	&CheckDate AS LimitDate,
			|	VALUE(Enum.LimitedTransactions.FlowOfCash) AS LimitedTransaction,
			|	VALUE(Catalog.BudgetFlowItems.EmptyRef) AS BudgetFlowItem");
		Query.SetParameter("CheckDate", DocumentAttributes[AttributeNameDateOfVerification]);
	EndIf;
	If LimitedTransactions.Find(Enums.LimitedTransactions.Expenses) <> Undefined Then
		QueryText = "
			|SELECT
			|	&CheckDate AS LimitDate,
			|	VALUE(Enum.LimitedTransactions.Expenses) AS LimitedTransaction,
			|	ExpensesTable.BudgetFlowItem AS BudgetFlowItem
			|FROM
			|	&TabularPartOfDocument AS ExpensesTable
			|WHERE
			|	ExpensesTable.Ref = &Document";
		If TypeOf(Document) = Type("DocumentRef.ApplicationForBusinessTrip") Then
			QueryText = StrReplace(QueryText, "&CheckDate", "ExpensesTable.PlannedExpenseDate");
			QueryText = StrReplace(QueryText, "&TabularPartOfDocument", "Document.ApplicationForBusinessTrip.Expenses");
		Else
			DocumentName = Metadata.FindByType(TypeOf(Document)).FullName();
			QueryText = StrReplace(QueryText, "&CheckDate", "ExpensesTable.Ref.Date");
			QueryText = StrReplace(QueryText, "&TabularPartOfDocument",
				StringFunctionsClientServer.SubstituteParametersToString("%1.Goods", DocumentName));
		EndIf;
		QueriesTexts.Add(QueryText);
		Query.SetParameter("Document", Document);
	EndIf;
	Query.Text = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin()) + Chars.LF
		+ "ORDER BY LimitDate"; // @query-part
	DocumentAttributes.Insert("VerificationDates", Query.Execute().Unload());
	
	DocumentAttributes.Insert("Document", Document);
	DocumentAttributes.Insert("DocumentKind", Common.MetadataObjectID(TypeOf(Document)));
	DocumentAttributes.Insert("LimitedTransactions", LimitedTransactions);
	ControlParameters.Insert("DocumentAttributes", DocumentAttributes);
	
	If ControlParameters.ByRegisterOfLimits Then
		If (TypeOf(Document) = Type("DocumentRef.PaymentRequest")
			Or TypeOf(Document) = Type("DocumentRef.ApplicationForBusinessTrip")) Then
			ControlParameters.Insert("FindingErrors", Not DocumentAttributes.OverLimits);
			ControlParameters.Insert("ReserveLimitAmount", True);
		ElsIf TypeOf(Document) = Type("DocumentRef.PurchaseRequest")
			Or TypeOf(Document) = Type("DocumentRef.ApplicationForCollateral") Then
			ControlParameters.Insert("FindingErrors", True);
			ControlParameters.Insert("ReserveLimitAmount", True);
		Else
			ControlParameters.Insert("FindingErrors", False);
			ControlParameters.Insert("ReserveLimitAmount", False);
		EndIf;
	Else
		ControlParameters.Insert("FindingErrors", True);
	EndIf;
	
	ControlParameters.Insert("TablesForRegisteredRecords", New Structure);
	ControlParameters.Insert("TempTablesManager");
	
	Return ControlParameters;
	
EndFunction

Function FactIsCalculatedAccordingToDocumentAccordingToSettingsForGettingFact(DocumentAttributes, TempTablesManager,
	ConfigureActualDataReceipt)
	
	QueriesTexts = New Array;
	QueriesTexts.Add(ConfigureActualDataReceipt.QueryText);
	
	Query = New Query;
	If TempTablesManager = Undefined Then
		TempTablesManager = New TempTablesManager;
	EndIf;
	Query.TempTablesManager = TempTablesManager;
	For Each Parameter In ConfigureActualDataReceipt.QueryOptions Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	Query.SetParameter("Document", DocumentAttributes.Document);
	Query.SetParameter("BeginOfPeriod", DocumentAttributes.VerificationDates[0].LimitDate);
	Query.SetParameter("EndOfPeriod",
		DocumentAttributes.VerificationDates[DocumentAttributes.VerificationDates.Count() - 1].LimitDate);
	
	Return FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts,
		"ActualDataOnDocument");
	
EndFunction

Procedure PerformControlOverBudgetingLimits(ControlParameters)
	
	SetPrivilegedMode(True);
	
	PermissionLimitRequired = True;
	ResolutionLimitFound     = False;
	InformationLimitFound  = False;
	
	SearchForPermissiveLimit = New Structure("LimitType, LimitedTransaction",
		Enums.TypesOfCashExpenseLimit.AllowingWithinLimit,
		Enums.LimitedTransactions.FlowOfCash);
	InformationLimitSearch = New Structure("LimitType, LimitedTransaction",
		Enums.TypesOfCashExpenseLimit.informational,
		Enums.LimitedTransactions.FlowOfCash);
	
	ContinueCalculation = True;
	
	OnlyInformationLimitsAreViolated = ControlParameters.OnlyInformationLimitsAreViolated;
	Errors = ControlParameters.Errors;
	FindingErrors = ControlParameters.FindingErrors;
	DocumentAttributes = ControlParameters.DocumentAttributes;
	
	#Region Stage1_DefinitionOfFormallyValidLimits
	
	If ContinueCalculation Then
		
		CurrentLimits = CurrentLimits(DocumentAttributes);
		If CurrentLimits.LimitRules = Undefined Or CurrentLimits.LimitRules.Count() = 0 Then
			PermissionLimitRequired = False;
			ContinueCalculation = False;
		EndIf;
		
		PermissionLimitRequired = CurrentLimits.PermissionLimitRequired;
	EndIf;
	
	#EndRegion 
	
	#Region Stage2_FactCalculationByDocument
	
	If ContinueCalculation Then
		If ControlParameters.ByRegisterOfLimits Then
			If CurrentLimits.ConfigureActualDataReceipt = Undefined
				Or IsBlankString(CurrentLimits.ConfigureActualDataReceipt.QueryText) Then
				ContinueCalculation = False;
			ElsIf Not FactIsCalculatedAccordingToDocumentAccordingToSettingsForGettingFact(DocumentAttributes,
				ControlParameters.TempTablesManager, CurrentLimits.ConfigureActualDataReceipt) Then
				TMCommonUse.DestroyTemporaryTables(ControlParameters.TempTablesManager,
					"ActualDataOnDocument");
				ContinueCalculation = False;
			EndIf;
		Else
			ParametersForGettingFactForControllingLimits = ParametersForGettingFactForControllingLimits(DocumentAttributes,
				CurrentLimits, True);
			FactAccordingToDocument = BudgetingServer.FactByBudgetType(
				ParametersForGettingFactForControllingLimits.FactGettingParameters,
				ParametersForGettingFactForControllingLimits.DataSources,
				DocumentAttributes.Currency,
				Enums.BudgetingDataReceiptMode.All);
			If FactAccordingToDocument.Count() = 0 Then
				ContinueCalculation = False;
			EndIf;
		EndIf;
	EndIf;
	
	#EndRegion 
	
	#Region Stage3_DeterminationOfLimitsThatWorkedOnDocument
	
	If ContinueCalculation And Not ControlParameters.ByRegisterOfLimits Then
		
		TriggeredLimits = CurrentLimits(DocumentAttributes, FactAccordingToDocument.UnloadColumn("BudgetFlowItem"));
		If TriggeredLimits.LimitRules.Count() = 0 Then
			ContinueCalculation = False;
		EndIf;
		
	EndIf;

	If ContinueCalculation And Not ControlParameters.ByRegisterOfLimits Then
		
		If ControlParameters.AccordingToCorrespondenceTable Then
			
			RulesForTriggeredLimits = TriggeredLimits.ActualDataQueryRules_.Copy(
				New Structure("DataSourceSection",
				Enums.SectionsOfBudgetingDataSources.OperationalAccounting), "Rule, TypeOfAccountingDataExpense");
			If RulesForTriggeredLimits.Count() > 0 Then
				// We reflect the documents in budgeting "on the fly", that is, in the transaction of the application
				DocumentsKinds = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
					DataSourcesCached.TypesOfDocumentsForControllingLimits(RulesForTriggeredLimits[0].TypeOfAccountingDataExpense));
				For Each LineLimit In TriggeredLimits.LimitRules Do
					If InformationRegisters.JobsForPostingInBudgeting.RequiredReflectionInBudgetingForReportForPeriod(
						LineLimit.BeginOfPeriod, LineLimit.EndOfPeriod, , True, DocumentsKinds) Then
						ActualBudgetingDataServer.ReflectDocumentsInBudgeting(LineLimit.BeginOfPeriod,
							LineLimit.EndOfPeriod, DocumentsKinds);
					EndIf;
				EndDo;
			EndIf;
		
		EndIf;

		ParametersForGettingFactForControllingLimits = ParametersForGettingFactForControllingLimits(DocumentAttributes,
			TriggeredLimits, False);
		
		FactAccordingToDocuments = BudgetingServer.FactByBudgetType(
			ParametersForGettingFactForControllingLimits.FactGettingParameters,
			ParametersForGettingFactForControllingLimits.DataSources,
			DocumentAttributes.Currency,
			Enums.BudgetingDataReceiptMode.All);
			
		If ControlParameters.AccordingToCorrespondenceTable Then
			CommonClientServer.SupplementTable(FactAccordingToDocument, FactAccordingToDocuments);
		EndIf;
		
		If ControlParameters.AccordingToCorrespondenceTable And RulesForTriggeredLimits.Count() > 0 Then
			
			ParametersForGettingStoredFact = ParametersForGettingFactForControllingLimits.FactGettingParameters;
			ParametersForGettingStoredFact.Insert("DataReceiptMode",
				Enums.BudgetingDataReceiptMode.All);
	
			Filter_Settings = New DataCompositionSettings;
			FinancialReportingServer.NewFilter(Filter_Settings.Filter, "Rule.RuleType",
				Enums.ActualBudgetingDataQueryRuleType.ActualData, ,
				DataCompositionComparisonType.NotEqual);
			FinancialReportingServer.NewFilter(Filter_Settings.Filter, "Rule",
				RulesForTriggeredLimits.UnloadColumn("Rule"), , DataCompositionComparisonType.InList);
			FinancialReportingServer.NewFilter(Filter_Settings.Filter, "Recorder",
				DocumentAttributes.Document, , DataCompositionComparisonType.NotEqual);
			ParametersForGettingStoredFact.Insert("AdditionalSelection", Filter_Settings);
    
			ParametersForGettingStoredFact.Insert("FunctionalCurrency", Undefined);
			ParametersForGettingStoredFact.Insert("ReturnManAndLocalAmounts", False);
			ParametersForGettingStoredFact.Insert("ReportCurrency", DocumentAttributes.Currency);
			ParametersForGettingStoredFact.Insert("CurrentLimits",
				TriggeredLimits.LimitRules.Copy( , "BudgetFlowItem,BeginOfPeriod,EndOfPeriod"));
			CommonClientServer.SupplementStructure(
				ParametersForGettingFactForControllingLimits.FactGettingParameters, ParametersForGettingStoredFact,
				True);
    
			StoredFactAccordingToDocuments = BudgetingServer.FactOfBudgetItemIsStored(
				ParametersForGettingFactForControllingLimits.FactGettingParameters);
			StoredFactAccordingToDocuments.Columns.Sum.Name = "SumReceipt";
			StoredFactAccordingToDocuments.Columns.AmountInCurrency.Name = "SumCurrReceipt";
			CommonClientServer.SupplementTable(StoredFactAccordingToDocuments, FactAccordingToDocuments);
			
		EndIf;
		
		FactAccordingToDocuments.Columns.SumCurrReceipt.Name = "SumReal";
		
		If FactAccordingToDocuments.Count() = 0 Then
			ContinueCalculation = False;
		EndIf;
		
	EndIf;
	#EndRegion 
	
	#Region Stage4_planFactualAnalysisOfTriggeredLimits
	
	PlanFactByRules = New ValueTable;
	
	If ContinueCalculation And Not ControlParameters.ByRegisterOfLimits Then
		
		FactAccordingToDocument.Columns.SumCurrReceipt.Name = "SumReal";
		
		// The fact for all applications is obtained in excess for control purposes, because different analysts (measurements) can spend the same limit analysts.
		// Let's add a column - a sign of the participation of analysts (measurements) in the original application - so as not to control unnecessary analysts.
		FactAccordingToDocuments.Columns.Add("InTheInitialRequest", New TypeDescription("Boolean"));
		// Column for calculating the amount that can be debited.
		FactAccordingToDocuments.Columns.Add("AmountFromOriginalApplication", TMCommonUse.MoneyFieldTypeDescription());
		
		RequestSearchColumns = "BudgetFlowItem, Currency, BeginOfPeriod, EndOfPeriod";
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			RequestSearchColumns = RequestSearchColumns + ", Dimension" + DimensionNumber;
		EndDo;
		
		If FactAccordingToDocuments.Columns.Find("Organization") <> Undefined Then
			RequestSearchColumns = RequestSearchColumns + ", Organization";
		EndIf;
		If FactAccordingToDocuments.Columns.Find("Department") <> Undefined Then
			RequestSearchColumns = RequestSearchColumns + ", Department";
		EndIf;
		
		FactAccordingToDocuments.Indexes.Add(RequestSearchColumns);
		FactSearchStructure = New Structure(RequestSearchColumns);
		For Each LineOfOriginalApplication In FactAccordingToDocument Do
			FillPropertyValues(FactSearchStructure, LineOfOriginalApplication);
			LinesOfGeneralFact = FactAccordingToDocuments.FindRows(FactSearchStructure);
			If LinesOfGeneralFact.Count() > 0 Then
				GeneralFactLine = LinesOfGeneralFact[0];
				GeneralFactLine.InTheInitialRequest = True;
				GeneralFactLine.AmountFromOriginalApplication = LineOfOriginalApplication.SumReal;
			EndIf;
		EndDo;
		
	EndIf;
	
	If ContinueCalculation Then
		
		If ControlParameters.ByRegisterOfLimits Then
			// The actual data on the document is stored in a temp table. The rest of the data is in the limit register
			// Preliminary selection of triggered limits is not required.
			FactAccordingToDocuments = Undefined;
			ParametersForGettingFactForControllingLimits = Undefined;
			TriggeredLimits = CurrentLimits;
		EndIf;
		
		// Collecting a request for a plan-fact analysis
		PlanFactByRules = ActionPlanForLimitRules(ParametersForGettingFactForControllingLimits, ControlParameters,
			FactAccordingToDocuments, TriggeredLimits);
		
		OnlyInformationLimitsAreViolated = True;
		CacheOfSubmittedInformation = New Map;
		
		// Plan-fact analysis
		For Each FactLine In PlanFactByRules Do
			If FactLine.ExcessAmount = 0 Then
				Continue;
			EndIf;
			HierarchyOfAnalystsByRules = TriggeredLimits.HierarchyOfAnalystsByRules; // Map
			DimensionsHierarchy = HierarchyOfAnalystsByRules.Get(FactLine.LimitsRule);
			
			MessageText = TextOfMessageCheckingWhetherLimitsAreExceededBasedOnBudgetingData(
				DimensionsHierarchy,
				FactLine, 
				FactLine.BeginOfPeriod,
				CacheOfSubmittedInformation);
				
			CommonClientServer.AddUserError(Errors, "", MessageText, "");
			
			If FactLine.LimitType <> Enums.TypesOfCashExpenseLimit.informational Then
				OnlyInformationLimitsAreViolated = False;
			EndIf;
			
		EndDo;
		
	EndIf;
	#EndRegion 
	
	If Not FindingErrors Then
		Return;
	EndIf;
	
	If ContinueCalculation Then
		PlanFactByRules.Indexes.Add("LimitType");
		
		ResolutionLimitFound    = PlanFactByRules.FindRows(SearchForPermissiveLimit).Count() > 0;
		InformationLimitFound = PlanFactByRules.FindRows(InformationLimitSearch).Count() > 0;
	EndIf;
	
	If DocumentAttributes.DocumentAmount > 0 And Not ResolutionLimitFound And PermissionLimitRequired Then
		// Analysis that the application fell within one of the "permissive limits".
		OnlyInformationLimitsAreViolated = False;
		MessageText = NStr("vi = 'Yêu cầu không thuộc quy tắc giới hạn ""Được phép"" theo lưu chuyển tiền tệ. 
									|Yêu cầu chỉ có thể được xác định là vượt hạn mức.';
									|ru = 'Заявка не попадает ни в одно ""Разрешающее"" правило лимитирования по движению денежных средств. 
									|Заявка может быть только сверх-лимитной.';
									|en = 'Request is not included in any Allowing cash flow limiting rule.
									|Request can be only above the limit.'; fa = 'Request is not included in any Allowing cash flow limiting rule.
									|Request can be only above the limit.';
									|it = 'Request is not included in any Allowing cash flow limiting rule.
									|Request can be only above the limit.';
									|pl = 'Request is not included in any Allowing cash flow limiting rule.
									|Request can be only above the limit.';
									|tr = 'Talep, nakit akışına yönelik herhangi bir ""İzin veren"" limit kuralına uymuyor. 
									|Talep sadece limit üstü olabilir.'");
		CommonClientServer.AddUserError(Errors, "",MessageText, "");
	ElsIf DocumentAttributes.DocumentAmount > 0 And Not ResolutionLimitFound And Not InformationLimitFound Then
		// If only information limits are in effect in the system at the current date, then permissive limits are not required,
		// but if the application does not fall into any limit rule, then this is an error,
		// because the settings of the rules for collecting actual data may not have been taken into account.
		OnlyInformationLimitsAreViolated = False;
		MessageText = NStr("vi = 'Yêu cầu này không thuộc bất kỳ quy tắc hạn mức nào liên quan đến lưu chuyển tiền tệ.
									|Yêu cầu chỉ có thể được xác định là vượt hạn mức.';
									|ru = 'Заявка не попадает ни в одно правило лимитирования по движению денежных средств.
									|Заявка может быть только сверх-лимитной.';
									|en = 'Request is not included in any cash flow limiting rule.
									|Request can be only above the limit.'; fa = 'Request is not included in any cash flow limiting rule.
									|Request can be only above the limit.';
									|it = 'Request is not included in any cash flow limiting rule.
									|Request can be only above the limit.';
									|pl = 'Request is not included in any cash flow limiting rule.
									|Request can be only above the limit.';
									|tr = 'Talep, nakit akışına yönelik hiçbir limit kuralına uymuyor. 
									|Talep sadece limit üstü olabilir.'");
		CommonClientServer.AddUserError(Errors, "",MessageText, "");
	EndIf;
	
	ControlParameters.Errors = Errors;
	ControlParameters.OnlyInformationLimitsAreViolated = OnlyInformationLimitsAreViolated;
	
EndProcedure

Function TextOfMessageCheckingWhetherLimitsAreExceededBasedOnBudgetingData(DimensionsHierarchy, FactLine, CheckDate, CacheOfSubmittedInformation)
	
	ApplicableLimitRule = FactLine.LimitsRule; // CatalogRef.BudgetingLimits -
	
	If RegisterOfBudgetingLimitsIsUsed() Then
		RightToUseReport = AccessRight("Use", Metadata.Reports.LimitsByBudgetingData);
	Else
		RightToUseReport = AccessRight("Use", Metadata.Reports.CashFlowLimitsForBudgetingData);
	EndIf;
	
	LimitAnalystPresentation = LimitPresentation(DimensionsHierarchy, FactLine, CacheOfSubmittedInformation);
	
	ApplicableLimitRuleAttributes = Common.ObjectAttributesValues(ApplicableLimitRule,
		"Description, Periodicity");
	RulePeriod = FinancialReportingServer.IntervalPresentation(CheckDate,
		ApplicableLimitRuleAttributes.Periodicity);
	
	PresentationOfLimitRule = CacheOfSubmittedInformation.Get(ApplicableLimitRule);
	If PresentationOfLimitRule = Undefined Then
		PresentationOfLimitRule = ApplicableLimitRuleAttributes.Description;
		CacheOfSubmittedInformation.Insert(ApplicableLimitRule, PresentationOfLimitRule);
	EndIf;
	
	If RightToUseReport Then
		If ValueIsFilled(LimitAnalystPresentation) Then
			MessageText = NStr("vi = 'Tổng vượt quá %1 %4 giới hạn ""%5"" theo chỉ tiêu ngân sách dự kiến %6.';
								|ru = 'Общее превышение на %1 %4 лимита ""%5"" по аналитикам запланированного бюджета %6.';
								|en = 'Total exceeding %1 %4 of limit ""%5"" by the %6 planned budget dimensions.'; fa = 'Total exceeding %1 %4 of limit ""%5"" by the %6 planned budget dimensions.';
								|it = 'L''eccedenza totale per %1 %4il limite ""%5"" sugli analisti del budget pianificato %6.';
								|pl = 'Całkowity nadmiar na %1 %4 limitu „%5” analityków planowanego budżetu %6.';
								|tr = '""%5"" limitinin %1 %4 kısmında planlanan %6 bütçe boyutuna göre aşılan toplam.'");
		Else
			MessageText = NStr("vi = 'Tổng vượt quá %1 %4 giới hạn ""%5"".';
								|ru = 'Общее превышение на %1 %4 лимита ""%5"".';
								|en = 'Total exceeding %1 %4 of limit ""%5"".'; fa = 'Total exceeding %1 %4 of limit ""%5"".';
								|it = 'Eccesso totale al %1 %4 limite ""%5"".';
								|pl = 'Całkowity nadmiar na %1 %4 limitu „%5”.';
								|tr = '""%5"" limitinin %1 %4 kısmında aşılan toplam.'");
		EndIf;
		If FactLine.SumPlan = 0 Then
			MessageText = MessageText
				+ Chars.LF
				+ NStr("vi = 'Chưa thiết lập hạn mức trong kỳ %7.';
						|ru = 'Лимит в периоде %7 не установлен.';
						|en = 'Limit in the %7 period is not set.'; fa = 'Limit in the %7 period is not set.';
						|it = 'Il limite nel periodo %7 non è impostato.';
						|pl = 'Limit w okresie %7 nie jest ustawiony.';
						|tr = '%7 döneminde limit ayarlanmadı.'");
		ElsIf FactLine.AmountCanBeDebited > 0 Then
			MessageText = MessageText
				+ Chars.LF
				+ NStr("vi = 'Tổng hạn mức trong kỳ %7 - %2 %4. Có thể chi %3 %4.';
						|ru = 'Всего лимит в периоде %7 - %2 %4. Можно списать %3 %4.';
						|en = 'Total limit in the %7 period - %2 %4. %3 %4 can be written off.'; fa = 'Total limit in the %7 period - %2 %4. %3 %4 can be written off.';
						|it = 'Totale limite nel periodo %7 - %2 %4. Può essere cancellato %3 %4.';
						|pl = 'Całkowity limit w okresie %7 - %2 %4. Możesz odpisać %3%4.';
						|tr = '%7 - %2 %4 dönemindeki toplam limit. %3 %4 gider yazılabilir.'");
		Else
			MessageText = MessageText
				+ Chars.LF
				+ NStr("vi = 'Tổng hạn mức trong kỳ %7 -%2%4. Hạn mức đã được sử dụng hết.';
						|ru = 'Всего лимит в периоде %7 - %2 %4. Лимит израсходован.';
						|en = 'Total limit in the %7 period - %2 %4. Limit is exhausted.'; fa = 'Total limit in the %7 period - %2 %4. Limit is exhausted.';
						|it = 'Totale limite nel periodo %7 - %2 %4. Il limite è esaurito.';
						|pl = 'Całkowity limit w okresie %7 - %2%4. Limit został wydany.';
						|tr = '%7 - %2 %4 dönemindeki toplam limit. Limit kullanıldı.'");
		EndIf;
	Else
		If ValueIsFilled(LimitAnalystPresentation) Then
			MessageText = NStr("vi = 'Tổng vượt quá giới hạn ""%5"" theo %6 chỉ tiêu ngân sách theo kế hoạch cho giai đoạn %7.';
								|ru = 'Общее превышение лимита ""%5"" по аналитикам запланированного бюджета %6 за период %7.';
								|en = 'Total exceeding of limit ""%5"" by the %6 planned budget dimensions for the %7 period.'; fa = 'Total exceeding of limit ""%5"" by the %6 planned budget dimensions for the %7 period.';
								|it = 'Superamento totale del limite ""%5"" sugli analisti del budget %6 pianificato per il periodo %7.';
								|pl = 'Całkowite przekroczenie limitu „%5” przez analityków planowanego budżetu %6 na ten okres %7.';
								|tr = '%7 dönemi için %6 planlanan bütçe boyutuna göre aşılan ""%5"" limiti.'");
		Else
			MessageText = NStr("vi = 'Tổng vượt quá giới hạn ""%5"" trong kỳ %7.';
								|ru = 'Общее превышение лимита ""%5"" за период %7.';
								|en = 'Total exceeding of limit ""%5"" for the %7 period.'; fa = 'Total exceeding of limit ""%5"" for the %7 period.';
								|it = 'Totale superamento del limite ""%5"" per il periodo %7.';
								|pl = 'Całkowite przekroczenie limitu „%5” dla okresu %7.';
								|tr = '%7 dönemi için aşılan ""%5"" toplam limiti.'");
		EndIf;
		If FactLine.AmountCanBeDebited > 0 Then
			MessageText = MessageText
			+ Chars.LF
			+ NStr("vi = 'Bạn có thể ghi %3 %4.';
					|ru = 'Можно списать %3 %4.';
					|en = '%3 %4 can be written off.'; fa = '%3 %4 can be written off.';
					|it = 'Puoi cancellare %3 %4.';
					|pl = 'Możesz rozchodować %3%4.';
					|tr = '%3 %4 Gider yazılabilir.'");
		Else
			MessageText = MessageText
			+ Chars.LF
			+ NStr("vi = 'Hạn mức chi.';
					|ru = 'Лимит израсходован.';
					|en = 'Limit is exhausted.'; fa = 'Limit is exhausted.';
					|it = 'Il limite è esaurito.';
					|pl = 'Limit został wyczerpany.';
					|tr = 'Limit uygulandı.'");
		EndIf;
	EndIf;
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
		FactLine.ExcessAmount,
		FactLine.SumPlan,
		FactLine.AmountCanBeDebited,
		FactLine.Currency,
		PresentationOfLimitRule,
		LimitAnalystPresentation,
		RulePeriod);
		
	Return MessageText;

EndFunction

Function LimitPresentation(DimensionsHierarchy, FoundRow, CacheOfSubmittedInformation)
	
	PartsPresentationOfLimit = New Array;
	
	For Each UsedDimension In DimensionsHierarchy Do
		If Not UsedDimension.Used Then
			Continue;
		EndIf;
		DimensionNameTypeOfAnalytics = UsedDimension.MeasurementViewAnalytics;
		
		DimensionValue = FoundRow[UsedDimension.PathToAnalytics];
		If ValueIsFilled(DimensionValue) Then
			ValuePresentation = CacheOfSubmittedInformation.Get(DimensionValue);
			If ValuePresentation = Undefined Then
				ValuePresentation = String(DimensionValue);
				CacheOfSubmittedInformation.Insert(DimensionValue, ValuePresentation);
			EndIf;
		Else
			ValuePresentation = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
				DimensionNameTypeOfAnalytics, "OtherItems",, CacheOfSubmittedInformation);
		EndIf;
		
		PartsPresentationOfLimit.Add(ValuePresentation);
	EndDo;
	
	Return StrConcat(PartsPresentationOfLimit, " / ");
	
EndFunction

Procedure CalculateNearestPlanAnalystsTakingIntoAccountHierarchy(ActualData, LimitRules, ScheduledData)
	
	HierarchyOfAnalystsByRules = LimitRules.HierarchyOfAnalystsByRules; // Map
	ThereIsScenarioPlan = ScheduledData.Columns.Find("ScenarioPlan") <> Undefined;
	If ThereIsScenarioPlan Then
		RuleScripts = LimitRules.RuleScripts; // Map
	EndIf;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	// Let's fill out the plan analytics according to the final coefficient of the plan analysts and the corresponding analysts
	ActualData.Columns.Add("CompanyPlan", New TypeDescription("CatalogRef.Companies"));
	ActualData.Columns.Add("DepartmentPlan", New TypeDescription("CatalogRef.BusinessStructure"));
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ActualData.Columns.Add("Dimension" + DimensionNumber + "Plan", BudgetingServer.AllTypesOfAnalytics());
		If ActualData.Columns.Find("Dimension" + DimensionNumber).ValueType.Types().Count() = 0 Then
			ActualData.Columns.Delete("Dimension" + DimensionNumber);
			ActualData.Columns.Add("Dimension" + DimensionNumber, BudgetingServer.AllTypesOfAnalytics());
		EndIf;
	EndDo;
	
	PlanLinesNotFound = ScheduledData.CopyColumns();
	ColumnsNames = SearchFieldsForPlannedLimitValues();
	
	FindingPlan = New Structure(ColumnsNames);
	IndexOfPlanTable = ScheduledData.Indexes.Add(ColumnsNames);
	
	For Each FactString In ActualData Do
		
		DimensionsHierarchy = HierarchyOfAnalystsByRules.Get(FactString.LimitsRule);
		RemainderCoefficient = FactString.FinalPlanAnalyticsFactor;
		ThereAreAnalyticsUsed = False;
		FoundCompleteMismatchOfAnalysts = False;
		For Each HierarchyLine In DimensionsHierarchy Do
			If Not HierarchyLine.Used Then
				Continue;
			EndIf;
			
			ThereAreAnalyticsUsed = True;
			MatchRate = Int(RemainderCoefficient / HierarchyLine.ZoomRatio);
			RemainderCoefficient = RemainderCoefficient % HierarchyLine.ZoomRatio;
			If MatchRate = 2 Then
				// Exact match of measurement/analytics.
				FactString[HierarchyLine.PathToAnalytics + "Plan"] = FactString[HierarchyLine.PathToAnalytics];
			ElsIf MatchRate = 0 Then
				// A complete mismatch of the analytics for the type of measurement (analytics) used.
				// Starting from this step, all the analytics following the hierarchy are other.
				FoundCompleteMismatchOfAnalysts = True;
				Break;
			EndIf;
		EndDo;
		
		If FoundCompleteMismatchOfAnalysts
			Or Not ThereAreAnalyticsUsed Then
			// Since this line is not in the plan, we add it.
			FillPropertyValues(FindingPlan, FactString);
			If ScheduledData.FindRows(FindingPlan).Count() = 0 Then
				PlanExtensionLine = PlanLinesNotFound.Add();
				FillPropertyValues(PlanExtensionLine, FindingPlan);
				If ThereIsScenarioPlan Then
					PlanExtensionLine.ScenarioPlan = RuleScripts.Get(FactString.LimitsRule);
				EndIf;
				PlanExtensionLine.Currency = FactString.Currency; // The currencies have been converted into the application currency.
			EndIf;
		EndIf;
	EndDo;
	
	ScheduledData.Indexes.Delete(IndexOfPlanTable);
	If PlanLinesNotFound.Count() > 0 Then
		ColumnsNames = "";
		For Each Column In PlanLinesNotFound.Columns Do
			ColumnsNames = ColumnsNames + ?(ColumnsNames = "", "", ", ") + Column.Name;
		EndDo;
		PlanLinesNotFound.GroupBy(ColumnsNames); // A zero-sum plan.
		For Each PlanExtensionLine In PlanLinesNotFound Do
			NewLinePlan = ScheduledData.Add();
			FillPropertyValues(NewLinePlan, PlanExtensionLine);
		EndDo;
	EndIf;
	
EndProcedure

Function ActionPlanForLimitRules(FactGettingParameters, ControlParameters, ActualData, LimitRules, InContextOfFactGroupings = False, AdditionalSelectionOfReportTranscript = Undefined)
	
	ActionPlanForLimitRules = New ValueTable;
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	Document = ControlParameters.DocumentAttributes.Document;
	Currency = ControlParameters.DocumentAttributes.Currency;
	VerificationDates = ControlParameters.DocumentAttributes.VerificationDates;
	LimitedTransactions = ControlParameters.DocumentAttributes.LimitedTransactions;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	DecryptionByRegistrar = False;
	If Not AdditionalSelectionOfReportTranscript = Undefined
		And AdditionalSelectionOfReportTranscript.UseFilter1 Then
		// Transcript of the limits report. It is used only together with the selection according to the limits rule.
		DecryptionByRegistrar = AdditionalSelectionOfReportTranscript.DecryptionByRegistrar;
	EndIf;
	
	RulesForLimitsWithAdditionalData = LimitRules.LimitRules;
	
	If FactGettingParameters <> Undefined Then
		If Not FactGettingParameters.FactGettingParameters.ByCompanies 
			And ActualData.Columns.Find("Organization") = Undefined Then
			ActualData.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
		EndIf;
		If Not FactGettingParameters.FactGettingParameters.ByBusinessUnits 
			And ActualData.Columns.Find("Department") = Undefined Then
			ActualData.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
		EndIf;
	EndIf;
	
	FilterByDocument = ValueIsFilled(Document);
	
	#Region GettingPlannedData
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FilterByRequest", FilterByDocument);
	AdditionalParameters.Insert("DecryptionByRegistrar", DecryptionByRegistrar);
	AdditionalParameters.Insert("UseMultipleCurrencies", UseMultipleCurrencies);
	AdditionalParameters.Insert("VerificationDates", VerificationDates);
	AdditionalParameters.Insert("RequestCurrency", Currency);
	AdditionalParameters.Insert("AdditionalSelectionOfReportTranscript", AdditionalSelectionOfReportTranscript);
	
	ByRegisterOfLimits = ControlParameters <> Undefined And ControlParameters.Property("ByRegisterOfLimits")
		And ControlParameters.ByRegisterOfLimits;
	
	If ByRegisterOfLimits Then
	
		TempTablesManager = ControlParameters.TempTablesManager;
		
		TempTablesManager = VT_PlanFactManagerForRegisterOfLimits(RulesForLimitsWithAdditionalData, ActualData,
			AdditionalParameters, TempTablesManager);
		ScheduledData = TempTablesManager.Tables.Find("PlannedDataOnRules").GetData().Unload();
		
	ElsIf DecryptionByRegistrar Then
		
		PlannedDataOnRegistrars = PlanningDataForPlanets(RulesForLimitsWithAdditionalData, AdditionalParameters);
		
		// We collapse the data for the correct distribution.
		ScheduledData = PlannedDataOnRegistrars.Copy();
		If ScheduledData.Count() > 0 Then
			MeasurementColumns = "";
			For Each Column In ScheduledData.Columns Do
				If Column.Name = "Recorder"
					Or Column.Name = "SumPlan" Then
					Continue;
				EndIf;
				MeasurementColumns = MeasurementColumns + ?(MeasurementColumns = "", "", ", ") + Column.Name;
			EndDo;
			ScheduledData.GroupBy(MeasurementColumns, "SumPlan");
		EndIf;
	Else
		ScheduledData = PlanningDataForPlanets(RulesForLimitsWithAdditionalData, AdditionalParameters);
	EndIf;
	
	#EndRegion
	
	#Region ReconciliationOfFactAndAdditionOfPlan
	
	If ByRegisterOfLimits Then
		
		ActualDataCollapsed = TempTablesManager.Tables.Find("ActualDataOnRules").GetData().Unload();
		
	Else
		
		ActualDataCollapsed = CollapsedFactForPlanFact(RulesForLimitsWithAdditionalData,
	                                                       ActualData,
	                                                       ScheduledData,
	                                                       AdditionalParameters);
	EndIf;
	
	// Refilling the plan analysts in the collapsed fact table and supplementing the plan table in the absence of data.
	CalculateNearestPlanAnalystsTakingIntoAccountHierarchy(ActualDataCollapsed,
		LimitRules,
		ScheduledData);
	
	#EndRegion 
	
	#Region PlanarCalculation
	
	If DecryptionByRegistrar Then
		// The Actual Data table is collapsed by unused dimensions (analysts), but contains a logger.
		// We leave the original table to get the decryption.
		ActualData = ActualDataCollapsed.Copy();
		MeasurementsOfFact = "";
		For Each FactColumn_ In ActualData.Columns Do
			If FactColumn_.Name = "SumReal" Then
				Continue;
			EndIf;
			MeasurementsOfFact = MeasurementsOfFact + ?(MeasurementsOfFact = "", "", ", ") + FactColumn_.Name;
		EndDo;
		ActualData.GroupBy(MeasurementsOfFact, "SumReal");
	Else
		ActualData = ActualDataCollapsed;
	EndIf;
	
	If ByRegisterOfLimits Then
		
		AddTemporaryFactTableWithPlanDimensions(TempTablesManager, ActualData);
		TablesOfDataOnLimits = CalculatePlanFactAndGenerateRegisteredRecordsTable(TempTablesManager, ControlParameters);
		ActionPlanForLimitRules = TablesOfDataOnLimits.ActionPlanForLimitRules;
		If ControlParameters.ReserveLimitAmount Then
			ControlParameters.TablesForRegisteredRecords.Insert("TableLimitsBasedOnBudgetingData",
				TablesOfDataOnLimits.TableLimitsBasedOnBudgetingData);
			TempTablesManager.Close();
		Else
			ControlParameters.TempTablesManager = TempTablesManager;
		EndIf;
		
	Else
		
		OutlineOfPlanOfFact = Catalogs.BudgetingLimits.GetTemplate("VarianceAnalysisOfLimits");
		
		If ActualData.Columns.Find("AmountFromOriginalApplication") <> Undefined Then
			FinancialReportingServer.NewSetField(OutlineOfPlanOfFact.DataSets.Real,
			"AmountFromOriginalApplication",
			"AmountFromOriginalApplication",,
			TMCommonUse.MoneyFieldTypeDescription());
			
			FinancialReportingServer.NewCalculatedField(OutlineOfPlanOfFact,
			"AmountCanBeDebited",
			"0",
			,
			True,
			TMCommonUse.MoneyFieldTypeDescription());
			
			FinancialReportingServer.NewResource(OutlineOfPlanOfFact, 
			"AmountCanBeDebited",
			"Sum",
			"CASE
			| WHEN ISNULL(SUM(SumPlan), 0) > (ISNULL(SUM(SumReal), 0) - ISNULL(SUM(AmountFromOriginalApplication), 0))
			|     THEN ISNULL(SUM(SumPlan), 0) - (ISNULL(SUM(SumReal), 0) - ISNULL(SUM(AmountFromOriginalApplication), 0))
			|     ELSE 0
			| END");
			
		EndIf;
		
		SettingsComposer = BudgetingServer.DefaultInitializedComposer(OutlineOfPlanOfFact);
		
		DataCompositionClientServer.DisableOutputOfTotals(SettingsComposer);
		
		ExternalDataSets = New Structure;
		ExternalDataSets.Insert("RulesForLimitsWithAdditionalData", RulesForLimitsWithAdditionalData);
		ExternalDataSets.Insert("ActualData", ActualData);
		ExternalDataSets.Insert("ScheduledData",    ScheduledData);
		
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(OutlineOfPlanOfFact));
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
		
		FinancialReportingServer.SetLayoutParameter(SettingsComposer, "FilterByRequest", FilterByDocument);
		FinancialReportingServer.SetLayoutParameter(SettingsComposer, "CourseVerificationDate",
			VerificationDates[0].LimitDate);
		FinancialReportingServer.SetLayoutParameter(SettingsComposer, "ReportCurrency", Currency);
		
		If ActualData.Columns.Find("AmountFromOriginalApplication") <> Undefined Then
			AmountFieldFactOfOriginalRequest =SettingsComposer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
			AmountFieldFactOfOriginalRequest.Use = True;
			AmountFieldFactOfOriginalRequest.Field = New DataCompositionField("AmountCanBeDebited");
		EndIf;
		
		If InContextOfFactGroupings Then
			Settings = SettingsComposer.GetSettings();
			If Settings.Structure.Count() > 0 Then
				Group = Settings.Structure[0];
				If Group.Structure.Count() > 0
					And Group.Structure[0].Name = "DimensionsOfFact" Then
					Group.Structure[0].Use = True;
				EndIf;
			EndIf;
			SettingsComposer.LoadSettings(Settings);
			
			TreePlanFact = FinancialReportingServer.UploadDCSResults(OutlineOfPlanOfFact, SettingsComposer,
				ExternalDataSets, True);
			
			ActionPlanForLimitRules = New ValueTable;
			For Each TreeColumn In TreePlanFact.Columns Do
				If TreeColumn.Name = "Organization"
					Or TreeColumn.Name = "CompanyActual" Then
					ColumnType = New TypeDescription("CatalogRef.Companies");
				ElsIf TreeColumn.Name = "Department"
					Or TreeColumn.Name = "DepartmentActual" Then
					ColumnType = New TypeDescription("CatalogRef.BusinessStructure");
				Else
					ColumnType = TreeColumn.ValueType;
				EndIf;
				ActionPlanForLimitRules.Columns.Add(TreeColumn.Name, ColumnType);
			EndDo;
			ActionPlanForLimitRules.Columns.Add("ThisIsAFactLine", New TypeDescription("Boolean"));
			ActionPlanForLimitRules.Columns.Add("HasFactLines", New TypeDescription("Boolean"));
			
			If DecryptionByRegistrar Then
				ActionPlanForLimitRules.Columns.Add("Recorder");
				
				// Correspondences, where the Key is the name of the Planfact column, the value is the name of the column of the table with the registrar.
				PlanSearchFields = New Map;
				FactSearchFields = New Map;
				
				PlanSearchFields.Insert("Organization", "CompanyPlan");
				PlanSearchFields.Insert("Department", "DepartmentPlan");
				
				FactSearchFields.Insert("CompanyActual", "Organization");
				FactSearchFields.Insert("DepartmentActual", "Department");
				
				For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
					PlanSearchFields.Insert("Dimension" + DimensionNumber, "Dimension" + DimensionNumber + "Plan");
					FactSearchFields.Insert("Dimension" + DimensionNumber + "Real", "Dimension" + DimensionNumber);
				EndDo;
				
				PlanLoggersColumns = "LimitsRule, BudgetFlowItem, BeginOfPeriod, EndOfPeriod";
				ColumnsOfFactLoggers = "LimitsRule, BudgetFlowItem, BeginOfPeriod, EndOfPeriod";
				
				For Each ColumnsMap In PlanSearchFields Do
					PlanLoggersColumns = PlanLoggersColumns + ", " + ColumnsMap.Value;
				EndDo;
				For Each ColumnsMap In FactSearchFields Do
					ColumnsOfFactLoggers = ColumnsOfFactLoggers + ", " + ColumnsMap.Value;
				EndDo;
				
				PlannedDataOnRegistrars.Indexes.Add(PlanLoggersColumns);
				ActualDataCollapsed.Indexes.Add(ColumnsOfFactLoggers);
				
				SearchPlan = New Structure(PlanLoggersColumns);
				SearchFact = New Structure(ColumnsOfFactLoggers);
				
			EndIf;
			// The value tree is bypassed. On the 1st level, only the amount of the plan is set, on the 2nd only the amount of the fact.
			// It turns out a table that is placed in the layout scheme of the report.
			
			For Each LinePlan In TreePlanFact.Rows Do
				
				If DecryptionByRegistrar Then
					
					FillPropertyValues(SearchPlan, LinePlan, "LimitsRule, BudgetFlowItem, BeginOfPeriod, EndOfPeriod");
					For Each ColumnsMap In PlanSearchFields Do
						SearchPlan[ColumnsMap.Value] = LinePlan[ColumnsMap.Key];
					EndDo;
					PlanRegistrars = PlannedDataOnRegistrars.FindRows(SearchPlan);
					For Each PlanLineWithRegistrar In PlanRegistrars Do
						
						NewRow = ActionPlanForLimitRules.Add();
						FillPropertyValues(NewRow, LinePlan,, "SumReal");
						NewRow.SumPlan = PlanLineWithRegistrar.SumPlan;
						NewRow.Recorder = PlanLineWithRegistrar.Recorder;
						NewRow.SumReal = 0;
						NewRow.ExcessAmount = 0;
						NewRow.ThisIsAFactLine = False;
						NewRow.HasFactLines = (LinePlan.Rows.Count() > 0);
						
					EndDo;
				Else
					
					NewRow = ActionPlanForLimitRules.Add();
					FillPropertyValues(NewRow, LinePlan,, "SumReal");
					NewRow.SumReal = 0;
					NewRow.ThisIsAFactLine = False;
					NewRow.HasFactLines = (LinePlan.Rows.Count() > 0);
					
				EndIf;
				
				For Each NestedFactString In LinePlan.Rows Do
					
					If DecryptionByRegistrar Then
						
						FillPropertyValues(SearchFact, LinePlan, "LimitsRule, BudgetFlowItem, BeginOfPeriod, EndOfPeriod");
						For Each ColumnsMap In FactSearchFields Do
							SearchFact[ColumnsMap.Value] = NestedFactString[ColumnsMap.Key];
						EndDo;
						
						FactLoggers = ActualDataCollapsed.FindRows(SearchFact);
						For Each FactStringWithLogger In FactLoggers Do
							
							NewRow = ActionPlanForLimitRules.Add();
							FillPropertyValues(NewRow, NestedFactString,, "SumPlan, ExcessAmount");
							NewRow.SumPlan = 0;
							NewRow.ExcessAmount = 0;
							NewRow.SumReal = FactStringWithLogger.SumReal;
							NewRow.Recorder = FactStringWithLogger.Recorder;
							NewRow.ThisIsAFactLine = True;
							
						EndDo;
					Else
						
						NewRow = ActionPlanForLimitRules.Add();
						FillPropertyValues(NewRow, NestedFactString,, "SumPlan, ExcessAmount");
						NewRow.SumPlan = 0;
						NewRow.ExcessAmount = 0;
						NewRow.ThisIsAFactLine = True;
						
					EndIf;
					
				EndDo;
				
			EndDo;
		Else
			
			ActionPlanForLimitRules = FinancialReportingServer.UploadDCSResults(OutlineOfPlanOfFact,
				SettingsComposer, ExternalDataSets);
			
		EndIf;
		
	EndIf;
	
	If Not UseMultipleCurrencies Then
		If ActionPlanForLimitRules.Columns.Find("Currency") = Undefined Then
			ActionPlanForLimitRules.Columns.Add("Currency");
		EndIf;
		ActionPlanForLimitRules.FillValues(Constants.ManagementAccountingCurrency.Get(), "Currency");
	EndIf;
	
	#EndRegion
	
	Return ActionPlanForLimitRules;

EndFunction

Function PlanningDataForPlanets(RulesForLimitsWithAdditionalData, AdditionalParameters)
	
	DecryptionByRegistrar = AdditionalParameters.DecryptionByRegistrar;
	UseMultipleCurrencies = AdditionalParameters.UseMultipleCurrencies;
	CheckDate = AdditionalParameters.VerificationDates[0].LimitDate;
	RequestCurrency = AdditionalParameters.RequestCurrency;
	AdditionalSelectionOfReportTranscript = AdditionalParameters.AdditionalSelectionOfReportTranscript; // - Structure -
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("RulesForLimitsWithAdditionalData", RulesForLimitsWithAdditionalData);
	SchemeForObtainingPlan = Catalogs.BudgetingLimits.GetTemplate("GettingOfPlanData");
	If DecryptionByRegistrar Then
		DataSetPlan = SchemeForObtainingPlan.DataSets.Plan;
		DataSetPlan.Query = StrReplace(DataSetPlan.Query,
		                                     "//FrequencyLoggerForDecryption",
		                                     "Recorder");
		DataSetPlan.Query = StrReplace(DataSetPlan.Query,
		                                     "//LoggerFieldExpressionForDecryption",
		                                     "PlanTable_.Recorder AS Recorder,");
		DataSetPlan.Query = StrReplace(DataSetPlan.Query,
		                                     "//LoggerFieldForDecryption",
		                                     "Recorder.*,");
		FinancialReportingServer.NewSetField(DataSetPlan, "Recorder", "Recorder");
	EndIf;
	ComposerForGettingPlan = BudgetingServer.DefaultInitializedComposer(SchemeForObtainingPlan);
	
	If UseMultipleCurrencies Then
		
		PlanRecalculationColumns = New Array;
		PlanRecalculationColumns.Add("SumPlan");
		
		PlanRecalculationParameters = BudgetingServer.TemplateForCurrencyConversionParameters();
		PlanRecalculationParameters.NameOfSourceDataSet = "Plan";
		PlanRecalculationParameters.SourceCurrency = "CurrencyPlan";
		PlanRecalculationParameters.ConversionColumns = PlanRecalculationColumns;
		PlanRecalculationParameters.RatePeriod = CheckDate;
		PlanRecalculationParameters.TargetCurrency = RequestCurrency;
		
		BudgetingServer.AddDataConversionToCurrency(SchemeForObtainingPlan, ComposerForGettingPlan, PlanRecalculationParameters);
		
		SettlementCurrencyField = SchemeForObtainingPlan.CalculatedFields.Find("Currency");
		SettlementCurrencyField.Expression = "&TargetCurrency" + "Plan" + "1";
		
	EndIf;
		
	ComposerForGettingPlan.Initialize(New DataCompositionAvailableSettingsSource(SchemeForObtainingPlan));
	ComposerForGettingPlan.Refresh(DataCompositionSettingsRefreshMethod.Full);
	DataCompositionClientServer.DisableOutputOfTotals(ComposerForGettingPlan);
	
	If Not AdditionalSelectionOfReportTranscript = Undefined
		And AdditionalSelectionOfReportTranscript.UseFilter1 Then
		// Transcript of the limits report. When deciphering, the type of comparison is only for equality.
		// Changing report settings is not allowed.
		If AdditionalSelectionOfReportTranscript.Property("BudgetingModel")
			And Not AdditionalSelectionOfReportTranscript.Property("LimitsRule") Then
			
			FinancialReportingServer.NewCalculatedField(SchemeForObtainingPlan,
			                                                "BudgetingModel",
			                                                "LimitsRule.Owner",
			                                                ,
			                                                True,
			                                                New TypeDescription("CatalogRef.BudgetingModels"));
			
			FinancialReportingServer.NewFilter(
				ComposerForGettingPlan.Settings.Filter,
				"BudgetingModel",
				AdditionalSelectionOfReportTranscript.BudgetingModel,,
				DataCompositionComparisonType.Equal);
		EndIf;
		If AdditionalSelectionOfReportTranscript.Property("LimitsRule") Then
			
			FinancialReportingServer.NewFilter(
				ComposerForGettingPlan.Settings.Filter,
				"LimitsRule",
				AdditionalSelectionOfReportTranscript.LimitsRule,,
				DataCompositionComparisonType.Equal);
		EndIf;
		SelectionByPlanAnalysts = Undefined;
		If AdditionalSelectionOfReportTranscript.Property("SelectionByPlanAnalysts", SelectionByPlanAnalysts) Then
			For Each FilterElement In SelectionByPlanAnalysts Do
				FinancialReportingServer.NewFilter(
					ComposerForGettingPlan.Settings.Filter,
					FilterElement.DimensionNameAnalyticsNumber + "Plan",
					FilterElement.Value,,
					DataCompositionComparisonType.Equal);
			EndDo;
		EndIf;
		If DecryptionByRegistrar Then
			GroupingDataChunks = ComposerForGettingPlan.Settings.Structure[0];
			FinancialReportingServer.NewDimensionField(GroupingDataChunks, "Recorder");
		EndIf;
	EndIf;
	
	ScheduledData = FinancialReportingServer.UploadDCSResults(SchemeForObtainingPlan,
		ComposerForGettingPlan,
		ExternalDataSets);
	
	Return ScheduledData;
EndFunction

Function CollapsedFactForPlanFact(RulesForLimitsWithAdditionalData, ActualData, ScheduledData, AdditionalParameters)
	
	DecryptionByRegistrar = AdditionalParameters.DecryptionByRegistrar;
	UseMultipleCurrencies = AdditionalParameters.UseMultipleCurrencies;
	CheckDate = AdditionalParameters.VerificationDates[0].LimitDate;
	RequestCurrency = AdditionalParameters.RequestCurrency;
	
	#Region FactConvolutionTemplate
	
	// 1. Initially, the fact is obtained with the analytics specified in the article. Since
	// measurements and analytics can be disabled in the limit control rules, it is necessary to collapse the fact lines in the context
	// of the limit control rules used (the section for the budgeting item is not sufficient, because one article can be specified in different rules).
	
	// 2. In the Planfactual Analysis scheme, the fact is attached to the plan. That is, the data set of the plan must be
	// obtained without taking into account the parameters of the fact data set. The rules table will be supplemented with possible periods for obtaining planned data.
	
	// 3. For each fact line, we will get one (and only one) line of the plan that is most suitable for it, taking into account the hierarchy of measurements
	// and analytics specified in the limit control rule.
	//  EXAMPLE 1. Thus, if a plan is given:
	//     Counterparty1
	//        <Other Contracts> - amount of 1 plan
	//     Counterparty2
	//        <Other Contracts> - the sum of 2 plans
	//     <Other counterparties>
	//        <Other Contracts> - the amount of 3 plans,
	//   then for the fact line Counterparty1 and Contract2, only the amount of 1 plan should be received, as the nearest value.
	//  EXAMPLE 2. Also, if a plan is set:
	//     Counterparty1
	//        Contract1 - amount of 1 plan
	//     Counterparty2
	//        Agreement2 - the sum of 2 plans
	//     <Other counterparties>
	//        <Other Contracts> - the amount of 3 plans,
	//   then for the fact line Counterparty1 and Contract2, only the amount = 0 should be received
	//   according to the NON-specified analytics of the plan Counterparty1 and <Other Contracts>.
	//  EXAMPLE 3. Also, if a plan is set:
	//     Counterparty1
	//        <Other Contracts> - amount of 1 plan
	//     Counterparty2
	//        <Other Contracts> - the sum of 2 plans
	//     <Other counterparties>
	//        <Other Contracts> - the amount of 3 plans,
	//   then for the fact line Counterparty3 and Contract3, only the amount of 3 plans should be received, as the nearest value.
	//
	// Using the calculated measurement coefficients and analytics,
	// the maximum cumulative coefficient of a line of a suitable plan is calculated in the fact convolution DCS.
	// Moreover, in the fact DCS convolution for the purposes of determining the closest plan analytics, taking into account the hierarchy,
	// it is considered that ALL lines of the plan are suitable for the fact line. Thus, if there is no suitable line
	// of the plan (Example 2), then the maximum cumulative coefficient of the line of the suitable plan will be calculated correctly.
	// The higher the dimension (analytics) in the hierarchy, the higher the coefficient of measurement (analytics).
	// When calculating the total coefficient, it is considered if the analysts match completely, the coefficient is multiplied by 2,
	// If the analytics in the fact is filled in, and in the <other> plan, then the coefficient is multiplied by 1,
	// If the analytics in the plan is filled in and does not match the analytics of the fact, then the coefficient is multiplied by 0.
	//  EXAMPLE 1 (conditions are given above):
	//   for the fact line, Counterparty1 and Contract2 correspond to the plan line:
	//     Counterparty1, <Other Contracts>. Total coefficient = 2 * 10 + 1 * 1 = 21,
	//                                       where 2 is the coincidence of counterparties
	//                                           10 - analytics coefficient Counterparties
	//                                           1 - other Contract analytics in terms of
	//                                           1 - Contract analytics coefficient.
	//     Counterparty2, Contract2. Total coefficient = 0 * 10 + 2 * 1 = 2.
	//     <Other counterparties>, <Other Contracts>. Total coefficient = 1 * 10 + 1 * 1 = 11.
	//   Thus, the maximum coefficient of suitable plan analytics = 21.
	//   The reverse transformation gives the plan analytics: 20 = 2 * 10 (Counterparty1) and 1 = 1 * 1 (<Other Contracts>).
	//  EXAMPLE 2 (the conditions are given above):
	//   for the fact line, Counterparty1 and Contract2 correspond to the lines of the plan:
	//     Counterparty1, <Other Contracts>. Total coefficient = 2 * 10 + 0 * 1 = 20,
	//     Counterparty2, Contract2. Total coefficient = 0 * 10 + 2 * 1 = 2.
	//     <Other counterparties>, <Other Contracts>. Total coefficient = 1 * 10 + 1 * 1 = 11.
	//   Thus, the maximum coefficient of suitable plan analytics = 20.
	//   The reverse transformation gives the plan analytics: 20 = 2 * 10 (Counterparty1) and 0 = 0 * 1 (<Other Contracts>), although such an analysis of the plan is NOT specified.
	//  EXAMPLE 3 (conditions are given above):
	//   for the fact line, Counterparty3 and Contract3 correspond to the plan lines:
	//     Counterparty1, <Other Contracts>. Total coefficient = 0 * 10 + 1 * 1 = 1,
	//     Counterparty2, <Other Contracts>. Total coefficient = 0 * 10 + 1 * 1 = 1.
	//     <Other counterparties>, <Other Contracts>. Total coefficient = 1 * 10 + 1 * 1 = 11.
	//   Thus, the maximum coefficient of suitable plan analytics = 11.
	//   The reverse transformation gives the plan analytics: 10 = 1 * 10 (<Other counterparties>) and 1 = 1 * 1 (<Other Contracts>).
	
	FactConvolutionScheme = Catalogs.BudgetingLimits.GetTemplate("ActualDataCollapse");
	
	ExpressionFinalCoefficientOfPlanAnalytics = ExpressionFinalCoefficientOfPlanAnalytics();
	
	#EndRegion
	
	DataSetFact = FactConvolutionScheme.DataSets.Real;
	If DecryptionByRegistrar Then
		// The registrar of the fact.
		FinancialReportingServer.NewSetField(DataSetFact, "Recorder", "Recorder");
	EndIf;
	If ActualData.Columns.Find("AmountFromOriginalApplication") <> Undefined Then
		FinancialReportingServer.NewSetField(DataSetFact,
		                                           "AmountFromOriginalApplication",
		                                           "AmountFromOriginalApplication",,
		                                           TMCommonUse.MoneyFieldTypeDescription());
		
		FinancialReportingServer.NewResource(FactConvolutionScheme, "AmountFromOriginalApplication", "Sum");
	EndIf;
	
	TotalPlanAnalyticsCoefficientField = FactConvolutionScheme.CalculatedFields.Find("FinalPlanAnalyticsFactor");
	TotalPlanAnalyticsCoefficientField.Expression = ExpressionFinalCoefficientOfPlanAnalytics;
	
	ConvolutionSettingsComposer = BudgetingServer.DefaultInitializedComposer(FactConvolutionScheme);
	
	If UseMultipleCurrencies Then
		
		PlanRecalculationColumns = New Array;
		PlanRecalculationColumns.Add("SumReal");
		If ActualData.Columns.Find("AmountFromOriginalApplication") <> Undefined Then
			PlanRecalculationColumns.Add("AmountFromOriginalApplication");
		EndIf;
		
		FactRecalculationParameters = BudgetingServer.TemplateForCurrencyConversionParameters();
		FactRecalculationParameters.NameOfSourceDataSet = "Real";
		FactRecalculationParameters.SourceCurrency = "CurrencyActual";
		FactRecalculationParameters.ConversionColumns = PlanRecalculationColumns;
		FactRecalculationParameters.RatePeriod = CheckDate;
		FactRecalculationParameters.TargetCurrency = RequestCurrency;
		
		BudgetingServer.AddDataConversionToCurrency(FactConvolutionScheme, ConvolutionSettingsComposer, FactRecalculationParameters);
		
		SettlementCurrencyField = FactConvolutionScheme.CalculatedFields.Find("Currency");
		SettlementCurrencyField.Expression = "&TargetCurrency" + "Real" + "1";
		
	EndIf;
	
	ConvolutionSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(FactConvolutionScheme));
	ConvolutionSettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	DataCompositionClientServer.DisableOutputOfTotals(ConvolutionSettingsComposer);
	
	If DecryptionByRegistrar Then
		GroupingDataChunks = ConvolutionSettingsComposer.Settings.Structure[0];
			FinancialReportingServer.NewDimensionField(GroupingDataChunks, "Recorder");
	EndIf;
	If ActualData.Columns.Find("AmountFromOriginalApplication") <> Undefined Then
		AmountFieldFactOfOriginalRequest =ConvolutionSettingsComposer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		AmountFieldFactOfOriginalRequest.Use = True;
		AmountFieldFactOfOriginalRequest.Field = New DataCompositionField("AmountFromOriginalApplication");
	EndIf;
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("RulesForLimitsWithAdditionalData", RulesForLimitsWithAdditionalData);
	ExternalDataSets.Insert("ScheduledData", ScheduledData);
	ExternalDataSets.Insert("ActualData", ActualData);
	
	ActualDataCollapsed = FinancialReportingServer.UploadDCSResults(FactConvolutionScheme, ConvolutionSettingsComposer, ExternalDataSets);
	
	Return ActualDataCollapsed;
EndFunction

Function DataOfAdditionalFieldsOfRulesLimits(LimitRules, HierarchyOfAnalystsByRules)
	
	AdditionalFieldData_ = LimitRules.CopyColumns();
	AdditionalFieldData_.Columns.Add("ByCompanies", New TypeDescription("Boolean"));
	AdditionalFieldData_.Columns.Add("ByBusinessUnits", New TypeDescription("Boolean"));
	AdditionalFieldData_.Columns.Add("ByScenarios", New TypeDescription("Boolean"));
	// Fields for the purposes of determining the most appropriate plan line for each fact line.
	AdditionalFieldData_.Columns.Add("OrganizationCoefficient", New TypeDescription("Number", , ,
		New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	AdditionalFieldData_.Columns.Add("SubdivisionCoefficient", New TypeDescription("Number", , ,
		New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	// The fields of the beginning of the period and the end of the period for transmitting parameters to the plan receipt sets.
	AdditionalFieldData_.Columns.Add("BeginOfPeriod", New TypeDescription("Date", , , , ,
		New DateQualifiers(DateFractions.Date)));
	AdditionalFieldData_.Columns.Add("EndOfPeriod", New TypeDescription("Date", , , , ,
		New DateQualifiers(DateFractions.Date)));
	
	TypesOfAnalyticsRules = New Structure; 
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AdditionalFieldData_.Columns.Add("DimensionKind" + DimensionNumber,
			New TypeDescription("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions, Null"));
		TypesOfAnalyticsRules.Insert("DimensionKind" + DimensionNumber);
		
		// Fields for the purposes of determining the most appropriate plan line for each fact line.
		AdditionalFieldData_.Columns.Add("CoefficientOfTypeOfAnalytics" + DimensionNumber,
			New TypeDescription("Number", , , New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
		TypesOfAnalyticsRules.Insert("CoefficientOfTypeOfAnalytics" + DimensionNumber);
	EndDo;
	
	For Each LimitRule In LimitRules Do
	
		#Region CachingRuleSettings
		DimensionsHierarchy = HierarchyOfAnalystsByRules.Get(LimitRule.LimitsRule);
		FoundRows = DimensionsHierarchy.FindRows(New Structure("MeasurementViewAnalytics", "Organization"));
		If FoundRows.Count() > 0
		   And FoundRows[0].Used Then
			ByCompanies = True;
			OrganizationCoefficient = FoundRows[0].ZoomRatio;
		Else
			ByCompanies = False;
			OrganizationCoefficient = 0;
		EndIf;
			
		FoundRows = DimensionsHierarchy.FindRows(New Structure("MeasurementViewAnalytics", "Department"));
		If FoundRows.Count() > 0
		   And FoundRows[0].Used Then
			ByBusinessUnits = True;
			SubdivisionCoefficient = FoundRows[0].ZoomRatio;
		Else
			ByBusinessUnits = False;
			SubdivisionCoefficient = 0;
		EndIf;
		
		ByScenarios = ValueIsFilled(LimitRule.Scenario);
		
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			FoundRows = DimensionsHierarchy.FindRows(New Structure("PathToAnalytics", "Dimension" + DimensionNumber));
			If FoundRows.Count() > 0
			   And FoundRows[0].Used Then
				TypesOfAnalyticsRules["DimensionKind" + DimensionNumber] = FoundRows[0].MeasurementViewAnalytics;
				TypesOfAnalyticsRules["CoefficientOfTypeOfAnalytics" + DimensionNumber] = FoundRows[0].ZoomRatio;
			Else
				TypesOfAnalyticsRules["DimensionKind" + DimensionNumber] = Undefined;
				TypesOfAnalyticsRules["CoefficientOfTypeOfAnalytics" + DimensionNumber] = 0;
			EndIf;
		EndDo;
		
		#EndRegion 
		
		AdditionalDataLine_ = AdditionalFieldData_.Add();
		FillPropertyValues(AdditionalDataLine_, LimitRule);
		AdditionalDataLine_.ByCompanies           = ByCompanies;
		AdditionalDataLine_.OrganizationCoefficient   = OrganizationCoefficient;
		AdditionalDataLine_.ByBusinessUnits         = ByBusinessUnits;
		AdditionalDataLine_.SubdivisionCoefficient = SubdivisionCoefficient;
		AdditionalDataLine_.ByScenarios              = ByScenarios;
		
		FillPropertyValues(AdditionalDataLine_, TypesOfAnalyticsRules);
	EndDo;
	
	AdditionalFieldData_.Columns.Add("HashOfDataCompositionSchema");
	
	Return AdditionalFieldData_;
EndFunction

// Returns the setting for getting a fact for a document that consumes the limit
//
// Parameters:
//  DocumentKind - CatalogRef.MetadataObjectIDs - type of controlled document
//  ActualDataQueryRules_ - Undefined,
//                          Assignment tables - rules for getting a fact.
//  RulesForLimitsByTypeOfAnalytics - Undefined,
//                          Assignment tables - rules for filling in types of limit rule analytics.
//
// Returns:
//  Structure - the data structure for building a query to the source of the fact:
//   *QueryText - String - Query text
//   *QueryOptions - Structure - request parameters
//
Function SettingUpReceiptOfFactOnDocumentOnDate(DocumentKind, ActualDataQueryRules_, RulesForLimitsByTypeOfAnalytics)
	
	ConfigureActualDataReceipt = New Structure("QueryText, QueryOptions, TemporaryTableNames", "",
		New Structure, New Array);
	
	RowsCount = 0;
	If TypeOf(ActualDataQueryRules_) = Type("ValueTable") Then
		RowsCount = RowsCount + ActualDataQueryRules_.Count();
	EndIf;
	If TypeOf(RulesForLimitsByTypeOfAnalytics) = Type("ValueTable") Then
		RowsCount = RowsCount + RulesForLimitsByTypeOfAnalytics.Count();
	EndIf;
	If RowsCount = 0 Then
		Return ConfigureActualDataReceipt;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"CommonModule.LimitsByBudgetingData.SettingUpReceiptOfFactOnDocumentOnDate");
	ProcessedRowsCount = 0;
	
	ColumnsTypesOfRuleAccountingData = "TypeOfAccountingDataReceipt, TypeOfAccountingDataExpense, HashOfDataCompositionSchema";
	If TypeOf(ActualDataQueryRules_) = Type("ValueTable") Then
		TypesOfRuleAccountingData = ActualDataQueryRules_.Copy(, ColumnsTypesOfRuleAccountingData);
		If TypeOf(RulesForLimitsByTypeOfAnalytics) = Type("ValueTable")
			And RulesForLimitsByTypeOfAnalytics.Count() > 0 Then
			FillPropertyValues(TypesOfRuleAccountingData.Add(), RulesForLimitsByTypeOfAnalytics[0],
				ColumnsTypesOfRuleAccountingData);
		EndIf;
	Else
		TypesOfRuleAccountingData = RulesForLimitsByTypeOfAnalytics.Copy(, ColumnsTypesOfRuleAccountingData);
	EndIf;
	TypesOfRuleAccountingData.GroupBy(ColumnsTypesOfRuleAccountingData);
	TypesOfRuleAccountingData.Columns.Add("TempTableName", New TypeDescription("String", ,
		New StringQualifiers(500)));
	TypesOfRuleAccountingData.Columns.Add("Factor",
		New TypeDescription("EnumRef.IndicatorsOfAnalyticalRegisters"));
	TypesOfRuleAccountingData.Columns.Add("DCSSettings", New TypeDescription("DataCompositionSettings"));
	
	FullDocumentName = Common.MetadataObjectByID(DocumentKind).FullName();
	ManagerOfDocument = Common.ObjectManagerByFullName(FullDocumentName);
	
	QueriesTexts = New Array;
	
	RulesAttributes = New Array;
	TemplateForRuleAttributes = "DimensionPopulationExpression%1, FillInAnalyticsWithSpecifiedValue%1, DimensionValue%1";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		RulesAttributes.Add(StringFunctionsClientServer.SubstituteParametersToString(TemplateForRuleAttributes,
			DimensionNumber));
	EndDo;
	
	If TypeOf(ActualDataQueryRules_) = Type("ValueTable") Then
		RuleDescriptions = Common.ObjectsAttributesValues(ActualDataQueryRules_.UnloadColumn("Rule"),
			StrConcat(RulesAttributes, ", ") + ", BudgetFlowItem, TransactionAmountSource, SettingsComposer, DataSourceScheme");
	EndIf;
	
	TheStructureOfTheSearch = New Structure(ColumnsTypesOfRuleAccountingData);
	
	For Each ReceiptExpense In TypesOfRuleAccountingData Do
		If IsBlankString(ReceiptExpense.HashOfDataCompositionSchema) Then
			TempTableName = "RegisterRecords" + TargetValueMonitoring.GetNameOfEnumerationValue(ReceiptExpense.TypeOfAccountingDataExpense)
				+ TargetValueMonitoring.GetNameOfEnumerationValue(ReceiptExpense.TypeOfAccountingDataReceipt);
			QueriesTexts.Add(ManagerOfDocument.QueryTextFactSourceByTypeOfAccountingData(
				ReceiptExpense.TypeOfAccountingDataExpense, ReceiptExpense.TypeOfAccountingDataReceipt, TempTableName));
			FactSourceTemplate = DataSourcesServer.TableOfCorrespondenceRegisters(New Structure("Receipt, Expense",
				ReceiptExpense.TypeOfAccountingDataReceipt, ReceiptExpense.TypeOfAccountingDataExpense));
			DCSRules_ = DataSourcesServer.DataCompositionSchemaAccordingToCorrespondenceTableOfRegisters(FactSourceTemplate);
		Else
			RequiredFieldsOfRuleDataSource = StrSplit(
				"Organization,Department,Currency,DataSource,Recorder,AmountInCurrency", ",");
			TempTableName = "TempTable_" + ReceiptExpense.HashOfDataCompositionSchema;
			FillPropertyValues(TheStructureOfTheSearch, ReceiptExpense);
			Rule = ActualDataQueryRules_.FindRows(TheStructureOfTheSearch)[0].Rule;
			DCSRules_ = RuleDescriptions[Rule].DataSourceScheme.Get();
			ErrorText = "";
			For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
				DimensionPopulationExpression = RuleDescriptions[Rule]["DimensionPopulationExpression"+DimensionNumber];
				If IsBlankString(DimensionPopulationExpression) Then
					Continue;
				EndIf;
				DimensionPopulationExpression = ProcessingOfFormulasClientServer.OperandParts(DimensionPopulationExpression)[0];
				If RequiredFieldsOfRuleDataSource.Find(DimensionPopulationExpression) = Undefined Then
					RequiredFieldsOfRuleDataSource.Add(DimensionPopulationExpression);
				EndIf;
			EndDo;
			ElementsOfRuleSelection = DataCompositionClientServer.GetSelectionElements(
				RuleDescriptions[Rule].SettingsComposer.Get().Filter);
			For Each FilterElement In ElementsOfRuleSelection Do
				If RequiredFieldsOfRuleDataSource.Find(TrimAll(FilterElement.LeftValue)) = Undefined Then
					RequiredFieldsOfRuleDataSource.Add(TrimAll(FilterElement.LeftValue));
				EndIf;
			EndDo;
			For Each RequiredField In RequiredFieldsOfRuleDataSource Do
				SelectedFieldsOfSKDRuleSettings = DCSRules_.DefaultSettings.Selection; // - DataCompositionSelectedFields -
				If DataCompositionServer.FindDCSFieldByFullName(SelectedFieldsOfSKDRuleSettings.Items,
					RequiredField) = Undefined Then
					ErrorText = ?(IsBlankString(ErrorText), "", ErrorText + Chars.LF)
						+ StringFunctionsClientServer.SubstituteParametersToString(NStr(
						"vi = 'Đã tùy chỉnh sai quy tắc dữ liệu tùy ý theo dạng ngân sách ""%1"": Chưa chỉ ra trường ""%2"" để điền đối tượng phân tích trong các trường được chọn.';
						|ru = 'Некорректно настроено правило произвольных данных по статье бюджетов ""%1"": Поле ""%2"" для заполнения аналитики не указано в выбранных полях.';
						|en = 'The arbitrary data rule for the ""%1"" budget flow item is incorrectly configured: the ""%2"" field for filling in the dimension is not specified in the selected fields.'; fa = 'The arbitrary data rule for the ""%1"" budget flow item is incorrectly configured: the ""%2"" field for filling in the dimension is not specified in the selected fields.';
						|it = 'Некорректно настроено правило произвольных данных по статье бюджетов ""%1"": Поле ""%2"" для заполнения аналитики не указано в выбранных полях.';
						|pl = 'The arbitrary data rule for the ""%1"" budget flow item is incorrectly configured: the ""%2"" field for filling in the dimension is not specified in the selected fields.';
						|tr = '""%1"" bütçe kalemi için rastgele veri kuralı yanlış ayarlanmış: Boyut doldurması için ""%2"" alanı, seçilen alanlarda belirtilmemiş.'"),
						RuleDescriptions[Rule].BudgetFlowItem, RequiredField);
				EndIf;
			EndDo;
			If Not IsBlankString(ErrorText) Then
				Raise ErrorText;
			EndIf;
			RequestByRule = DataSourcesServer.QueryAccordingToSchemaOfRuleDataSource(DCSRules_, TempTableName);
			If RequestByRule = Undefined Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
					"vi = 'Đã tùy chỉnh sai quy tắc dữ liệu tùy ý theo dạng ngân sách ""%1"": không có trường được chọn trong các tùy chỉnh.';
					|ru = 'Некорректно настроено правило произвольных данных по статье бюджетов ""%1"": отсутствуют выбранные поля в настройках.';
					|en = 'The arbitrary data rule for the ""%1"" budget flow item is incorrectly configured: the selected fields are missing in the settings.'; fa = 'The arbitrary data rule for the ""%1"" budget flow item is incorrectly configured: the selected fields are missing in the settings.';
					|it = 'Некорректно настроено правило произвольных данных по статье бюджетов ""%1"": отсутствуют выбранные поля в настройках.';
					|pl = 'The arbitrary data rule for the ""%1"" budget flow item is incorrectly configured: the selected fields are missing in the settings.';
					|tr = '""%1"" bütçe kalemi için rastgele veri kuralı yanlış konfigüre edilmiş: Ayarlarda seçili alanlar eksik.'"),
					RuleDescriptions[Rule].BudgetFlowItem);
				Raise ErrorText;
			EndIf;
			QueriesTexts.Add(RequestByRule.Text);
			For Each QueryParameter In RequestByRule.Parameters Do
				ConfigureActualDataReceipt.QueryOptions.Insert(QueryParameter.Key, QueryParameter.Value);
			EndDo;
		EndIf;
		ReceiptExpense.TempTableName = TempTableName;
		ReceiptExpense.DCSSettings = BudgetingServer.InitializedDefaultSettings(DCSRules_);
	EndDo;
	
	TemplateForRequestToSourceOfFactBasedOnRule =
		"SELECT
		|	&BudgetFlowItemGUID AS BudgetFlowItem,
		|	&GUIDLimitRule AS LimitsRule,
		|	&LimitationPeriod AS LimitationPeriod,
		|	AliasOfSourceTable.Period AS Period,
		|	AliasOfSourceTable.Organization AS Organization,
		|	AliasOfSourceTable.Department AS Department,
		|	AliasOfSourceTable.Currency AS Currency,
		|	&TextOfDimensionsFields,
		|	&TextAmount AS Sum,
		|	&TextSumFact AS SumReal
		|INTO ActualDataOnDocument
		|FROM
		|	AliasOfSourceTable AS AliasOfSourceTable
		|WHERE
		|	&DataSourceCondition
		|	AND &ConditionText";
	TemplateForRequestToSourceOfFactBasedOnRule = StrReplace(TemplateForRequestToSourceOfFactBasedOnRule,
		"AS AliasOfSourceTable", "AS AliasOfSourceTable
										 |	&TextOfConnections"); // @query-part
	
	TextsOfRequestsToFactSourceAccordingToRule = New Array;
	
	If TypeOf(ActualDataQueryRules_) = Type("ValueTable") Then
	
		AmountIndicators_ = DataSourcesCached.RegisteredRecordsOfCashDisbursements();
		
		UseFactAmount = (FullDocumentName = Metadata.Documents.BankAccountIssue.FullName()
			Or FullDocumentName = Metadata.Documents.CashVoucher.FullName());
		
		For Each StringRule In ActualDataQueryRules_ Do
			
			ProcessedRowsCount = ProcessedRowsCount + 1;
			
			FillPropertyValues(TheStructureOfTheSearch, StringRule);
			TypesOfAccountingDataRules = TypesOfRuleAccountingData.FindRows(TheStructureOfTheSearch)[0];
			RuleDescription_ = RuleDescriptions[StringRule.Rule];
			
			DataForRuleRequest = DataSourcesServer.DataForRequestToSourceOfFactAccordingToRule(RuleDescription_,
				TypesOfAccountingDataRules.DCSSettings);
			
			If StringRule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
				NameOfAmountIndicator = AmountIndicators_.Get(RuleDescription_.TransactionAmountSource).Resources[0]["Name"];
			Else
				NameOfAmountIndicator = "AmountInCurrency";
			EndIf;
			If UseFactAmount Then
				QueryText = StrReplace(TemplateForRequestToSourceOfFactBasedOnRule, "&TextSumFact", "AliasOfSourceTable." + NameOfAmountIndicator);
				QueryText = StrReplace(QueryText, "&TextAmount", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(0));
			Else
				QueryText = StrReplace(TemplateForRequestToSourceOfFactBasedOnRule, "&TextSumFact", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(0));
				QueryText = StrReplace(QueryText, "&TextAmount", "AliasOfSourceTable." + NameOfAmountIndicator);
			EndIf;
			QueryText = StrReplace(QueryText, "&TextOfDimensionsFields",
				DataForRuleRequest.QueryTextFragments.TextOfDimensionsFields);
			QueryText = StrReplace(QueryText, "&TextOfConnections",
				DataForRuleRequest.QueryTextFragments.TextOfConnections);
			If Not IsBlankString(DataForRuleRequest.QueryTextFragments.TextOfConnections) Then
				// the use of additional Attributes increases the calculation time of the cached setting
				NumberOfConnections = StrOccurrenceCount(DataForRuleRequest.QueryTextFragments.TextOfConnections,
					"LEFT JOIN"); // @query-part
				ProcessedRowsCount = ProcessedRowsCount + 2*NumberOfConnections;
			EndIf;
			If StringRule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
				QueryText = StrReplace(QueryText, "&DataSourceCondition", "AliasOfSourceTable.DataSource = "
					+ FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(StringRule.BusinessOperation));
			Else
				QueryText = StrReplace(QueryText, "&DataSourceCondition", "AliasOfSourceTable.DataSource = "
					+ FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(StringRule.DataSource));
			EndIf;
			QueryText = StrReplace(QueryText, "&ConditionText",
				DataForRuleRequest.QueryTextFragments.ConditionText);
			If Not IsBlankString(DataForRuleRequest.QueryTextFragments.ConditionText) Then
				ConditionsNumber = StrLineCount(DataForRuleRequest.QueryTextFragments.ConditionText);
				ProcessedRowsCount = ProcessedRowsCount + ConditionsNumber;
			EndIf;
			CommonClientServer.SupplementStructure(ConfigureActualDataReceipt.QueryOptions,
				DataForRuleRequest.QueryOptions);
			BudgetFlowItemParameterName = "BudgetFlowItem" + TargetValueMonitoring.UniqueIDPerLine(
				StringRule.BudgetFlowItem.UUID());
			QueryText = StrReplace(QueryText, "BudgetFlowItemGUID", BudgetFlowItemParameterName);
			ConfigureActualDataReceipt.QueryOptions.Insert(BudgetFlowItemParameterName, StringRule.BudgetFlowItem);
			QueryText = StrReplace(QueryText, "&GUIDLimitRule",
				FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined));
			QueryText = StrReplace(QueryText, "&LimitationPeriod",
				FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined));
			
			If TextsOfRequestsToFactSourceAccordingToRule.Count() > 0 Then
				QueryText = StrReplace(QueryText, "INTO ActualDataOnDocument", ""); // @query-part
			EndIf;
			
			TextsOfRequestsToFactSourceAccordingToRule.Add(StrReplace(QueryText, "AliasOfSourceTable",
				TypesOfAccountingDataRules.TempTableName));
		
		EndDo;
	
	EndIf;
	
	If TypeOf(RulesForLimitsByTypeOfAnalytics) = Type("ValueTable") Then
		
		FrequencyOfLimitRules = Common.ObjectsAttributeValue(
			RulesForLimitsByTypeOfAnalytics.UnloadColumn("Rule"), "Periodicity");
		
		For Each StringRule In RulesForLimitsByTypeOfAnalytics Do
			
			ProcessedRowsCount = ProcessedRowsCount + 1;
			
			FillPropertyValues(TheStructureOfTheSearch, StringRule);
			TypesOfAccountingDataRules = TypesOfRuleAccountingData.FindRows(TheStructureOfTheSearch)[0];
			
			DataForRuleRequest = DataSourcesServer.DataForRequestToSourceOfFactAccordingToRule(StringRule,
				TypesOfAccountingDataRules.DCSSettings);
			
			NameOfAmountIndicator = "Sum";
			NameOfAmountIndicatorFact = "SumReal";
			QueryText = StrReplace(TemplateForRequestToSourceOfFactBasedOnRule, "&TextSumFact", "AliasOfSourceTable."
				+ NameOfAmountIndicatorFact);
			QueryText = StrReplace(QueryText, "&TextAmount", "AliasOfSourceTable." + NameOfAmountIndicator);
			QueryText = StrReplace(QueryText, "&TextOfDimensionsFields",
				DataForRuleRequest.QueryTextFragments.TextOfDimensionsFields);
			QueryText = StrReplace(QueryText, "&TextOfConnections",
				DataForRuleRequest.QueryTextFragments.TextOfConnections);
			If Not IsBlankString(DataForRuleRequest.QueryTextFragments.TextOfConnections) Then
				// the use of additional Attributes increases the calculation time of the cached setting
				NumberOfConnections = StrOccurrenceCount(DataForRuleRequest.QueryTextFragments.TextOfConnections,
					"LEFT JOIN"); // @query-part
				ProcessedRowsCount = ProcessedRowsCount + 2*NumberOfConnections;
			EndIf;
			QueryText = StrReplace(QueryText, "&ConditionText",
				FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(True));
			CommonClientServer.SupplementStructure(ConfigureActualDataReceipt.QueryOptions,
				DataForRuleRequest.QueryOptions);
			BudgetFlowItemParameterName = "BudgetFlowItem" + TargetValueMonitoring.UniqueIDPerLine(
				StringRule.BudgetFlowItem.UUID());
			QueryText = StrReplace(QueryText, "&DataSourceCondition",
				"AliasOfSourceTable.BudgetFlowItem = &BudgetFlowItemGUID");
			QueryText = StrReplace(QueryText, "BudgetFlowItemGUID", BudgetFlowItemParameterName);
			ConfigureActualDataReceipt.QueryOptions.Insert(BudgetFlowItemParameterName, StringRule.BudgetFlowItem);
			NameOfLimitRuleParameter = "LimitsRule" + TargetValueMonitoring.UniqueIDPerLine(
				StringRule.Rule.UUID());
			QueryText = StrReplace(QueryText, "GUIDLimitRule", NameOfLimitRuleParameter);
			ConfigureActualDataReceipt.QueryOptions.Insert(NameOfLimitRuleParameter, StringRule.Rule);
			TextLimitationPeriod = StringFunctionsClientServer.SubstituteParametersToString(
				"BEGINOFPERIOD(AliasOfSourceTable.Period, %1)", 
				FinancialReportingClientServerCached.PeriodicityByString(FrequencyOfLimitRules.Get(StringRule.Rule))); 
			QueryText = StrReplace(QueryText, "&LimitationPeriod", TextLimitationPeriod);
			
			If TextsOfRequestsToFactSourceAccordingToRule.Count() > 0 Then
				QueryText = StrReplace(QueryText, "INTO ActualDataOnDocument", ""); // @query-part
			EndIf;
			
			TextsOfRequestsToFactSourceAccordingToRule.Add(StrReplace(QueryText, "AliasOfSourceTable",
				TypesOfAccountingDataRules.TempTableName));
		
		EndDo;
		
	EndIf;
	
	ConfigureActualDataReceipt.QueryOptions.Insert("IDOfUnusedFinRecord",
		DocumentsPosting.IDOfUnusedFinRecord());
	
	QueryTextToFactSourceAccordingToRule = StrConcat(TextsOfRequestsToFactSourceAccordingToRule,
		TMCommonUse.QuerySeparatorInJoin()) + "
		|
		|INDEX BY
		|	BudgetFlowItem"; // @query-part
	QueriesTexts.Add(QueryTextToFactSourceAccordingToRule);
	
	ConfigureActualDataReceipt.QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	ConfigureActualDataReceipt.TemporaryTableNames = TypesOfRuleAccountingData.UnloadColumn("TempTableName");
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ProcessedRowsCount);
	
	Return ConfigureActualDataReceipt;

EndFunction

// Returns parameters for getting a fact to check the document for compliance with the budgeting limits.
//
// Parameters:
// 	DocumentAttributes - Structure - Request properties or report parameters:
// 	 *CheckDate   - Date - Date the limits were checked.
// 	 *LinkToApplication - DocumentRef.PaymentRequest - The application being reviewed.
// 	 *RequestCurrency   - CatalogRef.Currencies - Currency of the application or report.
// 	CurrentLimits - See CurrentLimits.
// 	FilterByRequest - Boolean - flag the need to set a selection on the application.
// 	AdditionalSelectionOfReportTranscript - Undefined - default.
// 	                                     - Structure - structure of additional report selection during decryption:
// 	 *UseFilter1 - Boolean - Flag for using selection. Required property.
// 	 *LimitsRule    - CatalogRef.BudgetingLimits
// 	 *SelectionByAnalystsReal - Array of Structure - array of selection elements based on fact analysts, if they are specified. Optional property:
// 	  **DimensionNameAnalyticsNumber - String - The name of the dimension or the name of the analytics by number. For example, "Analytics1".
// 	  **Value - Characteristic.BudgetFlowItemDimensions - the value of the selection.
// 	 *DecryptionByRegistrar - Boolean - Flag of the need for decryption by the registrar.
//
// Returns:
//	Structure - Parameters for obtaining the fact by items and the budget indicator. See DataSourcesServer.TemplateForGettingFactParameters.
//
Function ParametersForGettingFactForControllingLimits(DocumentAttributes, CurrentLimits, FilterByRequest, AdditionalSelectionOfReportTranscript = Undefined)
	
	LimitRules = CurrentLimits.LimitRules;
	
	Periodicity_ = LimitRules.Copy(, "Periodicity");
	Periodicity_.GroupBy("Periodicity");
	
	DimensionKinds = CurrentLimits.DimensionKinds.Copy(, "DimensionKind");
	DimensionKinds.GroupBy("DimensionKind");
	
	Dimensions = CurrentLimits.Dimensions.Copy(, "DimensionName");
	Dimensions.GroupBy("DimensionName");
	
	CheckDate = DocumentAttributes.VerificationDates[0].LimitDate;
	
	// Initialize the parameters for getting the fact
	FunctionResult = New Structure("FactGettingParameters, DataSources");
	// General parameters for obtaining actual data
	FactGettingParameters = New Structure;
	FactGettingParameters.Insert("ScenarioCurrency",    DocumentAttributes.Currency);
	FactGettingParameters.Insert("ActualDataLimit", CheckDate);
	FactGettingParameters.Insert("UpdateDate",  CheckDate);
	FactGettingParameters.Insert("BeginOfPeriod",     CheckDate); // Specified by expressions of data sources
	FactGettingParameters.Insert("EndOfPeriod",      CheckDate); // Specified by expressions of data sources
	FactGettingParameters.Insert("RatePeriod",       CheckDate); // Redefinition of the currency conversion date on the date of verification.
	FactGettingParameters.Insert("Scenario",          Catalogs.BudgetingScenarios.BudgetFulfillment);
	FactGettingParameters.Insert("Period", New StandardPeriod(CheckDate, CheckDate));
	FactGettingParameters.Insert("AdditionalFiltersForAnalytics", New Structure);
	FactGettingParameters.Insert("ByRegistrar",    False);
	
	Indicators = New Structure("Sum");
	FactGettingParameters.Insert("Indicators", Indicators);
	
	ColumnsOfDataTable_ = New Structure("Periodicity_, Dimensions, DimensionKinds");
	ColumnsOfDataTable_.Periodicity_ = Periodicity_.UnloadColumn("Periodicity");
	ColumnsOfDataTable_.Dimensions     = Dimensions.UnloadColumn("DimensionName");
	ColumnsOfDataTable_.DimensionKinds  = DimensionKinds.UnloadColumn("DimensionKind");
	FactGettingParameters.Insert("ColumnsOfDataTable_", ColumnsOfDataTable_);
	
	If ColumnsOfDataTable_.Dimensions.Find("Organization") <> Undefined Then
		ByCompanies = True;
	Else
		ByCompanies = False;
	EndIf;
	FactGettingParameters.Insert("ByCompanies", ByCompanies);
	
	If ColumnsOfDataTable_.Dimensions.Find("Department") <> Undefined Then
		ByBusinessUnits = True;
	Else
		ByBusinessUnits = False;
	EndIf;
	FactGettingParameters.Insert("ByBusinessUnits", ByBusinessUnits);
	
	FieldCompositionSettings = New Structure;
	FieldCompositionSettings.Insert("QuantityRequired", False);
	FieldCompositionSettings.Insert("AmountRequired", True);
	FieldCompositionSettings.Insert("AmountRequiredOpeningBalance", False);
	FieldCompositionSettings.Insert("AmountRequiredReceipt", True);
	FieldCompositionSettings.Insert("AmountRequiredExpense", False);
	
	FactGettingParameters.Insert("FieldCompositionSettings", FieldCompositionSettings);
	
	FunctionResult.FactGettingParameters = FactGettingParameters;
	
	// General parameters of data sources
	DataSources = New Array;
	
	GeneralDataSourceParameters = New Structure;
	GeneralDataSourceParameters.Insert("SourceType", Enums.BudgetingDataSourceTypes.Turnovers);
	GeneralDataSourceParameters.Insert("PeriodOfShift", Undefined);
	GeneralDataSourceParameters.Insert("OffsetFrequency", Enums.Periodicity.Year);
	GeneralDataSourceParameters.Insert("PrivilegedMode", True);
	GeneralDataSourceParameters.Insert("AssumesActualData", "NotAssumed");
	GeneralDataSourceParameters.Insert("AssumesBudgetExecution", "Assumed");
	GeneralDataSourceParameters.Insert("ThereAreOnLineRules", True);
	GeneralDataSourceParameters.Insert("ThereAreTargets_", False);
	
	GeneralDataSourceParameters.Insert("AdditionalSelection", New DataCompositionSettings);
	If FilterByRequest Then
		DataCompositionClientServer.AddFilter(
			GeneralDataSourceParameters.AdditionalSelection,
			"Recorder",
			DocumentAttributes.Document);
		FactGettingParameters.Insert("SelectionByRegistrarForAllFact",
			New Structure("ComparisonType, RightValue", DataCompositionComparisonType.Equal,
			DocumentAttributes.Document));
	ElsIf ValueIsFilled(DocumentAttributes.Document)
		And GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters") Then
		DataCompositionClientServer.AddFilter(
			GeneralDataSourceParameters.AdditionalSelection,
			"Recorder",
			DocumentAttributes.Document, DataCompositionComparisonType.NotEqual);
		FactGettingParameters.Insert("SelectionByRegistrarForAllFact",
			New Structure("ComparisonType, RightValue", DataCompositionComparisonType.NotEqual,
			DocumentAttributes.Document));
	EndIf;
	DataCompositionClientServer.AddFilter(
		GeneralDataSourceParameters.AdditionalSelection,
		"Scenario",
		Catalogs.BudgetingScenarios.BudgetFulfillment);
	
	If Not AdditionalSelectionOfReportTranscript = Undefined
		And AdditionalSelectionOfReportTranscript.UseFilter1 Then
		
		// If the selection is set by the registrar, then the current limits are necessarily obtained with the selection according to one limit rule.
		FactGettingParameters.ByRegistrar = AdditionalSelectionOfReportTranscript.DecryptionByRegistrar;
		
		If AdditionalSelectionOfReportTranscript.Property("SelectionByAnalystsReal")
			And Not FilterByRequest Then
			// The rules for obtaining the fact on the application must be fulfilled without additional selections of the transcript of the report,
			// because the selection according to the analysis of the transcript may not coincide with the analysis of the application
			SelectionsByAnalysts = AdditionalSelectionOfReportTranscript.SelectionByAnalystsReal;
			For Each FilterElement In SelectionsByAnalysts Do
				DataCompositionClientServer.AddFilter(
					GeneralDataSourceParameters.AdditionalSelection,
					FilterElement.DimensionNameAnalyticsNumber,
					FilterElement.Value);
			EndDo;
		EndIf;
	EndIf;
	
	// Unique parameters of data sources
	For Each UniqueAttribute In Periodicity_ Do 
		UniqueDataSourceParameters = New Structure("Id, Periodicity, Objects,
			|ExpressionOfGroupingPeriod, ExpressionStartOfPeriod, ExpressionEndOfPeriod");
		
		FillPropertyValues(UniqueDataSourceParameters, UniqueAttribute);
		UniqueDataSourceParameters.Id = "ID_" + DataSources.Count();
		
		PeriodicityName = Common.EnumerationValueName(UniqueAttribute.Periodicity);
		UniqueDataSourceParameters.ExpressionOfGroupingPeriod = StrTemplate("BEGINOFPERIOD(&BeginOfPeriod, %1)", PeriodicityName);
		UniqueDataSourceParameters.ExpressionStartOfPeriod      = StrTemplate("BEGINOFPERIOD(&BeginOfPeriod, %1)", PeriodicityName);
		UniqueDataSourceParameters.ExpressionEndOfPeriod       = StrTemplate("ENDOFPERIOD(&EndOfPeriod, %1)", PeriodicityName);
		
		If Periodicity_.Count() = 1 Then
			UniqueDataSourceParameters.Objects = LimitRules.UnloadColumn("BudgetFlowItem");
		Else
			SelectionOfLimitRules = New Structure("Periodicity");
			FillPropertyValues(SelectionOfLimitRules, UniqueAttribute);
			
			UniqueDataSourceParameters.Objects = LimitRules.Copy(SelectionOfLimitRules, "BudgetFlowItem").UnloadColumn("BudgetFlowItem");
		EndIf;
		UniqueDataSourceParameters.Objects = CommonClientServer.CollapseArray(
			UniqueDataSourceParameters.Objects);
		
		CommonClientServer.SupplementStructure(UniqueDataSourceParameters, GeneralDataSourceParameters, False);
		
		DataSources.Add(UniqueDataSourceParameters);
	EndDo;
	
	FunctionResult.DataSources = DataSources;
	
	Return FunctionResult;
	
EndFunction

// Returns limit settings based on budgeting data that are valid for the specified dates of verification.
// 
// Parameters:
//	Parameters - Structure - structure of parameters.
//
// Returns:
//  Undefined - if there are no limit settings
//	Structure - Structure - Limit settings.
// 
Function LimitSettingsForVerificationDates(Parameters) Export
	
	ValidityPeriodsByLimitDates = Parameters.VerificationDates.Copy(, "LimitDate"); // - ValueTable -
	ValidityPeriodsByLimitDates.GroupBy("LimitDate");
	ValidityPeriodsByLimitDates.Columns.Add("ValidOnDate", New TypeDescription("Date"));
	ValidityPeriodsByLimitDates.Columns.Add("ValidToDate", New TypeDescription("Date"));
	
	LimitSettingsByValidityPeriod = New Array;
	SettlementLimitDates = Parameters.VerificationDates.CopyColumns("LimitDate");
	
	ColumnNamesValidityPeriods = "ValidOnDate,ValidToDate";
	StructurePeriodOfValidity = New Structure(ColumnNamesValidityPeriods);
	
	Counter = 0;
	While Counter < ValidityPeriodsByLimitDates.Count() Do
		LimitDate = ValidityPeriodsByLimitDates[Counter];
		CacheValue = InformationRegisters.BudgetingLimitSettingsCache.GetCacheValue(
			LimitDate.LimitDate, Parameters.DocumentKind, Parameters.BusinessOperation);
		If CacheValue <> Undefined Then
			FillPropertyValues(StructurePeriodOfValidity, CacheValue);
			If ValidityPeriodsByLimitDates.FindRows(StructurePeriodOfValidity).Count() = 0 Then
				LimitSettingsByValidityPeriod.Add(CacheValue);
			EndIf;
			FillPropertyValues(LimitDate, CacheValue);
			Counter = Counter + 1;
		Else
			FillPropertyValues(SettlementLimitDates.Add(), LimitDate);
			ValidityPeriodsByLimitDates.Delete(Counter);
		EndIf;
	EndDo;
	
	LimitSettings = New Structure("LimitSettingsByValidityPeriod, ValidityPeriodsByLimitDates",
		LimitSettingsByValidityPeriod, ValidityPeriodsByLimitDates);
	
	If SettlementLimitDates.Count() = 0 Then
		Return LimitSettings;
	EndIf;
	
	ByRegisterOfLimits = RegisterOfBudgetingLimitsIsUsed();
	
	UseRulesForGettingFact = (Parameters.LimitedTransactions.Find(
		Enums.LimitedTransactions.FlowOfCash) <> Undefined);
	UseBDRLimitRules = (Parameters.LimitedTransactions.Find(Enums.LimitedTransactions.Expenses)
		<> Undefined);
	
	DateLimitRules = New Structure;
	DateLimitRules.Insert("LimitRules");
	DateLimitRules.Insert("ActualDataQueryRules_");
	DateLimitRules.Insert("HierarchyOfAnalystsByRules");
	DateLimitRules.Insert("PermissionLimitRequired", False);
	DateLimitRules.Insert("DimensionKinds");
	DateLimitRules.Insert("Dimensions");
	DateLimitRules.Insert("RuleScripts");
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("SettlementLimitDates", SettlementLimitDates);
	If UseRulesForGettingFact Then
		DateOfLimitsLine = Parameters.VerificationDates.Find(Enums.LimitedTransactions.FlowOfCash);
		Query.SetParameter("DateWhenFactRulesAreUpToDate", ?(DateOfLimitsLine = Undefined,
			Parameters.VerificationDates[0].LimitDate, DateOfLimitsLine.LimitDate));
	EndIf;
	Query.SetParameter("BusinessOperation", Parameters.BusinessOperation);
	Query.SetParameter("LimitedTransactions", Parameters.LimitedTransactions);
	Query.SetParameter("AccordingToCorrespondenceTable", GetFunctionalOption(
		"SettingUpRulesForObtainingFactsFromCorrespondingRegisters"));
	
	QueriesTexts = New Array;
	QueriesTexts.Add("
		|SELECT
		|	CAST(LimitDates.LimitDate AS DATE) AS LimitDate
		|INTO LimitDates
		|FROM
		|	&SettlementLimitDates AS LimitDates
		|
		|INDEX BY
		|	LimitDate");
	
	QueriesTexts.Add("
		|SELECT
		|	BudgetingModels.Ref AS Model,
		|	BudgetingModels.ValidOnDate AS ValidOnDate,
		|	BudgetingModels.ValidToDate AS ValidToDate,
		|	LimitDates.LimitDate AS LimitDate
		|INTO CurrentBudgetingModelsBasedOnLimitDates
		|FROM
		|	Catalog.BudgetingModels AS BudgetingModels
		|		INNER JOIN LimitDates AS LimitDates
		|		ON BudgetingModels.ValidOnDate <= LimitDates.LimitDate
		|			AND BudgetingModels.ValidToDate >= LimitDates.LimitDate
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Catalog.BudgetingLimits AS BudgetingLimits
		|			WHERE
		|				BudgetingLimits.Owner = BudgetingModels.Ref
		|				AND BudgetingLimits.LimitedTransaction IN (&LimitedTransactions))
		|
		|UNION ALL
		|
		|SELECT
		|	BudgetingModels.Ref,
		|	BudgetingModels.ValidOnDate,
		|	DATETIME(3999, 12, 31),
		|	LimitDates.LimitDate
		|FROM
		|	Catalog.BudgetingModels AS BudgetingModels
		|		INNER JOIN LimitDates AS LimitDates
		|		ON BudgetingModels.ValidOnDate <= LimitDates.LimitDate
		|			AND BudgetingModels.ValidToDate = DATETIME(1, 1, 1)
		|			AND BudgetingModels.Status = VALUE(Enum.BudgetingModelStatuses.Valid)
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Catalog.BudgetingLimits AS BudgetingLimits
		|			WHERE
		|				BudgetingLimits.Owner = BudgetingModels.Ref
		|				AND BudgetingLimits.LimitedTransaction IN (&LimitedTransactions))
		|
		|INDEX BY
		|	LimitDate");
	
	If Not FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts,
		"CurrentBudgetingModelsBasedOnLimitDates") Then
		Return LimitSettings;
	EndIf;
	
	QueriesTexts.Add("
		|SELECT
		|	MAX(CurrentBudgetingModelsBasedOnLimitDates.ValidOnDate) AS ValidOnDate,
		|	MIN(CurrentBudgetingModelsBasedOnLimitDates.ValidToDate) AS ValidToDate,
		|	CurrentBudgetingModelsBasedOnLimitDates.LimitDate AS LimitDate
		|INTO ValidityPeriodsByLimitDates
		|FROM
		|	CurrentBudgetingModelsBasedOnLimitDates AS CurrentBudgetingModelsBasedOnLimitDates
		|
		|GROUP BY
		|	CurrentBudgetingModelsBasedOnLimitDates.LimitDate
		|
		|INDEX BY
		|	LimitDate");
	
	QueriesTexts.Add("
		|SELECT DISTINCT
		|	CurrentBudgetingModelsBasedOnLimitDates.Model AS Model,
		|	ValidityPeriodsByLimitDates.ValidOnDate AS ValidOnDate,
		|	ValidityPeriodsByLimitDates.ValidToDate AS ValidToDate
		|INTO CurrentBudgetingModels
		|FROM
		|	CurrentBudgetingModelsBasedOnLimitDates AS CurrentBudgetingModelsBasedOnLimitDates
		|		INNER JOIN ValidityPeriodsByLimitDates AS ValidityPeriodsByLimitDates
		|		ON CurrentBudgetingModelsBasedOnLimitDates.LimitDate = ValidityPeriodsByLimitDates.LimitDate
		|
		|INDEX BY
		|	Model");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
		"CurrentBudgetingModelsBasedOnLimitDates");
	
	QueriesTexts.Add("
		|SELECT
		|	BudgetingLimits.Ref AS LimitsRule,
		|	BudgetingLimits.Description AS Description,
		|	BudgetingLimits.BudgetFlowOrBalanceItem AS BudgetFlowItem,
		|	BudgetingLimits.Scenario AS Scenario,
		|	BudgetingLimits.Periodicity AS Periodicity,
		|	BudgetingLimits.LimitType AS LimitType,
		|	BudgetingLimits.LimitedTransaction AS LimitedTransaction,
		|	CurrentBudgetingModels.ValidOnDate AS ValidOnDate,
		|	CurrentBudgetingModels.ValidToDate AS ValidToDate
		|INTO CurrentLimitRules
		|FROM
		|	Catalog.BudgetingLimits AS BudgetingLimits
		|		INNER JOIN CurrentBudgetingModels AS CurrentBudgetingModels
		|		ON BudgetingLimits.Owner = CurrentBudgetingModels.Model
		|		
		|WHERE
		|	NOT BudgetingLimits.IsFolder
		|	AND NOT BudgetingLimits.DeletionMark
		|	AND BudgetingLimits.LimitedTransaction IN (&LimitedTransactions)
		|
		|INDEX BY
		|	BudgetFlowItem,
		|	LimitsRule");
	
	If UseRulesForGettingFact Then
		
		If ValueIsFilled(Parameters.DocumentKind) Then
			ManagerOfDocument = Common.ObjectManagerByFullName(
				Common.MetadataObjectByID(Parameters.DocumentKind).FullName());
			QueriesTexts.Add(ManagerOfDocument.QueryTextDataSourcesOfRulesForObtainingFact());
		Else
			SubqueryTexts_ = New Array;
			If ByRegisterOfLimits Then
				ArrayOfDocumentNames = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
					DataSourcesCached.TypesOfDocumentsForControllingLimits(Enums.AccountingDataTypes.Cash), False);
			Else
				ArrayOfDocumentNames = New Array;
				ArrayOfDocumentNames.Add(Metadata.Documents.PaymentRequest.FullName());
				ArrayOfDocumentNames.Add(Metadata.Documents.ApplicationForBusinessTrip.FullName());
			EndIf;
			For Each DocumentName In ArrayOfDocumentNames Do
				ManagerOfDocument = Common.ObjectManagerByFullName(DocumentName);
				QueryText = ManagerOfDocument.QueryTextDataSourcesOfRulesForObtainingFact();
				If SubqueryTexts_.Count() > 0 Then
					QueryText = StrReplace(QueryText, "INTO DataSourcesOfRulesForObtainingFact", ""); // @query-part
				EndIf;
				SubqueryTexts_.Add(QueryText);
			EndDo;
			QueriesTexts.Add(StrConcat(SubqueryTexts_, TMCommonUse.QuerySeparatorInJoin(
				True)));
		EndIf;
		
		QueriesTexts.Add("
			|SELECT
			|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Rule,
			|	ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem AS BudgetFlowItem,
			|	ActualDataQueryRulesByBudgetFlowItems.DataSourceSection AS DataSourceSection,
			|	NOT DataSourcesOfRulesForObtainingFact.DataSource IS NULL AS ApplyRule
			|INTO CurrentRulesForObtainingFactOperationalAccounting
			|FROM
			|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
			|		LEFT JOIN DataSourcesOfRulesForObtainingFact AS DataSourcesOfRulesForObtainingFact
			|		ON ActualDataQueryRulesByBudgetFlowItems.DataSource = DataSourcesOfRulesForObtainingFact.DataSource
			|WHERE
			|	ActualDataQueryRulesByBudgetFlowItems.DataSourceSection = VALUE(Enum.SectionsOfBudgetingDataSources.OperationalAccounting)
			|	AND ActualDataQueryRulesByBudgetFlowItems.RuleType IN (VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData), VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillment))
			|	AND NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark
			|	AND ActualDataQueryRulesByBudgetFlowItems.ValidFrom <= &DateWhenFactRulesAreUpToDate
			|	AND (ActualDataQueryRulesByBudgetFlowItems.ValidTo >= &DateWhenFactRulesAreUpToDate
			|		OR ActualDataQueryRulesByBudgetFlowItems.ValidTo = DATETIME(1, 1, 1))
			|	AND TRUE IN
			|			(SELECT TOP 1
			|				TRUE
			|			FROM
			|				CurrentLimitRules AS CurrentLimitRules
			|			WHERE
			|				CurrentLimitRules.BudgetFlowItem = ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem)
			|
			|INDEX BY
			|	BudgetFlowItem,
			|	Rule");
		
		QueriesTexts.Add("
			|SELECT
			|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Rule,
			|	ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem AS BudgetFlowItem
			|FROM
			|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
			|WHERE
			|	ActualDataQueryRulesByBudgetFlowItems.DataSourceSection = VALUE(Enum.SectionsOfBudgetingDataSources.CustomQuery)
			|	AND ActualDataQueryRulesByBudgetFlowItems.RuleType IN (VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData), VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillment))
			|	AND NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark
			|	AND ActualDataQueryRulesByBudgetFlowItems.ValidFrom <= &DateWhenFactRulesAreUpToDate
			|	AND (ActualDataQueryRulesByBudgetFlowItems.ValidTo >= &DateWhenFactRulesAreUpToDate
			|		OR ActualDataQueryRulesByBudgetFlowItems.ValidTo = DATETIME(1, 1, 1))
			|	AND TRUE IN
			|			(SELECT TOP 1
			|				TRUE
			|			FROM
			|				CurrentLimitRules AS CurrentLimitRules
			|			WHERE
			|				CurrentLimitRules.BudgetFlowItem = ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem)");
			
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		QueriesTexts.Clear();
		Result = Query.Execute();
		ThereAreRulesWithArbitraryData = False;
		If Not Result.IsEmpty() Then
			OriginalTableOfRulesWithArbitraryData = Result.Unload();
			NewTableOfRulesWithArbitraryData = OriginalTableOfRulesWithArbitraryData.CopyColumns();
			NewTableOfRulesWithArbitraryData.Columns.Add("TypeOfAccountingDataExpense",
				New TypeDescription("EnumRef.AccountingDataTypes"));
			NewTableOfRulesWithArbitraryData.Columns.Add("TypeOfAccountingDataReceipt",
				New TypeDescription("EnumRef.AccountingDataTypes"));
			For Each RuleRow In OriginalTableOfRulesWithArbitraryData Do
				TypesOfAccountingDataRules = DataSourcesCached.TypesOfAccountingDataRulesWithArbitraryData(RuleRow.Rule);
				For Each ReceiptExpenseRules In TypesOfAccountingDataRules Do
					NewRow = NewTableOfRulesWithArbitraryData.Add();
					FillPropertyValues(NewRow, RuleRow);
					FillPropertyValues(NewRow, ReceiptExpenseRules);
				EndDo;
			EndDo;
			
			If NewTableOfRulesWithArbitraryData.Count() > 0 Then
				
				ThereAreRulesWithArbitraryData = True;
				
				QueriesTexts.Add("
					|SELECT
					|	CAST(RulesWithArbitraryData.Rule AS Catalog.ActualDataQueryRulesByBudgetFlowItems) AS Rule,
					|	CAST(RulesWithArbitraryData.BudgetFlowItem AS Catalog.BudgetFlowItems) AS BudgetFlowItem,
					|	CAST(RulesWithArbitraryData.TypeOfAccountingDataExpense AS Enum.AccountingDataTypes) AS Expense,
					|	CAST(RulesWithArbitraryData.TypeOfAccountingDataReceipt AS Enum.AccountingDataTypes) AS Receipt
					|INTO RulesWithArbitraryData
					|FROM
					|	&RulesWithArbitraryData AS RulesWithArbitraryData");
				Query.SetParameter("RulesWithArbitraryData", NewTableOfRulesWithArbitraryData);
				
				QueriesTexts.Add("
					|SELECT
					|	RulesWithArbitraryData.Rule AS Rule,
					|	RulesWithArbitraryData.BudgetFlowItem AS BudgetFlowItem,
					|	VALUE(Enum.SectionsOfBudgetingDataSources.CustomQuery) AS DataSourceSection,
					|	NOT DataSourcesOfRulesForObtainingFact.Expense IS NULL AS ApplyRule
					|INTO CurrentRulesForGettingFactsArbitraryData
					|FROM
					|	RulesWithArbitraryData AS RulesWithArbitraryData
					|		LEFT JOIN DataSourcesOfRulesForObtainingFact AS DataSourcesOfRulesForObtainingFact
					|		ON RulesWithArbitraryData.Expense = DataSourcesOfRulesForObtainingFact.Expense
					|			AND RulesWithArbitraryData.Receipt = DataSourcesOfRulesForObtainingFact.Receipt");
				
				FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
					"RulesWithArbitraryData");
				
			EndIf;
			
		EndIf;
		
		SubqueryTexts_ = New Array;
		SubqueryTexts_.Add("
			|SELECT
			|	CurrentRulesForObtainingFactOperationalAccounting.Rule AS Rule,
			|	CurrentRulesForObtainingFactOperationalAccounting.BudgetFlowItem AS BudgetFlowItem,
			|	CurrentRulesForObtainingFactOperationalAccounting.DataSourceSection AS DataSourceSection,
			|	CurrentRulesForObtainingFactOperationalAccounting.ApplyRule AS ApplyRule
			|INTO CurrentRulesForObtainingFact
			|FROM
			|	CurrentRulesForObtainingFactOperationalAccounting AS CurrentRulesForObtainingFactOperationalAccounting");
		
		If ThereAreRulesWithArbitraryData Then
			SubqueryTexts_.Add("
				|SELECT
				|	CurrentRulesForGettingFactsArbitraryData.Rule,
				|	CurrentRulesForGettingFactsArbitraryData.BudgetFlowItem,
				|	CurrentRulesForGettingFactsArbitraryData.DataSourceSection,
				|	CurrentRulesForGettingFactsArbitraryData.ApplyRule
				|FROM
				|	CurrentRulesForGettingFactsArbitraryData AS CurrentRulesForGettingFactsArbitraryData");
		
		EndIf;
		
		QueriesTexts.Add(StrConcat(SubqueryTexts_, TMCommonUse.QuerySeparatorInJoin())
			+ Chars.LF + "INDEX BY BudgetFlowItem, Rule");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
			"CurrentRulesForObtainingFactOperationalAccounting");
		If ThereAreRulesWithArbitraryData Then
			FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
				"CurrentRulesForGettingFactsArbitraryData");
		EndIf;
		
		If Not FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts,
			"CurrentRulesForObtainingFact") Then
			Return LimitSettings;
		EndIf;
		
	Else
		
		If Not FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts,
			"CurrentLimitRules") Then
			Return LimitSettings;
		EndIf;
	
	EndIf;
	
	QueriesTexts.Add("
		|SELECT TOP 1
		|	CurrentLimitRules.LimitsRule AS LimitsRule
		|FROM
		|	CurrentLimitRules AS CurrentLimitRules
		|WHERE
		|	CurrentLimitRules.LimitType = VALUE(Enum.TypesOfCashExpenseLimit.AllowingWithinLimit)
		|	AND CurrentLimitRules.LimitedTransaction = VALUE(Enum.LimitedTransactions.FlowOfCash)");
	
	QueriesTexts.Add("
		|SELECT
		|	ValidityPeriodsByLimitDates.LimitDate AS LimitDate,
		|	ValidityPeriodsByLimitDates.ValidOnDate AS ValidOnDate,
		|	ValidityPeriodsByLimitDates.ValidToDate AS ValidToDate
		|FROM
		|	ValidityPeriodsByLimitDates AS ValidityPeriodsByLimitDates");
	
	IndexOffset = 0;
	
	If UseRulesForGettingFact Then
	
		QueriesTexts.Add("
			|SELECT
			|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Rule,
			|	ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem AS BudgetFlowItem,
			|	ActualDataQueryRulesByBudgetFlowItems.DataSourceSection AS DataSourceSection,
			|	ActualDataQueryRulesByBudgetFlowItems.DataSource AS DataSource,
			|	CAST(ActualDataQueryRulesByBudgetFlowItems.DataSource AS Catalog.BusinessTransactionsSettings).BusinessOperation AS BusinessOperation,
			|	CAST(ActualDataQueryRulesByBudgetFlowItems.DataSource AS Catalog.BusinessTransactionsSettings).Receipt AS TypeOfAccountingDataReceipt,
			|	CAST(ActualDataQueryRulesByBudgetFlowItems.DataSource AS Catalog.BusinessTransactionsSettings).Expense AS TypeOfAccountingDataExpense,
			|	ActualDataQueryRulesByBudgetFlowItems.HashOfDataCompositionSchema AS HashOfDataCompositionSchema,
			|	ValidityPeriodsByLimitDates.ValidOnDate AS ValidOnDate,
			|	ValidityPeriodsByLimitDates.ValidToDate AS ValidToDate
			|FROM
			|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
			|		INNER JOIN CurrentRulesForObtainingFact AS CurrentRulesForObtainingFact
			|			INNER JOIN ValidityPeriodsByLimitDates AS ValidityPeriodsByLimitDates
			|			ON (ValidityPeriodsByLimitDates.LimitDate = &DateWhenFactRulesAreUpToDate)
			|		ON ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem = CurrentRulesForObtainingFact.BudgetFlowItem
			|			AND ActualDataQueryRulesByBudgetFlowItems.Ref = CurrentRulesForObtainingFact.Rule
			|			AND (CurrentRulesForObtainingFact.ApplyRule)");
		
		SubqueryTexts_ = New Array;
		SubqueryTexts_.Add("
			|SELECT
			|	CurrentLimitRules.LimitsRule AS LimitsRule,
			|	CurrentLimitRules.Description AS Description,
			|	CurrentLimitRules.BudgetFlowItem AS BudgetFlowItem,
			|	CurrentLimitRules.Scenario AS Scenario,
			|	CurrentLimitRules.Periodicity AS Periodicity,
			|	CurrentLimitRules.LimitType AS LimitType,
			|	CurrentLimitRules.LimitedTransaction AS LimitedTransaction,
			|	CurrentLimitRules.ValidOnDate AS ValidOnDate,
			|	CurrentLimitRules.ValidToDate AS ValidToDate
			|FROM
			|	CurrentLimitRules AS CurrentLimitRules
			|WHERE
			|	CurrentLimitRules.LimitedTransaction = VALUE(Enum.LimitedTransactions.FlowOfCash)
			|	AND TRUE IN
			|			(SELECT TOP 1
			|				TRUE
			|			FROM
			|				CurrentRulesForObtainingFact AS CurrentRulesForObtainingFact
			|			WHERE
			|				CurrentRulesForObtainingFact.BudgetFlowItem = CurrentLimitRules.BudgetFlowItem
			|				AND (CurrentRulesForObtainingFact.ApplyRule))");
		If UseBDRLimitRules Then
			SubqueryTexts_.Add("
				|SELECT
				|	CurrentLimitRules.LimitsRule,
				|	CurrentLimitRules.Description,
				|	CurrentLimitRules.BudgetFlowItem,
				|	CurrentLimitRules.Scenario,
				|	CurrentLimitRules.Periodicity,
				|	CurrentLimitRules.LimitType,
				|	CurrentLimitRules.LimitedTransaction,
				|	CurrentLimitRules.ValidOnDate,
				|	CurrentLimitRules.ValidToDate
				|FROM
				|	CurrentLimitRules AS CurrentLimitRules
				|WHERE
				|	CurrentLimitRules.LimitedTransaction = VALUE(Enum.LimitedTransactions.Expenses)");
		EndIf;
		
		QueriesTexts.Add(StrConcat(SubqueryTexts_, TMCommonUse.QuerySeparatorInJoin()));
	
	Else
		
		QueriesTexts.Add("
			|SELECT
			|	CurrentLimitRules.LimitsRule AS LimitsRule,
			|	CurrentLimitRules.Description AS Description,
			|	CurrentLimitRules.BudgetFlowItem AS BudgetFlowItem,
			|	CurrentLimitRules.Scenario AS Scenario,
			|	CurrentLimitRules.Periodicity AS Periodicity,
			|	CurrentLimitRules.LimitType AS LimitType,
			|	CurrentLimitRules.LimitedTransaction AS LimitedTransaction,
			|	CurrentLimitRules.ValidOnDate AS ValidOnDate,
			|	CurrentLimitRules.ValidToDate AS ValidToDate
			|FROM
			|	CurrentLimitRules AS CurrentLimitRules
			|WHERE
			|	CurrentLimitRules.LimitedTransaction = VALUE(Enum.LimitedTransactions.Expenses)");
		
		IndexOffset = 1;
		
	EndIf;
	
	If Not ByRegisterOfLimits Then
		
		QueriesTexts.Add("
			|SELECT
			|	CurrentLimitRules.LimitsRule AS LimitsRule,
			|	CurrentLimitRules.BudgetFlowItem AS BudgetFlowItem,
			|	RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionKind AS DimensionKind
			|FROM
			|	CurrentLimitRules AS CurrentLimitRules
			|		INNER JOIN Catalog.BudgetingLimits.DimensionsHierarchy AS RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics
			|		ON CurrentLimitRules.LimitsRule = RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.Ref
			|			AND (RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionKind <> VALUE(ChartOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef))
			|			AND (RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.Used)");
		
		QueriesTexts.Add("
			|SELECT DISTINCT
			|	CurrentLimitRules.LimitsRule AS LimitsRule,
			|	CurrentLimitRules.BudgetFlowItem AS BudgetFlowItem,
			|	RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionName AS DimensionName
			|FROM
			|	CurrentLimitRules AS CurrentLimitRules
			|		INNER JOIN Catalog.BudgetingLimits.DimensionsHierarchy AS RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics
			|		ON CurrentLimitRules.LimitsRule = RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.Ref
			|			AND (RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionName <> """")
			|			AND (RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.Used)");
			
	ElsIf UseBDRLimitRules Then
		
		QueryText = "
			|SELECT
			|	CurrentLimitRules.LimitsRule AS Rule,
			|	CurrentLimitRules.BudgetFlowItem AS BudgetFlowItem,
			|	&TextAnalyst_,
			|	&TextOfAnalystSFillInExpressions,
			|	&TextOfFillingInSpecifiedValueAnalyst,
			|	&TextAnalyst_2,
			|	VALUE(Enum.LimitedTransactions.Expenses) AS LimitedTransaction,
			|	VALUE(Enum.AccountingDataTypes.IncomeExpenses) AS TypeOfAccountingDataReceipt,
			|	VALUE(Enum.AccountingDataTypes.Products) AS TypeOfAccountingDataExpense,
			|	UNDEFINED AS HashOfDataCompositionSchema
			|FROM
			|	CurrentLimitRules AS CurrentLimitRules
			|		LEFT JOIN Catalog.BudgetingLimits.DimensionsHierarchy AS RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics
			|		ON CurrentLimitRules.LimitsRule = RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.Ref
			|			AND (RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionKind <> VALUE(ChartOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef))
			|			AND (RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.Used)
			|WHERE
			|	CurrentLimitRules.LimitedTransaction = VALUE(Enum.LimitedTransactions.Expenses)
			|
			|GROUP BY
			|	CurrentLimitRules.LimitsRule,
			|	CurrentLimitRules.BudgetFlowItem";
		TextAnalyst_ = "";
		TextOfAnalystSFillInExpressions = "";
		TextOfFillingInSpecifiedValueAnalyst = "";
		TextAnalyst_2 = "";
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			TextAnalyst_ = TextAnalyst_ + ?(TextAnalyst_ = "", "", "," + Chars.LF + Chars.Tab)
				+ StringFunctionsClientServer.SubstituteParametersToString("MAX(CASE
				|	WHEN RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionKind = CurrentLimitRules.BudgetFlowItem.DimensionKind%1
				|		THEN RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionKind
				|	ELSE UNDEFINED
				|END) AS DimensionKind%1", DimensionNumber);
			TextOfAnalystSFillInExpressions = TextOfAnalystSFillInExpressions + ?(TextOfAnalystSFillInExpressions
				= "", "", "," + Chars.LF + Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString("MAX(CASE
				|	WHEN RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionKind = CurrentLimitRules.BudgetFlowItem.DimensionKind%1
				|		THEN CAST(RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionPopulationExpression AS STRING(1000))
				|	ELSE """"
				|END) AS DimensionPopulationExpression%1", DimensionNumber);
			TextOfFillingInSpecifiedValueAnalyst = TextOfFillingInSpecifiedValueAnalyst + ?(
				TextOfFillingInSpecifiedValueAnalyst = "", "", "," + Chars.LF + Chars.Tab)
				+ StringFunctionsClientServer.SubstituteParametersToString("MAX(CASE
				|	WHEN RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionKind = CurrentLimitRules.BudgetFlowItem.DimensionKind%1
				|		THEN RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.FillInAnalyticsWithSpecifiedValue
				|	ELSE FALSE
				|END) AS FillInAnalyticsWithSpecifiedValue%1", DimensionNumber);
			TextAnalyst_2 = TextAnalyst_2 + ?(TextAnalyst_2 = "", "", "," + Chars.LF
				+ Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString("MAX(CASE
				|	WHEN RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionKind = CurrentLimitRules.BudgetFlowItem.DimensionKind%1
				|		THEN RulesForLimitsBasedOnBudgetingDataHierarchyOfAnalytics.DimensionValue
				|	ELSE UNDEFINED
				|END) AS DimensionValue%1", DimensionNumber);
		EndDo;
		QueryText = StrReplace(QueryText, "&TextAnalyst_", TextAnalyst_);
		QueryText = StrReplace(QueryText, "&TextOfAnalystSFillInExpressions", TextOfAnalystSFillInExpressions);
		QueryText = StrReplace(QueryText, "&TextOfFillingInSpecifiedValueAnalyst",
			TextOfFillingInSpecifiedValueAnalyst);
		QueryText = StrReplace(QueryText, "&TextAnalyst_2", TextAnalyst_2);
		QueriesTexts.Add(QueryText);
		
	EndIf;
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	QueryResult = Query.ExecuteBatch();
	
	ValidityPeriodsForSettlementLimitDates = QueryResult[1].Unload();
	TMCommonUse.AddRowsToTable(ValidityPeriodsByLimitDates, ValidityPeriodsForSettlementLimitDates);
	ActionPeriods = ValidityPeriodsForSettlementLimitDates.Copy(, ColumnNamesValidityPeriods);
	ActionPeriods.GroupBy(ColumnNamesValidityPeriods);
	MultipleValidityPeriods = (ActionPeriods.Count() > 1);
	
	LimitRules = QueryResult[3-IndexOffset].Unload();
	If MultipleValidityPeriods Then
		LimitRules.Indexes.Add(ColumnNamesValidityPeriods);
	EndIf;
	
	ActualDataQueryRules_ = Undefined;
	If UseRulesForGettingFact Then
		ActualDataQueryRules_ = QueryResult[2].Unload();
		ActualDataQueryRules_.Columns.Add("DataSourceObjectType");
		ActualDataQueryRules_.FillValues(Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"), "DataSourceObjectType");
		If MultipleValidityPeriods Then
			ActualDataQueryRules_.Indexes.Add(ColumnNamesValidityPeriods);
		EndIf;
	EndIf;
	
	PermissionLimitRequired = Not QueryResult[0].IsEmpty();
	If Not ByRegisterOfLimits Then
		DimensionKinds = QueryResult[4].Unload();
		Dimensions = QueryResult[5].Unload();
	ElsIf UseBDRLimitRules Then
		DimensionKinds = QueryResult[4-IndexOffset].Unload();
	EndIf;
	
	For Each ActionPeriod In ActionPeriods Do
	
		RuleScripts = New Map;
		
		If MultipleValidityPeriods Then
			FillPropertyValues(StructurePeriodOfValidity, ActionPeriod);
			RulesForLimitsByValidityPeriod = LimitRules.Copy(StructurePeriodOfValidity);
		Else
			RulesForLimitsByValidityPeriod = LimitRules;
		EndIf;
		
		HierarchyOfAnalystsByRules = Catalogs.BudgetingLimits.HierarchyOfAnalyticsByRulesWithSourceColumns(
			RulesForLimitsByValidityPeriod.UnloadColumn("LimitsRule"));
		For Each RuleRow In RulesForLimitsByValidityPeriod Do
			HierarchyOfRuleAnalysts = HierarchyOfAnalystsByRules.Get(RuleRow.LimitsRule);
			HierarchyOfRuleAnalysts.Columns.Add("ZoomRatio");
			RowsInHierarchy = HierarchyOfRuleAnalysts.Count();
			For Each RowOfAnalyticsHierarchy In HierarchyOfRuleAnalysts Do
				// The coefficient of influence of analytics (measurement) is determined taking into account the hierarchy.
				// The smaller the line number, the higher the coefficient, the higher the priority of analytics (measurement).
				AnalyticsCoefficient = ?(RowOfAnalyticsHierarchy.Used, 1, 0)
					* Pow(10, RowsInHierarchy - RowOfAnalyticsHierarchy.NumberInHierarchy);
				RowOfAnalyticsHierarchy.ZoomRatio = AnalyticsCoefficient;
			EndDo;
			HierarchyOfAnalystsByRules.Insert(RuleRow.LimitsRule, HierarchyOfRuleAnalysts);
			
			RuleScripts.Insert(RuleRow.LimitsRule, RuleRow.Scenario);
		EndDo;
		
		RulesForLimitsWithAdditionalData = DataOfAdditionalFieldsOfRulesLimits(RulesForLimitsByValidityPeriod, HierarchyOfAnalystsByRules);
		
		RulesForLimitsForValidityPeriod = Common.CopyRecursive(DateLimitRules);
		If UseRulesForGettingFact And MultipleValidityPeriods Then
			RulesForLimitsForValidityPeriod.ActualDataQueryRules_ = ActualDataQueryRules_.Copy(StructurePeriodOfValidity);
		Else
			RulesForLimitsForValidityPeriod.ActualDataQueryRules_ = ActualDataQueryRules_;
		EndIf;
		RulesForLimitsForValidityPeriod.LimitRules = RulesForLimitsWithAdditionalData;
		RulesForLimitsForValidityPeriod.HierarchyOfAnalystsByRules = HierarchyOfAnalystsByRules;
		RulesForLimitsForValidityPeriod.PermissionLimitRequired = PermissionLimitRequired;
		RulesForLimitsForValidityPeriod.RuleScripts = RuleScripts;
		If Not ByRegisterOfLimits Then
			RulesForLimitsForValidityPeriod.DimensionKinds = DimensionKinds;
			RulesForLimitsForValidityPeriod.Dimensions = Dimensions;
		ElsIf UseBDRLimitRules Then
			If MultipleValidityPeriods Then
				RulesForLimitsForValidityPeriod.DimensionKinds = DimensionKinds.CopyColumns(); // - ValueTable -
				For Each TableRow In DimensionKinds Do
					If RuleScripts.Get(TableRow.Rule) <> Undefined Then
						NewRow = RulesForLimitsForValidityPeriod.DimensionKinds.Add();
						FillPropertyValues(NewRow, TableRow);
					EndIf;
				EndDo;
			Else
				RulesForLimitsForValidityPeriod.DimensionKinds = DimensionKinds;
			EndIf;
		EndIf;
	
		DateLimitSettings = New Structure("ConfigureActualDataReceipt, ConfigureLimitRules");
		If ByRegisterOfLimits And ValueIsFilled(Parameters.DocumentKind) Then
			DateLimitSettings.ConfigureActualDataReceipt = SettingUpReceiptOfFactOnDocumentOnDate(
				Parameters.DocumentKind, RulesForLimitsForValidityPeriod.ActualDataQueryRules_,
				RulesForLimitsForValidityPeriod.DimensionKinds);
		EndIf;
		DateLimitSettings.ConfigureLimitRules = RulesForLimitsForValidityPeriod;
		InformationRegisters.BudgetingLimitSettingsCache.SetCacheValue(
			ActionPeriod.ValidOnDate, ActionPeriod.ValidToDate, Parameters.DocumentKind,
			Parameters.BusinessOperation, DateLimitSettings);
		
		DateLimitSettings.Insert("ValidOnDate", ActionPeriod.ValidOnDate);
		DateLimitSettings.Insert("ValidToDate", ActionPeriod.ValidToDate);
		LimitSettingsByValidityPeriod.Add(DateLimitSettings);
	EndDo;
	
	Return LimitSettings;
	
EndFunction

Procedure AddRequestToReceiveFactByValidityPeriod(QueriesTexts, ConfigureActualDataReceipt, ValidOnDate,
	ValidToDate, LimitDates)
	
	StructurePeriodOfValidity = New Structure("ValidOnDate, ValidToDate", ValidOnDate, ValidToDate);
	
	HashOfValidityPeriod = Common.CheckSumString(StructurePeriodOfValidity);
	For Each TempTableName In ConfigureActualDataReceipt.TemporaryTableNames Do
		ConfigureActualDataReceipt.QueryText = StrReplace(ConfigureActualDataReceipt.QueryText, TempTableName,
			TempTableName + HashOfValidityPeriod);
	EndDo;
	NameOfTempTableOfFact = "ActualDataOnDocument" + HashOfValidityPeriod;
	ConfigureActualDataReceipt.QueryText = StrReplace(ConfigureActualDataReceipt.QueryText,
		"ActualDataOnDocument", NameOfTempTableOfFact);
	
	DatesOfLimitsByValidityPeriod = LimitDates.FindRows(StructurePeriodOfValidity);
	MinimumDateLimits = DatesOfLimitsByValidityPeriod[0].LimitDate;
	MaximumDateLimits = DatesOfLimitsByValidityPeriod[DatesOfLimitsByValidityPeriod.UBound()].LimitDate;
	ConfigureActualDataReceipt.QueryText = StrReplace(ConfigureActualDataReceipt.QueryText, "&BeginOfPeriod",
		FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(MinimumDateLimits));
	ConfigureActualDataReceipt.QueryText = StrReplace(ConfigureActualDataReceipt.QueryText, "&EndOfPeriod",
		FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(MaximumDateLimits));
	
	QueriesTexts.Add(ConfigureActualDataReceipt.QueryText);
	
	For Each TempTableName In ConfigureActualDataReceipt.TemporaryTableNames Do
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
			TempTableName + HashOfValidityPeriod);
	EndDo;
	ConfigureActualDataReceipt.TemporaryTableNames.Clear();
	ConfigureActualDataReceipt.TemporaryTableNames.Add(NameOfTempTableOfFact);
	
EndProcedure

// Returns conditions for checking the request for compliance with the budgeting limits.
//
// Parameters:
//  Parameters - Structure - parameters for calculating current limit rules:
//   *CheckDate - Date - the date on which the status of limits is checked.
//   *DocumentKind - CatalogRef.MetadataObjectIDs - the type of document that limit rules are calculated from.
//   *BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document
//	FilterByBudgetItems - Undefined, Array of CatalogRef.BudgetFlowItems - selection of budget limit settings.
//	InvertSelection - Boolean - sign the application of selection Otrabotanogo the condition is Not.
//	SelectionAccordingToLimitRules - Array of CatalogRef.BudgetingLimits - Additional
//					non-invertible selection according to the rules of limits. It is used when decrypting a report on limits.
//					Undefined. The default value.
//
// Returns:
//	Structure - parameters for checking the application for compliance with budgeting limits:
//		*LimitRules - See LimitsByBudgetingDataServer.LimitSettingsForVerificationDates
//		*ActualDataQueryRules_ - ValueTable - See Catalogs.Rules for receiving the actual cost of the budgets.Templates.Fact Receipt rulesreferences
//		*HierarchyOfAnalystsByRules - Map of KeyAndValue - the structure of the hierarchy of analysts according to the rules of limits.
//		*PermissionLimitRequired - Boolean - True if control is required by any permissive limit
//		*DimensionKinds - ValueTable
//		*Dimensions - ValueTable
//		*RuleScripts - Map of KeyAndValue - compliance of the limit rule and its scenario
//
Function CurrentLimits(Parameters, FilterByBudgetItems = Undefined, InvertSelection = False, SelectionAccordingToLimitRules = Undefined)
	
	CurrentLimits = New Structure;
	CurrentLimits.Insert("LimitRules");
	CurrentLimits.Insert("ActualDataQueryRules_");
	CurrentLimits.Insert("HierarchyOfAnalystsByRules");
	CurrentLimits.Insert("PermissionLimitRequired", False);
	CurrentLimits.Insert("DimensionKinds");
	CurrentLimits.Insert("Dimensions");
	CurrentLimits.Insert("RuleScripts");
	ByRegisterOfLimits = RegisterOfBudgetingLimitsIsUsed();
	If ByRegisterOfLimits Then
		CurrentLimits.Insert("ConfigureActualDataReceipt");
	EndIf;
	
	DatesLimitSettings = LimitSettingsForVerificationDates(Parameters);
	If DatesLimitSettings.LimitSettingsByValidityPeriod.Count() = 0 Then
		Return CurrentLimits;
	EndIf;
	
	QueriesTexts = New Array;
	
	For Each SettingLimitsByValidityPeriod In DatesLimitSettings.LimitSettingsByValidityPeriod Do
		If CurrentLimits.LimitRules = Undefined Then
			FillPropertyValues(CurrentLimits, SettingLimitsByValidityPeriod);
			FillPropertyValues(CurrentLimits, SettingLimitsByValidityPeriod.ConfigureLimitRules);
			If DatesLimitSettings.LimitSettingsByValidityPeriod.Count() > 1 Then
				AddRequestToReceiveFactByValidityPeriod(QueriesTexts,
					SettingLimitsByValidityPeriod.ConfigureActualDataReceipt,
					SettingLimitsByValidityPeriod.ValidOnDate, SettingLimitsByValidityPeriod.ValidToDate,
					DatesLimitSettings.ValidityPeriodsByLimitDates);
			EndIf;
		Else
			// Setting Up The Fact Receipt
			AddRequestToReceiveFactByValidityPeriod(QueriesTexts,
				SettingLimitsByValidityPeriod.ConfigureActualDataReceipt,
				SettingLimitsByValidityPeriod.ValidOnDate, SettingLimitsByValidityPeriod.ValidToDate,
				DatesLimitSettings.ValidityPeriodsByLimitDates);
			CommonClientServer.SupplementStructure(CurrentLimits.ConfigureActualDataReceipt.QueryOptions,
				SettingLimitsByValidityPeriod.ConfigureActualDataReceipt.QueryOptions, False);
			CommonClientServer.SupplementArray(
				CurrentLimits.ConfigureActualDataReceipt.TemporaryTableNames,
				SettingLimitsByValidityPeriod.ConfigureActualDataReceipt.TemporaryTableNames);
			
			// Setting Up Limit Rules
			ConfigureLimitRules = SettingLimitsByValidityPeriod.ConfigureLimitRules;
			TMCommonUse.AddRowsToTable(CurrentLimits.LimitRules,
				ConfigureLimitRules.LimitRules);
			If TypeOf(ConfigureLimitRules.ActualDataQueryRules_) = Type("ValueTable") Then
				If CurrentLimits.ActualDataQueryRules_ = Undefined Then
					CurrentLimits.ActualDataQueryRules_ = ConfigureLimitRules.ActualDataQueryRules_.Copy();
				Else
					TMCommonUse.AddRowsToTable(CurrentLimits.ActualDataQueryRules_,
						ConfigureLimitRules.ActualDataQueryRules_);
				EndIf;
			EndIf;
			CommonClientServer.SupplementMap(CurrentLimits.HierarchyOfAnalystsByRules,
				ConfigureLimitRules.HierarchyOfAnalystsByRules, False);
			If Not CurrentLimits.PermissionLimitRequired Then
				CurrentLimits.PermissionLimitRequired = ConfigureLimitRules.PermissionLimitRequired;
			EndIf;
			If TypeOf(ConfigureLimitRules.DimensionKinds) = Type("ValueTable") Then
				If CurrentLimits.DimensionKinds = Undefined Then
					CurrentLimits.DimensionKinds = ConfigureLimitRules.DimensionKinds.Copy();
				Else 
					For Each TableRow In ConfigureLimitRules.DimensionKinds Do
						If CurrentLimits.RuleScripts.Get(TableRow.Rule) = Undefined Then
							NewRow = CurrentLimits.DimensionKinds.Add();
							FillPropertyValues(NewRow, TableRow);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			CommonClientServer.SupplementMap(CurrentLimits.RuleScripts,
				ConfigureLimitRules.RuleScripts, False);
		EndIf;
	EndDo;
	
	If QueriesTexts.Count() > 0 Then
		TemporaryTableNames = CurrentLimits.ConfigureActualDataReceipt.TemporaryTableNames;
		TemplateSubqueryText = "
			|SELECT
			|	*
			|INTO ActualDataOnDocument
			|FROM
			|	FactTableAlias AS FactTableAlias";
		SubqueryTexts_ = New Array;
		For Each TempTableName In TemporaryTableNames Do
			SubqueryText = ?(TemporaryTableNames.Find(TempTableName) = 0, TemplateSubqueryText,
				StrReplace(TemplateSubqueryText, "INTO ActualDataOnDocument", "")); // @query-part
			SubqueryTexts_.Add(StrReplace(SubqueryText, "FactTableAlias", TempTableName));
		EndDo;
		QueriesTexts.Add(StrConcat(SubqueryTexts_, TMCommonUse.QuerySeparatorInJoin())
			+ Chars.LF + "INDEX BY BudgetFlowItem, LimitsRule, LimitationPeriod"); // @query-part
		For Each TempTableName In TemporaryTableNames Do
			FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
				TempTableName);
		EndDo;
		TemporaryTableNames.Clear();
		CurrentLimits.ConfigureActualDataReceipt.QueryText = StrConcat(QueriesTexts,
			Common.QueryBatchSeparator());
	EndIf;
	
	StructurePeriodOfValidity = New Structure("ValidOnDate, ValidToDate");
	
	NamesOfRuleLimitColumns = New Array;
	For Each Column In CurrentLimits.LimitRules.Columns Do // - ValueTableColumn -
		If Not StructurePeriodOfValidity.Property(Column.Name) Then
			NamesOfRuleLimitColumns.Add(Column.Name);
		EndIf;
	EndDo;
	NamesOfRuleLimitColumns = StrConcat(NamesOfRuleLimitColumns, ",");
	LimitRulesWithLimitPeriods = CurrentLimits.LimitRules.CopyColumns(NamesOfRuleLimitColumns);
	RuleLimitationPeriods = LimitRulesWithLimitPeriods.CopyColumns("BeginOfPeriod, EndOfPeriod");
	For Each StringRule In CurrentLimits.LimitRules Do
		FillPropertyValues(StructurePeriodOfValidity, StringRule);
		RuleLimitationPeriods.Clear();
		For Each LimitDate In DatesLimitSettings.ValidityPeriodsByLimitDates.FindRows(
			StructurePeriodOfValidity) Do
			LimitationPeriod = RuleLimitationPeriods.Add();
			LimitationPeriod.BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(LimitDate.LimitDate,
				StringRule.Periodicity);
			LimitationPeriod.EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(LimitDate.LimitDate,
				StringRule.Periodicity);
		EndDo;
		RuleLimitationPeriods.GroupBy("BeginOfPeriod, EndOfPeriod");
		For Each LimitationPeriod In RuleLimitationPeriods Do
			NewRow = LimitRulesWithLimitPeriods.Add();
			FillPropertyValues(NewRow, StringRule);
			FillPropertyValues(NewRow, LimitationPeriod);
		EndDo;
	EndDo;
	CurrentLimits.Insert("LimitRules", LimitRulesWithLimitPeriods);
	LimitRulesWithLimitPeriods.GroupBy(NamesOfRuleLimitColumns);
	
	LimitsValidForDates = CurrentLimits.LimitRules; // ValueTable -
	LimitsValidForDates.Indexes.Add("LimitsRule"); // Reference to the Reference worklink.Rulesmitovepod of budgeting
	LimitsValidForDates.Indexes.Add("Scenario");
	LimitsValidForDates.Indexes.Add("Periodicity");
	
	SelectionIsRequiredByBudgetFlowItems = False;
	If TypeOf(FilterByBudgetItems) = Type("Array") Then
		FilterByBudgetItems = CommonClientServer.CollapseArray(FilterByBudgetItems);
		BudgetFlowItemsOfRulesLimits = CommonClientServer.CollapseArray(LimitsValidForDates.UnloadColumn("BudgetFlowItem"));
		SelectionIsRequiredByBudgetFlowItems = (FilterByBudgetItems.Count() < BudgetFlowItemsOfRulesLimits.Count());
	EndIf;
	If SelectionIsRequiredByBudgetFlowItems Then
		For Each KeyAndValue In CurrentLimits Do
			If TypeOf(KeyAndValue.Value) <> Type("ValueTable") Then
				Continue;
			EndIf;
			Counter = 0;
			While Counter < KeyAndValue.Value.Count() Do
				If FilterByBudgetItems.Find(KeyAndValue.Value[Counter].BudgetFlowItem) = Undefined Then
					KeyAndValue.Value.Delete(Counter);
				Else
					Counter = Counter + 1;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	SelectionAccordingToRulesOfLimitsIsRequired = False;
	If TypeOf(SelectionAccordingToLimitRules) = Type("Array") Then
		LimitRules = CommonClientServer.CollapseArray(LimitsValidForDates.UnloadColumn("LimitsRule"));
		SelectionAccordingToRulesOfLimitsIsRequired = (SelectionAccordingToLimitRules.Count() < LimitRules.Count());
	EndIf;
	If SelectionAccordingToRulesOfLimitsIsRequired Then
		For Each KeyAndValue In CurrentLimits Do
			If TypeOf(KeyAndValue.Value) <> Type("ValueTable")
				Or KeyAndValue.Value.Columns.Find("LimitsRule") = Undefined Then
				Continue;
			EndIf;
			Counter = 0;
			While Counter < KeyAndValue.Value.Count() Do
				If SelectionAccordingToLimitRules.Find(KeyAndValue.Value[Counter].LimitsRule) = Undefined Then
					KeyAndValue.Value.Delete(Counter);
				Else
					Counter = Counter + 1;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	Return CurrentLimits;
	
EndFunction

// Returns an array of limit rules in accordance with the selection of the report transcript
//
// Parameters:
//  FilterDecryptions - Undefined, Structure - decryption parameters:
//   * BudgetingModel - CatalogRef.BudgetingModels - budgeting model from the extension
//   * LimitsRule - CatalogRef.BudgetingLimits - rule of limits from decryption
//
// Returns:
//  Array of CatalogRef.BudgetingLimits
//
Function SelectionAccordingToRulesOfDecodingReport(FilterDecryptions)
	
	SelectionAccordingToLimitRules = Undefined;
	If Not FilterDecryptions = Undefined
		And FilterDecryptions.UseFilter1 Then
		If FilterDecryptions.Property("BudgetingModel")
			Or FilterDecryptions.Property("LimitsRule") Then
		
			// When decrypting, only equality selections are used.
			// Arbitrary selections and report settings are not provided.
			Query = New Query;
			Query.Text =
			"SELECT
			|	Rules.Ref AS Ref
			|FROM
			|	Catalog.BudgetingLimits AS Rules
			|WHERE
			|	&ModelSelectionText
			|	AND &TextOfSelectionByRule";
			
			If FilterDecryptions.Property("BudgetingModel") Then
				ModelSelectionText = "Rules.Owner = &BudgetingModel";
				Query.SetParameter("BudgetingModel", FilterDecryptions.BudgetingModel);
			Else
				ModelSelectionText = "True";
			EndIf;
			Query.Text = StrReplace(Query.Text, "&ModelSelectionText", ModelSelectionText);
			If FilterDecryptions.Property("LimitsRule") Then
				TextOfSelectionByRule = "Rules.Ref = &LimitsRule";
				Query.SetParameter("LimitsRule", FilterDecryptions.LimitsRule);
			Else
				TextOfSelectionByRule = "True";
			EndIf;
			Query.Text = StrReplace(Query.Text, "&TextOfSelectionByRule", TextOfSelectionByRule);
			
			SelectionAccordingToLimitRules = Query.Execute().Unload().UnloadColumn("Ref");
			
		EndIf;
	EndIf;
	
	Return SelectionAccordingToLimitRules;
	
EndFunction

Function SearchFieldsForPlannedLimitValues()
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	If RegisterOfBudgetingLimitsIsUsed() Then
		ColumnsNames = "LimitsRule, CompanyPlan, DepartmentPlan, BeginOfPeriod, EndOfPeriod";
	Else
		ColumnsNames = "LimitsRule, BudgetFlowItem, CompanyPlan, DepartmentPlan, BeginOfPeriod, EndOfPeriod";
	EndIf;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ColumnsNames = ColumnsNames + ", " + "Dimension" + DimensionNumber + "Plan";
	EndDo;
	
	Return ColumnsNames;
	
EndFunction

Function ExpressionFinalCoefficientOfPlanAnalytics(TablesNames = Undefined)
	
	// Calculation of the final coefficient for finding the nearest analytics
	// The values of the coefficients of the corresponding measurements (analysts) are determined by their position
	// and use in the hierarchy of measurements (analysts) in the settings of the limit control rule.
	// The higher the position in the hierarchy, the multiple (10 times) higher the coefficient of measurement (analytics).
	
	// The total coefficient of the most suitable plan analytics is calculated as
	// the sum of the coefficients of the type of measurement (type of analytics) multiplied by the coefficient
	// of coincidence of the measurements (analysts) of the plan and the fact.
	// The coefficient of coincidence of the measurement (analytics) of the plan and the fact is equal to 2 
	// if the values of the measurement (analytics) of the plan and the fact completely coincide.
	// The coefficient of coincidence of the measurement (analytics) of the plan and the fact is equal to 1, 
	// if the value of the measurement (analytics) of the plan is a different value.
	// The coefficient of coincidence of the measurement (analytics) of the plan and the fact is 0 
	// if the values of the measurement (analytics) of the plan and the fact do not completely coincide.
	ExpressionFinalCoefficientOfPlanAnalytics = "
		| RulesTable.RateOfRuleCompany
		| * CASE
		|       WHEN NOT RulesTable.ByRuleCompanies
		|           THEN 2
		|       WHEN FactTable_.CompanyActual = PlanTable_.CompanyPlan
		|           THEN 2
		|       WHEN PlanTable_.CompanyPlan = VALUE(Catalog.Companies.EmptyRef)
		|           THEN 1
		|    ELSE 0
		|    END";
	ExpressionFinalCoefficientOfPlanAnalytics = ExpressionFinalCoefficientOfPlanAnalytics + "
		| + RulesTable.RateOfRuleDepartment
		| * CASE
		|       WHEN NOT RulesTable.ByRuleDepartments
		|           THEN 2
		|        WHEN FactTable_.DepartmentActual = PlanTable_.DepartmentPlan
		|            THEN 2
		|        WHEN PlanTable_.DepartmentPlan = VALUE(Catalog.BusinessStructure.EmptyRef)
		|            THEN 1
		|        ELSE 0
		|    END";
	
	PlanAnalyticsCoefficientExpressionTemplate = "
		| + RulesTable.CoefficientOfTypeOfAnalytics%DimensionNumber%Rules
		| * CASE
		|        WHEN RulesTable.DimensionKind%DimensionNumber%Rules = UNDEFINED
		|            THEN 2
		|        WHEN FactTable_.Dimension%DimensionNumber%Real = PlanTable_.Dimension%DimensionNumber%Plan
		|            THEN 2
		|        WHEN PlanTable_.Dimension%DimensionNumber%Plan = UNDEFINED
		|            THEN 1
		|        ELSE 0
		|    END";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ExpressionFinalCoefficientOfPlanAnalytics = ExpressionFinalCoefficientOfPlanAnalytics
			+ StrReplace(PlanAnalyticsCoefficientExpressionTemplate, "%DimensionNumber%", DimensionNumber);
	EndDo;
	
	If TablesNames = Undefined Then
		ExpressionFinalCoefficientOfPlanAnalytics = StrReplace(ExpressionFinalCoefficientOfPlanAnalytics,
			"RulesTable.", "");
		ExpressionFinalCoefficientOfPlanAnalytics = StrReplace(ExpressionFinalCoefficientOfPlanAnalytics,
			"PlanTable_.", "");
		ExpressionFinalCoefficientOfPlanAnalytics = StrReplace(ExpressionFinalCoefficientOfPlanAnalytics,
			"FactTable_.", "");
	Else
		ExpressionFinalCoefficientOfPlanAnalytics = StrReplace(ExpressionFinalCoefficientOfPlanAnalytics,
			"RulesTable", TablesNames.RulesTable);
		ExpressionFinalCoefficientOfPlanAnalytics = StrReplace(ExpressionFinalCoefficientOfPlanAnalytics,
			"PlanTable_", TablesNames.PlanTable_);
		ExpressionFinalCoefficientOfPlanAnalytics = StrReplace(ExpressionFinalCoefficientOfPlanAnalytics,
			"FactTable_", TablesNames.FactTable_);
	EndIf;
	
	Return ExpressionFinalCoefficientOfPlanAnalytics;
	
EndFunction

Function VT_PlanFactManagerForRegisterOfLimits(RulesForLimitsWithAdditionalData, ActualData, AdditionalParameters,
	TempTablesManager)
	
	UseMultipleCurrencies = AdditionalParameters.UseMultipleCurrencies;
	
	If TempTablesManager = Undefined Then
		TempTablesManager = New TempTablesManager;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("RulesForLimitsWithAdditionalData", RulesForLimitsWithAdditionalData);
	Query.SetParameter("ActualData", ActualData);
	Query.SetParameter("CheckDate", AdditionalParameters.VerificationDates[0].LimitDate);
	Query.SetParameter("BaseCurrency", Constants.DefaultBaseCurrency.Get());
	Query.SetParameter("TargetCurrency", AdditionalParameters.RequestCurrency);
	Query.TempTablesManager = TempTablesManager;
	
	QueriesTexts = New Array;
	
	// Current Rules For Limits With Additional Data
	QueryText =
	"SELECT
	|	CAST(RulesForLimitsWithAdditionalData.LimitsRule AS Catalog.BudgetingLimits) AS LimitsRule,
	|	CAST(RulesForLimitsWithAdditionalData.LimitType AS Enum.TypesOfCashExpenseLimit) AS LimitType,
	|	CAST(RulesForLimitsWithAdditionalData.LimitedTransaction AS Enum.LimitedTransactions) AS LimitedTransaction,
	|	CAST(RulesForLimitsWithAdditionalData.Periodicity AS Enum.Periodicity) AS Periodicity,
	|	CAST(RulesForLimitsWithAdditionalData.BudgetFlowItem AS Catalog.BudgetFlowItems) AS BudgetFlowItem,
	|	CAST(RulesForLimitsWithAdditionalData.BeginOfPeriod AS DATE) AS BeginOfPeriod,
	|	CAST(RulesForLimitsWithAdditionalData.EndOfPeriod AS DATE) AS EndOfPeriod,
	|	CAST(RulesForLimitsWithAdditionalData.ByCompanies AS BOOLEAN) AS ByRuleCompanies,
	|	CAST(RulesForLimitsWithAdditionalData.OrganizationCoefficient AS NUMBER(10, 0)) AS RateOfRuleCompany,
	|	CAST(RulesForLimitsWithAdditionalData.ByBusinessUnits AS BOOLEAN) AS ByRuleDepartments,
	|	CAST(RulesForLimitsWithAdditionalData.SubdivisionCoefficient AS NUMBER(10, 0)) AS RateOfRuleDepartment,
	|	&TextAnalyst_,
	|	&TextOfCoefficientsOfTypesOfAnalytics
	|INTO CurrentRulesForLimitsWithAdditionalData
	|FROM
	|	&RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData
	|
	|INDEX BY
	|	BudgetFlowItem";
	TextAnalyst_ = "";
	TextOfCoefficientsOfTypesOfAnalytics = "";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalyst_ = TextAnalyst_ + ?(TextAnalyst_ = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"ISNULL(CAST(RulesForLimitsWithAdditionalData.DimensionKind%1 AS ChartOfCharacteristicTypes.BudgetFlowItemDimensions), UNDEFINED) AS DimensionKind%1Rules",
				DimensionNumber);
		TextOfCoefficientsOfTypesOfAnalytics = TextOfCoefficientsOfTypesOfAnalytics + ?(TextOfCoefficientsOfTypesOfAnalytics = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"CAST(RulesForLimitsWithAdditionalData.CoefficientOfTypeOfAnalytics%1 AS NUMBER(10, 0)) AS CoefficientOfTypeOfAnalytics%1Rules",
				DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextAnalyst_", TextAnalyst_);
	QueryText = StrReplace(QueryText, "&TextOfCoefficientsOfTypesOfAnalytics", TextOfCoefficientsOfTypesOfAnalytics);
	QueriesTexts.Add(QueryText);
	
	// The rules of limits with additional data that worked according to the document
	QueryText = 
	"SELECT
	|	CurrentRulesForLimitsWithAdditionalData.BeginOfPeriod,
	|	CurrentRulesForLimitsWithAdditionalData.LimitsRule,
	|	CurrentRulesForLimitsWithAdditionalData.BudgetFlowItem,
	|	*
	|INTO RulesForLimitsWithAdditionalData
	|FROM
	|	CurrentRulesForLimitsWithAdditionalData AS CurrentRulesForLimitsWithAdditionalData
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				ActualDataOnDocument AS ActualDataOnDocument
	|			WHERE
	|				CurrentRulesForLimitsWithAdditionalData.BudgetFlowItem = ActualDataOnDocument.BudgetFlowItem)
	|
	|INDEX BY
	|	BeginOfPeriod,
	|	LimitsRule";
	QueriesTexts.Add(QueryText);
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
		"CurrentRulesForLimitsWithAdditionalData");
	
	// Conversion factors of planned amounts by limits to the target currency (document currency)
	If UseMultipleCurrencies Then
		QueriesTexts.Add(" 
		|SELECT ALLOWED
		|	CurrencyExchangeRate.Currency AS Currency,
		|	CurrencyExchangeRate.CourseNumerator * TargetCurrencyRate.CourseDenominator / (CurrencyExchangeRate.CourseDenominator * TargetCurrencyRate.CourseNumerator) AS ConversionFactor_
		|INTO ConversionRatiosToTargetCurrency
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(
		|			&CheckDate,
		|			BaseCurrency = &BaseCurrency) AS CurrencyExchangeRate
		|		INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(
		|				&CheckDate,
		|				Currency = &TargetCurrency
		|					AND BaseCurrency = &BaseCurrency) AS TargetCurrencyRate
		|		ON (TRUE)
		|WHERE
		|	CurrencyExchangeRate.CourseDenominator <> 0
		|	AND TargetCurrencyRate.CourseNumerator <> 0");
	EndIf;
	
	// Balances of limits in planned amounts
	QueriesTexts.Add("
	|SELECT
	|	Limits.LimitationPeriod AS LimitationPeriod,
	|	Limits.LimitsRule AS LimitsRule,
	|	Limits.Organization AS Organization,
	|	Limits.Department AS Department,
	|	Limits.Dimension1 AS Dimension1,
	|	Limits.Dimension2 AS Dimension2,
	|	Limits.Dimension3 AS Dimension3,
	|	Limits.Dimension4 AS Dimension4,
	|	Limits.Dimension5 AS Dimension5,
	|	Limits.Dimension6 AS Dimension6,
	|	Limits.Currency AS Currency,
	|	Limits.LimitTurnover AS Limit,
	|	Limits.ApplicationAmountTurnover + Limits.SumRealTurnover AS LimitConsumption
	|INTO ScheduledData
	|FROM
	|	AccumulationRegister.LimitsByBudgetingData.Turnovers(
	|			,
	|			,
	|			,
	|			(LimitationPeriod, LimitsRule) IN
	|				(SELECT
	|					RulesForLimitsWithAdditionalData.BeginOfPeriod,
	|					RulesForLimitsWithAdditionalData.LimitsRule
	|				FROM
	|					RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData)) AS Limits
	|
	|INDEX BY
	|	LimitationPeriod,
	|	LimitsRule");
	
	// Limit Balances in amounts in the target currency
	QueryText = 
	"SELECT
	|	RulesForLimitsWithAdditionalData.LimitsRule AS LimitsRule,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod AS BeginOfPeriod,
	|	RulesForLimitsWithAdditionalData.EndOfPeriod AS EndOfPeriod,
	|	ScheduledData.Organization AS CompanyPlan,
	|	ScheduledData.Department AS DepartmentPlan,
	|	ScheduledData.Dimension1 AS Dimension1Plan,
	|	ScheduledData.Dimension2 AS Dimension2Plan,
	|	ScheduledData.Dimension3 AS Dimension3Plan,
	|	ScheduledData.Dimension4 AS Dimension4Plan,
	|	ScheduledData.Dimension5 AS Dimension5Plan,
	|	ScheduledData.Dimension6 AS Dimension6Plan,
	|	ScheduledData.Currency AS Currency,
	|	SUM(CAST(ScheduledData.Limit * &ConversionFactor_ AS NUMBER(31,2))) AS SumPlan,
	|	SUM(CAST(ScheduledData.LimitConsumption * &ConversionFactor_ AS NUMBER(31,2))) AS SumReal,
	|	MAX(&ConversionFactor_) AS ConversionRatioToTargetCurrency
	|INTO PlannedDataOnRules
	|FROM
	|	RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData
	|		INNER JOIN ScheduledData AS ScheduledData
	|		ON RulesForLimitsWithAdditionalData.BeginOfPeriod = ScheduledData.LimitationPeriod
	|			AND RulesForLimitsWithAdditionalData.LimitsRule = ScheduledData.LimitsRule
	|		AND &TextOfConversionConnectionToTargetCurrency
	|
	|GROUP BY
	|	RulesForLimitsWithAdditionalData.LimitsRule,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod,
	|	RulesForLimitsWithAdditionalData.EndOfPeriod,
	|	ScheduledData.Organization,
	|	ScheduledData.Department,
	|	ScheduledData.Dimension1,
	|	ScheduledData.Dimension2,
	|	ScheduledData.Dimension3,
	|	ScheduledData.Dimension4,
	|	ScheduledData.Dimension5,
	|	ScheduledData.Dimension6,
	|	ScheduledData.Currency
	|
	|HAVING
	|	SUM(ScheduledData.Limit) > 0
	|
	|INDEX BY
	|	BeginOfPeriod,
	|	EndOfPeriod,
	|	LimitsRule";
	If UseMultipleCurrencies Then
		QueryText = StrReplace(QueryText, "&ConversionFactor_", "ISNULL(ConversionRatiosToTargetCurrency.ConversionFactor_, 1)");
		QueryText = StrReplace(QueryText, "AND &TextOfConversionConnectionToTargetCurrency", "
				|	LEFT JOIN ConversionRatiosToTargetCurrency AS ConversionRatiosToTargetCurrency
				|	ON ScheduledData.Currency = ConversionRatiosToTargetCurrency.Currency");
	Else
		QueryText = StrReplace(QueryText, "&ConversionFactor_", "1");
		QueryText = StrReplace(QueryText, "AND &TextOfConversionConnectionToTargetCurrency", "");
	EndIf;
	QueriesTexts.Add(QueryText);
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "ScheduledData");
	If UseMultipleCurrencies Then
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
			"ConversionRatiosToTargetCurrency");
	EndIf;
	
	// Calculated fact according to the document
	QueryText =
	"SELECT
	|	RulesForLimitsWithAdditionalData.LimitsRule AS LimitsRule,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod AS BeginOfPeriod,
	|	RulesForLimitsWithAdditionalData.EndOfPeriod AS EndOfPeriod,
	|	ActualData.Period AS Period,
	|	CASE
	|		WHEN RulesForLimitsWithAdditionalData.ByRuleCompanies
	|			THEN ActualData.Organization
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END AS CompanyActual,
	|	CASE
	|		WHEN RulesForLimitsWithAdditionalData.ByRuleDepartments
	|			THEN ActualData.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS DepartmentActual,
	|	ActualData.Currency AS Currency,
	|	&TextOfDimensionsFields,
	|	SUM(ActualData.Sum) AS Sum,
	|	SUM(ActualData.SumReal) AS SumReal
	|INTO ActualData
	|FROM
	|	RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData
	|		INNER JOIN ActualDataOnDocument AS ActualData
	|		ON RulesForLimitsWithAdditionalData.BudgetFlowItem = ActualData.BudgetFlowItem
	|
	|WHERE
	|	RulesForLimitsWithAdditionalData.LimitedTransaction = VALUE(Enum.LimitedTransactions.FlowOfCash)
	|
	|GROUP BY
	|	RulesForLimitsWithAdditionalData.LimitsRule,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod,
	|	RulesForLimitsWithAdditionalData.EndOfPeriod,
	|	ActualData.Period,
	|	CASE
	|		WHEN RulesForLimitsWithAdditionalData.ByRuleCompanies
	|			THEN ActualData.Organization
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END,
	|	CASE
	|		WHEN RulesForLimitsWithAdditionalData.ByRuleDepartments
	|			THEN ActualData.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END,
	|	ActualData.Currency,
	|	&TextOfAnalystGroups
	|
	|UNION ALL
	|
	|SELECT
	|	RulesForLimitsWithAdditionalData.LimitsRule,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod,
	|	RulesForLimitsWithAdditionalData.EndOfPeriod,
	|	ActualData.Period,
	|	CASE
	|		WHEN RulesForLimitsWithAdditionalData.ByRuleCompanies
	|			THEN ActualData.Organization
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END,
	|	CASE
	|		WHEN RulesForLimitsWithAdditionalData.ByRuleDepartments
	|			THEN ActualData.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END,
	|	ActualData.Currency AS Currency,
	|	&TextOfAnalystFactFields,
	|	SUM(ActualData.Sum) AS Sum,
	|	SUM(ActualData.SumReal) AS SumReal
	|FROM
	|	RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData
	|		INNER JOIN ActualDataOnDocument AS ActualData
	|		ON RulesForLimitsWithAdditionalData.BudgetFlowItem = ActualData.BudgetFlowItem
	|			AND RulesForLimitsWithAdditionalData.LimitsRule = ActualData.LimitsRule
	|			AND RulesForLimitsWithAdditionalData.BeginOfPeriod = ActualData.LimitationPeriod
	|
	|WHERE
	|	RulesForLimitsWithAdditionalData.LimitedTransaction = VALUE(Enum.LimitedTransactions.Expenses)
	|
	|GROUP BY
	|	RulesForLimitsWithAdditionalData.LimitsRule,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod,
	|	RulesForLimitsWithAdditionalData.EndOfPeriod,
	|	ActualData.Period,
	|	CASE
	|		WHEN RulesForLimitsWithAdditionalData.ByRuleCompanies
	|			THEN ActualData.Organization
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END,
	|	CASE
	|		WHEN RulesForLimitsWithAdditionalData.ByRuleDepartments
	|			THEN ActualData.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END,
	|	ActualData.Currency,
	|	&TextOfAnalystFactGroups
	|
	|INDEX BY
	|	BeginOfPeriod,
	|	EndOfPeriod,
	|	LimitsRule";
	TextOfDimensionsFields = "";
	TextOfAnalystFactFields = "";
	TextOfAnalystGroups = "";
	TextOfAnalystFactGroups = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfDimensionsFields = TextOfDimensionsFields + ?(TextOfDimensionsFields = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"CASE
				|	WHEN RulesForLimitsWithAdditionalData.DimensionKind%1Rules = UNDEFINED
				|		THEN UNDEFINED
				|	ELSE ActualData.Dimension%1
				|END AS Dimension%1Real",
				DimensionNumber);
		TextOfAnalystFactFields = TextOfAnalystFactFields + ?(TextOfAnalystFactFields = "", "", "," + Chars.LF
			+ Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString(
				"ActualData.Dimension%1 AS Dimension%1Real",
				DimensionNumber);
		TextOfAnalystGroups = TextOfAnalystGroups + ?(TextOfAnalystGroups = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"CASE
				|	WHEN RulesForLimitsWithAdditionalData.DimensionKind%1Rules = UNDEFINED
				|		THEN UNDEFINED
				|	ELSE ActualData.Dimension%1
				|END",
				DimensionNumber);
		TextOfAnalystFactGroups = TextOfAnalystFactGroups + ?(TextOfAnalystFactGroups = "", "", "," + Chars.LF
			+ Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString(
				"ActualData.Dimension%1",
				DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextOfAnalystFactFields", TextOfAnalystFactFields);
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", TextOfDimensionsFields);
	QueryText = StrReplace(QueryText, "&TextOfAnalystFactGroups", TextOfAnalystFactGroups);
	QueryText = StrReplace(QueryText, "&TextOfAnalystGroups", TextOfAnalystGroups);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
		"ActualDataOnDocument");
	
	QueryText = 
	"SELECT
	|	RulesForLimitsWithAdditionalData.LimitsRule AS LimitsRule,
	|	RulesForLimitsWithAdditionalData.LimitType AS LimitType,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod AS BeginOfPeriod,
	|	RulesForLimitsWithAdditionalData.EndOfPeriod AS EndOfPeriod,
	|	ActualData.Period AS Period,
	|	ActualData.CompanyActual AS Organization,
	|	ActualData.DepartmentActual AS Department,
	|	&TextOfDimensionsFields,
	|	ISNULL(MAX(&ExpressionFinalCoefficientOfPlanAnalytics), 0) AS FinalPlanAnalyticsFactor,
	|	ActualData.Currency AS Currency,
	|	ActualData.Sum AS Sum,
	|	ActualData.SumReal AS SumReal
	|INTO ActualDataOnRules
	|FROM
	|	ActualData AS ActualData
	|		INNER JOIN RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData
	|		ON ActualData.BeginOfPeriod = RulesForLimitsWithAdditionalData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = RulesForLimitsWithAdditionalData.EndOfPeriod
	|			AND ActualData.LimitsRule = RulesForLimitsWithAdditionalData.LimitsRule
	|		LEFT JOIN PlannedDataOnRules AS ScheduledData
	|		ON ActualData.BeginOfPeriod = ScheduledData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = ScheduledData.EndOfPeriod
	|			AND ActualData.LimitsRule = ScheduledData.LimitsRule
	|			AND (ActualData.CompanyActual = ScheduledData.CompanyPlan
	|			OR ScheduledData.CompanyPlan = VALUE(Catalog.Companies.EmptyRef))
	|			AND (ActualData.DepartmentActual = ScheduledData.DepartmentPlan
	|			OR ScheduledData.DepartmentPlan = VALUE(Catalog.BusinessStructure.EmptyRef))
	|			AND &DimensionsJoinText
	|
	|GROUP BY
	|	RulesForLimitsWithAdditionalData.LimitsRule,
	|	RulesForLimitsWithAdditionalData.LimitType,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod,
	|	RulesForLimitsWithAdditionalData.EndOfPeriod,
	|	ActualData.Period,
	|	ActualData.CompanyActual,
	|	ActualData.DepartmentActual,
	|	&TextOfAnalystGroups,
	|	ActualData.Currency,
	|	ActualData.Sum,
	|	ActualData.SumReal
	|
	|INDEX BY
	|	BeginOfPeriod,
	|	EndOfPeriod,
	|	LimitsRule";
	TextOfDimensionsFields = "";
	TextOfAnalystGroups = "";
	DimensionsJoinText = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfDimensionsFields = TextOfDimensionsFields + ?(TextOfDimensionsFields = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
			"ActualData.Dimension%1Real AS Dimension%1", DimensionNumber);
		TextOfAnalystGroups = TextOfAnalystGroups + ?(TextOfAnalystGroups = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString("ActualData.Dimension%1Real",
			DimensionNumber);
		DimensionsJoinText = DimensionsJoinText + ?(DimensionsJoinText = "", "", Chars.LF
			+ Chars.Tab + "And ") + StringFunctionsClientServer.SubstituteParametersToString(
				"(ActualData.Dimension%1Real = ScheduledData.Dimension%1Plan OR ScheduledData.Dimension%1Plan = UNDEFINED)",
			DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", TextOfDimensionsFields);
	QueryText = StrReplace(QueryText, "&TextOfAnalystGroups", TextOfAnalystGroups);
	QueryText = StrReplace(QueryText, "&DimensionsJoinText", DimensionsJoinText);
	
	TablesNames = New Structure("RulesTable, PlanTable_, FactTable_", "RulesForLimitsWithAdditionalData",
		"ScheduledData", "ActualData");
	QueryText = StrReplace(QueryText, "&ExpressionFinalCoefficientOfPlanAnalytics",
		ExpressionFinalCoefficientOfPlanAnalytics(TablesNames));
	
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "ActualData");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	Query.ExecuteBatch();
	
	Return TempTablesManager;
	
EndFunction

Procedure AddTemporaryFactTableWithPlanDimensions(TempTablesManager, FactTable_)
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager, "ActualDataOnRules");
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	QueryText =
	"SELECT
	|	CAST(ActualData.LimitsRule AS Catalog.BudgetingLimits) AS LimitsRule,
	|	CAST(ActualData.Currency AS Catalog.Currencies) AS Currency,
	|	CAST(ActualData.BeginOfPeriod AS DATE) AS BeginOfPeriod,
	|	CAST(ActualData.EndOfPeriod AS DATE) AS EndOfPeriod,
	|	CAST(ActualData.Period AS DATE) AS Period,
	|	CAST(ActualData.Organization AS Catalog.Companies) AS Organization,
	|	CAST(ActualData.Department AS Catalog.BusinessStructure) AS Department,
	|	CAST(ActualData.Organization AS Catalog.Companies) AS CompanyPlan,
	|	CAST(ActualData.Department AS Catalog.BusinessStructure) AS DepartmentPlan,
	|	&TextAnalystFact,
	|	&TextDimensionPlan,
	|	CAST(ActualData.Sum AS NUMBER(31, 2)) AS Sum,
	|	CAST(ActualData.SumReal AS NUMBER(31, 2)) AS SumReal
	|INTO ActualDataOnRules
	|FROM
	|	&ActualData AS ActualData
	|
	|INDEX BY
	|	BeginOfPeriod,
	|	EndOfPeriod,
	|	LimitsRule";
	TextAnalystFact = "";
	TextDimensionPlan = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalystFact = TextAnalystFact + ?(TextAnalystFact = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"ActualData.Dimension%1 AS Dimension%1",
				DimensionNumber);
		TextDimensionPlan = TextDimensionPlan + ?(TextDimensionPlan = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"ActualData.Dimension%1Plan AS Dimension%1Plan",
				DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextAnalystFact", TextAnalystFact);
	QueryText = StrReplace(QueryText, "&TextDimensionPlan", TextDimensionPlan);
	
	Query = New Query;
	Query.SetParameter("ActualData", FactTable_);
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	
	Query.Execute();
	
EndProcedure

Function CalculatePlanFactAndGenerateRegisteredRecordsTable(TempTablesManager, ControlParameters)
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	QueriesTexts = New Array;
	
	// Fact plan according to the rules of limits (in the currency of the document)
	QueryText = 
	"SELECT
	|	RulesForLimitsWithAdditionalData.LimitsRule AS LimitsRule,
	|	RulesForLimitsWithAdditionalData.LimitType AS LimitType,
	|	RulesForLimitsWithAdditionalData.LimitedTransaction AS LimitedTransaction,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod AS BeginOfPeriod,
	|	RulesForLimitsWithAdditionalData.EndOfPeriod AS EndOfPeriod,
	|	ActualData.CompanyPlan AS Organization,
	|	ActualData.DepartmentPlan AS Department,
	|	&TextDimensionPlan,
	|	ActualData.Currency AS Currency,
	|	ISNULL(ScheduledData.SumPlan, 0) AS SumPlan,
	|	CASE
	|		WHEN ISNULL(ScheduledData.SumPlan, 0) < ISNULL(ScheduledData.SumReal, 0) + ActualData.Sum
 	|			THEN ISNULL(ScheduledData.SumReal, 0) + ActualData.Sum - ISNULL(ScheduledData.SumPlan, 0)
 	|		ELSE 0 
 	|	END AS ExcessAmount,
	|	CASE
	|		WHEN ISNULL(ScheduledData.SumPlan, 0) > ISNULL(ScheduledData.SumReal, 0)
	|			THEN ISNULL(ScheduledData.SumPlan, 0) - ISNULL(ScheduledData.SumReal, 0)
	|		ELSE 0
	|	END AS AmountCanBeDebited
	|FROM
	|	ActualDataOnRules AS ActualData
	|		INNER JOIN RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData
	|		ON ActualData.BeginOfPeriod = RulesForLimitsWithAdditionalData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = RulesForLimitsWithAdditionalData.EndOfPeriod
	|			AND ActualData.LimitsRule = RulesForLimitsWithAdditionalData.LimitsRule
	|		LEFT JOIN PlannedDataOnRules AS ScheduledData
	|		ON ActualData.BeginOfPeriod = ScheduledData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = ScheduledData.EndOfPeriod
	|			AND ActualData.LimitsRule = ScheduledData.LimitsRule
	|			AND ActualData.CompanyPlan = ScheduledData.CompanyPlan
	|			AND ActualData.DepartmentPlan = ScheduledData.DepartmentPlan
	|			AND &TextOfConnectionAnalystPlan
	|WHERE
	|	&FindingErrors";
	TextDimensionPlan = "";
	TextOfConnectionAnalystPlan = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextDimensionPlan = TextDimensionPlan + ?(TextDimensionPlan = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
			"ActualData.Dimension%1Plan AS Dimension%1", DimensionNumber);
		TextOfConnectionAnalystPlan = TextOfConnectionAnalystPlan + ?(TextOfConnectionAnalystPlan = "", "", Chars.LF
			+ Chars.Tab + "And ") + StringFunctionsClientServer.SubstituteParametersToString(
			"ActualData.Dimension%1Plan = ScheduledData.Dimension%1Plan", DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextDimensionPlan", TextDimensionPlan);
	QueryText = StrReplace(QueryText, "&TextOfConnectionAnalystPlan", TextOfConnectionAnalystPlan);
	
	QueriesTexts.Add(QueryText);
	
	// The table of Register Records by budgeting limits (in the plan currency)
	QueryText = 
	"SELECT
	|	ActualData.Period AS Period,
	|	RulesForLimitsWithAdditionalData.Periodicity AS Periodicity,
	|	RulesForLimitsWithAdditionalData.LimitsRule AS LimitsRule,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod AS LimitationPeriod,
	|	ActualData.CompanyPlan AS Organization,
	|	ActualData.DepartmentPlan AS Department,
	|	&TextDimensionPlan,
	|	VALUE(Catalog.Companies.EmptyRef) AS CompanyActual,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS DepartmentActual,
	|	&TextOfEmptyAnalystFact,
	|	ISNULL(ScheduledData.Currency, ActualData.Currency) AS Currency,
	|	&Document AS ReservationDocument,
	|	0 AS Limit,
	|	CAST(ActualData.Sum / ISNULL(ScheduledData.ConversionRatioToTargetCurrency, 1) AS NUMBER(31,2)) AS ApplicationAmount,
	|	0 AS SumReal
	|INTO TableLimitsBasedOnBudgetingData
	|FROM
	|	ActualDataOnRules AS ActualData
	|		INNER JOIN RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData
	|		ON ActualData.BeginOfPeriod = RulesForLimitsWithAdditionalData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = RulesForLimitsWithAdditionalData.EndOfPeriod
	|			AND ActualData.LimitsRule = RulesForLimitsWithAdditionalData.LimitsRule
	|		LEFT JOIN PlannedDataOnRules AS ScheduledData
	|		ON ActualData.BeginOfPeriod = ScheduledData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = ScheduledData.EndOfPeriod
	|			AND ActualData.LimitsRule = ScheduledData.LimitsRule
	|			AND ActualData.CompanyPlan = ScheduledData.CompanyPlan
	|			AND ActualData.DepartmentPlan = ScheduledData.DepartmentPlan
	|			AND &TextOfConnectionAnalystPlan
	|WHERE
	|	&ReserveLimitAmount
	|
	|UNION ALL
	|
	|SELECT
	|	ActualData.Period,
	|	RulesForLimitsWithAdditionalData.Periodicity,
	|	RulesForLimitsWithAdditionalData.LimitsRule,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod,
	|	ActualData.CompanyPlan,
	|	ActualData.DepartmentPlan,
	|	&TextDimensionPlan,
	|	VALUE(Catalog.Companies.EmptyRef),
	|	VALUE(Catalog.BusinessStructure.EmptyRef),
	|	&TextOfEmptyAnalystFact,
	|	ISNULL(ScheduledData.Currency, ActualData.Currency),
	|	&Document,
	|	0,
	|	-CAST(ActualData.Sum / ISNULL(ScheduledData.ConversionRatioToTargetCurrency, 1) AS NUMBER(31,2)),
	|	0
	|FROM
	|	ActualDataOnRules AS ActualData
	|		INNER JOIN RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData
	|		ON ActualData.BeginOfPeriod = RulesForLimitsWithAdditionalData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = RulesForLimitsWithAdditionalData.EndOfPeriod
	|			AND ActualData.LimitsRule = RulesForLimitsWithAdditionalData.LimitsRule
	|		LEFT JOIN PlannedDataOnRules AS ScheduledData
	|		ON ActualData.BeginOfPeriod = ScheduledData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = ScheduledData.EndOfPeriod
	|			AND ActualData.LimitsRule = ScheduledData.LimitsRule
	|			AND ActualData.CompanyPlan = ScheduledData.CompanyPlan
	|			AND ActualData.DepartmentPlan = ScheduledData.DepartmentPlan
	|			AND &TextOfConnectionAnalystPlan
	|WHERE
	|	&ReserveLimitAmount
	|	AND ActualData.SumReal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	ActualData.Period,
	|	RulesForLimitsWithAdditionalData.Periodicity,
	|	RulesForLimitsWithAdditionalData.LimitsRule,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod,
	|	ActualData.CompanyPlan,
	|	ActualData.DepartmentPlan,
	|	&TextDimensionPlan,
	|	ActualData.Organization,
	|	ActualData.Department,
	|	&TextAnalystFact,
	|	ISNULL(ScheduledData.Currency, ActualData.Currency),
	|	UNDEFINED,
	|	0,
	|	0,
	|	CAST(ActualData.SumReal / ISNULL(ScheduledData.ConversionRatioToTargetCurrency, 1) AS NUMBER(31,2))
	|FROM
	|	ActualDataOnRules AS ActualData
	|		INNER JOIN RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData
	|		ON ActualData.BeginOfPeriod = RulesForLimitsWithAdditionalData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = RulesForLimitsWithAdditionalData.EndOfPeriod
	|			AND ActualData.LimitsRule = RulesForLimitsWithAdditionalData.LimitsRule
	|		LEFT JOIN PlannedDataOnRules AS ScheduledData
	|		ON ActualData.BeginOfPeriod = ScheduledData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = ScheduledData.EndOfPeriod
	|			AND ActualData.LimitsRule = ScheduledData.LimitsRule
	|			AND ActualData.CompanyPlan = ScheduledData.CompanyPlan
	|			AND ActualData.DepartmentPlan = ScheduledData.DepartmentPlan
	|			AND &TextOfConnectionAnalystPlan
	|WHERE
	|	&ReserveLimitAmount
	|	AND ActualData.SumReal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	ActualData.Period,
	|	RulesForLimitsWithAdditionalData.Periodicity,
	|	RulesForLimitsWithAdditionalData.LimitsRule,
	|	RulesForLimitsWithAdditionalData.BeginOfPeriod,
	|	ActualData.CompanyPlan,
	|	ActualData.DepartmentPlan,
	|	&TextDimensionPlan,
	|	ActualData.Organization,
	|	ActualData.Department,
	|	&TextAnalystFact,
	|	ISNULL(ScheduledData.Currency, ActualData.Currency),
	|	UNDEFINED,
	|	0,
	|	0,
	|	CAST(ActualData.SumReal / ISNULL(ScheduledData.ConversionRatioToTargetCurrency, 1) AS NUMBER(31,2))
	|FROM
	|	ActualDataOnRules AS ActualData
	|		INNER JOIN RulesForLimitsWithAdditionalData AS RulesForLimitsWithAdditionalData
	|		ON ActualData.BeginOfPeriod = RulesForLimitsWithAdditionalData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = RulesForLimitsWithAdditionalData.EndOfPeriod
	|			AND ActualData.LimitsRule = RulesForLimitsWithAdditionalData.LimitsRule
	|		LEFT JOIN PlannedDataOnRules AS ScheduledData
	|		ON ActualData.BeginOfPeriod = ScheduledData.BeginOfPeriod
	|			AND ActualData.EndOfPeriod = ScheduledData.EndOfPeriod
	|			AND ActualData.LimitsRule = ScheduledData.LimitsRule
	|			AND ActualData.CompanyPlan = ScheduledData.CompanyPlan
	|			AND ActualData.DepartmentPlan = ScheduledData.DepartmentPlan
	|			AND &TextOfConnectionAnalystPlan
	|WHERE
	|	NOT &ReserveLimitAmount";
	TextAnalystFact = "";
	TextDimensionPlan = "";
	TextOfEmptyAnalystFact = "";
	TextOfConnectionAnalystPlan = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextDimensionPlan = TextDimensionPlan + ?(TextDimensionPlan = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
			"ActualData.Dimension%1Plan AS Dimension%1", DimensionNumber);
		TextAnalystFact = TextAnalystFact + ?(TextAnalystFact = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
			"ActualData.Dimension%1 AS Dimension%1Real", DimensionNumber);
		TextOfEmptyAnalystFact = TextOfEmptyAnalystFact + ?(TextOfEmptyAnalystFact = "", "", "," + Chars.LF
			+ Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString(
			"UNDEFINED AS Dimension%1Real", DimensionNumber);
		TextOfConnectionAnalystPlan = TextOfConnectionAnalystPlan + ?(TextOfConnectionAnalystPlan = "", "", Chars.LF
			+ Chars.Tab + "And ") + StringFunctionsClientServer.SubstituteParametersToString(
				"ActualData.Dimension%1Plan = ScheduledData.Dimension%1Plan", DimensionNumber);
	EndDo;
	If ControlParameters.ReserveLimitAmount Then
		QueryText = StrReplace(QueryText, "INTO TableLimitsBasedOnBudgetingData", "");
	EndIf;
	QueryText = StrReplace(QueryText, "&TextDimensionPlan", TextDimensionPlan);
	QueryText = StrReplace(QueryText, "&TextAnalystFact", TextAnalystFact);
	QueryText = StrReplace(QueryText, "&TextOfEmptyAnalystFact", TextOfEmptyAnalystFact);
	QueryText = StrReplace(QueryText, "&TextOfConnectionAnalystPlan", TextOfConnectionAnalystPlan);
	
	QueriesTexts.Add(QueryText);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Document", ControlParameters.DocumentAttributes.Document);
	Query.SetParameter("FindingErrors", ControlParameters.FindingErrors);
	Query.SetParameter("ReserveLimitAmount", ControlParameters.ReserveLimitAmount);
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	Result = Query.ExecuteBatch();
	
	TablesOfDataOnLimits = New Structure;
	TablesOfDataOnLimits.Insert("ActionPlanForLimitRules", Result[0].Unload());
	If ControlParameters.ReserveLimitAmount Then
		TablesOfDataOnLimits.Insert("TableLimitsBasedOnBudgetingData", Result[1].Unload());
	Else
		TMCommonUse.DestroyTemporaryTables(TempTablesManager,
			"RulesForLimitsWithAdditionalData,PlannedDataOnRules,ActualDataOnRules");
	EndIf;
	
	Return TablesOfDataOnLimits;
	
EndFunction

Procedure ReflectLimitsBasedOnBudgetingData(Jobs, IdsOfUnprocessedRecords,
	AdditionalProperties = Undefined) Export
	
	DocumentsForProcessing_ = Jobs.UnloadColumn("Document");
	If DocumentsForProcessing_.Count() = 0 Then
		Return;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	QueriesTexts = New Array;
	
    #Region Common_Tables
	
	QueriesTexts.Add(" 
	|SELECT
	|	CashToBePaid.Recorder AS Document,
	|	CashToBePaid.PaymentRequest AS ReservationDocument,
	|	CAST(CashToBePaid.PaymentRequest AS Document.ApplicationForBusinessTrip).RequiredPaymentDate AS Date,
	|	SUM(CashToBePaid.Sum) AS Sum
	|INTO ReservationDocuments
	|FROM
	|	AccumulationRegister.CashToBePaid AS CashToBePaid
	|WHERE
	|	CashToBePaid.Recorder IN(&DocumentsForProcessing_)
	|	AND CashToBePaid.PaymentRequest REFS Document.ApplicationForBusinessTrip
	|	AND CashToBePaid.PaymentRequest <> VALUE(Document.ApplicationForBusinessTrip.EmptyRef)
	|
	|GROUP BY
	|	CashToBePaid.PaymentRequest,
	|	CashToBePaid.Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	CashToBePaid.Recorder,
	|	CashToBePaid.PaymentRequest,
	|	CAST(CashToBePaid.PaymentRequest AS Document.PaymentRequest).RequiredPaymentDate,
	|	SUM(CashToBePaid.Sum)
	|FROM
	|	AccumulationRegister.CashToBePaid AS CashToBePaid
	|WHERE
	|	CashToBePaid.Recorder IN(&DocumentsForProcessing_)
	|	AND CashToBePaid.PaymentRequest REFS Document.PaymentRequest
	|	AND CashToBePaid.PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
	|
	|GROUP BY
	|	CashToBePaid.PaymentRequest,
	|	CashToBePaid.Recorder
	|
	|INDEX BY
	|	ReservationDocument");
	
	#EndRegion
	
	#Region TablesForAdjustingLimitPeriod
	
	QueriesTexts.Add("
	|SELECT
	|	ReservationDocuments.Document AS Document,
	|	ReservationDocuments.ReservationDocument AS ReservationDocument,
	|	ReservationDocuments.Date AS Date,
	|	ReservationDocuments.Sum AS Base,
	|	ISNULL(SUM(ReservationDocuments_Previous.Sum), 0) AS BaseAccumulated
	|INTO Documents_Coefficients
	|FROM
	|	ReservationDocuments AS ReservationDocuments
	|		LEFT JOIN ReservationDocuments AS ReservationDocuments_Previous
	|		ON ReservationDocuments.Document = ReservationDocuments_Previous.Document
	|			AND ReservationDocuments.ReservationDocument > ReservationDocuments_Previous.ReservationDocument
	|
	|GROUP BY
	|	ReservationDocuments.Document,
	|	ReservationDocuments.ReservationDocument,
	|	ReservationDocuments.Date,
	|	ReservationDocuments.Sum
	|
	|INDEX BY
	|	Document");
	
	QueriesTexts.Add("
	|SELECT
	|	ReservationDocuments.Document AS Document,
	|	SUM(ReservationDocuments.Sum) AS BaseAmount
	|INTO Documents_AmountOfDatabase
	|FROM
	|	ReservationDocuments AS ReservationDocuments
	|
	|GROUP BY
	|	ReservationDocuments.Document");
	
	#EndRegion
	
	#Region TablesForReversingReservesByLimits
	
	QueriesTexts.Add("
	|SELECT
	|	CashToBePaid.Recorder AS ReservationDocument,
	|	SUM(CashToBePaid.Sum) AS Sum
	|INTO AmountsAccordingToReservationDocuments
	|FROM
	|	AccumulationRegister.CashToBePaid AS CashToBePaid
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				ReservationDocuments AS ReservationDocuments
	|			WHERE
	|				CashToBePaid.Recorder = ReservationDocuments.ReservationDocument)
	|
	|GROUP BY
	|	CashToBePaid.Recorder
	|
	|INDEX BY
	|	ReservationDocument");
	
	QueriesTexts.Add("
	|SELECT
	|	CashToBePaid.PaymentRequest AS ReservationDocument,
	|	CashToBePaid.Recorder AS Document,
	|	SUM(CashToBePaid.Sum) AS Sum
	|INTO AmountOfFactAccordingToReservationDocuments
	|FROM
	|	AccumulationRegister.CashToBePaid AS CashToBePaid
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				ReservationDocuments AS ReservationDocuments
	|			WHERE
	|				CashToBePaid.PaymentRequest = ReservationDocuments.ReservationDocument)
	|	AND CashToBePaid.Recorder REFS Document.CashVoucher
	|
	|GROUP BY
	|	CashToBePaid.PaymentRequest,
	|	CashToBePaid.Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	CashToBePaid.PaymentRequest,
	|	CashToBePaid.Recorder,
	|	SUM(CashToBePaid.Sum)
	|FROM
	|	AccumulationRegister.CashToBePaid AS CashToBePaid
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				ReservationDocuments AS ReservationDocuments
	|			WHERE
	|				CashToBePaid.PaymentRequest = ReservationDocuments.ReservationDocument)
	|	AND CashToBePaid.Recorder REFS Document.BankAccountIssue
	|
	|GROUP BY
	|	CashToBePaid.PaymentRequest,
	|	CashToBePaid.Recorder
	|
	|INDEX BY
	|	ReservationDocument,
	|	Document");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "ReservationDocuments");
	
	QueriesTexts.Add("
	|SELECT
	|	NestedQuery.ReservationDocument AS ReservationDocument,
	|	MAX(NestedQuery.Sum) AS BaseAmount
	|INTO ReservationDocuments_AmountOfDatabase
	|FROM
	|	(SELECT
	|		AmountOfFactAccordingToReservationDocuments.ReservationDocument AS ReservationDocument,
	|		SUM(AmountOfFactAccordingToReservationDocuments.Sum) AS Sum
	|	FROM
	|		AmountOfFactAccordingToReservationDocuments AS AmountOfFactAccordingToReservationDocuments
	|	
	|	GROUP BY
	|		AmountOfFactAccordingToReservationDocuments.ReservationDocument
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AmountsAccordingToReservationDocuments.ReservationDocument,
	|		AmountsAccordingToReservationDocuments.Sum
	|	FROM
	|		AmountsAccordingToReservationDocuments AS AmountsAccordingToReservationDocuments) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ReservationDocument
	|
	|INDEX BY
	|	ReservationDocument");

	QueriesTexts.Add("
	|SELECT
	|	AmountOfFactAccordingToReservationDocuments.ReservationDocument AS ReservationDocument,
	|	AmountOfFactAccordingToReservationDocuments.Document AS Document,
	|	AmountOfFactAccordingToReservationDocuments.Sum AS Base,
	|	ISNULL(SUM(ReservationDocuments_Previous.Sum), 0) AS BaseAccumulated
	|INTO ReservationDocuments_Coefficients
	|FROM
	|	AmountOfFactAccordingToReservationDocuments AS AmountOfFactAccordingToReservationDocuments
	|		LEFT JOIN AmountOfFactAccordingToReservationDocuments AS ReservationDocuments_Previous
	|		ON AmountOfFactAccordingToReservationDocuments.ReservationDocument = ReservationDocuments_Previous.ReservationDocument
	|			AND AmountOfFactAccordingToReservationDocuments.Document > ReservationDocuments_Previous.Document
	|
	|GROUP BY
	|	AmountOfFactAccordingToReservationDocuments.ReservationDocument,
	|	AmountOfFactAccordingToReservationDocuments.Document,
	|	AmountOfFactAccordingToReservationDocuments.Sum
	|
	|INDEX BY
	|	ReservationDocument");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "AmountOfFactAccordingToReservationDocuments");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "AmountsAccordingToReservationDocuments");
	
	QueryText = "
	|SELECT
	|	LimitReserves.LimitationPeriod AS LimitationPeriod,
	|	LimitReserves.LimitsRule AS LimitsRule,
	|	LimitReserves.Organization AS Organization,
	|	LimitReserves.Currency AS Currency,
	|	LimitReserves.Department AS Department,
	|	&TextAnalyst,
	|	LimitReserves.ReservationDocument AS ReservationDocument,
	|	LimitReserves.ApplicationAmount AS ApplicationAmount
	|INTO LimitReserves
	|FROM
	|	AccumulationRegister.LimitsByBudgetingData AS LimitReserves
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				ReservationDocuments_AmountOfDatabase AS ReservationDocuments_AmountOfDatabase
	|			WHERE
	|				LimitReserves.Recorder = ReservationDocuments_AmountOfDatabase.ReservationDocument)
	|
	|INDEX BY
	|	ReservationDocument";
	TextAnalyst = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalyst = TextAnalyst + ?(TextAnalyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString("LimitReserves.Dimension%1 AS Dimension%1", DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextAnalyst", TextAnalyst);
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	LimitReserves.LimitationPeriod AS LimitationPeriod,
	|	LimitReserves.LimitsRule AS LimitsRule,
	|	LimitReserves.Organization AS Organization,
	|	LimitReserves.Currency AS Currency,
	|	LimitReserves.Department AS Department,
	|	&TextAnalyst,
	|	LimitReserves.ReservationDocument AS ReservationDocument,
	|	ReservationDocuments_Coefficients.Document AS Document,
	|	&AmountDistribution_ApplicationAmount * (-1) AS ApplicationAmount
	|INTO TableOfReverseReservesLimits
	|FROM
	|	LimitReserves AS LimitReserves
	|		LEFT JOIN ReservationDocuments_Coefficients AS ReservationDocuments_Coefficients
	|		ON LimitReserves.ReservationDocument = ReservationDocuments_Coefficients.ReservationDocument
	|		LEFT JOIN ReservationDocuments_AmountOfDatabase AS ReservationDocuments_AmountOfDatabase
	|		ON LimitReserves.ReservationDocument = ReservationDocuments_AmountOfDatabase.ReservationDocument";
	QueryText = StrReplace(QueryText, "&TextAnalyst", TextAnalyst);
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"LimitReserves.ApplicationAmount",
		"ISNULL(ReservationDocuments_Coefficients.Base, 0)",
		"ISNULL(ReservationDocuments_Coefficients.BaseAccumulated, 0)",
		"ISNULL(ReservationDocuments_AmountOfDatabase.BaseAmount, 0)");
	QueriesTexts.Add(StrReplace(QueryText, "&AmountDistribution_ApplicationAmount", AmountDistributionText));
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "ReservationDocuments_AmountOfDatabase");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "ReservationDocuments_Coefficients");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "LimitReserves");
	
	#EndRegion
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("DocumentsForProcessing_", DocumentsForProcessing_);
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	Query.ExecuteBatch();
	
	QueriesTexts.Clear();
	
	QueryText = "
	|SELECT
	|	LimitsByBudgetingData.Period AS Period,
	|	LimitsByBudgetingData.LimitsRule AS LimitsRule,
	|	CASE
	|		WHEN Documents_Coefficients.Date IS NULL
	|			THEN LimitsByBudgetingData.LimitationPeriod
	|		WHEN LimitsByBudgetingData.Periodicity = VALUE(Enum.Periodicity.DAY)
	|			THEN Documents_Coefficients.Date
	|		WHEN LimitsByBudgetingData.Periodicity = VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(Documents_Coefficients.Date, WEEK)
	|		WHEN LimitsByBudgetingData.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(Documents_Coefficients.Date, TENDAYS)
	|		WHEN LimitsByBudgetingData.Periodicity = VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(Documents_Coefficients.Date, MONTH)
	|		WHEN LimitsByBudgetingData.Periodicity = VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(Documents_Coefficients.Date, QUARTER)
	|		WHEN LimitsByBudgetingData.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(Documents_Coefficients.Date, HALFYEAR)
	|		ELSE BEGINOFPERIOD(Documents_Coefficients.Date, YEAR)
	|	END AS LimitationPeriod,
	|	LimitsByBudgetingData.Organization AS Organization,
	|	LimitsByBudgetingData.Department AS Department,
	|	&TextDimensionPlan,
	|	LimitsByBudgetingData.CompanyActual AS CompanyActual,
	|	LimitsByBudgetingData.DepartmentActual AS DepartmentActual,
	|	&TextAnalystFact,
	|	LimitsByBudgetingData.Currency AS Currency,
	|	UNDEFINED AS ReservationDocument,
	|	0 AS Limit,
	|	0 AS ApplicationAmount,
	|	CASE
	|		WHEN Documents_AmountOfDatabase.Document IS NULL
	|			THEN LimitsByBudgetingData.SumReal
	|		ELSE &AmountDistribution_AmountFact
	|	END AS SumReal
	|FROM
	|	TableLimitsBasedOnBudgetingData AS LimitsByBudgetingData
	|		LEFT JOIN Documents_Coefficients AS Documents_Coefficients
	|		ON (Documents_Coefficients.Document = &CurrentDocument)
	|		LEFT JOIN Documents_AmountOfDatabase AS Documents_AmountOfDatabase
	|		ON (Documents_AmountOfDatabase.Document = &CurrentDocument)
	|
	|UNION ALL
	|
	|SELECT
	|	&CheckDate,
	|	LimitsByBudgetingData.LimitsRule AS LimitsRule,
	|	LimitsByBudgetingData.LimitationPeriod AS LimitationPeriod,
	|	LimitsByBudgetingData.Organization AS Organization,
	|	LimitsByBudgetingData.Department AS Department,
	|	&TextDimensionPlan,
	|	VALUE(Catalog.Companies.EmptyRef) AS CompanyActual,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS DepartmentActual,
	|	&TextOfEmptyAnalystFact,
	|	LimitsByBudgetingData.Currency AS Currency,
	|	LimitsByBudgetingData.ReservationDocument AS ReservationDocument,
	|	0 AS Limit,
	|	LimitsByBudgetingData.ApplicationAmount AS ApplicationAmount,
	|	0 AS SumReal
	|FROM
	|	TableOfReverseReservesLimits AS LimitsByBudgetingData
	|WHERE
	|	LimitsByBudgetingData.Document = &CurrentDocument";
	TextDimensionPlan = "";
	TextAnalystFact = "";
	TextOfEmptyAnalystFact = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextDimensionPlan = TextDimensionPlan + ?(TextDimensionPlan = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString("LimitsByBudgetingData.Dimension%1 AS Dimension%1", DimensionNumber);
		TextAnalystFact = TextAnalystFact + ?(TextAnalystFact = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString("LimitsByBudgetingData.Dimension%1Real AS Dimension%1Real", DimensionNumber);
		TextOfEmptyAnalystFact = TextOfEmptyAnalystFact + ?(TextOfEmptyAnalystFact = "", "", "," + Chars.LF
			+ Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString(
			"UNDEFINED AS Dimension%1Real", DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextDimensionPlan", TextDimensionPlan);
	QueryText = StrReplace(QueryText, "&TextAnalystFact", TextAnalystFact);
	QueryText = StrReplace(QueryText, "&TextOfEmptyAnalystFact", TextOfEmptyAnalystFact);
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"LimitsByBudgetingData.SumReal",
		"ISNULL(Documents_Coefficients.Base, 0)",
		"ISNULL(Documents_Coefficients.BaseAccumulated, 0)",
		"ISNULL(Documents_AmountOfDatabase.BaseAmount, 0)");
	QueriesTexts.Add(StrReplace(QueryText, "&AmountDistribution_AmountFact", AmountDistributionText));
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TableLimitsBasedOnBudgetingData");
	
	Jobs.Sort("RecordDate");
	
	DocumentSearchStructure = New Structure("Document");
	
	ProcessedDocuments = New Array;
	IdOfUnprocessedRecord = Undefined;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("CommonModule.LimitsByBudgetingData.ReflectLimitsBasedOnBudgetingData");
	NumberOfRecordsProcessed = 0;
	
	For Each RowJob In Jobs Do
		
		If ProcessedDocuments.Find(RowJob.Document) <> Undefined Then
			NumberOfRecordsProcessed = NumberOfRecordsProcessed + 1;
			Continue;
		EndIf;
		
		CurrentDocument = RowJob.Document;
		IdOfUnprocessedRecord = RowJob.RecordID;
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.JobsOfRecordingLimitsByBudgetingData");
			LockItem.SetValue("RecordID", IdOfUnprocessedRecord);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			Parameters = ControlParametersForBudgetingLimits(CurrentDocument);
			Parameters.TempTablesManager = TempTablesManager;
			
			PerformControlOverBudgetingLimits(Parameters);
			TemporaryTablesByDocument = New Array;
			For Each TempTable In TempTablesManager.Tables Do
				TableName = TempTable.FullName;
				If StrFind(TableName, "RegisteredRecordsOfCash") > 0 Then
					TemporaryTablesByDocument.Add(TableName);
				EndIf;
			EndDo;
			TMCommonUse.DestroyTemporaryTables(TempTablesManager, TemporaryTablesByDocument);
			
			ThereIsTableOfLimits = (TempTablesManager.Tables.Find("TableLimitsBasedOnBudgetingData") <> Undefined);
			If Not ThereIsTableOfLimits Then
				NumberOfRecordsProcessed = NumberOfRecordsProcessed + 1;
				CommitTransaction();
				Continue;
			EndIf;
			
			QueryTextsForDocument = New Array;
			
			If Not FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query,
				QueryTextsForDocument, "TableLimitsBasedOnBudgetingData") Then
				
				TMCommonUse.DestroyTemporaryTables(TempTablesManager, "TableLimitsBasedOnBudgetingData");
				NumberOfRecordsProcessed = NumberOfRecordsProcessed + 1;
				CommitTransaction();
				Continue;
				
			EndIf;
			
			QueryTextsForDocument.Clear();
			
			RecordSet = AccumulationRegisters.LimitsByBudgetingData.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(CurrentDocument);
			
			If Not FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query,
				QueryTextsForDocument, "TableOfReverseReservesLimits") Then
				
				RecordSet.Load(TempTablesManager.Tables.Find(
					"TableLimitsBasedOnBudgetingData").GetData().Unload());
				RecordSet.Write();
				
				TMCommonUse.DestroyTemporaryTables(TempTablesManager, "TableLimitsBasedOnBudgetingData");
				
				NumberOfRecordsProcessed = NumberOfRecordsProcessed + RecordSet.Count();
				
			Else
				
				Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
				Query.SetParameter("CurrentDocument", CurrentDocument);
				Query.SetParameter("CheckDate", Parameters.DocumentAttributes.VerificationDates[0].LimitDate);
				
				Result = Query.ExecuteBatch();
				RecordSet.Load(Result[0].Unload());
				RecordSet.Write();
				
				NumberOfRecordsProcessed = NumberOfRecordsProcessed + RecordSet.Count();
				
				ProcessedDocuments.Add(CurrentDocument);
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
		
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			If IdOfUnprocessedRecord <> Undefined Then
				ErrorText = DeferredJobs.ExecutionErrorText(DocumentSearchStructure, RowJob, ErrorText);
			EndIf;
			IdsOfUnprocessedRecords.Insert(IdOfUnprocessedRecord, ErrorText);
			
			PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, NumberOfRecordsProcessed);
			
		EndTry;
		
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, NumberOfRecordsProcessed);
		
EndProcedure

#Region EventSubscriptions

Procedure DetermineNeedForControllingLimitsBeforeWritingDocument(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not RegisterOfBudgetingLimitsIsUsed() Then
		Return;
	EndIf;

	SetPrivilegedMode(True);
	
	If Source.Posted And WriteMode = DocumentWriteMode.Posting Then
		
		AttributesNotToCheck = New Structure;
		AttributesNotToCheck.Insert("Comment");
		If TypeOf(Source) = Type("DocumentObject.PaymentRequest")
			Or TypeOf(Source) = Type("DocumentObject.ApplicationForBusinessTrip") Then
			AttributesNotToCheck.Insert("WhoDecided");
			CurrentStatus = Source.Status;
			InitialStatus = Common.ObjectAttributeValue(Source.Ref, "Status");
			CheckedStatuses = New Array;
			CheckedStatuses.Add(Enums.StatusesOfPaymentRequests.IsRejected);
			CheckedStatuses.Add(Enums.EmployeeApplicationStatuses.IsRejected);
			CheckedStatuses.Add(Enums.EmployeeApplicationStatuses.Withdrawn);
			If CheckedStatuses.Find(CurrentStatus) = Undefined And CheckedStatuses.Find(InitialStatus)
				= Undefined Then
				AttributesNotToCheck.Insert("Status");
			EndIf;
		EndIf;
		
		UnverifiableTableParts = New Structure;
		UnverifiableTableParts.Insert("AdditionalAttributes");
		If TypeOf(Source) = Type("DocumentObject.PaymentRequest") Then
			UnverifiableTableParts.Insert("ReferenceDocuments");
			UnverifiableTableParts.Insert("ContractsWithCustomers");
		EndIf;
		If TypeOf(Source) = Type("DocumentObject.PaymentRequest")
			Or TypeOf(Source) = Type("DocumentObject.BankAccountIssue") Then
			UnverifiableTableParts.Insert("InstructionsForBank");
		EndIf;
		
		DocumentChanges = TMCommonUse.DocumentChanges(Source, AttributesNotToCheck, UnverifiableTableParts);
		
		If DocumentChanges.Count() = 0 Then
			Source.AdditionalProperties.Insert("IgnoreLimitControlBasedOnBudgetingData", True);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion