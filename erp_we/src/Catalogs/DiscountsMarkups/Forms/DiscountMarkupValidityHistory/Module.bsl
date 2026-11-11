
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Source            = Parameters.Source;
	DiscountMarkup       = Parameters.DiscountMarkup;
	ItemItemPosition = Parameters.ItemItemPosition;
	If ValueIsFilled(ItemItemPosition) Then
		Products = ItemItemPosition.Products;
		Characteristic = ItemItemPosition.Characteristic;
	EndIf;
	
	Items.ValidityOfDiscountsMarkups.Visible = ValueIsFilled(DiscountMarkup);
	Items.ValidityOfDiscountsMarkupsByItems.Visible = ValueIsFilled(ItemItemPosition);
	Items.DiscountMarkup.Visible = ValueIsFilled(DiscountMarkup);
	Items.Products.Visible = ValueIsFilled(Products);
	Items.Characteristic.Visible = ValueIsFilled(Characteristic);

	If ValueIsFilled(DiscountMarkup) Then
		
		CommonClientServer.SetDynamicListFilterItem(
			ValidityOfDiscountsMarkups,
			"DiscountMarkup",
			DiscountMarkup,
			DataCompositionComparisonType.Equal,
			,
			True);
			
		CommonClientServer.SetDynamicListFilterItem(
			ValidityOfDiscountsMarkups,
			"Source",
			Source,
			DataCompositionComparisonType.Equal,
			,
			True);
			
	EndIf;
	
	If ValueIsFilled(ItemItemPosition) Then
		
		CommonClientServer.SetDynamicListFilterItem(
			ValidityOfDiscountsMarkupsByItems,
			"Products",
			Products,
			DataCompositionComparisonType.Equal,
			,
			True);
			
		CommonClientServer.SetDynamicListFilterItem(
			ValidityOfDiscountsMarkupsByItems,
			"Characteristic",
			Characteristic,
			DataCompositionComparisonType.Equal,
			,
			True);
			
		CommonClientServer.SetDynamicListFilterItem(
			ValidityOfDiscountsMarkupsByItems,
			"Source",
			Source,
			DataCompositionComparisonType.Equal,
			,
			True);
			
	EndIf;
	
	If Not ValueIsFilled(Source) Then
		Items.Source.Visible = False;
	Else
		
		If TypeOf(Source) = Type("CatalogRef.Warehouses") Then
			Items.Source.Title = NStr("vi = 'Kho bãi';
										|ru = 'Склад';
										|en = 'Warehouse'; fa = 'Warehouse';
										|it = 'Magazzino';
										|pl = 'Magazyn';
										|tr = 'Ambar'");
		ElsIf TypeOf(Source) = Type("CatalogRef.TermsOfSale") Then
			Items.Source.Title = NStr("vi = 'Thỏa thuận';
										|ru = 'Соглашение';
										|en = 'Agreement'; fa = 'توافق‌نامه';
										|it = 'Accordo';
										|pl = 'Porozumienie:';
										|tr = 'Anlaşma'");
		ElsIf TypeOf(Source) = Type("CatalogRef.LoyaltyCardKinds") Then
			Items.Source.Title = NStr("vi = 'Dạng thẻ khách hàng thân thiết';
										|ru = 'Вид карты лояльности';
										|en = 'Loyalty card kind'; fa = 'نوع کارت وفاداری';
										|it = 'Tipo di carta di fedeltà';
										|pl = 'Rodzaj karty lojalnościowej';
										|tr = 'Sadakat kartı türü'");
		ElsIf TypeOf(Source) = Type("CatalogRef.DiscountsMarkups") Then
			Items.Source.Title = NStr("vi = 'Chiết khấu (phụ thu)';
										|ru = 'Скидка (наценка)';
										|en = 'Discount (markup)'; fa = 'تخفیف (افزایش قیمت)';
										|it = 'Sconto (sovrapprezzo)';
										|pl = 'Rabat (marża)';
										|tr = 'İndirim (zam)'");
		ElsIf TypeOf(Source) = Type("CatalogRef.DiscountMarkupTerms") Then
			Items.Source.Title = NStr("vi = 'Điều kiện cho phép';
										|ru = 'Условие предоставления';
										|en = 'Term'; fa = 'شرط';
										|it = 'Condizione della concessione';
										|pl = 'Warunek nadania';
										|tr = 'Sağlama şartı'");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ListEventHandlers

&AtClient
Procedure ValidityOfDiscountsMarkupsAfterDeleteRow(Item)
	
	ArrayDiscountsMargins = New Array;
	ArraySources = New Array;
	
	ArrayDiscountsMargins.Add(DiscountMarkup);
	ArraySources.Add(Source);
	
	Parameter = New Structure;
	Parameter.Insert("DiscountMarkup", ArrayDiscountsMargins);
	Parameter.Insert("Source", ArraySources);
	
	Notify("Write_ValidityOfDiscountsMarkups", Parameter, ThisForm);
	
EndProcedure

&AtClient
Procedure ValidityOfDiscountsMarkupsByItemsAfterDeleteRow(Item)
	
	ArraySources = New Array;
	ArraySources.Add(Source);
	
	Parameter = New Structure;
	Parameter.Insert("Source", ArraySources);
	
	Notify("Write_ValidityOfDiscountsMarkupsByItems", Parameter, ThisForm);
	
EndProcedure

#EndRegion