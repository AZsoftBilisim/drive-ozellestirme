#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
	Settings.Events.OnLoadUserSettingsAtServer = True;
	
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
	
	// Additional command
	ReportSettings = ThisForm.ReportSettings;
	
	If ReportSettings.Property("Contextual")
	   And ReportSettings.Contextual Then
		
		ComparisonScenarioParameter = DataCompositionSchema.Parameters.Find("ComparisonScenarios");
		OptionToDisplayOnlyScriptDeviations = DataCompositionSchema.Parameters.Find("DisplayOnlyScriptDeviations");
		
		ComparisonScenarioParameter.IncludeInAvailableFields = False;
		ComparisonScenarioParameter.UseRestriction = True;
		OptionToDisplayOnlyScriptDeviations.IncludeInAvailableFields = False;
		OptionToDisplayOnlyScriptDeviations.UseRestriction = True;
		
		ReportsServer.AttachSchema(ThisObject, ThisForm, DataCompositionSchema, "");
		
	EndIf;
	
	If Parameters.Property("Details")
	   And Parameters.Details <> Undefined Then
		
		// correction of the report variant key during decryption
		If IsTempStorageURL(Parameters.Details.Data) Then
			
			DetailsData = GetFromTempStorage(Parameters.Details.Data);
			
			If Parameters.Property("VariantKey") And Parameters.VariantKey = Undefined Then
				Parameters.VariantKey = DetailsData.Settings.AdditionalProperties.VariantKey;
			EndIf;
			
			ThisForm.CurrentVariantKey = DetailsData.Settings.AdditionalProperties.VariantKey;
			
		EndIf;
		
		ReportSettings.OptionRef = ReportsOptions.ReportVariant(ReportSettings.ReportRef, ThisForm.CurrentVariantKey);
		
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	AdditionalPropertiesFilledIn = ValueIsFilled(NewDCSettings.AdditionalProperties);
	FilledInOptionKey = NewDCSettings.AdditionalProperties.Property("VariantKey")
							And ValueIsFilled(NewDCSettings.AdditionalProperties.VariantKey);
	
	CurrentVariantKey = ?(AdditionalPropertiesFilledIn And FilledInOptionKey,
												NewDCSettings.AdditionalProperties.VariantKey,
												ThisForm.CurrentVariantKey);
	
	Planning.BalancePlansBeforeUploadingOptionToServer(ThisForm, NewDCSettings);

	ParameterOnlyExceedingDeviation = DataCompositionSchema.Parameters.Find("OnlyExcessOfDeviation");
	ParameterIsOnlyLessThanDeviation = DataCompositionSchema.Parameters.Find("OnlyLessThanDeviation");
	
	ComparisonScenarioParameter = DataCompositionSchema.Parameters.Find("ComparisonScenarios");
	OptionToDisplayOnlyScriptDeviations = DataCompositionSchema.Parameters.Find("DisplayOnlyScriptDeviations");
	
	If CurrentVariantKey <> "PlanBalanceForThePeriod" Then
		
		ParameterOnlyExceedingDeviation.IncludeInAvailableFields = False;
		ParameterOnlyExceedingDeviation.UseRestriction = True;
		ParameterIsOnlyLessThanDeviation.IncludeInAvailableFields = False;
		ParameterIsOnlyLessThanDeviation.UseRestriction = True;
		
	Else
		
		ParameterOnlyExceedingDeviation.IncludeInAvailableFields = True;
		ParameterOnlyExceedingDeviation.UseRestriction = False;
		ParameterIsOnlyLessThanDeviation.IncludeInAvailableFields = True;
		ParameterIsOnlyLessThanDeviation.UseRestriction = False;
		
	EndIf;
	
	If CurrentVariantKey <> "ComparisonOfScenariosForPeriod"
	   And CurrentVariantKey <> "ComparisonOfScenariosByPeriod" Then
		
		ComparisonScenarioParameter.IncludeInAvailableFields = False;
		ComparisonScenarioParameter.UseRestriction = True;
		OptionToDisplayOnlyScriptDeviations.IncludeInAvailableFields = False;
		OptionToDisplayOnlyScriptDeviations.UseRestriction = True;
		
	Else
		
		ComparisonScenarioParameter.IncludeInAvailableFields = True;
		ComparisonScenarioParameter.UseRestriction = False;
		OptionToDisplayOnlyScriptDeviations.IncludeInAvailableFields = True;
		OptionToDisplayOnlyScriptDeviations.UseRestriction = False;
		
	EndIf;
	
	ReportsServer.AttachSchema(ThisObject, ThisForm, DataCompositionSchema, "");
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   NewDCUserSettings - DataCompositionUserSettings -
//       Custom settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form Extension for the report.Prizagruzkepusersing settings in the server"
//    in the syntax assistant.
//
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export
	
	FormSettingsComposer = Form.Report.SettingsComposer;
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		Planning.BalancePlansBeforeUploadingCustomSettingsToServer(Form, NewDCUserSettings);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Planning.BalancingPlansHandlingFillChecks(SettingsComposer, Cancel);
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	Scenario = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "Scenario");
	
	If Not ValueIsFilled(Scenario.Value) Then
		Raise NStr("vi = 'Chưa điền giá trị tham số ""Kịch bản"".';
					|ru = 'Не заполнено значение параметра ""Сценарий"".';
					|en = 'Parameter ""Scenario"" is not filled in.'; fa = 'Parameter ""Scenario"" is not filled in.';
					|it = 'Il valore del parametro ""Scenario"" non è compilato.';
					|pl = 'Wartość parametru ""Scenariusz"" nie jest wypełniona.';
					|tr = '""Senaryo"" parametresinin değeri doldurulmamış.'");
	EndIf;
	
	Planning.BalanceOfPlansInLayoutOfResult(DataCompositionSchema, SettingsComposer, 
		ResultDocument, DetailsData, StandardProcessing);
	
	CheckTaskQueueIssueWarning(Scenario.Value);

	ComparisonScenarios = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "ComparisonScenarios");
	
	If ComparisonScenarios <> Undefined Then
		If ComparisonScenarios.Value <> Undefined Then
			CheckTaskQueueIssueWarning(ComparisonScenarios.Value);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckTaskQueueIssueWarning(Scenario)
	
	ArrayOfScenarios = New Array;
	
	If TypeOf(Scenario) <> Type("ValueList") Then
		ArrayOfScenarios.Add(Scenario);
	Else
		For Each AdditionalScenario_ In Scenario Do
			ArrayOfScenarios.Add(AdditionalScenario_.Value);
		EndDo;
	EndIf;
	
	For Each TestableScenario In ArrayOfScenarios Do
		
		Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.QueueOfProductionPlanCalculation AS QueueOfProductionPlanCalculation
		|WHERE
		|	QueueOfProductionPlanCalculation.State = VALUE(Enum.StatesOfProductionPlanCalculation.CalculationIsRequired)
		|	AND QueueOfProductionPlanCalculation.Scenario = &Scenario
		|");
		
		Query.SetParameter("Scenario", TestableScenario);
		
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		
		If Not QueryResult.IsEmpty() Then
			
			InformationRegisters.QueueOfProductionPlanCalculation.RunJob();
			
			For Each Item In SettingsComposer.Settings.Structure Do
				If Item.Name = "CalculationQueue" Then
					Item.Use = True;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
