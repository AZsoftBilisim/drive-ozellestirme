
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Products") Then
		FilterProducts = Parameters.Products;
		Attributes = Common.ObjectAttributesValues(FilterProducts, New Structure("Quality"));
		If Attributes.Quality = Enums.QualityLevels.New
			Or Attributes.Quality = Enums.QualityLevels.SuitableToALimitedExtent Then
			FilterElementName = "Products";
		Else
			FilterElementName = "OtherQualityGoods";
		EndIf;
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			FilterElementName,
			FilterProducts,
			DataCompositionComparisonType.Equal,
			,
			True);
	Else
		Raise NStr("vi = 'Có thể xem danh sách hàng hóa có chất lượng khác
		                             |chỉ trong biểu mẫu mặt hàng.';
		                             |ru = 'Список товаров другого качества можно посмотреть
		                             |только в форме номенклатуры.';
		                             |en = 'You can see the list of nonconforming products
		                             |only in the form of products.'; fa = 'You can see the list of nonconforming products
		                             |only in the form of products.';
		                             |it = 'L''elenco delle merci di qualità diversa può essere visualizzato
		                             |solo sotto forma degli articoli.';
		                             |pl = 'Listę towarów o innej jakości można przeglądać tylko
		                             |w postaci pozycji.';
		                             |tr = 'Uygun kalitede olmayan ürünlerin listesi
		                             |sadece öğe formunda görüntülenebilir.'");		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	Notify("Write_AnotherQualityGoods", FilterProducts);
EndProcedure

#EndRegion

