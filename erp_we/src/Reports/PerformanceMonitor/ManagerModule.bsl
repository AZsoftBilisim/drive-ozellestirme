///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.ReportsOptions

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportsOptionsAvailable = PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.ReportsOptions");
	If ReportsOptionsAvailable Then
		ModuleReportsOptions = PerformanceMonitorInternal.CommonModule("ReportsOptions");
		
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorByKeyOperations"); // See ReportsOptions.OptionDetails		
		OptionSettings.LongDesc = 
			NStr("vi = 'Cung cấp thông tin về đánh giá hiệu suất';
				|ru = 'Предоставляет информацию об оценке производительности';
				|en = 'Provides Apdex metrics.'; fa = 'Provides Apdex metrics.';
				|it = 'Fornisce l''informazione sulla valutazione delle prestazioni';
				|pl = 'Dostarcza informacji o ocenie wydajności';
				|tr = 'Performans İzleyici hakkında bilgiler sağlar'");
			
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorComparison"); // See ReportsOptions.OptionDetails
		OptionSettings.LongDesc = 
			NStr("vi = 'Cung cấp thông tin về so sánh đánh giá hiệu suất trong kỳ';
				|ru = 'Предоставляет информацию о сравнении оценки производительности за период';
				|en = 'Compares Apdex metrics during a period'; fa = 'Compares Apdex metrics during a period';
				|it = 'Fornisce l''informazione sul confronto valutazione delle prestazioni per il periodo';
				|pl = 'Dostarcza informacji dot. porównania oceny wydajności za okres';
				|tr = 'Performans İzleyici hakkında döneme göre bildi sağlar'");
			
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorPeriodInColumns"); // See ReportsOptions.OptionDetails
		OptionSettings.LongDesc = 
			NStr("vi = 'Cung cấp thông tin về đánh giá hiệu suất theo từng kỳ. Kỳ được trình bày trong các cột';
				|ru = 'Предоставляет информацию об оценке производительности в разрезе периодов. Периоды представлены в колонках';
				|en = 'Provides Apdex metrics by period.'; fa = 'Provides Apdex metrics by period.';
				|it = 'Fornisce l''informazione sul confronto valutazione delle prestazioni nel contesto dei periodi. I periodi vengono riportati nelle colonne';
				|pl = 'Dostarcza informacji o ocenie wydajności w kontekście okresów. Okresy są prezentowane w kolumnach';
				|tr = 'Dönemlere göre performans değerlendirmesi hakkında bilgi verir. Dönemler sütunlar halinde sunulur'");
	EndIf;
			
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
