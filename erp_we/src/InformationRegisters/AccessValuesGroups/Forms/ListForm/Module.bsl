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

	SetConditionalAppearance();
	
	ReadOnly = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

&AtClient
Procedure UpdateRegisterData(Command)
	
	HasChanges = False;
	
	UpdateRegisterDataAtServer(HasChanges);
	
	If HasChanges Then
		Text = NStr("vi = 'Đã cập nhật thành công.';
					|ru = 'Обновление выполнено успешно.';
					|en = 'Updated successfully.'; fa = 'Updated successfully.';
					|it = 'Aggiornamento effettuato con successo.';
					|pl = 'Aktualizacja zakończona powodzeniem.';
					|tr = 'Güncelleme başarılı.'");
	Else
		Text = NStr("vi = 'Không cần cập nhật.';
					|ru = 'Обновление не требуется.';
					|en = 'No update required.'; fa = 'No update required.';
					|it = 'Aggiornamento non richiesto.';
					|pl = 'Aktualizacja nie jest konieczna.';
					|tr = 'Güncelleme gerekmiyor.'");
	EndIf;
	
	ShowMessageBox(, Text);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	List.SettingsComposer.Settings.ConditionalAppearance.Items.Clear();
	
	ApplyDataGroupAppearance(0, NStr("vi = 'Giá trị truy cập chuẩn';
									|ru = 'Стандартные значения доступа';
									|en = 'Standard access values'; fa = 'مقادیر دسترسی استاندارد';
									|it = 'Valori di accesso standard';
									|pl = 'Standardowe wartości dostępu';
									|tr = 'Standart erişim değerleri'"));
	ApplyDataGroupAppearance(1, NStr("vi = 'Người sử dụng bên ngoài/thông thường';
									|ru = 'Обычные/внешние пользователи';
									|en = 'Internal or external users'; fa = 'کاربران داخلی یا خارجی';
									|it = 'Utenti regolari/esterni';
									|pl = 'Zwykli/zewnętrzni użytkownicy';
									|tr = 'Normal/harici kullanıcılar'"));
	ApplyDataGroupAppearance(2, NStr("vi = 'Nhóm người sử dụng bên ngoài/thông thường';
									|ru = 'Обычные/внешние группы пользователей';
									|en = 'Internal or external user groups'; fa = 'گروه‌های کاربران داخلی یا خارجی';
									|it = 'Gruppi di utenti regolari/esterni';
									|pl = 'Zwykłe/zewnętrzne grupy użytkowników';
									|tr = 'Normal veya harici kullanıcı grupları'"));
	ApplyDataGroupAppearance(3, NStr("vi = 'Nhóm người thực hiện';
									|ru = 'Группы исполнителей';
									|en = 'Assignee groups'; fa = 'گروه‌های مجری';
									|it = 'Gruppi di prestatori di lavoro';
									|pl = 'Grupy wykonawców';
									|tr = 'Yürütücü grupları'"));
	ApplyDataGroupAppearance(4, NStr("vi = 'Đối tượng đăng nhập';
									|ru = 'Объекты авторизации';
									|en = 'Authorization objects'; fa = 'اشیای احراز مجوز';
									|it = 'Oggetti di autorizzazione';
									|pl = 'Obiekty autoryzacji';
									|tr = 'Yetkilendirme nesneleri'"));
	
EndProcedure

&AtServer
Procedure ApplyDataGroupAppearance(DataGroup, Text)
	
	AppearanceItem = List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	AppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FieldItem = AppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField("DataGroup");
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("DataGroup");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = DataGroup;
	
	AppearanceItem.Appearance.SetParameterValue("Text", Text);
	
EndProcedure

&AtServer
Procedure UpdateRegisterDataAtServer(HasChanges)
	
	SetPrivilegedMode(True);
	
	InformationRegisters.AccessValuesGroups.UpdateRegisterData(HasChanges);
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion
