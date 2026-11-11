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

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array();
	For Each VersionRecord In ThisObject Do
		If Not IsBlankString(VersionRecord.Version) And Not IsFullVersionNumber(VersionRecord.Version) Then
			Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Số phiên bản không hợp lệ:%1 (giá trị dự kiến ​​là ""1.2.3.4"")';
					|ru = 'Некорректный номер версии: %1 (ожидалось значение в виде ""1.2.3.4"")';
					|en = 'Invalid version number: %1. The expected format is ""1.2.3.4"".'; fa = 'Invalid version number: %1. The expected format is ""1.2.3.4"".';
					|it = 'Il numero della versione errato: %1 (si aspettava il valore in forma ""1.2.3.4"")';
					|pl = 'Nieprawidłowy numer wersji: %1 (oczekiwana wartość w postaci ""1.2.3.4"")';
					|tr = 'Hatalı sürüm numarası: %1 (""1.2.3.4"" şeklinde bir değer bekleniyor)'"), VersionRecord.Version));
			Cancel = True; 
	    	AttributesNotToCheck.Add("Version"); 
		EndIf;
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

#EndRegion

#Region Private

Function IsFullVersionNumber(Val VersionNumber)
	
	VersionParts = StrSplit(VersionNumber, ".");
	If VersionParts.Count() <> 4 Then
		Return False;	
	EndIf;
	
	NumberType = New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative));
 	For Digit = 0 To 3 Do
		VersionPart = VersionParts[Digit];
		If NumberType.AdjustValue(VersionPart) = 0 And VersionPart <> "0" Then
			Return False;
		EndIf;
	EndDo;
	Return True;
		
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf