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
	
	IsOwnerMarkedForDeletion = Common.ObjectAttributeValue(Owner, "DeletionMark");
	
	If IsOwnerMarkedForDeletion = Undefined
		Or IsOwnerMarkedForDeletion Then
		PredefinedFolder = False;
		Return;
	EndIf;

	If Not Interactions.UserIsResponsibleForMaintainingFolders(Owner) Then
		Common.MessageToUser(
			NStr("vi = 'Thao tác chỉ khả dụng đối với người chịu trách nhiệm quản lý thư mục thư này.';
				|ru = 'Действие доступно только ответственному за ведение папок для данной почты.';
				|en = 'The operation is available only to the user responsible for managing the account''s folders.'; fa = 'The operation is available only to the user responsible for managing the account''s folders.';
				|it = 'Действие доступно только ответственному за ведение папок для данной почты.';
				|pl = 'The operation is available only to the user responsible for managing the account''s folders.';
				|tr = 'Eylem sadece bu posta için klasörlerin yönetiminden sorumlu olan tarafından kullanılabilir.'"),
			Ref,,,Cancel);
	ElsIf PredefinedFolder And (Not Parent.IsEmpty()) Then
		Common.MessageToUser(
			NStr("vi = 'Không thể di chuyển thư mục định trước vào thư mục này.';
				|ru = 'Нельзя переместить предопределенную папку в другую папку.';
				|en = 'Cannot move a predefined folder to another folder.'; fa = 'Cannot move a predefined folder to another folder.';
				|it = 'Нельзя переместить предопределенную папку в другую папку.';
				|pl = 'Cannot move a predefined folder to another folder.';
				|tr = 'Varsayılan klasör başka bir klasöre taşınamaz.'"),
			Ref,,,Cancel);
	EndIf;
	
	AdditionalProperties.Insert("Parent", Common.ObjectAttributeValue(Ref, "Parent"));
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	PredefinedFolder = False;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("Parent") And Parent <> AdditionalProperties.Parent Then
		If Not AdditionalProperties.Property("ParentChangeProcessed") Then
			Interactions.SetFolderParent(Ref,Parent,True)
		EndIf;
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