///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(Variants, CommandExecuteParameters)
	If TypeOf(Variants) <> Type("Array") Or Variants.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn phương án báo cáo của chương trình, mà cần bỏ tùy chỉnh sắp xếp.';
								|ru = 'Выберите варианты отчетов, для которых необходимо сбросить настройки размещения.';
								|en = 'Select report options to reset location settings.'; fa = 'Select report options to reset location settings.';
								|it = 'Выберите варианты отчетов, для которых необходимо сбросить настройки размещения.';
								|pl = 'Select report options to reset location settings.';
								|tr = 'Yerleşim ayarlarını sıfırlamak istediğiniz rapor seçeneklerini seçin.'"));
		Return;
	EndIf;
	
	OpenForm("Catalog.ReportsOptions.Form.ResetAssignmentToSections",
		New Structure("Variants", Variants), CommandExecuteParameters.Source);
EndProcedure

#EndRegion
