//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AnalysisOfTransactionsOfOperationalAccounting);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.DefaultVisibility = False;
	OptionDetails.FunctionalOptions.Add("SettingOfPostingByAccountingObjects");
	OptionDetails.LongDesc = NStr("vi = 'Bút toán theo đối tượng kế toán được tạo trong các biểu ghi tài chính
		| có áp dụng tùy chỉnh tài khoản và tùy chỉnh phản ánh đối ứng.';
		|ru = 'Сформированные в финансовых регистрах проводки по объектам учета
		|с применением настроек счетов и настроек отражения корреспонденций.';
		|en = 'Accounting object entries generated in financial registers
		|using account settings and correspondence recording settings.'; fa = 'Accounting object entries generated in financial registers
		|using account settings and correspondence recording settings.';
		|it = 'Сформированные в финансовых регистрах проводки по объектам учета
		|с применением настроек счетов и настроек отражения корреспонденций.';
		|pl = 'Utworzone w rejestrach finansowych wpisów księgowych według obiektów ewidencji
		|z zastosowanie ustawień kont i ustawień odzwierciedlenia korespondencji.';
		|tr = 'Hesap ayarları ve muhabir yansıtma ayarları kullanılarak
		| muhasebe nesneleri için finansal kayıtlarda oluşturulan girişler.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AnalysisOfTransactionsOfOperationalAccounting");
	OptionDetails.DefaultVisibility = False;
	OptionDetails.FunctionalOptions.Add("SettingOfPostingByAccountingObjects");
	OptionDetails.LongDesc = NStr("vi = 'Bút toán theo đối tượng kế toán được tạo trong các biểu ghi tài chính
		| có áp dụng tùy chỉnh tài khoản và tùy chỉnh phản ánh đối ứng.';
		|ru = 'Сформированные в финансовых регистрах проводки по объектам учета
		|с применением настроек счетов и настроек отражения корреспонденций.';
		|en = 'Accounting object entries generated in financial registers
		|using account settings and correspondence recording settings.'; fa = 'Accounting object entries generated in financial registers
		|using account settings and correspondence recording settings.';
		|it = 'Сформированные в финансовых регистрах проводки по объектам учета
		|с применением настроек счетов и настроек отражения корреспонденций.';
		|pl = 'Utworzone w rejestrach finansowych wpisów księgowych według obiektów ewidencji
		|z zastosowanie ustawień kont i ustawień odzwierciedlenia korespondencji.';
		|tr = 'Hesap ayarları ve muhabir yansıtma ayarları kullanılarak
		| muhasebe nesneleri için finansal kayıtlarda oluşturulan girişler.'");

	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ErrorsInOnlineAccountingTransactions");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
