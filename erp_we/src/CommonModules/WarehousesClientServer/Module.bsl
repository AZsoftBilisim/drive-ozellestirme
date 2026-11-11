
#Region Public

// The procedure coordinates and sets the values of address storage usage attributes.
//
// Parameters:
//  ObjectCatalog - CatalogObject.Warehouses - object warehouse for installation of the signs.
//
Procedure AgreeOnFeatureValues(ObjectCatalog) Export
	
	If Not ValueIsFilled(ObjectCatalog.CustomizeBinLocationWarehousing) Then
		ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.DontUse");
	EndIf;
	
	If ObjectCatalog.ShopFloorStockroom Then
		ObjectCatalog.UseWarehouseManagemantSystemForGoodsIssue = False;
		ObjectCatalog.UseWarehouseManagemantSystemForGoodsReceipt = False;
	EndIf;	
	
	If Not (ObjectCatalog.UseWarehouseManagemantSystemForGoodsIssue
	 And ObjectCatalog.UseWarehouseManagemantSystemForGoodsReceipt
	 And ObjectCatalog.UseWarehouseManagemantSystemForGoodsSurplusesShortages) Then
		
		ObjectCatalog.UseWarerooms = False;
		
	EndIf;

	If Not ObjectCatalog.UseWarehouseManagemantSystemForGoodsIssue Then
		ObjectCatalog.StartShipmentOnceDeliveryOrderIsCreated = False;
	EndIf;
	
	If Not ObjectCatalog.WarehouseStore = PredefinedValue("Enum.TypesOfWarehouses.RetailStore") Then
		ObjectCatalog.RetailPriceType = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
	EndIf;
	
	If ObjectCatalog.UseWarerooms Then
		ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.DeterminedByWareroomsSettings");
	ElsIf ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.DeterminedByWareroomsSettings") Then
		ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.DontUse");
	EndIf;
	
	If Not (ObjectCatalog.UseWarehouseManagemantSystemForGoodsIssue
			And ObjectCatalog.UseWarehouseManagemantSystemForGoodsReceipt
			And ObjectCatalog.UseWarehouseManagemantSystemForGoodsSurplusesShortages)
		And ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.CellsBalance") Then
			ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.DontUse");
	EndIf;
	
	If ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.CellsBalance") Then
		ObjectCatalog.UseBinLocationWarehousing          = True;
	ElsIf ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.BinsReferenceAddress") Then
		ObjectCatalog.UseBinLocationWarehousing          = False;
		ObjectCatalog.UseBinLocationWarehousingForInformation = True;
	Else
		ObjectCatalog.UseBinLocationWarehousing          = False;
		ObjectCatalog.UseBinLocationWarehousingForInformation = False;
	EndIf;
	
	If ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.DeterminedByWareroomsSettings") Then
		ObjectCatalog.WarehouseZoneUsage = PredefinedValue("Enum.UseIsDeterminedInWarerooms.DeterminedByWareroomsSettings");
	ElsIf ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.DontUse") Then
		ObjectCatalog.WarehouseZoneUsage = PredefinedValue("Enum.UseIsDeterminedInWarerooms.DontUse");
	EndIf;
	
	If (ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.DeterminedByWareroomsSettings")
		Or ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.CellsBalance")
		Or ObjectCatalog.UseItemsBatch)
		And ObjectCatalog.UseWarehouseManagemantSystemForGoodsIssue Then
		ObjectCatalog.UseGoodsIssueNoteStatuses = True;
	EndIf;
	
	If Not ObjectCatalog.UseWarehouseManagemantSystemForGoodsIssue Then
		ObjectCatalog.UseGoodsIssueNoteStatuses = False;
		ObjectCatalog.StartDateOfWarehouseManagemantSystemForGoodsIssue = Date(1, 1, 1);
	EndIf;
	
	If Not ObjectCatalog.UseWarehouseManagemantSystemForGoodsReceipt Then
		ObjectCatalog.UseGoodsReceiptNoteStatuses = False;
		ObjectCatalog.StartDateOfWarehouseManagemantSystemForGoodsReceipt = Date(1, 1, 1);
	EndIf;
	
	If Not ObjectCatalog.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
		ObjectCatalog.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages = Date(1, 1, 1);
	EndIf;
	
	If Not ObjectCatalog.CustomizeBinLocationWarehousing = PredefinedValue("Enum.SettingsOfBinLocationWarehousing.CellsBalance") Then
		ObjectCatalog.StartDateOfUsingWarehouseBinSystem = Date(1, 1, 1);
	EndIf;
	
	If Not ObjectCatalog.UseWarerooms Then
		ObjectCatalog.StartDateOfWareroomUse = Date(1, 1, 1);
	EndIf;
	
	If ObjectCatalog.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
		ObjectCatalog.UseInventoryRecountStatuses = True;	
	EndIf;
	
