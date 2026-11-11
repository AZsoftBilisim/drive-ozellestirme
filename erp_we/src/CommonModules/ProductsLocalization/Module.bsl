#Region Private

#Region ProductKind

Procedure RelationshipOfFeaturesOfAccountingForIFIS(RelationshipOfFeaturesOfAccountingForIFIS) Export
	
	Return;
	
EndProcedure

Procedure HintOnAccountingForProducts(ToolTipText, AccountingFeature) Export
	
	Return;
	
EndProcedure

// Parameters:
// 	DetailsOfSettingUpSpecifyingSeries - Array of String
//
Procedure DetailsOfSettingUpSpecifyingSeries(DetailsOfSettingUpSpecifyingSeries) Export
	
	DetailsOfSettingUpSpecifyingSeries.Add("CIMSPMSNumber");
	DetailsOfSettingUpSpecifyingSeries.Add("UseUSAISManufacturerBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("UseCertificate2USAISBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("UseManufacturerVetISBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("UseWarehouseJournalRecordVetISBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("UseVetISLotIDBatch");
	DetailsOfSettingUpSpecifyingSeries.Add("MRCMOTP");
	
	Return;
	
EndProcedure

Procedure DescriptionOfUseOfSeriesProps(DescriptionsOfUseOfSeriesProps, SeriesUseSettings) Export
	
	DescriptionUsingPropsSeries = Catalogs.ItemKinds.DescriptionUsingPropsSeries();
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
	
	DescriptionUsingPropsSeries = Catalogs.ItemKinds.DescriptionUsingPropsSeries();
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
	
	DescriptionUsingPropsSeries = Catalogs.ItemKinds.DescriptionUsingPropsSeries();
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
	
	DescriptionUsingPropsSeries = Catalogs.ItemKinds.DescriptionUsingPropsSeries();
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
	
	DescriptionUsingPropsSeries = Catalogs.ItemKinds.DescriptionUsingPropsSeries();
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
	
	DescriptionUsingPropsSeries = Catalogs.ItemKinds.DescriptionUsingPropsSeries();
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
	
	DescriptionUsingPropsSeries = Catalogs.ItemKinds.DescriptionUsingPropsSeries();
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
	DescriptionUsingPropsSeries.Use = False;
	DescriptionUsingPropsSeries.CheckUniquenessOfValue = True;
	DescriptionUsingPropsSeries.CheckFilling = False;
	DescriptionsOfUseOfSeriesProps.Add(DescriptionUsingPropsSeries);
	
EndProcedure

Function ValuesOfDetailsAreStrictlyFilledInBySpecificsOfAccounting(FeatureOfAccountingOrKeyTypesOfProducts) Export
	
	If TheseAreUSAISManufacturedProducts(FeatureOfAccountingOrKeyTypesOfProducts) Then
		Result = New Structure;
		Result.Insert("AlcoholContainingProducts", True);
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AutomaticSeriesGenerationIsProvided(AutomaticSeriesGenerationIsProvided, SeriesUseSettings) Export
	
	
	Return;
	
EndProcedure

// Fills the item in the list of Nomenclature types with default values.
// 
// Parameters:
// 	ProductKind - CatalogObject.ItemKinds - object reference
Procedure FillInDetailsOfDefaultProductType(ProductKind) Export
	
	
	Return;
	
EndProcedure

#EndRegion

#Region Products

Procedure BankingDetailsThatCanTBeEditedInGroupProcessingProducts(NotAttributesToEdit) Export
	
	Return;
	
EndProcedure

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Parameters:
// 	AttributesToLock - Array of String - names of blocked Bank details
// 
Procedure GetObjectAttributesToLock(AttributesToLock) Export
	
	AttributesToLock.Add("KeepRecordsByCCD");
	AttributesToLock.Add("TracedGoods");
	AttributesToLock.Add("TransferProductBatchIDMaterial");
	AttributesToLock.Add("Operations0");
	AttributesToLock.Add("ItemParticipatesInActivityAtRateOfNDS0");
	AttributesToLock.Add("SubjectToVATAtCustomer");
	
	AttributesToLock.Add("AlcoholContainingProductsOpenPackage");
	
	Return;
	
EndProcedure

// Parameters:
// 	StrictlyTakenOutOfSight - Array of String
// 	FilledInOnlyWhenCreatingProducts - Array of String
// 	AreOverfilledIfTheirValuesWereEqualToDefaultValues - Array of String
// 	RefilledIfTheyWerenTFilledInBefore - Array of String
// 	DefaultValues - Structure
//
Procedure FillInDetailsForTypeOfProduct(StrictlyTakenOutOfSight,
		FilledInOnlyWhenCreatingProducts,
		AreOverfilledIfTheirValuesWereEqualToDefaultValues,
		RefilledIfTheyWerenTFilledInBefore,
		DefaultValues) Export
	
	FilledInOnlyWhenCreatingProducts.Add("KeepRecordsByCCD");
	FilledInOnlyWhenCreatingProducts.Add("ImportedAlcoholContainingProducts");
	FilledInOnlyWhenCreatingProducts.Add("SubjectToVATAtCustomer");
	
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("KindOfAlcoholContainingProducts");
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("Strength");
	AreOverfilledIfTheirValuesWereEqualToDefaultValues.Add("CodeForSection7OfVATDeclaration");
	
	CommonClientServer.SupplementArray(AreOverfilledIfTheirValuesWereEqualToDefaultValues,
												DetailsOfAllRussianClassifiers());
	
	Return;
	
EndProcedure

Procedure WorkOutLogicOfConnectionDetails(Products) Export
	
	If ValueIsFilled(Products.ProductKind)
		And Not Common.ObjectAttributeValue(Products.ProductKind, "ContainsPreciousMetalsOrStones") Then
		
		Products.PreciousMetalsAndStones.Clear();
		
	EndIf;
	
	
EndProcedure

// Fills in the values of import accounting details and traceability according to the nomenclature data.
//
// Parameters:
//	Products - CatalogObject.Products, FormDataStructure - the item item being processed.
//	TraceabilityDetails - See ProductsClientServer.DefaultTraceabilityDetails.
//
Procedure FillInImportAndTraceabilityDetails(Products, TraceabilityDetails) Export
	
	ProductsClientServerLocalization.FillInImportAndTraceabilityDetails(Products,
																					TraceabilityDetails);
	
EndProcedure

Function ValueTextIsNotFilledIn(SectionName) Export
	
	If SectionName = "KindOfAlcoholContainingProducts" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указаны>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificati>';
					|pl = '<nie określone>';
					|tr = '<belirtilmeyenler>'");
	ElsIf SectionName = "ManufacturerImporterConterparty" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указаны>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificati>';
					|pl = '<nie określone>';
					|tr = '<belirtilmeyenler>'");
	ElsIf SectionName = "BusinessActivityClassifierCode" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указаны>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificati>';
					|pl = '<nie określone>';
					|tr = '<belirtilmeyenler>'");
	ElsIf SectionName = "BusinessActivityClassifierCode2" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указаны>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificati>';
					|pl = '<nie określone>';
					|tr = '<belirtilmeyenler>'");
	ElsIf SectionName = "RNCPCode" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указаны>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificati>';
					|pl = '<nie określone>';
					|tr = '<belirtilmeyenler>'");
	ElsIf SectionName = "RNCTEAPS2Code" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указаны>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificati>';
					|pl = '<nie określone>';
					|tr = '<belirtilmeyenler>'");
	ElsIf SectionName = "CodeByKindsOfBusinessActivityClassifier" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указаны>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificati>';
					|pl = '<nie określone>';
					|tr = '<belirtilmeyenler>'");
	ElsIf SectionName = "ProductClassificationTypeCode" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указаны>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificati>';
					|pl = '<nie określone>';
					|tr = '<belirtilmeyenler>'");
	ElsIf SectionName = "TRUCode" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указаны>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificati>';
					|pl = '<nie określone>';
					|tr = '<belirtilmeyenler>'");
	ElsIf SectionName = "Operations0" Then
		Return NStr("vi = '<chưa chỉ định>';
					|ru = '<не указаны>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificati>';
					|pl = '<nie określone>';
					|tr = '<belirtilmeyenler>'");
	EndIf;
	
	Return "";
	
EndFunction

// Parameters:
// 	TabularDocumentRight - SpreadsheetDocument
// 	Object - CatalogObject.Products
// 	VisibilityAndHeaderSettings - See Catalogs.Products.VisibilityAndHeaderSettings
// 	ForPrint - Boolean
//
Procedure OutputChapters(TabularDocumentRight, Object, VisibilityAndHeaderSettings, ForPrint) Export
	
	
	Return;
	
EndProcedure

// Parameters:
// 	BankingDetailsDisabledByFederalDistrict - Array of String
// 
Procedure BankingDetailsDisabledByFederalDistrict(BankingDetailsDisabledByFederalDistrict) Export
	
	LocalizationRFService                          = GetFunctionalOption("LocalizationRFService");
	UseImportedGoods            = GetFunctionalOption("UseImportedGoods");
	UseImports           = GetFunctionalOption("UseImports");
	UseSalesForExport           = GetFunctionalOption("UseSalesForExport");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Date(1, 1, 1));
	UseProductClassifiers_ = GetFunctionalOption("UseProductClassifiers");
	UseOldClassifiers       = GetFunctionalOption("OutdatedClassifierUsageRNCPAndRNCEA");
	UseAccountingOfPreciousMaterial = False;
	
	EnterInformationForDeclarationsOfAlcoholicProducts = False;
	TradeManagement = GetFunctionalOption("TradeManagement");
	
	UseSalesAtRateOf0 = False;
	
	VATAccountingSettings = VATAccountingERP.AccountingSettings();
	UseVATDeclarationSection7Filling = VATAccountingSettings.UseVATDeclarationSection7Filling;
	TransactionsWithGoodsSubjectToBuyerSPersonalIncomeTax  = VATAccountingSettings.SellGoodsSubjectToVATAtCustomer 
		Or VATAccountingSettings.BuyGoodsSubjectToVATAtCustomer;
	
	If Not UseVATDeclarationSection7Filling Then
		BankingDetailsDisabledByFederalDistrict.Add("CodeForSection7OfVATDeclaration");
	EndIf;
	
	If Not TransactionsWithGoodsSubjectToBuyerSPersonalIncomeTax Then
		BankingDetailsDisabledByFederalDistrict.Add("SubjectToVATAtCustomer");
	EndIf;
	
	If Not EnterInformationForDeclarationsOfAlcoholicProducts Then
		CommonClientServer.SupplementArray(BankingDetailsDisabledByFederalDistrict, DetailsOfAlcoholicBeverages());
	EndIf;
	
	If Not (UseImports
		Or UseSalesForExport
		Or UseTraceableImportedGoodsAccounting) Then
		
		BankingDetailsDisabledByFederalDistrict.Add("FEACNCode");
		
	EndIf;
	
	If Not UseSalesAtRateOf0 Then
		BankingDetailsDisabledByFederalDistrict.Add("Operations0");
	EndIf;
	
	If Not UseImportedGoods Then
		BankingDetailsDisabledByFederalDistrict.Add("KeepRecordsByCCD");
	EndIf;
	
	If Not UseTraceableImportedGoodsAccounting Then
		BankingDetailsDisabledByFederalDistrict.Add("TracedGoods");
	EndIf;
	
	If Not UseTraceableImportedGoodsAccounting
		Or TradeManagement Then
		BankingDetailsDisabledByFederalDistrict.Add("TransferProductBatchIDMaterial");
	EndIf;
	
	If Not UseProductClassifiers_ Then
		CommonClientServer.SupplementArray(BankingDetailsDisabledByFederalDistrict, DetailsOfAllRussianClassifiers());
		
		BankingDetailsDisabledByFederalDistrict.Add("ProductClassificationTypeCode");
	ElsIf Not UseOldClassifiers Then
		BankingDetailsDisabledByFederalDistrict.Add("BusinessActivityClassifierCode");
		BankingDetailsDisabledByFederalDistrict.Add("RNCPCode");
	EndIf;
	
	If Not UseAccountingOfPreciousMaterial Then
		BankingDetailsDisabledByFederalDistrict.Add("PreciousMetalsAndStones");
	EndIf;
	
	If Not LocalizationRFService Then
		BankingDetailsDisabledByFederalDistrict.Add("CodeByKindsOfBusinessActivityClassifier");
	EndIf;
	
	Return;
	
EndProcedure

// Parameters:
// 	RequiredBankingDetailsDisplayedDuringCreation - Array of String
// 	ItemsType - EnumRef.ItemsTypes
// 	FeatureOfAccountingOrKeyTypesOfProducts - EnumRef.ItemAccountingFeatures
//
Procedure RequiredBankingDetailsDisplayedDuringCreation(RequiredBankingDetailsDisplayedDuringCreation, ItemsType, FeatureOfAccountingOrKeyTypesOfProducts) Export
	
	RequiredBankingDetailsDisplayedDuringCreation.Add("KeepRecordsByCCD");
	RequiredBankingDetailsDisplayedDuringCreation.Add("TracedGoods");
	RequiredBankingDetailsDisplayedDuringCreation.Add("TransferProductBatchIDMaterial");
	
	Return;
	
EndProcedure

Procedure BankingDetailsWithRedefinedMandatoryFields(BankingDetailsWithRedefinedMandatoryFields, ItemsType, FeatureOfAccountingOrKeyTypesOfProducts, Object) Export
	BankingDetailsWithRedefinedMandatoryFields.Insert("PreciousMetalsAndStones.Placement", False);
	If Object <> Undefined Then
		BankingDetailsWithRedefinedMandatoryFields.Insert("FEACNCode", Object.TracedGoods);
	EndIf;
	
EndProcedure

// Parameters:
// 	DetailsNotDisplayedInSettingsTable - Array of String
// 
Procedure DetailsNotDisplayedInSettingsTable(DetailsNotDisplayedInSettingsTable) Export
	
	DetailsNotDisplayedInSettingsTable.Add("SubjectToMineralExtractionTaxAtRate");
	DetailsNotDisplayedInSettingsTable.Add("DeleteRNCEA2Code");
	DetailsNotDisplayedInSettingsTable.Add("ProductsUnderVetISControl");
	
	Return;
	
EndProcedure

// Parameters:
// 	UnusedPropsForUniquenessControl - Array of String
// 
Procedure UnusedPropsForUniquenessControl(UnusedPropsForUniquenessControl) Export
	
	UnusedPropsForUniquenessControl.Add("PreciousMetalsAndStones");
	
	Return;
	
EndProcedure

Procedure TypesNotUsedForFillingAndSelectionControl(TypesNotUsedForFillingAndSelectionControl) Export
	
	Return;
	
EndProcedure

Procedure RecommendedPropsForUniquenessControl(RecommendedPropsForUniquenessControl, ItemsType, FeatureOfAccountingOrKeyTypesOfProducts) Export
	
	Return;
	
EndProcedure

// Parameters:
// 	AttributesTable - See Catalogs.Products.DependenceOfBankingDetailsOnTypeOfProductItem
// 	ItemsType - EnumRef.ItemsTypes
// 	FeatureOfAccountingOrKeyTypesOfProducts - EnumRef.ItemAccountingFeatures
// 	UseVariants - EnumRef.ItemVariantsUsageOptions
// 	TheseAreDetailsOfCharacteristics - Boolean
// 
Procedure DependenceOfBankingDetailsOnTypeOfProductItem(AttributesTable,
												ItemsType,
												FeatureOfAccountingOrKeyTypesOfProducts,
												UseVariants,
												TheseAreDetailsOfCharacteristics) Export
	
	If TypeOf(UseVariants) = Type("EnumRef.ItemVariantsUsageOptions") Then
		UseCharacteristics = UseVariants <> Enums.ItemVariantsUsageOptions.DontUse;
	Else
		UseCharacteristics = UseVariants;
	EndIf;
	
	ThisIsAProduct				= (ItemsType = Enums.ItemsTypes.OwnGoods);
	IsService				= (ItemsType = Enums.ItemsTypes.OperationService);
	ThisIsWork				= (ItemsType = Enums.ItemsTypes.Work_5);
	ThisIsMultiTurnContainer	= (ItemsType = Enums.ItemsTypes.ReusablePackage);
	
	If TheseAreDetailsOfCharacteristics Then
		Attributes = Metadata.Catalogs.ItemsCharacteristics.Attributes;
	Else
		Attributes = Metadata.Catalogs.Products.Attributes;
	EndIf;
	
	If TheseAreDetailsOfCharacteristics Then
		Return;
	EndIf;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.KeepRecordsByCCD;
	NewRow.Use = ThisIsAProduct
								Or ThisIsMultiTurnContainer;
	
	UsingTraceability =
		ThisIsAProduct
		Or ThisIsMultiTurnContainer
		Or ThisIsWork;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.TracedGoods;
	NewRow.Use = UsingTraceability;
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.TransferProductBatchIDMaterial;
	NewRow.Use = UsingTraceability;
	NewRow = AttributesTable.Add();
	NewRow.Use = ThisIsAProduct;
	
	
	#Region AllRussianClassifiers
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.BusinessActivityClassifierCode;
	NewRow.Use = True;
		
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.BusinessActivityClassifierCode2;
	NewRow.Use = True;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.RNCPCode;
	NewRow.Use = Not (ThisIsWork
									Or IsService);
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.RNCTEAPS2Code;
	NewRow.Use = True;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.CodeByKindsOfBusinessActivityClassifier;
	NewRow.Use = ThisIsAProduct Or IsService Or ThisIsWork;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.ProductClassificationTypeCode;
	NewRow.Use = ThisIsAProduct;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.TRUCode;
	NewRow.Use = ThisIsAProduct;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute      = Attributes.ProductClassificationTypeDescription;
	NewRow.Use = ThisIsAProduct;
	#EndRegion
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute            = Attributes.CodeForSection7OfVATDeclaration;
	NewRow.Use = ThisIsAProduct
								Or ThisIsWork
								Or IsService;
	
	NewRow = AttributesTable.Add();
	NewRow.Attribute            = Attributes.SubjectToVATAtCustomer;
	NewRow.Use = ThisIsAProduct;
	
	Return;
	
EndProcedure

Procedure UsingElements(VisibilityOfElements, Object, VisibilityModeShowHighPriorityOnly, VerificationModeForUsingBankingDetails) Export
	
	#Region FunctionalOptions
		PaymentByElectronicCertificatesOfFSS = False;
	#EndRegion
	
	#Region LocalAccounting
	
	
	PreciousMetalsAndStones = False;
	If ValueIsFilled(Object.ProductKind) Then
		PreciousMetalsAndStones = Common.ObjectAttributeValue(Object.ProductKind, "ContainsPreciousMetalsOrStones");
	EndIf;

	VisibilityOfElements.Insert("PreciousMetalsAndStones", PreciousMetalsAndStones
														And (VerificationModeForUsingBankingDetails
															Or Not VisibilityModeShowHighPriorityOnly
															And AccessRight("View",
															Metadata.Catalogs.Products.TabularSections.PreciousMetalsAndStones)));
		
	If Not VerificationModeForUsingBankingDetails Then
		VisibilityOfElements.Insert("HyperlinkGoToPreciousMaterials", VisibilityOfElements.PreciousMetalsAndStones);
	EndIf;
	
	UseVATDeclarationSection7Filling = GetFunctionalOption("UseVATDeclarationSection7Filling");
	
	CodeVisibilityOfSection7OfVATDeclaration = VisibilityOfElements.CodeForSection7OfVATDeclaration
		And UseVATDeclarationSection7Filling
		And Not Object.SubjectToVATAtCustomer
		And (Object.VATRate = Catalogs.VATRates.EXCLUDINGVAT)
		And (Not VisibilityModeShowHighPriorityOnly
			Or VerificationModeForUsingBankingDetails);
		
	VisibilityOfElements.Insert("CodeForSection7OfVATDeclaration", CodeVisibilityOfSection7OfVATDeclaration);
	
	UseSalesAtRateOf0 = False;
	
	VisibilityOfOperation0 = UseSalesAtRateOf0 And (Not VisibilityModeShowHighPriorityOnly
																			Or VerificationModeForUsingBankingDetails);
	VisibilityOfElements.Insert("Operations0", VisibilityOfOperation0);
	If Not VerificationModeForUsingBankingDetails Then
		VisibilityOfElements.Insert("ItemParticipatesInActivityAtRateOfNDS0", VisibilityOfOperation0);
	EndIf;
	
	#EndRegion
	
	#Region InformationOnAlcoholicProducts
	
	VisibilityOfElements.VolumeInDecaliters = VisibilityOfElements.VolumeInDecaliters
									And Not Object.AlcoholContainingProductsOpenPackage
									And (Not VisibilityModeShowHighPriorityOnly
										Or VerificationModeForUsingBankingDetails);
	If Not VerificationModeForUsingBankingDetails Then
		VisibilityOfElements.Insert("DecorDecalitres",         VisibilityOfElements.VolumeInDecaliters);
		VisibilityOfElements.Insert("CalculateVolumeInDecaliters", VisibilityOfElements.VolumeInDecaliters);
		VisibilityOfElements.Insert("DecorationPercentagesOfTheFortress",  VisibilityOfElements.KindOfAlcoholContainingProducts);
	EndIf;
	
	#EndRegion
	
	#Region AllRussianClassifiers
	
	If Not VerificationModeForUsingBankingDetails Then
		VisibilityOfElements.Insert("TRUCode", PaymentByElectronicCertificatesOfFSS);
	EndIf;
	
	#EndRegion
	
	
EndProcedure

Procedure ItemsTitles(ItemsTitles, Object, VisibilityOfElements) Export
	
	ItemsTitles.Insert("KeepRecordsByCCD", TittleKeepRecordsOfCCD());
	
	If Object.ItemsType = Enums.ItemsTypes.Work_5 Then
		ItemsTitles.Insert("TracedGoods", NStr("vi = 'Công việc được truy xuất';
												|ru = 'Прослеживаемая работа';
												|en = 'Traceable work'; fa = 'Traceable work';
												|it = 'Прослеживаемая работа';
												|pl = 'Traceable work';
												|tr = 'İzlenebilir iş'"));
	Else
		ItemsTitles.Insert("TracedGoods", NStr("vi = 'Truy xuất hàng hóa';
												|ru = 'Прослеживаемый товар';
												|en = 'Traceable goods'; fa = 'کالاهای قابل ردیابی';
												|it = 'Прослеживаемый товар';
												|pl = 'Towar identyfikowalny';
												|tr = 'İzlenebilir ürün'"));
	EndIf;
	ItemsTitles.Insert(
		"TransferProductBatchIDMaterial",
		NStr("vi = 'Số đăng ký lô hàng có thể được chuyển sang sản phẩm
				|(trong trường hợp sử dụng trong sản xuất)';
				|ru = 'РНПТ может переноситься на продукцию
				|(в случае использования в производстве)';
				|en = 'RNPT can be transferred to manufactured products
				|(if it is used in manufacturing)'; fa = 'RNPT قابل انتقال به محصولات تولیدی است
				|(در صورت استفاده در تولید)';
				|it = 'РНПТ может переноситься на продукцию
				|(в случае использования в производстве)';
				|pl = 'RNPT can be transferred to manufactured products
				|(if it is used in manufacturing)';
				|tr = 'RNPT, 
				| ürününe aktarılabilir (üretimde kullanılıyorsa)'"));
	Return;
	
EndProcedure

// Returns the header of the VESTIUCHETPOGTD props.
//
// Returns:
//	String - the title of the VESTIUCHETPOGTD props.
//
Function TittleKeepRecordsOfCCD() Export
	
	Title = NStr("vi = 'Hàng hóa nhập khẩu (ghi nhận theo tờ khai hải quan)';
				|ru = 'Импортный товар (учет по ГТД)';
				|en = 'Imported goods (CCD accounting)'; fa = 'کالاهای وارداتی (حسابداری اظهارنامه گمرکی)';
				|it = 'Articolo di importazione (contabilità della Dichiarazione Doganale)';
				|pl = 'Towar importowany (ewidencja według ładunkowych deklaracji celnych)';
				|tr = 'İthal ürün (Kargo Gümrük Beyannamesine göre muhasebe)'");
	
	
	Return Title;
	
EndFunction

Procedure ProcessingFillInChecksProducts(Object, Cancel, CheckedAttributes) Export
	

	Return;
	
EndProcedure

Procedure ProcessingOfFillingVerificationBarcodesOfItems(Form, Cancel, CheckedAttributes) Export
	
	
	Return;
	
EndProcedure

Procedure WhenReceivingDataFromListOfItemBarcodesAtServer(TagName, Settings, Rows) Export
	
	
	Return;
	
EndProcedure

Procedure ParametersForCopyingAdditionalData(Object, CreationParameters, ParametersForCopyingAdditionalData, MatchesCopiedObjects) Export
	
	OptionToTransferSettingsByCharacteristics =
	 ProductsServer.OptionToTransferSettingsByCharacteristics(Object,
	 		CreationParameters.CopySource,
			MatchesCopiedObjects);
			
	If OptionToTransferSettingsByCharacteristics = "NoWrap" Then
		Return;
	EndIf;
	
	
	Return;
	
EndProcedure

Procedure FillInByCreationParameters(Object, CreationParameters) Export
	
	
	Return;

EndProcedure

Procedure CopyAdditionalData(Object, CreationParameters, ParametersForCopyingAdditionalData, MatchesCopiedObjects) Export
	
	
	Return;
	
EndProcedure

// Parameters:
// 	FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend - Array of EnumRef.ItemAccountingFeatures
// 
Procedure FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend(FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend) Export
	
	Return;
	
EndProcedure

// See Catalogs.Products.DefineParametersForLoadingDataFromFile
Procedure DefineParametersForLoadingDataFromFile(Parameters) Export
	
	
	Return;
	
EndProcedure

// Returns the text of the field if you do not need to enter the CCD.
//
// Parameters:
//	HintKind - String - string ID of the text variant of the 'CCD Number' field.
//
// Returns:
//	String - text of the field.
//
Function TextOfCCDField(HintKind = "") Export
	
	FieldText = NStr("vi = '<TKHQ không được sử dụng>';
					|ru = '<ГТД не используются>';
					|en = '<CCD numbers are not used>'; fa = '<CCD numbers are not used>';
					|it = '<Le dichiarazioni doganali di carico non vengono usate>';
					|pl = '<ŁDC nie jest używana>';
					|tr = '<GB kullanılmıyor>'");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Date(1, 1, 1));
	
	If HintKind = "NotisSpecified" Then
		FieldText = NStr("vi = '<TKHQ không được sử dụng>';
						|ru = '<ГТД не указываются>';
						|en = '<CCD are not specified>'; fa = '<CCD are not specified>';
						|it = '<ГТД не указываются>';
						|pl = '<CCD are not specified>';
						|tr = '<GTD''ler belirtilmemiş>'");
		
	EndIf;
	
	Return FieldText;
	
EndFunction

// Checking required Attributes
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the Catalog element.
// 	Cancel - Boolean - a sign of failure.
//
Procedure CheckRequiredBankingDetails(Form, Cancel) Export
	
	Return;
	
EndProcedure

Procedure ChoiceDataGetProcessing(Parameters, Query, QueryText) Export
	
	
EndProcedure

// Returns a collection of texts requesting the replacement of localized Attributes in the Item Catalog.
//
// Returns:
//	Structure - collection of Query Texts:
//		* DetailsOfItemSelection - String - The Query Text of the item Attributes for the query selection fields.
//		* DetailsOfItemGrouping - String - The Query Text of the item Attributes for the request grouping fields.
//		* DetailsOfConnectionNomenclature - String - The Query Text of the item Attributes for the request connections.
//
Function QueryTextsForItemDetails() Export
	
	QueryTexts = New Structure;
	QueryTexts.Insert("DetailsOfItemSelection",     "UNDEFINED");
	QueryTexts.Insert("DetailsOfItemGrouping", "UNDEFINED");
	QueryTexts.Insert("DetailsOfConnectionNomenclature",  "");
	
	Return QueryTexts;
	
EndFunction

// Fills in the collection of Query Texts for replacing localized Attributes in the Item list of Catalog.
//
// Parameters:
//	SourceOfProducts - String - description of the item data source from which the Catalog data will be retrieved.
//									For example, "Table Items.Item"
//									or "EXPRESS (&The item AS A Catalog.Item).
//	QueryTexts - See QueryTextsForItemDetails.
//
Procedure FillInQueryTextDetailsOfItem(SourceOfProducts, QueryTexts) Export
	
	
EndProcedure

// Checks whether the item indication meets the specified verification conditions.
//
// Parameters:
//	AddedData - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	ParametersStructure - See BarcodingOfItemsClientServer.BarcodeProcessingParameters.
//	MeetsConditions - Boolean - indicates whether the item indication meets the specified conditions.
//
Procedure CheckThatItemIndicationMeetsFollowingConditions(AddedData, ParametersStructure, MeetsConditions) Export
	
	
EndProcedure

#EndRegion

#Region ItemsCharacteristics

Procedure ProcessingVerificationOfFillingInProductCharacteristics(Object, Cancel, CheckedAttributes) Export
	
	Return;
	
EndProcedure

#EndRegion

#Region ItemsBatches

Procedure CheckSeriesCompletion(DocumentObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray, CheckParameters) Export
	
	Return;
	
EndProcedure

Procedure CheckWhetherSeriesIndicationFormCanBeOpened(SeriesUseSettings, SeriesSpecificationParameters, ConnectionFieldValues) Export
	
	Return;
	
EndProcedure

Procedure PresentationOfGoodsInFormOfIndicationOfSeries(OwnGoodsPresentation, ConnectionFieldValues) Export
	
	Return;
	
EndProcedure

// Check filling in the details of the series.
// 
// Parameters:
// 	Object - DataProcessorObjectDataProcessorName - must contain:
// 		* SetOfSeries - TabularSection
//  NotCheckedAttributeArray - Array - unverifiable details
//  CheckParameters - Structure - verification parameters
//  Cancel - Boolean
Procedure CheckFillingInDetailsOfSeries(Object, NotCheckedAttributeArray, CheckParameters, Cancel) Export
	
	Return;
	
EndProcedure

Function AddSeriesBasedOnPlacemarkInformation(CurLabel_, Parameters, TSSetOfSeries, CurrentRowID) Export
	
	ProcessedString = Undefined;
	
	Return ProcessedString;
	
EndFunction

Procedure DetailsOfSeriesFromLine(SeriesAttributes, Val EnteredString, SeriesUseSettings) Export
	
	ValidUntil_ = Undefined;
	Number   = Undefined;
	
	EnteredString = StrReplace(EnteredString, " "+" "," ");
	
	If SeriesUseSettings.UseShelfLifeOnBatchRegistration Then
		StringIsValidUntil			= "";
		ExpirationDateStringFormat	= "";
		
		For Each AttributeDetails In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
			If AttributeDetails.AttributeName = "ValidUntil_" Then
				ExpirationDateStringFormat = AttributeDetails.Format;
				
				Break;
			EndIf;
		EndDo;
		
		If SeriesUseSettings.PrecisionOfBatchShelfLifeIndication = PredefinedValue("Enum.AccuracyOfShelfLifeIndication.UpToHours") Then
			StringLengthIsValidUpTo = StrLen(ExpirationDateStringFormat) - 5; // 5 = Length("DF="")
		Else
			StringLengthIsValidUpTo = StrLen(ExpirationDateStringFormat) - 3; // 3 = Length("DF=")
		EndIf;
		
		StringIsValidUntil = Right(TrimAll(EnteredString), StringLengthIsValidUpTo);
		
	EndIf;
	
	If SeriesUseSettings.UseShelfLifeOnBatchRegistration Then
		
		If StrLen(StringIsValidUntil) <> StringLengthIsValidUpTo Then
			ValidUntil_ = '00010101';
		EndIf;
		
		If ValidUntil_ = Undefined Then
			ArrayOfParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(StringIsValidUntil,".");
			
			If (SeriesUseSettings.PrecisionOfBatchShelfLifeIndication = PredefinedValue("Enum.AccuracyOfShelfLifeIndication.UpToMonths")
					And ArrayOfParts.Count() < 2)
				Or (SeriesUseSettings.PrecisionOfBatchShelfLifeIndication <> PredefinedValue("Enum.AccuracyOfShelfLifeIndication.UpToMonths")
					And ArrayOfParts.Count() < 3) Then
				
				ValidUntil_ = '00010101';
				
			EndIf;
		EndIf;
		
		If ValidUntil_ = Undefined Then
			If SeriesUseSettings.PrecisionOfBatchShelfLifeIndication <> PredefinedValue("Enum.AccuracyOfShelfLifeIndication.UpToMonths") Then
				Day  = ArrayOfParts[0];
				Month = ArrayOfParts[1];
			Else
				Day  = "01";
				Month = ArrayOfParts[0];
				Year   = ArrayOfParts[1];
			EndIf;
			
			If SeriesUseSettings.PrecisionOfBatchShelfLifeIndication = PredefinedValue("Enum.AccuracyOfShelfLifeIndication.UpToHours") Then
				YearHour =  StringFunctionsClientServer.SplitStringIntoSubstringsArray(ArrayOfParts[2]," ");
				If YearHour.Count() = 2 Then
					Year = YearHour[0];
					Hour = YearHour[1];
				ElsIf YearHour.Count() = 1 Then
					Year = YearHour[0];
					Hour = "00";
				Else
					Year = "00";
					Hour = "00";
				EndIf;	
			Else
				If SeriesUseSettings.PrecisionOfBatchShelfLifeIndication = PredefinedValue("Enum.AccuracyOfShelfLifeIndication.UpToDays") Then
					Year = ArrayOfParts[2];
				EndIf;
				Hour = "00";
			EndIf;
			
			If StrFind(Hour, ":") > 0 Then
				Hour = Left(Hour, StrFind(Hour, ":") - 1);
			EndIf;
			
			DateAsString = "20" + Year + Month + Day + Hour + "0000";
			
			DateType = New TypeDescription("Date");
			ValidUntil_ = DateType.AdjustValue(DateAsString);
		EndIf;
		
	EndIf;
	
	If SeriesUseSettings.SpecifyNumberWhenRegisteringBatch Then
		If ValueIsFilled(ValidUntil_) Then
			Number = StrReplace(EnteredString," " + NStr("vi = 'đến';
														|ru = 'до';
														|en = 'to'; fa = 'تا';
														|it = 'al';
														|pl = 'do';
														|tr = 'kadar'") + " " + StringIsValidUntil, "");
		Else
			Number = EnteredString;
		EndIf;
	EndIf;
	
	If Number <> Undefined Then
		SeriesAttributes.Number = Number;
	EndIf;
	
	If ValidUntil_ <> Undefined Then
		SeriesAttributes.ValidUntil_ = ValidUntil_;
	EndIf;
	
	Return;
	
EndProcedure

// Parameters:
// 	BarcodesByType - See BarcodingOfItemsServer.StructureByBarcodeType
// 	Barcode - See BarcodingOfItemsClient.BarcodeDataStructure
// 	
// Returns:
// 	Boolean - this is a typed barcode
// 
Function AssignBarcodeToType(BarcodesByType, Barcode) Export
	
	ThisIsTypedBarcode = False;
	
	
	Return ThisIsTypedBarcode; 
	
EndFunction

#EndRegion

#Region BatchAccountingPolicies

Procedure BeforeRecordingSeriesAccountingPolicy(Object) Export
	
	Return;
	
EndProcedure

#EndRegion

// Returns an array of product search areas.
//
// Parameters:
// 	SearchAreas - Array - Array of metadata for product search areas.
// 	Form - ClientApplicationForm - the form from which the search function was called.
// 	SearchParameters - Structure
//
Procedure DescriptionsOfSearchAreas(SearchAreas, Form, SearchParameters) Export
	
	
	Return;
	
EndProcedure

// Configures the shape of the item in the Nomenclature Catalog.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the Catalog element.
//	VisibilityOfElements - See Catalogs.Products.UsingElements.
//
Procedure CustomizeFormAndUpdateCard(Form, VisibilityOfElements) Export
	
	Return;
	
EndProcedure


Procedure ConfigureAvailabilityOfBlockedBankingDetails(Form) Export
	
	Return;
	
EndProcedure


Function DetailsOfAlcoholicBeverages()
	
	DetailsOfAlcoholicBeverages = New Array;
	
	DetailsOfAlcoholicBeverages.Add("KindOfAlcoholContainingProducts");
	DetailsOfAlcoholicBeverages.Add("ImportedAlcoholContainingProducts");
	DetailsOfAlcoholicBeverages.Add("VolumeInDecaliters");
	DetailsOfAlcoholicBeverages.Add("Strength");
	DetailsOfAlcoholicBeverages.Add("AlcoholContainingProductsOpenPackage");
	
	Return DetailsOfAlcoholicBeverages;
	
EndFunction

Function DetailsOfAllRussianClassifiers()
	
	DetailsOfAllRussianClassifiers = New Array;
	DetailsOfAllRussianClassifiers.Add("BusinessActivityClassifierCode");
	DetailsOfAllRussianClassifiers.Add("BusinessActivityClassifierCode2");
	DetailsOfAllRussianClassifiers.Add("RNCPCode");
	DetailsOfAllRussianClassifiers.Add("RNCTEAPS2Code");
	
	Return DetailsOfAllRussianClassifiers;
	
EndFunction

// These are labeled products.
// 
// Parameters:
//  Products - CatalogRef.Products - the product being checked
// 
// Returns:
//  Boolean - Truth is a labeled product
Function TheseAreMarkedProducts(Products) Export
	
	Result = False;
	
	Return Result;
	
EndFunction

Procedure UpdateParametersOfRequestProcessingVerificationOfFillingInDocuments(Query) Export
	
	Return;
	
EndProcedure

#Region QualityCertificates

// Sets the Conditional appearance of the 'Accreditation Status' field in the item certificate list table.
//
// Parameters:
//	Form - ClientApplicationForm - contains data from a form that contains:
//		* Items - FormAllItems - elements of the client application form.
//		* ConditionalAppearance - DataCompositionConditionalAppearance - conditional design of the line-up of these form elements.
//
Procedure SetConditionalAppearanceOfListOfCertificatesOfNomenclature(Form) Export
	
	
EndProcedure

// Returns certificate information based on the FSA service registry data.
//
// Parameters:
//	Number - String - Item certificate number.
//	StartDateOfValidityPeriod - Date - start date of the item certificate validity period.
//	ValidTo - Date - expiration date of the item certificate.
//	CertificateType - String - type of item certificate.
//	ServiceIsAvailable - Boolean - indicates whether the accreditation service is available.
//
// Returns:
//	Structure - certificate information according to the FSA service registry, including properties:
//		* ErrorText - String - error text.
//
Function RequestInformationFromRosaccreditation(Number, StartDateOfValidityPeriod, ValidTo, CertificateType, ServiceIsAvailable) Export
	
	Response = New Structure("ErrorText", "");

	Return Response;
	
EndFunction

// Called from the corresponding handler of the Catalog of certificates of the nomenclature.
//
// Parameters:
//	Object - CatalogObject.QualityCertificates - The object being processed.
//	CopiedObject - CatalogObject.QualityCertificates - The source directory that is the source of copying.
//
Procedure WhenCopying_NomenclatureCertificates(Object, CopiedObject) Export
	
	
	Return;
	
EndProcedure

// Overrides the Query Text of the DCS dataset of the 'Products with existing certificates' report.
//
// Parameters:
//	DataCompositionSchema - DataCompositionSchema - The Data composition schema of the 'Products with existing certificates' report.
//
Procedure SetQueryTextOfGoodsReportWithExpiringCertificates(DataCompositionSchema) Export
	
	
	Return;
	
EndProcedure

// Called from the corresponding Form handler of the item in the Catalog of certificates of nomenclature.
//
// Parameters:
//	Form - See Catalog.QualityCertificates.Form.ItemForm
Procedure WhenCreatingOnServer_CertificatesOfItem_FormOfElement(Form) Export
	
	Items = Form.Items;
	
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	
	Items.GroupOfRACHeader.Visible = LocalizationRFService;
	Items.GroupOfRACITSNotConnected.Visible = LocalizationRFService;
	Items.FillInInscriptionFromOfRAC.Visible = LocalizationRFService;
	Items.FillInAccordingToDataOfRAC.Visible = LocalizationRFService;
	
	
EndProcedure

// Called from the corresponding handler of the Form of the list of certificates Catalog of the nomenclature.
//
// Parameters:
//	Form - ClientApplicationForm - The Form of the list of item certificates.
//
Procedure WhenCreatingOnServer_NomenclatureCertificates_ListForm(Form) Export
	
	Items = Form.Items;
	
	SetVisibilityOfFormElementsOfListOfCertificatesOfNomenclature(Items);
	
EndProcedure

Procedure SetVisibilityOfFormElementsOfListOfCertificatesOfNomenclature(Items)
	
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	
	If LocalizationRFService Then
		Return;
	EndIf;
	
	Items.StatusOfRACSelection.Visible = False;
	Items.UpdateStatusesOfRAC.Visible = False;
	Items.QualityCertificatesStatusOfRAC.Visible = False;
	
EndProcedure

// Parameters:
//	FillParameters - See ProductsClientServer.ParametersForSettingStatusOfCertificatesOfDefaultNomenclature.
//
Procedure AddParametersForSettingStatusOfNomenclatureCertificates(FillParameters) Export
	
	
EndProcedure

// Parameters:
//	CertificateObject - CatalogObject.QualityCertificates - the object of the item certificate Catalog element.
//	FillParameters - See ProductsClientServer.ParametersForSettingStatusOfCertificatesOfDefaultNomenclature.
//	ProcessObject - Boolean - indicates whether the item needs to be modified.
//
Procedure SetStatusOfNomenclatureCertificates(CertificateObject, FillParameters, ProcessObject) Export
	
	
EndProcedure

// Parameters:
//	CheckParameters - Structure - the test parameters.
//
Procedure AddParametersForCheckingComplianceOfStatusesOfNomenclatureCertificate(CheckParameters) Export
	
	
EndProcedure

// Parameters:
//	CertificateData - QueryResultSelection - Item certificate data.
//	NoteText2 - String - the information text of the State of compliance with the Status of the certificate of the item.
//	CheckParameters - Structure - indicates whether the item needs to be modified.
//
Procedure CheckThatStatusOfItemCertificateMatches(CertificateData, NoteText2, CheckParameters) Export
	
	
EndProcedure


#EndRegion

#Region SFGISIntegration

// Returns the structure of the Form object with the added Attributes.
//
// Parameters:
//	Form - ClientApplicationForm - The Form to get the extended object for.
//	Object - FormDataStructure, Structure - object (at the entrance), extended (if necessary, at the exit)
//
Procedure AddFormObject(Form, Object) Export
	
	
	Return;
	
EndProcedure

// Restores the Form object and the product types key from the data object.
//
// Parameters:
//	Form  - ClientApplicationForm - The Form that you want to restore.
//	Object - Structure - The object from which you want to restore the Form data.
Procedure RestoreFormObject(Form, Object) Export
	
	
	Return;
	
EndProcedure

// Returns a key for product types or accounting features.
//
// Parameters:
//	Object - ClientApplicationForm, CatalogObject - Form or data object.
//
// Returns:
//  EnumRef.ItemAccountingFeatures - If the product types key is not filled in.
Function FeatureOfAccountingOrKeyTypesOfProducts(Object) Export
	
	
	ValueType = TypeOf(Object);
	If ValueType = Type("ClientApplicationForm") Then
		
		Result = Object.Object.AccountingFeature;
		
	Else
		
		Result = Object.AccountingFeature;
	
	
	EndIf;
	
	Return Result;
	
EndFunction

// Sets the accounting feature and the key of the types of products according to the transmitted value.
//
// Parameters:
//	Object - CatalogObject - The object where the values are set.
//	Value - EnumRef.ItemAccountingFeatures - set value.
Procedure ToEstablishPeculiarityOfAccountingAndKeyOfManufacturedProducts(Object, Value) Export
	
	If TypeOf(Value) = Type("EnumRef.ItemAccountingFeatures") Then
		Object.AccountingFeature = Value;
	ElsIf Object.AdditionalProperties.Property("KeyTypesOfProducts") Then
		Object.AccountingFeature = Enums.ItemAccountingFeatures.WithoutAccountingFeatures;
		Object.AdditionalProperties.KeyTypesOfProducts = Value;
	EndIf;
	
EndProcedure

Function TheseAreISMPManufacturedProducts(KeyTypesOfProducts, IncludeTobaccoManufacturedProducts = False) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

Function TheseAreMOTPManufacturedProducts(KeyTypesOfProducts) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

Function TheseAreUSAISManufacturedProducts(KeyTypesOfProducts) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

Function TheseAreManufacturedProductsOfVETIS(KeyTypesOfProducts) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

Function ProductTypeUsesVeterinaryCertificate(KeyTypesOfProducts) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
