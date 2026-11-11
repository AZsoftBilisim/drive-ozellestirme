#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Package = Parameters.Package;
	If Not ValueIsFilled(Package) Then
		Package = Common.ObjectAttributeValue(Parameters.Products, "UnitOfMeasure");
	EndIf;
	
	FillInTable();
	SetHeadersWhenCreatingForm();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PickUpGoodsOnChange(Item)
	
	FillInTable();
	Update_Selected();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAssignmentsTable

&AtClient
Procedure TableWhenActivatingCell(Item)

	If Item.CurrentItem.Name = Items.TableMoveRight.Name Then
		CurrentData = Items.AssignmentsTable.CurrentData;
		If CurrentData <> Undefined Then
			CurrentData.Selected = CurrentData.InStock;
			Update_Selected();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TableMatchedOnChange(Item)
	
	Update_Selected();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	Selected = AssignmentsTable.Total("Selected");
	If Selected <> Parameters.Pick Then
		Template = NStr("vi = 'Số lượng được chọn (%1 %3) không trùng với số lượng cần chọn (%2 %3). Không thể thực hiện lệnh.';
						|ru = 'Подобранное количество (%1 %3) не совпадает с количеством, которое необходимо подобрать (%2 %3). Команда не может быть выполнена.';
						|en = 'The picked quantity (%1 %3) does not match the quantity to be picked (%2 %3). Cannot execute the command.'; fa = 'The picked quantity (%1 %3) does not match the quantity to be picked (%2 %3). Cannot execute the command.';
						|it = 'La quantità selezionata (%1 %3) non coincide con la quantità che deve essere selezionata (%2%3). Impossibile eseguire il comando.';
						|pl = 'Wybrana ilość (%1 %3) nie jest zgodna z ilością, którą należy wybrać (%2 %3). Polecenie nie może być wykonane.';
						|tr = 'Seçili miktar (%1 %3) eşleştirilecek miktarla eşleşmiyor. (%2 %3) Komut yürütülemedi.'");
		Text = StrTemplate(
			Template,
			Format(Selected, "NFD=3; NZ=0,000;"),
			Format(Parameters.Pick, "NFD=3; NZ=0,000;"),
			Package);
		ShowMessageBox(, Text);
		Return;
	EndIf;
	Result = New Structure("SelectedGoods", SelectedGoods());
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInTable()
	
	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Products = &Products
		|			AND Characteristic = &Characteristic
		|			AND Warehouse = &Warehouse
		|			AND Purpose <> &DestinationRecipient
		|			AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|			AND &GetBalanceOfLotReferences) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Products = &Products
		|			AND Characteristic = &Characteristic
		|			AND Warehouse = &Warehouse
		|			AND Purpose <> &DestinationRecipient
		|			AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef) AS UnderControl,
		|	Table.QuantityForShipAction AS InStock,
		|	ISNULL(
		|		CASE
		|			WHEN SupplyOfGoodsOfProvenQuality.QuantityForShipAction > 0
		|				THEN SupplyOfGoodsOfProvenQuality.QuantityInStockForActionToReserveAsReceived
		|						- SupplyOfGoodsOfProvenQuality.QuantityForShipAction
		|			WHEN SupplyOfGoodsOfProvenQuality.QuantityInStockForActionToReserveAsReceived > 0
		|				THEN SupplyOfGoodsOfProvenQuality.QuantityInStockForActionToReserveAsReceived
		|			ELSE 0
		|		END, 0) AS AvailableByAllLotsReference
		|FROM
		|	CollateralData AS Table
		|		
		|		LEFT JOIN CollateralData AS SupplyOfGoodsOfProvenQuality
		|		ON SupplyOfGoodsOfProvenQuality.Products =Table.Products
		|		 AND SupplyOfGoodsOfProvenQuality.Characteristic = Table.Characteristic
		|		 AND SupplyOfGoodsOfProvenQuality.Warehouse = Table.Warehouse
		|		 AND SupplyOfGoodsOfProvenQuality.Purpose = Table.Purpose
		|		 AND SupplyOfGoodsOfProvenQuality.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|		
		|		LEFT JOIN Catalog.Assignments AS DestinationRecipient
		|		ON DestinationRecipient.Ref = &DestinationRecipient
		|WHERE
		|	CASE
		|		WHEN
		|			DestinationRecipient.AssignmentType IN(
		|						VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22))
		|			THEN
		|				Table.Purpose.AssignmentType IN(
		|							VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22))
		|						AND DestinationRecipient.Partner = Table.Purpose.Partner
		|						AND DestinationRecipient.Contract = Table.Purpose.Contract
		|					OR Table.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
		|		ELSE
		|			NOT Table.Purpose.AssignmentType IN(
		|				VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
		|	END
		|	AND Table.QuantityForShipAction > 0
		|ORDER BY
		|	Purpose, UnderControl, InStock DESC";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "CollateralData"; // @query-part-1
	ProvisionInDocumentsServer.CollateralData(QueryText, TablesNames);
	
	ThisIsSelectionOfLotReferences = PickUpGoods = PickUpGoodsValueAll();
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("Products", Parameters.Products);
	Query.SetParameter("Characteristic", Parameters.Characteristic);
	Query.SetParameter("Warehouse", Parameters.Warehouse);
	Query.SetParameter("DestinationRecipient", Parameters.Purpose);
	Query.SetParameter("GetBalanceOfLotReferences", ThisIsSelectionOfLotReferences);
	Result = Query.Execute().Unload();
	AssignmentsTable.Clear();
	AssignmentsTable.Load(Result);
	
	PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Parameters.Products);
	For Each String In AssignmentsTable Do
		String.InStock = String.InStock / PackagingFactor;
		String.AvailableByAllLotsReference = String.AvailableByAllLotsReference / PackagingFactor;
	EndDo;
	
	Items.TableOfControlledLotReferences.Visible = ThisIsSelectionOfLotReferences;
	Items.Totals1Group.Visible = ThisIsSelectionOfLotReferences;
	Items.TableIsUnderControl.Visible = ThisIsSelectionOfLotReferences;
	Items.MoveToDocument.Enabled = AssignmentsTable.Count() > 0;
	
