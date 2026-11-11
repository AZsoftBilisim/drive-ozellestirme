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
	
	TimestampServersAddresses = DigitalSignatureInternal.TimestampServersAddresses(Value);
	ErrorText = NStr("vi = 'Giá trị địa chỉ máy chủ dấu thời gian không hợp lệ: %1.';
					|ru = 'Недопустимое значение адреса сервера меток времени: %1.';
					|en = 'Invalid timestamp server address: %1.'; fa = 'Invalid timestamp server address: %1.';
					|it = 'Invalid timestamp server address: %1.';
					|pl = 'Invalid timestamp server address: %1.';
					|tr = 'Geçersiz zaman damgası sunucu adresi değeri: %1.'");
	
	For Each Address In TimestampServersAddresses Do
		URLStructure1 = CommonClientServer.URIStructure(Address);
		If Not Common.DomainNameCorrect(URLStructure1.Host) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Address);
		EndIf;
	EndDo;
	
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