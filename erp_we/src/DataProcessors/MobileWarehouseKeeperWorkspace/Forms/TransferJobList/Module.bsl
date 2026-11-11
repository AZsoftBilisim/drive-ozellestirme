
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Warehouse                 = Parameters.Warehouse;
	Premise             = Parameters.Premise;
	Performer           = Parameters.Performer;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	ScanningProcedure   = Parameters.ScanningProcedure;
	
	UpdateSelectionsAndSorting();
	
#If MobileStandaloneServer Then
	Items.Performer.ChoiceButton = False;
	Items.Confirm.Visible = False;
#EndIf
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateFormData();
	
	CreateRepresentationOfWarehouseSelection();
	ToFormRepresentationOfSelectionRoom();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.MPMChoiceForm") Then
		
		Warehouse = ValueSelected;
		Premise = Undefined;
		CreateRepresentationOfWarehouseSelection();
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

#Region FormTableItemsEventHandlers

&AtClient
Procedure DocumentsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	CurrentRow = Items.DocumentsList.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref", CurrentRow.Ref);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsTransferJob",FormParameters,
	ThisForm,,,,LongDesc,
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
Procedure SelectionsClearWarehouse(Command)
	
	Warehouse       = Undefined;
	Premise   = Undefined;
	
	CreateRepresentationOfWarehouseSelection();
	ToFormRepresentationOfSelectionRoom();
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsCleanRoom(Command)

	Premise   = Undefined;
	ToFormRepresentationOfSelectionRoom();
	UpdateFormData(); 
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	UpdateFormData();
EndProcedure

&AtClient
Procedure PerformerOnChange(Item)
	UpdateFormData();
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	UpdateFormData();
EndProcedure

&AtClient
Procedure CreateMove(Command)
	
	ClearMessages();
	
	If Warehouse.IsEmpty() Then
		Status(NStr("vi = 'Chưa chọn kho vào bộ lọc';
					|ru = 'Не выбран склад в отборе';
					|en = 'The warehouse is not selected in the filter'; fa = 'The warehouse is not selected in the filter';
					|it = 'Не выбран склад в отборе';
					|pl = 'The warehouse is not selected in the filter';
					|tr = 'Filtrede ambar seçilmedi'"));
		Return;
	EndIf;
		
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsTransferJob",FormParameters,
	ThisObject,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure FindByBarcode(Command)
		
	LongDesc = New CallbackDescription("DocumentScanResult", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType", "DocumentSearch");
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Context", "Job_GoodsTransfer");
		
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

#EndRegion

#Region Private

&AtServer
Procedure UpdateFormData()
	
	FillInListOfDocuments();
	
EndProcedure

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateFormData();
	CreateRepresentationOfWarehouseSelection();
	ToFormRepresentationOfSelectionRoom();
	
EndProcedure

&AtServer
Procedure FillInListOfDocuments()
	
	DocumentsList.Clear();
	
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.TransferJobList();
	
	Query.SetParameter("Warehouse", Warehouse);
	
	If ValueIsFilled(Premise) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "AND DocumentGoodsPickingPlacement.Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "");
	EndIf;
	
	If ValueIsFilled(Performer) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionExecutor", "AND DocumentGoodsPickingPlacement.Performer = &Performer");
		Query.SetParameter("Performer", Performer);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionExecutor", "");
	EndIf;
	
	Statuses = New Array;
	If Status = "AllIncomplete" Then 
		Statuses.Add(Enums.StatusesOfGoodsPickingPlacement.Prepared2);
		Statuses.Add(Enums.StatusesOfGoodsPickingPlacement.InProgress);
	ElsIf Status = "All" Then
		For Each Value In Enums.StatusesOfGoodsPickingPlacement Do 
			Statuses.Add(Value);
		EndDo;
	Else
		Statuses.Add(Enums.StatusesOfGoodsPickingPlacement[Status]);
	EndIf;
	Query.SetParameter("Statuses", Statuses);
	
	If ValueIsFilled(BeginOfPeriod) And ValueIsFilled(EndOfPeriod) Then
		Query.Text = Query.Text + "
	|	AND DocumentGoodsPickingPlacement.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod";
		Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
		Query.SetParameter("EndOfPeriod", EndOfPeriod + 60*60*24);
	EndIf;
	
	Query.Text = Query.Text + "
	|ORDER BY
	|	" + Sort;
	
	If SortDirection = "Descending" Then
		Query.Text = Query.Text + " DESC";
	Else
		Query.Text = Query.Text + " ASC";
	EndIf;
	
	DocumentsResult = Query.Execute().Unload();
	
	DocumentsList.Load(DocumentsResult);
	
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
			
	Return DataProcessors.MobileWarehouseKeeperWorkspace.DataOfWarehouseDocumentForSHK(Barcode, "Job_GoodsTransfer");
	
EndFunction

&AtClient
Procedure DocumentScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	If Result.References.Count() Then
			
		LongDesc = New CallbackDescription("UpdateForm", ThisObject);
			
		FormParameters = New Structure;
		FormParameters.Insert("Ref", Result.References[0]);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Barcode", Result.Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsTransferJob", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent);
		
	EndIf;
	
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
	
	If Warehouse["IsFolder"] Then
		UseWarerooms = False;
	Else
		UseWarerooms = Warehouse["UseWarerooms"];
	EndIf;
	Items.GroupTeamSelectionsOpen2.Visible    = UseWarerooms;
	Items.TeamSelectionsClearRoom.Visible = UseWarerooms;
	
	Items.TeamSelectionsToOpen.Title = PresentationsOfSelections;
	
EndProcedure

&AtServer
Procedure ToFormRepresentationOfSelectionRoom()
	
	PresentationsOfSelections = "";
	If ValueIsFilled(Premise) Then
		PresentationsOfSelections = Premise;
		Items.TeamSelectionsOpenRoom.TextColor = WebColors.Black;
		Items.TeamSelectionsClearRoom.Visible = True;
		Items.FrameSelectionsOpen2.Picture = PictureLib.BorderMenuBlack;
	Else
		PresentationsOfSelections = NStr("vi = 'Nhà kho';
										|ru = 'Помещение';
										|en = 'Wareroom'; fa = 'بخش انبار';
										|it = 'Locale';
										|pl = 'Pomieszczenie';
										|tr = 'Alan'");
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
	Items.Status.ChoiceList.Add("AllIncomplete", NStr("vi = 'Tất cả chưa thực hiện';
														|ru = 'Все невыполненные';
														|en = 'All incomplete'; fa = 'همه ناتمام‌ها';
														|it = 'Tutte non completate';
														|pl = 'Wszystkie niewykonane';
														|tr = 'Tüm gerçekleştirilmeyenler'"));
	Items.Status.ChoiceList.Add("Prepared2", NStr("vi = 'Đã soạn';
													|ru = 'Подготовлено';
													|en = 'Prepared'; fa = 'آماده‌شده';
													|it = 'Preparato';
													|pl = 'Przygotowane';
													|tr = 'Hazırlandı'"));
	Items.Status.ChoiceList.Add("InProgress", NStr("vi = 'Đang làm việc';
													|ru = 'В работе';
													|en = 'In progress'; fa = 'در حال انجام';
													|it = 'In esecuzione';
													|pl = 'Wykonuje się';
													|tr = 'İşleniyor'"));
	Items.Status.ChoiceList.Add("CompletedWithoutErrors", NStr("vi = 'Đã thực hiện không có lỗi';
																|ru = 'Выполнено без ошибок';
																|en = 'Fully completed'; fa = 'به‌طور کامل تکمیل شد';
																|it = 'Eseguito senza errori';
																|pl = 'Wykonano bez błędów';
																|tr = 'Hatasız tamamlandı'"));
	Items.Status.ChoiceList.Add("DoneWithErrors", NStr("vi = 'Đã thực hiện bị lỗi';
														|ru = 'Выполнено с ошибками';
														|en = 'Partially completed'; fa = 'تکمیل جزئی';
														|it = 'Completato con errori';
														|pl = 'Wykonano z błędami';
														|tr = 'Hatalarla tamamlandı'"));
	
	Status = "AllIncomplete";

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
Procedure SelectPeriod(Command)
	
	Notification = New CallbackDescription(
		"SelectPeriodCompletion",
		ThisObject);
		
	MobileWarehouseKeeperWorkspaceClient.EditPeriod(
		ThisObject,
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"),
		Notification);
	
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
