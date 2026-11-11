#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - Structure - see the return value of the Clientserver report.Get a setup report for silence().
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	ParameterCurrencyOfManagementAccounting = DataCompositionClientServer.GetParameter(SettingsComposer, "ManagementAccountingCurrency");
	If ParameterCurrencyOfManagementAccounting <> Undefined 
		And Not (ValueIsFilled(ParameterCurrencyOfManagementAccounting.Value)
			Or TypeOf(ParameterCurrencyOfManagementAccounting.Value) = Type("String")) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ManagementAccountingCurrency", ManagementAccountingCurrency);
	EndIf;
	
	UserSettingsModified = False;
	ReportCurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportCurrency");
	If ReportCurrencyParameter <> Undefined 
		And (Not ValueIsFilled(ReportCurrencyParameter.Value) Or TypeOf(ReportCurrencyParameter.Value) = Type("String")) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ReportCurrency", ManagementAccountingCurrency);
		UserSettingsModified = True;
	EndIf;
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	For Each Filter In ReportSettings.Filter.Items Do
		If TypeOf(Filter) = Type("DataCompositionFilterItem")
			And Filter.LeftValue = New DataCompositionField("Dimension")
			And Filter.RightValue = Undefined Then
			Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
		EndIf;
	EndDo;
	
	AnalyticsField_ = AnalyticsField_();
	QueryText = DataCompositionSchema.DataSets.WorkingCapital.Query;
	QueryText = StrReplace(QueryText, "AssetsLiabilities.Dimension AS Dimension", AnalyticsField_ + " AS Dimension");
	QueryText = StrReplace(QueryText, "(AssetsLiabilities.Dimension).* AS Dimension", "("+AnalyticsField_ + ").* AS Dimension");
	DataCompositionSchema.DataSets.WorkingCapital.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, CompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

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
		ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandParameter;
		ThisForm.ParametersForm.Filter.Insert("AssetRef", Parameters.CommandParameter);
	EndIf;
	
EndProcedure

Function AnalyticsField_()
	
	SelectionPattern =
	"CASE AssetsLiabilities.Dimension
	|		WHEN NULL THEN UNDEFINED
	|%1
	|		ELSE AssetsLiabilities.Dimension
	|	END";
	ConditionTemplate =
	"		WHEN VALUE(%1.EmptyRef) THEN UNDEFINED";
	SelectionConditions = New Array;
	TypesOfAnalytics_ = Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems.Type.Types();
	For Each TypeOfAnalytics In TypesOfAnalytics_ Do
		
		FullTypeName = Metadata.FindByType(TypeOfAnalytics).FullName();
		SelectionConditions.Add(StrTemplate(ConditionTemplate, FullTypeName));
		
	EndDo;
	Return StrTemplate(SelectionPattern, StrConcat(SelectionConditions, Chars.LF));
	
EndFunction

#EndRegion

#EndIf