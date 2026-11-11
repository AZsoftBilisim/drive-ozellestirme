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
	
	If Parameters.Property("CommandParameter") And ValueIsFilled(Parameters.CommandParameter) Then
		
		References_0 = GeneralPurposeTMServerCall.ObjectAttributesValues(
				Parameters.CommandParameter, "IsFolder, Periodicity, SetAValueForEachPeriod, ByPeriods");
		
		If References_0.IsFolder Then
			Cancel = True;
			Return;
		EndIf;
		
		If References_0.SetAValueForEachPeriod Or References_0.ByPeriods Then
			Periodicity = References_0.Periodicity;
		Else
			Periodicity = PredefinedValue("Enum.Periodicity.Month");
		EndIf;
		
		ThisForm.ParametersForm.Filter.Insert("NonFinancialItem", Parameters.CommandParameter);
		ThisForm.ParametersForm.Filter.Insert("Periodicity", Periodicity);
	EndIf;
	
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
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer; // DataCompositionSettingsComposer - 
	
	If ThisForm.CurrentVariantKey = "Details" Then
		
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
					String(GroupingField.Field));
			EndDo;
			PlaceAdded = NewGrouping.Structure;
			AddSource_1 = Group.Structure;
		EndDo;
		
		If FixedSettings.Selection.Items.Count() > 0 Then
			DataCompositionClientServer.CopyElements(FormSettingsComposer.Settings.Selection,
					FixedSettings.Selection,
					True);
		EndIf;
		FormSettingsComposer.Settings.AdditionalProperties.Insert("CurrentVariantKey", "Details");
		FormSettingsComposer.Settings.DataParameters.SetParameterValue("DetailsMode", True);
		
	Else
		
		FormSettingsComposer.Settings.DataParameters.SetParameterValue("DetailsMode", ThisForm.DetailsMode);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings(); // DataCompositionSettings -
	
	BudgetingServer.AddDCSAnalyticsByType(DataCompositionSchema, "NonFinancialItem");
	
	BudgetingServer.AddAnalyticsPresentationExpressionsToDCS(DataCompositionSchema,
			"DataSets.NonFinancialItemValues.Fields",
			"NonFinancialItem");
	
	Parameters = ParametersForObtainingValuesOfNonFinancialIndicators(ReportSettings);
	NonFinancialItemValues = BudgetingServer.NonFinancialItemValues(ReportSettings, Parameters);
	NonFinancialItemValues.Sort("InstallationPeriod, IndicatorValue DESC");
	
	ConfigurePeriodExtension(ReportSettings);
	AddResourcesByScenario(NonFinancialItemValues, ReportSettings);
	
	ExternalSets = New Structure;
	ExternalSets.Insert("NonFinancialItemValues", NonFinancialItemValues);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

Function ParametersForObtainingValuesOfNonFinancialIndicators(ReportSettings)
	
	Parameters = BudgetingServer.TemplateForParametersForObtainingValuesOfNonFinancialIndicators();
	
	Parameters.Period = DataCompositionClientServer.GetParameter(ReportSettings, "Period").Value; 
	Parameters.Periodicity = DataCompositionClientServer.GetParameter(ReportSettings, "Periodicity").Value;
	Parameters.ByCompanies = True;
	Parameters.ByBusinessUnits = True;
	Parameters.Insert("ReportCurrency", Parameters.CurrencyOfMan);
	
	Return Parameters; 
	
EndFunction

Procedure ConfigurePeriodExtension(ReportSettings) 
	
	Periodicity = DataCompositionClientServer.GetParameter(ReportSettings, "Periodicity").Value;
	
	If Not ValueIsFilled(Periodicity) Then
		Return;
	EndIf;
	
	StringPeriodicity = Common.EnumerationValueName(Periodicity);
	AdditionType = DataCompositionPeriodAdditionType[StringPeriodicity];
	
	Period = DataCompositionClientServer.GetParameter(ReportSettings, "Period").Value; // StandardPeriod -
	PeriodField = New DataCompositionField("Period");
	
	For Each StructureItem In ReportSettings.Structure Do
		Groups = DataCompositionClientServer.GetGroupings(StructureItem);
		For Each Group In Groups Do
			CompositionGroup1 = Group.Value; // DataCompositionGroup, DataCompositionTableGroup -
			GroupItems = CompositionGroup1.GroupFields.Items;
			If GroupItems.Count() = 1 And GroupItems[0].Field = PeriodField Then
				GroupingPeriod = GroupItems[0];
				GroupingPeriod.AdditionType = AdditionType;
				GroupingPeriod.BeginOfPeriod = Period.StartDate;
				GroupingPeriod.EndOfPeriod = Period.EndDate;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure AddResourcesByScenario(NonFinancialItemValues, ReportSettings)
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	Groups = New Array;
	Groups.Add("NonFinancialItem");
	Groups.Add("Organization");
	Groups.Add("Department");
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		Groups.Add("Dimension" + DimensionNumber);
	EndDo;
	Groups.Add("Scenario");
	Groups.Add("Recorder");
	
	DetailsMode = False;
	DecryptionModeParameter = New DataCompositionParameter("DetailsMode");
	DecryptionModeParameter = ReportSettings.DataParameters.FindParameterValue(DecryptionModeParameter);
	If Not DecryptionModeParameter = Undefined Then
		DetailsMode = DecryptionModeParameter.Value;
	EndIf;
	
	If DetailsMode Then
		Groups.Add("Period");
		
		DimensionsOfSettingsStructure = New Array;
		FillInSettingsStructureDimensions(DimensionsOfSettingsStructure,
				ReportSettings.Structure);
		
		NumberOfDimensions = Groups.Count();
		For TagNumber = 1 To NumberOfDimensions Do
			ArrayIndex = NumberOfDimensions - TagNumber;
			GroupName = Groups[ArrayIndex];
			If DimensionsOfSettingsStructure.Find(GroupName) = Undefined Then
				Groups.Delete(ArrayIndex);
			EndIf;
		EndDo;
	EndIf;
	
	ScenarioTable = NonFinancialItemValues.Copy();
	ScenarioTable.GroupBy("Scenario");
	ScenarioTable.Sort("Scenario");
	
	For Each StringScript In ScenarioTable Do
		
		Scenario = StringScript.Scenario;
		If Not ValueIsFilled(Scenario) Then
			Title = NStr("vi = '<Theo tất cả các kịch bản>';
						|ru = '<По всем сценариям>';
						|en = '<By all scenarios>'; fa = '<By all scenarios>';
						|it = '<Secondo tutti gli scenari>';
						|pl = '<Dla wszystkich scenariuszy>';
						|tr = '<Tüm senaryolara göre>'");
			ScriptID = "EmptyScript";
		Else
			Title = String(Scenario);
			ScriptID = "Scenario_" + StrReplace(String(Scenario.UUID()), "-", "");
		EndIf;
		
		Expression = "CASE WHEN Scenario = &ScriptID THEN IndicatorValue ELSE 0 END";
		Expression = StrReplace(Expression, "ScriptID", ScriptID);
		
		Parameter = DataCompositionSchema.Parameters.Add();
		Parameter.Use = DataCompositionParameterUse.Always;
		Parameter.Name = ScriptID;
		Parameter.Value = Scenario;
		Parameter.UseRestriction = True;
		
		NewCalculatedField = FinancialReportingServer.NewCalculatedField(
			DataCompositionSchema, ScriptID, Expression, Title);
		NewCalculatedField.ValueType = New TypeDescription("Number", New NumberQualifiers(3,0));
		
		For Each Group In Groups Do
			
			NewResource = DataCompositionSchema.TotalFields.Add();
			NewResource.DataPath = String(ScriptID);
			
			Expression =
			"Reports.NonFinancialItemValues.Attachable_MetricValueForGrouping(
			|	EvalExpressionWithGroupValueTable(%1,,,%2),
			|	UnitOfMeasure,
			|	NonFinancialItem,
			|	NonFinancialItem.IndicatorKind,
			|	NonFinancialItem.ByPeriods,
			|	NonFinancialItem.ByCompanies,
			|	NonFinancialItem.ByBusinessUnits,
			|	NonFinancialItem.NumberOfUsedDimensions,
			|	NonFinancialItem.SetAValueForEachPeriod,
			|	Period,
			|	&Periodicity,
			|	CASE
			|		WHEN NonFinancialItem.ByPeriods
			|			THEN NonFinancialItem.SubperiodFrequency
			|		ELSE NonFinancialItem.Periodicity
			|	END,
			|	%3,
			|	&DetailsMode,
			|	&Cache)";
			
			GroupingExpression1 = StrTemplate("
			|		SubperiodNumber AS SubperiodNumber,
			|		InstallationPeriod AS InstallationPeriod,
			|		Currency AS Currency,
			|		SUM(%1) AS VALUE", ScriptID);
			
			GroupingExpression2 = StrTemplate("SUM(%1) <> 0", ScriptID);
			
			Expression = StrTemplate(Expression,
				"""" + GroupingExpression1 + """",
				"""" + GroupingExpression2 + """",
				"""" + Group + """");
			
			NewResource.Expression = Expression;
			NewResource.Groups.Add(Group);
		EndDo;
		
		FinancialReportingServer.NewSelectionField(ReportSettings, ScriptID, Title);
		
		ConditionalAppearanceItem = ReportSettings.ConditionalAppearance.Items.Add();
		ConditionalAppearanceItem.UseInFieldsHeader = DataCompositionConditionalAppearanceUse.DontUse;
		ConditionalAppearanceItem.UseInHeader = DataCompositionConditionalAppearanceUse.DontUse;
		
		FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
		FieldItem.Use = True;
		FieldItem.Field = New DataCompositionField(ScriptID);
		
		ConditionalAppearanceItem.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Right);
		ConditionalAppearanceItem.Appearance.SetParameterValue("MinWidth", 20);
		ConditionalAppearanceItem.Appearance.SetParameterValue("MaxWidth", 20);
		
	EndDo;
	
	Parameter = DataCompositionSchema.Parameters.Add();
	Parameter.Use = DataCompositionParameterUse.Always;
	Parameter.UseRestriction = True;
	Parameter.IncludeInAvailableFields = False;
	Parameter.Name = "Cache";
	Parameter.Value = New Map;

EndProcedure

Procedure FillInSettingsStructureDimensions(DimensionsOfSettingsStructure, SettingsStructureItem)
	
	For Each StructureItem In SettingsStructureItem Do
		If StructureItem.Use Then
			For Each GroupingField In StructureItem.GroupFields.Items Do
				If GroupingField.Use Then
					GroupName = String(GroupingField.Field);
					If DimensionsOfSettingsStructure.Find(GroupName) = Undefined Then
						DimensionsOfSettingsStructure.Add(GroupName);
					EndIf;
				EndIf;
			EndDo;
			
			FillInSettingsStructureDimensions(DimensionsOfSettingsStructure, StructureItem.Structure);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
