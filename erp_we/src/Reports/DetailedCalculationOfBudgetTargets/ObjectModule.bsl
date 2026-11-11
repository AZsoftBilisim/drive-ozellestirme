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
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	If Not UseMultipleCurrencies Then
		CurrencyParameter = DataCompositionSchema.Parameters.Currency;
		CurrencyParameter.IncludeInAvailableFields = False;
		CurrencyParameter.UseRestriction = True;
		ReportsServer.AttachSchema(ThisObject, ThisForm, DataCompositionSchema, "");
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	If Not UseMultipleCurrencies Then
		ReportSettings = SettingsComposer.GetSettings();
		ParameterProperties = DataCompositionClientServer.GetParameter(ReportSettings, "Currency");
		ParameterProperties.Use = True;
		ParameterProperties.Value = Constants.ManagementAccountingCurrency.Get();
	EndIf;
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	Var DocumentsCount;
	
	StandardProcessing = False;
	
	ExternalSets = DataSets();
	
	ReportSettings = SettingsComposer.GetSettings();
	ParameterValue =  ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Factor"));
	If ParameterValue = Undefined Or Not ParameterValue.Use Then
		Raise NStr("vi = 'Báo cáo này chỉ được dùng để diễn giải dữ liệu của chỉ tiêu ngân sách.';
					|ru = 'Данный отчет предназначен только для расшифровки данных показателя бюджетов.';
					|en = 'This report can only be used to drill down data of a budget balance item.'; fa = 'This report can only be used to drill down data of a budget balance item.';
					|it = 'Данный отчет предназначен только для расшифровки данных показателя бюджетов.';
					|pl = 'This report can only be used to drill down data of a budget balance item.';
					|tr = 'Mevcut rapor sadece veri bütçe dengesi kalemi deşifresi için amaçlandı.'");
	EndIf;
	
	For Each StructureItem In ReportSettings.Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings") Then
			Exceptions = New Structure("Dimension1, Dimension2, Dimension3, Dimension4, Dimension5, Dimension6, Currency");
			FinancialReportingServer.CopyFilter(ReportSettings.Filter, StructureItem.Settings.Filter, True, Exceptions);
			For Each Parameter In ReportSettings.DataParameters.Items Do
				ParameterValue =  StructureItem.Settings.DataParameters.FindParameterValue(Parameter.Parameter);
				If ParameterValue <> Undefined Then
					FillPropertyValues(ParameterValue, Parameter);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	#Region StartBackgroundReflectionOfDocumentsInBudgeting
		Period = BudgetingClientServer.ValueOfDCSSettings(SettingsComposer, "Period"); // StandardPeriod - 
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
	DataSets.Insert("Dimension", Dimension(ReportSettings));
	
	Return DataSets;
	
EndFunction

Function BalancesAtBeginning(ReportSettings, FactGettingParameters)
	
	FactGettingParameters.BalancesOnlyAtBeginningOfPeriod = True;
	FactGettingParameters.AdditionalSelection = ReportSettings;
	
	FactOnBudgetIndicators = BudgetingServer.FactOnBudgetIndicators(
		ReportSettings, 
		FactGettingParameters);
	
	If Not FactGettingParameters.Indicators.Property("Sum") Then
		FactOnBudgetIndicators.Columns.Add("Sum");
	EndIf;
	If Not FactGettingParameters.Indicators.Property("Count") Then
		FactOnBudgetIndicators.Columns.Add("Count");
	EndIf;

	Return FactOnBudgetIndicators;
	
EndFunction

Function Turnovers(ReportSettings, FactGettingParameters)
	
	FactGettingParameters.AdditionalSelection = Undefined;
	
	// We will determine the need to detail the turnover by period or registrar
	For Each StructureItem In ReportSettings.Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings")
			And StructureItem.ObjectID = "LinkedItemTurnovers" Then
			If DataCompositionClientServer.FieldUsed_(StructureItem.Settings, "Recorder") Then
				FactGettingParameters.ByRegistrar = True;
			EndIf;
			For Each Periodicity In Enums.Periodicity.OrderedPeriodicities() Do
				If Not ValueIsFilled(Periodicity) Then
					PeriodField = "Period";
				Else
					PeriodField = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
				EndIf;
				If DataCompositionClientServer.FieldUsed_(StructureItem.Settings, PeriodField) Then
					FactGettingParameters.Periodicity = Periodicity;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	FactOnBudgetItems = BudgetingServer.FactOnItemsThatAffectBudgetPerformance(
		ReportSettings, 
		FactGettingParameters, 
		True); // ValueTable
		
	If Not FactGettingParameters.Indicators.Property("Sum") Then
		FactOnBudgetItems.Columns.Add("SumCurrReceipt");
		FactOnBudgetItems.Columns.Add("SumCurrExpense");
	EndIf;
	
	If Not FactGettingParameters.Indicators.Property("Count") Then
		FactOnBudgetItems.Columns.Add("CountReceipt");
		FactOnBudgetItems.Columns.Add("CountExpense");
	EndIf;
	
	Return FactOnBudgetItems;
	
EndFunction

Function LeftoversAtEnd(ReportSettings, FactGettingParameters)
	
	FactGettingParameters.BalancesOnlyAtBeginningOfPeriod = False;
	FactGettingParameters.AdditionalSelection = ReportSettings;
	
	FactOnBudgetIndicators = BudgetingServer.FactOnBudgetIndicators(
		ReportSettings, 
		FactGettingParameters);
		
	If Not FactGettingParameters.Indicators.Property("Sum") Then
		FactOnBudgetIndicators.Columns.Add("Sum");
	EndIf;
	If Not FactGettingParameters.Indicators.Property("Count") Then
		FactOnBudgetIndicators.Columns.Add("Count");
	EndIf;

	Return FactOnBudgetIndicators;
	
EndFunction

Function Dimension(ReportSettings)
	
	Dimension = New ValueTable;
	For Each Field In DataCompositionSchema.DataSets.Find("Dimension").Fields Do
		Dimension.Columns.Add(Field.Field, Field.ValueType);
	EndDo;
	
	Return Dimension;
	
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
	
	NameOfLayoutField = "BudgetBalanceItem";
	FilterItems1 = New Array;
	BudgetReportingCacheCalculationServer.FindSelectionByName(Var_SettingsComposer.Settings, NameOfLayoutField, FilterItems1);
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
	
	Parameters.ByCompanies = True;
	Parameters.ByBusinessUnits = True;
	Parameters.DataAcquisitionRules = True;
	
	Return Parameters; 
	
EndFunction

#EndRegion

#EndRegion

#EndIf