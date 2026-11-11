#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionProcessor = New DataCompositionProcessor;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	// Setting parameters
	
	DataCompositionClientServer.SetParameter(
		ReportSettings,
		"DesignationStep",
		NStr("vi = 'Công đoạn';
			|ru = 'Этап';
			|en = 'Stage'; fa = 'مرحله';
			|it = 'Этап';
			|pl = 'Stage';
			|tr = 'Aşama'"));
	
	DataCompositionClientServer.SetParameter(
		ReportSettings,
		"DesignationProduct",
		NStr("vi = 'Mặt hàng';
			|ru = 'Номенклатура';
			|en = 'Item'; fa = 'قلم';
			|it = 'Item';
			|pl = 'Item';
			|tr = 'Öğe'"));
		
	DataCompositionClientServer.SetParameter(
		ReportSettings,
		"InTotal",
		NStr("vi = 'Tổng số';
			|ru = 'Итого';
			|en = 'Total'; fa = 'جمع کل';
			|it = 'Итого';
			|pl = 'Total';
			|tr = 'Toplam'"));
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True, False);
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor); 
	
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
	Settings.Events.BeforeLoadVariantAtServer = True;
EndProcedure

// See ReportsOverridable.BeforeLoadVariantAtServer.
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		Form.ParametersForm.Filter.Insert("ProductionOrder", Parameters.CommandParameter);
		DataCompositionClientServer.SetParameter(NewDCSettings, "Period", New StandardPeriod());
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
