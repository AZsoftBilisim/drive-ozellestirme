///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Procedure ShowExclusiveChangeModeWarning() Export
	
	QueryText = 
		NStr("vi = 'Để thay đổi chế độ tìm kiếm toàn văn
		           |cần hoàn tất phiên làm việc của tất cả người sử dụng, ngoại trừ người sử dụng hiện tại.';
		           |ru = 'Для изменения режима полнотекстового поиска требуется 
		           |завершение сеансов всех пользователей, кроме текущего.';
		           |en = 'To change the full-text search mode, close all sessions,
		           |except for the current user session.'; fa = 'To change the full-text search mode, close all sessions,
		           |except for the current user session.';
		           |it = 'Per modificare la modalità di ricerca full-text, è necessario 
		           |terminare le sessioni di tutti gli utenti, tranne quella corrente.';
		           |pl = 'Aby zmienić tryb wyszukiwania pełnotekstowego, musisz 
		           |zakończyć wszystkie sesje użytkownika z wyjątkiem sesji bieżącej.';
		           |tr = 'Tam metin arama modunu değiştirmek için mevcut kullanıcı dışındaki tüm kullanıcı oturumlarını 
		           |kapatın.'");
	
	Buttons = New ValueList;
	Buttons.Add("ActiveUsers", NStr("vi = 'Người sử dụng đang làm việc';
									|ru = 'Активные пользователи';
									|en = 'Active users'; fa = 'کاربران فعال';
									|it = 'Utenti attivi';
									|pl = 'Aktywni użytkownicy';
									|tr = 'Aktif kullanıcılar'"));
	Buttons.Add(DialogReturnCode.Cancel);
	
	Handler = New CallbackDescription("AfterDisplayWarning", ThisObject);
	ShowQueryBox(Handler, QueryText, Buttons,, "ActiveUsers");
	
EndProcedure

Procedure AfterDisplayWarning(Response, ExecutionParameters) Export
	
	If Response = "ActiveUsers" Then
		StandardSubsystemsClient.OpenActiveUserList();
	EndIf
	
EndProcedure

#EndRegion