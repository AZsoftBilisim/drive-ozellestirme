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
	
	UpdateDataItemsAccessKeys = True;
	UpdateAccessKeysRights = True;
	DeleteObsoleteInternalData = True;
	
	ListsWithAccessKeys = AccessManagementInternal.ListsWithAccessKeys(, True);
	VersionsOfRestrictions = New Map;
	
	For Each ListDetails In ListsWithAccessKeys Do
		List = ListDetails.Key;
		TableProperties = ListDetails.Value;
		FullName = TableProperties.TableName;
		ListsToUpdate.Add(List, String(List), True);
		VersionsOfRestrictions.Insert(FullName, TableProperties.VersionOfRestriction);
		If Not AccessManagementInternal.IsReferenceTableType(FullName) Then
			Continue;
		EndIf;
		EmptyRef = PredefinedValue(FullName + ".EmptyRef");
		AccessUpdateObjectsTypes.Add(EmptyRef, String(TypeOf(EmptyRef)));
		AccessUpdateObjectsTypesTablesNames.Add(EmptyRef, FullName);
	EndDo;
	
	ListsRestrictionsVersions = New FixedMap(VersionsOfRestrictions);
	AccessUpdateObjectsTypes.SortByPresentation();
	ListsToUpdate.SortByPresentation();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AccessUpdateObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentTypeItem = AccessUpdateObjectsTypes.FindByValue(
		SelectedAccessUpdateObjectType);
	
	If CurrentTypeItem = Undefined Then
		CurrentTypeItem = AccessUpdateObjectsTypes[0];
	EndIf;
	
	AccessUpdateObjectsTypes.ShowChooseItem(
		New CallbackDescription("AccessUpdateObjectStartChoiceContinued", ThisObject),
		NStr("vi = 'Chọn kiểu dữ liệu';
			|ru = 'Выбор типа данных';
			|en = 'Select data type'; fa = 'Select data type';
			|it = 'Scelta del tipo dati';
			|pl = 'Wybierz typ danych';
			|tr = 'Veri türünü seçin'"),
		CurrentTypeItem);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowAccessToObject(Command)
	
	If Not ValueIsFilled(AccessUpdateObject) Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn đối tượng.';
								|ru = 'Выберите объект.';
								|en = 'Please select an object.'; fa = 'Please select an object.';
								|it = 'Selezionare oggetto.';
								|pl = 'Wybierz obiekt.';
								|tr = 'Nesneyi seçin.'"));
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAccessToObject(Command)
	
	ShowMessageBox(, UpdateAccessToObjectAtServer());
	
EndProcedure

&AtClient
Procedure ScheduleListsAccessUpdate(Command)
	
	If Not UpdateDataItemsAccessKeys
	   And Not UpdateAccessKeysRights
	   And Not DeleteObsoleteInternalData Then
	
		ShowMessageBox(, NStr("vi = 'Vui lòng chọn ít nhất một loại cập nhật.';
								|ru = 'Выберите хотя бы один вид обновления.';
								|en = 'Please select at least one update kind.'; fa = 'Please select at least one update kind.';
								|it = 'Selezionare almeno un tipo di aggiornamento.';
								|pl = 'Wybierz co najmniej jeden rodzaj aktualizacji.';
								|tr = 'En az bir güncelleme türü seçin.'"));
		Return;
	EndIf;
	
	If Not ScheduleListsAccessUpdateAtServer() Then
		ShowMessageBox(, NStr("vi = 'Vui lòng chọn ít nhất một danh sách.';
								|ru = 'Выберите хотя бы один список.';
								|en = 'Please select at least one list.'; fa = 'Please select at least one list.';
								|it = 'Selezionare almento un elenco.';
								|pl = 'Wybierz co najmniej jedną listę.';
								|tr = 'En az bir liste seçin.'"));
		Return;
	EndIf;
	
	Notify("Write_DataAccessKeysUpdate", New Structure, Undefined);
	Notify("Write_UsersAccessKeysUpdate", New Structure, Undefined);
	
	ShowUserNotification(NStr("vi = 'Cập nhật theo lịch trình.';
								|ru = 'Обновление запланировано.';
								|en = 'The update is scheduled.'; fa = 'The update is scheduled.';
								|it = 'Aggiornamento pianificato.';
								|pl = 'Aktualizacja jest zaplanowana.';
								|tr = 'Güncelleme planlandı.'"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function UpdateAccessToObjectAtServer()
	
	If Not ValueIsFilled(AccessUpdateObject) Then
		Return NStr("vi = 'Hãy chọn đối tượng.';
					|ru = 'Выберите объект.';
					|en = 'Please select an object.'; fa = 'Please select an object.';
					|it = 'Selezionare oggetto.';
					|pl = 'Wybierz obiekt.';
					|tr = 'Nesneyi seçin.'");
	EndIf;
	
	FullName = AccessUpdateObject.Metadata().FullName();
	TransactionID = New UUID;
	
	Text = "";
	
	UpdateAccessToObjectForUsersKind(AccessUpdateObject,
		FullName, TransactionID, False, Text);
	
	UpdateAccessToObjectForUsersKind(AccessUpdateObject,
		FullName, TransactionID, True, Text);
	
	Return Text;
	
EndFunction

&AtServer
Procedure UpdateAccessToObjectForUsersKind(ObjectReference, FullName, TransactionID, ForExternalUsers, Text)
	
	RestrictionParameters = AccessManagementInternal.RestrictionParameters(FullName,
		TransactionID, ForExternalUsers);
	
	Text = Text + ?(Text = "", "", Chars.LF + Chars.LF);
	If ForExternalUsers Then
		If RestrictionParameters.AccessDenied Then
			Text = Text + NStr("vi = 'Đối với người sử dụng ngoài (cấm truy cập):';
								|ru = 'Для внешних пользователей (доступ запрещен):';
								|en = 'For external users (access denied):'; fa = 'For external users (access denied):';
								|it = 'Per li utenti esterni (accesso vietato):';
								|pl = 'Dla użytkowników zewnętrznych (odmowa dostępu):';
								|tr = 'Harici kullanıcılar için (erişim yasaklandı):'");
			
		ElsIf RestrictionParameters.RestrictionDisabled Then
			Text = Text + NStr("vi = 'Đối với người sử dụng ngoài (ngắt hạn chế):';
								|ru = 'Для внешних пользователей (ограничение отключено):';
								|en = 'For external users (restriction disabled):'; fa = 'For external users (restriction disabled):';
								|it = 'Per utenti esterni (restrizione disabilitata):';
								|pl = 'Dla użytkowników zewnętrznych (ograniczenie wyłączone):';
								|tr = 'Harici kullanıcılar için (kısıtlama devre dışı bırakıldı):'");
		Else
			Text = Text + NStr("vi = 'Đối với người sử dụng:';
								|ru = 'Для внешних пользователей:';
								|en = 'For external users:'; fa = 'For external users:';
								|it = 'Per gli utenti esterni:';
								|pl = 'Dla użytkowników zewnętrznych:';
								|tr = 'Harici kullanıcılar için:'");
		EndIf;
	Else
		If RestrictionParameters.AccessDenied Then
			Text = Text + NStr("vi = 'Đối với người sử dụng (truy cập bị cấm):';
								|ru = 'Для пользователей (доступ запрещен):';
								|en = 'For users (access denied):'; fa = 'For users (access denied):';
								|it = 'Per gli utenti (accesso vietato):';
								|pl = 'Dla użytkowników (odmowa dostępu):';
								|tr = 'Kullanıcılar için (erişim yasaklandı):'");
			
		ElsIf RestrictionParameters.RestrictionDisabled Then
			Text = Text + NStr("vi = 'Đối với người sử dụng (việc hạn chế bị ngắt):';
								|ru = 'Для пользователей (ограничение отключено):';
								|en = 'For users (restriction disabled):'; fa = 'For users (restriction disabled):';
								|it = 'Per gli utenti (restrizione disabilitata)';
								|pl = 'Dla użytkowników (ograniczenie wyłączone):';
								|tr = 'Kullanıcılar için (kısıtlama devre dışı bırakıldı):'");
		Else
			Text = Text + NStr("vi = 'Đối với người sử dụng:';
								|ru = 'Для пользователей:';
								|en = 'For users:'; fa = 'For users:';
								|it = 'Per gli utenti:';
								|pl = 'Dla użytkowników:';
								|tr = 'Kullanıcılar için:'");
		EndIf;
	EndIf;
	
	SourceAccessKeyObsolete = AccessManagementInternal.SourceAccessKeyObsolete(
		ObjectReference, RestrictionParameters);
	
	HasRightsChanges = False;
	
	AccessManagementInternal.UpdateAccessKeysOfDataItemsOnWrite(ObjectReference,
		RestrictionParameters, TransactionID, True, HasRightsChanges);
	
	If RestrictionParameters.DoNotWriteAccessKeys Then
		If RestrictionParameters.AccessDenied
		 Or RestrictionParameters.RestrictionDisabled Then
			Text = Text + Chars.LF + NStr("vi = 'Không cần cập nhật. Các khóa truy cập cho các đối tượng thuộc loại này là không bắt buộc.';
											|ru = 'Обновление не требуется. Ключи доступа к объектам этого типа не нужны.';
											|en = 'Update not required. Objects of this type don''t require access keys.'; fa = 'Update not required. Objects of this type don''t require access keys.';
											|it = 'Non è richiesto l''aggiornamento. Le chiavi di accesso agli oggetti di questo tipo non sono richieste.';
											|pl = 'Aktualizacja nie jest wymagana. Klucze dostępu do obiektów tego typu nie są wymagane.';
											|tr = 'Güncelleme gerekmiyor. Bu türde nesnelere erişim anahtarları gerekmiyor.'");
		Else
			Text = Text + Chars.LF + NStr("vi = 'Không cần cập nhật. Các đối tượng kiểu này sử dụng khóa truy cập cho chủ sở hữu của chúng.';
											|ru = 'Обновление не требуется. Объекты этого типа используют ключи доступа к их владельцам.';
											|en = 'Update not required. Objects of this type use the owner''s access key.'; fa = 'Update not required. Objects of this type use the owner''s access key.';
											|it = 'Aggiornamento non richiesto. Gli oggetti di questo tipo utilizzano chiavi di accesso ai loro proprietari.';
											|pl = 'Aktualizacja nie jest wymagana. Obiekty tego typu są używane klucze dostępu do ich właścicieli.';
											|tr = 'Güncelleme gerekmiyor. Bu türde nesneler sahibinin erişim anahtarlarını kullanıyor.'");
		EndIf;
		Return;
	EndIf;
	
	If SourceAccessKeyObsolete Then
		Text = Text + Chars.LF + NStr("vi = '1. Đã cập nhật truy cập đến đối tượng.';
										|ru = '1. Обновлен ключ доступа к объекту.';
										|en = 'The object access key is updated.'; fa = 'The object access key is updated.';
										|it = '1. Chiave di accesso all''oggetto aggiornata.';
										|pl = '1. Zaktualizowano klucz dostępu do obiektu.';
										|tr = '1. Nesneye erişim anahtarı güncellendi.'");
	Else
		Text = Text + Chars.LF + NStr("vi = '1. Không cần cập nhật. Khóa truy cập đối tượng không bị lỗi thời.';
										|ru = '1. Обновление не требуется. Ключ доступа к объекту не устарел.';
										|en = '1. Update is not required. The object access key is not expired.'; fa = '1. Update is not required. The object access key is not expired.';
										|it = '1. Aggiornamento non richiesto. Chiave di accesso all''oggetto ancora valida.';
										|pl = '1. Aktualizacja nie jest wymagana. Klucz dostępu do obiektu jest przestarzały.';
										|tr = '1. Güncelleme gerekmiyor. Nesnenin erişim anahtarı hala geçerli.'");
	EndIf;
	
	If HasRightsChanges Then
		If RestrictionParameters.HasUsersRestriction Then
			If ForExternalUsers Then
				Text = Text + Chars.LF + NStr("vi = '2. Đã cập nhật các quyền đối với khóa truy cập cho người dùng bên ngoài hoặc nhóm truy cập.';
												|ru = '2. Обновлены права на ключ доступа у внешних пользователей или групп доступа.';
												|en = '2. Rights to the access key are updated for external users and access groups.'; fa = '2. Rights to the access key are updated for external users and access groups.';
												|it = '2. Sono stati aggiornati i diritti della chiave di accesso presso gli utenti esterni o i gruppi di accesso.';
												|pl = '2. Zaktualizowano prawa do klucza dostępu u użytkowników zewnętrznych lub grup dostępu.';
												|tr = '2. Harici kullanıcıların veya erişim gruplarının erişim anahtarı yetkileri güncellendi.'");
			Else
				Text = Text + Chars.LF + NStr("vi = '2. Đã cập nhật các quyền đối với khóa truy cập cho người dùng hoặc nhóm truy cập.';
												|ru = '2. Обновлены права на ключ доступа у пользователей или групп доступа.';
												|en = '2. Rights to the access key are updated for users and access groups.'; fa = '2. Rights to the access key are updated for users and access groups.';
												|it = '2. Sono stati aggiornati i diritti della chiave di accesso presso gli utenti o i gruppi di accesso.';
												|pl = '2. Zaktualizowano prawa do klucza dostępu u użytkowników lub grup dostępu.';
												|tr = '2. Kullanıcıların veya erişim gruplarının erişim anahtarı yetkileri güncellendi.'");
			EndIf;
		Else
			Text = Text + Chars.LF + NStr("vi = '2. Đã cập nhật các quyền khóa truy cập cho các nhóm truy cập.';
											|ru = '2. Обновлены права на ключ доступа у групп доступа.';
											|en = '2. Rights to the access key are updated for access groups.'; fa = '2. Rights to the access key are updated for access groups.';
											|it = '2. Sono stati aggiornati i diritti della chiave di accesso presso i gruppi di accesso.';
											|pl = '2. Zaktualizowano prawa do klucza dostępu u grup dostępu.';
											|tr = '2. Erişim grubunda erişin anahtarı yetkileri güncellendi.'");
		EndIf;
	Else
		If RestrictionParameters.HasUsersRestriction Then
			If ForExternalUsers Then
				Text = Text + Chars.LF + NStr("vi = '2. Không cần cập nhật. Quyền truy cập chính cho người dùng bên ngoài và các nhóm truy cập không bị ngừng sử dụng.';
												|ru = '2. Обновление не требуется. Права на ключ доступа у внешних пользователей и групп доступа не устарели.';
												|en = '2. Update is not required. Rights to the access key for external users and access groups are current.'; fa = '2. Update is not required. Rights to the access key for external users and access groups are current.';
												|it = '2. Aggiornamento non richiesto. I diritti della chiave di accesso presso gli utenti esterni e i gruppi di accesso sono ancora validi.';
												|pl = '2. Aktualizacja nie jest wymagana. Prawa na klucz dostępu u użytkowników zewnętrznych i grup dostępu nie są przestarzałe.';
												|tr = '2. Güncelleme gerekmiyor. Harici kullanıcıların ve erişim grubunun anahtar yetkileri hala geçerli.'");
			Else
				Text = Text + Chars.LF + NStr("vi = '2. Không cần cập nhật. Quyền truy cập chính cho người dùng và nhóm truy cập chưa hết hạn.';
												|ru = '2. Обновление не требуется. Права на ключ доступа у пользователей и групп доступа не устарели.';
												|en = '2. Update is not required. Rights to the access key for users and access groups are current.'; fa = '2. Update is not required. Rights to the access key for users and access groups are current.';
												|it = '2. Aggiornamento non richiesto. I diritti della chiave di accesso presso gli utenti e i gruppi di accesso sono ancora validi.';
												|pl = '2. Aktualizacja nie jest wymagana. Prawa na klucz dostępu u użytkowników i grup dostępu nie są przestarzałe.';
												|tr = '2. Güncelleme gerekmiyor. Kullanıcıların ve erişim grubunun anahtar yetkileri hala geçerli.'");
			EndIf;
		Else
			Text = Text + Chars.LF + NStr("vi = '2. Không cần cập nhật. Quyền truy cập chính cho các nhóm truy cập chưa hết hạn.';
											|ru = '2. Обновление не требуется. Права на ключ доступа у групп доступа не устарели.';
											|en = '2. Update is not required. Rights to the access key for access groups are current.'; fa = '2. Update is not required. Rights to the access key for access groups are current.';
											|it = '2. Aggiornamento non richiesto. I diritti della chiave di accesso presso i gruppi di accesso sono ancora validi.';
											|pl = '2. Aktualizacja nie jest wymagana. Prawa na klucz dostępu u grup dostępu nie są przestarzałe.';
											|tr = '2. Güncelleme gerekmiyor. Erişim grubunun anahtar yetkileri hala geçerli.'");
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ScheduleListsAccessUpdateAtServer()
	
	Lists = New Array;
	For Each ListItem In ListsToUpdate Do
		If ListItem.Check Then
			Lists.Add(ListItem.Value);
		EndIf;
	EndDo;
	
	If Lists.Count() = 0 Then
		Return False;
	EndIf;
	
	If Lists.Count() = ListsToUpdate.Count() Then
		Lists = Undefined;
	EndIf;
	
	If UpdateDataItemsAccessKeys Or UpdateAccessKeysRights Then
		PlanningParameters = AccessManagementInternal.AccessUpdatePlanningParameters();
		PlanningParameters.ListsRestrictionsVersions = New Map(ListsRestrictionsVersions);
		PlanningParameters.IsUpdateContinuation = True;
		If Not UpdateDataItemsAccessKeys Then
			PlanningParameters.DataAccessKeys = False;
		EndIf;
		If Not UpdateAccessKeysRights Then
			PlanningParameters.AllowedAccessKeys = False;
		EndIf;
		PlanningParameters.LongDesc = "ScheduleManualAccessUpdate";
		AccessManagementInternal.ScheduleAccessUpdate(Lists, PlanningParameters);
	EndIf;
	
	If DeleteObsoleteInternalData Then
		PlanningParameters = AccessManagementInternal.AccessUpdatePlanningParameters(False);
		PlanningParameters.ListsRestrictionsVersions = New Map(ListsRestrictionsVersions);
		PlanningParameters.IsObsoleteItemsDataProcessor = True;
		PlanningParameters.LongDesc = "ScheduleManualAccessUpdate";
		AccessManagementInternal.ScheduleAccessUpdate(Lists, PlanningParameters);
	EndIf;
	
	AccessManagementInternal.SetAccessUpdate(False);
	AccessManagementInternal.SetAccessUpdate(True);
	
	Return True;
	
EndFunction

// AccessUpdateObjectStartChoice event handler continuation.
&AtClient
Procedure AccessUpdateObjectStartChoiceContinued(SelectedElement, Var_Undefined) Export
	
	If SelectedElement = Undefined Then
		Return;
	EndIf;
	
	SelectedAccessUpdateObjectType = SelectedElement.Value;
	If TypeOf(AccessUpdateObject) <> TypeOf(SelectedAccessUpdateObjectType) Then
		AccessUpdateObject = SelectedAccessUpdateObjectType;
	EndIf;
	
	AccessValueStartChoiceCompletion();
	
EndProcedure

// Completes the AccessUpdateObjectStartChoice event handler.
&AtClient
Procedure AccessValueStartChoiceCompletion()
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CurrentRow", AccessUpdateObject);
	
	ListItem = AccessUpdateObjectsTypesTablesNames.FindByValue(
		SelectedAccessUpdateObjectType);
	
	If ListItem = Undefined Then
		Return;
	EndIf;
	ChoiceFormName = ListItem.Presentation + ".ChoiceForm";
	
	OpenForm(ChoiceFormName, FormParameters, Items.AccessUpdateObject);
	
EndProcedure

#EndRegion
