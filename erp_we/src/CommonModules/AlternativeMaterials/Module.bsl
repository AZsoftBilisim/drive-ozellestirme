////////////////////////////////////////////////////////////////
// The Analogimaterials module contains procedures and functions for 
// working with the mechanism of replacing materials with analogues.
//
////////////////////////////////////////////////////////////////
//

#Region Public

#Region StructureOfData

// Returns the structure of fields for uploading and filling in the table.
//
// Returns:
// 	Structure - contains fields:
//		* MainField		  - String 	  - the main fields of the table separated by commas
//		* AdditionalFields  - Structure - structure of additional fields-key: name field 
//																			 value: type description
//		* SpoofFields     - Structure - structure of substituted fields-kluya: name of the field to fill
//																		  in value: name field data source to fill in
//		* DefaultValues - Structure - structure of default values key: the name of the field
//																			  value: the value field
// 
Function StructureOfTableFieldsToReplaceWithAnalogues() Export
	
	FieldsStructure = ProductionServer.TableFieldStructure();
	
	FieldsStructure.MainField = "LineNumber,
				   				  |Products,
				   				  |Characteristic, 
				   				  |Count";	
	
	FieldsStructure.AdditionalFields.Insert("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	FieldsStructure.AdditionalFields.Insert("Purpose", New TypeDescription("CatalogRef.Assignments"));
	FieldsStructure.AdditionalFields.Insert("WithAssignment", New TypeDescription("Boolean"));
	FieldsStructure.AdditionalFields.Insert("TotalCount1", Common.TypeDescriptionNumber(15, 3));
	
	Return FieldsStructure;
	
EndFunction

// Returns the parameters required for selecting analogs
//
// Parameters:
//  SourceType - TypeDescription - source type of the parameter generation section
//
// Returns:
//  Structure - Contains:
//   * GeneralParameters    - Structure - Contains:
//                          ** ShowBalance - Boolean -
//                          ** DetailsMode - Boolean - used when opening the matching form
//                          ** SelectionOfPermissions - Map of KeyAndValue - collection where:  
//                          	*** Key - String - The name of the field for which the selection is applied.
//                          	*** Value - String - Name of the parameter in the request.
//                          ** PermissionSelectionParameters - Map of KeyAndValue - collection where: 
//                          	*** Key - String - Name of the parameter in the request.
//                          	*** Value - AnyRef - parameter value.
//   * GoodsParameters  - Structure - Contains:
//                          ** Goods                       - String               - address of temporary storage
//                          ** GoodsNonReplaceableQuantity - String, Undefined - address of temporary storage
//                          ** InventoryAllocation         - String, Undefined - address of temporary storage
//                          ** GoodsTogetherWithParameters     - Boolean               - indicates where to fill in the product parameters
//   * SubstitutesParameters - Structure - Contains:
//                          ** ParametersTable - See TableOfAnalogParameters
//                          ** Reserves           - ValueTable, Undefined -
//                          ** Warehouse             - CatalogRef.Warehouses, Undefined -
//
Function AnalogSelectionParameters(SourceType) Export

	Parameters = New Structure;
	Parameters.Insert("GeneralParameters", New Structure);
	Parameters.Insert("GoodsParameters", New Structure);
	Parameters.Insert("SubstitutesParameters", New Structure);
	
	Parameters.GeneralParameters.Insert("ShowBalance");
	Parameters.GeneralParameters.Insert("DetailsMode", False);
	Parameters.GeneralParameters.Insert("SelectionOfPermissions", New Map);
	Parameters.GeneralParameters.Insert("PermissionSelectionParameters", New Map);

	Parameters.GoodsParameters.Insert("Goods");
	Parameters.GoodsParameters.Insert("GoodsNonReplaceableQuantity");
	Parameters.GoodsParameters.Insert("InventoryAllocation");
	Parameters.GoodsParameters.Insert("GoodsTogetherWithParameters", False);
	
	Parameters.SubstitutesParameters.Insert("ParametersTable", TableOfAnalogParameters(SourceType));
	Parameters.SubstitutesParameters.Insert("Reserves");
	Parameters.SubstitutesParameters.Insert("Warehouse");
		
	Return Parameters;
	
EndFunction

#EndRegion

#Region DataGeneration

// Returns the address of the temporary storage of the inventory allocation table created from the object data
//
// Parameters:
//  Form 					  - Structure, FormDataStructure				  - See ProvisionInDocumentsServer.InventoryAllocationForDocumentBeingEdited
//	AddressInStorage           - String                                        - address of the product table in the storage
// 	AddressInTempStorage - UUID, String, Undefined - Temporary storage address
//
// Returns:
// 	String - the address of the temporary storage of the table value 
// 
Function PlaceInventoryDistributionInTemporaryStorage(
			Form, AddressInStorage, AddressInTempStorage = Undefined) Export
			
	InventoryAllocationTable	= ProvisionInDocumentsServer.InventoryAllocationForDocumentBeingEdited(
									True,
									Form,
									False);
			
	SupplementInventoryDistributionTable(AddressInStorage, InventoryAllocationTable);		
		
	Return PutToTempStorage(InventoryAllocationTable, AddressInTempStorage);
	
EndFunction	

// Returns additional parameters used in the method " getdannyetovars"
// 
// Returns:
//  Structure - Contains:
//   * RowFilter - Structure, Undefined - key: name of the table Attribute
//                                            value: array of table Attribute values to select.
//   * SourceOfResults - ValueTable, FormDataCollection, Undefined - The table of values for calculating totals,
//                                                                            if Undefined, is then determined through the Form.
//   * CallingFromForm   - Boolean - indicates a call from a Form. The default is TRUE.
//
Function AdditionalParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("RowFilter");
	Parameters.Insert("SourceOfResults");
	Parameters.Insert("CallingFromForm", True);
	
	Return Parameters;
	
EndFunction

// Generates product data for displaying, selecting, and replacing analogs
//
// Parameters:
// 	Form                   - ClientApplicationForm - 
// 	ObjectName              - String - Object name
// 	TableName              - String - table name
//	Mode                   - Number - 0 - show analogs
//                                    1 - find analogues
//                                    2 - replace with analogs.
//  DistributeStocks      - Boolean - 
//  FieldsStructure          - See AlternativeMaterials.StructureOfTableFieldsToReplaceWithAnalogues
//	AdditionalParameters - See AlternativeMaterials.AdditionalParameters
// 
// Returns:
//  Structure - See AlternativeMaterials.AnalogSelectionParameters key Parametrelerin
//
Function GetProductData(
			Form,
			ObjectName,
			TableName,
			Mode,
			DistributeStocks,
			FieldsStructure,
			AdditionalParameters = Undefined) Export
	
	CallingFromForm		= True;
	RowFilter			= Undefined;
	SourceOfResults		= Undefined;

	If TypeOf(AdditionalParameters) = Type("Structure") Then
		AdditionalParameters.Property("CallingFromForm",   CallingFromForm);
		AdditionalParameters.Property("RowFilter",     RowFilter);
		AdditionalParameters.Property("SourceOfResults", SourceOfResults);
	EndIf;
	
	ProductsAddressInStorage = Undefined;
	ProductsNonReplaceableQuantityAddressInStorage = Undefined;
	DistributionOfStocksAddressInStorage = Undefined;
			
	If Mode = 0 Then// show analogs
		
		// Goods
		ProductsAddressInStorage = ProductionServer.PlaceStringDataInTemporaryStorage(
									Form, ObjectName, TableName, False, FieldsStructure, RowFilter);
		
	ElsIf Mode = 1 Then// find analogues 
		
		// Goods
		NamesOfDimensionColumns = New Array;
		NamesOfDimensionColumns.Add("Products");
		NamesOfDimensionColumns.Add("Characteristic");
		NamesOfDimensionColumns.Add("Purpose");
		
		If Not FieldsStructure.DefaultValues.Property("Warehouse") Then
			NamesOfDimensionColumns.Add("Warehouse");
		EndIf;
		
		If Not FieldsStructure.DefaultValues.Property("WithAssignment") Then
			NamesOfDimensionColumns.Add("WithAssignment");
		EndIf;
		
		ColumnSettings = New Structure;
		ColumnSettings.Insert("NameOfSummableColumn", "Count");
		ColumnSettings.Insert("SummaryColumn", New Structure("Name, ValueType", "TotalCount1"));
		ColumnSettings.Insert("GroupingColumns", StrConcat(NamesOfDimensionColumns, ", "));
		
		DataTable = ProductionServer.TableWithTotalValueOfColumnByRow(
							Form, ObjectName, TableName, True, ColumnSettings, RowFilter, SourceOfResults);
								
		FormData1 = New Structure;
		FormData1.Insert("UUID", Form.UUID);
		FormData1.Insert(ObjectName, New Structure);
		FormData1[ObjectName].Insert(TableName, DataTable);
		
		ProductsAddressInStorage = ProductionServer.PlaceStringDataInTemporaryStorage(
									FormData1, ObjectName, TableName, False, FieldsStructure);
			
		// Inventories
		If DistributeStocks Then
			
			DistributionOfStocksAddressInStorage = PlaceInventoryDistributionInTemporaryStorage(Form, ProductsAddressInStorage);
			
		EndIf;	
							
	ElsIf Mode = 2 Then// replace with analogues
		
		InventoryAllocationTable = ProvisionInDocumentsServer.InventoryAllocationForDocumentBeingEdited(
										CallingFromForm,
										Form,
										True);
										
		InventoryAllocationTable.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
		
		For Each InventoryLine In InventoryAllocationTable Do
			
			InventoryLine.WithAssignment = InventoryLine.Purpose = Undefined Or ValueIsFilled(InventoryLine.Purpose);
			
			If InventoryLine.Purpose = Undefined Then
				InventoryLine.Purpose = Catalogs.Assignments.EmptyRef();
			EndIf;	
			
		EndDo;	
				
		// Goods
		SecurityTable = InventoryAllocationTable.Copy(
			New Structure("InventoryState", Undefined)); // See ProductionServer.ServiceStructureOfValueTable
		
		SecurityTable.Columns.ShipmentOrder.Name = "Ref";
		
		ObjectTable = Form[ObjectName][TableName];
		SourceTable_ = ?(TypeOf(ObjectTable) = Type("ValueTable"), ObjectTable.Copy(), ObjectTable.Unload()); // ValueTable - 
		SourceTable_.Columns.Add("QuantityIsProvided", Common.TypeDescriptionNumber(15, 3));
		
		If RowFilter <> Undefined Then
					
			CancelStringProcessing = False;
			LinesToDelete = New Array;
			
			For Each SourceString In SourceTable_ Do
			
				For Each FilterElement In RowFilter Do
					If FilterElement.Value.Find(SourceString[FilterElement.Key]) = Undefined Then
						LinesToDelete.Add(SourceString);
						Break;
					EndIf;
				EndDo;	
			
			EndDo;
			
			TMCommonUse.DeleteTableRows(SourceTable_, LinesToDelete);
			
		EndIf;
		
		NamesOfSelectionFieldsByProductType = New Array;
		NamesOfSelectionFieldsByProductType.Add("Products");
		NamesOfSelectionFieldsByProductType.Add("Characteristic");
		NamesOfSelectionFieldsByProductType.Add("WithAssignment");
		NamesOfSelectionFieldsByProductType.Add("SupplyOption");
		
		If Not FieldsStructure.DefaultValues.Property("Warehouse") Then
			NamesOfSelectionFieldsByProductType.Add("Warehouse");
		EndIf;
		
		NamesOfSelectionFieldsByLineNumber = New Array;
		NamesOfSelectionFieldsByLineNumber.Add("LineNumber");
		
		If SourceTable_.Columns.Find("Ref") <> Undefined Then
			NamesOfSelectionFieldsByProductType.Add("Ref");
			NamesOfSelectionFieldsByLineNumber.Add("Ref");
		EndIf;
		
		SelectionFieldsByProductType = StrConcat(NamesOfSelectionFieldsByProductType, ", ");
		SelectionFieldsByLineNumber = StrConcat(NamesOfSelectionFieldsByLineNumber, ", ");
		
		SourceTable_.Indexes.Add(SelectionFieldsByProductType);
		SourceTable_.Indexes.Add(SelectionFieldsByLineNumber);
		
		DataTable = SourceTable_.CopyColumns();
		
		FilterRemainingGoodsByShelfLives = New Structure(SelectionFieldsByProductType);
		
		SelectionByLineNumber_ = New Structure(SelectionFieldsByLineNumber);
		
		While SecurityTable.Count() > 0 Do
			
			SecurityLine = SecurityTable[0];
			
			FillPropertyValues(FilterRemainingGoodsByShelfLives, SecurityLine);
			FilterRemainingGoodsByShelfLives.SupplyOption = Enums.SupplyOptions.ReserveAsReceived;
			ArrayOfStringsPreliminary = SourceTable_.FindRows(FilterRemainingGoodsByShelfLives);
			FilterRemainingGoodsByShelfLives.SupplyOption = Enums.SupplyOptions.ToSupply;
			RowsArray = SourceTable_.FindRows(FilterRemainingGoodsByShelfLives);
			CommonClientServer.SupplementArray(RowsArray, ArrayOfStringsPreliminary);
			
			While RowsArray.Count() > 0 Do
				
				SourceString = RowsArray[0];
				
				If RowFilter <> Undefined Then
					
					CancelStringProcessing = False;
					
					For Each FilterElement In RowFilter Do
						If FilterElement.Value.Find(SourceString[FilterElement.Key]) = Undefined Then
							CancelStringProcessing = True;
							Break;
						EndIf;
					EndDo;
					
					If CancelStringProcessing Then
						SourceTable_.Delete(SourceString);
						RowsArray.Delete(0);
						Continue;
					EndIf;
					
				EndIf;
				
				FillPropertyValues(SelectionByLineNumber_, SourceString);
				
				ArrayOfProcessedStrings = DataTable.FindRows(SelectionByLineNumber_);
				If ArrayOfProcessedStrings.Count() > 0 Then
					DataString1 = ArrayOfProcessedStrings[0];	
				Else
					DataString1 = DataTable.Add();
					FillPropertyValues(DataString1, SourceString);
				EndIf;
				
				DistributionQuantity = Min(SecurityLine.Count, SourceString.Count);
				
				DataString1.Count = DataString1.Count - DistributionQuantity;
				
				SourceString.QuantityIsProvided = SourceString.QuantityIsProvided + DistributionQuantity;
				SourceString.Count = SourceString.Count - DistributionQuantity;	
				SecurityLine.Count = SecurityLine.Count - DistributionQuantity;	

				If SourceString.Count = 0 Then
					SourceTable_.Delete(SourceString);
					RowsArray.Delete(0);
				EndIf;
				
				If SecurityLine.Count = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
			SecurityTable.Delete(SecurityLine);
			
		EndDo;
		
		// Filling in the quantity
		If DataTable.Columns.Find("TotalCount1") = Undefined Then
		
			DataTable.Columns.Add("TotalCount1", Common.TypeDescriptionNumber(15, 3));
			
		EndIf;
		
		CheckSecurityOption = SourceTable_.Columns.Find("SupplyOption") <> Undefined;
		ArrayOfExcludedOptions = New Array;
		ArrayOfExcludedOptions.Add(Enums.SupplyOptions.Ship);
		
		For Each SpecificationRow In DataTable Do
			SpecificationRow.TotalCount1 = SpecificationRow.Count;
		EndDo;
		
		For Each RowOfOriginalTable In SourceTable_ Do
			
			If CheckSecurityOption
			   And ArrayOfExcludedOptions.Find(RowOfOriginalTable.SupplyOption) <> Undefined Then
			
				Continue;
			
			EndIf;
			
			FillPropertyValues(SelectionByLineNumber_, RowOfOriginalTable);
			RowsArray = DataTable.FindRows(SelectionByLineNumber_);
			
			If RowsArray.Count() > 0 Then
			
				For Each SpecificationRow In RowsArray Do
					SpecificationRow.TotalCount1 = SpecificationRow.TotalCount1 + RowOfOriginalTable.QuantityIsProvided;
				EndDo;
				
			Else
				
				NewRow = DataTable.Add();
				FillPropertyValues(NewRow, RowOfOriginalTable);
				NewRow.TotalCount1 = RowOfOriginalTable.Count;
			
			EndIf;
			RowOfOriginalTable.Count = RowOfOriginalTable.QuantityIsProvided;
		
		EndDo;
		
		FormData1 = New Structure;
		FormData1.Insert("UUID", Form.UUID);
		FormData1.Insert(ObjectName, New Structure);
		FormData1[ObjectName].Insert(TableName, DataTable);
		
		ProductsAddressInStorage = ProductionServer.PlaceStringDataInTemporaryStorage(
									FormData1, ObjectName, TableName, False, FieldsStructure);
		
		If SourceTable_.Count() > 0 Then
			ProductsNonReplaceableQuantityAddressInStorage = PutToTempStorage(
															SourceTable_, Form.UUID);
		EndIf; 
		
		// Inventories
		CollapseFields = "Products,Characteristic,Purpose,WithAssignment,Warehouse";
		BalanceTable = InventoryAllocationTable.Copy(
			New Structure("DemandCharacteristic", Undefined), // free Balance
			CollapseFields + ",Count");
		BalanceTable.GroupBy(CollapseFields, "Count");
		DistributionOfStocksAddressInStorage = PutToTempStorage(BalanceTable, Form.UUID);
		
	EndIf;
	
	StructureOfData = New Structure;
	StructureOfData.Insert("Goods", ProductsAddressInStorage);
	StructureOfData.Insert("GoodsNonReplaceableQuantity", ProductsNonReplaceableQuantityAddressInStorage);
	StructureOfData.Insert("InventoryAllocation", DistributionOfStocksAddressInStorage);	
	
	Return StructureOfData;
	
EndFunction	

#EndRegion

#Region ReplacementWithAnalogues

// Performs the substitution of materials for selected analogues
//
// Parameters:
//  TabularSection	   	  - FormDataCollection - the table in which you want to perform the replacement
//  AddressInStorage	   	  - String				 - address of the storage where the selected analogs are located
//  AdditionalFields 	  - String, Undefined - the table fields you need to fill in the lines with the substituted analogues, 
//												   based on the lines of the replaced materials.
//  ActionCodeAnalogs           - String        - if transmitted, analogues are reserved in the warehouse taking into account the free Balance
//  											   . For the action "ACTION_ANALOGE_RESERVATE", the value of the Attribute of the "Support option" is set to "Warehouse" (default value),
//  											   for the action "ACTION_ANALOGE_OUTLOAD", the value of the Attribute of the "Support option" is set to "Ship".
// 
// Returns:
//  Structure - contains fields:
//  * IndexesOfNewRows		 - Array - contains the indices of the new row (similar to)
//  * IndexesOfModifiedRows - Array - contains indexes of modified rows (materials)
//
Function PerformReplacementForAnalogues(
			TabularSection, AddressInStorage, AdditionalFields = Undefined, ActionCodeAnalogs = "") Export
	
	ReplacementTable = GetFromTempStorage(AddressInStorage);//ValueTable - 
	ReplacementTable.Indexes.Add("ThisIsASubstitute");
	
	ReserveAtWarehouse = ActionCodeAnalogs = "Action_Substitutes_ToReserve_" Or ActionCodeAnalogs = "Action_Substitutes_Ship";
	If ReserveAtWarehouse Then
		
		ReplacementTable.Columns.Add("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
		ReplacementTable.Columns.Add("Processed", New TypeDescription("Boolean"));
		ReplacementTable.Indexes.Add("ThisIsASubstitute, Processed, SelectionNumber");
		ReplacementTable.Indexes.Add("ThisIsASubstitute, Processed, SelectionNumber, Products, Characteristic");
		
		FilterStructure1 = New Structure("ThisIsASubstitute, Processed, SelectionNumber", True, False);
		ProductSelectionStructure = New Structure(
			"ThisIsASubstitute, Processed, SelectionNumber, Products, Characteristic", True, False);
		
		ArrayOfMatchingNumbers = CommonClientServer.CollapseArray(ReplacementTable.UnloadColumn("SelectionNumber"));
		For Each SelectionNumber In ArrayOfMatchingNumbers Do
			
			FilterStructure1.SelectionNumber = SelectionNumber;
			
			While True Do
				
				ArrayOfUnprocessedStrings = ReplacementTable.FindRows(FilterStructure1);
				If ArrayOfUnprocessedStrings.Count() = 0 Then
					Break;
				Else
					
					FillPropertyValues(ProductSelectionStructure, ArrayOfUnprocessedStrings[0]);
					RowsArray = ReplacementTable.FindRows(ProductSelectionStructure);
					
					WarehouseStockBalance = RowsArray[0].WarehouseStockBalance;
					For Each TableRow In RowsArray Do
						
						If WarehouseStockBalance = 0 Then
							
							TableRow.Processed = True;
							
						ElsIf TableRow.Count > WarehouseStockBalance Then
							
							NewTableRow = ReplacementTable.Add();
							FillPropertyValues(NewTableRow, TableRow,, "Count");
							NewTableRow.Count = TableRow.Count - WarehouseStockBalance;
							NewTableRow.Processed = True;
							
							TableRow.Count = WarehouseStockBalance;
							TableRow.Processed = True;
							If ActionCodeAnalogs = "Action_Substitutes_ToReserve_" Then
								TableRow.SupplyOption = Enums.SupplyOptions.FromWarehouse;
							ElsIf ActionCodeAnalogs = "Action_Substitutes_Ship" Then
								TableRow.SupplyOption = Enums.SupplyOptions.Ship;
							EndIf;
							
							WarehouseStockBalance = 0;
							
						Else
							
							TableRow.Processed = True;
							If ActionCodeAnalogs = "Action_Substitutes_ToReserve_" Then
								TableRow.SupplyOption = Enums.SupplyOptions.FromWarehouse;
							ElsIf ActionCodeAnalogs = "Action_Substitutes_Ship" Then
								TableRow.SupplyOption = Enums.SupplyOptions.Ship;
							EndIf;
							
							WarehouseStockBalance = WarehouseStockBalance - TableRow.Count;	
							
						EndIf;
						
					EndDo;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;	
	
	If AdditionalFields <> Undefined Then
		
		ArrayOfAdditionalFields = StrSplit(AdditionalFields, ", ", False);
		For Each AdditionalField In ArrayOfAdditionalFields Do
			If ReplacementTable.Columns.Find(AdditionalField) = Undefined Then
				ReplacementTable.Columns.Add(AdditionalField);
			EndIf;
		EndDo;
		
		ReplacementTable.Indexes.Add("ThisIsASubstitute, ConnectionKey");
		
		FieldArray = StrSplit(AdditionalFields, ",");
		KeyArray = CommonClientServer.CollapseArray(ReplacementTable.UnloadColumn("ConnectionKey"));
		
		For Each Var_Key In KeyArray Do
			
			FieldsStructure = New Structure(AdditionalFields);
			For Each Field In FieldsStructure Do
				FieldsStructure.Insert(Field.Key, New Array);	
			EndDo;	
			
			ArrayOfLineNumbers = StrSplit(Var_Key, ";", False);
			For Each LineNumber In ArrayOfLineNumbers Do
				
				TSRow = TabularSection[LineNumber - 1];
				For Each Field In FieldsStructure Do
					KeyValue = Field.Value;//Array - 
					KeyValue.Add(TSRow[Field.Key]);	
				EndDo;	
				
			EndDo;
			
			For Each Field In FieldsStructure Do
				
				ArrayOfValues = CommonClientServer.CollapseArray(Field.Value);
				If ArrayOfValues.Count() = 1 Then
					
					RowsArray = ReplacementTable.FindRows(New Structure("ThisIsASubstitute, ConnectionKey", True, Var_Key));
					For Each TableRow In RowsArray Do
						TableRow[Field.Key] = ArrayOfValues[0];	
					EndDo;	
					
				EndIf;	
				
			EndDo;	
			
		EndDo;	
		
	EndIf;
	
	IndexesOfNewRows = New Array;
	IndexesOfModifiedRows = New Array;
	NumberOfDeletedRows = 0;
	
	ReplacementTable.Sort("OriginalLineNumber");
	
	RowsArray = ReplacementTable.FindRows(New Structure("ThisIsASubstitute", False));
	For Each TableRow In RowsArray Do
		
		RowIndex = TableRow.OriginalLineNumber - 1 - NumberOfDeletedRows;
		
		TSRow = TabularSection[RowIndex];
		If TSRow.Count = TableRow.Count Then
			
			TabularSection.Delete(TSRow);
			
			ArrayIndex = IndexesOfModifiedRows.Find(RowIndex);
			If ArrayIndex <> Undefined Then
				IndexesOfModifiedRows.Delete(ArrayIndex);	
			EndIf;
			
			NumberOfDeletedRows = NumberOfDeletedRows + 1;
				
		Else
			
			TSRow.Count = TSRow.Count - TableRow.Count;
			TSRow.NumberOfPackages = TSRow.Count;
			TSRow.Package = Undefined;
			
			ArrayIndex = IndexesOfModifiedRows.Find(RowIndex);
			If ArrayIndex = Undefined Then
				IndexesOfModifiedRows.Add(RowIndex);
			EndIf;	
			
		EndIf;	
		
	EndDo;
	
	GroupingColumns = "Products, Characteristic, Warehouse, WithAssignment, Purpose, ThisIsASubstitute%1";
	
	If ReserveAtWarehouse Then
		GroupingColumns = StrTemplate(GroupingColumns, ", SupplyOption%1");
	EndIf;
	
	If AdditionalFields <> Undefined Then
		ArrayOfDimensionFields = StrSplit(Left(GroupingColumns, StrLen(GroupingColumns) - 2), ", ", False);
		For Each AdditionalField In ArrayOfAdditionalFields Do
			If ArrayOfDimensionFields.Find(AdditionalField) = Undefined Then
				GroupingColumns = StrTemplate(GroupingColumns, ", " + AdditionalField + "%1");	
			EndIf;	
		EndDo;	
	EndIf;
	
	ReplacementTable.GroupBy(StrTemplate(GroupingColumns, ""), "Count");
	
	RowsArray = ReplacementTable.FindRows(New Structure("ThisIsASubstitute", True));
	For Each TableRow In RowsArray Do
		
		TSRow = TabularSection.Add();
		FillPropertyValues(TSRow, TableRow);
		TSRow.NumberOfPackages = TSRow.Count;
		
		IndexesOfNewRows.Add(TSRow.LineNumber - 1);
		
	EndDo;
	
	Return New Structure("IndexesOfNewRows, IndexesOfModifiedRows", IndexesOfNewRows, IndexesOfModifiedRows);
	
EndFunction	

// Replaces materials with analogs based on priority and free balance
//
// Parameters:
//  TabularSection          - FormDataCollection - the table in which you want to perform the replacement
//  AnalogSelectionParameters - See AlternativeMaterials.AnalogSelectionParameters
//  AdditionalFields      - String, Undefined - the table fields you need to fill in the lines with the substituted analogues, 
//                                                   based on the lines of the replaced materials.
//  ActionCodeAnalogs            - String         - if transmitted, analogues are reserved in the warehouse taking into account the free Balance
//  											     . For the action "ACTION_ANALOGE_RESERVATE", the value of the Attribute of the "Support option" is set to "Warehouse" (default value),
//  											     for the action "ACTION_ANALOGE_OUTLOAD", the value of the Attribute of the "Support option" is set to "Ship".
// 
// Returns:
//  Structure - contains fields:
//  * IndexesOfNewRows      - Array - contains the indices of the new row (similar to)
//  * IndexesOfModifiedRows - Array - contains indexes of modified rows (materials)
//
Function PerformReplacementWithAnaloguesAutomatically(
			TabularSection, AnalogSelectionParameters, AdditionalFields = Undefined, ActionCodeAnalogs = "") Export
	
	StringStructure_1 = New Structure("IndexesOfNewRows, IndexesOfModifiedRows", New Array, New Array);
	
	ReplacementTable = GetReplacementTable(AnalogSelectionParameters,, ActionCodeAnalogs);
	If ReplacementTable = Undefined Then
		Return StringStructure_1;
	EndIf;
	
	ReserveAtWarehouse = ActionCodeAnalogs = "Action_Substitutes_ToReserve_" Or ActionCodeAnalogs = "Action_Substitutes_Ship";
	
	GroupingColumns = "Ref, LineNumber, Products, Characteristic, Warehouse, ThisIsASubstitute, Purpose, WithAssignment"
						 + ?(ReserveAtWarehouse,", SupplyOption", "");
	
	ReplacementTable.GroupBy(GroupingColumns, "Count, ReplacedPriority");
	
	ValuesOfAdditionalFields = New Structure;
	
	If AdditionalFields <> Undefined Then
		
		FieldsStructure = New Structure(AdditionalFields);
		For Each Field In FieldsStructure Do
			FieldsStructure.Insert(Field.Key, New Array);	
		EndDo;
		
		ArrayOfLineNumbers = CommonClientServer.CollapseArray(ReplacementTable.UnloadColumn("LineNumber"));
		ArrayOfLineNumbers.Delete(ArrayOfLineNumbers.Find(0));
		
		For Each LineNumber In ArrayOfLineNumbers Do
			
			TSRow = TabularSection[LineNumber - 1];
			For Each Field In FieldsStructure Do
				KeyValue = Field.Value;//Array - 
				KeyValue.Add(TSRow[Field.Key]);
			EndDo;
			
		EndDo;
		
		For Each Field In FieldsStructure Do
			
			ArrayOfValues = CommonClientServer.CollapseArray(Field.Value);
			If ArrayOfValues.Count() = 1 Then
				ValuesOfAdditionalFields.Insert(Field.Key, ArrayOfValues[0]);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	GoodsNonReplaceableQuantity                = Undefined;
	ProductsNonReplaceableQuantityAddressInStorage = AnalogSelectionParameters.GoodsParameters.GoodsNonReplaceableQuantity;
	If IsTempStorageURL(ProductsNonReplaceableQuantityAddressInStorage) Then
		
		GoodsNonReplaceableQuantity =
			GetFromTempStorage(ProductsNonReplaceableQuantityAddressInStorage);// ValueTable
		
		If GoodsNonReplaceableQuantity.Count() > 0 Then
			GoodsNonReplaceableQuantity.Indexes.Add("LineNumber");
		Else
			GoodsNonReplaceableQuantity = Undefined;
		EndIf;
		
	EndIf;
	
	ReplacementTable.Sort("LineNumber Desc");
	
	RowsArray = ReplacementTable.FindRows(New Structure("ThisIsASubstitute", False));
	For Each TableRow In RowsArray Do
		
		RowIndex = TableRow.LineNumber - 1;
		TSRow = TabularSection[RowIndex];
		
		If GoodsNonReplaceableQuantity <> Undefined Then
			
			ArrayOfStringsNonReplaceableQuantity =
				GoodsNonReplaceableQuantity.FindRows(New Structure("LineNumber", TableRow.LineNumber));
			
			If ArrayOfStringsNonReplaceableQuantity.Count() > 0 Then
				TableRow.Count = TableRow.Count - TableRow.ReplacedPriority + ArrayOfStringsNonReplaceableQuantity[0].Count;
			EndIf;
			
		EndIf;
		
		If TableRow.Count = 0 Then
			
			TabularSection.Delete(TSRow);
			
			IndexesOfModifiedRows = StringStructure_1.IndexesOfModifiedRows;
			ElementIndex         = IndexesOfModifiedRows.UBound();
			While ElementIndex > -1 Do
				IndexesOfModifiedRows[ElementIndex] = IndexesOfModifiedRows[ElementIndex] - 1;
				ElementIndex = ElementIndex - 1;
			EndDo;
			
		Else
			
			TSRow.Count = TableRow.Count;
			TSRow.NumberOfPackages = TSRow.Count;
			TSRow.Package = Undefined;
			
			StringStructure_1.IndexesOfModifiedRows.Add(RowIndex);
			
		EndIf;
		
	EndDo;
	
	RowsArray = ReplacementTable.FindRows(New Structure("ThisIsASubstitute", True));
	For Each TableRow In RowsArray Do
		
		TSRow = TabularSection.Add();
		FillPropertyValues(TSRow, TableRow,, "LineNumber");
		FillPropertyValues(TSRow, ValuesOfAdditionalFields);
		TSRow.NumberOfPackages = TSRow.Count;
		
		StringStructure_1.IndexesOfNewRows.Add(TSRow.LineNumber - 1);
		
	EndDo;
	
	Return StringStructure_1;
	
EndFunction

// Gets a replacement table for forming stages.
//
// Parameters:
//  Goods  - ValueTable - table of materials with columns:
//             * Stage                      - DocumentRef.ProductionStage2_2, Number -
//             * Id             - Number -
//             * Products              - CatalogRef.Products -
//             * Characteristic            - CatalogRef.ItemsCharacteristics -
//             * Department             - CatalogRef.BusinessStructure -
//             * LineOfBusiness   - CatalogRef.LinesOfBusiness -
//             * ProductionOrder       - DocumentRef.ProductionOrder2_2 -
//             * BillOfMaterials              - CatalogRef.BillsOfMaterials -
//             * LinkKeyBOM     - UUID -
//             * StageOfResourceBillOfMaterials - CatalogRef.ProductionStages -
//             * Product                   - CatalogRef.Products -
//             * ItemVariantOfProduct     - CatalogRef.ItemsCharacteristics -
//             * SupplyAssignment     - CatalogRef.Assignments -
//             * WithAssignment               - Boolean -
//             * Count                - Number -
//  SelectionOfPermissions - Structure - collection for selecting replacement permissions:
//      * Filter - Map of KeyAndValue - Contains a description of the fields for which the selection should be applied:
//         ** Key - String - The name of the field for which the selection is applied.
//         ** Value - String - Name of the parameter in the request.
//      * PermissionSelectionParameters - Map of KeyAndValue - Contains a description of the parameters in the request:
//         ** Key - String - Name of the parameter in the request.
//         ** Value - AnyRef - The value of the parameter in the request.
//  Reserves - ValueTable, Undefined - table of reserves with columns:
//             * Products       - CatalogRef.Products -
//             * Characteristic     - CatalogRef.ItemsCharacteristics -
//             * Warehouse              - CatalogRef.Warehouses -
//             * Department      - CatalogRef.BusinessStructure -
//             * Purpose         - CatalogRef.Assignments -
//             * ItemsType    - EnumRef.ItemsTypes -
//             * SupplyOption - EnumRef.SupplyOptions -
//             * DateOfShipment       - Date -
//             * WorkShipmentDate  - Date -
//             * Count         - Number -
//  ConsiderManyToManyPermissions - Boolean - TRUTH: many-to-many permissions are taken into account
//                                            FALSE: many-to-many permissions are ignored.
//                                            The default is TRUE.
//  SourceType - TypeDescription - description of the type for linking tables of materials and parameters.
// 
// Returns:
//  ValueTable, Undefined - replacement table.
//
Function GetReplacementTableForGeneratingStages(
			Goods,
			SelectionOfPermissions,
			Reserves = Undefined,
			ConsiderManyToManyPermissions = True,
			SourceType = Undefined) Export
	
	If Goods.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	If SourceType = Undefined Then
		SourceType = New TypeDescription("DocumentRef.ProductionStage2_2");
	EndIf;
	
	AnalogSelectionParameters = AnalogSelectionParameters(SourceType);
	
	If SelectionOfPermissions <> Undefined Then
	
		AnalogSelectionParameters.GeneralParameters.SelectionOfPermissions = SelectionOfPermissions.Filter;
		AnalogSelectionParameters.GeneralParameters.PermissionSelectionParameters = SelectionOfPermissions.PermissionSelectionParameters;
	
	EndIf;
	
	FieldsStructure = StructureOfTableFieldsToReplaceWithAnalogues();
	FieldsStructure.MainField = "Ref, " + Chars.LF + FieldsStructure.MainField;
	FieldsStructure.SpoofFields.Insert("Purpose", "SupplyAssignment");
	
	DataTable = Goods.Copy();
	DataTable.Columns.Stage.Name          = "Ref";
	DataTable.Columns.Id.Name = "LineNumber";
	DataTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	
	ObjectName = "Object";
	TableName = "Goods";

	FormData1 = New Structure;
	FormData1.Insert("UUID", New UUID);
	FormData1.Insert(ObjectName, New Structure);
	FormData1[ObjectName].Insert(TableName, DataTable);
	
	ProductsAddressInStorage = ProductionServer.PlaceStringDataInTemporaryStorage(
								FormData1, ObjectName, TableName, False, FieldsStructure);
	
	ProductData_9 = New Structure;
	ProductData_9.Insert("Goods", ProductsAddressInStorage);
	
	If Reserves <> Undefined And Reserves.Count() > 0 Then
		
		ProductData_9.Insert(
			"Reserves", 
			PutToTempStorage(Reserves.Copy(New Structure("Purpose", Catalogs.Assignments.EmptyRef()))));
			
	EndIf;
	
	FillPropertyValues(AnalogSelectionParameters.GoodsParameters, ProductData_9);
	FillPropertyValues(AnalogSelectionParameters.SubstitutesParameters, ProductData_9);
	
	ProcessedStages      = New Map;
	PermissionValidityDate = BegOfDay(CurrentSessionDate());
	ParametersTable      = AnalogSelectionParameters.SubstitutesParameters.ParametersTable;
	For Each LineProducts_ In Goods Do
		
		CurrentStep = LineProducts_.Stage;
		
		If ProcessedStages.Get(CurrentStep) <> Undefined Then
			Continue;
		EndIf;
		
		ProcessedStages.Insert(CurrentStep, CurrentStep);
		
		TableRow = ParametersTable.Add();
		FillPropertyValues(TableRow, LineProducts_);
		
		TableRow.PermissionValidityDate = PermissionValidityDate;
		TableRow.Ref                 = CurrentStep;
		TableRow.Stage                   = LineProducts_.StageOfResourceBillOfMaterials;
		
	EndDo;	
	
	AnalogSelectionParameters.SubstitutesParameters.ParametersTable = PutToTempStorage(ParametersTable);
	
	ReplacementTable = GetReplacementTable(
					AnalogSelectionParameters,
					ConsiderManyToManyPermissions,
					"Action_Substitutes_ToReserve_");
	
	If ReplacementTable = Undefined Then
		Return Undefined;
	EndIf;
	
	ReplacementTable.Columns.LineNumber.Name = "Id";
	
	Return ReplacementTable;
		
EndFunction

// Retrieves the replacement table
//
// Parameters:
//	AnalogSelectionParameters 	   - See AlternativeMaterials.AnalogSelectionParameters 
//  ConsiderManyToManyPermissions - Boolean    - Truth: many-to-many permissions are taken into account
//												 False: many-to-many permissions are ignored.
//  ActionCodeAnalogs             - String    - if transmitted, analogues are reserved in the warehouse taking into account the free Balance
//  											 . For the action "ACTION_ANALOGE_RESERVATE", the value of the Attribute of the "Support option" is set to "Warehouse" (default value),
//  											 for the action "ACTION_ANALOGE_OUTLOAD", the value of the Attribute of the "Support option" is set to "Ship".
// 
// Returns:
//  - Undefined    - there is no possibility of replacement.
//  - ValueTable - replacement table with columns:
//    * LineNumber                   - Number - Line number.
//    * Ref                        - DocumentRef - source document.
//    * Products                  - CatalogRef.Products - Nomenclature.
//    * Characteristic                - CatalogRef.ItemsCharacteristics - item description.
//    * Count                    - Number - Quantity.
//    * Warehouse                         - CatalogRef.Warehouses - warehouse.
//    * WithAssignment                   - Boolean - indicates a separate position.
//    * Resolution                    - DocumentRef.EngineeringChangeOrder, DocumentRef.RegisterAdjustment - permission.
//    * ReplacedQuantityLineByLine - Map - Key: line number of the material,
//                                                     Value: replaced by the number.
//    * ThisIsASubstitute                     - Boolean - indicates an analog.
//    * SupplyOption            - EnumRef.SupplyOptions - when reserving in a warehouse.
//    * Purpose                    - CatalogRef.Assignments - purpose.
//    * ReplacedPriority           - Number - the number for which priority substitution was applied.
//
Function GetReplacementTable(
			AnalogSelectionParameters, ConsiderManyToManyPermissions = True, ActionCodeAnalogs = "") Export
			
	GoodsParameters = AnalogSelectionParameters.GoodsParameters;
	
	TableOfGoods = GetFromTempStorage(GoodsParameters.Goods);
	If TableOfGoods.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	GoodsTogetherWithParameters = AnalogSelectionParameters.GoodsParameters.GoodsTogetherWithParameters;
	
	InventoryTable = ?(IsTempStorageURL(GoodsParameters.InventoryAllocation), 
							GetFromTempStorage(GoodsParameters.InventoryAllocation), 
							Undefined);	
	
	SubstitutesParameters = AnalogSelectionParameters.SubstitutesParameters;
	
	TableOfReserves = ?(IsTempStorageURL(SubstitutesParameters.Reserves),
							GetFromTempStorage(SubstitutesParameters.Reserves), 
							Undefined);
	
	GetWarehouseFromChina = SubstitutesParameters.Warehouse = Undefined;
	ReserveAtWarehouse = ActionCodeAnalogs = "Action_Substitutes_ToReserve_" Or ActionCodeAnalogs = "Action_Substitutes_Ship";
	
	SelectionParameters_2Balance = New Structure;
	SelectionParameters_2Balance.Insert("ApplyInventoryTable", InventoryTable <> Undefined);
	SelectionParameters_2Balance.Insert("ApplyReserveTable", TableOfReserves <> Undefined);
	
	ResolutionSelectionParameters = New Structure("ConsiderManyToMany", ConsiderManyToManyPermissions);
	PriorityPermissionSelectionParameters = New Structure("ConsiderManyToMany", ConsiderManyToManyPermissions);
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(QueryTextGoods());
	ArrayOfTexts.Add(QueryTextTableOfMaterials(True, AnalogSelectionParameters.GeneralParameters.SelectionOfPermissions));
	ArrayOfTexts.Add(QueryTextAvailableManyToManyPermissions(ResolutionSelectionParameters));
	ArrayOfTexts.Add(QueryTextTableOfAnalogues(GetWarehouseFromChina));
	ArrayOfTexts.Add(QueryTextTableLeftovers(SelectionParameters_2Balance));
	ArrayOfTexts.Add(ProductDataManagement.QueryTextPackageData_(StrSplit("TableOfMaterials,TableOfAnalogues",",")));
	ArrayOfTexts.Add(TextOfPermissionRequestByPriority(PriorityPermissionSelectionParameters));
	
	Query = New Query;
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Goods", TableOfGoods);
	
	If InventoryTable <> Undefined Then
		
		Query.SetParameter("Inventories", InventoryTable); // Free Balance.
		
	EndIf;
		
	If TableOfReserves <> Undefined Then
		Query.SetParameter("Reserves", TableOfReserves);
	EndIf;
	
	If Not GoodsTogetherWithParameters Then
		
		SubstitutesParameters = AnalogSelectionParameters.SubstitutesParameters;
		ParametersTable = GetFromTempStorage(SubstitutesParameters.ParametersTable);
		Query.SetParameter("ParametersTable", ParametersTable);
	
	EndIf;
	
	Query.SetParameter(
		?(GetWarehouseFromChina, "DefaultWarehouse", "Warehouse"), 
		?(GetWarehouseFromChina, Catalogs.Warehouses.DefaultWarehouse(), SubstitutesParameters.Warehouse));
		
	For Each MapItem In AnalogSelectionParameters.GeneralParameters.PermissionSelectionParameters Do
		Query.SetParameter(MapItem.Key, MapItem.Value);
	EndDo;
		
	ResultsArray = Query.ExecuteBatch();  
	
	PermissionMaterialsTable = ResultsArray[ResultsArray.UBound() - 3].Unload();
	If PermissionMaterialsTable.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	PermissionMaterialsTable.Indexes.Add("Resolution, Ref");
	PermissionMaterialsTable.Indexes.Add("Resolution, ControlMultiplier");
	
	TableOfAnalogPermissions = ResultsArray[ResultsArray.UBound() - 2].Unload();
	TableOfAnalogPermissions.Indexes.Add("Resolution, Ref");
	TableOfAnalogPermissions.Indexes.Add("Products, Characteristic, Warehouse");
	
	TableOfPermissionsByPriority = ResultsArray[ResultsArray.UBound() - 1].Unload(); // See ProductionServer.ServiceStructureOfValueTable
	TableOfPermissionsByPriority.Indexes.Add("Resolution, Ref");
	TableOfPermissionsByPriority.Indexes.Add("LineNumber");
	
	AssignmentsTable = ResultsArray[ResultsArray.UBound()].Unload();
	AssignmentsTable.Indexes.Add("Resolution, Ref");
	
	Packing_DataTable = ResultsArray[ResultsArray.UBound() - 5].Unload();
	ProductDataManagement.FillInPackingDataInDataset(PermissionMaterialsTable, Packing_DataTable);
	ProductDataManagement.FillInPackingDataInDataset(TableOfAnalogPermissions, Packing_DataTable);
	
	RemnantsOfAnalogues = ResultsArray[ResultsArray.UBound() - 4].Unload();
	RemnantsOfAnalogues.Indexes.Add("Products, Characteristic, Warehouse, Purpose");
	SearchForBalances = New Structure("Products, Characteristic, Warehouse, Purpose");
	
	TableOfProductsByPermission = TableOfGoods.CopyColumns("Products, Characteristic, Count"); // ValueTable - 
	TableOfProductsByPermission.Columns.Add("LineNumbers", New TypeDescription("Array"));
	TableOfProductsByPermission.Indexes.Add("Products, Characteristic");
	
	ReplacementTable = TableOfGoods.CopyColumns("LineNumber, Ref, Products, Characteristic, Count, Warehouse"); // ValueTable - 
	ReplacementTable.Columns.Add("Resolution", New TypeDescription("DocumentRef.EngineeringChangeOrder"));
	ReplacementTable.Columns.Add("ReplacedQuantityLineByLine", New TypeDescription("Map"));
	ReplacementTable.Columns.Add("ThisIsASubstitute", New TypeDescription("Boolean"));
	ReplacementTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	ReplacementTable.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
	ReplacementTable.Columns.Add("ReplacedPriority", Common.TypeDescriptionNumber(15, 3));
	
	If ReserveAtWarehouse Then
		ReplacementTable.Columns.Add("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	EndIf;
	
	ReplacementTable.Indexes.Add("LineNumber");
	
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	InterchangeableMaterialsFilter = New Structure("Resolution, Ref, Products, Characteristic");
	SelectionByPermission = New Structure("Resolution, Ref");
	SelectionByPermissionAndAppointment = New Structure("Resolution, Ref, Purpose, InterchangeableSubstitute");
	FilterAnalogsByResolution = New Structure("Resolution, Ref");
	SelectionByMultiplicity = New Structure("Resolution, ControlMultiplier", Undefined, True);
	FilterRemainingGoodsByShelfLives = New Structure("Products, Characteristic");

	SelectionByPermissionAndAppointment.InterchangeableSubstitute = False;
		
	While TableOfPermissionsByPriority.Count() > 0 Do
		
		PriorityPermissionString = TableOfPermissionsByPriority[0];
		FillPropertyValues(SelectionByMultiplicity, PriorityPermissionString, "Resolution");
		ControlMultiplier = PermissionMaterialsTable.FindRows(SelectionByMultiplicity).Count() > 0;
		ListBasedReplacement = PriorityPermissionString.ProductsRole = Enums.SubstituteRoles.InterchangeableSubstitute;
		PriorityReplacement = PriorityPermissionString.ReplacementPriority = Enums.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute;
		
		FillPropertyValues(SelectionByPermission, PriorityPermissionString);
		FillPropertyValues(FilterAnalogsByResolution, PriorityPermissionString);
		
		CrawlTable = CrawlingTableOfMaterials(TableOfPermissionsByPriority, AssignmentsTable, SelectionByPermission, ListBasedReplacement);
		
		For Each CrawlString In CrawlTable Do
		
			StandardOfAnalogue = 1;
			CoefficientOfInterchangeableMaterial = 1;
			TotalQuantityToBeDistributed = 0;
			PurposeOfSet = CrawlString.Purpose;
			ExcludeIsolatedBalance = False;
			UseOnlySeparateOneBalance = False;
			FillPropertyValues(SelectionByPermission, FilterAnalogsByResolution);
			
			TableOfProductsByPermission.Clear();
			
			MatchingAssignments = New Map;
			ComplianceIsSeparate = New Map;
			ThereIsSeparatePositionWithAppointment = False;
			ArrayOfResolutionStrings = TableOfPermissionsByPriority.FindRows(CrawlString.FilterParameters);
			For Each TableRow In ArrayOfResolutionStrings Do
				
				FillPropertyValues(FilterRemainingGoodsByShelfLives, TableRow);
				
				ArrayOfRows = TableOfProductsByPermission.FindRows(FilterRemainingGoodsByShelfLives);
				If ArrayOfRows.Count() > 0 Then
					LineProducts_ = ArrayOfRows[0];
				Else
					LineProducts_ = TableOfProductsByPermission.Add();
					FillPropertyValues(LineProducts_, FilterRemainingGoodsByShelfLives);
					LineProducts_.Count = 0;
				EndIf;
				
				QuantityToBeAccountedFor = ?(PriorityReplacement, TableRow.TotalCount1, TableRow.Count);
				
				LineProducts_.Count = LineProducts_.Count + QuantityToBeAccountedFor;

				ArrayOfLineNumbers = LineProducts_.LineNumbers; // Array - 
				ArrayOfLineNumbers.Add(TableRow.LineNumber);
				
				MatchingAssignments.Insert(TableRow.Purpose, True);
				ComplianceIsSeparate.Insert(TableRow.WithAssignment, True);
				
				If TableRow.WithAssignment
				   And ValueIsFilled(TableRow.Purpose) Then
				
					ThereIsSeparatePositionWithAppointment = True;
				
				EndIf;
				
				FillPropertyValues(InterchangeableMaterialsFilter, TableRow);
				
			EndDo;
			
			If TableOfProductsByPermission.Count() = 0 Then
				Continue;
			EndIf;
				
			ArrayOfCoefficients = New Array;
			
			NumberOfAppointmentsInSet = MatchingAssignments.Count();
			NumberOfElementsIsSeparateInSet = ComplianceIsSeparate.Count();
			
			If NumberOfAppointmentsInSet = 1 Then
				
				If ComplianceIsSeparate.Get(True) <> Undefined Then
				
					UseOnlySeparateOneBalance = True;
					
				EndIf;
				
			Else
				
				If NumberOfElementsIsSeparateInSet = 1 Then
					
					ValueOfAssignment = ComplianceIsSeparate.Get(True);
					
					If ValueOfAssignment = True Then
						ArrayOfCoefficients.Add(0);
					Else
						ExcludeIsolatedBalance = True;
					EndIf;
					
				Else
					
					If ThereIsSeparatePositionWithAppointment Then
						ArrayOfCoefficients.Add(0);
					Else
						ExcludeIsolatedBalance = True;
					EndIf;
				
				EndIf;
				
			EndIf;
			
			MaterialsFilter = ?(ListBasedReplacement, InterchangeableMaterialsFilter, SelectionByPermission);
			
			ArrayOfStringsMaterials = PermissionMaterialsTable.FindRows(MaterialsFilter);
			For Each TableRow In ArrayOfStringsMaterials Do
				
				FillPropertyValues(FilterRemainingGoodsByShelfLives, TableRow);
				
				ArrayOfProductRowsByResolution = TableOfProductsByPermission.FindRows(FilterRemainingGoodsByShelfLives);
				
				CalculationCoefficient = ?(ArrayOfProductRowsByResolution.Count() = 0,
											0, ProductionClientServer.CoefficientByStandard(
																			ControlMultiplier, 
																			ArrayOfProductRowsByResolution[0].Count,
																			TableRow.NormativeStandard,
																			TableRow.PackageData));
				
				CoefficientSelected = ArrayOfCoefficients.Count() > 0;
				CoefficientOfInterchangeableMaterial = CalculationCoefficient;
				
				If Not CoefficientSelected 
				 Or CoefficientSelected And ArrayOfCoefficients[0] > CalculationCoefficient Then
					ArrayOfCoefficients.Insert(0, CalculationCoefficient);
				EndIf;
				
			EndDo;
			
			QuantityToReplace = TableOfProductsByPermission.Total("Count");
			TotalAmounBalance = 0;
			ArrayOfStringsAnalogs = TableOfAnalogPermissions.FindRows(FilterAnalogsByResolution);
			For Each TableRow In ArrayOfStringsAnalogs Do
				
				If TableRow.ThisIsWork Then
					
					StandardOfAnalogue = TableRow.NormativeStandard;
					TotalAmounBalance = QuantityToReplace;
					Continue;
					
				EndIf;
				
				If Not ExcludeIsolatedBalance Then
					
					FillPropertyValues(SearchForBalances, TableRow, "Products, Characteristic, Warehouse");
					SearchForBalances.Purpose = PurposeOfSet;
					RowsOfBalancesOfAnalogues = RemnantsOfAnalogues.FindRows(SearchForBalances);
					For Each AnalogBalanceLine In RowsOfBalancesOfAnalogues Do
					
						TableRow.DetachedBalance = AnalogBalanceLine.Balance;
						TableRow.WarehouseStockBalance = AnalogBalanceLine.Balance;
						TableRow.LineIsSeparateBalance = AnalogBalanceLine;
					
					EndDo;
				
				EndIf;
				
				If Not UseOnlySeparateOneBalance Then
					
					FillPropertyValues(SearchForBalances, TableRow, "Products, Characteristic, Warehouse");
					SearchForBalances.Purpose = EmptyAssignment;
					RowsOfBalancesOfAnalogues = RemnantsOfAnalogues.FindRows(SearchForBalances);
					For Each AnalogBalanceLine In RowsOfBalancesOfAnalogues Do
					
						TableRow.WarehouseStockBalance = TableRow.WarehouseStockBalance + AnalogBalanceLine.Balance;
						TableRow.LineFreeBalance = AnalogBalanceLine;
					
					EndDo;
				
				EndIf;
				
				LineBalance = ?(UseOnlySeparateOneBalance, 
					TableRow.DetachedBalance, 
					TableRow.WarehouseStockBalance);
					
				CalculationCoefficient	= ProductionClientServer.CoefficientByStandard(
																	ControlMultiplier, 
																	LineBalance, 
																	TableRow.NormativeStandard,
																	TableRow.PackageData);
					
				TotalAmounBalance = TotalAmounBalance + CalculationCoefficient;
				StandardOfAnalogue = TableRow.NormativeStandard;
				
				If ArrayOfCoefficients[0] > CalculationCoefficient Then
					ArrayOfCoefficients.Insert(0, CalculationCoefficient);
				EndIf;
				
			EndDo;
			
			If TotalAmounBalance = 0 Then
				CalculationCoefficient = 0;
			ElsIf ListBasedReplacement Then
			
				ThereAreEnoughAnalogues = TotalAmounBalance >= QuantityToReplace;
				
				If ThereAreEnoughAnalogues Then
					CalculationCoefficient = CoefficientOfInterchangeableMaterial;
				Else
					CalculationCoefficient = Min(TotalAmounBalance, CoefficientOfInterchangeableMaterial);
				EndIf;
				
				TotalQuantityToBeDistributed = CalculationCoefficient * StandardOfAnalogue;
					
			Else
				CalculationCoefficient = ArrayOfCoefficients[0];
			EndIf;
			
			If CalculationCoefficient > 0 Then
				
				ReplacedQuantityLineByLine = New Map;// Key: material line number; Value: replaced quantity
				
				For Each TableRow In ArrayOfStringsMaterials Do
					
					QuantityToDistribution = CalculationCoefficient * TableRow.NormativeStandard
						* TableRow.PackageData.Numerator / TableRow.PackageData.Denominator;
						
					FillPropertyValues(FilterRemainingGoodsByShelfLives, TableRow);
					ArrayOfLineNumbers = TableOfProductsByPermission.FindRows(FilterRemainingGoodsByShelfLives)[0].LineNumbers;
					For Each LineNumber In ArrayOfLineNumbers Do
						
						FilterByANumber = New Structure("LineNumber", LineNumber);
						
						ArrayOfStringsByNumber = TableOfPermissionsByPriority.FindRows(FilterByANumber);
						
						If ArrayOfStringsByNumber.Count() > 0 Then
							
							StringByNumber = ArrayOfStringsByNumber[0];
							QuantityToBeAccountedFor = ?(PriorityReplacement, StringByNumber.TotalCount1, StringByNumber.Count);
							MaterialQuantity = Min(QuantityToBeAccountedFor, QuantityToDistribution);
							ReplacedPriority = 0;
						
							If MaterialQuantity > 0 Then
								ReplacedQuantityLineByLine.Insert(LineNumber, MaterialQuantity);
							EndIf;
							
							For Each RowByPriority In ArrayOfStringsByNumber Do
								DifferenceTo = RowByPriority.TotalCount1 - RowByPriority.Count;
								RowByPriority.Count = RowByPriority.Count - MaterialQuantity;
								RowByPriority.TotalCount1 = RowByPriority.TotalCount1 - MaterialQuantity;
								DifferenceAfter = RowByPriority.TotalCount1 - RowByPriority.Count;
								ReplacedPriority = ?(DifferenceAfter = DifferenceTo, 0, DifferenceTo - DifferenceAfter);
							EndDo;
							
							ArrayOfReplacementTableRows = ReplacementTable.FindRows(FilterByANumber);
							RowOfReplacementTable = 
								?(ArrayOfReplacementTableRows.Count() > 0, ArrayOfReplacementTableRows[0], ReplacementTable.Add()); 
							FillPropertyValues(RowOfReplacementTable, RowByPriority,, "Resolution");
							RowOfReplacementTable.ReplacedPriority = ReplacedPriority;
								
							If RowByPriority.TotalCount1 = 0 Then
								RowIndex = ArrayOfStringsByNumber.UBound();
								While RowIndex > -1 Do
									TableOfPermissionsByPriority.Delete(ArrayOfStringsByNumber[RowIndex]);
									RowIndex = RowIndex - 1;
								EndDo;
							EndIf;
							
							QuantityToDistribution = QuantityToDistribution - MaterialQuantity;
							If QuantityToDistribution = 0 Then
								Break;
							EndIf;	
						
						EndIf;
						
					EndDo;
					
				EndDo;
				
				If ListBasedReplacement Then
				
					For Each TableRow In ArrayOfStringsAnalogs Do
					
						If TotalQuantityToBeDistributed = 0 Then
							Break;
						EndIf;
						
						SubstituteQuantity = CalculationCoefficient * TableRow.NormativeStandard
							* TableRow.PackageData.Numerator / TableRow.PackageData.Denominator;
							
						If TableRow.ThisIsWork And UseOnlySeparateOneBalance Then
							NumberOfSeparateAnalogue = SubstituteQuantity;
						Else	
							
							WarehouseStockBalance = TableRow.DetachedBalance;
							NumberOfSeparateAnalogue = Min(SubstituteQuantity, WarehouseStockBalance, TotalQuantityToBeDistributed);
							
						EndIf;	
							
						If NumberOfSeparateAnalogue > 0 Then
							
							TableRow.LineIsSeparateBalance.Balance = TableRow.LineIsSeparateBalance.Balance - NumberOfSeparateAnalogue;
							TableRow.WarehouseStockBalance = TableRow.WarehouseStockBalance - NumberOfSeparateAnalogue;
							TotalQuantityToBeDistributed = TotalQuantityToBeDistributed - NumberOfSeparateAnalogue;
							
							RowOfReplacementTable = ReplacementTable.Add(); 
							FillPropertyValues(RowOfReplacementTable, TableRow);
							RowOfReplacementTable.Count = NumberOfSeparateAnalogue;
							RowOfReplacementTable.WithAssignment = True;
							RowOfReplacementTable.Purpose = PurposeOfSet;
							RowOfReplacementTable.ReplacedQuantityLineByLine = ReplacedQuantityLineByLine;
							RowOfReplacementTable.ThisIsASubstitute = True;
							
							If TableRow.ThisIsWork And ReserveAtWarehouse Then
								RowOfReplacementTable.SupplyOption = Enums.SupplyOptions.ToSupply;
							ElsIf ActionCodeAnalogs = "Action_Substitutes_ToReserve_" Then
								RowOfReplacementTable.SupplyOption = Enums.SupplyOptions.FromWarehouse;
							ElsIf ActionCodeAnalogs = "Action_Substitutes_Ship" Then
								RowOfReplacementTable.SupplyOption = Enums.SupplyOptions.Ship;
							EndIf;
							
						EndIf;
					
					EndDo;
				
				EndIf;
				
				For Each TableRow In ArrayOfStringsAnalogs Do
					
					If TotalQuantityToBeDistributed = 0 And ListBasedReplacement Then
						Break;
					EndIf;
					
					SubstituteQuantity = CalculationCoefficient * TableRow.NormativeStandard
						* TableRow.PackageData.Numerator / TableRow.PackageData.Denominator;
						
					If ListBasedReplacement Then
						
						WarehouseStockBalance = TableRow.WarehouseStockBalance;
						If TableRow.ThisIsWork Then
							
							SubstituteQuantity = TotalQuantityToBeDistributed;
							NumberOfSeparateAnalogue = ?(UseOnlySeparateOneBalance, SubstituteQuantity, 0);
							NumberOfNonIsolatedAnalog = ?(Not UseOnlySeparateOneBalance, SubstituteQuantity, 0);
							
						Else	
							
							SubstituteQuantity = Min(SubstituteQuantity, WarehouseStockBalance, TotalQuantityToBeDistributed);
							NumberOfSeparateAnalogue = 0;
							NumberOfNonIsolatedAnalog = SubstituteQuantity;
							
						EndIf;
						
					Else
						
						If TableRow.ThisIsWork And UseOnlySeparateOneBalance Then
							NumberOfSeparateAnalogue = SubstituteQuantity;
						Else
							NumberOfSeparateAnalogue = Min(TableRow.DetachedBalance, SubstituteQuantity);
						EndIf;
						
						NumberOfNonIsolatedAnalog = SubstituteQuantity - NumberOfSeparateAnalogue;
						
					EndIf;
					
					If SubstituteQuantity = 0 Then
						Continue;
					EndIf;
					
					If Not TableRow.ThisIsWork Then
						
						If NumberOfSeparateAnalogue > 0 Then
							TableRow.LineIsSeparateBalance.Balance = TableRow.LineIsSeparateBalance.Balance - NumberOfSeparateAnalogue;
						EndIf;
						
						If NumberOfNonIsolatedAnalog > 0 Then
							TableRow.LineFreeBalance.Balance = TableRow.LineFreeBalance.Balance - NumberOfNonIsolatedAnalog;
						EndIf;
						
						TableRow.DetachedBalance = 0;
						TableRow.WarehouseStockBalance = 0;
						
					EndIf;
					
					TotalQuantityToBeDistributed = TotalQuantityToBeDistributed - SubstituteQuantity;
					
					If NumberOfSeparateAnalogue > 0 Then
					
						RowOfReplacementTable = ReplacementTable.Add(); 
						FillPropertyValues(RowOfReplacementTable, TableRow);
						RowOfReplacementTable.Count = NumberOfSeparateAnalogue;
						RowOfReplacementTable.WithAssignment = True;
						RowOfReplacementTable.Purpose = PurposeOfSet;
						RowOfReplacementTable.ReplacedQuantityLineByLine = ReplacedQuantityLineByLine;
						RowOfReplacementTable.ThisIsASubstitute = True;
						
						If TableRow.ThisIsWork And ReserveAtWarehouse Then
							RowOfReplacementTable.SupplyOption = Enums.SupplyOptions.ToSupply;
						ElsIf ActionCodeAnalogs = "Action_Substitutes_ToReserve_" Then
							RowOfReplacementTable.SupplyOption = Enums.SupplyOptions.FromWarehouse;
						ElsIf ActionCodeAnalogs = "Action_Substitutes_Ship" Then
							RowOfReplacementTable.SupplyOption = Enums.SupplyOptions.Ship;
						EndIf;
					
					EndIf;
					
					If NumberOfNonIsolatedAnalog > 0 Then
					
						RowOfReplacementTable = ReplacementTable.Add(); 
						FillPropertyValues(RowOfReplacementTable, TableRow);
						RowOfReplacementTable.Count = NumberOfNonIsolatedAnalog;
						RowOfReplacementTable.WithAssignment = False;
						RowOfReplacementTable.Purpose = EmptyAssignment;
						RowOfReplacementTable.ReplacedQuantityLineByLine = ReplacedQuantityLineByLine;
						RowOfReplacementTable.ThisIsASubstitute = True;
						
						If TableRow.ThisIsWork And ReserveAtWarehouse Then
							RowOfReplacementTable.SupplyOption = Enums.SupplyOptions.NotRequired;
						ElsIf ActionCodeAnalogs = "Action_Substitutes_ToReserve_" Then
							RowOfReplacementTable.SupplyOption = Enums.SupplyOptions.FromWarehouse;
						ElsIf ActionCodeAnalogs = "Action_Substitutes_Ship" Then
							RowOfReplacementTable.SupplyOption = Enums.SupplyOptions.Ship;
						EndIf;
					
					EndIf;
					
				EndDo;
				
			EndIf;
		
		EndDo;
		
		ArrayOfRowsToDelete_1 = TableOfPermissionsByPriority.FindRows(SelectionByPermission);
		RowIndex = ArrayOfRowsToDelete_1.UBound();
		While RowIndex > -1 Do
			TableOfPermissionsByPriority.Delete(ArrayOfRowsToDelete_1[RowIndex]);
			RowIndex = RowIndex - 1;
		EndDo;
		
	EndDo;
	
	Return ?(ReplacementTable.Count() = 0, Undefined, ReplacementTable);
	
EndFunction	

#EndRegion

#Region AvailabilityOfAnalogues

// Fills in the flag for the presence of analogs
//
// Parameters:
//  Table                 - FormDataCollection, ValueTable - the list in which you need to fill in the attribute "There is a similar material" contains:
//                             * LineNumber          - Number -
//                             * ThereAreSubstituteMaterials - Boolean -
//	AnalogSelectionParameters - See AlternativeMaterials.AnalogSelectionParameters
//
Procedure NotePresenceOfAnalogues(Table, AnalogSelectionParameters, Form = Undefined) Export
	
	TableOfGoods = GetFromTempStorage(AnalogSelectionParameters.GoodsParameters.Goods);
	If TableOfGoods.Count() = 0 Then
		Return;
	EndIf;
	
	FillInIndicatorInForm = TypeOf(Form) = Type("ClientApplicationForm") 
		And CommonClientServer.HasAttributeOrObjectProperty(Form, "ThereAreAnalogues");
	TableRowPropertiesChecked = False;
	CheckAdditionalFields = False;
	ShipOption = Enums.SupplyOptions.Ship;
		
	If FillInIndicatorInForm Then
		Form.ThereAreAnalogues = False;
	EndIf;
	
	ResolutionSelectionParameters = New Structure("ConsiderManyToMany", True);
	GoodsTogetherWithParameters = AnalogSelectionParameters.GoodsParameters.GoodsTogetherWithParameters;
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(QueryTextGoods());
	ArrayOfTexts.Add(QueryTextTableOfMaterials());
	ArrayOfTexts.Add(QueryTextAvailableManyToManyPermissions(ResolutionSelectionParameters));
	ArrayOfTexts.Add(QueryTextAvailabilityOfAnalogues());
	
	Query = New Query;
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	Query.SetParameter("Goods", TableOfGoods);
	
	If Not GoodsTogetherWithParameters Then
		
		SubstitutesParameters = AnalogSelectionParameters.SubstitutesParameters;
		ParametersTable = GetFromTempStorage(SubstitutesParameters.ParametersTable);
		Query.SetParameter("ParametersTable", ParametersTable);
	
	EndIf;
	
	TableAvailabilityOfAnalogues = Query.Execute().Unload();
	TableAvailabilityOfAnalogues.Indexes.Add("LineNumber");
	ThereAreAnalogues = False;
	
	For Each TableRow In Table Do
		
		TableRow.ThereAreSubstituteMaterials = 
			TableAvailabilityOfAnalogues.FindRows(New Structure("LineNumber", TableRow.LineNumber)).Count() > 0;
			
		If ThereAreAnalogues Or Not FillInIndicatorInForm Then
			Continue;
		EndIf;	
			
		If Not TableRowPropertiesChecked Then
			
			CheckAdditionalFields =
				CommonClientServer.HasAttributeOrObjectProperty(TableRow, "SupplyOption")
				And CommonClientServer.HasAttributeOrObjectProperty(TableRow, "Canceled");
				
			TableRowPropertiesChecked = True;
			
		EndIf;	
			
		If FillInIndicatorInForm And TableRow.ThereAreSubstituteMaterials Then
			
			If CheckAdditionalFields Then
			
				If TableRow.SupplyOption <> ShipOption And Not TableRow.Canceled Then
					ThereAreAnalogues = True;
				EndIf;
				
			Else
				
				ThereAreAnalogues = True;
			
			EndIf;	
			
		EndIf;
			
	EndDo;
	
	If FillInIndicatorInForm Then
		Form.ThereAreAnalogues = ThereAreAnalogues;
	EndIf;
	
EndProcedure

#EndRegion

#Region QueriesTexts

// Returns the query text for the temporary table " Products"
//
// Parameters:
//  GoodsTogetherWithParameters - Boolean - True: the parameters are specified in the product lines
//                                      False: The parameters are specified in a separate table of values
//
// Returns:
//  String - query text.
//
Function QueryTextGoods(GoodsTogetherWithParameters = False) Export
	
	If GoodsTogetherWithParameters Then
	
		QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Count AS Count,
		|	Goods.TotalCount1 AS TotalCount1,
		|	Goods.Ref AS Ref,
		|	Goods.Purpose AS Purpose,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.PermissionValidityDate AS PermissionValidityDate,
		|	Goods.ProductionOrder AS ProductionOrder,
		|	Goods.SalesOrder AS SalesOrder,
		|	Goods.BillOfMaterials AS BillOfMaterials,
		|	Goods.Stage AS Stage,
		|	Goods.Product AS Product,
		|	Goods.ItemVariantOfProduct AS ItemVariantOfProduct,
		|	Goods.Department AS Department,
		|	Goods.LineOfBusiness AS LineOfBusiness
		|INTO GoodsWithParameters
		|FROM
		|	&Goods AS Goods
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Count AS Count,
		|	Goods.TotalCount1 AS TotalCount1,
		|	Goods.Ref AS Ref,
		|	Goods.Purpose AS Purpose,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.Warehouse AS Warehouse
		|INTO Goods
		|FROM
		|	GoodsWithParameters AS Goods
		|
		|INDEX BY
		|	Products,
		|	Characteristic";
		
	Else
		
		QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Count AS Count,
		|	Goods.TotalCount1 AS TotalCount1,
		|	Goods.Ref AS Ref,
		|	Goods.Purpose AS Purpose,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.Warehouse AS Warehouse
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|	
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ParametersTable.Ref AS Ref,
		|	ParametersTable.PermissionValidityDate AS PermissionValidityDate,
		|	ParametersTable.ProductionOrder AS ProductionOrder,
		|	ParametersTable.SalesOrder AS SalesOrder,
		|	ParametersTable.BillOfMaterials AS BillOfMaterials,
		|	ParametersTable.Stage AS Stage,
		|	ParametersTable.Product AS Product,
		|	ParametersTable.ItemVariantOfProduct AS ItemVariantOfProduct,
		|	ParametersTable.Department AS Department,
		|	ParametersTable.LineOfBusiness AS LineOfBusiness
		|INTO ParametersTable
		|FROM
		|	&ParametersTable AS ParametersTable
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Count AS Count,
		|	Goods.TotalCount1 AS TotalCount1,
		|	Goods.Ref AS Ref,
		|	Goods.Purpose AS Purpose,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.Warehouse AS Warehouse,
		|	ParametersTable.PermissionValidityDate AS PermissionValidityDate,
		|	ParametersTable.ProductionOrder AS ProductionOrder,
		|	ParametersTable.SalesOrder AS SalesOrder,
		|	ParametersTable.BillOfMaterials AS BillOfMaterials,
		|	ParametersTable.Stage AS Stage,
		|	ParametersTable.Product AS Product,
		|	ParametersTable.ItemVariantOfProduct AS ItemVariantOfProduct,
		|	ParametersTable.Department AS Department,
		|	ParametersTable.LineOfBusiness AS LineOfBusiness
		|INTO GoodsWithParameters
		|FROM
		|	Goods AS Goods
		|	INNER JOIN ParametersTable AS ParametersTable
		|		ON Goods.Ref = ParametersTable.Ref
		|
		|INDEX BY
		|	Products,
		|	Characteristic"
	
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the query text with temporary tables that define the content table from the available permissions 
//
// Parameters:
//  CalculateApplicationPriority - Boolean - The truth: the calculated priority of the application
//                                           False: application priority is not calculated.
//  Filter - Map of KeyAndValue - collection where:  
//  	* Key - String - parameter name.
//  	* Value - AnyRef - parameter value.
//
// Returns:
//  String - query text.
//
Function QueryTextTableOfMaterials(CalculateApplicationPriority = False, Filter = Undefined) Export
	
	QueryText =
	"SELECT
	|	Goods.Ref AS Ref,
	|	Goods.LineNumber AS LineNumber,
	|	AlternativeMaterials.Recorder AS Resolution,
	|	AlternativeMaterials.Products AS Products,
	|	AlternativeMaterials.Characteristic AS Characteristic,
	|	AlternativeMaterials.Package AS Package,
	|	AlternativeMaterials.NumberOfPackages AS NumberOfPackages,
	|	Goods.Department AS Department,
	|	Goods.Purpose AS Purpose,
	|	Goods.WithAssignment AS WithAssignment,
	|	&TextReplacementPriority AS ReplacementPriority,
	|	AlternativeMaterials.ProductsRole AS ProductsRole,
	|	Goods.Count AS MaterialQuantity,
	|	Goods.TotalCount1 AS TotalAmountOfMaterial
	|INTO GoodsAndPermits
	|FROM
	|	InformationRegister.AlternativeMaterials AS AlternativeMaterials
	|		INNER JOIN GoodsWithParameters AS Goods
	|		ON AlternativeMaterials.Products = Goods.Products
	|			AND AlternativeMaterials.Characteristic = Goods.Characteristic
	|			AND AlternativeMaterials.ProductsRole IN (VALUE(Enum.SubstituteRoles.Material), VALUE(Enum.SubstituteRoles.InterchangeableSubstitute))
	|			AND (Goods.PermissionValidityDate = DATETIME(1, 1, 1)
	|			OR (AlternativeMaterials.Period <= Goods.PermissionValidityDate
	|			AND (AlternativeMaterials.EndPeriod = DATETIME(1, 1, 1)
	|				OR AlternativeMaterials.EndPeriod >= Goods.PermissionValidityDate)))
	|			AND &SelectionOfPermissions
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.ScopesOfSubstitutes AS AreasOfAction
	|			WHERE
	|				AreasOfAction.Resolution = AlternativeMaterials.Recorder
	|				AND (AreasOfAction.ProductionOrder IN (Goods.ProductionOrder,
	|															VALUE(Document.ProductionOrder2_2.EmptyRef),
	|															UNDEFINED))
	|				AND (AreasOfAction.SalesOrder IN (Goods.SalesOrder, VALUE(Document.SalesOrder.EmptyRef)))
	|				AND (AreasOfAction.BillOfMaterials IN (Goods.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)))
	|				AND (AreasOfAction.Stage IN (Goods.Stage, VALUE(Catalog.ProductionStages.EmptyRef)))
	|				AND (AreasOfAction.Product = Goods.Product
	|						AND AreasOfAction.ItemVariantOfProduct IN (Goods.ItemVariantOfProduct, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) 
	|					OR AreasOfAction.Product = VALUE(Catalog.Products.EmptyRef)
	|						AND AreasOfAction.ItemVariantOfProduct = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|				AND (AreasOfAction.Department IN (Goods.Department, VALUE(Catalog.BusinessStructure.EmptyRef)))
	|				AND (AreasOfAction.LineOfBusiness IN (Goods.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)))) 
	|
	|INDEX BY
	|	Resolution,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.LineNumber LineNumberOfGoods,
	|	Goods.Resolution AS Resolution,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package AS Package,
	|	Goods.ReplacementPriority AS ReplacementPriority,
	|	Goods.ProductsRole AS ProductsRole,
	|	Goods.Department AS Department,
	|	Goods.Purpose AS Purpose,
	|	Goods.WithAssignment AS WithAssignment,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	AlternativeMaterials.Products AS Substitute,
	|	AlternativeMaterials.Characteristic AS VariantOfAlternativeMaterial,
	|	AlternativeMaterials.Package AS PackageOfAlternativeMaterial,
	|	AlternativeMaterials.NumberOfPackages AS NumberOfPackagesOfAlternativeMaterial,
	|	&Priority AS Priority,
	|	AlternativeMaterials.Period AS Period,
	|	AlternativeMaterials.LineNumber AS LineNumberAnalog,
	|	Goods.MaterialQuantity AS MaterialQuantity,
	|	Goods.TotalAmountOfMaterial AS TotalAmountOfMaterial
	|INTO AlternativeMaterials
	|FROM
	|	GoodsAndPermits AS Goods
	|		INNER JOIN InformationRegister.AlternativeMaterials AS AlternativeMaterials
	|		ON Goods.Resolution = AlternativeMaterials.Recorder
	|			AND AlternativeMaterials.ProductsRole IN (VALUE(Enum.SubstituteRoles.Substitute), VALUE(Enum.SubstituteRoles.InterchangeableSubstitute))
	|
	|INDEX BY
	|	Substitute,
	|	VariantOfAlternativeMaterial
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData.Recorder AS Resolution
	|INTO ExcludedPermissions
	|FROM
	|	InformationRegister.AlternativeMaterials AS RegisterData
	|		LEFT JOIN AlternativeMaterials AS AlternativeMaterials
	|		ON RegisterData.Recorder = AlternativeMaterials.Resolution
	|			AND RegisterData.Products = AlternativeMaterials.Products
	|			AND RegisterData.Characteristic = AlternativeMaterials.Characteristic
	|WHERE 
	|	RegisterData.ProductsRole = VALUE(Enum.SubstituteRoles.Material)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				AlternativeMaterials AS AlternativeMaterials
	|			WHERE
	|				AlternativeMaterials.Resolution = RegisterData.Recorder)
	|	AND AlternativeMaterials.Resolution IS NULL
	|
	|INDEX BY
	|	Resolution
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AlternativeMaterials.Ref AS Ref,
	|	AlternativeMaterials.Period AS Period,
	|	AlternativeMaterials.Resolution AS Resolution,
	|	AlternativeMaterials.Products AS Products,
	|	AlternativeMaterials.Characteristic AS Characteristic,
	|	AlternativeMaterials.Purpose AS Purpose,
	|	AlternativeMaterials.WithAssignment AS WithAssignment,
	|	AlternativeMaterials.NumberOfPackages AS NumberOfPackages,
	|	AlternativeMaterials.Package AS Package,
	|	AlternativeMaterials.Priority AS Priority,
	|	AlternativeMaterials.ReplacementPriority AS ReplacementPriority,
	|	AlternativeMaterials.ProductsRole AS ProductsRole,
	|	AlternativeMaterials.LineNumberOfGoods AS LineNumberOfGoods,
	|	AlternativeMaterials.MaterialQuantity AS MaterialQuantity,
	|	AlternativeMaterials.TotalAmountOfMaterial AS TotalAmountOfMaterial
	|INTO TableOfMaterialsByPurpose
	|FROM
	|	AlternativeMaterials AS AlternativeMaterials
	|WHERE
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					ExcludedPermissions AS ExcludedPermissions
	|				WHERE
	|					ExcludedPermissions.Resolution = AlternativeMaterials.Resolution)
	|
	|INDEX BY
	|	LineNumberOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfMaterialsByPurpose.Ref AS Ref,
	|	TableOfMaterialsByPurpose.Period AS Period,
	|	TableOfMaterialsByPurpose.Resolution AS Resolution,
	|	TableOfMaterialsByPurpose.Products AS Products,
	|	TableOfMaterialsByPurpose.Characteristic AS Characteristic,
	|	TableOfMaterialsByPurpose.NumberOfPackages AS NumberOfPackages,
	|	TableOfMaterialsByPurpose.Package AS Package,
	|	TableOfMaterialsByPurpose.Priority AS Priority,
	|	TableOfMaterialsByPurpose.ReplacementPriority AS ReplacementPriority,
	|	TableOfMaterialsByPurpose.ProductsRole AS ProductsRole
	|INTO TableOfMaterials
	|FROM
	|	TableOfMaterialsByPurpose AS TableOfMaterialsByPurpose
	|
	|INDEX BY
	|	Resolution,
	|	Ref,
	|	Products,
	|	Characteristic";
	
	QueryTextPriorityField = ?(CalculateApplicationPriority, 
		"AlternativeMaterials.ScopeMaxPriority", "1");
		
	If TypeOf(Filter) = Type("Map")
	   And Not GetFunctionalOption("DynamicStructureOfProductionOrders")
	   And Filter.Get("AlternativeMaterials.ReplacementPriority") <> Undefined Then
	
		Filter.Delete("AlternativeMaterials.ReplacementPriority");
	
	EndIf;
	
	QueryTextSelectionOfPermissions = TMCommonUse.SelectionTextBySelectionCollection(Filter);
		
	QueryText = StrReplace(QueryText, "&Priority", QueryTextPriorityField);
	
	QueryText = StrReplace(QueryText, "&SelectionOfPermissions", QueryTextSelectionOfPermissions);
	
	QueryText = StrReplace(QueryText, "&TextReplacementPriority", ReplacementPriorityTextField());
	
	Return QueryText;
	
EndFunction

// Returns the query text with temporary tables that define the table of analogues from the available permissions
//
// Parameters:
//  GetWarehouseFromChina - Boolean - True: the Warehouse is determined from the security scheme
//                                        False: the Warehouse is passed as a parameter.
//
// Returns:
//  String - query text.
//
Function QueryTextTableOfAnalogues(GetWarehouseFromChina = True) Export
	
	QueryText =
	"SELECT DISTINCT
	|	TableOfMaterials.Ref AS Ref,
	|	TableOfMaterials.Resolution AS Resolution,
	|	AlternativeMaterials.LineNumberAnalog AS LineNumberAnalog,
	|	AlternativeMaterials.Substitute AS Products,
	|	AlternativeMaterials.VariantOfAlternativeMaterial AS Characteristic,
	|	AlternativeMaterials.NumberOfPackagesOfAlternativeMaterial AS NumberOfPackages,
	|	AlternativeMaterials.PackageOfAlternativeMaterial AS Package,
	|	AlternativeMaterials.ReplacementPriority AS ReplacementPriority,
	|	AlternativeMaterials.ProductsRole AS ProductsRole,
	|	AlternativeMaterials.Department AS Department
	|INTO TableOfAnaloguesWithSources
	|FROM
	|	TableOfMaterials AS TableOfMaterials
	|		LEFT JOIN AlternativeMaterials AS AlternativeMaterials
	|		ON TableOfMaterials.Resolution = AlternativeMaterials.Resolution
	|			AND TableOfMaterials.Ref = AlternativeMaterials.Ref
	|WHERE
	|	NOT(TableOfMaterials.Products = AlternativeMaterials.Substitute
	|				AND TableOfMaterials.Characteristic = AlternativeMaterials.VariantOfAlternativeMaterial
	|				AND TableOfMaterials.ProductsRole = VALUE(Enum.SubstituteRoles.InterchangeableSubstitute))
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfAnalogues.Ref AS Ref,
	|	TableOfAnalogues.LineNumberAnalog AS LineNumberAnalog,
	|	TableOfAnalogues.Resolution AS Resolution,
	|	TableOfAnalogues.Products AS Products,
	|	TableOfAnalogues.Characteristic AS Characteristic,
	|	TableOfAnalogues.NumberOfPackages AS NumberOfPackages,
	|	TableOfAnalogues.Package AS Package,
	|	&Warehouse AS Warehouse,
	|	TableOfAnalogues.ReplacementPriority AS ReplacementPriority,
	|	TableOfAnalogues.ProductsRole AS ProductsRole
	|INTO TableOfAnalogues
	|FROM
	|	TableOfAnaloguesWithSources AS TableOfAnalogues";
	
	If GetWarehouseFromChina Then
		
		StructureOfQueryTexts = ProductionSupply.RequestTextForContentTransferSettings(
			"TableOfAnalogues", 
			"Department", 
			ProductionSupply.SoftwareOptionAccordingToProductionVersion(True));
		
		QueryText = StrReplace(QueryText, "&Warehouse", StructureOfQueryTexts.WarehouseTextField);
		
		QueriesTexts = New Array;
		QueriesTexts.Add(QueryText);
		QueriesTexts.Add(StructureOfQueryTexts.JoinText);
	
		QueryText = StrConcat(QueriesTexts, Chars.LF);
		
	EndIf;
	
	IndexText_ =
	"
	|INDEX BY
	|	Products,
	|	Characteristic";
	
	QueriesTexts = New Array;
	QueriesTexts.Add(QueryText);
	QueriesTexts.Add(IndexText_);
	
	QueryText = StrConcat(QueriesTexts, Chars.LF);
	
	Return QueryText;
	
EndFunction

// Returns the query text with temporary tables that define possible and available many to many permissions
//
// Parameters:
//  SelectionParameters_2 - Structure, Undefined - Contains:
//                      * ConsiderManyToMany - Boolean - determines whether to get the available many-to-many permissions
//
// Returns:
//  String - query text.
//
Function QueryTextAvailableManyToManyPermissions(SelectionParameters_2 = Undefined) Export 
	
	ConsiderManyToMany = SelectionParameters_2 <> Undefined 
						   And SelectionParameters_2.Property("ConsiderManyToMany") 
						   And SelectionParameters_2.ConsiderManyToMany;
	
	QueryText =
	"SELECT
	|	TableOfMaterials.Resolution AS Resolution
	|INTO ManyToManyPermissions
	|FROM
	|	TableOfMaterials AS TableOfMaterials
	|WHERE
	|	TableOfMaterials.ProductsRole <> VALUE(Enum.SubstituteRoles.InterchangeableSubstitute)
	|
	|GROUP BY
	|	TableOfMaterials.Resolution
	|
	|HAVING
	|	COUNT(DISTINCT TableOfMaterials.Products) + COUNT(DISTINCT TableOfMaterials.Characteristic) > 2
	|
	|INDEX BY
	|	Resolution";
	
	If ConsiderManyToMany Then
		
		QueryTexts = New Array;
		QueryTexts.Add(QueryText);
	
		QueryText =
		"SELECT DISTINCT
		|	ManyToManyPermissions.Resolution AS Resolution,
		|	TableOfMaterials.Products      AS Products,
		|	TableOfMaterials.Characteristic    AS Characteristic
		|INTO PermissionsManyToManyMaterials
		|FROM
		|	ManyToManyPermissions AS ManyToManyPermissions
		|		LEFT JOIN TableOfMaterials AS TableOfMaterials
		|		ON ManyToManyPermissions.Resolution = TableOfMaterials.Resolution
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PermissionsManyToManyMaterials.Resolution AS Resolution,
		|	SUM(1) AS NumberOfDifferentRows
		|INTO ManyToManyPermissionsNumberOfDifferentRows
		|FROM
		|	PermissionsManyToManyMaterials AS PermissionsManyToManyMaterials
		|
		|GROUP BY
		|	PermissionsManyToManyMaterials.Resolution
		|
		|INDEX BY
		|	Resolution
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AvailableManyToManyPermissions.Ref AS Ref,
		|	AvailableManyToManyPermissions.Resolution AS Resolution
		|INTO AvailableManyToManyPermissions
		|FROM
		|	(SELECT DISTINCT
		|		Goods.Ref AS Ref,
		|		Goods.Products AS Products,
		|		Goods.Characteristic AS Characteristic,
		|		PermissionsManyToManyMaterials.Resolution AS Resolution,
		|		ManyToManyPermissionsNumberOfDifferentRows.NumberOfDifferentRows AS NumberOfDifferentRows
		|	FROM
		|		Goods AS Goods
		|			LEFT JOIN PermissionsManyToManyMaterials AS PermissionsManyToManyMaterials
		|			ON Goods.Products = PermissionsManyToManyMaterials.Products
		|				AND Goods.Characteristic = PermissionsManyToManyMaterials.Characteristic
		|			LEFT JOIN ManyToManyPermissionsNumberOfDifferentRows AS ManyToManyPermissionsNumberOfDifferentRows
		|			ON (PermissionsManyToManyMaterials.Resolution = ManyToManyPermissionsNumberOfDifferentRows.Resolution)
		|	WHERE
		|		PermissionsManyToManyMaterials.Resolution IS NOT NULL ) AS AvailableManyToManyPermissions
		|
		|GROUP BY
		|	AvailableManyToManyPermissions.Ref,
		|	AvailableManyToManyPermissions.Resolution
		|
		|HAVING
		|	SUM(1) = MAX(AvailableManyToManyPermissions.NumberOfDifferentRows)
		|
		|INDEX BY
		|	Resolution,
		|	Ref";
		
		QueryTexts.Add(QueryText);
		
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the request text that determines whether there are analogs
//
// Returns:
//  String - query text.
//
Function QueryTextAvailabilityOfAnalogues() Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber AS LineNumber
	|FROM
	|	Goods AS Goods
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				TableOfMaterials AS TableOfMaterials
	|			WHERE
	|				TableOfMaterials.Products = Goods.Products
	|				AND TableOfMaterials.Characteristic = Goods.Characteristic
	|				AND TableOfMaterials.Ref = Goods.Ref
	|				AND NOT TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							ManyToManyPermissions AS ManyToManyPermissions
	|						WHERE
	|							ManyToManyPermissions.Resolution = TableOfMaterials.Resolution))
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.LineNumber
	|FROM
	|	Goods AS Goods
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				AvailableManyToManyPermissions AS AvailableManyToManyPermissions
	|					LEFT JOIN Document.EngineeringChangeOrder.UsedMaterials AS ResolutionMaterials
	|					ON
	|						AvailableManyToManyPermissions.Resolution = ResolutionMaterials.Ref
	|			WHERE
	|				AvailableManyToManyPermissions.Ref = Goods.Ref
	|				AND ResolutionMaterials.Products = Goods.Products
	|				AND ResolutionMaterials.Characteristic = Goods.Characteristic)";
	
	Return QueryText;
	
EndFunction	

// Returns the request text for selected permissions, materials, and analogues
//
// Parameters:
//  SelectionParameters_2 - Structure - Contains:
//                      * ConsiderManyToMany - Boolean - determines the need to obtain available many-to-many permissions.
//                   - Undefined - if there is no many-to-many selection.
//
// Returns:
//  String - query text.
//
Function TextOfPermissionRequestByPriority(SelectionParameters_2 = Undefined) Export
	
	ConsiderManyToMany = SelectionParameters_2 <> Undefined 
						   And SelectionParameters_2.Property("ConsiderManyToMany") 
						   And SelectionParameters_2.ConsiderManyToMany;
		
	QueryTexts = New Array;
	
	QueryText =
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Warehouse AS Warehouse,
	|	Table.Purpose AS Purpose,
	|	Table.CountBalance AS Balance
	|FROM 
	|	BalanceTable AS Table
	|;
	|SELECT
	|	TableOfMaterials.Ref AS Ref,
	|	TableOfMaterials.Resolution AS Resolution,
	|	TableOfMaterials.Products AS Products,
	|	TableOfMaterials.Characteristic AS Characteristic,
	|	TableOfMaterials.NumberOfPackages AS NormativeStandard,
	|	TableOfMaterials.Package AS Package,
	|	UNDEFINED AS PackageData,
	|	TableOfMaterials.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS ControlMultiplier
	|FROM
	|	TableOfMaterials AS TableOfMaterials
	|WHERE
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					ManyToManyPermissions AS ManyToManyPermissions
	|				WHERE
	|					ManyToManyPermissions.Resolution = TableOfMaterials.Resolution)";
	
	QueryTexts.Add(QueryText);
	
	If ConsiderManyToMany Then
	
		QueryText =
		"SELECT
		|	TableOfMaterials.Ref,
		|	TableOfMaterials.Resolution,
		|	TableOfMaterials.Products,
		|	TableOfMaterials.Characteristic,
		|	TableOfMaterials.NumberOfPackages,
		|	TableOfMaterials.Package,
		|	UNDEFINED,
		|	TableOfMaterials.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|FROM
		|	TableOfMaterials AS TableOfMaterials
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				AvailableManyToManyPermissions AS AvailableManyToManyPermissions
		|			WHERE
		|				AvailableManyToManyPermissions.Resolution = TableOfMaterials.Resolution
		|				AND AvailableManyToManyPermissions.Ref = TableOfMaterials.Ref)";
		
		QueryTexts.Add(QueryText);
		
		QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
		QueryTexts.Clear();
		
		QueryTexts.Add(QueryText);
		
	EndIf;
	
	QueryText =
	"SELECT
	|	TableOfAnalogues.Ref AS Ref,
	|	TableOfAnalogues.LineNumberAnalog AS LineNumberAnalog,
	|	TableOfAnalogues.Resolution AS Resolution,
	|	TableOfAnalogues.ReplacementPriority AS ReplacementPriority,
	|	TableOfAnalogues.ProductsRole = VALUE(Enum.SubstituteRoles.InterchangeableSubstitute) AS InterchangeableSubstitute,
	|	TableOfAnalogues.Products AS Products,
	|	TableOfAnalogues.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) AS ThisIsWork,
	|	TableOfAnalogues.Characteristic AS Characteristic,
	|	TableOfAnalogues.NumberOfPackages AS NormativeStandard,
	|	TableOfAnalogues.Package AS Package,
	|	UNDEFINED AS PackageData,
	|	UNDEFINED AS LineIsSeparateBalance,
	|	UNDEFINED AS LineFreeBalance,
	|	0 AS WarehouseStockBalance,
	|	0 AS DetachedBalance,
	|	TableOfAnalogues.Warehouse AS Warehouse
	|FROM
	|	TableOfAnalogues AS TableOfAnalogues
	|WHERE
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					ManyToManyPermissions AS ManyToManyPermissions
	|				WHERE
	|					ManyToManyPermissions.Resolution = TableOfAnalogues.Resolution)
	|";
	
	QueryTexts.Add(QueryText);
	
	If ConsiderManyToMany Then
		
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		QueryTexts.Clear();
		
		QueryTexts.Add(QueryText);
	
		QueryText =
		"SELECT
		|	TableOfAnalogues.Ref,
		|	TableOfAnalogues.LineNumberAnalog,
		|	TableOfAnalogues.Resolution,
		|	TableOfAnalogues.ReplacementPriority,
		|	TableOfAnalogues.ProductsRole = VALUE(Enum.SubstituteRoles.InterchangeableSubstitute),
		|	TableOfAnalogues.Products,
		|	TableOfAnalogues.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5),
		|	TableOfAnalogues.Characteristic,
		|	TableOfAnalogues.NumberOfPackages,
		|	TableOfAnalogues.Package,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	0,
		|	0,
		|	TableOfAnalogues.Warehouse
		|FROM
		|	TableOfAnalogues AS TableOfAnalogues
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				AvailableManyToManyPermissions AS AvailableManyToManyPermissions
		|			WHERE
		|				AvailableManyToManyPermissions.Resolution = TableOfAnalogues.Resolution
		|				AND AvailableManyToManyPermissions.Ref = TableOfAnalogues.Ref)
		|";
		
		QueryTexts.Add(QueryText);
		
		QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
		QueryTexts.Clear();
		
		QueryTexts.Add(QueryText);
		
	Else
		
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		QueryTexts.Clear();
		
		QueryTexts.Add(QueryText);
		
	EndIf;
	
	QueryText = 
	"
	|
	|ORDER BY
	|	LineNumberAnalog";
	
	QueryTexts.Add(QueryText);
	
	QueryText = StrConcat(QueryTexts);
	QueryTexts.Clear();
	QueryTexts.Add(QueryText);
	
	QueryText =
	"SELECT
	|	Goods.Ref AS Ref,
	|	Goods.LineNumberOfGoods AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.WithAssignment AS WithAssignment,
	|	Goods.MaterialQuantity AS Count,
	|	Goods.TotalAmountOfMaterial AS TotalCount1,
	|	Goods.Resolution AS Resolution,
	|	Goods.ReplacementPriority AS ReplacementPriority,
	|	Goods.ProductsRole AS ProductsRole,
	|	Goods.Priority AS Priority,
	|	Goods.Period AS Period,
	|	CASE
	|		WHEN Goods.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute)
	|			THEN 1
	|		WHEN Goods.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials)
	|			THEN 2
	|		ELSE 10
	|	END AS PriorityAccordingToInstructionsForReplacement
	|FROM
	|	TableOfMaterialsByPurpose AS Goods
	|WHERE
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					ManyToManyPermissions AS ManyToManyPermissions
	|				WHERE
	|					ManyToManyPermissions.Resolution = Goods.Resolution)";
	
	QueryTexts.Add(QueryText);
	
	If ConsiderManyToMany Then
		
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		QueryTexts.Clear();
		
		QueryTexts.Add(QueryText);
		
		QueryText =	
		"SELECT
		|	Goods.Ref,
		|	Goods.LineNumberOfGoods,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.WithAssignment,
		|	Goods.MaterialQuantity,
		|	Goods.TotalAmountOfMaterial,
		|	Goods.Resolution,
		|	Goods.ReplacementPriority,
		|	Goods.ProductsRole,
		|	Goods.Priority,
		|	Goods.Period,
		|	CASE
		|		WHEN Goods.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute)
		|			THEN 1
		|		WHEN Goods.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials)
		|			THEN 2
		|		ELSE 10
		|	END
		|FROM
		|	TableOfMaterialsByPurpose AS Goods
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				AvailableManyToManyPermissions AS AvailableManyToManyPermissions
		|			WHERE
		|				AvailableManyToManyPermissions.Resolution = Goods.Resolution
		|				AND AvailableManyToManyPermissions.Ref = Goods.Ref)";
		
		QueryTexts.Add(QueryText);
		
		QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
		QueryTexts.Clear();
		
		QueryTexts.Add(QueryText);
		
	EndIf;	
	
	If Not ConsiderManyToMany Then
		
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		QueryTexts.Clear();
		
		QueryTexts.Add(QueryText);
		
	EndIf;	
	
	QueryText = 
	"
	|
	|ORDER BY
	|	LineNumber,
	|	WithAssignment DESC,
	|	PriorityAccordingToInstructionsForReplacement,
	|	Priority DESC,
	|	Period DESC,
	|	Resolution DESC";
	
	QueryTexts.Add(QueryText);
	QueryText = StrConcat(QueryTexts);
	
	QueryTexts.Clear();
	QueryTexts.Add(QueryText);
	QueryText = 
	"SELECT
	|	Goods.Ref AS Ref,
	|	Goods.Purpose AS Purpose,
	|	MAX(Goods.WithAssignment) AS WithAssignment,
	|	Goods.Resolution AS Resolution
	|FROM
	|	TableOfMaterialsByPurpose AS Goods
	|WHERE
	|	Goods.ProductsRole <> VALUE(Enum.SubstituteRoles.InterchangeableSubstitute)
	|
	|GROUP BY
	|	Goods.Resolution,
	|	Goods.Ref,
	|	Goods.Purpose";
	
	QueryTexts.Add(QueryText);
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

// Returns the query text for the temporary table " table of Statistics"
//
// Parameters:
//  SelectionParameters_2 - Structure - Contains:
//                      * ApplyInventoryTable - Boolean - true: replaces the amount of free balance from the "Inventory allocation" register
//                                                                   with the "Quantity" from the inventory table if there are corresponding rows
//                                                           false: the inventory table is not used.
//                      * ApplyReserveTable - Boolean -true: reduces the amount of free Balance from the "Inventory Allocation" register
//                                                                   by the "Amount" from the reserves table if there are corresponding rows
//                                                           false: the inventory table is not used.
//
// Returns:
//  String - query text.
//
Function QueryTextTableLeftovers(SelectionParameters_2) Export
				
	ApplyInventoryTable = SelectionParameters_2.Property("ApplyInventoryTable")
							  And SelectionParameters_2.ApplyInventoryTable;
		
	ApplyReserveTable = SelectionParameters_2.Property("ApplyReserveTable") 
							   And SelectionParameters_2.ApplyReserveTable;
							
	GetBalancesAtOtherWarehouses = SelectionParameters_2.Property("GetBalancesAtOtherWarehouses") 
							   And SelectionParameters_2.GetBalancesAtOtherWarehouses;
	
	QueryTexts = New Array;
	
	If ApplyInventoryTable Then
		
		QueryText = 
		"SELECT
		|	InventoryTable.Products AS Products,
		|	InventoryTable.Characteristic AS Characteristic,
		|	InventoryTable.Warehouse AS Warehouse,
		|	InventoryTable.Purpose AS Purpose,
		|	InventoryTable.WithAssignment AS WithAssignment,
		|	InventoryTable.Count AS Count
		|INTO InventoryTransferred
		|FROM
		|	&Inventories AS InventoryTable
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	SUM(Inventories.Count) AS Count
		|INTO InventoryTable
		|FROM
		|	InventoryTransferred AS Inventories
		|
		|GROUP BY
		|	Inventories.Products,
		|	Inventories.Characteristic,
		|	Inventories.Warehouse,
		|	Inventories.Purpose
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose";
		
	Else
		
		QueryText =
		"SELECT TOP 0
		|	NULL AS Products,
		|	NULL AS Characteristic,
		|	NULL AS Warehouse,
		|	NULL AS Purpose,
		|	NULL AS WithAssignment,
		|	NULL AS Count
		|INTO InventoryTransferred
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 0
		|	NULL AS Products,
		|	NULL AS Characteristic,
		|	NULL AS Warehouse,
		|	NULL AS Purpose,
		|	NULL AS Count
		|INTO InventoryTable";
		
	EndIf;
	
	QueryTexts.Add(QueryText);
	
	If ApplyReserveTable Then	
		
		QueryText = 
		"SELECT
		|	Reserves.Products AS Products,
		|	Reserves.Characteristic AS Characteristic,
		|	Reserves.Warehouse AS Warehouse,
		|	Reserves.Purpose AS Purpose,
		|	Reserves.Count AS Count
		|INTO Reserves
		|FROM
		|	&Reserves AS Reserves
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfReserves.Products AS Products,
		|	TableOfReserves.Characteristic AS Characteristic,
		|	TableOfReserves.Warehouse AS Warehouse,
		|	TableOfReserves.Purpose AS Purpose,
		|	SUM(TableOfReserves.Count) AS Count
		|INTO TableOfReserves
		|FROM
		|	Reserves AS TableOfReserves
		|
		|GROUP BY
		|	TableOfReserves.Products,
		|	TableOfReserves.Characteristic,
		|	TableOfReserves.Warehouse,
		|	TableOfReserves.Purpose
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose";
		
	Else
		
		QueryText =
		"SELECT TOP 0
		|	NULL AS Products,
		|	NULL AS Characteristic,
		|	NULL AS Warehouse,
		|	NULL AS Purpose,
		|	NULL AS Count
		|INTO TableOfReserves";
		
	EndIf;
	
	QueryTexts.Add(QueryText);
	
	QueryTextTableAnalogsWithPurpose = 
	"SELECT
	|	GoodsAndPermits.Ref AS Ref,
	|	GoodsAndPermits.Resolution AS Resolution,
	|	GoodsAndPermits.Purpose AS Purpose
	|INTO LinkAssignments
	|FROM
	|	GoodsAndPermits AS GoodsAndPermits
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsAndPermits.Ref,
	|	GoodsAndPermits.Resolution,
	|	VALUE(Catalog.Assignments.EmptyRef)
	|FROM
	|	GoodsAndPermits AS GoodsAndPermits
	|
	|INDEX BY
	|	Ref,
	|	Resolution
	|;
	|
	|SELECT DISTINCT
	|	AnalogsWithPurpose.Products AS Products,
	|	AnalogsWithPurpose.Characteristic AS Characteristic,
	|	AnalogsWithPurpose.Warehouse AS Warehouse,
	|	AnalogsWithPurpose.SupplyAssignment AS SupplyAssignment
	|INTO AnalogsWithPurpose
	|FROM
	|	(SELECT
	|		TableOfAnalogues.Products AS Products,
	|		TableOfAnalogues.Characteristic AS Characteristic,
	|		TableOfAnalogues.Warehouse AS Warehouse,
	|		LinkAssignments.Purpose AS SupplyAssignment
	|	FROM
	|		TableOfAnalogues AS TableOfAnalogues
	|			INNER JOIN LinkAssignments AS LinkAssignments
	|			ON TableOfAnalogues.Ref = LinkAssignments.Ref
	|				AND TableOfAnalogues.Resolution = LinkAssignments.Resolution) AS AnalogsWithPurpose
	|;
	|SELECT
	|	TableOfAnalogues.Products AS Products,
	|	TableOfAnalogues.Characteristic AS Characteristic,
	|	TableOfAnalogues.Warehouse AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|INTO SelectionOfBalanceAnalogues
	|FROM
	|	TableOfAnalogues AS TableOfAnalogues
	|
	|UNION ALL
	|
	|SELECT
	|	AnalogsWithPurpose.Products,
	|	AnalogsWithPurpose.Characteristic,
	|	AnalogsWithPurpose.Warehouse,
	|	AnalogsWithPurpose.SupplyAssignment
	|FROM
	|	AnalogsWithPurpose AS AnalogsWithPurpose
	|WHERE
	|	AnalogsWithPurpose.SupplyAssignment <> VALUE(Catalog.Assignments.EmptyRef)
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose";
	
	If GetBalancesAtOtherWarehouses Then
		
		QueryTextTableStocksAreTemporary = 
		"SELECT ALLOWED
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
		|			(Products, Characteristic, Purpose) IN(
		|				SELECT
		|					SelectionOfBalanceAnalogues.Products AS Products,
		|					SelectionOfBalanceAnalogues.Characteristic AS Characteristic,
		|					SelectionOfBalanceAnalogues.Purpose AS Purpose
		|				FROM
		|					SelectionOfBalanceAnalogues AS SelectionOfBalanceAnalogues)) AS Inventories
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
		
	Else
		
		QueryTextTableStocksAreTemporary = 
		"SELECT
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
		|	(Products, Characteristic, Warehouse, Purpose) IN(
		|		SELECT
		|			TableOfAnalogues.Products AS Products,
		|			TableOfAnalogues.Characteristic AS Characteristic,
		|			TableOfAnalogues.Warehouse AS Warehouse,
		|			TableOfAnalogues.Purpose AS Purpose
		|		FROM
		|			SelectionOfBalanceAnalogues AS TableOfAnalogues)) AS Inventories
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
		
	EndIf;
	
	QueryTextTableLeftovers = 
	"SELECT
	|	Calculation.Products AS Products,
	|	Calculation.Characteristic AS Characteristic,
	|	Calculation.Warehouse AS Warehouse,
	|	Calculation.Purpose AS Purpose,
	|	Calculation.Purpose <> VALUE(Catalog.Assignments.EmptyRef) AS WithAssignment,
	|	Calculation.QuantityForShipAction AS AvailableForInventoryAllocation
	|INTO StocksAreTemporary
	|FROM
	|	CalculationOfBalancesForSettingActions AS Calculation
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose
	|
	|;
	|////////////////////////////////////////////////
	|SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Warehouse AS Warehouse,
	|	Table.Purpose AS Purpose,
	|	&Count AS CountBalance
	|INTO NameOfRemainderTable
	|FROM
	|	StocksAreTemporary AS Table
	|		
	|		LEFT JOIN InventoryTable AS InventoryTable
	|		ON Table.Products = InventoryTable.Products
	|		 AND Table.Characteristic = InventoryTable.Characteristic
	|		 AND Table.Warehouse = InventoryTable.Warehouse
	|		 AND Table.Purpose = InventoryTable.Purpose
	|		
	|		LEFT JOIN TableOfReserves AS TableOfReserves
	|		ON Table.Products = TableOfReserves.Products
	|		 AND Table.Characteristic = TableOfReserves.Characteristic
	|		 AND Table.Warehouse = TableOfReserves.Warehouse
	|		 AND Table.Purpose = TableOfReserves.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Warehouse,
	|	Table.SupplyAssignment,
	|	0
	|FROM
	|	AnalogsWithPurpose AS Table
	|WHERE
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					StocksAreTemporary AS StocksAreTemporary
	|				WHERE
	|					StocksAreTemporary.Products = Table.Products
	|					AND StocksAreTemporary.Characteristic = Table.Characteristic
	|					AND StocksAreTemporary.Warehouse = Table.Warehouse
	|					AND StocksAreTemporary.Purpose = Table.SupplyAssignment)
	|
	|INDEX BY
	|	Products, Characteristic, Warehouse";
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryTextTableLeftovers, TablesNames);
	
	ArrayOfQueryTextsForGettingBalances = New Array;
	ArrayOfQueryTextsForGettingBalances.Add(QueryTextTableAnalogsWithPurpose);
	ArrayOfQueryTextsForGettingBalances.Add(QueryTextTableStocksAreTemporary);
	ArrayOfQueryTextsForGettingBalances.Add(QueryTextTableLeftovers);
	
	QueryText = StrConcat(ArrayOfQueryTextsForGettingBalances, Common.QueryBatchSeparator());
	
	QueryTexts.Add(QueryText);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	QueryText = StrReplace(QueryText, 
		"&Count", ?(ApplyInventoryTable, "ISNULL(InventoryTable.Count, Table.AvailableForInventoryAllocation)", "Table.AvailableForInventoryAllocation") + "&Count");
		
	QueryText = StrReplace(QueryText, 
		"&Count", ?(ApplyReserveTable, " - ISNULL(TableOfReserves.Count, 0)", ""));
	
	If GetBalancesAtOtherWarehouses Then
		
		QueryTextBalancesWithOtherWarehouses = 
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.CountBalance AS CountBalance
		|INTO BalanceTable
		|FROM
		|	AllBalance AS Table
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				SelectionOfBalanceAnalogues AS SelectionOfBalanceAnalogues
		|			WHERE
		|				SelectionOfBalanceAnalogues.Products = Table.Products
		|				AND SelectionOfBalanceAnalogues.Characteristic = Table.Characteristic
		|				AND SelectionOfBalanceAnalogues.Warehouse = Table.Warehouse
		|				AND SelectionOfBalanceAnalogues.Purpose = Table.Purpose)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose,
		|	SUM(Table.CountBalance) AS CountBalance
		|INTO TableOfBalancesAtOtherWarehouses
		|FROM
		|	AllBalance AS Table
		|WHERE
		|	NOT TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				SelectionOfBalanceAnalogues AS SelectionOfBalanceAnalogues
		|			WHERE
		|				SelectionOfBalanceAnalogues.Products = Table.Products
		|				AND SelectionOfBalanceAnalogues.Characteristic = Table.Characteristic
		|				AND SelectionOfBalanceAnalogues.Warehouse = Table.Warehouse
		|				AND SelectionOfBalanceAnalogues.Purpose = Table.Purpose)
		|
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose";
		
		QueryText = StrReplace(QueryText, "NameOfRemainderTable", "AllBalance");
		
		QueryTexts.Clear();
		QueryTexts.Add(QueryText);
		QueryTexts.Add(QueryTextBalancesWithOtherWarehouses);
		
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	Else
		
		QueryText = StrReplace(QueryText, "NameOfRemainderTable", "BalanceTable");
	
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the Query Text with temp tables that define possible permissions for the transmitted content. 
//
// Parameters:
//  SelectionParameters_2 - Structure, Undefined - Contains:
//                      * GoodsTogetherWithParameters - Boolean - checks whether the parameters are passed in the same table with the products.
//                      * SelectionOfPermissions - Map of KeyAndValue - collection where: 
//                          	** Key - String - parameter name.
//                          	** Value - String - parameter value.
//
// Returns:
//  String - query text.
//
Function QueryTextGoodsWithPermissions(SelectionParameters_2 = Undefined) Export
	
	GoodsTogetherWithParameters = SelectionParameters_2 <> Undefined 
						   And SelectionParameters_2.Property("GoodsTogetherWithParameters") 
						   And SelectionParameters_2.GoodsTogetherWithParameters;
						   
	If SelectionParameters_2 <> Undefined
	   And SelectionParameters_2.Property("SelectionOfPermissions") Then
		SelectionOfPermissions = SelectionParameters_2.SelectionOfPermissions;
	Else
		SelectionOfPermissions = New Map;
	EndIf;
	
	If GoodsTogetherWithParameters Then
	
		QueryTextGoods =
		"SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Ref AS Ref,
		|	Goods.PermissionValidityDate AS PermissionValidityDate,
		|	Goods.ProductionOrder AS ProductionOrder,
		|	Goods.SalesOrder AS SalesOrder,
		|	Goods.BillOfMaterials AS BillOfMaterials,
		|	CAST(Goods.Stage AS Catalog.ProductionStages) AS Stage,
		|	Goods.Product AS Product,
		|	Goods.ItemVariantOfProduct AS ItemVariantOfProduct,
		|	Goods.Department AS Department,
		|	Goods.LineOfBusiness AS LineOfBusiness
		|INTO GoodsWithParameters
		|FROM
		|	&Goods AS Goods
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Ref AS Ref
		|INTO Goods
		|FROM
		|	GoodsWithParameters AS Goods
		|
		|INDEX BY
		|	Products,
		|	Characteristic";
		
	Else
		
		QueryTextGoods = "SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Ref AS Ref
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ParametersTable.Ref AS Ref,
		|	ParametersTable.PermissionValidityDate AS PermissionValidityDate,
		|	ParametersTable.ProductionOrder AS ProductionOrder,
		|	ParametersTable.SalesOrder AS SalesOrder,
		|	ParametersTable.BillOfMaterials AS BillOfMaterials,
		|	ParametersTable.Stage AS Stage,
		|	ParametersTable.Product AS Product,
		|	ParametersTable.ItemVariantOfProduct AS ItemVariantOfProduct,
		|	ParametersTable.Department AS Department,
		|	ParametersTable.LineOfBusiness AS LineOfBusiness
		|INTO ParametersTable
		|FROM
		|	&ParametersTable AS ParametersTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Ref AS Ref,
		|	ParametersTable.PermissionValidityDate AS PermissionValidityDate,
		|	ParametersTable.ProductionOrder AS ProductionOrder,
		|	ParametersTable.SalesOrder AS SalesOrder,
		|	ParametersTable.BillOfMaterials AS BillOfMaterials,
		|	ParametersTable.Stage AS Stage,
		|	ParametersTable.Product AS Product,
		|	ParametersTable.ItemVariantOfProduct AS ItemVariantOfProduct,
		|	ParametersTable.Department AS Department,
		|	ParametersTable.LineOfBusiness AS LineOfBusiness
		|INTO GoodsWithParameters
		|FROM
		|	Goods AS Goods
		|		INNER JOIN ParametersTable AS ParametersTable
		|		ON Goods.Ref = ParametersTable.Ref
		|
		|INDEX BY
		|	Products,
		|	Characteristic";
	
	EndIf;
	
	If SelectionParameters_2.Property("NameOfTemporaryGoodsTable") Then
	
		QueryTextGoods = StrReplace(QueryTextGoods, "&Goods", SelectionParameters_2.NameOfTemporaryGoodsTable);
	
	EndIf;
	
	QueryTextMaterialsAndPermissions = 
	"SELECT DISTINCT
	|	Goods.Ref AS Ref,
	|	AlternativeMaterials.Recorder AS Resolution
	|INTO TableOfLinksWithPermissions
	|FROM
	|	InformationRegister.AlternativeMaterials AS AlternativeMaterials
	|		INNER JOIN GoodsWithParameters AS Goods
	|		ON AlternativeMaterials.Products = Goods.Products
	|			AND AlternativeMaterials.Characteristic = Goods.Characteristic
	|			AND (Goods.PermissionValidityDate = DATETIME(1, 1, 1)
	|			OR (AlternativeMaterials.Period <= Goods.PermissionValidityDate
	|			AND (AlternativeMaterials.EndPeriod = DATETIME(1, 1, 1)
	|				OR AlternativeMaterials.EndPeriod >= Goods.PermissionValidityDate)))
	|			AND &SelectionOfPermissions
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.ScopesOfSubstitutes AS AreasOfAction
	|			WHERE
	|				AreasOfAction.Resolution = AlternativeMaterials.Recorder
	|				AND (AreasOfAction.ProductionOrder IN (Goods.ProductionOrder,
	|															VALUE(Document.ProductionOrder2_2.EmptyRef),
	|															UNDEFINED))
	|				AND (AreasOfAction.SalesOrder IN (Goods.SalesOrder, VALUE(Document.SalesOrder.EmptyRef)))
	|				AND (AreasOfAction.BillOfMaterials IN (Goods.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)))
	|				AND (AreasOfAction.Stage IN (Goods.Stage, VALUE(Catalog.ProductionStages.EmptyRef)))
	|				AND (AreasOfAction.Product = Goods.Product
	|						AND AreasOfAction.ItemVariantOfProduct IN (Goods.ItemVariantOfProduct, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) 
	|					OR AreasOfAction.Product = VALUE(Catalog.Products.EmptyRef)
	|						AND AreasOfAction.ItemVariantOfProduct = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|				AND (AreasOfAction.Department IN (Goods.Department, VALUE(Catalog.BusinessStructure.EmptyRef)))
	|				AND (AreasOfAction.LineOfBusiness IN (Goods.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))))
	|
	|
	|INDEX BY
	|	Resolution
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Goods.Ref AS Ref,
	|	AlternativeMaterials.Recorder AS Resolution,
	|	AlternativeMaterials.Period AS Period,
	|	AlternativeMaterials.LineNumber AS LineNumber,
	|	AlternativeMaterials.Products AS Products,
	|	AlternativeMaterials.Characteristic AS Characteristic,
	|	AlternativeMaterials.ProductsRole AS ProductsRole,
	|	&TextReplacementPriority AS ReplacementPriority,
	|	AlternativeMaterials.Package AS Package,
	|	AlternativeMaterials.NumberOfPackages AS NumberOfPackages,
	|	AlternativeMaterials.ScopeMaxPriority AS ScopeMaxPriority,
	|	AlternativeMaterials.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders
	|INTO AlternativeMaterials
	|FROM
	|	InformationRegister.AlternativeMaterials AS AlternativeMaterials
	|		INNER JOIN TableOfLinksWithPermissions AS Goods
	|		ON AlternativeMaterials.Recorder = Goods.Resolution
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AlternativeMaterials.Resolution AS Resolution,
	|	AlternativeMaterials.LineNumber AS LineNumber,
	|	AlternativeMaterials.Period AS Period,
	|	AlternativeMaterials.Products AS Products,
	|	AlternativeMaterials.Characteristic AS Characteristic,
	|	AlternativeMaterials.ProductsRole AS ProductsRole,
	|	AlternativeMaterials.ReplacementPriority AS ReplacementPriority,
	|	AlternativeMaterials.Package AS Package,
	|	AlternativeMaterials.NumberOfPackages AS NumberOfPackages,
	|	AlternativeMaterials.ScopeMaxPriority AS ScopeMaxPriority,
	|	AlternativeMaterials.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders
	|INTO TableOfMaterials
	|FROM
	|	AlternativeMaterials AS AlternativeMaterials
	|WHERE
	|	AlternativeMaterials.ProductsRole = VALUE(Enum.SubstituteRoles.Material)";
	
	If TypeOf(SelectionOfPermissions) = Type("Map")
	   And Not GetFunctionalOption("DynamicStructureOfProductionOrders")
	   And SelectionOfPermissions.Get("AlternativeMaterials.ReplacementPriority") <> Undefined Then
	
		SelectionOfPermissions.Delete("AlternativeMaterials.ReplacementPriority");
	
	EndIf;
		
	QueryTextSelectionOfPermissions = TMCommonUse.SelectionTextBySelectionCollection(SelectionOfPermissions);
	
	QueryTextMaterialsAndPermissions = StrReplace(
		QueryTextMaterialsAndPermissions, "&SelectionOfPermissions", QueryTextSelectionOfPermissions);
	
	QueryTextMaterialsAndPermissions = StrReplace(
		QueryTextMaterialsAndPermissions, "&TextReplacementPriority", ReplacementPriorityTextField());
	
	QueryTextArray = New Array; 
	QueryTextArray.Add(QueryTextGoods);
	QueryTextArray.Add(QueryTextMaterialsAndPermissions);
	
	Return StrConcat(QueryTextArray, Common.QueryBatchSeparator());

EndFunction

// Returns the Query Text with temp tables defining the selection of analogues (set to set, list of interchangeable ones) 
//
// Parameters:
//  SelectionParameters_2 - Structure, Undefined - Contains:
//                      * ToSelectInterchangeableAnalogues - Boolean - determines the need for the selection of interchangeable analogues.
//                      * ConsiderManyToMany - Boolean - determines the need to obtain available many-to-many permissions.
//                      * TempTableName - String - the name of the temporary table for placing the result.
//
// Returns:
//  String - query text.
//
Function QueryTextTableConnectionsOfMaterialsAndAnalogues(SelectionParameters_2 = Undefined) Export
	
	ToSelectInterchangeableAnalogues = SelectionParameters_2 <> Undefined 
						   And SelectionParameters_2.Property("ToSelectInterchangeableAnalogues") 
						   And SelectionParameters_2.ToSelectInterchangeableAnalogues;
	
	ConsiderManyToMany = SelectionParameters_2 <> Undefined 
						   And SelectionParameters_2.Property("ConsiderManyToMany") 
						   And SelectionParameters_2.ConsiderManyToMany;
	
	If SelectionParameters_2 <> Undefined
	   And SelectionParameters_2.Property("TempTableName") Then
		TempTableName = SelectionParameters_2.TempTableName;
	Else
		TempTableName = "";
	EndIf;
	
	QueryTextTableOfMaterialsAndAnalogues = 
	"SELECT
	|	AlternativeMaterials.Resolution AS Resolution,
	|	AlternativeMaterials.Period AS Period,
	|	AlternativeMaterials.LineNumber AS LineNumber,
	|	AlternativeMaterials.Products AS Products,
	|	AlternativeMaterials.Characteristic AS Characteristic,
	|	AlternativeMaterials.ProductsRole AS ProductsRole,
	|	AlternativeMaterials.ReplacementPriority AS ReplacementPriority,
	|	AlternativeMaterials.Package AS Package,
	|	AlternativeMaterials.NumberOfPackages AS NumberOfPackages,
	|	AlternativeMaterials.ScopeMaxPriority AS ScopeMaxPriority,
	|	AlternativeMaterials.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
	|	AlternativeMaterials.Ref AS Ref,
	|	NOT ManyToManyPermissions.Resolution IS NULL AS ManyToMany
	|INTO TableOfMaterialsAndAnaloguesWithLinks
	|FROM
	|	AlternativeMaterials AS AlternativeMaterials
	|		LEFT JOIN ManyToManyPermissions AS ManyToManyPermissions
	|		ON AlternativeMaterials.Resolution = ManyToManyPermissions.Resolution
	|WHERE
	|	&ManyToManyCondition
	|
	|INDEX BY
	|	Resolution,
	|	Ref";
	
	QueryTextTableOfMaterialsAndAnalogues = StrReplace(
		QueryTextTableOfMaterialsAndAnalogues,
		"&ManyToManyCondition",
		?(ConsiderManyToMany, "TRUE", "ManyToManyPermissions.Resolution IS NULL"));
	
	If ToSelectInterchangeableAnalogues Then
	
		TextInterchangeableCounterparts = 
		"SELECT
		|	TableOfMaterialsAndAnalogues.Resolution AS Resolution,
		|	TableOfMaterialsAndAnalogues.Period AS Period,
		|	TableOfMaterialsAndAnalogues.LineNumber AS LineNumber,
		|	TableOfMaterialsAndAnalogues.Products AS Products,
		|	TableOfMaterialsAndAnalogues.Characteristic AS Characteristic,
		|	TableOfMaterialsAndAnalogues.ProductsRole AS ProductsRole,
		|	TableOfMaterialsAndAnalogues.ReplacementPriority AS ReplacementPriority,
		|	TableOfMaterialsAndAnalogues.Package AS Package,
		|	TableOfMaterialsAndAnalogues.NumberOfPackages AS NumberOfPackages,
		|	TableOfMaterialsAndAnalogues.ScopeMaxPriority AS ScopeMaxPriority,
		|	TableOfMaterialsAndAnalogues.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
		|	TableOfMaterialsAndAnalogues.Ref AS Ref,
		|	TableOfMaterialsAndAnalogues.ManyToMany AS ManyToMany
		|INTO InterchangeableSubstitutes
		|FROM
		|	TableOfMaterialsAndAnaloguesWithLinks AS TableOfMaterialsAndAnalogues
		|WHERE
		|	TableOfMaterialsAndAnalogues.ProductsRole = VALUE(Enum.SubstituteRoles.InterchangeableSubstitute)
		|
		|INDEX BY
		|	Resolution,
		|	Products,
		|	Characteristic,
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InterchangeableSubstitutes.Resolution AS Resolution,
		|	InterchangeableSubstitutes.Period AS Period,
		|	InterchangeableSubstitutes.LineNumber AS LineNumber,
		|	InterchangeableSubstitutes.Products AS Material,
		|	InterchangeableSubstitutes.Characteristic AS MaterialCharacteristics,
		|	InterchangeableAnaloguesSupplement.Products AS Substitute,
		|	InterchangeableAnaloguesSupplement.Characteristic AS AnalogCharacteristics,
		|	InterchangeableSubstitutes.ProductsRole AS ProductsRole,
		|	InterchangeableSubstitutes.ReplacementPriority AS ReplacementPriority,
		|	InterchangeableSubstitutes.Package AS Package,
		|	InterchangeableSubstitutes.NumberOfPackages AS NumberOfPackages,
		|	InterchangeableSubstitutes.ScopeMaxPriority AS ScopeMaxPriority,
		|	InterchangeableSubstitutes.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
		|	InterchangeableSubstitutes.Ref AS Ref,
		|	InterchangeableSubstitutes.ManyToMany AS ManyToMany,
		|	RECORDAUTONUMBER() AS ConnectionKey
		|INTO InterchangeableCounterpartsWithCommunicationKeys
		|FROM
		|	InterchangeableSubstitutes AS InterchangeableSubstitutes
		|		INNER JOIN InterchangeableSubstitutes AS InterchangeableAnaloguesSupplement
		|		ON InterchangeableSubstitutes.Resolution = InterchangeableAnaloguesSupplement.Resolution
		|			AND InterchangeableSubstitutes.Ref = InterchangeableAnaloguesSupplement.Ref
		|			AND (NOT(InterchangeableSubstitutes.Products = InterchangeableAnaloguesSupplement.Products
		|					AND InterchangeableSubstitutes.Characteristic = InterchangeableAnaloguesSupplement.Characteristic))
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Goods AS Goods
		|			WHERE
		|				Goods.Products = InterchangeableSubstitutes.Products
		|				AND Goods.Characteristic = InterchangeableSubstitutes.Characteristic)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InterchangeableCounterpartsWithCommunicationKeys.Resolution AS Resolution,
		|	InterchangeableCounterpartsWithCommunicationKeys.Period AS Period,
		|	InterchangeableCounterpartsWithCommunicationKeys.LineNumber AS LineNumber,
		|	InterchangeableCounterpartsWithCommunicationKeys.Material AS Products,
		|	InterchangeableCounterpartsWithCommunicationKeys.MaterialCharacteristics AS Characteristic,
		|	InterchangeableCounterpartsWithCommunicationKeys.ProductsRole AS ProductsRole,
		|	InterchangeableCounterpartsWithCommunicationKeys.ReplacementPriority AS ReplacementPriority,
		|	InterchangeableCounterpartsWithCommunicationKeys.Package AS Package,
		|	InterchangeableCounterpartsWithCommunicationKeys.NumberOfPackages AS NumberOfPackages,
		|	InterchangeableCounterpartsWithCommunicationKeys.ScopeMaxPriority AS ScopeMaxPriority,
		|	InterchangeableCounterpartsWithCommunicationKeys.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
		|	InterchangeableCounterpartsWithCommunicationKeys.Ref AS Ref,
		|	FALSE AS ManyToMany,
		|	InterchangeableCounterpartsWithCommunicationKeys.ConnectionKey AS ConnectionKey,
		|	FALSE AS ThisIsASubstitute
		|INTO ConnectionsOfMaterialsAndAnalogues
		|FROM
		|	InterchangeableCounterpartsWithCommunicationKeys AS InterchangeableCounterpartsWithCommunicationKeys
		|
		|UNION ALL
		|
		|SELECT
		|	InterchangeableCounterpartsWithCommunicationKeys.Resolution AS Resolution,
		|	InterchangeableCounterpartsWithCommunicationKeys.Period AS Period,
		|	InterchangeableCounterpartsWithCommunicationKeys.LineNumber AS LineNumber,
		|	InterchangeableCounterpartsWithCommunicationKeys.Substitute AS Products,
		|	InterchangeableCounterpartsWithCommunicationKeys.AnalogCharacteristics AS Characteristic,
		|	InterchangeableCounterpartsWithCommunicationKeys.ProductsRole AS ProductsRole,
		|	InterchangeableCounterpartsWithCommunicationKeys.ReplacementPriority AS ReplacementPriority,
		|	InterchangeableCounterpartsWithCommunicationKeys.Package AS Package,
		|	InterchangeableCounterpartsWithCommunicationKeys.NumberOfPackages AS NumberOfPackages,
		|	InterchangeableCounterpartsWithCommunicationKeys.ScopeMaxPriority AS ScopeMaxPriority,
		|	InterchangeableCounterpartsWithCommunicationKeys.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
		|	InterchangeableCounterpartsWithCommunicationKeys.Ref AS Ref,
		|	FALSE AS ManyToMany,
		|	InterchangeableCounterpartsWithCommunicationKeys.ConnectionKey AS ConnectionKey,
		|	TRUE AS ThisIsASubstitute
		|FROM
		|	InterchangeableCounterpartsWithCommunicationKeys AS InterchangeableCounterpartsWithCommunicationKeys";
		
	Else
		
		TextInterchangeableCounterparts = 
		"SELECT TOP 0
		|	UNDEFINED AS Resolution,
		|	UNDEFINED AS Period,
		|	UNDEFINED AS LineNumber,
		|	UNDEFINED AS Products,
		|	UNDEFINED AS Characteristic,
		|	UNDEFINED AS ProductsRole,
		|	UNDEFINED AS ReplacementPriority,
		|	UNDEFINED AS Package,
		|	UNDEFINED AS NumberOfPackages,
		|	UNDEFINED AS ScopeMaxPriority,
		|	UNDEFINED AS UseItForAutocorrectInOrders,
		|	UNDEFINED AS Ref,
		|	UNDEFINED AS ManyToMany,
		|	UNDEFINED AS ConnectionKey,
		|	UNDEFINED AS ThisIsASubstitute
		|INTO ConnectionsOfMaterialsAndAnalogues";
	
	EndIf;
		
	Separator = TMCommonUse.QuerySeparatorInJoin();
	
	TextAvailablePermissionsSet = 
	"SELECT
	|	TableOfMaterialsAndAnalogues.Resolution,
	|	TableOfMaterialsAndAnalogues.Period,
	|	TableOfMaterialsAndAnalogues.LineNumber,
	|	TableOfMaterialsAndAnalogues.Products,
	|	TableOfMaterialsAndAnalogues.Characteristic,
	|	TableOfMaterialsAndAnalogues.ProductsRole,
	|	TableOfMaterialsAndAnalogues.ReplacementPriority,
	|	TableOfMaterialsAndAnalogues.Package,
	|	TableOfMaterialsAndAnalogues.NumberOfPackages,
	|	TableOfMaterialsAndAnalogues.ScopeMaxPriority,
	|	TableOfMaterialsAndAnalogues.UseItForAutocorrectInOrders,
	|	TableOfMaterialsAndAnalogues.Ref,
	|	TableOfMaterialsAndAnalogues.ManyToMany,
	|	0,
	|	TableOfMaterialsAndAnalogues.ProductsRole = VALUE(Enum.SubstituteRoles.Substitute)
	|FROM
	|	TableOfMaterialsAndAnaloguesWithLinks AS TableOfMaterialsAndAnalogues
	|WHERE
	|	TableOfMaterialsAndAnalogues.ProductsRole <> VALUE(Enum.SubstituteRoles.InterchangeableSubstitute)
	|	AND &ManyToManyCondition";
	
	ManyToManyCondition = 
	"TRUE IN
	|	(SELECT TOP 1
	|		TRUE
	|	FROM
	|		AvailableManyToManyPermissions AS AvailableManyToManyPermissions
	|	WHERE
	|		AvailableManyToManyPermissions.Resolution = TableOfMaterialsAndAnalogues.Resolution
	|		AND AvailableManyToManyPermissions.Ref = TableOfMaterialsAndAnalogues.Ref
	|		AND TableOfMaterialsAndAnalogues.ManyToMany
	|
	|	UNION ALL
	|
	|	SELECT TOP 1
	|		TRUE
	|	FROM
	|		AlternativeMaterials AS AlternativeMaterials
	|	WHERE
	|		AlternativeMaterials.Resolution = TableOfMaterialsAndAnalogues.Resolution
	|		AND NOT TableOfMaterialsAndAnalogues.ManyToMany)";
	
	TextAvailablePermissionsSet = StrReplace(
		TextAvailablePermissionsSet,
		"&ManyToManyCondition",
		?(ConsiderManyToMany, ManyToManyCondition, "NOT TableOfMaterialsAndAnalogues.ManyToMany"));
		
	TextInterchangeableCounterparts = StrReplace(
		TextInterchangeableCounterparts,
		"INTO ConnectionsOfMaterialsAndAnalogues",
		?(IsBlankString(TempTableName), "", StrTemplate("INTO %1", TempTableName)));
	
	QueryTextArray = New Array;
	QueryTextArray.Add(TextInterchangeableCounterparts);
	QueryTextArray.Add(Separator);
	QueryTextArray.Add(TextAvailablePermissionsSet);
		
	QueryTextConnectionsOfMaterialsAndAnalogues = StrConcat(QueryTextArray);
	
	QueryTextArray.Clear();
	
	QueryTextArray.Add(QueryTextTableOfMaterialsAndAnalogues);
	QueryTextArray.Add(QueryTextConnectionsOfMaterialsAndAnalogues);
	
	Return StrConcat(QueryTextArray, Common.QueryBatchSeparator());

