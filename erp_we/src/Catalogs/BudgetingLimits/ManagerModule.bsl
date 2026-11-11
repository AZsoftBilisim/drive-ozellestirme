
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns an updated table of the limit rule Analytics hierarchy, taking into account the model parameters, article Analytics, and the previously defined rule hierarchy.
// 
// Parameters:
//  BudgetingModel - CatalogRef.BudgetingModels - The budgeting model that the limits rule applies to.
//  BudgetFlowOrBalanceItem - CatalogRef.BudgetFlowItems - Article the budgets of the rules limits.
//  SourceOfSpecifiedHierarchy - ValueTable - tabular part of the rule Catalog element:
//   * LineNumber  - Number - row number of the table.
//   * DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Filled in if the line contains budgeting Analytics.
//   * DimensionName - String - Filled in if the line contains budgeting Analytics.
//   * Used - Boolean - Flag for using Analytics or measurement.
//   				- CatalogRef.BudgetingLimits - A reference to the rule from which the hierarchy will be taken.
//   				- CatalogObject.BudgetingLimits - The rule object from which the hierarchy will be taken.
//
// Returns:
//  ValueTable  - updated analytics hierarchy table:
//   * DimensionKind  - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Filled in if the line contains budgeting Analytics.
//   * DimensionName  - String - Filled in if the line contains budgeting Analytics.
//   * Used  - Boolean - Flag for using Analytics or measurement.
//   * Presentation - String - An analysis or measurement view.
//
Function DimensionsHierarchy(BudgetingModel, BudgetFlowOrBalanceItem, SourceOfSpecifiedHierarchy) Export
	
	MetadataTables = Metadata.Catalogs.BudgetingLimits.TabularSections.DimensionsHierarchy.Attributes;
	PresentationLength = Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.DescriptionLength;
	TypicalAnalyticsPresentation = New TypeDescription("String",, New StringQualifiers(PresentationLength, AllowedLength.Variable));
	
	If Not ValueIsFilled(BudgetingModel)
	 Or Not ValueIsFilled(BudgetFlowOrBalanceItem) Then
		DimensionsHierarchy = New ValueTable();
		DimensionsHierarchy.Columns.Add("DimensionKind",  MetadataTables.DimensionKind.Type);
		DimensionsHierarchy.Columns.Add("DimensionName",  MetadataTables.DimensionName.Type);
		DimensionsHierarchy.Columns.Add("Used",  MetadataTables.Used.Type);
		DimensionsHierarchy.Columns.Add("Presentation", TypicalAnalyticsPresentation);
	
		Return DimensionsHierarchy;
	EndIf;
	
	ModelDetails = Common.ObjectAttributesValues(BudgetingModel,
		"BudgetsByBusinessUnits, BudgetsByCompanies");
	
	// Fill in the default hierarchy from the settings of the budget model and the article.
	DefaultAnalyticsHierarchy = New ValueTable();
	DefaultAnalyticsHierarchy.Columns.Add("DimensionKind", MetadataTables.DimensionKind.Type);
	DefaultAnalyticsHierarchy.Columns.Add("DimensionName", MetadataTables.DimensionName.Type);
	DefaultAnalyticsHierarchy.Columns.Add("Presentation", TypicalAnalyticsPresentation);
	DefaultAnalyticsHierarchy.Columns.Add("PlaceInHierarchy", New TypeDescription("Number", New NumberQualifiers(2, 0, AllowedSign.Nonnegative)));
	
	If ModelDetails.BudgetsByCompanies Then
		AnalyticsLine_ = DefaultAnalyticsHierarchy.Add();
		AnalyticsLine_.DimensionName   = "Organization";
		AnalyticsLine_.Presentation  = BudgetReportingClientServer.PresentationOfBudgetingDimension(
			"Organization");
		AnalyticsLine_.PlaceInHierarchy = DefaultAnalyticsHierarchy.Count();
	EndIf;
	
	If ModelDetails.BudgetsByBusinessUnits Then
		AnalyticsLine_ = DefaultAnalyticsHierarchy.Add();
		AnalyticsLine_.DimensionName   = "Department";
		AnalyticsLine_.Presentation  = BudgetReportingClientServer.PresentationOfBudgetingDimension(
			"Department");
		AnalyticsLine_.PlaceInHierarchy = DefaultAnalyticsHierarchy.Count();
	EndIf;
	
	PathToBudgetLineAnalysts = PathToBudgetLineAnalysts();
	DetailsOfArticleAnalysis = Common.ObjectAttributesValues(BudgetFlowOrBalanceItem, 
		PathToBudgetLineAnalysts);
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		DimensionKind = DetailsOfArticleAnalysis["DimensionKind" + DimensionNumber];
		If Not ValueIsFilled(DimensionKind) Then
			Continue;
		EndIf;
		AnalyticsLine_ = DefaultAnalyticsHierarchy.Add();
		AnalyticsLine_.DimensionKind   = DimensionKind;
		AnalyticsLine_.Presentation  = DetailsOfArticleAnalysis["DimensionKind" + DimensionNumber + "Description"];
		AnalyticsLine_.PlaceInHierarchy = DefaultAnalyticsHierarchy.Count();
	EndDo;
	
	// Update the analytics usage flag and the place in the hierarchy from the tabular part of the object.
	If TypeOf(SourceOfSpecifiedHierarchy) = Type("ValueTable") Then
		HierarchyOfObjectAnalysts = SourceOfSpecifiedHierarchy;
	Else
		ColumnNames = "LineNumber, DimensionKind, DimensionName, Used, DimensionPopulationExpression, FillInAnalyticsWithSpecifiedValue, DimensionValue";
		HierarchyOfObjectAnalysts = SourceOfSpecifiedHierarchy.DimensionsHierarchy.Unload(, ColumnNames);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("DefaultAnalyticsHierarchy", DefaultAnalyticsHierarchy);
	Query.SetParameter("HierarchyOfObjectAnalysts", HierarchyOfObjectAnalysts);
	Query.Text =
	"SELECT
	|	DefaultAnalyticsHierarchy.DimensionKind AS DimensionKind,
	|	DefaultAnalyticsHierarchy.DimensionName AS DimensionName,
	|	DefaultAnalyticsHierarchy.Presentation AS Presentation,
	|	DefaultAnalyticsHierarchy.PlaceInHierarchy AS PlaceInHierarchy
	|INTO DefaultAnalyticsHierarchy
	|FROM
	|	&DefaultAnalyticsHierarchy AS DefaultAnalyticsHierarchy
	|;
	|
	|SELECT
	|	HierarchyOfObjectAnalysts.LineNumber AS LineNumber,
	|	HierarchyOfObjectAnalysts.DimensionKind AS DimensionKind,
	|	HierarchyOfObjectAnalysts.DimensionName AS DimensionName,
	|	HierarchyOfObjectAnalysts.Used AS Used,
	|	HierarchyOfObjectAnalysts.DimensionPopulationExpression AS DimensionPopulationExpression,
	|	HierarchyOfObjectAnalysts.FillInAnalyticsWithSpecifiedValue AS FillInAnalyticsWithSpecifiedValue,
	|	HierarchyOfObjectAnalysts.DimensionValue AS DimensionValue
	|INTO HierarchyOfObjectAnalysts
	|FROM
	|	&HierarchyOfObjectAnalysts AS HierarchyOfObjectAnalysts
	|;
	|
	|SELECT
	|	DefaultAnalyticsHierarchy.DimensionKind AS DimensionKind,
	|	DefaultAnalyticsHierarchy.DimensionName AS DimensionName,
	|	DefaultAnalyticsHierarchy.Presentation AS Presentation,
	|	ISNULL(HierarchyOfObjectAnalysts.Used, FALSE) AS Used,
	|	ISNULL(HierarchyOfObjectAnalysts.DimensionPopulationExpression, """") AS DimensionPopulationExpression,
	|	ISNULL(HierarchyOfObjectAnalysts.FillInAnalyticsWithSpecifiedValue, FALSE) AS FillInAnalyticsWithSpecifiedValue,
	|	ISNULL(HierarchyOfObjectAnalysts.DimensionValue, UNDEFINED) AS DimensionValue
	|FROM
	|	DefaultAnalyticsHierarchy AS DefaultAnalyticsHierarchy
	|LEFT JOIN
	|	HierarchyOfObjectAnalysts AS HierarchyOfObjectAnalysts
	|ON
	|	DefaultAnalyticsHierarchy.DimensionKind = HierarchyOfObjectAnalysts.DimensionKind
	|		AND DefaultAnalyticsHierarchy.DimensionName = HierarchyOfObjectAnalysts.DimensionName
	|ORDER BY
	|	ISNULL(HierarchyOfObjectAnalysts.LineNumber, 999),
	|	DefaultAnalyticsHierarchy.PlaceInHierarchy";
	
	DimensionsHierarchy = Query.Execute().Unload();
	
	Return DimensionsHierarchy;
	
EndFunction

// Returns a rule - dimension hierarchy (analyst) match for an array of rules
// indicating the columns that contain the result for the plan-fact table of limits.
// 
// Parameters:
//  Rules - Array of CatalogRef.BudgetingLimits - An array of regulations limits.
//
// Returns:
//  Map of KeyAndValue - updated analytics hierarchy table:
//   * Key - CatalogRef.BudgetingLimits - Rule of budgeting limits.
//   * Value - ValueTable - Hierarchy of rule analysts with indication of columns of the fact plan table:
//     ** NumberInHierarchy - Number - Line number in the hierarchy. The smaller the number, the higher the dimension (analytics) in the hierarchy. 
//     					A number from 1 to (the maximum number of analysts in budgeting + 2 dimensions).
//     ** NumberInHierarchyAmongThoseUsed - Number - The number of the row in the hierarchy, taking into account only the dimensions used (types of analytics).
//     ** MeasurementViewAnalytics - String - The name of the dimension, for example, "Organization".
//     							- ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//     ** Used - Boolean - flag for using a measurement (type of analytics).
//     ** PathToAnalytics - String - The path to the data of the measurement value (analytics).
//     					For measurements, this is the name of the measurement, for analytics, this is numbered analytics under the number
//     					specified in the article.
//
Function HierarchyOfAnalyticsByRulesWithSourceColumns(Rules) Export
	
	Result = New Map;
	HierarchyTableTemplate = New ValueTable();
	HierarchyTableTemplate.Columns.Add("NumberInHierarchy", New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	HierarchyTableTemplate.Columns.Add("NumberInHierarchyAmongThoseUsed", New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	HierarchyTableTemplate.Columns.Add("MeasurementViewAnalytics", New TypeDescription("String, ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions",, New StringQualifiers(50, AllowedLength.Variable)));
	HierarchyTableTemplate.Columns.Add("Used", New TypeDescription("Boolean"));
	HierarchyTableTemplate.Columns.Add("PathToAnalytics", New TypeDescription("String",, New StringQualifiers(100, AllowedLength.Variable)));
	
	// 1. We get a hierarchy of analysts according to the rules.
	Query = New Query;
	Query.SetParameter("Rules", Rules);
	
	QueryTexts = New Array;
	Separator = ";
	|
	|//////////////////////////////////////////////////////
	|";
	
	// 1.1. Taking into account a possible erroneous situation when the analytics for the article have been changed, but not in the rule.
	// Getting measurements (types of analytics) by default from the data of the budgeting model and the article.
	QueryTextsOrderOfMeasurements = New Array();
	TextUnion = "
	|
	|UNION ALL
	|
	|";
	
	Text =
	"SELECT
	|	Rules.Ref AS LimitsRule,
	|	1 AS DefaultAnalyticsViewDimensionNumber,
	|	""Organization"" AS MeasurementViewAnalytics,
	|	""Organization"" AS PathToAnalytics
	|INTO DefaultAnalytics
	|FROM
	|	Catalog.BudgetingLimits AS Rules
	|WHERE
	|	Rules.Ref IN (&Rules)
	|	AND Rules.Owner.BudgetsByCompanies
	|
	|UNION ALL
	|
	|SELECT
	|	Rules.Ref AS LimitsRule,
	|	2 AS DefaultAnalyticsViewDimensionNumber,
	|	""Department"" AS MeasurementViewAnalytics,
	|	""Department"" AS PathToAnalytics
	|FROM
	|	Catalog.BudgetingLimits AS Rules
	|WHERE
	|	Rules.Ref IN (&Rules)
	|	AND Rules.Owner.BudgetsByBusinessUnits";
	QueryTextsOrderOfMeasurements.Add(Text);
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		Text =
		"SELECT
		|	Rules.Ref AS LimitsRule,
		|	&DefaultAnalyticsViewDimensionNumber AS DefaultAnalyticsViewDimensionNumber,
		|	&DimensionKind AS MeasurementViewAnalytics,
		|	&PathToAnalytics AS PathToAnalytics
		|FROM
		|	Catalog.BudgetingLimits AS Rules
		|WHERE
		|	Rules.Ref IN (&Rules)";
		Text = StrReplace(Text, "&DefaultAnalyticsViewDimensionNumber", DimensionNumber + 2);
		Text = StrReplace(Text, "&DimensionKind", "Rules.BudgetFlowOrBalanceItem.DimensionKind" + DimensionNumber);
		Text = StrReplace(Text, "&PathToAnalytics", """Dimension" + DimensionNumber + """");
		
		QueryTextsOrderOfMeasurements.Add(Text);
	EndDo;
	
	Text = StrConcat(QueryTextsOrderOfMeasurements, TextUnion);
	
	QueryTexts.Add(Text);
	
	// 1.2. Selection of the hierarchy of dimensions and types of analytics from the rule.
	Text =
	"SELECT
	|	RulesHierarchyOfAnalysts.Ref AS LimitsRule,
	|	RulesHierarchyOfAnalysts.LineNumber AS LineNumber,
	|	RulesHierarchyOfAnalysts.Used AS Used,
	|	CASE
	|		WHEN RulesHierarchyOfAnalysts.DimensionName <> """"
	|			THEN RulesHierarchyOfAnalysts.DimensionName
	|		ELSE RulesHierarchyOfAnalysts.DimensionKind
	|	END AS MeasurementViewAnalytics
	|INTO HierarchyOfRules
	|FROM
	|	Catalog.BudgetingLimits.DimensionsHierarchy AS RulesHierarchyOfAnalysts
	|WHERE
	|	RulesHierarchyOfAnalysts.Ref IN (&Rules)";
	
	QueryTexts.Add(Text);
	
	// 1.3. Combining sets. If, as a result of an error, there is an analysis in the article that is not in the article, then it is not used at the end of the hierarchy. 
	Text =
	"SELECT
	|	DefaultAnalytics.LimitsRule AS LimitsRule,
	|	DefaultAnalytics.MeasurementViewAnalytics AS MeasurementViewAnalytics,
	|	DefaultAnalytics.PathToAnalytics AS PathToAnalytics,
	|	ISNULL(HierarchyOfRules.Used, FALSE) AS Used,
	|	ISNULL(HierarchyOfRules.LineNumber, 999) * 100 +
	|		DefaultAnalytics.DefaultAnalyticsViewDimensionNumber AS LevelInHierarchy
	|FROM
	|	DefaultAnalytics AS DefaultAnalytics
	|		LEFT JOIN HierarchyOfRules AS HierarchyOfRules
	|		ON DefaultAnalytics.LimitsRule = HierarchyOfRules.LimitsRule
	|		AND DefaultAnalytics.MeasurementViewAnalytics = HierarchyOfRules.MeasurementViewAnalytics
	|ORDER BY
	|	LimitsRule,
	|	LevelInHierarchy
	|TOTALS
	|BY
	|	LimitsRule,
	|	LevelInHierarchy";
	
	QueryTexts.Add(Text);
	
	Query.Text = StrConcat(QueryTexts, Separator);
	
	RuleSelection = Query.Execute().Select(QueryResultIteration.ByGroups, "LimitsRule");
	While RuleSelection.Next() Do
		SelectionLevelInHierarchy = RuleSelection.Select(QueryResultIteration.ByGroups, "LevelInHierarchy");
		Rule = RuleSelection.LimitsRule; 
		DimensionsHierarchy = HierarchyTableTemplate.CopyColumns();
		NumberInHierarchy = 0;
		NumberInHierarchyAmongThoseUsed = 0;
		While SelectionLevelInHierarchy.Next() Do
			RecordsSelection = SelectionLevelInHierarchy.Select();
			While RecordsSelection.Next() Do
				NumberInHierarchy = NumberInHierarchy + 1;
				If RecordsSelection.Used Then
					NumberInHierarchyAmongThoseUsed = NumberInHierarchyAmongThoseUsed + 1;
				EndIf;
				NewRow = DimensionsHierarchy.Add();
				FillPropertyValues(NewRow, RecordsSelection, "MeasurementViewAnalytics, Used, PathToAnalytics");
				NewRow.NumberInHierarchy = NumberInHierarchy;
				NewRow.NumberInHierarchyAmongThoseUsed = ?(RecordsSelection.Used, NumberInHierarchyAmongThoseUsed, 0);
			EndDo;
		EndDo;
		Result.Insert(Rule, DimensionsHierarchy);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a view of the used hierarchy of limit rule Analytics.
//
// Parameters:
//  SourceOfSpecifiedHierarchy - ValueTable - tabular part of the rule Catalog element:
//   * LineNumber  - Number - row number of the table.
//   * DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Filled in if the line contains budgeting Analytics.
//   * DimensionName - String - Filled in if the line contains budgeting Analytics.
//   * Used - Boolean - Flag for using Analytics or measurement.
//   				- CatalogRef.BudgetingLimits - A reference to the rule from which the hierarchy will be taken.
//   				- CatalogObject.BudgetingLimits - The rule object from which the hierarchy will be taken.
//
// Returns:
//  String - Enumeration of the used analytics, taking into account the hierarchy.
//
Function DimensionPresentation(SourceOfSpecifiedHierarchy) Export
	
	If TypeOf(SourceOfSpecifiedHierarchy) = Type("ValueTable") Then
		DimensionsHierarchy = SourceOfSpecifiedHierarchy;
	Else
		DimensionsHierarchy = SourceOfSpecifiedHierarchy.DimensionsHierarchy.Unload();
	EndIf;
	
	Query = New Query;
	Query.SetParameter("DimensionsHierarchy", DimensionsHierarchy);
	Query.Text =
	"SELECT
	|	DimensionsHierarchy.DimensionKind AS DimensionKind,
	|	DimensionsHierarchy.DimensionName AS DimensionName,
	|	DimensionsHierarchy.Used AS Used,
	|	DimensionsHierarchy.LineNumber AS LineNumber
	|INTO DimensionsHierarchy
	|FROM
	|	&DimensionsHierarchy AS DimensionsHierarchy
	|;
	|
	|SELECT
	|	CASE
	|		WHEN DimensionsHierarchy.DimensionName = ""Organization""
	|			THEN &RepresentationOfTheOrganization
	|		WHEN DimensionsHierarchy.DimensionName = ""Department""
	|			THEN &DivisionRepresentation
	|		ELSE PRESENTATION(DimensionsHierarchy.DimensionKind)
	|	END AS Presentation
	|FROM
	|	DimensionsHierarchy AS DimensionsHierarchy
	|WHERE
	|	DimensionsHierarchy.Used
	|ORDER BY
	|	DimensionsHierarchy.LineNumber";
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	RepresentationOfTheOrganization   = BudgetReportingClientServer.PresentationOfBudgetingDimension("Organization",
		DefaultLanguageCode);
	DivisionRepresentation = BudgetReportingClientServer.PresentationOfBudgetingDimension("Department",
		DefaultLanguageCode);
	Query.SetParameter("RepresentationOfTheOrganization", RepresentationOfTheOrganization);
	Query.SetParameter("DivisionRepresentation", DivisionRepresentation);
	
	EnumeratingAnalytics = Query.Execute().Unload().UnloadColumn("Presentation");
	DimensionPresentation = StrConcat(EnumeratingAnalytics, ", ");
	
	Return DimensionPresentation;
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsFolder OR
	|	( Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef)
	|	OR ValueAllowed(Scenario)
	|	) AND ValueAllowed(BudgetFlowOrBalanceItem)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
//  Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("BudgetFlowOrBalanceItem");
	Result.Add("Scenario");
	Result.Add("Periodicity");
	Result.Add("LimitType");
	Result.Add("LimitedTransaction");
	
	Return Result;
	
EndFunction

// Checks the use of the object
//
// Parameters:
//  Parameters - Structure - contains an object that you want to check for usage
//  StorageAddress - String - address of the storage where the verification result will be placed.
//
Procedure CheckObjectUsage(Parameters, StorageAddress) Export
	
	ThereAreRefs = CommonServerCall.RefsToObjectFound(Parameters.Object);
	
	If Not ThereAreRefs Then
		ThereAreRefs = CheckForBudgetTurnover(Parameters.Object);
	EndIf;
	
	PutToTempStorage(ThereAreRefs, StorageAddress);
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		LimitedTransactions = LimitsByBudgetingDataServer.UsedLimitedOFOperations();
		If LimitedTransactions.Count() = 1 Then
			FilterParameters = Undefined;
			Parameters.Property("Filter", FilterParameters);
			If FilterParameters = Undefined Then
				FilterParameters = New Structure("LimitedTransaction", LimitedTransactions[0]);
			Else
				FilterParameters.Insert("LimitedTransaction", LimitedTransactions[0]);
			EndIf;
			Parameters.Insert("Filter", FilterParameters);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function CheckForBudgetTurnover(RuleForObtainingFact)
	
	If TypeOf(RuleForObtainingFact) = Type("CatalogRef.BudgetingLimits")
		And Not ValueIsFilled(RuleForObtainingFact) Then
		Return False;
	ElsIf TypeOf(RuleForObtainingFact) = Type("CatalogObject.BudgetingLimits")
		And Not ValueIsFilled(RuleForObtainingFact.Ref) Then
		Return False;
	EndIf;
	
	If TypeOf(RuleForObtainingFact) = Type("CatalogRef.BudgetingLimits") Then
		ObjectAttributes = Common.ObjectAttributesValues(RuleForObtainingFact, "BudgetFlowOrBalanceItem, Scenario");
		BudgetFlowOrBalanceItem = ObjectAttributes.BudgetFlowOrBalanceItem;
		Scenario = ObjectAttributes.Scenario;
	Else
		BudgetFlowOrBalanceItem = RuleForObtainingFact.BudgetFlowOrBalanceItem;
		Scenario = RuleForObtainingFact.Scenario;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	BudgetTurnovers.BudgetFlowItem AS BudgetFlowItem
	|FROM
	|	AccumulationRegister.BudgetTurnovers.Turnovers(
	|			,
	|			,
	|			,
	|			BudgetFlowItem = &BudgetFlowOrBalanceItem
	|				AND (Scenario = &Scenario
	|					OR &ByAllScenarios)) AS BudgetTurnovers";
	Query.SetParameter("BudgetFlowOrBalanceItem", BudgetFlowOrBalanceItem);
	Query.SetParameter("Scenario", Scenario);
	Query.SetParameter("ByAllScenarios", Not ValueIsFilled(Scenario));
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

