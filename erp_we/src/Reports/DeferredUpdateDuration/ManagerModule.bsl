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
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "DeferredUpdateDuration");
	OptionSettings.LongDesc = NStr("vi = 'Thời lượng thực hiện thủ tục xử lý dữ liệu bổ sung
		|có gom nhóm theo trình tự cập nhật.';
		|ru = 'Длительность выполнения дополнительных процедур обработки данных
		|с группировкой по порядку обновления.';
		|en = 'The duration of additional data processing procedures
		|with grouping by update order.'; fa = 'The duration of additional data processing procedures
		|with grouping by update order.';
		|it = 'Длительность выполнения дополнительных процедур обработки данных
		|с группировкой по порядку обновления.';
		|pl = 'The duration of additional data processing procedures
		|with grouping by update order.';
		|tr = 'Güncelleme sırasına göre gruplandırılan 
		|ek veri işleme prosedürünün tamamlanma süresi.'");
	OptionSettings.SearchSettings.Keywords = NStr("vi = 'Thời lượng cập nhật hoãn lại';
													|ru = 'Длительность отложенного обновления';
													|en = 'Deferred update duration'; fa = 'مدت به‌روزرسانی معوق';
													|it = 'Длительность отложенного обновления';
													|pl = 'Deferred update duration';
													|tr = 'Ertelenmiş güncelleme süresi'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf