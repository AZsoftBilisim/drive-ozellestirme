////////////////////////////////////////////////////////////////////////////////
// The "Set of Server Calls" module contains procedures and functions for
// working with sets.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// The procedure sets the conditional design for the Set mechanism
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which you want to set the conditional design should contain:
//    * Object - DocumentObject
//  TSName - String - name of the table part
//  TSForms - Boolean - PM is a form prop.
//
Procedure SetConditionalAppearance(Form, TSName, TSForms = False) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items           = Form.Items;
	
	ItemsToLock = SetsClientServer.ItemsToLock(TSName);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	For Each ItemToLock In ItemsToLock Do
		If Items.Find(ItemToLock) <> Undefined Then
			ItemField = Item.Fields.Items.Add();
			FormItem = Items[ItemToLock]; // FormGroup, FormTable, FormField, FormButton
			ItemField.Field = New DataCompositionField(FormItem.Name);
		EndIf;
	EndDo;

	If TSForms Then
		Path = TSName;
	Else
		Path = "Object." + TSName;
	EndIf;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(Path + ".ProductsInSet");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure


// The procedure should be called when the set editing
// is finished in the set editing form.
//
// Parameters:
//  Form - ClientApplicationForm
//  TSName - String - name of the table part
//  Parameters - Structure:
//  * Data - ValueTable
//  * StructureOfActionsWithModifiedStrings - Structure
//  * StructureOfActionsWithAddedStrings - Structure
//  * DialColumns - Array of String
//  * MapColumnNames - Map of KeyAndValue:
//    ** Key - String
//    ** Value - String
//                - Undefined
//
Procedure AtEndOfEditingSet(Form, TSName = "Goods", Parameters) Export
	
	Data                                 = Parameters.Data;
	StructureOfActionsWithModifiedStrings  = Parameters.StructureOfActionsWithModifiedStrings;
	StructureOfActionsWithAddedStrings = Parameters.StructureOfActionsWithAddedStrings;
	Columns                                = Parameters.DialColumns;
	ThereAreModifiedColumns                  = Parameters.Property("MapColumnNames");
	
	Filter = New Structure;
	Filter.Insert("ProductsInSet",   Data.ProductsInSet);
	Filter.Insert("ItemVariantOfSet", Data.ItemVariantOfSet);
	If Columns.Find("DocumentSalesOfGoodsAndServices") <> Undefined Then
		Filter.Insert("DocumentSalesOfGoodsAndServices", Data.DocumentSalesOfGoodsAndServices);
	EndIf;
	
	UntieFromSet = False;
	If Data.Property("UntieFromSet") Then
		UntieFromSet = Data.UntieFromSet;
	EndIf;
	
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, TSName) Then
		TS = Form.Object[TSName];
	Else
		TS = Form[TSName];
	EndIf;
	
	TSForCheck = TS.Unload(New Array);	//ValueTable


	ThereIsSalesOrder = TSForCheck.Columns.Find("SalesOrder") <> Undefined;
	If ThereIsSalesOrder Then
		Filter.Insert("SalesOrder", Data.SalesOrder);
	EndIf;
	SetLines = TS.FindRows(Filter);

	ItIsRequiredToDefineParametersOfBatchesOfModifiedLines = False;
	SeriesParameters_ = Undefined;
	If StructureOfActionsWithModifiedStrings.Property("CheckSeriesCalculateStatus", SeriesParameters_) Then
		ItIsRequiredToDefineParametersOfBatchesOfModifiedLines = SeriesParameters_ = Undefined;
	EndIf;
	ItIsRequiredToDefineParametersOfBatchesOfAddedLines = False;
	SeriesParameters_ = Undefined;
	If StructureOfActionsWithAddedStrings.Property("CheckSeriesCalculateStatus", SeriesParameters_) Then
		ItIsRequiredToDefineParametersOfBatchesOfAddedLines = SeriesParameters_ = Undefined;
	EndIf;
	OrderLinesToAdd = New Array;
	AddedLinesImplementation = New Array;	
	ChangeableOrderLines = New Array;
	ChangeableOrderLinesWithDiscountRecalculation = New Array;
	MutableStringsImplementation = New Array;	
	ChangeableRowsImplementationWithDiscountRecalculation = New Array;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each TSRow In Data.Components Do
		
		Filter = New Structure;
		Filter.Insert("LineNumber", TSRow.DocumentRowNumber);
		
		If TMCommonUseClientServer.HasObjectAttribute(Form.Object, TSName) Then
			FoundRows = Form.Object[TSName].FindRows(Filter);
		Else
			FoundRows = Form[TSName].FindRows(Filter);
		EndIf;
		
		If FoundRows.Count() > 0 Then
			
			CurrentRow = FoundRows[0];
			
			ChangedFields = New Array;
			For Each Column In Columns Do
				NameOfDocumentColumn = Column;
				If ThereAreModifiedColumns Then 
					NameOfDocumentColumn = Parameters.MapColumnNames.Get(Column);
					If NameOfDocumentColumn = Undefined Then
						NameOfDocumentColumn = Column;
					EndIf;
				EndIf;
				If CurrentRow[NameOfDocumentColumn] <> TSRow[Column] Then
					CurrentRow[NameOfDocumentColumn] = TSRow[Column];
					ChangedFields.Add(Column);
				EndIf;
			EndDo;
			
			If UntieFromSet Then
				CurrentRow.ProductsInSet   = Undefined;
				CurrentRow.ItemVariantOfSet = Undefined;
				CurrentRow.SetIndex         = 0;
			EndIf;
			
			ClearingAutomaticDiscounts = False;
			If ChangedFields.Find("NumberOfPackages") <> Undefined
				Or ChangedFields.Find("Price") <> Undefined
				Or ChangedFields.Find("PriceKind") <> Undefined Then
				ClearingAutomaticDiscounts = True;
			EndIf;
			
			TargetArray = ChangeableOrderLines;
			
			If ItIsRequiredToDefineParametersOfBatchesOfModifiedLines Then
				SeriesSpecificationParameters = DefineSerialSalesAssistantParameters(Form.SeriesSpecificationParameters, CurrentRow);
				If SeriesSpecificationParameters = Form.SeriesSpecificationParameters.SaleOfGoodsAndServices Then
					TargetArray = MutableStringsImplementation;
				EndIf;
			EndIf;
			
			If StructureOfActionsWithModifiedStrings.Property("RecalculateAmountTakingIntoAccountAutomaticDiscount")
				And ClearingAutomaticDiscounts Then
				If TargetArray = ChangeableOrderLines Then
					TargetArray = ChangeableOrderLinesWithDiscountRecalculation;
				ElsIf TargetArray = MutableStringsImplementation Then
					TargetArray = ChangeableRowsImplementationWithDiscountRecalculation;
				EndIf;
			EndIf;
			
			TargetArray.Add(CurrentRow);
			
			RowIndex = SetLines.Find(CurrentRow);
			If Not RowIndex = Undefined Then
				SetLines.Delete(RowIndex);
			EndIf;
			
		Else
			
			NewRow = TS.Add();
			NewRow.ProductsInSet   = Data.ProductsInSet;
			NewRow.ItemVariantOfSet = Data.ItemVariantOfSet;
			
			FillPropertyValues(NewRow, TSRow,,"ProductsInSet,ItemVariantOfSet");
			NewRow.SetIndex = ?(ValueIsFilled(NewRow.ProductsInSet), 1, 0);
			
			If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "DocumentCreationOption") Then
				FillInDesignOptionInLineOfTablePartOfSalesAssistant(NewRow, Form.Object.DocumentCreationOption);
			EndIf;

			TargetArray = OrderLinesToAdd;

			If ItIsRequiredToDefineParametersOfBatchesOfAddedLines Then
				SeriesSpecificationParameters = DefineSerialSalesAssistantParameters(Form.SeriesSpecificationParameters, NewRow);
				If SeriesSpecificationParameters = Form.SeriesSpecificationParameters.SaleOfGoodsAndServices Then
					TargetArray = AddedLinesImplementation;
				EndIf;
				StructureOfActionsWithAddedStrings.CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters);
			EndIf;

			TargetArray.Add(NewRow);
			
		EndIf;
		
	EndDo;

	If ChangeableOrderLines.Count() Then
		If ItIsRequiredToDefineParametersOfBatchesOfModifiedLines Then
			SeriesSpecificationParameters = DefineSerialSalesAssistantParameters(Form.SeriesSpecificationParameters, ChangeableOrderLines[0]);
			StructureOfActionsWithModifiedStrings.CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters);
		EndIf;
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ChangeableOrderLines,
			StructureOfActionsWithModifiedStrings,
			TS,
			CachedValues);
	EndIf;

	If MutableStringsImplementation.Count() Then
		If ItIsRequiredToDefineParametersOfBatchesOfModifiedLines Then
			SeriesSpecificationParameters = DefineSerialSalesAssistantParameters(Form.SeriesSpecificationParameters, MutableStringsImplementation[0]);
			StructureOfActionsWithModifiedStrings.CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters);
		EndIf;
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			MutableStringsImplementation,
			StructureOfActionsWithModifiedStrings,
			TS,
			CachedValues);
	EndIf;

	If ChangeableOrderLines.Count() Then
		If ItIsRequiredToDefineParametersOfBatchesOfModifiedLines Then
			SeriesSpecificationParameters = DefineSerialSalesAssistantParameters(Form.SeriesSpecificationParameters, ChangeableOrderLines[0]);
			StructureOfActionsWithModifiedStrings.CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters);
		EndIf;
		If StructureOfActionsWithModifiedStrings.Property("RecalculateAmountTakingIntoAccountAutomaticDiscount") Then
			StructureOfActionsWithModifiedStrings.RecalculateAmountTakingIntoAccountAutomaticDiscount.Insert("Clear", True);
		EndIf;
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ChangeableOrderLines,
			StructureOfActionsWithModifiedStrings,
			TS,
			CachedValues);
	EndIf;

	If MutableStringsImplementation.Count() Then
		If ItIsRequiredToDefineParametersOfBatchesOfModifiedLines Then
			SeriesSpecificationParameters = DefineSerialSalesAssistantParameters(Form.SeriesSpecificationParameters, MutableStringsImplementation[0]);
			StructureOfActionsWithModifiedStrings.CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters);
		EndIf;
		If StructureOfActionsWithModifiedStrings.Property("RecalculateAmountTakingIntoAccountAutomaticDiscount") Then
			StructureOfActionsWithModifiedStrings.RecalculateAmountTakingIntoAccountAutomaticDiscount.Insert("Clear", True);
		EndIf;
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			MutableStringsImplementation,
			StructureOfActionsWithModifiedStrings,
			TS,
			CachedValues);
	EndIf;

	If OrderLinesToAdd.Count() Then
		If ItIsRequiredToDefineParametersOfBatchesOfAddedLines Then
			SeriesSpecificationParameters = DefineSerialSalesAssistantParameters(Form.SeriesSpecificationParameters, OrderLinesToAdd[0]);
			StructureOfActionsWithAddedStrings.CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters);
		EndIf;
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			OrderLinesToAdd,
			StructureOfActionsWithAddedStrings,
			TS,
			CachedValues);
	EndIf;

	If AddedLinesImplementation.Count() Then
		If ItIsRequiredToDefineParametersOfBatchesOfAddedLines Then
			SeriesSpecificationParameters = DefineSerialSalesAssistantParameters(Form.SeriesSpecificationParameters, AddedLinesImplementation[0]);
			StructureOfActionsWithAddedStrings.CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters);
		EndIf;
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			AddedLinesImplementation,
			StructureOfActionsWithAddedStrings,
			TS,
			CachedValues);
	EndIf;

	For Each SetString_ In SetLines Do
		TS.Delete(SetString_);
	EndDo;
	
	Form.Modified = True;
	
