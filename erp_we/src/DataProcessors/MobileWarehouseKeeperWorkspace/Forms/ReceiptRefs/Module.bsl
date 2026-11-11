
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	ShowProductPhotos = Parameters.ShowProductPhotos;
	ScanningProcedure   = Parameters.ScanningProcedure;
	Warehouse                 = Parameters.Warehouse;
	Premise             = Parameters.Premise;
	DateOfReceipt       = CurrentSessionDate();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CreateRepresentationOfWarehouseSelection();
	
	UpdateSortingList();
	UpdateFormDataServer();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.MPMChoiceForm") Then
		
		Warehouse = ValueSelected;
		CreateRepresentationOfWarehouseSelection();
		ToFormRepresentationOfSelectionRoom();

		UpdateFormData();
		
	EndIf; 
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warerooms.Form.MPMChoiceForm") Then
		
		Premise = ValueSelected;
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

#Region FormTableItemsEventHandlersListOfOrders_

&AtClient
Procedure ListOfOrders_Selection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.ListOfOrders_.CurrentData = Undefined Then
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
	
	CurrentRow = Items.ListOfOrders_.CurrentData;
	
	FillingStructure = GetStructureOfOrderFilling();
	
	If CurrentRow <> Undefined Then
		FillPropertyValues(FillingStructure, CurrentRow);
		FillingStructure.Warehouse           = Warehouse;
		FillingStructure.Premise       = Premise;
		FillingStructure.DateOfReceipt = DateOfReceipt;
		
		FormParameters = New Structure;
		FormParameters.Insert("DocumentType", 1);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("FillingStructure", FillingStructure);
		FormParameters.Insert("DocumentName_1", CurrentRow.DocumentType);
		FormParameters.Insert("Number", CurrentRow.Number);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		LongDesc = New CallbackDescription("UpdateFormData", ThisObject);
		
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Goods",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	EndIf;
	
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
	Filter.Insert("UseWarehouseManagemantSystemForGoodsReceipt", True);
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
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateFormData();
	
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
	
	DateOfReceipt = Undefined;
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure ReceiptStatusFilterOnChange(Item)
	
	CreateRepresentationOfWarehouseSelection();
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure StartAcceptance(Command)
	
	CurrentRow = Items.ListOfOrders_.CurrentData;
	
	GoodsQuantity = GetNumberOfProducts(CurrentRow.ReferenceOrder, CurrentRow.ControlledLotReference);

	If GoodsQuantity = 0 Then
		Status(NStr("vi = 'Không có hàng hóa để nhận';
					|ru = 'Нет товаров для приемки';
					|en = 'There are no goods to receive'; fa = 'There are no goods to receive';
					|it = 'Нет товаров для приемки';
					|pl = 'There are no goods to receive';
					|tr = 'Kabul için ürün mevcut değil'"));
		Return;
	EndIf;
	
	FillingStructure = GetStructureOfOrderFilling(); 	
	FillPropertyValues(FillingStructure, CurrentRow);
	FillingStructure.Warehouse           = Warehouse;
	FillingStructure.Premise       = Premise;
	FillingStructure.DateOfReceipt = DateOfReceipt;
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingStructure", FillingStructure);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ReceiptGoodsOrder",FormParameters,
	ThisObject,,,,,
	FormWindowOpeningMode.Independent);
	
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
	
	ReceiptStatusFilter = "All";
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
Procedure FindByBarcode(Command)
	
	If UsedFormServer = UsedServer.Main Then
		
		LongDesc = New CallbackDescription("DocumentScanResult", ThisObject);
	
		FormParameters = New Structure;
		FormParameters.Insert("FindType", "DocumentSearch");
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise);
		FormParameters.Insert("Context", "Receiving");
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfOrders_ControlledLotReferenceHeader.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfOrders_LotNumber.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfOrders_BatchDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfOrders_DocumentTypeOfLotReference.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfOrders_.ThisIsAcceptanceOfControlledLotReference");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

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
	
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.RequestForOrderForAcceptance(Warehouse, DateOfReceipt, ReceiptStatusFilter);
	Query.Text = StrReplace(Query.Text, "WHERE &ConditionForOrders", "");

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
	
	Items.TeamSelectionsToOpen.Title = PresentationsOfSelections;
	
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
		PresentationsOfSelections = NStr("vi = 'Chọn nhà kho';
										|ru = 'Выбрать помещение';
										|en = 'Select a wareroom'; fa = 'Select a wareroom';
										|it = 'Selezionare magazzino';
										|pl = 'Wybierz pomieszczenie';
										|tr = 'Alan seç'");
		Items.TeamSelectionsOpenRoom.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClearRoom.Visible = False;
		Items.FrameSelectionsOpen1.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	Items.TeamSelectionsOpenRoom.Title = PresentationsOfSelections;
	
EndProcedure

&AtServerNoContext
Function GetStructureOfOrderFilling()
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.StructureOfFillingIncomingOrder();
	
EndFunction

&AtServerNoContext
Function GetNumberOfProducts(ReferenceOrder, ControlledLotReference)
	
	QueryResult = DataProcessors.MobileWarehouseKeeperWorkspace.ListOfGoodsForShipmentAcceptance(
		1,
		ReferenceOrder,
		ControlledLotReference);

	Return QueryResult.Count();
	
EndFunction

&AtServer
Procedure UpdateSortingList()
	
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
	
EndProcedure

&AtClient
Procedure SortOnChange(Item)
	UpdateFormData();
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
			
	Return DataProcessors.MobileWarehouseKeeperWorkspace.DataOfDocumentOnSHK(Barcode, Warehouse, "Receiving");
	
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
		
		FillingStructure = GetStructureOfOrderFilling();
	
		FillPropertyValues(FillingStructure, ReferenceOrder);
		FillingStructure.Warehouse           = Warehouse;
		FillingStructure.Premise       = Premise; 
		
		FormParameters = New Structure;

		FillingStructure.Insert("Sender", ReferenceOrder.Sender);
		FormParameters.Insert("DocumentType", 1);
		
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
	If Item.Name = "sh_ShamsiInput_F_DateOfReceipt" Then
		DateOfReceiptOnChange(Items.DateOfReceipt);
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
