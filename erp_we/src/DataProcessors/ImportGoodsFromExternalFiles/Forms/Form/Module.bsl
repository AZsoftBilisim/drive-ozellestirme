#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If IsBlankString(Parameters.Title) Then
		Raise NStr("vi = 'Xem xét mở bộ xử lý chỉ từ biểu mẫu của đối tượng.';
					|ru = 'Предусмотрено открытие обработки только из форм объектов.';
					|en = 'Data processor can be opened only from object forms.'; fa = 'Data processor can be opened only from object forms.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme degli oggetti.';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z form obiektów.';
					|tr = 'İşleme sadece nesne formlarından açılır.'");
	EndIf;
	
	SetConditionalAppearance();
	
	Title = Parameters.Title;
	If ValueIsFilled(Parameters.AdditionalExplanationWhenUploading) Then
		Items.Step1Label1.Title = Items.Step1Label1.Title + " " + Parameters.AdditionalExplanationWhenUploading;
	EndIf;

	CheckFillingOfItem =
		Not Parameters.SkipItemVerification And Not Parameters.ImportPackingLists;
	CheckCharacteristicPopulation = Parameters.CheckCharacteristicPopulation;
	MapBySupplierProducts = ValueIsFilled(Parameters.FillInThePartnerSNomenclature)
		And GetFunctionalOption("UsePartnersProducts")
		And AccessRight("Read", Metadata.Catalogs.ProductCrossReferences);
	If MapBySupplierProducts Then
		Object.Partner = Parameters.FillInThePartnerSNomenclature;
	EndIf;
	
	ThisIsReusablePackage = Parameters.ThisIsReusablePackage;
	
	ImportQuantity = Parameters.ImportQuantity;
	ImportPrices       = Parameters.ImportPrices;
	ImportAmounts      = Parameters.ImportAmounts;
	ImportCCD        = Parameters.ImportCCD;
	
	ImportInventory           = Parameters.ImportInventory;
	ImportDiscounts           = Parameters.ImportDiscounts;
	Object.ImportPackingLists = Parameters.ImportPackingLists;
	
	AmountsRecalculate = Parameters.AmountsRecalculate;
	PriceIncludesVAT    = Parameters.PriceIncludesVAT;
	VATTaxation = Parameters.VATTaxation;
	FillingDate     = Parameters.FillingDate;
	Organization        = Parameters.Organization;
	
	ComponentsPriceParameters = Parameters.ComponentsPriceParameters;
	
	ParametersArray = New Array;
	FilterRemainingGoodsByShelfLives = New Structure;
	SelectionAccordingToCompositionOfSet = False;
	For Each Filter In Parameters.FilterParameters Do
		If Filter.Key = "ProductSegment" Then
			ParametersArray.Add(New ChoiceParameter("ProductSegment", Filter.Value));
			If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
				ParametersArray.Add(New ChoiceParameter("ForbiddingTheEditingOfAnItemSegment", True));
			EndIf;
		ElsIf Filter.Key = "ItemsType" Then
			// Redefining item types.
			// When specifying the barcode of a set, it should be possible to transfer components to the document that
			// correspond to the acceptable types of item of the document, even if the
			// item type is not explicitly defined as part of the acceptable types - a Set.
			AcceptableProductTypes = Common.CopyRecursive(Filter.Value, False);
			
			If AcceptableProductTypes.Find(Enums.ItemsTypes.Set) = Undefined Then
				SelectionAccordingToCompositionOfSet = True;
				AcceptableProductTypes.Add(Enums.ItemsTypes.Set);
			EndIf;
			
			FilterRemainingGoodsByShelfLives.Insert(Filter.Key, AcceptableProductTypes);
			ParametersArray.Add(New ChoiceParameter("Filter." + Filter.Key, AcceptableProductTypes));
		Else
			FilterRemainingGoodsByShelfLives.Insert(Filter.Key, Filter.Value);
			ParametersArray.Add(New ChoiceParameter("Filter." + Filter.Key, Filter.Value));
		EndIf;
	EndDo;
	
	Items.GoodsProducts.ChoiceParameters = New FixedArray(ParametersArray);
	
	If FilterRemainingGoodsByShelfLives.Property("ItemsType") Then
		FilterText1 = NStr("vi = 'Để chọn dạng mặt hàng: %1.';
							|ru = 'Для выбора доступна номенклатура с типом: %1.';
							|en = 'Items with type: %1 are available for selection.'; fa = 'Items with type: %1 are available for selection.';
							|it = 'Per la selezione è disponibile l''articolo con tipo: %1';
							|pl = 'Do wyboru jest dostępna nomenklatura typu: %1.';
							|tr = '%1 tipi ile seçim için öğe erişilebilir.'");
		
		Types				= New Array;
		TypesPresentation	= New Array;
		
		For Each FilterType In FilterRemainingGoodsByShelfLives.ItemsType Do
			If Not GetFunctionalOption("UseReusablePackage")
				And FilterType = Enums.ItemsTypes.ReusablePackage Then
				
				Continue;
				
			EndIf;
			
			Types.Add(FilterType);
			
			If SelectionAccordingToCompositionOfSet
				And FilterType = Enums.ItemsTypes.Set Then
				
				ContainsServices = FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.OperationService) <> Undefined
					Or FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.Work_5) <> Undefined;
				ContainsGoods = FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.ReusablePackage) <> Undefined
					Or FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.OwnGoods) <> Undefined;
				
				If Not ContainsServices
					And ContainsGoods Then
					
					SetPresentation =  NStr("ru = 'Набор, содержащий товары';
											|vi = 'A set containing goods';
											|en = 'A set containing goods'; fa = 'A set containing goods';
											|it = 'A set containing goods';
											|pl = 'A set containing goods';
											|tr = 'Mal içeren set'");
					
				ElsIf ContainsServices
					And Not ContainsGoods Then
					
					SetPresentation =  NStr("ru = 'Набор, содержащий услуги';
											|vi = 'A set containing services';
											|en = 'A set containing services'; fa = 'A set containing services';
											|it = 'A set containing services';
											|pl = 'A set containing services';
											|tr = 'Hizmet içeren set'");
					
				Else
					
					SetPresentation = FilterType;
					
				EndIf;
				
				TypesPresentation.Add(SetPresentation);
				
			Else
				TypesPresentation.Add(FilterType);
			EndIf;
		EndDo;
		Items.FilterLabel.Title = StrTemplate(FilterText1, StrConcat(TypesPresentation, ", "));
		
		CharacteristicsParameters = New Array;
		CharacteristicsParameters.Add(New ChoiceParameter("Filter.ItemsType", Types));
		Items.GoodsCharacteristic.ChoiceParameters = New FixedArray(CharacteristicsParameters);
		Items.GoodsPartnerProducts.ChoiceParameters = New FixedArray(CharacteristicsParameters);
	EndIf;
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseDiscountAdjustmentsInPurchases      = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	
	InitializeTableDocument();
	SetAvailabilityOfClipboardCommands();
	SetColumnAvailability();
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not CheckFillingOfItem Then
		NotCheckedAttributeArray = New Array;
		NotCheckedAttributeArray.Add("Object");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
		If Object.Goods.Count() = 0 Then
			ErrorText = StrTemplate(NStr("ru = 'Не введено ни одной строки в список ""%1""';
										|vi = 'No line is entered into the ""%1"" list';
										|en = 'No line is entered into the ""%1"" list'; fa = 'No line is entered into the ""%1"" list';
										|it = 'Non è immessa alcuna riga nell''elenco ""%1""';
										|pl = 'Nie wprowadzono żadnego wiersza do listy ""%1""';
										|tr = '""%1"" listesine herhangi satır girilmedi'"),
				Metadata.DataProcessors.ImportGoodsFromExternalFiles.TabularSections.Goods.Synonym);
			Common.MessageToUser(ErrorText, , "Object.Goods", , Cancel);
		EndIf;
	EndIf;
	
	If Object.ImportPackingLists Then
		PackingListsByLineNumbers = New Map;
		For CurIndex__ = 0 To Object.Goods.Count()-1 Do
			
			CurrentRow = Object.Goods[CurIndex__]; // LineOfATabularSection
			If Not ValueIsFilled(CurrentRow.Products)
				And Not ValueIsFilled(CurrentRow.PackingList) Then
				
				ErrorText = NStr("vi = 'Chưa điền dữ liệu theo hàng hóa hoặc phiếu đóng gói tại dòng %LineNumber%.';
								|ru = 'Не заполнены данные по товару или упаковочному листу в строке %LineNumber%.';
								|en = 'Product or packing list data is required in line %LineNumber%.'; fa = 'Product or packing list data is required in line %LineNumber%.';
								|it = 'I dati relativi alla merce oppure al packing list non sono compilati nella riga %LineNumber%.';
								|pl = 'Nie wypełnione są dane towaru lub listy pakowej w wierszu %LineNumber%.';
								|tr = '%LineNumber% satırındaki ürün veya ambalaj listesi verileri doldurulmadı.'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
				Field = CommonClientServer.PathToTabularSection("Object.Goods", CurrentRow.LineNumber, "Products");
				CommonClientServer.MessageToUser(ErrorText, , Field, , Cancel);
				
			EndIf;
			
			If ValueIsFilled(CurrentRow.PackingList) Then
				If PackingListsByLineNumbers[CurrentRow.PackingList] = Undefined Then
					PackingListsByLineNumbers.Insert(CurrentRow.PackingList, CurrentRow.LineNumber);
				Else
					ErrorText = NStr("vi = 'Trong dòng %LineNumber% lặp lại %PackingList% từ dòng %LineNumberToRepeat%.
						|Hãy thay đổi hoặc xóa một trong các dòng.';
						|ru = 'В строке %LineNumber% повторяется %PackingList% из строки %LineNumberToRepeat%.
						|Измените или удалите одну из строк.';
						|en = '%PackingList% from line %LineNumberToRepeat% is repeated in line %LineNumber%.
						|Change or delete one of the lines.'; fa = '%PackingList% from line %LineNumberToRepeat% is repeated in line %LineNumber%.
						|Change or delete one of the lines.';
						|it = 'Nella riga  %LineNumber% si ripete %PackingList% dalla riga %LineNumberToRepeat%.
						| Modificare oppure eliminare una delle righe.';
						|pl = 'W wierszu %LineNumber% powtarza się %PackingList% z wierszu %LineNumberToRepeat%.
						|Zmień lub usuń jeden z wierszy.';
						|tr = '%LineNumber% satırı, %LineNumberToRepeat% satırındaki %PackingList%''i tekrarlar.
						|Satırlardan birini değiştir veya sil.'");
					ErrorText = StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
					ErrorText = StrReplace(ErrorText, "%PackingList%", CurrentRow.PackingList);
					ErrorText = StrReplace(ErrorText, "%LineNumberToRepeat%",
						PackingListsByLineNumbers[CurrentRow.PackingList]);
					Field = CommonClientServer.PathToTabularSection("Object.Goods", CurrentRow.LineNumber, "PackingList");
					CommonClientServer.MessageToUser(ErrorText, , Field, , Cancel);
				EndIf;
			EndIf;
		EndDo;
		
	EndIf;
	If CreateCCDNumbers Or CheckCharacteristicPopulation Then
		For CurIndex__ = 0 To Object.Goods.Count()-1 Do
			
			CurrentRow = Object.Goods[CurIndex__]; // LineOfATabularSection
			
			ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Sản phẩm""';
								|ru = 'в строке %LineNumber% списка ""Товары""';
								|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
								|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
								|pl = 'w wierszu %LineNumber% listy ""Towary""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
			ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", CurrentRow.LineNumber);
			
			If CurrentRow.CreateCCDNumber And CurrentRow.TheRecordsAreKeptByCCD And Not ValueIsFilled(CurrentRow.OriginCountry) Then
				
				CommonClientServer.MessageToUser(
					NStr("vi = 'Chưa điền cột ""Nước xuất xứ""';
						|ru = 'Не заполнена колонка ""Страна происхождения""';
						|en = 'Column ""Country of origin"" is not filled in'; fa = 'Column ""Country of origin"" is not filled in';
						|it = 'Non è compilata la colonna ""Paese d''origine""';
						|pl = 'Nie została wypełniona kolumna ""Kraj pochodzenia""';
						|tr = '""Menşe ülke"" sütunu doldurulmadı'") + ErrorAddress,
					,
					"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "OriginCountry"),
					,
					Cancel);
				
			EndIf;
			
			// Checking the filling of the characteristics.
			If CurrentRow.ItemVariantsAreUsed And Not ValueIsFilled(CurrentRow.Characteristic) Then
				
				CommonClientServer.MessageToUser(
					NStr("vi = 'Chưa điền cột ""Đặc tính""';
						|ru = 'Не заполнена колонка ""Характеристика""';
						|en = 'Column ""Variant"" is not filled in'; fa = 'Column ""Variant"" is not filled in';
						|it = 'La colonna ""Caratteristica"" non è compilata';
						|pl = 'Nie wypełniono kolumny ""Характеристика""';
						|tr = '""Varyant"" sütunu doldurulmadı'") + " " + ErrorAddress,
					,
					"Object." + CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Characteristic"),
					,
					Cancel);
				
			EndIf;
			
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Items.Goods.CurrentData.RowCode = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	
	StructureOfParametersOfProductComparison = New Structure;
	StructureOfParametersOfProductComparison.Insert("Ref",                             Object);
	StructureOfParametersOfProductComparison.Insert("Partner",                            Object.Partner);
	StructureOfParametersOfProductComparison.Insert("DoNotPerformValidationForUser", False);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate();
	ParametersFillInVATRate.Organization = Organization;
	ParametersFillInVATRate.VATTaxation = VATTaxation;
	ParametersFillInVATRate.Date = FillingDate;	
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	
	If MapBySupplierProducts Then
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
		StructureOfActions.Insert(
			"CheckMatchedPartnerProducts",
			StructureOfParametersOfProductComparison);
	EndIf;
		
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ThisIsReusablePackage);
	If AmountsRecalculate Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ValueIsFilled(CurrentRow.Products) Then
		CurrentRow.PackingList = PredefinedValue("Document.PackingList.EmptyRef");
	EndIf;
	
	If Not CurrentRow.TheRecordsAreKeptByCCD
		And (ValueIsFilled(CurrentRow.CCDNumber)
		Or ValueIsFilled(CurrentRow.ImportedCCDNumber)) Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.ImportedCCDNumber = "";
		CurrentRow.CreateCCDNumber = False;
	EndIf;

EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfParametersOfProductComparison = New Structure;
	StructureOfParametersOfProductComparison.Insert("Ref",                             Object);
	StructureOfParametersOfProductComparison.Insert("Partner",                            Object.Partner);
	StructureOfParametersOfProductComparison.Insert("DoNotPerformValidationForUser", False);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	
	If MapBySupplierProducts Then
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
		StructureOfActions.Insert(
			"CheckMatchedPartnerProducts",
			StructureOfParametersOfProductComparison);
	EndIf;		
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	
	StructureOfParametersOfProductComparison = New Structure;
	StructureOfParametersOfProductComparison.Insert("Ref",                             Object);
	StructureOfParametersOfProductComparison.Insert("Partner",                            Object.Partner);
	StructureOfParametersOfProductComparison.Insert("DoNotPerformValidationForUser", False);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate();
	ParametersFillInVATRate.Organization = Organization;
	ParametersFillInVATRate.VATTaxation = VATTaxation;
	ParametersFillInVATRate.Date = FillingDate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert(
		"CheckMatchedPartnerProducts",
		StructureOfParametersOfProductComparison);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ThisIsReusablePackage);
	If AmountsRecalculate Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ValueIsFilled(CurrentRow.Products) Then
		CurrentRow.PackingList = PredefinedValue("Document.PackingList.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPackingListOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	If ValueIsFilled(CurrentRow.PackingList) Then
		CurrentRow.Products       = PredefinedValue("Catalog.Products.EmptyRef");
		CurrentRow.Characteristic     = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
		CurrentRow.Package           = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
		CurrentRow.NumberOfPackages = 1;
		CurrentRow.Count         = 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, PriceIncludesVAT, AmountsRecalculate);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	If Not AmountsRecalculate Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, PriceIncludesVAT, True);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPercentRateOfManualDiscountOnChange(Item)
	
	If Not AmountsRecalculate Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("RecalculateAmountOfManualDiscount_", False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsManualDiscountOnChange(Item)
	
	If Not AmountsRecalculate Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("RecalculateAmountOfManualDiscount_", False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	If Not AmountsRecalculate Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountForAmountInPurchases", 
		BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInVHFPurchases(
			Object, 
			True));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	If Not AmountsRecalculate Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	If Not AmountsRecalculate Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow <> Undefined And Item.CurrentItem.Name = "GoodsProducts" Then
		FillInSelectionListOfProductCharacteristics(CurrentRow.RowCode);
	ElsIf Item.CurrentItem.Name = "GoodsCharacteristic" Then
		FillInSelectionListOfProductCharacteristics(CurrentRow.RowCode, True);
	ElsIf Item.CurrentItem.Name = "GoodsPackingList" Then
		FillInPackingListSelection(CurrentRow.RowCode);
	ElsIf Item.CurrentItem.Name = "GoodsPartnerProducts" Then
		
		CurrentData = Items.Goods.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	CurrentRow.CreateCCDNumber = Not ValueIsFilled(CurrentRow.CCDNumber);
EndProcedure

&AtClient
Procedure GoodsOriginCountryClearing(Item, StandardProcessing)
	CurrentRow = Items.Goods.CurrentData;
	CurrentRow.ImportedCountryOfOrigin = "";
EndProcedure

&AtClient
Procedure GoodsPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

EndProcedure

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	For Each FilterCriterion In FilterRemainingGoodsByShelfLives Do
		FilterParameters.Insert("Products." + FilterCriterion.Key, FilterCriterion.Value);
	EndDo;
	
	Columns = "Products,Characteristic,ProductsInSet,ItemVariantOfSet,"
		+ ?(ImportQuantity, "Package,NumberOfPackages,", "")
		+ ?(ImportPrices, "Price,", "")
		+ ?(ImportCCD, "CCDNumber,", "")
		+ ?(ImportInventory, "MinimumBalance,MaximumBalance", "")
		+ ?(ImportDiscounts, "PercentRateOfManualDiscount,", "")
		+ ?(Object.ImportPackingLists, "PackingList,", "");
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate();
	ParametersFillInVATRate.Organization = Organization;
	ParametersFillInVATRate.VATTaxation = VATTaxation;
	ParametersFillInVATRate.Date = FillingDate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ThisIsReusablePackage);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, PriceIncludesVAT, AmountsRecalculate);
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		If Not UseDiscountAdjustmentsInPurchases Then
			CurrentRow.PercentRateOfManualDiscount = 0;
			CurrentRow.ManualDiscount = 0;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
			
	FillInServiceDetailsForProductRange();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
		
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#Region SearchAndComparisonOfProducts

&AtServer
Procedure AddSelectedProducts(TableOfSelectedItems, RowCode, FoundProducts, FoundCharacteristic = Undefined, PartnerProductsFound = Undefined)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Products", FoundProducts);
	If Not FoundCharacteristic = Undefined Then
		FilterStructure1.Insert("Characteristic", FoundCharacteristic);
	EndIf;	
	FilterStructure1.Insert("RowCode", RowCode);
	
	PreviouslySelectedProducts = TableOfSelectedItems.FindRows(FilterStructure1);
	If PreviouslySelectedProducts.Count() = 0 Then
		SelectedString_ = TableOfSelectedItems.Add();
		SelectedString_.RowCode = RowCode;
		SelectedString_.Products = FoundProducts;
		If Not PartnerProductsFound = Undefined Then
			SelectedString_.PartnerProducts = PartnerProductsFound;
		EndIf;	
		If Not FoundCharacteristic = Undefined Then
			SelectedString_.Characteristic = FoundCharacteristic;
		EndIf;	
	EndIf;
	
EndProcedure

&AtServer
Function SearchLinkedTable(ArrayOfPreviouslyFound, RelatedTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult)
	
	Result = New ValueTable;
	For Each FieldForResult In FieldsFoundEarlierForResult Do
		Result.Columns.Add(FieldForResult.Value);
	EndDo;	
	For Each FieldForResult In FieldsOfLinkedTableForResult Do
		Result.Columns.Add(FieldForResult.Value);
	EndDo;	
	
	If ArrayOfPreviouslyFound.Count() > 0 Then
		For Each StringByKey In ArrayOfPreviouslyFound Do
			FilterForSearch = New Structure;
			For Each Link In Links Do
				FilterForSearch.Insert(Link.Value, StringByKey[Link.Key]);
			EndDo;
			For Each FilterElement In SelectionByLinkedTable Do
				FilterForSearch.Insert(FilterElement.Key, FilterElement.Value);
			EndDo;
			FoundBySelection = RelatedTable.FindRows(FilterForSearch);
			For Each StringFoundBySelection In FoundBySelection Do
				NewResultString = Result.Add();
				For Each FieldForResult In FieldsFoundEarlierForResult Do
					NewResultString[FieldForResult.Value] = StringByKey[FieldForResult.Key];
				EndDo;	
				For Each FieldForResult In FieldsOfLinkedTableForResult Do
					NewResultString[FieldForResult.Value] = StringFoundBySelection[FieldForResult.Key];
				EndDo;	
			EndDo;	
		EndDo;	
	EndIf;
	
	Return Result;
EndFunction	

&AtServer
Procedure CompareTableDocumentDataWithInformationSecurityData()
	
	RowsToProcess = New Array;
	
	ClarificationOfProducts.Clear();
	SelectedProducts.Clear();
	
	SelectedItemIndexed = SelectedProducts.Unload();
	SelectedItemIndexed.Indexes.Add("RowCode");
	
	FoundRows = SelectedItemIndexed.Copy();

	Object.Goods.Clear();
	
	IBData = GetDataAndBPOProductsAndCharacteristics();
	ProductsTable = IBData.ProductsTable;
	CharacteristicTable = IBData.CharacteristicTable;
	SupplierProductList = IBData.SupplierProductList;
	
	ColumnNumbers = New Map;
	ColumnNumber = 1;
	
	ColumnNumbers.Insert("BarcodeColumn", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
	ColumnNumber = ColumnNumber +1;
	ColumnNumbers.Insert("ColumnCode", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
	ColumnNumber = ColumnNumber +1;
	ColumnNumbers.Insert("ColumnArticle", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
	ColumnNumber = ColumnNumber +1;
	ColumnNumbers.Insert("ColumnProducts", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
	ColumnNumber = ColumnNumber +1;
	If UseItemVariants Then
		ColumnNumbers.Insert("ColumnCharacteristics", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
		ColumnNumber = ColumnNumber +1;
	EndIf;
	If ImportQuantity Then
		ColumnNumbers.Insert("ColumnQuantity", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
		ColumnNumber = ColumnNumber +1;
	EndIf;
	If ImportInventory Then
		ColumnNumbers.Insert("ColumnMinimumRemainder", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
		ColumnNumber = ColumnNumber +1;
		ColumnNumbers.Insert("ColumnMaximumRemainder", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
		ColumnNumber = ColumnNumber +1;
	EndIf;
	If ImportPrices Then
		ColumnNumbers.Insert("PriceColumn", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
		ColumnNumber = ColumnNumber +1;
	EndIf;
	If ImportAmounts Then
		If UseDiscountAdjustmentsInPurchases And ImportDiscounts Then
			ColumnNumbers.Insert("ManualDiscountPercentageColumn", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
			ColumnNumber = ColumnNumber +1;
			ColumnNumbers.Insert("ManualDiscountAmountColumn", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
			ColumnNumber = ColumnNumber +1;
		EndIf;
		ColumnNumbers.Insert("ColumnSum", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
		ColumnNumber = ColumnNumber +1;
		If VATTaxation <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
			ColumnNumbers.Insert("VATAmountColumn", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
			ColumnNumber = ColumnNumber +1;
			If Not PriceIncludesVAT Then
				ColumnNumbers.Insert("ColumnSumWithVAT", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
				ColumnNumber = ColumnNumber +1;
			EndIf;
		EndIf;
	EndIf;
	If ImportCCD Then
		ColumnNumbers.Insert("ColumnNumberOfCCD", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
		ColumnNumber = ColumnNumber +1;
		ColumnNumbers.Insert("ColumnCountryOfOrigin", "C" + Format(ColumnNumber, "NZ=0; NG=0"));
		ColumnNumber = ColumnNumber +1;
	EndIf;
	
	HeaderHeight = 1;
	LineNumber = HeaderHeight + 1 ;
	
	StringNumber = Format(LineNumber, "NZ=0; NG=0");
	FilledInProductsCodeArticleBarcode = ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnArticle")).Text)
		Or ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnProducts")).Text)
		Or ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("BarcodeColumn")).Text)
		Or ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnCode")).Text);
	
	PackingListSynonymInReg   = StrReplace(Upper(Metadata.Documents.PackingList.Synonym), " ", "");
	SynonymLengthPackingList = StrLen(PackingListSynonymInReg);
	CodesOfPackingListsForCheck.Clear();
	
	While FilledInProductsCodeArticleBarcode Do
		
		NewRow = ClarificationOfProducts.Add();
		Count = 0;
		NewRow.RowCode = LineNumber;
		
		Try
			NewRow.Barcode = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("BarcodeColumn")).Text;
			NewRow.Code = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnCode")).Text;
			NewRow.SKU = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnArticle")).Text;
			NewRow.NomenclatureName = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnProducts")).Text;
			If UseItemVariants Then
				NewRow.CharacteristicName = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnCharacteristics")).Text;
			EndIf;
			If ImportQuantity Then
				Count = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnQuantity")).Text;
			EndIf;
		Except
			CommonClientServer.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
		
		If ImportQuantity Then
			AssignNumericValueWhenFillingInTS(NewRow.Count, Count, LineNumber, "Count", HeaderHeight);
		EndIf;
		
		If ImportInventory Then

			MinimumBalance = 0;
			Try
				MinimumBalance = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnMinimumRemainder")).Text;
			Except
				CommonClientServer.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EndTry;

			AssignNumericValueWhenFillingInTS(NewRow.MinimumBalance, MinimumBalance, LineNumber, "MinimumBalance", HeaderHeight);

			MaximumBalance = 0;
			Try
				MaximumBalance = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnMaximumRemainder")).Text;
			Except
				CommonClientServer.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EndTry;

			AssignNumericValueWhenFillingInTS(NewRow.MaximumBalance, MaximumBalance, LineNumber, "MaximumBalance", HeaderHeight);

		EndIf;

		If ImportPrices Then
			Price = 0;
			Try
				Price = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("PriceColumn")).Text;
			Except
				CommonClientServer.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EndTry;
			
			AssignNumericValueWhenFillingInTS(NewRow.Price, Price, LineNumber, "Price", HeaderHeight);
			
		EndIf;
		
		If ImportAmounts Then
			PercentRateOfManualDiscount = 0;
			ManualDiscount   = 0;
			Sum               = 0;
			VATAmount            = 0;
			AmountIncludingVAT           = 0;
			
			Try
				If UseDiscountAdjustmentsInPurchases And ImportDiscounts Then
					PercentRateOfManualDiscount = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ManualDiscountPercentageColumn")).Text;
					ManualDiscount = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ManualDiscountAmountColumn")).Text;
					PercentRateOfManualDiscount = StrReplace(PercentRateOfManualDiscount, "%", "");
				EndIf;
				If ColumnNumbers.Get("ColumnSum") <>  Undefined Then
					Sum     = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnSum")).Text;
				EndIf;
				If ColumnNumbers.Get("VATAmountColumn") <>  Undefined Then
					VATAmount  = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("VATAmountColumn")).Text;
				EndIf;
				If ColumnNumbers.Get("ColumnSumWithVAT") <>  Undefined Then
					AmountIncludingVAT = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnSumWithVAT")).Text;
				EndIf;
				
			Except
				CommonClientServer.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EndTry;
			
			AssignNumericValueWhenFillingInTS(NewRow.PercentRateOfManualDiscount, PercentRateOfManualDiscount, LineNumber, "PercentRateOfManualDiscount", HeaderHeight);
			AssignNumericValueWhenFillingInTS(NewRow.ManualDiscount, ManualDiscount, LineNumber, "ManualDiscount", HeaderHeight);
			AssignNumericValueWhenFillingInTS(NewRow.Sum, Sum, LineNumber, "Sum", HeaderHeight);
			AssignNumericValueWhenFillingInTS(NewRow.VATAmount, VATAmount, LineNumber, "VATAmount", HeaderHeight);
			AssignNumericValueWhenFillingInTS(NewRow.AmountIncludingVAT, AmountIncludingVAT, LineNumber, "AmountIncludingVAT", HeaderHeight);
			
		EndIf;
		
		If ImportCCD Then
			Try
				CCDNumber            = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnNumberOfCCD")).Text;
				OriginCountry = SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnCountryOfOrigin")).Text;
			Except
				CommonClientServer.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EndTry;
			
			If ValueIsFilled(CCDNumber) Then
				NewRow.CCDNumber             = TrimAll(CCDNumber);
				If ValueIsFilled(OriginCountry) Then
					NewRow.OriginCountry  = Upper(TrimAll(OriginCountry));
				EndIf;
			EndIf;
			
		EndIf;
		
		SearchStringCode            = Upper(StrReplace(NewRow.Code, " ", "")); 
		SearchStringArticle        = Upper(StrReplace(NewRow.SKU, " ", "")); 
		SearchStringProducts   = Upper(StrReplace(NewRow.NomenclatureName, " ", ""));
		SearchStringCharacteristic = Upper(StrReplace(NewRow.CharacteristicName, " ", ""));
		
		If ValueIsFilled(NewRow.Barcode) Then
			BarcodeWithoutSpaces = StrReplace(NewRow.Barcode, " ", "");
			//@skip-check query-in-loop
			SelectionOfFoundProducts = SelectProductsByBarcode(BarcodeWithoutSpaces);
			If SelectionOfFoundProducts.Count() > 0 Then
				While SelectionOfFoundProducts.Next() Do
					SelectedString_ = SelectedItemIndexed.Add();
					SelectedString_.RowCode = LineNumber;
					FillPropertyValues(SelectedString_, SelectionOfFoundProducts);
				EndDo;
			ElsIf Object.ImportPackingLists Then
				StringWithNewCode = CodesOfPackingListsForCheck.Add();
				StringWithNewCode.Code = BarcodeWithoutSpaces;
				StringWithNewCode.RowCode = LineNumber;
			EndIf;
			
		ElsIf ValueIsFilled(NewRow.Code) And ValueIsFilled(NewRow.CharacteristicName) Then
			
			Links = New Structure("SignificanceForFeatureSelection", "SignificanceForFeatureSelection");
			FieldsFoundEarlierForResult = New Structure("Products", "Products");
			FieldsOfLinkedTableForResult = New Structure("Characteristic", "Characteristic");
			
			FoundProductsByKey = ProductsTable.FindRows(New Structure("Code", SearchStringCode));
			SelectionByLinkedTable = New Structure("NameOfTheSearchFeature", SearchStringCharacteristic);
			FoundRows = SearchLinkedTable(FoundProductsByKey, CharacteristicTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
			If FoundRows.Count() = 0 Then
				SelectionByLinkedTable = New Structure("FullNameOfCharacteristicSearch", SearchStringCharacteristic);
				FoundRows = SearchLinkedTable(FoundProductsByKey, CharacteristicTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
				If FoundRows.Count() = 0 Then
					FoundRows = SearchLinkedTable(FoundProductsByKey, CharacteristicTable, Links, New Structure, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
				EndIf;
			EndIf;
			For Each FoundRow In FoundRows Do
				AddSelectedProducts(SelectedItemIndexed, LineNumber, FoundRow.Products, FoundRow.Characteristic);
			EndDo;	
			
		ElsIf ValueIsFilled(NewRow.SKU) And ValueIsFilled(NewRow.NomenclatureName) And ValueIsFilled(NewRow.CharacteristicName) Then
			
			Links = New Structure("SignificanceForFeatureSelection", "SignificanceForFeatureSelection");
			FieldsFoundEarlierForResult = New Structure("Products", "Products");
			FieldsOfLinkedTableForResult = New Structure("Characteristic", "Characteristic");
			FoundProductsByKey = ProductsTable.FindRows(New Structure("ProductIDSearch, NameSearch", SearchStringArticle, SearchStringProducts));
			SelectionByLinkedTable = New Structure("NameOfTheSearchFeature", SearchStringCharacteristic);
			FoundRows = SearchLinkedTable(FoundProductsByKey, CharacteristicTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
			If FoundRows.Count() = 0 Then
				SelectionByLinkedTable = New Structure("FullNameOfCharacteristicSearch", SearchStringCharacteristic);
				FoundRows = SearchLinkedTable(FoundProductsByKey, CharacteristicTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
			EndIf;
			If FoundRows.Count() = 0 Then
				FoundProductsByArticleFullName = ProductsTable.FindRows(New Structure("ProductIDSearch, FullNameSearch", SearchStringArticle, SearchStringProducts));
				SelectionByLinkedTable = New Structure("NameOfTheSearchFeature", SearchStringCharacteristic);
				FoundRows = SearchLinkedTable(FoundProductsByArticleFullName, CharacteristicTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
				If FoundRows.Count() = 0 Then
					SelectionByLinkedTable = New Structure("FullNameOfCharacteristicSearch", SearchStringCharacteristic);
					FoundRows = SearchLinkedTable(FoundProductsByArticleFullName, CharacteristicTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
				EndIf;
			EndIf;
			FoundSupplierProducts = False;
			If FoundRows.Count() = 0 Then
				FoundRows = SearchLinkedTable(FoundProductsByKey, CharacteristicTable, Links, New Structure, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
				If FoundRows.Count() = 0 Then
					FoundRows = SearchLinkedTable(FoundProductsByArticleFullName, CharacteristicTable, Links, New Structure, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
					If FoundRows.Count() = 0 Then
						FoundRows = SupplierProductList.FindRows(New Structure("SupplierArticleSearch, PartnerProductsSearch", SearchStringArticle, SearchStringProducts));
						FoundSupplierProducts = (FoundRows.Count()>0);
					EndIf;	
				EndIf;	
			EndIf;
			
			For Each FoundRow In FoundRows Do
				AddSelectedProducts(SelectedItemIndexed, LineNumber, FoundRow.Products, FoundRow.Characteristic, ?(FoundSupplierProducts, FoundRow.PartnerProducts, Undefined));
			EndDo;	
			
		ElsIf ValueIsFilled(NewRow.Code) And Not ValueIsFilled(NewRow.CharacteristicName) Then
			
			FoundProductsByKey = ProductsTable.FindRows(New Structure("Code, NameSearch", SearchStringCode, SearchStringProducts));
			If FoundProductsByKey.Count() = 0 Then
				FoundProductsByKey = ProductsTable.FindRows(New Structure("Code, FullNameSearch", SearchStringCode, SearchStringProducts));
				If FoundProductsByKey.Count() = 0 Then
					FoundProductsByKey = ProductsTable.FindRows(New Structure("Code", SearchStringCode));
				EndIf;
			EndIf;
			For Each ProductsByKey In FoundProductsByKey Do
				AddSelectedProducts(SelectedItemIndexed, LineNumber, ProductsByKey.Products);
			EndDo;			
			
		ElsIf ValueIsFilled(NewRow.SKU) And ValueIsFilled(NewRow.NomenclatureName) And Not ValueIsFilled(NewRow.CharacteristicName) Then
			FoundSupplierProducts = False;
			FoundProductsByKey = ProductsTable.FindRows(New Structure("ProductIDSearch, NameSearch", SearchStringArticle,	SearchStringProducts));
			If FoundProductsByKey.Count() = 0 Then
				FoundProductsByKey = ProductsTable.FindRows(New Structure("ProductIDSearch, FullNameSearch",	SearchStringArticle, SearchStringProducts));
				If FoundProductsByKey.Count() = 0 Then
					FoundProductsByKey = ProductsTable.FindRows(New Structure("ProductIDSearch", SearchStringArticle));
					If FoundProductsByKey.Count() = 0 Then
						FoundProductsByKey = SupplierProductList.FindRows(New Structure("SupplierArticleSearch, PartnerProductsSearch", SearchStringArticle, SearchStringProducts));
						FoundSupplierProducts = (FoundProductsByKey.Count()>0);
						If FoundProductsByKey.Count() = 0 Then
							FoundProductsByKey = SupplierProductList.FindRows(New Structure("SupplierArticleSearch", SearchStringArticle));
							FoundSupplierProducts = (FoundProductsByKey.Count()>0);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			For Each ProductsByKey In FoundProductsByKey Do
				If FoundSupplierProducts Then
					AddSelectedProducts(SelectedItemIndexed, LineNumber, ProductsByKey.Products, ProductsByKey.Characteristic, ProductsByKey.PartnerProducts);
				Else
					AddSelectedProducts(SelectedItemIndexed, LineNumber, ProductsByKey.Products);
				EndIf;	
			EndDo;
			
		ElsIf Not ValueIsFilled(NewRow.SKU) And ValueIsFilled(NewRow.NomenclatureName) And ValueIsFilled(NewRow.CharacteristicName) Then
			
			Links = New Structure("SignificanceForFeatureSelection", "SignificanceForFeatureSelection");
			FieldsFoundEarlierForResult = New Structure("Characteristic", "Characteristic");
			FieldsOfLinkedTableForResult = New Structure("Products", "Products");
			
			FoundKeyCharacteristics = CharacteristicTable.FindRows(New Structure("NameOfTheSearchFeature", SearchStringCharacteristic));
			SelectionByLinkedTable = New Structure("NameSearch", SearchStringProducts);
			FoundRows = SearchLinkedTable(FoundKeyCharacteristics, ProductsTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
			If FoundRows.Count() = 0 Then
				SelectionByLinkedTable = New Structure("FullNameSearch", SearchStringProducts);
				FoundRows = SearchLinkedTable(FoundKeyCharacteristics, ProductsTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
				If FoundRows.Count() = 0 Then
					FoundKeyCharacteristics = CharacteristicTable.FindRows(New Structure("FullNameOfCharacteristicSearch", SearchStringCharacteristic));
					SelectionByLinkedTable = New Structure("NameSearch", SearchStringProducts);
					FoundRows = SearchLinkedTable(FoundKeyCharacteristics, ProductsTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
					If FoundRows.Count() = 0 Then
						SelectionByLinkedTable = New Structure("FullNameSearch", SearchStringProducts);
						FoundRows = SearchLinkedTable(FoundKeyCharacteristics, ProductsTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
					EndIf;
				EndIf;	
			EndIf;	
			
			If FoundRows.Count() = 0 Then
				FoundSupplierProducts = False;
				FoundProductsByKey = ProductsTable.FindRows(New Structure("NameSearch",	SearchStringProducts));
				If FoundProductsByKey.Count() = 0 Then
					FoundProductsByKey = ProductsTable.FindRows(New Structure("FullNameSearch", SearchStringProducts));
					If FoundProductsByKey.Count() = 0 Then
						FoundProductsByKey = SupplierProductList.FindRows(New Structure("PartnerProductsSearch", SearchStringProducts));
						FoundSupplierProducts = (FoundProductsByKey.Count()>0);
					EndIf;
				EndIf;
				For Each ProductsByKey In FoundProductsByKey Do
					If FoundSupplierProducts Then
						AddSelectedProducts(SelectedItemIndexed, LineNumber, ProductsByKey.Products, ProductsByKey.Characteristic, ProductsByKey.PartnerProducts);
					Else
						FoundKeyCharacteristics = CharacteristicTable.FindRows(New Structure("SignificanceForFeatureSelection", ProductsByKey.SignificanceForFeatureSelection));
						For Each KeyCharacteristics In FoundKeyCharacteristics Do
							AddSelectedProducts(SelectedItemIndexed, LineNumber, ProductsByKey.Products, KeyCharacteristics.Characteristic);
						EndDo;
					EndIf;
				EndDo;
			Else
				For Each FoundRow In FoundRows Do
					AddSelectedProducts(SelectedItemIndexed, LineNumber, FoundRow.Products, FoundRow.Characteristic);
				EndDo;
			EndIf;
			
		ElsIf ValueIsFilled(NewRow.SKU) And Not ValueIsFilled(NewRow.NomenclatureName) And Not ValueIsFilled(NewRow.CharacteristicName) Then
			
			FoundSupplierProducts = False;
			FoundProductsByKey = ProductsTable.FindRows(New Structure("ProductIDSearch",	SearchStringArticle));
			If FoundProductsByKey.Count() = 0 Then
				FoundProductsByKey = SupplierProductList.FindRows(New Structure("SupplierArticleSearch", SearchStringArticle));
				FoundSupplierProducts = (FoundProductsByKey.Count()>0);
			EndIf;
			For Each ProductsByKey In FoundProductsByKey Do
				If FoundSupplierProducts Then
					AddSelectedProducts(SelectedItemIndexed, LineNumber, ProductsByKey.Products, ProductsByKey.Characteristic, ProductsByKey.PartnerProducts);
				Else
					AddSelectedProducts(SelectedItemIndexed, LineNumber, ProductsByKey.Products);
				EndIf;	
			EndDo;
			
		ElsIf ValueIsFilled(NewRow.SKU) And Not ValueIsFilled(NewRow.NomenclatureName) And ValueIsFilled(NewRow.CharacteristicName) Then
			
			Links = New Structure("SignificanceForFeatureSelection", "SignificanceForFeatureSelection");
			FieldsFoundEarlierForResult = New Structure("Products", "Products");
			FieldsOfLinkedTableForResult = New Structure("Characteristic", "Characteristic");
			FoundSupplierProducts = False;
			FoundProductsByKey = ProductsTable.FindRows(New Structure("ProductIDSearch", SearchStringArticle));
			SelectionByLinkedTable = New Structure("NameOfTheSearchFeature", SearchStringCharacteristic);
			FoundRows = SearchLinkedTable(FoundProductsByKey, CharacteristicTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
			If FoundRows.Count() = 0 Then
				SelectionByLinkedTable = New Structure("FullNameOfCharacteristicSearch", SearchStringCharacteristic);
				FoundRows = SearchLinkedTable(FoundProductsByKey, CharacteristicTable, Links, SelectionByLinkedTable, FieldsFoundEarlierForResult, FieldsOfLinkedTableForResult);
				If FoundRows.Count() = 0 Then
					FoundRows = SupplierProductList.FindRows(New Structure("SupplierArticleSearch", SearchStringArticle));
					FoundSupplierProducts = (FoundRows.Count()>0);
				EndIf;
			EndIf;
			
			For Each FoundRow In FoundRows Do
				AddSelectedProducts(SelectedItemIndexed, LineNumber, FoundRow.Products, FoundRow.Characteristic, ?(FoundSupplierProducts, FoundRow.PartnerProducts, Undefined) );
			EndDo;
			
		ElsIf Not ValueIsFilled(NewRow.SKU) And ValueIsFilled(NewRow.NomenclatureName) And Not ValueIsFilled(NewRow.CharacteristicName) Then
			
			If Object.ImportPackingLists
				And StrFind(SearchStringProducts, PackingListSynonymInReg) = 1 Then
				CodeEndingPosition = StrFind(Upper(NewRow.NomenclatureName), " " + NStr("vi = 'TỪ';
																						|ru = 'ОТ';
																						|en = 'DATED'; fa = 'DATED';
																						|it = 'DEL';
																						|pl = 'Z DN.';
																						|tr = 'İTİBAREN'") + " ") - 1;
				
				If CodeEndingPosition > 0 Then
					WorksheetCodeSearchString = StrReplace(Left(NewRow.NomenclatureName, CodeEndingPosition), " ", "");
				Else
					WorksheetCodeSearchString = StrReplace(NewRow.NomenclatureName, " ", "");
				EndIf;
				WorksheetCodeSearchString = Mid(WorksheetCodeSearchString, SynonymLengthPackingList + 1);
				StringWithNewCode = CodesOfPackingListsForCheck.Add();
				StringWithNewCode.Code = WorksheetCodeSearchString;
				StringWithNewCode.RowCode = LineNumber;
			Else
				
				FoundSupplierProducts = False;
				FoundProductsByKey = ProductsTable.FindRows(New Structure("NameSearch",	SearchStringProducts));
				If FoundProductsByKey.Count() = 0 Then
					FoundProductsByKey = ProductsTable.FindRows(New Structure("FullNameSearch", SearchStringProducts));
					If FoundProductsByKey.Count() = 0 Then
						FoundProductsByKey = SupplierProductList.FindRows(New Structure("PartnerProductsSearch", SearchStringProducts));
						FoundSupplierProducts = (FoundProductsByKey.Count()>0);
					EndIf;
				EndIf;
				For Each ProductsByKey In FoundProductsByKey Do
					If FoundSupplierProducts Then
						AddSelectedProducts(SelectedItemIndexed, LineNumber, ProductsByKey.Products, ProductsByKey.Characteristic, ProductsByKey.PartnerProducts);
					Else
						AddSelectedProducts(SelectedItemIndexed, LineNumber, ProductsByKey.Products);
					EndIf;	
				EndDo;
				
			EndIf;
			
		EndIf;
		
		// Filling in PM goods.
		NewLineProducts = Object.Goods.Add();
		NewLineProducts.ImportedProducts    = NewRow.NomenclatureName;
		NewLineProducts.ImportedCharacteristic  = NewRow.CharacteristicName;
		NewLineProducts.DownloadableArticleNumber         = NewRow.SKU;
		NewLineProducts.ImportedBarcode        = NewRow.Barcode;
		NewLineProducts.ImportedCode             = NewRow.Code;
		NewLineProducts.ImportedCCDNumber        = NewRow.CCDNumber;
		NewLineProducts.ImportedCountryOfOrigin = NewRow.OriginCountry;
		If ImportQuantity Then
			NewLineProducts.NumberOfPackages        = NewRow.Count;
		EndIf;
		NewLineProducts.RowCode                  = LineNumber;
		FillPropertyValues(NewLineProducts, NewRow,,"SKU");
		
		ArrayOfSelectedProducts = SelectedItemIndexed.FindRows(New Structure("RowCode", LineNumber));
		
		If ArrayOfSelectedProducts.Count() = 1 Then
			FillPropertyValues(NewLineProducts, ArrayOfSelectedProducts.Get(0));
		ElsIf ArrayOfSelectedProducts.Count() = 0 Then
			ErrorText = NStr("vi = 'Theo dữ liệu để tìm kiếm trong dòng %LineNumber% không tìm thấy kết quả trùng khớp.';
							|ru = 'По данным для поиска в строке %LineNumber% совпадений не найдено.';
							|en = 'No matches by data for search in line %LineNumber%.'; fa = 'No matches by data for search in line %LineNumber%.';
							|it = 'Nessuna corrispondenza trovata per la stringa %LineNumber% di ricerca.';
							|pl = 'Według danych dla wyszukiwania w wierszu %LineNumber% nie znaleziono zbieżności.';
							|tr = '%LineNumber% satırındaki arama verileri için hiçbir eşleşme bulunamadı.'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", LineNumber-HeaderHeight);
			CommonClientServer.MessageToUser(ErrorText);
		Else
			ErrorText = NStr("vi = 'Theo dịch vụ để tìm kiếm trong dòng %LineNumber% chưa tìm thấy một số trùng lặp.';
							|ru = 'По данным для поиска в строке %LineNumber% найдено несколько совпадений.';
							|en = 'Several matches are found by data for search in line %LineNumber%.'; fa = 'Several matches are found by data for search in line %LineNumber%.';
							|it = 'Sono state trovate alcune corrispondenze per i dati di ricerca nella riga %LineNumber%.';
							|pl = 'Według danych dla wyszukiwania w wierszu %LineNumber% znaleziono kilka zbieżności. ';
							|tr = '%LineNumber% satırındaki arama verileri için birden fazla eşleşme bulundu.'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", LineNumber - HeaderHeight);
			
			Common.MessageToUser(ErrorText);
		EndIf;
		
		RowsToProcess.Add(NewLineProducts);
		
		LineNumber = LineNumber + 1;
		StringNumber = Format(LineNumber, "NZ=0; NG=0");
		
		Try
			FilledInProductsCodeArticleBarcode = ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnArticle")).Text)
				Or ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnProducts")).Text)
				Or ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("BarcodeColumn")).Text)
				Or ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + ColumnNumbers.Get("ColumnCode")).Text);
		Except
			CommonClientServer.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate();
	ParametersFillInVATRate.Organization = Organization;
	ParametersFillInVATRate.VATTaxation = VATTaxation;
	ParametersFillInVATRate.Date = FillingDate;
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ThisIsReusablePackage);
	If ImportQuantity Then
		StructureOfActions.Insert("RecalculateNumberOfUnits");
	EndIf;
		
	If AmountsRecalculate Then
		
		AmountOfManualDiscountIsFilledIn = Object.Goods.Total("ManualDiscount") <> 0;
		PercentageOfManualDiscountIsFilled = Object.Goods.Total("PercentRateOfManualDiscount") <> 0;
		ThereAreDiscounts = AmountOfManualDiscountIsFilledIn Or PercentageOfManualDiscountIsFilled;
		
		StructureOfRecalculationOfAmount = New Structure;
		StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
		
		If Not ValueIsFilled(Object.Goods.Total("VATAmount")) Or ThereAreDiscounts Then
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		EndIf;
		If Not ValueIsFilled(Object.Goods.Total("AmountIncludingVAT")) Or ThereAreDiscounts Then
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		EndIf; 
		If Not ValueIsFilled(Object.Goods.Total("Sum")) Or ThereAreDiscounts Then
			StructureOfActions.Insert("RecalculateAmount");
		EndIf;
		
		If AmountOfManualDiscountIsFilledIn And Not PercentageOfManualDiscountIsFilled Then
			StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
		ElsIf Not AmountOfManualDiscountIsFilledIn And PercentageOfManualDiscountIsFilled Then
			StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
		EndIf;
		
		If ThereAreDiscounts Then
			StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
		EndIf;
		
	EndIf;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	FillInServiceDetailsForProductRange();
	
	If ImportCCD Then
		AddCCDNumbersToProducts();
	EndIf;
	
	If Object.ImportPackingLists Then
		FillOutPackingLists();
	EndIf;
	
	ClarificationOfProducts.Clear();
	
	SelectedProducts.Load(SelectedItemIndexed);
	SelectedItemIndexed = Undefined;
	
EndProcedure

&AtServer
Function SelectProductsByBarcode(Barcode)
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED DISTINCT
		|	ItemsBarcodes.Barcode AS Barcode,
		|	ItemsBarcodes.Products AS Products,
		|	ItemsBarcodes.Characteristic AS Characteristic,
		|	ItemsBarcodes.Package AS Package
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|		ON (ProductKitConfigurations.Owner = ItemsBarcodes.Products)
		|			AND (ProductKitConfigurations.Owner.ItemsType = VALUE(Enum.ItemsTypes.Set))
		|			AND (ProductKitConfigurations.Characteristic = ItemsBarcodes.Characteristic)
		|			AND (ProductKitConfigurations.Main)
		|WHERE
		|	TRUE
		|	AND ItemsBarcodes.Barcode = &Barcode
		|	AND &TextOfProductSelectionCriteria
		|";
	
	TextOfProductSelectionCriteria = "TRUE";
	If ValueIsFilled(FilterRemainingGoodsByShelfLives) Then
		Conditions = New Array;
		For Each Filter In FilterRemainingGoodsByShelfLives Do
			Conditions.Add(StrTemplate("ItemsBarcodes.Products.%1 IN (&%2)", Filter.Key, Filter.Key));
			Query.SetParameter(Filter.Key, Filter.Value);
		EndDo;
		
		TextOfProductSelectionCriteria = StrConcat(Conditions, Chars.LF + Chars.Tab + "And ");
		
		If FilterRemainingGoodsByShelfLives.Property("ItemsType") Then
			ContainsServices = FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.OperationService) <> Undefined
				Or FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.Work_5) <> Undefined;
			ContainsGoods = FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.ReusablePackage) <> Undefined
				Or FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.OwnGoods) <> Undefined;
			
			If Not ContainsServices
				And ContainsGoods Then
				
				TextOfProductSelectionCriteria = TextOfProductSelectionCriteria + "
					|	AND NOT ISNULL(ProductKitConfigurations.ContainsServices, FALSE)";
				
			EndIf;
			
			If ContainsServices
				And Not ContainsGoods Then
				
				TextOfProductSelectionCriteria = TextOfProductSelectionCriteria + "
					|	AND NOT ISNULL(ProductKitConfigurations.ContainsGoods, FALSE)";
				
			EndIf;
		EndIf;
	EndIf;
	
	Query.Text = StrReplace(Query.Text,"&TextOfProductSelectionCriteria", TextOfProductSelectionCriteria);
	Query.SetParameter("Barcode", Barcode);
	
	Return Query.Execute().Select();
	
EndFunction

&AtServer
Function GetDataAndBPOProductsAndCharacteristics()
	
	Result = New Structure;
	Result.Insert("ProductsTable", New ValueTable);
	Result.Insert("CharacteristicTable", New ValueTable);
	Result.Insert("SupplierProductList", New ValueTable);
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	Products.Ref AS Products,
		|	Products.Code AS Code,
		|	Products.SKU AS SKU,
		|	Products.Description AS Description,
		|	Products.DescriptionFull AS DescriptionFull,
		|	Products.ItemsType = VALUE(Enum.ItemsTypes.Set) AS IsRecordsSet,
		|	Products.UseVariants AS UseVariants,
		|	UNDEFINED AS SignificanceForFeatureSelection
		|INTO ProductsTable
		|FROM
		|	Catalog.Products AS Products
		|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|		ON (ProductKitConfigurations.Owner = Products.Ref)
		|			AND (ProductKitConfigurations.Owner.ItemsType = VALUE(Enum.ItemsTypes.Set))
		|			AND (ProductKitConfigurations.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|			AND (ProductKitConfigurations.Main)
		|WHERE
		|	NOT Products.IsFolder
		|	AND NOT Products.DeletionMark
		|	AND Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
		|	AND &TextOfSelectionCondition
		|
		|UNION
		|
		|SELECT
		|	Products.Ref,
		|	Products.Code,
		|	Products.SKU,
		|	Products.Description,
		|	Products.DescriptionFull,
		|	Products.ItemsType = VALUE(Enum.ItemsTypes.Set),
		|	Products.UseVariants,
		|	CASE
		|		WHEN Products.ItemsType = VALUE(Enum.ItemsTypes.Set)
		|			AND Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse) 
		|			THEN Products.Ref
		|		WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|			THEN Products.Ref
		|		WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|			THEN Products.ItemVariantsOwner
		|		WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
		|			THEN Products.ProductKind
		|		ELSE UNDEFINED
		|	END
		|FROM
		|	Catalog.Products AS Products
		|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|		ON (CASE
		|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|					THEN Products.Ref
		|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|					THEN Products.ItemVariantsOwner
		|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
		|					THEN Products.ProductKind
		|				ELSE UNDEFINED
		|			END = ItemsCharacteristics.Owner)
		|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|		ON (ProductKitConfigurations.Owner = Products.Ref)
		|			AND (ProductKitConfigurations.Owner.ItemsType = VALUE(Enum.ItemsTypes.Set))
		|			AND (ProductKitConfigurations.Characteristic = ItemsCharacteristics.Ref)
		|			AND (ProductKitConfigurations.Main)
		|WHERE
		|	Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
		|	AND NOT Products.DeletionMark
		|	AND NOT ItemsCharacteristics.DeletionMark
		|	AND &TextOfSelectionCondition
		|
		|INDEX BY
		|	Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ProductsTable.UseVariants AS UseVariants,
		|	ProductsTable.SignificanceForFeatureSelection AS SignificanceForFeatureSelection,
		|	ProductsTable.IsRecordsSet AS IsRecordsSet
		|INTO ParametersForSelectingCharacteristics
		|FROM
		|	ProductsTable AS ProductsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	FilterParameters.SignificanceForFeatureSelection AS SignificanceForFeatureSelection,
		|	ItemsCharacteristics.Ref AS Characteristic
		|INTO CharacteristicTable
		|FROM
		|	ParametersForSelectingCharacteristics AS FilterParameters
		|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|		ON FilterParameters.SignificanceForFeatureSelection = ItemsCharacteristics.Owner
		|WHERE
		|	NOT FilterParameters.SignificanceForFeatureSelection = UNDEFINED
		|	AND NOT ItemsCharacteristics.DeletionMark
		|	AND NOT FilterParameters.IsRecordsSet
		|
		|UNION ALL
		|
		|SELECT
		|	FilterParameters.SignificanceForFeatureSelection,
		|	ProductKitConfigurations.Characteristic
		|FROM
		|	Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|		INNER JOIN ParametersForSelectingCharacteristics AS FilterParameters
		|		ON ProductKitConfigurations.Owner = FilterParameters.SignificanceForFeatureSelection
		|		AND ProductKitConfigurations.Main
		|WHERE
		|	NOT FilterParameters.SignificanceForFeatureSelection = UNDEFINED
		|	AND NOT ProductKitConfigurations.DeletionMark
		|	AND FilterParameters.IsRecordsSet
		|	AND &TextOfConditionSelectionByCharacteristic
		|
		|INDEX BY
		|	SignificanceForFeatureSelection,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Har.Characteristic.Description AS ItemVariantName,
		|	Har.Characteristic.DescriptionFull AS FullNameOfTheCharacteristic_3,
		|	Har.Characteristic AS Characteristic,
		|	Har.SignificanceForFeatureSelection AS SignificanceForFeatureSelection
		|FROM
		|	CharacteristicTable AS Har
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Nom.Code AS Code,
		|	Nom.SKU AS SKU,
		|	Nom.Description AS Description,
		|	Nom.DescriptionFull AS DescriptionFull,
		|	Nom.Products AS Products,
		|	Nom.UseVariants AS UseVariants,
		|	Nom.SignificanceForFeatureSelection AS SignificanceForFeatureSelection
		|FROM
		|	ProductsTable AS Nom";
		
	If MapBySupplierProducts Then
		Query.Text = Query.Text + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Nom.Products AS Products,
		|	ProductCrossReferences.Ref AS PartnerProducts,
		|	ProductCrossReferences.SKU AS SupplierProductID,
		|	ProductCrossReferences.Characteristic AS Characteristic
		|FROM
		|	Catalog.ProductCrossReferences AS ProductCrossReferences
		|		INNER JOIN ProductsTable AS Nom
		|		ON (Nom.Products = ProductCrossReferences.Products)
		|		LEFT JOIN CharacteristicTable AS Har
		|		ON (Har.SignificanceForFeatureSelection = Nom.SignificanceForFeatureSelection)
		|			AND (Har.Characteristic = ProductCrossReferences.Characteristic)
		|WHERE
		|	NOT ProductCrossReferences.DeletionMark
		|	AND ProductCrossReferences.Owner = &Partner";
		
		Query.SetParameter("Partner", Object.Partner);
	EndIf;
	
	TextOfProductSelectionCriteria = "TRUE";
	TextOfSelectionCriteriaByCharacteristic = "TRUE";
	If ValueIsFilled(FilterRemainingGoodsByShelfLives) Then
		
		Conditions = New Array;
		For Each Filter In FilterRemainingGoodsByShelfLives Do
			Conditions.Add(StrTemplate("Products.%1 IN (&%2)", Filter.Key, Filter.Key));
			Query.SetParameter(Filter.Key, Filter.Value);
		EndDo;
		
		TextOfProductSelectionCriteria = StrConcat(Conditions, Chars.LF + Chars.Tab + "And ");
		
		If FilterRemainingGoodsByShelfLives.Property("ItemsType") Then
			ContainsServices = FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.OperationService) <> Undefined
				Or FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.Work_5) <> Undefined;
			ContainsGoods = FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.ReusablePackage) <> Undefined
				Or FilterRemainingGoodsByShelfLives.ItemsType.Find(Enums.ItemsTypes.OwnGoods) <> Undefined;
			
			If Not ContainsServices
				And ContainsGoods Then
				
				TextOfProductSelectionCriteria = TextOfProductSelectionCriteria + "
					|	AND NOT ISNULL(ProductKitConfigurations.ContainsServices, FALSE)";
				TextOfSelectionCriteriaByCharacteristic = TextOfSelectionCriteriaByCharacteristic + "
					|	AND NOT ProductKitConfigurations.ContainsServices";
				
			EndIf;
			
			If ContainsServices
				And Not ContainsGoods Then
				
				TextOfProductSelectionCriteria = TextOfProductSelectionCriteria + "
					|	AND NOT ISNULL(ProductKitConfigurations.ContainsGoods, FALSE)";
				TextOfSelectionCriteriaByCharacteristic = TextOfSelectionCriteriaByCharacteristic + "
					|	AND NOT ProductKitConfigurations.ContainsGoods";
				
			EndIf;
		EndIf;
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&TextOfConditionSelectionByCharacteristic", TextOfSelectionCriteriaByCharacteristic);
	Query.Text = StrReplace(Query.Text, "&TextOfSelectionCondition", TextOfProductSelectionCriteria);
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[3]; // QueryResult
	
	For Each ResultColumn In QueryResult.Columns Do
		Result.CharacteristicTable.Columns.Add(ResultColumn.Name);
	EndDo;
	Result.CharacteristicTable.Columns.Add("NameOfTheSearchFeature");
	Result.CharacteristicTable.Columns.Add("FullNameOfCharacteristicSearch");
	SelectingCharacteristicsTable = QueryResult.Select();
	While SelectingCharacteristicsTable.Next() Do
		NewRowOfCharacteristicsTable = Result.CharacteristicTable.Add();
		FillPropertyValues( NewRowOfCharacteristicsTable, SelectingCharacteristicsTable);
		
		NewRowOfCharacteristicsTable.NameOfTheSearchFeature = Upper(StrReplace(NewRowOfCharacteristicsTable.ItemVariantName, " ", ""));
		NewRowOfCharacteristicsTable.FullNameOfCharacteristicSearch = Upper(StrReplace(NewRowOfCharacteristicsTable.FullNameOfTheCharacteristic_3, " ", ""));
	EndDo;
	
	QueryResult = ResultsArray[4]; // QueryResult

	For Each ResultColumn In QueryResult.Columns Do
		Result.ProductsTable.Columns.Add(ResultColumn.Name);
	EndDo;
	Result.ProductsTable.Columns.Add("ProductIDSearch");
	Result.ProductsTable.Columns.Add("NameSearch");
	Result.ProductsTable.Columns.Add("FullNameSearch");
	SelectionOfProductTable = QueryResult.Select();
	While SelectionOfProductTable.Next() Do
		NewRowOfProductTable = Result.ProductsTable.Add();
		FillPropertyValues( NewRowOfProductTable, SelectionOfProductTable);
		
		NewRowOfProductTable.Code = Upper(StrReplace(NewRowOfProductTable.Code, " ", ""));
		NewRowOfProductTable.ProductIDSearch = Upper(StrReplace(NewRowOfProductTable.SKU, " ", ""));
		NewRowOfProductTable.NameSearch = Upper(StrReplace(NewRowOfProductTable.Description, " ", ""));
		NewRowOfProductTable.FullNameSearch = Upper(StrReplace(NewRowOfProductTable.DescriptionFull, " ", ""));
	EndDo;
	
	Result.SupplierProductList.Columns.Add("Products");
	Result.SupplierProductList.Columns.Add("PartnerProducts");
	Result.SupplierProductList.Columns.Add("SupplierProductID");
	Result.SupplierProductList.Columns.Add("Characteristic");
	Result.SupplierProductList.Columns.Add("PartnerProductsSearch");
	Result.SupplierProductList.Columns.Add("SupplierArticleSearch");
	If MapBySupplierProducts Then
		QueryResult = ResultsArray[5]; // QueryResult
		SelectionOfSupplierProductListTable = QueryResult.Select();
		While SelectionOfSupplierProductListTable.Next() Do
			NewRowOfSupplierProductListTable = Result.SupplierProductList.Add();
			FillPropertyValues(NewRowOfSupplierProductListTable, SelectionOfSupplierProductListTable);
			
			NewRowOfSupplierProductListTable.PartnerProductsSearch = Upper(StrReplace(NewRowOfSupplierProductListTable.PartnerProducts, " ", ""));
			NewRowOfSupplierProductListTable.SupplierArticleSearch = Upper(StrReplace(NewRowOfSupplierProductListTable.SupplierProductID, " ", ""));
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Procedure AddCCDNumbersToProducts()
	
	Query = New Query("
	|SELECT
	|	CCDTable.RowCode AS RowCode,
	|	CCDTable.CCDNumber AS CCDNumber,
	|	CCDTable.OriginCountry AS OriginCountry
	|INTO TableOfCCDNumbers
	|FROM
	|	&CCDTable AS CCDTable
	|WHERE
	|	CCDTable.CCDNumber <> """"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CatalogData.Ref AS CCDReferenceNumber,
	|	CatalogData.OriginCountry.Description AS OriginCountry,
	|	TableOfCCDNumbers.CCDNumber AS CCDNumber,
	|	TableOfCCDNumbers.RowCode AS RowCode
	|FROM
	|	TableOfCCDNumbers AS TableOfCCDNumbers
	|		LEFT JOIN Catalog.CCDNumbers AS CatalogData
	|		ON TableOfCCDNumbers.CCDNumber = CatalogData.Code 
	|			AND TableOfCCDNumbers.OriginCountry = CatalogData.OriginCountry.Description
	|WHERE
	|	NOT CatalogData.DeletionMark
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfCCDNumbers.RowCode AS RowCode,
	|	CatalogData.Ref AS OriginCountry
	|FROM
	|	TableOfCCDNumbers AS TableOfCCDNumbers
	|		LEFT JOIN Catalog.WorldCountries AS CatalogData
	|		ON TableOfCCDNumbers.OriginCountry = CatalogData.Description
	|WHERE
	|	NOT CatalogData.DeletionMark");
	CCDTable = ClarificationOfProducts.Unload(,"RowCode, CCDNumber, OriginCountry");
	Query.SetParameter("CCDTable", CCDTable);
	Result = Query.ExecuteBatch();

	SamplingOfCCD = Result[1].Unload();
	SampleCountries = Result[2].Unload();
	
	For Each StringToUpdate In CCDTable Do
		FilterParameters = New Structure;
		FilterParameters.Insert("RowCode", StringToUpdate.RowCode); 
		If ValueIsFilled(StringToUpdate.CCDNumber) Then
			FoundRows = SamplingOfCCD.FindRows(FilterParameters);
			If FoundRows.Count() = 1 Then
				FilledRowsOfProductsTable = Object.Goods.FindRows(New Structure("RowCode", StringToUpdate.RowCode));
				If FilledRowsOfProductsTable.Count() = 1 Then
					FillableFields = FilledRowsOfProductsTable.Get(0);
					FillableFields.CCDNumber = FoundRows.Get(0).CCDReferenceNumber;
				EndIf; 
			ElsIf FoundRows.Count() = 0 Then
				FilledRowsOfProductsTable = Object.Goods.FindRows(New Structure("RowCode", StringToUpdate.RowCode));
				If FilledRowsOfProductsTable.Count() = 1 Then
					FillableFields = FilledRowsOfProductsTable.Get(0);
					FillableFields.CreateCCDNumber = True;
				EndIf;
			EndIf;
			
		EndIf;
		If ValueIsFilled(StringToUpdate.OriginCountry) Then
			CountriesFound = SampleCountries.FindRows(FilterParameters);
			If CountriesFound.Count() = 1 Then
				FillableFields.OriginCountry = CountriesFound.Get(0).OriginCountry;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure InitializeTableDocument()
	
	FillingTemplateBasedOnExternalSource = DataProcessors.ImportGoodsFromExternalFiles.GetTemplate("DataImportTemplate");
	SpreadsheetDocument.Clear();
	
	ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Barcode");
	SpreadsheetDocument.Join(ScopeOfApplication_10);
	ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Code");
	SpreadsheetDocument.Join(ScopeOfApplication_10);
	ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("SKU");
	SpreadsheetDocument.Join(ScopeOfApplication_10);
	ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Products");
	If Object.ImportPackingLists Then
		ScopeOfApplication_10.Parameters.TitleProductLocation = NStr("vi = 'Mặt hàng / Phiếu đóng gói';
																	|ru = 'Номенклатура / Упаковочный лист';
																	|en = 'Items / Packing list'; fa = 'اقلام / فهرست بسته‌بندی';
																	|it = 'Articolo/Distinta di imballaggio';
																	|pl = 'Towar / Specyfikacja ładunkowa';
																	|tr = 'Öğe / Ürün listesi'");
	Else
		ScopeOfApplication_10.Parameters.TitleProductLocation = NStr("vi = 'Mặt hàng';
																	|ru = 'Номенклатура';
																	|en = 'Items'; fa = 'اقلام';
																	|it = 'Articolo';
																	|pl = 'Items';
																	|tr = 'Öğe'");
	EndIf;
	SpreadsheetDocument.Join(ScopeOfApplication_10);
	If UseItemVariants Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Characteristic");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf;
	If ImportQuantity Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Count");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf;
	If ImportInventory Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("MinimumBalance");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("MaximumBalance");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf;
	If ImportPrices Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Price");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf;
	If ImportAmounts Then
		If UseDiscountAdjustmentsInPurchases And ImportDiscounts Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("PercentRateOfManualDiscount");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("ManualDiscount");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
		EndIf;
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Sum");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
		
		If VATTaxation <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("VATAmount");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
			If Not PriceIncludesVAT Then
				ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("AmountIncludingVAT");
				SpreadsheetDocument.Join(ScopeOfApplication_10);
			EndIf;
		EndIf;
	EndIf;
	If ImportCCD Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("CCDNumber");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("OriginCountry");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf;
	
	SpreadsheetDocument.FixedTop = 1;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, PriceIncludesVAT, AmountsRecalculate)
	
	StructureOfRecalculationOfAmount = New Structure;
		
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If Not AmountsRecalculate Then
		Return;
	EndIf;
	
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
											New Structure("Products", "TheRecordsAreKeptByCCD"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
EndProcedure

&AtClient
Procedure FillInSelectionListOfProductCharacteristics(CurLineCode, ListOfCharacteristics = False)
	
	If ListOfCharacteristics Then
		TrackSelectionList = Items.GoodsCharacteristic.ChoiceList;
		TrackSelectionList.Clear();
	Else
		ProductSelectionList  = Items.GoodsProducts.ChoiceList;
		ProductSelectionList.Clear();
	EndIf;
	
	ArrayOfSelectedProducts = SelectedProducts.FindRows(New Structure("RowCode", CurLineCode));
	For Each ArrayElement In ArrayOfSelectedProducts Do
		If ListOfCharacteristics Then
			If TrackSelectionList.FindByValue(ArrayElement.Characteristic) = Undefined
				And ValueIsFilled(ArrayElement.Characteristic) Then
				TrackSelectionList.Add(ArrayElement.Characteristic);
			EndIf;
		Else
			If ProductSelectionList.FindByValue(ArrayElement.Products) = Undefined Then
				ProductSelectionList.Add(ArrayElement.Products);
			EndIf;
		EndIf;
	EndDo; 
EndProcedure

&AtClient
Procedure FillInPackingListSelection(CurLineCode)
	
	ArrayOfSelectedWorkSheets = SelectedPackingLists.FindRows(New Structure("RowCode", CurLineCode));
	ChoiceList = Items.GoodsPackingList.ChoiceList;
	ChoiceList.Clear();
	For Each Page1 In ArrayOfSelectedWorkSheets Do
		PresentationOfPackingList =
			Page1.Code + " " + NStr("vi = 'ngày';
									|ru = 'от';
									|en = 'dated'; fa = 'مورخ';
									|it = 'del';
									|pl = 'od';
									|tr = 'itibaren'") + " " + Page1.Date;
		ChoiceList.Add(Page1.PackingList, PresentationOfPackingList);
	EndDo;

EndProcedure

&AtServer
Function PutProductsInStorage()

	Goods = Object.Goods.Unload();
	
	GoodsForTransfer = Goods.CopyColumns();
	GoodsForTransfer.Columns.Add("ProductsInSet", New TypeDescription("CatalogRef.Products"));
	GoodsForTransfer.Columns.Add("ItemVariantOfSet", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	GoodsForTransfer.Columns.Add("SetIndex", TMCommonUse.GetDescriptionOfNumberTypes(10,0));
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate();
	ParametersFillInVATRate.Organization = Organization;
	ParametersFillInVATRate.VATTaxation = VATTaxation;
	ParametersFillInVATRate.Date = FillingDate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ThisIsReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInCountryOfOriginForCCDNumber");
	
	
	ActionsAreNotSet = New Structure("FillInCountryOfOriginForCCDNumber");
	
	RowsToProcess = New Array();
	RowsToProcessSet = New Array();
	
	For Each TSRow In Goods Do
		
		If TSRow.ItemsType <> Enums.ItemsTypes.Set Then
			NewRow = GoodsForTransfer.Add();
			FillPropertyValues(NewRow, TSRow);
			
			If ValueIsFilled(NewRow.CCDNumber)
				And Not ValueIsFilled(NewRow.OriginCountry) Then
					RowsToProcess.Add(NewRow);
			EndIf;
		Else
			
			ComponentParameters = SelectGoodsClientServer.ProductParameters_1();
			FillPropertyValues(ComponentParameters, TSRow);
			ComponentParameters.ProductsInSet   = TSRow.Products;
			ComponentParameters.ItemVariantOfSet = TSRow.Characteristic;
			ComponentParameters.Insert("ItemKitConfiguration", Undefined);
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("Date",       ComponentsPriceParameters.Date);
			AdditionalParameters.Insert("Currency",     ComponentsPriceParameters.Currency);
			AdditionalParameters.Insert("Terms", ComponentsPriceParameters.Terms);
			AdditionalParameters.Insert("PriceKind",    ComponentsPriceParameters.PriceKind);
			AdditionalParameters.Insert("Price",       TSRow.Price);
			AdditionalParameters.Insert("Organization", Organization);
			SelectedGoods = SetsServerCall.Components(ComponentParameters, AdditionalParameters);
			
			For Each SelectedGoodItem In SelectedGoods Do
				
				NewRow = GoodsForTransfer.Add();
				FillPropertyValues(NewRow, SelectedGoodItem);
				NewRow.SetIndex = 1;
				
				RowsToProcessSet.Add(NewRow);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcessSet,
		StructureOfActions,
		GoodsForTransfer);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		ActionsAreNotSet,
		GoodsForTransfer);
	
	Return PutToTempStorage(GoodsForTransfer);
	
EndFunction

&AtServerNoContext
Function CreateCCDNumber(CCDNumber, OriginCountry)
	
	NewCCDNumber = Catalogs.CCDNumbers.CreateItem();
	ParametersToFill = Catalogs.CCDNumbers.ParametersForFillingElement(CCDNumber, OriginCountry);
	ParametersToFill.FillInSerialNumberOfProductAutomatically = True;
	NewCCDNumber.Fill(ParametersToFill);
	NewCCDNumber.DataExchange.Load = True;
	Try 
		NewCCDNumber.Write();
	Except
		CommonClientServer.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
	Return NewCCDNumber.Ref;
	
EndFunction

&AtServer
Procedure CreateCCDNumbers()
	
	TableOfCCDNumbersBeingCreated = Object.Goods.Unload(New Structure("CreateCCDNumber, TheRecordsAreKeptByCCD", True, True),"ImportedCCDNumber, OriginCountry");
	Query = New Query("
	|SELECT
	|	CCDTable.ImportedCCDNumber AS ImportedCCDNumber,
	|	CCDTable.OriginCountry AS OriginCountry
	|INTO TableOfCCDNumbers
	|FROM
	|	&CCDTable AS CCDTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CatalogData.Ref AS CCDNumber,
	|	TableOfCCDNumbers.ImportedCCDNumber AS ImportedCCDNumber,
	|	TableOfCCDNumbers.OriginCountry AS OriginCountry
	|FROM
	|	TableOfCCDNumbers AS TableOfCCDNumbers
	|		LEFT JOIN Catalog.CCDNumbers AS CatalogData
	|		ON TableOfCCDNumbers.ImportedCCDNumber = CatalogData.Code
	|			AND TableOfCCDNumbers.OriginCountry = CatalogData.OriginCountry
	|			AND NOT CatalogData.DeletionMark
	|
	|GROUP BY
	|	CatalogData.Ref,
	|	TableOfCCDNumbers.ImportedCCDNumber,
	|	TableOfCCDNumbers.OriginCountry");
	Query.SetParameter("CCDTable", TableOfCCDNumbersBeingCreated);
	SamplingOfCCD = Query.Execute().Unload();

	For Each LineToCreate In SamplingOfCCD Do
		If ValueIsFilled(LineToCreate.CCDNumber) Then
			CCDNumberToBeFilledIn = LineToCreate.CCDNumber;
		Else 
			CCDNumberToBeFilledIn = CreateCCDNumber(LineToCreate.ImportedCCDNumber, LineToCreate.OriginCountry);
		EndIf; 
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("ImportedCCDNumber", LineToCreate.ImportedCCDNumber);
		TheStructureOfTheSearch.Insert("OriginCountry", LineToCreate.OriginCountry);
		TheStructureOfTheSearch.Insert("CreateCCDNumber", True);
		TheStructureOfTheSearch.Insert("TheRecordsAreKeptByCCD", True);
		FoundRows = Object.Goods.FindRows(TheStructureOfTheSearch);
			
		For Each RowToFill In FoundRows Do
			RowToFill.CCDNumber = CCDNumberToBeFilledIn;
		EndDo; 
	EndDo;
	
EndProcedure

&AtServer
Procedure SetColumnAvailability()
	
	TMCommonUseClientServer.SetFormItemProperty(Items,
		"GoodsImportedCharacteristic",
		"Visible",
		UseItemVariants);
	
	ItemArray = New Array;
	ItemArray.Add("GoodsGroupCountryOfOrigin");
	ItemArray.Add("ProductsGroupGTDNumber");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Visible",
		ImportCCD,
		True);
	
	ItemArray.Clear();
	ItemArray.Add("GoodsPercentRateOfManualDiscount");
	ItemArray.Add("GoodsManualDiscount");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Visible",
		ImportDiscounts And UseDiscountAdjustmentsInPurchases,
		True);
	
	ItemArray.Clear();
	ItemArray.Add("GoodsPackingList");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Visible",
		Object.ImportPackingLists,
		True);
	
	ItemArray.Clear();
	ItemArray.Add("ProductsPartnerSArticle");
	ItemArray.Add("GoodsPartnerProducts");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Visible",
		MapBySupplierProducts);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure Next(Command)
	FilledInProductsCodeArticleBarcode = ValueIsFilled(SpreadsheetDocument.Area("R2C1").Text)
			Or ValueIsFilled(SpreadsheetDocument.Area("R2C2").Text)
			Or ValueIsFilled(SpreadsheetDocument.Area("R2C3").Text)
			Or ValueIsFilled(SpreadsheetDocument.Area("R2C4").Text);
			
	If Not FilledInProductsCodeArticleBarcode Then
		ShowMessageBox(Undefined, NStr("vi = 'Cần sao chép các cột vào bảng từ tệp ngoài.';
										|ru = 'Необходимо скопировать колонки в таблицу из внешнего файла.';
										|en = 'You must copy columns to the table from an external file.'; fa = 'You must copy columns to the table from an external file.';
										|it = 'È necessario copiare le colonne nella tabella dal file esterno.';
										|pl = 'Należy skopiować kolumny do tablicy z pliku zewnętrznego.';
										|tr = 'Sütunları harici bir dosyadan tabloya kopyalamanız gerekir.'"));
		Return;
	EndIf;
	
	ClearMessages();
	Status(NStr("vi = 'Đang thực hiện so sánh dữ liệu đã nhập với dữ liệu của cơ sở thông tin. Xin vui lòng chờ trong giây lát...';
				|ru = 'Осуществляется сопоставление введенных данных с данными информационной базы. Пожалуйста подождите...';
				|en = 'Entered data is being mapped with the infobase data. Please wait...'; fa = 'Entered data is being mapped with the infobase data. Please wait...';
				|it = 'Viene eseguita l''associazione dei dati inseriti con i dati del database informatico. Attendere prego...';
				|pl = 'Odbywa się zestawienie wprowadzonych danych z danymi z bazy informacyjnej. Proszę czekać...';
				|tr = 'Girilen veriler infobase''deki verilerle karşılaştırılır. Lütfen bekle...'"),,,PictureLib.Information32);
	CompareTableDocumentDataWithInformationSecurityData();

	Items.Steps.CurrentPage = Items.Step2;
	
EndProcedure

&AtClient
Procedure Back(Command)
	Items.Steps.CurrentPage = Items.Step1;
EndProcedure

&AtClient
Procedure MoveGoods(Command)
	
	ClearMessages();
	CreateCCDNumbers = False;
	If Object.Goods.FindRows(New Structure("CreateCCDNumber, TheRecordsAreKeptByCCD", True, True)).Count()>0 Then
		ButtonsList = New ValueList();
		ButtonsList.Add("Create", NStr("vi = 'Tạo mới';
										|ru = 'Создать';
										|en = 'Create'; fa = 'ایجاد';
										|it = 'Creare';
										|pl = 'Create';
										|tr = 'Oluştur'"));
		ButtonsList.Add("WithoutCreation", NStr("vi = 'Không tạo mới';
												|ru = 'Не создавать';
												|en = 'Do not create'; fa = 'ایجاد نشود';
												|it = 'Non creare';
												|pl = 'Nie tworzyć';
												|tr = 'Oluşturma'"));
		ButtonsList.Add("Cancel", NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'"));
		
		ShowQueryBox(New CallbackDescription("MoveGoodsCompletion", ThisObject), 
			NStr("vi = 'Không tìm thấy nhiều số tờ khai hải quan được kết nhập vào cơ sở thông tin. Tạo mới tờ khai hải quan?';
				|ru = 'Некоторые загружаемые номера ГТД не найдены в информационной базе. Создать номера ГТД?';
				|en = 'Some imported CCD numbers are not found in the infobase. Create CCD numbers?'; fa = 'Some imported CCD numbers are not found in the infobase. Create CCD numbers?';
				|it = 'Alcuni numeri di dichiarazione doganale scaricabili non sono stati trovati nel database. Creare numeri di dichiarazione doganale?';
				|pl = 'Niektóre pobierane numery ŁDC nie znaleziono w bazie informacyjnej. Utworzyć numery ŁDC?';
				|tr = 'Yüklenen bazı GKB numaraları infobase''de bulunmadı. GKB numarası oluşturulsun mu?'"), 
			ButtonsList);
		Return;
	EndIf;
	
	MoveToFragment();
EndProcedure

&AtClient
Procedure MoveGoodsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "Cancel" Then
		Return;
	ElsIf QuestionResult = "Create" Then
		CreateCCDNumbers = True;
	EndIf;
	MoveToFragment();
	
EndProcedure

&AtClient
Procedure MoveToFragment()
	
	If CheckFilling() Then
		If CreateCCDNumbers Then
			CreateCCDNumbers();
		EndIf;
		GoodsAddressInStorage = PutProductsInStorage();
		Close(GoodsAddressInStorage);
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// The mark of an unfilled characteristic if the form is open with the parameter checkfillationcharacteristics = True.
	If Parameters.CheckCharacteristicPopulation Then

		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantsAreUsed");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);

	EndIf;

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountIncludingVAT.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceIncludesVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountIncludingVAT.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ImportAmounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	// Hiding the number of packages

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsUnitOfMeasure.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ImportQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	// Hiding stocks

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsMinimumBalance.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsMaximumBalance.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ImportInventory");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<ürünler için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<TKHQ không được sử dụng>';
													|ru = '<ГТД не используются>';
													|en = '<CCD numbers are not used>'; fa = '<CCD numbers are not used>';
													|it = '<Le dichiarazioni doganali di carico non vengono usate>';
													|pl = '<ŁDC nie jest używana>';
													|tr = '<Kargo Gümrük Beyannamesi kullanılmıyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsImportedCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseItemVariants");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsImportedCCDNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ImportCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ImportPrices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsImportedCCDNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsDownloadableRoomRtdinfo.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsImportedCountryOfOrigin.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOriginCountry.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsImportedCCDNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsDownloadableRoomRtdinfo.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ImportedCCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsDownloadableRoomRtdinfo.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ImportedCCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<sẽ tạo>';
													|ru = '<будет создан>';
													|en = '<will be created>'; fa = '<will be created>';
													|it = '<sarà creato>';
													|pl = '<zostanie utworzony>';
													|tr = '<oluşturulacak>'"));
	Item.Appearance.SetParameterValue("Show", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsDownloadableRoomRtdinfo.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.NotGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ImportedCCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsImportedCountryOfOrigin.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ImportedCountryOfOrigin");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.OriginCountry");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.OriginCountry");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CreateCCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsImportedCountryOfOrigin.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.OriginCountry");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ImportedCountryOfOrigin");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.OriginCountry");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không tìm thấy>';
													|ru = '<не найдена>';
													|en = '<not found>'; fa = '<یافت نشد>';
													|it = '<non trovata>';
													|pl = '<nie znaleziona>';
													|tr = '<bulunamadı>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ImportAmounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<ürünler için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'vị trí';
													|ru = 'место';
													|en = 'place'; fa = 'place';
													|it = 'luogo';
													|pl = 'place';
													|tr = 'yer'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackingList.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng cho hàng hóa>';
													|ru = '<не используется для товаров>';
													|en = '<not used for goods>'; fa = '<not used for goods>';
													|it = '<non si utilizza per le merci>';
													|pl = '<nie jest używane dla towarów>';
													|tr = '<ürünler için kullanılmıyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure FillOutPackingLists()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TTCodes.Code,
	|	TTCodes.RowCode
	|INTO TTCodes
	|FROM
	|	&CodesOfPackingListsForCheck AS TTCodes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackingList.Ref AS PackingList,
	|	PackingList.Code AS Code,
	|	PackingList.Date AS Date,
	|	TTCodes.RowCode
	|INTO TTSelectedPackingSheets
	|FROM
	|	Document.PackingList AS PackingList
	|		INNER JOIN TTCodes AS TTCodes
	|		ON PackingList.Code = TTCodes.Code
	|		AND PackingList.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTSelectedPackingSheets.PackingList,
	|	TTSelectedPackingSheets.Code,
	|	TTSelectedPackingSheets.Date,
	|	TTSelectedPackingSheets.RowCode
	|FROM
	|	TTSelectedPackingSheets AS TTSelectedPackingSheets
	|
	|ORDER BY
	|	TTSelectedPackingSheets.PackingList.Code,
	|	TTSelectedPackingSheets.PackingList.Date DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTSelectedPackingSheets.RowCode,
	|	MAX(TTSelectedPackingSheets.PackingList) AS PackingList
	|FROM
	|	TTSelectedPackingSheets AS TTSelectedPackingSheets
	|
	|GROUP BY
	|	TTSelectedPackingSheets.RowCode
	|
	|HAVING
	|	COUNT(TTSelectedPackingSheets.PackingList) = 1";
	Query.SetParameter("CodesOfPackingListsForCheck", CodesOfPackingListsForCheck.Unload());
	
	QueryResult = Query.ExecuteBatch();
	SelectedPackingLists.Load(QueryResult[2].Unload());
	For Each Page1 In QueryResult[3].Unload() Do
		Object.Goods[Page1.RowCode - 2].PackingList = Page1.PackingList;
		Object.Goods[Page1.RowCode - 2].Count = 1;
		Object.Goods[Page1.RowCode - 2].NumberOfPackages = 1;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function AssignNumericValueWhenFillingInTS(Receiver, StringSourceOfNumericValue, AbsoluteLineNumber, NameOfColumn, HeaderHeight = 0)
	Success = True;
	
	ValueForCasting = StrReplace(StringSourceOfNumericValue, " ", "");
	If ValueIsFilled(ValueForCasting) Then
		MTypes = New Array;
		MTypes.Add(Type("Number"));
		MTypes.Add(Type("TypeDescription"));
		DescriptionOfHTypes = New TypeDescription(MTypes);
		CastedValue = DescriptionOfHTypes.AdjustValue(ValueForCasting);
		If Not CastedValue = Undefined Then
			Receiver = CastedValue;			
		Else
			Success = False;
			ErrorText = NStr("vi = 'Trong dòng %LineNumber%, cột ""%Column%"" chọn giá trị ""%Value%"", không phải là số.';
							|ru = 'В строке %LineNumber%, колонке ""%Column%"" введено значение ""%Value%"", не являющееся числом.';
							|en = 'In line %LineNumber% in column ""%Column%"", value ""%Value%"" is entered. The value is not a digit.'; fa = 'In line %LineNumber% in column ""%Column%"", value ""%Value%"" is entered. The value is not a digit.';
							|it = 'Nella riga %LineNumber%, colonna""%Column%"" è inserito il valore ""%Value%"", che non è un numero.';
							|pl = 'W wierszu %LineNumber%, kolumnie ""%Column%"" wprowadzono wartość ""%Value%"", nie będące liczbą.';
							|tr = 'Satır %LineNumber%, sütun ""%Column%"" içine sayı olmayan bir ""%Value%"" değeri girilir.'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", AbsoluteLineNumber-HeaderHeight);
			ErrorText = StrReplace(ErrorText, "%Column%", NameOfColumn);
			ErrorText = StrReplace(ErrorText, "%Value%", StringSourceOfNumericValue);
			CommonClientServer.MessageToUser(ErrorText);
		EndIf;	
	Else
		Receiver = 0;
	EndIf;
	
	Return Success;
EndFunction

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	GoodsPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

#EndRegion
