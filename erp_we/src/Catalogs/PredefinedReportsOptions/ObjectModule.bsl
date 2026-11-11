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

Procedure BeforeWrite(Cancel)
	If AdditionalProperties.Property("PredefinedObjectsFilling") Then
		CheckPredefinedReportOptionFilling(Cancel);
	EndIf;
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not AdditionalProperties.Property("PredefinedObjectsFilling") Then
		Raise NStr("vi = 'Cấm ghi vào danh mục ""Phương án báo cáo định trước"". Chương trình sẽ điền tự động dữ liệu của danh mục.';
					|ru = 'Запись в справочник ""Предопределенные варианты отчетов"" запрещена. Его данные заполняются автоматически.';
					|en = 'Cannot save to ""Predefined report options"" catalog. It is populated automatically.'; fa = 'Cannot save to ""Predefined report options"" catalog. It is populated automatically.';
					|it = 'La scrittura nell''elenco ""Opzioni predefinite dei report"" è proibita. I suoi dati vengono compilati automaticamente.';
					|pl = 'Zapisywanie do katalogu ""Określone wcześniej warianty raportów"" jest zabroniona. Jego dane są wypełniane automatycznie.';
					|tr = '""Önceden tanımlanmış rapor seçenekleri"" dizinine yazma yasaktır. Verileri otomatik olarak doldurulur.'");
	EndIf;
EndProcedure

// Basic validation of predefined report options.
Procedure CheckPredefinedReportOptionFilling(Cancel)
	
	If DeletionMark Then
		Return;
	EndIf;
	If ValueIsFilled(Report) Then
		Return;
	EndIf;
		
	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa điền trường ""%1"".';
																		|ru = 'Не заполнено поле ""%1"".';
																		|en = 'Field %1 is required.'; fa = 'Field %1 is required.';
																		|it = 'Не заполнено поле ""%1"".';
																		|pl = 'Field %1 is required.';
																		|tr = '""%1"" alanı doldurulmadı.'"), "Report");
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf