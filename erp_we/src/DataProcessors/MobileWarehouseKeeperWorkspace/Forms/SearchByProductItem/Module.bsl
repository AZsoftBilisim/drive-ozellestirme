 #Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Products          = Parameters.Products;
	SKU               = Common.ObjectAttributeValue(Products, "SKU");
	Warehouse                 = Parameters.Warehouse;
	Premise             = Parameters.Premise;
	Series                 = Parameters.Series;
	Characteristic        = Parameters.Characteristic;
	ShowProductPhotos = Parameters.ShowProductPhotos;

	FillBalance();
	
	CreateRepresentationOfWarehouseSelection();
	ToFormRepresentationOfSelectionRoom();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.ChoiceForm") Then
		
		Warehouse = ValueSelected;
		CreateRepresentationOfWarehouseSelection();
		FillBalance();
		
	EndIf;
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warerooms.Form.ChoiceForm") Then
		
		Premise = ValueSelected;
		ToFormRepresentationOfSelectionRoom();
		FillBalance();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrdersList

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.Count);
	FormParameters.Insert("Mode", "View");
	FormParameters.Insert("LineNumber", Item.CurrentRow);
	FormParameters.Insert("Warehouse", Item.CurrentData.Warehouse);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", SKU);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisForm,,,,,
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
	"Catalog.Warehouses.Form.ChoiceForm",
	FormOpenParameters,
	ThisForm,,,,,
	FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectionsClearWarehouse(Command)
	
	Warehouse = Undefined;
	CreateRepresentationOfWarehouseSelection();
	FillBalance();
	
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
	"Catalog.Warerooms.Form.ChoiceForm",
	FormOpenParameters,
	ThisObject,,,,,
	FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectionsCleanRoom(Command)
	
	Premise = Undefined;
	ToFormRepresentationOfSelectionRoom();
	FillBalance();
	
EndProcedure

&AtClient
Procedure SelectionsClearCharacteristic(Command)
	
	Characteristic = Undefined;
	FillBalance();
	
EndProcedure

&AtClient
Procedure SelectionsClearSeries(Command)
	
	Series = Undefined;
	FillBalance();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInBalanceOfGoodsAtAddressWarehouse()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	GoodsInStorageBinsBalance.Products AS Products,
		|	GoodsInStorageBinsBalance.Products.SKU AS SKU,
		|	GoodsInStorageBinsBalance.Characteristic AS Characteristic,
		|	CASE
		|		WHEN GoodsInStorageBinsBalance.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN GoodsInStorageBinsBalance.Products.UnitOfMeasure
		|		ELSE GoodsInStorageBinsBalance.Package
		|	END AS Package,
		|	GoodsInStorageBinsBalance.Cell AS Cell,
		|	GoodsInStorageBinsBalance.Series AS Series,
		|	GoodsInStorageBinsBalance.Cell.Owner AS Warehouse,
		|	GoodsInStorageBinsBalance.Cell.Premise AS Premise,
		|	GoodsInStorageBinsBalance.InStockBalance AS Count
		|FROM
		|	AccumulationRegister.GoodsInStorageBins.Balance(
		|			,
		|			Products = &Products
		|				AND &ConditionCharacteristic
		|				AND &ConditionPremises
		|				AND &ConditionBatch
		|				AND &ConditionWarehouse) AS GoodsInStorageBinsBalance";
	
	Query.SetParameter("Products",   Products);
	
	If ValueIsFilled(Premise) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "AND Cell.Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "");
	EndIf;
	
	If ValueIsFilled(Warehouse) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionWarehouse", "AND Cell.Owner = &Warehouse");
		Query.SetParameter("Warehouse", Warehouse);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionWarehouse", "");
	EndIf;
	
	If ValueIsFilled(Characteristic) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionCharacteristic", "AND Characteristic = &Characteristic");
		Query.SetParameter("Characteristic", Characteristic);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionCharacteristic", "");
	EndIf;
	
	If ValueIsFilled(Series) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionBatch", "AND Series = &Series");
		Query.SetParameter("Series", Series);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionBatch", "");
	EndIf;

	QueryResult = Query.Execute().Unload();
	Goods.Load(QueryResult);
	
EndProcedure

