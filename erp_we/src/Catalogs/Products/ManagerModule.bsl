#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	AttributesToLock = New Array;
	AttributesToLock.Add("FEACNCode");
	AttributesToLock.Add("PriceGroup");
	AttributesToLock.Add("UsePackages");
	AttributesToLock.Add("PackagingGroup");
	AttributesToLock.Add("Quality");
	AttributesToLock.Add("VATRate");
	AttributesToLock.Add("UnitOfMeasure");
	AttributesToLock.Add("Principal");
	AttributesToLock.Add("Counterparty");
	AttributesToLock.Add("FinancialAccountingGroup");
	
	ProductsLocalization.GetObjectAttributesToLock(AttributesToLock);
	
	Return AttributesToLock;

EndFunction

// Checks whether the transferred characteristic and packaging can be a characteristic and packaging of the transferred
// item. When checking, it is taken into account that the characteristics may be common for the item type,
// and packages may be common for a set of packages.
//
//		Parameters:
//			Products - CatalogRef.Products - nomenclature-owner of characteristics and packages
//			Characteristic - CatalogRef.ItemsCharacteristics - check the feature
//			Package - CatalogRef.PackagesAndUnitsOfMeasure - check the packing.
//
//		Returns:
//			Structure - structure with fields:
//				* Characteristic - CatalogRef.Products - if the checked characteristic is suitable, 
//						it is recorded, if not-an empty link.
//				* Package - CatalogRef.PackagesAndUnitsOfMeasure - if the package being checked is suitable, 
//						it is recorded; if not, it is an empty link.
//				* ItemVariantsAreUsed - Boolean - equal to TRUE if the item is used for recording characteristics.
//
Function CharacteristicAndPackagingBelongToOwner(Products, Characteristic, Package) Export
	ReturnStructure = New Structure("Characteristic, Package, ItemVariantsAreUsed");
	ReturnStructure.Characteristic             = Catalogs.ItemsCharacteristics.EmptyRef();
	ReturnStructure.Package                   = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	ReturnStructure.ItemVariantsAreUsed = False;
	
	If Not ValueIsFilled(Products) Then
		
		Return ReturnStructure;
		
	EndIf;
	
	If GetFunctionalOption("UseItemVariants") Then
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	ISNULL(CatCharacteristics.Ref, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
		|	CASE
		|		WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
		|			OR CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|			OR CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItemVariantsAreUsed
		|FROM
		|	Catalog.Products AS CatProducts
		|		LEFT JOIN Catalog.ItemsCharacteristics AS CatCharacteristics
		|		ON (CASE
		|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
		|					THEN CatProducts.ProductKind
		|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|					THEN CatProducts.Ref
		|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|					THEN CatProducts.ItemVariantsOwner
		|				ELSE FALSE
		|			END = CatCharacteristics.Owner)
		|			AND (CatCharacteristics.Ref = &Characteristic)
		|WHERE
		|	CatProducts.Ref = &Products";
		
		Query.SetParameter("Products", 	Products);
		Query.SetParameter("Characteristic", Characteristic);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		FillPropertyValues(ReturnStructure, Selection);
		
	EndIf;	
	
	PackagingSelectionParameters = New Structure();
	PackagingSelectionParameters.Insert("Products", Products);
	
	PackageSelectionData = Catalogs.PackagesAndUnitsOfMeasure.GetChoiceData(PackagingSelectionParameters);
	
	For Each ValueListItem In PackageSelectionData Do
		If (TypeOf(ValueListItem.Value) = Type("Structure")
			And ValueListItem.Value.Value = Package)
			Or ValueListItem.Value = Package Then 
			ReturnStructure.Package = Package;
			Break;
		EndIf;
	EndDo;
	
	Return ReturnStructure;
	
EndFunction

// Checks whether characteristics are used for the passed item
//	Parameters:
//		Products - CatalogRef.Products - item to check
//	Returns:
//		Boolean - TRUE if the characteristics are used.
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

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array of String - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	
	If Not GetFunctionalOption("UseMultipleKindsOfProducts") Then
		NotAttributesToEdit.Add("ProductKind");
	EndIf;
	NotAttributesToEdit.Add("ThereAreGoodsOfOtherQuality");
	NotAttributesToEdit.Add("UseVariants");
	NotAttributesToEdit.Add("SearchCode");
	NotAttributesToEdit.Add("DescriptionFull");
	NotAttributesToEdit.Add("SuppliedInReusablePackage");
	NotAttributesToEdit.Add("ReusablePackageItems");
	NotAttributesToEdit.Add("ReusablePackageVariant");
	NotAttributesToEdit.Add("LongDesc");
	NotAttributesToEdit.Add("ItemsType");
	NotAttributesToEdit.Add("ItemVariantsOwner");
	NotAttributesToEdit.Add("BatchOwner");
	NotAttributesToEdit.Add("ProductCategoryOwner");
	NotAttributesToEdit.Add("PicturesFile");
	NotAttributesToEdit.Add("DescriptionFileForWebsite");
	NotAttributesToEdit.Add("AccountingFeature");
	NotAttributesToEdit.Add("VATRate");
	
	CommonClientServer.SupplementArray(NotAttributesToEdit, DetailsOfSignsOfAccountingFeatures(Metadata.Catalogs.Products));
	
	ProductsLocalization.BankingDetailsThatCanTBeEditedInGroupProcessingProducts(NotAttributesToEdit);
	
	Return NotAttributesToEdit;
	
EndFunction

// If characteristics are maintained for the passed item, the parameter returns the owner of the characteristics.
//
//	Parameters:
//		Products - CatalogRef.Products - item to check
//		TechnicalCharacteristics - CatalogRef.Products, CatalogRef.ItemKinds - this parameter
//			returns the owner of the characteristics (this depends on whether the characteristics are used individually
//			or shared by the item type).
//	Returns:
//		Boolean - indicates that the transferred item is being accounted for by characteristics.
//
Function CheckUsageCharacteristicsAndGetOwnerToSelect(Products, TechnicalCharacteristics) Export

	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("ProductKind"           , "ProductKind");
	AttributesStructure1.Insert("UseVariants", "UseVariants");
	AttributesStructure1.Insert("ItemVariantsOwner"     , "ItemVariantsOwner");
	BankingDetailsValues = Common.ObjectAttributesValues(Products, AttributesStructure1);

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

// Fills in the details of the item item with the values of the corresponding details of the item type.
//
// Parameters:
//	Products						 - CatalogObject.Products, FormDataStructure - item to fill in,
//	AbortFillingInCaseOfVerificationError - Boolean - True-indicates that data filling has been canceled,
//	Cancel								 - Boolean - if the item type is changed, the correctness of this change is checked.
//													If that check returns an error, the parameter is set to TRUE.
//	OldKindOfProducts				 - CatalogRef.ItemKinds, Undefined - passed if the item type change is being processed.
//	FillingByCopySource	 - Boolean - indicates whether data from the copy source is being filled in.
//
Procedure FillInDetailsForTypeOfProduct(Products,
												AbortFillingInCaseOfVerificationError = False,
												Cancel = False,
												OldKindOfProducts = Undefined,
												FillingByCopySource = False) Export
	
	If Products.IsFolder Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Products.ProductKind) Then
		Return;
	EndIf;
	
	If OldKindOfProducts = Undefined Then 
		If ValueIsFilled(Products.Ref) Then
			OldKindOfProducts = Common.ObjectAttributeValue(Products.Ref, "ProductKind");
			If ValueIsFilled(OldKindOfProducts) Then
				CheckCorrectnessOfChangingProductTypeFillInNewType(Products, OldKindOfProducts, Cancel);
			EndIf;
			If Cancel
				And AbortFillingInCaseOfVerificationError Then
				Return;
			EndIf;
			
		Else
			OldKindOfProducts = Catalogs.ItemKinds.EmptyRef();
		EndIf;
	EndIf;
	
	StrictlyTakenOutOfSight = DetailsOfSignsOfAccountingFeatures(Metadata.Catalogs.Products);
	StrictlyTakenOutOfSight.Add("ItemsType");
	StrictlyTakenOutOfSight.Add("SaleRegistrationOption");
	StrictlyTakenOutOfSight.Add("AccessGroup");
	StrictlyTakenOutOfSight.Add("UseVariants");
	StrictlyTakenOutOfSight.Add("BatchOwner");
	StrictlyTakenOutOfSight.Add("ItemVariantsOwner");
	StrictlyTakenOutOfSight.Add("ProductCategoryOwner");
	StrictlyTakenOutOfSight.Add("AccountingFeature");
	StrictlyTakenOutOfSight.Add("ShelfLifeUnitOfMeasure");
	StrictlyTakenOutOfSight.Add("AlcoholContainingProducts");
	
	FilledInOnlyWhenCreatingProducts = New Array;
	FilledInOnlyWhenCreatingProducts.Add("UnitOfMeasure");
	FilledInOnlyWhenCreatingProducts.Add("UnitForReports");
	FilledInOnlyWhenCreatingProducts.Add("UnitFactorForReports");
	FilledInOnlyWhenCreatingProducts.Add("AssignedPurchaseSale");
	FilledInOnlyWhenCreatingProducts.Add("VATRate");
	FilledInOnlyWhenCreatingProducts.Add("PriceGroup");
	FilledInOnlyWhenCreatingProducts.Add("ControlQualityOfReceivedGoods");
	FilledInOnlyWhenCreatingProducts.Add("TermOfQualityControl");
	
	AreOverfilledIfTheirValuesWereEqualToDefaultValues = New Array;
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("WarehouseGroup");
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("ItemsGroup");
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("AnalyticalGroup");
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("FinancialAccountingGroup");
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("PriceTagTemplate");
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("LabelsTemplate");
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("SupplyScheme");
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("ProcurementStrategy");
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("FEACNCode");
	
	RefilledIfTheyWerenTFilledInBefore = New Array;
	// At the same time, Boolean details are not filled in if they are FALSE, i.e. booleans can only change from FALSE to TRUE.
	RefilledIfTheyWerenTFilledInBefore.Add("UsePackages");
	RefilledIfTheyWerenTFilledInBefore.Add("PackagingGroup");
	RefilledIfTheyWerenTFilledInBefore.Add("SuppliedInReusablePackage");
	RefilledIfTheyWerenTFilledInBefore.Add("ReusablePackageItems");
	RefilledIfTheyWerenTFilledInBefore.Add("ReusablePackageVariant");
	RefilledIfTheyWerenTFilledInBefore.Add("KeepRecordsOfQualityCertificates");
	
	DefaultValues = New Structure;
	// Will be used if other methods have not filled in these details
	DefaultValues.Insert("FinancialAccountingGroup", Catalogs.InventoryAccountingGroups.GetDefaultFinancialAccountingGroup());
	DefaultValues.Insert("WarehouseGroup", SettingsValueCached.DefaultProductInventoryGroup());
	DefaultValues.Insert("AnalyticalGroup", Catalogs.AnalyticalInventoryGroups.GetDefaultAnalyticalAccountingGroup());
	DefaultValues.Insert("Quality", Enums.QualityLevels.New);
	DefaultValues.Insert("VATRate", VATAccountingERP.VATRateOfMainCountry());
	
	ProductsLocalization.FillInDetailsForTypeOfProduct(StrictlyTakenOutOfSight,
		FilledInOnlyWhenCreatingProducts,
		AreOverfilledIfTheirValuesWereEqualToDefaultValues,
		RefilledIfTheyWerenTFilledInBefore,
		DefaultValues);
	
	// We will clear the details that exactly need to be filled in by type	
	TMCommonUseClientServer.ClearPropertyValues(Products, StrictlyTakenOutOfSight);
	
	ReceivedDetails = New Array;
	CommonClientServer.SupplementArray(ReceivedDetails, StrictlyTakenOutOfSight);
	
	FillInDetailsToBeFilledInDuringCreation = Not FillingByCopySource
												And Not ValueIsFilled(Products.Ref);
	
	If FillInDetailsToBeFilledInDuringCreation Then
		// We will get the details of a new type, if you need to fill in only when creating, then we will simply not receive such details.
		CommonClientServer.SupplementArray(ReceivedDetails, FilledInOnlyWhenCreatingProducts);
	EndIf;
	
	CommonClientServer.SupplementArray(ReceivedDetails, AreOverfilledIfTheirValuesWereEqualToDefaultValues);
	CommonClientServer.SupplementArray(ReceivedDetails, RefilledIfTheyWerenTFilledInBefore);
	
	DetailsOfNewType = Common.ObjectAttributesValues(Products.ProductKind, ReceivedDetails);
	
	// If the item is being created, then we will clear the details that are filled in by type when creating, if these
	// details are filled in in the new form.
	If FillInDetailsToBeFilledInDuringCreation Then
		
		For Each AttributeName In FilledInOnlyWhenCreatingProducts Do
			
			If ValueIsFilled(DetailsOfNewType[AttributeName]) Then
				Products[AttributeName] = Undefined;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	HSCodeBeforeChange = Products.FEACNCode;
	
	// We will clear the details that were previously filled in with default values (if these defaults are not set in the new form
	// , we will not clear them).
	If ValueIsFilled(OldKindOfProducts) Then
		DetailsOfOldType = Common.ObjectAttributesValues(OldKindOfProducts,
																			AreOverfilledIfTheirValuesWereEqualToDefaultValues);
		
		For Each KeyValue In DetailsOfOldType Do
			If Products[KeyValue.Key] = KeyValue.Value
				And ValueIsFilled(DetailsOfNewType[KeyValue.Key]) Then
				
				Products[KeyValue.Key] = Undefined;
				
			EndIf;
		EndDo;
	EndIf;
	
	// We will fill in only the unfilled details - those that need to be filled in have always been forcibly cleared earlier.
	TMCommonUseClientServer.FillInValuesOfEmptyProperties(Products, DetailsOfNewType);
	TMCommonUseClientServer.FillInValuesOfEmptyProperties(Products, DefaultValues);
	
	WorkOutLogicOfConnectionDetails(Products);
	
	If FillInDetailsToBeFilledInDuringCreation
		Or HSCodeBeforeChange <> Products.FEACNCode Then
		
		FillInImportAndTraceabilityDetails(Products);
		
	EndIf;
	
EndProcedure

// The procedure harmonizes the values of the details with each other, excluding invalid combinations of values.
//
// Parameters:
//  Products - CatalogObject.Products - element to work out the logic
//                                                                       of the connection of details for.
//               - FormDataStructure - Items (from the Form of the item)
//               - Structure - Item with extended fields (from the Form of the item)
Procedure WorkOutLogicOfConnectionDetails(Products) Export
	
	FeatureOfAccountingOrKeyTypesOfProducts = ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(Products);
	
	If TypeOf(FeatureOfAccountingOrKeyTypesOfProducts) = Type("EnumRef.ItemAccountingFeatures") Then
		DetailsOfSignsOfAccountingFeatures = Catalogs.Products.DetailsOfSignsOfAccountingFeatures(Metadata.Catalogs.Products);
		For Each AttributeName In DetailsOfSignsOfAccountingFeatures Do
			Products[AttributeName] = FeatureOfAccountingOrKeyTypesOfProducts =
				PredefinedValue("Enum.ItemAccountingFeatures." + AttributeName);
		EndDo;
	EndIf;
	
	Products.AlcoholContainingProducts = ProductsLocalization.TheseAreUSAISManufacturedProducts(FeatureOfAccountingOrKeyTypesOfProducts);

	// Disabling the cleaning of unused Attributes for the case of programmatic creation of an object
	DisableAttributeClearing = False;
	If TypeOf(Products) <> Type("CatalogObject.Products")
		Or Not Products.AdditionalProperties.Property("DisableAttributeClearing", DisableAttributeClearing)
		Or DisableAttributeClearing <> True Then

		UsingBankingDetails = UsingElements(Products, False, True);
		ObjectMetadata = Metadata.Catalogs.Products;

		For Each KeyValue In UsingBankingDetails Do
			If Not KeyValue.Value Then
				If ObjectMetadata.Attributes.Find(KeyValue.Key) <> Undefined Then
					Products[KeyValue.Key] = ObjectMetadata.Attributes.Find(KeyValue.Key).Type.AdjustValue(Undefined);
				ElsIf ObjectMetadata.TabularSections.Find(KeyValue.Key) <> Undefined Then
					Products[KeyValue.Key].Clear();
				Else
					ExceptionText = NStr("vi = 'Khi xóa các mục tin không sử dụng của mặt hàng, không tìm thấy mục tin %AttributeName%';
										|ru = 'При очистке неиспользуемых реквизитов номенклатуры не найден реквизит %AttributeName%';
										|en = 'When clearing unused item attributes, the attribute %AttributeName% was not found'; fa = 'When clearing unused item attributes, the attribute %AttributeName% was not found';
										|it = 'При очистке неиспользуемых реквизитов номенклатуры не найден реквизит %AttributeName%';
										|pl = 'When clearing unused item attributes, the attribute %AttributeName% was not found';
										|tr = 'Kullanılmayan öğe öznitelikleri temizlenirken %AttributeName% özniteliği bulunamadı'");
					ExceptionText = StrReplace(ExceptionText, "%AttributeName%", KeyValue.Key);
					Raise ExceptionText;
				EndIf;
			EndIf;
		EndDo;

	EndIf;

	If DisableAttributeClearing = True Then
		Products.AdditionalProperties.DisableAttributeClearing = False;
	EndIf;

	If Products.ItemsType = Enums.ItemsTypes.Work_5
		Or Products.ItemsType = Enums.ItemsTypes.OperationService Then
		
		If ValueIsFilled(Products.Principal) Then
			If TypeOf(Products.Principal) = Type("CatalogRef.Companies") Then
				Products.Counterparty = Products.Principal;
			ElsIf Not ValueIsFilled(Products.Counterparty) Then
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Products.Principal, Products.Counterparty);
			EndIf;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(Products.FEACNCode) Then
		Products.FEACNUnitOfMeasure = Common.ObjectAttributeValue(Products.FEACNCode,
																						"UnitOfMeasure");
	Else
		Products.FEACNUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	EndIf;
	
	If ValueIsFilled(Products.PackagingGroup)
		And Products.PackagingGroup <> Catalogs.PackagingGroups.SpecialForItem Then
		
		Products.UnitOfMeasure = Common.ObjectAttributeValue(Products.PackagingGroup, "UnitOfMeasure");
		
	EndIf;
	
	UseProductCategories = GetFunctionalOption("UseProductCategories");
	
	If UseProductCategories
		And ValueIsFilled(Products.ProductCategory) Then
		
		CategoryOwner = Common.ObjectAttributeValue(Products.ProductCategory, "Owner");
		
		If CategoryOwner <> Products.ProductKind
			And CategoryOwner <> Products.ProductCategoryOwner Then
			
			Products.ProductCategory = Catalogs.ProductCategories.EmptyRef();
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Products.UnitForReports) Then
		Products.UnitForReports = Products.UnitOfMeasure;
	EndIf;
	
	If Not ValueIsFilled(Products.UnitFactorForReports)
		Or Products.UnitForReports = Products.UnitOfMeasure Then
		
		Products.UnitFactorForReports = 1;
		
	EndIf;
	
	UnitType_ = "";
	DimensionalStorageUnit = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Products.UnitOfMeasure, UnitType_);
	
	WorkOutLogicOfFillingMeasure(Products, DimensionalStorageUnit, UnitType_, "Weight");
	WorkOutLogicOfFillingMeasure(Products, DimensionalStorageUnit, UnitType_, "VolumeM3");
	WorkOutLogicOfFillingMeasure(Products, DimensionalStorageUnit, UnitType_, "AreaTypeOfMeasurement");
	WorkOutLogicOfFillingMeasure(Products, DimensionalStorageUnit, UnitType_, "Length");
	
	ProductsLocalization.WorkOutLogicOfConnectionDetails(Products);
	
EndProcedure

// Fills in the values of import accounting details and traceability according to the nomenclature data.
//
// Parameters:
//	Products - CatalogObject.Products, FormDataStructure - the item item being processed.
//
Procedure FillInImportAndTraceabilityDetails(Products) Export
	
	TraceabilityDetails = TraceabilityDetails(Products.FEACNCode);
	
	Products.FEACNUnitOfMeasure = TraceabilityDetails.UnitOfMeasure;
	
	ProductsLocalization.FillInImportAndTraceabilityDetails(Products, TraceabilityDetails);
	
EndProcedure

// Returns an initialized collection of traceability details according to the HS code data.
//
// Parameters:
//	FEACNCode - CatalogRef.FEACN - HS code of the nomenclature.
//
// Returns:
//	See ProductsClientServer.DefaultTraceabilityDetails.
//
Function TraceabilityDetails(FEACNCode) Export
	
	TraceabilityDetails = ProductsClientServer.DefaultTraceabilityDetails();
	
	If ValueIsFilled(FEACNCode) Then
		
		AttributesNames = New Array;
		For Each KeyAndValue In TraceabilityDetails Do
			AttributesNames.Add(KeyAndValue.Key);
		EndDo;
		
		FillPropertyValues(TraceabilityDetails, Common.ObjectAttributesValues(FEACNCode, AttributesNames));
		
	EndIf;
	
	Return TraceabilityDetails;
	
EndFunction

// Checks whether the item type is changed correctly and sets the rejection To TRUE in case of problems.
//
// Parameters:
//	Products          - CatalogObject.Products, FormDataStructure - nomenclature, a new type of nomenclature,
//	OldKindOfProducts - CatalogRef.ItemKinds - item type before the shift,
//	Cancel                 - Boolean - True-cancel change the item type.
//
Procedure CheckCorrectnessOfChangingProductTypeFillInNewType(Products, OldKindOfProducts, Cancel) Export
	
	ConditionsForSelectingNewTypeOfProduct = ConditionsForSelectingNewTypeOfProduct();
	
	TextOfSelectionFields = "";
	For Each KeyValue In ConditionsForSelectingNewTypeOfProduct Do
		TextOfSelectionFields = TextOfSelectionFields + KeyValue.Value + " AS " + KeyValue.Key + ", ";
	EndDo;
	
	QueryText = "
	|SELECT
	|	&SelectionFields1,
	|	NewTypeOfProduct.Ref AS Ref
	|FROM
	|	Catalog.ItemKinds AS NewTypeOfProduct ";
	
	If Not IsBlankString(TextOfSelectionFields) Then
		QueryText = StrReplace(QueryText, "&SelectionFields1,", TextOfSelectionFields);
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	QueryOptions = Query.FindParameters();

	AttributesNames = New Array;
	For Each Parameter In QueryOptions Do
		AttributesNames.Add(Parameter.Name);
	EndDo;
	
	OldDetails = Common.ObjectAttributesValues(OldKindOfProducts, AttributesNames);
	For Each Parameter In QueryOptions Do
		Query.SetParameter(Parameter.Name, OldDetails[Parameter.Name]);
	EndDo;
	
	Query.Text = Query.Text + "
	|WHERE
	|	NewTypeOfProduct.Ref = &NewTypeOfProduct";
	Query.SetParameter("NewTypeOfProduct", Products.ProductKind);
	
	Result = Query.Execute().Unload();
	ErrorValue_ = Result[0];
	
	For Each Error In Result.Columns Do
		If Error.Name = "Ref"
			Or Not ErrorValue_[Error.Name] Then
			Continue;
		EndIf;
		
		If Error.Name = "ThereIsProblemWithTypeOfProduct" Then
			Cancel = True;
			MessageText = NStr("vi = 'Vấn đề khi thay đổi dạng mặt hàng: dạng mặt hàng mới có kiểu mặt hàng khác.';
								|ru = 'Проблема при изменении вида номенклатуры: у нового вида другой тип номенклатуры.';
								|en = 'Problem changing the item kind: the new kind has a different item type.'; fa = 'Problem changing the item kind: the new kind has a different item type.';
								|it = 'Si è verificato il problema nel corso della modifica del tipo di articolo: il nuovo tipo ha un altro tipo di articolo.';
								|pl = 'Problem przy zmianie rodzaju towaru: nowy rodzaj posiada inny typ pozycji.';
								|tr = 'Öğe türünü değiştirirken sorun oluştu: Yeni türde farklı öğe türü mevcut.'");
			CommonClientServer.MessageToUser(MessageText);
		ElsIf Error.Name = "ThereIsProblemAccountingFeature" Then
			Cancel = True;
			MessageText = NStr("vi = 'Vấn đề khi thay đổi dạng mặt hàng: dạng mặt hàng mới có đặc điểm kế toán khác.';
								|ru = 'Проблема при изменении вида номенклатуры: у нового вида другая особенность учета.';
								|en = 'Issue changing the item kind: a new kind has a different accounting feature.'; fa = 'Issue changing the item kind: a new kind has a different accounting feature.';
								|it = 'Si è verificato il problema nel corso della modifica del tipo di articolo: il nuovo tipo ha una diversa caratteristica di contabilità.';
								|pl = 'Problem przy zmianie rodzaju towaru: nowy rodzaj posiada inną cechę ewidencji.';
								|tr = 'Öğe türünü değiştirirken sorun: Yeni türün farklı bir muhasebe özelliği mevcut.'");
			CommonClientServer.MessageToUser(MessageText);
		ElsIf Error.Name = "ThereIsProblemToUseSeries" Then
			Cancel = True;
			MessageText = NStr("vi = 'Vấn đề khi thay đổi dạng mặt hàng: dạng mặt hàng mới có các tùy chỉnh không tương thích để ghi nhận sê-ri.';
								|ru = 'Проблема при изменении вида номенклатуры: у нового вида несовместимые настройки ведения серий.';
								|en = 'Problem changing the item kind: the new kind has incompatible settings of batch keeping.'; fa = 'Problem changing the item kind: the new kind has incompatible settings of batch keeping.';
								|it = 'Si è verificato il problema nel corso della modifica del tipo di articolo: il nuovo tipo possiede delle configurazioni non compatibili alla gestione delle serie.';
								|pl = 'Problem przy zmianie rodzaju towaru: nowy rodzaj posiada nieodpowiednie ustawienia prowadzenia serii.';
								|tr = 'Öğe türü değiştirilirken sorun oluştu: Yeni türün, uyumsuz parti yönetimi ayarları mevcut.'");
			CommonClientServer.MessageToUser(MessageText);
		ElsIf Error.Name = "ThereIsProblemUsingCharacteristics" Then
			Cancel = True;
			MessageText = NStr("vi = 'Vấn đề khi thay đổi dạng mặt hàng: dạng mặt hàng mới có các tùy chỉnh không tương thích để ghi nhận đặc tính.';
								|ru = 'Проблема при изменении вида номенклатуры: у нового вида несовместимые настройки ведения характеристик.';
								|en = 'Problem changing the item kind: the new kind has incompatible variant registration settings.'; fa = 'Problem changing the item kind: the new kind has incompatible variant registration settings.';
								|it = 'Si è verificato il problema nel corso della modifica del tipo di articolo: il nuovo tipo possiede delle configurazioni non compatibili alla gestione delle caratteristiche.';
								|pl = 'Problem przy zmianie rodzaju towaru: nowy rodzaj posiada nieodpowiednie ustawienia prowadzenia charakterystyk.';
								|tr = 'Öğe türü değiştirilirken sorun oluştu: yeni türün ayarlarıyla uyumsuz özellik yönetimi mevcut.'");
			CommonClientServer.MessageToUser(MessageText);
		Else
			ExceptionText = NStr("vi = 'Mã lỗi không xác định.';
								|ru = 'Неизвестный код ошибки.';
								|en = 'Unknown error code.'; fa = 'Unknown error code.';
								|it = 'Il codice errore sconosciuto.';
								|pl = 'Nieznany kod błędu.';
								|tr = 'Bilinmeyen hata kodu.'");
			Raise ExceptionText;
		EndIf;
	EndDo;
	
EndProcedure

// Conditions for selecting a new type of item. They are used both for limiting the selection list and for checking the view change.
// Returns:
//  Structure - the structure of conditions. The key is the name of the condition, the values are the text of the condition request.
//
Function ConditionsForSelectingNewTypeOfProduct() Export
	
	ConditionsForSelectingNewTypeOfProduct = New Structure;
	
	ThereIsProblemWithTypeOfProduct = "
	|	CASE
	|		WHEN &Ref = NewTypeOfProduct.Ref
	|			THEN FALSE
	|		WHEN &ItemsType <> NewTypeOfProduct.ItemsType
	|			THEN TRUE
	|		ELSE FALSE
	|	END ";
	ConditionsForSelectingNewTypeOfProduct.Insert("ThereIsProblemWithTypeOfProduct", ThereIsProblemWithTypeOfProduct);
	
	ThereIsProblemAccountingFeature = "
	|	CASE
	|		WHEN &Ref = NewTypeOfProduct.Ref
	|			THEN FALSE
	|		WHEN &AccountingFeature <> NewTypeOfProduct.AccountingFeature
	|			THEN TRUE
	|		ELSE FALSE
	|	END ";
	ConditionsForSelectingNewTypeOfProduct.Insert("ThereIsProblemAccountingFeature", ThereIsProblemAccountingFeature);
	
	ThereIsProblemToUseSeries = "
	|	CASE
	|		WHEN &Ref = NewTypeOfProduct.Ref
	|			THEN FALSE
	|		WHEN NOT(NOT &KeepAccountingByBatch
	|						AND NOT NewTypeOfProduct.KeepAccountingByBatch
	|					OR &KeepAccountingByBatch
	|						AND NewTypeOfProduct.KeepAccountingByBatch
	|						AND (&BatchOwner = NewTypeOfProduct.BatchOwner
	|								AND &BatchOwner <> VALUE(Catalog.ItemKinds.EmptyRef)
	|								AND NewTypeOfProduct.BatchOwner <> VALUE(Catalog.ItemKinds.EmptyRef)
	|							OR &BatchOwner = NewTypeOfProduct.Ref
	|							OR NewTypeOfProduct.BatchOwner = &Ref))
	|			THEN TRUE
	|		ELSE FALSE
	|	END ";
	ConditionsForSelectingNewTypeOfProduct.Insert("ThereIsProblemToUseSeries", ThereIsProblemToUseSeries);
	
	ThereIsProblemUsingCharacteristics = "
	|	CASE
	|		WHEN &Ref = NewTypeOfProduct.Ref
	|			THEN FALSE
	|		WHEN NOT(&UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|						AND NewTypeOfProduct.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					OR &UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|						AND NewTypeOfProduct.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|					OR &UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|						AND NewTypeOfProduct.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|						AND NewTypeOfProduct.ItemVariantsOwner = &Ref
	|					OR NewTypeOfProduct.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|						AND &UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|						AND &ItemVariantsOwner = NewTypeOfProduct.Ref
	|					OR NewTypeOfProduct.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|						AND &UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|						AND &ItemVariantsOwner = NewTypeOfProduct.ItemVariantsOwner)
	|			THEN TRUE
	|		ELSE FALSE
	|	END ";
	ConditionsForSelectingNewTypeOfProduct.Insert("ThereIsProblemUsingCharacteristics", ThereIsProblemUsingCharacteristics);
	
	Return ConditionsForSelectingNewTypeOfProduct;
	
EndFunction

// Returns the visibility and header settings for form elements. Used for building the form and table
// document of the item card.
// Parameters:
//  Object - CatalogObject.Products, FormDataStructure - element for which you need to work out the logic of communication details
//	VisibilityModeShowHighPriorityOnly 	- Boolean - indicates whether the main details are displayed.
//
// Returns:
//  Structure - structure with keys:
//		* VisibilityOfElements - See UsingElements
//		* ItemsTitles - See ItemsTitles
//
Function VisibilityAndHeaderSettings(Object, VisibilityModeShowHighPriorityOnly = False) Export
	
	VisibilityAndHeaderSettings = New Structure;
	
	VisibilityOfElements = UsingElements(Object, VisibilityModeShowHighPriorityOnly, False);
	ItemsTitles = ItemsTitles(Object, VisibilityOfElements);
		
	VisibilityAndHeaderSettings.Insert("VisibilityOfElements", VisibilityOfElements);
	VisibilityAndHeaderSettings.Insert("ItemsTitles", ItemsTitles);
		
	Return VisibilityAndHeaderSettings;
	
EndFunction

// Returns the details of the measure.
// 
// Parameters:
// 	Measure - String - Measure name
// Returns:
// 	Structure - Contains keys:
// 		* Use - String - Name of the usage prop
// 		* UnitOfMeasure - String - Name of the unit of measurement prop
// 		* Numerator - String - Name of the numerator's prop
// 		* Denominator - String - Name of the requesite of the denominator
// 		* CanBeSpecifiedInDocuments - String - Name availability flag in documents
Function DetailsOfMeasure(Measure) Export
	
	DetailsOfMeasure = New Structure;
	DetailsOfMeasure.Insert("Use");
	DetailsOfMeasure.Insert("UnitOfMeasure");
	DetailsOfMeasure.Insert("Numerator");
	DetailsOfMeasure.Insert("Denominator");
	DetailsOfMeasure.Insert("CanBeSpecifiedInDocuments");
	
	If Measure = "VolumeM3" Then
		DetailsOfMeasure.Use = "VolumeUse";
		DetailsOfMeasure.UnitOfMeasure = "VolumeUnitOfMeasure";
		DetailsOfMeasure.Numerator = "VolumeNumerator";
		DetailsOfMeasure.Denominator = "VolumeDenominator";
		DetailsOfMeasure.CanBeSpecifiedInDocuments = "VolumeCanBeSpecifiedInDocuments";
	ElsIf Measure = "Length" Then
		DetailsOfMeasure.Use = "LengthUse";
		DetailsOfMeasure.UnitOfMeasure = "LengthUnitOfMeasure";
		DetailsOfMeasure.Numerator = "LengthNumerator";
		DetailsOfMeasure.Denominator = "LengthDenominator";
		DetailsOfMeasure.CanBeSpecifiedInDocuments = "YouCanSpecifyLengthInDocuments";
	ElsIf Measure = "Width" Then
		DetailsOfMeasure.Use = "WidthToUse";
		DetailsOfMeasure.UnitOfMeasure = "WidthUnitOfMeasure";
		DetailsOfMeasure.Numerator = "WidthNumerator";
		DetailsOfMeasure.Denominator = "WidthDenominator";
		DetailsOfMeasure.CanBeSpecifiedInDocuments = "WidthCanBeSpecifiedInDocuments";
	ElsIf Measure = "Weight" Then
		DetailsOfMeasure.Use = "WeightUse";
		DetailsOfMeasure.UnitOfMeasure = "WeightUnitOfMeasure";
		DetailsOfMeasure.Numerator = "WeightNumerator";
		DetailsOfMeasure.Denominator = "WeightDenominator";
		DetailsOfMeasure.CanBeSpecifiedInDocuments = "YouCanSpecifyWeightInDocuments";
	ElsIf Measure = "AreaTypeOfMeasurement" Then
		DetailsOfMeasure.Use = "AreaUse";
		DetailsOfMeasure.UnitOfMeasure = "AreaUnitOfMeasure";
		DetailsOfMeasure.Numerator = "AreaNumerator";
		DetailsOfMeasure.Denominator = "AreaDenominator";
		DetailsOfMeasure.CanBeSpecifiedInDocuments = "AreaCanBeSpecifiedInDocuments";
	Else
		Raise StrTemplate(NStr("vi = 'Chưa xác định mục tin của phương thức %1';
								|ru = 'Не определены реквизиты меры %1';
								|en = 'Measure %1 attributes not defined'; fa = 'Measure %1 attributes not defined';
								|it = 'Requisiti di misura %1 non definiti';
								|pl = 'Nie określono atrybutów miary %1';
								|tr = 'Ölçü öznitelikleri tanımlanmamış %1'"), Measure);
	EndIf;
	
	Return DetailsOfMeasure;
	
EndFunction

#Region InterfaceImplementation

// Sets parameters for loading data from a file
//
// Parameters:
//     Parameters - Structure - List of parameters. Fields: 
//         * Title           - String       - The window title 
//         * RequiredColumns2 - Array       - A list of the names of the columns are mandatory
//         * ColumnDataType    - Map - Description of the data type
//
Procedure DefineParametersForLoadingDataFromFile(Parameters) Export
	
	Parameters.Title = NStr("vi = 'Mặt hàng';
							|ru = 'Номенклатура';
							|en = 'Item'; fa = 'قلم';
							|it = 'Articolo';
							|pl = 'Item';
							|tr = 'Öğe'");
	
	Parameters.ColumnDataType.Insert("Description", New TypeDescription("String",, New StringQualifiers(100)));
	Parameters.ColumnDataType.Insert("Parent",  New TypeDescription("CatalogRef.Products"));
	Parameters.ColumnDataType.Insert("UnitOfMeasure",  New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Parameters.ColumnDataType.Insert("SaleRegistrationOption",  New TypeDescription("EnumRef.SalesRegistrationOptions"));
	Parameters.ColumnDataType.Insert("WeightUnitOfMeasure",  New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Parameters.ColumnDataType.Insert("ProductKind",  New TypeDescription("CatalogRef.ItemKinds"));
	Parameters.ColumnDataType.Insert("AccessGroup",  New TypeDescription("CatalogRef.ItemAccessGroups"));
	Parameters.ColumnDataType.Insert("ShelfLifeUnitOfMeasure",  New TypeDescription("EnumRef.TimeMeasureUnits"));
	Parameters.ColumnDataType.Insert("LengthUnitOfMeasure",  New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Parameters.ColumnDataType.Insert("UseVariants",  New TypeDescription("EnumRef.ItemVariantsUsageOptions"));
	Parameters.ColumnDataType.Insert("Quality",  New TypeDescription("EnumRef.QualityLevels"));
	Parameters.ColumnDataType.Insert("Brand",  New TypeDescription("CatalogRef.Brands"));
	Parameters.ColumnDataType.Insert("PackagingGroup",  New TypeDescription("CatalogRef.PackagingGroups"));
	Parameters.ColumnDataType.Insert("FinancialAccountingGroup",  New TypeDescription("CatalogRef.InventoryAccountingGroups"));
	Parameters.ColumnDataType.Insert("ReusablePackageItems",  New TypeDescription("CatalogRef.Products"));
	Parameters.ColumnDataType.Insert("Manufacturer",  New TypeDescription("CatalogRef.Manufacturers"));
	Parameters.ColumnDataType.Insert("ManufacturerImporterConterparty",  New TypeDescription("CatalogRef.Counterparties"));
	Parameters.ColumnDataType.Insert("WarehouseGroup",  New TypeDescription("CatalogRef.WarehouseGroupsOfItems"));
	Parameters.ColumnDataType.Insert("VATRate",  New TypeDescription("CatalogRef.VATRates"));
	Parameters.ColumnDataType.Insert("ItemsType",  New TypeDescription("EnumRef.ItemsTypes"));
	Parameters.ColumnDataType.Insert("ProductCategory",  New TypeDescription("CatalogRef.ProductCategories"));
	Parameters.ColumnDataType.Insert("VolumeUnitOfMeasure",  New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Parameters.ColumnDataType.Insert("ReusablePackageVariant",  New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Parameters.ColumnDataType.Insert("AreaUnitOfMeasure",  New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Parameters.ColumnDataType.Insert("SupplyScheme",  New TypeDescription("CatalogRef.SupplySchemes"));
	Parameters.ColumnDataType.Insert("ProcurementStrategies",  New TypeDescription("CatalogRef.ProcurementStrategies"));
	Parameters.ColumnDataType.Insert("PriceGroup",  New TypeDescription("CatalogRef.PriceGroups"));
	Parameters.ColumnDataType.Insert("PriceTagTemplate",  New TypeDescription("CatalogRef.LabelAndPriceTagTemplates"));
	Parameters.ColumnDataType.Insert("ItemsGroup",  New TypeDescription("CatalogRef.SeasonalGroups"));
	Parameters.ColumnDataType.Insert("ItemsCollection",  New TypeDescription("CatalogRef.ItemsCollections"));
	
	TypesArray = New Array;
	TypesArray.Add(New TypeDescription("CatalogRef.Companies"));
	TypesArray.Add(New TypeDescription("CatalogRef.Partners"));
	Parameters.ColumnDataType.Insert("Principal",  New TypeDescription(TypesArray));

	TypesArray = New Array;
	TypesArray.Add(New TypeDescription("CatalogRef.Companies"));
	TypesArray.Add(New TypeDescription("CatalogRef.Counterparties"));
	Parameters.ColumnDataType.Insert("Counterparty",  New TypeDescription(TypesArray));

	Parameters.ColumnDataType.Insert("SalesRank",  New TypeDescription("CatalogRef.SalesRanks"));
	Parameters.ColumnDataType.Insert("AnalyticalGroup",  New TypeDescription("CatalogRef.AnalyticalInventoryGroups"));
	Parameters.ColumnDataType.Insert("FEACNCode",  New TypeDescription("CatalogRef.FEACN"));
	
	Parameters.ColumnDataType.Insert("AccountingFeature",  New TypeDescription("EnumRef.ItemAccountingFeatures"));
	Parameters.ColumnDataType.Insert("FEACNUnitOfMeasure",  New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Parameters.ColumnDataType.Insert("OriginCountry",  New TypeDescription("CatalogRef.WorldCountries"));
	
	BooleanType = New TypeDescription("Boolean");
	
	Parameters.ColumnDataType.Insert("WeightUse",  BooleanType);
	Parameters.ColumnDataType.Insert("YouCanSpecifyWeightInDocuments",  BooleanType);
	Parameters.ColumnDataType.Insert("KeepRecordsByCCD",  BooleanType);
	Parameters.ColumnDataType.Insert("KeepRecordsOfQualityCertificates",  BooleanType);
	Parameters.ColumnDataType.Insert("AlcoholContainingProducts",  BooleanType);
	Parameters.ColumnDataType.Insert("ThereAreGoodsOfOtherQuality",  BooleanType);
	Parameters.ColumnDataType.Insert("ImportedAlcoholContainingProducts",  BooleanType);
	Parameters.ColumnDataType.Insert("LengthUse",  BooleanType);
	Parameters.ColumnDataType.Insert("YouCanSpecifyLengthInDocuments",  BooleanType);
	Parameters.ColumnDataType.Insert("UseCustomPriceTagTemplate",  BooleanType);
	Parameters.ColumnDataType.Insert("UseCustomTemplateLabels",  BooleanType);
	Parameters.ColumnDataType.Insert("UsePackages",  BooleanType);
	Parameters.ColumnDataType.Insert("SoldByPermission",  BooleanType);
	Parameters.ColumnDataType.Insert("SuppliedInReusablePackage",  BooleanType);
	Parameters.ColumnDataType.Insert("VolumeUse",  BooleanType);
	Parameters.ColumnDataType.Insert("VolumeCanBeSpecifiedInDocuments",  BooleanType);
	Parameters.ColumnDataType.Insert("AreaUse",  BooleanType);
	Parameters.ColumnDataType.Insert("AreaCanBeSpecifiedInDocuments",  BooleanType);
	Parameters.ColumnDataType.Insert("AssignedPurchaseSale",  BooleanType);
	Parameters.ColumnDataType.Insert("ControlQualityOfReceivedGoods",  BooleanType);
	Parameters.ColumnDataType.Insert("SubjectToMineralExtractionTaxAtRate",  BooleanType);
	Parameters.ColumnDataType.Insert("ProductsMarkedForSPMS",  BooleanType);
	Parameters.ColumnDataType.Insert("ControlIdentificationMarkCIMSPMS",  BooleanType);
	Parameters.ColumnDataType.Insert("AlcoholContainingProductsOpenPackage",  BooleanType);
	Parameters.ColumnDataType.Insert("SubjectToVATAtCustomer",  BooleanType);
	Parameters.ColumnDataType.Insert("TracedGoods",  BooleanType);
	Parameters.ColumnDataType.Insert("TransferProductBatchIDMaterial",  BooleanType);
	NonNegativeNumber15_3 = New NumberQualifiers(15, 3, AllowedSign.Nonnegative);
	NonNegativeNumber15_0 = New NumberQualifiers(15, 0, AllowedSign.Nonnegative);
	NonNegativeNumber18_6 = New NumberQualifiers(18, 6, AllowedSign.Nonnegative);
	NonNegativeNumber5_0  = New NumberQualifiers(5, 0,  AllowedSign.Nonnegative);

	Parameters.ColumnDataType.Insert("WeightDenominator", New TypeDescription("Number", NonNegativeNumber15_3));
	Parameters.ColumnDataType.Insert("WeightNumerator", New TypeDescription("Number", NonNegativeNumber15_3));
	Parameters.ColumnDataType.Insert("LengthDenominator", New TypeDescription("Number", NonNegativeNumber15_3));
	Parameters.ColumnDataType.Insert("LengthNumerator", New TypeDescription("Number", NonNegativeNumber15_3));
	Parameters.ColumnDataType.Insert("VolumeInDecaliters", New TypeDescription("Number", NonNegativeNumber18_6));
	Parameters.ColumnDataType.Insert("ExpirationDate_", New TypeDescription("Number", NonNegativeNumber15_0));
	Parameters.ColumnDataType.Insert("TermOfQualityControl", New TypeDescription("Number", NonNegativeNumber5_0));
	Parameters.ColumnDataType.Insert("VolumeDenominator", New TypeDescription("Number", NonNegativeNumber15_3));
	Parameters.ColumnDataType.Insert("VolumeNumerator", New TypeDescription("Number", NonNegativeNumber15_3));
	Parameters.ColumnDataType.Insert("AreaDenominator", New TypeDescription("Number", NonNegativeNumber15_3));
	Parameters.ColumnDataType.Insert("AreaNumerator", New TypeDescription("Number", NonNegativeNumber15_3));
	Parameters.ColumnDataType.Insert("UnitFactorForReports", New TypeDescription("Number", NonNegativeNumber15_3));
	Parameters.ColumnDataType.Insert("Strength", New TypeDescription("Number", NonNegativeNumber15_3));
	
	ArrayOfRequiredColumns = New Array;
	ArrayOfRequiredColumns.Add("Description");
	ArrayOfRequiredColumns.Add("UnitOfMeasure");
	ArrayOfRequiredColumns.Add("SaleRegistrationOption");
	ArrayOfRequiredColumns.Add("ProductKind");
	ArrayOfRequiredColumns.Add("UseVariants");
	ArrayOfRequiredColumns.Add("Quality");
	ArrayOfRequiredColumns.Add("VATRate");
	ArrayOfRequiredColumns.Add("ItemsType");
	
	If Catalogs.ItemAccessGroups.AccessGroupsAreUsed() Then
		ArrayOfRequiredColumns.Add("AccessGroup");
	EndIf;
	
	Parameters.RequiredColumns2 = ArrayOfRequiredColumns;
	
	ProductsLocalization.DefineParametersForLoadingDataFromFile(Parameters);
	
EndProcedure

// Compares the uploaded data with the data in the information security system.
// The composition and type of columns in the table correspond to the Attributes of the Catalog or the "Upload File" Template.
//
// Parameters:
//   DataToImport - See ImportDataFromFile.MappingTable
//
Procedure MatchUploadedDataFromFile(DataToImport) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataForComparison.Description AS Description,
	|	DataForComparison.Id AS Id
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|
	|INDEX BY
	|	DataForComparison.Description,
	|	DataForComparison.Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products.Ref AS Products,
	|	DataForComparison.Id AS Id
	|FROM
	|	DataForComparison AS DataForComparison
	|		INNER JOIN Catalog.Products AS Products
	|		ON (Products.Description = DataForComparison.Description)
	|			AND (Products.DeletionMark = FALSE)
	|";
	
	Query.SetParameter("DataForComparison", DataToImport);

	QueryResult = Query.Execute().Select();

	While QueryResult.Next() Do
		Filter = New Structure("Id", QueryResult.Id);
		Rows = DataToImport.FindRows(Filter);
		For Each String In Rows Do
			String.MappingObject = QueryResult.Products;
		EndDo;
	EndDo;
	
EndProcedure

// Loading data from a file.
//
// Parameters:
//  DataToImport - See ImportDataFromFile.DescriptionOfTheUploadedDataForReferenceBooks
//  ImportParameters - See ImportDataFromFile.DataLoadingSettings
//  Cancel - Boolean    - cancel the download. For example, if the data is incorrect.
//
Procedure LoadFromFile(DataToImport, ImportParameters, Cancel) Export
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		Properties = New Map;
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		EmptyRefToObject = Catalogs.Products.EmptyRef();
		If ModulePropertyManager.UseAddlAttributes(EmptyRefToObject)
			Or ModulePropertyManager.UseAddlInfo(EmptyRefToObject) Then
			ListOfProperties = ModulePropertyManager.ObjectProperties(EmptyRefToObject);
			For Each Property In ListOfProperties Do
				Properties.Insert(String(Property), Property);
			EndDo;
		EndIf;
	EndIf;
	
	PropertiesTable = New ValueTable;
	PropertiesTable.Columns.Add("Property");
	PropertiesTable.Columns.Add("Value");
	
	QualityOfGoodsIsNotUsed = Not GetFunctionalOption("UseGoodsQuality");
	
	For Each TableRow In DataToImport Do
		MappingObjectIsFull = ValueIsFilled(TableRow.MappingObject);
		
		If (MappingObjectIsFull
			And ImportParameters.UpdateExistingItems = 0)
			Or (Not MappingObjectIsFull
			And ImportParameters.CreateNewItems = 0) Then
				TableRow.RowMappingResult = "Skipped";
				Continue;
		EndIf;
		
		AccessManagement.DisableAccessKeysUpdate(True);
		BeginTransaction();
		Try
			
			If MappingObjectIsFull Then
				
				Block        = New DataLock;
				LockItem = Block.Add("Catalog.Products");
				LockItem.SetValue("Ref", TableRow.MappingObject);
				Block.Lock();
				
				CatalogItem = TableRow.MappingObject.GetObject();
				
				If CatalogItem = Undefined Then
					Raise StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Mặt hàng có tên gọi %1bị trùng lặp, nhưng không còn tồn tại nữa.';
							|ru = 'Номенклатура с наименованием %1 была сопоставлена, но больше не существует.';
							|en = 'The %1 item has been matched but no longer exists.'; fa = 'The %1 item has been matched but no longer exists.';
							|it = 'L''articolo con il nome %1 è stato associato, ma non esiste più.';
							|pl = 'Produkt o nazwie %1 został porównany, ale więcej nie istnieje.';
							|tr = '%1 tanımlı öğe karşılaştırıldı, fakat artık mevcut değil.'"), TableRow.Description);
				EndIf;
				TableRow.RowMappingResult = "Updated";
				
			Else
				
				CatalogItem = CreateItem();
				TableRow.RowMappingResult = "Created";
				
			EndIf;
			
			CatalogItem.Description = TableRow.Description;
			
			PropertiesTable.Clear();
			For Each Column In DataToImport.Columns Do
				
				AttributeName = Column.Name;
				
				If AttributeName = "Id"
					Or AttributeName = "MappingObject"
					Or AttributeName = "RowMappingResult"
					Or AttributeName = "ConflictsList"
					Or AttributeName = "ErrorDescription"Then
					Continue;
				EndIf;
				
				If StrStartsWith(AttributeName, "AdditionalAttribute_") Then
					AddPropertyValue(PropertiesTable, Properties, "AdditionalAttribute_", AttributeName,  TableRow[AttributeName]);
				ElsIf StrStartsWith(AttributeName, "Property_") Then
					AddPropertyValue(PropertiesTable, Properties, "Property_", AttributeName,  TableRow[AttributeName]);
				Else
					CellValue = TableRow[AttributeName];
					If ValueIsFilled(CellValue) Then
						CatalogItem[AttributeName] = CellValue;
					EndIf;
				EndIf;
			EndDo;
			
			If QualityOfGoodsIsNotUsed Then
				CatalogItem.Quality = PredefinedValue("Enum.QualityLevels.New");
			EndIf;
			
			NationalLanguageSupportServer.BeforeWriteAtServer(CatalogItem);
			
			SessionParameters.PropertiesFillingInteractiveCheck = True;
			If Not CatalogItem.CheckFilling() Then
				TableRow.RowMappingResult = "Skipped";
				UserMessages = GetUserMessages(True);
				If UserMessages.Count()>0 Then
					MessagesText = "";
					For Each UserMessage In UserMessages Do
						MessagesText  = MessagesText + UserMessage.Text + Chars.LF;
					EndDo;
					TableRow.ErrorDescription = MessagesText;
				EndIf;
				RollbackTransaction();
			Else
				CatalogItem.Write();
				If PropertiesTable.Count() > 0 And Common.SubsystemExists("StandardSubsystems.Properties") Then
					ModulePropertyManager = Common.CommonModule("PropertyManager");
					ModulePropertyManager.WriteObjectProperties(CatalogItem.Ref, PropertiesTable);
				EndIf;
				
				TableRow.MappingObject = CatalogItem.Ref;
				AccessManagement.DisableAccessKeysUpdate(False);
				SessionParameters.PropertiesFillingInteractiveCheck = False;
				CommitTransaction();
			EndIf;
		Except
			RollbackTransaction();
			AccessManagement.DisableAccessKeysUpdate(False, False);
			SessionParameters.PropertiesFillingInteractiveCheck = False;
			Cause = BriefErrorDescription(ErrorInfo());
			TableRow.RowMappingResult = "Skipped";
			TableRow.ErrorDescription = NStr("vi = 'Không thể ghi lại dữ liệu do nguyên nhân:';
											|ru = 'Невозможна запись данных по причине:';
											|en = 'Cannot save the data due to:'; fa = 'Cannot save the data due to:';
											|it = 'Impossibile salvare i dati a causa di:';
											|pl = 'Zapisywanie danych jest niemożliwe z powodu:';
											|tr = 'Şu nedenlerle veri kaydedilmiyor:'") + Chars.LF + Cause;
		EndTry;
	EndDo;
	
EndProcedure

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	IsFolder OR
	|	ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers
 
Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then	
		If Parameters.Property("CopyingValue") Then
			CopiedObject = Parameters.CopyingValue;
			If Not CopiedObject.IsFolder Then
				StandardProcessing = False;
				Parameters = New Structure("CopyingValue", CopiedObject);
				SelectedForm = "ItemForm";
			EndIf;
		ElsIf Parameters.Property("ChoiceMode") Then
			If Parameters.ChoiceMode
				And (Not Parameters.Property("IsFolder")
				 	Or Not Parameters.IsFolder) Then
				StandardProcessing = False;
				SelectedForm = "ItemForm";
			EndIf;
		EndIf;
	ElsIf FormType = "ChoiceForm" Then
		ChoiceFoldersAndItems = Undefined;
		If Parameters.Property("ChoiceFoldersAndItems",ChoiceFoldersAndItems) Then
			If ChoiceFoldersAndItems = FoldersAndItemsUse.FoldersAndItems Then
				StandardProcessing = False;
				SelectedForm = "SelectionOfGroupsAndItemsForm";
			EndIf;
		Else
			StandardProcessing = False;
			SelectedForm = "SelectionOfGroupsAndItemsForm";
		EndIf;
	EndIf;
	
EndProcedure

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ProductsServerCall.ProductsProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// The item card
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ProductProfile";
	PrintCommand.Presentation = NStr("vi = 'In';
									|ru = 'Печать';
									|en = 'Print'; fa = 'چاپ';
									|it = 'Stampa';
									|pl = 'Print';
									|tr = 'Yazdır'");
	PrintCommand.FormCaption = NStr("vi = 'Thẻ mặt hàng';
									|ru = 'Карточка номенклатуры';
									|en = 'Item profile'; fa = 'پروفایل قلم';
									|it = 'Scheda articolo';
									|pl = 'Karta towaru';
									|tr = 'Ürün profili'");
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProductProfile") Then
		
		ObjectCount = ObjectsArray.Count();
		For IndexOf = 0 To ObjectCount - 1 Do
			
			CurrentIndex = ObjectCount - IndexOf - 1;
			CurrentObject = ObjectsArray[CurrentIndex];
			If Common.ObjectAttributeValue(CurrentObject, "IsFolder") Then
				ObjectsArray.Delete(CurrentIndex);
			EndIf;
			
		EndDo;
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection, 
			"ProductProfile", 
			?(ObjectsArray.Count() = 1, ObjectsArray[0], NStr("vi = 'Danh sách mặt hàng';
																|ru = 'Список номенклатуры';
																|en = 'Item list'; fa = 'فهرست اقلام';
																|it = 'Elenco di articoli';
																|pl = 'Lista nomenklatury';
																|tr = 'Ürün listesi'")), 
			CreatePrintedFormOfProductCard(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
	
EndProcedure

Function CreatePrintedFormOfProductCard(ObjectsArray, PrintObjects, PrintParameters)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ProductProfile";
	
	FirstCard = True;
	
	For Each Products In ObjectsArray Do
		If FirstCard Then
			FirstCard = False;
		Else
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		SpreadsheetDocument.Put(
			TableDocumentOfProductCard(Products, Undefined, True));
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

#Region ProductProfile

// Returns a table document for the item.
// Parameters:
//  Products - CatalogObject.Products, FormDataStructure - element to work out the logic
//                                                                       of the connection of details for.
//  VisibilityAndHeaderSettings - See VisibilityAndHeaderSettings
//  ForPrint - Boolean - indicates that the table document is being generated for printing
//
// Returns:
//	SpreadsheetDocument - a tabular document with the details.
//
Function TableDocumentOfProductCard(Products, VisibilityAndHeaderSettings, ForPrint) Export
	
	Var Title;
	
	If VisibilityAndHeaderSettings = Undefined Then
		VisibilityAndHeaderSettings = VisibilityAndHeaderSettings(Products);
	EndIf;
	
	Object = Undefined;
	If TypeOf(Products) = Type("CatalogRef.Products") Then
		Object = Products.GetObject();
	ElsIf TypeOf(Products) = Type("CatalogObject.Products")
		Or TypeOf(Products) = Type("FormDataStructure") Then
		Object = Products;
	Else
		Return New SpreadsheetDocument;
	EndIf;
	
	TableDocumentCard = New SpreadsheetDocument;
	
	VisibilityStructure = VisibilityAndHeaderSettings.VisibilityOfElements;
	TheStructureOfTheHeaders = VisibilityAndHeaderSettings.ItemsTitles;
	
	Template = GetTemplate("PF_MXL_ProductProfile");
	
	#Region Header
	
	SectionHeader = Template.GetArea("Header");
	FillPropertyValues(SectionHeader.Parameters, Object);
		
	If Not ValueIsFilled(Object.Description) Then
		SectionHeader.Parameters.Description = ValueTextIsNotFilledIn("Description");
	EndIf;
	If Not ForPrint Then
		SectionHeader.Parameters.Decryption_Name = "Description";
	EndIf;
	
	If Not ValueIsFilled(Object.DescriptionFull) Then
		SectionHeader.Parameters.DescriptionFull = ValueTextIsNotFilledIn("DescriptionFull");
	EndIf;
	If Not ForPrint Then
		SectionHeader.Parameters.DecryptionFullName = "DescriptionFull";
	EndIf;
	
	If Not ValueIsFilled(Object.SKU) Then
		SectionHeader.Parameters.SKU = ValueTextIsNotFilledIn("SKU");
	EndIf;
	If Not ForPrint Then
		SectionHeader.Parameters.DecodingArticle = "SKU";
	EndIf;
	
	If Not ValueIsFilled(Object.Code) Then
		SectionHeader.Parameters.Code = ValueTextIsNotFilledIn("Code");
	EndIf;
	If Not ForPrint Then
		SectionHeader.Parameters.DecryptionCode = "Code";
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToItemWithSimilarProperties", VisibilityStructure) Then
		If TheStructureOfTheHeaders.Property("HyperlinkGoToItemWithSimilarProperties", Title) Then
			SectionHeader.Parameters.HyperlinkGoToItemWithSimilarProperties = String(Title);
		EndIf;
		If Not ForPrint Then
			SectionHeader.Parameters.DecryptionHyperlinkGoProductsWithSimilarProperties = "HyperlinkGoToItemWithSimilarProperties";
		EndIf;
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToItemBarcodes", VisibilityStructure) Then 
		If TheStructureOfTheHeaders.Property("HyperlinkGoToItemBarcodes", Title) Then
			SectionHeader.Parameters.HyperlinkGoToItemBarcodes = String(Title);
		EndIf;
		If Not ForPrint Then
			SectionHeader.Parameters.DecryptionHyperlinkGoBarcodesProducts = "HyperlinkGoToItemBarcodes";
		EndIf;
	EndIf;
	
	TableDocumentCard.Join(SectionHeader);
	
	#EndRegion
		
	ColumnTabularDocument = New SpreadsheetDocument;
	
	#Region TabularDocumentLeft
	
	TabularDocumentLeft = New SpreadsheetDocument;
		
	#Region LongDesc
	
	If ChapterVisible("LongDesc", VisibilityStructure) Then 
		
		ScopeDescriptionHeader = Template.GetArea("DescriptionTitle");
		TabularDocumentLeft.Put(ScopeDescriptionHeader);
		
		// The output image
		If ValueIsFilled(Object.PicturesFile) Then
			
			AreaDescriptionPicture = Template.GetArea("PictureDescription_1");
			Try
				SetPrivilegedMode(True);
				ProductPicture = FilesOperations.FileBinaryData(Object.PicturesFile);
				SetPrivilegedMode(False);
			Except
				ProductPicture = Undefined;
			EndTry;
			
			If ValueIsFilled(ProductPicture) Then
				PictureArea = AreaDescriptionPicture.Areas.PictureAddress;
				
				If TypeOf(ProductPicture) = Type("Picture") Then
					PictureArea.Picture = ProductPicture;
				ElsIf TypeOf(ProductPicture) = Type("BinaryData") Then
					CardImage = New Picture(ProductPicture);
					
					PictureArea.Picture = ?(CardImage.Format() = PictureFormat.UnknownFormat,
												Undefined,
												CardImage);
				EndIf;
				
				If Not ForPrint Then
					AreaDescriptionPicture.Parameters.Details = "PicturesFile";
				EndIf;
				
				TabularDocumentLeft.Put(AreaDescriptionPicture);
			Else
				ImageDescriptionError = Template.GetArea("ImageFileStringError");
				If Not ForPrint Then
					ImageDescriptionError.Parameters.Details = "PicturesFile";
				EndIf;
				TabularDocumentLeft.Put(ImageDescriptionError);
			EndIf;
			
		Else
			
			PictureDescriptionNo = Template.GetArea("ImageFileString");
			If Not ForPrint Then
				PictureDescriptionNo.Parameters.Details = "PicturesFile";
			EndIf;
			TabularDocumentLeft.Put(PictureDescriptionNo);
			
		EndIf;	
		
		PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
		PartitionOutputParameters.SectionName = "LongDesc";
		PartitionOutputParameters.AreaNameString = "DescriptionString";
		PartitionOutputParameters.NameOfPropsParameter = "DescriptionProps";
		PartitionOutputParameters.TextOfPropsValue =  Object.LongDesc;
		OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		
		If SectionIsVisible("DescriptionFileForWebsite", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "DescriptionFileForWebsite";
			PartitionOutputParameters.AreaNameString = "SiteDescriptionFileString";
			PartitionOutputParameters.NameOfPropsParameter = "DESCRIPTIONFileForSiteProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.DescriptionFileForWebsite;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToFiles", VisibilityStructure) Then
			AreaDESCRIPTIONFilesString = Template.GetArea("StringFiles");
			
			If TheStructureOfTheHeaders.Property("HyperlinkGoToFiles", Title) Then
				AreaDESCRIPTIONFilesString.Parameters.Files = String(Title);
				If Not ForPrint Then
					AreaDESCRIPTIONFilesString.Parameters.Details = "HyperlinkGoToFiles";
				EndIf;
			EndIf;
			TabularDocumentLeft.Put(AreaDESCRIPTIONFilesString);
		EndIf;
		
		If SectionIsVisible("KeepRecordsOfQualityCertificates", VisibilityStructure) Then 
			
			
			Area = Template.GetArea("KeepRecordsOfProductCertificates");
			Picture = ImageOfFlagByValue(Object.KeepRecordsOfQualityCertificates);
			Area.Area("KeepRecordsOfQualityCertificatesFlag").Picture = Picture;
						
			If TheStructureOfTheHeaders.Property("HyperlinkGoToItemCertificates", Title) Then
				Area.Parameters.HyperlinkGoToItemCertificates = String(Title);
				If SectionIsVisible("HyperlinkGoCertificatesProductsAttention", VisibilityStructure) Then 
					Area.Area("HyperlinkGoCertificatesProductsAttention").Picture = PictureLib.Attention16;
				EndIf;
				If Not ForPrint Then
					Area.Parameters.DecryptingHyperlink = "HyperlinkGoToItemCertificates";
				EndIf;
			EndIf;
			
			If Not ForPrint Then
				Area.Parameters.Details = "KeepRecordsOfQualityCertificates";
			EndIf;
			TabularDocumentLeft.Put(Area);
			
		EndIf;
		
		
	EndIf;
		
	#EndRegion
	
	#Region AdditionalAttributes
	
	QueryText =
	"SELECT
	|	SetsOfAdditionalProps.LineNumber			AS RowNumberToSort,
	|	FALSE									AS CommonProperty,
	|	ItemKinds.PropertiesSet			AS PropertiesSet,
	|	SetsOfAdditionalProps.Property			AS Property,
	|	SetsOfAdditionalProps.Property.Name		AS AttributeName,
	|	SetsOfAdditionalProps.Property.Title	AS AttributeRepresentation,
	|	AdditionalAttributesOfItem.Value		AS Value
	|INTO AdditionalAttributesOfItem
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsOfAdditionalProps
	|		ON ItemKinds.PropertiesSet = SetsOfAdditionalProps.Ref
	|		
	|		LEFT JOIN Catalog.Products.AdditionalAttributes AS AdditionalAttributesOfItem
	|		ON AdditionalAttributesOfItem.Ref = &Products
	|			AND SetsOfAdditionalProps.Property = AdditionalAttributesOfItem.Property
	|WHERE
	|	ItemKinds.Ref IN(&ProductKind)
	|	AND NOT SetsOfAdditionalProps.Property.IsAdditionalInfo
	|
	|UNION ALL
	|
	|SELECT
	|	SetsOfAdditionalProps.LineNumber			AS RowNumberToSort,
	|	TRUE									AS CommonProperty,
	|	&SharedSet								AS PropertiesSet,
	|	SetsOfAdditionalProps.Property			AS Property,
	|	SetsOfAdditionalProps.Property.Name		AS AttributeName,
	|	SetsOfAdditionalProps.Property.Title	AS AttributeRepresentation,
	|	AdditionalAttributesOfItem.Value		AS Value
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsOfAdditionalProps
	|		LEFT JOIN Catalog.Products.AdditionalAttributes AS AdditionalAttributesOfItem
	|		ON AdditionalAttributesOfItem.Ref = &Products
	|			AND SetsOfAdditionalProps.Property = AdditionalAttributesOfItem.Property
	|WHERE
	|	SetsOfAdditionalProps.Ref = &SharedSet
	|	AND NOT SetsOfAdditionalProps.Property.IsAdditionalInfo
	|
	|INDEX BY
	|	Property
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DependenciesOfAdditionalAttributes.Ref		AS Property,
	|	DependenciesOfAdditionalAttributes.Attribute	AS Attribute,
	|	DependenciesOfAdditionalAttributes.Condition	AS Condition,
	|	DependenciesOfAdditionalAttributes.Value	AS Value
	|INTO ConditionsForVisibilityOfAdditionalProps
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.AdditionalAttributesDependencies AS DependenciesOfAdditionalAttributes
	|		INNER JOIN AdditionalAttributesOfItem AS AdditionalAttributesOfItem
	|		ON DependenciesOfAdditionalAttributes.Ref = AdditionalAttributesOfItem.Property
	|
	|WHERE
	|	DependenciesOfAdditionalAttributes.PropertiesSet IN(&ViewSet, &SharedSet)
	|	AND DependenciesOfAdditionalAttributes.DependentProperty LIKE ""isVisible""";
	
	QueryText = StrReplace(QueryText,
								"&ViewSet",
								"CAST(&ProductKind AS Catalog.ItemKinds).PropertiesSet");
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("ProductKind",	Object.ProductKind);
	Query.SetParameter("Products",		Object.Ref);
	Query.SetParameter("SharedSet",			PropertyManager.PropertiesSetByName("Catalog_Products_Overall"));
	
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	AdditionalAttributes		= QueryResult[0].Unload();
	VisibilityConditionsForAttributes	= QueryResult[1].Unload();
	
	If ChapterVisible("AdditionalAttributes", VisibilityStructure, AdditionalAttributes.Count()) Then
		
		HeaderArea_ = Template.GetArea("AdditionalDetailsHeader");
		
		TabularDocumentLeft.Put(HeaderArea_);
		
		AdditionalAttributes.Sort("CommonProperty Desc, RowNumberToSort Asc");
		VisibilityConditionsForAttributes.Indexes.Add("Property");
		
		For Each AdditionalAttribute5 In AdditionalAttributes Do
			
			AttributeValue = AdditionalAttribute5.Value;
			If Not ValueIsFilled(AttributeValue)
				And AdditionalAttribute5.Property.ValueType = New TypeDescription("Boolean") Then
				
				AttributeValue = False;
				
			EndIf;
			
			NameOfAdditionalPropsElement = "AdditionalAttributeValue_" 
										+ StrReplace(Upper(String(AdditionalAttribute5.PropertiesSet.UUID())), "-", "x")
										+ "_"
										+ StrReplace(Upper(String(AdditionalAttribute5.Property.UUID())), "-", "x");
			
				
			OutputAttribute = VisibilityOfAdditionalAttributes(Object,
																AdditionalAttribute5,
																AdditionalAttributes,
																VisibilityConditionsForAttributes)
								And SectionIsVisible(NameOfAdditionalPropsElement, VisibilityStructure);
			
			If OutputAttribute Then
				PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
				PartitionOutputParameters.SectionName				= "AdditionalAttributes";
				PartitionOutputParameters.AreaNameString			= "AdditionalDetailsLine";
				PartitionOutputParameters.NameOfPropsParameter		= "AdditionalDetailsDetails";
				PartitionOutputParameters.TextOfPropsValue	= AttributeValue;
				PartitionOutputParameters.PropsHeaderText	= AdditionalAttribute5.AttributeRepresentation;
				PartitionOutputParameters.NewPartitionName			= NameOfAdditionalPropsElement;
				
				OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
			EndIf;
		EndDo;
		
	EndIf;
	
	#EndRegion	
	
	#Region ManufacturerDetails
	
	If ChapterVisible("ManufacturerDetails", VisibilityStructure) Then 

		
		ScopeDescriptionHeader = Template.GetArea("ManufacturerInformationHeader");
		TabularDocumentLeft.Put(ScopeDescriptionHeader);
		
		If SectionIsVisible("ManufacturerImporterConterparty", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "ManufacturerImporterConterparty";
			PartitionOutputParameters.AreaNameString = "ManufacturerImporterCounterpartyString";
			PartitionOutputParameters.NameOfPropsParameter = "ManufacturerImporterCounterpartyDetails";
			PartitionOutputParameters.TextOfPropsValue = Object.ManufacturerImporterConterparty;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("Manufacturer", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "Manufacturer";
			PartitionOutputParameters.AreaNameString = "ManufacturerString";
			PartitionOutputParameters.NameOfPropsParameter = "ManufacturerProps";
			PartitionOutputParameters.TextOfPropsValue = Object.Manufacturer;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("Brand", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "Brand";
			PartitionOutputParameters.AreaNameString = "BrandLine";
			PartitionOutputParameters.NameOfPropsParameter = "BrandProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.Brand;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("OriginCountry", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "OriginCountry";
			PartitionOutputParameters.AreaNameString = "CountryOfOriginString";
			PartitionOutputParameters.NameOfPropsParameter = "CountryOfOriginProps";
			PartitionOutputParameters.TextOfPropsValue = Object.OriginCountry;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("Principal", VisibilityStructure)
			Or SectionIsVisible("Counterparty", VisibilityStructure)
			Or SectionIsVisible ("HyperlinkGoToAgreements", VisibilityStructure) Then
			AreaImplementationOfServiceUnderAgencyAgreement = Template.GetArea("SalesOfAServiceUnderAnAgencyAgreement");
			If TheStructureOfTheHeaders.Property("AgencyServicesGroup", Title) Then
				AreaImplementationOfServiceUnderAgencyAgreement.Parameters.SalesOfAServiceUnderAnAgencyAgreement = Title;
			EndIf;
			If Not ForPrint Then
				AreaImplementationOfServiceUnderAgencyAgreement.Parameters.Details = "AgencyServicesGroup";
			EndIf;
			TabularDocumentLeft.Put(AreaImplementationOfServiceUnderAgencyAgreement);
		EndIf;
		
		If SectionIsVisible("Principal", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "Principal";
			PartitionOutputParameters.AreaNameString = "PrincipalString";
			PartitionOutputParameters.NameOfPropsParameter = "PrincipalProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.Principal;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("Counterparty", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "Counterparty";
			PartitionOutputParameters.AreaNameString = "CounterpartyString";
			PartitionOutputParameters.NameOfPropsParameter = "CounterpartyDetails";
			PartitionOutputParameters.TextOfPropsValue =  Object.Counterparty;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToAgreements", VisibilityStructure) Then 
			HyperlinkAreaGoToAgreement = Template.GetArea("HyperlinkGoToString");
			
			HyperlinkAreaGoToAgreement.Parameters.HyperlinkGoToAgreements = String(
				TheStructureOfTheHeaders.HyperlinkGoToAgreements.Title);
			
			If Not ForPrint Then
				DecryptionOfAgreement = New Structure;
				DecryptionOfAgreement.Insert("TagName", "HyperlinkGoToAgreements");
				DecryptionOfAgreement.Insert("Hyperlink", TheStructureOfTheHeaders.HyperlinkGoToAgreements.Hyperlink);
				
				HyperlinkAreaGoToAgreement.Parameters.Details = DecryptionOfAgreement;
			EndIf;
			
			TabularDocumentLeft.Put(HyperlinkAreaGoToAgreement);
		EndIf;
		
	EndIf;	
	
	#EndRegion
	
	#Region PlanningAndMarketing
	
	If ChapterVisible("PlanningAndMarketing", VisibilityStructure) Then 
		
		ScopeDescriptionHeader = Template.GetArea("PlanningAndMarketing_");
		TabularDocumentLeft.Put(ScopeDescriptionHeader);
		
		If SectionIsVisible("ProductCategory", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "ProductCategory";
			PartitionOutputParameters.AreaNameString = "ProductCategoryString";
			PartitionOutputParameters.NameOfPropsParameter = "ProductCategoryDetails";
			PartitionOutputParameters.TextOfPropsValue =  Object.ProductCategory;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("ItemsCollection", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "ItemsCollection";
			PartitionOutputParameters.AreaNameString = "CollectionOfProducts";
			PartitionOutputParameters.NameOfPropsParameter = "CollectionOfProductsProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.ItemsCollection;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("ItemsGroup", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "ItemsGroup";
			PartitionOutputParameters.AreaNameString = "SeasonalGroupString";
			PartitionOutputParameters.NameOfPropsParameter = "SeasonalGroupProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.ItemsGroup;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("SalesRank", VisibilityStructure) Then 
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "SalesRank";
			PartitionOutputParameters.AreaNameString = "SalesRatingLine";
			PartitionOutputParameters.NameOfPropsParameter = "SalesRatingProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.SalesRank;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToJointSales", VisibilityStructure) Then
			AreaHyperlinkGoJointSalesLine = Template.GetArea("HyperlinkGoJointSalesLine");
			If Not ForPrint Then
				AreaHyperlinkGoJointSalesLine.Parameters.Details = "HyperlinkGoToJointSales";
			EndIf;
			TabularDocumentLeft.Put(AreaHyperlinkGoJointSalesLine);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToSegments", VisibilityStructure) Then
			HyperlinkGoSegmentsArea = Template.GetArea("HyperlinkGoSegmentsLine");
			If TheStructureOfTheHeaders.Property("HyperlinkGoToSegments", Title) Then  
				HyperlinkGoSegmentsArea.Parameters.HyperlinkGoToSegments = String(Title);
			EndIf;
			If Not ForPrint Then
				HyperlinkGoSegmentsArea.Parameters.Details = "HyperlinkGoToSegments";
			EndIf;
			TabularDocumentLeft.Put(HyperlinkGoSegmentsArea);
		EndIf;
				
	EndIf;	
	
	#EndRegion
	
	#Region SupplyAndProduction
	
	If ChapterVisible("SupplyAndProduction", VisibilityStructure) Then 
		
		Area = Template.GetArea("ProvisionAndProductionOfServices");
		If TheStructureOfTheHeaders.Property("DecorationSoftware", Title) Then
			Area.Parameters.ProvidingProduction = Title;
		EndIf;		
		TabularDocumentLeft.Put(Area);
		
		If SectionIsVisible("AssignedPurchaseSale", VisibilityStructure) Then
			Area = Template.GetArea("SeparatePurchaseSaleLine");
			Picture = ImageOfFlagByValue(Object.AssignedPurchaseSale);
			Area.Area("AssignedPurchaseSaleFlag").Picture = Picture;
			If Not ForPrint Then
				Area.Parameters.Details = "AssignedPurchaseSale";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
		
		If SectionIsVisible("ProcurementStrategy", VisibilityStructure) Then 
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "ProcurementStrategy";
			PartitionOutputParameters.AreaNameString = "WayToEnsureNeedsOfLine";
			PartitionOutputParameters.NameOfPropsParameter = "WayToEnsureNeedsOfProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.ProcurementStrategy;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("SupplyScheme", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "SupplyScheme";
			PartitionOutputParameters.AreaNameString = "SecuritySchemeString";
			PartitionOutputParameters.NameOfPropsParameter = "SchemeOfProvidingProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.SupplyScheme;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
				
		If SectionIsVisible("HyperlinkGoConfigurationOptions", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkGoConfigurationOptionsString");
			If TheStructureOfTheHeaders.Property("HyperlinkGoConfigurationOptions", Title) Then
				Area.Parameters.HyperlinkGoConfigurationOptions = String(Title);
			EndIf;
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoConfigurationOptions";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToInventoryMaintenanceSettings", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkGoToInventoryMaintenanceSettingsLine");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoToInventoryMaintenanceSettings";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoSettingUpWaysToMeetYourNeeds", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkConfiguringWaysToMeetNeeds");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoSettingUpWaysToMeetYourNeeds";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoSettingUpTheTransferOfMaterialsToProduction", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkGoSettingUpMaterialTransferToProductionLine");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoSettingUpTheTransferOfMaterialsToProduction";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToProduction", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkGoProductionLine");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoToProduction";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
				
	EndIf;	
	
	#EndRegion
	
	#Region QualityControl
	
	If ChapterVisible("QualityControl", VisibilityStructure) Then 
		
		ScopeDescriptionHeader = Template.GetArea("QualityControlHeader");
		TabularDocumentLeft.Put(ScopeDescriptionHeader);
		
		If SectionIsVisible("ControlQualityOfReceivedGoods", VisibilityStructure) Then
			Area = Template.GetArea("MonitorQualityOfReceivedGoodsLine");
			Picture = ImageOfFlagByValue(Object.ControlQualityOfReceivedGoods);
			Area.Area("ControlQualityOfReceivedGoodsFlag").Picture = Picture;
			If Not ForPrint Then
				Area.Parameters.Details = "ControlQualityOfReceivedGoods";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
		
		If SectionIsVisible("TermOfQualityControl", VisibilityStructure) Then 
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "TermOfQualityControl";
			PartitionOutputParameters.AreaNameString = "TermOfQualityControlLine";
			PartitionOutputParameters.NameOfPropsParameter = "QualityControlPeriodAttributes";
			PartitionOutputParameters.TextOfPropsValue =  Object.TermOfQualityControl;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region Prices
	
	If ChapterVisible("Prices", VisibilityStructure) Then 

		
		ScopeDescriptionHeader = Template.GetArea("PricesHeader");
		TabularDocumentLeft.Put(ScopeDescriptionHeader);
		
		If SectionIsVisible("PriceGroup", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "PriceGroup";
			PartitionOutputParameters.AreaNameString = "PriceGroupString";
			PartitionOutputParameters.NameOfPropsParameter = "PriceGroupProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.PriceGroup;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentLeft, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToCompanyPriceList", VisibilityStructure) Then
			Area = Template.GetArea("PriceListOfCompanyLine");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoToCompanyPriceList";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToSupplierPriceLists", VisibilityStructure) Then
			Area = Template.GetArea("SuppliersPriceLists");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoToSupplierPriceLists";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoCompanyPriceChangeHistory", VisibilityStructure) Then
			Area = Template.GetArea("PriceChangeHistoryOfCompany");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoCompanyPriceChangeHistory";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoSupplierPriceChangeHistory", VisibilityStructure) Then
			Area = Template.GetArea("SupplierPriceChangeHistoryLine");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoSupplierPriceChangeHistory";
			EndIf;
			TabularDocumentLeft.Put(Area);
		EndIf;
		
	EndIf;
				
	#EndRegion
	
	#Region PrintPriceTagsAndLabels
	
	If ChapterVisible("PrintPriceTagsAndLabels", VisibilityStructure) Then 
		
		TypeOfProductTemplates = Common.ObjectAttributesValues(Object.ProductKind, "PriceTagTemplate, LabelsTemplate");
		
		ScopeDescriptionHeader = Template.GetArea("PrintingLabelsAndPriceTags");
		TabularDocumentLeft.Put(ScopeDescriptionHeader);
		
		Area = Template.GetArea("UseCustomLabelTemplate");
		If Object.UseCustomTemplateLabels Then
			Area.Parameters.UseCustomTemplateLabels = NStr("vi = 'Khuôn mẫu nhãn tem riêng:';
															|ru = 'Индивидуальный шаблон этикетки:';
															|en = 'Custom label template:'; fa = 'Custom label template:';
															|it = 'Modello individuale dell''etichetta:';
															|pl = 'Indywidualny szablon etykiety:';
															|tr = 'Özelleştirilmiş etiket numunesi:'");
			If Not ForPrint Then
				Area.Parameters.Details = "UseCustomTemplateLabels";
			EndIf;
			TabularDocumentLeft.Put(Area);
			LabelArea_ = Template.GetArea("LabelTemplateLine");
			LabelArea_.Parameters.LabelsTemplate = Object.LabelsTemplate;
			If Not ForPrint Then
				LabelArea_.Parameters.Details = "LabelsTemplate";
			EndIf;
			TabularDocumentLeft.Put(LabelArea_);
		Else
			Area.Parameters.UseCustomTemplateLabels = NStr("vi = 'Sử dụng chung cho dạng mẫu nhãn tem';
															|ru = 'Используется общий для вида шаблон этикетки';
															|en = 'Label template common for the kind is used'; fa = 'Label template common for the kind is used';
															|it = 'Viene utilizzato il modello comune per tipo di etichetta';
															|pl = 'Jest wykorzystywany wspólny dla rodzaju szablon etykiety';
															|tr = 'Tür için paylaşımlı etiket numunesi kullanılıyor'");
			If Not ForPrint Then
				Area.Parameters.Details = "UseCustomTemplateLabels";
			EndIf;
			TabularDocumentLeft.Put(Area);
			LabelArea_ = Template.GetArea("LabelTemplateLine");
			If ValueIsFilled(TypeOfProductTemplates.LabelsTemplate) Then
				LabelArea_.Parameters.LabelsTemplate = TypeOfProductTemplates.LabelsTemplate;
			Else
				LabelArea_.Parameters.LabelsTemplate =  NStr("vi = '<chưa chỉ ra>';
															|ru = '<не указан>';
															|en = '<not specified>'; fa = '<مشخص نشده>';
															|it = '<non specificato>';
															|pl = '<nie określono>';
															|tr = '<belirtilmedi>'");
			EndIf;
			If Not ForPrint Then
				LabelArea_.Parameters.Details = "LabelsTemplate";
			EndIf;
			TabularDocumentLeft.Put(LabelArea_);
		EndIf;
		
		Area = Template.GetArea("UseCustomizedPriceTagTemplate");
		If Object.UseCustomPriceTagTemplate Then
			Area.Parameters.UseCustomPriceTagTemplate = NStr("vi = 'Mẫu nhãn giá riêng:';
															|ru = 'Индивидуальный шаблон ценника:';
															|en = 'Custom price tag template:'; fa = 'Custom price tag template:';
															|it = 'Il modello individuale del cartellino prezzi:';
															|pl = 'Indywidualny szablon cennika:';
															|tr = 'Özelleştirilmiş fiyat etiketi numunesi:'");
			Area.Parameters.Details = "UseCustomPriceTagTemplate";
			TabularDocumentLeft.Put(Area);
			PriceTagArea = Template.GetArea("PriceTagTemplateLine");
			PriceTagArea.Parameters.PriceTagTemplate = Object.PriceTagTemplate;
			If Not ForPrint Then
				PriceTagArea.Parameters.Details = "PriceTagTemplate";
			EndIf;
			TabularDocumentLeft.Put(PriceTagArea);
		Else
			Area.Parameters.UseCustomPriceTagTemplate = NStr("vi = 'Sử dụng chung cho dạng mẫu nhãn giá';
															|ru = 'Используется общий для вида шаблон ценника';
															|en = 'Price tag template common for the kind is used'; fa = 'Price tag template common for the kind is used';
															|it = 'Viene utilizzato il modello comune per tipo cartellino prezzi';
															|pl = 'Jest wykorzystywany wspólny dla rodzaju szablon cennika';
															|tr = 'Tür için paylaşımlı fiyat etiketi numunesi kullanılıyor'");
			If Not ForPrint Then
				Area.Parameters.Details = "UseCustomPriceTagTemplate";
			EndIf;
			TabularDocumentLeft.Put(Area);
			PriceTagArea = Template.GetArea("PriceTagTemplateLine");
			If ValueIsFilled(TypeOfProductTemplates.PriceTagTemplate) Then
				PriceTagArea.Parameters.PriceTagTemplate = TypeOfProductTemplates.PriceTagTemplate;
			Else
				PriceTagArea.Parameters.PriceTagTemplate =  NStr("vi = '<chưa chỉ ra>';
																|ru = '<не указан>';
																|en = '<not specified>'; fa = '<مشخص نشده>';
																|it = '<non specificato>';
																|pl = '<nie określono>';
																|tr = '<belirtilmedi>'");
			EndIf;
			If Not ForPrint Then
				PriceTagArea.Parameters.Details = "PriceTagTemplate";
			EndIf;
			TabularDocumentLeft.Put(PriceTagArea);
		EndIf;
				
	EndIf;	
	
	#EndRegion
	
	ColumnTabularDocument.Join(TabularDocumentLeft);
	
	#EndRegion
		
	#Region TabularDocumentRight
	
	TabularDocumentRight = New SpreadsheetDocument;
	
	
	#Region MainAccountingParameters
	
	If ChapterVisible("MainAccountingParameters", VisibilityStructure) Then 
		
		HeaderArea_ = Template.GetArea("MainAccountingParametersHeader");
		TabularDocumentRight.Put(HeaderArea_);
		
		If SectionIsVisible("Parent", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "Parent";
			PartitionOutputParameters.AreaNameString = "ParentString_";
			PartitionOutputParameters.NameOfPropsParameter = "ParentProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.Parent;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("AccessGroup", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "AccessGroup";
			PartitionOutputParameters.AreaNameString = "AccessGroupString";
			PartitionOutputParameters.NameOfPropsParameter = "AccessGroupProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.AccessGroup;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;

		If SectionIsVisible("ProductKind", VisibilityStructure) Or SectionIsVisible("ProductKindSwitch", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "ProductKind";
			PartitionOutputParameters.AreaNameString = "TypeOfProductLine";
			PartitionOutputParameters.NameOfPropsParameter = "TypeOfProductDetails";
			PartitionOutputParameters.TextOfPropsValue =  Object.ProductKind;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("ItemsType", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "ItemsType";
			PartitionOutputParameters.AreaNameString = "ProductTypeString";
			PartitionOutputParameters.NameOfPropsParameter = "ProductTypeProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.ItemsType;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoSetComposition", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkGoSetCompositionString");
			If TheStructureOfTheHeaders.Property("HyperlinkGoSetComposition", Title) Then
				Area.Parameters.HyperlinkGoSetComposition = String(Title);
				If SectionIsVisible("HyperlinkGoSetCompositionAttention", VisibilityStructure) Then
					Area.Area("HyperlinkGoSetCompositionAttention").Picture = PictureLib.Attention16;
				EndIf;
			EndIf;
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoSetComposition";
			EndIf;
			TabularDocumentRight.Put(Area);
		EndIf;
		
		If SectionIsVisible("UseVariants", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "UseVariants";
			PartitionOutputParameters.AreaNameString = "UsingStringCharacteristics";
			PartitionOutputParameters.NameOfPropsParameter = "UsingPropsCharacteristics";
			PartitionOutputParameters.TextOfPropsValue = Object.UseVariants;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToItemCharacteristics", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkGoToProductCharacteristicsLine");
			If TheStructureOfTheHeaders.Property("HyperlinkGoToItemCharacteristics", Title) Then
				Area.Parameters.HyperlinkGoToItemCharacteristics = String(Title);
			EndIf;
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoToItemCharacteristics";
			EndIf;
			TabularDocumentRight.Put(Area);
		EndIf;

		
		If SectionIsVisible("BatchUsageSettings", VisibilityStructure) Then
			BatchUsageSettings = Common.ObjectAttributeValue(Object.ProductKind, "BatchUsageSettings");
			If Not ValueIsFilled(BatchUsageSettings) Then
				ConfiguringSerialUsage = NStr("vi = 'Không sử dụng';
												|ru = 'Не используются';
												|en = 'Not used'; fa = 'استفاده نمی‌شود';
												|it = 'Non vengono utilizzati';
												|pl = 'Nie używa się';
												|tr = 'Kullanılmıyor'");
			Else
				ConfiguringSerialUsage = String(BatchUsageSettings);
			EndIf;
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "BatchUsageSettings";
			PartitionOutputParameters.AreaNameString = "ConfiguringSerialUsage";
			PartitionOutputParameters.NameOfPropsParameter = "SettingUpUseOfPropsSeries";
			PartitionOutputParameters.TextOfPropsValue = ConfiguringSerialUsage;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("SaleRegistrationOption", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "SaleRegistrationOption";
			PartitionOutputParameters.AreaNameString = "OptionForRegistrationOfSaleLine";
			PartitionOutputParameters.NameOfPropsParameter = "OptionForRegistrationOfSaleProps";
			PartitionOutputParameters.TextOfPropsValue =  Object.SaleRegistrationOption;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("VATRate", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "VATRate";
			PartitionOutputParameters.AreaNameString = "VATRateLine";
			PartitionOutputParameters.NameOfPropsParameter = "VATRateDetails";
			PartitionOutputParameters.TextOfPropsValue = Object.VATRate;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("HyperlinkToProductVATRates", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkToProductItemVATRatesLine");
			If TheStructureOfTheHeaders.Property("HyperlinkToProductVATRates", Title) Then
				Area.Parameters.HyperlinkToProductVATRates = String(Title);
			EndIf;
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkToProductVATRates";
			EndIf;
			TabularDocumentRight.Put(Area);
		EndIf;
		
		If Catalogs.Products.SectionIsVisible("FEACNCode", VisibilityStructure) Then
			
			StringTNVED = "";
			
			If ValueIsFilled(Object.FEACNCode) Then
				Var_148_Template			= NStr("vi = '%Mã% (%Tên%)';
													|ru = '%Code% (%Description%)';
													|en = '%Code% (%Description%)'; fa = '%Code% (%Description%)';
													|it = '%Code% (%Description%)';
													|pl = '%Code% (%Description%)';
													|tr = '%Code% (%Description%)'");
				Description	= Common.ObjectAttributeValue(Object.FEACNCode, "Description");
				
				StringTNVED = StrReplace(Var_148_Template,		"%Code%",			Object.FEACNCode);
				StringTNVED = StrReplace(StringTNVED,	"%Description%",	Description);
			EndIf;
			
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "FEACNCode";
			PartitionOutputParameters.AreaNameString = "HSCodeString";
			PartitionOutputParameters.NameOfPropsParameter = "HSCodeProps";
			PartitionOutputParameters.TextOfPropsValue = StringTNVED;
			Catalogs.Products.OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint,PartitionOutputParameters);
			
		EndIf;
		
		If SectionIsVisible("Quality", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "Quality";
			PartitionOutputParameters.AreaNameString = "QualityString";
			PartitionOutputParameters.NameOfPropsParameter = "QualityProps";
			PartitionOutputParameters.TextOfPropsValue = Object.Quality;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToOtherQualityProducts", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkToProductsOfDifferentQualityLine");
			If TheStructureOfTheHeaders.Property("HyperlinkGoToOtherQualityProducts", Title) Then
				Area.Parameters.HyperlinkGoToOtherQualityProducts = String(Title);
			EndIf;
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoToOtherQualityProducts";
			EndIf;
			TabularDocumentRight.Put(Area);
		EndIf;
	EndIf;
	
	#EndRegion
	
	#Region UnitsAndStorageArea
	
	If ChapterVisible("UnitsAndStorageArea", VisibilityStructure) Then 
		
		HeaderArea_ = Template.GetArea("UnitsOfMeasurementAndStorageAreaHeader");
		TabularDocumentRight.Put(HeaderArea_);
		
		If SectionIsVisible("UsePackages", VisibilityStructure) Then 
			If Object.UsePackages Then
				If Object.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem Then
					Set = NStr("vi = 'Bộ sản phẩm riêng';
								|ru = 'Индивидуальный набор';
								|en = 'Custom set of packaging units'; fa = 'مجموعه سفارشی واحدهای بسته‌بندی';
								|it = 'Insieme personalizzato';
								|pl = 'Zestaw indywidualny';
								|tr = 'Özelleştirilmiş küme'");
				Else
					Set = Object.PackagingGroup;
				EndIf;
				
				PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
				PartitionOutputParameters.SectionName = "UsePackages";
				PartitionOutputParameters.AreaNameString = "UseFollowingString";
				PartitionOutputParameters.NameOfPropsParameter = "UsePackingProps";
				PartitionOutputParameters.TextOfPropsValue = Set;
				OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
			Else
				PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
				PartitionOutputParameters.SectionName = "UsePackages";
				PartitionOutputParameters.AreaNameString = "UseFollowingString";
				PartitionOutputParameters.NameOfPropsParameter = "UsePackingProps";
				PartitionOutputParameters.TextOfPropsValue = NStr("vi = 'không sử dụng';
																	|ru = 'не используются';
																	|en = 'not used'; fa = 'استفاده نمی‌شود';
																	|it = 'non vengono utilizzati';
																	|pl = 'nie używa się';
																	|tr = 'kullanılmıyor'");
				OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
			EndIf;
		EndIf;
				
		If SectionIsVisible("HyperlinkGoToItemPackaging", VisibilityStructure) Then 
			Area = Template.GetArea("HyperlinkGoPackingProductLine");
			If TheStructureOfTheHeaders.Property("HyperlinkGoToItemPackaging", Title) Then  
				Area.Parameters.HyperlinkGoToItemPackaging = String(Title);
				If SectionIsVisible("HyperlinkForProductPackagingAttention", VisibilityStructure) Then 
					Area.Area("HyperlinkForProductPackagingAttention").Picture = PictureLib.Attention16;
				EndIf;
			EndIf;
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoToItemPackaging";
			EndIf;
			TabularDocumentRight.Put(Area);
		EndIf;
		
		If SectionIsVisible("HyperlinkToGoPackingSet", VisibilityStructure) Then 
			Area = Template.GetArea("HyperlinkGoPackingSetString");
			If TheStructureOfTheHeaders.Property("HyperlinkToGoPackingSet", Title) Then  
				Area.Parameters.HyperlinkToGoPackingSet = String(Title);
				If SectionIsVisible("HyperlinkGoPackingSetAttention", VisibilityStructure) Then 
					Area.Area("HyperlinkGoPackingSetAttention").Picture = PictureLib.Attention16;
				EndIf;
			EndIf;
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkToGoPackingSet";
			EndIf;
			TabularDocumentRight.Put(Area);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToPackageConsumptionForecasts", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkGoToPackageConsumptionForecastsLine");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoToPackageConsumptionForecasts";
			EndIf;
			TabularDocumentRight.Put(Area);
		EndIf;
		
		If SectionIsVisible("UnitOfMeasure", VisibilityStructure) Then
			
			FillString = NStr("vi = '%UnitOfMeasure%%Tara%';
								|ru = '%UnitOfMeasure%%Tara%';
								|en = '%UnitOfMeasure%%Tara%'; fa = '%UnitOfMeasure%%Tara%';
								|it = '%UnitOfMeasure%%Tara%';
								|pl = '%UnitOfMeasure%%Tara%';
								|tr = '%UnitOfMeasure%%Tara%'");
			If ValueIsFilled(Object.UnitOfMeasure) Then
				FillString = StrReplace(FillString, "%UnitOfMeasure%", Object.UnitOfMeasure);
			Else
				FillString = StrReplace(FillString, "%UnitOfMeasure%", NStr("vi = '<chưa chỉ ra>';
																			|ru = '<не указана>';
																			|en = '<line not specified>'; fa = '<line not specified>';
																			|it = '<non indicata>';
																			|pl = '<nie określono>';
																			|tr = '<belirtilmedi>'"));
			EndIf;
			
			If Object.SuppliedInReusablePackage Then 
				FillString = StrReplace(FillString, "%Tara%", NStr("vi = ',cung cấp trong bao bì';
																	|ru = ', поставляется в таре';
																	|en = ', supplied in package'; fa = ', supplied in package';
																	|it = ', fornita con imballaggio';
																	|pl = ', jest dostarczany w tarze';
																	|tr = ', ambalajda teslim edilmektedir'"));
			Else
				FillString = StrReplace(FillString, "%Tara%", "");
			EndIf;
			
			TheStructureOfTheHeaders.Property("UnitOfMeasure", Title);
			
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "UnitOfMeasure";
			PartitionOutputParameters.AreaNameString = "UnitOfMeasurementString";
			PartitionOutputParameters.NameOfPropsParameter = "UnitOfMeasurementProps";
			PartitionOutputParameters.PropsHeaderText = Title;
			PartitionOutputParameters.TextOfPropsValue = FillString;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);

		EndIf;
		
		If SectionIsVisible("ReusablePackageItems", VisibilityStructure) Then
			
			FillString = ProductsClientServer.ProductPresentation(
				Object.ReusablePackageItems,
				Object.ReusablePackageVariant);				
			
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "ReusablePackageItems";
			PartitionOutputParameters.AreaNameString = "ProductsMultiTurnPackagingLine";
			PartitionOutputParameters.NameOfPropsParameter = "ProductsMultiTurnPackagingProps";
			PartitionOutputParameters.TextOfPropsValue = FillString;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
			
		EndIf;
		
		If SectionIsVisible("UnitForReports", VisibilityStructure) Then
			
			FillString = NStr("vi = '<chưa chỉ ra>';
								|ru = '<не указана>';
								|en = '<line not specified>'; fa = '<line not specified>';
								|it = '<non indicata>';
								|pl = '<nie określono>';
								|tr = '<belirtilmedi>'");
			
			If ValueIsFilled(Object.UnitForReports) Then
				If Object.UnitForReports <> Object.UnitOfMeasure Then
					FillString = NStr("vi = '%UnitForReports%, chứa %Count% %UnitOfMeasure%';
										|ru = '%UnitForReports%, содержит %Count% %UnitOfMeasure%';
										|en = '%UnitForReports% contains %Count% %UnitOfMeasure%'; fa = '%UnitForReports% contains %Count% %UnitOfMeasure%';
										|it = '%UnitForReports%, contiene %Count% %UnitOfMeasure%';
										|pl = '%UnitForReports%, zawiera %Count%%UnitOfMeasure%';
										|tr = '%UnitForReports%, %Count% %UnitOfMeasure% içeriyor'");
					FillString = StrReplace(FillString, "%Count%", Object.UnitFactorForReports);
					FillString = StrReplace(FillString, "%UnitOfMeasure%", Object.UnitOfMeasure);
				Else
					FillString = NStr("vi = '%UnitForReports%';
										|ru = '%UnitForReports%';
										|en = '%UnitForReports%'; fa = '%UnitForReports%';
										|it = '%UnitForReports%';
										|pl = '%UnitForReports%';
										|tr = '%UnitForReports%'");
				EndIf;
				
				FillString = StrReplace(FillString, "%UnitForReports%", Object.UnitForReports);
			EndIf;
			
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "UnitForReports";
			PartitionOutputParameters.AreaNameString = "UnitForReportsLine";
			PartitionOutputParameters.NameOfPropsParameter = "ReportingUnitProps";
			PartitionOutputParameters.TextOfPropsValue = FillString;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
			
		EndIf;
		
		If SectionIsVisible("Weight", VisibilityStructure) Then
			
			If Object.WeightUse Then
				FillString = NStr("vi = '%Count1% %UnitOfMeasure% nặng %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|ru = '%Count1% %UnitOfMeasure% весит %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|en = '%Count1% %UnitOfMeasure% weighs %Count2% %Unit%, %CanBeSpecifiedInDocuments%'; fa = '%Count1% %UnitOfMeasure% weighs %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|it = '%Count1% %UnitOfMeasure% pesa %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|pl = '%Count1%%UnitOfMeasure% waży %Count2%%Unit%, %CanBeSpecifiedInDocuments%';
									|tr = '%Count1% %UnitOfMeasure% %Count2% %Unit% %CanBeSpecifiedInDocuments% ağırlığında'");
				FillString = StrReplace(FillString, "%Count1%", Object.WeightDenominator);
				FillString = StrReplace(FillString, "%Count2%", Object.WeightNumerator);
				FillString = StrReplace(FillString, "%UnitOfMeasure%", Object.UnitOfMeasure);
				FillString = StrReplace(FillString, "%Unit%", Object.WeightUnitOfMeasure);				
				If Object.YouCanSpecifyWeightInDocuments Then
					FillString = StrReplace(FillString, "%CanBeSpecifiedInDocuments%", NStr("vi = 'có thể chỉ định số lượng tính theo %UnitOfMeasure% trong chứng từ';
																							|ru = 'можно указывать количество в %UnitOfMeasure% в документах';
																							|en = 'you can specify quantity in %UnitOfMeasure% in the documents'; fa = 'you can specify quantity in %UnitOfMeasure% in the documents';
																							|it = 'è possibile indicare quantità in %UnitOfMeasure% nei documenti';
																							|pl = 'można określać ilość w %UnitOfMeasure% w dokumentach';
																							|tr = 'Belgelerde miktar %UnitOfMeasure% olarak belirtilebilir'"));
					FillString = StrReplace(FillString, "%UnitOfMeasure%", Object.WeightUnitOfMeasure);
				Else
					FillString = StrReplace(FillString, "%CanBeSpecifiedInDocuments%", NStr("vi = 'chỉ định để tham khảo';
																							|ru = 'указан справочно';
																							|en = 'specified for reference'; fa = 'specified for reference';
																							|it = 'indicato per informazione';
																							|pl = 'określono informacyjnie';
																							|tr = 'referans olarak belirtildi'"));
				EndIf;
			Else
				FillString = NStr("vi = '<không được đo>';
									|ru = '<не измеряется>';
									|en = '<not measured>'; fa = '<not measured>';
									|it = '<non conteggiato>';
									|pl = '<nie jest mierzone>';
									|tr = '<ölçülmüyor>'");
			EndIf;
			
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "Weight";
			PartitionOutputParameters.AreaNameString = "WeightString";
			PartitionOutputParameters.NameOfPropsParameter = "WeightProps";
			PartitionOutputParameters.TextOfPropsValue = FillString;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
			
		EndIf;

		
		If SectionIsVisible("VolumeM3", VisibilityStructure) Then
			
			If Object.VolumeUse Then
				FillString = NStr("vi = '%Count1% %UnitOfMeasure% chiếm %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|ru = '%Count1% %UnitOfMeasure% занимает объем %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|en = '%Count1% %UnitOfMeasure% of volume %Count2% %Unit%, %CanBeSpecifiedInDocuments%'; fa = '%Count1% %UnitOfMeasure% of volume %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|it = '%Count1% %UnitOfMeasure% occupa spazio di %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|pl = '%Count1% %UnitOfMeasure% zajmuje objętość %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|tr = '%Count1% %UnitOfMeasure% %Count2% %Unit% %CanBeSpecifiedInDocuments% hacmi kapsıyor'");
				FillString = StrReplace(FillString, "%Count1%", Object.VolumeDenominator);
				FillString = StrReplace(FillString, "%Count2%", Object.VolumeNumerator);
				FillString = StrReplace(FillString, "%UnitOfMeasure%", Object.UnitOfMeasure);
				FillString = StrReplace(FillString, "%Unit%", Object.VolumeUnitOfMeasure);				
				If Object.VolumeCanBeSpecifiedInDocuments Then
					FillString = StrReplace(FillString, "%CanBeSpecifiedInDocuments%", NStr("vi = 'có thể chỉ định số lượng tính theo %UnitOfMeasure% trong chứng từ';
																							|ru = 'можно указывать количество в %UnitOfMeasure% в документах';
																							|en = 'you can specify quantity in %UnitOfMeasure% in the documents'; fa = 'you can specify quantity in %UnitOfMeasure% in the documents';
																							|it = 'è possibile indicare quantità in %UnitOfMeasure% nei documenti';
																							|pl = 'można określać ilość w %UnitOfMeasure% w dokumentach';
																							|tr = 'Belgelerde miktar %UnitOfMeasure% olarak belirtilebilir'"));
					FillString = StrReplace(FillString, "%UnitOfMeasure%", Object.VolumeUnitOfMeasure);
				Else
					FillString = StrReplace(FillString, "%CanBeSpecifiedInDocuments%", NStr("vi = 'chỉ định để tham khảo';
																							|ru = 'указан справочно';
																							|en = 'specified for reference'; fa = 'specified for reference';
																							|it = 'indicato per informazione';
																							|pl = 'określono informacyjnie';
																							|tr = 'referans olarak belirtildi'"));
				EndIf;
			Else
				FillString = NStr("vi = '<không được đo>';
									|ru = '<не измеряется>';
									|en = '<not measured>'; fa = '<not measured>';
									|it = '<non conteggiato>';
									|pl = '<nie jest mierzone>';
									|tr = '<ölçülmüyor>'");
			EndIf;
			
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "VolumeM3";
			PartitionOutputParameters.AreaNameString = "VolumeString";
			PartitionOutputParameters.NameOfPropsParameter = "VolumeProps";
			PartitionOutputParameters.TextOfPropsValue = FillString;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
			
		EndIf;

		
		If SectionIsVisible("Length", VisibilityStructure) Then
			
			If Object.LengthUse Then
				FillString = NStr("vi = '%Count1% %UnitOfMeasure% chiều dài %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|ru = '%Count1% %UnitOfMeasure% имеет длину %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|en = '%Count1% %UnitOfMeasure% of length %Count2% %Unit%, %CanBeSpecifiedInDocuments%'; fa = '%Count1% %UnitOfMeasure% of length %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|it = '%Count1% %UnitOfMeasure% ha lunghezza di %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|pl = '%Count1% %UnitOfMeasure% ma długość %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|tr = '%Count1% %UnitOfMeasure% %Count2% %Unit% %CanBeSpecifiedInDocuments% uzunluğu mevcut'");
				FillString = StrReplace(FillString, "%Count1%", Object.LengthDenominator);
				FillString = StrReplace(FillString, "%Count2%", Object.LengthNumerator);
				FillString = StrReplace(FillString, "%UnitOfMeasure%", Object.UnitOfMeasure);
				FillString = StrReplace(FillString, "%Unit%", Object.LengthUnitOfMeasure);				
				If Object.YouCanSpecifyLengthInDocuments Then
					FillString = StrReplace(FillString, "%CanBeSpecifiedInDocuments%", NStr("vi = 'có thể chỉ định số lượng tính theo %UnitOfMeasure% trong chứng từ';
																							|ru = 'можно указывать количество в %UnitOfMeasure% в документах';
																							|en = 'you can specify quantity in %UnitOfMeasure% in the documents'; fa = 'you can specify quantity in %UnitOfMeasure% in the documents';
																							|it = 'è possibile indicare quantità in %UnitOfMeasure% nei documenti';
																							|pl = 'można określać ilość w %UnitOfMeasure% w dokumentach';
																							|tr = 'Belgelerde miktar %UnitOfMeasure% olarak belirtilebilir'"));
					FillString = StrReplace(FillString, "%UnitOfMeasure%", Object.LengthUnitOfMeasure);
				Else
					FillString = StrReplace(FillString, "%CanBeSpecifiedInDocuments%", NStr("vi = 'chỉ định để tham khảo';
																							|ru = 'указана справочно';
																							|en = 'line specified for reference'; fa = 'line specified for reference';
																							|it = 'indicata per informazione';
																							|pl = 'określono informacyjnie';
																							|tr = 'referans olarak belirtildi'"));
				EndIf;
			Else
				FillString = NStr("vi = '<không được đo>';
									|ru = '<не измеряется>';
									|en = '<not measured>'; fa = '<not measured>';
									|it = '<non conteggiato>';
									|pl = '<nie jest mierzone>';
									|tr = '<ölçülmüyor>'");
			EndIf;
			
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "Length";
			PartitionOutputParameters.AreaNameString = "LengthString";
			PartitionOutputParameters.NameOfPropsParameter = "LengthProps";
			PartitionOutputParameters.TextOfPropsValue = FillString;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
			
		EndIf;
		
		If SectionIsVisible("AreaTypeOfMeasurement", VisibilityStructure) Then
			
			If Object.AreaUse Then
				FillString = NStr("vi = '%Count1% %UnitOfMeasure% có diện tích %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|ru = '%Count1% %UnitOfMeasure% имеет площадь %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|en = '%Count1% %UnitOfMeasure% of size %Count2% %Unit%, %CanBeSpecifiedInDocuments%'; fa = '%Count1% %UnitOfMeasure% of size %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|it = '%Count1% %UnitOfMeasure% ha spazio di %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|pl = '%Count1% %UnitOfMeasure% ma powierzchnię %Count2% %Unit%, %CanBeSpecifiedInDocuments%';
									|tr = '%Count1% %UnitOfMeasure% %Count2% %Unit% %CanBeSpecifiedInDocuments% alanı mevcut'");
				FillString = StrReplace(FillString, "%Count1%", Object.AreaDenominator);
				FillString = StrReplace(FillString, "%Count2%", Object.AreaNumerator);
				FillString = StrReplace(FillString, "%UnitOfMeasure%", Object.UnitOfMeasure);
				FillString = StrReplace(FillString, "%Unit%", Object.AreaUnitOfMeasure);				
				If Object.AreaCanBeSpecifiedInDocuments Then
					FillString = StrReplace(FillString, "%CanBeSpecifiedInDocuments%", NStr("vi = 'có thể chỉ định số lượng tính theo %UnitOfMeasure% trong chứng từ';
																							|ru = 'можно указывать количество в %UnitOfMeasure% в документах';
																							|en = 'you can specify quantity in %UnitOfMeasure% in the documents'; fa = 'you can specify quantity in %UnitOfMeasure% in the documents';
																							|it = 'è possibile indicare quantità in %UnitOfMeasure% nei documenti';
																							|pl = 'można określać ilość w %UnitOfMeasure% w dokumentach';
																							|tr = 'Belgelerde miktar %UnitOfMeasure% olarak belirtilebilir'"));
					FillString = StrReplace(FillString, "%UnitOfMeasure%", Object.AreaUnitOfMeasure);
				Else
					FillString = StrReplace(FillString, "%CanBeSpecifiedInDocuments%", NStr("vi = 'chỉ định để tham khảo';
																							|ru = 'указана справочно';
																							|en = 'line specified for reference'; fa = 'line specified for reference';
																							|it = 'indicata per informazione';
																							|pl = 'określono informacyjnie';
																							|tr = 'referans olarak belirtildi'"));
				EndIf;
			Else
				FillString = NStr("vi = '<không được đo>';
									|ru = '<не измеряется>';
									|en = '<not measured>'; fa = '<not measured>';
									|it = '<non conteggiato>';
									|pl = '<nie jest mierzone>';
									|tr = '<ölçülmüyor>'");
			EndIf;
			
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "AreaTypeOfMeasurement";
			PartitionOutputParameters.AreaNameString = "SquareRow";
			PartitionOutputParameters.NameOfPropsParameter = "SquareProps";
			PartitionOutputParameters.TextOfPropsValue = FillString;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("WarehouseGroup", VisibilityStructure) Then 
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "WarehouseGroup";
			PartitionOutputParameters.AreaNameString = "WarehouseGroupLine";
			PartitionOutputParameters.NameOfPropsParameter = "WarehouseGroupProps";
			PartitionOutputParameters.TextOfPropsValue = Object.WarehouseGroup;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoToItemPlacement", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkGoProductPlacementLine");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoToItemPlacement";
			EndIf;
			TabularDocumentRight.Put(Area);
		EndIf;
		
		If SectionIsVisible("ExpirationDate_", VisibilityStructure) Then
			FillString = NStr("vi = '%ExpirationDate_% %ShelfLifeUnitOfMeasure%';
								|ru = '%ExpirationDate_% %ShelfLifeUnitOfMeasure%';
								|en = '%ExpirationDate_% %ShelfLifeUnitOfMeasure%'; fa = '%ExpirationDate_% %ShelfLifeUnitOfMeasure%';
								|it = '%ExpirationDate_%%ShelfLifeUnitOfMeasure%';
								|pl = '%ExpirationDate_% %ShelfLifeUnitOfMeasure%';
								|tr = '%ExpirationDate_% %ShelfLifeUnitOfMeasure%'");
			FillString = StrReplace(FillString, "%ExpirationDate_%", Object.ExpirationDate_);
			FillString = StrReplace(FillString, "%ShelfLifeUnitOfMeasure%", Object.ShelfLifeUnitOfMeasure);
			
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "ExpirationDate_";
			PartitionOutputParameters.AreaNameString = "ExpirationDateString";
			PartitionOutputParameters.NameOfPropsParameter = "ExpirationDateProps";
			PartitionOutputParameters.TextOfPropsValue = FillString;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region AccountingFinancial
	
	If ChapterVisible("AccountingFinancial", VisibilityStructure) Then 
		
		HeaderArea_ = Template.GetArea("FinancialAccountingHeading");
		TabularDocumentRight.Put(HeaderArea_);
		
		If SectionIsVisible("AnalyticalGroup", VisibilityStructure) Then 
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "AnalyticalGroup";
			PartitionOutputParameters.AreaNameString = "AnalyticalAccountingGroupRow";
			PartitionOutputParameters.NameOfPropsParameter = "AnalyticalAccountingGroupProps";
			PartitionOutputParameters.TextOfPropsValue = Object.AnalyticalGroup;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);	 
		EndIf;
		
		If SectionIsVisible("FinancialAccountingGroup", VisibilityStructure) Then
			PartitionOutputParameters = SectionOutputParametersBasedOnSizeOfValues();
			PartitionOutputParameters.SectionName = "FinancialAccountingGroup";
			PartitionOutputParameters.AreaNameString = "FinancialAccountingGroupLine";
			PartitionOutputParameters.NameOfPropsParameter = "FinancialAccountingGroupDetails";
			PartitionOutputParameters.TextOfPropsValue = Object.FinancialAccountingGroup;
			OutputSectionTakingIntoAccountSizeOfValues(TabularDocumentRight, Template, ForPrint, PartitionOutputParameters);
		EndIf;
		
		If SectionIsVisible("HyperlinkGoDistributionOfSalesByLineOfBusiness", VisibilityStructure) Then
			Area = Template.GetArea("HyperlinkGoDistributionOfSalesByLineOfActivity");
			If Not ForPrint Then
				Area.Parameters.Details = "HyperlinkGoDistributionOfSalesByLineOfBusiness";
			EndIf;
			TabularDocumentRight.Put(Area);
		EndIf;
			
	EndIf;
	
	#EndRegion
	
	ProductsLocalization.OutputChapters(TabularDocumentRight, Object, VisibilityAndHeaderSettings, ForPrint);
	
	ColumnTabularDocument.Join(TabularDocumentRight);
	
	#EndRegion
	
	TableDocumentCard.Put(ColumnTabularDocument);
	
	Return TableDocumentCard;
	
EndFunction

Function ValueTextIsNotFilledIn(SectionName)

	If SectionName = "Description" Then
		Return NStr("vi = '<chưa chỉ ra>';
					|ru = '<не указано>';
					|en = '<none>'; fa = '<هیچ>';
					|it = '<non indicato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "DescriptionFull" Then
		Return NStr("vi = '<chưa chỉ ra>';
					|ru = '<не указано>';
					|en = '<none>'; fa = '<هیچ>';
					|it = '<non indicato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "SKU" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "Code" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "LongDesc" Then
		Return NStr("vi = '<chưa chỉ ra>';
					|ru = '<не указано>';
					|en = '<none>'; fa = '<هیچ>';
					|it = '<non indicato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "DescriptionFileForWebsite" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "AdditionalAttributes" Then
		Return NStr("vi = '<chưa đặt giá trị>';
					|ru = '<значение не задано>';
					|en = '<value is not set>'; fa = '<value is not set>';
					|it = '<valore non impostato>';
					|pl = '<nie określono wartości>';
					|tr = '<değer ayarlanmadı>'");
	ElsIf SectionName = "Manufacturer" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "OriginCountry" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "Brand" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "Counterparty" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "Principal" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "ProductCategory" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "ItemsCollection" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "ItemsGroup" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "SalesRank" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "ProcurementStrategy" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "SupplyScheme" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "TermOfQualityControl" Then
		Return NStr("vi = '0';
					|ru = '0';
					|en = '0'; fa = '0';
					|it = '0';
					|pl = '0';
					|tr = '0'");
	ElsIf SectionName = "PriceGroup" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "Parent" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "AccessGroup" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "WarehouseGroup" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "AnalyticalGroup" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "FinancialAccountingGroup" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указана>';
					|en = '<line not specified>'; fa = '<line not specified>';
					|it = '<non indicata>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	ElsIf SectionName = "FEACNCode" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<nie określono>';
					|tr = '<belirtilmedi>'");
	Else
		Return ProductsLocalization.ValueTextIsNotFilledIn(SectionName);
	EndIf;
	
EndFunction

// Parameters for the output of the section, taking into account the size of the values.
// 
// Returns:
//  Structure - Section Output Parameters Based On The Size Of The Values:
// * SectionName - String -
// * AreaNameString - String -
// * NameOfPropsParameter - String -
// * TextOfPropsValue - 
// * PropsHeaderText -
// * NewPartitionName -
Function SectionOutputParametersBasedOnSizeOfValues() Export
	
	PartitionOutputParameters = New Structure;
	PartitionOutputParameters.Insert("SectionName", "");
	PartitionOutputParameters.Insert("AreaNameString", "");
	PartitionOutputParameters.Insert("NameOfPropsParameter", "");
	PartitionOutputParameters.Insert("TextOfPropsValue");
	PartitionOutputParameters.Insert("PropsHeaderText");
	PartitionOutputParameters.Insert("NewPartitionName");
	
	Return PartitionOutputParameters;
	
EndFunction

// Output a section based on the size of the values.
// 
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - Table document
//  Template - SpreadsheetDocument - Template
//  ForPrint - Boolean - For printing
//  OutputParameters - See SectionOutputParametersBasedOnSizeOfValues
Procedure OutputSectionTakingIntoAccountSizeOfValues(SpreadsheetDocument, Template, ForPrint, OutputParameters) Export
	
	AreaRow = Template.GetArea(OutputParameters.AreaNameString);
		
	If OutputParameters.PropsHeaderText <> Undefined Then
		AreaRow.Parameters[OutputParameters.NameOfPropsParameter] = String(OutputParameters.PropsHeaderText) + ":";
	EndIf;
	
	If ValueIsFilled(OutputParameters.TextOfPropsValue) Then 
		AreaRow.Parameters[OutputParameters.SectionName] = OutputParameters.TextOfPropsValue;
	Else
		AreaRow.Parameters[OutputParameters.SectionName] = ValueTextIsNotFilledIn(OutputParameters.SectionName);
	EndIf;
	
	If Not ForPrint Then
		If OutputParameters.NewPartitionName = Undefined Then 
			AreaRow.Parameters.Details = OutputParameters.SectionName;
		Else
			AreaRow.Parameters.Details = OutputParameters.NewPartitionName;
		EndIf;
	EndIf;
	
	SpreadsheetDocument.Put(AreaRow);
	
	NumberOfAdditionalRows_ = 0;
	
	NumberOfAdditionalRows_ = NumberOfAdditionalRows_(
			SpreadsheetDocument,
			OutputParameters.SectionName,
			OutputParameters.TextOfPropsValue,
			OutputParameters.PropsHeaderText);
	
	Counter = NumberOfAdditionalRows_;
	
	ScopeOfAdmission_ = Template.GetArea(GetNameOfCommandLineAreaBySectionName(OutputParameters.SectionName));
	
	While Counter > 0 Do
		Counter = Counter - 1;
		SpreadsheetDocument.Put(ScopeOfAdmission_);
	EndDo;
	
	MergeSectionWithLinesBelow(SpreadsheetDocument, OutputParameters.AreaNameString, NumberOfAdditionalRows_);
	
EndProcedure

Procedure MergeSectionWithLinesBelow(SpreadsheetDocument, AreaName, NumberOfAdditionalRows)
	
	If NumberOfAdditionalRows = 0 Then
		Return;
	EndIf;
	
	Area = SpreadsheetDocument.Area(AreaName);
	Area.UndoMerge();
	Area.Name = Undefined;
	AddressOfRegion = Area.Name;
	AddressStructure1 = AddressStructure1(AddressOfRegion);
	
	AddressOfStartHeaderColumn = AddressStructure1.AddressOfStartColumn + 1; // + 1, because the column on the left is indented
	AddressOfEndHeaderColumn = AddressOfStartHeaderColumn + 7; // +7, because the header occupies 8 columns
	AddressOfStartValueColumn = AddressOfEndHeaderColumn + 1;
	
	// In the left column of the card, the difference should be 20, in the right - 21
	If AddressStructure1.AddressOfEndColumn - AddressStructure1.AddressOfStartColumn = 20 Then
		AddressOfEndValueColumn = AddressStructure1.AddressOfEndColumn;
	ElsIf AddressStructure1.AddressOfEndColumn - AddressStructure1.AddressOfStartColumn = 21 Then
		AddressOfEndValueColumn = AddressStructure1.AddressOfEndColumn - 1;
	EndIf;
	
	AddressOfStartLine = AddressStructure1.AddressOfStartLine;
	AddressOfEndLine = AddressStructure1.AddressOfEndLine;
	
	// For the header
	NewAddress = "R" + AddressOfStartLine + "C" + AddressOfStartHeaderColumn + ":"
				+ "R" + (AddressOfEndLine + NumberOfAdditionalRows) + "C" + AddressOfEndHeaderColumn;
	Area = SpreadsheetDocument.Area(NewAddress);
	Area.Merge();
	
	// For the value
	NewAddress = "R" + AddressOfStartLine + "C" + AddressOfStartValueColumn + ":"
				+ "R" + (AddressOfEndLine + NumberOfAdditionalRows) + "C" + AddressOfEndValueColumn;
	Area = SpreadsheetDocument.Area(NewAddress);
	Area.Merge();
	
EndProcedure

Function AddressStructure1(Address)
	
	ArrayAreaAddress = StrSplit(Address, ":");
	If ArrayAreaAddress.Count() <> 2 Then
		// This means that the row consists of one column, the procedure for combining with such does not work.
		Return Undefined;
	EndIf;
	
	AddressStart = ArrayAreaAddress[0];
	ArrayAddressStart = StrSplit(AddressStart, "C");
	AddressOfStartLine = StrReplace(ArrayAddressStart[0], "R", "");
	AddressOfStartColumn = ArrayAddressStart[1];
	
	AddressEnd = ArrayAreaAddress[1];
	ArrayAddressEnd = StrSplit(AddressEnd, "C");
	AddressOfEndLine = StrReplace(ArrayAddressEnd[0], "R", "");
	AddressOfEndColumn = ArrayAddressEnd[1];

	AddressStructure1 = New Structure;
	AddressStructure1.Insert("AddressOfStartLine", 	Number(AddressOfStartLine));
	AddressStructure1.Insert("AddressOfStartColumn", 	Number(AddressOfStartColumn));
	AddressStructure1.Insert("AddressOfEndLine", 	Number(AddressOfEndLine));
	AddressStructure1.Insert("AddressOfEndColumn", 	Number(AddressOfEndColumn));
	
	Return AddressStructure1;
	
EndFunction

Function GetNameOfCommandLineAreaBySectionName(SectionName)
	
	If SectionName = "AdditionalAttributes"
		Or SectionName = "LongDesc"
		Or SectionName = "Manufacturer"
		Or SectionName = "ManufacturerImporterConterparty"
		Or SectionName = "OriginCountry"
		Or SectionName = "Brand"
		Or SectionName = "Principal"
		Or SectionName = "Counterparty"
		Or SectionName = "DescriptionFileForWebsite"
		Or SectionName = "KeepRecordsOfQualityCertificates"
		Or SectionName = "ProductCategory"
		Or SectionName = "ItemsCollection"
		Or SectionName = "ItemsGroup"
		Or SectionName = "SalesRank"
		Or SectionName = "HyperlinkGoToSegments"
		Or SectionName = "HyperlinkGoToJointSales"
		Or SectionName = "AssignedPurchaseSale"
		Or SectionName = "ProcurementStrategy"
		Or SectionName = "SupplyScheme"
		Or SectionName = "HyperlinkGoConfigurationOptions"
		Or SectionName = "HyperlinkGoToInventoryMaintenanceSettings"
		Or SectionName = "HyperlinkGoSettingUpWaysToMeetYourNeeds"
		Or SectionName = "HyperlinkGoToProduction" 
		Or SectionName = "ControlQualityOfReceivedGoods"
		Or SectionName = "TermOfQualityControl"
		Or SectionName = "PriceGroup"
		Or SectionName = "HyperlinkGoToCompanyPriceList"
		Or SectionName = "HyperlinkGoToSupplierPriceLists"
		Or SectionName = "LabelsTemplate"
		Or SectionName = "PriceTagTemplate"
		Or SectionName = "AnalyticalGroup"
		Or SectionName = "FinancialAccountingGroup" Then
		Return "ExtraLineLeft";
	Else
		Return "DopingLaw";
	EndIf;
	
EndFunction

Function NumberOfAdditionalRows_(SpreadsheetDocument, SectionName, TextToFillInValue, TextOfFillingInDetails)
	
	ColumnWidth = 2.38;
	NumberOfColumnsInPropsValue = 12;
	WidthOfPropsValue = NumberOfColumnsInPropsValue * ColumnWidth;
	NumberOfRowsOfValue = RowsCount(WidthOfPropsValue, TextToFillInValue);
	
	NumberOfRowsOfProperty = 0;
	If ValueIsFilled(TextOfFillingInDetails) Then
		NumberOfColumnsInPropsHeader = 8;
		WidthOfPropsHeader = ColumnWidth * NumberOfColumnsInPropsHeader;
		NumberOfRowsOfProperty = RowsCount(WidthOfPropsHeader, TextOfFillingInDetails);
	EndIf;
	
	CountOfRows = Max(NumberOfRowsOfValue, NumberOfRowsOfProperty);
	
	If CountOfRows = 0 Then
		Return 0;
	EndIf;
	
	Return CountOfRows - 1;
	
EndFunction

Function RowsCount(AreaWidth, String)
	
	If Not ValueIsFilled(String) Then
		Return 0;
	EndIf;
	
	AverageCharacterWidth = 0.75;
	
	WordArray = StrSplit(String, " ");
		
	RowsCount = 1; // = 1, because we did the check for fullness above, which means one line is needed exactly
	CurrentRow = "";
	
	For Each Word In WordArray Do
		
		CurrentRow = CurrentRow + Word + " ";
		If StrLen(CurrentRow) * AverageCharacterWidth > AreaWidth Then
			RowsCount = RowsCount + 1;
			CurrentRow = Word + " ";
		EndIf;
		
	EndDo;	 
	 	 
	Return RowsCount;
	
EndFunction

Function ImageOfFlagByValue(FlagValue1) Export
	
	If FlagValue1 Then
		Return PictureLib.FlagSpecified;
	Else
		Return PictureLib.FlagNotSpecified;
	EndIf;
	
EndFunction

Function SectionIsVisible(SectionName, VisibilityStructure) Export
	
	Visible = True;
	If VisibilityStructure.Property(SectionName) Then
		Visible = VisibilityStructure[SectionName];
	EndIf;
	
	Return Visible;
	
EndFunction

Function ChapterVisible(ChapterName, VisibilityStructure, NumberOfAdditionalBankingDetails = 0)
	
	If ChapterName = "LongDesc" Then 
		Return True;
	EndIf;
	
	If ChapterName = "AdditionalAttributes" Then
		Return NumberOfAdditionalBankingDetails > 0 And GetFunctionalOption("UseAdditionalAttributesAndInfo");		
	EndIf;
	
	If ChapterName = "ManufacturerDetails" Then
		Return SectionIsVisible("Manufacturer", VisibilityStructure) 
					Or SectionIsVisible("Brand", VisibilityStructure) 
					Or SectionIsVisible("ManufacturerImporterConterparty", VisibilityStructure)
					Or SectionIsVisible("Principal", VisibilityStructure)
					Or SectionIsVisible("Counterparty", VisibilityStructure)		
					Or SectionIsVisible("HyperlinkGoToAgreements", VisibilityStructure);		
	EndIf;
				
	If ChapterName = "PlanningAndMarketing" Then
		Return SectionIsVisible("ProductCategory", VisibilityStructure)
					Or SectionIsVisible("ItemsCollection", VisibilityStructure)
					Or SectionIsVisible("ItemsGroup", VisibilityStructure)
					Or SectionIsVisible("SalesRank", VisibilityStructure)
					Or SectionIsVisible("HyperlinkGoToSegments", VisibilityStructure)
					Or SectionIsVisible("HyperlinkGoToJointSales", VisibilityStructure);
	EndIf;
				
	If ChapterName = "SupplyAndProduction" Then
		Return SectionIsVisible("AssignedPurchaseSale", VisibilityStructure)
					Or SectionIsVisible("ProcurementStrategy", VisibilityStructure)
					Or SectionIsVisible("SupplyScheme", VisibilityStructure)
					Or SectionIsVisible("HyperlinkGoConfigurationOptions", VisibilityStructure)
					Or SectionIsVisible("HyperlinkGoToInventoryMaintenanceSettings", VisibilityStructure)
					Or SectionIsVisible("HyperlinkGoSettingUpWaysToMeetYourNeeds", VisibilityStructure)
					Or SectionIsVisible("HyperlinkGoSettingUpTheTransferOfMaterialsToProduction", VisibilityStructure)
					Or SectionIsVisible("HyperlinkGoToProduction", VisibilityStructure);
	EndIf;
	
	If ChapterName = "QualityControl" Then
		Return SectionIsVisible("ControlQualityOfReceivedGoods", VisibilityStructure)
					Or SectionIsVisible("TermOfQualityControl", VisibilityStructure);
	EndIf;
	
	If ChapterName = "Prices" Then
		Return SectionIsVisible("PriceGroup", VisibilityStructure)
					Or SectionIsVisible("HyperlinkGoToCompanyPriceList", VisibilityStructure)
					Or SectionIsVisible("HyperlinkGoToSupplierPriceLists", VisibilityStructure);
	EndIf;
				
	If ChapterName = "PrintPriceTagsAndLabels" Then
		Return SectionIsVisible("LabelsTemplate", VisibilityStructure)
				Or SectionIsVisible("PriceTagTemplate", VisibilityStructure);
	EndIf;
	
	If ChapterName = "MainAccountingParameters" Then
		Return True;
	EndIf;
	
	If ChapterName = "UnitsAndStorageArea" Then
		Return True;
	EndIf;
	
	If ChapterName = "AccountingFinancial" Then
		Return SectionIsVisible("AnalyticalGroup", VisibilityStructure)
					Or SectionIsVisible("FinancialAccountingGroup", VisibilityStructure)
					Or SectionIsVisible("HyperlinkGoDistributionOfSalesByLineOfBusiness", VisibilityStructure);
	EndIf;
		
	Return False;
	
EndFunction

Function RightOfAccessToMetadataObjectByDetails(Right, PropsMetadataObject) Export

	If Users.IsFullUser() Then
		Return True;
	EndIf;
	
	ArrayOfTypesToCheck = PropsMetadataObject.Type.Types();
	For Each Type In ArrayOfTypesToCheck Do
		
		If TMCommonUse.IsPrimitiveType(Type) Then
			Continue;
		EndIf;
		
		MetadataObject = Metadata.FindByType(Type);
		If MetadataObject <> Undefined
			And Not AccessRight(Right, MetadataObject) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
EndFunction

// Returns a sign that the Attribute is visible.
//
// Parameters:
//	Attribute - String, ValueTableRow - description of the Attribute.
//	AttributeName - String - name of the prop.
//	VisibilityModeShowHighPriorityOnly - Boolean - indicates the display mode for important Attributes.
//	SettingString - ValueTableRow - description of Attribute settings.
//
// Returns:
//	Boolean - indicates whether the Attribute is visible.
//
Function VisibilityOfProps(Attribute, AttributeName, VisibilityModeShowHighPriorityOnly, SettingString) Export
	
	If Not TypeOf(Attribute) = Type("String") Then
		Return RightOfAccessToMetadataObjectByDetails("View", Attribute)
				And (Not VisibilityModeShowHighPriorityOnly
					Or SettingString.DisplayWhenCreated)
	Else
		Return AccessRight("View", Metadata.Catalogs.Products.Attributes[AttributeName])
				And RightOfAccessToMetadataObjectByDetails("View", Metadata.Catalogs.Products.Attributes[AttributeName])
				And (Not VisibilityModeShowHighPriorityOnly
					Or SettingString.DisplayWhenCreated)
	EndIf;
	
EndFunction

Function VisibilityOfAdditionalAttributes(Object, PropertyDetails, AddAttributes, VisibilityConditionsForAttributes)
	
	Visible = True;
	
	DependencyConditions	= Undefined;
	AttributesValues	= New Structure;
	
	RowFilter = New Structure("Property", PropertyDetails.Property);
	DependenciesStrings = VisibilityConditionsForAttributes.FindRows(RowFilter);
	
	For Each DependencyString In DependenciesStrings Do
		If TypeOf(DependencyString.Attribute) = Type("String") Then
			AttributePath1 = "Parameters.ObjectDetails." + DependencyString.Attribute;
		Else
			AdAttributesData = AddAttributes.Find(DependencyString.Attribute, "Property");
			
			If AdAttributesData = Undefined Then
				Continue; // Additional props do not exist, the condition is ignored.
			EndIf;
			
			AttributePath1 = "Parameters.Form." + AdAttributesData.AttributeName;
			
			AttributesValues.Insert(AdAttributesData.AttributeName, AdAttributesData.Value);
		EndIf;
		
		FillInDependencyConditions(DependencyConditions, DependencyString, AttributePath1);
	EndDo;
	
	If DependencyConditions <> Undefined Then
		Parameters = New Structure;
		Parameters.Insert("Form",					AttributesValues);
		Parameters.Insert("ParameterValues",	DependencyConditions.ParameterValues);
		Parameters.Insert("ObjectDetails",		Object);
		
		Try
			Visible = Common.CalculateInSafeMode(DependencyConditions.ConditionCode, Parameters);
		Except
			Visible = True;
			
			EventName = NStr("vi = 'Tạo thẻ mặt hàng ""%1"".
								|Không thể tính toán điều kiện hiển thị mục tin bổ sung ""%2""';
								|ru = 'Формирование карточки номеклатуры ""%1"".
								|Не удалось вычислить условие видимости дополнительного реквизита ""%2""';
								|en = 'Generate the %1 item card.
								|Cannot calculate the visibility condition of the %2 additional attribute'; fa = 'Generate the %1 item card.
								|Cannot calculate the visibility condition of the %2 additional attribute';
								|it = 'Формирование карточки номеклатуры ""%1"".
								|Не удалось вычислить условие видимости дополнительного реквизита ""%2""';
								|pl = 'Generate the %1 item card.
								|Cannot calculate the visibility condition of the %2 additional attribute';
								|tr = 'Öğe kartı oluşturma ""%1"".
								| ""%2"" ek özniteliği için görünürlük koşulu hesaplanamadı'",
								Common.DefaultLanguageCode());
			EventName = StrTemplate(EventName, String(Object.Ref), PropertyDetails.AttributeRepresentation);
			
			WriteLogEvent(EventName,
									EventLogLevel.Error,
									Metadata.Catalogs.Products,
									Object.Ref,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	Return Visible;
	
EndFunction

Procedure FillInDependencyConditions(DependencyConditions, AdAttributesData, AttributePath1)
	
	// Converting an old condition for backward compatibility.
	NewCondition	= "";
	ConditionByParts	= StrSplit(AdAttributesData.Condition, " ");
	
	If ConditionByParts.Count() > 0 Then
		For Each ConditionPart In ConditionByParts Do
			NewCondition = NewCondition + Upper(Left(ConditionPart, 1)) + Mid(ConditionPart, 2);
		EndDo;
	EndIf;
	
	If ValueIsFilled(NewCondition) Then
		AdAttributesData.Condition = NewCondition;
	EndIf;
	
	ConditionTemplate = "";
	
	If AdAttributesData.Condition = "Equal" Then
		ConditionTemplate = "%1 = %2";
	ElsIf AdAttributesData.Condition = "NotEqual" Then
		ConditionTemplate = "%1 <> %2";
	EndIf;
	
	If AdAttributesData.Condition = "InList" Then
		ConditionTemplate = "%2.FindByValue(%1) <> Undefined";
	ElsIf AdAttributesData.Condition = "NotInList" Then
		ConditionTemplate = "%2.FindByValue(%1) = Undefined";
	EndIf;
	
	RightValue = "";
	
	If ValueIsFilled(ConditionTemplate) Then
		RightValue = "Parameters.ParameterValues[""%1""]";
		RightValue = StrTemplate(RightValue, AttributePath1);
	EndIf;
	
	If AdAttributesData.Condition = "Filled" Then
		ConditionTemplate = "ValueIsFilled(%1)";
	ElsIf AdAttributesData.Condition = "NotFilled" Then
		ConditionTemplate = "Not ValueIsFilled(%1)";
	EndIf;
	
	If ValueIsFilled(RightValue) Then
		ConditionCode = StringFunctionsClientServer.SubstituteParametersToString(ConditionTemplate,
																			AttributePath1,
																			RightValue);
	Else
		ConditionCode = StringFunctionsClientServer.SubstituteParametersToString(ConditionTemplate, AttributePath1);
	EndIf;
	
	SetDependenceCondition(DependencyConditions, AdAttributesData, AttributePath1, ConditionCode);
	
EndProcedure

Procedure SetDependenceCondition(DependencyConditions, AdAttributesData, AttributePath1, ConditionCode)
	
	Condition = AdAttributesData.Condition;
	
	If DependencyConditions = Undefined Then
		
		ParameterValues = New Map;
		
		If Condition = "InList"
			Or Condition = "NotInList" Then
			
			Value = New ValueList;
			Value.Add(AdAttributesData.Value);
			
		Else
			Value = AdAttributesData.Value;
		EndIf;
		
		ParameterValues.Insert(AttributePath1, Value);
		
		DependencyConditions = New Structure;
		DependencyConditions.Insert("ConditionCode",			ConditionCode);
		DependencyConditions.Insert("ParameterValues",	ParameterValues);
		
	ElsIf (Condition = "InList"
			Or Condition = "NotInList")
		And TypeOf(DependencyConditions.ParameterValues[AttributePath1]) = Type("ValueList") Then
		
		AttributeValues = DependencyConditions.ParameterValues[AttributePath1]; // ValueList
		AttributeValues.Add(AdAttributesData.Value);
		
	Else
		DependencyConditions.ConditionCode = DependencyConditions.ConditionCode + " And " + ConditionCode;
		
		If Condition = "InList"
			Or Condition = "NotInList" Then
			
			Value = New ValueList;
			Value.Add(AdAttributesData.Value);
			
		Else
			Value = AdAttributesData.Value;
		EndIf;
		
		DependencyConditions.ParameterValues.Insert(AttributePath1, Value);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region CreateBasedOnSubmenu

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

#EndRegion

#Region ReportsSubmenu

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.StockAvailability.AddReportCommand(ReportsCommands);//ValueTableRow
	If ReportCommand <> Undefined Then
		ReportCommand.Importance = "Important";
		ReportCommand.WriteMode = "";
	EndIf;
	
	ReportCommand = Reports.GoodsInStorageBins.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Importance = "Important";
		ReportCommand.WriteMode = "";
	EndIf;
	
	ReportCommand = Reports.ABCXYZAnalysisOfInventory.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
		ReportCommand.WriteMode = "";
	EndIf;
	
	ReportCommand = Reports.CompanyGoodsStock.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 2;
		ReportCommand.WriteMode = "";
	EndIf;
	
	ReportCommand = Reports.WarehouseStock.AddProductMovementCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 3;
		ReportCommand.WriteMode = "";
	EndIf;
	
	ReportCommand = Reports.GoodsInStorageBins.AddProductMovementReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 4;
		ReportCommand.WriteMode = "";
	EndIf;
	
	ReportCommand = Reports.ItemsBatchList.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 5;
		ReportCommand.WriteMode = "";
	EndIf;
	ReportCommand = Reports.OrderCompleteness.AddStaffingTeamByProduct(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 6;
		ReportCommand.WriteMode = "";
	EndIf;
	ReportCommand = Reports.GoodsInWarehousesByShelfLives.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.WriteMode = "";
	EndIf;
	
	ReportCommand = Reports.RevenueAndCOGS.AddProductSalesTeam(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.WriteMode = "";
	EndIf;
	
	ReportCommand = Reports.ProductRangeState.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.WriteMode = "";
		ReportCommand.FunctionalOptions = "UseProductRange";
	EndIf;
	
	
EndProcedure

#EndRegion

#Region MechanismsForSettingUpWorkWithDetailsInFormOfProducts

// Returns the names of details that are currently disabled by the functional options.
//
// Returns:
//	Array of String - the names of the details.
//
Function BankingDetailsDisabledByFederalDistrict(TheseAreDetailsOfCharacteristics = False) Export
	
	BankingDetailsDisabledByFederalDistrict = New Array;
	UseAgentServiceSale  = GetFunctionalOption("UseAgentServiceSale");
	UsePartnersAndCounterparties = GetFunctionalOption("UsePartnersAndCounterparties");
	
	If Not UseAgentServiceSale Then
		BankingDetailsDisabledByFederalDistrict.Add("Principal");
		BankingDetailsDisabledByFederalDistrict.Add("Counterparty");
	ElsIf Not UsePartnersAndCounterparties Then
		BankingDetailsDisabledByFederalDistrict.Add("Counterparty");
	EndIf;
	
	If TheseAreDetailsOfCharacteristics Then
		Return BankingDetailsDisabledByFederalDistrict;
	EndIf;
	
	OutputQuality							= GetFunctionalOption("UseGoodsQuality");
	UseGoodsQualityControl			= GetFunctionalOption("UseGoodsQualityControl");
	UseBinLocationWarehousing				= GetFunctionalOption("UseBinLocationWarehousing", New Structure);
	DisplayPriceGroup						= GetFunctionalOption("UsePriceGroups");
	DisplayFinancialAccountingGroup						= GetFunctionalOption("UseFinancialAccountingGroups");
	DisplayAssortment							= GetFunctionalOption("UseProductCategories");
	DisplayMultiTurnContainers					= GetFunctionalOption("UseReusablePackage");
	UseCharacteristics					= GetFunctionalOption("UseItemVariants");
	UseUnitsForReports				= GetFunctionalOption("UseUnitsOfMeasureForReports");
	UseSeasonalIndexes			= GetFunctionalOption("UseSeasonalIndexes");
	UseCollectionManagement			= GetFunctionalOption("UseCollectionManagement");
	UseSalesRanks		= GetFunctionalOption("UseSalesRanks");
	UseOrderSupplyWithAssignment	= GetFunctionalOption("UseOrderSupplyWithAssignment");
	UseQualityCertificates			= GetFunctionalOption("UseQualityCertificates");
	UseSecurityMethods				= GetFunctionalOption("UseAdvancedDemandFulfillment");
	UseItemPackages			= GetFunctionalOption("UseItemPackages");
	UseAnalyticalInventoryGroups = GetFunctionalOption("UseAnalyticalInventoryGroups");
	UseItemAccessGroups		= GetFunctionalOption("UseItemAccessGroups");
	UseVATAccounting							= GetFunctionalOption("UseVATAccounting");
	UseImportedGoods					= GetFunctionalOption("UseImportedGoods");
	
	If Not OutputQuality Then
		BankingDetailsDisabledByFederalDistrict.Add("Quality");
	EndIf;
	
	If Not UseBinLocationWarehousing Then
		BankingDetailsDisabledByFederalDistrict.Add("WarehouseGroup");
	EndIf;
	
	If Not DisplayPriceGroup Then
		BankingDetailsDisabledByFederalDistrict.Add("PriceGroup");
	EndIf;
	
	If Not DisplayFinancialAccountingGroup Then
		BankingDetailsDisabledByFederalDistrict.Add("FinancialAccountingGroup");
	EndIf;
	
	If Not UseAnalyticalInventoryGroups Then
		BankingDetailsDisabledByFederalDistrict.Add("AnalyticalGroup");
	EndIf;
	
	If Not DisplayAssortment Then
		BankingDetailsDisabledByFederalDistrict.Add("ProductCategory");
	EndIf;
	
	If Not DisplayMultiTurnContainers Then
		BankingDetailsDisabledByFederalDistrict.Add("SuppliedInReusablePackage");
		BankingDetailsDisabledByFederalDistrict.Add("ReusablePackageItems");
		BankingDetailsDisabledByFederalDistrict.Add("ReusablePackageVariant");
	ElsIf Not UseCharacteristics Then 	
		BankingDetailsDisabledByFederalDistrict.Add("ReusablePackageVariant");
	EndIf;
	
	If Not UseCharacteristics Then
		BankingDetailsDisabledByFederalDistrict.Add("UseVariants");
	EndIf;
	
	If Not UseUnitsForReports Then
		BankingDetailsDisabledByFederalDistrict.Add("UnitForReports");
	EndIf;
	
	If Not UseSeasonalIndexes Then
		BankingDetailsDisabledByFederalDistrict.Add("ItemsGroup");
	EndIf;
	
	If Not UseCollectionManagement Then
		BankingDetailsDisabledByFederalDistrict.Add("ItemsCollection");
	EndIf;
	
	If Not UseSalesRanks Then
		BankingDetailsDisabledByFederalDistrict.Add("SalesRank");
	EndIf;
	
	If Not UseOrderSupplyWithAssignment Then
		BankingDetailsDisabledByFederalDistrict.Add("AssignedPurchaseSale");
	EndIf;
	
	If Not UseQualityCertificates Then
		BankingDetailsDisabledByFederalDistrict.Add("KeepRecordsOfQualityCertificates");
	EndIf;
	
	If Not UseSecurityMethods Then
		BankingDetailsDisabledByFederalDistrict.Add("SupplyScheme");
		BankingDetailsDisabledByFederalDistrict.Add("ProcurementStrategy");
	EndIf;
	
	If Not UseGoodsQualityControl Then
		BankingDetailsDisabledByFederalDistrict.Add("ControlQualityOfReceivedGoods");
		BankingDetailsDisabledByFederalDistrict.Add("TermOfQualityControl");
	EndIf;
	
	If Not UseItemPackages Then
		BankingDetailsDisabledByFederalDistrict.Add("UsePackages");
	EndIf;
	
	If Not UseItemAccessGroups Then
		BankingDetailsDisabledByFederalDistrict.Add("AccessGroup");
	EndIf;
	
	If Not UseVATAccounting Then
		BankingDetailsDisabledByFederalDistrict.Add("VATRate");
	EndIf;
	
	ProductsLocalization.BankingDetailsDisabledByFederalDistrict(BankingDetailsDisabledByFederalDistrict);
	
	Return BankingDetailsDisabledByFederalDistrict;
	
EndFunction

// Returns the names of the details that are always displayed when creating a new item.
//
// Returns:
//	Array - elements - String - the names of the details.
//
Function RequiredBankingDetailsDisplayedDuringCreation(ItemsType, FeatureOfAccountingOrKeyTypesOfProducts)
	
	RequiredBankingDetailsDisplayedDuringCreation = New Array;
	
	RequiredBankingDetailsDisplayedDuringCreation.Add("DescriptionFull");
	RequiredBankingDetailsDisplayedDuringCreation.Add("OriginCountry");
	RequiredBankingDetailsDisplayedDuringCreation.Add("VATRate");
	RequiredBankingDetailsDisplayedDuringCreation.Add("FEACNCode");
	
	If ItemsType = Enums.ItemsTypes.OperationService
		And FeatureOfAccountingOrKeyTypesOfProducts <> Enums.ItemAccountingFeatures.PerformedBySellerCompany Then
		
		CommonClientServer.SupplementArray(RequiredBankingDetailsDisplayedDuringCreation, DetailsOfAgencyServices());
		
	EndIf;
	
	ProductsLocalization.RequiredBankingDetailsDisplayedDuringCreation(RequiredBankingDetailsDisplayedDuringCreation,
																		ItemsType,
																		FeatureOfAccountingOrKeyTypesOfProducts);
	
	Return RequiredBankingDetailsDisplayedDuringCreation;
	
EndFunction

// Returns the names of details that are not displayed in the settings table.
//
// Returns:
//	Array of String - the names of the details.
//
Function DetailsNotDisplayedInSettingsTable() Export
	
	DetailsNotDisplayedInSettingsTable = New Array;
	
	CommonClientServer.SupplementArray(DetailsNotDisplayedInSettingsTable, DetailsOfSignsOfAccountingFeatures(Metadata.Catalogs.Products));
	
	DetailsNotDisplayedInSettingsTable.Add("SearchCode");
	DetailsNotDisplayedInSettingsTable.Add("UseCustomPriceTagTemplate");
	DetailsNotDisplayedInSettingsTable.Add("UseCustomTemplateLabels");
	DetailsNotDisplayedInSettingsTable.Add("UsePackages");
	DetailsNotDisplayedInSettingsTable.Add("PackagingGroup");
	DetailsNotDisplayedInSettingsTable.Add("ItemsType");
	DetailsNotDisplayedInSettingsTable.Add("ThereAreGoodsOfOtherQuality");
	DetailsNotDisplayedInSettingsTable.Add("UseVariants");
	DetailsNotDisplayedInSettingsTable.Add("ReusablePackageItems");
	DetailsNotDisplayedInSettingsTable.Add("ReusablePackageVariant");
	DetailsNotDisplayedInSettingsTable.Add("AccountingFeature");
	DetailsNotDisplayedInSettingsTable.Add("FEACNUnitOfMeasure");
	DetailsNotDisplayedInSettingsTable.Add("ShelfLifeUnitOfMeasure");
	DetailsNotDisplayedInSettingsTable.Add("UnitFactorForReports");
	DetailsNotDisplayedInSettingsTable.Add("ItemVariantsOwner");
	DetailsNotDisplayedInSettingsTable.Add("BatchOwner");
	DetailsNotDisplayedInSettingsTable.Add("ProductCategoryOwner");
	DetailsNotDisplayedInSettingsTable.Add("AccessGroup");
	DetailsNotDisplayedInSettingsTable.Add("SaleRegistrationOption");
	DetailsNotDisplayedInSettingsTable.Add("TermOfQualityControl");
	
	DetailsNotDisplayedInSettingsTable.Add("WeightUnitOfMeasure");
	DetailsNotDisplayedInSettingsTable.Add("WeightDenominator");
	DetailsNotDisplayedInSettingsTable.Add("YouCanSpecifyWeightInDocuments");
	DetailsNotDisplayedInSettingsTable.Add("WeightNumerator");
	
	DetailsNotDisplayedInSettingsTable.Add("VolumeUnitOfMeasure");
	DetailsNotDisplayedInSettingsTable.Add("VolumeDenominator");
	DetailsNotDisplayedInSettingsTable.Add("VolumeCanBeSpecifiedInDocuments");
	DetailsNotDisplayedInSettingsTable.Add("VolumeNumerator");
	
	DetailsNotDisplayedInSettingsTable.Add("LengthUnitOfMeasure");
	DetailsNotDisplayedInSettingsTable.Add("LengthDenominator");
	DetailsNotDisplayedInSettingsTable.Add("YouCanSpecifyLengthInDocuments");
	DetailsNotDisplayedInSettingsTable.Add("LengthNumerator");
	
	DetailsNotDisplayedInSettingsTable.Add("AreaUnitOfMeasure");
	DetailsNotDisplayedInSettingsTable.Add("AreaDenominator");
	DetailsNotDisplayedInSettingsTable.Add("AreaCanBeSpecifiedInDocuments");
	DetailsNotDisplayedInSettingsTable.Add("AreaNumerator");
	DetailsNotDisplayedInSettingsTable.Add("DeleteExcisableGoods");
	
	ProductsLocalization.DetailsNotDisplayedInSettingsTable(DetailsNotDisplayedInSettingsTable);
	
	Return DetailsNotDisplayedInSettingsTable;
	
EndFunction

// Returns the names of details that are not used for uniqueness control.
//
// Returns:
//	Array of String - the names of the details.
//
Function UnusedPropsForUniquenessControl() Export
	
	UnusedPropsForUniquenessControl = New Array;
	
	UnusedPropsForUniquenessControl.Add("DescriptionFull");
	UnusedPropsForUniquenessControl.Add("LongDesc");
	UnusedPropsForUniquenessControl.Add("PicturesFile");
	UnusedPropsForUniquenessControl.Add("PriceTagTemplate");
	UnusedPropsForUniquenessControl.Add("LabelsTemplate");
	UnusedPropsForUniquenessControl.Add("DescriptionFileForWebsite");
	UnusedPropsForUniquenessControl.Add("UseCustomPriceTagTemplate");
	UnusedPropsForUniquenessControl.Add("UseCustomTemplateLabels");
	UnusedPropsForUniquenessControl.Add("ExpirationDate_");
	UnusedPropsForUniquenessControl.Add("AssignedPurchaseSale");
	
	UnusedPropsForUniquenessControl.Add("WeightUse");
	UnusedPropsForUniquenessControl.Add("VolumeUse");
	UnusedPropsForUniquenessControl.Add("AreaUse");
	UnusedPropsForUniquenessControl.Add("LengthUse");
	
	ProductsLocalization.UnusedPropsForUniquenessControl(UnusedPropsForUniquenessControl);
	
	Return UnusedPropsForUniquenessControl;
	
EndFunction

// Returns value types. Details of these types are not checked for fullness.
//
// Returns:
//	Array of TypeDescription - collection of types.
//
Function TypesNotUsedForFillingAndSelectionControl() Export
	
	TypesNotUsedForFillingAndSelectionControl = New Array;
	
	TypesNotUsedForFillingAndSelectionControl.Add(New TypeDescription("CatalogRef.ProductsAttachedFiles"));
	TypesNotUsedForFillingAndSelectionControl.Add(New TypeDescription("CatalogRef.Files"));
	TypesNotUsedForFillingAndSelectionControl.Add(New TypeDescription("ValueStorage"));
	TypesNotUsedForFillingAndSelectionControl.Add(New TypeDescription("String",,New StringQualifiers(0)));
	
	ProductsLocalization.TypesNotUsedForFillingAndSelectionControl(TypesNotUsedForFillingAndSelectionControl);
	
	Return TypesNotUsedForFillingAndSelectionControl;
	
EndFunction

// Returns a description of actions with item details in the item form, depending on the item type.
//
// Parameters:
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//	FeatureOfAccountingOrKeyTypesOfProducts - EnumRef.ItemAccountingFeatures,
//	                                        Reference link.The key of individual products is the peculiarity of item accounting.
//	UseVariants - EnumRef.ItemVariantsUsageOptions, Boolean - 
//		use case for the item or whether characteristics are used.
//	UseShelfLifeOnBatchRegistration - Boolean - indicates whether the expiration date is used in the item series.
//	TheseAreDetailsOfCharacteristics - Boolean - indicates whether the details belong to the reference list of nomenclature Characteristics.
//
// Returns:
//	ValueTable - with columns:
//		* Attribute - MetadataObjectAttribute - details of the Nomenclature reference list
//		* ActionWithProps - String - action.
//
Function DependenceOfBankingDetailsOnTypeOfProductItem(ItemsType,
												FeatureOfAccountingOrKeyTypesOfProducts,
												UseVariants,
												UseShelfLifeOnBatchRegistration,
												TheseAreDetailsOfCharacteristics) Export
	
	If TypeOf(UseVariants) = Type("EnumRef.ItemVariantsUsageOptions") Then
		UseCharacteristics = UseVariants <> Enums.ItemVariantsUsageOptions.DontUse;
	Else
		UseCharacteristics = UseVariants;
	EndIf;
	
	ThisIsAProduct 				= (ItemsType = Enums.ItemsTypes.OwnGoods);
	IsRecordsSet 				= (ItemsType = Enums.ItemsTypes.Set);
	IsService 				= (ItemsType = Enums.ItemsTypes.OperationService);
	ThisIsWork 				= (ItemsType = Enums.ItemsTypes.Work_5);
	ThisIsMultiTurnContainer 	= (ItemsType = Enums.ItemsTypes.ReusablePackage);

	// Create a table of details to fill in.
	
	AttributesTable = New ValueTable;
	AttributesTable.Columns.Add("Attribute");
	AttributesTable.Columns.Add("Use");
	
	If TheseAreDetailsOfCharacteristics Then
		Attributes = Metadata.Catalogs.ItemsCharacteristics.Attributes;
	Else
		Attributes = Metadata.Catalogs.Products.Attributes;
	EndIf;
	
	// Details that should be in the nomenclature only when characteristics are not used.
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.Principal;
	NewRow.Use = (IsService
									Or ThisIsWork)
								And (FeatureOfAccountingOrKeyTypesOfProducts = Enums.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis
									Or FeatureOfAccountingOrKeyTypesOfProducts = Enums.ItemAccountingFeatures.PerformedByPartner)
								And (Not UseCharacteristics
									Or TheseAreDetailsOfCharacteristics);
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.Counterparty;
	NewRow.Use = (IsService
									Or ThisIsWork)
								And FeatureOfAccountingOrKeyTypesOfProducts = Enums.ItemAccountingFeatures.PerformedByPartner
								And (Not UseCharacteristics
									Or TheseAreDetailsOfCharacteristics);
	
	If TheseAreDetailsOfCharacteristics Then
		ProductsLocalization.DependenceOfBankingDetailsOnTypeOfProductItem(AttributesTable,
																		ItemsType,
																		FeatureOfAccountingOrKeyTypesOfProducts,
																		UseVariants,
																		True);
		AttributesTable.Indexes.Add("Attribute");
		Return AttributesTable;
	EndIf;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.SaleRegistrationOption;
	NewRow.Use = (GetFunctionalOption("UseDeedsOfTransfer")
									And ThisIsAProduct)
								Or ThisIsWork
								Or IsService;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.WarehouseGroup;
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.Quality;
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	DependenceOfMeasureDetailsOnTypeOfProduct(AttributesTable, Attributes, ItemsType, "Weight");
	DependenceOfMeasureDetailsOnTypeOfProduct(AttributesTable, Attributes, ItemsType, "VolumeM3");
	DependenceOfMeasureDetailsOnTypeOfProduct(AttributesTable, Attributes, ItemsType, "AreaTypeOfMeasurement");
	DependenceOfMeasureDetailsOnTypeOfProduct(AttributesTable, Attributes, ItemsType, "Length");
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.UsePackages;
	NewRow.Use = ThisIsAProduct;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.PackagingGroup;
	NewRow.Use = ThisIsAProduct;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.AssignedPurchaseSale;
	NewRow.Use = ThisIsAProduct
								Or ThisIsWork;
		
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.SuppliedInReusablePackage;
	NewRow.Use = ThisIsAProduct;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.ReusablePackageItems;
	NewRow.Use = ThisIsAProduct;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.ReusablePackageVariant;
	NewRow.Use = ThisIsAProduct;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.UnitOfMeasure;
	NewRow.Use = True;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.ExpirationDate_;
	NewRow.Use = (ThisIsAProduct
									Or ThisIsMultiTurnContainer)
								And UseShelfLifeOnBatchRegistration;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.ShelfLifeUnitOfMeasure;
	NewRow.Use = (ThisIsAProduct
									Or ThisIsMultiTurnContainer)
								And UseShelfLifeOnBatchRegistration;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.FinancialAccountingGroup;
	NewRow.Use = Not IsRecordsSet;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.KeepRecordsOfQualityCertificates;
	NewRow.Use = ThisIsAProduct;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.SupplyScheme;
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.ProcurementStrategy;
	NewRow.Use = ThisIsWork;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.ControlQualityOfReceivedGoods;
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.TermOfQualityControl;
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.FEACNCode;
	NewRow.Use = Not (ThisIsWork
									Or IsService);
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.OriginCountry;
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	ProductsLocalization.DependenceOfBankingDetailsOnTypeOfProductItem(AttributesTable,
																		ItemsType,
																		FeatureOfAccountingOrKeyTypesOfProducts,
																		UseVariants,
																		False);
	
	AttributesTable.Indexes.Add("Attribute");
	
	Return AttributesTable;
	
EndFunction

// The function is the Value properties props
// 
// Returns:
//	Structure - contains the following properties:
//		* Name - String - name of the prop.
//		* Presentation - String - Presentation of the props.
//		* Type - TypeDescription - The type of the prop.
//		* Required_ToFillIn - Boolean - indicates whether the Attribute must be filled in.
//		* RequiredToDisplayWhenCreating - Boolean - indicates whether the Attribute must be displayed when creating a Catalog item.
//		* RecommendedForUniquenessControl - Boolean - indicates whether the Attribute needs to participate in checking the uniqueness of the Catalog element.
//		* Use - Boolean - indicates whether the Attribute is used.
//
Function PropertyValuesOfProps() Export
	
	Result = New Structure;
	Result.Insert("Name");
	Result.Insert("Presentation");
	Result.Insert("Type");
	Result.Insert("Use");
	Result.Insert("Required_ToFillIn");
	Result.Insert("RequiredToDisplayWhenCreating", False);
	Result.Insert("RecommendedForUniquenessControl", False);
	
	Return Result;
	
EndFunction

// To call in the method, the value is set to Setpovtisp.Userequipment
// Returns the properties of the item details, taking into account the settings made
// in the metadata and pre-defined in the modules of the item Manager.
//
// Parameters:
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//	FeatureOfAccountingOrKeyTypesOfProducts - EnumRef.ItemAccountingFeatures,
//	                                        Reference link.The key of individual products is the peculiarity of item accounting.
//	UseVariants - EnumRef.ItemVariantsUsageOptions, Boolean - 
//		use case for the item or whether characteristics are used.
//	UseShelfLifeOnBatchRegistration - Boolean - indicates whether the expiration date is used in the item series.
//
// Returns:
//	FixedStructure - Contains:
//		* Key - String - name of the prop.
//		* Value - See PropertyValuesOfProps.
//
Function AllAttributes(ItemsType,
					FeatureOfAccountingOrKeyTypesOfProducts,
					UseVariants,
					UseShelfLifeOnBatchRegistration) Export
	
	ThisIsAProduct = (ItemsType = Enums.ItemsTypes.OwnGoods);
	ThisIsMultiTurnContainer = (ItemsType = Enums.ItemsTypes.ReusablePackage);
	
	RequiredBankingDetailsDisplayedDuringCreation   = RequiredBankingDetailsDisplayedDuringCreation(ItemsType,
																								FeatureOfAccountingOrKeyTypesOfProducts);
	RecommendedPropsForUniquenessControl = RecommendedPropsForUniquenessControl(ItemsType, FeatureOfAccountingOrKeyTypesOfProducts);
	
	SettingsOfBankingDetailsByType = DependenceOfBankingDetailsOnTypeOfProductItem(ItemsType,
																		FeatureOfAccountingOrKeyTypesOfProducts,
																		UseVariants,
																		UseShelfLifeOnBatchRegistration,
																		False);
	
	BankingDetailsDisabledByFederalDistrict = BankingDetailsDisabledByFederalDistrict();
	BankingDetailsWithRedefinedMandatoryFields = BankingDetailsWithRedefinedMandatoryFields(ItemsType, FeatureOfAccountingOrKeyTypesOfProducts, Undefined);
	
	AllAttributes = New Structure;
	
	For Each Attribute In Metadata.Catalogs.Products.Attributes Do
		
		PropertyValues = PropertyValuesOfProps();
		
		PropertyValues.Name = Attribute.Name;
		AttributeRepresentation = "";
		
		SettingString = SettingsOfBankingDetailsByType.Find(Attribute, "Attribute");
		
		If SettingString = Undefined Then
			PropertyValues.Use = BankingDetailsDisabledByFederalDistrict.Find(Attribute.Name) = Undefined;
		Else
			PropertyValues.Use = SettingString.Use
											And BankingDetailsDisabledByFederalDistrict.Find(Attribute.Name) = Undefined;
		EndIf;
		
		If Attribute.Name = "UnitOfMeasure" Then
			If ThisIsAProduct
				Or ThisIsMultiTurnContainer Then
				AttributeRepresentation = NStr("vi = 'Đơn vị lưu kho';
												|ru = 'Единица хранения';
												|en = 'Stock UOM'; fa = 'واحد انبار';
												|it = 'Unità di stoccaggio';
												|pl = 'Jednostka magazynowa';
												|tr = 'Stok ölçü birimi'");
			Else
				AttributeRepresentation = NStr("vi = 'Đơn vị tính';
												|ru = 'Единица измерения';
												|en = 'Unit of measure'; fa = 'واحد اندازه‌گیری';
												|it = 'Unità di misura';
												|pl = 'Jednosta miary';
												|tr = 'Ölçü birimi'");
			EndIf;
		Else
			AttributeRepresentation = Attribute.Synonym;
			If Not ValueIsFilled(AttributeRepresentation) Then
				AttributeRepresentation = Attribute.Name;
			EndIf;
		EndIf;
		
		PropertyValues.Presentation = AttributeRepresentation;
		
		Required_ToFillIn = BankingDetailsWithRedefinedMandatoryFields.Get(Attribute.Name);
		
		If Required_ToFillIn = Undefined Then 
			Required_ToFillIn = (Attribute.FillChecking = FillChecking.ShowError);
		EndIf;
		
		PropertyValues.Required_ToFillIn = PropertyValues.Use
													And Required_ToFillIn;
		PropertyValues.Type = Attribute.Type;
		
		PropertyValues.RequiredToDisplayWhenCreating = PropertyValues.Use
																And (RequiredBankingDetailsDisplayedDuringCreation.Find(Attribute.Name) <> Undefined
																	Or PropertyValues.Required_ToFillIn);
		PropertyValues.RecommendedForUniquenessControl = PropertyValues.Use
																And RecommendedPropsForUniquenessControl.Find(Attribute.Name) <> Undefined;
		
		AllAttributes.Insert(Attribute.Name, New FixedStructure(PropertyValues));
	EndDo;
	
	CompleteAllDetailsWithDetailsOfForm(AllAttributes);
	
	Return New FixedStructure(AllAttributes);
	
EndFunction

// Parameters:
// 	Form - ClientApplicationForm - 
//
Procedure ConfigureFormUsingSettingsTable(Form) Export
	
	TheStructureOfTheSearch = New Structure("Property");
	ThereIsDescriptionOfAdditionalAttributes = GetFunctionalOption("UseAdditionalAttributesAndInfo")
		And CommonClientServer.HasAttributeOrObjectProperty(Form, "PropertiesAdditionalAttributeDetails");
	UseNonUniqueItemBarcodes = GetFunctionalOption("UseNonUniqueItemBarcodes");

	For Each RowOfDetailsTable In Form.AttributeSettingTable Do
		
		If RowOfDetailsTable.IsAddlAttribute Then
			
			If Not ThereIsDescriptionOfAdditionalAttributes Then
				Continue;
			EndIf;
			
			TheStructureOfTheSearch.Property = RowOfDetailsTable.Property;
			FoundRows = Form.PropertiesAdditionalAttributeDetails.FindRows(TheStructureOfTheSearch);
			
			If FoundRows.Count() = 0 Then
				Continue;
			EndIf;
			
			FormItemName = FoundRows[0].ValueAttributeName;
			
		Else
			
			FormItemName = RowOfDetailsTable.AttributeName;
			
		EndIf;
		
		If Form.Items.Find(FormItemName) = Undefined Then
			Continue;
		EndIf;
		
		RowOfDetailsTable.DataPath = FormItemName;
		
		Item = Form.Items[FormItemName];
		
		If Item.Type = FormFieldType.InputField Then
			Form.Items[FormItemName].AutoMarkIncomplete = RowOfDetailsTable.RequiredToFill;
			
			If Not RowOfDetailsTable.RequiredToFill
				And Form.Items[FormItemName].MarkIncomplete Then
				
				Form.Items[FormItemName].MarkIncomplete = False;
				
			EndIf;
		EndIf;
		
		If RowOfDetailsTable.Uniqueness
			Or (FormItemName = "Barcode"
				And Not UseNonUniqueItemBarcodes) Then
			
			Item.BackColor = StyleColors.SelectionBackColor;
			
		ElsIf Item.Type = FormFieldType.InputField Then
			Item.BackColor = New Color;
		EndIf;
		
	EndDo;
	
EndProcedure

Function BankingDetailsWithRedefinedMandatoryFields(ItemsType, FeatureOfAccountingOrKeyTypesOfProducts, Object) Export
	
	BankingDetailsWithRedefinedMandatoryFields = New Map;
	
	RequestedDetailsOfTypeOfProduct = "WorkingNameTemplateOfProductItem, UseShelfLifeOnBatchRegistration, 
											|UseVariants";
	
	If Object = Undefined Then
		ProductKindAttributes = TMCommonUse.DefaultValuesForItemDetails(Catalogs.ItemKinds.EmptyRef(),
			RequestedDetailsOfTypeOfProduct);
	Else
		ProductKindAttributes = TMCommonUse.DefaultValuesForItemDetails(Object.ProductKind,
			RequestedDetailsOfTypeOfProduct);
	EndIf;	
	
	If Object = Undefined Then
		BankingDetailsWithRedefinedMandatoryFields.Insert("Description", True);
	Else
		BankingDetailsWithRedefinedMandatoryFields.Insert("Description", Not ValueIsFilled(ProductKindAttributes.WorkingNameTemplateOfProductItem));
	EndIf;
	
	If Object = Undefined Then 
		BankingDetailsWithRedefinedMandatoryFields.Insert("PriceTagTemplate", False);
	Else
		BankingDetailsWithRedefinedMandatoryFields.Insert("PriceTagTemplate", Object.UseCustomPriceTagTemplate);
	EndIf;
		
	If Object = Undefined Then 
		BankingDetailsWithRedefinedMandatoryFields.Insert("LabelsTemplate", False);
	Else
		BankingDetailsWithRedefinedMandatoryFields.Insert("LabelsTemplate", Object.UseCustomTemplateLabels);
	EndIf;
	
	If Object = Undefined Then
		BankingDetailsWithRedefinedMandatoryFields.Insert("PackagingGroup", False);
	Else
		BankingDetailsWithRedefinedMandatoryFields.Insert("PackagingGroup", Object.UsePackages);
	EndIf;
	
	BankingDetailsWithRedefinedMandatoryFields.Insert("AccessGroup", Catalogs.ItemAccessGroups.AccessGroupsAreUsed());
	
	BankingDetailsWithRedefinedMandatoryFields.Insert("UnitOfMeasure", ItemsType = Enums.ItemsTypes.OwnGoods
																			Or ItemsType = Enums.ItemsTypes.ReusablePackage
																			Or ItemsType = Enums.ItemsTypes.Set);
	BankingDetailsWithRedefinedMandatoryFields.Insert("Principal", FeatureOfAccountingOrKeyTypesOfProducts = Enums.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis
																		Or FeatureOfAccountingOrKeyTypesOfProducts = Enums.ItemAccountingFeatures.PerformedByPartner);
																		
	BankingDetailsWithRedefinedMandatoryFields.Insert("Counterparty", FeatureOfAccountingOrKeyTypesOfProducts = Enums.ItemAccountingFeatures.PerformedByPartner);
	
	If Object = Undefined Then
		BankingDetailsWithRedefinedMandatoryFields.Insert("ReusablePackageItems", False);
		BankingDetailsWithRedefinedMandatoryFields.Insert("ReusablePackageVariant", False);
	Else
		BankingDetailsWithRedefinedMandatoryFields.Insert("ReusablePackageItems", Object.SuppliedInReusablePackage);
		BankingDetailsWithRedefinedMandatoryFields.Insert("ReusablePackageVariant",
																			Object.SuppliedInReusablePackage
																			And Catalogs.Products.ItemVariantsAreUsed(Object.ReusablePackageItems));
	EndIf;
	
	If Object = Undefined Then
		BankingDetailsWithRedefinedMandatoryFields.Insert("ShelfLifeUnitOfMeasure", False);
	Else
		BankingDetailsWithRedefinedMandatoryFields.Insert("ShelfLifeUnitOfMeasure", ProductKindAttributes.UseShelfLifeOnBatchRegistration);
	EndIf;
	
	RedefineObligationToFillInDetailsOfMeasure(Object, BankingDetailsWithRedefinedMandatoryFields, "Weight");
	RedefineObligationToFillInDetailsOfMeasure(Object, BankingDetailsWithRedefinedMandatoryFields, "VolumeM3");
	RedefineObligationToFillInDetailsOfMeasure(Object, BankingDetailsWithRedefinedMandatoryFields, "AreaTypeOfMeasurement");
	RedefineObligationToFillInDetailsOfMeasure(Object, BankingDetailsWithRedefinedMandatoryFields, "Length");
	
	ProductsLocalization.BankingDetailsWithRedefinedMandatoryFields(
		BankingDetailsWithRedefinedMandatoryFields, ItemsType, FeatureOfAccountingOrKeyTypesOfProducts, Object);
	
	If Object <> Undefined Then
		
		AttributesToChange       = New Array;
		AttributeSettingTable = DependenceOfBankingDetailsOnTypeOfProductItem(ItemsType,
																			FeatureOfAccountingOrKeyTypesOfProducts,
																			ProductKindAttributes.UseVariants,
																			ProductKindAttributes.UseShelfLifeOnBatchRegistration,
																			False);
		
		For Each Attribute In BankingDetailsWithRedefinedMandatoryFields Do
			
			If Attribute.Value Then
				If Attribute.Key = "Description" Then
					Continue;
				EndIf;
				
				AttributeMetadata = Metadata.Catalogs.Products.Attributes.Find(Attribute.Key);
				SettingUpProps  = AttributeSettingTable.Find(AttributeMetadata);
				
				If ValueIsFilled(SettingUpProps)
					And Not SettingUpProps.Use Then
					
					AttributesToChange.Add(Attribute.Key);
					
				EndIf;
			EndIf;
			
		EndDo;
		
		For Each AttributeName In AttributesToChange Do
			BankingDetailsWithRedefinedMandatoryFields.Insert(AttributeName, False);
		EndDo;
		
	EndIf;
	
	Return BankingDetailsWithRedefinedMandatoryFields;
	
EndFunction

Function RecommendedPropsForUniquenessControl(ItemsType, FeatureOfAccountingOrKeyTypesOfProducts)
	
	RecommendedPropsForUniquenessControl = New Array;
	
	ProductsLocalization.RecommendedPropsForUniquenessControl(
		RecommendedPropsForUniquenessControl, ItemsType, FeatureOfAccountingOrKeyTypesOfProducts); 
	
	Return RecommendedPropsForUniquenessControl;
	
EndFunction

// Parameters:
// 	Form - ClientApplicationForm - contains including:
// 	* Object - CatalogObject.Products - 
//
Procedure CheckUniquenessOfElementByItsDetails(Form) Export
	
	Form.TableFound.Clear();
	
	ThisIsProduct		= TypeOf(Form.Object.Ref) = Type("CatalogRef.Products");
	FormAttributes		= ?(ThisIsProduct, DetailsOfSettingsTableForm(), Undefined);
	RowFilter			= New Structure("Uniqueness", True);
	UniqueProps	= Form.AttributeSettingTable.FindRows(RowFilter);
	
	If FormAttributes <> Undefined Then
		UniquenessControlDetails = New Array;
		
		For Each ControlAttribute In UniqueProps Do
			If FormAttributes.Get(ControlAttribute.AttributeName) = Undefined Then
				UniquenessControlDetails.Add(ControlAttribute);
			EndIf;
		EndDo;
	Else
		UniquenessControlDetails = UniqueProps;
	EndIf;
	
	If UniquenessControlDetails.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	
	QueryText = 
	"SELECT DISTINCT
	|	VerifiableCatalog.Ref AS Ref,
	|	TRUE AS FoundByAdditionalAttributes
	|FROM
	|	Catalog.NameOfCatalogToCheck AS VerifiableCatalog
	|	,&TextOfRequestToConnectSTCAndBankingDetails
	|WHERE
	|	&QueryTextConditionsForBankDetails";
	
	TemplateOfTheConditionForTheBankDetails = 
	"
	|	VerifiableCatalog.AttributeName = &AttributeName";
	
	TemplateConditionsForAdditionalBankingDetails =
	"
	|  (ConditionForAdditionalDetails_ConditionCounter.Value IS NULL
	|  			AND &ValueEmpty_ConditionCounter
	|  	OR ConditionForAdditionalDetails_ConditionCounter.Property = &Property_ConditionCounter
	|  			AND ConditionForAdditionalDetails_ConditionCounter.Value = &Value_ConditionCounter)";

	ConnectionTextTemplate =
	"
	| LEFT JOIN Catalog.NameOfCatalogToCheck.AdditionalAttributes AS ConditionForAdditionalDetails_ConditionCounter
	| ON VerifiableCatalog.Ref = ConditionForAdditionalDetails_ConditionCounter.Ref
	| 		AND ConditionForAdditionalDetails_ConditionCounter.Property = &Property_ConditionCounter";
	
	ConditionCounter	= 1;
	TermsAndConditions_	= New Array;
	
	If ThisIsProduct Then
		ConditionText =
		"
		|	NOT VerifiableCatalog.IsFolder
		|	AND VerifiableCatalog.ProductKind IN(&ItemKinds)";
		TermsAndConditions_.Add(ConditionText);
		
		Query.SetParameter("ItemKinds", TypesOfProductsThatAreIdenticalInTermsOfUniquenessControlSettings(Form.Object));
	Else
		ConditionText =
		"
		|	VerifiableCatalog.Owner = &Owner";
		TermsAndConditions_.Add(ConditionText);
		
		Query.SetParameter("Owner", Form.Object.Owner);
	EndIf;
	
	ConnectionTexts = New Array;
	
	For Each ConditionString In UniquenessControlDetails Do
		If Not ConditionString.IsAddlAttribute Then
			ConditionText = StrReplace(TemplateOfTheConditionForTheBankDetails, "AttributeName", ConditionString.AttributeName);
			TermsAndConditions_.Add(ConditionText);
			
			If IsBlankString(ConditionString.DataPath) Then
				DataPath = ConditionString.AttributeName;
			Else
				DataPath = ConditionString.DataPath;
			EndIf;
			
			Query.SetParameter(ConditionString.AttributeName, Form.Object[DataPath]);
		Else
			ConditionCounterString = Format(ConditionCounter,"NG=");
			
			ConditionText = TemplateConditionsForAdditionalBankingDetails;
			ConditionText = StrReplace(ConditionText, "&Property_ConditionCounter", "&Property_" + ConditionCounterString);
			ConditionText = StrReplace(ConditionText, "&Value_ConditionCounter", "&Value_" + ConditionCounterString);
			ConditionText = StrReplace(ConditionText, "&ValueEmpty_ConditionCounter", "&ValueIsEmpty_" + ConditionCounterString);
			ConditionText = StrReplace(ConditionText, "ConditionCounter", ConditionCounterString);
			TermsAndConditions_.Add(ConditionText);
			
			Query.SetParameter("Property_" + ConditionCounter, ConditionString.Property);
			Query.SetParameter("Value_" + ConditionCounter, Form[ConditionString.DataPath]);
			Query.SetParameter("ValueIsEmpty_" + ConditionCounter, ?(TypeOf(Form[ConditionString.DataPath]) = Type("Boolean")
																				And Not Form[ConditionString.DataPath],
																			True,
																			Not ValueIsFilled(Form[ConditionString.DataPath])));
			
			JoinText = StrReplace(ConnectionTextTemplate, "ConditionCounter", Format(ConditionCounter,"NG="));
			ConnectionTexts.Add(JoinText);
			
			ConditionCounter = ConditionCounter + 1;
		EndIf;
	EndDo;
	
	QueryText = StrReplace(QueryText,
								",&TextOfRequestToConnectSTCAndBankingDetails",
								StrConcat(ConnectionTexts));
	QueryText = StrReplace(QueryText,
								"&QueryTextConditionsForBankDetails",
								StrConcat(TermsAndConditions_, Chars.LF + "And" + Chars.NBSp));
	QueryText = StrReplace(QueryText,
								"NameOfCatalogToCheck",
								?(ThisIsProduct, "Products", "ItemsCharacteristics"));
	
	Query.Text = QueryText;
	
	Form.TableFound.Load(Query.Execute().Unload());
	
EndProcedure

Function TypesOfProductsThatAreIdenticalInTermsOfUniquenessControlSettings(Object)
	
	IdenticalTypesOfProducts = New Array;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	AttributesForControl.AttributeName,
	|	AttributesForControl.IsAddlAttribute,
	|	AttributesForControl.Property
	|FROM
	|	Catalog.ItemKinds.AttributesForProductsControl AS AttributesForControl
	|WHERE
	|	AttributesForControl.Uniqueness
	|	AND AttributesForControl.Ref = &ProductKind
	|	AND NOT (NOT AttributesForControl.IsAddlAttribute
	|		AND AttributesForControl.AttributeName IN (&AttributesToExclude))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AttributesForControl.Ref AS ProductKind,
	|	AttributesForControl.AttributeName AS AttributeName,
	|	AttributesForControl.IsAddlAttribute AS IsAddlAttribute,
	|	AttributesForControl.Property AS Property
	|FROM
	|	Catalog.ItemKinds.AttributesForProductsControl AS AttributesForControl
	|WHERE
	|	AttributesForControl.Uniqueness
	|	AND AttributesForControl.Ref.ItemsType = &ItemsType
	|	AND NOT (NOT AttributesForControl.IsAddlAttribute
	|		AND AttributesForControl.AttributeName IN (&AttributesToExclude))
	|
	|ORDER BY
	|	ProductKind,
	|	AttributeName,
	|	IsAddlAttribute,
	|	Property
	|
	|TOTALS BY
	|	ProductKind";
	
	AttributesToExclude = New Array;
	AttributesToExclude.Add("ProductKind");
	
	FormAttributes = DetailsOfSettingsTableForm();
	
	For Each KeyAndValue In FormAttributes Do
		AttributesToExclude.Add(KeyAndValue.Key);
	EndDo;
	
	Query.SetParameter("ProductKind",		Object.ProductKind);
	Query.SetParameter("ItemsType",		Object.ItemsType);
	Query.SetParameter("AttributesToExclude",	AttributesToExclude);
	
	QueryResults = Query.ExecuteBatch();
	
	TableOfCurTypeProductDetails = QueryResults[0].Unload();
	NumberOfControlDetails = TableOfCurTypeProductDetails.Count();
	
	DetailsOfProductTypes   = QueryResults[1]; // QueryResult
	Filter = New Structure("AttributeName, IsAddlAttribute, Property");
	
	SelectionByType = DetailsOfProductTypes.Select(QueryResultIteration.ByGroups);
	
	While SelectionByType.Next() Do
		MeetsConditions	= True;
		SelectionByBankingDetails		= SelectionByType.Select();
		NumberOfTypeDetails		= SelectionByBankingDetails.Count();
		
		If NumberOfTypeDetails = 0 Then
			Continue;
		EndIf;
		
		If NumberOfTypeDetails <> NumberOfControlDetails Then
			Continue;
		EndIf;
		
		While SelectionByBankingDetails.Next() Do
			FillPropertyValues(Filter, SelectionByBankingDetails);
			
			If TableOfCurTypeProductDetails.FindRows(Filter).Count() = 0 Then
				MeetsConditions = False;
			EndIf;
			
			If Not MeetsConditions Then
				Break;
			EndIf;
		EndDo;
		
		If Not MeetsConditions Then
			Continue;
		EndIf;
		
		IdenticalTypesOfProducts.Add(SelectionByType.ProductKind);
	EndDo;
	
	Return IdenticalTypesOfProducts;
	
EndFunction

// Returns a collection of Catalog form Attributes used in the control settings.
//
// Returns:
//	Map of KeyAndValue - collection of Attributes of the Catalog Form where:
//		* Key - String - name of the prop.
//		* Value - Arbitrary - the default value of the Attribute.
//
Function DetailsOfSettingsTableForm() Export
	
	FormAttributes = New Map;
	FormAttributes.Insert("Barcode", "");
	
	Return FormAttributes;
	
EndFunction

#EndRegion

#Region Other

// Checks whether the current user has rights to enter information about the item without control.
//
// Returns:
//	Boolean - availability of the right to enter
//
Function UncontrolledInputIsAvailable() Export
	
	Return UserRightsCached.EnterInformationAboutItemsWithoutControl();
	
EndFunction

// Checks whether the item name is unique.
//
// Parameters:
//	Object - CatalogObject.Products - element of the nomenclature reference list.
//
// Returns:
//	Boolean - a sign of the uniqueness of the name of this element of the directory.
//
Function WorkingNameIsUnique(Object) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	Products.Ref AS Products
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref <> &Ref
	|	AND Products.Description = &Description
	|	AND NOT Products.IsFolder";
	
	Query.SetParameter("Ref",       Object.Ref);
	Query.SetParameter("Description", Object.Description);

	Return Query.Execute().IsEmpty();
	
EndFunction

Procedure WorkOutLogicOfFillingMeasure(Products, DimensionalStorageUnit, UnitType_, Measure) Export
	
	If Measure <> "Weight"
		And Measure <> "Length"
		And Measure <> "AreaTypeOfMeasurement"
		And Measure <> "VolumeM3" Then
		Return;
	EndIf;
	
	DetailsOfMeasure = DetailsOfMeasure(Measure);
	
	If DimensionalStorageUnit
		And UnitType_ = Measure
		And (Products.ItemsType = Enums.ItemsTypes.OwnGoods
			Or Products.ItemsType = Enums.ItemsTypes.ReusablePackage) Then
		
		Products[DetailsOfMeasure.Use] = True;
		Products[DetailsOfMeasure.Denominator]  = 1;
		Products[DetailsOfMeasure.Numerator]    = 1;
		Products[DetailsOfMeasure.CanBeSpecifiedInDocuments] = True;
		Products[DetailsOfMeasure.UnitOfMeasure] = Products.UnitOfMeasure;
		
	EndIf;
	
	If Products.ItemsType = Enums.ItemsTypes.Work_5
		Or Products.ItemsType = Enums.ItemsTypes.OperationService
		Or Products.ItemsType = Enums.ItemsTypes.Set
		Or Products[DetailsOfMeasure.Denominator] = 0
		Or Products[DetailsOfMeasure.Numerator] = 0
		Or Not Products[DetailsOfMeasure.Use] Then 
		
		Products[DetailsOfMeasure.UnitOfMeasure]          = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		Products[DetailsOfMeasure.Denominator]               = 0;
		Products[DetailsOfMeasure.Numerator]                 = 0;
		Products[DetailsOfMeasure.CanBeSpecifiedInDocuments] = False;
		Products[DetailsOfMeasure.Use]              = False;
	Else
	
		If Not ValueIsFilled(Products[DetailsOfMeasure.UnitOfMeasure]) Then
			Products[DetailsOfMeasure.UnitOfMeasure] = ProductsServer.DefaultUnitOfMeasurement(Measure);
		EndIf;

	EndIf;
	
EndProcedure

// Returns a table of required details.
//
// Parameters:
//	ProductKind - CatalogObject.ItemKinds - item types in the reference list.
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//	FeatureOfAccountingOrKeyTypesOfProducts - EnumRef.ItemAccountingFeatures,
//	                                        Reference link.The key of individual products is the peculiarity of item accounting.
//	UseVariants - EnumRef.ItemVariantsUsageOptions, Boolean - 
//		use case for the item or whether characteristics are used.
//	UseShelfLifeOnBatchRegistration - Boolean - indicates whether the expiration date is used in the item series.
//	AttributesOwner - String - name of the object of the details owner.
//
// Returns:
//	ValueTable - a table with mandatory and output details during creation.
//
Function AttributeSettingTable(ProductKind,
								ItemsType,
								FeatureOfAccountingOrKeyTypesOfProducts,
								UseVariants,
								UseShelfLifeOnBatchRegistration,
								AttributesOwner) Export
	
	Query = New Query;
	QueryText =
	"SELECT
	|	AllProductDetailsTable.Name AS Name,
	|	AllProductDetailsTable.Presentation AS Presentation,
	|	AllProductDetailsTable.Required_ToFillIn AS Required_ToFillIn,
	|	AllProductDetailsTable.RequiredToDisplayWhenCreating AS RequiredToDisplayWhenCreating,
	|	AllProductDetailsTable.Use AS Use
	|INTO AllProductDetailsTable
	|FROM
	|	&AllProductDetailsTable AS AllProductDetailsTable
	|
	|INDEX BY
	|	Name
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN AttributesForControl.IsAddlAttribute
	|			THEN AttributesForControl.Property.Presentation
	|		ELSE AttributesForControl.AttributeRepresentation
	|	END AS Presentation,
	|	AttributesForControl.IsAddlAttribute AS IsAddlAttribute,
	|	CASE
	|		WHEN AttributesForControl.IsAddlAttribute
	|			THEN AttributesForControl.Property.Description
	|		ELSE AttributesForControl.AttributeName
	|	END AS AttributeName,
	|	AttributesForControl.Property AS Property,
	|	CASE
	|		WHEN AttributesForControl.IsAddlAttribute
	|			THEN ISNULL(TTAllAdditionalDetails.RequiredToFill, FALSE)
	|		ELSE AttributesForControl.RequiredToFill
	|	END AS RequiredToFill,
	|	AttributesForControl.Uniqueness AS Uniqueness,
	|	CASE
	|		WHEN ISNULL(TTAllAdditionalDetails.RequiredToFill, FALSE)
	|			THEN TRUE
	|		ELSE AttributesForControl.DisplayWhenCreated
	|	END AS DisplayWhenCreated,
	|	AttributesForControl.IsAddlAttribute AS Use,
	|	FALSE AS ThereArePropsInMetadata
	|INTO AttributesForControlTable
	|FROM
	|	#SourceDetailsForControl AS AttributesForControl
	|		LEFT JOIN TTAllAdditionalDetails AS TTAllAdditionalDetails
	|		ON AttributesForControl.Property = TTAllAdditionalDetails.Property
	|WHERE
	|	AttributesForControl.Ref = &ProductKind
	|	AND (AttributesForControl.IsAddlAttribute
	|				AND NOT TTAllAdditionalDetails.Property IS NULL
	|			OR NOT AttributesForControl.IsAddlAttribute)
	|
	|INDEX BY
	|	AttributeName
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.IsAddlAttribute AS IsAddlAttribute,
	|	NestedQuery.AttributeName AS AttributeName,
	|	NestedQuery.Property AS Property,
	|	MAX(NestedQuery.RequiredToFill) AS RequiredToFill,
	|	MAX(NestedQuery.Uniqueness) AS Uniqueness,
	|	MAX(NestedQuery.DisplayWhenCreated) AS DisplayWhenCreated,
	|	MAX(NestedQuery.Use) AS Use,
	|	MAX(NestedQuery.ThereArePropsInMetadata) AS ThereArePropsInMetadata
	|INTO TTForRequest
	|FROM
	|	(SELECT
	|		AttributesForControl.IsAddlAttribute AS IsAddlAttribute,
	|		AttributesForControl.AttributeName AS AttributeName,
	|		AttributesForControl.Property AS Property,
	|		AttributesForControl.RequiredToFill AS RequiredToFill,
	|		AttributesForControl.Uniqueness AS Uniqueness,
	|		AttributesForControl.DisplayWhenCreated AS DisplayWhenCreated,
	|		AttributesForControl.Use AS Use,
	|		FALSE AS ThereArePropsInMetadata
	|	FROM
	|		AttributesForControlTable AS AttributesForControl
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		FALSE,
	|		AllProductDetailsTable.Name,
	|		VALUE(ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef),
	|		AllProductDetailsTable.Required_ToFillIn,
	|		FALSE,
	|		AllProductDetailsTable.RequiredToDisplayWhenCreating,
	|		AllProductDetailsTable.Use,
	|		TRUE
	|	FROM
	|		AllProductDetailsTable AS AllProductDetailsTable) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.IsAddlAttribute,
	|	NestedQuery.AttributeName,
	|	NestedQuery.Property
	|
	|INDEX BY
	|	Property,
	|	AttributeName
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN TTForRequest.ThereArePropsInMetadata
	|			THEN ISNULL(AllProductDetailsTable.Presentation, """")
	|		ELSE ISNULL(AttributesForControlTable.Presentation, """")
	|	END AS Presentation,
	|	TTForRequest.IsAddlAttribute AS IsAddlAttribute,
	|	TTForRequest.AttributeName AS AttributeName,
	|	TTForRequest.Property AS Property,
	|	TTForRequest.RequiredToFill AS RequiredToFill,
	|	TTForRequest.Uniqueness AS Uniqueness,
	|	TTForRequest.DisplayWhenCreated AS DisplayWhenCreated,
	|	TTForRequest.Use AS Use,
	|	TTForRequest.Property.ValueType AS Type,
	|	ISNULL(TTAllAdditionalDetails.Set, VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef)) AS Set,
	|	ISNULL(TTAllAdditionalDetails.IsCommonAttribute, FALSE) AS IsCommonAttribute,
	|	ISNULL(TTAllAdditionalDetails.PropertiesSet, VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef)) AS PropertiesSet
	|FROM
	|	TTForRequest AS TTForRequest
	|		LEFT JOIN TTAllAdditionalDetails AS TTAllAdditionalDetails
	|		ON TTForRequest.Property = TTAllAdditionalDetails.Property
	|		
	|		LEFT JOIN AllProductDetailsTable AS AllProductDetailsTable
	|		ON TTForRequest.AttributeName = AllProductDetailsTable.Name
	|			AND TTForRequest.ThereArePropsInMetadata = TRUE
	|		
	|		LEFT JOIN AttributesForControlTable AS AttributesForControlTable
	|		ON TTForRequest.AttributeName = AttributesForControlTable.AttributeName
	|			AND TTForRequest.ThereArePropsInMetadata = FALSE
	|WHERE
	|	(TTForRequest.IsAddlAttribute
	|			OR TTForRequest.ThereArePropsInMetadata)
	|
	|UNION ALL
	|
	|SELECT
	|	TTAllAdditionalDetails.Property.Presentation	AS Presentation,
	|	TRUE												AS IsAddlAttribute,
	|	TTForRequest.AttributeName							AS AttributeName,
	|	TTAllAdditionalDetails.Property				AS Property,
	|	TTAllAdditionalDetails.RequiredToFill	AS RequiredToFill,
	|	FALSE												AS Uniqueness,
	|	TTAllAdditionalDetails.RequiredToFill	AS DisplayWhenCreated,
	|	TRUE												AS Use,
	|	TTAllAdditionalDetails.Type					AS Type,
	|	TTAllAdditionalDetails.Set					AS Set,
	|	TRUE												AS IsCommonAttribute,
	|	TTAllAdditionalDetails.PropertiesSet			AS PropertiesSet
	|FROM
	|	TTAllAdditionalDetails AS TTAllAdditionalDetails
	|		LEFT JOIN TTForRequest AS TTForRequest
	|		ON TTForRequest.Property = TTAllAdditionalDetails.Property
	|
	|WHERE
	|	TTForRequest.IsAddlAttribute IS NULL";
	
	TempTablesManager = New TempTablesManager;
	
	AllAdditionalDetails_(ProductKind, AttributesOwner, TempTablesManager);
	
	If AttributesOwner = "Products" Then
		AllProductDetailsTable = SettingsValueCached.AllProductDetailsTable(ItemsType,
																								FeatureOfAccountingOrKeyTypesOfProducts,
																								UseVariants,
																								UseShelfLifeOnBatchRegistration);
		//
		QueryText = StrReplace(QueryText, "#SourceDetailsForControl", "Catalog.ItemKinds.AttributesForProductsControl");
	Else
		AllProductDetailsTable = SettingsValueCached.AllDetailsOfProductCharacteristicsTable(ItemsType,
																												FeatureOfAccountingOrKeyTypesOfProducts);
		//
		QueryText = StrReplace(QueryText, "#SourceDetailsForControl", "Catalog.ItemKinds.AttributesForItemVariantsControl");
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("ProductKind", ProductKind);
	Query.SetParameter("AllProductDetailsTable", AllProductDetailsTable);
	Query.TempTablesManager = TempTablesManager;
	
	Table = Query.Execute().Unload();
	
	For Each RowOfTables In Table Do
		If Not RowOfTables.IsAddlAttribute Then
			If AttributesOwner = "Products" Then
				AttributeDetails = PropsDescription(RowOfTables.AttributeName,
													ItemsType,
													FeatureOfAccountingOrKeyTypesOfProducts,
													UseVariants,
													UseShelfLifeOnBatchRegistration);
			Else
				AttributeDetails = Catalogs.ItemsCharacteristics.PropsDescription(RowOfTables.AttributeName,
																							ItemsType,
																							FeatureOfAccountingOrKeyTypesOfProducts);
			EndIf;
			
			RowOfTables.Type = AttributeDetails.Type;
			RowOfTables.Presentation = AttributeDetails.Presentation;
			RowOfTables.Use = AttributeDetails.Use;
			
			RowOfTables.RequiredToFill = RowOfTables.Use
											And (AttributeDetails.Required_ToFillIn
											Or RowOfTables.RequiredToFill);
											
			RowOfTables.DisplayWhenCreated = RowOfTables.Use
											And (RowOfTables.DisplayWhenCreated
												Or AttributeDetails.RequiredToDisplayWhenCreating
												Or RowOfTables.RequiredToFill
												Or RowOfTables.Uniqueness);
		Else
			RowOfTables.DisplayWhenCreated = RowOfTables.DisplayWhenCreated
												Or RowOfTables.RequiredToFill
												Or RowOfTables.Uniqueness;
		EndIf;
	EndDo;
	
	Return Table;
	
EndFunction

// Returns a table of additional details of the item
//
// Parameters:
//  ProductKind			 - CatalogRef.ItemKinds
//  AssigningAdditionalBankingDetails	 - String - Name of the item type (Nomenclature, specificationsof the Nomenclature, seriesof the nomenclature).
//  TempTablesManager	 - Undefined, TempTablesManager -
// 
// Returns:
//  ValueTable - Columns:
//		* AttributeName - String - the name of the property
//		* AttributeRepresentation - String - the caption property
//		* IsAddlAttribute - Boolean - always TRUE
//		* IsCommonAttribute - Boolean - indicates that the additional details are included in the set of Reference_nomenklatura_Common
//		* RequiredToFill - Boolean
//		* PropertiesSet - CatalogRef.AdditionalAttributesAndInfoSets - the set of properties for which the additional props were created
//		* Type - TypeDescription
//
Function AllAdditionalDetails_(ProductKind, AssigningAdditionalBankingDetails, TempTablesManager = Undefined) Export
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		QueryText = 
		"SELECT
		|	VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef) AS Set,
		|	"""" AS AttributeName,
		|	"""" AS AttributeRepresentation,
		|	VALUE(ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef) AS Property,
		|	TRUE AS IsAddlAttribute,
		|	FALSE AS IsCommonAttribute,
		|	FALSE AS RequiredToFill,
		|	FALSE AS MustBeFilledInWithACondition,
		|	FALSE AS VisibleWithACondition,
		|	FALSE AS AvailableWithACondition,
		|	VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef) AS PropertiesSet,
		|	VALUETYPE("""") AS Type 
		|INTO TTAllAdditionalDetails
		|
		|WHERE
		|	FALSE";
		
	Else
		QueryText = 
		"SELECT DISTINCT
		|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Ref AS Property
		|INTO RequiredToFill
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.AdditionalAttributesDependencies AS AdditionalAttributesAndInfoAdditionalAttributesDependencies
		|
		|WHERE
		|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Value = &ProductKind
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.Attribute = ""ProductKind""
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.DependentProperty LIKE ""RequiredToFill""
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.PropertiesSet = &ViewSet
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.Condition = ""Equal""
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.Ref.RequiredToFill
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Ref
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.AdditionalAttributesDependencies AS AdditionalAttributesAndInfoAdditionalAttributesDependencies
		|
		|WHERE
		|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Value = &ProductKind
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.Attribute = ""ProductKind""
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.DependentProperty LIKE ""RequiredToFill""
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.PropertiesSet = &SharedSet
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.Condition = ""InList""
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.Ref.RequiredToFill
		|
		|INDEX BY
		|	Property
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Ref AS Property
		|INTO MustBeFilledInWithACondition
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.AdditionalAttributesDependencies AS AdditionalAttributesAndInfoAdditionalAttributesDependencies
		|
		|WHERE
		|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.PropertiesSet IN (&ViewSet, &SharedSet)
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.Attribute <> ""ProductKind""
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.DependentProperty LIKE ""RequiredToFill""
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.Ref.RequiredToFill
		|
		|INDEX BY
		|	Property
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Ref AS Property
		|INTO isVisible
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.AdditionalAttributesDependencies AS AdditionalAttributesAndInfoAdditionalAttributesDependencies
		|
		|WHERE
		|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.PropertiesSet IN (&ViewSet, &SharedSet)
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.DependentProperty LIKE ""isVisible""
		|
		|INDEX BY
		|	Property
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Ref AS Property
		|INTO Available
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.AdditionalAttributesDependencies AS AdditionalAttributesAndInfoAdditionalAttributesDependencies
		|
		|WHERE
		|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.PropertiesSet IN (&ViewSet, &SharedSet)
		|	AND AdditionalAttributesAndInfoAdditionalAttributesDependencies.DependentProperty LIKE ""Available""
		|
		|INDEX BY
		|	Property
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AdditionalAttributes.Ref AS Set,
		|	AdditionalAttributes.Property.Description AS AttributeName,
		|	AdditionalAttributes.Property.Title AS AttributeRepresentation,
		|	AdditionalAttributes.Property AS Property,
		|	TRUE AS IsAddlAttribute,
		|	CASE
		|		WHEN AdditionalAttributes.Ref = &SharedSet
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IsCommonAttribute,
		|	NOT RequiredToFill.Property IS NULL AS RequiredToFill,
		|	NOT MustBeFilledInWithACondition.Property IS NULL AS MustBeFilledInWithACondition,
		|	NOT isVisible.Property IS NULL AS VisibleWithACondition,
		|	NOT Available.Property IS NULL AS AvailableWithACondition,
		|	AdditionalAttributes.Property.PropertiesSet AS PropertiesSet,
		|	AdditionalAttributes.Property.ValueType AS Type
		|INTO TTAllAdditionalDetails
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AdditionalAttributes
		|		LEFT JOIN RequiredToFill AS RequiredToFill
		|		ON AdditionalAttributes.Property = RequiredToFill.Property
		|		LEFT JOIN Available AS Available
		|		ON AdditionalAttributes.Property = Available.Property
		|		LEFT JOIN isVisible AS isVisible
		|		ON AdditionalAttributes.Property = isVisible.Property
		|		LEFT JOIN MustBeFilledInWithACondition AS MustBeFilledInWithACondition
		|		ON AdditionalAttributes.Property = MustBeFilledInWithACondition.Property
		|
		|WHERE
		|	NOT AdditionalAttributes.DeletionMark
		|	AND (AdditionalAttributes.Ref = &SharedSet
		|			OR AdditionalAttributes.Ref = &ViewSet)";
		
		If AssigningAdditionalBankingDetails = "Products" Then
			SharedSet = "&Set_Catalog_Products_Overall";
			ViewSet  = "CAST(&ProductKind AS Catalog.ItemKinds).PropertiesSet";
		ElsIf AssigningAdditionalBankingDetails = "ItemsCharacteristics" Then
			SharedSet = "&Set_Catalog_ItemsCharacteristics_Overall";
			ViewSet  = "CAST(&ProductKind AS Catalog.ItemKinds).CharacteristicsPropertySet";
		ElsIf AssigningAdditionalBankingDetails = "ItemsBatches" Then
			SharedSet = "&Set_Catalog_ItemsBatches_Overall";
			ViewSet  = "CAST(&ProductKind AS Catalog.ItemKinds).BatchPropertySet";
		EndIf;
		
		QueryText = StrReplace(QueryText, "&SharedSet", SharedSet);
		QueryText = StrReplace(QueryText, "&ViewSet", ViewSet);
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ProductKind", ProductKind);
	Query.SetParameter("Set_Catalog_Products_Overall", PropertyManager.PropertiesSetByName("Catalog_Products_Overall"));
	Query.SetParameter("Set_Catalog_ItemsCharacteristics_Overall", PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"));
	Query.SetParameter("Set_Catalog_ItemsBatches_Overall", PropertyManager.PropertiesSetByName("Catalog_ItemsBatches_Overall"));
	
	
	If TempTablesManager = Undefined Then
		QueryText = StrReplace(QueryText, "INTO TTAllAdditionalDetails", "");
		Query.Text = QueryText;
		
		Return Query.Execute().Unload();
	Else
		QueryText = QueryText + "
		|
		|INDEX BY
		|	Property";
		
		Query.Text = QueryText;
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
		
		Return Undefined;
	EndIf;
	
EndFunction

// Returns a description of the item detail settings.
//
// Parameters:
//	Attribute - MetadataObjectAttribute - details of the Nomenclature reference list.
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//	FeatureOfAccountingOrKeyTypesOfProducts - EnumRef.ItemAccountingFeatures,
//	                                        Reference link.The key of individual products is the peculiarity of item accounting.
//	UseVariants - EnumRef.ItemVariantsUsageOptions, Boolean - 
//		use case for the item or whether characteristics are used.
//	UseShelfLifeOnBatchRegistration - Boolean - indicates whether the expiration date is used in the item series.
//	This requisitecharacteristics is a Boolean attribute that indicates that the details belong to the reference list of characteristics of the Nomenclature.
//
// Returns:
//	See PropertyValuesOfProps.
//
Function PropsDescription(Attribute,
							ItemsType,
							FeatureOfAccountingOrKeyTypesOfProducts,
							UseVariants,
							UseShelfLifeOnBatchRegistration) Export
	
	If TypeOf(Attribute) = Type("String")
		Or TypeOf(Attribute) = Type("MetadataObject") Then
		
		AllProductDetails = SettingsValueCached.AllProductDetails(ItemsType,
																					FeatureOfAccountingOrKeyTypesOfProducts,
																					UseVariants,
																					UseShelfLifeOnBatchRegistration);
		
		If TypeOf(Attribute) = Type("String") Then
			AttributeName = Attribute;
		Else
			AttributeName = Attribute.Name;
		EndIf;
		
		Return AllProductDetails[AttributeName];
	ElsIf TypeOf(Attribute) = Type("FixedStructure") Then
		Return Attribute;
	Else
		ExceptionText = NStr("vi = 'Kiểu giá trị không mong muốn của tham số Mục tin.';
							|ru = 'Неожиданный тип параметра Реквизит.';
							|en = 'Unexpected Attribute parameter type.'; fa = 'Unexpected Attribute parameter type.';
							|it = 'Tipo inaspettato del parametro Requisito.';
							|pl = 'Nieoczekiwany typ parametru Atrybut.';
							|tr = 'Beklenmeyen parametre tipi Öznitelik.'");
		Raise ExceptionText;
	EndIf;
	
EndFunction

// Returns:
// 	ValueTable - Contains:
//		* Name - String - description of props
//		* Presentation - String - 
//		* Type - TypeDescription - 
//		* Required_ToFillIn - Boolean - 
//		* RequiredToDisplayWhenCreating - Boolean - 
//		* RecommendedForUniquenessControl - Boolean - 
//		* Use - Boolean - 
//
Function StructureOfDescriptionOfDetailsInTable(StructureOfDescriptions) Export
	Table = New ValueTable; // See StructureOfDescriptionOfDetailsInTable 
	FirstRow = True;
	
	For Each AttributeDetails In StructureOfDescriptions Do
		
		If FirstRow Then
			For Each Property In AttributeDetails.Value Do
				If TypeOf(Property.Value) = Type("String") Then
					Table.Columns.Add(Property.Key,
						New TypeDescription("String",,New StringQualifiers(255, AllowedLength.Variable)));
				Else
					TypesArray = New Array;
					TypesArray.Add(TypeOf(Property.Value));
					Table.Columns.Add(Property.Key,New TypeDescription(TypesArray));
				EndIf;
			EndDo;
			FirstRow = False;
		EndIf;
		
		NewRow = Table.Add();
		NewRow.Name = AttributeDetails.Key;
		FillPropertyValues(NewRow, AttributeDetails.Value);
	EndDo;
	
	Return Table;
EndFunction

Function AttributesNotToCheck(Object) Export
	
	NotCheckedAttributeArray = New Array;
	
	FeatureOfAccountingOrKeyTypesOfProducts = ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(Object);
	
	BankingDetailsWithRedefinedMandatoryFields = BankingDetailsWithRedefinedMandatoryFields(
															Object.ItemsType,
															FeatureOfAccountingOrKeyTypesOfProducts,
															Object);

	For Each KeyValue In BankingDetailsWithRedefinedMandatoryFields Do
		
		If Not KeyValue.Value Then
			NotCheckedAttributeArray.Add(KeyValue.Key);
		EndIf;
		
	EndDo;
		
	Return NotCheckedAttributeArray;
	
EndFunction

// Returns the names of the details of the item to be used only for Agency services.
//
// Returns:
//	Array of String - the names of the details.
//
Function DetailsOfAgencyServices()
	
	ArrayOfAgencyDetails = New Array;
	
	ArrayOfAgencyDetails.Add("Principal");
	ArrayOfAgencyDetails.Add("Counterparty");
	
	Return ArrayOfAgencyDetails;
	
EndFunction

Function DetailsOfSignsOfAccountingFeatures(ObjectMetadata) Export
	
	DetailsOfSignsOfAccountingFeatures = New Array;
	
	AccountingFeatures = New Array;
	AccountingFeatures.Add(Enums.ItemAccountingFeatures.ContainsPreciousMetalsOrStones);
	
	CommonClientServer.SupplementArray(
		AccountingFeatures,
		Enums.ItemAccountingFeatures.FeaturesOfServiceAccounting());
	
	For Each EnumerationValue In AccountingFeatures Do
		
		EnumerationValueName = Common.EnumerationValueName(EnumerationValue);
		
		If ObjectMetadata.Attributes.Find(EnumerationValueName) <> Undefined Then
			DetailsOfSignsOfAccountingFeatures.Add(EnumerationValueName);
		EndIf;
		
	EndDo;
	
	Return DetailsOfSignsOfAccountingFeatures;
	
EndFunction

// Returns a structure with element visibility.
// Parameters:
//	PassedObject - CatalogObject.Products - item in the nomenclature reference list
//	VisibilityModeShowHighPriorityOnly - Boolean - indicates whether the main details are displayed.
//	VerificationModeForUsingBankingDetails - Boolean - whether to check the use of Bank details.
//
// Returns:
//	Structure - the visibility structure of the elements. The key is the name of the element, the values are visibility.
//
Function UsingElements(PassedObject, VisibilityModeShowHighPriorityOnly, VerificationModeForUsingBankingDetails) Export
	
	NamesOfProductItemDetails = "KeepAccountingByBatch, BatchUsageSettings, UseShelfLifeOnBatchRegistration,"
										+ "LabelsTemplate, PriceTagTemplate";
	If TypeOf(PassedObject.Ref) = Type("CatalogRef.ItemKinds") Then
		Object = TMCommonUse.StructureWithMetadataObjectProperties(Metadata.Catalogs.Products);
		FillPropertyValues(Object, PassedObject);
		ProductKindAttributes = New Structure(NamesOfProductItemDetails);
		FillPropertyValues(ProductKindAttributes, PassedObject);
		Object.ProductKind = PassedObject.Ref;
	Else
		Object = PassedObject;
		ProductKindAttributes = TMCommonUse.DefaultValuesForItemDetails(Object.ProductKind,
																							NamesOfProductItemDetails);
	EndIf;
	
	UsingElements = New Structure;
	
	AnExternalUserIsAuthorized = TMCommonUseClientServer.AnExternalUserIsAuthorized();
	
	#Region FunctionalOptions
	
	UseReusablePackage 			= GetFunctionalOption("UseReusablePackage");
	UseItemVariants 	= GetFunctionalOption("UseItemVariants");
	UseMultipleKindsOfProducts 	= GetFunctionalOption("UseMultipleKindsOfProducts");
	UseItemsBatch 			= GetFunctionalOption("UseItemsBatch"); 
	UseAssemblyDisassembly 				= GetFunctionalOption("UseAssemblyDisassembly");
	UseQualityCertificates 	= GetFunctionalOption("UseQualityCertificates");
	UseProductSegments 		= GetFunctionalOption("UseProductSegments");
	UseProduction 				= GetFunctionalOption("UseProduction");
	UseBinLocationWarehousing			= GetFunctionalOption("UseBinLocationWarehousing");
	UseAdditionalAttributesAndInfo = GetFunctionalOption("UseAdditionalAttributesAndInfo");
	UseBinLocationWarehousingForInformation	= GetFunctionalOption("UseBinLocationWarehousingForInformation");
	UsePurchaseCommission			= GetFunctionalOption("UsePurchaseCommission");
	UseMultipleCompanies		= GetFunctionalOption("UseMultipleCompanies");
	UseItemsSoldTogether = GetFunctionalOption("UseItemsSoldTogether");
	ForecastPackageConsumption		= GetFunctionalOption("ForecastPackageConsumption");
	GenerateFinancialResult			= GetFunctionalOption("GenerateFinancialResult");
	UseAdvancedDemandFulfillment = GetFunctionalOption("UseAdvancedDemandFulfillment");
	UseTermsOfPurchases		= GetFunctionalOption("UseTermsOfPurchases");
	UseGoodsQualityControl     = GetFunctionalOption("UseGoodsQualityControl");
	UseVATAccounting						= GetFunctionalOption("UseVATAccounting");
	UseExcisableGoods           = GetFunctionalOption("UseExcisableGoods");
	UseProductionManagement = GetFunctionalOption("UseProductionManagement");
	#EndRegion
	
	#Region ProductTypeAttributes
	ThisIsAProduct				= (Object.ItemsType = Enums.ItemsTypes.OwnGoods);
	ThisIsMultiTurnContainer	= (Object.ItemsType = Enums.ItemsTypes.ReusablePackage);
	ThisIsWork 				= (Object.ItemsType = Enums.ItemsTypes.Work_5);
	IsService 				= (Object.ItemsType = Enums.ItemsTypes.OperationService);
	IsRecordsSet 				= (Object.ItemsType = Enums.ItemsTypes.Set);
	#EndRegion
	
	#Region SettingUpByProductType
	
	FeatureOfAccountingOrKeyTypesOfProducts = ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(PassedObject);
	
	DetailsSettingsByTypeOfProduct = AttributeSettingTable(Object.ProductKind,
																	Object.ItemsType,
																	FeatureOfAccountingOrKeyTypesOfProducts,
																	Object.UseVariants,
																	ProductKindAttributes.UseShelfLifeOnBatchRegistration,
																	"Products");
	
	FormAttributes = DetailsOfSettingsTableForm();
	
	For Each RowOfTables In DetailsSettingsByTypeOfProduct Do
		AttributeName = RowOfTables.AttributeName;
		If RowOfTables.IsAddlAttribute Then
			If Not VerificationModeForUsingBankingDetails Then
			
				FormItemName = "AdditionalAttributeValue_"
					+ StrReplace(?(RowOfTables.IsCommonAttribute,
							Upper(String(RowOfTables.Set.UUID())),
							Upper(String(RowOfTables.PropertiesSet.UUID()))),
						"-",
						"x")
					+ "_"
					+ StrReplace(Upper(String(RowOfTables.Property.UUID())), "-", "x");
				
				UsingElements.Insert(FormItemName, RowOfTables.Use 
																	And VisibilityOfProps(RowOfTables,
																	AttributeName,
																	VisibilityModeShowHighPriorityOnly,
																	RowOfTables));
			EndIf;
		Else
			If (AttributeName = "SaleRegistrationOption"
					Or AttributeName = "Quality"
					Or AttributeName = "UseVariants")
				And VerificationModeForUsingBankingDetails Then
				
				UsingElements.Insert(AttributeName, True);
				
			Else
				Attribute = ?(FormAttributes.Get(AttributeName) = Undefined, AttributeName, RowOfTables);
				
				UsingElements.Insert(AttributeName, RowOfTables.Use
															And (VerificationModeForUsingBankingDetails
																Or VisibilityOfProps(Attribute,
																				AttributeName,
																				VisibilityModeShowHighPriorityOnly,
																				RowOfTables)));
			EndIf;
		EndIf;
	EndDo;
	
	#EndRegion
	
	#Region FormHeader_
	
	If Not VerificationModeForUsingBankingDetails Then
		UsingElements.Insert("FillInAWorkNameFromTemplate", 	ValueIsFilled(Object.ProductKind));
		UsingElements.Insert("FillInAPrintNameFromTemplate", 	ValueIsFilled(Object.ProductKind));
		
		HyperlinkGoProductBarcodesVisibility = AccessRight("View",
			Metadata.InformationRegisters.ItemsBarcodes)
			And Not VisibilityModeShowHighPriorityOnly
			And ValueIsFilled(Object.Ref);
		
		HyperlinkGoProductsWithSimilarVisibilityProperties = AccessRight("View", 
			Metadata.InformationRegisters.SegmentProducts)
			And Not TMCommonUseClientServer.AnExternalUserIsAuthorized()
			And Not VisibilityModeShowHighPriorityOnly;
		
		UsingElements.Insert("HyperlinkGoToItemBarcodes", 
			HyperlinkGoProductBarcodesVisibility);
		
		UsingElements.Insert("HyperlinkGoToItemWithSimilarProperties",
			HyperlinkGoProductsWithSimilarVisibilityProperties);
	EndIf;
	#EndRegion
	
	#Region LongDesc
	
	If Not VerificationModeForUsingBankingDetails Then
		HyperlinkGoFilesVisibility = AccessRight("View", Metadata.Catalogs.ProductsAttachedFiles)
			And Not VisibilityModeShowHighPriorityOnly;
		
		VisibilityOfImageFileCommands = UsingElements.PicturesFile;
		
		UsingElements.Insert("HyperlinkGoToFiles", HyperlinkGoFilesVisibility);
		
		UsingElements.Insert("AddImage", VisibilityOfImageFileCommands);
		UsingElements.Insert("ClearImage", VisibilityOfImageFileCommands);
		UsingElements.Insert("ChangeImage", ValueIsFilled(Object.Ref));
		UsingElements.Insert("ViewImage", ValueIsFilled(Object.Ref));
		UsingElements.Insert("SelectAnImageFromAttachedFiles", ValueIsFilled(Object.Ref));
		
		HyperlinkGoToProductCertificatesVisibility = UseQualityCertificates
			And Object.KeepRecordsOfQualityCertificates
			And Not VisibilityModeShowHighPriorityOnly
			And AccessRight("View", Metadata.InformationRegisters.QualityCertificateApplicationAreas);
			
		UsingElements.Insert("HyperlinkGoToItemCertificates",
			HyperlinkGoToProductCertificatesVisibility);
	EndIf;
	
	#EndRegion
	
	#Region ManufacturerDetails
	
	If Not VerificationModeForUsingBankingDetails Then
		GoToVisibilityHyperlink = 
			Not VisibilityModeShowHighPriorityOnly
			And FeatureOfAccountingOrKeyTypesOfProducts = Enums.ItemAccountingFeatures.PerformedByPartner
			And AccessRight("View", Metadata.Catalogs.TermsOfPurchaseFromVendors)
			And UseTermsOfPurchases;
			
		UsingElements.Insert("HyperlinkGoToAgreements", GoToVisibilityHyperlink);
	EndIf;
	
	#EndRegion
	
	#Region PlanningAndMarketing
	
	UsingElements.Insert("ProductCategory", ValueIsFilled(Object.ProductKind)
														And Not VisibilityModeShowHighPriorityOnly
														Or VerificationModeForUsingBankingDetails);
	
	If Not VerificationModeForUsingBankingDetails Then
		HyperlinkGoJointSalesVisibility = UseItemsSoldTogether
			And Not IsRecordsSet
			And Not ThisIsMultiTurnContainer
			And AccessRight("View", Metadata.InformationRegisters.ProductsSoldTogether)
			And Not VisibilityModeShowHighPriorityOnly;
		
		HyperlinkGoSegmentsVisibility = UseProductSegments
			And AccessRight("View", Metadata.InformationRegisters.SegmentProducts)
			And Not VisibilityModeShowHighPriorityOnly
			And Not AnExternalUserIsAuthorized;
		
		UsingElements.Insert("HyperlinkGoToJointSales", HyperlinkGoJointSalesVisibility);
		
		UsingElements.Insert("HyperlinkGoToSegments", HyperlinkGoSegmentsVisibility);
	EndIf;
	
	#EndRegion
	
	#Region SupplyAndProduction
	
	If Not VerificationModeForUsingBankingDetails Then
		HyperlinkGoConfigurationOptionsVisibility = UseAssemblyDisassembly
			And Object.ItemsType = Enums.ItemsTypes.OwnGoods
			And AccessRight("View", Metadata.Catalogs.ProductKitConfigurations)
			And Not VisibilityModeShowHighPriorityOnly;
		
		HyperlinkGoSettingUpWaysToEnsureVisibilityNeeds = 
			 UseAdvancedDemandFulfillment
			And (Object.ItemsType = Enums.ItemsTypes.OwnGoods
				Or Object.ItemsType = Enums.ItemsTypes.ReusablePackage)
			And Not VisibilityModeShowHighPriorityOnly
			And AccessRight("View", Metadata.DataProcessors.SettingOfProcurementStrategies);
		
		HyperlinkGoSettingUpInventoryMaintenanceVisibility = UseAdvancedDemandFulfillment
			And (Object.ItemsType = Enums.ItemsTypes.OwnGoods
				Or Object.ItemsType = Enums.ItemsTypes.ReusablePackage)
			And Not VisibilityModeShowHighPriorityOnly
			And AccessRight("View", Metadata.DataProcessors.SetUpStockReplenishment);
		
		HyperlinkGoSettingUpMaterialTransferToProductionVisibility = False;
		
		HyperlinkGoToVisibility = False;
		HyperlinkGoToVisibility = UseProduction
			And Not IsService
			And Not (IsRecordsSet
					And Not ProductDataManagementCached.ItIsAvailableToStoreCompositionOfSetInSpecifications())
			And AccessRight("View", Metadata.CommonForms.ApplyProductsToManufacturing)
			And Not VisibilityModeShowHighPriorityOnly;
		UsingElements.Insert("HyperlinkGoConfigurationOptions", HyperlinkGoConfigurationOptionsVisibility);
		
		UsingElements.Insert("HyperlinkGoToInventoryMaintenanceSettings",
			HyperlinkGoSettingUpInventoryMaintenanceVisibility);
		
		UsingElements.Insert("HyperlinkGoSettingUpWaysToMeetYourNeeds",
			HyperlinkGoSettingUpWaysToEnsureVisibilityNeeds);
			
		UsingElements.Insert("HyperlinkGoSettingUpTheTransferOfMaterialsToProduction",
			HyperlinkGoSettingUpMaterialTransferToProductionVisibility);
		
		UsingElements.Insert("HyperlinkGoToProduction", HyperlinkGoToVisibility);
	EndIf;
	
	#EndRegion
	
	#Region QualityControl
	
	If Not VerificationModeForUsingBankingDetails Then
		ItemVisibility = Object.ControlQualityOfReceivedGoods
			And UsingElements.ControlQualityOfReceivedGoods;
		UsingElements.Insert("TermOfQualityControl", ItemVisibility);
		ItemVisibility = ItemVisibility And UseGoodsQualityControl;
		UsingElements.Insert("IndentationTermOfQualityControlPicture", ItemVisibility);
		UsingElements.Insert("InscriptionControlPeriodDays", ItemVisibility);
	EndIf;
	
	#EndRegion
	
	#Region Prices
	
	If Not VerificationModeForUsingBankingDetails Then
		HyperlinkGoToPriceListOfVisibilityCompany = Not VisibilityModeShowHighPriorityOnly
			And AccessRight("View", Metadata.DataProcessors.PriceList);
		
		HyperlinkGoSupplierPriceListsVisibility = Not IsRecordsSet
			And Not VisibilityModeShowHighPriorityOnly
			And AccessRight("View", Metadata.DataProcessors.VendorPriceLists);
		
		HyperlinkGoCompanyPriceChangeHistoryVisibility = Not VisibilityModeShowHighPriorityOnly
			And AccessRight("View", Metadata.InformationRegisters.ItemsPrices)
			And Not AnExternalUserIsAuthorized;
		
		HyperlinkGoSupplierPriceChangeHistoryVisibility = Not IsRecordsSet
			And Not VisibilityModeShowHighPriorityOnly
			And AccessRight("View", Metadata.InformationRegisters.ItemsPricesOfVendor);
		
		UsingElements.Insert("HyperlinkGoToCompanyPriceList", HyperlinkGoToPriceListOfVisibilityCompany);
		UsingElements.Insert("HyperlinkGoToSupplierPriceLists",
			HyperlinkGoSupplierPriceListsVisibility);
		UsingElements.Insert("HyperlinkGoCompanyPriceChangeHistory",
			HyperlinkGoCompanyPriceChangeHistoryVisibility);
		UsingElements.Insert("HyperlinkGoSupplierPriceChangeHistory",
			HyperlinkGoSupplierPriceChangeHistoryVisibility);
	EndIf;
	
	#EndRegion
	
	#Region PrintPriceTagsAndLabels
	
	If Not VerificationModeForUsingBankingDetails Then
		VisibilityLabelTemplate = UsingElements.LabelsTemplate;
		
		VisibilityOfPriceTagTemplate = UsingElements.PriceTagTemplate;
		
		UsingElements.Insert("UseCommonLabelTemplate", VisibilityLabelTemplate);
		UsingElements.Insert("UseCustomTemplateLabels", VisibilityLabelTemplate);
		UsingElements.Insert("LabelsTemplate",							VisibilityLabelTemplate);
		UsingElements.Insert("ProductKindLabelsTemplate",			ValueIsFilled(ProductKindAttributes.LabelsTemplate)
																				And VisibilityLabelTemplate
																				And Not Object.UseCustomTemplateLabels);
		UsingElements.Insert("ProductKindLabelTemplateNotSpecified",	Not ValueIsFilled(ProductKindAttributes.LabelsTemplate)
																				And VisibilityLabelTemplate
																				And Not Object.UseCustomTemplateLabels);
		
		UsingElements.Insert("UseCommonPriceTagTemplate",	VisibilityOfPriceTagTemplate);
		UsingElements.Insert("UseCustomPriceTagTemplate",	VisibilityOfPriceTagTemplate);
		UsingElements.Insert("PriceTagTemplate",							VisibilityOfPriceTagTemplate);
		UsingElements.Insert("ProductKindPriceTagTemplate",				ValueIsFilled(ProductKindAttributes.PriceTagTemplate)
																				And VisibilityOfPriceTagTemplate
																				And Not Object.UseCustomPriceTagTemplate);
		UsingElements.Insert("ProductKindNoPriceTagTemplateSpecified",		Not ValueIsFilled(ProductKindAttributes.PriceTagTemplate)
																				And VisibilityOfPriceTagTemplate
																				And Not Object.UseCustomPriceTagTemplate);
		
	EndIf;
	#EndRegion
	
	#Region MainAccountingParameters
	
	If Not VerificationModeForUsingBankingDetails Then
		ProductTypeVisibility = UseMultipleKindsOfProducts And Not VisibilityModeShowHighPriorityOnly;
		ProductTypeSwitchVisibility = Not UseMultipleKindsOfProducts And Not VisibilityModeShowHighPriorityOnly;
		TypeOfProductRequiredFieldsVisibility = UseMultipleKindsOfProducts And VisibilityModeShowHighPriorityOnly;
		ProductTypeRadioButtonRequiredFieldsVisibility = Not UseMultipleKindsOfProducts And VisibilityModeShowHighPriorityOnly;
		ProductTypeVisibility_ = UseMultipleKindsOfProducts And Not VisibilityModeShowHighPriorityOnly;
		
		UsingElements.Insert("ProductKind", 								ProductTypeVisibility);
		UsingElements.Insert("ProductKindSwitch", 				ProductTypeSwitchVisibility);
		UsingElements.Insert("ProductKindRequiredFields", 				TypeOfProductRequiredFieldsVisibility);
		UsingElements.Insert("ProductKindSwitchRequiredFields", ProductTypeRadioButtonRequiredFieldsVisibility);
		UsingElements.Insert("ItemsType", 								ProductTypeVisibility_);
		
		UsingVisibilityCharacteristics  = UsingElements.UseVariants
			And Not VisibilityModeShowHighPriorityOnly;
		
		UsingElements.Insert("UseVariants", UsingVisibilityCharacteristics);
		
		HyperlinkGoProductCharacteristicsVisibility = UsingVisibilityCharacteristics
			And AccessRight("View", Metadata.Catalogs.ItemsCharacteristics)
			And Object.UseVariants <> Enums.ItemVariantsUsageOptions.DontUse;
		
		UsingElements.Insert("HyperlinkGoToItemCharacteristics", 
			HyperlinkGoProductCharacteristicsVisibility);
			
		ConfiguringUseOfSeriesVisibility = UseItemsBatch
			And (ThisIsAProduct
				Or ThisIsMultiTurnContainer)
			And Not VisibilityModeShowHighPriorityOnly;
		
		HyperlinkGoToProductsOfDifferentQualityVisibility = UsingElements.Quality
			And AccessRight("View", Metadata.InformationRegisters.AnotherQualityGoods)
			And Not VisibilityModeShowHighPriorityOnly;
		
		HyperlinkToProductVATRates = UseVATAccounting
			And AccessRight("View", Metadata.InformationRegisters.ProductsVATRates)
			And Not VisibilityModeShowHighPriorityOnly;
		
		UsingElements.Insert("BatchUsageSettings", ConfiguringUseOfSeriesVisibility);
		
		UsingElements.Insert("HyperlinkGoSetComposition",
										AccessRight("View", Metadata.Catalogs.ProductKitConfigurations)
										And Object.ItemsType = Enums.ItemsTypes.Set
										And Not VisibilityModeShowHighPriorityOnly);
		
		UsingElements.Insert("HyperlinkGoToOtherQualityProducts",
										HyperlinkGoToProductsOfDifferentQualityVisibility);
		
		UsingElements.Insert("HyperlinkToProductVATRates",
										HyperlinkToProductVATRates);
	EndIf;
	
	#EndRegion
	
	#Region UnitsOfMeasureAndStorageConditions
	VisibilityOfPackageSettings = UsingElements.UsePackages
								And Object.UsePackages
								And (Not VisibilityModeShowHighPriorityOnly
									Or VerificationModeForUsingBankingDetails);
	
	VisibilityReportingUnit = UsingElements.UnitForReports
								And (VerificationModeForUsingBankingDetails 
								Or Not VisibilityModeShowHighPriorityOnly
								And AccessRight("View", Metadata.Catalogs.Products.Attributes.UnitForReports)
								And RightOfAccessToMetadataObjectByDetails("View", 
															Metadata.Catalogs.Products.Attributes.UnitForReports));
	
	CoefficientOfOneForVisibilityReports = VisibilityReportingUnit
											  And ValueIsFilled(Object.UnitForReports)
											  And Object.UnitForReports <> Object.UnitOfMeasure
											  And (Not VisibilityModeShowHighPriorityOnly
											  	Or VerificationModeForUsingBankingDetails);
	
	UsingElements.Insert("UnitForReports", 			 VisibilityReportingUnit);
	UsingElements.Insert("UnitFactorForReports",  CoefficientOfOneForVisibilityReports);
	UsingElements.Insert("ShelfLifeUnitOfMeasure", UsingElements.ExpirationDate_);
	UsingElements.Insert("PackagingGroup", VisibilityOfPackageSettings
									And (Object.PackagingGroup <> Catalogs.PackagingGroups.SpecialForItem
										Or VerificationModeForUsingBankingDetails));
		
	SuppliedInMultiTurnContainerVisibility = UseReusablePackage
		And ThisIsAProduct
		And ValueIsFilled(Object.UnitOfMeasure)
		And Not Object.UsePackages
		And Not Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Object.UnitOfMeasure)
		And (VerificationModeForUsingBankingDetails 
			Or Not VisibilityModeShowHighPriorityOnly
			 	And AccessRight("View", Metadata.Catalogs.Products.Attributes.SuppliedInReusablePackage));
	
	ProductsMultiTurnPackagingVisibility = SuppliedInMultiTurnContainerVisibility 
		And Object.SuppliedInReusablePackage;
	
	CharacteristicMultiTurnPackagingVisibility = ProductsMultiTurnPackagingVisibility
		And ValueIsFilled(Object.ReusablePackageItems) 
		And ItemVariantsAreUsed(Object.ReusablePackageItems);
	
	UsingElements.Insert("SuppliedInReusablePackage", 	SuppliedInMultiTurnContainerVisibility);
	UsingElements.Insert("ReusablePackageItems", 	ProductsMultiTurnPackagingVisibility);
	UsingElements.Insert("ReusablePackageVariant", CharacteristicMultiTurnPackagingVisibility);
	
	If Not VerificationModeForUsingBankingDetails Then
		
		SettingsForCommonSetOfPackagesVisibility = VisibilityOfPackageSettings
												And Object.PackagingGroup <> Catalogs.PackagingGroups.SpecialForItem;
												
		// Details with visibility settings on the interface and depending on the associated fields.
		UsingElements.Insert("SetOfPackagesGeneral", SettingsForCommonSetOfPackagesVisibility
			And AccessRight("View", Metadata.Catalogs.Products.Attributes.PackagingGroup)
			And RightOfAccessToMetadataObjectByDetails("View", Metadata.Catalogs.Products.Attributes.PackagingGroup));
		
		UnitForReportsUnitOfMeasurementLabelVisibility = CoefficientOfOneForVisibilityReports
															And Object.UnitForReports <> Object.UnitOfMeasure
															And Not VisibilityModeShowHighPriorityOnly;
		UsingElements.Insert("UnitForReportsUnitOfMeasurementLabel", 	UnitForReportsUnitOfMeasurementLabelVisibility);
		
		TareAndVisibility = SuppliedInMultiTurnContainerVisibility
			And Object.SuppliedInReusablePackage;
		UsingElements.Insert("TareIndent", 						TareAndVisibility);
		
		HyperlinkGoProductPlacementVisibility =
			(ThisIsAProduct
			Or ThisIsMultiTurnContainer)
			And Not VisibilityModeShowHighPriorityOnly
			And UseBinLocationWarehousingForInformation
			And AccessRight("View", Metadata.InformationRegisters.PlaceProductsInStorageBins);
			
		UsingElements.Insert("HyperlinkGoToItemPlacement",
			HyperlinkGoProductPlacementVisibility);
								
		HyperlinkToProductPackagingVisibility = VisibilityOfPackageSettings
			And Object.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem
			And AccessRight("View", Metadata.Catalogs.PackagesAndUnitsOfMeasure);
		
		HyperlinkGoPackageConsumptionForecastsVisibility = VisibilityOfPackageSettings
			And ForecastPackageConsumption
			And AccessRight("View", Metadata.Catalogs.PackagesAndUnitsOfMeasure)
			And AccessRight("View", Metadata.InformationRegisters.PackageConsumptionForecasts)
			And AccessRight("View", Metadata.InformationRegisters.SettingsOfBinLocationWarehouses);
		
		UsingElements.Insert("HyperlinkToGoPackingSet", 		SettingsForCommonSetOfPackagesVisibility
																				And AccessRight("View", Metadata.Catalogs.PackagesAndUnitsOfMeasure));
		UsingElements.Insert("HyperlinkGoToItemPackaging",	HyperlinkToProductPackagingVisibility);
		
		UsingElements.Insert("HyperlinkGoToPackageConsumptionForecasts",
			HyperlinkGoPackageConsumptionForecastsVisibility);
		
		UsingElements.Insert("PackageSetIndent", 						VisibilityOfPackageSettings);
		UsingElements.Insert("UseOfPackagesIndividualSet", VisibilityOfPackageSettings);
		UsingElements.Insert("UsingPackagesCommonSet", 			VisibilityOfPackageSettings);
	EndIf;
		
	#EndRegion

	#Region AccountingFinancial
		
	If Not VerificationModeForUsingBankingDetails Then
		HyperlinkGoDistributionOfSalesByLineOfBusiness = 
			(ThisIsAProduct
				Or ThisIsMultiTurnContainer
				Or IsService
				Or ThisIsWork)
			And GenerateFinancialResult
			And AccessRight("View", Metadata.InformationRegisters.SetUpAllocationByLinesOfBusiness)
			And Not VisibilityModeShowHighPriorityOnly;
		
		UsingElements.Insert("HyperlinkGoDistributionOfSalesByLineOfBusiness",
			HyperlinkGoDistributionOfSalesByLineOfBusiness);
	EndIf;
	
	#EndRegion
	
	#Region OtherElements
	If Not VerificationModeForUsingBankingDetails Then
		UsingElements.Insert("CheckForUniqueness", 
									VisibilityModeShowHighPriorityOnly
									And Constants.ControlItemUniquenessByCombinationValuesAttributes.Get()
									And Not ValueIsFilled(Object.Ref));
	EndIf;
	#EndRegion
	
	#Region Reports
	
	If Not VerificationModeForUsingBankingDetails Then
		UsingElements.Insert("CompanyGoodsStock", (ThisIsAProduct
				Or ThisIsMultiTurnContainer
				Or ThisIsWork)
			And (UseMultipleCompanies
				Or UsePurchaseCommission)
			And AccessRight("View", Metadata.Reports.CompanyGoodsStock));
		
		UsingElements.Insert("ItemsBatchList", (ThisIsAProduct
				Or ThisIsMultiTurnContainer)
			And ProductKindAttributes.KeepAccountingByBatch
			And AccessRight("View", Metadata.Reports.ItemsBatchList));
		
		UsingElements.Insert("WarehouseStock", (ThisIsAProduct
				Or ThisIsMultiTurnContainer)
			And AccessRight("View", Metadata.Reports.WarehouseStock));
		
		UsingElements.Insert("GoodsInStorageBins", (ThisIsAProduct
				Or ThisIsMultiTurnContainer)
			And UseBinLocationWarehousing
			And AccessRight("View", Metadata.Reports.WarehouseStock));
		
		UsingElements.Insert("StockAvailability", (ThisIsAProduct
				Or ThisIsMultiTurnContainer)
			And AccessRight("View", Metadata.Reports.StockAvailability));
		
		UsingElements.Insert("GoodsInWarehousesByShelfLives", (ThisIsAProduct
				Or ThisIsMultiTurnContainer)
			And ProductKindAttributes.KeepAccountingByBatch
			And ProductKindAttributes.UseShelfLifeOnBatchRegistration
			And AccessRight("View", Metadata.Reports.GoodsInWarehousesByShelfLives));
		
		UsingElements.Insert("RevenueAndCOGS",
			AccessRight("View", Metadata.Reports.RevenueAndCOGS));
		
		UsingElements.Insert("ProductRangeState",
			AccessRight("View", Metadata.Reports.ProductRangeState));
	EndIf;
	#EndRegion
	
	#Region ExciseTaxGroup
	
	If Not VerificationModeForUsingBankingDetails Then
		
		If ThisIsAProduct Then
			TableOfCategories = ExcisableGoodsAccounting.ExcisableItemCategories(Object.Ref);
			HasCategory = ValueIsFilled(TableOfCategories)
				And ValueIsFilled(TableOfCategories[0].ExcisableGoodsCategory);
			If HasCategory Then
				ThereIsStory = True;
			Else
				CategoryHistoryTable = ExcisableGoodsAccounting.GetHistoryOfItemCategories(Object.Ref);
			ThereIsStory = 
				ValueIsFilled(CategoryHistoryTable)
				And (ValueIsFilled(CategoryHistoryTable[0].ExcisableGoodsCategory)
					Or CategoryHistoryTable.Count() > 1);
			EndIf;
		Else
			HasCategory = False;
			ThereIsStory = False;
		EndIf;
		
		UsingElements.Insert("GroupCategory", ThisIsAProduct And UseExcisableGoods);
		UsingElements.Insert("HyperlinkGoToCurrentExciseCategoryOfItem", ThisIsAProduct
			And UseExcisableGoods);
		UsingElements.Insert("HyperlinkGoExciseCategoriesOfItems", ThisIsAProduct
			And UseExcisableGoods
			And ThereIsStory);
		UsingElements.Insert("GroupDescriptionOfExciseCategory", ThisIsAProduct
			And UseExcisableGoods
			And HasCategory);
			
	EndIf;
	#EndRegion
		
	ProductsLocalization.UsingElements(UsingElements, Object, VisibilityModeShowHighPriorityOnly, VerificationModeForUsingBankingDetails);
	
	Return UsingElements;
	
EndFunction

// Returns a structure with the titles of the items.
// Parameters:
//	Object - CatalogObject.Products - item in the nomenclature reference list
//	Structuraladjustment - Structure - structure-of-sight items.
//
// Returns:
//	Structure - the structure of the element headers, the key is the element name, the values are the header, contains:
//		* UnitOfMeasure - String
//		* AgencyServicesGroup - String
//		* DecorationSoftware - String
//		* HyperlinkGoConfigurationOptions - String
//		* HyperlinkGoToOtherQualityProducts - String
//		* HyperlinkGoToItemBarcodes - String
//		* HyperlinkGoSetComposition - String
//		* HyperlinkGoSetCompositionAttention - String
//		* HyperlinkGoToItemCharacteristics- String
//		* HyperlinkGoToItemPackaging - String
//		* HyperlinkToGoPackingSet - String
//		* HyperlinkForProductPackagingAttention - String
//		* HyperlinkGoPackingSetAttention - String
//		* HyperlinkGoCertificatesProductsAttention - String
//		* HyperlinkGoToItemCertificates - String
//		* HyperlinkGoToPreciousMaterials - String
//		* HyperlinkGoToFiles - String
//		* HyperlinkGoToSegments - String
//		* HyperlinkGoToAgreements - String
//		* HyperlinkToProductVATRates - String
//		* HyperlinkGoExciseCategoriesOfItems - String
//		* HyperlinkGoToCurrentExciseCategoryOfItem - String
//		* DescriptionOfExciseCategory - String
//
Function ItemsTitles(Object, VisibilityOfElements)
	
	ItemsTitles = New Structure;
	
	#Region ProductTypeAttributes
	
	ThisIsAProduct				= (Object.ItemsType = Enums.ItemsTypes.OwnGoods);
	ThisIsMultiTurnContainer 	= (Object.ItemsType = Enums.ItemsTypes.ReusablePackage);
	ThisIsWork 				= (Object.ItemsType = Enums.ItemsTypes.Work_5);
	IsService 				= (Object.ItemsType = Enums.ItemsTypes.OperationService);
	IsRecordsSet 				= (Object.ItemsType = Enums.ItemsTypes.Set);
	
	#EndRegion
	
	CharacteristicsUsed = Object.UseVariants <> Enums.ItemVariantsUsageOptions.DontUse;
	
	ItemsTitles.Insert("UnitOfMeasure", ?(ThisIsAProduct Or ThisIsMultiTurnContainer,
															NStr("vi = 'Đơn vị lưu kho';
																|ru = 'Единица хранения';
																|en = 'Stock UOM'; fa = 'واحد انبار';
																|it = 'Unità di stoccaggio';
																|pl = 'Jednostka magazynowa';
																|tr = 'Stok ölçü birimi'"),
															NStr("vi = 'Đơn vị tính';
																|ru = 'Единица измерения';
																|en = 'Unit of measure'; fa = 'واحد اندازه‌گیری';
																|it = 'Unità di misura';
																|pl = 'Jednosta miary';
																|tr = 'Ölçü birimi'")));
															
	If ThisIsWork Then
		ItemsTitles.Insert("AgencyServicesGroup", NStr("vi = 'Công việc được thực hiện theo hợp đồng đại lý';
														|ru = 'Работа выполняется по агентскому договору';
														|en = 'Work is performed under the agency agreement'; fa = 'Work is performed under the agency agreement';
														|it = 'Il lavoro viene eseguito in base ad un accordo di agenzia';
														|pl = 'Praca jest wykonywana w ramach umowy agencyjnej';
														|tr = 'İş, acentelik sözleşmesi kapsamında yürütülür'"));
	Else
		ItemsTitles.Insert("AgencyServicesGroup", NStr("vi = 'Dịch vụ được cung cấp theo hợp đồng đại lý';
														|ru = 'Услуга реализуется по агентскому договору';
														|en = 'The service is rendered under agency agreement'; fa = 'خدمت بر اساس قرارداد عاملیت ارائه می‌شود';
														|it = 'Il servizio viene erogato in base ad un accordo di agenzia';
														|pl = 'Usługa jest świadczona w ramach umowy agencyjnej';
														|tr = 'Hizmet, acentelik sözleşmesi kapsamında gerçekleştirilmektedir'"));
	EndIf;
	
	If Not GetFunctionalOption("UseProduction") Then
		ItemsTitles.Insert("DecorationSoftware", NStr("vi = 'Đảm bảo';
														|ru = 'Обеспечение';
														|en = 'Supply'; fa = 'Supply';
														|it = 'Approvvigionamento';
														|pl = 'Supply';
														|tr = 'Tedarik'"));
	Else
		ItemsTitles.Insert("DecorationSoftware", NStr("vi = 'Đảm bảo và sản xuất';
														|ru = 'Обеспечение и производство';
														|en = 'Supply and production'; fa = 'تأمین و تولید';
														|it = 'Approvvigionamento e produzione';
														|pl = 'Zaspokojenie i produkcja';
														|tr = 'Tedarik ve üretim'"));
	EndIf;
	
	#Region HyperlinkHeaders
	
	WarningPicture = PictureLib.WarningStartingFromRowBeginning;
	
	QueryTexts = New ValueList;
	
	If SectionIsVisible("HyperlinkGoToOtherQualityProducts", VisibilityOfElements) Then
		QueryText =
		"SELECT
		|	AnotherQualityGoods.Products AS Products,
		|	AnotherQualityGoods.OtherQualityGoods AS OtherQualityGoods,
		|	AnotherQualityGoods.QualityGradation AS QualityGradation
		|FROM
		|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
		|WHERE
		|	AnotherQualityGoods.Products = &Products";
		QueryTexts.Add(QueryText, "HyperlinkGoToOtherQualityProducts");
	EndIf;

	If SectionIsVisible("HyperlinkGoToItemBarcodes", VisibilityOfElements) Then
		QueryText =
		"SELECT
		|	ItemsBarcodes.Barcode AS Barcode,
		|	ItemsBarcodes.Products AS Products,
		|	ItemsBarcodes.Characteristic AS Characteristic,
		|	ItemsBarcodes.Package AS Package
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|WHERE
		|	ItemsBarcodes.Products = &Products";
		QueryTexts.Add(QueryText, "HyperlinkGoToItemBarcodes");
	EndIf;
	
	If SectionIsVisible("HyperlinkGoSetComposition", VisibilityOfElements) Then
		QueryText =
		"SELECT
		|	ConfigurationOptionsForProductRange.LineNumber AS LineNumber
		|FROM
		|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
		|WHERE
		|	NOT &CharacteristicsUsed
		|	AND ConfigurationOptionsForProductRange.Ref = &ItemKitConfiguration
		|	AND NOT ConfigurationOptionsForProductRange.Ref.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	ProductKitConfigurations.Ref AS Ref
		|FROM
		|	Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|WHERE
		|	&CharacteristicsUsed
		|	AND ProductKitConfigurations.Owner = &Products
		|	AND NOT ProductKitConfigurations.Ref.DeletionMark";
		QueryTexts.Add(QueryText, "HyperlinkGoSetComposition");
	EndIf;
	
	If SectionIsVisible("HyperlinkGoConfigurationOptions", VisibilityOfElements) Then
		QueryText =
		"SELECT
		|	ProductKitConfigurations.Ref AS Ref
		|FROM
		|	Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|WHERE
		|	ProductKitConfigurations.Owner = &Products
		|	AND NOT ProductKitConfigurations.DeletionMark";
		QueryTexts.Add(QueryText, "HyperlinkGoConfigurationOptions");
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToItemCharacteristics", VisibilityOfElements) Then
		QueryText =
		"SELECT
		|	ItemsCharacteristics.Ref AS Ref
		|FROM
		|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|WHERE
		|	ItemsCharacteristics.Owner = &TechnicalCharacteristics
		|	AND NOT ItemsCharacteristics.DeletionMark";
		QueryTexts.Add(QueryText, "HyperlinkGoToItemCharacteristics");
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToItemPackaging", VisibilityOfElements)
		Or SectionIsVisible("HyperlinkToGoPackingSet", VisibilityOfElements) Then
		QueryText =
		"SELECT
		|	PackagesAndUnitsOfMeasure.Ref AS Ref
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
		|WHERE
		|	PackagesAndUnitsOfMeasure.Owner = &PackageOwner
		|	AND NOT PackagesAndUnitsOfMeasure.DeletionMark";
		QueryTexts.Add(QueryText, "HyperlinkGoPackagingProductsOrHyperlinkGoPackagingSet");
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToItemCertificates", VisibilityOfElements) Then
		QueryText =
		"SELECT
		|	QualityCertificateApplicationAreas.QualityCertificate AS QualityCertificate
		|FROM
		|	InformationRegister.QualityCertificateApplicationAreas AS QualityCertificateApplicationAreas
		|WHERE
		|	QualityCertificateApplicationAreas.ProductKind = &ProductKind
		|	AND (QualityCertificateApplicationAreas.Products = &Products
		|			OR QualityCertificateApplicationAreas.Products = VALUE(Catalog.Products.EmptyRef))
		|	AND NOT QualityCertificateApplicationAreas.QualityCertificate.DeletionMark
		|	AND QualityCertificateApplicationAreas.QualityCertificate.Status = VALUE(Enum.StatusesOfQualityCertificates.Valid_)";
		QueryTexts.Add(QueryText, "HyperlinkGoToItemCertificates");
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToFiles", VisibilityOfElements) Then
		QueryText =
		"SELECT
		|	ProductsAttachedFiles.Ref AS Ref
		|FROM
		|	Catalog.ProductsAttachedFiles AS ProductsAttachedFiles
		|WHERE
		|	ProductsAttachedFiles.FileOwner = &Products
		|	AND NOT ProductsAttachedFiles.DeletionMark";
		QueryTexts.Add(QueryText, "HyperlinkGoToFiles");
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToSegments", VisibilityOfElements) Then
		QueryText =
		"SELECT DISTINCT
		|	SegmentProducts.Segment AS Segment
		|FROM
		|	InformationRegister.SegmentProducts AS SegmentProducts
		|WHERE
		|	SegmentProducts.Products = &Products";
		QueryTexts.Add(QueryText, "HyperlinkGoToSegments");
		
		QueryText =
		"SELECT TOP 1
		|	ProductSegments.Ref AS Segment,
		|	ProductSegments.EmployeeResponsible AS EmployeeResponsible,
		|	ProductSegments.GenerationMethod AS GenerationMethod
		|FROM
		|	Catalog.ProductSegments AS ProductSegments
		|WHERE
		|	NOT ProductSegments.IsFolder
		|	AND NOT ProductSegments.DeletionMark
		|	AND ProductSegments.GenerationMethod = VALUE(Enum.SegmentGenerationMethods.GenerateDynamically)";
		QueryTexts.Add(QueryText, "HyperlinkGoSegmentsFormDynamically");
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToAgreements", VisibilityOfElements) Then
		
		QueryText =
		"SELECT
		|	COUNT(DISTINCT TermsOfPurchaseFromVendors.Ref) AS NumberOfAgreements
		|INTO NumberOfServiceAgreements
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
		|WHERE
		|	NOT &CharacteristicsUsed
		|	AND TermsOfPurchaseFromVendors.Partner = &Partner
		|	AND (TermsOfPurchaseFromVendors.Counterparty = &Counterparty
		|		OR (NOT &CounterpartiesAreUsed
		|			OR TermsOfPurchaseFromVendors.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)))
		|	AND TermsOfPurchaseFromVendors.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
		|	AND TermsOfPurchaseFromVendors.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
		|	AND (TermsOfPurchaseFromVendors.ValidityStartDate = DATETIME(1, 1, 1)
		|		OR TermsOfPurchaseFromVendors.ValidityStartDate <= &CurrentDate)
		|	AND (TermsOfPurchaseFromVendors.ValidityEndDate = DATETIME(1, 1, 1)
		|		OR TermsOfPurchaseFromVendors.ValidityEndDate >= &CurrentDate)
		|
		|HAVING
		|	COUNT(DISTINCT TermsOfPurchaseFromVendors.Ref) > 0";
		
		QueryTexts.Add(QueryText, "NumberOfServiceAgreements");
		
		QueryText =
		"SELECT DISTINCT
		|	COUNT(DISTINCT TermsOfPurchaseFromVendors.Ref) AS NumberOfAgreements,
		|	MAX(NOT TSAgentServices.Ref IS NULL
		|		OR NOT TermsOfPurchaseFromVendors.UseSpecifiedAgentServices) AS ThereAreConventionsOnProduct
		|INTO ServiceAgreements_
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
		|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS TSAgentServices
		|		ON TermsOfPurchaseFromVendors.Ref = TSAgentServices.Ref
		|			AND TSAgentServices.Products = &Products
		|WHERE
		|	NOT &CharacteristicsUsed
		|	AND TermsOfPurchaseFromVendors.Partner = &Partner
		|	AND (TermsOfPurchaseFromVendors.Counterparty = &Counterparty
		|		OR (NOT &CounterpartiesAreUsed
		|			OR TermsOfPurchaseFromVendors.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)))
		|	AND TermsOfPurchaseFromVendors.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
		|	AND TermsOfPurchaseFromVendors.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
		|	AND (TermsOfPurchaseFromVendors.ValidityStartDate = DATETIME(1, 1, 1)
		|		OR TermsOfPurchaseFromVendors.ValidityStartDate <= &CurrentDate)
		|	AND (TermsOfPurchaseFromVendors.ValidityEndDate = DATETIME(1, 1, 1)
		|		OR TermsOfPurchaseFromVendors.ValidityEndDate >= &CurrentDate)
		|	AND (NOT TSAgentServices.Ref IS NULL
		|		OR NOT TermsOfPurchaseFromVendors.UseSpecifiedAgentServices)
		|
		|HAVING
		|	COUNT(DISTINCT TermsOfPurchaseFromVendors.Ref) > 0";
		
		QueryTexts.Add(QueryText, "ServiceAgreements_");
		
		QueryText =
		"SELECT
		|	ISNULL(ServiceAgreements_.NumberOfAgreements, NumberOfServiceAgreements.NumberOfAgreements) AS NumberOfAgreements,
		|	ISNULL(ServiceAgreements_.ThereAreConventionsOnProduct, FALSE) AS ThereAreConventionsOnProduct
		|FROM
		|	NumberOfServiceAgreements AS NumberOfServiceAgreements
		|		FULL JOIN ServiceAgreements_ AS ServiceAgreements_
		|		ON TRUE";
		
		QueryTexts.Add(QueryText, "HyperlinkGoConventionsAreNotUsed");
		
		QueryText =
		"SELECT
		|	COUNT(DISTINCT TermsOfPurchaseFromVendors.Ref) AS NumberOfAgreements,
		|	ISNULL(MAX(NOT TSAgentServices.Ref IS NULL
		|			OR NOT TermsOfPurchaseFromVendors.UseSpecifiedAgentServices),
		|		FALSE) AS ThereAreConventionsOnProduct
		|FROM
		|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
		|		ON ItemsCharacteristics.Principal = TermsOfPurchaseFromVendors.Partner
		|			AND (ItemsCharacteristics.Counterparty = TermsOfPurchaseFromVendors.Counterparty
		|				OR TermsOfPurchaseFromVendors.Counterparty = VALUE(Catalog.Counterparties.EmptyRef))
		|		
		|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS TSAgentServices
		|		ON TermsOfPurchaseFromVendors.Ref = TSAgentServices.Ref
		|			AND TSAgentServices.Products = &Products
		|			AND TSAgentServices.Characteristic = ItemsCharacteristics.Ref
		|WHERE
		|	&CharacteristicsUsed
		|	AND ISNULL(ItemsCharacteristics.Owner, UNDEFINED) = &TechnicalCharacteristics
		|	AND NOT ISNULL(ItemsCharacteristics.DeletionMark, FALSE)
		|	AND TermsOfPurchaseFromVendors.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
		|	AND TermsOfPurchaseFromVendors.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
		|	AND (TermsOfPurchaseFromVendors.ValidityStartDate = DATETIME(1, 1, 1)
		|		OR TermsOfPurchaseFromVendors.ValidityStartDate <= &CurrentDate)
		|	AND (TermsOfPurchaseFromVendors.ValidityEndDate = DATETIME(1, 1, 1)
		|		OR TermsOfPurchaseFromVendors.ValidityEndDate >= &CurrentDate)
		|	AND (NOT TSAgentServices.Ref IS NULL
		|		OR NOT TermsOfPurchaseFromVendors.UseSpecifiedAgentServices)";
		
		QueryTexts.Add(QueryText, "HyperlinkGoConventionsUsedCharacteristics");
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Products",				Object.Ref);
	Query.SetParameter("Partner",					Object.Principal);
	Query.SetParameter("Counterparty",					Object.Counterparty);
	Query.SetParameter("CounterpartiesAreUsed",	ValueIsFilled(Object.Counterparty));
	Query.SetParameter("ProductKind",			Object.ProductKind);
	Query.SetParameter("CurrentDate",				BegOfDay(CurrentSessionDate()));
	Query.SetParameter("CharacteristicsUsed",	CharacteristicsUsed);
	
	If SectionIsVisible("HyperlinkGoSetComposition", VisibilityOfElements) Then 
		ItemKitConfiguration = SetsServerCall.DefaultProductConfigurationOption(
											Object.Ref,
											Catalogs.ItemsCharacteristics.EmptyRef());
		Query.SetParameter("ItemKitConfiguration", ItemKitConfiguration);
	Else
		Query.SetParameter("ItemKitConfiguration", Catalogs.ProductKitConfigurations.EmptyRef());
	EndIf;	
	
	Query.SetParameter("ItemKitConfiguration", ItemKitConfiguration);
	
	If Object.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems Then
		TechnicalCharacteristics = Object.Ref;
	ElsIf Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
		TechnicalCharacteristics = Object.ProductKind;
	ElsIf Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
		TechnicalCharacteristics = Object.ItemVariantsOwner;
	EndIf;
	Query.SetParameter("TechnicalCharacteristics", TechnicalCharacteristics);
	
	If Object.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem Then
		PackageOwner = Object.Ref;
	Else 
		PackageOwner = Object.PackagingGroup;
	EndIf;
	Query.SetParameter("PackageOwner", PackageOwner);
		
	SetPrivilegedMode(True);
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts,,True);
	SetPrivilegedMode(False);
	
	If SectionIsVisible("HyperlinkGoToOtherQualityProducts", VisibilityOfElements) Then
		Count = Tables.HyperlinkGoToOtherQualityProducts.Count();
		HyperlinkHeader = New FormattedString(NStr("vi = 'Hàng hóa có chất lượng khác';
													|ru = 'Товары другого качества';
													|en = 'Nonconforming products'; fa = 'محصولات نامنطبق';
													|it = 'Prodotti di un''altra qualità';
													|pl = 'Wiersze pozycji innej jakości';
													|tr = 'Farklı kalitede olan ürünler'") 
																+ " (" + Count + ")",,,,"GoodsOfDifferentQualityQuantity");
		ItemsTitles.Insert("HyperlinkGoToOtherQualityProducts", HyperlinkHeader);
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToItemWithSimilarProperties", VisibilityOfElements) Then
		HyperlinkHeader = New FormattedString(NStr("vi = 'Mặt hàng với thuộc tính tương tự';
													|ru = 'Номенклатура с аналогичными свойствами';
													|en = 'Items with similar properties'; fa = 'اقلام با خاصیت‌های مشابه';
													|it = 'Articoli con proprietà simili';
													|pl = 'Towary z analogicznymi właściwościami';
													|tr = 'Benzer özelliklere sahip öğe'"),
															,
															,
															,
															"ProductsWithSimilarProperties");
		ItemsTitles.Insert("HyperlinkGoToItemWithSimilarProperties", HyperlinkHeader);
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToItemBarcodes", VisibilityOfElements) Then
		Count = Tables.HyperlinkGoToItemBarcodes.Count();
		HyperlinkHeader = New FormattedString(NStr("vi = 'Mã vạch';
													|ru = 'Штрихкоды';
													|en = 'Barcodes'; fa = 'بارکدها';
													|it = 'Codici a barre';
													|pl = 'Kody kreskowe';
													|tr = 'Barkodlar'") + " (" + Count + ")",,,,"ItemsBarcodesCount");
		ItemsTitles.Insert("HyperlinkGoToItemBarcodes", HyperlinkHeader);
	EndIf;
	
	If SectionIsVisible("HyperlinkGoSetComposition", VisibilityOfElements) Then
		Count = Tables.HyperlinkGoSetComposition.Count();
		If Count <> 0 Then
			HyperlinkName = ?(CharacteristicsUsed, "CustomizeSet", "SetComposition");
			HyperlinkHeader = New FormattedString(NStr("vi = 'Thành phần bộ sản phẩm';
														|ru = 'Состав набора';
														|en = 'Set content'; fa = 'محتوای مجموعه';
														|it = 'Composizione del set';
														|pl = 'Skład zestawu';
														|tr = 'Set kapsamı'") + " (" + Count + ")",,,,HyperlinkName);
		Else
			HyperlinkHeader = New FormattedString(New FormattedString(NStr("vi = 'Tùy chỉnh bộ sản phẩm';
																			|ru = 'Настроить набор';
																			|en = 'Configure set'; fa = 'Configure set';
																			|it = 'Impostare l''insieme';
																			|pl = 'Skonfiguruj zestaw';
																			|tr = 'Seti ayarla'"),,,,"CustomizeSet"),
																New FormattedString(" ", WarningPicture));
		EndIf;
		ItemsTitles.Insert("HyperlinkGoSetComposition", HyperlinkHeader);
		VisibilityOfElements.Insert("HyperlinkGoSetCompositionAttention", Count = 0);
	ElsIf SectionIsVisible("HyperlinkGoConfigurationOptions", VisibilityOfElements) Then
		Count = Tables.HyperlinkGoConfigurationOptions.Count();
		HyperlinkHeader = New FormattedString(NStr("vi = 'Phương án đóng bộ';
													|ru = 'Варианты комплектации';
													|en = 'Kit configurations'; fa = 'پیکربندی‌های کیت';
													|it = 'Variazioni delle dotazioni';
													|pl = 'Warianty kompletacji';
													|tr = 'Ürün seti seçenekleri'") + " (" + Count + ")",,,,"KitConfigurations");
		ItemsTitles.Insert("HyperlinkGoConfigurationOptions", HyperlinkHeader);
		VisibilityOfElements.Insert("HyperlinkGoSetCompositionAttention", False);
	Else
		VisibilityOfElements.Insert("HyperlinkGoSetCompositionAttention", False);
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToItemCharacteristics", VisibilityOfElements) Then
		NumberOfCharacteristics = Tables.HyperlinkGoToItemCharacteristics.Count();
		HyperlinkHeader = New FormattedString(NStr("vi = 'Danh sách';
													|ru = 'Список';
													|en = 'List'; fa = 'فهرست';
													|it = 'Elenco';
													|pl = 'Lista';
													|tr = 'Liste'") + " (" + NumberOfCharacteristics + ")",,,,"ItemsCharacteristics");
		ItemsTitles.Insert("HyperlinkGoToItemCharacteristics", HyperlinkHeader);
	Else
		NumberOfCharacteristics = 0;
	EndIf;
		
	If SectionIsVisible("HyperlinkGoToItemPackaging", VisibilityOfElements) 
			Or SectionIsVisible("HyperlinkToGoPackingSet", VisibilityOfElements) Then 
		Count = Tables.HyperlinkGoPackagingProductsOrHyperlinkGoPackagingSet.Count();
		If Count <> 0 Then 
			HyperlinkHeader = New FormattedString(NStr("vi = 'Danh sách';
														|ru = 'Список';
														|en = 'List'; fa = 'فهرست';
														|it = 'Elenco';
														|pl = 'Lista';
														|tr = 'Liste'") + " (" + Count + ")",,,,"ProductPackages");
			VisibilityOfElements.Insert("HyperlinkForProductPackagingAttention", False);
		Else
			HyperlinkHeader = New FormattedString(
				New FormattedString(NStr("vi = 'Danh sách';
										|ru = 'Список';
										|en = 'List'; fa = 'فهرست';
										|it = 'Elenco';
										|pl = 'Lista';
										|tr = 'Liste'") + " (" + Count + ")",,,,"ProductPackages"));
			VisibilityOfElements.Insert("HyperlinkForProductPackagingAttention", 
				Object.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem);
		EndIf;
		ItemsTitles.Insert("HyperlinkGoToItemPackaging", HyperlinkHeader);
		If Count <> 0 Then 
			HyperlinkHeader = New FormattedString(NStr("vi = 'Danh sách';
														|ru = 'Список';
														|en = 'List'; fa = 'فهرست';
														|it = 'Elenco';
														|pl = 'Lista';
														|tr = 'Liste'") + " (" + Count + ")",,,,"SetPackaging");
			VisibilityOfElements.Insert("HyperlinkGoPackingSetAttention", False);
		Else
			HyperlinkHeader = New FormattedString(
				New FormattedString(NStr("vi = 'Danh sách';
										|ru = 'Список';
										|en = 'List'; fa = 'فهرست';
										|it = 'Elenco';
										|pl = 'Lista';
										|tr = 'Liste'") + " (" + Count + ")",,,,"SetPackaging"));
			VisibilityOfElements.Insert("HyperlinkGoPackingSetAttention", 
				Object.PackagingGroup <> Catalogs.PackagingGroups.SpecialForItem);
		EndIf;
		ItemsTitles.Insert("HyperlinkToGoPackingSet", HyperlinkHeader);
	Else
		VisibilityOfElements.Insert("HyperlinkForProductPackagingAttention", False);
		VisibilityOfElements.Insert("HyperlinkGoPackingSetAttention", False);
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToItemCertificates", VisibilityOfElements) Then
		Count = Tables.HyperlinkGoToItemCertificates.Count();
		If Count <> 0 Then 
			HyperlinkHeader = New FormattedString(NStr("vi = 'Danh sách';
														|ru = 'Список';
														|en = 'List'; fa = 'فهرست';
														|it = 'Elenco';
														|pl = 'Lista';
														|tr = 'Liste'") + " (" + Count + ")",,,,"QualityCertificates");
			VisibilityOfElements.Insert("HyperlinkGoCertificatesProductsAttention", False);
		Else
			HyperlinkHeader = New FormattedString(
				New FormattedString(NStr("vi = 'Danh sách';
										|ru = 'Список';
										|en = 'List'; fa = 'فهرست';
										|it = 'Elenco';
										|pl = 'Lista';
										|tr = 'Liste'") + " (" + Count + ")",,,,"QualityCertificates"));
			VisibilityOfElements.Insert("HyperlinkGoCertificatesProductsAttention", True);
		EndIf;
		ItemsTitles.Insert("HyperlinkGoToItemCertificates", HyperlinkHeader);
	Else 
		VisibilityOfElements.Insert("HyperlinkGoCertificatesProductsAttention", False);
	EndIf;
		
	If SectionIsVisible("HyperlinkGoToPreciousMaterials", VisibilityOfElements) Then
		Count = Object.PreciousMetalsAndStones.Count();
		HyperlinkHeader = New FormattedString(NStr("vi = 'Thành phần của vật liệu quý';
													|ru = 'Содержание драгоценных материалов';
													|en = 'Precious material content'; fa = 'محتوای مواد قیمتی';
													|it = 'Contenuto dei materiali preziosi';
													|pl = 'Zawartość wartościowych materiałów';
													|tr = 'Değerli malzemelerin içeriği'") 
																+ " (" + Count + ")",,,,"PreciousMetalsAndStones");
		ItemsTitles.Insert("HyperlinkGoToPreciousMaterials", HyperlinkHeader);
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToFiles", VisibilityOfElements) Then
		Count = Tables.HyperlinkGoToFiles.Count();
		HyperlinkHeader = New FormattedString(NStr("vi = 'Tệp';
													|ru = 'Файлы';
													|en = 'Files'; fa = 'فایل‌ها';
													|it = 'File';
													|pl = 'Pliki';
													|tr = 'Dosyalar'") + " (" + Count + ")",,,,"Files");
		ItemsTitles.Insert("HyperlinkGoToFiles", HyperlinkHeader);		
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToSegments", VisibilityOfElements) Then
		Segments = Tables.HyperlinkGoToSegments.UnloadColumn("Segment");
	
		ThereAreDynamicSegments = Tables.HyperlinkGoSegmentsFormDynamically.Count() > 0;
		TextDynamicSegments = ?(ThereAreDynamicSegments, NStr("vi = ', không tính các phân khúc đã lập động';
																|ru = ', без учета формируемых динамически';
																|en = ', except for those generated dynamically'; fa = ', except for those generated dynamically';
																|it = ', escluso quelli generati dinamicamente';
																|pl = ', bez uwzględnienia tworzonych dynamicznie';
																|tr = ', dinamik olarak oluşturulan olmaksızın'"), "");
			
		Count = Segments.Count();
		If Count = 1 Then
			HyperlinkHeader = New FormattedString(NStr("vi = 'Phân khúc';
														|ru = 'Сегмент';
														|en = 'Segment'; fa = 'بخش';
														|it = 'Segmento';
														|pl = 'Segment';
														|tr = 'Segment'") + " " + Segments[0] + TextDynamicSegments,,,,"Segments");
		Else
			HyperlinkHeader = New FormattedString(NStr("vi = 'Phân khúc';
														|ru = 'Сегменты';
														|en = 'Segments'; fa = 'بخش‌ها';
														|it = 'Segmenti';
														|pl = 'Segmenty';
														|tr = 'Segmentler'") + " (" + Count + TextDynamicSegments + ")",,,,"Segments");
		EndIf;
		ItemsTitles.Insert("HyperlinkGoToSegments", HyperlinkHeader);
	EndIf;
	
	If SectionIsVisible("HyperlinkGoToAgreements", VisibilityOfElements) Then
		
		TableOfAgreements			= ?(CharacteristicsUsed,
											Tables.HyperlinkGoConventionsUsedCharacteristics,
											Tables.HyperlinkGoConventionsAreNotUsed);
		NumberOfAgreements			= ?(TableOfAgreements.Count() > 0,
											TableOfAgreements[0].NumberOfAgreements,
											0);
		ThereAreConventionsOnProduct	= ?(TableOfAgreements.Count() > 0,
											TableOfAgreements[0].ThereAreConventionsOnProduct,
											False);
		
		If AccessRight("Insert", Metadata.Catalogs.TermsOfPurchaseFromVendors) Then
			
			If NumberOfAgreements = 0
				And Not ThereAreConventionsOnProduct Then
				
				If CharacteristicsUsed Then
					HyperlinkTitleBar	= NStr("vi = 'Chưa chọn đặc tính trong thỏa thuận';
												|ru = 'Характеристики не выбраны в соглашениях';
												|en = 'Variants are not selected in agreements'; fa = 'Variants are not selected in agreements';
												|it = 'Caratteristiche non selezionate negli accordi';
												|pl = 'Charakterystyki nie zostały wybrane w porozumieniach';
												|tr = 'Anlaşmalarda varyantlar seçilmedi'");
					AgreementHyperlink		= "ListOfAgreementsByCharacteristics";
				Else
					HyperlinkTitleBar	= NStr("vi = 'Tạo thỏa thuận';
												|ru = 'Создать соглашение';
												|en = 'Create agreement'; fa = 'ایجاد توافق‌نامه';
												|it = 'Creare un accordo';
												|pl = 'Nowa umowa';
												|tr = 'Anlaşma oluştur'");
					AgreementHyperlink		= "AgreementsToCreate";
				EndIf;
				
			Else
				
				If ThereAreConventionsOnProduct Then
					
					StringOfAgreements = StringWithNumber(";%1 agreement_;;%1 agreements;%1 agreements;%1 agreements",
													NumberOfAgreements,
													NumericValueType.Cardinal,
													"L=ru");
					
					HyperlinkTitleBar = NStr("vi = 'Đã chọn trong %NumberOfAgreements%';
											|ru = 'Выбрана в %NumberOfAgreements%';
											|en = 'Selected in %NumberOfAgreements%'; fa = 'Selected in %NumberOfAgreements%';
											|it = 'Selezionato in %NumberOfAgreements%';
											|pl = 'Wybrano w %NumberOfAgreements%';
											|tr = '%NumberOfAgreements%''de seçildi'");
					HyperlinkTitleBar = StrReplace(HyperlinkTitleBar, "%NumberOfAgreements%", StringOfAgreements);
				Else
					HyperlinkTitleBar = NStr("vi = 'Chọn trong thỏa thuận hiện có';
											|ru = 'Выбрать в существующем соглашении';
											|en = 'Select in the existing agreement'; fa = 'Select in the existing agreement';
											|it = 'Selezionare in un accordo esistente';
											|pl = 'Wybierz w istniejącym porozumieniu';
											|tr = 'Mevcut anlaşmada seç'");
				EndIf;
				
				If CharacteristicsUsed Then
					AgreementHyperlink = "ListOfAgreementsByCharacteristics";
				Else
					AgreementHyperlink = ?(ThereAreConventionsOnProduct, "ListOfAgreementsByProductName", "AgreementsToChoose");
				EndIf;
				
			EndIf;
			
		Else
			
			If NumberOfAgreements = 0 Then
				If CharacteristicsUsed Then
					HyperlinkTitleBar	= NStr("vi = 'Chưa chọn đặc tính trong thỏa thuận';
												|ru = 'Характеристики не выбраны в соглашениях';
												|en = 'Variants are not selected in agreements'; fa = 'Variants are not selected in agreements';
												|it = 'Caratteristiche non selezionate negli accordi';
												|pl = 'Charakterystyki nie zostały wybrane w porozumieniach';
												|tr = 'Anlaşmalarda varyantlar seçilmedi'");
				Else
					HyperlinkTitleBar	= NStr("vi = 'Chưa chọn trong thỏa thuận';
												|ru = 'Не выбрана в соглашениях';
												|en = 'Not selected in agreements'; fa = 'Not selected in agreements';
												|it = 'Non selezionato negli accordi';
												|pl = 'Nie wybrano w uzgadnianiach';
												|tr = 'Anlaşmalarda seçilmedi'");
				EndIf;
			Else
				StringOfAgreements = StringWithNumber(";%1 agreement_;;%1 agreements;%1 agreements;%1 agreements",
												NumberOfAgreements,
												NumericValueType.Cardinal,
												"L=ru");
				
				HyperlinkTitleBar = NStr("vi = 'Đã chọn trong %NumberOfAgreements%';
										|ru = 'Выбрана в %NumberOfAgreements%';
										|en = 'Selected in %NumberOfAgreements%'; fa = 'Selected in %NumberOfAgreements%';
										|it = 'Selezionato in %NumberOfAgreements%';
										|pl = 'Wybrano w %NumberOfAgreements%';
										|tr = '%NumberOfAgreements%''de seçildi'");
				HyperlinkTitleBar = StrReplace(HyperlinkTitleBar, "%NumberOfAgreements%", StringOfAgreements);
			EndIf;
			
			If CharacteristicsUsed Then
				AgreementHyperlink = "ListOfAgreementsByCharacteristics";
			Else
				AgreementHyperlink = "ListOfAgreementsByProductName";
			EndIf;
			
		EndIf;
		
		HyperlinkHeader = New FormattedString(HyperlinkTitleBar, , , , AgreementHyperlink);
		
		AgreementHeader = New Structure;
		AgreementHeader.Insert("Title",	HyperlinkHeader);
		AgreementHeader.Insert("Hyperlink",	AgreementHyperlink);
		
		ItemsTitles.Insert("HyperlinkGoToAgreements", AgreementHeader);
		
	EndIf;
	
	If SectionIsVisible("HyperlinkToProductVATRates", VisibilityOfElements) Then
		
		Count = 0;
		If ValueIsFilled(Object.Ref) Then
			TableOfVATRates = InformationRegisters.ProductsVATRates.TableOfProductVATRates(Object.Ref);
			Count = TableOfVATRates.Count();
		EndIf;
		
		TitleText = NStr("vi = 'Tất cả thuế suất (%1)';
						|ru = 'Все ставки (%1)';
						|en = 'All rates (%1)'; fa = 'All rates (%1)';
						|it = 'Tutte le aliquote (%1)';
						|pl = 'Wszystkie stawki (%1)';
						|tr = 'Tüm oranlar (%1)'");
		TitleText = StrReplace(TitleText, "%1", Count);
		
		HyperlinkHeader = New FormattedString(TitleText, , , , "ProductsVATRates");
		
		ItemsTitles.Insert("HyperlinkToProductVATRates", HyperlinkHeader);
	EndIf;

	If SectionIsVisible("HyperlinkGoExciseCategoriesOfItems", VisibilityOfElements) Then
		
		TitleText = "";
		Count = 0;
		If ValueIsFilled(Object.Ref) Then
			ExciseDutyTable = ExcisableGoodsAccounting.GetHistoryOfItemCategories(Object.Ref);
			Count = ExciseDutyTable.Count();
		EndIf;
		If Count > 0 Then
			TitleText = NStr("vi = 'Lịch sử các hàng hóa tiêu thụ đặc biệt (%1)';
							|ru = 'История категорий (%1)';
							|en = 'Category history (%1)'; fa = 'Category history (%1)';
							|it = 'Category history (%1)';
							|pl = 'Category history (%1)';
							|tr = 'Kategorilerin geçmişi (%1)'");
			TitleText = StrReplace(TitleText, "%1", Count);
		EndIf;
		
		HyperlinkHeader = New FormattedString(TitleText, , , , "ExcisableGoodsCategories");
		
		ItemsTitles.Insert("HyperlinkGoExciseCategoriesOfItems", HyperlinkHeader);
		
	EndIf;

	If SectionIsVisible("HyperlinkGoToCurrentExciseCategoryOfItem", VisibilityOfElements) Then
		
		Count = 0;
		DescriptionTitleText = "";
		If ValueIsFilled(Object.Ref) Then
			TableOfCategories = ExcisableGoodsAccounting.ExcisableItemCategories(Object.Ref);
			Count = TableOfCategories.Count();
		EndIf;
		
		If Count = 0 Then
			TitleText = NStr("vi = '<Hàng hóa chịu thuế tiêu thụ đặc biệt>';
							|ru = '<Неподакцизный товар>';
							|en = '<Non-excisable goods>'; fa = '<Non-excisable goods>';
							|it = '<Non-excisable goods>';
							|pl = '<Non-excisable goods>';
							|tr = '<Tüketim vergisine tabi olmayan ürün>'");
			HyperlinkHeader = New FormattedString(TitleText, , , , "NewItemCategory");
		ElsIf Not ValueIsFilled(TableOfCategories[0].ExcisableGoodsCategory) Then
			If GetFunctionalOption("BaseVersion") Then
				TitleText = NStr("vi = '<Hàng hóa chịu thuế TTĐB>';
								|ru = '<Подакцизный товар>';
								|en = '<Excisable goods>'; fa = '<Excisable goods>';
								|it = '<Excisable goods>';
								|pl = '<Excisable goods>';
								|tr = '<Tüketim vergisine tabi ürün>'");
			Else
				TitleText = NStr("vi = '<Hàng hóa chịu thuế tiêu thụ đặc biệt. Chỉ ra thể loại>';
								|ru = '<Подакцизный товар. Указать категорию>';
								|en = '<Excisable goods. Specify category>'; fa = '<Excisable goods. Specify category>';
								|it = '<Excisable goods. Specify category>';
								|pl = '<Excisable goods. Specify category>';
								|tr = '<Tüketim vergisine tabi ürün. Kategori belirt>'");
			EndIf;
			HyperlinkHeader = New FormattedString(TitleText, , , , "NewItemCategory");
		ElsIf Count = 1 Then
			TitleText = String(TableOfCategories[0].ExcisableGoodsCategory);
			HyperlinkHeader = New FormattedString(TitleText, , , , "CurrentExciseCategoryOfItem");
			If TableOfCategories[0].RateType = Enums.TypesOfExcisableCategoryRates.FixedRate Then
				DescriptionTitleText = String(TableOfCategories[0].Rate1) + " " + String(TableOfCategories[0].Currency)
					+ " " + NStr("vi = 'trong';
								|ru = 'за';
								|en = 'for'; fa = 'برای';
								|it = 'for';
								|pl = 'for';
								|tr = 'için'") + " " + String(TableOfCategories[0].UnitOfMeasure);
			ElsIf TableOfCategories[0].RateType = Enums.TypesOfExcisableCategoryRates.AdValoremRate Then
				DescriptionTitleText = NStr("vi = 'Thuế hải quan';
											|ru = 'Адвалорная ставка';
											|en = 'Ad valorem rate'; fa = 'Ad valorem rate';
											|it = 'Ad valorem rate';
											|pl = 'Ad valorem rate';
											|tr = 'Ad valorem oranı'");
			EndIf;
		Else
			TitleText = NStr("vi = 'Thể loại (%1)';
							|ru = 'Категории (%1)';
							|en = 'Categories (%1)'; fa = 'Categories (%1)';
							|it = 'Categories (%1)';
							|pl = 'Categories (%1)';
							|tr = 'Kategoriler (%1)'");
			TitleText = StrReplace(TitleText, "%1", Count);
			HyperlinkHeader = New FormattedString(TitleText, , , , "CurrentExciseCategoryOfItem");
		EndIf;
		
		ItemsTitles.Insert("HyperlinkGoToCurrentExciseCategoryOfItem", HyperlinkHeader);
		ItemsTitles.Insert("DescriptionOfExciseCategory", DescriptionTitleText);
		
	EndIf;

	#EndRegion
	
	ProductsLocalization.ItemsTitles(ItemsTitles, Object, VisibilityOfElements);
	
	Return ItemsTitles;

EndFunction

// Parameters:
// 	ItemHeader - String, FormattedString - See ItemsTitles 
// 					 - Structure - contains - See ItemsTitles:
// 					 	* Value - Structure:
// 					 		** Title - String
// Returns:
// 	String - Title
//
Function HyperlinkHeader(ItemHeader) Export
	If TypeOf(ItemHeader.Value) = Type("String") 
		Or TypeOf(ItemHeader.Value) = Type("FormattedString") Then
		Return ItemHeader.Value;
	Else
		Return ItemHeader.Value.Title;
	EndIf;	
EndFunction

Procedure RedefineObligationToFillInDetailsOfMeasure(Object, BankingDetailsWithRedefinedMandatoryFields, Measure)
	
	DetailsOfMeasure = DetailsOfMeasure(Measure);
	
	If Object = Undefined Then
		BankingDetailsWithRedefinedMandatoryFields.Insert(DetailsOfMeasure.Numerator, False);
		BankingDetailsWithRedefinedMandatoryFields.Insert(DetailsOfMeasure.Denominator, False);
	Else
		BankingDetailsWithRedefinedMandatoryFields.Insert(DetailsOfMeasure.Numerator, Object[DetailsOfMeasure.Use]);
		BankingDetailsWithRedefinedMandatoryFields.Insert(DetailsOfMeasure.Denominator, Object[DetailsOfMeasure.Use]);
	EndIf;
	
EndProcedure

Procedure DependenceOfMeasureDetailsOnTypeOfProduct(AttributesTable, Attributes, ItemsType, Measure)
	
	ThisIsAProduct 				= (ItemsType = Enums.ItemsTypes.OwnGoods);
	ThisIsMultiTurnContainer 	= (ItemsType = Enums.ItemsTypes.ReusablePackage);
	
	DetailsOfMeasure = DetailsOfMeasure(Measure);
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes[DetailsOfMeasure.UnitOfMeasure];
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes[DetailsOfMeasure.Denominator];
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes[DetailsOfMeasure.CanBeSpecifiedInDocuments];
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes[DetailsOfMeasure.Numerator];
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes[DetailsOfMeasure.Use];
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
								
EndProcedure

Procedure AddPropertyValue(PropertiesTable, Properties, Prefix, ColumnName, Value)
	PropertyName = TrimAll(StandardSubsystemsServer.TransformAdaptedColumnDescriptionToString(Mid(ColumnName, StrLen(Prefix) + 1)));
	Property = Properties.Get(PropertyName); // ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
	If Property <> Undefined Then
		NewPropertiesRow = PropertiesTable.Add();
		NewPropertiesRow.Property = Property.Ref;
		NewPropertiesRow.Value = Value;
	EndIf;
EndProcedure

Procedure CompleteAllDetailsWithDetailsOfForm(AllAttributes)
	
	// Description of the Form Attributes Barcode
	PropertyValues = PropertyValuesOfProps();
	PropertyValues.Name = "Barcode";
	PropertyValues.Use = True;
	PropertyValues.Presentation = NStr("vi = 'Mã vạch';
										|ru = 'Штрихкод';
										|en = 'Barcode'; fa = 'بارکد';
										|it = 'Barcode';
										|pl = 'Barcode';
										|tr = 'Barkod'");
	PropertyValues.Required_ToFillIn = False;
	PropertyValues.Type = New TypeDescription("String", , New StringQualifiers(200, AllowedLength.Variable));
	PropertyValues.RequiredToDisplayWhenCreating = True;
	PropertyValues.RecommendedForUniquenessControl =
		Not GetFunctionalOption("UseNonUniqueItemBarcodes");
	
	AllAttributes.Insert(PropertyValues.Name, New FixedStructure(PropertyValues));
	
EndProcedure

#EndRegion

#Region InfobaseUpdate


#EndRegion

#EndRegion

#EndIf

#Else
Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	StandardProcessing = False;
	Fields.Add("Description");
EndProcedure
#EndIf