EndProcedure

// Fields where the selected products may not match the order and this is not considered a shortage.
//
// Parameters:
//  Form			 - ClientApplicationForm				 - Current form
//  CurrentData	 - FormDataCollectionItem, Undefined - if data is transmitted, it is calculated for them if
//  	Is undefined in General, for PM.
// 
// Returns:
//  Structure - a structure with the following keys:
//  * PackingList_ - Boolean - True if packages are taken into account
//  * SeriesStatusesThatAreNotTakenIntoAccount - Array - an array of statuses disregarded the instructions of the series
//  * ConsiderSeries - Boolean - True if the series are taken into account.
//
Function FieldsTakenIntoAccountWhenCheckingSpendingOrder(Form, CurrentData) Export
	
	Result = New Structure("PackingList_,ConsiderSeries,SeriesStatusesThatAreNotTakenIntoAccount");
	
	Result.PackingList_ = Form.UseBinLocationWarehousing;
	
	SeriesStatusesThatAreNotTakenIntoAccount = New Array();
	SeriesStatusesThatAreNotTakenIntoAccount.Add(0);
	SeriesStatusesThatAreNotTakenIntoAccount.Add(1);
	SeriesStatusesThatAreNotTakenIntoAccount.Add(2);
	SeriesStatusesThatAreNotTakenIntoAccount.Add(3);
	SeriesStatusesThatAreNotTakenIntoAccount.Add(4);
	
	Result.SeriesStatusesThatAreNotTakenIntoAccount = SeriesStatusesThatAreNotTakenIntoAccount;
	
	If CurrentData = Undefined Then
		Result.ConsiderSeries = True;
	Else
		Result.ConsiderSeries    = SeriesStatusesThatAreNotTakenIntoAccount.Find(CurrentData.BatchesIndicationStatus) = Undefined;
	EndIf;

	Return Result;
	
EndFunction

// Checks whether the array contains warehouse operations of the "Acceptance" type.
//
// Parameters:
//		WarehouseTransactions - Array - array of values of warehouse operations.
//
//	Returns:
//		Boolean - True, among the array elements there is a warehouse operation of the "Acceptance" type.
//
Function ThereIsAcceptance(WarehouseTransactions) Export
	
	WarehouseOperationsOfGoodsAcceptance = WarehouseOperationsOfGoodsAcceptance();
	For Each ArrRow In WarehouseTransactions Do 
		If WarehouseOperationsOfGoodsAcceptance.Find(ArrRow) <> Undefined Then
			Return True;
		EndIf;
	EndDo;
		
	Return False;
	
EndFunction

// Returns an array of values for warehouse operations of the "Acceptance" type"
//
//	Returns:
//		Array - array of values of warehouse operations.
//
Function WarehouseOperationsOfGoodsAcceptance() Export
	
	OperationArray = New Array;
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.OBEntry"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ReceivingOfComponentsAfterDisassembly"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ReceivingByReturnFromACustomer"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ReceivingByTransfer"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.GoodsReceiptByOtherTransactions"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ReceivingOfAssembledSets"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ManufactureOfProducts"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ProductsReleaseToBusinessUnit"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ReturnMaterialsFromProductionReceiving"));
	
	Return OperationArray;
	
EndFunction

// Checks whether the array contains warehouse operations of the "Shipment" type.
//
// Parameters:
//		WarehouseTransactions - Array - array of values of warehouse operations.
//
//	Returns:
//		Boolean - True, among the array elements there is a warehouse operation of the "Shipment" type.
//
Function ThereIsShipment(WarehouseTransactions) Export
	WarehouseShippingOperations = WarehouseShippingOperations();
	For Each ArrRow In WarehouseTransactions Do 
		If WarehouseShippingOperations.Find(ArrRow) <> Undefined Then
			Return True;
		EndIf;
	EndDo;
		
	Return False;
	
