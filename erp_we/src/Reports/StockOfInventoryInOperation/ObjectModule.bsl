#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	ReportParameters = ReportParameters(MainCircuitSettings);
	
	If Upper(ReportParameters.InventoryAssessment) = Upper("ByPriceType")
		And Not ValueIsFilled(ReportParameters.PriceKind) Then
		
		MessageText = NStr("vi = 'Để đánh giá giá trị, cần chỉ ra dạng giá trong tùy chỉnh báo cáo.';
							|ru = 'Для оценки стоимости необходимо указать вид цены в настройках отчета.';
							|en = 'To valuate cost, specify the price type in the report settings.'; fa = 'To valuate cost, specify the price type in the report settings.';
							|it = 'Per la valutazione del costo è necessario indicare il tipo di prezzo nelle impostazioni di report.';
							|pl = 'Aby ocenić wartość należy podać rodzaj ceny w ustawieniach raportu.';
							|tr = 'Maliyeti belirlemek için rapor ayarlarında fiyat türünü belirtmeniz gerekir.'");
		Common.MessageToUser(MessageText,,,, Cancel); 
		
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	QueryText = DataCompositionSchema.DataSets.DataSet.Query;
	
	QueryText = StrReplace(
		QueryText,
		"&QueryTextItemWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"InventoryInOperation.Products.UnitOfMeasure",
			"InventoryInOperation.Products"));
									
	QueryText = StrReplace(
		QueryText,
		"&QueryTextTheVolumeOfTheItem",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
			"InventoryInOperation.Products.UnitOfMeasure",
			"InventoryInOperation.Products"));
	
	QueryText = StrReplace(
		QueryText, 
		"&TextOfRequestIsPackingCoefficientOfProductPrice", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsPrices.Package", 
			"ItemsPrices.Products"));

	DataCompositionSchema.DataSets.DataSet.Query = QueryText;
	
	SetReportParameters();

	MainCircuitSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfDynamicHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(
		DataCompositionSchema,
		SettingsComposer,
		ResultDocument,
		AuxiliaryReportParameters());
	
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
	
	If Parameters.Property("CommandParameter") Then
		
		If Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then
			
			If Parameters.CommandDetails.AdditionalParameters.CommandName = "StockOfInventoryInOperation" Then
				ThisForm.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
			EndIf;
		EndIf;
		
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
//	NewDCUserSettings	- DataCompositionUserSettings, Undefined - custom settings that will be loaded into
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
	
	SchemaKey = VariantKey;
	FieldHeaders = ParameterizableFieldHeaders();
	
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
			DataCompositionServer.SetDimensionFieldHeaders(FoundSettingElement.Items, FieldHeaders);
		EndIf;
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
	
	OverridingHeaders = New Structure;
	OverridingHeaders.Insert("TotalInStorageUnits", NStr("vi = 'Tổng số theo đơn vị lưu kho';
														|ru = 'Итого в единицах хранения';
														|en = 'Total in stock UOM'; fa = 'Total in stock UOM';
														|it = 'Totale in unità di stoccaggio';
														|pl = 'Łącznie w jednostkach przechowywania';
														|tr = 'Depolama birimlerindeki toplam'"));
	OverridingHeaders.Insert("TotalInUnitsForReports", NStr("vi = 'Tổng số theo đơn vị báo cáo';
															|ru = 'Итого в единицах для отчетов';
															|en = 'Total in report UOM'; fa = 'Total in report UOM';
															|it = 'Totale in unità per i report';
															|pl = 'Łącznie w jednostkach dla raportów';
															|tr = 'Raporlama için birimlerdeki toplam'"));

	TheStructureOfTheHeaders = DataCompositionServer.UnitFieldHeaders(SettingsComposer, OverridingHeaders);
	
	Return TheStructureOfTheHeaders;
	
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

Procedure SetReportParameters()
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "CurrentDate", CurrentSessionDate());
	DataCompositionClientServer.SetParameter(SettingsComposer, "CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	PriceManagementSystem.SetVSKDPricingOption(SettingsComposer);
	
EndProcedure

Function ReportParameters(MainCircuitSettings)

	DataSelectionValues = New Structure;
	DataSelectionValues.Insert("InventoryAssessment", TMReportsServer.ParameterValue(MainCircuitSettings, "InventoryAssessment"));
	DataSelectionValues.Insert("PriceKind", TMReportsServer.ParameterValue(MainCircuitSettings, "PriceKind"));
	
	Return DataSelectionValues;
	
EndFunction

#EndRegion

#EndIf