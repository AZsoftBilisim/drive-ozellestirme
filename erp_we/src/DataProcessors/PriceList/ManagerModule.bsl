#If Server Then

#Region TimeConsumingOperations

Procedure ApplySettingsInBackground(Parameters, StorageAddress) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
	"DataProcessor.PriceList.ManagerModule.ApplySettingsInBackground");
	
	ShapeStructure 		= Parameters[0].ShapeStructure;
	SettingsStructure 	= Parameters[0].SettingsStructure;
	
	ProductsTable = SettingPricesServer.CreateProductTable(ShapeStructure);
	
	// Loading the generated list of products.
	ResultStructure1 = DataProcessors.GoodsSelectionByPicking.PrepareDataStructure(SettingsStructure);
	For Each TSRow In ResultStructure1.TableOfGoods Do
		
		NewRow = ProductsTable.Add();
		NewRow.Products = TSRow.Products;
		
		If ShapeStructure.UsePriceManagementSystem25 Then
			If ShapeStructure.UseItemVariants Then
				NewRow.PricingVariant = TSRow.PricingVariant;
			EndIf;
			 
			If ShapeStructure.UseItemsBatch Then
				NewRow.PricingBatch = TSRow.PricingBatch;
			EndIf;
			 
			If ShapeStructure.UseItemPackages Then
				NewRow.PricingPackage = TSRow.PricingPackage;
			EndIf;
		Else	 
			If ShapeStructure.UseItemVariants Then
				NewRow.Characteristic   = TSRow.Characteristic;
			EndIf;
		EndIf;
	EndDo;
	
	DataCache = SettingPricesServer.InitializeDataCacheStructure();
		
	ProductsTable = SettingPricesServer.AddProducts_2(ShapeStructure, ProductsTable, DataCache);
	ValueTable = SettingPricesServer.GoodsTable(ShapeStructure, DataCache,,ProductsTable);

	If ShapeStructure.UsePriceManagementSystem25 Then
		ProductsThatAreNotAllowedToBeEdited = SettingPricesServer.GetProductsThatAreNotAllowedToBeEdited(ShapeStructure, ProductsTable);
		SettingPricesServer.LoadOldPricesOfProductsPriceList2_5(ShapeStructure, ValueTable, DataCache, ProductsThatAreNotAllowedToBeEdited);
	Else	
		ProductsThatAreNotAllowedToBeEdited = SettingPricesServer.GetProductsThatAreNotAllowedToBeEdited(ShapeStructure, ProductsTable);
		SettingPricesServer.LoadOldPricesOfProductsPriceList(ShapeStructure, ValueTable, DataCache, ProductsThatAreNotAllowedToBeEdited);
	EndIf;
	
	ShapeStructure.NumberOfRowsInThePriceTree = ProductsTable.Count();
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("ShapeStructure", ShapeStructure);
	
	StorageAddress = PutToTempStorage(ExecutionResult, StorageAddress);

	NumberOfProcessedData = ValueTable.Count() / 10;
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedData);
	
EndProcedure

Procedure ChangePricesOnServer(Parameters, StorageAddress) Export
	
	ShapeStructure 		= Parameters[0].ShapeStructure;
	CalculationParameters 	= Parameters[0].CalculationParameters;
	
	SettingPricesServer.ChangePrices(ShapeStructure, CalculationParameters);
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("ShapeStructure", ShapeStructure);	
	
	StorageAddress = PutToTempStorage(ExecutionResult, StorageAddress);
EndProcedure

Procedure ChangePricesToPercentageOnServer(Parameters, StorageAddress) Export
	
	ShapeStructure 		= Parameters[0].ShapeStructure;
	CalculationParameters 	= Parameters[0].CalculationParameters;
	
	SettingPricesServer.ChangePricesByPercentage_2(ShapeStructure, CalculationParameters);
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("ShapeStructure", ShapeStructure);	
	
	StorageAddress = PutToTempStorage(ExecutionResult, StorageAddress);
EndProcedure

Procedure CalculatePricesOnServer(Parameters, StorageAddress) Export
	
	ShapeStructure 		= Parameters[0].ShapeStructure;
	CalculationParameters 	= Parameters[0].CalculationParameters;
	
	SettingPricesServer.CalculatePrices(ShapeStructure, CalculationParameters);
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("ShapeStructure", ShapeStructure);	
	
	StorageAddress = PutToTempStorage(ExecutionResult, StorageAddress);
EndProcedure

Procedure FillInPricesFromDocuments(Parameters, StorageAddress) Export
	
	ShapeStructure 		= Parameters[0].ShapeStructure;
	CalculationParameters 	= Parameters[0].CalculationParameters;
	
	SettingPricesServer.FillInPricesFromDocuments(ShapeStructure, CalculationParameters);
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("ShapeStructure", ShapeStructure);	
	
	StorageAddress = PutToTempStorage(ExecutionResult, StorageAddress);
EndProcedure

Procedure ChangeVATRatesATServer(Parameters, StorageAddress) Export
	
	ShapeStructure 		= Parameters[0].ShapeStructure;
	CalculationParameters 	= Parameters[0].CalculationParameters;
	
	SettingPricesServer.ChangeVATRates(ShapeStructure, CalculationParameters);
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("ShapeStructure", ShapeStructure);	
	
	StorageAddress = PutToTempStorage(ExecutionResult, StorageAddress);

EndProcedure

#EndRegion

#EndIf