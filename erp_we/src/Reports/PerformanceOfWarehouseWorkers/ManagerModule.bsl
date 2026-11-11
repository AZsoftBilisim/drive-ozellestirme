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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PerformanceOfWarehouseWorkers);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá số lượng nhiệm vụ đã xử lý bởi nhân viên kho.';
									|ru = 'Оценка количества обработанных складскими сотрудниками заданий.';
									|en = 'Evaluation of quantity of jobs processed by warehouse workers.'; fa = 'Evaluation of quantity of jobs processed by warehouse workers.';
									|it = 'Оценка количества обработанных складскими сотрудниками заданий.';
									|pl = 'Ocena ilości przetworzonych zadań pracownikami magazynów.';
									|tr = 'Ambar çalışanları tarafından işlenen görevlerin değerlendirilmesi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PerformanceOfWarehouseWorkers");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá số lượng hàng hóa đã xử lý bởi các nhân viên kho trong kỳ.
		|Bao nhiêu hàng hóa đã được tiếp nhận, lấy ra, xếp vào hoặc kiểm đếm?';
		|ru = 'Оценка количества обработанных складскими сотрудниками грузов за период.
		|Сколько приемок, размещений, отборов или пересчетов было сделано?';
		|en = 'Estimate the cargo quantity processed by warehouse workers for a period.
		|Verify how many receipts, put-away, pickings, or recounts have been made.'; fa = 'Estimate the cargo quantity processed by warehouse workers for a period.
		|Verify how many receipts, put-away, pickings, or recounts have been made.';
		|it = 'Оценка количества обработанных складскими сотрудниками грузов за период.
		|Сколько приемок, размещений, отборов или пересчетов было сделано?';
		|pl = 'Ocena ilości przetworzonych ładunków pracownikami magazynów za okres. 
		|Ile akceptacji, rozmieszczeń, selekcji lub przeliczeń zostało zrobione?';
		|tr = 'Dönem için ambar çalışanları tarafından işlenen ürün sayısının değerlendirilmesi.
		|Kaç adet kabul, yerleştirme, geri çekme veya yeniden hesaplama yapıldı?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
