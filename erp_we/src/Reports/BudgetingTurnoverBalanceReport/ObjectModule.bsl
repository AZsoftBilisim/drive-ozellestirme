#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	If Not FormSettingsComposer.Settings.AdditionalProperties.Property("CurrentVariantKey") Then
		FormSettingsComposer.Settings.AdditionalProperties.Insert("CurrentVariantKey", ThisForm.CurrentVariantKey);
	EndIf;
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	If ThisForm.CurrentVariantKey = "Details" Then
		
		FormSettingsComposer = ThisForm.Report.SettingsComposer; // DataCompositionSettingsComposer -
		FixedSettings = FormSettingsComposer.FixedSettings;
		
		AddSource_1 = FixedSettings.Structure;
		PlaceAdded = FormSettingsComposer.Settings.Structure;
		PlaceAdded.Clear();
		
		While AddSource_1.Count() Do
			Group = AddSource_1[0];
			NewGrouping = FinancialReportingServer.NewGrouping(PlaceAdded, Group.Name,, False);
			For Each GroupingField In Group.GroupFields.Items Do
				FinancialReportingServer.NewDimensionField(
					NewGrouping,
					String(GroupingField.Field),
					GroupingField.GroupType);
			EndDo;
			PlaceAdded = NewGrouping.Structure;
			AddSource_1 = Group.Structure;
		EndDo;
		
		If FixedSettings.Selection.Items.Count() > 0 Then
			DataCompositionClientServer.CopyElements(FormSettingsComposer.Settings.Selection, FixedSettings.Selection, True);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	Var DocumentsCount;
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	ExternalSets = DataSets();
	
	BudgetingServer.AddDCSAnalyticsByType(DataCompositionSchema, "BudgetFlowItem");
	
	BudgetingServer.AddAnalyticsPresentationExpressionsToDCS(DataCompositionSchema,
			"DataSets.TurnoverDimension.Fields",
			"BudgetFlowItem");
	
	#Region StartBackgroundReflectionOfDocumentsInBudgeting
		Period = BudgetingClientServer.ValueOfDCSSettings(SettingsComposer, "Period"); // StandardPeriod -
		BeginOfPeriod = Period.StartDate;
		EndOfPeriod = Period.EndDate;
		AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
		If AuxProperties.Property("NumberOfDocumentsToBeReflectedInBudgeting") Then
			AuxProperties.Delete("NumberOfDocumentsToBeReflectedInBudgeting");
			UserSettingsModified = True;
		EndIf;
		StartBackgroundTask = False;
		If InformationRegisters.JobsForPostingInBudgeting.RequiredReflectionInBudgetingForReportForPeriod(
		BeginOfPeriod, EndOfPeriod, DocumentsCount, StartBackgroundTask) Then
			
			If StartBackgroundTask Then
				ActualBudgetingDataServer.ReflectDocumentsAsBackgroundTask(BeginOfPeriod, EndOfPeriod);
			EndIf;
			AuxProperties.Insert("NumberOfDocumentsToBeReflectedInBudgeting", DocumentsCount);
			AuxProperties.Insert("BeginOfPeriod", BeginOfPeriod);
			AuxProperties.Insert("EndOfPeriod", EndOfPeriod);
			
			AddParametersForCheckingDocumentReflection(AuxProperties, SettingsComposer);
			
		EndIf;
	#EndRegion
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema,
				SettingsComposer.GetSettings(),
				DetailsData);
	
	AdjustRelationshipsOfLayoutTemplateDataSets(CompositionTemplate);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	ActualBudgetingDataServer.DeduceRelevanceOfReflectionOfActualData(ResultDocument, AuxProperties,
		StartBackgroundTask);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

Procedure AdjustRelationshipsOfLayoutTemplateDataSets(CompositionTemplate)
	
	For Each LinkingDatasets In CompositionTemplate.DataSetLinks Do
		
		If LinkingDatasets.SourceDataSet = "TurnoverDimension"
			And LinkingDatasets.DestinationDataSet = "BudgetFlowItems" Then
			LinkingDatasets.LinkType = DataCompositionDataSetsLinkType.Inner;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region GettingReportData

Function DataSets()
	
	ReportSettings = SettingsComposer.GetSettings();
	FactGettingParameters = ParametersForGettingFactByReportSettings(ReportSettings);
	
	DataSets = New Structure;
	DataSets.Insert("TurnoversPlan", TurnoversPlan(ReportSettings));
	TurnoverFact = TurnoverFact(ReportSettings, FactGettingParameters);
	DataSets.Insert("TurnoverFact", TurnoverFact);
	FilterStructure1 = New Structure("Scenario", Catalogs.BudgetingScenarios.ActualData);
	DataSets.Insert("TurnoversAreJustFact", TurnoverFact.Copy(FilterStructure1));
	
	Return DataSets;
	
EndFunction

Function TurnoversPlan(ReportSettings)
	
	LayoutSchemeOfPlan = Reports.BudgetingTurnoverBalanceReport.GetTemplate("TurnoversPlan");
	Settings = LayoutSchemeOfPlan.DefaultSettings;
	
	BudgetingServer.AddDCSAnalyticsByType(LayoutSchemeOfPlan, "BudgetFlowItem");
	
	Set = LayoutSchemeOfPlan.DataSets.Plan;
	
	ExpressionParameters = BudgetingServer.TemplateForAnalyticsFieldParametersWithConditionForNumberOfAnalyticsTypes();
	ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "BudgetTurnovers.BudgetFlowItem.NumberOfUsedDimensions";
	ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "BudgetTurnovers.Dimension";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		Set.Query = StrReplace(Set.Query, "&AnalystSExpression" + DimensionNumber,
			BudgetingServer.TextOfAnalyticsFieldWithConditionForNumberOfTypesOfAnalytics(ExpressionParameters, DimensionNumber));
	EndDo;
	
	DataCompositionClientServer.FillInElements(Settings.DataParameters, ReportSettings.DataParameters);
	DataCompositionClientServer.CopyDataCompositionFilter(LayoutSchemeOfPlan, Settings, ReportSettings);
	
	Group = Settings.Structure[0];
	
	If DataCompositionClientServer.FieldUsed_(ReportSettings, "Recorder", True) Then
		FinancialReportingServer.NewDimensionField(Group, "Recorder");
	EndIf;
	
	For Each Periodicity In Enums.Periodicity.OrderedPeriodicities() Do
		If Not ValueIsFilled(Periodicity) Then
			PeriodField = "Period";
		Else
			PeriodField = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		EndIf;
		If DataCompositionClientServer.FieldUsed_(ReportSettings, PeriodField, True) Then
			FinancialReportingServer.NewDimensionField(Group, PeriodField);
		EndIf;
	EndDo;
	
	If DataCompositionClientServer.FieldUsed_(ReportSettings, "UpdateDate", True) Then
		FinancialReportingServer.NewDimensionField(Group, "UpdateDate");
	EndIf;
	
	ReportCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "Currency").Value;
	FunctionalCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "FunctionalCurrency").Value;
	
	If FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_ Then
		If ReportCurrency = Constants.ManagementAccountingCurrency.Get() Then
			SumExpression = "SumMan";
		Else
			SumExpression = "
			|CASE
			|	WHEN Currency = &Currency THEN
			|		AmountInCurrency
			|	ELSE
			|		SumMan * RelativeRateOfManAccounting / RelativeExchangeRateBaseCurrencyOfManScenarioAccounting * ISNULL(ForecastRate, 1)
			|END
			|";
		EndIf;
	ElsIf FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal Then
		SumExpression = "
		|CASE
		|	WHEN LocalAccountingCurrency = &Currency THEN
		|		SumCompl
		|	ELSE
		|		CASE
		|			WHEN Currency = &Currency THEN
		|				AmountInCurrency
		|			ELSE
		|				SumCompl / RelativeExchangeRateBaseCurrencyOfLocalAccountingScenario * ISNULL(ForecastRate, 1)
		|		END
		|END
		|";
	Else
		SumExpression = "0";
	EndIf;
	
	Resources = New Structure;
	Resources.Insert("SumPlan", SumExpression);
	Resources.Insert("CountPlan", "Count");
	For Each Resource In Resources Do
		FinancialReportingServer.NewCalculatedResource(LayoutSchemeOfPlan, Resource.Key, Resource.Value, "Sum");
		FinancialReportingServer.NewSelectionField(Settings, Resource.Key);
	EndDo;
	
	Plan = FinancialReportingServer.UploadDCSResults(LayoutSchemeOfPlan, Settings);
	
	Return Plan;
	
EndFunction

Function TurnoverFact(ReportSettings, FactGettingParameters)
	
	NeedToObtainFact = True;
	If ReportSettings.AdditionalProperties.Property("VariantKey")
		And ReportSettings.AdditionalProperties.VariantKey = "Details" Then
		NeedToObtainFact = AvailabilityOfActualDataInScriptReportSettings(ReportSettings);
	EndIf;
	
	If Not NeedToObtainFact Then
		FactOnBudgetItems = New ValueTable;
		DataSetFact = DataCompositionSchema.DataSets.TurnoverFact;
		For Each LayoutField In DataSetFact.Fields Do
			FactOnBudgetItems.Columns.Add(String(LayoutField.Field), LayoutField.ValueType);
		EndDo;
		If FactOnBudgetItems.Columns.Find("Scenario") = Undefined Then
			FactOnBudgetItems.Columns.Add("Scenario", New TypeDescription("CatalogRef.BudgetingScenarios"));
		EndIf;
	Else
		DataCompositionClientServer.DeleteSelection(ReportSettings.Filter, "Scenario");
		FactOnBudgetItems = BudgetingServer.FactOnBudgetItems(ReportSettings, FactGettingParameters); // ValueTable - 
		
		If ValueIsFilled(FactGettingParameters.Periodicity) Then
			FactOnBudgetItems.Columns["Period"].Name =  FinancialReportingClientServer.PeriodStrings(FactGettingParameters.Periodicity).Period;
		EndIf;
		If FactGettingParameters.ThereIsPeriodicityOfSecond Then
			FactOnBudgetItems.Columns["SecondPeriod"].Name = "UpdateDate";
		EndIf;
		
		DataSetFact = DataCompositionSchema.DataSets.TurnoverFact;
		For Each DataSetField In DataSetFact.Fields Do
			If FactOnBudgetItems.Columns.Find(DataSetField.Field) <> Undefined Then
				Continue;
			EndIf;
			FactOnBudgetItems.Columns.Add(DataSetField.Field, DataSetField.ValueType);
		EndDo;
	EndIf;
	
	Return FactOnBudgetItems;
	
EndFunction

#EndRegion

#Region Other

Procedure AddParametersForCheckingDocumentReflection(AuxProperties, Var_SettingsComposer)
	//If there is a simple selection that may affect the need for a warning about non-reflected documents, then we will add the parameters.
	NameOfLayoutField = "BudgetFlowItem";
	FilterItems1 = New Array;
	BudgetReportingCacheCalculationServer.FindSelectionByName(Var_SettingsComposer.GetSettings(), NameOfLayoutField, FilterItems1);
	If FilterItems1.Count() = 1 Then
		FilterElement = FilterItems1[0]; // DataCompositionFilterItem -
		If FilterElement.Use
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal
			And FilterElement.Parent = Undefined Then
			AuxProperties.Insert("CheckingStoredRulesAndBudgets_", FilterElement.RightValue);
		EndIf;
	EndIf;
EndProcedure

