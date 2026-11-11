#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("UseWarehouseManagemantSystemForGoodsIssue");
	Result.Add("UseWarehouseManagemantSystemForGoodsReceipt");
	Result.Add("UseWarerooms");
	Result.Add("CustomizeBinLocationWarehousing");
	Result.Add("UseWarehouseManagemantSystemForGoodsSurplusesShortages");
	Result.Add("WarehouseStore");
	Result.Add("Parent");
	Result.Add("SelectGroup");
	Result.Add("RetailPriceType;RetailPriceType,UseTheRetailPriceView");
	Result.Add("SpecialPriceType;SpecialPriceTypePresentation,UseAnIndividualViewOfThePrice");
	Result.Add("UseGoodsIssueNoteStatuses");
	Result.Add("UseGoodsReceiptNoteStatuses");
	Result.Add("StartDateOfWarehouseManagemantSystemForGoodsIssue");
	Result.Add("StartDateOfWarehouseManagemantSystemForGoodsReceipt");
	Result.Add("StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages");
	Result.Add("StartDateOfWareroomUse");
	Result.Add("StartDateOfUsingWarehouseBinSystem");
	Result.Add("ControlQualityOfReceivedGoods");
	
	Result.Add("StoreSupportsOrderAssembly;StoreSupportsOrderAssembly");
	Result.Add("StoreSupportsDeliveryByOwnCouriers;StoreSupportsDeliveryByOwnCouriers");
	Result.Add("OrderAssemblyStartDate;OrderAssemblyStartDate");
	Result.Add("StartDateOfDeliveryByOwnCouriers;StartDateOfDeliveryByOwnCouriers");
	Result.Add("ShopFloorStockroom;Shop");
	Result.Add("Department");
	                                                         
	Return Result;

EndFunction

// Returns a retail warehouse if one retail warehouse is found, otherwise it returns an empty link.
//
//	Returns:
//		CatalogRef.Warehouses - retail warehouse.
//
Function DefaultRetailWarehouse() Export
	
	Query = New Query(
	"SELECT ALLOWED TOP 2
	|	Warehouses.Ref AS Warehouse
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	(NOT Warehouses.DeletionMark)
	|	AND Warehouses.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)");
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 
	   And Selection.Next()
	Then
		Warehouse = Selection.Warehouse;
	Else
		Warehouse = Catalogs.Warehouses.EmptyRef();
	EndIf;
	
	Return Warehouse;

EndFunction 

