#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Period.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Period");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Date("19800101");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Giá trị ban đầu';
													|ru = 'Начальное значение';
													|en = 'Initial value'; fa = 'مقدار اولیه';
													|it = 'Valore iniziale';
													|pl = 'Wartość początkowa';
													|tr = 'İlk değer'"));
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Country.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Country");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	If GetFunctionalOption("UseMultiCountryAccounting") Then
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa điền';
														|ru = 'Не заполнено';
														|en = 'Not filled'; fa = 'Not filled';
														|it = 'Non compilato';
														|pl = 'Nie wypełnione';
														|tr = 'Boş'"));
	Else
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tất cả';
														|ru = 'Все';
														|en = 'All'; fa = 'همه';
														|it = 'Tutti';
														|pl = 'Wszystkie';
														|tr = 'Tümü'"));
	EndIf;
EndProcedure

#EndRegion