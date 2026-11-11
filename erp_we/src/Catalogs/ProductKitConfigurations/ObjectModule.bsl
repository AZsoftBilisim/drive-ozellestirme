#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	NotCheckedAttributeArray = New Array;
	UseCharacteristics = GetFunctionalOption("UseItemVariants");
	// Checking the filling of characteristics, including goods.
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	
	QuantityVerificationParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	QuantityVerificationParameters.CheckPossibilityOfRounding = False;
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters);

	// Checking the filling of the characteristics in the header.
	If Not UseCharacteristics Or Not Catalogs.Products.ItemVariantsAreUsed(Owner) Then

		NotCheckedAttributeArray.Add("Characteristic");

	EndIf;
	
	CheckComponentCharacteristics = 
		UseCharacteristics And Not ValueIsFilled(MainComponentCharacteristic)
		And Catalogs.Products.ItemVariantsAreUsed(ProductsOfMainComponent);
	If CheckComponentCharacteristics Then
		CheckedAttributes.Add("MainComponentCharacteristic");
	EndIf;
	
	If ValueIsFilled(ProductsOfMainComponent) Then
		FilterOfProducts_ =
			New Structure("Products, Characteristic", ProductsOfMainComponent, MainComponentCharacteristic);
		ViewOfTheMainComponent =
			ProductsClientServer.ProductPresentation(ProductsOfMainComponent, MainComponentCharacteristic);
		If Goods.FindRows(FilterOfProducts_).Count() = 0 Then
			MessageText = NStr("vi = 'Thành phần chính `%ProductName_%` không được tìm thấy trong hàng hóa. 
				|Chỉ định thành phần chính từ danh sách hàng hóa';
				|ru = 'Основной компонент `%ProductName_%` в товарах не найден.
				|Укажите основной компонент из перечня товаров';
				|en = 'Main component ""%ProductName_%"" is not found in the list of goods.
				|Choose a main component from the list of goods'; fa = 'Main component ""%ProductName_%"" is not found in the list of goods.
				|Choose a main component from the list of goods';
				|it = 'Il componente principale `%ProductName_%` non è stato trovato nelle merci. 
				| Indicare il componente dalla lista della merce.';
				|pl = 'Głównego komponentu `%ProductName_%` w towarach nie znaleziono.
				|Podaj główny komponent z wykazu towarów';
				|tr = '`%ProductName_%` ana bileşeni ürünlerde bulunamadı.
				|Lütfen ürün listesinden ana bileşeni seçin'");
			MessageText = StrReplace(MessageText, "%ProductName_%", ViewOfTheMainComponent);
			
			Common.MessageToUser(MessageText, , , "Object", Cancel);
		EndIf;
	EndIf;
	
	FilterOfProducts_ = New Structure("Products, Characteristic", Owner, Characteristic);
	OwnerPresentation = ProductsClientServer.ProductPresentation(Owner, Characteristic);
	For Each TSRow In Goods.FindRows(FilterOfProducts_) Do
		MessageText = NStr("vi = 'Trong dòng %LineNumber% đã chỉ định hàng hóa ""%ProductName_%"".
			|Một hàng hóa không thể đồng thời là một bộ và là một thành phần.';
			|ru = 'В строке %LineNumber% указан товар ""%ProductName_%"".
			|Один и тот же товар не может являться и комплектом, и комплектующей одновременно.';
			|en = 'You have specified ""%ProductName_%"" in line %LineNumber%.
			|The same product cannot be both a set and a component.'; fa = 'You have specified ""%ProductName_%"" in line %LineNumber%.
			|The same product cannot be both a set and a component.';
			|it = 'La riga %LineNumber% contiene il prodotto ""%ProductName_%"".
			|Il prodotto non può essere un insieme e un componente allo stesso tempo.';
			|pl = 'W wierszu %LineNumber% jest podany towar ""%ProductName_%"".
			|Jeden i ten sam towar nie może być jednocześnie kompletem i komponentem.';
			|tr = '%LineNumber% satırında ürün belirtildi ""%ProductName_%"". 
			|Aynı ürün aynı anda hem set hem de bileşen olamaz.'");
		MessageText = StrReplace(MessageText, "%ProductName_%", OwnerPresentation);
		MessageText = StrReplace(MessageText, "%LineNumber%", TSRow.LineNumber);
		
		Field = CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "Products");
		Common.MessageToUser(MessageText, , Field, "Object", Cancel);
	EndDo;
	
	ItemsType = Common.ObjectAttributeValue(Owner, "ItemsType");
	If ItemsType = Enums.ItemsTypes.Set Then
		NotCheckedAttributeArray.Add("NumberOfPackages");
		NotCheckedAttributeArray.Add("Count");
		NotCheckedAttributeArray.Add("Description");
		If SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares Then
			CheckedAttributes.Add("Goods.CostShare");
		EndIf;
	Else
		QuantityVerificationParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		QuantityVerificationParameters.TSName = "Object";
		QuantityVerificationParameters.CheckPossibilityOfRounding = False;
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters);
	EndIf;
	
	If ItemsType = Enums.ItemsTypes.Set
		And PresentationOptionInPrintForms <> Enums.OptionsOfSetPresentationInPrintForms.OnlyComponents Then
		
		Query = New Query(
		"SELECT DISTINCT TOP 2
		|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
		|		VALUE(Catalog.VATRates.EmptyRef))) AS VATRate,
		|	ISNULL(ProductsVATRates.Country, ISNULL(BasicVATRates.Country,
		|		VALUE(Catalog.WorldCountries.EmptyRef))) AS Country
		|FROM
		|	Catalog.Products AS CatalogProducts
		|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(, Products IN (&ProductsArray)) AS
		|			ProductsVATRates
		|		ON CatalogProducts.Ref = ProductsVATRates.Products
		|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast() AS BasicVATRates
		|		ON (TRUE)
		|WHERE
		|	CatalogProducts.Ref IN (&ProductsArray)
		|TOTALS
		|BY
		|	Country");
		
		Query.SetParameter("ProductsArray", Goods.UnloadColumn("Products"));
		
		Result = Query.Execute();
		
		SampleCountry = Result.Select(QueryResultIteration.ByGroups);
		While SampleCountry.Next() Do
		
			SelectionDetailRecords = SampleCountry.Select();
			If SelectionDetailRecords.Count() > 1 Then
				UserMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong bộ sản phẩm có các mặt hàng với thuế suất GTGT khác nhau tại %1.
					           |Đối với các bộ sản phẩm này, trong mẫu in chỉ có thể hiển thị các thành phần chi tiết.';
					           |ru = 'В составе набора присутствуют позиции номенклатуры с разными ставками НДС в стране %1.
					           |Для таких наборов в печатных формах можно выводить только комплектующие.';
					           |en = 'The set contains product items with different VAT rates in %1.
					           |Print forms for such sets can include components only.'; fa = 'The set contains product items with different VAT rates in %1.
					           |Print forms for such sets can include components only.';
					           |it = 'Nella composizione del set, vi sono posizioni di nomenclatura con aliquote IVA differente nel paese %1.
					           |Per questi set, solo gli accessori possono essere visualizzati su forme di stampa.';
					           |pl = 'W składzie zestawu istnieją pozycję towaru z różnymi stawkami VAT w kraju %1.
					           |Dla takich zestawów w formularzach wydruku można pokazywać tylko części.';
					           |tr = 'Küme, %1 ülkesinde farklı KDV oranlarına sahip stok kalemleri içeriyor.
					           |Bu tür kümeler için, yazdırma formlarında yalnızca bileşenler görüntülenebilir.'"),
					SampleCountry.Country);
					           
				Common.MessageToUser(UserMessage,,
					"PresentationOptionInPrintForms""
					|""Object", Cancel);
				
			EndIf;
		EndDo;
		
	EndIf;
	
	CheckParameters = Catalogs.ProductKitConfigurations.SetValidationParameters(ThisObject);
	
	AccountingForTraceableGoodsLocalization.CheckIfKitIsCorrect(ThisObject, Cancel, CheckParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)

	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Owner", Owner) And ValueIsFilled(Owner) Then

		FillingData.Property("Characteristic", Characteristic);

		Main = Not ThereIsBasicConfigurationOption(Owner, Characteristic);

	EndIf;

EndProcedure

Procedure OnCopy(CopiedObject)

	ItemsType = Common.ObjectAttributeValue(Owner, "ItemsType");
	If ItemsType = Enums.ItemsTypes.Set Then
		Raise NStr("vi = 'Không cần sao chép thành phần bộ sản phẩm';
					|ru = 'Копирование состава набора не требуется';
					|en = 'Copying the set content is not required'; fa = 'Copying the set content is not required';
					|it = 'Non è richiesta alcuna copia di composizione del set';
					|pl = 'Kopiowanie składu zestawu nie jest konieczne';
					|tr = 'Kümenin içeriğinin kopyalanması gerekli değildir'");
	EndIf;
	
	Main = Not ThereIsBasicConfigurationOption(Owner, Characteristic);

EndProcedure

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	ItemsType = Common.ObjectAttributeValue(Owner, "ItemsType");
	If ItemsType = Enums.ItemsTypes.Set Then
		
		TableOfProducts = Goods.Unload(,"Products");
		Query = New Query("
		|SELECT
		|	T.Products
		|INTO Table
		|FROM
		|	&Table AS T
		|;
		|
		|SELECT DISTINCT
		|	T.Products.ItemsType AS ItemsType
		|FROM
		|	Table AS T
		|");
		Query.SetParameter("Table", TableOfProducts);
		ItemsTypes = Query.Execute().Unload().UnloadColumn("ItemsType");
		
		ContainsGoods = ItemsTypes.Find(Enums.ItemsTypes.OwnGoods) <> Undefined
		             Or ItemsTypes.Find(Enums.ItemsTypes.ReusablePackage) <> Undefined;
		
		ContainsServices = ItemsTypes.Find(Enums.ItemsTypes.OperationService) <> Undefined
		             Or ItemsTypes.Find(Enums.ItemsTypes.Work_5) <> Undefined;
		
		NumberOfPackages = 1;
		Count         = 1;
		Description       = NStr("vi = 'Thành phần bộ đóng gói';
								|ru = 'Состав набора';
								|en = 'Set content'; fa = 'محتوای مجموعه';
								|it = 'Composizione del set';
								|pl = 'Skład zestawu';
								|tr = 'Set kapsamı'") + " (" + Goods.Count() + ")";
		Main           = True;
		
	Else
	
		If Main And (True <> Common.ObjectAttributeValue(Ref, "Main")) Then

			SetPrivilegedMode(True);

			Query = New Query(
			"SELECT
			|	Table.Ref AS Ref
			|FROM
			|	Catalog.ProductKitConfigurations AS Table
			|WHERE
			|	Table.Owner         = &Owner
			|	AND Table.Characteristic = &Characteristic
			|	AND Table.Main
			|	AND Table.Ref <> &Ref
			|");
			Query.SetParameter("Owner", Owner);
			Query.SetParameter("Characteristic", Characteristic);
			Query.SetParameter("Ref", Ref);
			Selection = Query.Execute().Select();
			While Selection.Next() Do

				Object = Selection.Ref.GetObject(); // CatalogObject.ProductKitConfigurations - 
				Object.Main = False;
				Object.Write();

			EndDo;

		EndIf;
	
	EndIf;
	
	If Not Catalogs.Products.ItemVariantsAreUsed(ProductsOfMainComponent) Then
		MainComponentCharacteristic = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Function ThereIsBasicConfigurationOption(Products, ProductCharacteristic = Undefined)

	QueryText = 
	"SELECT TOP 1
	|	1
	|FROM
	|	Catalog.ProductKitConfigurations AS Table
	|WHERE
	|	Table.Owner = &Products
	|	AND Table.Main
	|";
	If ValueIsFilled(ProductCharacteristic) Then
		QueryText = QueryText + " AND Table.Characteristic = &Characteristic ";
	EndIf;

	Query = New Query(QueryText);
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", ProductCharacteristic);
	Return Not Query.Execute().IsEmpty();

EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