// Returns a retail warehouse if one retail warehouse is found, otherwise it returns an empty link.
//
//	Parameters:
//		ConsiderWarehouseGroups - Boolean - if TRUE, but a group of warehouses that can be selected in documents can be returned.
//						otherwise, only a specific warehouse is returned if it is the only one in the directory
//		ExcludeGroupsAvailableInOrders - Boolean - If you take into account the Warehouse group = TRUE, then this parameter allows you to exclude from the analysis
//						groups of warehouses that can only be selected in orders
//	Returns:
//		CatalogRef.Warehouses - retail warehouse.
//
Function DefaultWarehouse(ConsiderWarehouseGroups = False, ExcludeGroupsAvailableInOrders = False) Export
	
	If ConsiderWarehouseGroups Then
		
		Query = New Query("
		|SELECT ALLOWED TOP 2
		|	Table.Ref AS Warehouse
		|FROM
		|	Catalog.Warehouses AS Table
		|WHERE
		|	NOT Table.DeletionMark
		|	AND Table.SelectGroup IN (&SelectWarehouseGroup)
		|");
		
		Query.SetParameter("SelectWarehouseGroup", OptionsForSelectingWarehouseGroup(ExcludeGroupsAvailableInOrders));
		
	Else
		
		Query = New Query("
		|SELECT ALLOWED TOP 2
		|	Table.Ref AS Warehouse
		|FROM
		|	Catalog.Warehouses AS Table
		|WHERE
		|	(NOT Table.DeletionMark)
		|	AND (NOT Table.IsFolder)
		|");
		
	EndIf;
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count() = 1 Then
		Warehouse = Selection.Warehouse;
	Else
		Warehouse = Catalogs.Warehouses.EmptyRef();
	EndIf;
	
	Return Warehouse;
	
EndFunction

// Checks that the warehouse has disabled the control of free balances
//
// Parameters:
//  Warehouse	 - 	CatalogRef.Warehouses - link to the warehouse.
// 
// Returns:
//  Boolean - a sign that the inventory control is disabled.
//
Function InventoryControlDisabled(Warehouse) Export
	
	Query = New Query(
	"SELECT TOP 1
	|	1 AS Result
	|FROM
	|	InformationRegister.SetUpSupplyControl AS Setting
	|WHERE
	|	Setting.Warehouse = &Warehouse
	|	AND Setting.AvailableStockControl");
	
	Query.SetParameter("Warehouse", Warehouse);
	
	Return Query.Execute().IsEmpty();
	
EndFunction

// The function returns the accounting view of warehouse prices
//
// Parameters:
//  Warehouse	 - CatalogRef.Warehouses	 - the warehouse for which the accounting type of price is determined.
// 
// Returns:
//  CatalogRef.TypesOfPrices - link to the accounting type of the warehouse price.
//
Function AccountingPriceType(Warehouse) Export
	Var PriceKind;
	
	If GetFunctionalOption("UseSeveralPriceTypes") And ValueIsFilled(Warehouse) Then
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	Warehouses.AccountingPriceType
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref = &Warehouse";
		Query.SetParameter("Warehouse", Warehouse);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			PriceKind = Selection.AccountingPriceType;
		EndIf;
		
	EndIf;
	
	Return Catalogs.TypesOfPrices.DefaultPriceType(PriceKind);
	
EndFunction

// This function returns the source of price information for printing the warehouse
//
// Parameters:
//  Warehouse	 - CatalogRef.Warehouses	 - the warehouse for which the accounting type of price is determined.
// 
// Returns:
//  EnumRef.SourcesOfPriceInformationForPrinting - the default enumeration value for the warehouse.
//
Function SourseOfInformationAboutPricesForPrinting(Warehouse) Export
	If Not ValueIsFilled(Warehouse) Then
		Return Enums.SourcesOfPriceInformationForPrinting.EmptyRef();
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	Warehouses.SourseOfInformationAboutPricesForPrinting
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref = &Warehouse";
	Query.SetParameter("Warehouse",Warehouse);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.SourseOfInformationAboutPricesForPrinting;
	Else
		Return Enums.SourcesOfPriceInformationForPrinting.EmptyRef();
	EndIf;
EndFunction

// Checks in privileged mode whether the directory item is a warehouse group.
//	
//	Parameters:
//		Warehouse - CatalogRef.Warehouses - the directory element that is being checked for
//	Returns:
// 		Boolean 
//
Function IsFolder(Warehouse) Export
	
	If Not ValueIsFilled(Warehouse) Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Return Common.ObjectAttributeValue(Warehouse, "IsFolder");
	
EndFunction 

// Checks in privileged mode whether a directory item is a warehouse group, and
//  warehouses can be specified in the table parts of sales documents.
//
// Parameters:
//  Warehouse	 - CatalogRef.Warehouses	 - the directory element that is being checked.
// 
// Returns:
//  Boolean - a warehouse is a group of warehouses.
//
Function ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse) Export
	
	If ValueIsFilled(Warehouse) 
		And GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments") Then
		Return Catalogs.Warehouses.IsFolder(Warehouse);
	Else
		Return False;
	EndIf;
	
EndFunction 

// Checks in privileged mode whether the directory element is a warehouse group, and
//  warehouses can be specified in the table parts of purchase documents.
//
// Parameters:
//  Warehouse	 - CatalogRef.Warehouses	 - The warehouse to get the attribute for.
// 
// Returns:
//  Boolean - a warehouse is a group of warehouses. Warehouses of this group can be specified in the tabular part
//  of the purchase document.
//
Function ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Warehouse) Export
	
	If ValueIsFilled(Warehouse) 
		And GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") Then
		Return Catalogs.Warehouses.IsFolder(Warehouse);
	Else
		Return False;
	EndIf;
	
EndFunction 

// Checks whether a warehouse is included in a warehouse group.
// 
// Parameters:
//  GroupOfWarehouses - CatalogRef.Warehouses - warehouse group
//  Warehouse - CatalogRef.Warehouses - 
// 
// Returns:
//  Boolean
Function WarehouseInGroup(GroupOfWarehouses, Warehouse) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CatWarehouses.Ref
	|FROM
	|	Catalog.Warehouses AS CatWarehouses
	|WHERE
	|	Ref = &Warehouse
	|	AND CatWarehouses.Ref IN HIERARCHY (&GroupOfWarehouses)
	|";
	Query.SetParameter("GroupOfWarehouses", GroupOfWarehouses);
	Query.SetParameter("Warehouse",         Warehouse);
	
	If Query.Execute().IsEmpty() Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Returns an array of possible (according to the FO settings) options for selecting a warehouse group.
//
// Parameters:
// 		ExcludeGroupsAvailableInOrders - Boolean - indicates that the array should not include the allow Order value.
//
// Returns:
// 		Array - contains the enumeration values of the selected group of warehouses for which warehouses should be selected.
//
Function OptionsForSelectingWarehouseGroup(ExcludeGroupsAvailableInOrders) Export
	
	SelectWarehouseGroup = New Array();
	SelectWarehouseGroup.Add(Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices);
	If Not ExcludeGroupsAvailableInOrders Then
		SelectWarehouseGroup.Add(Enums.SelectWarehouseGroup.AllowInOrders);
	EndIf;
	
	Return SelectWarehouseGroup;
	
EndFunction

// Returns an array of references to the warehouse groups that the specified warehouse belongs to in the hierarchy.
//	
//	Parameters:
//		Warehouse - CatalogRef.Warehouses - warehouse to get an array of groups for
//	Returns:
//		Array - an array of links to groups whose hierarchy includes the warehouse.
//
Function FolderHierarchy(Warehouse) Export
	SetPrivilegedMode(True);
	
	GroupsArray1 = New Array;
	
	Group = Common.ObjectAttributeValue(Warehouse, "Parent");
	
	While ValueIsFilled(Group) Do
		GroupsArray1.Add(Group);
		Group = Common.ObjectAttributeValue(Group, "Parent");
	EndDo;

	Return GroupsArray1; 
	
EndFunction

// Returns the request text for documents that depend on the use of the order scheme when received.
//
// Returns:
//	String - the text of the request for documents that depend on the use of the order scheme upon receipt.
//
Function TextOfRequestForDocumentsThatDependOnOrderSchemeUponReceipt() Export
	DetailsList1 = New Array; // Array of See ObjectDetails
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "ReturnOfGoodsFromCustomer";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "PurchaseOrder";
	LongDesc.FieldNameDate = "TS.DateOfReceipt";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "RequestForReturnOfGoodsFromCustomer";
	LongDesc.FieldNameDate = "TS.DateOfReceipt";
	LongDesc.TSName = "ReturnedGoods";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "PurchaseAdjustment";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	LongDesc.TSName = "Discrepancies";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "InventoryTransfer";
	LongDesc.WarehouseFieldName = "Header.DestinationWarehouse";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "VendorInvoice";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsReceiptForStorage";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "OtherGoodsRecordingAsReceived";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "AssemblyFromComponents";
	DetailsList1.Add(LongDesc);
	
	Return TextOfRequestToCalculateRecommendedStartDateForNewAccountingSchemeInWarehouse(DetailsList1);
EndFunction

// Returns the request text for documents that depend on the use of the order scheme for shipment.
//
// Returns:
//	String - the text of the request for documents that depend on the use of the order scheme during shipment.
//
Function RequestTextForDocumentsThatDependOnShippingOrderScheme() Export
	DetailsList1 = New Array;
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "InventoryConsumption";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "ReturnOfGoodsToVendor";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsShipmentFromStorage";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "InventoryTransfer";
	LongDesc.WarehouseFieldName = "Header.SourceWarehouse";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "TransferOrder";
	LongDesc.WarehouseFieldName = "Header.SourceWarehouse";
	LongDesc.FieldNameDate = "TS.ShipmentStart";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "CustomerInvoice";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "AssemblyFromComponents";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "RequestForReturnOfGoodsFromCustomer";
	LongDesc.FieldNameDate = "TS.DateOfShipment";
	LongDesc.TSName = "SubstituteGoods";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "ByAssemblyDisassemblyOrder";
	LongDesc.FieldNameDate = "Header.AssemblyDisassemblyStart";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "InventoryConsumptionOrder";
	LongDesc.FieldNameDate = "TS.DateOfShipment";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "SalesOrder";
	LongDesc.FieldNameDate = "TS.DateOfShipment";
	DetailsList1.Add(LongDesc);
	
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "OrderOfMaterialsForProduction";
	LongDesc.FieldNameDate = "TS.ShipmentStart";
	DetailsList1.Add(LongDesc);
	
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "SubcontractOrder2_5";
	LongDesc.FieldNameDate = "TS.DateOfShipment";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	LongDesc.TSName = "SupplyWithMaterialsAndWorks";
	DetailsList1.Add(LongDesc);
	
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "MaterialProviderOrder2_5";
	LongDesc.TSName = "ManufacturedProduct";
	LongDesc.FieldNameDate = "TS.DateOfShipment";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	DetailsList1.Add(LongDesc);
	
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "RMOrder";
	LongDesc.FieldNameDate = "Header.StartDate";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	LongDesc.TSName = "MaterialsAndWorks";
	DetailsList1.Add(LongDesc);
	

	Return TextOfRequestToCalculateRecommendedStartDateForNewAccountingSchemeInWarehouse(DetailsList1);
EndFunction

// Returns the request text for documents that depend on the use of the order scheme when reflecting surpluses and shortages.
//
// Returns:
//	String - the text of the request for documents that depend on the use of the order scheme when reflecting surpluses, shortages.
//
Function TextOfRequestForDocumentsThatDependOnOrderSchemeWhenReflectingSurplusesShortages() Export
	DetailsList1 = New Array;
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "PurchaseAdjustment";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	LongDesc.TSName = "Discrepancies";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "SaleAdjustment";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	LongDesc.TSName = "Discrepancies";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "InventorySurplusRecognition";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsMisgrading";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "InventoryRecount";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsDamage";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "WriteOffOfGoodsShortages";
	DetailsList1.Add(LongDesc);
	
	Return TextOfRequestToCalculateRecommendedStartDateForNewAccountingSchemeInWarehouse(DetailsList1);
EndFunction

// Returns the request text for documents that depend on the use of storage facilities.
// 
// Returns:
//  String - the text of the request for documents that depend on the use of storage facilities.
//
Function RequestTextForDocumentsThatDependOnUseOfStorageFacilities() Export
	DetailsList1 = New Array;
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsSurplusesNote";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsShortageNote";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "DamageNote";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "InventoryAdjustmentGoodsShipmentOrder";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "RetailSalesReport";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "InventoryRecount";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsReceiptNote";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsIssueNote";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "SetStorageBinLocks";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "CashRegisterReceipt";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "CashRegisterReceiptReturn";
	DetailsList1.Add(LongDesc);
	
	Return TextOfRequestToCalculateRecommendedStartDateForNewAccountingSchemeInWarehouse(DetailsList1);
EndFunction

// Returns the request text for documents that depend on the use of address storage of balances.
//
// Parameters:
//	SelectByRoom - Boolean - True - indicates that you need to filter documents by storage space.
//
// Returns:
//	String - the text of the request for documents that depend on the use of address storage of balances.
//
Function RequestTextForDocumentsThatDependOnUseOfAddressStorage(SelectByRoom = False) Export
	
	DetailsList1 = New Array;
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsSurplusesNote";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsShortageNote";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "DamageNote";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsTransferNote";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "InventoryAdjustmentGoodsShipmentOrder";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "InventoryRecount";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsReceiptNote";
	DetailsList1.Add(LongDesc);
	
	LongDesc = ObjectDetails();
	LongDesc.Name = "GoodsIssueNote";
	LongDesc.FieldNameDate = "Header.DateOfShipment";
	DetailsList1.Add(LongDesc);
	
	Return TextOfRequestToCalculateRecommendedStartDateForNewAccountingSchemeInWarehouse(DetailsList1,SelectByRoom);
	
EndFunction

// Enabling maintenance of expense order statuses for all warehouses
//
Procedure EnableUseOfSpendingOrderStatuses() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	NOT Warehouses.IsFolder
	|	AND Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|	AND NOT Warehouses.UseGoodsIssueNoteStatuses";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		WarehouseObject = Selection.Ref.GetObject(); // CatalogObject.Warehouses
		WarehouseObject.UseGoodsIssueNoteStatuses = True;
		WarehouseObject.Write();
		
	EndDo;
	
EndProcedure

// Checks the possibility and sets an individual price list for the object.
// 
// Parameters:
// 	Ref - CatalogRef.Warehouses - Link to the price list column.
// 	PricesKind - CatalogRef.TypesOfPrices - Link to the price list column.
// Returns:
// 	Boolean - The result of the execution.
Function InstallIPL(Ref, PricesKind) Export
	OperationResult = False;
	
	CatalogObject = Ref.GetObject();
	ThisIsRetailWarehouse = (CatalogObject.WarehouseStore = Enums.TypesOfWarehouses.RetailStore);
	If ValueIsFilled(CatalogObject.SpecialPriceType) Or Not ThisIsRetailWarehouse Then
		OperationResult = False;
		
		MessageTextTemplate = NStr("vi = 'Chưa đóng gói dạng giá riêng đối với kho bãi ""%ObjectName_1%"" do nguyên nhân: %Cause%';
									|ru = 'Не произведена установка индивидуального виды цен для склада ""%ObjectName_1%"" по причине: %Cause%';
									|en = 'The individual price types have not been set for the warehouse ""%ObjectName_1%"". Reason: %Cause%'; fa = 'The individual price types have not been set for the warehouse ""%ObjectName_1%"". Reason: %Cause%';
									|it = 'Non è stato impostato alcun tipo di prezzo individuale per il magazzino ""%ObjectName_1%"" a causa di: %Cause%';
									|pl = 'Nie wykonano ustawienia indywidualnego rodzaju cen dla magazynu ""%ObjectName_1%"" z powodu: %Cause%';
									|tr = '""%ObjectName_1%"" ambarı için özelleştirilmiş fiyat türünün yapılandırılamama nedeni: %Cause%'");
		MessageText = StrReplace(MessageTextTemplate, "%ObjectName_1%", CatalogObject.Description);
		If ValueIsFilled(CatalogObject.SpecialPriceType) Then
			MessageText = StrReplace(MessageText, "%Cause%", "u history__ already is_specified individual_ kind prices_!");
		Else	
			MessageText = StrReplace(MessageText, "%Cause%", "warehouse not retail_2!");
		EndIf;
		
		Raise MessageText;
	Else	
		CatalogObject.SpecialPriceType = PricesKind;
		SetPrivilegedMode(True);
		CatalogObject.Write();
		SetPrivilegedMode(False);
		OperationResult = True;
	EndIf;
	
	Return OperationResult;
EndFunction

// Deletes the individual price list for the item.
// 
// Parameters:
// 	Ref - CatalogRef.Warehouses - Link to the price list column.
// Returns:
// 	Boolean - The result of the execution.
Function DeleteIPL(Ref) Export
	OperationResult = False;	
	
	CatalogObject = Ref.GetObject();
	CatalogObject.SpecialPriceType = Catalogs.TypesOfPrices.EmptyRef();
	SetPrivilegedMode(True);
	CatalogObject.Write();
	SetPrivilegedMode(False);
	
	OperationResult = True;
	
	Return OperationResult;
EndFunction
 
#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsFolder OR
	|	ValueAllowed(Ref)";
	
	Restriction.TextForExternalUsers1 =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region ToAccessWarehouseProperties

// Returns warehouse properties
//
// Parameters:
//	Warehouses - Array, CatalogRef.Warehouses - warehouses for which properties are defined
//
// Returns:
//	Map - keys are references to warehouses, values are a structure of property values
//
Function WarehouseProperties_(Warehouses) Export
	
	WarehouseData_2 = New Map;
	
	If TypeOf(Warehouses) = Type("CatalogRef.Warehouses") Then
		WarehouseArray = New Array;
		WarehouseArray.Add(Warehouses);
	Else
		WarehouseArray = Warehouses;		 
	EndIf;	
	
	EmptyWarehouse = Catalogs.Warehouses.EmptyRef();
	If WarehouseArray.Find(EmptyWarehouse) <> Undefined Then
	
		PropertyStructure = New Structure;
		PropertyStructure.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
		PropertyStructure.Insert("ShopFloorStockroom", False);
		
		WarehouseData_2.Insert(EmptyWarehouse, PropertyStructure);
		
		If WarehouseArray.Count() = 1 Then
			Return WarehouseData_2;
		EndIf;	
			
	EndIf;
		
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Warehouses.Ref AS Ref,
	|	Warehouses.Department AS Department,
	|	Warehouses.ShopFloorStockroom AS ShopFloorStockroom
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN (&WarehouseArray)";
	
	Query.SetParameter("WarehouseArray", WarehouseArray);
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		PropertyStructure = New Structure;
		PropertyStructure.Insert("Department");
		PropertyStructure.Insert("ShopFloorStockroom");
		
		FillPropertyValues(PropertyStructure, Selection);
		
		WarehouseData_2.Insert(Selection.Ref, PropertyStructure);		
		
	EndDo;
	
	Return WarehouseData_2;
	
EndFunction	

// Returns default values for warehouse parameters.
// 
// Returns:
//  Structure - Default:
// * Ref - CatalogRef.Warehouses - 
// * UseBinLocationWarehousing - Boolean - 
// * UseBinLocationWarehousingForInformation - Boolean - 
// * UseWarehouseManagemantSystemForGoodsIssue - Boolean - 
// * UseWarehouseManagemantSystemForGoodsSurplusesShortages - Boolean - 
// * UseWarehouseManagemantSystemForGoodsReceipt - Boolean - 
// * UseItemsBatch - Boolean - 
// * UseWarerooms - Boolean - 
// * RealTimeStockControl - Boolean - 
// * CustomizeBinLocationWarehousing - EnumRef.SettingsOfBinLocationWarehousing - 
// * WarehouseStore - EnumRef.TypesOfWarehouses - 
// * WarehouseZoneUsage - EnumRef.UseIsDeterminedInWarerooms - 
// * UseGoodsIssueNoteStatuses - Boolean - 
// * UseGoodsReceiptNoteStatuses - Boolean - 
// * UseInventoryRecountStatuses - Boolean - 
// * StartDateOfWarehouseManagemantSystemForGoodsIssue - Date - 
// * StartDateOfWarehouseManagemantSystemForGoodsReceipt - Date - 
// * StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages - Date - 
// * StartDateOfWareroomUse - Date - 
// * StartDateOfUsingWarehouseBinSystem - Date - 
// * UseCostAccountingByBatches - Boolean - 
// * AvailableStockControl - Boolean - 
// * CustodyWarehouse - Boolean - 
// * DepositoryKind - EnumRef.DepositaryKinds - 
// * Depository - Undefined - 
// * CustodyPeriod - Number - 
// * CustodyUntilCalledFor - Boolean - 
// * GoodsStorageConditions - String - 
// * ShopFloorStockroom - Boolean - 
Function DefaultValues() Export
	
	StructureOfValues = New Structure;
	
	StructureOfValues.Insert("Ref", Catalogs.Warehouses.EmptyRef());
	StructureOfValues.Insert("UseBinLocationWarehousing", False);
	StructureOfValues.Insert("UseBinLocationWarehousingForInformation", False);
	StructureOfValues.Insert("UseWarehouseManagemantSystemForGoodsIssue", False);
	StructureOfValues.Insert("UseWarehouseManagemantSystemForGoodsSurplusesShortages", False);
	StructureOfValues.Insert("UseWarehouseManagemantSystemForGoodsReceipt", False);
	StructureOfValues.Insert("UseItemsBatch", False);
	StructureOfValues.Insert("UseWarerooms", False);
	StructureOfValues.Insert("RealTimeStockControl", False);
	StructureOfValues.Insert("CustomizeBinLocationWarehousing", Enums.SettingsOfBinLocationWarehousing.DontUse);
	StructureOfValues.Insert("WarehouseStore", Enums.TypesOfWarehouses.WholesaleWarehouse);
	StructureOfValues.Insert("WarehouseZoneUsage", Enums.UseIsDeterminedInWarerooms.DontUse);
	StructureOfValues.Insert("UseGoodsIssueNoteStatuses", False);
	StructureOfValues.Insert("UseGoodsReceiptNoteStatuses", False);
	StructureOfValues.Insert("UseInventoryRecountStatuses", False);
	StructureOfValues.Insert("StartDateOfWarehouseManagemantSystemForGoodsIssue", '00010101');
	StructureOfValues.Insert("StartDateOfWarehouseManagemantSystemForGoodsReceipt", '00010101');
	StructureOfValues.Insert("StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages", '00010101');
	StructureOfValues.Insert("StartDateOfWareroomUse", '00010101');
	StructureOfValues.Insert("StartDateOfUsingWarehouseBinSystem", '00010101');
	StructureOfValues.Insert("UseCostAccountingByBatches", False);
	StructureOfValues.Insert("AvailableStockControl", False);
	StructureOfValues.Insert("CustodyWarehouse", False);
	StructureOfValues.Insert("DepositoryKind", Enums.DepositaryKinds.OwnCompany);
	StructureOfValues.Insert("Depository", Undefined);
	StructureOfValues.Insert("CustodyPeriod", 0);
	StructureOfValues.Insert("CustodyUntilCalledFor", False);
	StructureOfValues.Insert("GoodsStorageConditions", "");
	StructureOfValues.Insert("ShopFloorStockroom", False);
	
	Return StructureOfValues
	
EndFunction

// Generates the current accounting parameters for the warehouse.
//
// Parameters:
//	Warehouses - Array of CatalogRef.Warehouses, CatalogRef.Warehouses, Undefined - warehouses for which accounting parameters are defined
// 
// Returns:
// 	ValueTable - Table of values with columns:
//		* Ref - CatalogRef.Warehouses
//		* Presentation - String
//		* UseBinLocationWarehousing - Boolean
//		* UseBinLocationWarehousingForInformation - Boolean
//		* UseWarehouseManagemantSystemForGoodsIssue - Boolean
//		* UseWarehouseManagemantSystemForGoodsSurplusesShortages - Boolean
//		* UseWarehouseManagemantSystemForGoodsReceipt - Boolean
//		* UseItemsBatch - Boolean
//		* UseWarerooms - Boolean
//		* RealTimeStockControl - Boolean
//		* CustomizeBinLocationWarehousing - EnumRef.SettingsOfBinLocationWarehousing
//		* WarehouseStore - EnumRef.TypesOfWarehouses
//		* WarehouseZoneUsage - EnumRef.UseIsDeterminedInWarerooms
//		* UseGoodsIssueNoteStatuses - Boolean
//		* UseGoodsReceiptNoteStatuses - Boolean
//		* UseInventoryRecountStatuses - Boolean
//		* StartDateOfWarehouseManagemantSystemForGoodsIssue - Date
//		* StartDateOfWarehouseManagemantSystemForGoodsReceipt - Date
//		* StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages - Date
//		* StartDateOfWareroomUse - Date
//		* StartDateOfUsingWarehouseBinSystem - Date
//		* UseCostAccountingByBatches - Boolean
//		* AvailableStockControl - Boolean
//		* CustodyWarehouse - Boolean
//		* DepositoryKind - EnumRef.DepositaryKinds
//		* Depository - CatalogRef.Counterparties, CatalogRef.Companies - 
//		* CustodyPeriod - Number
//		* CustodyUntilCalledFor - Boolean
//		* GoodsStorageConditions - String
//		* ShopFloorStockroom - Boolean
Function CurrentAccountingParameters(Warehouses = Undefined) Export
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED
		|	Warehouses.Ref AS Ref,
		|	Warehouses.Presentation AS Presentation,
		|	Warehouses.UseBinLocationWarehousing AS UseBinLocationWarehousing,
		|	Warehouses.UseBinLocationWarehousingForInformation AS UseBinLocationWarehousingForInformation,
		|	Warehouses.UseWarehouseManagemantSystemForGoodsIssue AS UseWarehouseManagemantSystemForGoodsIssue,
		|	Warehouses.UseWarehouseManagemantSystemForGoodsSurplusesShortages AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
		|	Warehouses.UseWarehouseManagemantSystemForGoodsReceipt AS UseWarehouseManagemantSystemForGoodsReceipt,
		|	Warehouses.UseItemsBatch AS UseItemsBatch,
		|	Warehouses.UseWarerooms AS UseWarerooms,
		|	Warehouses.RealTimeStockControl AS RealTimeStockControl,
		|	Warehouses.CustomizeBinLocationWarehousing AS CustomizeBinLocationWarehousing,
		|	Warehouses.WarehouseStore AS WarehouseStore,
		|	Warehouses.WarehouseZoneUsage AS WarehouseZoneUsage,
		|	Warehouses.UseGoodsIssueNoteStatuses AS UseGoodsIssueNoteStatuses,
		|	Warehouses.UseGoodsReceiptNoteStatuses AS UseGoodsReceiptNoteStatuses,
		|	Warehouses.UseInventoryRecountStatuses AS UseInventoryRecountStatuses,
		|	Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue AS StartDateOfWarehouseManagemantSystemForGoodsIssue,
		|	Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt AS StartDateOfWarehouseManagemantSystemForGoodsReceipt,
		|	Warehouses.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages AS StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages,
		|	Warehouses.StartDateOfWareroomUse AS StartDateOfWareroomUse,
		|	Warehouses.StartDateOfUsingWarehouseBinSystem AS StartDateOfUsingWarehouseBinSystem,
		|	Warehouses.UseCostAccountingByBatches AS UseCostAccountingByBatches,
		|	Warehouses.AvailableStockControl AS AvailableStockControl,
		|	Warehouses.CustodyWarehouse AS CustodyWarehouse,
		|	Warehouses.DepositoryKind AS DepositoryKind,
		|	Warehouses.Depository AS Depository,
		|	Warehouses.CustodyPeriod AS CustodyPeriod,
		|	Warehouses.CustodyUntilCalledFor AS CustodyUntilCalledFor,
		|	Warehouses.GoodsStorageConditions AS GoodsStorageConditions,
		|	Warehouses.ShopFloorStockroom AS ShopFloorStockroom
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	CASE
		|		WHEN &InAllWarehouses THEN
		|			TRUE
		|	ELSE
		|		Warehouses.Ref IN (&Warehouses)
		|	END
		|	AND NOT Warehouses.IsFolder
		|	AND NOT Warehouses.DeletionMark";
	
	Query.SetParameter("Warehouses", Warehouses);
	Query.SetParameter("InAllWarehouses", Warehouses = Undefined);
	QueryResult = Query.Execute().Unload();
	
	Return QueryResult;
EndFunction

// Generates a text description of the set parameters.
// 
// Parameters:
// 	Warehouse - CatalogRef.Warehouses - link to the warehouse.
// 	ValidityDate - Date - period of validity of settings.
// 	CurrentAccountingParameters - ValueTableRow of See CurrentAccountingParameters
// 	
// Returns:
// 	String - Description of the current parameters in a string.
Function DescriptionOfActiveParameters(Warehouse, ValidityDate = Undefined, CurrentAccountingParameters = Undefined) Export
	
	If CurrentAccountingParameters = Undefined Then
		CurrentAccountingParametersForWarehouses = CurrentAccountingParameters(Warehouse);
		If CurrentAccountingParametersForWarehouses.Count() > 0 Then
			CurrentAccountingParameters = CurrentAccountingParametersForWarehouses[0];
		Else
			CurrentAccountingParameters = DefaultValues();
		EndIf;
	EndIf;
	
	If ValidityDate = Undefined Then
		ValidityDate = CurrentSessionDate();
	EndIf;
	
	StringPattern_ = "%1: %2." + Chars.LF;
	StringPatternBoolean = "%1." + Chars.LF;
	
	SettingsDescriptionString = StrTemplate(StringPattern_, 
		NStr("vi = 'Kiểu kho';
			|ru = 'Тип склада';
			|en = 'Warehouse type'; fa = 'نوع انبار';
			|it = 'Tipo di magazzino';
			|pl = 'Typ magazynu';
			|tr = 'Ambar tipi'"),
		CurrentAccountingParameters.WarehouseStore);
	
	If CurrentAccountingParameters.AvailableStockControl Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean, 
			NStr("vi = 'Đã bật kiểm soát số dư tùy ý';
				|ru = 'Включен контроль свободных остатков';
				|en = 'Available inventory control is enabled'; fa = 'Available inventory control is enabled';
				|it = 'Available inventory control is enabled';
				|pl = 'Available inventory control is enabled';
				|tr = 'Serbest bakiye kontrolü etkinleştirildi'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean, 
			NStr("vi = 'Đã tắt kiểm soát số dư tùy ý';
				|ru = 'Контроль свободных остатков отключен';
				|en = 'Available inventory control is disabled'; fa = 'Available inventory control is disabled';
				|it = 'Available inventory control is disabled';
				|pl = 'Available inventory control is disabled';
				|tr = 'Serbest bakiye kontrolü devre dışı bırakıldı'"));
	EndIf;
	
	If CurrentAccountingParameters.RealTimeStockControl Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean, 
			NStr("vi = 'Đã bật kiểm soát số dư hiện hoạt';
				|ru = 'Включен контроль оперативных остатков';
				|en = 'Real-time inventory control is enabled'; fa = 'Real-time inventory control is enabled';
				|it = 'Real-time inventory control is enabled';
				|pl = 'Real-time inventory control is enabled';
				|tr = 'Operasyonel bakiye kontrolü etkinleştirildi'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean, 
			NStr("vi = 'Đã tắt kiểm soát số dư hiện hoạt';
				|ru = 'Контроль оперативных остатков отключен';
				|en = 'Real-time inventory control is disabled'; fa = 'Real-time inventory control is disabled';
				|it = 'Real-time inventory control is disabled';
				|pl = 'Real-time inventory control is disabled';
				|tr = 'Operasyonel bakiye kontrolü devre dışı bırakıldı'"));
	EndIf;
	
	If CurrentAccountingParameters.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean, 
			NStr("vi = 'Sử dụng lưu trữ theo địa chỉ để lưu trữ số dư mặt hàng';
				|ru = 'Используется адресное хранение для хранения остатков номенклатуры';
				|en = 'Bin location system is enabled for goods storing'; fa = 'Bin location system is enabled for goods storing';
				|it = 'Bin location system is enabled for goods storing';
				|pl = 'Bin location system is enabled for goods storing';
				|tr = 'Depo konum sistemi, öğe bakiyelerini depolamak için kullanılır'"));
	ElsIf CurrentAccountingParameters.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.BinsReferenceAddress Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean, 
			NStr("vi = 'Sử dụng lưu trữ theo địa chỉ để sắp đặt mặt hàng theo danh mục';
				|ru = 'Используется адресное хранение для справочного размещения номенклатуры';
				|en = 'Bin location system is enabled for reference-address warehousing'; fa = 'Bin location system is enabled for reference-address warehousing';
				|it = 'Bin location system is enabled for reference-address warehousing';
				|pl = 'Bin location system is enabled for reference-address warehousing';
				|tr = 'Depo konum sistemi, referans adres depolaması için kullanılır'"));
	ElsIf CurrentAccountingParameters.CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.DeterminedByWareroomsSettings Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean, 
			NStr("vi = 'Việc sử dụng lưu trữ theo địa chỉ được xác định bằng các tùy chỉnh nhà kho';
				|ru = 'Использование адресного хранение определяется настройками помещений';
				|en = 'Bin location system usage is determined by wareroom settings'; fa = 'Bin location system usage is determined by wareroom settings';
				|it = 'Bin location system usage is determined by wareroom settings';
				|pl = 'Bin location system usage is determined by wareroom settings';
				|tr = 'Depo konum takibinin kullanımı, deponun ayarlarına göre belirlenir'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean, 
			NStr("vi = 'Không sử dụng lưu trữ theo địa chỉ';
				|ru = 'Адресное хранение не используется';
				|en = 'Bin location system is not used'; fa = 'Bin location system is not used';
				|it = 'Bin location system is not used';
				|pl = 'Bin location system is not used';
				|tr = 'Depo konum sistemi kullanılmıyor'"));
	EndIf;
	
	If CurrentAccountingParameters.CustodyWarehouse Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean, 
			NStr("vi = 'Kho bãi hoạt động theo chế độ lưu giữ hàng hóa có trách nhiệm';
				|ru = 'Склад работает в режиме ответственного хранения товаров';
				|en = 'The warehouse is used for VMI operations'; fa = 'The warehouse is used for VMI operations';
				|it = 'The warehouse is used for VMI operations';
				|pl = 'The warehouse is used for VMI operations';
				|tr = 'Depo, ürünler için satıcı tarafından yönetilen stok modunda çalışır'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean, 
			NStr("vi = 'Không sử dụng lưu giữ hàng hóa có trách nhiệm tại kho bãi';
				|ru = 'Ответственное хранения товаров на складе не используется';
				|en = 'The warehouse is not used for VMI operations'; fa = 'The warehouse is not used for VMI operations';
				|it = 'The warehouse is not used for VMI operations';
				|pl = 'The warehouse is not used for VMI operations';
				|tr = 'Depoda ürünler için satıcı tarafından yönetilen stok kullanılmıyor'"));
	EndIf;
	
	If CurrentAccountingParameters.WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.Use Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Sử dụng khu vực làm việc theo kho';
					|ru = 'Используются складские рабочие участки';
					|en = 'Warehouse areas are used'; fa = 'Warehouse areas are used';
					|it = 'Warehouse areas are used';
					|pl = 'Warehouse areas are used';
					|tr = 'Depo ambar alanları kullanılıyor'"));
	ElsIf CurrentAccountingParameters.WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.DeterminedByWareroomsSettings Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Việc sử dụng khu vực làm việc theo kho được xác định bằng các cài đặt nhà kho';
					|ru = 'Использование складских рабочих участков определяется настройками помещения';
					|en = 'Warehouse area usage is determined by wareroom settings'; fa = 'Warehouse area usage is determined by wareroom settings';
					|it = 'Warehouse area usage is determined by wareroom settings';
					|pl = 'Warehouse area usage is determined by wareroom settings';
					|tr = 'Depo ambar alanlarının kullanımı tesis ayarlarına göre belirlenir'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Không sử dụng khu vực làm việc theo kho';
					|ru = 'Складские рабочие участки не используются';
					|en = 'Warehouse areas are not used'; fa = 'Warehouse areas are not used';
					|it = 'Warehouse areas are not used';
					|pl = 'Warehouse areas are not used';
					|tr = 'Depo ambar alanları kullanılmıyor'"));
	EndIf;
	
	If CurrentAccountingParameters.UseWarehouseManagemantSystemForGoodsReceipt
		And CurrentAccountingParameters.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= ValidityDate Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Sử dụng sơ đồ hai pha khi tiếp nhận';
					|ru = 'Используется ордерная схема при поступлении';
					|en = 'Warehouse management on goods receipt is used'; fa = 'Warehouse management on goods receipt is used';
					|it = 'Warehouse management on goods receipt is used';
					|pl = 'Warehouse management on goods receipt is used';
					|tr = 'Giriş sırasında ambar yönetimi kullanılıyor'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Không sử dụng sơ đồ hai pha khi nhập hàng';
					|ru = 'Ордерная схема при поступлении не используется';
					|en = 'Warehouse management on goods receipt is not used'; fa = 'Warehouse management on goods receipt is not used';
					|it = 'Warehouse management on goods receipt is not used';
					|pl = 'Warehouse management on goods receipt is not used';
					|tr = 'Girişte sırasında ambar yönetimi kullanılmıyor'"));
	EndIf;
	
	If CurrentAccountingParameters.UseGoodsReceiptNoteStatuses
		And CurrentAccountingParameters.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= ValidityDate Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Sử dụng trạng thái phiếu nhập';
					|ru = 'Используются статусы приходных ордеров';
					|en = 'Goods receipt statuses are used'; fa = 'Goods receipt statuses are used';
					|it = 'Goods receipt statuses are used';
					|pl = 'Goods receipt statuses are used';
					|tr = 'Ambar girişi fişi durumları kullanılıyor'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Không sử dụng trạng thái phiếu nhập';
					|ru = 'Статусы приходных ордеров не используются';
					|en = 'Goods receipt statuses are not used'; fa = 'Goods receipt statuses are not used';
					|it = 'Goods receipt statuses are not used';
					|pl = 'Goods receipt statuses are not used';
					|tr = 'Ambar girişi fişi durumları kullanılmıyor'"));
	EndIf;
	
	If CurrentAccountingParameters.UseWarehouseManagemantSystemForGoodsIssue
		And CurrentAccountingParameters.StartDateOfWarehouseManagemantSystemForGoodsIssue <= ValidityDate Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Sử dụng sơ đồ hai pha khi giao hàng';
					|ru = 'Используется ордерная схема при отгрузке';
					|en = 'Warehouse management for outbound deliveries is used'; fa = 'Warehouse management for outbound deliveries is used';
					|it = 'Warehouse management for outbound deliveries is used';
					|pl = 'Warehouse management for outbound deliveries is used';
					|tr = 'Sevkiyat sırasında ambar yönetimi kullanılıyor'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Không sử dụng sơ đồ hai pha khi giao hàng';
					|ru = 'Ордерная схема при отгрузке не используется';
					|en = 'Warehouse management for outbound deliveries is not used'; fa = 'Warehouse management for outbound deliveries is not used';
					|it = 'Warehouse management for outbound deliveries is not used';
					|pl = 'Warehouse management for outbound deliveries is not used';
					|tr = 'Sevkiyat sırasında ambar yönetimi kullanılmıyor'"));
	EndIf;
	
	If CurrentAccountingParameters.UseGoodsIssueNoteStatuses
		And CurrentAccountingParameters.StartDateOfWarehouseManagemantSystemForGoodsIssue <= ValidityDate Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Sử dụng trạng thái phiếu xuất';
					|ru = 'Используются статусы расходных ордеров';
					|en = 'Goods issue statuses are used'; fa = 'Goods issue statuses are used';
					|it = 'Goods issue statuses are used';
					|pl = 'Goods issue statuses are used';
					|tr = 'Gider siparişleri durumları kullanılıyor'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Không sử dụng trạng thái phiếu xuất';
					|ru = 'Статусы расходных ордеров не используются';
					|en = 'Goods issue statuses are not used'; fa = 'Goods issue statuses are not used';
					|it = 'Goods issue statuses are not used';
					|pl = 'Goods issue statuses are not used';
					|tr = 'Gider siparişleri durumları kullanılmıyor'"));
	EndIf;
		
	If CurrentAccountingParameters.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		And CurrentAccountingParameters.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= ValidityDate Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Sử dụng sơ đồ hai pha khi phản ánh hàng thừa và hàng thiếu trong kho';
					|ru = 'Используется ордерная схема при отражении излишков и недостач товаров на складе';
					|en = 'Warehouse management is enabled for recording surplus and shortage of goods at the warehouse'; fa = 'Warehouse management is enabled for recording surplus and shortage of goods at the warehouse';
					|it = 'Warehouse management is enabled for recording surplus and shortage of goods at the warehouse';
					|pl = 'Warehouse management is enabled for recording surplus and shortage of goods at the warehouse';
					|tr = 'Ambar yönetimi, depodaki ürün fazlalıklarını ve eksikliklerini yansıtmak için kullanılıyor'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Không sử dụng sơ đồ hai pha khi phản ánh hàng thừa và hàng thiếu trong kho';
					|ru = 'Ордерная схема при отражении излишков и недостач товаров на складе не используется';
					|en = 'Warehouse management is not enabled for recording surplus and shortage of goods at the warehouse'; fa = 'Warehouse management is not enabled for recording surplus and shortage of goods at the warehouse';
					|it = 'Warehouse management is not enabled for recording surplus and shortage of goods at the warehouse';
					|pl = 'Warehouse management is not enabled for recording surplus and shortage of goods at the warehouse';
					|tr = 'Ambar yönetimi, depodaki ürün fazlalıklarını ve eksikliklerini yansıtmak için kullanılmıyor'"));
	EndIf;
	
	If CurrentAccountingParameters.UseInventoryRecountStatuses
		And CurrentAccountingParameters.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= ValidityDate Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Sử dụng trạng thái tính toán lại hàng hóa';
					|ru = 'Используются статусы пересчетов товаров';
					|en = 'Inventory count sheet statuses are used'; fa = 'Inventory count sheet statuses are used';
					|it = 'Inventory count sheet statuses are used';
					|pl = 'Inventory count sheet statuses are used';
					|tr = 'Ürünlerin stok sayımı durumları kullanılıyor'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Không sử dụng trạng thái kiểm đếm hàng hóa';
					|ru = 'Статусы пересчетов товаров не используются';
					|en = 'Inventory count sheet statuses are not used'; fa = 'Inventory count sheet statuses are not used';
					|it = 'Inventory count sheet statuses are not used';
					|pl = 'Inventory count sheet statuses are not used';
					|tr = 'Ürünlerin stok sayımı durumları kullanılmıyor'"));
	EndIf;

	If CurrentAccountingParameters.UseWarerooms
		And CurrentAccountingParameters.StartDateOfWareroomUse <= ValidityDate Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Sử dụng ghi nhận theo nhà kho';
					|ru = 'Используется учет по складским помещениям';
					|en = 'Warerooms are used'; fa = 'انبارک‌ها استفاده می‌شوند';
					|it = 'Warerooms are used';
					|pl = 'Warerooms are used';
					|tr = 'Ambar alanları muhasebesi kullanılıyor'"));
	Else
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Không sử dụng ghi nhận theo nhà kho';
					|ru = 'Учет по складским помещениям не используется';
					|en = 'Warerooms are not used'; fa = 'Warerooms are not used';
					|it = 'Warerooms are not used';
					|pl = 'Warerooms are not used';
					|tr = 'Ambar alanları muhasebesi kullanılmıyor'"));
	EndIf;
	
	Return SettingsDescriptionString
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	WarehousesServerCall.WarehousesProcessingSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndIf

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" And Not GetFunctionalOption("UseSeveralWarehouses") Then
		
		Parameters.Insert("Key", WarehousesServerCall.GetDefaultWarehouse());
		SelectedForm = "ItemForm";
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInRoomInCatalog(Parameters,StorageAddress) Export
	
	Warehouse = Parameters.Warehouse;
	Premise = Parameters.Premise;
	
	Query = New Query;
	Query.SetParameter("Warehouse", Warehouse);
	
	Query.Text =
	"SELECT
	|	StorageBins.Ref
	|FROM
	|	Catalog.StorageBins AS StorageBins
	|WHERE
	|	StorageBins.Owner = &Warehouse
	|	AND StorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CatalogObject = Selection.Ref.GetObject(); // CatalogObject.StorageBins
		CatalogObject.Premise = Premise;
		CatalogObject.Write();
	EndDo;
	
	Query.Text =
	"SELECT
	|	WarehouseZones.Ref
	|FROM
	|	Catalog.WarehouseZones AS WarehouseZones
	|WHERE
	|	WarehouseZones.Owner = &Warehouse
	|	AND WarehouseZones.Premise = VALUE(Catalog.Warerooms.EmptyRef)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CatalogObject = Selection.Ref.GetObject();  // CatalogObject.WarehouseZones
		CatalogObject.Premise = Premise;
		CatalogObject.Write();
	EndDo;
	
	Query.Text =
	"SELECT
	|	StorageAreas.Ref
	|FROM
	|	Catalog.StorageAreas AS StorageAreas
	|WHERE
	|	StorageAreas.Owner = &Warehouse
	|	AND StorageAreas.Premise = VALUE(Catalog.Warerooms.EmptyRef)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CatalogObject = Selection.Ref.GetObject();  // CatalogObject.StorageAreas
		CatalogObject.Premise = Premise;
		CatalogObject.Write();
	EndDo;
	
	Query.SetParameter("Premise", Premise);
	Query.Text =
	"SELECT
	|	GoodsPlacementRules.WarehouseGroupOfProducts,
	|	GoodsPlacementRules.WarehouseGroupOfPackages,
	|	GoodsPlacementRules.Warehouse,
	|	&Premise,
	|	GoodsPlacementRules.StorageArea,
	|	GoodsPlacementRules.Priority
	|FROM
	|	InformationRegister.GoodsPlacementRules AS GoodsPlacementRules
	|WHERE
	|	GoodsPlacementRules.Warehouse = &Warehouse
	|	AND GoodsPlacementRules.Premise = VALUE(Catalog.Warerooms.EmptyRef)";
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		WriteSetOfInformationAboutRoomInRegister(Result, Parameters, "GoodsPlacementRules");
	EndIf;
	
	Query.Text =
	"SELECT
	|	PlaceProductsInStorageBins.Products,
	|	PlaceProductsInStorageBins.Warehouse,
	|	&Premise,
	|	PlaceProductsInStorageBins.Cell,
	|	PlaceProductsInStorageBins.MainStorageBin
	|FROM
	|	InformationRegister.PlaceProductsInStorageBins AS PlaceProductsInStorageBins
	|WHERE
	|	PlaceProductsInStorageBins.Warehouse = &Warehouse
	|	AND PlaceProductsInStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)";
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		WriteSetOfInformationAboutRoomInRegister(Result, Parameters, "PlaceProductsInStorageBins");
	EndIf;
	
	Query.Text =
	"SELECT
	|	&Premise,
	|	SettingsOfBinLocationWarehouses.*
	|FROM
	|	InformationRegister.SettingsOfBinLocationWarehouses AS SettingsOfBinLocationWarehouses
	|WHERE
	|	SettingsOfBinLocationWarehouses.Warehouse = &Warehouse
	|	AND SettingsOfBinLocationWarehouses.Premise = VALUE(Catalog.Warerooms.EmptyRef)";
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		WriteSetOfInformationAboutRoomInRegister(Result, Parameters, "SettingsOfBinLocationWarehouses");
	EndIf;
	
EndProcedure

Procedure WriteSetOfInformationAboutRoomInRegister(QueryResult, Parameters, RegisterName)
	
	BeginTransaction();
	
	Try
		
		SetPlacement_ = InformationRegisters[RegisterName].CreateRecordSet();
		
		FilterWarehouse = SetPlacement_.Filter.Warehouse; // FilterItem
		FilterWarehouse.Set(Parameters.Warehouse);
		
		FilterPremise = SetPlacement_.Filter.Premise; // FilterItem
		FilterPremise.Set(Parameters.Premise);
		
		SetPlacement_.Load(QueryResult.Unload());
		SetPlacement_.Write();
		SetPlacement_.Clear();
		
		FilterWarehouse = SetPlacement_.Filter.Warehouse; // FilterItem
		FilterWarehouse.Set(Parameters.Warehouse);
		
		FilterPremise = SetPlacement_.Filter.Premise; // FilterItem
		FilterPremise.Set(Catalogs.Warerooms.EmptyRef());
		
		SetPlacement_.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode(); // To record an event in the registration Log.
		WriteLogEvent(NStr("vi = 'Điền nhà kho vào các danh mục.';
							|ru = 'Заполнение помещений в справочниках.';
							|en = 'Filling in warerooms in catalogs.'; fa = 'Filling in warerooms in catalogs.';
							|it = 'Riempimento dei locali negli elenchi.';
							|pl = 'Wypełnianie pomieszczeń w katalogach.';
							|tr = 'Kataloglarda depo doldurma.'", DefaultLanguageCode),
			EventLogLevel.Error, , ,
			DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

Function NamesOfObjectsWithEmptySpace(Warehouse) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	""StorageBins"" AS NameOfObject
	|FROM
	|	Catalog.StorageBins AS StorageBins
	|WHERE
	|	StorageBins.Owner = &Warehouse
	|	AND StorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	""WarehouseZones""
	|FROM
	|	Catalog.WarehouseZones AS WarehouseZones
	|WHERE
	|	WarehouseZones.Owner = &Warehouse
	|	AND WarehouseZones.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	""StorageAreas""
	|FROM
	|	Catalog.StorageAreas AS StorageAreas
	|WHERE
	|	StorageAreas.Owner = &Warehouse
	|	AND StorageAreas.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	""GoodsPlacementRules""
	|FROM
	|	InformationRegister.GoodsPlacementRules AS GoodsPlacementRules
	|WHERE
	|	GoodsPlacementRules.Warehouse = &Warehouse
	|	AND GoodsPlacementRules.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	""PlaceProductsInStorageBins""
	|FROM
	|	InformationRegister.PlaceProductsInStorageBins AS PlaceProductsInStorageBins
	|WHERE
	|	PlaceProductsInStorageBins.Warehouse = &Warehouse
	|	AND PlaceProductsInStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)";
	
	Query.SetParameter("Warehouse", Warehouse);
	
	Return Query.Execute().Unload().UnloadColumn("NameOfObject");
	
EndFunction

// Parameters:
// 	DetailsList1 - Array of See ObjectDetails - 
// 	SelectByRoom - Boolean -
// 	 
// Returns:
// 	String -
// 
Function TextOfRequestToCalculateRecommendedStartDateForNewAccountingSchemeInWarehouse(DetailsList1,SelectByRoom = False)
	
	ThisIsFirstOneInArray = True;
	QueryText = "";
	QueryTextTemplate2 = "
	|SELECT
	|	&MaximumDescriptionFieldNameDate AS Date
	|FROM
	|	&DocumentDescriptionName AS Header
	|	,&AttachTS
	|WHERE Header.Posted
	|	AND &DescriptionWarehouseFieldName = &Warehouse
	|	AND &SelectByRoom
	|";

	For Each LongDesc In DetailsList1 Do
		AttachTS = StrFind(LongDesc.WarehouseFieldName,"TS.") > 0 Or StrFind(LongDesc.FieldNameDate,"TS.");
		
		Text = QueryTextTemplate2;

		Text = StrReplace(Text, "&MaximumDescriptionFieldNameDate", 	"MAX(" + LongDesc.FieldNameDate + ")");
		Text = StrReplace(Text, "&DocumentDescriptionName", 			"Document." + LongDesc.Name);
		Text = StrReplace(Text, "&DescriptionWarehouseFieldName", 		LongDesc.WarehouseFieldName);
		
		ReplacementText_2 = "";
		If AttachTS Then
			ReplacementText_2 = "INNER JOIN Document." + LongDesc.Name + "."+ LongDesc.TSName + " AS TS
							|On (Header.Ref = TS.Ref)";
		EndIf;
		Text = StrReplace(Text, ",&AttachTS", ReplacementText_2);

		ReplacementText_2 = "";
		If SelectByRoom Then
			If LongDesc.Name = "GoodsTransferNote" Then
				ReplacementText_2 = "AND Header.SenderWareroom = &Premise
				|	OR Header.ReceivingWareroom = &Premise";
			Else
				ReplacementText_2 = "And " + ?(Find(LongDesc.WarehouseFieldName,"TS.") > 0,"TS.","Header.") + "Premise = &Premise";
			EndIf;
		EndIf;
		Text = StrReplace(Text, "AND &SelectByRoom", ReplacementText_2);
	
		If Not ThisIsFirstOneInArray Then
			QueryText = Text + "
				|UNION ALL" + QueryText;
		Else
			QueryText = Text;
			ThisIsFirstOneInArray = False;
		EndIf;
	EndDo;
	
	QueryText = QueryText + "
	|ORDER BY DATE DESC";
	
	Return QueryText;
	
EndFunction

// Returns:
// 	Structure - Contains:
// * FieldNameDate - String -
// * WarehouseFieldName - String -
// * TSName - String -
// * Name - String - 
//
Function ObjectDetails()
	
	LongDesc = New Structure;
	LongDesc.Insert("Name");
	LongDesc.Insert("TSName",             "Goods");
	LongDesc.Insert("WarehouseFieldName",      "Header.Warehouse");
	LongDesc.Insert("FieldNameDate",       "Header.Date");
	Return LongDesc;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.Warehouses.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a6ec615b-1bd4-4a82-b8cb-9f57e390a0fa");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.Warehouses.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Kho bãi"":';
								|ru = 'Обновление справочника ""Склады"":';
								|en = 'Update the ""Warehouse"" catalog:'; fa = 'Update the ""Warehouse"" catalog:';
								|it = 'Update the ""Warehouse"" catalog:';
								|pl = 'Update the ""Warehouse"" catalog:';
								|tr = '""Ambarlar"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.Warehouses.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.Warehouses.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.Warehouses.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not AdditionalLanguagesAreUsed Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	NOT Warehouses.Description = """"
	|	AND Warehouses.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	NOT Warehouses.Description = """"
	|	AND Warehouses.DescriptionLanguage2 = """"
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Kho bãi"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Склады"" по обработчику:';
								|en = 'Cannot process the ""Warehouse"" catalog by the handler:'; fa = 'Cannot process the ""Warehouse"" catalog by the handler:';
								|it = 'Cannot process the ""Warehouse"" catalog by the handler:';
								|pl = 'Cannot process the ""Warehouse"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Ambarlar"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TT
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Ref AS Ref,
	|	Warehouses.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON TT.Ref = Warehouses.Ref";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
					
					CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
					
				EndIf;
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
					
					CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
					
				EndIf;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