Function AvailabilityOfActualDataInScriptReportSettings(ReportSettings)
	
	SchemaOfReportScript = DataCompositionServer.EmptyCircuit();
	DataSetScenarios = DataCompositionServer.AddEmptyDataSet(SchemaOfReportScript,
		Type("DataCompositionSchemaDataSetQuery"),
		"BudgetingScenarios");
	
	DataSetScenarios.Query = 
	"SELECT ALLOWED
	|	BudgetingScenarios.Ref AS Scenario
	|FROM
	|	Catalog.BudgetingScenarios AS BudgetingScenarios
	|WHERE
	|	BudgetingScenarios.Ref IN (VALUE(Catalog.BudgetingScenarios.ActualData), VALUE(Catalog.BudgetingScenarios.BudgetFulfillment))";
	
	FinancialReportingServer.NewSetField(DataSetScenarios, "Scenario", "Scenario",, New TypeDescription("CatalogRef.BudgetingScenarios"));
	
	ScriptSettings = New DataCompositionSettings;
	DataCompositionClientServer.AddGrouping(ScriptSettings);
	DataCompositionClientServer.AddSelectedField(ScriptSettings, "Scenario");
	
	DataCompositionClientServer.CopyDataCompositionFilter(SchemaOfReportScript, ScriptSettings, ReportSettings);
	
	BudgetingScenarios = FinancialReportingServer.UploadDCSResults(SchemaOfReportScript, ScriptSettings);
	
	Return BudgetingScenarios.Count() > 0;
	
EndFunction

Function ParametersForGettingFactByReportSettings(ReportSettings)
	
	Parameters = BudgetingServer.TemplateForGettingFactParameters();
	
	Parameters.ReportCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "Currency").Value;
	Parameters.FunctionalCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "FunctionalCurrency").Value;
	Parameters.Period = DataCompositionClientServer.GetParameter(ReportSettings, "Period").Value;
	
	Parameters.ByCompanies = True;
	Parameters.ByBusinessUnits = True;
	
	If DataCompositionClientServer.FieldUsed_(ReportSettings, "Recorder") Then
		Parameters.ByRegistrar = True;
	EndIf;
	
	Periodicity_ = New Array;
	For Each Periodicity In Enums.Periodicity.OrderedPeriodicities() Do
		If Not ValueIsFilled(Periodicity) Then
			PeriodField = "Period";
		Else
			PeriodField = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		EndIf;
		If DataCompositionClientServer.FieldUsed_(ReportSettings, PeriodField) Then
			Periodicity_.Add(Periodicity);
		EndIf;
	EndDo;
	Parameters.Periodicity = BudgetReportingClientServer.MinimumPeriodicity(Periodicity_);
	
	ThereIsPeriodicityOfSecond = DataCompositionClientServer.FieldUsed_(ReportSettings,
			"UpdateDate",
			True);
	Parameters.Insert("ThereIsPeriodicityOfSecond", ThereIsPeriodicityOfSecond);
	
	Return Parameters; 
	
EndFunction

Procedure SetRequiredSettings(UserSettingsModified)
	
	CurrencyCustomParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Currency");
	CurrencyFixedParameter = DataCompositionClientServer.GetParameter(SettingsComposer.FixedSettings, "Currency");
	
	ThereIsCurrency = CurrencyCustomParameter <> Undefined And ValueIsFilled(CurrencyCustomParameter.Value);
	If Not ThereIsCurrency Then
		ThereIsCurrency = CurrencyFixedParameter <> Undefined And ValueIsFilled(CurrencyFixedParameter.Value);
	EndIf;
	
	If Not ThereIsCurrency Then
		DataCompositionClientServer.SetParameter(
			SettingsComposer, "Currency", Constants.ManagementAccountingCurrency.Get());
		UserSettingsModified = True;
	Else
		UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
		If Not UseMultipleCurrencies Then
			CurrencyValue = ?(CurrencyCustomParameter = Undefined, Undefined, CurrencyCustomParameter.Value);
			If Not ValueIsFilled(CurrencyValue) Then
				CurrencyValue = ?(CurrencyFixedParameter = Undefined, Undefined, CurrencyFixedParameter.Value);
			EndIf;
			CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
			If CurrencyValue <> CurrencyOfMan Then
				DataCompositionClientServer.SetParameter(
					SettingsComposer, "Currency", CurrencyOfMan);
				UserSettingsModified = True;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		ThisForm.ParametersForm.Filter.Insert("BudgetFlowItem", Parameters.CommandParameter);
	EndIf;
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	If Not UseMultipleCurrencies Then
		CurrencyParameter = DataCompositionSchema.Parameters.Currency;
		CurrencyParameter.IncludeInAvailableFields = False;
		CurrencyParameter.UseRestriction = True;
		ReportsServer.AttachSchema(ThisObject, ThisForm, DataCompositionSchema, "");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
