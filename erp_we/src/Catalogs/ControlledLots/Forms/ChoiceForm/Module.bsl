#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Interpretation of input parameters.
	UnderControl = "1";
	Package = ?(ValueIsFilled(Parameters.Package), Parameters.Package,
		Common.ObjectAttributeValue(Parameters.Products, "UnitOfMeasure"));
	PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Parameters.Products);
	
	Items.InStock.Title = StrTemplate(Items.InStock.Title, Package);
	OnChangesToServerControl(True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UnderControlOnChange(Item)
	
	OnChangesToServerControl(False);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If Parameters.Source = "Document.RequestForGoodsQualityControl"
			And IsARequest(Value) Then
				StandardProcessing = False;
				WarningText = NStr("vi = 'Trong yêu cầu kiểm soát chất lượng hàng hóa, cần phải chỉ định các lô hàng được kiểm soát mà hàng hóa đã được nhập. Không thể chọn lô hàng được kiểm soát liên kết với yêu cầu kiểm soát chất lượng hàng hóa.';
									|ru = 'В заявке на контроль качества товаров необходимо указывать контролируемые партии, по которым поступил товар. Выбор контролируемой партии, связанной с заявкой на контроль качества товаров, недоступен.';
									|en = 'In the request for goods quality control, specify the controlled lots under which the goods were received. Cannot select a controlled lot related to the request for goods quality control.'; fa = 'In the request for goods quality control, specify the controlled lots under which the goods were received. Cannot select a controlled lot related to the request for goods quality control.';
									|it = 'In the request for goods quality control, specify the controlled lots under which the goods were received. Cannot select a controlled lot related to the request for goods quality control.';
									|pl = 'In the request for goods quality control, specify the controlled lots under which the goods were received. Cannot select a controlled lot related to the request for goods quality control.';
									|tr = 'Ürün kalite kontrol talebinde, ürünün geldiği kontrol edilen lotların belirtilmesi gerekir. Ürün kalite kontrol talebine bağlı kontrol edilen lotun seçimi yapılamıyor.'");
				ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function IsARequest(Value)
	
	SetPrivilegedMode(True);
	Lot = Common.ObjectAttributeValue(Value, "Lot");
	Return TypeOf(Lot) = Type("DocumentRef.RequestForGoodsQualityControl");
	
EndFunction

&AtServer
Procedure OnChangesToServerControl(CallWhenCreatingForm)
	
	ActiveOnly = UnderControl = "1";
	
	VisibilityOfResidues = Parameters.Source = "Document.InventoryAssignmentAdjustment" And ActiveOnly;
	Items.InStock.Visible = VisibilityOfResidues;
	Items.Totals1Group.Visible = VisibilityOfResidues;
	
	If Parameters.Source = "Document.InventoryAssignmentAdjustment" Then
		
		If ActiveOnly Then
			
			Text =
				"SELECT
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
				|			AND Purpose = &Purpose) AS Inventories
				|INDEX BY
				|	Products, Characteristic, Warehouse, Purpose
				|;
				|
				|////////////////////////////////////////////////
				|SELECT
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
				|			AND Purpose = &Purpose) AS Inventories
				|INDEX BY
				|	Products, Characteristic, Warehouse, Purpose
				|;
				|
				|////////////////////////////////////////////////
				|SELECT
				|	Table.ControlledLotReference AS Ref,
				|	Table.QuantityForShipAction AS Surplus,
				|	ISNULL(
				|		CASE
				|			WHEN SupplyOfGoodsOfProvenQuality.QuantityForShipAction > 0
				|				THEN SupplyOfGoodsOfProvenQuality.QuantityInStockForActionToReserveAsReceived
				|						- SupplyOfGoodsOfProvenQuality.QuantityForShipAction
				|			WHEN SupplyOfGoodsOfProvenQuality.QuantityInStockForActionToReserveAsReceived > 0
				|				THEN SupplyOfGoodsOfProvenQuality.QuantityInStockForActionToReserveAsReceived
				|			ELSE 0
				|		END, 0) AS AvailableByAllLotsReference
				|INTO Balance
				|FROM
				|	CollateralData AS Table
				|		LEFT JOIN CollateralData AS SupplyOfGoodsOfProvenQuality
				|		ON SupplyOfGoodsOfProvenQuality.Products =Table.Products
				|		 AND SupplyOfGoodsOfProvenQuality.Characteristic = Table.Characteristic
				|		 AND SupplyOfGoodsOfProvenQuality.Warehouse = Table.Warehouse
				|		 AND SupplyOfGoodsOfProvenQuality.Purpose = Table.Purpose
				|		 AND SupplyOfGoodsOfProvenQuality.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
				|WHERE
				|	Table.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
				|		AND Table.QuantityForShipAction > 0
				|INDEX BY
				|	Ref
				|;
				|
				|////////////////////////////////////////////////
				|SELECT
				|	ControlledLots.Ref AS Ref,
				|	ControlledLots.Description AS Description,
				|	ControlledLots.ReasonForGoodsLock AS ReasonForGoodsLock,
				|	ControlledLots.ReceiptDocumentNumber AS ReceiptDocumentNumber,
				|	ControlledLots.Contract AS Contract,
				|	ControlledLots.Partner AS Partner,
				|	ControlledLots.DateOfReceipt AS DateOfReceipt,
				|	ControlledLots.Lot AS Lot,
				|	Balance.Surplus / &PackagingFactor AS InStock,
				|	Balance.AvailableByAllLotsReference / &PackagingFactor AS AvailableByAllLotsReference
				|FROM
				|	Catalog.ControlledLots AS ControlledLots
				|		INNER JOIN Balance AS Balance
				|		ON Balance.Ref = ControlledLots.Ref";
			
			TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
			TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
			TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
			TablesNames.Result = "CollateralData"; // @query-part-1
			ProvisionInDocumentsServer.CollateralData(Text, TablesNames, False);
			
			ListProperties = Common.DynamicListPropertiesStructure();
			ListProperties.MainTable = "Catalog.ControlledLots";
			ListProperties.DynamicDataRead = False;
			ListProperties.QueryText = Text;
			Common.SetDynamicListProperties(Items.List, ListProperties);
			
			CommonClientServer.SetDynamicListParameter(
				List,
				"Products",
				Parameters.Products);
			CommonClientServer.SetDynamicListParameter(
				List,
				"Characteristic",
				Parameters.Characteristic);
			CommonClientServer.SetDynamicListParameter(
				List,
				"Warehouse",
				Parameters.Warehouse);
			CommonClientServer.SetDynamicListParameter(
				List,
				"Purpose",
				Parameters.Purpose);
			CommonClientServer.SetDynamicListParameter(
				List,
				"PackagingFactor",
				PackagingFactor);
				
		Else
			
			Text =
				"SELECT
				|	ControlledLotsOverridable.Ref AS Ref,
				|	ControlledLotsOverridable.Description AS Description,
				|	ControlledLotsOverridable.ReasonForGoodsLock AS ReasonForGoodsLock,
				|	ControlledLotsOverridable.ReceiptDocumentNumber AS ReceiptDocumentNumber,
				|	ControlledLotsOverridable.Contract AS Contract,
				|	ControlledLotsOverridable.Partner AS Partner,
				|	ControlledLotsOverridable.DateOfReceipt AS DateOfReceipt,
				|	ControlledLotsOverridable.Lot AS Lot,
				|	CAST(0 AS NUMBER(15,3)) AS InStock,
				|	CAST(0 AS NUMBER(15,3)) AS AvailableByAllLotsReference
				|FROM
				|	Catalog.ControlledLots AS ControlledLotsOverridable";
				
			ListProperties = Common.DynamicListPropertiesStructure();
			ListProperties.MainTable = "Catalog.ControlledLots";
			ListProperties.DynamicDataRead = True;
			ListProperties.QueryText = Text;
			Common.SetDynamicListProperties(Items.List, ListProperties);
			
		EndIf;
		
	Else
		
		If CallWhenCreatingForm Then
			
			Query = New Query();
			Query.Text =
				"SELECT ALLOWED DISTINCT
				|	Table.OrderDocument AS Ref
				|FROM
				|	AccumulationRegister.InventoryAndDemands.Balance(,
				|		VALUETYPE(OrderDocument) = TYPE(Catalog.ControlledLots)) AS Table";
				
			ActiveLinks = Query.Execute().Unload().UnloadColumn("Ref");
			
			If Parameters.Source = "Document.RequestForGoodsQualityControl" Then
				
				SetPrivilegedMode(True);
				Query.SetParameter("ActiveLinks", ActiveLinks);
				Query.Text =
					"SELECT
					|	Table.Ref AS Ref
					|FROM
					|	Catalog.ControlledLots AS Table
					|WHERE
					|	Table.Ref IN(&ActiveLinks)
					|		AND VALUETYPE(Table.Lot) <> TYPE(Document.RequestForGoodsQualityControl)";
				ActiveLinks = Query.Execute().Unload().UnloadColumn("Ref");
				SetPrivilegedMode(False);
				
			EndIf;
			
			CommonClientServer.SetDynamicListParameter(List, "References", ActiveLinks);
			
		EndIf;
		
		CommonClientServer.SetDynamicListParameter(List, "ActiveOnly", ActiveOnly);
		
	EndIf;
	
EndProcedure

#EndRegion