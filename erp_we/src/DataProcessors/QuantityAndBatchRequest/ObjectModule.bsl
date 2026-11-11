#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the processing data based on the incoming parameters of its use.
//
// Parameters:
//  KeyParameters - See ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm
//  FillingData - See ProvisionInDocumentsClientServer.ParametersOfQuantityAndSeriesRequestForm
//
Procedure Fill(KeyParameters, FillingData) Export
	
	// Parameters are the details of the object.
	FillPropertyValues(ThisObject, FillingData,
		"Products,
		|Characteristic,
		|Warehouse,
		|Purpose,
		|ControlledLotReference,
		|QuantityRegistered,
		|SupplyOptionBeforeChange,
		|Recorder,
		|Price,
		|PriceKind,
		|Package,
		|Currency,
		|Date,
		|PriceIncludesVAT,
		|WithoutFilterByVATInclusionInPrice,
		|Terms,
		|Partner,
		|UsePriceManagementSystem25");
	
	// Security option, Separately.
	If KeyParameters.SelectGoods Then
		
		ItemsType = Common.ObjectAttributeValue(Products, "ItemsType");
		
		If Not ItemsType = Enums.ItemsTypes.Set Then
			
			DefaultOptionAndFlag = ProvisionInDocumentsClientServer.DefaultOptionAndFlagForMatching(
				ItemsType,
				FillingData.AcceptableSeparateActions,
				FillingData.AllowedNonIsolatedActions,
				KeyParameters.LimitSupplyOptions,
				FillingData.SecurityOptionAndFlagSeparately,
				FillingData.WithAssignment);
		
			SupplyOption = DefaultOptionAndFlag.SupplyOption;
			WithAssignment = DefaultOptionAndFlag.WithAssignment;
		Else
			WithAssignment = FillingData.AcceptableSeparateActions.Count() > 0 And FillingData.DetachedSet;
		EndIf;
		
	Else
		SupplyOption = FillingData.SecurityOptionForTheDocument;
		WithAssignment = FillingData.SeparatelyInTheDocument;
	EndIf;
	
	// Quantity.
	NumberOfPackages = 1;
	If Not KeyParameters.SelectGoods Then
		NumberOfPackages = FillingData.CountByDocument;
	EndIf;
	
	Count = NumberOfPackages * Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products);
	
	If KeyParameters.SelectGoods Then
		NumberOfPackages = 1;
		Count = NumberOfPackages * Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products);

		If ItemsType = Enums.ItemsTypes.Set Then
			
			// Parameters of the configuration option.
			ConfigurationOptionParameters = SetsServerCall.ProductConfigurationOptions(Products, Characteristic);
			If ConfigurationOptionParameters <> Undefined Then
				ItemKitConfiguration = ConfigurationOptionParameters.ItemKitConfiguration;
				SetPricingOption        = ConfigurationOptionParameters.SetPricingOption;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// Tab. part of the composition of the set.
	If Not ItemKitConfiguration.IsEmpty() Then
	
		ArrayOfComponents = DataProcessors.QuantityAndBatchRequest.Components(ThisObject, FillingData.Warehouses);
		For Each TSRow In ArrayOfComponents Do
			NewComponents = SetComposition.Add();
			FillPropertyValues(NewComponents, TSRow);
		EndDo;
		
		DataProcessors.QuantityAndBatchRequest.KitCompositionCalculateQuantityPickUp(ThisObject);
		
		// Available and Available by set.
		InStock = 0;
		Available = 0;
		
		InStockSets = Undefined;
		AvailableSets_ = Undefined;
		For Each String In SetComposition Do
			
			InStockAtRow = 0;
			AvailableInLine_ = 0;
			If String.NumberOfPackages <> 0 Then
				InStockAtRow = Int(String.InStock / String.NumberOfPackages);
				AvailableInLine_ = Int(String.Available / String.NumberOfPackages);
			EndIf;
			
			If InStockSets = Undefined Or InStockAtRow < InStockSets Then
				InStockSets = InStockAtRow;
			EndIf;
			
			If AvailableSets_ = Undefined Or AvailableInLine_ < AvailableSets_ Then
				AvailableSets_ = AvailableInLine_;
			EndIf;
			
		EndDo;
		InStock = InStockSets;
		Available = AvailableSets_;
		
	EndIf;
	
	// Tab. part of the Goods.
	FillInTheProducts(KeyParameters, FillingData);
	
	// The index of the document line in the Goods tabular part.
	FoundRow = Goods.Find(True, "ThisIsDocumentRow");
	DocumentRowIndex = ?(FoundRow = Undefined, -1, Goods.IndexOf(FoundRow));
	
	// Types of prices, Price.
	DataProcessors.QuantityAndBatchRequest.FillInPriceTypes(ThisObject, KeyParameters.EditPriceType);
	DataProcessors.QuantityAndBatchRequest.SetPriceByPriceType(ThisObject, KeyParameters);
	DataProcessors.QuantityAndBatchRequest.SetPriceAccordingToCompositionOfSet(ThisObject);
	
	// To recalculate the price on changing the packaging.
	InitialPrice = Price;
	OriginalPackaging = Package;
	
EndProcedure

#EndRegion

#Region Private

Procedure FillInTheProducts(KeyParameters, FillingData)
	
	SelectGoods                    = KeyParameters.SelectGoods;
	SelectSeries                      = KeyParameters.SelectSeries;
	SeriesSelection_3                       = KeyParameters.SeriesSelection_3;
	Department                    = FillingData.Department;
	AddressAvailableBalances            = FillingData.AddressAvailableBalances;
	SeriesSpecificationParameters           = FillingData.SeriesSpecificationParameters;
	WarehouseByDocument                 = FillingData.WarehouseByDocument;
	TableAddressSelectedEarlier       = FillingData.TableAddressSelectedEarlier;
	
	Goods.Clear();
	
	TableOfProductBalances  = Undefined;
	If SelectGoods Then
		
		If ItemKitConfiguration.IsEmpty() Then
			ProductAnalyticsTable = SetComposition.UnloadColumns("Products,Characteristic");
			NewRow = ProductAnalyticsTable.Add();
			NewRow.Products   = Products;
			NewRow.Characteristic = Characteristic;
		Else
			ProductAnalyticsTable = SetComposition.Unload(, "Products,Characteristic");
		EndIf;
		
		TablePickedUpEarlier = GetFromTempStorage(TableAddressSelectedEarlier);
		
		TableOfProductBalances = ProvisionInDocumentsServer.FreeBalancesForProductSelection(
			ProductAnalyticsTable,
			TablePickedUpEarlier,
			FillingData.Warehouses,
			FillingData.Purpose,
			Department,
			FillingData.ControlledLotReference);
		
		RowFilter = New Structure("Products,Characteristic");
		
		TableOfProductBalances.Indexes.Add("Products,Characteristic");
		TableOfProductBalances.Columns.Add("ProductIndexForSelection");
		If Not ItemKitConfiguration.IsEmpty() Then
			For IndexOf = 0 To SetComposition.Count() - 1 Do
				FillPropertyValues(RowFilter, SetComposition[IndexOf]);
				FoundRows = TableOfProductBalances.FindRows(RowFilter);
				For Each TableRow In FoundRows Do
					TableRow.ProductIndexForSelection = IndexOf;
				EndDo;
			EndDo;
		EndIf;
		
	Else
		
		TableOfProductBalances = GetFromTempStorage(AddressAvailableBalances);
		DeleteFromTempStorage(AddressAvailableBalances);
		
	EndIf;
	
	Goods.Load(TableOfProductBalances);
	For Each String In Goods Do
		String.ThereIsStockInSchedule = String.OnSchedule > 0;
		String.ThereIsStockOnWarehouse = String.InStock > 0;
		String.Department = Department;
	EndDo;
	If SeriesSelection_3 Then
		For Each String In Goods Do
			String.ThisIsSelectedGroupWarehouse = String.Warehouse = WarehouseByDocument;
		EndDo;
	EndIf;
	
	// Filling in the column "Statuskazaniyaseries".
	If SelectSeries Then
		
		TableToFillIn_ = Goods;
		AdditionalColumnsForSpecifyingSeries = KeyParameters.AdditionalColumnsForSpecifyingSeries;
		If AdditionalColumnsForSpecifyingSeries <> Undefined Then
			TableToFillIn_ = Goods.Unload();
			For Each AdditionalColumn In AdditionalColumnsForSpecifyingSeries Do
				TableToFillIn_.Columns.Add(AdditionalColumn.Key);
			EndDo;
			For Each String In TableToFillIn_ Do
				FillPropertyValues(String, AdditionalColumnsForSpecifyingSeries);
			EndDo;
		EndIf;
		
		DataProcessors.QuantityAndBatchRequest.FillInStatusOfSeriesIndicationInTable(
			SupplyOption, TableToFillIn_, SeriesSpecificationParameters, FillingData.Warehouse);
		
		If AdditionalColumnsForSpecifyingSeries <> Undefined Then
			Goods.Load(TableToFillIn_);
		EndIf;
	
	EndIf;
	
	// Filling in the column "This is the document structure".
	ItemsType = Common.ObjectAttributeValue(Products, "ItemsType");
	WarehouseDivisionByDocument = ?(ItemsType = Enums.ItemsTypes.OwnGoods, WarehouseByDocument,
	                                ?(ItemsType = Enums.ItemsTypes.ReusablePackage, WarehouseByDocument,
	                                ?(ItemsType = Enums.ItemsTypes.Work_5, Department,
	                                Undefined)));
	
	Filter = New Structure("Warehouse,WithAssignment", WarehouseDivisionByDocument, WithAssignment);
	FoundRows = Goods.FindRows(Filter);
	
	// The document line should be made visible regardless of the display modes of the remainder.
	If FoundRows.Count() > 0 Then
		FoundRows[0].ThisIsDocumentRow = True;
		FoundRows[0].ThereIsStockOnWarehouse = True;
		FoundRows[0].ThereIsStockInSchedule = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf