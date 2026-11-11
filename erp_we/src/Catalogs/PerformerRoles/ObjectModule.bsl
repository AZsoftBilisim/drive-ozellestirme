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
	
	If Not UsedByAddressingObjects And Not UsedWithoutAddressingObjects Then
		Common.MessageToUser(
			NStr("vi = 'Chưa chỉ ra phương pháp chỉ định người thực hiện cho vai trò: cùng với đối tượng đánh địa chỉ, không có hoặc cả hai cách.';
				|ru = 'Не указаны допустимые способы назначения исполнителей на роль: совместно с объектами адресации, без них или обоими способами.';
				|en = 'The allowed methods for adding assignees to roles are not specified (together with the business objects, without them, or both ways).'; fa = 'The allowed methods for adding assignees to roles are not specified (together with the business objects, without them, or both ways).';
				|it = 'Non sono indicati i metodi consentiti per l''assegnazione degli esecutori al ruolo: insieme agli oggetti di indirizzamento, senza di essi o con entrambi i metodi.';
				|pl = 'Nie wskazano możliwych sposobów przeznaczenia wykonawców do roli: wspólnie z obiektami adresacji, bez nich lub obydwoma sposobami.';
				|tr = 'İzin verilen role atanan atama yöntemleri belirtilmedi (gönderim hedefleri ile birlikte, olmaksızın, veya her iki şekilde).'"),
		 	ThisObject, "UsedWithoutAddressingObjects",,Cancel);
		Return;
	EndIf;
	
	If Not UsedByAddressingObjects Then
		Return;
	EndIf;
	
	MainAddressingObjectTypesAreSet = MainAddressingObjectTypes <> Undefined And Not MainAddressingObjectTypes.IsEmpty();
	If Not MainAddressingObjectTypesAreSet Then
		Common.MessageToUser(NStr("vi = 'Chưa chỉ ra kiểu đối tượng đánh địa chỉ chính.';
									|ru = 'Не указаны типы основного объекта адресации.';
									|en = 'Types of the main business object are not specified.'; fa = 'Types of the main business object are not specified.';
									|it = 'I tipi dell''oggetto principale di indirizzamento non sono specificati.';
									|pl = 'Nie wskazano typów obiektu głównego adresacji.';
									|tr = 'Ana gönderim hedefinin türleri belirtilmedi.'"),
		 	ThisObject, "MainAddressingObjectTypes",,Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
	If MainAddressingObjectTypes <> Undefined And MainAddressingObjectTypes.IsEmpty() Then
		MainAddressingObjectTypes = Undefined;
	EndIf;
	
	If AdditionalAddressingObjectTypes <> Undefined And AdditionalAddressingObjectTypes.IsEmpty() Then
		AdditionalAddressingObjectTypes = Undefined;
	EndIf;
	
	If Not GetFunctionalOption("UseExternalUsers") Then
		If Purpose.Find(Catalogs.Users.EmptyRef(), "UsersType") = Undefined Then
			// If external users are disconnected, the role must be assigned to users.
			Purpose.Add().UsersType = Catalogs.Users.EmptyRef();
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not UsedByAddressingObjects And UsedWithoutAddressingObjects Then
		
		DataLock = New DataLock;
		LockItem = DataLock.Add("InformationRegister.TaskPerformers");
		LockItem.SetValue("PerformerRole", Ref);
		DataLock.Lock();

		Set = InformationRegisters.TaskPerformers.CreateRecordSet();
		Set.Filter.PerformerRole.Set(Ref);
		Set.Read();
		If Set.Count() > 0 Then
			For Each PerformerTasks In Set Do
				PerformerTasks.MainAddressingObject       = Undefined;
				PerformerTasks.AdditionalAddressingObject = Undefined;
			EndDo;
		EndIf;
		Set.Write();

	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure OnReadPresentationsAtServer() Export
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
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