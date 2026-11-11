#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form or report settings.
//         - ManagedFormExtensionForReports
//         - Structure:
//           * ReportSettings - See ReportsClientServer.DefaultReportSettings
//  NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//  Form - See ReportsOverridable.OnCreateAtServer.Form
//  Cancel - See ReportsOverridable.OnCreateAtServer.Cancel
//  StandardProcessing - See ReportsOverridable.OnCreateAtServer.StandardProcessing
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	If Not Form.Parameters.Property("CommandParameter") Or Not ValueIsFilled(Form.Parameters.CommandParameter) Then
		MessageText = NStr("vi = 'Không hỗ trợ mở trực tiếp báo cáo ""Kế hoạch mua hàng"". 
			|Để mở báo cáo, có thể sử dụng lệnh ""Kế hoạch mua hàng"" trên các biểu mẫu chứng từ.';
			|ru = 'Непосредственное открытие отчета ""План закупок"" не предусмотрено. 
			|Для открытия отчета можно воспользоваться командой ""План закупок"" в формах документов.';
			|en = 'Direct opening of the ""Purchase plan"" report is not provided. 
			|To open the report, click ""Purchase plan"" in the document forms.'; fa = 'Direct opening of the ""Purchase plan"" report is not provided. 
			|To open the report, click ""Purchase plan"" in the document forms.';
			|it = 'Non è prevista l''apertura diretta del report ""Piano di acquisti"".
			| Per aprire il report è possibile utilizzare il comando ""Piano degli acquisti"" nei moduli dei documenti.';
			|pl = 'Bezpośrednie otwarcie raportu ""Plan zakupów"" nie jest przewidziane. 
			|Do otwarcia raportu można skorzystać z polecenia ""Plan zakupów"" w formularzach dokumentów.';
			|tr = '""Satın alma planı"" raporu açılması sağlanamadı. 
			| Raporun açılması için belge formunda yer alan ""Satın alma planı"" komutundan faydalanabilirsiniz.'");
		Raise MessageText;
	EndIf;

	Form.ParametersForm.Filter.Insert("PurchasePlan", Form.Parameters.CommandParameter);
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   NewDCUserSettings - DataCompositionUserSettings -
//       Custom settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form Extension for the report.Prizagruzkepusersing settings in the server"
//    in the syntax assistant.
//
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export
	
	If Form.Parameters.Property("CommandParameter") Then
		
		Period = Common.ObjectAttributesValues(Form.Parameters.CommandParameter, "BeginOfPeriod, PeriodEnding, Periodicity");
		DataCompositionClientServer.SetParameter(
			SettingsComposer,
			"Period",
			New StandardPeriod(Period.BeginOfPeriod, Period.PeriodEnding),
			ValueIsFilled(Period));
		
		DataCompositionClientServer.SetParameter(
			SettingsComposer,
			"Periodicity",
			Period.Periodicity,
			ValueIsFilled(Period));
		
		NewDCUserSettings = SettingsComposer.GetSettings();
	EndIf;

	
EndProcedure

#EndRegion

#EndIf
