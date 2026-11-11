#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//	Form        - ClientApplicationForm - report form,
//	VariantKey - String           - name of the predefined report variant or unique ID,
//	Settings    - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//	Form                - ClientApplicationForm - report form,
//	Cancel                - Boolean           - passed from the handler parameters "as is",
//	StandardProcessing - Boolean           - passed from the handler parameters "as is".
//
// See also:
//	"Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails") Then
			
			// A structure with fields from the report variationdetermined.Before adding Command reports.Teams of reports.
			CommandDetails = Parameters.CommandDetails; // Structure -
			AdditionalCommandParameters = CommandDetails.AdditionalParameters; // Structure -
			
			If AdditionalCommandParameters.Property("CommandName") Then
				
				If AdditionalCommandParameters.CommandName = "RemainingGoodsByShelfLives" Then
					Form.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
				EndIf;
				
			EndIf;
			
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(
		DataCompositionSchema.DataSets[0].Query,
		TablesNames);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	SetFieldHeaders(CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetFieldHeaders(CompositionTemplate)
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;

	If GetFunctionalOption("UseMultipleCurrencies") Then
		ManagementAccountingCurrency = " (" + String(Constants.ManagementAccountingCurrency.Get()) + ")";
	Else
		ManagementAccountingCurrency = "";
	EndIf;
	
	ABCClassificationParameterType = "";
	
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") 
			And StrFind(FilterElement.LeftValue, "ABCClassificationParameterType") > 0 Then
			ABCClassificationParameterType = FilterElement.RightValue;
		EndIf;
	EndDo;

	If ABCClassificationParameterType = Enums.TypesOfClassificationParameters.GrossProfit 
		Or ABCClassificationParameterType = Enums.TypesOfClassificationParameters.Revenue Then
		ABCClassificationParameterType = String(ABCClassificationParameterType) + ManagementAccountingCurrency;
	EndIf;
	
	TitlesMap = New Map();
	TitlesMap.Insert("1", ABCClassificationParameterType);
	TitlesMap.Insert("2", ManagementAccountingCurrency);
	
	DataCompositionServer.SetLayoutTemplateHeaders(TitlesMap, CompositionTemplate);
	
EndProcedure

#EndRegion

#EndIf