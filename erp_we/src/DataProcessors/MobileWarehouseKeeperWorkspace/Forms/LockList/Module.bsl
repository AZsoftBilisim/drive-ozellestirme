
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Warehouse     = Parameters.Warehouse;
	Premise = Parameters.Premise;
	
	UpdateFormData();

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CreateMenu_("Blocked");
	
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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToBlockedSection(Command)
	CreateMenu_("Blocked");
EndProcedure

&AtClient
Procedure GoToAllCellsSection(Command)
	CreateMenu_("AllCells");
EndProcedure

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
		ThisForm,,,,,
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
		ThisForm,,,,,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure
	
&AtClient
Procedure SelectionsClearWarehouse(Command)
	
	Warehouse = Undefined;
	CreateRepresentationOfWarehouseSelection();
	ToFormRepresentationOfSelectionRoom();
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure SelectionsCleanRoom(Command)

	Premise = Undefined;
	ToFormRepresentationOfSelectionRoom();
	UpdateFormData(); 
	
EndProcedure

&AtClient
Procedure BlockedBinsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("Cell", Items.BlockedBins.CurrentData.Cell);
	FormParameters.Insert("LockType", Items.BlockedBins.CurrentData.LockType);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.StorageBinLock",FormParameters,
	ThisForm,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CreateMenu_(TabName)
	
	Items.FrameLocked.Picture = PictureLib.BorderMenuWhite;
	Items.BlockedTeam.TextColor = WebColors.DarkGray;
	
	Items.FrameAllCells.Picture = PictureLib.BorderMenuWhite;
	Items.AllCellsCommand.TextColor = WebColors.DarkGray;
	
	If TabName = "Blocked" Then
		
		Items.BlockedTeam.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.PageBlocked;
		Items.FrameLocked.Picture = PictureLib.BorderMenuBlack;
		
	ElsIf TabName = "AllCells" Then
		
		Items.AllCellsCommand.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.AllCellsPage;
		Items.FrameAllCells.Picture = PictureLib.BorderMenuBlack;
		
	EndIf;
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtServer
Procedure GenerateMenuCommandHeaders()
	Items.BlockedTeam.Title = StrTemplate(NStr("vi = 'Đã phong tỏa (%1)';
												|ru = 'Заблокированные (%1)';
												|en = 'Blocked (%1)'; fa = 'Blocked (%1)';
												|it = 'Bloccati (%1)';
												|pl = 'Zablokokwane (%1)';
												|tr = 'Kilitli olanlar (%1)'"), BlockedBins.Count());
	Items.AllCellsCommand.Title = StrTemplate(NStr("vi = 'Tất cả ô hàng';
													|ru = 'Все ячейки';
													|en = 'All storage bins'; fa = 'همه محل‌های نگهداری';
													|it = 'Tutte le celle';
													|pl = 'Wszystkie komórki';
													|tr = 'Tüm hücreler'"));
EndProcedure

&AtServer
Procedure UpdateFormData()
	
	FillInListOfBlockedCells();
	
	Cells.Filter.Items.Clear();
	
	FilterElement = Cells.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("Owner");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.Use = True;
	FilterElement.RightValue = Warehouse;
	
	FilterElement = Cells.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("Premise");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.Use = True;
	FilterElement.RightValue = Premise;
	
EndProcedure

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateFormOnServer(Result);
	
EndProcedure

&AtServer
Procedure UpdateFormOnServer(Result = Undefined)
	
	UpdateFormData();
	CreateRepresentationOfWarehouseSelection();
	ToFormRepresentationOfSelectionRoom();
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtServer
Procedure FillInListOfBlockedCells()
	
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.LockList();
	
	If Not Premise.IsEmpty() Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "AND StorageBinsLocks.Cell.Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "");
	EndIf;

	Query.SetParameter("Warehouse", Warehouse);
	
	TableOfLocks = Query.Execute().Unload();
	
	BlockedBins.Load(TableOfLocks);
	
	GenerateMenuCommandHeaders();

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
	
	If Warehouse["IsFolder"] = True Then
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

&AtClient
Procedure Scan(Command)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("CellSearchResult", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType", "CellSearch");
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning",FormParameters,
	ThisForm,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure CellSearchResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("Cell", Result);
	FormParameters.Insert("LockType", Undefined);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.StorageBinLock",FormParameters,
	ThisForm,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure CellsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("Cell", Item.CurrentRow);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.StorageBinLock",FormParameters,
	ThisForm,,,,LongDesc,
	FormWindowOpeningMode.Independent);

EndProcedure

#EndRegion
