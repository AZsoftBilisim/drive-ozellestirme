
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetSelectionOnlyUnfinished(List.Filter, IncompleteOnly);
	
	SetConditionalAppearance();
		
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure IncompleteOnlyOnChange(Item)
	
	SetSelectionOnlyUnfinished(List.Filter, IncompleteOnly);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Development.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Development");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Phát triển';
													|ru = 'Разработки';
													|en = 'Development'; fa = 'توسعه';
													|it = 'Sviluppi';
													|pl = 'Opracowania';
													|tr = 'Geliştirme'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Development.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Development");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Nghiên cứu';
													|ru = 'Исследования';
													|en = 'Research'; fa = 'تحقیق';
													|it = 'Ricerche';
													|pl = 'Badania';
													|tr = 'Araştırma'"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionOnlyUnfinished(Filters, IncompleteOnly)
	
	CommonClientServer.SetFilterItem(Filters, "Completed", False,,, IncompleteOnly = 0);
	
EndProcedure

#EndRegion
