#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	If Parameters.FillingValues.Property("Barcode") Then
		Record.Barcode = Parameters.FillingValues.Barcode;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	TMCommonUse.CustomizePeripherals(ThisObject);
	
	If Record.SourceRecordKey.IsEmpty() Then
		UpdateItemDetails(Record, ProductAttributes);
		SetItemsAvailability(Items, ProductAttributes);
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing, Parameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ItemsBarcodes", Record.Products);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	Query		= New Query;
	Barcode	= TrimAll(Record.Barcode);
	
	If GetFunctionalOption("UseNonUniqueItemBarcodes") Then
		Query.Text =
		"SELECT TOP 1
		|	ItemsBarcodes.Barcode						AS Barcode,
		|	PRESENTATION(ItemsBarcodes.Products)	AS Products,
		|	PRESENTATION(ItemsBarcodes.Characteristic)	AS Characteristic,
		|	PRESENTATION(ItemsBarcodes.Series)			AS Series,
		|	PRESENTATION(ItemsBarcodes.Package)		AS Package
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON ItemsBarcodes.Products = CatalogProducts.Ref
		|		
		|		INNER JOIN Catalog.ItemKinds.AttributesForProductsControl AS UniquenessControlDetails
		|		ON CatalogProducts.ProductKind = UniquenessControlDetails.Ref
		|			AND UniquenessControlDetails.AttributeName = &PropsNameBarcode
		|			AND UniquenessControlDetails.Uniqueness
		|WHERE
		|	ItemsBarcodes.Barcode = &Barcode
		|	AND NOT (ItemsBarcodes.Products = &Products
		|		AND ItemsBarcodes.Characteristic = &Characteristic
		|		AND ItemsBarcodes.Series = &Series
		|		AND ItemsBarcodes.Package = &Package
		|		)
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	ItemsBarcodes.Barcode						AS Barcode,
		|	PRESENTATION(ItemsBarcodes.Products)	AS Products,
		|	PRESENTATION(ItemsBarcodes.Characteristic)	AS Characteristic,
		|	PRESENTATION(ItemsBarcodes.Series)			AS Series,
		|	PRESENTATION(ItemsBarcodes.Package)		AS Package
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON ItemsBarcodes.Products = CatalogProducts.Ref
		|		
		|		LEFT JOIN Catalog.ItemKinds.AttributesForProductsControl AS UniquenessControlDetails
		|		ON CatalogProducts.ProductKind = UniquenessControlDetails.Ref
		|			AND UniquenessControlDetails.AttributeName = &PropsNameBarcode
		|			AND NOT UniquenessControlDetails.Uniqueness
		|WHERE
		|	ItemsBarcodes.Barcode = &Barcode
		|	AND NOT ISNULL(UniquenessControlDetails.Uniqueness, FALSE)
		|	AND NOT (ItemsBarcodes.Products = &Products
		|		AND ItemsBarcodes.Characteristic = &Characteristic
		|		AND ItemsBarcodes.Series = &Series
		|		AND ItemsBarcodes.Package = &Package
		|		)
		|	AND TRUE IN
		|			(SELECT
		|				TRUE
		|			FROM
		|				Catalog.Products AS CatalogProducts
		|					INNER JOIN Catalog.ItemKinds.AttributesForProductsControl AS ControlAttributes
		|					ON CatalogProducts.ProductKind = ControlAttributes.Ref
		|						AND ControlAttributes.AttributeName = &PropsNameBarcode
		|						AND ControlAttributes.Uniqueness
		|			WHERE
		|				CatalogProducts.Ref = &Products)
		|";
		
		Query.SetParameter("PropsNameBarcode", "Barcode");
	Else
		Query.Text =
		"SELECT TOP 1
		|	ItemsBarcodes.Barcode						AS Barcode,
		|	PRESENTATION(ItemsBarcodes.Products)	AS Products,
		|	PRESENTATION(ItemsBarcodes.Characteristic)	AS Characteristic,
		|	PRESENTATION(ItemsBarcodes.Series)			AS Series,
		|	PRESENTATION(ItemsBarcodes.Package)		AS Package
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|WHERE
		|	ItemsBarcodes.Barcode = &Barcode
		|	AND NOT (ItemsBarcodes.Products = &Products
		|		AND ItemsBarcodes.Characteristic = &Characteristic
		|		AND ItemsBarcodes.Series = &Series
		|		AND ItemsBarcodes.Package = &Package
		|		)
		|";
	EndIf;
	
	Query.SetParameter("Barcode",		Barcode);
	Query.SetParameter("Products",	Record.Products);
	Query.SetParameter("Characteristic",	Record.Characteristic);
	Query.SetParameter("Series",			Record.Series);
	Query.SetParameter("Package",		Record.Package);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	If Record.SourceRecordKey.Barcode <> Barcode Then
		ItemRepresentations = New Array;
		
		ItemsTemplate = NStr("vi = '""%1""';
							|ru = '""%1""';
							|en = '""%1""'; fa = '""%1""';
							|it = '""%1""';
							|pl = '""%1""';
							|tr = '""%1""'");
		
		ProductPresentation = ProductsClientServer.ProductPresentation(
										TrimAll(Selection.Products),
										TrimAll(Selection.Characteristic));
		ProductPresentation = StrTemplate(ItemsTemplate, ProductPresentation);
		ItemRepresentations.Add(ProductPresentation);
		
		If Not IsBlankString(Selection.Series) Then
			BatchPresentation = NStr("ru = 'с серией ""%1""';
									|vi = 'with batch %1';
									|en = 'with batch %1'; fa = 'with batch %1';
									|it = 'with batch %1';
									|pl = 'with batch %1';
									|tr = '""%1"" partisi ile'");
			BatchPresentation = StrTemplate(BatchPresentation, TrimAll(Selection.Series));
			
			ItemRepresentations.Add(BatchPresentation);
		EndIf;
		
		If Not IsBlankString(Selection.Package) Then
			PackagingPresentation = NStr("ru = 'в упаковке ""%1""';
										|vi = 'in the ""%1"" packaging unit';
										|en = 'in the ""%1"" packaging unit'; fa = 'in the ""%1"" packaging unit';
										|it = 'in the ""%1"" packaging unit';
										|pl = 'in the ""%1"" packaging unit';
										|tr = '""%1"" ambalajında'");
			PackagingPresentation = StrTemplate(PackagingPresentation, TrimAll(Selection.Package));
			
			ItemRepresentations.Add(PackagingPresentation);
		EndIf;
		
		MessageText = NStr("ru = 'Такой штрихкод уже назначен для номенклатуры %1.';
							|vi = 'Such barcode is already specified  for the %1 item.';
							|en = 'Such barcode is already specified  for the %1 item.'; fa = 'Such barcode is already specified  for the %1 item.';
							|it = 'Such barcode is already specified  for the %1 item.';
							|pl = 'Such barcode is already specified  for the %1 item.';
							|tr = 'Bu barkod, %1 öğe için zaten atanmış.'");
		MessageText = StrTemplate(MessageText, StrConcat(ItemRepresentations, " "));
		
		Common.MessageToUser(MessageText, Undefined, "Barcode", "Record", Cancel);
	EndIf;
	
	ProductsLocalization.ProcessingOfFillingVerificationBarcodesOfItems(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	UpdateItemDetails(Record, ProductAttributes);
	SetItemsAvailability(Items, ProductAttributes);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	FormEvents.OnWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductsOnChange(Item)
	
	LineDetails =
		"Products,
		|Characteristic,
		|ItemVariantsAreUsed,
		|SeriesAreUsed,
		|Series,
		|Package,
		|UnitOfMeasure";
	
	
	CurrentRow = New Structure(LineDetails);
	FillPropertyValues(CurrentRow, Record);
	
	FillInUnitOfMeasurementAttribute = New Structure("Products", "UnitOfMeasure");
	
	StringActions = New Structure;
	StringActions.Insert("CheckCharacteristicsByOwner",		Record.Characteristic);
	StringActions.Insert("CheckBatchByOwner",				Record.Series);
	StringActions.Insert("CheckFillPackageByOwner",	Record.Package);
	StringActions.Insert("FillInUnitOfMeasurementAttribute",			FillInUnitOfMeasurementAttribute);
	
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StringActions, CachedValues);
	
	FillPropertyValues(Record, CurrentRow);
	
	ItemDetailsTemplate = ProductAttributes();
	FillPropertyValues(ItemDetailsTemplate, CurrentRow);
	
	ProductAttributes = New FixedStructure(ItemDetailsTemplate);
	
	SetItemsAvailability(Items, ProductAttributes);
	
	
EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	
	ItemDetailsTemplate = ProductAttributes();
	FillPropertyValues(ItemDetailsTemplate, ProductAttributes);
	FillPropertyValues(ItemDetailsTemplate, Record);
	
	ProductAttributes = New FixedStructure(ItemDetailsTemplate);
	
	SetItemsAvailability(Items, ProductAttributes);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NewBarcode(Command)
	
	ClearMessages();
	
	If ThisIsAWeightProduct(Record.Products, Record.Package) Then
		Record.Barcode = GenerateBarcodeEAN13WeightProduct();
	Else
		Record.Barcode = GenerateBarcodeEAN13();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	Modified = True;
	
	If BarcodeData_5.Count() > 0 Then
		Record.Barcode = BarcodeData_5[BarcodeData_5.Count() - 1].Barcode;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_WhenChangingElement(Item)
	FormEventsClient.WhenChangingElement(ThisObject, Item);
EndProcedure

&AtServerNoContext
Function ThisIsAWeightProduct(Products, Package)
	
	MeasuredValueType = Undefined;
	
	If ValueIsFilled(Package) Then
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	CASE
		|		WHEN ISNULL(PackagesAndUnitsOfMeasure.MeasuredValueType, UNDEFINED) = VALUE(Enum.TypesOfMeasuredValues.Package)
		|			THEN ISNULL(PackagesAndUnitsOfMeasure.UnitOfMeasure.MeasuredValueType, UNDEFINED)
		|		ELSE PackagesAndUnitsOfMeasure.MeasuredValueType
		|	END AS MeasuredValueType
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
		|WHERE
		|	PackagesAndUnitsOfMeasure.Ref = &Package";
		
		Query.SetParameter("Package", Package);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			MeasuredValueType = Selection.MeasuredValueType;
		EndIf;
		
	Else
		MeasuredValueType = Common.ObjectAttributeValue(Products,
																			"UnitOfMeasure.MeasuredValueType",
																			True);
	EndIf;
	
	Return MeasuredValueType = Enums.TypesOfMeasuredValues.Weight;
	
EndFunction

&AtServerNoContext
Function GenerateBarcodeEAN13()
	
	Return InformationRegisters.ItemsBarcodes.GenerateBarcodeEAN13();
	
EndFunction

&AtServerNoContext
Function GenerateBarcodeEAN13WeightProduct()
	
	Return InformationRegisters.ItemsBarcodes.GenerateBarcodeOfWeightProductEAN13();
	
EndFunction

&AtClientAtServerNoContext
Function ProductAttributes()
	
	PackagingUnitIsDefaultUnit	= PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	
	ItemDetailsTemplate = New Structure;
	ItemDetailsTemplate.Insert("ItemVariantsAreUsed",	False);
	ItemDetailsTemplate.Insert("SeriesAreUsed",			False);
	ItemDetailsTemplate.Insert("Package",					PackagingUnitIsDefaultUnit);
	ItemDetailsTemplate.Insert("UnitOfMeasure",			PackagingUnitIsDefaultUnit);
	
	Return ItemDetailsTemplate;
	
EndFunction

&AtServerNoContext
Procedure UpdateItemDetails(Record, ProductAttributes)
	
	ItemDetailsTemplate = ProductAttributes();
	FillPropertyValues(ItemDetailsTemplate, Record);
	
	If ValueIsFilled(Record.Products) Then
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	CASE
		|		WHEN ProductData_1.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
		|				OR ProductData_1.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|				OR ProductData_1.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|			THEN TRUE
		|		ELSE FALSE
		|	END								AS ItemVariantsAreUsed,
		|	ISNULL(ProductData_1.ProductKind.KeepAccountingByBatch, FALSE) AS SeriesAreUsed,
		|	ProductData_1.UnitOfMeasure	AS UnitOfMeasure
		|FROM
		|	Catalog.Products AS ProductData_1
		|WHERE
		|	ProductData_1.Ref = &Products";
		
		Query.SetParameter("Products", Record.Products);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			FillPropertyValues(ItemDetailsTemplate, Selection);
		EndIf;
		
	EndIf;
	
	ProductAttributes = New FixedStructure(ItemDetailsTemplate);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsAvailability(Items, ProductAttributes)
	
	CharacteristicInputHint	= ?(Not ProductAttributes.ItemVariantsAreUsed,
										NStr("vi = '<không sử dụng đặc tính>';
											|ru = '<характеристики не используются>';
											|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
											|it = '<le caratteristiche non vengono usate>';
											|pl = '<charakterystyki nie dotyczą>';
											|tr = '<varyantlar kullanılmamaktadır>'"),
										"");
	BatchInputPrompt				= ?(Not ProductAttributes.SeriesAreUsed,
										NStr("vi = '<không sử dụng sê-ri>';
											|ru = '<серии не используются>';
											|en = '<batches are not used>'; fa = '<batches are not used>';
											|it = '<le serie non sono utilizzate>';
											|pl = '<serie nie są używane>';
											|tr = '<partiler kullanılmamaktadır>'"),
										"");
	PackagingUnitInputPrompt			= ?(Not ValueIsFilled(ProductAttributes.Package),
										String(ProductAttributes.UnitOfMeasure),
										"");
	
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"Characteristic",
																	"Enabled",
																	ProductAttributes.ItemVariantsAreUsed);
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"Characteristic",
																	"InputHint",
																	CharacteristicInputHint);
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"Series",
																	"Enabled",
																	ProductAttributes.SeriesAreUsed);
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"Series",
																	"InputHint",
																	BatchInputPrompt);
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"Package",
																	"InputHint",
																	PackagingUnitInputPrompt);
	
EndProcedure

#EndRegion

#EndRegion
