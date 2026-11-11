#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	VATTaxationType = Parameters.VATTaxationType;
	
	CommonClientServer.SetDynamicListParameter(List, "VATTaxationType", VATTaxationType);
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure FilterCountryOnChange(Item)
	
	FilterList = ListForSelectionByCountry(Country);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Country", FilterList, DataCompositionComparisonType.InList, , ValueIsFilled(Country));
		
EndProcedure

&AtClient
Procedure FilterPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SelectionGroupStartOfPeriod = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Đầu kỳ';
			|ru = 'Начало периода';
			|en = 'Period start'; fa = 'شروع دوره';
			|it = 'Inizio del periodo';
			|pl = 'Początek okresu';
			|tr = 'Dönem başı'"),
		DataCompositionFilterItemsGroupType.OrGroup);

	CommonClientServer.AddCompositionItem(
		SelectionGroupStartOfPeriod,
		"BeginOfPeriod",
		DataCompositionComparisonType.LessOrEqual,
		Period,,
		ValueIsFilled(Period));

	CommonClientServer.AddCompositionItem(
		SelectionGroupStartOfPeriod,
		"BeginOfPeriod",
		DataCompositionComparisonType.NotFilled,
		Period,,
		ValueIsFilled(Period));
		
	SelectionGroupEndOfPeriod = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Cuối kỳ';
			|ru = 'Конец периода';
			|en = 'Period end'; fa = 'پایان دوره';
			|it = 'Fine del periodo';
			|pl = 'Koniec okresu';
			|tr = 'Dönem sonu'"),
		DataCompositionFilterItemsGroupType.OrGroup);

	CommonClientServer.AddCompositionItem(
		SelectionGroupEndOfPeriod,
		"EndOfPeriod",
		DataCompositionComparisonType.GreaterOrEqual,
		Period,,
		ValueIsFilled(Period));

	CommonClientServer.AddCompositionItem(
		SelectionGroupEndOfPeriod,
		"EndOfPeriod",
		DataCompositionComparisonType.NotFilled,
		Period,,
		ValueIsFilled(Period));

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
	FormParameters = New Structure;
	
	If ValueIsFilled(VATTaxationType) Then
		FormParameters.Insert("FillingValues", New Structure("VATTaxationType", VATTaxationType));
	EndIf;
	
	If Copy And Item.CurrentData <> Undefined Then
		FormParameters.Insert("CopyingValue", Item.CurrentRow);
	EndIf;
	
	OpenForm("Catalog.VATRates.ObjectForm", FormParameters, Items.List);
	
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

&AtServer
Function ListForSelectionByCountry(Country)
	
	FilterList = New ValueList;
	FilterList.Add(Catalogs.WorldCountries.EmptyRef());
	FilterList.Add(Country);
	
	Return FilterList;
	
EndFunction 

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_Period" Then
		FilterPeriodOnChange(Items.FilterPeriod);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
