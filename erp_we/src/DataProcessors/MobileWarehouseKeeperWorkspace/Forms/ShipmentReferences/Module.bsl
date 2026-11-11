
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ShowProductPhotos = Parameters.ShowProductPhotos;
	Warehouse     = Parameters.Warehouse;
	Premise = Parameters.Premise;
	Performer = Users.CurrentUser();
	ScanningProcedure = Parameters.ScanningProcedure;
	
	CreateRepresentationOfWarehouseSelection();
	
	UpdateListOfStates();
	UpdateSortingList();
	
	FillInListOfOrders_(); 
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.MPMChoiceForm") Then
		
		Warehouse = ValueSelected;
		CreateRepresentationOfWarehouseSelection();
		UpdateFormData();
		
	EndIf;
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warerooms.Form.MPMChoiceForm") Then
		
		Premise = ValueSelected;
		ToFormRepresentationOfSelectionRoom();
		UpdateFormData();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If UsedFormServer = UsedServer.Main Then
		// Peripherals
		If Source = "Peripherals" And IsInputAvailable() Then
			
			ThereIsRawEvent = MobileWarehouseKeeperWorkspaceClient.ThereIsRawEvent();
			
			If EventName = "ScanData" And ThereIsRawEvent Then
				
				Data = MobileWarehouseKeeperWorkspaceClient.ConvertDataFromScannerToStructure(Parameter);
				
				ProcessBarcode(Data);
				
			EndIf;
		EndIf;
	EndIf;

EndProcedure 

#EndRegion

#Region FormHeaderItemsEventHandlers 

 &AtClient
Procedure ReceiptStatusFilterOnChange(Item)
	
	CreateRepresentationOfWarehouseSelection();
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SortOnChange(Item)
	
	UpdateFormData();  
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfOrders_

&AtClient
Procedure ListOfOrders_Selection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.ListOfOrders_.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Items.ListOfOrders_.CurrentData.ReferenceOrder) = Type("CatalogRef.CounterpartyContracts") 
		And Not ValueIsFilled(Warehouse) Then
		
		Status(NStr("vi = 'Hãy chỉ ra kho bãi trong bộ lọc';
					|ru = 'Укажите склад в отборе';
					|en = 'Specify a warehouse in the filter'; fa = 'Specify a warehouse in the filter';
					|it = 'Укажите склад в отборе';
					|pl = 'Specify a warehouse in the filter';
					|tr = 'Filtredeki ambarı belirtin'"));
		Return;
		
	EndIf;
		
	FillingStructure = New Structure;
	FillingStructure.Insert("Warehouse", Warehouse);
	FillingStructure.Insert("Premise", Premise);
	FillingStructure.Insert("ReferenceOrder", CurrentRow.ReferenceOrder);
	FillingStructure.Insert("Recipient", CurrentRow.Recipient);
	
	FormParameters = New Structure;
	FormParameters.Insert("DocumentType", 2);

	FormParameters.Insert("FillingStructure", FillingStructure);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("DocumentName_1", CurrentRow.DocumentType);
	FormParameters.Insert("Number", CurrentRow.Number);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	LongDesc = New CallbackDescription("UpdateFormData", ThisObject);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Goods",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectionsOpenWarehouse(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	FormOpenParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
		
	Filter = New Structure();
	Filter.Insert("UseWarehouseManagemantSystemForGoodsIssue", True);
	FormOpenParameters.Insert("Filter", Filter);
		
	OpenForm(
		"Catalog.Warehouses.Form.MPMChoiceForm",
		FormOpenParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectionsOpenRoom(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	
	Filter = New Structure();
	Filter.Insert("Owner", Warehouse);
	FormOpenParameters.Insert("Filter", Filter);
	
	OpenForm(
		"Catalog.Warerooms.Form.MPMChoiceForm",
		FormOpenParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure UpdateForm(Command)
	
	UpdateFormData();
	CreateRepresentationOfWarehouseSelection();
	
EndProcedure 

&AtClient
Procedure SelectionsClearWarehouse(Command)
	
	Warehouse = Undefined;
	CreateRepresentationOfWarehouseSelection();
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsCleanRoom(Command)

	Premise = Undefined;
	ToFormRepresentationOfSelectionRoom();
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsClearDate(Command)
	
	DateOfShipment = Undefined;
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsClearSorting(Command)
	
	Sort = "Date";
	Items.ChangeSortingDirection.Picture = PictureLib.SortRowsAsc;
	SortDirection = "Ascending";
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsClearState(Command)
	
	ShipmentStatus = "All";
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure ChangeSortingDirection(Command)
	
	If Items.ChangeSortingDirection.Picture = PictureLib.SortRowsAsc Then
		Items.ChangeSortingDirection.Picture = PictureLib.SortRowsDesc;
		SortDirection = "Descending";
	Else
		Items.ChangeSortingDirection.Picture = PictureLib.SortRowsAsc;
		SortDirection = "Ascending";
	EndIf;
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure StartShipping(Command)
	
	ClearMessages();
	
	FillingStructure = StructureOfOrderFilling();
	FillPropertyValues(FillingStructure, ThisObject);
	
	CurrentRow = Items.ListOfOrders_.CurrentData;
	GoodsQuantity = GetNumberOfProducts(CurrentRow.ReferenceOrder);

	If GoodsQuantity = 0 Then
		Status(NStr("vi = 'Không có hàng hóa để giao hàng';
					|ru = 'Нет товаров для отрузки';
					|en = 'There are no goods to ship'; fa = 'There are no goods to ship';
					|it = 'Нет товаров для отрузки';
					|pl = 'There are no goods to ship';
					|tr = 'Sevkiyat için ürün mevcut değil'"));
		Return;
	EndIf;

	FillingStructure.ShipmentReferences.Add(CurrentRow.ReferenceOrder);
	FillingStructure.Recipient = CurrentRow.Recipient;
	
	CreationResult = NewSpendingOrder(FillingStructure);
	
	If Not ValueIsFilled(CreationResult.Ref) Then
		Return;
	EndIf;
	
	UseBinLocationWarehousing = ThisIsBinLocationSystem(CreationResult.Ref);
	
	LongDesc = New CallbackDescription("UpdateFormData", ThisObject);
	
	If UseBinLocationWarehousing Then
		
		If CreationResult.BatchIndicationIsRequired Then
			
			ClearMessages();
			
			FormParameters = New Structure;
			FormParameters.Insert("Ref", CreationResult.Ref);
			FormParameters.Insert("ShowProductPhotos", ShowProductPhotos); 
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
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ExpenseOrder", FormParameters,
			ThisObject,,,,LongDesc,
			FormWindowOpeningMode.Independent);
	EndIf;

EndProcedure

&AtClient
Procedure FindByBarcode(Command)
	
	If UsedFormServer = UsedServer.Main Then
		
		LongDesc = New CallbackDescription("DocumentScanResult", ThisObject);
	
		FormParameters = New Structure;
		FormParameters.Insert("FindType", "DocumentSearch");
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise);
		FormParameters.Insert("Context", "Shipment");
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateFormData(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateFormDataServer();
	
EndProcedure

&AtServer
Procedure UpdateFormDataServer()
	
	FillInListOfOrders_();
	
EndProcedure

&AtServer
Procedure FillInListOfOrders_()	

#If Not MobileStandaloneServer Then
	If Not ValueIsFilled(Warehouse) Then
		ListOfOrders_.Clear();
		Return;
	EndIf;
	
	If Not Users.IsFullUser(Undefined) Then
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	Warehouses.Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref = &Warehouse";
		
		Query.SetParameter("Warehouse", Warehouse);
		
		If Query.Execute().IsEmpty() Then
			ListOfOrders_.Clear();
			Return;
		EndIf;
		
		SetPrivilegedMode(True);
	EndIf;
	 
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.RequestOrderForShipment(Warehouse);
	
	Query.SetParameter("Warehouse", 				Warehouse);
	Query.SetParameter("TransportationJob", Documents.TransportationJob.EmptyRef());
	Query.SetParameter("DateOfShipment", 		?(ValueIsFilled(DateOfShipment), EndOfDay(DateOfShipment) + 1, DateOfShipment));
	IssueInvoicesFirst = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
	Query.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
	Query.SetParameter("ShowDetailsShipment", False);
	Query.Text = StrReplace(Query.Text, "&ConditionForOrders", "");	
	
	States1 = New Array;
	If ShipmentStatus = "AllInProgress" Then 
		States1.Add(Enums.GoodsPickingStates.DuringSelection);
		States1.Add(Enums.GoodsPickingStates.PendingPicking);
		States1.Add(Enums.GoodsPickingStates.PendingShipment);
	ElsIf ShipmentStatus = "All" Then
		For Each Value In Enums.GoodsPickingStates Do 
			States1.Add(Value);
		EndDo;
	Else
		States1.Add(Enums.GoodsPickingStates[ShipmentStatus]);
	EndIf;
	Query.SetParameter("States1", States1);
	
	Query.Text = Query.Text + "
	|ORDER BY
	|	";
	
	If Sort = "Recipient" Then
		Query.Text = Query.Text + "Recipient.Description";
	Else
		Query.Text = Query.Text + Sort;
	EndIf;
	
	If SortDirection = "Descending" Then
		Query.Text = Query.Text + " DESC";
	Else
		Query.Text = Query.Text + " ASC";
	EndIf;
	
	ListOfOrders_.Load(Query.Execute().Unload());	
#EndIf

EndProcedure

&AtServer
Procedure CreateRepresentationOfWarehouseSelection()
	
	PresentationsOfSelections = "";
	If ValueIsFilled(Warehouse) Then
		PresentationsOfSelections = Warehouse;
		Items.TeamSelectionsToOpen.TextColor = WebColors.Black;
		Items.TeamSelectionsClear.Visible = True;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuBlack;
		
	Else
		PresentationsOfSelections = NStr("vi = 'Chọn kho bãi';
										|ru = 'Выбрать склад';
										|en = 'Select a warehouse'; fa = 'Select a warehouse';
										|it = 'Selezionare magazzino';
										|pl = 'Wybierz magazyn';
										|tr = 'Ambar seç'");

		Items.TeamSelectionsToOpen.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClear.Visible = False;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	If Warehouse["IsFolder"] Then
		UseWarerooms = False;
	Else
		UseWarerooms = Warehouse["UseWarerooms"];
	EndIf;
	Items.GroupTeamSelectionsOpen1.Visible    = UseWarerooms;
	Items.TeamSelectionsClearRoom.Visible = UseWarerooms;
	
	Items.TeamSelectionsToOpen.Title = PresentationsOfSelections;
	
EndProcedure

&AtClient
Procedure ToFormRepresentationOfSelectionRoom()
	
	PresentationsOfSelections = "";
	If ValueIsFilled(Premise) Then
		PresentationsOfSelections = Premise;
		Items.TeamSelectionsOpenRoom.TextColor = WebColors.Black;
		Items.TeamSelectionsClearRoom.Visible = True;
		Items.FrameSelectionsOpen1.Picture = PictureLib.BorderMenuBlack;
	Else
		PresentationsOfSelections = NStr("vi = 'Nhà kho';
										|ru = 'Помещение';
										|en = 'Wareroom'; fa = 'بخش انبار';
										|it = 'Locale';
										|pl = 'Pomieszczenie';
										|tr = 'Alan'");
		Items.TeamSelectionsOpenRoom.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClearRoom.Visible = False;
		Items.FrameSelectionsOpen1.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	Items.TeamSelectionsOpenRoom.Title = PresentationsOfSelections;
	
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)

	BarcodesAreValid = MobileWarehouseKeeperWorkspaceClient.BarcodesAreValid(BarcodeData_1); 
	
	If Not BarcodesAreValid Then
		Return;
	EndIf;
	
	Status(NStr("vi = 'Đang tìm kiếm đối tượng theo mã vạch...';
				|ru = 'Выполняется поиск объекта по штрихкоду...';
				|en = 'Searching for the object by barcode...'; fa = 'Searching for the object by barcode...';
				|it = 'Searching for the object by barcode...';
				|pl = 'Searching for the object by barcode...';
				|tr = 'Nesne barkoda göre aranıyor...'"));
		
	BarcodeData = BarcodeDataOrders(BarcodeData_1.Barcode);
	
	If ValueIsFilled(BarcodeData.References) Then
		DocumentScanResult(BarcodeData);
	Else 
		Status(NStr("vi = 'Không tìm thấy chứng từ theo mã vạch.
			|Có thể kho đã chỉ định không chính xác.';
			|ru = 'Документ по штрихкоду не найден.
			|Возможно неверно указан склад.';
			|en = 'The document is not found by barcode.
			|The warehouse may be specified incorrectly.'; fa = 'The document is not found by barcode.
			|The warehouse may be specified incorrectly.';
			|it = 'The document is not found by barcode.
			|The warehouse may be specified incorrectly.';
			|pl = 'The document is not found by barcode.
			|The warehouse may be specified incorrectly.';
			|tr = 'Barkoda göre belge bulunamadı.
			|Ambar yanlış belirtilmiş olabilir.'"));
	EndIf;
		
EndProcedure

&AtServer
Function BarcodeDataOrders(Val Barcode)
		
	Return DataProcessors.MobileWarehouseKeeperWorkspace.DataOfDocumentOnSHK(Barcode, Warehouse, "Shipment");
	
EndFunction 

&AtClient
Procedure DocumentScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	LongDesc = New CallbackDescription("UpdateFormData", ThisObject);

	If Result.References.Count() > 1 Then
		
		LongDesc = New CallbackDescription("DocumentScanResult", ThisObject);
		
		FormParameters = New Structure;
		FormParameters.Insert("ScanningResult", Result);
		FormParameters.Insert("Warehouse", Warehouse); 
		FormParameters.Insert("Premise", Premise);
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ScanSelectionForm", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		ReferenceOrder =  Result.References[0];
		
		FillingStructure = New Structure;
		FillingStructure.Insert("Warehouse", Warehouse);
		FillingStructure.Insert("Premise", Premise);
		FillingStructure.Insert("ReferenceOrder", ReferenceOrder.ReferenceOrder); 
		
		FormParameters = New Structure;

		FillingStructure.Insert("Recipient", ReferenceOrder.Recipient);
		FormParameters.Insert("DocumentType", 2);
		
		FormParameters.Insert("FillingStructure", FillingStructure);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("DocumentName_1", ReferenceOrder.DocumentType);
		FormParameters.Insert("Number", ReferenceOrder.Number);
		FormParameters.Insert("Barcode", Result.Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Goods", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StructureOfOrderFilling()
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.FillingStructureOfExpenseOrder();
	
EndFunction

&AtServerNoContext
Function GetNumberOfProducts(ReferenceOrder)
	
	QueryResult = DataProcessors.MobileWarehouseKeeperWorkspace.ListOfGoodsForShipmentAcceptance(2, ReferenceOrder);

	Return QueryResult.Count();
	
EndFunction

&AtServer
Procedure UpdateListOfStates()
	
	UseGoodsIssueNoteStatuses = GetFunctionalOption("UseGoodsIssueNoteStatuses", 
																			New Structure("Warehouse", Warehouse));
	
	Items.State.ChoiceList.Clear();
	
	If UseGoodsIssueNoteStatuses Then
		Items.State.ChoiceList.Add("AllInProgress", NStr("vi = 'Tất cả đang làm việc';
														|ru = 'Все в работе';
														|en = 'All in progress'; fa = 'All in progress';
														|it = 'Tutto in esecuzione';
														|pl = 'Wszystkie w toku';
														|tr = 'Tümü işte'"));		
		Items.State.ChoiceList.Add("PendingPicking", NStr("vi = 'Đang chờ lấy ra';
															|ru = 'Ожидается отбор';
															|en = 'Pending picking'; fa = 'در انتظار برداشت';
															|it = 'In attesa della selezione';
															|pl = 'Oczekuje się dobór';
															|tr = 'Filtre bekleniyor'"));
		Items.State.ChoiceList.Add("PendingShipment", NStr("vi = 'Đang chờ xuất hàng';
															|ru = 'Ожидается отгрузка';
															|en = 'Pending shipment'; fa = 'در انتظار ارسال';
															|it = 'In attesa della spedizione';
															|pl = 'Oczekuje się wysyłka';
															|tr = 'Sevkiyat bekleniyor'"));		
		Items.State.ChoiceList.Add("PendingInvoiceRegistration", NStr("vi = 'Đang chờ lập hóa đơn';
																		|ru = 'Ожидается оформление накладных';
																		|en = 'Pending invoice registration'; fa = 'در انتظار ثبت فاکتور';
																		|it = 'È prevista l''emissione dei documenti di trasporto';
																		|pl = 'Oczekiwanie sporządzenia faktur';
																		|tr = 'İrsaliye düzenleme bekleniyor'"));
		Items.State.ChoiceList.Add("All", NStr("vi = 'Tất cả';
												|ru = 'Все';
												|en = 'All'; fa = 'همه';
												|it = 'Tutti';
												|pl = 'Wszystkie';
												|tr = 'Tümü'"));
		ShipmentStatus = "AllInProgress";
	Else
		Items.State.ChoiceList.Add("PendingPicking", NStr("vi = 'Đang chờ lấy ra';
															|ru = 'Ожидается отбор';
															|en = 'Pending picking'; fa = 'در انتظار برداشت';
															|it = 'In attesa della selezione';
															|pl = 'Oczekuje się dobór';
															|tr = 'Filtre bekleniyor'"));
		Items.State.ChoiceList.Add("PendingInvoiceRegistration", NStr("vi = 'Đang chờ lập hóa đơn';
																		|ru = 'Ожидается оформление накладных';
																		|en = 'Pending invoice registration'; fa = 'در انتظار ثبت فاکتور';
																		|it = 'È prevista l''emissione dei documenti di trasporto';
																		|pl = 'Oczekiwanie sporządzenia faktur';
																		|tr = 'İrsaliye düzenleme bekleniyor'"));
		Items.State.ChoiceList.Add("All", NStr("vi = 'Tất cả';
												|ru = 'Все';
												|en = 'All'; fa = 'همه';
												|it = 'Tutti';
												|pl = 'Wszystkie';
												|tr = 'Tümü'"));		
		ShipmentStatus = "PendingPicking";
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateSortingList()
	
	ShipmentStatus = "All";
	
	Items.Sort.ChoiceList.Clear();
	Items.Sort.ChoiceList.Add("Date", NStr("vi = 'Ngày';
											|ru = 'Дата';
											|en = 'Date'; fa = 'تاریخ';
											|it = 'Data';
											|pl = 'Data';
											|tr = 'Tarih'"));
	Items.Sort.ChoiceList.Add("Number", NStr("vi = 'Số';
											|ru = 'Номер';
											|en = 'Number'; fa = 'شماره';
											|it = 'Numero';
											|pl = 'Numer';
											|tr = 'Numara'"));
	Items.Sort.ChoiceList.Add("Recipient", NStr("vi = 'Người nhận';
												|ru = 'Получатель';
												|en = 'Recipient'; fa = 'گیرنده';
												|it = 'Destinatario';
												|pl = 'Odbiorca';
												|tr = 'Alıcı'"));
	Sort = "Date";
	
	Items.ChangeSortingDirection.Picture = PictureLib.SortRowsAsc;
	SortDirection = "Ascending";
	
EndProcedure

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

&AtServerNoContext
Function NewSpendingOrder(FillingStructure)
		
	Return DataProcessors.MobileWarehouseKeeperWorkspace.NewSpendingOrder(FillingStructure);

EndFunction 

&AtServerNoContext
Function NewSelectionOfGoods(LinkSpendingOrder)
		
	Return DataProcessors.MobileWarehouseKeeperWorkspace.NewSelectionOfGoods(LinkSpendingOrder);

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
	If Item.Name = "sh_ShamsiInput_F_DateOfShipment" Then
		DateOfReceiptOnChange(Items.DateOfShipment);
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
