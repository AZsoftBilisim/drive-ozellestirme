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
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		
		For Each DataSet In DatasetsToDelete() Do
			Set = DataCompositionSchema.DataSets.DataSet1; // DataCompositionSchemaDataSetUnion
			Set.Items.Delete(DataSet);
		EndDo;
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	// Generate a report
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate,, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

Function DatasetsToDelete()
	
	Set = DataCompositionSchema.DataSets.DataSet1; // DataCompositionSchemaDataSetUnion
	
	DatasetsToDelete = New Array;
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.BankAccountCash) Then
		DatasetsToDelete.Add(Set.Items.Find("BankAccountPayments_"));
	EndIf;
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.CashAccountBalance) Then
		DatasetsToDelete.Add(Set.Items.Find("CashPayment"));
	EndIf;
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.CashInCashRegistersCR) Then
		DatasetsToDelete.Add(Set.Items.Find("InCashRegisters"));
	EndIf;
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.CashInTransit) Then
		DatasetsToDelete.Add(Set.Items.Find("InTransit"));
	EndIf;
	
	Return DatasetsToDelete;
	
EndFunction

#EndRegion

#EndIf