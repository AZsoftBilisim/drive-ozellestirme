#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DocumentType = Parameters.DocumentType;
	Barcode = Parameters.Barcode;
	ScanningProcedure = Parameters.ScanningProcedure;
	
	Items.StartAcceptance.Visible = DocumentType = 1;
	Items.StartShipping.Visible = DocumentType = 2 Or DocumentType = 3;
				
	FillPropertyValues(ThisObject, Parameters.FillingStructure); 
	
	If DocumentType = 1 Then
		ReferenceOrder = Parameters.FillingStructure.ReferenceOrder;
		TheOrderLine = ToFormPresentationOfOrder(Parameters.DocumentName_1, Parameters.Number,
				Common.ObjectAttributeValue(ReferenceOrder, "Date"));
		ControlledLotReference = Parameters.FillingStructure.ControlledLotReference;
		QueryResult = 
			DataProcessors.MobileWarehouseKeeperWorkspace.ListOfGoodsForShipmentAcceptance(
				Parameters.DocumentType,
				ReferenceOrder,
				ControlledLotReference);
			
		Items.Sender.Visible = (TypeOf(Sender) = Type("CatalogRef.Partners") Or TypeOf(Sender) = Type("CatalogRef.Persons"));
	ElsIf DocumentType = 2 Then 
		OrderShipment = Parameters.FillingStructure.ReferenceOrder;
		TheOrderLine = ToFormPresentationOfOrder(Parameters.DocumentName_1, Parameters.Number,
				Common.ObjectAttributeValue(OrderShipment, "Date"));
		QueryResult = 
			DataProcessors.MobileWarehouseKeeperWorkspace.ListOfGoodsForShipmentAcceptance(Parameters.DocumentType, OrderShipment);
			
		Items.Recipient.Visible = (TypeOf(Recipient) = Type("CatalogRef.Partners") Or TypeOf(Recipient) = Type("CatalogRef.Persons"));
	Else
		ExpenseOrder = Parameters.FillingStructure.ReferenceOrder;	
		QueryResult = ListOfGoodsForShipmentByOrder();
	
		DateOrderNumber = Common.ObjectAttributesValues(ExpenseOrder, "Date, Number");
		DocumentName_1 = NStr("vi = 'Phiếu xuất kho';
								|ru = 'Расходный ордер';
								|en = 'Goods issue note'; fa = 'حواله صدور کالا';
								|it = 'Mandato di pagamento';
								|pl = 'Asygnata rozchodowa';
								|tr = 'Ambar çıkış fişi'");
		TheOrderLine = ToFormPresentationOfOrder(DocumentName_1, DateOrderNumber.Number,
				DateOrderNumber.Date);
		Items.Recipient.Visible = (TypeOf(Recipient) = Type("CatalogRef.Partners") Or TypeOf(Recipient) = Type("CatalogRef.Persons"));
		Items.StartShipping.Title = NStr("vi = 'Bắt đầu lấy ra';
										|ru = 'Начать отбор';
										|en = 'Start picking'; fa = 'Start picking';
										|it = 'Start picking';
										|pl = 'Start picking';
										|tr = 'Filtrelemeye başla'");
	EndIf;
		
	Goods.Load(QueryResult);

	ShowProductPhotos = Parameters.ShowProductPhotos;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If UsedFormServer = UsedServer.Main Then
		// Peripherals
		If Source = "Peripherals" And IsInputAvailable() Then 
			
			ThereIsRawEvent = MobileWarehouseKeeperWorkspaceClient.ThereIsRawEvent();
			If EventName = "ScanData" And ThereIsRawEvent Then
		
				If DocumentType = 1 Then 
					StartAcceptance();
				ElsIf DocumentType = 2 Or DocumentType = 3 Then
					StartShipping();
				EndIf;
			
			EndIf;
		EndIf;
	EndIf;

EndProcedure 

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackages);
	FormParameters.Insert("Mode", "View");
	FormParameters.Insert("LineNumber", Item.CurrentRow); 
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure StartAcceptanceCommand(Command)
	
	StartAcceptance()
	
EndProcedure

&AtClient
Procedure StartShipmentCommand(Command)
	
	StartShipping()
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ToFormPresentationOfOrder(DocumentName_1, Number, Date)
	
	AbbreviatedNumber = ObjectsPrefixesClientServer.NumberForPrinting(Number);

	Return StrTemplate(NStr("vi = '%1 số %2 ngày %3';
							|ru = '%1 № %2 от %3';
							|en = '%1 #%2, %3'; fa = '%1 #%2, %3';
							|it = '%1 № %2 dal %3';
							|pl = '%1 nr %2 z dnia %3.';
							|tr = '%3 tarihli %2 numaralı %1'"), DocumentName_1, AbbreviatedNumber, Format(Date, NStr("vi = 'DF=''dd.ММ.yyy HH:mm''';
																										|ru = 'ДФ=''дд.ММ.гг ЧЧ:мм''';
																										|en = 'DF=''MM/dd/yy hh:mm tt'''; fa = 'DF=''MM/dd/yy hh:mm tt''';
																										|it = 'D F ''=gg.ММ.aa 00:mm''';
																										|pl = 'DF=''dd.MM.yy HH:mm''';
																										|tr = 'DF=''dd.MM.yy HH:mm'''")));
	
EndFunction 

&AtClient
Procedure StartAcceptance()
	
	If Goods.Count() = 0 Then  
		Status(NStr("vi = 'Không có hàng hóa để nhận';
					|ru = 'Нет товаров для приемки';
					|en = 'There are no goods to receive'; fa = 'There are no goods to receive';
					|it = 'Нет товаров для приемки';
					|pl = 'There are no goods to receive';
					|tr = 'Kabul için ürün mevcut değil'"));
		Return;
	EndIf;
	
	FillingStructure = GetStructureOfOrderFilling();
	
	FillPropertyValues(FillingStructure, ThisObject);
	
	LongDesc = New CallbackDescription("CloseForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("DocumentType", 1);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);  
	FormParameters.Insert("FillingStructure", FillingStructure);
	FormParameters.Insert("Barcode", Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ReceiptGoodsOrder",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure StartShipping()
	
	ClearMessages();
	
	If Goods.Count() = 0 Then
		Status(NStr("vi = 'Không có hàng hóa để giao';
					|ru = 'Нет товаров для отгрузки';
					|en = 'There are no goods to ship'; fa = 'There are no goods to ship';
					|it = 'Нет товаров для отгрузки';
					|pl = 'There are no goods to ship';
					|tr = 'Sevkiyat için ürün mevcut değil'")); 
		Return;
	EndIf; 
	
	LongDesc = New CallbackDescription("CloseForm", ThisObject);

	If DocumentType = 3 Then
		
		SpecifyingSeries = CheckStatusOfBatchIndicationWhenPlanningSelection(ExpenseOrder); 
		
		If SpecifyingSeries Then
			
			ClearMessages();
			
			FormParameters = New Structure;
			FormParameters.Insert("Ref",ExpenseOrder);
			FormParameters.Insert("ShowProductPhotos", ShowProductPhotos); 
			FormParameters.Insert("Barcode", Barcode);
			FormParameters.Insert("ScanningProcedure", ScanningProcedure);

			OpenForm(
				"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ExpenseOrder", FormParameters,
				ThisObject,,,,LongDesc,
				FormWindowOpeningMode.Independent);
				
			Return;
		EndIf;
		
		RefFilter = NewSelectionOfGoods(ExpenseOrder);

		If Not ValueIsFilled(RefFilter) Then		
			ErrorText = NStr("vi = 'Không thể thực hiện nhiệm vụ lấy ra hàng hóa theo quy tắc lấy ra.';
							|ru = 'Не удалось сформировать задания на отбор товаров согласно правилам отбора.';
							|en = 'Cannot generate goods picking jobs according to the picking rules.'; fa = 'Cannot generate goods picking jobs according to the picking rules.';
							|it = 'Impossibile generare i task per la selezione delle merci secondo le regole di selezione.';
							|pl = 'Nie udało się utworzyć zadania na wybór towarów zgodnie z zasadami wyboru.';
							|tr = 'Filtre kurallarına göre ürün filtre görevleri oluşturulamadı.'");
			Status(ErrorText);
			Return;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref", RefFilter);
		FormParameters.Insert("Performer", Performer);
		FormParameters.Insert("Seamless", True);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Barcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Filter", FormParameters,
			ThisObject,,,,LongDesc,
			FormWindowOpeningMode.Independent);
			
		Return;
	EndIf;
	
	FillingStructure = GetStructureOfFillingExpenseOrder();
	
	FillPropertyValues(FillingStructure, ThisObject);
	FillingStructure.ShipmentReferences.Add(OrderShipment);
	
	CreationResult = NewSpendingOrder(FillingStructure);
	
	If Not ValueIsFilled(CreationResult.Ref) Then
		Return;
	EndIf;
	
	UseBinLocationWarehousing = ThisIsBinLocationSystem(CreationResult.Ref);
	
	If UseBinLocationWarehousing Then  
		
		If CreationResult.BatchIndicationIsRequired Then
			
			ClearMessages();
			
			FormParameters = New Structure;
			FormParameters.Insert("Ref", CreationResult.Ref);
			FormParameters.Insert("ShowProductPhotos", ShowProductPhotos); 
			FormParameters.Insert("Barcode", Barcode);
			FormParameters.Insert("ScanningProcedure", ScanningProcedure);

			OpenForm(
				"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ExpenseOrder", FormParameters,
				ThisObject,,,,LongDesc,
				FormWindowOpeningMode.Independent);
				
			Return;
		EndIf;

		RefFilter = NewSelectionOfGoods(CreationResult.Ref);
		
		If Not ValueIsFilled(RefFilter) Then
			ErrorText = NStr("vi = 'Không thể thực hiện nhiệm vụ lấy ra hàng hóa theo quy tắc lấy ra.';
							|ru = 'Не удалось сформировать задания на отбор товаров согласно правилам отбора.';
							|en = 'Cannot generate goods picking jobs according to the picking rules.'; fa = 'Cannot generate goods picking jobs according to the picking rules.';
							|it = 'Impossibile generare i task per la selezione delle merci secondo le regole di selezione.';
							|pl = 'Nie udało się utworzyć zadania na wybór towarów zgodnie z zasadami wyboru.';
							|tr = 'Filtre kurallarına göre ürün filtre görevleri oluşturulamadı.'");
			Status(ErrorText);
			Return;
		EndIf;
	
		FormParameters = New Structure;
		FormParameters.Insert("Ref", RefFilter);
		FormParameters.Insert("Performer", Performer);
		FormParameters.Insert("Seamless", True);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Barcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Filter", FormParameters,
			ThisObject,,,,LongDesc,
			FormWindowOpeningMode.Independent);
		
	Else
		
		If CreationResult.HasError Then
			Return;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref", CreationResult.Ref);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Barcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ExpenseOrder", FormParameters,
			ThisObject,,,,LongDesc,
			FormWindowOpeningMode.Independent);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetStructureOfOrderFilling()
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.StructureOfFillingIncomingOrder();
	
EndFunction 

&AtServerNoContext
Function GetStructureOfFillingExpenseOrder()
	
	Return WarehousesServer.ParametersForReissuingSpendingOrders();
	
EndFunction

&AtServer
Function ThisIsBinLocationSystem(Val LinkToSpendingOrder)
	
	WarehouseProperties = DataProcessors.MobileWarehouseKeeperWorkspace.WarehouseProperties(Warehouse);	
	UseBinLocationWarehousing = WarehouseProperties.UseBinLocationWarehousing;
	Premise = Common.ObjectAttributeValue(LinkToSpendingOrder, "Premise");
	If WarehouseProperties.UseWarerooms Then
		StructureOfRoom = Common.ObjectAttributesValues(Premise, "UseBinLocationWarehousing");
		UseBinLocationWarehousing = StructureOfRoom.UseBinLocationWarehousing;
	EndIf;
	
	Return UseBinLocationWarehousing;
	
EndFunction

&AtServer
Function CheckStatusOfBatchIndicationWhenPlanningSelection(Val LinkToSpendingOrder)
	
	SpecifyingSeries = 
		DataProcessors.MobileWarehouseKeeperWorkspace.CheckStatusOfBatchIndicationWhenPlanningSelection(LinkToSpendingOrder, 
		Warehouse);
	
	Return SpecifyingSeries;
	
EndFunction

&AtServer
Function ListOfGoodsForShipmentByOrder()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	GoodsByReferences.Products AS Products,
		|	GoodsByReferences.Products.SKU AS SKU,
		|	GoodsByReferences.Products.UnitOfMeasure AS Package,
		|	GoodsByReferences.Characteristic AS Characteristic,
		|	GoodsByReferences.Series AS Series,
		|	GoodsByReferences.Purpose AS Purpose,
		|	GoodsByReferences.Count AS Count,
		|	GoodsByReferences.Count AS NumberOfPackages
		|FROM
		|	Document.GoodsIssueNote.GoodsByReferences AS GoodsByReferences
		|WHERE
		|	GoodsByReferences.Ref = &Ref";
	
	Query.SetParameter("Ref", ExpenseOrder);
	Return Query.Execute().Unload();
	
EndFunction

&AtServerNoContext
Function NewSpendingOrder(Val FillingStructure)
		
	Return DataProcessors.MobileWarehouseKeeperWorkspace.NewSpendingOrder(FillingStructure);

EndFunction 

&AtServerNoContext
Function NewSelectionOfGoods(Val LinkSpendingOrder)
		
	Return DataProcessors.MobileWarehouseKeeperWorkspace.NewSelectionOfGoods(LinkSpendingOrder);

EndFunction

#EndRegion