
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Object.Ref = ExchangePlans.SalesRepresentativeMobileApplication.ThisNode() Then
		Items.User.Visible = False;
		Items.UserName.Visible = False;
		Items.MobileDevice.Visible = False;
		Items.MobileApplicationVersion.Visible = False;
		Items.Password.Visible = False;
		Items.AdvancedFilter.Visible = False;
		Items.AdditionalSettings.Visible = False;
	EndIf;
	
	DownloadSelectionSettings();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	SaveSettings = SettingsComposer.GetSettings();
	SettingsStructure = MobileApps.DescriptionOfDataLayoutSelection(SaveSettings.Filter);
	Storage = New ValueStorage(SettingsStructure);
	CurrentObject.StorageOfExchangeSchemeFilter = Storage;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MobileApplicationVersionOnChange(Item)
	
	DownloadSelectionSettings();
	
EndProcedure

&AtClient
Procedure MobileApplicationVersionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure UseContactDetailsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RestoreStandardSettings(Command)
	
	DownloadStandardSettings();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
// Fills in the linker settings based on the passed parameters.
//
// Parameters:
//  The configuration schema is the data layout schema for which the settings are compiled.
//  Configuration Settings - layout settings that are loaded into the linker.
//
Procedure FillInComposerSettings(CompositionSchema, CompositionSettings)
	
	Address = New UUID();
	URLSchemes = PutToTempStorage(CompositionSchema, Address);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
	
	SettingsComposer.Initialize(SettingsSource);
	SettingsComposer.LoadSettings(CompositionSettings);
	
EndProcedure	

&AtServer
// Fills in the linker settings with previously saved selection data.
//
Procedure DownloadSelectionSettings()
	
	CompositionSchema = ExchangePlans.SalesRepresentativeMobileApplication.GetTemplate("CompositionSchemaOfExchangeSettings");
	CompositionSettings = CompositionSchema.DefaultSettings;
	FillInComposerSettings(CompositionSchema, CompositionSettings);
	
	NodeObject = FormAttributeToValue("Object");
	FilterStructure1 = NodeObject.StorageOfExchangeSchemeFilter.Get();
	
	If TypeOf(FilterStructure1) <> Type("Structure") Then
		Return;
	EndIf;
	
	If FilterStructure1.Count() > 0 Then	
		MobileApps.CompleteLayoutSelectionFromStructure(SettingsComposer.Settings.Filter, FilterStructure1);
	EndIf;

EndProcedure

&AtServer
// Fills the linker settings with the standard settings defined during development.
//
Procedure DownloadStandardSettings()
	
	CompositionSchema = ExchangePlans.SalesRepresentativeMobileApplication.GetTemplate("CompositionSchemaOfExchangeSettings");
	CompositionSettings = CompositionSchema.DefaultSettings;
	FillInComposerSettings(CompositionSchema, CompositionSettings);
	
EndProcedure

#EndRegion
