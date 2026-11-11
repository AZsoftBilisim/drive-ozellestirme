
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Stage   = Parameters.Stage;
	Mode  = Parameters.Mode;
	
	Parameters.Property("AddressOfProcessRecordingParameters", AddressOfProcessRecordingParameters);
	Parameters.Property("AddressOfStageUpdateParameters",   AddressOfStageUpdateParameters);
	Parameters.Property("AddressOfStageDataToUpdate",    AddressOfStageDataToUpdate);
	
	FillInServiceDetails();
	
	FillInData();
	
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	SetSelectionOfOperations();
	
EndProcedure

&AtClient
Procedure OnlyChangedItems(Item)
	
	SetSelectionOfModifiedRows(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSupplyWithMaterialsAndWorks

&AtClient
Procedure SupplyWithMaterialsAndWorksOnActivateRow(Item)
	
	SetSelectionOfOperations();
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksMarkOnChange(Item)
	
	FillInQuantityResult(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtClient
Procedure ManufacturedProductsOnActivateRow(Item)
	
	SetSelectionOfOperations();
	
EndProcedure

&AtClient
Procedure ManufacturedProductsMarkOnChange(Item)
	
	FillInQuantityResult(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsCostTypeOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If CurrentData.CostType = PredefinedValue("Enum.CostTypesOfFinishedProducts.Calculating") Then
		CurrentData.ProductCostElement = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsOnActivateRow(Item)
	
	SetSelectionOfOperations();
	
EndProcedure

&AtClient
Procedure LaborCostsMarkOnChange(Item)
	
	FillInQuantityResult(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAll(Command)
	
	ClearMessages();
	
	DataToEndEditing = PrepareDataForEndOfEditing();
	
	If Not DataToEndEditing.SettingsCheckPassed Then
		
		Return;
	
	ElsIf Not DataToEndEditing.ThereAreActionsToBePerformed Then
		
		Close(ClosingParameters(True));
		
	ElsIf Mode = ProductionProcessEditorClientServer.ModeFromStageForm() Then
		
		Close(ClosingParameters(True, True));
		
	Else
		
		StartRecordingProcessData(DataToEndEditing);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordOnlyTechnicalProcess(Command)
	
	Close(ClosingParameters(True));
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	SelectOrClearAll(True);
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	SelectOrClearAll(False);
	
EndProcedure

&AtClient
Procedure HowToFillInTheCalculationArticle(Command)
	
	FillInCalculationArticleInLines("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure Issue_FillOutCalculationArticle(Command)
	
	FillInCalculationArticleInLines("ManufacturedProducts", "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure LaborCostsFillInTheCalculationArticle(Command)
	
	FillInCalculationArticleInLines("LaborCosts");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	For Each KeyAndValue In DescriptionOfTables(ThisObject) Do
		
		DescriptionOfTS = KeyAndValue.Value; // See DescriptionOfConstructorTable
		
		//
		Item = ConditionalAppearance.Items.Add();
		Item.Fields.Items.Add().Field = New DataCompositionField(DescriptionOfTS.ActionElement);
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".Mark");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = False;
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".ReadOnly");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = False;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("Text", DoNotModifyComment());
		
		//
		Item = ConditionalAppearance.Items.Add();
		Item.Fields.Items.Add().Field = New DataCompositionField(DescriptionOfTS.ActionElement);
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".ReadOnly");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("Text", New DataCompositionField(DescriptionOfTS.TSName+".Comment"));
		
		//
		Item = ConditionalAppearance.Items.Add();
		Item.Fields.Items.Add().Field = New DataCompositionField(DescriptionOfTS.TSName);
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".ReadOnly");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = True;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		//
		Item = ConditionalAppearance.Items.Add();
		Item.Fields.Items.Add().Field = New DataCompositionField(DescriptionOfTS.ElementQuantityProcessTechnology);
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".NumberOfTechnicalProcesses");
		Filter.ComparisonType = DataCompositionComparisonType.NotEqual;
		Filter.RightValue = New DataCompositionField(DescriptionOfTS.TSName+".CountStage");
		
		Item.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
		
		//
		Item = ConditionalAppearance.Items.Add();
		Item.Fields.Items.Add().Field = New DataCompositionField(DescriptionOfTS.QuantityResultElement);
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".CountStage");
		Filter.ComparisonType = DataCompositionComparisonType.NotEqual;
		Filter.RightValue = New DataCompositionField(DescriptionOfTS.TSName+".QuantityResult");
		
		Item.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
		
		//
		Item = ConditionalAppearance.Items.Add();
		Item.Fields.Items.Add().Field = New DataCompositionField(DescriptionOfTS.ArrowPictureElement);
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".Mark");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = False;
		
		Item.Appearance.SetParameterValue("Show", False);
		
		For Each KeyAndValue In ParametersForCheckingFillingInAttributes(DescriptionOfTS.TSName) Do
			
			Setting = KeyAndValue.Value;
			
			//
			Item = ConditionalAppearance.Items.Add();
			Item.Fields.Items.Add().Field = New DataCompositionField(Setting.Item);
			
			Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".Action");
			Filter.ComparisonType = DataCompositionComparisonType.InList;
			Filter.RightValue = ProductionProcessEditorClientServer.ActionsChangeExistingOnes();
			
			Item.Appearance.SetParameterValue("ReadOnly", True);
			If Setting.HideValue Then
				Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
				Item.Appearance.SetParameterValue("Text", NStr("vi = '<trong số chứng từ>';
																|ru = '<из документа>';
																|en = '<from document>'; fa = '<from document>';
																|it = '<from document>';
																|pl = '<from document>';
																|tr = '<belgeden>'"));
			EndIf;
			
			//
			Item = ConditionalAppearance.Items.Add();
			Item.Fields.Items.Add().Field = New DataCompositionField(Setting.Item);
			
			Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".Action");
			Filter.ComparisonType = DataCompositionComparisonType.Equal;
			Filter.RightValue = ActionAdd();
			
			Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+"."+KeyAndValue.Key);
			Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".Mark");
			Filter.ComparisonType = DataCompositionComparisonType.Equal;
			Filter.RightValue = True;
			
			If DescriptionOfTS.TSName = "ManufacturedProducts"
				And KeyAndValue.Key = "ProductCostElement" Then
				
				Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
				Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".CostType");
				Filter.ComparisonType = DataCompositionComparisonType.Equal;
				Filter.RightValue = Enums.CostTypesOfFinishedProducts.Fixed;
				
			EndIf;
			
			Item.Appearance.SetParameterValue("MarkIncomplete", True);
			
			//
			If DescriptionOfTS.TSName = "ManufacturedProducts"
				And KeyAndValue.Key = "ProductCostElement" Then
				
				Item = ConditionalAppearance.Items.Add();
				Item.Fields.Items.Add().Field = New DataCompositionField(Setting.Item);
					
				Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
				Filter.LeftValue = New DataCompositionField(DescriptionOfTS.TSName+".CostType");
				Filter.ComparisonType = DataCompositionComparisonType.Equal;
				Filter.RightValue = Enums.CostTypesOfFinishedProducts.Calculating;
					
				Item.Appearance.SetParameterValue("ReadOnly", True);
			
			EndIf;
			
		EndDo;
		
	EndDo;
	
	//
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "ManufacturedProducts.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "SupplyWithMaterialsAndWorksProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "SupplyWithMaterialsAndWorks.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "ManufacturedProductsCharacteristic", "ManufacturedProducts.ItemVariantsAreUsed");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "SupplyWithMaterialsAndWorksCharacteristic", "SupplyWithMaterialsAndWorks.ItemVariantsAreUsed");
	
	EstablishConditionalAppearanceOfProvisionOfMaterialsAndWorks();
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfProvisionOfMaterialsAndWorks()
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksSupplyAssignment.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("SupplyWithMaterialsAndWorks.SupplyAssignment");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = New DataCompositionField("Object.Purpose");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Công đoạn hiện tại';
													|ru = 'Текущий этап';
													|en = 'Current step'; fa = 'مرحله جاری';
													|it = 'Fase corrente';
													|pl = 'Bieżący etap';
													|tr = 'Mevcut aşama'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksSupplyAssignment.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("SupplyWithMaterialsAndWorks.ItemsType");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("SupplyWithMaterialsAndWorks.CountStage");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với hàng hóa và công việc>';
													|ru = '<для товаров и работ>';
													|en = '<for goods and labor>'; fa = '<for goods and labor>';
													|it = '<per beni e opere>';
													|pl = '<dla towarów i robót>';
													|tr = '<ürünler ve işler için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	ProvisionInDocumentsServer.SetConditionalAppearanceApart(
		ConditionalAppearance,
		Items.SupplyWithMaterialsAndWorksWithAssignment,
		"SupplyWithMaterialsAndWorks.SupplyOption",
		"SupplyWithMaterialsAndWorks.ItemsType");
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksSupplyAssignment.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("SupplyWithMaterialsAndWorks.WithAssignment");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.DynamicStructure");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksSupplyAssignment.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("SupplyWithMaterialsAndWorks.SupplyAssignment");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = New DataCompositionField("Object.Purpose");
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("SupplyWithMaterialsAndWorks.WithAssignment");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);
	
	// The warehouse can be selected only for goods
	SetConditionalAppearanceOfWarehouse("SupplyWithMaterialsAndWorks", Items.SupplyWithMaterialsAndWorksWarehouse.Name);
	SetConditionalAppearanceOfWarehouse("ManufacturedProducts", Items.ManufacturedProductsWarehouse.Name);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfWarehouse(TableName, TagName)
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TagName);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(StrTemplate("%1.ItemsType", TableName));
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.ItemsTypes.Work_5;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(StrTemplate("%1.CountStage", TableName));
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	Title = StrTemplate("%1 %2", Title, Parameters.PresentationStage);
	
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	Items.LaborCostsProductCostElement.Visible = Not Object.OperationAsOutputReference;
	Items.LaborCostsFillInTheCalculationArticle.Visible = Not Object.OperationAsOutputReference;
	
	OnlyChangedItems = True;
	DisplayedRows = SetSelectionOfModifiedRows(ThisObject);
	
	SetCurrentPage(DisplayedRows);

	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize
		Or AttributesStructure1.Property("InfoBar") Then
		
		Items.InformationPanelGroup.Visible = ValueIsFilled(Items.InfoBarLabel.Title);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCurrentPage(DisplayedRows = Undefined)
	
	PageHasLines = Undefined;
	
	For Each KeyAndValue In DescriptionOfTables(ThisObject) Do
		DescriptionOfTS = KeyAndValue.Value;
		If ThereAreActionsToBePerformed(ThisObject, DescriptionOfTS.TSName) Then
			Items.GroupPages.CurrentPage = Items[DescriptionOfTS.PageItem];
			Return;
		EndIf;
		If PageHasLines = Undefined
			And DisplayedRows <> Undefined
			And DisplayedRows[DescriptionOfTS.TSName] > 0 Then
			PageHasLines = Items[DescriptionOfTS.PageItem]
		EndIf;
	EndDo;
	
	If PageHasLines <> Undefined Then
		Items.GroupPages.CurrentPage = PageHasLines;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	LongTermOperationsStructure = New Structure("DataWriter");
	
	StageObject = Stage.GetObject();
	ValueToFormAttribute(StageObject, "Object");
	
	AttributesList = New Array;
	AttributesList.Add("Contract");
	AttributesList.Add("Partner");
	AttributesList.Add("LineOfBusiness");
	AttributesList.Add("BusinessOperation");
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Object.Department);
	
	ParametersForFillingAssignments = ProductionSupply.ActionParametersFillInPurposeOfProvisionInProductionPhase(
		Object, Object.ManufacturedProducts);
		
	If Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		Or False Then
		PurposeOfTollRelease = Documents.ProductionStage2_2.DefaultAssignmentForByProducts(Object.ReferenceOrder);
	EndIf;
	
	CostAllocationParameters = New FixedStructure(Documents.ProductionStage2_2.CostAllocationParameters(Object));
	
	ProductionSupply.FillInListOfSelectedAssignmentsInProductionPhase(
		Object, Object.ManufacturedProducts, RefsFilterInSelectionOfAssignmentsForm);
	
	Items.SupplyWithMaterialsAndWorksSupplyAssignment.ChoiceList.LoadValues(
		RefsFilterInSelectionOfAssignmentsForm.UnloadValues());
	
	FillPropertyValues(ThisObject, Object, StrConcat(AttributesList, ","));
	
EndProcedure

&AtServer
Procedure FillInData()
	
	AddressOfStageUpdateParameters = Undefined;
	If Not Parameters.Property("AddressOfStageUpdateParameters", AddressOfStageUpdateParameters)
		Or Not IsTempStorageURL(AddressOfStageUpdateParameters) Then
		Return;
	EndIf;
	
	ParametersOfUpdate = GetFromTempStorage(AddressOfStageUpdateParameters);
	
	TSDescriptions = DescriptionOfTables(ThisObject);
	
	For Each String In ParametersOfUpdate.MappingTable Do
		DescriptionOfTS = TSDescriptions[String.TSName];
		If DescriptionOfTS.Use Then
			Table = ThisObject[DescriptionOfTS.TSName]; // FormTable
			NewRow = Table.Add();
			FillPropertyValues(NewRow, String);
			FillInServiceAttributesOfResourceLine(ThisObject, NewRow, DescriptionOfTS);
			NewRow.LineNumber = Table.Count();
		EndIf;
	EndDo;
	
	CheckFillInCostTypeOfOutputProducts();
	
	ParametersOfUpdate.ProcessTechnologyResources.GroupBy(
		"Products,Characteristic,WorkKind,OperationNumber,NameOfTheOperation", "Count");
	ParametersOfUpdate.ProcessTechnologyResources.Sort("OperationNumber,NameOfTheOperation");
	ResourcesByOperations.Load(ParametersOfUpdate.ProcessTechnologyResources);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ProductsServer.FillInServiceDetailsForProductInCollection(ManufacturedProducts, StructureOfActions);
	ProductsServer.FillInServiceDetailsForProductInCollection(SupplyWithMaterialsAndWorks, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Function SetSelectionOfModifiedRows(Form)
	
	Result = New Structure;
	
	For Each KeyAndValue In DescriptionOfTables(Form) Do
		
		DescriptionOfTS = KeyAndValue.Value; // See DescriptionOfConstructorTable
		
		If Form.OnlyChangedItems Then
			Filter = New Structure("IsChanged", True);
			RowFilter = New FixedStructure(Filter);
			RowsCount = Form[DescriptionOfTS.TSName].FindRows(Filter).Count();
		Else
			RowFilter = Undefined;
			RowsCount = Form[DescriptionOfTS.TSName].Count();
		EndIf;
		
		Table = Form.Items[DescriptionOfTS.TSName]; // FormTable
		Table.RowFilter = RowFilter;
		
		Page = Form.Items[DescriptionOfTS.PageItem]; // FormGroup
		Page.Title = DescriptionOfTS.Title + ?(RowsCount > 0, " ("+RowsCount+")", "");
		
		Result.Insert(DescriptionOfTS.TSName, RowsCount);
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure SetSelectionOfOperations()
	
	Filter = New Structure;
	Filter.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	Filter.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	Filter.Insert("WorkKind", PredefinedValue("Catalog.EmployeeWorkKinds.EmptyRef"));
	
	CurrentData = Items[TableIsCurrent(ThisObject).TSName].CurrentData;
	If CurrentData <> Undefined Then
		
		FillPropertyValues(Filter, CurrentData);
		
	EndIf;
	
	OperationsCount = ResourcesByOperations.FindRows(Filter).Count();
	Items.ResourcesByOperations.RowFilter = New FixedStructure(Filter);
	
	HeaderParts = New Array;
	HeaderParts.Add(NStr("vi = 'Giao dịch';
						|ru = 'Операции';
						|en = 'Operations'; fa = 'عملیات';
						|it = 'Operations';
						|pl = 'Operations';
						|tr = 'İşlemler'"));
	If OperationsCount > 0 Then
		HeaderParts.Add(" (");
		HeaderParts.Add(OperationsCount);
		HeaderParts.Add(")");
	EndIf;
	Items.OperationsResourcesGroup.Title  = StrConcat(HeaderParts);
	
EndProcedure

&AtServer
Procedure FillInServiceAttributesOfResourceLine(Form, RowData, DescriptionOfTS)
	
	RowData.Picture = DescriptionOfTS.Picture;
	
	ProductionProcessEditorClientServer.FillInDefaultActionParameters(RowData, DescriptionOfTS.TSName);
	
	If Not RowData.ReadOnly Then;
		If RowData.Action = ActionAdd()
				Or RowData.Action = ZoomInAction() Then
			RowData.PictureArrow = PictureLib.UpArrow;
		Else
			RowData.PictureArrow = PictureLib.DownArrow;
		EndIf;
	EndIf;
	
	FillOutPurpose(Form, RowData, DescriptionOfTS);
	
	FillInQuantityResult(Form, RowData, DescriptionOfTS);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInQuantityResult(Form, RowData = Undefined, DescriptionOfTS = Undefined)
	
	If DescriptionOfTS = Undefined Then
		DescriptionOfTS = TableIsCurrent(Form);
	EndIf;
	
	If RowData = Undefined Then
		CurrentRow = Form.Items[DescriptionOfTS.TSName].CurrentRow;
		RowData = Form[DescriptionOfTS.TSName].FindByID(CurrentRow);
	EndIf;
	
	If Not RowData.Mark Then
		RowData.QuantityResult = RowData.CountStage;
		If DescriptionOfTS.ThereArePackages Then
			RowData.NumberOfPackagingUnitsResult = RowData.NumberOfPackagingUnitsStage;
		EndIf;
	Else
		RowData.QuantityResult = RowData.NumberOfTechnicalProcesses;
		If DescriptionOfTS.ThereArePackages Then
			RowData.NumberOfPackagingUnitsResult = RowData.NumberOfPackagingUnitsProcessTechnology;
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillOutPurpose(Form, RowData, DescriptionOfTS)
	
	If Not RowData.IsChanged
			Or RowData.ReadOnly Then
		Return;
	EndIf;
	
	If DescriptionOfTS.TSName = "SupplyWithMaterialsAndWorks"
		And RowData.Action = ActionAdd() Then
		RowData.SupplyAssignment = Form.ParametersForFillingAssignments.AssignmentMaterials;
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckFillInCostTypeOfOutputProducts()
	
	NumberOfProducts  = ManufacturedProducts.Count();
	
	ThereIsCalculated = ManufacturedProducts.FindRows(
		New Structure("CostType", Enums.CostTypesOfFinishedProducts.Calculating)).Count();
	
	For IndexOf = 0 To NumberOfProducts - 1 Do
		String = ManufacturedProducts[NumberOfProducts - 1 - IndexOf];
		If ValueIsFilled(String.CostType) Then
			Continue;
		EndIf;
		If Not ThereIsCalculated
			And ProductionManagementClientServer.ThisIsAProductionIssueStage(Object) Then
			String.CostType = Enums.CostTypesOfFinishedProducts.Calculating;
			ThereIsCalculated = True;
		Else
			String.CostType = Enums.CostTypesOfFinishedProducts.Fixed;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Function CheckSettings()
	
	Cancel = False;
	
	MessageTemplate = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 của danh sách ""%3""';
							|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
							|en = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.'; fa = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.';
							|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata';
							|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
							|tr = 'Sütun ""%1"", ""%3"" listesinin %2satırında doldurulmamış'");
	
	For Each KeyAndValue In DescriptionOfTables(ThisObject) Do
		
		DescriptionOfTS = KeyAndValue.Value; // See DescriptionOfConstructorTable
		
		For Each String In ThisObject[DescriptionOfTS.TSName] Do
			If Not String.Mark Then
				Continue;
			EndIf;
			For Each KeyAndValue In ParametersForCheckingFillingInAttributes(DescriptionOfTS.TSName) Do
				
 				If String.CountStage <> 0
 					Or ValueIsFilled(String[KeyAndValue.Key])
 					Or (DescriptionOfTS.TSName = "ManufacturedProducts"
							And KeyAndValue.Key = "ProductCostElement"
							And String.CostType = PredefinedValue("Enum.CostTypesOfFinishedProducts.Calculating"))
					Or (DescriptionOfTS.TSName = "LaborCosts"
							And KeyAndValue.Key = "ProductCostElement"
							And Object.OperationAsOutputReference)
					Or (KeyAndValue.Key = "Warehouse"
							And String.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")) Then
					Continue;
 				EndIf;
 				
				MessageText = StrTemplate(MessageTemplate,
					Items[KeyAndValue.Value.Item].Title, String.LineNumber, DescriptionOfTS.Title);
				DataPath = StrTemplate("%1[%2].%3", DescriptionOfTS.TSName, String.LineNumber-1, KeyAndValue.Key);
				CommonClient.MessageToUser(MessageText,, DataPath,, Cancel);
				
			EndDo;
		EndDo;
		
	EndDo;
	
	Return Not Cancel;
	
EndFunction

#Region UpdatingData

&AtClient
Function PrepareDataForEndOfEditing()
	
	Result = New Structure;
	Result.Insert("SettingsCheckPassed", CheckSettings());
	Result.Insert("ThereAreActionsToBePerformed",  ThereAreActionsToBePerformed(ThisObject));
	
	If Result.SettingsCheckPassed
		And Result.ThereAreActionsToBePerformed Then
		
		CommonClientServer.SupplementStructure(Result, PrepareDataToEndEditingATServer());
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function PrepareDataToEndEditingATServer()
	
	Result = New Structure;
	
	StageObject               = Stage.GetObject();
	StageDataToUpdate = New Structure;
	CachedValues     = Undefined;
	
	For Each KeyAndValue In DescriptionOfTables(ThisObject) Do
		
		DescriptionOfTS = KeyAndValue.Value; // See DescriptionOfConstructorTable
		TSName = DescriptionOfTS.TSName;
		
		If Not ThereAreActionsToBePerformed(ThisObject, TSName) Then
			Continue;
		EndIf;
		
		For Each StageTSName In StrSplit(DescriptionOfTS.StageTSName, ",") Do
			
			ProcessingResult = New Structure;
			ProcessingResult.Insert("ModifiedRows",  New Array);
			ProcessingResult.Insert("AddedRows", New Array);
			
			TheStructureOfTheSearch1     = New Structure(DescriptionOfTS.SearchFields);
			TheStructureOfTheSearch2     = New Structure(DescriptionOfTS.SearchFields);
			
			DocumentTable = StageObject[StageTSName].Unload(); // ValueTable
			DocumentTable.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
			DocumentTable.Indexes.Add("Canceled");
			DocumentTable.Indexes.Add(DescriptionOfTS.SearchFields);
			
			For Each StringAction In ThisObject[TSName] Do
				
				If Not StringAction.Mark Then
					Continue;
				EndIf;
				
				If (StageTSName = "ManufacturedProducts"
						And StringAction.CostType = Enums.CostTypesOfFinishedProducts.Fixed)
					Or (StageTSName = "SideAndIntermediateRelease"
						And StringAction.CostType = Enums.CostTypesOfFinishedProducts.Calculating) Then
					Continue;
				EndIf;
				
				FillPropertyValues(TheStructureOfTheSearch1, StringAction);
				
				If StringAction.Action = ActionAdd() Then
					
					NewRow = DocumentTable.Add();
					FillPropertyValues(NewRow, StringAction);
					NewRow.LineNumber = DocumentTable.Count();
					
					NewRow.Count    = StringAction.NumberOfTechnicalProcesses - StringAction.CountStage;
					NewRow.Department = Object.Department;
					
					If StageTSName = "SupplyWithMaterialsAndWorks" Then
						If NewRow.WithAssignment Then
							NewRow.Purpose = NewRow.SupplyAssignment;
						EndIf;
						If StringAction.ItemsType = Enums.ItemsTypes.Work_5 Then
							NewRow.SupplyOption = ?(NewRow.WithAssignment, Enums.SupplyOptions.ToSupply, Enums.SupplyOptions.NotRequired);
						Else
							NewRow.SupplyOption = Enums.SupplyOptions.ToSupply;
						EndIf;
					EndIf;
					
					If DescriptionOfTS.TSName = "ManufacturedProducts" Then
						NewRow.Recipient = ?(StringAction.ItemsType = Enums.ItemsTypes.Work_5, Object.Department, StringAction.Warehouse);
						NewRow.ProductionDate = ?(StageObject.ProductionInOneDay, StageObject.ProductionDate, CurrentSessionDate());
					EndIf;
					
					ProcessingResult.AddedRows.Add(NewRow);
					
				ElsIf StringAction.Action = ZoomInAction() Then
					
					QuantityIncreaseTotal = StringAction.NumberOfTechnicalProcesses - StringAction.CountStage;
					
					DocumentTable.Sort("Canceled,LineNumber DESC");
					
					For IndexOf = 0 To DocumentTable.Count() - 1 Do
						String = DocumentTable[IndexOf];
						FillPropertyValues(TheStructureOfTheSearch2, String);
						If Common.DataMatch(TheStructureOfTheSearch1, TheStructureOfTheSearch2)
								And ProductionProcessEditorClientServer.YouCanChangeStageString(StageTSName, String, StringAction.Action) Then
							String.Count = String.Count + QuantityIncreaseTotal;
							ProcessingResult.ModifiedRows.Add(String);
							Break;
						EndIf;
					EndDo;
					
				ElsIf StringAction.Action = ReduceAction() Then
					
					QuantityReduceTotal = StringAction.CountStage - StringAction.NumberOfTechnicalProcesses;
					
					DocumentTable.Sort("Canceled,LineNumber DESC");
					
					For IndexOf = 0 To DocumentTable.Count() - 1 Do
						String = DocumentTable[IndexOf];
						FillPropertyValues(TheStructureOfTheSearch2, String);
						If Common.DataMatch(TheStructureOfTheSearch1, TheStructureOfTheSearch2)
								And ProductionProcessEditorClientServer.YouCanChangeStageString(StageTSName, String, StringAction.Action) Then
							If QuantityReduceTotal > 0 Then
								ReduceNumber = Min(String.Count, QuantityReduceTotal);
								String.Count = String.Count - ReduceNumber;
								QuantityReduceTotal = QuantityReduceTotal - ReduceNumber;
								If String.Count > 0 Then
									ProcessingResult.ModifiedRows.Add(String);
								EndIf;
							EndIf;
						EndIf;
					EndDo;
					
				ElsIf StringAction.Action = ActionDelete() Then
					
					For Each String In DocumentTable.FindRows(TheStructureOfTheSearch1) Do
						String.Count = 0;
					EndDo;
					
				EndIf;
				
			EndDo;
			
			For Each FoundRow In DocumentTable.FindRows(New Structure("Count", 0)) Do
				DocumentTable.Delete(FoundRow);
			EndDo;
			
			PerformActionsForArrayOfStrings(ProcessingResult.ModifiedRows, DescriptionOfTS, StageTSName, CachedValues);
			PerformActionsForArrayOfStrings(ProcessingResult.AddedRows, DescriptionOfTS, StageTSName, CachedValues, True);
			
			CheckFillInCostShares(DocumentTable, StageTSName);
			
			DocumentTable.Sort("LineNumber");
			
			StageDataToUpdate.Insert(StageTSName, DocumentTable);
			
		EndDo;
		
	EndDo;
	
	PutToTempStorage(StageDataToUpdate, AddressOfStageDataToUpdate);
	
	ProcessRecordingParameters = Common.CopyRecursive(GetFromTempStorage(AddressOfProcessRecordingParameters));
	ProcessRecordingParameters.Insert("StageDataToUpdate", StageDataToUpdate);
	
	Result.Insert("AddressOfProcessRecordingParameters", PutToTempStorage(ProcessRecordingParameters, UUID));
	
	Return Result;
	
EndFunction

&AtClient
Procedure StartRecordingProcessData(DataToEndEditing, CloseAtEnd = True)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Stage", Stage);
	AdditionalParameters.Insert("Department", Object.Department);
	AdditionalParameters.Insert("CloseAtEnd", CloseAtEnd);
	
	Notification = New CallbackDescription("RecordingOfProcessDataEnd", ThisObject, AdditionalParameters);
	
	ProductionProcessEditorClient.StartRecordingProcessData(
		ThisObject, DataToEndEditing, Notification);
	
EndProcedure

&AtClient
Procedure RecordingOfProcessDataEnd(TimeConsumingOperation, AdditionalParameters) Export
	
	Result = ProductionProcessEditorClient.RecordingOfProcessDataEnd(
		ThisObject, TimeConsumingOperation, AdditionalParameters);
	
	If Result.ThereAreStageRecordingErrors Then
		
		ArrayOfTexts = New Array;
		ArrayOfTexts.Add(Result.ErrorText);
		ArrayOfTexts.Add("");
		ArrayOfTexts.Add(NStr("vi = 'Thực hiện ghi quy trình công nghệ mà không có cập nhật công đoạn?';
								|ru = 'Выполнить запись техпроцесса без обновления этапа?';
								|en = 'Save the technological process without updating the stage?'; fa = 'Save the technological process without updating the stage?';
								|it = 'Save the technological process without updating the stage?';
								|pl = 'Save the technological process without updating the stage?';
								|tr = 'Aşamayı güncellemeden teknolojik süreç kaydı yapılsın mı?'"));
		
		Notification = New CallbackDescription("RecordTechnicalProcessWithoutUpdatingEndStage", ThisObject);
		
		ShowQueryBox(Notification,
			StrConcat(ArrayOfTexts, Chars.LF), QuestionDialogMode.YesNo,,, NStr("vi = 'Lỗi ghi lại dữ liệu';
																				|ru = 'Ошибка записи данных';
																				|en = 'Data saving error'; fa = 'Data saving error';
																				|it = 'Errore di scrittura dei dati';
																				|pl = 'Błąd zapisu danych';
																				|tr = 'Veri kaydı hatası'"));
		
	ElsIf Result.CloseAtEnd Then
		
		Modified = False;
		
		Close(ClosingParameters(,,True));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordTechnicalProcessWithoutUpdatingEndStage(QuestionResult, DataForCreatingTechnicalProcess) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Close(ClosingParameters(True));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PerformActionsForArrayOfStrings(RowsArray, DescriptionOfTS, StageTSName, CachedValues, AddedRows = False)
	
	StructureOfActions = New Structure;
	
	If DescriptionOfTS.ThereArePackages Then
		StructureOfActions.Insert("RecalculateNumberOfPackages");
	EndIf;
	
	If AddedRows Then
		
		If StageTSName = "ManufacturedProducts" Then
			StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
			StructureOfActions.Insert("CheckFillAssignment", PurposeOfTollRelease);
		ElsIf StageTSName = "SideAndIntermediateRelease" Then
			StructureOfActions.Insert("CheckFillAssignment", PurposeOfTollRelease);
		EndIf;
		
	EndIf;
	
	For Each LineOfATabularSection In RowsArray Do
		
		BatchProcessingOfTablePartServer.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckFillInCostShares(DocumentTable, StageTSName)
	
	If StageTSName <> "ManufacturedProducts"
		Or DocumentTable.Count() < 2
		Or Mode = ProductionProcessEditorClientServer.ModeFromStageForm()
		Or Object.MethodOfAllocatingFinishedProductCosts <> Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares Then
		Return;
	EndIf;
	
	For Each String In DocumentTable Do
		If Not ValueIsFilled(String.CostShare) Then
			String.CostShare = 1;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure SelectOrClearAll(Value)
	
	DescriptionOfTS = TableIsCurrent(ThisObject);
	
	For Each String In ThisObject[DescriptionOfTS.TSName] Do
		If Not String.ReadOnly Then
			String.Mark = Value;
			FillInQuantityResult(ThisObject, String, DescriptionOfTS);
		EndIf;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function TableIsCurrent(Form)
	
	Result = DescriptionOfConstructorTable();
	
	For Each KeyAndValue In DescriptionOfTables(Form) Do
		DescriptionOfTS = KeyAndValue.Value;
		If Form.Items[DescriptionOfTS.PageItem] = Form.Items.GroupPages.CurrentPage Then
			Result = KeyAndValue.Value;
		EndIf;
	EndDo;
	
	Return Result
	
EndFunction

&AtClientAtServerNoContext
Function DescriptionOfTables(Form)
	
	Result = New Structure();
	
	LongDesc = DescriptionOfConstructorTable("SupplyWithMaterialsAndWorks");
	LongDesc.Picture   = 2;
	LongDesc.Title  = NStr("vi = 'Đảm bảo';
							|ru = 'Обеспечение';
							|en = 'Supply'; fa = 'Supply';
							|it = 'Supply';
							|pl = 'Supply';
							|tr = 'Tedarik'");
	LongDesc.SearchFields = "Products,Characteristic";
	Result.Insert("MaterialsAndServices", LongDesc);
	
	LongDesc = DescriptionOfConstructorTable("ManufacturedProducts");
	LongDesc.StageTSName = "ManufacturedProducts,SideAndIntermediateRelease";
	LongDesc.Picture   = 4;
	LongDesc.Title  = NStr("vi = 'Xuất xưởng';
							|ru = 'Выпуск';
							|en = 'Release'; fa = 'آزادسازی';
							|it = 'Release';
							|pl = 'Release';
							|tr = 'İmal edilen ürünler'");
	LongDesc.SearchFields = "Products,Characteristic";
	Result.Insert(LongDesc.TSName, LongDesc);
	
	LongDesc = DescriptionOfConstructorTable("LaborCosts");
	LongDesc.Picture   = 3;
	LongDesc.Title  = NStr("vi = 'Công lao động';
							|ru = 'Трудозатраты';
							|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
							|it = 'Labor costs';
							|pl = 'Labor costs';
							|tr = 'İş gücü maliyetleri'");
	LongDesc.ThereArePackages = False;
	LongDesc.SearchFields   = "WorkKind";
	Result.Insert(LongDesc.TSName, LongDesc);
	
	Return Result;
	
EndFunction

// Description of the constructor table.
// 
// Parameters:
//  TSName - String - table name
// 
// Returns:
//  Structure - Description of the resource table:
// * TSName - String - table name
// * StageTSName - String - List of stage tables
// * Picture - Number - Image Size
// * ThereArePackages - Boolean - are there packages in the table
// * Title - String - Title
// * SearchFields - String
// * SortFields - String
&AtClientAtServerNoContext
Function DescriptionOfConstructorTable(TSName = "")
	
	Result = New Structure;
	
	Result.Insert("TSName", TSName);
	Result.Insert("StageTSName", TSName);
	Result.Insert("Picture", 1);
	Result.Insert("ThereArePackages", True);
	Result.Insert("Title", "");
	Result.Insert("SearchFields", "");
	Result.Insert("Use", True);
	
	CommonClientServer.SupplementStructure(Result, MatchingElements(TSName));
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function MatchingElements(TSName)
	
	Result = New Structure;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		Result.Insert("PageItem",             "PageProvidingMaterialsAndWorks");
		Result.Insert("MarkElement",              "SupplyWithMaterialsAndWorksMark");
		Result.Insert("ActionElement",             "SupplyWithMaterialsAndWorksAction");
		Result.Insert("ElementQuantityProcessTechnology", "SupplyWithMaterialsAndWorksNumberOfPackagingUnitsProcessTechnology");
		Result.Insert("ElementNumberStage",       "SupplyWithMaterialsAndWorksNumberOfPackagingUnitsStage");
		Result.Insert("QuantityResultElement",  "SupplyWithMaterialsAndWorksNumberOfPackagingUnitsResult");
		Result.Insert("ArrowPictureElement",      "SupplyWithMaterialsAndWorksPictureArrow");
		
	ElsIf TSName = "LaborCosts" Then
		
		Result.Insert("PageItem",             "LaborCostsPage");
		Result.Insert("MarkElement",              "LaborCostsMark");
		Result.Insert("ActionElement",             "LaborCostsAction");
		Result.Insert("ElementQuantityProcessTechnology", "LaborCostsNumberOfTechnicalProcesses");
		Result.Insert("ElementNumberStage",       "LaborCostsCountStage");
		Result.Insert("QuantityResultElement",  "LaborCostsQuantityResult");
		Result.Insert("ArrowPictureElement",      "LaborCostsPictureArrow");
		
	ElsIf TSName = "ManufacturedProducts" Then
		
		Result.Insert("PageItem",             "OutputProductsPage");
		Result.Insert("MarkElement",              "ManufacturedProductsMark");
		Result.Insert("ActionElement",             "ManufacturedProductsAction");
		Result.Insert("ElementQuantityProcessTechnology", "ManufacturedProductsNumberOfPackagingUnitsProcessTechnology");
		Result.Insert("ElementNumberStage",       "ManufacturedProductsNumberOfPackagingUnitsStage");
		Result.Insert("QuantityResultElement",  "ManufacturedProductsNumberOfPackagingUnitsResult");
		Result.Insert("ArrowPictureElement",      "ManufacturedProductsPictureArrow");
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ParametersForCheckingFillingInAttributes(TSName)
	
	Result = New Structure;
	
	AttributesList = "Item,HideValue";
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		Result.Insert("Warehouse",                 New Structure(AttributesList, "SupplyWithMaterialsAndWorksWarehouse", True));
		Result.Insert("WithAssignment",           New Structure(AttributesList, "SupplyWithMaterialsAndWorksWithAssignment", False));
		Result.Insert("SupplyAssignment", New Structure(AttributesList, "SupplyWithMaterialsAndWorksSupplyAssignment", True));
		Result.Insert("ProductCostElement",     New Structure(AttributesList, "SupplyWithMaterialsAndWorksProductCostElement", True));
		
	ElsIf TSName = "ManufacturedProducts" Then
		
		Result.Insert("CostType",       New Structure(AttributesList, "ManufacturedProductsCostType", False));
		Result.Insert("Warehouse",              New Structure(AttributesList, "ManufacturedProductsWarehouse", True));
		Result.Insert("ProductCostElement",  New Structure(AttributesList, "ManufacturedProductsProductCostElement", True));
		
	ElsIf TSName = "LaborCosts" Then
		
		Result.Insert("ProductCostElement",  New Structure(AttributesList, "LaborCostsProductCostElement", True));
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ThereAreActionsToBePerformed(Form, TSName = Undefined)
	
	For Each KeyAndValue In DescriptionOfTables(Form) Do
		DescriptionOfTS = KeyAndValue.Value;
		If TSName = Undefined Or DescriptionOfTS.TSName = TSName Then
			For Each String In Form[DescriptionOfTS.TSName] Do
				If String.Mark Then
					Return True;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Function ClosingParameters(RecordTechnicalProcess = False, UpdateStage = False, CloseAtEnd = False)
	
	Result = New Structure;
	
	Result.Insert("RecordTechnicalProcess",   RecordTechnicalProcess);
	Result.Insert("CloseAtEnd", CloseAtEnd);
	
	If Not UpdateStage Then
		PutToTempStorage(Undefined, AddressOfStageDataToUpdate);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure FillInCalculationArticleInLines(TSName, StageTSName = "")
	
	If IsBlankString(StageTSName) Then
		StageTSName = TSName;
	EndIf;
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("ExpenseType", ProductionClient.TypesOfCostsForChoosingCalculationArticle(StageTSName));
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInCalculationArticleInLinesCompletion", ThisObject, TSName);
	
	OpenForm(
		"Catalog.ProductCostElements.ChoiceForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCalculationArticleInLinesCompletion(ClosingResult, TSName) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items[TSName].SelectedRows;
	
	For Each RowID In SelectedRows Do
		
		CurrentData = ThisObject[TSName].FindByID(RowID);
		
		If CurrentData.ReadOnly
			Or Not CurrentData.Action = ActionAdd()
			Or (TSName = "ManufacturedProducts" And CurrentData.CostType = PredefinedValue("Enum.CostTypesOfFinishedProducts.Calculating"))  Then
			Continue;
		EndIf;
		
		If CurrentData.ProductCostElement <> ClosingResult Then
			CurrentData.ProductCostElement = ClosingResult;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Constants

&AtClientAtServerNoContext
Function ActionAdd()
	Return ProductionProcessEditorClientServer.ActionAdd();
EndFunction

&AtClientAtServerNoContext
Function ActionDelete()
	Return ProductionProcessEditorClientServer.ActionDelete();
EndFunction

&AtClientAtServerNoContext
Function ZoomInAction()
	Return ProductionProcessEditorClientServer.ZoomInAction();
EndFunction

&AtClientAtServerNoContext
Function ReduceAction()
	Return ProductionProcessEditorClientServer.ReduceAction();
EndFunction

&AtClientAtServerNoContext
Function DoNotModifyComment()
	Return NStr("vi = 'Không thay đổi';
				|ru = 'Не изменять';
				|en = 'Do not change'; fa = 'تغییر نکند';
				|it = 'Non modificare';
				|pl = 'Nie zmieniaj';
				|tr = 'Değiştirme'");
EndFunction

#EndRegion

#EndRegion
