#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the series usage settings for the item type in the warehouse (Department).
//
// Parameters:
//  ProductKind		    - CatalogRef.ItemKinds - type of item that you want to get the serial parameters for
//                          - FormDataStructure - Item type (from the Form of the item)
//                          - Structure - Item view with extended fields (from the Form of the item)
//  SeriesSpecificationParameters	- Structure, FixedStructure - See ProductsClientServer.SeriesSpecificationParameters 
//  ConnectionFieldValues		- Structure, FixedStructure - 
// 
// Returns:
//  Structure - structure with keys:
//  * ProductKind  - CatalogRef.ItemKinds - the type of item whose series parameters you want to get
//  * KeepAccountingByBatch - Boolean - True if the series for the item type are used
//  * SpecifyNumberWhenRegisteringBatch - Boolean - True if the series numbers for the item type are used
//  * UseShelfLifeOnBatchRegistration - Boolean - True if the series expiration date is used for the item type
//  * SpecifyQuantityWhenRegisteringBatch - Boolean - True if the number of series is specified
//  * ShelfLifeUnitOfMeasure - EnumRef.TimeMeasureUnits - term measurement unit
//  shelf life of the series.
//  * PrecisionOfBatchShelfLifeIndication - EnumRef.AccuracyOfShelfLifeIndication - accuracy of the deadline
//  shelf life of the series.
//  * WorkingNameTemplateSetOfSeries - String - template for the working name of the series
//  * BatchOwner - CatalogRef.ItemKinds - Owner
//  * BatchSettingsAreTakenFromOtherItemsKind - Boolean - True if the series settings are taken from a different type of item
//  * LabelTemplateBatches - CatalogRef.LabelAndPriceTagTemplates - link to the series label template
//  * UseRFIDTags - Boolean - True if RFID tags are used.
//  * UseBatchProductionDate - Boolean - True if the series of the item type
//  is recorded by production dates.
//  * Signs  - Boolean - signs of the use of serial details, depending on the localization. 
//  				True if the series of the type of nomenclature is being recorded
//  * ExpirationDateFormatString - String - a format string of the expiration date
//  * MandatoryAdditionalDetails - FixedArray of String - names of additional Attributes
//  * BatchAccountingPolicy - CatalogRef.BatchAccountingPolicies - link to the series accounting policy
//  * SpecifyUponReceipt - Boolean - True if the series are specified at the time of receipt
//  * SpecifyOnShipment - Boolean - True if the series is specified during shipment
//  * SpecifyWhenPlanningShipment - Boolean - True if the series are specified during shipment planning
//  * BatchesAccountingByFEFO - Boolean - True if series are counted by FEFO
//  * SpecifyByPickingResult - Boolean - True if the series are counted based on selection
//  * AccountForRemainingSeries - Boolean - True if the remaining series are taken into account
//  * UseCostAccountingByBatches - Boolean  - True if the cost price is taken into account by series.
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
															TMCommonUse.DefaultValuesForItemDetails(
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
	
	If Not ValueIsFilled(SeriesUseSettings.LabelTemplateBatches) Then
		SeriesUseSettings.LabelTemplateBatches 
			= Catalogs.LabelAndPriceTagTemplates.DefaultTemplate(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel);
	EndIf;
	
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
			AttributesForBatchControl = ?(TypeOf(ProductKind) = Type("Structure"),
				ProductKind.AttributesForBatchControl.Copy(
					New Structure("IsAddlAttribute,RequiredToFill", True, True)),
				ProductKind.AttributesForBatchControl.Unload(
					New Structure("IsAddlAttribute,RequiredToFill", True, True)));
		EndIf;
	EndIf;
	
	SeriesUseSettings.MandatoryAdditionalDetails = New FixedArray(AttributesForBatchControl.UnloadColumn("Property"));
	
	Return SeriesUseSettings;
	
EndFunction

// Gets the item type if the item type is the same in the reference list.
//
// Returns:
// 	CatalogRef.ItemKinds - the found type of nomenclature
// 	Undefined - if there are no types of nomenclature or there are more than one types of nomenclature.
//
Function DefaultProductType() Export
	
	Text = 
	"SELECT TOP 2
	|	ItemKinds.Ref AS ProductKind
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	NOT ItemKinds.DeletionMark
	|	AND NOT ItemKinds.IsFolder";
	
	Query = New Query(Text);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = QueryResult.Select();
	
	If Selection.Count() = 1 Then
		Selection.Next();
		ProductKind = Selection.ProductKind;
	Else
		ProductKind = Undefined;
	EndIf;
	
	Return ProductKind;
	
EndFunction // Prominent Nomenclature()

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("ItemsType");
	Result.Add("AccountingFeature");
	Result.Add("UseVariants");
	Result.Add("UseCharacteristics");
	Result.Add("SettingsOfPriceKeyByItemVariant");
	Result.Add("SettingsOfPriceKeyByBatch");
	Result.Add("SettingsOfPriceKeyByPackage");
	Result.Add("KeepAccountingByBatch; OptionOfSeriesSettings");
	Result.Add("BatchAccountingPolicies; BatchAccountingPoliciesAddTheWarehouseToTheSeriesAccountingPolicies,BatchAccountingPoliciesAddTheDepartmentToTheSeriesAccountingPolicies");
	Result.Add("BatchUsageSettings");
	Result.Add("PrecisionOfBatchShelfLifeIndication");
	Result.Add("SaleRegistrationOption");
	Result.Add("PresentationOptionInPrintForms");
	Result.Add("SetPricingOption;GroupSetPrice");
	Result.Add("ItemVariantsOwner");
	Result.Add("BatchOwner");
	Result.Add("BatchSettingsAreTakenFromOtherItemsKind");
	Result.Add("ProductCategoriesCommonWithAnotherKindOfItems");
	Result.Add("ProductCategoryOwner; ConfigureProductCategories");
	Result.Add("ThereAreIndividualSettingsOfSeriesAccountingPolicy; ThereAreIndividualSettingsOfSeriesAccountingPolicy");
	Result.Add("AlcoholContainingProducts");
	
	CommonClientServer.SupplementArray(Result, Catalogs.Products.DetailsOfSignsOfAccountingFeatures(Metadata.Catalogs.ItemKinds));
	
	Return Result;
	
EndFunction

// Returns the preset item types.
//
// Returns:
//	Array of CatalogRef.ItemKinds - 
//
Function GetPresetProductTypes() Export

	SetPrivilegedMode(True);
	
	ArrayOfViews = New Array;
	
	AddPresetProductType(ArrayOfViews, Enums.ItemsTypes.OwnGoods, NStr("vi = 'Hàng hóa';
																		|ru = 'Товар';
																		|en = 'Product'; fa = 'کالا';
																		|it = 'Merce';
																		|pl = 'Towar';
																		|tr = 'Ürün'"));
	AddPresetProductType(ArrayOfViews, Enums.ItemsTypes.OperationService, NStr("vi = 'Dịch vụ';
																				|ru = 'Услуга';
																				|en = 'Service'; fa = 'خدمت';
																				|it = 'Servizio';
																				|pl = 'Usługa';
																				|tr = 'Hizmet'"));
	
	Return ArrayOfViews;

EndFunction 

// Adds the item type with the specified type to the array.
// If there is no item type with this type in the IB, it is created.
//
// Parameters:
//	ArrayOfViews - Array                              - array of item types,
//	Type         - EnumRef.ItemsTypes - the type of item,
//	Name         - String                              - name of the new item type.
//
Procedure AddPresetProductType(ArrayOfViews, Type, Name) Export

	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ItemKinds.Ref
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	ItemKinds.ItemsType = &Type
	|	AND NOT ItemKinds.DeletionMark";
						  
	Query.SetParameter("Type", Type);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		NewView = Catalogs.ItemKinds.CreateItem();
		NewView.Fill(Undefined);
		NewView.Description = Name;
		NewView.ItemsType = Type;
		
		If GetFunctionalOption("UseItemAccessGroups") Then
			NewView.AccessGroup = Catalogs.ItemAccessGroups.GetDefaultAccessGroup(NewView);
		EndIf;
		NewView.SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoice;
		
		FillInDetailsForControl(NewView, "Products");
		
		SettingUpMeasurementUnit = NewView.AttributesForProductsControl.Find("UnitOfMeasure");
		If SettingUpMeasurementUnit <> Undefined Then
			SettingUpMeasurementUnit.DisplayWhenCreated = True;
			SettingUpMeasurementUnit.RequiredToFill = True;
		EndIf;
		
		NewView.UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		NewView.UnitForReports = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		
		NewView.Write();
		
		ArrayOfViews.Add(NewView.Ref);
		
	Else
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		ArrayOfViews.Add(Selection.Ref);
		
	EndIf;	

EndProcedure 

// Parameters:
// 	FillingData - Structure - data structure to fill in
// 	ProductKindReference - CatalogRef.ItemKinds - link to the created object
// 
Procedure CreateAnItemView(FillingData, ProductKindReference) Export
	
	ItemProductType = Catalogs.ItemKinds.CreateItem();
	
	ItemProductType.Fill(Undefined);
	ItemProductType.SetNewCode();
	
	ItemProductType.Description      = FillingData.Description;
	ItemProductType.VATRate         = FillingData.VATRate;
	ItemProductType.ItemsType   = FillingData.ItemsType;
	ItemProductType.LongDesc          = FillingData.LongDesc;
	ItemProductType.UnitOfMeasure  = FillingData.UnitOfMeasure;
	ItemProductType.UnitForReports = FillingData.UnitForReports;
	ItemProductType.Parent          = FillingData.Parent;
	ItemProductType.UseCharacteristics = FillingData.UseCharacteristics;
	ItemProductType.UseVariants = FillingData.UseVariants;
	ItemProductType.SaleRegistrationOption 	 = FillingData.SaleRegistrationOption;
	
	If Catalogs.ItemAccessGroups.AccessGroupsAreUsed() Then
		AccessGroup = Catalogs.ItemAccessGroups.GetDefaultAccessGroup(ItemProductType);
		FillingData.Property("AccessGroup", AccessGroup);
		ItemProductType.AccessGroup = AccessGroup;
	EndIf;
	
	FillInDetailsForControl(ItemProductType, "Products");
	
	SettingUpMeasurementUnit = ItemProductType.AttributesForProductsControl.Find("UnitOfMeasure");
	If SettingUpMeasurementUnit <> Undefined Then
		SettingUpMeasurementUnit.DisplayWhenCreated = True;
		SettingUpMeasurementUnit.RequiredToFill = True;
	EndIf;
	
	ItemProductType.Write();
	
	ProductKindReference = ItemProductType.Ref;
	
EndProcedure

// Returns the value of the expiration date unit based on the accuracy of specifying the expiration date of the series.
//
// Parameters:
//	AccuracyOfIndicationOfExpirationDate - EnumRef.AccuracyOfShelfLifeIndication - Accuracy of the deadline 
//									shelf life of the series of the item type.
//
// Returns:
//	EnumRef.TimeMeasureUnits - the unit of measurement of the expiration date by the value of the accuracy of the indication 
//												of the expiration date of the series.
//
Function ShelfLifeUnitOfMeasure(AccuracyOfIndicationOfExpirationDate) Export
	
	ShelfLifeUnitOfMeasure = Enums.TimeMeasureUnits.EmptyRef();
	
	If AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.UpToMonths Then
		ShelfLifeUnitOfMeasure = Enums.TimeMeasureUnits.Month;
	ElsIf AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.UpToDays Then
		ShelfLifeUnitOfMeasure = Enums.TimeMeasureUnits.Days1;
	ElsIf AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.UpToHours Then
		ShelfLifeUnitOfMeasure = Enums.TimeMeasureUnits.Hour;
	EndIf;
	
	Return ShelfLifeUnitOfMeasure;
	
EndFunction

// Returns details for pricing by item type
// 
// Parameters:
// 	ProductKind - CatalogRef.ItemKinds - Product kind
// 	KeyCut - String - key section ("Characteristics" or " Series")
// Returns:
// 	ValueTable - Assignment table - a table with the details for filling in the key
Function GetDetailsForPricingKey(Val ProductKind, Val KeyCut) Export

	If KeyCut = "Characteristics" Then
		TableName = "ItemVariantsAttributesForPriceKey";
	ElsIf KeyCut = "SetOfSeries" Then
		TableName = "BatchAttributesForPriceKey";
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TypesOfProductsDetailsForPriceKey.AttributeName,
	|	TypesOfProductsDetailsForPriceKey.IsAddlAttribute,
	|	TypesOfProductsDetailsForPriceKey.Property,
	|	TypesOfProductsDetailsForPriceKey.Used,
	|	UNDEFINED AS Value
	|FROM
	|	&TableName AS TypesOfProductsDetailsForPriceKey
	|WHERE
	|	TypesOfProductsDetailsForPriceKey.Ref = &ProductKind
	|	AND TypesOfProductsDetailsForPriceKey.Used";
	
	Query.Text = StrReplace(Query.Text, "&TableName", "Catalog.ItemKinds." + TableName);
	Query.SetParameter("ProductKind", ProductKind);

	DetailsForPriceKey = Query.Execute().Unload();
	
	Return DetailsForPriceKey
EndFunction

#Region Commands

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

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
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

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#Region ProcessingOfFormulas

// Creates a tree of possible operands for a formula using a template.
//
// Parameters:
// 	PropertiesSets - Structure:
// 		* PropertiesSet - CatalogRef.AdditionalAttributesAndInfoSets
// 		* BatchPropertySet - CatalogRef.AdditionalAttributesAndInfoSets
// 		* CharacteristicsPropertySet - CatalogRef.AdditionalAttributesAndInfoSets
// 	TemplateName - String
//
// Returns:
//	See ProcessingOfFormulas.GetEmptyOperandTree
//
Function PrepareTreeOfOperands(PropertiesSets, TemplateName) Export
	
	PropertiesSet = New Structure();
	PropertiesSet.Insert("SetOfProductProperties", False);
	PropertiesSet.Insert("CharacteristicsPropertySet", False);
	PropertiesSet.Insert("Set", Undefined);
	
	If TemplateName = "NameTemplateForPrintingOfProductItem"
		Or TemplateName = "WorkingNameTemplateOfProductItem" Then
		
		PropertiesSet.SetOfProductProperties = True;
		PropertiesSet.Set = PropertiesSets.PropertiesSet;
		
	ElsIf TemplateName = "NameTemplateForPrintingCharacteristics"
		Or TemplateName = "WorkingNameTemplateCharacteristics" Then
		
		PropertiesSet.CharacteristicsPropertySet = True;
		PropertiesSet.Set = PropertiesSets.CharacteristicsPropertySet;
		
	Else
		
		PropertiesSet.Set = PropertiesSets.BatchPropertySet;
		
	EndIf;
	
	OperandsTree = ProcessingOfFormulas.GetEmptyOperandTree();
	
	RootRowOfTree = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	If PropertiesSet.SetOfProductProperties Then
		
		RootRowOfTree.Id = "Products";
		RootRowOfTree.Presentation = NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Item'; fa = 'قلم';
											|it = 'Articolo';
											|pl = 'Pozycja';
											|tr = 'Öğe'");
		RootRowOfTree.ValueType = New TypeDescription("CatalogRef.Products");
		
		SetOfCommonProperties = PropertyManager.PropertiesSetByName("Catalog_Products_Overall");
		
	ElsIf PropertiesSet.CharacteristicsPropertySet Then
		
		RootRowOfTree.Id = "ProductCharacteristic";
		RootRowOfTree.Presentation = NStr("vi = 'Đặc tính mặt hàng';
											|ru = 'Характеристика номенклатуры';
											|en = 'Item variant'; fa = 'گونه قلم';
											|it = 'Caratteristica dell''articolo';
											|pl = 'Charakterystyka produktu';
											|tr = 'Ürün varyantları'");
		RootRowOfTree.ValueType = New TypeDescription("CatalogRef.ItemsCharacteristics");
		
		SetOfCommonProperties = PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall");
		
	Else
		
		RootRowOfTree.Id = "ProductSeries";
		RootRowOfTree.Presentation = NStr("vi = 'Sê-ri mặt hàng';
											|ru = 'Серия номенклатуры';
											|en = 'Item batch'; fa = 'بچ قلم';
											|it = 'Serie dell''elenco articoli';
											|pl = 'Seria produktów';
											|tr = 'Ürün partisi'");
		RootRowOfTree.ValueType = New TypeDescription("CatalogRef.ItemsBatches");
		
		SetOfCommonProperties = PropertyManager.PropertiesSetByName("Catalog_ItemsBatches_Overall");
		
	EndIf;
	
	RootRowOfTree.OperandSelectionAllowed = False;
	RootRowOfTree.IncludedInID = False;
	RootRowOfTree.ExpandToAttributes = True;
	
	SweepRestrictions = ProcessingOfFormulas.LimitationsOfOperandSweep();
	SweepRestrictions.AdditionalAttributeSets.Add(PropertiesSet.Set);
	SweepRestrictions.AdditionalAttributeSets.Add(SetOfCommonProperties);
	SweepRestrictions.NotOutputAttributes = "DataVersion,DeleteExcisableGoods,ProductsUnderVetISControl";
	
	ProcessingOfFormulas.ExpandOperandString(RootRowOfTree, SweepRestrictions);
	
	Return OperandsTree;
	
EndFunction

// Fills in the correspondence of operands to their types.
//
// Parameters:
// 	OperandsTree - See ProcessingOfFormulas.GetEmptyOperandTree
// 	Result - Map of String
//
Procedure GetTypesOfOperands(OperandsTree, Result) Export
	
	For Each TreeRow In OperandsTree.Rows Do
		
		GetTypesOfOperands(TreeRow, Result);
		
		If TreeRow.OperandSelectionAllowed Then
			Result.Insert(TreeRow.Id, TreeRow.ValueType);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

// Returns an indication of the use of unique barcodes by item type in the system's accounting settings.
//
// Parameters:
//	UseNonUniqueBarcodes - Boolean - indicates whether non-unique item barcodes are used in the accounting system
//													.
//
// Returns:
//	Boolean - True, the system includes settings for keeping records of unique barcodes by item types.
//
Function ThereAreSetBarcodeUniquenessSettings(UseNonUniqueBarcodes) Export
	
	Query = New Query;
	Query.Text = QueryTextOfBarcodeUniquenessControlSettings(UseNonUniqueBarcodes, True);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

// Sets the default barcode uniqueness settings for Catalog items.
//
// Parameters:
//	UseNonUniqueBarcodes - Boolean - indicates whether non-unique item barcodes are used in the accounting system
//													.
Procedure SetDefaultBarcodeUniquenessSettings(UseNonUniqueBarcodes) Export
	
	Query = New Query;
	Query.Text = QueryTextOfBarcodeUniquenessControlSettings(UseNonUniqueBarcodes);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	AmountOfDataToBeProcessed = 0;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
						"Catalog.ItemKinds.ManagerModule.SetDefaultBarcodeUniquenessSettings");
	
	EventName			= NStr("vi = 'Cập nhật tùy chỉnh mục tin để kiểm soát mặt hàng';
								|ru = 'Обновление настроек реквизитов для контроля номенклатуры';
								|en = 'Update settings of attributes for products control'; fa = 'Update settings of attributes for products control';
								|it = 'Update settings of attributes for products control';
								|pl = 'Update settings of attributes for products control';
								|tr = 'Öğe kontrolü için öznitelik ayarlarının güncellenmesi'", Common.DefaultLanguageCode());
	CommentTemplate	= NStr("vi = 'Không thể cập nhật tùy chỉnh mục tin để kiểm soát mặt hàng cho dạng mặt hàng ""%1"", do: %2';
								|ru = 'Не удалось обновить настройки реквизитов для контроля номенклатуры для вида номенклатуры ""%1"", по причине: %2';
								|en = 'Cannot update the settings of attributes for products control for the ""%1"" item kind. Reason: %2'; fa = 'Cannot update the settings of attributes for products control for the ""%1"" item kind. Reason: %2';
								|it = 'Cannot update the settings of attributes for products control for the ""%1"" item kind. Reason: %2';
								|pl = 'Cannot update the settings of attributes for products control for the ""%1"" item kind. Reason: %2';
								|tr = '""%1"" öğe türünün öğe kontrolü için öznitelik ayarları şu nedenden dolayı güncellenemedi: %2'");
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		AmountOfDataToBeProcessed = AmountOfDataToBeProcessed + 1;
		
		BeginTransaction();
		
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog.ItemKinds");
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			ProductKind = Selection.Ref.GetObject(); // CatalogObject.ItemKinds -
			
			If ProductKind <> Undefined Then
				SettingUpControl = ProductKind.AttributesForProductsControl.Find("Barcode", "AttributeName");
				
				If SettingUpControl <> Undefined Then
					SettingUpControl.Uniqueness				= Not UseNonUniqueBarcodes;
					SettingUpControl.AvailabilityUnique	= UseNonUniqueBarcodes;
				EndIf;
			EndIf;
			
			If ProductKind.Modified() Then
				ProductKind.Write();
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			MessageText = StrTemplate(CommentTemplate,
										Selection.Ref,
										ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				EventName,
				EventLogLevel.Warning,
				Metadata.Catalogs.ItemKinds,
				,
				MessageText);
		EndTry;
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, AmountOfDataToBeProcessed);
	
EndProcedure

// Adds the transferred objects to the tabular part of the "Accounting policy" of the types of nomenclature.  
// 
// Parameters:
//  Added_Objects - Array of CatalogRef.Warehouses, CatalogRef.BusinessStructure - Which need to be added to the table part.
// 
Procedure AddObjectsToBatchAccountingPolicies(Added_Objects) Export

	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		Block.Add("Catalog.ItemKinds");
		Block.Lock();
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ItemKinds.Ref AS Ref
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|WHERE
		|	ItemKinds.KeepAccountingByBatch";
		
		QueryResult = Query.Execute();
		Selection = SelectByRefs(QueryResult);
		
		While Selection.Next() Do
			
			ProductKind = Selection.GetObject();
			
			For Each ObjectToAdd In Added_Objects Do
				PolicyRow = ProductKind.BatchAccountingPolicies.Add();
				PolicyRow.BatchAccountingPolicy = ProductKind.BatchAccountingPolicy;
				PolicyRow.Warehouse = ObjectToAdd;
			EndDo;
			
			ProductKind.DataExchange.Load = True;
			ProductKind.Write();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;

EndProcedure

// Deletes the transferred objects from the table part of the "Accounting policyasseries" of the types of nomenclature  
// 
// Parameters:
//  ObjectsToDelete - Array of CatalogRef.Warehouses, CatalogRef.BusinessStructure - Which should be removed from the table part.
// 
Procedure DeleteObjectsFromSeriesAccountingPolicies(ObjectsToDelete) Export

	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		Block.Add("Catalog.ItemKinds");
		Block.Lock();
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	BatchAccountingPolicies.Ref AS Ref,
		|	BatchAccountingPolicies.LineNumber AS LineNumber
		|FROM
		|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
		|WHERE
		|	BatchAccountingPolicies.Warehouse IN (&ObjectsToDelete)
		|
		|ORDER BY
		|	Ref DESC,
		|	LineNumber DESC";
		
		Query.SetParameter("ObjectsToDelete", ObjectsToDelete);
		QueryResult = Query.Execute();
		
		SelectingRows = QueryResult.Select();
		RowsOfItemTypesThatAreBeingDeleted = New Map;
		LinesToDelete = Undefined;
		CurrentRef = EmptyRef();
		
		While SelectingRows.Next() Do
			
			If CurrentRef <> SelectingRows.Ref Then
				
				CurrentRef = SelectingRows.Ref;
				
				LinesToDelete = New Array;
				RowsOfItemTypesThatAreBeingDeleted.Insert(CurrentRef, LinesToDelete);
			
			EndIf;
			
			LinesToDelete.Add(SelectingRows.LineNumber);
			
		EndDo;
		
		ObjectSelection = SelectByRefs(QueryResult);
		While ObjectSelection.Next() Do
			
			ProductKind = ObjectSelection.GetObject();
			For Each LineNumber In RowsOfItemTypesThatAreBeingDeleted.Get(ProductKind.Ref) Do
				ProductKind.BatchAccountingPolicies.Delete(LineNumber - 1);
			EndDo;
			
			ProductKind.DataExchange.Load = True;
			ProductKind.Write();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;

EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	ProductsServerCall.TypesOfProductsProcessingOfSelectionData(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region InfobaseUpdate

// Called after loading data from the local version
// to the service data area or Vice versa.
//
Procedure AfterImportData(Container) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ItemKinds.Ref
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	(ItemKinds.RestrictNameChangeToPrintItems
	|			OR ItemKinds.DisableNameChangeToPrintItemVariant
	|			OR ItemKinds.ProhibitEditingWorkingTitleOfItems
	|			OR ItemKinds.ProhibitEditingWorkingTitleOfItemVariants)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		CatalogObject = Selection.Ref.GetObject(); // CatalogObject.ItemKinds
		
		CatalogObject.RestrictNameChangeToPrintItems   = False;
		CatalogObject.DisableNameChangeToPrintItemVariant = False;
		CatalogObject.ProhibitEditingWorkingTitleOfItems    = False;
		CatalogObject.ProhibitEditingWorkingTitleOfItemVariants  = False;
		
		CatalogObject.Write();
		
	EndDo;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.ItemKinds.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.41";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("d8496097-6001-4bb8-8c09-ce139d4a9f06");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.ItemKinds.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Dạng mặt hàng"":';
								|ru = 'Обновление справочника ""Виды номенклатуры"":';
								|en = 'Update the ""Item kinds"" catalog:'; fa = 'Update the ""Item kinds"" catalog:';
								|it = 'Update the ""Item kinds"" catalog:';
								|pl = 'Update the ""Item kinds"" catalog:';
								|tr = '""Öğe türleri"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(StrTemplate(NStr("vi = '- xóa mục tin ""%1"" từ phần bảng ""%2"";';
											|ru = '- удаление реквизита ""%1"" из табличной части ""%2"";';
											|en = '- Delete the ""%1"" attribute from the ""%2"" table'; fa = '- Delete the ""%1"" attribute from the ""%2"" table';
											|it = '- Delete the ""%1"" attribute from the ""%2"" table';
											|pl = '- Delete the ""%1"" attribute from the ""%2"" table';
											|tr = '- ""%1"" özniteliğinin ""%2"" tablo bölümünden silinmesi;'"),
		Metadata.Catalogs.ItemKinds.Attributes.DeleteRNCEA2Code.Name,
		Metadata.Catalogs.ItemKinds.TabularSections.AttributesForProductsControl.Presentation()));
	ListOfDescriptions.Add(StrTemplate(NStr("vi = '- xóa mục tin ""%1"" từ phần bảng ""%2"";';
											|ru = '- удаление реквизита ""%1"" из табличной части ""%2"";';
											|en = '- Delete the ""%1"" attribute from the ""%2"" table'; fa = '- Delete the ""%1"" attribute from the ""%2"" table';
											|it = '- Delete the ""%1"" attribute from the ""%2"" table';
											|pl = '- Delete the ""%1"" attribute from the ""%2"" table';
											|tr = '- ""%1"" özniteliğinin ""%2"" tablo bölümünden silinmesi;'"),
		Metadata.Catalogs.ItemKinds.Attributes.DeleteExcisableGoods.Name,
		Metadata.Catalogs.ItemKinds.TabularSections.AttributesForProductsControl.Presentation()));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục.';
								|ru = '- Заполнение мультиязычных реквизитов справочника.';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.ItemKinds.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.ItemKinds.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.ItemKinds.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();

	Query = New Query;
	QueryParts = New Array;
	
	QueryParts.Add( 
	"SELECT
	|	ItemKindsAttributesForProductsControl.Ref AS Ref
	|FROM
	|	Catalog.ItemKinds.AttributesForProductsControl AS ItemKindsAttributesForProductsControl
	|WHERE
	|	ItemKindsAttributesForProductsControl.AttributeName = ""DeleteRNCEA2Code""
	|	OR ItemKindsAttributesForProductsControl.AttributeName = ""ExcisableGoods""
	|	OR ItemKindsAttributesForProductsControl.AttributeName = ""DeleteExcisableGoods""
	|	OR ItemKindsAttributesForProductsControl.AttributeName = ""ProductsUnderVetISControl""
	|	OR ItemKindsAttributesForProductsControl.AttributeName = ""FootwearProducts""
	|	OR ItemKindsAttributesForProductsControl.AttributeName = ""DeleteShoeProducts""
	|	OR ItemKindsAttributesForProductsControl.AttributeName = ""TobaccoProducts""
	|	OR ItemKindsAttributesForProductsControl.AttributeName = ""DeleteTobaccoProducts""
	|");
	
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If AdditionalLanguagesAreUsed Then
		
		QueryParts.Add(
		"SELECT
		|	ItemKinds.Ref AS Ref
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|WHERE
		|	NOT ItemKinds.Description = """"
		|	AND ItemKinds.DescriptionLanguage1 = """"
		|	
		|UNION 
		|	
		|SELECT
		|	ItemKinds.Ref AS Ref
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|WHERE
		|	NOT ItemKinds.Description = """"
		|	AND ItemKinds.DescriptionLanguage2 = """"");
		
	EndIf;
	
	
	Query.Text = Query.Text + StrConcat(QueryParts, 
		"
		|
		|UNION ALL
		|
		|");
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Query = New Query;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Dạng mặt hàng"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Виды номенклатуры"" по обработчику:';
								|en = 'Cannot process the ""Item kinds"" catalog by the handler:'; fa = 'Cannot process the ""Item kinds"" catalog by the handler:';
								|it = 'Cannot process the ""Item kinds"" catalog by the handler:';
								|pl = 'Cannot process the ""Item kinds"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Ürün türleri"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(StrTemplate(NStr("vi = '- xóa mục tin ""%1"" từ phần bảng ""%2"";';
											|ru = '- удаление реквизита ""%1"" из табличной части ""%2"";';
											|en = '- Delete the ""%1"" attribute from the ""%2"" table'; fa = '- Delete the ""%1"" attribute from the ""%2"" table';
											|it = '- Delete the ""%1"" attribute from the ""%2"" table';
											|pl = '- Delete the ""%1"" attribute from the ""%2"" table';
											|tr = '- ""%1"" özniteliğinin ""%2"" tablo bölümünden silinmesi;'"),
		Metadata.Catalogs.ItemKinds.Attributes.DeleteRNCEA2Code.Name,
		Metadata.Catalogs.ItemKinds.TabularSections.AttributesForProductsControl.Presentation()));
	ListOfDescriptions.Add(StrTemplate(NStr("vi = '- xóa mục tin ""%1"" từ phần bảng ""%2"";';
											|ru = '- удаление реквизита ""%1"" из табличной части ""%2"";';
											|en = '- Delete the ""%1"" attribute from the ""%2"" table'; fa = '- Delete the ""%1"" attribute from the ""%2"" table';
											|it = '- Delete the ""%1"" attribute from the ""%2"" table';
											|pl = '- Delete the ""%1"" attribute from the ""%2"" table';
											|tr = '- ""%1"" özniteliğinin ""%2"" tablo bölümünden silinmesi;'"),
		Metadata.Catalogs.ItemKinds.Attributes.DeleteExcisableGoods.Name,
		Metadata.Catalogs.ItemKinds.TabularSections.AttributesForProductsControl.Presentation()));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục.';
								|ru = '- Заполнение мультиязычных реквизитов справочника.';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması.'"));
	
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TableOfElements
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfElements.Ref AS Ref,
	|	CatalogData.DataVersion AS DataVersion,
	|	ISNULL(TypesOfItemsAttributesForItemControlDeleteOKVED2Code.DisplayWhenCreated, FALSE) AS DisplayDeleteOKVED2CodeWhenCreating,
	|	ISNULL(TypesOfItemsAttributesForItemControlDeleteOKVED2Code.RequiredToFill, FALSE) AS ItIsMandatoryToFillInAndDeleteOKVED2Code,
	|	ISNULL(TypesOfItemsAttributesForItemControlDeleteOKVED2Code.Uniqueness, FALSE) AS ItIsUniqueToDeleteOKVED2Code,
	|	ISNULL(TypesOfNomenclatureAttributesForNomenclatureControlOKVED2Code.DisplayWhenCreated, FALSE) AS DisplayOKVED2CodeWhenCreating,
	|	ISNULL(TypesOfNomenclatureAttributesForNomenclatureControlOKVED2Code.RequiredToFill, FALSE) AS ItIsMandatoryToFillInOKVED2Code,
	|	ISNULL(TypesOfNomenclatureAttributesForNomenclatureControlOKVED2Code.Uniqueness, FALSE) AS OKVED2CodeIsUnique
	|FROM
	|	TableOfElements AS TableOfElements
	|		LEFT JOIN Catalog.ItemKinds AS CatalogData
	|		ON (TableOfElements.Ref = CatalogData.Ref)
	|		LEFT JOIN Catalog.ItemKinds.AttributesForProductsControl AS TypesOfItemsAttributesForItemControlDeleteOKVED2Code
	|		ON (TableOfElements.Ref = TypesOfItemsAttributesForItemControlDeleteOKVED2Code.Ref)
	|			AND (TypesOfItemsAttributesForItemControlDeleteOKVED2Code.AttributeName = ""DeleteRNCEA2Code"")
	|		LEFT JOIN Catalog.ItemKinds.AttributesForProductsControl AS TypesOfNomenclatureAttributesForNomenclatureControlOKVED2Code
	|		ON (TableOfElements.Ref = TypesOfNomenclatureAttributesForNomenclatureControlOKVED2Code.Ref)
	|			AND (TypesOfNomenclatureAttributesForNomenclatureControlOKVED2Code.AttributeName = ""BusinessActivityClassifierCode2"")
	|";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				#Region ProcessRemovalOfPropsFromTablePartAndFillingInMultilingualProps
				If (Not Catalog.DisplayOKVED2CodeWhenCreating
					And Not Catalog.ItIsMandatoryToFillInOKVED2Code
					And Not Catalog.OKVED2CodeIsUnique)
					And (Not Catalog.DisplayDeleteOKVED2CodeWhenCreating
					Or Not Catalog.ItIsMandatoryToFillInAndDeleteOKVED2Code
					Or Not Catalog.ItIsUniqueToDeleteOKVED2Code) Then
					
					FoundRows = CatalogObject.AttributesForProductsControl.FindRows(New Structure("AttributeName", "BusinessActivityClassifierCode2"));
					If FoundRows.Count() > 0 Then
						
						FoundRows[0].DisplayWhenCreated = Catalog.DisplayDeleteOKVED2CodeWhenCreating;
						FoundRows[0].RequiredToFill = Catalog.ItIsMandatoryToFillInAndDeleteOKVED2Code;
						FoundRows[0].Uniqueness = Catalog.ItIsUniqueToDeleteOKVED2Code;
						
					EndIf;
					
				EndIf;
				
				FoundRows = CatalogObject.AttributesForProductsControl.FindRows(New Structure("AttributeName", "DeleteRNCEA2Code"));
				If FoundRows.Count() > 0 Then
					
					CatalogObject.AttributesForProductsControl.Delete(FoundRows[0]);
					
				EndIf;
				
				FoundRows = CatalogObject.AttributesForProductsControl.FindRows(New Structure("AttributeName", "ExcisableGoods"));
				If FoundRows.Count() > 0 Then
					
					CatalogObject.AttributesForProductsControl.Delete(FoundRows[0]);
					
				EndIf;
				
				FoundRows = CatalogObject.AttributesForProductsControl.FindRows(New Structure("AttributeName", "ProductsUnderVetISControl"));
				If FoundRows.Count() > 0 Then
					
					CatalogObject.AttributesForProductsControl.Delete(FoundRows[0]);
					
				EndIf;
				
				FoundRows = CatalogObject.AttributesForProductsControl.FindRows(New Structure("AttributeName", "DeleteTobaccoProducts"));
				If FoundRows.Count() > 0 Then
					
					CatalogObject.AttributesForProductsControl.Delete(FoundRows[0]);
					
				EndIf;
				
				FoundRows = CatalogObject.AttributesForProductsControl.FindRows(New Structure("AttributeName", "DeleteShoeProducts"));
				If FoundRows.Count() > 0 Then
					
					CatalogObject.AttributesForProductsControl.Delete(FoundRows[0]);
					
				EndIf;
				
				If AdditionalLanguagesAreUsed Then
					
					If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
						
						CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
						
					EndIf;
					
					If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
						
						CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
						
					EndIf;
					
				EndIf;
				
				#EndRegion
				
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#Region Other

// Performs processing of updating the links
// 
// Parameters:
// 	ProductKind - CatalogObject.ItemKinds - The object being processed.
Procedure WorkOutLogicOfConnectionDetails(ProductKind) Export
	
	FeatureOfAccountingOrKeyTypesOfProducts = ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(ProductKind);
	
	If TypeOf(FeatureOfAccountingOrKeyTypesOfProducts) = Type("EnumRef.ItemAccountingFeatures") Then
		DetailsOfSignsOfAccountingFeatures = Catalogs.Products.DetailsOfSignsOfAccountingFeatures(Metadata.Catalogs.ItemKinds);
		For Each AttributeName In DetailsOfSignsOfAccountingFeatures Do
			ProductKind[AttributeName] = FeatureOfAccountingOrKeyTypesOfProducts =
				PredefinedValue("Enum.ItemAccountingFeatures." + AttributeName);
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(FeatureOfAccountingOrKeyTypesOfProducts) Then
		If ProductKind.ItemsType = Enums.ItemsTypes.OperationService Then
			ProductsLocalization.ToEstablishPeculiarityOfAccountingAndKeyOfManufacturedProducts(
				ProductKind, Enums.ItemAccountingFeatures.PerformedBySellerCompany);
		Else
			ProductsLocalization.ToEstablishPeculiarityOfAccountingAndKeyOfManufacturedProducts(
				ProductKind, Enums.ItemAccountingFeatures.WithoutAccountingFeatures);
		EndIf;
	EndIf;
	
	AttributesValues = ValuesOfDetailsAreStrictlyFilledInBySpecificsOfAccounting(FeatureOfAccountingOrKeyTypesOfProducts);
	If AttributesValues <> Undefined Then
		FillPropertyValues(ProductKind, AttributesValues);
	EndIf;
			
	CheckByTypeAndFeaturesProductsClearOwner(ProductKind, "ItemVariantsOwner");
	CheckByTypeAndFeaturesProductsClearOwner(ProductKind, "BatchOwner");
	CheckByTypeAndFeaturesProductsClearOwner(ProductKind, "ProductCategoryOwner");
	
	UsingBankingDetails = Catalogs.Products.UsingElements(ProductKind,False,True);
	ObjectMetadata = Metadata.Catalogs.ItemKinds;
	
	For Each KeyValue In UsingBankingDetails Do
		If Not KeyValue.Value Then
			If ObjectMetadata.Attributes.Find(KeyValue.Key) <> Undefined Then
				ProductKind[KeyValue.Key] = Undefined;
			EndIf;
		EndIf;
	EndDo;
	
	If Not ProductKind.UseCharacteristics Then
		
		ProductKind.UseVariants = PredefinedValue("Enum.ItemVariantsUsageOptions.DontUse");
		
		ProductKind.NameTemplateForPrintingCharacteristics = "";
		ProductKind.WorkingNameTemplateCharacteristics  = "";
		
		ProductKind.DisableNameChangeToPrintItemVariant = False;
		ProductKind.ProhibitEditingWorkingTitleOfItemVariants  = False;
		ProductKind.ItemVariantsOwner = Undefined;
		
	EndIf;
		
	If ProductKind.UseVariants <> Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
		ProductKind.ItemVariantsOwner = EmptyRef();
	EndIf;
	
	If Not ProductKind.KeepAccountingByBatch Then
		
		DefaultBankingDetailsValues = TMCommonUse.DefaultValuesForItemDetails(EmptyRef(),
			DetailsOfSettingUpSpecifyingSeries());
			
		FillPropertyValues(ProductKind, DefaultBankingDetailsValues);
			
		ProductKind.BatchAccountingPolicy = Catalogs.BatchAccountingPolicies.SeriesAreNotUsed;
		ProductKind.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.DontUse;
		ProductKind.BatchAccountingPolicies.Clear();
		
	Else
		
		If ProductKind.BatchSettingsAreTakenFromOtherItemsKind
			And (TypeOf(ProductKind) = Type("CatalogObject.ItemKinds")
				And Not ProductKind.AdditionalProperties.Property("SkipFillingInTSSeriesAccountingPolicy")) Then
			
			DetailsOfSeriesOwner = Common.ObjectAttributesValues(ProductKind.BatchOwner,
				DetailsOfSettingUpSpecifyingSeries());
			
			FillPropertyValues(ProductKind, DetailsOfSeriesOwner,,"BatchOwner,BatchSettingsAreTakenFromOtherItemsKind");
			
			Query = New Query;
			Query.Text =
			"SELECT
			|	TypesOfProductPolicyAccountingSeries.Warehouse,
			|	TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy
			|FROM
			|	Catalog.ItemKinds.BatchAccountingPolicies AS TypesOfProductPolicyAccountingSeries
			|WHERE
			|	TypesOfProductPolicyAccountingSeries.Ref = &BatchOwner";
			
			Query.SetParameter("BatchOwner", ProductKind.BatchOwner);
			
			ProductKind.BatchAccountingPolicies.Load(Query.Execute().Unload());
			
		Else
			
			SeriesUseSettings = SeriesUseSettings(ProductKind);
			
			For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
				
				If Not IsBlankString(LongDesc.AccountingFeatures) Then
					
					FeatureNames = StrSplit(LongDesc.AccountingFeatures, ",");
					
					ItIsNecessaryToClear = True;
					
					For Each FeatureName In FeatureNames Do
						
						If ProductKind.AccountingFeature = PredefinedValue("Enum.ItemAccountingFeatures." + FeatureName) Then
							ItIsNecessaryToClear = False;
							Break;
						EndIf;
						
					EndDo;
					
					If ItIsNecessaryToClear Then
						ProductKind[LongDesc.SettingName] = False;
					EndIf;
					
				EndIf;
				
			EndDo;
			
			ProductKind.SpecifyQuantityWhenRegisteringBatch = (ProductKind.BatchUsageSettings = Enums.ItemsBatchUsageSettings.GoodsLot);
			
			If ProductKind.BatchUsageSettings <> Enums.ItemsBatchUsageSettings.InventoryItem Then
				ProductKind.UseRFIDTags = False;
			EndIf;
			
			If Not ProductKind.UseShelfLifeOnBatchRegistration
				And Not ProductKind.UseBatchProductionDate Then
				ProductKind.ShelfLifeUnitOfMeasure = Enums.TimeMeasureUnits.EmptyRef();
				ProductKind.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.EmptyRef();
			Else
				If Not ValueIsFilled(ProductKind.PrecisionOfBatchShelfLifeIndication) Then
					ProductKind.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToDays;
				EndIf;
				ProductKind.ShelfLifeUnitOfMeasure = ShelfLifeUnitOfMeasure(
						ProductKind.PrecisionOfBatchShelfLifeIndication);
			EndIf;
			
			If Not ProductKind.BatchSettingsAreTakenFromOtherItemsKind Then
				ProductKind.BatchOwner = EmptyRef();
			EndIf;
			
			If Not AutomaticSeriesGenerationIsProvided(SeriesUseSettings) Then
				ProductKind.GenerateBatchAutomatically = False;
			EndIf;
			
			If ProductKind.GenerateBatchAutomatically Then
				ProductKind.SpecifyNumberWhenRegisteringBatch = False;
			EndIf;
			
			PolicySelectionParameters = ProductsClientServer.SelectionParametersForSeriesAccountingPolicies();
			FillPropertyValues(PolicySelectionParameters, ProductKind);
			
			If ValueIsFilled(ProductKind.BatchAccountingPolicy)
				And ProductKind.BatchAccountingPolicy <> Catalogs.BatchAccountingPolicies.SeriesAreNotUsed Then
				
				PolicySelection_ = ProductsServer.SelectionOfSeriesAccountingPoliciesByParameters(PolicySelectionParameters);
				
				If Not TMCommonUse.LinkMatchesSelection(ProductKind.BatchAccountingPolicy, PolicySelection_) Then
					ProductKind.BatchAccountingPolicy = Catalogs.BatchAccountingPolicies.SeriesAreNotUsed;
				EndIf;
				
			EndIf;
			
			For Each RowOfTables In ProductKind.BatchAccountingPolicies Do
				
				If RowOfTables.BatchAccountingPolicy <> Catalogs.BatchAccountingPolicies.SeriesAreNotUsed Then
					
					PolicySelectionParameters.Warehouse = RowOfTables.Warehouse;
					
					PolicySelection_ = ProductsServer.SelectionOfSeriesAccountingPoliciesByParameters(PolicySelectionParameters);
					
					If Not TMCommonUse.LinkMatchesSelection(RowOfTables.BatchAccountingPolicy, PolicySelection_) Then
						RowOfTables.BatchAccountingPolicy = ProductKind.BatchAccountingPolicy;
					EndIf;
					
				EndIf;
				
			EndDo;
						
		EndIf;
		
	EndIf;
	
	If Not ProductKind.ProductCategoriesCommonWithAnotherKindOfItems Then
		ProductKind.ProductCategoryOwner = EmptyRef();
	EndIf;
	
	FillInDetailsForControl(ProductKind, "Products");
	FillInAdditionalDetailsForControlAndSelection(ProductKind, "Products");
	
	FillInDetailsForControl(ProductKind, "ItemsCharacteristics");
	FillInAdditionalDetailsForControlAndSelection(ProductKind, "ItemsCharacteristics");
	
	FillInAdditionalDetailsForControlAndSelection(ProductKind, "ItemsBatches");

	ControlUniquenessOfItems = ProductKind.AttributesForProductsControl.FindRows(New Structure("Uniqueness", True)).Count() > 0;
		
EndProcedure

// Fills in the details by default
// 
// Parameters:
// 	ProductKind - CatalogObject.ItemKinds - The object being processed.
//
Procedure FillDefaultAttributes(ProductKind) Export
		
	If Not ValueIsFilled(ProductKind.AccessGroup) Then
		ProductKind.AccessGroup = Catalogs.ItemAccessGroups.GetDefaultAccessGroup(ProductKind);
	EndIf;	
	
	If Not ValueIsFilled(ProductKind.ItemsType) 
		And Not Enums.ItemAccountingFeatures.OneOfFeaturesIsIncluded() Then
		// If there are no features of the item accounting, then sets the "Product" type by default,
		// otherwise the user must explicitly specify the type.
		ProductKind.ItemsType = Enums.ItemsTypes.OwnGoods;
	EndIf;
	
	If IsBlankString(ProductKind.NameTemplateForPrintingOfProductItem) Then
		ProductKind.NameTemplateForPrintingOfProductItem = "[Description]";
	EndIf;

	FeatureOfAccountingOrKeyTypesOfProducts = ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(ProductKind);
	
	AttributesValues = ValuesOfDetailsAreStrictlyFilledInBySpecificsOfAccounting(FeatureOfAccountingOrKeyTypesOfProducts);
	If AttributesValues <> Undefined Then
		FillPropertyValues(ProductKind, AttributesValues);
	EndIf;
	
	If Not ValueIsFilled(ProductKind.SaleRegistrationOption) Then
		ProductKind.SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoice;
	EndIf;
	
	If ProductKind.KeepAccountingByBatch Then
		
		If Not ValueIsFilled(ProductKind.BatchUsageSettings) Then
			ProductKind.BatchUsageSettings = Enums.ItemsBatchUsageSettings.GoodsLot;
		EndIf;	
		
		If Not ProductKind.SpecifyNumberWhenRegisteringBatch
			And Not ProductKind.UseShelfLifeOnBatchRegistration Then
			ProductKind.SpecifyNumberWhenRegisteringBatch = True;
		EndIf;
		
		QueryText =
		"SELECT TOP 2
		|	ItemKinds.Ref AS Ref
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|WHERE
		|	NOT ItemKinds.DeletionMark
		|	AND ItemKinds.Ref <> &Ref
		|	AND &TextOfSelectionConditions";
		
		Query = New Query;
		Query.SetParameter("Ref", ProductKind.Ref);
		
		SeriesOwnerSelection = ProductsServer.SelectionOfOwnerOfSubordinateCatalogs(ProductKind, "BatchOwner");
		
		If SeriesOwnerSelection.Count() > 0 Then 
			ArrayOfConditionTexts_ = New Array;
			
			For Each KeyValue In SeriesOwnerSelection Do
				
				If TypeOf(KeyValue.Value) = Type("Array")
					Or TypeOf(KeyValue.Value) = Type("FixedArray") Then
					ArrayOfConditionTexts_.Add("ItemKinds." + KeyValue.Key + " IN(&" +KeyValue.Key + ")");
				Else
					ArrayOfConditionTexts_.Add("ItemKinds." + KeyValue.Key + " = &" +KeyValue.Key);
				EndIf;
				Query.SetParameter(KeyValue.Key, KeyValue.Value);
				
			EndDo;
			
			QueryText = StrReplace(QueryText, "&TextOfSelectionConditions", StrConcat(ArrayOfConditionTexts_, " And "));
		Else
			QueryText = StrReplace(QueryText, "&TextOfSelectionConditions", "TRUE");
		EndIf;
		
		Query.Text = QueryText;
		Selection = Query.Execute().Select();
		
		If Selection.Count() = 1 Then
			
			Selection.Next();
			ProductKind.BatchOwner = Selection.Ref;
			ProductKind.BatchSettingsAreTakenFromOtherItemsKind = True;
			
		Else
			
			ProductKind.BatchOwner = Undefined;
			ProductKind.BatchSettingsAreTakenFromOtherItemsKind = False;
			
		EndIf;	
			
	EndIf;
	
	If ProductKind.UseCharacteristics Then
		
		If Not ValueIsFilled(ProductKind.UseVariants)
			Or ProductKind.UseVariants = Enums.ItemVariantsUsageOptions.DontUse Then
			ProductKind.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind;
		EndIf;
		
		If IsBlankString(ProductKind.NameTemplateForPrintingCharacteristics) Then
			ProductKind.NameTemplateForPrintingCharacteristics = "[Description]";
		EndIf;
	EndIf;

	SetDefaultPricingDetails(ProductKind);

	ProductsLocalization.FillInDetailsOfDefaultProductType(ProductKind);
	
EndProcedure

Function ValuesOfDetailsAreStrictlyFilledInBySpecificsOfAccounting(FeatureOfAccountingOrKeyTypesOfProducts) Export
	
	Return ProductsLocalization.ValuesOfDetailsAreStrictlyFilledInBySpecificsOfAccounting(
		FeatureOfAccountingOrKeyTypesOfProducts);
	
EndFunction

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
	
	ProductsLocalization.DetailsOfSettingUpSpecifyingSeries(DetailsOfSettingUpSpecifyingSeries);
	
	Return DetailsOfSettingUpSpecifyingSeries;
	
EndFunction

Function SettingsForUsingSerialFields(OnlyDetailsOfType)
	
	SettingsForUsingSerialFields = New Structure;
	SettingsForUsingSerialFields = TMCommonUse.DefaultValuesForItemDetails(
												EmptyRef(),
												DetailsOfSettingUpSpecifyingSeries());
	
	SettingsForUsingSerialFields.Insert("ProductKind", EmptyRef());
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
	
	ProductsLocalization.DescriptionOfUseOfSeriesProps(DescriptionsOfUseOfSeriesProps, SeriesUseSettings);
	
	Return DescriptionsOfUseOfSeriesProps;
	
EndFunction

Function DescriptionUsingPropsSeries() Export
	
	DescriptionUsingPropsSeries = New Structure;
	DescriptionUsingPropsSeries.Insert("AttributeName");
	DescriptionUsingPropsSeries.Insert("AttributeRepresentation");
	DescriptionUsingPropsSeries.Insert("SettingName");
	DescriptionUsingPropsSeries.Insert("NameTemplateText");
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

Function AutomaticSeriesGenerationIsProvided(SeriesUseSettings) Export
	
	AutomaticSeriesGenerationIsProvided = False;
	ProductsLocalization.AutomaticSeriesGenerationIsProvided(AutomaticSeriesGenerationIsProvided, SeriesUseSettings); 
	
	Return AutomaticSeriesGenerationIsProvided;
	
EndFunction

// Checks whether it is possible to change the display settings of the props.
//
//	Parameters:
//		Object - CatalogObject.Products
//		PropsString - String
//		OwnerOfProps - String
//
//	Returns:
//		Boolean - changing the setting is possible.
//
Function YouCanChangeSettingsForDisplayingProps(Object, PropsString, OwnerOfProps) Export
	
	AttributeName   = PropsString.AttributeName;
	IsAddlAttribute = PropsString.IsAddlAttribute;
	
	FeatureOfAccountingOrKeyTypesOfProducts = ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(Object);
	
	If IsAddlAttribute Then
		Attributes = Common.ObjectAttributesValues(PropsString.Property,"RequiredToFill");
		RequiredToFill = Attributes.RequiredToFill;
	Else
		If OwnerOfProps = "Products" Then
			
			AttributeDetails = Catalogs.Products.PropsDescription(AttributeName,
																Object.ItemsType,
																FeatureOfAccountingOrKeyTypesOfProducts,
																Object.UseVariants,
																Object.UseShelfLifeOnBatchRegistration);
			
			RequiredToFill = AttributeDetails.Required_ToFillIn;
			
		Else
			RequiredToFill = False;
		EndIf;
	EndIf;
	
	ChangeSettingsAvailable = Not RequiredToFill;
	
	If ThisIsNecessarilyDisplayedProps(Object, AttributeName, OwnerOfProps, IsAddlAttribute, RequiredToFill) Then
		ChangeSettingsAvailable = False;
	EndIf;
	
	Return ChangeSettingsAvailable
			And Not (PropsString.Uniqueness
					Or PropsString.RequiredToFill);
	
EndFunction

// Checks whether it is possible to change the required information setting.
//
//	Parameters:
//		Object - CatalogObject.Products
//		Requestname-String
//		OwnerOfProps - String
//		Autodoprava - Boolean
//		Fill In The Required Boolean Field
//
//	Returns:
//		Boolean - changing the setting is possible.
//
Function YouCanChangeSettingsForMandatoryBankingDetails(Object, PropsString, OwnerOfProps)
	
	AttributeName         = PropsString.AttributeName;
	IsAddlAttribute       = PropsString.IsAddlAttribute;
	
	FeatureOfAccountingOrKeyTypesOfProducts = ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(Object);
	
	If IsAddlAttribute Then
		ExceptionText = NStr("vi = 'Hàm không được dùng để sử dụng mục tin bổ sung.';
							|ru = 'Функция не предназначена для использования с доп. реквизитами.';
							|en = 'The function is not intended for use with additional attributes.'; fa = 'The function is not intended for use with additional attributes.';
							|it = 'La funzione non è progettata per essere utilizzata con requisti aggiuntivi.';
							|pl = 'Funkcja nie jest przeznaczona do wykorzystywania z atrybutami dodat.';
							|tr = 'Fonksiyon, ek öznitelikler ile kullanılmak üzere tasarlanmamıştır.'");
		Raise ExceptionText;
	Else
		If OwnerOfProps = "Products" Then
			
			AttributeDetails = Catalogs.Products.PropsDescription(AttributeName,
																		Object.ItemsType,
																		FeatureOfAccountingOrKeyTypesOfProducts,
																		Object.UseVariants,
																		Object.UseShelfLifeOnBatchRegistration);
			
			ValueType = AttributeDetails.Type;
			
			RequiredToFill = AttributeDetails.Required_ToFillIn;
			
		ElsIf OwnerOfProps = "ItemsCharacteristics" Then
			
			AttributeDetails = Catalogs.ItemsCharacteristics.PropsDescription(AttributeName,
																						Object.ItemsType,
																						FeatureOfAccountingOrKeyTypesOfProducts);
			
			ValueType = AttributeDetails.Type;
			
			RequiredToFill = AttributeDetails.Required_ToFillIn;
			
		Else
			RequiredToFill = False;
		EndIf;
	EndIf;
	
	ChangeSettingsAvailable = Not RequiredToFill;
	
	TypesDetailsBoolean = New TypeDescription("Boolean");
	
	Return ChangeSettingsAvailable
		And ValueType <> TypesDetailsBoolean;
	
EndFunction

// Adds details to the table parts of an item in the nomenclature reference list.
//
// Parameters:
//	Object - CatalogObject.Products
//	Attribute - See Catalogs.Products.PropertyValuesOfProps
//  OwnerOfProps - String - The owner of the props
Procedure AddDetailsForMonitoringAndSelectingProducts(Object, Attribute, OwnerOfProps) Export
	
	If Catalogs.Products.DetailsNotDisplayedInSettingsTable().Find(Attribute.Name) <> Undefined Then
		Return;
	EndIf;
	
	DetailsNotUsedForControl = Catalogs.Products.UnusedPropsForUniquenessControl();
	TypesNotUsedForControl = Catalogs.Products.TypesNotUsedForFillingAndSelectionControl();
	
	AttributeRepresentation = Attribute.Presentation;
	
	ThisIsUnusedPropsForControl	= (DetailsNotUsedForControl.Find(Attribute.Name) <> Undefined);
	ThisIsUnusedTypeForControl			= (TypesNotUsedForControl.Find(Attribute.Name) <> Undefined);
	ThisIsRequiredToFillInDetails	= Attribute.Required_ToFillIn;
	
	ThisIsPropsRecommendedForUniquenessControl = Attribute.RecommendedForUniquenessControl; 
	
	Filter = New Structure("AttributeName, IsAddlAttribute", Attribute.Name, False);
	
	If OwnerOfProps = "Products" Then
		TSName = "AttributesForProductsControl";
	Else
		TSName = "AttributesForItemVariantsControl";
	EndIf;
	
	FoundRows = Object[TSName].FindRows(Filter);
	
	IsNewLine = False;
	
	If FoundRows.Count() = 0 Then
		StringOfDetailsForControl = Object[TSName].Add();
		StringOfDetailsForControl.AttributeName = Attribute.Name;
		
		IsNewLine = True;
	Else
		StringOfDetailsForControl = FoundRows[0];
	EndIf;
	
	StringOfDetailsForControl.AttributeRepresentation = AttributeRepresentation;
	
	If Not StringOfDetailsForControl.RequiredToFill Then
		StringOfDetailsForControl.RequiredToFill = ThisIsRequiredToFillInDetails;
	EndIf;
	
	If Not StringOfDetailsForControl.DisplayWhenCreated Then
		StringOfDetailsForControl.DisplayWhenCreated =
			ThisIsNecessarilyDisplayedProps(Object, Attribute, "Products", False, ThisIsRequiredToFillInDetails);
	EndIf;
	
	If IsNewLine
		And Attribute.Name = "Barcode" Then
		
		RecommendedForUniquenessControl = Not GetFunctionalOption("UseNonUniqueItemBarcodes");
		
		StringOfDetailsForControl.DisplayWhenCreated	= True;
		StringOfDetailsForControl.Uniqueness				= RecommendedForUniquenessControl;
		StringOfDetailsForControl.AvailabilityUnique		= Not RecommendedForUniquenessControl;
		
	ElsIf IsNewLine
		And ThisIsPropsRecommendedForUniquenessControl Then
		
		StringOfDetailsForControl.Uniqueness				= True;
		StringOfDetailsForControl.DisplayWhenCreated	= True;
		StringOfDetailsForControl.AvailabilityUnique		= True;
		
	ElsIf ThisIsUnusedTypeForControl
		Or ThisIsUnusedPropsForControl Then
		
		StringOfDetailsForControl.Uniqueness			= False;
		StringOfDetailsForControl.AvailabilityUnique	= False;
		
	Else
		StringOfDetailsForControl.AvailabilityUnique = True;
	EndIf;
	
	StringOfDetailsForControl.MandatoryFillingOfAvailability		= YouCanChangeSettingsForMandatoryBankingDetails(Object,
																												StringOfDetailsForControl,
																												OwnerOfProps);
	StringOfDetailsForControl.DisplayAvailabilityOnCreation	= YouCanChangeSettingsForDisplayingProps(Object,
																													StringOfDetailsForControl,
																													OwnerOfProps);
EndProcedure

Function ThisIsNecessarilyDisplayedProps(Object, AttributeName, OwnerOfProps, IsAddlAttribute, RequiredToFill)
	
	If IsAddlAttribute Then
		Return RequiredToFill;
	EndIf;
	
	If RequiredToFill Then
		Return True;
	EndIf;
	
	If OwnerOfProps = "Products" Then
		
		FeatureOfAccountingOrKeyTypesOfProducts = ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(Object);
		
		NecessarilyDisplayed = Catalogs.Products.PropsDescription(AttributeName,
																Object.ItemsType,
																FeatureOfAccountingOrKeyTypesOfProducts,
																Object.UseVariants,
																Object.UseShelfLifeOnBatchRegistration).RequiredToDisplayWhenCreating;
		
		Return NecessarilyDisplayed;
		
	EndIf;
	
	Return False;
	
EndFunction

Procedure RemoveControlDetails(Object, AttributeName, OwnerOfProps)
	
	Filter = New Structure("AttributeName", AttributeName);
	CollectionOfPropsForControl = CollectionOfPropsForControl(Object, OwnerOfProps);
	
	FoundRows = CollectionOfPropsForControl.FindRows(Filter);
	
	If FoundRows.Count() > 0 Then
		
		RowOfDetailsTable = FoundRows[0];
		CollectionOfPropsForControl.Delete(RowOfDetailsTable);
		
	EndIf;
	
EndProcedure

Procedure DeleteSelectionDetails(Object, AttributeName, OwnerOfProps)
	
	CollectionOfSelectionProps = CollectionOfSelectionProps(Object, OwnerOfProps); 
	
	RowsArray = CollectionOfSelectionProps.FindRows(New Structure("AttributeName", AttributeName));
	
	If RowsArray.Count() > 0 Then
		RowOfDetailsTable = RowsArray[0];
		CollectionOfSelectionProps.Delete(RowOfDetailsTable);
	EndIf;
	
EndProcedure

Procedure WhenChangingFlagIsUnique(Object, OwnerOfProps, CurrentData) Export
	
	TypesDetailsBoolean = New TypeDescription("Boolean");
	
	If OwnerOfProps <> "ItemsBatches"
		And CurrentData.Uniqueness Then
		CurrentData.RequiredToFill = True;
		CurrentData.DisplayWhenCreated = True;
	EndIf;
		
	// If the type of the props is Boolean, then do not include the filling control.
	If CurrentData.IsAddlAttribute Then
		
		ValueType = Common.ObjectAttributeValue(CurrentData.Property, "ValueType");
		
		If ValueType = TypesDetailsBoolean Then
			CurrentData.RequiredToFill = False;
		EndIf;
		
	Else
		
		If OwnerOfProps = "Products" Then
			
			FeatureOfAccountingOrKeyTypesOfProducts = ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(Object);
			
			AttributeType = Catalogs.Products.PropsDescription(CurrentData.AttributeName,
																	Object.ItemsType,
																	FeatureOfAccountingOrKeyTypesOfProducts,
																	Object.UseVariants,
																	Object.UseShelfLifeOnBatchRegistration).Type;
			
			If AttributeType = TypesDetailsBoolean Then
				CurrentData.RequiredToFill = False;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If OwnerOfProps <> "ItemsBatches" Then
		CurrentData.DisplayAvailabilityOnCreation = YouCanChangeSettingsForDisplayingProps(
			Object, CurrentData, OwnerOfProps);
	EndIf;
	
EndProcedure

// Fills in the table of settings for controlling the details of the Nomenclature and characteristics of the Nomenclature reference lists.
//
// Parameters:
//	Object - CatalogObject.Products, CatalogObject.ItemsCharacteristics - Yandex business directory object.
//	AttributesOwner - String - the name of the owner of the Attributes.
//
Procedure FillInDetailsForControl(Object, AttributesOwner) Export
	
	If AttributesOwner = "ItemsCharacteristics"
		And Not Object.UseCharacteristics Then
		Object.AttributesOfItemVariantQuickFilter.Clear();
		Return;
	EndIf;
	
	FeatureOfAccountingOrKeyTypesOfProducts = ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(Object);
	
	If AttributesOwner = "ItemsCharacteristics" Then
		DependenceOnTypeOfProduct = SettingsValueCached.AllDetailsOfProductCharacteristics(Object.ItemsType,
																									FeatureOfAccountingOrKeyTypesOfProducts);
	Else
		DependenceOnTypeOfProduct = SettingsValueCached.AllProductDetails(Object.ItemsType,
																						FeatureOfAccountingOrKeyTypesOfProducts,
																						Object.UseCharacteristics,
																						Object.UseShelfLifeOnBatchRegistration);
	EndIf;
	
	For Each SettingByType In DependenceOnTypeOfProduct Do
		
		If SettingByType.Value.Use Then
			AddDetailsForMonitoringAndSelectingProducts(Object, SettingByType.Value, AttributesOwner);
		Else
			RemoveControlDetails(Object, SettingByType.Key, AttributesOwner);
			DeleteSelectionDetails(Object, SettingByType.Key, AttributesOwner);
		EndIf;
		
	EndDo;
	
	If AttributesOwner = "ItemsCharacteristics" Then
		Object.AttributesForItemVariantsControl.Sort("AttributeRepresentation");
	Else
		Object.AttributesForProductsControl.Sort("AttributeRepresentation");
	EndIf;
	
EndProcedure

// Filling in additional details
// 
// Parameters:
// 	Object - CatalogObject.ItemKinds
// 	AssigningAdditionalBankingDetails - String
Procedure FillInAdditionalDetailsForControlAndSelection(Object, AssigningAdditionalBankingDetails) Export
	
	If AssigningAdditionalBankingDetails = "ItemsCharacteristics"
		And Not Object.UseCharacteristics Then
		Object.AttributesForItemVariantsControl.Clear();
		Return;
	ElsIf AssigningAdditionalBankingDetails = "ItemsBatches"
		And Not Object.KeepAccountingByBatch Then
		Object.AttributesForBatchControl.Clear();
		Return;
	EndIf;
	
	TypesNotUsedForControl = Catalogs.Products.TypesNotUsedForFillingAndSelectionControl();
	
	Filter = New Structure("Property, IsAddlAttribute");
	AllAdditionalDetails = Catalogs.Products.AllAdditionalDetails_(Object.Ref, AssigningAdditionalBankingDetails);
	
	AttributesForControl    = CollectionOfPropsForControl(Object, AssigningAdditionalBankingDetails);
	QuickSelectionDetails = CollectionOfSelectionProps(Object, AssigningAdditionalBankingDetails);
	
	LinesToDelete = New Array;
	
	For Each AdditionalAttribute5 In AttributesForControl Do
		If Not AdditionalAttribute5.IsAddlAttribute Then
			Continue;
		EndIf;
		
		FillPropertyValues(Filter, AdditionalAttribute5);
		
		DescriptionOfAdditionalProps = AllAdditionalDetails.FindRows(Filter);
		
		If DescriptionOfAdditionalProps.Count() = 0 Then
			LinesToDelete.Add(AdditionalAttribute5);
		Else
			FillPropertyValues(AdditionalAttribute5,DescriptionOfAdditionalProps[0]);
		EndIf;
	EndDo;
	
	For Each String In LinesToDelete Do
		AttributesForControl.Delete(String);
	EndDo;
	
	If QuickSelectionDetails <> Undefined Then
		LinesToDelete = New Array;
		
		For Each AdditionalAttribute5 In QuickSelectionDetails Do
			If Not AdditionalAttribute5.IsAddlAttribute Then
				Continue;
			EndIf;
			
			FillPropertyValues(Filter, AdditionalAttribute5);
			
			If AllAdditionalDetails.FindRows(Filter).Count() = 0 Then
				LinesToDelete.Add(AdditionalAttribute5);
			EndIf;
		EndDo;
		
		For Each String In LinesToDelete Do
			QuickSelectionDetails.Delete(String);
		EndDo;
	EndIf;
	
	For Each AdditionalAttribute5 In AllAdditionalDetails Do
		ValueType = AdditionalAttribute5.Type;
		ThisIsUnusedTypeForControl = TypesNotUsedForControl.Find(ValueType) <> Undefined;
		
		FillPropertyValues(Filter, AdditionalAttribute5);
		
		FoundRows = AttributesForControl.FindRows(Filter);
		
		If FoundRows.Count() > 0 Then
			StringOfDetailsForControl = FoundRows[0];
			StringOfDetailsForControl.AttributeRepresentation = AdditionalAttribute5.AttributeRepresentation;
		Else
			StringOfDetailsForControl = AttributesForControl.Add();
			FillPropertyValues(StringOfDetailsForControl, AdditionalAttribute5);
		EndIf;
		
		If AdditionalAttribute5.RequiredToFill Then
			StringOfDetailsForControl.RequiredToFill = True;
			If AssigningAdditionalBankingDetails <> "ItemsBatches" Then
				StringOfDetailsForControl.DisplayWhenCreated = True;
			EndIf;
		EndIf;
		
		StringOfDetailsForControl.MandatoryFillingOfAvailability = True;
		
		If AssigningAdditionalBankingDetails <> "ItemsBatches" Then
			If Not ThisIsUnusedTypeForControl Then
				StringOfDetailsForControl.AvailabilityUnique = True;
			Else
				StringOfDetailsForControl.Uniqueness = False;
				StringOfDetailsForControl.AvailabilityUnique = False;
			EndIf;
			
			StringOfDetailsForControl.DisplayAvailabilityOnCreation = Not StringOfDetailsForControl.RequiredToFill
																			And Not StringOfDetailsForControl.Uniqueness;
		EndIf;
	EndDo;
		
	If QuickSelectionDetails <> Undefined Then
		Filter = New Structure("Property");
		
		For Each AdditionalAttribute5 In AllAdditionalDetails Do
			FillPropertyValues(Filter, AdditionalAttribute5);
			MutableStrings = QuickSelectionDetails.FindRows(Filter);
			
			For Each AttributesRow In MutableStrings Do
				FillPropertyValues(AttributesRow, AdditionalAttribute5, "AttributeRepresentation");
			EndDo;
		EndDo;
	EndIf;
	
	If AttributesForControl <> Undefined Then
		AttributesForControl.Sort("AttributeRepresentation");
	EndIf;
	
EndProcedure

// Fills in the pricing settings table for the product range and Series Characteristics.
//
Procedure FillInDetailsForPricing(Object, AttributesOwner) Export
	
//	These are the ReqUestionchAracteristics = The owner of the requirements = "Characteristics of the Nomenclature";
	
	If AttributesOwner = "ItemsCharacteristics"
		And (Not Object.UseCharacteristics 
		Or Not Object.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.UseByAttributes) Then
		Object.ItemVariantsAttributesForPriceKey.Clear();
		Return;
	ElsIf AttributesOwner = "ItemsBatches"
		And (Not Object.KeepAccountingByBatch 
		Or Not Object.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.UseByAttributes) Then
		Object.BatchAttributesForPriceKey.Clear();
		Return;
	EndIf;
	
EndProcedure

Function CollectionOfPropsForControl(CurrentObject, TypeOfElementSetOwner) Export
	
	If TypeOfElementSetOwner = "Products" Then
		Return CurrentObject.AttributesForProductsControl;
	ElsIf TypeOfElementSetOwner = "ItemsCharacteristics" Then
		Return CurrentObject.AttributesForItemVariantsControl;
	ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
		Return CurrentObject.AttributesForBatchControl;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function CollectionOfSelectionProps(CurrentObject, TypeOfElementSetOwner) Export
	
	If TypeOfElementSetOwner = "Products" Then
		Return CurrentObject.AttributesOfQuickFilterOfProducts;
	ElsIf TypeOfElementSetOwner = "ItemsCharacteristics" Then
		Return CurrentObject.AttributesOfItemVariantQuickFilter;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function CollectionOfKeyDetails(CurrentObject, TypeOfElementSetOwner) Export
	
	If TypeOfElementSetOwner = "ItemsCharacteristics" Then
		Return CurrentObject.ItemVariantsAttributesForPriceKey;
	ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
		Return CurrentObject.BatchAttributesForPriceKey;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function UseProduction() Export
	
	UseProduction = False; //For TM
	UseProduction = GetFunctionalOption("UseProductionManagement"); //For KAUP

	Return UseProduction;
	
EndFunction

Procedure CheckByTypeAndFeaturesProductsClearOwner(ProductKind, PropsNameOwner)
	
	If Not ValueIsFilled(ProductKind[PropsNameOwner]) Then
		Return;
	EndIf;
	
	SelectionOfOwner = ProductsServer.SelectionOfOwnerOfSubordinateCatalogs(ProductKind, PropsNameOwner);
	
	If Not TMCommonUse.LinkMatchesSelection(ProductKind[PropsNameOwner], SelectionOfOwner) Then
		ProductKind[PropsNameOwner] = Undefined;	
	EndIf;
EndProcedure

// Fills in the default pricing details
// 
// Parameters:
// 	ProductKind - CatalogObject.ItemKinds - The object being processed.
//
Procedure SetDefaultPricingDetails(ProductKind) Export
	
	// Setting up pricing settings based on the characteristics of the item	
	ProductKind.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.DontUse;
	If ProductKind.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind 
		And ValueIsFilled(ProductKind.ItemVariantsOwner) Then
		
		PriceKeySettingsByCharacteristicByOwner = Common.ObjectAttributesValues(ProductKind.ItemVariantsOwner,"SettingsOfPriceKeyByItemVariant");
		ProductKind.SettingsOfPriceKeyByItemVariant = PriceKeySettingsByCharacteristicByOwner.SettingsOfPriceKeyByItemVariant;
		
	EndIf;

	// Setting up pricing settings by item series		
	ProductKind.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.DontUse;
	If ProductKind.BatchSettingsAreTakenFromOtherItemsKind And ValueIsFilled(ProductKind.BatchOwner) Then
		
		PriceKeySettingsByCharacteristicByOwner = Common.ObjectAttributesValues(ProductKind.BatchOwner,"SettingsOfPriceKeyByBatch");
		ProductKind.SettingsOfPriceKeyByBatch = PriceKeySettingsByCharacteristicByOwner.SettingsOfPriceKeyByBatch;
		
	EndIf;

	// process tabular pricing parts
	FillInDetailsForPricing(ProductKind, "ItemsCharacteristics");
	FillInDetailsForPricing(ProductKind, "ItemsBatches");
	
EndProcedure

// Fills in the default pricing details
// 
// Parameters:
// 	ItemKinds - Array  - From elements of the reference Link type.Types of nomenclature.
// 	InstallationParameters - Structure - The settings for the installation.
//
Procedure SetPricingDetails(ItemKinds, InstallationParameters) Export
	
	For Each ProductKind In ItemKinds Do
		
		ItemProductType = Undefined;
		// Setting up pricing settings based on the characteristics of the item	
		If Not ProhibitUseOfCharacteristicsForPricing(ProductKind) And Not InstallationParameters.SettingsOfPriceKeyByItemVariant = Undefined Then
			
			ItemProductType = ProductKind.GetObject();//CatalogObject.ItemKinds
			ItemProductType.SettingsOfPriceKeyByItemVariant = InstallationParameters.SettingsOfPriceKeyByItemVariant;
			
			// process tabular pricing parts
			FillInDetailsForPricing(ItemProductType, "ItemsCharacteristics");
			
		EndIf;
		
		// Setting up pricing settings by item series
		If Not ProhibitUseOfSeriesForPricing(ProductKind) And Not InstallationParameters.SettingsOfPriceKeyByBatch = Undefined Then
			
			If ItemProductType = Undefined Then
				ItemProductType = ProductKind.GetObject();//CatalogObject.ItemKinds
			EndIf;
			
			ItemProductType.SettingsOfPriceKeyByBatch = InstallationParameters.SettingsOfPriceKeyByBatch;
				
			// process tabular pricing parts
			FillInDetailsForPricing(ItemProductType, "ItemsBatches");
			
		EndIf;
		
		If Not InstallationParameters.SettingsOfPriceKeyByPackage = Undefined Then
			
			If ItemProductType = Undefined Then
				ItemProductType = ProductKind.GetObject();//CatalogObject.ItemKinds
			EndIf;
			
			ItemProductType.SettingsOfPriceKeyByPackage = InstallationParameters.SettingsOfPriceKeyByPackage;
			
		EndIf;
		
		If Not ItemProductType = Undefined Then
			Try
				ItemProductType.Write();
			Except
			EndTry;
		EndIf;
		
	EndDo;
	
EndProcedure

Function ProhibitUseOfSeriesForPricing(Val ProductKind) Export
	
	Disable = False;
	
	If Not ProductKind.KeepAccountingByBatch Then
		Disable = True;
	EndIf;
	
	Return Disable;
	
EndFunction

Function ProhibitUseOfCharacteristicsForPricing(Val ProductKind) Export
	
	Disable = False;
	
	If Not ProductKind.UseCharacteristics
		Or ProductKind.UseVariants = Enums.ItemVariantsUsageOptions.DontUse 
		Or (ProductKind.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems
			 And ProductKind.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.UseByAttributes) Then
		
		Disable = True;
			
	EndIf;
	
	Return Disable;
	
EndFunction

Function QueryTextOfBarcodeUniquenessControlSettings(UseNonUniqueBarcodes, SearchForRecords = False)
	
	If UseNonUniqueBarcodes Then
		QueryText =
		"SELECT
		|	AttributesForControl.Ref AS Ref
		|FROM
		|	Catalog.ItemKinds.AttributesForProductsControl AS AttributesForControl
		|WHERE
		|	AttributesForControl.AttributeName = ""Barcode""
		|	AND AttributesForControl.Uniqueness";
	Else
		QueryText =
		"SELECT
		|	AttributesForControl.Ref AS Ref
		|FROM
		|	Catalog.ItemKinds.AttributesForProductsControl AS AttributesForControl
		|WHERE
		|	AttributesForControl.AttributeName = ""Barcode""
		|	AND AttributesForControl.Uniqueness
		|	AND AttributesForControl.AvailabilityUnique";
	EndIf;
	
	If SearchForRecords Then
		QueryText = StrReplace(QueryText, "SELECT", "SELECT TOP 1"); // @query-part-1 @query-part-2
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf