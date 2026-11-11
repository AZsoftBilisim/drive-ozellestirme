
#Region Variables

&AtClient 
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ItemsType = Common.ObjectAttributeValue(Parameters.Products, "ItemsType");
	If ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		MessageText = NStr("vi = 'Không thể thay đổi chất lượng dịch vụ.';
							|ru = 'Качество услуг изменять нельзя.';
							|en = 'Service quality cannot be changed.'; fa = 'Service quality cannot be changed.';
							|it = 'Impossibile modificare la qualità dei servizi.';
							|pl = 'Jakość usług nie może być zmieniana.';
							|tr = 'Hizmet kalitesi değiştirilemez.'");
		Raise MessageText;
	ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		MessageText = NStr("vi = 'Không thể thay đổi chất lượng công việc.';
							|ru = 'Качество работ изменять нельзя.';
							|en = 'Work quality cannot be changed.'; fa = 'Work quality cannot be changed.';
							|it = 'Impossibile modificare la qualità dei lavori.';
							|pl = 'Jakość prac nie może być zmieniana.';
							|tr = 'Hizmet kalitesi değiştirilemez.'");
		Raise MessageText;
	EndIf;
	
	If Not GetFunctionalOption("UseSummaryAccountingOfLowQualityGoods") Then
		Items.PageFormGroup.PagesRepresentation = FormPagesRepresentation.None;
		Items.PageFormGroup.CurrentPage    = Items.PageByItem;
	EndIf;
	
	ProductOfOriginalQuality = InformationRegisters.AnotherQualityGoods.GetOriginalQualityGoods(Parameters.Products);
	If ValueIsFilled(ProductOfOriginalQuality) Then
		Products = ProductOfOriginalQuality;
		CommonClientServer.SetDynamicListFilterItem(ProductList, "Products", ProductOfOriginalQuality, DataCompositionComparisonType.Equal,,True);
	Else
		MessageTextTemplate = NStr("vi = 'Đối với hàng hóa %OwnGoods% không tìm thấy hàng hóa chất lượng ban đầu. Không thể chọn hàng hóa có chất lượng khác.';
									|ru = 'Для товара %OwnGoods% не найден товар исходного качества. Выбор товаров другого качества невозможен.';
									|en = 'For goods %OwnGoods% the nonconforming products are not found. Cannot select goods of other quality.'; fa = 'For goods %OwnGoods% the nonconforming products are not found. Cannot select goods of other quality.';
									|it = 'Nessun prodotto della qualità originale trovato per il prodotto %OwnGoods%. La selezione di prodotti di un''altra qualità non è possibile.';
									|pl = 'Dla towaru %OwnGoods% nie znaleziono towaru o wyjściowej jakości. Wybór towarów innej jakości nie jest możliwy.';
									|tr = 'Ürün için %OwnGoods% orijinal kalitedeki ürün bulunamadı. Uygun kalitede olmayan ürünler seçimi mümkün değildir.'");
		MessageText = StrReplace(MessageTextTemplate, "%OwnGoods%", Common.ObjectAttributeValue(Parameters.Products, "Description"));
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	Items.GroupCreateALowQualityProduct.Visible  = AccessRight("Insert", Metadata.Catalogs.Products);
	Items.GroupCreateALowQualityProduct1.Visible = AccessRight("Insert", Metadata.Catalogs.Products);
	Items.TheGeneralPageOfTheList.Visible              = AccessRight("Update", Metadata.InformationRegisters.AnotherQualityGoods);
	If Items.TheGeneralPageOfTheList.Visible Then
		ProductsFields = New Structure;
		ProductsFields.Insert("ProductKind");
		ProductsFields.Insert("KeepAccountingByBatch",           "ProductKind.KeepAccountingByBatch");
		ProductsFields.Insert("BatchUsageSettings", "ProductKind.BatchUsageSettings");
		ProductAttributes = Common.ObjectAttributesValues(Parameters.Products, ProductsFields);
		If ProductAttributes.KeepAccountingByBatch
			And Not ProductAttributes.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
			CommonClientServer.SetDynamicListFilterItem(GeneralList,
				"ProductKind",
				ProductAttributes.ProductKind,
				DataCompositionComparisonType.Equal,,
				True);
			Items.TheGeneralPageOfTheList.Title = NStr("vi = 'Hàng hóa có chất lượng khác với dạng mặt hàng có chất lượng ban đầu';
														|ru = 'Товары другого качества с видом номенклатуры товара исходного качества';
														|en = 'Nonconforming products with item kind of goods of the original quality'; fa = 'Nonconforming products with item kind of goods of the original quality';
														|it = 'Merci di altra qualità con il tipo di articolo dei prodotti della qualità originale';
														|pl = 'Wiersze pozycji innej jakości z rodzajem towaru, towaru jakości wyjściowej';
														|tr = 'Öğe türü orijinal kalitede olan diğer kalitede ürünler'");
		EndIf;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_Products" Then
		If ValueIsFilled(Source) Then
			SetQualityGradation(Source);
			Items.GeneralList.CurrentRow = Source;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ProcessSelectionOfPoorQualityProducts();
	
EndProcedure

&AtClient
Procedure GeneralListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ProcessSelectionOfPoorQualityProducts();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)

	ProcessSelectionOfPoorQualityProducts();

EndProcedure

&AtClient
Procedure CreateALimitedUseItem(Command)
	Quality = PredefinedValue("Enum.QualityLevels.SuitableToALimitedExtent"); 
	CreateProductsWithDifferentQuality(Quality);
EndProcedure

&AtClient
Procedure CreateAnInvalidItem(Command)
	Quality = PredefinedValue("Enum.QualityLevels.NotUsable"); 
	CreateProductsWithDifferentQuality(Quality);
EndProcedure 
 
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Function CheckSetGradation(ProductOfOriginalQuality, LowQualityProduct)
	Cancel = False;
	ThereIsGradation = InformationRegisters.AnotherQualityGoods.CheckForGradation(ProductOfOriginalQuality, LowQualityProduct);
	If Not ThereIsGradation Then
		Try
			InformationRegisters.AnotherQualityGoods.RecordLinkToProductOfDifferentQuality(ProductOfOriginalQuality, LowQualityProduct);
		Except
			Cancel = True;
		EndTry;
	EndIf;	
	
	Return Cancel;
EndFunction

&AtServer
Procedure SetQualityGradation(LowQualityProduct) 
	                                       
	InformationRegisters.AnotherQualityGoods.RecordLinkToProductOfDifferentQuality(Products, LowQualityProduct);
	
EndProcedure

&AtClient
Procedure ProcessSelectionOfPoorQualityProducts()
	
	ClearMessages();
	
	Cancel = False;
	CheckGradation = False;
	
	If Items.PageFormGroup.CurrentPage = Items.PageByItem Then
		CurrentData = Items.List.CurrentData;
		If CurrentData = Undefined Then
			Return
		EndIf;
		LowQualityProduct = CurrentData.OtherQualityGoods;
	Else
		CurrentData = Items.GeneralList.CurrentData;
		If CurrentData = Undefined Then
			Return
		EndIf;
		LowQualityProduct = CurrentData.Ref;
		CheckGradation = True;
		ThereIsMatch = False;
	EndIf;
	
	If CheckGradation Then
		Cancel = CheckSetGradation(Products, LowQualityProduct);	
	EndIf;
	 
	If Not Cancel And GeneralPurposeTMServerCall.ObjectAttributeValue(LowQualityProduct, "DeletionMark") Then
		ShowQueryBox(New CallbackDescription("ProcessSelectionOfPoorQualityProductsCompletion", ThisObject, New Structure("LowQualityProduct, Cancel", LowQualityProduct, Cancel)), NStr("vi = 'Dữ liệu được chọn đã bị đặt dấu xóa.
			|Chọn dữ liệu này?';
			|ru = 'Выбранные данные помечены на удаление.
			|Выполнить выбор этих данных?';
			|en = 'Selected data is marked for deletion.
			|Select this data?'; fa = 'Selected data is marked for deletion.
			|Select this data?';
			|it = 'Selezionati dei dati contrassegnati per la cancellazione.
			|Effettuare la scelta dei dati?';
			|pl = 'Wybrane dane są zaznaczone do usunięcia.
			|Wybrać te dane?';
			|tr = 'Seçilen veriler silinmek üzere işaretlenir.
			|Bu verilerin seçimini gerçekleştir?'") , QuestionDialogMode.YesNo);
        Return;
	EndIf;

	ProcessSelectionOfLowQualityProductsClientFragment(LowQualityProduct, Cancel);
EndProcedure

&AtClient
Procedure ProcessSelectionOfPoorQualityProductsCompletion(QuestionResult, AdditionalParameters) Export
    
    LowQualityProduct = AdditionalParameters.LowQualityProduct;
    Cancel = AdditionalParameters.Cancel;
    
    
    If QuestionResult = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ProcessSelectionOfLowQualityProductsClientFragment(LowQualityProduct, Cancel);

EndProcedure

&AtClient
Procedure ProcessSelectionOfLowQualityProductsClientFragment(Val LowQualityProduct, Val Cancel)
    
    If Not Cancel Then
        Close(LowQualityProduct);
    EndIf;

EndProcedure

&AtClient
Procedure CreateProductsWithDifferentQuality(Quality)
	ParametersForCreatingForm = New Structure;
	ParametersForCreatingForm.Insert("Quality", Quality);
	
	FormParameters = New Structure("CopyingValue, AdditionalParameters", Products, ParametersForCreatingForm);
	OpenForm(
		"Catalog.Products.ObjectForm", 
		FormParameters,
		,
		,
		,
		,
		New CallbackDescription("CreateProductsWithDifferentQualityCompletion", ThisObject), 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CreateProductsWithDifferentQualityCompletion(Result, AdditionalParameters) Export
	
	Items.List.Refresh();

EndProcedure

&AtClient
Procedure PageFormGroupOnCurrentPageChange(Item, CurrentPage)
	If Items.PageFormGroup.CurrentPage = Items.PageByItem Then
		Items.CommandBarsPages.CurrentPage = Items.PageRelatedGoodsListCommandBar;
	Else 
		Items.CommandBarsPages.CurrentPage = Items.PageGeneralListCommandBar;
	EndIf;
EndProcedure

#EndRegion

#EndRegion
