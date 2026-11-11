
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	Warehouse                 = Parameters.Warehouse;
	Premise             = Parameters.Premise;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	Mode             	  = Parameters.Mode;
	User          = Parameters.Performer;
	ScanningProcedure   = Parameters.ScanningProcedure;
	
	GoodsIssueNoteGenerationMode = Constants.GoodsIssueNoteGenerationMode.Get();
	
	If Mode = "NotesToFilter" 
		And GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.ByWarehouseman Then
		Performer = Parameters.Performer;
		Items.MenuGroup_2.Visible = False;
		Items.AssignMe.Visible = False;
		Items.ToBegin.Visible = False;
	ElsIf Mode = "NotesToFilter"
		And GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.Automatically Then
		Mode = "OrdersToBeSelectedAutomatically";
	ElsIf Mode = "NotesToCheck" Then
		CheckOnlyYourNotes = DataProcessors.MobileWarehouseKeeperWorkspace.HaveRightToCheckYourOrders()
			And Not DataProcessors.MobileWarehouseKeeperWorkspace.ThereIsRightToCheckOtherPeopleSOrders();
		CheckOnlyOtherNotes = DataProcessors.MobileWarehouseKeeperWorkspace.ThereIsRightToCheckOtherPeopleSOrders()
			And Not DataProcessors.MobileWarehouseKeeperWorkspace.HaveRightToCheckYourOrders();
	EndIf;
	
	CreateSelectionView();
	UpdateSelectionsAndSorting();
	
	FillInOrderLists();
	CustomizeForm();

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OpenPage("FreeOrdersPage");
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.MPMChoiceForm") Then
		
		Warehouse = ValueSelected;
		Premise = Undefined;
		CreateSelectionView();
		UpdateFormData();
		
	EndIf;
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warerooms.Form.MPMChoiceForm") Then
		
		Premise = ValueSelected;
		ToFormRepresentationOfSelectionRoom();
		UpdateFormData();
		
	EndIf;
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Users.Form.ListForm") Then
		
		Performer = ValueSelected;
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
Procedure PerformerChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	ClearMessages();
	
	If CheckOnlyOtherNotes And ValueSelected = User Then
		ErrorText = NStr("vi = 'Người sử dụng hiện tại chỉ có thể kiểm tra các phiếu khác.';
						|ru = 'Текущий пользователь может проверять только чужие ордера.';
						|en = 'The current user can only check other notes.'; fa = 'The current user can only check other notes.';
						|it = 'The current user can only check other notes.';
						|pl = 'The current user can only check other notes.';
						|tr = 'Mevcut kullanıcı sadece diğer kişilerin siparişlerini kontrol edebilir.'");
		Status(ErrorText);
		Return;
	EndIf;
	
	Performer = ValueSelected;
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure InspectorOnChange(Item) 
	
	UpdateFormData();

EndProcedure

&AtClient
Procedure ShippedByOnChange(Item)
	
	UpdateFormData();

EndProcedure

&AtClient
Procedure StatusOnChange(Item) 
	
	UpdateFormData();
	
	If Not (Mode = "NotesToShip" And Status = "Verified") Then 
		Items.ToBegin.Visible = False;
		Items.AssignMe.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SortOnChange(Item)
	
	UpdateFormData();
	
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

&AtClient
Procedure PerformerStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure("ChoiceMode", True);
	
	If CheckOnlyOtherNotes Then
		
		ListUsers = New ValueList;
		ListUsers.Add(User);
		OpeningParameters.Insert("UsersToHide", ListUsers);
		
	EndIf;
	
	OpenForm("Catalog.Users.Form.ListForm", OpeningParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfOrdersIsFree

&AtClient
Procedure ListOfOrdersIsFreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.ListOfOrdersIsFree.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure; 
	FormParameters.Insert("Ref", CurrentRow.Ref);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	LongDesc = New CallbackDescription("UpdateFormData", ThisObject);
		
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ExpenseOrder",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfOrdersIsMine

&AtClient
Procedure ListOfOrdersIsMineSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.ListOfOrdersIsMine.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	LongDesc = New CallbackDescription("UpdateFormData", ThisObject);

	If Mode = "OrdersToBeSelectedAutomatically"
		And UseBinLocationWarehousing Then
				
		If UseWarerooms And Not ValueIsFilled(Premise) Then
			Status(NStr("vi = 'Hãy chỉ định vị trí khi lấy hàng';
						|ru = 'Укажите помещение в отборе';
						|en = 'Specify the wareroom for picking'; fa = 'Specify the wareroom for picking';
						|it = 'Specify the wareroom for picking';
						|pl = 'Specify the wareroom for picking';
						|tr = 'Filtrede alan belirtin'"));
			Return;
		EndIf;
				
		FillingStructure = New Structure;
		FillingStructure.Insert("Warehouse", Warehouse);
		FillingStructure.Insert("Premise", Premise);
		FillingStructure.Insert("ReferenceOrder", CurrentRow.Ref);
		FillingStructure.Insert("Recipient", CurrentRow.Recipient);
				
		FormParameters = New Structure;
		FormParameters.Insert("DocumentType", 3);
	
		FormParameters.Insert("FillingStructure", FillingStructure);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
			
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Goods", FormParameters,
			ThisObject,,,,LongDesc,
			FormWindowOpeningMode.Independent); 
	Else
	
		FormParameters = New Structure;
		FormParameters.Insert("Ref", CurrentRow.Ref);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
			
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ExpenseOrder", FormParameters,
			ThisObject,,,,LongDesc,
			FormWindowOpeningMode.Independent);
			
	EndIf;

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
	Filter.Insert("UseWarehouseManagemantSystemForGoodsIssue", True);
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
	
EndProcedure 

&AtClient
Procedure SelectionsClearWarehouse(Command)
	
	Warehouse = Undefined;
	Premise = Undefined;
	CreateSelectionView();
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
Procedure SelectionsClearController(Command)
	
	Inspector = Undefined;
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsClearShipped(Command)
	
	ShippedBy = Undefined;
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsClearStatus(Command)
	
	Status = "All";
	
	Items.ToBegin.Visible = False;
	Items.AssignMe.Visible = False; 
	
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
Procedure GoToFreeSection(Command)
	
	OpenPage("FreeOrdersPage");

EndProcedure

&AtClient
Procedure GoToMySection(Command)

	OpenPage("MyOrdersPage");

EndProcedure

&AtClient
Procedure ToBegin(Command)
	
	ClearMessages();
	
	CurrentRow = Items.ListOfOrdersIsFree.CurrentData;
	
	If Not AssignMeAtServer(CurrentRow.Ref) Then
		Return;
	EndIf;
	
	LongDesc = New CallbackDescription("UpdateFormData", ThisObject);
	CurrentRow = Items.ListOfOrdersIsFree.CurrentData;
	
	If Mode = "OrdersToBeSelectedAutomatically"
		And UseBinLocationWarehousing Then 
		
		If UseWarerooms And Not ValueIsFilled(Premise) Then
			Status(NStr("vi = 'Hãy chỉ định vị trí khi lấy hàng';
						|ru = 'Укажите помещение в отборе';
						|en = 'Specify the wareroom for picking'; fa = 'Specify the wareroom for picking';
						|it = 'Specify the wareroom for picking';
						|pl = 'Specify the wareroom for picking';
						|tr = 'Filtrede alan belirtin'"));
			Return;
		EndIf; 
		
		FillingStructure = New Structure;
		FillingStructure.Insert("Warehouse", Warehouse);
		FillingStructure.Insert("Premise", Premise);
		FillingStructure.Insert("ReferenceOrder", CurrentRow.Ref);
		FillingStructure.Insert("Recipient", CurrentRow.Recipient);
			
		FormParameters = New Structure;
		FormParameters.Insert("DocumentType", 3);

		FormParameters.Insert("FillingStructure", FillingStructure);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Goods", FormParameters,
			ThisObject,,,,LongDesc,
			FormWindowOpeningMode.Independent); 
	Else
		FormParameters = New Structure;
		FormParameters.Insert("Ref", CurrentRow.Ref);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ExpenseOrder", FormParameters,
			ThisObject,,,,LongDesc,
			FormWindowOpeningMode.Independent);
	EndIf;

EndProcedure

&AtClient
Procedure CompleteShipment(Command)  
	
	CurrentRow = Items.ListOfOrdersIsMine.CurrentData;
	CompleteShipmentATServer(CurrentRow.Ref);
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure AssignMe(Command)  
		
	CurrentRow = Items.ListOfOrdersIsFree.CurrentData;
	AssignMeAtServer(CurrentRow.Ref);
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure RemoveFromMe(Command)

	CurrentRow = Items.ListOfOrdersIsMine.CurrentData;
	TakeOffFromMeATServer(CurrentRow.Ref);
	
	UpdateFormData();
			
EndProcedure

&AtClient
Procedure FindByBarcode(Command)
			
	LongDesc = New CallbackDescription("DocumentScanResult", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType", "DocumentSearch");
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Context", "ExpenseOrder");
		
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
Procedure CustomizeForm()
	
	Items.MenuGroup_2.Visible = Not (UseGoodsIssueNoteStatuses And Mode = "NotesToFilter");
	
	If Mode = "NotesToFilter" Then
		TitleText = NStr("vi = 'Phiếu xuất kho cần lấy hàng';
						|ru = 'Расходные ордера к отбору';
						|en = 'Goods issues to pick'; fa = 'Goods issues to pick';
						|it = 'Goods issues to pick';
						|pl = 'Goods issues to pick';
						|tr = 'Filtre için gider siparişleri'");
		Items.ToBegin.Title = NStr("vi = 'Bắt đầu lấy hàng';
									|ru = 'Начать отбор';
									|en = 'Start picking'; fa = 'Start picking';
									|it = 'Start picking';
									|pl = 'Start picking';
									|tr = 'Filtrelemeye başla'");
	ElsIf Mode = "OrdersToBeSelectedAutomatically" Then
		TitleText = NStr("vi = 'Phiếu xuất kho cần lấy hàng';
						|ru = 'Расходные ордера к отбору';
						|en = 'Goods issues to pick'; fa = 'Goods issues to pick';
						|it = 'Goods issues to pick';
						|pl = 'Goods issues to pick';
						|tr = 'Filtre için gider siparişleri'");
		Items.ListOfOrdersIsMineInspector.Visible = False;
		Items.ToBegin.Title = NStr("vi = 'Bắt đầu lấy hàng';
									|ru = 'Начать отбор';
									|en = 'Start picking'; fa = 'Start picking';
									|it = 'Start picking';
									|pl = 'Start picking';
									|tr = 'Filtrelemeye başla'");
	ElsIf Mode = "NotesToCheck" Then 
		TitleText = NStr("vi = 'Phiếu xuất kho cần kiểm tra';
						|ru = 'Расходные ордера к проверке';
						|en = 'Goods issues to check'; fa = 'Goods issues to check';
						|it = 'Goods issues to check';
						|pl = 'Goods issues to check';
						|tr = 'Kontrol için gider siparişleri'");
		Items.ToBegin.Title = NStr("vi = 'Bắt đầu kiểm tra';
									|ru = 'Начать проверку';
									|en = 'Check start'; fa = 'Check start';
									|it = 'Check start';
									|pl = 'Check start';
									|tr = 'Kontrole başla'");
		Items.ListOfOrdersIsMineInspector.Visible = False;
	ElsIf Mode = "NotesToShip" Then
		TitleText = NStr("vi = 'Phiếu xuất kho cần giao hàng';
						|ru = 'Расходные ордера к отгрузке';
						|en = 'Goods issues to ship'; fa = 'Goods issues to ship';
						|it = 'Goods issues to ship';
						|pl = 'Goods issues to ship';
						|tr = 'Sevkiyat için gider siparişleri'");
		Items.ToBegin.Title = NStr("vi = 'Bắt đầu xuất hàng';
									|ru = 'Начать отгрузку';
									|en = 'Start shipment'; fa = 'شروع ارسال';
									|it = 'Avviare spedizione';
									|pl = 'Rozpocznij wysyłkę';
									|tr = 'Sevkiyatı başlat'");
		Items.ListOfOrdersIsMineEmployeeResponsible.Visible = False;
		Items.SelectionsController.Visible = UseGoodsIssueNoteStatuses;
		Items.SelectionsShipped.Visible = UseGoodsIssueNoteStatuses;
		Items.SelectionsStatus.Visible = UseGoodsIssueNoteStatuses;
	EndIf;
	Title = TitleText;

#If MobileStandaloneServer Then
	If Mode = "OrdersToBeSelectedAutomatically"
		And UseBinLocationWarehousing Then
		Items.ToBegin.Visible = False;
	EndIf;
	
	Items.Performer.ChoiceButton = False;
	Items.Inspector.ChoiceButton = False;
	Items.ShippedBy.ChoiceButton = False;
#EndIf

EndProcedure

&AtClient
Procedure UpdateFormData(Result = Undefined, AdditionalParameters = Undefined) Export
	
	FillInOrderLists();
	
EndProcedure

&AtServer
Procedure FillInOrderLists()
	
	If ValueIsFilled(Warehouse) And Not UseGoodsIssueNoteStatuses Then
		FillInListOfOrdersWithoutStatuses();
		Return;
	EndIf;
		
	ListOfOrdersIsFree.Clear();
	ListOfOrdersIsMine.Clear();
	
	RequestFree = DataProcessors.MobileWarehouseKeeperWorkspace.RequestListOfSpendingOrders();
	RequestMy = DataProcessors.MobileWarehouseKeeperWorkspace.RequestListOfSpendingOrders();
	
	RequestFree = GenerateRequest(RequestFree, True);
	RequestMy = GenerateRequest(RequestMy, False);
	
	ListOfOrdersIsFree.Load(RequestFree.Execute().Unload());
	If Not Mode = "NotesToFilter" Then
		ListOfOrdersIsMine.Load(RequestMy.Execute().Unload());
	EndIf;

	GenerateMenuCommandHeaders();

EndProcedure  

&AtServer
Procedure FillInListOfOrdersWithoutStatuses()
	
	Items.GroupPages.CurrentPage = Items.OrderListGroupIsFree;

	ListOfOrdersIsFree.Clear();
	ListOfOrdersIsMine.Clear();
	
	RequestFree = DataProcessors.MobileWarehouseKeeperWorkspace.RequestListOfSpendingOrders();
	RequestMy = DataProcessors.MobileWarehouseKeeperWorkspace.RequestListOfSpendingOrders();
	
	RequestFree = GenerateRequestWithoutStatuses(RequestFree, True);
	RequestMy = GenerateRequestWithoutStatuses(RequestMy, False);
	
	ListOfOrdersIsFree.Load(RequestFree.Execute().Unload());
	ListOfOrdersIsMine.Load(RequestMy.Execute().Unload());

	GenerateMenuCommandHeaders();

EndProcedure

&AtServer
Function GenerateRequest(Query, ListIsFree = True)
	
	Query.SetParameter("Warehouse", Warehouse);
	
	ArrayOfConditions = New Array;
	
	If ValueIsFilled(Premise) Then
		ArrayOfConditions.Add("GoodsIssueNote.Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	EndIf;
	
	If ValueIsFilled(BeginOfPeriod) And ValueIsFilled(EndOfPeriod) Then
		ArrayOfConditions.Add("GoodsIssueNote.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod");
		Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
		Query.SetParameter("EndOfPeriod", EndOfDay(EndOfPeriod));
	EndIf;
	
	UseStatuses = UseGoodsIssueNoteStatuses Or Mode = "NotesToShip";
	If UseStatuses And ValueIsFilled(Status) And ListIsFree Then
		If Status = "AllUnshipped" Then
			ArrayOfConditions.Add("GoodsIssueNote.Status <> VALUE(Enum.GoodsIssueNoteStatuses.Shipped_)");
		ElsIf Not Status = "All" Then
			ArrayOfConditions.Add("GoodsIssueNote.Status = &Status");
			Query.SetParameter("Status", Enums.GoodsIssueNoteStatuses[Status]);
		EndIf; 
	Else
		ArrayOfConditions.Add("GoodsIssueNote.Status = &Status");
	EndIf;
	
	StatusFree = Undefined;
	MyStatus = Undefined;
	
	If Mode = "NotesToFilter" Then
		StatusFree = Enums.GoodsIssueNoteStatuses.ForPicking;
	ElsIf Mode = "OrdersToBeSelectedAutomatically" Then
		StatusFree = Enums.GoodsIssueNoteStatuses.Prepared;
		MyStatus = Enums.GoodsIssueNoteStatuses.ForPicking;
	ElsIf Mode = "NotesToCheck" Then
		StatusFree = Enums.GoodsIssueNoteStatuses.ForChecking;
		MyStatus = Enums.GoodsIssueNoteStatuses.DuringChecking;
	ElsIf Mode = "NotesToShip" Then
		MyStatus = Enums.GoodsIssueNoteStatuses.ToShip;
		If Not ValueIsFilled(Status) Then
			StatusFree = Enums.GoodsIssueNoteStatuses.Verified;
			Status = "Verified";
		EndIf;
	EndIf; 
	
	If ListIsFree Then
		Query.SetParameter("ResponsibleTitle", NStr("vi = 'Người thực hiện';
													|ru = 'Исполнитель';
													|en = 'Assignee'; fa = 'Assignee';
													|it = 'Assignee';
													|pl = 'Assignee';
													|tr = 'İcracı'"));
		
		If Mode = "NotesToCheck" Then
			If ValueIsFilled(Performer) Then
				ArrayOfConditions.Add("GoodsIssueNote.EmployeeResponsible = &EmployeeResponsible");
				Query.SetParameter("EmployeeResponsible", Performer);
				
			ElsIf CheckOnlyOtherNotes Then
				ArrayOfConditions.Add("GoodsIssueNote.EmployeeResponsible <> &EmployeeResponsible");
				Query.SetParameter("EmployeeResponsible", User);
			EndIf;
			
			If CheckOnlyYourNotes Then
				ArrayOfConditions.Add("GoodsIssueNote.EmployeeResponsible = &EmployeeResponsible");
				Query.SetParameter("EmployeeResponsible", User);
			EndIf; 
		ElsIf ValueIsFilled(Performer) Then
			ArrayOfConditions.Add("GoodsIssueNote.EmployeeResponsible = &EmployeeResponsible");
			Query.SetParameter("EmployeeResponsible", Performer);
		EndIf;
		
		If ValueIsFilled(Inspector) Then
			ArrayOfConditions.Add("GoodsIssueNote.Inspector = &Inspector");
			Query.SetParameter("Inspector", Inspector);
		EndIf;
		
		If ValueIsFilled(ShippedBy) Then
			ArrayOfConditions.Add("GoodsIssueNote.ShippedBy = &ShippedBy");
			Query.SetParameter("ShippedBy", ShippedBy);
		EndIf;
		
		If StatusFree <> Undefined Then
			Query.SetParameter("Status", StatusFree);
		EndIf;
	Else
		If Mode = "OrdersToBeSelectedAutomatically" Then
			ArrayOfConditions.Add("GoodsIssueNote.EmployeeResponsible = &EmployeeResponsible");
			Query.SetParameter("ResponsibleTitle", NStr("vi = 'Người thực hiện';
														|ru = 'Исполнитель';
														|en = 'Assignee'; fa = 'Assignee';
														|it = 'Assignee';
														|pl = 'Assignee';
														|tr = 'İcracı'"));
			Query.SetParameter("EmployeeResponsible", User);  
			
		ElsIf Mode = "NotesToCheck" Then 
			ArrayOfConditions.Add("GoodsIssueNote.Inspector = &Inspector");
			Query.SetParameter("ResponsibleTitle", NStr("vi = 'Người thực hiện';
														|ru = 'Исполнитель';
														|en = 'Assignee'; fa = 'Assignee';
														|it = 'Assignee';
														|pl = 'Assignee';
														|tr = 'İcracı'"));
			Query.SetParameter("Inspector", User);
			
		ElsIf Mode = "NotesToShip" Then 
			ArrayOfConditions.Add("GoodsIssueNote.ShippedBy = &ShippedBy");
			Query.SetParameter("ResponsibleTitle", NStr("vi = 'Người kiểm soát';
														|ru = 'Контролер';
														|en = 'Inspector'; fa = 'بازرس';
														|it = 'Inspector';
														|pl = 'Inspector';
														|tr = 'Denetleyici'"));
			Query.SetParameter("ShippedBy", User); 
			
		EndIf;
		Query.SetParameter("Status", MyStatus);
	EndIf;
	
	If ArrayOfConditions.Count() > 0 Then
		Query.Text = Query.Text + "
			|	AND " + StrConcat(ArrayOfConditions, "
			|	AND ");
	EndIf;
	
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

	Return Query;
	
EndFunction

&AtServer
Function GenerateRequestWithoutStatuses(Query, ListIsFree = True)
	
	Query.SetParameter("Warehouse", Warehouse);
	
	ArrayOfConditions = New Array;
	ArrayOfConditions.Add("GoodsIssueNote.Status = &Status");
	
	If ValueIsFilled(Premise) Then
		ArrayOfConditions.Add("GoodsIssueNote.Premise = &Premise");
		Query.SetParameter("Premise", Premise);	
	EndIf;
	
	If ValueIsFilled(BeginOfPeriod) And ValueIsFilled(EndOfPeriod) Then
		ArrayOfConditions.Add("GoodsIssueNote.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod");
		Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
		Query.SetParameter("EndOfPeriod", EndOfDay(EndOfPeriod));
	EndIf;
		
	MyStatus = Enums.GoodsIssueNoteStatuses.Shipped_;
	StatusFree = Enums.GoodsIssueNoteStatuses.Shipped_;
	
	Query.SetParameter("ResponsibleTitle", NStr("vi = 'Người thực hiện';
												|ru = 'Исполнитель';
												|en = 'Assignee'; fa = 'Assignee';
												|it = 'Assignee';
												|pl = 'Assignee';
												|tr = 'İcracı'"));

	If ListIsFree Then
		If ValueIsFilled(Performer) Then
			ArrayOfConditions.Add("GoodsIssueNote.EmployeeResponsible = &EmployeeResponsible");
			Query.SetParameter("EmployeeResponsible", Performer);
		EndIf;
		Query.SetParameter("Status", StatusFree);
	Else
		ArrayOfConditions.Add("GoodsIssueNote.EmployeeResponsible = &EmployeeResponsible");
		Query.SetParameter("EmployeeResponsible", User);
		Query.SetParameter("Status", MyStatus);
	EndIf;
	
	If ArrayOfConditions.Count() > 0 Then
		Query.Text = Query.Text + "
			|	AND " + StrConcat(ArrayOfConditions, "
			|	AND ");
	EndIf;
	
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

	Return Query;
	
EndFunction

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
			
	Return DataProcessors.MobileWarehouseKeeperWorkspace.DataOfWarehouseDocumentForSHK(Barcode, "ExpenseOrder");

EndFunction

&AtClient
Procedure DocumentScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	If Result.References.Count() Then
			
		FormParameters = New Structure; 
		FormParameters.Insert("Ref", Result.References[0]);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Barcode", Result.Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		LongDesc = New CallbackDescription("UpdateFormData", ThisObject);
			
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ExpenseOrder", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenPage(TabName)
	
	Items.FrameFree.Picture = PictureLib.BorderMenuWhite;
	Items.CommandFreeOrders.TextColor = WebColors.DarkGray;
	
	Items.FrameIsMine.Picture = PictureLib.BorderMenuWhite;
	Items.MyOrdersCommand.TextColor = WebColors.DarkGray;
	
	If TabName = "FreeOrdersPage" Then 
		Items.CommandFreeOrders.TextColor = WebColors.Black;
		Items.FrameFree.Picture = PictureLib.BorderMenuBlack;
		Items.GroupPages.CurrentPage = Items.OrderListGroupIsFree;
		Items.SelectionsPerformer.Visible = True;
		Items.SelectionsStatus.Visible = False;
		If Mode = "NotesToCheck" Then
			Items.SelectionsPerformer.Visible = Not CheckOnlyYourNotes;
		ElsIf Mode = "NotesToShip" Then
			Items.SelectionsController.Visible = UseGoodsIssueNoteStatuses;
			Items.SelectionsShipped.Visible = UseGoodsIssueNoteStatuses;
			Items.SelectionsStatus.Visible = UseGoodsIssueNoteStatuses;
		EndIf;
	ElsIf TabName = "MyOrdersPage" Then
		Items.MyOrdersCommand.TextColor = WebColors.Black;
		Items.FrameIsMine.Picture   = PictureLib.BorderMenuBlack;
		Items.GroupPages.CurrentPage = Items.MyOrdersListGroup;
		If Mode = "NotesToShip" Then
			Items.CompleteShipment.Visible = True;
		EndIf;
		Items.SelectionsStatus.Visible = False;
		Items.SelectionsPerformer.Visible = False;
		Items.SelectionsController.Visible = False;
		Items.SelectionsShipped.Visible = False;
	EndIf;
			
EndProcedure

&AtServer
Procedure CreateSelectionView()
	
	CreateRepresentationOfWarehouseSelection();
	ToFormRepresentationOfSelectionRoom();
	
EndProcedure

&AtServer
Procedure CreateRepresentationOfWarehouseSelection()
	
	UseWarerooms = False;
	UseGoodsIssueNoteStatuses = False;
	UseBinLocationWarehousing = False;
	
	PresentationsOfSelections = "";
	If ValueIsFilled(Warehouse) Then
		PresentationsOfSelections = Warehouse;
		Items.TeamSelectionsToOpen.TextColor = WebColors.Black;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuBlack;
		
		WarehouseProperties = DataProcessors.MobileWarehouseKeeperWorkspace.WarehouseProperties(Warehouse);
		If ValueIsFilled(WarehouseProperties) Then
			UseGoodsIssueNoteStatuses = WarehouseProperties.UseGoodsIssueNoteStatuses;
			UseWarerooms = WarehouseProperties.UseWarerooms; 
			UseBinLocationWarehousing = WarehouseProperties.UseBinLocationWarehousing;
		EndIf;
		Items.TeamSelectionsClear.Visible = True;
	Else
		PresentationsOfSelections = NStr("vi = 'Kho bãi';
										|ru = 'Склад';
										|en = 'Warehouse'; fa = 'Warehouse';
										|it = 'Magazzino';
										|pl = 'Magazyn';
										|tr = 'Ambar'");
		Items.TeamSelectionsToOpen.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClear.Visible = False;
		Items.MenuGroup_2.Visible = False;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	Items.GroupSelectionsRoom.Visible = UseWarerooms;
	Items.TeamSelectionsToOpen.Title = PresentationsOfSelections;
	
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure ToFormRepresentationOfSelectionRoom()
	
	PresentationsOfSelections = "";
	If ValueIsFilled(Premise) Then
		PresentationsOfSelections = Premise;
		Items.TeamSelectionsOpenRoom.TextColor = WebColors.Black;
		Items.TeamSelectionsClearRoom.Visible = True;
		Items.FrameSelectionsOpen2.Picture = PictureLib.BorderMenuBlack; 
		
		UseBinLocationWarehousing = Premise["UseBinLocationWarehousing"];

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
	
	Items.Performer.ChoiceList.Clear();
	If CheckOnlyOtherNotes Then
		UsersList = New ValueList;
		UsersList.Add(User);
	EndIf;
	Items.Performer.ChoiceList.LoadValues(DataProcessors.MobileWarehouseKeeperWorkspace.GetListOfUsers(UsersList));
		
	If Not Mode = "NotesToCheck" 
		Or (Mode = "NotesToCheck" And Not CheckOnlyOtherNotes) Then
		Items.Performer.ChoiceList.Insert(0, User, NStr("vi = '<Chứng từ của tôi>';
														|ru = '<Мои документы>';
														|en = '<My documents>'; fa = '<My documents>';
														|it = '<i miei documenti>';
														|pl = '<Моje dokumenty>';
														|tr = '<Belgelerim>'"));
	EndIf;
	
	If Mode = "NotesToShip" Then
		Items.Inspector.ChoiceList.Clear();
		Items.ShippedBy.ChoiceList.Clear();
		
		ChoiceList = DataProcessors.MobileWarehouseKeeperWorkspace.GetListOfUsers();
		Items.Inspector.ChoiceList.LoadValues(ChoiceList);
		Items.ShippedBy.ChoiceList.LoadValues(ChoiceList);
	EndIf;
	
	Sort = "Date";
	
	Items.ChangeSortingDirection.Picture = PictureLib.SortRowsAsc;
	SortDirection = "Ascending";
	
EndProcedure

&AtClient
Procedure SelectPeriodCompletion(Period, AdditionalParameters) Export
	
	If Period <> Undefined Then
		PeriodForChangesOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure PeriodForChangesOnServer()
	
	FillInOrderLists();
	
EndProcedure

&AtServer
Procedure GenerateMenuCommandHeaders()
	
	Items.CommandFreeOrders.Title = StrTemplate(NStr("vi = 'Tự do (%1)';
													|ru = 'Свободные (%1)';
													|en = 'Free (%1)'; fa = 'Free (%1)';
													|it = 'Liberi (%1)';
													|pl = 'Wolne (%1)';
													|tr = 'Boş (%1)'"), ListOfOrdersIsFree.Count());
	Items.MyOrdersCommand.Title = StrTemplate(NStr("vi = 'Của tôi (%1)';
													|ru = 'Мои (%1)';
													|en = 'My (%1)'; fa = 'My (%1)';
													|it = 'Mio (%1)';
													|pl = 'Moje (%1)';
													|tr = 'Benim (%1)'"), ListOfOrdersIsMine.Count());
	
EndProcedure

&AtServer
Function AssignMeAtServer(Val ExpenseOrder)
	
	If Mode = "OrdersToBeSelectedAutomatically" Then
		NoteStatus = Enums.GoodsIssueNoteStatuses.ForPicking;
	ElsIf Mode = "NotesToCheck" Then
		NoteStatus = Enums.GoodsIssueNoteStatuses.DuringChecking;
	ElsIf Mode = "NotesToShip" Then
		NoteStatus = Enums.GoodsIssueNoteStatuses.ToShip;
	EndIf;
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.SetStatusOfOrder(ExpenseOrder, NoteStatus);
	
EndFunction

&AtServerNoContext
Procedure CompleteShipmentATServer(ExpenseOrder)

	NoteStatus = Enums.GoodsIssueNoteStatuses.Shipped_;
	DataProcessors.MobileWarehouseKeeperWorkspace.SetStatusOfOrder(ExpenseOrder, NoteStatus);
	
EndProcedure 

&AtServer
Procedure TakeOffFromMeATServer(Val ExpenseOrder)

	If Mode = "OrdersToBeSelectedAutomatically" Then
		NoteStatus = Enums.GoodsIssueNoteStatuses.Prepared;
	ElsIf Mode = "NotesToCheck" Then
		NoteStatus = Enums.GoodsIssueNoteStatuses.ForChecking;
	ElsIf Mode = "NotesToShip" Then
		NoteStatus = Enums.GoodsIssueNoteStatuses.Verified;
	EndIf; 
	
	DataProcessors.MobileWarehouseKeeperWorkspace.SetStatusOfOrder(ExpenseOrder, NoteStatus);
	
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