EndProcedure

&AtServer
Procedure SetHeadersWhenCreatingForm()
	
	Items.TableInStock.Title = StrTemplate(Items.TableInStock.Title, Package);
	Items.TableMatched.Title = StrTemplate(Items.TableMatched.Title, Package);
	
	If ValueIsFilled(Parameters.Characteristic) Then
		Title = NStr("vi = 'Chỉ ra mục đích đối với hàng hóa: %1,%3 trong kho: %2';
					|ru = 'Указание назначений для товара: %1,%3 на складе: %2';
					|en = 'Specify assignments for goods: %1,%3 in the warehouse: %2'; fa = 'Specify assignments for goods: %1,%3 in the warehouse: %2';
					|it = 'Indicazione di assegnazioni per la merce: %1,%3 nel magazzino: %2';
					|pl = 'Podanie przeznaczeń dla towaru: %1,%3 w magazynie: %2';
					|tr = 'Ürünler için atama belirtme: %1,%3 ambarda: %2'");
		Title = StrTemplate(Title, Parameters.Products, Parameters.Warehouse, Parameters.Characteristic);
	Else
		Title = NStr("vi = 'Chỉ ra mục đích đối với hàng hóa: %1 trong kho: %2';
					|ru = 'Указание назначений для товара: %1 на складе: %2';
					|en = 'Specify assignments for goods: %1 in the warehouse: %2'; fa = 'Specify assignments for goods: %1 in the warehouse: %2';
					|it = 'Indicazione di assegnazioni per la merce: %1 nel magazzino: %2';
					|pl = 'Podanie przeznaczeń dla towaru: %1 w magazynie: %2';
					|tr = 'Ürünler için atama belirtme: %1 ambarda: %2'");
		Title = StrTemplate(Title, Parameters.Products, Parameters.Warehouse);
	EndIf;
	
	Items.DecorationToPickUp.Title = StrTemplate(Items.DecorationToPickUp.Title,
		Format(Parameters.Pick, "NFD=3; NZ=0,000;"), Package);
	Selected = AssignmentsTable.Total("Selected");
	Items.SceneryIsSelected.Title = StrTemplate(NStr("vi = 'Đã chọn: %1 %2';
													|ru = 'Подобрано: %1 %2';
													|en = 'Picked: %1 %2'; fa = 'انتخاب‌شده: %1 %2';
													|it = 'Selezionato: %1 %2';
													|pl = 'Wybrano: %1 %2';
													|tr = 'Seçildi: %1 %2'"),
		Format(Selected, "NFD=3; NZ=0,000;"), Package);
	
EndProcedure

&AtServer
Function SelectedGoods()
	
	Result = AssignmentsTable.Unload(New Array(), "Purpose,ControlledLotReference,Selected");
	
	For Each String In AssignmentsTable Do
		If String.Selected > 0 Then
			FillPropertyValues(Result.Add(), String);
		EndIf;
	EndDo;
	
	Address = PutToTempStorage(Result);
	Return Address;
	
EndFunction

&AtClient
Procedure Update_Selected()
	
	Selected = AssignmentsTable.Total("Selected");
	Items.SceneryIsSelected.Title = StrTemplate(NStr("vi = 'Đã chọn: %1 %2';
													|ru = 'Подобрано: %1 %2';
													|en = 'Picked: %1 %2'; fa = 'انتخاب‌شده: %1 %2';
													|it = 'Selezionato: %1 %2';
													|pl = 'Wybrano: %1 %2';
													|tr = 'Seçildi: %1 %2'"),
		Format(Selected, "NFD=3; NZ=0,000;"), Package);
	
EndProcedure

&AtServer
Function PickUpGoodsValueAll()
	
	Return 1;
	
EndFunction

#EndRegion
