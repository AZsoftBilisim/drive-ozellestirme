//////////////////////////////////////////////////////////////////////////////////////////
// Comparison of the nomenclature of counterparties:
// a mechanism for comparing the nomenclature of counterparties with the nomenclature of the information base.
//
/////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates the "default identifier" of the counterparty's item in case from an external source 
// (the information system from which the mapping is performed) the ID could not be obtained.
// Calculated as the hash sum of the natural keys of the counterparty's nomenclature.
//
// Parameters:
//  ProductCrossReference - See ProductCrossReferencesMappingClientServer.NewCounterpartyProducts
//  Content - Array of String - The names of the Agent nomenclature keys that should be included in the identifier,
//                              the default value of the natural key nomenclature of the agent
//
// Returns:
//  String - query text.
//
Function PartnerProductIdByNaturalKeys(Val ProductCrossReference, 
	Val Content = Undefined) Export
	
	If TypeOf(Content) <> Type("Array") Then
		Content = NaturalKeysOfItemOfCounterparty();
	EndIf;
	
	Var_Key = New Structure(StrConcat(Content,","));
	FillPropertyValues(Var_Key, ProductCrossReference);
	
	For Each ItemOfKey In Var_Key Do
		Var_Key.Insert(ItemOfKey.Key, TrimAll(ItemOfKey.Value));
	EndDo;
	
	Prefix = "";
	
	Return StrTemplate("%1%2", Prefix, Common.CheckSumString(Var_Key));
	
EndFunction

#Region FillingInCounterpartyProductCatalog

// Creates a new or updates an existing counterparty item.
//
// Parameters:
//  CounterpartyProductData - Structure - the data of the counterparty's item to create the item.
//                                              See ProductCrossReferencesMappingClientServer.NewCounterpartyProducts.
//  InformationSecurityProducts                - Structure - compliance with the nomenclature of the information base.
//                                              See ProductCrossReferencesMappingClientServer.NewProductsForInformationBase. 
//  Cancel                         - Boolean - an error occurred while writing the object.
//  ErrorTextToUser       - String - the text of the error when an exception occurs.
//  AdditionalParameters       - Structure - managed parameters when recording the counterparty's item.
//                                              See NewAdditionalParametersWhenRecordingCounterpartyProducts.
//  MarkToDelete            - Boolean - indicates whether it is marked for deletion.
//
Procedure CreateUpdateCounterpartyProducts(CounterpartyProductData,
												Val InformationSecurityProducts,
												Cancel,
												ErrorTextToUser = "",
												Val AdditionalParameters = Undefined,
												Val MarkToDelete = False) Export
	
	ItemOwner = CounterpartyProductData.Owner;
	ErrorText = "";
	
	If Not ValueIsFilled(ItemOwner) Then
		ErrorTextToUser = NStr("vi = 'Chưa điền đối tượng chủ của mặt hàng.';
								|ru = 'Не заполнен владелец номенклатуры.';
								|en = 'The owner of items is blank.'; fa = 'The owner of items is blank.';
								|it = 'Il titolare di prodotti non è compilato.';
								|pl = 'Nie wypełniono właściciela pozycji.';
								|tr = 'Öğenin sahibi doldurulmadı.'");
		Cancel = True;
		Return;
	EndIf;
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = NewAdditionalParametersWhenRecordingCounterpartyProducts();
	EndIf;
	RegisterEntryIsRequired                = AdditionalParameters.RegisterEntryIsRequired;
	LinkSearchRequired                   = AdditionalParameters.LinkSearchRequired;
	SearchForUnitOfMeasureByOceaniaIsRequired   = AdditionalParameters.SearchForUnitOfMeasureByOceaniaIsRequired;
	CounterpartyProductRegisterData = AdditionalParameters.CounterpartyProductRegisterData;
	
	ProductCrossReference = CounterpartyProductData.ProductCrossReference;
	
	ObjectMetadata = Metadata.Catalogs.ProductCrossReferences;
	FullObjectName  = ObjectMetadata.FullName();
	
	Presentations = ProductCrossReferencesMappingInternal.PresentationsOfCounterpartyProductRange();
	ProductCrossReferencesMappingOverridable.WhenDefiningPresentationsOfProductCollation(
			Presentations);
	OwnerOfProductInGenitiveCase = Lower(Presentations.OwnerOfProductInGenitiveCase);
	
	BeginTransaction();
	Try
		GeneralPurposeEDL.SetManagedLock(FullObjectName,
			New Structure("ItemOwner", ItemOwner));

		If Not ValueIsFilled(ProductCrossReference) And LinkSearchRequired Then
			ProductCrossReference = ReferenceOfCounterpartyProductsBasedOnCounterpartyData(CounterpartyProductData);
		EndIf;

		If ValueIsFilled(ProductCrossReference) Then
			CounterpartyProductItem = ProductCrossReference.GetObject();
			ErrorMessageText_ = StrTemplate(NStr("vi = 'Không thể thay đổi mặt hàng %1 %2 theo đối tượng chủ %3';
												|ru = 'Не удалось изменить номенклатуру %1 %2 по владельцу %3';
												|en = 'Cannot change items %1 %2 by owner %3'; fa = 'Cannot change items %1 %2 by owner %3';
												|it = 'Non è stato possibile modificare articoli %1%2 per titolare %3';
												|pl = 'Nie udało się zmienić pozycji %1 %2 wg właściciela %3';
												|tr = '%3 sahibinin %1 %2 öğeleri düzenlenemedi.'", Common.DefaultLanguageCode()),
									OwnerOfProductInGenitiveCase,
									ProductCrossReference.Description,
									ItemOwner);
			GeneralPurposeEDL.SetManagedLockOnLink(ProductCrossReference);
		ElsIf Not MarkToDelete Then
			CounterpartyProductItem = Catalogs.ProductCrossReferences.CreateItem();
			ErrorMessageText_ = StrTemplate(NStr("vi = 'Không thể tạo mới mặt hàng %1 theo đối tượng chủ %2';
												|ru = 'Не удалось создать новую номенклатуру %1 по владельцу %2';
												|en = 'Cannot create new item %1 by owner %2'; fa = 'Cannot create new item %1 by owner %2';
												|it = 'Non è stato possibile creare nuovo articolo %1 per titolare %2';
												|pl = 'Nie udało się utworzyć nowej pozycji %1 wg właściciela %2';
												|tr = '%2 sahibinin yeni %1 öğesi oluşturulamadı.'", Common.DefaultLanguageCode()),
									OwnerOfProductInGenitiveCase,
									ItemOwner);
		Else
			CommitTransaction();
			Return;
		EndIf;

		If Not MarkToDelete Then

			FillInCounterpartySProductItem(CounterpartyProductItem, CounterpartyProductData,
				InformationSecurityProducts, SearchForUnitOfMeasureByOceaniaIsRequired, CounterpartyProductRegisterData);

			If CounterpartyProductItem.DeletionMark Then
				CounterpartyProductItem.DeletionMark = False;
			EndIf;
		
			
		Else
			CounterpartyProductItem.DeletionMark = True;
		EndIf;
		
		If Not RegisterEntryIsRequired Then
			CounterpartyProductItem.AdditionalProperties.Insert("Synchronization");
		EndIf;

		CounterpartyProductItem.Write();
		CounterpartyProductItem.Unlock();
		CounterpartyProductData.ProductCrossReference = CounterpartyProductItem.Ref;
		
			
		CommitTransaction();
	Except
		RollbackTransaction();
		BriefErrorDescription = BriefErrorDescription(ErrorInfo());
		ErrorText = DetailErrorDescription(ErrorInfo());
		If IsBlankString(ErrorTextToUser) Then
			ErrorTextToUser = StrTemplate(NStr("vi = '%1 do nguyên nhân:
													|%2';
													|ru = '%1 по причине:
													|%2';
													|en = '%1 due to:
													|%2'; fa = '%1 due to:
													|%2';
													|it = '%1 a causa di:
													|%2';
													|pl = '%1 z powodu:
													|%2';
													|tr = '%1 şu sebeple:
													|%2'", Common.DefaultLanguageCode()),
													ErrorMessageText_,
													BriefErrorDescription);
		EndIf;
		
		WriteParameters = GeneralPurposeEDL.NewLogEntryOptions();
		WriteParameters.Data = CounterpartyProductItem;
		GeneralPurposeEDL.WriteToLog_(ErrorText,
			GeneralPurposeEDLClientServer.BadSubsystems().ProductCrossReferencesMapping,, WriteParameters);
		
		Cancel = True;
		
	EndTry;
	
EndProcedure

// Fills in the data of the counterparty's nomenclature by reference or object of the counterparty's nomenclature reference.
//
// Parameters:
//  ProductCrossReference       - CatalogRef.ProductCrossReferences - the object of the counterparty's nomenclature.
//                                  Reference object.Counterparty Nomenclature - reference to the counterparty's nomenclature.
//  CounterpartyProductData - Structure                                 - data of the counterparty's nomenclature.
//                                                                              See ProductCrossReferencesMappingClientServer.NewCounterpartyProducts.
//
Procedure FillInDataOfCounterpartySProductListUsingLink(ProductCrossReference, CounterpartyProductData) Export
	
	FillPropertyValues(CounterpartyProductData, ProductCrossReference);
	CounterpartyProductData.Owner                = ProductCrossReference.ItemOwner;
	If TypeOf(ProductCrossReference) = Type("CatalogObject.ProductCrossReferences") Then
		CounterpartyProductData.ProductCrossReference = ProductCrossReference.Ref;
	Else
		CounterpartyProductData.ProductCrossReference = ProductCrossReference;
	EndIf;
	CounterpartyProductData.Characteristic          = ProductCrossReference.ItemVariantName;
	CounterpartyProductData.Description            = ProductCrossReference.ItemName;
	CounterpartyProductData.UnitOfMeasure        = ProductCrossReference.BaseUnitOfMeasureDescription;
	CounterpartyProductData.PackageName    = ProductCrossReference.PackageName;
	CounterpartyProductData.UnitOfMeasureCode     = ProductCrossReference.BaseUnitOfMeasureARCMUCode;
	CounterpartyProductData.CombinationBarcode      = ProductCrossReference.Barcode;
	CounterpartyProductData.ItemsBarcodes   = ProductCrossReference.OtherItemsBarcodes;
	
EndProcedure

// Fills in the object of the counterparty's nomenclature based on the transmitted data of the counterparty's nomenclature.
//
// Parameters:
//  CounterpartyProductItem          - CatalogObject.ProductCrossReferences - the object of the counterparty's nomenclature.
//  CounterpartyProductData          - Structure of See ProductCrossReferencesMappingClientServer.NewCounterpartyProducts -
//                                                                                     data of the counterparty's nomenclature.
//  InformationSecurityProducts                         - Structure of See ProductCrossReferencesMappingClientServer.NewProductsForInformationBase -
//                                                                                     data of the nomenclature of the information base.
//  SearchForUnitOfMeasureByOceaniaIsRequired   - Boolean                                    - indicates whether it is necessary to search for a unit of measurement in the OCEAN
//                                                                                       to fill in the counterparty's data, if the unit of measurement was not filled in.
//  CounterpartyProductRegisterData - Boolean                                    - the data of the counterparty's nomenclature is filled in from the information register
//                                                                                       Nomenclatura Kontragentovbed.
//
Procedure FillInCounterpartySProductItem(CounterpartyProductItem, CounterpartyProductData, Val InformationSecurityProducts = Undefined,
				Val SearchForUnitOfMeasureByOceaniaIsRequired = True, Val CounterpartyProductRegisterData = False) Export
				
	ObjectData = New Structure;
	For Each ObjectAttribute In CounterpartyProductItem.Metadata().Attributes Do
		ObjectData.Insert(ObjectAttribute.Name);
	EndDo;
	ObjectData.Insert("Description");
	ObjectData.Insert("Owner");
	
	If ValueIsFilled(Metadata.Catalogs.ProductCrossReferences.Owners) Then
		FillPropertyValues(ObjectData, CounterpartyProductData, ,
			"Description, QuantityInBaseUnitOfMeasure, NumberOfPackages");
	Else
		FillPropertyValues(ObjectData, CounterpartyProductData, ,
			"Description, Owner, QuantityInBaseUnitOfMeasure, NumberOfPackages");
	EndIf;
	ObjectData.ItemOwner               = CounterpartyProductData.Owner;
	ObjectData.ItemVariantName         = CounterpartyProductData.Characteristic;
	ObjectData.ItemName           = CounterpartyProductData.Description;
	ObjectData.Barcode                           = CounterpartyProductData.CombinationBarcode;
	ObjectData.OtherItemsBarcodes = CounterpartyProductData.ItemsBarcodes;
	
	If IsBlankString(ObjectData.Id) Then
		
		ObjectData.Id = PartnerProductIdByNaturalKeys(CounterpartyProductData);
	EndIf;
	
	If IsBlankString(CounterpartyProductData.ProductsIdentifier) Then
		ProductCrossReferencesMappingClientServer.SplitIDIntoParts(ObjectData.Id,
																						ObjectData);
		CounterpartyProductData.ProductsIdentifier   = ObjectData.ProductsIdentifier;
		CounterpartyProductData.ItemVariantID = ObjectData.ItemVariantID;
		CounterpartyProductData.PackageID       = ObjectData.PackageID;
	EndIf;
	
	FillInInformationOfUnitsOfMeasurementOfPackages(ObjectData, CounterpartyProductData,
		SearchForUnitOfMeasureByOceaniaIsRequired, CounterpartyProductRegisterData);
		
	If Not ValueIsFilled(ObjectData.DescriptionFull) Then
		
		ObjectData.DescriptionFull = Catalogs.ProductCrossReferences.FullNameOfCounterpartyProducts(
																							ObjectData.ItemName,
																							ObjectData.ItemVariantName,
																							ObjectData.PackageName);
	EndIf;
	
	If IsBlankString(CounterpartyProductItem.Description) Then
	ObjectData.Description = ObjectData.DescriptionFull;
	Else
		ObjectData.Description = CounterpartyProductItem.Description;
	EndIf;
	
	If ValueIsFilled(InformationSecurityProducts) Then
		If ValueIsFilled(InformationSecurityProducts.Products) Then
			ObjectData.Products = InformationSecurityProducts.Products;
		EndIf;
		If ValueIsFilled(InformationSecurityProducts.Characteristic) Then
			ObjectData.Characteristic = InformationSecurityProducts.Characteristic;
		EndIf;
		If ValueIsFilled(InformationSecurityProducts.Package) Then
			ObjectData.Package = InformationSecurityProducts.Package;
		EndIf;

		If ValueIsFilled(ObjectData.Products) 
			And Not ValueIsFilled(ObjectData.Package) Then
			ProductCrossReferencesMappingOverridable.BasicUnitOfProductMeasurement(
				ObjectData.Products, ObjectData.Package);
		EndIf;
		
	EndIf;
	
	DeleteEmptyStructureProperties(ObjectData);
	FillPropertyValues(CounterpartyProductItem, ObjectData);
	FillInOtherProductBarcodes(CounterpartyProductItem);
		
EndProcedure

// Fills in an empty comparison in the counterparty's nomenclature for the nomenclature of the information base from the goods table.
//
// Parameters:
//  TableOfGoods            - ValueTable - the product table that will be placed in the temporary table.
//  Cancel                     - Boolean          - indicates whether there are errors during the execution of the procedure.
//  DefaultProductTable - Boolean          - indicates whether to use the temporary Goods table with columns:
//                                                Ingredient nomenclature, Nomenclature, Characteristics, Packaging. 
//
Procedure FillInEmptyMappingInCounterpartySProductNameForInformationSecurityProductName(Val TableOfGoods, Cancel, DefaultProductTable = False) Export
	
	Query = New Query;
	Query.SetParameter("Goods", TableOfGoods);
	Query.SetParameter("EmptyItemList", ProductCrossReferencesMappingInternal.EmptyBadProductReference());
	
	Query.Text = 
	"SELECT
	|	Goods.ProductCrossReference AS ProductCrossReference,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package AS Package
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.Products <> &EmptyItemList
	|	AND Goods.ProductCrossReference <> VALUE(Catalog.ProductCrossReferences.EmptyRef)";

	QueryText = "";
	ProductCrossReferencesMappingOverridable.TextOfSearchRequestForUnmappedProductListOfCounterpartiesForInformationSecurityProductList(
		QueryText, DefaultProductTable);
		
	If IsBlankString(QueryText) Then
		Query.Text = Query.Text + Common.QueryBatchSeparator() +
		"SELECT
		|	Goods.ProductCrossReference AS ProductCrossReference,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Package AS Package
		|FROM
		|	Goods AS Goods
		|		INNER JOIN Catalog.ProductCrossReferences AS ProductCrossReferences
		|		ON Goods.ProductCrossReference = ProductCrossReferences.Ref
		|WHERE
		|	ProductCrossReferences.Products = &EmptyItemList";
		
	ElsIf DefaultProductTable Then
		Query.Text = Query.Text + Common.QueryBatchSeparator() + QueryText;
	Else
		Query.Text = QueryText;
	EndIf;
	
	Selection = Query.Execute().Select();

	While Selection.Next() Do
		
		ProductCrossReference = Selection.ProductCrossReference;
		
		Try
			
			LockDataForEdit(ProductCrossReference);
			
			ProductCrossReferenceObject = ProductCrossReference.GetObject(); // CatalogObject
			FillPropertyValues(ProductCrossReferenceObject, Selection);
			ProductCrossReferenceObject.Write();
			
		Except
			
			ErrorText = NStr("vi = 'Không thể phong tỏa %Item%. %ErrorDescription%';
							|ru = 'Не удалось заблокировать %Item%. %ErrorDescription%';
							|en = 'Cannot lock %Item%.%ErrorDescription%'; fa = 'Cannot lock %Item%.%ErrorDescription%';
							|it = 'Non è stato possibile bloccare %Item%. %ErrorDescription%';
							|pl = 'Blokowanie %Item% nie powiodło się. %ErrorDescription%';
							|tr = '%Item% bloke edilemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Item%",        ProductCrossReference);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
			Cancel = True;
			Raise ErrorText;
			
		EndTry;
		
	EndDo;

EndProcedure

// Returns additional parameters when recording the counterparty item.
//
// Returns:
//  Structure - Contains Parameters:
//   * RegisterEntryIsRequired                - Boolean - indicates whether an entry in the Nomenclaturecontragentsbed information register needs to be updated.
//   * LinkSearchRequired                   - Boolean - indicates whether to search for the counterparty's item reference.
//   * SearchForUnitOfMeasureByOceaniaIsRequired   - Boolean - indicates whether it is necessary to search for a unit of measurement in the OCEAN
//                                                       to fill in the counterparty's data, if the unit of measurement was not filled in.
//   * CounterpartyProductRegisterData - Boolean - The data of the counterparty's nomenclature is filled in from the Nomenclaturecontragentsbed data register.
//   * UseCharacteristics - Boolean,Undefined - indicates whether the feature is used in the nomenclature.
//
Function NewAdditionalParametersWhenRecordingCounterpartyProducts() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RegisterEntryIsRequired"               , True);
	AdditionalParameters.Insert("LinkSearchRequired"                  , True);
	AdditionalParameters.Insert("SearchForUnitOfMeasureByOceaniaIsRequired"  , True);
	AdditionalParameters.Insert("CounterpartyProductRegisterData", False);
	AdditionalParameters.Insert("UseCharacteristics", Undefined);
	
	Return AdditionalParameters;
	
EndFunction

#EndRegion

#Region SearchForProductListOfCounterparties

// Returns the query text with duplicate rows of the non-matched counterparty's nomenclature in the goods table.
// The request uses the Empty Nomenclature parameter, which must be set in the request.
// The product table should contain columns:
//   Line Number - Line - item line number.
//   The nomenclature of the agent is a reference link.Nomenclature of counterparties - reference of the counterparty's nomenclature.
//   Nomenclature            - Definable type.NomenclatoraBED - the reference of the nomenclature.
//   Characteristic - Definable type.Characteristic Nomenclature - reference characteristics.
//   Packaging is a definable type.Packagenomendurybed - packaging reference.
//
// Parameters:
//  NameOfTemporaryProductTable - String - name of the temporary table. By default, the name is "Temporary tabletables".
//
// Returns:
//  String - query text.
//
Function TextOfSearchRequestForDuplicateRowsOfUnmappedCounterpartyProductList(Val NameOfTemporaryProductTable = Undefined) Export
	
	QueryText = "SELECT
	|	MAX(NestedRequestForDuplicates.LineNumber) AS LineNumber,
	|	NestedRequestForDuplicates.ProductCrossReference AS ProductCrossReference
	|FROM
	|	(SELECT
	|		MAX(DocumentGoods.LineNumber) AS LineNumber,
	|		DocumentGoods.ProductCrossReference AS ProductCrossReference,
	|		DocumentGoods.Products AS Products,
	|		DocumentGoods.Characteristic AS Characteristic,
	|		DocumentGoods.Package AS Package
	|	FROM
	|		&NameOfTemporaryProductTable AS DocumentGoods
	|	WHERE
	|		DocumentGoods.Products <> &EmptyItemList
	|		AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.ProductCrossReferences AS ProductCrossReferences
	|				WHERE
	|					ProductCrossReferences.Ref = DocumentGoods.ProductCrossReference
	|					AND ProductCrossReferences.Products =&EmptyItemList)
	|	
	|	GROUP BY
	|		DocumentGoods.ProductCrossReference,
	|		DocumentGoods.Products,
	|		DocumentGoods.Characteristic,
	|		DocumentGoods.Package) AS NestedRequestForDuplicates
	|
	|GROUP BY
	|	NestedRequestForDuplicates.ProductCrossReference
	|
	|HAVING
	|	COUNT(*) > 1";
	
	Return StrReplace(QueryText, "&NameOfTemporaryProductTable", 
		?(NameOfTemporaryProductTable = Undefined, "TemporaryTableOfGoods_", NameOfTemporaryProductTable));
		
EndFunction

// Returns the result of a query with a unique counterparty item found in the product table when the owner changes.
//
// Parameters:
//  ItemOwner - DefinedType.ItemOwnerEDL - the owner of the item.
//  Goods               - ValueTable                         - contains columns:
//   * LineNumber             - String                                        - the number of the row in the items table IB.
//                                                                               If the column is missing, it is added to the table.
//   * Products            - DefinedType.EDLProducts               - nomenclature of the information base.
//   * Characteristic          - DefinedType.ItemsCharacteristicEDL - characteristics of the information base.
//   * Package                - DefinedType.PackageEDLItems       - packaging of the information base.
//   * ProductCrossReference - CatalogRef.ProductCrossReferences     - reference of the counterparty nomenclature.
//                                                                               If the column is missing, it is added to the table.
//                                                                               It is used for searching by the ID of a similar
//                                                                               item of the counterparty when the owner changes.
//
// Returns:
//  QueryResult - the result of the search query for the counterparty's nomenclature by the nomenclature of the information base:
//   * LineNumber             - String                                        - line number from the Products table.
//   * ProductCrossReference - CatalogRef.ProductCrossReferences     - reference of the counterparty nomenclature.
//
Function ResultOfCounterpartyProductSearchQueryWhenOwnerChanges(Val ItemOwner, Val Goods) Export
	
	If Goods.Columns.Find("LineNumber") = Undefined Then
		LineNumberType = New TypeDescription("Number", New NumberQualifiers(15, 0, AllowedSign.Nonnegative));
		Goods.Columns.Add("LineNumber", LineNumberType);
	EndIf;
	
	If Goods.Columns.Find("ProductCrossReference") = Undefined Then
		Goods.Columns.Add("ProductCrossReference", New TypeDescription("CatalogRef.ProductCrossReferences"));
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ItemOwner", ItemOwner);
	Query.SetParameter("Goods", Goods);
	Query.Text = 
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package AS Package,
	|	Goods.ProductCrossReference AS ProductCrossReference
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	ProductCrossReferences.Ref AS ProductCrossReference,
	|	Goods.ProductCrossReference AS OldProducts_
	|INTO CounterpartyProductsById
	|FROM
	|	Goods AS Goods
	|		INNER JOIN Catalog.ProductCrossReferences AS OldCounterpartyProducts
	|			INNER JOIN Catalog.ProductCrossReferences AS ProductCrossReferences
	|			ON OldCounterpartyProducts.Id = ProductCrossReferences.Id
	|				AND (TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						Goods AS Goods
	|					WHERE
	|						Goods.Products = ProductCrossReferences.Products
	|						AND Goods.Characteristic = ProductCrossReferences.Characteristic
	|						AND Goods.Package = ProductCrossReferences.Package))
	|		ON Goods.ProductCrossReference = OldCounterpartyProducts.Ref
	|WHERE
	|	ProductCrossReferences.ItemOwner = &ItemOwner
	|	AND NOT ProductCrossReferences.DeletionMark
	|	AND NOT ProductCrossReferences.Invalid
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CounterpartyProductsById.ProductCrossReference AS ProductCrossReference,
	|	CounterpartyProductsById.LineNumber AS LineNumber
	|FROM
	|	CounterpartyProductsById AS CounterpartyProductsById
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(ProductCrossReferences.Ref),
	|	Goods.LineNumber
	|FROM
	|	Goods AS Goods
	|		INNER JOIN Catalog.ProductCrossReferences AS ProductCrossReferences
	|		ON Goods.Products = ProductCrossReferences.Products
	|			AND Goods.Characteristic = ProductCrossReferences.Characteristic
	|			AND Goods.Package = ProductCrossReferences.Package
	|			AND (NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						CounterpartyProductsById AS CounterpartyProductsById
	|					WHERE
	|						CounterpartyProductsById.OldProducts_ = Goods.ProductCrossReference))
	|WHERE
	|	ProductCrossReferences.ItemOwner = &ItemOwner
	|	AND NOT ProductCrossReferences.DeletionMark
	|	AND NOT ProductCrossReferences.Invalid
	|
	|GROUP BY
	|	Goods.LineNumber
	|
	|HAVING
	|	COUNT(*) = 1";
	
	Return Query.Execute();
	
EndFunction

// Returns the result of the query with the found unambiguous nomenclature of the counterparty for the nomenclature of the information base in the context of the owner.
//
// Parameters:
//  ItemOwner - DefinedType.ItemOwnerEDL - the owner of the item.
//  Goods               - ValueTable                         - contains columns:
//   * LineNumber             - String                                        - the number of the row in the items table IB.
//                                                                               If the column is missing, it is added to the table.
//   * Products            - DefinedType.EDLProducts               - nomenclature of the information base.
//   * Characteristic          - DefinedType.ItemsCharacteristicEDL - characteristics of the information base.
//   * Package                - DefinedType.PackageEDLItems       - packaging of the information base.
//   * ProductCrossReference - CatalogRef.ProductCrossReferences     - reference of the counterparty nomenclature.
//                                                                               If the column is missing, it is added to the table.
//                                                                               It is used for searching by the ID of a similar
//                                                                               item of the counterparty when the owner changes.
//
// Returns:
//  QueryResult - the result of the search query for the counterparty's nomenclature by the nomenclature of the information base:
//   * LineNumber                        - String                                        - line number from the Products table.
//   * ProductCrossReference            - CatalogRef.ProductCrossReferences     - reference of the counterparty nomenclature.
//   * NumberOfCounterpartyProducts_ - Number                                         - the number of counterparty items found by filtering.
//   * Products                       - DefinedType.EDLProducts               - nomenclature of the information base.
//   * Characteristic                     - DefinedType.ItemsCharacteristicEDL - characteristics of the information base.
//   * Package                           - DefinedType.PackageEDLItems       - packaging of the information base.
//
Function ResultOfSearchQueryForCounterpartyProductsByInformationSecurityProducts(Val ItemOwner, Val Goods) Export
	
	If Goods.Columns.Find("LineNumber") = Undefined Then
		LineNumberType = New TypeDescription("Number", New NumberQualifiers(15, 0, AllowedSign.Nonnegative));
		Goods.Columns.Add("LineNumber", LineNumberType);
	EndIf;
	
	If Goods.Columns.Find("ProductCrossReference") = Undefined Then
		Goods.Columns.Add("ProductCrossReference", New TypeDescription("CatalogRef.ProductCrossReferences"));
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ItemOwner", ItemOwner);
	Query.SetParameter("Goods"              , Goods);
	Query.SetParameter("EmptyItemList"  , ProductCrossReferencesMappingInternal.EmptyBadProductReference());
	
	Query.Text = 
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package AS Package,
	|	Goods.ProductCrossReference AS ProductCrossReference
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.Products <> &EmptyItemList
	|	AND Goods.ProductCrossReference = VALUE(Catalog.ProductCrossReferences.EmptyRef)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ProductCrossReferences.Ref) AS ProductCrossReference,
	|	Goods.LineNumber AS LineNumber
	|FROM
	|	Goods AS Goods
	|		INNER JOIN Catalog.ProductCrossReferences AS ProductCrossReferences
	|		ON Goods.Products = ProductCrossReferences.Products
	|			AND Goods.Characteristic = ProductCrossReferences.Characteristic
	|			AND Goods.Package = ProductCrossReferences.Package
	|WHERE
	|	ProductCrossReferences.ItemOwner = &ItemOwner
	|	AND NOT ProductCrossReferences.DeletionMark
	|	AND NOT ProductCrossReferences.Invalid
	|
	|GROUP BY
	|	Goods.LineNumber
	|
	|HAVING
	|	COUNT(*) = 1";
	
	Return Query.Execute();
	
EndFunction

// Returns the counterparty's nomenclature found by the nomenclature of the information base in the table row.
//
// Parameters:
//  ItemOwner - DefinedType.ItemOwnerEDL - the owner of the item.
//  InformationSecurityProducts       - Structure                               - contains information from a table row.
//                               See ProductCrossReferencesMappingClientServer.NewProductsForInformationBase.
//
// Returns:
//  CatalogRef.ProductCrossReferences - a link to the counterparty's nomenclature found.
//                                              If the counterparty's nomenclature is not found, an empty link is returned.
//
Function CounterpartyProductsByProductsInTableRow(Val ItemOwner, Val InformationSecurityProducts) Export
	
	Query = New Query;
	Query.SetParameter("ItemOwner"   , ItemOwner);
	Query.SetParameter("Products"           , InformationSecurityProducts.Products);
	Query.SetParameter("Characteristic"         , InformationSecurityProducts.Characteristic);
	Query.SetParameter("Package"               , InformationSecurityProducts.Package);
	Query.SetParameter("ProductCrossReference", InformationSecurityProducts.ProductCrossReference);
	Query.SetParameter("EmptyItemList"     , ProductCrossReferencesMappingInternal.EmptyBadProductReference());
	
	Query.Text =
	"SELECT
	|	MAX(ProductCrossReferences.Ref) AS ProductCrossReference,
	|	COUNT(*) AS NumberOfCounterpartyProducts
	|INTO SearchProducts
	|FROM
	|	Catalog.ProductCrossReferences AS ProductCrossReferences
	|WHERE
	|	ProductCrossReferences.ItemOwner = &ItemOwner
	|	AND ProductCrossReferences.Products = &Products
	|	AND ProductCrossReferences.Characteristic = &Characteristic
	|	AND ProductCrossReferences.Package = &Package
	|	AND NOT ProductCrossReferences.DeletionMark
	|	AND NOT ProductCrossReferences.Invalid
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN ProductCrossReferences.Products = &EmptyItemList
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS MappingIsFull,
	|	CASE
	|		WHEN ProductCrossReferences.Products = &Products
	|				AND ProductCrossReferences.Characteristic = &Characteristic
	|				AND ProductCrossReferences.Package = &Package
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Matched,
	|	ProductCrossReferences.Ref AS ProductCrossReference
	|INTO ProductListOfCounterpartiesFromTable
	|FROM
	|	Catalog.ProductCrossReferences AS ProductCrossReferences
	|WHERE
	|	ProductCrossReferences.Ref = &ProductCrossReference
	|
	|GROUP BY
	|	CASE
	|		WHEN ProductCrossReferences.Products = &EmptyItemList
	|			THEN FALSE
	|		ELSE TRUE
	|	END,
	|	CASE
	|		WHEN ProductCrossReferences.Products = &Products
	|				AND ProductCrossReferences.Characteristic = &Characteristic
	|				AND ProductCrossReferences.Package = &Package
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	ProductCrossReferences.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN ProductListOfCounterpartiesFromTable.Matched = TRUE
	|			THEN ProductListOfCounterpartiesFromTable.ProductCrossReference
	|		ELSE CASE
	|				WHEN SearchProducts.NumberOfCounterpartyProducts = 1
	|					THEN SearchProducts.ProductCrossReference
	|				ELSE CASE
	|						WHEN ProductListOfCounterpartiesFromTable.MappingIsFull = FALSE
	|							THEN ProductListOfCounterpartiesFromTable.ProductCrossReference
	|						ELSE VALUE(Catalog.ProductCrossReferences.EmptyRef)
	|					END
	|			END
	|	END AS ProductCrossReference
	|FROM
	|	SearchProducts AS SearchProducts
	|		FULL JOIN ProductListOfCounterpartiesFromTable AS ProductListOfCounterpartiesFromTable
	|		ON (TRUE)";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.ProductCrossReference;
	Else
		Return Catalogs.ProductCrossReferences.EmptyRef();
	EndIf;
	
EndFunction

// Returns a table of counteragent item data found by unique identifiers.
//
// Parameters:
//  UniqueIdentifiers - Array of String - unique identifiers for which to return the data of the counterparty nomenclature.
//
// Returns:
//  ValueTable - Counterparty Product Data:
//   * ProductCrossReference             - CatalogRef.ProductCrossReferences - reference of the counterparty's nomenclature.
//   * ItemOwner                - DefinedType.ItemOwnerEDL   - reference to the owner of the counterparty's item.
//   * Id                       - String                                    - id of the counterparty's item.
//   * ServiceItemID    - String                                    - id of the item in the 1C service:Nomenclature.
//   * ServiceVariantID  - String                                    - id of the characteristic in the 1C service:Nomenclature.
//   * ItemName            - String                                    - name of the item.
//   * ItemVariantName          - String                                    - name of the characteristic.
//   * PackageName                - String                                    - name of the package.
//   * BaseUnitOfMeasureDescription - String                                    - name of the base unit of measurement.
//   * BaseUnitOfMeasureARCMUCode      - String                                    - The code of the OCEAN unit of measurement.
//   * QuantityInBaseUnitOfMeasure   - String                                    - the numerator.
//   * NumberOfPackages                  - String                                    - denominator.
//   * Barcode                            - String                                    - combination barcode: nomenclature, characteristic, packaging.
//   * OtherItemsBarcodes  - String                                    - the barcode of the item, separated by commas.
//   * SKU                             - String                                    - article number.
//   * VATRate                           - String                                    - VAT rate.
//
Function CounterpartyProductDataByInternalIdentifiers(Val UniqueIdentifiers) Export
	
	CounterpartyProductReferences = New Array;
	For Each Id In UniqueIdentifiers Do
		
		If Not StringFunctionsClientServer.IsUUID(Id) Then
			Continue;
		EndIf;
		
		Ref = Catalogs.ProductCrossReferences.GetRef(New UUID(Id));
		If ValueIsFilled(Ref) Then
			CounterpartyProductReferences.Add(Ref);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("CounterpartyProductReferences", CounterpartyProductReferences);
	Query.Text = 
	"SELECT
	|	ProductCrossReferences.Ref AS ProductCrossReference,
	|	ProductCrossReferences.ItemOwner,
	|	ProductCrossReferences.Id,
	|	ProductCrossReferences.ServiceItemID,
	|	ProductCrossReferences.ServiceVariantID,
	|	ProductCrossReferences.ItemName,
	|	ProductCrossReferences.ItemVariantName,
	|	ProductCrossReferences.PackageName,
	|	ProductCrossReferences.BaseUnitOfMeasureDescription,
	|	ProductCrossReferences.BaseUnitOfMeasureARCMUCode,
	|	ProductCrossReferences.QuantityInBaseUnitOfMeasure,
	|	ProductCrossReferences.NumberOfPackages,
	|	ProductCrossReferences.Barcode,
	|	ProductCrossReferences.OtherItemsBarcodes,
	|	ProductCrossReferences.SKU,
	|	ProductCrossReferences.VATRate
	|FROM
	|	Catalog.ProductCrossReferences AS ProductCrossReferences
	|WHERE
	|	ProductCrossReferences.Ref IN (&CounterpartyProductReferences)";
	
	
	Result = Query.Execute().Unload();
	Result.Columns.Add("RecordKey",  New TypeDescription("String", New StringQualifiers(36)));
	For Each SelectionElement_ In Result Do
		SelectionElement_.RecordKey = XMLString(SelectionElement_.ProductCrossReference);
	EndDo;
	
	Result.Indexes.Add("RecordKey");
	
	Return Result;
	
EndFunction

// Creates a temporary search table for the counterparty nomenclature in the information database based on the selection table.
// Columns:
//  ID-Row-Item ID.
//  Name-Line - name of the item.
//  Namecharacteristics-String - name of the characteristic.
//  Unit of measurement-String - if the name of the package is filled in, it is passed, otherwise the name of the unit of measurement (base).
//  Unit of measurement Code-String - code of the unit of measurement.
//  Article number                             - Line - item item number.
//  StavkaNDS-Line - the VAT rate of the item.
//  Barcode-String-barcode (not used, fields are used instead:combination barcode and item barcode).
//  Combination bar code-String-combination bar code: nomenclature, characteristic, packaging.
//  Barcodes of the nomenclature-Line-barcodes of the nomenclature separated by commas.
//  Service nomenclature identifier-String-ID of the nomenclature in the 1C service:Nomenclature.
//  Service Characteristic identifier-String - identifier of the characteristic in the 1C service:Nomenclature.
//  Package name-String - the name of the package.
//  The name of the base unit of measurement-String-the name of the base unit of measurement.
//  Number of packages-Number - the number of packages (denominator).
//  Quantity of the base unit of measurement-Number-quantity of the unit of measurement (numerator).
//  Owner-Definable type.The proprietor of the nomenclature of the information base is the owner of the nomenclature of the information base.
//  Nomenclature                        - Definable type.Nomenclatureabed-the nomenclature of the information base.
//  Characteristic-Definable type.Characteristics of the nomenclature of the Russian Federation-the characteristics of the information base.
//  Packaging-Definable type.Packaging Nomenclature of the Russian Federation-packaging of the information base.
//
//  The selection is made according to the following combination of fields:
//   Counterparty nomenclature - if the counterparty nomenclature is filled in.
//   Owner, Item, Characteristic, Package - if the counterparty's item is empty.
//
// Parameters:
//  FilterTable           - ValueTable         - table for selecting matching records:
//   * Owner                 - DefinedType.ItemOwnerEDL       - the owner of the item.
//   * ProductCrossReference  - CatalogRef.ProductCrossReferences     - reference of the counterparty's nomenclature.
//   * Products             - DefinedType.EDLProducts               - nomenclature of the information base.
//   * Characteristic           - DefinedType.ItemsCharacteristicEDL - characteristics of the information base.
//   * Package                 - DefinedType.PackageEDLItems       - packaging of the information base.
//  TempTableName     - String                  - the name of the temporary table to place the selected data in.
//  TempTablesManager - TempTablesManager - the temporary table manager where the temporary table will be created.
//
Procedure CreateTemporaryTableOfProductsForContractorsBasedOnSelectionTable(Val FilterTable, Val TempTableName, TempTablesManager) Export
	
	If FilterTable.Columns.Find("LineNumber") = Undefined Then
		LineNumberType = New TypeDescription("Number", New NumberQualifiers(15, 0, AllowedSign.Nonnegative));
		FilterTable.Columns.Add("LineNumber", LineNumberType);
	EndIf;

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	FilterTable.LineNumber AS LineNumber,
	|	FilterTable.Owner AS Owner,
	|	CAST(FilterTable.ProductCrossReference AS Catalog.ProductCrossReferences) AS ProductCrossReference,
	|	FilterTable.Products AS Products,
	|	FilterTable.Characteristic AS Characteristic,
	|	FilterTable.Package AS Package
	|INTO TT_FilterTable
	|FROM
	|	&FilterTable AS FilterTable
	|
	|INDEX BY
	|	Owner,
	|	ProductCrossReference
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ProductCrossReferences.Products AS Products,
	|	ProductCrossReferences.Characteristic AS Characteristic,
	|	ProductCrossReferences.Package AS Package,
	|	ProductCrossReferences.Id AS Id,
	|	ProductCrossReferences.ItemOwner AS Owner,
	|	ProductCrossReferences.ItemName AS Description,
	|	ProductCrossReferences.ItemVariantName AS ItemVariantName,
	|	ProductCrossReferences.PackageName AS UnitOfMeasure,
	|	ProductCrossReferences.BaseUnitOfMeasureDescription AS BaseUnitOfMeasureDescription,
	|	ProductCrossReferences.BaseUnitOfMeasureARCMUCode AS UnitOfMeasureCode,
	|	ProductCrossReferences.QuantityInBaseUnitOfMeasure AS QuantityInBaseUnitOfMeasure,
	|	ProductCrossReferences.NumberOfPackages AS NumberOfPackages,
	|	ProductCrossReferences.Barcode AS CombinationBarcode,
	|	ProductCrossReferences.OtherItemsBarcodes AS ItemsBarcodes,
	|	TT_FilterTable.LineNumber AS LineNumber,
	|	TT_FilterTable.ProductCrossReference AS ProductCrossReference,
	|	ProductCrossReferences.ServiceItemID AS ServiceItemID,
	|	ProductCrossReferences.ServiceVariantID AS ServiceVariantID,
	|	ProductCrossReferences.SKU AS SKU,
	|	ProductCrossReferences.VATRate AS VATRate
	|INTO TT_ProductCrossReferences
	|FROM
	|	TT_FilterTable AS TT_FilterTable
	|		INNER JOIN Catalog.ProductCrossReferences AS ProductCrossReferences
	|		ON TT_FilterTable.ProductCrossReference = ProductCrossReferences.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	ProductCrossReferences.Products,
	|	ProductCrossReferences.Characteristic,
	|	ProductCrossReferences.Package,
	|	ProductCrossReferences.Id,
	|	ProductCrossReferences.ItemOwner,
	|	ProductCrossReferences.ItemName,
	|	ProductCrossReferences.ItemVariantName,
	|	ProductCrossReferences.PackageName,
	|	ProductCrossReferences.BaseUnitOfMeasureDescription,
	|	ProductCrossReferences.BaseUnitOfMeasureARCMUCode,
	|	ProductCrossReferences.QuantityInBaseUnitOfMeasure,
	|	ProductCrossReferences.NumberOfPackages,
	|	ProductCrossReferences.Barcode,
	|	ProductCrossReferences.OtherItemsBarcodes,
	|	TT_FilterTable.LineNumber,
	|	ProductCrossReferences.Ref,
	|	ProductCrossReferences.ServiceItemID,
	|	ProductCrossReferences.ServiceVariantID,
	|	ProductCrossReferences.SKU,
	|	ProductCrossReferences.VATRate
	|FROM
	|	TT_FilterTable AS TT_FilterTable
	|		INNER JOIN Catalog.ProductCrossReferences AS ProductCrossReferences
	|		ON TT_FilterTable.Owner = ProductCrossReferences.ItemOwner
	|			AND TT_FilterTable.Products = ProductCrossReferences.Products
	|			AND TT_FilterTable.Characteristic = ProductCrossReferences.Characteristic
	|			AND TT_FilterTable.Package = ProductCrossReferences.Package
	|WHERE
	|	NOT ProductCrossReferences.DeletionMark
	|	AND NOT ProductCrossReferences.Invalid
	|	AND TT_FilterTable.ProductCrossReference = VALUE(Catalog.ProductCrossReferences.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_FilterTable";
	
	Query.SetParameter("FilterTable", FilterTable);
	
	If TempTableName = "TT_FilterTable" Then
		Query.Text = StrReplace(Query.Text, "TT_FilterTable", "TT_FilterTable1");
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "TT_ProductCrossReferences", TempTableName);
	Query.Execute();
	
EndProcedure

// Returns the result of a query with a uniquely found matched counterparty item by the owner ID.
// The column "Nomenclature of Contragents"is added to the source table.
//
// Parameters:
//  TableOfGoods - ValueTable - contains columns:
//   * LineNumber             - String                                        - the number of the row in the items table IB.
//                                                                               If the column is missing, it is added to the table.
//   * Owner                - DefinedType.ItemOwnerEDL       - the owner of the item.
//   * Products            - DefinedType.EDLProducts               - nomenclature of the information base.
//   * Characteristic          - DefinedType.ItemsCharacteristicEDL - characteristics of the information base.
//   * Package                - DefinedType.PackageEDLItems       - packaging of the information base.
//   * Id           - String                                        - id of the supplier's item.
// 
// Returns:
//  QueryResult - contains columns:
//   * LineNumber             - String                                        - the number of the row in the items table IB.
//                                                                               If the column is missing, it is added to the table.
//   * Owner                - DefinedType.ItemOwnerEDL       - the owner of the item.
//   * Products            - DefinedType.EDLProducts               - nomenclature of the information base.
//   * Characteristic          - DefinedType.ItemsCharacteristicEDL - characteristics of the information base.
//   * Package                - DefinedType.PackageEDLItems       - packaging of the information base.
//   * Id           - String                                        - id of the supplier's item.
//   * ProductCrossReference - CatalogRef.ProductCrossReferences     - reference of the counterparty nomenclature.
//
Function RequestResultForUniquelyMatchedCounterpartyProductsById(TableOfGoods) Export
	
	Query = New Query;
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.Text = 
	"SELECT
	|	TableOfGoods.Owner AS Owner,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.Id AS Id,
	|	TableOfGoods.LineNumber AS LineNumber
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|INDEX BY
	|	Owner,
	|	Products,
	|	Characteristic,
	|	Package,
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Owner AS Owner,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.Id AS Id,
	|	TableOfGoods.LineNumber AS LineNumber,
	|	ISNULL(MAX(ProductCrossReferences.Ref), VALUE(Catalog.ProductCrossReferences.EmptyRef)) AS ProductCrossReference
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.ProductCrossReferences AS ProductCrossReferences
	|		ON TableOfGoods.Owner = ProductCrossReferences.ItemOwner
	|			AND TableOfGoods.Id = ProductCrossReferences.Id
	|
	|GROUP BY
	|	TableOfGoods.Owner,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Package,
	|	TableOfGoods.Id,
	|	TableOfGoods.LineNumber
	|
	|HAVING
	|	COUNT(DISTINCT ProductCrossReferences.Ref) = 1";
	
	Return Query.Execute();
	
EndFunction

#EndRegion


#Region InterfaceImplementation

// StandardSubsystems.DuplicateObjectsDetection

// See DuplicateObjectsDetectionOverridable.OnDefineObjectsWithSearchForDuplicates
Procedure OnDefineObjectsWithSearchForDuplicates(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.ProductCrossReferences.FullName(), "DuplicatesSearchParameters
	|OnSearchForDuplicates");
	
EndProcedure

//End StandardSubsystems.DuplicateObjectsDetection


#EndRegion

#EndRegion

#Region Internal


// See ElectronicInteraction.OnFillListsWithAccessRestriction
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	ProductCrossReferencesMappingOverridable.WhenFillingInListsWithRestrictedAccess_ProductsOfCounterparties(Lists);
	
EndProcedure

// See ElectronicInteraction.OnFillMetadataObjectsAccessRestrictionKinds
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	ProductCrossReferencesMappingOverridable.WhenFillingInTypesOfRightsRestrictionsForMetadataObjects_ProductListOfCounterparties(LongDesc);
	
EndProcedure

Function ProductIDAccordingToProductData(Val Description, Val Characteristic = Undefined, Val UnitOfMeasure = Undefined) Export
	
	ProductsIdentifier = ProductIDByLine(Description, 100);
	If ValueIsFilled(Characteristic) Then
		ItemVariantID = ProductIDByLine(Characteristic, 100);
	Else
		ItemVariantID = "";
	EndIf;
	If ValueIsFilled(UnitOfMeasure) Then
		PackageID = ProductIDByLine(UnitOfMeasure, 100);
	Else
		PackageID = "";
	EndIf;
	Id = ProductsIdentifier + "#" + ItemVariantID + "#" + PackageID;
	Return Id;
	
EndFunction

Function ProductIDByLine(Val RowOfProduct, Val MaxLength = Undefined) Export
	
	If Not ValueIsFilled(MaxLength) Then
		MaxLength = 110;
	EndIf;
	
	Id = RowOfProduct;
	Id = Upper(Id);
	Id = StrReplace(Id, " ", "");
	
	Length = StrLen(Id);
	
	If Length > MaxLength Then
		
		Hashing = New DataHashing(HashFunction.MD5);
		Hashing.Append(Id);
		
		HashString_ = String(Hashing.HashSum);
		HashString_ = StrReplace(HashString_, " ", "");
		
		LengthOfHashString = StrLen(HashString_);
		
		Id = Left(Id, MaxLength - LengthOfHashString) + HashString_;
		
	EndIf;
	
	Return Id;
	
EndFunction

#EndRegion

#Region Private

#Region FillingInCounterpartyProductList

Function ReferenceOfCounterpartyProductsBasedOnCounterpartyData(Val CounterpartyData)
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED TOP 1
	|	ProductCrossReferences.Ref AS Ref
	|FROM
	|	Catalog.ProductCrossReferences AS ProductCrossReferences
	|WHERE
	|	ProductCrossReferences.ItemOwner = &ItemOwner
	|	AND ProductCrossReferences.Id = &Id";
	
	Query.SetParameter("ItemOwner"      , CounterpartyData.Owner);
	Query.SetParameter("Id"             , CounterpartyData.Id);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Catalogs.ProductCrossReferences.EmptyRef();
	EndIf;
	
EndFunction

Procedure FillInOtherProductBarcodes(Object)
	
	If Not IsBlankString(Object.OtherItemsBarcodes) Then
		OtherTsProductBarcodes = StrConcat(Object.OtherProductsBarcodes.Unload().UnloadColumn("Barcode"), ",");
		If Object.OtherItemsBarcodes <> OtherTsProductBarcodes Then
			Object.OtherProductsBarcodes.Clear();
			SetOfOtherBarcodes = StrSplit(Object.OtherItemsBarcodes, ",");
			For Each Barcode In SetOfOtherBarcodes Do
				NewRow = Object.OtherProductsBarcodes.Add();
				NewRow.Barcode = TrimAll(Barcode);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInInformationOfUnitsOfMeasurementOfPackages(Object, CounterpartyProductData,
	Val SearchForUnitOfMeasureByOceaniaIsRequired, Val CounterpartyProductRegisterData)
	
	PackageName = CounterpartyProductData.PackageName;
	UnitOfMeasure     = CounterpartyProductData.UnitOfMeasure;
	UnitOfMeasureCode  = CounterpartyProductData.UnitOfMeasureCode;
	
	If IsBlankString(PackageName) Then
		Object.PackageName = UnitOfMeasure;
		If Not IsBlankString(CounterpartyProductData.UnitOfMeasureCode) 
			And SearchForUnitOfMeasureByOceaniaIsRequired Then
			ProductCrossReferencesMappingOverridable.FindUnitNameByOkeyCode(
				UnitOfMeasureCode, UnitOfMeasure);
		EndIf;
	EndIf;
	
	If Not IsBlankString(UnitOfMeasure) Then
		Object.BaseUnitOfMeasureDescription = UnitOfMeasure;
		Object.BaseUnitOfMeasureARCMUCode      = UnitOfMeasureCode;
	ElsIf Not IsBlankString(CounterpartyProductData.UnitOfMeasureCode) Then
		Object.BaseUnitOfMeasureDescription = CounterpartyProductData.UnitOfMeasure;
		Object.BaseUnitOfMeasureARCMUCode      = CounterpartyProductData.UnitOfMeasureCode;
	EndIf;
	
	If IsBlankString(Object.PackageName) Then
		Object.PackageName = Object.BaseUnitOfMeasureDescription;
	EndIf;
	
	If Not CounterpartyProductRegisterData Then
		Object.QuantityInBaseUnitOfMeasure = CounterpartyProductData.QuantityInBaseUnitOfMeasure;
		Object.NumberOfPackages = CounterpartyProductData.NumberOfPackages;
	EndIf;
	
	If Object.QuantityInBaseUnitOfMeasure = 0
			And Object.NumberOfPackages = 0 Then
				
		Object.QuantityInBaseUnitOfMeasure = 1;
		Object.NumberOfPackages = 1;
			
	EndIf;
	
	CounterpartyProductData.PackageName = Object.PackageName;
	CounterpartyProductData.UnitOfMeasure     = Object.BaseUnitOfMeasureDescription;
	CounterpartyProductData.UnitOfMeasureCode  = Object.BaseUnitOfMeasureARCMUCode;

EndProcedure

#EndRegion


#Region Other

Procedure DeleteEmptyStructureProperties(Parameter)
	Result = New Structure;
	For Each KeyAndValue In Parameter Do
		If ValueIsFilled(KeyAndValue.Value) Then
			Result.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndIf;
	EndDo;
	Parameter = Result;
EndProcedure

// Returns an array of keys from the mapping of the nomenclaturecontragentclientserver.The new nomenclature of the counterparty,
// which is a set of natural keys of the counterparty's nomenclature
//
// Returns:
//  Array of String - key names of the counterparty's item
//
Function NaturalKeysOfItemOfCounterparty()
	
	Keys = New Array;
	
	Keys.Add("Description");         // name of the item.
	Keys.Add("Characteristic");       // name of the item's characteristic.
	Keys.Add("UnitOfMeasure");     // name of the unit of measurement of the nomenclature.
	Keys.Add("UnitOfMeasureCode");  // code for the OKEI unit of measurement of the nomenclature.
	Keys.Add("SKU");              // the article of the nomenclature.
	Keys.Add("ProductsAndServicesCode");      // Product code. 
	Keys.Add("CombinationBarcode");   // combination barcode: nomenclature, characteristic, packaging. 
	
	Return Keys;
	
EndFunction

#EndRegion

#EndRegion
