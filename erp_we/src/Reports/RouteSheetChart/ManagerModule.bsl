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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.RouteSheetChart);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.FunctionalOptions.Add("UseRouteSheets");
	OptionDetails.LongDesc = NStr("vi = 'Trình tự thực hiện các giao dịch theo sơ đồ quy trình.';
									|ru = 'Последовательность выполнения операций маршрутной карты в виде схемы.';
									|en = 'View the sequence of route sheet operations (flow chart view).'; fa = 'View the sequence of route sheet operations (flow chart view).';
									|it = 'Последовательность выполнения операций маршрутной карты в виде схемы.';
									|pl = 'Kolejność wykonywania operacji karty technologicznej w rodzaju schematu.';
									|tr = 'Rotanın şema biçimindeki işlem gerçekleştirme sırası.'");
	OptionDetails.SearchSettings.FieldDescriptions = NStr("vi = 'Dạng thao tác
		|Bộ phận
		|Dạng nguồn lực sản xuất';
		|ru = 'Вид операции
		|Подразделение
		|Вид рабочего центра';
		|en = 'Operation type
		|Business unit
		|Work center type'; fa = 'Operation type
		|Business unit
		|Work center type';
		|it = 'Вид операции
		|Подразделение
		|Вид рабочего центра';
		|pl = 'Typ operacji
		|Dział
		|Rodzaj centrum wykonania pracy';
		|tr = 'İşlem türü
		|Departman
		|İş merkezi türü'");
	OptionDetails.SearchSettings.FilterParameterDescriptions = NStr("vi = 'Sơ đồ quy trình
		|Giao dịch trong các lộ trình lồng trong';
		|ru = 'Маршрутная карта
		|Операции вложенных маршрутов';
		|en = 'Route sheet
		|Nested route operations'; fa = 'Route sheet
		|Nested route operations';
		|it = 'Маршрутная карта
		|Операции вложенных маршрутов';
		|pl = 'Karta technologiczna
		|Operacje włożonych tras';
		|tr = 'Rota
		|İç içe harita işlemleri'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
