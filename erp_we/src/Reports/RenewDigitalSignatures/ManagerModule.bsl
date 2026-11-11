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
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	Else
		Return;
	EndIf;
	
	If Not Common.DataSeparationEnabled()
		Or Common.SeparatedDataUsageAvailable() Then
		RefineSignaturesAutomatically = Constants.RefineSignaturesAutomatically.Get();
		AddTimestampsAutomatically = Constants.AddTimestampsAutomatically.Get();
	Else
		RefineSignaturesAutomatically = 0;
		AddTimestampsAutomatically = False;
	EndIf;
	
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, True);
	ReportSettings.DefineFormSettings = True;
	ReportSettings.LongDesc = NStr("vi = 'Chữ ký cần gia hạn hiệu lực.';
									|ru = 'Подписи, срок действия которых должен быть продлен.';
									|en = 'Expiring signatures to be renewed.'; fa = 'Expiring signatures to be renewed.';
									|it = 'Firme il cui periodo di validità deve essere prorogato.';
									|pl = 'Podpisy, których termin ważności powinien być przedłużony.';
									|tr = 'Geçerlilik süresi uzatılacak imzalar.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "rawsignatures");
	OptionSettings.LongDesc = NStr("vi = 'Hiển thị chữ ký cần xác định kiểu và nâng cấp theo tùy chỉnh.';
									|ru = 'Выводит подписи, у которых нужно определить тип и усовершенствовать согласно настройкам.';
									|en = 'Displays signatures that are subject to enhancement (after their types are determined).'; fa = 'Displays signatures that are subject to enhancement (after their types are determined).';
									|it = 'Firme presso le quali bisogna definire il tipo e perfezionare in base alle impostazioni.';
									|pl = 'Wyświetla podpisy, dla których nie trzeba określać typu i udoskonalić zgodnie z ustawieniami.';
									|tr = 'Türü belirlenecek ve ayarlar doğrultusunda iyileştirilecek imzaları çıkarır.'");
	OptionSettings.Enabled = RefineSignaturesAutomatically <> 0;

	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "RequireImprovementSignatures");
	OptionSettings.LongDesc = NStr("vi = 'Hiển thị chữ ký cần nâng cấp.';
									|ru = 'Выводит подписи, которые требуется усовершенствовать.';
									|en = 'Displays signatures to be enhanced.'; fa = 'Displays signatures to be enhanced.';
									|it = 'Firme da perfezionare.';
									|pl = 'Wyświetla podpisy, które należy udoskonalić.';
									|tr = 'İyileştirilecek imzaları çıkarır.'");
	OptionSettings.Enabled = RefineSignaturesAutomatically <> 0;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "RequiredAddArchiveTags");
	OptionSettings.LongDesc = NStr("vi = 'Hiển thị chữ ký, trong đó cần thêm dấu lưu trữ.';
									|ru = 'Выводит подписи, в которые пора добавить архивные метки.';
									|en = 'Displays signatures that require archive timestamps.'; fa = 'Displays signatures that require archive timestamps.';
									|it = 'Firme a cui aggiungere contrassegni di archivio.';
									|pl = 'Wyświetla podpisy, do których pora dodać znaczniki archiwalne.';
									|tr = 'Arşiv işareti konulacak imzaları çıkarır.'");
	OptionSettings.Enabled = AddTimestampsAutomatically;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ErrorsOnAutoRenewal");
	OptionSettings.LongDesc = NStr("vi = 'Hiển thị chữ ký không thể gia hạn tự động.';
									|ru = 'Выводит подписи, которые не удалось продлить автоматически.';
									|en = 'Displays signatures that cannot be renewed automatically.'; fa = 'Displays signatures that cannot be renewed automatically.';
									|it = 'Выводит подписи, которые не удалось продлить автоматически.';
									|pl = 'Displays signatures that cannot be renewed automatically.';
									|tr = 'Otomatik olarak silinemeyen imzaları kaldırır.'");
	OptionSettings.Enabled = AddTimestampsAutomatically Or RefineSignaturesAutomatically = 1;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf