#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Procedure - Fill in the Status of the series indication in the line
//  Fills in the Statuses of specifying series for a set of lines.
// Parameters:
//  LinesForSettingStatusOfSeries - Array of LineOfATabularSection - A set of lines to indicate the Status
//  SeriesSpecificationParameters		   - See ProductsClientServer.SeriesSpecificationParameters
//  SupplyOption			   - EnumRef.SupplyOptions - If not specified, it is taken from the string
//
Procedure FillInStatusOfSeriesInLine(LinesForSettingStatusOfSeries, SeriesSpecificationParameters, SupplyOption = Undefined) Export
	
	If LinesForSettingStatusOfSeries.Count() = 0 Then
		Return;
	EndIf;

	EmptyBatch_ = New Structure("Series", Catalogs.ItemsBatches.EmptyRef());

	If Not SeriesSpecificationParameters.UseItemsBatch Then
		For Each String In LinesForSettingStatusOfSeries Do
			String.BatchesIndicationStatus = 0;
			FillPropertyValues(String, EmptyBatch_);
		EndDo;
		Return;
	EndIf;
		
	FirstRow = LinesForSettingStatusOfSeries[0];

	Warehouse = FirstRow.Warehouse;

	StructureWarehouses = New Structure;
	If ValueIsFilled(SeriesSpecificationParameters.WarehouseFieldName) Then
		StructureWarehouses.Insert(SeriesSpecificationParameters.WarehouseFieldName, Warehouse);
	EndIf;
	If ValueIsFilled(SeriesSpecificationParameters.NameOfSenderWarehouseField) Then
		StructureWarehouses.Insert(SeriesSpecificationParameters.NameOfSenderWarehouseField, Warehouse);
	EndIf;
	If ValueIsFilled(SeriesSpecificationParameters.NameOfRecipientWarehouseField) Then
		StructureWarehouses.Insert(SeriesSpecificationParameters.NameOfRecipientWarehouseField, Catalogs.Warehouses.EmptyRef());
	EndIf;

	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfGoods.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	TableOfGoods.Columns.Add("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	TableOfGoods.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
	TableOfGoods.Columns.Add(SeriesSpecificationParameters.FieldNameQuantity, TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
	TableOfGoods.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableOfGoods.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(15, 0, AllowedSign.Nonnegative)));
	If ValueIsFilled(SeriesSpecificationParameters.WarehouseFieldName) Then
		TableOfGoods.Columns.Add(SeriesSpecificationParameters.WarehouseFieldName, New TypeDescription("CatalogRef.Warehouses"));
	EndIf;

	ProductsServer.CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, TableOfGoods); // There is also a statuskazaniyasery

	For Each String In LinesForSettingStatusOfSeries Do
		If SupplyOption = Undefined Then
			RowSecurityOption = String.SupplyOption;
		Else
			RowSecurityOption = SupplyOption;
		EndIf;
		If Not ValueIsFilled(String.Products)
			Or Not ValueIsFilled(String.Warehouse)
			Or SeriesSpecificationParameters.ThisIsOrder
				And RowSecurityOption <> PredefinedValue("Enum.SupplyOptions.Ship")
				And RowSecurityOption <> PredefinedValue("Enum.SupplyOptions.FromWarehouse") Then
			String.BatchesIndicationStatus = 0;
			FillPropertyValues(String, EmptyBatch_);
		Else
			NewRow = TableOfGoods.Add();
			FillPropertyValues(NewRow, String);
			If SupplyOption <> Undefined Then
				NewRow.SupplyOption = RowSecurityOption;
			EndIf;
			NewRow.LineNumber = TableOfGoods.IndexOf(NewRow) + 1;
		EndIf;
	EndDo;

	If TableOfGoods.Count() = 0 Then
		Return;
	EndIf;

	ObjectStructure_ = Common.ValueTableRowToStructure(TableOfGoods[0]);
	CommonClientServer.SupplementStructure(ObjectStructure_, StructureWarehouses, True);

	If Not SeriesSpecificationParameters.ProductInHeader Then
		ObjectStructure_.Insert(SeriesSpecificationParameters.NameTSGoods, TableOfGoods);
	EndIf;

	If SeriesSpecificationParameters.TSSeriesName <> SeriesSpecificationParameters.NameTSGoods
		And ValueIsFilled(SeriesSpecificationParameters.TSSeriesName) Then
		TableOfSeries = TableOfGoods.Copy();
		ObjectStructure_.Insert(SeriesSpecificationParameters.TSSeriesName, TableOfSeries);
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ObjectStructure_, SeriesSpecificationParameters);

	If SeriesSpecificationParameters.ProductInHeader Then
		FirstRow.BatchesIndicationStatus = ?(ObjectStructure_.BatchesIndicationStatus > 8, ObjectStructure_.BatchesIndicationStatus, 0);
		If FirstRow.BatchesIndicationStatus = 0 Then
			FillPropertyValues(FirstRow, EmptyBatch_);
		EndIf;
	Else
		For Each LineOfATabularSection In ObjectStructure_[SeriesSpecificationParameters.NameTSGoods] Do
			String = LinesForSettingStatusOfSeries.Get(LineOfATabularSection.LineNumber - 1);
			String.BatchesIndicationStatus = ?(LineOfATabularSection.BatchesIndicationStatus > 8, LineOfATabularSection.BatchesIndicationStatus, 0);
			If String.BatchesIndicationStatus = 0 Then
				FillPropertyValues(String, EmptyBatch_);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf