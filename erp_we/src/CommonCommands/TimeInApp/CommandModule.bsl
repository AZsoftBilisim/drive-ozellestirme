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
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	AdditionalInformation = AdditionalInformation();
	ShowMessageBox(,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thời gian trong ứng dụng: %1
				|Giờ trên server: %2
				|Giờ trên client: %3
				|
				|Thời gian trong ứng dụng là thời gian theo giờ của server mà được điều chỉnh theo múi giờ
				|""%4"", 
				|được sử dụng khi ghi lại dữ liệu khác nhau, ví dụ như chứng từ.';
				|ru = 'Время в приложении: %1
				|Часы на сервере: %2
				|Часы на клиенте: %3
				|
				|Время в приложении - это время на часах сервера, приведенное к часовому поясу
				|""%4"",
				|используется при записи различных данных, например, документов.';
				|en = 'Application time: %1
				|Server time: %2
				|Client time: %3
				|
				|The application time is the server time converted to the device''s timezone
				|(%4).
				|This time is used in timestamps when saving documents and other objects.'; fa = 'Application time: %1
				|Server time: %2
				|Client time: %3
				|
				|The application time is the server time converted to the device''s timezone
				|(%4).
				|This time is used in timestamps when saving documents and other objects.';
				|it = 'Время в приложении: %1
				|Часы на сервере: %2
				|Часы на клиенте: %3
				|
				|Время в приложении - это время на часах сервера, приведенное к часовому поясу
				|""%4"",
				|используется при записи различных данных, например, документов.';
				|pl = 'Application time: %1
				|Server time: %2
				|Client time: %3
				|
				|The application time is the server time converted to the device''s timezone
				|(%4).
				|This time is used in timestamps when saving documents and other objects.';
				|tr = 'Uygulamadaki saat: %1
				|Sunucudaki saat: %2
				|Müşterideki saat: %3
				|
				|Uygulamadaki saat, sunucu saatindeki saat dilimine göre ayarlanan saattir
				|""%4"", 
				|Belgeler gibi çeşitli verileri kaydederken kullanılır.'"),
			Format(CommonClient.SessionDate(), "DLF=T"),
			Format(AdditionalInformation.ServerDate, "DLF=T"),
			Format(CurrentDate(), "DLF=T"), // ACC:143 - An example of CurrentDate call for determining the computer time
			AdditionalInformation.TimeZonePresentation));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function AdditionalInformation()
	Result = New Structure;
	Result.Insert("TimeZonePresentation", TimeZonePresentation(SessionTimeZone()));
	Result.Insert("ServerDate", CurrentDate()); // ACC:143 - CurrentDate is called to get the server time.
	Return Result;
EndFunction

#EndRegion