
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "VATTaxationType", Parameters.VATTaxationType);
	CommonClientServer.SetDynamicListParameter(List, "UpdateDate", Parameters.UpdateDate);
	
	Items["ListContextMenuChange"].Visible = False;
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance() 
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BeginOfPeriod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BeginOfPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không giới hạn';
													|ru = 'Без ограничений';
													|en = 'Without restrictions'; fa = 'بدون محدودیت';
													|it = 'Senza restrizioni';
													|pl = 'Bez ograniczeń';
													|tr = 'Kısıtlamasız'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EndOfPeriod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.EndOfPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không giới hạn';
													|ru = 'Без ограничений';
													|en = 'Without restrictions'; fa = 'بدون محدودیت';
													|it = 'Senza restrizioni';
													|pl = 'Bez ograniczeń';
													|tr = 'Kısıtlamasız'"));
	
	//
	
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Country.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Country");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tất cả';
													|ru = 'Все';
													|en = 'All'; fa = 'همه';
													|it = 'Tutti';
													|pl = 'All';
													|tr = 'Tümü'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	//
	
EndProcedure

#EndRegion


