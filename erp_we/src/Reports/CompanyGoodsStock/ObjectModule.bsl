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
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - The Form of the report. Contains including:
//   	* Parameters - Structure - The parameter structure contains, among other things:
//   		** CommandDetails - Structure:
//   			*** AdditionalParameters - Structure:
//   				**** CommandName - String
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails")
		And Parameters.CommandDetails.Property("AdditionalParameters") Then
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "ListOfProductsOfOrganizations" Then
			ThisForm.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
	If Not GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		
		DataCompositionSchemaOfForm = GetFromTempStorage(ThisForm.ReportSettings.SchemaURL); // DataCompositionSchema
		DataCompositionSchemaOfForm.Parameters.Find("IncludeTransferOfInventoryOfOtherCompanies").UseRestriction = True;
		PutToTempStorage(DataCompositionSchemaOfForm, ThisForm.ReportSettings.SchemaURL);
		
	EndIf;
	
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
//	NewDCUserSettings	- DataCompositionUserSettings,Undefined - custom settings that will be loaded into
//																							the settings Builder after it is initialized.
//																							Undefined when user settings do not need to be loaded
//																							(already loaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	If NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	SchemaKey		= VariantKey;
	FieldHeaders	= ParameterizableFieldHeaders();
	
	AccountingInFEACNUnitOfMeasurementIsUsed = AccountingForTraceableGoodsLocalization.AccountingInFEACNUnitOfMeasurementIsUsed();
	
	If Not AccountingInFEACNUnitOfMeasurementIsUsed Then
		HideFields(NewDCSettings.Structure, "Products.FEACNUnitOfMeasure");
	EndIf;
	
	DataCompositionServer.SetHeadersOfSelectedFields(NewDCSettings.Selection.Items, FieldHeaders);
	DataCompositionServer.SetDimensionFieldHeaders(NewDCSettings.Structure, FieldHeaders);
	
	If TypeOf(NewDCUserSettings) <> Type("DataCompositionUserSettings") Then
		Return;
	EndIf;
	
	SettingID = NewDCSettings.Selection.UserSettingID;
	
	If ValueIsFilled(SettingID) Then
		FoundSettingElement = NewDCUserSettings.Items.Find(SettingID);
		
		If FoundSettingElement <> Undefined Then
			DataCompositionServer.SetHeadersOfSelectedFields(FoundSettingElement.Items, FieldHeaders);
		EndIf;
	EndIf;
	
	SettingID = NewDCSettings.Structure.UserSettingID;
	
	If ValueIsFilled(SettingID) Then
		FoundSettingElement = NewDCUserSettings.Items.Find(SettingID);
		
		If FoundSettingElement <> Undefined Then
			If Not AccountingInFEACNUnitOfMeasurementIsUsed Then
				HideFields(NewDCSettings.Structure, "Products.FEACNUnitOfMeasure");
			EndIf;
			
			DataCompositionServer.SetDimensionFieldHeaders(FoundSettingElement.Items, FieldHeaders);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	DataCompositionClientServer.SetParameter(SettingsComposer,
													"CompanyVATTaxation",
													NStr("vi = 'Chính sách thuế GTGT của doanh nghiệp';
														|ru = 'Налогообложение НДС организации';
														|en = 'Company VAT taxation'; fa = 'Company VAT taxation';
														|it = 'Tassazione IVA dell''azienda';
														|pl = 'Opodatkowanie VAT firmy';
														|tr = 'İş yerinin KDV vergilendirmesi'"),
													True);
	DataCompositionClientServer.SetParameter(SettingsComposer,
													"CompanyOwnerVATTaxation",
													NStr("vi = 'Thuế GTGT của doanh nghiệp chủ sở hữu';
														|ru = 'Налогообложение НДС организации-владельца';
														|en = 'VAT taxation of the company owner'; fa = 'مالیات‌ستانی VAT شرکت مالک';
														|it = 'Tassazione IVA dell''azienda-titolare';
														|pl = 'Opodatkowanie VAT firmy-właściciela';
														|tr = 'İş yeri sahibinin KDV vergilendirmesi'"),
													True);
	DataCompositionClientServer.SetParameter(SettingsComposer,
													"CompanySellerVATTaxation",
													NStr("vi = 'Thuế GTGT của người bán';
														|ru = 'Налогообложение НДС организации-продавца';
														|en = 'VAT taxation of the company seller'; fa = 'مالیات‌ستانی VAT شرکت فروشنده';
														|it = 'Tassazione IVA dell''azienda-venditrice';
														|pl = 'Opodatkowanie VAT firmy-sprzedawcy';
														|tr = 'Satıcı iş yerinin KDV vergilendirmesi'"),
													True);
	
	DataCompositionSchemaDataSetUnion = DataCompositionSchema.DataSets.CompanyGoods; // DataCompositionSchemaDataSetUnion 
	
	QueryText = DataCompositionSchemaDataSetUnion.Items.CompanyGoods.Query;
	QueryText = StrReplace(QueryText,
								"&QueryTextItemWeight1",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
									"DimensionOfProductItem.Products.UnitOfMeasure",
									"DimensionOfProductItem.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextTheVolumeOfTheItem1",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
									"DimensionOfProductItem.Products.UnitOfMeasure",
									"DimensionOfProductItem.Products"));

	DataCompositionSchemaDataSetUnion.Items.CompanyGoods.Query = QueryText;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	ExcludeTurnoverOnImportedGoodsWithEmptyCCDNumber = DataCompositionClientServer.GetParameter(ReportSettings, "ExcludeTurnoverOnImportedGoodsWithEmptyCCDNumber");
	If ExcludeTurnoverOnImportedGoodsWithEmptyCCDNumber.Use 
			And ExcludeTurnoverOnImportedGoodsWithEmptyCCDNumber.Value = True Then
		SecondPeriod = DataCompositionSchemaDataSetUnion.Fields.Find("SecondPeriod");
		If SecondPeriod <> Undefined Then
			SecondPeriod.Role.Required = True;
		EndIf;
		PeriodRegistrar = DataCompositionSchemaDataSetUnion.Fields.Find("Recorder");
		If PeriodRegistrar <> Undefined Then
			PeriodRegistrar.Role.Required = True;
		EndIf;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema,
																SettingsComposer,
																ResultDocument,
																AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	
	Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "IncludeTransferOfInventoryOfOtherCompanies");
	Parameter.Use = True;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
EndProcedure

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;
	
EndFunction

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

// Disables the use of fields in the data layout settings by the specified name.
//
// Parameters:
//	Fields - DataCompositionSelectedFieldCollection,
//			Collections of Field groupings of Data components,
//			Collection of elements of the structureconstructioncomposed,
//			The collection of User-defined Data setups is the data layout fields that you want to disable
//																		using, by the specified name.
//	FieldName - String - name of the field for which you want to disable the use of
//						For example, "Nomenclature", "Nomenclature.Code".
//
Procedure HideFields(Fields, FieldName)
	
	For Each Field In Fields Do
		If TypeOf(Field) = Type("DataCompositionGroup") Then
			HideFields(Field.Structure, FieldName);
			HideFields(Field.Selection.Items, FieldName);
			HideFields(Field.GroupFields.Items, FieldName);
		ElsIf TypeOf(Field) = Type("DataCompositionSelectedFieldGroup") Then
			HideFields(Field.Items, FieldName);
		ElsIf TypeOf(Field) = Type("DataCompositionSelectedField")
			Or TypeOf(Field) = Type("DataCompositionGroupField") Then
			
			If String(Field.Field) = FieldName Then
				Field.Use = False;
			EndIf;
			
		ElsIf TypeOf(Field) = Type("DataCompositionAutoSelectedField") Then
			Continue;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf