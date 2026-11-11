
#Region Public

// Returns a structure of parameters for processing bar codes.
//
// Returns:
//	Structure:
//		* CurrentRow - Undefined
//		* ArrayOfRowsWithExciseStamps - Array of Number
//		* ArrayOfRowsWithSeries_ - Array of Number
//		* ArrayOfRowsWithSelectedBatches - Array of Number
//		* LoadingFromPDT - Boolean
//		* ToFillTheAppointment - Boolean
//		* CurrentPackingList - Undefined
//		* LabelledWHProducts - Boolean
//		* WHBarcodes - Boolean -
//		* WorkOutChangingPackingLists - Boolean
//		* ConsiderPackingLists - Boolean
//		* CalculateSets - Boolean
//		* AssortmentVerificationParameters - Undefined
//		* UnknownBarcodes - Array of Structure:
//			** Barcode - String
//			** Count - Number
//		* NonUniqueBarcodes - Map of KeyAndValue:
//			** Key - String
//			** Value - Boolean
//		* AddOnlyProductsOverAndAboveOrder - Boolean
//		* OnlyTara - Boolean
//		* ServicesOnly - Boolean
//		* OnlyGoodsAndWork - Boolean
//		* OnlyWorks - Boolean
//		* OnlyGoodsAndServices - Boolean
//		* GoodsOnly - Boolean
//		* BlockFormData - Boolean
//		* ChangeQuantity - Boolean
//		* TSName - String
//		* ColumnNamePackaging - String
//		* NotUsePackages - Boolean
//		* ColumnNameQuantity - String
//		* ActionsWithUnknownBarcodes - String
//		* TransferSpecifiedGoodsToDocument - Boolean
//		* SeriesSpecificationParameters - Undefined
//		* StructureOfActionsWithLinesFromPackingLists - Undefined
//		* StructureOfActionsWithModifiedStrings - Undefined
//		* StructureOfActionsWithAddedStrings - Undefined
//		* Barcodes - Undefined
//		* DonTSearchInCanceledRows - Boolean - True - when searching in PM, the canceled string will not be taken into account
//		* AddContainers - Boolean - If True, a container will be selected for the goods
//		* Warehouse - Undefined
//		* WarehouseGroupIsUsed - Undefined
//		* OnlyWithTransferOfProductBatchIDMaterial - Boolean
//		* UseContainersAsGoods - Boolean
//
Function BarcodeProcessingParameters() Export
	
	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("Barcodes",                                      Undefined);
	ProcessingParameters.Insert("StructureOfActionsWithAddedStrings",         Undefined);
	ProcessingParameters.Insert("StructureOfActionsWithModifiedStrings",          Undefined);
	ProcessingParameters.Insert("StructureOfActionsWithLinesFromPackingLists", Undefined);
	ProcessingParameters.Insert("SeriesSpecificationParameters",                         Undefined);
	ProcessingParameters.Insert("ActionsWithUnknownBarcodes",               "RegisterMoveToDocument");
	ProcessingParameters.Insert("TransferSpecifiedGoodsToDocument",            True);
	ProcessingParameters.Insert("ColumnNameQuantity",                           "NumberOfPackages");
	ProcessingParameters.Insert("NotUsePackages",                         False);
	ProcessingParameters.Insert("ColumnNamePackaging",                             "Package");
	ProcessingParameters.Insert("TSName",                                          "Goods");
	ProcessingParameters.Insert("ChangeQuantity",                             True);
	ProcessingParameters.Insert("BlockFormData",                         True);
	ProcessingParameters.Insert("GoodsOnly",                                   False);
	ProcessingParameters.Insert("OnlyGoodsAndWork",                            False);
	ProcessingParameters.Insert("OnlyGoodsAndServices",                            False);
	ProcessingParameters.Insert("ServicesOnly",                                   False);
	ProcessingParameters.Insert("OnlyWorks",                                   False);
	ProcessingParameters.Insert("OnlyTara",                                     False);
	ProcessingParameters.Insert("AddOnlyProductsOverAndAboveOrder",                False);
	ProcessingParameters.Insert("UnknownBarcodes",                           New Array);
	ProcessingParameters.Insert("NonUniqueBarcodes",                          New Map);
	ProcessingParameters.Insert("AssortmentVerificationParameters",                  Undefined);
	ProcessingParameters.Insert("CalculateSets",                             False);
	ProcessingParameters.Insert("ConsiderPackingLists",                      False);
	ProcessingParameters.Insert("WorkOutChangingPackingLists",           False);
	ProcessingParameters.Insert("WHBarcodes",                                   False);
	ProcessingParameters.Insert("LabelledWHProducts",                        False);
	ProcessingParameters.Insert("CurrentPackingList",                         Undefined);
	ProcessingParameters.Insert("ToFillTheAppointment",                            False);
	ProcessingParameters.Insert("LoadingFromPDT",                                  False);
	ProcessingParameters.Insert("DonTSearchInCanceledRows",                     True);
	ProcessingParameters.Insert("AddContainers",                                 True);
	ProcessingParameters.Insert("Warehouse",                                          Undefined);
	ProcessingParameters.Insert("WarehouseGroupIsUsed",                      Undefined);
	ProcessingParameters.Insert("OnlyWithTransferOfProductBatchIDMaterial",                  False);
	ProcessingParameters.Insert("UseContainersAsGoods",                True);
	
	//Return parameter
	ProcessingParameters.Insert("ArrayOfRowsWithSeries_",             New Array);
	ProcessingParameters.Insert("ArrayOfRowsWithSelectedBatches", New Array);
	ProcessingParameters.Insert("ArrayOfRowsWithExciseStamps",    New Array);
	ProcessingParameters.Insert("CurrentRow",                   Undefined);
	
	Return ProcessingParameters;
	
EndFunction

#EndRegion
