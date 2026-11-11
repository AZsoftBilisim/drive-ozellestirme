///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = NStr("vi = 'Hàm sự kiện cập nhật';
				|ru = 'Обработчик обновления';
				|en = 'Update handler'; fa = 'رویدادگردان به‌روزرسانی';
				|it = 'Gestore aggiornamento';
				|pl = 'Procesor danych aktualizacji';
				|tr = 'Güncelleme işleyicisi'") + " " + Record.HandlerName;
	
	If ValueIsFilled(Record.Comment) Then
		Items.GroupComment.Title = NStr("vi = 'Ghi chú';
										|ru = 'Комментарий';
										|en = 'Comment'; fa = 'توضیحات';
										|it = 'Commento';
										|pl = 'Comment';
										|tr = 'Yorum'") + " *";
	Else
		Items.GroupComment.Title = NStr("vi = 'Ghi chú';
										|ru = 'Комментарий';
										|en = 'Comment'; fa = 'توضیحات';
										|it = 'Commento';
										|pl = 'Comment';
										|tr = 'Yorum'");
	EndIf;
	
	If ValueIsFilled(Record.ErrorInfo) Then
		Items.GroupErrorInfo.Title = NStr("vi = 'Thông tin về lỗi';
											|ru = 'Информация об ошибке';
											|en = 'Error details'; fa = 'جزئیات خطا';
											|it = 'Informazione sull''errore';
											|pl = 'Informacje o błędzie';
											|tr = 'Hata bilgisi'") + " *";
	Else
		Items.GroupErrorInfo.Title = NStr("vi = 'Thông tin về lỗi';
											|ru = 'Информация об ошибке';
											|en = 'Error details'; fa = 'جزئیات خطا';
											|it = 'Informazione sull''errore';
											|pl = 'Informacje o błędzie';
											|tr = 'Hata bilgisi'");
	EndIf;
	
	DataToProcess = NStr("vi = 'Mở';
						|ru = 'Открыть';
						|en = 'Open'; fa = 'باز';
						|it = 'Aprire';
						|pl = 'Otwórz';
						|tr = 'Aç'");
	
	Data = FormAttributeToValue("Record").DataToProcess;
	ProcessedDataStorage = PutToTempStorage(Data, UUID);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_UpdateHandlers", WriteParameters);
EndProcedure

#EndRegion
