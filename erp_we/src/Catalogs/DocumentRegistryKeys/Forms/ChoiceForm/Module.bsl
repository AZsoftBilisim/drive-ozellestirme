
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	KeyTypes = Metadata.Catalogs.DocumentRegistryKeys.Attributes.Key.Type.Types();
	
	Items.ValueType.ChoiceList.Add("", NStr("vi = '<Tất cả các loại>';
											|ru = '<Все типы>';
											|en = '<All types>'; fa = '<همه انواع>';
											|it = '<Tutti i tipi>';
											|pl = '<Wszystkie typy>';
											|tr = '<Tüm tipler>'"));
	
	For Each KeyType In KeyTypes Do
		
		TypeMetadata = Metadata.FindByType(KeyType);
		
		If TypeMetadata <> Undefined Then
			FullName = TypeMetadata.FullName();
			Items.ValueType.ChoiceList.Add(FullName, TypeMetadata.Presentation());
			EmptyValue = PredefinedValue(FullName + ".EmptyRef");
			EmptyKeyValues.Add(EmptyValue);
		EndIf;
		
	EndDo;
	
	SetConditionalAppearance();
		
	CommonClientServer.SetDynamicListParameter(List, "KeyValueType", TypeOf(Undefined));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ValueTypeOnChange(Item)
	TypeOfValueWhenChangedOnServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure TypeOfValueWhenChangedOnServer()
	
	If IsBlankString(ValueType) Then
		CommonClientServer.SetDynamicListParameter(List, "KeyValueType", TypeOf(Undefined));
	Else	
		
		KeyMetadata = Metadata.FindByFullName(ValueType);
		
		CommonClientServer.SetDynamicListParameter(List,
			"KeyValueType",
			TypeOf(KeyMetadata.StandardAttributes.Ref.Type.AdjustValue()));
	EndIf;
		
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Description.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Key");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = EmptyKeyValues;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<giá trị trống>';
													|ru = '<пустое значение>';
													|en = '<empty value>'; fa = '<empty value>';
													|it = '<valore vuoto>';
													|pl = '<pusta wartość>';
													|tr = '<boş değer>'"));
	
EndProcedure

#EndRegion

