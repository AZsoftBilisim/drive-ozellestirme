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
	
	If ValueIsFilled(Parameters.PropertyKind) Then
		PropertyKind = Parameters.PropertyKind;
		Items.PropertyKind.Visible = False;
		If PropertyKind = Enums.PropertiesKinds.AdditionalAttributes Then
			Var_Key = "AdditionalAttributeSets";
		ElsIf PropertyKind = Enums.PropertiesKinds.AdditionalInfo Then
			Var_Key = "AdditionalDataSets";
		ElsIf PropertyKind = Enums.PropertiesKinds.Labels Then
			Var_Key = "LabelsSets";
		EndIf;
	Else
		PropertyKind = Enums.PropertiesKinds.AdditionalAttributes;
		Var_Key = "AdditionalAttributeSets";
	EndIf;
	StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, Var_Key);
	
	FormColor = Items.Properties.BackColor;
	
	ConfigureSetsDisplay();
	ApplySetsAndPropertiesAppearance();
	
	If Not Common.SubsystemExists("StandardSubsystems.DuplicateObjectsDetection") Then
		Items.DuplicateObjectsDetection.Visible = False;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.PropertiesSets.InitialTreeView = InitialTreeView.ExpandAllLevels;
		Items.PropertiesSets.TitleLocation         = FormItemTitleLocation.Top;
		Items.Properties.TitleLocation              = FormItemTitleLocation.Top;
		Items.PropertiesSubmenuAdd.Representation      = ButtonRepresentation.Picture;
	EndIf;
	
	CurrentLanguageSuffix = Common.CurrentUserLanguageSuffix();
	
	If CurrentLanguageSuffix = Undefined Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		
		ListProperties.QueryText = StrReplace(PropertiesSets.QueryText, "WHERE",
			"LEFT JOIN Catalog.AdditionalAttributesAndInfoSets.Presentations AS PresentationSets
			|ON (PresentationSets.Ref = SetsOverridable.Ref)
			|AND (PresentationSets.LanguageCode = &LanguageCode)
			|WHERE");
			
		ListProperties.QueryText = StrReplace(ListProperties.QueryText, "SetsOverridable.Description AS Description",
			"SetsOverridable.Description AS Description, PresentationSets.Description AS DescriptionInOtherLanguages");
		
		Common.SetDynamicListProperties(Items.PropertiesSets, ListProperties);
		
		CommonClientServer.SetDynamicListParameter(
			PropertiesSets, "LanguageCode", CurrentLanguage().LanguageCode, True);
		
	ElsIf ValueIsFilled(CurrentLanguageSuffix) Then
		
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
			ModuleNationalLanguageSupportServer.OnCreateAtServer(ThisObject,, "PropertiesSets");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_AdditionalAttributesAndInfo"
	 Or EventName = "Write_ObjectsPropertiesValues"
	 Or EventName = "Write_ObjectPropertyValueHierarchy" Then
		
		// When writing a property, move it to the matching group.
		// When writing a value, update the first 3 values in the list.
		OnChangeCurrentSetAtServer();
		
	ElsIf EventName = "GoAdditionalDataAndAttributeSets" Then
		// When opening a metadata object property editor, open the object's set (group of sets).
		// 
		If TypeOf(Parameter) = Type("Structure") Then
			SelectSpecifiedRows(Parameter);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PropertyKindOnChange(Item)
	
	ConfigureSetsDisplay();
	ApplySetsAndPropertiesAppearance();
	
EndProcedure

&AtClient
Procedure ShowUnusedAttributesOnChange(Item)
	SwitchSetsList();
	OnChangeCurrentSet();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPropertiesSets

&AtClient
Procedure PropertiesSetsOnActivateRow(Item)
	
	AttachIdleHandler("OnChangeCurrentSet", 0.1, True);
	
EndProcedure

&AtClient
Procedure PropertiesSetsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesSetsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
	
	If String = Undefined Then
		Return;
	EndIf;
	
	If Items.PropertiesSets.RowData(String).IsFolder Then
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertiesSetsDrag(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
	
	If DragParameters.Value.CommonValues Then
		ItemToDrag = DragParameters.Value.AdditionalValuesOwner;
	Else
		ItemToDrag = DragParameters.Value.Property;
	EndIf;
	
	If TypeOf(ItemToDrag) <> Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo") Then
		Return;
	EndIf;
	
	DestinationSet = String;
	AddAttributeToSet(ItemToDrag, String);
EndProcedure

&AtServerNoContext
Procedure PropertiesSetsOnGetDataAtServer(TagName, Settings, Rows)
	
	For Each DynamicListRow In Rows Do
		Data = DynamicListRow.Value.Data;
		If Data.IsFolder Then
			Data.Presentation = String(Data.Ref);
			Continue;
		EndIf;
		
		If Data.PropertyKind = Enums.PropertiesKinds.AdditionalInfo Then
			If Not ValueIsFilled(Data.InfoCount) Then
				Data.Presentation = String(Data.Ref);
				Continue;
			EndIf;
			If Data.Property("DescriptionInOtherLanguages") And ValueIsFilled(Data.DescriptionInOtherLanguages) Then
				Data.Presentation = Data.DescriptionInOtherLanguages + " (" + Data.InfoCount + ")";
				Continue;
			EndIf;
			Data.Presentation = String(Data.Ref) + " (" + Data.InfoCount + ")";
		ElsIf Data.PropertyKind = Enums.PropertiesKinds.AdditionalAttributes Then
			If Not ValueIsFilled(Data.AttributesCount) Then
				Data.Presentation = String(Data.Ref);
				Continue;
			EndIf;
			If Data.Property("DescriptionInOtherLanguages") And ValueIsFilled(Data.DescriptionInOtherLanguages) Then 
				Data.Presentation = Data.DescriptionInOtherLanguages + " (" + Data.AttributesCount + ")";
				Continue;
			EndIf;
			Data.Presentation = String(Data.Ref) + " (" + Data.AttributesCount + ")";
		ElsIf Data.PropertyKind = Enums.PropertiesKinds.Labels Then
			If Not ValueIsFilled(Data.LabelCount) Then
				Data.Presentation = String(Data.Ref);
				Continue;
			EndIf;
			If Data.Property("DescriptionInOtherLanguages") And ValueIsFilled(Data.DescriptionInOtherLanguages) Then 
				Data.Presentation = Data.DescriptionInOtherLanguages + " (" + Data.AttributesCount + ")";
				Continue;
			EndIf;
			Data.Presentation = String(Data.Ref) + " (" + Data.LabelCount + ")";
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProperties

&AtClient
Procedure PropertiesOnActivateRow(Item)
	
	PropertiesSetCommandAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure PropertiesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Copy Then
		Copy();
	Else
		Create();
	EndIf;
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesBeforeRowChange(Item, Cancel)
	
	Change();
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesBeforeDeleteRow(Item, Cancel)
	
	ChangeDeletionMark();
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure PropertiesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		If ValueSelected.Property("AdditionalValuesOwner") Then
			
			FormParameters = New Structure;
			FormParameters.Insert("PropertyKind1", PropertyKind);
			FormParameters.Insert("CurrentPropertiesSet",            Current_Set);
			FormParameters.Insert("AdditionalValuesOwner", ValueSelected.AdditionalValuesOwner);
			
			OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
				FormParameters, Items.Properties);
			
		ElsIf ValueSelected.Property("CommonProperty") Then
			
			ChangedSet = Current_Set;
			If ValueSelected.Property("Drag") Then
				AddCommonPropertyByDragging(ValueSelected.CommonProperty);
			Else
				ExecuteCommandAtServer("AddCommonProperty", ValueSelected.CommonProperty);
				ChangedSet = DestinationSet;
			EndIf;
			
			Notify("Write_AdditionalAttributesAndInfoSets",
				New Structure("Ref", ChangedSet), ChangedSet);
		Else
			SelectSpecifiedRows(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertiesDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PropertiesDragStart(Item, DragParameters, Perform)
	// Properties and attributes cannot be moved, only copied.
	// Make sure the cursor icon reflects this.
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Action           = DragAction.Copy;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Create(Command = Undefined)
	
	FormParameters = New Structure;
	FormParameters.Insert("PropertiesSet", Current_Set);
	FormParameters.Insert("PropertyKind1", PropertyKind);
	FormParameters.Insert("CurrentPropertiesSet", Current_Set);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
		FormParameters, Items.Properties);
	
EndProcedure

&AtClient
Procedure AddFromSet(Command)
	
	FormParameters = New Structure;
	
	SelectedValues = New Array;
	CommonProperties = Properties.FindRows(New Structure("Common", True));
	For Each Property In CommonProperties Do
		SelectedValues.Add(Property.Property);
	EndDo;
	
	If Not ValueIsFilled(PropertyKind) Then
		FormParameters.Insert("SelectSharedProperty", True);
	Else
		FormParameters.Insert("SelectAdditionalValuesOwner", True);
	EndIf;
	
	FormParameters.Insert("SelectedValues", SelectedValues);
	FormParameters.Insert("PropertyKind1", PropertyKind);
	FormParameters.Insert("CurrentPropertiesSet", Current_Set);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
		FormParameters, Items.Properties);
EndProcedure

&AtClient
Procedure Change(Command = Undefined)
	
	If Items.Properties.CurrentData <> Undefined Then
		// Open the property form.
		FormParameters = New Structure;
		FormParameters.Insert("Key", Items.Properties.CurrentData.Property);
		FormParameters.Insert("CurrentPropertiesSet", Current_Set);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
			FormParameters, Items.Properties);
	EndIf;
	
EndProcedure

&AtClient
Procedure Copy(Command = Undefined, PasteFromClipboard2 = False)
	
	FormParameters = New Structure;
	CopyingValue = Items.Properties.CurrentData.Property;
	FormParameters.Insert("AdditionalValuesOwner", CopyingValue);
	FormParameters.Insert("CurrentPropertiesSet", Current_Set);
	FormParameters.Insert("CopyingValue", CopyingValue);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure AddAttributeToSet(AdditionalValuesOwner, Set = Undefined)
	
	FormParameters = New Structure;
	If Set = Undefined Then
		CurrentPropertiesSet = Current_Set;
	Else
		CurrentPropertiesSet = Set;
		FormParameters.Insert("Drag", True);
	EndIf;
	
	FormParameters.Insert("CopyWithQuestion", True);
	FormParameters.Insert("AdditionalValuesOwner", AdditionalValuesOwner);
	FormParameters.Insert("PropertyKind1", PropertyKind);
	FormParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm", FormParameters, Items.Properties);
	
EndProcedure

&AtClient
Procedure MarkToDelete(Command)
	
	ChangeDeletionMark();
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	ExecuteCommandAtServer("MoveUp");
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	ExecuteCommandAtServer("MoveDown");
	
EndProcedure

&AtClient
Procedure DuplicateObjectsDetection(Command)
	ModuleDuplicateObjectsDetectionClient = CommonClient.CommonModule("DuplicateObjectsDetectionClient");
	DuplicateObjectsDetectionFormName = ModuleDuplicateObjectsDetectionClient.DuplicateObjectsDetectionDataProcessorFormName();
	OpenForm(DuplicateObjectsDetectionFormName);
EndProcedure

&AtClient
Procedure CopySelectedAttribute(Command)
	AttributeToCopy = New Structure;
	AttributeToCopy.Insert("AttributeToCopy", Items.Properties.CurrentData.Property);
	AttributeToCopy.Insert("CommonValues", Items.Properties.CurrentData.CommonValues);
	AttributeToCopy.Insert("AdditionalValuesOwner", Items.Properties.CurrentData.AdditionalValuesOwner);
	
	Items.PasteAttribute.Enabled = Not ShowUnusedAttributes;
EndProcedure

&AtClient
Procedure PasteAttribute(Command)
	If AttributeToCopy.CommonValues Then
		AdditionalValuesOwner = AttributeToCopy.AdditionalValuesOwner;
	Else
		AdditionalValuesOwner = AttributeToCopy.AttributeToCopy;
	EndIf;
	
	AddAttributeToSet(AdditionalValuesOwner);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ApplySetsAndPropertiesAppearance()
	
	PropertiesSets.ConditionalAppearance.Items.Clear();
	
	// Appearance of the sets root.
	ConditionalAppearanceItem = PropertiesSets.ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	AppearanceColorItem.Value = NStr("vi = 'Tập hợp';
									|ru = 'Наборы';
									|en = 'Sets'; fa = 'مجموعه‌ها';
									|it = 'Set';
									|pl = 'Sets';
									|tr = 'Kümeler'");
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotFilled;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("Presentation");
	AppearanceFieldItem.Use = True;
	
	// Appearance of unavailable set groups that by default are displayed by the platform as a part of group tree.
	ConditionalAppearanceItem = PropertiesSets.ConditionalAppearance.Items.Add();
	
	VisibilityItem = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	VisibilityItem.Value = False;
	VisibilityItem.Use = True;
	
	DataFilterItemsGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	DataFilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	DataFilterItemsGroup.Use = True;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotInList;
	DataFilterItem.RightValue = AvailableSetsList;
	DataFilterItem.Use  = True;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Parent");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotInList;
	DataFilterItem.RightValue = AvailableSetsList;
	DataFilterItem.Use  = True;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Filled;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("Presentation");
	AppearanceFieldItem.Use = True;
	
	ConditionalAppearance.Items.Clear();
	
	// Configuring required properties.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Font");
	AppearanceColorItem.Value = StyleFonts.MainListItem;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Properties.RequiredToFill");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("PropertiesTitle");
	AppearanceFieldItem.Use = True;
	
	// Configuring required properties.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	VisibilityItem = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	VisibilityItem.Value = False;
	VisibilityItem.Use = True; 
	
	DataFilterItemsGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	DataFilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	DataFilterItemsGroup.Use = True;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("FieldForSearch");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Filled;
	DataFilterItem.Use  = True;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("PropertiesSets.Presentation");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotContains;
	DataFilterItem.RightValue = New DataCompositionField("FieldForSearch");
	DataFilterItem.Use  = True; 
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("Presentation");
	AppearanceFieldItem.Use = True;
	
EndProcedure

&AtClient
Procedure SelectSpecifiedRows(LongDesc)
	
	If LongDesc.Property("Set") Then
		
		If TypeOf(LongDesc.Set) = Type("String") Then
			ConvertStringsToReferences(LongDesc);
		EndIf;
		
		If LongDesc.PropertyKind1 <> PropertyKind Then
			PropertyKind = LongDesc.PropertyKind1;
			ConfigureSetsDisplay();
		EndIf;
		
		Items.PropertiesSets.CurrentRow = LongDesc.Set;
		Current_Set = Undefined;
		OnChangeCurrentSet();
		FoundRows = Properties.FindRows(New Structure("Property", LongDesc.Property));
		If FoundRows.Count() > 0 Then
			Items.Properties.CurrentRow = FoundRows[0].GetID();
		Else
			Items.Properties.CurrentRow = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SwitchSetsList()
	
	If Not ShowUnusedAttributes Then
		Items.SetsPages.CurrentPage = Items.Main;
		Return;
	EndIf;
	
	Items.SetsPages.CurrentPage = Items.Unused;
	
	ListPresentation = "";
	If PropertyKind = PredefinedValue("Enum.PropertiesKinds.AdditionalInfo") Then
		ListPresentation = NStr("vi = 'Thông tin bổ sung không sử dụng';
								|ru = 'Неиспользуемые дополнительные сведения';
								|en = 'Unused additional information records'; fa = 'Unused additional information records';
								|it = 'Informazioni aggiuntive non in uso';
								|pl = 'Nieużywane informacje dodatkowe';
								|tr = 'Kullanılmayan ek bilgiler'");
	ElsIf PropertyKind = PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes") Then
		ListPresentation = NStr("vi = 'Mục tin bổ sung không sử dụng';
								|ru = 'Неиспользуемые дополнительные реквизиты';
								|en = 'Unused additional attributes'; fa = 'Unused additional attributes';
								|it = 'Requisiti aggiuntivi non in uso';
								|pl = 'Nieużywane dodatkowe atrybuty';
								|tr = 'Kullanılmayan ek öznitelikler'");
	ElsIf PropertyKind = PredefinedValue("Enum.PropertiesKinds.Labels") Then
		ListPresentation = NStr("vi = 'Nhãn đánh dấu không sử dụng';
								|ru = 'Неиспользуемые метки';
								|en = 'Unused labels'; fa = 'Unused labels';
								|it = 'Неиспользуемые метки';
								|pl = 'Unused labels';
								|tr = 'Kullanılmayan etiketler'");
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		UnusedSets, "ListPresentation", ListPresentation, True);
	
EndProcedure

&AtServerNoContext
Procedure ConvertStringsToReferences(LongDesc)
	
	LongDesc.Insert("Set", Catalogs.AdditionalAttributesAndInfoSets.GetRef(
		New UUID(LongDesc.Set)));
	
	LongDesc.Insert("Property", ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.GetRef(
		New UUID(LongDesc.Property)));
	
EndProcedure

&AtServer
Procedure ConfigureSetsDisplay()
	
	CreateButton            = Items.PropertiesCreate;
	ButtonCreateContext = Items.PropertiesContextMenuCreate;
	CreateCommand                      = Commands.Find("Create");
	CopyCommand                  = Commands.Find("Copy");
	ChangeCommand                     = Commands.Find("Change");
	MarkForDeletionCommand           = Commands.Find("MarkToDelete");
	MoveUpCommand             = Commands.Find("MoveUp");
	MoveDownCommand              = Commands.Find("MoveDown");
	
	If PropertyKind = Enums.PropertiesKinds.AdditionalInfo Then
		Title = NStr("vi = 'Thông tin bổ sung';
					|ru = 'Дополнительные сведения';
					|en = 'Additional information records'; fa = 'رکوردهای اطلاعات تکمیلی';
					|it = 'Informazioni aggiuntive';
					|pl = 'Dodatkowego informacje';
					|tr = 'Ek bilgi'");
		
		CreateButton.Title          = NStr("vi = 'Mới';
											|ru = 'Новый';
											|en = 'New item'; fa = 'قلم جدید';
											|it = 'Новый';
											|pl = 'New item';
											|tr = 'Yeni'");
		ButtonCreateContext.Title = NStr("vi = 'Mới';
										|ru = 'Новый';
										|en = 'New item'; fa = 'قلم جدید';
										|it = 'Новый';
										|pl = 'New item';
										|tr = 'Yeni'");
		CreateCommand.ToolTip         = NStr("vi = 'Tạo thông tin đơn trị';
											|ru = 'Создать уникальное сведение';
											|en = 'Create a unique information record.'; fa = 'Create a unique information record.';
											|it = 'Creare un''informazione unica';
											|pl = 'Utwórz unikalną informację';
											|tr = 'Benzersiz bilgi oluştur'");
		
		CopyCommand.ToolTip        = NStr("vi = 'Tạo mới thông tin bằng cách sao chép thông tin hiện tại';
											|ru = 'Создать новое сведение копированием текущего';
											|en = 'Create an information record by copying the current one.'; fa = 'Create an information record by copying the current one.';
											|it = 'Creare una nuova informazione copiando quella corrente';
											|pl = 'Utwórz nową informację poprzez kopiowanie bieżącej';
											|tr = 'Geçerli olanı kopyalayarak yeni bir bilgi oluştur'");
		ChangeCommand.ToolTip           = NStr("vi = 'Thay đổi (hoặc mở) thông tin hiện tại';
												|ru = 'Изменить (или открыть) текущее сведение';
												|en = 'Change or open the information record.'; fa = 'Change or open the information record.';
												|it = 'Modificare (o aprire) l''informazione corrente';
												|pl = 'Zmień (lub otwórz) bieżącą informację';
												|tr = 'Mevcut bilgiyi düzenle veya aç'");
		MarkForDeletionCommand.ToolTip = NStr("vi = 'Đánh dấu xóa thông tin hiện tại (Del)';
												|ru = 'Пометить текущее сведение на удаление (Del)';
												|en = 'Mark the information record for deletion (Del).'; fa = 'Mark the information record for deletion (Del).';
												|it = 'Contrassegnare l''informazione corrente per la cancellazione (Del)';
												|pl = 'Zaznacz bieżącą informację do usunięcia (Del)';
												|tr = 'Silinmek için geçerli bilgiyi işaretle (Del)'");
		MoveUpCommand.ToolTip   = NStr("vi = 'Chuyển thông tin hiện tại lên trên';
										|ru = 'Переместить текущее сведение вверх';
										|en = 'Move the information record up the list.'; fa = 'Move the information record up the list.';
										|it = 'Spostare l''informazione corrente in alto';
										|pl = 'Przemieść bieżącą informację do góry';
										|tr = 'Geçerli bilgiyi yukarı taşı'");
		MoveDownCommand.ToolTip    = NStr("vi = 'Chuyển thông tin hiện tại xuống dưới';
											|ru = 'Переместить текущее сведение вниз';
											|en = 'Move the information record down the list.'; fa = 'Move the information record down the list.';
											|it = 'Spostare l''informazione corrente in basso';
											|pl = 'Przemieść bieżącą informację w dół';
											|tr = 'Geçerli bilgiyi aşağı taşı'");
		
		MetadataTabularSection =
			Metadata.Catalogs.AdditionalAttributesAndInfoSets.TabularSections.AdditionalInfo;
		
		Items.PropertiesTitle.ToolTip = MetadataTabularSection.Attributes.Property.Tooltip;
		
		Items.PropertiesRequiredToFill.Visible = False;
		
		Items.PropertiesValueType.ToolTip =
			NStr("vi = 'Kiểu giá trị mà có thể nhập khi điền thông tin.';
				|ru = 'Типы значения, которое можно ввести при заполнении сведения.';
				|en = 'Available information record value types.'; fa = 'Available information record value types.';
				|it = 'Tipi del valore, che può essere immesso durante la compilazione dell''informazione.';
				|pl = 'Typy wartości, które można wprowadzić przy wypełnianiu informacji.';
				|tr = 'Bilginin doldurulmasında girilebilecek değer türleri.'");
		
		Items.PropertiesCommonValues.ToolTip =
			NStr("vi = 'Thông tin sử dụng danh sách giá trị thông tin mẫu';
				|ru = 'Сведение использует список значений сведения-образца.';
				|en = 'The information record inherits the master record''s list of values.'; fa = 'The information record inherits the master record''s list of values.';
				|it = 'L''informazione utilizza un elenco di valori dell''informazione-modello.';
				|pl = 'Informacja wykorzystuje listę wartości wzorcowej.';
				|tr = 'Bilgi, değerlerin örnek listesini kullanır.'");
		
		Items.ShowUnusedAttributes.Title = NStr("vi = 'Hiển thị thông tin không sử dụng';
												|ru = 'Показать неиспользуемые сведения';
												|en = 'Show unused information records'; fa = 'Show unused information records';
												|it = 'Mostra informazioni non in uso';
												|pl = 'Pokaż nieużywane dane';
												|tr = 'Kullanılmayan bilgileri göster'");
		
		Items.PropertiesCommon.Title = NStr("vi = 'Chung';
											|ru = 'Общий';
											|en = 'Shared'; fa = 'اشتراکی';
											|it = 'Generale';
											|pl = 'Shared';
											|tr = 'Ortak'");
		Items.PropertiesCommon.ToolTip = NStr("vi = 'Thông tin bổ sung chung
		                                              | được sử dụng trong một số tập hợp thông tin bổ sung.';
		                                              |ru = 'Общее дополнительное сведение, которое используется в
		                                              |нескольких наборах дополнительных сведений.';
		                                              |en = 'A shared additional information record.
		                                              |It belongs to multiple sets.'; fa = 'A shared additional information record.
		                                              |It belongs to multiple sets.';
		                                              |it = 'Informazione aggiuntiva generale che viene usata in
		                                              |alcuni insiemi di informazioni aggiuntive.';
		                                              |pl = 'Wspólna informacja dodatkowa, która jest wykorzystywana w
		                                              |kilku zestawach informacji dodatkowych.';
		                                              |tr = 'Birkaç ek veri kümesinde kullanılan 
		                                              |ortak özel veriler.'");
	ElsIf PropertyKind = Enums.PropertiesKinds.Labels Then
		Title = NStr("vi = 'Đánh dấu';
					|ru = 'Метки';
					|en = 'Labels'; fa = 'برچسب‌ها';
					|it = 'Метки';
					|pl = 'Labels';
					|tr = 'Etiketler'");
		CreateButton.Title            = NStr("vi = 'Mới';
											|ru = 'Новый';
											|en = 'New item'; fa = 'قلم جدید';
											|it = 'Новый';
											|pl = 'New item';
											|tr = 'Yeni'");
		ButtonCreateContext.Title = NStr("vi = 'Mới';
										|ru = 'Новый';
										|en = 'New item'; fa = 'قلم جدید';
										|it = 'Новый';
										|pl = 'New item';
										|tr = 'Yeni'");
		CreateCommand.ToolTip          = NStr("vi = 'Tạo nhãn đánh dấu duy nhất';
												|ru = 'Создать уникальную метку';
												|en = 'Create a unique label'; fa = 'Create a unique label';
												|it = 'Создать уникальную метку';
												|pl = 'Create a unique label';
												|tr = 'Benzersiz etiket oluştur'");
		
		CopyCommand.ToolTip        = NStr("vi = 'Tạo nhãn đánh dấu mới bằng cách sao chép nhãn hiện tại';
											|ru = 'Создать новую метку копированием текущей';
											|en = 'Create a new label by copying the current label'; fa = 'Create a new label by copying the current label';
											|it = 'Создать новую метку копированием текущей';
											|pl = 'Create a new label by copying the current label';
											|tr = 'Mevcut etiketi kopyalayarak yeni bir etiket oluştur'");
		ChangeCommand.ToolTip           = NStr("vi = 'Thay đổi (hoặc mở) nhãn đánh dấu hiện tại';
												|ru = 'Изменить (или открыть) текущую метку';
												|en = 'Edit or open the current label'; fa = 'Edit or open the current label';
												|it = 'Изменить (или открыть) текущую метку';
												|pl = 'Edit or open the current label';
												|tr = 'Mevcut etiketi değiştir (veya aç)'");
		MarkForDeletionCommand.ToolTip = NStr("vi = 'Đặt dấu xóa nhãn đánh dấu hiện tại (Del)';
												|ru = 'Пометить текущую метку на удаление (Del)';
												|en = 'Mark the current label for deletion (Del)'; fa = 'Mark the current label for deletion (Del)';
												|it = 'Пометить текущую метку на удаление (Del)';
												|pl = 'Mark the current label for deletion (Del)';
												|tr = 'Mevcut etiketi silmek üzere işaretle (Del)'");
		MoveUpCommand.ToolTip   = NStr("vi = 'Chuyển nhãn đánh dấu lên trên';
										|ru = 'Переместить текущую метку вверх';
										|en = 'Move the current label up'; fa = 'Move the current label up';
										|it = 'Переместить текущую метку вверх';
										|pl = 'Move the current label up';
										|tr = 'Mevcut etiketi yukarı taşı'");
		MoveDownCommand.ToolTip    = NStr("vi = 'Chuyển nhãn đánh dấu xuống dưới';
											|ru = 'Переместить текущую метку вниз';
											|en = 'Move the current label down'; fa = 'Move the current label down';
											|it = 'Переместить текущую метку вниз';
											|pl = 'Move the current label down';
											|tr = 'Mevcut etiketi aşağı taşı'");
		
		MetadataTabularSection =
			Metadata.Catalogs.AdditionalAttributesAndInfoSets.TabularSections.AdditionalAttributes;
		
		Items.PropertiesTitle.ToolTip = MetadataTabularSection.Attributes.Property.Tooltip;
		
		Items.PropertiesRequiredToFill.Visible = True;
		Items.PropertiesRequiredToFill.ToolTip =
			Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.Attributes.RequiredToFill.Tooltip;
		
		Items.PropertiesValueType.ToolTip =
			NStr("vi = 'Kiểu giá trị mà có thể nhập khi điền nhãn đánh dấu.';
				|ru = 'Типы значения, которое можно ввести при заполнении метки.';
				|en = 'Types of a value that you can enter when filling a label.'; fa = 'Types of a value that you can enter when filling a label.';
				|it = 'Типы значения, которое можно ввести при заполнении метки.';
				|pl = 'Types of a value that you can enter when filling a label.';
				|tr = 'Etiketi doldururken girilebilecek değer tipleri.'");
		
		Items.PropertiesCommonValues.ToolTip =
			NStr("vi = 'Nhãn đánh dấu sử dụng danh sách giá trị nhãn đánh dấu mẫu.';
				|ru = 'Метка использует список значений метки-образца.';
				|en = 'The label uses the list of master label values.'; fa = 'The label uses the list of master label values.';
				|it = 'Метка использует список значений метки-образца.';
				|pl = 'The label uses the list of master label values.';
				|tr = 'Etiket, örnek etiket değerlerinin listesini kullanır.'");
		
		Items.ShowUnusedAttributes.Title = NStr("vi = 'Hiển thị nhãn đánh dấu không sử dụng';
												|ru = 'Показать неиспользуемые метки';
												|en = 'Show unused labels'; fa = 'Show unused labels';
												|it = 'Показать неиспользуемые метки';
												|pl = 'Show unused labels';
												|tr = 'Kullanılmayan etiketleri göster'");
		
		Items.PropertiesCommon.Title = NStr("vi = 'Chung';
											|ru = 'Общая';
											|en = 'Common'; fa = 'مشترک';
											|it = 'Общая';
											|pl = 'Common';
											|tr = 'Ortak'");
		Items.PropertiesCommon.ToolTip = NStr("vi = 'Nhãn chung được dùng trong
		                                              |nhiều tập hợp nhãn đánh dấu.';
		                                              |ru = 'Общая метка, которая используется в
		                                              |нескольких наборах меток.';
		                                              |en = 'A common label that is used in
		                                              |several label sets.'; fa = 'A common label that is used in
		                                              |several label sets.';
		                                              |it = 'Общая метка, которая используется в
		                                              |нескольких наборах меток.';
		                                              |pl = 'A common label that is used in
		                                              |several label sets.';
		                                              |tr = 'Birden fazla etiket kümesinde
		                                              |kullanılan ortak etiket.'");
		Items.Properties.Header = False;
		Items.PropertiesValueType.Visible = False;
	Else
		Title = NStr("vi = 'Mục tin bổ sung';
					|ru = 'Дополнительные реквизиты';
					|en = 'Additional attributes'; fa = 'ویژگی‌های تکمیلی';
					|it = 'Requisiti aggiuntivi';
					|pl = 'Atrybuty dodatkowe';
					|tr = 'Ek öznitelikler'");
		CreateButton.Title            = NStr("vi = 'Mới';
											|ru = 'Новый';
											|en = 'New item'; fa = 'قلم جدید';
											|it = 'Новый';
											|pl = 'New item';
											|tr = 'Yeni'");
		ButtonCreateContext.Title = NStr("vi = 'Mới';
										|ru = 'Новый';
										|en = 'New item'; fa = 'قلم جدید';
										|it = 'Новый';
										|pl = 'New item';
										|tr = 'Yeni'");
		CreateCommand.ToolTip          = NStr("vi = 'Tạo mục tin đơn trị';
												|ru = 'Создать уникальный реквизит';
												|en = 'Create a unique attribute.'; fa = 'ایجاد ویژگی یکتا.';
												|it = 'Crea requisito unico';
												|pl = 'Utwórz unikalny atrybut';
												|tr = 'Benzersiz öznitelik oluştur'");
		
		CopyCommand.ToolTip        = NStr("vi = 'Tạo mục tin mới bằng cách sao chép mục tin hiện tại';
											|ru = 'Создать новый реквизит копированием текущего';
											|en = 'Create an attribute by copying the current one.'; fa = 'Create an attribute by copying the current one.';
											|it = 'Creare un requisito unico copiando quello attuale';
											|pl = 'Utwórz nowy atrybut poprzez kopiowanie bieżącego';
											|tr = 'Mevcut olanı kopyalayarak yeni bir öznitelik oluştur'");
		ChangeCommand.ToolTip           = NStr("vi = 'Thay đổi (hoặc mở) mục tin hiện tại';
												|ru = 'Изменить (или открыть) текущий реквизит';
												|en = 'Change or open the attribute.'; fa = 'Change or open the attribute.';
												|it = 'Modificare (o aprire) il requisito corrente';
												|pl = 'Zmień (lub otwórz) bieżący atrybut';
												|tr = 'Mevcut özniteliği düzenle (veya aç)'");
		MarkForDeletionCommand.ToolTip = NStr("vi = 'Đánh dấu xóa mục tin hiện tại (Del)';
												|ru = 'Пометить текущий реквизит на удаление (Del)';
												|en = 'Mark the attribute for deletion (Del).'; fa = 'Mark the attribute for deletion (Del).';
												|it = 'Contrassegnare il requisito corrente per la cancellazione (Del)';
												|pl = 'Zaznacz bieżący atrybut do usunięcia (Del)';
												|tr = 'Mevcut özniteliği silinmek üzere işaretle (Sil)'");
		MoveUpCommand.ToolTip   = NStr("vi = 'Chuyển mục tin hiện tại lên trên';
										|ru = 'Переместить текущий реквизит вверх';
										|en = 'Move the attribute up the list.'; fa = 'انتقال ویژگی به بالای فهرست.';
										|it = 'Spostare il requisito corrente in alto';
										|pl = 'Przemieść bieżący atrybut do góry';
										|tr = 'Mevcut özniteliği yukarı taşı'");
		MoveDownCommand.ToolTip    = NStr("vi = 'Chuyển mục tin hiện tại xuống dưới';
											|ru = 'Переместить текущий реквизит вниз';
											|en = 'Move the attribute down the list.'; fa = 'انتقال ویژگی به پایین فهرست.';
											|it = 'Spostare il requisito corrente in basso';
											|pl = 'Przemieść bieżący atrybut w dół';
											|tr = 'Mevcut özniteliği aşağı taşı'");
		
		MetadataTabularSection =
			Metadata.Catalogs.AdditionalAttributesAndInfoSets.TabularSections.AdditionalAttributes;
		
		Items.PropertiesTitle.ToolTip = MetadataTabularSection.Attributes.Property.Tooltip;
		
		Items.PropertiesRequiredToFill.Visible = True;
		Items.PropertiesRequiredToFill.ToolTip =
			Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.Attributes.RequiredToFill.Tooltip;
		
		Items.PropertiesValueType.ToolTip =
			NStr("vi = 'Kiểu giá trị mà có thể nhập khi điền mục tin.';
				|ru = 'Типы значения, которое можно ввести при заполнении реквизита.';
				|en = 'Available attribute value types.'; fa = 'انواع مقدار ویژگی در دسترس.';
				|it = 'Tipi del valore, che può essere immesso durante la compilazione del requisito.';
				|pl = 'Typy wartości, które można wprowadzić przy wypełnianiu atrybutu.';
				|tr = 'Özniteliğin doldurulmasında girilebilecek değer türleri.'");
		
		Items.PropertiesCommonValues.ToolTip =
			NStr("vi = 'Mục tin sử dụng danh sách giá trị của mục tin mẫu.';
				|ru = 'Реквизит использует список значений реквизита-образца.';
				|en = 'The attribute inherits the master attribute''s list of values.'; fa = 'ویژگی فهرست مقادیر ویژگی اصلی را به ارث می‌برد.';
				|it = 'Il requisito utilizza un elenco di valori del requisito-modello.';
				|pl = 'Atrybut wykorzystuje listę wartości wzorcowej.';
				|tr = 'Özellik, öznitelik-örnek değer listesini kullanır.'");
		
		Items.ShowUnusedAttributes.Title = NStr("vi = 'Hiển thị mục tin không sử dụng';
												|ru = 'Показать неиспользуемые реквизиты';
												|en = 'Show unused attributes'; fa = 'نمایش ویژگی‌های استفاده‌نشده';
												|it = 'Mostra i requisiti non in uso';
												|pl = 'Pokaż nieużywane atrybuty';
												|tr = 'Kullanılmayan öznitelikleri göster'");
		
		Items.PropertiesCommon.Title = NStr("vi = 'Chung';
											|ru = 'Общий';
											|en = 'Shared'; fa = 'اشتراکی';
											|it = 'Generale';
											|pl = 'Shared';
											|tr = 'Ortak'");
		Items.PropertiesCommon.ToolTip = NStr("vi = 'Mục tin bổ sung chung, được sử dụng trong 
		                                              |một số tập hợp mục tin bổ sung.';
		                                              |ru = 'Общий дополнительный реквизит, который используется в
		                                              |нескольких наборах дополнительных реквизитов.';
		                                              |en = 'A shared additional attribute.
		                                              |It belongs to multiple sets.'; fa = 'A shared additional attribute.
		                                              |It belongs to multiple sets.';
		                                              |it = 'Requisito aggiuntivo generale che viene usato in
		                                              |alcuni insiemi di requisiti aggiuntivi.';
		                                              |pl = 'Wspólny atrybut dodatkowy, który jest wykorzystywany w
		                                              |kilku zestawach atrybutów dodatkowych.';
		                                              |tr = 'Birden fazla ek öznitelik kümesinde kullanılan
		                                              |ortak ek öznitelik.'");
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Sets.Ref AS Ref,
	|	Sets.DeletionMark AS DeletionMark,
	|	Sets.Predefined AS Predefined,
	|	Sets.IsFolder AS IsFolder,
	|	Sets.Parent AS Parent,
	|	Sets.PredefinedDataName AS PredefinedDataName,
	|	Sets.PredefinedSetName AS PredefinedSetName
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets AS Sets
	|WHERE
	|	Sets.Parent = VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef)";
	
	Sets = Query.Execute().Unload();
	AvailableSets = New Array;
	AvailableSetsList.Clear();
	
	SetProperties = New Structure;
	SetProperties.Insert("DeletionMark");
	SetProperties.Insert("Predefined");
	SetProperties.Insert("IsFolder");
	SetProperties.Insert("Parent");
	SetProperties.Insert("PredefinedDataName");
	SetProperties.Insert("PredefinedSetName");
	
	For Each TableRow In Sets Do
		If StrStartsWith(TableRow.PredefinedDataName, "Delete") Then
			Continue;
		EndIf;
		
		FillPropertyValues(SetProperties, TableRow);
		
		SetPropertiesTypes = PropertyManagerInternal.SetPropertiesTypes(SetProperties, False);
		
		If PropertyKind = Enums.PropertiesKinds.AdditionalInfo And SetPropertiesTypes.AdditionalInfo
			Or PropertyKind = Enums.PropertiesKinds.AdditionalAttributes And SetPropertiesTypes.AdditionalAttributes
			Or PropertyKind = Enums.PropertiesKinds.Labels And SetPropertiesTypes.Labels Then
			AvailableSets.Add(TableRow.Ref);
			AvailableSetsList.Add(TableRow.Ref);
		EndIf;
	EndDo;
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "PropertyKind", PropertyKind, True);
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "Sets", AvailableSets, True);
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "LanguageCode", CurrentLanguage().LanguageCode, True);
	
	OnChangeCurrentSetAtServer();
	
EndProcedure
	
&AtClient
Procedure OnChangeCurrentSet()
	
	If ShowUnusedAttributes Then
		Current_Set = Undefined;
		OnChangeCurrentSetAtServer();
	ElsIf Items.PropertiesSets.CurrentData = Undefined Then
		If ValueIsFilled(Current_Set) Then
			Current_Set = Undefined;
			OnChangeCurrentSetAtServer();
		EndIf;
		
	ElsIf Items.PropertiesSets.CurrentData.Ref <> Current_Set Then
		Current_Set          = Items.PropertiesSets.CurrentData.Ref;
		CurrentSetIsFolder = Items.PropertiesSets.CurrentData.IsFolder;
		OnChangeCurrentSetAtServer();
	EndIf;
	
#If MobileClient Then
	CurrentItem = Items.Properties;
	If Not ImportanceConfigured Then
		Items.PropertiesSets.DisplayImportance = DisplayImportance.VeryLow;
		ImportanceConfigured = True;
	EndIf;
	Items.Properties.Title = String(Current_Set);
#EndIf
	
EndProcedure

&AtClient
Procedure ChangeDeletionMark()
	
	If Items.Properties.CurrentData <> Undefined Then
		
		If PropertyKind = PredefinedValue("Enum.PropertiesKinds.AdditionalInfo") Then
			If Not ShowUnusedAttributes Then
				QueryText = NStr("vi = 'Loại trừ thông tin từ tập hợp?';
								|ru = 'Исключить сведение из набора?';
								|en = 'Do you want to remove the information record from the set?'; fa = 'Do you want to remove the information record from the set?';
								|it = 'Escludi informazione dalla selezione';
								|pl = 'Wykluczyć dane z zestawu?';
								|tr = 'Toplama setten hariç tutulsun mu?'");
				
			ElsIf Items.Properties.CurrentData.DeletionMark Then
				QueryText = NStr("vi = 'Bỏ dấu xóa thông tin hiện tại?';
								|ru = 'Снять с текущего сведения пометку на удаление?';
								|en = 'Do you want to clear the deletion mark from the information record?'; fa = 'Do you want to clear the deletion mark from the information record?';
								|it = 'Togliere dall''informazione corrente il contrassegno per la cancellazione?';
								|pl = 'Usunąć z bieżącej informacji zaznaczenie do usunięcia?';
								|tr = 'Mevcut bilgiler için silme işareti kaldırılsın mi?'");
			Else
				QueryText = NStr("vi = 'Đặt dấu xóa thông tin hiện tại?';
								|ru = 'Пометить текущее сведение на удаление?';
								|en = 'Do you want to mark the information record for deletion?'; fa = 'Do you want to mark the information record for deletion?';
								|it = 'Contrassegnare per la cancellazione l''informazione corrente?';
								|pl = 'Zaznacz bieżącą informację do usunięcia?';
								|tr = 'Geçerli bilgi silinmek üzere işaretlensin mi?'");
			EndIf;
		ElsIf PropertyKind = PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes") Then
			If Not ShowUnusedAttributes Then
				QueryText = NStr("vi = 'Loại trừ mục tin khỏi tập hợp?';
								|ru = 'Исключить реквизит из набора?';
								|en = 'Do you want to remove the attribute from the set?'; fa = 'Do you want to remove the attribute from the set?';
								|it = 'Escludere il requisito dalla selezione?';
								|pl = 'Wykluczyć atrybut z zestawu?';
								|tr = 'Öznitelikler setten çıkarılsın mı?'");
				
			ElsIf Items.Properties.CurrentData.DeletionMark Then
				QueryText = NStr("vi = 'Bỏ dấu xóa mục tin hiện tại?';
								|ru = 'Снять с текущего реквизита пометку на удаление?';
								|en = 'Do you want to clear the deletion mark from the attribute?'; fa = 'Do you want to clear the deletion mark from the attribute?';
								|it = 'Togliere dal requisito corrente il contrassegno per la cancellazione?';
								|pl = 'Usunąć z bieżącego atrybutu wspólnego zaznaczenie do usunięcia?';
								|tr = 'Mevcut öznitelik için silme işareti kaldırılsın mi?'");
			Else
				QueryText = NStr("vi = 'Đặt dấu xóa mục tin hiện tại?';
								|ru = 'Пометить текущий реквизит на удаление?';
								|en = 'Do you want to mark the attribute for deletion?'; fa = 'Do you want to mark the attribute for deletion?';
								|it = 'Contrassegnare per la cancellazione il requisito corrente?';
								|pl = 'Zaznaczyć bieżący atrybut do usunięcia?';
								|tr = 'Geçerli öznitelik silinmek üzere işaretlensin mi?'");
			EndIf;
		ElsIf PropertyKind = PredefinedValue("Enum.PropertiesKinds.Labels") Then
			If Not ShowUnusedAttributes Then
				QueryText = NStr("vi = 'Bỏ nhãn đánh dấu khỏi tập hợp?';
								|ru = 'Исключить метку из набора?';
								|en = 'Do you want to remove the label from the set?'; fa = 'Do you want to remove the label from the set?';
								|it = 'Исключить метку из набора?';
								|pl = 'Do you want to remove the label from the set?';
								|tr = 'Etiket kümeden çıkarılsın mı?'");
				
			ElsIf Items.Properties.CurrentData.DeletionMark Then
				QueryText = NStr("vi = 'Bỏ dấu xóa khỏi nhãn này?';
								|ru = 'Снять с текущей метки пометку на удаление?';
								|en = 'Do you want to unmark the label for deletion?'; fa = 'Do you want to unmark the label for deletion?';
								|it = 'Снять с текущей метки пометку на удаление?';
								|pl = 'Do you want to unmark the label for deletion?';
								|tr = 'Mevcut etiketin silinmek üzere işaretini kaldırılsın mı?'");
			Else
				QueryText = NStr("vi = 'Đặt dấu xóa nhãn này?';
								|ru = 'Пометить текущую метку на удаление?';
								|en = 'Do you want to mark the label for deletion?'; fa = 'Do you want to mark the label for deletion?';
								|it = 'Пометить текущую метку на удаление?';
								|pl = 'Do you want to mark the label for deletion?';
								|tr = 'Mevcut etiket silinmek üzere işaretlensin mi?'");
			EndIf;
		EndIf;
		
		ShowQueryBox(
			New CallbackDescription("ChangeDeletionMarkCompletion", ThisObject, Current_Set),
			QueryText, QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeDeletionMarkCompletion(Response, Current_Set) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ExecuteCommandAtServer("ChangeDeletionMark");
	
	Notify("Write_AdditionalAttributesAndInfoSets",
		New Structure("Ref", Current_Set), Current_Set);
	
EndProcedure

&AtServer
Procedure OnChangeCurrentSetAtServer()
	
	If ValueIsFilled(Current_Set)
	   And Not CurrentSetIsFolder
	   Or ShowUnusedAttributes Then
		
		CurrentEnable = True;
		If Items.Properties.BackColor <> Items.PropertiesSets.BackColor Then
			Items.Properties.BackColor = Items.PropertiesSets.BackColor;
		EndIf;
		PropertyManagerInternal.UpdateCurrentSetPropertiesList(ThisObject, 
			Current_Set,
			PropertyKind,
			CurrentEnable);
	Else
		CurrentEnable = False;
		If Items.Properties.BackColor <> FormColor Then
			Items.Properties.BackColor = FormColor;
		EndIf;
		Properties.Clear();
	EndIf;
	
	If Items.Properties.ReadOnly = CurrentEnable Then
		Items.Properties.ReadOnly = Not CurrentEnable;
	EndIf;
	
	PropertiesSetCommandAvailability(ThisObject);
	
	Items.PropertiesSets.Refresh();
	
EndProcedure

&AtClientAtServerNoContext
Procedure PropertiesSetCommandAvailability(Context)
	
	Items = Context.Items;
	ShowUnusedAttributes = Context.ShowUnusedAttributes;
	
	CommonAvailability = Not Items.Properties.ReadOnly;
	InsertAvailability = CommonAvailability And (Context.AttributeToCopy <> Undefined);
	
	AvailabilityForString = CommonAvailability
		And Context.Items.Properties.CurrentRow <> Undefined;
	
	CommonAvailability = CommonAvailability And Not ShowUnusedAttributes;
	
	// Customizing commands of command bar.
	Items.AddFromSet.Enabled           = CommonAvailability;
	Items.PropertiesCreate.Enabled            = CommonAvailability;
	
	Items.PropertiesCopy.Enabled        = AvailabilityForString And Not ShowUnusedAttributes;
	Items.PropertiesEdit.Enabled           = AvailabilityForString;
	Items.PropertiesMarkForDeletion.Enabled = AvailabilityForString;
	
	Items.PropertiesMoveUp.Enabled   = AvailabilityForString;
	Items.PropertiesMoveDown.Enabled    = AvailabilityForString;
	
	Items.CopyAttribute.Enabled         = AvailabilityForString;
	Items.PasteAttribute.Enabled           = InsertAvailability And Not ShowUnusedAttributes;
	
	// Customizing commands of context menu.
	Items.PropertiesContextMenuCreate.Enabled            = CommonAvailability;
	Items.PropertiesContextMenuAddFromSet.Enabled   = CommonAvailability;
	
	Items.PropertiesContextMenuCopy.Enabled        = AvailabilityForString And Not ShowUnusedAttributes;
	Items.PropertiesContextMenuChange.Enabled           = AvailabilityForString;
	Items.PropertiesContextMenuMarkToDelete.Enabled = AvailabilityForString;
	
	Items.PropertiesContextMenuCopyAttribute.Enabled = AvailabilityForString;
	Items.PropertiesContextMenuPasteAttribute.Enabled   = InsertAvailability And Not ShowUnusedAttributes;
	
EndProcedure

&AtServer
Procedure AddCommonPropertyByDragging(PropertyToAdd)
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AdditionalAttributesAndInfoSets");
	LockItem.SetValue("Ref", DestinationSet);
	
	Try
		LockDataForEdit(DestinationSet);
		BeginTransaction();
		Try
			Block.Lock();
			LockDataForEdit(DestinationSet);
			
			SetDestinationObject = DestinationSet.GetObject();
			
			If PropertyKind = Enums.PropertiesKinds.AdditionalAttributes
				Or PropertyKind = Enums.PropertiesKinds.Labels Then
				PropertiesKindName = "AdditionalAttributes"; 
			ElsIf PropertyKind = Enums.PropertiesKinds.AdditionalInfo Then
				PropertiesKindName = "AdditionalInfo";
			EndIf;
			TabularSection = SetDestinationObject[PropertiesKindName];
			
			FoundRow = TabularSection.Find(PropertyToAdd, "Property");
			
			If FoundRow = Undefined Then
				NewRow = TabularSection.Add();
				NewRow.Property = PropertyToAdd;
				SetDestinationObject.Write();
				
			ElsIf FoundRow.DeletionMark Then
				FoundRow.DeletionMark = False;
				SetDestinationObject.Write();
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	Except
		UnlockDataForEdit(DestinationSet);
		Raise;
	EndTry;
	
	Items.PropertiesSets.Refresh();
	DestinationSet = Undefined;
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(Command, Parameter = Undefined)
	
	Block = New DataLock;
	
	If Command = "ChangeDeletionMark" Then
		LockItem = Block.Add("Catalog.AdditionalAttributesAndInfoSets");
		LockItem = Block.Add("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo");
		LockItem = Block.Add("Catalog.ObjectsPropertiesValues");
		LockItem = Block.Add("Catalog.ObjectPropertyValueHierarchy");
	Else
		LockItem = Block.Add("Catalog.AdditionalAttributesAndInfoSets");
		LockItem.SetValue("Ref", Current_Set);
	EndIf;
	
	If ShowUnusedAttributes Then
		BeginTransaction();
		Try
			Block.Lock();
			
			String = Properties.FindByID(Items.Properties.CurrentRow);
			ChangeDeletionMarkAndValuesOwner(String.Property, Undefined);
			OnChangeCurrentSetAtServer();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		Return;
	EndIf;
	
	Try
		LockDataForEdit(Current_Set);
		BeginTransaction();
		Try
			Block.Lock();
			LockDataForEdit(Current_Set);
			
			CurrentSetObject = Current_Set.GetObject();
			If CurrentSetObject.DataVersion <> CurrentSetDataVersion Then
				OnChangeCurrentSetAtServer();
				If PropertyKind = Enums.PropertiesKinds.AdditionalInfo Then
					Raise
						NStr("vi = 'Chưa thực hiện thao tác vì thành phần thông tin bổ sung
						           |đã bị thay đổi bởi người sử dụng khác.
						           |Đã đọc thành phần mới của thông tin bổ sung.
						           |
						           |Hãy thử thao tác lại, nếu cần.';
						           |ru = 'Действие не выполнено, так как состав дополнительных сведений
						           |был изменен другим пользователем.
						           |Новый состав дополнительных сведений прочитан.
						           |
						           |Повторите действие, если требуется.';
						           |en = 'The action is not performed as the set of information records
						           |has been changed by another user.
						           |The new set of additional information records has been read.
						           |
						           |Please try again if required.'; fa = 'The action is not performed as the set of information records
						           |has been changed by another user.
						           |The new set of additional information records has been read.
						           |
						           |Please try again if required.';
						           |it = 'L''azione non è stata completata poiché la composizione delle informazioni aggiuntive
						           |è stata modificata da un altro utente.
						           |La nuova composizione delle informazioni aggiuntive è stata letta.
						           |
						           |Se necessario, ripetere l''azione.';
						           |pl = 'Działanie nie zostało wykonane, ponieważ skład informacji dodatkowych
						           |został zmieniony przez innego użytkownika.
						           |Nowy skład informacji dodatkowych został odczytany.
						           |
						           |Powtórz działanie, jeśli jest to konieczne.';
						           |tr = 'Ek bilgilerin 
						           |içeriği başka bir kullanıcı tarafından değiştirildiği için eylem gerçekleştirilemez. 
						           |Ek bilgilerin yeni içeriği hazır. 
						           |
						           |Gerekirse işlemi tekrarlayın'");
				ElsIf PropertyKind = Enums.PropertiesKinds.AdditionalAttributes Then
					Raise
						NStr("vi = 'Chưa thực hiện thao tác vì thành phần mục tin bổ sung
						           |đã bị thay đổi bởi người sử dụng khác.
						           |Đã đọc thành phần mới của mục tin bổ sung.
						           |
						           |Hãy thử thao tác lại, nếu cần.';
						           |ru = 'Действие не выполнено, так как состав дополнительных реквизитов
						           |был изменен другим пользователем.
						           |Новый состав дополнительных реквизитов прочитан.
						           |
						           |Повторите действие, если требуется.';
						           |en = 'The action is not performed as the set of additional attributes
						           |has been changed by another user.
						           |The new set of additional attributes has been read.
						           |
						           |Please try again if required.'; fa = 'The action is not performed as the set of additional attributes
						           |has been changed by another user.
						           |The new set of additional attributes has been read.
						           |
						           |Please try again if required.';
						           |it = 'L''azione non è stata completata poiché la composizione dei requisiti aggiuntivi
						           |è stata modificata da un altro utente.
						           |La nuova composizione dei requisiti aggiuntivi è stata letta.
						           |
						           |Se necessario, ripetere l''azione.';
						           |pl = 'Działanie nie zostało wykonane, ponieważ skład atrybutów dodatkowych
						           |został zmieniony przez innego użytkownika
						           |Nowy skład atrybutów dodatkowych został odczytany.
						           |
						           |Powtórz działanie, jeśli jest to konieczne.';
						           |tr = 'Ek özniteliklerin
						           |içeriği başka bir kullanıcı tarafından değiştirildiği için eylem gerçekleştirilemez.
						           |Ek özniteliklerin yeni içeriği hazır.
						           |
						           |Gerekirse işlemi tekrarlayın.'");
				ElsIf PropertyKind = Enums.PropertiesKinds.Labels Then
					Raise
						NStr("vi = 'Chưa thực hiện thao tác, bởi vì người sử dụng khác đã thay đổi thành phần của nhãn
						           |.
						           |Đã đọc thành phần mới của nhãn.
						           |
						           |Hãy thử lại, nếu cần.';
						           |ru = 'Действие не выполнено, так как состав меток
						           |был изменен другим пользователем.
						           |Новый состав меток прочитан.
						           |
						           |Повторите действие, если требуется.';
						           |en = 'The action is not performed as the set of labels
						           |has been changed by another user.
						           |The new set of labels has been read.
						           |
						           |Please try again if required.'; fa = 'The action is not performed as the set of labels
						           |has been changed by another user.
						           |The new set of labels has been read.
						           |
						           |Please try again if required.';
						           |it = 'Действие не выполнено, так как состав меток
						           |был изменен другим пользователем.
						           |Новый состав меток прочитан.
						           |
						           |Повторите действие, если требуется.';
						           |pl = 'The action is not performed as the set of labels
						           |has been changed by another user.
						           |The new set of labels has been read.
						           |
						           |Please try again if required.';
						           |tr = 'Etiket içeriği başka bir kullanıcı tarafından değiştirildiğinden
						           |dolayı eylem gerçekleştirilmedi.
						           |Yeni etiket içeriği okundu.
						           |
						           |Gerekirse işlemi tekrarlayın.'");
				EndIf;
			EndIf;
			
			If PropertyKind = Enums.PropertiesKinds.AdditionalInfo Then
				PropertiesKindName = "AdditionalInfo";
			Else
				PropertiesKindName = "AdditionalAttributes";
			EndIf;
			TabularSection = CurrentSetObject[PropertiesKindName];
			
			If Command = "AddCommonProperty" Then
				FoundRow = TabularSection.Find(Parameter, "Property");
				
				If FoundRow = Undefined Then
					NewRow = TabularSection.Add();
					NewRow.Property = Parameter;
					CurrentSetObject.Write();
					
				ElsIf FoundRow.DeletionMark Then
					FoundRow.DeletionMark = False;
					CurrentSetObject.Write();
				EndIf;
			Else
				String = Properties.FindByID(Items.Properties.CurrentRow);
				
				If String <> Undefined Then
					IndexOf = String.LineNumber-1;
					
					If Command = "MoveUp" Then
						TopRowIndex = Properties.IndexOf(String)-1;
						If TopRowIndex >= 0 Then
							Move = Properties[TopRowIndex].LineNumber - String.LineNumber;
							TabularSection.Move(IndexOf, Move);
						EndIf;
						CurrentSetObject.Write();
						
					ElsIf Command = "MoveDown" Then
						BottomRowIndex = Properties.IndexOf(String)+1;
						If BottomRowIndex < Properties.Count() Then
							Move = Properties[BottomRowIndex].LineNumber - String.LineNumber;
							TabularSection.Move(IndexOf, Move);
						EndIf;
						CurrentSetObject.Write();
						
					ElsIf Command = "ChangeDeletionMark" Then
						String = Properties.FindByID(Items.Properties.CurrentRow);
						
						If String.Common Then
							TabularSection.Delete(IndexOf);
							CurrentSetObject.Write();
							Properties.Delete(String);
						Else
							TabularSection[IndexOf].DeletionMark = Not TabularSection[IndexOf].DeletionMark;
							CurrentSetObject.Write();
							
							ChangeDeletionMarkAndValuesOwner(
								TabularSection[IndexOf].Property,
								TabularSection[IndexOf].DeletionMark);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	Except
		UnlockDataForEdit(Current_Set);
		Raise;
	EndTry;
	
	OnChangeCurrentSetAtServer();
	
EndProcedure

&AtServer
Procedure ChangeDeletionMarkAndValuesOwner(CurrentProperty, PropertyDeletionMark)
	
	// ACC:1328-off - A lock is set higher up in the stack.
	// ACC:1327-off - A lock is set higher up in the stack.
	OldValuesOwner = CurrentProperty;
	
	NewValuesMark   = Undefined;
	NewValuesOwner  = Undefined;
	
	ObjectProperty = CurrentProperty.GetObject();
	
	If PropertyDeletionMark = Undefined Then
		PropertyDeletionMark = Not ObjectProperty.DeletionMark;
	EndIf;
	
	If PropertyDeletionMark Then
		// When marking a unique property for deletion:
		// - Mark the property itself.
		// - If there are clones not marked for deletion,
		//   set a new value owner and assign a new original property to the clones.
		//   Alternatively, mark the original and the cloned properties for deletion.
		//   
		ObjectProperty.DeletionMark = True;
		
		If Not ValueIsFilled(ObjectProperty.AdditionalValuesOwner) Then
			Query = New Query;
			Query.SetParameter("Property", ObjectProperty.Ref);
			Query.Text =
			"SELECT
			|	Properties.Ref,
			|	Properties.DeletionMark
			|FROM
			|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
			|WHERE
			|	Properties.AdditionalValuesOwner = &Property";
			Upload0 = Query.Execute().Unload();
			FoundRow = Upload0.Find(False, "DeletionMark");
			If FoundRow <> Undefined Then
				NewValuesOwner  = FoundRow.Ref;
				ObjectProperty.AdditionalValuesOwner = NewValuesOwner;
				For Each TableRow In Upload0 Do
					CurrentObject = TableRow.Ref.GetObject();
					If CurrentObject.Ref = NewValuesOwner Then
						CurrentObject.AdditionalValuesOwner = Undefined;
					Else
						CurrentObject.AdditionalValuesOwner = NewValuesOwner;
					EndIf;
					CurrentObject.Write();
				EndDo;
			Else
				NewValuesMark = True;
			EndIf;
		EndIf;
		ObjectProperty.Write();
	Else
		If ObjectProperty.DeletionMark Then
			ObjectProperty.DeletionMark = False;
			ObjectProperty.Write();
		EndIf;
		// When clearing the deletion mark from a unique property:
		// - Clear the deletion mark from the property itself.
		// - If it was cloned and the clones are marked for deletion,
		//   set a new (current) value owner for all properties
		//     and clear the deletion mark from the values.
		//     Alternatively, clear the deletion mark from the values.
		//   
		If Not ValueIsFilled(ObjectProperty.AdditionalValuesOwner) Then
			NewValuesMark = False;
			
		ElsIf Common.ObjectAttributeValue(
		            ObjectProperty.AdditionalValuesOwner, "DeletionMark") Then
			
			Query = New Query;
			Query.SetParameter("Property", ObjectProperty.AdditionalValuesOwner);
			Query.Text =
			"SELECT
			|	Properties.Ref AS Ref
			|FROM
			|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
			|WHERE
			|	Properties.AdditionalValuesOwner = &Property";
			Array = Query.Execute().Unload().UnloadColumn("Ref");
			Array.Add(ObjectProperty.AdditionalValuesOwner);
			NewValuesOwner = ObjectProperty.Ref;
			For Each CurrentRef In Array Do
				If CurrentRef = NewValuesOwner Then
					Continue;
				EndIf;
				CurrentObject = CurrentRef.GetObject();
				CurrentObject.AdditionalValuesOwner = NewValuesOwner;
				CurrentObject.Write();
			EndDo;
			OldValuesOwner = ObjectProperty.AdditionalValuesOwner;
			ObjectProperty.AdditionalValuesOwner = Undefined;
			ObjectProperty.Write();
			NewValuesMark = False;
		EndIf;
	EndIf;
	
	If NewValuesMark  = Undefined  And NewValuesOwner = Undefined Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Owner", OldValuesOwner);
	Query.Text =
	"SELECT
	|	ObjectsPropertiesValues.Ref AS Ref,
	|	ObjectsPropertiesValues.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
	|WHERE
	|	ObjectsPropertiesValues.Owner = &Owner
	|
	|UNION ALL
	|
	|SELECT
	|	ObjectPropertyValueHierarchy.Ref,
	|	ObjectPropertyValueHierarchy.DeletionMark
	|FROM
	|	Catalog.ObjectPropertyValueHierarchy AS ObjectPropertyValueHierarchy
	|WHERE
	|	ObjectPropertyValueHierarchy.Owner = &Owner";
	
	Upload0 = Query.Execute().Unload();
	
	For Each TableRow In Upload0 Do
		CurrentObject = TableRow.Ref.GetObject();
		
		If NewValuesOwner <> Undefined And CurrentObject.Owner <> NewValuesOwner Then
			CurrentObject.Owner = NewValuesOwner;
		EndIf;
		
		If NewValuesMark <> Undefined And CurrentObject.DeletionMark <> NewValuesMark Then
			CurrentObject.DeletionMark = NewValuesMark;
		EndIf;

		If CurrentObject.Modified() Then
			CurrentObject.DataExchange.Load = True;
			CurrentObject.Write();
		EndIf;
	EndDo;
	
	// ACC:1327-on
	// ACC:1328-on
	
EndProcedure

#EndRegion
