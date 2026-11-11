
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ShowProductPhotos = Parameters.ShowProductPhotos;
	Warehouse                 = Parameters.Warehouse;
	Premise             = Parameters.Premise;
	Performer           = Parameters.Performer;
	ScanningProcedure   = Parameters.ScanningProcedure;
	
	UpdateSelectionsAndSorting();
	
#If MobileStandaloneServer Then
	Items.Performer.ChoiceButton = False;
#EndIf
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CreateSelectionView();
	ToFormRepresentationOfSelectionRoom();
	
	UpdateFormDataServer();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.MPMChoiceForm") Then
		
		Warehouse = ValueSelected;
		Premise = Undefined;
		CreateSelectionView();
		ToFormRepresentationOfSelectionRoom();
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

#Region FormTableItemsEventHandlersOrdersList

&AtClient
Procedure OrdersListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.OrdersList.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref", CurrentRow.Ref);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	LongDesc = New CallbackDescription("UpdateFormData", ThisObject);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ReceiptGoodsOrder",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectionsOpen(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	FormOpenParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
		
	Filter = New Structure();
	Filter.Insert("UseWarehouseManagemantSystemForGoodsReceipt", True);
	FormOpenParameters.Insert("Filter", Filter);
	
	OpenForm(
		"Catalog.Warehouses.Form.MPMChoiceForm",
		FormOpenParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UpdateForm(Command)
	UpdateFormData();
	CreateSelectionView();
EndProcedure 

&AtClient
Procedure SelectionsClearWarehouse(Command)
	
	Warehouse = Undefined;
	Premise = Undefined;
	CreateSelectionView();
	ToFormRepresentationOfSelectionRoom();
	UpdateFormData();
	
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
Procedure SelectionsCleanRoom(Command)
	
	Premise = Undefined;
	ToFormRepresentationOfSelectionRoom();
	UpdateFormData(); 
	
EndProcedure

&AtClient
Procedure FindByBarcode(Command)
	
	LongDesc = New CallbackDescription("DocumentScanResult", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType", "DocumentSearch");
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Context", "ReceiptGoodsOrder");

	If UsedFormServer = UsedServer.Main Then
				
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent); 
	Else
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanningOfflineMode", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent); 	
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item) 
	
	CreateSelectionView();
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure PerformerOnChange(Item)
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectPeriod(Command)
	
	Notification = New CallbackDescription(
		"SelectPeriodCompletion",
		ThisObject);
		
	MobileWarehouseKeeperWorkspaceClient.EditPeriod(
		ThisObject,
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"),
		Notification);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateFormData(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateFormDataServer();
	
EndProcedure

&AtServer
Procedure UpdateFormDataServer()
	
	FillListOfOrders();
	
EndProcedure

&AtServer
Procedure FillListOfOrders()

	UseGoodsReceiptNoteStatuses = False; 
	If ValueIsFilled(Warehouse) Then
		UseGoodsReceiptNoteStatuses = Warehouse["UseGoodsReceiptNoteStatuses"];
	EndIf;	
	Items.SelectionsStatus.Visible = UseGoodsReceiptNoteStatuses;
	
	OrdersList.Clear();
	
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.GoodsReceiptNoteList();
	
	Query.SetParameter("Warehouse", Warehouse);
	
	If ValueIsFilled(Premise) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "AND GoodsReceiptNote.Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "");
	EndIf;
	
	If ValueIsFilled(Performer) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionExecutor", "AND GoodsReceiptNote.Performer = &Performer");
		Query.SetParameter("Performer", Performer);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionExecutor", "");
	EndIf;
	
	If UseGoodsReceiptNoteStatuses Then
		Statuses = New Array;
		If Status = "AllRejected" Then 
			Statuses.Add(Enums.GoodsReceiptNoteStatuses.ToReceive);
			Statuses.Add(Enums.GoodsReceiptNoteStatuses.InProgress);
		ElsIf Status = "All" Then
			For Each Value In Enums.GoodsReceiptNoteStatuses Do 
				Statuses.Add(Value);
			EndDo;
		Else
			Statuses.Add(Enums.GoodsReceiptNoteStatuses[Status]);
		EndIf;
		Query.SetParameter("Statuses", Statuses);
	Else
	    Query.Text = StrReplace(Query.Text, "AND GoodsReceiptNote.Status IN (&Statuses)", "");
	EndIf;
	
	If ValueIsFilled(BeginOfPeriod) And ValueIsFilled(EndOfPeriod) Then
		Query.Text = Query.Text + "
	|	AND GoodsReceiptNote.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod";
		Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
		Query.SetParameter("EndOfPeriod", EndOfPeriod + 60*60*24);
	EndIf;
	
	Query.Text = Query.Text + "
	|ORDER BY
	|	";
	
	If Sort = "Sender" Then
		Query.Text = Query.Text + "Sender.Description";
	Else
		Query.Text = Query.Text + Sort;
	EndIf;
	
	If SortDirection = "Descending" Then
		Query.Text = Query.Text + " DESC";
	Else
		Query.Text = Query.Text + " ASC";
	EndIf;
	
	OrdersList.Load(Query.Execute().Unload());
	
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
		
	BarcodeData = BarcodeDocumentData(BarcodeData_1.Barcode);
	
	If ValueIsFilled(BarcodeData.References) Then
		DocumentScanResult(BarcodeData);
	Else 
		Status(NStr("vi = 'Không tìm thấy chứng từ theo mã vạch.';
					|ru = 'Документ по штрихкоду не найден.';
					|en = 'Document is not found by barcode.'; fa = 'Document is not found by barcode.';
					|it = 'Document is not found by barcode.';
					|pl = 'Document is not found by barcode.';
					|tr = 'Barkod ile belge bulunamadı.'"));
	EndIf;
	
EndProcedure

&AtServer
Function BarcodeDocumentData(Val Barcode)
		
	Return DataProcessors.MobileWarehouseKeeperWorkspace.DataOfWarehouseDocumentForSHK(Barcode, "ReceiptGoodsOrder");
	
EndFunction

&AtClient
Procedure DocumentScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	If Result.References.Count() Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref", Result.References[0]);
		FormParameters.Insert("Performer", Performer);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Barcode", Result.Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		LongDesc = New CallbackDescription("UpdateFormData", ThisObject);
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ReceiptGoodsOrder", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateSelectionView()
	
	PresentationsOfSelections = "";
	If ValueIsFilled(Warehouse) Then
		PresentationsOfSelections = Warehouse;
		Items.TeamSelectionsToOpen.TextColor = WebColors.Black;
		Items.TeamSelectionsClear.Visible = True;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuBlack;
	Else
		PresentationsOfSelections = NStr("vi = 'Kho bãi';
										|ru = 'Склад';
										|en = 'Warehouse'; fa = 'Warehouse';
										|it = 'Magazzino';
										|pl = 'Magazyn';
										|tr = 'Ambar'");
		Items.TeamSelectionsToOpen.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClear.Visible = False;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	If Warehouse["IsFolder"] Then
		UseWarerooms = False;
	Else
		UseWarerooms = Warehouse["UseWarerooms"];
	EndIf;
	Items.GroupTeamSelectionsOpen2.Visible    = UseWarerooms;
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
		Items.FrameSelectionsOpen2.Picture = PictureLib.BorderMenuBlack;
	Else
		PresentationsOfSelections = NStr("vi = 'Chọn nhà kho';
										|ru = 'Выбрать помещение';
										|en = 'Select a wareroom'; fa = 'Select a wareroom';
										|it = 'Selezionare locale';
										|pl = 'Wybierz pomieszczenie';
										|tr = 'Alan seç'");
		Items.TeamSelectionsOpenRoom.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClearRoom.Visible = False;
		Items.FrameSelectionsOpen2.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	Items.TeamSelectionsOpenRoom.Title = PresentationsOfSelections;
	
EndProcedure

&AtServer
Procedure UpdateSelectionsAndSorting()
	
	Items.Status.ChoiceList.Clear();
	
	Items.Status.ChoiceList.Add("All", NStr("vi = 'Tất cả';
											|ru = 'Все';
											|en = 'All'; fa = 'همه';
											|it = 'Tutti';
											|pl = 'Wszystkie';
											|tr = 'Tümü'"));
	Items.Status.ChoiceList.Add("AllRejected", NStr("vi = 'Tất cả chưa được tiếp nhận';
													|ru = 'Все непринятые';
													|en = 'All rejected'; fa = 'All rejected';
													|it = 'All rejected';
													|pl = 'All rejected';
													|tr = 'Tüm reddedilenler'"));		
	Items.Status.ChoiceList.Add("ToReceive", NStr("vi = 'Đến nhập hàng';
													|ru = 'К поступлению';
													|en = 'To receive'; fa = 'برای دریافت';
													|it = 'In arrivo';
													|pl = 'Do przyjęcia';
													|tr = 'Teslim alınacak'"));
	Items.Status.ChoiceList.Add("InProgress", NStr("vi = 'Đang làm việc';
													|ru = 'В работе';
													|en = 'In progress'; fa = 'در حال انجام';
													|it = 'In esecuzione';
													|pl = 'Wykonuje się';
													|tr = 'İşleniyor'"));
	Items.Status.ChoiceList.Add("DataProcessorIsRequired", NStr("vi = 'Cần xử lý';
																|ru = 'Требуется обработка';
																|en = 'Processing is required'; fa = 'پردازش الزامی است';
																|it = 'Elaborazione richiesta';
																|pl = 'Jest wymagane przetwarzanie';
																|tr = 'İşleme gereklidir'"));
	Items.Status.ChoiceList.Add("Accepted", NStr("vi = 'Đã tiếp nhận';
												|ru = 'Принят';
												|en = 'Accepted'; fa = 'پذیرفته‌شده';
												|it = 'Accepted';
												|pl = 'Accepted';
												|tr = 'Kabul edildi'"));
	
	Status = "AllRejected";
	
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
	Items.Sort.ChoiceList.Add("Sender", NStr("vi = 'Nơi gửi';
											|ru = 'Отправитель';
											|en = 'Sender'; fa = 'فرستنده';
											|it = 'Mittente';
											|pl = 'Nadawca';
											|tr = 'Gönderici'"));
	Sort = "Date";
	
	Items.ChangeSortingDirection.Picture = PictureLib.SortRowsAsc;
	SortDirection = "Ascending";
	
	Items.Performer.ChoiceList.Clear();
	Items.Performer.ChoiceList.LoadValues(DataProcessors.MobileWarehouseKeeperWorkspace.GetListOfUsers());
	Items.Performer.ChoiceList.Insert(0, Performer, NStr("vi = '<Chứng từ của tôi>';
														|ru = '<Мои документы>';
														|en = '<My documents>'; fa = '<My documents>';
														|it = '<i miei documenti>';
														|pl = '<Моje dokumenty>';
														|tr = '<Belgelerim>'"));
	
EndProcedure

&AtClient
Procedure SortOnChange(Item)
	UpdateFormData();
EndProcedure
	
&AtClient
Procedure SelectPeriodCompletion(Period, AdditionalParameters) Export
	
	If Period <> Undefined Then
		PeriodForChangesOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If BeginOfPeriod > EndOfPeriod Then
		EndOfPeriod = BeginOfPeriod;
	EndIf;
	
	PeriodForChangesOnServer();
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If EndOfPeriod < BeginOfPeriod And ValueIsFilled(EndOfPeriod) Or Not ValueIsFilled(BeginOfPeriod) Then
		BeginOfPeriod = EndOfPeriod;
	EndIf;
	
	PeriodForChangesOnServer();
	
EndProcedure

&AtServer
Procedure PeriodForChangesOnServer()
	
	UpdateFormDataServer();
	
EndProcedure

&AtClient
Procedure SelectionsClearSorting(Command)
	
	Sort = "Date";
	Items.ChangeSortingDirection.Picture = PictureLib.SortRowsAsc;
	SortDirection = "Ascending";
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsClearPeriod(Command)
	
	BeginOfPeriod =  '00010101';
	EndOfPeriod =  '00010101';
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsClearArtist(Command)
	
	Performer = Undefined;
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsClearStatus(Command)
	
	Status = "All";
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
	If Item.Name = "sh_ShamsiInput_F_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndOfPeriod" Then
		EndOfPeriodOnChange(Items.EndOfPeriod);
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