&AtServer
Procedure FillInBalanceOfGoodsInWarehouse()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProductStockBalance.Products AS Products,
		|	ProductStockBalance.Products.SKU AS SKU,
		|	ProductStockBalance.Characteristic AS Characteristic,
		|	ProductStockBalance.Series AS Series,
		|	ProductStockBalance.Warehouse AS Warehouse,
		|	ProductStockBalance.Premise AS Premise,
		|	ProductStockBalance.InStockBalance AS Count,
		|	ProductStockBalance.Products.UnitOfMeasure AS Package
		|FROM
		|	AccumulationRegister.ProductStock.Balance(
		|			,
		|			Products = &Products
		|				AND &ConditionCharacteristic
		|				AND &ConditionPremises
		|				AND &ConditionBatch
		|				AND &ConditionWarehouse) AS ProductStockBalance";
	
	Query.SetParameter("Products", Products);
	
	If ValueIsFilled(Premise) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "AND Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "");
	EndIf;
	
	If ValueIsFilled(Warehouse) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionWarehouse", "AND Warehouse = &Warehouse");
		Query.SetParameter("Warehouse", Warehouse);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionWarehouse", "");
	EndIf;
	
	If ValueIsFilled(Characteristic) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionCharacteristic", "AND Characteristic = &Characteristic");
		Query.SetParameter("Characteristic", Characteristic);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionCharacteristic", "");
	EndIf;     
	
	If ValueIsFilled(Series) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionBatch", "AND Series = &Series");
		Query.SetParameter("Series", Series);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionBatch", "");
	EndIf;
	
	QueryResult = Query.Execute().Unload();
	Goods.Load(QueryResult);
	
EndProcedure

&AtServer
Procedure CreateRepresentationOfWarehouseSelection()
	
	PresentationsOfSelections = "";
	If ValueIsFilled(Warehouse) Then
		PresentationsOfSelections = Warehouse;
		Items.TeamSelectionsToOpen.TextColor = WebColors.Black;
		Items.GroupTeamQualifiersTheNumberOfClear.Visible = True;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuBlack;
	Else
		PresentationsOfSelections = NStr("vi = 'Kho bãi';
										|ru = 'Склад';
										|en = 'Warehouse'; fa = 'Warehouse';
										|it = 'Magazzino';
										|pl = 'Magazyn';
										|tr = 'Ambar'");
		Items.TeamSelectionsToOpen.TextColor = WebColors.DarkGray;
		Items.GroupTeamQualifiersTheNumberOfClear.Visible = False;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	If Common.ObjectAttributeValue(Warehouse, "IsFolder") = True Then
		UseWarerooms = False;
	Else
		UseWarerooms = Warehouse["UseWarerooms"];
	EndIf;
	Items.GroupTeamSelectionsOpen2.Visible    = UseWarerooms;
	Items.TeamSelectionsClearRoom.Visible = UseWarerooms;
	
	Items.TeamSelectionsToOpen.Title = PresentationsOfSelections;
	
EndProcedure

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
										|it = 'Selezionare magazzino';
										|pl = 'Wybierz pomieszczenie';
										|tr = 'Alan seç'");
		Items.TeamSelectionsOpenRoom.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClearRoom.Visible = False;
		Items.FrameSelectionsOpen2.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	Items.TeamSelectionsOpenRoom.Title = PresentationsOfSelections;
	
EndProcedure

&AtServer
Procedure FillBalance()
	
	Items.GroupCharacteristics.Visible  = ValueIsFilled(Characteristic); 
	Items.GroupSeries.Visible           = ValueIsFilled(Series); 
	
	If Not ValueIsFilled(Warehouse) Then
		FillInBalanceOfGoodsInWarehouse();
		Return;
	EndIf;
	
	WarehouseProperties = DataProcessors.MobileWarehouseKeeperWorkspace.WarehouseProperties(Warehouse);
	
	UseBinLocationWarehousing            = WarehouseProperties.UseBinLocationWarehousing;
	UseWarehouseManagemantSystemForGoodsReceipt = WarehouseProperties.UseWarehouseManagemantSystemForGoodsReceipt;
	UsePremises                   = WarehouseProperties.UseWarerooms;
	
	If WarehouseProperties.UseWarerooms Then
		StructureOfRoom = Common.ObjectAttributesValues(Premise, "UseBinLocationWarehousing");
		UseBinLocationWarehousing = StructureOfRoom.UseBinLocationWarehousing;
	EndIf;
	
	If DataProcessors.MobileWarehouseKeeperWorkspace.GetCatalogAttributes(Products, "UseVariants") = Enums.ItemVariantsUsageOptions.DontUse Then
		UseCharacteristics = False;
	Else
		UseCharacteristics = True;
	EndIf;
	
	Items.GroupSelectionsRoom.Visible = UsePremises;
	Items.GoodsPremise.Visible       = UsePremises;
	Items.GoodsCell.Visible          = UseBinLocationWarehousing;
	Items.GoodsCharacteristic.Visible  = UseCharacteristics;
	
	If UseBinLocationWarehousing Then
		FillInBalanceOfGoodsAtAddressWarehouse();
	Else
		FillInBalanceOfGoodsInWarehouse();
	EndIf;
	
EndProcedure

#EndRegion