
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
	ItemField.Field = New DataCompositionField(Items.Department.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LineOfBusiness.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ConstructionMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Trùng với dữ liệu kế toán';
													|ru = 'Совпадает с данными учета';
													|en = 'Matches the accounting data'; fa = 'Matches the accounting data';
													|it = 'Совпадает с данными учета';
													|pl = 'Matches the accounting data';
													|tr = 'Vergi muhasebesi ile örtüşmektedir'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
EndProcedure

#EndRegion
