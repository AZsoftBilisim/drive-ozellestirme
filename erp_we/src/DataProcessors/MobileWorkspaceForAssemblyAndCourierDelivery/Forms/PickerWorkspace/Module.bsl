#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurrentForm = "DesktopForm";
	
	OrderDocument = Parameters.OrderDocument;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	OrderCurrency_ = Common.ObjectAttributeValue(OrderDocument, "Currency");
	OrderNumber = Common.ObjectAttributeValue(OrderDocument, "Number");
	Currency = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.CurrencyPresentation(OrderCurrency_);
	
	FillInFormTablesByOrder();
	CreateGroupTables();
	
	SoftwareInterfaceFormation();
	
	RecalculateGroupTotals();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ChangeSectionAndActiveCommands();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If CurrentForm = "DesktopForm" Then
		SaveIntermediateData();
		Close();
	ElsIf CurrentForm = "ProductCardForm" Then
		Items.DesktopForm.Visible = True;
		Items.ProductCardForm.Visible = False;
		Title = NStr("vi = 'Đặt hàng:';
					|ru = 'Заказ:';
					|en = 'Order:'; fa = 'سفارش:';
					|it = 'Ordine:';
					|pl = 'Zamówienie:';
					|tr = 'Sipariş:'") + OrderNumber;
		CurrentForm = "DesktopForm";
		Cancel = True;
	ElsIf CurrentForm = "CollectProductForm" Then
		Items.ProductCardForm.Visible = True;
		Items.CollectProductForm.Visible = False;
		Title = NStr("vi = 'Thẻ đơn hàng';
					|ru = 'Карточка заказа';
					|en = 'Order card'; fa = 'Order card';
					|it = 'Cartellino ordine';
					|pl = 'Karta zamówienia';
					|tr = 'Sipariş kartı'");
		CurrentForm = "ProductCardForm";
		HideCalculator();
		Cancel = True;
	ElsIf CurrentForm = "FormSearchByBarcode" Then
		Items.ProductCardForm.Visible = True;
		Items.FormSearchByBarcode.Visible = False;
		Title = NStr("vi = 'Thẻ đơn hàng';
					|ru = 'Карточка заказа';
					|en = 'Order card'; fa = 'Order card';
					|it = 'Cartellino ordine';
					|pl = 'Karta zamówienia';
					|tr = 'Sipariş kartı'");
		CurrentForm = "ProductCardForm";
		HideCalculator();
		Cancel = True;
	ElsIf CurrentForm = "ReplacementConfirmationForm" Then
		Items.FormSearchByBarcode.Visible = True;
		Items.ReplacementConfirmationForm.Visible = False;
		Title = NStr("vi = 'Thay thế hàng hóa';
					|ru = 'Замена товара';
					|en = 'Goods item replacement'; fa = 'Goods item replacement';
					|it = 'Sostituzione del prodotto';
					|pl = 'Zmiana towaru';
					|tr = 'Ürün değişimi'");
		CurrentForm = "FormSearchByBarcode";
		HideCalculator();
		ShowCalculator(1);
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure StartTheBuild(Command)
	
	StatusSet = StartBuildingOnServer();
	
	If StatusSet Then
		ChangeSectionAndActiveCommands();
	EndIf;
	
EndProcedure

&AtClient
Procedure SectionToBuild(Command)
	ChangeSection("ForAssembly");
EndProcedure

&AtClient
Procedure SectionToClarify(Command)
	ChangeSection("ToClarify");
EndProcedure

&AtClient
Procedure CollectedSection(Command)
	ChangeSection("Assembled");
EndProcedure

&AtClient
Procedure ToAssemble(Command)
	
	CurrentForm = "CollectProductForm";
	Title = NStr("vi = 'Tập hợp hàng hóa';
				|ru = 'Собрать товар';
				|en = 'Pick goods item'; fa = 'Pick goods item';
				|it = 'Prelevare prodotto';
				|pl = 'Zbierz towar';
				|tr = 'Ürünü montaj et'");
	
	Items.ProductCardForm.Visible = False;
	Items.CollectProductForm.Visible = True;
	ChangeConfirmationCommand();
	
EndProcedure

&AtClient
Procedure Replace(Command)
	
	Barcode = "";
	
	CurrentForm = "FormSearchByBarcode";
	Title = NStr("vi = 'Tìm kiếm theo mã vạch';
				|ru = 'Поиск по штрихкоду';
				|en = 'Search by barcode'; fa = 'جستجو بر اساس بارکد';
				|it = 'Ricerca per codice a barre';
				|pl = 'Wyszukiwanie za pomocą kodu kreskowego';
				|tr = 'Barkod ile arama'");
	
	Items.ProductCardForm.Visible = False;
	Items.FormSearchByBarcode.Visible = True;
	
	If SearchResult.Count() > 0 Then
		
		// Deleting old search results
		For Each FoundProduct In SearchResult Do
			DeleteProductCardOnServer("SearchResult", FoundProduct.ID);
		EndDo;
		
		SearchResult.Clear();
	EndIf;
	
	ShowCalculator(1);
	
EndProcedure

&AtClient
Procedure CancelCollected(Command)
	CurrentForm = "DesktopForm";
	Title = NStr("vi = 'Đặt hàng:';
				|ru = 'Заказ:';
				|en = 'Order:'; fa = 'سفارش:';
				|it = 'Ordine:';
				|pl = 'Zamówienie:';
				|tr = 'Sipariş:'") + OrderNumber;
	
	UndoCollectedOnServer();
	
	RecalculateGroupTotals();
	
	DeleteProductCardOnServer("Assembled", ID);
	Items.DesktopForm.Visible = True;
	Items.ProductCardForm.Visible = False;
	HideCalculator();
	
	ChangeSectionAndActiveCommands();
EndProcedure

&AtClient
Procedure CancelOutOfStock(Command)
	CurrentForm = "DesktopForm";
	Title = NStr("vi = 'Đặt hàng:';
				|ru = 'Заказ:';
				|en = 'Order:'; fa = 'سفارش:';
				|it = 'Ordine:';
				|pl = 'Zamówienie:';
				|tr = 'Sipariş:'") + OrderNumber;
	
	CancelItemNotOnServer();
	
	RecalculateGroupTotals();
	
	DeleteProductCardOnServer("ProductNo", ID);
	Items.DesktopForm.Visible = True;
	Items.ProductCardForm.Visible = False;
	HideCalculator();
	
	ChangeSectionAndActiveCommands();

EndProcedure

&AtClient
Procedure AboutTheOrder(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ReferenceOrder", OrderDocument);
	FormOpenParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ReferenceCard",
		FormOpenParameters,
		ThisForm,,,,,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#If MobileClient Then
	
&AtClient
Procedure Scan(Command)
	
	If MultimediaTools.BarcodeScanningSupported() Then
		
		ScanningHandler = New CallbackDescription("ScanProcessing", ThisForm);
		
		MultimediaTools.ShowBarcodeScanning(NStr("vi = 'Hướng máy ảnh vào mã vạch';
												|ru = 'Наведите камеру на штрихкод';
												|en = 'Point the camera at the barcode'; fa = 'Point the camera at the barcode';
												|it = 'Puntare la camera sul codice a barre';
												|pl = 'Skieruj aparat na kod kreskowy';
												|tr = 'Kamerayı barkoda doğrult'"),
			ScanningHandler,
			,
			BarcodeType.Linear);
	EndIf;

EndProcedure

&AtClient
Procedure ScanProcessing(SHK, Result, Message, AdditionalParameters) Export

	If Result Then
		
		MultimediaTools.PlaySoundAlert(SoundAlert.Default,True);
		MultimediaTools.CloseBarcodeScanning();
		
		Barcode = SHK;
		
		ProductSearchByBarcode();
	Else	
		Message = NStr("vi = 'Lỗi xử lý mã vạch';
						|ru = 'Ошибка обработки штрих кода';
						|en = 'Barcode processing error'; fa = 'Barcode processing error';
						|it = 'Errore di elaborazione del codice a barre';
						|pl = 'Wystąpił błąd podczas przetwarzania kodu kreskowego';
						|tr = 'Barkod işleme hatası'");
	EndIf;
	
EndProcedure

#EndIf

&AtClient
Procedure ReducedAmount(Command)
	If Number(Items.NumberOfEntries_4.Title) - 1 < 0 Then
		Return
	EndIf;
	
	Items.NumberOfEntries_4.Title = Number(Items.NumberOfEntries_4.Title) - 1;
	ChangeConfirmationCommand();
EndProcedure

&AtClient
Procedure IncreasedAmount(Command)
	Items.NumberOfEntries_4.Title = Number(Items.NumberOfEntries_4.Title) + 1;
	ChangeConfirmationCommand();
EndProcedure

&AtClient
Procedure NumberOfEntries_4(Command)
	Items.ProductPropertiesCollect.Visible = Not Items.ProductPropertiesCollect.Visible;
	Items.WarningGroup.Visible  = Not Items.WarningGroup.Visible;
	ChangeConfirmationCommand();
	ShowCalculator(0);
EndProcedure

#Region Calculator

&AtClient
Procedure CommandPoint(Command)
	CalculatorComma = True;
EndProcedure

&AtClient
Procedure TheCleanCommand(Command)
	
	If CurrentForm = "CollectProductForm" Then
		NumberOfCharacters = StrLen(Items.NumberOfEntries_4.Title);
		Items.NumberOfEntries_4.Title = Mid(Items.NumberOfEntries_4.Title, 1, NumberOfCharacters - 1);
		
		ChangeConfirmationCommand();
	ElsIf CurrentForm = "FormSearchByBarcode" Then
		NumberOfCharacters = StrLen(Barcode);
		Barcode = Mid(Barcode, 1, NumberOfCharacters - 1);
	ElsIf CurrentForm = "ReplacementConfirmationForm" Then
		NumberOfCharacters = StrLen(Items.NumberOfReplacementLev.Title);
		Items.NumberOfReplacementLev.Title = Mid(Items.NumberOfReplacementLev.Title, 1, NumberOfCharacters - 1);
		Items.TheNumberOfReplacementRights.Title = Items.NumberOfReplacementLev.Title;
		
		If Items.NumberOfReplacementLev.Title = "" Then
			Items.NumberOfReplacementLev.Title = "0";
			Items.TheNumberOfReplacementRights.Title = "0";
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Calculator0(Command)
	EnterValue("0");
EndProcedure

&AtClient
Procedure Calculator1(Command)
	EnterValue("1");
EndProcedure

&AtClient
Procedure Calculator2(Command)
	EnterValue("2");
EndProcedure

&AtClient
Procedure Calculator3(Command)
	EnterValue("3");
EndProcedure

&AtClient
Procedure Calculator4(Command)
	EnterValue("4");
EndProcedure

&AtClient
Procedure Calculator5(Command)
	EnterValue("5");
EndProcedure

&AtClient
Procedure Calculator6(Command)
	EnterValue("6");
EndProcedure

&AtClient
Procedure Calculator7(Command)
	EnterValue("7");
EndProcedure

&AtClient
Procedure Calculator8(Command)
	EnterValue("8");
EndProcedure

&AtClient
Procedure Calculator9(Command)
	EnterValue("9");
EndProcedure

#EndRegion

&AtClient
Procedure Confirm(Command)
	
	CurrentForm = "DesktopForm";
	Title = NStr("vi = 'Đặt hàng:';
				|ru = 'Заказ:';
				|en = 'Order:'; fa = 'سفارش:';
				|it = 'Ordine:';
				|pl = 'Zamówienie:';
				|tr = 'Sipariş:'") + OrderNumber;
	
	Try 
		QuantityConfirmed = Number(Items.NumberOfEntries_4.Title);
	Except
		QuantityConfirmed = 0;
	EndTry;
	
	Try 
		CountPlan = Number(Items.TheNumberOfInputPlan.Title);
	Except
		CountPlan = 0;
	EndTry;
	
	If QuantityConfirmed = 0 Then
		TransferToSpecify(CountPlan);
	Else
		MovingToCollected(QuantityConfirmed);
		TransferToSpecify(CountPlan - QuantityConfirmed);
	EndIf;
	
	RecalculateGroupTotals();
	
	DeleteProductCardOnServer("ForAssembly", ID);
	Items.DesktopForm.Visible = True;
	Items.CollectProductForm.Visible = False;
	HideCalculator();
	
	ChangeSectionAndActiveCommands();
	
EndProcedure

&AtClient
Procedure FinishTheBuild(Command)
	
	If ForAssembly.Count() > 0 Then
		DoQueryBox = NStr("vi = 'Không phải tất cả hàng hóa đã được tập hợp. Kết thúc đóng bộ đơn hàng?';
							|ru = 'Собраны не все товары. Завершить сборку заказа?';
							|en = 'Not all goods have been picked. Complete picking the order?'; fa = 'Not all goods have been picked. Complete picking the order?';
							|it = 'Non tutti i prodotti sono stati prelevati. Completare l''assemblaggio dell''ordine?';
							|pl = 'Zebrano nie wszystkie towary. Zakończyć kompletację zamówienia?';
							|tr = 'Tüm ürünler toplanmadı. Sipariş montajı tamamlansın mı?'");
	ElsIf Substitutions_3.Count() > 0 Then
		DoQueryBox = NStr("vi = 'Đã xử lý không phải tất cả thay thế. Kết thúc tập hợp đơn hàng?';
							|ru = 'Отработаны не все замены. Завершить сборку заказа?';
							|en = 'Not all replacements have been processed. Complete picking the order?'; fa = 'Not all replacements have been processed. Complete picking the order?';
							|it = 'Non tutte le sostituzioni sono state esaminate. Completare l''assemblaggio dell''ordine?';
							|pl = 'Wypracowano nie wszystkie zmiany. Zakończyć kompletację zamówienia?';
							|tr = 'Tüm değiştirmeler işlenmedi. Sipariş montajı tamamlansın mı?'");
	ElsIf ReturnToTheShelf.Count() > 0 Then
		DoQueryBox = NStr("vi = 'Không phải tất cả hàng hóa đã được trả lại lên kệ. Kết thúc tập hợp đơn hàng?';
							|ru = 'Не все товары возвращены на полку. Завершить сборку заказа?';
							|en = 'Not all goods were returned to the shelf. Complete picking the order?'; fa = 'Not all goods were returned to the shelf. Complete picking the order?';
							|it = 'Non tutti i prodotti sono stati rimessi sullo scaffale. Completare l''assemblaggio dell''ordine?';
							|pl = 'Nie wszystkie towary zwrócono na półkę. Zakończyć kompletację zamówienia?';
							|tr = 'Tüm ürünler rafa iade edilmedi. Sipariş montajı tamamlansın mı?'");
	Else
		DoQueryBox = NStr("vi = 'Kết thúc tập hợp đơn hàng?';
							|ru = 'Завершить сборку заказа?';
							|en = 'Complete picking the order?'; fa = 'Complete picking the order?';
							|it = 'Completare l''assemblaggio dell''ordine?';
							|pl = 'Zakończyć kompletację zamówienia?';
							|tr = 'Sipariş montajı tamamlansın mı?'");
	EndIf;
	
	Mode = QuestionDialogMode.YesNo;
	Notification = New CallbackDescription("AfterClosingQuestionFinishBuild", ThisObject, Parameters);
	ShowQueryBox(Notification, DoQueryBox , Mode, 0);
	
EndProcedure

&AtClient
Procedure FindByBarcode(Command)
	FindGoodsBySHK();
EndProcedure

&AtClient
Procedure ConfirmTheReplacement(Command)
	
	CurrentForm = "DesktopForm";
	Title = NStr("vi = 'Đặt hàng:';
				|ru = 'Заказ:';
				|en = 'Order:'; fa = 'سفارش:';
				|it = 'Ordine:';
				|pl = 'Zamówienie:';
				|tr = 'Sipariş:'") + OrderNumber;
	
	Try 
		QuantityConfirmed = Number(Items.TheNumberOfReplacementRights.Title);
	Except
		QuantityConfirmed = 0;
	EndTry;
	
	Try 
		CountPlan = Number(Items.NumberOfReplacementLev.Title);
	Except
		CountPlan = 0;
	EndTry;
	
	If QuantityConfirmed = 0 Then
		
	Else
		TransferToReplacement(CountPlan, QuantityConfirmed);
	EndIf;
	
	RecalculateGroupTotals();
	
	DeleteProductCardOnServer("ForAssembly", ID);
	Items.DesktopForm.Visible = True;
	Items.ReplacementConfirmationForm.Visible = False;
	HideCalculator();
	
	ChangeSectionAndActiveCommands();

EndProcedure

&AtClient
Procedure Substitutions_3Selection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInFormTablesByOrder()

	Status = InformationRegisters.AssemblyAndDeliveryStatuses.GetOrderStatus(OrderDocument);
	
	If Status = Enums.AssemblyAndDeliveryStatuses.ForAssembly Then
		
		StorageAddress = PutToTempStorage(Undefined, UUID);
		
		DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.GoodsTable(OrderDocument, StorageAddress);
		ForAssembly.Load(GetFromTempStorage(StorageAddress));
		
		Cnt = 1;
		For Each String In ForAssembly Do
			String.ID = Cnt;
			Cnt = Cnt + 1;
		EndDo;
		
		LastID = Cnt;
		
	ElsIf Status = Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress Then
		LoadIntermediateData();
		
		Items.StartTheBuild.Visible = False;
		Items.Scan.Visible = True;
	EndIf;

EndProcedure

&AtClient
Procedure ChangeSection(SectionName)
	
	Items.FrameToBuild.Picture = PictureLib.BorderMenuWhite;
	Items.SectionToBuild.TextColor = WebColors.DarkGray;
	
	Items.FrameToClarify.Picture = PictureLib.BorderMenuWhite;
	Items.SectionToClarify.TextColor = WebColors.DarkGray;
	
	Items.TheFrameIsAssembled.Picture = PictureLib.BorderMenuWhite;
	Items.CollectedSection.TextColor = WebColors.DarkGray;
	
	Items.ForAssembly.Visible = False;
	Items.ToClarify.Visible = False;
	Items.Assembled.Visible = False;
	
	If SectionName = "ForAssembly" Then
		NameOfFrameElement  = "FrameToBuild";
		NameOfSectionElement = "SectionToBuild";
	ElsIf SectionName = "ToClarify" Then
		NameOfFrameElement  = "FrameToClarify";
		NameOfSectionElement = "SectionToClarify";
	ElsIf SectionName = "Assembled" Then
		NameOfFrameElement  = "TheFrameIsAssembled";
		NameOfSectionElement = "CollectedSection";
	EndIf;
	
	Items[NameOfFrameElement].Picture    = PictureLib.BorderMenuBlack;
	Items[NameOfSectionElement].TextColor = WebColors.Black;
	Items[SectionName].Visible = True;
	
	If ForAssembly.Count() = 0 Then
		Items.FinishTheBuild.Visible = True;
		Items.Scan.Visible = False;
		Items.StartTheBuild.Visible = False;
	Else
		Items.FinishTheBuild.Visible = False;
		Items.Scan.Visible = Not CurStatusForBuild();
		Items.StartTheBuild.Visible = CurStatusForBuild();
	EndIf;
	
EndProcedure

&AtServer
Procedure SoftwareInterfaceFormation()
	
	For Each EGroups In GroupsToBuild Do
		
		ProductGroup_1 = CreateGroupOnForm("ForAssembly", EGroups.ID);
		
		// Creating a group for the product card
		For Each OrderLine In ForAssembly Do
			
			If OrderLine.Group <> EGroups.Group Then
				Continue;
			EndIf;
			
			ID = StrReplace(String(OrderLine.ID),Chars.NBSp,"");
			CreateProductCardOnForm("ForAssembly", ID, ProductGroup_1);
			
		EndDo;
		
	EndDo;
	
	For Each EGroups In TheGroupAssembled Do
		
		ProductGroup_1 = CreateGroupOnForm("Assembled", EGroups.ID);
		
		// Creating a group for the product card
		For Each OrderLine In Assembled Do
			
			If OrderLine.Group <> EGroups.Group Then
				Continue;
			EndIf;
			
			ID = StrReplace(String(OrderLine.ID),Chars.NBSp,"");
			CreateProductCardOnForm("Assembled", ID, ProductGroup_1);
			
		EndDo;
		
	EndDo;
	
	For Each ProductLineNo In ProductNo Do
		CreateProductCardOnForm("ProductNo", ProductLineNo.ID, Items.ProductNo);
	EndDo;
	
	For Each StringIsReturnedToShelf In ReturnToTheShelf Do
		CreateProductCardOnForm("ReturnToTheShelf", StringIsReturnedToShelf.ID, Items.ReturnToTheShelfGroup);
	EndDo;
	
EndProcedure

// The addition of the product
// 
// Parameters:
// 	Command - FormButton
//@skip-warning
&AtClient
Procedure ProductSelection(Command)
	
	If CurrentForm = "DesktopForm" Or CurrentForm = "ScanForm" Then
		SeparatorPos = StrFind(Command.Name, "_");
		ID = Number(Mid(Command.Name, SeparatorPos + 1));
		
		Section = "";
		
		If StrFind(Command.Name, "ForAssembly") > 0 Then
			Section = "ForAssembly";
		ElsIf StrFind(Command.Name, "ProductNo") > 0 Then
			Section = "ProductNo";
		ElsIf StrFind(Command.Name, "Assembled") > 0 Then
			Section = "Assembled";
		EndIf;
		
		OpenGoodsProfile(Section);
		
	ElsIf CurrentForm = "FormSearchByBarcode" Then
		
		SeparatorPos = StrFind(Command.Name, "_");
		Examina = Number(Mid(Command.Name, SeparatorPos + 1));
		
		FillOutReplacementForm();
		
		HideCalculator();
		ShowCalculator(2);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OpenGoodsProfile(Section)
	
	CurrentForm = "ProductCardForm";
	Title = NStr("vi = 'Thẻ hàng hóa';
				|ru = 'Карточка товара';
				|en = 'Goods profile'; fa = 'پروفایل کالا';
				|it = 'Scheda merce';
				|pl = 'Karta towaru';
				|tr = 'Ürün profili'");
	
	Items.DesktopForm.Visible = False;
	Items.ProductCardForm.Visible = True;
	
	FilterParameters = New Structure("ID", ID);
	
	If Section = "ForAssembly" Then
		ArrayOfProducts_2 = ForAssembly.FindRows(FilterParameters);
	ElsIf Section = "ProductNo" Then
		ArrayOfProducts_2 = ProductNo.FindRows(FilterParameters);
	ElsIf Section = "Assembled" Then
		ArrayOfProducts_2 = Assembled.FindRows(FilterParameters);
	ElsIf StrLen(Barcode) > 0 Then
		ArrayOfProducts_2 = SearchResult.FindRows(FilterParameters);
	EndIf;
	
	If ArrayOfProducts_2.Count() > 0 Then
		
		RowGoods = ArrayOfProducts_2[0];
		
		If Not RowGoods.PicturesFile.IsEmpty() Then
			ProductPhoto = FilesOperations.FileData(RowGoods.PicturesFile, ThisObject.UUID).RefToBinaryFileData;
		EndIf;
		
		Items.ProductName.Title        = ProductsClientServer.ProductPresentation(RowGoods.Products, RowGoods.Characteristic,,RowGoods.Series);
		Items.ProductName_3.Title = Items.ProductName.Title;
		Items.TheValueOfTheArticle.Title           = ?(RowGoods.SKU = "", "-", RowGoods.SKU);
		Items.TheValueOfTheBarcode.Title          = ?(RowGoods.Barcode = "", "-", RowGoods.Barcode);
		
		If RowGoods.ThisIsAWeightProduct Then
			Items.ValueWeight.Title = "-";
		Else 
			Items.ValueWeight.Title = String(RowGoods.Weight) + " " + String(RowGoods.WeightUnitOfMeasure);
		EndIf;
		
		Items.TheValueOfThePrice.Title        = String(RowGoods.Price) + " " + Currency;
		Items.TheValueOfThePriceToCollect.Title = Items.TheValueOfThePrice.Title;
		
		ExpirationDate_ = "-";
		If RowGoods.ExpirationDate_ > 0 Then
			ExpirationDate_ = String(RowGoods.ExpirationDate_) + " " + String(RowGoods.ShelfLifeUnitOfMeasure);
		EndIf;
		
		Items.TheValueOfTheExpirationDate.Title        = ExpirationDate_;
		Items.TheValueOfTheExpirationDateToCollect.Title = ExpirationDate_;
		
		Items.NumberOfEntries_4.Title     = RowGoods.Count;
		Items.TheNumberOfInputPlan.Title = RowGoods.Count;
		
		Items.UnitOfMeasureLabel.Title = RowGoods.Package;
		
		If Status = Enums.AssemblyAndDeliveryStatuses.ForAssembly Then
			Items.CollectTheProduct.Visible = False;
			Items.Replace.Visible = False;
			Items.CancelCollected.Visible = False;
			Items.CancelOutOfStock.Visible = False;
			Return;
		EndIf;
		
		If Section = "ForAssembly" Then
			Items.CollectTheProduct.Visible = True;
			Items.Replace.Visible = True;
			Items.CancelCollected.Visible = False;
			Items.CancelOutOfStock.Visible = False;
			Items.CollectTheProduct.Title         = NStr("vi = 'Cần đóng bộ';
														|ru = 'Собрать';
														|en = 'To assemble'; fa = 'برای جمع‌آوری';
														|it = 'Da assemblare';
														|pl = 'Skompletuj';
														|tr = 'Topla'") + " " + String(RowGoods.Count) + " " + String(RowGoods.Package);
		ElsIf Section = "Assembled" Then
			Items.CollectTheProduct.Visible = False;
			Items.Replace.Visible = False;
			Items.CancelCollected.Visible = True;
			Items.CancelOutOfStock.Visible = False;
		ElsIf Section = "ProductNo" Then
			Items.CollectTheProduct.Visible = False;
			Items.Replace.Visible = False;
			Items.CancelCollected.Visible = False;
			Items.CancelOutOfStock.Visible = True;
		EndIf;
		
	Else			
		Items.CollectTheProduct.Visible = False;
		Items.Replace.Visible = False;
		Items.CancelCollected.Visible = False;
		Items.CancelOutOfStock.Visible = False;	
	EndIf;
	
EndProcedure

&AtServer
Function StartBuildingOnServer()
	
	StatusSet = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.ToSetStatusOfOrderIsGoingTo(OrderDocument);
	
	If StatusSet Then
		Status = Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress;
		SaveIntermediateData();
	EndIf;
	
	Return StatusSet;
	
EndFunction

&AtServer
Procedure SaveIntermediateData()
	
	IntermediateData = IntermediateData();
	IntermediateData.ForAssembly        = ForAssembly.Unload();
	IntermediateData.GroupsToBuild  = GroupsToBuild.Unload();
	IntermediateData.Assembled        = Assembled.Unload();
	IntermediateData.TheGroupAssembled  = TheGroupAssembled.Unload();
	IntermediateData.ProductNo      = ProductNo.Unload();
	IntermediateData.Substitutions_3         = Substitutions_3.Unload();
	IntermediateData.ReturnToTheShelf = ReturnToTheShelf.Unload();
	
	IntermediateData.LastID = LastID;
	
	OrderData = New ValueStorage(IntermediateData);
	
	NumberOfRowsAssembled = Assembled.Count();
	
	InformationRegisters.AssemblyAndDeliveryStatuses.WriteIntermediateAssemblyData(OrderDocument, OrderData, NumberOfRowsAssembled);
	
EndProcedure

&AtServer
Function IntermediateData()
	
	PriceFillingParameters = New Structure;
	PriceFillingParameters.Insert("ForAssembly");
	PriceFillingParameters.Insert("GroupsToBuild");
	PriceFillingParameters.Insert("Assembled");
	PriceFillingParameters.Insert("TheGroupAssembled");
	PriceFillingParameters.Insert("NumberOfRowsAssembled");
	PriceFillingParameters.Insert("ProductNo");
	PriceFillingParameters.Insert("Substitutions_3");
	PriceFillingParameters.Insert("ReturnToTheShelf");
	PriceFillingParameters.Insert("LastID");
	
	Return PriceFillingParameters;
	
EndFunction

&AtServer
Procedure LoadIntermediateData()
	
	OrderData = InformationRegisters.AssemblyAndDeliveryStatuses.GetIntermediateBuildData(OrderDocument);
	IntermediateData = OrderData.Get();
	
	Try
		LastID = IntermediateData.LastID;
	Except
	EndTry;

	Try
		ForAssembly.Load(IntermediateData.ForAssembly);
		GroupsToBuild.Load(IntermediateData.GroupsToBuild);
	Except
	EndTry;
	
	Try
 		Assembled.Load(IntermediateData.Assembled);
		TheGroupAssembled.Load(IntermediateData.TheGroupAssembled);
	Except
	EndTry;
	
	Try
		ProductNo.Load(IntermediateData.ProductNo);
	Except
	EndTry;
	
	Try
		Substitutions_3.Load(IntermediateData.Substitutions_3);
		For Each String In Substitutions_3 Do
			String.Picture = FilesOperations.FileData(String.PicturesFile, ThisObject.UUID).RefToBinaryFileData;
			String.Picture1 = FilesOperations.FileData(String.PicturesFile1, ThisObject.UUID).RefToBinaryFileData;
		EndDo;
	Except
	EndTry;
	
	Try
		ReturnToTheShelf.Load(IntermediateData.ReturnToTheShelf);
	Except
	EndTry;

	
EndProcedure

&AtClient
Procedure EnterValue(Number)
	
	If CurrentForm = "FormSearchByBarcode" Then
		
		If CalculatorComma Then
			Barcode = Barcode + "," + Number;
			CalculatorComma = False;
		Else
			Barcode = Barcode + Number
		EndIf;
		
	EndIf;
	
	If CurrentForm = "CollectProductForm" Then
		
		If CalculatorComma Then
			StringWeight = Items.NumberOfEntries_4.Title + "," + Number;
			CalculatorComma = False;
		Else
			StringWeight = Items.NumberOfEntries_4.Title + Number
		EndIf;
		
		Items.NumberOfEntries_4.Title = Number(StringWeight);
		
		ChangeConfirmationCommand();
		
	EndIf;
	
	If CurrentForm = "ReplacementConfirmationForm" Then
		
		If CalculatorComma Then
			StringWeight = Items.NumberOfReplacementLev.Title + "," + Number;
			CalculatorComma = False;
		Else
			StringWeight = Items.NumberOfReplacementLev.Title + Number
		EndIf;
		
		Items.NumberOfReplacementLev.Title = Number(StringWeight);
		Items.TheNumberOfReplacementRights.Title = Items.NumberOfReplacementLev.Title;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure MovingToCollected(Count)
	
	FilterParameters = New Structure("ID", ID);
	RowsArray = ForAssembly.FindRows(FilterParameters);
	
	Var_Group = Undefined;
	
	For Each LineToBuild In RowsArray Do
		
		Var_Group = LineToBuild.Group;
		
		NewRow = Assembled.Add();
		FillPropertyValues(NewRow, LineToBuild);
		NewRow.Count = Count;
		LastID = LastID + 1;
		NewRow.ID = LastID;
		
		LineToBuild.Count = LineToBuild.Count - Count;
		
		If LineToBuild.Count <= 0 Then
			ForAssembly.Delete(LineToBuild);
		EndIf;
		
		UpdateGroupTables(Var_Group, "ForAssembly");
		UpdateGroupTables(Var_Group, "Assembled");
		
		DrawProduct(NewRow);
	EndDo;
	
EndProcedure

&AtServer
Procedure TransferToSpecify(Count)
	
	FilterParameters = New Structure("ID", ID);
	RowsArray = ForAssembly.FindRows(FilterParameters);
	
	Var_Group = Undefined;
	
	For Each LineToBuild In RowsArray Do
		
		Var_Group = LineToBuild.Group;
		
		NewRow = ProductNo.Add();
		FillPropertyValues(NewRow, LineToBuild);
		NewRow.Count = Count;
		LastID = LastID + 1;
		NewRow.ID = LastID ;
		
		LineToBuild.Count = LineToBuild.Count - Count;
		
		If LineToBuild.Count <= 0 Then
			ForAssembly.Delete(LineToBuild);
		EndIf;
		
		UpdateGroupTables(Var_Group, "ForAssembly");
		
		CreateProductCardOnForm("ProductNo", NewRow.ID, Items.ProductNo);
	EndDo;
	
EndProcedure

&AtServer
Procedure TransferToReplacement(QuantityToBuild, QuantityReplacement)
	
	Var_Group = Undefined;

	SelectionParametersForAssembly = New Structure("ID", ID);
	ReadyForAssembly = ForAssembly.FindRows(SelectionParametersForAssembly);
	
	If ReadyForAssembly.Count() = 0 Then
		Return;
	EndIf;
	
	SelectionParametersSearchResult = New Structure("ID", Examina);
	ArraySearchResults = SearchResult.FindRows(SelectionParametersSearchResult);
	
	If ArraySearchResults.Count() = 0 Then
		Return;
	EndIf;
	
	LineToBuild = ReadyForAssembly[0];
	SearchResultString_ = ArraySearchResults[0];
	
	Var_Group = LineToBuild.Group;
	
	NewRow = Substitutions_3.Add();
	FillPropertyValues(NewRow, LineToBuild);
	NewRow.Count = QuantityToBuild;
	If ShowProductPhotos And Not NewRow.PicturesFile.IsEmpty() Then
		NewRow.Picture = FilesOperations.FileData(NewRow.PicturesFile, ThisObject.UUID).RefToBinaryFileData;
	EndIf;
	LastID = LastID + 1;
	NewRow.ID = LastID;
	
	NewRow.Products1 = SearchResultString_.Products;
	NewRow.Count1 = QuantityReplacement;
	NewRow.Price1 = SearchResultString_.Price;
	NewRow.Group1 = SearchResultString_.Group;
	NewRow.RowsCount1 = SearchResultString_.RowsCount;
	NewRow.SKU1 = SearchResultString_.SKU;
	NewRow.Barcode1 = SearchResultString_.Barcode;
	NewRow.Weight1 = SearchResultString_.Weight;
	NewRow.WeightUnitOfMeasure1 = SearchResultString_.WeightUnitOfMeasure;
	NewRow.Package1 = SearchResultString_.Package;
	NewRow.Characteristic1 = SearchResultString_.Characteristic;
	NewRow.PicturesFile1 = SearchResultString_.PicturesFile;
	NewRow.ExpirationDate_1 = SearchResultString_.ExpirationDate_;
	NewRow.ShelfLifeUnitOfMeasure1 = SearchResultString_.ShelfLifeUnitOfMeasure;
	NewRow.PriceKind1 = SearchResultString_.PriceKind;
	If ShowProductPhotos And Not NewRow.PicturesFile1.IsEmpty() Then
		NewRow.Picture1 = FilesOperations.FileData(NewRow.PicturesFile1, ThisObject.UUID).RefToBinaryFileData;
	EndIf;
	LastID = LastID + 1;
	NewRow.ID1 = LastID;
	
	LineToBuild.Count = LineToBuild.Count - QuantityToBuild;
	
	If LineToBuild.Count <= 0 Then
		ForAssembly.Delete(LineToBuild);
	EndIf;
	
	UpdateGroupTables(Var_Group, "ForAssembly");
	
EndProcedure

Procedure UndoCollectedOnServer()
	
	FilterParameters = New Structure("ID", ID);
	RowsArray = Assembled.FindRows(FilterParameters);
	
	Var_Group = Undefined;
	
	For Each LineCollected In RowsArray Do
		
		Var_Group = LineCollected.Group;
		
		NewRow = ForAssembly.Add();
		FillPropertyValues(NewRow, LineCollected);
		NewRow.Count = LineCollected.Count;
		LastID = LastID + 1;
		NewRow.ID = LastID;
		
		Assembled.Delete(LineCollected);
		
		UpdateGroupTables(Var_Group, "ForAssembly");
		UpdateGroupTables(Var_Group, "Assembled");
		
		DrawProductForAssembly(NewRow);
	EndDo;
	
EndProcedure

Procedure CancelItemNotOnServer()
	
	FilterParameters = New Structure("ID", ID);
	RowsArray = ProductNo.FindRows(FilterParameters);
	
	Var_Group = Undefined;
	
	For Each ProductLineNo In RowsArray Do
		
		Var_Group = ProductLineNo.Group;
		
		NewRow = ForAssembly.Add();
		FillPropertyValues(NewRow, ProductLineNo);
		NewRow.Count = ProductLineNo.Count;
		LastID = LastID + 1;
		NewRow.ID = LastID;
		
		ProductNo.Delete(ProductLineNo);
		
		UpdateGroupTables(Var_Group, "ForAssembly");
		
		DrawProductForAssembly(NewRow);
	EndDo;
	
EndProcedure

// This procedure refills the group tables 
&AtServer
Procedure UpdateGroupTables(Var_Group, TableName)
	
	If TableName = "Assembled" Then
		FormAttributeName = "TheGroupAssembled";
	ElsIf TableName = "ForAssembly" Then
		FormAttributeName = "GroupsToBuild";
	EndIf;
	
	// We determine the number of rows in the modified group
	FilterParameters = New Structure("Group", Var_Group);
	RowsArray = ThisForm[TableName].FindRows(FilterParameters);
	NumberInGroup = RowsArray.Count();
	
	FilterParameters = New Structure("Group", Var_Group);
	GroupsArray1 = ThisForm[FormAttributeName].FindRows(FilterParameters);

	NewID = 1;
	TabVal = ThisForm[FormAttributeName].Unload(,"ID");
	TabVal.Sort("ID Desc");
	If TabVal.Count() > 0 Then
		NewID = TabVal[0].ID + 1;
	EndIf;
	
	If GroupsArray1.Count() = 0 Then
		NewFolder = ThisForm[FormAttributeName].Add();
		NewFolder.Group          = Var_Group;
		NewFolder.RowsCount = NumberInGroup;
		NewFolder.ID = NewID;
	Else
		For Each String In GroupsArray1 Do
			String.RowsCount = NumberInGroup;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateGroupTables()
	
	If GroupsToBuild.Count() = 0 Then
		TabVal = ForAssembly.Unload(,"Group, RowsCount");
		TabVal.GroupBy("Group", "RowsCount");
		GroupsToBuild.Load(TabVal);
		
		Cnt = 1;
		For Each String In GroupsToBuild Do
			String.ID = Cnt;
			Cnt = Cnt + 1;
		EndDo;
	EndIf;
	
	If TheGroupAssembled.Count() = 0 Then
		TabVal = Assembled.Unload(,"Group, RowsCount");
		TabVal.GroupBy("Group", "RowsCount");
		TheGroupAssembled.Load(TabVal);
		
		Cnt = 1;
		For Each String In TheGroupAssembled Do
			String.ID = Cnt;
			Cnt = Cnt + 1;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure RecalculateGroupTotals()
	
	Items.SectionToBuild.Title  = NStr("vi = 'Cần đóng bộ';
										|ru = 'Собрать';
										|en = 'To assemble'; fa = 'برای جمع‌آوری';
										|it = 'Da assemblare';
										|pl = 'Skompletuj';
										|tr = 'Topla'") + " " + String(GroupsToBuild.Total("RowsCount"));
	Items.SectionToClarify.Title = NStr("vi = 'Làm rõ';
										|ru = 'Уточнить';
										|en = 'Specify'; fa = 'تعیین';
										|it = 'Specificare';
										|pl = 'Specify';
										|tr = 'Kesinleştir'") + " " + String(ProductNo.Count() + Substitutions_3.Count());
	Items.CollectedSection.Title  = NStr("vi = 'Gom được';
										|ru = 'Собрано';
										|en = 'Assembled'; fa = 'مونتاژشده';
										|it = 'Composto';
										|pl = 'Assembled';
										|tr = 'Toplandı'") + " " + String(TheGroupAssembled.Total("RowsCount"));
	
	For Each String In GroupsToBuild Do
		GroupName = ?(String.Group = "", NStr("vi = 'Không có nhóm';
												|ru = 'Без группы';
												|en = 'Without group'; fa = 'بدون گروه';
												|it = 'Senza gruppo';
												|pl = 'Bez grupy';
												|tr = 'Grup olmadan'"), String.Group);
		Items["ProductGroupForAssembly" + String.ID].Title = GroupName + " - " + String.RowsCount;
	EndDo;
	
	For Each String In TheGroupAssembled Do
		GroupName = ?(String.Group = "", NStr("vi = 'Không có nhóm';
												|ru = 'Без группы';
												|en = 'Without group'; fa = 'بدون گروه';
												|it = 'Senza gruppo';
												|pl = 'Bez grupy';
												|tr = 'Grup olmadan'"), String.Group);
		Items["ProductGroupCollected" + String.ID].Title = GroupName + " - " + String.RowsCount;
	EndDo;
	
	Items.TheReplacementGroup.Title = NStr("vi = 'Thay thế';
											|ru = 'Замены';
											|en = 'Replacements'; fa = 'جایگزینی‌ها';
											|it = 'Sostituzioni';
											|pl = 'Replacements';
											|tr = 'İkameler'") + " - " + String(Substitutions_3.Count());
	Items.ProductNo.Title = NStr("vi = 'Không có hàng hóa';
								|ru = 'Товара нет';
								|en = 'No goods item available'; fa = 'قلم کالا در دسترس نیست';
								|it = 'Prodotto assente';
								|pl = 'Brak towaru';
								|tr = 'Ürün mevcut değil'") + " - " + String(ProductNo.Count() + Substitutions_3.Count());
	Items.ReturnToTheShelfGroup.Title = NStr("vi = 'Trả lại lên kệ';
											|ru = 'Вернуть на полку';
											|en = 'Return to shelf'; fa = 'بازگشت به قفسه';
											|it = 'Rimettere sullo scaffale';
											|pl = 'Zwróć na półkę';
											|tr = 'Rafa geri gönder'") + " - " + String(ReturnToTheShelf.Count());
	
EndProcedure

&AtServer
Procedure DrawProduct(OrderLine)
	
	// Finding the group ID
	FilterParameters = New Structure("Group", OrderLine.Group);
	GroupsArray1 = TheGroupAssembled.FindRows(FilterParameters);
	
	If GroupsArray1.Count() = 0 Then
		Return;
	EndIf;
	
	GroupRow = GroupsArray1[0];
	
	ElementGroupCollected = Items.Find("ProductGroupCollected" + GroupRow.ID);
	If ElementGroupCollected = Undefined Then
		ElementGroupCollected = CreateGroupOnForm("Assembled", GroupRow.ID);
	EndIf;
	
	CreateProductCardOnForm("Assembled", OrderLine.ID, ElementGroupCollected);
	
EndProcedure

&AtServer
Procedure DrawProductForAssembly(OrderLine)
	
	// Finding the group ID
	FilterParameters = New Structure("Group", OrderLine.Group);
	GroupsArray1 = GroupsToBuild.FindRows(FilterParameters);
	
	If GroupsArray1.Count() = 0 Then
		Return;
	EndIf;
	
	GroupRow = GroupsArray1[0];
	
	GroupToBuildElement = Items.Find("ProductGroupForAssembly" + GroupRow.ID);
	If GroupToBuildElement = Undefined Then
		GroupToBuildElement = CreateGroupOnForm("ForAssembly", GroupRow.ID);
	EndIf;
	
	CreateProductCardOnForm("ForAssembly", OrderLine.ID, GroupToBuildElement);
	
EndProcedure

&AtServer
Function CreateGroupOnForm(SectionName, GroupIdentifier)
	
	If SectionName = "ForAssembly" Then
		ElementNameWithoutPostfix = "ProductGroupForAssembly";
	ElsIf SectionName = "Assembled" Then
		ElementNameWithoutPostfix = "ProductGroupCollected";
	EndIf;
	
	ProductGroup_1 = Items.Add(
	"" + ElementNameWithoutPostfix + String(GroupIdentifier),
	Type("FormGroup"),
	Items[SectionName]);
	
	ProductGroup_1.Type                     = FormGroupType.UsualGroup;
	ProductGroup_1.Behavior               = UsualGroupBehavior.Collapsible;
	ProductGroup_1.TitleTextColor     = New Color(126,126,126);
	ProductGroup_1.TitleFont          = StyleFonts.TextFontAssemblyAndDelivery;
	ProductGroup_1.Group = ChildFormItemsGroup.Vertical;
	
	Return ProductGroup_1; 
	
EndFunction

&AtServer
Procedure CreateProductCardOnForm(SectionName, ProductID, Parent)
	
	FilterParameters = New Structure("ID", ProductID);
	RowsArray = ThisForm[SectionName].FindRows(FilterParameters);
	
	OrderLine = Undefined;
	If RowsArray.Count() > 0 Then
		OrderLine = RowsArray[0];
	Else
		Return;
	EndIf;
	
	// PRODUCT CARD
	GoodsProfile = Items.Add("GoodsProfile" + SectionName + ProductID, Type("FormGroup"), Parent);
	GoodsProfile.Type                 = FormGroupType.UsualGroup;
	GoodsProfile.Group         = ChildFormItemsGroup.Vertical; 
	GoodsProfile.ShowTitle = False;
	
	// PRODUCT CARD 2 Without margins
	ProductCardContainer = Items.Add("GoodsProfile2" + SectionName + ProductID, Type("FormGroup"), GoodsProfile);
	ProductCardContainer.Type                = FormGroupType.UsualGroup;
	ProductCardContainer.Group        = ChildFormItemsGroup.AlwaysHorizontal; 
	ProductCardContainer.ShowTitle = False;
	
	// PRODUCT CARD Left part
	ProductCardLeftSide = Items.Add("ProductCardLev" + SectionName + ProductID, Type("FormGroup"), ProductCardContainer);
	ProductCardLeftSide.Type                = FormGroupType.UsualGroup;
	ProductCardLeftSide.Group        = ChildFormItemsGroup.AlwaysHorizontal; 
	ProductCardLeftSide.ShowTitle = False;
	ProductCardLeftSide.Width = 4;
	
	// PRODUCT CARD Right side
	ProductCardRightSide = Items.Add("ProductCard" + SectionName + ProductID, Type("FormGroup"), ProductCardContainer);
	ProductCardRightSide.Type                = FormGroupType.UsualGroup;
	ProductCardRightSide.Group        = ChildFormItemsGroup.Vertical; 
	ProductCardRightSide.ShowTitle = False;
	
	// PRODUCT CARD Upper area
	ProductCardTop = Items.Add("ProductCardEdit" + SectionName + ProductID, Type("FormGroup"), ProductCardRightSide);
	ProductCardTop.Type                = FormGroupType.UsualGroup;
	ProductCardTop.Group        = ChildFormItemsGroup.AlwaysHorizontal; 
	ProductCardTop.ShowTitle = False;
	ProductCardTop.Representation = UsualGroupRepresentation.None;
	
	// PRODUCT CARD Lower area
	ProductCardBottom = Items.Add("ProductCardEdit_" + SectionName + ProductID, Type("FormGroup"), ProductCardRightSide);
	ProductCardBottom.Type                = FormGroupType.UsualGroup;
	ProductCardBottom.Group        = ChildFormItemsGroup.AlwaysHorizontal; 
	ProductCardBottom.ShowTitle = False;
	ProductCardBottom.Representation = UsualGroupRepresentation.None;
	ProductCardBottom.HorizontalStretch = True;
	
	// PRODUCT PHOTO
	If ShowProductPhotos Then
		AttributesToBeAdded = New Array;
		AttributeType = New TypeDescription("String");
		FormAttribute = New FormAttribute("Photo_" + SectionName + ProductID, AttributeType);
		
		AttributesToBeAdded.Add(FormAttribute);
		
		// Forcing the form to create new details
		ChangeAttributes(AttributesToBeAdded);
		
		// The output of the props on the form (if necessary)
		InputField = Items.Add("Photo_" + SectionName + ProductID, Type("FormField"), ProductCardLeftSide);
		InputField.Type = FormFieldType.PictureField;
		InputField.DataPath = "Photo_" + SectionName + ProductID;
		InputField.PictureSize = PictureSize.Proportionally;
		InputField.Width = 4;
		InputField.Height = 2;
		InputField.HorizontalStretch = False;
		InputField.TitleLocation = FormItemTitleLocation.None;
		InputField.Border = StyleBorders.BorderNoBorder;
		
		// Accessing the form details from the code
		If Not OrderLine.PicturesFile.IsEmpty() Then
			LinkToDDF = FilesOperations.FileData(OrderLine.PicturesFile, ThisObject.UUID).RefToBinaryFileData;
			ThisForm["Photo_" + SectionName + ProductID] = LinkToDDF;
		EndIf;
	EndIf;
	
	// Name of item
	Command = Commands.Add(
	"ProductItemName" + SectionName + "_" + ProductID); //Command name
	Command.Title = ProductsClientServer.ProductPresentation(OrderLine.Products, OrderLine.Characteristic,,OrderLine.Series);
	Command.Action = "ProductSelection"; //Name of the associated procedure
	FormButton = Items.Add("ProductButton" + SectionName + ProductID, Type("FormButton"), ProductCardTop);
	FormButton.CommandName = "ProductItemName" + SectionName + "_" + ProductID; 
	FormButton.Type        = FormButtonType.UsualButton; 
	FormButton.Font      = StyleFonts.TextFontSelectedAssemblyAndDelivery;
	FormButton.TextColor = New Color(0,0,0);
	FormButton.ShapeRepresentation = ButtonShapeRepresentation.None;
	FormButton.HorizontalAlignInGroup = ItemHorizontalLocation.Left;
	FormButton.TitleHeight = 2;
	FormButton.HorizontalStretch = True;
	
	// Amount of goods
	Command = Commands.Add(
	"ProductQuantity__" + SectionName + "_" + ProductID); //Command name
	Command.Title = String(OrderLine.Count) + " " + String(OrderLine.Package);
	Command.Action  = "ProductSelection"; //Name of the associated procedure
	
	FormButton = Items.Add("ProductQuantityButton" + SectionName + ProductID, Type("FormButton"), ProductCardTop);
	FormButton.CommandName = "ProductQuantity__" + SectionName + "_" + ProductID; 
	FormButton.Type        = FormButtonType.UsualButton; 
	FormButton.Font      = StyleFonts.TextFontSelectedAssemblyAndDelivery;
	FormButton.TextColor = New Color(106,210,110);
	FormButton.ShapeRepresentation = ButtonShapeRepresentation.None;
	FormButton.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	FormButton.VerticalAlignInGroup = ItemVerticalAlign.Top;
	
	// Product weight
	If OrderLine.ThisIsAWeightProduct Or OrderLine.Weight = 0 Then
		TitleWeight = "";
	Else 
		TitleWeight = String(OrderLine.Weight) + " " + String(OrderLine.WeightUnitOfMeasure);
	EndIf;
	
	Command = Commands.Add(
	"ProductWeight_" + SectionName + "_" + ProductID); //Command name
	Command.Title = TitleWeight;
	Command.Action  = "ProductSelection"; //Name of the associated procedure
	
	FormButton = Items.Add("ButtonItemWeight" + SectionName + ProductID, Type("FormButton"), ProductCardBottom);
	FormButton.CommandName = "ProductWeight_" + SectionName + "_" + ProductID; 
	FormButton.Type        = FormButtonType.UsualButton; 
	FormButton.Font      = StyleFonts.TextFontSelectedAssemblyAndDelivery;
	FormButton.TextColor = New Color(126,126,126);
	FormButton.ShapeRepresentation = ButtonShapeRepresentation.None;
	FormButton.HorizontalAlignInGroup = ItemHorizontalLocation.Left;
	If TitleWeight = "" Then
		FormButton.Visible = False;
	EndIf;
	
	// Price of goods
	Command = Commands.Add(
	"ProductPrice" + SectionName + "_" + ProductID); //Command name
	Command.Title = String(OrderLine.Price) + " " + Currency;
	Command.Action  = "ProductSelection"; //Name of the associated procedure
	
	FormButton = Items.Add("ProductPriceButton" + SectionName + ProductID, Type("FormButton"), ProductCardBottom);
	FormButton.CommandName = "ProductPrice" + SectionName + "_" + ProductID; 
	FormButton.Type        = FormButtonType.UsualButton; 
	FormButton.Font      = StyleFonts.TextFontSelectedAssemblyAndDelivery;
	FormButton.TextColor = New Color(126,126,126);
	FormButton.ShapeRepresentation = ButtonShapeRepresentation.None;
	FormButton.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	
	// Line INDENTATION
	Line = Items.Add("Line" + SectionName + ProductID, Type("FormDecoration"), GoodsProfile);
	Line.Type = FormDecorationType.Picture;
	Line.Picture = PictureLib.BorderGray;
	Line.HorizontalStretch = True;
	Line.PictureSize = PictureSize.Stretch;
	Line.Height = 0;
	
EndProcedure

&AtClient
Procedure ChangeSectionAndActiveCommands() 
	
	If ForAssembly.Count() > 0 Then
		ChangeSection("ForAssembly");
	ElsIf 2=3 Then
		ChangeSection("ToClarify");
	ElsIf Assembled.Count() > 0 Then
		ChangeSection("Assembled");
	EndIf;
	
EndProcedure

&AtServer
Function CurStatusForBuild()
	
	If Status = Enums.AssemblyAndDeliveryStatuses.ForAssembly Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Function StyleColorGreenTeam()
	
	Return StyleColors.CommandColorGreenAssemblyAndDelivery;
	
EndFunction

&AtClient
Procedure ChangeConfirmationCommand()
	
	If Items.NumberOfEntries_4.Title = "" Then
		Items.NumberOfEntries_4.Title = "0";
		Items.Confirm.Title = NStr("vi = 'Không có hàng hóa';
									|ru = 'Товара нет';
									|en = 'No goods item available'; fa = 'قلم کالا در دسترس نیست';
									|it = 'Prodotto assente';
									|pl = 'Brak towaru';
									|tr = 'Ürün mevcut değil'");
		Items.Confirm.BackColor = New Color(253, 91, 81);
		Items.ConfirmCollectionOfTheGoods.Title = "OfProduct none";
		Items.ConfirmCollectionOfTheGoods.BackColor = New Color(253, 91, 81);
	EndIf;
	
	If Number(Items.NumberOfEntries_4.Title) = 0 Then
		Items.Confirm.Title = NStr("vi = 'Không có hàng hóa';
									|ru = 'Товара нет';
									|en = 'No goods item available'; fa = 'قلم کالا در دسترس نیست';
									|it = 'Prodotto assente';
									|pl = 'Brak towaru';
									|tr = 'Ürün mevcut değil'");
		Items.Confirm.BackColor = New Color(253, 91, 81);
		Items.ConfirmCollectionOfTheGoods.Title = "OfProduct none";
		Items.ConfirmCollectionOfTheGoods.BackColor = New Color(253, 91, 81);
	Else
		Items.Confirm.Title = NStr("vi = 'Xác nhận';
									|ru = 'Подтвердить';
									|en = 'Confirm'; fa = 'تأیید';
									|it = 'Confermare';
									|pl = 'Potwierdź';
									|tr = 'Onayla'");
		Items.Confirm.BackColor = StyleColorGreenTeam();
		Items.ConfirmCollectionOfTheGoods.Title = "Confirm";
		Items.ConfirmCollectionOfTheGoods.BackColor = StyleColorGreenTeam();
	EndIf;
	
EndProcedure

// Shows the calculator form group.
//
//	Parameters:
//		Form - Number - 0 is the collect form, 1 is the search by SHK form
//						2 this is a form of substitution
//
&AtClient
Procedure ShowCalculator(Form)
	
	// Showing hiding the calculator
	Items.CalculatorGroup.Visible = Not Items.CalculatorGroup.Visible;
	
	If Form = 0 Then
		Items.ConfirmCollectionOfTheGoods.Visible = Items.CalculatorGroup.Visible;
		Items.Confirm.Visible = Not Items.CalculatorGroup.Visible;
		Items.Find.Visible = False;
		Items.ConfirmTheReplacement.Visible = False;
	ElsIf Form = 1 Then
		Items.ConfirmCollectionOfTheGoods.Visible = False;
		Items.Confirm.Visible = True;
		Items.Find.Visible = True;
		Items.ConfirmTheReplacement.Visible = False;
	ElsIf Form = 2 Then
		Items.ConfirmCollectionOfTheGoods.Visible = False;
		Items.Confirm.Visible = False;
		Items.Find.Visible = False;
		Items.ConfirmTheReplacement.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure HideCalculator()
	Items.CalculatorGroup.Visible = False;
	Items.Confirm.Visible = True;
EndProcedure

// Parameters: Source 0 - from replacement; 1 - from adding a new one
&AtServer
Procedure FindGoodsBySHK()
	
	CurrentForm = "FormSearchByBarcode";
	Title = NStr("vi = 'Quét ảnh';
				|ru = 'Сканировать';
				|en = 'Scan'; fa = 'اسکن';
				|it = 'Scansionare';
				|pl = 'Skanuj';
				|tr = 'Tara'");
	
	If SearchResult.Count() > 0 Then
		
		// Deleting old search results
		For Each FoundProduct In SearchResult Do
			DeleteProductCardOnServer("SearchResult", FoundProduct.ID);
		EndDo;
		
		SearchResult.Clear();
	EndIf;
	
	FilterParameters = New Structure("ID", ID);
	ArrayOfProducts_2 = ForAssembly.FindRows(FilterParameters);
	If ArrayOfProducts_2.Count() = 0 Then
		Return;
	EndIf;
	
	Terms = Common.ObjectAttributeValue(OrderDocument, "Terms");
	PriceKind = Common.ObjectAttributeValue(Terms, "PricesKind"); 
	
	TableOfGoods = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.FindGoodsBySHK(Barcode, PriceKind);
	
	SearchResult.Load(TableOfGoods);
	
	For Each FoundProduct In SearchResult Do
		
		CreateProductCardOnForm("SearchResult", FoundProduct.ID, Items.FoundGoods);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure DeleteProductCardOnServer(SectionName, ProductID)
	
	// Delete Form Elements
	ThisForm.Items.Delete(Items.Find("GoodsProfile" + SectionName + ProductID));
	
	// Delete Form Commands
	ThisForm.Commands.Delete(Commands.Find("ProductItemName" + SectionName + "_" + ProductID));
	ThisForm.Commands.Delete(Commands.Find("ProductQuantity__" + SectionName + "_" + ProductID));
	ThisForm.Commands.Delete(Commands.Find("ProductWeight_" + SectionName + "_" + ProductID));
	ThisForm.Commands.Delete(Commands.Find("ProductPrice" + SectionName + "_" + ProductID));

	// To remove the details
	If ShowProductPhotos Then
		AttributesToDeleteArray = New Array();
		AttributesToDeleteArray.Add("Photo_" + SectionName + ProductID); 
		ChangeAttributes(, AttributesToDeleteArray);
	Else
		ChangeAttributes();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOutReplacementForm()
	
	CurrentForm = "ReplacementConfirmationForm";
	Items.FormSearchByBarcode.Visible = False;
	Items.ReplacementConfirmationForm.Visible = True;
	
	FilterParameters = New Structure("ID", ID);
	ReadyForAssembly = ForAssembly.FindRows(FilterParameters);
	If ReadyForAssembly.Count() = 0 Then
		Return;
	EndIf;
	LineToBuild = ReadyForAssembly[0];

	FilterParameters = New Structure("ID", Examina);
	ArraySearch = SearchResult.FindRows(FilterParameters);
	If ArraySearch.Count() = 0 Then
		Return;
	EndIf;
	SearchString_ = ArraySearch[0];
	
	If ShowProductPhotos And Not LineToBuild.PicturesFile.IsEmpty() Then
		ProductPhotoReplacementLion = FilesOperations.FileData(LineToBuild.PicturesFile, ThisObject.UUID).RefToBinaryFileData;
		Items.ProductPhotoLev.Visible = True;
	EndIf;
	Items.NumberOfReplacementLev.Title = LineToBuild.Count;
	Items.PackTheLion.Title = LineToBuild.Package;
	Items.NameLion.Title = LineToBuild.Products;
	Items.PriceLev.Title = String(LineToBuild.Price) + " " + Currency;
	
	If ShowProductPhotos And Not SearchString_.PicturesFile.IsEmpty() Then
		ProductPhotoReplacementOfRights = FilesOperations.FileData(SearchString_.PicturesFile, ThisObject.UUID).RefToBinaryFileData;
		Items.ProductPhotoRights.Visible = True;
	EndIf;
	Items.TheNumberOfReplacementRights.Title = LineToBuild.Count;
	Items.PackIsRight.Title = SearchString_.Package;
	Items.TheNameOfTheRights.Title = SearchString_.Products;
	Items.PriceOfRights.Title = String(SearchString_.Price) + " " + Currency;

EndProcedure

&AtClient
Procedure ToTransferAReplacementInCollected(Command)
	StringReplacement = Items.Substitutions_3.CurrentData;
	Structure = GetCurRowData(StringReplacement);
	Substitutions_3.Delete(StringReplacement);
	ToTransferAReplacementInCollectedServer(Structure);
	
	RecalculateGroupTotals();
EndProcedure

&AtServer
Procedure ToTransferAReplacementInCollectedServer(StringReplacement)
	
	Var_Group = Undefined;
	Var_Group = StringReplacement.Group;
	
	NewRow = Assembled.Add();
	FillPropertyValues(NewRow, StringReplacement);
	LastID = LastID + 1;
	NewRow.ID = LastID;
	
	UpdateGroupTables(Var_Group, "Assembled");
	
	DrawProduct(NewRow);
	
EndProcedure

&AtClient
Procedure ToPostponeTheReplacementOfGoodsNot(Command)
	
	// Current line
	StringReplacement = Items.Substitutions_3.CurrentData;
	
	// Convert the string to the Product structure = Products
	Structure = GetCurRowData2(StringReplacement);
	
	// Convert the string to the Product structure = Nomenclature1
	Structure2 = GetCurRowData(StringReplacement);
	
	Substitutions_3.Delete(StringReplacement);
	
	TransferToProductNoServer(Structure);
	TransferToReturnToShelfServer(Structure2);
	
	RecalculateGroupTotals();
EndProcedure

&AtServer
Procedure TransferToProductNoServer(StringReplacement)
	
	NewRow = ProductNo.Add();
	FillPropertyValues(NewRow, StringReplacement);
	LastID = LastID + 1;
	NewRow.ID = LastID;
	
	CreateProductCardOnForm("ProductNo", NewRow.ID, Items.ProductNo);
	
EndProcedure

&AtServer
Procedure TransferToReturnToShelfServer(StringReplacement)
	
	NewRow = ReturnToTheShelf.Add();
	FillPropertyValues(NewRow, StringReplacement);
	LastID = LastID + 1;
	NewRow.ID = LastID;
	
	CreateProductCardOnForm("ReturnToTheShelf", NewRow.ID, Items.ReturnToTheShelfGroup);
	
EndProcedure

&AtClient
Function GetCurRowData(CurrentRow)
	
	Structure = New Structure;
	
	Structure.Insert("Products", CurrentRow.Products1);
	Structure.Insert("Count", CurrentRow.Count1);
	Structure.Insert("Price", CurrentRow.Price1);
	Structure.Insert("Group", CurrentRow.Group1);
	Structure.Insert("ID", CurrentRow.ID1);
	Structure.Insert("RowsCount", CurrentRow.RowsCount1);
	Structure.Insert("SKU", CurrentRow.SKU1);
	Structure.Insert("Barcode", CurrentRow.Barcode1);
	Structure.Insert("Weight", CurrentRow.Weight1);
	Structure.Insert("WeightUnitOfMeasure", CurrentRow.WeightUnitOfMeasure1);
	Structure.Insert("Package", CurrentRow.Package1);
	Structure.Insert("Characteristic", CurrentRow.Characteristic1);
	Structure.Insert("PicturesFile", CurrentRow.PicturesFile1);
	Structure.Insert("ExpirationDate_", CurrentRow.ExpirationDate_1);
	Structure.Insert("ShelfLifeUnitOfMeasure", CurrentRow.ShelfLifeUnitOfMeasure1);
	Structure.Insert("PriceKind", CurrentRow.PriceKind1);
	
	Return Structure;
	
EndFunction

&AtClient
Function GetCurRowData2(CurrentRow)
	
	Structure = New Structure;
	
	Structure.Insert("Products", CurrentRow.Products);
	Structure.Insert("Count", CurrentRow.Count);
	Structure.Insert("Price", CurrentRow.Price);
	Structure.Insert("Group", CurrentRow.Group);
	Structure.Insert("ID", CurrentRow.ID);
	Structure.Insert("RowsCount", CurrentRow.RowsCount);
	Structure.Insert("SKU", CurrentRow.SKU);
	Structure.Insert("Barcode", CurrentRow.Barcode);
	Structure.Insert("Weight", CurrentRow.Weight);
	Structure.Insert("WeightUnitOfMeasure", CurrentRow.WeightUnitOfMeasure);
	Structure.Insert("Package", CurrentRow.Package);
	Structure.Insert("Characteristic", CurrentRow.Characteristic);
	Structure.Insert("PicturesFile", CurrentRow.PicturesFile);
	Structure.Insert("ExpirationDate_", CurrentRow.ExpirationDate_);
	Structure.Insert("ShelfLifeUnitOfMeasure", CurrentRow.ShelfLifeUnitOfMeasure);
	Structure.Insert("PriceKind", CurrentRow.PriceKind);
	
	Return Structure;
	
EndFunction

&AtClient
Procedure ProductSearchByBarcode()
	
	If CurrentForm = "DesktopForm" Then
		
		FilterParameters = New Structure("Barcode", Barcode);
		
		RowsArray = ForAssembly.FindRows(FilterParameters);
		If RowsArray.Count() > 0 Then
			
			ID = RowsArray[0].ID;
			OpenGoodsProfile("ForAssembly");
			
		Else
			
			Mode = QuestionDialogMode.YesNo;
			Notification = New CallbackDescription("AfterClosingQuestionAddProduct", ThisObject, Parameters);
			ShowQueryBox(Notification, NStr("vi = 'Không tìm thấy hàng hóa trong đơn hàng, thêm mới?';
											|ru = 'Товар не найден в заказе, добавить новый?';
											|en = 'Goods item is not found in order, do you want to add a new one?'; fa = 'Goods item is not found in order, do you want to add a new one?';
											|it = 'Prodotto non trovato nell''ordine, aggiungerne uno nuovo?';
											|pl = 'Nie znaleziono towaru w zamówieniu, dodać nowy?';
											|tr = 'Ürün siparişte bulunamadı, yeni biri eklensin mi?'"), Mode, 0);
			
		EndIf;
		
	ElsIf CurrentForm = "FormSearchByBarcode" Then
		
		FindGoodsBySHK();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestionAddProduct(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	Else 
		Items.DesktopForm.Visible = False;
		Items.FormSearchByBarcode.Visible = True;
		FindGoodsBySHK();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestionFinishBuild(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	Else 
		FinishBuildOnServer();
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure FinishBuildOnServer()
	
	StructureOrder = New Structure;
	StructureOrder.Insert("Assembled", Assembled.Unload());
	StructureOrder.Insert("ProductNo", ProductNo.Unload());
	
	DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.SetStatusOfOrderCollected(OrderDocument, StructureOrder);
	
EndProcedure

#EndRegion