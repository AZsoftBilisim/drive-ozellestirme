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
	
	InfobasePublicationURL = Common.InfobasePublicationURL();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	GenerateRefAddress();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InfobasePublicationURLOnChange(Item)
	
	GenerateRefAddress();

EndProcedure

&AtClient
Procedure ObjectReferenceOnChange(Item)
	
	GenerateRefAddress();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Insert(Command)
	
	ClearMessages();
	
	Cancel = False;
	
	If IsBlankString(InfobasePublicationURL) Then
		
		MessageText = NStr("vi = 'Chưa chỉ ra địa chỉ đăng tải cơ sở thông tin trên Internet.';
							|ru = 'Не указан адрес публикации информационной базы в интернете.';
							|en = 'Infobase publication URL not specified.'; fa = 'Infobase publication URL not specified.';
							|it = 'Non è indicato l''indirizzo di pubblicazione della banca dati su Internet.';
							|pl = 'Nie podano adres do publikowania bazy informacyjnej w Internecie.';
							|tr = 'İnternetteki Infobase yayın adresi belirtilmedi.'");
		CommonClient.MessageToUser(MessageText,, "InfobasePublicationURL",, Cancel);
		
	EndIf;
	
	If IsBlankString(ObjectReference) Then
		
		MessageText = NStr("vi = 'Chưa chỉ ra tham chiếu nội bộ đến đối tượng.';
							|ru = 'Не указана внутренняя ссылка на объект.';
							|en = 'In-app link to the object is not specified.'; fa = 'In-app link to the object is not specified.';
							|it = 'Non è indicato il link interno dell''oggetto.';
							|pl = 'Nie podano odnośnika wewnętrznego do obiektu.';
							|tr = 'Uygulama içi nesne bağlantısı belirtilmedi.'");
		CommonClient.MessageToUser(MessageText,, "ObjectReference",, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		NotifyChoice(GeneratedRef);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GenerateRefAddress()

	GeneratedRef = InfobasePublicationURL + "#"+ ObjectReference;

EndProcedure

#EndRegion