EndFunction

// Returns the Query Text with temp tables defining the order of application of analogues in relation to materials. 
//
// Parameters:
//  SelectionParameters_2 - Structure, Undefined - Contains:
//                      * ToSelectInterchangeableAnalogues - Boolean - determines the need for the selection of interchangeable analogues.
//                      * GoodsTogetherWithParameters - Boolean - checks whether the parameters are passed in the same table with the products.
//                      * ConsiderManyToMany - Boolean - determines the need to obtain available many-to-many permissions.
//                      * SelectionOfPermissions - Map of KeyAndValue - collection where: 
//                          	** Key - String - parameter name.
//                          	** Value - String - parameter value.
//                      * TempTableName - String - the name of the temporary table for placing the result.
//
// Returns:
//  String - query text.
//
Function QueryTextDataOfMaterialsAndAnalogues(SelectionParameters_2) Export
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(QueryTextGoodsWithPermissions(SelectionParameters_2));
	ArrayOfTexts.Add(QueryTextAvailableManyToManyPermissions(SelectionParameters_2));
	ArrayOfTexts.Add(QueryTextTableConnectionsOfMaterialsAndAnalogues(SelectionParameters_2));
	
	Return StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	
EndFunction

// In the current version, the selection of directive substitutions is not supported.
//
// Parameters:
//  SelectionParameters_2 - Undefined
//
// Returns:
//  String - query text.
//
Function QueryTextDirectiveSubstitutions(SelectionParameters_2 = Undefined) Export
	
	Text = 
	"SELECT TOP 0
	|	VALUE(Document.EngineeringChangeOrder.EmptyRef) AS Resolution,
	|	DATETIME(1, 1, 1) AS Period,
	|	1 AS LineNumber,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Enum.SubstituteRoles.EmptyRef) AS ProductsRole,
	|	VALUE(Enum.RulesOfReplacingWithSubstitutes.EmptyRef) AS ReplacementPriority,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	1 AS NumberOfPackages,
	|	0 AS ScopeMaxPriority,
	|	FALSE AS UseItForAutocorrectInOrders,
	|	0 AS Ref,
	|	FALSE AS ManyToMany,
	|	0 AS ConnectionKey,
	|	FALSE AS ThisIsASubstitute
	|INTO TableDirectiveSubstitutions";
	
	If SelectionParameters_2 <> Undefined
	   And SelectionParameters_2.Property("TempTableName") Then
		TempTableName = SelectionParameters_2.TempTableName;
	Else
		TempTableName = "";
	EndIf;
	
	Text = StrReplace(
		Text,
		"INTO TableDirectiveSubstitutions",
		?(IsBlankString(TempTableName), "", StrTemplate("INTO %1", TempTableName)));
	
	Return Text;
	
