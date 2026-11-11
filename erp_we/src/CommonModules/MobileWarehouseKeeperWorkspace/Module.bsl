
#Region Public

// The procedure is triggered only on an offline server instead of a standard serversystem.Setting
// Session parameters sets only the Current User session parameter.
//
// Parameters:
//  SessionParametersNames - Array of String
//                        - Undefined - names of session parameters to initialize.
//                                         An array of set session parameter IDs
//                                         to be initialized if the handler is called
//                                         before using uninitialized session parameters.
//                                         Undefined if the event handler is called by the system at the start of the session.
//
// Returns:
//  Array of String - names of session parameters whose values were successfully set.
//
Function SessionParametersSetting(SessionParametersNames) Export
	
	SpecifiedParameters = New Array;
	
	If SessionParametersNames <> Undefined
		And SessionParametersNames.Find("CurrentUser") <> Undefined Then
		
		ServiceUsersSettingSessionParameters("CurrentUser", SpecifiedParameters);
	EndIf;
	
	Return SpecifiedParameters;
	
EndFunction

// See ProductsServer.FillInStatusesForSpecifyingSeries
//
Procedure FillInStatusesForSpecifyingSeries(Object,
											SeriesSpecificationParameters,
											RowsOfProductsToProcess = Undefined,
											SeriesRowsToProcess = Undefined) Export
	
	If Not (SeriesSpecificationParameters.ProductInHeader
		Or Object[SeriesSpecificationParameters.NameTSGoods].Count() <> 0 ) Then
		Return;
	EndIf;
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		
		If GetFunctionalOption("UseItemsBatch") Then
			If SeriesSpecificationParameters.ProductInHeader Then
				Object.BatchesIndicationStatus = 0;	
			Else
				For Each RowOfTables In Object[SeriesSpecificationParameters.NameTSGoods] Do
					If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
						RowOfTables.BatchesIndicationStatus = 0;
					Else
						For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
							RowOfTables[NameOfStatusField] = 0;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		Return;
	EndIf;
	
	VHFWarehouses = SeriesSpecificationParameters.LinkFields.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined
		Or SeriesSpecificationParameters.AdditionalFieldNames.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined;
	
	If Not VHFWarehouses
		And SeriesSpecificationParameters.WarehouseFieldName <> Undefined Then
		
		If SeriesSpecificationParameters.NameOfSenderWarehouseField <> Undefined
			And SeriesSpecificationParameters.NameOfRecipientWarehouseField <> Undefined Then
			Warehouse = New Structure("Sender,Recipient");
			Warehouse.Sender = Object[SeriesSpecificationParameters.NameOfSenderWarehouseField];
			Warehouse.Recipient  = Object[SeriesSpecificationParameters.NameOfRecipientWarehouseField];
		Else
			Warehouse = Object[SeriesSpecificationParameters.WarehouseFieldName];
		EndIf;
		
	Else
		Warehouse = Undefined;
	EndIf;
	
	If SeriesSpecificationParameters.ProductInHeader Then
		
		TableOfGoods = New ValueTable;
		TableOfGoods.Columns.Add("Products",New TypeDescription("CatalogRef.Products"));
		TableOfGoods.Columns.Add("Characteristic",New TypeDescription("CatalogRef.ItemsCharacteristics"));
		TableOfGoods.Columns.Add("Series",New TypeDescription("CatalogRef.ItemsBatches"));
		TableOfGoods.Columns.Add("Count",DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
		TableOfGoods.Columns.Add("LineNumber",New TypeDescription("Number",New NumberQualifiers(5,0,AllowedSign.Nonnegative)));
		
		If ValueIsFilled(SeriesSpecificationParameters.TSSeriesName) Then
			TableOfSeries = Object[SeriesSpecificationParameters.TSSeriesName];
		Else
			TableOfSeries = New ValueTable;
			TableOfSeries.Columns.Add("Products",New TypeDescription("CatalogRef.Products"));
			TableOfSeries.Columns.Add("Characteristic",New TypeDescription("CatalogRef.ItemsCharacteristics"));
			TableOfSeries.Columns.Add("Series",New TypeDescription("CatalogRef.ItemsBatches"));
			TableOfSeries.Columns.Add("Purpose",New TypeDescription("CatalogRef.Assignments"));
			TableOfSeries.Columns.Add("Count",DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
			
			RowSeries = TableOfSeries.Add();
			FillPropertyValues(RowSeries, Object);
		EndIf;
		
		CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, TableOfGoods);
		
		RowOfProduct = TableOfGoods.Add();
		FillPropertyValues(RowOfProduct,Object);
		If SeriesSpecificationParameters.ThisIsOrder
			And SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipSetsForDisassembly) <> Undefined
			And Not Object.WithAssignment Then
			// In the order header, when changing the security option, the destination is not cleared,
			//	so for an unsociable shipment, we will clear the destination here.
			RowOfProduct.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		RowOfProduct.LineNumber = 1;
		
		TheStructureOfTheSearch = New Structure("Products, Characteristic, Purpose");
		FillPropertyValues(TheStructureOfTheSearch, RowOfProduct);
		FoundSeriesRows_ = TableOfSeries.FindRows(TheStructureOfTheSearch);
		
		Selection = SelectionFromRequestForCalculatingStatusesForSpecifyingSeries(SeriesSpecificationParameters,
																TableOfGoods,
																TableOfSeries,
																Warehouse,
																,
																FoundSeriesRows_);
		
		If Selection.Next() Then
			
			Object.BatchesIndicationStatus = Selection.BatchesIndicationStatus;
			
			FieldStatuses = New Array;
			FieldStatuses.Add(14);
			FieldStatuses.Add(18);
			FieldStatuses.Add(20);
			
			If FieldStatuses.Find(Selection.BatchesIndicationStatus) = Undefined Then
				Object.Series = Catalogs.ItemsBatches.EmptyRef();
			EndIf;
		EndIf;
	Else
		
		Selection = SelectionFromRequestForCalculatingStatusesForSpecifyingSeries(SeriesSpecificationParameters,
																Object[SeriesSpecificationParameters.NameTSGoods],
																Object[SeriesSpecificationParameters.TSSeriesName],
																Warehouse,
																RowsOfProductsToProcess,
																SeriesRowsToProcess);
		
		While Selection.Next() Do
			RowOfTables = Object[SeriesSpecificationParameters.NameTSGoods][Selection.LineNumber - 1];
			If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
				RowOfTables.BatchesIndicationStatus = Selection.BatchesIndicationStatus;
			Else
				For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
					RowOfTables[NameOfStatusField] = Selection[NameOfStatusField];
				EndDo;
			EndIf;
			
		EndDo;
	EndIf;
	
EndProcedure

// See ProductsServer.SplitProductsByProductLocations
//
Procedure SplitProductsByProductLocations(TabularPartProducts) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Products.Ref AS Products,
	|	PackagesAndUnitsOfMeasure.Ref AS CargoItem,
	|	PackagesAndUnitsOfMeasure.NumberOfPackages AS NumberOfItems
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON (CASE
	|				WHEN Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|					THEN PackagesAndUnitsOfMeasure.Owner = Products.Ref
	|				WHEN Products.PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
	|					THEN PackagesAndUnitsOfMeasure.Owner = Products.PackagingGroup
	|				ELSE FALSE
	|			END)
	|WHERE
	|	Products.Ref IN(&ItemList)
	|	AND NOT PackagesAndUnitsOfMeasure.DeletionMark
	|	AND PackagesAndUnitsOfMeasure.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	TableOfGoods = TabularPartProducts.Unload();
	Query.SetParameter("ItemList", TableOfGoods.UnloadColumn("Products"));
	ProductsAndPackaging = Query.Execute().Unload();
	PackagingProductLocations = ProductsAndPackaging.UnloadColumn("CargoItem");
	
	If ProductsAndPackaging.Count() > 0 Then
		
		TabularPartProducts.Clear();
		
		For Each String In TableOfGoods Do
			If PackagingProductLocations.Find(String.Package) <> Undefined Then
				AddAndFillLine(TabularPartProducts, String);
			Else
				ProductPackages = ProductsAndPackaging.FindRows(New Structure("Products", String.Products));
				If ProductPackages.Count() = 0 Then
					AddAndFillLine(TabularPartProducts, String);
				Else
					For Each StringPacking In ProductPackages Do
						NewRow = AddAndFillLine(TabularPartProducts, String);
						NewRow.NumberOfPackages = NewRow.Count * StringPacking.NumberOfItems;  
						NewRow.Package = StringPacking.CargoItem;
					EndDo;
				EndIf;
			EndIf;
		EndDo;
		
	EndIf;
EndProcedure

// See ProductsServer.CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries
//
Procedure CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, Table, Val Var_Metadata = Undefined, ThisIsSeriesTable = False) Export
	
	If Var_Metadata = Undefined Then
		Var_Metadata = ObjectMetadataByFullName(SeriesSpecificationParameters.FullObjectName);
	EndIf;
	
	If SeriesSpecificationParameters.ProductInHeader Then
		MetadataOfTSProductDetails = Var_Metadata.Attributes;
	Else
		MetadataOfTSProductDetails = Var_Metadata.TabularSections[SeriesSpecificationParameters.NameTSGoods].Attributes;
	EndIf;	
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		If Table.Columns.Find(ArrRow) = Undefined Then
			Table.Columns.Add(ArrRow,MetadataOfTSProductDetails[ArrRow].Type);
		EndIf;
	EndDo;
	
	If ThisIsSeriesTable Then
		Return;
	EndIf;
	
	For Each ArrRow In SeriesSpecificationParameters.AdditionalFieldNames Do
		If Table.Columns.Find(ArrRow) = Undefined Then
			Table.Columns.Add(ArrRow,MetadataOfTSProductDetails[ArrRow].Type);
		EndIf;
	EndDo;

	If SeriesSpecificationParameters.ThisIsOrder Then
		If Table.Columns.Find("Canceled") = Undefined Then
			Table.Columns.Add("Canceled",New TypeDescription("Boolean"));
		EndIf;
		If Table.Columns.Find("SupplyOption") = Undefined Then
			Table.Columns.Add("SupplyOption",New TypeDescription("EnumRef.SupplyOptions"));
		EndIf;
	EndIf;
	
	If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
		If Table.Columns.Find("BatchesIndicationStatus") = Undefined Then
			Table.Columns.Add("BatchesIndicationStatus",New TypeDescription("Number",New NumberQualifiers(2,0,AllowedSign.Nonnegative)));
		EndIf;
	Else
		For Each ArrRow In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
			If Table.Columns.Find(ArrRow) = Undefined Then
				Table.Columns.Add(ArrRow,New TypeDescription("Number",New NumberQualifiers(2,0,AllowedSign.Nonnegative)));
			EndIf;
		EndDo;
	EndIf;

EndProcedure

// See ProductsServer.SelectionFromRequestForCalculatingStatusesForSpecifyingSeries
// 
// Parameters:
//  SeriesSpecificationParameters - Arbitrary
//  GoodsTable - Arbitrary
//  SeriesTable - Arbitrary
//  Warehouse - CatalogRef.Warehouses
//  RowsOfProductsToProcess - Arbitrary
//  SeriesRowsToProcess- Arbitrary
//  ReturnATable - Boolean
//
// Returns:
//  Arbitrary
//  
Function SelectionFromRequestForCalculatingStatusesForSpecifyingSeries(SeriesSpecificationParameters,
													GoodsTable,
													SeriesTable,
													Warehouse, //If the warehouses are in PM, then the parameter is ignored
													RowsOfProductsToProcess = Undefined,
													SeriesRowsToProcess = Undefined,
													ReturnATable = False) Export
	
	ManagerModule = ObjectManagerByFullName(SeriesSpecificationParameters.FullObjectName);
	
	QueryText = ManagerModule.TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters);
	
	Query = New Query;
	Query.Text = QueryText;
	
#If Not MobileStandaloneServer Then
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
#EndIf
	
	If TypeOf(Warehouse) = Type("Structure") Then
		Query.SetParameter("SourceWarehouse", Warehouse.Sender);
		Query.SetParameter("DestinationWarehouse", Warehouse.Recipient);
	Else
		Query.SetParameter("Warehouse", Warehouse);
		Query.SetParameter("SourceWarehouse", Warehouse);
		Query.SetParameter("DestinationWarehouse", Warehouse);
	EndIf;
	
	SetRequestParametersBySpecifyingSeriesParameters(Query,SeriesSpecificationParameters);
	
	If TypeOf(GoodsTable) = Type("ValueTable") Then
		TableProductsQueryParameter = GoodsTable;
	Else
		If RowsOfProductsToProcess <> Undefined Then
			TableProductsQueryParameter = GoodsTable.Unload(RowsOfProductsToProcess);
		Else
			TableProductsQueryParameter = GoodsTable.Unload();
		EndIf;
	EndIf;
	
	If TypeOf(SeriesTable) = Type("ValueTable") Then
		QueryParameterSeriesTable = SeriesTable;
	Else
		If SeriesRowsToProcess <> Undefined Then
			QueryParameterSeriesTable = SeriesTable.Unload(SeriesRowsToProcess);
		Else
			QueryParameterSeriesTable = SeriesTable.Unload();
		EndIf;
	EndIf;
	
 	Query.SetParameter("Goods", TableProductsQueryParameter);
	Query.SetParameter("SetOfSeries", QueryParameterSeriesTable);
	
	SetPrivilegedMode(True); // During the movement of goods, one of the warehouses may not be available to the user
	
	If ReturnATable Then
		Result = Query.Execute().Unload();
	Else
		Result = Query.Execute().Select();
	EndIf;
	
	Return Result;
	
EndFunction

// See TMCommonUse.ObjectMetadataByFullName
//
Function ObjectMetadataByFullName(FullName) Export
	
	NameParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FullName, ".");
	
	MOClass = NameParts[0];
	MetadataObjectName1   = NameParts[1];
	
	If      Upper(MOClass) = "EXCHANGEPLAN" Then
		Return Metadata.ExchangePlans[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CATALOG" Then
		Return Metadata.Catalogs[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "DOCUMENT" Then
		Return Metadata.Documents[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "DOCUMENTJOURNAL" Then
		Return Metadata.DocumentJournals[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "ENUM" Then
		Return Metadata.Enums[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "REPORT" Then
		Return Metadata.Reports[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "DATAPROCESSOR" Then
		Return Metadata.DataProcessors[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Return Metadata.ChartsOfCharacteristicTypes[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CHARTOFACCOUNTS" Then
		Return Metadata.ChartsOfAccounts[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CHARTOFCALCULATIONTYPES" Then
		Return Metadata.ChartsOfCalculationTypes[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "INFORMATIONREGISTER" Then
		Return Metadata.InformationRegisters[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "ACCUMULATIONREGISTER" Then
		Return Metadata.AccumulationRegisters[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "ACCOUNTINGREGISTER" Then
		Return Metadata.AccountingRegisters[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CALCULATIONREGISTER" Then
		Return Metadata.CalculationRegisters[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "BUSINESSPROCESS" Then
		Return Metadata.BusinessProcesses[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "TASK" Then
		Return Metadata.Tasks[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CONSTANT" Then
		Return Metadata.Constants[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "SEQUENCE" Then
		Return Metadata.Sequences[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CommonModule" Then
		Return Metadata.CommonModules[MetadataObjectName1];
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неизвестный тип объекта метаданных (%1)';
				|vi = 'Unknown type of metadata object (%1)';
				|en = 'Unknown type of metadata object (%1)'; fa = 'Unknown type of metadata object (%1)';
				|it = 'Tipo di oggetto di metadati sconosciuto (%1)';
				|pl = 'Nieznany typ obiektu metadanych (%1)';
				|tr = 'Metaveri (%1) nesnesinin bilinmeyen türü'"), MOClass);
	EndIf;
	
EndFunction

// See TMCommonUse.DescriptionOfQuantitativeFieldType
//
Function DescriptionOfQuantitativeFieldType(Val FieldSign = Undefined) Export
	
	If FieldSign = Undefined Then
		FieldSign = AllowedSign.Any;
	EndIf;
	
	Return New TypeDescription("Number", New NumberQualifiers(15, 3, FieldSign));
	
EndFunction

// See ProductsServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object, ObjectManager) Export
	
	AttributesNames = ObjectManager.NamesOfDetailsForFillingInParametersForSpecifyingSeries();
	AttributesValues = ValuesOfDetailsForFillingInParametersForSpecifyingSeries(Object, AttributesNames);
	Return ObjectManager.SeriesSpecificationParameters(AttributesValues);
	
EndFunction

// See WarehousesServer.UseOfSeriesInStock
//
Function UseOfSeriesInStock(Warehouse, WarehouseCanBeGroup) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("UseItemsBatch", False);
	ReturnStructure.Insert("UseCostAccountingByBatches", False);
	
	If Not ValueIsFilled(Warehouse) Then
		Return ReturnStructure;
	EndIf;
	
	If WarehouseCanBeGroup Then
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	MAX(Warehouses.UseItemsBatch) AS UseItemsBatch,
		|	MAX(Warehouses.UseCostAccountingByBatches) AS UseCostAccountingByBatches
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	NOT Warehouses.IsFolder
		|	AND (Warehouses.Ref IN HIERARCHY (&Warehouse)
		|			OR Warehouses.Ref = &Warehouse)
		|
		|HAVING
		|	NOT MAX(Warehouses.UseItemsBatch) IS NULL ";
		
		Query.SetParameter("Warehouse",Warehouse);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			FillPropertyValues(ReturnStructure, Selection);
		EndIf;
		
	Else
		
		FOParameters = New Structure("Warehouse", Warehouse);
		
		ReturnStructure.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse", FOParameters); 
		ReturnStructure.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse", FOParameters);
		
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// See Common.ObjectAttributesValues
//
Function ObjectAttributesValues(Ref, Val Attributes, SelectAllowedItems = False, Val LanguageCode = Undefined) Export
	
	// If the name of the predefined is passed.
	If TypeOf(Ref) = Type("String") Then
		
		FullNameOfPredefinedItem = Ref;
		
		// Calculating a link by the name of a predefined one.
		// - additionally performs metadata validation of the predefined, pre-executed.
		Try
			Ref = PredefinedItem(FullNameOfPredefinedItem);
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai tham số đầu tiên %1 trong hàm %2:
				|%3';
				|ru = 'Неверный первый параметр %1 в функции %2:
				|%3';
				|en = 'Invalid value of the %1 first parameter, function %2:
				|%3.'; fa = 'Invalid value of the %1 first parameter, function %2:
				|%3.';
				|it = 'Primo parametro invalido %1 nella funzione %2:
				|%3';
				|pl = 'Niepoprawny pierwszy parametr %1 w funkcji %2:
				|%3';
				|tr = '%2 işlevinde ilk yanlış geçersiz parametre%1:
				|%3'"), "Ref", "Common.ObjectAttributesValues", 
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndTry;
		
		// Parsing the full name of the predefined.
		FullNameParts1 = StrSplit(FullNameOfPredefinedItem, ".");
		FullMetadataObjectName = FullNameParts1[0] + "." + FullNameParts1[1];
		
		// If the predefined one is not created in the IB, then you need to check access to the object.
		// In other scenarios, access verification is performed at the time of request execution.
		If Ref = Undefined Then 
			ObjectMetadata = MetadataObjectByFullName(FullMetadataObjectName);
			If Not AccessRight("Read", ObjectMetadata) Then 
				Raise(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không đủ quyền để làm việc với bảng ""%1""';
						|ru = 'Недостаточно прав для работы с таблицей ""%1""';
						|en = 'Insufficient rights to access table %1.'; fa = 'Insufficient rights to access table %1.';
						|it = 'Permessi insufficienti per lavorare con la tabella ""%1""';
						|pl = 'Nie wystarczające uprawnienia do pracy z tabelą ""%1""';
						|tr = '""%1"" tablosu ile çalışma hakları yetersiz'"), FullMetadataObjectName),
					ErrorCategory.AccessViolation);
			EndIf;
		EndIf;
		
	Else // If a link is passed.
		
		Try
			FullMetadataObjectName = Ref.Metadata().FullName(); 
		Except
			Raise (StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sai tham số đầu tiên %1 trong hàm %2: 
					|Giá trị phải là tham chiếu hoặc tên của phần tử định trước.';
					|ru = 'Неверный первый параметр %1 в функции %2: 
					|Значение должно быть ссылкой или именем предопределенного элемента.';
					|en = 'Invalid value of the %1 first parameter, function %2:
					|The value must contain predefined item name or reference.'; fa = 'Invalid value of the %1 first parameter, function %2:
					|The value must contain predefined item name or reference.';
					|it = 'Primo parametro invalido %1 nella funzione %2: 
					|Il valore deve essere un collegamento o un nome dell''elemento predefinito.';
					|pl = 'Nieprawidłowy pierwszy parametr %1 w funkcji %2: 
					|- Wartość musi być referencją lub nazwą predefiniowanego elementu.';
					|tr = '%2 işlevinde geçersiz ilk %1parametre: 
					|Değer, bir referans veya önceden tanımlanmış bir öğenin adı olmalıdır.'"), 
				"Ref", "Common.ObjectAttributesValues"),
				ErrorCategory.ConfigurationError);
		EndTry;
		
	EndIf;
	
	// Parsing the details if the second parameter is a string.
	If TypeOf(Attributes) = Type("String") Then
		If IsBlankString(Attributes) Then
			Return New Structure;
		EndIf;
		
		Attributes = StrSplit(Attributes, ",", False);
		For IndexOf = 0 To Attributes.UBound() Do
			Attributes[IndexOf] = TrimAll(Attributes[IndexOf]);
		EndDo;
	EndIf;
	
	MultilingualAttributes = New Map;
	LanguageSuffix = "";
	If ValueIsFilled(LanguageCode) Then
		If SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = CommonModule("NationalLanguageSupportServer");
			LanguageSuffix = ModuleNationalLanguageSupportServer.LanguageSuffix(LanguageCode);
			If ValueIsFilled(LanguageSuffix) Then
				MultilingualAttributes = ModuleNationalLanguageSupportServer.MultilingualObjectAttributes(Ref);
			EndIf;
		EndIf;
	EndIf;
	
	// Bringing the details to a single format.
	FieldsStructure = New Structure;
	If TypeOf(Attributes) = Type("Structure")
		Or TypeOf(Attributes) = Type("FixedStructure") Then
		
		For Each KeyAndValue In Attributes Do
			FieldsStructure.Insert(KeyAndValue.Key, TrimAll(KeyAndValue.Value));
		EndDo;
		
	ElsIf TypeOf(Attributes) = Type("Array")
		Or TypeOf(Attributes) = Type("FixedArray") Then
		
		For Each Attribute In Attributes Do
			Attribute = TrimAll(Attribute);
			Try
				FieldAlias = StrReplace(Attribute, ".", "");
				FieldsStructure.Insert(FieldAlias, Attribute);
			Except 
				// If the alias is not a key.
				
				// Search for field availability errors.
				Result = CheckIfObjectAttributesExist(FullMetadataObjectName, Attributes);
				If Result.Error Then 
					Raise(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Sai tham số thứ hai %1 trong hàm %2: %3';
							|ru = 'Неверный второй параметр %1 в функции %2: %3';
							|en = 'Invalid value of the %1 second parameter, function %2: %3'; fa = 'Invalid value of the %1 second parameter, function %2: %3';
							|it = 'Tipo errato di secondo parametro %1 nella funzione %2: %3';
							|pl = 'Nieprawidłowy drugi parametr %1 w funkcji %2: %3';
							|tr = '%2işlevinde geçersiz ikinci %1 parametre: %3'"),
						"Attributes", "Common.ObjectAttributesValues", Result.ErrorDescription),
						ErrorCategory.ConfigurationError);
				EndIf;
				
				// The error could not be recognized, the primary error was thrown.
				Raise;
			
			EndTry;
		EndDo;
	Else
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai kiểu tham số thứ hai %1 trong hàm %2: %3.';
				|ru = 'Неверный тип второго параметра %1 в функции %2: %3.';
				|en = 'Invalid type of the second parameter %1 in function %2: %3.'; fa = 'Invalid type of the second parameter %1 in function %2: %3.';
				|it = 'Tipo errato di secondo parametro %1 nella funzione %2: %3.';
				|pl = 'Nieprawidłowy typ drugiego parametru %1 w funkcji %2: %3 ';
				|tr = '%2 işlevinde geçersiz ikinci %1 parametre türü: %3.'"), 
			"Attributes", "Common.ObjectAttributesValues", String(TypeOf(Attributes))),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	// Preparation of the result (after executing the request, it will be redefined).
	Result = New Structure;
	
	// Formation of the request text for the selected fields.
	QueryTextofFields = "";
	For Each KeyAndValue In FieldsStructure Do
		
		FieldName = ?(ValueIsFilled(KeyAndValue.Value),
						KeyAndValue.Value,
						KeyAndValue.Key);
		FieldAlias = KeyAndValue.Key;
		
		If MultilingualAttributes[FieldName] <> Undefined Then
			FieldName = FieldName + LanguageSuffix;
		EndIf;
		
		QueryTextofFields = 
			QueryTextofFields + ?(IsBlankString(QueryTextofFields), "", ",") + "
			|	" + FieldName + " AS " + FieldAlias;
		
		// Pre-adding a field by alias to the returned result.
		Result.Insert(FieldAlias);
		
	EndDo;
	
	// If there is no predefined in the IB.
	// - bringing the result to the absence of an object in the IB or the transmission of an empty link.
	If Ref = Undefined Then 
		Return Result;
	EndIf;
	
	If Type("Structure") = TypeOf(Attributes)
		Or Type("FixedStructure") = TypeOf(Attributes) Then
		Attributes = New Array;
		For Each KeyAndValue In FieldsStructure Do
			FieldName = ?(ValueIsFilled(KeyAndValue.Value),
						KeyAndValue.Value,
						KeyAndValue.Key);
			Attributes.Add(FieldName);
		EndDo;
	EndIf;
	
	BankDetailsViaAPoint = New Array;
	For IndexOf = -Attributes.UBound() To 0 Do
		FieldName = Attributes[-IndexOf];
		If StrFind(FieldName, ".") Then
			BankDetailsViaAPoint.Add(FieldName);
			Attributes.Delete(-IndexOf);
		EndIf;
	EndDo;
	
	If ValueIsFilled(Attributes) Then
		ObjectAttributesValues = ObjectsAttributesValues(ValueInArray(Ref), Attributes, SelectAllowedItems, LanguageCode)[Ref];
		If ObjectAttributesValues <> Undefined Then
			For Each KeyAndValue In FieldsStructure Do
				FieldName = ?(ValueIsFilled(KeyAndValue.Value),
							KeyAndValue.Value,
							KeyAndValue.Key);
				If StrFind(FieldName, ".") = 0 And ObjectAttributesValues.Property(FieldName) Then
					Result[KeyAndValue.Key] = ObjectAttributesValues[FieldName];
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(BankDetailsViaAPoint) Then
		Return Result;
	EndIf;
	
	Attributes = BankDetailsViaAPoint;
	
	QueryText = 
		"SELECT ALLOWED
		|&QueryTextofFields
		|FROM
		|	&FullMetadataObjectName AS SpecifiedTableAlias
		|WHERE
		|	SpecifiedTableAlias.Ref = &Ref";
	
	If Not SelectAllowedItems Then 
		QueryText = StrReplace(QueryText, "ALLOWED", ""); // @Query-part-1
	EndIf;
	
	QueryText = StrReplace(QueryText, "&QueryTextofFields", QueryTextofFields);
	QueryText = StrReplace(QueryText, "&FullMetadataObjectName", FullMetadataObjectName);
	
	// Request execution.
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text = QueryText;
	
	Try
		Selection = Query.Execute().Select();
	Except
		
		// If the details were passed as a string, then they have already been converted into an array.
		// If the details are an array, we leave them unchanged.
		// If the details are a structure, we convert them into an array.
		// In other cases, an exception would have already been thrown.
		If Type("Structure") = TypeOf(Attributes)
			Or Type("FixedStructure") = TypeOf(Attributes) Then
			Attributes = New Array;
			For Each KeyAndValue In FieldsStructure Do
				FieldName = ?(ValueIsFilled(KeyAndValue.Value),
							KeyAndValue.Value,
							KeyAndValue.Key);
				Attributes.Add(FieldName);
			EndDo;
		EndIf;
		
		// Search for field availability errors.
		Result = CheckIfObjectAttributesExist(FullMetadataObjectName, Attributes);
		If Result.Error Then 
			Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sai tham số thứ hai %1 trong hàm %2: %3';
					|ru = 'Неверный второй параметр %1 в функции %2: %3';
					|en = 'Invalid value of the %1 second parameter, function %2: %3'; fa = 'Invalid value of the %1 second parameter, function %2: %3';
					|it = 'Tipo errato di secondo parametro %1 nella funzione %2: %3';
					|pl = 'Nieprawidłowy drugi parametr %1 w funkcji %2: %3';
					|tr = '%2işlevinde geçersiz ikinci %1 parametre: %3'"), 
				"Attributes", "Common.ObjectAttributesValues", Result.ErrorDescription),
				ErrorCategory.ConfigurationError);
		EndIf;

		Raise;
		
	EndTry;
	
	// Filling in the details.
	If Selection.Next() Then
		FillPropertyValues(Result, Selection);
	EndIf;
	
	Return Result;
	
EndFunction

// See Common.ObjectAttributeValue
//
Function ObjectAttributeValue(Ref, AttributeName, SelectAllowedItems = False, Val LanguageCode = Undefined) Export
	
	If IsBlankString(AttributeName) Then 
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai tham số thứ hai %1 trong hàm %2: 
				|Cần điền tên mục tin.';
				|ru = 'Неверный второй параметр %1 в функции %2: 
				|Имя реквизита должно быть заполнено.';
				|en = 'Invalid value of the %1 second parameter, function %2:
				|The attribute name cannot be empty.'; fa = 'Invalid value of the %1 second parameter, function %2:
				|The attribute name cannot be empty.';
				|it = 'Tipo errato di secondo parametro %1 nella funzione %2: 
				|il nome del requisito deve essere compilato.';
				|pl = 'Nieprawidłowy drugi parametr %1 w funkcji %2: 
				|Nazwa atrybutu musi zostać wypełniona.';
				|tr = '%2 işlevinde geçersiz ikinci %1parametre: 
				|Öznitelik adı doldurulmalıdır.'"), 
			"AttributeName", "Common.ObjectAttributeValue"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	Result = ObjectAttributesValues(Ref, AttributeName, SelectAllowedItems, LanguageCode);
	Return Result[StrReplace(AttributeName, ".", "")];
	
EndFunction 

// See Common.ObjectsAttributesValues
//
Function ObjectsAttributesValues(References, Val Attributes, SelectAllowedItems = False, Val LanguageCode = Undefined) Export
	
	If TypeOf(Attributes) = Type("Array") Or TypeOf(Attributes) = Type("FixedArray") Then
		Attributes = StrConcat(Attributes, ",");
	EndIf;
	
	If IsBlankString(Attributes) Then 
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai tham số thứ hai %1 trong hàm %2: 
				|Cần chỉ ra trường đối tượng.';
				|ru = 'Неверный второй параметр %1 в функции %2: 
				|Поле объекта должно быть указано.';
				|en = 'Invalid value of the %1 second parameter, function %2:
				|The object field must be specified.'; fa = 'Invalid value of the %1 second parameter, function %2:
				|The object field must be specified.';
				|it = 'Tipo errato di secondo parametro %1 nella funzione %2: 
				|Campo oggetto deve essere indicato.';
				|pl = 'Nieprawidłowy drugi parametr %1 w funkcji %2: 
				|Pole obiektu powinno być podane.';
				|tr = '%2 işlevinde geçersiz ikinci %1 parametre: 
				|Nesne alanı belirtilmelidir.'"), 
			"Attributes", "Common.ObjectsAttributesValues"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	If StrFind(Attributes, ".") <> 0 Then 
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai tham số thứ hai %1 trong hàm %2: 
				|Không hỗ trợ dấu chấm.';
				|ru = 'Неверный второй параметр %1 в функции %2: 
				|Обращение через точку не поддерживается.';
				|en = 'Invalid value of the %1 second parameter, function %2:
				|Dot syntax is not supported.'; fa = 'Invalid value of the %1 second parameter, function %2:
				|Dot syntax is not supported.';
				|it = 'Tipo errato di secondo parametro %1 nella funzione %2: 
				|Contatto tramite punto non supportato.';
				|pl = 'Niepoprawny drugi parametr %1 w funkcji %2: 
				|Zwrot przez kropkę nie jest obsługiwany.';
				|tr = '%2 işlevinde geçersiz ikinci %1 parametre: 
				|Nokta üzerinden başvuru desteklenmiyor.'"), 
			"Attributes", "Common.ObjectsAttributesValues"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	AttributesValues = New Map;
	If References.Count() = 0 Then
		Return AttributesValues;
	EndIf;
	
	If ValueIsFilled(LanguageCode) Then
		LanguageCode = StrSplit(LanguageCode, "_", True)[0];
	EndIf;
	
	AttributesQueryText = Attributes;
	
	If SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = CommonModule("NationalLanguageSupportServer");
		If ValueIsFilled(LanguageCode) Then
			LanguageSuffix = ModuleNationalLanguageSupportServer.LanguageSuffix(LanguageCode);
			If ValueIsFilled(LanguageSuffix) Then
				MultilingualAttributes = ModuleNationalLanguageSupportServer.MultilingualObjectAttributes(References[0]);
				AttributesSet = StrSplit(Attributes, ",");
				For Position = 0 To AttributesSet.UBound() Do
					AttributeName = TrimAll(AttributesSet[Position]);
					If MultilingualAttributes[AttributeName] <> Undefined Then
						NameWithSuffix = AttributeName + LanguageSuffix;
						AttributesSet[Position] = NameWithSuffix + " AS " + AttributeName;
					EndIf;
				EndDo;
				AttributesQueryText = StrConcat(AttributesSet, ",");
			EndIf;
		EndIf;
	EndIf;
	
	RefsByTypes = New Map;
	For Each Ref In References Do
		Type = TypeOf(Ref);
		If RefsByTypes[Type] = Undefined Then
			RefsByTypes[Type] = New Array;
		EndIf;
		ItemByType = RefsByTypes[Type]; // Array
		ItemByType.Add(Ref);
	EndDo;
	
	QueriesTexts = New Array;
	QueryOptions = New Structure;
	
	MetadataObjectNames = New Array;
	
	For Each RefsByType In RefsByTypes Do
		Type = RefsByType.Key;
		MetadataObject = Metadata.FindByType(Type);
		If MetadataObject = Undefined Then
			Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sai tham số đầu tiên %1 trong hàm %2: 
					|Giá trị mảng phải là tham chiếu.';
					|ru = 'Неверный первый параметр %1 в функции %2: 
					|Значения массива должны быть ссылками.';
					|en = 'Invalid value of the %1 first parameter, function %2:
					|The array values must be references.'; fa = 'Invalid value of the %1 first parameter, function %2:
					|The array values must be references.';
					|it = 'Tipo errato di primo parametro %1 nella funzione %2: 
					|I valori della matrice devono essere collegamenti.';
					|pl = 'Nieprawidłowy pierwszy parametr %1 w funkcji %2: 
					|Wartości masywu powinny być odnośnikami.';
					|tr = '%2 işlevinde geçersiz ilk %1parametre: 
					|Dizin değerleri bağlantı olmalıdır.'"), 
				"References", "Common.ObjectsAttributesValues"),
				ErrorCategory.ConfigurationError);
		EndIf;
		
		FullMetadataObjectName = MetadataObject.FullName();
		MetadataObjectNames.Add(FullMetadataObjectName);
		
		QueryText =
			"SELECT ALLOWED
			|	Ref,
			|	&Attributes
			|FROM
			|	&FullMetadataObjectName AS SpecifiedTableAlias
			|WHERE
			|	SpecifiedTableAlias.Ref IN (&References)";
		If Not SelectAllowedItems Or QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "ALLOWED", ""); // @Query-part-1
		EndIf;
		QueryText = StrReplace(QueryText, "&Attributes", AttributesQueryText);
		QueryText = StrReplace(QueryText, "&FullMetadataObjectName", FullMetadataObjectName);
		ParameterName = "References" + StrReplace(FullMetadataObjectName, ".", "");
		QueryText = StrReplace(QueryText, "&References", "&" + ParameterName); // @Query-part-1
		QueryOptions.Insert(ParameterName, RefsByType.Value);
		
		If SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer  = CommonModule("NationalLanguageSupportServer");
			
			If ValueIsFilled(LanguageCode) And LanguageCode <> DefaultLanguageCode()
				And ModuleNationalLanguageSupportServer.ObjectContainsPMRepresentations(FullMetadataObjectName) Then
				
				MultilingualAttributes = ModuleNationalLanguageSupportServer.MultilingualObjectAttributes(MetadataObject);
				TablesFields = New Array;
				TablesFields.Add("SpecifiedTableAlias.Ref");
				For Each Attribute In StrSplit(Attributes, ",") Do
					If MultilingualAttributes[Attribute] <> Undefined Then
						
						If MultilingualAttributes[Attribute] = True Then
							AttributeField = "ISNULL(PresentationTable." + Attribute + ", """")";
						Else
							LanguageSuffix = ModuleNationalLanguageSupportServer.LanguageSuffix(LanguageCode);
							AttributeField = ?(ValueIsFilled(LanguageSuffix), Attribute + LanguageSuffix, Attribute);
						EndIf;
						
						TablesFields.Add(StringFunctionsClientServer.SubstituteParametersToString("%1 AS %2",
							AttributeField, Attribute));
					Else
						TablesFields.Add(Attribute);
					EndIf;
					
				EndDo;
				
				TablesFields = StrConcat(TablesFields, "," + Chars.LF);
				
				Tables = FullMetadataObjectName + " " + "AS SpecifiedTableAlias" + Chars.LF
					+ "LEFT JOIN" + " " + FullMetadataObjectName + ".Presentations AS PresentationTable" + Chars.LF
					+ "On PresentationTable.Ref = SpecifiedTableAlias.Ref AND PresentationTable.LanguageCode = &LanguageCode";
					
				ParameterName = "References" + StrReplace(FullMetadataObjectName, ".", "");
				Conditions = "SpecifiedTableAlias.Ref IN (&" + ParameterName + ")";
				
				QueryStrings = New Array;
				QueryStrings.Add("SELECT" + ?(SelectAllowedItems And Not ValueIsFilled(QueriesTexts), " " + "ALLOWED", "")); // @Query-part-1, @Query-part-3
				QueryStrings.Add(TablesFields);
				QueryStrings.Add("FROM"); // @Query-part-1
				QueryStrings.Add(Tables);
				QueryStrings.Add("WHERE"); // @Query-part-1
				QueryStrings.Add(Conditions);
				
				QueryText = StrConcat(QueryStrings, Chars.LF);
			EndIf;
		EndIf;
		
		QueriesTexts.Add(QueryText);
	EndDo;
	
	QueryText = StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF);
	
	Query = New Query(QueryText);
	Query.SetParameter("LanguageCode", LanguageCode);
	For Each Parameter In QueryOptions Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	Try
		Selection = Query.Execute().Select();
	Except
		
		// Removing spaces.
		Attributes = StrReplace(Attributes, " ", "");
		// Converting a parameter to an array of fields.
		Attributes = StrSplit(Attributes, ",");
		
		// Search for field availability errors.
		ErrorList = New Array;
		For Each FullMetadataObjectName In MetadataObjectNames Do
			Result = CheckIfObjectAttributesExist(FullMetadataObjectName, Attributes);
			If Result.Error Then 
				ErrorList.Add(Result.ErrorDescription);
			EndIf;
		EndDo;
		
		If ValueIsFilled(ErrorList) Then
			Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sai tham số thứ hai %1 trong hàm %2: %3';
					|ru = 'Неверный второй параметр %1 в функции %2: %3';
					|en = 'Invalid value of the %1 second parameter, function %2: %3'; fa = 'Invalid value of the %1 second parameter, function %2: %3';
					|it = 'Tipo errato di secondo parametro %1 nella funzione%2 : %3';
					|pl = 'Nieprawidłowy drugi parametr %1 w funkcji %2: %3';
					|tr = '%2işlevinde geçersiz ikinci %1 parametre: %3'"), 
				"Attributes", "Common.ObjectsAttributesValues", 
				StrConcat(ErrorList, Chars.LF)),
				ErrorCategory.ConfigurationError);
		EndIf;
		
		Raise;
		
	EndTry;
	
	While Selection.Next() Do
		Result = New Structure(Attributes);
		FillPropertyValues(Result, Selection);
		AttributesValues[Selection.Ref] = Result;
		
	EndDo;
	
	Return AttributesValues;
	
EndFunction

// See Common.ObjectsAttributeValue
//
Function ObjectsAttributeValue(ReferencesArrray, AttributeName, SelectAllowedItems = False, Val LanguageCode = Undefined) Export
	
	If IsBlankString(AttributeName) Then 
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai tham số thứ hai %1 trong hàm %2: 
			|Cần điền tên mục tin.';
			|ru = 'Неверный второй параметр %1 в функции %2: 
			|Имя реквизита должно быть заполнено.';
			|en = 'Invalid value of the %1 second parameter, function %2:
			|The attribute name cannot be empty.'; fa = 'Invalid value of the %1 second parameter, function %2:
			|The attribute name cannot be empty.';
			|it = 'Tipo errato di secondo parametro %1 nella funzione %2: 
			|il nome del requisito deve essere compilato.';
			|pl = 'Nieprawidłowy drugi parametr %1 w funkcji %2: 
			|Nazwa atrybutu musi zostać wypełniona.';
			|tr = '%2 işlevinde geçersiz ikinci %1parametre: 
			|Öznitelik adı doldurulmalıdır.'"), 
			"AttributeName", "Common.ObjectsAttributeValue"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	AttributesValues = ObjectsAttributesValues(ReferencesArrray, AttributeName, SelectAllowedItems, LanguageCode);
	For Each Item In AttributesValues Do
		AttributesValues[Item.Key] = Item.Value[AttributeName];
	EndDo;
		
	Return AttributesValues;
	
EndFunction

// See Common.ValueTableToArray()
//
// Parameters:
//  ValueTable - ValueTable - the original table of values.
//
// Returns:
//  Array of String - a collection of table rows in the form of structures.
//
Function ValueTableToArray(ValueTable) Export
	
	Array = New Array();
	StructureString = "";
	CommaRequired = False;
	For Each Column In ValueTable.Columns Do
		If CommaRequired Then
			StructureString = StructureString + ",";
		EndIf;
		StructureString = StructureString + Column.Name;
		CommaRequired = True;
	EndDo;
	For Each TableRow In ValueTable Do
		NewRow = New Structure(StructureString);
		FillPropertyValues(NewRow, TableRow);
		Array.Add(NewRow);
	EndDo;
	Return Array;

EndFunction

// See Common.MetadataObjectByFullName
//
Function MetadataObjectByFullName(FullName) Export
	
	PointPosition = StrFind(FullName, ".");
	BaseTypeName = Left(FullName, PointPosition - 1);
	
	CollectionsNames = MobileWarehouseKeeperWorkspaceCached.CollectionNamesByBaseTypeNames();
	Collection = CollectionsNames.Get(Upper(BaseTypeName));
	
	If Collection <> Undefined Then
		If Collection <> "Subsystems" Then
			ObjectName = Mid(FullName, PointPosition + 1);
			MetadataObject = Metadata[Collection].Find(ObjectName);
		Else
			SubsystemsNames = StrSplit(Upper(FullName), ".");
			Count = SubsystemsNames.Count();
			Subsystem = Metadata;
			MetadataObject = Undefined;
			IndexOf = 0;
			While True Do
				IndexOf = IndexOf + 1;
				If IndexOf >= Count Then
					Break;
				EndIf;
				SubsystemName = SubsystemsNames[IndexOf];
				Subsystem = Subsystem.Subsystems.Find(SubsystemName);
				If Subsystem = Undefined Then
					Break;
				EndIf;
				IndexOf = IndexOf + 1;
				If IndexOf = Count Then
					MetadataObject = Subsystem;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If MetadataObject = Undefined Then
		MetadataObject = Metadata.FindByFullName(FullName);
	EndIf;
	
	Return MetadataObject;
	
EndFunction

// See Common.SubsystemExists
//
Function SubsystemExists(FullSubsystemName) Export
	
	SubsystemsNames = MobileWarehouseKeeperWorkspaceCached.SubsystemsNames();
	Return SubsystemsNames.Get(FullSubsystemName) <> Undefined;
	
EndFunction

// See Common.CommonModule
//
Function CommonModule(Name) Export
	
	If Metadata.CommonModules.Find(Name) <> Undefined Then
		// APK:488-Off compute in safe mode is not used to avoid calling the general module recursively.
		//tag
		//Set the Safe mode (True);
		Module = Eval(Name);
		// APK:488-on
	ElsIf StrOccurrenceCount(Name, ".") = 1 Then
		Return ServerManagerModule(Name);
	Else
		Module = Undefined;
	EndIf;
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неверное значение параметра %1 в %2. Общий модуль ""%3"" не существует.';
				|vi = 'Invalid parameter %1 in %2. Common module ""%3"" does not exist.';
				|en = 'Invalid parameter %1 in %2. Common module ""%3"" does not exist.'; fa = 'Invalid parameter %1 in %2. Common module ""%3"" does not exist.';
				|it = 'Неверное значение параметра %1 в %2. Общий модуль ""%3"" не существует.';
				|pl = 'Invalid parameter %1 in %2. Common module ""%3"" does not exist.';
				|tr = '%2''deki %1 parametresi için geçersiz değer. ""%3"" genel modülü mevcut değil.'"), 
			"Name", "Common.CommonModule", Name), 
			ErrorCategory.ConfigurationError);
	EndIf;
	
	Return Module;
	
EndFunction

// See Common.DefaultLanguageCode
//
Function DefaultLanguageCode() Export
	
	If SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = CommonModule("NationalLanguageSupportServer");
		Return ModuleNationalLanguageSupportServer.DefaultLanguageCode();
	EndIf;
	
	Return Metadata.DefaultLanguage.LanguageCode;
	
EndFunction

// See Common.PredefinedItem
//
Function PredefinedItem(FullPredefinedItemName) Export
	
	StandardProcessing = UseStandardGettingPredefinedItemFunction(
		FullPredefinedItemName);
	
	If StandardProcessing Then 
		Return PredefinedValue(FullPredefinedItemName);
	EndIf;
	
	PredefinedItemFields = PredefinedItemNameByFields(FullPredefinedItemName);
	
	PredefinedValues = MobileWarehouseKeeperWorkspaceCached.RefsByPredefinedItemsNames(
		PredefinedItemFields.FullMetadataObjectName);
	
	Return GeneralPurposeUtilityClientServerPredefinedElement(
		FullPredefinedItemName, PredefinedItemFields, PredefinedValues);
	
EndFunction

// See Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor
//
Function PackagingFactor(Package, Products) Export 
	
	If Not ValueIsFilled(Package) Then
		Return 1;
	EndIf;
	
	If Not ValueIsFilled(Products) Then
		QueryText = 
		"SELECT TOP 1
		|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
		|	Package.MeasuredValueType AS MeasuredValueType
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS Package
		|WHERE
		|	Package.Ref = &PackagingUnitOfMeasure";
		
		SourceOfProducts = Undefined;
	Else
		QueryText = 
		"SELECT TOP 1
		|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
		|	Package.MeasuredValueType AS MeasuredValueType
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS Package
		|		INNER JOIN Catalog.Products AS Products
		|		ON (Products.Ref = &Products)
		|			AND (Package.Ref = &PackagingUnitOfMeasure)";
		SourceOfProducts =  "Products";
	EndIf;
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor",
								RequestTextForPackingCoefficient("Package",SourceOfProducts));

	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("PackagingUnitOfMeasure", Package);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If Selection.MeasuredValueType <> Enums.TypesOfMeasuredValues.Package
			And Products = Undefined Then
			ExceptionText = NStr("ru = 'Для расчета коэффициента упаковки нужно передать номенклатуру.';
								|vi = 'Transfer products to calculate the packaging unit factor.';
								|en = 'Transfer products to calculate the packaging unit factor.'; fa = 'Transfer products to calculate the packaging unit factor.';
								|it = 'Per calcolare il coefficiente di imballaggio, è necessario trasferire l''articolo.';
								|pl = 'Aby obliczyć współczynnik opakowania, należy przekazać towary.';
								|tr = 'Paketleme ünitesi katsayısını hesaplamak için öğenin aktarılması gerekir.'");
			Raise ExceptionText;
		EndIf;
		
		ZoomRatio = Selection.ZoomRatio;
		
	EndIf;
	
	Return ZoomRatio;
	
EndFunction

// See Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient
//
Function RequestTextForPackingCoefficient(SourceOfPackaging, SourceOfProducts = Undefined) Export 
	
	If Not ValueIsFilled(SourceOfProducts)  Then 
		
		QueryText = 
		"CASE WHEN ISNULL(GoodsTable.Package.Denominator,1) <> 0
		|			 AND ISNULL(GoodsTable.Package.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	THEN CAST(ISNULL(GoodsTable.Package.Numerator, 1) / ISNULL(GoodsTable.Package.Denominator, 1) AS NUMBER(27, 11))
		|	ELSE NULL
		|END";
		
	Else		
		
		QueryText = 
		"CASE
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
		|				AND GoodsTable.Products.WeightUse
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Numerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.WeightNumerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|			THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
		|				AND GoodsTable.Products.VolumeUse
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Numerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.VolumeNumerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|			THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
		|				AND GoodsTable.Products.AreaUse
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Numerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.AreaNumerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|			THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
		|				AND GoodsTable.Products.LengthUse
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Numerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.LengthNumerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|			THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|		WHEN (GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
		|					OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
		|					OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
		|					OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time))
		|				AND GoodsTable.Products.UnitOfMeasure.MeasuredValueType = GoodsTable.Package.MeasuredValueType
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|			THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.UnitOfMeasure.Numerator / GoodsTable.Products.UnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|			THEN CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|			THEN 1
		|		ELSE NULL
		|	END";
		
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	Return QueryText;	 
	
EndFunction

// See Catalogs.StorageBins.DefaultAcceptanceZone
//
Function DefaultAcceptanceZone(Warehouse,Premise,ReceivingArea = Undefined) Export
	
	If ValueIsFilled(ReceivingArea) Then
		CellDetails = ObjectAttributesValues(ReceivingArea, "Owner,Premise,StorageBinType");
		
		If CellDetails.Owner = Warehouse
			And CellDetails.Premise = Premise
			And CellDetails.StorageBinType = Enums.TypesOfStorageCells.Receiving Then
			Return ReceivingArea;
		EndIf;
	EndIf;
	
	Query = New Query(
	"SELECT TOP 2
	|	CatCells.Ref AS Cell
	|FROM
	|	Catalog.StorageBins AS CatCells
	|WHERE
	|	(NOT CatCells.DeletionMark)
	|	AND CatCells.StorageBinType = VALUE(Enum.TypesOfStorageCells.Receiving)
	|	AND CatCells.Owner = &Warehouse
	|	AND CatCells.Premise = &Premise");
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 
	   And Selection.Next() Then
		Cell = Selection.Cell;
	Else
		Cell = Catalogs.StorageBins.EmptyRef();
	EndIf;
	
	Return Cell;

EndFunction

// See Catalogs.Products.ItemVariantsAreUsed
//
Function ItemVariantsAreUsed(Products) Export
	
	If Not ValueIsFilled(Products) Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CASE
	|		WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			OR CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			OR CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|				THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed
	|FROM
	|	Catalog.Products AS CatProducts
	|WHERE
	|	CatProducts.Ref = &Ref";
	
	Query.SetParameter("Ref", Products);
	
	Selection = Query.Execute().Select();
	
	Selection.Next();
	
	Return Selection.ItemVariantsAreUsed;
	
EndFunction

// See ProductsServer.DefaultUnitOfMeasurement
//
Function DefaultUnitOfMeasurement(TypeOfMeasuredValueString) Export
	
	If TypeOfMeasuredValueString = "Weight" Then
		Value = Constants.UnitOfMeasureForWeight.Get();
	ElsIf TypeOfMeasuredValueString = "VolumeM3" Then
		Value = Constants.UnitOfMeasureForVolume.Get();
	ElsIf TypeOfMeasuredValueString = "AreaTypeOfMeasurement" Then
		Value = Constants.UnitOfMeasureForArea.Get();
	ElsIf TypeOfMeasuredValueString = "Length" Then 
		Value = Constants.UnitOfMeasureForLength.Get();
	ElsIf TypeOfMeasuredValueString = "Piece" Then 
		Value = Constants.UnitOfMeasureOfQuantity.Get();
	ElsIf TypeOfMeasuredValueString = "Bottling" Then 
		Value = Constants.UnitOfMeasureOfDraughtProducts.Get();
	Else
		Value = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	EndIf;
	
	Return Value;
EndFunction

// See Common.ObjectManagerByFullName
//
// Parameters:
//  FullName - String - full name of the metadata object. Example: "Directory.Companies".
//
// Returns:
//  CatalogManager
//
Function ObjectManagerByFullName(FullName) Export
	
	Var MOClass, MetadataObjectName1, Manager;
	
	NameParts = StrSplit(FullName, ".");
	
	If NameParts.Count() >= 2 Then
		MOClass = NameParts[0];
		MetadataObjectName1   = NameParts[1];
	Else 
		Manager = Undefined;
	EndIf;
	
#If MobileStandaloneServer Then
	If      Upper(MOClass) = "EXCHANGEPLAN" Then
		Manager = ExchangePlans;
		
	ElsIf Upper(MOClass) = "CATALOG" Then
		Manager = Catalogs;
		
	ElsIf Upper(MOClass) = "DOCUMENT" Then
		Manager = Documents;
		
	ElsIf Upper(MOClass) = "DOCUMENTJOURNAL" Then
		Manager = DocumentJournals;
		
	ElsIf Upper(MOClass) = "ENUM" Then
		Manager = Enums;
		
	ElsIf Upper(MOClass) = "REPORT" Then
		Manager = Reports;
		
	ElsIf Upper(MOClass) = "DATAPROCESSOR" Then
		Manager = DataProcessors;
		
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Manager = ChartsOfCharacteristicTypes;
		
	ElsIf Upper(MOClass) = "INFORMATIONREGISTER" Then
		Manager = InformationRegisters;
		
	ElsIf Upper(MOClass) = "ACCUMULATIONREGISTER" Then
		Manager = AccumulationRegisters;
		
	ElsIf Upper(MOClass) = "CONSTANT" Then
		Manager = Constants;
		
	ElsIf Upper(MOClass) = "SEQUENCE" Then
		Manager = Sequences;
		
	Else
		Manager = Undefined;
	EndIf;
#Else
	If      Upper(MOClass) = "EXCHANGEPLAN" Then
		Manager = ExchangePlans;
		
	ElsIf Upper(MOClass) = "CATALOG" Then
		Manager = Catalogs;
		
	ElsIf Upper(MOClass) = "DOCUMENT" Then
		Manager = Documents;
		
	ElsIf Upper(MOClass) = "DOCUMENTJOURNAL" Then
		Manager = DocumentJournals;
		
	ElsIf Upper(MOClass) = "ENUM" Then
		Manager = Enums;
		
	ElsIf Upper(MOClass) = "REPORT" Then
		Manager = Reports;
		
	ElsIf Upper(MOClass) = "DATAPROCESSOR" Then
		Manager = DataProcessors;
		
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Manager = ChartsOfCharacteristicTypes;
		
	ElsIf Upper(MOClass) = "CHARTOFACCOUNTS" Then
		Manager = ChartsOfAccounts;
		
	ElsIf Upper(MOClass) = "CHARTOFCALCULATIONTYPES" Then
		Manager = ChartsOfCalculationTypes;
		
	ElsIf Upper(MOClass) = "INFORMATIONREGISTER" Then
		Manager = InformationRegisters;
		
	ElsIf Upper(MOClass) = "ACCUMULATIONREGISTER" Then
		Manager = AccumulationRegisters;
		
	ElsIf Upper(MOClass) = "ACCOUNTINGREGISTER" Then
		Manager = AccountingRegisters;
		
	ElsIf Upper(MOClass) = "CALCULATIONREGISTER" Then
		
		If      NameParts.Count() = 2 Then
			Manager = CalculationRegisters;
			
		ElsIf NameParts.Count() = 4 Then
			SubordinateMOClass = NameParts[2];
			SubordinateMOName = NameParts[3];
			
			If Upper(SubordinateMOClass) = "RECALCULATION" Then 
				Manager = CalculationRegisters[MetadataObjectName1].Recalculations;
				MetadataObjectName1 = SubordinateMOName;
				
			Else 
				Manager = Undefined;
			EndIf;
			
		Else
			Manager = Undefined;
		EndIf;
		
	ElsIf Upper(MOClass) = "BUSINESSPROCESS" Then
		Manager = BusinessProcesses;
		
	ElsIf Upper(MOClass) = "TASK" Then
		Manager = Tasks;
		
	ElsIf Upper(MOClass) = "CONSTANT" Then
		Manager = Constants;
		
	ElsIf Upper(MOClass) = "SEQUENCE" Then
		Manager = Sequences;
		
	Else
		Manager = Undefined;
	EndIf;
#EndIf
	
	If Manager = Undefined Then
		CheckMetadataObjectExists(FullName);
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неверное значение параметра %1 функции %2. У объекта метаданных ""%3"" нет менеджера объекта.';
				|vi = 'Invalid value of parameter ""%1"" in function ""%2"". Metadata object ""%3"" is missing an object manager.';
				|en = 'Invalid value of parameter ""%1"" in function ""%2"". Metadata object ""%3"" is missing an object manager.'; fa = 'Invalid value of parameter ""%1"" in function ""%2"". Metadata object ""%3"" is missing an object manager.';
				|it = 'Неверное значение параметра %1 функции %2. У объекта метаданных ""%3"" нет менеджера объекта.';
				|pl = 'Invalid value of parameter ""%1"" in function ""%2"". Metadata object ""%3"" is missing an object manager.';
				|tr = '%2 fonksiyonunun %1 parametresi için geçersiz değer. ''%3'' meta veri nesnesinin bir nesne yöneticisi yok.'"), 
			"FullName", "Common.ObjectManagerByFullName", FullName),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	Try
		Return Manager[MetadataObjectName1];
	Except
		CheckMetadataObjectExists(FullName);
		Raise;
	EndTry;
	
EndFunction

// See Catalogs.ItemKinds.SeriesUseSettings
//
Function SeriesUseSettings(ProductKind, SeriesSpecificationParameters = Undefined, ConnectionFieldValues = Undefined) Export
	
	ProductKindAttributes		= New Structure;
	DetailsOfSettingUpSpecifyingSeries	= DetailsOfSettingUpSpecifyingSeries();
	
	For Each ArrRow In DetailsOfSettingUpSpecifyingSeries Do
		ProductKindAttributes.Insert(ArrRow);
	EndDo;
	
	ProductKindAttributes.Insert("ProductKind");
	ProductKindAttributes.Insert("AccountingFeature");
	ProductKindAttributes.Insert("KeepAccountingByBatch");
	
	If TypeOf(ProductKind) <> Type("CatalogRef.ItemKinds") Then
		FillPropertyValues(ProductKindAttributes, ProductKind);
		
		ProductKindAttributes.ProductKind = ProductKind.Ref;
		ProductKindAttributes.BatchOwner = ?(ProductKind.BatchSettingsAreTakenFromOtherItemsKind,
													ProductKind.BatchOwner,
													ProductKind.Ref);
		ProductKindAttributes.LabelTemplateBatches = ?(ProductKind.BatchSettingsAreTakenFromOtherItemsKind,
															DefaultValuesForItemDetails(
																ProductKind.BatchOwner,
																"LabelTemplateBatches"),
															ProductKind.LabelTemplateBatches);
	Else
		
		ProductKindAttributes.ProductKind = "Ref";
		ProductKindAttributes.BatchOwner =
		"CASE
		|		WHEN BatchSettingsAreTakenFromOtherItemsKind
		|			THEN BatchOwner
		|		ELSE Ref
		|	END";
		ProductKindAttributes.LabelTemplateBatches =
		"CASE
		|		WHEN BatchSettingsAreTakenFromOtherItemsKind
		|			THEN BatchOwner.LabelTemplateBatches
		|		ELSE LabelTemplateBatches
		|	END";
		
		SelectionFields1 = New Array;
		
		For Each TypeDetails_ In ProductKindAttributes Do
			FieldName		= ?(ValueIsFilled(TypeDetails_.Value),
						TypeDetails_.Value,
						TypeDetails_.Key);
			SelectionField= "
							|	" + FieldName + " AS " + TypeDetails_.Key;
			
			SelectionFields1.Add(SelectionField);
		EndDo;
		
		SelectionText = StrConcat(SelectionFields1, ",");
		QueryText =
		"SELECT
		|&SelectionFields1
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|WHERE
		|	ItemKinds.Ref = &Ref";
		QueryText = StrReplace(QueryText, "&SelectionFields1", SelectionText);
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Ref", ProductKind);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			FillPropertyValues(ProductKindAttributes, Selection);
		EndIf;
		
	EndIf;
	
	SeriesUseSettings = SettingsForUsingSerialFields(False);
	
	FillPropertyValues(SeriesUseSettings, ProductKindAttributes);
	
	DescriptionsOfUseOfSeriesProps = DescriptionsOfUseOfSeriesProps(SeriesUseSettings, SeriesSpecificationParameters, ConnectionFieldValues);
	
	ToCreateFixedArray = New Array;
	
	For Each LongDesc In DescriptionsOfUseOfSeriesProps Do
		ToCreateFixedArray.Add(New FixedStructure(LongDesc));
	EndDo;
	
	SeriesUseSettings.DescriptionsOfUseOfSeriesProps = New FixedArray(ToCreateFixedArray);
	
#If Not MobileStandaloneServer Then
	If Not ValueIsFilled(SeriesUseSettings.LabelTemplateBatches) Then
		SeriesUseSettings.LabelTemplateBatches 
			= Catalogs.LabelAndPriceTagTemplates.DefaultTemplate(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel);
	EndIf;
#EndIf
	
	If TypeOf(ProductKind) = Type("CatalogRef.ItemKinds")
		And (ValueIsFilled(ConnectionFieldValues)
			And ConnectionFieldValues.Property("Warehouse")
			And (ValueIsFilled(ConnectionFieldValues.Warehouse)
				Or UseProduction())) Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ISNULL(TSBatchAccountingPolicies.BatchAccountingPolicy, VALUE(Catalog.BatchAccountingPolicies.EmptyRef)) AS BatchAccountingPolicy,
		|	ISNULL(TSBatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving, FALSE) AS SpecifyUponReceipt,
		|	ISNULL(TSBatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipment, FALSE) AS SpecifyOnShipment,
		|	ISNULL(TSBatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment, FALSE) AS SpecifyWhenPlanningShipment,
		|	ISNULL(TSBatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO, FALSE) AS BatchesAccountingByFEFO,
		|	ISNULL(TSBatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult, FALSE) AS SpecifyByPickingResult,
		|	ISNULL(TSBatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries, FALSE)
		|			AND (TSBatchAccountingPolicies.Warehouse REFS Catalog.Warehouses OR &ThereIsProduction)AS AccountForRemainingSeries,
		|	ISNULL(TSBatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE) 
		|			AND (TSBatchAccountingPolicies.Warehouse REFS Catalog.Warehouses OR &ThereIsProduction)
		|		AS UseCostAccountingByBatches
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS TSBatchAccountingPolicies
		|		ON ItemKinds.Ref = TSBatchAccountingPolicies.Ref
		|			AND (TSBatchAccountingPolicies.Warehouse = &WarehouseDivision)
		|WHERE
		|	ItemKinds.Ref = &ProductKind";		
		Query.SetParameter("ProductKind", ProductKind);
		Query.SetParameter("WarehouseDivision", ConnectionFieldValues.Warehouse);
		Query.SetParameter("ThereIsProduction", UseProduction());
		
		Selection = Query.Execute().Select();
		
		Selection.Next();
		
		FillPropertyValues(SeriesUseSettings, Selection);
		
	EndIf;
	
	If TypeOf(ProductKind) = Type("CatalogRef.ItemKinds") Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	ItemKindsAttributesForBatchControl.Property AS Property
		|FROM
		|	Catalog.ItemKinds.AttributesForBatchControl AS ItemKindsAttributesForBatchControl
		|WHERE
		|	ItemKindsAttributesForBatchControl.Ref = CASE
		|			WHEN CAST(&ProductKind AS Catalog.ItemKinds).BatchSettingsAreTakenFromOtherItemsKind
		|				THEN CAST(&ProductKind AS Catalog.ItemKinds).BatchOwner
		|			ELSE &ProductKind
		|		END
		|	AND ItemKindsAttributesForBatchControl.IsAddlAttribute
		|	AND ItemKindsAttributesForBatchControl.RequiredToFill";
		
		Query.SetParameter("ProductKind", ProductKind);
		AttributesForBatchControl = Query.Execute().Unload();
		
	Else
		If ProductKind.BatchSettingsAreTakenFromOtherItemsKind Then
			
			Query = New Query;
			Query.Text =
			"SELECT
			|	ItemKindsAttributesForBatchControl.Property AS Property
			|FROM
			|	Catalog.ItemKinds.AttributesForBatchControl AS ItemKindsAttributesForBatchControl
			|WHERE
			|	ItemKindsAttributesForBatchControl.Ref = &BatchOwner
			|	AND ItemKindsAttributesForBatchControl.IsAddlAttribute
			|	AND ItemKindsAttributesForBatchControl.RequiredToFill";
			
			Query.SetParameter("BatchOwner", ProductKind.BatchOwner);
			AttributesForBatchControl = Query.Execute().Unload();
		
		Else
			AttributesForBatchControl = ProductKind.AttributesForBatchControl.Unload(
				New Structure("IsAddlAttribute,RequiredToFill", True, True));
		EndIf;
	EndIf;
	
	SeriesUseSettings.MandatoryAdditionalDetails = New FixedArray(AttributesForBatchControl.UnloadColumn("Property")); 
	
	Return SeriesUseSettings;
	
EndFunction

// See ProductsLocalization.DetailsOfSettingUpSpecifyingSeries
//
Procedure AttributesSettingsSerialIndicationItemLocalization(DetailsOfSettingUpSpecifyingSeries) Export
	
	DetailsOfSettingUpSpecifyingSeries.Add("CIMSPMSNumber");
	DetailsOfSettingUpSpecifyingSeries.Add("UseUSAISManufacturerBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("UseCertificate2USAISBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("UseManufacturerVetISBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("UseWarehouseJournalRecordVetISBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("UseVetISLotIDBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("MRCMOTP");
	
	Return;
	
EndProcedure

// See TMCommonUse.DefaultValuesForItemDetails
//
Function DefaultValuesForItemDetails(Ref, Attributes) Export
	
	If ValueIsFilled(Ref) Then
		Result = ObjectAttributesValues(Ref, Attributes);
	Else
		If TypeOf(Attributes) = Type("String") Then 
			Result = New Structure(Attributes);
		ElsIf TypeOf(Attributes) = Type("Array") Then
			Result = New Structure(StrConcat(Attributes, ","));
		Else
			ExceptionText = NStr("vi = 'Loại tham số ""Mục tin"" không hợp lệ';
								|ru = 'Неверный тип параметра ""Реквизиты""';
								|en = 'Invalid type of ""Attributes"" parameter'; fa = 'Invalid type of ""Attributes"" parameter';
								|it = 'Tipo di parametro ""Requisiti"" non corretto';
								|pl = 'Nieprawidłowy typ parametru ""Rekwizyty""';
								|tr = 'Yanlış ""Öznitelikler"" parametresi tipi'");
			Raise ExceptionText;
		EndIf;
		
		ObjectMetadata = Metadata.FindByType(TypeOf(Ref)); // MetadataObjectDocument - 
		
		If ObjectMetadata = Undefined Then
			ExceptionText = NStr("vi = 'Giá trị được truyền không phải là một liên kết';
								|ru = 'Переданное значение не является ссылкой';
								|en = 'The transferred value is not a reference'; fa = 'The transferred value is not a reference';
								|it = 'Valore trasmesso non è un link';
								|pl = 'Wysłana wartość nie jest odnośnikiem';
								|tr = 'Transfer edilen değer bağlantı değil'");
			Raise ExceptionText;
		EndIf;
		
		For Each KeyValue In Result Do
			
			AttributeMetadata = ObjectMetadata.Attributes.Find(KeyValue.Key);
			
			If AttributeMetadata = Undefined Then
				
				For Each StandardAttribute In  ObjectMetadata.StandardAttributes Do
					If StandardAttribute.Name = KeyValue.Key Then
						AttributeMetadata = StandardAttribute;
						Break;
					EndIf;
				EndDo;
				
				If AttributeMetadata = Undefined Then 
					
					ExceptionText = NStr("vi = 'Mục tin %AttributeName% không tim thấy';
										|ru = 'Реквизит %AttributeName% не найден';
										|en = 'Attribute %AttributeName% is not found'; fa = 'Attribute %AttributeName% is not found';
										|it = 'Il requisito %AttributeName% non trovato';
										|pl = 'Rekwizyt %AttributeName% nie został znaleziony';
										|tr = '%AttributeName% özniteliği bulunamadı'");
					ExceptionText = StrReplace(ExceptionText, "%AttributeName%", KeyValue.Key);
					Raise ExceptionText;
				EndIf;
				
			EndIf;
			
			Result[KeyValue.Key] = AttributeMetadata.Type.AdjustValue();	
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// See Catalogs.ItemKinds.DescriptionsOfUseOfSeriesProps
//
// Parameters:
//   SeriesUseSettings - Arbitrary
//   SeriesSpecificationParameters - Arbitrary
//   ConnectionFieldValues - Arbitrary
//   
// Returns:
//   Array of Structure:
//       * AttributeName - String
//       * AttributeRepresentation - String
//       * SettingName - String
//       * NameTemplateText - String
//       * Use - Boolean
//       * AccountingFeatures - String
//       * Format - String
//       * PresentationOfFormatStringInHeader - String
//       * CheckFilling - Boolean
//       * CanBeEdited - Boolean
//       * ConditionalAppearanceText - String
//       * CheckUniquenessOfValue - Boolean
//
Function DescriptionsOfUseOfSeriesProps(SeriesUseSettings = Undefined, SeriesSpecificationParameters = Undefined, ConnectionFieldValues = Undefined) Export

	DescriptionsOfUseOfSeriesProps = New Array;
	
	If SeriesUseSettings = Undefined Then
		SeriesUseSettings = SettingsForUsingSerialFields(True);
	Else
		ExpirationDateFormatString = "";
	EndIf;
	
	ExpirationDateFormatString = Enums.AccuracyOfShelfLifeIndication.FormatString(SeriesUseSettings.PrecisionOfBatchShelfLifeIndication);
	PresentationOfFormatStringInExpirationDateHeader = Enums.AccuracyOfShelfLifeIndication.FormatStringPresentation(SeriesUseSettings.PrecisionOfBatchShelfLifeIndication);

	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "Number";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "SpecifyNumberWhenRegisteringBatch";
	DescriptionUsingPropsSeries.NameTemplateText = NStr("vi = '%Number%';
														|ru = '%Number%';
														|en = '%Number%'; fa = '%Number%';
														|it = '%Number%';
														|pl = '%Number%';
														|tr = '%Number%'");
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "ProductionDate";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseBatchProductionDate";
	DescriptionUsingPropsSeries.NameTemplateText = NStr("vi = 'từ %ProductionDate%';
														|ru = 'от %ProductionDate%';
														|en = 'dated %ProductionDate%'; fa = 'dated %ProductionDate%';
														|it = 'dal %ProductionDate%';
														|pl = 'od %ProductionDate%';
														|tr = '%ProductionDate% tarihli'");
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.Format = ExpirationDateFormatString;
	DescriptionUsingPropsSeries.PresentationOfFormatStringInHeader = PresentationOfFormatStringInExpirationDateHeader;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "ValidUntil_";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseShelfLifeOnBatchRegistration";
	DescriptionUsingPropsSeries.NameTemplateText = NStr("vi = 'đến %ValidUntil_%';
														|ru = 'до %ValidUntil_%';
														|en = 'until %ValidUntil_%'; fa = 'until %ValidUntil_%';
														|it = 'al %ValidUntil_%';
														|pl = 'do %ValidUntil_%';
														|tr = 'bitişi %ValidUntil_%'");
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.Format = ExpirationDateFormatString;
	DescriptionUsingPropsSeries.PresentationOfFormatStringInHeader = PresentationOfFormatStringInExpirationDateHeader;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "RFIDTID";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseRFIDTags";
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CanBeEdited = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "RFIDUser";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseRFIDTags";
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CanBeEdited = False; // The ERP does not implement the RFIDUser bank record 
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "RFIDEPC";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseRFIDTags";
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CheckFilling = True;
	DescriptionUsingPropsSeries.CanBeEdited = False; // In ERP, only the RFIDEPC bank record is implemented and only for integration with GISM
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "EPCGTIN";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseRFIDTags";
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CanBeEdited = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "RFIDTagIsCorruptedAndCannotBeRead";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseRFIDTags";
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CanBeEdited = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionOfUseOfSeriesProps(DescriptionsOfUseOfSeriesProps, SeriesUseSettings, SeriesSpecificationParameters, ConnectionFieldValues);
	
	Return DescriptionsOfUseOfSeriesProps;

EndFunction

// See Catalogs.ItemKinds.DescriptionUsingPropsSeries
//
// Returns:
//   Structure:
//       * AttributeName - String
//       * AttributeRepresentation - String
//       * SettingName - String
//       * NameTemplateText - String
//       * Use - Boolean
//       * AccountingFeatures - String
//       * Format - String
//       * PresentationOfFormatStringInHeader - String
//       * CheckFilling - Boolean
//       * CanBeEdited - Boolean
//       * ConditionalAppearanceText - String
//       * CheckUniquenessOfValue - Boolean
//
Function DescriptionUsingPropsSeries() Export
	
	DescriptionUsingPropsSeries = New Structure;
	DescriptionUsingPropsSeries.Insert("AttributeName", "");
	DescriptionUsingPropsSeries.Insert("AttributeRepresentation", "");
	DescriptionUsingPropsSeries.Insert("SettingName", "");
	DescriptionUsingPropsSeries.Insert("NameTemplateText", "");
	DescriptionUsingPropsSeries.Insert("Use", False);
	
	DescriptionUsingPropsSeries.Insert("AccountingFeatures", "");
	DescriptionUsingPropsSeries.Insert("Format", "");
	DescriptionUsingPropsSeries.Insert("PresentationOfFormatStringInHeader", "");
	DescriptionUsingPropsSeries.Insert("CheckFilling", True);
	DescriptionUsingPropsSeries.Insert("CanBeEdited", True);
	DescriptionUsingPropsSeries.Insert("ConditionalAppearanceText", "");
	DescriptionUsingPropsSeries.Insert("CheckUniquenessOfValue", False);
	
	Return DescriptionUsingPropsSeries;
	
EndFunction

// See ProductsLocalization.DescriptionOfUseOfSeriesProps
//
Procedure DescriptionOfUseOfSeriesProps(DescriptionsOfUseOfSeriesProps, SeriesUseSettings = Undefined, SeriesSpecificationParameters = Undefined, ConnectionFieldValues = Undefined) Export
	
#If Not MobileStandaloneServer Then
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "ManufacturerUSAIS";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseUSAISManufacturerBatch";
	DescriptionUsingPropsSeries.NameTemplateText = NStr("vi = '%ManufacturerUSAIS%';
														|ru = '%ManufacturerUSAIS%';
														|en = '%ManufacturerUSAIS%'; fa = '%ManufacturerUSAIS%';
														|it = '%ManufacturerUSAIS%';
														|pl = '%ManufacturerUSAIS%';
														|tr = '%ManufacturerUSAIS%'");
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CheckFilling = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "Certificate2USAIS";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseCertificate2USAISBatch";
	DescriptionUsingPropsSeries.NameTemplateText = NStr("vi = '%Certificate2USAIS%';
														|ru = '%Certificate2USAIS%';
														|en = '%Certificate2USAIS%'; fa = '%Certificate2USAIS%';
														|it = '%Certificate2USAIS%';
														|pl = '%Certificate2USAIS%';
														|tr = '%Certificate2USAIS%'");
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CheckFilling = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "ManufacturerVetIS";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseManufacturerVetISBatch";
	DescriptionUsingPropsSeries.NameTemplateText = NStr("vi = '%ManufacturerVetIS%';
														|ru = '%ManufacturerVetIS%';
														|en = '%ManufacturerVetIS%'; fa = '%ManufacturerVetIS%';
														|it = '%ManufacturerVetIS%';
														|pl = '%ManufacturerVetIS%';
														|tr = '%ManufacturerVetIS%'");
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CheckFilling = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "WarehouseBookRecordVetIS";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseWarehouseJournalRecordVetISBatch";
	DescriptionUsingPropsSeries.NameTemplateText = NStr("vi = '%WarehouseBookRecordVetIS%';
														|ru = '%WarehouseBookRecordVetIS%';
														|en = '%WarehouseBookRecordVetIS%'; fa = '%WarehouseBookRecordVetIS%';
														|it = '%WarehouseBookRecordVetIS%';
														|pl = '%WarehouseBookRecordVetIS%';
														|tr = '%WarehouseBookRecordVetIS%'");
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CheckFilling = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
#EndIf
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "LotIDVetIS";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "UseVetISLotIDBatch";
	DescriptionUsingPropsSeries.NameTemplateText = NStr("vi = '%LotIDVetIS%';
														|ru = '%LotIDVetIS%';
														|en = '%LotIDVetIS%'; fa = '%LotIDVetIS%';
														|it = '%LotIDVetIS%';
														|pl = '%LotIDVetIS%';
														|tr = '%LotIDVetIS%'");
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CheckFilling = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "MaximumRetailPriceMOTP";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "MRCMOTP";
	DescriptionUsingPropsSeries.NameTemplateText = NStr("vi = 'Giá bán lẻ tối đa %MaximumRetailPriceMOTP%';
														|ru = 'МРЦ %MaximumRetailPriceMOTP%';
														|en = 'MRP %MaximumRetailPriceMOTP%'; fa = 'MRP %MaximumRetailPriceMOTP%';
														|it = 'Prezzo Massimo al Dettaglio %MaximumRetailPriceMOTP%';
														|pl = 'MCD %MaximumRetailPriceMOTP%';
														|tr = 'MPF %MaximumRetailPriceMOTP%'");
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CheckFilling = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
	DescriptionUsingPropsSeries = DescriptionUsingPropsSeries();
	DescriptionUsingPropsSeries.AttributeName = "NumberOfSPMSControlIdentificationMark";
	DescriptionUsingPropsSeries.AttributeRepresentation
		= Metadata.Catalogs.ItemsBatches.Attributes.Find(DescriptionUsingPropsSeries.AttributeName).Presentation();
	DescriptionUsingPropsSeries.SettingName = "CIMSPMSNumber";
	DescriptionUsingPropsSeries.NameTemplateText = NStr("vi = '%Couples1% %NumberOfSPMSControlIdentificationMark%';
														|ru = '%Couples1% %NumberOfSPMSControlIdentificationMark%';
														|en = '%Couples1% %NumberOfSPMSControlIdentificationMark%'; fa = '%Couples1% %NumberOfSPMSControlIdentificationMark%';
														|it = '%Couples1% %NumberOfSPMSControlIdentificationMark%';
														|pl = '%Couples1% %NumberOfSPMSControlIdentificationMark%';
														|tr = '%Couples1% %NumberOfSPMSControlIdentificationMark%'");
	DescriptionUsingPropsSeries.NameTemplateText = StrReplace(DescriptionUsingPropsSeries.NameTemplateText, "%Couples1%", "KiZ");
	DescriptionUsingPropsSeries.Use = SeriesUseSettings[DescriptionUsingPropsSeries.SettingName];
	DescriptionUsingPropsSeries.CheckUniquenessOfValue = True;
	DescriptionUsingPropsSeries.Use = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
EndProcedure

// See Catalogs.ItemKinds.UseProduction
//
//  Returns:
//   Boolean
//
Function UseProduction() Export
	
	UseProduction = False; //For TM
#If Not MobileStandaloneServer Then
	UseProduction = GetFunctionalOption("UseProductionManagement"); //For KAUP
#EndIf
	Return UseProduction;
	
EndFunction

// See Catalogs.Products.CheckUsageCharacteristicsAndGetOwnerToSelect
//
Function CheckUsageCharacteristicsAndGetOwnerToSelect(Products, TechnicalCharacteristics) Export

	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("ProductKind"           , "ProductKind");
	AttributesStructure1.Insert("UseVariants", "UseVariants");
	AttributesStructure1.Insert("ItemVariantsOwner"     , "ItemVariantsOwner");
	BankingDetailsValues = ObjectAttributesValues(Products, AttributesStructure1);

	If BankingDetailsValues.UseVariants = Enums.ItemVariantsUsageOptions.DontUse Then
		UseVariants = False;
	Else
		UseVariants = True;

		If BankingDetailsValues.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
			TechnicalCharacteristics = BankingDetailsValues.ProductKind;
		ElsIf BankingDetailsValues.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
			TechnicalCharacteristics = BankingDetailsValues.ItemVariantsOwner;
		Else
			TechnicalCharacteristics = Products;
		EndIf;
	EndIf;

	Return UseVariants;

EndFunction

// See SelectGoodsServer.SetSelectionByOwnerCharacteristics
//
Procedure SetSelectionByOwnerCharacteristics(Form) Export
	
	MobileWarehouseKeeperWorkspaceClientServer.SetDynamicListFilterItem(
		Form.List, "Owner", Form.ItemVariantsOwner, 
		DataCompositionComparisonType.Equal, "SelectionBasedOnCharacteristics", True);
	
EndProcedure
	
// See WarehousesServer.UseBinLocationWarehousing
//
Function UseBinLocationWarehousing(Warehouse, Premise = Undefined, Date = Undefined, ConsiderDate = True) Export
	If Not ValueIsFilled(Warehouse) Then
		Return False;
	EndIf;
	If Not ConsiderDate Then
		ParametersStructure = New Structure("Warehouse,Premise",Warehouse,Premise);
		Return GetFunctionalOption("UseBinLocationWarehousing", ParametersStructure);
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	1 AS Field1
		|FROM
		|	InformationRegister.SettingsOfBinLocationWarehouses AS SettingsOfBinLocationWarehouses
		|WHERE
		|	SettingsOfBinLocationWarehouses.UseBinLocationWarehousing
		|	AND SettingsOfBinLocationWarehouses.StartDateOfUsingWarehouseBinSystem <= &Date
		|	AND SettingsOfBinLocationWarehouses.Warehouse = &Warehouse
		|	AND SettingsOfBinLocationWarehouses.Premise = &Premise
		|	AND (NOT &Premise = VALUE(Catalog.Warerooms.EmptyRef)
		|			OR (NOT SettingsOfBinLocationWarehouses.Warehouse.UseWarerooms
		|				OR &Date < SettingsOfBinLocationWarehouses.Warehouse.StartDateOfWareroomUse))";
	Query.SetParameter("Warehouse",Warehouse);
	Query.SetParameter("Premise",
		?(ValueIsFilled(Premise),Premise,Catalogs.Warerooms.EmptyRef()));
	Query.SetParameter("Date",
		?(ValueIsFilled(Date),Date,CurrentSessionDate()));
	
	Return Not Query.Execute().IsEmpty();
EndFunction

// See Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits
//
Function DimensionalTypesOfUnits() Export
	
	DimensionalTypes = New Array;
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.Weight);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.Length);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.VolumeM3);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement);
	
	Return DimensionalTypes;
	
EndFunction

// See Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingFactorToSelect
//
Function RequestTextForPackingFactorToSelect(SourceOfPackaging, SourceOfProducts = Undefined) Export 
	
	If Not ValueIsFilled(SourceOfProducts)  Then 
		
		QueryText = 
		"CASE WHEN ISNULL(GoodsTable.Package.Denominator,1) <> 0
		|		AND ISNULL(GoodsTable.Package.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	THEN CAST(ISNULL(GoodsTable.Package.Numerator, 1) / ISNULL(GoodsTable.Package.Denominator, 1) AS NUMBER(27, 11))
		|	ELSE NULL
		|END";
		
	Else		
		
		QueryText = 
		"CASE
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
		|		AND GoodsTable.Products.WeightUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|		THEN 
		|			CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
		|		AND GoodsTable.Products.VolumeUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|		THEN
		|			CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
		|		AND GoodsTable.Products.AreaUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|		THEN
		|			CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
		|		AND GoodsTable.Products.LengthUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|		THEN
		|			CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|	WHEN (GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time))
		|		AND GoodsTable.Products.UnitOfMeasure.MeasuredValueType = GoodsTable.Package.MeasuredValueType
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		THEN
		|			CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.UnitOfMeasure.Numerator / GoodsTable.Products.UnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		THEN CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		THEN 1
		|	ELSE NULL
		|END";
		
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	Return QueryText;	 
	
EndFunction

// See Catalogs.PackagesAndUnitsOfMeasure.RequestTextAvailabilityFactorForPackageSelection
//
Function RequestTextAvailabilityFactorForPackageSelection(SourceOfPackaging, SourceOfProducts = Undefined) Export 
	
	If Not ValueIsFilled(SourceOfProducts)  Then 
		
		QueryText = 
		"CASE WHEN ISNULL(GoodsTable.Package.Denominator,1) <> 0
		|		AND ISNULL(GoodsTable.Package.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	THEN TRUE
		|	ELSE FALSE
		|END";
		
	Else		
		
		QueryText = 
		"CASE
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
		|		AND GoodsTable.Products.WeightUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|		THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|			AND CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
		|		AND GoodsTable.Products.VolumeUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|		THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|			AND CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
		|		AND GoodsTable.Products.AreaUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|		THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|			AND CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
		|		AND GoodsTable.Products.LengthUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|		THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|			AND CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|	WHEN (GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time))
		|		AND GoodsTable.Products.UnitOfMeasure.MeasuredValueType = GoodsTable.Package.MeasuredValueType
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.UnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.UnitOfMeasure.Denominator, 0) <> 0
		|		THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.UnitOfMeasure.Numerator / GoodsTable.Products.UnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|			AND CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.UnitOfMeasure.Numerator / GoodsTable.Products.UnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		THEN TRUE
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		THEN TRUE
		|	ELSE TRUE
		|END";
		
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	Return QueryText;	 
	
EndFunction

// See UsersInternal.AuthorizedUser
//
Function AuthorizedUser() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Not SeparatedDataUsageAvailable() Then
		ErrorText = CurrentUserUnavailableInSessionWithoutSeparatorsMessageText();
		Raise ErrorText;
	EndIf;
	
	Return SessionParameters.CurrentUser;
	
EndFunction

// See Common.SeparatedDataUsageAvailable
//
Function SeparatedDataUsageAvailable() Export
	
	Return MobileWarehouseKeeperWorkspaceCached.SeparatedDataUsageAvailable();
	
EndFunction

// See UsersInternal.NewParametersOfExtendedPickForm
//
Function NewParametersOfExtendedPickForm() Export
	
	Result = New Structure;
	Result.Insert("PickFormHeader", "");
	Result.Insert("SelectedUsers", New Array);
	Result.Insert("PickingCompletionButtonTitle", "");
	
	Return Result;
	
EndFunction

// See UsersInternal.SetUpFieldDynamicListPicNum
//
Procedure SetUpFieldDynamicListPicNum(List) Export
	
	RestrictUsageOfDynamicListFieldToFill(List, "PictureNumber");
	
EndProcedure

// See UsersInternal.RestrictUsageOfDynamicListFieldToFill
//
Procedure RestrictUsageOfDynamicListFieldToFill(List, FieldName) Export
	
	Fields = List.GetRestrictionsForUseInGroup();
	If Fields.Find(FieldName) = Undefined Then
		Fields.Add(FieldName);
		List.SetRestrictionsForUseInGroup(Fields);
	EndIf;
	
	Fields = List.GetRestrictionsForUseInFilter();
	If Fields.Find(FieldName) = Undefined Then
		Fields.Add(FieldName);
		List.SetRestrictionsForUseInFilter(Fields);
	EndIf;
	
	Fields = List.GetRestrictionsForUseInOrder();
	If Fields.Find(FieldName) = Undefined Then
		Fields.Add(FieldName);
		List.SetRestrictionsForUseInOrder(Fields);
	EndIf;
	
EndProcedure

// See UsersInternal.SelectGroupUsers
//
Procedure SelectGroupUsers(SelectedItems, StoredParameters, ListBox) Export 
	
	If SelectedItems.Count() = 0 Then 
		Return;
	EndIf;
	
	SelectedElement = SelectedItems[0].SelectedElement;
	SelectedItemType = TypeOf(SelectedElement);
	
	If SelectedItemType = Type("CatalogRef.UserGroups")
			And StoredParameters.UsersGroupsSelection
		Or SelectedItemType = Type("CatalogRef.ExternalUsersGroups")
			And StoredParameters.SelectExternalUsersGroups
		Or SelectedItemType <> Type("CatalogRef.UserGroups")
			And SelectedItemType <> Type("CatalogRef.ExternalUsersGroups") Then 
		
		Return;
	EndIf;
	
	GroupUsers = GroupUsers(ListBox);
	
	SelectedItems.Clear();
	
	For Each GroupUser1 In GroupUsers Do 
		
		Item = New Structure;
		Item.Insert("SelectedElement", GroupUser1.Ref);
		Item.Insert("PictureNumber", GroupUser1.PictureNumber);
		
		SelectedItems.Add(Item);
		
	EndDo;
	
EndProcedure

// See Users.AuthorizedUser
//
Function UsersAuthorizedUser() Export
	
	Return AuthorizedUser();
	
EndFunction

// See Users.CurrentUser
//
Function CurrentUser() Export
	
	Return UsersServiceClientServerCurrentUser(UsersAuthorizedUser());
	
EndFunction

// See UsersInternal.SessionParametersSetting
//
Procedure ServiceUsersSettingSessionParameters(Val ParameterName, SpecifiedParameters) Export
	
	If ParameterName <> "CurrentUser"
	   And ParameterName <> "CurrentExternalUser"
	   And ParameterName <> "AuthorizedUser"
	   And ParameterName <> "UsersCatalogsUpdate" Then
		
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SessionParameters.UsersCatalogsUpdate = New FixedMap(New Map);
	If ParameterName = "UsersCatalogsUpdate" Then
		Return;
	EndIf;
	
	Try
		Values = CurrentUserSessionParameterValues();
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось установить параметр сеанса %1 по причине:
			           |""%2"".
			           |
			           |Обратитесь к администратору.';
			           |vi = 'Couldn''t set session parameter for user ""%1"". Reason:
			           |%2
			           |
			           |Please contact the administrator.';
			           |en = 'Couldn''t set session parameter for user ""%1"". Reason:
			           |%2
			           |
			           |Please contact the administrator.'; fa = 'Couldn''t set session parameter for user ""%1"". Reason:
			           |%2
			           |
			           |Please contact the administrator.';
			           |it = 'Non è stato possibile impostare il parametro di sessione %1a causa di:
			           |""%2"".
			           |
			           |Rivolgersi all''amministratore.';
			           |pl = 'Nie udało się ustawić parametr sesji %1 z powodu:
			           |""%2"".
			           |
			           |Skontaktuj się z administratorem.';
			           |tr = '%1 oturum parametresi aşağıdaki nedenle belirlenemedi: 
			           |""%2"". 
			           |
			           | Yöneticiye başvurun.'"),
			"CurrentUser",
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		Raise ErrorText;
	EndTry;
	
	If TypeOf(Values) = Type("String") Then
		Raise Values;
	EndIf;
	
	SessionParameters.CurrentUser = Values.CurrentUser;
	
	SpecifiedParameters.Add("CurrentUser");
	
EndProcedure

// See Users.IBUserOccupied
//
Function IBUserOccupied(IBUser, Account = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(IBUser) = Type("String") Then
		Account = InfoBaseUsers.FindByName(IBUser);
		
	ElsIf TypeOf(IBUser) = Type("UUID") Then
		Account = InfoBaseUsers.FindByUUID(IBUser);
	Else
		Account = IBUser;
	EndIf;
	
	If Account = Undefined Then
		Return False;
	EndIf;
	
	Return UserByIDExists(
		Account.UUID);
	
EndFunction
	
// See UsersInternal.UserByIDExists
//
Function UserByIDExists(UUID,
                                               RefToCurrent = Undefined,
                                               FoundUser = Undefined,
                                               ServiceUserID = False) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("RefToCurrent", RefToCurrent);
	Query.SetParameter("UUID", UUID);
	Query.Text = 
	"SELECT
	|	Users.Ref AS User
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID = &UUID
	|	AND Users.Ref <> &RefToCurrent";
	
	Result = False;
	FoundUser = Undefined;
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		FoundUser = Selection.User;
		Result = True;
		FindAmbiguousIBUsers(Undefined, UUID);
	EndIf;
	
	Return Result;
	
EndFunction

// See UsersInternal.AdministratorRolesAvailable
//
Function AdministratorRolesAvailable(IBUser = Undefined) Export
	
	If IBUser = Undefined
	 Or IBUser = InfoBaseUsers.CurrentUser() Then
	
		// APK:336-off Do not replace with roles available. This is a special verification of administrator roles.
		//@skip-check using-isinrole
		Return IsInRole(Metadata.Roles.FullAccess)
		     //@skip-check using-isinrole
		     And (IsInRole(Metadata.Roles.SystemAdministrator)
		        Or DataSeparationEnabled() );
		// APK:336-on
	EndIf;
	
	Return IBUser.Roles.Contains(Metadata.Roles.FullAccess)
	     And (IBUser.Roles.Contains(Metadata.Roles.SystemAdministrator)
	        Or DataSeparationEnabled() );
	
EndFunction

// See Common.DataSeparationEnabled
//
Function DataSeparationEnabled() Export
	
	Return MobileWarehouseKeeperWorkspaceCached.DataSeparationEnabled();
	
EndFunction

// See UsersInternal.UnspecifiedUserProperties
//
Function UnspecifiedUserProperties() Export
	
	SetPrivilegedMode(True);
	
	Properties = New Structure;
	Properties.Insert("Ref", Undefined);
	
	Properties.Insert("StandardRef", Catalogs.Users.GetRef(
		New UUID("aa00559e-ad84-4494-88fd-f0826edc46f0")));
	
	Properties.Insert("FullName", UnspecifiedUserFullName());
	
	Properties.Insert("FullNameForSearch", "<" + NStr("vi = 'Chưa chỉ ra';
														|ru = 'Не указан';
														|en = 'Not specified'; fa = 'مشخص نشده';
														|it = 'Non specificato';
														|pl = 'Nie określony';
														|tr = 'Belirtilmemiş'") + ">");
	
	// Search by a unique identifier.
	Query = New Query;
	Query.SetParameter("Ref", Properties.StandardRef);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Ref = &Ref";
	
	BeginTransaction();
	Try
		If Query.Execute().IsEmpty() Then
			Query.SetParameter("FullName", Properties.FullNameForSearch);
			Query.Text =
			"SELECT TOP 1
			|	Users.Ref
			|FROM
			|	Catalog.Users AS Users
			|WHERE
			|	Users.Description = &FullName";
			Result = Query.Execute();
			
			If Not Result.IsEmpty() Then
				Selection = Result.Select();
				Selection.Next();
				Properties.Ref = Selection.Ref;
			EndIf;
		Else
			Properties.Ref = Properties.StandardRef;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Properties;
	
EndFunction

// See Users.UnspecifiedUserFullName
//
Function UnspecifiedUserFullName() Export
	
	Return "<" + NStr("vi = 'Chưa chỉ ra';
						|ru = 'Не указан';
						|en = 'Not specified'; fa = 'مشخص نشده';
						|it = 'Non specificato';
						|pl = 'Nie określony';
						|tr = 'Belirtilmedi'") + ">";
	
EndFunction

// See SSLSubsystemsIntegration.OnNoCurrentUserInCatalog
//
Procedure OnNoCurrentUserInCatalog(CreateUser) Export

	If SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		ModuleUsersInternalSaaS = CommonModule("UsersInternalSaaS");
		ModuleUsersInternalSaaS.OnNoCurrentUserInCatalog(CreateUser);
	EndIf;

EndProcedure

// See Users.FindAmbiguousIBUsers
//
Procedure FindAmbiguousIBUsers(Val User,
                                            Val UUID = Undefined,
                                            Val FoundIDs = Undefined,
                                            Val ServiceUserID = False) Export
	
	SetPrivilegedMode(True);
	BlankUUID = BlankUUID();
	
	If TypeOf(UUID) <> Type("UUID")
	 Or UUID = BlankUUID Then
		
		UUID = Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("BlankUUID", BlankUUID);
	
	If User = Undefined And UUID = Undefined Then
		Query.Text =
		"SELECT
		|	Users.IBUserID AS AmbiguousID
		|FROM
		|	Catalog.Users AS Users
		|
		|GROUP BY
		|	Users.IBUserID
		|
		|HAVING
		|	Users.IBUserID <> &BlankUUID AND
		|	COUNT(Users.Ref) > 1";
		
	ElsIf UUID <> Undefined Then
		
		Query.SetParameter("UUID", UUID);
		Query.Text =
		"SELECT
		|	Users.IBUserID AS AmbiguousID
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.IBUserID = &UUID";
	Else
		Query.SetParameter("User", User);
		Query.Text =
		"SELECT
		|	Users.IBUserID AS AmbiguousID
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.IBUserID IN
		|			(SELECT
		|				CatalogUsers.IBUserID
		|			FROM
		|				Catalog.Users AS CatalogUsers
		|			WHERE
		|				CatalogUsers.Ref = &User
		|				AND CatalogUsers.IBUserID <> &BlankUUID)";
		
		If TypeOf(User) = Type("CatalogRef.ExternalUsers") Then
			Query.Text = StrReplace(Query.Text,
				"Catalog.Users AS CatalogUsers",
				"Catalog.ExternalUsers AS CatalogUsers");
		EndIf;
	EndIf;
	
	If ServiceUserID Then
		Query.Text = StrReplace(Query.Text,
			"IBUserID",
			"ServiceUserID");
	EndIf;
	
	Upload0 = Query.Execute().Unload();
	
	If User = Undefined And UUID = Undefined Then
		If Upload0.Count() = 0 Then
			Return;
		EndIf;
	Else
		If Upload0.Count() < 2 Then
			Return;
		EndIf;
	EndIf;
	
	AmbiguousIDs = Upload0.UnloadColumn("AmbiguousID");
	
	Query = New Query;
	Query.SetParameter("AmbiguousIDs", AmbiguousIDs);
	Query.Text =
	"SELECT
	|	AmbiguousIDs.AmbiguousID AS AmbiguousID,
	|	AmbiguousIDs.User AS User
	|FROM
	|	(SELECT
	|		Users.IBUserID AS AmbiguousID,
	|		Users.Ref AS User
	|	FROM
	|		Catalog.Users AS Users
	|	WHERE
	|		Users.IBUserID IN(&AmbiguousIDs)) AS AmbiguousIDs
	|
	|ORDER BY
	|	AmbiguousIDs.AmbiguousID,
	|	AmbiguousIDs.User";
	
	Result = Query.Execute().Unload();
	
	ErrorDescription = "";
	CurrentAmbiguousID = Undefined;
	
	For Each TableRow In Result Do
		If TableRow.AmbiguousID <> CurrentAmbiguousID Then
			CurrentAmbiguousID = TableRow.AmbiguousID;
			If TypeOf(FoundIDs) = Type("Map") Then
				CurrentUsers = New Array;
				FoundIDs.Insert(CurrentAmbiguousID, CurrentUsers);
			Else
				CurrentIBUser = InfoBaseUsers.CurrentUser();
				
				If CurrentIBUser.UUID <> CurrentAmbiguousID Then
					CurrentIBUser =
						InfoBaseUsers.FindByUUID(
							CurrentAmbiguousID);
				EndIf;
				
				If CurrentIBUser = Undefined Then
					LoginName = "<" + NStr("vi = 'không tìm thấy';
											|ru = 'не найден';
											|en = 'not found'; fa = 'not found';
											|it = 'non trovato';
											|pl = 'nie znaleziono';
											|tr = 'bulunamadı'") + ">";
				Else
					LoginName = CurrentIBUser.Name;
				EndIf;
				
				If ServiceUserID Then
					ErrorDescription = ErrorDescription + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Người sử dụng dịch vụ có tên định danh ""%1""
						           |tương ứng với nhiều hơn một phần tử trong danh mục:';
						           |ru = 'Пользователю сервиса с идентификатором ""%1""
						           |соответствует более одного элемента в справочнике:';
						           |en = 'The service user with ID ""%1""
						           |is mapped to multiple catalog items:'; fa = 'The service user with ID ""%1""
						           |is mapped to multiple catalog items:';
						           |it = 'All''utente con identificatore ""%1""
						           |corrisponde più di un elemento nell''elenco:';
						           |pl = 'Użytkownik usługi z identyfikatorem ""%1""
						           | odpowiada więcej niż jednemu elementowi w katalogu:';
						           |tr = '""%1"" tanımlayıcısı olan servis kullanıcısı 
						           | kılavuzdaki birden fazla öğe ile uyumludur:'"),
						CurrentAmbiguousID);
				Else
					ErrorDescription = ErrorDescription + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Người sử dụng CSTT ""%1"" với tên định danh ""%2""
						           |tương ứng với nhiều hơn một phần tử trong danh mục:';
						           |ru = 'Пользователю ИБ ""%1"" с идентификатором ""%2""
						           |соответствует более одного элемента в справочнике:';
						           |en = 'Infobase user ""%1"" with ID ""%2""
						           |is mapped to multiple catalog items:'; fa = 'Infobase user ""%1"" with ID ""%2""
						           |is mapped to multiple catalog items:';
						           |it = 'All''utente del DB ""%1"" con identificatore ""%2""
						           |corrisponde più di un elemento nell''elenco:';
						           |pl = 'Użytkownik IB ""%1"" z identyfikatorem ""%2""
						           | pasuje do więcej niż jednego elementu w katalogu:';
						           |tr = '%1Tanımlayıcı olan 
						           |VT kullanıcısı, %2kataloğunda birden fazla öğeye karşılık gelir:'"),
						LoginName,
						CurrentAmbiguousID);
				EndIf;
				ErrorDescription = ErrorDescription + Chars.LF;
			EndIf;
		EndIf;
		
		If TypeOf(FoundIDs) = Type("Map") Then
			CurrentUsers.Add(TableRow.User);
		Else
			ErrorDescription = ErrorDescription + "- "
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '""%1"" %2';
						|ru = '""%1"" %2';
						|en = '""%1"" %2'; fa = '""%1"" %2';
						|it = '""%1"" %2';
						|pl = '""%1"" %2';
						|tr = '""%1"" %2'"),
					TableRow.User,
					GetURL(TableRow.User)) + Chars.LF;
		EndIf;
	EndDo;
	
	If TypeOf(FoundIDs) <> Type("Map") Then
		Raise ErrorDescription;
	EndIf;
	
EndProcedure

// See WorkplaceOfWarehouseWorkerApplicationInterface.FindCellByBarcode
//
Function FindCellByBarcode(Warehouse, Premise, CellBarcode, ThisIsScan = False) Export
	
	ObjectsManagers = New Array();
	ObjectsManagers.Add(Catalogs.StorageBins.EmptyRef());
	
	If ThisIsScan Then
		ReferencesArrray = GetLinkFromBarcodeOfTabularDocument(CellBarcode,
			ObjectsManagers);
	Else
		ReferencesArrray = New Array;
	EndIf;
	
	If ReferencesArrray.Count() = 0 Then
		Return FindCellByCode(Warehouse, Premise, CellBarcode);
	Else
		
		CellParameters_ = New Structure;
		CellDetails = ObjectAttributesValues(ReferencesArrray[0], "Code, StorageBinType, IsFolder");
		
		If CellDetails.IsFolder Then
			CellParameters_.Insert("ReturnCode", 0);
			Return CellParameters_;
		Else
			CellParameters_.Insert("ReturnCode", 1);
			CellParameters_.Insert("Cell", ReferencesArrray[0]);
			CellParameters_.Insert("CellType", CellDetails.StorageBinType);
			CellParameters_.Insert("CellCode", CellDetails.Code);
			CellParameters_.Insert("CellBarcode", CellBarcode);
			
			Return CellParameters_;
		EndIf;
		
	EndIf;
	
EndFunction

// See BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument
//
Function GetLinkFromBarcodeOfTabularDocument(Barcode, Managers = Undefined) Export
	
	If Not StringFunctionsClientServer.OnlyNumbersInString(Barcode, False, False)
		Or TrimAll(Barcode) = "" Then
		Return New Array;
	EndIf;
	
	BarcodeInHexadecimal = ConvertDecimalToHexadecimalNotation(Number(Barcode));
	While StrLen(BarcodeInHexadecimal) < 32 Do
		BarcodeInHexadecimal = "0" + BarcodeInHexadecimal;
	EndDo;
	
	Id =
	        Mid(BarcodeInHexadecimal, 1,  8)
	+ "-" + Mid(BarcodeInHexadecimal, 9,  4)
	+ "-" + Mid(BarcodeInHexadecimal, 13, 4)
	+ "-" + Mid(BarcodeInHexadecimal, 17, 4)
	+ "-" + Mid(BarcodeInHexadecimal, 21, 12);
	
	If StrLen(Id) <> 36 Then
		Return New Array;
	EndIf;
	
	If Managers = Undefined Then
		ObjectsManagers = New Array();
		For Each MetadataItem In Metadata.Documents Do
			ObjectsManagers.Add(Documents[MetadataItem.Name]);
		EndDo;
	Else
		ObjectsManagers = New Array();
		For Each EmptyRef In Managers Do
			
			RefType = TypeOf(EmptyRef);
#If Not MobileStandaloneServer Then
			If Documents.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Documents[EmptyRef.Metadata().Name]);
				
			ElsIf Catalogs.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Catalogs[EmptyRef.Metadata().Name]);
				
			ElsIf Tasks.AllRefsType(RefType).ContainsType(RefType) Then	
				ObjectsManagers.Add(Tasks[EmptyRef.Metadata().Name]);
				
			ElsIf BusinessProcesses.AllRefsType(RefType).ContainsType(RefType) Then	
				ObjectsManagers.Add(BusinessProcesses[EmptyRef.Metadata().Name]);
				
			ElsIf ChartsOfCharacteristicTypes.AllRefsType(RefType).ContainsType(RefType) Then
				ObjectsManagers.Add(ChartsOfCharacteristicTypes[EmptyRef.Metadata().Name]);
				
			Else
				ExceptionText = NStr("ru = 'Ошибка распознавания штрихкода: тип ""%Type%"" не поддерживается.';
									|vi = 'Barcode recognition error: type ""%Type%"" is not supported.';
									|en = 'Barcode recognition error: type ""%Type%"" is not supported.'; fa = 'Barcode recognition error: type ""%Type%"" is not supported.';
									|it = 'Errore di riconoscimento del codice a barre: il tipo ""%Type%"" non è supportato.';
									|pl = 'Błąd rozpoznawania kodu kreskowego: typ ""%Type%"" nie jest obsługiwany.';
									|tr = 'Barkod tanıma hatası: ""%Type%"" türü desteklenmiyor.'");
				ExceptionText = StrReplace(ExceptionText,"%Type%",RefType);
				
				Raise ExceptionText;
			EndIf;
#Else
			If Documents.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Documents[EmptyRef.Metadata().Name]);
				
			ElsIf Catalogs.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Catalogs[EmptyRef.Metadata().Name]);
				
			ElsIf ChartsOfCharacteristicTypes.AllRefsType(RefType).ContainsType(RefType) Then
				ObjectsManagers.Add(ChartsOfCharacteristicTypes[EmptyRef.Metadata().Name]);
				
			Else
				ExceptionText = NStr("ru = 'Ошибка распознавания штрихкода: тип ""%Type%"" не поддерживается.';
									|vi = 'Barcode recognition error: type ""%Type%"" is not supported.';
									|en = 'Barcode recognition error: type ""%Type%"" is not supported.'; fa = 'Barcode recognition error: type ""%Type%"" is not supported.';
									|it = 'Errore di riconoscimento del codice a barre: il tipo ""%Type%"" non è supportato.';
									|pl = 'Błąd rozpoznawania kodu kreskowego: typ ""%Type%"" nie jest obsługiwany.';
									|tr = 'Barkod tanıma hatası: ""%Type%"" türü desteklenmiyor.'");
				ExceptionText = StrReplace(ExceptionText,"%Type%",RefType);
				
				Raise ExceptionText;
			EndIf;
#EndIf
			
		EndDo;
	EndIf;
	
	Query = New Query;
	
	ReferencesArrray = New Array;
	FirstQuery = True;
	For Each Manager In ObjectsManagers Do
		
		Try
			Ref = Manager.GetRef(New UUID(Id));
		Except
			Continue;
		EndTry;
		
		RefMetadata = Ref.Metadata();
		If Not AccessRight("Read", RefMetadata) Then
			Continue;
		EndIf;
		
		ReferencesArrray.Add(Ref);
		
		If FirstQuery Then
			Query.Text = Query.Text +
			"SELECT ALLOWED Table.Ref AS Ref
			|FROM &TheMetadataLinksToTheFullName AS Table
			|WHERE Ref IN (&ReferencesArrray)
			|";
		Else	
			Query.Text = Query.Text + 
			"UNION ALL
			|
			|SELECT Table.Ref AS Ref
			|FROM &TheMetadataLinksToTheFullName AS Table
			|WHERE Ref IN (&ReferencesArrray)
			|";
		EndIf;

		Query.Text = StrReplace(Query.Text, "&TheMetadataLinksToTheFullName", RefMetadata.FullName());
		FirstQuery = False;
		
	EndDo;
	
	If Not FirstQuery Then
		Query.Parameters.Insert("ReferencesArrray", ReferencesArrray);
		Return Query.Execute().Unload().UnloadColumn("Ref");
	Else
		Return New Array;
	EndIf;
	
EndFunction

// See WorkplaceOfWarehouseWorkerApplicationInterface.FindCellByCode
//
Function FindCellByCode(Warehouse, Premise, CellCode) Export
	
	CellParameters_ = New Structure("ReturnCode", 1);
	CellParameters_.Insert("Cell", Catalogs.StorageBins.EmptyRef());
	CellParameters_.Insert("CellType", Enums.TypesOfStorageCells.EmptyRef());
	CellParameters_.Insert("CellCode", CellCode);
	CellParameters_.Insert("CellBarcode", "");
	
	Query = New Query;
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Code", CellCode);
	
	Query.Text =
	"SELECT TOP 1
	|	StorageBins.Ref AS Cell,
	|	StorageBins.StorageBinType,
	|	StorageBins.Code AS CellCode,
	|	StorageBins.IsFolder AS IsFolder
	|FROM
	|	Catalog.StorageBins AS StorageBins
	|WHERE
	|	StorageBins.Owner = &Warehouse
	|	AND StorageBins.Code = &Code
	|	AND StorageBins.Premise = &Premise";
	
	QueryResult = Query.Execute();
	CellTable = QueryResult.Unload();
	
	If CellTable.Count() = 0 Then
		CellParameters_.ReturnCode = 0;
		Return CellParameters_;
	Else
		
		If CellTable[0].IsFolder Then
			CellParameters_.ReturnCode = 0;
			Return CellParameters_;
		Else
			CellParameters_.Cell = CellTable[0].Cell;
			CellParameters_.CellType = CellTable[0].StorageBinType;
			CellParameters_.CellBarcode = NumericCodeFromLink(CellTable[0].Cell);
			Return CellParameters_;
		EndIf;
		
	EndIf;
	
EndFunction

// See BarcodingOfPrintForms.NumericCodeFromLink
//
Function NumericCodeFromLink(Ref) Export
	HexadecimalNumber = StrReplace(String(Ref.UUID()),"-","");
	Return ConvertFromHexadecimalToDecimal(HexadecimalNumber);
EndFunction

// See ProductsClientServer.SeriesSpecificationParameters
// 
Function ItemClientServerSerialSpecificationParameters() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("UseItemsBatch",Undefined);
	ParametersStructure.Insert("UseCostAccountingByBatches",Undefined);
	ParametersStructure.Insert("WarehouseTransactions",New Array); 
	ParametersStructure.Insert("LinkFields", New Array);
	ParametersStructure.Insert("FullObjectName", "");
	
	ParametersStructure.Insert("ReadOnly",False);
	ParametersStructure.Insert("ProductInHeader",False);
	ParametersStructure.Insert("BlockFormData",True);
	ParametersStructure.Insert("NameTSGoods","Goods");
	ParametersStructure.Insert("TSSeriesName","SetOfSeries");
	ParametersStructure.Insert("FieldNameQuantity","Count");
	ParametersStructure.Insert("WarehouseFieldName","Warehouse");
	ParametersStructure.Insert("FieldNameControlledLotReference", Undefined);
	ParametersStructure.Insert("NameOfSenderWarehouseField",Undefined);
	ParametersStructure.Insert("NameOfRecipientWarehouseField",Undefined);
	ParametersStructure.Insert("FieldNameRoom",Undefined);
	ParametersStructure.Insert("ItSWarrant",False);
	ParametersStructure.Insert("ThisIsOrder",False);
	ParametersStructure.Insert("ThisIsAnInvoice",False);
	ParametersStructure.Insert("SeriesOnlyForCostPrice",False);
	ParametersStructure.Insert("ShipmentPlanning",False);
	ParametersStructure.Insert("SelectionPlanning",False);
	ParametersStructure.Insert("PickingCheck",False);
	ParametersStructure.Insert("FactOfSelection",False);
	ParametersStructure.Insert("OrderPreparation",False);
	ParametersStructure.Insert("RegisterSeries", True);
	ParametersStructure.Insert("Date",Date(1,1,1));
	ParametersStructure.Insert("FieldNamesWithSuffix",New Structure);
	ParametersStructure.Insert("FieldNamesStatusOfSeriesIndication",New Array);
	ParametersStructure.Insert("MatchesSeriesFieldNameToStatusOfSeriesIndication",New Map);
	ParametersStructure.Insert("FieldNamesForOrderDefinition",New Array);
	ParametersStructure.Insert("AdditionalFieldNames",New Array);
	ParametersStructure.Insert("UseBinLocationWarehousing",False);
	ParametersStructure.Insert("NameOfValueSourceInObjectForm","Object");
	ParametersStructure.Insert("SelectingRowsToCheck", Undefined);
	ParametersStructure.Insert("OnlySeriesTakingIntoAccountLeftovers", False);
	ParametersStructure.Insert("SpecialCheckingOfSeriesIndicationStatuses", False);
	ParametersStructure.Insert("NeedToRoundUpQuantity", True);
	ParametersStructure.Insert("QueryOptions", New Structure);
	ParametersStructure.Insert("SeriesWhenPlanningShipmentVHFSeriesAreIndicated", False);
	ParametersStructure.Insert("ParametersForGettingDataFromRegisters", New Structure);
	ParametersStructure.Insert("ProductLocationsAreUsed", False);
	ParametersStructure.Insert("SeriesCanBeSpecifiedInRefinementTable", False);
	ParametersStructure.Insert("IndependentCalculationOfSeveralStatusesOfSeriesIndicationIsRequired", False);
	
	ParametersStructure.Insert("DocumentOperation_", Undefined);
	
	Return ParametersStructure;
	
EndFunction

// See CommonClientServer.ValueInArray
//
Function ValueInArray(Val Value) Export
	
	Result = New Array;
	Result.Add(Value);
	Return Result;
	
EndFunction

// See CommonInternalClientServer.PredefinedValueNotFoundErrorText
// 
// Parameters:
//  FullPredefinedItemName - String
//  
// Returns:
//  String
// 
Function UseStandardGettingPredefinedItemFunction(FullPredefinedItemName) Export
	
	// The standard function of the platform is used to get:
	//  - empty links; 
	//  - enumeration values;
	//  - business process route points.
	
	Return StrEndsWith(Upper(FullPredefinedItemName), ".EMPTYREF")
		Or StrStartsWith(Upper(FullPredefinedItemName), "ENUM.")
		Or StrStartsWith(Upper(FullPredefinedItemName), "BUSINESSPROCESS.");
	
EndFunction
	
// See CommonInternalClientServer.PredefinedItemNameByFields
// 
// Parameters:
//  FullPredefinedItemName - String
//  
// Returns:
//  Structure:
//       * FullMetadataObjectName - String
//       * PredefinedItemName - String
// 
Function PredefinedItemNameByFields(FullPredefinedItemName) Export
	
	FullNameParts1 = StrSplit(FullPredefinedItemName, ".");
	If FullNameParts1.Count() <> 3 Then 
		Raise PredefinedValueNotFoundErrorText(FullPredefinedItemName);
	EndIf;
	
	FullMetadataObjectName = Upper(FullNameParts1[0] + "." + FullNameParts1[1]);
	PredefinedItemName = FullNameParts1[2];
	
	Result = New Structure;
	Result.Insert("FullMetadataObjectName", FullMetadataObjectName);
	Result.Insert("PredefinedItemName", PredefinedItemName);
	
	Return Result;
	
EndFunction

// See CommonInternalClientServer.PredefinedItem
// 
// Parameters:
//  FullPredefinedItemName - String
//  PredefinedItemFields - String
//  PredefinedValues - Arbitrary
//  
// Returns:
//  Arbitrary
// 
Function GeneralPurposeUtilityClientServerPredefinedElement(FullPredefinedItemName, PredefinedItemFields, PredefinedValues) Export
	
	// If the enumeration does not exist in the metadata.
	If PredefinedValues = Undefined Then 
		Return Undefined;
	EndIf;
	
	// If the predefined one is not in the metadata, or it is in the metadata, but not created in the information security.
	Result = PredefinedValues.Get(PredefinedItemFields.PredefinedItemName);
	If Result = Undefined Or Result = Null Then 
		Return Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

// See CommonClientServer.SetDynamicListParameter
// 
Procedure SetDynamicListParameter(List, ParameterName, Value, Use = True) Export
	
	DataCompositionParameterValue = List.Parameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	If DataCompositionParameterValue <> Undefined Then
		If Use And DataCompositionParameterValue.Value <> Value Then
			DataCompositionParameterValue.Value = Value;
		EndIf;
		If DataCompositionParameterValue.Use <> Use Then
			DataCompositionParameterValue.Use = Use;
		EndIf;
	EndIf;
	
EndProcedure

// See CommonInternalClientServer.PredefinedValueNotFoundErrorText
// 
// Parameters:
//  FullPredefinedItemName - String
//  
// Returns:
//  String
// 
Function PredefinedValueNotFoundErrorText(FullPredefinedItemName) Export
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Предопределенное значение ""%1"" не существует.';
			|vi = 'Predefined value ""%1"" does not exist.';
			|en = 'Predefined value ""%1"" does not exist.'; fa = 'Predefined value ""%1"" does not exist.';
			|it = 'Valore predeterminato ""%1"" inesistente.';
			|pl = 'Predefiniowana wartość ""%1"" nie istnieje.';
			|tr = 'Önceden tanımlanmış ""%1"" değeri mevcut değil.'"), FullPredefinedItemName);
	
EndFunction
	
// See CommonClientServer.BlankUUID
// 
Function BlankUUID() Export
	
	Return New UUID("00000000-0000-0000-0000-000000000000");
	
EndFunction

// See CommonClientServer.CheckParameter
// 
Procedure CheckParameter(Val NameOfAProcedureOrAFunction, Val ParameterName, Val ParameterValue, 
	Val ExpectedTypes, Val PropertiesTypesToExpect = Undefined, Val ExpectedValues = Undefined) Export
	
	Context = "CommonClientServer.CheckParameter";
	Validate(TypeOf(NameOfAProcedureOrAFunction) = Type("String"), 
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Giá trị tham số không hợp lệ %1.';
				|ru = 'Недопустимое значение параметра %1.';
				|en = 'Invalid value of the %1 parameter.'; fa = 'Invalid value of the %1 parameter.';
				|it = 'Valore non disponibile del parametro %1.';
				|pl = 'Niedopuszczalna wartość parametru %1';
				|tr = '%1 parametre değeri geçersiz.'"), "NameOfAProcedureOrAFunction"), 
		Context);
	Validate(TypeOf(ParameterName) = Type("String"), 
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Giá trị tham số không hợp lệ %1.';
				|ru = 'Недопустимое значение параметра %1.';
				|en = 'Invalid value of the %1 parameter.'; fa = 'Invalid value of the %1 parameter.';
				|it = 'Valore non disponibile del parametro %1.';
				|pl = 'Niedopuszczalna wartość parametru %1';
				|tr = '%1 parametre değeri geçersiz.'"), "ParameterName"), 
			Context);
	
	IsCorrectType = ExpectedTypeValue(ParameterValue, ExpectedTypes);
	Validate(IsCorrectType <> Undefined, 
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Giá trị tham số không hợp lệ %1.';
				|ru = 'Недопустимое значение параметра %1.';
				|en = 'Invalid value of the %1 parameter.'; fa = 'Invalid value of the %1 parameter.';
				|it = 'Valore non disponibile del parametro %1.';
				|pl = 'Niedopuszczalna wartość parametru %1';
				|tr = '%1 parametre değeri geçersiz.'"), "ExpectedTypes"),
		Context);
		
	If ParameterValue = Undefined Then
		PresentationOfParameterValue = "Undefined";
	ElsIf TypeOf(ParameterValue) = Type("BinaryData") And ParameterValue.Size() = 0 Then
		PresentationOfParameterValue = "";
	Else
		PresentationOfParameterValue = String(ParameterValue);
	EndIf;
	
	Validate(IsCorrectType,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Giá trị không hợp lệ cho tham số %1 trong %2.
			           |Dự kiến: %3; giá trị chuyển: %4 (kiểu %5).';
			           |ru = 'Недопустимое значение параметра %1 в %2. 
			           |Ожидалось: %3; передано значение: %4 (тип %5).';
			           |en = 'Invalid value of the %1 parameter in %2.
			           |Expected value: %3, passed value: %4 (type: %5).'; fa = 'Invalid value of the %1 parameter in %2.
			           |Expected value: %3, passed value: %4 (type: %5).';
			           |it = 'Valore del parametro %1 in %2 non valido.
			           |Atteso: %3; valore immesso: %4 (tipo %5).';
			           |pl = 'Niedopuszczalna wartość parametrów %1 w %2. 
			           |Było oczekiwane: %3; przekazano wartość: %4 (typ %5).';
			           |tr = '%1''deki %2 parametrenin geçersiz değeri.
			           |Beklenen %5 ; gönderilen değer %3 (%4 tür).'"),
			ParameterName, NameOfAProcedureOrAFunction, TypesPresentation(ExpectedTypes), 
			PresentationOfParameterValue,
		TypeOf(ParameterValue)));
	
	If TypeOf(ParameterValue) = Type("Structure") And PropertiesTypesToExpect <> Undefined Then
		
		Validate(TypeOf(PropertiesTypesToExpect) = Type("Structure"), 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Giá trị tham số không hợp lệ %1.';
					|ru = 'Недопустимое значение параметра %1.';
					|en = 'Invalid value of the %1 parameter.'; fa = 'Invalid value of the %1 parameter.';
					|it = 'Valore non disponibile del parametro %1.';
					|pl = 'Niedopuszczalna wartość parametru %1';
					|tr = '%1 parametre değeri geçersiz.'"), "NameOfAProcedureOrAFunction"),
			Context);
		
		For Each Property In PropertiesTypesToExpect Do
			
			ExpectedPropertyName = Property.Key;
			ExpectedPropertyType = Property.Value;
			PropertyValue = Undefined;
			
			Validate(ParameterValue.Property(ExpectedPropertyName, PropertyValue), 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Giá trị tham số không hợp lệ %1 (Cấu trúc) trong %2.
					           |Thuộc tính dự kiến trong cấu trúc %3 (kiểu %4).';
					           |ru = 'Недопустимое значение параметра %1 (Структура) в %2. 
					           |В структуре ожидалось свойство %3 (тип %4).';
					           |en = 'Invalid value of parameter %1 (Structure) in %2.
					           |Expected value: %3 (type: %4).'; fa = 'Invalid value of parameter %1 (Structure) in %2.
					           |Expected value: %3 (type: %4).';
					           |it = 'Valore del parametro %1 (Struttura) in %2 non valido.
					           |Nella struttura era attesa la proprietà %3 (tipo %4).';
					           |pl = 'Niedopuszczalna wartość parametrów %1 (Struktura) w %2. 
					           |W strukturze była oczekiwana właściwość %3 (typ %4).';
					           |tr = '%2'' de geçersiz parametre değeri %1 (Yapı). Yapıda (%4 tipi) 
					           | %3 özellik beklenmiştir.'"), 
					ParameterName, NameOfAProcedureOrAFunction, ExpectedPropertyName, ExpectedPropertyType));
			
			IsCorrectType = ExpectedTypeValue(PropertyValue, ExpectedPropertyType);
			Validate(IsCorrectType, 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Giá trị thuộc tính không hợp lệ %1 trong tham số %2 (Cấu trúc) trong %3.
					           |Dự kiến: %4; giá trị chuyển: %5 (kiểu %6).';
					           |ru = 'Недопустимое значение свойства %1 в параметре %2 (Структура) в %3. 
					           |Ожидалось: %4; передано значение: %5 (тип %6).';
					           |en = 'Invalid value of property %1 in parameter %2 (Structure) in %3.
					           |Expected value: %4; passed value: %5 (type: %6).'; fa = 'Invalid value of property %1 in parameter %2 (Structure) in %3.
					           |Expected value: %4; passed value: %5 (type: %6).';
					           |it = 'Valore della proprietà %1 nel parametro %2 (Struttura) in %3 non valido.
					           |Atteso: %4; valore immesso: %5 (tipo %6).';
					           |pl = 'Niedopuszczalna wartość właściwości %1 w parametrze %2 (Struktura) w %3. 
					           |Było oczekiwane: %4; przekazano wartość: %5 (typ %6).';
					           |tr = '%1''deki %2 parametre (Yapı) %3 öğesindeki geçersiz özellik değeri.
					           | Beklenen:%4 ; iletilen değer: %5 (%6 tür).'"), 
					ExpectedPropertyName, ParameterName,	NameOfAProcedureOrAFunction,
					TypesPresentation(ExpectedTypes), 
					?(PropertyValue <> Undefined, PropertyValue, NStr("vi = 'Không xác định';
																		|ru = 'Неопределено';
																		|en = 'Undefined'; fa = 'تعریف‌نشده';
																		|it = 'Indefinito';
																		|pl = 'Undefined';
																		|tr = 'Tanımlanmamış'")),
				TypeOf(PropertyValue)));
			
		EndDo;
	EndIf;
	
	If ExpectedValues <> Undefined Then
		If TypeOf(ExpectedValues) = Type("String") Then
			ExpectedValues = StrSplit(ExpectedValues, ",");
		EndIf; 
		Validate(ExpectedValues.Find(ParameterValue) <> Undefined,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Giá trị tham số không hợp lệ %1 trong %2.
				           |Dự kiến: %3; 
				           |giá trị đã chuyển: %4 (kiểu %5).';
				           |ru = 'Недопустимое значение параметра %1 в %2. 
				           |Ожидалось: %3; 
				           |передано значение: %4 (тип %5).';
				           |en = 'Invalid value of the %1 parameter in %2.
				           |Expected value: %3.
				           |Passed value: %4 (type: %5).'; fa = 'Invalid value of the %1 parameter in %2.
				           |Expected value: %3.
				           |Passed value: %4 (type: %5).';
				           |it = 'Valore non disponibile del parametro %1 in %2.
				           |Previsto: %3; 
				           |valore dato: %4 (tipo %5).';
				           |pl = 'Niedopuszczalna wartość parametrów %1 w %2. 
				           |Było oczekiwane: %3; 
				           |przekazano wartość: %4 (typ %5).';
				           |tr = '%2''deki %1 parametrenin geçersiz değeri. 
				           |Beklenen: %3; 
				           |aktarılan değer: %4 (%5 türü).'"),
				ParameterName, NameOfAProcedureOrAFunction, StrConcat(ExpectedValues, ","), 
				PresentationOfParameterValue, TypeOf(ParameterValue)));
	EndIf;
	
EndProcedure

// See CommonClientServer.Validate
// 
Procedure Validate(Val Condition, Val Message = "", Val CheckContext = "") Export
	
	If Condition <> True Then
		
		If IsBlankString(Message) Then
			ExceptionText = NStr("vi = 'Giao dịch không hợp lệ';
								|ru = 'Недопустимая операция';
								|en = 'Invalid operation.'; fa = 'Invalid operation.';
								|it = 'Operazione non permessa';
								|pl = 'Niedopuszczalna operacja';
								|tr = 'Geçersiz işlem'"); // Assertion failed
		Else
			ExceptionText = Message;
		EndIf;
		
		If Not IsBlankString(CheckContext) Then
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 trong %2';
					|ru = '%1 в %2';
					|en = '%1 in %2'; fa = '%1 in %2';
					|it = '%1 in %2';
					|pl = '%1 do %2';
					|tr = '%2''da %1'"), ExceptionText, CheckContext);
		EndIf;
		
		Raise(ExceptionText, ErrorCategory.ConfigurationError);
		
	EndIf;
	
EndProcedure

// See CommonClientServer.HasAttributeOrObjectProperty
// 
Function HasAttributeOrObjectProperty(Object, AttributeName) Export
	
	UniqueKey   = New UUID;
	AttributeStructure = New Structure(AttributeName, UniqueKey);
	FillPropertyValues(AttributeStructure, Object);
	
	Return AttributeStructure[AttributeName] <> UniqueKey;
	
EndFunction

// See UsersInternalClientServer.CurrentUser
// 
// Parameters:
//  AuthorizedUser - CatalogRef.Users
// 
// Returns:
//  CatalogRef.Users
// 
Function UsersServiceClientServerCurrentUser(AuthorizedUser) Export
	
	If TypeOf(AuthorizedUser) <> Type("CatalogRef.Users") Then
		ErrorText = NStr("ru = 'Невозможно получить текущего пользователя
									|в сеансе внешнего пользователя.';
									|vi = 'Cannot get the current external user
									|in the external user session.';
									|en = 'Cannot get the current external user
									|in the external user session.'; fa = 'Cannot get the current external user
									|in the external user session.';
									|it = 'Impossibile recuperare l''utente corrente
									|nella sessione dell''utente esterno.';
									|pl = 'Nie można uzyskać bieżącego użytkownika
									|w sesji użytkownika zewnętrznego.';
									|tr = 'Geçerli kullanıcı
									| harici kullanıcı oturumunda alınamaz.'");
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	Return AuthorizedUser;
	
EndFunction

// See ProductsClientServer.ItIsNecessaryToRegisterSeries
// 
Function ItIsNecessaryToRegisterSeries(SeriesSpecificationParameters) Export
	
	If (SeriesSpecificationParameters.ShipmentPlanning
		   		Or SeriesSpecificationParameters.SelectionPlanning  
		   		Or SeriesSpecificationParameters.OrderPreparation)
				And Not SeriesSpecificationParameters.FactOfSelection Then
		
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// See BarcodingOfItemsServer.SeriesInformationFromBarcode
//
Function SeriesInformationFromBarcode(Val Barcode, ThereIsNumberField, ThereIsFieldValidUntil) Export
	Result = New Structure;
	Result.Insert("Number", "");
	Result.Insert("ValidUntil_", '00010101');
	Result.Insert("HasError", False);
	
	Barcode = TrimAll(Barcode);
	
	If ThereIsNumberField Then
		
		Result.Number = Barcode;
		
		If ThereIsFieldValidUntil Then
			
			If StrLen(Result.Number) >= 6 Then
				
				If StrLen(Result.Number) >= 8 Then
					ExpirationDateFromBarcode = Right(Result.Number, 8);
					Result.ValidUntil_		= DateFromBarcodeString(ExpirationDateFromBarcode);
					
					If ValueIsFilled(Result.ValidUntil_) Then
						Result.Number = Left(Result.Number,StrLen(Result.Number) - 8);
					EndIf;	
				EndIf;
				
				If Not ValueIsFilled(Result.ValidUntil_) Then
					
					ExpirationDateFromBarcode = Right(Result.Number, 6);
					Result.ValidUntil_		= DateFromBarcodeString(ExpirationDateFromBarcode);
					
					If ValueIsFilled(Result.ValidUntil_) Then
						Result.Number = Left(Result.Number,StrLen(Result.Number) - 6);
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
	Else
		
		Result.ValidUntil_ = DateFromBarcodeString(Barcode);
		
	EndIf;	
	
	If Not ValueIsFilled(Result.Number)
		And Not ValueIsFilled(Result.ValidUntil_) Then
		
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
		
		MessageToUser(MessageText,,,,Result.HasError);
		
	EndIf;
	
	Return Result;
	
EndFunction

// See CommonClientServer.MessageToUser
// 
Procedure MessageToUser(
		Val MessageToUserText,
		Val DataKey = Undefined,
		Val Field = "",
		Val DataPath = "",
		Cancel = False) Export
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	IsObject = False;
	
#If Not ThinClient And Not WebClient And Not MobileClient Then
	If DataKey <> Undefined
	   And XMLTypeOf(DataKey) <> Undefined Then
		ValueTypeAsString = XMLTypeOf(DataKey).TypeName;
		IsObject = StrFind(ValueTypeAsString, "Object.") > 0;
	EndIf;
#EndIf
	
	If IsObject Then
		Message.SetData(DataKey);
	Else
		Message.DataKey = DataKey;
	EndIf;
	
	If Not IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
		
	Message.Message();
	
	Cancel = True;
	
EndProcedure

// See CommonClientServer.SupplementArray
// 
Procedure SupplementArray(DestinationArray, SourceArray1, UniqueValuesOnly = False) Export
	
	If UniqueValuesOnly Then
		
		UniqueValues = New Map;
		
		For Each Value In DestinationArray Do
			UniqueValues.Insert(Value, True);
		EndDo;
		
		For Each Value In SourceArray1 Do
			If UniqueValues[Value] = Undefined Then
				DestinationArray.Add(Value);
				UniqueValues.Insert(Value, True);
			EndIf;
		EndDo;
		
	Else
		
		For Each Value In SourceArray1 Do
			DestinationArray.Add(Value);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// See AddAndFillLine the Nomenclaturserver module.
//
// Parameters:
//  Table - ValueTable
//  SourceRow - String
// 
Function AddAndFillLine(Table, SourceRow)
	NewRow = Table.Add();
	FillPropertyValues(NewRow, SourceRow);
	Return NewRow;
EndFunction

// See SetRequestParametersBySpecifyingSeriesParameters the Nomenclaturserver module.
//
// Parameters:
//  Query - Query
//  SeriesSpecificationParameters - Arbitrary
// 
Procedure SetRequestParametersBySpecifyingSeriesParameters(Query,SeriesSpecificationParameters)
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.RetailShipment) <> Undefined Then
		Query.SetParameter("RetailShipment", True);
	Else
		Query.SetParameter("RetailShipment", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentToCustomer) <> Undefined Then
		Query.SetParameter("ShipmentToCustomer", True);
	Else
		Query.SetParameter("ShipmentToCustomer", False);
	EndIf;
		
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipComponentsForAssembly) <> Undefined Then
		Query.SetParameter("ShipComponentsForAssembly", True);
	Else
		Query.SetParameter("ShipComponentsForAssembly", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipSetsForDisassembly) <> Undefined Then
		Query.SetParameter("ShipSetsForDisassembly", True);
	Else
		Query.SetParameter("ShipSetsForDisassembly", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentForInternalNeeds) <> Undefined Then
		Query.SetParameter("ShipmentForInternalNeeds", True);
	Else
		Query.SetParameter("ShipmentForInternalNeeds", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentUnderReturnToVendor) <> Undefined Then
		Query.SetParameter("ShipmentUnderReturnToVendor", True);
	Else
		Query.SetParameter("ShipmentUnderReturnToVendor", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentByTransfer) <> Undefined Then
		Query.SetParameter("ShipmentByTransfer", True);
	Else
		Query.SetParameter("ShipmentByTransfer", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceiptFromVendor) <> Undefined Then
		Query.SetParameter("ReceiptFromVendor", True);
	Else
		Query.SetParameter("ReceiptFromVendor", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer) <> Undefined Then
		Query.SetParameter("ReceivingByReturnFromACustomer", True);
	Else
		Query.SetParameter("ReceivingByReturnFromACustomer", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingByTransfer) <> Undefined Then
		Query.SetParameter("ReceivingByTransfer", True);
	Else
		Query.SetParameter("ReceivingByTransfer", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.GoodsReceiptByOtherTransactions) <> Undefined Then
		Query.SetParameter("GoodsReceiptByOtherTransactions", True);
	Else
		Query.SetParameter("GoodsReceiptByOtherTransactions", False);            
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingOfAssembledSets) <> Undefined Then
		Query.SetParameter("ReceivingOfAssembledSets", True);
	Else
		Query.SetParameter("ReceivingOfAssembledSets", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingOfComponentsAfterDisassembly) <> Undefined Then
		Query.SetParameter("ReceivingOfComponentsAfterDisassembly", True);
	Else
		Query.SetParameter("ReceivingOfComponentsAfterDisassembly", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.SurplusesRecord) <> Undefined Then
		Query.SetParameter("SurplusesRecord", True);
	Else
		Query.SetParameter("SurplusesRecord", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShortageRecord) <> Undefined Then
		Query.SetParameter("ShortageRecord", True);
	Else
		Query.SetParameter("ShortageRecord", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.DamageRecord) <> Undefined Then
		Query.SetParameter("DamageRecord", True);
	Else
		Query.SetParameter("DamageRecord", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.Recalculate) <> Undefined Then
		Query.SetParameter("Recalculate", True);
	Else
		Query.SetParameter("Recalculate", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.RecalculationResultRecord) <> Undefined Then
		Query.SetParameter("RecalculationResultRecord", True);
	Else
		Query.SetParameter("RecalculationResultRecord", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.PickingFromStorageBins) <> Undefined Then
		Query.SetParameter("PickingFromStorageBins", True);
	Else
		Query.SetParameter("PickingFromStorageBins", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentControl) <> Undefined Then
		Query.SetParameter("ShipmentControl", True);
	Else
		Query.SetParameter("ShipmentControl", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.PlacementIntoBins) <> Undefined Then
		Query.SetParameter("PlacementIntoBins", True);
	Else
		Query.SetParameter("PlacementIntoBins", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.TransferBetweenWarerooms) <> Undefined Then
		Query.SetParameter("TransferBetweenWarerooms", True);
	Else
		Query.SetParameter("TransferBetweenWarerooms", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipProductsFromProduction) <> Undefined Then
		Query.SetParameter("ShipProductsFromProduction", True);
	Else
		Query.SetParameter("ShipProductsFromProduction", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ProductReceivingFromManufacturing) <> Undefined Then
		Query.SetParameter("ProductReceivingFromManufacturing", True);
	Else
		Query.SetParameter("ProductReceivingFromManufacturing", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.TransferToProductionShipment) <> Undefined Then
		Query.SetParameter("TransferToProductionShipment", True);
	Else
		Query.SetParameter("TransferToProductionShipment", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.TransferToProductionReceiving) <> Undefined Then
		Query.SetParameter("TransferToProductionReceiving", True);
	Else
		Query.SetParameter("TransferToProductionReceiving", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ProductionTransferShipment) <> Undefined Then
		Query.SetParameter("ProductionTransferShipment", True);
	Else
		Query.SetParameter("ProductionTransferShipment", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingByTransfersInProduction) <> Undefined Then
		Query.SetParameter("ReceivingByTransfersInProduction", True);
	Else
		Query.SetParameter("ReceivingByTransfersInProduction", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReturnMaterialsFromProductionShipment) <> Undefined Then
		Query.SetParameter("ReturnMaterialsFromProductionShipment", True);
	Else
		Query.SetParameter("ReturnMaterialsFromProductionShipment", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.AllocationForCosts) <> Undefined Then
		Query.SetParameter("AllocationForCosts", True);
	Else
		Query.SetParameter("AllocationForCosts", False);
	EndIf;
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ConsumptionDuringProduction) <> Undefined Then
		Query.SetParameter("ConsumptionDuringProduction", True);
	Else
		Query.SetParameter("ConsumptionDuringProduction", False);
	EndIf;
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReturnMaterialsFromProductionReceiving) <> Undefined Then
		Query.SetParameter("ReturnMaterialsFromProductionReceiving", True);
	Else
		Query.SetParameter("ReturnMaterialsFromProductionReceiving", False);
	EndIf;
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingInventoryInOperation) <> Undefined Then
		Query.SetParameter("ReceivingInventoryInOperation", True);
	Else
		Query.SetParameter("ReceivingInventoryInOperation", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.DisposalInventoryInOperation) <> Undefined Then
		Query.SetParameter("DisposalInventoryInOperation", True);
	Else
		Query.SetParameter("DisposalInventoryInOperation", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.RecordInventoryInOperation) <> Undefined Then
		Query.SetParameter("RecordInventoryInOperation", True);
	Else
		Query.SetParameter("RecordInventoryInOperation", False);
	EndIf;
	
	For Each AddnlParameter_ In SeriesSpecificationParameters.QueryOptions Do
		Query.SetParameter(AddnlParameter_.Key, AddnlParameter_.Value);
	EndDo;
	
	Query.SetParameter("ShipmentPlanning", SeriesSpecificationParameters.ShipmentPlanning);
	
	Query.SetParameter("SelectionPlanning", SeriesSpecificationParameters.SelectionPlanning);
	
	Query.SetParameter("FactOfSelection", SeriesSpecificationParameters.FactOfSelection);
	
	Query.SetParameter("PickingCheck", SeriesSpecificationParameters.PickingCheck);              
	
	Query.SetParameter("OrderPreparation", SeriesSpecificationParameters.OrderPreparation);
	
	Query.SetParameter("SeriesOnlyForCostPrice", SeriesSpecificationParameters.SeriesOnlyForCostPrice);
	
	Query.SetParameter("Date", SeriesSpecificationParameters.Date);
	
	Query.SetParameter("UseBinLocationWarehousing",SeriesSpecificationParameters.UseBinLocationWarehousing);
	
	Query.SetParameter("Date", SeriesSpecificationParameters.Date);
	Query.SetParameter("ProductInHeader", SeriesSpecificationParameters.ProductInHeader);
	
	Query.SetParameter("OnlySeriesTakingIntoAccountLeftovers", SeriesSpecificationParameters.OnlySeriesTakingIntoAccountLeftovers);
	
	Query.SetParameter("DocumentOperation_", SeriesSpecificationParameters.DocumentOperation_);

EndProcedure

// See ValuesOfDetailsForFillingInParametersForSpecifyingSeries the Nomenclaturserver module.
//
// Parameters:
//  Object - MetadataObject
//  AttributesNames - String
// 
// Returns: 
//  Arbitrary
//  
Function ValuesOfDetailsForFillingInParametersForSpecifyingSeries(Object, AttributesNames)
	
	If Documents.AllRefsType().ContainsType(TypeOf(Object)) Then
		Structure = ObjectAttributesValues(Object, AttributesNames);
	Else
		Structure = New Structure(AttributesNames);
		FillPropertyValues(Structure, Object);
	EndIf;
	If Structure.Property("Date") And Not ValueIsFilled(Structure.Date) Then
		Structure.Date = CurrentSessionDate();
	EndIf;
	If Structure.Property("DateOfShipment") And Not ValueIsFilled(Structure.DateOfShipment) Then
		Structure.DateOfShipment = CurrentSessionDate();
	EndIf;
	Return Structure;
	
EndFunction

// See CheckIfObjectAttributesExist a general-purpose module.
//
// Parameters:
//  FullMetadataObjectName - String
//  ExpressionsToCheck - Arbitrary
// 
// Returns: 
//  Structure:
//       * Error - Boolean
//       * ErrorDescription - String
//  
Function CheckIfObjectAttributesExist(FullMetadataObjectName, ExpressionsToCheck)
	
	ObjectMetadata = MetadataObjectByFullName(FullMetadataObjectName);
	If ObjectMetadata = Undefined Then 
		Return New Structure("Error, ErrorDescription", True, 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối tượng metadata không tồn tại ""%1"".';
					|ru = 'Несуществующий объект метаданных ""%1"".';
					|en = 'Non-existing metadata object: ""%1"".'; fa = 'Non-existing metadata object: ""%1"".';
					|it = 'Несуществующий объект метаданных ""%1"".';
					|pl = 'Non-existing metadata object: ""%1"".';
					|tr = 'Var olmayan meta veri nesnesi: ""%1"".'"), FullMetadataObjectName));
	EndIf;
	
#If MobileStandaloneServer Then
	ErrorText = "";
#Else
	// Allowing a call from the secure mode of external processing or extension.
	// Information about the availability of schema source fields when checking metadata is not secret.
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Schema = New QuerySchema;
	Package = Schema.QueryBatch.Add(Type("QuerySchemaSelectQuery"));
	Operator = Package.Operators.Get(0);
	
	Source = Operator.Sources.Add(FullMetadataObjectName, "Table");
	ErrorText = "";
	
	For Each CurrentExpression In ExpressionsToCheck Do
		
		If Not QuerySchemaSourceFieldAvailable(Source, CurrentExpression) Then 
			ErrorText = ErrorText + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tồn tại trường đối tượng ""%1"".';
					|ru = 'Поле объекта ""%1"" не существует.';
					|en = '""%1"" object field does not exist.'; fa = '""%1"" object field does not exist.';
					|it = 'Campo oggetto ""%1"" inesistente.';
					|pl = '- Pola obiektu ""%1"" nie istnieje.';
					|tr = '""%1"" nesne alanı mevcut değil.'"), CurrentExpression);
		EndIf;
		
	EndDo;
#EndIf
		
	Return New Structure("Error, ErrorDescription", Not IsBlankString(ErrorText), ErrorText);
	
EndFunction

// See ServerManagerModule a general-purpose module.
//
// Parameters:
//  Name - String
// 
// Returns: 
//  MetadataObject
//  
Function ServerManagerModule(Name)
	ObjectFound = False;
	
	NameParts = StrSplit(Name, ".");
	If NameParts.Count() = 2 Then
		
		KindName = Upper(NameParts[0]);
		ObjectName = NameParts[1];
		
		If KindName = Upper("Constants") Then
			If Metadata.Constants.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("InformationRegisters") Then
			If Metadata.InformationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("AccumulationRegisters") Then
			If Metadata.AccumulationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("AccountingRegisters") Then
			If Metadata.AccountingRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("CalculationRegisters") Then
			If Metadata.CalculationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Catalogs") Then
			If Metadata.Catalogs.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Documents") Then
			If Metadata.Documents.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Reports") Then
			If Metadata.Reports.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("DataProcessors") Then
			If Metadata.DataProcessors.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("BusinessProcesses") Then
			If Metadata.BusinessProcesses.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("DocumentJournals") Then
			If Metadata.DocumentJournals.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Tasks") Then
			If Metadata.Tasks.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfAccounts") Then
			If Metadata.ChartsOfAccounts.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ExchangePlans") Then
			If Metadata.ExchangePlans.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfCharacteristicTypes") Then
			If Metadata.ChartsOfCharacteristicTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfCalculationTypes") Then
			If Metadata.ChartsOfCalculationTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ObjectFound Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неверное значение параметра %1 в функции %2. Объект метаданных ""%3"" не существует.';
				|vi = 'Invalid value of parameter ""%1"" in function ""%2"". Metadata object doesn''t exist: ""%3"".';
				|en = 'Invalid value of parameter ""%1"" in function ""%2"". Metadata object doesn''t exist: ""%3"".'; fa = 'Invalid value of parameter ""%1"" in function ""%2"". Metadata object doesn''t exist: ""%3"".';
				|it = 'Неверное значение параметра %1 в функции %2. Объект метаданных ""%3"" не существует.';
				|pl = 'Invalid value of parameter ""%1"" in function ""%2"". Metadata object doesn''t exist: ""%3"".';
				|tr = '%2 fonksiyonundaki %1 parametresi için geçersiz değer. ''%3'' meta veri nesnesi mevcut değil.'"), 
			"Name", "Common.ServerManagerModule", Name),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	// APK:488-Off compute in safe mode is not used to avoid calling the general module recursively.
	//tag
	//Set the Safe mode (True);
	Module = Eval(Name);
	// APK:488-on
	
	Return Module;
EndFunction

// See QuerySchemaSourceFieldAvailable a general-purpose module.
//
// Parameters:
//  OperatorSource - Arbitrary
//  ExpressToCheck - String
// 
// Returns: 
//  Boolean
//  
Function QuerySchemaSourceFieldAvailable(OperatorSource, ExpressToCheck)
	
	FieldNameParts = StrSplit(ExpressToCheck, ".");
	AvailableFields = OperatorSource.Source.AvailableFields;
	
	CurrentFieldNamePart = 0;
	While CurrentFieldNamePart < FieldNameParts.Count() Do 
		
		CurrentField = AvailableFields.Find(FieldNameParts.Get(CurrentFieldNamePart)); 
		
		If CurrentField = Undefined Then 
			Return False;
		EndIf;
		
		// Increment of the next part of the field name and the corresponding field availability list.
		CurrentFieldNamePart = CurrentFieldNamePart + 1;
		AvailableFields = CurrentField.Fields;
		
	EndDo;
	
	Return True;
	
EndFunction

// See CheckMetadataObjectExists a general-purpose module.
//
// Parameters:
//  FullName - String
// 
Procedure CheckMetadataObjectExists(FullName)
	
	If MetadataObjectByFullName(FullName) = Undefined Then 
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Несуществующий тип объекта метаданных ""%1"".';
				|vi = 'Non-existing metadata object type: ""%1"".';
				|en = 'Non-existing metadata object type: ""%1"".'; fa = 'Non-existing metadata object type: ""%1"".';
				|it = 'Несуществующий тип объекта метаданных ""%1"".';
				|pl = 'Non-existing metadata object type: ""%1"".';
				|tr = 'Bilinmeyen meta veri nesne türü ""%1"".'"), FullName),
			ErrorCategory.ConfigurationError);
	EndIf;
	
EndProcedure

// See DetailsOfSettingUpSpecifyingSeries the Catalogs manager module.Types of nomenclature.
//
// Returns: 
//  Array of String
//  
Function DetailsOfSettingUpSpecifyingSeries()
	
	DetailsOfSettingUpSpecifyingSeries = New Array;
	
	DetailsOfSettingUpSpecifyingSeries.Add("SpecifyNumberWhenRegisteringBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("UseShelfLifeOnBatchRegistration");
	DetailsOfSettingUpSpecifyingSeries.Add("UseRFIDTags");
	DetailsOfSettingUpSpecifyingSeries.Add("UseBatchProductionDate");
	
	DetailsOfSettingUpSpecifyingSeries.Add("BatchUsageSettings");
	DetailsOfSettingUpSpecifyingSeries.Add("GenerateBatchAutomatically");
	DetailsOfSettingUpSpecifyingSeries.Add("BatchOwner");
	DetailsOfSettingUpSpecifyingSeries.Add("LabelTemplateBatches");
	DetailsOfSettingUpSpecifyingSeries.Add("BatchSettingsAreTakenFromOtherItemsKind");
	DetailsOfSettingUpSpecifyingSeries.Add("WorkingNameTemplateSetOfSeries");
	DetailsOfSettingUpSpecifyingSeries.Add("ShelfLifeUnitOfMeasure");
	DetailsOfSettingUpSpecifyingSeries.Add("PrecisionOfBatchShelfLifeIndication");
	DetailsOfSettingUpSpecifyingSeries.Add("SpecifyQuantityWhenRegisteringBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("BatchAccountingPolicy");
	DetailsOfSettingUpSpecifyingSeries.Add("SettingsOfPriceKeyByBatch");
	
	
	AttributesSettingsSerialIndicationItemLocalization(DetailsOfSettingUpSpecifyingSeries);
	
	Return DetailsOfSettingUpSpecifyingSeries;
	
EndFunction

// See SettingsForUsingSerialFields the Catalogs manager module.Types of nomenclature.
//
// Parameters:
//  OnlyDetailsOfType - Boolean
//  
// Returns: 
//  Structure:
//       * ProductKind                  - CatalogRef.ItemKinds
//       * AccountingFeature                 - EnumRef.ItemAccountingFeatures
//       * KeepAccountingByBatch                - Boolean
//       * SettingsOfPriceKeyByBatch         - EnumRef.FilterOptionForPriceKey
//       * BatchAccountingPolicy               - CatalogRef.BatchAccountingPolicies
//       * SpecifyUponReceipt          - Boolean
//       * SpecifyOnShipment             - Boolean
//       * SpecifyWhenPlanningShipment - Boolean
//       * BatchesAccountingByFEFO                  - Boolean
//       * SpecifyByPickingResult           - Boolean
//       * AccountForRemainingSeries            - Boolean
//       * UseCostAccountingByBatches   - Boolean
//       * MandatoryAdditionalDetails         - FixedArray of String
//       * DescriptionsOfUseOfSeriesProps - FixedArray of String
//
Function SettingsForUsingSerialFields(OnlyDetailsOfType)
	
	SettingsForUsingSerialFields = New Structure;
	SettingsForUsingSerialFields = DefaultValuesForItemDetails(
												Catalogs.ItemKinds.EmptyRef(),
												DetailsOfSettingUpSpecifyingSeries());
	
	SettingsForUsingSerialFields.Insert("ProductKind", Catalogs.ItemKinds.EmptyRef());
	SettingsForUsingSerialFields.Insert("AccountingFeature", Enums.ItemAccountingFeatures.EmptyRef());
	SettingsForUsingSerialFields.Insert("KeepAccountingByBatch", False);
	SettingsForUsingSerialFields.Insert("SettingsOfPriceKeyByBatch", Enums.FilterOptionForPriceKey.DontUse);
	
	If Not OnlyDetailsOfType Then
		SettingsForUsingSerialFields.Insert("BatchAccountingPolicy", Catalogs.BatchAccountingPolicies.EmptyRef());
		SettingsForUsingSerialFields.Insert("SpecifyUponReceipt", False);
		SettingsForUsingSerialFields.Insert("SpecifyOnShipment", False);
		SettingsForUsingSerialFields.Insert("SpecifyWhenPlanningShipment", False);
		SettingsForUsingSerialFields.Insert("BatchesAccountingByFEFO", False);
		SettingsForUsingSerialFields.Insert("SpecifyByPickingResult", False);
		SettingsForUsingSerialFields.Insert("AccountForRemainingSeries", False);
		SettingsForUsingSerialFields.Insert("UseCostAccountingByBatches", False);
		SettingsForUsingSerialFields.Insert("MandatoryAdditionalDetails", New FixedArray(New Array));
		SettingsForUsingSerialFields.Insert("DescriptionsOfUseOfSeriesProps", New FixedArray(New Array));
	EndIf;
	
	Return SettingsForUsingSerialFields;
EndFunction

// See CurrentUserUnavailableInSessionWithoutSeparatorsMessageText The user's module is off-duty.
//
// Returns:
//  String
//
Function CurrentUserUnavailableInSessionWithoutSeparatorsMessageText()
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Недопустимое получение параметра сеанса %1
		           |в сеансе без указания всех разделителей.';
		           |vi = 'Couldn''t get session parameter for user ""%1"".
		           |Not all session separators are specified.';
		           |en = 'Couldn''t get session parameter for user ""%1"".
		           |Not all session separators are specified.'; fa = 'Couldn''t get session parameter for user ""%1"".
		           |Not all session separators are specified.';
		           |it = 'Ricezione non disponibile del parametro di sessione %1
		           |nella sessione senza indicazione di tutti i divisori.';
		           |pl = 'Nieprawidłowe pobieranie parametru sesji %1
		           |w sesji bez określania wszystkich ograniczników.';
		           |tr = 'Geçersiz %1 oturumu parametre girişi, 
		           |tüm ayırıcıların belirlenmediği oturumdur.'"),
		"CurrentUser");
	
EndFunction

// See GroupUsers The user's module is off-duty.
//
// Parameters:
//  ListBox - Arbitrary
//  
// Returns:
//  ValueTable:
//       * CurrentUser         - CatalogRef.Users
//                                     - Undefined
//       * CurrentExternalUser  - CatalogRef.Users
//                                     - Undefined
//
Function GroupUsers(ListBox)
	
	Schema = ListBox.GetPerformingDataCompositionScheme();
	Settings = ListBox.GetPerformingDataCompositionSettings();
	
	AddGroupUsersFields(Settings);
	
	TemplateComposer = New DataCompositionTemplateComposer();
	CompositionTemplate = TemplateComposer.Execute(
		Schema, Settings,,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	
	Return OutputProcessor.Output(CompositionProcessor);
	
EndFunction

// See AddGroupUsersFields The user's module is off-duty.
//
// Parameters:
//  Settings - Arbitrary
//  
Procedure AddGroupUsersFields(Settings)
	
	FieldsToAdd = StrSplit("Ref, PictureNumber", ", ", False);
	SettingsStructure = Settings.Structure[0]; // DataCompositionGroup
	SelectedFields = SettingsStructure.Selection;
	
	For Each FieldToAdd In FieldsToAdd Do 
		
		AvailableField = SelectedFields.SelectionAvailableFields.FindField(New DataCompositionField(FieldToAdd));
		
		If AvailableField = Undefined Then 
			Continue;
		EndIf;
		
		FieldFound = False;
		
		For Each Item In SelectedFields.Items Do 
			
			If Item.Field = AvailableField.Field Then 
				FieldFound = True;
				Break;
			EndIf;
			
		EndDo;
		
		If FieldFound Then 
			Continue;
		EndIf;
		
		SelectedField = SelectedFields.Items.Add(Type("DataCompositionSelectedField"));
		FillPropertyValues(SelectedField, AvailableField);
		
	EndDo;
	
EndProcedure

// See CurrentUserSessionParameterValues The user's module is off-duty.
//
// Returns:
//  Structure:
//       * CurrentUser         - CatalogRef.Users
//                                     - Undefined
//       * CurrentExternalUser  - CatalogRef.Users
//                                     - Undefined
//
Function CurrentUserSessionParameterValues()
	
	If Not SeparatedDataUsageAvailable() Then
		Return CurrentUserUnavailableInSessionWithoutSeparatorsMessageText();
	EndIf;
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể thiết lập tham số phiên làm việc %1.';
			|ru = 'Не удалось установить параметр сеанса %1.';
			|en = 'Couldn''t set session parameter for user ""%1"".'; fa = 'Couldn''t set session parameter for user ""%1"".';
			|it = 'Non è stato possibile impostare il parametro della sessione %1.';
			|pl = 'Nie można ustawić parametru sesji %1.';
			|tr = '%1 oturumun parametresi belirlenemedi.'"),
		"CurrentUser") + Chars.LF;
	
	UserInfo = FindCurrentUserInCatalog();
	
	If Not UserInfo.CreateUser
	   And Not UserInfo.UserFound Then
		
		Return ErrorTitle + UserNotFoundInCatalogMessageText(
			UserInfo.UserName);
	EndIf;
	
	If UserInfo.CurrentUser        = Undefined Then
		
		Return ErrorTitle + UserNotFoundInCatalogMessageText(
				UserInfo.UserName) + Chars.LF
			+ NStr("vi = 'Đã xuất hiện lỗi nội bộ khi tìm kiếm người sử dụng.';
					|ru = 'Возникла внутренняя ошибка при поиске пользователя.';
					|en = 'Internal user search error.'; fa = 'Internal user search error.';
					|it = 'Si è verificato un errore interno durante la ricerca dell''utente.';
					|pl = 'Wystąpił błąd wewnętrzny podczas wyszukiwania użytkownika.';
					|tr = 'Kullanıcıyı ararken bir iç hata oluştu.'");
	EndIf;
	
	Values = New Structure;
	Values.Insert("CurrentUser",        UserInfo.CurrentUser);
	Values.Insert("CurrentExternalUser", UserInfo.CurrentExternalUser);
	
	Return Values;
	
EndFunction

// See FindCurrentUserInCatalog The user's module is off-duty.
//
// Returns:
//  Structure:
//       * UserName             - String
//                                     - Undefined
//       * UserFullName       - String
//                                     - Undefined
//       * IBUserID - String
//                                     - Undefined
//       * UserFound          - Boolean
//       * CreateUser         - Boolean
//       * RefToNew                - CatalogRef.Users
//                                     - Undefined
//       * IsInternal                   - Boolean
//       * CurrentUser         - CatalogRef.Users
//                                     - Undefined
//       * CurrentExternalUser  - CatalogRef.Users
//                                     - Undefined
//
Function FindCurrentUserInCatalog()
	
	Result = New Structure;
	Result.Insert("UserName",             Undefined);
	Result.Insert("UserFullName",       Undefined);
	Result.Insert("IBUserID", Undefined);
	Result.Insert("UserFound",          False);
	Result.Insert("CreateUser",         False);
	Result.Insert("RefToNew",                Undefined);
	Result.Insert("IsInternal",                   False);
	Result.Insert("CurrentUser",         Undefined);
	Result.Insert("CurrentExternalUser",  Undefined);
	
	CurrentIBUser = InfoBaseUsers.CurrentUser();
	
	If IsBlankString(CurrentIBUser.Name) Then
		UnspecifiedUserProperties = UnspecifiedUserProperties();
		
		Result.UserName       = UnspecifiedUserProperties.FullName;
		Result.UserFullName = UnspecifiedUserProperties.FullName;
		Result.RefToNew          = UnspecifiedUserProperties.StandardRef;
		
		If UnspecifiedUserProperties.Ref = Undefined Then
			Result.CreateUser = True;
			Result.IsInternal = True;
			Result.IBUserID = "";
		Else
			Result.UserFound = True;
			Result.CurrentUser = UnspecifiedUserProperties.Ref;
		EndIf;
		
		Return Result;
	EndIf;

	Result.UserName             = CurrentIBUser.Name;
	Result.IBUserID = CurrentIBUser.UUID;
	
	FindAmbiguousIBUsers(Undefined, Result.IBUserID);
	
	Query = New Query;
	Query.Parameters.Insert("IBUserID", Result.IBUserID);
	
	Query.Text =
	"SELECT TOP 1
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID = &IBUserID";
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result.CurrentUser = Selection.Ref;
		Result.UserFound = True;
		Return Result;
	EndIf;
	
	OnNoCurrentUserInCatalog(
		Result.CreateUser);
	
	If Not Result.CreateUser
	   And Not AdministratorRolesAvailable() Then
		
		Return Result;
	EndIf;
	
	Result.IBUserID = CurrentIBUser.UUID;
	Result.UserFullName       = CurrentIBUser.FullName;
	
	If Result.CreateUser Then
		Return Result;
	EndIf;
	
	UserByDescription = UserRefByFullDescription(
		Result.UserFullName);
	
	If UserByDescription <> Undefined Then
		Result.UserFound  = True;
		Result.CurrentUser = UserByDescription;
	Else
		Result.CreateUser = True;
	EndIf;
	
	Return Result;
	
EndFunction

// See UserRefByFullDescription The user's module is off-duty.
//
// Parameters:
//  FullName - String
//  
// Returns:
//  CatalogRef.Users
//
Function UserRefByFullDescription(FullName)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.IBUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Description = &FullName";
	
	Query.SetParameter("FullName", FullName);
	
	Result = Undefined;
	
	BeginTransaction();
	Try
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			
			Selection = QueryResult.Select();
			Selection.Next();
			
			If Not IBUserOccupied(Selection.IBUserID) Then
				Result = Selection.Ref;
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Result;
	
EndFunction

// See UserNotFoundInCatalogMessageText The user's module is off-duty.
//
// Parameters:
//  UserName - String
//  
// Returns:
//  String
//
Function UserNotFoundInCatalogMessageText(UserName)
	
	ErrorMessageTemplate =
		NStr("ru = 'Пользователь ""%1"" не существует в справочнике ""Пользователи"".
		           |
		           |Обратитесь к администратору.';
		           |vi = 'User ""%1"" does not exist in the ""Users"" catalog.
		           |
		           |Contact your administrator.';
		           |en = 'User ""%1"" does not exist in the ""Users"" catalog.
		           |
		           |Contact your administrator.'; fa = 'User ""%1"" does not exist in the ""Users"" catalog.
		           |
		           |Contact your administrator.';
		           |it = 'L''utente ""%1"" non esiste nella directory ""Utenti"". 
		           |
		           |Rivolgersi all''amministratore.';
		           |pl = 'Użytkownik ""%1"" nie istnieje w katalogu ""Użytkownicy"".
		           |
		           |Zwróć się do administratora.';
		           |tr = '""%1"" Kullanıcısı ""Kullanıcılar"" rehberinde mevcut değil. 
		           |
		           | Yöneticinize başvurun.'");
	
	Return StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageTemplate, UserName);
	
EndFunction

// See ConvertDecimalToHexadecimalNotation The barcoding module of printed forms.
//
// Parameters:
//  Decimal - Number
//  
// Returns:
//  String
//
Function ConvertDecimalToHexadecimalNotation(Val Decimal)
	
	Result = "";
	
	While Decimal > 0 Do
		Remainder = Decimal % 16;
		Decimal  = (Decimal - Remainder) / 16;
		Result        = Mid("0123456789abcdef", Remainder + 1, 1) + Result;
	EndDo;
	
	Return Result;
	
EndFunction

// See ConvertFromHexadecimalToDecimal The barcoding module of printed forms.
//
// Parameters:
//  Value - String
//  
// Returns:
//  String
//
Function ConvertFromHexadecimalToDecimal(Val Value)
	
	Value = Lower(Value);
	StringLength = StrLen(Value);
	
	Result = 0;
	For CharacterNumber = 1 To StringLength Do
		Result = Result * 16 + StrFind("0123456789abcdef", Mid(Value, CharacterNumber, 1)) - 1;
	EndDo;
	
	Return Format(Result, "NG=0");
	
EndFunction

// See ExpectedTypeValue The general purpose Clientserver module.
//
// Parameters:
//  Value - Arbitrary
//  ExpectedTypes - Arbitrary
//  
// Returns:
//  Boolean
//
Function ExpectedTypeValue(Value, ExpectedTypes)
	
	ValueType = TypeOf(Value);
	If TypeOf(ExpectedTypes) = Type("TypeDescription") Then
		Return ExpectedTypes.Types().Find(ValueType) <> Undefined;
	ElsIf TypeOf(ExpectedTypes) = Type("Type") Then
		Return ValueType = ExpectedTypes;
	ElsIf TypeOf(ExpectedTypes) = Type("Array") 
		Or TypeOf(ExpectedTypes) = Type("FixedArray") Then
		Return ExpectedTypes.Find(ValueType) <> Undefined;
	ElsIf TypeOf(ExpectedTypes) = Type("Map") 
		Or TypeOf(ExpectedTypes) = Type("FixedMap") Then
		Return ExpectedTypes.Get(ValueType) <> Undefined;
	EndIf;
	Return Undefined;
	
EndFunction

// See TypesPresentation The general purpose Clientserver module.
//
// Parameters:
//  ExpectedTypes - Arbitrary
//  
// Returns:
//  String
//
Function TypesPresentation(ExpectedTypes)
	
	If TypeOf(ExpectedTypes) = Type("Array")
		Or TypeOf(ExpectedTypes) = Type("FixedArray")
		Or TypeOf(ExpectedTypes) = Type("Map")
		Or TypeOf(ExpectedTypes) = Type("FixedMap") Then
		
		Result = "";
		IndexOf = 0;
		For Each Item In ExpectedTypes Do
			
			If TypeOf(ExpectedTypes) = Type("Map")
				Or TypeOf(ExpectedTypes) = Type("FixedMap") Then 
				
				Type = Item.Key;
			Else 
				Type = Item;
			EndIf;
			
			If Not IsBlankString(Result) Then
				Result = Result + ", ";
			EndIf;
			
			Result = Result + TypePresentation(Type);
			IndexOf = IndexOf + 1;
			If IndexOf > 10 Then
				Result = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1, ... (tổng số %2 kiểu)';
						|ru = '%1,... (всего %2 типов)';
						|en = '%1,… (total %2 types)'; fa = '%1,… (total %2 types)';
						|it = '%1... (totale %2 tipi)';
						|pl = '%1,... (łącznie %2 typów)';
						|tr = '%1,... (toplam %2 tür)'"), 
					Result, 
					ExpectedTypes.Count());
				Break;
			EndIf;
		EndDo;
		
		Return Result;
		
	Else 
		Return TypePresentation(ExpectedTypes);
	EndIf;
	
EndFunction

// See TypePresentation The general purpose Clientserver module.
//
// Parameters:
//  Type - TypeDescription
//      - Undefined
//  
// Returns:
//  String
//
Function TypePresentation(Type)
	
	If Type = Undefined Then
		
		Return "Undefined";
		
	ElsIf TypeOf(Type) = Type("TypeDescription") Then
		
		TypeAsString = String(Type);
		Return 
			?(StrLen(TypeAsString) > 150, 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1, ... (tổng số  %2 kiểu)';
						|ru = '%1,... (всего %2 типов)';
						|en = '%1,… (total %2 types)'; fa = '%1,… (total %2 types)';
						|it = '%1... (totale %2 tipi)';
						|pl = '%1,... (łącznie %2 typów)';
						|tr = '%1,... (toplam %2 tür)'"),
					Left(TypeAsString, 150),
					Type.Types().Count()), 
				TypeAsString);
		
	Else
		
		TypeAsString = String(Type);
		Return 
			?(StrLen(TypeAsString) > 150, 
				Left(TypeAsString, 150) + "...", 
				TypeAsString);
		
	EndIf;
	
EndFunction

// See DateFromBarcodeString The barcoding modulenomencenturyserver.
// 
// Parameters:
//  Barcode - String
//  
// Returns:
//  Date
//
Function DateFromBarcodeString(Val Barcode)
	BarcodeDate = '00010101';	
	If StringFunctionsClientServer.OnlyNumbersInString(Barcode) Then
		If StrLen(Barcode) = 8 Then
			
			Barcode =  "20" + Mid(Barcode,5,2) + Mid(Barcode,3,2) + Left(Barcode,2) + Right(Barcode, 2) + "0000";
			
			Try
				BarcodeDate = Date(Barcode);
			Except
				BarcodeDate = '00010101';
			EndTry;             
		ElsIf StrLen(Barcode) = 6 Then
			
			Barcode =  "20" + Mid(Barcode,5,2) + Mid(Barcode,3,2) + Left(Barcode,2) + "000000";
			
			Try
				BarcodeDate = Date(Barcode);
			Except
				BarcodeDate = '00010101';
			EndTry;
		EndIf;
	EndIf;
	
	Return BarcodeDate;
EndFunction

#EndRegion

