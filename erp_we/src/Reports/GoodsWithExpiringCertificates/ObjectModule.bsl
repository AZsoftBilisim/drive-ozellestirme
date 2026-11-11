#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	ProductsLocalization.SetQueryTextOfGoodsReportWithExpiringCertificates(DataCompositionSchema);
	
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
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
//	Context - Arbitrary - parameters of the context in which the report is used,
//	SchemaKey - String - ID of the current configuration Builder schema,
//	VariantKey - String, Undefined - the name of a predefined or unique identifier of a custom 
//											version of the report. It is uncertain when the call is for the decryption option
//											or without context.
//	NewDCSettings - DataCompositionSettings, Undefined - report variant settings that will be loaded 
//		into the settings Builder after it is initialized.
//		Undefined when the option settings do not need to be loaded (already loaded earlier).
//	NewDCUserSettings - DataCompositionUserSettings, Undefined -
//		User settings that will be loaded into the settings builder after its initialization.
//		It is uncertain when the user settings do not need to be loaded (already loaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey <> "SchemeInitialized" Then
		
		SchemaKey        = "SchemeInitialized";
		DatasetFields = DataCompositionSchema.DataSets.QualityCertificates.Fields;
		
		ValuesOfCertificateTypeField = New ValueList;
		ArrayOfCertificateTypes    = Catalogs.QualityCertificates.CreateListToSelectCertificateTypes();
		
		For Each CertificateType In ArrayOfCertificateTypes Do
			ValuesOfCertificateTypeField.Add(CertificateType, CertificateType);
		EndDo;
		
		CertificateTypeField = DatasetFields.Find("CertificateType");
		CertificateTypeField.SetAvailableValues(ValuesOfCertificateTypeField);
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf