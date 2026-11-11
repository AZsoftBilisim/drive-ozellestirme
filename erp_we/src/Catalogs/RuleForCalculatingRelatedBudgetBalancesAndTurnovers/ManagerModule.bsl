#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array of String - names of blocked Bank details:
//		* AttributeToLock - String - Name of the blocked account.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("Receiver");
	Result.Add("Source");
	Result.Add("SourceType");
	Result.Add("RecordCalculationInPlanningDocuments");
	
	Return Result;
	
EndFunction

// Updates all cached query texts in the calculation rules.
//
Procedure UpdateQueryRepositories() Export
	
	Selection = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Select();
	While Selection.Next() Do
		CatalogObject = Selection.GetObject();
		If CatalogObject.Status = Enums.BudgetingRuleStatuses.Valid
			And Not CatalogObject.DeletionMark Then
			RequestByRule = GetRequestForPaymentRulesSettings(CatalogObject);
		Else
			RequestByRule = Undefined;
		EndIf;
		CatalogObject.RequestStorage = New ValueStorage(RequestByRule);
		CatalogObject.DataExchange.Load = True;
		CatalogObject.Write();
	EndDo;
	
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
	|	ValueAllowed(Source)
	|	AND ValueAllowed(Receiver)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

// Returns a data layout diagram for configuring selection by turnover (Balance) of an item (indicator) of budgets.
//
// Parameters:
//  ItemIndicator - CatalogRef.BudgetFlowItems,
//  				 CatalogRef.BudgetBalanceItems
//  TypesOfAnalyticsArticlesOfIndicator - Structure - structure of types of analytics of an article (indicator) of budgets
//
// Returns:
//  DataCompositionSchema
//
Function GetDataLayoutDiagram(SourceType, ItemIndicator, TypesOfAnalyticsArticlesOfIndicator) Export
	
	DataSourceParameters = Common.CopyRecursive(
		BudgetingCached.ParametersOfRegisterOfSourceOfReceivingDataForBudgeting(SourceType));
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,
		Type("DataCompositionSchemaDataSetQuery"),
		"SourceData");
	DataSet.AutoFillAvailableFields = True;
	
	If SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers
		And ValueIsFilled(ItemIndicator) Then
		
		Attributes = Common.ObjectAttributesValues(ItemIndicator, "RecordByCurrency, RecordByQuantity");
		If Not Attributes.RecordByCurrency Then
			DataSourceParameters.Dimensions.Delete("Currency");
			DataSourceParameters.Resources.Delete("AmountInCurrency");
		EndIf;
		If Not Attributes.RecordByQuantity Then
			DataSourceParameters.Resources.Delete("Count");
		EndIf;
		
	EndIf;
	
	//@skip-check bsl-ql-hub
	QueryTextOfDataset = 
	"SELECT
	|	&TextOfMeasurementFields,
	|	&TextOfDimensionsFields,
	|	&TextOfResourcesFields
	|{SELECT
	|	&TextOfDimensionAliases,
	|	&TextOfAnalystAliases,
	|	&TextOfResourceAliases}
	|FROM
	|	AccumulationRegister.BudgetTurnovers.Turnovers({&BeginOfPeriod}, {&EndOfPeriod}, , {&TextOfMeasurementConditions}) AS SourceData
	|{WHERE
	|	&TextOfAnalystConditions,
	|	&TextOfResourcesFields}";
	
	TextOfMeasurementFields = "";
	TextOfDimensionsFields = "";
	TextOfResourcesFields = "";
	TextOfDimensionAliases = "";
	TextOfAnalystAliases = "";
	TextOfResourceAliases = "";
	TextOfMeasurementConditions = "";
	TextOfAnalystConditions = "";
	
	FinReports = FinancialReportingServer;
	
	For Each Dimension In DataSourceParameters.Dimensions Do
		FinReports.NewSetField(DataSet, Dimension.Key, Dimension.Key, Dimension.Value.Description,
			Dimension.Value.ValueType);
		TextOfMeasurementFields = TextOfMeasurementFields + ?(TextOfMeasurementFields = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString("SourceData.%1 AS %1", Dimension.Key);
		TextOfDimensionAliases = TextOfDimensionAliases + ?(TextOfDimensionAliases = "", "", "," + Chars.LF
			+ Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString("%1.*", Dimension.Key);
		TextOfMeasurementConditions = TextOfMeasurementConditions + ?(TextOfMeasurementConditions = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString("(%1).* AS %1", Dimension.Key);
	EndDo;
	If Not GetFunctionalOption("UsePartnersAndCounterparties")
		And DataSourceParameters.Dimensions.Property("Partner") Then
		FinReports.NewSetField(DataSet, "Counterparty", , , New TypeDescription("CatalogRef.Counterparties"));
		TextOfMeasurementFields = TextOfMeasurementFields + ?(TextOfMeasurementFields = "", "", "," + Chars.LF + Chars.Tab)
			+ "VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty";
		TextOfDimensionAliases = TextOfDimensionAliases + ?(TextOfDimensionAliases = "", "", "," + Chars.LF
			+ Chars.Tab) + "Counterparty.*";
		TextOfMeasurementConditions = TextOfMeasurementConditions + ?(TextOfMeasurementConditions = "", "", "," + Chars.LF + Chars.Tab)
			+ "(VALUE(Catalog.Counterparties.EmptyRef)).* AS Counterparty";
	EndIf;
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "&TextOfMeasurementFields", TextOfMeasurementFields);
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "&TextOfDimensionAliases",
		TextOfDimensionAliases);
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "&TextOfMeasurementConditions", TextOfMeasurementConditions);
	
	If SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers
		And ValueIsFilled(ItemIndicator) Then
	
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			DimensionKind = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1", DimensionNumber);
			If Not ValueIsFilled(TypesOfAnalyticsArticlesOfIndicator[DimensionKind]) Then
				Continue;
			EndIf;
			Field = FinReports.NewSetField(DataSet, StringFunctionsClientServer.SubstituteParametersToString(
				"Dimension%1", DimensionNumber));
			DimensionKindDescription = StringFunctionsClientServer.SubstituteParametersToString(
				"DimensionKind%1Description", DimensionNumber);
			Field.Title = TypesOfAnalyticsArticlesOfIndicator[DimensionKindDescription];
			TypeOfAnalyticsValueType = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1ValueType",
				DimensionNumber);
			Field.ValueType = TypesOfAnalyticsArticlesOfIndicator[TypeOfAnalyticsValueType];
			TextOfAnalyticsField = "WHEN VALUETYPE(SourceData.Dimension%1) = TYPE(%2) THEN CAST(SourceData.Dimension%1 AS %2)"; // @query-part
			TextsOfAnalyticsFields = New Array;
			For Each TypeOfAnalyticsType In Field.ValueType.Types() Do
				TextsOfAnalyticsFields.Add(StringFunctionsClientServer.SubstituteParametersToString(TextOfAnalyticsField,
					DimensionNumber, FinancialAccountingByBalanceSheetRegisterData.FullTypeName(TypeOfAnalyticsType)));
			EndDo;
			TextOfDimensionsFields = TextOfDimensionsFields + ?(TextOfDimensionsFields = "", "", "," + Chars.LF + Chars.Tab)
				+ StringFunctionsClientServer.SubstituteParametersToString(
				"CASE %1 ELSE UNDEFINED END AS Dimension%2", StrConcat(TextsOfAnalyticsFields, Chars.LF
				+ Chars.Tab), DimensionNumber); //@ query-part
			TextOfAnalystAliases = TextOfAnalystAliases + ?(TextOfAnalystAliases = "", "", "," + Chars.LF
				+ Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString("Dimension%1.*", DimensionNumber); //@ query-part
			TextOfAnalystConditions = TextOfAnalystConditions + ?(TextOfAnalystConditions = "", "", "," + Chars.LF + Chars.Tab)
				+ StringFunctionsClientServer.SubstituteParametersToString(
				"(CASE %1 ELSE UNDEFINED END).* AS Dimension%2", StrConcat(TextsOfAnalyticsFields, Chars.LF
				+ Chars.Tab), DimensionNumber); //@ query-part
		EndDo;
		
	Else
		
		QueryTextOfDataset
			= StrReplace(QueryTextOfDataset, "BudgetTurnovers", DataSourceParameters.RegisterName);
		
	EndIf;
	
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "&TextOfDimensionsFields,", ?(IsBlankString(
		TextOfDimensionsFields), "", TextOfDimensionsFields + ","));
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "&TextOfAnalystAliases,", ?(IsBlankString(
		TextOfAnalystAliases), "", TextOfAnalystAliases + ","));
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "&TextOfAnalystConditions,", ?(IsBlankString(
		TextOfAnalystConditions), "", TextOfAnalystConditions + ","));
	
	For Each Resource In DataSourceParameters.Resources Do
		FinReports.NewSetField(DataSet, Resource.Key, Resource.Key, Resource.Value.Description,
			Resource.Value.ValueType);
		TextOfResourcesFields = TextOfResourcesFields + ?(TextOfResourcesFields = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString("SourceData.%1Turnover AS %1", Resource.Key);
		TextOfResourceAliases = TextOfResourceAliases + ?(TextOfResourceAliases = "", "", "," + Chars.LF
			+ Chars.Tab) + Resource.Key;
	EndDo;
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "&TextOfResourcesFields", TextOfResourcesFields);
	QueryTextOfDataset = StrReplace(QueryTextOfDataset, "&TextOfResourceAliases",
		TextOfResourceAliases);
	
	DataSet.Query = QueryTextOfDataset;
	
	DataCompositionServer.AddParameter(DataCompositionSchema, "BeginOfPeriod", New TypeDescription("Date"));
	DataCompositionServer.AddParameter(DataCompositionSchema, "EndOfPeriod", New TypeDescription("Date"));
	For Each Parameter In DataCompositionSchema.Parameters Do
		Parameter.UseRestriction = True;
		Parameter.IncludeInAvailableFields = False;
	EndDo;
	
	Return DataCompositionSchema;
	
EndFunction

// Returns the data layout scheme for setting the period offset in the rule.
//
// Parameters:
//  DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Dimension kind
//  TabularSectionName - String - name of the tabular part containing the description of the period offset settings
//
// Returns:
//  DataCompositionSchema
//
Function GetDataCompositionSchemaOfPeriodOffset(DimensionKind = Undefined, TabularSectionName = "Custom") Export
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema,
		Type("DataCompositionSchemaDataSetQuery"),
		TabularSectionName);
	
	If ValueIsFilled(DimensionKind) And TabularSectionName = "PaymentScheduleSteps" Then
		
		NamesOfRelatedMetadataObjects = BudgetingCached.NamesOfTypesOfAnalyticsTypeThatContainTablePart(
			DimensionKind, TabularSectionName);
		
		DatasetRequestTemplate = 
		"SELECT
		|	PM_StagesOfPaymentSchedule.Ref AS DimensionValue,
		|	PM_StagesOfPaymentSchedule.LineNumber AS LineNumber,
		|	CASE
		|		WHEN PM_StagesOfPaymentSchedule.Move > &DeliveryPeriodDays
		|			THEN PM_StagesOfPaymentSchedule.Move - &DeliveryPeriodDays
		|		ELSE &DeliveryPeriodDays - PM_StagesOfPaymentSchedule.Move
		|	END AS PeriodOfShift,
		|	VALUE(Enum.Periodicity.DAY) AS OffsetFrequency,
		|	CASE
		|		WHEN PM_StagesOfPaymentSchedule.Move > &DeliveryPeriodDays
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS OffsetForward,
		|	PM_StagesOfPaymentSchedule.PaymentPercentage / 100 AS ZoomRatio
		|{SELECT
		|	DimensionValue,
		|	LineNumber,
		|	PeriodOfShift,
		|	OffsetFrequency,
		|	OffsetForward,
		|	ZoomRatio}
		|FROM
		|	&TabularPartOfAssociatedMetadataObject AS PM_StagesOfPaymentSchedule
		|WHERE
		|	PM_StagesOfPaymentSchedule.CalculateFrom IN (VALUE(Enum.PaymentDateCalculationOptions.FromOrderDate), VALUE(Enum.PaymentDateCalculationOptions.FromApprovalDate))
		|
		|UNION ALL
		|
		|SELECT
		|	PM_StagesOfPaymentSchedule.Ref,
		|	PM_StagesOfPaymentSchedule.LineNumber,
		|	PM_StagesOfPaymentSchedule.Move,
		|	VALUE(Enum.Periodicity.DAY),
		|	FALSE,
		|	PM_StagesOfPaymentSchedule.PaymentPercentage / 100
		|FROM
		|	&TabularPartOfAssociatedMetadataObject AS PM_StagesOfPaymentSchedule
		|WHERE
		|	PM_StagesOfPaymentSchedule.CalculateFrom = VALUE(Enum.PaymentDateCalculationOptions.BeforeShipmentDate)
		|
		|UNION ALL
		|
		|SELECT
		|	PM_StagesOfPaymentSchedule.Ref,
		|	PM_StagesOfPaymentSchedule.LineNumber,
		|	PM_StagesOfPaymentSchedule.Move,
		|	VALUE(Enum.Periodicity.DAY),
		|	TRUE,
		|	PM_StagesOfPaymentSchedule.PaymentPercentage / 100
		|FROM
		|	&TabularPartOfAssociatedMetadataObject AS PM_StagesOfPaymentSchedule
		|WHERE
		|	PM_StagesOfPaymentSchedule.CalculateFrom = VALUE(Enum.PaymentDateCalculationOptions.FromShipmentDate)
		|
		|UNION ALL
		|
		|SELECT
		|	PM_StagesOfPaymentSchedule.Ref,
		|	PM_StagesOfPaymentSchedule.LineNumber,
		|	PM_StagesOfPaymentSchedule.Move + &DeadlineOfTransferOfTitleToGoods,
		|	VALUE(Enum.Periodicity.DAY),
		|	TRUE,
		|	PM_StagesOfPaymentSchedule.PaymentPercentage / 100
		|FROM
		|	&TabularPartOfAssociatedMetadataObject AS PM_StagesOfPaymentSchedule
		|WHERE
		|	PM_StagesOfPaymentSchedule.CalculateFrom = VALUE(Enum.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods)";
		
		QueryTextsOfDataset = New Array;
		For Counter = 1 To NamesOfRelatedMetadataObjects.Count() Do
			MetadataObjectName = NamesOfRelatedMetadataObjects[Counter-1];
			MetadataObject = Common.MetadataObjectByFullName(MetadataObjectName);
			TabularPartOfAssociatedMetadataObject = MetadataObjectName + "." + TabularSectionName;
			QueryTextOfDataset = StrReplace(DatasetRequestTemplate,
				"&TabularPartOfAssociatedMetadataObject", TabularPartOfAssociatedMetadataObject);
			If Counter > 1 Then
				QueryTextOfDataset = StrReplace(QueryTextOfDataset,
				"{SELECT
				|	DimensionValue,
				|	LineNumber,
				|	PeriodOfShift,
				|	OffsetFrequency,
				|	OffsetForward,
				|	ZoomRatio}", ""); // @query-part
			EndIf;
			ReplacementExpressionPatterns = New Map;
			ReplacementExpressionPatterns.Insert(1, "TS_%1.Ref.%2");
			ReplacementExpressionPatterns.Insert(2, "DATEDIFF(BEGINOFPERIOD(TS_%1.Ref.Date, DAY), TS_%1.Ref.%2, DAY)"); // @query-part
			ReplacementParameters = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
				"&DeliveryPeriodDays,&DeadlineOfTransferOfTitleToGoods", ",");
			For Each ReplacementParameter In ReplacementParameters Do
				ParameterReplacementPerformed = False;
				For AttributeNumber = 1 To 2 Do
					If ParameterReplacementPerformed Then
						Break;
					EndIf;
					If AttributeNumber = 1 Then
						If ReplacementParameters.Find(ReplacementParameter) = 0 Then
							AttributesOfReplacement = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
								"DeliveryPeriodDays,ShipmentDueDate", ",");
						Else
							AttributesOfReplacement = CommonClientServer.ValueInArray("DeadlineOfTransferOfTitleToGoods");
						EndIf;
					Else
						AttributesOfReplacement = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
							"DateOfReceipt,DateOfShipment", ",");
					EndIf;
					ExpressionPattern = ReplacementExpressionPatterns.Get(AttributeNumber);
					For Each Attribute In AttributesOfReplacement Do
						If Common.HasObjectAttribute(Attribute, MetadataObject) Then
							QueryTextOfDataset = StrReplace(QueryTextOfDataset, ReplacementParameter,
								StringFunctionsClientServer.SubstituteParametersToString(ExpressionPattern, TabularSectionName, Attribute));
							ParameterReplacementPerformed = True;
							Break;
						EndIf;
					EndDo;
				EndDo;
				If Not ParameterReplacementPerformed Then
					QueryTextOfDataset = StrReplace(QueryTextOfDataset, ReplacementParameter, "0");
				EndIf;
			EndDo;
			QueryTextsOfDataset.Add(QueryTextOfDataset);
			If Common.HasObjectAttribute("PaymentSchedule", MetadataObject) Then
				QueryTextOfDataset = StrReplace(QueryTextOfDataset,
					StringFunctionsClientServer.SubstituteParametersToString(
					"TS_%1.Ref", TabularSectionName), "RelatedMetadataObject.Ref");
				QueryTextOfDataset = StrReplace(QueryTextOfDataset,
					StringFunctionsClientServer.SubstituteParametersToString(
					"%1 AS TS_%2", TabularPartOfAssociatedMetadataObject, TabularSectionName),
					StringFunctionsClientServer.SubstituteParametersToString(
					"Catalog.PaymentSchedules.Stages AS TS_%1
					|	INNER JOIN %2 AS RelatedMetadataObject
					|	ON TS_%1.Ref = RelatedMetadataObject.PaymentSchedule", TabularSectionName, MetadataObjectName)); //@ query-part
				QueryTextsOfDataset.Add(QueryTextOfDataset);
			EndIf;
		EndDo;
		QueryTextOfDataset = StrConcat(QueryTextsOfDataset,
			TMCommonUse.QuerySeparatorInJoin());
		
	Else
		
		QueryTextOfDataset = 
		"SELECT
		|	UNDEFINED AS DimensionValue,
		|	1 AS LineNumber,
		|	0 AS PeriodOfShift,
		|	VALUE(Enum.Periodicity.DAY) AS OffsetFrequency,
		|	FALSE AS OffsetForward,
		|	1 AS ZoomRatio
		|{SELECT
		|	DimensionValue,
		|	LineNumber,
		|	PeriodOfShift,
		|	OffsetFrequency,
		|	OffsetForward,
		|	ZoomRatio}";
		
	EndIf;
	
	DataSet.Query = QueryTextOfDataset;
	
	FinReports = FinancialReportingServer;
	
	FinReports.NewSetField(DataSet, "DimensionValue", "DimensionValue", ,
		Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.Type);
	FinReports.NewSetField(DataSet, "LineNumber", "LineNumber", ,
		New TypeDescription("Number", New NumberQualifiers(10, 0)));
	FinReports.NewSetField(DataSet, "PeriodOfShift", "PeriodOfShift", ,
		New TypeDescription("Number", New NumberQualifiers(10, 0)));
	FinReports.NewSetField(DataSet, "OffsetFrequency", "OffsetFrequency", ,
		New TypeDescription("EnumRef.Periodicity"));
	FinReports.NewSetField(DataSet, "OffsetForward", "OffsetForward", , New TypeDescription("Boolean"));
	FinReports.NewSetField(DataSet, "ZoomRatio", "ZoomRatio", , New TypeDescription("Number",
		New NumberQualifiers(31, 6)));
	
	DataCompositionServer.AddParameter(DataCompositionSchema, "DimensionKind",
		New TypeDescription("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions"), DimensionKind, True);
	
	Settings = DataCompositionSchema.DefaultSettings;
	
	FinReports.NewGrouping(Settings.Structure, , , False);
	
	FinReports.NewSelectionField(Settings, "DimensionValue");
	FinReports.NewSelectionField(Settings, "LineNumber");
	FinReports.NewSelectionField(Settings, "PeriodOfShift");
	FinReports.NewSelectionField(Settings, "OffsetFrequency");
	FinReports.NewSelectionField(Settings, "OffsetForward");
	FinReports.NewSelectionField(Settings, "ZoomRatio");
	
	Return DataCompositionSchema;
	
EndFunction

// Returns a request generated based on the settings of the calculation rule for related Balances and budget turnover.
//
// Parameters:
//  CalculationRule - CatalogObject.RuleForCalculatingRelatedBudgetBalancesAndTurnovers
//
// Returns:
//  Structure:
//   *QueryText - String - Query text
//   *QueryTextTemporaryTable - String - The Query Text Of Temporary Tables
//   *QueryTextsOfDistributionDatabase - Map of KeyAndValue - query texts of temporary tables with distribution databases:
//    **Key - String - name of the temporary table
//    **Value - String - Query text
//   *QueryOptions - Structure - request parameters:
//    **ParameterName - String - value of the request parameter
//   *RuleID - String - hash sum of rule settings
//   *SourceIdentificator - String - Source reference GUIDE
//   *ReceiverId - String - Receiver reference GUIDE
//
Function GetRequestForPaymentRulesSettings(CalculationRule) Export
	
	RequestForSettings = New Structure;
	RequestForSettings.Insert("QueryText", "");
	RequestForSettings.Insert("QueryOptions", New Structure);
	RequestForSettings.Insert("QueryTextTemporaryTable", "");
	RequestForSettings.Insert("QueryTextsOfDistributionDatabase", New Map);
	RequestForSettings.Insert("QueryTextForecastExchangeRates", "");
	RequestForSettings.Insert("QueryTextPartnersCounterparties");
	RequestForSettings.Insert("RuleID", "");
	RequestForSettings.Insert("SourceIdentificator", "");
	RequestForSettings.Insert("ReceiverId", "");
	
	RegisterParameters = BudgetingCached.ParametersOfRegisterOfSourceOfReceivingDataForBudgeting(CalculationRule.SourceType);
	
	TypesOfSourceAnalytics = Undefined;
	If ValueIsFilled(CalculationRule.Source) Then
		TypesOfSourceAnalytics = BudgetingServer.DimensionKinds(CalculationRule.Source, True);
	EndIf;
	DataCompositionSchema = GetDataLayoutDiagram(CalculationRule.SourceType, CalculationRule.Source,
		TypesOfSourceAnalytics);
	SettingsComposer = New DataCompositionSettingsComposer;
	
	DataCompositionSettings = Undefined;
	
	QueryTemplate = 
	"SELECT
	|	CAST(&Receiver_Identifier AS Catalog.BudgetFlowItems) AS BudgetFlowItem,
	|	AliasOfSourceTable.DayPeriod AS DayPeriod,
	|	&PlanningPeriodField AS PlanningPeriod,
	|	&LoggerField_ AS Recorder,
	|	&FieldScenario AS Scenario,
	|	AliasOfSourceTable.Status AS Status,
	|	&OrganizationField_ AS Organization,
	|	&DivisionField AS Department,
	|	&FieldCurrency AS Currency,
	|	&TextOfMeasurementFields,
	|	&TextOfDimensionsFields,
	|	&TextOfSourceAnalystFields,
	|	AliasOfSourceTable.CountTurnover * &ReverseSign AS CountTurnover,
	|	AliasOfSourceTable.SumManTurnover * &ZoomRatio * &ReverseSign AS SumManTurnover,
	|	AliasOfSourceTable.ScenarioAmountTurnover * &ZoomRatio * &ReverseSign AS ScenarioAmountTurnover,
	|	AliasOfSourceTable.SumComplTurnover * &ZoomRatio * &ReverseSign AS SumComplTurnover,
	|	AliasOfSourceTable.AmountInCurrencyTurnover * &ZoomRatio * &ReverseSign AS AmountInCurrencyTurnover,
	|	&CalculationRule AS CalculationRule,
	|	&Expense AS Expense
	|INTO Data
	|FROM
	|	AccumulationRegister.BudgetTurnovers.Turnovers(
	|			{&ExpressionStartOfPeriod},
	|			{&ExpressionEndOfPeriod}, Auto,
	|			&ParametersOfPlanningPeriod
	|				AND &ConditionBySource) AS AliasOfSourceTable
	|WHERE
	|	&ConditionText
	|	AND &ResourceConditions
	|	AND &ConditionsOfPlanningPeriod";
	If CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
		PlanningPeriodField = "PlanningPeriod";
		QueryTemplate = StrReplace(QueryTemplate, "&LoggerField_", "UNDEFINED");
		QueryTemplate = StrReplace(QueryTemplate, "&FieldScenario", "AliasOfSourceTable.Scenario");
		QueryTemplate = StrReplace(QueryTemplate, "&FieldCurrency", "AliasOfSourceTable.Currency");
		QueryTemplate = StrReplace(QueryTemplate, "&CalculationRule", "UNDEFINED");
		QueryTemplate = StrReplace(QueryTemplate, "&ConditionBySource", "BudgetFlowItem IN (&Source_Identifier)");
	Else
		PlanningPeriodField = "DayPeriod";
		If CalculationRule.RecordCalculationInPlanningDocuments Then
			QueryTemplate = StrReplace(QueryTemplate, "&LoggerField_", "AliasOfSourceTable.Recorder");
			QueryTemplate = StrReplace(QueryTemplate, "{&ExpressionStartOfPeriod}", "");
			QueryTemplate = StrReplace(QueryTemplate, "{&ExpressionEndOfPeriod}", "");
			CalculationRuleLink = ?(CalculationRule.IsNew(), CalculationRule.GetNewObjectRef(), CalculationRule.Ref);
			NameOfCalculationRuleParameter = StringFunctionsClientServer.SubstituteParametersToString("CalculationRule_%1",
				StrReplace(CalculationRuleLink.UUID(), "-", ""));
			QueryTemplate = StrReplace(QueryTemplate, "&CalculationRule", "&" + NameOfCalculationRuleParameter);
			RequestForSettings.QueryOptions.Insert(NameOfCalculationRuleParameter, CalculationRuleLink);
		Else
			QueryTemplate = StrReplace(QueryTemplate, "&LoggerField_", "UNDEFINED");
			QueryTemplate = StrReplace(QueryTemplate, "&CalculationRule", "UNDEFINED");
		EndIf;
		QueryTemplate = StrReplace(QueryTemplate, "BudgetTurnovers", RegisterParameters.RegisterName);
		QueryTemplate = StrReplace(QueryTemplate, "&FieldScenario", "AliasOfSourceTable.Scenario.BudgetingScenario");
		QueryTemplate = StrReplace(QueryTemplate, "&FieldCurrency", "AliasOfSourceTable.Scenario.BudgetingScenario.Currency");
		QueryTemplate = StrReplace(QueryTemplate, "&ConditionBySource", "Scenario.BudgetingScenario <> VALUE(Catalog.BudgetingScenarios.EmptyRef)");
	EndIf;
	
	AvailableTypesOfAnalytics = BudgetingCached.AvailableTypesOfAnalyticsForPlanningSourceType(
		CalculationRule.SourceType);
	DataPathOrganization = AvailableTypesOfAnalytics.Get(Type("CatalogRef.Companies"));
	If DataPathOrganization <> Undefined Then
		QueryTemplate = StrReplace(QueryTemplate, "&OrganizationField_", StrReplace(DataPathOrganization, "TableName",
			"AliasOfSourceTable"));
	Else
		QueryTemplate = StrReplace(QueryTemplate, "&OrganizationField_", "VALUE(Catalog.Companies.EmptyRef)");
	EndIf;
	PathToDataDivision = AvailableTypesOfAnalytics.Get(Type("CatalogRef.BusinessStructure"));
	If PathToDataDivision <> Undefined Then
		QueryTemplate = StrReplace(QueryTemplate, "&DivisionField", StrReplace(PathToDataDivision, "TableName",
			"AliasOfSourceTable"));
	Else
		QueryTemplate = StrReplace(QueryTemplate, "&DivisionField", "VALUE(Catalog.BusinessStructure.EmptyRef)");
	EndIf;
	
	BudgetBalanceItemType = Undefined;
	If TypeOf(CalculationRule.Receiver) = Type("CatalogRef.BudgetBalanceItems") Then
		QueryTemplate = StrReplace(QueryTemplate, "AS Catalog.BudgetFlowItems", "AS Catalog.BudgetBalanceItems"); // @query-part
		BudgetBalanceItemType = Common.ObjectAttributeValue(CalculationRule.Receiver, "IndicatorType");
		If BudgetBalanceItemType = Enums.BudgetBalanceItemType.Estimated_ Then
			QueryTemplate = StrReplace(QueryTemplate, "AS BudgetFlowItem,", "AS BudgetBalanceItem," + Chars.LF
				+ Chars.Tab + "AliasOfSourceTable.BudgetFlowItem AS BudgetFlowItem,"); // @query-part
		EndIf;
	EndIf;
	QueryTemplate = StrReplace(QueryTemplate, "AS AliasOfSourceTable", "AS AliasOfSourceTable"
		+ Chars.LF + Chars.Tab + "&TextOfConnections"); // @query-part
	
	If Not RegisterParameters.Resources.Property("Count") Then
		QueryTemplate = StrReplace(QueryTemplate, "AliasOfSourceTable.CountTurnover", "0");
	EndIf;
	
	QueriesTexts = New Array;
	QueryTextsTemporaryTables = New Array;
	QueryTextsOfDistributionDatabase = RequestForSettings.QueryTextsOfDistributionDatabase;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	MaximumIterationNumber = 0;
	ReceiverAnalystNumbersByIterationNumbers = MatchingOfAllSourceNumbersOfReceiverAnalyticsToIterationNumbers(
		CalculationRule);
	AnalystNumbersByIterationNumbers = MatchingNumbersOfReceiverAnalystProfileToIterationNumbers(CalculationRule);
	InitialNumbersOfAnalystByIterationNumbers = MatchingSourceNumbersOfReceiverAnalystProfileToIterationNumbers(
		CalculationRule);
	
	RequestForSettings.RuleID = HashSettingsCalculationRules(CalculationRule);
	If ValueIsFilled(CalculationRule.Source) Then
		SourceIdentificator = StrReplace(CalculationRule.Source.UUID(), "-", "");
		NameOfSourceParameter = StringFunctionsClientServer.SubstituteParametersToString(?(TypeOf(CalculationRule.Source)
			= Type("CatalogRef.BudgetFlowItems"), "BudgetFlowItem_%1", "BudgetBalanceItem_%1"), SourceIdentificator);
	Else
		SourceIdentificator = Common.EnumerationValueName(CalculationRule.SourceType);
		NameOfSourceParameter = StringFunctionsClientServer.SubstituteParametersToString("SourceType_%1",
			SourceIdentificator);
	EndIf;
	ReceiverId = StrReplace(CalculationRule.Receiver.UUID(), "-", "");
	NameOfReceiverParameter = StringFunctionsClientServer.SubstituteParametersToString(?(TypeOf(CalculationRule.Receiver)
		= Type("CatalogRef.BudgetFlowItems"), "BudgetFlowItem_%1", "BudgetBalanceItem_%1"), ReceiverId);
	
	TableOfPartnersCounterpartiesIsRequired = Not GetFunctionalOption("UsePartnersAndCounterparties")
		And RegisterParameters.Dimensions.Property("Partner");
	
	ThereIsPeriodOffset = (CalculationRule.DataCalculationSettings.FindRows(New Structure(
		"PeriodOffsetSettingOption", Enums.PeriodOffsetSettingOptions.EmptyRef())).Count()
		< CalculationRule.DataCalculationSettings.Count());
	
	For Each SettingRow In CalculationRule.DataCalculationSettings Do
		
		DataCompositionSettings = SettingRow.SettingsComposer.Get();
		DataCompositionServer.InitializeSettingsComposer(SettingsComposer, DataCompositionSchema,
			DataCompositionSettings);
		DataCompositionSettings = SettingsComposer.GetSettings();

		DataForRequest = DataSourcesServer.DataForRequestToSourceByDataCalculationSettings(CalculationRule,
			DataCompositionSettings, SettingRow.ExpressionOffsetPeriod);
		
		If ValueIsFilled(CalculationRule.Source) Then
			SourceAnalyticsExpression = "AliasOfSourceTable.Dimension%1 AS Dimension%1Source1"; // @query-part
		Else
			SourceAnalyticsExpression = "UNDEFINED AS Dimension%1Source1"; // @query-part
		EndIf;
		ArrayOfSourceAnalystFields = New Array;
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			ArrayOfSourceAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
				SourceAnalyticsExpression, DimensionNumber));
		EndDo;
		QueryText = StrReplace(QueryTemplate, "&TextOfSourceAnalystFields", StrConcat(
			ArrayOfSourceAnalystFields, "," + Chars.LF + Chars.Tab));
		QueryText = StrReplace(QueryText, "&TextOfDimensionsFields",
			DataForRequest.QueryTextFragments.TextOfDimensionsFields);
		QueryText = StrReplace(QueryText, "&TextOfConnections",
			DataForRequest.QueryTextFragments.TextOfConnections);
		QueryText = StrReplace(QueryText, "&ConditionText",
			DataForRequest.QueryTextFragments.ConditionText + ?(CalculationRule.RecordCalculationInPlanningDocuments,
			Chars.LF + Chars.Tab + StringFunctionsClientServer.SubstituteParametersToString(
			"AND AliasOfSourceTable.Recorder IN (&Recorders_%1)", SourceIdentificator), ""));
		QueryText = StrReplace(QueryText, "Source_Identifier", "Source_"
			+ RequestForSettings.RuleID);
		QueryText = StrReplace(QueryText, "Receiver_Identifier", "Receiver_"
			+ RequestForSettings.RuleID);
		If ValueIsFilled(CalculationRule.Source) Then
			DataForRequest.QueryOptions.Insert(NameOfSourceParameter, CalculationRule.Source);
		Else
			DataForRequest.QueryOptions.Insert(NameOfSourceParameter, CalculationRule.SourceType);
		EndIf;
		DataForRequest.QueryOptions.Insert(NameOfReceiverParameter, CalculationRule.Receiver);
		RequestForSettings.SourceIdentificator = NameOfSourceParameter;
		RequestForSettings.ReceiverId = NameOfReceiverParameter;
		QueryText = StrReplace(QueryText, "&LineNumber", SettingRow.LineNumber);
		RowID = StringFunctionsClientServer.SubstituteParametersToString("%1_String%2",
			RequestForSettings.RuleID, Format(SettingRow.LineNumber, "NG=0"));
		CommonClientServer.SupplementStructure(RequestForSettings.QueryOptions,
			DataForRequest.QueryOptions, False);
		
		QuantitativeAccountingOnly
			= Enums.DataSourceTypesForBudgeting.OnlyQuantitativeAccountingBySourceType(
			CalculationRule.SourceType);
		If Not QuantitativeAccountingOnly Then
			ResourceName = Common.EnumerationValueName(SettingRow.AmountSource);
		EndIf;
		If Not RegisterParameters.Resources.Property("SumMan") Then
			QueryText = StrReplace(QueryText, "AliasOfSourceTable.SumManTurnover", ?(QuantitativeAccountingOnly,
				"0", StringFunctionsClientServer.SubstituteParametersToString("AliasOfSourceTable.%1Turnover", ResourceName)));
		EndIf;
		If Not RegisterParameters.Resources.Property("SumCompl") Then
			QueryText = StrReplace(QueryText, "AliasOfSourceTable.SumComplTurnover", ?(QuantitativeAccountingOnly,
				"0", StringFunctionsClientServer.SubstituteParametersToString("AliasOfSourceTable.%1Turnover", ResourceName)));
		EndIf;
		If Not RegisterParameters.Resources.Property("ScenarioAmount") Then
			QueryText = StrReplace(QueryText, "AliasOfSourceTable.ScenarioAmountTurnover", ?(QuantitativeAccountingOnly,
				"0", StringFunctionsClientServer.SubstituteParametersToString("AliasOfSourceTable.%1Turnover", ResourceName)));
		EndIf;
		If Not RegisterParameters.Resources.Property("AmountInCurrency") Then
			QueryText = StrReplace(QueryText, "AliasOfSourceTable.AmountInCurrencyTurnover", ?(QuantitativeAccountingOnly,
				"0", StringFunctionsClientServer.SubstituteParametersToString("AliasOfSourceTable.%1Turnover", ResourceName)));
		EndIf;
		
		If ValueIsFilled(SettingRow.ZoomRatio) Then
			QueryText = StrReplace(QueryText, "&ZoomRatio",
				FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(SettingRow.ZoomRatio));
		Else
			QueryText = StrReplace(QueryText, "&ZoomRatio", "1");
		EndIf;
		
		QueryText = StrReplace(QueryText, "&ReverseSign", ?(SettingRow.ReverseSign And BudgetBalanceItemType
			<> Enums.BudgetBalanceItemType.Estimated_, "-1", "1"));
		QueryText = StrReplace(QueryText, "&Expense", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
			SettingRow.ReverseSign));
		
		If CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
			QueryText = StrReplace(QueryText, "&ResourceConditions", "TRUE");
		ElsIf CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansCustomers
			Or CalculationRule.SourceType
			= Enums.DataSourceTypesForBudgeting.CashFlowPlansVendors Then
			QueryText = StrReplace(QueryText, "&ResourceConditions", "AliasOfSourceTable.SumTurnover <> 0");
		Else
			QueryText = StrReplace(QueryText, "&ResourceConditions",
				"AliasOfSourceTable.CountTurnover <> 0");
		EndIf;
		
		If TableOfPartnersCounterpartiesIsRequired And StrFind(QueryText, "AliasOfSourceTable.Counterparty") > 0 Then
			
			AddQueryTextTableOfPartnerCounterparties(RequestForSettings.QueryTextPartnersCounterparties,
				ThereIsPeriodOffset, CalculationRule.RecordCalculationInPlanningDocuments);
			
			QueryText = StrReplace(QueryText, "AliasOfSourceTable.Counterparty", "TTPartnersCounterparties.Counterparty");
			
			QueryText = StrReplace(QueryText, "AS AliasOfSourceTable", "AS AliasOfSourceTable
			|		LEFT JOIN TTPartnersCounterparties AS TTPartnersCounterparties
			|		ON AliasOfSourceTable.Partner = TTPartnersCounterparties.Partner"); // @query-part
			
		EndIf;
		
		If SettingRow.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.OnSchedule Then
			
			QueryText = StrReplace(QueryText, "&ExpressionStartOfPeriod", "&DateEmpty");
			QueryText = StrReplace(QueryText, "&ExpressionEndOfPeriod", "&UpdateDate");
			QueryText = StrReplace(QueryText, "&ParametersOfPlanningPeriod", "TRUE");
			QueryText = StrReplace(QueryText, "&ConditionsOfPlanningPeriod", "TRUE");
			
		Else
			
			If IsBlankString(SettingRow.ExpressionOffsetPeriod) Or StrFind(
				DataForRequest.QueryTextFragments.ExpressionOffsetPeriod,
				SettingRow.ExpressionOffsetPeriod) > 0 Then
				If CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
					QueryText = StrReplace(QueryText, "&ExpressionStartOfPeriod", "&DateEmpty");
					QueryText = StrReplace(QueryText, "&ExpressionEndOfPeriod", "&UpdateDate");
					QueryText = StrReplace(QueryText, "&ParametersOfPlanningPeriod",
						"PlanningPeriod BETWEEN &ExpressionStartOfPeriod AND &ExpressionEndOfPeriod");
				Else
					QueryText = StrReplace(QueryText, "&ParametersOfPlanningPeriod", "TRUE");
				EndIf;
				QueryText = StrReplace(QueryText, "&ConditionsOfPlanningPeriod", "TRUE");
				If Not IsBlankString(SettingRow.ExpressionOffsetPeriod) Then
					DataForRequest.QueryTextFragments.ExpressionOffsetPeriod = SettingRow.ExpressionOffsetPeriod;
				EndIf;
			Else
				QueryText = StrReplace(QueryText, "&ParametersOfPlanningPeriod", "TRUE");
				If CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
					QueryText = StrReplace(QueryText, "&ExpressionStartOfPeriod", "&DateEmpty");
					QueryText = StrReplace(QueryText, "&ExpressionEndOfPeriod", "&UpdateDate");
					QueryText = StrReplace(QueryText, "&ConditionsOfPlanningPeriod",
						"&PlanningPeriodField BETWEEN &ExpressionStartOfPeriod AND &ExpressionEndOfPeriod");
				Else
					QueryText = StrReplace(QueryText, "&ConditionsOfPlanningPeriod", "TRUE");
				EndIf;
			EndIf;
			If ValueIsFilled(SettingRow.PeriodOffsetSettingOption) Then
				If SettingRow.PeriodOffsetSettingOption
					= Enums.PeriodOffsetSettingOptions.FromDimension Then
					PeriodOfShift = StringFunctionsClientServer.SubstituteParametersToString(
						"ISNULL(AliasOfSourceTable.%1, 0)",
					DataForRequest.QueryTextFragments.ExpressionOffsetPeriod);
				Else
					PeriodOfShift = SettingRow.PeriodOfShift;
				EndIf;
				ExpressionPeriod = StringFunctionsClientServer.SubstituteParametersToString(
					"DATEADD(&PlanningPeriodField, %1, %2%3)",
					FinancialReportingClientServerCached.PeriodicityByString(SettingRow.OffsetFrequency),
					Format(SettingRow.OffsetForward, "BF=; BT=-"), PeriodOfShift); //@ query-part
				ExpressionStartOfPeriod = StringFunctionsClientServer.SubstituteParametersToString(
					"DATEADD(&BeginOfPeriod, %1, %2%3)",
					FinancialReportingClientServerCached.PeriodicityByString(SettingRow.OffsetFrequency),
					Format(SettingRow.OffsetForward, "BF=-; BT="), PeriodOfShift); //@ query-part
				ExpressionEndOfPeriod = StringFunctionsClientServer.SubstituteParametersToString(
					"DATEADD(ENDOFPERIOD(&EndOfPeriod, %1), %1, %2%3)",
					FinancialReportingClientServerCached.PeriodicityByString(SettingRow.OffsetFrequency),
					Format(SettingRow.OffsetForward, "BF=-; BT="), PeriodOfShift); //@ query-part
				QueryText = StrReplace(QueryText, "&PlanningPeriodField AS PlanningPeriod", ExpressionPeriod
					+ " AS PlanningPeriod"); // @query-part
				QueryText = StrReplace(QueryText, "&ExpressionStartOfPeriod", ExpressionStartOfPeriod);
				QueryText = StrReplace(QueryText, "&ExpressionEndOfPeriod", ExpressionEndOfPeriod);
			ElsIf BudgetBalanceItemType <> Enums.BudgetBalanceItemType.Estimated_ Then
				QueryText = StrReplace(QueryText, "&ExpressionStartOfPeriod", "&BeginOfPeriod");
				QueryText = StrReplace(QueryText, "&ExpressionEndOfPeriod", "ENDOFPERIOD(&EndOfPeriod, DAY)"); //@ query-part
			EndIf;
			
		EndIf;
		
		QueryText = StrReplace(QueryText, "&PlanningPeriodField",
			StringFunctionsClientServer.SubstituteParametersToString("AliasOfSourceTable.%1", PlanningPeriodField));
		
		If CalculationRule.DataCalculationSettings.IndexOf(SettingRow) = 0 Then
		
			AddQueryTextsOfDistributionDatabaseToGetAnalytics(QueryTextsOfDistributionDatabase,
				RequestForSettings.QueryOptions, CalculationRule, MaximumIterationNumber);
		
		EndIf;
		
		UseForecastExchangeRates
			= SettingRow.AmountSource = Enums.IndicatorsOfAnalyticalRegisters.Count
			And CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers
			Or CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.SalesPlans
			Or CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.PurchasePlans
			Or CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansCustomers
			Or CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansVendors;
		
		UsePreliminaryData = ValueIsFilled(SettingRow.NFIFactor)
			Or UseForecastExchangeRates
			Or ValueIsFilled(SettingRow.AllocationProfile)
			Or MaximumIterationNumber > 0
			Or SettingRow.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.OnSchedule;
		If UsePreliminaryData And BudgetBalanceItemType = Enums.BudgetBalanceItemType.Estimated_ Then
			ErrorText = NStr("vi = 'Sai tùy chỉnh quy tắc để tính toán chỉ tiêu theo %1 nguồn%2.';
							|ru = 'Некорректные настройки правила для расчета показателя %1 по источнику %2.';
							|en = 'Incorrect settings of the rule for calculating the %1 indicator by the %2 source.'; fa = 'Incorrect settings of the rule for calculating the %1 indicator by the %2 source.';
							|it = 'Incorrect settings of the rule for calculating the %1 indicator by the %2 source.';
							|pl = 'Incorrect settings of the rule for calculating the %1 indicator by the %2 source.';
							|tr = '%2 kaynağına dayalı olarak %1 göstergesinin hesaplanmasına ilişkin kuralın yanlış ayarları.'");
			Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorText, CalculationRule.Receiver,
				CalculationRule.Source);
		EndIf;
		If UsePreliminaryData Then
			If CalculationRule.SourceType <> Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
				Array_DimensionFields = New Array;
				For Each Dimension In RegisterParameters.Dimensions Do
					If Dimension.Key = "Organization" Or Dimension.Key = "Department" Or Dimension.Key = "Scenario"
						Or Dimension.Key = "Status" Then
						Continue;
					EndIf;
					Array_DimensionFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
						"AliasOfSourceTable.%1 AS %1", Dimension.Key));
				EndDo;
				QueryText = StrReplace(QueryText, "&TextOfMeasurementFields", StrConcat(Array_DimensionFields, ","
					+ Chars.LF + Chars.Tab));
			Else
				QueryText = StrReplace(QueryText, "&TextOfMeasurementFields,", "");
			EndIf;
			QueryText = StrReplace(QueryText, "INTO Data",
				StringFunctionsClientServer.SubstituteParametersToString("INTO PreliminaryData_%1",
				RowID)); // @query-part
			QueryTextsTemporaryTables.Add(QueryText);
		Else
			QueryText = StrReplace(QueryText, "&TextOfMeasurementFields,", "");
			If QueriesTexts.Count() > 0 Then
				QueryText = StrReplace(QueryText, "INTO Data", ""); // @query-part
			EndIf;
		EndIf;

		If ValueIsFilled(SettingRow.NFIFactor) Then
			AddQueryTextConversionFactorsForNFP(QueryTextsOfDistributionDatabase, SettingRow,
				RequestForSettings.QueryOptions);
		EndIf;
		
		If UseForecastExchangeRates Then
			AddQueryTextForecastExchangeRates(RequestForSettings.QueryTextForecastExchangeRates,
				RequestForSettings.QueryOptions, ThereIsPeriodOffset, CalculationRule.RecordCalculationInPlanningDocuments);
		EndIf;
		
		NameOfTemporaryTableForSettingPeriodOffset = "";
		NumberOfTypeOfAnalytics = "";
		If SettingRow.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.OnSchedule Then
			AddQueryTextsForSettingOffsetOfDCSPeriod(NameOfTemporaryTableForSettingPeriodOffset, NumberOfTypeOfAnalytics,
				QueryTextsOfDistributionDatabase, SettingRow, CalculationRule);
		EndIf;

		If ValueIsFilled(SettingRow.AllocationProfile) Then
			AddQueryTextsToDistributionDatabaseByPeriod(QueryTextsOfDistributionDatabase, SettingRow,
				RequestForSettings.QueryOptions);
		EndIf;
		
		If UsePreliminaryData Then
		
			QueryText = 
			"SELECT
			|	PreliminaryData.BudgetFlowItem AS BudgetFlowItem,
			|	PreliminaryData.DayPeriod AS DayPeriod,
			|	PreliminaryData.PlanningPeriod AS PlanningPeriod,
			|	PreliminaryData.Recorder AS Recorder,
			|	PreliminaryData.Scenario AS Scenario,
			|	PreliminaryData.Status AS Status,
			|	PreliminaryData.Organization AS Organization,
			|	PreliminaryData.Department AS Department,
			|	PreliminaryData.Currency AS Currency,
			|	&TextOfDimensionsFields,
			|	&TextOfSourceAnalystFields,
			|	PreliminaryData.CountTurnover AS CountTurnover,
			|	PreliminaryData.SumManTurnover * &NFIFactor * &ConversionToManSCurrency AS SumManTurnover,
			|	PreliminaryData.ScenarioAmountTurnover * &NFIFactor AS ScenarioAmountTurnover,
			|	PreliminaryData.SumComplTurnover * &NFIFactor * &ConversionToLocalCurrency AS SumComplTurnover,
			|	PreliminaryData.AmountInCurrencyTurnover * &NFIFactor * &RecalculationToCurrency AS AmountInCurrencyTurnover,
			|	PreliminaryData.CalculationRule AS CalculationRule,
			|	PreliminaryData.Expense AS Expense
			|INTO Data
			|FROM
			|	PreliminaryData AS PreliminaryData";
			If BudgetBalanceItemType = Enums.BudgetBalanceItemType.Estimated_ Then
				QueryText = StrReplace(QueryText, "AS BudgetFlowItem,", "AS BudgetFlowItem," + Chars.LF + Chars.Tab
					+ "PreliminaryData.BudgetBalanceItem AS BudgetBalanceItem,"); // @query-part
			EndIf;
			ArrayOfAnalystFields = New Array;
			ArrayOfSourceAnalystFields = New Array;
			For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
				ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
					"PreliminaryData.Dimension%1 AS Dimension%1", DimensionNumber));
				ArrayOfSourceAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
					"PreliminaryData.Dimension%1Source1 AS Dimension%1Source1", DimensionNumber));
			EndDo;
			QueryText = StrReplace(QueryText, "&TextOfSourceAnalystFields", StrConcat(ArrayOfSourceAnalystFields, ","
				+ Chars.LF + Chars.Tab));
			QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", StrConcat(ArrayOfAnalystFields, ","
				+ Chars.LF + Chars.Tab));
			
			If ValueIsFilled(SettingRow.NFIFactor) Then
				QueryText = StrReplace(QueryText, "&NFIFactor", "ISNULL(NFPCoefficients.IndicatorValue, &DefaultCoefficient)");
				QueryText = QueryText + "
				|		LEFT JOIN NFPCoefficients AS NFPCoefficients
				|		ON &ConditionsForOrganizations
				|			AND &ConditionByDivision
				|			AND &ScenarioConditions
				|			AND &ConditionByCurrency"; //@ query-part
				
				NFPID = StrReplace(SettingRow.NFIFactor.UUID(), "-", "");
				NFPDetails = Common.ObjectAttributesValues(SettingRow.NFIFactor,
					"ByCompanies, ByBusinessUnits, ByScenarios, IndicatorKind");
				If NFPDetails.ByCompanies Then
					QueryText = StrReplace(QueryText, "&ConditionsForOrganizations",
						"PreliminaryData.Organization = NFPCoefficients.Organization");
				Else
					QueryText = StrReplace(QueryText, "&ConditionsForOrganizations",
						"NFPCoefficients.Organization = VALUE(Catalog.Companies.EmptyRef)"); //@ query-part
				EndIf;
				If NFPDetails.ByBusinessUnits Then
					QueryText = StrReplace(QueryText, "&ConditionByDivision",
						"PreliminaryData.Department = NFPCoefficients.Department");
				Else
					QueryText = StrReplace(QueryText, "&ConditionByDivision",
						"NFPCoefficients.Department = VALUE(Catalog.BusinessStructure.EmptyRef)"); //@ query-part
				EndIf;
				If NFPDetails.ByScenarios Then
					QueryText = StrReplace(QueryText, "&ScenarioConditions",
						"PreliminaryData.Scenario = NFPCoefficients.Scenario");
				Else
					QueryText = StrReplace(QueryText, "&ScenarioConditions",
						"NFPCoefficients.Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef)"); //@ query-part
				EndIf;
				If NFPDetails.IndicatorKind = Enums.NonFinancialItemKinds.Cash_ Then
					QueryText = StrReplace(QueryText, "&ConditionByCurrency",
						"PreliminaryData.Scenario.Currency = NFPCoefficients.Currency");
					QueryText = StrReplace(QueryText, "&DefaultCoefficient", "0");
				Else
					QueryText = StrReplace(QueryText, "&ConditionByCurrency", "TRUE");
					QueryText = StrReplace(QueryText, "&DefaultCoefficient", "1");
				EndIf;
				If SettingRow.AmountSource = Enums.IndicatorsOfAnalyticalRegisters.Count Then
					SourceResources = New Array;
					SourceResources.Add("PreliminaryData.SumManTurnover");
					SourceResources.Add("PreliminaryData.ScenarioAmountTurnover");
					SourceResources.Add("PreliminaryData.SumComplTurnover");
					SourceResources.Add("PreliminaryData.AmountInCurrencyTurnover");
					For Each Resource In SourceResources Do
						QueryText = StrReplace(QueryText, Resource, "PreliminaryData.CountTurnover");
					EndDo;
				EndIf;

				If ValueIsFilled(CalculationRule.Source) Then
					ComplianceAnalyst = BudgetingCached.ComplianceOfAnalystWithItemIndicatorOfSNFPBudgets(
						CalculationRule.Source, SettingRow.NFIFactor);
					ConnectionConditionTemplate = "AND PreliminaryData.Dimension%1Source1 = NFPCoefficients.Dimension%2"; // @query-part
				Else
					ComplianceAnalyst = BudgetingCached.ComplianceOfArticleAnalystWithNFPSIndicatorWithTypeOfPlanningSource(
						CalculationRule.SourceType, SettingRow.NFIFactor);
					ConnectionConditionTemplate = "AND %1 = NFPCoefficients.Dimension%2"; // @query-part
				EndIf;
				If TypeOf(ComplianceAnalyst) = Type("Map") And ComplianceAnalyst.Count() > 0 Then
					ArrayOfConnectionConditions = New Array;
					For Each KeyAndValue In ComplianceAnalyst Do
						ArrayOfConnectionConditions.Add(StringFunctionsClientServer.SubstituteParametersToString(ConnectionConditionTemplate,
							StrReplace(KeyAndValue.Value, "TableName", "PreliminaryData"), KeyAndValue.Key));
					EndDo;
					QueryText = QueryText + Chars.LF + Chars.Tab + StrConcat(ArrayOfConnectionConditions, Chars.LF + Chars.Tab);
				EndIf;

				QueryText = StrReplace(QueryText, "NFPCoefficients",
					StringFunctionsClientServer.SubstituteParametersToString("NFPCoefficients_%1", NFPID));
			Else
				QueryText = StrReplace(QueryText, "&NFIFactor", "1");
			EndIf;
			
			If UseForecastExchangeRates Then
				
				AddQueryTextsForecastExchangeRatesByPeriod(QueryTextsTemporaryTables, RowID);
				
				QueryText = StrReplace(QueryText, "&ConversionToManSCurrency",
					"CAST(ISNULL(ForecastExchangeRatesOfScenario.Rate, 1) AS NUMBER(15,3)) / CAST(ISNULL(ForecastExchangeRatesOfMen.Rate, 1) AS NUMBER(15,3))");
				QueryText = StrReplace(QueryText, "&ConversionToLocalCurrency",
					"CAST(ISNULL(ForecastExchangeRatesOfScenario.Rate, 1) AS NUMBER(15,3)) / CAST(ISNULL(ForecastLocalCurrencyExchangeRates.Rate, 1) AS NUMBER(15,3))");
				QueryText = StrReplace(QueryText, "&RecalculationToCurrency",
					"CAST(ISNULL(ForecastExchangeRatesOfScenario.Rate, 1) AS NUMBER(15,3)) / CAST(ISNULL(ForecastDocumentCurrencyRates.Rate, 1) AS NUMBER(15,3))");
				
				QueryText = QueryText + "
				|		LEFT JOIN TT_ForecastExchangeRates AS ForecastExchangeRatesOfScenario
				|		ON PreliminaryData.Scenario = ForecastExchangeRatesOfScenario.Scenario
				|			AND PreliminaryData.Scenario.Currency = ForecastExchangeRatesOfScenario.Currency
				|			AND PreliminaryData.PlanningPeriod = ForecastExchangeRatesOfScenario.PlanningPeriod
				|		LEFT JOIN TT_ForecastExchangeRates AS ForecastDocumentCurrencyRates
				|		ON PreliminaryData.Scenario = ForecastDocumentCurrencyRates.Scenario
				|			AND PreliminaryData.Currency = ForecastDocumentCurrencyRates.Currency
				|			AND PreliminaryData.PlanningPeriod = ForecastDocumentCurrencyRates.PlanningPeriod
				|		LEFT JOIN TT_ForecastExchangeRates AS ForecastExchangeRatesOfMen
				|		ON PreliminaryData.Scenario = ForecastExchangeRatesOfMen.Scenario
				|			AND (ForecastExchangeRatesOfMen.Currency = &ManagementAccountingCurrency)
				|			AND PreliminaryData.PlanningPeriod = ForecastExchangeRatesOfMen.PlanningPeriod
				|		LEFT JOIN TT_ForecastExchangeRates AS ForecastLocalCurrencyExchangeRates
				|		ON PreliminaryData.Scenario = ForecastLocalCurrencyExchangeRates.Scenario
				|			AND (ForecastLocalCurrencyExchangeRates.Currency = &LocalAccountingCurrency)
				|			AND PreliminaryData.PlanningPeriod = ForecastLocalCurrencyExchangeRates.PlanningPeriod"; //@ query-part
				
				QueryText = StrReplace(QueryText, "TT_ForecastExchangeRates",
					StringFunctionsClientServer.SubstituteParametersToString("TTForecastExchangeRates_%1", RowID));
				QueryText = StrReplace(QueryText, "ForecastExchangeRatesOfScenario",
					StringFunctionsClientServer.SubstituteParametersToString("ForecastExchangeRatesOfScenario_%1", RowID));
				QueryText = StrReplace(QueryText, "ForecastDocumentCurrencyRates",
					StringFunctionsClientServer.SubstituteParametersToString("ForecastDocumentCurrencyRates_%1", RowID));
				QueryText = StrReplace(QueryText, "ForecastExchangeRatesOfMen",
					StringFunctionsClientServer.SubstituteParametersToString("ForecastExchangeRatesOfMen_%1", RowID));
				QueryText = StrReplace(QueryText, "ForecastLocalCurrencyExchangeRates",
					StringFunctionsClientServer.SubstituteParametersToString("ForecastLocalCurrencyExchangeRates_%1", RowID));
				
			Else
				
				QueryText = StrReplace(QueryText, "&ConversionToManSCurrency", "1");
				QueryText = StrReplace(QueryText, "&ConversionToLocalCurrency", "1");
				QueryText = StrReplace(QueryText, "&RecalculationToCurrency", "1");
				
			EndIf;
			
			If SettingRow.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.OnSchedule Then
				
				ConnectionPattern = "
					|		LEFT JOIN PeriodOffsetSettings_Coefficients AS PeriodOffsetSettings_Coefficients
					|		ON PreliminaryData.Dimension%1Source1 = PeriodOffsetSettings_Coefficients.DimensionValue
					|		LEFT JOIN  PeriodOffsetSettings_Amount AS  PeriodOffsetSettings_Amount
					|		ON PreliminaryData.Dimension%1Source1 = PeriodOffsetSettings_Amount.DimensionValue"; //@ query-part
				If CalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
					QueryText = QueryText + StringFunctionsClientServer.SubstituteParametersToString(ConnectionPattern,
						NumberOfTypeOfAnalytics);
				Else
					QueryText = QueryText + StrReplace(ConnectionPattern, "Dimension%1Source1", NumberOfTypeOfAnalytics);
				EndIf;
				
				SourceResources = New Array;
				SourceResources.Add("PreliminaryData.CountTurnover");
				SourceResources.Add("PreliminaryData.SumManTurnover");
				SourceResources.Add("PreliminaryData.ScenarioAmountTurnover");
				SourceResources.Add("PreliminaryData.SumComplTurnover");
				SourceResources.Add("PreliminaryData.AmountInCurrencyTurnover");
				For Each Resource In SourceResources Do
					QueryText = StrReplace(QueryText, Resource, TMCommonUse.AmountDistributionText(Resource,
						"ISNULL(PeriodOffsetSettings_Coefficients.ZoomRatio, 0)",
						"ISNULL(PeriodOffsetSettings_Coefficients.AccumulatedCoefficient, 0)",
						"ISNULL(PeriodOffsetSettings_Amount.TotalCoefficient, 0)")); //@ query-part
				EndDo;
			
			EndIf;
			
			If ValueIsFilled(SettingRow.AllocationProfile) Then
				
				QueryText = QueryText + "
				|		LEFT JOIN DistributionBase_Coefficients AS DistributionBase_Coefficients
				|		ON &ConditionsForOrganizations
				|			AND &ConditionByDivision
				|			AND &ScenarioConditions
				|			AND &ConditionForConnectingAnalystCoefficientsFields
				|		LEFT JOIN DistributionBase_Amount AS DistributionBase_Amount
				|		ON &ConditionsForOrganizations
				|			AND &ConditionByDivision
				|			AND &ScenarioConditions
				|			AND &ConditionForJoiningAnalystSumFields"; //@ query-part
				
				NFPID = StrReplace(SettingRow.AllocationProfile.UUID(), "-", "");
				NFPDetails = Common.ObjectAttributesValues(SettingRow.AllocationProfile,
					"ByCompanies, ByBusinessUnits, ByScenarios, Periodicity, SubperiodFrequency");
				If NFPDetails.ByCompanies Then
					QueryText = StrReplace(QueryText, "&ConditionsForOrganizations",
						"PreliminaryData.Organization = DistributionBase_Coefficients.Organization");
				Else
					QueryText = StrReplace(QueryText, "&ConditionsForOrganizations",
						"DistributionBase_Coefficients.Organization = VALUE(Catalog.Companies.EmptyRef)"); //@ query-part
				EndIf;
				If NFPDetails.ByBusinessUnits Then
					QueryText = StrReplace(QueryText, "&ConditionByDivision",
						"PreliminaryData.Department = DistributionBase_Coefficients.Department");
				Else
					QueryText = StrReplace(QueryText, "&ConditionByDivision",
						"DistributionBase_Coefficients.Department = VALUE(Catalog.BusinessStructure.EmptyRef)"); //@ query-part
				EndIf;
				If NFPDetails.ByScenarios Then
					QueryText = StrReplace(QueryText, "&ScenarioConditions",
						"PreliminaryData.Scenario = DistributionBase_Coefficients.Scenario");
				Else
					QueryText = StrReplace(QueryText, "&ScenarioConditions",
						"DistributionBase_Coefficients.Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef)"); //@ query-part
				EndIf;
				
				SourceResources = New Array;
				SourceResources.Add("PreliminaryData.CountTurnover");
				SourceResources.Add("PreliminaryData.SumManTurnover");
				SourceResources.Add("PreliminaryData.ScenarioAmountTurnover");
				SourceResources.Add("PreliminaryData.SumComplTurnover");
				SourceResources.Add("PreliminaryData.AmountInCurrencyTurnover");
				For Each Resource In SourceResources Do
					QueryText = StrReplace(QueryText, Resource, TMCommonUse.AmountDistributionText(Resource,
						"ISNULL(DistributionBase_Coefficients.ZoomRatio, 0)",
						"ISNULL(DistributionBase_Coefficients.AccumulatedCoefficient, 0)",
						"ISNULL(DistributionBase_Amount.TotalCoefficient, 0)"));
				EndDo;
				
				If ValueIsFilled(CalculationRule.Source) Then
					ComplianceAnalyst = BudgetingCached.ComplianceOfAnalystWithItemIndicatorOfSNFPBudgets(
						CalculationRule.Source, SettingRow.AllocationProfile);
					TemplateConnectionConditionsCoefficients = "PreliminaryData.Dimension%1Source1 = DistributionBase_Coefficients.Dimension%2";
					TemplateForSumConnectionCondition = "PreliminaryData.Dimension%1Source1 = DistributionBase_Amount.Dimension%2";
				Else
					ComplianceAnalyst = BudgetingCached.ComplianceOfArticleAnalystWithNFPSIndicatorWithTypeOfPlanningSource(
						CalculationRule.SourceType, SettingRow.AllocationProfile);
					TemplateConnectionConditionsCoefficients = "%1 = DistributionBase_Coefficients.Dimension%2";
					TemplateForSumConnectionCondition = "%1 = DistributionBase_Amount.Dimension%2";
				EndIf;
					
				If TypeOf(ComplianceAnalyst) = Type("Map") And ComplianceAnalyst.Count() > 0 Then
					ArrayOfConnectionConditionsCoefficients = New Array;
					ArrayOfConnectionConditionsSum = New Array;
					For Each KeyAndValue In ComplianceAnalyst Do
						ArrayOfConnectionConditionsCoefficients.Add(StringFunctionsClientServer.SubstituteParametersToString(
							TemplateConnectionConditionsCoefficients,
							StrReplace(KeyAndValue.Value, "TableName", "PreliminaryData"), KeyAndValue.Key));
						ArrayOfConnectionConditionsSum.Add(StringFunctionsClientServer.SubstituteParametersToString(
							TemplateForSumConnectionCondition,
							StrReplace(KeyAndValue.Value, "TableName", "PreliminaryData"), KeyAndValue.Key));
					EndDo;
					ConditionForConnectingAnalystCoefficientsFields = StrConcat(ArrayOfConnectionConditionsCoefficients,
						Chars.LF + Chars.Tab + "And ");
					ConditionForJoiningAnalystSumFields = StrConcat(ArrayOfConnectionConditionsSum, Chars.LF
						+ Chars.Tab + "And ");
					QueryText = StrReplace(QueryText, "&ConditionForConnectingAnalystCoefficientsFields", ?(
						IsBlankString(ConditionForConnectingAnalystCoefficientsFields), "TRUE",
						ConditionForConnectingAnalystCoefficientsFields));
					QueryText = StrReplace(QueryText, "&ConditionForJoiningAnalystSumFields", ?(IsBlankString(
						ConditionForJoiningAnalystSumFields), "TRUE", ConditionForJoiningAnalystSumFields));
				Else
					QueryText = StrReplace(QueryText, "&ConditionForConnectingAnalystCoefficientsFields", "TRUE");
					QueryText = StrReplace(QueryText, "&ConditionForJoiningAnalystSumFields", "TRUE");
				EndIf;
				
				ExpressionPeriod = StringFunctionsClientServer.SubstituteParametersToString(
					"CASE
					|	WHEN DistributionBase_Coefficients.SubperiodNumber IS NULL
					|		OR DistributionBase_Coefficients.SubperiodNumber = 1
					|		THEN BEGINOFPERIOD(PreliminaryData.PlanningPeriod, %1)
					|	ELSE DATEADD(BEGINOFPERIOD(PreliminaryData.PlanningPeriod, %1), %2, DistributionBase_Coefficients.SubperiodNumber-1)
					|END AS PlanningPeriod",
					FinancialReportingClientServerCached.PeriodicityByString(NFPDetails.Periodicity),
					FinancialReportingClientServerCached.PeriodicityByString(NFPDetails.SubperiodFrequency));
				QueryText = StrReplace(QueryText, "PreliminaryData.PlanningPeriod AS PlanningPeriod", //@ query-part
					ExpressionPeriod);

				QueryText = StrReplace(QueryText, "AllocationBase",
					StringFunctionsClientServer.SubstituteParametersToString("AllocationBase_%1",
					NFPID));
				
			EndIf;
					
			If SettingRow.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.OnSchedule Then
				
				QueryText = QueryText + "
					|WHERE
					|	PreliminaryData.PlanningPeriod BETWEEN &ExpressionStartOfPeriod AND &ExpressionEndOfPeriod"; //@ query-part
				
				ExpressionTimeFenceCondition = "CASE PeriodOffsetSettings_Coefficients.OffsetFrequency
					|	WHEN VALUE(Enum.Periodicity.Day)
					|		THEN DATEADD(%1, DAY, CASE
					|			WHEN PeriodOffsetSettings_Coefficients.OffsetForward
					|				THEN %8PeriodOffsetSettings_Coefficients.PeriodOfShift
					|			ELSE %9PeriodOffsetSettings_Coefficients.PeriodOfShift
					|		END)
					|	WHEN VALUE(Enum.Periodicity.Week)
					|		THEN DATEADD(%2, WEEK, CASE
					|			WHEN PeriodOffsetSettings_Coefficients.OffsetForward
					|				THEN %8PeriodOffsetSettings_Coefficients.PeriodOfShift
					|			ELSE %9PeriodOffsetSettings_Coefficients.PeriodOfShift
					|		END)
					|	WHEN VALUE(Enum.Periodicity.TenDays)
					|		THEN DATEADD(%3, TENDAYS, CASE
					|			WHEN PeriodOffsetSettings_Coefficients.OffsetForward
					|				THEN %8PeriodOffsetSettings_Coefficients.PeriodOfShift
					|			ELSE %9PeriodOffsetSettings_Coefficients.PeriodOfShift
					|		END)
					|	WHEN VALUE(Enum.Periodicity.Month)
					|		THEN DATEADD(%4, MONTH, CASE
					|			WHEN PeriodOffsetSettings_Coefficients.OffsetForward
					|				THEN %8PeriodOffsetSettings_Coefficients.PeriodOfShift
					|			ELSE %9PeriodOffsetSettings_Coefficients.PeriodOfShift
					|		END)
					|	WHEN VALUE(Enum.Periodicity.Quarter)
					|		THEN DATEADD(%5, QUARTER, CASE
					|			WHEN PeriodOffsetSettings_Coefficients.OffsetForward
					|				THEN %8PeriodOffsetSettings_Coefficients.PeriodOfShift
					|			ELSE %9PeriodOffsetSettings_Coefficients.PeriodOfShift
					|		END)
					|	WHEN VALUE(Enum.Periodicity.HalfYear)
					|		THEN DATEADD(%6, HALFYEAR, CASE
					|			WHEN PeriodOffsetSettings_Coefficients.OffsetForward
					|				THEN %8PeriodOffsetSettings_Coefficients.PeriodOfShift
					|			ELSE %9PeriodOffsetSettings_Coefficients.PeriodOfShift
					|		END)
					|	ELSE DATEADD(%7, YEAR, CASE
					|			WHEN PeriodOffsetSettings_Coefficients.OffsetForward
					|				THEN %8PeriodOffsetSettings_Coefficients.PeriodOfShift
					|			ELSE %9PeriodOffsetSettings_Coefficients.PeriodOfShift
					|		END)
					|END"; // @query-part
				ExpressionPeriod = StringFunctionsClientServer.SubstituteParametersToString(ExpressionTimeFenceCondition,
					"PreliminaryData.PlanningPeriod", "PreliminaryData.PlanningPeriod",
					"PreliminaryData.PlanningPeriod", "PreliminaryData.PlanningPeriod",
					"PreliminaryData.PlanningPeriod", "PreliminaryData.PlanningPeriod",
					"PreliminaryData.PlanningPeriod", "", "-");
				ExpressionStartOfPeriod = StringFunctionsClientServer.SubstituteParametersToString(
					ExpressionTimeFenceCondition, "&BeginOfPeriod", "&BeginOfPeriod", "&BeginOfPeriod", "&BeginOfPeriod",
					"&BeginOfPeriod", "&BeginOfPeriod", "&BeginOfPeriod", "-", "");
				ExpressionEndOfPeriod = StringFunctionsClientServer.SubstituteParametersToString(
					ExpressionTimeFenceCondition, "ENDOFPERIOD(&EndOfPeriod, DAY)",
					"ENDOFPERIOD(&EndOfPeriod, WEEK)", "ENDOFPERIOD(&EndOfPeriod, TENDAYS)",
					"ENDOFPERIOD(&EndOfPeriod, MONTH)", "ENDOFPERIOD(&EndOfPeriod, QUARTER)",
					"ENDOFPERIOD(&EndOfPeriod, HALFYEAR)", "ENDOFPERIOD(&EndOfPeriod, YEAR)", "-", ""); //@ query-part
				If CalculationRule.RecordCalculationInPlanningDocuments Then
					ExpressionStartOfPeriod = StrReplace(ExpressionStartOfPeriod, "&BeginOfPeriod", "PreliminaryData.DayPeriod");
					ExpressionEndOfPeriod = StrReplace(ExpressionEndOfPeriod, "&EndOfPeriod", "PreliminaryData.DayPeriod");
				EndIf;
				QueryText = StrReplace(QueryText,
					"PreliminaryData.PlanningPeriod AS PlanningPeriod", ExpressionPeriod
					+ " AS PlanningPeriod"); // @query-part
				QueryText = StrReplace(QueryText, "&ExpressionStartOfPeriod", ExpressionStartOfPeriod);
				QueryText = StrReplace(QueryText, "&ExpressionEndOfPeriod", ExpressionEndOfPeriod);
				QueryText = StrReplace(QueryText, "PeriodOffsetSettings", NameOfTemporaryTableForSettingPeriodOffset);
				
			EndIf;
			
			QueryText = StrReplace(QueryText, "PreliminaryData",
				StringFunctionsClientServer.SubstituteParametersToString("PreliminaryData_%1",
				RowID));
			
			For IterationNumber = 1 To MaximumIterationNumber Do
				
				IdOfLineIteration = StringFunctionsClientServer.SubstituteParametersToString(
					"%1_Iteration%2String%3", RequestForSettings.RuleID, IterationNumber, Format(
					SettingRow.LineNumber, "NG=0"));

				If Not ValueIsFilled(SettingRow.NFIFactor)
					And Not UseForecastExchangeRates
					And Not ValueIsFilled(SettingRow.AllocationProfile)
					And SettingRow.PeriodOffsetSettingOption <> Enums.PeriodOffsetSettingOptions.OnSchedule
					And IterationNumber = 1 Then
					QueryText = QueryTextsTemporaryTables[QueryTextsTemporaryTables.UBound()];
					QueryText = StrReplace(QueryText,
						StringFunctionsClientServer.SubstituteParametersToString("INTO PreliminaryData_%1", RowID),
						StringFunctionsClientServer.SubstituteParametersToString("INTO IterationData_%1", IdOfLineIteration));
					QueryTextsTemporaryTables[QueryTextsTemporaryTables.UBound()] = QueryText;
				Else
					QueryText = StrReplace(QueryText, "INTO Data",
						StringFunctionsClientServer.SubstituteParametersToString("INTO IterationData_%1", //@ query-part
						IdOfLineIteration));
					QueryText = QueryText + "
						|
						|INDEX BY
						|	Organization,
						|	Department,
						|	Scenario"; //@ query-part
					QueryTextsTemporaryTables.Add(QueryText);
				EndIf;
				
				If IterationNumber = 1 Then
					
					If ValueIsFilled(SettingRow.NFIFactor)
						Or ValueIsFilled(SettingRow.AllocationProfile) Then
						
						FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(
							QueryTextsTemporaryTables, StringFunctionsClientServer.SubstituteParametersToString(
							"PreliminaryData_%1", RowID));
						
					EndIf;
					
				Else
					
					IdOfPreviousLineIteration = StringFunctionsClientServer.SubstituteParametersToString(
						"%1_Iteration%2String%3", RequestForSettings.RuleID, IterationNumber - 1, Format(
						SettingRow.LineNumber, "NG=0"));
				
					FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(
						QueryTextsTemporaryTables, StringFunctionsClientServer.SubstituteParametersToString(
						"IterationData_%1", IdOfPreviousLineIteration));
					
				EndIf;
				
				QueryText = 
				"SELECT
				|	IterationData.BudgetFlowItem AS BudgetFlowItem,
				|	IterationData.DayPeriod AS DayPeriod,
				|	IterationData.PlanningPeriod AS PlanningPeriod,
				|	IterationData.Recorder AS Recorder,
				|	IterationData.Scenario AS Scenario,
				|	IterationData.Status AS Status,
				|	IterationData.Organization AS Organization,
				|	IterationData.Department AS Department,
				|	IterationData.Currency AS Currency,
				|	&TextOfDimensionsFields,
				|	&TextOfSourceAnalystFields,
				|	IterationData.CountTurnover AS CountTurnover,
				|	IterationData.SumManTurnover AS SumManTurnover,
				|	IterationData.ScenarioAmountTurnover AS ScenarioAmountTurnover,
				|	IterationData.SumComplTurnover AS SumComplTurnover,
				|	IterationData.AmountInCurrencyTurnover AS AmountInCurrencyTurnover,
				|	IterationData.CalculationRule AS CalculationRule,
				|	IterationData.Expense AS Expense
				|INTO Data
				|FROM
				|	IterationData AS IterationData
				|		LEFT JOIN DistributionBase_Coefficients AS DistributionBase_Coefficients
				|		ON &ConditionsForOrganizations
				|			AND &ConditionByDivision
				|			AND &ScenarioConditions
				|			AND &ConditionForConnectingAnalystCoefficientsFields
				|		LEFT JOIN DistributionBase_Amount AS DistributionBase_Amount
				|		ON &ConditionsForOrganizations
				|			AND &ConditionByDivision
				|			AND &ScenarioConditions
				|			AND &ConditionForJoiningAnalystSumFields";
				
				DistributionProfileLine = CalculationRule.DimensionFillingSettings.Find(IterationNumber,
					"IterationNumber");
				AllocationProfile = DistributionProfileLine.AllocationProfile;
				RoundingPrecision = DistributionProfileLine.RoundingPrecision;
				
				NFPID = StrReplace(AllocationProfile.UUID(), "-", "");
				NFPDetails = Common.ObjectAttributesValues(AllocationProfile,
					"ByCompanies, ByBusinessUnits, ByScenarios");
				If NFPDetails.ByCompanies Then
					QueryText = StrReplace(QueryText, "&ConditionsForOrganizations",
						"IterationData.Organization = DistributionBase_Coefficients.Organization");
				Else
					QueryText = StrReplace(QueryText, "&ConditionsForOrganizations",
						"DistributionBase_Coefficients.Organization = VALUE(Catalog.Companies.EmptyRef)"); //@ query-part
				EndIf;
				If NFPDetails.ByBusinessUnits Then
					QueryText = StrReplace(QueryText, "&ConditionByDivision",
						"IterationData.Department = DistributionBase_Coefficients.Department");
				Else
					QueryText = StrReplace(QueryText, "&ConditionByDivision",
						"DistributionBase_Coefficients.Department = VALUE(Catalog.BusinessStructure.EmptyRef)"); //@ query-part
				EndIf;
				If NFPDetails.ByScenarios Then
					QueryText = StrReplace(QueryText, "&ScenarioConditions",
						"IterationData.Scenario = DistributionBase_Coefficients.Scenario");
				Else
					QueryText = StrReplace(QueryText, "&ScenarioConditions",
						"DistributionBase_Coefficients.Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef)"); //@ query-part
				EndIf;
				
				SourceResources = New Array;
				SourceResources.Add("IterationData.CountTurnover");
				SourceResources.Add("IterationData.SumManTurnover");
				SourceResources.Add("IterationData.ScenarioAmountTurnover");
				SourceResources.Add("IterationData.SumComplTurnover");
				SourceResources.Add("IterationData.AmountInCurrencyTurnover");
				ResourceRoundingPattern = "";
				If RoundingPrecision <> 1 Then
					ResourceRoundingPattern = "CAST(%1 AS NUMBER(%2,0))"; // @query-part
				EndIf;
				For Each Resource In SourceResources Do
					If Not IsBlankString(ResourceRoundingPattern) Then
						QueryText = StrReplace(QueryText, Resource, StringFunctionsClientServer.SubstituteParametersToString(
							ResourceRoundingPattern, Resource, FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(RoundingPrecision)));
					EndIf;
					QueryText = StrReplace(QueryText, Resource, TMCommonUse.AmountDistributionText(Resource,
						"ISNULL(DistributionBase_Coefficients.ZoomRatio, 0)",
						"ISNULL(DistributionBase_Coefficients.AccumulatedCoefficient, 0)",
						"ISNULL(DistributionBase_Amount.TotalCoefficient, 0)")); //@ query-part
				EndDo;
				
				AnalystNumbersWithoutDistribution = ReceiverAnalystNumbersByIterationNumbers.Get(IterationNumber);
				MatchingAnalystNumbersWithDistribution = AnalystNumbersByIterationNumbers.Get(IterationNumber);
				ArrayOfAnalystFields = New Array;
				ArrayOfSourceAnalystFields = New Array;
				For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
					If AnalystNumbersWithoutDistribution.Find(DimensionNumber) <> Undefined Then
						ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
							"IterationData.Dimension%1 AS Dimension%1", DimensionNumber));
					Else
						ProfileAnalyticsNumber = MatchingAnalystNumbersWithDistribution.Get(DimensionNumber);
						If ProfileAnalyticsNumber <> Undefined Then
							ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
								"DistributionBase_Coefficients.Dimension%1 AS Dimension%2", ProfileAnalyticsNumber,
								DimensionNumber));
						Else
							ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
								"UNDEFINED AS Dimension%2", ProfileAnalyticsNumber, DimensionNumber));
						EndIf;
					EndIf;
					ArrayOfSourceAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
						"UNDEFINED AS Dimension%1Source1", DimensionNumber)); //@ query-part
				EndDo;
				TextOfSourceAnalystFields = StrConcat(ArrayOfSourceAnalystFields, "," + Chars.LF + Chars.Tab);
				QueryText = StrReplace(QueryText, "&TextOfSourceAnalystFields", TextOfSourceAnalystFields);
				TextOfDimensionsFields = StrConcat(ArrayOfAnalystFields, "," + Chars.LF + Chars.Tab);
				QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", TextOfDimensionsFields);
				
				ArrayOfConditionsForJoiningAnalystCoefficientsFields = New Array;
				ArrayOfConditionsForJoiningAnalystSumFields = New Array;
				For Each KeyAndValue In InitialNumbersOfAnalystByIterationNumbers.Get(IterationNumber) Do
					ArrayOfConditionsForJoiningAnalystCoefficientsFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
						"IterationData.Dimension%1 = DistributionBase_Coefficients.Dimension%2",
						KeyAndValue.Value, KeyAndValue.Key));
					ArrayOfConditionsForJoiningAnalystSumFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
						"IterationData.Dimension%1 = DistributionBase_Amount.Dimension%2", KeyAndValue.Value,
						KeyAndValue.Key));
				EndDo;
				ConditionForConnectingAnalystCoefficientsFields = StrConcat(
					ArrayOfConditionsForJoiningAnalystCoefficientsFields, Chars.LF + Chars.Tab + "And ");
				ConditionForJoiningAnalystSumFields = StrConcat(ArrayOfConditionsForJoiningAnalystSumFields,
					Chars.LF + Chars.Tab + "And ");
				QueryText = StrReplace(QueryText, "&ConditionForConnectingAnalystCoefficientsFields", ?(IsBlankString(
					ConditionForConnectingAnalystCoefficientsFields), "TRUE", ConditionForConnectingAnalystCoefficientsFields));
				QueryText = StrReplace(QueryText, "&ConditionForJoiningAnalystSumFields", ?(IsBlankString(
					ConditionForJoiningAnalystSumFields), "TRUE", ConditionForJoiningAnalystSumFields));

				QueryText = StrReplace(QueryText, "IterationData",
					StringFunctionsClientServer.SubstituteParametersToString("IterationData_%1",
					IdOfLineIteration));

				QueryText = StrReplace(QueryText, "AllocationBase",
					StringFunctionsClientServer.SubstituteParametersToString("AllocationBase_%1",
					NFPID));
				
			EndDo;
		
		EndIf;

		QueriesTexts.Add(QueryText);
		
	EndDo;
	
	RequestForSettings.QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	If QueryTextsTemporaryTables.Count() > 0 Then
		RequestForSettings.QueryTextTemporaryTable = StrConcat(QueryTextsTemporaryTables,
			Common.QueryBatchSeparator());
	EndIf;
	
	Return RequestForSettings;
	
EndFunction

// Returns the name of the calculation rule, generated by the names of the source and receiver of the rule.
//
// Parameters:
//  Description - String - name of the calculation rule
//  SourceType - EnumRef.DataSourceTypesForBudgeting - type of data source
//  Source - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems - data source for the rule
//  Receiver - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems - receiving data by rule
//
// Returns:
//  String
//
Function GenerateRuleName(Description, SourceType, Source, Receiver) Export

	If Not ValueIsFilled(Receiver)
		Or Not ValueIsFilled(SourceType) Then
		Return Description;
	EndIf;
	
	ItemArray = CommonClientServer.ValueInArray(Receiver);
	
	If ValueIsFilled(Source) Then
		ItemArray.Add(Source);
	EndIf;
	
	NamesOfItems = Common.ObjectsAttributeValue(ItemArray, "Description");
	If NamesOfItems.Count() = 1
		And SourceType <> Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
		NamesOfItems.Insert(SourceType, TrimAll(SourceType));
	EndIf;
	
	If NamesOfItems.Count() = 2 Then
		Description = ?(ValueIsFilled(Source), NamesOfItems.Get(Source),
			NamesOfItems.Get(SourceType)) + " --> " + NamesOfItems.Get(Receiver);
	EndIf;
	
	Return Description;

EndFunction

// Returns an array of valid calculation rules for the specified budget item or indicator
//
// Parameters:
//  ItemIndicator - CatalogRef.BudgetFlowItems,
//						CatalogRef.BudgetBalanceItems
//
// Returns:
//  Array of CatalogRef.RuleForCalculatingRelatedBudgetBalancesAndTurnovers
//
Function RulesForCalculatingBudgetIndicatorItem(ItemIndicator) Export
	
	Query = New Query;
	Query.SetParameter("ItemIndicator", ItemIndicator);
	Query.Text = 
	"SELECT
	|	CalculationsRules.Ref AS CalculationRule
	|FROM
	|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|WHERE
	|	CalculationsRules.Receiver = &ItemIndicator
	|	AND NOT CalculationsRules.DeletionMark
	|	AND CalculationsRules.Status = VALUE(Enum.BudgetingRuleStatuses.Valid)";
	SetPrivilegedMode(True);
	RulesArray = Query.Execute().Unload().UnloadColumn("CalculationRule");
	SetPrivilegedMode(False);
	
	Return RulesArray;

EndFunction

#EndRegion

#Region Private

Function HashSettingsCalculationRules(CalculationRule)
	
	StructureOfRuleSettings = New Structure("DimensionFillingSettings, DataCalculationSettings, MatchingAnalystValues");
	StructureOfRuleSettings.DimensionFillingSettings = CalculationRule.DimensionFillingSettings.Unload();
	StructureOfRuleSettings.DimensionFillingSettings.Sort("DimensionKind");
	StructureOfRuleSettings.DataCalculationSettings = CalculationRule.DataCalculationSettings.Unload();
	StructureOfRuleSettings.DataCalculationSettings.Sort("ZoomRatio, NFIFactor, AllocationProfile, AmountSource");
	StructureOfRuleSettings.MatchingAnalystValues = CalculationRule.MatchingAnalystValues.Unload();
	StructureOfRuleSettings.MatchingAnalystValues.Sort("DimensionValue");
	StructureOfRuleSettings.Insert("SourceType", CalculationRule.SourceType);
	
	SerializedRuleSettings = Common.ValueToXMLString(StructureOfRuleSettings);
	HashSettingsRules = TMCommonUse.HashSumOfString(SerializedRuleSettings, HashFunction.MD5);
	
	Return HashSettingsRules;
	
EndFunction

Procedure AddQueryTextsForSettingOffsetOfDCSPeriod(TempTableName, NumberOfTypeOfAnalytics,
	QueryTextsOfDistributionDatabase, Settings, CalculationRule)
	
	If ValueIsFilled(Settings.DCSTemplateName) Then
		If Not ValueIsFilled(CalculationRule.Source) Then
			Raise NStr(
				"vi = 'Không cho phép sử dụng sơ đồ dàn dựng dữ liệu được chọn của dịch chuyển kỳ cho kiểu nguồn này.';
				|ru = 'Использование выбранной схемы компоновки данных смещения периода для данного типа источника недопустимо.';
				|en = 'Cannot use the selected data composition schema of period offset for this source type.'; fa = 'Cannot use the selected data composition schema of period offset for this source type.';
				|it = 'Cannot use the selected data composition schema of period offset for this source type.';
				|pl = 'Cannot use the selected data composition schema of period offset for this source type.';
				|tr = 'Seçilen dönem kayması veri inşa edilme şemasının bu kaynak tipi için kullanılması geçerli değildir.'");
		EndIf;
		TypesOfSourceAnalytics = BudgetingServer.DimensionKinds(CalculationRule.Source, True);
		RelatedKindOfAnalytics = TypesOfSourceAnalytics[Left(Settings.DCSTemplateName, StrFind(Settings.DCSTemplateName,
			"_") - 1)];
		NumberOfTypeOfAnalytics = Mid(Settings.DCSTemplateName, StrFind(Settings.DCSTemplateName, "_") - 1, 1);
		TabularSectionName = Mid(Settings.DCSTemplateName, StrFind(Settings.DCSTemplateName, "_") + 1);
		DataCompositionSchema = GetDataCompositionSchemaOfPeriodOffset(RelatedKindOfAnalytics, TabularSectionName);
		DataCompositionSettings = DataCompositionSchema.DefaultSettings;
	Else
		TabularSectionName = "Custom";
		DataCompositionSchema = Settings.StorageOfDataCompositionSchema.Get();
		DataCompositionSettings = Settings.StorageOfDataCompositionSettings.Get();
		AnalyticsViewParameter = DataCompositionClientServer.GetParameter(DataCompositionSettings, "DimensionKind");
		If AnalyticsViewParameter = Undefined
			Or Not ValueIsFilled(AnalyticsViewParameter.Value) Then
			Raise NStr(
				"vi = 'Trong sơ đồ dàn dựng dữ liệu cài đặt dịch chuyển kỳ chưa xác định tham số ""Dạng đối tượng phân tích""';
				|ru = 'В схеме компоновки данных настроек смещения периода не задан параметр ""Вид аналитики""';
				|en = 'The Dimension kind parameter is not specified in the data composition schema of the period offset settings'; fa = 'The Dimension kind parameter is not specified in the data composition schema of the period offset settings';
				|it = 'The Dimension kind parameter is not specified in the data composition schema of the period offset settings';
				|pl = 'The Dimension kind parameter is not specified in the data composition schema of the period offset settings';
				|tr = '""Boyut türü"" parametresi, dönem kayması ayarlarının veri inşa şemasında belirtilmedi'");
		EndIf;
		If ValueIsFilled(CalculationRule.Source) Then
			NumberOfTypeOfAnalytics = BudgetingCached.NumberOfTypeOfAnalyticsItemIndicatorBudgets(CalculationRule.Source,
				AnalyticsViewParameter.Value);
		Else
			AvailableTypesOfAnalytics = BudgetingCached.AvailableTypesOfAnalyticsForPlanningSourceType(
				CalculationRule.SourceType);
			If TypeOf(AnalyticsViewParameter.Value) = Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions") Then
				TypesOfAnalyticsType = BudgetingCached.TypesOfAnalyticsType(AnalyticsViewParameter.Value);
				NumberOfTypeOfAnalytics = StrReplace(AvailableTypesOfAnalytics.Get(TypesOfAnalyticsType[0]), "TableName.", "");
			EndIf;
		EndIf;
		If Not ValueIsFilled(NumberOfTypeOfAnalytics) Then
			Raise NStr(
				"vi = 'Trong sơ đồ dàn dựng dữ liệu cài đặt, việc dịch chuyển kỳ đã xác định sai tham số ""Dạng đối tượng phân tích""';
				|ru = 'В схеме компоновки данных настроек смещения периода некорректно указан параметр ""Вид аналитики""';
				|en = 'The ""Dimension kind"" parameter is incorrectly specified in the data composition schema of the period offset settings'; fa = 'The ""Dimension kind"" parameter is incorrectly specified in the data composition schema of the period offset settings';
				|it = 'The ""Dimension kind"" parameter is incorrectly specified in the data composition schema of the period offset settings';
				|pl = 'The ""Dimension kind"" parameter is incorrectly specified in the data composition schema of the period offset settings';
				|tr = '""Boyu türü"" parametresi, dönem kayması ayarlarının veri inşa şemasında yanlış belirtildi'");
		EndIf;
	EndIf;
	
	SerializedDataCompositionSchema = Common.ValueToXMLString(DataCompositionSchema);
	HashOfDataCompositionSchema = TMCommonUse.HashSumOfString(SerializedDataCompositionSchema, HashFunction.MD5);
	TempTableName = StringFunctionsClientServer.SubstituteParametersToString("PeriodOffsetSettings_%1",
		HashOfDataCompositionSchema);
	QueryTextsTemporaryTables = New Array;
	
	CompositionTemplate = DataCompositionServer.GetLayoutTemplate(DataCompositionSchema, DataCompositionSettings);
	Query = DataCompositionServer.GETRequestFromLayoutTemplate(CompositionTemplate, TabularSectionName);
	QueryTextForPeriodOffset = RequestSchemes.SetRoomToTemporaryTable(Query.Text,
		TempTableName) + Chars.LF + Chars.Tab + "INDEX BY DimensionValue, LineNumber";
	QueryTextsTemporaryTables.Add(QueryTextForPeriodOffset);
	
	QueryTextForPeriodOffset =
	"SELECT
	|	PeriodOffsetSettings.DimensionValue,
	|	PeriodOffsetSettings.PeriodOfShift,
	|	PeriodOffsetSettings.OffsetFrequency,
	|	PeriodOffsetSettings.OffsetForward,
	|	PeriodOffsetSettings.LineNumber,
	|	PeriodOffsetSettings.ZoomRatio,
	|	ISNULL(SUM(PeriodOffsetSettings_PreviousOnes.ZoomRatio), 0) AS AccumulatedCoefficient
	|INTO PeriodOffsetSettings_Coefficients
	|FROM
	|	PeriodOffsetSettings AS PeriodOffsetSettings
	|		LEFT JOIN PeriodOffsetSettings AS PeriodOffsetSettings_PreviousOnes
	|		ON PeriodOffsetSettings.DimensionValue = PeriodOffsetSettings_PreviousOnes.DimensionValue
	|			AND PeriodOffsetSettings.LineNumber > PeriodOffsetSettings_PreviousOnes.LineNumber
	|
	|GROUP BY
	|	PeriodOffsetSettings.DimensionValue,
	|	PeriodOffsetSettings.PeriodOfShift,
	|	PeriodOffsetSettings.OffsetFrequency,
	|	PeriodOffsetSettings.OffsetForward,
	|	PeriodOffsetSettings.LineNumber,
	|	PeriodOffsetSettings.ZoomRatio
	|
	|INDEX BY
	|	PeriodOffsetSettings.DimensionValue";
	QueryTextsTemporaryTables.Add(StrReplace(QueryTextForPeriodOffset,
		"PeriodOffsetSettings", TempTableName));
	
	QueryTextForPeriodOffset = 
	"SELECT
	|	PeriodOffsetSettings.DimensionValue,
	|	SUM(PeriodOffsetSettings.ZoomRatio) AS TotalCoefficient
	|INTO PeriodOffsetSettings_Amount
	|FROM
	|	PeriodOffsetSettings AS PeriodOffsetSettings
	|
	|GROUP BY
	|	PeriodOffsetSettings.DimensionValue
	|
	|INDEX BY
	|	DimensionValue";
	QueryTextsTemporaryTables.Add(StrReplace(QueryTextForPeriodOffset,
		"PeriodOffsetSettings", TempTableName));
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueryTextsTemporaryTables,
		TempTableName);
	
	QueryTextsOfDistributionDatabase.Insert(TempTableName, StrConcat(QueryTextsTemporaryTables,
		Common.QueryBatchSeparator()));
	
EndProcedure

Procedure AddQueryTextConversionFactorsForNFP(QueryTextsOfDistributionDatabase, Settings, QueryOptions)

	NFPID = StrReplace(Settings.NFIFactor.UUID(), "-", "");
	TempTableName = StringFunctionsClientServer.SubstituteParametersToString("NFPCoefficients_%1", NFPID);
	If QueryTextsOfDistributionDatabase.Get(TempTableName) <> Undefined Then
		Return;
	EndIf;

	QueryText =
	"SELECT
	|	NFPCoefficients.Scenario AS Scenario,
	|	NFPCoefficients.Organization AS Organization,
	|	NFPCoefficients.Department AS Department,
	|	&TextOfDimensionsFields,
	|	NFPCoefficients.Currency AS Currency,
	|	CAST(NFPCoefficients.IndicatorValue AS NUMBER(31, 6)) AS IndicatorValue
	|INTO NFPCoefficients
	|FROM
	|	InformationRegister.NonFinancialItemValues.SliceLast({(&UpdateDate)}, NonFinancialItem = &NFPParameter) AS NFPCoefficients
	|{WHERE
	|	(NFPCoefficients.EndDate < &UpdateDate)}";
	NameOfNFPParameter = StringFunctionsClientServer.SubstituteParametersToString("NFP%1", NFPID);
	QueryText = StrReplace(QueryText, "NFPParameter", NameOfNFPParameter);
	QueryOptions.Insert(NameOfNFPParameter, Settings.NFIFactor);
	
	ArrayOfAnalystFields = New Array;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	TypesOfNFPAnalysts = BudgetingServer.DimensionKinds(Settings.NFIFactor);
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AnalyticsViewLine = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1", DimensionNumber);
		If Not ValueIsFilled(TypesOfNFPAnalysts[AnalyticsViewLine]) Then
			Continue;
		EndIf;
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"NFPCoefficients.Dimension%1 AS Dimension%1", DimensionNumber));
	EndDo;
	TextOfDimensionsFields = StrConcat(ArrayOfAnalystFields, "," + Chars.LF + Chars.Tab);
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields,", ?(IsBlankString(TextOfDimensionsFields), "",
		TextOfDimensionsFields + ","));
	
	QueryText = StrReplace(QueryText, "NFPCoefficients", TempTableName);
	QueryTextsOfDistributionDatabase.Insert(TempTableName, QueryText);

EndProcedure

Procedure AddQueryTextForecastExchangeRates(QueryText, QueryOptions, ThereIsPeriodOffset,
	RecordCalculationInPlanningDocuments)
	
	If Not IsBlankString(QueryText) Then
		Return;
	EndIf;
	
	QueryText = Catalogs.BudgetingScenarios.QueryTextScriptCourseTable("ForecastExchangeRates");
	QueryText = StrReplace(QueryText, "&ScenarioCondition", "TRUE");
	QueryText = StrReplace(QueryText, "&ConditionByCurrency1", "TRUE");
	QueryText = StrReplace(QueryText, "&ConditionByCurrency2", "TRUE");
	If ThereIsPeriodOffset Or RecordCalculationInPlanningDocuments Then
		QueryText = StrReplace(QueryText, "ForecastedExchangeRatesOfScenarios.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod",
			"TRUE");
		QueryText = StrReplace(QueryText, "&BeginOfPeriod", "&DateEmpty");
	EndIf;
	
	QueryOptions.Insert("ManagementAccountingCurrency", SettingsValueCached.ManagementAccountingCurrency());
	QueryOptions.Insert("LocalAccountingCurrency", SettingsValueCached.DefaultBaseCurrency());
	
EndProcedure

Procedure AddQueryTextsForecastExchangeRatesByPeriod(QueriesTexts, RowID)
	
	QueryTextsTemporaryTables = New Array;
	
	QueryText =
	"SELECT DISTINCT
	|	PreliminaryData.Scenario AS Scenario,
	|	PreliminaryData.PlanningPeriod AS PlanningPeriod,
	|	PreliminaryData.Currency AS Currency
	|INTO TTPlanningPeriodsWithCurrencies
	|FROM
	|	PreliminaryData AS PreliminaryData
	|
	|INDEX BY
	|	Scenario,
	|	PlanningPeriod";
	QueryText = StrReplace(QueryText, "PreliminaryData",
		StringFunctionsClientServer.SubstituteParametersToString("PreliminaryData_%1", RowID));
	QueryText = StrReplace(QueryText, "TTPlanningPeriodsWithCurrencies",
		StringFunctionsClientServer.SubstituteParametersToString("TTPlanningPeriodsWithCurrencies_%1", RowID));
	QueryTextsTemporaryTables.Add(QueryText);
	
	QueryText =
	"SELECT DISTINCT
	|	TTPlanningPeriodsWithCurrencies.Scenario AS Scenario,
	|	TTPlanningPeriodsWithCurrencies.PlanningPeriod AS PlanningPeriod
	|INTO TTPlanningPeriodsWithoutCurrencies
	|FROM
	|	TTPlanningPeriodsWithCurrencies AS TTPlanningPeriodsWithCurrencies
	|
	|INDEX BY
	|	Scenario,
	|	PlanningPeriod";
	QueryText = StrReplace(QueryText, "TTPlanningPeriodsWithCurrencies",
		StringFunctionsClientServer.SubstituteParametersToString("TTPlanningPeriodsWithCurrencies_%1", RowID));
	QueryText = StrReplace(QueryText, "TTPlanningPeriodsWithoutCurrencies",
		StringFunctionsClientServer.SubstituteParametersToString("TTPlanningPeriodsWithoutCurrencies_%1", RowID));
	QueryTextsTemporaryTables.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	TTPlanningPeriodsWithoutCurrencies.Scenario AS Scenario,
	|	TTPlanningPeriodsWithoutCurrencies.PlanningPeriod AS PlanningPeriod,
	|	ForecastExchangeRates.Currency AS Currency,
	|	MAX(ForecastExchangeRates.Period) AS Period
	|INTO TTPeriodsOfForecastExchangeRates
	|FROM
	|	TTPlanningPeriodsWithoutCurrencies AS TTPlanningPeriodsWithoutCurrencies
	|		INNER JOIN ForecastExchangeRates AS ForecastExchangeRates
	|		ON TTPlanningPeriodsWithoutCurrencies.Scenario = ForecastExchangeRates.Scenario
	|			AND TTPlanningPeriodsWithoutCurrencies.PlanningPeriod >= ForecastExchangeRates.Period
	|			AND (ForecastExchangeRates.Currency IN
	|				(SELECT
	|					TTPlanningPeriodsWithCurrencies.Currency
	|				FROM
	|					TTPlanningPeriodsWithCurrencies AS TTPlanningPeriodsWithCurrencies
	|			
	|				UNION ALL
	|			
	|				SELECT
	|					&ManagementAccountingCurrency
	|			
	|				UNION ALL
	|			
	|				SELECT
	|					&LocalAccountingCurrency))
	|
	|GROUP BY
	|	TTPlanningPeriodsWithoutCurrencies.Scenario,
	|	TTPlanningPeriodsWithoutCurrencies.PlanningPeriod,
	|	ForecastExchangeRates.Currency
	|
	|INDEX BY
	|	Scenario,
	|	Currency,
	|	Period";
	QueryText = StrReplace(QueryText, "TTPlanningPeriodsWithCurrencies",
		StringFunctionsClientServer.SubstituteParametersToString("TTPlanningPeriodsWithCurrencies_%1", RowID));
	QueryText = StrReplace(QueryText, "TTPlanningPeriodsWithoutCurrencies",
		StringFunctionsClientServer.SubstituteParametersToString("TTPlanningPeriodsWithoutCurrencies_%1", RowID));
	QueryText = StrReplace(QueryText, "TTPeriodsOfForecastExchangeRates",
		StringFunctionsClientServer.SubstituteParametersToString("TTPeriodsOfForecastExchangeRates_%1", RowID));
	QueryTextsTemporaryTables.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueryTextsTemporaryTables,
		StringFunctionsClientServer.SubstituteParametersToString("TTPlanningPeriodsWithCurrencies_%1", RowID));
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueryTextsTemporaryTables,
		StringFunctionsClientServer.SubstituteParametersToString("TTPlanningPeriodsWithoutCurrencies_%1", RowID));
	
	QueryText =
	"SELECT
	|	TTPeriodsOfForecastExchangeRates.Scenario AS Scenario,
	|	TTPeriodsOfForecastExchangeRates.PlanningPeriod AS PlanningPeriod,
	|	TTPeriodsOfForecastExchangeRates.Currency AS Currency,
	|	ForecastExchangeRates.Rate AS Rate
	|INTO TT_ForecastExchangeRates
	|FROM
	|	TTPeriodsOfForecastExchangeRates AS TTPeriodsOfForecastExchangeRates
	|		INNER JOIN ForecastExchangeRates AS ForecastExchangeRates
	|		ON TTPeriodsOfForecastExchangeRates.Scenario = ForecastExchangeRates.Scenario
	|			AND TTPeriodsOfForecastExchangeRates.Currency = ForecastExchangeRates.Currency
	|			AND TTPeriodsOfForecastExchangeRates.Period = ForecastExchangeRates.Period
	|
	|INDEX BY
	|	Scenario,
	|	Currency,
	|	PlanningPeriod";
	QueryText = StrReplace(QueryText, "TTPeriodsOfForecastExchangeRates",
		StringFunctionsClientServer.SubstituteParametersToString("TTPeriodsOfForecastExchangeRates_%1", RowID));
	QueryText = StrReplace(QueryText, "TT_ForecastExchangeRates",
		StringFunctionsClientServer.SubstituteParametersToString("TTForecastExchangeRates_%1", RowID));
	QueryTextsTemporaryTables.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueryTextsTemporaryTables,
		StringFunctionsClientServer.SubstituteParametersToString("TTPeriodsOfForecastExchangeRates_%1", RowID));
	
	QueriesTexts.Add(StrConcat(QueryTextsTemporaryTables, Common.QueryBatchSeparator()));
	
EndProcedure

Procedure AddQueryTextTableOfPartnerCounterparties(QueryText, ThereIsPeriodOffset,
	RecordCalculationInPlanningDocuments)
	
	If Not IsBlankString(QueryText) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	Counterparties.Partner AS Partner,
	|	MAX(Counterparties.Ref) AS Counterparty
	|INTO TTPartnersCounterparties
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				AccumulationRegister.SalesPlans AS Plans
	|			WHERE
	|				Counterparties.Partner = Plans.Partner
	|				AND &ConditionByPeriod
	|				AND &ConditionForRegistrar
	|		
	|			UNION ALL
	|		
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				AccumulationRegister.PurchasePlans AS Plans
	|			WHERE
	|				Counterparties.Partner = Plans.Partner
	|				AND &ConditionByPeriod
	|				AND &ConditionForRegistrar)
	|
	|GROUP BY
	|	Counterparties.Partner
	|
	|INDEX BY
	|	Partner";
	If ThereIsPeriodOffset Or RecordCalculationInPlanningDocuments Then
		QueryText = StrReplace(QueryText, "&ConditionByPeriod", "TRUE");
	Else
		QueryText = StrReplace(QueryText, "&ConditionByPeriod", "(Plans.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod)");
	EndIf;
	If RecordCalculationInPlanningDocuments Then
		QueryText = StrReplace(QueryText, "&ConditionForRegistrar", "Plans.Recorder IN (&Recorders)");
	Else
		QueryText = StrReplace(QueryText, "&ConditionForRegistrar", "TRUE");
	EndIf;
	
EndProcedure

Procedure AddQueryTextsToDistributionDatabaseByPeriod(QueryTextsOfDistributionDatabase, Settings, QueryOptions)

	NFPID = StrReplace(Settings.AllocationProfile.UUID(), "-", "");
	TempTableName = StringFunctionsClientServer.SubstituteParametersToString("AllocationBase_%1", NFPID);
	If QueryTextsOfDistributionDatabase.Get(TempTableName) <> Undefined Then
		Return;
	EndIf;
	
	QueryTextsTemporaryTables = New Array;
	
	QueryText =
	"SELECT
	|	AllocationBase.Scenario AS Scenario,
	|	AllocationBase.Organization AS Organization,
	|	AllocationBase.Department AS Department,
	|	&TextOfDimensionsFields,
	|	AllocationBase.SubperiodNumber AS SubperiodNumber,
	|	CAST(AllocationBase.IndicatorValue AS NUMBER(31, 6)) AS IndicatorValue
	|INTO AllocationBase
	|FROM
	|	InformationRegister.NonFinancialItemValues.SliceLast({(&UpdateDate)}, NonFinancialItem = &NFPParameter) AS AllocationBase
	|{WHERE
	|	(AllocationBase.EndDate < &UpdateDate)}
	|
	|INDEX BY
	|	Scenario,
	|	Organization,
	|	Department";
	QueryText = QueryText + ",
	|	&TextOfAnalystAliases,
	|	SubperiodNumber";
	NameOfNFPParameter = StringFunctionsClientServer.SubstituteParametersToString("NFP%1", NFPID);
	QueryText = StrReplace(QueryText, "NFPParameter", NameOfNFPParameter);
	QueryOptions.Insert(NameOfNFPParameter, Settings.AllocationProfile);
	
	ArrayOfAnalystFields = New Array;
	ArrayOfAnalystAliases = New Array;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	TypesOfNFPAnalysts = BudgetingServer.DimensionKinds(Settings.AllocationProfile);
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AnalyticsViewLine = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1", DimensionNumber);
		If Not ValueIsFilled(TypesOfNFPAnalysts[AnalyticsViewLine]) Then
			Continue;
		EndIf;
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"AllocationBase.Dimension%1 AS Dimension%1", DimensionNumber));
		ArrayOfAnalystAliases.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"Dimension%1", DimensionNumber));
	EndDo;
	TextOfDimensionsFields = StrConcat(ArrayOfAnalystFields, "," + Chars.LF + Chars.Tab);
	TextOfAnalystAliases = StrConcat(ArrayOfAnalystAliases, "," + Chars.LF + Chars.Tab);
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields,", ?(IsBlankString(TextOfDimensionsFields), "",
		TextOfDimensionsFields + ","));
	QueryText = StrReplace(QueryText, "&TextOfAnalystAliases,", ?(IsBlankString(
		TextOfAnalystAliases), "", TextOfAnalystAliases + ","));
	
	QueryText = StrReplace(QueryText, "AllocationBase", TempTableName);
	QueryTextsTemporaryTables.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	AllocationBase.Scenario AS Scenario,
	|	AllocationBase.Organization AS Organization,
	|	AllocationBase.Department AS Department,
	|	&TextOfDimensionsFields,
	|	AllocationBase.SubperiodNumber AS SubperiodNumber,
	|	AllocationBase.IndicatorValue AS ZoomRatio,
	|	ISNULL(SUM(DistributionBase_Previous.IndicatorValue), 0) AS AccumulatedCoefficient
	|INTO DistributionBase_Coefficients
	|FROM
	|	AllocationBase AS AllocationBase
	|	LEFT JOIN AllocationBase AS DistributionBase_Previous
	|		ON AllocationBase.Scenario = DistributionBase_Previous.Scenario
	|		AND AllocationBase.Organization = DistributionBase_Previous.Organization
	|		AND AllocationBase.Department = DistributionBase_Previous.Department
	|		AND &ConditionForJoiningAnalystFields
	|		AND AllocationBase.SubperiodNumber > DistributionBase_Previous.SubperiodNumber
	|
	|GROUP BY
	|	AllocationBase.Scenario,
	|	AllocationBase.Organization,
	|	AllocationBase.Department,
	|	&TextOfAnalystGroups,
	|	AllocationBase.SubperiodNumber,
	|	AllocationBase.IndicatorValue
	|
	|INDEX BY
	|	Scenario,
	|	Organization,
	|	Department";
	QueryText = QueryText + "
	|	,&TextOfAnalystAliases";
	
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields,", ?(IsBlankString(TextOfDimensionsFields), "",
		TextOfDimensionsFields + ","));
	QueryText = StrReplace(QueryText, ",&TextOfAnalystAliases", ?(IsBlankString(
		TextOfAnalystAliases), "", "," + TextOfAnalystAliases));
	
	ArrayOfAnalyticsGroups = New Array;
	ArrayOfConditionsForJoiningAnalystFields = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AnalyticsViewLine = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1", DimensionNumber);
		If Not ValueIsFilled(TypesOfNFPAnalysts[AnalyticsViewLine]) Then
			Continue;
		EndIf;
		ArrayOfAnalyticsGroups.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"AllocationBase.Dimension%1", DimensionNumber));
		ArrayOfConditionsForJoiningAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"AllocationBase.Dimension%1 = DistributionBase_Previous.Dimension%1", DimensionNumber));
	EndDo;
	TextOfAnalystGroups = StrConcat(ArrayOfAnalyticsGroups, "," + Chars.LF + Chars.Tab);
	ConditionForJoiningAnalystFields = StrConcat(ArrayOfConditionsForJoiningAnalystFields, Chars.LF + Chars.Tab + "And ");
	QueryText = StrReplace(QueryText, "&TextOfAnalystGroups,", ?(IsBlankString(TextOfAnalystGroups), "",
		TextOfAnalystGroups + ","));
	QueryText = StrReplace(QueryText, "&ConditionForJoiningAnalystFields", ?(IsBlankString(
		ConditionForJoiningAnalystFields), "TRUE", ConditionForJoiningAnalystFields));
	
	QueryText = StrReplace(QueryText, "AllocationBase", TempTableName);
	QueryTextsTemporaryTables.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	AllocationBase.Scenario AS Scenario,
	|	AllocationBase.Organization AS Organization,
	|	AllocationBase.Department AS Department,
	|	&TextOfDimensionsFields,
	|	SUM(AllocationBase.IndicatorValue) AS TotalCoefficient
	|INTO DistributionBase_Amount
	|FROM
	|	AllocationBase AS AllocationBase
	|
	|GROUP BY
	|	AllocationBase.Scenario,
	|	AllocationBase.Organization,
	|	AllocationBase.Department
	|	,&TextOfAnalystGroups
	|
	|INDEX BY
	|	Scenario,
	|	Organization,
	|	Department";
	QueryText = QueryText + "
	|	,&TextOfAnalystAliases";
	
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields,", ?(IsBlankString(TextOfDimensionsFields), "",
		TextOfDimensionsFields + ","));
	QueryText = StrReplace(QueryText, ",&TextOfAnalystGroups", ?(IsBlankString(TextOfAnalystGroups), "",
		"," + TextOfAnalystGroups));
	QueryText = StrReplace(QueryText, ",&TextOfAnalystAliases", ?(IsBlankString(
		TextOfAnalystAliases), "", "," + TextOfAnalystAliases));
	
	QueryText = StrReplace(QueryText, "AllocationBase", TempTableName);
	QueryTextsTemporaryTables.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueryTextsTemporaryTables,
		TempTableName);
	
	QueryTextsOfDistributionDatabase.Insert(TempTableName, StrConcat(QueryTextsTemporaryTables,
		Common.QueryBatchSeparator()));

EndProcedure

Procedure AddQueryTextsOfDistributionDatabaseToGetAnalytics(QueryTextsOfDistributionDatabase,
	QueryOptions, CalculationRule, MaximumIterationNumber)

	AnalystDistributionProfiles = CalculationRule.DimensionFillingSettings.Unload(
		New Structure("FillingMethod",
		Enums.MethodsOfFillingBudgetFlowItemDimensions.ByAllocationProfile),
		"AllocationProfile, IterationNumber");
	AnalystDistributionProfiles.GroupBy("AllocationProfile, IterationNumber");
	AnalystDistributionProfiles.Sort("IterationNumber DESC");
	MaximumIterationNumber = ?(AnalystDistributionProfiles.Count() = 0, 0,
		AnalystDistributionProfiles[0].IterationNumber);
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For IterationNumber = 1 To MaximumIterationNumber Do
		
		AllocationProfile = AnalystDistributionProfiles.Find(IterationNumber, "IterationNumber");
		If AllocationProfile = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"vi = 'Sai cài đặt hồ sơ phân bổ: chưa tìm thấy hồ sơ có số %1';
				|ru = 'Некорректные настройки профиля распределения: не найден профиль с номером %1';
				|en = 'Incorrect allocation profile settings: the profile with number %1 is not found'; fa = 'Incorrect allocation profile settings: the profile with number %1 is not found';
				|it = 'Incorrect allocation profile settings: the profile with number %1 is not found';
				|pl = 'Incorrect allocation profile settings: the profile with number %1 is not found';
				|tr = 'Hatalı dağıtım profili ayarları: %1 numaralı profil bulunamadı'"), IterationNumber);
		EndIf;
		
		NFPID = StrReplace(AllocationProfile.AllocationProfile.UUID(), "-", "");
		TempTableName = StringFunctionsClientServer.SubstituteParametersToString("AllocationBase_%1",
			NFPID);
		If QueryTextsOfDistributionDatabase.Get(TempTableName) <> Undefined Then
			Continue;
		EndIf;
		
		QueryTextsTemporaryTables = New Array;
		
		QueryText =
		"SELECT
		|	RECORDAUTONUMBER() AS LineNumber,
		|	AllocationBase.Scenario AS Scenario,
		|	AllocationBase.Organization AS Organization,
		|	AllocationBase.Department AS Department,
		|	&TextOfDimensionsFields,
		|	CAST(AllocationBase.IndicatorValue AS NUMBER(31, 6)) AS IndicatorValue
		|INTO AllocationBase
		|FROM
		|	InformationRegister.NonFinancialItemValues.SliceLast({(&UpdateDate)}, NonFinancialItem = &NFPParameter) AS AllocationBase
		|{WHERE
		|	(AllocationBase.EndDate < &UpdateDate)}
		|
		|INDEX BY
		|	Scenario,
		|	Organization,
		|	Department";
		QueryText = QueryText + ",
		|	&TextOfAnalystAliases,
		|	LineNumber";
		NameOfNFPParameter = StringFunctionsClientServer.SubstituteParametersToString("NFP%1", NFPID);
		QueryText = StrReplace(QueryText, "NFPParameter", NameOfNFPParameter);
		QueryOptions.Insert(NameOfNFPParameter, AllocationProfile.AllocationProfile);

		ArrayOfAnalystFields = New Array;
		ArrayOfAnalystAliases = New Array;
		TypesOfNFPAnalysts = BudgetingServer.DimensionKinds(AllocationProfile.AllocationProfile);
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			AnalyticsViewLine = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1", DimensionNumber);
			If Not ValueIsFilled(TypesOfNFPAnalysts[AnalyticsViewLine]) Then
				Continue;
			EndIf;
			ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
				"AllocationBase.Dimension%1 AS Dimension%1", DimensionNumber));
			ArrayOfAnalystAliases.Add(StringFunctionsClientServer.SubstituteParametersToString(
				"Dimension%1", DimensionNumber));
		EndDo;
		TextOfDimensionsFields = StrConcat(ArrayOfAnalystFields, "," + Chars.LF + Chars.Tab);
		TextOfAnalystAliases = StrConcat(ArrayOfAnalystAliases, "," + Chars.LF + Chars.Tab);
		QueryText = StrReplace(QueryText, "&TextOfDimensionsFields,", ?(IsBlankString(TextOfDimensionsFields), "",
			TextOfDimensionsFields + ","));
		QueryText = StrReplace(QueryText, "&TextOfAnalystAliases,", ?(IsBlankString(
			TextOfAnalystAliases), "", TextOfAnalystAliases + ","));
		
		QueryText = StrReplace(QueryText, "AllocationBase", TempTableName);
		QueryTextsTemporaryTables.Add(QueryText);
		
		QueryText = 
		"SELECT
		|	AllocationBase.Scenario AS Scenario,
		|	AllocationBase.Organization AS Organization,
		|	AllocationBase.Department AS Department,
		|	&TextOfDimensionsFields,
		|	AllocationBase.IndicatorValue AS ZoomRatio,
		|	ISNULL(SUM(DistributionBase_Previous.IndicatorValue), 0) AS AccumulatedCoefficient
		|INTO DistributionBase_Coefficients
		|FROM
		|	AllocationBase AS AllocationBase
		|	LEFT JOIN AllocationBase AS DistributionBase_Previous
		|		ON AllocationBase.Scenario = DistributionBase_Previous.Scenario
		|		AND AllocationBase.Organization = DistributionBase_Previous.Organization
		|		AND AllocationBase.Department = DistributionBase_Previous.Department
		|		AND &ConditionForJoiningAnalystFields
		|		AND AllocationBase.LineNumber > DistributionBase_Previous.LineNumber
		|
		|GROUP BY
		|	AllocationBase.Scenario,
		|	AllocationBase.Organization,
		|	AllocationBase.Department,
		|	&TextOfAnalystGroups,
		|	AllocationBase.IndicatorValue
		|
		|INDEX BY
		|	Scenario,
		|	Organization,
		|	Department";
		QueryText = QueryText + "
		|	,&TextOfAnalystAliases";
		
		QueryText = StrReplace(QueryText, "&TextOfDimensionsFields,", ?(IsBlankString(TextOfDimensionsFields), "",
			TextOfDimensionsFields + ","));
		QueryText = StrReplace(QueryText, ",&TextOfAnalystAliases", ?(IsBlankString(
			TextOfAnalystAliases), "", "," + TextOfAnalystAliases));
		
		ArrayOfAnalyticsGroups = New Array;
		ArrayOfConditionsForJoiningAnalystFields = New Array;
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			AnalyticsViewLine = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1", DimensionNumber);
			If Not ValueIsFilled(TypesOfNFPAnalysts[AnalyticsViewLine]) Then
				Continue;
			EndIf;
			ArrayOfAnalyticsGroups.Add(StringFunctionsClientServer.SubstituteParametersToString(
				"AllocationBase.Dimension%1", DimensionNumber));
			ArrayOfConditionsForJoiningAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
				"AllocationBase.Dimension%1 = DistributionBase_Previous.Dimension%1", DimensionNumber));
		EndDo;
		TextOfAnalystGroups = StrConcat(ArrayOfAnalyticsGroups, "," + Chars.LF + Chars.Tab);
		ConditionForJoiningAnalystFields = StrConcat(ArrayOfConditionsForJoiningAnalystFields, Chars.LF + Chars.Tab + "And ");
		QueryText = StrReplace(QueryText, "&TextOfAnalystGroups,", ?(IsBlankString(TextOfAnalystGroups), "",
			TextOfAnalystGroups + ","));
		QueryText = StrReplace(QueryText, "&ConditionForJoiningAnalystFields", ?(IsBlankString(
			ConditionForJoiningAnalystFields), "TRUE", ConditionForJoiningAnalystFields));
		
		QueryText = StrReplace(QueryText, "AllocationBase", TempTableName);
		QueryTextsTemporaryTables.Add(QueryText);
		
		QueryText = 
		"SELECT
		|	AllocationBase.Scenario AS Scenario,
		|	AllocationBase.Organization AS Organization,
		|	AllocationBase.Department AS Department,
		|	&TextOfDimensionsFields,
		|	SUM(AllocationBase.IndicatorValue) AS TotalCoefficient
		|INTO DistributionBase_Amount
		|FROM
		|	AllocationBase AS AllocationBase
		|
		|GROUP BY
		|	AllocationBase.Scenario,
		|	AllocationBase.Organization,
		|	AllocationBase.Department
		|	,&TextOfAnalystGroups
		|
		|INDEX BY
		|	Scenario,
		|	Organization,
		|	Department";
		QueryText = QueryText + "
		|	,&TextOfAnalystAliases";
		
		QueryText = StrReplace(QueryText, "&TextOfDimensionsFields,", ?(IsBlankString(TextOfDimensionsFields), "",
			TextOfDimensionsFields + ","));
		QueryText = StrReplace(QueryText, ",&TextOfAnalystGroups", ?(IsBlankString(TextOfAnalystGroups), "",
			"," + TextOfAnalystGroups));
		QueryText = StrReplace(QueryText, ",&TextOfAnalystAliases", ?(IsBlankString(
			TextOfAnalystAliases), "", "," + TextOfAnalystAliases));
		
		QueryText = StrReplace(QueryText, "AllocationBase", TempTableName);
		QueryTextsTemporaryTables.Add(QueryText);
		
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueryTextsTemporaryTables,
			TempTableName);
	
		QueryTextsOfDistributionDatabase.Insert(TempTableName, StrConcat(QueryTextsTemporaryTables,
			Common.QueryBatchSeparator()));
		
	EndDo;

EndProcedure

Function MatchingOfAllSourceNumbersOfReceiverAnalyticsToIterationNumbers(CalculationRule)
	
	MatchingAnalyticsAndIterationNumbers = New Map;
	AnalystNumbersWithoutDistribution = New Array;
	AnalystNumbersWithDistribution = New Array;
	
	For Each SettingString In CalculationRule.DimensionFillingSettings Do
		DimensionNumber = BudgetingCached.NumberOfTypeOfAnalyticsItemIndicatorBudgets(CalculationRule.Receiver,
			SettingString.DimensionKind);
		If SettingString.FillingMethod
			<> Enums.MethodsOfFillingBudgetFlowItemDimensions.ByAllocationProfile Then
			AnalystNumbersWithoutDistribution.Add(DimensionNumber);
		Else
			If MatchingAnalyticsAndIterationNumbers.Get(SettingString.IterationNumber) = Undefined Then
				MatchingAnalyticsAndIterationNumbers.Insert(SettingString.IterationNumber,
					CommonClientServer.ValueInArray(DimensionNumber));
			Else
				MatchingAnalyticsAndIterationNumbers[SettingString.IterationNumber].Add(DimensionNumber);
			EndIf;
			AnalystNumbersWithDistribution.Add(DimensionNumber);
		EndIf;
	EndDo;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		If AnalystNumbersWithoutDistribution.Find(DimensionNumber) = Undefined
			And AnalystNumbersWithDistribution.Find(DimensionNumber) = Undefined Then
			AnalystNumbersWithoutDistribution.Add(DimensionNumber);
		EndIf;
	EndDo;
	
	Result = New Map;
	
	For IterationNumber = 1 To MatchingAnalyticsAndIterationNumbers.Count() Do
		Result.Insert(IterationNumber, Common.CopyRecursive(AnalystNumbersWithoutDistribution));
		AnalystNumbersByIterationNumber = MatchingAnalyticsAndIterationNumbers.Get(IterationNumber);
		If AnalystNumbersByIterationNumber <> Undefined Then
			CommonClientServer.SupplementArray(AnalystNumbersWithoutDistribution, AnalystNumbersByIterationNumber);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function MatchingSourceNumbersOfReceiverAnalystProfileToIterationNumbers(CalculationRule)
	
	AnalystDistributionProfiles = CalculationRule.DimensionFillingSettings.Unload(New Structure("FillingMethod",
		Enums.MethodsOfFillingBudgetFlowItemDimensions.ByAllocationProfile), "AllocationProfile, IterationNumber");
	AnalystDistributionProfiles.GroupBy("AllocationProfile, IterationNumber");
	
	Result = New Map;
	
	For Each RowProfile In AnalystDistributionProfiles Do
		ComplianceAnalyst = BudgetingCached.ComplianceOfAnalystWithItemIndicatorOfSNFPBudgets(
			CalculationRule.Receiver, RowProfile.AllocationProfile);
		Result.Insert(RowProfile.IterationNumber, ComplianceAnalyst);
	EndDo;
	
	For Each SettingRow In CalculationRule.DimensionFillingSettings Do
		If SettingRow.FillingMethod
			<> Enums.MethodsOfFillingBudgetFlowItemDimensions.ByAllocationProfile Then
			Continue;
		EndIf;
		DimensionNumber = BudgetingCached.NumberOfTypeOfAnalyticsItemIndicatorBudgets(
			SettingRow.AllocationProfile, SettingRow.DimensionKind);
		Result[SettingRow.IterationNumber].Delete(DimensionNumber);
	EndDo;
	
	Return Result;
	
EndFunction

Function MatchingNumbersOfReceiverAnalystProfileToIterationNumbers(CalculationRule)
	
	Result = New Map;
	
	For Each SettingString In CalculationRule.DimensionFillingSettings Do
		If SettingString.FillingMethod
			<> Enums.MethodsOfFillingBudgetFlowItemDimensions.ByAllocationProfile Then
			Continue;
		EndIf;
		NumberOfProfileAnalyticsType = BudgetingCached.NumberOfTypeOfAnalyticsItemIndicatorBudgets(
			SettingString.AllocationProfile, SettingString.DimensionKind);
		NumberOfTypeOfReceiverAnalytics = BudgetingCached.NumberOfTypeOfAnalyticsItemIndicatorBudgets(
			CalculationRule.Receiver, SettingString.DimensionKind);
		If Result.Get(SettingString.IterationNumber) = Undefined Then
			MatchingAnalystNumbers = New Map;
			MatchingAnalystNumbers.Insert(NumberOfTypeOfReceiverAnalytics, NumberOfProfileAnalyticsType);
			Result.Insert(SettingString.IterationNumber, MatchingAnalystNumbers);
		Else
			Result[SettingString.IterationNumber].Insert(NumberOfTypeOfReceiverAnalytics, NumberOfProfileAnalyticsType);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.5";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Id = New UUID("eef95c74-fc73-40ec-ba25-5ab76db9d602");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Ghi lại danh mục ""Quy tắc tính toán số dư và phát sinh liên quan của ngân sách"":';
								|ru = 'Перезапись справочника ""Правила расчета связанных остатков и оборотов бюджетов"":';
								|en = 'Overwrite the ""Rules for calculating related budget balances and turnovers"" catalog:'; fa = 'Overwrite the ""Rules for calculating related budget balances and turnovers"" catalog:';
								|it = 'Overwrite the ""Rules for calculating related budget balances and turnovers"" catalog:';
								|pl = 'Overwrite the ""Rules for calculating related budget balances and turnovers"" catalog:';
								|tr = '""İlgili bütçe bakiyelerinin ve cirolarının hesaplanma kuralları"" kataloğunun yeniden kaydı:'"));
	ListOfDescriptions.Add(NStr("vi = 'điền mục tin ""Kiểu nguồn"" bằng giá trị ""Phát sinh ngân sách""';
								|ru = 'заполнение реквизита ""Тип источника"" значением ""Обороты бюджетов""';
								|en = 'fill in the ""Source type"" attribute with the ""Budget turnovers"" value'; fa = 'fill in the ""Source type"" attribute with the ""Budget turnovers"" value';
								|it = 'fill in the ""Source type"" attribute with the ""Budget turnovers"" value';
								|pl = 'fill in the ""Source type"" attribute with the ""Budget turnovers"" value';
								|tr = '""Kaynak Türü"" özniteliğinin ""Bütçelerin Ciroları"" değeriyle doldurulması'"));
	ListOfDescriptions.Add(NStr("vi = 'điền mục tin ""Nguồn số tiền"" bằng giá trị ""Số tiền""';
								|ru = 'заполнение реквизита ""Источник суммы"" значением ""Сумма""';
								|en = 'fill in the ""Amount source"" attribute with the ""Amount"" value'; fa = 'fill in the ""Amount source"" attribute with the ""Amount"" value';
								|it = 'fill in the ""Amount source"" attribute with the ""Amount"" value';
								|pl = 'fill in the ""Amount source"" attribute with the ""Amount"" value';
								|tr = '""Tutarın Kaynağı"" özniteliğinin ""Toplam"" değeriyle doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	New_Items = New Array;
	New_Items.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.FullName());
	Handler.NewObjects = StrConcat(New_Items, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CalculationsRules.Ref AS CalculationRule
	|FROM
	|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|WHERE
	|	CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.EmptyRef)";
	ReferencesArrray = Query.Execute().Unload().UnloadColumn("CalculationRule");
	
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.FullName();
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	For Each CatalogItem In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", CatalogItem.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			CatalogObject = CatalogItem.Ref.GetObject(); // CatalogObject.RuleForCalculatingRelatedBudgetBalancesAndTurnovers
			
			If CatalogObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(CatalogItem.Ref);
				CommitTransaction();
				Continue;
			EndIf;
			
			ObjectNeedsToBeOverwritten = False;
			
			If CatalogObject.SourceType = Enums.DataSourceTypesForBudgeting.EmptyRef() Then
				
				CatalogObject.SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers;
				ObjectNeedsToBeOverwritten = True;
				For Each SettingRow In CatalogObject.DataCalculationSettings Do
					If SettingRow.AmountSource = Enums.IndicatorsOfAnalyticalRegisters.EmptyRef() Then
						SettingRow.AmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
					EndIf;
				EndDo;
				
			EndIf;
			
			If ObjectNeedsToBeOverwritten Then
				ExceptionReason = "BadData";
				If CatalogObject.DimensionFillingSettings.Count() > 0 Then
					CatalogObject.AdvancedModeOfDimensionFillSetting = True;
				EndIf;
				InfobaseUpdate.WriteData(CatalogObject, , True);
			Else
				InfobaseUpdate.MarkProcessingCompletion(CatalogItem.Ref);
			EndIf;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			If ExceptionReason = "BadData" Then
				InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), CatalogItem.Ref);
				InfobaseUpdate.MarkProcessingCompletion(CatalogItem.Ref);
				InfobaseUpdate.FileIssueWithData(CatalogItem.Ref,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		FullObjectName);
	
EndProcedure

Function CreateCalculationRuleBasedOnSourceType(SourceType, Receiver, AmountSource, PlanProfiles) Export
	
	ObjectCalculationRule = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.CreateItem();
	ObjectCalculationRule.SourceType = SourceType;
	ObjectCalculationRule.Receiver = Receiver;
	ObjectCalculationRule.Description = GenerateRuleName(ObjectCalculationRule.Description, SourceType, Undefined, Receiver);
	ObjectCalculationRule.Status = Enums.BudgetingRuleStatuses.Valid;
	ObjectCalculationRule.Comment = NStr("vi = 'Đã tạo tự động hàm sự kiện cập nhật CSTT';
										|ru = 'Сформирован автоматически обработчиком обновления ИБ';
										|en = 'Generated automatically by the infobase update handler'; fa = 'Generated automatically by the infobase update handler';
										|it = 'Generated automatically by the infobase update handler';
										|pl = 'Generated automatically by the infobase update handler';
										|tr = 'IB güncelleme işleyicisi tarafından otomatik olarak oluşturuldu'");
	ObjectCalculationRule.AdvancedModeOfDimensionFillSetting = True;
	ObjectCalculationRule.RecordCalculationInPlanningDocuments = True;
	NewRow = ObjectCalculationRule.DataCalculationSettings.Add();
	If ValueIsFilled(AmountSource) Then
		NewRow.AmountSource = AmountSource;
	EndIf;
	NewRow.ZoomRatio = 1;
	If PlanProfiles.Count() > 0 Then
		CompositionSettings = New DataCompositionSettings;
		FieldName = BudgetingCached.NameOfDimensionOfPlanningDocumentBySourceType(SourceType) + ".PlanProfile";
		ListOfPlanProfiles = New ValueList;
		ListOfPlanProfiles.LoadValues(PlanProfiles);
		FinancialReportingServer.SetFilter(CompositionSettings.Filter, FieldName, ListOfPlanProfiles,
			DataCompositionComparisonType.InList, True);
		NewRow.SettingsComposer = New ValueStorage(CompositionSettings);
		NewRow.FilterPresentation = TrimAll(CompositionSettings.Filter);
	EndIf;

	TypesOfReceiverAnalytics = BudgetingServer.DimensionKinds(Receiver, True);
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	AvailableTypesOfAnalytics = BudgetingCached.AvailableTypesOfAnalyticsForPlanningSourceType(ObjectCalculationRule.SourceType);
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AnalyticsViewLine = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1", DimensionNumber);
		StringTypeOfAnalyticsTypeValue = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1ValueType", DimensionNumber);
		If ValueIsFilled(TypesOfReceiverAnalytics[AnalyticsViewLine]) Then
			NewRow = ObjectCalculationRule.DimensionFillingSettings.Add();
			NewRow.DimensionKind = TypesOfReceiverAnalytics[AnalyticsViewLine];
			TypesOfAnalyticsType = TypesOfReceiverAnalytics[StringTypeOfAnalyticsTypeValue].Types();
			DimensionPopulationExpression = "";
			For Each TypeOfAnalyticsType In TypesOfAnalyticsType Do
				If AvailableTypesOfAnalytics[TypeOfAnalyticsType] <> Undefined Then
					NewRow.FillingMethod = Enums.MethodsOfFillingBudgetFlowItemDimensions.FromDataSource;
					If TypeOfAnalyticsType = Type("CatalogRef.Companies") Then
						If StrFind(AvailableTypesOfAnalytics[TypeOfAnalyticsType], "Plan.Terms.Organization") > 0 Then
							DimensionPopulationExpression = "Plan.Terms.Organization";
						Else
							DimensionPopulationExpression = "Terms.Organization";
						EndIf;
					ElsIf TypeOfAnalyticsType = Type("CatalogRef.Counterparties") Then
						If StrFind(AvailableTypesOfAnalytics[TypeOfAnalyticsType], "TTPartnersCounterparties.Counterparty") > 0 Then
							DimensionPopulationExpression = "Counterparty";
						ElsIf StrFind(AvailableTypesOfAnalytics[TypeOfAnalyticsType], "Terms.Counterparty") > 0 Then
							DimensionPopulationExpression = "Terms.Counterparty";
						Else
							DimensionPopulationExpression = AvailableTypesOfAnalytics[TypeOfAnalyticsType];
						EndIf;
					ElsIf TypeOfAnalyticsType = Type("CatalogRef.CashFlowReportItems") Then
						DimensionPopulationExpression = "Terms.CashFlowItem";
					Else
						DimensionPopulationExpression = StrReplace(AvailableTypesOfAnalytics[TypeOfAnalyticsType], "TableName.", "");
					EndIf;
					If StrEndsWith(DimensionPopulationExpression, ".Value") Then
						DimensionPopulationExpression = StrReplace(DimensionPopulationExpression, ".Value", "");
						DimensionPopulationExpression = StrReplace(DimensionPopulationExpression, "_", ".{DR_.") + "}";
					EndIf;
					NewRow.DimensionPopulationExpression = DimensionPopulationExpression;
					Break;
				EndIf;
			EndDo;
			If IsBlankString(DimensionPopulationExpression) Then
				NewRow.FillingMethod = Enums.MethodsOfFillingBudgetFlowItemDimensions.BySpecifiedValue;
			EndIf;
		EndIf;
	EndDo;
	
	Try
		ObjectCalculationRule.Write();
		Return ObjectCalculationRule.Ref;
	Except
		MessageText = NStr("vi = 'Không thể tạo quy tắc tính toán theo kiểu nguồn %1 và khoản mục ngân sách %2 do:%3';
							|ru = 'Не удалось сформировать правило расчета по типу источника %1 и статье бюджетов %2 по причине:%3';
							|en = 'Cannot generate a calculation rule based on the %1 source type and the %2 budget item. Reason: %3'; fa = 'Cannot generate a calculation rule based on the %1 source type and the %2 budget item. Reason: %3';
							|it = 'Cannot generate a calculation rule based on the %1 source type and the %2 budget item. Reason: %3';
							|pl = 'Cannot generate a calculation rule based on the %1 source type and the %2 budget item. Reason: %3';
							|tr = '%1 kaynak tipi ve %2 bütçe akış öğesi kapsamında hesaplama kuralı şu nedenden dolayı oluşturulamadı:%3'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(MessageText, SourceType, Receiver,
			Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndFunction

#EndRegion

#EndRegion

#EndIf