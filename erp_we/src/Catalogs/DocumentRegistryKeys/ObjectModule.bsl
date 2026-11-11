
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If Key = Undefined Then
	
		MessageText = NStr("vi = 'Trường ""Khóa"" không thể để trống!';
							|ru = 'Поле ""Ключ"" не может быть пустым!';
							|en = 'The ""Key"" field must be filled.'; fa = 'The ""Key"" field must be filled.';
							|it = 'Поле ""Ключ"" не может быть пустым!';
							|pl = 'The ""Key"" field must be filled.';
							|tr = '""Anahtar"" alanı boş olamaz!'");
		Common.MessageToUser(MessageText,,,, Cancel);
	
	EndIf;

EndProcedure
	
#EndRegion

#EndIf
