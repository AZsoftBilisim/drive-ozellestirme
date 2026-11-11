
////////////////////////////////////////////////////////////////////////////////
// Subsystem "Working with nomenclature".
// General module.The work of the nomenclature is undefined.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public


#Region ObtainingInformationBaseData


// See WorkingWithProductItemsOverridable.SearchForProductsByBarcodeWhenCreatingThemOnServer.
Procedure SearchForProductsByBarcodeWhenCreatingThemOnServer(Form) Export
	
	SearchForItemsByBarcodeInitializeForm(Form);
	SearchForItemsByBarcodeSetConditionalAppearance(Form);
	ItemSearchByBarcodeFillInItemBarcodes(Form);
	
EndProcedure

// See WorkingWithProductItemsOverridable.SearchForProductsByBarcodeProcessingFillInChecks.
Procedure SearchForProductsByBarcodeProcessingFillInChecks(Form, Cancel, CheckedAttributes) Export
	
	ItemsBarcodes = Form.ItemsBarcodes;
	
	InformationRegisters.ItemsBarcodes.CheckBatchCompletion(ItemsBarcodes, Cancel);
	InformationRegisters.ItemsBarcodes.CheckingNonUniqueItemBarcodes(ItemsBarcodes, Cancel);
	
EndProcedure

// See WorkingWithProductItemsOverridable.RegisterBarcodes.
Procedure RegisterBarcodes(ItemsBarcodes) Export
	
	InformationRegisters.ItemsBarcodes.RegisterProductsBarcodes(ItemsBarcodes);
	
EndProcedure

// See WorkingWithProductItemsOverridable.ItemSearchByBarcodeBarcodeData.
Procedure ItemSearchByBarcodeBarcodeData(BarcodeData_) Export
	
	BarcodeData_.Insert("Registered",				False);
	BarcodeData_.Insert("RegisteredByDataProcessor",	False);
	BarcodeData_.Insert("Series",						Undefined);
	BarcodeData_.Insert("Package",						Undefined);
	
EndProcedure


#EndRegion


#EndRegion

#Region Private


