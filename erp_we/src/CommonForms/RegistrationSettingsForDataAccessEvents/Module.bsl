///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var NameOfTableToDelete, NewCurLine;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Not Users.IsFullUser(, True) Then
		Cancel = True;
	EndIf;
	
	URL = "e1cib/app/CommonForm.RegistrationSettingsForDataAccessEvents";
	
	FillCurrentSettings();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseOnClient", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettings

&AtClient
Procedure SettingsOnActivateRow(Item)
	
	DeleteEnabled = Item.CurrentData <> Undefined
		And Item.CurrentData.ThisIsTable;
	
	Items.SettingsContextMenuDelete.Enabled = DeleteEnabled;
	Items.SettingsDelete.Enabled = DeleteEnabled;
	
EndProcedure

&AtClient
Procedure SettingsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	AttachIdleHandler("SelectObjects", 0.1, True);
	
EndProcedure

&AtClient
Procedure SettingsBeforeDeleteRow(Item, Cancel)
	
	NewCurLine = Undefined;
	
	If Item.CurrentData = Undefined
	 Or Not Item.CurrentData.ThisIsTable Then
		Cancel = True;
		Return;
	EndIf;
	
	NameOfTableToDelete = Item.CurrentData.Name;
	
	TablesItems = Settings.GetItems();
	IndexOf = TablesItems.IndexOf(Settings.FindByID(Item.CurrentRow));
	If TablesItems.Count() > IndexOf + 1 Then
		NewCurLine = TablesItems.Get(IndexOf + 1).GetID();
	ElsIf IndexOf > 0 Then
		NewCurLine = TablesItems.Get(IndexOf - 1).GetID();
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsAfterDeleteRow(Item)
	
	ListItem = SelectedObjects.FindByValue(NameOfTableToDelete);
	If ListItem <> Undefined Then
		SelectedObjects.Delete(ListItem);
	EndIf;
	
	If NewCurLine <> Undefined Then
		Item.CurrentRow = NewCurLine;
		NewCurLine = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	WriteAndCloseOnClient();
EndProcedure

&AtClient
Procedure Select(Command)
	
	SelectObjects();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsToControl.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsDoRegister.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsComment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Settings.IsField");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsComment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Settings.ToControl");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Settings.DoRegister");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsPresentation.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsName.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Settings.IsNameDeleted");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

EndProcedure

&AtClient
Procedure SelectObjects()
	
	MetadataFilter = New ValueList;
	MetadataFilter.Add("ExchangePlans");
	MetadataFilter.Add("Constants");
	MetadataFilter.Add("Sequences");
	MetadataFilter.Add("Catalogs");
	MetadataFilter.Add("Documents");
	MetadataFilter.Add("DocumentJournals");
	MetadataFilter.Add("ChartsOfCharacteristicTypes");
	MetadataFilter.Add("ChartsOfAccounts");
	MetadataFilter.Add("ChartsOfCalculationTypes");
	MetadataFilter.Add("InformationRegisters");
	MetadataFilter.Add("AccumulationRegisters");
	MetadataFilter.Add("AccountingRegisters");
	MetadataFilter.Add("CalculationRegisters");
	MetadataFilter.Add("BusinessProcesses");
	MetadataFilter.Add("Tasks");
	MetadataFilter.Add("ExternalDataSources");
	
	FormParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	FormParameters.MetadataObjectsToSelectCollection = MetadataFilter;
	FormParameters.SelectedMetadataObjects = SelectedObjects;
	FormParameters.UUIDSource = UUID;
	FormParameters.SelectSingle = False;
	FormParameters.ShouldSelectExternalDataSourceTables = True;
	FormParameters.ObjectsGroupMethod = "ByKinds";
	
	CallbackDescription = New CallbackDescription("SelectObjectsCompletion", ThisObject);
	StandardSubsystemsClient.ChooseMetadataObjects(FormParameters, CallbackDescription);
	
EndProcedure

&AtClient
Procedure SelectObjectsCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		HandleSelected(Result.UnloadValues());
		StandardSubsystemsClient.ExpandTreeNodes(ThisObject, Items.Settings.Name,, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure HandleSelected(SelectedTables)
	
	ItemsToRemove = New Array;
	TablesItems = Settings.GetItems();
	TablesNames = New Map;
	
	IndexOf = 0;
	For Each RowColumn In TablesItems Do
		If SelectedTables.Find(RowColumn.Name) <> Undefined Then
			TablesNames.Insert(RowColumn.Name, RowColumn);
		ElsIf RowColumn.IsNameDeleted Then
			TablesNames.Insert(RowColumn.Name, RowColumn);
			SelectedTables.Insert(IndexOf, RowColumn.Name);
			IndexOf = IndexOf + 1;
		Else
			ItemsToRemove.Add(RowColumn);
		EndIf;
	EndDo;
	
	For Each RowColumn In ItemsToRemove Do
		TablesItems.Delete(RowColumn);
	EndDo;
	
	IndexOf = -1;
	For Each Selected_Table In SelectedTables Do
		RowColumn = TablesNames.Get(Selected_Table);
		If RowColumn <> Undefined Then
			IndexOf = IndexOf + 1;
			ElementIndex = TablesItems.IndexOf(RowColumn);
			TablesItems.Move(ElementIndex, IndexOf - ElementIndex);
			Continue;
		EndIf;
		MetadataObject = Common.MetadataObjectByFullName(Selected_Table);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		FullTableName = MetadataObject.FullName();
		TableFields = UsersInternalCached.TableFields(FullTableName);
		If TableFields = Undefined Then
			Continue;
		EndIf;
		IndexOf = IndexOf + 1;
		RowColumn = TablesItems.Insert(IndexOf);
		RowColumn.Name = FullTableName;
		RowColumn.ThisIsTable = True;
		RowColumn.Presentation = MetadataObject.Presentation();
		RowColumn.Picture = PictureInDesigner(MetadataObject, RowColumn.Presentation);
		RowColumn.ToControl = True;
		RowColumn.DoRegister = True;
		ItemDetails = New Structure("Item, Fields, TabularSections",
			RowColumn, New Map, New Map);
		AddTable(ItemDetails, TableFields);
	EndDo;
	
	SelectedObjects.Clear();
	For Each RowColumn In TablesItems Do
		SelectedObjects.Add(RowColumn.Name);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillCurrentSettings()
	
	CurrentSettings = UserMonitoring.RegistrationSettingsForDataAccessEvents();
	EventSettings = CurrentSettings.Content;
	GeneralComment = CurrentSettings.GeneralComment;
	
	Comments = New Map;
	For Each KeyAndValue In CurrentSettings.Comments Do
		Comments.Insert(Lower(KeyAndValue.Key), KeyAndValue.Value);
	EndDo;
	
	TablesItems = Settings.GetItems();
	Added1 = New Map;
	SelectedObjects.Clear();
	
	For Each EventSetting In EventSettings Do
		MetadataObject = Common.MetadataObjectByFullName(EventSetting.Object);
		If MetadataObject = Undefined Then
			IsTableNameDeleted = True;
			FullTableName = EventSetting.Object;
			TablePresentation = EventSetting.Object;
		Else
			IsTableNameDeleted = False;
			FullTableName = MetadataObject.FullName();
			TablePresentation = MetadataObject.Presentation();
		EndIf;
		TableFields = UsersInternal.TableFieldsConsideringAccessEventSettings(EventSetting);
		If TableFields = Undefined Then
			Continue;
		EndIf;
		SelectedObjects.Add(FullTableName);
		ItemDetails = Added1.Get(FullTableName);
		If ItemDetails = Undefined Then
			RowColumn = TablesItems.Add();
			RowColumn.Name = FullTableName;
			RowColumn.IsNameDeleted = IsTableNameDeleted;
			RowColumn.ThisIsTable = True;
			RowColumn.Presentation = TablePresentation;
			RowColumn.Picture = PictureInDesigner(MetadataObject, RowColumn.Presentation);
			RowColumn.ToControl = True;
			RowColumn.DoRegister = True;
			ItemDetails = New Structure("Item, Fields, TabularSections",
				RowColumn, New Map, New Map);
			Added1.Insert(FullTableName, ItemDetails);
		EndIf;
		ConfiguredFields = New Structure;
		ConfiguredFields.Insert("AccessFields",      FieldsInLowerCase(EventSetting.AccessFields));
		ConfiguredFields.Insert("LoggedFields",  FieldsInLowerCase(EventSetting.LoggedFields));
		ConfiguredFields.Insert("AllFields",          TableFields.AllFields);
		ConfiguredFields.Insert("FullTableName", FullTableName);
		ConfiguredFields.Insert("Comments",      Comments);
		
		AddTable(ItemDetails,
			TableFields, ConfiguredFields, IsTableNameDeleted);
	EndDo;
	
	IndexOf = 0;
	For Each RowColumn In TablesItems Do
		If RowColumn.IsNameDeleted Then
			ElementIndex = TablesItems.IndexOf(RowColumn);
			TablesItems.Move(ElementIndex, IndexOf - ElementIndex);
			IndexOf = IndexOf + 1;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function FieldsInLowerCase(Fields)
	
	Result = New Map;
	For Each Field In Fields Do
		If TypeOf(Field) = Type("Array") Then
			For Each NestedField In Field Do
				If Result.Get(Lower(NestedField)) = Undefined Then
					Result.Insert(Lower(NestedField), NestedField);
				EndIf;
			EndDo;
		ElsIf Result.Get(Lower(Field)) = Undefined Then
			Result.Insert(Lower(Field), Field);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure AddTable(TableItemDetails, TableFields, ConfiguredFields = Undefined, IsTableNameDeleted = False)
	
	RowColumn = TableItemDetails.Item;
	TabularSections = TableItemDetails.TabularSections;
	Fields           = TableItemDetails.Fields;
	
	ItemsOfFieldsAndTables = RowColumn.GetItems();
	
	For Each CollectionDescription_ In TableFields.Collections Do
		If CollectionDescription_.Fields <> Undefined Then
			AddFields(ItemsOfFieldsAndTables,
				CollectionDescription_.Fields, Fields, ConfiguredFields, IsTableNameDeleted,
				PictureInDesigner(Undefined, "", CollectionDescription_.Name));
		Else
			For Each TableDetails In CollectionDescription_.Tables Do
				TabularSection = TabularSections.Get(TableDetails.Name);
				If TabularSection = Undefined Then
					TabularSectionItem = ItemsOfFieldsAndTables.Add();
					TabularSectionItem.IsTabularSection = True;
					TabularSectionItem.Name = TableDetails.Name;
					TabularSectionItem.IsNameDeleted = IsTableNameDeleted
						Or Not ValueIsFilled(CollectionDescription_.Name);
					TabularSectionItem.Presentation = TableDetails.Presentation;
					TabularSectionItem.Picture = PictureInDesigner(Undefined, "", CollectionDescription_.Name);
					TabularSectionItem.ToControl = True;
					TabularSectionItem.DoRegister = True;
					TabularSection = New Structure;
					TabularSection.Insert("Item", TabularSectionItem);
					TabularSection.Insert("Fields", New Map);
					TabularSections.Insert(TableDetails.Name, TabularSection);
				EndIf;
				AddFields(TabularSection.Item.GetItems(),
					TableDetails.Fields, TabularSection.Fields, ConfiguredFields, IsTableNameDeleted,
					PictureInDesigner(Undefined, "", CollectionDescription_.Name, True),
					TableDetails.Name + ".");
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AddFields(FieldsItems, FieldsDetails, AddedFields, ConfiguredFields,
			IsTableNameDeleted, Picture, TabularSectionName = "")
	
	For Each FieldDetails In FieldsDetails Do
		FieldItem = AddedFields.Get(FieldDetails.Name);
		If FieldItem = Undefined Then
			FieldItem = FieldsItems.Add();
			FieldItem.IsField = True;
			FieldItem.Name = FieldDetails.Name;
			FieldItem.IsNameDeleted = IsTableNameDeleted;
			FieldItem.Presentation = FieldDetails.Presentation;
			FieldItem.Picture = Picture;
			AddedFields.Insert(FieldDetails.Name, FieldItem);
		EndIf;
		If ConfiguredFields = Undefined Then
			Continue;
		EndIf;
		FieldNameForSearch = Lower(TabularSectionName + FieldDetails.Name);
		If ConfiguredFields.AllFields.Get(FieldNameForSearch) = Undefined Then
			FieldItem.IsNameDeleted = True;
		EndIf;
		If ConfiguredFields.AccessFields.Get(FieldNameForSearch) <> Undefined Then
			FieldItem.ToControl = True;
		EndIf;
		If ConfiguredFields.LoggedFields.Get(FieldNameForSearch) <> Undefined Then
			FieldItem.DoRegister = True;
		EndIf;
		FieldFullNameForSearch = Lower(ConfiguredFields.FullTableName + "." + FieldNameForSearch);
		FieldItem.Comment = ConfiguredFields.Comments.Get(FieldFullNameForSearch);
	EndDo;
	
EndProcedure

&AtServer
Function PictureInDesigner(MetadataObject, Presentation, CollectionName = Undefined, CollectionFields = False)
	
	If MetadataObject <> Undefined Then
		StringParts1 = StrSplit(MetadataObject.FullName(), ".");
		IconName = StringParts1[0];
		If IconName = "ExternalDataSource" Then
			IconName = "ExternalDataSourceTable";
			Presentation = Metadata.ExternalDataSources[StringParts1[1]].Presentation()
				+ ". " + Presentation;
		EndIf;
	ElsIf CollectionName = Undefined Then
		Return Undefined;
	Else
		RefinedCollectionName = CollectionName;
		If CollectionFields Then
			If CollectionName = "TabularSections" Then
				RefinedCollectionName = "Attributes";
			ElsIf CollectionName = "StandardTabularSections" Then
				RefinedCollectionName = "StandardAttributes";
			EndIf;
		EndIf;
		IconName = "Metadata" + RefinedCollectionName;
	EndIf;
	
	Images = New Structure(IconName);
	FillPropertyValues(Images, PictureLib);
	
	Return Images[IconName];
	
EndFunction

&AtClient
Procedure WriteAndCloseOnClient(Result = Undefined, AdditionalParameters = Undefined) Export
	
	ClearMessages();
	
	If IsWrittenAtServer() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Function IsWrittenAtServer()
	
	EventSettings = New Array;
	Comments = New Map;
	HasErrors = False;
	
	TablesItems = Settings.GetItems();
	For Each RowColumn In TablesItems Do
		If RowColumn.IsNameDeleted Then
			Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa tìm thấy bảng ""%1"".';
					|ru = 'Таблица ""%1"" не найдена.';
					|en = 'Cannot file table ""%1"".'; fa = 'Cannot file table ""%1"".';
					|it = 'Таблица ""%1"" не найдена.';
					|pl = 'Cannot file table ""%1"".';
					|tr = 'Tablo""%1"" bulunamadı'"), RowColumn.Name), , "Settings");
			HasErrors = True;
			Continue;
		EndIf;
		ItemsOfTabularSectionsAndFields = RowColumn.GetItems();
		AccessFields = New Array;
		LoggedFields = New Array;
		For Each FieldOrTabularSectionItem In ItemsOfTabularSectionsAndFields Do
			If FieldOrTabularSectionItem.IsField Then
				FieldsItems = CommonClientServer.ValueInArray(FieldOrTabularSectionItem);
			Else
				FieldsItems = FieldOrTabularSectionItem.GetItems();
			EndIf;
			For Each FieldItem In FieldsItems Do
				FieldName = FieldItem.Name;
				If FieldOrTabularSectionItem.IsTabularSection Then
					FieldName = FieldOrTabularSectionItem.Name + "." + FieldName;
				EndIf;
				If FieldItem.IsNameDeleted
				   And (FieldItem.ToControl Or FieldItem.DoRegister) Then
					Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Chưa tìm thấy trường ""%1"".';
								|ru = 'Поле ""%1"" не найдено.';
								|en = 'The ""%1"" field is not found.'; fa = 'The ""%1"" field is not found.';
								|it = 'Поле ""%1"" не найдено.';
								|pl = 'The ""%1"" field is not found.';
								|tr = '""%1""alanı bulunamadı'"),
						RowColumn.Name + "." + FieldName), , "Settings");
					HasErrors = True;
					Continue;
				EndIf;
				If FieldItem.ToControl Then
					AccessFields.Add(FieldName);
				EndIf;
				If FieldItem.DoRegister Then
					LoggedFields.Add(FieldName);
				EndIf;
				If ValueIsFilled(FieldItem.Comment)
				   And (FieldItem.ToControl Or FieldItem.DoRegister) Then
					Comments.Insert(RowColumn.Name + "." + FieldName, FieldItem.Comment);
				EndIf;
			EndDo;
		EndDo;
		If Not ValueIsFilled(AccessFields) Then
			If ValueIsFilled(LoggedFields) Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đối với bảng ""%1"" đã chỉ ra các trường mà cần đưa chúng vào sự kiện, nhưng chưa chỉ ra các trường mà sẽ được ghi lại khi truy cập đến chúng.';
							|ru = 'Для таблицы ""%1"" указаны поля, которые нужно включать в событие, но не указаны поля, при доступе к которым событие будет записываться.';
							|en = 'The table ""%1"" specifies fields to include in the event but does not specify fields that trigger event recording upon access.'; fa = 'The table ""%1"" specifies fields to include in the event but does not specify fields that trigger event recording upon access.';
							|it = 'Для таблицы ""%1"" указаны поля, которые нужно включать в событие, но не указаны поля, при доступе к которым событие будет записываться.';
							|pl = 'The table ""%1"" specifies fields to include in the event but does not specify fields that trigger event recording upon access.';
							|tr = '""%1"" tablosu için etkinliğe dahil edilmesi gereken alanlar belirtildi ancak erişildiğinde etkinliği kaydedecek alanlar belirtilmedi'"),
					RowColumn.Presentation), , "Settings");
				HasErrors = True;
			EndIf;
			Continue;
		EndIf;
		NewSetting = New EventLogAccessEventUseDescription;
		NewSetting.Object = RowColumn.Name;
		NewSetting.AccessFields = AccessFields;
		NewSetting.LoggedFields = LoggedFields;
		EventSettings.Add(NewSetting);
	EndDo;
	
	If HasErrors Then
		Return False;
	EndIf;
	
	NewSettings1 = New Structure;
	NewSettings1.Insert("Content", EventSettings);
	NewSettings1.Insert("Comments", Comments);
	NewSettings1.Insert("GeneralComment", GeneralComment);
	
	UserMonitoring.SetRegistrationSettingsForDataAccessEvents(NewSettings1);
	
	Modified = False;
	
	Return True;
	
EndFunction

#EndRegion
