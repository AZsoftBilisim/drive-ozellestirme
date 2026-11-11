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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "DeferredUpdateProgress");
	OptionSettings.LongDesc = NStr("vi = 'Tiến trình thực hiện thủ tục xử lý dữ liệu bổ sung.';
									|ru = 'Прогресс выполнения дополнительных процедур обработки данных.';
									|en = 'Progress of additional data processing procedures.'; fa = 'Progress of additional data processing procedures.';
									|it = 'Progresso di esecuzione delle ulteriori procedure di elaborazione dei dati.';
									|pl = 'Postęp wykonania dodatkowych procedur przetwarzania danych.';
									|tr = 'Ek veri işleme prosedürleri yürütülüyor.'");
	OptionSettings.SearchSettings.Keywords = NStr("vi = 'Cập nhật hoãn lại';
													|ru = 'Отложенное обновление';
													|en = 'Deferred update'; fa = 'به‌روزرسانی معوق';
													|it = 'Aggiornamento posticipato';
													|pl = 'Odroczona aktualizacja';
													|tr = 'Ertelenmiş güncelleme'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf