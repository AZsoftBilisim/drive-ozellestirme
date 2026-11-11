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
	
	ReadOnly = True;
	
	ChoiceList = Items.SetItemsType.ChoiceList;
	AddListItem(ChoiceList, "AccessGroups");
	AddListItem(ChoiceList, "UserGroups");
	AddListItem(ChoiceList, "Users");
	AddListItem(ChoiceList, "ExternalUsersGroups");
	AddListItem(ChoiceList, "ExternalUsers");
	
	SetAttributesPageByType(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SetItemsTypeOnChange(Item)
	
	SetAttributesPageByType(ThisObject);
	Object.Groups.Clear();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
	ShowMessageBox(,
		NStr("vi = 'Không nên thay đổi tập hợp nhóm truy cập vì nó được ánh xạ tới các khóa truy cập khác nhau.
		           |Để khắc phục sự cố không chuẩn, nên xóa tập hợp nhóm truy cập hoặc
		           | liên kết đến nó trong sổ đăng ký và thực hiện quy trình cập nhật quyền truy cập.';
		           |ru = 'Набор групп доступа не следует изменять, так как он сопоставлен с разными ключами доступа.
		           |Чтобы исправить нестандартную проблему следует удалить набор групп доступа или
		           |связь с ним в регистрах и выполнить процедуру обновления доступа.';
		           |en = 'It is recommended that you do not change the access group set as it is mapped to different access keys.
		           |To resolve the issue, delete the access group set or
		           |delete the mapping between the set and the access keys in the registers, and then run the access update.'; fa = 'It is recommended that you do not change the access group set as it is mapped to different access keys.
		           |To resolve the issue, delete the access group set or
		           |delete the mapping between the set and the access keys in the registers, and then run the access update.';
		           |it = 'L''insieme di gruppi di accesso non deve essere modificato, poiché è associato a chiavi di accesso diverse. 
		           |Per risolvere un problema non conforme agli standard, bisogna cancellare l''insieme dei gruppi di accesso oppure
		           |il collegamento ad essi nei registri ed eseguire la procedura di aggiornamento dell''accesso.';
		           |pl = 'Zestaw grup dostępu nie należy zmieniać, ponieważ on jest zestawiony z różnymi kluczami dostępu. 
		           |Aby poprawić nietypowy problem należy usunąć zestaw grup dostępu lub
		           |związek z nim w rejestrach i wykonać procedurę aktualizacji dostępu.';
		           |tr = 'Farklı nesnelerle eşleştirildiğinden erişim anahtarı değiştirilmemelidir.
		           |Standart olmayan bir sorunu gidermek için, erişim anahtarını veya 
		           |kayıtlarda onunla bağlantıyı kaldırmanız ve erişim güncelleme işlemini gerçekleştirmeniz gerekir.'"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddListItem(ChoiceList, CatalogName)
	
	BlankID = CommonClientServer.BlankUUID();
	
	ChoiceList.Add(Catalogs[CatalogName].GetRef(BlankID),
		Metadata.Catalogs[CatalogName].Presentation());
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAttributesPageByType(Form)
	
	If TypeOf(Form.Object.SetItemsType) = Type("CatalogRef.Users")
	 Or TypeOf(Form.Object.SetItemsType) = Type("CatalogRef.ExternalUsers") Then
		
		Form.Items.SetsAttributes.CurrentPage = Form.Items.SingleUserSetAttributes;
	Else
		Form.Items.SetsAttributes.CurrentPage = Form.Items.GroupsSetAttributes;
	EndIf;
	
EndProcedure

#EndRegion
