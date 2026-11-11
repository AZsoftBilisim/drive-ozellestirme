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
	
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(NewDCSettings);

EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
//	Context							- Arbitrary									- parameters of the context in which the report is used.
//	SchemaKey							- String										- ID of the current configuration Builder schema.
//	VariantKey						- String, Undefined							- name of the predefined or unique ID of the custom
//																							version of the report.
//																							Undefined when calling for a decryption option or without context.
//	NewDCSettings					- DataCompositionSettings, Undefined		- report variant settings that will be loaded
//																							into the settings Builder after it is initialized.
//																							Undefined when the option settings do not need to be loaded (already loaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings,
//											Undefined - user settings that will be loaded into
//																							the settings Builder after it is initialized.
//																							Undefined when user settings do not need to be loaded
//																							(already loaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	SchemaKey = VariantKey;
	
	SetLimitOnFunctionalOptions(Context, SchemaKey);
	
	If NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	FieldHeaders = ParameterizableFieldHeaders();
	DataCompositionServer.SetHeadersOfSelectedFields(NewDCSettings.Selection.Items, FieldHeaders);
	
	If TypeOf(NewDCUserSettings) <> Type("DataCompositionUserSettings") Then
		Return;
	EndIf;
	
	SettingID = NewDCSettings.Structure.UserSettingID;
	
	If ValueIsFilled(SettingID) Then
		FoundSettingElement = NewDCUserSettings.Items.Find(SettingID);
		
		If FoundSettingElement <> Undefined Then 
			DataCompositionServer.SetDimensionFieldHeaders(FoundSettingElement.Items, FieldHeaders);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;

	ReportSettings = SettingsComposer.GetSettings();
	
	QueryText = DataCompositionSchema.DataSets.ProductsRelease.Query;
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("OutputTurnover_.ItemsLocationAttributes.Products.UnitOfMeasure", "OutputTurnover_.ItemsLocationAttributes.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("OutputTurnover_.ItemsLocationAttributes.Products.UnitOfMeasure", "OutputTurnover_.ItemsLocationAttributes.Products"));
	
	DataCompositionSchema.DataSets.ProductsRelease.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfDynamicHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
	
Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

Function StructureOfDynamicHeaders()
	DynamicHeaders = New Structure;
	
	Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "GroupingProducts");
	AvailableSetting = ReportsClientServer.FindAvailableSetting(SettingsComposer.Settings, Parameter);
	If AvailableSetting <> Undefined Then
		PresentationOfParameterValue = AvailableSetting.AvailableValues[Parameter.Value-1];
		DynamicHeaders.Insert("GroupingProducts", PresentationOfParameterValue);
	EndIf;
	
	Return DynamicHeaders;
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(Settings)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(Settings, "QuantityUnits");
	EndIf;
	
	If Not GetFunctionalOption("UseProductionManagement")
		Or GetFunctionalOption("ComplexAutomation") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(Settings, "ProductionOrder21");
		RemoveConditionalAppearanceOfField(Settings, "ProductionOrder21");
	EndIf;
	
	If Not GetFunctionalOption("UseProductionManagement2_2")
		Or GetFunctionalOption("ComplexAutomation") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(Settings, "ProductionOrder");
		RemoveConditionalAppearanceOfField(Settings, "ProductionOrder");
	EndIf;
	
	If GetFunctionalOption("ComplexAutomation") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(Settings, "InventoryType");
		RemoveConditionalAppearanceOfField(Settings, "InventoryType");
	EndIf;
	
EndProcedure

Procedure SetLimitOnFunctionalOptions(Context, SchemaKey)
	
	HasChanges = False;
	
	If Not GetFunctionalOption("UseProductionManagement")
		Or GetFunctionalOption("ComplexAutomation") Then
		HasChanges = True;
		SetFieldUsageLimit("ProductionOrder21");
	EndIf;
	
	If Not GetFunctionalOption("UseProductionManagement2_2")
		Or GetFunctionalOption("ComplexAutomation") Then
		HasChanges = True;
		SetFieldUsageLimit("ProductionOrder");
	EndIf;
	
	If GetFunctionalOption("ComplexAutomation") Then
		HasChanges = True;
		SetFieldUsageLimit("InventoryType");
	EndIf;
	
	If HasChanges Then
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

Procedure SetFieldUsageLimit(FieldName, Restrict = True)
	
	For Each CurSet In DataCompositionSchema.DataSets Do
		
		CurField = CurSet.Fields.Find(FieldName);
		
		If Not CurField = Undefined Then
			
			CurField.UseRestriction.Group = Restrict;
			CurField.UseRestriction.Field = Restrict;
			CurField.UseRestriction.Order = Restrict;
			CurField.UseRestriction.Condition = Restrict;
			
			CurField.AttributeUseRestriction.Group = Restrict;
			CurField.AttributeUseRestriction.Field = Restrict;
			CurField.AttributeUseRestriction.Order = Restrict;
			CurField.AttributeUseRestriction.Condition = Restrict;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Deletes the conditional design of the specified field.
// 
// Parameters:
// 	Settings - DataCompositionSettings - the report settings.
// 	FieldName - String - field name.
//
Procedure RemoveConditionalAppearanceOfField(Settings, FieldName)
	
	PreparationForDeletion = New Array;
	For Each CurDesign In Settings.ConditionalAppearance.Items Do
		
		FieldsToDelete_ = New Array;
		For Each CurField In CurDesign.Fields.Items Do
			If CurField.Field = New DataCompositionField(FieldName) Then
				FieldsToDelete_.Add(CurField);
			EndIf;
		EndDo;
		
		If FieldsToDelete_.Count() = CurDesign.Fields.Items.Count() Then
			PreparationForDeletion.Add(CurDesign);
			Continue;
		EndIf;
		
		For Each CurField In FieldsToDelete_ Do
			CurDesign.Fields.Items.Delete(CurField);
		EndDo;
		
	EndDo;
	
	For Each CurDesign In PreparationForDeletion Do
		Settings.ConditionalAppearance.Items.Delete(CurDesign);
	EndDo;
	
EndProcedure

#EndRegion

#EndIf