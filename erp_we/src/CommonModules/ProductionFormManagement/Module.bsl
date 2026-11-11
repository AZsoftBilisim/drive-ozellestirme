////////////////////////////////////////////////////////////////////////////////
// Procedures for managing the forms of the "Production" subsystem
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ConfiguringForms

#Region ConditionalAppearance

#Region SupplyWithMaterialsAndWorks

// Adds conditional registration of production support to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  ItemsNames   - See ProductionFormManagement.NamesOfMaterialAndWorkSupportElements
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure EstablishConditionalAppearanceOfProvisionOfMaterialsAndWorks(Form, ObjectName, TSName, ItemsNames, DataPaths = Undefined) Export

	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	// StandardAppearance
	#Region Items_Characteristics_Batch
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = ItemsNames.TSProductsUnitOfMeasure;
	ConditionalDesignParameters.PathToPackagingUnitField = ObjectName + "." + TSName + ".Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		Form, 
		ItemsNames.TSCharacteristic,
		ObjectName + "." + TSName + ".ItemVariantsAreUsed");

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		Form, 
		"SeriesAlwaysWHGoods", 
		ItemsNames.TSSeries, 
		ObjectName + "." + TSName + ".BatchesIndicationStatus", 
		ObjectName + "." + TSName + ".ItemsType");
	
	#EndRegion
	
	// The prohibition of editing the specification if the flag is not set is performed
	#Region Provision_Specification_ViewOnly
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSBillOfMaterials);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = PathDataLayoutField(ObjectName, DataPaths, "DynamicStructure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Produced");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<được chỉ định khi sản xuất trong quy trình>';
													|ru = '<указывается при производстве в процессе>';
													|en = '<specified during production in the process>'; fa = '<specified during production in the process>';
													|it = '<viene indicato durante la produzione nel processo>';
													|pl = '<jest określane przy produkcji w toku>';
													|tr = '<süreçte üretim esnasında belirtilmektedir>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	#EndRegion
	
	// Warehouse, mark empty
	#Region WarehouseMarkEmpty
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSWarehouse);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".WarehouseIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	// The warehouse can be selected only for goods
	#Region ViewOnlyWarehouse
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSWarehouse);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	// Representation of fields when canceling rows
	#Region CancelLines
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSWarehouse);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSDateOfShipment);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSNumberOfPackages);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items[ItemsNames.TSName],
		ItemsNames.TSCanceled,
		ItemsNames.TSCancellationReason,
		ItemsNames.TSPrice,
		ItemsNames.TSSum);
	
	#EndRegion
	
	SetConditionalAppearanceOfCalculationArticle(
		Form, ObjectName, TSName, ItemsNames.TSProductCostElement, DataPaths, True);
		
	#Region DateOfShipment
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance,
		ItemsNames.DateOfShipment,
		ObjectName + ".DateOfShipment",
		"DateOfShipmentRequired_");
	
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(Form);
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance,
		ItemsNames.TSDateOfShipment,
		ObjectName + "." + TSName + ".DateOfShipment",
		ObjectName + "." + TSName + ".DateOfShipmentRequired_");
	
	#EndRegion
	
	ProvisionInDocumentsServer.SetConditionalAppearanceApart(
		ConditionalAppearance,
		Items[ItemsNames.TSWithAssignment],
		ObjectName + "." + TSName + ".SupplyOption",
		ObjectName + "." + TSName + ".ItemsType");
		
	// The flag cannot be removed separately for semi-finished products in the process
	#Region ApartFromOnlyViewing
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSWithAssignment);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Produced");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	// The destination cannot be changed during the Ship action, for containers and for semi-finished products in the process,
	// at the stage of a non-dynamic order if the flag is removed Separately
	#Region AppointmentViewOnly
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSPurpose);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ItemsType");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSPurpose);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".SupplyOption");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.SupplyOptions.Ship;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSPurpose);

	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Produced");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSPurpose);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".WithAssignment");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = PathDataLayoutField(ObjectName, DataPaths, "DynamicStructure");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	// The assignment does not need to be filled in for tare and canceled lines
	#Region AssignmentCheckingEmptyField
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSPurpose);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ItemsType");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = True;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Produced");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = True;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".WithAssignment");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	#Region PurposePresentation
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSPurpose);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ItemsType");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<dành cho hàng hóa và công việc>';
													|ru = '<для товаров и работ>';
													|en = '<for goods and works>'; fa = '<for goods and works>';
													|it = '<per beni e opere>';
													|pl = '<dla towarów i robót>';
													|tr = '<ürünler ve işler için>'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSPurpose);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ItemsType");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".WithAssignment");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	#EndRegion
	
	#Region OnlyViewingIsPerformed
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TSProduced);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ItemsType");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region FinishedProductBeingRepaired
	
	If ValueIsFilled(ItemsNames.TSUnderRepairProduct) Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(ItemsNames.TSUnderRepairProduct);
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = PathDataLayoutField(ObjectName, DataPaths, "WorkPlanning");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = True;
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".UnderRepairProduct");
		Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<được chỉ định để tham khảo>';
														|ru = '<указывается справочно>';
														|en = '<specified for reference>'; fa = '<مشخص‌شده برای مرجع>';
														|it = '<specified for reference>';
														|pl = '<specified for reference>';
														|tr = '<referans olarak belirtilir>'"));
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(ItemsNames.TSUnderRepairProduct);
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = PathDataLayoutField(ObjectName, DataPaths, "WorkPlanning");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = False;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
														|ru = '<не используется>';
														|en = '<not used>'; fa = '<استفاده نمی‌شود>';
														|it = '<non viene utilizzato>';
														|pl = '<nie używa się>';
														|tr = '<kullanılmayan>'"));
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
			Form,
			ItemsNames.TSUnderRepairVariant,
			ObjectName + "." + TSName + ".FinishedProductBeingRepairedCharacteristicsAreUsed");

		ProductsServer.EstablishConditionalAppearanceOfProductSeries(
			Form,
			"SeriesAlwaysWHGoods",
			ItemsNames.TSUnderRepairBatch,
			ObjectName + "." + TSName + ".UnderRepairBatchSpecificationStatus", 
			ObjectName + "." + TSName + ".RepairedFinishedProductTypeOfItem");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Adds a conditional design for the Support Option field to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure SetConditionalAppearanceOfSecurityFields(Form, ObjectName, TSName, DataPaths = Undefined) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	#Region Warehouse
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[TSName + "Warehouse"].Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".SupplyOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyOptions.TransferedEarlier;
	
	Item.Appearance.SetParameterValue("Text",                 NStr("vi = '<không cần>';
																	|ru = '<не требуется>';
																	|en = '<not required>'; fa = '<الزامی نیست>';
																	|it = '<non richiesto>';
																	|pl = '<nie jest wymagane>';
																	|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("TextColor",            StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	
	#EndRegion
	
EndProcedure

// Adds a conditional design for the Upload date field to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure EstablishConditionalAppearanceOfShipmentDate(Form, ObjectName, TSName, DataPaths = Undefined) Export
	
	// Visibility when using a common date
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[TSName + "DateOfShipment"].Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + ".NotShipInInstallments");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Mandatory filling for previously submitted
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[TSName + "DateOfShipment"].Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".SupplyOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyOptions.TransferedEarlier;
	
	Item.Appearance.SetParameterValue("Text",                 NStr("vi = '<không cần>';
																	|ru = '<не требуется>';
																	|en = '<not required>'; fa = '<الزامی نیست>';
																	|it = '<non richiesto>';
																	|pl = '<nie jest wymagane>';
																	|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("TextColor",            StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	
EndProcedure

#EndRegion

// Adds a conditional design for the articulation field to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  TagName      - String - the name of the form element to be drawn.
//  DataPaths      - Structure, Undefined - the path to the data.
//  ThereIsCancellationOfLines  - Boolean - indicates whether lines are canceled.
//
Procedure SetConditionalAppearanceOfCalculationArticle(Form, ObjectName, TSName, TagName, DataPaths = Undefined, ThereIsCancellationOfLines = False) Export
	
	// Description:
	// - the calculation article is required in the status Started and Completed if the line is not canceled.
	ConditionalAppearance = Form.ConditionalAppearance;
	
	StatusesList = New ValueList;
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.Initiated);
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.Completed);
	StatusesList.Add(Enums.TollingOrderStatuses.ForFulfillment);
	StatusesList.Add(Enums.TollingOrderStatuses.ToSupply);
	StatusesList.Add(Enums.TollingOrderStatuses.Closed);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	NewItem = ConditionalAppearanceItem.Fields.Items.Add();
	NewItem.Field = New DataCompositionField(TagName);
	
	SelectionGroupOr = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = PathDataLayoutField(ObjectName, DataPaths, "Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = StatusesList;
	
	If ThereIsCancellationOfLines Then
		
		ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
	EndIf;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

#Region Other

// Forms the structure of the names of the form elements to be formed.
// 
// Returns:
//  Structure - Names Of Production Stage Security Elements:
// * DateOfShipment - String - name of the element on the form
// * TSName - String - name of the table part of the form element
// * TSProductsUnitOfMeasure - String - name of the column in the table part
// * TSCharacteristic - String - name of the column in the table part
// * TSSeries - String - name of the column in the table part
// * TSBillOfMaterials - String - name of the column in the table part
// * TSWarehouse - String - name of the column in the table part
// * TSDateOfShipment - String - name of the column in the table part
// * TSNumberOfPackages - String - name of the column in the table part
// * TSPrice - String - name of the column in the table part
// * TSSum - String - name of the column in the table part
// * TSCanceled - String - name of the column in the table part
// * TSCancellationReason - String - name of the column in the table part
// * TSWithAssignment - String - name of the column in the table part
// * TSProductCostElement - String - name of the column in the table part
// * TSPurpose - String - name of the column in the table part
// * TSProduced - String - name of the column in the table part
// * TSUnderRepairProduct - String - name of the column in the table part
// * TSUnderRepairVariant - String - name of the column in the table part
Function NamesOfMaterialAndWorkSupportElements() Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("DateOfShipment");
	ReturnValue.Insert("TSName");
	ReturnValue.Insert("TSProductsUnitOfMeasure");
	ReturnValue.Insert("TSCharacteristic");
	ReturnValue.Insert("TSSeries");
	ReturnValue.Insert("TSBillOfMaterials");
	ReturnValue.Insert("TSWarehouse");
	ReturnValue.Insert("TSDateOfShipment");
	ReturnValue.Insert("TSNumberOfPackages");
	ReturnValue.Insert("TSPrice");
	ReturnValue.Insert("TSSum");
	ReturnValue.Insert("TSCanceled");
	ReturnValue.Insert("TSCancellationReason");
	ReturnValue.Insert("TSWithAssignment");
	ReturnValue.Insert("TSProductCostElement");
	ReturnValue.Insert("TSPurpose");
	ReturnValue.Insert("TSProduced");
	ReturnValue.Insert("TSUnderRepairProduct");
	ReturnValue.Insert("TSUnderRepairVariant");
	ReturnValue.Insert("TSUnderRepairBatch");
	Return ReturnValue;

EndFunction

// The data layout field along the path.
// 
// Parameters:
//  ObjectName - String - Object name
//  DataPaths - Structure - Data paths
//  FieldName - String - field name
// 
// Returns:
//  DataCompositionField - Field layout of the data on the way
//
Function PathDataLayoutField(ObjectName, DataPaths, FieldName) Export
	
	FieldDataPath = CommonClientServer.StructureProperty(DataPaths, FieldName, ObjectName + "." + FieldName);
	Return New DataCompositionField(FieldDataPath);
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndRegion
