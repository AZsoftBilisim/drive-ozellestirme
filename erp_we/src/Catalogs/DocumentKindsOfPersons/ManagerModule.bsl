#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - name of the table part of the object
//                               Value-Uploading an empty table part to the table of values
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	#Region DriverLicense
	Item = Items.Add();
	Item.PredefinedDataName = "DriverLicense";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giấy phép lái xe';
																					|ru = 'Водительское удостоверение';
																					|en = 'Driver license';
																					|it = 'Patente di guida';
																					|pl = 'Prawo jazdy';
																					|tr = 'Ehliyet'", LanguagesCodes); // @NStr-2
	#EndRegion

	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.CashFlowReportItems - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
EndProcedure

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.DocumentKindsOfPersons);
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
EndProcedure

#EndRegion

#EndIf
