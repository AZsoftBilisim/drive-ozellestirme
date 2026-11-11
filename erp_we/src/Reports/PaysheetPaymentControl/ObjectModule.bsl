#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// For the General "report Form" form of the "report Options" subsystem.
// Parameters:
//   Form - ClientApplicationForm - Report form
//   VariantKey - String - Report variant key
//   Settings - Structure - Report Form Settings
Procedure DefineFormSettings(Form, VariantKey, Settings) Export

	Settings.Print.PageOrientation = PageOrientation.Landscape;
	Settings.Events.BeforeImportSettingsToComposer = True;

EndProcedure
	
// Called before loading new data layout settings. 
// Used to change the layout scheme.
//
// Parameters:
//   Context - ClientApplicationForm - The context of the Settings Composer
//   SchemaKey - String - Data Layout Schema key
//   VariantKey - String - The key of the data layout settings option
//   NewDCSettings - DataCompositionSettings - New data layout settings
//   NewDCUserSettings - DataCompositionUserSettings - New custom data layout settings
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings,
	NewDCUserSettings) Export

	If SchemaKey <> VariantKey Then

		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);

		SchemaKey = VariantKey;

	EndIf;

EndProcedure

#EndRegion

#EndIf