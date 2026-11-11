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
	
	If ValueIsFilled(PerformerRole) Then
		
		Description = String(PerformerRole);
		
		If ValueIsFilled(MainAddressingObject) Then
			Description = Description + ", " + String(MainAddressingObject);
		EndIf;
		
		If ValueIsFilled(AdditionalAddressingObject) Then
			Description = Description + ", " + String(AdditionalAddressingObject);
		EndIf;
	Else
		Description = NStr("vi = 'Không có địa chỉ theo vai trò';
							|ru = 'Без ролевой адресации';
							|en = 'Without role addressing'; fa = 'Without role addressing';
							|it = 'Senza un indirizzamento di ruolo';
							|pl = 'Bez adresacji ról';
							|tr = 'Rol adresleme olmadan'");
	EndIf;
	
	// Check for duplicates.
	Query = New Query(
		"SELECT TOP 1
		|	TaskPerformersGroups.Ref
		|FROM
		|	Catalog.TaskPerformersGroups AS TaskPerformersGroups
		|WHERE
		|	TaskPerformersGroups.PerformerRole = &PerformerRole
		|	AND TaskPerformersGroups.MainAddressingObject = &MainAddressingObject
		|	AND TaskPerformersGroups.AdditionalAddressingObject = &AdditionalAddressingObject
		|	AND TaskPerformersGroups.Ref <> &Ref");
	Query.SetParameter("PerformerRole", PerformerRole);
	Query.SetParameter("MainAddressingObject", MainAddressingObject);
	Query.SetParameter("AdditionalAddressingObject", AdditionalAddressingObject);
	Query.SetParameter("Ref", Ref);
	
	If Not Query.Execute().IsEmpty() Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã có nhóm người thực hiện nhiệm vụ mà có đặt:
			           |vai trò người thực hiện ""%1"",
			           |đối tượng đánh địa chỉ chính ""%2""
			           |và đối tượng đánh địa chỉ bổ sung ""%3""';
			           |ru = 'Уже есть группа исполнителей задач, для которой заданы:
			           |роль исполнителя ""%1"",
			           |основной объект адресации ""%2""
			           |и дополнительный объект адресации ""%3""';
			           |en = 'There is already the task assignee group for which
			           |assignee role ""%1"",
			           |main business object ""%2"",
			           |and additional business object ""%3"" are set'; fa = 'There is already the task assignee group for which
			           |assignee role ""%1"",
			           |main business object ""%2"",
			           |and additional business object ""%3"" are set';
			           |it = 'Esiste già un gruppo di esecutori de compiti per i quali sono indicati:
			           |il ruolo dell''esecutore ""%1"",
			           |l''oggetto d''indirizzamento principale ""%2""
			           |e l''oggetto di indirizzamento aggiuntivo ""%3""';
			           |pl = 'Już istnieje grupa wykonawców, dla której określono:
			           |rolę wykonawcy ""%1"",
			           |główny obiekt adresacji ""%2""
			           |i dodatkowy obiekt adresacji ""%3""';
			           |tr = 'Atanan rolü ""%1"", 
			           | ana gönderim hedefi""%2"", 
			           |ve ek gönderim hedefleri ""%3"" belirlenen göreve atanan grubu zaten mevcut
			           |'"),
			String(PerformerRole),
			String(MainAddressingObject),
			String(AdditionalAddressingObject)));
	EndIf;
	
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