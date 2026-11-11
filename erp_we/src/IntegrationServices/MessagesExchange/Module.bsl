#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ProcessMessageNormalPriority(Message, Cancel)
	ProcessMessage(Message, Cancel);
EndProcedure

Procedure ProcessMessageHighPriority(Message, Cancel)
	ProcessMessage(Message, Cancel, True);
EndProcedure

#EndRegion

#Region Private

Procedure ProcessMessage(Message, Cancel, HighProperty = False)
	Try
		IntegrationBus.ProcessMessage(Message, Cancel);
	Except
		WriteLogEvent(
			NStr("vi = 'ИнтеграционнаяШина.Lỗi xử lý thông báo';
				|ru = 'ИнтеграционнаяШина.Ошибка обработки сообщения';
				|en = 'Integration bus.Message processing error'; fa = 'Integration bus.Message processing error';
				|it = 'Integration bus.Message processing error';
				|pl = 'Integration bus.Message processing error';
				|tr = 'ИнтеграционнаяШина.Mesaj işleme hatası'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.IntegrationServices.MessagesExchange,,
			CloudTechnology.DetailedErrorText(ErrorInfo()));
		Raise;
	EndTry;
EndProcedure

#EndRegion

#EndIf
