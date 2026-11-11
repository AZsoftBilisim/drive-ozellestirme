
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//  		registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Budgeting");
	DocumentMechanisms.Add("ControlOfBudgetingLimits");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.RegistrarOfBudgetTurnover") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableBudgetTurnovers(Query, QueryTexts, Registers);
		QueryTextTableLimitsByBudgetingData(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Generates a verification request when changing the status of the list of documents.
//
// Parameters:
//	DocumentsArray - Array of DocumentRef.RegistrarOfBudgetTurnover - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.PlanStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.RegistrarOfBudgetTurnover AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes.
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string.
//	NewStatus - EnumRef.PlanStatuses - new status.
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the document
	
EndFunction

#EndRegion

#Region Private

#Region Posting

// Fills in the text and parameters of the initialization request.
// 
// Parameters:
// 	Query - Query - 
// 	DocumentRef - DocumentRef.RegistrarOfBudgetTurnover - 
Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	RegistrarOfBudgetTurnover.Ref AS Ref,
	|	RegistrarOfBudgetTurnover.Date AS Date,
	|	RegistrarOfBudgetTurnover.Status AS Status,
	|	RegistrarOfBudgetTurnover.Organization AS Organization,
	|	RegistrarOfBudgetTurnover.Department AS Department,
	|	RegistrarOfBudgetTurnover.Scenario AS Scenario,
	|	RegistrarOfBudgetTurnover.Scenario.Currency AS ScenarioCurrency,
	|	RegistrarOfBudgetTurnover.CalculationRule AS CalculationRule,
	|	RegistrarOfBudgetTurnover.CalculationRule.SourceType AS SourceType,
	|	CAST(RegistrarOfBudgetTurnover.CalculationRule.Receiver AS Catalog.BudgetFlowItems) AS BudgetFlowItem,
	|	CAST(RegistrarOfBudgetTurnover.CalculationRule.Receiver AS Catalog.BudgetFlowItems).LimitedTransaction AS LimitedTransaction,
	|	RegistrarOfBudgetTurnover.PlanningPeriod AS PlanningPeriod,
	|	RegistrarOfBudgetTurnover.Periodicity AS Periodicity,
	|	RegistrarOfBudgetTurnover.DocumentBasis AS DocumentBasis
	|FROM
	|	Document.RegistrarOfBudgetTurnover AS RegistrarOfBudgetTurnover
	|WHERE
	|	RegistrarOfBudgetTurnover.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Ref", Attributes.Ref);
	Query.SetParameter("UpdateDate", Attributes.Date);
	Query.SetParameter("Status", Attributes.Status);
	Query.SetParameter("Scenario", Attributes.Scenario);
	Query.SetParameter("BeginOfPeriod", Attributes.PlanningPeriod);
	Query.SetParameter("EndOfPeriod", WorkingWithClientServerPeriods.PeriodEndDate_(Attributes.PlanningPeriod,
		Attributes.Periodicity));
	Query.SetParameter("CalculationRule", Attributes.CalculationRule);
	Query.SetParameter("BudgetFlowItem", Attributes.BudgetFlowItem);
	Query.SetParameter("LimitedTransaction", Attributes.LimitedTransaction);
	Query.SetParameter("DocumentBasis", Attributes.DocumentBasis);
	
	Query.SetParameter("Organization", Attributes.Organization);
	Query.SetParameter("Department", Attributes.Department);
	
	Query.SetParameter("ScenarioCurrency", Attributes.ScenarioCurrency);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());

	If ValueIsFilled(Attributes.Organization) Then
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(
			Attributes.Organization);
	Else
		LocalAccountingCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	Query.SetParameter("LocalAccountingCurrency", LocalAccountingCurrency);
	Query.SetParameter("FillInLocalAmount", ValueIsFilled(LocalAccountingCurrency));
	Query.SetParameter("LimitsRegisterIsUsed", LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed());
	
	Query.SetParameter("SourceType", Attributes.SourceType);
	
	If Attributes.SourceType <> Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
		Query.Text = 
		"SELECT
		|	SalesOperationsPlanningScenarios.Ref AS Ref
		|FROM
		|	Catalog.SalesOperationsPlanningScenarios AS SalesOperationsPlanningScenarios
		|WHERE
		|	SalesOperationsPlanningScenarios.BudgetingScenario = &Scenario
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataCalculationSettings.NFIFactor AS NFP
		|FROM
		|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.DataCalculationSettings AS DataCalculationSettings
		|WHERE
		|	DataCalculationSettings.Ref = &CalculationRule
		|
		|UNION ALL
		|
		|SELECT
		|	DataCalculationSettings.AllocationProfile
		|FROM
		|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.DataCalculationSettings AS DataCalculationSettings
		|WHERE
		|	DataCalculationSettings.Ref = &CalculationRule
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&TextTypeOfAnalyticsValueType
		|FROM
		|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
		|WHERE
		|	NonFinancialItemsOfBudgets.Ref IN
		|			(SELECT
		|				NFPCalculationRules.NFP
		|			FROM
		|				NFPCalculationRules)";
		
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		ArrayOfTextsOfTypesOfAnalytics = New Array;
		TextTemplateTypeOfAnalyticsValueType =
			"NonFinancialItemsOfBudgets.DimensionKind%1.ValueType AS DimensionKind%1ValueType";
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			ArrayOfTextsOfTypesOfAnalytics.Add(StringFunctionsClientServer.SubstituteParametersToString(
				TextTemplateTypeOfAnalyticsValueType, DimensionNumber));
		EndDo;
		Query.Text = StrReplace(Query.Text, "&TextTypeOfAnalyticsValueType", StrConcat(
			ArrayOfTextsOfTypesOfAnalytics, "," + Chars.LF + Chars.Tab));
		Results = Query.ExecuteBatch();
		
		PlanningScenarios = Results[0].Unload().UnloadColumn("Ref");
		Query.SetParameter("PlanningScenarios", PlanningScenarios);
		
		TableOfTypesOfTypesOfNFPAnalysts = Results[2].Unload();
		TypesOfTypesOfNFPAnalysts = New Array;
		For Each TableRow In TableOfTypesOfTypesOfNFPAnalysts Do
			For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
				FieldName = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1ValueType",
					DimensionNumber);
				If ValueIsFilled(TableRow[FieldName]) And TypesOfTypesOfNFPAnalysts.Find(TableRow[FieldName])
					= Undefined Then
					CommonClientServer.SupplementArray(TypesOfTypesOfNFPAnalysts, TableRow[FieldName].Types(),
						True);
				EndIf;
			EndDo;
		EndDo;
		Query.SetParameter("TypesOfTypesOfNFPAnalysts", TypesOfTypesOfNFPAnalysts);
		
	EndIf;
	
EndProcedure

Function QueryTextTTTheseCalculationRules(Query, QueryTexts)

	RegisterName = "TTTheseCalculationRules"; 
	
	RequestBasedOnCalculationRule = BudgetingServer.GenerateRequestToDataSourceAccordingToCalculationRules(
		CommonClientServer.ValueInArray(Query.Parameters.CalculationRule), "Plan");
	For Each QueryParameter In RequestBasedOnCalculationRule.QueryOptions Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	
	QueryText = "";
	If Not IsBlankString(RequestBasedOnCalculationRule.QueryTextTT) Then
		QueryText = RequestBasedOnCalculationRule.QueryTextTT + Common.QueryBatchSeparator();
	EndIf;
	QueryText = QueryText + RequestBasedOnCalculationRule.QueryText;
	If ValueIsFilled(Query.Parameters.DocumentBasis) Then
		QueryText = StrReplace(QueryText, "UNDEFINED AS Recorder",
			"AliasOfSourceTable.Recorder");
	EndIf;
	If Query.Parameters.SourceType <> Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
		AvailableTypesOfAnalytics = BudgetingCached.AvailableTypesOfAnalyticsForPlanningSourceType(
			Query.Parameters.SourceType);
		DimensionNamesUsed = New Array;
		For Each TypeOfTypeOfNFPAnalytics In Query.Parameters.TypesOfTypesOfNFPAnalysts Do
			PathToDataTypeTypeOfAnalyticsNFP = AvailableTypesOfAnalytics.Get(TypeOfTypeOfNFPAnalytics);
			If PathToDataTypeTypeOfAnalyticsNFP = Undefined Then
				Continue;
			EndIf;
			FirstPointPosition = StrFind(PathToDataTypeTypeOfAnalyticsNFP, ".");
			PositionOfSecondPoint = StrFind(PathToDataTypeTypeOfAnalyticsNFP, ".", , , 2);
			If PositionOfSecondPoint = 0 Then
				DimensionName = Mid(PathToDataTypeTypeOfAnalyticsNFP, FirstPointPosition + 1);
			Else
				DimensionName = Mid(PathToDataTypeTypeOfAnalyticsNFP, FirstPointPosition + 1, PositionOfSecondPoint
					- FirstPointPosition - 1);
			EndIf;
			If DimensionNamesUsed.Find(DimensionName) = Undefined Then
				DimensionNamesUsed.Add(DimensionName);
			EndIf;
		EndDo;
		DimensionsOfSource = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
			BudgetingCached.ParametersOfRegisterOfSourceOfReceivingDataForBudgeting(
			Query.Parameters.SourceType).Dimensions);
		For Each DimensionFromSource In DimensionsOfSource Do
			If Query.Parameters.Property(DimensionFromSource) Then
				Continue;
			ElsIf DimensionNamesUsed.Find(DimensionFromSource) = Undefined Then
				QueryText = StrReplace(QueryText, StringFunctionsClientServer.SubstituteParametersToString(
					"AliasOfSourceTable.%1 AS %1", DimensionFromSource),
					StringFunctionsClientServer.SubstituteParametersToString("UNDEFINED AS %1", DimensionFromSource));
			EndIf;
		EndDo;
		QueryText = StrReplace(QueryText, "{&BeginOfPeriod}", "&BeginOfPeriod");
		QueryText = StrReplace(QueryText, "{ENDOFPERIOD(&EndOfPeriod, DAY)}",
			"ENDOFPERIOD(&EndOfPeriod, DAY)");
	Else
		QueryText = StrReplace(QueryText, "{&UpdateDate}", "&UpdateDate");
	EndIf;
	
	SourceType = RequestBasedOnCalculationRule.SourcesTypes[0];
	TemplateConditionsForSourceTable = "%1 = &%1"; // @query-part
	ConditionsForSourceTable = New Array;
	If SourceType = "BudgetTurnovers" Then
		ConditionsForSourceTable.Add(StringFunctionsClientServer.SubstituteParametersToString(
			TemplateConditionsForSourceTable, "Scenario"));
	Else
		ConditionsForSourceTable.Add("Scenario IN (&PlanningScenarios)");
	EndIf;
	If ValueIsFilled(Query.Parameters.Organization) Then
		ConditionsForSourceTable.Add(StringFunctionsClientServer.SubstituteParametersToString(
		TemplateConditionsForSourceTable, "Organization"));
	EndIf;
	If ValueIsFilled(Query.Parameters.Department) Then
		ConditionsForSourceTable.Add(StringFunctionsClientServer.SubstituteParametersToString(
		TemplateConditionsForSourceTable, "Department"));
	EndIf;
	If SourceType = "BudgetTurnovers" Then
		QueryText = StrReplace(QueryText, "&SourceTableConditionsAndAlignmentFields", StrConcat(
			ConditionsForSourceTable, " And "));
	Else
		QueryText = StrReplace(QueryText, "&SourceTableConditionsAndAlignmentFields_" + SourceType,
			StrConcat(ConditionsForSourceTable, " And "));
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTLimitRules(Query, QueryTexts)

	RegisterName = "TTLimitRules"; 
	
	QueryText =
	"SELECT
	|	LimitRules.Ref AS LimitsRule,
	|	LimitRules.BudgetFlowOrBalanceItem AS BudgetFlowItem,
	|	LimitRules.Periodicity AS Periodicity,
	|	CASE
	|		WHEN CompanyLimitRules.Ref IS NULL
	|			THEN VALUE(Catalog.Companies.EmptyRef)
	|		ELSE &Organization
	|	END AS Organization,
	|	CASE
	|		WHEN DivisionLimitRules.Ref IS NULL
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE &Department
	|	END AS Department,
	|	&FieldTextTypesOfRuleAnalytics
	|INTO TTLimitRules
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
	|
	|WHERE
	|	&LimitsRegisterIsUsed
	|	AND LimitRules.BudgetFlowOrBalanceItem = &BudgetFlowItem
	|	AND (LimitRules.Scenario = &Scenario
	|			OR LimitRules.Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef))
	|	AND NOT LimitRules.DeletionMark
	|	AND LimitRules.Owner.Status = VALUE(Enum.BudgetingModelStatuses.Valid)";
	
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
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableBudgetTurnovers(Query, QueryTexts, Registers)
	
	RegisterName = "BudgetTurnovers";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTheseCalculationRules", QueryTexts) Then
		QueryTextTTTheseCalculationRules(Query, QueryTexts);
	EndIf;
	
	QueryText =
		"SELECT
		|	&UpdateDate AS Period,
		|	&CalculationRule AS CalculationRule,
		|	Data.PlanningPeriod AS PlanningPeriod,
		|	Data.Scenario AS Scenario,
		|	&Status AS Status,
		|	Data.BudgetFlowItem AS BudgetFlowItem,
		|	Data.Organization AS Organization,
		|	Data.Department AS Department,
		|	Data.Currency AS Currency,
		|	&TextOfDimensionsFields,
		|	Data.CountTurnover AS Count,
		|	Data.SumManTurnover AS SumMan,
		|	Data.ScenarioAmountTurnover AS ScenarioAmount,
		|	Data.SumComplTurnover AS SumCompl,
		|	Data.AmountInCurrencyTurnover AS AmountInCurrency
		|FROM
		|	Data AS Data
		|WHERE
		|	&Status <> VALUE(Enum.PlanStatuses.RolledBack_)
		|	AND &ConditionForRegistrar";
	If ValueIsFilled(Query.Parameters.DocumentBasis) Then
		QueryText = StrReplace(QueryText, "&ConditionForRegistrar", "Data.Recorder = &DocumentBasis");
	Else
		QueryText = StrReplace(QueryText, "&ConditionForRegistrar", "TRUE");
	EndIf;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	ArrayOfAnalystFields = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
		"Data.Dimension%1 AS Dimension%1", DimensionNumber));
	EndDo;
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", StrConcat(ArrayOfAnalystFields, "," + Chars.LF
		+ Chars.Tab));
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLimitsByBudgetingData(Query, QueryTexts, Registers)
	
	RegisterName = "LimitsByBudgetingData";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not ValueIsFilled(Query.Parameters.LimitedTransaction) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTheseCalculationRules", QueryTexts) Then
		QueryTextTTTheseCalculationRules(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLimitRules", QueryTexts) Then
		QueryTextTTLimitRules(Query, QueryTexts);
	EndIf;
	
	QueryText =
		"SELECT
		|	&UpdateDate AS Period,
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
		|	LimitRules.LimitsRule AS LimitsRule,
		|	LimitRules.Organization AS Organization,
		|	LimitRules.Department AS Department,
		|	Data.Currency AS Currency,
		|	&TextOfDimensionsFields,
		|	Data.AmountInCurrencyTurnover AS Limit
		|FROM
		|	Data AS Data
		|		INNER JOIN TTLimitRules AS LimitRules
		|		ON Data.BudgetFlowItem = LimitRules.BudgetFlowItem
		|WHERE
		|	&LimitsRegisterIsUsed
		|	AND &Status = VALUE(Enum.PlanStatuses.Upholded)
		|	AND Data.AmountInCurrencyTurnover <> 0
		|	AND &ConditionForRegistrar";
	If ValueIsFilled(Query.Parameters.DocumentBasis) Then
		QueryText = StrReplace(QueryText, "&ConditionForRegistrar", "Data.Recorder = &DocumentBasis");
	Else
		QueryText = StrReplace(QueryText, "&ConditionForRegistrar", "TRUE");
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
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
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Scenario)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf