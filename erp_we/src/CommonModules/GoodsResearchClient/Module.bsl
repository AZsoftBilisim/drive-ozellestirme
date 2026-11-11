#Region Public

#Region GoodsResearchSheets

// Sets a new Status for Product research mapping
//
// Parameters:
//	NewStatus				- EnumRef.StatusesOfGoodsResearchSheet - New status
//	StatusPresentation	- String - the introduction of the new status
//  ArrayOfItemResearchMaps		- Array of CatalogRef.GoodsResearchSheets - List of Product research maps.
//
Procedure SetStatusOfGoodsResearchCards(NewStatus, StatusPresentation, ArrayOfItemResearchMaps) Export
	
	If ArrayOfItemResearchMaps.Count() = 0 Then
		Return
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StatusValue",      NewStatus);
	AdditionalParameters.Insert("StatusPresentation", StatusPresentation);
	AdditionalParameters.Insert("HighlightedLinks",     ArrayOfItemResearchMaps);
	CallbackDescription = New CallbackDescription("SetStatusOfGoodsResearchCardsCompletion", ThisObject, AdditionalParameters);
	
	QueryText = NStr("ru = 'Выбранным картам исследования товаров будет установлен статус ""%1"". Продолжить?';
					|vi = 'The ""%1"" status will be set for the selected goods research sheets. Continue?';
					|en = 'The ""%1"" status will be set for the selected goods research sheets. Continue?'; fa = 'The ""%1"" status will be set for the selected goods research sheets. Continue?';
					|it = 'The ""%1"" status will be set for the selected goods research sheets. Continue?';
					|pl = 'The ""%1"" status will be set for the selected goods research sheets. Continue?';
					|tr = 'Seçili ürün araştırma kartlarına ""%1 "" durumu atanacak. Devam edilsin mi?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, StatusPresentation);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure SetStatusOfGoodsResearchCardsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = GoodsResearchServerCall.SetStatusOfGoodsResearchCards(
										AdditionalParameters.HighlightedLinks, 
										AdditionalParameters.StatusValue);
										
	TMCommonUseClient.NotifyUserAboutSettingStatus(
			Undefined,
			ProcessedItemsCount, 
			AdditionalParameters.HighlightedLinks.Count(), 
			AdditionalParameters.StatusPresentation);
			
	Notify("Write_GoodsResearchSheets");
	NotifyChanged(Type("CatalogRef.GoodsResearchSheets"));
	
EndProcedure

#Region SelectionByProperties

Procedure UpdateSelectionSettingsByPropertiesByKey(Table, Setting, ConnectionKey) Export
	
	TheStructureOfTheSearch = New Structure("ConnectionKey", ConnectionKey);
	StringsList = Table.FindRows(TheStructureOfTheSearch);
	For Each StringCondition In StringsList Do
		Table.Delete(StringCondition);
	EndDo;
	
	For Each Condition In Setting Do
		NewRow = Table.Add();
		FillPropertyValues(NewRow, Condition);
		NewRow.ConnectionKey = ConnectionKey;
	EndDo;
	
EndProcedure

Procedure UpdateTablePart(Table, Setting) Export
	
	Table.Clear();
	
	For Each String In Setting Do
		NewRow = Table.Add();
		FillPropertyValues(NewRow, String);
	EndDo;
	
EndProcedure

// Converts settings from a table to an array of structures by the specified row.
//
// Parameters:
//   RowData - Structure - The row data to search in the settings table
//   SettingsTable - ValueTable - Table containing settings
//   AttributesList - String - List of Attributes to include in the resulting structure
//
// Returns:
// 	Array of Structure:
//   * Fields - Arbitrary - Array of structures with settings Attributes
Function DetailsOfSettingsByLineInArray(RowData, SettingsTable, AttributesList) Export
	
	Result = New Array;
	
	TheStructureOfTheSearch = New Structure("ConnectionKey", RowData.ConnectionKey);
	
	StringsList = SettingsTable.FindRows(TheStructureOfTheSearch);
	For Each String In StringsList Do
		StringDataStructure = New Structure(AttributesList);
		FillPropertyValues(StringDataStructure, String);
		Result.Add(StringDataStructure);
	EndDo; 
	
	Return Result;
	
EndFunction

// Parameters:
//   ValueTable - ValueTable - table of values to convert
// Returns:
// 	Array of Structure:
//   * Fields - Arbitrary - the fields correspond to the columns passed in the values table.
Function TableIntoStructuresArray(Val ValueTable) Export
	
	Result = New Array;
	
	ColumnsNames = "";
	For Each Column In ValueTable.Columns Do
		ColumnsNames = ColumnsNames + "," + Column.Name;
	EndDo;
	ColumnsNames = Mid(ColumnsNames, 2);
	
	For Each String In ValueTable Do
		StringStructure = New Structure(ColumnsNames);
		FillPropertyValues(StringStructure, String);
		Result.Add(StringStructure);
	EndDo;
	
	Return Result;
	
EndFunction

// Converts a table of values into an array of structures
// 
// Parameters:
// 	ValueTable - ValueTable - table of values to convert
// 	AttributesList - Structure - list of Bank details
// Returns:
// 	Array of Structure:
//   * Fields - Arbitrary - The fields correspond to the columns passed in the list of requests.
Function DetailsOfTableInArrayOfStructures(Val ValueTable, AttributesList) Export
	
	Result = New Array;
	
	For Each String In ValueTable Do
		StringStructure = New Structure(AttributesList);
		FillPropertyValues(StringStructure, String);
		Result.Add(StringStructure);
	EndDo;
	
	Return Result;
	
EndFunction

Procedure SelectionByPropertiesBeforeRowChange(
	Form,
	CurrentData,
	TableOfAvailableProperties,
	ConditionsStructure) Export
	
	PropertyTableRows = 
		TableOfAvailableProperties.FindRows(New Structure("Property", CurrentData.Property));
		
	If Not ValueIsFilled(PropertyTableRows) Then
		Return;
	EndIf;
	
	PropertySelectionSetTypeConstraintForValue(Form, CurrentData, ConditionsStructure, PropertyTableRows[0].ValueType);
	
EndProcedure

Procedure SelectionOfPropertiesPropertyIsWhenYouChange(
	Form,
	CurrentData,
	TableOfAvailableProperties,
	ConditionsStructure) Export
	
	PropertyTableRows = 
		TableOfAvailableProperties.FindRows(New Structure("Property", CurrentData.Property));
		
	If Not ValueIsFilled(PropertyTableRows) Then
		Return;
	EndIf;
	
	CurrentData.Condition  = "Equal";
	
	TypeOfValueGiven = 
		PropertySelectionSetTypeConstraintForValue(Form, CurrentData, ConditionsStructure, PropertyTableRows[0].ValueType);
	
	CurrentData.Value = TypeOfValueGiven.AdjustValue(Undefined);
	
EndProcedure

Procedure TheSelectionOfThePropertiesSubjectToChange(
	Form,
	CurrentData,
	TableOfAvailableProperties,
	ConditionsStructure) Export
	
	PropertyTableRows = 
		TableOfAvailableProperties.FindRows(New Structure("Property", CurrentData.Property));
		
	If Not ValueIsFilled(PropertyTableRows) Then
		Return;
	EndIf;
	
	CurrentCondition = ConditionsStructure[CurrentData.Condition];
	
	TypeOfValueGiven = 
		PropertySelectionSetTypeConstraintForValue(Form, CurrentData, ConditionsStructure, PropertyTableRows[0].ValueType);
	
	If CurrentCondition.List Then
		
		CurrentData.Value = New ValueList;
		CurrentData.Value.ValueType = TypeOfValueGiven;
		
	Else
		
		If CurrentCondition.Interval Or CurrentCondition.Fullness Then
			CurrentData.Value = Undefined;
		EndIf;
		
		CurrentData.Value = TypeOfValueGiven.AdjustValue(CurrentData.Value);
		
	EndIf;
	
	For IndexOf = 1 To 2 Do
		CurrentData["Value"+IndexOf] = TypeOfValueGiven.AdjustValue(Undefined);
	EndDo;
	
EndProcedure

// Handler for the start of the selection conditions for the selection of properties
// 
// Parameters:
// 	Form - ClientApplicationForm- Form
// 	CurrentData - FormDataCollectionItem - row of the table forms
// 	TableOfAvailableProperties - ValueTable - available properties
// 	ConditionsStructure - Structure - Conditions
Procedure SelectionOfPropertiesTheConditionOfTheBeginningOfTheSelection(
	Form,
	CurrentData,
	TableOfAvailableProperties,
	ConditionsStructure) Export
	
	ChoiceList = Form.Items.Condition.ChoiceList;
	ChoiceList.Clear();
	
	PropertyTableRows = 
		TableOfAvailableProperties.FindRows(New Structure("Property", CurrentData.Property));
		
	If Not ValueIsFilled(PropertyTableRows) Then
		Return;
	EndIf;
	
	For Each KeyAndValue In ConditionsStructure Do
		Condition = KeyAndValue.Value; // See GoodsResearchClientServer.StructureOfSelectionConditionByProductProperties
		If Condition.Comparison 
			And Not PropertyTableRows[0].ValueType.ContainsType(Type("Number"))
			And Not PropertyTableRows[0].ValueType.ContainsType(Type("Date"))
		Then
			Continue;
		EndIf;
		ChoiceList.Add(Condition.Id, Condition.Presentation);
	EndDo;
	
EndProcedure

Procedure SelectionByPropertiesValueIntervalWhenChanging(CurrentData, AttributeName) Export

	ValueTypeFilter = New TypeDescription(
		CommonClientServer.ValueInArray(TypeOf(CurrentData[AttributeName])));
	
	For IndexOf = 1 To 2 Do
		CurrentData["Value"+IndexOf] = ValueTypeFilter.AdjustValue(CurrentData["Value"+IndexOf]);
	EndDo;
	
EndProcedure

// Sets the type restriction for the selection element by properties
// 
// Parameters:
// 	Form - ClientApplicationForm- Form
// 	CurrentData - FormDataCollectionItem - Form table row - from:
// 		* Condition - String - condition ID
// 	ConditionsStructure - Structure - Conditions
// 	ValueType - TypeDescription - the value type of the source
// Returns:
// 	TypeDescription - the type of value given
Function PropertySelectionSetTypeConstraintForValue(
	Form,
	CurrentData,
	ConditionsStructure,
	ValueType) Export
	
	CurrentCondition = ConditionsStructure[CurrentData.Condition]; // See GoodsResearchClientServer.StructureOfSelectionConditionByProductProperties
	
	If CurrentCondition.Comparison Then
		RemovedTypes = New Array;
		For Each Type In ValueType.Types() Do
			If Not Type = Type("Date") And Not Type = Type("Number") Then
				RemovedTypes.Add(Type);
			EndIf;
		EndDo;
		TypeOfValueGiven = New TypeDescription(ValueType,,RemovedTypes);
	Else
		TypeOfValueGiven = ValueType;
	EndIf;
	
	ChoiceParameters = New Array;
	If ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.Owner", CurrentData.Property));
	EndIf;
	
	Form.Items.Value.ChoiceParameters = New FixedArray(ChoiceParameters);
	If CurrentCondition.List Then
		Form.Items.Value.TypeRestriction = New TypeDescription("ValueList");
	ElsIf CurrentCondition.Interval Then
		Form.Items.Value1.TypeRestriction = TypeOfValueGiven;
		Form.Items.Value2.TypeRestriction = TypeOfValueGiven;
	Else
		Form.Items.Value.TypeRestriction  = TypeOfValueGiven;
	EndIf;
	
	Return TypeOfValueGiven;
	
EndFunction

// Checks whether the selection by properties is configured correctly
// 
// Parameters:
// 	SelectionByProperties - FormDataCollection - table of set selections
// 	TableOfAvailableProperties - FormDataCollection - property sheet
// 	HasErrors - Boolean - a sign of the presence of errors
// Returns:
// 	Array - array of configuration items
//
Function SelectionByPropertiesPerformControlGenerateResultOfSetting(
	SelectionByProperties,
	TableOfAvailableProperties,
	HasErrors) Export
	
	TemplateFieldNotFilledIn  = NStr("vi = 'Lỗi điền cài đặt trên dòng  %1.';
									|ru = 'Ошибка заполнения настройки в строке %1.';
									|en = 'An error occurred when filling in settings in line %1.'; fa = 'An error occurred when filling in settings in line %1.';
									|it = 'Errore durante la compilazione dell''impostazione nella riga %1.';
									|pl = 'Błąd wypełnienia ustawienia w wierszu %1.';
									|tr = '%1 satırındaki ayar doldurma hatası.'");
	TemplateInvalidProperty = NStr("vi = 'Thuộc tính được chỉ định không hợp lệ trên dòng  %1.';
									|ru = 'Указано неверное свойство в строке %1.';
									|en = 'Incorrect property is specified in line %1.'; fa = 'Incorrect property is specified in line %1.';
									|it = 'Parametro incorretto indicato nella riga %1.';
									|pl = 'Wskazano nieprawidłową właściwość w wierszu %1.';
									|tr = '%1 satırında yanlış özellik belirtildi.'");
	TemplateInvalidCondition  = NStr("vi = 'Lỗi điền cài đặt trên dòng  %1. Giá trị bên trái không thể lớn hơn bên phải.';
									|ru = 'Ошибка заполнения настройки в строке %1. Левое значение не может быть больше правого.';
									|en = 'An error occurred when filling in settings in line %1. The left value cannot be greater than the right one.'; fa = 'An error occurred when filling in settings in line %1. The left value cannot be greater than the right one.';
									|it = 'Errore di compilazione dell''impostazione nella riga %1. Il valore sinistro non può essere maggiore di quello destro.';
									|pl = 'Błąd wypełnienia ustawienia w wierszu %1. Lewa wartość nie może być większa od prawej.';
									|tr = '%1 satırındaki ayar doldurma hatası. Soldaki değer, sağdakinden büyük olamaz.'");
	DataPathTemplate      = "SelectionByProperties[%1].%2";
	
	Attributes        = DetailsSettingUpSelectionByProperties();
	ConditionsStructure = GoodsResearchClientServer.StructureOfSelectionConditionsByProductProperties();
	
	Result = New Array;
	
	For Each FIlterRow In SelectionByProperties Do
		
		If IsBlankString(FIlterRow.Condition) Then
			Continue;
		EndIf;
		
		RowIndex = SelectionByProperties.IndexOf(FIlterRow);
		
		CurrentCondition = ConditionsStructure[FIlterRow.Condition]; // See GoodsResearchClientServer.StructureOfSelectionConditionByProductProperties
		
		If CurrentCondition.Interval Then
			If FIlterRow.Value1 <> Undefined
				And FIlterRow.Value2 <> Undefined
				And FIlterRow.Value1 > FIlterRow.Value2 Then
				CommonClient.MessageToUser(
					StrTemplate(TemplateInvalidCondition,RowIndex+1),,
					StrTemplate(DataPathTemplate, RowIndex, "Value1"),,
					HasErrors);
				Continue;
			EndIf;
			VerificationFields = StrSplit(StrReplace(Attributes,"Value","Value1,Value2"), ",");
		Else
			VerificationFields = StrSplit(Attributes, ",");
		EndIf;
		
		For Each Field In VerificationFields Do
			If Not ValueIsFilled(FIlterRow[Field])
				And Not FIlterRow[Field] = 0 
				And Not CurrentCondition.Fullness Then
				CommonClient.MessageToUser(
					StrTemplate(TemplateFieldNotFilledIn,RowIndex+1),,
					StrTemplate(DataPathTemplate, RowIndex, Field),,
					HasErrors);
			ElsIf Field = "Property" 
					And TableOfAvailableProperties.FindRows(New Structure("Property", FIlterRow[Field])).Count() = 0 Then
				CommonClient.MessageToUser(
					StrTemplate(TemplateInvalidProperty,RowIndex+1),,
					StrTemplate(DataPathTemplate, RowIndex, Field),,
					HasErrors);
			EndIf;
		EndDo;
		
		If HasErrors Then
			Continue;
		EndIf;
		
		If CurrentCondition.List Then
			For Each ListItem In FIlterRow.Value Do
				ConditionSettingsElement = New Structure(Attributes);
				FillPropertyValues(ConditionSettingsElement, FIlterRow);
				ConditionSettingsElement.Value = ListItem.Value;
				Result.Add(ConditionSettingsElement);
			EndDo;
		ElsIf CurrentCondition.Interval Then
			ConditionSettingsElement = New Structure(Attributes);
			ConditionSettingsElement.Property = FIlterRow.Property;
			ConditionSettingsElement.Condition  = ?(CurrentCondition.Id = "InInterval", "Greater", "GreaterOrEqual");
			ConditionSettingsElement.Value = FIlterRow.Value1;
			Result.Add(ConditionSettingsElement);
			
			ConditionSettingsElement = New Structure(Attributes);
			ConditionSettingsElement.Property = FIlterRow.Property;
			ConditionSettingsElement.Condition  = ?(CurrentCondition.Id = "InInterval", "Less", "LessOrEqual");
			ConditionSettingsElement.Value = FIlterRow.Value2;
			Result.Add(ConditionSettingsElement);
		Else
			ConditionSettingsElement = New Structure(Attributes);
			FillPropertyValues(ConditionSettingsElement, FIlterRow);
			Result.Add(ConditionSettingsElement);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the Attributes used to configure the selection by properties.
//
// Returns:
//   String - comma-separated list of Attributes for setting up selection by properties
Function DetailsSettingUpSelectionByProperties() Export
	
	Return "Property,Condition,Value";
	
EndFunction

// Returns a list of Attributes used for selection by properties.
//
// Returns:
//   String - comma-separated list of Attributes
Function DetailsOfSelectionByProperties() Export
	
	Return "ConnectionKey,Property,Condition,Value";
	
EndFunction

// Returns a list of Attributes used for assigning research.
//
// Returns:
//   String - comma-separated list of Attributes
Function AttributesOfGoodsLineOfQualityControlRequest() Export
	
	Return "LineNumber,Products,Characteristic,ProductKind,UnitOfMeasure,Warehouse,Purpose,Series,Package,Count,NumberOfPackages,ControlledLotReference";
	
EndFunction

#EndRegion

#Region ItemList

// Returns a list of Attributes used when setting up the item list.
//
// Returns:
//   String - comma-separated list of Attributes
Function AttributesSetupItemList() Export
	
	Return "Products,Characteristic,ProductKind";
	
EndFunction

#EndRegion

#EndRegion
