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

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder And DeletionMark Then
		Use = False;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AccountingCheckIsChanged = ObjectChanged();
	
EndProcedure

#EndRegion

#Region Private

Function ObjectChanged()
	
	If IsNew() Then
		Return False;
	EndIf;
	
	If AccountingCheckIsChanged Then
		Return True;
	EndIf;
	
	If AdditionalProperties.Property("CheckChange") And Not AdditionalProperties.CheckChange Then
		Return False;
	EndIf;
	
	CheckedAttributes = New Array;
	CheckedAttributes.Add("Description");
	
	If Not IsFolder Then
		
		Attributes = Metadata().Attributes;
		For Each Attribute In Attributes Do
			
			If Attribute.Name = "AdditionalParameters"
				Or Attribute.Name = "CheckRunSchedule"
				Or Attribute.Name = "AccountingCheckIsChanged" Then
				Continue;
			EndIf;
			
			CheckedAttributes.Add(Attribute.Name);
			
		EndDo;
		
	EndIf;
	
	For Each AttributeToCheck In CheckedAttributes Do
		
		If Ref[AttributeToCheck] <> ThisObject[AttributeToCheck] Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf