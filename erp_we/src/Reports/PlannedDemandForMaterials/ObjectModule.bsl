#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer,
		ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
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
			ProductAssignmentField = New DataCompositionField("AssignmentOfProducts");
			SpecificationField = New DataCompositionField("BillOfMaterials");
			
			GroupFields = Parameters.Details.UsedSettings.Structure[0].GroupFields; // DataCompositionGroupFields - 
			
			For Each Group In GroupFields.Items Do
			
				If Group.Field = ProductProductsField 
					Or Group.Field = FieldCharacteristicOfProduction
					Or Group.Field = SpecificationField
					Or Group.Field = ProductAssignmentField Then
				
					ReplaceOption = True;
					Break;
				
				EndIf; 
			
			EndDo; 
		
		EndIf; 
		
		// filling in the decryption parameters
		If IsTempStorageURL(Parameters.Details.Data) Then
		
			DetailsData = GetFromTempStorage(Parameters.Details.Data);
			
			If Not DetailsData.Settings.AdditionalProperties.Property("CurrentVariantKey")
				Or DetailsData.Settings.AdditionalProperties.CurrentVariantKey <> "PlannedNeedForMaterialsContext" Then
			
				Return;
			
			EndIf; 
		EndIf; 
		
		If Not ReplaceOption Then
			Return;
		EndIf; 
		
		If Parameters.Property("VariantKey") Then
			Parameters.VariantKey = "DecodingContext";
		EndIf; 
		If Parameters.Property("PurposeUseKey") Then
			Parameters.PurposeUseKey = "DecodingContext";
		EndIf;
		
		ThisForm.CurrentVariantKey = "DecodingContext";
		
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
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	If FormSettingsComposer.Settings.AdditionalProperties.Property("CurrentVariantKey") 
		And FormSettingsComposer.Settings.AdditionalProperties.CurrentVariantKey = "PlannedNeedForMaterialsContext"
		And ThisForm.CurrentVariantKey = "DecodingContext" Then
		
		Scenario = Undefined;
		SpecifyTargets = Undefined;
		FormSettingsComposer.Settings.AdditionalProperties.Property("Scenario", Scenario);
		FormSettingsComposer.Settings.AdditionalProperties.Property("SpecifyTargets", SpecifyTargets);
		
		ReportObject = Reports.PlannedDemandForMaterials.Create();
		Variant = ReportObject.DataCompositionSchema.SettingVariants.Find(ThisForm.CurrentVariantKey);
		
		DataCompositionClientServer.FillInElements(Variant.Settings.DataParameters,	FormSettingsComposer.Settings.DataParameters);
		DataCompositionClientServer.CopyElements(Variant.Settings.Filter,			FormSettingsComposer.Settings.Filter, False);
		
		FormSettingsComposer.LoadSettings(Variant.Settings);
		
		If Scenario <> Undefined Then
		
			DataCompositionClientServer.SetParameter(
				FormSettingsComposer, 
				"Scenario", 
				Scenario);
		
		EndIf;
		
		If SpecifyTargets <> Undefined Then
		
			DataCompositionClientServer.SetParameter(
				FormSettingsComposer, 
				"SpecifyTargets", 
				SpecifyTargets);
		
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
			
		PlanningByAssignments = Common.ObjectAttributeValue(FormSettingsComposer.Settings.AdditionalProperties.Scenario
			, "PlanningByAssignments");
			
		FormSettingsComposer.Settings.AdditionalProperties.Insert(
			"SpecifyTargets", 
			PlanningByAssignments);
			
		DataCompositionClientServer.SetParameter(
			FormSettingsComposer, 
			"SpecifyTargets", 
			PlanningByAssignments);
		
	EndIf; 
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

#EndRegion

#Region Private

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;
	
EndFunction

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.UnitFieldHeaders(SettingsComposer);
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf