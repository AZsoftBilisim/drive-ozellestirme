///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function SupportRequestTopic() Export
	
	Return NStr("vi = 'Vấn đề khi điền địa chỉ';
				|ru = 'Проблема при заполнении адреса';
				|en = 'Issue when filling address'; fa = 'Issue when filling address';
				|it = 'Issue when filling address';
				|pl = 'Issue when filling address';
				|tr = 'Adres doldurma sorunu'");
	
EndFunction

Function SupportRequestText(Val Address, Val TechnicalInformation) Export
	
	MainReason = StrReplace(TechnicalInformation, Chars.LF, " ");
	
	Template = NStr("vi = 'Vấn đề khi điền địa chỉ %1: %2.
		|
		|<Vui lòng mô tả sự cố đã xảy ra và đính kèm ảnh chụp màn hình của lỗi.>';
		|ru = 'Проблема при заполнении адреса %1: %2.
		|
		|<Опишите возникшую проблему и приложите скриншоты ошибки.>';
		|en = 'Issue when filling address %1: %2.
		|
		|<Describe the issue and attach screenshots.>'; fa = 'Issue when filling address %1: %2.
		|
		|<Describe the issue and attach screenshots.>';
		|it = 'Issue when filling address %1: %2.
		|
		|<Describe the issue and attach screenshots.>';
		|pl = 'Issue when filling address %1: %2.
		|
		|<Describe the issue and attach screenshots.>';
		|tr = '%1 adresi doldurulurken sorun oluştu: %2.
		|
		|<Sorunu açıklayın ve hatanın ekran görüntülerini ekleyin.>'");
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(Template, Address, MainReason);
	
	Return Result;
	
EndFunction

#EndRegion
