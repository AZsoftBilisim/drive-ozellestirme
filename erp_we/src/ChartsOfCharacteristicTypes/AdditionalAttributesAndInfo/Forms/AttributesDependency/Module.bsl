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
	
	PropertyToConfigure = Parameters.PropertyToConfigure;
	
	ObjectProperties = Common.ObjectAttributesValues(Parameters.AdditionalAttribute, "Title");
	
	Title = NStr("vi = '%1 mục tin bổ sung ""%2""';
				|ru = '%1 дополнительного реквизита ""%2""';
				|en = '%1 of ""%2"" additional attribute'; fa = '%1 of ""%2"" additional attribute';
				|it = '%1 del requisito aggiuntivo ""%2""';
				|pl = '%1 atrybutu dodatkowego ""%2""';
				|tr = '""%2"" ek özniteliğinin %1'");
	If PropertyToConfigure = "Available" Then
		PropertyPresentation = NStr("vi = 'Tính khả dụng';
									|ru = 'Доступность';
									|en = 'Availability'; fa = 'دسترس‌پذیری';
									|it = 'Accessibilità';
									|pl = 'Dostępność';
									|tr = 'Erişilebilirlik'");
	ElsIf PropertyToConfigure = "RequiredToFill" Then
		PropertyPresentation = NStr("vi = 'Bắt buộc điền';
									|ru = 'Обязательность заполнения';
									|en = '""Required"" property'; fa = '""Required"" property';
									|it = 'Obbligo di compilazione';
									|pl = 'Konieczność wypełnienia';
									|tr = 'Gerekli doldurma'");
	Else
		PropertyPresentation = NStr("vi = 'Tính hiển thị';
									|ru = 'Видимость';
									|en = 'Visibility'; fa = 'نمایش';
									|it = 'Visibilità';
									|pl = 'Widoczność';
									|tr = 'Görünürlük'");
	EndIf;
	Title = StrReplace(Title, "%1", PropertyPresentation);
	Title = StrReplace(Title, "%2", ObjectProperties.Title);
	
	If Not ValueIsFilled(ObjectProperties.Title)  Then
		Title = StrReplace(Title, """", "");
	EndIf;
	
	PropertiesSet = Parameters.Set;
	
	If Not ValueIsFilled(PropertiesSet) Then
		ExceptionText = NStr("vi = 'Đặt mức độ hiển thị, tính khả dụng và điền bắt buộc 
			              |chỉ khả dụng khi mở thêm mục tin bổ sung 
			              |từ danh sách ""Mục tin bổ sung"".';
			              |ru = 'Настройка видимости, доступности и обязательности заполнения
			              |доступна только при открытии дополнительного реквизита
			              |из списка ""Дополнительные реквизиты"".';
			              |en = 'You can configure attribute visibility, availability, and whether it is required
			              |only if you open the additional attribute
			              |from the ""Additional attributes"" list.'; fa = 'You can configure attribute visibility, availability, and whether it is required
			              |only if you open the additional attribute
			              |from the ""Additional attributes"" list.';
			              |it = 'Impostazione di visibilità, accessibilità e compilazione obbligatoria 
			              | è disponibile sono all''apertura del requisito aggiuntivo 
			              |dall''elenco ""Requisiti aggiuntivi"".';
			              |pl = 'Ustawienie widoczności, dostępności i wymagalności wypełnienia
			              |jest dostępne tylko podczas otwarcia atrybutu dodatkowego
			              |z listy ""Atrybuty dodatkowe"".';
			              |tr = 'Görünürlük, erişilebilirlik ve doldurma zorunluluğunun ayarı
			              | ancak ""Ek öznitelikler"" listesinden
			              | ek öznitelik açıldığında kullanılabilir.'");
		ExceptionText = StrReplace(ExceptionText, Chars.LF, " ");
		Raise ExceptionText;
	EndIf;
	
	Parent = Common.ObjectAttributeValue(PropertiesSet, "Parent");
	If Not ValueIsFilled(Parent) Then
		Parent = PropertiesSet;
	EndIf;
	
	AdditionalAttributesSet = Common.ObjectAttributeValue(Parent, "AdditionalAttributes").Unload();
	
	PredefinedPropertiesSets = PropertyManagerCached.PredefinedPropertiesSets();
	SetDetails = PredefinedPropertiesSets.Get(Parent); // See Catalogs.AdditionalAttributesAndInfoSets.SetProperties
	If SetDetails = Undefined Then
		PredefinedDataName = Common.ObjectAttributeValue(Parent, "PredefinedDataName");
	Else
		PredefinedDataName = SetDetails.Name;
	EndIf;
	
	ReplacedCharacterPosition = StrFind(PredefinedDataName, "_");
	FullMetadataObjectName = Left(PredefinedDataName, ReplacedCharacterPosition - 1)
		                       + "."
		                       + Mid(PredefinedDataName, ReplacedCharacterPosition + 1);
	
	ObjectAttributes = ListOfAttributesToFilter(FullMetadataObjectName, AdditionalAttributesSet);
	
	FIlterRow = Undefined;
	AdditionalAttributesDependencies = Parameters.AttributesDependencies;
	For Each LineOfATabularSection In AdditionalAttributesDependencies Do
		If LineOfATabularSection.PropertiesSet <> PropertiesSet Then
			Continue;
		EndIf;
		If LineOfATabularSection.DependentProperty = PropertyToConfigure Then
			ConditionByParts = StrSplit(LineOfATabularSection.Condition, " ");
			NewCondition = "";
			If ConditionByParts.Count() > 0 Then
				For Each ConditionPart In ConditionByParts Do
					NewCondition = NewCondition + Upper(Left(ConditionPart, 1)) + Mid(ConditionPart, 2);
				EndDo;
			EndIf;
			
			If ValueIsFilled(NewCondition) Then
				LineOfATabularSection.Condition = NewCondition;
			EndIf;
			
			AttributeWithMultivalue = (LineOfATabularSection.Condition = "InList")
				Or (LineOfATabularSection.Condition = "NotInList");
			
			If AttributeWithMultivalue Then
				FilterParameters = New Structure;
				FilterParameters.Insert("Attribute", LineOfATabularSection.Attribute);
				FilterParameters.Insert("Condition",  LineOfATabularSection.Condition);
				
				SearchResult = AttributesDependencies.FindRows(FilterParameters);
				If SearchResult.Count() = 0 Then
					FIlterRow = AttributesDependencies.Add();
					FillPropertyValues(FIlterRow, LineOfATabularSection,, "Value");
					
					Values = New ValueList;
					Values.Add(LineOfATabularSection.Value);
					FIlterRow.Value = Values;
				Else
					FIlterRow = SearchResult[0];
					FIlterRow.Value.Add(LineOfATabularSection.Value);
				EndIf;
			Else
				FIlterRow = AttributesDependencies.Add();
				FillPropertyValues(FIlterRow, LineOfATabularSection);
			EndIf;
			
			AttributeDetails = ObjectAttributes.Find(FIlterRow.Attribute, "Attribute");
			If AttributeDetails = Undefined Then
				Continue; // Object attribute is not found.
			EndIf;
			FIlterRow.ChoiceMode   = AttributeDetails.ChoiceMode;
			FIlterRow.Presentation = AttributeDetails.Presentation;
			FIlterRow.ValueType   = AttributeDetails.ValueType;
			If AttributeWithMultivalue Then
				FIlterRow.Value.ValueType = AttributeDetails.ValueType;
			EndIf;
		EndIf;
	EndDo;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "PropertiesObjectAttributeSelection" Then
		CurrentRow = AttributesDependencies.FindByID(Items.AttributesDependencies.CurrentRow);
		FilterParameters = New Structure;
		FilterParameters.Insert("Attribute", Parameter.Attribute);
		FoundRows = AttributesDependencies.FindRows(FilterParameters);
		If FoundRows.Count() > 0 Then
			Items.AttributesDependencies.CurrentRow = FoundRows[0].GetID();
			AttributesDependencies.Delete(CurrentRow);
			Return;
		EndIf;
		FillPropertyValues(CurrentRow, Parameter);
		CurrentRow.PropertiesSet = PropertiesSet;
		AttributesDependenciesSetTypeRestrictionForValue();
		CurrentRow.DependentProperty = PropertyToConfigure;
		CurrentRow.Condition  = "Equal";
		CurrentRow.Value = CurrentRow.ValueType.AdjustValue(Undefined);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AttributesDependenciesAttributeStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenAttributeChoiceForm();
EndProcedure

&AtClient
Procedure AttributesDependenciesBeforeRowChange(Item, Cancel)
	AttributesDependenciesSetTypeRestrictionForValue();
EndProcedure

&AtClient
Procedure AttributesDependenciesComparisonKindOnChange(Item)
	AttributesDependenciesSetTypeRestrictionForValue();
	
	FormTable = Items.AttributesDependencies;
	CurrentRow = AttributesDependencies.FindByID(FormTable.CurrentRow);
	
	If FormTable.CurrentData.Condition = "InList"
		Or FormTable.CurrentData.Condition = "NotInList" Then
		If TypeOf(CurrentRow.Value) <> Type("ValueList") Then
			PreviousValue2 = CurrentRow.Value;
			CurrentRow.Value = New ValueList;
			CurrentRow.Value.ValueType = FormTable.CurrentData.ValueType;
			If ValueIsFilled(PreviousValue2) Then
				CurrentRow.Value.Add(PreviousValue2);
			EndIf;
		EndIf;
	ElsIf FormTable.CurrentData.Condition = "Equal"
		Or FormTable.CurrentData.Condition = "NotEqual" Then
		If TypeOf(CurrentRow.Value) = Type("ValueList")
			And CurrentRow.Value.Count() > 0 Then
			CurrentRow.Value = CurrentRow.Value[0].Value;
		EndIf;
	Else
		CurrentRow.Value = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure AttributesDependenciesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	If Not CanAddLine Then
		Cancel = True;
	Else
		OpenAttributeChoiceForm();
		CanAddLine = False;
	EndIf;
EndProcedure

&AtClient
Procedure OpenAttributeChoiceForm()
	FormParameters = New Structure;
	FormParameters.Insert("ObjectAttributes", ObjectAttributesInStorage);
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.SelectAttribute", FormParameters);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddCondition(Command)
	CanAddLine = True;
	Items.AttributesDependencies.AddRow();
EndProcedure

&AtClient
Procedure OkCommand(Command)
	Result = New Structure;
	Result.Insert(PropertyToConfigure, FilterSettingsInValueStorage());
	Notify("PropertiesAttributeDependencySet", Result);
	Close();
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FilterSettingsInValueStorage()
	
	If AttributesDependencies.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	DependenciesTable = FormAttributeToValue("AttributesDependencies");
	TableCopy = DependenciesTable.Copy();
	TableCopy.Columns.Delete("Presentation");
	TableCopy.Columns.Delete("ValueType");
	
	FilterParameter = New Structure;
	FilterParameter.Insert("Condition", "InList");
	ConvertDependenciesInList(TableCopy, FilterParameter);
	FilterParameter.Condition = "NotInList";
	ConvertDependenciesInList(TableCopy, FilterParameter);
	
	Return New ValueStorage(TableCopy, New Deflation(9));
	
EndFunction

&AtServer
Procedure ConvertDependenciesInList(Table, Filter)
	For Each TableRow In Table.FindRows(Filter) Do
		For Each Item In TableRow.Value Do
			NewRow = Table.Add();
			FillPropertyValues(NewRow, TableRow);
			NewRow.Value = Item.Value;
		EndDo;
		Table.Delete(TableRow);
	EndDo;
EndProcedure

&AtServer
Function ListOfAttributesToFilter(FullMetadataObjectName, AdditionalAttributesSet)
	
	ObjectAttributes = New ValueTable;
	ObjectAttributes.Columns.Add("Attribute");
	ObjectAttributes.Columns.Add("Presentation", New TypeDescription("String"));
	ObjectAttributes.Columns.Add("ValueType", New TypeDescription);
	ObjectAttributes.Columns.Add("PictureNumber", New TypeDescription("Number"));
	ObjectAttributes.Columns.Add("ChoiceMode", New TypeDescription("FoldersAndItemsUse"));
	
	MetadataObject = Common.MetadataObjectByFullName(FullMetadataObjectName);
	
	For Each AdditionalAttribute In AdditionalAttributesSet Do
		ObjectProperties = Common.ObjectAttributesValues(AdditionalAttribute.Property, "Title, ValueType", , CurrentLanguage().LanguageCode);
		StringAttribute = ObjectAttributes.Add();
		StringAttribute.Attribute = AdditionalAttribute.Property;
		StringAttribute.Presentation = String(AdditionalAttribute.Property);
		StringAttribute.PictureNumber  = 2;
		StringAttribute.ValueType = ObjectProperties.ValueType;
	EndDo;
	
	For Each Attribute In MetadataObject.StandardAttributes Do
		AddAttributeToTable(ObjectAttributes, Attribute, True);
	EndDo;
	
	For Each Attribute In MetadataObject.Attributes Do
		AddAttributeToTable(ObjectAttributes, Attribute, False);
	EndDo;
	
	ObjectAttributes.Sort("Presentation Asc");
	
	ObjectAttributesInStorage = PutToTempStorage(ObjectAttributes, UUID);
	
	Return ObjectAttributes;
	
EndFunction

&AtServer
Procedure AddAttributeToTable(ObjectAttributes, Attribute, Standard)
	StringAttribute = ObjectAttributes.Add();
	StringAttribute.Attribute = Attribute.Name;
	StringAttribute.Presentation = Attribute.Presentation();
	StringAttribute.PictureNumber  = 1;
	StringAttribute.ValueType = Attribute.Type;
	If Standard Then
		StringAttribute.ChoiceMode = ?(Attribute.Name = "Parent", FoldersAndItemsUse.Folders, Undefined);
	Else
		StringAttribute.ChoiceMode = Attribute.ChoiceFoldersAndItems;
	EndIf;
EndProcedure

&AtClient
Procedure AttributesDependenciesSetTypeRestrictionForValue()
	
	FormTable = Items.AttributesDependencies;
	InputField    = Items.AttributesDependenciesRightValue;
	
	ChoiceParametersArray1 = New Array;
	If TypeOf(FormTable.CurrentData.Attribute) <> Type("String") Then
		ChoiceParametersArray1.Add(New ChoiceParameter("Filter.Owner", FormTable.CurrentData.Attribute));
	EndIf;
	
	ChoiceMode = FormTable.CurrentData.ChoiceMode;
	If ChoiceMode = FoldersAndItemsUse.Folders Then
		InputField.ChoiceFoldersAndItems = FoldersAndItems.Folders;
	ElsIf ChoiceMode = FoldersAndItemsUse.Items Then
		InputField.ChoiceFoldersAndItems = FoldersAndItems.Items;
	ElsIf ChoiceMode = FoldersAndItemsUse.FoldersAndItems Then
		InputField.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
	EndIf;
	
	InputField.ChoiceParameters = New FixedArray(ChoiceParametersArray1);
	If FormTable.CurrentData.Condition = "InList"
		Or FormTable.CurrentData.Condition = "NotInList" Then
		InputField.TypeRestriction = New TypeDescription("ValueList");
	Else
		InputField.TypeRestriction = FormTable.CurrentData.ValueType;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AvailabilityItem = ConditionalAppearanceItem.Appearance.Items.Find("Enabled");
	AvailabilityItem.Value = False;
	AvailabilityItem.Use = True;
	
	ComparisonValues = New ValueList;
	ComparisonValues.Add("Filled");
	ComparisonValues.Add("NotFilled"); // An exception. It's an ID.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.InList;
	DataFilterItem.RightValue = ComparisonValues;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("AttributesDependenciesRightValue");
	AppearanceFieldItem.Use = True;
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NotEqual";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Không bằng';
																		|ru = 'Не равно';
																		|en = 'Not equal to'; fa = 'نابرابر با';
																		|it = 'Non equo';
																		|pl = 'Nie równa się';
																		|tr = 'Eşit değil'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Equal";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Bằng';
																		|ru = 'Равно';
																		|en = 'Equal to'; fa = 'برابر با';
																		|it = 'Uguale';
																		|pl = 'Equal to';
																		|tr = 'Eşit'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NotFilled";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa điền';
																		|ru = 'Не заполнено';
																		|en = 'Empty'; fa = 'خالی';
																		|it = 'Non compilato';
																		|pl = 'Nie wypełnione';
																		|tr = 'Boş'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Filled";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Đã điền';
																		|ru = 'Заполнено';
																		|en = 'Filled'; fa = 'پرشده';
																		|it = 'Compilato';
																		|pl = 'Filled';
																		|tr = 'Dolduruldu'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "InList";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Trong danh sách';
																		|ru = 'В списке';
																		|en = 'In list'; fa = 'در فهرست';
																		|it = 'Nella lista';
																		|pl = 'W liście';
																		|tr = 'Listede'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesDependenciesComparisonKind.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("AttributesDependencies.Condition");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NotInList";
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Không trong danh sách';
																		|ru = 'Не в списке';
																		|en = 'Not in list'; fa = 'نه در فهرست';
																		|it = 'Non nella lista';
																		|pl = 'Nie w liście';
																		|tr = 'Listede değil'"));
	
EndProcedure

#EndRegion
