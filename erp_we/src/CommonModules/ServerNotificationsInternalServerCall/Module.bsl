///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// See ServerNotifications.SessionUndeliveredServerNotifications
Function SessionUndeliveredServerNotifications(Val Parameters) Export
	
	Return ServerNotifications.SessionUndeliveredServerNotifications(Parameters);
	
EndFunction

// Parameters:
//  ErrorText - String
//
Procedure RegisterUndeliveredServerNotificationsRetrievalError(Val ErrorText) Export
	
	WriteLogEvent(
		NStr("vi = 'Thông báo từ server.Lỗi khi nhận các thông báo server chưa được gửi đến';
			|ru = 'Серверные оповещения.Ошибка получения недоставленных серверных оповещений';
			|en = 'Server notifications.Error getting or processing undelivered server notifications'; fa = 'Server notifications.Error getting or processing undelivered server notifications';
			|it = 'Server notifications.Error getting or processing undelivered server notifications';
			|pl = 'Server notifications.Error getting or processing undelivered server notifications';
			|tr = 'Sunucu bildirimleri.Teslim edilmeyen sunucu bildirimleri alırken hata oluştu'",
			Common.DefaultLanguageCode()),
		EventLogLevel.Error,,, ErrorText);
	
EndProcedure

// Parameters:
//  LongDesc - Structure:
//   * Date - Date
//   * Id - String
//   * Conversation - String
//   * Text - String
//   * DetailErrorDescription - String
//
Procedure LogErrorGettingDataFromMessage(Val LongDesc) Export
	
	If StrLineCount(LongDesc.Text) = 3 Then
		NameOfAlert = TrimAll(StrGetLine(LongDesc.Text, 1));
		NotificationID = Lower(TrimAll(StrGetLine(LongDesc.Text, 2)));
		LongRunningOperationProcedureName = TrimAll(StrGetLine(LongDesc.Text, 3));
		If StringFunctionsClientServer.IsUUID(NotificationID) Then
			Query = New Query;
			Query.SetParameter("NotificationID", NotificationID);
			Query.Text =
			"SELECT
			|	SentServerNotifications.NotificationContent AS NotificationContent
			|FROM
			|	InformationRegister.SentServerNotifications AS SentServerNotifications
			|WHERE
			|	SentServerNotifications.NotificationID <> &NotificationID";
			SetPrivilegedMode(True);
			Selection = Query.Execute().Select();
			SetPrivilegedMode(False);
			If Selection.Next() Then
				NotificationContent = Selection.NotificationContent;
				If TypeOf(NotificationContent) = Type("ValueStorage") Then
					XMLNotificationContent = XMLString(NotificationContent);
				EndIf;
			Else
				XMLNotificationContent = "<" + NStr("vi = 'Không tìm thấy nội dung thông báo trong cơ sở dữ liệu';
													|ru = 'Содержимое оповещения не найдено в базе данных';
													|en = 'The notification content is not found in the database'; fa = 'The notification content is not found in the database';
													|it = 'Il contenuto dell''avviso non è stato trovato nel database';
													|pl = 'Nie znaleziono treści powiadomienia w bazie danych';
													|tr = 'Bildirimin içeriği veritabanında bulunamadı'") + ">"; 
			EndIf;
		Else
			XMLNotificationContent = "<" + NStr("vi = 'Tên định danh của thông báo không phải là tên định danh đơn trị';
												|ru = 'Идентификатор оповещения не является уникальным идентификатором';
												|en = 'The notification ID is not a UUID'; fa = 'The notification ID is not a UUID';
												|it = 'L''identificativo dell''avviso non è univoco';
												|pl = 'Identyfikator powiadomienia nie jest unikalnym identyfikatorem';
												|tr = 'Bildirim kimliği bir UUID değildir'") + ">"; 
		EndIf;
	EndIf;
	If Not ValueIsFilled(NameOfAlert) Then
		NameOfAlert = "<" + NStr("vi = 'Không có dữ liệu';
								|ru = 'Нет данных';
								|en = 'No data'; fa = 'داده‌ای وجود ندارد';
								|it = 'Nessun dato';
								|pl = 'Brak danych';
								|tr = 'Veri yok'") + ">";
	EndIf;
	If Not ValueIsFilled(NotificationID) Then
		NotificationID = "<" + NStr("vi = 'Không có dữ liệu';
									|ru = 'Нет данных';
									|en = 'No data'; fa = 'داده‌ای وجود ندارد';
									|it = 'Nessun dato';
									|pl = 'Brak danych';
									|tr = 'Veri yok'") + ">";
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Khi truy cập thuộc tính ""%1"" thông báo của hệ thống tương tác với các thuộc tính:
		           |- Ngày: %2
		           |- Tên định danh: %3
		           |- Thảo luận: %4
		           |- Nội dung
		           |	Tên thông báo: %5
		           |	Tên định danh thông báo: %6';
		           |ru = 'При обращении к свойству ""%1"" сообщения системы взаимодействия со свойствами:
		           |- Дата: %2
		           |- Идентификатор: %3
		           |- Обсуждение: %4
		           |- Текст
		           |	Имя оповещения: %5
		           |	Идентификатор оповещения: %6';
		           |en = 'When accessing the ""%1"" property of the collaboration system message with properties:
		           |- Date: %2
		           |- ID: %3
		           |- Conversation: %4
		           |- Text
		           |	Notification name: %5
		           |	Notification ID: %6'; fa = 'When accessing the ""%1"" property of the collaboration system message with properties:
		           |- Date: %2
		           |- ID: %3
		           |- Conversation: %4
		           |- Text
		           |	Notification name: %5
		           |	Notification ID: %6';
		           |it = 'Durante la chiamata della proprietà ""%1"" del messaggio del sistema di interazione con le proprietà:
		           |- Data:%2
		           |- Identificativo: %3
		           |- Discussione:%4
		           |- Testo:
		           |	Nome avviso: %5
		           |	Identificativo avviso: %6';
		           |pl = 'Podczas zwrotu do właściwości ""%1"" wiadomości systemu interakcji z właściwościami:
		           |- Data: %2
		           |- Identyfikator: %3
		           |- Dyskusja: %4
		           |- Tekst
		           |	Nazwa powiadomienia: %5
		           |	Identyfikator powiadomienia: %6';
		           |tr = 'Bu özelliklere sahip Ortak Çalışma Sistemi mesajının ""%1"" özelliğine başvururken:
		           | - Tarih: %2
		           |- Kimlik: %3
		           |- Sohbet: %4
		           |- Metin
		           |	Bildirim adı: %5
		           |	Bildirim kimliği: %6'"),
		"Data",
		LongDesc.Date,
		LongDesc.Id,
		LongDesc.Conversation,
		NameOfAlert,
		NotificationID);
	
	If ValueIsFilled(LongRunningOperationProcedureName)
	   And LongRunningOperationProcedureName <> "-" Then
		
		ErrorText = ErrorText + "
		|	" + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tên thủ tục giao dịch kéo dài: %1';
				|ru = 'Имя процедуры длительной операции: %1';
				|en = 'Long-running operation procedure name: %1'; fa = 'Long-running operation procedure name: %1';
				|it = 'Nome della procedura dell''operazione a lungo termine: %1';
				|pl = 'Nazwa procedury długotrwałej operacji: %1';
				|tr = 'Uzun süreli işlem prosedürünün adı: %1'"),
			LongRunningOperationProcedureName);
	EndIf;
	
	ErrorText = ErrorText + Chars.LF;
	ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã xảy ra lỗi:
		           |
		           |%1';
		           |ru = 'Возникла ошибка:
		           |
		           |%1';
		           |en = 'An error occurred:
		           |
		           |%1'; fa = 'An error occurred:
		           |
		           |%1';
		           |it = 'Si è verificato un errore:
		           |
		           |%1';
		           |pl = 'Wystąpił błąd:
		           |
		           |%1';
		           |tr = 'Bir hata oluştu:
		           |
		           |%1'"),
		LongDesc.DetailErrorDescription);
	
	If ValueIsFilled(XMLNotificationContent)
	   And NotificationID <> "-" Then
		
		ErrorText = ErrorText + Chars.LF + Chars.LF;
		ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nội dung thông báo có định dạng kho chứa giá trị XML (từ cơ sở dữ liệu):
			           |%1';
			           |ru = 'Содержимое оповещения в формате хранилища значения в XML (из базы данных):
			           |%1';
			           |en = 'Notification content in a value storage format in XML (from the database):
			           |%1'; fa = 'Notification content in a value storage format in XML (from the database):
			           |%1';
			           |it = 'Il contenuto dell''avviso in formato di repository valore in XML (dal database):
			           |%1';
			           |pl = 'Treść powiadomienia w formacie repozytorium wartości w XML (z bazy danych):
			           |%1';
			           |tr = 'XML değer deposu (veritabanından) formatındaki bildirim içeriği:
			           |%1'"),
			XMLNotificationContent);
	EndIf;
	
	WriteLogEvent(
		NStr("vi = 'Thông báo từ máy chủ.Lỗi nhận dữ liệu thông báo từ thông điệp';
			|ru = 'Серверные оповещения.Ошибка получения данных оповещения из сообщения';
			|en = 'Server notifications.An error occurred when receiving the notification data from the message'; fa = 'Server notifications.An error occurred when receiving the notification data from the message';
			|it = 'Avvisi server. Errore di ricezione dati dell''avviso dal messaggio';
			|pl = 'Powiadomienia serwerowe.Błąd otrzymania danych powiadomienia z wiadomości';
			|tr = 'Sunucu bildirimleri.Mesajdan bildirim verilerini alma hatası'",
			Common.DefaultLanguageCode()),
		EventLogLevel.Error,, NameOfAlert, ErrorText);
	
EndProcedure

// Parameters:
//  Comment - String - Comment for the Event log
//
Procedure WritePerformanceIndicators(Val Comment) Export
	
	EventName = NStr("vi = 'Thông báo từ máy chủ.Chỉ tiêu hiệu suất';
					|ru = 'Серверные оповещения.Показатели производительности';
					|en = 'Server notifications.Performance indicators'; fa = 'Server notifications.Performance indicators';
					|it = 'Серверные оповещения.Показатели производительности';
					|pl = 'Server notifications.Performance indicators';
					|tr = 'Sunucu alarmı.Performans göstergeleri'",
		Common.DefaultLanguageCode());
	
	WriteLogEvent(EventName,
		EventLogLevel.Information,,, Comment);
	
	If Common.SubsystemExists("CloudTechnology") Then
		ModuleCommonCTL = Common.CommonModule("CommonCTL");
		ModuleCommonCTL.TechnologyLogEntry(EventName, Comment);
	EndIf;
	
EndProcedure

#EndRegion
