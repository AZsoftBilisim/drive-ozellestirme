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
	
	Settings.EditOptionsAllowed = False;
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
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
		
		Date = GeneralPurposeTMServerCall.ObjectAttributeValue(Parameters.CommandParameter, "RequiredPaymentDate");
	
		ThisForm.ParametersForm.Filter.Insert("Date", Date);
		ThisForm.ParametersForm.Filter.Insert("Document", Parameters.CommandParameter);
		
	EndIf;
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	If Not UseMultipleCurrencies Then
		CurrencyParameter = DataCompositionSchema.Parameters.Find("Currency");
		ReportOutputParameter = DataCompositionSchema.Parameters.Find("ReportOutput");
		CurrencyParameter.UseRestriction = True;
		CurrencyParameter.Use = DataCompositionParameterUse.Always;
		CurrencyParameter.Value = Constants.ManagementAccountingCurrency.Get();
		CurrencyParameter.DenyIncompleteValues = False;
		CurrencyParameter.IncludeInAvailableFields = False;
		ReportOutputParameter.UseRestriction = True;
		ReportOutputParameter.Use = DataCompositionParameterUse.Auto;
		ReportOutputParameter.Value = 1;
		ReportsServer.AttachSchema(ThisObject, ThisForm, DataCompositionSchema, "");
	EndIf;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//   For example, if the report schema depends on the option key or report parameters.
//   For schema changes to take effect, call the ReportServer method.Connect the circuit().
//
// Parameters:
//   Context - Arbitrary - 
//       Parameters of the context in which the report is used.
//       Used for passing the ReportServer method parameters.Connect the circuit().
//   SchemaKey - String -
//       ID of the current configuration Builder schema.
//       By default, it is empty (this means that the linker is initialized based on the main schema).
//       Used for optimization to reinitialize the linker as rarely as possible).
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       Name of the predefined or unique ID of the custom version of the report.
//       Undefined when calling for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Builder after it is initialized.
//       Undefined when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the Settings Composer after it is initialized.
//       It is uncertain when user settings do not need to be loaded (already loaded earlier).
//
// Examples:
// 1. The Composer of the report is initialized based on the scheme from the general Templates:
//	If the key of the scheme <> is "1" Then
//		Schema Key = "1";
//		SCHEMACD = Get a Public package("My Public Schemacompositions");
//		Server report.Connect a schema(This is an Object, Context, Schema, Schema Key);
//	The end if;
//
// 2. The scheme depends on the value of the parameter displayed in the user settings of the report:
//	If the type of ID is(New usersenastroykid) = Type("Custom setups of Data components") Then
//		Full Data objectName = "";
//		For Each Cd element From The New Userenastroykid.Elements of the Cycle
//			If the type of ID is (CD element) = Type("Parameter setter values") Then
//				Parameter Name = String(element).Parameter);
//				If Parameter Name = "Data objectmethod" Then
//					Full Data objectName = Data element.Value;
//				The end if;
//			The end if;
//		The end of the cycle;
//		If the Schema key <> is the full Data objectName, then
//			Schema Key = Full Data objectname;
//			Schemacd = New schemacomposedata;
//			Filling in the schema...
//			Server report.Connect a schema(This is an Object, Context, Schema, Schema Key);
//		The end if;
//	The end if;
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If VariantKey = "UseOfCashFlowLimitsContext" Then
		CurrencyParameter = DataCompositionSchema.Parameters.Find("Currency");
		CurrencyParameter.Use = DataCompositionParameterUse.Auto;
		
		ReportOutputParameter = DataCompositionSchema.Parameters.Find("ReportOutput");
		ReportOutputParameter.UseRestriction = True;
		ReportOutputParameter.Use = DataCompositionParameterUse.Auto;
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	#Region SettingRequiredParameters
	
	DocumentParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Document");
	DateParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Date");
	
	// Processing of the "Date" parameter
	AttributesOfApplication = New Structure("Date, RequiredPaymentDate, Currency, BusinessOperation");
	If ValueIsFilled(DocumentParameter.Value) Then
		If TypeOf(DocumentParameter.Value) = Type("DocumentRef.ApplicationForBusinessTrip") Then
			AttributesOfApplication = Common.ObjectAttributesValues(DocumentParameter.Value,
				"Date, RequiredPaymentDate, Currency");
			AttributesOfApplication.Insert("BusinessOperation",
				Enums.BusinessTransactions.IssueCashToAdvanceHolder);
		Else
			AttributesOfApplication = Common.ObjectAttributesValues(DocumentParameter.Value,
				"Date, RequiredPaymentDate, Currency, BusinessOperation");
		EndIf;
		If ValueIsFilled(AttributesOfApplication.RequiredPaymentDate) Then
			DateUsed = AttributesOfApplication.RequiredPaymentDate;
		Else 
			DateUsed = AttributesOfApplication.Date;
		EndIf;
	Else
		If TypeOf(DateParameter.Value) = Type("StandardBeginningDate") Then
			DateUsed = DateParameter.Value.Date;
		ElsIf TypeOf(DateParameter.Value) = Type("Date") Then
			DateUsed = DateParameter.Value;
		Else
			DateUsed = CurrentSessionDate();
		EndIf;
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "CacheOfSubmittedInformation", New Map, True);
	DataCompositionClientServer.SetParameter(SettingsComposer, "Date", DateUsed, True);
	UserSettingsModified = True;
	
	ReportOutputParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportOutput");
	CurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Currency");
	
	OutputAnalyticsField = New DataCompositionField("DataParameters.OutputAnalytics");
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		If FilterElement.LeftValue = OutputAnalyticsField Then
			// The service field for the report structure is disabled during decryption.
			FilterElement.Use = False;
		EndIf;
	EndDo;
	
	// Currency Processing
	If ReportOutputParameter.Value = 0 Then // In the currency of the document
		CurrencyParameter.Value = AttributesOfApplication.Currency;
		
		UserSettingsModified = True;
	Else
		If Not ValueIsFilled(CurrencyParameter.Value) Then
			DataCompositionClientServer.SetParameter(
				SettingsComposer, "Currency", Constants.ManagementAccountingCurrency.Get());
			
			UserSettingsModified = True;
		EndIf;
	EndIf;
	
	DataCompositionClientServer.SetParameter(
		SettingsComposer, "ExplanationModeByRecorder", False);
	
	#EndRegion 
	
	VerificationDates = New ValueTable;
	VerificationDates.Columns.Add("LimitDate", New TypeDescription("Date"));
	VerificationDates.Columns.Add("LimitedTransaction", New TypeDescription("EnumRef.LimitedTransactions"));
	NewRow = VerificationDates.Add();
	NewRow.LimitDate = DateUsed;
	NewRow.LimitedTransaction = Enums.LimitedTransactions.FlowOfCash;
	Parameters = New Structure("VerificationDates, DocumentKind, BusinessOperation", VerificationDates,
		Catalogs.MetadataObjectIDs.EmptyRef(), Enums.BusinessTransactions.EmptyRef());
	If ValueIsFilled(DocumentParameter.Value) Then
		Parameters.DocumentKind = Common.MetadataObjectID(TypeOf(DocumentParameter.Value));
		Parameters.BusinessOperation = AttributesOfApplication.BusinessOperation;
	EndIf;
	Parameters.Insert("LimitedTransactions", CommonClientServer.ValueInArray(Enums.LimitedTransactions.FlowOfCash));
	DateLimitSettings = LimitsByBudgetingDataServer.LimitSettingsForVerificationDates(Parameters);
	LimitsEffectiveAsOfDate = DateLimitSettings.LimitSettingsByValidityPeriod[0].ConfigureLimitRules;
	
	ExternalSets = New Structure("CashFlowLimits, CurrentLimits");
	
	If LimitsEffectiveAsOfDate.Count() > 0
		And Not LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Then
		
		Parameters.Insert("Document", DocumentParameter.Value);
		Parameters.Insert("Currency", CurrencyParameter.Value);
		Parameters.Insert("LimitedTransactions", CommonClientServer.ValueInArray(Enums.LimitedTransactions.FlowOfCash));
		
		FilterDecryptions = GetTranscriptSelectionToRetrieveData(SettingsComposer);
		LimitReductionPlan = LimitsByBudgetingDataServer.LimitReductionPlan(Parameters, FilterDecryptions);
		Data = ConvertFactPlanOfLimitsForOutputToReport(LimitReductionPlan, FilterDecryptions);
		
		If FilterDecryptions.DecryptionByRegistrar Then
			DataCompositionClientServer.SetParameter(
				SettingsComposer, "ExplanationModeByRecorder", True);
		EndIf;
		
		If Data.Count() > 0 Then
			ExternalSets.CashFlowLimits = Data;
		Else
			CashFlowLimitsEmpty = New ValueTable;
			For Each DataSetField In DataCompositionSchema.DataSets.CashFlowLimits.Fields Do 
				CashFlowLimitsEmpty.Columns.Add(DataSetField.Field, DataSetField.ValueType, DataSetField.Title);
			EndDo;
			
			ExternalSets.CashFlowLimits = CashFlowLimitsEmpty;
		EndIf;
			
		ExternalSets.CurrentLimits = LimitsEffectiveAsOfDate.LimitRules;
	Else
		CurrentLimitsAreEmpty = New ValueTable;
		For Each DataSetField In DataCompositionSchema.DataSets.CurrentLimits.Fields Do 
			CurrentLimitsAreEmpty.Columns.Add(DataSetField.Field, DataSetField.ValueType, DataSetField.Title);
		EndDo;
		
		ExternalSets.CurrentLimits = CurrentLimitsAreEmpty;
			CashFlowLimitsEmpty = New ValueTable;
			For Each DataSetField In DataCompositionSchema.DataSets.CashFlowLimits.Fields Do 
				CashFlowLimitsEmpty.Columns.Add(DataSetField.Field, DataSetField.ValueType, DataSetField.Title);
			EndDo;
			
		ExternalSets.CashFlowLimits = CashFlowLimitsEmpty;
	EndIf;
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	Var Errors;
	
	// Currency Processing
	ReportOutputParameter	= DataCompositionClientServer.GetParameter(SettingsComposer, "ReportOutput");
	DocumentParameter	= DataCompositionClientServer.GetParameter(SettingsComposer, "Document");
	CurrencyParameter		= DataCompositionClientServer.GetParameter(SettingsComposer, "Currency");
	
	If ReportOutputParameter.Value = 0 
		And Not ValueIsFilled(DocumentParameter.Value) Then // In the currency of the document
		
		CommonClientServer.AddUserError(Errors, 
			"Document", 
			NStr("vi = 'Chưa điền trường ""Hạn mức áp dụng cho chứng từ"".';
				|ru = 'Не заполнено поле ""Лимиты, применяемые для документа"".';
				|en = '""Limits applied for the document"" is not filled in.'; fa = '""Limits applied for the document"" is not filled in.';
				|it = 'Il campo ""Limiti applicati al documento"" non è compilato.';
				|pl = 'Pole ""Limity zastosowane do dokumentu"" nie jest wypełnione.';
				|tr = '""Belge için geçerli sınırlar"" alanı doldurulmamış.'"),
			""); 
		
	ElsIf ReportOutputParameter.Value = 1
		And GetFunctionalOption("UseMultipleCurrencies")
		And Not ValueIsFilled(CurrencyParameter.Value) Then // In the currency
		
		CommonClientServer.AddUserError(Errors, 
			"Currency", 
			NStr("vi = 'Chưa điền trường ""Tiền tệ"".';
				|ru = 'Не заполнено поле ""Валюта"".';
				|en = '""Currency"" is not filled in.'; fa = '""Currency"" is not filled in.';
				|it = 'Il campo ""Valuta"" non è compilato.';
				|pl = 'Pole ""Waluta"" nie jest wypełnione.';
				|tr = '""Para birimi"" alanı doldurulmadı.'"),
			""); 
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
EndProcedure

#EndRegion

#Region Private

Function GetTranscriptSelectionToRetrieveData(Var_SettingsComposer)
	
	Settings = Var_SettingsComposer.Settings;
	
	SelectionForPlanets = New Structure;
	SelectionForPlanets.Insert("UseFilter1", False);
	SelectionForPlanets.Insert("DecryptionByRegistrar", False);
	
	ThereIsSelectionAccordingToRuleOfLimits = False;
	ThereAreSelectionsForAnalytics = False;
	If Settings.Filter.Items.Count() = 0 Then
		// Decryption by the registrar is possible only if there is a selection according to the limits rule.
		Return SelectionForPlanets;
	EndIf;
	
	SelectionValuesForAnalytics = New ValueTable;
	SelectionValuesForAnalytics.Columns.Add("LayoutField");
	SelectionValuesForAnalytics.Columns.Add("NumberOfAnalyticsInHierarchy");
	SelectionValuesForAnalytics.Columns.Add("Used", New TypeDescription("Boolean"));
	SelectionValuesForAnalytics.Columns.Add("FactAnalysis", New TypeDescription("Boolean"));
	SelectionValuesForAnalytics.Columns.Add("Value");
	
	MaximumNumberOfAnalystsInLimits = BudgetingClientServer.MaximumNumberOfAnalysts() + 2;
	For DimensionNumber = 1 To MaximumNumberOfAnalystsInLimits Do
		NewRow = SelectionValuesForAnalytics.Add();
		NewRow.LayoutField = New DataCompositionField("Dimension" + DimensionNumber);
		NewRow.NumberOfAnalyticsInHierarchy = DimensionNumber;
		
		NewRow = SelectionValuesForAnalytics.Add();
		NewRow.LayoutField = New DataCompositionField("Dimension" + DimensionNumber + "Real");
		NewRow.NumberOfAnalyticsInHierarchy = DimensionNumber;
		NewRow.FactAnalysis = True;
	EndDo;
	
	If Settings.Filter.Items.Count() > 0 Then
		SelectionForPlanets.UseFilter1 = True;
		
		For Each FilterElement In Settings.Filter.Items Do
			If Not FilterElement.Use Then
				Continue;
			EndIf;
			If FilterElement.LeftValue = New DataCompositionField("BudgetingModel") Then
				SelectionForPlanets.Insert("BudgetingModel", FilterElement.RightValue);
				SelectionForPlanets.UseFilter1 = True;
			EndIf;
			If FilterElement.LeftValue = New DataCompositionField("LimitsRule") Then
				SelectionForPlanets.Insert("LimitsRule", FilterElement.RightValue);
				ThereIsSelectionAccordingToRuleOfLimits = True;
			EndIf;
			AnalyticsSelectionString = SelectionValuesForAnalytics.Find(FilterElement.LeftValue, "LayoutField");
			If Not AnalyticsSelectionString = Undefined Then
				ThereAreSelectionsForAnalytics = True;
				AnalyticsSelectionString.Used = True;
				AnalyticsSelectionString.Value = FilterElement.RightValue;
				SelectionForPlanets.UseFilter1 = True;
			EndIf;
		EndDo;
	EndIf;
	
	// Fact analysts are displayed only when the fact exists,
	// and there may not be values for the plan analysts. Therefore, in order to correctly calculate
	// the plan fact, it is necessary to exclude the last empty analysts from the selection
	// (up to the first one from the end of the completed analysis). If the plan analytics is filled in, it means
	// that there is an entry in the budget turnover for this analytics value. If it is not filled in, then there may be no record,
	// and it is necessary to get a plan with some excess for the correctness of the calculation.
	DisabledPlanSelection = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalystsInLimits Do
		AnalyticsNumberFromEnd = MaximumNumberOfAnalystsInLimits - DimensionNumber + 1;
		SelectionStringPlan = SelectionValuesForAnalytics.FindRows(New Structure("NumberOfAnalyticsInHierarchy, FactAnalysis", AnalyticsNumberFromEnd, False));
		If SelectionStringPlan.Count() Then
			If SelectionStringPlan[0].Used
				And ValueIsFilled(SelectionStringPlan[0].Value) Then
				Break;
			Else
				DisabledPlanSelection.Add(SelectionStringPlan[0]);
			EndIf;
		EndIf;
	EndDo;
	For Each FIlterRow In DisabledPlanSelection Do
		FIlterRow.Used = False;
	EndDo;
	
	If ThereAreSelectionsForAnalytics And ThereIsSelectionAccordingToRuleOfLimits Then
		// In the report, the analysts are arranged according to the hierarchy specified in the limits rule.
		// We will get the hierarchy settings for transferring selection by report analytics to selection by dimensions (analysts) of the plan and fact.
		
		SelectionByPlanAnalysts = New Array;
		SelectionByAnalystsReal = New Array;
		
		LimitRules = New Array;
		LimitRules.Add(SelectionForPlanets.LimitsRule);
		
		HierarchyByRules = Catalogs.BudgetingLimits.HierarchyOfAnalyticsByRulesWithSourceColumns(
			LimitRules);
		
		DimensionsHierarchy = HierarchyByRules.Get(SelectionForPlanets.LimitsRule);
		For Each AnalyticsSelectionString In SelectionValuesForAnalytics Do
			If Not AnalyticsSelectionString.Used Then
				Continue;
			EndIf;
			HierarchyLine = DimensionsHierarchy.Find(AnalyticsSelectionString.NumberOfAnalyticsInHierarchy, "NumberInHierarchyAmongThoseUsed");
			If Not HierarchyLine = Undefined Then
				DimensionNameAnalyticsNumber = HierarchyLine.PathToAnalytics;
				MeasurementViewAnalytics = HierarchyLine.MeasurementViewAnalytics;
				FilterElement = New Structure;
				FilterElement.Insert("DimensionNameAnalyticsNumber", DimensionNameAnalyticsNumber);
				FilterElement.Insert("MeasurementViewAnalytics", MeasurementViewAnalytics);
				FilterElement.Insert("Value", AnalyticsSelectionString.Value);
				
				If AnalyticsSelectionString.FactAnalysis Then
					SelectionByAnalystsReal.Add(FilterElement);
				Else
					SelectionByPlanAnalysts.Add(FilterElement);
				EndIf;
			EndIf;
		EndDo;
		
		If SelectionByPlanAnalysts.Count() > 0 Then
			SelectionForPlanets.Insert("SelectionByPlanAnalysts", SelectionByPlanAnalysts);
		EndIf;
		If SelectionByAnalystsReal.Count() > 0 Then
			SelectionForPlanets.Insert("SelectionByAnalystsReal", SelectionByAnalystsReal);
		EndIf;
	EndIf;
	If Settings.Structure.Count() > 0 Then
		StructureItem = Settings.Structure[0];
		GroupFields = Undefined;
		If TypeOf(StructureItem) = Type("DataCompositionGroup") Then
			GroupFields = StructureItem.GroupFields.Items;
		ElsIf TypeOf(StructureItem) = Type("DataCompositionTable") Then
			If StructureItem.Rows.Count() > 0 Then
				GroupFields = StructureItem.Rows[0].GroupFields.Items;
			EndIf;
		EndIf;
		If Not GroupFields = Undefined
			And GroupFields.Count() = 1
			And GroupFields[0].Field = New DataCompositionField("Recorder") Then
			
			If ThereIsSelectionAccordingToRuleOfLimits Then
				SelectionForPlanets.DecryptionByRegistrar = True;
			Else
				MessageText = NStr("vi = 'Việc giải mã theo nhà đăng ký chỉ có thể được sử dụng trong khuôn khổ của quy tắc giới hạn.';
									|ru = 'Расшифровка по регистратору может использоваться только в рамках правила лимитов.';
									|en = 'Drill-down by recorder can only be used within the limit rule.'; fa = 'Drill-down by recorder can only be used within the limit rule.';
									|it = 'La decodifica per il registratore può essere utilizzata solo all''interno delle regole relative ai limiti.';
									|pl = 'Szczegóły płatności według rejestratora mogą być używane tylko w ramach zasady limitów.';
									|tr = 'Kayda göre deşifre sadece kural kısıtlamaları dahilinde kullanılabilir.'");
				Raise MessageText;
			EndIf;
		EndIf;
	EndIf;
	Return SelectionForPlanets;
	
EndFunction

Function ConvertFactPlanOfLimitsForOutputToReport(LimitReductionPlan, FilterDecryptions)
	
	If LimitReductionPlan.Count() > 0 Then
		LimitRulesUsed = LimitReductionPlan.UnloadColumn("LimitsRule");
		LimitRulesUsed = CommonClientServer.CollapseArray(LimitRulesUsed);
		
		HierarchyOfAnalystsByRules = Catalogs.BudgetingLimits.HierarchyOfAnalyticsByRulesWithSourceColumns(
			LimitRulesUsed);
	Else
		HierarchyOfAnalystsByRules = New Map;
	EndIf;
	
	ResultTable1 = New ValueTable;
	ResultTable1.Columns.Add("LimitsRule", New TypeDescription("CatalogRef.BudgetingLimits"));
	ResultTable1.Columns.Add("LimitType", New TypeDescription("EnumRef.TypesOfCashExpenseLimit"));
	ResultTable1.Columns.Add("LimitPeriodicity", New TypeDescription("EnumRef.Periodicity"));
	ResultTable1.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	ResultTable1.Columns.Add("SumPlan", TMCommonUse.MoneyFieldTypeDescription());
	ResultTable1.Columns.Add("SumReal", TMCommonUse.MoneyFieldTypeDescription());
	ResultTable1.Columns.Add("Recorder");
	
	// It is used to output the measurements of the fact after the output of the measurements of the plan.
	ResultTable1.Columns.Add("NumberOfUsedAnalyticsDimensions", Common.TypeDescriptionNumber(2, 0));
	ResultTable1.Columns.Add("ThisIsAFactLine", New TypeDescription("Boolean"));
	
	MaximumNumberOfBudgetingAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	MaximumNumberOfAnalyticsLimits = MaximumNumberOfBudgetingAnalysts + 2; // The dimensions are "Organization" and "Division".
	
	For CounterAnalyst = 1 To MaximumNumberOfAnalyticsLimits Do
		ResultTable1.Columns.Add("Dimension" + CounterAnalyst);
		ResultTable1.Columns.Add("Dimension" + CounterAnalyst + "Real");
		ResultTable1.Columns.Add("MeasurementViewAnalytics" + CounterAnalyst);
	EndDo;
	
	FillInLogger = FilterDecryptions.UseFilter1
	                     And FilterDecryptions.DecryptionByRegistrar
	                     And LimitReductionPlan.Columns.Find("Recorder") <> Undefined;
	
	FillColumns = "LimitsRule, LimitType, LimitPeriodicity, Currency, SumPlan, SumReal, ThisIsAFactLine"
		+ ?(FillInLogger, ", Recorder", "");
	
	For Each LinePlanFact In LimitReductionPlan Do
		
		AnalyticsHierarchyTable = HierarchyOfAnalystsByRules.Get(LinePlanFact.LimitsRule);
		
		NewRow = ResultTable1.Add();
		FillPropertyValues(NewRow, LinePlanFact, FillColumns);
		
		For CounterAnalyst = 1 To MaximumNumberOfAnalyticsLimits Do
			NewRow["Dimension" + CounterAnalyst] = Null;
			NewRow["Dimension" + CounterAnalyst + "Real"] = Null;
			NewRow["MeasurementViewAnalytics" + CounterAnalyst] = Undefined;
		EndDo;
		
		CounterAnalyst = 0;
		For Each HierarchyLine In AnalyticsHierarchyTable Do
			If Not HierarchyLine.Used Then
				Continue;
			EndIf;
			If LinePlanFact.SumPlan = 0
				And LinePlanFact.SumReal = 0
				And Not LinePlanFact.HasFactLines Then
				// Output only rules with empty amounts. We do not output analytics.
				Continue;
			EndIf;
			CounterAnalyst = CounterAnalyst + 1;
			NewRow["Dimension" + CounterAnalyst] = LinePlanFact[HierarchyLine.PathToAnalytics];
			NewRow["Dimension" + CounterAnalyst + "Real"] = LinePlanFact[HierarchyLine.PathToAnalytics + "Real"];
			NewRow["MeasurementViewAnalytics" + CounterAnalyst] = HierarchyLine.MeasurementViewAnalytics;
		EndDo;
		NewRow.NumberOfUsedAnalyticsDimensions = CounterAnalyst;
	EndDo;
	
	Return ResultTable1;
	
EndFunction

#EndRegion

#EndIf