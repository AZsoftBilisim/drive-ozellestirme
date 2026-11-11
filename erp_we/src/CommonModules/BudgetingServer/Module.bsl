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
			Or Not Document.AdditionalProperties.DeferredPosting Then
			Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.BudgetTurnovers);
		EndIf;
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.NonFinancialItemValues);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.OpeningBalanceOfEstimates);
		Parameters.ThereAreDerivedMotions = True;
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
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
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "BudgetTurnovers");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "NonFinancialItemValues");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "OpeningBalanceOfEstimates");
	
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

// Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export


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
	
	If TypeOf(Document) = Type("DocumentObject.InventoryConsumptionPlan")
		Or TypeOf(Document) = Type("DocumentObject.PurchasePlan")
		Or TypeOf(Document) = Type("DocumentObject.PlanOfGoodsStock")
		Or TypeOf(Document) = Type("DocumentObject.SalesPlan")
		Or TypeOf(Document) = Type("DocumentObject.SalesPlanByCategories")
		Or TypeOf(Document) = Type("DocumentObject.ProductionPlan")
		And Not Common.ObjectAttributeValue(Document.Scenario, "UseForMaterialsPlanning")
		Or TypeOf(Document) = Type("DocumentObject.AssemblyDisassemblyPlan") Then
		
		If ValueIsFilled(Document.BudgetingScenario) Then
			InformationRegisters.JobsForPostingPlanningDocumentsInBudgeting.AddJob(Document.Ref);
			InformationRegisters.JobsForPostingPlanningDocumentsInBudgeting.RunJob();
		EndIf;
	
	ElsIf TypeOf(Document) = Type("DocumentObject.BudgetEntryForm") Then
		If Common.ObjectAttributeValue(Document.BudgetProfile, "GenerateRelatedBudgetTurnovers") Then
			UniversalQueueOfRealTimeJobs.ProcessTask_(Document.Ref,
				Enums.UniversalQueueTasks.GenerationOfRelatedBudgetTurnovers);
		EndIf;
	EndIf;
	
EndProcedure


#EndRegion

#Region ConvertingAnalyticsTypes

// Returns an indication that the dimension is considered an analysis by dimension type
//
// Parameters:
// 	TypeOfMeasurementValue - TypeDescription - A description of the types of Analytics
// 	DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Link to PVC Analyticsintelligent.
//
// Returns:
// 	Boolean - True if the measurement is analytics.
//
Function ThisIsAnalyticsDimension(TypeOfMeasurementValue, DimensionKind = Undefined) Export
	
	ThisIsAnalyticsDimension = True;
	
	If TypeOf(DimensionKind) = Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions") Then
		ThisIsAnalyticsDimension = True;
	ElsIf TypeOfMeasurementValue = AllTypesOfAnalytics() Then
		ThisIsAnalyticsDimension = True;
	Else
		AllTypesOfAnalytics = AllTypesOfAnalytics();
		Types = TypeOfMeasurementValue.Types();
		For Each TypeOfAnalytics In Types Do
			If TypeOfAnalytics = Type("CatalogRef.Companies") Then
				ThisIsAnalyticsDimension = False;
				Break;
			ElsIf TypeOfAnalytics = Type("CatalogRef.BusinessStructure") Then
				ThisIsAnalyticsDimension = False;
				Break;
			ElsIf TypeOfAnalytics = Type("CatalogRef.BudgetingScenarios") Then
				ThisIsAnalyticsDimension = False;
				Break;
			ElsIf TypeOfAnalytics = Type("CatalogRef.Currencies") Then
				ThisIsAnalyticsDimension = False;
				Break;
			ElsIf Not AllTypesOfAnalytics.ContainsType(TypeOfAnalytics) Then
				ThisIsAnalyticsDimension = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return ThisIsAnalyticsDimension;
	
EndFunction

// Returns an empty value expression.
//
// Returns:
// 	String - Expression of the analytics value for the query.
//
Function ExpressingEmptyValue() Export
	Return "Undefined";
EndFunction

// Returns a description of the types of all types of budgeting Analytics
//
// Returns:
// 	TypeDescription - description of the types of all types of values of budgeting analytics.
//
Function AllTypesOfAnalytics() Export
	Return Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.Type;
EndFunction

// Returns an expression of the dimension value with a check value type
//
// Parameters:
// 	SourceExpression - String - Expression of the source of the Analytics value. For example, the query / table field that the Analytics value is taken from.
// 				If the source expression is empty, the analysis expression returns an empty analysis expression. Not filled in by default.
// 	DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - to generate an expression for the SKD, you need an analysis view.
//
// Returns:
// 	String - Expression of the analytics value for the query, with a value type check.
//
Function ExpressingAnalyticsValueBySourceAndType(SourceExpression = "", DimensionKind = Undefined) Export
	
	If Not ValueIsFilled(SourceExpression)
	 Or Not ValueIsFilled(DimensionKind) Then
		ResultingExpression = ExpressingEmptyValue();
	Else
		ResultingExpression = "
			|CASE 
			// Casting Empty to an Undefined value - Null, Undefined, Empty Link
			|	WHEN NOT ValueIsFilled(&DimensionValue) THEN &EmptyAnalytics
			// Checking whether the value matches the expected type
			|	WHEN NOT VALUETYPE(&DimensionValue) IN (BudgetingCached.TypesOfAnalyticsType(""&Guido"")) THEN &EmptyAnalytics
			// After all the checks, you can use the value of the field
			|	ELSE &DimensionValue
			|END";
		ResultingExpression = StrReplace(ResultingExpression, "&DimensionValue", SourceExpression);
		ResultingExpression = StrReplace(ResultingExpression, "&Guido",
				TargetValueMonitoring.UniqueIDPerLine(DimensionKind.UUID()));
		ResultingExpression = StrReplace(ResultingExpression, "&EmptyAnalytics", ExpressingEmptyValue());
	EndIf;
	
	Return ResultingExpression;
EndFunction

// Returns an expression of the dimension value with a check value type
//
// Parameters:
// 	SourceExpression - String - Expression of the source of the Analytics value. For example, the query / table field that the Analytics value is taken from.
// 				If the source expression is empty, the analysis expression returns an empty analysis expression. Not filled in by default.
// 	ExpressionSourceOfAnalyticsView - String - Expression of the source of the Analytics view.
// 				If the source expression is empty, the analysis expression returns an empty analysis expression. Not filled in by default.
//
// Returns:
// 	String - Expression of the analytics value for the SKD, with a value type check.
//
Function ExpressingAnalyticsValueBySourceAndTypeOfAnalytics(SourceExpression = "", ExpressionSourceOfAnalyticsView = "") Export
	
	TypeControlRequired = ValueIsFilled(ExpressionSourceOfAnalyticsView) 
		And ValueIsFilled(SourceExpression) 
		And Not Upper(SourceExpression) = "UNDEFINED";
	
	If TypeControlRequired Then
		ExpressionWithTypeControl = "
			|CASE 
			// Casting Empty to an Undefined value - Null, Undefined, Empty Link
			|	WHEN NOT ValueIsFilled(&DimensionValue) THEN &EmptyAnalytics
			// Checking whether the value matches the expected type
			|	WHEN NOT VALUETYPE(&DimensionValue) IN (BudgetingCached.TypesOfAnalyticsType(ISNULL(&DimensionKind, UNDEFINED))) THEN &EmptyAnalytics
			// After all the checks, you can use the value of the field
			|	ELSE &DimensionValue
			|END";
		ExpressionWithTypeControl = StrReplace(ExpressionWithTypeControl, "&DimensionValue", SourceExpression);
		ExpressionWithTypeControl = StrReplace(ExpressionWithTypeControl, "&DimensionKind", ExpressionSourceOfAnalyticsView);
		ExpressionWithTypeControl = StrReplace(ExpressionWithTypeControl, "&EmptyAnalytics", ExpressingEmptyValue());
	Else
		ExpressionWithTypeControl = SourceExpression;
	EndIf;
	
	Return ExpressionWithTypeControl;
EndFunction

// Returns a template of parameters for the Textpolyaanalyticconditionspokolitiesviewanalytics function.
//
// Returns:
// 	Structure - the structure of the parameters. Structure Description See TextOfAnalyticsFieldWithConditionForNumberOfTypesOfAnalytics.
//
Function TemplateForAnalyticsFieldParametersWithConditionForNumberOfAnalyticsTypes() Export
	
	Parameters = New Structure;
	
	// For the following expressions, the analytics index is not specified!
	Parameters.Insert("ExpressionNumberOfAnalyticsUsed", ""); // expression of the table name type.The article shows the name of the table.The quantity of the analyst used
	Parameters.Insert("ExpressingAnalyticsValueWithoutIndex",    ""); // expression is the path to the field storing the analytics value
	
	Parameters.Insert("AnalyticsBroadcastParameters",            New Structure);
	Parameters.AnalyticsBroadcastParameters.Insert("BroadcastAnalyticsIsPossible",       False);
	
	// For the following expressions, the analytics index is not specified!
	Parameters.AnalyticsBroadcastParameters.Insert("HowToBroadcastAnalyticsWithoutIndex",   ""); // expression of the type of connectionreferences.Broadcast Analytics
	Parameters.AnalyticsBroadcastParameters.Insert("AnalyticsAddressExpressionWithoutIndex", ""); // expression of the type of connectionreferences.Addresstranslationsanalysts
	Parameters.AnalyticsBroadcastParameters.Insert("ExpressingAnalyticsValueWhenBroadcastingWithoutIndex", "");
	
	Return Parameters;
	
EndFunction

// Returns an expression for the analytics field with a condition based on the total number of analytics types used
// and other conditions that can be optionally set by parameters. In general, the expression looks like this:
//          CHOICE
//                WHEN the expression number is used by the analyst >= [Number of running analytics]
//                   <And NOT an expressiontranslate the analysis of the NON-index[Number of running analytics]>
//                         THEN the Value expressionanalyticsindex[Number of running analytics]
//                WHEN the expression number is used by the analyst >= [Number of running analytics]
//                   <And the expression to translate the analysis of the Index[Number of running analytics]
//                    And expressionadtranslationanalyticsindex[Running Analytics number] = [Addresstranslationanalysts =
//                    1] THEN the expression of the meaning of the analysistranslation of the index[Addresstranslationanalysts = 1]>
//                ...
//                ...
//                WHEN the expression number is used by the analyst >= [CurrentNomerAnalytics]
//                   <And the expression to translate the analysis of the Index[Number of running analytics]
//                    And expressionadtranslationanalyticsindex[Running Analytics number] = [Addresstranslationanalysts =
//                    6] THEN the expression of the value of the analyst and the translationindicationbezindex[Adresstranslationanalysts = 6]>
//                OTHERWISE IT IS UNCERTAIN
//          THE END
//
// Parameters:
// 	Parameters - Structure - parameter structure:
// 	 *ExpressionNumberOfAnalyticsUsed - String - Expression of the table name type.The article is indicative of the Table name.The quantity of analyst used.
// 						For example, "Data.Article budgets.The number of used analyst" or "connectionindicators.The quantity of analyst used."
// 	 *ExpressingAnalyticsValueWithoutIndex - String - Expression of the analytics value. For example, the link of indicators.Analytics%% of the current analytics number.
// 	 *AnalyticsBroadcastParameters - Structure - Structure of analytics translation parameters:
// 	    **BroadcastAnalyticsIsPossible - Boolean - If True, then it is possible to broadcast analytics, then filling in the parameters is required.
// 	    					The expression is to broadcast the analysis of the Index and the expression is to retranslate the analysis of the index.
// 	    **HowToBroadcastAnalyticsWithoutIndex - String - Expression of the path to the field describing the need for translation.
// 	    					For example, "Svyazypreferences.Broadcast Analytics%The current analytics number is %."
// 	    **AnalyticsAddressExpressionWithoutIndex - String - Expression of the path to the floor, describing which field
// 	    					to broadcast analytics from. For example, "Addresstranslationanalysts%The current analytics number is %."
// 	    **ExpressingAnalyticsValueWhenBroadcastingWithoutIndex - String - Expression of the path to the field that stores
// 	    					the analytics value during the broadcast. There can be 6 such fields of analytics values,
// 	    					depending on the broadcast address, the required field is taken.
// 	    					For example, "Turnover budgets.Analytics%Addresstranslationanalysts %".
// 	CurAnalyticsNumber - Number - The number of the analysis that the expression is being created for.
//
// Returns:
// 	String - Expression for the request field / SKD.
//
Function TextOfAnalyticsFieldWithConditionForNumberOfTypesOfAnalytics(Parameters, CurAnalyticsNumber) Export
	
	ExpressionNumberOfAnalyticsUsed = Parameters.ExpressionNumberOfAnalyticsUsed;
	ExpressingAnalyticsValueWithoutIndex = Parameters.ExpressingAnalyticsValueWithoutIndex;
	BroadcastAnalyticsIsPossible = Parameters.AnalyticsBroadcastParameters.BroadcastAnalyticsIsPossible;
	HowToBroadcastAnalyticsWithoutIndex = Parameters.AnalyticsBroadcastParameters.HowToBroadcastAnalyticsWithoutIndex;
	AnalyticsAddressExpressionWithoutIndex = Parameters.AnalyticsBroadcastParameters.AnalyticsAddressExpressionWithoutIndex;
	ExpressingAnalyticsValueWhenBroadcastingWithoutIndex = Parameters.AnalyticsBroadcastParameters.ExpressingAnalyticsValueWhenBroadcastingWithoutIndex;
	
	ThereAreErrorsInParameters = False;
	
	If Not ValueIsFilled(ExpressionNumberOfAnalyticsUsed) Then
		ThereAreErrorsInParameters = True;
	EndIf;
	If Not ValueIsFilled(ExpressingAnalyticsValueWithoutIndex) Then
		ThereAreErrorsInParameters = True;
	EndIf;
	If Not ValueIsFilled(CurAnalyticsNumber) Then
		ThereAreErrorsInParameters = True;
	EndIf;
	If BroadcastAnalyticsIsPossible Then
		If Not ValueIsFilled(HowToBroadcastAnalyticsWithoutIndex) Then
			ThereAreErrorsInParameters = True;
		EndIf;
		If Not ValueIsFilled(AnalyticsAddressExpressionWithoutIndex) Then
			ThereAreErrorsInParameters = True;
		EndIf;
		If Not ValueIsFilled(ExpressingAnalyticsValueWhenBroadcastingWithoutIndex) Then
			ThereAreErrorsInParameters = True;
		EndIf;
	EndIf;
	
	If ThereAreErrorsInParameters Then
		LanguageCode = Common.DefaultLanguageCode();
		ErrorText = NStr("vi = 'Có lỗi trong các tham số đã truyền';
						|ru = 'Есть ошибки в переданных параметрах';
						|en = 'There are errors in passed parameters.'; fa = 'There are errors in passed parameters.';
						|it = 'Ci sono errori nei parametri passati';
						|pl = 'Są błędy w przekazanych parametrach';
						|tr = 'Transfer edilen parametrelerde hata mevcut'", LanguageCode);
		LREvent = NStr("vi = 'Nhận giá trị biểu thức kích thước ngân sách';
						|ru = 'Получение выражения значения аналитики бюджетирования';
						|en = 'Receive budgeting dimension expression value'; fa = 'Receive budgeting dimension expression value';
						|it = 'Ottenimento dell''espressione del valore dell''analitica di budgeting';
						|pl = 'Pobieranie wyrażenia wartości analityki budżetowania';
						|tr = 'Bütçeleme boyut değeri ifadesinin alımı'", LanguageCode);
		WriteLogEvent(LREvent,
			EventLogLevel.Error,,,
			ErrorText);
		Raise ErrorText;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	Expression = "CASE"; //@Query-part
	
	If Not BroadcastAnalyticsIsPossible Then
		
		PartOfExpression =
		"  WHEN %ExpressionNumberOfAnalyticsUsed% >= %CurAnalyticsNumber%
		|			THEN %ExpressingAnalyticsValueWithoutIndex%%CurAnalyticsNumber%";
		
		Expression = Expression + Chars.LF + PartOfExpression;
		
	Else
		
		PartOfExpression =
		"  WHEN %ExpressionNumberOfAnalyticsUsed% >= %CurAnalyticsNumber%
		|		AND NOT %HowToBroadcastAnalyticsWithoutIndex%%CurAnalyticsNumber%
		|			THEN %ExpressingAnalyticsValueWithoutIndex%%CurAnalyticsNumber%";
		
		Expression = Expression + Chars.LF + PartOfExpression;
		
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			
			PartOfExpression =
			"  WHEN %ExpressionNumberOfAnalyticsUsed% >= %CurAnalyticsNumber%
			|		AND %HowToBroadcastAnalyticsWithoutIndex%%CurAnalyticsNumber%
			|		AND %AnalyticsAddressExpressionWithoutIndex%%CurAnalyticsNumber% = %DimensionTranslationAddress%
			|			THEN %ExpressingAnalyticsValueWhenBroadcastingWithoutIndex%%DimensionTranslationAddress%";
			
			PartOfExpression = StrReplace(PartOfExpression, "%DimensionTranslationAddress%", DimensionNumber);
			
			Expression = Expression + Chars.LF + PartOfExpression;
			
		EndDo;
		
	EndIf;
	
	PartOfExpression = 
	"  ELSE %ExpressingEmptyValue% 
	| END";
	
	Expression = Expression + Chars.LF + PartOfExpression;
	
	Expression = StrReplace(Expression, "%ExpressionNumberOfAnalyticsUsed%", ExpressionNumberOfAnalyticsUsed);
	Expression = StrReplace(Expression, "%CurAnalyticsNumber%", CurAnalyticsNumber);
	Expression = StrReplace(Expression, "%ExpressingAnalyticsValueWithoutIndex%", ExpressingAnalyticsValueWithoutIndex);
	Expression = StrReplace(Expression, "%HowToBroadcastAnalyticsWithoutIndex%", HowToBroadcastAnalyticsWithoutIndex);
	Expression = StrReplace(Expression, "%AnalyticsAddressExpressionWithoutIndex%", AnalyticsAddressExpressionWithoutIndex);
	Expression = StrReplace(Expression, "%ExpressingAnalyticsValueWhenBroadcastingWithoutIndex%", ExpressingAnalyticsValueWhenBroadcastingWithoutIndex);
	Expression = StrReplace(Expression, "%ExpressingEmptyValue%", ExpressingEmptyValue());
	
	Return Expression;
	
EndFunction

// Returns a template of parameters for the textpolarcondition function of the video Analytics Function
//
// Returns:
// 	Structure - the structure of the parameters. Structure Description See TextOfFieldWithConditionByTypeOfAnalytics.
//
Function TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics() Export
	Parameters = New Structure;
	Parameters.Insert("ExpressionNumberOfAnalyticsUsed", "");
	Parameters.Insert("ExpressionViewAnalyticsWithoutIndex", "");
	Parameters.Insert("ExpressingAnalyticsValueWithoutIndex", "");
	Parameters.Insert("NameOfAnalyticsViewParameter", "");
	
	Parameters.Insert("ExpressingEmptyValue", ""); // Only for auxiliary expressions of selection by analytics.
	
	Return Parameters;
EndFunction

// Returns the text of the field for defining Analytics by type
//
// Parameters:
// 	Parameters  - Structure - parameter structure:
// 	 *ExpressionNumberOfAnalyticsUsed - String - Expression of the table name type.The article is indicative of the Table name.The quantity of analyst used.
// 					For example, "Data.Article budgets.The quantity of analyst used."
// 	 *ExpressionViewAnalyticsWithoutIndex - String - The expression is the path to the analytics view, set without an index. Type "Data.Article budgets.Vidanalysts".
// 	 *ExpressingAnalyticsValueWithoutIndex - String - Expression of the analytics value. For example, the link of indicators.Analytics%% of the current analytics number.
// 	 *NameOfAnalyticsViewParameter - String - The Name of the Parameter to Be Passed to the request or DCS, the Link to the PVC.Analyticistate budgets.
//
// Returns:
// 	String - the "CHOICE" construct for substitution in the SCD or a query for the field of the type of analytics.
//
Function TextOfFieldWithConditionByTypeOfAnalytics(Parameters) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	Expression =
	"CASE"; //@Query-part
	
	For CurAnalyticsNumber = 1 To MaximumNumberOfAnalysts Do
		
		PartOfExpression =
		"  WHEN %ExpressionNumberOfAnalyticsUsed% >= %CurAnalyticsNumber%
		|		AND %ExpressionViewAnalyticsWithoutIndex%%CurAnalyticsNumber% = %AnalyticsViewParameter%
		|			THEN %ExpressingAnalyticsValueWithoutIndex%%CurAnalyticsNumber%";
		
		PartOfExpression = StrReplace(PartOfExpression, "%CurAnalyticsNumber%", CurAnalyticsNumber);
		Expression = Expression + Chars.LF + PartOfExpression;
	
	EndDo;
	
	PartOfExpression =
	"  ELSE %ExpressingEmptyValue% 
	| END";
	
	ExpressingEmptyValue = Parameters.ExpressingEmptyValue;
	If Not ValueIsFilled(ExpressingEmptyValue) Then
		PartOfExpression = StrReplace(PartOfExpression, "%ExpressingEmptyValue%", ExpressingEmptyValue());
	Else
		// Only for auxiliary expressions of selection by analytics.
		PartOfExpression = StrReplace(PartOfExpression, "%ExpressingEmptyValue%", ExpressingEmptyValue);
	EndIf;
	
	Expression = Expression + Chars.LF + PartOfExpression;
	
	AnalyticsViewParameter = "&" + Parameters.NameOfAnalyticsViewParameter;
	
	Expression = StrReplace(Expression, "%ExpressionNumberOfAnalyticsUsed%", Parameters.ExpressionNumberOfAnalyticsUsed);
	Expression = StrReplace(Expression, "%ExpressionViewAnalyticsWithoutIndex%", Parameters.ExpressionViewAnalyticsWithoutIndex);
	Expression = StrReplace(Expression, "%ExpressingAnalyticsValueWithoutIndex%", Parameters.ExpressingAnalyticsValueWithoutIndex);
	Expression = StrReplace(Expression, "%AnalyticsViewParameter%", AnalyticsViewParameter);
	
	Return Expression;
	
EndFunction

#EndRegion

// Returns parameters for getting the default fact
//
// Returns:
//	Structure - Parameters for getting facts by items and budget metrics with properties:
//		*ReportCurrency - CatalogRef.Currencies - Data currency.
//		*FunctionalCurrency - EnumRef.AccountingKindsInFunctionalCurrency - The cached value of the functional currency
//		*InternationalCurrency - CatalogRef.Currencies - The cached value of the functional currency of international accounting (See FinancialAccountingOfGeneralPurpose.AccountingCurrencies) 
//		*Period - StandardPeriod - Sampling period.
//		*Periodicity - EnumRef.Periodicity, Undefined - Frequency of data detailing for the period. Undefined - no details.
//		*BalancesOnlyAtBeginningOfPeriod - Boolean - Get the fact only at the beginning of the period (for balances),
//			otherwise the data is received at the end of each of the sub-periods.
//			The default value is False.
//		*ReturnManAndLocalAmounts - Boolean - Return amounts from the UPR and regl registers.
//			The default value is False.
//		*DataAcquisitionRules - Boolean - add a column with the applied rule to the data table.
//			The default value is False.
//		*Indicators - Structure - indicators that are automatically selected based on the settings of the source data set:
//			**Count - Arbitrary - the presence of the property in the structure means that you should add getting the quantity to the selection
//			**Sum - Arbitrary - the presence of the property in the structure means that you should add getting the amount to the selection
//		*AddStoredFactForItemsThatAffectBudgetPerformance - Boolean - Supplement the fact for articles that affect indicators with a stored fact.
//				By default, True. False - if the entire stored fact is obtained separately (using cached SKDS).
//				The stored fact is supplemented directly in standard budgeting reports.
//		*DimensionKinds - Array of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Analytics (Nomenclature, Contractors...), in the context of which you need to get the fact.
//		*ByCompanies - Boolean - To deploy to organizations. The default value is False.
//		*ByBusinessUnits - Boolean - Expand by Department. The default value is False.
//		*ByRegistrar - Boolean - To expand the fact to the Registrar (for speed). The default value is False.
//		*AdditionalSelection - Structure - Additional (to the main selection of the rule) selection, which is superimposed on the source data:
//			**Key - Arbitrary - the name of the field on which you want to apply additional selection
//			**Value - Arbitrary - value of additional selection.
//							- DataCompositionSettings - 
//
Function TemplateForGettingFactParameters() Export
	
	Parameters = New Structure();
	
	Parameters.Insert("Period");
	Parameters.Insert("Periodicity");
	Parameters.Insert("BalancesOnlyAtBeginningOfPeriod", False);
	Parameters.Insert("ReturnManAndLocalAmounts", False);
	Parameters.Insert("DataAcquisitionRules", False);
	Parameters.Insert("ReturnBudgetIndicatorItem", False);
	
	// Data indicators
	Parameters.Insert("Indicators", New Structure("Count, Sum"));
	Parameters.Insert("AddStoredFactForItemsThatAffectBudgetPerformance", True);
	
	// Data sections
	Parameters.Insert("DimensionKinds", New Array);
	Parameters.Insert("ByCompanies", False);
	Parameters.Insert("ByBusinessUnits", False);
	Parameters.Insert("ByRegistrar", False);
	
	Parameters.Insert("AdditionalSelection");
	
	// Currencies
	Parameters.Insert("ReportCurrency");
	SetPrivilegedMode(True);
	DetailsOfChartOfAccounts = Common.ObjectAttributesValues(
		Catalogs.FinancialAccountingChartsOfAccounts.International,
		"PresentationCurrency, AccountingInFunctionalCurrency");
	If DetailsOfChartOfAccounts.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal Then
		FunctionalCurrency = Constants.LocalAccountingCurrency.Get();
	Else
		FunctionalCurrency = SettingsValueCached.ManagementAccountingCurrency();
	EndIf;
	SetPrivilegedMode(False);
	Parameters.Insert("InternationalCurrency", FunctionalCurrency);
	Parameters.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	Parameters.Insert("FunctionalCurrency", Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal);
	
	Parameters.Insert("DataReceiptMode");
	
	Return Parameters;
	
EndFunction

// Returns an empty table with typed columns, according to the specified parameters for articles.
//
// Parameters:
// 	Parameters - See BudgetingServer.TemplateForGettingFactParameters.
//
// Returns:
// 	ValueTable - an empty table with typed columns:
// 		*BudgetFlowItem - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems - Budget item.
// 		*Scenario - CatalogRef.BudgetingScenarios - the actual data scenario. Predefined elements
// 						of "budget Execution" or "actual Data".
// 		*DataSourceSection - EnumRef.SectionsOfBudgetingDataSources - operational,
// 						regulated, international accounting, or arbitrary data.
// 		*DataSource - CatalogRef.BusinessTransactionsSettings - source of operational data.
//						- ChartOfAccountsRef - source of accounting (regulated or international) accounting data.
//						- String - source of arbitrary data.
// 		*BalancedAccount - ChartOfAccountsRef - cor. source of accounting data (regulated or international).
// 		*TransactionAmountSource - EnumRef.IndicatorsOfAnalyticalRegisters - pointer to the name of a specific
// 						resource in the data source register.
// 		*TotalType - EnumRef.TypesOfTotals - total in the form of a balance or turnover (collapsed and expanded by Dt and CT).
// 		*Filter - String - LongDesc
// 		*Rule - CatalogRef.ActualDataQueryRulesByBudgetFlowItems - rule for extracting a fact
// 		*Period - Date - the date of the fact given at the beginning of the standard period.
// 						Possible periodicity values are set by the values of the Periodicity enumeration.
// 		*Recorder - DocumentRef - document RegisteredRecorded in the specified line. Only for turns.
//						Provided that the details of the registrar are enabled.
//						See TemplateForGettingFactParameters() property by registrar.
// 		*Organization - CatalogRef.Companies - The organization that the fact belongs to.
//						Provided that the organization details are enabled.
//						See TemplateForGettingFactParameters() an organization property.
// 		*Department - CatalogRef.BusinessStructure - The division to which the fact belongs.
//						Provided that the detail by division is included.
//						See TemplateForGettingFactParameters() property by divisions.
// 		*Dimension1 - Arbitrary - Type from the plan of types of characteristics "Analyticstateybudgetov" - the value of Analytics.
// 		*Dimension2 - Arbitrary - Type from the plan of types of characteristics "Analyticstateybudgetov" - the value of Analytics.
// 		*Dimension3 - Arbitrary - Type from the plan of types of characteristics "Analyticstateybudgetov" - the value of Analytics.
// 		*Dimension4 - Arbitrary - Type from the plan of types of characteristics "Analyticstateybudgetov" - the value of Analytics.
// 		*Dimension5 - Arbitrary - Type from the plan of types of characteristics "Analyticstateybudgetov" - the value of Analytics.
// 		*Dimension6 - Arbitrary - Type from the plan of types of characteristics "Analyticstateybudgetov" - the value of Analytics.
// 		*Key_UniqueIdentifierOfAnalyticsType - TypeDescription - type of Analytics.
// 		*UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - units of measurement of the quantitative indicator "Quantity".
// 		*Count - Number - value of the quantitative indicator.
// 		*StorageCurrency - CatalogRef.Currencies - the currency of the operation of the indicator "Sum" (the currency of the fact).
// 		*RatePeriod - Date - the nearest date of the currency exchange rate applied for conversion.
// 		*Sum - Number - the value of the total indicator in the currency of the fact.
// 		*Currency - CatalogRef.Currencies - the currency amount of the indicator "Somevalue".
// 		*AmountInCurrency - Number - the sum indicator" Amount", reduced to the specified currency.
// 		*SumMan - Number - amount rate in currency of the administrative account.
// 		*SumCompl - Number - the sum indicator in the currency of regulated accounting.
//
Function FactTableTemplateForBudgetItems(Parameters) Export
	
	FactTable_ = New ValueTable;
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BudgetFlowItems"));
	TypesArray.Add(Type("CatalogRef.BudgetBalanceItems"));
	
	FactTable_.Columns.Add("BudgetFlowItem", New TypeDescription(TypesArray));
	FactTable_.Columns.Add("Scenario", New TypeDescription("CatalogRef.BudgetingScenarios"));
	
	If Parameters.DataAcquisitionRules Then
		
		FactTable_.Columns.Add("DataSourceSection", New TypeDescription("EnumRef.SectionsOfBudgetingDataSources"));
		
		TypesArray = New Array;
		TypesArray.Add(Type("CatalogRef.BusinessTransactionsSettings"));
		ChartOfAccountsType = FinancialAccountingClientServer.TypeChartOfAccounts();
		If Not ChartOfAccountsType = Undefined Then
			TypesArray.Add(ChartOfAccountsType);
		EndIf;
		ChartOfAccountsType = LocalAccntingClientServer.TypeChartOfAccounts();
		If Not ChartOfAccountsType = Undefined Then
			TypesArray.Add(ChartOfAccountsType);
		EndIf;
		TypesArray.Add(Type("String"));
		DescriptionOfDataSourceTypes = New TypeDescription(TypesArray);
		
		FactTable_.Columns.Add("DataSource", DescriptionOfDataSourceTypes);
		
		TypesOfCorAccounts = New Array;
		ChartOfAccountsType = LocalAccntingClientServer.TypeChartOfAccounts();
		If Not ChartOfAccountsType = Undefined Then
			TypesOfCorAccounts.Add(ChartOfAccountsType);
		EndIf;
		ChartOfAccountsType = FinancialAccountingClientServer.TypeChartOfAccounts();
		If Not ChartOfAccountsType = Undefined Then
			TypesOfCorAccounts.Add(ChartOfAccountsType);
		EndIf;
		DescriptionOfCorAccountTypes = New TypeDescription(TypesOfCorAccounts);
		
		FactTable_.Columns.Add("BalancedAccount", DescriptionOfCorAccountTypes);
		
		FactTable_.Columns.Add("TransactionAmountSource", New TypeDescription("EnumRef.IndicatorsOfAnalyticalRegisters"));
		FactTable_.Columns.Add("TotalType", New TypeDescription("EnumRef.TypesOfTotals"));
		FactTable_.Columns.Add("Filter", New TypeDescription("String"));
		
		FactTable_.Columns.Add("Rule", New TypeDescription("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"));
		
	EndIf;
	
	TypesDetailsDate = New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date));
	If Parameters.Periodicity <> Undefined Then
		FactTable_.Columns.Add("Period", TypesDetailsDate);
	EndIf;
	
	If Parameters.Property("ThereIsPeriodicityOfSecond")
		And Parameters.ThereIsPeriodicityOfSecond Then
		FactTable_.Columns.Add("SecondPeriod",
			New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.DateTime)));
	EndIf;
	
	If Parameters.ByRegistrar Then
		FactTable_.Columns.Add("Recorder", Documents.AllRefsType());
	EndIf;
	
	If Parameters.ByCompanies Then
		FactTable_.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	EndIf;
	If Parameters.ByBusinessUnits Then
		FactTable_.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	EndIf;
	
	DescriptionOfAnalyticsTypes_ = AllTypesOfAnalytics();
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		FactTable_.Columns.Add("Dimension" + DimensionNumber, DescriptionOfAnalyticsTypes_);
	EndDo;
	For Each DimensionKind In Parameters.DimensionKinds Do
		AnalyticsViewColumn = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		FactTable_.Columns.Add(AnalyticsViewColumn, DescriptionOfAnalyticsTypes_);
	EndDo;
	
	If Parameters.Indicators.Property("Count") Then
		FactTable_.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		FactTable_.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(15,3)));
	EndIf;
	
	If Parameters.Indicators.Property("Sum") Then
		
		NumberType = TMCommonUse.MoneyFieldTypeDescription();
		
		FactTable_.Columns.Add("RatePeriod", TypesDetailsDate);
		FactTable_.Columns.Add("Sum", NumberType);
		
		FactTable_.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
		FactTable_.Columns.Add("AmountInCurrency", NumberType);	
		
		If Parameters.ReturnManAndLocalAmounts Then
			FactTable_.Columns.Add("SumMan", NumberType);
			FactTable_.Columns.Add("SumCompl", NumberType);
			FactTable_.Columns.Add("Comment", New TypeDescription("String"));
		EndIf;
		
		FactTable_.Columns.Add("StorageCurrency", New TypeDescription("CatalogRef.Currencies"));
		FactTable_.Columns.Add("AmountInStorageCurrency", NumberType);
		FactTable_.Columns.Add("CurrencyFunctional", New TypeDescription("CatalogRef.Currencies"));
		FactTable_.Columns.Add("AmountInFunctionalCurrency", NumberType);
	EndIf;
	
	Return FactTable_;
	
EndFunction

// Returns the default parameters for currency conversion
// 
// Returns:
//	Structure - calculation parameters that determine the method of conversion from one currency to another:
//	  *NameOfSourceDataSet - String - name of the data set to be recalculated and contains the sum fields.
//	  *SourceOfExchangeRates - String - name of the information register with currency exchange rates. It can take one of two values
//	  				: "currency exchange Rate" or "forecast rate Scenarios". Currency exchange rate (default) - actual exchange rates.
//	  				Prognosesenteret - forecast exchange rates budgeting. In this case, you need to specify
//	  				which scenario to choose courses for.
//	  *SourceCurrency - CatalogRef.Currencies - the currency from which you want to recalculate the amounts in the table.
//	  			- String - the name of the column with the Reference Link type.The currency that contains the values of the source
//	  				currency for each row.
//	  			- Undefined - (by default) - a column with the name "Source Currency" will be searched.
//	  				If the column is missing, recalculation will not be performed.
//	  *ConversionColumns - Array of String - Array of column names containing the original amounts.
//	  			- String - name of the column to recalculate
//	  			- Undefined - (by default) - a search will be performed for columns with the names "Sum",
//	  				"Sum-input", "Sum-output", "Sum-currency", "Sum-input", "Sum-output", "Indicator value".
//	  *ConversionDataSetNumber - Number - the conversion data set number is intended for multiple
//	  				conversions in the same schema. The default value is 1.
//	  *RatePeriod - Date - the date on which the recalculation is to be performed.
//	  			- String - the name of the column with the Date type, which contains the values of the course dates for each row.
//	  			- Undefined - (by default) - the column with the name "Course period" will be searched.
//	  				If the column is missing, the date of the course will be equated to today.
//	  *ForecastRateScenario - CatalogRef.BudgetingScenarios - the scenario for which the forecast rates are set.
//	  			- String - the name of the field with the Reference Link type.Scripts, which contains the values
//	  				of the course script for each row.
//	  			- Undefined - (default) - the column named "Script"will be searched for.
//	  				If the column is missing, the recalculation will not be performed.
//	  *TargetCurrency - CatalogRef.Currencies - the currency in which you want to recalculate the amounts in the table.
//	  			- String - the name of the field with the Reference Link type.Currency, which contains the target currency values for each row.
//	  			- Undefined - (by default) - a column named "Target Currency" will be searched.
//	  				If the column is missing, recalculation will not be performed.
//
Function TemplateForCurrencyConversionParameters() Export
	
	TemplateForCurrencyConversionParameters = New Structure;
	
	TemplateForCurrencyConversionParameters.Insert("NameOfSourceDataSet", "");
	TemplateForCurrencyConversionParameters.Insert("SourceOfExchangeRates", Metadata.InformationRegisters.RelativeExchangeRates.Name);
	TemplateForCurrencyConversionParameters.Insert("SourceCurrency", Undefined);
	TemplateForCurrencyConversionParameters.Insert("ConversionColumns", Undefined);
	TemplateForCurrencyConversionParameters.Insert("ConversionDataSetNumber", 1);
	TemplateForCurrencyConversionParameters.Insert("RatePeriod", Undefined);
	TemplateForCurrencyConversionParameters.Insert("ForecastRateScenario", Undefined);
	TemplateForCurrencyConversionParameters.Insert("TargetCurrency", Undefined);
	
	Return TemplateForCurrencyConversionParameters;
	
EndFunction

// Returns an empty typed configuration structure to be filled in later
// Used for interactive and non-interactive filling in source fields from the source schema 
// for each type of Analytics rule for getting actual data.
//
// Returns:
//	Structure - Parameters For Filling In Analytics:
//		*AddressOfDataCompositionSchema - String - address of the data source schema in temporary storage.
//		*SettingsComposer - DataCompositionSettingsComposer - settings based on the data source schema.
//		*UUID - UUID - ID of the form or directory element
//					that the settings are generated for.
//		*DimensionPopulationSettings - ValueTable - settings for each of the 6 analytics:
//			**DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//			**DimensionNumber - Number - The dimension number.
//			**DimensionPopulationExpression - String - the expression filling.
//			**FillInTheSpecifiedValue - Boolean - flag for filling in the specified value.
//			**DimensionValue - Arbitrary - the value of analytics.
//			**PresentationOfDimensionPopulationExpression - String - Representation of the fill expression.
//			**MissingInAvailableFields - Boolean - The checker flag.
//			**AdditionalProperty - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - additional banking details.
//
Function TemplateForAnalystFillingParameters() Export
	ParametersForFillingInAnalytics = New Structure; 
	
	DimensionPopulationSettings = New ValueTable;
	DimensionPopulationSettings.Columns.Add("DimensionKind", New TypeDescription("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions"));
	DimensionPopulationSettings.Columns.Add("DimensionNumber", Common.TypeDescriptionNumber(1));
	DimensionPopulationSettings.Columns.Add("DimensionPopulationExpression", Common.StringTypeDetails(0));
	DimensionPopulationSettings.Columns.Add("FillInTheSpecifiedValue", TMCommonUse.DescriptionOfTypesByType(Type("Boolean")));
	DimensionPopulationSettings.Columns.Add("DimensionValue", AllTypesOfAnalytics());
	DimensionPopulationSettings.Columns.Add("PresentationOfDimensionPopulationExpression", Common.StringTypeDetails(0));
	DimensionPopulationSettings.Columns.Add("MissingInAvailableFields", TMCommonUse.DescriptionOfTypesByType(Type("Boolean")));
	DimensionPopulationSettings.Columns.Add("AdditionalProperty", New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo"));
	
	ParametersForFillingInAnalytics.Insert("DimensionPopulationSettings", DimensionPopulationSettings);
	ParametersForFillingInAnalytics.Insert("AddressOfDataCompositionSchema", "");
	ParametersForFillingInAnalytics.Insert("SettingsComposer", New DataCompositionSettingsComposer);
	ParametersForFillingInAnalytics.Insert("UUID", New UUID("00000000-0000-0000-0000-000000000000"));
	
	Return ParametersForFillingInAnalytics;
EndFunction

// Returns parameters for getting default values for non-financial indicators
//
// Returns:
// 	 Structure - Parameters For Obtaining Values Of Non-Financial Indicators:
//    *DataReceiptMode - EnumRef.BudgetingDataReceiptMode - data acquisition mode.
//    *InternationalCurrency - CatalogRef.Currencies - Currency of international accounting.
//    *ComplCurrency - CatalogRef.Currencies - Currency of regulated accounting.
//    *CurrencyOfMan - CatalogRef.Currencies - currency of management accounting.
//    *AdditionalSelection - Arbitrary - An additional selection.
//    *ByBusinessUnits - Boolean - Flag for getting data by division.
//    *ByCompanies - Boolean - The flag data in the context of organizations.
//    *DimensionKinds - Array of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Types of Analytics.
//    *Periodicity - EnumRef.Periodicity - Periodicity.
//    *Period - StandardPeriod - data acquisition period.
Function TemplateForParametersForObtainingValuesOfNonFinancialIndicators() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("Period");
	Parameters.Insert("Periodicity");
	
	Parameters.Insert("DimensionKinds", New Array);
	Parameters.Insert("ByCompanies", False);
	Parameters.Insert("ByBusinessUnits", False);
	
	Parameters.Insert("AdditionalSelection");
	
	// Currencies
	Parameters.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	Parameters.Insert("ComplCurrency", Constants.LocalAccountingCurrency.Get());
	SetPrivilegedMode(True);
	DetailsOfChartOfAccounts = Common.ObjectAttributesValues(
								Catalogs.FinancialAccountingChartsOfAccounts.International,
								"PresentationCurrency, AccountingInFunctionalCurrency");
	If DetailsOfChartOfAccounts.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal Then
		FunctionalCurrency = Constants.LocalAccountingCurrency.Get();
	Else
		FunctionalCurrency = SettingsValueCached.ManagementAccountingCurrency();
	EndIf;
	Parameters.Insert("InternationalCurrency", FunctionalCurrency);
	Parameters.Insert("DataReceiptMode", Enums.BudgetingDataReceiptMode.Allowed);
	
	Return Parameters;
	
EndFunction

// Returns the configuration created by the passed schema
//
// Parameters:
// 	DataCompositionSchema - DataCompositionSchema - the schema to initialize the settings for.
//
// Returns:
// DataCompositionSettings - default settings.
//
Function InitializedDefaultSettings(DataCompositionSchema) Export
	
	SettingsComposer = DefaultInitializedComposer(DataCompositionSchema);
	
	Return SettingsComposer.GetSettings();
	
EndFunction

// Returns the settings linker created using the passed schema
//
// Parameters:
// 	DataCompositionSchema - DataCompositionSchema - the schema to initialize the settings for.
//
// Returns:
// DataCompositionSettingsComposer - default settings.
//
Function DefaultInitializedComposer(DataCompositionSchema) Export
	
	SettingsComposer = New DataCompositionSettingsComposer;
	If DataCompositionSchema <> Undefined Then
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	Return SettingsComposer;
	
EndFunction

// Returns an empty value for the corresponding dimension type 
// 
// Parameters:
//	DimensionName - String - name of the register dimension accumulation Register.Turnover of budgets.
//
// Returns:
//	Arbitrary - an empty value of the corresponding type.
// 
Function DefaultValueForMeasurement(DimensionName) Export
	DefaultValue = Undefined;
	
	If DimensionName = "Organization" Then
		DefaultValue = Catalogs.Companies.EmptyRef();
	ElsIf DimensionName = "Department" Then
		DefaultValue = Catalogs.BusinessStructure.EmptyRef();
	EndIf;
	
	Return DefaultValue;
EndFunction

// Returns a table with actual data
// The composition of columns is determined by the parameters for getting the fact.
//
// Parameters:
//	FactGettingParameters - See DataSourcesServer.TemplateForGettingFactParameters.
//
// Returns:
//	ValueTable - Actual data.
//
Function FactOfArticlesAccordingToRules(FactGettingParameters) Export
	
	#Region InitializingVariables
	
	// Parameters for obtaining actual data
	DataAcquisitionRules = FactGettingParameters.DataAcquisitionRules;
	ByCompanies = FactGettingParameters.ByCompanies;
	ByBusinessUnits = FactGettingParameters.ByBusinessUnits;
	ByRegistrar = FactGettingParameters.ByRegistrar;
	ByPeriods = FactGettingParameters.Periodicity <> Undefined;
	Periodicity = FactGettingParameters.Periodicity;
	DimensionKinds = FactGettingParameters.DimensionKinds;
	MaximumNumberOfAnalytics = FactGettingParameters.MaximumNumberOfAnalytics;
	NumberedAnalyticsUsed = FactGettingParameters.NumberedAnalyticsUsed;
	
	TableOfArticleRules  = FactGettingParameters.TableOfArticleRules;
	DataSourcesServer.SetIndexesFromArray(TableOfArticleRules);
	
	// Additional data
	AdditionalData = FactGettingParameters.AdditionalData;
	TypeOfAdditionalData = AdditionalData.Kind;
	AdditionalDataTable = AdditionalData.DataTable;
	IdFieldName = AdditionalData.IdFieldName;
	
	AdditionalDataCalculatedFields = TypeOfAdditionalData = Enums.KindOfAdditionalDataSourceInformation.CalculatedFields;
	AdditionalDataAdditionalSet = TypeOfAdditionalData = Enums.KindOfAdditionalDataSourceInformation.DataSetAdditional;
	
	UsedColumnsForData = New Array;
		
	// Period table
	PeriodsTable = FactGettingParameters.PeriodsTable;
	ColumnsOfPeriodsTable = PeriodsTable.Columns;
	
	// Identification of data sources
	ReceivedTemplates = New Map;
	DataSetsForIdentification = New Map;
	
	IdFieldName = "DataSourceID";
	
	// Data Convolution
	ColumnIds = New Array;
	ColumnsAggregates = New Array;
	
	#EndRegion 
	
	#Region ConfiguringDataSets
	
	// Create an empty schema
	FactReceiptDCS = DataCompositionServer.EmptyCircuit();
	
	// Add ND period tables
	LBTableOfPeriods = DataCompositionServer.AddEmptyDataSet(FactReceiptDCS,
		Type("DataCompositionSchemaDataSetObject"), "PeriodsTable");
		
	For Each Column In PeriodsTable.Columns Do
		FinancialReportingServer.NewSetField(LBTableOfPeriods, Column.Name, Column.Name,, Column.ValueType);
	EndDo;
	
	// Add the ND of the association
	LBUnitedFact = DataCompositionServer.AddEmptyDataSet(FactReceiptDCS, 
		Type("DataCompositionSchemaDataSetUnion"), "CombinedFact");
	
	// For each unique layout of the scheme, add a register ID and transfer the type settings.
	For Each ApplicableFactRule In TableOfArticleRules Do
		TemplateName = ApplicableFactRule.NameOfTheDataSourceTemplate;
		
		If ReceivedTemplates.Get(TemplateName) = Undefined Then
			Template = DataSourcesServer.DataLayoutRules(ApplicableFactRule.Rule,,, True);
			
			ReceivedTemplates.Insert(TemplateName, Template);
		EndIf;
	EndDo;
	
	For Each ResultingTemplate In ReceivedTemplates Do 
		DataSetName = ResultingTemplate.Key;
		InitialTemplate = ResultingTemplate.Value;
		
		// Let's move all the data sets of the sources to the combined set
		CopiedDataSets = DataCompositionServer.CopyDatasets(LBUnitedFact, InitialTemplate, DataSetName);
		
		DesiredCollectionOfSets = DataSetsForIdentification[DataSetName];
		If DesiredCollectionOfSets = Undefined Then
			
			DataSetsForIdentification.Insert(DataSetName, CopiedDataSets);
			
		Else
			
			CommonClientServer.SupplementArray(DesiredCollectionOfSets, CopiedDataSets);
			
		EndIf;
	EndDo;
	
	// We will prepare the layouts BEFORE the transfer - we will add the "Source identifier" field to them
	// , We will add the "Set Identifier" field to each set
	// For the supplied schemes - this is the name of the layout and the data source of the business operation settings
	// For arbitrary data, this is a string of the form "hash_key". 
	// The hash is used to minimize the number of arbitrary data sets. 
	// If the SKDS are identical in different rules, then there will be only one data set in the executable schema.
	For Each DataSetForIdentification In DataSetsForIdentification Do 
		SetID    = DataSetForIdentification.Key;
		SetsByID = DataSetForIdentification.Value;
		
		For Each RecruitmentById In SetsByID Do 
			SetRequest = RecruitmentById.Query;
				
			If TypeOf(RecruitmentById) = Type("DataCompositionSchemaDataSetQuery") Then
				// Adding a field to the extended layout query fields and query selection fields
				SetRequest = RequestSchemes.AddSelectionFieldToQuery(SetRequest, """" + SetID + """", IdFieldName, , True, True);
				
				SetRequest = StrReplace(SetRequest, """DataSourceID""", """" + SetID + """");
				
				RecruitmentById.Query = SetRequest;
			EndIf;
			
		EndDo;
	EndDo;
		
	#EndRegion 
	
	#Region ConfiguringBasicDataSetFields
	
	// Add parameter fields to the query text to connect to the table of periods
	FactSets = LBUnitedFact.Items;
	
	For Each PeriodTableColumn In ColumnsOfPeriodsTable Do 
		ColumnName = PeriodTableColumn.Name;
		ColumnType = PeriodTableColumn.ValueType;
		
		For Each FactSet In FactSets Do 
			If TypeOf(FactSet) = Type("DataCompositionSchemaDataSetQuery") Then
				SampleFieldExpression = "&" + ColumnName;
				
				FactSet.Query = RequestSchemes.AddSelectionFieldToQuery(FactSet.Query,
					SampleFieldExpression, ColumnName,, True, True);
			EndIf;
			
			FinancialReportingServer.NewSetField(FactSet, ColumnName, ColumnName,, ColumnType);
		EndDo;
		
		// Let's add the fields of the child sets to the root, unifying fact
		FinancialReportingServer.NewSetField(LBUnitedFact, ColumnName, ColumnName,, ColumnType);
		
		// Let's add the connection of the ND periods and the ND of the union by the parameters of the period
		DataCompositionServer.AddDataSetAssociation(FactReceiptDCS,
			LBTableOfPeriods,
			LBUnitedFact,
			ColumnName,
			ColumnName,
			ColumnName);
	EndDo;
	
	#EndRegion 
	
	#Region ConnectingAdditionalDataSource
	
	// Add additional data to the calculation fields
	AdditionalDataColumns = AdditionalDataTable.Columns;
	If AdditionalDataCalculatedFields Then
		
		// Let's collect a collection of calculated columns
		For Each AdditionalDataColumn In AdditionalDataColumns Do
			FieldName = AdditionalDataColumn.Name;
			If FieldName = "UUID"
				Or DataAcquisitionRules 
					And (FieldName = "RuleOfFact" Or FieldName = "BeginOfPeriod" Or FieldName = "EndOfPeriod") Then
				
				Continue;
			EndIf;
			UsedColumnsForData.Add(AdditionalDataColumn);
		EndDo;
		
		For Each AdditionalDataLine_ In AdditionalDataTable Do
			UUID = AdditionalDataLine_.UUID;
			
			For Each AdditionalDataColumn In UsedColumnsForData Do
				FieldName = AdditionalDataColumn.Name;
				FieldType = AdditionalDataColumn.ValueType;
				Simple = AdditionalDataLine_[FieldName];
				
				FieldNameInSchema = FieldName + "_" + UUID;
				
				// Add a parameter with the value
				DataCompositionServer.AddParameter(FactReceiptDCS, FieldNameInSchema, FieldType, Simple);
			
				// Calculate the value of the rule for groupings
				FinancialReportingServer.NewCalculatedField(FactReceiptDCS, FieldNameInSchema, "&" + FieldNameInSchema);
				
			EndDo;
		EndDo;
	ElsIf AdditionalDataAdditionalSet Then 
		LBAdditionalDataAdditionalSet = DataCompositionServer.AddEmptyDataSet(FactReceiptDCS, 
			Type("DataCompositionSchemaDataSetObject"), "AdditionalDataTable");
			
		For Each AdditionalDataColumn In AdditionalDataColumns Do
			FieldName = AdditionalDataColumn.Name;
			FieldType = AdditionalDataColumn.ValueType;
			
			FinancialReportingServer.NewSetField(LBAdditionalDataAdditionalSet, FieldName, FieldName, , FieldType);
			
			// The main mode of attaching additional data to the left is for all available columns
			If LBUnitedFact.Fields.Find(FieldName) = Undefined Then
				// "True" columns of additional data. Those for which connection is possible are already in the data sets.
				UsedColumnsForData.Add(AdditionalDataColumn);
				
				Continue;
			EndIf;
			
			// Let's add the connection of the ND periods and the ND of the union by the parameters of the period
			DataCompositionServer.AddDataSetAssociation(FactReceiptDCS, 
				LBUnitedFact, 
				LBAdditionalDataAdditionalSet,
				FieldName, 
				FieldName);
		EndDo;
	EndIf;
	
	#EndRegion 
	
	#Region ConfiguringDimensionsAndSelections
	
	// Create and initialize the linker
	Settings = BudgetingServer.InitializedDefaultSettings(FactReceiptDCS);
	
	DataCompositionClientServer.DisableOutputOfTotals(Settings);
	
	// Let's add fields common to all groupings to the root of the structure
	RootElementOfStructure = Settings.Structure;
	
	// Let's set the general parameters
	DataCompositionClientServer.SetParameter(Settings, "PrivilegedMode", False);
	DataCompositionClientServer.SetParameter(Settings, "SourcePrivilegedMode", False);
	
	// Let's add general selections
	If FactGettingParameters.AdditionalSelection <> Undefined Then
		FinancialReportingServer.CopyFilter(FactGettingParameters.AdditionalSelection.Filter, Settings.Filter, True);
	EndIf;
	
	// Let's add data pre-filtering selections for each rule
	GroupOfAdditionalSelectionsOfAllRules = FinancialReportingServer.NewFilter(Settings.Filter,
		Undefined,, Type("DataCompositionFilterItemGroup"));
	GroupOfAdditionalSelectionsOfAllRules.GroupType     = DataCompositionFilterItemsGroupType.OrGroup;
	GroupOfAdditionalSelectionsOfAllRules.Use = True;
	GroupOfAdditionalSelectionsOfAllRules.Presentation = "AdmissionOfAllRules";
	
	TotalFields = FactReceiptDCS.TotalFields;
		
	For Each PeriodAndRule In PeriodsTable Do 
		RuleSearch = New Structure("Rule", PeriodAndRule.RuleOfFact); 
		FoundRows = TableOfArticleRules.FindRows(RuleSearch);
		ApplicableRule = FoundRows[0];
		
		If DataAcquisitionRules Then
			SearchingForRuleAndPeriod = New Structure("RuleOfFact, BeginOfPeriod, EndOfPeriod");
			FillPropertyValues(SearchingForRuleAndPeriod, PeriodAndRule);

			FoundRows = AdditionalDataTable.FindRows(SearchingForRuleAndPeriod);
			AddTheseRules = FoundRows[0];
		EndIf;
		
		UUID = ApplicableRule.UUID;
		IdentifierOfTemplate = ApplicableRule.NameOfTheDataSourceTemplate;
		SettingsComposer = ApplicableRule.SettingsComposer; // ValueStorage
		RuleSettings = SettingsComposer.Get();
		ZoomRatio = ApplicableRule.ZoomRatio;
		
		DataSourceSection = ApplicableRule.DataSourceSection;
		DataSource = ApplicableRule.DataSource;
		BusinessOperation = ApplicableRule.BusinessOperation;
		
		GroupDopingRules = FinancialReportingServer.NewFilter(GroupOfAdditionalSelectionsOfAllRules,
			Undefined,, Type("DataCompositionFilterItemGroup"));
		GroupDopingRules.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		GroupDopingRules.Use = True;
		GroupDopingRules.Presentation = "DopingRules_" + UUID;
		
		FinancialReportingServer.NewFilter(GroupDopingRules, "DataSourceID",
			IdentifierOfTemplate,, DataCompositionComparisonType.Equal);
		
		FinancialReportingServer.CopyFilter(RuleSettings.Filter, GroupDopingRules, True);
		
		// For each rule (if required), add a grouping to form part of the fact table
		// In the grouping, add the selections needed to get a portion of the rule data
		// Add additional selections.
		GroupingRules = FinancialReportingServer.NewGrouping(RootElementOfStructure);
		
		If DataAcquisitionRules Then
			FinancialReportingServer.NewDimensionField(GroupingRules, "BeginOfPeriod");
			FinancialReportingServer.NewDimensionField(GroupingRules, "EndOfPeriod");
		EndIf;
		
		If AdditionalDataCalculatedFields Then
			For Each AdditionalDataColumn In AdditionalDataColumns Do 
				ColumnName = AdditionalDataColumn.Name;
				
				If ColumnName = "UUID"
					Or DataAcquisitionRules 
						And (ColumnName = "RuleOfFact" Or ColumnName = "BeginOfPeriod" Or ColumnName = "EndOfPeriod") Then
					Continue;
				EndIf;
				
				ColumnIds.Add(ColumnName);
		
				If DataAcquisitionRules Then
					FinancialReportingServer.NewDimensionField(GroupingRules,
						ColumnName + "_" + AddTheseRules.UUID);
				Else
					FinancialReportingServer.NewDimensionField(GroupingRules,
						ColumnName + "_" + UUID);
				EndIf;
			EndDo;
			
		ElsIf AdditionalDataAdditionalSet Then
			For Each AdditionalDataColumn In UsedColumnsForData Do 
				ColumnName = AdditionalDataColumn.Name;
				
				If ColumnName = "UUID" Then
					Continue;
				EndIf;
				
				FinancialReportingServer.NewDimensionField(GroupingRules, ColumnName);
			EndDo;
		EndIf;
		
		If ByCompanies Then
			FinancialReportingServer.NewDimensionField(GroupingRules, "Organization");
		EndIf;
		
		If ByBusinessUnits Then
			FinancialReportingServer.NewDimensionField(GroupingRules, "Department");
		EndIf;
		
		If ByRegistrar Then
			FinancialReportingServer.NewDimensionField(GroupingRules, "Recorder");
		EndIf;
		
		If ByPeriods Then
			PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
			
			FinancialReportingServer.NewDimensionField(GroupingRules, PeriodName);
		EndIf;
		
		For DimensionNumber = 1 To MaximumNumberOfAnalytics Do 
			If Not NumberedAnalyticsUsed.Property("Dimension" + DimensionNumber) Then
				Continue;
			EndIf;
			
			DimensionKind = ApplicableRule["DimensionKind" + DimensionNumber];
			
			If ValueIsFilled(DimensionKind) 
				And Not DimensionKinds.Find(DimensionKind) = Undefined Then
				NameOfAnalyticsField = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
				
				If DataAcquisitionRules Then
					FieldSuffix = AddTheseRules.UUID;
				Else
					FieldSuffix = UUID;
				EndIf;
				
				NameOfNumberedAnalyticsField = "Dimension" + DimensionNumber + "_" + FieldSuffix;
				
				// It is expected that the rules for getting the fact are all expressions filled in
				// But there are situations when analytics is used, but the expression is not filled in. 
				// For example, after programmatically creating rules.
				DimensionPopulationExpression = ApplicableRule["DimensionPopulationExpression" + DimensionNumber];
				If Not ValueIsFilled(DimensionPopulationExpression) Then
					DimensionPopulationExpression = "UNDEFINED";
				EndIf;
				
				FinancialReportingServer.NewCalculatedField(FactReceiptDCS, NameOfAnalyticsField, DimensionPopulationExpression, , True);
				FinancialReportingServer.NewDimensionField(GroupingRules, NameOfAnalyticsField);
				
				FinancialReportingServer.NewCalculatedField(FactReceiptDCS, NameOfNumberedAnalyticsField, DimensionPopulationExpression, , True);
				FinancialReportingServer.NewDimensionField(GroupingRules, NameOfNumberedAnalyticsField);
			EndIf;
		EndDo;
		
		SourcesAndRules = DataSourcesServer.SourcesAndRules(FactReceiptDCS, ApplicableRule);
		
		// Amount in the transaction currency
		FieldNameInTransactionCurrency = "";
		If SourcesAndRules.Property("Currency", FieldNameInTransactionCurrency) Then
			FinancialReportingServer.NewDimensionField(GroupingRules, "Currency");
			
			If TotalFields.Find(FieldNameInTransactionCurrency) = Undefined Then
				CoefficientPrefix = ?(ZoomRatio = 1, "", "(" + Format(ZoomRatio, "NDS=.; NZ=0; NG=0") + ") * ");
				
				FinancialReportingServer.NewResource(FactReceiptDCS, FieldNameInTransactionCurrency, CoefficientPrefix + "Sum");
			EndIf;
			FinancialReportingServer.NewSelectionField(GroupingRules, FieldNameInTransactionCurrency);
			
			FinancialReportingServer.NewFilter(GroupingRules.Filter, FieldNameInTransactionCurrency,,, DataCompositionComparisonType.Filled);
			
			ColumnsAggregates.Add(FieldNameInTransactionCurrency);
		EndIf;
		
		// Selections of a separate rule at the level of the grouping that includes it
		// In fact, this is an additional filtering of data that belongs to a separate rule.
		FinancialReportingServer.NewFilter(GroupingRules.Filter,
			"DataSourceID", IdentifierOfTemplate,, DataCompositionComparisonType.Equal);
		
		If DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
			FinancialReportingServer.NewFilter(GroupingRules.Filter,
				"BusinessOperation", BusinessOperation,, DataCompositionComparisonType.Equal);
		ElsIf DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting
			Or DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting Then
			
			FinancialReportingServer.NewFilter(GroupingRules.Filter,
				"Account", DataSource,, DataCompositionComparisonType.Equal);
		EndIf;
		
		If DataAcquisitionRules Then
			FinancialReportingServer.NewFilter(GroupingRules.Filter,
				"BeginOfPeriod", PeriodAndRule.BeginOfPeriod,, DataCompositionComparisonType.Equal);
			FinancialReportingServer.NewFilter(GroupingRules.Filter,
				"EndOfPeriod", PeriodAndRule.EndOfPeriod,, DataCompositionComparisonType.Equal);
			FinancialReportingServer.NewFilter(GroupingRules.Filter,
				"RuleOfFact", PeriodAndRule.RuleOfFact,, DataCompositionComparisonType.Equal);
		EndIf;
		FinancialReportingServer.CopyFilter(RuleSettings.Filter, GroupingRules.Filter, True);
	
	EndDo;
	
	#EndRegion 
	
	#Region GetData
	
	// Initialize the layout layout, which will be stored in the cache and executed
	DataAcquisitionTemplate = FinancialReportingServer.PrepareLayoutTemplateForUploadingDCS(FactReceiptDCS, Settings);
	
	// Execute a processor output to a collection of values
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("PeriodsTable", PeriodsTable);
	If AdditionalDataAdditionalSet Then
		ExternalDataSets.Insert("AdditionalDataTable", AdditionalDataTable);
	EndIf;
	SourceDataByRules = FinancialReportingServer.UploadDCSResultsFromTemplate(DataAcquisitionTemplate, ExternalDataSets);
	
	#EndRegion 
	
	#Region DataPostprocessing_ConvolutionOfRulesAndSums
	
	// "Collapse" the rule ID columns into one
	If DataAcquisitionRules Then
		
		For DimensionNumber = 1 To MaximumNumberOfAnalytics Do 
			If Not NumberedAnalyticsUsed.Property("Dimension" + DimensionNumber) Then
				Continue;
			EndIf;
			
			ColumnIds.Add("Dimension" + DimensionNumber);
		EndDo;
		
		ColumnIds = CommonClientServer.CollapseArray(ColumnIds);
		
		RowOfIdentifiersColumn = StrConcat(ColumnIds, ", ");
		
		IDs = AdditionalDataTable.UnloadColumn("UUID");
		ColumnsAggregates = CommonClientServer.CollapseArray(ColumnsAggregates);
		DataSourcesServer.CollapseByIDColumns(
			SourceDataByRules,
			RowOfIdentifiersColumn,
			IDs, "_",
			ColumnsAggregates,
			True);
		
		IDs.Clear();
		
		If FactGettingParameters.Indicators.Property("Sum") Then
			ColumnsAmountIds = "Sum";
			
			For Each ColumnAggregate In ColumnsAggregates Do 
				IDs.Add(StrReplace(ColumnAggregate, "Sum", ""));
			EndDo;
			
			DataSourcesServer.CollapseByIDColumns(SourceDataByRules, ColumnsAmountIds, IDs);
		EndIf;
		
		If FactGettingParameters.Indicators.Property("Count") And False Then
			ColumnsQuantityIds = "Count";
			
			For Each ColumnAggregate In ColumnsAggregates Do 
				IDs.Add(StrReplace(ColumnAggregate, "Count", ""));
			EndDo;
			
			DataSourcesServer.CollapseByIDColumns(SourceDataByRules,
				ColumnsQuantityIds, IDs);
		EndIf;
		
	EndIf;
	
	#EndRegion 
	
	// Return the fact table
	TableIndexes = FactGettingParameters.TableIndexes; // Map
	TableIndexes_ = TableIndexes.Get("TableOfArticleRules");
	DataSourcesServer.SetIndexesFromArray(TableOfArticleRules, TableIndexes_);
	
	Return SourceDataByRules;
	
EndFunction

// Returns the fact for budget items in accordance with the configured rules
//
// Parameters:
// 	Filter_Settings - DataCompositionSettings - Settings for selecting budget items
// 	Parameters - Structure - Parameters for obtaining actual data
// 	ConvertToCurrency_ - Boolean - Indicates whether conversion from the storage currency to the article currency is required
// 	SupplementWithStoredFact - Boolean - Indicates whether the actual data needs to be supplemented with stored data.
//
// Returns:
// ValueTable - Actual data on budget items.
//
Function FactOnBudgetItems(Filter_Settings, Val Parameters, ConvertToCurrency_ = True, SupplementWithStoredFact = True) Export
	
	// Let's prepare a fact table
	FactOnBudgetItems = FactTableTemplateForBudgetItems(Parameters);
	
	// Let's prepare a table of rules according to which it is planned to receive data
	SetPrivilegedMode(True);
	
	DataCompositionSchema = Catalogs.ActualDataQueryRulesByBudgetFlowItems.GetTemplate("ActualDataQueryRules_");
	
	Settings = DataCompositionSchema.DefaultSettings;
	DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema, Settings, Filter_Settings,
		"Scenario");
	DataCompositionClientServer.AddFilter(
		Settings, "CachingOfRuleResults", False, DataCompositionComparisonType.Equal);
	
	// We will add a selection that ensures the selection of only articles for obtaining turnover
	DataCompositionClientServer.AddFilter(
		Settings, "BudgetBalanceItem",, DataCompositionComparisonType.NotFilled);
	
	TableOfArticleRules = FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings);
	TableOfArticleRules.Columns.Add("DataSourceObjectType");
	TableOfArticleRules.FillValues(Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"), "DataSourceObjectType");
	
	SetPrivilegedMode(False);
	
	// We will get the fact in accordance with the rules
	For Each Rule In TableOfArticleRules Do
		FactOfArticleOfBudgetsAccordingToRule(Rule, Parameters, FactOnBudgetItems);
	EndDo;
	
	If ConvertToCurrency_ And Parameters.Indicators.Property("Sum") Then
		DataTableParameters = ParametersForConvertingDataTableToCurrency(FactOnBudgetItems);
		ConvertDataTableToCurrency(DataTableParameters, Parameters.ReportCurrency, Parameters.FunctionalCurrency);
		FactOnBudgetItems = DataTableParameters.DataTable;
	EndIf;
	
	If SupplementWithStoredFact Then
		FilterElement = FinancialReportingServer.FindSelectionElement(Filter_Settings.Filter, "BudgetFlowItem");
		If FilterElement <> Undefined And FilterElement.Use Then
			If Parameters.AdditionalSelection = Undefined Then
				Parameters.AdditionalSelection = New DataCompositionSettings;
			EndIf;
			FinancialReportingServer.NewFilter(Parameters.AdditionalSelection.Filter, "BudgetFlowItem",
				FilterElement.RightValue, , FilterElement.ComparisonType);
		EndIf;
		TableStoredFact = FactOfBudgetItemIsStored(Parameters, ConvertToCurrency_);
		CommonClientServer.SupplementTable(TableStoredFact, FactOnBudgetItems);
	EndIf;
	
	Return FactOnBudgetItems;
	
EndFunction

// Returns a fact for budget indicators in accordance with the configured rules
//
// Parameters:
// 	Filter_Settings - DataCompositionSettings - Rule selection settings
// 	Parameters - Structure - Parameters for obtaining actual data:
// 	* Period - StandardPeriod - 
// 	TempTablesManager - TempTablesManager - manager of a temporary table when converting a fact into the report currency.
// 							- Undefined
// 	TempTableName - String - name of the temporary table
//
// Returns:
// 	ValueTable - Actual data on budget indicators.
//
Function FactOnBudgetIndicators(Filter_Settings, Val Parameters, TempTablesManager = Undefined,
	TempTableName = "") Export
	
	PeriodsTable = Planning.PeriodTableTemplate();
	
	If Parameters.BalancesOnlyAtBeginningOfPeriod Or Not ValueIsFilled(Parameters.Periodicity) Then
		Period = PeriodsTable.Add();
		Period.StartDate = Parameters.Period.StartDate;
		Period.EndDate = Parameters.Period.EndDate;
	Else
		Planning.FillInPeriodTable(
			PeriodsTable, Parameters.Periodicity, Parameters.Period.StartDate, Parameters.Period.EndDate);
	EndIf;
	Parameters.Insert("PeriodsTable", PeriodsTable);
	
	// Let's prepare a fact table
	FactOnBudgetIndicators = FactTableTemplateForBudgetIndicators(Parameters);
	
	// Let's prepare a table of rules
	SetPrivilegedMode(True);
	
	DataCompositionSchema = Catalogs.ActualDataQueryRulesByBudgetBalanceItems.GetTemplate("ActualDataQueryRules_");
	Settings = DataCompositionSchema.DefaultSettings;
	DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema, Settings, Filter_Settings);
	DataCompositionServer.GetLayoutTemplate(DataCompositionSchema, Settings);
	RulesTable = FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings);
	RulesTable.Columns.Add("DataSourceObjectType");
	RulesTable.FillValues(Type("CatalogRef.ActualDataQueryRulesByBudgetBalanceItems"), "DataSourceObjectType");
	
	SetPrivilegedMode(False);
	
	// We will get the fact in accordance with the rules
	For Each Rule In RulesTable Do
		FactThatBudgetsAreCalculatedAccordingToRule(Rule, Parameters, FactOnBudgetIndicators);
	EndDo;
	
	// Let's convert the fact into the currency of budget indicators
	If Parameters.Indicators.Property("Sum") Then
		DataTableParameters = ParametersForConvertingDataTableToCurrency(FactOnBudgetIndicators);
		If TempTablesManager <> Undefined Then
			DataTableParameters.TempTablesManager = TempTablesManager;
			DataTableParameters.TempTableName = TempTableName;
			DataTableParameters.IndexFields = "BudgetBalanceItem";
		EndIf;
		ConvertDataTableToCurrency(DataTableParameters, Parameters.ReportCurrency, Parameters.FunctionalCurrency);
		FactOnBudgetIndicators = DataTableParameters.DataTable;
	ElsIf TempTablesManager <> Undefined Then
		Query = New Query(TMCommonUse.QueryTextDataFromValueTable(FactOnBudgetIndicators,
			TempTableName, "BudgetBalanceItem"));
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter(TempTableName, FactOnBudgetIndicators);
		Query.Execute();
	EndIf;
	
	Return FactOnBudgetIndicators;
	
EndFunction

// Returns the fact for budget items and indicators, as well as the values of non-financial indicators included in the structure
// of the budget type.
//
// Parameters:
// 	DataParameters - Structure - Selections defined at the budget report level
// 	DataSources - Array of Structure - array of budget-type data sources
// 	ReportCurrency - CatalogRef.Currencies - The currency in which the fact must be returned.
// 	DataReceiptMode - EnumRef.BudgetingDataReceiptMode - data acquisition mode.
//
// Returns:
// 	ValueTable - Fact by type of budget.
//
Function FactByBudgetType(DataParameters, DataSources, ReportCurrency, DataReceiptMode) Export
	
	If UseAlternativeAlgorithm() Then
		DataTableByBudgetType = CalculateFactByBudgetTypeAlternative(
			DataParameters, DataSources, ReportCurrency, DataReceiptMode);
	Else
		DataTableByBudgetType = CalculateFactByBudgetType(
			DataParameters, DataSources, ReportCurrency, DataReceiptMode);
	EndIf;
	
	Return DataTableByBudgetType;
	
EndFunction

// Returns a table with actual data
// The composition of columns is determined by the parameters for getting the fact.
//
// Parameters:
//	SourceCatalogName - String - for example, "The rules for obtaining the facts of the evidence of the budgets". See the details of the source of the published report.Supported referencessources of data()
//	FactGettingParameters - See DataSourcesServer.TemplateForGettingFactParameters
//
// Returns:
//	ValueTable - Actual data.
//
Function ActualDataFromSources(SourceCatalogName, FactGettingParameters)
	
	#Region InitializingVariables
	TheseAreRevolutions = (SourceCatalogName = "ActualDataQueryRulesByBudgetFlowItems");
	TheseAreLeftovers = (SourceCatalogName = "ActualDataQueryRulesByBudgetBalanceItems");
	
	LocalAccounting = Enums.SectionsOfBudgetingDataSources.LocalAccounting;
	FinancialAccounting = Enums.SectionsOfBudgetingDataSources.FinancialAccounting;
	
	// Parameters for obtaining actual data
	DataAcquisitionRules = FactGettingParameters.DataAcquisitionRules;
	ByCompanies = FactGettingParameters.ByCompanies;
	ByBusinessUnits = FactGettingParameters.ByBusinessUnits;
	ByRegistrar = FactGettingParameters.ByRegistrar;
	ByUnitsOfMeasurement = FactGettingParameters.ByUnitsOfMeasurement;
	ByCurrency = FactGettingParameters.ByCurrency;
	DataReceiptMode = FactGettingParameters.AccessRestrictions.DataReceiptMode;
	
	If TheseAreRevolutions Then
		ByPeriods = FactGettingParameters.Periodicity <> Undefined;
		Periodicity = FactGettingParameters.Periodicity;
		If ByPeriods Then
			ExpressingPlanningPeriod = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		Else
			ExpressingPlanningPeriod = "DayPeriod";
		EndIf;
		ExpressionOfRatePeriod = "DayPeriod";
	ElsIf TheseAreLeftovers Then
		ByPeriods = False;
		ExpressingPlanningPeriod = "Period";
		ExpressionOfRatePeriod = "Period";
		
		
		NumberOfExtDimensionIsInternational = Metadata.ChartsOfAccounts.International.MaxExtDimensionCount;
	EndIf;
	
	RequestedTypesOfAnalytics = FactGettingParameters.DimensionKinds;
	MaximumNumberOfAnalytics = FactGettingParameters.MaximumNumberOfAnalytics;
	NumberedAnalyticsUsed = FactGettingParameters.NumberedAnalyticsUsed;
	
	TableOfArticleRules  = FactGettingParameters.TableOfArticleRules;
	DataSourcesServer.SetIndexesFromArray(TableOfArticleRules);
	
	// Additional data
	AdditionalData = FactGettingParameters.AdditionalData;
	TypeOfAdditionalData = AdditionalData.Kind;
	AdditionalDataTable = AdditionalData.DataTable;
	
	AdditionalDataCalculatedFields = TypeOfAdditionalData = Enums.KindOfAdditionalDataSourceInformation.CalculatedFields;
	AdditionalDataAdditionalSet = TypeOfAdditionalData = Enums.KindOfAdditionalDataSourceInformation.DataSetAdditional;
	
	// Period table
	TableOfDataAreas  = FactGettingParameters.DataAreas.DataTable; // ValueTable -
	ColumnsOfDataAreas  = TableOfDataAreas.Columns;
	
	// Identification of data sources
	ReceivedTemplates = New Map;
	DataSetsForIdentification = New Map;
	
	IdFieldName = "DataSourceID";
	ExpressionOfIdentifierParameter = """DataSourceID"" = &DataSourceID"; // @query-part
	ExpressionConditionPrefix = "ExpressionCondition";
	
	ExpressionConditions = FactGettingParameters.ExpressionConditions;
	
	// Data Convolution
	ColumnIds = New Array;
	ColumnsAggregates = New Array;
	
	ActualDataReceiptTemplate = DataSourcesCached.GettingCatalogTemplate(SourceCatalogName, "ActualDataReceiptTemplate");
	FactReceiptDCS = DataCompositionServer.CopyDataLayoutDiagram(ActualDataReceiptTemplate);
	
	#EndRegion 
	
	#Region DataSets
	
	#Region CombinedFact
	
	LBUnitedFact = FactReceiptDCS.DataSets.CombinedFact; // DataCompositionSchemaDataSetUnion -
	
	// Let's check if there are sources of regulated or international accounting
	If TheseAreRevolutions Then
		SelectionByAccountingSection = New Structure("DataSourceSection", LocalAccounting);
		ThereIsASourceWithGroupCorrAccount = TableOfArticleRules.FindRows(SelectionByAccountingSection).Count() > 0;
		If Not ThereIsASourceWithGroupCorrAccount Then
			SelectionByAccountingSection = New Structure("DataSourceSection", FinancialAccounting);
			For Each RuleRow In TableOfArticleRules.FindRows(SelectionByAccountingSection) Do
				If FinancialAccountingOfGeneralPurpose.OptionForGeneratingTransactionsByAccount(
					RuleRow.DataSource) = Enums.EntryGenerationOptions.WithCorrespondence Then
					ThereIsASourceWithGroupCorrAccount = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// For each unique layout of the scheme, add a register ID and transfer the type settings.
	For Each ApplicableFactRule In TableOfArticleRules Do
		DataSourceID = ApplicableFactRule.DataSourceID;
		
		If ReceivedTemplates.Get(DataSourceID) = Undefined Then
			Template = DataSourcesServer.DataLayoutRules(ApplicableFactRule.RuleOfFact,,
				DataReceiptMode, True);
			
			If TheseAreLeftovers Then
				If ApplicableFactRule.DataSourceSection = FinancialAccounting Then
					ReduceExtDimensionOfSourceIfNecessary(
						Template,
						ApplicableFactRule.NameOfTheDataSourceTemplate,
						ApplicableFactRule.LimitationOfNumberOfExtDimension,
						NumberOfExtDimensionIsInternational);
				EndIf;
			EndIf;
			
			ReceivedTemplates.Insert(DataSourceID, Template);
		EndIf;
	EndDo;
	
	For Each ResultingTemplate In ReceivedTemplates Do 
		DataSourceID = ResultingTemplate.Key;
		InitialTemplate = ResultingTemplate.Value; // DataCompositionSchema -
		
		// Let's move all the data sets of the sources to the combined set
		CopiedDataSets = DataCompositionServer.CopyDatasets(LBUnitedFact,
			InitialTemplate, DataSourceID);
		
		ArbitrarySet = False;
		TemplateRules = TableOfArticleRules.FindRows(New Structure("DataSourceID", DataSourceID));
		If TemplateRules.Count() > 0 Then
			ArbitrarySet = TemplateRules[0].DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery;
		EndIf;
		
		ParametersNotCopied = NamesOfCommonParametersOfFactGettingRules();
		
		// Since parameters can be named the same in different schemes, but have different meanings,
		// it is necessary to rename them, as well as replace their names in the query text.
		// It is also necessary to take into account that there may be a parameter whose name partially repeats the name of another
		// parameter. In this case, the replacement should be made starting with the longest parameter by name.
		ParameterNames = New ValueTable;
		ParameterNames.Columns.Add("Name", New TypeDescription("String"));
		ParameterNames.Columns.Add("NewName", New TypeDescription("String"));
		ParameterNames.Columns.Add("Replace", New TypeDescription("Boolean"));
		ParameterNames.Columns.Add("NameLength", New TypeDescription("Number",,, New NumberQualifiers(5, 0, AllowedSign.Nonnegative)));
		For Each SchemeParameter In InitialTemplate.Parameters Do
			ParameterNameString = ParameterNames.Add();
			ParameterNameString.Name = SchemeParameter.Name;
			ParameterNameString.NameLength = StrLen(SchemeParameter.Name);
			ParameterNameString.Replace = ArbitrarySet And ParametersNotCopied.Find(SchemeParameter.Name) = Undefined;
			If ParameterNameString.Replace Then
				ParameterNameString.NewName = StringFunctionsClientServer.SubstituteParametersToString(
					"P%1_%2",
					DataSourceID,
					SchemeParameter.Name);
			Else
				ParameterNameString.NewName = ParameterNameString.Name;
			EndIf;
		EndDo;
		ParameterNames.Sort("NameLength DESC");
		
		For Each CopiedDataSet In CopiedDataSets Do
			If TypeOf(CopiedDataSet) = Type("DataCompositionSchemaDataSetQuery") Then
				For Each ParameterNameString In ParameterNames Do
					If ParameterNameString.Replace Then
						CopiedDataSet.Query = StrReplace(CopiedDataSet.Query,
								"&" + ParameterNameString.Name,
								"&" + ParameterNameString.NewName);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		For Each SourceParameter_ In InitialTemplate.Parameters Do
			ParameterNameString = ParameterNames.Find(SourceParameter_.Name, "Name");
			DesiredParameterName  = ParameterNameString.NewName;
			
			NewParameter1 = FactReceiptDCS.Parameters.Find(DesiredParameterName);
			
			If NewParameter1 = Undefined Then
				NewParameter1 = FactReceiptDCS.Parameters.Add();
				NewParameter1.Name = DesiredParameterName;
			EndIf;
			
			FillPropertyValues(NewParameter1, SourceParameter_,, "Name");
			If ParameterNameString.Replace Then
				// User parameters should always be used, even if the use of Auto is in the SKD.
				NewParameter1.Use = DataCompositionParameterUse.Always;
			EndIf;
		EndDo;
		
		DesiredCollectionOfSets = DataSetsForIdentification[DataSourceID];
		If DesiredCollectionOfSets = Undefined Then
			DataSetsForIdentification.Insert(DataSourceID, CopiedDataSets);
		Else
			CommonClientServer.SupplementArray(DesiredCollectionOfSets, CopiedDataSets);
		EndIf;
	EndDo;
	
	// We will prepare the layouts BEFORE the transfer - we will add the "Data Source Identifier" field
	// For the supplied schemes to them - this is the name of the layout and the data source of the business operation settings
	// For arbitrary data, this is a hash schema string 
	// The hash is used to minimize the number of arbitrary data sets. 
	// If the SKDS are identical in different rules, then there will be only one data set in the executable schema.
	For Each DataSetForIdentification In DataSetsForIdentification Do 
		SetID = DataSetForIdentification.Key;
		SetsByID = DataSetForIdentification.Value;
		
		For Each RecruitmentById In SetsByID Do 
			If TypeOf(RecruitmentById) = Type("DataCompositionSchemaDataSetQuery") Then
				SetRequest = RecruitmentById.Query;
				
				// Adding a field to the extended layout query fields and query selection fields
				SetRequest = RequestSchemes.AddSelectionFieldToQuery(SetRequest, """" + SetID + """", IdFieldName, , True, True);
				
				SetRequest = RequestSchemes.AddConditionToRequest(SetRequest, ExpressionOfIdentifierParameter);
				
				SetRequest = StrReplace(SetRequest, """" + IdFieldName + """", """" + SetID + """");
				
				RecruitmentById.Query = SetRequest;
			EndIf;
		EndDo;
	EndDo;
	
	// In the query texts, we will add parameter fields to connect to the table of data areas.
	ElementsOfCombinedFact = LBUnitedFact.Items;
	
	SourceExpression = "";
	For Each DataAreaColumn In ColumnsOfDataAreas Do 
		ColumnName = DataAreaColumn.Name;
		
		If Not FactGettingParameters.Property(ExpressionConditionPrefix + ColumnName, SourceExpression) Then
			SourceExpression = ColumnName;
		EndIf;
		
		If ColumnName = IdFieldName Then
			Continue;
		EndIf;
		
		ColumnType = DataAreaColumn.ValueType;
		
		For Each ElementOfCombinedFact In ElementsOfCombinedFact Do 
			AddSelectionFieldToQueryRecursively(ColumnName, ElementOfCombinedFact);
			
			FinancialReportingServer.NewSetField(ElementOfCombinedFact, ColumnName, ColumnName, , ColumnType);
		EndDo;
		
		// Let's add the fields of the child sets to the root, unifying fact
		FinancialReportingServer.NewSetField(LBUnitedFact, ColumnName, ColumnName, , ColumnType);
	EndDo;
	
	#EndRegion 
	
	#Region AdditionalDataTable
	
	LBTableOfAdditionalData = FactReceiptDCS.DataSets.AdditionalDataTable;
	
	// Let's add fields of identifiers of expressions of named analytics
	For Each DimensionKind In RequestedTypesOfAnalytics Do
		NameOfAnalyticsField = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		
		FinancialReportingServer.NewSetField(
			LBTableOfAdditionalData, 
			"ID_" + "ExpressionOfNamedAnalytics" + NameOfAnalyticsField, 
			"ID_" + "ExpressionOfNamedAnalytics" + NameOfAnalyticsField);
	EndDo;
	
	For Each ColumnNameAndExpression In ExpressionConditions Do
		ExpressionName = ColumnNameAndExpression.Key;
		If StrStartsWith(ExpressionName, "ExpressionOfNamedAnalytics") Then
			// These fields can be used in the selection without the output of analytics
			SetFieldName = "ID_" + ExpressionName;
			SetField = LBTableOfAdditionalData.Fields.Find(SetFieldName);
			If SetField = Undefined
				And Not AdditionalDataTable.Columns.Find(SetFieldName) = Undefined Then
				FinancialReportingServer.NewSetField(
				LBTableOfAdditionalData, 
				SetFieldName,
				SetFieldName);
			EndIf;
		EndIf;
	EndDo;
		
	#EndRegion 
		
	#EndRegion 
	
	#Region DataSetLinks
	
	// Let's clarify the expressions of relations at the beginning and end of the period
	For Each LinkingDatasets In FactReceiptDCS.DataSetLinks Do 
		If LinkingDatasets.SourceDataSet = "TableOfDataAreas"
			Or LinkingDatasets.DestinationDataSet = "TableOfDataAreas" Then
			Prefix = "TOD_";
		ElsIf LinkingDatasets.SourceDataSet = "AdditionalDataTable"
			Or LinkingDatasets.DestinationDataSet = "AdditionalDataTable" Then
			Prefix = "TDD_";
		Else
			Prefix = "";
		EndIf;
		
		If Not TheseAreRevolutions
			And LinkingDatasets.SourceExpression = "ExpressionPeriodBoundary"
			And LinkingDatasets.Parameter = "PeriodLimit" Then
			// It is necessary to transform the right part of the expression.
			// You cannot create a Period Boundary field with the period boundary type, but there is a Period field in the "Combined Fact" set.
			// The "period boundary" is the "Period" reduced to the period boundary or with the addition of a second (up to 8.3.14).
			If ReductionToBoundaryOfPeriodInConnectionsOfSchemeForObtainingFactIsUsed() Then
				DestinationExpression =
				"CASE
				|	WHEN GettingBalancesForPeriodBoundary
				|		THEN DataCompositionServer.PeriodBoundary(Period, ""Including"")
				|	ELSE Period
				|END";
			Else
				DestinationExpression =
				"CASE
				|	WHEN GettingBalancesForPeriodBoundary
				|		THEN DATEADD(Period, ""Second"", 1)
				|	ELSE Period
				|END";
			EndIf;
			LinkingDatasets.DestinationExpression = DestinationExpression;
		EndIf;
		
		AdaptFieldExpression(LinkingDatasets.SourceExpression, Prefix, ExpressionConditions);
		AdaptFieldExpression(LinkingDatasets.DestinationExpression, Prefix, ExpressionConditions);
		
		AdaptExpressionOfPlanningPeriod(LinkingDatasets.SourceExpression, ExpressingPlanningPeriod, ExpressionOfRatePeriod);
		AdaptExpressionOfPlanningPeriod(LinkingDatasets.DestinationExpression, ExpressingPlanningPeriod, ExpressionOfRatePeriod);
	EndDo;
		
	// Let's clarify the composition of the links
	If TheseAreRevolutions And Not ThereIsASourceWithGroupCorrAccount Then
		LinkCount = FactReceiptDCS.DataSetLinks.Count();
		For LinkNumber = 1 To LinkCount Do
			ReverseIndex = LinkCount - LinkNumber;
			LinkingDatasets = FactReceiptDCS.DataSetLinks[ReverseIndex];
			If LinkingDatasets.LinkConditionExpression = "&ThereIsASourceWithGroupCorrAccount" Then
				FactReceiptDCS.DataSetLinks.Delete(LinkingDatasets);
			EndIf;
		EndDo;
	EndIf;
	
	// Let's clarify the composition of the links
	If TheseAreRevolutions
		And Not FactReceiptDCS.Parameters.Find("TurnoverByExpenseDimension") = Undefined Then
		Link = FactReceiptDCS.DataSetLinks.Add();
		Link.SourceDataSet = "CombinedFact";
		Link.SourceExpression = "ISNULL(TurnoverByExpenseDimension, FALSE)";
		Link.DestinationDataSet = "AdditionalDataTable";
		Link.DestinationExpression =
		"CASE WHEN TDD_DataSourceID = ""RecordsProductsProducts""
		|	THEN TDD_TurnoverByExpenseDimension
		|	ELSE FALSE
		|END";
	EndIf;
	
	#EndRegion 
	
	#Region CalculatedFields
	
	// Let's add calculated fields of named analytics
	AllTypesOfBudgetingAnalytics = AllTypesOfAnalytics();
	For Each DimensionKind In RequestedTypesOfAnalytics Do
		NameOfAnalyticsField       = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		AnalyticsFieldExpression = ExpressionConditions["ExpressionOfNamedAnalytics" + NameOfAnalyticsField];
		
		FieldToEval = FinancialReportingServer.NewCalculatedField(FactReceiptDCS,
			NameOfAnalyticsField,
			AnalyticsFieldExpression,,
			True,
			AllTypesOfBudgetingAnalytics);
	EndDo;
	
	For Each ExpressionCondition In ExpressionConditions Do
		If StrStartsWith(ExpressionCondition.Key, "ExpressionOfNamedAnalytics") Then
			NameOfAnalyticsField = Mid(ExpressionCondition.Key, StrLen("ExpressionOfNamedAnalytics") + 1);
			AnalyticsFieldExpression = ExpressionCondition.Value;
			
			FieldToEval = FinancialReportingServer.NewCalculatedField(FactReceiptDCS,
				NameOfAnalyticsField,
				AnalyticsFieldExpression,,
				True,
				AllTypesOfBudgetingAnalytics);
		EndIf;
	EndDo;
	
	// Let's refine the expressions of calculated fields
	For Each FieldToEval In FactReceiptDCS.CalculatedFields Do 
		AdaptFieldExpression(FieldToEval.Expression, , ExpressionConditions);
		AdaptExpressionOfPlanningPeriod(FieldToEval.Expression, ExpressingPlanningPeriod, ExpressionOfRatePeriod);
	EndDo;
	
	#Region ReplacingCharacteristicsInExpressionsOfCalculatedFields
	
	// Correction of the query sets of the fact acquisition scheme, in the case of using characteristics
	// in analytics filling expressions (the expressions themselves were modified earlier). If characteristics are used
	// , the text in the language of the extension of requests for redefinition of obtaining characteristics will be added to the request sets.
	OriginalAnalystFillExpressions = New Array;
	For Each KeyAndValue In FactGettingParameters.OriginalAnalystFillExpressions Do
		OriginalAnalystFillExpressions.Add(KeyAndValue.Key);
	EndDo;
	ResultOfTransformations = ProcessingOfFormulas.DataForObtainingFormulaExpressionsViaDCS(FactReceiptDCS,
		OriginalAnalystFillExpressions, False, True);
	
	If ResultOfTransformations.HasErrors Then
		ErrorsMessages = ResultOfTransformations.ConversionErrorMessages; // Map -
		For Each KeyAndValue In ErrorsMessages Do
			OriginalExpression = KeyAndValue.Key;
			ConversionErrorText = KeyAndValue.Value;
			ItemIndicator = FactGettingParameters.OriginalAnalystFillExpressions.Get(OriginalExpression);
			If TypeOf(ItemIndicator) = Type("CatalogRef.BudgetFlowItems") Then
				ErrorText = NStr("vi = 'Lỗi khi chỉ ra đối tượng phân tích của khoản mục ngân sách ""%1"": %2';
								|ru = 'Ошибка в указании аналитики статьи бюджетов ""%1"": %2';
								|en = 'Error in specification of budget flow item dimension ""%1"": %2'; fa = 'Error in specification of budget flow item dimension ""%1"": %2';
								|it = 'Errore nell''indicazione dell''analitica della voce di bilanci ""%1"": %2';
								|pl = 'Błąd w podaniu analityki pozycji budżetów ""%1"": %2';
								|tr = 'Belirtilen ""%1"" bütçe kaleminin boyutunda hata: %2'");
			Else
				ErrorText = NStr("vi = 'Lỗi khi chỉ ra đối tượng phân tích chỉ tiêu ngân sách ""%1"": %2';
								|ru = 'Ошибка в указании аналитики показателя бюджетов ""%1"": %2';
								|en = 'Error in specification of budget balance item dimension ""%1"": %2'; fa = 'Error in specification of budget balance item dimension ""%1"": %2';
								|it = 'Errore nell''indicazione dell''analitica dell''indicatore di bilanci ""%1"": %2';
								|pl = 'Błąd w podaniu analityki wskaźnika budżetów ""%1"": %2';
								|tr = 'Belirtilen ""%1"" bütçe dengesi kaleminin boyutunda hata: %2'");
			EndIf;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorText,
				ItemIndicator,
				ConversionErrorText);
			
			Raise ErrorText;
		EndDo;
	EndIf;
	
	ExpressionReplacementTable = New ValueTable();
	ExpressionReplacementTable.Columns.Add("OriginalExpression", New TypeDescription("String"));
	ExpressionReplacementTable.Columns.Add("ReplacementExpression", New TypeDescription("String"));
	For Each OriginalExpressionAndReplacement In ResultOfTransformations.ConvertedExpressions Do
		OriginalExpression = OriginalExpressionAndReplacement.Key;
		Replacement = OriginalExpressionAndReplacement.Value;
		If OriginalExpression = Replacement Then
			// There were no substitutions of characteristics.
			Continue;
		EndIf;
		StringOfSubstitutions = ExpressionReplacementTable.Add();
		StringOfSubstitutions.OriginalExpression = Upper(OriginalExpression);
		StringOfSubstitutions.ReplacementExpression = Upper(Replacement);
	EndDo;
	ExpressionReplacementTable.Sort("OriginalExpression DESC");
	For Each FieldToEval In FactReceiptDCS.CalculatedFields Do
		ExpressionChanged = False;
		ExpressionOfCalculatedField = Upper(FieldToEval.Expression);
		For Each StringOfSubstitutions In ExpressionReplacementTable Do
			PositionNumber = StrFind(ExpressionOfCalculatedField, StringOfSubstitutions.OriginalExpression);
			While PositionNumber > 0 Do
				ExpressionChanged = True;
				ExpressionOfCalculatedField = StrReplace(ExpressionOfCalculatedField, StringOfSubstitutions.OriginalExpression, StringOfSubstitutions.ReplacementExpression);
				PositionNumber = StrFind(ExpressionOfCalculatedField, StringOfSubstitutions.OriginalExpression);
			EndDo;
		EndDo;
		If ExpressionChanged Then
			FieldToEval.Expression = ExpressionOfCalculatedField;
		EndIf;
	EndDo;
	
	#EndRegion
	
	#EndRegion 
	
	#Region TotalFields
		
	For Each TotalField In FactReceiptDCS.TotalFields Do 
		ColumnsAggregates.Add(TotalField.DataPath);
	EndDo;
	
	#EndRegion 
	
	Settings = BudgetingServer.InitializedDefaultSettings(FactReceiptDCS);
	DataCompositionClientServer.DisableOutputOfTotals(Settings);
	
	RootElementOfStructure = Settings.Structure;
	
	#Region Parameters
	
	// Let's set the general parameters
	DataCompositionClientServer.SetParameter(Settings, "ActualDataLimit", FactGettingParameters.ActualDataLimit);
	DataCompositionClientServer.SetParameter(Settings, "ReportCurrency", FactGettingParameters.ReportCurrency);
	DataCompositionClientServer.SetParameter(Settings, "InternationalCurrency", FactGettingParameters.InternationalCurrency);
	#EndRegion 
	
	#Region PrimaryDataSamplingSettings
	
	// Adding resource fields
	For Each ColumnAggregate In ColumnsAggregates Do 
		FinancialReportingServer.NewSelectionField(Settings, ColumnAggregate);
	EndDo;
	
	// Let's add data pre-filtering selections - the level of the data acquisition rule.
	GroupPreSelection = FinancialReportingServer.NewFilter(Settings.Filter,
		Undefined,, Type("DataCompositionFilterItemGroup"));
	GroupPreSelection.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	GroupPreSelection.Use = True;
	GroupPreSelection.Presentation = "PreSelection";
	
	AdditionalSelectionsInvolved = New Map; // The key is the name of the directory and the hash, the value is the linker with selections
	IIDSelectionGroups = New Map; // The key is the identifier of the data source, the value is a reference to the selection group
	KeyAddFilter = "";
	
	For Each RuleDetails In TableOfArticleRules Do
		DataSourceID = RuleDetails.DataSourceID;
		
		KeyAddFilter = DataSourceID + "_" + RuleDetails.SettingsHash;
		
		If IIDSelectionGroups[DataSourceID] = Undefined Then
			GroupDataSourceID = FinancialReportingServer.NewFilter(GroupPreSelection,
				Undefined,, Type("DataCompositionFilterItemGroup"));
			GroupDataSourceID.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			GroupDataSourceID.Use = True;
			GroupDataSourceID.Presentation = DataSourceID;
			
			FinancialReportingServer.NewFilter(GroupDataSourceID,
				"DataSourceID", DataSourceID);
			
			If DataSourcesServer.ThisIsItemOfAssetsLiabilities(RuleDetails.DataSource) Then
				ResultingTemplate = ReceivedTemplates.Get(DataSourceID);
				If ResultingTemplate <> Undefined Then
					SelectingSourceData = ResultingTemplate.DefaultSettings.Filter;
					If SelectingSourceData.Items.Count() > 0 Then
						DataCompositionClientServer.CopyElements(GroupDataSourceID, SelectingSourceData, False);
					EndIf;
				EndIf;
			EndIf;
			
			GroupAllAdditionalRuleSelections = FinancialReportingServer.NewFilter(GroupDataSourceID,
				Undefined,, Type("DataCompositionFilterItemGroup"));
			GroupAllAdditionalRuleSelections.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			GroupAllAdditionalRuleSelections.Use = True;
			GroupAllAdditionalRuleSelections.Presentation = "AllAdditionalRuleSelections_" + DataSourceID;
			
			IIDSelectionGroups.Insert(DataSourceID, GroupAllAdditionalRuleSelections);
		Else
			GroupAllAdditionalRuleSelections = IIDSelectionGroups[DataSourceID];
		EndIf;
		
		If AdditionalSelectionsInvolved[KeyAddFilter] = Undefined Then
			SettingsForAdditionalSelectionsRules = DataSourcesCached.GetStoredCatalogSettings(
				RuleDetails.SourceCatalogName,
				RuleDetails.SettingsHash);
			
			If SettingsForAdditionalSelectionsRules <> Undefined Then
				GroupDopingRules = FinancialReportingServer.NewFilter(GroupAllAdditionalRuleSelections,
					Undefined,, Type("DataCompositionFilterItemGroup"));
				GroupDopingRules.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				GroupDopingRules.Use = True;
				GroupDopingRules.Presentation = "DopingRules_" + KeyAddFilter;
				
				// Basic rule level selection - business transaction, account, or arbitrary value (arbitrary rules)
				// Let's apply the transformed hierarchical rule sources
				// For example, the account 08 specified in the PPFD will be represented by sub-accounts in the actual data.
				FinancialReportingServer.NewFilter(
					GroupDopingRules, 
					"DataSource",
					FactGettingParameters.HierarchyOfDataSources.MatchingForSelections[RuleDetails.DataSource],,
					DataCompositionComparisonType.InList);
				
				If TheseAreRevolutions
					And(RuleDetails.DataSourceSection = LocalAccounting 
						Or RuleDetails.DataSourceSection = FinancialAccounting)
					And ValueIsFilled(RuleDetails.CorDataSource) Then
					
					FinancialReportingServer.NewFilter(GroupDopingRules,
						"GroupCorAccount.BalancedAccount", RuleDetails.CorDataSource, , DataCompositionComparisonType.InHierarchy);
				EndIf;
	
				// User-defined rule level selections
				FinancialReportingServer.CopyFilter(SettingsForAdditionalSelectionsRules.Filter, GroupDopingRules, True);
				
				// Note that they have already been added so as not to complicate the work of the query optimizer SKD
				AdditionalSelectionsInvolved.Insert(KeyAddFilter, True);
			EndIf;
		EndIf;
	EndDo;
	
	If FactGettingParameters.Property("SelectionByRegistrarForAllFact") Then
		// Registrar selection for the purpose of optimizing the acquisition of turnover by articles, when
		// it is known that registrar selection should be applied to all articles of all data sources.
		// For example, when checking the passage of a document according to the limits of the DS. The effectiveness depends on the number of rules for obtaining the fact.
		FilterValue = FactGettingParameters.SelectionByRegistrarForAllFact.RightValue;
		If TypeOf(FilterValue) = Type("Array") Then
			TypeOfSelectionComparison = DataCompositionComparisonType.InList;
		Else
			TypeOfSelectionComparison = FactGettingParameters.SelectionByRegistrarForAllFact.ComparisonType;
		EndIf;
		FinancialReportingServer.NewFilter(
			Settings.Filter,
			"Recorder",
			FilterValue,,
			TypeOfSelectionComparison);
	EndIf;
	
	#EndRegion 
	
	#Region GroupingAndMappingData
	
	GroupingDataChunks = FinancialReportingServer.NewGrouping(RootElementOfStructure);
	
	// Let's add basic fields that define the nature of the selected data
	FinancialReportingServer.NewDimensionField(GroupingDataChunks, "BudgetFlowItem");
	FinancialReportingServer.NewDimensionField(GroupingDataChunks, "BudgetBalanceItem");
	FinancialReportingServer.NewDimensionField(GroupingDataChunks, "ID_" + "Source1");
	FinancialReportingServer.NewDimensionField(GroupingDataChunks, "Period");
	If TheseAreRevolutions Then
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, "BeginOfPeriod");
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, "EndOfPeriod");
	EndIf;
	FinancialReportingServer.NewDimensionField(GroupingDataChunks, "Scenario");
	
	If ByPeriods Then
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, ExpressingPlanningPeriod);
	EndIf;
	
	If ByRegistrar Then
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, "Recorder");
	EndIf;
	
	If ByCurrency Then
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, "Currency");
	EndIf;
	
	FinancialReportingServer.NewDimensionField(GroupingDataChunks, "StorageCurrency");
	FinancialReportingServer.NewDimensionField(GroupingDataChunks, "RatePeriod");
	
	If ByUnitsOfMeasurement Then
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, "UnitOfMeasure");
	EndIf;
	
	If DataAcquisitionRules Then
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, "RuleOfFact");
	EndIf;
	
	// Add end-to-end measurements
	If ByCompanies Then
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, "Organization");
	EndIf;
	
	If ByBusinessUnits Then
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, "Department");
	EndIf;
	
	// Add numbered analytics
	For DimensionNumber = 1 To MaximumNumberOfAnalytics Do 
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, "Dimension" + DimensionNumber);
	EndDo;
	
	// Let's add named analytics
	For Each DimensionKind In RequestedTypesOfAnalytics Do
		NameOfAnalyticsField = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		
		FinancialReportingServer.NewDimensionField(GroupingDataChunks, NameOfAnalyticsField);
	EndDo;
	
	// We will add selections of the final filtering of data by sources
	If FactGettingParameters.AdditionalSelection <> Undefined Then
		FinancialReportingServer.CopyFilter(FactGettingParameters.AdditionalSelection.Filter,
			GroupingDataChunks.Filter, True);
	EndIf;
	
	// Let's add selections for accurate data acquisition in the context of data acquisition rules
	PPFDDataMappingGroup = FinancialReportingServer.NewFilter(GroupingDataChunks.Filter,
		Undefined,, Type("DataCompositionFilterItemGroup"));
	PPFDDataMappingGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	PPFDDataMappingGroup.Use = True;
	PPFDDataMappingGroup.Presentation = "PPFDDataMapping";
	
	GroupSelectionsUsed = New Map; // The key is the PPF, the value is the link to the selection group
	KeyAddFilter = "";
	
	For Each RuleDetails In TableOfArticleRules Do 
		RuleOfFact = RuleDetails.RuleOfFact;
		
		If GroupSelectionsUsed[RuleOfFact] = Undefined Then
			PPFDGroup = FinancialReportingServer.NewFilter(PPFDDataMappingGroup,
				Undefined,, Type("DataCompositionFilterItemGroup"));
			PPFDGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			PPFDGroup.Use = True;
			PPFDGroup.Presentation = "PPFD_" + RuleDetails.UUID;
			
			FinancialReportingServer.NewFilter(PPFDGroup, "RuleOfFact", RuleOfFact);
			
			GroupSelectionsUsed.Insert(RuleOfFact, PPFDGroup);
			SettingsForAdditionalSelectionsRules = DataSourcesCached.GetStoredCatalogSettings(
				RuleDetails.SourceCatalogName, 
				RuleDetails.SettingsHash); // DataCompositionSettings -
			
			If SettingsForAdditionalSelectionsRules <> Undefined
				And SettingsForAdditionalSelectionsRules.Filter.Items.Count() > 0 Then
				
				FinancialReportingServer.CopyFilter(SettingsForAdditionalSelectionsRules.Filter, PPFDGroup, True);
			EndIf;
		EndIf;
	EndDo;
	
	// Adding selections by non-zero resource fields
	GroupSelectionOfNonZero = FinancialReportingServer.NewFilter(GroupingDataChunks.Filter,
		Undefined,, Type("DataCompositionFilterItemGroup"));
	GroupSelectionOfNonZero.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	GroupSelectionOfNonZero.Use = True;
	GroupSelectionOfNonZero.Presentation = "SelectionOfNonzero";
	
	For Each ColumnAggregate In ColumnsAggregates Do
		FinancialReportingServer.NewFilter(GroupSelectionOfNonZero, ColumnAggregate, 0,, DataCompositionComparisonType.NotEqual);
	EndDo;
	
	#EndRegion 
	
	#Region GetData
	
	Try
		DataAcquisitionTemplate = FinancialReportingServer.PrepareLayoutTemplateForUploadingDCS(FactReceiptDCS, Settings);
	Except
		TemplateText = NStr("vi = 'Lỗi khi nhận quy tắc tính theo kịch bản %1. Hãy kiểm tra %2';
							|ru = 'Ошибка при получении правил расчета по сценарию %1. Проверьте %2';
							|en = 'An error occurred when getting calculation rules by the %1 scenario. Please check %2'; fa = 'An error occurred when getting calculation rules by the %1 scenario. Please check %2';
							|it = 'Errore durante la ricezione delle regole di calcolo in base allo scenario %1. Verificare %2';
							|pl = 'Błąd podczas odbioru reguł obliczenia według scenariusza %1. Sprawdź %2';
							|tr = '%1 senaryosuna göre hesaplama kuralı alımında hata. %2 kontrol edilmeli'");
		Raise(StrTemplate(TemplateText, FactGettingParameters.Scenario, Lower(Metadata.Catalogs[SourceCatalogName].Synonym)));
	EndTry;
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("TableOfDataAreas", TableOfDataAreas);
	ExternalDataSets.Insert("AdditionalDataTable", AdditionalDataTable);
	ExternalDataSets.Insert("HierarchyOfDataSources", FactGettingParameters.HierarchyOfDataSources.ComparisonTable_);
	If TheseAreRevolutions Then
		ExternalDataSets.Insert("ComparisonOfCorAccounts", FactGettingParameters.HierarchyOfDataSources.TableOfComparisonsOfCorAccounts);
	EndIf;
	
	SourceDataByRules = Undefined;
	If FactGettingParameters.AccessRestrictions.ThereIsPrivilegedMode Then
		UploadResultAccordingToLayoutTakingIntoAccountAccessRestrictions(SourceDataByRules, DataAcquisitionTemplate, ExternalDataSets, True);
	EndIf;
	If FactGettingParameters.AccessRestrictions.ThereIsNoPrivilegedMode Then
		UploadResultAccordingToLayoutTakingIntoAccountAccessRestrictions(SourceDataByRules, DataAcquisitionTemplate, ExternalDataSets, False);
	EndIf;
	
	#EndRegion 
	
	#Region DataPostProcessing
	
	// "Collapse" the rule ID columns into one
	If (AdditionalDataCalculatedFields Or AdditionalDataAdditionalSet)
		And DataAcquisitionRules Then
		
		For DimensionNumber = 1 To MaximumNumberOfAnalytics Do 
			If Not NumberedAnalyticsUsed.Property("Dimension" + DimensionNumber) Then
				Continue;
			EndIf;
			
			ColumnIds.Add("Dimension" + DimensionNumber);
		EndDo;
		
		ColumnIds = CommonClientServer.CollapseArray(ColumnIds);
		
		RowOfIdentifiersColumn = StrConcat(ColumnIds, ", ");
		
		IDs = AdditionalDataTable.UnloadColumn("UUID");
		DataSourcesServer.CollapseByIDColumns(
			SourceDataByRules, 
			RowOfIdentifiersColumn, 
			IDs, "_", 
			ColumnsAggregates,
			True);
		
		IDs.Clear();
		
		If FactGettingParameters.Indicators.Property("Sum") Then
			ColumnsAmountIds = "Sum";
			
			For Each ColumnAggregate In ColumnsAggregates Do 
				IDs.Add(StrReplace(ColumnAggregate, "Sum", ""));
			EndDo;
			
			DataSourcesServer.CollapseByIDColumns(SourceDataByRules,
				ColumnsAmountIds, IDs);
		EndIf;
		
		If FactGettingParameters.Indicators.Property("Count") And False Then
			ColumnsQuantityIds = "Count";
			
			For Each ColumnAggregate In ColumnsAggregates Do 
				IDs.Add(StrReplace(ColumnAggregate, "Count", ""));
			EndDo;
			
			DataSourcesServer.CollapseByIDColumns(SourceDataByRules,
				ColumnsQuantityIds, IDs);
		EndIf;
		
	EndIf;
	
	#EndRegion 
	
	// Return the fact table
	TableIndexes_ = FactGettingParameters.TableIndexes.Get("TableOfArticleRules");
	DataSourcesServer.SetIndexesFromArray(TableOfArticleRules, TableIndexes_);
	
	Return SourceDataByRules;
	
EndFunction

// Returns the values of non-financial indicators according to their settings
//
// Parameters:
// 	Filter_Settings - DataCompositionSettings - Settings for selecting rules.
// 	Parameters - Structure - Parameters for obtaining actual data:
// 	 *Period - StandardPeriod - data acquisition period.
// 	 *Periodicity - EnumRef.Periodicity - The frequency of the received data.
// 
// Returns:
// 	ValueTable - Values of non-financial indicators:
// 	* NonFinancialItem - CatalogRef.NonFinancialItemsOfBudgets - Non-financial indicator.
// 	* IndicatorKind - EnumRef.NonFinancialItemKinds - type of indicator.
// 	* Organization - CatalogRef.Companies - organization (if getting data in the context of organizations).
// 	* Department - CatalogRef.BusinessStructure - division (if getting data by division).
// 	* Scenario - CatalogRef.BudgetingScenarios - Scenario.
// 	* Currency - CatalogRef.Currencies - Currency.
// 	* UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - Unit of measurement for quantitative values.
// 	* Recorder - DocumentRef - Registrar.
// 	* Period - Date - Period.
// 	* InstallationPeriod - Date - Period for setting the value.
// 	* SubperiodNumber - Number - The number of subperiods.
// 	* IndicatorValue - Number - meaning.
Function NonFinancialItemValues(Filter_Settings, Val Parameters) Export
	
	PeriodsTable = Planning.PeriodTableTemplate();
	
	If Not ValueIsFilled(Parameters.Periodicity) Then
		Period = PeriodsTable.Add();
		Period.StartDate = Parameters.Period.StartDate;
		Period.EndDate = Parameters.Period.EndDate;
	Else
		Planning.FillInPeriodTable(
			PeriodsTable, 
			Parameters.Periodicity, 
			Parameters.Period.StartDate, 
			Parameters.Period.EndDate);
	EndIf;
	Parameters.Insert("PeriodsTable", PeriodsTable);
	
	ValueTable = TemplateForTableOfValuesOfNonFinancialIndicators(Parameters);
	
	NonFinancialIndicators = Catalogs.NonFinancialItemsOfBudgets.NonFinancialIndicatorsBasedOnSelection(Filter_Settings);
	For Each IndicatorLine_ In NonFinancialIndicators Do
		If IndicatorLine_.ImportFromOtherSubsystems Then
			If ValueIsFilled(IndicatorLine_.DataCompositionSchema) Then
				DataAcquisitionScheme = Catalogs.NonFinancialItemsOfBudgets.PredefinedDataAcquisitionScheme(
					IndicatorLine_.DataCompositionSchema,
					?(Parameters.Property("DataReceiptMode"), Parameters.DataReceiptMode, Undefined));
			Else
				StorageOfDataCompositionSchema = IndicatorLine_.StorageOfDataCompositionSchema; // ValueStorage
				DataAcquisitionScheme = StorageOfDataCompositionSchema.Get();
				If TypeOf(DataAcquisitionScheme) = Type("ValueStorage") Then
					DataAcquisitionScheme = DataAcquisitionScheme.Get();
				EndIf;
				If Parameters.DataReceiptMode = Enums.BudgetingDataReceiptMode.All Then
					For Each Set In DataAcquisitionScheme.DataSets Do
						If ValueIsFilled(Set.Query) Then
							Set.Query = RequestSchemes.SetSelectionOfAllowedRecordsInEntireRequest(Set.Query, False);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			StorageOfDataCompositionSettings = IndicatorLine_.StorageOfDataCompositionSettings; // ValueStorage
			DataAcquisitionSchemeSettings = StorageOfDataCompositionSettings.Get();
			Rule = RuleForObtainingNonFinancialIndicatorValues(IndicatorLine_, DataAcquisitionScheme, DataAcquisitionSchemeSettings);
			NonFinancialIndicatorValuesAccordingToRule(Rule, Parameters, ValueTable);
		EndIf;
		If IndicatorLine_.ByScenarios Or Not IndicatorLine_.ImportFromOtherSubsystems Then
			DataAcquisitionScheme = InformationRegisters.NonFinancialItemValues.GetTemplate("DataCompositionSchema");
			If Parameters.DataReceiptMode = Enums.BudgetingDataReceiptMode.All Then
				For Each Set In DataAcquisitionScheme.DataSets Do
					If ValueIsFilled(Set.Query) Then
						Set.Query = RequestSchemes.SetSelectionOfAllowedRecordsInEntireRequest(Set.Query, False);
					EndIf;
				EndDo;
			EndIf;
			
			DataAcquisitionSchemeSettings = DataAcquisitionScheme.DefaultSettings;
			DataCompositionClientServer.AddFilter(
				DataAcquisitionSchemeSettings, 
				"NonFinancialItem", 
				IndicatorLine_.NonFinancialItem);
			Rule = RuleForObtainingNonFinancialIndicatorValues(IndicatorLine_, DataAcquisitionScheme, DataAcquisitionSchemeSettings);
			Rule.AdvancedModeOfDimensionFillSetting = False;
			NonFinancialIndicatorValuesAccordingToRule(Rule, Parameters, ValueTable);
		EndIf;
	EndDo;
	
	Return ValueTable;
	
EndFunction

// Adds conversion algorithms to an existing schema
// 
// Parameters:
//	Schema - DataCompositionSchema - changeable scheme where you want to convert amounts.
//	SettingsComposer - DataCompositionSettingsComposer - change the settings
//	RecalculationParameters - See BudgetingServer.TemplateForCurrencyConversionParameters
//
Procedure AddDataConversionToCurrency(Schema, SettingsComposer, Val RecalculationParameters) Export
	
	// Variable initialization
	NameOfSourceDataSet = RecalculationParameters.NameOfSourceDataSet;
	ConversionDataSetNumber = RecalculationParameters.ConversionDataSetNumber;
	SourceOfExchangeRates = RecalculationParameters.SourceOfExchangeRates;
	SourceCurrency = RecalculationParameters.SourceCurrency;
	ConversionColumns = RecalculationParameters.ConversionColumns;
	RatePeriod = RecalculationParameters.RatePeriod;
	ForecastRateScenario = RecalculationParameters.ForecastRateScenario;
	TargetCurrency = RecalculationParameters.TargetCurrency;
	
	ForecastRateScenarioIsRequired = (SourceOfExchangeRates = "ForecastedExchangeRatesOfScenarios");
	
	NameOfConversionDataSet = "CurrencyExchangeRateCoefficients" + NameOfSourceDataSet + ConversionDataSetNumber;
	ConversionDataSet = Schema.DataSets.Find(NameOfConversionDataSet);
	
	SourceDataSet = Schema.DataSets[NameOfSourceDataSet];
	NameOfSourceDatasetWithNumber = NameOfSourceDataSet + ConversionDataSetNumber;
	
	// Modification of the scheme and settings
	If ConversionDataSet = Undefined Then
		ConversionDataSet = DataCompositionServer.AddEmptyDataSet(Schema, , NameOfConversionDataSet);
		
		TextOfConversionRequest = 
		"SELECT ALLOWED
		|	CurrencyExchangeRate.Currency AS CurrencyOfExchangeRates" + NameOfSourceDatasetWithNumber + ",
		|	&SourceCurrency" + NameOfSourceDatasetWithNumber + " AS SourceCurrency" + NameOfSourceDatasetWithNumber + ",
		|	&TargetCurrency" + NameOfSourceDatasetWithNumber + " AS TargetCurrency" + NameOfSourceDatasetWithNumber + ",
		|	CurrencyExchangeRate.CourseNumerator * ReportCurrencyRate.CourseDenominator / (CurrencyExchangeRate.CourseDenominator * ReportCurrencyRate.CourseNumerator) AS ConversionFactor_" + NameOfSourceDatasetWithNumber + "
		|FROM
		|	InformationRegister." + SourceOfExchangeRates + ".SliceLast(
		|			&RatePeriod" + NameOfSourceDatasetWithNumber + ",
		|			Currency = &SourceCurrency" + NameOfSourceDatasetWithNumber + "
		|			" + ?(ForecastRateScenarioIsRequired, "AND Scenario = &Scenario" + NameOfSourceDatasetWithNumber, "") + " AND BaseCurrency = &BaseCurrency
		|		) AS CurrencyExchangeRate
		|		INNER JOIN InformationRegister." + SourceOfExchangeRates + ".SliceLast(
		|			&RatePeriod" + NameOfSourceDatasetWithNumber + ", 
		|			Currency = &TargetCurrency" + NameOfSourceDatasetWithNumber + "
		|			" + ?(ForecastRateScenarioIsRequired, "AND Scenario = &Scenario" + NameOfSourceDatasetWithNumber, "") + " AND BaseCurrency = &BaseCurrency
		|		) AS ReportCurrencyRate
		|		On (TRUE)
		|WHERE
		|	CurrencyExchangeRate.CourseDenominator <> 0
		|	AND ReportCurrencyRate.CourseNumerator <> 0";

		ConversionDataSet.Query = TextOfConversionRequest;
		FinancialReportingServer.NewSetField(ConversionDataSet,
			"CurrencyOfExchangeRates" + NameOfSourceDatasetWithNumber,,, New TypeDescription("CatalogRef.Currencies"));
		FinancialReportingServer.NewSetField(ConversionDataSet,
			"SourceCurrency" + NameOfSourceDatasetWithNumber,,, New TypeDescription("CatalogRef.Currencies"));
		FinancialReportingServer.NewSetField(ConversionDataSet,
			"TargetCurrency" + NameOfSourceDatasetWithNumber,,, New TypeDescription("CatalogRef.Currencies"));
		FinancialReportingServer.NewSetField(ConversionDataSet,
			"ConversionFactor_" + NameOfSourceDatasetWithNumber); // We do not limit the length of the coefficient
		If ForecastRateScenarioIsRequired Then
			FinancialReportingServer.NewSetField(ConversionDataSet,
				"Scenario" + NameOfSourceDatasetWithNumber, , , New TypeDescription("CatalogRef.BudgetingScenarios"));
		EndIf;
		
		DataCompositionServer.AddParameter(Schema, "SourceCurrency" + NameOfSourceDatasetWithNumber,, SourceCurrency);
		DataCompositionServer.AddParameter(Schema, "TargetCurrency" + NameOfSourceDatasetWithNumber,, TargetCurrency);
		DataCompositionServer.AddParameter(Schema, "RatePeriod" + NameOfSourceDatasetWithNumber,, RatePeriod);
		DataCompositionServer.SetDCSParameter(Schema, "BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		If ForecastRateScenarioIsRequired Then
			DataCompositionServer.AddParameter(Schema, "Scenario" + NameOfSourceDatasetWithNumber,, ForecastRateScenario);
		EndIf;
	EndIf;
	
	// Let's clarify the values of the data parameters for recalculation
	DataCompositionServer.SetDCSParameter(Schema, "SourceCurrency" + NameOfSourceDatasetWithNumber, SourceCurrency);
	DataCompositionServer.SetDCSParameter(Schema, "TargetCurrency" + NameOfSourceDatasetWithNumber, TargetCurrency);
	DataCompositionServer.SetDCSParameter(Schema, "RatePeriod" + NameOfSourceDatasetWithNumber, RatePeriod);
	DataCompositionServer.SetDCSParameter(Schema, "BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	If ForecastRateScenarioIsRequired Then
		DataCompositionServer.SetDCSParameter(Schema, "Scenario" + NameOfSourceDatasetWithNumber, ForecastRateScenario);
	EndIf;
		
	ParameterTypeSourceCurrency = TypeOf(SourceCurrency);
	If ParameterTypeSourceCurrency = Type("CatalogRef.Currencies") Then
		DataCompositionClientServer.SetParameter(SettingsComposer,
			"SourceCurrency" + NameOfSourceDatasetWithNumber, SourceCurrency);
	ElsIf ParameterTypeSourceCurrency = Type("String") Then
		DataCompositionServer.AddDataSetAssociation(Schema,
			NameOfSourceDataSet,
			NameOfConversionDataSet,
			SourceCurrency, 
			"SourceCurrency" + NameOfSourceDatasetWithNumber,
			"SourceCurrency" + NameOfSourceDatasetWithNumber);
	ElsIf ParameterTypeSourceCurrency = Undefined Then
		DataCompositionServer.AddDataSetAssociation(Schema,
			NameOfSourceDataSet,
			NameOfConversionDataSet,
			"SourceCurrency" + NameOfSourceDatasetWithNumber,
			"SourceCurrency" + NameOfSourceDatasetWithNumber,
			"SourceCurrency" + NameOfSourceDatasetWithNumber);
	EndIf;
	
	TargetCurrencyParameterType = TypeOf(TargetCurrency);
	If TargetCurrencyParameterType = Type("CatalogRef.Currencies") Then
		DataCompositionClientServer.SetParameter(SettingsComposer,
			"TargetCurrency" + NameOfSourceDatasetWithNumber, TargetCurrency);
	ElsIf TargetCurrencyParameterType = Type("String") Then
		DataCompositionServer.AddDataSetAssociation(Schema,
			NameOfSourceDataSet,
			NameOfConversionDataSet,
			TargetCurrency,
			"TargetCurrency" + NameOfSourceDatasetWithNumber,
			"TargetCurrency" + NameOfSourceDatasetWithNumber);
	ElsIf TargetCurrencyParameterType = Undefined Then
		DataCompositionServer.AddDataSetAssociation(Schema,
			NameOfSourceDataSet,
			NameOfConversionDataSet, 
			"TargetCurrency" + NameOfSourceDatasetWithNumber,
			"TargetCurrency" + NameOfSourceDatasetWithNumber,
			"TargetCurrency" + NameOfSourceDatasetWithNumber);
	EndIf;
	
	If ForecastRateScenarioIsRequired Then
		TypeOfScenarioParameter = TypeOf(ForecastRateScenario);
		If TypeOfScenarioParameter = Type("CatalogRef.BudgetingScenarios") Then
			DataCompositionClientServer.SetParameter(SettingsComposer,
				"Scenario" + NameOfSourceDatasetWithNumber, ForecastRateScenario);
		ElsIf TypeOfScenarioParameter = Type("String") Then
			DataCompositionServer.AddDataSetAssociation(Schema,
				NameOfSourceDataSet,
				NameOfConversionDataSet,
				ForecastRateScenario,
				"Scenario" + NameOfSourceDatasetWithNumber,
				"Scenario" + NameOfSourceDatasetWithNumber);
		ElsIf TypeOfScenarioParameter = Undefined Then
			DataCompositionServer.AddDataSetAssociation(Schema,
				NameOfSourceDataSet,
				NameOfConversionDataSet,
				"Scenario" + NameOfSourceDatasetWithNumber,
				"Scenario" + NameOfSourceDatasetWithNumber,
				"Scenario" + NameOfSourceDatasetWithNumber);
		EndIf;
	EndIf;
	
	ParameterTypeCoursePeriod = TypeOf(RatePeriod);
	If ParameterTypeCoursePeriod = Type("Date") Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "RatePeriod" + NameOfSourceDatasetWithNumber, RatePeriod);
	ElsIf ParameterTypeCoursePeriod = Type("String") Then
		DataCompositionServer.AddDataSetAssociation(Schema,
			NameOfSourceDataSet,
			NameOfConversionDataSet,
			RatePeriod,
			"RatePeriod" + NameOfSourceDatasetWithNumber,
			"RatePeriod" + NameOfSourceDatasetWithNumber);
	ElsIf ParameterTypeCoursePeriod = Undefined Then
		DataCompositionServer.AddDataSetAssociation(Schema,
			NameOfSourceDataSet,
			NameOfConversionDataSet,
			"RatePeriod" + NameOfSourceDatasetWithNumber,
			"RatePeriod" + NameOfSourceDatasetWithNumber,
			"RatePeriod" + NameOfSourceDatasetWithNumber);
	EndIf;
	
	ParameterTypeOfRecalculationColumn = TypeOf(ConversionColumns);
	If ParameterTypeOfRecalculationColumn = Type("Array") Then
		CurrencyAmountFields = ConversionColumns;

	ElsIf ParameterTypeOfRecalculationColumn = Type("String") Then
		CurrencyAmountFields = New Array;
		CurrencyAmountFields.Add(ConversionColumns);
		
	ElsIf ParameterTypeOfRecalculationColumn = Undefined Then
		CurrencyAmountFields = New Array;
		CurrencyAmountFields.Add("Sum");
		CurrencyAmountFields.Add("SumReceipt");
		CurrencyAmountFields.Add("SumExpense");
		CurrencyAmountFields.Add("AmountInCurrency");
		CurrencyAmountFields.Add("SumCurrReceipt");
		CurrencyAmountFields.Add("SumCurrExpense");
		CurrencyAmountFields.Add("IndicatorValue");
	EndIf;
	
	For Each Field In CurrencyAmountFields Do
		SourceFieldYouAreLookingFor = Schema.CalculatedFields.Find(Field);
		
		If SourceFieldYouAreLookingFor <> Undefined Then
			SourceFieldYouAreLookingFor.Expression = "ROUND(" + SourceFieldYouAreLookingFor.Expression + " * ConversionFactor_"
				+ NameOfSourceDatasetWithNumber + ", 2)";
		Else
			SourceFieldYouAreLookingFor = SourceDataSet.Fields.Find(Field);
			
			If SourceFieldYouAreLookingFor = Undefined Then
				Continue;
			EndIf;
			
			Expression = "ROUND(" + Field + " * ConversionFactor_" + NameOfSourceDatasetWithNumber + ", 2)";
			FinancialReportingServer.NewCalculatedField(Schema, Field, Expression, SourceFieldYouAreLookingFor.Title, True);
		EndIf;
	EndDo;
	
EndProcedure

// Gets the value of the constant "address of publication of the information base in the local network"in privileged mode.
//
// Returns:
//   String - the value of the constant.
//
Function LocalInfobasePublishingURL() Export
	
	Value = Undefined; //Only for use in the UP
	SetPrivilegedMode(True);
	Value = Constants.LocalInfobasePublishingURL.Get();
	SetPrivilegedMode(False);
	Return Value;
	
EndFunction

// Gets the value of the "Use international financial accounting" constant in privileged mode.
// Only for ERP.
//
// Returns:
//   Boolean - the value of the constant.
//
Function InternationalAccountingIsUsed() Export
	
	Value = False; //Only for use in the UP
	SetPrivilegedMode(True);
	Value = Constants.UseFinancialAccounting.Get();
	SetPrivilegedMode(False);
	Return Value;
	
EndFunction

// Removes layouts, budgets, saved in the attached file the copy of the budget
// 
// Parameters:
//	Filter - CatalogRef.BudgetProfiles, DocumentRef.BudgetEntryForm - selection that will be used to determine the instance
//				the budget for the removal of attached files.
//
Procedure DeleteSavedBudgetTemplates(Filter) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "SELECT
	|	BudgetEntryFormAttachedFiles.Ref
	|FROM
	|	Catalog.BudgetEntryFormAttachedFiles AS BudgetEntryFormAttachedFiles
	|		INNER JOIN Document.BudgetEntryForm AS BudgetEntryForm
	|		ON BudgetEntryFormAttachedFiles.FileOwner = BudgetEntryForm.Ref
	|WHERE
	|	BudgetEntryFormAttachedFiles.ServiceFileType <> VALUE(Enum.ServiceFileTypesOfBudgetEntryForm.EmptyRef)
	|	AND &BudgetInstanceSelectionText";
	
	If TypeOf(Filter) = Type("CatalogRef.BudgetProfiles")
		And ValueIsFilled(Filter) Then
		
		Query.Text = StrReplace(Query.Text, "&BudgetInstanceSelectionText", "BudgetEntryForm.BudgetProfile = &Filter");
		
	ElsIf TypeOf(Filter) = Type("DocumentRef.BudgetEntryForm")
		And ValueIsFilled(Filter) Then
		
		Query.Text = StrReplace(Query.Text, "&BudgetInstanceSelectionText", "BudgetEntryForm.Ref = &Filter");
		
	Else
		
		SetPrivilegedMode(False);
		ErrorText = StrTemplate(NStr("vi = 'Thủ tục ""%1"": Sai tham số gọi ra';
									|ru = 'Процедура ""%1"": Неверные параметры вызова';
									|en = 'Procedure ""%1"": Invalid call parameters'; fa = 'Procedure ""%1"": Invalid call parameters';
									|it = 'Procedura ""%1"": Parametri errati di chiamata';
									|pl = 'Procedura ""%1"": Niepoprawne parametry wywołania';
									|tr = '""%1"" prosedürü: Geçersiz çağrı parametreleri'"), "DeleteSavedBudgetTemplates");
		Raise ErrorText;
	EndIf;
	
	Query.SetParameter("Filter", Filter);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Object = Selection.Ref.GetObject(); // CatalogObject
		Object.Delete();
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Returns the types of Analytics for the passed supported data source reference.
//
// Parameters:
//	DataSource - CatalogRef.ActualDataQueryRulesByBudgetBalanceItems - supported reference-data source.
//					- CatalogRef.ActualDataQueryRulesByBudgetFlowItems -
//					- CatalogRef.NonFinancialItemsOfBudgets -
//					- CatalogRef.BudgetBalanceItems -
//					- CatalogRef.BudgetFlowItems -
//	OutputAddFields - Boolean - True if you need to display the types of values and names of analytics.
//
// Returns:
//	Structure - types of data source analytics:
//		*DimensionKind1 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//		*DimensionKind2 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//		*DimensionKind3 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//		*DimensionKind4 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//		*DimensionKind5 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//		*DimensionKind6 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//
Function DimensionKinds(DataSource, OutputAddFields = False) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	Attributes = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		Attributes.Add("DimensionKind" + DimensionNumber);
		If OutputAddFields Then
			Attributes.Add("DimensionKind" + DimensionNumber + ".ValueType");
			Attributes.Add("DimensionKind" + DimensionNumber + ".Description");
			Attributes.Add("DimensionKind" + DimensionNumber + ".AdditionalProperty");
		EndIf;
	EndDo;
	
	If TypeOf(DataSource.Ref) = Type("CatalogRef.ActualDataQueryRulesByBudgetBalanceItems") Then
		DimensionKinds = Common.ObjectAttributesValues(DataSource.BudgetBalanceItem, Attributes);
		
	ElsIf TypeOf(DataSource.Ref) = Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems") Then
		DimensionKinds = Common.ObjectAttributesValues(DataSource.BudgetFlowItem, Attributes);
		
	ElsIf TypeOf(DataSource) = Type("CatalogRef.NonFinancialItemsOfBudgets")
		Or TypeOf(DataSource) = Type("CatalogRef.BudgetFlowItems")
		Or TypeOf(DataSource) = Type("CatalogRef.BudgetBalanceItems") Then
		DimensionKinds = Common.ObjectAttributesValues(DataSource, Attributes);
		
	EndIf;
	
	Return DimensionKinds;
	
EndFunction

// Adds calculated fields to the schema for analytical slices, and grouping fields to the settings.
// 
// Parameters:
//	DataCompositionSchema - DataCompositionSchema - dynamically supplemented by data source schema
//	Settings - DataCompositionSettings - dynamically updated data layout settings
//	DataSource - CatalogRef.ActualDataQueryRulesByBudgetBalanceItems - supported reference-data source.
//					- CatalogRef.ActualDataQueryRulesByBudgetFlowItems -
//					- CatalogRef.NonFinancialItemsOfBudgets -
//	Parameters - See BudgetingServer.TemplateForGettingFactParameters
//
Procedure AddAnalyticsFields(DataCompositionSchema, Settings, DataSource, Parameters)
	
	DimensionKinds = New ValueTable;
	DimensionKinds.Columns.Add("DimensionNumber", New TypeDescription("Number"));
	DimensionKinds.Columns.Add("DimensionKind", New TypeDescription("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions"));
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		NewRow = DimensionKinds.Add();
		NewRow.DimensionNumber = DimensionNumber;
		NewRow.DimensionKind = DataSource["DimensionKind" + DimensionNumber];
	EndDo;
	
	If DataSource.AdvancedModeOfDimensionFillSetting Then
		AnalyticsFillInExpressions = ExpressionsForFillingInAnalyticsByRule(DataSource, DimensionKinds, DataCompositionSchema);
	Else
		AnalyticsFillInExpressions = ExpressionsForFillingInAnalyticsAccordingToDataLayoutScheme(DataCompositionSchema, DimensionKinds, True);
	EndIf;
	
	CalculatedFields = DataCompositionSchema.CalculatedFields;
	
	// Let's add analytics "by number"
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		
		AnalyticsFieldByNumber = "Dimension" + DimensionNumber;
		
		SearchResult = AnalyticsFillInExpressions.Find(DimensionNumber, "DimensionNumber");
		
		FieldToEval = CalculatedFields.Add();
		FieldToEval.DataPath = AnalyticsFieldByNumber;
		If ValueIsFilled(SearchResult.Expression) Then
			ValueType = SearchResult.ValueType;
			Expression = SearchResult.Expression;
		Else
			ValueType = AllTypesOfAnalytics();
			Expression   = ExpressingEmptyValue();
		EndIf;
		FieldToEval.Expression = Expression;
		FieldToEval.ValueType = ValueType;
		
		AddGroupField(Settings, AnalyticsFieldByNumber);
		
	EndDo;
	
	// Let's add analytics "by type"
	TypesOfViewsTypesOfAnalytics = BudgetingCached.TypesOfViewsTypesOfAnalytics();
	
	If Parameters.Property("Analysts") Then
		Analysts = Parameters.Analysts;
	Else
		Analysts = TypesOfViewsTypesOfAnalytics.UnloadColumn("Ref");
		
		Parameters.Insert("Analysts", Analysts);
	EndIf;
	
	For Each LineTypesOfViewsTypesOfAnalytics In TypesOfViewsTypesOfAnalytics Do
		DimensionKind = LineTypesOfViewsTypesOfAnalytics.Ref;
		
		If Analysts.Find(DimensionKind) = Undefined Then
			Continue;
		EndIf;
		
		AnalyticsFieldByType = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		SearchResult = AnalyticsFillInExpressions.Find(DimensionKind, "DimensionKind");
		Expression = "";
		If Not SearchResult = Undefined Then
			Expression = ExpressingAnalyticsValueBySourceAndType(SearchResult.Expression, DimensionKind);
		EndIf;
		If Not ValueIsFilled(Expression) Then
			Expression = ExpressingEmptyValue();
		EndIf;
		
		If AnalyticsFieldByType <> Expression Then
			FieldToEval = CalculatedFields.Add();
			FieldToEval.DataPath = AnalyticsFieldByType;
			FieldToEval.Expression   = Expression;
			FieldToEval.ValueType = LineTypesOfViewsTypesOfAnalytics.ValueType;
		EndIf;
		
		If Parameters.DimensionKinds.Find(DimensionKind) <> Undefined Then
			AddGroupField(Settings, AnalyticsFieldByType);
		EndIf;
		
	EndDo;
	
	// Analytics Currency
	If DataSource.CurrencyFilling <> "DontFill" Then
		
		InReportCurrency = False;
		CalculatedCurrencyField = CalculatedFields.Add();
		CalculatedCurrencyField.DataPath = "Currency";
		CalculatedCurrencyField.ValueType = New TypeDescription("CatalogRef.Currencies");
		
		If DataSource.CurrencyFilling = "DeterminedByAnalytics" Then
			
			ExpressionAnalytics = CalculatedFields.Find("Dimension" + DataSource.DimensionAddressCurrency);
			
			CalculatedCurrencyField.Expression = 
			"CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
			|	&CacheAnalystValues, 
			|	" + ExpressionAnalytics.Expression + ", 
			|	""" + DataSource.DimensionCurrencyField + """,
			|	&Currency), ""Catalog.Currencies"")";
			
			AddParameter(DataCompositionSchema, "CacheAnalystValues", New Map);
			AddParameter(DataCompositionSchema, "Currency", Parameters.ReportCurrency);
			
		ElsIf DataSource.CurrencyFilling = "DeterminedByDataSource" Then 
			
			SetFields = DataCompositionSchema.DataSets[0].Fields;
			
			If DataSource.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting 
				And Not DataSource.SourceOfForeignExchange Then
				CalculatedCurrencyField.Expression = "Organization.LocalAccountingCurrency";
			ElsIf DataSource.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting
				And Not DataSource.SourceOfForeignExchange Then
				If GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting") Then
					CalculatedCurrencyField.Expression = "FinancialAccountingServerCached.CurrencyFunctional(FinancialAccountingChartOfAccounts, Organization)";
				Else
					CalculatedCurrencyField.Expression = "&InternationalCurrency";
				EndIf;
			Else
				If SetFields.Find("Currency") <> Undefined Then
					CalculatedCurrencyField.Expression = "Currency";
				Else
					InReportCurrency = True;
				EndIf;
			EndIf;
			
		ElsIf DataSource.CurrencyFilling = "DeterminedByReportCurrency" Then 
			InReportCurrency = True;
		EndIf;
		
		If InReportCurrency Then
			CalculatedCurrencyField.Expression = "&Currency";
			AddParameter(DataCompositionSchema, "Currency", Parameters.ReportCurrency);
		EndIf;
		
		AddGroupField(Settings, "Currency");
		
	EndIf;
	
	// Unit of Measurement Analytics
	If DataSource.UnitOfMeasureFilling <> "DontFill" Then
		
		SetFields = DataCompositionSchema.DataSets[0].Fields;
		If SetFields.Find("UnitOfMeasure") <> Undefined Then
			Expression = "UnitOfMeasure";
		Else
			If DataSource.UnitOfMeasureFilling = "DeterminedByAnalytics" Then
				ExpressionAnalytics = CalculatedFields.Find("Dimension" + DataSource.DimensionAddressUnitOfMeasure);
				Expression = 
					"CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
					|	&CacheAnalystValues, " + ExpressionAnalytics.Expression
						+ ", """ + DataSource.FieldOfDimensionUnitOfMeasure
						+ """), ""Catalog.PackagesAndUnitsOfMeasure"")";
				AddParameter(DataCompositionSchema, "CacheAnalystValues", New Map);
			ElsIf DataSource.UnitOfMeasureFilling = "FixedValue" Then 
				Expression = "&UnitOfMeasure";
				AddParameter(DataCompositionSchema, "UnitOfMeasure", DataSource.UnitOfMeasure);
			EndIf;
		EndIf;
		
		CalculatedFieldForMeasurement = CalculatedFields.Add();
		CalculatedFieldForMeasurement.DataPath = "UnitOfMeasure";
		CalculatedFieldForMeasurement.Expression = Expression;
		CalculatedFieldForMeasurement.ValueType = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
		AddGroupField(Settings, "UnitOfMeasure");
		
	EndIf;
	
EndProcedure

// Adds expressions for calculated fields, fields used in the selection of the layout.
// 
// Parameters:
//	DataCompositionSchema - DataCompositionSchema - dynamically supplemented by data source schema
//	Settings - DataCompositionSettings - dynamically updated data layout settings.
//
Procedure AddSelectionFieldExpressions(DataCompositionSchema, Settings) Export
	
	SelectionElements_ = DataCompositionClientServer.GetSelectionElements(Settings.Filter);
	
	For Each FilterElement In SelectionElements_ Do
		If TypeOf(FilterElement.LeftValue) = Type("DataCompositionField") Then
			FinancialReportingServer.NewCalculatedField(
				DataCompositionSchema,
				String(FilterElement.LeftValue),
				String(FilterElement.LeftValue),,
				Undefined);
		EndIf;
		If TypeOf(FilterElement.RightValue) = Type("DataCompositionField") Then
			FinancialReportingServer.NewCalculatedField(
				DataCompositionSchema, 
				String(FilterElement.RightValue),
				String(FilterElement.RightValue),,
				Undefined);
		EndIf;
	EndDo;
	
EndProcedure

// Matches and fills in the field names of data sets and required actual data metrics.
// 
// Parameters:
//	SourcesOfSum - Structure - compared fact indicators and data source fields:
//		*Key - String - name of the actual data metric.
//		*Value - String - the name of the field in the data source schema.
//	DataSet - DataCompositionSchemaDataSetQuery, DataCompositionSchemaDataSetObject, DataCompositionSchemaDataSetUnion - 
//				the data set whose fields are being analyzed.
//	AlwaysCurrencyInMetricName - Boolean - True - all names will have the first word "Currency".
//
Procedure FillInSourcesOfAmountAccordingToScheme(SourcesOfSum, DataSet, AlwaysCurrencyInMetricName = False) Export
	
	SchemaSetFields = DataSet.Fields;
	
	IndicatorsNames = New Map;
	If AlwaysCurrencyInMetricName Then
		IndicatorsNames.Insert("SumCompl",       "ComplCurrency");
		IndicatorsNames.Insert("SumMan",        "CurrencyOfMan");
		IndicatorsNames.Insert("SumOfInternational", "InternationalCurrency");
	Else
		IndicatorsNames.Insert("SumCompl",       "Compl");
		IndicatorsNames.Insert("SumMan",        "Man");
		IndicatorsNames.Insert("SumOfInternational", "International_");
	EndIf;
	
	If SchemaSetFields.Find("SumCompl") <> Undefined Then 
		SourcesOfSum.Insert(IndicatorsNames.Get("SumCompl"), "SumCompl");
	EndIf;
	If SchemaSetFields.Find("SumMan") <> Undefined Then 
		SourcesOfSum.Insert(IndicatorsNames.Get("SumMan"), "SumMan");
	EndIf;
	If SchemaSetFields.Find("SumOfInternational") <> Undefined Then 
		SourcesOfSum.Insert(IndicatorsNames.Get("SumOfInternational"), "SumOfInternational");
	EndIf;
	If SchemaSetFields.Find("AmountInCurrency") <> Undefined Then 
		SourcesOfSum.Insert("Currency", "AmountInCurrency");
	EndIf;
	
EndProcedure

// Matches and fills in the field names of data sets and required actual data metrics.
// 
// Parameters:
//	SourcesOfQuantity - Structure - compared fact indicators and data source fields:
//		*Key - String - name of the actual data metric
//		*Value - String - name of the field in the data source schema
//	DataSet - DataCompositionSchemaDataSetQuery, DataCompositionSchemaDataSetObject, DataCompositionSchemaDataSetUnion -
//			the data set whose fields are being analyzed.
//
Procedure FillInSourcesOfQuantityAccordingToScheme(SourcesOfQuantity, DataSet) Export
	
	SchemaSetFields = DataSet.Fields;
	
	If SchemaSetFields.Find("Count") <> Undefined Then 
		SourcesOfQuantity.Insert("Count", "Count");
	Else
		SourcesOfQuantity.Insert("Count", "0");
	EndIf;
	
EndProcedure

// The procedure creates a budget problem.
//
// Parameters:
// 	BudgetingModel - CatalogRef.BudgetingModels - The budgeting model.
// 	BudgetingProcess - CatalogRef.BudgetingSteps - The preparation of the budget.
//
Procedure BudgetTasksGeneration(BudgetingModel = Undefined, BudgetingProcess=Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.BudgetTasksGeneration);
	
	Tasks.BudgetTask.BudgetTasksGeneration(BudgetingModel, BudgetingProcess);
	
EndProcedure

// The regular procedure of the formation of the alerts according to the budget objectives.
//
Procedure GenerateNotificationsForBudgetTasks() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.GenerateNotificationsForBudgetTasks);
	
	Tasks.BudgetTask.GenerateNotificationsForBudgetTasks();
	
EndProcedure

// Causes the formation of documents for budget tasks with priority for first-priority tasks.
//
// Parameters:
// 	Process_ - DocumentRef.BudgetingProcess - Budget preparation process (task details) 
//	TasksOfFirstStage - Array of TaskRef.BudgetTask, TaskRef.BudgetTask - An array of tasks
//				or a budget task that will be processed first,
//				the remaining tasks will be considered "hung", and will be processed in the 2nd queue.
Procedure CreatingDocumentsForBudgetTasks(Process_, TasksOfFirstStage = Undefined) Export
	
	Tasks.BudgetTask.CreatingDocumentsForBudgetTasks(Process_, TasksOfFirstStage);
	
EndProcedure

#Region InteractiveWorkWithRulesForObtainingActualDataFromCommonFormSimplifiedConfigurationOfDataLayoutScheme

// Puts the changed values of user parameters in the data layout schema when you start editing
// the schema for getting actual data in the General form of simplified configuration of the data layout Schema.
//
// Parameters:
//   DataCompositionSchema - DataCompositionSchema - The scheme for obtaining the actual data.
//   SettingsComposer   - DataCompositionSettingsComposer - A linker with settings that contain parameters that are displayed to the user.
//
Procedure PutSettingsInActualDataAcquisitionScheme(DataCompositionSchema, SettingsComposer) Export
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	DataCompositionClientServer.ClearDataLayoutSettings(DataCompositionSchema.DefaultSettings);
	DataCompositionClientServer.CopyDataLayoutSettings(DataCompositionSchema.DefaultSettings,
		SettingsComposer.Settings);
	
	ReservedParameterNames = NamesOfCommonParametersOfFactGettingRules();
	Parameters = SettingsComposer.Settings.DataParameters.Items;
	For Each LayoutParameterString In Parameters Do
		If Not LayoutParameterString.Use Then
			Continue;
		EndIf;
		ParameterName = String(LayoutParameterString.Parameter);
		If ReservedParameterNames.Find(ParameterName) = Undefined Then
			SchemeParameter = DataCompositionSchema.Parameters.Find(ParameterName);
			If Not SchemeParameter = Undefined Then
				SchemeParameter.Value = LayoutParameterString.Value;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// Allows you to check the correctness of the scheme for obtaining actual data, correct errors if necessary,
// and fill in a list of critical errors that the user will need to correct.
//
// Parameters:
//   DataCompositionSchema - DataCompositionSchema - The scheme for obtaining the actual data.
//   SchemeContainsCriticalErrors - Boolean - a flag for critical errors that must
//   				be raised so that the user cannot apply the schema until the errors are fixed.
//   ListOfCriticalErrors - ValueList of String - A list containing the texts of critical error messages.
//   ListOfOtherMessages - ValueList of String - A list containing the texts of messages about fixed errors and other comments.
//   				This list of messages is displayed to the user once.
//
Procedure CheckingCorrectnessOfSchemeForObtainingActualData(DataCompositionSchema, SchemeContainsCriticalErrors,
					ListOfCriticalErrors, ListOfOtherMessages) Export
	
	ReservedParameterNames = NamesOfCommonParametersOfFactGettingRules();
	For Each ParameterElement In DataCompositionSchema.Parameters Do
		If Not ReservedParameterNames.Find(ParameterElement.Name) = Undefined Then
			If ParameterElement.IncludeInAvailableFields
			 Or Not ParameterElement.UseRestriction Then
				ParameterElement.IncludeInAvailableFields = False;
				ParameterElement.UseRestriction = True;
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Tham số ""%1"" được bảo lưu, người dùng không được phép chỉnh sửa. Tham số của lược đồ thành phần sẽ được sửa chữa.';
						|ru = 'Параметр ""%1"" является зарезервированным, его редактирование пользователем не допускается. Параметр схемы компоновки будет исправлен.';
						|en = 'The parameter ""%1"" is reserved, its editing by the user is not allowed. The parameter of composition schema will be corrected.'; fa = 'The parameter ""%1"" is reserved, its editing by the user is not allowed. The parameter of composition schema will be corrected.';
						|it = 'Il parametro ""%1"" è riservato, la sua modifica da parte dell''utente non è ammessa. Parametro dello schema di composizione sarà corretto.';
						|pl = 'Parametr ""%1"" jest zarezerwowany, go edytowanie przez użytkownika nie jest dozwolone. Parametr schematu układu zostanie skorygowany.';
						|tr = '""%1"" parametresi rezerve edilmiş, onun kullanıcıları düzenlemesine izni verilmiyor. Oluşturma şeması parametreleri düzeltilecek.'"),
					ParameterElement.Name);
				
				ListOfOtherMessages.Add(ErrorText);
			EndIf;
		Else
			ParameterElement.Use = DataCompositionParameterUse.Always;
		EndIf;
	EndDo;
	
EndProcedure

// Puts the changed parameter values in the layout diagram in the settings of the settings Builder.
// The need hipping behavior due to the possibility of specifying the default settings
// (then the standard initialization parameters are taken from default settings and need
// below was taken from the layout).
//
// Parameters:
//   DataCompositionSchema - DataCompositionSchema - The scheme for obtaining the actual data.
//   SettingsComposer - DataCompositionSettingsComposer - A linker with settings that contain parameters that are displayed to the user.
//
Procedure RefillingSettingsWhenChangingLayoutScheme(DataCompositionSchema, SettingsComposer) Export
	
	// If the default settings are filled in, then the parameter values are substituted from the default settings, and not the layout scheme.
	ReservedParameterNames = NamesOfCommonParametersOfFactGettingRules();
	Parameters = SettingsComposer.Settings.DataParameters.Items;
	For Each LayoutParameterString In Parameters Do
		ParameterName = String(LayoutParameterString.Parameter);
		If ReservedParameterNames.Find(ParameterName) = Undefined Then
			SchemeParameter = DataCompositionSchema.Parameters.Find(ParameterName);
			If Not SchemeParameter = Undefined Then
				LayoutParameterString.Value = SchemeParameter.Value;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Returns an array of parameter names whose value will not be copied to the General data layout scheme
// from the schema of an arbitrary rule for getting actual data, because they are reserved parameter names.
// Parameters that are not included in the list will be renamed to the format " P "+ ID of an arbitrary PPFD in the General scheme for getting a fact + " _ " + parameter Name,
// since one General scheme for getting a fact can contain any number of PPFDS with parameters that have the same name, but different values.
//
// Returns:
// 	Array of String - Array of names of layout data parameters.
//
Function NamesOfCommonParametersOfFactGettingRules()
	
	ParametersNotCopied = New Array;
	ParametersNotCopied.Add("BeginOfPeriod");
	ParametersNotCopied.Add("EndOfPeriod");
	ParametersNotCopied.Add("Period");
	ParametersNotCopied.Add("PeriodLimit");
	ParametersNotCopied.Add("ActualDataLimit");
	ParametersNotCopied.Add("Periodicity");
	ParametersNotCopied.Add("InternationalCurrency");
	ParametersNotCopied.Add("Currency");
	ParametersNotCopied.Add("ReportCurrency");
	ParametersNotCopied.Add("StorageCurrency");
	ParametersNotCopied.Add("InternationalAccountingIsUsed");
	ParametersNotCopied.Add("SourceCatalogName");
	ParametersNotCopied.Add("PrivilegedMode");
	ParametersNotCopied.Add("SourcePrivilegedMode");
	ParametersNotCopied.Add("DataSourceID");
	ParametersNotCopied.Add("RuleTypeActualData");
	ParametersNotCopied.Add("RuleTypeBudgetExecution");
	ParametersNotCopied.Add("ID_" + "ExpressionStartOfPeriod");
	ParametersNotCopied.Add("ID_" + "ExpressionEndOfPeriod");
	ParametersNotCopied.Add("ID_" + "ExpressionPeriod");
	ParametersNotCopied.Add("DataSource");
	ParametersNotCopied.Add("CorDataSource");
	ParametersNotCopied.Add("PrivilegedMode");
	ParametersNotCopied.Add("SourcePrivilegedMode");
	ParametersNotCopied.Add("CacheAnalystValues");
	ParametersNotCopied.Add("TurnoverByExpenseDimension");
	ParametersNotCopied.Add("GettingBalancesForPeriodBoundary");
	
	Return ParametersNotCopied;
	
EndFunction

// Fills in some details in the budget item or budget indicator.
// 
// Parameters:
// 	ArticleOrIndicator - CatalogObject.BudgetFlowItems, CatalogObject.BudgetBalanceItems - Item or indicator of budgets.
//
Procedure FillInAuxiliaryDetailsBeforeRecording(ArticleOrIndicator) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	DimensionKinds = New Structure;
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		DimensionKinds.Insert("DimensionKind" + Cnt);
	EndDo;
	FillPropertyValues(DimensionKinds, ArticleOrIndicator);
	
	AnalystTable = New ValueTable;
	AnalystTable.Columns.Add("NameOfAnalytics");
	AnalystTable.Columns.Add("DimensionValue");
	For Each KeyAndValue In DimensionKinds Do
		If Not ValueIsFilled(KeyAndValue.Value) Then
			Continue;
		EndIf;
		If AnalystTable.Find(KeyAndValue.Value, "DimensionValue") = Undefined Then
			NewRow = AnalystTable.Add();
			NewRow.NameOfAnalytics = KeyAndValue.Key;
			NewRow.DimensionValue = KeyAndValue.Value;
		EndIf;
	EndDo;
	AnalystTable.Sort("NameOfAnalytics");
	
	For Cnt = 0 To AnalystTable.Count() - 1 Do
		ArticleOrIndicator["DimensionKind" + (Cnt + 1)] = AnalystTable[Cnt].DimensionValue;
	EndDo;
	
	For RemainingAnalysts = AnalystTable.Count() + 1 To MaximumNumberOfAnalysts Do
		ArticleOrIndicator["DimensionKind" + RemainingAnalysts] = Undefined;
	EndDo;
	
	ArticleOrIndicator.NumberOfUsedDimensions = AnalystTable.Count();
	
	DimensionAddressCurrency = 0;
	If ArticleOrIndicator.CurrencyIsDeterminedByDimension Then
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			If ArticleOrIndicator.DimensionCurrencies = ArticleOrIndicator["DimensionKind" + DimensionNumber] Then
				DimensionAddressCurrency = DimensionNumber;
				Break;
			EndIf;
		EndDo;
	EndIf;
	ArticleOrIndicator.DimensionAddressCurrency = DimensionAddressCurrency;
	
	QuantityDimensionAddress = 0;
	If ArticleOrIndicator.UnitOfMeasureIsDeterminedByDimension Then
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			If ArticleOrIndicator.DimensionUnitsOfMeasurement = ArticleOrIndicator["DimensionKind" + DimensionNumber] Then
				QuantityDimensionAddress = DimensionNumber;
				Break;
			EndIf;
		EndDo;
	EndIf;
	ArticleOrIndicator.QuantityDimensionAddress = QuantityDimensionAddress;
	
EndProcedure

// Checks the availability of currency analytics and analytics of the unit of measurement of the budget item, budget indicator, or non-financial indicator in the list of analysts.
//
// Parameters:
//  ArticleOrIndicator - A reference object.Article budgets, Reference object.Indicators of budgets, a reference object.Non-financial indicators of budgets
//    - An item or indicator of budgets.
//  Cancel - Boolean - The error flag when testing.
Procedure CheckCompletionOfAnalyticsCurrencyUnitsOfMeasurement(ArticleOrIndicator, Cancel) Export

	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	If TypeOf(ArticleOrIndicator) = Type("CatalogObject.BudgetFlowItems") Then
		MessageTemplate = NStr("vi = '%1 chưa chỉ ra làm đối tượng phân tích của khoản mục';
								|ru = '%1 не указана в качестве аналитики статьи';
								|en = '%1 is not specified as an item dimension'; fa = '%1 is not specified as an item dimension';
								|it = '%1 non indicata come analitica della voce';
								|pl = '%1 nie określono jako analityki pozycji';
								|tr = '%1 madde boyutu olarak belirtilmemiş'");
	Else
		MessageTemplate = NStr("vi = '%1 chưa chỉ ra làm đối tượng phân tích của chỉ tiêu';
								|ru = '%1 не указана в качестве аналитики показателя';
								|en = '%1 is not specified as an indicator dimension'; fa = '%1 is not specified as an indicator dimension';
								|it = '%1 non indicata come analitica dell''indicatore';
								|pl = '%1 nie określono jako analityki wskaźnika';
								|tr = '%1 gösterge boyutu olarak belirtilmemiş'");
	EndIf;
	
	If TypeOf(ArticleOrIndicator) = Type("CatalogObject.NonFinancialItemsOfBudgets") Then
		RecordByCurrency = (ArticleOrIndicator.IndicatorKind = Enums.NonFinancialItemKinds.Cash_);
		RecordByQuantity = (ArticleOrIndicator.IndicatorKind = Enums.NonFinancialItemKinds.Quantitative);
	Else
		RecordByCurrency = ArticleOrIndicator.RecordByCurrency;
		RecordByQuantity = ArticleOrIndicator.RecordByQuantity;
	EndIf;
	
	If RecordByCurrency
		And ArticleOrIndicator.CurrencyIsDeterminedByDimension
		And ValueIsFilled(ArticleOrIndicator.DimensionCurrencies) Then
		ThereIsCurrencyAnalysis = False;
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			If ArticleOrIndicator.DimensionCurrencies = ArticleOrIndicator["DimensionKind" + DimensionNumber] Then
				ThereIsCurrencyAnalysis = True;
				Break;
			EndIf;
		EndDo;
		If Not ThereIsCurrencyAnalysis Then
			AnalyticsPresentation = NStr("vi = 'Chỉ số tiền tệ';
										|ru = 'Аналитика валюты';
										|en = 'Currency dimension'; fa = 'بُعد ارز';
										|it = 'Analitica di valuta';
										|pl = 'Analityka waluty';
										|tr = 'Para birimleri boyutu'");
			Message = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, AnalyticsPresentation);
			Common.MessageToUser(Message, , , , Cancel);
		EndIf;
	EndIf;
	
	If RecordByQuantity
		And ArticleOrIndicator.UnitOfMeasureIsDeterminedByDimension
		And ValueIsFilled(ArticleOrIndicator.DimensionUnitsOfMeasurement) Then
		ThereAreAnalyticsUnitsOfMeasurement = False;
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			If ArticleOrIndicator.DimensionUnitsOfMeasurement = ArticleOrIndicator["DimensionKind" + DimensionNumber] Then
				ThereAreAnalyticsUnitsOfMeasurement = True;
				Break;
			EndIf;
		EndDo;
		If Not ThereAreAnalyticsUnitsOfMeasurement Then
			AnalyticsPresentation = NStr("vi = 'Chỉ số đơn vị tính';
										|ru = 'Аналитика единицы измерения';
										|en = 'Unit of measure dimension'; fa = 'بُعد واحد اندازه‌گیری';
										|it = 'Analitica dell''unità di misura';
										|pl = 'Analityka jednostki miary';
										|tr = 'Ölçü birimleri boyutu'");
			Message = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, AnalyticsPresentation);
			Common.MessageToUser(Message, , , , Cancel);
		EndIf;
	EndIf;

EndProcedure

// Checks
// the presence of Item or type of nomenclature analytics if there is an analysis of the characteristics of the nomenclature, which should be paired with the owner analytics.
//
// Parameters:
//  ArticleOrIndicator - CatalogObject.BudgetFlowItems, CatalogObject.BudgetBalanceItems, CatalogObject.NonFinancialItemsOfBudgets - Item or indicator of budgets.
//  Cancel - Boolean - The error flag when testing.
Procedure CheckAnalyticsCompletionByItem(ArticleOrIndicator, Cancel) Export

	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	If TypeOf(ArticleOrIndicator) = Type("CatalogObject.BudgetFlowItems") Then
		MessageTemplate = NStr("vi = 'Đối tượng %1 hoặc %2 cần được chỉ ra làm đối tượng phân tích của dạng';
								|ru = 'Аналитика %1 или %2 должна быть указана в качестве аналитики статьи';
								|en = 'The %1 or %2 dimension must be specified as the item dimension'; fa = 'The %1 or %2 dimension must be specified as the item dimension';
								|it = 'Аналитика %1 или %2 должна быть указана в качестве аналитики статьи';
								|pl = 'The %1 or %2 dimension must be specified as the item dimension';
								|tr = '%1 veya %2 boyutu kalemin boyutu olarak belirtilmelidir'");
	Else
		MessageTemplate = NStr("vi = 'Đối tượng %1 hoặc %2 cần được chỉ ra làm đối tượng phân tích của chỉ tiêu';
								|ru = 'Аналитика %1 или %2 должна быть указана в качестве аналитики показателя';
								|en = 'The %1 or %2 dimension must be specified as the indicator dimension'; fa = 'The %1 or %2 dimension must be specified as the indicator dimension';
								|it = 'Аналитика %1 или %2 должна быть указана в качестве аналитики показателя';
								|pl = 'The %1 or %2 dimension must be specified as the indicator dimension';
								|tr = '%1 veya %2 boyutu göstergenin boyutu olarak belirtilmelidir'");
	EndIf;
	
	ThereIsAnalyticsOnNomenclature = False;
	ThereIsAnalyticsOnCharacteristicsOfNomenclature = False;
	DimensionProducts = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.BudgetingItems;
	DimensionItemKinds = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.ItemKinds;
	DimensionItemsCharacteristics = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.ItemsCharacteristics;
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		If ArticleOrIndicator["DimensionKind" + DimensionNumber] = DimensionProducts
			Or ArticleOrIndicator["DimensionKind" + DimensionNumber] = DimensionItemKinds Then
			ThereIsAnalyticsOnNomenclature = True;
		ElsIf ArticleOrIndicator["DimensionKind" + DimensionNumber] = DimensionItemsCharacteristics Then
			ThereIsAnalyticsOnCharacteristicsOfNomenclature = True;
		EndIf;
	EndDo;
	
	If ThereIsAnalyticsOnCharacteristicsOfNomenclature
		And Not ThereIsAnalyticsOnNomenclature Then
		Message = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, DimensionProducts, DimensionItemKinds);
		Common.MessageToUser(Message, , , , Cancel);
	EndIf;
	
EndProcedure

#Region AnalyticalReports

// Parameters:
// 	DataCompositionSchema - DataCompositionSchema - scheme of the layout.
// 	SourceAnalytics - String - The field name of the source dimension.
Procedure AddDCSAnalyticsByType(DataCompositionSchema, SourceAnalytics) Export
	
	DimensionKinds = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.TypesOfAnalytics();
	For Each DimensionKind In DimensionKinds Do
		
		NameOfAnalyticsField = FinancialReportingCached.NameOfBudgetReportField(DimensionKind.Ref);
		NameOfAnalyticsViewParameter_ = "DimensionKind" + NameOfAnalyticsField;
		
		ExpressionParameters = TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
		ExpressionParameters.ExpressionNumberOfAnalyticsUsed = SourceAnalytics + ".NumberOfUsedDimensions";
		ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = SourceAnalytics + ".DimensionKind";
		ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Dimension";
		ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
		
		ExpressionAnalytics = TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
		
		FinancialReportingServer.NewCalculatedField(
			DataCompositionSchema,
			NameOfAnalyticsField,
			ExpressionAnalytics,
			DimensionKind.Presentation,
			True,
			BudgetingServer.AllTypesOfAnalytics());
		
		SchemeParameter = DataCompositionSchema.Parameters.Find(NameOfAnalyticsViewParameter_);
		If SchemeParameter = Undefined Then
			SchemeParameter = DataCompositionSchema.Parameters.Add();
			SchemeParameter.Name = NameOfAnalyticsViewParameter_;
		EndIf;
		SchemeParameter.Value = DimensionKind.Ref;
		SchemeParameter.UseRestriction = True;
		SchemeParameter.ValueType = New TypeDescription("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions");
		
	EndDo;
	
EndProcedure

// Complements the layout fields from "Analytic1" to "Analytic6" with expressions for getting the Analytics view.
//
// Parameters:
// 	DataCompositionSchema - DataCompositionSchema - The circuit layout in which you want to set the expression of the submission
// 	PathToLayoutFields - String - Path to layout fields, for example, " data Set.Valuesfinancial indicators.Fields"
// 	SourceAnalytics - String - Name of the layout field that contains the settings for the analysis types, i.e. "Viewanalytics1", "Viewanalytics2".
//
Procedure AddAnalyticsPresentationExpressionsToDCS(DataCompositionSchema, PathToLayoutFields, SourceAnalytics) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	LayoutFields = DataCompositionSchema;
	Array = StringFunctionsClientServer.SplitStringIntoSubstringsArray(PathToLayoutFields, ".");
	For Each Attribute In Array Do
		LayoutFields = LayoutFields[Attribute];
	EndDo;
	
	AnalyticsNameTemplate = "Dimension%DimensionNumber%";
	AnalyticsViewTemplate  = "DimensionKind%DimensionNumber%";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		
		NameOfAnalyticsField = StrReplace(AnalyticsNameTemplate, "%DimensionNumber%", DimensionNumber);
		
		LayoutField = LayoutFields.Find(NameOfAnalyticsField);
		If TypeOf(LayoutField) = Type("DataCompositionSchemaDataSetField")
			And TrimAll(LayoutField.PresentationExpression) = "&PresentationTextOfDimensionValue" Then
			
			Expression = 
			"CASE
			|	WHEN NOT ValueIsFilled(%NameOfAnalyticsField%) AND ValueIsFilled(%AnalyticsViewField%)
			|		THEN BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
			|				%AnalyticsViewField%, ""OtherItems"", PRESENTATION(%AnalyticsViewField%))
			|	ELSE %NameOfAnalyticsField%
			|END";
			
			NameOfAnalyticsType  = StrReplace(AnalyticsViewTemplate, "%DimensionNumber%", DimensionNumber);
			AnalyticsViewField = SourceAnalytics + "." + NameOfAnalyticsType;
			
			Expression = StrReplace(Expression, "%NameOfAnalyticsField%",  NameOfAnalyticsField);
			Expression = StrReplace(Expression, "%AnalyticsViewField%", AnalyticsViewField);
			
			LayoutField.PresentationExpression = Expression;
		EndIf;
		
	EndDo;
	
EndProcedure

// Clears the value of the parameter Getactualsize in customizing linker settings form.
// 
// Parameters:
// 	ThisForm - ClientApplicationForm - A form containing the settings Builder.
// 	UserSettings - DataCompositionUserSettings - custom setting.
Procedure BeforeLoadUserSettingsAtServer(ThisForm, UserSettings) Export
	
	SettingsComposer = ThisForm.Report.SettingsComposer;
	Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "DateWhenTheDataIsUpToDate");
	If Parameter <> Undefined Then
		UserSettingID = Parameter.UserSettingID;
		UserSettingItem = UserSettings.Items.Find(UserSettingID);
		If UserSettingItem <> Undefined Then
			UserSettingItem.Value = Date('00010101');
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ConfiguringDataAcquisitionRules

Function ExpressionsForFillingInAnalyticsByRule(Rule, DimensionKinds, DataCompositionSchema)
	
	FillingExpressions = New ValueTable;
	FillingExpressions.Columns.Add("DimensionNumber", New TypeDescription("Number"));
	FillingExpressions.Columns.Add("DimensionKind", New TypeDescription("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions"));
	FillingExpressions.Columns.Add("ValueType", New TypeDescription("TypeDescription"));
	FillingExpressions.Columns.Add("Expression", New TypeDescription("String"));
	
	DescriptionOfAnalyticsTypes = 
		Common.ObjectsAttributeValue(DimensionKinds.UnloadColumn("DimensionKind"), "ValueType");
	
	AnalystExpressionsFromRule = New Array;
	For Each AnalyticsViewLine In DimensionKinds Do
		DimensionNumber = AnalyticsViewLine.DimensionNumber;
		If Not ValueIsFilled(Rule["DimensionKind" + DimensionNumber]) Then
			Continue;
		EndIf;
		If Not Rule["FillInAnalyticsWithSpecifiedValue" + DimensionNumber] Then
			Expression = Rule["DimensionPopulationExpression" + DimensionNumber];
			If AnalystExpressionsFromRule.Find(Expression) = Undefined Then
				AnalystExpressionsFromRule.Add(Expression);
			EndIf;
		EndIf;
	EndDo;
	If AnalystExpressionsFromRule.Count() > 0 Then
		DataForObtainingExpressions = ProcessingOfFormulas.DataForObtainingFormulaExpressionsViaDCS(DataCompositionSchema,
			AnalystExpressionsFromRule, False, True);
		ReplacingAnalystExpressions = DataForObtainingExpressions.ConvertedExpressions;
	Else
		ReplacingAnalystExpressions = New Map;
	EndIf;
	
	For Each AnalyticsViewLine In DimensionKinds Do
		
		NewRow = FillingExpressions.Add();
		FillPropertyValues(NewRow, AnalyticsViewLine);
		NewRow.ValueType = DescriptionOfAnalyticsTypes[AnalyticsViewLine.DimensionKind];
		
		DimensionNumber = AnalyticsViewLine.DimensionNumber;
		
		If Rule["FillInAnalyticsWithSpecifiedValue" + DimensionNumber] Then
			ParameterName = "DimensionValue" + DimensionNumber;
			AddParameter(DataCompositionSchema, ParameterName, Rule[ParameterName]);
			Expression = "&" + ParameterName;
		Else
			Expression = Rule["DimensionPopulationExpression" + DimensionNumber];
			
			ConvertedExpression = ReplacingAnalystExpressions.Get(Expression);
			If Not ConvertedExpression = Undefined Then
				Expression = ConvertedExpression;
			EndIf;
			
			If ThisIsAnalyticsDimension(NewRow.ValueType, AnalyticsViewLine.DimensionKind) Then
				Expression = ExpressingAnalyticsValueBySourceAndType(Expression, AnalyticsViewLine.DimensionKind);
			EndIf;
		EndIf;
		
		NewRow.Expression = Expression;
		
	EndDo;
	
	Return FillingExpressions; 
	
EndFunction

// Returns a table of expressions for filling in Analytics.
//
// Parameters:
//  DataCompositionSchema - DataCompositionSchema - The scheme for obtaining the actual data.
//  DimensionKinds - ValueTable - Analyst Table:
//   *DimensionNumber - Number - Serial number of analytics.
//   *DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//  CheckTypeOfValueInExpression - Boolean - Flag for checking the type of analysis in the expression itself. The default value is False.
//  			Must be set to True when getting data to convert
//  			values of the wrong type to an empty value.
//  			It must be set to False when automatically selecting the appropriate SCD fields.
// Returns:
//  ValueTable - Table of Analyst expressions:
//   *DimensionNumber - Number - Serial number of analytics.
//   *DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//   *ValueType - TypeDescription - Type of the Analytics value.
//   *Expression - String - The analytics fill-in line. Depending on the value of the Check flag, the value in the expression
//   			may contain a check for the data type.
//   *Ambiguous_ - Boolean - True if the selected analytics expression is ambiguous and the
//   			data acquisition rules require manual selection of the analytics field.
//
Function ExpressionsForFillingInAnalyticsAccordingToDataLayoutScheme(DataCompositionSchema, DimensionKinds, CheckTypeOfValueInExpression = False) Export
	
	FillingExpressions = New ValueTable;
	FillingExpressions.Columns.Add("DimensionNumber", New TypeDescription("Number"));
	FillingExpressions.Columns.Add("DimensionKind", New TypeDescription("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions"));
	FillingExpressions.Columns.Add("ValueType", New TypeDescription("TypeDescription"));
	FillingExpressions.Columns.Add("Expression", New TypeDescription("String"));
	FillingExpressions.Columns.Add("Ambiguous_", New TypeDescription("Boolean"));
	
	SourcesOfAnalyticsContent = New Map;
	TypesOfAnalyticsFillSources = New Map;
	
	NameOfSourceFieldFolderCor = "CorGroupDataSource";
	ThereAreCorSourceFields = False;
	
	If DataCompositionSchema <> Undefined
		And DataCompositionSchema.DataSets.Count() <> 0 Then
		SetFields = DataCompositionSchema.DataSets[0].Fields;
		For Each SetField In SetFields Do
			If TypeOf(SetField) = Type("DataCompositionSchemaDataSetFieldFolder") Then
				If SetField.DataPath = NameOfSourceFieldFolderCor Then
					ThereAreCorSourceFields = True;
				EndIf;
				Continue;
			ElsIf TypeOf(SetField) = Type("DataCompositionSchemaNestedDataSet") Then
				Continue;
			EndIf;
			If ValueIsFilled(SetField.ValueType) Then
				SourcesOfAnalyticsContent.Insert(SetField.DataPath, SetField.ValueType);
				ValueToSave_ = TypesOfAnalyticsFillSources.Get(SetField.ValueType);
				If ValueToSave_ = Undefined Then
					ValueToSave_ = New Array;
				EndIf;
				ValueToSave_.Add(SetField.DataPath);
				TypesOfAnalyticsFillSources.Insert(SetField.ValueType, ValueToSave_);
			EndIf;
		EndDo;
	EndIf;
	
	DescriptionOfAnalyticsTypes = 
		Common.ObjectsAttributeValue(DimensionKinds.UnloadColumn("DimensionKind"), "ValueType");
		
	ThereIsAnalyticsNumber = (DimensionKinds.Columns.Find("DimensionNumber") <> Undefined);
	
	For Each AnalyticsViewLine In DimensionKinds Do
		DimensionKind = AnalyticsViewLine.DimensionKind;
		DescriptionOfAnalyticsTypes_ = DescriptionOfAnalyticsTypes[DimensionKind];
		
		StringFillingExpression = FillingExpressions.Add();
		FillPropertyValues(StringFillingExpression, AnalyticsViewLine);
		StringFillingExpression.ValueType = DescriptionOfAnalyticsTypes_;
		
		If Not ValueIsFilled(DimensionKind) Then
			Continue;
		EndIf;
		
		AnalyticsFieldByNumber = "Dimension" + ?(ThereIsAnalyticsNumber, AnalyticsViewLine.DimensionNumber, "");
		
		UniquelySuitableFields = New Array; // A field whose type description matches the description of the types of analytics
		ConditionallyAppropriateFields = New Array; // Fields whose type descriptions contain types of analytics
		
		If SourcesOfAnalyticsContent[AnalyticsFieldByNumber] <> Undefined Then
			UniquelySuitableFields.Add(AnalyticsFieldByNumber);
		Else
			// Let's try to select the field filling in analytics "by type"
			SourceOfAnalyticsFilling = TypesOfAnalyticsFillSources.Get(DescriptionOfAnalyticsTypes_);
			If Not SourceOfAnalyticsFilling = Undefined Then
				UniquelySuitableFields = SourceOfAnalyticsFilling;
				If ThereAreCorSourceFields Then
					SuitableFieldsOfCorSource = New Array();
					NumberOfSuitableFields = UniquelySuitableFields.Count();
					For NumberOfAppropriateField = 1 To NumberOfSuitableFields Do
						IndexOfAppropriateField = NumberOfSuitableFields - NumberOfAppropriateField;
						If StrStartsWith(UniquelySuitableFields[IndexOfAppropriateField], NameOfSourceFieldFolderCor) Then
							SuitableFieldsOfCorSource.Add(UniquelySuitableFields[IndexOfAppropriateField]);
							UniquelySuitableFields.Delete(IndexOfAppropriateField);
						EndIf;
					EndDo;
					If UniquelySuitableFields.Count() = 0 Then
						UniquelySuitableFields = SuitableFieldsOfCorSource;
					EndIf;
				EndIf;
			Else
				For Each SourceOfAnalyticsFilling In SourcesOfAnalyticsContent Do
					For Each Type In SourceOfAnalyticsFilling.Value.Types() Do
						If DescriptionOfAnalyticsTypes_.ContainsType(Type) Then
							AddFieldToEnd = Not ThereAreCorSourceFields Or ThereAreCorSourceFields And StrStartsWith(SourceOfAnalyticsFilling.Key, NameOfSourceFieldFolderCor);
							If AddFieldToEnd Then
								ConditionallyAppropriateFields.Add(SourceOfAnalyticsFilling.Key);
							Else
								ConditionallyAppropriateFields.Insert(0, SourceOfAnalyticsFilling.Key);
							EndIf;
						EndIf;
					EndDo;
				EndDo;
			EndIf;
		EndIf;
		
		If UniquelySuitableFields.Count() <> 0 Then
			If CheckTypeOfValueInExpression Then
				StringFillingExpression.Expression = ExpressingAnalyticsValueBySourceAndType(UniquelySuitableFields[0],
					DimensionKind);
			Else
				StringFillingExpression.Expression = UniquelySuitableFields[0];
			EndIf;
			StringFillingExpression.Ambiguous_ = UniquelySuitableFields.Count() > 1;
		ElsIf ConditionallyAppropriateFields.Count() <> 0 Then
			If CheckTypeOfValueInExpression Then
				StringFillingExpression.Expression = ExpressingAnalyticsValueBySourceAndType(ConditionallyAppropriateFields[0],
					DimensionKind);
			Else
				StringFillingExpression.Expression = ConditionallyAppropriateFields[0];
			EndIf;
			StringFillingExpression.Ambiguous_ = ConditionallyAppropriateFields.Count() > 1;
		EndIf;
	EndDo;
	
	Return FillingExpressions; 
	
EndFunction

// Parameters:
// 	ConditionalAppearance - DataCompositionConditionalAppearance - 
// 	TableName - String - LongDesc
Procedure AddAnalyticsDisplaySettingsToConditionalAppearance(ConditionalAppearance, TableName) Export
	
	TypesOfAnalytics = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.TypesOfAnalytics();
	
	For Each DimensionKind In TypesOfAnalytics Do
		
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue = New DataCompositionField(TableName + ".DimensionKind");
		DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		DataFilterItem.RightValue = DimensionKind.Ref;
		DataFilterItem.Use = True;
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue = New DataCompositionField(TableName + ".DimensionValue");
		DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
		DataFilterItem.Use = True;
		
		Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Text");
		Appearance.Use = True;
		Appearance.Value = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
			DimensionKind, "OtherItems", DimensionKind.Presentation);
		
		FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
		FormattedField.Use = True;
		FormattedField.Field = New DataCompositionField(StrReplace(TableName, "Object.", "") + "DimensionValue");
		
	EndDo;
	
EndProcedure

// Initializes the configuration linker for the actual data acquisition rule.
// 
// Parameters:
// 	Rule - CatalogObject.ActualDataQueryRulesByBudgetBalanceItems - The rule of obtaining a fact.
// 			- CatalogObject.ActualDataQueryRulesByBudgetFlowItems - The rule of obtaining a fact.
// 	ParametersForFillingInAnalytics - ClientApplicationForm - The Form containing the parameter:
// 	  * AddressOfDataCompositionSchema - String - address of the temporary storage that contains the layout scheme for getting actual data.
// 	CompositionSetup - DataCompositionSettings - customize the layout.
// 						- DataCompositionSettingsComposer - 
//
Procedure InitializeRuleSettingsComposer(Rule, ParametersForFillingInAnalytics, CompositionSetup) Export
	
	If TypeOf(Rule.Ref) <> Type("CatalogRef.BudgetingLimits") Then
	
		If Not ValueIsFilled(Rule.DataSourceSection) Or Not ValueIsFilled(Rule.DataSource) Then
			ParametersForFillingInAnalytics.SettingsComposer.Initialize(Undefined);
			Return;
		EndIf;
		
		// Let's clarify the linker settings, otherwise, after the formation of the "old" budget, the modified scheme is returned from the cache.
		If Not ValueIsFilled(ParametersForFillingInAnalytics.AddressOfDataCompositionSchema) Then
			CorrespondencesTable = Undefined;
			If Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
				And DataSourcesServer.ThisIsSettingUpBusinessOfOperation(Rule.DataSource)
				And GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters") Then
				CorrespondencesTable = DataSourcesServer.TableOfCorrespondenceRegisters(Rule.DataSource);
			EndIf;
			DataCompositionSchema = DataSourcesServer.DataLayoutRules(Rule, New Structure("CalculatedFields"),, True, CorrespondencesTable);
			SetFieldPropertiesForRuleSettings(DataCompositionSchema, Rule);
			
			ParametersForFillingInAnalytics.AddressOfDataCompositionSchema = 
				PutToTempStorage(DataCompositionSchema, ParametersForFillingInAnalytics.UUID);
		EndIf;
		
	Else
		
		If Not ValueIsFilled(ParametersForFillingInAnalytics.AddressOfDataCompositionSchema) Then
			ParametersForFillingInAnalytics.SettingsComposer.Initialize(Undefined);
			Return;
		EndIf;
		
	EndIf;
	
	Try
		SettingsSource = New DataCompositionAvailableSettingsSource(ParametersForFillingInAnalytics.AddressOfDataCompositionSchema);
		ParametersForFillingInAnalytics.SettingsComposer.Initialize(SettingsSource);
	Except
		LREvent = NStr("vi = 'Đang khởi tạo trình liên kết cài đặt quy tắc';
						|ru = 'Выполнение инициализации компоновщика настроек правила';
						|en = 'Initializing rule setting composer'; fa = 'Initializing rule setting composer';
						|it = 'Esecuzione dell''inizializzazione del compositore delle impostazioni della regola';
						|pl = 'Wykonanie inicjowania kreatora ustawień reguły';
						|tr = 'Kural ayar oluşturucusunun başlatma işlemi gerçekleştirilmesi'",
			Common.DefaultLanguageCode());
		WriteLogEvent(
			LREvent,
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If CompositionSetup = Undefined Then
		DataCompositionSchema = GetFromTempStorage(ParametersForFillingInAnalytics.AddressOfDataCompositionSchema);
		ParametersForFillingInAnalytics.SettingsComposer = DefaultInitializedComposer(DataCompositionSchema);
	Else
		ParametersForFillingInAnalytics.SettingsComposer.LoadSettings(CompositionSetup);
		ParametersForFillingInAnalytics.SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	EndIf;
	
EndProcedure

// Fills in the settings of the settings Builder with the properties of filling in the Analytics from the rule.
// 
// Parameters:
// 	ParametersForFillingInAnalytics - ClientApplicationForm - Form with Attributes:
// 	 *SettingsComposer - DataCompositionSettingsComposer -
// 	 *AddressOfDataCompositionSchema - String - address of the temporary storage that contains the schema for getting the fact.
// 	Rule - CatalogObject.ActualDataQueryRulesByBudgetBalanceItems - The rule of obtaining a fact.
// 			- CatalogObject.ActualDataQueryRulesByBudgetFlowItems -
// 			- CatalogObject.NonFinancialItemsOfBudgets -
// 	DimensionKinds - See BudgetingServer.DimensionKinds
//
Procedure FillInSettingsForFillingInAnalyticsByRule(ParametersForFillingInAnalytics, Rule, DimensionKinds) Export
	
	ParametersForFillingInAnalytics.DimensionPopulationSettings.Clear();
	
	ArrayOfAnalyticsTypes = New Array;
	For Each DimensionKind In DimensionKinds Do
		ArrayOfAnalyticsTypes.Add(DimensionKind.Value);
	EndDo;
	
	AdditionalProperties = Common.ObjectsAttributeValue(ArrayOfAnalyticsTypes, "AdditionalProperty");
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		
		DimensionKind = DimensionKinds["DimensionKind" + DimensionNumber];
		If Not ValueIsFilled(DimensionKind) Then
			Continue;
		EndIf;
		
		SettingString = ParametersForFillingInAnalytics.DimensionPopulationSettings.Add();
		SettingString.DimensionNumber = DimensionNumber;
		SettingString.DimensionKind = DimensionKind;
		SettingString.AdditionalProperty = AdditionalProperties[DimensionKind];
		SettingString.FillInTheSpecifiedValue = Rule["FillInAnalyticsWithSpecifiedValue" + DimensionNumber];
		SettingString.DimensionValue = Rule["DimensionValue" + DimensionNumber];
		SettingString.DimensionPopulationExpression = Rule["DimensionPopulationExpression" + DimensionNumber];
		
	EndDo;
	
EndProcedure

// Checks the settings for filling in Analytics.
// 
// Parameters:
// 	DimensionPopulationSettings - FormTable - The tabular part of the form that contains the settings for filling in Analytics.
// 	Cancel - Boolean - The error flag when testing.
// 	SettingUpAnalyticsContent - Boolean - flag for advanced settings for filling in Analytics.
//
Procedure ProcessingVerificationOfAnalyticsFillingSettings(DimensionPopulationSettings, Cancel, SettingUpAnalyticsContent = False) Export
	
	If Not SettingUpAnalyticsContent Then
		Return;
	EndIf;
	
	MessageTemplate = NStr("vi = 'Tùy chỉnh điền chỉ số ""%1""';
							|ru = 'Настройте заполнение аналитики ""%1""';
							|en = 'Set up population of the ""%1"" dimension'; fa = 'Set up population of the ""%1"" dimension';
							|it = 'Impostate la compilazione dell''analitica ""%1""';
							|pl = 'Ustaw wypełnienie analityki ""%1""';
							|tr = '""%1"" boyut doldurma işlemini ayarlayın'");
	FieldPattern = "DimensionPopulationSettings[%1].PresentationOfDimensionPopulationExpression";
	
	For Each SettingString In DimensionPopulationSettings Do
		
		If SettingString.FillInTheSpecifiedValue Then
			Continue;
		EndIf;
		
		If Not SettingString.MissingInAvailableFields And SettingString.DimensionPopulationExpression <> "" Then
			Continue;
		EndIf;
			
		Message = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, SettingString.DimensionKind);
		Field = StringFunctionsClientServer.SubstituteParametersToString(FieldPattern, SettingString.GetID());
		CommonClientServer.MessageToUser(Message,, Field,, Cancel);
		
	EndDo;
	
EndProcedure

// Puts the settings for filling in Analytics from the form Builder settings in these rules.
// 
// Parameters:
// 	ParametersForFillingInAnalytics - ClientApplicationForm - Form containing Attributes:
//   *SettingsComposer - DataCompositionSettingsComposer - The linker settings.
//   *AddressOfDataCompositionSchema - String - address of the temporary storage of the fact receipt scheme.
// 	Rule - CatalogObject.ActualDataQueryRulesByBudgetBalanceItems - rules for getting a fact.
// 			- CatalogObject.ActualDataQueryRulesByBudgetFlowItems -
// 			- CatalogObject.NonFinancialItemsOfBudgets -
//
Procedure PutAnalyticsFillingSettingsInRule(ParametersForFillingInAnalytics, Rule) Export
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		Rule["DimensionValue" + DimensionNumber] = Undefined;
		Rule["FillInAnalyticsWithSpecifiedValue" + DimensionNumber] = Undefined;
		Rule["DimensionPopulationExpression" + DimensionNumber] = Undefined;
	EndDo;
	
	For Each SettingString In ParametersForFillingInAnalytics.DimensionPopulationSettings Do
		DimensionNumber = SettingString.DimensionNumber;
		Rule["DimensionValue" + DimensionNumber] = SettingString.DimensionValue;
		Rule["FillInAnalyticsWithSpecifiedValue" + DimensionNumber] = SettingString.FillInTheSpecifiedValue;
		Rule["DimensionPopulationExpression" + DimensionNumber] = SettingString.DimensionPopulationExpression;
	EndDo;
	
EndProcedure

Procedure CheckAnalyticsFillExpression(SettingString, SettingsComposer, ExpressionsWithPresentationsOfCharacteristics, ColumnNamesOfExpression, ClearInaccessibleSettings = False)
	
	ColumnNameExpression = ColumnNamesOfExpression.ColumnNameExpression;
	ColumnNamePresentationOfExpression = ColumnNamesOfExpression.ColumnNamePresentationOfExpression;
	
	If CommonClientServer.HasAttributeOrObjectProperty(SettingString, "FillingMethod") Then
		If SettingString.FillingMethod <> Enums.MethodsOfFillingBudgetFlowItemDimensions.FromDataSource Then
			SettingString[ColumnNameExpression] = "";
		EndIf;
	ElsIf CommonClientServer.HasAttributeOrObjectProperty(SettingString, "FillInTheSpecifiedValue")
		And SettingString.FillInTheSpecifiedValue Then
		SettingString[ColumnNameExpression] = "";
	EndIf;
	
	If SettingString[ColumnNameExpression] = "" Then
		SettingString.MissingInAvailableFields = False;
		SettingString[ColumnNamePresentationOfExpression] = "";
		Return;
	EndIf;
	
	SettingString.MissingInAvailableFields = False;
	
	ModifiedExpression = ExpressionsWithPresentationsOfCharacteristics.Get(SettingString[ColumnNameExpression]);
	Field = New DataCompositionField(ModifiedExpression);
	AvailableField = SettingsComposer.Settings.SelectionAvailableFields.FindField(Field);
	If AvailableField = Undefined Then
		If ClearInaccessibleSettings Then
			SettingString[ColumnNameExpression] = "";
		Else
			SettingString.MissingInAvailableFields = True;
		EndIf;
		SettingString[ColumnNamePresentationOfExpression] = SettingString[ColumnNameExpression];
	Else
		SettingString[ColumnNamePresentationOfExpression] = AvailableField.Title;
	EndIf;
	
EndProcedure

// Checks the correctness of the fill-in expression.
// 
// Parameters:
// 	ParametersForFillingInAnalytics - ClientApplicationForm - Form containing Attributes:
// 	 *AddressOfDataCompositionSchema - String - Address of the temporary storage containing the data layout scheme.
// 	 *SettingsComposer - DataCompositionSettingsComposer - The linker settings form.
// 	RowID - Number - The ID of the current dimension line.
// 	TabularSectionName - String - name of the tabular part containing the settings for filling in analytics
//
Procedure CheckAnalyticsFillExpressionAfterSelection(ParametersForFillingInAnalytics, RowID, TabularSectionName) Export
	
	If StrFind(TabularSectionName, "Object.") Then
		TabularSectionName = StrReplace(TabularSectionName, "Object.", "");
		SettingString = ParametersForFillingInAnalytics.Object[TabularSectionName].FindByID(RowID);
	Else
		SettingString = ParametersForFillingInAnalytics[TabularSectionName].FindByID(RowID);
	EndIf;
	CompositionSchema = GetFromTempStorage(ParametersForFillingInAnalytics.AddressOfDataCompositionSchema);
	ParametersForFillingInAnalytics.SettingsComposer.Initialize(
		New DataCompositionAvailableSettingsSource(ParametersForFillingInAnalytics.AddressOfDataCompositionSchema));
	
	ColumnNamesOfExpression = New Structure;
	If TabularSectionName = "DataCalculationSettings" Then
		ColumnNamesOfExpression.Insert("ColumnNameExpression", "ExpressionOffsetPeriod");
		ColumnNamesOfExpression.Insert("ColumnNamePresentationOfExpression", "PresentationOfOffsetPeriodExpression");
	Else
		ColumnNamesOfExpression.Insert("ColumnNameExpression", "DimensionPopulationExpression");
		ColumnNamesOfExpression.Insert("ColumnNamePresentationOfExpression", "PresentationOfDimensionPopulationExpression");
	EndIf;
	
	ArrayOfExpressions = New Array;
	ArrayOfExpressions.Add(SettingString[ColumnNamesOfExpression.ColumnNameExpression]);
	ExpressionsWithPresentationsOfCharacteristics = ProcessingOfFormulas.ExpressionsWithPresentationsOfCharacteristicsForOnlineVerification(
		ArrayOfExpressions, CompositionSchema);
	
	CheckAnalyticsFillExpression(SettingString,
	ParametersForFillingInAnalytics.SettingsComposer, ExpressionsWithPresentationsOfCharacteristics, ColumnNamesOfExpression);
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	ParametersForFillingInAnalytics - ClientApplicationForm - Form with Attributes:
// * DimensionPopulationSettings - ValueTable -:
// ** DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
// ** DimensionNumber - Number - The dimension number.
// ** DimensionPopulationExpression - String - Expression for filling in Analytics.
// ** FillInTheSpecifiedValue - Boolean - Fill in the specified value.
// ** DimensionValue - AnyRef - the value of analytics.
// ** PresentationOfDimensionPopulationExpression - String - Representation of an expression.
// ** MissingInAvailableFields - Boolean - Flag for the absence of a field for the specified expression in the available fields.
// ** AdditionalProperty - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo -
// 	Rule - CatalogObject.ActualDataQueryRulesByBudgetBalanceItems -
// 			- CatalogObject.ActualDataQueryRulesByBudgetFlowItems -
// 			- CatalogObject.NonFinancialItemsOfBudgets - An object containing the settings for filling in the analytics.
// 	ClearInaccessibleSettings - Boolean - Flag for clearing unavailable settings.
// 	TabularSectionName - String - name of the table part
//
Procedure CheckAvailabilityOfAnalyticsFields(ParametersForFillingInAnalytics, Rule,
	ClearInaccessibleSettings = False, TabularSectionName = "") Export
	
	If IsTempStorageURL(ParametersForFillingInAnalytics.AddressOfDataCompositionSchema) Then
		CompositionSchema = GetFromTempStorage(ParametersForFillingInAnalytics.AddressOfDataCompositionSchema);
	Else
		CompositionSchema = Undefined;
	EndIf;
	
	If IsBlankString(TabularSectionName) Then
		DimensionFillingSettings = ParametersForFillingInAnalytics.DimensionPopulationSettings;
	ElsIf TabularSectionName = "DimensionsHierarchy" Then
		DimensionFillingSettings = ParametersForFillingInAnalytics.DimensionsHierarchy;
	Else
		DimensionFillingSettings = Rule[TabularSectionName];
	EndIf;
	ColumnNamesOfExpression = New Structure;
	If TabularSectionName = "DataCalculationSettings" Then
		ColumnNamesOfExpression.Insert("ColumnNameExpression", "ExpressionOffsetPeriod");
		ColumnNamesOfExpression.Insert("ColumnNamePresentationOfExpression", "PresentationOfOffsetPeriodExpression");
	Else
		ColumnNamesOfExpression.Insert("ColumnNameExpression", "DimensionPopulationExpression");
		ColumnNamesOfExpression.Insert("ColumnNamePresentationOfExpression", "PresentationOfDimensionPopulationExpression");
	EndIf;
	
	AnalystExpressions = New Array;
	For Each SettingString In DimensionFillingSettings Do
		If ValueIsFilled(SettingString[ColumnNamesOfExpression.ColumnNameExpression]) Then
			AnalystExpressions.Add(SettingString[ColumnNamesOfExpression.ColumnNameExpression]);
		EndIf;
	EndDo;
	ExpressionsWithPresentationsOfCharacteristics = ProcessingOfFormulas.ExpressionsWithPresentationsOfCharacteristicsForOnlineVerification(
		AnalystExpressions,
		CompositionSchema);
	
	For Each SettingString In DimensionFillingSettings Do
		CheckAnalyticsFillExpression(SettingString,
			ParametersForFillingInAnalytics.SettingsComposer,
			ExpressionsWithPresentationsOfCharacteristics,
			ColumnNamesOfExpression,
			ClearInaccessibleSettings);
	EndDo;
	
EndProcedure

// Sets the settings for filling in Analytics based on the algorithm.
// 
// Parameters:
// 	ParametersForFillingInAnalytics - ClientApplicationForm, Structure - Form or structure with properties:
// * AddressOfDataCompositionSchema - String - Address of the temporary storage of the layout diagram.
// * SettingsComposer - DataCompositionSettingsComposer - The linker settings.
// * UUID - UUID - the ID of the form.
// * DimensionPopulationSettings - ValueTable - settings for filling in analytics:
// ** DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
// ** DimensionNumber - Number - The dimension number.
// ** DimensionPopulationExpression - String - Expression for filling in Analytics.
// ** FillInTheSpecifiedValue - Boolean - Fill in the specified value.
// ** DimensionValue - AnyRef - the value of analytics.
// ** PresentationOfDimensionPopulationExpression - String - Representation of an expression.
// ** MissingInAvailableFields - Boolean - Flag for the absence of a field for the specified expression in the available fields.
// ** AdditionalProperty - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - link to additional Attributes.
// 	Set-up tablesapplication
// 					 TablesFormcOllection
// 	AnalyticsFillInExpressions - See BudgetingServer.ExpressionsForFillingInAnalyticsAccordingToDataLayoutScheme
//
Procedure SetSettingsForFillingInAnalyticsAutomatically(ParametersForFillingInAnalytics, TableName, AnalyticsFillInExpressions = Undefined) Export
	
	If IsTempStorageURL(ParametersForFillingInAnalytics.AddressOfDataCompositionSchema) Then
		
		If TableName = "DimensionsHierarchy" Then
			ColumnNames = "DimensionKind";
			Filter = New Structure("Used, DimensionName", True, "");
		Else
			ColumnNames = "DimensionNumber, DimensionKind";
			Filter = New Structure;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(ParametersForFillingInAnalytics, TableName) Then
			TableOfAnalyticsSettings = ParametersForFillingInAnalytics[TableName];
		Else
			TableOfAnalyticsSettings = ParametersForFillingInAnalytics.Object[TableName];
		EndIf;
		
		DataCompositionSchema = GetFromTempStorage(ParametersForFillingInAnalytics.AddressOfDataCompositionSchema);
		If AnalyticsFillInExpressions = Undefined Then
			If TypeOf(TableOfAnalyticsSettings) = Type("ValueTable") Then
				DimensionKinds = TableOfAnalyticsSettings.Copy(Filter, ColumnNames);
			Else
				DimensionKinds = TableOfAnalyticsSettings.Unload(Filter, ColumnNames);
			EndIf;
			
			AnalyticsFillInExpressions = ExpressionsForFillingInAnalyticsAccordingToDataLayoutScheme(DataCompositionSchema, DimensionKinds);
		EndIf;
		
		MessageTemplate = NStr("vi = 'Trong nguồn có nhiều tùy chọn phù hợp để điền chỉ số ""%1"". Yêu cầu lựa chọn thủ công.';
								|ru = 'В источнике есть несколько подходящих вариантов заполнения аналитики ""%1"". Требуется ручной выбор.';
								|en = 'There are several suitable options for mapping the ""%1"" dimension in the source. Select manually.'; fa = 'There are several suitable options for mapping the ""%1"" dimension in the source. Select manually.';
								|it = 'Nella sorgente ci sono alcune varianti adatte alla compilazione dell''analitica ""%1"". È necessaria una selezione manuale.';
								|pl = 'W źródle jest kilka odpowiednich wariantów wypełnienia analityki ""%1"". Jest wymagany ręczny wybór.';
								|tr = 'Kaynakta ""%1"" boyutu için bazı doldurma seçenekleri mevcut. Manuel olarak seçim yapmak gerekli.'");
		FieldPattern = TableName + "[%1].PresentationOfDimensionPopulationExpression";
		TheFormContext = Not TypeOf(TableOfAnalyticsSettings) = Type("ValueTable");
		
		ColumnNamesOfExpression = New Structure;
		ColumnNamesOfExpression.Insert("ColumnNameExpression", "DimensionPopulationExpression");
		ColumnNamesOfExpression.Insert("ColumnNamePresentationOfExpression", "PresentationOfDimensionPopulationExpression");
		
		ArrayOfExpressions = New Array;
		For Each SettingString In TableOfAnalyticsSettings Do
			Filter = New Structure(ColumnNames);
			FillPropertyValues(Filter, SettingString);
			SearchResult = AnalyticsFillInExpressions.FindRows(Filter);
			If SearchResult.Count() = 0 Then
				Continue;
			EndIf;
			SearchResult = SearchResult[0];
			
			If ValueIsFilled(SearchResult.Expression) Then
				If SearchResult.Ambiguous_ Then
					SettingString[ColumnNamesOfExpression.ColumnNameExpression] = "";
				Else
					SettingString[ColumnNamesOfExpression.ColumnNameExpression] = SearchResult.Expression;
				EndIf;
				If TableName = "DimensionPopulationSettings" Then
					SettingString.FillInTheSpecifiedValue = False;
				EndIf;
			Else
				SettingString[ColumnNamesOfExpression.ColumnNameExpression] = "";
				If TableName = "DimensionPopulationSettings" Then
					SettingString.FillInTheSpecifiedValue = True;
				EndIf;
			EndIf;
			
			If SearchResult.Ambiguous_ And TheFormContext Then
				Message = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, SettingString.DimensionKind);
				Field = StringFunctionsClientServer.SubstituteParametersToString(FieldPattern, SettingString.GetID());
				CommonClientServer.MessageToUser(Message, , Field);
			EndIf;
			
			ArrayOfExpressions.Add(SettingString[ColumnNamesOfExpression.ColumnNameExpression]);
		EndDo;
		
		ExpressionsWithPresentationsOfCharacteristics = ProcessingOfFormulas.ExpressionsWithPresentationsOfCharacteristicsForOnlineVerification(
			ArrayOfExpressions,
			DataCompositionSchema);
		
		For Each SettingString In TableOfAnalyticsSettings Do
			CheckAnalyticsFillExpression(SettingString,
				ParametersForFillingInAnalytics.SettingsComposer, ExpressionsWithPresentationsOfCharacteristics, ColumnNamesOfExpression);
		EndDo;
		
	EndIf;
	
EndProcedure

// Overrides the properties of some fields in the data layout schema, depending on additional rule parameters.
// 
// Parameters:
// 	DataCompositionSchema - DataCompositionSchema - scheme of the layout.
// 	Rule - CatalogObject.ActualDataQueryRulesByBudgetFlowItems -
// 			- CatalogObject.ActualDataQueryRulesByBudgetBalanceItems -
// 			- CatalogRef.ActualDataQueryRulesByBudgetFlowItems -
// 			- CatalogRef.ActualDataQueryRulesByBudgetBalanceItems - The rule of obtaining a fact.
Procedure SetFieldPropertiesForRuleSettings(DataCompositionSchema, Rule) Export
	
	If DataCompositionSchema = Undefined
		Or DataCompositionSchema.DataSets.Count() = 0 Then
		Return;
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Rule, "DataSourceSection")
		And (Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting
		Or Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting) Then
		
		DatasetFields = DataCompositionSchema.DataSets[0].Fields;
		
		Account = Rule.DataSource;
		ExtDimensionTypes = FinancialReportingCached.AccountExtDimensionTypes(Rule.DataSource);
		AccountGroupField = DatasetFields.Find("GroupAccount_3");
		If AccountGroupField <> Undefined Then
			AccountAttributes = Common.ObjectAttributesValues(Account, "Code, Description");
			AccountGroupField.Title = StringFunctionsClientServer.SubstituteParametersToString(
				"%1, %2", AccountAttributes.Code, AccountAttributes.Description); 
		EndIf;
		
		TypesOfCorExtdimension = Undefined;
		If TypeOf(Rule.Ref) = Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems")
			And ValueIsFilled(Rule.CorDataSource) Then
			
			BalancedAccount = Rule.CorDataSource;
			TypesOfCorExtdimension = FinancialReportingCached.AccountExtDimensionTypes(Rule.CorDataSource);
			FieldGroupCorAccount = DatasetFields.Find("GroupCorAccount");
			If FieldGroupCorAccount <> Undefined Then
				AccountAttributes = Common.ObjectAttributesValues(BalancedAccount, "Code, Description");
				FieldGroupCorAccount.Title = StringFunctionsClientServer.SubstituteParametersToString(
					"%1, %2", AccountAttributes.Code, AccountAttributes.Description); 
			EndIf;
			
			CorAccountField = DatasetFields.Find("GroupCorAccount.BalancedAccount");
			If CorAccountField <> Undefined Then
				CorAccountField.UseRestriction.Condition = True;
				CorAccountField.AttributeUseRestriction.Condition = True;
			EndIf;
			
		EndIf;
		
		SetExtdimensionFieldProperties(DataCompositionSchema, ExtDimensionTypes, TypesOfCorExtdimension);
		
	EndIf;
	
	// Let's hide the service fields from the list of fields available for selection
	ServiceFields = DataSourcesCached.ServiceFieldsOfCalculationTemplates();
	
	For Each SetField In DataCompositionSchema.DataSets[0].Fields Do
		
		If TypeOf(SetField) = Type("DataCompositionSchemaDataSetFieldFolder") Then 
			Continue;
		EndIf;
		
		ThisFieldIsNotAvailableForAnalytics =
			Not ValueIsFilled(SetField.ValueType)
			Or SetField.ValueType.ContainsType(Type("Number"));
		
		SetField.UseRestriction.Field = ThisFieldIsNotAvailableForAnalytics;
		SetField.AttributeUseRestriction.Field = ThisFieldIsNotAvailableForAnalytics;
		
		If SetField.Field = "Recorder" And CommonClientServer.HasAttributeOrObjectProperty(Rule,
			"CachingOfRuleResults") Then
			
			IntermediateCaching = Rule.CachingOfRuleResults;
			
			SetField.UseRestriction.Field = False;
			SetField.UseRestriction.Condition = Not IntermediateCaching;
			SetField.AttributeUseRestriction.Field = Not IntermediateCaching;
			SetField.AttributeUseRestriction.Condition = Not IntermediateCaching;
			
		ElsIf Not ServiceFields.Find(SetField.Field) = Undefined Then
			
			SetField.UseRestriction.Condition = True;
			
		EndIf;
		
	EndDo;
	
	NamesOfReservedParameters = NamesOfCommonParametersOfFactGettingRules();
	For Each LayoutParameter In DataCompositionSchema.Parameters Do
		If Not NamesOfReservedParameters.Find(LayoutParameter.Name) = Undefined Then
			LayoutParameter.UseRestriction = True;
			LayoutParameter.IncludeInAvailableFields = False;
		EndIf;
	EndDo;
	
EndProcedure

Procedure SetExtdimensionFieldProperties(DataCompositionSchema, ExtDimensionTypes, TypesOfCorExtdimension = Undefined)
	
	DatasetFields = DataCompositionSchema.DataSets[0].Fields;
	For ExtDimensionNumber = 1 To 3 Do
		SetExtdimensionFieldProperties_(ExtDimensionNumber, False, DatasetFields, ExtDimensionTypes);
		If TypesOfCorExtdimension <> Undefined Then
			SetExtdimensionFieldProperties_(ExtDimensionNumber, True, DatasetFields, TypesOfCorExtdimension);
		EndIf;
	EndDo;
	
EndProcedure

Procedure SetExtdimensionFieldProperties_(ExtDimensionNumber, BalancedExtDimension, DatasetFields, ExtDimensionTypes)
	
	If BalancedExtDimension Then
		FieldName = "BalancedExtDimension" + ExtDimensionNumber;
	Else
		FieldName = "ExtDimension" + ExtDimensionNumber;
	EndIf;
	
	// Adding a restriction to a condition is incorrect, because the rules may have selection settings based on the properties of the account
	// even if the COR account itself is not specified in the rule
	UseRestrictions = New Array;
	UseRestrictions.Add("Field");
	UseRestrictions.Add("Group");
	UseRestrictions.Add("Order");
	
	For Each DataSetField In DatasetFields Do
		If TypeOf(DataSetField) = Type("DataCompositionSchemaDataSetFieldFolder") Then
			Continue;
		EndIf;
		If DataSetField.Field <> FieldName Then
			Continue;
		EndIf;
		StringViewExtdimension = ExtDimensionTypes.Find(ExtDimensionNumber, "ExtDimensionNumber");
		If StringViewExtdimension <> Undefined Then
			DataSetField.ValueType = StringViewExtdimension.ValueType;
			DataSetField.Title = String(StringViewExtdimension.ExtDimensionType);
		Else
			For Each Restriction In UseRestrictions Do
				DataSetField.UseRestriction[Restriction] = True;
				DataSetField.AttributeUseRestriction[Restriction] = True;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

// Sets the conditional design of the settings for filling in Analytics.
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - 
//  TableName - String - name of the table with settings for filling in analytics
//
Procedure SetConditionalSettingsForFillingInAnalytics(ConditionalAppearance, TableName) Export
	
	AddAnalyticsDisplaySettingsToConditionalAppearance(ConditionalAppearance, TableName);
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField(TableName + ".FillInTheSpecifiedValue");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = False;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	Appearance.Use = True;
	Appearance.Value = False;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField(TableName + "DimensionPopulationExpression");
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField(TableName + "MissingInAvailableFields");
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField(TableName + ".FillInTheSpecifiedValue");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = True;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	Appearance.Use = True;
	Appearance.Value = False;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField(TableName + "DimensionValue");
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField(TableName + ".FillInTheSpecifiedValue");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	If TableName = "DimensionsHierarchy" Then
		AddSelectionBasedOnTypesOfAnalyticsUsed(ConditionalAppearanceItem.Filter, False, TableName);
	EndIf;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	Appearance.Use = True;
	Appearance.Value = NStr("vi = 'Giá trị chỉ định';
							|ru = 'Указанным значением';
							|en = 'Specified value'; fa = 'مقدار مشخص‌شده';
							|it = 'Con il valore indicato';
							|pl = 'Wskazaną wartością';
							|tr = 'Belirtilen değer ile'");
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField(TableName + "FillInTheSpecifiedValue");
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField(TableName + ".FillInTheSpecifiedValue");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	If TableName = "DimensionsHierarchy" Then
		AddSelectionBasedOnTypesOfAnalyticsUsed(ConditionalAppearanceItem.Filter, False, TableName);
	EndIf;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	Appearance.Use = True;
	Appearance.Value = NStr("vi = 'Từ dữ liệu nguồn';
							|ru = 'Из источника данных';
							|en = 'From data source'; fa = 'از منبع داده';
							|it = 'Dall''origine dei dati';
							|pl = 'Ze źródła danych';
							|tr = 'Kaynaktan veriler'");
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField(TableName + "FillInTheSpecifiedValue");
	
	If TableName = "DimensionsHierarchy" Then
	
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		
		AddSelectionBasedOnTypesOfAnalyticsUsed(ConditionalAppearanceItem.Filter, True, TableName);
		
		Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Enabled");
		Appearance.Use = True;
		Appearance.Value = False;
	
		Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Text");
		Appearance.Use = True;
		Appearance.Value = "";
		
		FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
		FormattedField.Use = True;
		FormattedField.Field = New DataCompositionField(TableName + "FillInTheSpecifiedValue");
		
		FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
		FormattedField.Use = True;
		FormattedField.Field = New DataCompositionField(TableName + "DimensionPopulationExpression");
		
		FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
		FormattedField.Use = True;
		FormattedField.Field = New DataCompositionField(TableName + "DimensionValue");
		
	EndIf;
	
EndProcedure

// Re-fills in the details of the fact receipt rules for the selected data receipt rules.
// 
// Parameters:
// 	Object - CatalogObject.ActualDataQueryRulesByBudgetBalanceItems -
// 			- CatalogObject.ActualDataQueryRulesByBudgetFlowItems - the rule.
//
Procedure FillInDetailsOfObjectInAnalyticsSettings(Object) Export
	
	ParametersForFillingInAnalytics = TemplateForAnalystFillingParameters();
	DimensionKinds = DimensionKinds(Object);
	
	If Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		ParametersForFillingInAnalytics.AddressOfDataCompositionSchema = PutToTempStorage(Object.DataSourceScheme.Get());
	EndIf;
	
	InitializeRuleSettingsComposer(Object, ParametersForFillingInAnalytics, Undefined); 
	FillInSettingsForFillingInAnalyticsByRule(ParametersForFillingInAnalytics, Object, DimensionKinds);
	CheckAvailabilityOfAnalyticsFields(ParametersForFillingInAnalytics, Object);
	SetSettingsForFillingInAnalyticsAutomatically(ParametersForFillingInAnalytics, "DimensionPopulationSettings");
	PutAnalyticsFillingSettingsInRule(ParametersForFillingInAnalytics, Object);
	
EndProcedure

Procedure AddSelectionBasedOnTypesOfAnalyticsUsed(Filter, Invert, TableName)
	
	DataFilterItemsGroup = Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	DataFilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField(TableName + ".Used");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = Not Invert;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField(TableName + ".DimensionKind");
	DataFilterItem.ComparisonType = ?(Invert, DataCompositionComparisonType.Equal, DataCompositionComparisonType.NotEqual);
	DataFilterItem.RightValue = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef();
	
EndProcedure

// Fills in the details of the schema hashes and data layout settings before writing the rules.
// 
// Parameters:
// 	Object - CatalogObject.ActualDataQueryRulesByBudgetBalanceItems -
// 			- CatalogObject.ActualDataQueryRulesByBudgetFlowItems - the rule.
Procedure FillInDetailsOfSettingsAndSchemaHashes(Object) Export
	
	// Generating and verifying the uniqueness of the hash for settings
	DCSettings = Undefined;
	If Not Object.AdditionalProperties.Property("DCSettings", DCSettings) Then
		DCSettings = Object.SettingsComposer.Get();
	EndIf;
	Object.SettingsHash = HashSettingsWithUniquenessCheck(Object, DCSettings);

	// Generating and verifying the uniqueness of a hash for an arbitrary scheme
	If Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		DCSchema = Object.DataSourceScheme.Get();
		Object.HashOfDataCompositionSchema = HashSettingsWithUniquenessCheck(Object, DCSchema);
	Else
		Object.HashOfDataCompositionSchema = "";
	EndIf;
	
EndProcedure

// Returns the hash of settings.
// 
// Parameters:
// 	Object - CatalogObject.ActualDataQueryRulesByBudgetFlowItems, CatalogObject.ActualDataQueryRulesByBudgetBalanceItems - LongDesc
// 	Settings - DataCompositionSchema, DataCompositionSettings - scheme or settings.
// Returns:
// 	String - Hash.
Function HashSettingsWithUniquenessCheck(Object, Settings)
	
	ThisIsRuleOfObtainingFactForBudgetItems = False;
	If TypeOf(Object) = Type("CatalogObject.ActualDataQueryRulesByBudgetBalanceItems") Then
		SourceCatalogName = "ActualDataQueryRulesByBudgetBalanceItems";
	ElsIf TypeOf(Object) = Type("CatalogObject.ActualDataQueryRulesByBudgetFlowItems") Then
		SourceCatalogName = "ActualDataQueryRulesByBudgetFlowItems";
		ThisIsRuleOfObtainingFactForBudgetItems = True;
	EndIf;
	
	TheseAreDataLayoutSettings = TypeOf(Settings) = Type("DataCompositionSettings");
	
	Local = False;
	International = False;
	International = Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting;
	// Checking for the presence of an identical hash for other objects and modifying it
	HashIsRepeatedForDifferentSettings = True;
	
	While HashIsRepeatedForDifferentSettings Do 
		If TheseAreDataLayoutSettings Then
			// The selection is not stored, but affects the uniqueness of the hash for articles
			// In arbitrary rules, the data source is an information field and is not set by the user.
			If Not Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
				FinancialReportingServer.NewFilter(Settings.Filter, "DataSource", Object.DataSource);
				If Local Or International Then
					If ThisIsRuleOfObtainingFactForBudgetItems Then
						FinancialReportingServer.NewFilter(Settings.Filter, "GroupCorAccount.BalancedAccount", Object.CorDataSource);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		SerializedSettings = Common.ValueToXMLString(Settings);
		SettingsHash = TMCommonUse.HashSumOfString(SerializedSettings, HashFunction.MD5);
			
		// It is not obtained from the cache, because further in the code the "Link" field is deleted in the add. settings.
		If TheseAreDataLayoutSettings Then
			SettingsWithIdenticalHash = DataSourcesServer.GetStoredCatalogSettings(SourceCatalogName,
				SettingsHash, ?(SourceCatalogName = "ActualDataQueryRulesByBudgetFlowItems", Object.BudgetFlowItem,
				Object.BudgetBalanceItem));
		Else
			SettingsWithIdenticalHash = DataSourcesServer.GettingStoredCatalogTemplate(SourceCatalogName,
				SettingsHash, ?(SourceCatalogName = "ActualDataQueryRulesByBudgetFlowItems", Object.BudgetFlowItem,
				Object.BudgetBalanceItem));
		EndIf;
		
		// There are no recorded objects with an identical hash
		If SettingsWithIdenticalHash = Undefined Then
			HashIsRepeatedForDifferentSettings = False;
		Else
			If TheseAreDataLayoutSettings Then
				AdditionalProperties = SettingsWithIdenticalHash.AdditionalProperties; // Structure
			Else
				AdditionalProperties = SettingsWithIdenticalHash.DefaultSettings.AdditionalProperties;
			EndIf;
		
			// Only the current object was found
			HashIsRepeatedForDifferentSettings = Not Object.Ref = AdditionalProperties.Ref;
			
			// When comparing settings, the link property is not required
			AdditionalProperties.Delete("Ref");
			
			If TheseAreDataLayoutSettings Then
				// The selection is not stored, but affects the uniqueness of the hash for articles
				// In arbitrary rules, the data source is an information field and is not set by the user.
				If Not Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
					FinancialReportingServer.NewFilter(SettingsWithIdenticalHash.Filter, "DataSource", Object.DataSource);
					If Local Or International Then
						If ThisIsRuleOfObtainingFactForBudgetItems Then
							FinancialReportingServer.NewFilter(Settings.Filter, "GroupCorAccount.BalancedAccount", Object.CorDataSource);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
			
		// There are objects with an identical hash in the database. Let's check the identity of the settings
		If HashIsRepeatedForDifferentSettings Then
			SerializedSettingsWithIdenticalHash = Common.ValueToXMLString(SettingsWithIdenticalHash);
			
			If SerializedSettings <> SerializedSettingsWithIdenticalHash Then
				HashModifier = Undefined;
				If TheseAreDataLayoutSettings Then
					AdditionalProperties = Settings.AdditionalProperties;
				Else
					AdditionalProperties = Settings.DefaultSettings.AdditionalProperties;
				EndIf;
				
				If Not AdditionalProperties.Property("HashModifier", HashModifier) Then
					AdditionalProperties.Insert("HashModifier");
				EndIf;
				
				If HashModifier = Undefined Then
					HashModifier = 1;
				Else
					HashModifier = HashModifier + 1;
				EndIf;
				
				If HashModifier = 10 Then
					ErrorText = NStr("vi = 'Đã vượt quá số lần cho phép kiểm tra hash tùy chỉnh.
						|Đã ngắt thực hiện để ngăn chặn vòng lặp của cơ chế ghi lại đối tượng.';
						|ru = 'Превышено допустимое количество итераций проверки хеша настроек.
						|Выполнение прервано для предотвращения зацикливания механизма записи объекта.';
						|en = 'The maximum number of check iterations of settings hash is exceeded.
						|Execution is aborted to prevent looping when writing the object.'; fa = 'The maximum number of check iterations of settings hash is exceeded.
						|Execution is aborted to prevent looping when writing the object.';
						|it = 'È superato il numero massimo di interazioni di controllo dell''hash delle impostazioni.
						|L''esecuzione è stata interrotta per prevenire la creazione di cicli nel meccanismo di scrittura dell''oggetto.';
						|pl = 'Przekroczona dopuszczalna ilość iteracji weryfikacji hashu ustawień. 
						|Wykonanie przerwano dla zapobiegania zapętlenia mechanizmu zapisu obiektu.';
						|tr = 'Ayarların sonuç doğrulaması için izin verilen yineleme sayısı aşıldı.
						|Nesne kaydetme mekanizmasının döngü önlemleri sebebiyle kesintiye uğradı.'");
					Raise ErrorText;
				EndIf;
				
				AdditionalProperties.HashModifier = HashModifier;
				
				// Let's update the hash of the settings taking into account the modifier
				SerializedSettings = Common.ValueToXMLString(Settings);
				SettingsHash = TMCommonUse.HashSumOfString(SerializedSettings, HashFunction.MD5);
			Else 
				HashIsRepeatedForDifferentSettings = False;
			EndIf;
		EndIf;
	EndDo;
	
	Return SettingsHash;
	
EndFunction

#EndRegion

#Region GettingDataOnArticlesAndIndicators

// LongDesc
// 
// Parameters:
// 	DataTableByBudgetType - See TemplateForDataTableByBudgetType
// 	DataSource - Structure - structure with properties:
// 	 *SourceType - EnumRef.BudgetingDataSourceTypes - source type.
// 	 *Objects - Array of CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems, CatalogRef.NonFinancialItemsOfBudgets -
// 	 *AssumesActualData - String - Indicates whether to get the fact from the source, depending on the settings.
// 	 *Id - String - ID of the data source.
// 	Parameters - Structure - LongDesc:
// * ReportCurrency - CatalogRef.Currencies -
// * FunctionalCurrency - EnumRef.AccountingKindsInFunctionalCurrency -
// * InternationalCurrency - CatalogRef.Currencies -
// * Period - StandardPeriod -
// * Periodicity - EnumRef.Periodicity, Undefined -
// * BalancesOnlyAtBeginningOfPeriod - Boolean -
// * ReturnManAndLocalAmounts - Boolean -
// * DataAcquisitionRules - Boolean -
// * Indicators - Structure -:
// ** Count - Arbitrary -
// ** Sum - Arbitrary -
// * AddStoredFactForItemsThatAffectBudgetPerformance - Boolean -
// * DimensionKinds - Array of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// * ByCompanies - Boolean -
// * ByBusinessUnits - Boolean -
// * ByRegistrar - Boolean -
// * AdditionalSelection - Structure -:
// ** Key - Arbitrary -
// ** Value - Arbitrary -
// 	DataParameters - Structure - LongDesc
Procedure GetFactFromDataSourceRevolutions(DataTableByBudgetType, DataSource, Parameters, DataParameters)
	
	SourceParameters_2 = ParametersByDataSource(Parameters, DataSource, DataParameters);
	
	FilterRules_ = New DataCompositionSettings;
	If DataSource.SourceType = Enums.BudgetingDataSourceTypes.Turnovers Then
		DataCompositionClientServer.AddFilter(
			FilterRules_,
			"CachingOfRuleResults",
			False,
			DataCompositionComparisonType.Equal);
	EndIf;
	
	If DataSource.Objects <> Undefined Then
		BudgetFlowItems = New ValueList;
		BudgetFlowItems.LoadValues(DataSource.Objects);
		DataCompositionClientServer.AddFilter(FilterRules_, "BudgetFlowItem", BudgetFlowItems, DataCompositionComparisonType.InList);
	EndIf;
	
	ReportScript = Undefined;
	If DataParameters <> Undefined Then
		DataParameters.Property("Scenario", ReportScript);
	EndIf;
	
	ReportScenarioActualData = (ReportScript = Catalogs.BudgetingScenarios.ActualData);
	ScenarioOfBudgetExecutionReport = (ReportScript = Catalogs.BudgetingScenarios.BudgetFulfillment);
	
	AssumedFact = DataSource.AssumesActualData = "Assumed"
				Or (DataSource.AssumesActualData = "DeterminedByReportSettings"
						And ReportScenarioActualData);
	BudgetExecutionIsExpected = DataSource.AssumesBudgetExecution = "Assumed"
				Or (DataSource.AssumesBudgetExecution = "DeterminedByReportSettings"
						And ScenarioOfBudgetExecutionReport);
	
	TypesList = New ValueList;
	If AssumedFact Or BudgetExecutionIsExpected Then
		TypesList.Add(Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData);
	EndIf;
	If AssumedFact Then
		TypesList.Add(Enums.ActualBudgetingDataQueryRuleType.ActualData);
	EndIf;
	If BudgetExecutionIsExpected Then
		TypesList.Add(Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment);
	EndIf;
	
	DataCompositionClientServer.AddFilter(FilterRules_, "RuleType", TypesList, DataCompositionComparisonType.InList);
	
	FactOnBudgetItems = FactOnBudgetItems(FilterRules_, SourceParameters_2,, False);
	
	For Each String In FactOnBudgetItems Do
		NewRow = DataTableByBudgetType.Add();
		FillPropertyValues(NewRow, String);
		NewRow["ID_" + "Source1"] = DataSource.Id;
		NewRow.SumReceipt = String.Sum;
		NewRow.SumCurrReceipt = String.AmountInCurrency;
		NewRow.CountReceipt = String.Count;
	EndDo;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	DataTableByBudgetType - See TemplateForDataTableByBudgetType
// 	DataSource - Structure - structure with properties:
// 	 *SourceType - EnumRef.BudgetingDataSourceTypes - source type.
// 	 *Objects - Array of CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems, CatalogRef.NonFinancialItemsOfBudgets -
// 	 *AssumesActualData - String - Indicates whether to get the fact from the source, depending on the settings.
// 	 *Id - String - ID of the data source.
// 	Parameters - Structure - LongDesc:
// * ReportCurrency - CatalogRef.Currencies -
// * CurrencyOfMan - CatalogRef.Currencies -
// * ComplCurrency - CatalogRef.Currencies -
// * InternationalCurrency - CatalogRef.Currencies -
// * Period - StandardPeriod -
// * Periodicity - EnumRef.Periodicity, Undefined -
// * BalancesOnlyAtBeginningOfPeriod - Boolean -
// * ReturnManAndLocalAmounts - Boolean -
// * DataAcquisitionRules - Boolean -
// * Indicators - Structure -:
// ** Count - Arbitrary -
// ** Sum - Arbitrary -
// * AddStoredFactForItemsThatAffectBudgetPerformance - Boolean -
// * DimensionKinds - Array of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// * ByCompanies - Boolean -
// * ByBusinessUnits - Boolean -
// * ByRegistrar - Boolean -
// * AdditionalSelection - Structure -:
// ** Key - Arbitrary -
// ** Value - Arbitrary -
// 	DataParameters - Structure - LongDesc
Procedure GetFactFromDataSource(DataTableByBudgetType, DataSource, Parameters, DataParameters)
	
	SourceParameters_2 = ParametersByDataSource(Parameters, DataSource, DataParameters);
	
	FilterRules_ = New DataCompositionSettings;
	If DataSource.Objects <> Undefined Then
		BudgetBalanceItems = New ValueList;
		BudgetBalanceItems.LoadValues(DataSource.Objects);
		DataCompositionClientServer.AddFilter(
			FilterRules_, "BudgetBalanceItem", BudgetBalanceItems, DataCompositionComparisonType.InList);
	EndIf;
	
	ReportScript = Undefined;
	If DataParameters <> Undefined Then
		DataParameters.Property("Scenario", ReportScript);
	EndIf;
	
	ReportScenarioActualData = (ReportScript = Catalogs.BudgetingScenarios.ActualData);
	ScenarioOfBudgetExecutionReport = (ReportScript = Catalogs.BudgetingScenarios.BudgetFulfillment);
	
	AssumedFact = DataSource.AssumesActualData = "Assumed"
			Or (DataSource.AssumesActualData = "DeterminedByReportSettings"
				And  ReportScenarioActualData);
	BudgetExecutionIsExpected = DataSource.AssumesBudgetExecution = "Assumed"
			Or (DataSource.AssumesBudgetExecution = "DeterminedByReportSettings"
				And  ScenarioOfBudgetExecutionReport);
	
	TypesList = New ValueList;
	If AssumedFact Or BudgetExecutionIsExpected Then
		TypesList.Add(Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData);
	EndIf;
	If AssumedFact Then
		TypesList.Add(Enums.ActualBudgetingDataQueryRuleType.ActualData);
	EndIf;
	If BudgetExecutionIsExpected Then
		TypesList.Add(Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment);
	EndIf;
	
	DataCompositionClientServer.AddFilter(FilterRules_, "RuleType", TypesList, DataCompositionComparisonType.InList);
	
	FactOnBudgetIndicators = FactOnBudgetIndicators(FilterRules_, SourceParameters_2);
	
	BudgetingScenarios = SelectionDrivenScenarios(SourceParameters_2.AdditionalSelection);
	If BudgetingScenarios.Count() = 0 Then
		Raise NStr("vi = 'Kịch bản nguồn dữ liệu không được xác định';
					|ru = 'Не определены сценарии источника данных';
					|en = 'Data source scenarios are not determined'; fa = 'Data source scenarios are not determined';
					|it = 'Non sono stati identificati gli scenari della sorgente dei dati';
					|pl = 'Nie określono scenariuszy źródła danych';
					|tr = 'Veri kaynak senaryosu tanımlanmamış'")
	EndIf;
	
	ExecutionLines = FactOnBudgetIndicators.FindRows(New Structure("Scenario", Catalogs.BudgetingScenarios.BudgetFulfillment));
	RowsOfActualData = FactOnBudgetIndicators.FindRows(New Structure("Scenario", Catalogs.BudgetingScenarios.ActualData));
	
	For Each ScenariosRow In BudgetingScenarios Do
		If ScenariosRow.Scenario = Catalogs.BudgetingScenarios.BudgetFulfillment Then
			AdditionTable = ExecutionLines;
		Else
			AdditionTable = RowsOfActualData;
		EndIf;
		For Each FactLine_ In AdditionTable Do
			NewRow = DataTableByBudgetType.Add();
			FillPropertyValues(NewRow, FactLine_);
			NewRow.Scenario = ScenariosRow.Scenario;
			NewRow["ID_" + "Source1"] = DataSource.Id;
			
			If ValueIsFilled(NewRow.BudgetFlowItem) Then //target indicator
				NewRow.SumReceipt = FactLine_.Sum;
				NewRow.SumCurrReceipt = FactLine_.AmountInCurrency;
				NewRow.CountReceipt = FactLine_.Count;
			Else
				NewRow.SumOpeningBalance = FactLine_.Sum;
				NewRow.SumCurrOpeningBalance = FactLine_.AmountInCurrency;
				NewRow.CountOpeningBalance = FactLine_.Count;
			EndIf;
		EndDo;
	EndDo;
	
	If BudgetingScenarios.Find(Catalogs.BudgetingScenarios.ActualData) <> Undefined
		Or BudgetingScenarios.Find(Catalogs.BudgetingScenarios.BudgetFulfillment) <> Undefined Then
		FactOnBudgetItems = FactOnItemsThatAffectBudgetPerformance(FilterRules_, SourceParameters_2, False);
		For Each FactLine_ In FactOnBudgetItems Do
			NewRow = DataTableByBudgetType.Add();
			FillPropertyValues(NewRow, FactLine_);
			NewRow["ID_" + "Source1"] = DataSource.Id;
		EndDo;
	EndIf;
	
EndProcedure

Procedure GetValuesByNonFinancialDataSource(DataTableByBudgetType, DataSource, Parameters, DataParameters)
	
	SourceParameters_2 = ParametersByDataSource(Parameters, DataSource, DataParameters);
	
	FilterRules_ = New DataCompositionSettings;
	If DataSource.Objects <> Undefined Then
		NonFinancialIndicators = New ValueList;
		NonFinancialIndicators.LoadValues(DataSource.Objects);
		DataCompositionClientServer.AddFilter(
			FilterRules_, 
			"NonFinancialItem", 
			NonFinancialIndicators, DataCompositionComparisonType.InList);
	EndIf;
	
	NonFinancialItemValues = NonFinancialItemValues(FilterRules_, SourceParameters_2);
	
	CopyTableOfDataByBudgetType = DataTableByBudgetType.CopyColumns();
	TransferNFPValuesToCommonTable(NonFinancialItemValues, DataSource, Parameters, SourceParameters_2, CopyTableOfDataByBudgetType);
	
	ScriptCourseData = New Structure;
	ScriptCourseData.Insert("ActualDataLimit", DataParameters.ActualDataLimit);
	If DataParameters.Property("Scenario") And ValueIsFilled(DataParameters.Scenario) Then
		ScriptCourseData.Insert("ScenarioCourseTable", Catalogs.BudgetingScenarios.ScenarioCourseTable(DataParameters.Scenario, , DataParameters.BeginOfPeriod, DataParameters.EndOfPeriod));
	EndIf;
	
	RecalculationFields = New Array;
	RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
		"IndicatorValue", "AmountInFunctionalCurrency", "IndicatorValue", "ValueOfIndicatorInCurrency"));
	DataTableParameters = ParametersForConvertingDataTableToCurrency(CopyTableOfDataByBudgetType);
	ConvertDataTableToCurrency(DataTableParameters, Parameters.ReportCurrency, Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal, RecalculationFields, ScriptCourseData);
	
	For Each String In DataTableParameters.DataTable Do
		NewRow = DataTableByBudgetType.Add();
		FillPropertyValues(NewRow, String);
	EndDo;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	NonFinancialItemValues - See BudgetingServer.NonFinancialItemValues
// 	DataSource - ValueTableRow - Description of the data source:
// 	*Id - String - ID of the source.
// 	*ExpressionPeriod - String - The expression of the period.
// 	*ExpressionPeriodBoundary - String - Expression of the period boundary.
// 	*DependentDataSourceIndicator - CatalogRef.BudgetBalanceItems - Indicator.
// 	Parameters - See BudgetingServer.TemplateForGettingFactParameters
// 	SourceParameters_2 - See ParametersByDataSource
// 	DataTableByBudgetType - See TemplateForDataTableByBudgetType
//
Procedure TransferNFPValuesToCommonTable(Val NonFinancialItemValues, Val DataSource, Val Parameters, Val SourceParameters_2, Val DataTableByBudgetType)
	
	Var DefaultColumnValues, String;
	
	// Modify the structure of the temporary table of values and move it to the general
	// The data will not be recalculated here.
	DefaultColumnValues = New Structure;
	DefaultColumnValues.Insert("ID_" + "Source1", DataSource.Id);
	DefaultColumnValues.Insert("Currency", SourceParameters_2.ReportCurrency);
	
	DefaultColumnValues.Insert("SumOpeningBalance", 0);
	DefaultColumnValues.Insert("SumReceipt", 0);
	DefaultColumnValues.Insert("SumExpense", 0);
	DefaultColumnValues.Insert("SumCurrOpeningBalance", 0);
	DefaultColumnValues.Insert("SumCurrReceipt", 0);
	DefaultColumnValues.Insert("SumCurrExpense", 0);
	DefaultColumnValues.Insert("CountOpeningBalance", 0);
	DefaultColumnValues.Insert("CountReceipt", 0);
	DefaultColumnValues.Insert("CountExpense", 0);
	
	If ValueIsFilled(Parameters.Periodicity) Then
		NonFinancialItemValues.Columns.Period.Name = "PeriodReplaced";
		NonFinancialItemValues.Columns.InstallationPeriod.Name = "Period";
	EndIf;
	
	NonFinancialItemValues.Columns.Currency.Name = "StorageCurrency";
	
	NonFinancialItemValues.Columns.Add("RatePeriod");
	TMCommonUseClientServer.CopyValuesFromColumnToColumn(NonFinancialItemValues, "Period", "RatePeriod"); 
	
	TMCommonUseClientServer.SupplementTable(NonFinancialItemValues, DataTableByBudgetType, DefaultColumnValues);
	
	For Each String In DataTableByBudgetType Do
		String.NFPIndex = DataTableByBudgetType.IndexOf(String);
		
		// We will clarify the data for future conversion by exchange rates
		If Not String.IndicatorKind = Enums.NonFinancialItemKinds.Cash_ Then
			String.StorageCurrency = Undefined;
			String.Currency = Undefined;
		EndIf;
	EndDo;
	
	DataTableByBudgetType.Columns.Add("AmountInFunctionalCurrency", New TypeDescription("Number"));

EndProcedure

// Parameters refined by the data source.
// 
// Parameters:
// 	Parameters - Structure - LongDesc:
// 	*ReportCurrency - CatalogRef.Currencies - Currency of the report or document.
// 	*CurrencyOfMan - CatalogRef.Currencies - currency of management accounting.
// 	*ComplCurrency - CatalogRef.Currencies - Currency of regulated accounting.
// 	*InternationalCurrency - CatalogRef.Currencies - Currency of international accounting.
// 	*Period - StandardPeriod - Period of the report or document.
// 	*Periodicity - EnumRef.Periodicity - The periodicity of the data.
// 	*BalancesOnlyAtBeginningOfPeriod - Boolean - Flag for receiving balances only at the beginning of the period.
// 	*ReturnManAndLocalAmounts - Boolean -
// 	*DataAcquisitionRules - Boolean -
// 	*Indicators - Structure -:
// 	**Count - Arbitrary -
// 	**Sum - Arbitrary -
// 	*AddStoredFactForItemsThatAffectBudgetPerformance - Boolean -
// 	*DimensionKinds - Array of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	*ByCompanies - Boolean -
// 	*ByBusinessUnits - Boolean -
// 	*ByRegistrar - Boolean -
// 	*AdditionalSelection - Structure -:
// 	**Key - Arbitrary - 
// 	**Value - Arbitrary -
// 	DataSource - ValueTableRow, Structure - Description of the data source:
// 	*SourceType - EnumRef.BudgetingDataSourceTypes -
// 	*Objects - Array of CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems, CatalogRef.NonFinancialItemsOfBudgets -
// 	*AssumesActualData - String - 
// 	*Id - String - ID of the source.
// 	DataParameters - Structure - LongDesc
// 	
// Returns:
// 	Structure - structure with properties:
// 	*ReportCurrency - CatalogRef.Currencies - Currency of the report or document.
// 	*CurrencyOfMan - CatalogRef.Currencies - currency of management accounting.
// 	*ComplCurrency - CatalogRef.Currencies - Currency of regulated accounting.
// 	*InternationalCurrency - CatalogRef.Currencies - Currency of international accounting.
// 	*Period - StandardPeriod - Period of the report or document.
// 	*Periodicity - EnumRef.Periodicity - The periodicity of the data.
// 	*BalancesOnlyAtBeginningOfPeriod - Boolean - Flag for receiving balances only at the beginning of the period.
// 	*ReturnManAndLocalAmounts - Boolean -
// 	*DataAcquisitionRules - Boolean -
// 	*Indicators - Structure -:
// 	**Count - Arbitrary -
// 	**Sum - Arbitrary -
// 	*AddStoredFactForItemsThatAffectBudgetPerformance - Boolean -
// 	*DimensionKinds - Array of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	*ByCompanies - Boolean -
// 	*ByBusinessUnits - Boolean -
// 	*ByRegistrar - Boolean -
// 	*AdditionalSelection - DataCompositionSettings -:
// 	**Key - Arbitrary - 
// 	**Value - Arbitrary -
// 	*ActualDataLimit - Date - The boundary of the actual data.
// 	*ExpressionStartOfPeriod - String -
// 	*ExpressionEndOfPeriod - String - 
// 	*ExpressionOfGroupingPeriod - String - 
Function ParametersByDataSource(Parameters, DataSource, DataParameters)
	
	SourceParameters_2 = Common.CopyRecursive(Parameters);
	
	SourceParameters_2.Insert("ExpressionStartOfPeriod", ConvertToDCSExpression(
		DataSource.ExpressionStartOfPeriod));
	SourceParameters_2.Insert("ExpressionEndOfPeriod", ConvertToDCSExpression(
		DataSource.ExpressionEndOfPeriod));
	SourceParameters_2.Insert("ExpressionOfGroupingPeriod", ConvertToDCSExpression(
		DataSource.ExpressionOfGroupingPeriod));
	SourceParameters_2.Insert("ActualDataLimit", DataParameters.ActualDataLimit);
	
	AdditionalSelection = New DataCompositionSettings;
	FinancialReportingServer.CopyFilter(DataSource.AdditionalSelection.Filter,
		AdditionalSelection.Filter);
	If AdditionalSelection <> Undefined And DataParameters <> Undefined Then
		BudgetReportingDisplayServer.AddDCSSettingsBeforeOutput(AdditionalSelection, DataParameters);
	EndIf;
	SourceParameters_2.AdditionalSelection = AdditionalSelection;
	
	Return SourceParameters_2;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	ReportCurrency - CatalogRef.Currencies - Currency of the report or document.
// 	Period - StandardPeriod - Period of the report or document.
// 	Periodicity - EnumRef.Periodicity - Periodicity.
// 	DimensionKinds - Array of ChartOfCharacteristicTypesRef.ItemAttributesOfFinancialReports - Types of Analytics.
// 	ByCompanies - Boolean - The flag data in the context of organizations.
// 	ByBusinessUnits - Boolean - Flag for getting data by division.
// 	DataReceiptMode - EnumRef.BudgetingDataReceiptMode - data acquisition mode.
// Returns:
// 	Structure - See BudgetingServer.TemplateForGettingFactParameters
Function ParametersForGettingFactByBudgetType(BudgetProfile, ReportCurrency, Period, Periodicity, DimensionKinds, ByCompanies, ByBusinessUnits, DataReceiptMode)
	
	Parameters = TemplateForGettingFactParameters();
	
	Parameters.ReportCurrency = ReportCurrency;
	Parameters.Period = Period;
	Parameters.Periodicity = Periodicity;
	If DimensionKinds <> Undefined Then
		Parameters.Insert("DimensionKinds", DimensionKinds);
	EndIf;
	Parameters.ByCompanies = ByCompanies;
	Parameters.ByBusinessUnits = ByBusinessUnits;
	Parameters.BalancesOnlyAtBeginningOfPeriod = True;
	Parameters.DataReceiptMode = DataReceiptMode;
	If ValueIsFilled(BudgetProfile) Then
		Parameters.FunctionalCurrency = Common.ObjectAttributeValue(BudgetProfile, "Owner.FunctionalCurrency");
	Else
		Parameters.FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_;
	EndIf;
	
	// In budget reports (budget instances), the entire stored fact is obtained separately (cached SKD),
	// the stored fact is also not used for limits (because rules with the budget execution type do not support the stored fact).
	Parameters.AddStoredFactForItemsThatAffectBudgetPerformance = False;
	
	Return Parameters;
	
EndFunction

Function FactTableTemplateForBudgetIndicators(Parameters)
	
	FactTable_ = New ValueTable;
	FactTable_.Columns.Add("BudgetBalanceItem", New TypeDescription("CatalogRef.BudgetBalanceItems"));
	FactTable_.Columns.Add("BudgetFlowItem", New TypeDescription("CatalogRef.BudgetBalanceItems"));
	FactTable_.Columns.Add("Scenario", New TypeDescription("CatalogRef.BudgetingScenarios"));
	
	If Parameters.DataAcquisitionRules Then
		FactTable_.Columns.Add("DataSourceSection", New TypeDescription("EnumRef.SectionsOfBudgetingDataSources"));
		
		DescriptionOfDataSourceTypes = New TypeDescription(
				"ChartOfCharacteristicTypesRef.AssetLiabilityItems, 
				|ChartOfAccountsRef.International,
				|String");
		FactTable_.Columns.Add("DataSource", DescriptionOfDataSourceTypes);
		
		FactTable_.Columns.Add("TotalType", New TypeDescription("EnumRef.TypesOfTotals"));
		FactTable_.Columns.Add("Filter", New TypeDescription("String"));
		
		FactTable_.Columns.Add("Rule", New TypeDescription("CatalogRef.ActualDataQueryRulesByBudgetBalanceItems"));
		
	EndIf;
	
	TypesDetailsDate =  New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date));
	
	If Parameters.Periodicity <> Undefined Then
		FactTable_.Columns.Add("Period", TypesDetailsDate);
	EndIf;
	
	If Parameters.Property("ThereIsPeriodicityOfSecond")
		And Parameters.ThereIsPeriodicityOfSecond Then
		FactTable_.Columns.Add("SecondPeriod",
			New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.DateTime)));
	EndIf;
	
	If Parameters.ByRegistrar Then
		FactTable_.Columns.Add("Recorder", Documents.AllRefsType());
	EndIf;
	
	If Parameters.ByCompanies Then
		FactTable_.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	EndIf;
	If Parameters.ByBusinessUnits Then
		FactTable_.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	DescriptionOfAnalyticsTypes_ = AllTypesOfAnalytics();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		FactTable_.Columns.Add("Dimension" + DimensionNumber, DescriptionOfAnalyticsTypes_);
	EndDo;
	For Each DimensionKind In Parameters.DimensionKinds Do
		AnalyticsViewColumn = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		FactTable_.Columns.Add(AnalyticsViewColumn, DescriptionOfAnalyticsTypes_);
	EndDo;
	
	If Parameters.Indicators.Property("Count") Then
		FactTable_.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		FactTable_.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(15,3)));
	EndIf;
	
	If Parameters.Indicators.Property("Sum") Then
		
		NumberType = TMCommonUse.MoneyFieldTypeDescription();
		TypeAmount = New TypeDescription(NumberType, "Null");
		
		FactTable_.Columns.Add("RatePeriod", TypesDetailsDate);
		FactTable_.Columns.Add("Sum", NumberType);
		
		FactTable_.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
		FactTable_.Columns.Add("AmountInCurrency", TMCommonUse.MoneyFieldTypeDescription());
		
		If Parameters.ReturnManAndLocalAmounts Then
			FactTable_.Columns.Add("SumMan", NumberType);
			FactTable_.Columns.Add("SumCompl", NumberType);
		EndIf;
		
		FactTable_.Columns.Add("StorageCurrency", New TypeDescription("CatalogRef.Currencies"));
		FactTable_.Columns.Add("AmountInStorageCurrency", NumberType);
		FactTable_.Columns.Add("CurrencyFunctional", New TypeDescription("CatalogRef.Currencies"));
		FactTable_.Columns.Add("AmountInFunctionalCurrency", TypeAmount);
		
	EndIf;
	
	Return FactTable_;
	
EndFunction

// Returns a template for a table of values for non-financial indicators.
// 
// Parameters:
// 	Parameters - Structure - structure with properties:
// 	*ByCompanies - Boolean - The flag data in the context of organizations.
// 	*ByBusinessUnits - Boolean - Flag for getting data by division.
// 	*DimensionKinds - Array of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Types of Analytics.
// Returns:
// 	ValueTable - Table of values with columns:
// * NonFinancialItem - CatalogRef.NonFinancialItemsOfBudgets - Non-financial indicator
// * IndicatorKind - EnumRef.NonFinancialItemKinds - type of indicator.
// * Organization - CatalogRef.Companies - Organization.
// * Department - CatalogRef.BusinessStructure - unit.
// * Scenario - CatalogRef.BudgetingScenarios - Scenario.
// * Currency - CatalogRef.Currencies - Currency.
// * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - Unit of measurement for quantitative values.
// * Recorder - DocumentRef - Registrar.
// * Period - Date - Period.
// * InstallationPeriod - Date - Period for setting values.
// * SubperiodNumber - Number - The number of subperiods.
// * IndicatorValue - Number - meaning.
Function TemplateForTableOfValuesOfNonFinancialIndicators(Parameters) Export
	
	ValueTable = New ValueTable;
	ValueTable.Columns.Add("NonFinancialItem", New TypeDescription("CatalogRef.NonFinancialItemsOfBudgets"));
	ValueTable.Columns.Add("IndicatorKind", New TypeDescription("EnumRef.NonFinancialItemKinds"));
	
	If Parameters.ByCompanies Then
		ValueTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	EndIf;
	If Parameters.ByBusinessUnits Then
		ValueTable.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	EndIf;
	
	ValueTable.Columns.Add("Scenario", New TypeDescription("CatalogRef.BudgetingScenarios"));
	
	DescriptionOfAnalyticsTypes_ = AllTypesOfAnalytics();
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ValueTable.Columns.Add("Dimension" + DimensionNumber, DescriptionOfAnalyticsTypes_);
	EndDo;
	For Each DimensionKind In Parameters.DimensionKinds Do
		AnalyticsViewColumn = FinancialReportingCached.NameOfBudgetReportField(DimensionKind); 
		ValueTable.Columns.Add(AnalyticsViewColumn, DescriptionOfAnalyticsTypes_);
	EndDo;
	
	ValueTable.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	ValueTable.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	ValueTable.Columns.Add("Recorder", Documents.AllRefsType());
	
	ValueTable.Columns.Add("Period", New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date)));
	ValueTable.Columns.Add("InstallationPeriod", New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date)));
	ValueTable.Columns.Add("SubperiodNumber", New TypeDescription("Number", New NumberQualifiers(3)));
	
	ValueTable.Columns.Add("IndicatorValue", New TypeDescription("Number", New NumberQualifiers(20,6)));
	
	Return ValueTable;
	
EndFunction

// Returns a table of actual data retrieved from the budget cache
//
// Parameters:
//  Parameters - Structure - the structure of the fact receipt parameters, including:
//   * DataReceiptMode - EnumRef.BudgetingDataReceiptMode
//   * CurrentLimits - ValueTable
//  ConvertToCurrency_ - Boolean - Indicates whether conversion from the storage currency to the article currency is required
//
// Returns:
//  ValueTable - the fact table consists of columns, including:
//   * BeginOfPeriod - Date - Beginning of the period
//   * EndOfPeriod - Date - End of the period
// 
Function FactOfBudgetItemIsStored(Parameters, ConvertToCurrency_ = True) Export
	
	DataCompositionSchema = Catalogs.ActualDataQueryRulesByBudgetFlowItems.GetTemplate("StoredTurnoverByBudgetFlowItems");
	If Parameters.DataReceiptMode = Enums.BudgetingDataReceiptMode.All Then
		For Each Set In DataCompositionSchema.DataSets Do
			If ValueIsFilled(Set.Query) Then
				Set.Query = RequestSchemes.SetSelectionOfAllowedRecordsInEntireRequest(Set.Query, False);
			EndIf;
		EndDo;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For Each Set In DataCompositionSchema.DataSets Do
		If ValueIsFilled(Set.Query) Then
			ExpressionParameters = TemplateForAnalyticsFieldParametersWithConditionForNumberOfAnalyticsTypes();
			ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "BudgetTurnovers.BudgetFlowItem.NumberOfUsedDimensions";
			ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "BudgetTurnovers.Dimension";
			
			For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
				Set.Query = StrReplace(Set.Query, "&AnalystSExpression" + DimensionNumber,
					TextOfAnalyticsFieldWithConditionForNumberOfTypesOfAnalytics(ExpressionParameters, DimensionNumber));
			EndDo;
		EndIf;
	EndDo;
	
	ExternalDataSets = New Structure;
	If Parameters.Property("CurrentLimits") And TypeOf(Parameters.CurrentLimits) = Type("ValueTable") Then
		
		ExternalDataSets.Insert("CurrentLimits", Parameters.CurrentLimits);
		
		For Each Set In DataCompositionSchema.DataSets Do
			If ValueIsFilled(Set.Query) Then
				Set.Query = RequestSchemes.AddSelectionFieldToQuery(Set.Query, "&BeginOfPeriod",
					"BeginOfPeriod", , True);
				Set.Query = RequestSchemes.AddSelectionFieldToQuery(Set.Query, "&EndOfPeriod", "EndOfPeriod",
					, True);
				FinancialReportingServer.NewSetField(Set, "BeginOfPeriod", "BeginOfPeriod", ,
					Parameters.CurrentLimits.Columns.BeginOfPeriod.ValueType);
				FinancialReportingServer.NewSetField(Set, "EndOfPeriod", "EndOfPeriod", ,
					Parameters.CurrentLimits.Columns.EndOfPeriod.ValueType);
			EndIf;
		EndDo;

		LBCurrentLimits = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema, Type(
			"DataCompositionSchemaDataSetObject"), "CurrentLimits");
		For Each Column In Parameters.CurrentLimits.Columns Do
			FinancialReportingServer.NewSetField(LBCurrentLimits, Column.Name, Column.Name,
				Column.Title, Column.ValueType);
		EndDo;

		DataCompositionServer.AddDataSetAssociation(DataCompositionSchema, "CurrentLimits", "Real",
			"BudgetFlowItem", "BudgetFlowItem");
		DataCompositionServer.AddDataSetAssociation(DataCompositionSchema, "CurrentLimits", "Real",
			"BeginOfPeriod", "BeginOfPeriod", "BeginOfPeriod");
		DataCompositionServer.AddDataSetAssociation(DataCompositionSchema, "CurrentLimits", "Real",
			"EndOfPeriod", "EndOfPeriod", "EndOfPeriod");
		
	EndIf;
	
	Settings = InitializedDefaultSettings(DataCompositionSchema);
	
	AddDimensionFields(DataCompositionSchema, Settings, Parameters);
	
	If Parameters.Property("CurrentLimits") Then
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "Scenario", "VALUE(Catalog.BudgetingScenarios.BudgetFulfillment)");
	Else
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "Scenario",
			"CASE WHEN Rule.RuleType = VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillment) THEN VALUE(Catalog.BudgetingScenarios.BudgetFulfillment) ELSE VALUE(Catalog.BudgetingScenarios.ActualData) END");
		FinancialReportingServer.NewFilter(Settings.Filter, "Scenario", Catalogs.BudgetingScenarios.ActualData);
	EndIf;
	AddGroupField(Settings, "Scenario");
	AddGroupField(Settings, "Rule");
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AnalyticsFieldByNumber = "Dimension" + DimensionNumber;
		AddGroupField(Settings, AnalyticsFieldByNumber);
	EndDo;
	
	If Parameters.AdditionalSelection <> Undefined Then
		DataCompositionClientServer.CopyDataCompositionFilter(
			DataCompositionSchema, Settings, Parameters.AdditionalSelection);
	EndIf;
	
	If Not Parameters.Property("CurrentLimits") Then
		
		ParameterStandardPeriod = Parameters.Period; // StandardPeriod -
		DataCompositionClientServer.SetParameter(Settings, "BeginOfPeriod", ParameterStandardPeriod.StartDate);
		DataCompositionClientServer.SetParameter(Settings, "EndOfPeriod", ParameterStandardPeriod.EndDate);
		
		If Parameters.Property("ExpressionStartOfPeriod") Then
			StartOfPeriodParameter = DataCompositionSchema.Parameters.Find("BeginOfPeriod");
			StartOfPeriodParameter.Expression = Parameters.ExpressionStartOfPeriod;
		EndIf;
		If Parameters.Property("ExpressionEndOfPeriod") Then
			EndOfPeriodParameter = DataCompositionSchema.Parameters.Find("EndOfPeriod");
			EndOfPeriodParameter.Expression = Parameters.ExpressionEndOfPeriod;
		EndIf;
		
		If Parameters.Periodicity <> Undefined Then
			
			FieldNamePeriod = FinancialReportingClientServer.PeriodStrings(Parameters.Periodicity).Period;
			ExpressionPeriod = FieldNamePeriod;
			
			If Parameters.Property("ExpressionOfGroupingPeriod") Then
				ExpressionPeriod = StrReplace(Parameters.ExpressionOfGroupingPeriod, "PLANNINGPERIOD", ExpressionPeriod);
			EndIf;
			
			FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "Period", ExpressionPeriod);
			AddGroupField(Settings, "Period");
			
		EndIf;
		
		If Parameters.Property("ThereIsPeriodicityOfSecond")
			And Parameters.ThereIsPeriodicityOfSecond Then
			
			FieldNamePeriod = "SecondPeriod";
			ExpressionPeriod = FieldNamePeriod;
			
			FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "SecondPeriod", ExpressionPeriod);
			AddGroupField(Settings, "SecondPeriod");
			
		EndIf;
		
	Else
		
		AddGroupField(Settings, "BeginOfPeriod");
		AddGroupField(Settings, "EndOfPeriod");
		
	EndIf;
	
	Resources = New Structure;
	
	If Parameters.Indicators.Property("Sum") Then
		
		If Parameters.Property("CurrentLimits") Then
			ExpressionOfAmountInCurrencyField = "AmountInCurrency";
		Else
			ExpressionOfAmountInCurrencyField = "CASE WHEN BudgetFlowItem.RecordByCurrency OR SumMan = 0 AND SumCompl = 0 THEN AmountInCurrency ELSE 0 END";
		EndIf;
		
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "StorageCurrency",
			"CASE WHEN " + ExpressionOfAmountInCurrencyField + " <> 0 THEN Currency ELSE UNDEFINED END");
		AddGroupField(Settings, "StorageCurrency");
		
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "RatePeriod", "DayPeriod");
		AddGroupField(Settings, "RatePeriod");
		
		Resources.Insert("AmountInStorageCurrency", ExpressionOfAmountInCurrencyField);
		
		If Parameters.FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_ Then
			ExpressionOfAmountFieldInFunctionalCurrency = "SumMan";
		ElsIf Parameters.FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal Then
			ExpressionOfAmountFieldInFunctionalCurrency = "SumCompl";
		Else
			ExpressionOfAmountFieldInFunctionalCurrency = "NULL";
		EndIf;
		
		Resources.Insert("AmountInFunctionalCurrency", ExpressionOfAmountFieldInFunctionalCurrency);
	EndIf;
	
	If Parameters.Indicators.Property("Count") Then
		Resources.Insert("Count", "Count");
	EndIf;
	
	For Each Resource In Resources Do
		FinancialReportingServer.NewCalculatedResource(DataCompositionSchema, Resource.Key, Resource.Value, "Sum");
		FinancialReportingServer.NewSelectionField(Settings, Resource.Key);
	EndDo;
	
	If Parameters.ByRegistrar Then
		AddGroupField(Settings, "Recorder");
	EndIf;
	
	DataCompositionClientServer.DisableOutputOfTotals(Settings);
	SetSelectionForFullnessOfIndicators(Settings, Parameters);
	
	ActualBudgetingData = FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings, ExternalDataSets);
	
	If ConvertToCurrency_ And Parameters.Indicators.Property("Sum") Then
		DataTableParameters = ParametersForConvertingDataTableToCurrency(ActualBudgetingData);
		ConvertDataTableToCurrency(DataTableParameters, Parameters.ReportCurrency, Parameters.FunctionalCurrency);
		ActualBudgetingData = DataTableParameters.DataTable;
	EndIf;
	
	Return ActualBudgetingData;
	
EndFunction

Procedure FactOfArticleOfBudgetsAccordingToRule(Rule, Parameters, FactTable_) Export
	
	DataCompositionSchema = DataSourcesServer.DataLayoutRules(
		Rule, CollectionsThatAreClearedWhenFactIsReceived(), Parameters.DataReceiptMode, True);
	
	ParametersNotCopied = NamesOfCommonParametersOfFactGettingRules();
	For Each LayoutParameter In DataCompositionSchema.Parameters Do
		If Not ParametersNotCopied.Find(LayoutParameter.Name) = Undefined Then
			LayoutParameter.Value = Undefined;
		ElsIf Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
			// User parameters should always be used, even if the use of Auto is in the SKD.
			LayoutParameter.Use = DataCompositionParameterUse.Always;
		EndIf;
	EndDo;
	
	RegulatedOrInternationalAccounting =
		Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting
		Or Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting;
		
	If RegulatedOrInternationalAccounting Then
		ExtDimensionTypes = FinancialReportingCached.AccountExtDimensionTypes(Rule.DataSource);
		TypesOfCorExtdimension = FinancialReportingCached.AccountExtDimensionTypes(Rule.CorDataSource);
		SetExtdimensionFieldProperties(DataCompositionSchema, ExtDimensionTypes, TypesOfCorExtdimension); 
	EndIf;
	
	SettingsComposer = Rule.SettingsComposer; // ValueStorage
	Filter_Settings = SettingsComposer.Get();
	Settings = InitializedDefaultSettings(DataCompositionSchema);
	DataSet = DataCompositionSchema.DataSets[0];
	
	AddDimensionFields(DataCompositionSchema, Settings, Parameters);
	
	DataSetScenarios = DataCompositionServer.AddEmptyDataSet(
		DataCompositionSchema,
		Type("DataCompositionSchemaDataSetQuery"),
		"SetScenarios");
	DataSetScenarios.Query =
	"SELECT
	|	VALUE(Enum.ActualBudgetingDataQueryRuleType.ActualData) AS RuleType,
	|	VALUE(Catalog.BudgetingScenarios.ActualData) AS Scenario
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillment) AS RuleType,
	|	VALUE(Catalog.BudgetingScenarios.BudgetFulfillment) AS Scenario
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData) AS RuleType,
	|	VALUE(Catalog.BudgetingScenarios.ActualData) AS Scenario
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData) AS RuleType,
	|	VALUE(Catalog.BudgetingScenarios.BudgetFulfillment) AS Scenario";
	FieldTitle = NStr("vi = 'Loại quy tắc';
						|ru = 'Тип правила';
						|en = 'Rule type'; fa = 'نوع قاعده';
						|it = 'Tipo di regola';
						|pl = 'Typ reguły';
						|tr = 'Kural türü'");
	FinancialReportingServer.NewSetField(
		DataSetScenarios,
		"RuleType",
		"RuleType",
		FieldTitle,
		New TypeDescription("EnumRef.ActualBudgetingDataQueryRuleType"));
	FieldTitle = NStr("vi = 'Kịch bản';
						|ru = 'Сценарий';
						|en = 'Scenario'; fa = 'سناریو';
						|it = 'Scenario';
						|pl = 'Scenariusz';
						|tr = 'Senaryo'");
	FinancialReportingServer.NewSetField(
		DataSetScenarios,
		"Scenario",
		"Scenario",
		FieldTitle,
		New TypeDescription("CatalogRef.BudgetingScenarios"));
	If Rule.RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData Then
		RuleTypeExpression = "VALUE(Enum.ActualBudgetingDataQueryRuleType.ActualData)";
	ElsIf Rule.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment Then
		RuleTypeExpression = "VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillment)";
	Else
		RuleTypeExpression = "VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData)";
	EndIf;
	FinancialReportingServer.NewConnection(
		DataCompositionSchema,
		DataSet.Name,
		DataSetScenarios.Name,
		RuleTypeExpression,
		"RuleType");
	
	AddGroupField(Settings, "Scenario");
	
	AddAnalyticsFields(DataCompositionSchema, Settings, Rule, Parameters);
	
	If Parameters.Indicators.Property("Sum") Then
		AddAmountsByBudgetItemField(DataCompositionSchema, Settings, Rule, Parameters)
	EndIf;
	
	If Parameters.Indicators.Property("Count") Then
		AddQuantityField(DataCompositionSchema, Settings, Rule);
	EndIf;
	
	ParameterStandardPeriod = Parameters.Period; // StandardPeriod -
	DataCompositionClientServer.SetParameter(Settings, "BeginOfPeriod", ParameterStandardPeriod.StartDate);
	DataCompositionClientServer.SetParameter(Settings, "EndOfPeriod", ParameterStandardPeriod.EndDate);
	If Rule.DataSourceSection <> Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		DataCompositionClientServer.SetParameter(Settings, "DataSource", Rule.DataSource);
	EndIf;
	If Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
		DataCompositionClientServer.SetParameter(Settings, "BusinessOperation", Rule.BusinessOperation);
	EndIf;
	
	If RegulatedOrInternationalAccounting And ValueIsFilled(Rule.CorDataSource) Then
		CorAccountParameter = DataCompositionSchema.Parameters.Find("BalancedAccount");
		CorAccountParameter.Value = Rule.CorDataSource;
		CorAccountParameter.Use = DataCompositionParameterUse.Always;
	EndIf;
	
	DataCompositionClientServer.CopyDataCompositionFilter(
		DataCompositionSchema, Settings, Filter_Settings);
	
	If Parameters.AdditionalSelection <> Undefined Then
		DataCompositionClientServer.CopyDataCompositionFilter(
			DataCompositionSchema, Settings, Parameters.AdditionalSelection);
	EndIf;
	
	If Parameters.Property("ExpressionStartOfPeriod") Then
		StartOfPeriodParameter = DataCompositionSchema.Parameters.Find("BeginOfPeriod");
		If StartOfPeriodParameter = Undefined Then
			StartOfPeriodParameter = DataCompositionSchema.Parameters.Add();
			StartOfPeriodParameter.Name = "BeginOfPeriod";
			StartOfPeriodParameter.ValueType = New TypeDescription("Date",,,,, New DateQualifiers(DateFractions.DateTime));
		EndIf;
		StartOfPeriodParameter.Expression = Parameters.ExpressionStartOfPeriod;
	EndIf;
	
	If Parameters.Property("ExpressionEndOfPeriod") Then
		EndOfPeriodParameter = DataCompositionSchema.Parameters.Find("EndOfPeriod");
		If EndOfPeriodParameter = Undefined Then
			EndOfPeriodParameter = DataCompositionSchema.Parameters.Add();
			EndOfPeriodParameter.Name = "EndOfPeriod";
			EndOfPeriodParameter.ValueType = New TypeDescription("Date",,,,, New DateQualifiers(DateFractions.DateTime));
		EndIf;
		EndOfPeriodParameter.Expression = Parameters.ExpressionEndOfPeriod;
	EndIf;
	
	If Parameters.Property("ActualDataLimit") Then
		AddParameter(DataCompositionSchema, "ActualDataLimit", Parameters.ActualDataLimit);
	EndIf;
	
	ParameterTurnoverForFlowAnalysis = DataCompositionSchema.Parameters.Find("TurnoverByExpenseDimension");
	If ParameterTurnoverForFlowAnalysis <> Undefined Then
		ParameterTurnoverForFlowAnalysis.Value = Rule.TurnoverByExpenseDimension;
		ParameterTurnoverForFlowAnalysis.Use = DataCompositionParameterUse.Always;
		Settings.DataParameters.SetParameterValue("TurnoverByExpenseDimension", Rule.TurnoverByExpenseDimension);
	EndIf;
	
	If Parameters.Periodicity <> Undefined Then
		
		FieldNamePeriod = FinancialReportingClientServer.PeriodStrings(Parameters.Periodicity).Period;
		ThereIsFieldOfNecessaryPeriodicity = (DataSet.Fields.Find(FieldNamePeriod) <> Undefined);
		ThereIsPeriodField = (DataSet.Fields.Find("Period") <> Undefined);
		If ThereIsFieldOfNecessaryPeriodicity Then
			ExpressionPeriod = FieldNamePeriod;
		ElsIf ThereIsPeriodField Then
			ExpressionPeriod = StringFunctionsClientServer.SubstituteParametersToString(
				"BEGINOFPERIOD(Period, ""%1"")", 
				FinancialReportingClientServerCached.PeriodicityByString(Parameters.Periodicity)); 
		Else
			ErrorText = NStr("vi = 'Trong sơ đồ nguồn dữ liệu không có trường kỳ.
										|Không thể nhận dữ liệu theo từng kỳ.';
										|ru = 'В схеме источника данных отсутствует поле периода.
										|Получение данных в разрезе периода невозможно.';
										|en = 'The period field is missing in the data source scheme.
										|Cannot receive data by the period.'; fa = 'The period field is missing in the data source scheme.
										|Cannot receive data by the period.';
										|it = 'Nello schema della sorgente dei dati manca il campo del periodo.
										|L''ottenimento dei dati nel segmento del periodo è impossibile.';
										|pl = 'W schemacie źródła danych nie ma pola okresu.
										|Pobieranie danych w przekroju okresu jest niemożliwe';
										|tr = 'Veri kaynak şemasında dönem alanı eksik.
										|Dönemler arası veri alımı mümkün değil.'");
			Raise ErrorText;
		EndIf;
		
		If Parameters.Property("ExpressionOfGroupingPeriod") Then
			ExpressionPeriod = StrReplace(Parameters.ExpressionOfGroupingPeriod, "PLANNINGPERIOD", ExpressionPeriod);
		EndIf;
		
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "Period", ExpressionPeriod);
		AddGroupField(Settings, "Period");
		
	EndIf;
	
	If Parameters.Property("ThereIsPeriodicityOfSecond")
		And Parameters.ThereIsPeriodicityOfSecond Then
		FieldNamePeriod = "SecondPeriod";
		ThereIsFieldOfNecessaryPeriodicity = (DataSet.Fields.Find(FieldNamePeriod) <> Undefined);
		ThereIsPeriodField = (DataSet.Fields.Find("Period") <> Undefined);
		If ThereIsFieldOfNecessaryPeriodicity Then
			ExpressionPeriod = FieldNamePeriod;
		ElsIf ThereIsPeriodField Then
			ExpressionPeriod = "Period";
		Else
			ErrorText = NStr("vi = 'Trong sơ đồ nguồn dữ liệu không có trường kỳ.
									|Không thể nhận dữ liệu theo từng kỳ.';
									|ru = 'В схеме источника данных отсутствует поле периода.
									|Получение данных в разрезе периода невозможно.';
									|en = 'The period field is missing in the data source scheme.
									|Cannot receive data by the period.'; fa = 'The period field is missing in the data source scheme.
									|Cannot receive data by the period.';
									|it = 'Nello schema della sorgente dei dati manca il campo del periodo.
									|L''ottenimento dei dati nel segmento del periodo è impossibile.';
									|pl = 'W schemacie źródła danych nie ma pola okresu.
									|Pobieranie danych w przekroju okresu jest niemożliwe';
									|tr = 'Veri kaynak şemasında dönem alanı eksik.
									|Dönemler arası veri alımı mümkün değil.'");
			Raise ErrorText;
		EndIf;
		
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "SecondPeriod", ExpressionPeriod);
		AddGroupField(Settings, "SecondPeriod");
	EndIf;
	
	If Parameters.ByRegistrar Then
		ThereIsFieldLogger = (DataSet.Fields.Find("Recorder") <> Undefined);
		If Not ThereIsFieldLogger Then
			ErrorText = NStr("vi = 'Trong sơ đồ nguồn dữ liệu không có trường nguồn ghi. 
										|Không thể nhận dữ liệu theo từng nguồn ghi.';
										|ru = 'В схеме источника данных отсутствует поле регистратора. 
										|Получение данных в разрезе регистратора невозможно.';
										|en = 'The recorder field is missing in the data source scheme.
										|Cannot receive data by the recorder.'; fa = 'The recorder field is missing in the data source scheme.
										|Cannot receive data by the recorder.';
										|it = 'Nello schema della sorgente dei dati manca il campo registratore. 
										|L''ottenimento dei dati nel segmento del registratore è impossibile.';
										|pl = 'W schemacie źródła danych nie ma pola rejestratora.
										|Pobieranie danych w przekroju rejestratora jest niemożliwe.';
										|tr = 'Veri kaynak şemasında kaydedici alanı eksik.
										|Kaydediciler arası veri alımı mümkün değil.'");
			Raise ErrorText;
		EndIf;
		
		AddGroupField(Settings, "Recorder");
		
	EndIf;
	
	AddSelectionFieldExpressions(DataCompositionSchema, Settings);
	
	DataCompositionClientServer.DisableOutputOfTotals(Settings);
	SetSelectionForFullnessOfIndicators(Settings, Parameters);
	
	ExternalDataSets = Undefined;
	If DataSet.Name = "CorrespondencesTable" Then
		ExternalDataSets = New Structure("CorrespondencesTable", Rule.CorrespondencesTable);
	EndIf;
	Try
		ResultOfRule = FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings,
			ExternalDataSets);
	Except
		TemplateText = NStr(
			"vi = 'Lỗi khi nhận dữ liệu thực tế theo dạng ngân sách %1 theo quy tắc %2 do nguyên nhân: %3';
			|ru = 'Ошибка при получении фактических данных по статье бюджета %1 по правилу %2 по причине: %3';
			|en = 'An error occurred when getting actual data by the %1 budget flow item according to the %2 rule. Reason: %3'; fa = 'An error occurred when getting actual data by the %1 budget flow item according to the %2 rule. Reason: %3';
			|it = 'Ошибка при получении фактических данных по статье бюджета %1 по правилу %2 по причине: %3';
			|pl = 'An error occurred when getting actual data by the %1 budget flow item according to the %2 rule. Reason: %3';
			|tr = '%3 sebebiyle %2 kuralı uyarınca %1 bütçe kalemine göre gerçek veri alımında hata'");
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Raise StrTemplate(TemplateText, Rule.BudgetFlowItem, Rule.Rule, Chars.LF + ErrorText);
	EndTry;
	
	For Each ResultRow In ResultOfRule Do
		
		NewRow = AddRowToDataTable(FactTable_, ResultRow, Rule);
		
		If Parameters.Indicators.Property("Sum") Then
			If (Not ValueIsFilled(NewRow.StorageCurrency) Or Not ValueIsFilled(
				NewRow.AmountInStorageCurrency)) And ValueIsFilled(NewRow.CurrencyFunctional) Then
				NewRow.StorageCurrency = NewRow.CurrencyFunctional;
				NewRow.AmountInStorageCurrency = NewRow.AmountInFunctionalCurrency;
			EndIf;
			If ValueIsFilled(NewRow.AmountInStorageCurrency) Then
				NewRow.AmountInStorageCurrency = NewRow.AmountInStorageCurrency * Rule.ZoomRatio;
			EndIf;
			If ValueIsFilled(NewRow.AmountInFunctionalCurrency) Then
				NewRow.AmountInFunctionalCurrency = NewRow.AmountInFunctionalCurrency * Rule.ZoomRatio;
			EndIf;
			If Parameters.ReturnManAndLocalAmounts Then
				NewRow.SumMan = NewRow.SumMan * Rule.ZoomRatio;
				NewRow.SumCompl = NewRow.SumCompl * Rule.ZoomRatio;
			EndIf;
		EndIf;
		
		If Parameters.Indicators.Property("Count") Then
			NewRow.Count = NewRow.Count * Rule.ZoomRatio;
		EndIf;
	EndDo;
	
EndProcedure

Procedure FactThatBudgetsAreCalculatedAccordingToRule(Rule, Parameters, FactTable_, Val RedefinedDCS = Undefined)
	
	If RedefinedDCS = Undefined Then
		DataCompositionSchema = DataSourcesServer.DataLayoutRules(Rule,
			CollectionsThatAreClearedWhenFactIsReceived(), Parameters.DataReceiptMode, True);
		
		ParametersNotCopied = NamesOfCommonParametersOfFactGettingRules();
		For Each LayoutParameter In DataCompositionSchema.Parameters Do
			If Not ParametersNotCopied.Find(LayoutParameter.Name) = Undefined Then
				LayoutParameter.Value = Undefined;
			ElsIf Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
				// User parameters should always be used, even if the use of Auto is in the SKD.
				LayoutParameter.Use = DataCompositionParameterUse.Always;
			EndIf;
		EndDo;
	Else
		DataCompositionSchema = RedefinedDCS;
	EndIf;
	
	If Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting
		 Or Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting Then
		ExtDimensionTypes = FinancialReportingCached.AccountExtDimensionTypes(Rule.DataSource); 
		SetExtdimensionFieldProperties(DataCompositionSchema, ExtDimensionTypes); 
	EndIf;

	AddParameter(DataCompositionSchema, "Period");
	AddParameter(DataCompositionSchema, "PeriodLimit");
	AddParameter(DataCompositionSchema, "RatePeriod");
	AddParameter(DataCompositionSchema, "BeginOfPeriod");
	
	SettingsComposer = Rule.SettingsComposer; // ValueStorage
	Filter_Settings = SettingsComposer.Get();
	Settings = InitializedDefaultSettings(DataCompositionSchema);
	DataSet = DataCompositionSchema.DataSets[0];
	
	AddDimensionFields(DataCompositionSchema, Settings, Parameters);
	AddAnalyticsFields(DataCompositionSchema, Settings, Rule, Parameters);
	
	If Parameters.Indicators.Property("Sum") Then
		AddAmountsByBudgetIndicatorField(DataCompositionSchema, Settings, Rule, Parameters);
	EndIf;
	
	If Parameters.Indicators.Property("Count") Then
		AddQuantityField(DataCompositionSchema, Settings, Rule);
	EndIf;
	
	// Initialize the parameter so that it appears in the layout of the data layout
	DataCompositionClientServer.SetParameter(Settings, "AssetAndLiabilityItem", Rule.DataSource);
	DataCompositionClientServer.SetParameter(Settings, "DataSource", Rule.DataSource);
	
	DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema, Settings, Filter_Settings);
	If Parameters.AdditionalSelection <> Undefined Then
		DataCompositionClientServer.CopyDataCompositionFilter(
			DataCompositionSchema, Settings, Parameters.AdditionalSelection);
	EndIf;
	
	UseStartDate = Parameters.BalancesOnlyAtBeginningOfPeriod And 
								Not Rule.IndicatorType = Enums.BudgetBalanceItemType.SpecialPurpose;
	If Parameters.Property("ExpressionStartOfPeriod") Then
		PeriodParameter = DataCompositionSchema.Parameters.Find("Period");
		PeriodParameter.Expression = StrReplace(Parameters.ExpressionStartOfPeriod, "&" + "BEGINOFPERIOD", "&PERIOD");
		
		PeriodParameter = DataCompositionSchema.Parameters.Find("PeriodLimit");
		If UseStartDate Then
			PeriodParameter.Expression = StrReplace(Parameters.ExpressionStartOfPeriod, "&" + "BEGINOFPERIOD", "&PERIOD");
		Else
			PeriodParameter.Expression = "DataCompositionServer.PeriodBoundary(" + StrReplace(Parameters.ExpressionStartOfPeriod, "&" + "BEGINOFPERIOD", "&PERIOD") + ", ""Including"")";
		EndIf;
	EndIf;
	If Parameters.Property("ActualDataLimit") Then
		AddParameter(DataCompositionSchema, "ActualDataLimit", Parameters.ActualDataLimit);
	EndIf;
	
	If ValueIsFilled(Parameters.Periodicity) Then
		
		PeriodExpression = StringFunctionsClientServer.SubstituteParametersToString(
			"BEGINOFPERIOD(&RatePeriod, ""%1"")",
			FinancialReportingClientServerCached.PeriodicityByString(Parameters.Periodicity));
			
		If Rule.IndicatorType = Enums.BudgetBalanceItemType.Estimated_ Then
			CompoundExpression = PeriodExpression;
		Else
			CompoundExpression = StringFunctionsClientServer.SubstituteParametersToString(
				"ENDOFPERIOD(&RatePeriod, ""%1"")",
				FinancialReportingClientServerCached.PeriodicityByString(Parameters.Periodicity));
		EndIf;
		
		If Parameters.Property("ExpressionOfGroupingPeriod") Then
			PeriodExpression = StrReplace(Parameters.ExpressionOfGroupingPeriod, "PLANNINGPERIOD", CompoundExpression);
		EndIf;
		
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "Period", PeriodExpression);
		AddGroupField(Settings, "Period");
	EndIf;
	
	If Parameters.Property("ThereIsPeriodicityOfSecond")
		And Parameters.ThereIsPeriodicityOfSecond Then
		PeriodExpression = "&RatePeriod";
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "SecondPeriod", PeriodExpression);
		AddGroupField(Settings, "SecondPeriod");
	EndIf;
	
	DataSetScenarios = DataCompositionServer.AddEmptyDataSet(
		DataCompositionSchema,
		Type("DataCompositionSchemaDataSetQuery"),
		"SetScenarios");
	DataSetScenarios.Query =
	"SELECT
	|	VALUE(Enum.ActualBudgetingDataQueryRuleType.ActualData) AS RuleType,
	|	VALUE(Catalog.BudgetingScenarios.ActualData) AS Scenario
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillment) AS RuleType,
	|	VALUE(Catalog.BudgetingScenarios.BudgetFulfillment) AS Scenario
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData) AS
	|		RuleType,
	|	VALUE(Catalog.BudgetingScenarios.ActualData) AS Scenario
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData) AS
	|		RuleType,
	|	VALUE(Catalog.BudgetingScenarios.BudgetFulfillment) AS Scenario";
	FieldTitle = NStr("vi = 'Loại quy tắc';
						|ru = 'Тип правила';
						|en = 'Rule type'; fa = 'نوع قاعده';
						|it = 'Tipo di regola';
						|pl = 'Typ reguły';
						|tr = 'Kural türü'");
	FinancialReportingServer.NewSetField(
		DataSetScenarios,
		"RuleType",
		"RuleType",
		FieldTitle,
		New TypeDescription("EnumRef.ActualBudgetingDataQueryRuleType"));
	FieldTitle = NStr("vi = 'Kịch bản';
						|ru = 'Сценарий';
						|en = 'Scenario'; fa = 'سناریو';
						|it = 'Scenario';
						|pl = 'Scenariusz';
						|tr = 'Senaryo'");
	FinancialReportingServer.NewSetField(
		DataSetScenarios,
		"Scenario",
		"Scenario",
		FieldTitle,
		New TypeDescription("CatalogRef.BudgetingScenarios"));
	If Rule.RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData Then
		RuleTypeExpression = "VALUE(Enum.ActualBudgetingDataQueryRuleType.ActualData)";
	ElsIf Rule.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment Then
		RuleTypeExpression = "VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillment)";
	Else
		RuleTypeExpression = "VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData)";
	EndIf;
	FinancialReportingServer.NewConnection(
		DataCompositionSchema,
		DataSet.Name,
		DataSetScenarios.Name,
		RuleTypeExpression,
		"RuleType");
	AddGroupField(Settings, "Scenario");
	
	AddSelectionFieldExpressions(DataCompositionSchema, Settings);
	
	DataCompositionClientServer.DisableOutputOfTotals(Settings);
	SetSelectionForFullnessOfIndicators(Settings, Parameters);
	
	For Each StringPeriod In Parameters.PeriodsTable Do
		Period = ?(UseStartDate, StringPeriod.StartDate, StringPeriod.EndDate);
		FinancialReportingServer.SetParameter(Settings.DataParameters, "Period", Period, True);
		
		PeriodLimit = ?(UseStartDate, StringPeriod.StartDate, New Boundary(Period, BoundaryType.Including));
		FinancialReportingServer.SetParameter(Settings.DataParameters, "PeriodLimit", PeriodLimit, True);
		
		FinancialReportingServer.SetParameter(Settings.DataParameters, "RatePeriod", Period, True);
		FinancialReportingServer.SetParameter(Settings.DataParameters, "BeginOfPeriod", Parameters.Period.StartDate, True);
		
		ResultOfRule = FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings);
		For Each ResultRow In ResultOfRule Do
			NewRow = AddRowToDataTable(FactTable_, ResultRow, Rule);
			If Parameters.Indicators.Property("Sum") Then
				If Parameters.ReturnManAndLocalAmounts
					And Not ValueIsFilled(NewRow.AmountInFunctionalCurrency) And ValueIsFilled(NewRow.SumMan)
					And NewRow.CurrencyFunctional = Parameters.CurrencyOfMan Then
					NewRow.AmountInFunctionalCurrency = NewRow.SumMan;
				EndIf;
				If (Not ValueIsFilled(NewRow.StorageCurrency) Or Not ValueIsFilled(
					NewRow.AmountInStorageCurrency)) And ValueIsFilled(NewRow.CurrencyFunctional) Then
					NewRow.StorageCurrency = NewRow.CurrencyFunctional;
					NewRow.AmountInStorageCurrency = NewRow.AmountInFunctionalCurrency;
				EndIf;
				If ValueIsFilled(NewRow.AmountInStorageCurrency) Then
					NewRow.AmountInStorageCurrency = NewRow.AmountInStorageCurrency * Rule.ZoomRatio;
				EndIf;
				If ValueIsFilled(NewRow.AmountInFunctionalCurrency) Then
					NewRow.AmountInFunctionalCurrency = NewRow.AmountInFunctionalCurrency * Rule.ZoomRatio;
				EndIf;
			EndIf;
			If Parameters.Indicators.Property("Count") Then
				NewRow.Count = NewRow.Count * Rule.ZoomRatio;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure NonFinancialIndicatorValuesAccordingToRule(Rule, Parameters, ValueTable) Export
	
	DataCompositionSchema = Rule.DataAcquisitionScheme;
	NFPEntryTemplate = Undefined;
	Parameters.Property("NFPEntryTemplate", NFPEntryTemplate);
	
	If DataCompositionSchema = Undefined Then
		If Not ValueIsFilled(NFPEntryTemplate) Then
			MessageTemplate = NStr("vi = 'Lược đồ thành phần dữ liệu không được xác định cho chỉ số phi tài chính ""%1""';
									|ru = 'Не определена схема компоновки данных для нефинансового показателя ""%1""';
									|en = 'Data composition schema is not identified for the ""%1"" non-financial item'; fa = 'Data composition schema is not identified for the ""%1"" non-financial item';
									|it = 'Non è identificato lo schema del layout dei dati per l''indicatore non finanziario ""%1""';
									|pl = 'Nie określono schematu układu danych dla wskaźnika niefinansowego ""%1""';
									|tr = '""%1"" finansal olmayan öğesi için Veri Oluşturma Sistemi belirtilmemiş'");
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate, Rule.NonFinancialItem);
		Else
			MessageTemplate = NStr("vi = 'Lược đồ thành phần dữ liệu không được xác định trong mẫu nhập các chỉ số phi tài chính ""%1"" cho chỉ báo phi tài chính ""%2""';
									|ru = 'Не определена схема компоновки данных в шаблоне ввода нефинансовых показателей ""%1"" для нефинансового показателя ""%2""';
									|en = 'The data composition schema is not defined in the non-financial item profile ""%1"" for non-financial item ""%2""'; fa = 'The data composition schema is not defined in the non-financial item profile ""%1"" for non-financial item ""%2""';
									|it = 'Non è stato definito lo schema di configurazione dati nel modello di inserimento di indici non finanziari ""%1"" per indice non finanziario ""%2""';
									|pl = 'Nie określono schematu układu danych w szablonie wprowadzenia wskaźników niefinansowych ""%1"" dla wskaźnika niefinansowego ""%2""';
									|tr = '""%1"" finansal olmayan öğesinin giriş şablonunda ""%2"" finansal olmayan öğesi için Veri Oluşturma Sistemi belirtilmemiş'");
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate, NFPEntryTemplate, Rule.NonFinancialItem);
		EndIf;
		Raise MessageTemplate;
	EndIf;
	
	If Not DataCompositionSchema.DataSets.Count() Then
		If Not ValueIsFilled(NFPEntryTemplate) Then
			MessageTemplate = NStr("vi = 'Thiếu tập dữ liệu trong sơ đồ điền đối với chỉ số phi tài chính ""%1""';
									|ru = 'Отсутствует набор данных в схеме заполнения для нефинансового показателя ""%1""';
									|en = 'No data set in the population scheme for non-financial item ""%1""'; fa = 'No data set in the population scheme for non-financial item ""%1""';
									|it = 'Manca l''insieme dei dati nello schema di compilazione per l''indice non finanziario ""%1""';
									|pl = 'Brak zestawu danych w schemacie wypełnienia dla wskaźnika niefinansowego ""%1""';
									|tr = '""%1"" finansal olmayan öğesi için doldurma şemasında veri kümesi eksik'");
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Rule.NonFinancialItem);
		Else
			MessageTemplate = NStr("vi = 'Không có tập dữ liệu trong sơ đồ điền khuôn mẫu nhập các chỉ số phi tài chính ""%1"" cho chỉ số phi tài chính ""%2""';
									|ru = 'Отсутствует набор данных в схеме заполнения шаблона ввода нефинансовых показателей ""%1"" для нефинансового показателя ""%2""';
									|en = 'No data set in the template population schema of non-financial item profile ""%1"" for non-financial item ""%2""'; fa = 'No data set in the template population schema of non-financial item profile ""%1"" for non-financial item ""%2""';
									|it = 'Manca l''insieme dei dati nello schema di compilazione del modello per l''inserimento degli indici non finanziari ""%1"" per l''indice non finanziario ""%2""';
									|pl = 'Brak zestawu danych w schemacie wypełnienia szablonu wprowadzenia wskaźników niefinansowych ""%1"" dla wskaźnika niefinansowego ""%2""';
									|tr = '""%1"" finansal olmayan öğesindeki ""%2"" finansal olmayan öğesine giriş için doldurma şemasında veri kümesi eksik'");
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, NFPEntryTemplate, Rule.NonFinancialItem);
		EndIf;
		Raise MessageTemplate;
	EndIf;
	
	SetFields = DataCompositionSchema.DataSets[0].Fields;
	
	If SetFields.Find("IndicatorValue") = Undefined Then
		FieldNameInCodeLanguage = "IndicatorValue";
		If Not ValueIsFilled(NFPEntryTemplate) Then
			MessageTemplate = NStr("vi = 'Không có trường nào có tên ""%2"" trong sơ đồ thành phần dữ liệu của chỉ báo phi tài chính ""%1""';
									|ru = 'В схеме компоновки данных нефинансового показателя ""%1"" отсутствует поле с именем ""%2""';
									|en = 'The ""%2"" field is missing in the data composition schema of the ""%1"" non-financial item.'; fa = 'The ""%2"" field is missing in the data composition schema of the ""%1"" non-financial item.';
									|it = 'Nello schema di layout dei dati per l''indicatore non finanziario ""%1"" manca il campo ""ValoreIndicatore""%2';
									|pl = 'W schemacie układu danych wskaźnika niefinansowego ""%1"" nie ma pola o nazwie ""%2""';
									|tr = 'Veri Oluşturma Sistemi''nde ""%1"" finansal olmayan öğesinde ""%2"" isimli alan eksik'");
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
				Rule.NonFinancialItem,
				FieldNameInCodeLanguage);
		Else
			MessageTemplate = NStr("vi = 'Trong sơ đồ dàn dựng dữ liệu của khuôn mẫu nhập các chỉ tiêu tài chính ""%1"" cho chỉ báo phi tài chính ""%2"", không có trường nào có tên ""%3""';
									|ru = 'В схеме компоновки данных шаблона ввода нефинансовых показателей ""%1"" для нефинансового показателя ""%2"" отсутствует поле с именем ""%3""';
									|en = 'There is no field with the name ""%3"" in the data composition schema of the non-financial item profile ""%1"" for non-financial item ""%2""'; fa = 'There is no field with the name ""%3"" in the data composition schema of the non-financial item profile ""%1"" for non-financial item ""%2""';
									|it = 'Nello schema di configurazione dei dati del modelo per l''inserimento degli indici non finanziari ""%1"" per l''indice non finanziario ""%2"" manca campo con il nome ""%3""';
									|pl = 'W schemacie układu danych szablonu wprowadzenia wskaźników niefinansowych ""%1"" dla wskaźnika niefinansowego ""%2"" brak pola o nazwie ""%3""';
									|tr = 'Veri Oluşturma Sistemi''nde ""%2"" finansal olmayan öğesi için ""%1"" finansal olmayan öğesinin girişinde ""%3"" isimli alan eksik'");
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
				NFPEntryTemplate,
				Rule.NonFinancialItem,
				FieldNameInCodeLanguage);
		EndIf;
		Raise MessageTemplate;
	EndIf;
	
	If SetFields.Find("Period") = Undefined Then
		FieldNameInCodeLanguage = "Period";
		If Not ValueIsFilled(NFPEntryTemplate) Then
			MessageTemplate = NStr("vi = 'Không có trường nào có tên ""%2"" trong sơ đồ thành phần dữ liệu của chỉ báo phi tài chính ""%1""';
									|ru = 'В схеме компоновки данных нефинансового показателя ""%1"" отсутствует поле с именем ""%2""';
									|en = 'The ""%2"" field is missing in the data composition schema of the ""%1"" non-financial item.'; fa = 'The ""%2"" field is missing in the data composition schema of the ""%1"" non-financial item.';
									|it = 'Nello schema di layout dei dati per l''indicatore non finanziario ""%1"" manca il campo ""ValoreIndicatore""%2';
									|pl = 'W schemacie układu danych wskaźnika niefinansowego ""%1"" nie ma pola o nazwie ""%2""';
									|tr = 'Veri Oluşturma Sistemi''nde ""%1"" finansal olmayan öğesinde ""%2"" isimli alan eksik'");
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
				Rule.NonFinancialItem,
				FieldNameInCodeLanguage);
		Else
			MessageTemplate = NStr("vi = 'Trong sơ đồ dàn dựng dữ liệu của khuôn mẫu nhập các chỉ tiêu phi tài chính ""%1"" cho chỉ báo phi tài chính ""%2"", không có trường nào có tên ""%3""';
									|ru = 'В схеме компоновки данных шаблона ввода нефинансовых показатей ""%1"" для нефинансового показателя ""%2"" отсутствует поле с именем ""%3""';
									|en = 'There is no field with the name ""%3"" in the data composition schema of the input template for non-financial items ""%1"" for non-financial item ""%2""'; fa = 'There is no field with the name ""%3"" in the data composition schema of the input template for non-financial items ""%1"" for non-financial item ""%2""';
									|it = 'Nello schema di configurazione dei dati del modelo per l''inserimento degli indici non finanziari ""%1"" per l''indice non finanziario ""%2"" manca campo con il nome ""%3""';
									|pl = 'W schemacie układu danych szablonu wprowadzenia wskaźników niefinansowych ""%1"" dla wskaźnika niefinansowego ""%2"" brak pola o nazwie ""%3""';
									|tr = 'Veri Oluşturma Sistemi''nde ""%2"" finansal olmayan öğesindeki ""%1"" finansal olmayan öğesinin şablon girişi için ""%3"" isimli alan eksik'");
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
				NFPEntryTemplate,
				Rule.NonFinancialItem,
				FieldNameInCodeLanguage);
		EndIf;
		Raise MessageTemplate;
	EndIf;
	
	If Rule.CurrencyFilling = "DeterminedByDataSource" And SetFields.Find("Currency") = Undefined Then
		FieldNameInCodeLanguage = "Currency";
		If Not ValueIsFilled(NFPEntryTemplate) Then
			MessageTemplate = NStr("vi = 'Không có trường nào có tên ""%2"" trong sơ đồ thành phần dữ liệu của chỉ báo phi tài chính ""%1""';
									|ru = 'В схеме компоновки данных нефинансового показателя ""%1"" отсутствует поле с именем ""%2""';
									|en = 'The ""%2"" field is missing in the data composition schema of the ""%1"" non-financial item.'; fa = 'The ""%2"" field is missing in the data composition schema of the ""%1"" non-financial item.';
									|it = 'Nello schema di layout dei dati per l''indicatore non finanziario ""%1"" manca il campo ""ValoreIndicatore""%2';
									|pl = 'W schemacie układu danych wskaźnika niefinansowego ""%1"" nie ma pola o nazwie ""%2""';
									|tr = 'Veri Oluşturma Sistemi''nde ""%1"" finansal olmayan öğesinde ""%2"" isimli alan eksik'");
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
				Rule.NonFinancialItem,
				FieldNameInCodeLanguage);
		Else
			MessageTemplate = NStr("vi = 'Trong sơ đồ dàn dựng dữ liệu của khuôn mẫu nhập các chỉ tiêu tài chính ""%1"" cho chỉ báo phi tài chính ""%2"", không có trường nào có tên ""%3""';
									|ru = 'В схеме компоновки данных шаблона ввода нефинансовых показателей ""%1"" для нефинансового показателя ""%2"" отсутствует поле с именем ""%3""';
									|en = 'There is no field with the name ""%3"" in the data composition schema of the non-financial item profile ""%1"" for non-financial item ""%2""'; fa = 'There is no field with the name ""%3"" in the data composition schema of the non-financial item profile ""%1"" for non-financial item ""%2""';
									|it = 'Nello schema di configurazione dei dati del modelo per l''inserimento degli indici non finanziari ""%1"" per l''indice non finanziario ""%2"" manca campo con il nome ""%3""';
									|pl = 'W schemacie układu danych szablonu wprowadzenia wskaźników niefinansowych ""%1"" dla wskaźnika niefinansowego ""%2"" brak pola o nazwie ""%3""';
									|tr = 'Veri Oluşturma Sistemi''nde ""%2"" finansal olmayan öğesi için ""%1"" finansal olmayan öğesinin girişinde ""%3"" isimli alan eksik'");
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
				NFPEntryTemplate,
				Rule.NonFinancialItem,
				FieldNameInCodeLanguage);
		EndIf;
		Raise MessageTemplate;
	EndIf;
	
	Settings = New DataCompositionSettings;
	If Rule.DataAcquisitionSchemeSettings <> Undefined Then
		DataCompositionClientServer.CopyDataLayoutSettings(Settings, Rule.DataAcquisitionSchemeSettings); 
	EndIf;
	
	AddAnalyticsFields(DataCompositionSchema, Settings, Rule, Parameters);
	
	AddGroupField(Settings, "IndicatorValue");
	
	If Rule.ByCompanies 
		And SetFields.Find("Organization") <> Undefined Then
		AddGroupField(Settings, "Organization");
	EndIf;
	
	If Rule.ByBusinessUnits 
		And SetFields.Find("Department") <> Undefined Then
		AddGroupField(Settings, "Department");
	EndIf;
	
	AddParameter(DataCompositionSchema, "Period");
	If Parameters.Property("ActualDataLimit") Then
		AddParameter(DataCompositionSchema, "ActualDataLimit", Parameters.ActualDataLimit);
	EndIf;
	AddGroupField(Settings, "Period");
	
	If Parameters.Property("AdditionalSelection") And Parameters.AdditionalSelection <> Undefined Then
		DataCompositionClientServer.CopyDataCompositionFilter(
			DataCompositionSchema, Settings, Parameters.AdditionalSelection);
	EndIf;
	
	If Not Rule.ByScenarios Then
		FilterElement = FinancialReportingServer.FindSelectionElement(Settings.Filter, "Scenario");
		If FilterElement <> Undefined Then
			FilterElement.Use = False;
		EndIf;
	EndIf;
	
	If Rule.ByPeriods And SetFields.Find("SubperiodNumber") <> Undefined Then
		ExpressionOfCalculatedField = StringFunctionsClientServer.SubstituteParametersToString(
			"WorkingWithClientServerPeriods.AddInterval(
			|	BEGINOFPERIOD(Period, ""%1""),
			|	&SubperiodFrequency,
			|	CASE WHEN ValueIsFilled(SubperiodNumber) THEN SubperiodNumber - 1 ELSE 0 END, 
			|	&Cache)",
			FinancialReportingClientServerCached.PeriodicityByString(Rule.Periodicity));
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, 
			"InstallationPeriod",
			ExpressionOfCalculatedField);
		AddParameter(DataCompositionSchema, "Cache", New Map);
		AddParameter(DataCompositionSchema, "SubperiodFrequency", Rule.SubperiodFrequency);
	Else
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, 
			"InstallationPeriod", 
			"InstallationPeriod");
	EndIf;
	AddGroupField(Settings, "InstallationPeriod");
	
	If SetFields.Find("Recorder") <> Undefined Then
		AddGroupField(Settings, "Recorder");
	EndIf;
	
	If Rule.ByScenarios Then
		If SetFields.Find("Scenario") = Undefined Then
			FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "Scenario", "&ActualData");
			AddParameter(DataCompositionSchema, "ActualData", Catalogs.BudgetingScenarios.ActualData);
		EndIf;
		AddGroupField(Settings, "Scenario");
	EndIf;
	
	If Rule.ByPeriods And (SetFields.Find("SubperiodNumber") <> Undefined Or Parameters.Property("SubperiodsTable")) Then
		AddGroupField(Settings, "SubperiodNumber");
	EndIf;
	
	If Rule.ByPeriods And ValueIsFilled(Parameters.Periodicity) Then
		ExpressionOfCalculatedField = StringFunctionsClientServer.SubstituteParametersToString(
			"EndOfPeriod(Period, ""%1"")",
			FinancialReportingClientServerCached.PeriodicityByString(Parameters.Periodicity));
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema,
			"GroupingPeriodEnd",
			ExpressionOfCalculatedField);
		FinancialReportingServer.NewFilter(Settings.Structure[0].Filter, "InstallationPeriod", New DataCompositionField("Period"), ,DataCompositionComparisonType.GreaterOrEqual);
		FinancialReportingServer.NewFilter(Settings.Structure[0].Filter, "InstallationPeriod", New DataCompositionField("GroupingPeriodEnd"), ,DataCompositionComparisonType.LessOrEqual);
		AddGroupField(Settings, "GroupingPeriodEnd");
	EndIf;
	
	DataCompositionClientServer.DisableOutputOfTotals(Settings);
	
	ExternalSets = AddSetOfNonFinancialIndicatorPeriods(DataCompositionSchema, Parameters, Rule);
	
	FinancialReportingServer.NewFilter(Settings.Filter, "IndicatorValue",,, DataCompositionComparisonType.Filled);
	
	ResultOfRule = FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings, ExternalSets);
	
	For Each ResultRow In ResultOfRule Do
		AddRowToDataTable(ValueTable, ResultRow, Rule);
	EndDo;
	
EndProcedure

Function RuleForObtainingNonFinancialIndicatorValues(References_0, DataAcquisitionScheme, DataAcquisitionSchemeSettings = Undefined) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	Rule = New Structure();
	Rule.Insert("NonFinancialItem");
	Rule.Insert("ByCompanies");
	Rule.Insert("ByBusinessUnits");
	Rule.Insert("ByScenarios");
	Rule.Insert("ByPeriods");
	Rule.Insert("SetAValueForEachPeriod");
	Rule.Insert("Periodicity");
	Rule.Insert("SubperiodFrequency");
	Rule.Insert("NumberOfUsedDimensions");
	
	Rule.Insert("AdvancedModeOfDimensionFillSetting");
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		Rule.Insert("DimensionKind" + DimensionNumber);
		Rule.Insert("DimensionPopulationExpression" + DimensionNumber);
		Rule.Insert("FillInAnalyticsWithSpecifiedValue" + DimensionNumber);
		Rule.Insert("DimensionValue" + DimensionNumber);
	EndDo;
	
	FillPropertyValues(Rule, References_0);
	
	Rule.Insert("DataSourceSection", Enums.SectionsOfBudgetingDataSources.CustomQuery);
	Rule.Insert("DataAcquisitionScheme", DataAcquisitionScheme);
	Rule.Insert("DataAcquisitionSchemeSettings", DataAcquisitionSchemeSettings);
	
	Rule.Insert("IndicatorKind", References_0.IndicatorKind);
	
	Indicator_Monetary = (References_0.IndicatorKind = Enums.NonFinancialItemKinds.Cash_);
	If Not Indicator_Monetary Then
		Rule.Insert("CurrencyFilling", "DontFill");
	ElsIf References_0.CurrencyIsDeterminedByDimension Then
		Rule.Insert("CurrencyFilling", "DeterminedByAnalytics");
		Rule.Insert("DimensionAddressCurrency", References_0.DimensionAddressCurrency);
		Rule.Insert("DimensionCurrencyField", References_0.DimensionCurrencyField);
	Else 
		Rule.Insert("CurrencyFilling", "DeterminedByDataSource");
	EndIf;
	
	QuantitativeIndicator = (References_0.IndicatorKind = Enums.NonFinancialItemKinds.Quantitative);
	If Not QuantitativeIndicator Then
		Rule.Insert("UnitOfMeasureFilling", "DontFill");
	ElsIf References_0.UnitOfMeasureIsDeterminedByDimension Then
		Rule.Insert("UnitOfMeasureFilling", "DeterminedByAnalytics");
		Rule.Insert("DimensionAddressUnitOfMeasure", References_0.QuantityDimensionAddress);
		Rule.Insert("FieldOfDimensionUnitOfMeasure", References_0.FieldOfDimensionUnitOfMeasure);
	Else
		Rule.Insert("UnitOfMeasureFilling", "FixedValue");
		Rule.Insert("UnitOfMeasure", References_0.UnitOfMeasure);
	EndIf;
	
	Return Rule;
	
EndFunction

Function ParametersForConvertingDataTableToCurrency(DataTable = Undefined) Export
	
	DataTableParameters = New Structure;
	DataTableParameters.Insert("DataTable", DataTable);
	DataTableParameters.Insert("ColumnsOfDataTable_", New Structure);
	DataTableParameters.Insert("TempTablesManager");
	DataTableParameters.Insert("TempTableName", "DataTable");
	DataTableParameters.Insert("IndexFields", "");
	
	Return DataTableParameters;
	
EndFunction

// Recalculates the resource amount fields of the fact table into the report currency.
//
// Parameters:
//  DataTableParameters - Structure - the structure of the fact table parameters:
//   *TempTablesManager - TempTablesManager - if the fact table is passed or returned as a temporary table
//   						- Undefined - if the fact table is passed and returned as a table of values
//   *TempTableName - String - name of the passing and/or returning temporary fact table
//   *DataTable - ValueTable - Table of actual data
//  ReportCurrency - CatalogRef.Currencies - The currency to be converted to
//  FunctionalCurrency - EnumRef.AccountingKindsInFunctionalCurrency - Functional currency, the amounts in which are used for recalculation
//  RecalculationFields - Array of Structure - Names of the summary fields of the table: Half-account, half-functional currency, field output data (optional)
//  ScriptCourseData - Structure:
//   *ActualDataLimit - Date -
//   *ScenarioCourseTable - ValueTable -
//
Procedure ConvertDataTableToCurrency(DataTableParameters, ReportCurrency, FunctionalCurrency,
	RecalculationFields = Undefined, ScriptCourseData = Undefined) Export
	
	If DataTableParameters.TempTablesManager <> Undefined Then
		ErrorText = "";
		If IsBlankString(DataTableParameters.TempTableName) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang truyền bộ quản lý bảng tạm vào thủ tục %1 trong tham số %2 mà không chỉ định tên bảng tạm:
				|%3';
				|ru = 'В процедуру %1 в параметре %2 передается менеджер временных таблиц без указания имени временной таблицы:
				|%3';
				|en = 'In the %1 procedure, the temporary table manager is passed in the %2 parameter without specifying the temporary table name:
				|%3'; fa = 'In the %1 procedure, the temporary table manager is passed in the %2 parameter without specifying the temporary table name:
				|%3';
				|it = 'In the %1 procedure, the temporary table manager is passed in the %2 parameter without specifying the temporary table name:
				|%3';
				|pl = 'In the %1 procedure, the temporary table manager is passed in the %2 parameter without specifying the temporary table name:
				|%3';
				|tr = '%1 prosedürüne, %2 parametresi içinde geçici tablo adı belirtilmeksizin geçici tablo yöneticisi aktarılıyor: 
				|%3'"), "BudgetingServer.ConvertDataTableToCurrency", "DataTableParameters", 
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		ElsIf TypeOf(DataTableParameters.DataTable) = Type("ValueTable")
			And DataTableParameters.TempTablesManager.Tables.Find(DataTableParameters.TempTableName) <> Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang truyền bảng dữ liệu, bộ quản lý bảng tạm vào thủ tục %1 trong tham số %2 có sẵn bảng tạm đã được chỉ định:
				|%3';
				|ru = 'В процедуру %1 в параметре %2 передаются таблица данных менеджер временных таблиц с наличием указанной временной таблицы:
				|%3';
				|en = 'In the %1 procedure, the data table of the temporary table manager is passed in the %2 parameter with the specified temporary table:
				|%3'; fa = 'In the %1 procedure, the data table of the temporary table manager is passed in the %2 parameter with the specified temporary table:
				|%3';
				|it = 'In the %1 procedure, the data table of the temporary table manager is passed in the %2 parameter with the specified temporary table:
				|%3';
				|pl = 'In the %1 procedure, the data table of the temporary table manager is passed in the %2 parameter with the specified temporary table:
				|%3';
				|tr = '%1 prosedürüne, %2 parametresi içinde belirtilen geçici tablonun mevcut olduğu geçici tablo yöneticisi veri tablosu aktarılıyor: 
				|%3'"), "BudgetingServer.ConvertDataTableToCurrency", "DataTableParameters", 
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndIf;
		If Not IsBlankString(ErrorText) Then
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
	EndIf; 
	
	CalculateManSAndLocalSAmounts = Not ValueIsFilled(ReportCurrency)
		And FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal;
	
	If RecalculationFields = Undefined Then
		RecalculationField = New Structure;
		RecalculationField.Insert("RecalculationField", "AmountInStorageCurrency");
		RecalculationField.Insert("FunctionalCurrencyField", "AmountInFunctionalCurrency");
		RecalculationField.Insert("OutputDataField", "Sum");
		RecalculationField.Insert("OutputDataFieldInCurrency", "AmountInCurrency");
		If CalculateManSAndLocalSAmounts Then
			RecalculationField.Insert("OutputDataField", "SumMan");
			RecalculationField.Insert("LocalOutputDataField", "SumCompl");
		EndIf;
		RecalculationFields = New Array;
		RecalculationFields.Add(RecalculationField);
	EndIf;
	
	QueriesTexts = New Array;
	InitialTemporaryTables = New Array;
	
	Query = New Query;
	If DataTableParameters.TempTablesManager <> Undefined Then
		Query.TempTablesManager = DataTableParameters.TempTablesManager;
		For Each TempTable In Query.TempTablesManager.Tables Do
			InitialTemporaryTables.Add(TempTable.FullName);
		EndDo;
		If InitialTemporaryTables.Find(DataTableParameters.TempTableName) = Undefined Then
			InitialTemporaryTables.Add(DataTableParameters.TempTableName);
		EndIf;
	EndIf;
	
	If TypeOf(ScriptCourseData ) = Type("Structure") And ScriptCourseData.Property("ScenarioCourseTable") Then
		QueryText =
		"SELECT
		|	ScenarioCourseTable.Currency,
		|	ScenarioCourseTable.Period,
		|	ScenarioCourseTable.Rate
		|INTO ScenarioCourseTable
		|FROM
		|	&ScenarioCourseTable AS ScenarioCourseTable
		|
		|INDEX BY
		|	Period,
		|	Currency";
	Else
		QueryText =
		"SELECT
		|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
		|	DATETIME(1,1,1) AS Period,
		|	0 AS Rate
		|INTO ScenarioCourseTable";
	EndIf;
	QueriesTexts.Add(QueryText);
	
	If TypeOf(DataTableParameters.DataTable) = Type("ValueTable") Then
		QueriesTexts.Add(TMCommonUse.QueryTextDataFromValueTable(DataTableParameters.DataTable,
			DataTableParameters.TempTableName));
		Query.SetParameter(DataTableParameters.TempTableName, DataTableParameters.DataTable);
		ColumnsOfDataTable_ = DataTableParameters.DataTable.Columns;
	Else
		ColumnsOfDataTable_ = DataTableParameters.TempTablesManager.Tables.Find(
			DataTableParameters.TempTableName).Columns;
	EndIf;
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN &FunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_) THEN
	|			&CurrencyOfMan
	|		WHEN &FunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal) THEN
	|			&ComplCurrency
	|	END AS FunctionalCurrency,
	|	&OriginalFieldsOfTable
	|INTO Table
	|FROM
	|	TempTableName AS Table";
	QueriesTexts.Add(StrReplace(QueryText, "TempTableName", DataTableParameters.TempTableName));
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
		DataTableParameters.TempTableName);
	
	// Iteration 1 - calculation of conversion rates for the currency of the report or the currency of management accounting
	// Iteration 2 - calculation of exchange rate conversion factors for currencies by currency amounts of the table
	// Iteration 3 - calculation of exchange rate conversion factors for the currency of regulated accounting in the functional currency of Local accounting
	IterationsParameters = New Map;
	IterationsParameters.Insert(1, New Structure("FieldTextCurrency, NameOfOutputDataField",
		?(CalculateManSAndLocalSAmounts, "&CurrencyOfMan", "&ReportCurrency"), "OutputDataField"));
	IterationsParameters.Insert(2, New Structure("FieldTextCurrency, NameOfOutputDataField",
		"Table.Currency", "OutputDataFieldInCurrency"));
	If CalculateManSAndLocalSAmounts Then
		IterationsParameters.Insert(3, New Structure("FieldTextCurrency, NameOfOutputDataField",
		"Table.FunctionalCurrency", "LocalOutputDataField"));
	EndIf;
	
	For Each ParametersByIteration In IterationsParameters Do
		
		SubqueryTexts_ = New Array;
		
		QueryText =
		"SELECT DISTINCT
		|	CurrencyTable.Currency AS Currency,
		|	CurrencyTable.CurrencyOfAmount AS CurrencyOfAmount,
		|	CurrencyTable.CoursePeriodRecalculation AS CoursePeriodRecalculation
		|INTO TableOfPeriods_Suffix
		|FROM
		|	(SELECT
		|		&FieldCurrency AS Currency,
		|		Table.FunctionalCurrency AS CurrencyOfAmount,
		|		Table.RatePeriod AS CoursePeriodRecalculation
		|	FROM
		|		Table AS Table
		|	WHERE
		|		Table.StorageCurrency <> &FieldCurrency
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		&FieldCurrency,
		|		Table.StorageCurrency,
		|		Table.RatePeriod
		|	FROM
		|		Table AS Table
		|	WHERE
		|		Table.StorageCurrency <> &FieldCurrency
		|		AND Table.StorageCurrency <> VALUE(Catalog.Currencies.EmptyRef)) AS CurrencyTable
		|
		|INDEX BY
		|	CoursePeriodRecalculation";
		SubqueryTexts_.Add(QueryText);
		
		QueryText =
		"SELECT
		|	TableOfPeriods_Suffix.Currency AS Currency,
		|	TableOfPeriods_Suffix.CurrencyOfAmount AS CurrencyOfAmount,
		|	TableOfPeriods_Suffix.CoursePeriodRecalculation AS CoursePeriodRecalculation,
		|	MAX(TableOfPeriods_Suffix.Period) AS DateOfCourse
		|INTO TableOfPeriodsAmountCurrency_Suffix
		|FROM
		|	(SELECT
		|		TableOfPeriods_Suffix.Currency AS Currency,
		|		TableOfPeriods_Suffix.CurrencyOfAmount AS CurrencyOfAmount,
		|		TableOfPeriods_Suffix.CoursePeriodRecalculation AS CoursePeriodRecalculation,
		|		MAX(ExchangeRates.Period) AS Period
		|	FROM
		|		TableOfPeriods_Suffix AS TableOfPeriods_Suffix
		|			LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
		|			ON (ExchangeRates.Period <= TableOfPeriods_Suffix.CoursePeriodRecalculation)
		|				AND (ExchangeRates.Currency = TableOfPeriods_Suffix.CurrencyOfAmount)
		|				AND (ExchangeRates.Period <= &ActualDataLimit)
		|	
		|	GROUP BY
		|		TableOfPeriods_Suffix.Currency,
		|		TableOfPeriods_Suffix.CurrencyOfAmount,
		|		TableOfPeriods_Suffix.CoursePeriodRecalculation
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableOfPeriods_Suffix.Currency,
		|		TableOfPeriods_Suffix.CurrencyOfAmount,
		|		TableOfPeriods_Suffix.CoursePeriodRecalculation,
		|		MAX(ExchangeRates.Period)
		|	FROM
		|		TableOfPeriods_Suffix AS TableOfPeriods_Suffix
		|			INNER JOIN ScenarioCourseTable AS ExchangeRates
		|			ON (ExchangeRates.Period <= TableOfPeriods_Suffix.CoursePeriodRecalculation)
		|				AND (ExchangeRates.Currency = TableOfPeriods_Suffix.CurrencyOfAmount)
		|				AND (ExchangeRates.Period > &ActualDataLimit)
		|	
		|	GROUP BY
		|		TableOfPeriods_Suffix.Currency,
		|		TableOfPeriods_Suffix.CurrencyOfAmount,
		|		TableOfPeriods_Suffix.CoursePeriodRecalculation) AS TableOfPeriods_Suffix
		|
		|GROUP BY
		|	TableOfPeriods_Suffix.Currency,
		|	TableOfPeriods_Suffix.CurrencyOfAmount,
		|	TableOfPeriods_Suffix.CoursePeriodRecalculation";
		SubqueryTexts_.Add(QueryText);
		
		QueryText = 
		"SELECT
		|	TableOfPeriods_Suffix.Currency AS Currency,
		|	TableOfPeriods_Suffix.CoursePeriodRecalculation AS CoursePeriodRecalculation,
		|	MAX(TableOfPeriods_Suffix.Period) AS DateOfCourse
		|INTO TableOfPeriodsCurrency_Suffix
		|FROM
		|	(SELECT
		|		TableOfPeriods_Suffix.Currency AS Currency,
		|		TableOfPeriods_Suffix.CoursePeriodRecalculation AS CoursePeriodRecalculation,
		|		MAX(ExchangeRates.Period) AS Period
		|	FROM
		|		TableOfPeriods_Suffix AS TableOfPeriods_Suffix
		|			LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
		|			ON (ExchangeRates.Period <= TableOfPeriods_Suffix.CoursePeriodRecalculation)
		|				AND (ExchangeRates.Currency = TableOfPeriods_Suffix.Currency)
		|				AND (ExchangeRates.Period <= &ActualDataLimit)
		|	
		|	GROUP BY
		|		TableOfPeriods_Suffix.Currency,
		|		TableOfPeriods_Suffix.CoursePeriodRecalculation
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableOfPeriods_Suffix.Currency,
		|		TableOfPeriods_Suffix.CoursePeriodRecalculation,
		|		MAX(ExchangeRates.Period)
		|	FROM
		|		TableOfPeriods_Suffix AS TableOfPeriods_Suffix
		|			INNER JOIN ScenarioCourseTable AS ExchangeRates
		|			ON (ExchangeRates.Period <= TableOfPeriods_Suffix.CoursePeriodRecalculation)
		|				AND (ExchangeRates.Currency = TableOfPeriods_Suffix.Currency)
		|				AND (ExchangeRates.Period > &ActualDataLimit)
		|	
		|	GROUP BY
		|		TableOfPeriods_Suffix.Currency,
		|		TableOfPeriods_Suffix.CoursePeriodRecalculation) AS TableOfPeriods_Suffix
		|
		|GROUP BY
		|	TableOfPeriods_Suffix.Currency,
		|	TableOfPeriods_Suffix.CoursePeriodRecalculation";
		SubqueryTexts_.Add(QueryText);
		
		QueryText =
		"SELECT DISTINCT
		|	TableOfPeriods_Suffix.Currency AS Currency,
		|	TableOfPeriods_Suffix.CurrencyOfAmount AS CurrencyOfAmount,
		|	TableOfPeriods_Suffix.CoursePeriodRecalculation AS CoursePeriodRecalculation,
		|	CASE
		|		WHEN ISNULL(StorageCurrenciesRates.CourseDenominator, 0) <> 0
		|				AND ISNULL(ExchangeRates.CourseNumerator, 0) <> 0
		|			THEN StorageCurrenciesRates.CourseNumerator * ExchangeRates.CourseDenominator / (StorageCurrenciesRates.CourseDenominator * ExchangeRates.CourseNumerator)
		|		WHEN ISNULL(ScriptStorageCurrencyRates.Rate, 0) <> 0
		|			THEN CASE
		|					WHEN ISNULL(ExchangeRatesOfScenario.Rate, 0) <> 0
		|						THEN ScriptStorageCurrencyRates.Rate / ExchangeRatesOfScenario.Rate
		|					WHEN ISNULL(ExchangeRates.CourseNumerator, 0) <> 0
		|						THEN ScriptStorageCurrencyRates.Rate / ExchangeRates.CourseNumerator
		|					ELSE 0
		|				END
		|		ELSE 0
		|	END AS ConversionFactor_
		|INTO ConversionFactorsToCurrency_Suffix
		|FROM
		|	TableOfPeriods_Suffix AS TableOfPeriods_Suffix
		|		LEFT JOIN TableOfPeriodsAmountCurrency_Suffix AS TableOfPeriodsAmountCurrency_Suffix
		|		ON (TableOfPeriodsAmountCurrency_Suffix.CoursePeriodRecalculation = TableOfPeriods_Suffix.CoursePeriodRecalculation)
		|			AND (TableOfPeriodsAmountCurrency_Suffix.CurrencyOfAmount = TableOfPeriods_Suffix.CurrencyOfAmount)
		|			AND (TableOfPeriodsAmountCurrency_Suffix.Currency = TableOfPeriods_Suffix.Currency)
		|		LEFT JOIN InformationRegister.RelativeExchangeRates AS StorageCurrenciesRates
		|		ON (StorageCurrenciesRates.Period = TableOfPeriodsAmountCurrency_Suffix.DateOfCourse)
		|			AND (StorageCurrenciesRates.Currency = TableOfPeriodsAmountCurrency_Suffix.CurrencyOfAmount)
		|		LEFT JOIN ScenarioCourseTable AS ScriptStorageCurrencyRates
		|		ON (ScriptStorageCurrencyRates.Period = TableOfPeriodsAmountCurrency_Suffix.DateOfCourse)
		|			AND (ScriptStorageCurrencyRates.Currency = TableOfPeriodsAmountCurrency_Suffix.CurrencyOfAmount)
		|		LEFT JOIN TableOfPeriodsCurrency_Suffix AS TableOfPeriodsCurrency_Suffix
		|		ON (TableOfPeriodsCurrency_Suffix.CoursePeriodRecalculation = TableOfPeriods_Suffix.CoursePeriodRecalculation)
		|			AND (TableOfPeriodsCurrency_Suffix.Currency = TableOfPeriods_Suffix.Currency)
		|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
		|		ON (ExchangeRates.Period = TableOfPeriodsCurrency_Suffix.DateOfCourse)
		|			AND (ExchangeRates.Currency = TableOfPeriodsCurrency_Suffix.Currency)
		|		LEFT JOIN ScenarioCourseTable AS ExchangeRatesOfScenario
		|		ON (ExchangeRatesOfScenario.Period = TableOfPeriodsCurrency_Suffix.DateOfCourse)
		|			AND (ExchangeRatesOfScenario.Currency = TableOfPeriodsCurrency_Suffix.Currency)";
		SubqueryTexts_.Add(QueryText);
		
		QueryText = StrConcat(SubqueryTexts_, Common.QueryBatchSeparator());
		
		QueryText = StrReplace(QueryText, "&FieldCurrency", ParametersByIteration.Value.FieldTextCurrency);
		QueryText = StrReplace(QueryText, "Suffix", TrimAll(ParametersByIteration.Key));
		QueriesTexts.Add(QueryText);
	
	EndDo;
	
	QueryText =
	"SELECT
	|	&RecalculationFields1,
	|	&RecalculationFields2,
	|	&RecalculationFields3,
	|	&FinalFieldsOfTable,
	|	CASE
	|		WHEN Table.StorageCurrency = UNDEFINED
	|				OR Table.StorageCurrency = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN Table.FunctionalCurrency
	|		ELSE Table.StorageCurrency
	|	END AS StorageCurrency,
	|	CASE
	|		WHEN Table.StorageCurrency = UNDEFINED
	|				OR Table.StorageCurrency = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN Table.AmountInFunctionalCurrency
	|		ELSE Table.AmountInStorageCurrency
	|	END AS AmountInStorageCurrency
	|INTO TempTableName
	|FROM
	|	Table AS Table";
	
	For Counter = 1 To 3 Do
		
		ParametersByIteration = IterationsParameters.Get(Counter);
		
		If ParametersByIteration = Undefined Then
			
			QueryText = StrReplace(QueryText, StringFunctionsClientServer.SubstituteParametersToString(
				"&RecalculationFields%1,", Counter), "");
			
		Else
			
			QueryText = QueryText + "
			|	
			|	LEFT JOIN ConversionFactorsToCurrency_Suffix AS ConversionFactorsFromFunctionalCurrency_Suffix
			|	ON (&FunctionalCurrencyCondition)
			|		AND (ConversionFactorsFromFunctionalCurrency_Suffix.CurrencyOfAmount = Table.FunctionalCurrency)
			|		AND (ConversionFactorsFromFunctionalCurrency_Suffix.CoursePeriodRecalculation = Table.RatePeriod)
			|	LEFT JOIN ConversionFactorsToCurrency_Suffix AS ConversionFactorsFromStorageCurrency_Suffix
			|	ON (&StorageCurrencyCondition)
			|		AND (ConversionFactorsFromStorageCurrency_Suffix.CurrencyOfAmount = Table.StorageCurrency)
			|		AND (ConversionFactorsFromStorageCurrency_Suffix.CoursePeriodRecalculation = Table.RatePeriod)";
			
			If Counter = 2 Then
				QueryText = StrReplace(QueryText, "&FunctionalCurrencyCondition",
					"ConversionFactorsFromFunctionalCurrency_Suffix.Currency = Table.Currency");
				QueryText = StrReplace(QueryText, "&StorageCurrencyCondition",
					"ConversionFactorsFromStorageCurrency_Suffix.Currency = Table.Currency");
			ElsIf Counter = 3 Then
				QueryText = StrReplace(QueryText, "&FunctionalCurrencyCondition",
					"ConversionFactorsFromFunctionalCurrency_Suffix.Currency = Table.FunctionalCurrency");
				QueryText = StrReplace(QueryText, "&StorageCurrencyCondition",
					"ConversionFactorsFromStorageCurrency_Suffix.Currency = Table.FunctionalCurrency");
			Else
				QueryText = StrReplace(QueryText, "&FunctionalCurrencyCondition", "TRUE");
				QueryText = StrReplace(QueryText, "&StorageCurrencyCondition", "TRUE");
			EndIf;
			QueryText = StrReplace(QueryText, "Suffix", Counter);
			
		EndIf;
		
	EndDo;
	QueriesTexts.Add(QueryText);
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	TemplateForRecalculationField = "
	|	CASE
	|		WHEN Table.StorageCurrency = &FieldCurrency
	|			THEN Table.%1
	|		WHEN Table.StorageCurrency <> &FieldCurrency
	|			AND NOT (Table.%2 IS NULL
	|				OR Table.FunctionalCurrency = VALUE(Catalog.Currencies.EmptyRef)
	|				OR Table.%2 = 0 AND Table.%1 <> 0)
	|			THEN Table.%2 * ISNULL(ConversionFactorsFromFunctionalCurrency_Suffix.ConversionFactor_, 1)
	|		WHEN Table.StorageCurrency <> &FieldCurrency
	|			AND (Table.%2 IS NULL
	|				OR Table.FunctionalCurrency = VALUE(Catalog.Currencies.EmptyRef)
	|				OR Table.%2 = 0 AND Table.%1 <> 0)
	|			THEN Table.%1 * ISNULL(ConversionFactorsFromStorageCurrency_Suffix.ConversionFactor_, 1)
	|		WHEN Table.StorageCurrency = UNDEFINED
	|			THEN Table.%1
	|	END AS %3
	|";
	
	If TypeOf(ScriptCourseData) = Type("Structure") And ScriptCourseData.Property("ScenarioCourseTable") Then
		Query.SetParameter("ScenarioCourseTable", ScriptCourseData.ScenarioCourseTable);
		Query.SetParameter("ActualDataLimit", ScriptCourseData.ActualDataLimit);
	Else
		Query.Text = StrReplace(Query.Text, "ExchangeRates.Period <= &ActualDataLimit", "TRUE");
		Query.Text = StrReplace(Query.Text, "ExchangeRates.Period > &ActualDataLimit", "TRUE");
	EndIf;
	
	DuplicateTableFields = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
		"StorageCurrency,AmountInStorageCurrency", ",");
	
	For Each ParametersByIteration In IterationsParameters Do
		TextOfRecalculationField = StrReplace(TemplateForRecalculationField, "&FieldCurrency", ParametersByIteration.Value.FieldTextCurrency);
		TextOfRecalculationField = StrReplace(TextOfRecalculationField, "Suffix", TrimAll(ParametersByIteration.Key));
		
		RowsOfRecalculationFields = New Array;
		For Each Field In RecalculationFields Do
			OutputDataField = Field[ParametersByIteration.Value.NameOfOutputDataField];
			RowsOfRecalculationFields.Add(StrTemplate(TextOfRecalculationField, Field.RecalculationField, Field.FunctionalCurrencyField,
				OutputDataField));
			DuplicateTableFields.Add(OutputDataField);
		EndDo;
		Query.Text = StrReplace(Query.Text, "&RecalculationFields" + ParametersByIteration.Key, StrConcat(
			RowsOfRecalculationFields, "," + Chars.LF + Chars.Tab));
	EndDo;
	
	Query.SetParameter("ReportCurrency", ReportCurrency);
	Query.SetParameter("FunctionalCurrency", FunctionalCurrency);
	Query.SetParameter("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());
	
	OriginalFieldsOfTable = New Array;
	FinalFieldsOfTable = New Array;
	Untyped_Fields = New Array;
	For Each Column In ColumnsOfDataTable_ Do
		If ValueIsFilled(Column.ValueType) Then
			OriginalFieldsOfTable.Add(StringFunctionsClientServer.SubstituteParametersToString(
				"Table.%1 AS %1", Column.Name));
			If DuplicateTableFields.Find(Column.Name) = Undefined Then
				FinalFieldsOfTable.Add(StringFunctionsClientServer.SubstituteParametersToString(
					"Table.%1 AS %1", Column.Name));
			EndIf;
		Else
			Untyped_Fields.Add(Column.Name);
		EndIf;
		DataTableParameters.ColumnsOfDataTable_.Insert(Column.Name, Column.ValueType);
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&OriginalFieldsOfTable", StrConcat(OriginalFieldsOfTable, "," + Chars.LF
		+ Chars.Tab));
	Query.Text = StrReplace(Query.Text, "&FinalFieldsOfTable", StrConcat(FinalFieldsOfTable, "," + Chars.LF
		+ Chars.Tab));
	
	If ColumnsOfDataTable_.Find("Organization") <> Undefined Then
		If GetFunctionalOption("UseMultipleCompanies") Then
			Query.Text = StrReplace(Query.Text, "&ComplCurrency", "Table.Organization.LocalAccountingCurrency");
		Else
			DefaultCompany = SettingsValueCached.GetDefaultOrganization();
			Query.SetParameter("ComplCurrency",
				 SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DefaultCompany));
		EndIf;
	Else
		Query.SetParameter("ComplCurrency", SettingsValueCached.DefaultBaseCurrency());
	EndIf;
	If ColumnsOfDataTable_.Find("AmountInFunctionalCurrency") = Undefined Then
		Query.Text = StrReplace(Query.Text, "Table.AmountInFunctionalCurrency", "0");
	EndIf;
	If ColumnsOfDataTable_.Find("AmountInStorageCurrency") = Undefined Then
		Query.Text = StrReplace(Query.Text, "Table.AmountInStorageCurrency", "0");
	EndIf;
	
	If DataTableParameters.TempTablesManager = Undefined Then
		
		Query.Text = StrReplace(Query.Text, "INTO TempTableName", "");
		
		DataTable = Query.Execute().Unload();
		For Each Field In Untyped_Fields Do
			DataTable.Columns.Add(Field);
		EndDo;
		DataTableParameters.DataTable = DataTable;
		
	Else
		
		Query.Text = StrReplace(Query.Text, "TempTableName", DataTableParameters.TempTableName);
		If ValueIsFilled(DataTableParameters.IndexFields) Then
			Query.Text = Query.Text + Chars.LF +
				"INDEX BY
				|" + DataTableParameters.IndexFields;
		EndIf;
		
		Query.Execute();
		TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager, , InitialTemporaryTables);
		
	EndIf;
	
EndProcedure

Function FindLayoutFieldByFieldName(SetFields, FieldName)
	
	For Each SetField In SetFields Do
		If TypeOf(SetField) = Type("DataCompositionSchemaDataSetFieldFolder") Then
			Continue;
		EndIf;
		If Lower(SetField.Field) = Lower(FieldName) Then
			Return SetField;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Procedure AddDimensionFields(DataCompositionSchema, Settings, Parameters)
	
	SetFields = DataCompositionSchema.DataSets[0].Fields;
	
	If Parameters.ByCompanies And FindLayoutFieldByFieldName(SetFields, "Organization") <> Undefined Then
		AddGroupField(Settings, "Organization");
	EndIf;
	
	If Parameters.ByBusinessUnits And FindLayoutFieldByFieldName(SetFields, "Department") <> Undefined Then
		AddGroupField(Settings, "Department");
	EndIf;
	
EndProcedure

Function SourcesAndRules(DataCompositionSchema, Rule) Export
	
	DataSet = DataCompositionSchema.DataSets[0];
	
	SourcesOfSum = New Structure;
	If Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
		If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
			RuleOnItemOfAssetsLiabilities = DataSourcesServer.ThisIsItemOfAssetsLiabilities(Rule.DataSource);
		Else
			RuleOnItemOfAssetsLiabilities = False;
		EndIf;
		If RuleOnItemOfAssetsLiabilities Then
			RegisterIndicators = DataSourcesCached.IndicatorsOfSumOfItemOfAssetsLiabilities(Rule.DataSource);
		ElsIf GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters")
			Or Rule.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment
			And LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Then
			RegisterIndicators = DataSourcesCached.AmountIndicatorsByDataSource(Rule.DataSourceXO);
		Else
			DataSetName = DataSet.Name; // The data set name corresponds to the operation case
			RegisterIndicators = FinancialAccountingServerCached.Indicators(DataSetName);
		EndIf;
		AmountSourceData = RegisterIndicators.Get(Rule.TransactionAmountSource);
		SumSourceResources = ?(AmountSourceData = Undefined, Undefined, AmountSourceData.Resources);
		If SumSourceResources = Undefined Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối với nguồn của số tiền %1 của giao dịch kinh doanh %2 không tìm thấy tài nguyên phù hợp trong nguồn dữ liệu.';
					|ru = 'Для источника суммы %1 хозяйственной операции %2 не найдены соответствующие ресурсы в источнике данных.';
					|en = 'Corresponding resources are not found in the data source for the source of amount %1 of business transaction %2.'; fa = 'Corresponding resources are not found in the data source for the source of amount %1 of business transaction %2.';
					|it = 'Per la fonte della somma %1 della transazione commerciale %2 non sono state trovate le risorse corrispondenti nella sorgente dei dati.';
					|pl = 'Dla źródła wartości %1 operacji gospodarczej %2 nie znaleziono odpowiednich zasobów w źródle danych.';
					|tr = '%1 tutar kaynağı için %2 ticari işlemindeki veri kaynaklarında ilgili kaynaklar bulunamadı.'"), 
				Rule.TransactionAmountSource, 
				Rule.DataSourceXO);
			Raise MessageText;
		EndIf;
		
		For Each Resource In SumSourceResources Do
			If RuleOnItemOfAssetsLiabilities Then
				AmountField = AccountingResourceField(Resource["Name"], Rule.TotalType);
			Else
				AmountField = Resource["Name"];
			EndIf;
			If DataSet.Fields.Find(AmountField) = Undefined Then
				// The resource is not selected in the source
				Continue;
			EndIf;
			If Resource["SourceOfCurrency"] = "CurrencyOfMan" Then
				SourcesOfSum.Insert("Man", AmountField);
			ElsIf Resource["SourceOfCurrency"] = "ComplCurrency" Then
				SourcesOfSum.Insert("Compl", AmountField);
			Else
				SourcesOfSum.Insert("Currency", AmountField);
			EndIf;
		EndDo;
		
	ElsIf Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting Then
		SourcesOfSum.Insert("Compl", AccountingResourceField("Sum", Rule.TotalType));
		SourcesOfSum.Insert("Man", AccountingResourceField("AmountOfUU", Rule.TotalType));
		If Rule.SourceOfForeignExchange Then
			SourcesOfSum.Insert("Currency", AccountingResourceField("AmountInCurrency", Rule.TotalType));
		EndIf;
	ElsIf Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting Then
		SourcesOfSum.Insert("International_", AccountingResourceField("Sum", Rule.TotalType));
		If Rule.SourceOfForeignExchange Then
			SourcesOfSum.Insert("Currency", AccountingResourceField("AmountInCurrency", Rule.TotalType));
		EndIf;
	ElsIf Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		FillInSourcesOfAmountAccordingToScheme(SourcesOfSum, DataCompositionSchema.DataSets[0]);
	EndIf;
	
	Return SourcesOfSum;
	
EndFunction

Procedure AddAmountsByBudgetItemField(DataCompositionSchema, Settings, Rule, Parameters)
	
	SourcesOfSum = SourcesAndRules(DataCompositionSchema, Rule);
	
	AddAmountField(DataCompositionSchema, Settings, Rule, Parameters, SourcesOfSum);
	
	DataSet = DataCompositionSchema.DataSets[0];
	If DataSet.Fields.Find("DayPeriod") <> Undefined Then
		ExpressionOfCoursePeriodField = "DayPeriod";
	ElsIf DataSet.Fields.Find("Period") <> Undefined Then
		ExpressionOfCoursePeriodField = "Period";
	Else
		ExpressionOfCoursePeriodField = "&EndOfPeriod";
	EndIf;
	
	FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "RatePeriod", ExpressionOfCoursePeriodField);
	AddGroupField(Settings, "RatePeriod");
	
EndProcedure

Procedure AddAmountsByBudgetIndicatorField(DataCompositionSchema, Settings, Rule, Parameters)
	
	SourcesOfSum = New Structure;
	If Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
		FillInSourcesOfAmountAccordingToScheme(SourcesOfSum, DataCompositionSchema.DataSets[0]);
	ElsIf Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting Then
		SourcesOfSum.Insert("Compl", AccountingResourceField("Sum", Rule.TotalType));
		SourcesOfSum.Insert("Man", AccountingResourceField("AmountOfUU", Rule.TotalType));
		If Rule.SourceOfForeignExchange Then
			SourcesOfSum.Insert("Currency", AccountingResourceField("AmountInCurrency", Rule.TotalType));
		EndIf;
	ElsIf Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting Then
		SourcesOfSum.Insert("International_", AccountingResourceField("Sum", Rule.TotalType));
		If Rule.SourceOfForeignExchange Then
			SourcesOfSum.Insert("Currency", AccountingResourceField("AmountInCurrency", Rule.TotalType));
		EndIf;
	ElsIf Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		FillInSourcesOfAmountAccordingToScheme(SourcesOfSum, DataCompositionSchema.DataSets[0]);
	EndIf;
	
	AddAmountField(DataCompositionSchema, Settings, Rule, Parameters, SourcesOfSum);
	
	FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "RatePeriod", "&Period");
	AddGroupField(Settings, "RatePeriod");
	
EndProcedure

Procedure AddAmountField(DataCompositionSchema, Settings, Rule, Parameters, SourcesOfSum)
	
	FinancialReportingServer.NewCalculatedResource(DataCompositionSchema, "Sum",, "Sum");
	DataCompositionClientServer.AddSelectedField(Settings, "Sum");
	
	If SourcesOfSum.Property("Currency") Then
		
		SearchPrefix = SearchPrefix(Rule.DataSourceSection, "Currency", Rule.DataSourceObjectType);
		
		DatasetFields = DataCompositionSchema.DataSets[0].Fields;
		DataSetFieldCurrency = DatasetFields.Find(SearchPrefix + "Currency");
		
		If DataSetFieldCurrency = Undefined Then
			For Each DataSetField In DatasetFields Do
				If TypeOf(DataSetField) = Type("DataCompositionSchemaDataSetFieldFolder")
					Or TypeOf(DataSetField) = Type("DataCompositionSchemaNestedDataSet") Then
					Continue;
				EndIf;
				If DataSetField.ValueType.ContainsType(Type("CatalogRef.Currencies")) Then
					DataSetFieldCurrency = DataSetField;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If DataSetFieldCurrency = Undefined Then
			ErrorText = NStr("vi = 'Chưa xác định tiền tệ để nhận số tiền nguyên tệ.';
							|ru = 'Не определена валюта для получения валютной суммы.';
							|en = 'Currency for receiving currency amount  is not determined.'; fa = 'Currency for receiving currency amount  is not determined.';
							|it = 'Non è stata identificata la valuta per l''ottenimento della somma valutaria.';
							|pl = 'Nie określono waluty dla otrzymania wartości walutowej.';
							|tr = 'Para birimi tutarlarının toplanmaları için para birimi belirtilmemiş'");
			Raise ErrorText;
		Else
			DataPathCurrency = DataSetFieldCurrency.DataPath;
		EndIf;
		
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "StorageCurrency", DataPathCurrency);
		AddGroupField(Settings, "StorageCurrency");
		
		ExpressionOfAmountField = SourcesOfSum.Currency;
		FinancialReportingServer.NewCalculatedResource(DataCompositionSchema, "AmountInStorageCurrency", ExpressionOfAmountField, "Sum");
		DataCompositionClientServer.AddSelectedField(Settings, "AmountInStorageCurrency");
	ElsIf SourcesOfSum.Property("International_") Then
		
		If GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting") Then
			DataPathCurrency = "FinancialAccountingServerCached.CurrencyFunctional(FinancialAccountingChartOfAccounts, Organization)";
		Else
			DataPathCurrency = "&StorageCurrency";
			AddParameter(DataCompositionSchema, "StorageCurrency", Parameters.InternationalCurrency);
		EndIf;
		
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "StorageCurrency", DataPathCurrency);
		AddGroupField(Settings, "StorageCurrency");
		
		ExpressionOfAmountField = SourcesOfSum.International_;
		FinancialReportingServer.NewCalculatedResource(DataCompositionSchema, "AmountInStorageCurrency", ExpressionOfAmountField, "Sum");
		DataCompositionClientServer.AddSelectedField(Settings, "AmountInStorageCurrency");
	EndIf;
	
	If Parameters.FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_ Then
		
		If SourcesOfSum.Property("Man") Then
			ExpressionOfAmountFieldInFunctionalCurrency = SourcesOfSum.Man;
		Else
			ExpressionOfAmountFieldInFunctionalCurrency = "NULL";
		EndIf;
		ExpressionOfFunctionalCurrencyField = "&CurrencyFunctional";
		AddParameter(DataCompositionSchema, "CurrencyFunctional", Parameters.CurrencyOfMan);
		
	ElsIf Parameters.FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal Then
		If SourcesOfSum.Property("Compl") Then
			ExpressionOfAmountFieldInFunctionalCurrency = SourcesOfSum.Compl;
		Else
			ExpressionOfAmountFieldInFunctionalCurrency = "NULL";
		EndIf;
		If GetFunctionalOption("UseMultipleCompanies") Then
			ExpressionOfFunctionalCurrencyField = "Organization.LocalAccountingCurrency";
		Else
			ExpressionOfFunctionalCurrencyField = "Constants.LocalAccountingCurrency.Get()";
		EndIf;
		
	Else
		ExpressionOfAmountFieldInFunctionalCurrency = "NULL";
		ExpressionOfFunctionalCurrencyField = "NULL";
	EndIf;
	
	FinancialReportingServer.NewCalculatedResource(
		DataCompositionSchema, "AmountInFunctionalCurrency", ExpressionOfAmountFieldInFunctionalCurrency, "Sum");
	DataCompositionClientServer.AddSelectedField(Settings, "AmountInFunctionalCurrency");
	
	FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "CurrencyFunctional", ExpressionOfFunctionalCurrencyField);
	AddGroupField(Settings, "CurrencyFunctional");
	
	If Parameters.ReturnManAndLocalAmounts Then // for a stored cache
		
		If SourcesOfSum.Property("Man") Then
			ExpressionOfAmountField = SourcesOfSum.Man;
		Else
			ExpressionOfAmountField = "NULL";
		EndIf;
		FinancialReportingServer.NewCalculatedResource(DataCompositionSchema, "SumMan", ExpressionOfAmountField, "Sum");
		DataCompositionClientServer.AddSelectedField(Settings, "SumMan");
		
		If SourcesOfSum.Property("Compl") Then
			ExpressionOfAmountField = SourcesOfSum.Compl;
		Else
			ExpressionOfAmountField = "NULL";
		EndIf;
		FinancialReportingServer.NewCalculatedResource(DataCompositionSchema, "SumCompl", ExpressionOfAmountField, "Sum");
		DataCompositionClientServer.AddSelectedField(Settings, "SumCompl");
	EndIf;
	
EndProcedure

Procedure AddQuantityField(DataCompositionSchema, Settings, Rule)
	
	SetFields = DataCompositionSchema.DataSets[0].Fields;
	
	QuantityField = "Count";
	If Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting
	 Or Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting
	 Or (Rule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
		And TypeOf(Rule.Rule) = Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems")
		And GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems")
		And DataSourcesServer.ThisIsItemOfAssetsLiabilities(Rule.DataSource)) Then
		QuantityField = AccountingResourceField("Count", Rule.TotalType);
	EndIf;
	
	If SetFields.Find(QuantityField) <> Undefined Then
		FinancialReportingServer.NewCalculatedResource(DataCompositionSchema, "Count", QuantityField, "Sum");
	Else
		FinancialReportingServer.NewCalculatedResource(DataCompositionSchema, "Count", "NULL", "Sum");
	EndIf;
	DataCompositionClientServer.AddSelectedField(Settings, "Count");
	
EndProcedure

Procedure AddParameter(DataCompositionSchema, ParameterName, Value = Undefined)
	
	If DataCompositionSchema.Parameters.Find(ParameterName) <> Undefined Then
		Return;
	EndIf;
	
	Parameter = DataCompositionSchema.Parameters.Add();
	Parameter.Use = DataCompositionParameterUse.Always;
	Parameter.Name = ParameterName;
	Parameter.UseRestriction = True;
	
	If Value <> Undefined Then
		Parameter.Value = Value;
		Parameter.IncludeInAvailableFields = False;
	EndIf;
	
EndProcedure

Procedure SetSelectionForFullnessOfIndicators(Settings, Parameters)
	
	Filter = CommonClientServer.CreateFilterItemGroup(
		Settings.Filter.Items, "GroupFilter", DataCompositionFilterItemsGroupType.OrGroup);
		
	If Parameters.Indicators.Property("Sum") Then
		ThereIsSelectionByAmount = False;
		If Settings.Selection.SelectionAvailableFields.Items.Find("AmountInStorageCurrency") <> Undefined Then
			DataCompositionClientServer.AddFilter(
				Filter, "AmountInStorageCurrency",, DataCompositionComparisonType.Filled, True);
			ThereIsSelectionByAmount = True;
		EndIf;
		If Settings.Selection.SelectionAvailableFields.Items.Find("AmountInFunctionalCurrency") <> Undefined Then
			DataCompositionClientServer.AddFilter(
				Filter, "AmountInFunctionalCurrency",, DataCompositionComparisonType.Filled, True);
			ThereIsSelectionByAmount = True;
		EndIf;
		If Parameters.Property("CurrentLimits") And Not ThereIsSelectionByAmount Then
			DataCompositionClientServer.AddFilter(
				Filter, "AmountInCurrency",, DataCompositionComparisonType.Filled, True);
			ThereIsSelectionByAmount = True;
		EndIf;
		// To record the stored fact, the amount in the functional currency is not required to be full
		If Parameters.ReturnManAndLocalAmounts Or Not ThereIsSelectionByAmount Then
			DataCompositionClientServer.AddFilter(
				Filter, "SumMan",, DataCompositionComparisonType.Filled, True);
			DataCompositionClientServer.AddFilter(
				Filter, "SumCompl",, DataCompositionComparisonType.Filled, True);
		EndIf;
	EndIf;
	
	If Parameters.Indicators.Property("Count") Then
		DataCompositionClientServer.AddFilter(
			Filter, "Count",, DataCompositionComparisonType.Filled, True);
	EndIf;
	
EndProcedure

Function FactOnItemsThatAffectBudgetPerformance(FilterRules_, Parameters, ExpandPeriod = False, TempTablesManager = Undefined) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	// We will add a selection that ensures the selection of only articles that affect the indicators
	FilterElement = FinancialReportingServer.FindSelectionElement(FilterRules_.Filter, "BudgetBalanceItem");
	If FilterElement = Undefined Or Not FilterElement.Use Then
		DataCompositionClientServer.AddFilter(FilterRules_, "BudgetBalanceItem", , DataCompositionComparisonType.Filled);
	EndIf;
	
	// Installation of selections.
	SetPrivilegedMode(True);
	
	ArticleSelectionScheme = DataCompositionServer.EmptyCircuit();
	RequestSet = DataCompositionServer.AddEmptyDataSet(
		ArticleSelectionScheme, Type("DataCompositionSchemaDataSetQuery"), "RulesForCalculatingBudgetIndicators");
	RequestSet.Query =
	"SELECT
	|	CalculationsRules.Source AS BudgetFlowItem,
	|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems) AS BudgetBalanceItem,
	|	CalculationsRules.Ref AS CalculationRule
	|FROM
	|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|WHERE
	|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).IndicatorType = VALUE(Enum.BudgetBalanceItemType.Estimated_)
	|	AND NOT CalculationsRules.DeletionMark
	|	AND CalculationsRules.Status = VALUE(Enum.BudgetingRuleStatuses.Valid)";
	DataCompositionSettings = New DataCompositionSettings;
	AddGroupField(DataCompositionSettings, "BudgetFlowItem");
	AddGroupField(DataCompositionSettings, "CalculationRule");
	DataCompositionClientServer.CopyDataCompositionFilter(ArticleSelectionScheme, DataCompositionSettings, FilterRules_, "Scenario");
	DataCompositionClientServer.DisableOutputOfTotals(DataCompositionSettings);
	BudgetItemsByIndicators = FinancialReportingServer.UploadDCSResults(ArticleSelectionScheme, DataCompositionSettings);
	ArrayOfArticles = BudgetItemsByIndicators.UnloadColumn("BudgetFlowItem");
	FilterElement = FinancialReportingServer.FindSelectionElement(FilterRules_.Filter, "BudgetFlowItem");
	If FilterElement = Undefined Or Not FilterElement.Use Then
		DataCompositionClientServer.AddFilter(FilterRules_, "BudgetFlowItem", ArrayOfArticles, DataCompositionComparisonType.InList);
	EndIf;
	SetPrivilegedMode(False);
	
	FactOnBudgetItems = FactOnBudgetItems(FilterRules_,
		Parameters,
		False,
		Parameters.AddStoredFactForItemsThatAffectBudgetPerformance);
	
	AttributesTypesOfAnalytics = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AttributesTypesOfAnalytics.Add("DimensionKind" + DimensionNumber);
	EndDo;
	TypesOfBudgetsItemAnalytics = Common.ObjectsAttributesValues(ArrayOfArticles, StrConcat(AttributesTypesOfAnalytics, ","));
	TypesOfAnalystValues = New Map;
	FullNamesOfAnalystTypes = New Map;
	For Each DimensionKindsBudgetItems In TypesOfBudgetsItemAnalytics Do
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			TypeOfBudgetItemAnalytics = DimensionKindsBudgetItems.Value["DimensionKind" + DimensionNumber];
			If ValueIsFilled(TypeOfBudgetItemAnalytics) Then
				DimensionValuesTypes = BudgetingCached.TypesOfAnalyticsType(TypeOfBudgetItemAnalytics);
				For Each TypeOfAnalyticsValue In DimensionValuesTypes Do
					If FullNamesOfAnalystTypes.Get(TypeOfAnalyticsValue) = Undefined Then
						FullNamesOfAnalystTypes.Insert(TypeOfAnalyticsValue, Metadata.FindByType(TypeOfAnalyticsValue).FullName());
					EndIf;
					TypesOfValuesByAnalyticsNumber = TypesOfAnalystValues.Get("Dimension" + DimensionNumber);
					If TypesOfValuesByAnalyticsNumber = Undefined Then
						TypesOfAnalystValues.Insert("Dimension" + DimensionNumber, New Array);
					EndIf;
					CommonClientServer.SupplementArray(TypesOfAnalystValues["Dimension" + DimensionNumber],
						CommonClientServer.ValueInArray(FullNamesOfAnalystTypes[TypeOfAnalyticsValue]), True);
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	QueryTextSelectionFields1 = New Array;
	TemplateForAnalyticsFieldByValueType = "WHEN VALUETYPE(FactOnBudgetItems.%1) = TYPE(%2)
		|	THEN CAST(FactOnBudgetItems.%1 AS %2)";
	FieldPattern = "FactOnBudgetItems.%1 AS %1";
	For Each Column In FactOnBudgetItems.Columns Do
		If TypesOfAnalystValues.Get(Column.Name) <> Undefined Then
			AnalyticsFieldExpressionsByValueType = New Array;
			For Each TypeOfAnalyticsValue In TypesOfAnalystValues[Column.Name] Do
				AnalyticsFieldExpressionsByValueType.Add(StringFunctionsClientServer.SubstituteParametersToString(
					TemplateForAnalyticsFieldByValueType, Column.Name, TypeOfAnalyticsValue));
			EndDo;
			QueryTextSelectionFields1.Add(StringFunctionsClientServer.SubstituteParametersToString(
				"CASE %1 ELSE UNDEFINED END AS %2", Chars.LF + Chars.Tab + StrConcat(AnalyticsFieldExpressionsByValueType,
				Chars.LF + Chars.Tab), Column.Name));
		Else
			QueryTextSelectionFields1.Add(StringFunctionsClientServer.SubstituteParametersToString(FieldPattern, Column.Name));
		EndIf;
	EndDo;
	QueryTextTT = StrReplace(
		"SELECT
		|	&QueryTextSelectionFields1
		|INTO FactOnBudgetItems
		|FROM
		|	&FactOnBudgetItems AS FactOnBudgetItems", "&QueryTextSelectionFields1", StrConcat(
		QueryTextSelectionFields1, "," + Chars.LF + Chars.Tab)) + "
		|
		|INDEX BY
		|	BudgetFlowItem"
		+ Common.QueryBatchSeparator() +
		"SELECT DISTINCT
		|	CalculationsRules.Source AS BudgetFlowItem,
		|	CalculationsRules.Receiver AS BudgetBalanceItem
		|INTO RelationshipSettings
		|FROM
		|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
		|WHERE
		|	CalculationsRules.Ref IN(&CalculationsRules)"
		+ Common.QueryBatchSeparator() + 
		"SELECT
		|	*
		|INTO ActualData
		|FROM 
		|	FactOnBudgetItems AS FactOnBudgetItems
		|	INNER JOIN RelationshipSettings AS RelationshipSettings
		|	ON FactOnBudgetItems.BudgetFlowItem = RelationshipSettings.BudgetFlowItem
		|
		|INDEX BY
		|	RelationshipSettings.BudgetFlowItem,
		|	RelationshipSettings.BudgetBalanceItem";
	
	// Query to the fact table with settings according to the rules for calculating budget indicators
	CalculationsRules = BudgetItemsByIndicators.UnloadColumn("CalculationRule");
	RequestAccordingToCalculationRules = GenerateRequestToDataSourceAccordingToCalculationRules(CalculationsRules, "Real");
	QueryText = RequestAccordingToCalculationRules.QueryText;
	If IsBlankString(QueryText) Then
		QueryText = GetQueryTextToSourceOfIndicatorDataWithoutCalculationRules();
		QueryText = StrReplace(QueryText, "&ConditionText", "CalculationsRules.Ref IN (&CalculationsRules)");
		TableDetails = RequestSchemes.TableDetails(Type("QuerySchemaTempTableDescription"), "ActualData",
			"AliasOfSourceTable", "BudgetFlowItem", QueryText);
		IConnectionShort = RequestSchemes.IConnectionShort(TableDetails,
			"CalculationsRules.Source = AliasOfSourceTable.BudgetFlowItem",
		QuerySchemaJoinType.LeftOuter);
		QueryText = RequestSchemes.AddConnectionToRequest(QueryText, "CalculationsRules", IConnectionShort);
	EndIf;
	FieldsToAddition = New Array;
	If Parameters.DataAcquisitionRules Then
		FieldsToAddition.Add("AliasOfSourceTable.Rule AS Rule");
	EndIf;
	FieldsToDelete_ = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		FieldToDelete = StringFunctionsClientServer.SubstituteParametersToString("Dimension%1Source1", DimensionNumber);
		FieldsToDelete_.Add(FieldToDelete);
	EndDo;
	If Not Parameters.ByCompanies Then
		QueryText = StrReplace(QueryText, "AliasOfSourceTable.Organization",
		"VALUE(Catalog.Companies.EmptyRef)"); // @query-part
	EndIf;
	If Not Parameters.ByBusinessUnits Then
		QueryText = StrReplace(QueryText, "AliasOfSourceTable.Department",
		"VALUE(Catalog.BusinessStructure.EmptyRef)"); // @query-part
	EndIf;
	If Parameters.ByRegistrar Then
		QueryText = StrReplace(QueryText, "UNDEFINED AS Recorder",
		"AliasOfSourceTable.Recorder AS Recorder"); // @query-part
	EndIf;
	If Parameters.Periodicity <> Undefined Then
		FieldsToAddition.Add("AliasOfSourceTable.Period AS Period");
	EndIf;
	If Parameters.Property("ThereIsPeriodicityOfSecond") And Parameters.ThereIsPeriodicityOfSecond Then
		QueryText = StrReplace(QueryText, "DayPeriod", "SecondPeriod");
	Else
		FieldsToDelete_.Add("DayPeriod");
	EndIf;
	If Parameters.Indicators.Property("Sum") Then
		QueryText = StrReplace(QueryText, "ScenarioAmountTurnover", "Sum");
		QueryText = StrReplace(QueryText, "AmountInCurrencyTurnover", "AmountInCurrency");
		QueryText = StrReplace(QueryText, "SumManTurnover", "AmountInStorageCurrency");
		QueryText = StrReplace(QueryText, "SumComplTurnover", "AmountInFunctionalCurrency");
		FieldsToAddition.Add("AliasOfSourceTable.StorageCurrency AS StorageCurrency");
		FieldsToAddition.Add("AliasOfSourceTable.CurrencyFunctional AS CurrencyFunctional");
		FieldsToAddition.Add("AliasOfSourceTable.RatePeriod AS RatePeriod");
	Else
		FieldsToDelete_.Add("ScenarioAmountTurnover");
		FieldsToDelete_.Add("AmountInCurrencyTurnover");
		FieldsToDelete_.Add("SumManTurnover");
		FieldsToDelete_.Add("SumComplTurnover");
	EndIf;
	If Parameters.Indicators.Property("Count") Then
		QueryText = StrReplace(QueryText, "CountTurnover", "Count");
	Else
		FieldsToDelete_.Add("CountTurnover");
	EndIf;
	QueryText = RequestSchemes.RemoveFieldsFromRequest(QueryText, FieldsToDelete_);
	If FieldsToAddition.Count() > 0 Then
		QueryText = StrReplace(QueryText, Chars.LF + "FROM", // @query-part
		"," + Chars.LF + StrConcat(FieldsToAddition, "," + Chars.LF + Chars.Tab) + Chars.LF + "FROM"); // @query-part
	EndIf;
	
	IndicatorParameterFields = New Array;
	IndicatorParameterFields.Add(
		"AliasOfSourceTable.BudgetBalanceItem.NumberOfUsedDimensions AS NumberOfUsedDimensions");
	IndicatorParameterFields.Add(
		"AliasOfSourceTable.BudgetBalanceItem.CurrencyIsDeterminedByDimension AS CurrencyIsDeterminedByDimension");
	IndicatorParameterFields.Add(
		"AliasOfSourceTable.BudgetBalanceItem.DimensionAddressCurrency AS DimensionAddressCurrency");
	IndicatorParameterFields.Add(
		"AliasOfSourceTable.BudgetBalanceItem.DimensionCurrencies.CurrencyFilling AS DimensionCurrencyField");
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		IndicatorParameterFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"AliasOfSourceTable.BudgetBalanceItem.DimensionKind%1 AS IndicatorBudgetsTypeOfAnalytics%1", DimensionNumber));
	EndDo;
	QueryText = StrReplace(QueryText, Chars.LF + "FROM", // @query-part
		"," + Chars.LF + StrConcat(IndicatorParameterFields, "," + Chars.LF + Chars.Tab) + Chars.LF + "FROM"); // @query-part
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	DataCompositionSettings = New DataCompositionSettings;
	
	// Schema data set
	RequestSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,
		Type("DataCompositionSchemaDataSetQuery"),
		"FactOnItemsThatAffectBudgetPerformance");
	RequestSet.Query = QueryTextTT + Common.QueryBatchSeparator() + QueryText;
	For Each QueryParameter In RequestAccordingToCalculationRules.QueryOptions Do
		DataCompositionServer.AddParameter(DataCompositionSchema, QueryParameter.Key, , QueryParameter.Value,
			True, True);
	EndDo;
	DataCompositionServer.AddParameter(DataCompositionSchema, "FactOnBudgetItems",
		New TypeDescription("ValueTable"), FactOnBudgetItems, True, True);
	DataCompositionServer.AddParameter(DataCompositionSchema, "CalculationsRules",
		New TypeDescription("CatalogRef.RuleForCalculatingRelatedBudgetBalancesAndTurnovers"), CalculationsRules, , True);
	
	AddGroupField(DataCompositionSettings, "BudgetBalanceItem"); 
	
	Resources = New Structure;
	If Parameters.Indicators.Property("Sum") Then
		Resources.Insert("Sum", "AmountInFunctionalCurrency");
		Resources.Insert("SumCurr", "AmountInStorageCurrency");
	EndIf;
	If Parameters.Indicators.Property("Count") Then
		Resources.Insert("Count", "Count");
	EndIf;
	
	For Each Column In FactOnBudgetItems.Columns Do
		If StrFind(QueryText, "AS " + Column.Name) = 0 Then // @query-part
			Continue;
		EndIf;
		FieldName = Column.Name;
		NewField = RequestSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field = FieldName;
		NewField.DataPath = FieldName;
		NewField.ValueType = Column.ValueType;
		NewField.UseRestriction.Condition = True;
		If Not Resources.Property(FieldName) Then
			AddGroupField(DataCompositionSettings, FieldName);
		EndIf;
	EndDo;
	
	If ExpandPeriod Then
		For Each Periodicity In Enums.Periodicity.OrderedPeriodicities() Do
			ThereIsFieldLogger = RequestSet.Fields.Find("Recorder") <> Undefined;
			ThereIsPeriodField = RequestSet.Fields.Find("Period") <> Undefined;
			If Not ValueIsFilled(Periodicity) Then
				Field = "Recorder";
				If ThereIsFieldLogger Then
					Expression = "Recorder";
				Else
					Expression = "UNDEFINED";
				EndIf;
			Else
				Field = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
				If ThereIsPeriodField Then 
					Expression = StringFunctionsClientServer.SubstituteParametersToString(
						"BEGINOFPERIOD(Period, ""%1"")",
						FinancialReportingClientServerCached.PeriodicityByString(Periodicity));
				Else
					Expression = "DATETIME(1,1,1)";
				EndIf;
			EndIf;
			FinancialReportingServer.NewCalculatedField(DataCompositionSchema, Field, Expression);
			AddGroupField(DataCompositionSettings, Field);
		EndDo;
	EndIf;
	
	// Calculated Analytics fields
	AnalyticsExpressions = New Structure;
	ExpressionPattern =
	"CASE
	|	WHEN NumberOfUsedDimensions < %DimensionNumber
	|		THEN %EmptyDimensionValue%
	|	ELSE Dimension%DimensionNumber
	|END";
	ExpressionPattern = StrReplace(ExpressionPattern, "%EmptyDimensionValue%", ExpressingEmptyValue());
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		Expression = StrReplace(ExpressionPattern, "%DimensionNumber", DimensionNumber);
		FieldName = "Dimension" + DimensionNumber;
		FinancialReportingServer.NewCalculatedField(DataCompositionSchema, FieldName, Expression);
		AddGroupField(DataCompositionSettings, FieldName); 
		AnalyticsExpressions.Insert(FieldName, Expression);
	EndDo;
	
	TypesOfViewsTypesOfAnalytics = BudgetingCached.TypesOfViewsTypesOfAnalytics();
	If Parameters.Property("Analysts") Then
		Analysts = Parameters.Analysts;
	Else
		Analysts = TypesOfViewsTypesOfAnalytics.UnloadColumn("Ref");
		Parameters.Insert("Analysts", Analysts);
	EndIf;
	
	TemplateForNamedAnalyticsExpression =
	"CASE
	|	%ConditionByAnalyticsName%
	|	ELSE %EmptyDimensionValue%
	|END";
	TemplateConditionByAnalyticsName =
	"WHEN FinancialReportingCached.NameOfBudgetReportField(%IndicatorBudgetsTypeOfAnalytics%) = ""%NameOfAnalytics%""
	|		THEN %TypeCheckedAnalyticsTranslationExpression%";
	
	For Each LineTypesOfViewsTypesOfAnalytics In TypesOfViewsTypesOfAnalytics Do
		DimensionKind = LineTypesOfViewsTypesOfAnalytics.Ref;
		
		If Analysts.Find(DimensionKind) = Undefined Then
			Continue;
		EndIf;
		
		AnalyticsFieldByType = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		
		If FactOnBudgetItems.Columns.Find(AnalyticsFieldByType) = Undefined Then
			Continue;
		EndIf;
		
		Expression = TemplateForNamedAnalyticsExpression;
		
		ConditionByAnalyticsName = "";
		For MetricAnalyticsNumber = 1 To MaximumNumberOfAnalysts Do
		
			ConditionPart = StrReplace(TemplateConditionByAnalyticsName,
				"%IndicatorBudgetsTypeOfAnalytics%", "IndicatorBudgetsTypeOfAnalytics" + MetricAnalyticsNumber);
			
			TypeCheckedAnalyticsTranslationExpression = StrReplace(ExpressionPattern,
				"%DimensionNumber", MetricAnalyticsNumber);
			ConditionPart = StrReplace(ConditionPart,
				"%TypeCheckedAnalyticsTranslationExpression%",
				TypeCheckedAnalyticsTranslationExpression);
			ConditionByAnalyticsName = ConditionByAnalyticsName
				+ ?(ConditionByAnalyticsName = "", "", " " + Chars.LF + Chars.Tab) + ConditionPart;
		EndDo;
		
		Expression = StrReplace(Expression, "%ConditionByAnalyticsName%", ConditionByAnalyticsName);
		Expression = StrReplace(Expression, "%NameOfAnalytics%", AnalyticsFieldByType);
		
		Expression = StrReplace(Expression, "%EmptyDimensionValue%", ExpressingEmptyValue());
		
		FieldToEval = DataCompositionSchema.CalculatedFields.Add();
		FieldToEval.DataPath = AnalyticsFieldByType;
		FieldToEval.Expression   = Expression;
		FieldToEval.ValueType = LineTypesOfViewsTypesOfAnalytics.ValueType;
		
	EndDo;
	
	TermsAndConditionsForCurrencyAddress = "CASE"; //@Query-part
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TermsAndConditionsForCurrencyAddress = TermsAndConditionsForCurrencyAddress + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"				WHEN DimensionAddressCurrency = %1 THEN %2",
				DimensionNumber,
				AnalyticsExpressions["Dimension" + DimensionNumber]);
	EndDo;
	TermsAndConditionsForCurrencyAddress = TermsAndConditionsForCurrencyAddress + "
	|			END";
	
	ExpressionCurrency =
	"CASE 
	|	WHEN NOT CurrencyIsDeterminedByDimension 
	|		THEN StorageCurrency
	|	ELSE
	|		CAST(BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(
	|			&CacheAnalystValues, 
	|			%1, 
	|			DimensionCurrencyField,
	|			StorageCurrency), %2)
	|	END";
	ExpressionCurrency = StringFunctionsClientServer.SubstituteParametersToString(
		ExpressionCurrency,
		TermsAndConditionsForCurrencyAddress, """" + "Catalog.Currencies" + """");
	FinancialReportingServer.NewCalculatedField(DataCompositionSchema,
			"StorageCurrency",
			ExpressionCurrency,,,
			New TypeDescription("CatalogRef.Currencies"));
	AddGroupField(DataCompositionSettings, "StorageCurrency");
	
	AddParameter(DataCompositionSchema, "CacheAnalystValues", New Map);
	AddParameter(DataCompositionSchema, "Currency", Parameters.ReportCurrency);
	
	ExpressionReceipt = "CASE WHEN Expense THEN 0 ELSE %Field END";
	ExpressionExpense = "CASE WHEN Expense THEN %Field ELSE 0 END";
	
	For Each Resource In Resources Do
		
		ResourceReceipt = Resource.Key + "Receipt";
		FinancialReportingServer.NewCalculatedResource(
			DataCompositionSchema, 
			ResourceReceipt, 
			StrReplace(ExpressionReceipt, "%Field", Resource.Value), 
			"Sum");
		DataCompositionClientServer.AddSelectedField(DataCompositionSettings, ResourceReceipt);
		
		ResourceExpense = Resource.Key + "Expense";
		FinancialReportingServer.NewCalculatedResource(
			DataCompositionSchema, 
			ResourceExpense, 
			StrReplace(ExpressionExpense, "%Field", Resource.Value),
			"Sum");
		DataCompositionClientServer.AddSelectedField(DataCompositionSettings, ResourceExpense);
		
	EndDo;
	
	DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema, DataCompositionSettings, FilterRules_, "Scenario");
	DataCompositionClientServer.DisableOutputOfTotals(DataCompositionSettings);
	
	FactTable = FinancialReportingServer.UploadDCSResults(DataCompositionSchema, DataCompositionSettings);
	
	If Parameters.Indicators.Property("Sum") Then
		DataTableParameters = ParametersForConvertingDataTableToCurrency(FactTable);
		DataTableParameters.TempTablesManager = TempTablesManager;
		DataTableParameters.TempTableName = "TurnoverFactByInfluencingBudgetItems";
		DataTableParameters.IndexFields = "Scenario";
		RecalculationFields = New Array;
		RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
			"SumCurrReceipt", "SumReceipt", "SumReceipt", "SumCurrReceipt"));
		RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
			"SumCurrExpense", "SumExpense", "SumExpense", "SumCurrExpense"));
		ConvertDataTableToCurrency(DataTableParameters, Parameters.ReportCurrency, Parameters.FunctionalCurrency, RecalculationFields);
		FactTable = DataTableParameters.DataTable;
	ElsIf TempTablesManager <> Undefined Then
		Query = New Query(TMCommonUse.QueryTextDataFromValueTable(FactTable,
			"TurnoverFactByInfluencingBudgetItems", "Scenario"));
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("TurnoverFactByInfluencingBudgetItems", FactTable);
		Query.Execute();
	EndIf;
	
	Return FactTable;
	
EndFunction

Function AccountingResourceField(FieldAmount, TotalType) Export
	
	NameTotalType = Common.EnumerationValueName(TotalType);
	If NameTotalType = "Balance_" Then
		If FieldAmount = "Count" Then
			ResourceField = "NumberOfBalance";
		ElsIf FieldAmount = "Sum" Then
			ResourceField = "BalanceAmount";
		ElsIf FieldAmount = "AmountInCurrency" Then
			ResourceField = "AmountInTheBalanceCurrency";
		Else
			ResourceField = StrReplace(FieldAmount + NameTotalType, " ","");
		EndIf;
	ElsIf NameTotalType = "Balance_Dr" Then
		If FieldAmount = "Count" Then
			ResourceField = "NumberOfBalanceDr";
		ElsIf FieldAmount = "Sum" Then
			ResourceField = "BalanceAmountDr";
		ElsIf FieldAmount = "AmountInCurrency" Then
			ResourceField = "AmountInTheBalanceCurrencyDr";
		Else
			ResourceField = StrReplace(FieldAmount + NameTotalType, " ","");
		EndIf;
	ElsIf NameTotalType = "Balance_Cr" Then
		If FieldAmount = "Count" Then
			ResourceField = "NumberOfBalanceCr";
		ElsIf FieldAmount = "Sum" Then
			ResourceField = "BalanceAmountCr";
		ElsIf FieldAmount = "AmountInCurrency" Then
			ResourceField = "AmountInTheBalanceCurrencyCr";
		Else
			ResourceField = StrReplace(FieldAmount + NameTotalType, " ","");
		EndIf;
	Else
		ResourceField = StrReplace(FieldAmount + NameTotalType, " ","");
	EndIf;
	
	Return ResourceField;
	
EndFunction

Procedure AddGroupField(Settings, Field)
	
	If Settings.Structure.Count() = 0 Then
		Group = FinancialReportingServer.NewGrouping(Settings.Structure);
	Else
		Group = Settings.Structure[0];
	EndIf;
	
	FinancialReportingServer.NewDimensionField(Group, Field);
	
EndProcedure

Function AddRowToDataTable(FactTable_, String, Rule)
	
	NewRow = FactTable_.Add();
	FillPropertyValues(NewRow, Rule);
	FillPropertyValues(NewRow, String);
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		If ValueIsFilled(Rule["DimensionKind" + DimensionNumber])
			And Not ValueIsFilled(NewRow["Dimension" + DimensionNumber]) Then
			NewRow["Dimension" + DimensionNumber] = Undefined;
		EndIf;
	EndDo;
	
	Return NewRow;
	
EndFunction

Function AddSetOfNonFinancialIndicatorPeriods(DataCompositionSchema, Parameters, Rule)
	
	PeriodsTable = Parameters.PeriodsTable;
	
	TableOfPeriodsByInstallationDates = New ValueTable;
	TableOfPeriodsByInstallationDates.Columns.Add("Period");
	TableOfPeriodsByInstallationDates.Columns.Add("InstallationPeriod");
	
	If Not Rule.ByPeriods Then
		For Each PeriodTableRow In PeriodsTable Do 
			InstallationPeriod = PeriodTableRow.StartDate;
			While InstallationPeriod < PeriodTableRow.EndDate Do
				NewRow = TableOfPeriodsByInstallationDates.Add();
				NewRow.Period = PeriodTableRow.StartDate;
				NewRow.InstallationPeriod = InstallationPeriod;
				InstallationPeriod = WorkingWithClientServerPeriods.AddInterval(InstallationPeriod, Rule.Periodicity, 1);
			EndDo;
		EndDo;
	Else
		FillInBySubperiod = False;
		If Parameters.Property("SubperiodsTable") Then
			FillInBySubperiod = True;
			TableOfPeriodsByInstallationDates.Columns.Add("SubperiodNumber");
			PeriodsTable = Parameters.SubperiodsTable;
			FinancialReportingServer.NewCalculatedField(DataCompositionSchema, "SubperiodNumber", "SubperiodNumber");
		EndIf;
		For Each PeriodTableRow In PeriodsTable Do
			NewRow = TableOfPeriodsByInstallationDates.Add();
			NewRow.Period = PeriodTableRow.StartDate;
			NewRow.InstallationPeriod = PeriodTableRow.StartDate;
			If FillInBySubperiod Then
				NewRow.InstallationPeriod = PeriodTableRow.InstallationDate;
				NewRow.SubperiodNumber = PeriodTableRow.SubperiodNumber;
			EndIf;
		EndDo;
	EndIf;
	
	SetTableOfPeriodsByInstallationDates = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,
		Type("DataCompositionSchemaDataSetObject"),
		"TableOfPeriodsByInstallationDates");
	SetTableOfPeriodsByInstallationDates.ObjectName = "TableOfPeriodsByInstallationDates";
	
	For Each Column In TableOfPeriodsByInstallationDates.Columns Do
		FieldName = Column.Name;
		NewField = SetTableOfPeriodsByInstallationDates.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field = FieldName;
		NewField.DataPath = FieldName;
	EndDo;
	
	Link = DataCompositionSchema.DataSetLinks.Add();
	Link.SourceDataSet = "TableOfPeriodsByInstallationDates";
	If Parameters.Property("ExpressionStartOfPeriod") Then
		Link.SourceExpression = StrReplace(Parameters.ExpressionStartOfPeriod, "&" + "BEGINOFPERIOD", "INSTALLATIONPERIOD");
	Else
		Link.SourceExpression = "InstallationPeriod";
	EndIf;
	Link.DestinationDataSet = DataCompositionSchema.DataSets[0].Name;
	Link.DestinationExpression = "Period";
	Link.Parameter = "Period";
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("TableOfPeriodsByInstallationDates", TableOfPeriodsByInstallationDates);
	
	Return ExternalDataSets;
	
EndFunction

Function ConvertToDCSExpression(QueryLanguageExpression, Val NumericalExpression = False, Val ExpressionAnalytics = False) Export
	
	DCSExpression = Upper(QueryLanguageExpression); 
	
	TimeIntervals = New Structure;
	TimeIntervals.Insert("DAY",					"""Day""");
	TimeIntervals.Insert("WEEK",					"""Week""");
	TimeIntervals.Insert("TENDAYS",					"""TenDays""");
	TimeIntervals.Insert("MONTH",					"""Month""");
	TimeIntervals.Insert("QUARTER",					"""Quarter""");
	TimeIntervals.Insert("HALFYEAR",				"""HalfYear""");
	TimeIntervals.Insert("YEAR",						"""Year""");
	
	For Each Period In TimeIntervals Do
		// Clarifying the behavior for single-root words
		If Period.Key = "YEAR" And StrFind(DCSExpression, "HALFYEAR") > 0 Then
			Continue;
		EndIf;
		
		DCSExpression = StrReplace(DCSExpression, Period.Key, Period.Value);
	EndDo;
	
	If Not ValueIsFilled(QueryLanguageExpression) Then
		If NumericalExpression Then
			DCSExpression = "0";
		ElsIf ExpressionAnalytics Then
			DCSExpression = ExpressingEmptyValue();
		Else
			DCSExpression = "UNDEFINED";
		EndIf;
	EndIf;
	
	Return DCSExpression;
	
EndFunction

// Returns the template for the actual data table.
// 
// Parameters:
// 	Parameters - Structure - LongDesc:
// * ReportCurrency - CatalogRef.Currencies -
// * CurrencyOfMan - CatalogRef.Currencies -
// * ComplCurrency - CatalogRef.Currencies -
// * InternationalCurrency - CatalogRef.Currencies -
// * Period - StandardPeriod -
// * Periodicity - EnumRef.Periodicity, Undefined -
// * BalancesOnlyAtBeginningOfPeriod - Boolean -
// * ReturnManAndLocalAmounts - Boolean -
// * DataAcquisitionRules - Boolean -
// * Indicators - Structure - structure with properties:
// ** Count - Arbitrary -
// ** Sum - Arbitrary -
// * AddStoredFactForItemsThatAffectBudgetPerformance - Boolean -
// * DimensionKinds - Array of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// * ByCompanies - Boolean -
// * ByBusinessUnits - Boolean -
// * ByRegistrar - Boolean -
// * AdditionalSelection - Structure - structure with properties:
// ** Key - Arbitrary -
// ** Value - Arbitrary -
// Returns:
// 	ValueTable - table with columns:
// * NFPIndex - Number -
// * ID_Source1 - String -
// * BudgetFlowItem - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems -
// * BudgetBalanceItem - CatalogRef.BudgetBalanceItems -
// * NonFinancialItem - CatalogRef.NonFinancialItemsOfBudgets -
// * IndicatorKind - EnumRef.NonFinancialItemKinds -
// * Period - Date -
// * BeginOfPeriod - Date - 
// * EndOfPeriod - Date -
// * Scenario - CatalogRef.BudgetingScenarios -
// * Organization - CatalogRef.Companies -
// * Department - CatalogRef.BusinessStructure -
// * Currency - CatalogRef.Currencies -
// * StorageCurrency - CatalogRef.Currencies -
// * RatePeriod - Date -
// * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure -
// * CountOpeningBalance - Number -
// * SumOpeningBalance - Number -
// * SumCurrOpeningBalance - Number -
// * CountReceipt - Number -
// * SumReceipt - Number -
// * SumCurrReceipt - Number -
// * CountExpense - Number -
// * SumExpense - Number -
// * SumCurrExpense - Number -
// * IndicatorValue - Number -
// * SubperiodNumber - Number -
// * Recorder - DocumentRef -
Function TemplateForDataTableByBudgetType(Parameters)
	
	TypesDetailsDate =  New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date));
	DescriptionOfAnalyticsTypes_  = AllTypesOfAnalytics();
	DescriptionOfTypesQuantity = New TypeDescription("Number", New NumberQualifiers(15,3));
	DescriptionOfSumTypes = TMCommonUse.MoneyFieldTypeDescription();
	DescriptionAndValueOfNonFinancialIndicator = New TypeDescription("Number", New NumberQualifiers(20,6)); 
	
	FactTable_ = New ValueTable;
	
	FactTable_.Columns.Add("NFPIndex", New TypeDescription("Number", New NumberQualifiers(15)));
	FactTable_.Columns.Add("ID_" + "Source1", New TypeDescription("String", , , , New StringQualifiers(50)));
	ArrayOfArticleTypes = New Array;
	ArrayOfArticleTypes.Add(Type("CatalogRef.BudgetFlowItems"));
	ArrayOfArticleTypes.Add(Type("CatalogRef.BudgetBalanceItems"));
	FactTable_.Columns.Add("BudgetFlowItem", New TypeDescription(ArrayOfArticleTypes));
	FactTable_.Columns.Add("BudgetBalanceItem", New TypeDescription("CatalogRef.BudgetBalanceItems"));
	
	FactTable_.Columns.Add("NonFinancialItem", New TypeDescription("CatalogRef.NonFinancialItemsOfBudgets"));
	FactTable_.Columns.Add("IndicatorKind", New TypeDescription("EnumRef.NonFinancialItemKinds"));
	
	If ValueIsFilled(Parameters.Periodicity) Then
		FactTable_.Columns.Add("Period", TypesDetailsDate);
	EndIf;
	
	FactTable_.Columns.Add("BeginOfPeriod", TypesDetailsDate);
	FactTable_.Columns.Add("EndOfPeriod", TypesDetailsDate);
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		FactTable_.Columns.Add("Dimension" + DimensionNumber, DescriptionOfAnalyticsTypes_);
	EndDo;
	For Each DimensionKind In Parameters.DimensionKinds Do
		AnalyticsViewColumn = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		FactTable_.Columns.Add(AnalyticsViewColumn, DescriptionOfAnalyticsTypes_);
	EndDo;
	
	FactTable_.Columns.Add("Scenario", New TypeDescription("CatalogRef.BudgetingScenarios"));
	
	If Parameters.ByCompanies Then
		FactTable_.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	EndIf;
	If Parameters.ByBusinessUnits Then
		FactTable_.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	EndIf;
	
	FactTable_.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	FactTable_.Columns.Add("StorageCurrency", New TypeDescription("CatalogRef.Currencies"));
	FactTable_.Columns.Add("RatePeriod", TypesDetailsDate);
	
	FactTable_.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	FactTable_.Columns.Add("CountOpeningBalance", DescriptionOfTypesQuantity);
	FactTable_.Columns.Add("SumOpeningBalance", DescriptionOfSumTypes);
	FactTable_.Columns.Add("SumCurrOpeningBalance", DescriptionOfSumTypes);
	
	FactTable_.Columns.Add("CountReceipt", DescriptionOfTypesQuantity);
	FactTable_.Columns.Add("SumReceipt", DescriptionOfSumTypes);
	FactTable_.Columns.Add("SumCurrReceipt", DescriptionOfSumTypes);
	
	FactTable_.Columns.Add("CountExpense", DescriptionOfTypesQuantity);
	FactTable_.Columns.Add("SumExpense", DescriptionOfSumTypes);
	FactTable_.Columns.Add("SumCurrExpense", DescriptionOfSumTypes);
	
	FactTable_.Columns.Add("IndicatorValue", DescriptionAndValueOfNonFinancialIndicator);
	FactTable_.Columns.Add("SubperiodNumber", New TypeDescription("Number", New NumberQualifiers(3)));
	
	If Parameters.ByRegistrar Then
		FactTable_.Columns.Add("Recorder");
	EndIf;
	
	Return FactTable_;
	
EndFunction

Function CollectionsThatAreClearedWhenFactIsReceived()
	CollectionsToCleanUp = New Map;
	CollectionsToCleanUp.Insert("CalculatedFields");
	CollectionsToCleanUp.Insert("TotalFields");
	
	Return CollectionsToCleanUp;
EndFunction

Procedure AddSelectionFieldToQueryRecursively(ColumnName, Val ElementOfCombinedFact)
	
	If TypeOf(ElementOfCombinedFact) = Type("DataCompositionSchemaDataSetQuery") Then
		
		ElementOfCombinedFact.Query = RequestSchemes.AddSelectionFieldToQuery(
			ElementOfCombinedFact.Query, 
			"&" + ColumnName, 
			ColumnName, , 
			True, 
			True);
		
	ElsIf TypeOf(ElementOfCombinedFact) = Type("DataCompositionSchemaDataSetUnion") Then
		
		For Each ElementOfCombinedFact In ElementOfCombinedFact.Items Do 
			AddSelectionFieldToQueryRecursively(ColumnName, ElementOfCombinedFact);
		EndDo;
		
	EndIf;

EndProcedure

// Copies all rules for obtaining actual data from an article or indicator of source budgets for an article or indicator of receiver budgets
//
// Parameters:
// Source - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems -
// Receiver - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems -
//
Procedure CopyRulesForGettingActualData(Source, Receiver) Export
	
	If Not ValueIsFilled(Source) Or Not ValueIsFilled(Receiver) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Source", Source);
	Query.Text =
	"SELECT
	|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Ref,
	|	ActualDataQueryRulesByBudgetFlowItems.Description AS Description,
	|	ActualDataQueryRulesByBudgetFlowItems.SettingsComposer AS SettingsComposer,
	|	ActualDataQueryRulesByBudgetFlowItems.DataSourceScheme AS DataSourceScheme
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|WHERE
	|	ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem = &Source";
	If TypeOf(Source) = Type("CatalogRef.BudgetBalanceItems") Then
		Query.Text = StrReplace(Query.Text, "ActualDataQueryRulesByBudgetFlowItems", "ActualDataQueryRulesByBudgetBalanceItems");
		Query.Text = StrReplace(Query.Text, "BudgetFlowItem", "BudgetBalanceItem");
		SourceField = "BudgetBalanceItem";
	Else
		SourceField = "BudgetFlowItem";
	EndIf;
	
	MessageTemplate = NStr("vi = 'Không thể sao chép quy tắc %1 theo nguyên nhân: %2';
							|ru = 'Не удалось скопировать правило %1 по причине: %2';
							|en = 'Cannot copy the %1 rule. Reason: %2'; fa = 'Cannot copy the %1 rule. Reason: %2';
							|it = 'Не удалось скопировать правило %1 по причине: %2';
							|pl = 'Cannot copy the %1 rule. Reason: %2';
							|tr = '%1 kuralı şu nedenden dolayı kopyalanamadı: %2'");
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RuleObject_ = Selection.Ref.Copy();
		RuleObject_[SourceField] = Receiver;
		If TypeOf(Selection.SettingsComposer) = Type("ValueStorage") Then
			RuleObject_.SettingsComposer = New ValueStorage(Selection.SettingsComposer.Get());
		EndIf;
		If TypeOf(Selection.DataSourceScheme) = Type("ValueStorage") Then
			RuleObject_.DataSourceScheme = New ValueStorage(Selection.DataSourceScheme.Get());
		EndIf;
		Try
			RuleObject_.Write();
		Except
			Message = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Selection.Description,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Common.MessageToUser(Message);
		EndTry;
	EndDo;
	
EndProcedure

#EndRegion

#Region StoredBudgetTemplates

Function SavedTemplateFiles(Budget) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetEntryFormAttachedFiles.Ref,
		|	BudgetEntryFormAttachedFiles.ServiceFileType
		|FROM
		|	Catalog.BudgetEntryFormAttachedFiles AS BudgetEntryFormAttachedFiles
		|		INNER JOIN Enum.ServiceFileTypesOfBudgetEntryForm AS ServiceFileTypesOfBudgetEntryForm
		|		ON BudgetEntryFormAttachedFiles.ServiceFileType = ServiceFileTypesOfBudgetEntryForm.Ref
		|WHERE
		|	BudgetEntryFormAttachedFiles.FileOwner = &FileOwner
		|	AND NOT BudgetEntryFormAttachedFiles.DeletionMark";
	
	Query.SetParameter("FileOwner", Budget);
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	Result = New Structure;
	
	While SelectionDetailRecords.Next() Do
		If SelectionDetailRecords.ServiceFileType = Enums.ServiceFileTypesOfBudgetEntryForm.StoredBudget Then
			Result.Insert("StoredBudget", SelectionDetailRecords.Ref);
		ElsIf SelectionDetailRecords.ServiceFileType = Enums.ServiceFileTypesOfBudgetEntryForm.AuxiliaryData Then
			Result.Insert("AuxiliaryData", SelectionDetailRecords.Ref);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the restored structure
// 
// Parameters:
// 	LinkToBudget - DocumentRef.BudgetEntryForm -
// 	BudgetProfile - CatalogRef.BudgetProfiles -
// 	BudgetViewVersion - String - 
// Returns:
// 	Undefined, Structure - Contains:
// 	* BudgetProfile - CatalogRef.BudgetProfiles -
// 	* BudgetViewVersion - String -
// 	* Result - SpreadsheetDocument -
// 	* BudgetProfileDisplayParameters - See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
//
Function RestoreStoredTemplate(LinkToBudget, BudgetProfile, BudgetViewVersion) Export
	
	Files = BudgetingServer.SavedTemplateFiles(LinkToBudget);
	If Not Files.Property("StoredBudget")
		Or Not Files.Property("AuxiliaryData") Then
		Return Undefined;
	EndIf;
	
	AuxiliaryData = FilesOperations.FileBinaryData(Files.AuxiliaryData); // BinaryData
	FileNameAuxiliaryData = GetTempFileName("dat");
	AuxiliaryData.Write(FileNameAuxiliaryData);
	AuxiliaryData = ValueFromFile(FileNameAuxiliaryData);
	
	If TypeOf(AuxiliaryData) <> Type("Structure") Then
		Return Undefined;
	EndIf;
	
	If Not AuxiliaryData.Property("BudgetProfile")
		Or Not AuxiliaryData.Property("BudgetViewVersion") Then
		Return Undefined;
	EndIf;
	
	If AuxiliaryData.BudgetProfile <> BudgetProfile
		Or AuxiliaryData.BudgetViewVersion <> Common.ObjectAttributeValue(BudgetProfile, "DataVersion") Then
		Return Undefined;
	EndIf;
	
	StoredBudget = FilesOperations.FileBinaryData(Files.StoredBudget);
	FileNameStoredBudget = GetTempFileName("mxl");
	StoredBudget.Write(FileNameStoredBudget);
	StoredBudget = New SpreadsheetDocument;
	StoredBudget.Read(FileNameStoredBudget);
	
	RecoveryResult = AuxiliaryData;
	RecoveryResult.Insert("Result", StoredBudget);
	
	OutputParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(
							BudgetProfile, Enums.ModesOfBudgetReportGeneration.Document);
	OutputParameters.Insert("CellDataTableIndexes", New Map);
	RecoveryResult.Insert("BudgetProfileDisplayParameters", OutputParameters);
	
	DeleteFiles(FileNameAuxiliaryData);
	DeleteFiles(FileNameStoredBudget);
	
	Return RecoveryResult;
	
EndFunction

#EndRegion

#Region ConductingBudgetAudits

Function FillCacheOfArticleParameters(ParametersStructure) Export
	
	If ParametersStructure = Undefined Then
		Return New FixedMap(New Map);
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	TableOfArticlesAndIndicators = ParametersStructure.StructureOfReportDescription.CellStructure.Copy(,"BudgetFlowItem");
	TableOfArticlesAndIndicators.GroupBy("BudgetFlowItem");
	
	ArticlesAndTargets = TableOfArticlesAndIndicators.UnloadColumn("BudgetFlowItem");
	
	CommonClientServer.DeleteValueFromArray(ArticlesAndTargets, Catalogs.BudgetFlowItems.EmptyRef());
	CommonClientServer.DeleteValueFromArray(ArticlesAndTargets, Undefined);
	
	ComplianceOfArticlesWithIndicators = New Map;
	
	TextTypesOfArticleAnalytics = "";
	TextTypesOfMetricsAnalytics_ = "";
	TextOfTypicalAnalyticalArticles = "";
	TextTypicalAnalyticsMetrics = "";
	TextFillingCurrencyOfArticles = "";
	TextFillingInCurrencyOfIndicators = "";
	TextAdditionalPropertiesOfArticles = "";
	TextAdditionalPropertiesOfIndicators = "";
	For HotelRoom = 1 To MaximumNumberOfAnalysts Do
		TextTypesOfArticleAnalytics = TextTypesOfArticleAnalytics + ?(TextTypesOfArticleAnalytics = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetFlowItems.DimensionKind%1 AS DimensionKind%1",
				HotelRoom);
		
		TextTypesOfMetricsAnalytics_ = TextTypesOfMetricsAnalytics_ + ?(TextTypesOfMetricsAnalytics_ = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetBalanceItems.DimensionKind%1",
				HotelRoom);
		
		TextOfTypicalAnalyticalArticles = TextOfTypicalAnalyticalArticles + ?(TextOfTypicalAnalyticalArticles = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetFlowItems.DimensionKind%1.ValueType AS DimensionKind%1ValueType",
				HotelRoom);
		
		TextTypicalAnalyticsMetrics = TextTypicalAnalyticsMetrics + ?(TextTypicalAnalyticsMetrics = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetBalanceItems.DimensionKind%1.ValueType",
				HotelRoom);
		
		TextFillingCurrencyOfArticles = TextFillingCurrencyOfArticles + ?(TextFillingCurrencyOfArticles = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetFlowItems.DimensionKind%1.CurrencyFilling AS DimensionKind%1CurrencyFilling",
				HotelRoom);
		
		TextFillingInCurrencyOfIndicators = TextFillingInCurrencyOfIndicators + ?(TextFillingInCurrencyOfIndicators = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetBalanceItems.DimensionKind%1.CurrencyFilling",
				HotelRoom);
		
		TextAdditionalPropertiesOfArticles = TextAdditionalPropertiesOfArticles + ?(TextAdditionalPropertiesOfArticles = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetFlowItems.DimensionKind%1.AdditionalProperty AS DimensionKind%1AdditionalProperty",
				HotelRoom);
		
		TextAdditionalPropertiesOfIndicators = TextAdditionalPropertiesOfIndicators + ?(TextAdditionalPropertiesOfIndicators = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetBalanceItems.DimensionKind%1.AdditionalProperty",
				HotelRoom);
	EndDo;
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	BudgetFlowItems.Ref AS Ref,
	|	&TextTypesOfArticleAnalytics,
	|	&TextOfTypicalAnalyticalArticles,
	|	&TextFillingCurrencyOfArticles,
	|	&TextAdditionalPropertiesOfArticles,
	|	BudgetFlowItems.RecordByQuantity AS RecordByQuantity,
	|	BudgetFlowItems.RecordByCurrency AS RecordByCurrency,
	|	BudgetFlowItems.CurrencyIsDeterminedByDimension AS CurrencyIsDeterminedByDimension,
	|	BudgetFlowItems.DimensionAddressCurrency AS DimensionAddressCurrency,
	|	BudgetFlowItems.NumberOfUsedDimensions AS NumberOfUsedDimensions
	|FROM
	|	Catalog.BudgetFlowItems AS BudgetFlowItems
	|WHERE
	|	BudgetFlowItems.Ref IN(&ArticlesAndTargets)
	|
	|UNION ALL
	|
	|SELECT
	|	BudgetBalanceItems.Ref,
	|	&TextTypesOfMetricsAnalytics_,
	|	&TextTypicalAnalyticsMetrics,
	|	&TextFillingInCurrencyOfIndicators,
	|	&TextAdditionalPropertiesOfIndicators,
	|	BudgetBalanceItems.RecordByQuantity,
	|	BudgetBalanceItems.RecordByCurrency,
	|	BudgetBalanceItems.CurrencyIsDeterminedByDimension,
	|	BudgetBalanceItems.DimensionAddressCurrency,
	|	BudgetBalanceItems.NumberOfUsedDimensions
	|FROM
	|	Catalog.BudgetBalanceItems AS BudgetBalanceItems
	|WHERE
	|	BudgetBalanceItems.Ref IN(&ArticlesAndTargets)
	|";
	Query.Text = StrReplace(Query.Text, "&TextTypesOfArticleAnalytics", TextTypesOfArticleAnalytics);
	Query.Text = StrReplace(Query.Text, "&TextOfTypicalAnalyticalArticles", TextOfTypicalAnalyticalArticles);
	Query.Text = StrReplace(Query.Text, "&TextFillingCurrencyOfArticles", TextFillingCurrencyOfArticles);
	Query.Text = StrReplace(Query.Text, "&TextAdditionalPropertiesOfArticles", TextAdditionalPropertiesOfArticles);
	Query.Text = StrReplace(Query.Text, "&TextTypesOfMetricsAnalytics_", TextTypesOfMetricsAnalytics_);
	Query.Text = StrReplace(Query.Text, "&TextTypicalAnalyticsMetrics", TextTypicalAnalyticsMetrics);
	Query.Text = StrReplace(Query.Text, "&TextFillingInCurrencyOfIndicators", TextFillingInCurrencyOfIndicators);
	Query.Text = StrReplace(Query.Text, "&TextAdditionalPropertiesOfIndicators", TextAdditionalPropertiesOfIndicators);
	
	Query.SetParameter("ArticlesAndTargets", ArticlesAndTargets);
	
	AttributesTable = Query.Execute().Unload();
	
	For Each ArticleIndicatorOfBudgets In ArticlesAndTargets Do
		
		ArticleDetails_1 = New Structure;
		RowOfDetailsTable = AttributesTable.Find(ArticleIndicatorOfBudgets, "Ref");
		For Each Column In AttributesTable.Columns Do
			If Column.Name = "Ref" Then
				Continue;
			EndIf;
			ArticleDetails_1.Insert(Column.Name, RowOfDetailsTable[Column.Name]);
		EndDo;
		
		If ArticleDetails_1.RecordByCurrency Then
			If ArticleDetails_1.CurrencyIsDeterminedByDimension Then
				TypeOfAnalyticsCurrency = "DimensionKind" + ArticleDetails_1.DimensionAddressCurrency;
				AttributeName = ArticleDetails_1[TypeOfAnalyticsCurrency + "CurrencyFilling"];
				ArticleDetails_1.Insert("PathToCurrencyAnalytics", AttributeName);
				ArticleDetails_1.Insert("NameAndCurrency", FinancialReportingCached.NameOfBudgetReportField(ArticleDetails_1[TypeOfAnalyticsCurrency]));
				ArticleDetails_1.Insert("TypeOfAnalyticsCurrency", ArticleDetails_1[TypeOfAnalyticsCurrency]);
			EndIf;
		EndIf;
		
		StructureOfTypesOfAnalytics = New Structure;
		For Cnt = 1 To ArticleDetails_1.NumberOfUsedDimensions Do
			DimensionKind = ArticleDetails_1["DimensionKind" + Cnt];
			NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			StructureOfTypesOfAnalytics.Insert(NameOfAnalytics, DimensionKind);
		EndDo;
		
		ComplianceOfArticlesWithIndicators.Insert(ArticleIndicatorOfBudgets, ArticleDetails_1);
		
	EndDo;
	
	Return New FixedMap(ComplianceOfArticlesWithIndicators);
	
EndFunction

Procedure PutDocumentInQueue(Document) Export
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		LockItem = Block.Add("Constant.NumberOfJobForRecordingBudgetEntryForms");
		LockItem.Mode = DataLockMode.Shared;
		Block.Lock();
		
		JobNumber = Constants.NumberOfJobForRecordingBudgetEntryForms.Get();
		
		Record = InformationRegisters.JobsForPostingBudgetEntryForms.CreateRecordManager();
		Record.Document = Document;
		Record.JobNumber = JobNumber;
		Record.Write();
	
		CommitTransaction();
	Except
		RollbackTransaction();
		LREvent = NStr("vi = 'Trì hoãn kết chuyển chứng từ nhập các chỉ tiêu ngân sách';
						|ru = 'Отложенное проведение экземпляров бюджета';
						|en = 'Deferred posting of Budget entry forms'; fa = 'ثبت قطعی معوق فرم‌های ورود بودجه';
						|it = 'Registrazione del documento di inserimento del budget sospesa';
						|pl = 'Odłożone księgowanie egzemplarzy budżetu';
						|tr = 'Bütçe giriş formunun kaydedilmesinin ertelenmesi'", Common.DefaultLanguageCode());
		WriteLogEvent(
			LREvent, 
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

Procedure ExecuteDeferredBudgetInstances(Ref=Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DeferredPostingOfBudgetEntryForms);
	
	SetPrivilegedMode(True);

	BeginTransaction();
	
	Try
		Block = New DataLock;
		LockItem = Block.Add("Constant.NumberOfJobForRecordingBudgetEntryForms");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		JobNumber = Constants.NumberOfJobForRecordingBudgetEntryForms.Get();
		Constants.NumberOfJobForRecordingBudgetEntryForms.Set(JobNumber + 1);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		LREvent = NStr("vi = 'Trì hoãn kết chuyển chứng từ nhập các chỉ tiêu ngân sách';
						|ru = 'Отложенное проведение экземпляров бюджета';
						|en = 'Deferred posting of Budget entry forms'; fa = 'ثبت قطعی معوق فرم‌های ورود بودجه';
						|it = 'Registrazione del documento di inserimento del budget sospesa';
						|pl = 'Odłożone księgowanie egzemplarzy budżetu';
						|tr = 'Bütçe giriş formunun kaydedilmesinin ertelenmesi'", Common.DefaultLanguageCode());
		WriteLogEvent(
			LREvent, 
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	JobsForPostingBudgetEntryForms.JobNumber AS JobNumber,
		|	JobsForPostingBudgetEntryForms.Document,
		|	JobsForPostingBudgetEntryForms.Document.BudgetProfile AS BudgetProfile,
		|	JobsForPostingBudgetEntryForms.Document.BudgetProfile.SaveBudgetInTabularFormToBudgetEntryForm AS SaveBudgetInTabularFormToBudgetEntryForm,
		|	JobsForPostingBudgetEntryForms.Document.BudgetProfile.GenerateRelatedBudgetTurnovers AS GenerateRelatedBudgetTurnovers,
		|	JobsForPostingBudgetEntryForms.Document.BudgetProfile.DataVersion AS DataVersion,
		|	JobsForPostingBudgetEntryForms.Document.Scenario.Currency AS Currency,
		|	JobsForPostingBudgetEntryForms.DocumentIsPostedPendingValidation
		|FROM
		|	InformationRegister.JobsForPostingBudgetEntryForms AS JobsForPostingBudgetEntryForms
		|WHERE
		|	JobsForPostingBudgetEntryForms.JobNumber <= &JobNumber
		|	AND (&Ref = UNDEFINED
		|			OR JobsForPostingBudgetEntryForms.Document = &Ref)
		|
		|ORDER BY
		|	JobNumber DESC";
	
	Query.SetParameter("JobNumber", JobNumber);
	Query.SetParameter("Ref",Ref);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	ComplianceOfProcessedDocuments = New Map;
	
	While Selection.Next() Do
		
		If ComplianceOfProcessedDocuments[Selection.Document] = True Then
			RecordSet = InformationRegisters.JobsForPostingBudgetEntryForms.CreateRecordSet();
			RecordSet.Filter.JobNumber.Set(Selection.JobNumber);
			RecordSet.Filter.Document.Set(Selection.Document);
			RecordSet.Write();
		EndIf;
		
		If Ref = Undefined Then
			Var_Key = "DeferredPostingOfBudgetEntryForms" + String(Selection.Document.UUID());
		
			Filter = New Structure();
			Filter.Insert("Key", Var_Key);
			Filter.Insert("State", BackgroundJobState.Active);
			
			ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
			
			If ActiveTasks.Count() > 0 Then
				For Each ActiveTask In ActiveTasks Do
					ActiveTask.Cancel();
				EndDo;
			EndIf;
		EndIf;
		
		NeedAdditionalObjectProcessing = False;
		
		Ref = Selection.Document;
		
		TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(Selection.Document, "BudgetTurnovers, LimitsByBudgetingData");
		
		RegisterRecords = New Structure("BudgetTurnovers");
		GainingMomentum = AccumulationRegisters.BudgetTurnovers.CreateRecordSet();
		GainingMomentum.Filter.Recorder.Set(Ref);
		RegisterRecords.BudgetTurnovers = GainingMomentum;
		
		ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, False);
		
		GainingMomentum = RegisterRecords.BudgetTurnovers; // AccumulationRegisterRecordSet.BudgetTurnovers -
		GainingMomentum.Write(True);
		
		RegisterRecords = New Structure("LimitsByBudgetingData");
		SetOfLimitsBasedOnBudgetingData = AccumulationRegisters.LimitsByBudgetingData.CreateRecordSet();
		SetOfLimitsBasedOnBudgetingData.Filter.Recorder.Set(Ref);
		RegisterRecords.LimitsByBudgetingData = SetOfLimitsBasedOnBudgetingData;
		
		LimitsByBudgetingDataServer.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, False);
		
		SetOfLimitsBasedOnBudgetingData = RegisterRecords.LimitsByBudgetingData; // AccumulationRegisterRecordSet.LimitsByBudgetingData -
		SetOfLimitsBasedOnBudgetingData.Write(True);
		
		ComplianceOfProcessedDocuments.Insert(Selection.Document, True);
		
		If NeedAdditionalObjectProcessing Then
			RecordSet = InformationRegisters.JobsForPostingBudgetEntryForms.CreateRecordSet();
			RecordSet.Filter.JobNumber.Set(Selection.JobNumber);
			RecordSet.Filter.Document.Set(Selection.Document);
			RecordSet.Read();
			For Each Record In RecordSet Do
				Record.DocumentIsPostedPendingValidation = True;
			EndDo;
			RecordSet.Write();
		Else
			RecordSet = InformationRegisters.JobsForPostingBudgetEntryForms.CreateRecordSet();
			RecordSet.Filter.JobNumber.Set(Selection.JobNumber);
			RecordSet.Filter.Document.Set(Selection.Document);
			RecordSet.Write();
		EndIf;
		
		If Selection.GenerateRelatedBudgetTurnovers Then
			UniversalQueueOfRealTimeJobs.ProcessTask_(Selection.Document,
				Enums.UniversalQueueTasks.GenerationOfRelatedBudgetTurnovers);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure StartDeferredExecutionWithBackgroundTask(Ref) Export
	
	SetPrivilegedMode(True);
	
	Var_Key = "DeferredPostingOfBudgetEntryForms" + String(Ref.UUID());
	
	Filter = New Structure();
	Filter.Insert("Key", Var_Key);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If ActiveTasks.Count() > 0 Then
		For Each ActiveTask In ActiveTasks Do
			ActiveTask.Cancel();
		EndDo;
	EndIf;
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	If ActiveTasks.Count() > 0 Then
		Return;
	EndIf;
	
	JobDescription = NStr("vi = 'Trường hợp ngân sách hoãn lại đang chạy';
							|ru = 'Выполняется отложенное проведение экземпляров бюджета';
							|en = 'Deferred posting of Budget entry forms is in progress'; fa = 'Deferred posting of Budget entry forms is in progress';
							|it = 'Sta venendo eseguita la registrazione rimandata di inserimento del budget';
							|pl = 'Jest wykonywane odłożone księgowanie egzemplarzy budżetu';
							|tr = 'Bütçe giriş formunun kaydedilmesinin ertelenmesi gerçekleştiriliyor'");
	
	ExportProcedureParameters = New Array();
	ExportProcedureParameters.Add(Ref);
	
	JobParameters = New Array();
	JobParameters.Add("BudgetingServer.ExecuteDeferredBudgetInstances");
	JobParameters.Add(ExportProcedureParameters);
	
	BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
	
EndProcedure

// Checks the contents of the table parts of the budget instance and adjusts them
//
// Parameters:
// 	ObjectData - DocumentObject.BudgetEntryForm - object being checked and modified
// 	              - FormDataStructure - the object being checked and modified from the document form
// 	ObjectAndCalculationParameters - Structure - the parameters of the budget, including a copy of the object in the form of Dniepropetrowsk
// 	Budget - SpreadsheetDocument - tabular form of the budget that is used to check the use of Analytics using the values of the transcripts in the cells
// 	DetailsData - Arbitrary -
//
Procedure CheckFixTSInstanceBudget(ObjectData, ObjectAndCalculationParameters, Budget, DetailsData) Export
	
	// To bring the types of PM columns of the State Budget analyst in line with the types of budget type analysts.
	If ObjectData.BudgetFlowItemsDimension.Count() > 0 Then
		ItemParameterCache = ObjectAndCalculationParameters.ItemParameterCache; // FixedMap
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		
		For Each AnalyticsAndBudgetsLine In ObjectData.BudgetFlowItemsDimension Do
			ArticleParameters = ItemParameterCache.Get(AnalyticsAndBudgetsLine.BudgetFlowItem);
			If ArticleParameters = Undefined Then
				Continue;
			EndIf;
			For Cnt = 1 To MaximumNumberOfAnalysts Do
				// If the analytics type is not used in the analytics views, the value will be cleared
				// For example, in a situation when the composition of the budget type analytics was changed.
				DimensionKind = ArticleParameters["DimensionKind" + Cnt];
				If ValueIsFilled(DimensionKind) Then
					Value = BudgetingClientServer.ReducedAnalyticsValue(AnalyticsAndBudgetsLine["Dimension" + Cnt],
							DimensionKind.ValueType);
				Else
					Value = BudgetingClientServer.EmptyDimensionValue();
				EndIf;
				AnalyticsAndBudgetsLine["Dimension" + Cnt] = Value;
			EndDo;
		EndDo;
		
		If TypeOf(ObjectData) = Type("DocumentObject.BudgetEntryForm") Then
			ValueToFormData(ObjectData, ObjectAndCalculationParameters.Object);
		EndIf;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	Object = ObjectAndCalculationParameters.Object; // DocumentObject.BudgetEntryForm -
	TablePartsCache = New Structure;
	
	TablePartCache = Object.BudgetFlowItemsDimension.Unload();
	ColumnNamesIndex = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ColumnNamesIndex = ColumnNamesIndex + ?(ColumnNamesIndex = "", "", ",") + "Dimension" + DimensionNumber;
	EndDo;
	ColumnNamesIndex = ColumnNamesIndex + ",BudgetFlowItem,Currency";
	TablePartCache.Indexes.Add(ColumnNamesIndex);
	
	TablePartsCache.Insert("BudgetFlowItemsDimension", TablePartCache);
	
	TablePartCache = Object.DimensionValues_.Unload();
	ColumnNamesIndex = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ColumnNamesIndex = ColumnNamesIndex + ?(ColumnNamesIndex = "", "", ",") + "Dimension" + DimensionNumber
			+ "," + "DimensionKind" + DimensionNumber;
	EndDo;
	ColumnNamesIndex = ColumnNamesIndex + ",EditedValue,NumberOfUsedDimensions";
	TablePartCache.Indexes.Add(ColumnNamesIndex);
	TablePartsCache.Insert("DimensionValues_", TablePartCache);
	
	// Bring PM in line with the tabular document
	MatchingFoundIDs = New Map;
	For XCoordinate = 1 To Budget.TableWidth Do
		For YCoordinate = 1 To Budget.TableHeight Do
			Details = Budget.Area(YCoordinate, XCoordinate).Details;
			Details = DetailsData[Details];
			If TypeOf(Details) = Type("Structure") Then
				Details = BudgetReportingClientServer.ConvertDecryption(ObjectAndCalculationParameters, Details, True);
				If Details = Undefined Then
					Continue;
				EndIf;
				RowID = IDOfBudgetItemAnalytics(ObjectAndCalculationParameters,
					TablePartsCache, Details);
				If RowID <> Undefined Then
					ArrayOfPeriods = MatchingFoundIDs[RowID];
					If ArrayOfPeriods = Undefined Then
						ArrayOfPeriods = New Array;
						MatchingFoundIDs.Insert(RowID, ArrayOfPeriods);
					EndIf;
					ArrayOfPeriods.Add(Details.PlanningPeriod);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	ArrayOnDelete = New Array;
	For Each TableRow In ObjectData.BudgetFlowItemsDimension Do
		If MatchingFoundIDs[TableRow.RowID] = Undefined Then
			ArrayOnDelete.Add(New Structure("Table, String", "BudgetFlowItemsDimension", TableRow));
		EndIf;
	EndDo;
	For Each TableRow In ObjectData.DimensionValues_ Do
		If MatchingFoundIDs[TableRow.RowID] = Undefined Then
			ArrayOnDelete.Add(New Structure("Table, String", "DimensionValues_", TableRow));
		EndIf;
	EndDo;
	
	For Each TableRow In ObjectData.BudgetFlowItemTurnovers Do
		ArrayOfPeriods = MatchingFoundIDs[TableRow.RowID];
		If ArrayOfPeriods = Undefined Then
			ArrayOnDelete.Add(New Structure("Table, String", "BudgetFlowItemTurnovers", TableRow));
			Continue;
		EndIf;
		If ArrayOfPeriods.Find(TableRow.PlanningPeriod) = Undefined Then
			ArrayOnDelete.Add(New Structure("Table, String", "BudgetFlowItemTurnovers", TableRow));
		EndIf;
	EndDo;
	
	For Each TableAndRow In ArrayOnDelete Do
		TabularSection = ObjectData[TableAndRow.Table]; // TabularSection -
		TabularSection.Delete(TableAndRow["String"]);
	EndDo;
	
EndProcedure

// Gets the row ID of the table part of the budget instance based on the decryption data.
// Is the optimization method Budgetautoinsurance.Identoranalitikistatebudget.
//
// Parameters:
// 	ObjectAndCalculationParameters - Structure - the parameters of the budget, including a copy of the object in the form of Dniepropetrowsk:
// 	 *ScenarioCurrency - CatalogRef.Currencies - Currency of the script.
// 	TablePartsCache - Structure - The structure containing the unloaded and indexed tabular parts of the document:
// 	 *BudgetFlowItemsDimension - ValueTable - the unloaded tabular part of the budget analyticstatistics:
// 	  **RowID - String -
// 	  **BudgetFlowItem - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems -
// 	  **Dimension1 - Characteristic.BudgetFlowItemDimensions -
// 	  **Dimension2 - Characteristic.BudgetFlowItemDimensions -
// 	  **Dimension3 - Characteristic.BudgetFlowItemDimensions -
// 	  **Dimension4 - Characteristic.BudgetFlowItemDimensions -
// 	  **Dimension5 - Characteristic.BudgetFlowItemDimensions -
// 	  **Dimension6 - Characteristic.BudgetFlowItemDimensions -
// 	  **Currency - CatalogRef.Currencies -
// 	 *DimensionValues_ - ValueTable - the unloaded tabular part of the analyticreferences:
// 	  **RowID - String -
// 	  **EditedValue - String -
// 	  **DimensionKind1 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	  **DimensionKind2 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	  **DimensionKind3 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	  **DimensionKind4 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	  **DimensionKind5 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	  **DimensionKind6 - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	  **Dimension1 - Characteristic.BudgetFlowItemDimensions -
// 	  **Dimension2 - Characteristic.BudgetFlowItemDimensions -
// 	  **Dimension3 - Characteristic.BudgetFlowItemDimensions -
// 	  **Dimension4 - Characteristic.BudgetFlowItemDimensions -
// 	  **Dimension5 - Characteristic.BudgetFlowItemDimensions -
// 	  **Dimension6 - Characteristic.BudgetFlowItemDimensions -
// 	  **NumberOfUsedDimensions - Number -
//
Function IDOfBudgetItemAnalytics(ObjectAndCalculationParameters, TablePartsCache, SearchData_)
	RowID = Undefined;
	
	ScenarioCurrency = ObjectAndCalculationParameters.ScenarioCurrency;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	TheStructureOfTheSearch = New Structure;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TheStructureOfTheSearch.Insert("Dimension" + DimensionNumber);
	EndDo;
	
	If SearchData_.Property("BudgetFlowItem") Then
		TheStructureOfTheSearch.Insert("BudgetFlowItem");
		TheStructureOfTheSearch.Insert("Currency");
		TablePartCache = TablePartsCache.BudgetFlowItemsDimension;
	Else
		TheStructureOfTheSearch.Insert("EditedValue");
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			TheStructureOfTheSearch.Insert("DimensionKind" + Cnt);
		EndDo;
		TablePartCache = TablePartsCache.DimensionValues_;
	EndIf;
	
	FillPropertyValues(TheStructureOfTheSearch, SearchData_);
	
	If SearchData_.Property("BudgetFlowItem") Then
		If TypeOf(SearchData_) = Type("Structure") Then
			If SearchData_.Property("Currency") Then
				If SearchData_.Currency = Undefined Then
					TheStructureOfTheSearch.Delete("Currency");
				Else
					TheStructureOfTheSearch.Currency = SearchData_.Currency;
				EndIf;
			Else
				TheStructureOfTheSearch.Currency = ScenarioCurrency;
			EndIf;
		Else
			TheStructureOfTheSearch.Currency = ScenarioCurrency;
		EndIf;
	Else
		MaximumNumberOfAnalytics = 0;
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			If ValueIsFilled(TheStructureOfTheSearch["DimensionKind" + Cnt]) Then
				MaximumNumberOfAnalytics = Cnt;
			EndIf;
		EndDo;
		TheStructureOfTheSearch.Insert("NumberOfUsedDimensions", MaximumNumberOfAnalytics);
	EndIf;
	
	SearchResult = TablePartCache.FindRows(TheStructureOfTheSearch);
	If SearchResult.Count() <> 0 Then
		RowID = SearchResult[0].RowID;
	EndIf;
	
	Return RowID;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	TemplateForStorage - SpreadsheetDocument -
// 	AuxiliaryData - Structure - Contains:
//		* CellData_ - ValueTable -
//		* DetailsData - DataCompositionDetailsData -
//		* TreeOfEditListRows - ValueTree -
//		* BudgetViewVersion - String -
//		* BudgetProfile - CatalogRef.BudgetProfiles - 
//		* TableColumns - See BudgetReportingCacheCalculationServer.ColumnsOfDataTable_
//		* LevelStyle - Structure - LongDesc:
//			** Value - See BudgetReportingDisplayServer.GetCacheOfEditingListLineStyles
// 	LinkToBudget - DocumentRef.BudgetEntryForm - 
Procedure SaveStoredTemplate(TemplateForStorage, AuxiliaryData, LinkToBudget) Export
	
	TemplateFileName = GetTempFileName("mxl");
	TemplateForStorage.Write(TemplateFileName, SpreadsheetDocumentFileType.MXL);
	TemplateStorage = PutToTempStorage(New BinaryData(TemplateFileName));
	
	AuxiliaryDataFileName = GetTempFileName("dat");
	ValueToFile(AuxiliaryDataFileName, AuxiliaryData);
	AuxiliaryDataStorage = PutToTempStorage(New BinaryData(AuxiliaryDataFileName));
	
	SavedFiles = SavedTemplateFiles(LinkToBudget);
	FileParameters = New Structure;
	FileParameters.Insert("UniversalModificationDate", CurrentUniversalDate());
	FileParameters.Insert("TempTextStorageAddress", Undefined);
	FileParameters.Insert("Author", Users.AuthorizedUser());
	FileParameters.Insert("FilesOwner", LinkToBudget);
	FileParameters.Insert("ModificationTimeUniversal", Undefined);

	File = Undefined;
	If SavedFiles.Property("StoredBudget", File) Then
		FileParameters.Insert("FileAddressInTempStorage", TemplateStorage);
		FilesOperations.RefreshFile(File, FileParameters);
	Else
		FileParameters.Insert("BaseName", NStr("vi = 'Ngân sách';
												|ru = 'Бюджет';
												|en = 'Budget'; fa = 'بودجه';
												|it = 'Budget';
												|pl = 'Budget';
												|tr = 'Bütçe'"));
		FileParameters.Insert("ExtensionWithoutPoint", "mxl");
		File = FilesOperations.AppendFile(FileParameters, TemplateStorage, Undefined);
		FileObject1 = File.GetObject();
		FileObject1.ServiceFileType = Enums.ServiceFileTypesOfBudgetEntryForm.StoredBudget;
		FileObject1.Write();
	EndIf;
	
	If SavedFiles.Property("AuxiliaryData", File) Then
		FileParameters.Insert("FileAddressInTempStorage", AuxiliaryDataStorage);
		FilesOperations.RefreshFile(File, FileParameters);
	Else
		FileParameters.Insert("BaseName", NStr("vi = 'Dữ liệu ngân sách phụ trợ';
												|ru = 'Вспомогательные данные бюджета';
												|en = 'Auxiliary budget data'; fa = 'Auxiliary budget data';
												|it = 'Dati ausiliari del budget';
												|pl = 'Pomocnicze dane budżetu';
												|tr = 'Bütçe servis bilgileri'"));
		FileParameters.Insert("ExtensionWithoutPoint", "dat");
		File = FilesOperations.AppendFile(FileParameters, AuxiliaryDataStorage, Undefined);
		FileObject1 = File.GetObject();
		FileObject1.ServiceFileType = Enums.ServiceFileTypesOfBudgetEntryForm.AuxiliaryData;
		FileObject1.Write();
	EndIf;
	
	DeleteFiles(TemplateFileName);
	DeleteFiles(AuxiliaryDataFileName);
	
EndProcedure

#EndRegion

#Region GettingDataOnArticlesAndIndicators

Function GetRulesForCalculatingBudgetMetrics(RuleSelectionSettings) Export
	
	QueryText = 
	"SELECT
	|	CalculationsRules.Ref AS CalculationRule,
	|	CAST(CalculationsRules.Source AS Catalog.BudgetFlowItems) AS BudgetFlowItem,
	|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems) AS BudgetBalanceItem
	|FROM
	|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|WHERE
	|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).IndicatorType = VALUE(Enum.BudgetBalanceItemType.Estimated_)
	|	AND NOT CalculationsRules.DeletionMark
	|	AND CalculationsRules.Status = VALUE(Enum.BudgetingRuleStatuses.Valid)
	|{WHERE
	|	(CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems)).* AS BudgetBalanceItem,
	|	(CAST(CalculationsRules.Source AS Catalog.BudgetFlowItems)).* AS BudgetFlowItem}";
	DCSCalculationRules = DataCompositionServer.DataCompositionSchemaForQueryText(QueryText);
	
	Settings = New DataCompositionSettings;
	DataCompositionClientServer.AddGrouping(Settings);
	DataCompositionClientServer.AddSelectedField(Settings, "CalculationRule");
	DataCompositionClientServer.AddSelectedField(Settings, "BudgetFlowItem");
	DataCompositionClientServer.AddSelectedField(Settings, "BudgetBalanceItem");
	DataCompositionClientServer.CopyDataCompositionFilter(DCSCalculationRules, Settings, RuleSelectionSettings);
	
	Return FinancialReportingServer.UploadDCSResults(DCSCalculationRules, Settings);
	
EndFunction

Function GenerateRequestToDataSourceAccordingToCalculationRules(CalculationsRules, SourceIdentificator) Export
	
	RequestAccordingToCalculationRules = New Structure;
	RequestAccordingToCalculationRules.Insert("QueryText", "");
	RequestAccordingToCalculationRules.Insert("QueryTextTT", "");
	RequestAccordingToCalculationRules.Insert("QueryOptions", New Structure);
	RequestAccordingToCalculationRules.Insert("SourcesTypes", New Array);
	
	QueryTextsAccordingToCalculationRules = New Array;
	QueryTextsOfTTAccordingToCalculationRules = New Array;
	
	TextsExpressionsBudgetFlowItemSource = New Map;
	TextsExpressionsBudgetFlowItemReceiver = New Map;
	
	QueryTextForecastExchangeRates = "";
	QueryTextPartnersCounterparties = "";
	
	DistributionBasesAccordingToCalculationRules = New Array;
	CalculationRuleIds = New Map;
	DataOnCalculationRules = Common.ObjectsAttributesValues(CalculationsRules, "RequestStorage, SourceType");
	For Counter = 1 To CalculationsRules.Count() Do
		CalculationRule = CalculationsRules[Counter - 1];
		DataOnCalculationRule = DataOnCalculationRules.Get(CalculationRule);
		If Not ValueIsFilled(DataOnCalculationRule.SourceType) Then
			Continue;
		EndIf;
		RequestBasedOnCalculationRule = DataOnCalculationRule.RequestStorage.Get();
		If TypeOf(RequestBasedOnCalculationRule) = Type("Structure") Then
			AddQueriesTexts = True;
			RuleID = "";
			If StrFind(RequestBasedOnCalculationRule.SourceIdentificator, "SourceType_") > 0 Then
				RuleID = StrReplace(String(CalculationRule.UUID()), "-", "");
				SourceType = StrReplace(RequestBasedOnCalculationRule.SourceIdentificator, "SourceType_", "");
			Else
				MatchingSourcesReceivers = CalculationRuleIds.Get(RequestBasedOnCalculationRule.RuleID);
				If MatchingSourcesReceivers <> Undefined Then
					If MatchingSourcesReceivers.Get(RequestBasedOnCalculationRule.SourceIdentificator) <> Undefined Then
						// You need to replace the rule ID because a request for another receiver has already been processed based on the rule source
						RuleID = StrReplace(String(CalculationRule.UUID()), "-", "");
					Else
						AddQueriesTexts = False;
					EndIf;
				EndIf;
				SourceType = "BudgetTurnovers";
			EndIf;
			If RequestAccordingToCalculationRules.SourcesTypes.Find(SourceType) = Undefined Then
				RequestAccordingToCalculationRules.SourcesTypes.Add(SourceType);
			EndIf;
			
			If AddQueriesTexts Then
				QueryTextAccordingToCalculationRule = ?(Counter = 1, RequestBasedOnCalculationRule.QueryText, StrReplace(
					RequestBasedOnCalculationRule.QueryText, "INTO Data", ""));
				If SourceIdentificator = "Plan" Or SourceIdentificator = "StoredFact" Then
					QueryTextAccordingToCalculationRule = StrReplace(QueryTextAccordingToCalculationRule, ") AS AliasOfSourceTable",
						" AND &SourceTableConditionsAndAlignmentFields) AS AliasOfSourceTable");
					If SourceType <> "BudgetTurnovers" Then
						QueryTextAccordingToCalculationRule = StrReplace(QueryTextAccordingToCalculationRule,
						"&SourceTableConditionsAndAlignmentFields", "&SourceTableConditionsAndAlignmentFields_" + SourceType);
					EndIf;
				EndIf;
				If Not IsBlankString(RuleID) Then
					QueryTextAccordingToCalculationRule = StrReplace(QueryTextAccordingToCalculationRule,
						RequestBasedOnCalculationRule.RuleID, RuleID);
					QueryTextAccordingToCalculationRule = StrReplace(QueryTextAccordingToCalculationRule,
						"Source_" + RuleID, RequestBasedOnCalculationRule.SourceIdentificator);
					If SourceIdentificator = "Real" Then
						QueryTextAccordingToCalculationRule = StrReplace(QueryTextAccordingToCalculationRule,
							"&Receiver_" + RuleID, StringFunctionsClientServer.SubstituteParametersToString(
							"CASE WHEN AliasOfSourceTable.BudgetFlowItem = &%1 THEN &%2 END", //@ query-part
							RequestBasedOnCalculationRule.SourceIdentificator, RequestBasedOnCalculationRule.ReceiverId)); 
					Else
						QueryTextAccordingToCalculationRule = StrReplace(QueryTextAccordingToCalculationRule,
							"Receiver_" + RuleID, RequestBasedOnCalculationRule.ReceiverId);
					EndIf;
				EndIf;
				QueryTextsAccordingToCalculationRules.Add(QueryTextAccordingToCalculationRule);
				For Each KeyAndValue In RequestBasedOnCalculationRule.QueryTextsOfDistributionDatabase Do
					If DistributionBasesAccordingToCalculationRules.Find(KeyAndValue.Key) = Undefined Then
						QueryTextsOfTTAccordingToCalculationRules.Add(KeyAndValue.Value);
						DistributionBasesAccordingToCalculationRules.Add(KeyAndValue.Key);
					EndIf;
				EndDo;
				If Not IsBlankString(RequestBasedOnCalculationRule.QueryTextForecastExchangeRates) Then
					If IsBlankString(QueryTextForecastExchangeRates) Then
						QueryTextForecastExchangeRates = RequestBasedOnCalculationRule.QueryTextForecastExchangeRates;
					ElsIf StrFind(QueryTextForecastExchangeRates, "&BeginOfPeriod") > 0
						And StrFind(RequestBasedOnCalculationRule.QueryTextForecastExchangeRates, "&BeginOfPeriod") = 0 Then
						QueryTextForecastExchangeRates = RequestBasedOnCalculationRule.QueryTextForecastExchangeRates;
					EndIf;
				EndIf;
				If Not IsBlankString(RequestBasedOnCalculationRule.QueryTextPartnersCounterparties) Then
					If IsBlankString(QueryTextPartnersCounterparties) Then
						QueryTextPartnersCounterparties = RequestBasedOnCalculationRule.QueryTextPartnersCounterparties;
					ElsIf StrFind(QueryTextPartnersCounterparties, "&BeginOfPeriod") > 0
						And StrFind(RequestBasedOnCalculationRule.QueryTextPartnersCounterparties, "&BeginOfPeriod") = 0 Then
						QueryTextPartnersCounterparties = RequestBasedOnCalculationRule.QueryTextPartnersCounterparties;
					EndIf;
				EndIf;
				QueryTextTemporaryTable = RequestBasedOnCalculationRule.QueryTextTemporaryTable;
				If Not IsBlankString(QueryTextTemporaryTable) Then
					If SourceIdentificator = "Plan" Or SourceIdentificator = "StoredFact" Then
						QueryTextTemporaryTable = StrReplace(QueryTextTemporaryTable, ") AS AliasOfSourceTable",
							" AND &SourceTableConditionsAndAlignmentFields) AS AliasOfSourceTable");
						If SourceType <> "BudgetTurnovers" Then
							QueryTextTemporaryTable = StrReplace(QueryTextTemporaryTable,
							"&SourceTableConditionsAndAlignmentFields", "&SourceTableConditionsAndAlignmentFields_" + SourceType);
						EndIf;
					EndIf;
					If Not IsBlankString(RuleID) Then
						QueryTextTemporaryTable = StrReplace(QueryTextTemporaryTable,
							RequestBasedOnCalculationRule.RuleID, RuleID);
						QueryTextTemporaryTable = StrReplace(QueryTextTemporaryTable,
						"Source_" + RuleID, RequestBasedOnCalculationRule.SourceIdentificator);
						QueryTextTemporaryTable = StrReplace(QueryTextTemporaryTable,
						"Receiver_" + RuleID, RequestBasedOnCalculationRule.ReceiverId);
					EndIf;
					QueryTextsOfTTAccordingToCalculationRules.Add(QueryTextTemporaryTable);
				EndIf;
				If IsBlankString(RuleID) Then
					CalculationRuleIds.Insert(RequestBasedOnCalculationRule.RuleID, New Map);
					CalculationRuleIds[RequestBasedOnCalculationRule.RuleID].Insert(
						RequestBasedOnCalculationRule.SourceIdentificator, RequestBasedOnCalculationRule.ReceiverId);
				EndIf;
			Else
				CalculationRuleIds[RequestBasedOnCalculationRule.RuleID].Insert(
					RequestBasedOnCalculationRule.SourceIdentificator, RequestBasedOnCalculationRule.ReceiverId);
			EndIf;
			CommonClientServer.SupplementStructure(RequestAccordingToCalculationRules.QueryOptions,
				RequestBasedOnCalculationRule.QueryOptions, False);
		EndIf;
	EndDo;
	
	If Not IsBlankString(QueryTextForecastExchangeRates) Then
		QueryTextsOfTTAccordingToCalculationRules.Insert(0, QueryTextForecastExchangeRates);
	EndIf;
	If Not IsBlankString(QueryTextPartnersCounterparties) Then
		QueryTextsOfTTAccordingToCalculationRules.Insert(0, QueryTextPartnersCounterparties);
	EndIf;
	
	For Each IdOfCalculationRules In CalculationRuleIds Do
		FragmentsOfExpressionBudgetFlowItemSource = New Array;
		FragmentsOfExpressionBudgetFlowItemReceiver = New Array;
		For Each KeyAndValue In IdOfCalculationRules.Value Do
			FragmentsOfExpressionBudgetFlowItemSource.Add("&" + KeyAndValue.Key);
			FragmentsOfExpressionBudgetFlowItemReceiver.Add(StringFunctionsClientServer.SubstituteParametersToString(
				"WHEN AliasOfSourceTable.BudgetFlowItem = &%1 THEN &%2", KeyAndValue.Key, KeyAndValue.Value)); //@ query-part
		EndDo;
		TextsExpressionsBudgetFlowItemSource.Insert(IdOfCalculationRules.Key, StrConcat(
			FragmentsOfExpressionBudgetFlowItemSource, ", "));
		TextsExpressionsBudgetFlowItemReceiver.Insert(IdOfCalculationRules.Key,
			StringFunctionsClientServer.SubstituteParametersToString("CASE %1 END", StrConcat( //@ query-part
			FragmentsOfExpressionBudgetFlowItemReceiver, Chars.LF + Chars.Tab)));
	EndDo;

	QueryTextAccordingToCalculationRules = StrConcat(QueryTextsAccordingToCalculationRules,
		TMCommonUse.QuerySeparatorInJoin());
	If Not IsBlankString(QueryTextAccordingToCalculationRules) Then
		For Each IdOfCalculationRules In CalculationRuleIds Do
			TextOfExpressionSource = TextsExpressionsBudgetFlowItemSource.Get(IdOfCalculationRules.Key);
			TextOfReceiverExpression = TextsExpressionsBudgetFlowItemReceiver.Get(IdOfCalculationRules.Key);
			QueryTextAccordingToCalculationRules = StrReplace(QueryTextAccordingToCalculationRules, "&Source_"
				+ IdOfCalculationRules.Key, TextOfExpressionSource);
			QueryTextAccordingToCalculationRules = StrReplace(QueryTextAccordingToCalculationRules, "&Receiver_"
				+ IdOfCalculationRules.Key, TextOfReceiverExpression);
		EndDo;
		If SourceIdentificator = "Document" Then
			ReplacePlannedBudgetRegisterWithTemporaryTableInQueryText(QueryTextAccordingToCalculationRules, "DocumentData");
		ElsIf SourceIdentificator = "Real" Then
			ReplacePlannedBudgetRegisterWithTemporaryTableInQueryText(QueryTextAccordingToCalculationRules, "ActualData");
		Else
			If SourceIdentificator = "StoredFact" Then
				ReplacePlannedBudgetRegisterInQueryTextWithActualOne(QueryTextAccordingToCalculationRules);
			EndIf;
			IndexFields = "Organization,Department" + ?(SourceIdentificator = "StoredFact", "", ",Scenario");
			QueryTextAccordingToCalculationRules = QueryTextAccordingToCalculationRules + Chars.LF + Chars.Tab
				+ StringFunctionsClientServer.SubstituteParametersToString("INDEX BY %1", IndexFields); // @query-part
		EndIf;
	EndIf;
	QueryTextTTAccordingToCalculationRules = StrConcat(QueryTextsOfTTAccordingToCalculationRules,
		Common.QueryBatchSeparator());
	If Not IsBlankString(QueryTextTTAccordingToCalculationRules) Then
		For Each IdOfCalculationRules In CalculationRuleIds Do
			TextOfExpressionSource = TextsExpressionsBudgetFlowItemSource.Get(IdOfCalculationRules.Key);
			TextOfReceiverExpression = TextsExpressionsBudgetFlowItemReceiver.Get(IdOfCalculationRules.Key);
			QueryTextTTAccordingToCalculationRules = StrReplace(QueryTextTTAccordingToCalculationRules, "&Source_"
				+ IdOfCalculationRules.Key, TextOfExpressionSource);
			QueryTextTTAccordingToCalculationRules = StrReplace(QueryTextTTAccordingToCalculationRules, "&Receiver_"
				+ IdOfCalculationRules.Key, TextOfReceiverExpression);
		EndDo;
	EndIf;
	
	RequestAccordingToCalculationRules.QueryText = QueryTextAccordingToCalculationRules;
	RequestAccordingToCalculationRules.QueryTextTT = QueryTextTTAccordingToCalculationRules;
	
	Return RequestAccordingToCalculationRules;
	
EndFunction

Procedure ReplacePlannedBudgetRegisterInQueryTextWithActualOne(QueryText)
	
	QueryText = StrReplace(QueryText, "AliasOfSourceTable.PlanningPeriod",
		"BEGINOFPERIOD(&ExpressionStartOfPeriod, DAY)"); // @query-part
	QueryText = StrReplace(QueryText, "AliasOfSourceTable.Scenario",
		"VALUE(Catalog.BudgetingScenarios.ActualData)"); // @query-part
	QueryText = StrReplace(QueryText, "AliasOfSourceTable.Status",
		"VALUE(Enum.PlanStatuses.Upholded)"); // @query-part
	QueryText = StrReplace(QueryText, "{&DateEmpty}", "{&ExpressionStartOfPeriod AS EndOfPeriod_}");
	QueryText = StrReplace(QueryText, "{&UpdateDate}", "{&ExpressionEndOfPeriod AS EndOfPeriod_}");
	QueryText = StrReplace(QueryText, "PlanningPeriod BETWEEN &ExpressionStartOfPeriod AND &ExpressionEndOfPeriod",
		"TRUE");
	QueryText = RequestSchemes.RemoveFieldsFromRequest(QueryText, "ScenarioAmountTurnover");
	QueryText = StrReplace(QueryText,
		"AccumulationRegister.BudgetTurnovers.Turnovers", "AccumulationRegister.ActualBudgetingData.Turnovers"); // @query-part
	QueryText = RequestSchemes.AddSelectionFieldToQuery(QueryText, "Rule", "Rule");
	
	If GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters")
		And GetFunctionalOption("ControllingLimitsBasedOnBudgetingData2_4") Then
		QueriesTexts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(QueryText,
			TMCommonUse.QuerySeparatorInJoin());
		For Counter = 1 To QueriesTexts.Count() Do
			QueriesTexts[Counter - 1] = QueriesTexts[Counter - 1] + "
																		|	AND AliasOfSourceTable.Rule.RuleType <> VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillment)";
		EndDo;
		QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	EndIf;
	
EndProcedure

Procedure ReplacePlannedBudgetRegisterWithTemporaryTableInQueryText(QueryText, TempTableName)
	
	QueryText = StrReplace(QueryText, "INTO Data", ""); // @query-part
	If TempTableName = "ActualData" Then
		QueryText = StrReplace(QueryText, "AliasOfSourceTable.PlanningPeriod",
			"BEGINOFPERIOD(&ExpressionStartOfPeriod, DAY)"); // @query-part
		QueryText = StrReplace(QueryText, "AliasOfSourceTable.Status",
			"VALUE(Enum.PlanStatuses.Upholded)"); // @query-part
	EndIf;
	
	QueriesTexts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(QueryText,
		TMCommonUse.QuerySeparatorInJoin());
	For Counter = 0 To QueriesTexts.UBound() Do
		QueryText = QueriesTexts[Counter];
		PositionOfDataSource = StrFind(QueryText, "AccumulationRegister.BudgetTurnovers.Turnovers("); // @query-part
		PositionOfSourceAlias = StrFind(QueryText, ") AS AliasOfSourceTable", , PositionOfDataSource); // @query-part
		DataSourceText = Mid(QueryText, PositionOfDataSource, PositionOfSourceAlias
			- PositionOfDataSource + 1);
		ConditionStartPosition = StrFind(QueryText, "WHEN AliasOfSourceTable.BudgetFlowItem ="); // @query-part
		MultipleChoice = False;
		If ConditionStartPosition > 0 Then
			PositionOfConditionEnd = StrFind(QueryText, "END", , ConditionStartPosition); // @query-part
			ConditionText = Mid(QueryText, ConditionStartPosition, PositionOfConditionEnd - 1 - ConditionStartPosition);
			ConditionText = StrReplace(ConditionText, "&BudgetBalanceItem_",
				"AliasOfSourceTable.BudgetBalanceItem = &BudgetBalanceItem_");
			MultipleChoice = True;
		Else
			ConditionStartPosition = StrFind(DataSourceText, "BudgetFlowItem IN ("); // @query-part
			PositionOfConditionEnd = StrFind(DataSourceText, ")", , ConditionStartPosition);
			ConditionText = Mid(DataSourceText, ConditionStartPosition, PositionOfConditionEnd + 1
				- ConditionStartPosition);
			ConditionText = StrReplace(ConditionText, "BudgetFlowItem IN (",
				"AliasOfSourceTable.BudgetFlowItem IN ("); // @query-part
		EndIf;
		QueryText = StrReplace(QueryText, DataSourceText, TempTableName) + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(?(MultipleChoice, "AND CASE %1 END",
			"AND %1"), ConditionText); // @query-part
		QueriesTexts[Counter] = QueryText;
	EndDo;
	
	QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	
EndProcedure

Function GetQueryTextToSourceOfIndicatorDataWithoutCalculationRules() Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	QueryText = 
	"SELECT ALLOWED
	|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems) AS BudgetBalanceItem,
	|	CAST(CalculationsRules.Source AS Catalog.BudgetFlowItems) AS BudgetFlowItem,
	|	DATETIME(1,1,1) AS DayPeriod,
	|	DATETIME(1,1,1) AS PlanningPeriod,
	|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.BudgetingScenarios.EmptyRef) AS Scenario,
	|	VALUE(Enum.PlanStatuses.EmptyRef) AS Status,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	0 AS ScenarioAmountTurnover,
	|	0 AS SumManTurnover,
	|	0 AS SumComplTurnover,
	|	0 AS AmountInCurrencyTurnover,
	|	0 AS CountTurnover,
	|	&SelectionFields1,
	|	UNDEFINED AS Recorder,
	|	FALSE AS Expense
	|FROM
	|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|WHERE
	|	&ConditionText";
	
	SelectionFields1 = "";
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		PasteTemplate = "
		|	UNDEFINED AS Dimension%1";
		SelectionFields1 = SelectionFields1 + ?(SelectionFields1 = "", "", "," + Chars.LF) + StrTemplate(PasteTemplate, Cnt);
	EndDo;
	
	QueryText = StrReplace(QueryText, "&SelectionFields1", SelectionFields1);
	
	Return QueryText;

EndFunction

Function CalculateFactByBudgetType(DataParameters, DataSources, ReportCurrency, DataReceiptMode)
	
	ColumnsInBudgetViewDataTable = BudgetReportingCacheCalculationServer.ColumnsOfDataTable_(DataParameters.BudgetProfile);
	
	// We get the fact only in the context of the minimum periodicity
	Periodicity_ = New Array;
	CommonClientServer.SupplementArray(Periodicity_, ColumnsInBudgetViewDataTable.Periodicity_);
	For Each DataSource In DataSources Do
		If ValueIsFilled(DataSource.OffsetFrequency)
			And ValueIsFilled(DataSource.PeriodOfShift) Then
			Periodicity_.Add(DataSource.OffsetFrequency);
		EndIf;
	EndDo;
	Periodicity_ = CommonClientServer.CollapseArray(Periodicity_);
	Periodicity = BudgetReportingClientServer.MinimumPeriodicity(Periodicity_);
	
	DimensionKinds = ColumnsInBudgetViewDataTable.DimensionKinds;
	If ColumnsInBudgetViewDataTable.Dimensions.Find("Organization") <> Undefined Then
		ByCompanies = True;
	Else
		ByCompanies = False;
	EndIf;
	If ColumnsInBudgetViewDataTable.Dimensions.Find("Department") <> Undefined Then
		ByBusinessUnits = True;
	Else
		ByBusinessUnits = False;
	EndIf;
	
	Period = New StandardPeriod(DataParameters.BeginOfPeriod, DataParameters.EndOfPeriod);
	Parameters = ParametersForGettingFactByBudgetType(
		DataParameters.BudgetProfile, ReportCurrency, Period, Periodicity, DimensionKinds, ByCompanies, ByBusinessUnits, DataReceiptMode);
	
	ReportScript = Undefined;
	If DataParameters <> Undefined Then
		DataParameters.Property("Scenario", ReportScript);
	EndIf;
	
	ReportScenarioActualData = (ReportScript = Catalogs.BudgetingScenarios.ActualData);
	ScenarioOfBudgetExecutionReport = (ReportScript = Catalogs.BudgetingScenarios.BudgetFulfillment);
	
	DataTableByBudgetType = TemplateForDataTableByBudgetType(Parameters);
	For Each DataSource In DataSources Do
		
		If Not DataSource.ThereAreOnLineRules Then
			Continue;
		EndIf;
		
		GetActualData = DataSource.AssumesActualData = "Assumed"
				Or (DataSource.AssumesActualData = "DeterminedByReportSettings"
					And ReportScenarioActualData)
				Or DataSource.AssumesBudgetExecution = "Assumed"
				Or (DataSource.AssumesBudgetExecution = "DeterminedByReportSettings"
					And  ScenarioOfBudgetExecutionReport);
		
		If Not DataSource.PrivilegedMode = Undefined And DataSource.PrivilegedMode Then
			SetPrivilegedMode(True);
		EndIf;
		
		If DataSource.SourceType = Enums.BudgetingDataSourceTypes.Turnovers And GetActualData Then
			//@skip-check query-in-loop
			GetFactFromDataSourceRevolutions(DataTableByBudgetType, DataSource, Parameters, DataParameters);
			If DataSource.ThereAreTargets_ = True Then
				//@skip-check query-in-loop
				GetFactFromDataSource(DataTableByBudgetType, DataSource, Parameters, DataParameters);
			EndIf;
		ElsIf DataSource.SourceType = Enums.BudgetingDataSourceTypes.Balance And GetActualData Then
			//@skip-check query-in-loop
			GetFactFromDataSource(DataTableByBudgetType, DataSource, Parameters, DataParameters);
		ElsIf DataSource.SourceType = Enums.BudgetingDataSourceTypes.NonFinancial Then
			//@skip-check query-in-loop
			GetValuesByNonFinancialDataSource(DataTableByBudgetType, DataSource, Parameters, DataParameters);
		EndIf;
		
		If Not DataSource.PrivilegedMode = Undefined And DataSource.PrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
		
	EndDo;
	
	BudgetViewColumn = DataTableByBudgetType.Columns.Find("AmountInCurrencyOpeningBalance");
	If BudgetViewColumn <> Undefined Then
		BudgetViewColumn.Name = "SumCurrOpeningBalance";
	EndIf;
	
	Return DataTableByBudgetType;
	
EndFunction

#Region AlternativeFact

Function SpecifyDataParametersByBudgetType(DataParameters, DataSources, ReportCurrency, DataReceiptMode)
	
	ColumnsOfDataTable_ = Undefined;
	If Not DataParameters.Property("ColumnsOfDataTable_", ColumnsOfDataTable_) Then
		ColumnsOfDataTable_ = BudgetReportingCacheCalculationServer.ColumnsOfDataTable_(DataParameters.BudgetProfile);
	EndIf;
	
	Period = New StandardPeriod(DataParameters.BeginOfPeriod, DataParameters.EndOfPeriod);
	
	// We get the fact only in the context of the minimum periodicity
	Periodicity_ = New Array;
	CommonClientServer.SupplementArray(Periodicity_, ColumnsOfDataTable_.Periodicity_);
	For Each DataSource In DataSources Do
		If ValueIsFilled(DataSource.OffsetFrequency)
			And ValueIsFilled(DataSource.PeriodOfShift) Then
			Periodicity_.Add(DataSource.OffsetFrequency);
		EndIf;
	EndDo;
	Periodicity_ = CommonClientServer.CollapseArray(Periodicity_);
	MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(Periodicity_);
	
	// Types of analytics are required for the application of the add. selections of elements of the budget type
	// This applies to selections for named analysts, which require calculated fields "by name" of the type of analytics.
	AllKindsOfAnalytics = ColumnsOfDataTable_.DimensionKinds;
	
	// If the analytics are in the header and selections are set, then the fields will be needed
	AdditionalFiltersForAnalytics = Undefined;
	If DataParameters.Property("AdditionalFiltersForAnalytics", AdditionalFiltersForAnalytics) 
		And Not AdditionalFiltersForAnalytics = Undefined Then
		For Each NameOfAnalyticsType In AdditionalFiltersForAnalytics Do 
			AllKindsOfAnalytics.Add(FinancialReportingCached.BudgetReportFieldByName(NameOfAnalyticsType.Key));
		EndDo;
	EndIf;
	
	ByCompanies = False;
	If Not DataParameters.Property("ByCompanies", ByCompanies) Then
		ByCompanies = (ColumnsOfDataTable_.Dimensions.Find("Organization") <> Undefined);
	EndIf;
	
	ByBusinessUnits = False;
	If Not DataParameters.Property("ByBusinessUnits", ByBusinessUnits) Then
		ByBusinessUnits = (ColumnsOfDataTable_.Dimensions.Find("Department") <> Undefined);
	EndIf;
	
	BudgetProfile = Undefined;
	DataParameters.Property("BudgetProfile", BudgetProfile);
	
	Parameters = ParametersForGettingFactByBudgetType(
		BudgetProfile, ReportCurrency, Period, MinimumPeriodicity, AllKindsOfAnalytics, ByCompanies, ByBusinessUnits, DataReceiptMode);
	
	If DataParameters.Property("ByRegistrar") Then
		Parameters.ByRegistrar = DataParameters.ByRegistrar;
	Else
		Parameters.ByRegistrar = False;
	EndIf;
	
	Return Parameters;
	
EndFunction

Function PrepareParametersOfFactRevolutions(Parameters, DataParameters, DataReceiptMode)
	
	MetricSettingsAreSpecified = DataParameters.Property("Indicators");
	QuantityRequired = Not MetricSettingsAreSpecified Or DataParameters.Indicators.Property("Count");
	AmountRequired = Not MetricSettingsAreSpecified Or DataParameters.Indicators.Property("Sum");
	
	// Parameters for getting actual revolutions
	FieldCompositionSettings = Undefined;
	If Not DataParameters.Property("FieldCompositionSettings", FieldCompositionSettings) Then
		FieldCompositionSettings = New Structure ;
		FieldCompositionSettings.Insert("QuantityRequired", QuantityRequired);
		FieldCompositionSettings.Insert("AmountRequired", AmountRequired);
		FieldCompositionSettings.Insert("AmountRequiredOpeningBalance", False);
		FieldCompositionSettings.Insert("AmountRequiredReceipt", True);
		FieldCompositionSettings.Insert("AmountRequiredExpense", True);
	EndIf;
	ParametersForIdentifyingRpmExpressions = ExpressionIdentificationParameterTemplate(FieldCompositionSettings);
	
	ParametersAndRevolutions = DataSourcesServer.TemplateForGettingFactParameters(Parameters, ParametersForIdentifyingRpmExpressions);
	
	If DataParameters.Property("SelectionByRegistrarForAllFact") Then
		// Registrar selection for the purpose of optimizing the acquisition of turnover by articles, when
		// it is known that registrar selection should be applied to all articles of all data sources.
		// For example, when checking the passage of a document according to the limits of the DS. The effectiveness depends on the number of rules for obtaining the fact.
		ParametersAndRevolutions.Insert("SelectionByRegistrarForAllFact", DataParameters.SelectionByRegistrarForAllFact);
	EndIf;
	
	CommonClientServer.SupplementStructure(
		ParametersAndRevolutions.AdditionalFiltersForAnalytics, DataParameters.AdditionalFiltersForAnalytics);
		
	ParametersAndRevolutions.AccessRestrictions.DataReceiptMode = DataReceiptMode;
	FillPropertyValues(ParametersAndRevolutions, DataParameters);
	FillPropertyValues(ParametersAndRevolutions.AdditionalFiltersForMeasurements, DataParameters);
	FillPropertyValues(ParametersAndRevolutions.AdditionalFiltersForAnalytics, DataParameters);
	
	Return New Structure("ParametersAndRevolutions, ParametersForIdentifyingRpmExpressions",
		ParametersAndRevolutions, ParametersForIdentifyingRpmExpressions);
	
EndFunction

Function PrepareFactParametersBalances(Parameters, DataParameters, DataSources, DataReceiptMode)
	
	MetricSettingsAreSpecified = DataParameters.Property("Indicators");
	QuantityRequired = Not MetricSettingsAreSpecified Or DataParameters.Indicators.Property("Count");
	AmountRequired = Not MetricSettingsAreSpecified Or DataParameters.Indicators.Property("Sum");
	
	// Parameters for obtaining actual balances
	FieldCompositionSettings = Undefined;
	If Not DataParameters.Property("FieldCompositionSettings", FieldCompositionSettings) Then
		FieldCompositionSettings = New Structure ;
		FieldCompositionSettings.Insert("QuantityRequired", QuantityRequired);
		FieldCompositionSettings.Insert("AmountRequired", AmountRequired);
		FieldCompositionSettings.Insert("AmountRequiredOpeningBalance", True);
		FieldCompositionSettings.Insert("AmountRequiredReceipt", False);
		FieldCompositionSettings.Insert("AmountRequiredExpense", False);
		
		For Each DataSource In DataSources Do
			If DataSource.ThereAreTargets_ Then
				FieldCompositionSettings.AmountRequiredReceipt = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	ExpressionIdentificationParametersBalance = ExpressionIdentificationParameterTemplate(FieldCompositionSettings);
	
	FactParametersBalance = DataSourcesServer.TemplateForGettingFactParameters(Parameters, ExpressionIdentificationParametersBalance);
	
	CommonClientServer.SupplementStructure(FactParametersBalance.AdditionalFiltersForAnalytics, 
		DataParameters.AdditionalFiltersForAnalytics);
		
	FactParametersBalance.AccessRestrictions.DataReceiptMode = DataReceiptMode;
	FillPropertyValues(FactParametersBalance, DataParameters);
	FillPropertyValues(FactParametersBalance.AdditionalFiltersForMeasurements, DataParameters);
	FillPropertyValues(FactParametersBalance.AdditionalFiltersForAnalytics, DataParameters);
	
	Return New Structure("FactParametersBalance, ExpressionIdentificationParametersBalance",
		FactParametersBalance, ExpressionIdentificationParametersBalance);
	
EndFunction

Function PrepareAuxiliaryDataForObtainingNamedAnalytics(Parameters, DataSources, ParametersAndRevolutions, ParametersForIdentifyingRpmExpressions, FactParametersBalance, ExpressionIdentificationParametersBalance)
	
	IndexOfAnalystNamesAndTypes = New Map;
	
	// We will prepare auxiliary data for obtaining named analytics 
	For Each RequestedAnalytics In Parameters.DimensionKinds Do 
		NameOfNamedAnalytics = FinancialReportingCached.NameOfBudgetReportField(RequestedAnalytics);
		
		ParametersForIdentifyingRpmExpressions.DefaultValuesAndData.Insert(
			"ID_" + "ExpressionOfNamedAnalytics" + NameOfNamedAnalytics);
		ParametersForIdentifyingRpmExpressions.PartsOfExpressions.Insert(
			"ExpressionOfNamedAnalytics" + NameOfNamedAnalytics, New Array);
		ParametersAndRevolutions.ExpressionConditions.Insert("ExpressionOfNamedAnalytics" + NameOfNamedAnalytics);
		
		ExpressionIdentificationParametersBalance.DefaultValuesAndData.Insert(
			"ID_" + "ExpressionOfNamedAnalytics" + NameOfNamedAnalytics);
		ExpressionIdentificationParametersBalance.PartsOfExpressions.Insert(
			"ExpressionOfNamedAnalytics" + NameOfNamedAnalytics, New Array);
		FactParametersBalance.ExpressionConditions.Insert("ExpressionOfNamedAnalytics" + NameOfNamedAnalytics);
		
		IndexOfAnalystNamesAndTypes.Insert(
			"ExpressionOfNamedAnalytics" + NameOfNamedAnalytics, RequestedAnalytics);
	EndDo;
	
	For Each DataSource In DataSources Do
		If DataSource.Objects = Undefined Then
			Continue;
		EndIf;
		For Each ObjectString In DataSource.Objects Do
			If TypeOf(ObjectString) = Type("CatalogRef.BudgetFlowItems")
				Or TypeOf(ObjectString) = Type("CatalogRef.BudgetBalanceItems")
				Or TypeOf(ObjectString) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
				
				For Counter = 1 To BudgetingClientServer.MaximumNumberOfAnalysts() Do
					
					DimensionKind = ObjectString["DimensionKind" + Counter];
					If ValueIsFilled(DimensionKind) Then
						
						NameOfNamedAnalytics = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
						
						If Not IndexOfAnalystNamesAndTypes.Get("ExpressionOfNamedAnalytics" + NameOfNamedAnalytics) = Undefined Then
							Continue; // Analytics expression added
						EndIf;
						
						ParametersForIdentifyingRpmExpressions.DefaultValuesAndData.Insert(
							"ID_" + "ExpressionOfNamedAnalytics" + NameOfNamedAnalytics);
						ParametersForIdentifyingRpmExpressions.PartsOfExpressions.Insert(
							"ExpressionOfNamedAnalytics" + NameOfNamedAnalytics, New Array);
						ParametersAndRevolutions.ExpressionConditions.Insert(
							"ExpressionOfNamedAnalytics" + NameOfNamedAnalytics);
						
						ExpressionIdentificationParametersBalance.DefaultValuesAndData.Insert(
							"ID_" + "ExpressionOfNamedAnalytics" + NameOfNamedAnalytics);
						ExpressionIdentificationParametersBalance.PartsOfExpressions.Insert(
							"ExpressionOfNamedAnalytics" + NameOfNamedAnalytics, New Array);
						FactParametersBalance.ExpressionConditions.Insert(
							"ExpressionOfNamedAnalytics" + NameOfNamedAnalytics);
						
						IndexOfAnalystNamesAndTypes.Insert(
							"ExpressionOfNamedAnalytics" + NameOfNamedAnalytics, DimensionKind);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	Return IndexOfAnalystNamesAndTypes;
	
EndFunction

Procedure CycleBySources(Parameters, DataParameters, DataSources, DataGetParameters)
	
	ParametersAndRevolutions = DataGetParameters.ParametersAndRevolutions;
	ParametersForIdentifyingRpmExpressions = DataGetParameters.ParametersForIdentifyingRpmExpressions;
	FactParametersBalance = DataGetParameters.FactParametersBalance;
	ExpressionIdentificationParametersBalance = DataGetParameters.ExpressionIdentificationParametersBalance;
	InvolvedAdditionalSelectionsTurnovers = DataGetParameters.InvolvedAdditionalSelectionsTurnovers;
	AdditionalSelectionsInvolvedBalance = DataGetParameters.AdditionalSelectionsInvolvedBalance;
	
	// To verify the need to obtain actual data
	ReportScript = Undefined;
	If DataParameters <> Undefined Then
		DataParameters.Property("Scenario", ReportScript);
	EndIf;
	
	ReportScenarioActualData = (ReportScript = Catalogs.BudgetingScenarios.ActualData);
	ScenarioOfBudgetExecutionReport = (ReportScript = Catalogs.BudgetingScenarios.BudgetFulfillment);
	
	IndexOfAnalystNamesAndTypes = PrepareAuxiliaryDataForObtainingNamedAnalytics(Parameters, DataSources,
		ParametersAndRevolutions, ParametersForIdentifyingRpmExpressions, FactParametersBalance, ExpressionIdentificationParametersBalance);
	
	AmountIndicators_ = New Array;
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyOpeningBalance");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyManOpeningBalance");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyComplOpeningBalance");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyClosingBalance");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyManClosingBalance");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyComplClosingBalance");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyReceipt");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyManReceipt");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyComplReceipt");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyExpense");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyManExpense");
	AmountIndicators_.Add("IndicatorExpressionAmountCurrencyComplExpense");
	
	ObjectsOfBalanceDataSourcesByScenarios = DataGetParameters.ObjectsOfBalanceDataSourcesByScenarios;
	
	// When bypassing sources and filling in parameters, switching occurs for balances and revolutions.
	For Each DataSource In DataSources Do
		// When getting data from the document itself, NON-online ones are used 
		If Not DataSource.ThereAreOnLineRules Then
			Continue;
		EndIf;
		
		If DataSource.SourceType = Enums.BudgetingDataSourceTypes.NonFinancial Then
			Continue;
		EndIf;
		
		GetActualData = DataSource.AssumesActualData = "Assumed"
				Or (DataSource.AssumesActualData = "DeterminedByReportSettings"
					And ReportScenarioActualData)
				Or DataSource.AssumesBudgetExecution = "Assumed"
				Or (DataSource.AssumesBudgetExecution = "DeterminedByReportSettings"
					And ScenarioOfBudgetExecutionReport);
		
		TheseAreRevolutions = (DataSource.SourceType = Enums.BudgetingDataSourceTypes.Turnovers);
		TheseAreLeftovers = (DataSource.SourceType = Enums.BudgetingDataSourceTypes.Balance);
		TheseAreInfluencingArticles = ValueIsFilled(DataSource.DependentDataSourceIndicator);
		ThereAreTargets = DataSource.ThereAreTargets_;
		UseStartDate = Parameters.BalancesOnlyAtBeginningOfPeriod And Not ThereAreTargets;
		
		AdditionalCurSourceData = New ValueTable;
		
		If GetActualData Then
		
			ObjectsByDataSource = DataSource.Objects;
			If TheseAreLeftovers And Not ReportScenarioActualData And Not ScenarioOfBudgetExecutionReport Then
				ScriptDataSourceObjects = DataSourceObjectsForScenariosToExcludeReceiptOfFact(DataSource,
					DataParameters);
				If ScriptDataSourceObjects.Count() Then
					CommonClientServer.SupplementTable(ScriptDataSourceObjects,
						ObjectsOfBalanceDataSourcesByScenarios);
					If ValueIsFilled(DataParameters.Scenario) Then
						ObjectsByDataSource = CommonClientServer.ArraysDifference(ObjectsByDataSource,
							ScriptDataSourceObjects.UnloadColumn("BudgetBalanceItem"));
						If Not ObjectsByDataSource.Count() Then
							Continue;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			// Formation of a table of periods with the rules for obtaining the fact
			// Each source and all its articles/indicators are obtained within the same period and a set of add-ons.selections 
			// Instead of period values, expressions can be substituted.
			If TheseAreRevolutions And Not ThereAreTargets Then
				ParametersToFillIn = ParametersAndRevolutions;
				ExpressionIdentificationParameters = ParametersForIdentifyingRpmExpressions;
				AdditionalSelectionsInvolved = InvolvedAdditionalSelectionsTurnovers;
			ElsIf TheseAreLeftovers Or ThereAreTargets Then
				ParametersToFillIn = FactParametersBalance;
				ExpressionIdentificationParameters = ExpressionIdentificationParametersBalance;
				AdditionalSelectionsInvolved = AdditionalSelectionsInvolvedBalance;
				ExpressionIdentificationParameters.GettingBalancesForPeriodBoundary = Not UseStartDate;
				ExpressionIdentificationParameters.DefaultValues.GettingBalancesForPeriodBoundary = Not UseStartDate;
			EndIf;
			
			// Let's denote the requirements for data access encountered among the sources.
			// This will reduce the number of iterations of obtaining actual data.
			If Not ParametersToFillIn.AccessRestrictions.ThereIsPrivilegedMode Then
				ParametersToFillIn.AccessRestrictions.ThereIsPrivilegedMode = DataSource.PrivilegedMode;
			EndIf;
			If Not ParametersToFillIn.AccessRestrictions.ThereIsNoPrivilegedMode Then
				ParametersToFillIn.AccessRestrictions.ThereIsNoPrivilegedMode = Not DataSource.PrivilegedMode;
			EndIf;
			
			// Let's form a collection of unique extras. selections that are specified in:
			// - Budget report
			// - Details of the budget instance
			// - Operands of the budget type.
			SerializedSettings = Common.ValueToXMLString(DataSource.AdditionalSelection.Filter);
			SettingsHash = TMCommonUse.HashSumOfString(SerializedSettings, HashFunction.MD5);
			If AdditionalSelectionsInvolved[SettingsHash] = Undefined Then
				// Note that they have already been added so as not to complicate the work of the query optimizer SKD
				AdditionalSelectionsInvolved.Insert(SettingsHash, 
					New Structure("Id_Sources, Settings", 
						New Array, 
						DataSource.AdditionalSelection));
			EndIf; 
			// Unique selections can be applied in different sources, because they also define a unique period.
			AdditionalSelectionsInvolved[SettingsHash].Id_Sources.Add(DataSource.Id);
			
			AdditionalDataParameters = ParametersToFillIn.AdditionalData;
			PartsOfExpressions = ExpressionIdentificationParameters.PartsOfExpressions;
			DefaultValues = ExpressionIdentificationParameters.DefaultValues;
			DefaultValuesAndData = ExpressionIdentificationParameters.DefaultValuesAndData;
		
			// We will get the rules for obtaining a fact by articles and indicators
			TableOfArticleRules = RulesForGettingDataSourceFact(DataSource, ReportScript, ObjectsByDataSource);
			AddColumnsOfUniqueIdentifiers(TableOfArticleRules, "RuleOfFact");
			SupplementOriginalAnalystFillingExpressions(
				TableOfArticleRules, ParametersToFillIn.OriginalAnalystFillExpressions);
			
			#Region FillingDataAreaTable
			IdsOfDataSources = TableOfArticleRules.UnloadColumn("DataSourceID");
			IdsOfDataSources = CommonClientServer.CollapseArray(IdsOfDataSources);
			
			If ThereAreTargets Then
				DefaultValues.Period = Parameters.Period.EndDate;
			Else
				DefaultValues.Period = Parameters.Period.StartDate;
			EndIf;
			DefaultValues.BeginOfPeriod = Parameters.Period.StartDate;
			DefaultValues.EndOfPeriod = Parameters.Period.EndDate;
			
			DefaultValues.SourcePrivilegedMode = DataSource.PrivilegedMode;
			
			For Each PartOfOneExpression In PartsOfExpressions Do 
				// Identifiers for analyst expressions are generated in the additional data table for each rule.
				If StrStartsWith(PartOfOneExpression.Key, "DimensionPopulationExpression")
					Or PartOfOneExpression.Key = "ExpressionForFillingInAnalyticsCurrency"
					Or PartOfOneExpression.Key = "ExpressionFillingAnalyticsStorageCurrency"
					Or PartOfOneExpression.Key = "AnalyticsFillExpressionUnitOfMeasurement"
					Or StrStartsWith(PartOfOneExpression.Key, "ExpressionOfNamedAnalytics")
					Or StrStartsWith(PartOfOneExpression.Key, "IndicatorExpression")
					Or StrStartsWith(PartOfOneExpression.Key, "ExpressionForFillingCoursePeriod") Then
					Continue;
				EndIf;
				
				If PartOfOneExpression.Key = "ExpressionPeriod"
				 Or PartOfOneExpression.Key = "ExpressionPeriodBoundary" Then
					If TheseAreLeftovers Or ThereAreTargets Then
						If UseStartDate Then
							DataSource[PartOfOneExpression.Key] = DataSource.ExpressionStartOfPeriod;
						Else 
							DataSource[PartOfOneExpression.Key] = DataSource.ExpressionEndOfPeriod;
						EndIf;
					Else
						DataSource[PartOfOneExpression.Key] = DataSource.ExpressionOfGroupingPeriod;
					EndIf;
				EndIf;
				
				UpdateExpressionIdentificationParameters(
					ExpressionIdentificationParameters,
					DefaultValues,
					PartOfOneExpression.Key, // Name of the expression identifier field
					DataSource[PartOfOneExpression.Key]); // Expression string
			EndDo;
			
			TMCommonUseClientServer.SupplementTableFromArray(ParametersToFillIn.DataAreas.DataTable, 
				IdsOfDataSources, 
				"DataSourceID", 
				DefaultValues);
			
			DataAreaDataTable = ParametersToFillIn.DataAreas.DataTable; // ValueTable - 
			DataAreaDataTable.GroupBy(ParametersToFillIn.DataAreas.ConvolutionColumns);
			#EndRegion 
			
			// Fill in or add to the cache of properties of articles and indicators 
			If ParametersToFillIn.TableOfArticleRules.Count() = 0 Then
				ParametersToFillIn.TableOfArticleRules = TableOfArticleRules;
			Else
				CommonClientServer.SupplementTable(TableOfArticleRules, ParametersToFillIn.TableOfArticleRules);
			EndIf;
			
			// We will generate additional data - fields that clearly do not relate to the received data,
			// but are required for budgeting.
			If AdditionalCurSourceData.Count() = 0 Then
				AddAdditionalDataColumns(
					AdditionalCurSourceData,
					IndexOfAnalystNamesAndTypes);
			EndIf;
			
			DefaultValues["ID_" + "Source1"] = DataSource.Id;
			DefaultValues.BudgetBalanceItem = DataSource.DependentDataSourceIndicator;
			
			TMCommonUseClientServer.SupplementTable(TableOfArticleRules,
				AdditionalCurSourceData,
				DefaultValues,
				TheseAreRevolutions And Not ThereAreTargets);
				
			CacheOfDetailsForGettingSchema = New Structure;
			CacheOfDetailsForGettingSchema.Insert("DataSourceObjectType");
			CacheOfDetailsForGettingSchema.Insert("DataSourceSection");
			CacheOfDetailsForGettingSchema.Insert("DataSource");
			CacheOfDetailsForGettingSchema.Insert("HashOfDataCompositionSchema");
			CacheOfDetailsForGettingSchema.Insert("TransactionAmountSource");
			CacheOfDetailsForGettingSchema.Insert("RuleType");
			CacheOfDetailsForGettingSchema.Insert("TypeOfAccountingDataReceipt");
			CacheOfDetailsForGettingSchema.Insert("TypeOfAccountingDataExpense");
				
			// Fill in the IDs
			For Each AdditionalDataLine_ In AdditionalCurSourceData Do
				FillPropertyValues(DefaultValuesAndData, AdditionalDataLine_);
				
				FillPropertyValues(CacheOfDetailsForGettingSchema, AdditionalDataLine_);
				AdditionalDataLine_.CacheOfDetailsForGettingSchema = CacheOfDetailsForGettingSchema;
				
				For Each PartOfOneExpression In PartsOfExpressions Do
					
					If PartOfOneExpression.Key = "ExpressionFillingAnalyticsStorageCurrency" Then
						Continue;
					EndIf;
					
					ThisIsExpressionOfFillingAnalytics = StrStartsWith(PartOfOneExpression.Key, "DimensionPopulationExpression");
					ThisIsExpressionOfNamedAnalytics = StrStartsWith(PartOfOneExpression.Key, "ExpressionOfNamedAnalytics");
					ThisIsCurrencyAnalytics = (PartOfOneExpression.Key = "ExpressionForFillingInAnalyticsCurrency");
					
					ThisIsExpressionOfQuantityIndicator = StrStartsWith(PartOfOneExpression.Key, "IndicatorExpressionCount");
					ThisIsExpressionOfExponentSum = (AmountIndicators_.Find(PartOfOneExpression.Key) <> Undefined);
					ThisIsIndicatorExpression = ThisIsExpressionOfQuantityIndicator Or ThisIsExpressionOfExponentSum;
					
					If ThisIsIndicatorExpression Then
						ThisIsIndicatorOpeningBalance = StrFind(PartOfOneExpression.Key, "OpeningBalance") > 0;
						ThisIsIndicatorReceipt = StrFind(PartOfOneExpression.Key, "Receipt") > 0;
						ThisIsIndicatorExpense = StrFind(PartOfOneExpression.Key, "Expense") > 0;
					Else
						ThisIsIndicatorOpeningBalance = False;
						ThisIsIndicatorReceipt = False;
						ThisIsIndicatorExpense = False;
					EndIf;
					
					If Not (ThisIsExpressionOfFillingAnalytics
						Or ThisIsExpressionOfNamedAnalytics
						Or ThisIsIndicatorExpression
						Or ThisIsCurrencyAnalytics) Then
						Continue; // Identifiers for other analyst expressions are formed earlier
					EndIf;
					
					FieldFillingExpression = "";
					If ThisIsExpressionOfFillingAnalytics Or ThisIsCurrencyAnalytics Then
						
						If ThisIsCurrencyAnalytics Then
							
							ExpressionParameters = ExpressionForFillingInAnalyticsCurrency(ParametersToFillIn, AdditionalDataLine_);
							
							ParametersToFillIn.ByCurrency = ParametersToFillIn.ByCurrency Or ExpressionParameters.ByCurrency;
							FieldFillingExpression = ExpressionParameters.FieldFillingExpression;
							
						ElsIf StrFind(PartOfOneExpression.Key, "UnitOfMeasure") Then
							
							ExpressionParameters = AnalyticsFillExpressionUnitOfMeasurement(ParametersToFillIn.ByUnitsOfMeasurement, AdditionalDataLine_);
							
							ParametersToFillIn.ByUnitsOfMeasurement = ExpressionParameters.ByUnitsOfMeasurement;
							ParametersToFillIn.ExpressionConditions.QuantityConversionExpression = ExpressionParameters.QuantityConversionExpression;
							FieldFillingExpression = ExpressionParameters.FieldFillingExpression;
							
						Else
							
							DimensionNumber = Number(Right(PartOfOneExpression.Key, 1));
							FieldFillingExpression = ExpressionForFillingInAnalyticsBasedOnAdditionalData(DimensionNumber, AdditionalDataLine_);
							FieldFillingExpression = ExpressingAnalyticsValueBySourceAndTypeOfAnalytics(FieldFillingExpression, "DimensionKind" + DimensionNumber);
						EndIf;
						
						UpdateExpressionIdentificationParameters(
							ExpressionIdentificationParameters,
							DefaultValuesAndData,
							PartOfOneExpression.Key, // Name of the expression identifier field
							FieldFillingExpression,  // Expression string
							,
							True);
							
					ElsIf ThisIsExpressionOfNamedAnalytics Then
						
						RequestedTypeOfAnalytics = IndexOfAnalystNamesAndTypes[PartOfOneExpression.Key];
						
						For DimensionNumber = 1 To BudgetingClientServer.MaximumNumberOfAnalysts() Do 
							TypeOfRuleAnalytics = AdditionalDataLine_["DimensionKind" + DimensionNumber];
							
							If RequestedTypeOfAnalytics = TypeOfRuleAnalytics Then
								
								FieldFillingExpression = ExpressionForFillingInAnalyticsBasedOnAdditionalData(DimensionNumber, AdditionalDataLine_);
								FieldFillingExpression = ExpressingAnalyticsValueBySourceAndTypeOfAnalytics(FieldFillingExpression, "DimensionKind" + DimensionNumber);
								
								UpdateExpressionIdentificationParameters(
									ExpressionIdentificationParameters,
									DefaultValuesAndData,
									PartOfOneExpression.Key, // Name of the expression identifier field
									FieldFillingExpression,  // Expression string
									,
									True);
									
								Break;
							Else
								Continue;
							EndIf;
						EndDo;
						
					ElsIf ThisIsIndicatorExpression Then
						
						NameOfExpressionInDatabase = PartOfOneExpression.Key;
						NameOfExpressionInDatabase = StrReplace(NameOfExpressionInDatabase, "OpeningBalance", "");
						NameOfExpressionInDatabase = StrReplace(NameOfExpressionInDatabase, "Receipt", "");
						NameOfExpressionInDatabase = StrReplace(NameOfExpressionInDatabase, "Expense", "");
						
						FieldFillingExpression = AdditionalDataLine_[NameOfExpressionInDatabase];
						
						If Not ValueIsFilled(FieldFillingExpression) And ThisIsExpressionOfExponentSum Then
							For Each AmountSource In AdditionalDataLine_.AmountIndicatorExpressions Do
								If AmountSource.Key = "InternationalCurrency" Then
									FieldFillingExpression = AmountSource.Value;
									Break;
								EndIf;
							EndDo;
						EndIf;
						
						// Let's clarify the expression of unused fields in the source
						If TheseAreRevolutions And Not TheseAreInfluencingArticles And Not ThisIsIndicatorReceipt 
							Or TheseAreLeftovers And Not ThisIsIndicatorOpeningBalance
							Or TheseAreInfluencingArticles And AdditionalDataLine_.Expense And Not ThisIsIndicatorExpense
							Or TheseAreInfluencingArticles And Not AdditionalDataLine_.Expense And Not ThisIsIndicatorReceipt Then
							FieldFillingExpression = "0";
						EndIf;
						
						UpdateExpressionIdentificationParameters(
							ExpressionIdentificationParameters,
							DefaultValuesAndData,
							PartOfOneExpression.Key, // Name of the expression identifier field
							FieldFillingExpression,   // Expression string
							True);
					EndIf;
				EndDo;
				
				If AdditionalDataLine_.AmountIndicatorExpressions.Property("Currency") Then
					
					FieldFillingExpression = ExpressionFillingAnalyticsStorageCurrency(ParametersToFillIn, AdditionalDataLine_);
					ParametersToFillIn.ByCurrency = True;
					
					UpdateExpressionIdentificationParameters(
						ExpressionIdentificationParameters,
						DefaultValuesAndData,
						"ExpressionFillingAnalyticsStorageCurrency", // Name of the expression identifier field
						FieldFillingExpression);// Expression string
				Else
					
					UpdateExpressionIdentificationParameters(
						ExpressionIdentificationParameters,
						DefaultValuesAndData,
						"ExpressionFillingAnalyticsStorageCurrency", // Name of the expression identifier field
						"VALUE(Catalog.Currencies.EmptyRef)");// Expression string
				EndIf;
				
				FillPropertyValues(AdditionalDataLine_, DefaultValuesAndData);
			EndDo;
			
			If AdditionalDataParameters.DataTable.Count() = 0 Then
				AddAdditionalDataColumns(AdditionalDataParameters.DataTable, IndexOfAnalystNamesAndTypes);
			EndIf;
			CommonClientServer.SupplementTable(AdditionalCurSourceData, AdditionalDataParameters.DataTable);
		EndIf;
	EndDo;
	
EndProcedure

// Calculation with a table of rules in the context of data source identifiers ( iids) - unique SCD schemes.
//
// Parameters:
//    DataParameters - Structure - Selections defined at the budget report level
//    DataSources -  Array of ValueTableRow - Data sources of the budget type
//    ReportCurrency    - CatalogRef.Currencies - The currency in which the fact must be returned
//    DataReceiptMode - EnumRef.BudgetingDataReceiptMode
//
// Returns:
//    ValueTable - Actual data
//
Function CalculateFactByBudgetTypeAlternative(DataParameters, Val DataSources, ReportCurrency, DataReceiptMode)
	
	DataSources = TMCommonUse.ArrayToValueTable(DataSources);
	
	Parameters = SpecifyDataParametersByBudgetType(DataParameters, DataSources, ReportCurrency, DataReceiptMode);
	
	DataTableByBudgetType = TemplateForDataTableByBudgetType(Parameters);
	
	StructureOfFactParametersRevolutions = PrepareParametersOfFactRevolutions(Parameters, DataParameters, DataReceiptMode);
	ParametersAndRevolutions = StructureOfFactParametersRevolutions.ParametersAndRevolutions; // See DataSourcesServer.TemplateForGettingFactParameters
	ParametersForIdentifyingRpmExpressions = StructureOfFactParametersRevolutions.ParametersForIdentifyingRpmExpressions;
	
	StructureOfFactParametersRevolutions = PrepareFactParametersBalances(Parameters, DataParameters, DataSources, DataReceiptMode);
	FactParametersBalance = StructureOfFactParametersRevolutions.FactParametersBalance;
	ExpressionIdentificationParametersBalance = StructureOfFactParametersRevolutions.ExpressionIdentificationParametersBalance;
	
	DataSources.Columns.Add("ExpressionPeriod", DataSources.Columns.ExpressionOfGroupingPeriod.ValueType);
	DataSources.Columns.Add("ExpressionPeriodBoundary", DataSources.Columns.ExpressionOfGroupingPeriod.ValueType);
	
	InvolvedAdditionalSelectionsTurnovers = New Map; // Key - Hash, Value - Structure - Identifiers + Layout Settings
	AdditionalSelectionsInvolvedBalance = New Map; // Key - Hash, Value - Structure - Identifiers + Layout Settings
	
	ObjectsOfBalanceDataSourcesByScenarios = New ValueTable;
	ObjectsOfBalanceDataSourcesByScenarios.Columns.Add("BudgetBalanceItem", New TypeDescription(
		"CatalogRef.BudgetBalanceItems"));
	ObjectsOfBalanceDataSourcesByScenarios.Columns.Add("Scenario", New TypeDescription(
		"CatalogRef.BudgetingScenarios"));
	ObjectsOfBalanceDataSourcesByScenarios.Columns.Add("ID_Source1", New TypeDescription("String"));
	
	AddDataSourcesForInfluentialArticles(DataSources);
	
	DataGetParameters = New Structure;
	DataGetParameters.Insert("ParametersAndRevolutions", ParametersAndRevolutions);
	DataGetParameters.Insert("ParametersForIdentifyingRpmExpressions", ParametersForIdentifyingRpmExpressions);
	DataGetParameters.Insert("FactParametersBalance", FactParametersBalance);
	DataGetParameters.Insert("ExpressionIdentificationParametersBalance", ExpressionIdentificationParametersBalance);
	DataGetParameters.Insert("InvolvedAdditionalSelectionsTurnovers", InvolvedAdditionalSelectionsTurnovers);
	DataGetParameters.Insert("AdditionalSelectionsInvolvedBalance", AdditionalSelectionsInvolvedBalance);
	DataGetParameters.Insert("ObjectsOfBalanceDataSourcesByScenarios", ObjectsOfBalanceDataSourcesByScenarios);
	
	CycleBySources(Parameters, DataParameters, DataSources, DataGetParameters);
	
	RulesForCalculatingBudgetIndicators = New Array;
	
	For Each DataSource In DataSources Do
		If DataSource.SourceType = Enums.BudgetingDataSourceTypes.NonFinancial Then
			//@skip-check query-in-loop
			GetValuesByNonFinancialDataSource(DataTableByBudgetType, DataSource, Parameters, DataParameters);
		ElsIf DataSource.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
			CommonClientServer.SupplementArray(RulesForCalculatingBudgetIndicators, DataSource.CalculationsRules);
		EndIf;
	EndDo;
	
	// The data sources of the articles contain the rules of fact and the data is required to be obtained
	If ParametersAndRevolutions.DataAreas.DataTable.Count() > 0 Then
		
		GenerateExpressionConditions(ParametersAndRevolutions, ParametersForIdentifyingRpmExpressions);
		RefineTermsOfDataExpressionsTakingIntoAccountDomainExpressions(ParametersAndRevolutions, False);
		SpecifyMaximumNumberOfAnalytics(ParametersAndRevolutions);
		
		ParametersAndRevolutions.AdditionalData.Kind = Enums.KindOfAdditionalDataSourceInformation.DataSetAdditional;
		
		// Apply executable fact selections
		CreateSummaryDOPSelectionBasedOnDataSources(InvolvedAdditionalSelectionsTurnovers, ParametersAndRevolutions, False);
		
		MapHierarchicalDataSources(ParametersAndRevolutions);
		
		ActualDataOnArticles = ActualDataFromSources("ActualDataQueryRulesByBudgetFlowItems", ParametersAndRevolutions);
		
		If ActualDataOnArticles.Count() > 0 Then
		
			If DataParameters.Property("RatePeriod") Then // Limits need to be converted into currency on the date of the application or the report on the limits.
				ActualDataOnArticles.FillValues(DataParameters.RatePeriod, "RatePeriod");
			EndIf;
			
			If RulesForCalculatingBudgetIndicators.Count() > 0 Then
				
				QueryTextSelectionFields1 = New Array;
				For Each Column In ActualDataOnArticles.Columns Do
					If ValueIsFilled(Column.ValueType) Then
						QueryTextSelectionFields1.Add(StringFunctionsClientServer.SubstituteParametersToString(
							"AliasOfSourceTable.%1 AS %1", Column.Name));
					EndIf;
				EndDo;
				QueryTextTT = StrReplace(
					"SELECT
					|	&QueryTextSelectionFields1
					|INTO ActualData
					|FROM
					|	&FactOnBudgetItems AS AliasOfSourceTable", "&QueryTextSelectionFields1",
					StrConcat(QueryTextSelectionFields1, "," + Chars.LF + Chars.Tab)) + "
					|
					|INDEX BY
					|	BudgetFlowItem,
					|	BudgetBalanceItem";
				RequestAccordingToCalculationRules = GenerateRequestToDataSourceAccordingToCalculationRules(RulesForCalculatingBudgetIndicators, "Real");
				QueriesTexts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(RequestAccordingToCalculationRules.QueryText,
					TMCommonUse.QuerySeparatorInJoin());
				For Counter = 0 To QueriesTexts.UBound() Do
					QueryText = QueriesTexts[Counter];
					BeginningOfQuantityField = StrFind(QueryText, "AliasOfSourceTable.CountTurnover");
					EndOfFieldQuantity1 = StrFind(QueryText, "AS CountTurnover", , BeginningOfQuantityField); // @query-part
					EndOfFieldQuantity2 = StrFind(QueryText, ",", , BeginningOfQuantityField);
					CoefficientText = TrimAll(StrReplace(Mid(QueryText, BeginningOfQuantityField, ?(EndOfFieldQuantity1 = 0
						Or EndOfFieldQuantity1 > EndOfFieldQuantity2, EndOfFieldQuantity2, EndOfFieldQuantity1)
						- BeginningOfQuantityField - 1), "AliasOfSourceTable.CountTurnover", ""));
					
					FieldsToAddition = New Array;
					For Each SelectionField In QueryTextSelectionFields1 Do
						If StrFind(QueryText, Mid(SelectionField, StrFind(SelectionField, " AS ")) + ",") = 0 Then // @query-part
							If StrFind(SelectionField, "Count") > 0 Or StrFind(SelectionField, "Sum") > 0 Then
								FieldsToAddition.Add(StrReplace(SelectionField, "AS", CoefficientText + " AS")); // @query-part
							Else
								FieldsToAddition.Add(SelectionField);
							EndIf;
						EndIf;
					EndDo;
					If FieldsToAddition.Count() > 0 Then
						QueryText = StrReplace(QueryText, Chars.LF + "FROM", // @query-part
							"," + Chars.LF + StrConcat(FieldsToAddition, "," + Chars.LF + Chars.Tab) + Chars.LF + "FROM"); // @query-part
					EndIf;
					QueriesTexts[Counter] = QueryText;
				EndDo;
				QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
				FieldsToDelete_ = New Array;
				If Not ParametersAndRevolutions.ByCompanies Then
					QueryText = StrReplace(QueryText, "AliasOfSourceTable.Organization",
					"VALUE(Catalog.Companies.EmptyRef)"); // @query-part
				EndIf;
				If Not ParametersAndRevolutions.ByBusinessUnits Then
					QueryText = StrReplace(QueryText, "AliasOfSourceTable.Department",
					"VALUE(Catalog.BusinessStructure.EmptyRef)"); // @query-part
				EndIf;
				If Not ParametersAndRevolutions.ByCurrency Then
					QueryText = StrReplace(QueryText, "AliasOfSourceTable.Currency",
					"VALUE(Catalog.Currencies.EmptyRef)"); // @query-part
				EndIf;
				If ParametersAndRevolutions.Periodicity = Undefined Then
					FieldsToDelete_.Add("DayPeriod");
				Else
					QueryText = StrReplace(QueryText, "AliasOfSourceTable.DayPeriod",
					"AliasOfSourceTable.RatePeriod");
				EndIf;
				MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
				For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
					FieldsToDelete_.Add(StringFunctionsClientServer.SubstituteParametersToString("Dimension%1", DimensionNumber));
					FieldsToDelete_.Add(StringFunctionsClientServer.SubstituteParametersToString("Dimension%1Source1", DimensionNumber));
				EndDo;
				FieldsToDelete_.Add("CountTurnover");
				FieldsToDelete_.Add("ScenarioAmountTurnover");
				FieldsToDelete_.Add("AmountInCurrencyTurnover");
				FieldsToDelete_.Add("SumManTurnover");
				FieldsToDelete_.Add("SumComplTurnover");
				QueryText = RequestSchemes.RemoveFieldsFromRequest(QueryText, FieldsToDelete_);
				
				Query = New Query;
				Query.Text = QueryTextTT + Common.QueryBatchSeparator() + QueryText;
				Query.SetParameter("FactOnBudgetItems", ActualDataOnArticles);
				Query.SetParameter("ExpressionStartOfPeriod", DataParameters.BeginOfPeriod);
				Query.SetParameter("ExpressionEndOfPeriod", DataParameters.EndOfPeriod);
				For Each QueryParameter In RequestAccordingToCalculationRules.QueryOptions Do
					Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
				EndDo;
				ActualDataOnInfluencingArticles = Query.Execute().Unload();
				
				Counter = 0;
				While Counter < ActualDataOnArticles.Count() Do
					If ValueIsFilled(ActualDataOnArticles[Counter].BudgetBalanceItem) Then
						ActualDataOnArticles.Delete(Counter);
					Else
						Counter = Counter + 1;
					EndIf;
				EndDo;
				TMCommonUse.AddRowsToTable(ActualDataOnArticles, ActualDataOnInfluencingArticles);
				
			EndIf;
			
			RecalculationFields = New Array;
			If Parameters.FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_ Then
				ColumnNameFunctionalCurrencyReceipt = "AmountCurrencyManReceipt";
				ColumnNameFunctionalCurrencyExpense = "AmountCurrencyManExpense";
			Else
				ColumnNameFunctionalCurrencyReceipt = "SumCurrencyLocalParish";
				ColumnNameFunctionalCurrencyExpense = "AmountCurrencyLocalExpense";
			EndIf;
			
			RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
				"AmountCurrencyReceipt", ColumnNameFunctionalCurrencyReceipt, "SumReceipt", "AmountCurrencyReceipt"));
			RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
				"AmountCurrencyExpense", ColumnNameFunctionalCurrencyExpense, "SumExpense", "AmountCurrencyExpense"));
			
			DataTableParameters = ParametersForConvertingDataTableToCurrency(ActualDataOnArticles);
			ConvertDataTableToCurrency(DataTableParameters, Parameters.ReportCurrency, Parameters.FunctionalCurrency,
				RecalculationFields);
			ActualDataOnArticles = DataTableParameters.DataTable;
		
		EndIf;
		
		GenerateRowsOfActualData(
			DataTableByBudgetType, ActualDataOnArticles, ParametersAndRevolutions, InvolvedAdditionalSelectionsTurnovers, "Turnovers");
	EndIf;
	
	// The data sources of the indicators contain the rules of fact and the data is required to be obtained
	If FactParametersBalance.DataAreas.DataTable.Count() > 0 Then
		
		GenerateExpressionConditions(FactParametersBalance, ExpressionIdentificationParametersBalance);
		RefineTermsOfDataExpressionsTakingIntoAccountDomainExpressions(FactParametersBalance, FactParametersBalance.BalancesOnlyAtBeginningOfPeriod);
		SpecifyMaximumNumberOfAnalytics(FactParametersBalance);
		
		FactParametersBalance.AdditionalData.Kind = Enums.KindOfAdditionalDataSourceInformation.DataSetAdditional;
		
		CreateSummaryDOPSelectionBasedOnDataSources(AdditionalSelectionsInvolvedBalance, FactParametersBalance, True);
		
		// Apply executable fact selections
		MapHierarchicalDataSources(FactParametersBalance);
		
		ActualDataOnIndicators = ActualDataFromSources("ActualDataQueryRulesByBudgetBalanceItems", FactParametersBalance);
		
		If ActualDataOnIndicators.Count() > 0 Then
			
			RecalculationFields = New Array;
			If Parameters.FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_ Then
				ColumnNameFunctionalCurrency = "AmountCurrencyManOpeningBalance";
				ColumnNameFunctionalCurrencyReceipt = "AmountCurrencyManReceipt";
				ColumnNameFunctionalCurrencyExpense = "AmountCurrencyManExpense";
			Else
				ColumnNameFunctionalCurrency = "AmountCurrencyLocalInitialBalance";
				ColumnNameFunctionalCurrencyReceipt = "SumCurrencyLocalParish";
				ColumnNameFunctionalCurrencyExpense = "AmountCurrencyLocalExpense";
			EndIf;
			
			RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
				"AmountCurrencyOpeningBalance", ColumnNameFunctionalCurrency, "SumOpeningBalance", "AmountCurrencyOpeningBalance"));
			RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
				"AmountCurrencyReceipt", ColumnNameFunctionalCurrencyReceipt, "SumReceipt", "AmountCurrencyReceipt"));
			RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
				"AmountCurrencyExpense", ColumnNameFunctionalCurrencyExpense, "SumExpense", "AmountCurrencyExpense"));
			
			DataTableParameters = ParametersForConvertingDataTableToCurrency(ActualDataOnIndicators);
			ConvertDataTableToCurrency(DataTableParameters, Parameters.ReportCurrency, Parameters.FunctionalCurrency, RecalculationFields);
			ActualDataOnIndicators = DataTableParameters.DataTable;
		EndIf;
		
		GenerateRowsOfActualData(
			DataTableByBudgetType, ActualDataOnIndicators, FactParametersBalance, AdditionalSelectionsInvolvedBalance,
			"Balance", ObjectsOfBalanceDataSourcesByScenarios);
	EndIf;
	
	Return DataTableByBudgetType;
	
EndFunction

#EndRegion

// Complements the array of source expressions for filling in Analytics.
// 
// Parameters:
// 	TableOfArticleRules - ValueTable - Table of rules for getting a fact.
// 	OriginalAnalystFillExpressions - Array of String - array of original (before modification) expressions for filling in Analytics.
//
Procedure SupplementOriginalAnalystFillingExpressions(TableOfArticleRules, OriginalAnalystFillExpressions)
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Each RulesRow In TableOfArticleRules Do
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			OriginalExpression = RulesRow["DimensionPopulationExpression" + DimensionNumber];
			If Not ValueIsFilled(OriginalExpression) Then
				Continue;
			EndIf;
			
			If OriginalAnalystFillExpressions.Get(OriginalExpression) = Undefined Then
				If ValueIsFilled(RulesRow.BudgetFlowItem) Then
					ItemIndicator = RulesRow.BudgetFlowItem;
				Else
					ItemIndicator = RulesRow.BudgetBalanceItem;
				EndIf;
				OriginalAnalystFillExpressions.Insert(OriginalExpression, ItemIndicator);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure CreateSummaryDOPSelectionBasedOnDataSources(Val AdditionalSelectionsInvolved, Val FactParameters, ExcludeScenario = False)
	
	Var DataSourceSelectionGroup, GroupSelectionOfDataSources, AdditionalFactSelections, DopingInvolved;
	
	// Fill in the settings of the add. selections in the fact receipt parameters
	If FactParameters.AdditionalSelection = Undefined Then
		FactParameters.AdditionalSelection = New DataCompositionSettings;
	EndIf;
	AdditionalSelection = FactParameters.AdditionalSelection; // DataCompositionSettings -
	AdditionalFactSelections = AdditionalSelection.Filter;
	
	AdditionalFactSelections.Items.Clear();
	
	GroupSelectionOfDataSources = FinancialReportingServer.NewFilter(AdditionalFactSelections, Undefined,, Type("DataCompositionFilterItemGroup"));
	GroupSelectionOfDataSources.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	GroupSelectionOfDataSources.Use = True;
	GroupSelectionOfDataSources.Presentation = "SelectingAllDataSources";
	
	For Each DopingInvolved In AdditionalSelectionsInvolved Do 
		// Let's create an aggregate selection
		DataSourceSelectionGroup = FinancialReportingServer.NewFilter(GroupSelectionOfDataSources, Undefined,, Type("DataCompositionFilterItemGroup"));
		DataSourceSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		DataSourceSelectionGroup.Use = True;
		DataSourceSelectionGroup.Presentation = "SelectingDataSource_" + DopingInvolved.Key;
		
		FinancialReportingServer.CopyFilter(DopingInvolved.Value.Settings.Filter, DataSourceSelectionGroup, True);
		FinancialReportingServer.NewFilter(DataSourceSelectionGroup, "ID_" + "Source1", DopingInvolved.Value.Id_Sources, , DataCompositionComparisonType.InList);
	EndDo;
	
	// Fill in the selections with values 
	BudgetReportingDisplayServer.AddDCSSettingsBeforeDisplayingAlternative(FactParameters.AdditionalSelection, FactParameters, ExcludeScenario);
	
	If ExcludeScenario Then
		
		// Also add. scenario selection should not be triggered to obtain the initial balance of the calculated indicator
		// (because there is no scenario and no type of "budget execution" rules for the calculated indicator, and the final balance for the target 
		// indicator is calculated as the initial balance for the Fact scenario and data of influencing articles for the scenario that is either specified in the selection or in the report structure or in the header of the report (budget instance),
		// but should be triggered for influencing items on the calculated indicator and for targets
		FilterItems1Balance = DataCompositionClientServer.GetSelectionElements(FactParameters.AdditionalSelection.Filter);
		SelectionElementsReadyForDeletion = New Array; // Array of DataCompositionFilterItem -
		For Each FilterElement In FilterItems1Balance Do
			If TypeOf(FilterElement) = Type("DataCompositionFilterItem")
				And TrimAll(FilterElement.LeftValue) = "Scenario" Then
				
				If TypeOf(FilterElement.RightValue) = Type("String")
					And StrFind(FilterElement.RightValue, "<fill") Then
					// Custom selections are skipped
					Continue;
				EndIf;
				If Not FilterElement.Use Then
					Continue;
				EndIf;
				
				// We will place the selection element according to the scenario in a group OR, in the same group, we will add a group with two selections: the budget indicator is filled in and the budget item is not filled in
				// (because for influencing articles, exactly as for the target indicator, both the article and the indicator will be filled in)
				If FilterElement.Parent = Undefined Then
					ParentSelectionElements = AdditionalFactSelections.Items;
				Else
					ParentSelectionElements = FilterElement.Parent.Items;
				EndIf;
				OrGroup = ParentSelectionElements.Add(Type("DataCompositionFilterItemGroup"));
				OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
				OrGroup.Use = True;
				OrGroup.Presentation = NStr("vi = 'Lọc theo kịch bản khi nhận sự kiện chỉ được sử dụng cho các mục (bao gồm các mục ảnh hưởng đến chỉ báo mục) và chỉ báo mục tiêu';
											|ru = 'Отбор по сценариям при получении факта применяется только для статей (включая влияющие на показатель статьи) и целевые показатели';
											|en = 'Filter by scenarios when receiving actual data is used only for items (including items that affect item indicator) and target values'; fa = 'Filter by scenarios when receiving actual data is used only for items (including items that affect item indicator) and target values';
											|it = 'La selezione in base agli scenari con ottenimento del fatto si applica solo alle voci (incluse quelle aventi effetto sull''indicatore) e sugli indicatori mirati';
											|pl = 'Filtr według scenariuszy przy otrzymaniu faktu jest stosowany tylko dla pozycji (w tym wpływające na wskaźnik pozycji) i wskaźniki celowe';
											|tr = 'Bilgi alımı senaryosuna göre filtre sadece maddeler (madde göstergesindeki etkileyenler dahil) ve hedef değerler için geçerlidir'");
				
				NewElementSelectionScenario = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
				FillPropertyValues(NewElementSelectionScenario, FilterElement,"LeftValue, ComparisonType, RightValue, Use, Presentation");
				
				AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
				AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				AndGroup.Use = True;
				
				NewSelectionElementIsNotArticle = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
				NewSelectionElementIsNotArticle.LeftValue = New DataCompositionField("BudgetFlowItem");
				NewSelectionElementIsNotArticle.ComparisonType  = DataCompositionComparisonType.NotFilled;
				NewSelectionElementIsNotArticle.Use = True;
				
				NewSelectionElementCalculatedIndicator = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
				NewSelectionElementCalculatedIndicator.LeftValue = New DataCompositionField("BudgetBalanceItem");
				NewSelectionElementCalculatedIndicator.ComparisonType  = DataCompositionComparisonType.Filled;
				NewSelectionElementCalculatedIndicator.Use = True;
				
				SelectionElementsReadyForDeletion.Add(FilterElement);
			EndIf;
		EndDo;
		For Each SelectionElementToRemove In SelectionElementsReadyForDeletion Do
			If SelectionElementToRemove.Parent = Undefined Then
				ParentSelectionElements = AdditionalFactSelections.Items;
			Else
				ParentSelectionElements = SelectionElementToRemove.Parent.Items;
			EndIf;
			ParentSelectionElements.Delete(SelectionElementToRemove);
		EndDo;
	EndIf;
	
EndProcedure

Procedure MapHierarchicalDataSources(FactParameters)
	
	SetPrivilegedMode(True);
	
	MappingScheme = DataSourcesCached.DCS_HierarchyOfBudgetingDataSources();
	MappingTemplate = FinancialReportingServer.PrepareLayoutTemplateForUploadingDCS(MappingScheme, MappingScheme.DefaultSettings);
		
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("AdditionalDataTable", FactParameters.AdditionalData.DataTable);
		
	FactParameters.HierarchyOfDataSources.ComparisonTable_ = FinancialReportingServer.UploadDCSResultsFromTemplate(MappingTemplate, ExternalDataSets);
	
	MatchingForSelections = FactParameters.HierarchyOfDataSources.MatchingForSelections;
	For Each Comparison_ In FactParameters.HierarchyOfDataSources.ComparisonTable_ Do 
		If MatchingForSelections[Comparison_.OriginalDataSource] = Undefined Then
			Filter = New Structure("OriginalDataSource", Comparison_.OriginalDataSource);
			FoundRows = FactParameters.HierarchyOfDataSources.ComparisonTable_.FindRows(Filter);
			
			ArrayOfChildSources = New Array;
			For Each FoundRow In FoundRows Do 
				ArrayOfChildSources.Add(FoundRow.DataSource);
			EndDo;
			
			MatchingForSelections.Insert(Comparison_.OriginalDataSource, ArrayOfChildSources);
		Else
			Continue;
		EndIf;
	EndDo;
	
	// Let's add mappings for cor.accounts
	TableOfCorAccounts = FactParameters.AdditionalData.DataTable.Copy(, "BalancedAccount"); // ValueTable -
	CorAccountColumn = TableOfCorAccounts.Columns.BalancedAccount; // ValueTableColumn -
	CorAccountColumn.Name = "DataSource";
	For Each TableRow In TableOfCorAccounts Do 
		If TableRow.DataSource = Undefined Then
			TableRow.DataSource = True;
		EndIf;
	EndDo;
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("AdditionalDataTable", TableOfCorAccounts);
		
	FactParameters.HierarchyOfDataSources.TableOfComparisonsOfCorAccounts = FinancialReportingServer.UploadDCSResultsFromTemplate(MappingTemplate, ExternalDataSets);
	
	SetPrivilegedMode(False);
	
EndProcedure

// Returns a table of scenarios based on data layout selection.
//
// Parameters:
// 	 DataCompositionFilter - DataCompositionSettings - Settings selection on the script.
// Returns:
//   ValueTable - Scenario Table:
//		* Scenario - CatalogRef.BudgetingScenarios - Scenario.
//		* Currency - CatalogRef.Currencies - Currency.
//		* RequireExchangeRatesSpecificationForEachPeriod - Boolean - True if you need to specify chickens for each period. 
//
Function SelectionDrivenScenarios(DataCompositionFilter)
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	DataSetScenarios = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,
		Type("DataCompositionSchemaDataSetQuery"),
		"BudgetingScenarios");
	
	DataSetScenarios.Query = 
	"SELECT ALLOWED
	|	BudgetingScenarios.Ref AS Scenario,
	|	BudgetingScenarios.Currency AS Currency,
	|	BudgetingScenarios.RequireExchangeRatesSpecificationForEachPeriod AS RequireExchangeRatesSpecificationForEachPeriod
	|FROM
	|	Catalog.BudgetingScenarios AS BudgetingScenarios
	|WHERE
	|	NOT BudgetingScenarios.IsFolder
	|	AND NOT BudgetingScenarios.DeletionMark";
	DataSetScenarios.AutoFillAvailableFields = True;
	
	Settings = New DataCompositionSettings;
	DataCompositionClientServer.AddGrouping(Settings);
	DataCompositionClientServer.AddSelectedField(Settings, "Scenario");
	DataCompositionClientServer.AddSelectedField(Settings, "Currency");
	DataCompositionClientServer.AddSelectedField(Settings, "Periodicity");
	DataCompositionClientServer.AddSelectedField(Settings, "RequireExchangeRatesSpecificationForEachPeriod");
	DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema, Settings, DataCompositionFilter);
	
	Return FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings);
	
EndFunction

// Returns a table of matching IDs of data sources and scenarios, taking into account the selection of data layout.
//
// Parameters:
// 	 IdsOfDataSources - ValueTable - A collapsed table of values containing only enumerations of data source identifiers:
//		* ID_Source1 - String - Id of the data source of the fact table.
// 	 DataCompositionFilter - DataCompositionSettings - Settings selection on the script.
// Returns:
//   ValueTable - Scenario Table:
//		* Scenario - CatalogRef.BudgetingScenarios - Scenario.
//		* Currency - CatalogRef.Currencies - Currency.
//		* RequireExchangeRatesSpecificationForEachPeriod - Boolean - True if you need to specify chickens for each period. 
//
Function SelectionBasedDataSourceIDScenarios(IdsOfDataSources, DataCompositionFilter)
	
	ExternalSets = New Structure;
	ExternalSets.Insert("IdsOfDataSources", IdsOfDataSources);
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	
	DataSetIdentifiers = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,
		Type("DataCompositionSchemaDataSetObject"),
		"IdsOfDataSources");
	
	FinancialReportingServer.NewSetField(DataSetIdentifiers, "ID_" + "Source1", "ID_" + "Source1",, New TypeDescription("String",,,, New StringQualifiers(50)));
	
	DataSetScenarios       = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,
		Type("DataCompositionSchemaDataSetQuery"),
		"BudgetingScenarios");
	
	DataSetScenarios.Query = 
	"SELECT ALLOWED
	|	BudgetingScenarios.Ref AS Scenario,
	|	BudgetingScenarios.Currency AS Currency,
	|	BudgetingScenarios.RequireExchangeRatesSpecificationForEachPeriod AS RequireExchangeRatesSpecificationForEachPeriod
	|FROM
	|	Catalog.BudgetingScenarios AS BudgetingScenarios
	|WHERE
	|	NOT BudgetingScenarios.IsFolder
	|	AND NOT BudgetingScenarios.DeletionMark";
	
	FinancialReportingServer.NewSetField(DataSetScenarios, "Scenario", "Scenario",, New TypeDescription("CatalogRef.BudgetingScenarios"));
	FinancialReportingServer.NewSetField(DataSetScenarios, "Currency", "Currency",, New TypeDescription("CatalogRef.Currencies"));
	FinancialReportingServer.NewSetField(DataSetScenarios, "RequireExchangeRatesSpecificationForEachPeriod", "RequireExchangeRatesSpecificationForEachPeriod",, New TypeDescription("Boolean"));
	
	FinancialReportingServer.NewConnection(DataCompositionSchema,
			"IdsOfDataSources",
			"BudgetingScenarios",
			"TRUE",
			"TRUE");
	
	Settings = New DataCompositionSettings;
	DataCompositionClientServer.AddGrouping(Settings);
	DataCompositionClientServer.AddSelectedField(Settings, "ID_" + "Source1");
	DataCompositionClientServer.AddSelectedField(Settings, "Scenario");
	DataCompositionClientServer.AddSelectedField(Settings, "Currency");
	DataCompositionClientServer.AddSelectedField(Settings, "RequireExchangeRatesSpecificationForEachPeriod");
	
	DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema, Settings, DataCompositionFilter);
	
	SourceIDScripts = FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings, ExternalSets);
	SourceIDScripts.Indexes.Add("ID_" + "Source1");
	
	Return SourceIDScripts;
	
EndFunction

Procedure GenerateRowsOfActualData(DataTableByBudgetType, ActualData, FactParameters,
	AdditionalSelectionsInvolved, TypeOfAmount, ObjectsOfBalanceDataSourcesByScenarios = Undefined)
	
	IdsOfDataSources = ActualData.Copy(, "ID_" + "Source1");
	IdsOfDataSources.GroupBy("ID_" + "Source1", "");
	
	CreateSummaryDOPSelectionBasedOnDataSources(AdditionalSelectionsInvolved, FactParameters, False);
	DataSourceScenarios = SelectionBasedDataSourceIDScenarios(IdsOfDataSources, FactParameters.AdditionalSelection);
	
	StructureOfSourceSearchByScript = Undefined;
	If ObjectsOfBalanceDataSourcesByScenarios <> Undefined
		And ObjectsOfBalanceDataSourcesByScenarios.Count() Then
		ObjectsOfBalanceDataSourcesByScenarios.Indexes.Add("ID_Source1, Scenario, BudgetBalanceItem");
		StructureOfSourceSearchByScript = New Structure("ID_Source1, Scenario, BudgetBalanceItem");
	EndIf;
	
	For Each FactLine_ In ActualData Do
		// 1. Adding lines for the received scenarios is NOT performed for budget items received regardless of the indicator,
		// as well as budget items received as affecting the calculated indicator. For them, lines are added according to the scenario
		// for which they were received (actual data or budget execution).
		// 2. Adding lines for the received scenarios is performed only for calculated and target indicators, moreover, if
		// the scenario for which the indicator value was obtained = budget execution, then lines are added only for the budget execution scenario
		// (to avoid splitting the data when specifying the actual scenario and budget execution scenario in the report) - see methods for getting an unoptimized fact.
		If Not ValueIsFilled(FactLine_.BudgetBalanceItem)
			Or TypeOf(FactLine_.BudgetFlowItem) = Type("CatalogRef.BudgetFlowItems")
			Or FactLine_.Scenario = Catalogs.BudgetingScenarios.BudgetFulfillment Then
			
			NewRowOfActualData = DataTableByBudgetType.Add();
			FillPropertyValues(NewRowOfActualData, FactLine_);
			
			If TypeOfAmount = "Turnovers" Then
				NewRowOfActualData.SumCurrReceipt = FactLine_.AmountCurrencyReceipt;
				NewRowOfActualData.SumCurrExpense = FactLine_.AmountCurrencyExpense;
				NewRowOfActualData.SumReceipt = FactLine_.SumReceipt;
				NewRowOfActualData.SumExpense = FactLine_.SumExpense;
			ElsIf TypeOfAmount = "Balance" Then
				NewRowOfActualData.SumCurrOpeningBalance = FactLine_.AmountCurrencyOpeningBalance;
				NewRowOfActualData.SumOpeningBalance = FactLine_.SumOpeningBalance;
			EndIf;
			
		Else
			SourceScripts = DataSourceScenarios.FindRows(New Structure("ID_" + "Source1", FactLine_["ID_" + "Source1"]));
			For Each ScenariosRow In SourceScripts Do
				
				If ScenariosRow.Scenario = Catalogs.BudgetingScenarios.BudgetFulfillment Then
					Continue;
				EndIf;
				
				If StructureOfSourceSearchByScript <> Undefined Then
					FillPropertyValues(StructureOfSourceSearchByScript, FactLine_);
					FillPropertyValues(StructureOfSourceSearchByScript, ScenariosRow);
					SourceStringsAccordingToScript = ObjectsOfBalanceDataSourcesByScenarios.FindRows(StructureOfSourceSearchByScript);
					If SourceStringsAccordingToScript.Count() Then
						Continue;
					EndIf;
				EndIf;
				
				NewRowOfActualData = DataTableByBudgetType.Add();
				FillPropertyValues(NewRowOfActualData, FactLine_);
				
				If TypeOfAmount = "Turnovers" Then
					NewRowOfActualData.SumCurrReceipt = FactLine_.AmountCurrencyReceipt;
					NewRowOfActualData.SumCurrExpense = FactLine_.AmountCurrencyExpense;
					NewRowOfActualData.SumReceipt = FactLine_.SumReceipt;
					NewRowOfActualData.SumExpense = FactLine_.SumExpense;
				ElsIf TypeOfAmount = "Balance" Then
					NewRowOfActualData.SumCurrOpeningBalance = FactLine_.AmountCurrencyOpeningBalance;
					NewRowOfActualData.SumOpeningBalance = FactLine_.SumOpeningBalance;
				EndIf;
				
				NewRowOfActualData.Scenario = ScenariosRow.Scenario;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

Function ExpressionForFillingInAnalyticsCurrency(FactGettingParameters, Val AdditionalDataLine_)
	
	ByCurrency = False;
	FieldFillingExpression = "";
	SearchPrefix = SearchPrefix(AdditionalDataLine_.DataSourceSection, "Currency", AdditionalDataLine_.DataSourceObjectType);
	
	If AdditionalDataLine_.CurrencyFilling <> "DontFill" Then
		
		If Not FactGettingParameters.ByCurrency Then
			ByCurrency = True;
		EndIf;
		
		InReportCurrency = False;
		If AdditionalDataLine_.CurrencyFilling = "DeterminedByAnalytics" Then
			
			FieldFillingExpression = ExpressionForFillingInAnalyticsBasedOnAdditionalData(AdditionalDataLine_.DimensionAddressCurrency, AdditionalDataLine_);
			
			If FieldFillingExpression = "" Then
				FieldFillingExpression = "&ReportCurrency";
			Else
				FieldFillingExpression = FieldFillingExpression + "." + AdditionalDataLine_.DimensionCurrencyField;
			EndIf;
			
		ElsIf AdditionalDataLine_.CurrencyFilling = "DeterminedByDataSource" Then
			
			DataLayoutRules = DataSourcesServer.DataLayoutRules(AdditionalDataLine_.CacheOfDetailsForGettingSchema);
			SetFields = DataLayoutRules.DataSets[0].Fields;
			
			If SetFields.Find(SearchPrefix + "Currency") <> Undefined Then
				FieldFillingExpression = SearchPrefix + "Currency";
			Else
				InReportCurrency = True;
			EndIf;
			
		ElsIf AdditionalDataLine_.CurrencyFilling = "DeterminedByReportCurrency" Then
			InReportCurrency = True;
		EndIf;
		
		If InReportCurrency Then
			FieldFillingExpression = "&ReportCurrency";
		EndIf;
	EndIf;
	
	Return New Structure("FieldFillingExpression, ByCurrency", FieldFillingExpression, ByCurrency);
	
EndFunction

Function ExpressionFillingAnalyticsStorageCurrency(FactGettingParameters, Val AdditionalDataLine_)
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		Return "&ReportCurrency";
	EndIf;
	
	SearchPrefix = SearchPrefix(AdditionalDataLine_.DataSourceSection, "Currency", AdditionalDataLine_.DataSourceObjectType);
	
	DataLayoutRules = DataSourcesServer.DataLayoutRules(AdditionalDataLine_.CacheOfDetailsForGettingSchema);
	
	DatasetFields = DataLayoutRules.DataSets[0].Fields;
	DataSetFieldCurrency = DatasetFields.Find(SearchPrefix + "Currency");
	
	If DataSetFieldCurrency = Undefined Then
		For Each DataSetField In DatasetFields Do
			If TypeOf(DataSetField) = Type("DataCompositionSchemaDataSetFieldFolder")
				Or TypeOf(DataSetField) = Type("DataCompositionSchemaNestedDataSet") Then
				Continue;
			EndIf;
			If DataSetField.ValueType.ContainsType(Type("CatalogRef.Currencies")) Then
				DataSetFieldCurrency = DataSetField;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If DataSetFieldCurrency = Undefined Then
		ErrorText = NStr("vi = 'Chưa xác định tiền tệ để nhận số tiền nguyên tệ.';
						|ru = 'Не определена валюта для получения валютной суммы.';
						|en = 'Currency for receiving currency amount  is not determined.'; fa = 'Currency for receiving currency amount  is not determined.';
						|it = 'Non è stata identificata la valuta per l''ottenimento della somma valutaria.';
						|pl = 'Nie określono waluty dla otrzymania wartości walutowej.';
						|tr = 'Para birimi tutarlarının toplanmaları için para birimi belirtilmemiş'");
		Raise ErrorText;
	Else
		DataPathCurrency = DataSetFieldCurrency.DataPath;
	EndIf;
	
	Return DataPathCurrency;
	
EndFunction

Function AnalyticsFillExpressionUnitOfMeasurement(Val ByUnitsOfMeasurement, Val AdditionalDataLine_)
	
	FieldFillingExpression = "";
	QuantityConversionExpression = "";
	If AdditionalDataLine_.UnitOfMeasureFilling <> "DontFill" Then
		If Not ByUnitsOfMeasurement Then
			ByUnitsOfMeasurement = True;
		EndIf;
		
		If AdditionalDataLine_.UnitOfMeasureFilling = "DeterminedByAnalytics" Then
			FieldFillingExpression = ExpressionForFillingInAnalyticsBasedOnAdditionalData(AdditionalDataLine_.DimensionAddressUnitOfMeasure, AdditionalDataLine_);
			
			If FieldFillingExpression = "" Then
				// NON-extended mode settings to fill in the analytics and fill in the specified analytics values
				FieldFillingExpression = "UNDEFINED";
			Else
				DimensionPopulationExpression = FieldFillingExpression;
				FieldFillingExpression = FieldFillingExpression + "." + AdditionalDataLine_.FieldOfDimensionUnitOfMeasure;
				If AdditionalDataLine_.FieldOfDimensionUnitOfMeasure = "UnitForReports" Then
					QuantityConversionExpression = DimensionPopulationExpression + ".UnitFactorForReports";
				Else
					MeasurementMeasures = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
						"Weight, Length, VolumeM3, AreaTypeOfMeasurement", ",", , True);
					For Each MeasureOfMeasurement In MeasurementMeasures Do
						TextUnitsOfMeasurement = StringFunctionsClientServer.SubstituteParametersToString(
							"%1UnitOfMeasure", MeasureOfMeasurement);
						If AdditionalDataLine_.FieldOfDimensionUnitOfMeasure = TextUnitsOfMeasurement Then
							UseText = StringFunctionsClientServer.SubstituteParametersToString(
								"%1Use", MeasureOfMeasurement);
							TextNumerator = StringFunctionsClientServer.SubstituteParametersToString("%1Numerator",
								MeasureOfMeasurement);
							TextDenominator = StringFunctionsClientServer.SubstituteParametersToString("%1Denominator",
								MeasureOfMeasurement);
							QuantityConversionExpression = StringFunctionsClientServer.SubstituteParametersToString(
								"CASE WHEN %1 THEN %2 / %3 ELSE 1 END", DimensionPopulationExpression + "."
								+ UseText, DimensionPopulationExpression + "." + TextDenominator,
								DimensionPopulationExpression + "." + TextNumerator);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		ElsIf AdditionalDataLine_.UnitOfMeasureFilling = "FixedValue" Then 
			FieldFillingExpression = "UnitOfMeasure";
		EndIf;
	EndIf;
	
	AnalyticsFillExpressionUnitOfMeasurement = New Structure("FieldFillingExpression, QuantityConversionExpression, ByUnitsOfMeasurement", 
		FieldFillingExpression, QuantityConversionExpression, ByUnitsOfMeasurement);
	
	Return AnalyticsFillExpressionUnitOfMeasurement;
	
EndFunction

Function ExpressionForFillingInAnalyticsBasedOnAdditionalData(Val DimensionNumber, Val AdditionalDataLine_)
	
	FieldFillingExpression = "";
	
	If AdditionalDataLine_.AdvancedModeOfDimensionFillSetting 
		And AdditionalDataLine_["FillInAnalyticsWithSpecifiedValue" + DimensionNumber] Then
		FieldFillingExpression = "DimensionValue" + DimensionNumber;
	Else
		FieldFillingExpression = AdditionalDataLine_["DimensionPopulationExpression" + DimensionNumber];
	EndIf;
	
	Return FieldFillingExpression;

EndFunction

Function SearchPrefix(DataSourceSection, FieldName, DataSourceObjectType)
	Prefix = "";
	
	If DataSourceObjectType <> Type("CatalogRef.ActualDataQueryRulesByBudgetBalanceItems") Then
		// Prefixes are not used in budget indicators.
		If FieldName = "Currency" 
			And (DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting 
			Or DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting) Then
			Prefix = "GroupAccount_3.";
		EndIf;
	EndIf;
	
	Return Prefix;
EndFunction

// Updates the passed expression identification parameters and default values.
//
Procedure UpdateExpressionIdentificationParameters(
				ExpressionIdentificationParameters,
				DefaultValues,
				Val ExpressionFieldName,
				Val Expression,
				Val NumericalExpression = False,
				Val ExpressionAnalytics = False)
	
	Var ExpressionIDFound;
	
	ExpressionsInvolved = ExpressionIdentificationParameters.ExpressionsInvolved;
	ExpressionOccursInField = ExpressionIdentificationParameters.ExpressionOccursInField;
	
	PartsOfExpressions = ExpressionIdentificationParameters.PartsOfExpressions[ExpressionFieldName]; // Array of String -
	CurIDOfExpression = ExpressionIdentificationParameters.CurIDOfExpression;
	
	If ExpressionFieldName = "ExpressionPeriodBoundary" Then
		// The expression of the boundary period is the same as the expression of the period, but with a reduction to the boundary.
		IdFieldName = "ID_" + "ExpressionPeriod";
	Else
		IdFieldName = "ID_" + ExpressionFieldName;
	EndIf;
	ExpressionWasUsedForField = False;
	
	ExpressionIDFound = ExpressionsInvolved[Expression];
		
	If ExpressionIDFound = Undefined Then
		ExpressionsInvolved.Insert(Expression, CurIDOfExpression);
		
		DefaultValues[IdFieldName] = CurIDOfExpression;
		
		ExpressionIdentificationParameters.CurIDOfExpression = CurIDOfExpression + 1;
	Else
		DefaultValues[IdFieldName] = ExpressionIDFound;
		
		CurIDOfExpression = ExpressionIDFound;
		
		FilterCombinations = New Structure("Expression, ExpressionFieldName", Expression, ExpressionFieldName); 
		ExpressionWasUsedForField = ExpressionOccursInField.FindRows(FilterCombinations).Count() <> 0;
	EndIf;
	
	If Not ExpressionWasUsedForField Then
	
		NewCombination = ExpressionOccursInField.Add();
		NewCombination["Expression"] = Expression;
		NewCombination.ExpressionFieldName = ExpressionFieldName;
		
		DCSExpression = ConvertToDCSExpression(Expression, NumericalExpression, ExpressionAnalytics);
		If ExpressionFieldName = "ExpressionPeriodBoundary"
			And ExpressionIdentificationParameters.GettingBalancesForPeriodBoundary Then
			// For target indicators, it is necessary to obtain balances for the period boundary.
			If ExpressionIdentificationParameters.ReductionToPeriodBoundaryIsUsed Then
				DCSExpression = "DataCompositionServer.PeriodBoundary(" + DCSExpression + ", ""Including"")";
			Else
				DCSExpression = "DATEADD(" + DCSExpression + ", ""Second"", 1)";
			EndIf;
		EndIf;
		PartsOfExpressions.Add(
			" WHEN "
			+ IdFieldName 
			+ " = " 
			+ CurIDOfExpression 
			+ " THEN " 
			+ DCSExpression);
		
	EndIf;
		
EndProcedure

Procedure RefineTermsOfDataExpressionsTakingIntoAccountDomainExpressions(Val FactParameters, GettingRateAtBeginningOfPeriod = False)
	
	If ValueIsFilled(FactParameters.Periodicity) And Not GettingRateAtBeginningOfPeriod Then
		PeriodExpression = "ExpressionPeriod";
		If TrimAll(Upper(FactParameters.ExpressionConditions[PeriodExpression])) = "UNDEFINED" Then // There is no period dimension in the report, the period is the beginning of the report period
			PeriodExpression = "ExpressionStartOfPeriod";
		EndIf;
	Else
		PeriodExpression = "ExpressionStartOfPeriod";
	EndIf;
	
	For Each AdditionalDataLine_ In FactParameters.AdditionalData.DataTable Do 
		AdditionalDataLine_["ID_" + "ExpressionForFillingCoursePeriod"] = AdditionalDataLine_["ID_" + PeriodExpression];
	EndDo;
	
	If PeriodExpression = "ExpressionStartOfPeriod" Then
		// In an optimized fact, the field of the beginning of the period is always calculated already taking into account the offset (the expression is passed in
		// the data source links to the set of combined facts as the source expression).
		// Executing the same expression in a calculated field over an already converted date is not required.
		FactParameters.ExpressionConditions.ExpressionForFillingCoursePeriod = "BeginOfPeriod";
	Else
		FactParameters.ExpressionConditions.ExpressionForFillingCoursePeriod = "RatePeriod";
	EndIf;
	
EndProcedure

Procedure SpecifyMaximumNumberOfAnalytics(FactParameters)
	MaximumNumberOfAnalytics = FactParameters.MaximumNumberOfAnalytics;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		If Not FactParameters.ExpressionConditions["DimensionPopulationExpression" + DimensionNumber] = ConvertToDCSExpression(ExpressingEmptyValue()) Then
			MaximumNumberOfAnalytics = DimensionNumber;
		EndIf;
	EndDo;
	
	FactParameters.MaximumNumberOfAnalytics = MaximumNumberOfAnalytics;
EndProcedure

// Collects ready-made expressions from separate parts for calculation in the SKD
//
Procedure GenerateExpressionConditions(Val FactParameters, Val ExpressionIdentificationParameters)
	
	Var PartOfOneExpression, ThisIsIndicatorExpression;
	
	For Each PartOfOneExpression In ExpressionIdentificationParameters.PartsOfExpressions Do 
		ThisIsIndicatorExpression = StrStartsWith(PartOfOneExpression.Key, "IndicatorExpression");
		
		If PartOfOneExpression.Value.Count() = 0 Then
			FactParameters.ExpressionConditions[PartOfOneExpression.Key] = "UNDEFINED";
		ElsIf PartOfOneExpression.Value.Count() = 1 Then
			ExpressionCondition = PartOfOneExpression.Value[0];
			
			If StrEndsWith(Upper(ExpressionCondition), "UNDEFINED") Then
				FactParameters.ExpressionConditions[PartOfOneExpression.Key] = "UNDEFINED";
			ElsIf StrEndsWith(ExpressionCondition, "0") Then
				FactParameters.ExpressionConditions[PartOfOneExpression.Key] = "0";
			Else
				BeginningOfExpression = StrFind(ExpressionCondition, "THEN");
				FactParameters.ExpressionConditions[PartOfOneExpression.Key] = Right(ExpressionCondition, StrLen(ExpressionCondition) - (BeginningOfExpression + 4));
			EndIf;
			
			FactParameters.ExpressionConditions[PartOfOneExpression.Key] = 
				?(ThisIsIndicatorExpression, "ZoomRatio * ", "") 
				+ FactParameters.ExpressionConditions[PartOfOneExpression.Key];
		Else
			FactParameters.ExpressionConditions[PartOfOneExpression.Key] = 
				?(ThisIsIndicatorExpression, "ZoomRatio * ", "")
				+ "CASE"
				+ Chars.LF 
				+ StrConcat(PartOfOneExpression.Value, Chars.LF) 
				+ Chars.LF
				+ "END"; //@Query-part-3 @Query-part-4
		EndIf;
		If StrStartsWith(PartOfOneExpression.Key, "IndicatorExpressionCount")
			And Not IsBlankString(FactParameters.ExpressionConditions.QuantityConversionExpression) Then
			FactParameters.ExpressionConditions[PartOfOneExpression.Key] = FactParameters.ExpressionConditions[PartOfOneExpression.Key]
				+ " / " + FactParameters.ExpressionConditions.QuantityConversionExpression;
		EndIf;
	EndDo;

EndProcedure

// Adds columns of additional data that are intended for mapping the fact to articles and indicators.
//
Procedure AddAdditionalDataColumns(AdditionalDataTable_, IndexOfAnalystNamesAndTypes)
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	ColumnsOfDataTable_ = AdditionalDataTable_.Columns;
	
	RequiredFilling_ = ColumnsOfDataTable_.Find("DataSourceID") = Undefined;
	
	If RequiredFilling_ Then
		DateTypeDetails   = Common.DateTypeDetails(DateFractions.Date);
		StringTypeDetails = Common.StringTypeDetails(0);
		IDTypeDescription  = Common.TypeDescriptionNumber(4,, AllowedSign.Nonnegative);
		DescriptionOfAddressType  = Common.TypeDescriptionNumber(1,, AllowedSign.Nonnegative);
		DescriptionOfCoefficientType  = Common.TypeDescriptionNumber(7,2);
		BooleanTypeDetails = New TypeDescription("Boolean");
		DescriptionOfTypeOfAnalytics = New TypeDescription("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions");
		DescriptionOfAnalyticsValueType = Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.Type;
		
		// The key of the data area and the fields of connection with generalized data
		ColumnsOfDataTable_.Add("DataSourceID", StringTypeDetails);
		ColumnsOfDataTable_.Add("SourcePrivilegedMode", BooleanTypeDetails);
		ColumnsOfDataTable_.Add("Period", DateTypeDetails);
		ColumnsOfDataTable_.Add("BeginOfPeriod", DateTypeDetails);
		ColumnsOfDataTable_.Add("EndOfPeriod", DateTypeDetails);
		ColumnsOfDataTable_.Add("ID_" + "ExpressionPeriod", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "ExpressionStartOfPeriod", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "ExpressionEndOfPeriod", IDTypeDescription);
		
		// Additional data
		ColumnsOfDataTable_.Add("ID_" + "Source1", StringTypeDetails); // ID of the budgeting data source
		
		ColumnsOfDataTable_.Add("RuleOfFact", DataSourcesCached.DescriptionOfRuleType());
		ColumnsOfDataTable_.Add("DataSourceObjectType");
		ColumnsOfDataTable_.Add("CacheOfDetailsForGettingSchema");
		ColumnsOfDataTable_.Add("HashOfDataCompositionSchema");
		
		ColumnsOfDataTable_.Add("RuleType", DataSourcesCached.DescriptionOfTypeOfBudgetingData());
		ColumnsOfDataTable_.Add("ZoomRatio", DescriptionOfCoefficientType);
		ColumnsOfDataTable_.Add("Expense", BooleanTypeDetails);
		ColumnsOfDataTable_.Add("UUID", StringTypeDetails);
		ColumnsOfDataTable_.Add("DataSource");
		ColumnsOfDataTable_.Add("BalancedAccount");
		
		ColumnsOfDataTable_.Add("BudgetFlowItem", New TypeDescription("CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems"));
		ColumnsOfDataTable_.Add("BudgetBalanceItem", New TypeDescription("CatalogRef.BudgetBalanceItems"));
		
		// Fields used to generate expression identifiers for numbered and named analytics.
		ColumnsOfDataTable_.Add("AdvancedModeOfDimensionFillSetting", BooleanTypeDetails);
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			ColumnsOfDataTable_.Add("DimensionKind" + DimensionNumber, DescriptionOfTypeOfAnalytics);
			ColumnsOfDataTable_.Add("DimensionPopulationExpression" + DimensionNumber); // String or Undefined
			ColumnsOfDataTable_.Add("ID_" + "DimensionPopulationExpression" + DimensionNumber, IDTypeDescription);
			ColumnsOfDataTable_.Add("FillInAnalyticsWithSpecifiedValue" + DimensionNumber, BooleanTypeDetails);
			ColumnsOfDataTable_.Add("DimensionValue" + DimensionNumber, DescriptionOfAnalyticsValueType);
		EndDo;
		ColumnsOfDataTable_.Add("TurnoverByExpenseDimension", BooleanTypeDetails);
		
		ColumnsOfDataTable_.Add("TransactionAmountSource", New TypeDescription("EnumRef.IndicatorsOfAnalyticalRegisters"));
		ColumnsOfDataTable_.Add("TypeOfAccountingDataReceipt", New TypeDescription("EnumRef.AccountingDataTypes"));
		ColumnsOfDataTable_.Add("TypeOfAccountingDataExpense", New TypeDescription("EnumRef.AccountingDataTypes"));
		ColumnsOfDataTable_.Add("DataSourceSection", New TypeDescription("EnumRef.SectionsOfBudgetingDataSources"));
		
		// Currency
		ColumnsOfDataTable_.Add("ID_" + "ExpressionForFillingInAnalyticsCurrency", IDTypeDescription);
		ColumnsOfDataTable_.Add("SourceOfForeignExchange", BooleanTypeDetails);
		ColumnsOfDataTable_.Add("CurrencyFilling", StringTypeDetails);
		ColumnsOfDataTable_.Add("DimensionAddressCurrency", DescriptionOfAddressType);
		ColumnsOfDataTable_.Add("DimensionCurrencyField", StringTypeDetails);
		
		// Storage currency
		ColumnsOfDataTable_.Add("ID_" + "ExpressionFillingAnalyticsStorageCurrency", IDTypeDescription);
		
		// The period of the course
		ColumnsOfDataTable_.Add("ID_" + "ExpressionForFillingCoursePeriod", IDTypeDescription);
		
		// Unit
		ColumnsOfDataTable_.Add("ID_" + "AnalyticsFillExpressionUnitOfMeasurement", IDTypeDescription);
		ColumnsOfDataTable_.Add("UnitOfMeasureFilling", StringTypeDetails);
		ColumnsOfDataTable_.Add("DimensionAddressUnitOfMeasure", DescriptionOfAddressType);
		ColumnsOfDataTable_.Add("FieldOfDimensionUnitOfMeasure", StringTypeDetails);
		ColumnsOfDataTable_.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		
		// Indicators of actual data
		ColumnsOfDataTable_.Add("IndicatorExpressionCount", StringTypeDetails);
		ColumnsOfDataTable_.Add("IndicatorExpressionAmountCurrency", StringTypeDetails);
		ColumnsOfDataTable_.Add("IndicatorExpressionAmountCurrencyMan", StringTypeDetails);
		ColumnsOfDataTable_.Add("IndicatorExpressionAmountCurrencyCompl", StringTypeDetails);
		ColumnsOfDataTable_.Add("AmountIndicatorExpressions");
		
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionCountOpeningBalance", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyOpeningBalance", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyManOpeningBalance", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyComplOpeningBalance", IDTypeDescription);
		
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionCountReceipt", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyReceipt", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyManReceipt", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyComplReceipt", IDTypeDescription);
		
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionCountExpense", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyExpense", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyManExpense", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyComplExpense", IDTypeDescription);
		
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionCountClosingBalance", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyClosingBalance", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyManClosingBalance", IDTypeDescription);
		ColumnsOfDataTable_.Add("ID_" + "IndicatorExpressionAmountCurrencyComplClosingBalance", IDTypeDescription);
		
		For Each NameTypeOfAnalytics In IndexOfAnalystNamesAndTypes Do 
			ColumnsOfDataTable_.Add("ID_" + NameTypeOfAnalytics.Key, IDTypeDescription);
		EndDo;
	EndIf;
	
EndProcedure

// Adds columns of the column Name type to the source table_Unique identifier
// When data is post-processed, these columns are collapsed into a single column of the column Name type.
//
Procedure AddColumnsOfUniqueIdentifiers(SourceTable, SourceColumns_)
	
	ParameterTypeSourceColumns = TypeOf(SourceColumns_);
	If ParameterTypeSourceColumns = Type("Array") Then
		CollectionOfSourceColumns = SourceColumns_;
	ElsIf ParameterTypeSourceColumns = Type("String") Then
		CollectionOfSourceColumns = StrSplit(SourceColumns_, ",", False);
	Else
		CollectionOfSourceColumns = New Array;
	EndIf;
	
	OneColumn = (CollectionOfSourceColumns.Count() = 1);
	
	For Each SourceColumn In CollectionOfSourceColumns Do 
		SourceColumnName_ = TrimAll(SourceColumn);
		NameOfColumnToAdd = ?(OneColumn, "", SourceColumnName_) + "UUID";
		
		SourceTable.Columns.Add(NameOfColumnToAdd);
		
		For Each InitialString In SourceTable Do
			InitialString[NameOfColumnToAdd] = DataCompositionServer.RowUniqueIdentifier(InitialString[SourceColumnName_]);
		EndDo;
	EndDo;
	
EndProcedure 

Function DataSourceObjectsForScenariosToExcludeReceiptOfFact(DataSource, DataParameters)
	
	QueriesTexts =
		InformationRegisters.OpeningBalanceOfEstimates.QueryTextsCurrentBalanceDatesByScenario(False, False, True);
	
	QueryText = 
	"SELECT
	|	CurrentBalanceDatesByScenario.BudgetBalanceItem AS BudgetBalanceItem,
	|	CurrentBalanceDatesByScenario.Scenario AS Scenario,
	|	&Id AS ID_Source1
	|FROM
	|	CurrentBalanceDatesByScenario AS CurrentBalanceDatesByScenario
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	OpeningBalanceOfEstimates.BudgetBalanceItem,
	|	BudgetingScenarios.Scenario,
	|	&Id AS ID_Source1
	|FROM
	|	InformationRegister.OpeningBalanceOfEstimates AS OpeningBalanceOfEstimates
	|		LEFT JOIN BudgetingScenarios AS BudgetingScenarios
	|		ON (BudgetingScenarios.Scenario <> VALUE(Catalog.BudgetingScenarios.BudgetFulfillment))
	|WHERE
	|	OpeningBalanceOfEstimates.DateOfRemainingGoods = &StartingDateOfBalances
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CurrentBalanceDates
	|			WHERE
	|				CurrentBalanceDates.DateOfRemainingGoods = OpeningBalanceOfEstimates.DateOfRemainingGoods
	|				AND CurrentBalanceDates.BudgetBalanceItem = OpeningBalanceOfEstimates.BudgetBalanceItem)
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					CurrentBalanceDatesByScenario
	|				WHERE
	|					CurrentBalanceDatesByScenario.DateOfRemainingGoods = OpeningBalanceOfEstimates.DateOfRemainingGoods
	|					AND CurrentBalanceDatesByScenario.BudgetBalanceItem = OpeningBalanceOfEstimates.BudgetBalanceItem
	|					AND CurrentBalanceDatesByScenario.Scenario = BudgetingScenarios.Scenario)
	|	AND OpeningBalanceOfEstimates.Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef)";
	QueriesTexts.Add(QueryText);
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	QueryText = StrReplace(QueryText, "&StartingDateOfBalances", DataSource.ExpressionStartOfPeriod);
	QueryText = StrReplace(QueryText, "&ConditionScenario", ?(ValueIsFilled(DataParameters.Scenario),
		"BudgetingScenarios.Ref = &Scenario", "TRUE")); // @query-part
	QueryText = StrReplace(QueryText, "&ConditionIndicatorOfBudgets",
		"OpeningBalanceOfEstimates.BudgetBalanceItem IN (&Objects)"); // @query-part
	
	Query = New Query(QueryText);
	For Each ParameterName In StrSplit("Objects,Id", ",") Do
		Query.SetParameter(ParameterName, DataSource[ParameterName]);
	EndDo;
	For Each ParameterName In StrSplit("Scenario,BeginOfPeriod,EndOfPeriod,ActualDataLimit", ",") Do
		Query.SetParameter(ParameterName, DataParameters[ParameterName]);
	EndDo;
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns rules for getting a fact for articles and metrics
//
// Parameters:
//  DataSource - Structure - data source parameters. See the details of the budget Reportcashserver.Add a source().
//  ReportScript - CatalogRef.BudgetingScenarios - The script of the report, if appropriate.
//                 - Undefined - If the report script is not specified.
//
// Returns:
//  ValueTable - table of rules for obtaining actual data. For more information, see the property of the table of directionstates in the sourceserverserver.The template of the parameters of the receipt of the fact().
//
Function RulesForGettingDataSourceFact(DataSource, ReportScript, ObjectsByDataSource)
	
	ReportScenarioActualData = (ReportScript = Catalogs.BudgetingScenarios.ActualData);
	ScenarioOfBudgetExecutionReport = (ReportScript = Catalogs.BudgetingScenarios.BudgetFulfillment);
	
	RulesForGettingDataSourceFact = Undefined;
	
	SourcesTypes  = Enums.BudgetingDataSourceTypes;
	TypesOfFactRules = Enums.ActualBudgetingDataQueryRuleType;
	
	ContinueCalculation = True;
	TemplateName = "ActualDataQueryRules_";
	If DataSource.SourceType = SourcesTypes.Turnovers 
		And Not DataSource.ThereAreTargets_ Then
		SourceCatalogName = "ActualDataQueryRulesByBudgetFlowItems";
		FilterFieldName = "BudgetFlowItem";
	ElsIf DataSource.SourceType = SourcesTypes.Balance 
		Or DataSource.ThereAreTargets_ Then
		SourceCatalogName = "ActualDataQueryRulesByBudgetBalanceItems";
		FilterFieldName = "BudgetBalanceItem";
	Else
		ContinueCalculation = False;
	EndIf;
	
	If ContinueCalculation Then
		SetPrivilegedMode(True);
		
		SelectionValuesByArticlesIndicators = New ValueList;
		SelectionValuesByArticlesIndicators.LoadValues(ObjectsByDataSource);
		
		LayoutDiagramForTheseRules = DataSourcesCached.GettingCatalogTemplate(SourceCatalogName, TemplateName);
		DCSRules = DataCompositionServer.CopyDataLayoutDiagram(LayoutDiagramForTheseRules);
		Settings = InitializedDefaultSettings(DCSRules);
		
		AssumedFact = DataSource.AssumesActualData = "Assumed"
			Or (DataSource.AssumesActualData = "DeterminedByReportSettings"
				And ReportScenarioActualData);
		BudgetExecutionIsExpected = DataSource.AssumesBudgetExecution = "Assumed"
			Or (DataSource.AssumesBudgetExecution = "DeterminedByReportSettings"
				And ScenarioOfBudgetExecutionReport);
		
		ListOfRuleTypes = New ValueList;
		If AssumedFact Or BudgetExecutionIsExpected Then
			ListOfRuleTypes.Add(TypesOfFactRules.BudgetFulfillmentAndActualData);
		EndIf;
		If AssumedFact Then
			ListOfRuleTypes.Add(TypesOfFactRules.ActualData);
		EndIf;
		If BudgetExecutionIsExpected Then
			ListOfRuleTypes.Add(TypesOfFactRules.BudgetFulfillment);
		EndIf;
		
		FinancialReportingServer.SetFilter(Settings.Filter, "RuleType", ListOfRuleTypes, DataCompositionComparisonType.InList);
		If ValueIsFilled(ReportScript) Then
			If (AssumedFact And ReportScenarioActualData
				Or BudgetExecutionIsExpected And ScenarioOfBudgetExecutionReport)
				And Settings.FilterAvailableFields.FindField(New DataCompositionField("Scenario")) <> Undefined Then
				FinancialReportingServer.SetFilter(Settings.Filter, "Scenario", ReportScript, DataCompositionComparisonType.Equal);
			EndIf;
		EndIf;
		
		FinancialReportingServer.SetFilter(Settings.Filter, FilterFieldName, SelectionValuesByArticlesIndicators, DataCompositionComparisonType.InList);
		
		FilterByRegistrar = FinancialReportingServer.FindSelectionElement(DataSource.AdditionalSelection.Filter, "Recorder");
		TakeIntoAccountOperationalAccountingLimits = GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters")
			And FilterByRegistrar <> Undefined And FilterByRegistrar.ComparisonType = DataCompositionComparisonType.Equal;
		
		If DataSource.SourceType = SourcesTypes.Turnovers 
			And Not DataSource.ThereAreTargets_ Then
			If TakeIntoAccountOperationalAccountingLimits Then
				FiltersGroupOR = FinancialReportingServer.NewFilter(Settings.Filter, Undefined, , Type(
					"DataCompositionFilterItemGroup"));
				FiltersGroupOR.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
				FiltersGroupAnd = FinancialReportingServer.NewFilter(FiltersGroupOR, Undefined, , Type(
					"DataCompositionFilterItemGroup"));
				FiltersGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				FinancialReportingServer.SetFilter(FiltersGroupAnd, "DataSourceSection",
					Enums.SectionsOfBudgetingDataSources.OperationalAccounting,
					DataCompositionComparisonType.Equal);
					FinancialReportingServer.SetFilter(FiltersGroupAnd, "RuleType",
					Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment,
					DataCompositionComparisonType.Equal);
				FiltersGroupAnd = FinancialReportingServer.NewFilter(FiltersGroupOR, Undefined, , Type(
					"DataCompositionFilterItemGroup"));
				FiltersGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				FinancialReportingServer.SetFilter(FiltersGroupAnd,
						"DataSourceSection",
						Enums.SectionsOfBudgetingDataSources.OperationalAccounting,
						DataCompositionComparisonType.NotEqual);
				FinancialReportingServer.SetFilter(FiltersGroupAnd,
						"CachingOfRuleResults",
						False,
						DataCompositionComparisonType.Equal);
			Else
				FinancialReportingServer.SetFilter(Settings.Filter,
						"CachingOfRuleResults",
						False,
						DataCompositionComparisonType.Equal);
			EndIf;
		EndIf;
		
		If ValueIsFilled(DataSource.DependentDataSourceIndicator) Then
			FinancialReportingServer.SetFilter(Settings.Filter, "BudgetBalanceItem", DataSource.DependentDataSourceIndicator);
		ElsIf DataSource.SourceType = SourcesTypes.Turnovers 
			And Not DataSource.ThereAreTargets_ Then
			FinancialReportingServer.SetFilter(Settings.Filter, "BudgetBalanceItem", , DataCompositionComparisonType.NotFilled);
		EndIf;
		
		// We will get the rules in the form of a table with the values of the details
		RulesForGettingDataSourceFact = FinancialReportingServer.UploadDCSResults(DCSRules, Settings);
		
		If DataSource.SourceType = SourcesTypes.Balance Then
			ToDetermineNeedToLimitNumberOfExtDimension(
				RulesForGettingDataSourceFact,
				Enums.SectionsOfBudgetingDataSources.FinancialAccounting);
		EndIf;
		
		RulesForGettingDataSourceFact.Columns.Add("DataSourceObjectType");
		RulesForGettingDataSourceFact.FillValues(Type("CatalogRef." + SourceCatalogName), "DataSourceObjectType");
		
		SetPrivilegedMode(False);
	EndIf;
	
	RuleColumn = RulesForGettingDataSourceFact.Columns.Rule; // ValueTableColumn -
	RuleColumn.Name = "RuleOfFact";
	
	Return RulesForGettingDataSourceFact;
	
EndFunction

Procedure AdaptFieldExpression(OriginalExpression, IDPrefix = "", Val ExpressionConditions)
	
	PreparedExpression = "";
	
	If StrStartsWith(OriginalExpression, "ExpressionStartOfPeriod")
		Or StrStartsWith(OriginalExpression, "ExpressionEndOfPeriod")
		Or StrStartsWith(OriginalExpression, "ExpressionPeriod")
		Or StrStartsWith(OriginalExpression, "ExpressionPeriodBoundary")
		Or StrStartsWith(OriginalExpression, "DimensionPopulationExpression")
		Or StrStartsWith(OriginalExpression, "ExpressionForFillingCoursePeriod")
		Or StrStartsWith(OriginalExpression, "ExpressionForFillingInAnalyticsCurrency")
		Or StrStartsWith(OriginalExpression, "ExpressionFillingAnalyticsStorageCurrency")
		Or StrStartsWith(OriginalExpression, "IndicatorExpression")
		Or StrStartsWith(OriginalExpression, "ExpressionOfNamedAnalytics")
		Then
		If ExpressionConditions.Property(OriginalExpression, PreparedExpression) Then
			
			PreparedExpression = StrReplace(PreparedExpression, "ID_", IDPrefix + "ID_");
			PreparedExpression = StrReplace(PreparedExpression, "&" + "BEGINOFPERIOD", IDPrefix + "BEGINOFPERIOD");
			PreparedExpression = StrReplace(PreparedExpression, "&" + "ENDOFPERIOD", IDPrefix + "ENDOFPERIOD");
			PreparedExpression = StrReplace(PreparedExpression, "&" + "PERIOD", IDPrefix + "PERIOD");
			
			OriginalExpression = PreparedExpression;
		Else
			OriginalExpression = "UNDEFINED";
		EndIf;
	EndIf;

EndProcedure

Procedure AdaptExpressionOfPlanningPeriod(OriginalExpression, ExpressingPlanningPeriod, ExpressionOfRatePeriod)
	
	OriginalExpression = Upper(OriginalExpression);
	
	OriginalExpression = StrReplace(OriginalExpression, "PLANNINGPERIOD", ExpressingPlanningPeriod);
	OriginalExpression = StrReplace(OriginalExpression, "RATEPERIOD", ExpressionOfRatePeriod);
	
EndProcedure

// Uploads data to the passed table using the SKD layout, enabling privileged mode if necessary.
//
Procedure UploadResultAccordingToLayoutTakingIntoAccountAccessRestrictions(TableToFillIn, DataAcquisitionTemplate, ExternalDataSets, PrivilegedMode)
	
	If PrivilegedMode Then
		SetPrivilegedMode(True);
	EndIf;
	
	PrivilegedModeParameter = DataAcquisitionTemplate.ParameterValues.Find("PrivilegedMode");
	If PrivilegedModeParameter <> Undefined Then
		PrivilegedModeParameter.Value = PrivilegedMode;
	EndIf;
	
	If TypeOf(TableToFillIn) = Type("ValueTable") Then
		CommonClientServer.SupplementTable(
			FinancialReportingServer.UploadDCSResultsFromTemplate(DataAcquisitionTemplate, ExternalDataSets),
			TableToFillIn);
	Else
		TableToFillIn = FinancialReportingServer.UploadDCSResultsFromTemplate(DataAcquisitionTemplate, ExternalDataSets);
	EndIf;

	If PrivilegedMode Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Function ExpressionIdentificationParameterTemplate(FieldCompositionSettings)
	
	Var ExpressionIdentificationParameters;
	
	ExpressionIdentificationParameters = New Structure;
	
	ExpressionIdentificationParameters.Insert("CurIDOfExpression", 1);
	ExpressionIdentificationParameters.Insert("ExpressionsInvolved", New Map); // The key is an expression, the Value is the identifier of the expression condition
	
	ExpressionOccursInField = New ValueTable;
	ExpressionOccursInField.Columns.Add("Expression");
	ExpressionOccursInField.Columns.Add("ExpressionFieldName");
	ExpressionIdentificationParameters.Insert("ExpressionOccursInField", ExpressionOccursInField);
	
	// Expandable structure. Properties of the type "id_imiapoviduanalytics" can be added, for example, "ID_Partners".
	PartsOfExpressions = New Structure; 
	DefaultValues = New Structure;
	
	// Period Expressions
	PartsOfExpressions.Insert("ExpressionStartOfPeriod", New Array);
	PartsOfExpressions.Insert("ExpressionEndOfPeriod", New Array);
	PartsOfExpressions.Insert("ExpressionPeriod", New Array);
	PartsOfExpressions.Insert("ExpressionPeriodBoundary", New Array);
	
	DefaultValues.Insert("ID_" + "ExpressionStartOfPeriod");
	DefaultValues.Insert("ID_" + "ExpressionEndOfPeriod");
	DefaultValues.Insert("ID_" + "ExpressionPeriod");
	DefaultValues.Insert("GettingBalancesForPeriodBoundary", False);
	
	DefaultValues.Insert("BeginOfPeriod");
	DefaultValues.Insert("EndOfPeriod");
	DefaultValues.Insert("Period");
	
	// Analyst expressions
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		PartsOfExpressions.Insert("DimensionPopulationExpression" + DimensionNumber, New Array);
	EndDo;
	
	// Expressions of quantitative indicators
	If FieldCompositionSettings.QuantityRequired Then
		PartsOfExpressions.Insert("AnalyticsFillExpressionUnitOfMeasurement", New Array);
		PartsOfExpressions.Insert("IndicatorExpressionCountOpeningBalance", New Array);
	EndIf;
	
	// Expressions of summary indicators
	If FieldCompositionSettings.AmountRequired Then
		PartsOfExpressions.Insert("ExpressionForFillingCoursePeriod", New Array);
		PartsOfExpressions.Insert("ExpressionForFillingInAnalyticsCurrency", New Array);
		PartsOfExpressions.Insert("ExpressionFillingAnalyticsStorageCurrency", New Array);
		
		If FieldCompositionSettings.AmountRequiredOpeningBalance Then 
			PartsOfExpressions.Insert("IndicatorExpressionAmountCurrencyOpeningBalance", New Array);
			PartsOfExpressions.Insert("IndicatorExpressionAmountCurrencyManOpeningBalance", New Array);
			PartsOfExpressions.Insert("IndicatorExpressionAmountCurrencyComplOpeningBalance", New Array);
		EndIf;
		
		If FieldCompositionSettings.AmountRequiredReceipt Then 
			PartsOfExpressions.Insert("IndicatorExpressionCountReceipt", New Array);
			PartsOfExpressions.Insert("IndicatorExpressionAmountCurrencyReceipt", New Array);
			PartsOfExpressions.Insert("IndicatorExpressionAmountCurrencyManReceipt", New Array);
			PartsOfExpressions.Insert("IndicatorExpressionAmountCurrencyComplReceipt", New Array);
		EndIf;
		
		If FieldCompositionSettings.AmountRequiredExpense Then 
			PartsOfExpressions.Insert("IndicatorExpressionCountExpense", New Array);
			PartsOfExpressions.Insert("IndicatorExpressionAmountCurrencyExpense", New Array);
			PartsOfExpressions.Insert("IndicatorExpressionAmountCurrencyManExpense", New Array);
			PartsOfExpressions.Insert("IndicatorExpressionAmountCurrencyComplExpense", New Array);
		EndIf;
	EndIf;
	
	DefaultValues.Insert("SourcePrivilegedMode");
	DefaultValues.Insert("ID_" + "Source1");
	DefaultValues.Insert("BudgetBalanceItem");
	
	ExpressionIdentificationParameters.Insert("PartsOfExpressions", PartsOfExpressions);
	ExpressionIdentificationParameters.Insert("DefaultValues", DefaultValues);
	
	// Expandable structure. Properties of the type "id_imiapoviduanalytics" can be added, for example, "ID_Partners".
	DefaultValuesAndData = New Structure;
	For Each PartOfExpression In PartsOfExpressions Do
		If StrStartsWith(PartOfExpression.Key, "IndicatorExpression")
			Or StrStartsWith(PartOfExpression.Key, "DimensionPopulationExpression")
			Or PartOfExpression.Key = "ExpressionForFillingInAnalyticsCurrency"
			Or PartOfExpression.Key = "ExpressionFillingAnalyticsStorageCurrency" Then
			DefaultValuesAndData.Insert("ID_" + PartOfExpression.Key);
		EndIf;
	EndDo;

	DefaultValuesAndData.Insert("ID_" + "ExpressionForFillingCoursePeriod");
	// Additional selection of the budget type element
	DefaultValuesAndData.Insert("AdditionalSelection");
	
	ExpressionIdentificationParameters.Insert("DefaultValuesAndData", DefaultValuesAndData);
	
	// The targets are separated into separate data sources.
	// The parameter is used as a flag for the need to get balances taking into account the period boundary (parameter &Period Boundary).
	ExpressionIdentificationParameters.Insert("GettingBalancesForPeriodBoundary", False);
	ExpressionIdentificationParameters.Insert("ReductionToPeriodBoundaryIsUsed", ReductionToBoundaryOfPeriodInConnectionsOfSchemeForObtainingFactIsUsed());
	
	Return ExpressionIdentificationParameters;

EndFunction

Procedure AddDataSourcesForInfluentialArticles(DataSources)
	
	SourcesTypes = Enums.BudgetingDataSourceTypes;
	
	OriginalNumberOfSources = DataSources.Count();
	DataSources.Columns.Add("DependentDataSourceIndicator");
	
	BudgetBalanceItems = New Array;
	
	For TheIndexOfTheSource = 0 To OriginalNumberOfSources - 1 Do
		DataSource = DataSources[TheIndexOfTheSource];
		
		// When getting data from the document itself, NON-online ones are used 
		If Not DataSource.SourceType = SourcesTypes.Balance Then // Only the indicators have influential articles
			Continue;
		EndIf;
		
		SourceObjects = DataSource.Objects; // Array of CatalogRef.BudgetBalanceItems, CatalogRef.BudgetFlowItems -
		If SourceObjects = Undefined Then
			Continue;
		EndIf;
		For Each Object_Source In SourceObjects Do
			BudgetBalanceItems.Add(Object_Source);
		EndDo;
	EndDo;
	
	If BudgetBalanceItems.Count() = 0 Then
		Return;
	EndIf;
	
	// Let's prepare a table of rules according to which it is planned to receive data
	SetPrivilegedMode(True);
	
	// There is a method for data sources
	DataCompositionSchema = Catalogs.ActualDataQueryRulesByBudgetFlowItems.GetTemplate("ActualDataQueryRules_");
	
	Settings = DataCompositionSchema.DefaultSettings;
	
	// We will add a selection that ensures the selection of only articles that affect the indicators
	FilterElement = FinancialReportingServer.FindSelectionElement(Settings.Filter, "BudgetBalanceItem");
	If FilterElement = Undefined Or Not FilterElement.Use Then
		DataCompositionClientServer.AddFilter(Settings, "BudgetBalanceItem", BudgetBalanceItems, DataCompositionComparisonType.InList);
	EndIf;
	FinancialReportingServer.NewSelectionField(Settings, "BudgetBalanceItem");
	
	DataCompositionClientServer.AddFilter(Settings, 
		"CachingOfRuleResults", False, 
		DataCompositionComparisonType.Equal);
	
	TableOfArticleRules = FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings);
	TableOfArticleRules.Columns.Add("DataSourceObjectType");
	TableOfArticleRules.FillValues(Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"), "DataSourceObjectType");
	TableOfArticleRules.Indexes.Add("BudgetBalanceItem");
	
	SetPrivilegedMode(False);
	
	If TableOfArticleRules.Count() > 0 Then
		For TheIndexOfTheSource = 0 To OriginalNumberOfSources - 1 Do
			DataSource = DataSources[TheIndexOfTheSource];
			
			// When getting data from the document itself, NON-online ones are used 
			If Not DataSource.SourceType = SourcesTypes.Balance Then // Only the indicators have influential articles
				Continue;
			EndIf;
			If SourceObjects = Undefined Then
				Continue;
			EndIf;
			
			SourceObjects = DataSource.Objects;
			For Each Object_Source In SourceObjects Do
				Filter = New Structure("BudgetBalanceItem", Object_Source);
				FoundRows = TableOfArticleRules.FindRows(Filter);
				
				If FoundRows.Count() > 0 Then
					NewSource = DataSources.Add();
					FillPropertyValues(NewSource, DataSource,,"SourceType, Objects, CalculationsRules");
					NewSource.AssumesActualData = DataSource.InfluencingArticlesAndFactualData;
					NewSource.AssumesBudgetExecution = DataSource.AffectingItemsInvolvesBudgetExecution;
					NewSource.InfluencingArticlesAndFactualData = "";
					NewSource.AffectingItemsInvolvesBudgetExecution = "";
					
					NewSource.Objects = New Array;
					
					NewSource.DependentDataSourceIndicator = Object_Source;
					NewSource.SourceType = SourcesTypes.Turnovers;
					
					For Each ArticleRule In FoundRows Do
						Objects = NewSource.Objects; // Array -
						Objects.Add(ArticleRule.BudgetFlowItem);
					EndDo;
					NewSource.Objects = CommonClientServer.CollapseArray(NewSource.Objects);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

Function UseAlternativeAlgorithm()
	UseAlternativeAlgorithm = True;
	Return UseAlternativeAlgorithm;
EndFunction

Function ReductionToBoundaryOfPeriodInConnectionsOfSchemeForObtainingFactIsUsed()
	SystemInfo = New SystemInfo;
	CurrentMode = Metadata.CompatibilityMode;
	Modes = Metadata.ObjectProperties.CompatibilityMode;
	
	VersionWithCastToBorder = "8.3.14";
	
	PlatformVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(SystemInfo.AppVersion);
	If CommonClientServer.CompareVersionsWithoutBuildNumber(PlatformVersion, VersionWithCastToBorder) >= 0
		And CurrentMode = Modes.DontUse Then
		Result = True;
	Else
		Result = False;
	EndIf;
	
	Return Result;
EndFunction

Procedure ToDetermineNeedToLimitNumberOfExtDimension(ActualDataQueryRules_, DataSourcesSection)
	
	SelectionBySectionOfDataSources = New Structure("DataSourceSection", DataSourcesSection);
	RulesForDataSourcesSection = ActualDataQueryRules_.FindRows(SelectionBySectionOfDataSources);
	
	ThereIsLimitToNumberOfExtDimension = False;
	For Each RulesRow In RulesForDataSourcesSection Do
		If RulesRow.LimitationOfNumberOfExtDimension > 0 Then
			ThereIsLimitToNumberOfExtDimension = True;
			Break;
		EndIf;
	EndDo;
	
	If ThereIsLimitToNumberOfExtDimension Then
		NumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		NumberOfExtDimensionInTermsOf = 0;
		
		For Each RulesRow In RulesForDataSourcesSection Do
			ExtDimensionCount = 0;
			For DimensionNumber = 1 To NumberOfAnalysts Do
				DimensionPopulationExpression = RulesRow["DimensionPopulationExpression" + DimensionNumber];
				If Not IsBlankString(DimensionPopulationExpression) Then
					DataPathParts = StrSplit(DimensionPopulationExpression, ".");
					For Each DataPath In DataPathParts Do
						If StrStartsWith(DataPath, "ExtDimension") Then
							ExtDimensionNumber = Number(Right(DataPath, 1));
							ExtDimensionCount = Max(ExtDimensionCount, ExtDimensionNumber);
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
			If RulesRow.LimitationOfNumberOfExtDimension > 0 Then
				If ExtDimensionCount < RulesRow.LimitationOfNumberOfExtDimension Then
					RulesRow.LimitationOfNumberOfExtDimension = ExtDimensionCount;
				Else
					RulesRow.LimitationOfNumberOfExtDimension = -1;
				EndIf;
			EndIf;
			If ExtDimensionCount > NumberOfExtDimensionInTermsOf Then
				NumberOfExtDimensionInTermsOf = ExtDimensionCount;
			EndIf;
		EndDo;
		
		For Each RulesRow In RulesForDataSourcesSection Do
			If RulesRow.LimitationOfNumberOfExtDimension >= 0 Then
				If RulesRow.LimitationOfNumberOfExtDimension < NumberOfExtDimensionInTermsOf Then
					RulesRow.DataSourceID = RulesRow.DataSourceID + RulesRow.LimitationOfNumberOfExtDimension;
				Else
					RulesRow.LimitationOfNumberOfExtDimension = -1;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure ReduceExtDimensionOfSourceIfNecessary(Template, NameOfDataSource, LimitationOfNumberOfExtDimension, MaxExtDimensionCount)
	
	If LimitationOfNumberOfExtDimension >= 0 Then
		QueryText = Template.DataSets[NameOfDataSource].Query;
		ExtDimensionNumber = LimitationOfNumberOfExtDimension + 1;
		While ExtDimensionNumber <= MaxExtDimensionCount Do
			QueryText = StrReplace(
				QueryText,
				NameOfDataSource + ".ExtDimension" + ExtDimensionNumber + ".*",
				"UNDEFINED");
			QueryText = StrReplace(
				QueryText,
				NameOfDataSource + ".ExtDimension" + ExtDimensionNumber,
				"UNDEFINED");
			ExtDimensionNumber = ExtDimensionNumber + 1;
		EndDo;
		Template.DataSets[NameOfDataSource].Query = QueryText;
	EndIf;
	
EndProcedure

#EndRegion
#Region SettingUpRoutineTaskForCreatingBudgetTasks

// Gets the parameters of the scheduled task for the budgeting model and sets the details on the form.
//
// Parameters:
// 	Form - ClientApplicationForm - form of the budgeting model reference element.
//
Procedure GetScheduleForRoutineTask(Form) Export
	
	Form.Schedule = New JobSchedule;
	
	Object = Form.Object; // CatalogObject.BudgetingModels -
	If Object.Ref.IsEmpty() Then
		
		Form.Schedule.BeginTime = '00010101220000'; // at 10:00 pm
		Form.Schedule.DaysRepeatPeriod = 1; //every day
		
	Else
		
		SetPrivilegedMode(True);
		JobID = Form.Object.ScheduledJob;
		If TypeOf(JobID) = Type("UUID") Then
			Job = ScheduledJobsServer.Job(JobID);
			If Job <> Undefined Then
				Form.Schedule = Job.Schedule;
			EndIf;
		EndIf; 
		
	EndIf;
	
EndProcedure

// Creates an instance of a scheduled task when the conditions for executing the scheduled task are met.
// Called from the "Before writing" event handler in the budgeting model reference.
//
// Parameters:
// 	Object - CatalogObject.BudgetingModels - the object being recorded.
// 	Cancel  - Boolean - indicates that the model is not being recorded.
//
Procedure CheckInstanceOfRoutineTask(Object, Cancel) Export
	
	If Cancel Or Object.IsFolder Then
		Return;
	EndIf;
	
	// Creating a routine task (obtaining a unique identifier)
	SetPrivilegedMode(True);
	
	Job = ScheduledJobsServer.Job(Object.ScheduledJob);
	CreateJob = GetFunctionalOption("UseBudgetProcess")
			And Job = Undefined
			And Object.AutomaticallyGenerateTasks
			And Object.Status = Enums.BudgetingModelStatuses.Valid
			And Not Object.DeletionMark;
	
	If CreateJob Then
		
		JobDescription = NStr("vi = 'Tạo nhiệm vụ ngân sách theo mô hình: %1';
								|ru = 'Формирование бюджетных задач по модели: %1';
								|en = 'Budget task generation according to the model: %1'; fa = 'Budget task generation according to the model: %1';
								|it = 'Creazione dei compiti di bilancio secondo il modello: %1';
								|pl = 'Tworzenie zadań budżetowych według modelu: %1';
								|tr = 'Bütçe görevinin şu formüle göre oluşturulması: %1'");
		JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
			JobDescription, TrimAll(Object.Description));
		
		JobParameters = New Structure;
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.BudgetTasksGeneration);
		JobParameters.Insert("Use", False);
		JobParameters.Insert("Description",  JobDescription);
		
		Job = ScheduledJobsServer.AddJob(JobParameters);
		Object.ScheduledJob = ScheduledJobsServer.UUID(Job);
		
	EndIf;
	
	Object.AdditionalProperties.Insert("Job",Job);
	SetPrivilegedMode(False);
	
EndProcedure

// Called from the "on write" event handler in the budgeting model reference.
// Sets parameters for a routine task:
// 				- Usage
// 				- Schedule
// 				- Name.
//
// Parameters:
// 	Object - CatalogObject.BudgetingModels - the object being recorded.
// 	Cancel - Boolean - indicates that the model is not being recorded.
//
Procedure SetParametersForRoutineTaskInstance(Object, Cancel) Export
	
	If Cancel Or Object.IsFolder Then
		Return;
	EndIf;
	
	If Object.AdditionalProperties.Property("Job") Then
		Job = Object.AdditionalProperties.Job;
		If Job = Undefined Then
			Return;
		EndIf;
	Else
		Return;
	EndIf;
	
	RecordTask = False;
	JobParameters = New Structure;
	
	// The schedule is set in the form of an element
	If Object.AdditionalProperties.Property("Schedule") 
		And TypeOf(Object.AdditionalProperties.Schedule) = Type("JobSchedule")
		And String(Object.AdditionalProperties.Schedule) <> String(Job.Schedule) Then
	
		JobParameters.Insert("Schedule", Object.AdditionalProperties.Schedule);
		RecordTask = True;
		
	EndIf;
	
	// Usage is set in the form of an element
	If GetFunctionalOption("UseBudgetProcess")
		And Object.Status = Enums.BudgetingModelStatuses.Valid
		And Object.AutomaticallyGenerateTasks	
		And Not Object.DeletionMark Then
		
		JobParameters.Insert("Use", True);
		
	Else
		
		JobParameters.Insert("Use", False);
		
	EndIf;
	If JobParameters.Use <> Job.Use Then
		RecordTask = True;
	EndIf;

	JobDescription = NStr("vi = 'Tạo nhiệm vụ ngân sách theo mô hình: %1';
							|ru = 'Формирование бюджетных задач по модели: %1';
							|en = 'Budget task generation according to the model: %1'; fa = 'Budget task generation according to the model: %1';
							|it = 'Creazione dei compiti di bilancio secondo il modello: %1';
							|pl = 'Tworzenie zadań budżetowych według modelu: %1';
							|tr = 'Bütçe görevinin şu formüle göre oluşturulması: %1'");
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		JobDescription, TrimAll(Object.Description));
	JobParameters.Insert("Description", JobDescription);
	If TypeOf(Job) = Type("ScheduledJob")
		And JobParameters.Description <> Job.Description Then
		RecordTask = True;
	EndIf;
	
	If Job.Parameters.Count() <> 1 Or Job.Parameters[0] <> Object.Ref Then
		Parameters = New Array;
		Parameters.Add(Object.Ref);
		JobParameters.Insert("Parameters", Parameters);
		RecordTask = True;
	EndIf;
	
	If RecordTask Then
		SetPrivilegedMode(True);
		ScheduledJobsServer.ChangeJob(Object.ScheduledJob, JobParameters);
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

// Deletes an instance of a scheduled task.
// Called from the "Before deleting" event handler in the budgeting model reference.
//
// Parameters:
// 	Object - CatalogObject.BudgetingModels - the object being deleted.
// 	Cancel - Boolean - indicates whether the model was not deleted.
//
Procedure DeleteInstanceOfRoutineTask(Object, Cancel) Export
	
	If Cancel Or Object.IsFolder Then
		Return;
	EndIf;
	
	ScheduledJobsServer.DeleteJob(Object.ScheduledJob);
	
EndProcedure

#EndRegion
#Region EventHandlers

Procedure BudgetEntryFormAttachedFilesBeforeWriteBeforeWrite(Source, Cancel) Export
	
	If ValueIsFilled(Source.ServiceFileType)
		And ValueIsFilled(Source.BeingEditedBy) Then
		
		ErrorText = NStr("vi = 'Tệp là hệ thống
									|Cấm soạn tệp';
									|ru = 'Файл является служебным
									|Редактирование файла запрещено';
									|en = 'This file is for technical use
									|Editing is prohibited'; fa = 'This file is for technical use
									|Editing is prohibited';
									|it = 'Il file risulta essere di servizio
									|La modifica del file non è permessa';
									|pl = 'To jest plik serwisowy
									|Edycja pliku jest zabroniona';
									|tr = 'Dosya hizmet dosyasıdır
									|Dosyanın düzenlenmesi yasaktır'");
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

#EndRegion

Procedure PerformReflectionOfPlanningDocumentsInBudgeting(Jobs, IdsOfUnprocessedRecords,
	AdditionalProperties = Undefined) Export
	
	DocumentsForProcessing_ = Jobs.UnloadColumn("Document");
	If DocumentsForProcessing_.Count() = 0 Then
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("CommonModule.BudgetingServer.PerformReflectionOfPlanningDocumentsInBudgeting");
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.SetParameter("DocumentsForProcessing_", DocumentsForProcessing_);
	Query.SetParameter("LimitsRegisterIsUsed",
		LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed());
	Query.TempTablesManager = TempTablesManager;
	
	QueriesTexts = New Array;
	QueriesTexts.Add(
		"SELECT
		|	Plan.Ref AS Recorder,
		|	Plan.Date AS Date,
		|	Plan.BudgetingScenario AS Scenario,
		|	VALUE(Enum.DataSourceTypesForBudgeting.InventoryConsumptionPlans) AS SourceType
		|INTO DocumentsToBeProcessedBySourceType
		|FROM
		|	Document.InventoryConsumptionPlan AS Plan
		|WHERE
		|	Plan.Ref IN(&DocumentsForProcessing_)
		|
		|UNION ALL
		|
		|SELECT
		|	Plan.Ref,
		|	Plan.Date,
		|	Plan.BudgetingScenario,
		|	VALUE(Enum.DataSourceTypesForBudgeting.PurchasePlans)
		|FROM
		|	Document.PurchasePlan AS Plan
		|WHERE
		|	Plan.Ref IN(&DocumentsForProcessing_)
		|
		|UNION ALL
		|
		|SELECT
		|	Plan.Ref,
		|	Plan.Date,
		|	Plan.BudgetingScenario,
		|	VALUE(Enum.DataSourceTypesForBudgeting.CashFlowPlansVendors)
		|FROM
		|	Document.PurchasePlan AS Plan
		|WHERE
		|	Plan.Ref IN(&DocumentsForProcessing_)
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.PurchasePlan.CashFlowPlan AS CashFlowPlan
		|			WHERE
		|				Plan.Ref = CashFlowPlan.Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Plan.Ref,
		|	Plan.Date,
		|	Plan.BudgetingScenario,
		|	VALUE(Enum.DataSourceTypesForBudgeting.PlansOfGoodsStock)
		|FROM
		|	Document.PlanOfGoodsStock AS Plan
		|WHERE
		|	Plan.Ref IN(&DocumentsForProcessing_)
		|
		|UNION ALL
		|
		|SELECT
		|	Plan.Ref,
		|	Plan.Date,
		|	Plan.BudgetingScenario,
		|	VALUE(Enum.DataSourceTypesForBudgeting.SalesPlans)
		|FROM
		|	Document.SalesPlan AS Plan
		|WHERE
		|	Plan.Ref IN(&DocumentsForProcessing_)
		|
		|UNION ALL
		|
		|SELECT
		|	Plan.Ref,
		|	Plan.Date,
		|	Plan.BudgetingScenario,
		|	VALUE(Enum.DataSourceTypesForBudgeting.CashFlowPlansCustomers)
		|FROM
		|	Document.SalesPlan AS Plan
		|WHERE
		|	Plan.Ref IN(&DocumentsForProcessing_)
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.SalesPlan.CashFlowPlan AS CashFlowPlan
		|			WHERE
		|				Plan.Ref = CashFlowPlan.Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Plan.Ref,
		|	Plan.Date,
		|	Plan.BudgetingScenario,
		|	VALUE(Enum.DataSourceTypesForBudgeting.SalesPlansByCategories)
		|FROM
		|	Document.SalesPlanByCategories AS Plan
		|WHERE
		|	Plan.Ref IN(&DocumentsForProcessing_)
		|
		|UNION ALL
		|
		|SELECT
		|	Plan.Ref,
		|	Plan.Date,
		|	Plan.BudgetingScenario,
		|	VALUE(Enum.DataSourceTypesForBudgeting.ProductionPlans)
		|FROM
		|	Document.ProductionPlan AS Plan
		|WHERE
		|	Plan.Ref IN(&DocumentsForProcessing_)
		|	AND NOT Plan.Scenario.UseForMaterialsPlanning
		|
		|UNION ALL
		|
		|SELECT
		|	Plan.Ref,
		|	Plan.Date,
		|	Plan.ProductionPlan.BudgetingScenario,
		|	VALUE(Enum.DataSourceTypesForBudgeting.ProductionPlans)
		|FROM
		|	Document.RegisterProductionPlan AS Plan
		|WHERE
		|	Plan.Ref IN(&DocumentsForProcessing_)
		|
		|UNION ALL
		|
		|SELECT
		|	Plan.Ref,
		|	Plan.Date,
		|	Plan.BudgetingScenario,
		|	VALUE(Enum.DataSourceTypesForBudgeting.AssemblyDisassemblyPlans)
		|FROM
		|	Document.AssemblyDisassemblyPlan AS Plan
		|WHERE
		|	Plan.Ref IN(&DocumentsForProcessing_)");
	
	QueriesTexts.Add(
		"SELECT
		|	RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Ref AS CalculationRule,
		|	RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Receiver AS BudgetFlowItem
		|INTO CalculationsRules
		|FROM
		|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS RuleForCalculatingRelatedBudgetBalancesAndTurnovers
		|WHERE
		|	RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Status = VALUE(Enum.BudgetingRuleStatuses.Valid)
		|	AND RuleForCalculatingRelatedBudgetBalancesAndTurnovers.RecordCalculationInPlanningDocuments
		|	AND RuleForCalculatingRelatedBudgetBalancesAndTurnovers.SourceType IN
		|			(SELECT
		|				DocumentsToBeProcessedBySourceType.SourceType
		|			FROM
		|				DocumentsToBeProcessedBySourceType AS DocumentsToBeProcessedBySourceType)
		|	AND NOT RuleForCalculatingRelatedBudgetBalancesAndTurnovers.DeletionMark
		|
		|INDEX BY
		|	BudgetFlowItem");
	
	QueryText =
		"SELECT
		|	LimitRules.Ref AS LimitsRule,
		|	LimitRules.BudgetFlowOrBalanceItem AS BudgetFlowItem,
		|	LimitRules.Scenario AS Scenario,
		|	LimitRules.Periodicity AS Periodicity,
		|	CompanyLimitRules.DimensionName AS Organization,
		|	DivisionLimitRules.DimensionName AS Department,
		|	&FieldTextTypesOfRuleAnalytics
		|INTO LimitRules
		|FROM
		|	Catalog.BudgetingLimits AS LimitRules
		|		LEFT JOIN Catalog.BudgetingLimits.DimensionsHierarchy AS CompanyLimitRules
		|		ON LimitRules.Ref = CompanyLimitRules.Ref
		|			AND (CompanyLimitRules.Used)
		|			AND CompanyLimitRules.DimensionName = ""Organization""
		|		LEFT JOIN Catalog.BudgetingLimits.DimensionsHierarchy AS DivisionLimitRules
		|		ON LimitRules.Ref = DivisionLimitRules.Ref
		|			AND (DivisionLimitRules.Used)
		|			AND DivisionLimitRules.DimensionName = ""Department""
		|		AND &TextOfRuleAnalystTypesConnection
		|WHERE
		|	&LimitsRegisterIsUsed
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				CalculationsRules AS CalculationsRules
		|			WHERE
		|				LimitRules.BudgetFlowOrBalanceItem = CalculationsRules.BudgetFlowItem)
		|	AND NOT LimitRules.DeletionMark
		|	AND LimitRules.Owner.Status = VALUE(Enum.BudgetingModelStatuses.Valid)
		|
		|INDEX BY
		|	BudgetFlowItem,
		|	Scenario";
	
	TextOfFieldsOfTypesOfRuleAnalytics = "";
	TextOfRuleAnalystTypesConnection = "";
	TemplateForDescriptionOfRuleAnalyticsTypeField = "ISNULL(LimitRulesTypesOfAnalytics%1.DimensionKind, UNDEFINED) AS DimensionKind%1";
	TemplateForConnectingTypesOfRuleAnalytics =
	"		LEFT JOIN Catalog.BudgetingLimits.DimensionsHierarchy AS LimitRulesTypesOfAnalytics%1
	|		ON LimitRules.Ref = LimitRulesTypesOfAnalytics%1.Ref
	|			AND (LimitRulesTypesOfAnalytics%1.Used)
	|			AND (LimitRulesTypesOfAnalytics%1.DimensionKind = LimitRules.BudgetFlowOrBalanceItem.DimensionKind%1)
	|			AND (LimitRulesTypesOfAnalytics%1.DimensionKind <> VALUE(ChartOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef))";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfFieldsOfTypesOfRuleAnalytics = TextOfFieldsOfTypesOfRuleAnalytics + ?(TextOfFieldsOfTypesOfRuleAnalytics = "", "", ",
			|	")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				TemplateForDescriptionOfRuleAnalyticsTypeField,
				DimensionNumber);
		
		TextOfRuleAnalystTypesConnection = TextOfRuleAnalystTypesConnection + ?(TextOfRuleAnalystTypesConnection = "", "", "
			|	")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				TemplateForConnectingTypesOfRuleAnalytics,
				DimensionNumber);
	EndDo;
	
	QueryText = StrReplace(QueryText, "&FieldTextTypesOfRuleAnalytics", TextOfFieldsOfTypesOfRuleAnalytics);
	QueryText = StrReplace(QueryText, "AND &TextOfRuleAnalystTypesConnection", TextOfRuleAnalystTypesConnection);
	QueriesTexts.Add(QueryText);
	
	If Not FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts,
		"CalculationsRules") Then
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 0);
		Return;
	EndIf;
	
	DocumentsData = TempTablesManager.Tables.Find("DocumentsToBeProcessedBySourceType").GetData().Unload();
	DocumentsData.Indexes.Add("SourceType");
	DocumentsData.Indexes.Add("Recorder");
	SourcesTypes = DocumentsData.Copy(, "SourceType");
	SourcesTypes.GroupBy("SourceType");
	CalculationsRules = TempTablesManager.Tables.Find("CalculationsRules").GetData().Unload();
	
	RequestAccordingToCalculationRules = GenerateRequestToDataSourceAccordingToCalculationRules(CalculationsRules.UnloadColumn("CalculationRule"), "Plan");
	For Each StringSourceType In SourcesTypes Do
		FilterStructure1 = New Structure("SourceType", StringSourceType.SourceType);
		RequestAccordingToCalculationRules.QueryOptions.Insert(StringFunctionsClientServer.SubstituteParametersToString(
			"Recorders_%1", Common.EnumerationValueName(StringSourceType.SourceType)),
			DocumentsData.Copy(FilterStructure1).UnloadColumn("Recorder"));
	EndDo;
	
	If Not IsBlankString(RequestAccordingToCalculationRules.QueryTextTT) Then
		While True Do
			PositionBeginningOfCondition = StrFind(RequestAccordingToCalculationRules.QueryTextTT, "&SourceTableConditionsAndAlignmentFields");
			If PositionBeginningOfCondition = 0 Then
				Break;
			EndIf;
			PositionEndOfCondition = StrFind(RequestAccordingToCalculationRules.QueryTextTT, ")", , PositionBeginningOfCondition);
			ConditionLength = PositionEndOfCondition - PositionBeginningOfCondition;
			RequestAccordingToCalculationRules.QueryTextTT = StrReplace(RequestAccordingToCalculationRules.QueryTextTT, Mid(
				RequestAccordingToCalculationRules.QueryTextTT, PositionBeginningOfCondition, ConditionLength), "TRUE")
		EndDo;
		QueriesTexts.Add(RequestAccordingToCalculationRules.QueryTextTT);
	EndIf;
	While True Do
		PositionBeginningOfCondition = StrFind(RequestAccordingToCalculationRules.QueryText, "&SourceTableConditionsAndAlignmentFields");
		If PositionBeginningOfCondition = 0 Then
			Break;
		EndIf;
		PositionEndOfCondition = StrFind(RequestAccordingToCalculationRules.QueryText, ")", , PositionBeginningOfCondition);
		ConditionLength = PositionEndOfCondition - PositionBeginningOfCondition;
		RequestAccordingToCalculationRules.QueryText = StrReplace(RequestAccordingToCalculationRules.QueryText,
			Mid(RequestAccordingToCalculationRules.QueryText, PositionBeginningOfCondition, ConditionLength), "TRUE")
	EndDo;
	QueriesTexts.Add(RequestAccordingToCalculationRules.QueryText);
	
	QueryText =
		"SELECT
		|	Data.DayPeriod AS Period,
		|	Data.BudgetFlowItem AS BudgetFlowItem,
		|	Data.PlanningPeriod AS PlanningPeriod,
		|	Data.Recorder AS Recorder,
		|	Data.Scenario AS Scenario,
		|	Data.Status AS Status,
		|	Data.Organization AS Organization,
		|	Data.Department AS Department,
		|	Data.Currency AS Currency,
		|	&TextOfDimensionsFields,
		|	Data.CountTurnover AS Count,
		|	Data.SumManTurnover AS SumMan,
		|	Data.ScenarioAmountTurnover AS ScenarioAmount,
		|	Data.SumComplTurnover AS SumCompl,
		|	Data.AmountInCurrencyTurnover AS AmountInCurrency,
		|	Data.CalculationRule AS CalculationRule
		|FROM
		|	Data AS Data
		|WHERE
		|	Data.ScenarioAmountTurnover <> 0";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	ArrayOfAnalystFields = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"Data.Dimension%1 AS Dimension%1",
			DimensionNumber));
	EndDo;
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", StrConcat(ArrayOfAnalystFields, "," + Chars.LF
		+ Chars.Tab));
	QueriesTexts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	Data.DayPeriod AS Period,
		|	CASE LimitRules.Periodicity
		|		WHEN VALUE(Enum.Periodicity.WEEK)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, WEEK)
		|		WHEN VALUE(Enum.Periodicity.TENDAYS)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, TENDAYS)
		|		WHEN VALUE(Enum.Periodicity.MONTH)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, MONTH)
		|		WHEN VALUE(Enum.Periodicity.QUARTER)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, QUARTER)
		|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, HALFYEAR)
		|		WHEN VALUE(Enum.Periodicity.YEAR)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, YEAR)
		|		ELSE Data.PlanningPeriod
		|	END AS LimitationPeriod,
		|	Data.Recorder AS Recorder,
		|	LimitRules.LimitsRule AS LimitsRule,
		|	CASE
		|		WHEN LimitRules.Organization IS NULL
		|			THEN VALUE(Catalog.Companies.EmptyRef)
		|		ELSE Data.Organization
		|	END AS Organization,
		|	CASE
		|		WHEN LimitRules.Department IS NULL
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		ELSE Data.Department
		|	END AS Department,
		|	Data.Currency AS Currency,
		|	&TextOfDimensionsFields,
		|	Data.AmountInCurrencyTurnover AS Limit
		|FROM
		|	Data AS Data
		|		INNER JOIN LimitRules AS LimitRules
		|		ON Data.BudgetFlowItem = LimitRules.BudgetFlowItem
		|WHERE
		|	Data.Status = VALUE(Enum.PlanStatuses.Upholded)
		|	AND LimitRules.Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef)
		|	AND Data.AmountInCurrencyTurnover <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	Data.DayPeriod,
		|	CASE LimitRules.Periodicity
		|		WHEN VALUE(Enum.Periodicity.WEEK)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, WEEK)
		|		WHEN VALUE(Enum.Periodicity.TENDAYS)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, TENDAYS)
		|		WHEN VALUE(Enum.Periodicity.MONTH)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, MONTH)
		|		WHEN VALUE(Enum.Periodicity.QUARTER)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, QUARTER)
		|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, HALFYEAR)
		|		WHEN VALUE(Enum.Periodicity.YEAR)
		|			THEN BEGINOFPERIOD(Data.PlanningPeriod, YEAR)
		|		ELSE Data.PlanningPeriod
		|	END,
		|	Data.Recorder,
		|	LimitRules.LimitsRule,
		|	CASE
		|		WHEN LimitRules.Organization IS NULL
		|			THEN VALUE(Catalog.Companies.EmptyRef)
		|		ELSE Data.Organization
		|	END,
		|	CASE
		|		WHEN LimitRules.Department IS NULL
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		ELSE Data.Department
		|	END,
		|	Data.Currency,
		|	&TextOfDimensionsFields,
		|	Data.AmountInCurrencyTurnover
		|FROM
		|	Data AS Data
		|		INNER JOIN LimitRules AS LimitRules
		|		ON Data.BudgetFlowItem = LimitRules.BudgetFlowItem
		|			AND Data.Scenario = LimitRules.Scenario
		|WHERE
		|	Data.Status = VALUE(Enum.PlanStatuses.Upholded)
		|	AND Data.AmountInCurrencyTurnover <> 0";
		
	ArrayOfAnalystFields = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"CASE
			|	WHEN LimitRules.DimensionKind%1 = UNDEFINED
			|		THEN UNDEFINED
			|	ELSE Data.Dimension%1
			|END AS Dimension%1",
			DimensionNumber));
	EndDo;
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", StrConcat(ArrayOfAnalystFields, "," + Chars.LF
		+ Chars.Tab));
	QueriesTexts.Add(QueryText);
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Query.SetParameter("Recorders", DocumentsForProcessing_);
	Query.SetParameter("DateEmpty", '00010101');
	CommonClientServer.SupplementStructure(Query.Parameters, RequestAccordingToCalculationRules.QueryOptions);
	Result = Query.ExecuteBatch();
	BudgetTurnoverTable = Result[Result.Count()-2].Unload();
	BudgetTurnoverTable.Indexes.Add("Recorder");
	TableLimitsBasedOnBudgetingData = Result[Result.Count()-1].Unload();
	TableLimitsBasedOnBudgetingData.Indexes.Add("Recorder");
	
	Jobs.Sort("RecordDate");
	
	DocumentSearchStructure = New Structure("Document");
	
	ProcessedDocuments = New Array;
	IdOfUnprocessedRecord = Undefined;
	
	NumberOfRecordsProcessed = 0;
	
	For Each RowJob In Jobs Do
		
		If ProcessedDocuments.Find(RowJob.Document) <> Undefined Then
			NumberOfRecordsProcessed = NumberOfRecordsProcessed + 1;
			Continue;
		EndIf;
		
		CurrentDocument = RowJob.Document;
		If TypeOf(CurrentDocument) = Type("DocumentRef.RegisterProductionPlan") Then
			CurrentDocument = Common.ObjectAttributeValue(CurrentDocument, "ProductionPlan");
		EndIf;
		IdOfUnprocessedRecord = RowJob.RecordID;
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.JobsForPostingPlanningDocumentsInBudgeting");
			LockItem.SetValue("RecordID", IdOfUnprocessedRecord);
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem = Block.Add("AccumulationRegister.BudgetTurnovers.RecordSet");
			LockItem.SetValue("Recorder", CurrentDocument);
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem = Block.Add("AccumulationRegister.LimitsByBudgetingData.RecordSet");
			LockItem.SetValue("Recorder", CurrentDocument);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			RecordSet = AccumulationRegisters.BudgetTurnovers.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(CurrentDocument);
			
			FilterStructure1 = New Structure("Recorder", RowJob.Document);
			SetToRecordTable = BudgetTurnoverTable.Copy(FilterStructure1);
			RecordSet.Load(SetToRecordTable);
			RecordSet.Write();
			
			NumberOfRecordsProcessed = NumberOfRecordsProcessed + RecordSet.Count();
			
			RecordSet = AccumulationRegisters.LimitsByBudgetingData.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(CurrentDocument);
			
			FilterStructure1 = New Structure("Recorder", RowJob.Document);
			SetToRecordTable = TableLimitsBasedOnBudgetingData.Copy(FilterStructure1);
			RecordSet.Load(SetToRecordTable);
			RecordSet.Write();
			
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
Procedure GenerateRelatedBudgetTurnover(Jobs, IdsOfUnprocessedRecords,
	AdditionalProperties = Undefined) Export
	
	DocumentsForProcessing_ = Jobs.UnloadColumn("Object");
	If DocumentsForProcessing_.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("DocumentsForProcessing_", DocumentsForProcessing_);
	Query.Text = 
	"SELECT
	|	BudgetEntryForm.Ref AS Object,
	|	BudgetEntryForm.Date AS Date,
	|	BudgetEntryForm.Organization AS Organization,
	|	BudgetEntryForm.Department AS Department,
	|	BudgetEntryForm.Scenario AS Scenario,
	|	BudgetEntryForm.Status AS Status,
	|	BudgetEntryForm.BeginOfPeriod AS BeginOfPeriod,
	|	BudgetEntryForm.PeriodEnding AS PeriodEnding,
	|	BudgetEntryForm.BudgetProfile.Periodicity AS Periodicity
	|INTO InstancesOfBudgets
	|FROM
	|	Document.BudgetEntryForm AS BudgetEntryForm
	|WHERE
	|	BudgetEntryForm.Ref IN(&DocumentsForProcessing_)
	|
	|INDEX BY
	|	Object
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BudgetTurnovers.Recorder AS Object,
	|	CalculationsRules.Ref AS CalculationRule
	|INTO CalculationsRules
	|FROM
	|	AccumulationRegister.BudgetTurnovers AS BudgetTurnovers
	|		INNER JOIN Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|		ON BudgetTurnovers.BudgetFlowItem = CalculationsRules.Source
	|WHERE
	|	BudgetTurnovers.Recorder IN(&DocumentsForProcessing_)
	|	AND CalculationsRules.Status = VALUE(Enum.BudgetingRuleStatuses.Valid)
	|	AND NOT CalculationsRules.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.BudgetBalanceItems AS BudgetBalanceItems
	|				WHERE
	|					BudgetBalanceItems.Ref = CalculationsRules.Receiver
	|					AND BudgetBalanceItems.IndicatorType = VALUE(Enum.BudgetBalanceItemType.Estimated_))
	|
	|INDEX BY
	|	Object
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InstancesOfBudgets.Object AS Object,
	|	InstancesOfBudgets.Date AS Date,
	|	InstancesOfBudgets.Organization AS Organization,
	|	InstancesOfBudgets.Department AS Department,
	|	InstancesOfBudgets.Scenario AS Scenario,
	|	InstancesOfBudgets.Status AS Status,
	|	InstancesOfBudgets.BeginOfPeriod AS BeginOfPeriod,
	|	InstancesOfBudgets.PeriodEnding AS PeriodEnding,
	|	InstancesOfBudgets.Periodicity AS Periodicity,
	|	CalculationsRules.CalculationRule AS CalculationRule
	|FROM
	|	InstancesOfBudgets AS InstancesOfBudgets
	|		LEFT JOIN CalculationsRules AS CalculationsRules
	|		ON InstancesOfBudgets.Object = CalculationsRules.Object
	|TOTALS
	|	MAX(Date),
	|	MAX(Organization),
	|	MAX(Department),
	|	MAX(Scenario),
	|	MAX(Status),
	|	MAX(BeginOfPeriod),
	|	MAX(PeriodEnding),
	|	MAX(Periodicity)
	|BY
	|	Object
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegistrarOfBudgetTurnover.Ref AS DocumentRecorder,
	|	RegistrarOfBudgetTurnover.DocumentBasis AS Object,
	|	RegistrarOfBudgetTurnover.PlanningPeriod AS PlanningPeriod,
	|	RegistrarOfBudgetTurnover.CalculationRule AS CalculationRule,
	|	FALSE AS Check
	|FROM
	|	Document.RegistrarOfBudgetTurnover AS RegistrarOfBudgetTurnover
	|WHERE
	|	RegistrarOfBudgetTurnover.DocumentBasis IN(&DocumentsForProcessing_)
	|	AND NOT RegistrarOfBudgetTurnover.DeletionMark";
	
	Results = Query.ExecuteBatch();
	
	DocumentData__ = Results[2].Unload(QueryResultIteration.ByGroups);
	GeneratedDocuments = Results[3].Unload();
	
	Jobs.Sort("RecordDate");
	
	DocumentSearchStructure = New Structure("Object");
	
	ProcessedDocuments = New Array;
	IdOfUnprocessedRecord = Undefined;
	
	For Each RowJob In Jobs Do
		
		If ProcessedDocuments.Find(RowJob.Object) <> Undefined Then
			Continue;
		EndIf;
		
		CurrentDocument = RowJob.Object;
		IdOfUnprocessedRecord = RowJob.RecordID;
		DocumentSearchStructure.Object = CurrentDocument;
		
		LineDocument = DocumentData__.Rows.FindRows(DocumentSearchStructure);
		If LineDocument.Count() = 0 Then
			Continue;
		EndIf;
		
		BudgetPeriods = BudgetReportingDisplayServer.BudgetReportPeriods(LineDocument[0].BeginOfPeriod,
			LineDocument[0].PeriodEnding, LineDocument[0].Periodicity);
		
		RecorderDocuments = GeneratedDocuments.Copy(DocumentSearchStructure);
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("AccumulationRegister.BudgetTurnovers.RecordSet");
			LockItem.SetValue("Recorder", CurrentDocument);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			For Each StringRule In LineDocument[0].Rows Do
			
				If Not ValueIsFilled(StringRule.CalculationRule) Then
					Continue;
				EndIf;
				
				StructureOfRegistrarSearch = New Structure("CalculationRule, PlanningPeriod");
				StructureOfRegistrarSearch.CalculationRule = StringRule.CalculationRule;
				
				For Each BudgetPeriod In BudgetPeriods Do
					
					StructureOfRegistrarSearch.PlanningPeriod = BudgetPeriod;
					
					LineLogger = RecorderDocuments.FindRows(StructureOfRegistrarSearch);
					If LineLogger.Count() > 0 Then
						DocumentObject = LineLogger[0].DocumentRecorder.GetObject();
						LineLogger[0].Check = True;
					Else
						DocumentObject = Documents.RegistrarOfBudgetTurnover.CreateDocument();
						DocumentObject.DocumentBasis = CurrentDocument;
						DocumentObject.PlanningPeriod = BudgetPeriod;
					EndIf;
					FillPropertyValues(DocumentObject, StringRule);
					
					DocumentObject.Write(DocumentWriteMode.Posting);
					
				EndDo;
			
			EndDo;
			
			For Each LineLogger In RecorderDocuments Do
				If Not LineLogger.Check Then
					DocumentObject = LineLogger.DocumentRecorder.GetObject();
					DocumentObject.SetDeletionMark(True);
				EndIf;
			EndDo;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			If IdOfUnprocessedRecord <> Undefined Then
				ErrorText = DeferredJobs.ExecutionErrorText(DocumentSearchStructure, RowJob, ErrorText);
			EndIf;
			IdsOfUnprocessedRecords.Insert(IdOfUnprocessedRecord, ErrorText);
			
		EndTry;
	
	EndDo;
	
EndProcedure
#EndRegion

#Region InfobaseUpdate

// Checks whether the update handlers that block the budget report generation were executed.
// 
// Returns:
//  Boolean - True if the data is still being updated.
//
Function DataForBudgetReportIsStillUpdated() Export
	Return Not InfobaseUpdate.ObjectProcessed("Report.BudgetReport").Processed;
EndFunction

// Function for checking objects when opening forms and before writing.
// It can be used as a default verification function if
// there is enough logic-blocked objects are registered on the nodes of the information database Update exchange plan.
//
// Parameters:
//  MetadataAndFilter - See InfobaseUpdate.MetadataAndFilterByData.
//
// Returns:
//  Boolean - True if the object is updated and available for modification.
//
Function DataUpdatedForNewApplicationVersion(MetadataAndFilter) Export
	
	Data = MetadataAndFilter.Data;
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		If Not Common.IsSubordinateDIBNode() Then
			Return True;
		ElsIf GetFunctionalOption("DeferredMasterNodeUpdateCompleted") Then
			Return True;
		EndIf;
	EndIf;
	
	If MetadataAndFilter = Undefined Then
		MetadataAndFilter = InfobaseUpdate.MetadataAndFilterByData(Data, Undefined);
	EndIf;
	
	If MetadataAndFilter.IsNew Then
		
		CurObjectDataUpdated = True;
		
	Else
		
		CurObjectDataUpdated = Not InfobaseUpdate.HasDataToProcess(Undefined, MetadataAndFilter.Metadata, MetadataAndFilter.Filter);
		
	EndIf;
	
	If Not CurObjectDataUpdated Then
		Return CurObjectDataUpdated;
	EndIf;
	
	RelatedObjects = New Array;
	
	RelatedObjectDataUpdated = True;
	
	If MetadataAndFilter.Metadata = Metadata.Documents.SetValuesForNonFinancialItems Then
		
		RelatedObjects.Add(Metadata.Catalogs.NonFinancialItemsOfBudgets);
		RelatedObjects.Add(Metadata.Catalogs.NonFinancialItemProfiles);
	
	ElsIf MetadataAndFilter.Metadata = Metadata.Documents.SettingOfEstimatesOpeningBalance Then
		
		RelatedObjects.Add(Metadata.Catalogs.BudgetBalanceItems);
		RelatedObjects.Add(Metadata.InformationRegisters.OpeningBalanceOfEstimates);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Documents.BudgetEntryForm Then
		
		RelatedObjects.Add(Metadata.Catalogs.NonFinancialItemsOfBudgets);
		RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetBalanceItems);
		RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetFlowItems);
		RelatedObjects.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers);
		RelatedObjects.Add(Metadata.Catalogs.FinancialReportItems);
		RelatedObjects.Add(Metadata.InformationRegisters.NonFinancialItemValues);
		RelatedObjects.Add(Metadata.AccumulationRegisters.LimitsByBudgetingData);
		RelatedObjects.Add(Metadata.InformationRegisters.OpeningBalanceOfEstimates);
		RelatedObjects.Add(Metadata.AccumulationRegisters.BudgetTurnovers);
		RelatedObjects.Add(Metadata.InformationRegisters.CacheOfAuxiliaryBudgetProfileData);
		RelatedObjects.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule);
		RelatedObjects.Add(Metadata.AccumulationRegisters.ActualBudgetingData);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Catalogs.BudgetProfiles Then
		
		RelatedObjects.Add(Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions);
		RelatedObjects.Add(Metadata.Catalogs.FinancialReportItems);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Catalogs.FinancialReportItems Then
		
		RelatedObjects.Add(Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Reports.BudgetReport Then
		
		RelatedObjects.Add(Metadata.Catalogs.NonFinancialItemsOfBudgets);
		RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetBalanceItems);
		RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetFlowItems);
		RelatedObjects.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers);
		RelatedObjects.Add(Metadata.Catalogs.FinancialReportItems);
		RelatedObjects.Add(Metadata.InformationRegisters.NonFinancialItemValues);
		RelatedObjects.Add(Metadata.InformationRegisters.OpeningBalanceOfEstimates);
		RelatedObjects.Add(Metadata.AccumulationRegisters.BudgetTurnovers);
		RelatedObjects.Add(Metadata.InformationRegisters.CacheOfAuxiliaryBudgetProfileData);
		RelatedObjects.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule);
		RelatedObjects.Add(Metadata.AccumulationRegisters.ActualBudgetingData);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Reports.BudgetingTurnoverBalanceReport Then
		
		RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetFlowItems);
		RelatedObjects.Add(Metadata.AccumulationRegisters.BudgetTurnovers);
		RelatedObjects.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule);
		RelatedObjects.Add(Metadata.AccumulationRegisters.ActualBudgetingData);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Reports.TrialBalanceForBudgetBalanceItems Then
		
		RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetBalanceItems);
		RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetFlowItems);
		RelatedObjects.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers);
		RelatedObjects.Add(Metadata.AccumulationRegisters.BudgetTurnovers);
		RelatedObjects.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule);
		RelatedObjects.Add(Metadata.InformationRegisters.OpeningBalanceOfEstimates);
		RelatedObjects.Add(Metadata.AccumulationRegisters.ActualBudgetingData);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Reports.CheckRelatedBudgetBalancesAndTurnovers Then
		
		RelatedObjects.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Reports.CheckBudgetItemLinks Then
		
		RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetBalanceItems);
		RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetFlowItems);
		RelatedObjects.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers);
		RelatedObjects.Add(Metadata.AccumulationRegisters.BudgetTurnovers);
		RelatedObjects.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule);
		RelatedObjects.Add(Metadata.AccumulationRegisters.ActualBudgetingData);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Reports.ResultOfActualDataQuery Then
		
		RelatedObjects.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Reports.BudgetReportFormulaDrillDown Then
		
		RelatedObjects.Add(Metadata.Catalogs.FinancialReportItems);
		RelatedObjects.Add(Metadata.InformationRegisters.CacheOfAuxiliaryBudgetProfileData);
		RelatedObjects.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Reports.CashFlowLimitsForBudgetingData
		Or MetadataAndFilter.Metadata = Metadata.Reports.LimitsByBudgetingData Then
		
		RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetFlowItems);
		RelatedObjects.Add(Metadata.Catalogs.BudgetingLimits);
		RelatedObjects.Add(Metadata.AccumulationRegisters.BudgetTurnovers);
		RelatedObjects.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule);
		RelatedObjects.Add(Metadata.AccumulationRegisters.ActualBudgetingData);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Documents.PurchaseRequest Then
		If Constants.UseIEBLimitsOnPurchases.Get() Then
			RelatedObjects.Add(Metadata.Catalogs.BudgetingLimits);
			RelatedObjects.Add(Metadata.AccumulationRegisters.LimitsByBudgetingData);
		EndIf;
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Documents.ApplicationForBusinessTrip Then
		If Constants.UseBudgetingCashFlowLimits.Get()
			Or Constants.UseIEBLimitsOnConsumption.Get()
			Or Constants.UseIEBLimitsOnPurchases.Get() Then
			RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetFlowItems);
			RelatedObjects.Add(Metadata.Catalogs.BudgetingLimits);
			If Not Constants.ControllingLimitsBasedOnBudgetingData2_4.Get() Then
				RelatedObjects.Add(Metadata.AccumulationRegisters.LimitsByBudgetingData);
			Else
				RelatedObjects.Add(Metadata.AccumulationRegisters.BudgetTurnovers);
			EndIf;
			RelatedObjects.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule);
		EndIf;
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Documents.ApplicationForCollateral Then
		If Constants.UseIEBLimitsOnConsumption.Get()
			Or Constants.UseIEBLimitsOnPurchases.Get() Then
			RelatedObjects.Add(Metadata.Catalogs.BudgetingLimits);
			RelatedObjects.Add(Metadata.AccumulationRegisters.LimitsByBudgetingData);
		EndIf;
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Documents.PaymentRequest Then
		If Constants.UseBudgetingCashFlowLimits.Get() Then
			RelatedObjects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetFlowItems);
			RelatedObjects.Add(Metadata.Catalogs.BudgetingLimits);
			If Not Constants.ControllingLimitsBasedOnBudgetingData2_4.Get() Then
				RelatedObjects.Add(Metadata.AccumulationRegisters.LimitsByBudgetingData);
			Else
				RelatedObjects.Add(Metadata.AccumulationRegisters.BudgetTurnovers);
			EndIf;
			RelatedObjects.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule);
		EndIf;
	ElsIf MetadataAndFilter.Metadata = Metadata.Catalogs.FinancialReportTypes Then
		
		RelatedObjects.Add(Metadata.Catalogs.FinancialReportItems);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Documents.FinancialStatementCopy Then
		
		RelatedObjects.Add(Metadata.Catalogs.FinancialReportItems);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Reports.FinancialReport Then 
		
		RelatedObjects.Add(Metadata.Catalogs.FinancialReportItems);
	EndIf;
	
	For Each AssociatedObjectMetadata In RelatedObjects Do
	
		If InfobaseUpdate.HasDataToProcess(Undefined, AssociatedObjectMetadata) Then
			RelatedObjectDataUpdated = False;
			Break;
		EndIf;
	EndDo;
	
	Return CurObjectDataUpdated And RelatedObjectDataUpdated;
	
EndFunction

#EndRegion