Function PathToBudgetLineAnalysts()
	
	PathToAnalyticsDetails = New Array();
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		PathToAnalyticsDetails.Add("DimensionKind" + DimensionNumber);
		PathToAnalyticsDetails.Add("DimensionKind" + DimensionNumber + ".Description");
	EndDo;
	
	Return StrConcat(PathToAnalyticsDetails, " ,");
	
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.BudgetingLimits.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.45";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("467269e2-985c-42c2-800c-86237397d40c");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.BudgetingLimits.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền mục tin ""Giao dịch bị giới hạn"" trong quy tắc hạn mức bởi giá trị ""Lưu chuyển tiền tệ"".';
							|ru = 'Заполняет реквизит ""Лимитируемая операция"" в правилах лимитов значением ""Движение денежных средств"".';
							|en = 'Fills in the ""Limited operation"" attribute in the limit rules with the ""Cash flow"" value.'; fa = 'Fills in the ""Limited operation"" attribute in the limit rules with the ""Cash flow"" value.';
							|it = 'Fills in the ""Limited operation"" attribute in the limit rules with the ""Cash flow"" value.';
							|pl = 'Fills in the ""Limited operation"" attribute in the limit rules with the ""Cash flow"" value.';
							|tr = 'Limit kurallarındaki ""Limite tabi işlem"" alanını ""Nakit Akışı"" değeriyle doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.BudgetingLimits.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.BudgetingLimits.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.BudgetingLimits.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// LongDesc
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters = Undefined) Export
	
	MetadataObjectName = Metadata.Catalogs.BudgetingLimits.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = MetadataObjectName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText =
	"SELECT
	|	BudgetingLimits.Ref AS Ref
	|FROM
	|	Catalog.BudgetingLimits AS BudgetingLimits
	|WHERE
	|	BudgetingLimits.LimitedTransaction = VALUE(Enum.LimitedTransactions.EmptyRef)";
	
	Query = New Query(QueryText);
	Result = Query.Execute();
	
	ResultTable1 = Result.Unload();
	DataProcessorRefs = ResultTable1.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, DataProcessorRefs);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	MetadataObject = Metadata.Catalogs.BudgetingLimits;
	MetadataObjectName = MetadataObject.FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, MetadataObjectName);
		Return;
	EndIf;
	
	For Each Selection In UpdatedData Do
		BeginTransaction();
		
		Try
			
			Rule = Selection.Ref; // CatalogRef.BudgetingLimits - 
			
			Block = New DataLock;
			LockItem = Block.Add(MetadataObjectName);
			LockItem.SetValue("Ref", Rule);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			RuleObject_ = Rule.GetObject();
			RuleObject_.LimitedTransaction = Enums.LimitedTransactions.FlowOfCash;
			InfobaseUpdate.WriteObject(RuleObject_);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			Template = NStr("vi = 'Không thể ghi lại quy tắc hạn mức %1 do nguyên nhân: %2';
							|ru = 'Не удалось записать правило лимитов %1 по причине: %2';
							|en = 'Cannot save the ""%1"" limit rule due to: %2'; fa = 'Cannot save the ""%1"" limit rule due to: %2';
							|it = 'Cannot save the ""%1"" limit rule due to: %2';
							|pl = 'Cannot save the ""%1"" limit rule due to: %2';
							|tr = '%1 limit kuralı, şu nedenle kaydedilemedi: %2'");
			
			MessageText = 	StrTemplate(
				Template,
				Rule,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Error,
				MetadataObject,,
				MessageText);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, MetadataObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
