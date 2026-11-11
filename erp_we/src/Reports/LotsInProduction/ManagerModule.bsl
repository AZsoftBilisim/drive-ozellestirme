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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.LotsInProduction);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Thành phẩm được xuất xưởng theo những lô hàng nào?
	|Bộ phận nào đang thực hiện và thực hiện trong công đoạn nào?
	|Thời hạn sản xuất dự tính là khi nào, có chậm trễ không?';
	|ru = 'По каким партиям запущено производство?
	|В каком подразделении и на каком этапе (операции) находится выполнение?
	|Какие плановые сроки производства, есть ли задержка?';
	|en = 'Check by which lots production is running.
	|Track the business unit in charge and the execution stage (operation).
	|Verify the planned production duration and any possible delay.'; fa = 'Check by which lots production is running.
	|Track the business unit in charge and the execution stage (operation).
	|Verify the planned production duration and any possible delay.';
	|it = 'По каким партиям запущено производство?
	|В каком подразделении и на каком этапе (операции) находится выполнение?
	|Какие плановые сроки производства, есть ли задержка?';
	|pl = 'Według jakich partii uruchomiono produkcję? 
	|W jakim dziale i na jakim etapie (operacji) znajduje się wykonanie? 
	|Jakie planowe terminy produkcji, czy jest opóźnienie?';
	|tr = 'Hangi lotlarda üretim başladı?
	|Gerçekleştirme hangi departmanda ve (işlemin) hangi aşamasında?
	|Planlanan üretim tarihleri ​​nedir, gecikme var mı?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
