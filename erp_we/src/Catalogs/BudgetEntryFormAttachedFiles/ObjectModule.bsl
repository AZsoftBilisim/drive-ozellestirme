#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then 
		Return; 
	EndIf;
	
	If ValueIsFilled(ServiceFileType)
		And ValueIsFilled(BeingEditedBy) Then
		
		Raise NStr("vi = 'Tệp là hệ thống
									|Cấm soạn tệp';
									|ru = 'Файл является служебным
									|Редактирование файла запрещено';
									|en = 'This file is for technical use
									|Editing is prohibited'; fa = 'This file is for technical use
									|Editing is prohibited';
									|it = 'Il file risulta essere di servizio
									|La modifica del file non è permessa';
									|pl = 'To jest plik serwisowy
									|Edycja pliku jest zabroniona';
									|tr = 'Dosya hizmet dosyasıdır
									|Dosyanın düzenlenmesi yasaktır'");
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
