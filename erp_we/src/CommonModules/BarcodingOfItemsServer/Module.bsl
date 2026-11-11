
#Region Public

// Processes scanned barcodes:
//	- adds information about scanned barcodes to the tabular part of the Form object,
//	- calls the barcode creation assistant if they were not found in the information database.
//
// Parameters:
//	Form - ClientApplicationForm - The Form for which the scanned barcodes will be processed.
//	Object - FormDataStructure - a Form object that adds information from scanned
//									barcodes to the table part.
//	ParametersStructure - See BarcodingOfItemsClientServer.BarcodeProcessingParameters.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure ProcessBarcodes(Form, Object, ParametersStructure, CachedValues) Export
	
	// If you need to change the quantity, then you need to block the form data
	// If the block fails, an exception will be thrown.
	If ParametersStructure.ChangeQuantity
		And ParametersStructure.BlockFormData Then
		Form.LockFormDataForEdit();
	EndIf;
	
	UsePackingLists = GetFunctionalOption("UsePackingLists");
	
	Modified = False;
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	CachedValues.ProductBarcodeRegistrationRightIsAvailable = ProductBarcodeRegistrationRightIsAvailable();
	
	WeightBarCodePrefixes = SettingsValueCached.GetWeightBarCodePrefixes();
	
	If TypeOf(ParametersStructure.Barcodes) = Type("Array") Then
		ArrayOfBarcodes = ParametersStructure.Barcodes;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(ParametersStructure.Barcodes);
	EndIf;
	
	GetBarcodeData		= Not (ArrayOfBarcodes.Count() > 0
										And ArrayOfBarcodes[0].Property("Products"));
	ItemsBarcodes			= New Array;
	PreviouslyUnencashedBarcodes	= New Array;
	
	For Each CurBarcode In ArrayOfBarcodes Do
		CurBarcode.Barcode = Upper(TrimAll(CurBarcode.Barcode));
		InformationRegisters.ItemsBarcodes.ConvertWeightBarcode(CurBarcode, WeightBarCodePrefixes);
		
		If GetBarcodeData Then
			If Not ValueIsFilled(CachedValues.Barcodes[CurBarcode.Barcode])
				Or CachedValues.Barcodes[CurBarcode.Barcode].UnknownBarcode Then
				
				PreviouslyUnencashedBarcodes.Add(CurBarcode.Barcode);
				
			EndIf;
		Else
			ItemsBarcodes.Add(CurBarcode);
			PreviouslyUnencashedBarcodes.Add(CurBarcode.Barcode);
		EndIf;
	EndDo;
	
	If PreviouslyUnencashedBarcodes.Count() > 0 Then
		If GetBarcodeData Then
			InformationRegisters.ItemsBarcodes.GetDataOnBarcodesAdvanced(CachedValues,
																						PreviouslyUnencashedBarcodes);
		Else
			InformationRegisters.ItemsBarcodes.GetDataOnItemBarcodes(CachedValues,
																							ItemsBarcodes);
		EndIf;
		
		If UsePackingLists
			And ParametersStructure.ConsiderPackingLists Then
			
			Documents.PackingList.AddDataOnBarcodes(CachedValues, PreviouslyUnencashedBarcodes);
			
		EndIf;
	EndIf;
	
	// TS strings for batch processing.
	AddedProducts        = New Array;
	ModifiedGoods         = New Array;
	Added1Components = New Array;
	Modified1Components  = New Array;
	RowsToProcess     = New Array;
	
	PackagingByTSLines = New Structure;
	PackagingByTSLines.Insert("AddedPackaging", New Array);
	PackagingByTSLines.Insert("ModifiedPackaging", New Array);
	
	// TS row data for post-processing.
	RowDataTS                     = New Map;
	RowDataTSComponents        = New Map;
	LinesForProcessingBatches           = New Array;
	ArrayOfStringsWithSets              = New Array;
	ArrayOfRowsWithMultipleSheetsToProcess = New Array;
	
	CurrentRow = Undefined;
	
	If ParametersStructure.AssortmentVerificationParameters <> Undefined Then
		CheckAssortment_ = ProductRangeServerCached.ControlProductRange(
			ParametersStructure.AssortmentVerificationParameters.Warehouse,
			ParametersStructure.AssortmentVerificationParameters.Date);
		ParametersStructure.AssortmentVerificationParameters.Insert("CheckAssortment_", CheckAssortment_);
	EndIf;
	
	Assignments = Assignments(Object, ParametersStructure, CachedValues.Barcodes);
	
	UseItemsBatch = ParametersStructure.SeriesSpecificationParameters <> Undefined
		And ParametersStructure.SeriesSpecificationParameters.UseItemsBatch;
	AddPackagingByTSLine = GetFunctionalOption("UseReusablePackage")
		And ParametersStructure.AddContainers
		And ParametersStructure.ChangeQuantity
		And Not ParametersStructure.NotUsePackages
		And Not ParametersStructure.ServicesOnly
		And Not ParametersStructure.OnlyWorks
		And Not ParametersStructure.OnlyTara;
	
	If UseItemsBatch Then
		FillInUsageOfWarehouseGroup(Object, ParametersStructure);
		
		VHFWarehouses = ParametersStructure.WarehouseGroupIsUsed <> False
					And ProductsServer.WarehousesAreIndicatedInTabularPart(ParametersStructure.SeriesSpecificationParameters);
		
		If (Not VHFWarehouses
				And ParametersStructure.SeriesSpecificationParameters.ThisIsOrder)
			Or Not ParametersStructure.SeriesSpecificationParameters.ThisIsOrder Then
			
			ProductsServer.FillInWarehouseAccordingToParametersOfBatchIndication(
				Object,
				ParametersStructure,
				ParametersStructure.SeriesSpecificationParameters);
			
		EndIf;
	EndIf;
	
	BatchBarcodes = New Array;
	NonCacheableBarcodes = New Array;
	
	// The original value of the parameter is saved, which can be changed according to the item settings.
	NotUsePackages = ParametersStructure.NotUsePackages;
	
	For Each CurBarcode In ArrayOfBarcodes Do
		
		AddedData = CachedValues.Barcodes[CurBarcode.Barcode];
		ParametersStructure.NotUsePackages = NotUsePackages;
		
		If Not GetBarcodeData
			And (AddedData.NonUniqueBarcode
				Or Not AddedData.ReceivedAccordingToInfobaseData) Then
			
			NonCacheableBarcodes.Add(CurBarcode.Barcode);
			
		EndIf;
		
		If AddedData.UnknownBarcode Then
			If Not ParametersStructure.ConsiderPackingLists Then
				CurBarcode = Common.CopyRecursive(CurBarcode, False);
				
				ParametersStructure.UnknownBarcodes.Add(CurBarcode);
				
				If AddedData.NonUniqueBarcode
					And Not ParametersStructure.ChangeQuantity Then
					
					ParametersStructure.NonUniqueBarcodes.Insert(CurBarcode.Barcode, True);
					
				EndIf;
				
				Continue;
			EndIf;
		ElsIf AddedData.ItemsType <> Enums.ItemsTypes.Set
			And Not MeetsConditions(AddedData, ParametersStructure) Then
			
			Continue;
			
		EndIf;
		
		If AddedData.ItemsType <> Enums.ItemsTypes.Set Then
			
			If Not AddedData.ItemsBarcode Then
				BatchBarcodes.Add(CurBarcode.Barcode);
			EndIf;
			
			AddedData.QuantityByBarcode = CurBarcode.Count;
			AddedData.BarcodeNotFromCache      = PreviouslyUnencashedBarcodes.Find(CurBarcode.Barcode) <> Undefined;
			ProcessingMode = "OwnGoods";
			
			TSRow = AddChangeVHFString(Object,
												ParametersStructure,
												AddedData,
												ProcessingMode,
												CachedValues,
												ArrayOfRowsWithMultipleSheetsToProcess,
												Assignments);
			
			If TSRow <> Undefined Then
				DoNotUsePackagingUnitsContainerSelection = ParametersStructure.NotUsePackages;
				If AddedData.SuppliedInReusablePackage Then
					DoNotUsePackagingUnitsContainerSelection = False;
				EndIf;
				
				Data = New Structure;
				Data.Insert("UnknownBarcode",		AddedData.UnknownBarcode);
				Data.Insert("NumberOfBarcode",		CurBarcode.Count);
				Data.Insert("NotUsePackages",	DoNotUsePackagingUnitsContainerSelection);
				Data.Insert("PackingList",			AddedData.PackingList);
				Data.Insert("AddContainers",			AddPackagingByTSLine);
				Data.Insert("RowAdded",			False);
				
				ErrorAddingGoods = False;
				
				If UseItemsBatch
					And (AddedData.CompletedActions.Added2
						Or AddedData.CompletedActions.IsChanged)
					And Not (ParametersStructure.SeriesSpecificationParameters.NameOfValueSourceInObjectForm = "ThisForm"
						And Object.FormName = "CommonForm.CheckDocumentPopulation")
					And FillInWHBatchBatch(AddedData, ParametersStructure) Then
					
					BatchFillingData = FillingDataOfWHBatchBatch(
												TSRow,
												AddedData,
												ParametersStructure);
					
					ErrorAddingGoods = BatchFillingData.Count > 1
												And Not BatchFillingData.SpecifyQuantityWhenRegisteringBatch;
					
					If Not ErrorAddingGoods Then
						LinesForProcessingBatches.Add(BatchFillingData);
						
						// Goods that are identified by serial can be added to the TS Goods once.
						// Containers for such goods are added after processing of the TS Series.
						If AddPackagingByTSLine Then
							Data.AddContainers = BatchFillingData.SpecifyQuantityWhenRegisteringBatch;
						EndIf;
					Else
						CancelingChangesInLineWithError(Object, AddedData, TSRow, ParametersStructure);
						
						ProductPresentation = ProductsClientServer.ProductPresentation(
														TrimAll(String(TSRow.Products)),
														TrimAll(String(TSRow.Characteristic)));
						
						MessageText = NStr("ru = 'Отсканированное количество товара ""%1"" с серией ""%2"" по штрихкоду ""%3"" равно %4. Политика учета серий данного товара предусматривает, что количество по любой серии этого товара всегда будет равно 1.';
											|vi = 'The scanned quantity of the ""%1"" item with batch %2 by barcode %3 is equal to %4. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
											|en = 'The scanned quantity of the ""%1"" item with batch %2 by barcode %3 is equal to %4. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.'; fa = 'The scanned quantity of the ""%1"" item with batch %2 by barcode %3 is equal to %4. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
											|it = 'The scanned quantity of the ""%1"" item with batch %2 by barcode %3 is equal to %4. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
											|pl = 'The scanned quantity of the ""%1"" item with batch %2 by barcode %3 is equal to %4. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
											|tr = '""%3"" barkoduna göre ""%2"" partili ""%1"" ürününün taranan miktarı %4. Bu ürünün parti takip politikası, bu ürüne ait herhangi bir parti miktarının her zaman 1 olacağını öngörmektedir.'");
						MessageText = StrTemplate(MessageText,
													ProductPresentation,
													TrimAll(String(AddedData.Series)),
													AddedData.Barcode,
													Format(BatchFillingData.Count, "NZ=0; NG="));
						
						Common.MessageToUser(MessageText);
					EndIf;
				EndIf;
				
				If ErrorAddingGoods Then
					If AddedData.CompletedActions.IsChanged Then
						RowsToProcess.Add(TSRow);
						
						RowDataTS.Insert(TSRow, Data);
					EndIf;
				Else
					If AddedData.CompletedActions.Added2 Then
						Data.RowAdded = True;
						
						AddedProducts.Add(TSRow);
					ElsIf AddedData.CompletedActions.IsChanged Then
						ModifiedGoods.Add(TSRow);
					EndIf;
					
					RowDataTS.Insert(TSRow, Data);
				EndIf;
				
			EndIf;
			
		Else
			
			If CheckAssortment(Object, ParametersStructure, AddedData) Then
				
				ItemsToAddComponents = New Array;
				ErrorAddingComponents = False;
				
				Components = Components(AddedData.Products, AddedData.Characteristic);
				
				If Not SetMeetsFollowingConditions(AddedData, ParametersStructure, Components) Then
					Continue;
				EndIf;
				
				For Each StringComponents In Components Do
					
					If Not MeetsConditions(StringComponents, ParametersStructure) Then
						ErrorAddingComponents = True;
						Continue;
					EndIf;
					
					StringComponents.QuantityByBarcode = CurBarcode.Count;
					StringComponents.BarcodeNotFromCache      = True;
					ProcessingMode = "KitAccessories";
					AddedData.UnknownBarcode = False;
					
					TSRow = AddChangeVHFString(Object,
														ParametersStructure,
														StringComponents,
														ProcessingMode,
														CachedValues);
					
					If TSRow <> Undefined Then
						Data = New Structure;
						Data.Insert("TSRow", TSRow);
						Data.Insert("AddedData", StringComponents);
						ItemsToAddComponents.Add(Data);
						RowDataTSComponents.Insert(TSRow, Data);
						
						If StringComponents.CompletedActions.Added2 Then
							Added1Components.Add(TSRow);
						ElsIf StringComponents.CompletedActions.IsChanged Then
							Modified1Components.Add(TSRow);
						EndIf;
					Else
						ErrorAddingComponents = True;
					EndIf;
				EndDo;
				
				If ErrorAddingComponents
					And (AddedData.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
						Or AddedData.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices) Then
					For Each Data In ItemsToAddComponents Do
						CancelingChangesInLineWithError(Object,
														Data.AddedData,
														Data.TSRow,
														ParametersStructure);
						
						If Data.AddedData.CompletedActions.IsChanged Then
							RowsToProcess.Add(Data.TSRow);
						EndIf;
					EndDo;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ParametersStructure.NotUsePackages = NotUsePackages;
	
	// Preparation of TS lines for batch processing.
	ModifiedTSLines = New Array;
	CommonClientServer.SupplementArray(ModifiedTSLines, ModifiedGoods);
	CommonClientServer.SupplementArray(ModifiedTSLines, Modified1Components);
	CommonClientServer.SupplementArray(ModifiedTSLines, RowsToProcess);
	
	AddedLinesTS = New Array;
	CommonClientServer.SupplementArray(AddedLinesTS, AddedProducts);
	CommonClientServer.SupplementArray(AddedLinesTS, Added1Components);
	
	AddedModifiedLinesTS = New Array;
	CommonClientServer.SupplementArray(AddedModifiedLinesTS, ModifiedGoods);
	CommonClientServer.SupplementArray(AddedModifiedLinesTS, AddedProducts);
	
	// Pre-filling of the tap lines for a single batch processing call.
	If AddPackagingByTSLine Then
		AddContainerToTablePart(Object,
									ParametersStructure,
									CachedValues,
									AddedModifiedLinesTS,
									RowDataTS,
									PackagingByTSLines);
		
		CommonClientServer.SupplementArray(ModifiedTSLines,  PackagingByTSLines.ModifiedPackaging);
		CommonClientServer.SupplementArray(AddedLinesTS, PackagingByTSLines.AddedPackaging);
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(ModifiedTSLines,
		ParametersStructure.StructureOfActionsWithModifiedStrings,
		Object[ParametersStructure.TSName],
		CachedValues);
	BatchProcessingOfTablePartServer.ProcessTSStrings(AddedLinesTS,
		ParametersStructure.StructureOfActionsWithAddedStrings,
		Object[ParametersStructure.TSName],
		CachedValues);
	
	// Processing of PM lines, the series for which is recorded in a separate tabular part.
	TSStringsIdentifiableByBatch = New Structure;
	TSStringsIdentifiableByBatch.Insert("ModifiedGoods", New Array);
	TSStringsIdentifiableByBatch.Insert("RowsToProcess", New Array);
	
	FillIn_Batches(Object, LinesForProcessingBatches, ParametersStructure, RowDataTS, TSStringsIdentifiableByBatch);
	
	ModifiedTSLines = New Array;
	CommonClientServer.SupplementArray(ModifiedTSLines,
												TSStringsIdentifiableByBatch.RowsToProcess);
	
	AddedLinesTS = New Array;
	
	ContainersByTSLinesIdentifiedByBatch = New Structure;
	ContainersByTSLinesIdentifiedByBatch.Insert("AddedPackaging", New Array);
	ContainersByTSLinesIdentifiedByBatch.Insert("ModifiedPackaging", New Array);
	
	If AddPackagingByTSLine Then
		AddContainerToTablePart(Object,
									ParametersStructure,
									CachedValues,
									TSStringsIdentifiableByBatch.ModifiedGoods,
									RowDataTS,
									ContainersByTSLinesIdentifiedByBatch);
		
		CommonClientServer.SupplementArray(ModifiedTSLines,
													ContainersByTSLinesIdentifiedByBatch.ModifiedPackaging);
		CommonClientServer.SupplementArray(AddedLinesTS,
													ContainersByTSLinesIdentifiedByBatch.AddedPackaging);
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(ModifiedTSLines,
		ParametersStructure.StructureOfActionsWithModifiedStrings,
		Object[ParametersStructure.TSName],
		CachedValues);
	BatchProcessingOfTablePartServer.ProcessTSStrings(AddedLinesTS,
		ParametersStructure.StructureOfActionsWithAddedStrings,
		Object[ParametersStructure.TSName],
		CachedValues);
	
	// Post-processing of goods.
	For Each TSRow In AddedModifiedLinesTS Do
		
		Data = RowDataTS.Get(TSRow);
		If Not ValueIsFilled(Data.PackingList)
			And Not Data.UnknownBarcode
			And UseItemsBatch Then
			PostProcessingOfStatusesForSpecifyingBatchesOfTSLine(TSRow, Object, ParametersStructure, CachedValues);
		EndIf;
		PostProcessingOfItemSTSLine(TSRow, Data, Object, ParametersStructure, CachedValues);
		
		CurrentRow = TSRow.GetID();
		Modified = True;
		
	EndDo;
	
	// Post-processing of containers.
	If AddPackagingByTSLine
		And UseItemsBatch Then
		AddedModifiedLinesTS = New Array;
		CommonClientServer.SupplementArray(AddedModifiedLinesTS, PackagingByTSLines.ModifiedPackaging);
		CommonClientServer.SupplementArray(AddedModifiedLinesTS, PackagingByTSLines.AddedPackaging);
		CommonClientServer.SupplementArray(AddedModifiedLinesTS,
													ContainersByTSLinesIdentifiedByBatch.ModifiedPackaging);
		CommonClientServer.SupplementArray(AddedModifiedLinesTS,
													ContainersByTSLinesIdentifiedByBatch.AddedPackaging);
		
		For Each TSRow In AddedModifiedLinesTS Do
			PostProcessingOfStatusesForSpecifyingBatchesOfTSLine(TSRow, Object, ParametersStructure, CachedValues);
		EndDo;
	EndIf;

	// Post-processing of components.
	AddedModifiedLinesTS = New Array;
	CommonClientServer.SupplementArray(AddedModifiedLinesTS, Modified1Components);
	CommonClientServer.SupplementArray(AddedModifiedLinesTS, Added1Components);
	
	For Each TSRow In AddedModifiedLinesTS Do
		Data = RowDataTS.Get(TSRow);
		
		// The goods linecatch can be added as a component part of the kit and has already been processed earlier.
		If Data <> Undefined Then
			Continue;
		EndIf;
		
		Data = RowDataTSComponents.Get(TSRow);
		
		If Not ValueIsFilled(Data.AddedData.PackingList)
			And Not Data.AddedData.UnknownBarcode
			And UseItemsBatch Then
				
			PostProcessingOfStatusesForSpecifyingBatchesOfTSLine(Data.TSRow, Object, ParametersStructure, CachedValues);
			
		EndIf;
		
		PostProcessingOfTSLineOfKitComponent(Data.TSRow, ArrayOfStringsWithSets);
	EndDo;

	If ParametersStructure.CalculateSets And TMCommonUseClientServer.HasObjectAttribute(Object, "Currency") Then
		
		If TMCommonUseClientServer.HasObjectAttribute(Object, "Terms") Then
			CalculationParameters = New Structure;
			CalculationParameters.Insert("Date", Object.Date);
			CalculationParameters.Insert("Currency", Object.Currency);
			CalculationParameters.Insert("Terms", Object.Terms);
			CalculationParameters.Insert("CalculateSets", ParametersStructure.CalculateSets);
			CalculationParameters.Insert("PopulationFields", "Price, PriceKind");
		Else
			CalculationParameters = New Structure;
			CalculationParameters.Insert("Date", Object.Date);
			CalculationParameters.Insert("Currency", Object.Currency);
			CalculationParameters.Insert("PriceKind", Object.PriceKind);
			CalculationParameters.Insert("CalculateSets", ParametersStructure.CalculateSets);
			CalculationParameters.Insert("PopulationFields", "Price, PriceKind");
			
		EndIf;
		
		If TMCommonUseClientServer.HasObjectAttribute(Object, "Organization") Then
			CalculationParameters.Insert("Organization", Object.Organization);
		EndIf;
		
		If ParametersStructure.NotUsePackages
			And ValueIsFilled(ParametersStructure.ColumnNamePackaging) Then
			
			ColumnParameterByValue = New Structure(ParametersStructure.ColumnNamePackaging,
				Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
			
			CalculationParameters.Insert("ColumnsByValue", ColumnParameterByValue);
			
		EndIf;
		
		EnterprisePricesFillingServer.FillInPrices(
			Object[ParametersStructure.TSName],
			ArrayOfStringsWithSets, // Array of rows or selection structure
			CalculationParameters,
			ParametersStructure.StructureOfActionsWithModifiedStrings);
	
	EndIf;
	
	If Modified Then
		Form.Modified = True;
		If UsePackingLists
			And ParametersStructure.ConsiderPackingLists Then
			If ParametersStructure.WorkOutChangingPackingLists Then
				PackingListsServer.AddLinesOnPackingLists(Form, Object[ParametersStructure.TSName],
					ArrayOfRowsWithMultipleSheetsToProcess);
				ProductsServer.FillInStatusesForSpecifyingSeries(Form.Object, Form.SeriesSpecificationParameters, ArrayOfRowsWithMultipleSheetsToProcess);
			EndIf;
			PackingListsServer.RenumberLines(Form, Object[ParametersStructure.TSName], Form.MaximumLineNumber);
			PackingListsServer.FillInServiceDetails(Form, Object[ParametersStructure.TSName],
					ParametersStructure.StructureOfActionsWithLinesFromPackingLists, ArrayOfRowsWithMultipleSheetsToProcess);
		EndIf;
	EndIf;
	
	For Each Barcode In NonCacheableBarcodes Do
		CachedValues.Barcodes.Delete(Barcode);
	EndDo;
	
	If BatchBarcodes.Count() > 0 Then
		InformationRegisters.ItemsBarcodes.RegisterBarcodesOfLabelsOfBatchesOfItems(
			BatchBarcodes,
			CachedValues);
	EndIf;
	
	ParametersStructure.CurrentRow = CurrentRow;
	
EndProcedure

// Returns whether the item's barcode registration rights are available.
//
// Returns:
//	Boolean - True if the right to register item barcodes is available.
//
Function ProductBarcodeRegistrationRightIsAvailable() Export
	
	Return AccessRight("Update", Metadata.InformationRegisters.ItemsBarcodes);
	
EndFunction

// Returns a reference to the item corresponding to the transmitted barcode, or Undefined if the barcode is not registered.
//
// Parameters:
//	ProcessingParameters - See BarcodingOfItemsClientServer.BarcodeProcessingParameters.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
// Returns:
//	CatalogRef.Products, Undefined - The result of the search for the item by barcode.
//
Function BarcodeProducts(ProcessingParameters, CachedValues) Export
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		CachedValues.ProductBarcodeRegistrationRightIsAvailable = ProductBarcodeRegistrationRightIsAvailable();
	EndIf;
	
	WeightBarCodePrefixes		= SettingsValueCached.GetWeightBarCodePrefixes();
	PreviouslyUncachedBarcodes	= New Array;
	
	ProcessingParameters.Barcodes.Barcode = Upper(TrimAll(ProcessingParameters.Barcodes.Barcode));
	
	InformationRegisters.ItemsBarcodes.ConvertWeightBarcode(ProcessingParameters.Barcodes,
																		WeightBarCodePrefixes);
	
	If Not ValueIsFilled(CachedValues.Barcodes[ProcessingParameters.Barcodes.Barcode])
		Or CachedValues.Barcodes[ProcessingParameters.Barcodes.Barcode].UnknownBarcode Then
		
		PreviouslyUncachedBarcodes.Add(ProcessingParameters.Barcodes.Barcode);
		
	EndIf;
	
	If PreviouslyUncachedBarcodes.Count() > 0 Then
		InformationRegisters.ItemsBarcodes.GetBarcodeData(CachedValues,
																			PreviouslyUncachedBarcodes);
	EndIf;
	
	AddedData = CachedValues.Barcodes[ProcessingParameters.Barcodes.Barcode];
	
	If AddedData.UnknownBarcode Then
		ProcessingParameters.UnknownBarcodes.Add(ProcessingParameters.Barcodes);
		
		Return Undefined;
	Else
		Return AddedData.Products;
	EndIf;
	
EndFunction

// Decomposes the transmitted array of read barcodes by barcode types.
//
// Parameters:
//	Barcodes - Array of See BarcodingOfItemsClient.BarcodeDataStructure - collection of barcode composition descriptions.
//
// Returns:
//	Structure - a collection of barcode type descriptions containing the following properties:
//		* WithoutType - Array of See BarcodingOfItemsClient.BarcodeDataStructure.
//
Function StructureByBarcodeType(Barcodes) Export
	
	Result = New Structure();
	Result.Insert("WithoutType", New Array);
	
	For Each ArrRow In Barcodes Do
		
		If Not ProductsLocalization.AssignBarcodeToType(Result, ArrRow) Then 
			Result.WithoutType.Add(ArrRow);
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

// Fills in condition parameters by item type.
//
// Parameters:
//	StructureOfActions - See BarcodingOfItemsClient.BarcodeProcessingParameters.
//	ItemsTypes - ValueList of EnumRef.ItemsTypes,
//						Array Of the Link enumeration.Nomenclature types - data on item types.
//
Procedure DefineConditionsForTypesOfBarcodeProcessingItems(StructureOfActions, ItemsTypes) Export
	
	If TypeOf(ItemsTypes) = Type("ValueList") Then
		ItemTypesArray = ItemsTypes.UnloadValues();
	Else
		ItemTypesArray = ItemsTypes;
	EndIf;
	
	If ItemTypesArray.Find(Enums.ItemsTypes.OwnGoods) <> Undefined Then
		ThereAreWorks = ItemTypesArray.Find(Enums.ItemsTypes.Work_5) <> Undefined;
		ThereAreServices = ItemTypesArray.Find(Enums.ItemsTypes.OperationService) <> Undefined;
		ThereIsPackage   = ItemTypesArray.Find(Enums.ItemsTypes.ReusablePackage) <> Undefined;
		
		StructureOfActions.OnlyGoodsAndWork = ThereAreWorks And Not ThereAreServices;
		StructureOfActions.OnlyGoodsAndServices = Not ThereAreWorks And ThereAreServices;
		StructureOfActions.GoodsOnly        = Not ThereAreWorks And Not ThereAreServices;
		StructureOfActions.AddContainers      = ThereIsPackage
												And StructureOfActions.GoodsOnly;
		StructureOfActions.UseContainersAsGoods = ThereIsPackage
															And StructureOfActions.GoodsOnly;
	Else
		If ItemTypesArray.Find(Enums.ItemsTypes.OperationService) <> Undefined Then
			StructureOfActions.ServicesOnly = True;
		ElsIf ItemTypesArray.Find(Enums.ItemsTypes.Work_5) <> Undefined Then
			StructureOfActions.OnlyWorks = True;
		ElsIf ItemTypesArray.Find(Enums.ItemsTypes.ReusablePackage) <> Undefined Then
			StructureOfActions.OnlyTara   = True;
		EndIf;
	EndIf;
	
EndProcedure

// Extracts information about the number and expiration date from the barcode.
// Works only for barcodes generated by printing barcodes and serial numbers generated
// by the serial registration Form.
//
// Parameters:
//	Barcode - String - The barcode from which you want to extract information.
//	ThereIsNumberField - Boolean - indicates that a number is used for the series whose barcode is transmitted.
//	ThereIsFieldValidUntil - Boolean - indicates that a number is used for the series whose barcode is transmitted.
//	ReportErrors - Boolean - indicates whether it is necessary to display a message to the user about an error in obtaining information
//									about the Attributes of a series of items from a barcode.
//
// Returns:
//	Structure:
//		* Number - String - the number extracted from the barcode, if the numbers in a series of not - empty string.
//		* ValidUntil_ - Date - expiration date. if the series does not have an expiration date, it is an empty date.
//		* HasError - Boolean - indicates whether there is an error when retrieving the information of the item series Attributes from the barcode.
//
Function SeriesInformationFromBarcode(Val Barcode, ThereIsNumberField, ThereIsFieldValidUntil, ReportErrors = True) Export
	
	Result = New Structure;
	Result.Insert("Number",			"");
	Result.Insert("ValidUntil_",		'00010101');
	Result.Insert("HasError",	False);
	
	Barcode = TrimAll(Barcode);
	
	If ThereIsNumberField Then
		
		Result.Number = Barcode;
		
		If ThereIsFieldValidUntil Then
			
			If StrLen(Result.Number) >= 6 Then
				
				If StrLen(Result.Number) >= 8 Then
					ExpirationDateFromBarcode	= Right(Result.Number, 8);
					Result.ValidUntil_		= DateFromBarcodeString(ExpirationDateFromBarcode);
					
					If ValueIsFilled(Result.ValidUntil_) Then
						Result.Number = Left(Result.Number,StrLen(Result.Number) - 8);
					EndIf;
				EndIf;
				
				If Not ValueIsFilled(Result.ValidUntil_) Then
					
					ExpirationDateFromBarcode = Right(Result.Number, 6);
					Result.ValidUntil_		= DateFromBarcodeString(ExpirationDateFromBarcode);
					
					If ValueIsFilled(Result.ValidUntil_) Then
						Result.Number = Left(Result.Number, StrLen(Result.Number) - 6);
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
	Else
		
		Result.ValidUntil_ = DateFromBarcodeString(Barcode);
		
	EndIf;
	
	Result.HasError = Not ValueIsFilled(Result.Number)
							And Not ValueIsFilled(Result.ValidUntil_);
	
	If ReportErrors
		And Result.HasError Then
		
		If ThereIsNumberField
			And ThereIsFieldValidUntil Then
			MessageText = NStr("vi = 'Lỗi chuyển đổi mã vạch %Barcode% sang số sê-ri và thời hạn hữu ích. Hãy thử quét lại.';
								|ru = 'Ошибка преобразования штрихкода %Barcode% в номер серии и срок годности. Попробуйте повторить сканирование.';
								|en = 'An error occurred while converting barcode %Barcode% to batch number and shelf life. Try to scan again.'; fa = 'An error occurred while converting barcode %Barcode% to batch number and shelf life. Try to scan again.';
								|it = 'Errore di conversione del codice a barre %Barcode% il numero di serie e la data di scadenza. Prova a ripetere la scansione.';
								|pl = 'Błąd przekształcenia kodu kreskowego %Barcode% w numer serii i termin ważności. Spróbuj powtórzyć skanowanie.';
								|tr = 'Barkodun %Barcode% parti numarasına ve son kullanma tarihine dönüştürme hatası. Tekrar taramayı dene.'");
		ElsIf ThereIsNumberField Then
			MessageText = NStr("vi = 'Lỗi chuyển đổi mã vạch %Barcode% sang số sê-ri. Hãy thử quét lại.';
								|ru = 'Ошибка преобразования штрихкода %Barcode% в номер серии. Попробуйте повторить сканирование.';
								|en = 'An error occurred while converting barcode %Barcode% to a batch number. Try to scan again.'; fa = 'An error occurred while converting barcode %Barcode% to a batch number. Try to scan again.';
								|it = 'Errore di conversione del codice a barre %Barcode% il numero di serie. Prova a ripetere la scansione.';
								|pl = 'Błąd przekształcenia kodu kreskowego %Barcode% w numer serii. Spróbuj powtórzyć skanowanie.';
								|tr = 'Barkodun %Barcode% parti numarasına dönüştürme hatası. Tekrar taramayı dene.'");
		Else 
			MessageText = NStr("vi = 'Lỗi chuyển đổi mã vạch %Barcode% sang thời hạn hữu ích. Hãy thử quét lại.';
								|ru = 'Ошибка преобразования штрихкода %Barcode% в срок годности. Попробуйте повторить сканирование.';
								|en = 'An error occurred while converting barcode %Barcode% to shelf life. Try to scan again.'; fa = 'An error occurred while converting barcode %Barcode% to shelf life. Try to scan again.';
								|it = 'Errore di conversione del codice a barre %Barcode% nella data di scadenza. Prova a ripetere la scansione.';
								|pl = 'Błąd przekształcenia kodu kreskowego %Barcode% w termin ważności. Spróbuj powtórzyć skanowanie.';
								|tr = 'Barkodun %Barcode% son kullanma tarihine dönüştürme hatası. Tekrar taramayı dene.'");
		EndIf;
		
		MessageText = StrReplace(MessageText, "%Barcode%", Barcode);
		
		Common.MessageToUser(MessageText);
		
	EndIf;
	
	Return Result;
	
EndFunction

#Region RFID

// Processing of read RFID tags is performed.
//
// Parameters:
//	LBLData					- Array of Structure	- label data.
//	ProcessingParameters			- See ReadRFIDProcessingParameters.
//	TSSetOfSeries						- TabularSection		- the tabular part of the Series.
//	CurrentRowID	- Number					- ID.
// 
// Returns:
//	Structure - Contains Properties:
//		* CloseForm - Boolean - whether to close the form
//		* CurrentRowID - Number, Undefined - Id
//		* SeriesData - LineOfATabularSection, Undefined - a string with a series.
//
Function ProcessRFIDReading(LBLData, ProcessingParameters, TSSetOfSeries = Undefined, CurrentRowID = Undefined) Export
	
	SeriesUseSettings = ProcessingParameters.SeriesUseSettings;
	
	CorrectlyReadPlacemarks = New Array;
	
	For Each Label In LBLData Do
		
		// If the TID was not counted, then the tag reading cannot be considered successful
		If ValueIsFilled(Label.TID) Then
			CorrectlyReadPlacemarks.Add(Label);
		EndIf;
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("CloseForm", False);
	Result.Insert("CurrentRowID", Undefined);
	Result.Insert("SeriesData", Undefined);
	
	// From the reader, the same label could arrive several times
	// Therefore, first we will collapse the data that arrived.
	LabelTable = TMCommonUse.ArrayToValueTable(CorrectlyReadPlacemarks);
	ColumnsNames = New Array;
	
	For Each Column In LabelTable.Columns Do
		ColumnsNames.Add(Column.Name);
	EndDo;
	
	LabelTable.GroupBy(StrConcat(ColumnsNames,","));
	
	If LabelTable.Count() > 1 Then
		MessageText = NStr("vi = 'Đã đọc ngay một số đánh dấu RFID. Chỉ để trong vùng thao tác của đầu đọc một đánh dấu và đọc lại.';
							|ru = 'Считалось сразу несколько RFID-метки. Оставьте в зоне действия считывателя только одну метку и повторите считывание.';
							|en = 'Several RFID tags have been read at the same time. Put only one tag in the reader coverage and try to read again.'; fa = 'Several RFID tags have been read at the same time. Put only one tag in the reader coverage and try to read again.';
							|it = 'Diversi tag RFID sono stati letti contemporaneamente. Lasciare una sola etichetta nel raggio di azione del lettore e ripetere la lettura.';
							|pl = 'Zostało uznane za kilka tagów RFID na raz. Pozostaw tylko jedno oznaczenie w zasięgu czytnika i powtórz czytanie.';
							|tr = 'Aynı anda birden fazla RFID etiketi okundu. Okuyucunun alanında yalnızca bir etiket bırak ve tekrar oku.'");
		Common.MessageToUser(MessageText);
		Return Result;
	EndIf;
	
	ProcessedString = Undefined;
	
	If TSSetOfSeries = Undefined Then
		TSSetOfSeries = New ValueTable;
		TSSetOfSeries.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
		TSSetOfSeries.Columns.Add("Count", Common.TypeDescriptionNumber(1));
		TSSetOfSeries.Columns.Add("NumberOfPackages", Common.TypeDescriptionNumber(1));
		
		TSSetOfSeries.Columns.Add("RFIDTID", Metadata.DefinedTypes.RFIDTID.Type);
		TSSetOfSeries.Columns.Add("RFIDUser",Common.StringTypeDetails(30));
		TSSetOfSeries.Columns.Add("RFIDEPC",Common.StringTypeDetails(30));
		TSSetOfSeries.Columns.Add("EPCGTIN", Metadata.DefinedTypes.GTIN.Type);
		TSSetOfSeries.Columns.Add("YouNeedToSaveMark", New TypeDescription("Boolean"));
		TSSetOfSeries.Columns.Add("RFIDTIDFilledIn", New TypeDescription("Boolean"));
		TSSetOfSeries.Columns.Add("RFIDOperationStatus", Common.TypeDescriptionNumber(1));
		
		For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
			If LongDesc.SettingName <> "UseRFIDTags"
				And LongDesc.Use Then
				AttributeMetadata = Metadata.Catalogs.ItemsBatches.Attributes.Find(LongDesc.AttributeName);
				
				If AttributeMetadata = Undefined Then
					ExceptionText = NStr("vi = 'Chưa tìm thấy mục tin %AttributeName% trong số các mục tin của danh mục """"Sê-ri mặt hàng""""';
										|ru = 'Реквизит %AttributeName% не найден среди реквизитов справочника """"Серии номенклатуры""""';
										|en = 'Attribute %AttributeName% is not found among the attributes of the catalog """"Batch of products""""'; fa = 'Attribute %AttributeName% is not found among the attributes of the catalog """"Batch of products""""';
										|it = 'Requisito%AttributeName% non è stato trovato tra i requisiti del directory """"Serie di articoli""""';
										|pl = 'Rekwizyt %AttributeName% nie został znaleziony wśród rekwizytów poradnika """"Serie nomenklatury""""';
										|tr = 'Öznitelik %AttributeName% """"Ürün partileri"""" kataloğunun öznitelikleri arasında bulunmuyor'");
					ExceptionText = StrReplace(ExceptionText, "%AttributeName%", LongDesc.AttributeName);
					
					Raise ExceptionText;
				EndIf;
				
				TSSetOfSeries.Columns.Add(LongDesc.AttributeName, AttributeMetadata.Type);
			EndIf;
			
		EndDo;
	EndIf;
	
	CurLabel_ = LabelTable[0];
	
	ProcessedString = AddSeriesBasedOnPlacemarkInformation(CurLabel_, ProcessingParameters, TSSetOfSeries, CurrentRowID);	
	
	ParametersForFillingInFlagsForWorkingWithPlacemark = ParametersForFillingInFlagsForWorkingWithPlacemark();
	ParametersForFillingInFlagsForWorkingWithPlacemark.CurLabel_ = CurLabel_;
	ParametersForFillingInFlagsForWorkingWithPlacemark.SeriesUseSettings = ProcessingParameters.SeriesUseSettings;
	ParametersForFillingInFlagsForWorkingWithPlacemark.ConnectionFieldValues = ProcessingParameters.ConnectionFieldValues;
	FillInFlagsForWorkingWithPlacemark(ProcessedString, ParametersForFillingInFlagsForWorkingWithPlacemark);
	
	If TMCommonUse.DebugMode() Then
		PlacemarkString = "";
		
		For Each Column In LabelTable.Columns Do
			PlacemarkString = PlacemarkString + Column.Name + " " + LabelTable[0][Column.Name] + " ";
		EndDo;
		Common.MessageToUser(PlacemarkString);
	EndIf;
	
	If ProcessedString <> Undefined Then
		If TypeOf(TSSetOfSeries) <> Type("ValueTable") Then
			Result.CurrentRowID = ProcessedString.GetID();
		EndIf;
		Result.SeriesData = ProcessedString;
	EndIf;
	
	Return Result;

EndFunction

// Function - parameters for processing read RFID and PPI
// 
// Returns:
//	Structure - processing parameters:
//	* RFIDReaders - CatalogRef.Peripherals - link to the RFID reader.
//	* UUID - UUID, Undefined - unique form ID.
//	* SeriesUseSettings - See Catalogs.ItemKinds.SeriesUseSettings.
//	* SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
//	* ConnectionFieldValues - Structure - A collection of field relationships between TS Goods and TS Series from the Series parameterationsreferences.Communication fields:
//		** Key - String - the Attribute name without the suffix, for example, "Nomenclature".
//		** Value - String - the Attribute name with a suffix, for example, "nomenclature".
//
Function ReadRFIDProcessingParameters() Export
	
	Result = New Structure;
	Result.Insert("RFIDReaders",             Catalogs.Peripherals.EmptyRef());
	Result.Insert("UUID",     Undefined);
	Result.Insert("SeriesUseSettings", New Structure);
	Result.Insert("SeriesSpecificationParameters",      New Structure);
	Result.Insert("ConnectionFieldValues",          New Structure);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function AddChangeVHFString(Object, ParametersStructure, AddedData, ProcessingMode,
	CachedValues, ArrayOfRowsWithMultipleSheetsToProcess = Undefined, Assignments = Undefined)
	
	TabularSection = Object[ParametersStructure.TSName];
	
	Tara							= ProcessingMode = "Tara";
	FillIn_Batch					= False;
	FilterByBatch					= False;
	UsePackingLists	= GetFunctionalOption("UsePackingLists");
	SeriesSpecificationParameters			= ParametersStructure.SeriesSpecificationParameters;
	VHFWarehouses						= ParametersStructure.WarehouseGroupIsUsed <> False
										And ProductsServer.WarehousesAreIndicatedInTabularPart(SeriesSpecificationParameters);
	UseItemsBatch	= SeriesSpecificationParameters <> Undefined
										And SeriesSpecificationParameters.UseItemsBatch;
	BarcodeBatch				= AddedData.Series;
	ThisIsAPackingList				= Not Tara
										And ValueIsFilled(AddedData.PackingList);
	
	Add_Product		= CheckAssortment(Object, ParametersStructure, AddedData, ThisIsAPackingList);
	ColumnNamePackaging	= ParametersStructure.ColumnNamePackaging;
	AttributesNames		= "Products, Characteristic, ItemVariantsAreUsed," + ColumnNamePackaging;
	SelectionByPackaging	= New Structure(AttributesNames);
	
	If Not Tara
		And UseItemsBatch
		And AddedData.SeriesAreUsed Then
		
		FilterByBatch = VHFWarehouses
						Or SeriesSpecificationParameters.ThisIsOrder;
		
		If Not FilterByBatch Then
			SelectionByPackaging.Insert("Series");
			
			FillIn_Batch = FillInVHFGoodsBatch(AddedData, ParametersStructure);
			
			If Not FillIn_Batch Then
				AddedData.Series = Catalogs.ItemsBatches.EmptyRef();
			EndIf;
		EndIf;
		
	EndIf;
	
	If UsePackingLists
		And ParametersStructure.ConsiderPackingLists Then
		// We are looking only at the current level.
		//	If the "By goods" mode is enabled, then we search (and add) only at the top level.
		SelectionByPackaging.Insert("PackingListParent", ParametersStructure.CurrentPackingList);
	EndIf;
	
	If ParametersStructure.DonTSearchInCanceledRows And TabularSection.Count() > 0
		And CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0], "Canceled") Then
		SelectionByPackaging.Insert("Canceled", False);
	EndIf;

	If AddedData.Property("Products") And ValueIsFilled(AddedData.Products) Then
		If AddedData.UsePackages <> Undefined Then
			CurrentProductUsePackaging = AddedData.UsePackages;
		Else
			CurrentProductUsePackaging = Common.ObjectAttributeValue(AddedData.Products, "UsePackages");
		EndIf;
		
		If Not CurrentProductUsePackaging Then
			ParametersStructure.NotUsePackages = True;
		EndIf;
	EndIf;
	
	FoundRows = New Array;
	
	If AddedData.UnknownBarcode Then
		
		If ParametersStructure.WHBarcodes Then
			
			Filter = New Structure("Barcode, PackingListParent",
				AddedData.Barcode, ParametersStructure.CurrentPackingList);
			FoundRows = TabularSection.FindRows(Filter);
			
		Else
			
			Add_Product = False;
			
		EndIf;
		
		// The barcode may be unknown, which corresponds to several packing lists,
		//	while the packing list may already be specified in PM Goods, in which case you need to try to find it.
		If UsePackingLists
			And ParametersStructure.ConsiderPackingLists
			And FoundRows.Count() = 0 Then
			
			Filter			= New Structure("PackingListCode, PackingListParent",
												AddedData.Barcode, ParametersStructure.CurrentPackingList);
			FoundRows = TabularSection.FindRows(Filter);
			
			If FoundRows.Count() = 0 Then
				Add_Product = False;
				
				UnknownBarcode = New Structure("Barcode, Count");
				UnknownBarcode.Barcode	= AddedData.Barcode;
				UnknownBarcode.Count	= AddedData.QuantityByBarcode;
				
				ParametersStructure.UnknownBarcodes.Add(UnknownBarcode);
			EndIf;
			
		EndIf;
		
	Else
		
		If ThisIsAPackingList Then
			Filter = New Structure("PackingList", True);
			Filter.Insert("ThisIsAPackingList", True);
		Else
			If ParametersStructure.NotUsePackages
				Or Tara Then
				Filter = Common.CopyRecursive(SelectionByPackaging, False);
				Filter.Delete(ColumnNamePackaging);
			Else
				Filter = SelectionByPackaging;
			EndIf;
			
			If ParametersStructure.CalculateSets Then
				Filter.Insert("ProductsInSet");
				Filter.Insert("ItemVariantOfSet");
			EndIf;
			
			If ParametersStructure.AddOnlyProductsOverAndAboveOrder Then
				Filter.Insert("RowCode", 0);
			EndIf;
			
			If Not Tara
				And AddedData.BarcodeNotFromCache 
				And AddedData.MultipleUnitPackages 
				And AddedData.SinglePackaging = Undefined Then
				
				MessageText = NStr("vi = 'Mặt hàng ""%Products%"" sử dụng một số đóng gói với đơn vị tính ""%UnitOfMeasure%"" và hệ số bằng 1. Để gán mã vạch chi tiết, cần sử dụng một đơn vị đóng gói.';
									|ru = 'У номенклатуры ""%Products%"" используется несколько упаковок с единицей измерения ""%UnitOfMeasure%"" и коэффициентом 1. Для корректной привязки штрихкодов рекомендуется использовать одну единичную упаковку.';
									|en = 'Several packaging units with unit of measure ""%UnitOfMeasure%"" and factor 1 are used for items ""%Products%"". To link barcodes correctly, it is recommended that you use one single packaging unit.'; fa = 'Several packaging units with unit of measure ""%UnitOfMeasure%"" and factor 1 are used for items ""%Products%"". To link barcodes correctly, it is recommended that you use one single packaging unit.';
									|it = 'Per l''articolo ""%Products%"" vengono utilizzate più imballaggi con l''unità di misura ""%UnitOfMeasure%"" e coefficiente 1. Per il corretto collegamento dei codici a barre, si consiglia di utilizzare un singolo imballaggio.';
									|pl = 'Nomenklatura ""%Products%"" używa wielu paczek z jednostką miary ""%UnitOfMeasure%"" i współczynnik 1. Dla prawidłowego wiązania kodów kreskowych, zaleca się użycie jednego pakietu jednostkowego.';
									|tr = '""%Products%"" öğesi, ""%UnitOfMeasure%"" ölçü birimi ve faktör 1 ile birden fazla pakete sahiptir. Doğru barkod eşlemesi için bir birim paketi kullanılması önerilmektedir.'");
				MessageText = StrReplace(MessageText, "%Products%", String(AddedData.Products));
				MessageText = StrReplace(MessageText, "%UnitOfMeasure%", String(AddedData.UnitOfMeasure));
				Common.MessageToUser(MessageText);
			EndIf;
			
		EndIf;
		
		FillPropertyValues(Filter, AddedData);
		FoundRows = TabularSection.FindRows(Filter);
		RowsCount = FoundRows.Count();
		
		If FilterByBatch
			And RowsCount > 0 Then
			
			PickUpBatchOfVHFGoods(AddedData, ParametersStructure, FoundRows, FillIn_Batch, VHFWarehouses);
			
		ElsIf RowsCount > 0 Then
			AddedData.Series = BarcodeBatch;
		EndIf;
		
	EndIf;
	
	TSRow = Undefined;
	
	If Not ParametersStructure.ChangeQuantity Then
		If FoundRows.Count() = 0 Then
			
			If ThisIsAPackingList Then
				
				MessageText = NStr("vi = 'Trong phần bảng không tìm thấy dòng có ""%PackingList%""';
									|ru = 'В табличной части не найдена строка, содержащая ""%PackingList%""';
									|en = 'No rows containing ""%PackingList%"" are found in the table'; fa = 'No rows containing ""%PackingList%"" are found in the table';
									|it = 'Nella parte tabulare non è stata trovata la riga che contiene ""%PackingList%""';
									|pl = 'W części tabeli nie znaleziono wiersza zawierającego ""%PackingList%""';
									|tr = '""%PackingList%"" içeren satır tablo bölümünde bulunamadı'");
				MessageText = StrReplace(MessageText, "%PackingList%", AddedData.PackingList);
				
			ElsIf AddedData.UnknownBarcode Then
				
				If ParametersStructure.WHBarcodes Then
					MessageText = NStr("vi = 'Trong phần bảng chưa tìm thấy dòng có mã vạch ""%Barcode%""';
										|ru = 'В табличной части не найдена строка, содержащая штрихкод ""%Barcode%""';
										|en = 'No rows containing ""%Barcode%"" barcode are found in the table'; fa = 'No rows containing ""%Barcode%"" barcode are found in the table';
										|it = 'Nella parte tabulare non è stata trovata la riga che contiene il codice a barre  ""%Barcode%""';
										|pl = 'W części tabeli nie znaleziono linii zawierającej kod kreskowy ""%Barcode%""';
										|tr = 'Tablo bölümünde ""%Barcode%"" barkodunu içeren satır bulunamadı'");
				ElsIf AddedData.NonUniqueBarcode Then
					MessageText = NStr("ru = 'Не удалось определить номенклатуру, так как штрихкоду ""%Barcode%"" соответствует несколько товаров';
										|vi = 'Cannot identify the item, as the ""%Barcode%"" barcode corresponds to several items';
										|en = 'Cannot identify the item, as the ""%Barcode%"" barcode corresponds to several items'; fa = 'Cannot identify the item, as the ""%Barcode%"" barcode corresponds to several items';
										|it = 'Cannot identify the item, as the ""%Barcode%"" barcode corresponds to several items';
										|pl = 'Cannot identify the item, as the ""%Barcode%"" barcode corresponds to several items';
										|tr = '""%Barcode%"" barkoduna birden fazla ürün karşılık geldiğinden öğebelirlenemedi'");
				ElsIf UsePackingLists
					And ParametersStructure.ConsiderPackingLists Then
					
					MessageText = NStr("vi = 'Không tìm thấy mặt hàng hoặc phiếu đóng gói với mã vạch ""%Barcode%""';
										|ru = 'Номенклатура или упаковочный лист со штрихкодом ""%Barcode%"" не найдены';
										|en = 'Items or packing list with barcode ""%Barcode%"" are not found'; fa = 'Items or packing list with barcode ""%Barcode%"" are not found';
										|it = 'L''articolo o la distinta d''imballaggio con codice a barre ""%Barcode%"" non trovati';
										|pl = 'Nie znaleziono nomenklatury ani listy przewozowej z kodem kreskowym ""%Barcode%""';
										|tr = 'Öğe veya ""%Barcode%"" barkodlu ürün listesi bulunamadı'");
					
				Else
					MessageText = NStr("vi = 'Chưa tìm thấy mặt hàng với mã vạch ""%Barcode%""';
										|ru = 'Номенклатура со штрихкодом ""%Barcode%"" не найдена';
										|en = 'Items with barcode ""%Barcode%"" are not found'; fa = 'Items with barcode ""%Barcode%"" are not found';
										|it = 'Articolo con codice a barre ""%Barcode%"" non trovato';
										|pl = 'Nie znaleziono pozycji z kodem kreskowym ""%Barcode%""';
										|tr = '""%Barcode%"" barkodlu öğe bulunamadı'");
				EndIf;
				
				MessageText = StrReplace(MessageText, "%Barcode%", AddedData.Barcode);
				
			Else
				MessageText = NStr("vi = 'Trong phần bảng không tìm thấy dòng có hàng hóa ""%ProductName_%""';
									|ru = 'В табличной части не найдена строка с товаром ""%ProductName_%""';
									|en = 'No rows containing ""%ProductName_%"" goods are found in the table'; fa = 'No rows containing ""%ProductName_%"" goods are found in the table';
									|it = 'Nella parte tabulare non è stata trovata la riga con la merce ""%ProductName_%""';
									|pl = 'W części tabelarycznej nie znaleziono wiersza z pozycją ""%ProductName_%"".';
									|tr = '""%ProductName_%"" ürününe sahip satır tablo bölümünde bulunamadı'");
				
				ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
																					 AddedData.Characteristic,
																					 ?(Tara, "",AddedData.Package));
				MessageText = StrReplace(MessageText,"%ProductName_%",ProductName_);
			EndIf;
			
			Common.MessageToUser(MessageText);
			
		Else
			TSRow = FoundRows[IndexOfFoundString(FoundRows, FilterByBatch)];
		EndIf;
		
		Return TSRow;
		
	EndIf;
	
	If FoundRows.Count() = 0
		And Not Tara
		And Not ThisIsAPackingList
		And Not AddedData.UnknownBarcode Then 
		
		// If only one package with a coefficient of 1 and a unit of change is used for packaging. as in the nomenclature,
		// we will try to find a line with this package:
		//	- if we find it, we will increase the quantity in it
		//	- if not, add a new line.
		//	- in addition to the elements of the set - in this case, we take the packaging - which is indicated
		If ValueIsFilled(AddedData.SinglePackaging)
			And Not ValueIsFilled(AddedData.Package)
			And Not ProcessingMode = "KitAccessories" Then
			
			FillPropertyValues(SelectionByPackaging, AddedData);
			
			If ParametersStructure.NotUsePackages Then
				Filter = Common.CopyRecursive(SelectionByPackaging, False);
				Filter.Delete(ColumnNamePackaging);
			Else
				SelectionByPackaging[ColumnNamePackaging] = AddedData.SinglePackaging;
				Filter = SelectionByPackaging;
			EndIf;
			
			FoundRows = TabularSection.FindRows(Filter);
			
		ElsIf Not ParametersStructure.NotUsePackages
			And ValueIsFilled(AddedData.SinglePackaging)
			And AddedData.SinglePackaging = AddedData.Package Then
			
			SelectionByPackaging[ColumnNamePackaging] = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
			FoundRows = TabularSection.FindRows(SelectionByPackaging);
			
		ElsIf ProcessingMode = "KitAccessories" Then
			
			If ParametersStructure.NotUsePackages Then
				Filter = Common.CopyRecursive(SelectionByPackaging, False);
				Filter.Delete(ColumnNamePackaging);
			Else
				SelectionByPackaging[ColumnNamePackaging] = AddedData.Package;
				Filter = SelectionByPackaging;
			EndIf;
			
			FoundRows = TabularSection.FindRows(Filter);
			
		EndIf;
		
		If FilterByBatch
			And FoundRows.Count() > 0 Then
			
			PickUpBatchOfVHFGoods(AddedData, ParametersStructure, FoundRows, FillIn_Batch, VHFWarehouses);
			
		Else
			AddedData.Series = BarcodeBatch;
		EndIf;
		
	EndIf;
	
	If UsePackingLists
		And Not ParametersStructure.ConsiderPackingLists
		And ParametersStructure.CurrentPackingList <> Undefined
		And FoundRows.Count() > 0 Then
		
		// We will remove from the found lines on other packing lists
		// If there are already lines with this packing list in the PM, then there will be such a line in the found boxes[0]
		// , if there are no such lines, then either the found boxes will be cleared, or the found boxes[0]
		// there will be a line with an empty packing list.
		
		IndexOf = FoundRows.Count();
		LineWithNonEmptyPackingList = Undefined;
		
		While IndexOf > 0 Do
			
			IndexOf = IndexOf - 1;
			
			ArrRow = FoundRows[IndexOf];
			
			PackingListParent = ArrRow.PackingList;
			
			If ValueIsFilled(PackingListParent) Then
				If PackingListParent <> ParametersStructure.CurrentPackingList Then
					FoundRows.Delete(IndexOf);
				Else
					LineWithNonEmptyPackingList = IndexOf;
				EndIf;
			Else
				If ValueIsFilled(LineWithNonEmptyPackingList)
					Or (Not ValueIsFilled(LineWithNonEmptyPackingList)
						And IndexOf <> 0) Then
					FoundRows.Delete(IndexOf);
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If UsePackingLists
		And ParametersStructure.CurrentPackingList <> Undefined
		And ParametersStructure.ConsiderPackingLists Then
		
		CurPackingListCode = Common.ObjectAttributeValue(
										ParametersStructure.CurrentPackingList,
										"Code");
		
	EndIf;
	
	DataIsWH = FoundRows.Count() > 0;
	If DataIsWH Then
		TSRow = FoundRows[IndexOfFoundString(FoundRows, FilterByBatch)];
	EndIf;
	
	Count = AddedData.QuantityByBarcode * AddedData.NumberOfPackages * AddedData.ZoomRatio;
	NumberOfPackages = AddedData.QuantityByBarcode * AddedData.NumberOfPackages;
	
	If Not (AddedData.MarkedProducts And ParametersStructure.LabelledWHProducts)
		Or ParametersStructure.LoadingFromPDT Then
		If Not ParametersStructure.NotUsePackages Then
			QuantityToAdd = NumberOfPackages;
		Else
			QuantityToAdd = Count;
		EndIf;
	Else
		QuantityToAdd = 0;
	EndIf;
	
	FillOutAppointment = Assignments <> Undefined
							And FillOutAppointment(ParametersStructure, AddedData);
	If Not Tara
		And FillOutAppointment Then
		
		CurAssignment = SelectAppointment(AddedData,
			Assignments, ParametersStructure.ColumnNameQuantity, FoundRows, Count, DataIsWH);
		
	EndIf;
	
	If Not DataIsWH Then
		
		If Add_Product Then
			
			TSRow = TabularSection.Add();
			AddedData.CompletedActions.Added2	= True;
			AddedData.CompletedActions.IsChanged	= False;
			
			If ParametersStructure.WHBarcodes Then
				TSRow.Barcode = AddedData.Barcode;
			EndIf;
			
			If ParametersStructure.LabelledWHProducts 
				And CommonClientServer.HasAttributeOrObjectProperty(TSRow, "MarkedProducts") Then
				TSRow.MarkedProducts = AddedData.MarkedProducts;
			EndIf;
			
			If ThisIsAPackingList Then
				
				TSRow.ThisIsAPackingList = True;
				TSRow.PackingList = AddedData.PackingList;
				TSRow[ParametersStructure.ColumnNameQuantity] = 1;
				TSRow.PackingListParent    = ParametersStructure.CurrentPackingList;
				ArrayOfRowsWithMultipleSheetsToProcess.Add(TSRow);
				
			ElsIf AddedData.UnknownBarcode Then
				
				TSRow[ParametersStructure.ColumnNameQuantity] = AddedData.QuantityByBarcode;
				TSRow.BarcodeIsNotRecognized = 1;
				
			Else
				
				If ParametersStructure.SeriesSpecificationParameters <> Undefined Then 
					ProductsClientServer.UpdateCachedValuesToAccountForSeries(TSRow,CachedValues,
						ParametersStructure.SeriesSpecificationParameters);
				EndIf;
				
				If ParametersStructure.CalculateSets Then
					TSRow.ProductsInSet = AddedData.ProductsInSet;
					TSRow.ItemVariantOfSet = AddedData.ItemVariantOfSet;
				EndIf;
				
				TSRow.Products	= AddedData.Products;
				TSRow.Characteristic	= AddedData.Characteristic;
				
				If FillIn_Batch Then
					TSRow.Series = AddedData.Series;
				ElsIf UseItemsBatch
					And AddedData.SeriesAreUsed Then
					
					Ship = True;
					
					FillInTSLineToCalculateStatusOfBatchIndication(
						TabularSection,
						TSRow,
						ParametersStructure,
						CachedValues,
						Ship);
					
					FillIn_Batch = FillInVHFGoodsBatch(AddedData, ParametersStructure, Ship);
					
					If FillIn_Batch Then
						TSRow.Series = AddedData.Series;
					EndIf;
					
				EndIf;
				
				If Not Tara
					And Not ParametersStructure.NotUsePackages Then
					If ValueIsFilled(AddedData.SinglePackaging)
						And Not ProcessingMode = "KitAccessories" Then
						TSRow[ColumnNamePackaging] = AddedData.SinglePackaging;
					Else
						TSRow[ColumnNamePackaging] = AddedData.Package;
					EndIf;
				EndIf;
				
				TSRow.ItemVariantsAreUsed = AddedData.ItemVariantsAreUsed;
				
				If UsePackingLists
					And ParametersStructure.CurrentPackingList <> Undefined Then
					If ParametersStructure.ConsiderPackingLists Then
						TSRow.PackingListParent    = ParametersStructure.CurrentPackingList;
						TSRow.PackingListParentCode = CurPackingListCode;
					ElsIf TSRow.Property("DoNotShip")
						And TSRow.DoNotShip = 0 Then
						TSRow.PackingList = ParametersStructure.CurrentPackingList;
					EndIf;
				EndIf;
				
				TSRow[ParametersStructure.ColumnNameQuantity] = QuantityToAdd;
				
			EndIf;
			
		EndIf;
		
	Else
		
		TSRow = FoundRows[IndexOfFoundString(FoundRows, FilterByBatch)];
		
		If ParametersStructure.WHBarcodes
			And Not ValueIsFilled(TSRow.Barcode) Then
			TSRow.Barcode = AddedData.Barcode;
		EndIf;
		
		If ThisIsAPackingList
			Or AddedData.UnknownBarcode
				And ParametersStructure.ConsiderPackingLists
				And ValueIsFilled(TSRow.PackingList) Then
			
			MessageText = NStr("vi = '%PackingList% đã có trong phần bảng.';
								|ru = '%PackingList% уже есть в табличной части.';
								|en = '%PackingList% already exists in the table.'; fa = '%PackingList% already exists in the table.';
								|it = '%PackingList% è già presente nella parte tabulare.';
								|pl = '%PackingList% jest już w części tabelarycznej.';
								|tr = 'Tablo kısmında %PackingList% zaten bulunmaktadır.'");
			MessageText = StrReplace(MessageText,"%PackingList%", TSRow.PackingList);
			
			Common.MessageToUser(MessageText);
			
		Else
			If ParametersStructure.SeriesSpecificationParameters <> Undefined Then 
				ProductsClientServer.UpdateCachedValuesToAccountForSeries(TSRow,CachedValues,
					ParametersStructure.SeriesSpecificationParameters);
			EndIf;
			
			If UsePackingLists
				And ParametersStructure.CurrentPackingList <> Undefined Then
				If ParametersStructure.ConsiderPackingLists Then
					TSRow.PackingListParent    = ParametersStructure.CurrentPackingList;
					TSRow.PackingListParentCode = CurPackingListCode;
				ElsIf  Not ValueIsFilled(TSRow.PackingList)
					And TSRow.Property("DoNotShip")
					And TSRow.DoNotShip = 0 Then
					TSRow.PackingList = ParametersStructure.CurrentPackingList;
				EndIf;
			EndIf;
			
			TSRow[ParametersStructure.ColumnNameQuantity] = TSRow[ParametersStructure.ColumnNameQuantity]
				+ QuantityToAdd;
			
			AddedData.CompletedActions.Added2	= False;
			AddedData.CompletedActions.IsChanged	= True;
			
		EndIf;
		
	EndIf;
	
	If FillOutAppointment Then
		TSRow.Purpose = CurAssignment;
	EndIf;
	
	If FillIn_Batch Then
		ParametersStructure.ArrayOfRowsWithSelectedBatches.Add(TSRow.GetID());
	EndIf;
	
	If ParametersStructure.LabelledWHProducts
		And TSRow <> Undefined
		And CommonClientServer.HasAttributeOrObjectProperty(TSRow, "MarkedProducts")
		And TSRow.MarkedProducts Then
		ParametersStructure.ArrayOfRowsWithExciseStamps.Add(TSRow.GetID());
	EndIf;
	
	Return TSRow;
	
EndFunction

// Checks whether the item meets the conditions.
//
// Parameters:
//	AddedData - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//	ParametersStructure - See BarcodingOfItemsClientServer.BarcodeProcessingParameters
//
// Returns:
//	Boolean - The item corresponds to the conditions passed.
//
Function MeetsConditions(AddedData, ParametersStructure) Export
	
	ThisIsAPackingList = ValueIsFilled(AddedData.PackingList);
	
	If ThisIsAPackingList
		And Not ParametersStructure.ConsiderPackingLists Then
		
		MessageText = NStr("vi = 'Mã vạch ""%Barcode%"" tương ứng với phiếu đóng gói. Trong chứng từ này không hỗ trợ làm việc với mã vạch của phiếu đóng gói.';
							|ru = 'Штрихкод ""%Barcode%"" соответствует упаковочному листу. В этом документе не поддерживается работа со штрихкодами упаковочных листов.';
							|en = 'Barcode ""%Barcode%"" corresponds to the packing list. Operations with packing list barcodes is not supported in this document.'; fa = 'Barcode ""%Barcode%"" corresponds to the packing list. Operations with packing list barcodes is not supported in this document.';
							|it = 'Il codice a barre ""%Barcode%""  corrisponde alla distinta d''imballaggio. In questo documento non è supportato il lavoro con i codici a barre delle distinte d''imballaggio.';
							|pl = 'Kod kreskowy ""%Barcode%"" odpowiada liście pakowania. Ten dokument nie obsługuje pracy z kodami kreskowymi list pakowania.';
							|tr = '""%Barcode%"" barkodu bir ürün listesine karşılık gelir. Bu belge ürün listesi barkodlarını desteklemez.'");
		MessageText = StrReplace(MessageText, "%Barcode%", AddedData.Barcode);
		
		Common.MessageToUser(MessageText);
		
		Return False;
		
	EndIf;
	
	If Not ThisIsAPackingList
		And ParametersStructure.GoodsOnly
		And AddedData.ItemsType <> Enums.ItemsTypes.ReusablePackage
		And AddedData.ItemsType <> Enums.ItemsTypes.OwnGoods Then
		
		ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
																			AddedData.Characteristic,
																			AddedData.Package);
		
		MessageText = NStr("vi = 'Hàng hóa ""%ProductName_%"" là dịch vụ (công việc). Trong phần bảng này đã cấm thêm dịch vụ (công việc).';
							|ru = 'Товар ""%ProductName_%"" является услугой (работой). В данную табличную часть запрещено добавлять услуги (работы).';
							|en = 'Goods item ""%ProductName_%"" is a service (work). Adding services (works) to this table is not allowed.'; fa = 'Goods item ""%ProductName_%"" is a service (work). Adding services (works) to this table is not allowed.';
							|it = 'La merce ""%ProductName_%"" è un servizio (lavoro). Nella data parte tabulare è vietato aggiungere servizi (lavori).';
							|pl = 'Produkt ""%ProductName_%"" to usługa (praca). Zabrania się dodawania usług (utworów) do tej części tabelarycznej.';
							|tr = '""%ProductName_%"" ürünü bir hizmettir (iş). Bu tablo bölümüne hizmet (iş) eklemek yasaktır.'");
		MessageText = StrReplace(MessageText, "%ProductName_%", ProductName_);
		
		Common.MessageToUser(MessageText);
		
		Return False;
		
	EndIf;
	
	If Not ThisIsAPackingList
		And ParametersStructure.OnlyGoodsAndWork
		And AddedData.ItemsType <> Enums.ItemsTypes.ReusablePackage
		And AddedData.ItemsType <> Enums.ItemsTypes.OwnGoods
		And AddedData.ItemsType <> Enums.ItemsTypes.Work_5 Then
		
		ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
																			AddedData.Characteristic,
																			AddedData.Package);
		
		MessageText = NStr("ru = 'Товар ""%ProductName_%"" является услугой. В данную табличную часть запрещено добавлять услуги.';
							|vi = 'The ""%ProductName_%"" item is a service. Adding services to this table is not allowed.';
							|en = 'The ""%ProductName_%"" item is a service. Adding services to this table is not allowed.'; fa = 'The ""%ProductName_%"" item is a service. Adding services to this table is not allowed.';
							|it = 'The ""%ProductName_%"" item is a service. Adding services to this table is not allowed.';
							|pl = 'The ""%ProductName_%"" item is a service. Adding services to this table is not allowed.';
							|tr = '""%ProductName_%"" ürünü bir hizmettir. Bu tablo kısmına hizmet eklenmesine izin verilmez.'");
		MessageText = StrReplace(MessageText, "%ProductName_%", ProductName_);
		
		Common.MessageToUser(MessageText);
		
		Return False;
		
	EndIf;
	
	If Not ThisIsAPackingList
		And ParametersStructure.OnlyGoodsAndServices
		And AddedData.ItemsType <> Enums.ItemsTypes.ReusablePackage
		And AddedData.ItemsType <> Enums.ItemsTypes.OwnGoods
		And AddedData.ItemsType <> Enums.ItemsTypes.OperationService Then
		
		ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
																			AddedData.Characteristic,
																			AddedData.Package);
		
		MessageText = NStr("vi = 'Hàng hóa ""%ProductName_%"" là công việc. Cấm thêm hàng hóa vào phần bảng này.';
							|ru = 'Товар ""%ProductName_%"" является работой. В данную табличную часть запрещено добавлять работы.';
							|en = 'Goods item ""%ProductName_%"" is a work. Adding works to this table is not allowed.'; fa = 'Goods item ""%ProductName_%"" is a work. Adding works to this table is not allowed.';
							|it = 'Prodotto ""%ProductName_%"" è un lavoro. È vietato inserire lavori in questa tabella.';
							|pl = 'Produkt ""%ProductName_%"" jest pracą. Niedozwolone jest dodawanie pracy do tej sekcji tabelarycznej.';
							|tr = '""%ProductName_%"" ürünü bir iştir. Bu tablo bölümüne iş eklemek yasaktır.'");
		MessageText = StrReplace(MessageText, "%ProductName_%", ProductName_);
		
		Common.MessageToUser(MessageText);
		
		Return False;
		
	EndIf;
	
	If ParametersStructure.ServicesOnly
		And AddedData.ItemsType <> Enums.ItemsTypes.Work_5
		And AddedData.ItemsType <> Enums.ItemsTypes.OperationService Then
		
		ServiceName_1 = ProductsClientServer.ProductPresentation(AddedData.Products,
																			AddedData.Characteristic,
																			AddedData.Package);
		
		MessageText = NStr("vi = 'Mặt hàng ""%ServiceName_1%"" là hàng hóa (bao bì). Trong phần bảng này cấm thêm hàng hóa (bao bì).';
							|ru = 'Номенклатура ""%ServiceName_1%"" является товаром (тарой). В данную табличную часть запрещено добавлять товары (тару).';
							|en = 'Item ""%ServiceName_1%"" is a goods item (package). Adding goods (packages) to this table is not allowed.'; fa = 'Item ""%ServiceName_1%"" is a goods item (package). Adding goods (packages) to this table is not allowed.';
							|it = 'L''articolo ""%ServiceName_1%""  è una merce. Nella data parte tabulare è vietato aggiugnere merci.';
							|pl = 'Nomenklatura ""%ServiceName_1%"" jest towarem (pojemnikiem). Zabrania się dodawania towarów (kontenerów) do tej części tabelarycznej.';
							|tr = '""%ServiceName_1%"" öğesi üründür (ambalaj). Bu tablo bölümüne ürün (ambalaj) eklemek yasaktır.'");
		MessageText = StrReplace(MessageText,  "%ServiceName_1%", ServiceName_1);
		
		Common.MessageToUser(MessageText);
		
		Return False;
		
	EndIf;
	
	If ParametersStructure.OnlyWorks
		And AddedData.ItemsType <> Enums.ItemsTypes.Work_5 Then
		
		ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
																			AddedData.Characteristic,
																			AddedData.Package);
		
		MessageText = NStr("ru = 'Номенклатура ""%ProductName_%"" не является работой. В данную табличную часть разрешено добавлять только работы.';
							|vi = 'The ""%ProductName_%"" item is not a work. You can add only works to this table.';
							|en = 'The ""%ProductName_%"" item is not a work. You can add only works to this table.'; fa = 'The ""%ProductName_%"" item is not a work. You can add only works to this table.';
							|it = 'The ""%ProductName_%"" item is not a work. You can add only works to this table.';
							|pl = 'The ""%ProductName_%"" item is not a work. You can add only works to this table.';
							|tr = '""%ProductName_%"" öğesi bir iş değildir. Bu tablo kısmına yalnızca iş eklenmesine izin verilir.'");
		MessageText = StrReplace(MessageText, "%ProductName_%", ProductName_);
		
		Common.MessageToUser(MessageText);
		
		Return False;
		
	EndIf;
	
	If ParametersStructure.OnlyTara
		And AddedData.ItemsType <> Enums.ItemsTypes.ReusablePackage Then
		
		ContainerName = ProductsClientServer.ProductPresentation(AddedData.Products,
																			AddedData.Characteristic,
																			AddedData.Package);
		
		MessageText = NStr("vi = 'Mặt hàng ""%ContainerName%"" không có bao bì. Trong phần bảng này chỉ có thể thêm bao bì.';
							|ru = 'Номенклатура ""%ContainerName%"" не является тарой. В данную табличную часть можно добавлять только тару.';
							|en = 'Item ""%ContainerName%"" is not a package. Only packages can be added to this table.'; fa = 'Item ""%ContainerName%"" is not a package. Only packages can be added to this table.';
							|it = 'L''articolo ""%ContainerName%"" non è un imballaggio. Nella data parte tabulare è possibile aggiungere solo l''imballaggio.';
							|pl = 'Element ""%ContainerName%"" nie jest kontenerem. Do tej części tabelarycznej można dodać tylko tarę.';
							|tr = '""%ContainerName%"" öğesi bir ambalaj değildir. Bu tablo bölümüne sadece ambalajlar eklenebilir.'");
		MessageText = StrReplace(MessageText, "%ContainerName%", ContainerName);
		
		Common.MessageToUser(MessageText);
		
		Return False;
		
	EndIf;
	
	If ParametersStructure.GoodsOnly
		And AddedData.ItemsType = Enums.ItemsTypes.ReusablePackage
		And Not ParametersStructure.UseContainersAsGoods Then
		
		MessageText = NStr("vi = 'Mặt hàng ""%ContainerName%"" là bao bì. Trong phần bảng này chỉ có thể thêm hàng hóa.';
							|ru = 'Номенклатура ""%ContainerName%"" является тарой. В данную табличную часть можно добавлять только товары.';
							|en = 'The ""%ContainerName%"" item is a package. You can only add goods to this table.'; fa = 'The ""%ContainerName%"" item is a package. You can only add goods to this table.';
							|it = 'The ""%ContainerName%"" item is a package. You can only add goods to this table.';
							|pl = 'The ""%ContainerName%"" item is a package. You can only add goods to this table.';
							|tr = '""%ContainerName%"" öğesi bir ambalajdır. Bu tablo bölümüne sadece ürünler eklenebilir.'");
		
		ContainerName = ProductsClientServer.ProductPresentation(AddedData.Products,
			AddedData.Characteristic,
			AddedData.Package);
		
		MessageText = StrReplace(MessageText,"%ContainerName%", ContainerName);
		
		CommonClientServer.MessageToUser(MessageText);
		
		Return False;
		
	EndIf;
	
	MeetsConditions = True;
	
	ProductsLocalization.CheckThatItemIndicationMeetsFollowingConditions(
		AddedData,
		ParametersStructure,
		MeetsConditions);
	
	If Not MeetsConditions Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Checks whether the components of the set match the specified parameters.
//
// Parameters:
//	AddedData - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//	ParametersStructure - See BarcodingOfItemsClientServer.BarcodeProcessingParameters 
//	Components - Array of See BatchProcessingOfTablePartClientServer.CachedInformationStructureByBarcode - kit accessories.
//
// Returns:
//	Boolean - the set matches the passed conditions.
//
Function SetMeetsFollowingConditions(AddedData, ParametersStructure, Components) Export
	
	For Each StringComponents In Components Do
		
		If ParametersStructure.OnlyWorks
			And StringComponents.ItemsType <> Enums.ItemsTypes.Work_5
			Then
			
			MessageText = NStr("vi = 'Hàng hóa ""%ProductName_%"" là bộ sản phẩm và trong thành phần chi tiết không chỉ có công việc. Chỉ có thể thêm công việc vào phần bảng này.';
								|ru = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только работы. В данную табличную часть можно добавлять только работы.';
								|en = 'The ""%ProductName_%"" item is a set and its components include not only works. You can only add works to this table.'; fa = 'The ""%ProductName_%"" item is a set and its components include not only works. You can only add works to this table.';
								|it = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только работы. В данную табличную часть можно добавлять только работы.';
								|pl = 'The ""%ProductName_%"" item is a set and its components include not only works. You can only add works to this table.';
								|tr = '""%ProductName_%"" ürünü bir settir ve bileşenler arasında sadece işler yoktur. Bu tablo bölümüne sadece işler eklenebilir.'");
		
			ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
																					 AddedData.Characteristic,
																					 AddedData.Package);
		
			MessageText = StrReplace(MessageText, "%ProductName_%", ProductName_);
		
			Common.MessageToUser(MessageText);
			
			Return False;
			
		EndIf;
			
		If ParametersStructure.ServicesOnly
			And StringComponents.ItemsType <> Enums.ItemsTypes.OperationService
			And StringComponents.ItemsType <> Enums.ItemsTypes.Work_5
			Then
			
			MessageText = NStr("vi = 'Hàng hóa ""%ProductName_%"" là bộ sản phẩm và trong thành phần chi tiết không chỉ có dịch vụ và công việc. Chỉ có thể thêm dịch vụ và công việc vào phần bảng này.';
								|ru = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только услуги и работы. В данную табличную часть можно добавлять только услуги и работы.';
								|en = 'The ""%ProductName_%"" item is a set and its components include not only services and works. You can only add services and works to this table.'; fa = 'The ""%ProductName_%"" item is a set and its components include not only services and works. You can only add services and works to this table.';
								|it = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только услуги и работы. В данную табличную часть можно добавлять только услуги и работы.';
								|pl = 'The ""%ProductName_%"" item is a set and its components include not only services and works. You can only add services and works to this table.';
								|tr = '“%ProductName_%” ürünü bir settir ve bileşenleri arasında sadece hizmetler ve işler yoktur. Bu tablo bölümüne sadece hizmetler ve işler eklenebilir.'");
		
			ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
																					 AddedData.Characteristic,
																					 AddedData.Package);
		
			MessageText = StrReplace(MessageText, "%ProductName_%", ProductName_);
		
			Common.MessageToUser(MessageText);
			
			Return False;
			
		EndIf;
		
		If ParametersStructure.OnlyTara
			And StringComponents.ItemsType <> Enums.ItemsTypes.ReusablePackage
			Then
			
			MessageText = NStr("vi = 'Hàng hóa ""%ProductName_%"" là bộ sản phẩm và trong thành phần chi tiết không chỉ có bao bì. Chỉ có thể thêm bao bì vào phần bảng này.';
								|ru = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только тару. В данную табличную часть можно добавлять только тару.';
								|en = 'The ""%ProductName_%"" item is a set and its components include not only packages. You can only add packages to this table.'; fa = 'The ""%ProductName_%"" item is a set and its components include not only packages. You can only add packages to this table.';
								|it = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только тару. В данную табличную часть можно добавлять только тару.';
								|pl = 'The ""%ProductName_%"" item is a set and its components include not only packages. You can only add packages to this table.';
								|tr = '“%ProductName_%” ürünü bir settir ve bileşenleri arasında sadece konteynerler yoktur. Bu tablo kısmına sadece dara eklenebilir.'");
		
			ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
																					 AddedData.Characteristic,
																					 AddedData.Package);
		
			MessageText = StrReplace(MessageText, "%ProductName_%", ProductName_);
		
			Common.MessageToUser(MessageText);
			
			Return False;
			
		EndIf;
		
		If ParametersStructure.GoodsOnly Then
			
			Cancel = False;
			
			If ParametersStructure.UseContainersAsGoods
				And StringComponents.ItemsType <> Enums.ItemsTypes.OwnGoods
				And StringComponents.ItemsType <> Enums.ItemsTypes.ReusablePackage Then
				
				Cancel = True;
				MessageText =
					NStr("vi = 'Hàng hóa ""%ProductName_%"" là bộ sản phẩm và trong thành phần chi tiết không chỉ có hàng hóa và bao bì. Chỉ có thể thêm hàng hóa và bao bì vào phần bảng này.';
						|ru = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только товары и тару. В данную табличную часть можно добавлять только товары и тару.';
						|en = 'The ""%ProductName_%"" item is a set and its components include not only goods and packages. You can only add goods and packages to this table.'; fa = 'The ""%ProductName_%"" item is a set and its components include not only goods and packages. You can only add goods and packages to this table.';
						|it = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только товары и тару. В данную табличную часть можно добавлять только товары и тару.';
						|pl = 'The ""%ProductName_%"" item is a set and its components include not only goods and packages. You can only add goods and packages to this table.';
						|tr = '“%ProductName_%” ürünü bir settir ve bileşenleri arasında sadece mal ve dara yoktur. Bu tablo bölümüne sadece mal ve dara eklenebilir.'");
				
			ElsIf Not ParametersStructure.UseContainersAsGoods
				And StringComponents.ItemsType <> Enums.ItemsTypes.OwnGoods Then
				
				Cancel = True;
				MessageText =
					NStr("vi = 'Hàng hóa ""%ProductName_%"" là bộ sản phẩm và trong thành phần chi tiết không chỉ có hàng hóa. Trong phần bảng này chỉ có thể thêm hàng hóa.';
						|ru = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только товары. В данную табличную часть можно добавлять только товары.';
						|en = 'The ""%ProductName_%"" item is a set and its components include not only goods. You can only add goods to this table.'; fa = 'The ""%ProductName_%"" item is a set and its components include not only goods. You can only add goods to this table.';
						|it = 'The ""%ProductName_%"" item is a set and its components include not only goods. You can only add goods to this table.';
						|pl = 'The ""%ProductName_%"" item is a set and its components include not only goods. You can only add goods to this table.';
						|tr = '""%ProductName_%"" ürünü bir settir ve bileşenler arasında sadece ürünler yoktur. Bu tablo bölümüne sadece ürünler eklenebilir.'");
				
			EndIf;
			
			If Cancel Then
				
				ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
					AddedData.Characteristic,
					AddedData.Package);
				
				MessageText = StrReplace(MessageText, "%ProductName_%", ProductName_);
				
				Common.MessageToUser(MessageText);
				
				Return False;
				
			EndIf;
			
		EndIf;
		
		If ParametersStructure.OnlyGoodsAndWork
			And StringComponents.ItemsType <> Enums.ItemsTypes.OwnGoods
			And StringComponents.ItemsType <> Enums.ItemsTypes.ReusablePackage
			And StringComponents.ItemsType <> Enums.ItemsTypes.Work_5
			Then
			
			MessageText = NStr("vi = 'Hàng hóa ""%ProductName_%"" là bộ sản phẩm và trong thành phần chi tiết không chỉ có hàng hóa, bao bì và công việc. Chỉ có thể thêm hàng hóa, bao bì và công việc vào phần bảng này.';
								|ru = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только товары, тару и работы. В данную табличную часть можно добавлять только товары, тару и работы.';
								|en = 'The ""%ProductName_%"" item is a set and its components include not only goods, packages, and works. You can only add goods, packages, and works to this table.'; fa = 'The ""%ProductName_%"" item is a set and its components include not only goods, packages, and works. You can only add goods, packages, and works to this table.';
								|it = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только товары, тару и работы. В данную табличную часть можно добавлять только товары, тару и работы.';
								|pl = 'The ""%ProductName_%"" item is a set and its components include not only goods, packages, and works. You can only add goods, packages, and works to this table.';
								|tr = '“%ProductName_%” ürünü bir settir ve bileşenleri arasında sadece mallar, dara ve işler yoktur. Bu tablo bölümüne sadece mal, dara ve iş eklenebilir.'");
		
			ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
																					 AddedData.Characteristic,
																					 AddedData.Package);
		
			MessageText = StrReplace(MessageText, "%ProductName_%", ProductName_);
		
			Common.MessageToUser(MessageText);
			
			Return False;
			
		EndIf;

		If ParametersStructure.OnlyGoodsAndServices
			And StringComponents.ItemsType <> Enums.ItemsTypes.OwnGoods
			And StringComponents.ItemsType <> Enums.ItemsTypes.ReusablePackage
			And StringComponents.ItemsType <> Enums.ItemsTypes.OperationService
			Then
			
			MessageText = NStr("vi = 'Hàng hóa ""%ProductName_%"" là bộ sản phẩm và trong thành phần chi tiết không chỉ có hàng hóa, bao bì và dịch vụ. Chỉ có thể thêm hàng hóa, bao bì và dịch vụ vào phần bảng này.';
								|ru = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только товары, тару и услуги. В данную табличную часть можно добавлять только товары, тару или услуги.';
								|en = 'The ""%ProductName_%"" item is a set and its components include not only goods, packages, and services. You can only add goods, packages, or services to this table.'; fa = 'The ""%ProductName_%"" item is a set and its components include not only goods, packages, and services. You can only add goods, packages, or services to this table.';
								|it = 'Товар ""%ProductName_%"" является набором и среди комплектующих имеет не только товары, тару и услуги. В данную табличную часть можно добавлять только товары, тару или услуги.';
								|pl = 'The ""%ProductName_%"" item is a set and its components include not only goods, packages, and services. You can only add goods, packages, or services to this table.';
								|tr = '“%ProductName_%” ürünü bir settir ve bileşenleri arasında sadece mallar, dara ve hizmetler yoktur. Bu tablo bölümüne yalnızca mallar, dara veya hizmetler eklenebilir.'");
		
			ProductName_ = ProductsClientServer.ProductPresentation(AddedData.Products,
																					 AddedData.Characteristic,
																					 AddedData.Package);
		
			MessageText = StrReplace(MessageText, "%ProductName_%", ProductName_);
		
			Common.MessageToUser(MessageText);
			
			Return False;
			
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

Function CheckAssortment(Object, ParametersStructure, AddedData, ThisIsAPackingList = False)
	
	Add_Product = True;
	
	If ParametersStructure.AssortmentVerificationParameters = Undefined
		Or Not ParametersStructure.AssortmentVerificationParameters.CheckAssortment_
		Or ThisIsAPackingList 
		Or AddedData.UnknownBarcode
		Or ValueIsFilled(AddedData.ProductsInSet) Then
		
		Return Add_Product;
		
	EndIf;
	
	StructureOfStateOfAssortment = ProductRangeServer.StructureOfStateOfProductRangeInFormat(AddedData.Products,
																									ParametersStructure.AssortmentVerificationParameters.Warehouse,
																									Object.Date);
	
	If Not StructureOfStateOfAssortment[ParametersStructure.AssortmentVerificationParameters.NameOfAssortmentResource] Then
		GoodsPresentation =  ProductsClientServer.ProductPresentation(AddedData.Products,
																				 AddedData.Characteristic);
																				 
		AssortmentMessageText = StrReplace(ParametersStructure.AssortmentVerificationParameters.MessageText,
			"%1",
			GoodsPresentation);
		
		Common.MessageToUser(AssortmentMessageText);
		
		Add_Product = ParametersStructure.AssortmentVerificationParameters.AllowAdding;
		
	EndIf;

	Return Add_Product;
	
EndFunction

// Returns an array of configuration options for the specified item and characteristic.
//
// Parameters:
//	Products - CatalogRef.Products - The item for which you need to select the configuration option.
//	Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//
// Returns:
//	Array of See BatchProcessingOfTablePartClientServer.CachedInformationStructureByBarcode.
//
Function Components(Products, Characteristic) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MIN(GoodsTable.LineNumber)		AS LineNumber,
	|	CatalogProducts.Ref			AS Products,
	|	CatalogProducts.PackagingGroup	AS PackagingGroup,
	|	CatalogProducts.UnitOfMeasure	AS UnitOfMeasure,
	|	GoodsTable.Characteristic			AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	GoodsTable.Package					AS Package,
	|	SUM(GoodsTable.NumberOfPackages)	AS NumberOfPackages
	|INTO SetComponents
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS GoodsTable
	|		INNER JOIN Catalog.ProductKitConfigurations AS KitConfigurations
	|		ON GoodsTable.Ref = KitConfigurations.Ref
	|			AND KitConfigurations.Owner = &Owner
	|			AND KitConfigurations.Characteristic = &Characteristic
	|			AND KitConfigurations.Main
	|		
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON GoodsTable.Products = CatalogProducts.Ref
	|
	|GROUP BY
	|	CatalogProducts.Ref,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetComponents.Products	AS Products,
	|	ProductPackages.Ref			AS Package
	|INTO ProductPackages
	|FROM
	|	SetComponents AS SetComponents
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON SetComponents.Products = ProductPackages.Owner
	|			AND SetComponents.UnitOfMeasure = ProductPackages.UnitOfMeasure
	|			AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			AND ISNULL(ProductPackages.Denominator, 0) <> 0
	|
	|WHERE
	|	NOT ProductPackages.DeletionMark
	|	AND SetComponents.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|	AND CAST(ProductPackages.Numerator / ProductPackages.Denominator AS NUMBER(27, 11)) = 1
	|
	|UNION ALL
	|
	|SELECT
	|	SetComponents.Products	AS Products,
	|	ProductPackages.Ref			AS Package
	|FROM
	|	SetComponents AS SetComponents
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON SetComponents.PackagingGroup = ProductPackages.Owner
	|			AND SetComponents.UnitOfMeasure = ProductPackages.UnitOfMeasure
	|			AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			AND ISNULL(ProductPackages.Denominator, 0) <> 0
	|
	|WHERE
	|	NOT ProductPackages.DeletionMark
	|	AND SetComponents.PackagingGroup <> VALUE(Catalog.PackagingGroups.SpecialForItem)
	|	AND CAST(ProductPackages.Numerator / ProductPackages.Denominator AS NUMBER(27, 11)) = 1
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatalogProducts.Ref						AS Products,
	|	CatalogProducts.ItemsType				AS ItemsType,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.BatchOwner, UNDEFINED) = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN ISNULL(CatalogProducts.ProductKind.SpecifyQuantityWhenRegisteringBatch, FALSE)
	|		ELSE CatalogProducts.BatchOwner.SpecifyQuantityWhenRegisteringBatch
	|	END												AS SpecifyQuantityWhenRegisteringBatch,
	|	SetComponents.Characteristic					AS Characteristic,
	|	SetComponents.Series							AS Series,
	|	ISNULL(CatalogProducts.ProductKind.KeepAccountingByBatch, FALSE) AS SeriesAreUsed,
	|	SetComponents.Package						AS Package,
	|	ISNULL(CatalogOfPackagingUnits.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem) AS CargoItem,
	|	ISNULL(&QueryTextPackagingFactor1, 1)		AS ZoomRatio,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.UseVariants, UNDEFINED) = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END												AS ItemVariantsAreUsed,
	|	CatalogProducts.UsePackages			AS UsePackages,
	|	MAX(ProductPackages.Package)				AS SinglePackaging,
	|	COUNT(DISTINCT ProductPackages.Package)	AS NumberOfSinglePackages,
	|	SetComponents.UnitOfMeasure				AS UnitOfMeasure,
	|	SetComponents.NumberOfPackages				AS NumberOfPackages
	|FROM
	|	SetComponents AS SetComponents
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON SetComponents.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS CatalogOfPackagingUnits
	|		ON SetComponents.Package = CatalogOfPackagingUnits.Ref
	|		
	|		LEFT JOIN ProductPackages AS ProductPackages
	|		ON SetComponents.Products = ProductPackages.Products
	|
	|GROUP BY
	|	SetComponents.LineNumber,
	|	CatalogProducts.Ref,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.BatchOwner, UNDEFINED) = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN ISNULL(CatalogProducts.ProductKind.SpecifyQuantityWhenRegisteringBatch, FALSE)
	|		ELSE CatalogProducts.BatchOwner.SpecifyQuantityWhenRegisteringBatch
	|	END,
	|	SetComponents.Characteristic,
	|	SetComponents.Series,
	|	ISNULL(CatalogProducts.ProductKind.KeepAccountingByBatch, FALSE),
	|	SetComponents.Package,
	|	CatalogOfPackagingUnits.Ref,
	|	SetComponents.UnitOfMeasure,
	|	SetComponents.NumberOfPackages
	|
	|ORDER BY
	|	SetComponents.LineNumber";
	
	Query.Text = StrReplace(Query.Text,
								"&QueryTextPackagingFactor1",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"SetComponents.Package",
									"CatalogProducts"));
	
	Query.SetParameter("Owner",		Products);
	Query.SetParameter("Characteristic",	Characteristic);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Data = New Array;
	
	While Selection.Next() Do
		curData = BatchProcessingOfTablePartClientServer.CachedInformationStructureByBarcode();
		FillPropertyValues(curData, Selection);
		
		curData.ProductsInSet			= Products;
		curData.ItemVariantOfSet			= Characteristic;
		curData.UnknownBarcode			= False;
		curData.SinglePackaging				= ?(Selection.NumberOfSinglePackages = 1
														And Selection.ZoomRatio = 1,
													Selection.SinglePackaging,
													Undefined);
		curData.MultipleUnitPackages	= Selection.NumberOfSinglePackages > 1
													And Not Selection.CargoItem;
		curData.UsePackages			= Selection.UsePackages;
		
		Data.Add(curData);
	EndDo;
	
	Return Data;

EndFunction

// Returns a table containing information about assignments for products in the tabular part of the object being transferred.
//
// Parameters:
//	Object - FormDataStructure - a Form object with assignments in the table part that contains the following properties:
//				* Ref - DocumentRef, CatalogRef - link to the information base object.
//	ParametersStructure - See BarcodingOfItemsClientServer.BarcodeProcessingParameters.
//	CachedBarcodes - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
// Returns:
//	ValueTable - a table containing information about the Balance of the assignments of goods in the warehouse, which has the following columns:
//		* Products - CatalogRef.Products - The goods for which information about destination Balances is obtained.
//		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the product for which
//																			information about the Balance of assignments is obtained.
//		* Purpose - CatalogRef.Assignments - purpose of the product.
//		* Demand - Number - the need of the goods for the purpose in the warehouse.
//		* Balance - Number - the Balance of the goods for the purpose in the warehouse.
//
Function Assignments(Object, ParametersStructure, CachedBarcodes) Export
	
	If Not ParametersStructure.ToFillTheAppointment
		Or Not ParametersStructure.ChangeQuantity Then
		Return New ValueTable;
	EndIf;
	
	If TypeOf(ParametersStructure.Barcodes) = Type("Array") Then
		ArrayOfBarcodes = ParametersStructure.Barcodes;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(ParametersStructure.Barcodes);
	EndIf;
	
	Query = New Query();
	RequestTextParameters = Catalogs.Assignments.ParametersForCreatingRequestForAvailableAssignments();
	RequestTextParameters.TakeIntoAccountAlreadySelected              = True;
	RequestTextParameters.ForSeveralProducts               = True;
	RequestTextParameters.SortByDateOfAppointmentOrder = True;
	Query.Text = Common.ObjectManagerByRef(Object.Ref).RequestTextForAvailableAssignments(RequestTextParameters);
	
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	For Each CurBarcode In ArrayOfBarcodes Do
		ValueFromCache = CachedBarcodes[CurBarcode.Barcode];
		
		If ValueFromCache <> Undefined
			And ValueIsFilled(ValueFromCache.Products) Then
			
			NewRow = TableOfGoods.Add();
			FillPropertyValues(NewRow, ValueFromCache);
			
		EndIf;
	EndDo;
	
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("DocumentGoods",
		Object[ParametersStructure.TSName].Unload(, "Products,Characteristic,Purpose,Count"));
	Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
	Query.SetParameter("Warehouse", Object.Warehouse);
	Query.SetParameter("Recorder", Object.Ref);
	
	SetPrivilegedMode(True);
	Assignments = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Assignments.Indexes.Add("Products, Characteristic");
	
	Return Assignments;
	
EndFunction

Function FillOutAppointment(ParametersStructure, AddedData)
	
	Return ParametersStructure.ToFillTheAppointment
		And Not AddedData.UnknownBarcode
		And Not ValueIsFilled(AddedData.PackingList)
		And ParametersStructure.ChangeQuantity;
	
EndFunction

// Returns the value of the selected destination, according to the specified parameters.
//
// Parameters:
//	AddedData - Structure - a collection that contains goods information and has the following properties:
//							* Products - CatalogRef.Products - Nomenclature.
//							* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
//	Assignments - See Assignments.
//	ColumnNameQuantity - String - the name of the column in the row of the Strokitch collection.
//	ArrayOfTSStrings - Array of LineOfATabularSection - collection of rows in the table part of an object.
//	QuantityToAdd - Number - the quantity to add to the Strokitch collection.
//	DataIsWH - Boolean - True if the stringcatch collection contains data.
//
// Returns:
//	CatalogRef.Assignments - selected appointment.
//
Function SelectAppointment(AddedData,
			Assignments, ColumnNameQuantity, ArrayOfTSStrings, QuantityToAdd, DataIsWH) Export
	
	SelectionOfAppointments_ = New Structure("Products, Characteristic",
		AddedData.Products, AddedData.Characteristic);
	ProductAssignments = Assignments.Copy(SelectionOfAppointments_);
	ProductAssignments.Indexes.Add("Purpose");
	
	CurAssignment = Catalogs.Assignments.EmptyRef();
	
	StringWithEmptyAssignmentZeroQuantity = Undefined;
	
	If DataIsWH Then
		
		DataIsWH = False;
		IndexOf = ArrayOfTSStrings.Count();
		While Not DataIsWH
			And IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			TSRow = ArrayOfTSStrings[IndexOf];
			If ValueIsFilled(TSRow.Purpose) Then
				AssignmentRow1 = ProductAssignments.Find(TSRow.Purpose, "Purpose");
				If AssignmentRow1 <> Undefined
					And AssignmentRow1.Balance >= QuantityToAdd Then
					DataIsWH = True;
					CurAssignment = TSRow.Purpose;
					ArrayOfTSStrings.Insert(0, TSRow);
					ArrayOfTSStrings.Delete(IndexOf + 1);
				EndIf;
			Else
				If TSRow[ColumnNameQuantity] > 0 Then
					// If the number is already filled in the line and there is no assignment,
					// it means that the user controls the filling of assignments himself, or there are no assignments.
					DataIsWH = True;
					ArrayOfTSStrings.Insert(0, TSRow);
					ArrayOfTSStrings.Delete(IndexOf + 1);
				Else
					// Let's remember the line with the empty assignment, but let's try to find the line with the filled assignment
					// in order to refill it if possible.
					StringWithEmptyAssignmentZeroQuantity = TSRow;
				EndIf;
			EndIf;
		EndDo;
		
	EndIf;
	
	If Not DataIsWH Then
		
		For Each Page1 In ProductAssignments Do
			If Page1.Balance >= QuantityToAdd Then
				CurAssignment = Page1.Purpose;
				Break;
			EndIf;
		EndDo;
		
		If StringWithEmptyAssignmentZeroQuantity <> Undefined Then
			TSRow = StringWithEmptyAssignmentZeroQuantity;
			DataIsWH = True;
		EndIf;
	EndIf;
	
	Return CurAssignment;
	
EndFunction

Procedure FillInUsageOfWarehouseGroup(Object, ParametersStructure)
	
	SeriesSpecificationParameters = ParametersStructure.SeriesSpecificationParameters;
	
	If Not ProductsServer.WarehousesAreIndicatedInTabularPart(SeriesSpecificationParameters) Then
		Return;
	EndIf;
	
	WarehouseFieldName = SeriesSpecificationParameters.WarehouseFieldName;
	
	If SeriesSpecificationParameters.WarehouseFieldName <> Undefined
		And CommonClientServer.HasAttributeOrObjectProperty(Object, WarehouseFieldName) Then
		
		ParametersStructure.WarehouseGroupIsUsed = Catalogs.Warehouses.IsFolder(Object[WarehouseFieldName]);
		
	EndIf;
	
EndProcedure

Function BatchesIndicationStatus(AddedData, ParametersStructure)
	
	Warehouse = ParametersStructure.Warehouse;
	SeriesSpecificationParameters = ParametersStructure.SeriesSpecificationParameters;
	
	If TypeOf(Warehouse) = Type("Structure") Then
		CacheKey = BatchIndicationStatusCacheKey(Warehouse);
	Else
		CacheKey = Warehouse;
	EndIf;
	
	BatchesIndicationStatus = AddedData.BatchesIndicationStatuses.Get(CacheKey);
	
	If BatchesIndicationStatus = Undefined Then
		BatchesIndicationStatus = ProductsServer.DefaultBatchIndicationStatus(AddedData.Products,
																				Warehouse,
																				SeriesSpecificationParameters);
		
		AddedData.BatchesIndicationStatuses.Insert(CacheKey, BatchesIndicationStatus);
	EndIf;
	
	Return BatchesIndicationStatus;
	
EndFunction

Function BatchIndicationStatusCacheKey(Warehouse)
	
	CacheKey		= "";
	EmptyValue	= "EmptyValue";
	
	CacheKey = ?(ValueIsFilled(Warehouse.Sender),
				String(Warehouse.Sender.UUID()),
				EmptyValue);
	CacheKey = CacheKey + ?(ValueIsFilled(Warehouse.Recipient),
							String(Warehouse.Recipient.UUID()),
							EmptyValue);

	Return CacheKey;
	
EndFunction

Procedure PickUpBatchOfVHFGoods(AddedData, ParametersStructure, FoundRows, FillIn_Batch, VHFWarehouses)
	
	IndexOf					= FoundRows.UBound();
	SeriesSpecificationParameters	= ParametersStructure.SeriesSpecificationParameters;
	FirstLineWithoutBatch	= Undefined;
	
	SecurityOptionsAreUsed = SeriesSpecificationParameters.ThisIsOrder
		And CommonClientServer.HasAttributeOrObjectProperty(FoundRows[0], "SupplyOption");
	
	While IndexOf >= 0 Do
		TSRow = FoundRows[IndexOf];
		
		If SeriesSpecificationParameters.ThisIsOrder Then
			If Not VHFWarehouses Then
				BatchesIndicationStatus = BatchesIndicationStatus(AddedData, ParametersStructure);
			Else
				Warehouse = ParametersStructure.Warehouse;
				ParametersStructure.Warehouse = TSRow[SeriesSpecificationParameters.WarehouseFieldName];
				
				BatchesIndicationStatus = BatchesIndicationStatus(AddedData, ParametersStructure);
				
				ParametersStructure.Warehouse = Warehouse;
			EndIf;
		Else
			BatchesIndicationStatus = TSRow.BatchesIndicationStatus;
		EndIf;
		
		BatchIsIndicatedByVHFGoods = BatchesIndicationStatus > 0
									And ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(
										TSRow.BatchesIndicationStatus,
										SeriesSpecificationParameters);
		
		If BatchIsIndicatedByVHFGoods
			And TSRow.Series <> AddedData.Series Then
			
			FoundRows.Delete(IndexOf);
			
			If SecurityOptionsAreUsed
				And Not ValueIsFilled(TSRow.Series)
				And TSRow.SupplyOption <> Enums.SupplyOptions.Ship Then
				
				FirstLineWithoutBatch = TSRow;
				
			EndIf;
			
			IndexOf = IndexOf - 1;
			
			Continue;
			
		EndIf;
		
		If VHFWarehouses
			And Not SeriesSpecificationParameters.ThisIsOrder Then
			
			ParametersStructure.Warehouse = TSRow[SeriesSpecificationParameters.WarehouseFieldName];
			
		EndIf;
		
		If BatchIsIndicatedByVHFGoods Then
			FillIn_Batch = ValueIsFilled(AddedData.Series);
		EndIf;
		
		If IndexOf <> 0 Then
			FoundRows.Insert(0, TSRow);
			FoundRows.Delete(IndexOf + 1);
		EndIf;
		
		Break;
	EndDo;
	
	// In orders, we increase the quantity for the recognized goods from the series in the first line without the series.
	// The calculation of the Status of specifying the series in the order depends not only on the storage warehouse, but also on the security option.
	If FoundRows.Count() = 0
		And FirstLineWithoutBatch <> Undefined Then
		
		FoundRows.Add(FirstLineWithoutBatch);
		
	EndIf;
	
EndProcedure

Procedure FillInTSLineToCalculateStatusOfBatchIndication(TabularSection, TSRow, ParametersStructure, CachedValues, Ship)
	
	SeriesSpecificationParameters = ParametersStructure.SeriesSpecificationParameters;
	
	If Not (SeriesSpecificationParameters <> Undefined
		And SeriesSpecificationParameters.UseItemsBatch) Then
		
		Return;
		
	EndIf;
	
	ActionsWithStrings				= New Structure;
	ActionsCountWithAddedLines	= ParametersStructure.StructureOfActionsWithAddedStrings;
	
	If SeriesSpecificationParameters.ThisIsOrder
		And CommonClientServer.HasAttributeOrObjectProperty(TSRow, "SupplyOption") Then
		
		If ActionsCountWithAddedLines.Property("CheckSoftwareInSalesDocument") Then
			ActionsWithStrings.Insert(
				"CheckSoftwareInSalesDocument",
				ActionsCountWithAddedLines.CheckSoftwareInSalesDocument);
		EndIf;
		
		If ActionsCountWithAddedLines.Property("FillInShipForOrderPlusImplementationOption") Then
			ActionsWithStrings.Insert(
				"FillInShipForOrderPlusImplementationOption",
				ActionsCountWithAddedLines.FillInShipForOrderPlusImplementationOption);
		EndIf;
		
		Ship = ?(ActionsWithStrings.Count() > 0,
						Undefined,
						Ship);
		
	EndIf;
	
	SetWarehouseParameters = False;
	
	If ParametersStructure.WarehouseGroupIsUsed <> False
		And ProductsServer.WarehousesAreIndicatedInTabularPart(SeriesSpecificationParameters) Then
		
		If TabularSection.Count() > 1
			And ValueIsFilled(TabularSection[TabularSection.Count() - 2][SeriesSpecificationParameters.WarehouseFieldName]) Then
			
			TSRow[SeriesSpecificationParameters.WarehouseFieldName] =
				TabularSection[TabularSection.Count() - 2][SeriesSpecificationParameters.WarehouseFieldName];
			
			ParametersStructure.Warehouse = TSRow[SeriesSpecificationParameters.WarehouseFieldName];
			
		Else
			If ActionsCountWithAddedLines.Property("FillOutRecipientInDirectionOfIssue") Then
				SetWarehouseParameters = True;
				
				ActionsWithStrings.Insert(
					"FillOutRecipientInDirectionOfIssue",
					ActionsCountWithAddedLines.FillOutRecipientInDirectionOfIssue);
				
				If ActionsCountWithAddedLines.Property("FillInReleaseDirection") Then
					ActionsWithStrings.Insert(
						"FillInReleaseDirection",
						ActionsCountWithAddedLines.FillInReleaseDirection);
				EndIf;
			EndIf;
			
			If ActionsCountWithAddedLines.Property("CheckFillProductionWarehouse") Then
				SetWarehouseParameters = True;
				
				ActionsWithStrings.Insert(
					"CheckFillProductionWarehouse",
					ActionsCountWithAddedLines.CheckFillProductionWarehouse);
					
				If ActionsCountWithAddedLines.Property("FillInShopPantryAttribute") Then
					ActionsWithStrings.Insert(
						"FillInShopPantryAttribute",
						ActionsCountWithAddedLines.FillInShopPantryAttribute);
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;
	
	If ActionsWithStrings.Count() > 0 Then
		BatchProcessingOfTablePartServer.ProcessTSString(TSRow, ActionsWithStrings, CachedValues);
		
		If Ship = Undefined Then
			Ship = TSRow.SupplyOption = Enums.SupplyOptions.Ship;
		EndIf;
		
		If SetWarehouseParameters Then
			ParametersStructure.Warehouse = TSRow[SeriesSpecificationParameters.WarehouseFieldName];
		EndIf;
	EndIf;
	
EndProcedure

Function FillInVHFGoodsBatch(AddedData, ParametersStructure, Ship = True)
	
	FillInBatch = False;
	
	If Ship Then
		BatchesIndicationStatus	= BatchesIndicationStatus(AddedData, ParametersStructure);
		FillInBatch		= BatchesIndicationStatus > 0
								And ValueIsFilled(AddedData.Series)
								And ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(
									BatchesIndicationStatus,
									ParametersStructure.SeriesSpecificationParameters);
	EndIf;
	
	Return FillInBatch;
	
EndFunction

Function FillInWHBatchBatch(AddedData, ParametersStructure)
	
	FillInBatch = False;
	
	If Not AddedData.UnknownBarcode
		And ValueIsFilled(AddedData.Series)
		And Not ValueIsFilled(AddedData.PackingList) Then
		
		BatchesIndicationStatus = BatchesIndicationStatus(AddedData, ParametersStructure);
		
		FillInBatch = ProductsClientServer.ThisSeriesStatusIndicatesWHSeries(
							BatchesIndicationStatus,
							ParametersStructure.SeriesSpecificationParameters);
		
	EndIf;
	
	Return FillInBatch;
	
EndFunction

Function FillingDataOfWHBatchBatch(TSRow, AddedData, ParametersStructure)
	
	QuantityToAdd = 0;
	
	If ParametersStructure.LoadingFromPDT
		Or Not (AddedData.MarkedProducts
				And ParametersStructure.LabelledWHProducts) Then
		
		If Not ParametersStructure.NotUsePackages Then
			QuantityToAdd = AddedData.QuantityByBarcode * AddedData.NumberOfPackages;
		Else
			QuantityToAdd = AddedData.QuantityByBarcode * AddedData.NumberOfPackages
									* AddedData.ZoomRatio;
		EndIf;
	EndIf;
	
	FillingData = FillingDataOfWHBatchBatchByDefault();
	FillPropertyValues(FillingData, AddedData);
	FillingData.TSRow	= TSRow;
	FillingData.Count	= QuantityToAdd;
	
	Return FillingData;
	
EndFunction

Function FillingDataOfWHBatchBatchByDefault()
	
	FillingData = New Structure;
	FillingData.Insert("TSRow");
	FillingData.Insert("Series");
	FillingData.Insert("Count", 0);
	FillingData.Insert("SpecifyQuantityWhenRegisteringBatch", True);
	
	Return FillingData;
	
EndFunction

Procedure AddContainerToTablePart(Object, ParametersStructure, CachedValues, AddedModifiedLinesTS, RowDataTS, PackagingByTSLines)
	
	For Each TSRow In AddedModifiedLinesTS Do
		Data = RowDataTS.Get(TSRow);
		
		If Not Data.AddContainers Then
			Continue;
		EndIf;
		
		PostProcessingOfTSStringAddingPackaging(TSRow, Data, Object, ParametersStructure, CachedValues,
			PackagingByTSLines);
	EndDo;
	
EndProcedure

Procedure FillIn_Batches(Object, LinesForProcessingBatches, ParametersStructure, RowDataTS, TSStrings)
	
	If LinesForProcessingBatches.Count() = 0 Then
		Return;
	EndIf;
	
	LinkFields				= New Array;
	SeriesSpecificationParameters	= ParametersStructure.SeriesSpecificationParameters;
	
	For Each LinksField In SeriesSpecificationParameters.LinkFields Do
		LinkFields.Add(LinksField);
	EndDo;
	
	SetOfSeries			= Object[SeriesSpecificationParameters.TSSeriesName];
	TextOfLinkFields = StrConcat(LinkFields, ",");
	AttributesNames = "Products, Characteristic, Series"
						+ ?(ValueIsFilled(TextOfLinkFields), ", " + TextOfLinkFields, "");
	
	AddPackagingByTSLine = GetFunctionalOption("UseReusablePackage")
		And ParametersStructure.AddContainers
		And ParametersStructure.ChangeQuantity
		And Not ParametersStructure.NotUsePackages
		And Not ParametersStructure.ServicesOnly
		And Not ParametersStructure.OnlyWorks
		And Not ParametersStructure.OnlyTara;
	
	RowFilter = New Structure(AttributesNames);
	
	For Each StringForProcessing In LinesForProcessingBatches Do
		CurrentRow	= StringForProcessing.TSRow;
		RowData	= RowDataTS.Get(CurrentRow);
		
		FillPropertyValues(RowFilter, CurrentRow);
		RowFilter.Series = StringForProcessing.Series;
		
		BatchesWereFound = SetOfSeries.FindRows(RowFilter);
		
		Cancel = False;
		
		If BatchesWereFound.Count() > 0 Then
			If Not StringForProcessing.SpecifyQuantityWhenRegisteringBatch Then
				If Not RowData.RowAdded Then
					CurrentRow[ParametersStructure.ColumnNameQuantity] = CurrentRow[ParametersStructure.ColumnNameQuantity]
						- StringForProcessing.Count;
					
					// Preparing lines for batch processing.
					TSStrings.RowsToProcess.Add(CurrentRow);
					
					ProductPresentation = ProductsClientServer.ProductPresentation(
													TrimAll(String(CurrentRow.Products)),
													TrimAll(String(CurrentRow.Characteristic)));
					
					MessageText = NStr("ru = 'Товар ""%1"" с серией ""%2"" уже есть в табличной части. Политика учета серий данного товара предусматривает, что количество по любой серии этого товара всегда будет равно 1.';
										|vi = 'The ""%1"" item with batch ""%2"" is already in the table. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
										|en = 'The ""%1"" item with batch ""%2"" is already in the table. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.'; fa = 'The ""%1"" item with batch ""%2"" is already in the table. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
										|it = 'The ""%1"" item with batch ""%2"" is already in the table. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
										|pl = 'The ""%1"" item with batch ""%2"" is already in the table. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
										|tr = '""%2"" partili ""%1"" ürünü zaten tablo kısmında mevcut. Bu ürünün parti takip politikası, bu ürüne ait herhangi bir parti miktarının her zaman 1 olacağını öngörmektedir.'");
					MessageText = StrTemplate(MessageText,
												ProductPresentation,
												TrimAll(String(StringForProcessing.Series)));
					
					Common.MessageToUser(MessageText, Undefined, "", "", Cancel);
				EndIf;
			Else
				RowSeries = BatchesWereFound[0];
				RowSeries.Count = RowSeries.Count + StringForProcessing.Count;
			EndIf;
		Else
			NewRow = SetOfSeries.Add();
			FillPropertyValues(NewRow, CurrentRow);
			
			NewRow.Series		= StringForProcessing.Series;
			NewRow.Count	= StringForProcessing.Count;
		EndIf;
		
		If Not Cancel
			And Not StringForProcessing.SpecifyQuantityWhenRegisteringBatch Then
			// A container selection will be performed for the lines.
			RowData.AddContainers = AddPackagingByTSLine;
			
			TSStrings.ModifiedGoods.Add(CurrentRow);
		EndIf;
		
		RowID = CurrentRow.GetID();
		
		If ParametersStructure.ArrayOfRowsWithSelectedBatches.Find(RowID) = Undefined Then
			ParametersStructure.ArrayOfRowsWithSelectedBatches.Add(RowID);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CancelingChangesInLineWithError(Object, AddedData, TSRow, ParametersStructure)
	
	If AddedData.CompletedActions.Added2 Then
		TabularSection = Object[ParametersStructure.TSName];
		TabularSection.Delete(TSRow);
	ElsIf AddedData.CompletedActions.IsChanged Then
		If Not ParametersStructure.NotUsePackages Then
			TSRow[ParametersStructure.ColumnNameQuantity] = TSRow[ParametersStructure.ColumnNameQuantity]
				- AddedData.QuantityByBarcode;
		Else
			TSRow[ParametersStructure.ColumnNameQuantity] = TSRow[ParametersStructure.ColumnNameQuantity]
				- AddedData.QuantityByBarcode * AddedData.ZoomRatio;
		EndIf;
	EndIf;
	
EndProcedure

Function IndexOfFoundString(FoundRows, FilterByBatch)
	
	Return ?(FilterByBatch, 0, FoundRows.UBound());
	
EndFunction

Function DateFromBarcodeString(Val Barcode)
	
	BarcodeDate = '00010101';	
	
	If StringFunctionsClientServer.OnlyNumbersInString(Barcode) Then
		
		If StrLen(Barcode) = 8 Then
			
			Barcode = "20" + Mid(Barcode,5,2) + Mid(Barcode,3,2) + Left(Barcode,2) + Right(Barcode, 2) + "0000";
			
			Try
				BarcodeDate = Date(Barcode);
			Except
				BarcodeDate = '00010101';
			EndTry;
			
		ElsIf StrLen(Barcode) = 6 Then
			
			Barcode = "20" + Mid(Barcode,5,2) + Mid(Barcode,3,2) + Left(Barcode,2) + "000000";
			
			Try
				BarcodeDate = Date(Barcode);
			Except
				BarcodeDate = '00010101';
			EndTry;
			
		EndIf;
		
	EndIf;
	
	Return BarcodeDate;
	
EndFunction

#Region PostProcessingOfTSStrings

Procedure PostProcessingOfTSStringAddingPackaging(TSRow, Data, Object, ParametersStructure, CachedValues, PackagingByTSLines)
	
	If Data.NotUsePackages Then
		Return;
	EndIf;
	
	PackageTable = ReusablePackageServer.ReusablePackagingOfProductRange(
					TSRow.Products,
					TSRow[ParametersStructure.ColumnNamePackaging]);
	
	For Each RowOfTables In PackageTable Do
		AddedData = BatchProcessingOfTablePartClientServer.CachedInformationStructureByBarcode();
		FillPropertyValues(AddedData, RowOfTables);
		AddedData.QuantityByBarcode	= Data.NumberOfBarcode;
		AddedData.UnknownBarcode	= False;
		
		TareString = AddChangeVHFString(Object,
											ParametersStructure,
											AddedData,
											"Tara",
											CachedValues);
		
		If TareString <> Undefined Then
			If AddedData.CompletedActions.Added2 Then
				PackagingByTSLines.AddedPackaging.Add(TareString);
			ElsIf AddedData.CompletedActions.IsChanged Then
				PackagingByTSLines.ModifiedPackaging.Add(TareString);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure PostProcessingOfStatusesForSpecifyingBatchesOfTSLine(TSRow, Object, ParametersStructure, CachedValues)
	
	RowID = TSRow.GetID();
	
	// In the form of checking the filling of the document, only the fin is displayed.series, PM Series are not present,
	// the processing of the series will occur when processing PM lines (above).
	If Not (ParametersStructure.SeriesSpecificationParameters.NameOfValueSourceInObjectForm = "ThisForm"
			And Object.FormName = "CommonForm.CheckDocumentPopulation") Then
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
																						ParametersStructure.SeriesSpecificationParameters, 
																						TSRow.GetID(),
																						CachedValues);
	EndIf;
	
	If TSRow.BatchesIndicationStatus <> 0 Then
		If ParametersStructure.ArrayOfRowsWithSelectedBatches.Find(RowID) = Undefined Then
			ParametersStructure.ArrayOfRowsWithSeries_.Add(RowID);
		EndIf;
	EndIf;
	
EndProcedure

Procedure PostProcessingOfItemSTSLine(TSRow, Data, Object, ParametersStructure, CachedValues)
	
	If ParametersStructure.WHBarcodes
		And ParametersStructure.ChangeQuantity
		And Not Data.UnknownBarcode Then
		TSRow.BarcodeIsNotRecognized = 0;
	EndIf;
	
EndProcedure

Procedure PostProcessingOfTSLineOfKitComponent(TSRow, ArrayOfStringsWithSets)
	
	If TMCommonUseClientServer.HasObjectAttribute(TSRow, "SetIndex")
		And TMCommonUseClientServer.HasObjectAttribute(TSRow, "ProductsInSet")
		And ValueIsFilled(TSRow.ProductsInSet) Then
		TSRow.SetIndex = 1;
	EndIf;
	ArrayOfStringsWithSets.Add(TSRow);
	
EndProcedure

#EndRegion

#Region RFID

Function AddSeriesBasedOnPlacemarkInformation(CurLabel_, Parameters, TSSetOfSeries, CurrentRowID)
	
	ProcessedString = ProductsLocalization.AddSeriesBasedOnPlacemarkInformation(CurLabel_, Parameters, TSSetOfSeries, CurrentRowID);
	
	If ProcessedString <> Undefined Then
		Return ProcessedString;
	EndIf;
	
	SeriesUseSettings = Parameters.SeriesUseSettings;
	ProductKind             = SeriesUseSettings.BatchOwner;
	
	If Not ValueIsFilled(CurLabel_.TID) Then
		MessageText = NStr("vi = 'Lỗi thêm sê-ri thông tin về đánh dấu RFID: chưa điền TID.';
							|ru = 'Ошибка добавления серии по информации о RFID-метке: не заполнен TID.';
							|en = 'An error occurred while adding batch based on RFID tag information: TID is required.'; fa = 'An error occurred while adding batch based on RFID tag information: TID is required.';
							|it = 'Errore durante l''aggiunta della serie in base alle informazioni sul tag RFID: TID non compilato.';
							|pl = 'Błąd podczas dodawania partii przez informacje tagu RFID: TID nie został wypełniony.';
							|tr = 'RFID etiket bilgilerine göre parti ekleme hatası: TID doldurulmadı.'");
		Common.MessageToUser(MessageText);
		Return Undefined;
	ElsIf Not SeriesUseSettings.UseRFIDTags Then
		MessageText = NStr("vi = 'Lỗi thêm sê-ri thông tin về đánh dấu RFID: đối với sê-ri của dạng mặt hàng này, không sử dụng đánh dấu.';
							|ru = 'Ошибка добавления серии по информации о RFID-метке: для серий этого вида номенклатуры не используются метки.';
							|en = 'An error occurred while adding batch based on RFID tag information: tags are not used for the batch of this items kind.'; fa = 'An error occurred while adding batch based on RFID tag information: tags are not used for the batch of this items kind.';
							|it = 'Errore durante l''aggiunta di una serie di informazioni sulla tag RFID: per la serie di questo tipo di articolo non vengono utilizzati tag.';
							|pl = 'Błąd podczas dodawania serii informacji tagu RFID: w przypadku serii tego typu przedmiotu nie są stosowane żadne znaczniki.';
							|tr = 'RFID etiket bilgilerine göre parti ekleme hatası: bu tür isimlendirmeye sahip partiler için etiket kullanılmıyor.'");
		Common.MessageToUser(MessageText);
		Return Undefined;
	EndIf;
	
	FoundRows = TSSetOfSeries.FindRows(New Structure("RFIDTID", CurLabel_.TID));
		
	ProcessedString = Undefined;
	
	If CurrentRowID <> Undefined Then
		CurrentRow = TSSetOfSeries.FindByID(CurrentRowID);
	Else
		CurrentRow = Undefined;
	EndIf;
	
	// For the case when there is no information about the PPE in the system, so we read the RFID and the PPE number with the scanner.
	If FoundRows.Count() = 0
		And CurrentRow <> Undefined
		And Not ValueIsFilled(CurrentRow.RFIDTID)
		And (Not ValueIsFilled(CurrentRow.Number)
			Or Not SeriesUseSettings.SpecifyNumberWhenRegisteringBatch 
			Or CurrentRow.Number = CurLabel_.SerialNumber) Then
		
		ProcessedString = CurrentRow;
		ProcessedString.RFIDTID = CurLabel_.TID;
		If ValueIsFilled(CurLabel_.GTIN)
			And Not ValueIsFilled(ProcessedString.EPCGTIN) Then
			ProcessedString.EPCGTIN = StringFunctionsClientServer.DeleteDuplicateChars(CurLabel_.GTIN, "0");
		EndIf;
		
		If ValueIsFilled(CurLabel_.SerialNumber)
			And Not ValueIsFilled(ProcessedString.Number) Then
			ProcessedString.Number = CurLabel_.SerialNumber;
		EndIf;
		
		Return ProcessedString;	
	
	ElsIf FoundRows.Count() > 0 Then
		ProcessedString = FoundRows[0];
		
		Return ProcessedString;
	Else
		PropsSelectionTemplate = "	ItemsBatches.%AttributeName% AS %AttributeName%";
		
		ArrayOfTexts = New Array;
		ArrayOfTexts.Add("	ItemsBatches.Ref AS Series");
		
		For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
			AttributeText = StrReplace(PropsSelectionTemplate, "%AttributeName%", LongDesc.AttributeName);
			ArrayOfTexts.Add(AttributeText);
		EndDo;
		
		RequestRequestText =
		"SELECT
		|	&DetailsSelectionText
		|FROM
		|	Catalog.ItemsBatches AS ItemsBatches
		|WHERE
		|	ItemsBatches.ProductKind = &ProductKind
		|	AND ItemsBatches.RFIDTID = &TID";
		
		RequestRequestText = StrReplace(RequestRequestText, "&DetailsSelectionText" ,StrConcat(ArrayOfTexts,","));
		
		Query = New Query;
		Query.SetParameter("TID", CurLabel_.TID);
		Query.SetParameter("ProductKind", ProductKind);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			ProcessedString = TSSetOfSeries.Add();
			FillPropertyValues(ProcessedString, Selection);
			ProcessedString.Count         = 1;
			ProcessedString.NumberOfPackages = 1;
		Else
			ProcessedString = TSSetOfSeries.Add();
			ProcessedString.RFIDTID = CurLabel_.TID;
			
			If ValueIsFilled(CurLabel_.GTIN) Then
				ProcessedString.EPCGTIN = StringFunctionsClientServer.DeleteDuplicateChars(CurLabel_.GTIN, "0");
			EndIf;
			
			If ValueIsFilled(CurLabel_.SerialNumber)
				And  SeriesUseSettings.SpecifyNumberWhenRegisteringBatch Then
				ProcessedString.Number = CurLabel_.SerialNumber;
			EndIf;
		EndIf;	
				
	EndIf;
		
	Return ProcessedString;
	
EndFunction

// Function - Parameters fill the flags work with the label
// 
// Returns:
//  Structure - Contains Properties:
//		* CurLabel_ - Structure - Cur current rfid tag data
//		* SeriesUseSettings - See Catalogs.ItemKinds.SeriesUseSettings.
//		* ConnectionFieldValues - Structure, FixedStructure - collection of communication fields.
//
Function ParametersForFillingInFlagsForWorkingWithPlacemark() Export
	
	Result = New Structure;
	Result.Insert("CurLabel_");
	Result.Insert("SeriesUseSettings");
	Result.Insert("ConnectionFieldValues");
	
	Return Result;
	
EndFunction

// Fills in the flags for working with the RFID tag.
//
// Parameters:
//	ProcessedString - FormDataCollectionItem  - string to process
//	ParametersForFillingInFlagsForWorkingWithPlacemark - See ParametersForFillingInFlagsForWorkingWithPlacemark.
//
Procedure FillInFlagsForWorkingWithPlacemark(ProcessedString, ParametersForFillingInFlagsForWorkingWithPlacemark) Export
	
	If ProcessedString = Undefined Then
		Return;
	EndIf;
	
	DescriptionOfNumberUsage  = Undefined;
	RFIDEPCUsageDescription = Undefined;
	DescriptionOfUseOfRFIDTID = Undefined;
	
	CurLabel_ = ParametersForFillingInFlagsForWorkingWithPlacemark.CurLabel_;
	SeriesUseSettings = ParametersForFillingInFlagsForWorkingWithPlacemark.SeriesUseSettings;
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.AttributeName = "Number" Then
			DescriptionOfNumberUsage = LongDesc;
		ElsIf LongDesc.AttributeName = "RFIDEPC" Then
			RFIDEPCUsageDescription = LongDesc;
		ElsIf LongDesc.AttributeName = "RFIDTID" Then
			DescriptionOfUseOfRFIDTID = LongDesc;
		EndIf;
		
		If DescriptionOfNumberUsage <> Undefined
			And RFIDEPCUsageDescription <> Undefined
			And DescriptionOfUseOfRFIDTID <> Undefined Then
			Break;
		EndIf;
		
	EndDo;
	
	If Not DescriptionOfUseOfRFIDTID.Use Then
		Return;
	EndIf;
	
	ProcessedString.RFIDTIDFilledIn = ValueIsFilled(ProcessedString.RFIDTID);
	
	If CurLabel_ <> Undefined Then
		ProcessedString.RFIDEPC = CurLabel_.EPC;
	EndIf;
	
	// If there are tags, the number is used, but it cannot be changed manually, so it needs to be generated by TID tags.
	If (DescriptionOfNumberUsage.Use
		And Not DescriptionOfNumberUsage.CanBeEdited)
		And ProcessedString.RFIDTIDFilledIn Then
		
		NumberCalculationResult = EquipmentManagerClientServer.GetSerialNumberByTID(ProcessedString.RFIDTID,
																								ProcessedString.RFIDEPC);	
		
		If NumberCalculationResult.Result Then
			ProcessedString.Number = Format(NumberCalculationResult.SerialNumber, "NG=0");
		Else
			ProcessedString.Number = "";
			
			MessageText = NStr("vi = 'Số sê-ri phải được tạo bởi TID của thẻ RFID. Đã xảy ra lỗi trong khi tạo: %ErrorText%. Liên hệ với quản trị viên của bạn.';
								|ru = 'Номер серии должен быть сгенерирован по TID RFID-метки. При генерации произошла ошибка: %ErrorText%. Обратитесь к администратору.';
								|en = 'Serial number must be generated by RFID-tag TID. An error occurred during generation: %ErrorText%. Please contact the administrator.'; fa = 'Serial number must be generated by RFID-tag TID. An error occurred during generation: %ErrorText%. Please contact the administrator.';
								|it = 'Il numero di serie deve essere generato utilizzando un tag TID RFID. Si è verificato un errore durante la generazione: %ErrorText%. Contatta l''amministratore.';
								|pl = 'Numer serii powinien być wygenerowany według TID tagu RFID. Wystąpił błąd podczas generowania: %ErrorText%. Skontaktuj się z administratorem.';
								|tr = 'Parti numarası RFID etiketinin TID''sinden oluşturulmalıdır. Oluşturma sırasında hata oluştu: %ErrorText%. Lütfen Yöneticiyle iletişime geç.'");
			MessageText = StrReplace(MessageText, "%ErrorText%", NumberCalculationResult.ErrorDescription); 
			
			Common.MessageToUser(MessageText);
		EndIf;
		
	EndIf;
	
	If ParametersForFillingInFlagsForWorkingWithPlacemark.ConnectionFieldValues.Property("GTIN") Then
		GTIN = ParametersForFillingInFlagsForWorkingWithPlacemark.ConnectionFieldValues.GTIN;
	Else
		GTIN = ""
	EndIf;
	
	If Not RFIDEPCUsageDescription.CanBeEdited Then
		If Not IsBlankString(GTIN) 
			And ProcessedString.EPCGTIN <> GTIN
			And ProcessedString.RFIDTIDFilledIn Then
			
			MessageText = NStr("vi = 'GTIN đọc từ thẻ RFID không khớp với GTIN từ %1. Việc gắn thẻ được thực hiện bằng cách cá nhân hóa %1, do đó, cần đọc thẻ phù hợp bằng đầu đọc RFID.';
								|ru = 'GTIN, считанный из RFID метки не соответствует GTIN из %1. Маркировка осуществляется персонифицированными %1, поэтому необходимо считать подходящую метку RFID-считывателем.';
								|en = 'GTIN read from RFID tag does not correspond to GTIN from %1. Marking is made by personified %1, that is why you should scan the suitable tag using RFID reader.'; fa = 'GTIN read from RFID tag does not correspond to GTIN from %1. Marking is made by personified %1, that is why you should scan the suitable tag using RFID reader.';
								|it = 'Il GTIN letto dal tag RFID non corrisponde al GTIN dei %1. La marcatura viene eseguita da %1 personalizzati, pertanto è necessario considerare un''etichetta adatta come lettore RFID.';
								|pl = 'GTIN odczytany z tagu RFID nie pasuje do numeru GTIN od %1. Znakowanie przeprowadza spersonalizowany %1, dlatego konieczne jest odczytanie odpowiedniego znacznika jako czytnika RFID.';
								|tr = 'RFID etiketinden okunan GTIN, %1''in GTIN''siyle eşleşmiyor. İşaretleme kişiselleştirilmiş %1 ile yapılır, bu nedenle eşleşen etiketin bir RFID okuyucu ile okunması gerekir.'");
			MessageText = StrTemplate(MessageText, "KiZ");
			
			Common.MessageToUser(MessageText);
			
		EndIf;
		ProcessedString.YouNeedToSaveMark = False;
		
	ElsIf ValueIsFilled(GTIN)
		And DescriptionOfNumberUsage.Use 
		And ValueIsFilled(ProcessedString.Number) Then
		
		// If RFIDEPC can be written, then we will write SGTIN96 there. This is possible if serial numbers are used
		// and GTIN is passed through the values of the communication fields. In ERP, this parameter is passed only for GISM
		
		ProcessedString.EPCGTIN = GTIN;
		
		If StringFunctionsClientServer.StringToNumber(ProcessedString.Number) <> Undefined Then
			
			EPCData = EquipmentManagerClientServer.GenerateSGTIN96Data(ProcessedString.EPCGTIN,
																					ProcessedString.Number, 1);
			
			If (Not EquipmentManagerClientServer.EmptyEPC(EPCData)
				Or Not EquipmentManagerClientServer.EmptyEPC(ProcessedString.RFIDEPC)) Then
				ProcessedString.YouNeedToSaveMark = EPCData <> ProcessedString.RFIDEPC;
			Else
				ProcessedString.YouNeedToSaveMark = False;
			EndIf;
		Else
			ProcessedString.YouNeedToSaveMark = False;
		EndIf;
		
	EndIf;
	
	If Not ProcessedString.RFIDTIDFilledIn Then
		ProcessedString.RFIDOperationStatus = 0;
	ElsIf ProcessedString.YouNeedToSaveMark Then
		ProcessedString.RFIDOperationStatus = 1;
	Else
		ProcessedString.RFIDOperationStatus = 2;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
