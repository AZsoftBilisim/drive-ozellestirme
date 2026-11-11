#Region Variables

&AtClient
Var CachedValues; // It is used by the mechanism for processing changes in PM details.

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TransferByOrders = Parameters.TransferByOrders;
	SalesOrder      = Parameters.SalesOrder;
	DocumentCurrency   = Parameters.DocumentCurrency;
	ShipmentStarted    = InvoicesServer.ThereIsSpendingOrderForShippingOrders(Parameters.Document);
	
	UseWarehouseManagemantSystemForGoodsIssue     = Parameters.AdvancedWarehousingOnShipment;
	AddressOfGoodsToTransferInTemporaryStorage = Parameters.AddressOfGoodsToTransferInTemporaryStorage;
	
	OrdersFirst = 
		Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst;
		
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Parameters.BusinessOperation);
	
	UseSalesOrders              = Handler.UseSalesOrders();
	UseTransferForSeveralOrders = Handler.UseSaleByMultipleOrders();
	
	ByNote = OrdersFirst
				And UseWarehouseManagemantSystemForGoodsIssue;
	
	Items.ByNote.Visible          = UseSalesOrders
											And UseWarehouseManagemantSystemForGoodsIssue;
	Items.SalesOrder.Visible      = TransferByOrders
											And UseTransferForSeveralOrders;
	Items.TransferByOrder.Visible  = TransferByOrders
											And UseTransferForSeveralOrders;
	Items.TransferByOrders.Visible = TransferByOrders
											And UseTransferForSeveralOrders;
	Items.LabelHeaderSalesOrders.Visible = TransferByOrders
														And UseTransferForSeveralOrders;
	
	FillInTheGoodsTable(Parameters.Document, Parameters.DocumentCurrency);
	SetTitleFillInByOrdersOrders();
	SelectGoodsClientServer.CreateSelectionFormHeader(
		Title, ?(ValueIsFilled(Parameters.Title), Parameters.Title, Parameters.Document));
	
	ParameterNamesForSpecifyingSeries = Documents.TransferOfGoodsToBailee.NamesOfDetailsForFillingInParametersForSpecifyingSeries();
	ObjectParameters = New Structure(ParameterNamesForSpecifyingSeries);
	FillPropertyValues(ObjectParameters, Parameters);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ObjectParameters,
																		Documents.TransferOfGoodsToBailee);
	Items.TableOfGoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
	ThereAreGatheringGoods = TableOfGoods.Total("AccountingIsCollected") > 0;
	
	Items.GoodsTableGroupInNotes.Visible = UseWarehouseManagemantSystemForGoodsIssue;
	Items.TableOfGoodsNumberInProgress.Visible = ThereAreGatheringGoods;
	
	Items.InfoDecoration.Visible = ThereAreGatheringGoods;
	Items.DecorationInformationThereAreCollectedGoods.Visible = ThereAreGatheringGoods;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If Not ClosingInProgress
		And Modified
		And Not Exit Then
		
		Cancel = True;
		
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText       = NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
								|ru = 'Данные были изменены. Перенести изменения в документ?';
								|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
								|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
								|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
								|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
		
	EndIf;

EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Modified  = False;
		ClosingInProgress = True;
		
		MoveProductsToDocument();
		
	ElsIf QuestionResult = DialogReturnCode.No Then
		
		Modified  = False;
		ClosingInProgress = True;
		
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByNoteOnChange(Item)
	
	ReFillAmountMatched();
	
EndProcedure

&AtClient
Procedure ByOrdersOnChange(Item)
	
	WhenChangingByOrders();
	
EndProcedure

&AtClient
Procedure LabelHeaderSalesOrdersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	TitleText = NStr("vi = 'Đơn hàng của khách (%DocumentsCount%)';
					|ru = 'Заказы клиентов (%DocumentsCount%)';
					|en = 'Sales orders (%DocumentsCount%)'; fa = 'Sales orders (%DocumentsCount%)';
					|it = 'Ordini dei clienti (%DocumentsCount%)';
					|pl = 'Zamówienia klientów (%DocumentsCount%)';
					|tr = 'şSatış siparişleri (%DocumentsCount%)'");
	
	FormParameters = New Structure("DocumentsList, Title", OrderList, TitleText);
	
	OpenForm("CommonForm.ViewingListOfDocuments", FormParameters, ThisForm, , , , Undefined,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure TableOfGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.TableOfGoods.CurrentData <> Undefined Then
		If Field.Name = "TableOfGoodsSalesOrder" Then
			ShowValue(Undefined, Items.TableOfGoods.CurrentData.SalesOrder);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TableOfGoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.TableOfGoods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.DiscrepancyInvoice = CurrentRow.NumberOfPackages - CurrentRow.PackagingQuantityInInvoice;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()
	
	MoveProductsToDocument();
	
EndProcedure

&AtClient
Procedure ToChooseTheProductsExecute()
	
	SelectAllProductsOnServer(True);
	
EndProcedure

&AtClient
Procedure ExcludeGoodsExecute()
	
	SelectAllProductsOnServer(False);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Installation of conditional design on the tabular part 'Products'
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoods.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.ExistsInTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	// Setting the conditional design for the 'Quantity of packages in the Order' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsPackagingQuantityInTheOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByNote");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.BackgroundColorIsFullyProvided);
	
	// Setting the conditional design for the 'Quantity Packagingword' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsPackagingQuantityInTheNote.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByNote");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.BackgroundColorIsFullyProvided);
	
	// Setting the conditional design for the elements of the Unit of Measurement and Packaging of the "Goods" tabular part
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "TableOfGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "TableOfGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	// Setting the conditional design for the "Customer's Order" element of the "Products" tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
EndProcedure

&AtServer
Procedure FillInTheGoodsTable(Document, DocumentCurrency)
	
	TransferGoods = GetFromTempStorage(AddressOfGoodsToTransferInTemporaryStorage);
	
	SelectionData_ = New Structure;
	SelectionData_.Insert("Ref",      Parameters.Document);
	SelectionData_.Insert("Date",        Parameters.Date);
	SelectionData_.Insert("Partner",     Parameters.Partner);
	SelectionData_.Insert("Counterparty",  Parameters.Counterparty);
	SelectionData_.Insert("Terms",  Parameters.Terms);
	SelectionData_.Insert("Organization", Parameters.Organization);
	SelectionData_.Insert("Warehouse",       Parameters.Warehouse);
	SelectionData_.Insert("Contract",     Parameters.Contract);
	SelectionData_.Insert("Currency",      Parameters.DocumentCurrency);
	SelectionData_.Insert("SalesOpportunity",      Parameters.SalesOpportunity);
	SelectionData_.Insert("BusinessOperation",     Parameters.BusinessOperation);
	SelectionData_.Insert("LineOfBusiness",   Parameters.LineOfBusiness);
	SelectionData_.Insert("ToReturnReusablePackage", Parameters.ToReturnReusablePackage);
	SelectionData_.Insert("TransferGoods",            TransferGoods);
	SelectionData_.Insert("BusinessOperation",     Parameters.BusinessOperation);
	
	FillParameters = New Structure("DisplayMessage_1, SelectionByOrdersOrders", False, True);
	
	Documents.TransferOfGoodsToBailee.FillByOrderBalances(
		SelectionData_, TableOfGoods, Parameters.Warehouse, Undefined, FillParameters, TableOfBarcodesOfPackages);
	
	OrdersServer.SetSignsOfPresenceOfLineInDocument(TableOfGoods, "SalesOrder", Parameters.ArrayOfStringCodes);
	
	ReFillAmountMatched(True, TransferGoods);
	
EndProcedure

&AtServer
Procedure ReFillAmountMatched(WithFilling = False, TransferGoods = Undefined)

	ProcessedItemRows = New Array;

	If WithFilling Then

		ProcessedTransferLines = New Array;

		UpdateOrderInformation(TransferGoods);
		
		ByOrders = ?(OrderList.Count() > 0, True, ValueIsFilled(SalesOrder))
					Or ShipmentStarted;
		
		SetSelectionByOrders();
		
		TheStructureOfTheSearch = New Structure("Products, Characteristic, Series, SalesOrder, RowCode, Warehouse");
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	ArrayOfRowsToDelete_1 = New Array;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each CurRow In TableOfGoods Do
		
		NumberOfPackages = CurRow.NumberOfPackages;
		
		CurRow.Count         = ?(ByNote, CurRow.NoteQuantity,         CurRow.QuantityInOrder);
		CurRow.NumberOfPackages = ?(ByNote, CurRow.PackagingQuantityInTheNote, CurRow.PackagingQuantityInTheOrder);
		
		If CurRow.NumberOfPackages <> NumberOfPackages Then
			ProcessedItemRows.Add(CurRow);
		EndIf;
		
		If WithFilling Then
			
			FillPropertyValues(TheStructureOfTheSearch, CurRow);
			Rows = TransferGoods.FindRows(TheStructureOfTheSearch);
			
			If Rows.Count() > 0 Then
				
				TransferString = Rows.Get(0);
				FillPropertyValues(CurRow, TransferString, ,"PriceKind, Price, Count, NumberOfPackages");
				
				If CurRow.NumberOfPackages <> TransferString.NumberOfPackages Then
					ProcessedTransferLines.Add(CurRow);
				EndIf;
				
				CurRow.ExistsInTheDocument = True;
				
				CurRow.QuantityInInvoice         = TransferString.Count;
				CurRow.PackagingQuantityInInvoice = TransferString.NumberOfPackages;
				
				TransferGoods.Delete(TransferString);
				
			EndIf;
			
		EndIf;
		
		If OrderList.FindByValue(CurRow.SalesOrder) <> Undefined
			Or CurRow.SalesOrder = SalesOrder
			Or Not ValueIsFilled(CurRow.SalesOrder) Then
			
			CurRow.OrderFromInvoice = True;
			
		EndIf;
		
		CurRow.DiscrepancyInvoice = CurRow.NumberOfPackages - CurRow.PackagingQuantityInInvoice;
		
		If CurRow.DiscrepancyInvoice <> 0
			And ((CurRow.OrderFromInvoice
					And ByOrders)
				Or Not ByOrders) Then
			
			CurRow.RowIsSelected = True;
			
		Else
			CurRow.RowIsSelected = False;
		EndIf;
		
		If WithFilling Then
			
			If (CurRow.PackagingQuantityInInvoice = CurRow.PackagingQuantityInTheOrder
					Or Not ValueIsFilled(CurRow.SalesOrder))
				And (CurRow.PackagingQuantityInInvoice = CurRow.PackagingQuantityInTheNote
					Or Not CurRow.AdvancedWarehousingOnShipment) Then
				
				ArrayOfRowsToDelete_1.Add(TableOfGoods.IndexOf(CurRow));
				
			EndIf;
			
		EndIf;
		
		CurRow.AccountingIsCollected = Number(Not ValueIsFilled(CurRow.SalesOrder)
											And CurRow.NumberInProgress > 0);
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedItemRows,
		StructureOfActions,
		TableOfGoods,
		CachedValues);

	IndexOfArrayElement = ArrayOfRowsToDelete_1.Count() - 1;
	
	While IndexOfArrayElement >= 0 Do
		TableOfGoods.Delete(ArrayOfRowsToDelete_1[IndexOfArrayElement]);
		
		IndexOfArrayElement = IndexOfArrayElement - 1;
	EndDo;
	
	If WithFilling Then

		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ProcessedTransferLines,
			StructureOfActions,
			TableOfGoods,
			CachedValues);

		For Each CurRow In TransferGoods Do
			
			LineProducts_ = TableOfGoods.Add();
			FillPropertyValues(LineProducts_, CurRow, ,"Count, NumberOfPackages");
			
			LineProducts_.RowIsSelected          = True;
			LineProducts_.OrderFromInvoice       = True;
			LineProducts_.ExistsInTheDocument = True;
			
			LineProducts_.QuantityInInvoice         = CurRow.Count;
			LineProducts_.PackagingQuantityInInvoice = CurRow.NumberOfPackages;
			
			LineProducts_.DiscrepancyInvoice = -LineProducts_.PackagingQuantityInInvoice;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation(TransferGoods)
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "SalesOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.OrderNameInTablePart          = "SalesOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseTransferForSeveralOrders;
	
	OrdersServer.UpdateOrderInformationInForm(ThisForm, TransferGoods, ParametersOfUpdate);
	
EndProcedure

&AtServer
Procedure SetSelectionByOrders()
	
	If ByOrders Then
		Items.TableOfGoods.RowFilter = New FixedStructure("OrderFromInvoice", True);
	Else
		Items.TableOfGoods.RowFilter = Undefined;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

&AtServer
Procedure SetTitleFillInByOrdersOrders()
	
	If Not UseWarehouseManagemantSystemForGoodsIssue
		And UseSalesOrders Then
		
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ đơn hàng';
							|ru = 'Подбор товаров по заказам';
							|en = 'Pick goods by orders'; fa = 'Pick goods by orders';
							|it = 'Selezione delle merci per ordini';
							|pl = 'Wybór towarów wg zamówień';
							|tr = 'Siparişe göre ürünlerin seçimi'");
		
	ElsIf UseWarehouseManagemantSystemForGoodsIssue
		And Not UseSalesOrders Then
		
		TitleFillIn = NStr("vi = 'Lựa chọn hàng hóa theo lệnh';
							|ru = 'Подбор товаров по ордерам';
							|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
							|it = 'Selezione delle merci per mandati';
							|pl = 'Wybór towarów wg zleceń';
							|tr = 'Emire göre ürünlerin seçimi'");
		
	Else
		TitleFillIn = NStr("vi = 'Lựa chọn hàng hóa theo lệnh / đơn hàng';
							|ru = 'Подбор товаров по заказам/ордерам';
							|en = 'Pick by Order/Goods issue'; fa = 'انتخاب بر اساس سفارش/صدور کالا';
							|it = 'Selezione delle merci per ordini/mandati';
							|pl = 'Wybór towarów wg zamówień/zleceń wydania';
							|tr = 'Siparişe/emre göre ürünlerin seçimi'");
	EndIf;
	
	Title = TitleFillIn;
	
EndProcedure

&AtClient
Procedure MoveProductsToDocument()
	
	Cancel = False;
	
	// Removal of modification, because before closing, the attribute is checked.
	Modified = False;
	
	If Not UseTransferForSeveralOrders Then
		Cancel = CheckMultipleOrderSelection();
	EndIf;
	
	If Cancel Then
		ShowMessageBox(,NStr("vi = 'Bạn không thể chọn hàng hóa cho nhiều hơn một đơn hàng.';
							|ru = 'Нельзя выбрать товары больше, чем по одному заказу.';
							|en = 'You cannot select more goods than against one order.'; fa = 'You cannot select more goods than against one order.';
							|it = 'Non è possibile selezionare prodotti per più di un ordine.';
							|pl = 'Nie można wybrać towarów dla więcej niż jednego zamówienia.';
							|tr = 'Bir siparişten fazla mal seçemezsiniz.'"));
		
		Return;
	EndIf;
	
	CalculationResult1 = New Structure("GoodsAddressInStorage", PutProductsInStorage());
	
	Close();
	
	NotifyChoice(CalculationResult1);
	
EndProcedure

&AtServer
Function CheckMultipleOrderSelection()
	
	CustomerSFirstOrder = Undefined;
	
	RowFilter      = New Structure("RowIsSelected", True);
	RowsSelected = TableOfGoods.FindRows(RowFilter);
	
	For Each CurRow In RowsSelected Do
		
		If CurRow.RowIsSelected Then
			
			If ValueIsFilled(CustomerSFirstOrder)
				And ValueIsFilled(CurRow.SalesOrder)
				And CustomerSFirstOrder <> CurRow.SalesOrder Then
				
				Return True;
				
			EndIf;
			
			CustomerSFirstOrder = CurRow.SalesOrder;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Function PutProductsInStorage()
	
	// Forming a table to return to the document.
	RowFilter = New Structure("RowIsSelected", True);
	SelectedGoodsTable = TableOfGoods.Unload(RowFilter);
	
	// generating stamp data (if any) for uploading to a document
	SelectedBarcodesOfPackages = New Array;
	
	For Each String In SelectedGoodsTable Do
		BrandSearchStructure = New Structure();
		BrandSearchStructure.Insert("SalesOrder",String.SalesOrder);
		BrandSearchStructure.Insert("Products",String.Products);
		BrandSearchStructure.Insert("Characteristic",String.Characteristic);
		BrandSearchStructure.Insert("Series",String.Series);
		
		FoundRows = TableOfBarcodesOfPackages.FindRows(BrandSearchStructure);
		
		For Each FoundRow In FoundRows Do
			SelectedBarcodesOfPackages.Add(FoundRow.PackageBarcode);
		EndDo;
		
	EndDo;
	
	GoodsAddressInStorage = PutToTempStorage(
		New Structure("Goods, PackageBarcodes", SelectedGoodsTable, SelectedBarcodesOfPackages));
	
	Return GoodsAddressInStorage;
	
EndFunction

&AtServer
Procedure WhenChangingByOrders()
	
	SetSelectionByOrders();
	
	If ByOrders Then
		ResetSelectionOfRowsNotFromInvoice();
	Else
		SetSelectionOfLinesNotFromInvoice();
	EndIf;
	
EndProcedure

&AtServer
Procedure ResetSelectionOfRowsNotFromInvoice()
	
	TheStructureOfTheSearch = New Structure("RowIsSelected", True);
	GoodsSelected = TableOfGoods.FindRows(TheStructureOfTheSearch);
	
	For Each StringMatched In GoodsSelected Do
		StringMatched.RowIsSelected = StringMatched.OrderFromInvoice;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetSelectionOfLinesNotFromInvoice()
	
	TheStructureOfTheSearch = New Structure("RowIsSelected", False);
	GoodsSelected = TableOfGoods.FindRows(TheStructureOfTheSearch);
	
	For Each StringMatched In GoodsSelected Do
		If StringMatched.DiscrepancyInvoice <> 0 Then
			StringMatched.RowIsSelected = True;
		Else
			StringMatched.RowIsSelected = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SelectAllProductsOnServer(SelectionValue = True)
	
	RowFilter    = New Structure("RowIsSelected", Not SelectionValue);
	ProductLines_2 = TableOfGoods.FindRows(RowFilter);
	
	For Each TableRow In ProductLines_2 Do
		
		If ByOrders
			And Not TableRow.OrderFromInvoice Then
			
			TableRow.RowIsSelected = False;
			
		Else
			TableRow.RowIsSelected = SelectionValue;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