EndProcedure

// The procedure must be called when reading or creating a form on the server
//
// Parameters:
//  Form - ClientApplicationForm - 
//  TSName - String - name of the table part
//  TSTableOfShapeValues - Boolean - 
//
Procedure FillInServiceDetails(Form, TSName = "Goods", TSTableOfShapeValues = False) Export
	
	If Not TSTableOfShapeValues And TMCommonUseClientServer.HasObjectAttribute(Form.Object, TSName) Then
		TS = Form.Object[TSName];
	Else
		TS = Form[TSName];
	EndIf;
	
	For Each TSRow In TS Do
		
		TSRow.SetIndex = ?(ValueIsFilled(TSRow.ProductsInSet), 1, 0);
		
	EndDo;
	
EndProcedure

// Returns the address of the set in temporary storage for
// later editing the set in temporary storage.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  Parameters - Structure - Parameters
//  TSName - String - name of the table part
//
// Returns:
//  String - the address in the temporary storage.
//
Function SetAddressInTemporaryStorage(Form, Parameters, TSName = "Goods") Export
	
	Parameters.DialColumns.Add("LineNumber");
	Parameters.DialColumns.Add("DocumentRowNumber");
	Components = CreateSetCompositionTable(Parameters.DialColumns);
	
	ThereAreChangedColumnNames = Parameters.Property("MatchingColumnNamesForSet");

	CopyQuantity = False;
	
	If Not ThereAreChangedColumnNames Then
		If Parameters.DialColumns.Find("Count") <> Undefined
			And Parameters.DialColumns.Find("NumberOfPackages") = Undefined Then
			CopyQuantity = True;
		EndIf;
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ProductsInSet",   Parameters.ProductsInSet);
	FilterParameters.Insert("ItemVariantOfSet", Parameters.ItemVariantOfSet);
	If Parameters.DialColumns.Find("DocumentSalesOfGoodsAndServices") <> Undefined Then
		FilterParameters.Insert("DocumentSalesOfGoodsAndServices", Parameters.DocumentSalesOfGoodsAndServices);
	EndIf;
	If Parameters.Property("SalesOrder") = True Then
		FilterParameters.Insert("SalesOrder", Parameters.SalesOrder);
	EndIf;
	
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, TSName) Then
		FoundRows = Form.Object[TSName].FindRows(FilterParameters);
	Else
		FoundRows = Form[TSName].FindRows(FilterParameters);
	EndIf;
	
	For Each FoundRow In FoundRows Do
		
		NewRow = Components.Add();
		FillPropertyValues(NewRow, FoundRow);
		NewRow.DocumentRowNumber = NewRow.LineNumber;
		If ThereAreChangedColumnNames Then
			For Each Item In Parameters.MatchingColumnNamesForSet Do
				NewRow[Item.Key] = FoundRow[Item.Value];
			EndDo;
		EndIf;
		If CopyQuantity Then
			NewRow.NumberOfPackages = NewRow.Count;
		EndIf;
		
	EndDo;
	
	Return PutToTempStorage(Components, Form.UUID);
	
EndFunction

// Returns a table of coefficients for the distribution of the kit price for components
//
// Parameters:
//  TabularSection - ClientApplicationForm - shape.
//  Parameters - Structure - distribution parameters.
//
// Returns:
//  ValueTable - Table of coefficients of distribution of the kit price for components.
//
Function DistributionCoefficients(TabularSection, Parameters) Export
	
	Query = New Query(
	"SELECT
	|	Table.LineNumber                                       AS LineNumber,
	|	Table.ProductsInSet                                AS ProductsInSet,
	|	Table.ItemVariantOfSet                              AS ItemVariantOfSet,
	|	Table.Products                                      AS Products,
	|	Table.Characteristic                                    AS Characteristic,
	|	Table.Package                                          AS Package,
	|	Table.Count                                        AS Count,
	|	Table.NumberOfPackages                                AS NumberOfPackages
	|INTO Table
	|FROM
	|	&TabularSection AS Table
	|;
	|
	|//////////////////////////
	|SELECT
	|	Table.LineNumber                                       AS LineNumber,
	|	Table.ProductsInSet                                AS ProductsInSet,
	|	Table.ItemVariantOfSet                              AS ItemVariantOfSet,
	|	Table.Products                                      AS Products,
	|	Table.Characteristic                                    AS Characteristic,
	|	Table.Package                                          AS Package,
	|	Table.Count                                        AS Count,
	|	Table.NumberOfPackages                                AS NumberOfPackages,
	|	ProductKitConfigurations.Ref                   AS ProductKitConfigurations,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption
	|INTO TableWithConfigurationOptions
	|FROM
	|	Table AS Table
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON Table.ProductsInSet = ProductKitConfigurations.Owner
	|			AND Table.ItemVariantOfSet = ProductKitConfigurations.Characteristic
	|			AND ProductKitConfigurations.Main
	|WHERE
	|	ProductKitConfigurations.SetPricingOption <> VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|;
	|
	|/////
	|SELECT
	|	Goods.Ref            AS ProductKitConfigurations,
	|	Goods.Products      AS Products,
	|	Goods.Characteristic    AS Characteristic,
	|	SUM(CASE
	|			WHEN Goods.Count <> 0
	|				THEN Goods.CostShare / Goods.Count
	|			ELSE 0
	|		END) AS CostShare
	|INTO CostShares
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS Goods
	|WHERE
	|	Goods.Ref IN (SELECT DISTINCT T.ProductKitConfigurations FROM TableWithConfigurationOptions AS T WHERE T.SetPricingOption = VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Ref
	|;
	|
	|/////
	|SELECT
	|	Table.LineNumber                                           AS LineNumber,
	|	Table.ProductsInSet                                    AS ProductsInSet,
	|	Table.ItemVariantOfSet                                  AS ItemVariantOfSet,
	|	Table.Products                                          AS Products,
	|	Table.Characteristic                                        AS Characteristic,
	|	Table.Package                                              AS Package,
	|	Table.Count                                            AS Count,
	|	Table.NumberOfPackages                                    AS NumberOfPackages,
	|	CAST(Table.Count * ISNULL(CostShares.CostShare, 0) AS NUMBER(31,2)) AS Price,
	|	Table.ProductKitConfigurations                      AS ProductKitConfigurations,
	|	Table.SetPricingOption                              AS SetPricingOption
	|FROM
	|	TableWithConfigurationOptions AS Table
	|		LEFT JOIN CostShares AS CostShares
	|		ON CostShares.ProductKitConfigurations = Table.ProductKitConfigurations
	|			AND Table.SetPricingOption = VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)
	|			AND Table.Products = CostShares.Products
	|			AND Table.Characteristic = CostShares.Characteristic
	|");
	
	// Unload from the source table
	If TypeOf(TabularSection) = Type("ValueTable") Then
		Query.Parameters.Insert("TabularSection", TabularSection.Copy());
	Else
		Query.Parameters.Insert("TabularSection", TabularSection.Unload());
	EndIf;
	
	CalculationParameters = New Structure;
	For Each Parameter In Parameters Do
		CalculationParameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	CalculationParameters.Insert("CalculateSets", False);
	
	TS = Query.Execute().Unload();
	
	EnterprisePricesFillingServer.FillInPrices(
		TS,
		New Structure("SetPricingOption", Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices), // Array of rows or selection structure
		CalculationParameters);
		
	For Each TSRow In TS Do
		If TSRow.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices Then
			TSRow.Price = Round(TSRow.Price * TSRow.NumberOfPackages, 2);
		EndIf;
	EndDo;
	
	Return TS;
	
EndFunction

#Region PrintForms

// Returns empty values for subsystem parameters.
//
// Returns:
//  Structure - Empty parameter values.
Function BlankData() Export
	
	Character = "";
	BlankData = New Structure;
	BlankData.Insert("Count", Character);
	BlankData.Insert("UnitOfMeasure", Character);
	BlankData.Insert("Price", Character);
	BlankData.Insert("Sum", Character);
	BlankData.Insert("VATRate", Character);
	BlankData.Insert("VATAmount", Character);
	BlankData.Insert("AmountExcludingVAT", Character);
	BlankData.Insert("AmountIncludingVAT", Character);
	BlankData.Insert("VATAmount", Character);
	BlankData.Insert("TypeOfContractorSPrice", Character);
	BlankData.Insert("DateOfShipment", Character);
	BlankData.Insert("Characteristic", Character);
	BlankData.Insert("Package", Character);
	BlankData.Insert("DiscountAmount", Character);
	BlankData.Insert("AmountWithoutADiscount", Character);
	
	BlankData.Insert("ProductsCode", Character);
	BlankData.Insert("ProductCode_", Character);
	BlankData.Insert("UnitOfMeasurementName", Character);
	BlankData.Insert("UnitOfMeasureCode", Character);
	BlankData.Insert("PackageKind", Character);
	BlankData.Insert("QuantityInOnePlace", Character);
	BlankData.Insert("NumberOfSeats", Character);
	BlankData.Insert("GrossWeight", Character);
	
	BlankData.Insert("ExciseDuty", Character);
	
	BlankData.Insert("Cost", Character);
	BlankData.Insert("Total", Character);
	
	Return BlankData;
	
EndFunction

// Returns the prefix and Postfix of the name for output in printed forms
// 
// Parameters:
//  LineProducts_ - Structure - table row
//  UseSets - Boolean - The value of the FO "use Sets".
//
// Returns:
//  Structure - prefix and postfix.
Function GetPrefixAndPostfix(LineProducts_, UseSets) Export
	
	Prefix = "";
	Postfix = "";
	If UseSets 
		And (LineProducts_.TheseAreComponents Or LineProducts_.IsRecordsSet)
		And LineProducts_.PresentationOptionInPrintForms = Enums.OptionsOfSetPresentationInPrintForms.KitAndComponents Then
		
		If LineProducts_.TheseAreComponents Then
			Prefix = Chars.Tab + "•" + " ";
		EndIf;
		
		If LineProducts_.TheseAreComponents
			And (LineProducts_.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
			  Or LineProducts_.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices) Then
			Postfix = " - " + LineProducts_.Count + " " +LineProducts_.UnitOfMeasure;
		EndIf;
		
		FullSet = True;
		If TMCommonUseClientServer.HasObjectAttribute(LineProducts_, "FullSet")
			And LineProducts_.IsRecordsSet Then
			FullSet = LineProducts_.FullSet;
		EndIf;
		
		If LineProducts_.IsRecordsSet
			And LineProducts_.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
			Postfix = " - " + LineProducts_.Count + " " +LineProducts_.UnitOfMeasure;
		EndIf;
		
		If Not FullSet Then
			Postfix = Postfix + " " + NStr("vi = '(Một phần của bộ)';
											|ru = '(Часть набора)';
											|en = '(Part of a set)'; fa = '(Part of a set)';
											|it = '(Parte del set)';
											|pl = '(Część zestawu)';
											|tr = '(Küme bölümü)'");
		EndIf;
		
	EndIf;
	
	Return New Structure("Prefix, Postfix", Prefix, Postfix);
	
EndFunction

// Returns True if the product String should be displayed with empty data in the columns
// except for the name.
// 
// Parameters:
//  LineProducts_ - Structure - Table row.
//  UseSets - Boolean - The value of the FO "use Sets".
//
// Returns:
//  Boolean - The product line should be displayed with empty data in the columns
//           except for the name.
Function DisplayOnlyTitle(LineProducts_, UseSets) Export
	
	If UseSetArea(LineProducts_, UseSets) Then
		Return OutputOnlySetHeader(LineProducts_, UseSets)
	ElsIf UseScope(LineProducts_, UseSets) Then
		Return DisplayOnlyComponentTitle(LineProducts_, UseSets)
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns True if the product String should be displayed with empty data in the columns
// except for the name and this string is part of the set.
// 
// Parameters:
//  LineProducts_ - Structure - Table row.
//  UseSets - Boolean - The value of the FO "use Sets".
//
// Returns:
//  Boolean - 
Function DisplayOnlyComponentTitle(LineProducts_, UseSets) Export
	
	If UseSets
		And LineProducts_.TheseAreComponents
		And LineProducts_.PresentationOptionInPrintForms = Enums.OptionsOfSetPresentationInPrintForms.KitAndComponents
		And (    LineProducts_.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
		   Or LineProducts_.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices)
		Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns True if the product String should be displayed with empty data in columns
// except for the name and this string is a Set.
// 
// Parameters:
//  LineProducts_ - Structure - Table row.
//  UseSets - Boolean - The value of the FO "use Sets".
//
// Returns:
//  Boolean - The product line should be displayed with empty data in the columns
//           except for the name and this line is a set.
//
Function OutputOnlySetHeader(LineProducts_, UseSets) Export
	
	If UseSets
		And LineProducts_.IsRecordsSet
		And LineProducts_.PresentationOptionInPrintForms = Enums.OptionsOfSetPresentationInPrintForms.KitAndComponents
		And LineProducts_.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices
		Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns True if the set area should be used in the printed form
// 
// Parameters:
//  LineProducts_ - Structure - String tables.
//  UseSets - Boolean - The value of the FO "use Sets".
//
// Returns:
//  Boolean - the set area should be used in printed form.
//
Function UseSetArea(LineProducts_, UseSets) Export
	
	If UseSets
		And LineProducts_.IsRecordsSet
		And LineProducts_.PresentationOptionInPrintForms = Enums.OptionsOfSetPresentationInPrintForms.KitAndComponents Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns True if the component area should be used in the printed form.
// 
// Parameters:
//  LineProducts_ - Structure - Table row.
//  UseSets - Boolean - The value of the FO "use Sets".
//
// Returns:
//  Boolean - the component area must be used in printed form.
//
Function UseScope(LineProducts_, UseSets) Export
	
	If UseSets
		And LineProducts_.TheseAreComponents
		And LineProducts_.PresentationOptionInPrintForms = Enums.OptionsOfSetPresentationInPrintForms.KitAndComponents Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Procedure handler for the Delete event
// 
// Parameters:
//  Form     - ClientApplicationForm - 
//  TSName     - String - name of the table part
//  Parameters - Structure - (Sets, Other).
//
Procedure WhenRemovingComponents(Form, TSName, Parameters) Export
	
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, TSName) Then
		TS = Form.Object[TSName];
	Else
		TS = Form[TSName];
	EndIf;

	For IndexOf = -Parameters.Other.Count() + 1 To 0 Do
		TSRow = TS.FindByID(Parameters.Other[-IndexOf]);
		TS.Delete(TSRow);
	EndDo;
	
	For Each Set In Parameters.Sets Do
		FoundRows = TS.FindRows(Set);
		For Each TSRow In FoundRows Do
			TS.Delete(TSRow);
		EndDo;
	EndDo;
	
	Form.Modified = True;
	
EndProcedure

// Deletes rows with sets in the passed table according to the selection.
//
// Parameters:
//  TableOfGoods - ValueTable - A table with the required set nomenclature field.
//  FilterParameters - Array of EnumRef.ItemsTypes - Selection by type of nomenclature.
//
Procedure DeleteRowsOfSetsAccordingToSelection(TableOfGoods, FilterParameters) Export
	
	If TableOfGoods.Columns.Find("ProductsInSet") = Undefined Then
		Return;
	EndIf;
	
	SelectionDoesNotContainSets = FilterParameters.Find(Enums.ItemsTypes.Set) = Undefined;
	
	FilterNotContainsServices = FilterParameters.Find(Enums.ItemsTypes.OperationService) = Undefined
		And FilterParameters.Find(Enums.ItemsTypes.Work_5) = Undefined;
		
	FilterNotContainsGoods = FilterParameters.Find(Enums.ItemsTypes.OwnGoods) = Undefined
		And FilterParameters.Find(Enums.ItemsTypes.ReusablePackage) = Undefined;
		
	If SelectionDoesNotContainSets Or Not (FilterNotContainsServices Or FilterNotContainsGoods) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	*
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.*
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = TableOfGoods.ProductsInSet
	|			AND ProductKitConfigurations.Characteristic = TableOfGoods.ItemVariantOfSet
	|			AND ProductKitConfigurations.Main
	|	
	|WHERE
	|	CASE WHEN ProductKitConfigurations.Ref IS NULL THEN
	|		TRUE
	|	ELSE
	|		&Condition_SetDoesNotContainGoodsServices
	|	END
	|	
	|";
	
	Query.SetParameter("TableOfGoods", TableOfGoods);
	
	Condition = "TRUE";
	If FilterNotContainsServices Then
		Condition = "NOT ProductKitConfigurations.ContainsServices";
	ElsIf FilterNotContainsGoods Then
		Condition = "NOT ProductKitConfigurations.ContainsGoods";
	EndIf;
	Query.Text = StrReplace(Query.Text, "&Condition_SetDoesNotContainGoodsServices", Condition);
	
	TableOfGoods = Query.Execute().Unload();
	
EndProcedure

#EndRegion

#Region Private

// Create a set composition table
//
// Parameters:
//  DialColumns - Array - The names of the columns.
// 
// Returns:
//  ValueTable - Table of the composition of the set.
//
Function CreateSetCompositionTable(DialColumns) Export
	
	Components = New ValueTable;
	
	Components.Columns.Add("ProductsInSet",   New TypeDescription("CatalogRef.Products"));
	Components.Columns.Add("ItemVariantOfSet", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	If DialColumns.Find("LineNumber") <> Undefined Then
		Components.Columns.Add("LineNumber",          TMCommonUse.GetDescriptionOfNumberTypes(5,0));
	EndIf;
	
	If DialColumns.Find("DocumentRowNumber") <> Undefined Then
		Components.Columns.Add("DocumentRowNumber", TMCommonUse.GetDescriptionOfNumberTypes(5,0));
	EndIf;
	
	If DialColumns.Find("Products") <> Undefined Then
		Components.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	EndIf;
	
	If DialColumns.Find("Characteristic") <> Undefined Then
		Components.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	
	If DialColumns.Find("Price") <> Undefined Then
		Components.Columns.Add("Price", TMCommonUse.MoneyFieldTypeDescription());
	EndIf;
	
	If DialColumns.Find("PriceKind") <> Undefined Then
		Components.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
	EndIf;
	
	If DialColumns.Find("Package") <> Undefined Then
		Components.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	EndIf;
	
	If DialColumns.Find("Count") <> Undefined Then
		Components.Columns.Add("Count", TMCommonUse.GetDescriptionOfNumberTypes(15,3));
	EndIf;
	
	If DialColumns.Find("NumberOfPackages") <> Undefined Or DialColumns.Find("Count") <> Undefined Then
		Components.Columns.Add("NumberOfPackages", TMCommonUse.GetDescriptionOfNumberTypes(15,3));
	EndIf;
	
	If DialColumns.Find("PercentRateOfManualDiscount") <> Undefined Then
		Components.Columns.Add("PercentRateOfManualDiscount", TMCommonUse.GetDescriptionOfNumberTypes(15,2));
	EndIf;
	
	If DialColumns.Find("ManualDiscount") <> Undefined Then
		Components.Columns.Add("ManualDiscount", TMCommonUse.MoneyFieldTypeDescription());
	EndIf;
	
	If DialColumns.Find("PercentRateOfAutomaticDiscountMarkup") <> Undefined Then
		Components.Columns.Add("PercentRateOfAutomaticDiscountMarkup", TMCommonUse.GetDescriptionOfNumberTypes(15,2));
	EndIf;
	
	If DialColumns.Find("DiscountMarkupAmount") <> Undefined Then
		Components.Columns.Add("DiscountMarkupAmount", TMCommonUse.MoneyFieldTypeDescription());
	EndIf;
	
	If DialColumns.Find("CancellationReason") <> Undefined Then
		Components.Columns.Add("CancellationReason", New TypeDescription("CatalogRef.ReasonsForSaleOrderCancellation"));
	EndIf;
	
	If DialColumns.Find("Canceled") <> Undefined Then
		Components.Columns.Add("Canceled", New TypeDescription("Boolean"));
	EndIf;
	
	If DialColumns.Find("VATRate") <> Undefined Then
		Components.Columns.Add("VATRate", New TypeDescription("CatalogRef.VATRates"));
	EndIf;
	
	If DialColumns.Find("VATAmount") <> Undefined Then
		Components.Columns.Add("VATAmount", TMCommonUse.MoneyFieldTypeDescription());
	EndIf;

	If DialColumns.Find("AmountIncludingVAT") <> Undefined Then
		Components.Columns.Add("AmountIncludingVAT", TMCommonUse.MoneyFieldTypeDescription());
	EndIf;

	If DialColumns.Find("Sum") <> Undefined Then
		Components.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription());
	EndIf;
	
	If DialColumns.Find("Available") <> Undefined Then
		Components.Columns.Add("Available", TMCommonUse.GetDescriptionOfNumberTypes(15,3));
	EndIf;
	
	If DialColumns.Find("InStock") <> Undefined Then
		Components.Columns.Add("InStock", TMCommonUse.GetDescriptionOfNumberTypes(15,3));
	EndIf;
	
	If DialColumns.Find("DocumentSalesOfGoodsAndServices") <> Undefined Then
		Components.Columns.Add("DocumentSalesOfGoodsAndServices", New TypeDescription("DocumentRef.CustomerInvoice, 
											|DocumentRef.TransferOfGoodsToBailee, 
											|DocumentRef.RetailSalesReport"));
	EndIf;
	
	Return Components;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region SalesWizard

// Returns parameters for specifying series.
//
// Parameters:
//  SeriesSpecificationParameters - Structure - with properties:
//   * SaleOfGoodsAndServices - See ProductsClientServer.SeriesSpecificationParameters
//   * OrderDocument - See ProductsClientServer.SeriesSpecificationParameters
//  CurrentData - CurrentDataOfList - current data.
//
// Returns:
//  Structure - The composition of the fields is set by the Nomenclature Clientserver function.Parameters
//             of the series (see the description of the fields in the comments to this function).
Function DefineSerialSalesAssistantParameters(SeriesSpecificationParameters, CurrentData)
	
	If CurrentData.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice
		Or	CurrentData.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice Then
		Return SeriesSpecificationParameters.SaleOfGoodsAndServices;
	Else
		Return SeriesSpecificationParameters.OrderDocument;
	EndIf;
	
EndFunction

// Fills in the design option in the sales assistant table part row.
//
// Parameters:
//  CurRow - Structure - Current line.
//  DocumentCreationOption - EnumRef.OptionsOfRegisteringSalesDocuments - Version of the design.
//
Procedure FillInDesignOptionInLineOfTablePartOfSalesAssistant(CurRow, DocumentCreationOption)
	
	If DocumentCreationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice") Then
		If CurRow.DateOfShipment = BegOfDay(CurrentSessionDate()) Or CurRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Or CurRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
			CurRow.RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice");
		Else
			CurRow.RegistrationOption = PredefinedValue("Enum.OptionsOfRegisteringSalesDocuments.SalesOrder");
		EndIf;
	Else
		CurRow.RegistrationOption = DocumentCreationOption;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
