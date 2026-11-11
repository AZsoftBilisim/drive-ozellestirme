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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.IncidentRegistry);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Danh sách tất cả sự cố theo người thực hiện.
		|Những sự cố nào được ghi nhận cho người thực hiện?
		|Người sử dụng có bao nhiêu sự cố và quá hạn bao nhiêu ngày?';
		|ru = 'Список всех инцидентов по исполнителю.
		|Какие инциденты зарегистрированы на исполнителя?
		|Сколько у исполнителя инцидентов и на сколько дней просрочены?';
		|en = 'View the list of all incidents by the assignee.
		|Verify which incidents are registered for the assignee.
		|Check how many incidents the assignee has. Track how many days the incidents are overdue.'; fa = 'View the list of all incidents by the assignee.
		|Verify which incidents are registered for the assignee.
		|Check how many incidents the assignee has. Track how many days the incidents are overdue.';
		|it = 'Список всех инцидентов по исполнителю.
		|Какие инциденты зарегистрированы на исполнителя?
		|Сколько у исполнителя инцидентов и на сколько дней просрочены?';
		|pl = 'Lista wszystkich incydentów według wykonawcy.
		|Jakie incydenty są zarejestrowane na wykonawcę?
		|Ile wykonawca ma incydentów i o ile dni są one przeterminowane?';
		|tr = 'Atanana göre tüm olayların listesi.
		|Atananda hangi olaylar kayıtlıdır?
		|Atananın kaç tane olayı var ve kaç gün gecikti?'"); 
	OptionDetails.FunctionalOptions.Add("UseIncidents");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	DescriptionOfReport.DefaultVisibility = True;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
