///////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS FOR THE FORMATION OF MOVEMENTS FOR THE ACCOUNTING OF MULTI-TURN CONTAINERS

#Region Public

// Fills in the multi-turn container selected by processing in the document
//
// Parameters:
// Object - DocumentObject            - A document to fill in a multi-turn container.
// AddressOfContainerInStorage                - String - Address of the multi-turn container table in temporary storage.
// TableName                         - String - Name of the document table to fill in the multi-turn container in.
// ColumnsNames                       - String - Names of table columns for which you want to search for strings.
//                                              "Item, Characteristic, Warehouse, date "(Names may change
//                                              depending on the document).
// ActionStructureModifiedStrings  - Structure - Actions with changed strings.
// StructureOfActionsAddedLines - Structure - Actions with added rows.
// CachedValues               - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure FillMultiTurnContainersFromStorage(Object,
	                                             Val AddressOfContainerInStorage,
	                                             Val TableName,
	                                             Val ColumnsNames,
	                                             Val ActionStructureModifiedStrings,
	                                             Val StructureOfActionsAddedLines,
	                                             CachedValues = Undefined) Export
	
	If TMCommonUseClientServer.HasObjectAttribute(Object, "ReusablePackageFillingStatus") Then
		Object.ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.FilledIn;
	EndIf;
	
	StorageContainers = GetFromTempStorage(AddressOfContainerInStorage);
	ArrayOfRowsToDelete_1 = New Array();
	AddedRows = New Array();
	ModifiedRows = New Array();
	ColumnsArray1 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ColumnsNames, ",");
	
	If ColumnsArray1.Count() < 2 Then
		
		ErrorDescription = NStr("vi = 'Đã đặt sai tham số %1 hàm';
								|ru = 'Неверно задан параметр %1 функции';
								|en = '%1 function parameter is specified incorrectly'; fa = '%1 function parameter is specified incorrectly';
								|it = 'Parametro %1 della funzione non dato correttamente';
								|pl = 'Niepoprawnie zadano parametr %1 funkcji';
								|tr = 'Yanlış fonksiyon parametresi %1'");
		ErrorDescription = StrTemplate(ErrorDescription, "ColumnsNames");
		
		Raise ErrorDescription;
	EndIf;
	
	SearchForPositionsWithoutSets = Undefined;
	For Each TSRow In Object[TableName] Do
		SearchForPositionsWithoutSets = TMCommonUseClientServer.HasObjectAttribute(TSRow, "ProductsInSet");
		Break;
	EndDo;
	
	For Each RowOfGoods In StorageContainers Do
		
		TheStructureOfTheSearch = New Structure(ColumnsNames);
		TheStructureOfTheSearch[ColumnsArray1[0]] = RowOfGoods.Products;
		TheStructureOfTheSearch[ColumnsArray1[1]] = RowOfGoods.Characteristic;
		
		PopulateColumns(ColumnsArray1, RowOfGoods, TheStructureOfTheSearch);
		
		UseVariants = Common.ObjectAttributeValue(RowOfGoods.Products, "UseVariants");
		CharacteristicNotSpecified    = UseVariants <> Enums.ItemVariantsUsageOptions.DontUse
			And Not ValueIsFilled(RowOfGoods.Characteristic);
			
		If CharacteristicNotSpecified Then
			
			TheStructureOfTheSearch.Delete(ColumnsArray1[1]);
			
		EndIf;
		
		If TableName <> "Components" And SearchForPositionsWithoutSets = True Then
			TheStructureOfTheSearch.Insert("ProductsInSet", Catalogs.Products.EmptyRef());
		EndIf;
		
		ArrayOfTSRows = Object[TableName].FindRows(TheStructureOfTheSearch);
		
		If RowOfGoods.Count = 0 Then
			
			For Each CurItem In ArrayOfTSRows Do
				ArrayOfRowsToDelete_1.Add(CurItem);
			EndDo;
			
		ElsIf ArrayOfTSRows.Count() = 0 Then
			
			StringTSGoods = Object[TableName].Add();
			FillPropertyValues(StringTSGoods, RowOfGoods);
			
			PopulateColumns(ColumnsArray1, RowOfGoods, StringTSGoods);
			
			AddedRows.Add(StringTSGoods);
			
		ElsIf ArrayOfTSRows.Count() > 0 Then
			
			StringTSGoods = ArrayOfTSRows[0];
			
			If StringTSGoods.Count <> RowOfGoods.Count Then
				
				PreviousCharacteristic = StringTSGoods.Characteristic;
				
				FillPropertyValues(StringTSGoods, RowOfGoods);
					
				If CharacteristicNotSpecified Then 
					
					StringTSGoods.Characteristic = PreviousCharacteristic;
					
				EndIf;
				
				PopulateColumns(ColumnsArray1, RowOfGoods, StringTSGoods);
					
				ModifiedRows.Add(StringTSGoods);
				
			EndIf;
			
			If ArrayOfTSRows.Count() > 1 Then
				For Counter = 2 To ArrayOfTSRows.Count() Do
					ArrayOfRowsToDelete_1.Add(ArrayOfTSRows[Counter-1]);
				EndDo;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActionsAddedLines,
		Object[TableName],
		CachedValues);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ModifiedRows,
		ActionStructureModifiedStrings,
		Object[TableName],
		CachedValues);
	
	For Each CurItem In ArrayOfRowsToDelete_1 Do
		Object[TableName].Delete(CurItem);
	EndDo;

EndProcedure

// Calculates the date of return of multi-turn containers under the terms of the agreement
//
// Parameters:
//  Object                                   - DocumentObject - Document for which the term of return of the container is considered
//  ReusablePackageReturnCycleLength           - Number - Return period for multi-turn containers in days
//  CalculatePackageReturnDateAccordingToCalendar  - Boolean - Defines the date calculation option: for all days or for the main
//                                                      calendar of the company.
//  Calendar                                - CatalogRef.BusinessCalendars - Defines
//                                                                                          the container return calendar.
//
// Returns:
//  Date - calculated return date.
//
Function CalculateReturnDateOfMultiTurnContainer(Val Object,
	                                             Val ReusablePackageReturnCycleLength,
	                                             Val CalculatePackageReturnDateAccordingToCalendar,
	                                             Val Calendar) Export
	
	OneDay = 86400;
	
	TareReturnReferenceDate = DetermineTareReturnReferenceDate(Object);
	
	If Not ValueIsFilled(TareReturnReferenceDate) Then
		TareReturnReferenceDate = CurrentSessionDate();
	EndIf;
	
	If Not ValueIsFilled(ReusablePackageReturnCycleLength) Then
		ReusablePackageReturnCycleLength = 0;
	EndIf;
	
	If ValueIsFilled(CalculatePackageReturnDateAccordingToCalendar) 
		And CalculatePackageReturnDateAccordingToCalendar And ValueIsFilled(Calendar) Then
		ReusablePackagesReturnDate = CalendarSchedules.DateByCalendar(
			Calendar,
			TareReturnReferenceDate,
			ReusablePackageReturnCycleLength);
	Else
		ReusablePackagesReturnDate = TareReturnReferenceDate + OneDay * ReusablePackageReturnCycleLength;
	EndIf;
	
	Return BegOfDay(ReusablePackagesReturnDate);
	
EndFunction

// Resets the fill state of the multi-turn container in the document after changing the table part.
//
// Parameters:
// 	ReusablePackageFillingStatus - EnumRef.ReusablePackageFillingStates - 
//
Procedure UpdateFillingStateOfMultiTurnContainer(ReusablePackageFillingStatus) Export
	
	If ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.FilledIn Then
		ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.OfferToFillIn;
	EndIf;
	
EndProcedure

// Updates the table columns associated with the returnable container
//
// Parameters:
// Goods - FormDataCollection - A document table on which you want to update the column
// ToReturnReusablePackage - Boolean - if True, the container is returnable
// StructureOfAdditionalActions - Structure - Additional actions to perform.
//
Procedure UpdateNoReturnableContainerAttribute(Goods, ToReturnReusablePackage, StructureOfAdditionalActions = Undefined) Export
	
	If StructureOfAdditionalActions = Undefined Then
		StructureOfActions = New Structure;
	Else
		StructureOfActions = CommonClientServer.CopyStructure(StructureOfAdditionalActions);
	EndIf;
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", ToReturnReusablePackage);
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

// Returns the structure of parameters for checking whether a multi-turn container is specified in a document
//
// Returns:
//  Structure - structure with fields:
//   * TSName      - String - name of the table part of the document to check
//   * ThereAreCells - Boolean - indicates that there are cells in the PM.
//
Function ParametersForCheckingIndicationOfMultiTurnContainer() Export
	
	ParametersForCheckingIndicationOfMultiTurnContainer = New Structure;
	ParametersForCheckingIndicationOfMultiTurnContainer.Insert("TSName", "Goods");
	ParametersForCheckingIndicationOfMultiTurnContainer.Insert("ThereAreCells", True);
	ParametersForCheckingIndicationOfMultiTurnContainer.Insert("RowFilter", Undefined);
	
	Return ParametersForCheckingIndicationOfMultiTurnContainer;
	
EndFunction

// They will check that the table part of the container contains no less than the packages that require it.
// 
// Parameters:
//		Object - DocumentObject - document being checked	
//		ParametersForCheckingIndicationOfMultiTurnContainer - Structure - returned by the function parametercheckdefinition of a multi-Turntary
//		Cancel - Boolean - The result of the check.
//
Procedure CheckIndicationOfMultiTurnContainer(Object, ParametersForCheckingIndicationOfMultiTurnContainer, Cancel) Export
	
	If Not GetFunctionalOption("UseReusablePackage") Then
		Return;
	EndIf;
	
	Query = New Query;
	
	If ParametersForCheckingIndicationOfMultiTurnContainer.ThereAreCells Then
		
		Query.Text =
		"SELECT
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.NumberOfPackages AS NumberOfPackages,
		|	GoodsTable.Cell AS Cell
		|INTO GoodsTable
		|FROM
		|	&GoodsTable AS GoodsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(GoodsTable.NumberOfPackages) AS Count,
		|	GoodsTable.Products AS TaraProducts,
		|	GoodsTable.Characteristic AS TaraCharacteristic,
		|	GoodsTable.Cell AS Cell
		|INTO PackagingInDocument
		|FROM
		|	GoodsTable AS GoodsTable
		|WHERE
		|	CAST(GoodsTable.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|
		|GROUP BY
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Cell
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(NestedQuery.Count) AS Count,
		|	NestedQuery.TaraProducts AS TaraProducts,
		|	NestedQuery.TaraCharacteristic AS TaraCharacteristic,
		|	NestedQuery.Cell AS Cell
		|INTO RequiredPackaging
		|FROM
		|	(SELECT
		|		GoodsTable.NumberOfPackages AS Count,
		|		ProductPackages.ReusablePackageItems AS TaraProducts,
		|		ProductPackages.ReusablePackageVariant AS TaraCharacteristic,
		|		GoodsTable.Cell AS Cell
		|	FROM
		|		GoodsTable AS GoodsTable
		|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|			ON GoodsTable.Package = ProductPackages.Ref
		|	WHERE
		|		CAST(GoodsTable.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|		AND ProductPackages.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|		AND ProductPackages.SuppliedInReusablePackage
		|		AND GoodsTable.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MIN(GoodsTable.NumberOfPackages * RepackagingOptions.Count),
		|		RepackagingOptions.Package.ReusablePackageItems,
		|		RepackagingOptions.Package.ReusablePackageVariant,
		|		GoodsTable.Cell
		|	FROM
		|		GoodsTable AS GoodsTable
		|			INNER JOIN InformationRegister.RepackagingOptions AS RepackagingOptions
		|			ON GoodsTable.Package = RepackagingOptions.Source
		|	WHERE
		|		CAST(GoodsTable.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|		AND RepackagingOptions.Source.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|		AND RepackagingOptions.Package.SuppliedInReusablePackage
		|		AND GoodsTable.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	GROUP BY
		|		RepackagingOptions.Package.ReusablePackageItems,
		|		RepackagingOptions.Package.ReusablePackageVariant,
		|		GoodsTable.Cell
		|
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.TaraProducts,
		|	NestedQuery.TaraCharacteristic,
		|	NestedQuery.Cell
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RequiredPackaging.TaraProducts AS TaraProducts,
		|	RequiredPackaging.TaraCharacteristic AS TaraCharacteristic,
		|	ISNULL(PackagingInDocument.Count, 0) AS TareQuantityAdded,
		|	RequiredPackaging.Count AS NumberOfTareRequired,
		|	CAST(RequiredPackaging.TaraProducts AS Catalog.Products).UnitOfMeasure AS UnitOfMeasure,
		|	RequiredPackaging.Cell AS Cell
		|FROM
		|	RequiredPackaging AS RequiredPackaging
		|		LEFT JOIN PackagingInDocument AS PackagingInDocument
		|		ON RequiredPackaging.TaraProducts = PackagingInDocument.TaraProducts
		|			AND RequiredPackaging.TaraCharacteristic = PackagingInDocument.TaraCharacteristic
		|			AND RequiredPackaging.Cell = PackagingInDocument.Cell
		|WHERE
		|	RequiredPackaging.Count > ISNULL(PackagingInDocument.Count, 0)";
		
		If ParametersForCheckingIndicationOfMultiTurnContainer.RowFilter = Undefined Then
			Query.SetParameter("GoodsTable", Object[ParametersForCheckingIndicationOfMultiTurnContainer.TSName].Unload(,"Products,Characteristic,Package,Cell,NumberOfPackages"));
		Else
			Query.SetParameter("GoodsTable", Object[ParametersForCheckingIndicationOfMultiTurnContainer.TSName].Unload(
																												ParametersForCheckingIndicationOfMultiTurnContainer.RowFilter,
																												"Products,Characteristic,Package,Cell,NumberOfPackages"));
		EndIf;
	Else
		
		Query.Text =
		"SELECT
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.NumberOfPackages AS NumberOfPackages
		|INTO GoodsTable
		|FROM
		|	&GoodsTable AS GoodsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(GoodsTable.NumberOfPackages) AS Count,
		|	GoodsTable.Products AS TaraProducts,
		|	GoodsTable.Characteristic AS TaraCharacteristic
		|INTO PackagingInDocument
		|FROM
		|	GoodsTable AS GoodsTable
		|WHERE
		|	CAST(GoodsTable.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|
		|GROUP BY
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(NestedQuery.Count) AS Count,
		|	NestedQuery.TaraProducts AS TaraProducts,
		|	NestedQuery.TaraCharacteristic AS TaraCharacteristic
		|INTO RequiredPackaging
		|FROM
		|	(SELECT
		|		GoodsTable.NumberOfPackages AS Count,
		|		ProductPackages.ReusablePackageItems AS TaraProducts,
		|		ProductPackages.ReusablePackageVariant AS TaraCharacteristic
		|	FROM
		|		GoodsTable AS GoodsTable
		|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|			ON GoodsTable.Package = ProductPackages.Ref
		|	WHERE
		|		CAST(GoodsTable.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|		AND ProductPackages.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|		AND ProductPackages.SuppliedInReusablePackage
		|		AND GoodsTable.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MIN(GoodsTable.NumberOfPackages * RepackagingOptions.Count),
		|		RepackagingOptions.Package.ReusablePackageItems,
		|		RepackagingOptions.Package.ReusablePackageVariant
		|	FROM
		|		GoodsTable AS GoodsTable
		|			INNER JOIN InformationRegister.RepackagingOptions AS RepackagingOptions
		|			ON GoodsTable.Package = RepackagingOptions.Source
		|	WHERE
		|		CAST(GoodsTable.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|		AND RepackagingOptions.Source.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|		AND RepackagingOptions.Package.SuppliedInReusablePackage
		|		AND GoodsTable.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	GROUP BY
		|		RepackagingOptions.Package.ReusablePackageItems,
		|		RepackagingOptions.Package.ReusablePackageVariant
		|
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.TaraProducts,
		|	NestedQuery.TaraCharacteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RequiredPackaging.TaraProducts AS TaraProducts,
		|	RequiredPackaging.TaraCharacteristic AS TaraCharacteristic,
		|	ISNULL(PackagingInDocument.Count, 0) AS TareQuantityAdded,
		|	RequiredPackaging.Count AS NumberOfTareRequired,
		|	CAST(RequiredPackaging.TaraProducts AS Catalog.Products).UnitOfMeasure AS UnitOfMeasure
		|FROM
		|	RequiredPackaging AS RequiredPackaging
		|		LEFT JOIN PackagingInDocument AS PackagingInDocument
		|		ON RequiredPackaging.TaraProducts = PackagingInDocument.TaraProducts
		|			AND RequiredPackaging.TaraCharacteristic = PackagingInDocument.TaraCharacteristic
		|WHERE
		|	RequiredPackaging.Count > ISNULL(PackagingInDocument.Count, 0)";
		
		If ParametersForCheckingIndicationOfMultiTurnContainer.RowFilter = Undefined Then
			Query.SetParameter("GoodsTable", Object[ParametersForCheckingIndicationOfMultiTurnContainer.TSName].Unload(,"Products,Characteristic,Package,NumberOfPackages"));
		Else
			Query.SetParameter("GoodsTable", Object[ParametersForCheckingIndicationOfMultiTurnContainer.TSName].Unload(
																											ParametersForCheckingIndicationOfMultiTurnContainer.RowFilter,
																											"Products,Characteristic,Package,NumberOfPackages"));
		EndIf;
			
	EndIf;
	
	Selection = Query.Execute().Select();
	
	ObjectMetadata = Object.Metadata();
	PresentationOfTS = ObjectMetadata.TabularSections[ParametersForCheckingIndicationOfMultiTurnContainer.TSName].Synonym;
	
	While Selection.Next() Do
		
		If ParametersForCheckingIndicationOfMultiTurnContainer.ThereAreCells And ValueIsFilled(Selection.Cell) Then
			MessageText = NStr("vi = 'Trong danh sách %TSName% cho các gói trong ô %Cell%, được Phân bổ trong bao bì nhiều lượt ""%Tara%"", bao bì không đủ được chỉ định. Không đủ %Count% %UnitOfMeasure%.';
								|ru = 'В списке %TSName% для упаковок в ячейке %Cell%, поставляемых в многооборотной таре ""%Tara%"", указано недостаточное количество тары. Не хватает %Count% %UnitOfMeasure%.';
								|en = 'Insufficient package quantity is specified in the %TSName% list for packaging units in the %Cell% bin supplied in ""%Tara%"" reusable packaging. %Count% %UnitOfMeasure% is missing.'; fa = 'Insufficient package quantity is specified in the %TSName% list for packaging units in the %Cell% bin supplied in ""%Tara%"" reusable packaging. %Count% %UnitOfMeasure% is missing.';
								|it = 'Nella lista %TSName% per confezioni in cella %Cell%, fornito in un contenitore multi-giro ""%Tara%"", la quantità insufficiente di Tara è indicata. Manca %Count% %UnitOfMeasure%.';
								|pl = 'W liście %TSName% dla opakowań w komórce %Cell%, dostarczanych w postaci tary wielokrotnego użytku ""%Tara%"", jest wskazana niewystarczająca ilość tary. Nie starcza %Count% %UnitOfMeasure%.';
								|tr = 'Yeniden kullanılabilir ""%Tara%"" ambalajdaki sağlanan %Cell% hücresindeki paketler için %TSName% listesinde, yetersiz miktarda ambalaj var. Yeterli değil %Count% %UnitOfMeasure%.'");
			MessageText = StrReplace(MessageText,  "%Cell%" , Selection.Cell);
		Else
			MessageText = NStr("vi = 'Trong danh sách %TSName% đối với bộ đóng gói được giao với bao bì luân chuyển ""%Tara%"" đã chỉ ra thiếu số lượng bao bì. Không đủ %Count% %UnitOfMeasure%.';
								|ru = 'В списке %TSName% для упаковок, поставляемых в многооборотной таре ""%Tara%"", указано недостаточное количество тары. Не хватает %Count% %UnitOfMeasure%.';
								|en = 'Not enough package is specified in list %TSName% for packaging units supplied in reusable packaging ""%Tara%"". %Count% %UnitOfMeasure% is not enough.'; fa = 'Not enough package is specified in list %TSName% for packaging units supplied in reusable packaging ""%Tara%"". %Count% %UnitOfMeasure% is not enough.';
								|it = 'Nella lista %TSName% per confezioni fornite in un contenitore multi-giro ""%Tara%"", ha indicato un numero insufficiente di tara. Manca %Count% %UnitOfMeasure%.';
								|pl = 'W liście %TSName% dla opakowań, dostarczanych w postaci tary wielokrotnego użytku ""%Tara%"", jest wskazana niewystarczająca ilość tary. Nie starcza %Count% %UnitOfMeasure%.';
								|tr = 'Yeniden kullanılabilir ambalaj ""%Tara%"" içinde sağlanan paketler için %TSName% listesinde yetersiz ambalaj miktarı belirtildi. Yeterli değil %Count% %UnitOfMeasure%.'");
		EndIf;
		
		MessageText = StrReplace(MessageText,  "%TSName%" , PresentationOfTS);
		MessageText = StrReplace(MessageText,  "%Count%" , Selection.NumberOfTareRequired - Selection.TareQuantityAdded);
		MessageText = StrReplace(MessageText,  "%Tara%" , ProductsClientServer.ProductPresentation(Selection.TaraProducts,Selection.TaraCharacteristic));
		MessageText = StrReplace(MessageText,  "%UnitOfMeasure%" , Selection.UnitOfMeasure);
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
		
	EndDo;
	
EndProcedure

// The function returns a table of multi-turn containers by item and packaging (taking into account the hierarchy of packages).
//
// Parameters:
//  Products - CatalogRef.Products - nomenclature for selection.
//  Package - CatalogRef.PackagesAndUnitsOfMeasure - packaging for selection.
//
//  Returns:
//   ValueTable - Table of values with columns:
//    * Products               - CatalogRef.Products - packaging nomenclature for the transferred product.
//    * Characteristic             - CatalogRef.ItemsCharacteristics - characteristics of the container for the transferred product.
//    * ItemVariantsAreUsed - Boolean - indicates whether characteristics are used for the container nomenclature.
//    * Count                 - Number - the number of items.
//
Function ReusablePackagingOfProductRange(Products, Package) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.Count) AS NumberOfPackages,
	|	1 AS ZoomRatio
	|FROM
	|	(SELECT
	|		Products.ReusablePackageItems AS Products,
	|		Products.ReusablePackageVariant AS Characteristic,
	|		CASE
	|			WHEN Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS ItemVariantsAreUsed,
	|		1 AS Count
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.SuppliedInReusablePackage
	|		AND Products.Ref = &Products
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductPackages.ReusablePackageItems,
	|		ProductPackages.ReusablePackageVariant,
	|		CASE
	|			WHEN ProductPackages.ReusablePackageItems.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|				THEN TRUE
	|			ELSE FALSE
	|		END,
	|		1
	|	FROM
	|		Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|	WHERE
	|		ProductPackages.SuppliedInReusablePackage
	|		AND ProductPackages.Ref = &Package
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RepackagingOptions.Package.ReusablePackageItems,
	|		RepackagingOptions.Package.ReusablePackageVariant,
	|		CASE
	|			WHEN RepackagingOptions.Package.ReusablePackageItems.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|				THEN TRUE
	|			ELSE FALSE
	|		END,
	|		RepackagingOptions.Count
	|	FROM
	|		InformationRegister.RepackagingOptions AS RepackagingOptions
	|	WHERE
	|		&Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		AND RepackagingOptions.Source = &Package
	|		AND RepackagingOptions.Package.SuppliedInReusablePackage) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.ItemVariantsAreUsed";
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("Package", Package);
	
	Return Query.Execute().Unload();
	
EndFunction

#Region ConditionalAppearance

// Function-constructor of parameters for setting conditional formatting of strings with multi-turn packaging.
//
// Returns:
// 	Structure - parameter structure:
//      * Form - ClientApplicationForm - Contains this form
//      * ThisIsAdmission - Boolean - True if it is a receipt document
//      * NameOfVATRateField - String - The name of the form element containing the VAT rate, if it differs from the "Touristland"
//      * NameOfPriceInputField - String - Name of the form element containing the price, if it differs from " product Price"
//      * NameOfAmountInputField - String - Name of the form element containing the amount, if it differs from " product Sum"
//      * KTCHSelectionPath - String - The full path to the PM containing the above fields, if it differs from " Object.Goods.
//
Function ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers() Export
	
	InstallationParameters = New Structure;
	
	InstallationParameters.Insert("Form");
	InstallationParameters.Insert("ThisIsAdmission");
	InstallationParameters.Insert("ThisIsTransfer", False);
	InstallationParameters.Insert("NameOfVATRateField", "GoodsVATRate");
	InstallationParameters.Insert("NameOfPriceInputField", "GoodsPrice");
	InstallationParameters.Insert("NameOfAmountInputField", "GoodsSum");
	InstallationParameters.Insert("KTCHSelectionPath","Object.Goods");
	InstallationParameters.Insert("PathToSelectionFieldIsToReturnReusableContainer","Object.ToReturnReusablePackage");
	InstallationParameters.Insert("PathToSelectionFieldRequiresDepositForContainer","Object.PackageDepositIsRequired");
	
	Return InstallationParameters;
	
EndFunction

// We set the conditional design of prices, amounts, and VAT rates for lines with multi-turn packaging.
//
// Parameters:
// 	InstallationParameters - See ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers
//
Procedure SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters) Export

	Form                 = InstallationParameters.Form;
	ThisIsAdmission        = InstallationParameters.ThisIsAdmission;
	ThisIsTransfer           = InstallationParameters.ThisIsTransfer;
	NameOfVATRateField = InstallationParameters.NameOfVATRateField;
	NameOfPriceInputField      = InstallationParameters.NameOfPriceInputField;
	NameOfAmountInputField     = InstallationParameters.NameOfAmountInputField;
	KTCHSelectionPath         = InstallationParameters.KTCHSelectionPath;
	PathToSelectionFieldIsToReturnReusableContainer	= InstallationParameters.PathToSelectionFieldIsToReturnReusableContainer;
	PathToSelectionFieldRequiresDepositForContainer			= InstallationParameters.PathToSelectionFieldRequiresDepositForContainer;
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	PathToProductTypeSelectionField	= KTCHSelectionPath + ".ItemsType";
	PathToPriceSelectionField				= KTCHSelectionPath + ".Price";
	PathToSumSelectionField			= KTCHSelectionPath + ".Sum";
	
	If Not GetFunctionalOption("UseReusablePackage") Then
		
		If Not ThisIsTransfer Then
			
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			
			ItemField = ConditionalAppearanceItem.Fields.Items.Add();
			FormField = FormItems[NameOfPriceInputField]; // FormField
			ItemField.Field = New DataCompositionField(FormField.Name);
			
			ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToPriceSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
			
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			
			ItemField = ConditionalAppearanceItem.Fields.Items.Add();
			FormField = FormItems[NameOfAmountInputField]; // FormField
			ItemField.Field = New DataCompositionField(FormField.Name);
			
			ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSumSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
			
		EndIf;
		
		Return;
		
	EndIf;
	
	If NameOfVATRateField <> "" Then
		//
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		FormField = FormItems[NameOfVATRateField]; // FormField
		ItemField.Field = New DataCompositionField(FormField.Name);
		
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToProductTypeSelectionField);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
		
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldIsToReturnReusableContainer);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);	
		
	EndIf;
	
	If Not ThisIsTransfer Then
		
		If ThisIsAdmission Then
			//
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			
			ItemField = ConditionalAppearanceItem.Fields.Items.Add();
			FormField = FormItems[NameOfPriceInputField]; // FormField
			ItemField.Field = New DataCompositionField(FormField.Name);
			
			ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToPriceSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			FilterGroup1 = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			
			ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToProductTypeSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
			ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
			
			FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
			ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToProductTypeSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
			
			FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			
			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldRequiresDepositForContainer);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			
			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldIsToReturnReusableContainer);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = False;
			
			ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
			
			//
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			
			ItemField = ConditionalAppearanceItem.Fields.Items.Add();
			FormField = FormItems[NameOfAmountInputField]; // FormField
			ItemField.Field = New DataCompositionField(FormField.Name);
			
			ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSumSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			FilterGroup1 = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			
			ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToProductTypeSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
			ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
			
			FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
			ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToProductTypeSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
			
			FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			
			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldRequiresDepositForContainer);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			
			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldIsToReturnReusableContainer);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = False;
			
			ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
			
		Else
			//
			Item = ConditionalAppearance.Items.Add();

			ItemField = Item.Fields.Items.Add();
			FormField = FormItems[NameOfPriceInputField]; // FormField
			ItemField.Field = New DataCompositionField(FormField.Name);

			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToPriceSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

			FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

			ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToProductTypeSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(Enums.ItemsTypes.OwnGoods);
			ValueList.Add(Enums.ItemsTypes.OperationService);
			ValueList.Add(Enums.ItemsTypes.Work_5);
			ItemFilter.RightValue = ValueList;

			FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

			ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToProductTypeSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

			FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldRequiresDepositForContainer);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;

			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldIsToReturnReusableContainer);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = False;

			Item.Appearance.SetParameterValue("MarkIncomplete", True);

			//
			
			Item = ConditionalAppearance.Items.Add();

			ItemField = Item.Fields.Items.Add();
			FormField = FormItems[NameOfAmountInputField]; // FormField
			ItemField.Field = New DataCompositionField(FormField.Name);

			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSumSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

			FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

			ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToProductTypeSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(Enums.ItemsTypes.OwnGoods);
			ValueList.Add(Enums.ItemsTypes.OperationService);
			ValueList.Add(Enums.ItemsTypes.Work_5);
			ItemFilter.RightValue = ValueList;

			FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

			ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToProductTypeSelectionField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

			FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldRequiresDepositForContainer);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;

			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldIsToReturnReusableContainer);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = False;

			Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion 

#Region Private

#Region Other

// The function returns the start date for the return of the container, depending on the document and business transaction.
//
// Parameters:
//		Object - DocumentObject - the document being checked.
//	
//	Returned value
//		Dateusedforstatistics - date - starting date of the return packaging.
//
Function DetermineTareReturnReferenceDate(Object)
	
	ThereIsDateOfTransferOfOwnership = Common.HasObjectAttribute("DateOfTransferOfTitleToGoods", Object.Metadata());
	ThereIsBusinessTransactions = Common.HasObjectAttribute("BusinessOperation", Object.Metadata());
	
	BusinessTransaction = ?(ThereIsBusinessTransactions, Object.BusinessOperation, Undefined);
	DateOfTransferOfTitleToGoods = ?(ThereIsDateOfTransferOfOwnership, 
		Object.DateOfTransferOfTitleToGoods, 
		Date('00010101'));
	
	If (BusinessTransaction = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or BusinessTransaction = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		And ValueIsFilled(DateOfTransferOfTitleToGoods) Then
		
		TareReturnReferenceDate = DateOfTransferOfTitleToGoods;
	Else
		TareReturnReferenceDate = Object.Date;
	EndIf;
	
	Return TareReturnReferenceDate;
	
EndFunction

Procedure PopulateColumns(ColumnsArray1, SourceRow, DestinationRow)
	
	If ColumnsArray1.Count() = 5 Then
		If ValueIsFilled(ColumnsArray1[4]) Then
			DestinationRow[ColumnsArray1[4]] = SourceRow.DateOfReceipt;
		EndIf;
		If ValueIsFilled(ColumnsArray1[3]) Then
			DestinationRow[ColumnsArray1[3]] = SourceRow.Date;
		EndIf;
		If ValueIsFilled(ColumnsArray1[2]) Then
			DestinationRow[ColumnsArray1[2]] = SourceRow.Warehouse;
		EndIf;
	ElsIf ColumnsArray1.Count() = 4 Then
		If ValueIsFilled(ColumnsArray1[3]) Then
			DestinationRow[ColumnsArray1[3]] = SourceRow.Date;
		EndIf;
		If ValueIsFilled(ColumnsArray1[2]) Then
			DestinationRow[ColumnsArray1[2]] = SourceRow.Warehouse;
		EndIf;
	ElsIf ColumnsArray1.Count() = 3 Then
		If ValueIsFilled(ColumnsArray1[2]) Then
			DestinationRow[ColumnsArray1[2]] = SourceRow.Warehouse;
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#EndRegion

