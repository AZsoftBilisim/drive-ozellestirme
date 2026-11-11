///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value < 0 Or Value > 2 Then
		ErrorText = NStr("vi = 'Giá trị hằng không hợp lệ: %1. Giá trị hợp lệ:
			|0 - không nâng cấp chữ ký tự động và không hiển thị lệnh để xử lý thủ công trong giao diện;
			|1 - nâng cấp bằng nhiệm vụ thường kỳ;
			|2 - nâng cấp thủ công (hiển thị các lệnh trong giao diện của người quản trị và trong công việc hiện tại)';
			|ru = 'Недопустимое значение константы: %1. Допустимые значения:
			|0 - не усовершенствовать подписи автоматически и не показывать команды для ручной обработки в интерфейсе;
			|1 - усовершенствовать регламентным заданием;
			|2 - усовершенствовать вручную (показывать команды в интерфейсе администратора и в текущих делах)';
			|en = 'Incorrect constant value: %1. Possible values:
			|0 - do not enhance signatures automatically and do not display commands for manual processing in the interface.
			|1 - enhance signatures using a scheduled job.
			|2 - enhance signatures manually (display commands in the administrator interface and in the to-do list)'; fa = 'Incorrect constant value: %1. Possible values:
			|0 - do not enhance signatures automatically and do not display commands for manual processing in the interface.
			|1 - enhance signatures using a scheduled job.
			|2 - enhance signatures manually (display commands in the administrator interface and in the to-do list)';
			|it = 'Valore non disponibile delle costanti:%1. Valori disponibili:
			|0 - non perfezionare le firme automaticamente e non mostrare i comandi per l''elaborazione manuale nell''interfaccia; 
			|1 - perfezionare i compiti regolamentati; 2
			| - perfezionare manualmente (mostrare i comandi nell''interfaccia dell''amministratore e nelle azioni correnti)';
			|pl = 'Niedopuszczalna wartość stałej: %1. Dopuszczalne wartości:
			|0 - nie udoskonalaj podpisu automatycznie i nie pokazuj poleceń do ręcznego przetwarzania w interfejsie;
			|1 -udoskonal za pomocą zadania reglamentowanego;
			|2 - udoskonal ręcznie (pokazuj polecenia w interfejsie administratora w bieżących sprawach)';
			|tr = 'Geçersiz sabit değer: %1. Geçerli değerler:
			|0 - imzaları otomatik olarak geliştirme ve arayüzde manuel işleme komutları gösterme; 
			|1 - düzenleme görevi ile geliştir; 
			|2 - manuel olarak geliştir (yönetici arayüzünde ve mevcut durumlarda komutları göster)'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Value);
	EndIf;
	
	DigitalSignatureInternal.ChangeRegulatoryTaskExtensionCredibilitySignatures(Value);

EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf