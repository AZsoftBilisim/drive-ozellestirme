#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

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
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		ThisForm.ParametersForm.Filter.Insert("Recorder", Parameters.CommandParameter);
	Else
		Cancel = True;
		Raise NStr("vi = 'Báo cáo chỉ nhằm mục đích mở trong chứng từ ""Số dư đầu kỳ SXDD theo bộ phận"".';
					|ru = 'Отчет предназначен только для открытия в документе ""Начальные остатки НЗП по подразделениям"".';
					|en = 'The report is used only to be opened in the document ""WIP opening balances by business units"".'; fa = 'The report is used only to be opened in the document ""WIP opening balances by business units"".';
					|it = 'Il report è destinato solo per aprire nel documento ""Saldi iniziali della produzione non completata per reparti""';
					|pl = 'Raport przeznaczony jest wyłącznie do otwarcia w dokumencie „Wstępne salda produkcji w toku wg działów”.';
					|tr = 'Rapor, sadece ""Departmanlara göre tamamlanamayan üretimin başlangıç bakiyeleri"" belgesinde açılmak içindir.'") ;
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	// Preparing the layout layout
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionProcessor = New DataCompositionProcessor;

	ReportSettings = SettingsComposer.GetSettings();
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	// Preparing report data
	LoggerParameter	= DataCompositionClientServer.GetParameter(ReportSettings, "Recorder");
	Recorder			= LoggerParameter.Value;
	ExternalDataSets	= Documents.InitialWIPBalancesByBusinessUnits.DistributeInitialBalancesAmongProductionBatches(Recorder);
	
	// Building a report
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// Post-processing of the report
	SpreadsheetDocument = OutputProcessor.EndOutput();
	
	// Setting the report title
	Area = SpreadsheetDocument.FindText("%1%");
	If Area <> Undefined Then
		
		Department = Common.ObjectAttributeValue(Recorder, "Department");
		ReportHeader = NStr("vi = 'Phân bổ số dư SXDD cho bộ phận ""%1""';
							|ru = 'Распределение остатков НЗП в подразделении ""%1""';
							|en = 'Allocation of WIP balances in the business unit ""%1""'; fa = 'Allocation of WIP balances in the business unit ""%1""';
							|it = 'Ripartizione dei saldi della produzione non completata nel reparto ""%1""';
							|pl = 'Podział pozostałości produkcji w toku wg działu „%1”';
							|tr = '""%1"" departmanının tamamlanamayan bakiyelerin dağıtımı'");
		ReportHeader =
			StringFunctionsClientServer.SubstituteParametersToString(
				ReportHeader,
				Department);
		
		Area.Text = StrReplace(Area.Text, "%1%", ReportHeader);
		
	EndIf;
	
	// Setting currency headers.
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	
	Area = SpreadsheetDocument.FindText("%2%");
	While Not Area = Undefined Do
		Area.Text = StrReplace(Area.Text, "%2%", CurrencyOfMan);
		Area = SpreadsheetDocument.FindText("%2%");
	EndDo;
	
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
	
EndProcedure

#EndRegion

#EndIf
