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
	
	Settings.Events.OnCreateAtServer            = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	
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
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
		And ValueIsFilled(Parameters.CommandParameter) Then
		
		DocumentAttributes = Common.ObjectAttributesValues(Parameters.CommandParameter, "Date,Warehouse");
		AdvancedWarehousingIsUsed = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(
										DocumentAttributes.Warehouse, DocumentAttributes.Date);
		
		If Not AdvancedWarehousingIsUsed Then
			
			Cancel = True;
			
			MessageText = NStr("vi = 'Báo cáo được dùng để hiển thị thông tin theo các kho có sử dụng sơ đồ hai pha khi phản ánh hàng thừa, hàng thiếu, chuyển tồn và hàng hỏng. 
			|Trong kho %Warehouse% vào ngày %Date% không sử dụng sơ đồ hai pha tương ứng.';
			|ru = 'Отчет предназначен для вывода информации по складам, использующим ордерную схему при отражении излишков, недостач, пересортицы и порчи. 
			|На складе %Warehouse% на %Date% не используется соответствующая ордерная схема.';
			|en = 'The report is designed to display information on warehouses with enabled warehouse management while recording surplus, shortage, stock reclass, and stock quality change.
			|The corresponding warehouse management is not used in the %Warehouse% warehouse as of %Date%.'; fa = 'The report is designed to display information on warehouses with enabled warehouse management while recording surplus, shortage, stock reclass, and stock quality change.
			|The corresponding warehouse management is not used in the %Warehouse% warehouse as of %Date%.';
			|it = 'Il report è progettato per visualizzare informazioni sui magazzini che utilizzano lo schema degli ordini nel riflesso di eccedenze, ammanchi, reinquadramenti  e danni.
			| Nel magazzino %Warehouse% il %Date% non viene utilizzato lo schema dei mandati corrispondente.';
			|pl = 'Raport jest przeznaczony do wyświetlania informacji dla sklepów korzystających  ze schematu zamówieniowego w czasie odzwierciedlenia nadwyżki, braków, przeklasyfikowania i zepsucia. 
			| W magazynie %Warehouse% na dzień %Date% nie jest używany odpowiedni schemat zamówieniowy.';
			|tr = 'Rapor, fazlalıkları, eksiklikleri, yeniden sınıflandırmayı ve stok kalite değişikliğini yansıtırken ambar yönetimi kullanan ambarlar hakkındaki bilgileri görüntülemek için tasarlanmıştır. 
			| %Warehouse% ambarında %Date%''de karşılık gelen ambar yönetimi kullanılmıyor.'");
			
			MessageText = StrReplace(MessageText, "%Warehouse%", DocumentAttributes.Warehouse);
			MessageText = StrReplace(MessageText, "%Date%", Format(DocumentAttributes.Date,"DLF=D"));
			
			Raise MessageText;
			
		EndIf;
		
		ThisForm.ParametersForm.Filter.Insert("Warehouse", DocumentAttributes.Warehouse);
		
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	StandardProcessing = False;
	UserSettingsModified = False;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);

	ReportSettings = SettingsComposer.GetSettings();
	
	QueryText = DataCompositionSchema.DataSets.DataSet.Query;

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("ToRegister.Products.UnitOfMeasure", "ToRegister.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("ToRegister.Products.UnitOfMeasure", "ToRegister.Products"));

	DataCompositionSchema.DataSets.DataSet.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
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

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf