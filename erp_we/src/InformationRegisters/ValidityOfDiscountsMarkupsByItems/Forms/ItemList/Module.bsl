
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ActionSource = Parameters.Source;
	
	AutoTitle = False;
	If TypeOf(ActionSource) = Type("CatalogRef.DiscountMarkupTerms") Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Mặt hàng được kiểm tra theo điều kiện ""%1""';
				|ru = 'Номенклатура, по которой проверяется условие ""%1""';
				|en = 'Items in which condition ""%1"" is checked'; fa = 'Items in which condition ""%1"" is checked';
				|it = 'Articoli per cui viene verificata la condizione ""%1""';
				|pl = 'Nomenklatura, w której sprawdzany jest warunek ""%1""';
				|tr = '""%1"" koşulunun kontrol edildiği öğe'"), ActionSource);
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Mặt hàng mà được chiết khấu (phụ thu) ""%1""';
				|ru = 'Номенклатура, на которую предоставляется скидка (наценка) ""%1""';
				|en = 'Items to which discount (markup) ""%1"" is provided'; fa = 'Items to which discount (markup) ""%1"" is provided';
				|it = 'Articoli per cui viene concesso lo sconto (il markup) ""%1""';
				|pl = 'Nomenklatura, dla której oferowana jest zniżka (dodatkowa opłata) ""%1""';
				|tr = '""%1"" indirim (zam) sağlanan öğe'"), ActionSource);
	EndIf;
	SliceDate = CurrentSessionDate();
	ViewOption = "OnlyValidOnes";
	
	Items.FormClose.Visible = TypeOf(ActionSource) = Type("CatalogRef.DiscountsMarkups")
		Or TypeOf(ActionSource) = Type("CatalogRef.DiscountMarkupTerms");
	
	CommonClientServer.SetDynamicListParameter(
		Goods,
		"CurrentDate",
		SliceDate,
		True);
		
	CommonClientServer.SetDynamicListParameter(
		Goods,
		"DiscountMarkup",
		ActionSource,
		True);
		
	CommonClientServer.SetFilterItem(
		Goods.Filter,
		"Status",
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"),
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(ViewOption));
		
	Items.SetStatusValid.Visible = AccessRight("Update", Metadata.InformationRegisters.ValidityOfDiscountsMarkupsByItems);
	Items.SetTheStatusNotValid.Visible = AccessRight("Update", Metadata.InformationRegisters.ValidityOfDiscountsMarkupsByItems);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

// Parameters:
// 	EventName - String - Event name
// 	Parameter - Structure - with properties:
// 		* Source - Array of CatalogRef.DiscountsMarkups - 
// 	Source - ClientApplicationForm - Event source
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ValidityOfDiscountsMarkupsByItems" And Parameter.Source.Find(ActionSource) <> Undefined Then
		UpdateProductTable();
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ArrayProducts = ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
		If ArrayProducts.Count() > 0 Then
			OpenStatusChangeForm(
				ArrayProducts,
				ActionSource,
				PredefinedValue("Enum.DiscountValidityStatuses.Valid"));
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ViewOptionOnChange(Item)
	
	CommonClientServer.SetFilterItem(
		Goods.Filter,
		"Status",
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"),
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(ViewOption));
	
	UpdateProductTable();
	
EndProcedure

&AtClient
Procedure SliceDateOnChange(Item)
	
	CommonClientServer.SetDynamicListParameter(
		Goods,
		"CurrentDate",
		SliceDate,
		True);
		
	CommonClientServer.SetDynamicListParameter(
		Goods,
		"DiscountMarkup",
		ActionSource,
		True);
	
	UpdateProductTable();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DiscountMarkupValidityHistory(Command)
	
	DiscountsMarkupsClient.OpenStatusChangeHistoryForm(ThisObject, ActionSource);
	
EndProcedure

&AtClient
Procedure SetStatusValid(Command)
	
	DiscountsMarkupsClient.OpenStatusSettingForm(
		ThisObject,
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"), 
		ActionSource);
	
EndProcedure

&AtClient
Procedure SetTheStatusNotValid(Command)
	
	DiscountsMarkupsClient.OpenStatusSettingForm(
		ThisObject,
		PredefinedValue("Enum.DiscountValidityStatuses.NotValid"),
		ActionSource);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	SetPriceCalculationOptions = New Array;
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.EmptyRef"));
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares"));
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices"));
	
	FormParameters = New Structure;
	FormParameters.Insert("ModeOfSelectionWithoutQuantitativeParameters", True);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",       True);
	FormParameters.Insert("HideTheViewPriceColumn",                  True);
	FormParameters.Insert("HideTheItemPricesCommand",         True);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",         True);
	FormParameters.Insert("HideTheRequestQuantityButton",     True);
	FormParameters.Insert("Document",                                PredefinedValue("Document.PriceSetup.EmptyRef"));
	FormParameters.Insert("Title",                               NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                    SliceDate);
	FormParameters.Insert("DoNotSplitSetsByComponents",        True);
	FormParameters.Insert("SelectionByTheOptionOfCalculatingThePricesOfSets",        SetPriceCalculationOptions);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	DiscountsMarkupsServer.SetConditionalAppearanceOfDiscountSourceForm(ConditionalAppearance, Items, "Goods");

EndProcedure

&AtClient
Procedure Attachable_ListOnActivateRow()
	
	//Current Data = Elements.Discount rates.Current Data;
	//Discount rate = ?(Current Data = Undefined OR Current data.This is a group, undefined, of current data.Discount rate);
	//
	//If Discount Rate <> Activated Discount rate Then
	//	Renewing the use of Discount rates (discount rate);
	//	Activated Discount = ?(Current Data = Undefined, Undefined, Current data.Discount rate);
	//The end if;
	
EndProcedure

&AtClient
Procedure UpdateProductTable()
	
	Items.Goods.Refresh();
	
EndProcedure

&AtClient
Procedure OpenStatusChangeForm(ItemItemPosition, Source, Status)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("StartDate", SliceDate);
	OpeningParameters.Insert("ItemItemPosition", ItemItemPosition);
	OpeningParameters.Insert("Source", Source);
	OpeningParameters.Insert("Status", Status);
	
	OpenForm(
		"Catalog.DiscountsMarkups.Form.SettingOfValidityStatus",
		OpeningParameters,
		ThisForm);
	
EndProcedure

&AtServer
Function ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	ArrayProducts = New Array;
	For Each TSRow In TableOfGoods Do
		NewRow = New Structure;
		NewRow.Insert("Products", TSRow.Products);
		NewRow.Insert("Characteristic", TSRow.Characteristic);
		ArrayProducts.Add(NewRow);
	EndDo;
	
	Return ArrayProducts;
	
EndFunction

#EndRegion
