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
	Settings.Events.OnLoadVariantAtServer = True;
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
	
	// Additional command
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		ThisForm.ParametersForm.Filter.Insert("ProductionPlan", Parameters.CommandParameter);
		
		Scenario = Parameters.CommandParameter.Scenario;
		If Not Scenario.UseForMaterialsPlanning Then
			
			MessageText = NStr("vi = 'Kịch bản ""%Scenario%"" không bao gồm việc tính toán nhu cầu dự tính!';
								|ru = 'В сценарии ""%Scenario%"" не включен расчет плановых потребностей!';
								|en = 'The scenario ""%Scenario%"" does not have the planned demands calculation enabled!'; fa = 'The scenario ""%Scenario%"" does not have the planned demands calculation enabled!';
								|it = 'Nello scenario ""%Scenario%"" non è incluso il calcolo di fabbisogni pianificati!';
								|pl = 'Do scenariusza ""%Scenario%"" nie dodano obliczenia planowanych zapotrzebowań!';
								|tr = '""%Scenario%"" senaryosuna planlanan gereksinimlerin hesaplanması dahil değildir!'");
			MessageText = StrReplace(MessageText, "%Scenario%", Scenario);
			Common.MessageToUser(MessageText, , , , Cancel);
			
		EndIf;
		
	EndIf;
	
	If Parameters.Property("Details")
		And Parameters.Details <> Undefined Then
		
		ReplaceOption = False;
		
		If Parameters.Details.UsedSettings.Structure.Count() > 0 Then
			
			ProductProductsField = New DataCompositionField("ProductsItems");
			FieldCharacteristicOfProduction = New DataCompositionField("ItemVariant");
			SpecificationField = New DataCompositionField("BillOfMaterials");
			
			GroupFields = Parameters.Details.UsedSettings.Structure[0].GroupFields; // DataCompositionGroupFields - 
			
			For Each Group In GroupFields.Items Do
			
				If Group.Field = ProductProductsField 
					Or Group.Field = FieldCharacteristicOfProduction
					Or Group.Field = SpecificationField Then
				
					ReplaceOption = True;
					Break;
				
				EndIf; 
			
			EndDo; 
		
		EndIf; 
		
		ThisIsContextualReport = False;
		
		// filling in the decryption parameters
		If IsTempStorageURL(Parameters.Details.Data) Then
		
			DetailsData = GetFromTempStorage(Parameters.Details.Data);
			
			If Not DetailsData.Settings.AdditionalProperties.Property("CurrentVariantKey")
				Or Not (DetailsData.Settings.AdditionalProperties.CurrentVariantKey = "PlannedLaborCosts_"
				Or DetailsData.Settings.AdditionalProperties.CurrentVariantKey = "Main") Then
			
				Return;
			
			EndIf; 
			ThisIsContextualReport = DetailsData.Settings.AdditionalProperties.CurrentVariantKey = "PlannedLaborCosts_";
			
			PeriodicityParameter = DataCompositionClientServer.GetParameter(DetailsData, "Periodicity");
			
			If PeriodicityParameter <> Undefined Then
				DataCompositionClientServer.SetParameter(
					FormSettingsComposer,
					"Periodicity",
					PeriodicityParameter.Value);
				
				FormSettingsComposer.GetSettings();
			EndIf;
			
		EndIf; 
		
		If Not ReplaceOption Then
			Return;
		EndIf; 
		
		If Parameters.Property("VariantKey") Then
			Parameters.VariantKey = ?(ThisIsContextualReport, "DecodingContext", "Details");
		EndIf; 
		If Parameters.Property("PurposeUseKey") Then
			Parameters.PurposeUseKey = ?(ThisIsContextualReport, "DecodingContext", "Details");
		EndIf;
		
		ThisForm.CurrentVariantKey = ?(ThisIsContextualReport, "DecodingContext", "Details");
		
		ThisForm.DetailsMode = False;
		ThisForm.ReportSettings.EditOptionsAllowed = False;
		ThisForm.ReportSettings.OptionRef = ReportsOptions.ReportVariant(ThisForm.ReportSettings.ReportRef, ThisForm.CurrentVariantKey);
		
	EndIf;
	

EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	If FormSettingsComposer.Settings.AdditionalProperties.Property("CurrentVariantKey") 
		And ((FormSettingsComposer.Settings.AdditionalProperties.CurrentVariantKey = "PlannedLaborCosts_"
		And ThisForm.CurrentVariantKey = "DecodingContext")
		Or (FormSettingsComposer.Settings.AdditionalProperties.CurrentVariantKey = "Main"
		And ThisForm.CurrentVariantKey = "Details")) Then
		
		Scenario = Undefined;
		FormSettingsComposer.Settings.AdditionalProperties.Property("Scenario", Scenario);
		
		ReportObject = Reports.PlannedDemandForHumanResources.Create();
		Variant = ReportObject.DataCompositionSchema.SettingVariants.Find(ThisForm.CurrentVariantKey);
		
		DataCompositionClientServer.FillInElements(Variant.Settings.DataParameters,	FormSettingsComposer.Settings.DataParameters);
		DataCompositionClientServer.CopyElements(Variant.Settings.Filter,			FormSettingsComposer.Settings.Filter, False);
		
		// Forwarding the periodicity parameter during decryption
		PeriodicityParameter = DataCompositionClientServer.GetParameter(FormSettingsComposer, "Periodicity");
		
		FormSettingsComposer.LoadSettings(Variant.Settings);
		
		If PeriodicityParameter <> Undefined Then
			DataCompositionClientServer.SetParameter(
				FormSettingsComposer,
				"Periodicity",
				PeriodicityParameter.Value);
		EndIf;
		
		If Scenario <> Undefined Then
			DataCompositionClientServer.SetParameter(
				FormSettingsComposer, 
				"Scenario", 
				Scenario);
		
		EndIf; 
		
	EndIf; 
	
	FormSettingsComposer.Settings.AdditionalProperties.Insert("CurrentVariantKey", ThisForm.CurrentVariantKey);
	
	If ThisForm.ParametersForm.Filter.Property("ProductionPlan") Then
		
		FormSettingsComposer.Settings.AdditionalProperties.Insert(
			"Scenario", 
			Common.ObjectAttributeValue(ThisForm.ParametersForm.Filter.ProductionPlan, "Scenario"));
		
		DataCompositionClientServer.SetParameter(
			FormSettingsComposer, 
			"Scenario", 
			FormSettingsComposer.Settings.AdditionalProperties.Scenario);
		
	EndIf;
	
	PeriodicityParameter = DataCompositionClientServer.GetParameter(FormSettingsComposer, "Periodicity");
	ScenarioParameter = DataCompositionClientServer.GetParameter(FormSettingsComposer, "Scenario");
	
	If PeriodicityParameter <> Undefined And PeriodicityParameter.Value = Undefined
		And ScenarioParameter <> Undefined And ValueIsFilled(ScenarioParameter.Value) Then
		DataCompositionClientServer.SetParameter(
			FormSettingsComposer,
			"Periodicity",
			Common.ObjectAttributeValue(ScenarioParameter.Value, "Periodicity"));
	EndIf;
	
	NewDCSettings = FormSettingsComposer.Settings;
	

EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   NewDCUserSettings - DataCompositionUserSettings -
//       Custom settings to upload to The Settings Composer.
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export
	
	ScenarioParameter = DataCompositionClientServer.GetParameter(NewDCUserSettings, "Scenario");
	
	If ScenarioParameter <> Undefined And ScenarioParameter.Value <> Undefined Then
		
		Scenario = ScenarioParameter.Value;
		
		DataCompositionClientServer.SetParameter(
			SettingsComposer,
			"Periodicity",
			Common.ObjectAttributeValue(Scenario, "Periodicity"));
		
	ElsIf Form.Parameters.Property("CommandParameter") Then
		
		Plan = Form.Parameters.CommandParameter;
		
		DataCompositionClientServer.SetParameter(
			SettingsComposer,
			"Periodicity",
			Common.ObjectAttributeValue(Plan, "Scenario.Periodicity"));
		
	EndIf;
	
	NewDCUserSettings = SettingsComposer.GetSettings();
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, StandardProcessing)
	
	PeriodicityParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Periodicity");
	ScenarioParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Scenario");
	
	If PeriodicityParameter <> Undefined And Not ValueIsFilled(PeriodicityParameter.Value)
		And ScenarioParameter <> Undefined And ValueIsFilled(ScenarioParameter.Value) Then
			DataCompositionClientServer.SetParameter(
				SettingsComposer,
				"Periodicity",
				Common.ObjectAttributeValue(ScenarioParameter.Value, "Periodicity"));
	EndIf;
	
EndProcedure

#EndRegion

#EndIf