#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	Var DocumentsCount;
	
	StandardProcessing = False;
	
	ExternalSets = DataSets();
	
	ReportSettings = SettingsComposer.GetSettings();
	
	Factor = DataCompositionClientServer.GetParameter(ReportSettings, "Factor").Value; 
	SpecifiedCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "Currency").Use;
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	If Factor = "Count"
		Or SpecifiedCurrency
		Or Not UseMultipleCurrencies Then
		DisableUsageForSelectedField(ReportSettings.Selection.Items, "Currency");
		DisableUseForDimensions(ReportSettings.Structure, "Currency");
	EndIf;
	
	BudgetingServer.AddAnalyticsPresentationExpressionsToDCS(DataCompositionSchema,
				"DataSets.Union.Fields",
				"BudgetBalanceItem");
	
	Period = DataCompositionClientServer.GetParameter(ReportSettings, "Period").Value; // StandardPeriod
	If Not ValueIsFilled(Period.EndDate) Then
		Period.EndDate = CurrentSessionDate();
	EndIf;
	
	#Region StartBackgroundReflectionOfDocumentsInBudgeting
		BeginOfPeriod = Period.StartDate;
		EndOfPeriod = Period.EndDate;
		AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
		If AuxProperties.Property("NumberOfDocumentsToBeReflectedInBudgeting") Then
			AuxProperties.Delete("NumberOfDocumentsToBeReflectedInBudgeting");
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
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	ActualBudgetingDataServer.DeduceRelevanceOfReflectionOfActualData(ResultDocument, AuxProperties,
		StartBackgroundTask);
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

#Region GettingReportData

Function DataSets()
	
	ReportSettings = SettingsComposer.GetSettings();
	FactGettingParameters = ParametersForGettingFactByReportSettings(ReportSettings);
	
	DataSets = New Structure;
	DataSets.Insert("BalancesAtBeginning", BalancesAtBeginning(ReportSettings, FactGettingParameters));
	DataSets.Insert("Turnovers", Turnovers(ReportSettings, FactGettingParameters));
	DataSets.Insert("LeftoversAtEnd", LeftoversAtEnd(ReportSettings, FactGettingParameters));
	
	Return DataSets;
	
EndFunction

Function Turnovers(ReportSettings, FactGettingParameters)
	
	FactOnBudgetItems = BudgetingServer.FactOnItemsThatAffectBudgetPerformance(
		ReportSettings, 
		FactGettingParameters); // ValueTable
	
	Currency = DataCompositionClientServer.GetParameter(ReportSettings, "Currency");
	Factor = DataCompositionClientServer.GetParameter(ReportSettings, "Factor").Value;
	RefundAmountInForeignCurrency = Not Currency.Use And Factor = "Sum";
	
	If Not RefundAmountInForeignCurrency Then
		FactOnBudgetItems.Columns.Delete("SumCurrReceipt");
		FactOnBudgetItems.Columns.Delete("SumCurrExpense");
		FactOnBudgetItems.Columns.SumReceipt.Name = "SumCurrReceipt";
		FactOnBudgetItems.Columns.SumExpense.Name = "SumCurrExpense";
	EndIf;
	
	Return FactOnBudgetItems;
	
EndFunction

Function BalancesAtBeginning(ReportSettings, FactGettingParameters)
	
	FactGettingParameters.BalancesOnlyAtBeginningOfPeriod = True;
	
	FactOnBudgetIndicators = BudgetingServer.FactOnBudgetIndicators(
		ReportSettings, 
		FactGettingParameters);
		
	Currency = DataCompositionClientServer.GetParameter(ReportSettings, "Currency");
	Factor = DataCompositionClientServer.GetParameter(ReportSettings, "Factor").Value;
	RefundAmountInForeignCurrency = Not Currency.Use And Factor = "Sum";
	
	If Not RefundAmountInForeignCurrency Then
		FactOnBudgetIndicators.Columns.Delete("AmountInCurrency");
		FactOnBudgetIndicators.Columns.Sum.Name = "AmountInCurrency";
	EndIf;
	
	Return FactOnBudgetIndicators;
	
EndFunction

Function LeftoversAtEnd(ReportSettings, FactGettingParameters)
	
	FactGettingParameters.BalancesOnlyAtBeginningOfPeriod = False;
	
	FactOnBudgetIndicators = BudgetingServer.FactOnBudgetIndicators(
		ReportSettings,
		FactGettingParameters);
		
	Currency = DataCompositionClientServer.GetParameter(ReportSettings, "Currency");
	Factor = DataCompositionClientServer.GetParameter(ReportSettings, "Factor").Value;
	RefundAmountInForeignCurrency = Not Currency.Use And Factor = "Sum";
	
	If Not RefundAmountInForeignCurrency Then
		FactOnBudgetIndicators.Columns.Delete("AmountInCurrency");
		FactOnBudgetIndicators.Columns.Sum.Name = "AmountInCurrency";
	EndIf;

	Return FactOnBudgetIndicators;
	
EndFunction

#EndRegion

#Region Other

Procedure AddParametersForCheckingDocumentReflection(AuxProperties, Var_SettingsComposer)
	//If there is a simple selection that may affect the need for a warning about non-reflected documents, then we will add the parameters.
	NameOfLayoutField = "BudgetBalanceItem";
	FilterItems1 = New Array;
	BudgetReportingCacheCalculationServer.FindSelectionByName(Var_SettingsComposer.GetSettings(), NameOfLayoutField, FilterItems1);
	If FilterItems1.Count() = 1 Then
		FilterElement = FilterItems1[0]; // DataCompositionFilterItem -
		If FilterElement.Use
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal
			And FilterElement.Parent = Undefined Then
			AuxProperties.Insert("CheckingStoredRulesAndBudgets", FilterElement.RightValue);
		EndIf;
	EndIf;
EndProcedure

Function ParametersForGettingFactByReportSettings(ReportSettings)
	
	Parameters = BudgetingServer.TemplateForGettingFactParameters();
	
	Currency = DataCompositionClientServer.GetParameter(ReportSettings, "Currency");
	If Currency.Use Then
		Parameters.ReportCurrency = Currency.Value;
	Else
		Parameters.ReportCurrency = Constants.ManagementAccountingCurrency.Get();
	EndIf;
	Parameters.FunctionalCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "FunctionalCurrency").Value;
	
	Factor = DataCompositionClientServer.GetParameter(ReportSettings, "Factor").Value;
	Parameters.Indicators = New Structure(Factor);
	
	Parameters.Period = DataCompositionClientServer.GetParameter(ReportSettings, "Period").Value;
	If Not ValueIsFilled(Parameters.Period.EndDate) Then
		Parameters.Period.EndDate = CurrentSessionDate();
	EndIf;
	
	Parameters.ByCompanies = True;
	Parameters.ByBusinessUnits = True;
	
	Return Parameters;
	
EndFunction

Procedure DisableUsageForSelectedField(SelectionElements, FieldName)
	
	For Each ChoiceItem In SelectionElements Do
		
		LayoutField = New DataCompositionField(FieldName);
		If TypeOf(ChoiceItem) = Type("DataCompositionSelectedField") Then
			If ChoiceItem.Field = LayoutField Then
				ChoiceItem.Use = False;
			EndIf;
		ElsIf TypeOf(ChoiceItem) = Type("DataCompositionSelectedFieldGroup") Then
			DisableUsageForSelectedField(ChoiceItem.Items, FieldName);
		Else
			Continue;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DisableUseForDimensions(Structure, GroupName)
	
	For Each StructureItem In Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionGroup") Then
			LayoutField = New DataCompositionField(GroupName);
			For Each GroupingField In StructureItem.GroupFields.Items Do
				If TypeOf(GroupingField) = Type("DataCompositionGroupField")
					And GroupingField.Field = LayoutField Then
					GroupingField.Use = False;
				EndIf;
			EndDo;
			DisableUsageForSelectedField(StructureItem.Selection.Items, GroupName);
			DisableUseForDimensions(StructureItem.Structure, GroupName);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

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
		ThisForm.ParametersForm.Filter.Insert("BudgetBalanceItem", Parameters.CommandParameter);
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