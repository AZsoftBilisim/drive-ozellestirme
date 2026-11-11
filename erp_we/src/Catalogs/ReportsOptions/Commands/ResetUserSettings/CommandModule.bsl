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
		ShowMessageBox(, NStr("vi = 'Hãy chọn phương án báo cáo mà cần bỏ tùy chỉnh tự tạo.';
								|ru = 'Выберите варианты отчетов, для которых необходимо сбросить пользовательские настройки.';
								|en = 'Select report options to reset custom settings.'; fa = 'Select report options to reset custom settings.';
								|it = 'Selezionate le varianti dei report per le quali è necessario resettare le impostazioni personalizzate.';
								|pl = 'Wybierz warianty raportów, dla których należy zresetować ustawienia użytkownika.';
								|tr = 'Özel ayarları sıfırlamanız gereken rapor seçeneklerini seçin.'"));
		Return;
	EndIf;
	
	OpenForm("Catalog.ReportsOptions.Form.UserSettingsReset",
		New Structure("Variants", Variants), CommandExecuteParameters.Source);
EndProcedure

#EndRegion
