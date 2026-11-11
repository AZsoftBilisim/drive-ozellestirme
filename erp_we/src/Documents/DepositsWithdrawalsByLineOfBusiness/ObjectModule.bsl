
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Undefined;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If SourceArea = DestinationArea Then
		CommonClientServer.MessageToUser(NStr("vi = 'Mục đích của người nhận không thể trùng với mục đích của người gửi.';
												|ru = 'Направление получатель не может совпадать с направлением отправителем.';
												|en = 'Destination line of business cannot be the same as source line of business.'; fa = 'Destination line of business cannot be the same as source line of business.';
												|it = 'Destinazione del destinatario non può corrispondere alla destinazione del mittente.';
												|pl = 'Kierunek odbiorca nie może zbiegać się z kierunkiem nadawcy.';
												|tr = 'Alıcının yönü, gönderenin yönü ile aynı olamaz.'"), , "DestinationArea", "Object", Cancel);
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#EndIf