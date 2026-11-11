
#Region Public

// This procedure is called when clearing products in the device.
// Writes information to the exchange plan node.
//
// Parameters:
//  Device       - CatalogRef.Peripherals - Link to the device.
//  ExecutedSuccessfully - Boolean - Indicates whether the operation was completed successfully.
//
Procedure WhenClearingItemsInDevice(Device, ExecutedSuccessfully = True) Export
EndProcedure

// This procedure is called when goods are uploaded to the device.
// Writes information to the exchange plan node.
//
// Parameters:
//  Device       - CatalogRef.Peripherals - Link to the device.
//  StructureData - Structure
//  ExecutedSuccessfully - Boolean - Indicates whether the operation was completed successfully.
//  ExtendedUpload - Boolean - The criterion of using the extended discharge.
//
Procedure WhenUploadingGoodsToDevice(Device, StructureData, ExecutedSuccessfully = True, ExtendedUpload = False) Export
EndProcedure

#Region UnloadingGoods

// The procedure returns a structure with data in the format required for uploading the list of products to scales with label printing.
//
// Parameters:
//  DeviceParameters - Structure - the value to be filled in, see the Get Device Parameters function.
//  Device - CatalogRef.Peripherals - The device for which you want to get data.
//  OnlyChangedItems - Boolean - Flag for getting only modified data.
//
Procedure GetDataForWeights(DeviceParameters, Device, OnlyChangedItems = True) Export
EndProcedure

// The procedure returns the device parameters
//
// Parameters:
//  DeviceParameters - Structure:
//  * ExchangeRule - CatalogRef.RulesOfExchangeWithOfflinePeripherals - The exchange rule.
//  * InfobaseNode - ExchangePlanRef - the node information base.
//  * Warehouse - CatalogRef.Warehouses - warehouse.
//  * PriceKind - CatalogRef.TypesOfPrices - Type of price.
//  * SpecialPriceType - CatalogRef.TypesOfPrices - Individual type of price.
//  * EquipmentType - EnumRef.PeripheralTypes, EnumRef.OfflineEquipmentTypes - type of equipment.
//  * MaximumGoodsQuantity - Number - Maximum code.
//  * ExportChanges - Boolean - Indicates whether changes need to be uploaded.
//  Device - CatalogRef.Peripherals - Link to the device.
// 
Procedure GetDeviceParameters(DeviceParameters, Device) Export
EndProcedure

// The procedure registers changes for the device.
//
// Parameters:
//  Device - CatalogRef.Peripherals - Link to the device.
//
Procedure RecordChanges(Device) Export
EndProcedure

// The procedure fills in the structure of the price list for uploading to the KKM Offline in an extended format (with product groups)
//
Procedure FillInPriceListStructureFromUploadData(PriceListStructure, GoodsReadyForUnloading) Export
EndProcedure

#EndRegion

#Region UnloadingGoods

// The procedure updates the product table with data to be uploaded to the device.
//
// Parameters:
//  TableOfGoods - ValueTable - Table of products to be uploaded.
//  Device - CatalogRef.Peripherals - The device for which you want to get data
//  Parameters - Structure - The parameters of discharge.
//  UpdateProductCodes - Boolean - Flag for updating product codes before receiving data.
//  Barcode - String -.
//
Procedure ProductDataToUpload(TableOfGoods, Device, Parameters, UpdateProductCodes = False, Barcode = "") Export
EndProcedure

#EndRegion

#Region GoodsUnloadingRules

// The procedure updates the product table with product data for the upload rule with prices
//
// Parameters:
//  TableOfGoods - ValueTable - The products table
//  ExchangeRule - CatalogRef.RulesOfExchangeWithOfflinePeripherals - The exchange rule.
//  PriceKind - CatalogRef.TypesOfPrices - Type of price.
//  SpecialPriceType - CatalogRef.TypesOfPrices - individual view of the price.
//
Procedure DataOfGoodsUnderExchangeRule(TableOfGoods, ExchangeRule, PriceKind, SpecialPriceType) Export
EndProcedure

#EndRegion

// filling in the redefined procedures of the Manager Line Equipment module Undefined

Procedure FillInCashRegisterSettings(OfflineEquipment_, HardwareSettings) Export
EndProcedure

Procedure FillInPriceListOfCashRegister(OfflineEquipment_, PriceList, FullUpload) Export
EndProcedure

Procedure FillInPriceListOfCashRegisterByBarcode(OfflineEquipment_, PriceList, Barcode) Export
EndProcedure

Procedure DeletePriceListRegistrationAfterUploading(OfflineEquipment_) Export
EndProcedure

Procedure DownloadSalesReportsFromCashRegister(Device, SalesData, Cancel, ErrorMessage) Export
EndProcedure

Procedure DownloadContainerOpeningDataFromCashRegister(Device, DataOnOpeningContainers, Cancel, ErrorMessage) Export

	
EndProcedure

// Verifies that the transmitted value is a type of offline Cash register equipment.
//
// Parameters:
//  PeripheralType - EnumRef
//
// Returns:
//  Boolean
//
Function ThisIsTypeOfOfflineEquipmentCashRegister(PeripheralType) Export
	
	Result = False;
	Return Result;
	
EndFunction

#EndRegion

#Region Private


#Region QueriesTexts


#EndRegion

#EndRegion