Procedure SearchForItemsByBarcodeInitializeForm(Form)
	
	Items = Form.Items;
	
	RelationshipOfSelectionParameterWithItem		= New ChoiceParameterLink(
														"Products",
														"Items.ItemsBarcodes.CurrentData.Products",
														LinkedValueChangeMode.DontChange);
	RelationshipOfSelectionParameterWithCharacteristic	= New ChoiceParameterLink("Characteristic",
														"Items.ItemsBarcodes.CurrentData.Characteristic",
														LinkedValueChangeMode.DontChange);
	
	// Relationships of the selection parameters with the item
	ChoiceParameterLinks = New Array;
	ChoiceParameterLinks.Add(RelationshipOfSelectionParameterWithItem);
	
	// The relationship of the series with the item.
	ConnectionsOfBatchSelectionParameters = New Array;
	ConnectionsOfBatchSelectionParameters.Add(RelationshipOfSelectionParameterWithItem);
	ConnectionsOfBatchSelectionParameters.Add(RelationshipOfSelectionParameterWithCharacteristic);
	
	// Package selection parameters.
	PackagingSelectionParameters = New Array;
	PackagingSelectionParameters.Add(New ChoiceParameter("ShowCargoItems", True));
	PackagingSelectionParameters.Add(New ChoiceParameter("ShowMeasuredUnitsOfMeasure", False));
	
	Items.ItemsBarcodesCharacteristic.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	
	// Adding details
	BooleanType = New TypeDescription("Boolean");
	
	AttributesToAddArray = New Array;
	AttributesToAddArray.Add(New FormAttribute(
												"ThereAreAlcoholicProducts",
												BooleanType));
	AttributesToAddArray.Add(New FormAttribute(
												"UsePeripherals",
												BooleanType));
	AttributesToAddArray.Add(New FormAttribute(
												"SupportedPeripheralTypes",
												New TypeDescription("String")));
	AttributesToAddArray.Add(New FormAttribute(
												"Series",
												New TypeDescription("CatalogRef.ItemsBatches"),
												"ItemsBarcodes"));
	AttributesToAddArray.Add(New FormAttribute(
												"Package",
												New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"),
												"ItemsBarcodes"));
	AttributesToAddArray.Add(New FormAttribute(
												"SeriesAreUsed",
												BooleanType, "ItemsBarcodes"));
	Form.ChangeAttributes(AttributesToAddArray);
	
	// Adding Elements
	
	
	NewItem				= Items.Insert(
									"GroupPackagingUnitOfMeasurement",
									Type("FormGroup"),
									Items.ItemsBarcodes,
									Items.ItemsBarcodesCount);
	NewItem.Type			= FormGroupType.ColumnGroup;
	NewItem.Title		= NStr("vi = 'Gói, hộp, đơn vị tính';
								|ru = 'Упаковка, единица измерения';
								|en = 'Packaging unit, UOM'; fa = 'واحد بسته‌بندی، واحد اندازه‌گیری';
								|it = 'Imballaggio, unità di misura';
								|pl = 'Opakowanie, jednostka miary';
								|tr = 'Paketleme ünitesi, ölçü birimi'");
	NewItem.Group	= ColumnsGroup.InCell;
	NewItem.Visible		= True;
	
	NewItem							= Items.Insert(
												"Package",
												Type("FormField"),
												Items.GroupPackagingUnitOfMeasurement);
	NewItem.Type						= FormFieldType.InputField;
	NewItem.ShowInHeader			= False;
	NewItem.DataPath				= "ItemsBarcodes.Package";
	NewItem.ChoiceParameterLinks		= New FixedArray(ChoiceParameterLinks);
	NewItem.ChoiceParameters			= New FixedArray(PackagingSelectionParameters);
	NewItem.Visible					= True;
	NewItem.ChoiceButton				= True;
	NewItem.DropListButton	= False;
	NewItem.ChoiceButtonRepresentation	= ChoiceButtonRepresentation.ShowInInputField;
	NewItem.ChoiceForm				= "Catalog.PackagesAndUnitsOfMeasure.Form.FormOfSelectionFromDocuments";
	NewItem.Width						= 10;
	
	NewItem.SetAction("OnChange", "Attachable_SearchForItemsByBarcodeONChange");
	
	Item = Items.Find("ItemsBarcodesUnitOfMeasure");
	Item.ShowInHeader	= False;
	Item.Visible			= False;
	
	Items.Move(Item, Items.GroupPackagingUnitOfMeasurement);
	
	NewItem				= Items.Insert(
									"UnitOfMeasure",
									Type("FormField"),
									Items.GroupPackagingUnitOfMeasurement);
	NewItem.Type			= FormFieldType.InputField;
	NewItem.Title		= NStr("vi = 'Đơn vị tính';
								|ru = 'Ед. изм.';
								|en = 'Unit'; fa = 'واحد';
								|it = 'Unità di misura';
								|pl = 'J. m.';
								|tr = 'Ölçü birimi'");
	NewItem.DataPath	= "ItemsBarcodes.Products.UnitOfMeasure";
	NewItem.Visible		= True;
	NewItem.Width			= 8;
	
	NewItem							= Items.Insert(
												"Series",
												Type("FormField"),
												Items.ItemsBarcodes,
												Items.GroupPackagingUnitOfMeasurement);
	NewItem.Type						= FormFieldType.InputField;
	NewItem.Title					= NStr("vi = 'Sê-ri';
											|ru = 'Серия';
											|en = 'Batch'; fa = 'بچ';
											|it = 'Serie';
											|pl = 'Seria';
											|tr = 'Parti'");
	NewItem.DataPath				= "ItemsBarcodes.Series";
	NewItem.ChoiceParameterLinks		= New FixedArray(ConnectionsOfBatchSelectionParameters);
	NewItem.Visible					= GetFunctionalOption("UseItemsBatchWarehouse");
	NewItem.ChoiceButton				= True;
	NewItem.DropListButton	= False;
	NewItem.ChoiceButtonRepresentation	= ChoiceButtonRepresentation.ShowInInputField;
	NewItem.Width						= 16;
	
	NewItem.SetAction("OnChange", "Attachable_SearchForItemsByBarcodeONChange");
	
	
EndProcedure

Procedure SearchForItemsByBarcodeSetConditionalAppearance(Form)
	
	ConditionalAppearance = Form.ConditionalAppearance;
	
	If GetFunctionalOption("UseItemsBatchWarehouse") Then
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("Series");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ItemsBarcodes.SeriesAreUsed");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng sê-ri>';
														|ru = '<серии не используются>';
														|en = '<batches are not used>'; fa = '<batches are not used>';
														|it = '<le serie non sono utilizzate>';
														|pl = '<serie nie są używane>';
														|tr = '<partiler kullanılmamaktadır>'"));
		Item.Appearance.SetParameterValue("ReadOnly", True);
	EndIf;
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField	= "UnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField			= "ItemsBarcodes.Package";
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
	
EndProcedure

Procedure ItemSearchByBarcodeFillInItemBarcodes(Form)
	
	ItemsBarcodes			= Form.ItemsBarcodes;
	TableOfItemBarcodes	= ItemsBarcodes.Unload(); // ValueTable -
	Barcodes						= TableOfItemBarcodes.UnloadColumn("Barcode");
	CachedValues			= BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	FillableProperties				= "Products, Characteristic, Series, Package, ItemVariantsAreUsed, 
										|SeriesAreUsed";
	
	TableOfItemBarcodes.Clear();
	TableOfItemBarcodes.Indexes.Add("Barcode");
	
	InformationRegisters.ItemsBarcodes.GetDataOnBarcodesAdvanced(CachedValues, Barcodes);
	
	For Each TSRow In ItemsBarcodes Do
		BarcodeData_1 = CachedValues.Barcodes[TSRow.Barcode];
		FoundRow = TableOfItemBarcodes.Find(TSRow.Barcode, "Barcode");
		
		If FoundRow = Undefined Then
			NewRow = TableOfItemBarcodes.Add();
			FillPropertyValues(NewRow, BarcodeData_1, FillableProperties);
			
			If BarcodeData_1.UnknownBarcode Then
				NewRow.Registered = False;
			ElsIf Not BarcodeData_1.ItemsBarcode Then
				NewRow.Registered = False;
			Else
				NewRow.Registered = True;
			EndIf;
			
			NewRow.Barcode					= TSRow.Barcode;
			NewRow.Count					= TSRow.Count;
			NewRow.SearchInTheServiceWasNotUsed	= True;
		Else
			FoundRow.Count = FoundRow.Count + TSRow.Count;
		EndIf;
	EndDo;
	
	ItemsBarcodes.Load(TableOfItemBarcodes);
	
EndProcedure


#EndRegion
