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
	
	AccessManagementInternal.CheckIsAccessRestrictionDisabled();
	
	ObjectReference = Parameters.ObjectReference;
	If Not ValueIsFilled(ObjectReference) Then
		Raise NStr("vi = 'Chưa chỉ ra đối tượng chủ tùy chỉnh quyền.';
					|ru = 'Не указан владелец настроек прав.';
					|en = 'The owner of access rights is required.'; fa = 'The owner of access rights is required.';
					|it = 'Il proprietario delle impostazioni dei diritti non è indicato.';
					|pl = 'Nie wskazano właściciela ustawień uprawnień.';
					|tr = 'Yetki ayarların sahibi belirtilmedi.'");
	EndIf;
	
	AvailableRightsForSetting = AccessManagementInternal.RightsForObjectsRightsSettingsAvailable();
	ObjectRefType = TypeOf(ObjectReference);
	
	If AvailableRightsForSetting.ByRefsTypes.Get(ObjectRefType) = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Quyền của mỗi đối tượng không thể định cấu hình 
			           | cho các đối tượng thuộc loại ""%1"".';
			           |ru = 'Права доступа для каждого объекта не настраиваются
			           |для объектов типа ""%1"".';
			           |en = 'Objects of ""%1"" type
			           |don''t support individual access rights.'; fa = 'Objects of ""%1"" type
			           |don''t support individual access rights.';
			           |it = 'I diritti di accesso per ciascun oggetto non vengono configurati
			           |per oggetti di tipo ""%1"".';
			           |pl = 'Prawa dostępu dla każdego obiektu nie są ustawiane
			           |dla obiektów typu ""%1"".';
			           |tr = 'Her nesnenin erişim hakları %1""
			           |"" tipi nesneler için yapılandırılmamaktadır.'"),
			String(ObjectRefType));
	EndIf;
	
	If Not AccessRight("View", Metadata.FindByType(ObjectRefType)) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không có quyền Xem đối tượng kiểu ""%1"".';
				|ru = 'Нет права Просмотр на объекты типа ""%1"".';
				|en = 'Insufficient rights to read objects of the ""%1"" type.'; fa = 'Insufficient rights to read objects of the ""%1"" type.';
				|it = 'Nessun diritto Visualizzazione per gli oggetti del tipo ""%1"".';
				|pl = 'Brak prawa Przeglądanie do obiektów typu ""%1"".';
				|tr = '""%1"" tür nesneler için Görüntüleme hakkı yok.'"), String(ObjectRefType));
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Quyền truy cập: %1 (%2)';
			|ru = 'Права доступа: %1 (%2)';
			|en = 'Access rights: %1 (%2)'; fa = 'Access rights: %1 (%2)';
			|it = 'Diritti di accesso: %1 (%2)';
			|pl = 'Prawa dostępu: %1 (%2)';
			|tr = 'Erişim yetileri: %1 (%2)'"), String(ObjectReference), String(ObjectRefType));
	
	// Checking the permissions to open a form
	ValidatePermissionToManageRights();
	
	UseExternalUsers =
		ExternalUsers.UseExternalUsers()
		And AccessRight("View", Metadata.Catalogs.ExternalUsers);
	
	SetPrivilegedMode(True);
	
	UserTypesList.Add(Type("CatalogRef.Users"),
		Metadata.Catalogs.Users.Synonym);
	
	UserTypesList.Add(Type("CatalogRef.ExternalUsers"),
		Metadata.Catalogs.ExternalUsers.Synonym);
	
	ParentFilled =
		Parameters.ObjectReference.Metadata().Hierarchical
		And ValueIsFilled(Common.ObjectAttributeValue(Parameters.ObjectReference, "Parent"));
	
	Items.InheritParentRights.Visible = ParentFilled;
	
	FillRights();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseNotification", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InheritParentRightsOnChange(Item)
	
	InheritParentsRightsOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure InheritParentsRightsOnChangeAtServer()
	
	If InheritParentRights Then
		AddInheritedRights();
		FillUserPictureNumbers();
	Else
		// Clearing settings inherited from the hierarchical parents.
		IndexOf = RightsGroups.Count()-1;
		While IndexOf >= 0 Do
			If RightsGroups.Get(IndexOf).ParentSetting Then
				RightsGroups.Delete(IndexOf);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRightsGroups

&AtClient
Procedure RightsGroupsOnChange(Item)
	
	RightsGroups.Sort("ParentSetting Desc");
	
EndProcedure

&AtClient
Procedure RightsGroupsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "RightsGroupsUser" Then
		Return;
	EndIf;
	
	Cancel = False;
	CheckOpportunityToChangeRights(Cancel);
	
	If Not Cancel Then
		CurrentRight  = Mid(Field.Name, StrLen("RightsGroups") + 1);
		CurrentData = Items.RightsGroups.CurrentData;
		
		If CurrentRight = "InheritanceIsAllowed" Then
			CurrentData[CurrentRight] = Not CurrentData[CurrentRight];
			Modified = True;
			
		ElsIf AvailableRights.Property(CurrentRight) Then
			PreviousValue2 = CurrentData[CurrentRight];
			
			If CurrentData[CurrentRight] = True Then
				CurrentData[CurrentRight] = False;
				
			ElsIf CurrentData[CurrentRight] = False Then
				CurrentData[CurrentRight] = Undefined;
			Else
				CurrentData[CurrentRight] = True;
			EndIf;
			Modified = True;
			
			UpdateDependentRights(CurrentData, CurrentRight, PreviousValue2);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure RightsGroupsOnActivateRow(Item)
	
	CurrentData = Items.RightsGroups.CurrentData;
	
	CommandsAvailability = ?(CurrentData = Undefined, False, Not CurrentData.ParentSetting);
	Items.RightsGroupsContextMenuDelete.Enabled = CommandsAvailability;
	Items.FormDelete.Enabled                     = CommandsAvailability;
	Items.FormMoveUp.Enabled            = CommandsAvailability;
	Items.FormMoveDown.Enabled             = CommandsAvailability;
	
EndProcedure

&AtClient
Procedure RightsGroupsOnActivateField(Item)
	
	CommandsAvailability = AvailableRights.Property(Mid(Item.CurrentItem.Name, StrLen("RightsGroups") + 1));
	Items.RightsGroupsContextMenuDisableRight.Enabled       = CommandsAvailability;
	Items.RightsGroupsContextMenuGrantRight.Enabled = CommandsAvailability;
	Items.RightsGroupsContextMenuDenyRight.Enabled     = CommandsAvailability;
	
EndProcedure

&AtClient
Procedure RightsGroupsBeforeRowChange(Item, Cancel)
	
	CheckOpportunityToChangeRights(Cancel);
	
EndProcedure

&AtClient
Procedure RightsGroupsBeforeDeleteRow(Item, Cancel)
	
	CheckOpportunityToChangeRights(Cancel, True);
	
EndProcedure

&AtClient
Procedure RightsGroupsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		// Set initial values.
		Items.RightsGroups.CurrentData.SettingsOwner     = Parameters.ObjectReference;
		Items.RightsGroups.CurrentData.InheritanceIsAllowed = True;
		Items.RightsGroups.CurrentData.ParentSetting     = False;
		
		For Each AddedAttribute In AddedAttributes Do
			Items.RightsGroups.CurrentData[AddedAttribute.Key] = AddedAttribute.Value;
		EndDo;
	EndIf;
	
	If Items.RightsGroups.CurrentData.User = Undefined Then
		Items.RightsGroups.CurrentData.User  = PredefinedValue("Catalog.Users.EmptyRef");
		Items.RightsGroups.CurrentData.PictureNumber = -1;
	EndIf;
	
EndProcedure

&AtClient
Procedure RightsGroupsUserOnChange(Item)
	
	If ValueIsFilled(Items.RightsGroups.CurrentData.User) Then
		FillUserPictureNumbers(Items.RightsGroups.CurrentRow);
	Else
		Items.RightsGroups.CurrentData.PictureNumber = -1;
	EndIf;
	
EndProcedure

&AtClient
Procedure RightsGroupsUserStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectUsers();
	
EndProcedure

&AtClient
Procedure RightsGroupsUserClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Items.RightsGroups.CurrentData.User  = PredefinedValue("Catalog.Users.EmptyRef");
	Items.RightsGroups.CurrentData.PictureNumber = -1;
	
EndProcedure

&AtClient
Procedure RightsGroupsUserTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	If ValueIsFilled(Text) Then 
		StandardProcessing = False;
		ChoiceData = GenerateUserSelectionData(Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure RightsGroupsUserAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		ChoiceData = GenerateUserSelectionData(Text);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	WriteBeginning(True);
	
EndProcedure

&AtClient
Procedure Write(Command)
	
	WriteBeginning();
	
EndProcedure

&AtClient
Procedure Reread(Command)
	
	If Not Modified Then
		ReadRights();
	Else
		ShowQueryBox(
			New CallbackDescription("RereadCompletion", ThisObject),
			NStr("vi = 'Dữ liệu đã thay đổi. Đọc mà không lưu lại?';
				|ru = 'Данные изменены. Прочитать без сохранения?';
				|en = 'The data was changed. Do you want to read the data without saving it?'; fa = 'The data was changed. Do you want to read the data without saving it?';
				|it = 'Dati modificati. Leggere senza salvare?';
				|pl = 'Dane zostały zmienione. Odczytać bez zapisywania?';
				|tr = 'Veriler değişti. Kaydetmeden okunsun mu?'"),
			QuestionDialogMode.YesNo,
			5,
			DialogReturnCode.No);
	EndIf;
	
EndProcedure

&AtClient
Procedure DisableRight(Command)
	
	SetCurrentRightValue(Undefined);
	
EndProcedure

&AtClient
Procedure DenyRight(Command)
	
	SetCurrentRightValue(False);
	
EndProcedure

&AtClient
Procedure GrantRight(Command)
	
	SetCurrentRightValue(True);
	
EndProcedure

&AtClient
Procedure SetCurrentRightValue(NewValue)
	
	Cancel = False;
	CheckOpportunityToChangeRights(Cancel);
	
	If Not Cancel Then
		CurrentRight  = Mid(Items.RightsGroups.CurrentItem.Name, StrLen("RightsGroups") + 1);
		CurrentData = Items.RightsGroups.CurrentData;
		
		If AvailableRights.Property(CurrentRight)
		   And CurrentData <> Undefined Then
			
			PreviousValue2 = CurrentData[CurrentRight];
			CurrentData[CurrentRight] = NewValue;
			
			Modified = True;
			
			UpdateDependentRights(CurrentData, CurrentRight, PreviousValue2);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(
		Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("RightsGroups.ParentSetting");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = True;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.RightsGroups.Name);
	
EndProcedure

&AtClient
Procedure WriteAndCloseNotification(Result, Context) Export
	
	WriteBeginning(True);
	
EndProcedure

&AtClient
Procedure WriteBeginning(Close = False)
	
	Cancel = False;
	FillCheckProcessing(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	ConfirmRightsManagementCancellation = Undefined;
	Try
		WriteRights();
	Except
		If ConfirmRightsManagementCancellation <> True Then
			Raise;
		EndIf;
	EndTry;
	
	If ConfirmRightsManagementCancellation = True Then
		Buttons = New ValueList;
		Buttons.Add("WriteAndClose", NStr("vi = 'Ghi lại và đóng';
											|ru = 'Записать и закрыть';
											|en = 'Save and close'; fa = 'ذخیره و بستن';
											|it = 'Salvare e chiudere';
											|pl = 'Zapisz i zamknij';
											|tr = 'Kaydet ve kapat'"));
		Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Anuluj';
									|tr = 'İptal'"));
		ShowQueryBox(
			New CallbackDescription("SaveAfterConfirmation", ThisObject),
			NStr("vi = 'sau khi ghi lại, sẽ không dùng được tùy chỉnh quyền.';
				|ru = 'После записи настройка прав станет недоступной.';
				|en = 'Once you save the access rights, you will not be able to change them.'; fa = 'Once you save the access rights, you will not be able to change them.';
				|it = 'Dopo la registrazione, l''impostazione dei diritti diventerà non disponibile.';
				|pl = 'Po zapisaniu ustawianie uprawnień będzie niemożliwe.';
				|tr = 'Yazdıktan sonra, erişim hakları atayamazsınız.'"),
			Buttons,, "Cancel");
	Else
		If Close Then
			Close();
		Else
			ClearMessages();
		EndIf;
		WriteCompletion();
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveAfterConfirmation(Response, Context) Export
	
	If Response = "WriteAndClose" Then
		ConfirmRightsManagementCancellation = False;
		WriteRights();
		Close();
	EndIf;
	
	WriteCompletion();
	
EndProcedure

&AtClient
Procedure WriteCompletion()
	
	Notify("Write_ObjectsRightsSettings", , Parameters.ObjectReference);
	
EndProcedure

&AtClient
Procedure RereadCompletion(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		ReadRights();
	EndIf;
	
EndProcedure

#Region AuxiliaryProceduresAndFunctions

&AtClient
Procedure UpdateDependentRights(Val Data, Val Right, Val PreviousValue2, Val RecursionDepth = 0)
	
	If Data[Right] = PreviousValue2 Then
		Return;
	EndIf;
	
	If RecursionDepth > 100 Then
		Return;
	Else
		RecursionDepth = RecursionDepth + 1;
	EndIf;
	
	DependentRights = Undefined;
	
	If Data[Right] = True Then
		
		// Permissions were leveled up (from "False" or "Undefined" to "True").
		// Therefore, level up permissions for the parent access rights.
		DirectRightsDependencies.Property(Right, DependentRights);
		DependentRightValue = True;
		
	ElsIf Data[Right] = False Then
		
		// Restrictions were leveled up (from "True" or "Undefined" to "False").
		// Therefore, level up restrictions for the child access rights.
		ReverseRightsDependencies.Property(Right, DependentRights);
		DependentRightValue = False;
	Else
		If PreviousValue2 = False Then
			// Restrictions were leveled down (from "False" to "Undefined").
			// Therefore, level down restrictions for the parent rights.
			DirectRightsDependencies.Property(Right, DependentRights);
			DependentRightValue = Undefined;
		Else
			// Permissions were leveled down (from "True" to "Undefined").
			// Therefore, level down permissions for the child rights.
			ReverseRightsDependencies.Property(Right, DependentRights);
			DependentRightValue = Undefined;
		EndIf;
	EndIf;
	
	If DependentRights <> Undefined Then
		For Each DependentRight In DependentRights Do
			If TypeOf(DependentRight) = Type("Array") Then
				SetDependentRight = True;
				For Each OneOfDependentRights In DependentRight Do
					If Data[OneOfDependentRights] = DependentRightValue Then
						SetDependentRight = False;
						Break;
					EndIf;
				EndDo;
				If SetDependentRight Then
					If Not (DependentRightValue = Undefined And Data[DependentRight[0]] <> PreviousValue2) Then
						CurrentPreviousValue = Data[DependentRight[0]];
						Data[DependentRight[0]] = DependentRightValue;
						UpdateDependentRights(Data, DependentRight[0], CurrentPreviousValue);
					EndIf;
				EndIf;
			Else
				If Not (DependentRightValue = Undefined And Data[DependentRight] <> PreviousValue2) Then
					CurrentPreviousValue = Data[DependentRight];
					Data[DependentRight] = DependentRightValue;
					UpdateDependentRights(Data, DependentRight, CurrentPreviousValue);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure AddAttribute(NewAttributes, Attribute, InitialValue)
	
	NewAttributes.Add(Attribute);
	AddedAttributes.Insert(Attribute.Name, InitialValue);
	
EndProcedure

&AtServer
Function AddItem(Name, Type, Parent)
	
	Item = Items.Add(Name, Type, Parent);
	Item.FixingInTable = FixingInTable.None;
	
	Return Item;
	
EndFunction

&AtServer
Procedure AddAttributesOrFormItems(NewAttributes = Undefined)
	
	AvailableRightsForSetting = AccessManagementInternal.RightsForObjectsRightsSettingsAvailable();
	RightsOwnerRefType = TypeOf(Parameters.ObjectReference);
	AvailableRightsDetails1 = AvailableRightsForSetting.ByRefsTypes.Get(RightsOwnerRefType);
	
	PseudoFlagTypesDetails = New TypeDescription("Boolean, Number",
		New NumberQualifiers(1, 0, AllowedSign.Nonnegative));
	
	// Adding available rights restricted by an owner (by an access value table).
	For Each RightDetails In AvailableRightsDetails1 Do
		RightPresentations = InformationRegisters.ObjectsRightsSettings.AvailableRightPresentation(RightDetails);
		
		If NewAttributes <> Undefined Then
			
			AddAttribute(NewAttributes, New FormAttribute(RightPresentations.Name, PseudoFlagTypesDetails,
				"RightsGroups", RightPresentations.Title), RightDetails.InitialValue);
			
			AvailableRights.Insert(RightPresentations.Name);
			
			// Adding direct and reverse rights dependencies.
			DirectRightsDependencies.Insert(RightPresentations.Name, RightDetails.RequiredRights1);
			For Each RequiredRight In RightDetails.RequiredRights1 Do
				If ReverseRightsDependencies.Property(RequiredRight) Then
					DependentRights = ReverseRightsDependencies[RequiredRight];
				Else
					DependentRights = New Array;
					ReverseRightsDependencies.Insert(RequiredRight, DependentRights);
				EndIf;
				If DependentRights.Find(RightPresentations.Name) = Undefined Then
					DependentRights.Add(RightPresentations.Name);
				EndIf;
			EndDo;
		Else
			TagName = "RightsGroups"  + RightPresentations.Name;
			DataPath = "RightsGroups." + RightPresentations.Name;
			Item = AddItem(TagName, Type("FormField"), Items.RightsGroups);
			Item.Type                           = FormFieldType.LabelField;
			Item.HeaderHorizontalAlign = ItemHorizontalLocation.Center;
			Item.HorizontalAlign       = ItemHorizontalLocation.Center;
			Item.DataPath                   = DataPath;
			
			Item.ToolTip = RightPresentations.ToolTip;
			SetWidthByTitle(Item, RightPresentations.Title);
			
			SetCheckboxStyle(TagName, 0, DataPath, Undefined);
			SetCheckboxStyle(TagName, 1, DataPath, True);
			SetCheckboxStyle(TagName, 2, DataPath, False);
		EndIf;
		
		If Items.RightsGroups.HeaderHeight < StrLineCount(RightPresentations.Title) Then
			Items.RightsGroups.HeaderHeight = StrLineCount(RightPresentations.Title);
		EndIf;
	EndDo;
	
	If NewAttributes = Undefined And Parameters.ObjectReference.Metadata().Hierarchical Then
		// Item RightsGroupsInheritanceAllowed.
		Item = AddItem("RightsGroupsInheritanceAllowed", Type("FormField"), Items.RightsGroups);
		Item.Type                           = FormFieldType.LabelField;
		Item.HeaderHorizontalAlign = ItemHorizontalLocation.Center;
		Item.HorizontalAlign       = ItemHorizontalLocation.Center;
		Item.DataPath                   = "RightsGroups.InheritanceIsAllowed";
		
		Item.Title = NStr("vi = 'Đối với
		                               |thư mục con';
		                               |ru = 'Для
		                               |подпапок';
		                               |en = 'Apply to
		                               |subfolders'; fa = 'Apply to
		                               |subfolders';
		                               |it = 'Per
		                               |le sottocartelle';
		                               |pl = 'Apply to
		                               |subfolders';
		                               |tr = 'Alt klasörler
		                               |için'");
		Item.ToolTip = NStr("vi = 'Quyền không chỉ đối với thư mục hiện tại,
		                               |mà còn đối với các thư mục con của nó';
		                               |ru = 'Права не только для текущей папки,
		                               |но и для ее нижестоящих папок';
		                               |en = 'Apply the folder access rights
		                               |to its subfolders.'; fa = 'Apply the folder access rights
		                               |to its subfolders.';
		                               |it = 'Diritti non solo per la cartella corrente,
		                               |ma anche per le sue cartelle sottostanti';
		                               |pl = 'Uprawnienia nie tylko dla bieżącego folderu,
		                               |ale także dla jego folderów podporządkowanych';
		                               |tr = 'Yetkiler sadece geçerli klasör için değil, 
		                               |aynı zamanda alt klasörler için de'");
		SetWidthByTitle(Item);
		
		SetCheckboxStyle("RightsGroupsInheritanceAllowed", 1, "RightsGroups.InheritanceIsAllowed", True);
		SetCheckboxStyle("RightsGroupsInheritanceAllowed", 2, "RightsGroups.InheritanceIsAllowed", False);
		
		// Item RightsGroupsOwnerSettings.
		Item = AddItem("RightsGroupsOwnerSettings", Type("FormField"), Items.RightsGroups);
		Item.Type         = FormFieldType.LabelField;
		Item.DataPath = "RightsGroups.SettingsOwner";
		Item.Title   = NStr("vi = 'Kế thừa từ';
							|ru = 'Наследуется от';
							|en = 'Inherit from'; fa = 'Inherit from';
							|it = 'Eredita da';
							|pl = 'Dziedziczony po';
							|tr = 'Devreden'");
		Item.ToolTip   = NStr("vi = 'Thư mục mà tùy chỉnh quyền kế thừa từ đó';
								|ru = 'Папка, от которой наследуются настройка прав';
								|en = 'The folder that is the source of access rights.'; fa = 'The folder that is the source of access rights.';
								|it = 'Cartella, dalla quale viene ereditata la configurazione dei diritti';
								|pl = 'Folder, po którym są dziedziczone ustawienia uprawnień';
								|tr = 'Erişim hakları ayarlarının devralındığı klasör'");
		Item.Visible   = ParentFilled;
		
		
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		ConditionalAppearanceItem.Appearance.SetParameterValue("Text", "");
		
		FilterElement = ConditionalAppearanceItem.Filter.Items.Add(
			Type("DataCompositionFilterItem"));
		FilterElement.LeftValue  = New DataCompositionField("RightsGroups.ParentSetting");
		FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = False;
		
		FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
		FormattedField.Field = New DataCompositionField("RightsGroupsOwnerSettings");
		
		
		If Items.RightsGroups.HeaderHeight = 1 Then
			Items.RightsGroups.HeaderHeight = 2;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetWidthByTitle(Item, Var_Title = "")
	
	If Not ValueIsFilled(Var_Title) Then
		Var_Title = Item.Title;
	EndIf;
	
	ItemWidth = 0;
	For LineNumber = 1 To StrLineCount(Var_Title) Do
		ItemWidth = Max(ItemWidth, StrLen(StrGetLine(Var_Title, LineNumber)));
	EndDo;
	Item.Width = Int(ItemWidth * 0.7);
	
	If Item.Width < 3 Then
		Item.Width = 3;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCheckboxStyle(TagName, ColorOption, Var_AttributeName, RightValue);
	
	If ColorOption = 0 Then
		TextColor  = Metadata.StyleItems.UnassignedAccessRightColor.Value;
		Font       = Items.ImageRightNotAssigned.Font;
		Char      = Items.ImageRightNotAssigned.Title;
		
	ElsIf ColorOption = 1 Then
		TextColor = Metadata.StyleItems.AllowedAccessRightColor.Value;
		Font      = Items.PictureRightAllowed.Font;
		Char     = Items.PictureRightAllowed.Title;
		
	ElsIf ColorOption = 2 Then
		TextColor = Metadata.StyleItems.DeniedAccessRightColor.Value;
		Font      = Items.ImageRightForbidden.Font;
		Char     = Items.ImageRightForbidden.Title;
	EndIf;
	
	// Color.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor",  TextColor);
	
	If ColorOption <> 0 Then
		FilterElement = ConditionalAppearanceItem.Filter.Items.Add(
			Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("RightsGroups.ParentSetting");
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = False;
	EndIf;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(
		Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField(Var_AttributeName);
	FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = RightValue;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(TagName);
	
	// Font and text.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.Appearance.SetParameterValue("Font", Font);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", Char);
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(
		Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField(Var_AttributeName);
	FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = RightValue;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(TagName);
	
EndProcedure

&AtServer
Procedure FillRights()
	
	DirectRightsDependencies   = New Structure;
	ReverseRightsDependencies = New Structure;
	AvailableRights          = New Structure;
	
	AddedAttributes = New Structure;
	NewAttributes = New Array;
	AddAttributesOrFormItems(NewAttributes);
	
	// Adding form attributes.
	ChangeAttributes(NewAttributes);
	
	// Adding form items
	AddAttributesOrFormItems();
	
	ReadRights();
	
EndProcedure

&AtServer
Procedure ReadRights()
	
	RightsGroups.Clear();
	
	SetPrivilegedMode(True);
	RightsSettings = InformationRegisters.ObjectsRightsSettings.Read(Parameters.ObjectReference);
	
	InheritParentRights = RightsSettings.Inherit;
	
	For Each Setting In RightsSettings.Settings Do
		If InheritParentRights Or Not Setting.ParentSetting Then
			FillPropertyValues(RightsGroups.Add(), Setting);
		EndIf;
	EndDo;
	FillUserPictureNumbers();
	
	Modified = False;
	
EndProcedure

&AtServer
Procedure AddInheritedRights()
	
	SetPrivilegedMode(True);
	RightsSettings = InformationRegisters.ObjectsRightsSettings.Read(Parameters.ObjectReference);
	
	IndexOf = 0;
	For Each Setting In RightsSettings.Settings Do
		If Setting.ParentSetting Then
			FillPropertyValues(RightsGroups.Insert(IndexOf), Setting);
			IndexOf = IndexOf + 1;
		EndIf;
	EndDo;
	
	FillUserPictureNumbers();
	
EndProcedure

&AtClient
Procedure FillCheckProcessing(Cancel)
	
	ClearMessages();
	
	LineNumber = RightsGroups.Count()-1;
	
	While Not Cancel And LineNumber >= 0 Do
		CurrentRow = RightsGroups.Get(LineNumber);
		
		// Checking whether the rights check boxes are filled.
		NoFilledRight = True;
		FirstRightName = "";
		For Each AvailableRight In AvailableRights Do
			If Not ValueIsFilled(FirstRightName) Then
				FirstRightName = AvailableRight.Key;
			EndIf;
			If TypeOf(CurrentRow[AvailableRight.Key]) = Type("Boolean") Then
				NoFilledRight = False;
				Break;
			EndIf;
		EndDo;
		If NoFilledRight Then
			CommonClient.MessageToUser(
				NStr("vi = 'Chưa điền bất kỳ quyền truy cập nào.';
					|ru = 'Не заполнено ни одно право доступа.';
					|en = 'No access right specified.'; fa = 'No access right specified.';
					|it = 'Non è stato compilata nemmeno una regola d''accesso.';
					|pl = 'Nie wypełniono żadnego prawa dostępu.';
					|tr = 'Erişim hakkı belirlenmedi.'"),
				,
				"RightsGroups[" + Format(LineNumber, "NG=0") + "]." + FirstRightName,
				,
				Cancel);
			Return;
		EndIf;
		
		// Validate users and user groups, access values, and their duplicates.
		// 
		
		// Validate value population.
		If Not ValueIsFilled(CurrentRow["User"]) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Chưa điền người sử dụng hoặc nhóm.';
					|ru = 'Не заполнен пользователь или группа.';
					|en = 'A user or a group is required.'; fa = 'A user or a group is required.';
					|it = 'Non è compilato l''utente o il gruppo.';
					|pl = 'Nie wypełniono użytkownika lub grupy.';
					|tr = 'Kullanıcı veya grup girilmedi.'"),
				,
				"RightsGroups[" + Format(LineNumber, "NG=0") + "].User",
				,
				Cancel);
			Return;
		EndIf;
		
		// Check for duplicates.
		Filter = New Structure;
		Filter.Insert("SettingsOwner", CurrentRow["SettingsOwner"]);
		Filter.Insert("User",      CurrentRow["User"]);
		
		If RightsGroups.FindRows(Filter).Count() > 1 Then
			If TypeOf(Filter.User) = Type("CatalogRef.Users") Then
				MessageText = NStr("vi = 'Đã có tùy chỉnh cho người sử dụng ""%1"".';
									|ru = 'Настройка для пользователя ""%1"" уже есть.';
									|en = 'Access rights for user ""%1"" already exist.'; fa = 'Access rights for user ""%1"" already exist.';
									|it = 'La configurazione per l''utente ""%1"" è già esistente.';
									|pl = 'Ustawienia dla użytkownika ""%1"" już istnieją.';
									|tr = '""%1"" kullanıcı için ayarlar zaten var.'");
			Else
				MessageText = NStr("vi = 'Đã có tùy chỉnh cho nhóm người sử dụng ""%1"".';
									|ru = 'Настройка для группы пользователей ""%1"" уже есть.';
									|en = 'Access rights for user group ""%1"" already exist.'; fa = 'Access rights for user group ""%1"" already exist.';
									|it = 'La configurazione per il gruppo di utenti ""%1"" è già esistente.';
									|pl = 'Ustawienia dla grupy użytkowników ""%1"" już istnieją.';
									|tr = '""%1"" kullanıcı grubu için ayarlar zaten var.'");
			EndIf;
			CommonClient.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(MessageText, Filter.User),
				,
				"RightsGroups[" + Format(LineNumber, "NG=0") + "].User",
				,
				Cancel);
			Return;
		EndIf;
			
		LineNumber = LineNumber - 1;
	EndDo;
	
EndProcedure

&AtServer
Procedure WriteRights()
	
	ValidatePermissionToManageRights();
	
	BeginTransaction();
	Try
		SetPrivilegedMode(True);
		InformationRegisters.ObjectsRightsSettings.Write(Parameters.ObjectReference, RightsGroups, InheritParentRights);
		SetPrivilegedMode(False);
		
		If ConfirmRightsManagementCancellation = False
		 Or AccessManagement.HasRight("RightsManagement", Parameters.ObjectReference) Then
			
			Modified = False;
		Else
			ConfirmRightsManagementCancellation = True;
			Raise NStr("vi = 'sau khi ghi lại, sẽ không dùng được tùy chỉnh quyền.';
						|ru = 'После записи настройка прав станет недоступной.';
						|en = 'Once you save the access rights, you will not be able to change them.'; fa = 'Once you save the access rights, you will not be able to change them.';
						|it = 'Dopo la registrazione, l''impostazione dei diritti diventerà non disponibile.';
						|pl = 'Po zapisaniu ustawianie uprawnień będzie niemożliwe.';
						|tr = 'Yazdıktan sonra, erişim hakları atayamazsınız.'");
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	AccessManagementInternal.StartAccessUpdate();
	
EndProcedure

&AtClient
Procedure CheckOpportunityToChangeRights(Cancel, DeletionCheck = False)
	
	CurrentSettingOwner = Items.RightsGroups.CurrentData["SettingsOwner"];
	
	If ValueIsFilled(CurrentSettingOwner)
	   And CurrentSettingOwner <> Parameters.ObjectReference Then
		
		Cancel = True;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Các quyền này được kế thừa và có thể được thay đổi dưới dạng thiết lập các quyền 
			           |của thư mục mẹ ""%1"".';
			           |ru = 'Эти права унаследованы, их можно изменить в форме настройки прав
			           |вышестоящей папки ""%1"".';
			           |en = 'These access rights are inherited. Edit access rights
			           |of the parent folder: ""%1"".'; fa = 'These access rights are inherited. Edit access rights
			           |of the parent folder: ""%1"".';
			           |it = 'Questi diritti sono ereditati, è possibile modificarli nel form delle impostazioni
			           |della cartella di livello superiore ""%1"".';
			           |pl = 'Te uprawnienia zostały odziedziczone, można je zmienić w formularzu uprawnień
			           |folderu nadrzędnego ""%1"".';
			           |tr = 'Bu Yetkiler devralındı, 
			           |üst klasörün yetkileri%1şeklinde değiştirilebilirler.'"),
			CurrentSettingOwner);
		
		If DeletionCheck Then
			MessageText = MessageText + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để xóa tất cả các quyền được kế thừa,
				           |hãy bỏ dấu hộp kiểm ""%1"".';
				           |ru = 'Для удаления всех унаследованных прав
				           |снимите флажок ""%1"".';
				           |en = 'To delete all inherited access rights,
				           |clear the ""%1"" check box.'; fa = 'To delete all inherited access rights,
				           |clear the ""%1"" check box.';
				           |it = 'Per rimuovere tutti i diritti ereditati,
				           |rimuovere il contrassegno ""%1"".';
				           |pl = 'Aby usunąć wszystkie odziedziczone prawa należy
				           |odznaczyć pole wyboru ""%1"".';
				           |tr = 'Devralınan tüm yetkileri
				           | silmek için ""%1"" onay kutusunu temizleyin.'"),
				Items.InheritParentRights.Title);
		EndIf;
	EndIf;
	
	If Cancel Then
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GenerateUserSelectionData(Text)
	
	Return Users.GenerateUserSelectionData(Text);
	
EndFunction

&AtClient
Procedure ShowTypeSelectionUsersOrExternalUsers(ContinuationHandler)
	
	ExternalUsersSelectionAndPickup = False;
	
	If UseExternalUsers Then
		
		UserTypesList.ShowChooseItem(
			New CallbackDescription(
				"ShowTypeSelectionUsersOrExternalUsersCompletion",
				ThisObject,
				ContinuationHandler),
			NStr("vi = 'Chọn kiểu dữ liệu';
				|ru = 'Выбор типа данных';
				|en = 'Select data type'; fa = 'Select data type';
				|it = 'Scelta del tipo dati';
				|pl = 'Wybierz typ danych';
				|tr = 'Veri türünü seçin'"),
			UserTypesList[0]);
	Else
		RunCallback(ContinuationHandler, ExternalUsersSelectionAndPickup);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowTypeSelectionUsersOrExternalUsersCompletion(SelectedElement, ContinuationHandler) Export
	
	If SelectedElement <> Undefined Then
		ExternalUsersSelectionAndPickup =
			SelectedElement.Value = Type("CatalogRef.ExternalUsers");
		
		RunCallback(ContinuationHandler, ExternalUsersSelectionAndPickup);
	Else
		RunCallback(ContinuationHandler, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectUsers()
	
	CurrentUser = ?(Items.RightsGroups.CurrentData = Undefined,
		Undefined, Items.RightsGroups.CurrentData.User);
	
	If ValueIsFilled(CurrentUser)
	   And (    TypeOf(CurrentUser) = Type("CatalogRef.Users")
	      Or TypeOf(CurrentUser) = Type("CatalogRef.UserGroups") ) Then
		
		ExternalUsersSelectionAndPickup = False;
		
	ElsIf UseExternalUsers
	        And ValueIsFilled(CurrentUser)
	        And (    TypeOf(CurrentUser) = Type("CatalogRef.ExternalUsers")
	           Or TypeOf(CurrentUser) = Type("CatalogRef.ExternalUsersGroups") ) Then
	
		ExternalUsersSelectionAndPickup = True;
	Else
		ShowTypeSelectionUsersOrExternalUsers(
			New CallbackDescription("SelectUsersCompletion", ThisObject));
		Return;
	EndIf;
	
	SelectUsersCompletion(ExternalUsersSelectionAndPickup, Undefined);
	
EndProcedure

&AtClient
Procedure SelectUsersCompletion(ExternalUsersSelectionAndPickup, Context) Export
	
	If ExternalUsersSelectionAndPickup = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CurrentRow", ?(
		Items.RightsGroups.CurrentData = Undefined,
		Undefined,
		Items.RightsGroups.CurrentData.User));
	
	If ExternalUsersSelectionAndPickup Then
		FormParameters.Insert("SelectExternalUsersGroups", True);
	Else
		FormParameters.Insert("UsersGroupsSelection", True);
	EndIf;
	
	If ExternalUsersSelectionAndPickup Then
		
		OpenForm(
			"Catalog.ExternalUsers.ChoiceForm",
			FormParameters,
			Items.RightsGroupsUser);
	Else
		OpenForm(
			"Catalog.Users.ChoiceForm",
			FormParameters,
			Items.RightsGroupsUser);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillUserPictureNumbers(RowID = Undefined)
	
	Users.FillUserPictureNumbers(RightsGroups, "User", "PictureNumber", RowID);
	
EndProcedure

&AtServer
Procedure ValidatePermissionToManageRights()
	
	If AccessManagement.HasRight("RightsManagement", Parameters.ObjectReference) Then
		Return;
	EndIf;
	
	Raise NStr("vi = 'Không được phép tùy chỉnh quyền.';
				|ru = 'Настройка прав недоступна.';
				|en = 'You cannot change access rights.'; fa = 'You cannot change access rights.';
				|it = 'Configurazione dei diritti non disponibile.';
				|pl = 'Ustawienia praw są niedostępne.';
				|tr = 'Yetki ayarları mevcut değil.'");
	
EndProcedure

#EndRegion

#EndRegion