EndFunction

// Returns an array of values for warehouse operations of the "Shipment" type"
//
//	Returns:
//		Array - array of values of warehouse operations.
//
Function WarehouseShippingOperations() Export
	
	OperationArray = New Array;
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ShipmentForInternalNeeds"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ShipmentUnderReturnToVendor"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.TransferBetweenWarerooms"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ShipmentToCustomer"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ShipmentByTransfer"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ShipSetsForDisassembly"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.ShipComponentsForAssembly"));
	OperationArray.Add(PredefinedValue("Enum.WarehouseTransactions.TransferToProductionShipment"));
	
	Return OperationArray;

EndFunction

// Checks that the line can be moved to another order
//
// Parameters:
//  TSRow 	- FormDataCollectionItem	 - string to check
//  			- DocumentTabularSectionRow.GoodsIssueNote.ShippedGoods - the string to check.
// 
// Returns:
//  Boolean - the line can be moved to another order.
//
Function LineOfSpendingOrderCanBeTransferredToAnotherOrder(TSRow) Export
	
	Validation = True;
	
	If ValueIsFilled(TSRow.PackingListParent) Then
		MessageText = NStr("vi = 'Đã đóng gói dòng được chuyển trong một danh sách đóng gói. Hỗ trợ chuyển chỉ danh sách đóng gói toàn bộ, vì vậy cần hoặc loại trừ dòng khỏi danh sách đóng gói, hoặc chuyển đến cấp cao nhất và chuyển danh sách đóng gói toàn bộ.';
							|ru = 'Переносимая строка упакована в упаковочном листе. Поддерживается перенос только упаковочного листа целиком, поэтому нужно или исключить строку из упаковочного листа, или перейти на самый верхний уровень и перенести упаковочный лист целиком.';
							|en = 'The moved line is packed in the packing list. Only the whole packing list can be moved, that is why either exclude the line from the packing list, or go to the highest level and move the whole packing list.'; fa = 'The moved line is packed in the packing list. Only the whole packing list can be moved, that is why either exclude the line from the packing list, or go to the highest level and move the whole packing list.';
							|it = 'La riga da trasferire è inclusa nella packing list. Il trasferimento viene supportato solo per una packing list intera, quindi è necessario escludere la riga dalla packing list, o andare al livello più alto e spostare l''intera packing list.';
							|pl = 'Przenoszony wiersz jest zapakowany do wykazu ładunkowego. Obsługiwane jest tylko przenoszenie wykazu ładunkowego w całości, dlatego należy wykluczyć wiersz z wierszu ładunkowego lub przejść na najwyższy poziom i cały wykaz ładunkowy.';
							|tr = 'Aktarılacak satır ürün listesinde paketlenmiştir. Yalnızca ürün listesinin transferi desteklenir, bu nedenle satırının ürün listesinden çıkarılması veya en üst seviyeye gidip ürün listesinin tamamının aktarılması gerekir.'");
		CommonClientServer.MessageToUser(MessageText);
		Validation = False;
	EndIf;
	
	If TSRow.Action = PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.DoNotShip")
		Or TSRow.Action =  PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Pick") Then
		
		MessageText = NStr("vi = 'Đã chọn thao tác ""%Action%"" cho dòng được chuyển. Có thể chuyển chỉ các dòng với thao tác ""%Ship%""';
							|ru = 'Для переносимой строки выбрано действие ""%Action%"". Можно переносить только строки с действием ""%Ship%""';
							|en = 'The ""%Action%"" action is selected for the transferred line. Only lines with the ""%Ship%"" action can be transferred'; fa = 'The ""%Action%"" action is selected for the transferred line. Only lines with the ""%Ship%"" action can be transferred';
							|it = 'Per la riga da trasferire è stata selezionata l''azione ""%Action%"". È possibile trasferire solo le righe con l''azione ""%Ship%""';
							|pl = 'Dla wiersza, który ma zostać przeniesiony, wybrane jest działanie ""%Action%"". Możesz przesyłać tylko wiersze z działaniem ""%Ship%""';
							|tr = 'Aktarılacak satır için ""%Action%"" işlemi seçilir. Yalnızca ""%Ship%"" işlemine sahip satırlar aktarılabilir'");
		MessageText = StrReplace(MessageText, "%Action%", TSRow.Action);
		MessageText = StrReplace(MessageText, "%Ship%", PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Ship"));
		CommonClientServer.MessageToUser(MessageText);
		Validation = False;
	EndIf;
	Return Validation;

EndFunction

// Creates a label and image to display information about the number of warehouses in the document.
//
// Parameters:
//	SeveralWarehousesText - String - field on the form for displaying the number of warehouses in the document;
//	PictureField - PictureBox - field on the form for displaying an image warning about the number of warehouses more than one;
//	NumberOfWarehouses - Number - number of warehouses.
//
Procedure UpdateWarehouseGroupImage(SeveralWarehousesText, PictureField, NumberOfWarehouses) Export
	
	If NumberOfWarehouses > 1 Then
		PictureField.Picture = PictureLib.Information;
		SeveralWarehousesText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kho trong chứng từ: %1';
				|ru = 'Складов в документе: %1';
				|en = 'Warehouses in document: %1'; fa = 'Warehouses in document: %1';
				|it = 'Magazzini nel documento: %1';
				|pl = 'Magazynów w dokumencie: %1';
				|tr = 'Belgesindeki ambarlar: %1'"), NumberOfWarehouses);
	Else
		PictureField.Picture = New Picture();
		SeveralWarehousesText = "";
	EndIf;
	
EndProcedure

// Fills the warehouse in the PM line or in the list of lines if multiple warehouses are not used.
//
// Parameters:
//  UseSeveralWarehouses - Boolean - The truth is, if you are using multiple warehouses
//  DefaultWarehouse			 - CatalogRef.Warehouses - The default warehouse
//  TSStringOrListOfStrings		 - FormDataStructure - PM string or list of PM strings
//  WarehouseFieldName				 - String - Name of the details to fill in the warehouse.
//
Procedure FillDefaultWarehouse(UseSeveralWarehouses, DefaultWarehouse, TSStringOrListOfStrings, WarehouseFieldName = "Warehouse") Export
	
	If UseSeveralWarehouses Then
		Return;
	EndIf; 

	If TypeOf(TSStringOrListOfStrings) = Type("Array") 
		Or TypeOf(TSStringOrListOfStrings) = Type("FormDataCollection") Then
		For Each TSRow In TSStringOrListOfStrings Do
			TSRow[WarehouseFieldName] = DefaultWarehouse;
		EndDo; 
	Else
		TSStringOrListOfStrings[WarehouseFieldName] = DefaultWarehouse;
	EndIf; 

EndProcedure

// Returns the warehouse acceptance operation corresponding to the transferred business operation.
//
// Parameters:
//  BusinessOperation	 - EnumRef.BusinessTransactions
// 
// Returns:
//   EnumRef.WarehouseTransactions 
//
Function WarehouseAcceptanceOperationForBusinessOperation(BusinessOperation) Export
	
	If Not ValueIsFilled(BusinessOperation) Then
		Return PredefinedValue("Enum.WarehouseTransactions.EmptyRef");
	EndIf;
	
	MatchingOperations = ComplianceOfEconomicOperationsWithWarehouseAcceptanceOperations();
		
	WarehouseOperation = MatchingOperations.Get(BusinessOperation);
	
	If WarehouseOperation = Undefined Then
		ExceptionText = NStr("vi = 'Giao dịch kinh doanh ""%BusinessOperation%"" không liên quan đến hoạt động kho.';
							|ru = 'Хозяйственная операция ""%BusinessOperation%"" не сопоставлена со складской операцией.';
							|en = 'The ""%BusinessOperation%"" business transaction is not matched with the warehouse operation.'; fa = 'The ""%BusinessOperation%"" business transaction is not matched with the warehouse operation.';
							|it = 'L''operazione commerciale ""%BusinessOperation%""  non è confrontata con l''operazione di magazzino.';
							|pl = 'Transakcja gospodarcza ""%BusinessOperation%"" nie pokrywa się z transakcją w magazynie.';
							|tr = '""%BusinessOperation%"" ticari işlemi bir ambar işlemiyle karşılaştırılmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%BusinessOperation%", BusinessOperation);
		Raise BusinessOperation;
	EndIf;
	
	Return WarehouseOperation;
EndFunction

// Returns an array of business operations corresponding to warehouse acceptance operations.
// 
// Returns:
//  Array - array from the link enumeration.Economic operation.
//
Function EconomicOperationsOfAcceptanceToWarehouse()Export
	
	MatchingOperations = WarehousesClientServer.ComplianceOfEconomicOperationsWithWarehouseAcceptanceOperations();
	
	BusinessTransactions = New Array;
	
	For Each Operation In MatchingOperations Do
		BusinessTransactions.Add(Operation.Key);
	EndDo;
	
	Return BusinessTransactions;
	
EndFunction

// Returns the correspondence between business operations and warehouse acceptance operations
// 
// Returns:
//  Map
//		* Key-Enum Link.Economic operation
//		*Value - Enum link.Warehouse Operation
//
Function ComplianceOfEconomicOperationsWithWarehouseAcceptanceOperations() Export
	MatchingOperations = New Map;
	
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEU"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.PurchaseViaAdvanceHolder"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));
	
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5"), PredefinedValue("Enum.WarehouseTransactions.ReceiptFromVendor"));

	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices"), PredefinedValue("Enum.WarehouseTransactions.ReceivingByTransfer"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.InventoryTransfer"), PredefinedValue("Enum.WarehouseTransactions.ReceivingByTransfer"));
	
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsFromCustomer"), PredefinedValue("Enum.WarehouseTransactions.ReceivingByReturnFromACustomer"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent"), PredefinedValue("Enum.WarehouseTransactions.ReceivingByReturnFromACustomer"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian"), PredefinedValue("Enum.WarehouseTransactions.ReceivingByReturnFromACustomer"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReturnFromRetailCustomer"), PredefinedValue("Enum.WarehouseTransactions.ReceivingByReturnFromACustomer"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.GoodsReceiptFromCustomer"), PredefinedValue("Enum.WarehouseTransactions.ReceivingByReturnFromACustomer"));
	
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.AssemblyFromComponents"), PredefinedValue("Enum.WarehouseTransactions.ReceivingOfAssembledSets"));
	
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.DisassemblyIntoComponents"), PredefinedValue("Enum.WarehouseTransactions.ReceivingOfComponentsAfterDisassembly"));
	
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ProductsRelease"), PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ProductsReleaseFixCost"), PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse"), PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromProduction"), PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromStoreroom"), PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromProduction"), PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom"), PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.TransferOfSemiFinishedProducts"), PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices"), PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom"), PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
	
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.InventoryConsumptionReverseTransaction"), PredefinedValue("Enum.WarehouseTransactions.GoodsReceiptByOtherTransactions"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.GoodsReceiptByIncomeLiabilities"), PredefinedValue("Enum.WarehouseTransactions.GoodsReceiptByOtherTransactions"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.GoodsReceiptByExpencesAssets"), PredefinedValue("Enum.WarehouseTransactions.GoodsReceiptByOtherTransactions"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.RegistrationAtFADisposal"), PredefinedValue("Enum.WarehouseTransactions.GoodsReceiptByOtherTransactions"));
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReceiptFromProduction"), PredefinedValue("Enum.WarehouseTransactions.GoodsReceiptByOtherTransactions"));
	
	MatchingOperations.Insert(PredefinedValue("Enum.BusinessTransactions.ReturnFromProduction"), PredefinedValue("Enum.WarehouseTransactions.GoodsReceiptByOtherTransactions"));

	MatchingOperations.Insert(
		PredefinedValue("Enum.BusinessTransactions.PutOutOfOperation"), 
		PredefinedValue("Enum.WarehouseTransactions.GoodsReceiptByOtherTransactions"));

	Return MatchingOperations;
	
EndFunction

// Returns an array of types of warehouse acceptance cells.
// 
// Returns:
//  Array of EnumRef.TypesOfStorageCells
//
Function CellTypesAcceptance() Export
	
	Result = New Array;
	Result.Add(PredefinedValue("Enum.TypesOfStorageCells.Receiving"));
	
	Return Result;
	
EndFunction

// Returns an array of types of shipment storage cells.
// 
// Returns:
//  Array of EnumRef.TypesOfStorageCells
//
Function CellTypesShipment() Export
	
	Result = New Array;
	Result.Add(PredefinedValue("Enum.TypesOfStorageCells.Shipment"));
	Result.Add(PredefinedValue("Enum.TypesOfStorageCells.ShipmentIncludingBalances"));
	
	Return Result;
	
EndFunction

#EndRegion