EndFunction

#EndRegion

// In the current version, directive substitutions are not supported.
//
// Returns:
//  Boolean - query text.
//
Function UseDirectiveSubstitutions() Export

	Return False;

EndFunction

#EndRegion

#Region Private

// Returns a table (table structure) of parameters required for selecting analogs
//
// Parameters:
//  SourceType - TypeDescription - LongDesc
//  
// Returns:
//  ValueTable - LongDesc:
//   * PermissionValidityDate - Date - date of validity of the permits
//   * Ref - DocumentRef - attribution
//   * ProductionOrder - DocumentRef.ProductionOrder2_2 -
//   * SalesOrder - DocumentRef.SalesOrder -
//   * BillOfMaterials - CatalogRef.BillsOfMaterials -
//   * Stage - CatalogRef.ProductionStages - 
//   * Product - CatalogRef.Products -
//   * ItemVariantOfProduct - CatalogRef.ItemsCharacteristics -
//   * Department - CatalogRef.BusinessStructure -
//   * LineOfBusiness - CatalogRef.LinesOfBusiness -
//
Function TableOfAnalogParameters(SourceType) Export

	Types = New Array;
	Types.Add(Type("DocumentRef.ProductionOrder2_2"));
	
	ParametersTable = New ValueTable;
	ParametersTable.Columns.Add("PermissionValidityDate", Common.DateTypeDetails(DateFractions.DateTime));
	ParametersTable.Columns.Add("Ref", SourceType);
	ParametersTable.Columns.Add("ProductionOrder", New TypeDescription(Types));
	ParametersTable.Columns.Add("SalesOrder", New TypeDescription("DocumentRef.SalesOrder"));	
	ParametersTable.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	ParametersTable.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages"));
	ParametersTable.Columns.Add("Product", New TypeDescription("CatalogRef.Products"));	
	ParametersTable.Columns.Add("ItemVariantOfProduct", New TypeDescription("CatalogRef.ItemsCharacteristics"));	
	ParametersTable.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));	
	ParametersTable.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	
	Return ParametersTable;
	
EndFunction

// Complements the inventory distribution table (See ProvisionInDocumentsServer.InventoryAllocationForDocumentBeingEdited)
//
Procedure SupplementInventoryDistributionTable(AddressInStorage, InventoryTable)
	
	Query = New Query;
	Texts = New Array();
	QueryText =
	"SELECT DISTINCT
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.WithAssignment AS WithAssignment
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	WithAssignment,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryTable.InventoryState AS InventoryState,
	|	InventoryTable.DemandCharacteristic AS DemandCharacteristic,
	|	InventoryTable.Products AS Products,
	|	InventoryTable.Characteristic AS Characteristic,
	|	InventoryTable.Warehouse AS Warehouse,
	|	CASE
	|		WHEN InventoryTable.Purpose = UNDEFINED
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE InventoryTable.Purpose
	|	END AS Purpose,
	|	InventoryTable.Purpose = UNDEFINED
	|		OR InventoryTable.Purpose <> VALUE(Catalog.Assignments.EmptyRef) AS WithAssignment,
	|	InventoryTable.Count AS Count
	|INTO InventoryTable
	|FROM
	|	&InventoryTable AS InventoryTable
	|INDEX BY
	|	Products, Characteristic, Purpose, WithAssignment, Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.Purpose AS Purpose
	|INTO SelectionForBalances
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.WithAssignment
	|		AND TableOfGoods.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|FROM
	|	TableOfGoods AS TableOfGoods
	|INDEX BY
	|	Products, Characteristic, Purpose, Warehouse";
	Texts.Add(QueryText);
	
	QueryText = 
		"SELECT
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
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|				SELECT
		|					SelectionForBalances.Products AS Products,
		|					SelectionForBalances.Characteristic AS Characteristic,
		|					SelectionForBalances.Warehouse AS Warehouse,
		|					SelectionForBalances.Purpose AS Purpose
		|				FROM
		|					SelectionForBalances AS SelectionForBalances)) AS Inventories";
	Texts.Add(QueryText);
	
	QueryText = 
		"SELECT
		|	Calculation.Products AS Products,
		|	Calculation.Characteristic AS Characteristic,
		|	Calculation.Warehouse AS Warehouse,
		|	Calculation.Purpose AS Purpose,
		|	Calculation.QuantityForShipAction AS Count
		|INTO BalanceTable
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	Texts.Add(QueryText);
	
	QueryText =
	"SELECT
	|	InventoryTable.Products AS Products,
	|	InventoryTable.Characteristic AS Characteristic,
	|	InventoryTable.Warehouse AS Warehouse,
	|	InventoryTable.Purpose AS Purpose,
	|	InventoryTable.WithAssignment AS WithAssignment,
	|	InventoryTable.InventoryState AS InventoryState,
	|	InventoryTable.DemandCharacteristic AS DemandCharacteristic,
	|	InventoryTable.InventoryState = UNDEFINED AS ThisIsRemainder,
	|	TRUE AS ThisIsDocumentWarehouse,
	// The Balances of the warehouse were obtained from the inventory table.
	|	SUM(InventoryTable.Count) AS Count
	|INTO InventoryTableIsTemporary
	|FROM
	|	InventoryTable AS InventoryTable
	|
	|GROUP BY
	|	InventoryTable.Products,
	|	InventoryTable.Characteristic,
	|	InventoryTable.Warehouse,
	|	InventoryTable.Purpose,
	|	InventoryTable.WithAssignment,
	|	InventoryTable.InventoryState,
	|	InventoryTable.DemandCharacteristic,
	|	InventoryTable.InventoryState = UNDEFINED
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.WithAssignment AS WithAssignment,
	|	UNDEFINED AS InventoryState,
	|	UNDEFINED AS DemandCharacteristic,
	|	TRUE AS ThisIsRemainder,
	|	FALSE AS ThisIsDocumentWarehouse,
	// Balances were received for all warehouses from the security registers, except for the warehouse from the goods table.
	|	SUM(InventoryAllocation.Count) AS Count
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN BalanceTable AS InventoryAllocation
	|		ON TableOfGoods.Products = InventoryAllocation.Products
	|			AND TableOfGoods.Characteristic = InventoryAllocation.Characteristic
	|			AND TableOfGoods.Purpose = InventoryAllocation.Purpose
	|			AND (TableOfGoods.WithAssignment
	|					AND TableOfGoods.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|				OR NOT TableOfGoods.WithAssignment)
	|			AND TableOfGoods.Warehouse <> InventoryAllocation.Warehouse
	|WHERE
	// There is a warehouse from the item table in the inventory table
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InventoryTable AS InventoryTable
	|			WHERE
	|				InventoryTable.Products = TableOfGoods.Products
	|				AND InventoryTable.Characteristic = TableOfGoods.Characteristic
	|				AND InventoryTable.Purpose = TableOfGoods.Purpose
	|				AND InventoryTable.WithAssignment = TableOfGoods.WithAssignment
	|				AND InventoryTable.Warehouse = TableOfGoods.Warehouse)
	|	AND InventoryAllocation.Count IS NOT NULL 
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.WithAssignment
	|
	|HAVING
	|	SUM(InventoryAllocation.Count) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.WithAssignment AS WithAssignment,
	|	UNDEFINED AS InventoryState,
	|	UNDEFINED AS DemandCharacteristic,
	|	TRUE AS ThisIsRemainder,
	|	CASE
	|		WHEN TableOfGoods.Warehouse = InventoryAllocation.Warehouse
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsDocumentWarehouse,
	// Balances for all warehouses from the security registers were received.
	|	SUM(InventoryAllocation.Count) AS Count
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN BalanceTable AS InventoryAllocation
	|		ON TableOfGoods.Products = InventoryAllocation.Products
	|			AND TableOfGoods.Characteristic = InventoryAllocation.Characteristic
	|			AND TableOfGoods.Purpose = InventoryAllocation.Purpose
	|			AND (TableOfGoods.WithAssignment
	|					AND TableOfGoods.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|				OR NOT TableOfGoods.WithAssignment)
	|WHERE
	// The warehouse from the item table is missing from the inventory table
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InventoryTable AS InventoryTable
	|				WHERE
	|					InventoryTable.Products = TableOfGoods.Products
	|					AND InventoryTable.Characteristic = TableOfGoods.Characteristic
	|					AND InventoryTable.Purpose = TableOfGoods.Purpose
	|					AND InventoryTable.WithAssignment = TableOfGoods.WithAssignment
	|					AND InventoryTable.Warehouse = TableOfGoods.Warehouse)
	|	AND InventoryAllocation.Count IS NOT NULL 
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Warehouse,
	|	CASE
	|		WHEN TableOfGoods.Warehouse = InventoryAllocation.Warehouse
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.WithAssignment
	|
	|HAVING
	|	SUM(InventoryAllocation.Count) > 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ThisIsRemainder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryTableIsTemporary.Products AS Products,
	|	InventoryTableIsTemporary.Characteristic AS Characteristic,
	|	InventoryTableIsTemporary.Warehouse AS Warehouse,
	|	InventoryTableIsTemporary.Purpose AS Purpose,
	|	InventoryTableIsTemporary.WithAssignment AS WithAssignment,
	|	InventoryTableIsTemporary.InventoryState AS InventoryState,
	|	InventoryTableIsTemporary.DemandCharacteristic AS DemandCharacteristic,
	|	InventoryTableIsTemporary.ThisIsRemainder AS ThisIsRemainder,
	|	InventoryTableIsTemporary.ThisIsDocumentWarehouse AS ThisIsDocumentWarehouse,
	|	InventoryTableIsTemporary.Count AS Count
	|FROM
	|	InventoryTableIsTemporary AS InventoryTableIsTemporary
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryTable.Products AS Products,
	|	InventoryTable.Characteristic AS Characteristic,
	|	InventoryTable.Warehouse AS Warehouse,
	|	InventoryTable.Purpose AS Purpose,
	|	InventoryTable.WithAssignment AS WithAssignment,
	|	UNDEFINED AS InventoryState,
	|	UNDEFINED AS DemandCharacteristic,
	|	TRUE AS ThisIsRemainder,
	|	TRUE AS ThisIsDocumentWarehouse,
	|	0 AS Count
	|FROM
	|	InventoryTable AS InventoryTable
	|WHERE
	|	NOT TRUE IN
	|				(SELECT
	|					TRUE
	|				FROM
	|					InventoryTableIsTemporary AS InventoryTableIsTemporary
	|				WHERE
	|					InventoryTableIsTemporary.Products = InventoryTable.Products
	|					AND InventoryTableIsTemporary.Characteristic = InventoryTable.Characteristic
	|					AND InventoryTableIsTemporary.Warehouse = InventoryTable.Warehouse
	|					AND InventoryTableIsTemporary.Purpose = InventoryTable.Purpose
	|					AND InventoryTableIsTemporary.ThisIsRemainder)";
	Texts.Add(QueryText);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.SetParameter("TableOfGoods", GetFromTempStorage(AddressInStorage)); 
	Query.SetParameter("InventoryTable", InventoryTable);
	
	InventoryTable = Query.Execute().Unload();
	
EndProcedure

Function CrawlingTableOfMaterials(TableOfPermissionsByPriority, AssignmentsTable, SelectionByPermission, ListBasedReplacement)
	
	CrawlTable = New ValueTable;
	CrawlTable.Columns.Add("FilterParameters", New TypeDescription("Structure"));
	CrawlTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	
	If ListBasedReplacement Then
		
		RowsArray = TMCommonUse.FindRowsWithPreservingOrder(TableOfPermissionsByPriority, SelectionByPermission);
		For Each SpecificationRow In RowsArray Do
		
			FilterLineNumber = New Structure("Resolution, Ref, LineNumber");
			FillPropertyValues(FilterLineNumber, SpecificationRow);
			NewRow = CrawlTable.Add();
			NewRow.FilterParameters = FilterLineNumber;
			NewRow.Purpose = SpecificationRow.Purpose;
		
		EndDo;
		
	Else	
		
		AssignmentsArray = AssignmentsTable.FindRows(SelectionByPermission);
		
		For Each SpecificationRow In AssignmentsArray Do
			
			If SpecificationRow.WithAssignment Then
				
				SelectionAppointmentIsSeparate = New Structure;
				SelectionAppointmentIsSeparate.Insert("Resolution");
				SelectionAppointmentIsSeparate.Insert("Ref");
				SelectionAppointmentIsSeparate.Insert("Purpose");
				SelectionAppointmentIsSeparate.Insert("WithAssignment");
				FillPropertyValues(SelectionAppointmentIsSeparate, SelectionByPermission);
				SelectionAppointmentIsSeparate.Purpose = SpecificationRow.Purpose;
				SelectionAppointmentIsSeparate.WithAssignment = True;
				
				NewRow = CrawlTable.Add(); // the first iteration is separate materials
				NewRow.FilterParameters = SelectionAppointmentIsSeparate;
				NewRow.Purpose = SpecificationRow.Purpose;	
			
			EndIf;
			
			FilterPurpose = New Structure("Resolution, Ref, Purpose");
			FillPropertyValues(FilterPurpose, SelectionByPermission);
			FilterPurpose.Purpose = SpecificationRow.Purpose;
			
			NewRow = CrawlTable.Add(); // the second iteration - materials for the intended purpose
			NewRow.FilterParameters = FilterPurpose;
			NewRow.Purpose = SpecificationRow.Purpose;
			
			If SpecificationRow.WithAssignment Then
				
				SelectionAppointmentIsNotIsolated = New Structure;
				SelectionAppointmentIsNotIsolated.Insert("Resolution");
				SelectionAppointmentIsNotIsolated.Insert("Ref");
				SelectionAppointmentIsNotIsolated.Insert("Purpose");
				SelectionAppointmentIsNotIsolated.Insert("WithAssignment");
				FillPropertyValues(SelectionAppointmentIsNotIsolated, SelectionByPermission);
				SelectionAppointmentIsNotIsolated.Purpose = SpecificationRow.Purpose;
				SelectionAppointmentIsNotIsolated.WithAssignment = False;
				
				NewRow = CrawlTable.Add(); // the third iteration is non-isolated materials
				NewRow.FilterParameters = SelectionAppointmentIsNotIsolated;
				NewRow.Purpose = SpecificationRow.Purpose;
			
			EndIf;
			
		EndDo;
		
		NewRow = CrawlTable.Add(); // the last iteration is all the remaining materials
		NewRow.FilterParameters = SelectionByPermission;
		
	EndIf;
	
	Return CrawlTable;

EndFunction

// Returns the text of the replacement priority field depending on the function option.
//
// Returns:
//  String - text of the field.
//
Function ReplacementPriorityTextField()
	
	If GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		TextReplacementPriority = "AlternativeMaterials.ReplacementPriority";
	Else
		TextReplacementPriority = "VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials)";
	EndIf;
	
	Return TextReplacementPriority;
	
EndFunction

#EndRegion