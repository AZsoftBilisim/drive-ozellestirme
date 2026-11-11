#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	OptionsForEditingInventoryTypes = New FixedStructure(Parameters.OptionsForEditingInventoryTypes);
	
	FillPropertyValues(ThisObject, OptionsForEditingInventoryTypes);
	
	CurrentDate = ?(OptionsForEditingInventoryTypes.Property("DocumentDate")
						And ValueIsFilled(OptionsForEditingInventoryTypes.DocumentDate),
					OptionsForEditingInventoryTypes.DocumentDate,
					CurrentSessionDate());
	
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(CurrentDate);
	DateOfTraceableImportedGoodsAccountingStart =
		AccountingForTraceableGoodsLocalization.DateOfTraceableImportedGoodsAccountingStart();
	
	FillInInventoryTypeTree();
	FormItemsManagement();
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
																			CurrentDate,
																			"ProductsGroupQuantityByRNPT");
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TreeItems = InventoryKindTree.GetItems();
	For Each TreeItem In TreeItems Do
		If TreeItem.GetParent() = Undefined Then
			Items.InventoryKindTree.Expand(TreeItem.GetID());
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		CurrentData = Items.InventoryKindTree.CurrentData;
		
		If CurrentData <> Undefined Then
			CurrentData.CCDNumber = NewObject;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInventoryKindTree

&AtClient
Procedure InventoryKindTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.CurrentData.Property(Field.Name) Then
		Value = Undefined;
		If Field.Name = "LineNumber" Then
			If ValueIsFilled(Item.CurrentData.Products) Then
				Value = Item.CurrentData.Products;
			Else
				Value = Item.CurrentData.ProductsInventoryKinds;
			EndIf;
			StandardProcessing = False;
		ElsIf Items.InventoryKindTree.ReadOnly Then
			Value = Item.CurrentData[Field.Name];
		EndIf;
		If ValueIsFilled(Value) Then
			ShowValue(Undefined, Value);
		EndIf;
	ElsIf Items.InventoryKindTree.ReadOnly Then
		If ValueIsFilled(Item.CurrentData.InventoryOwnerAttribute) Then
			ShowValue(Undefined, Item.CurrentData.InventoryOwnerAttribute);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryKindTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	ParentRow = Item.CurrentData.GetParent();
	If Not Copy
	 And ParentRow <> Undefined Then
	 
		Cancel = True;
		Item.CurrentRow = ParentRow.GetID();
		Item.AddRow();
		
	ElsIf Copy
	 And ParentRow = Undefined Then
	 
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryKindTreeBeforeDeleteRow(Item, Cancel)
	
	TableRow = Item.CurrentData;
	If TableRow.GetParent() = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Dòng gốc của cây không thể xóa';
										|ru = 'Корневую строку дерева удалять нельзя';
										|en = 'Cannot delete a root line of a tree'; fa = 'Cannot delete a root line of a tree';
										|it = 'La riga principale dell''albero non può essere cancellata';
										|pl = 'Nie można usunąć głównego wiersza drzewa';
										|tr = 'Ağacın kök satırı silinemez'"));
		Cancel = True;
	EndIf;
	
	If Not Cancel Then
		ParentRow = TableRow.GetParent();
		ParentRow.QuantityTypesOfInventory = 0;
		ParentRow.QuantityByRNPTInventoryTypes	= 0;
		ParentRow.ExciseTaxAmount = 0;
		ParentRow.ExciseTaxBase = 0;
		For Each String In ParentRow.GetItems() Do
			ParentRow.QuantityTypesOfInventory = ParentRow.QuantityTypesOfInventory + String.Count;
			ParentRow.QuantityByRNPTInventoryTypes	= ParentRow.QuantityByRNPTInventoryTypes
															+ String.QuantityByGBRN;
			ParentRow.ExciseTaxAmount = ParentRow.ExciseTaxAmount + String.ExciseTaxAmount;
			ParentRow.ExciseTaxBase = ParentRow.ExciseTaxBase + String.ExciseTaxBase;
		EndDo;
		ParentRow.QuantityTypesOfInventory = ParentRow.QuantityTypesOfInventory - TableRow.Count;
		ParentRow.QuantityByRNPTInventoryTypes	= ParentRow.QuantityByRNPTInventoryTypes
														- TableRow.QuantityByGBRN;
		ParentRow.ExciseTaxAmount = ParentRow.ExciseTaxAmount - TableRow.ExciseTaxAmount;
		ParentRow.ExciseTaxBase = ParentRow.ExciseTaxBase - TableRow.ExciseTaxBase;
		FillInInformationField(ParentRow);
	EndIf;

EndProcedure

&AtClient
Procedure InventoryKindTreeOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		
		TableRow = Item.CurrentData;
		ParentRow = TableRow.GetParent();
		
		TotalTypesOfInventory = 0;
		AmountOfNDSVidyOfStocks = 0;
		QuantityTypesOfInventory = 0;
		QuantityByRNPTInventoryTypes	= 0;
		TreeRows = ParentRow.GetItems();
		For Each String In TreeRows Do
			QuantityTypesOfInventory = QuantityTypesOfInventory + String.Count;
			QuantityByRNPTInventoryTypes	= QuantityByRNPTInventoryTypes + String.QuantityByGBRN;
			TotalTypesOfInventory = TotalTypesOfInventory + String.AmountIncludingVAT;
			AmountOfNDSVidyOfStocks = AmountOfNDSVidyOfStocks + String.VATAmount;
		EndDo;
		ParentRow.QuantityTypesOfInventory = ParentRow.Count;
		ParentRow.QuantityByRNPTInventoryTypes	= ParentRow.QuantityByGBRN;
		FillInInformationField(ParentRow);
		
		TableRow.ProductsInventoryKinds = ParentRow.Products;
		TableRow.CharacteristicInventoryKinds = ParentRow.Characteristic;
		TableRow.PurposeTypesOfStocks = ParentRow.Purpose;
		TableRow.BatchTypesOfStocks = ParentRow.Series;
		TableRow.VATRate = ParentRow.VATRate;
		TableRow.Count = ParentRow.Count - QuantityTypesOfInventory;
		TableRow.QuantityByGBRN			= ParentRow.QuantityByGBRN - QuantityByRNPTInventoryTypes;
		TableRow.AmountIncludingVAT = ParentRow.AmountIncludingVAT - TotalTypesOfInventory;
		TableRow.VATAmount = ParentRow.VATAmount - AmountOfNDSVidyOfStocks;
		
		TableRow.DocumentSalesOfGoodsAndServices = ParentRow.DocumentSalesOfGoodsAndServices;
		If ValueIsFilled(ParentRow.DocumentSalesOfGoodsAndServices) Then
			TableRow.OriginWarehouse = Warehouse;
		EndIf;
		
		TableRow.TheRecordsAreKeptByCCD = ParentRow.TheRecordsAreKeptByCCD;
		TableRow.ItemsType = ParentRow.ItemsType;
		TableRow.TracedGoods = ParentRow.TracedGoods;
		TableRow.ExcisableGoods = ParentRow.ExcisableGoods;
		TableRow.SubjectToExcise = ParentRow.SubjectToExcise;
		TableRow.ExciseUnit = ParentRow.ExciseUnit;
		TableRow.ExciseConversionRatio = ParentRow.ExciseConversionRatio;
		TableRow.ExcisableGoodsCategory = ParentRow.ExcisableGoodsCategory;
		TableRow.ExciseTaxRate = ParentRow.ExciseTaxRate;
		TableRow.LocalExciseTaxRate = ParentRow.LocalExciseTaxRate;
		TableRow.CurrencyOfExciseDuty = ParentRow.CurrencyOfExciseDuty;
		EstablishAvailabilityOfDescriptionOfExciseCategoryOfItem(ParentRow.ExcisableGoods);
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryKindTreeOnActivateRow(Item)
	TableRow = Items.InventoryKindTree.CurrentData;
	If DisplayExciseTaxAmount And TableRow <> Undefined Then
		EstablishAvailabilityOfDescriptionOfExciseCategoryOfItem(TableRow.ExcisableGoods)
	EndIf;
	Return; // So that the handler is not empty in the TM
	
EndProcedure

&AtClient
Procedure InventoryKindTreeCountOnChange(Item)
	
	TableRow = Items.InventoryKindTree.CurrentData;
	ParentRow = TableRow.GetParent();
	
	If ParentRow.Count <> 0 Then
		TableRow.AmountIncludingVAT = Round(TableRow.Count * ParentRow.AmountIncludingVAT / ParentRow.Count, 2, RoundMode.Round15as20);
	Else
		TableRow.AmountIncludingVAT = 0;
	EndIf;
	
	If ParentRow.AmountIncludingVAT <> 0 Then
		TableRow.VATAmount = Round(TableRow.AmountIncludingVAT * ParentRow.VATAmount / ParentRow.AmountIncludingVAT, 2, RoundMode.Round15as20);
	Else
		TableRow.VATAmount = 0;
	EndIf;
	If TableRow.SubjectToExcise Then
		TableRow.ExciseTaxBase = Round(TableRow.Count * TableRow.ExciseConversionRatio, 3,
			RoundMode.Round15as20);
		TableRow.ExciseTaxAmount =
			Round(TableRow.ExciseTaxBase * TableRow.LocalExciseTaxRate, 2, RoundMode.Round15as20);
	Else
		TableRow.ExciseTaxBase = 0;
		TableRow.ExciseTaxAmount = 0;
	EndIf;
	ParentRow.QuantityTypesOfInventory = 0;
	ParentRow.QuantityByRNPTInventoryTypes	= 0;
	ParentRow.ExciseTaxAmount = 0;
	ParentRow.ExciseTaxBase = 0;
	For Each String In ParentRow.GetItems() Do
		String.QuantityByGBRN = String.Count * String.RNPTCoefficient;
		ParentRow.QuantityTypesOfInventory = ParentRow.QuantityTypesOfInventory + String.Count;
		ParentRow.QuantityByRNPTInventoryTypes	= ParentRow.QuantityByRNPTInventoryTypes
														+ String.QuantityByGBRN;
		ParentRow.ExciseTaxAmount = ParentRow.ExciseTaxAmount + String.ExciseTaxAmount;
		ParentRow.ExciseTaxBase = ParentRow.ExciseTaxBase + String.ExciseTaxBase;
	EndDo;
	FillInInformationField(ParentRow);
	
EndProcedure

&AtClient
Procedure CCDNumberOnChange(Item)
	
	TableRow = Items.InventoryKindTree.CurrentData;
	If ValueIsFilled(TableRow.CCDNumber) Then
		TableRow.CheckCCDNumber = CheckTraceabilityDataOfCCDNumberOnServer(TableRow.CCDNumber);
	Else
		TableRow.CheckCCDNumber = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure CCDNumberCreating(Item, StandardProcessing)
	
	If Not UseTraceableImportedGoodsAccounting Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	CurrentData = Items.InventoryKindTree.CurrentData;
	
	CCDNumberType = ?(CurrentData.TracedGoods,
					PredefinedValue("Enum.CCDNumberTypes.ProductBatchIDNumber"),
					PredefinedValue("Enum.CCDNumberTypes.CCDNumber"));
	
	FillParameters = New Structure;
	FillParameters.Insert("Code",				Item.EditText);
	FillParameters.Insert("Products",	CurrentData.ProductsInventoryKinds);
	FillParameters.Insert("CCDNumberType",	CCDNumberType);
	
	FormParameters		= New Structure("FillingValues", FillParameters);
	ClosingNotification_	= New CallbackDescription("CCDNumberCreatingCompletion", ThisObject, CurrentData.CCDNumber);
	
	OpenForm("Catalog.CCDNumbers.Form.ItemForm",
				FormParameters,
				ThisObject,
				UUID,
				,
				,
				ClosingNotification_);
	
EndProcedure

&AtClient
Procedure InventoryKindTreeExciseTaxAmountOnChange(Item)
	TableRow = Items.InventoryKindTree.CurrentData;
	ParentRow = TableRow.GetParent();
	FillInDataOnExciseTaxesInGroup(ParentRow);
	Return;
	
EndProcedure

&AtClient
Procedure InventoryOwnerAttributeOnChange(Item)
	If DisplayInventoryOwnerAttributeOfRecipient Then
		Return;
	EndIf;
	
	OnChangingInventoryOwnerAttribute(Item);
	Return;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToggleEditingOfInventoryTypes(Command)
	
	ConfigureEditingInventoryTypes(Not InventoryOwnerAttributesAreSpecifiedManually);
	
EndProcedure

&AtClient
Procedure MoveToDocument(Command)
	
	PutStockTypesInStorage();
	Close(DialogReturnCode.OK);
	
	Result = CommonClientServer.CopyStructure(OptionsForEditingInventoryTypes);
	Result.InventoryOwnerAttributesAreSpecifiedManually = InventoryOwnerAttributesAreSpecifiedManually;
	
	NotifyChoice(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure ToSelectProductBatchIDKits(Command)
	
	Items.InventoryKindTreeToSelectProductBatchIDKits.Check = Not Items.InventoryKindTreeToSelectProductBatchIDKits.Check;
	ToSelectProductBatchIDKits = Items.InventoryKindTreeToSelectProductBatchIDKits.Check;
	
	If Items.InventoryKindTreeToSelectProductBatchIDKits.Check Then
		
		RowID = 0;
		CommonClientServer.GetTreeRowIDByFieldValue(
			"CheckCCDNumber",RowID, InventoryKindTree.GetItems(), 1, False);
			
		Items.InventoryKindTree.CurrentRow = RowID;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillStockTypes(Command)
	
	ClearMessages();
	
	FillInInventoryOwnerAttributesAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InventoryKindTree.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("BackColor", StyleColors.ReportGroup1BackColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InventoryKindTree.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.ProductsInventoryKinds");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.InventoryOwnerAttribute");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InventoryKindTreeCount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InventoryKindTreeInformation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("InventoryKindTree.QuantityTypesOfInventory");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Show", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InventoryKindTreeAmountIncludingVAT.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InventoryKindTreeInformation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.AmountIncludingVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("InventoryKindTree.AmountWithVATVidsOfStocks");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Show", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InventoryKindTreeVATAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InventoryKindTreeInformation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.VATAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("InventoryKindTree.AmountOfNDSVidyOfStocks");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Show", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CCDNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.CCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.ProductsInventoryKinds");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không sử dụng tờ khai hải quan>';
													|ru = '<ГТД не используются>';
													|en = '<CCD numbers are not used>'; fa = '<CCD numbers are not used>';
													|it = '<Le dichiarazioni doganali di carico non vengono usate>';
													|pl = '<ŁDC nie jest używana>';
													|tr = '<Kargo Gümrük Beyannamesi kullanılmıyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	For Each RootItem In Items.InventoryKindTree.ChildItems Do
		If TypeOf(RootItem) = Type("FormField") Then
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(RootItem.Name);
		ElsIf TypeOf(RootItem) = Type("FormGroup") Then
			For Each SubordinateItem In RootItem.ChildItems Do
				If TypeOf(SubordinateItem) = Type("FormField") Then
					ItemField = Item.Fields.Items.Add();
					ItemField.Field = New DataCompositionField(SubordinateItem.Name);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.CheckCCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToSelectProductBatchIDKits");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InventoryKindTreeExciseTaxAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.ExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không chịu thuế TTĐB>';
													|ru = '<Неподакцизный>';
													|en = '<Non-excisable>'; fa = '<غیرمشمول عوارض>';
													|it = '<Non-excisable>';
													|pl = '<Non-excisable>';
													|tr = '<Tüketim vergisine tabi olmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InventoryKindTreeExciseTaxAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.ExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryKindTree.SubjectToExcise");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không sản xuất>';
													|ru = '<Непроизведенный>';
													|en = '<Unproduced>'; fa = '<Unproduced>';
													|it = '<Unproduced>';
													|pl = '<Unproduced>';
													|tr = '<Üretilmeyen>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
EndProcedure

#Region FormItemsManagement

&AtServer
Procedure ConfigureEditingInventoryTypes(EditingIsEnabled, PopulateStockSpeciesTree = True)
	
	InventoryOwnerAttributesAreSpecifiedManually = EditingIsEnabled;
	Items.ToggleEditingOfInventoryTypes.Check = InventoryOwnerAttributesAreSpecifiedManually;
	Items.FillStockTypes.Enabled = EditingIsEnabled;
	Items.InventoryKindTree.ReadOnly = Not EditingIsEnabled;
	Items.InventoryKindGroupIsSpecifiedManually.Visible = EditingIsEnabled;
	
	If PopulateStockSpeciesTree Then
		FillInInventoryTypeTree();
	EndIf;
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	Items.ToggleEditingOfInventoryTypes.Visible = EditInventoryKinds;
	Items.InventoryKindTree.ReadOnly = Not EditInventoryKinds;
	Items.TreeGroup_2.Visible = EditInventoryKinds;
	Items.FormGroup.Visible = Not EditInventoryKinds;
	Items.MoveToDocument.Visible = EditInventoryKinds;
	Items.FillStockTypes.Visible = EditInventoryKinds;
	
	Items.PictureWarning.Visible = DocumentItemModified;
	Items.LabelDocumentModified.Visible = DocumentItemModified;
	
	Items.InventoryKindTreeDocumentSalesOfGoodsAndServices.Visible = OptionsForEditingInventoryTypes.DisplaySalesDocuments;
	
	Items.ExcisableGoodsDataGroup.Visible = DisplayExciseTaxAmount;
	
	If OptionsForEditingInventoryTypes.DisplaySalesDocuments Then
		Items.InventoryOwnerAttribute.ChoiceForm = "Catalog.InventoryKinds.Form.ChoiceForm";
	Else
		Items.InventoryOwnerAttribute.ChoiceForm = "Catalog.InventoryKinds.Form.ChoiceFormByBalance";
	EndIf;	
	
	Items.InventoryKindTreeAmountIncludingVAT.Title = 
		?(GetFunctionalOption("UseVATAccounting"), NStr("vi = 'Số tiền gồm thuế GTGT';
														|ru = 'Сумма с НДС';
														|en = 'Amount including VAT'; fa = 'مبلغ با احتساب مالیات بر ارزش افزوده';
														|it = 'Importo IVA inclusa';
														|pl = 'Wartość z VAT';
														|tr = 'KDV dahil tutar'"), NStr("vi = 'Tổng số';
																							|ru = 'Сумма';
																							|en = 'Amount'; fa = 'مبلغ';
																							|it = 'Сумма';
																							|pl = 'Wartość';
																							|tr = 'Tutar'"));
	
	Items.InventoryKindGroupIsSpecifiedManually.Visible = InventoryOwnerAttributesAreSpecifiedManually;
	
	If EditInventoryKinds Then
		ConfigureEditingInventoryTypes(InventoryOwnerAttributesAreSpecifiedManually, False);
	EndIf;
	
	Items.InventoryKindTreeToSelectProductBatchIDKits.Visible = False;
	
	Items.InventoryKindTreeExciseTaxAmount.Visible = DisplayExciseTaxAmount;
	
	Items.InventoryOwnerAttribute.Title = ?(DisplayInventoryOwnerAttributeOfRecipient,
										NStr("vi = 'Dạng vật tư của nơi gửi';
											|ru = 'Вид запасов отправителя';
											|en = 'Sender inventory owner attributes'; fa = 'Sender inventory owner attributes';
											|it = 'Sender inventory owner attributes';
											|pl = 'Sender inventory owner attributes';
											|tr = 'Gönderi stok sahibinin öznitelikleri'"),
										NStr("vi = 'Dạng hàng tồn kho';
											|ru = 'Вид запасов';
											|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
											|it = 'Tipologia di scorte';
											|pl = 'Rodzaj pozycji';
											|tr = 'Stok sahibinin öznitelikleri'"));
	Items.RecipientInventoryOwnerAttribute.Visible = DisplayInventoryOwnerAttributeOfRecipient;
	Items.InventoryKindTreeRecipientInventoryOwnerAttributeOrganization.Visible = DisplayInventoryOwnerAttributeOfRecipient;
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "CCDNumber");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	If ValueIsFilled(LocalAccountingCurrency) Then
		NameOfLocalAccountingCurrency =
			Common.ObjectAttributeValue(LocalAccountingCurrency, "Description");
		TitleText = StrTemplate(NStr("vi = 'Số tiền thuế TTĐB (%1)';
									|ru = 'Сумма акциза (%1)';
									|en = 'Excise amount (%1)'; fa = 'Excise amount (%1)';
									|it = 'Excise amount (%1)';
									|pl = 'Excise amount (%1)';
									|tr = 'Tüketim vergisi tutarı (%1)'"), NameOfLocalAccountingCurrency);
	Else
		TitleText = NStr("vi = 'Số tiền thuế tiêu thụ đặc biệt';
						|ru = 'Сумма акциза';
						|en = 'Excise amount'; fa = 'مبلغ عوارض';
						|it = 'Importo accisa';
						|pl = 'Wartość akcyzy';
						|tr = 'Tüketim tutarı'");
	EndIf;
	Items.InventoryKindTreeExciseTaxAmount.Title = TitleText;
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure PutStockTypesInStorage() 
	
	TableTypesOfStocks_ = GetFromTempStorage(AddressOfInventoryKindsInStorage).CopyColumns();
	
	ThereIsQuantityOfRNPT = (TableTypesOfStocks_.Columns.Find("QuantityByGBRN") <> Undefined);
	ThereIsSumWithVAT = (TableTypesOfStocks_.Columns.Find("AmountIncludingVAT") <> Undefined);
	ThereIsVATAmount = (TableTypesOfStocks_.Columns.Find("VATAmount") <> Undefined);
	ThereIsVATRate = (TableTypesOfStocks_.Columns.Find("VATRate") <> Undefined);
	ThereIsShippingWarehouse = (TableTypesOfStocks_.Columns.Find("OriginWarehouse") <> Undefined);
	ThereIsImplementationDocument = (TableTypesOfStocks_.Columns.Find("DocumentSalesOfGoodsAndServices") <> Undefined);
	ThereIsWayToDetermineCost = (TableTypesOfStocks_.Columns.Find("CostDefiningMethod") <> Undefined);
	ThereIsExciseTaxAmount = (TableTypesOfStocks_.Columns.Find("ExciseTaxAmount") <> Undefined);
	ThereIsInventoryOwnerAttributeOfRecipient = (TableTypesOfStocks_.Columns.Find("RecipientInventoryOwnerAttribute") <> Undefined);
	
	Tree = FormAttributeToValue("InventoryKindTree");
	For Each ProductsRow In Tree.Rows Do
		
		For Each String In ProductsRow.Rows Do
		
			NewRow = TableTypesOfStocks_.Add();
			NewRow.ItemsLocationAttributes = ProductsRow.ItemsLocationAttributes;
			NewRow.InventoryOwnerAttribute = String.InventoryOwnerAttribute;
			NewRow.CCDNumber = String.CCDNumber;
			NewRow.Count = String.Count;
			If ThereIsQuantityOfRNPT Then
				NewRow.QuantityByGBRN = String.QuantityByGBRN;
			EndIf;
			If ThereIsSumWithVAT Then
				NewRow.AmountIncludingVAT = String.AmountIncludingVAT;
			EndIf;
			If ThereIsVATAmount Then
				NewRow.VATAmount = String.VATAmount;
			EndIf;
			If ThereIsVATRate Then
				NewRow.VATRate = String.VATRate;
			EndIf;
			If ThereIsShippingWarehouse Then
				NewRow.OriginWarehouse = String.OriginWarehouse;
			EndIf;
			If ThereIsImplementationDocument Then
				NewRow.DocumentSalesOfGoodsAndServices = String.DocumentSalesOfGoodsAndServices;
			EndIf;
			If ThereIsWayToDetermineCost Then
				NewRow.CostDefiningMethod = String.CostDefiningMethod;
			EndIf;
			If ThereIsExciseTaxAmount Then
				NewRow.ExciseTaxAmount = String.ExciseTaxAmount;
			EndIf;
			If ThereIsInventoryOwnerAttributeOfRecipient Then
				NewRow.RecipientInventoryOwnerAttribute = String.RecipientInventoryOwnerAttribute;
			EndIf;
			
		EndDo;
		
	EndDo;

	PutToTempStorage(TableTypesOfStocks_, AddressOfInventoryKindsInStorage);
	
EndProcedure

&AtServer
Procedure FillInInventoryTypeTree(TableTypesOfStocks_ = Undefined)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = 
	"SELECT
	|	SourceDocumentTable.LineNumber AS LineNumber,
	|	SourceDocumentTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	SourceDocumentTable.Warehouse AS Warehouse,
	|	SourceDocumentTable.Department AS Department,
	|	SourceDocumentTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	SourceDocumentTable.CostDefiningMethod AS CostDefiningMethod,
	|	SourceDocumentTable.Products AS Products,
	|	SourceDocumentTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN SourceDocumentTable.BatchesIndicationStatus IN (14, 18)
	|			THEN SourceDocumentTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	SourceDocumentTable.Purpose AS Purpose,
	|	SourceDocumentTable.Count AS Count,
	|	SourceDocumentTable.QuantityByGBRN AS QuantityByGBRN,
	|	(CASE
	|		WHEN SourceDocumentTable.Count < 0 THEN -1
	|		ELSE 1 END) AS Character,
	|	CASE WHEN SourceDocumentTable.SalesAmount <> 0 THEN
	|		SourceDocumentTable.SalesAmount
	|	ELSE
	|		SourceDocumentTable.Sum
	|	END AS Sum,
	|	CASE WHEN SourceDocumentTable.SalesAmount <> 0 THEN
	|		0
	|	ELSE
	|		SourceDocumentTable.VATAmount
	|	END AS VATAmount,
	|	SourceDocumentTable.VATRate AS VATRate
	|	
	|INTO SourceDocumentTable
	|FROM
	|	&SourceDocumentTable AS SourceDocumentTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(SourceDocumentTable.LineNumber) AS LineNumber,
	|	ISNULL(Dimension.DimensionKey, SourceDocumentTable.ItemsLocationAttributes) AS ItemsLocationAttributes,
	|	SourceDocumentTable.Warehouse AS StorageLocation,
	|	CASE
	|		WHEN &DisplaySalesDocuments
	|		THEN SourceDocumentTable.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED
	|	END DocumentSalesOfGoodsAndServices,
	|	SourceDocumentTable.CostDefiningMethod AS CostDefiningMethod,
	|	SourceDocumentTable.Products AS Products,
	|	CatalogProducts.KeepRecordsByCCD AS KeepRecordsByCCD,
	|	SourceDocumentTable.Characteristic AS Characteristic,
	|	SourceDocumentTable.Series AS Series,
	|	SourceDocumentTable.Character AS Character,
	|	&Country AS Country,
	|	SUM(SourceDocumentTable.Count) AS Count,
	|	SUM(SourceDocumentTable.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(
	|		SourceDocumentTable.Sum
	|		+ &PriceDoesNotIncludeVAT * SourceDocumentTable.VATAmount
	|	) AS AmountIncludingVAT,
	|	MAX(SourceDocumentTable.VATRate) AS VATRate,
	|	SUM(SourceDocumentTable.VATAmount) AS VATAmount
	|	
	|INTO DocumentTable
	|FROM
	|	SourceDocumentTable AS SourceDocumentTable
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatalogProducts
	|	ON
	|		SourceDocumentTable.Products = CatalogProducts.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		SourceDocumentTable.Products = Dimension.Products
	|		AND SourceDocumentTable.Characteristic = Dimension.Characteristic
	|		AND SourceDocumentTable.Series = Dimension.Series
	|		AND SourceDocumentTable.Warehouse = Dimension.StorageLocation
	|		AND SourceDocumentTable.Purpose = Dimension.Purpose
	|		AND SourceDocumentTable.ItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	CatalogProducts.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage)
	|	)
	|
	|GROUP BY
	|	ISNULL(Dimension.DimensionKey, SourceDocumentTable.ItemsLocationAttributes),
	|	SourceDocumentTable.Warehouse,
	|	SourceDocumentTable.DocumentSalesOfGoodsAndServices,
	|	SourceDocumentTable.CostDefiningMethod,
	|	SourceDocumentTable.Products,
	|	SourceDocumentTable.Characteristic,
	|	SourceDocumentTable.Series,
	|	SourceDocumentTable.Character,
	|	CatalogProducts.KeepRecordsByCCD
	|
	// Traceable Works
	|UNION ALL
	|
	|SELECT
	|	MIN(SourceDocumentTable.LineNumber),
	|	ISNULL(Dimension.DimensionKey, SourceDocumentTable.ItemsLocationAttributes),
	|	CASE
	|		WHEN &DivisionInHeader
	|			THEN &Department
	|		ELSE SourceDocumentTable.Department
	|	END AS StorageLocation,
	|	CASE
	|		WHEN &DisplaySalesDocuments
	|		THEN SourceDocumentTable.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED
	|	END,
	|	SourceDocumentTable.CostDefiningMethod,
	|	SourceDocumentTable.Products,
	|	CatalogProducts.KeepRecordsByCCD,
	|	SourceDocumentTable.Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef),
	|	SourceDocumentTable.Character,
	|	&Country AS Country,
	|	SUM(SourceDocumentTable.Count),
	|	SUM(SourceDocumentTable.QuantityByGBRN),
	|	SUM(
	|		SourceDocumentTable.Sum
	|		+ &PriceDoesNotIncludeVAT * SourceDocumentTable.VATAmount
	|	),
	|	MAX(SourceDocumentTable.VATRate),
	|	SUM(SourceDocumentTable.VATAmount)
	|FROM
	|	SourceDocumentTable AS SourceDocumentTable
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatalogProducts
	|	ON
	|		SourceDocumentTable.Products = CatalogProducts.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		SourceDocumentTable.Products = Dimension.Products
	|		AND SourceDocumentTable.Characteristic = Dimension.Characteristic
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = Dimension.Series
	|		AND SourceDocumentTable.Department = Dimension.StorageLocation
	|		AND SourceDocumentTable.Purpose = Dimension.Purpose
	|		AND SourceDocumentTable.ItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|
	|GROUP BY
	|	ISNULL(Dimension.DimensionKey, SourceDocumentTable.ItemsLocationAttributes),
	|	CASE
	|		WHEN &DivisionInHeader
	|			THEN &Department
	|		ELSE SourceDocumentTable.Department
	|	END,
	|	SourceDocumentTable.DocumentSalesOfGoodsAndServices,
	|	SourceDocumentTable.CostDefiningMethod,
	|	SourceDocumentTable.Products,
	|	SourceDocumentTable.Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef),
	|	SourceDocumentTable.Character,
	|	CatalogProducts.KeepRecordsByCCD
	|
	|INDEX BY
	|	Products,
	|	Country
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SourceTableStockTypes.ItemsLocationAttributes,
	|	SourceTableStockTypes.InventoryOwnerAttribute,
	|	SourceTableStockTypes.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	SourceTableStockTypes.CCDNumber,
	|	SourceTableStockTypes.VATRate,
	|	SourceTableStockTypes.Count,
	|	SourceTableStockTypes.QuantityByGBRN,
	|	SourceTableStockTypes.AmountIncludingVAT,
	|	SourceTableStockTypes.VATAmount,
	|	SourceTableStockTypes.ExciseTaxAmount,
	|	(CASE
	|		WHEN SourceTableStockTypes.Count < 0 THEN -1
	|		ELSE 1 END) AS Character,
	|	CASE 
	|		WHEN &DisplaySalesDocuments
	|		THEN SourceTableStockTypes.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED
	|	END DocumentSalesOfGoodsAndServices,
	|	SourceTableStockTypes.CostDefiningMethod,
	|	SourceTableStockTypes.OriginWarehouse
	|
	|INTO TTTableTypesOfStocks
	|FROM
	|	&SourceTableStockTypes AS SourceTableStockTypes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.ItemsLocationAttributes,
	|	Keys.Purpose AS Purpose,
	|	Keys.StorageLocation AS StorageLocation,
	|	Keys.Products,
	|	Keys.Characteristic,
	|	Keys.Series,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.VATRate,
	|	InventoryKinds.Character,
	|	SUM(InventoryKinds.Count),
	|	SUM(InventoryKinds.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(InventoryKinds.AmountIncludingVAT),
	|	SUM(InventoryKinds.VATAmount),
	|	SUM(InventoryKinds.ExciseTaxAmount) AS ExciseTaxAmount,
	|	InventoryKinds.DocumentSalesOfGoodsAndServices,
	|	InventoryKinds.CostDefiningMethod,
	|	InventoryKinds.OriginWarehouse
	|
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTableTypesOfStocks AS InventoryKinds
	|
	|	INNER JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Keys
	|	ON
	|		InventoryKinds.ItemsLocationAttributes = Keys.Ref
	|
	|GROUP BY
	|	InventoryKinds.ItemsLocationAttributes,
	|	Keys.Purpose,
	|	Keys.StorageLocation,
	|	Keys.Products,
	|	Keys.Characteristic,
	|	Keys.Series,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.RecipientInventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.VATRate,
	|	InventoryKinds.CostDefiningMethod,
	|	InventoryKinds.DocumentSalesOfGoodsAndServices,
	|	InventoryKinds.OriginWarehouse,
	|	InventoryKinds.Character
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExcisableGoodsCategories.Products AS Products,
	|	ExcisableGoodsCategories.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	ExcisableGoodsCategories.ConversionFactor_ AS ConversionFactor_,
	|	ExcisableGoodsCategories.ExcisableGoods AS ExcisableGoods
	|INTO TableOfExcisableItems
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&DocumentDate, (Products, Country) IN
	|		(SELECT
	|			DocumentTable.Products AS Products,
	|			DocumentTable.Country AS Country
	|		FROM
	|			DocumentTable AS DocumentTable)) AS ExcisableGoodsCategories
	|
	|WHERE
	|	ExcisableGoodsCategories.ExcisableGoods
	|
	|INDEX BY
	|	ExcisableGoodsCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Excisable_Items.Products AS Products,
	|	Excisable_Items.ConversionFactor_ AS ConversionFactor_,
	|	Excisable_Items.ExcisableGoods AS ExcisableGoods,
	|	ExcisableGoodsCategories.Currency AS CurrencyOfExciseDuty,
	|	ExcisableGoodsCategories.UnitOfMeasure AS ExciseUnit,
	|	ExcisableGoodsCategories.Ref AS ExcisableGoodsCategory
	|INTO ExciseDutyTable
	|FROM
	|	Catalog.ExcisableGoodsCategories AS ExcisableGoodsCategories
	|	INNER JOIN TableOfExcisableItems AS Excisable_Items
	|	ON ExcisableGoodsCategories.Ref = Excisable_Items.ExcisableGoodsCategory
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RatesOfExcisableGoodsCategoriesSliceLast.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	RatesOfExcisableGoodsCategoriesSliceLast.Rate1 AS ExciseTaxRate
	|INTO TableOfExciseRates
	|FROM
	|	InformationRegister.RatesOfExcisableGoodsCategories.SliceLast(&DocumentDate, ExcisableGoodsCategory IN
	|		(SELECT
	|			TableOfExcisableItems.ExcisableGoodsCategory AS ExcisableGoodsCategory
	|		FROM
	|			TableOfExcisableItems AS TableOfExcisableItems)) AS RatesOfExcisableGoodsCategoriesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS ConversionFactor_
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&DocumentDate, Currency IN
	|		(SELECT
	|			ExciseDutyTable.CurrencyOfExciseDuty AS CurrencyOfExciseDuty
	|		FROM
	|			ExciseDutyTable)
	|	AND BaseCurrency = &BaseCurrency) AS CurrencyExchangeRate
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DocumentTable.ItemsLocationAttributes.Purpose AS Purpose,
	|	CASE WHEN DocumentTable.StorageLocation = VALUE(Catalog.Warehouses.EmptyRef) THEN
	|		&Warehouse
	|	ELSE
	|		DocumentTable.StorageLocation
	|	END AS StorageLocation,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.KeepRecordsByCCD AS TheRecordsAreKeptByCCD,
	|	CatalogProducts.ItemsType AS ItemsType,
	|	CatalogProducts.TracedGoods AS TracedGoods,
	|	DocumentTable.Characteristic AS Characteristic,
	|	DocumentTable.Series AS Series,
	|	DocumentTable.Count AS Count,
	|	DocumentTable.QuantityByGBRN AS QuantityByGBRN,
	|	DocumentTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.VATRate AS VATRate,
	|
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	ISNULL(TableTypesOfStocks_.Count, 0) AS QuantityTypesOfInventory,
	|	ISNULL(TableTypesOfStocks_.QuantityByGBRN, 0) AS QuantityByRNPTInventoryTypes,
	|	CASE
	|		WHEN ISNULL(TableTypesOfStocks_.Count, 0) = 0
	|			THEN 0
	|		ELSE ISNULL(TableTypesOfStocks_.QuantityByGBRN, 0) / TableTypesOfStocks_.Count
	|	END AS RNPTCoefficient,
	|	ISNULL(TableTypesOfStocks_.AmountIncludingVAT, 0) AS AmountWithVATVidsOfStocks,
	|	ISNULL(TableTypesOfStocks_.VATAmount, 0) AS AmountOfNDSVidyOfStocks,
	|	ISNULL(TableTypesOfStocks_.VATRate, UNDEFINED) AS VATRateTypesOfInventory,
	|	ISNULL(ExciseDutyTable.ExcisableGoods, FALSE) AS ExcisableGoods,
	|	CASE WHEN &ExciseTaxIsLeviedOnInventoryOwnerAttributeOfRecipient THEN
	|		ISNULL(TypesOfStocksOfRecipient.SubjectToExcise, FALSE)
	|	ELSE
	|		ISNULL(InventoryKinds.SubjectToExcise, FALSE)
	|	END AS SubjectToExcise,
	|	CASE WHEN ISNULL(InventoryKinds.SubjectToExcise, FALSE)
	|		OR &ExciseTaxIsLeviedOnInventoryOwnerAttributeOfRecipient AND ISNULL(TypesOfStocksOfRecipient.SubjectToExcise, FALSE) THEN
	|		ISNULL(TableTypesOfStocks_.ExciseTaxAmount, 0)
	|	ELSE
	|		0
	|	END AS ExciseTaxAmount,
	|	CASE WHEN ISNULL(InventoryKinds.SubjectToExcise, FALSE)
	|		OR &ExciseTaxIsLeviedOnInventoryOwnerAttributeOfRecipient AND ISNULL(TypesOfStocksOfRecipient.SubjectToExcise, FALSE) THEN
	|		ISNULL(TableTypesOfStocks_.Count, 0) * ISNULL(ExciseDutyTable.ConversionFactor_, 0)
	|	ELSE
	|		0
	|	END AS ExciseTaxBase,
	|	ExciseDutyTable.ExciseUnit AS ExciseUnit,
	|	ISNULL(ExciseDutyTable.ConversionFactor_, 0) AS ExciseConversionRatio,
	|	ExciseDutyTable.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	ISNULL(TableOfExciseRates.ExciseTaxRate, 0) AS ExciseTaxRate,
	|	ISNULL(TableOfExciseRates.ExciseTaxRate, 0)
	|		* ISNULL(ExchangeRates.ConversionFactor_, 0) AS LocalExciseTaxRate,
	|	ExciseDutyTable.CurrencyOfExciseDuty AS CurrencyOfExciseDuty,
	|
	|	CASE WHEN InventoryKinds.SaleOfAnotherCompanyInventory THEN
	|		InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType
	|	ELSE
	|		InventoryKinds.InventoryType
	|	END AS InventoryType,
	|
	|	CASE WHEN InventoryKinds.SaleOfAnotherCompanyInventory THEN
	|		InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|	ELSE
	|		InventoryKinds.Organization
	|	END AS Organization,
	|
	|	CASE WHEN InventoryKinds.SaleOfAnotherCompanyInventory THEN
	|		InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.GoodsOwner
	|	ELSE
	|		InventoryKinds.GoodsOwner
	|	END AS GoodsOwner,
	|
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.CostDefiningMethod AS CostDefiningMethod,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse
	|FROM
	|	DocumentTable AS DocumentTable
	|		LEFT JOIN TableTypesOfStocks_ AS TableTypesOfStocks_
	|		ON DocumentTable.ItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|			AND DocumentTable.CostDefiningMethod = TableTypesOfStocks_.CostDefiningMethod
	|			AND DocumentTable.Character = TableTypesOfStocks_.Character
	|			AND (DocumentTable.StorageLocation = VALUE(Catalog.Warehouses.EmptyRef)
	|				OR DocumentTable.StorageLocation = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				OR DocumentTable.StorageLocation = TableTypesOfStocks_.StorageLocation)
	|			AND (DocumentTable.DocumentSalesOfGoodsAndServices = TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|				OR (&DisplaySalesDocuments
	|					AND (DocumentTable.DocumentSalesOfGoodsAndServices = UNDEFINED
	|						OR DocumentTable.DocumentSalesOfGoodsAndServices = VALUE(Document.CustomerInvoice.EmptyRef)
	|						OR DocumentTable.DocumentSalesOfGoodsAndServices = VALUE(Document.RetailSalesReport.EmptyRef))))
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON DocumentTable.Products = CatalogProducts.Ref
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksOfRecipient
	|			ON TableTypesOfStocks_.RecipientInventoryOwnerAttribute = TypesOfStocksOfRecipient.Ref
	|		
	|		LEFT JOIN ExciseDutyTable AS ExciseDutyTable
	|			ON ExciseDutyTable.Products = DocumentTable.Products
	|		
	|		LEFT JOIN TableOfExciseRates AS TableOfExciseRates
	|			ON ExciseDutyTable.ExcisableGoodsCategory = TableOfExciseRates.ExcisableGoodsCategory
	|		
	|		LEFT JOIN ExchangeRates AS ExchangeRates
	|			ON ExciseDutyTable.CurrencyOfExciseDuty = ExchangeRates.Currency
	|
	|UNION ALL
	|
	|SELECT
	|	0 AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Purpose AS Purpose,
	|	TableTypesOfStocks_.StorageLocation AS StorageLocation,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Products.KeepRecordsByCCD AS TheRecordsAreKeptByCCD,
	|	CatalogProducts.ItemsType AS ItemsType,
	|	CatalogProducts.TracedGoods AS TracedGoods,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Series AS Series,
	|	0 AS Count,
	|	0 AS QuantityByGBRN,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS QuantityTypesOfInventory,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByRNPTInventoryTypes,
	|	CASE
	|		WHEN TableTypesOfStocks_.Count = 0
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN / TableTypesOfStocks_.Count
	|	END AS RNPTCoefficient,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountWithVATVidsOfStocks,
	|	TableTypesOfStocks_.VATAmount AS AmountOfNDSVidyOfStocks,
	|	TableTypesOfStocks_.VATRate AS VATRateTypesOfInventory,
	|	FALSE AS ExcisableGoods,
	|	FALSE AS SubjectToExcise,
	|	0 AS ExciseTaxAmount,
	|	0 AS ExciseTaxBase,
	|	UNDEFINED AS ExciseUnit,
	|	0 AS ExciseConversionRatio,
	|	UNDEFINED AS CategoryOfExcisableItems,
	|	0 AS ExciseTaxRate,
	|	0 AS LocalExciseTaxRate,
	|	UNDEFINED AS CurrencyOfExciseDuty,
	|
	|	CASE WHEN InventoryKinds.SaleOfAnotherCompanyInventory THEN
	|		InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType
	|	ELSE
	|		InventoryKinds.InventoryType
	|	END AS InventoryType,
	|
	|	CASE WHEN InventoryKinds.SaleOfAnotherCompanyInventory THEN
	|		InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|	ELSE
	|		InventoryKinds.Organization
	|	END AS Organization,
	|
	|	CASE WHEN InventoryKinds.SaleOfAnotherCompanyInventory THEN
	|		InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.GoodsOwner
	|	ELSE
	|		InventoryKinds.GoodsOwner
	|	END AS GoodsOwner,
	|
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.CostDefiningMethod AS CostDefiningMethod,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse
	|
	|FROM
	|	TableTypesOfStocks_ AS TableTypesOfStocks_
	|		LEFT JOIN DocumentTable AS DocumentTable
	|		ON DocumentTable.ItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|			AND DocumentTable.Character = TableTypesOfStocks_.Character
	|			AND (DocumentTable.StorageLocation = VALUE(Catalog.Warehouses.EmptyRef)
	|				OR DocumentTable.StorageLocation = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				OR DocumentTable.StorageLocation = TableTypesOfStocks_.StorageLocation)
	|			AND (DocumentTable.DocumentSalesOfGoodsAndServices = TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|				OR (&DisplaySalesDocuments
	|					AND (DocumentTable.DocumentSalesOfGoodsAndServices = UNDEFINED
	|						OR DocumentTable.DocumentSalesOfGoodsAndServices = VALUE(Document.CustomerInvoice.EmptyRef)
	|						OR DocumentTable.DocumentSalesOfGoodsAndServices = VALUE(Document.RetailSalesReport.EmptyRef))))
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON DocumentTable.Products = CatalogProducts.Ref
	|WHERE
	|	DocumentTable.Products IS NULL
	|
	|ORDER BY
	|	LineNumber,
	|	InventoryOwnerAttribute,
	|	CCDNumber
	|
	|TOTALS
	|	SUM(Count),
	|	SUM(QuantityByGBRN),
	|	SUM(AmountIncludingVAT),
	|	SUM(VATAmount),
	|	MAX(VATRate),
	|	SUM(QuantityTypesOfInventory),
	|	SUM(QuantityByRNPTInventoryTypes),
	|	MAX(ExcisableGoods),
	|	MAX(SubjectToExcise),
	|	SUM(ExciseTaxAmount),
	|	SUM(ExciseTaxBase),
	|	MAX(ExcisableGoodsCategory),
	|	MAX(ExciseTaxRate),
	|	MAX(ExciseUnit),
	|	MAX(ExciseConversionRatio),
	|	MAX(LocalExciseTaxRate),
	|	MAX(CurrencyOfExciseDuty),
	|	SUM(AmountWithVATVidsOfStocks),
	|	SUM(AmountOfNDSVidyOfStocks),
	|	MAX(VATRateTypesOfInventory)
	|BY
	|	LineNumber";
	
	Query.SetParameter("PriceDoesNotIncludeVAT",				?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("DisplaySalesDocuments",	DisplaySalesDocuments);
	Query.SetParameter("Warehouse",							Warehouse);
	Query.SetParameter("DivisionInHeader",			OptionsForEditingInventoryTypes.DivisionInHeader);
	Query.SetParameter("Department",					OptionsForEditingInventoryTypes.Department);
	Query.SetParameter("DocumentDate",					OptionsForEditingInventoryTypes.DocumentDate);
	Query.SetParameter("UseTraceableImportedGoodsAccounting",
								UseTraceableImportedGoodsAccounting);
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	Query.SetParameter("Country",							RegistrationCountry);
	Query.SetParameter("BaseCurrency",					BaseCurrency);
	ExciseTaxIsLeviedOnInventoryOwnerAttributeOfRecipient = False;
	If TypeOf(Recorder) = Type("DocumentRef.IntercompanyGoodsReturn") Then
		ExciseTaxIsLeviedOnInventoryOwnerAttributeOfRecipient = True;
	EndIf;
	Query.SetParameter("ExciseTaxIsLeviedOnInventoryOwnerAttributeOfRecipient", ExciseTaxIsLeviedOnInventoryOwnerAttributeOfRecipient);
	// Generating Items table data.
	TableOfGoods = GetFromTempStorage(GoodsAddressInStorage); // ValueTable
	
	ColumnLineNumber = TableOfGoods.Columns.Find("LineNumber");
	If ColumnLineNumber <> Undefined Then
		ColumnLineNumber.Name = "LineNumber";
	EndIf;
	
	ThereIsQuantityOfRNPTVTCHGoods = (TableOfGoods.Columns.Find("QuantityByGBRN") <> Undefined);
	If Not ThereIsQuantityOfRNPTVTCHGoods Then
		TableOfGoods.Columns.Add("QuantityByGBRN", New TypeDescription("Number"));
	EndIf;
	
	ThereIsSum = (TableOfGoods.Columns.Find("Sum") <> Undefined);
	If Not ThereIsSum Then
		TableOfGoods.Columns.Add("Sum", New TypeDescription("Number"));
	EndIf;
	
	ThereIsVATAmount = (TableOfGoods.Columns.Find("VATAmount") <> Undefined);
	If Not ThereIsVATAmount Then
		TableOfGoods.Columns.Add("VATAmount", New TypeDescription("Number"));
		TableOfGoods.Columns.Add("VATRate", New TypeDescription("CatalogRef.VATRates"));
	EndIf;
	
	ThereIsSaleAmount = (TableOfGoods.Columns.Find("SalesAmount") <> Undefined);
	If Not ThereIsSaleAmount Then
		TableOfGoods.Columns.Add("SalesAmount", New TypeDescription("Number"));
	EndIf;
	
	ThereIs_Warehouse = (TableOfGoods.Columns.Find("Warehouse") <> Undefined);
	If Not ThereIs_Warehouse Then
		TableOfGoods.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	EndIf;
	
	ThereIsDivision = (TableOfGoods.Columns.Find("Department") <> Undefined);
	If Not ThereIsDivision Then
		TableOfGoods.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	EndIf;
	
	ThereIsImplementationDocument = (TableOfGoods.Columns.Find("DocumentSalesOfGoodsAndServices") <> Undefined);
	If Not ThereIsImplementationDocument Then
		TableOfGoods.Columns.Add("DocumentSalesOfGoodsAndServices", Documents.AllRefsType());
	EndIf;
	
	ThereIsSeries = (TableOfGoods.Columns.Find("Series") <> Undefined);
	If Not ThereIsSeries Then
		TableOfGoods.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	EndIf;

	ThereIsStatusOfIndicatingSeries = (TableOfGoods.Columns.Find("BatchesIndicationStatus") <> Undefined);
	If Not ThereIsStatusOfIndicatingSeries Then
		TableOfGoods.Columns.Add("BatchesIndicationStatus", New TypeDescription("Number"));
	EndIf;
	
	ThereIsAppointment = (TableOfGoods.Columns.Find("Purpose") <> Undefined);
	If Not ThereIsAppointment Then
		TableOfGoods.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	EndIf;
	
	ThereIsWayToDetermineCost = (TableOfGoods.Columns.Find("CostDefiningMethod") <> Undefined);
	If Not ThereIsWayToDetermineCost Then
		TableOfGoods.Columns.Add("CostDefiningMethod", New TypeDescription("EnumRef.WaysToCalculateReturnCost"));
	EndIf;
	
	Query.SetParameter("SourceDocumentTable", TableOfGoods);
	
	// Generating data from the Types of reserves table.
	If TableTypesOfStocks_ = Undefined Then
		TableTypesOfStocks_ = GetFromTempStorage(AddressOfInventoryKindsInStorage); // Assignment Tables - 
	EndIf;
	
	ThereIsQuantityOfRNPT = (TableTypesOfStocks_.Columns.Find("QuantityByGBRN") <> Undefined);
	If Not ThereIsQuantityOfRNPT Then
		TableTypesOfStocks_.Columns.Add("QuantityByGBRN", New TypeDescription("Number"));
	EndIf;
	
	ThereIsVATAmount = (TableTypesOfStocks_.Columns.Find("VATAmount") <> Undefined);
	If Not ThereIsVATAmount Then
		TableTypesOfStocks_.Columns.Add("VATAmount",  New TypeDescription("Number"));
		TableTypesOfStocks_.Columns.Add("VATRate", New TypeDescription("CatalogRef.VATRates"));
	EndIf;
	
	ThereIsSumWithVAT = (TableTypesOfStocks_.Columns.Find("AmountIncludingVAT") <> Undefined);
	If Not ThereIsSumWithVAT Then
		TableTypesOfStocks_.Columns.Add("AmountIncludingVAT",  New TypeDescription("Number"));
	EndIf;
	
	ThereIsShippingWarehouse = (TableTypesOfStocks_.Columns.Find("OriginWarehouse") <> Undefined);
	If Not ThereIsShippingWarehouse Then
		TableTypesOfStocks_.Columns.Add("OriginWarehouse", New TypeDescription("CatalogRef.Warehouses"));
	EndIf;
	
	ThereIsImplementationDocument = (TableTypesOfStocks_.Columns.Find("DocumentSalesOfGoodsAndServices") <> Undefined);
	If Not ThereIsImplementationDocument Then
		TableTypesOfStocks_.Columns.Add("DocumentSalesOfGoodsAndServices", Documents.AllRefsType());
	EndIf;
	
	ThereIsCCDNumber = (TableTypesOfStocks_.Columns.Find("CCDNumber") <> Undefined);
	If Not ThereIsCCDNumber Then
		TableTypesOfStocks_.Columns.Add("CCDNumber", New TypeDescription("CatalogRef.CCDNumbers"));
	EndIf;
	
	ThereIsWayToDetermineCost = (TableTypesOfStocks_.Columns.Find("CostDefiningMethod") <> Undefined);
	If Not ThereIsWayToDetermineCost Then
		TableTypesOfStocks_.Columns.Add("CostDefiningMethod", New TypeDescription("EnumRef.WaysToCalculateReturnCost"));
	EndIf;
	
	ThereIsExciseTaxAmount = (TableTypesOfStocks_.Columns.Find("ExciseTaxAmount") <> Undefined);
	If Not ThereIsExciseTaxAmount Then
		TableTypesOfStocks_.Columns.Add("ExciseTaxAmount", New TypeDescription("Number"));
	EndIf;
	
	ThereIsInventoryOwnerAttributeOfRecipient = (TableTypesOfStocks_.Columns.Find("RecipientInventoryOwnerAttribute") <> Undefined);
	If Not ThereIsInventoryOwnerAttributeOfRecipient Then
		TableTypesOfStocks_.Columns.Add("RecipientInventoryOwnerAttribute", New TypeDescription("CatalogRef.InventoryKinds"));
	EndIf;
	
	Query.SetParameter("SourceTableStockTypes", TableTypesOfStocks_);
	
	Tree = FormAttributeToValue("InventoryKindTree");
	Tree.Rows.Clear();
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		EditInventoryKinds = False;
	Else
		SelectionByLines = QueryResult.Select(QueryResultIteration.ByGroups);
		While SelectionByLines.Next() Do
			
			AddProductLine = True;
			
			Selection = SelectionByLines.Select();
			RecordsCount = Selection.Count();
			
			If RecordsCount > 1
				Or InventoryOwnerAttributesAreSpecifiedManually
				Or SelectionByLines.Count = 0 Then
				
				AddSubordinateLines = True;
				
			ElsIf SelectionByLines.Count <> SelectionByLines.QuantityTypesOfInventory
				Or (ThereIsQuantityOfRNPTVTCHGoods
					And SelectionByLines.QuantityByGBRN <> SelectionByLines.QuantityByRNPTInventoryTypes)
				Or SelectionByLines.AmountIncludingVAT <> SelectionByLines.AmountWithVATVidsOfStocks
				Or SelectionByLines.VATAmount <> SelectionByLines.AmountOfNDSVidyOfStocks
				Or SelectionByLines.VATRate <> SelectionByLines.VATRateTypesOfInventory Then
				
				AddSubordinateLines = True;
				
			Else
				AddSubordinateLines = False;
			EndIf;
			
			While Selection.Next() Do
				
				If AddProductLine Then
				
					GroupRow = Tree.Rows.Add();
					FillPropertyValues(GroupRow, Selection);
					
					If Not Selection.QuantityByGBRN
						And Selection.QuantityByRNPTInventoryTypes Then
						
						GroupRow.QuantityByGBRN = Selection.Count * Selection.RNPTCoefficient;
						
					EndIf;
					
					If AddSubordinateLines Then
						GroupRow.InventoryOwnerAttribute = Undefined;
						GroupRow.RecipientInventoryOwnerAttribute = Undefined;
						GroupRow.CCDNumber = Undefined;
						GroupRow.InventoryType = Undefined;
						GroupRow.GoodsOwner = Undefined;
						GroupRow.Organization = Undefined;
						GroupRow.OriginWarehouse = Undefined;
						GroupRow.QuantityTypesOfInventory = 0;
						GroupRow.QuantityByRNPTInventoryTypes = 0;
						GroupRow.AmountWithVATVidsOfStocks = 0;
						GroupRow.AmountOfNDSVidyOfStocks = 0;
						GroupRow.CostDefiningMethod = Undefined;
						GroupRow.ExciseTaxAmount = 0;
						GroupRow.ExciseTaxBase = 0;
						GroupRow.SubjectToExcise = False;
					EndIf;
					
					AddProductLine = False;
				
				EndIf;
			
				If Selection.QuantityTypesOfInventory <> 0 And AddSubordinateLines Then
					
					OtherTypesOfStocks = GroupRow.Rows.Add();
					OtherTypesOfStocks.ProductsInventoryKinds = Selection.Products;
					OtherTypesOfStocks.CharacteristicInventoryKinds = Selection.Characteristic;
					OtherTypesOfStocks.PurposeTypesOfStocks = Selection.Purpose;
					OtherTypesOfStocks.BatchTypesOfStocks = Selection.Series;
					OtherTypesOfStocks.InventoryOwnerAttribute = Selection.InventoryOwnerAttribute;
					OtherTypesOfStocks.RecipientInventoryOwnerAttribute = Selection.RecipientInventoryOwnerAttribute;
					OtherTypesOfStocks.InventoryType = Selection.InventoryType;
					OtherTypesOfStocks.GoodsOwner = Selection.GoodsOwner;
					OtherTypesOfStocks.Organization = Selection.Organization;
					OtherTypesOfStocks.TheRecordsAreKeptByCCD = Selection.TheRecordsAreKeptByCCD;
					OtherTypesOfStocks.ItemsType = Selection.ItemsType;
					OtherTypesOfStocks.TracedGoods = Selection.TracedGoods;
					OtherTypesOfStocks.CCDNumber = Selection.CCDNumber;
					OtherTypesOfStocks.DocumentSalesOfGoodsAndServices = Selection.DocumentSalesOfGoodsAndServices;
					OtherTypesOfStocks.CostDefiningMethod = Selection.CostDefiningMethod;
					OtherTypesOfStocks.OriginWarehouse = Selection.OriginWarehouse;
					OtherTypesOfStocks.Count = Selection.QuantityTypesOfInventory;
					OtherTypesOfStocks.QuantityByGBRN = Selection.QuantityByRNPTInventoryTypes;
					OtherTypesOfStocks.RNPTCoefficient = Selection.RNPTCoefficient;
					OtherTypesOfStocks.AmountIncludingVAT = Selection.AmountWithVATVidsOfStocks;
					OtherTypesOfStocks.VATAmount = Selection.AmountOfNDSVidyOfStocks;
					OtherTypesOfStocks.VATRate = Selection.VATRateTypesOfInventory;
					OtherTypesOfStocks.ExcisableGoods = Selection.ExcisableGoods;
					OtherTypesOfStocks.SubjectToExcise = Selection.SubjectToExcise;
					OtherTypesOfStocks.ExciseTaxAmount = Selection.ExciseTaxAmount;
					OtherTypesOfStocks.ExciseTaxBase = Selection.ExciseTaxBase;
					OtherTypesOfStocks.ExciseUnit = Selection.ExciseUnit;
					OtherTypesOfStocks.ExciseConversionRatio = Selection.ExciseConversionRatio;
					OtherTypesOfStocks.ExcisableGoodsCategory = Selection.ExcisableGoodsCategory;
					OtherTypesOfStocks.ExciseTaxRate = Selection.ExciseTaxRate;
					OtherTypesOfStocks.LocalExciseTaxRate = Selection.LocalExciseTaxRate;
					OtherTypesOfStocks.CurrencyOfExciseDuty = Selection.CurrencyOfExciseDuty;
					GroupRow.QuantityTypesOfInventory = GroupRow.QuantityTypesOfInventory + Selection.QuantityTypesOfInventory;
					GroupRow.QuantityByRNPTInventoryTypes = GroupRow.QuantityByRNPTInventoryTypes + Selection.QuantityByRNPTInventoryTypes;
					GroupRow.AmountWithVATVidsOfStocks = GroupRow.AmountWithVATVidsOfStocks + Selection.AmountWithVATVidsOfStocks;
					GroupRow.AmountOfNDSVidyOfStocks = GroupRow.AmountOfNDSVidyOfStocks + Selection.AmountOfNDSVidyOfStocks;
					GroupRow.ExciseTaxAmount = GroupRow.ExciseTaxAmount + Selection.ExciseTaxAmount;
					GroupRow.ExciseTaxBase = GroupRow.ExciseTaxBase + Selection.ExciseTaxBase;
					GroupRow.SubjectToExcise = Max(GroupRow.SubjectToExcise, Selection.SubjectToExcise);
					GroupRow.ExcisableGoods = Max(GroupRow.ExcisableGoods, Selection.ExcisableGoods);
					If GroupRow.Count > GroupRow.QuantityTypesOfInventory Then
						Shortage_	= Format(GroupRow.Count - GroupRow.QuantityTypesOfInventory, "NFD=3");
						Information	= NStr("vi = 'Không đủ: %Count%';
												|ru = 'Недостаточно: %Count%';
												|en = 'Insufficient: %Count%'; fa = 'Insufficient: %Count%';
												|it = 'Insufficiente: %Count%';
												|pl = 'Niewystarczająco: %Count%';
												|tr = 'Yeterli değil: %Count%'");
						
						GroupRow.Information = StrReplace(Information, "%Count%", Shortage_);
					ElsIf GroupRow.Count < GroupRow.QuantityTypesOfInventory Then
						Surplus		= Format(GroupRow.QuantityTypesOfInventory - GroupRow.Count, "NFD=3");
						Information	= NStr("vi = 'Vượt quá: %Count%';
												|ru = 'Превышение: %Count%';
												|en = 'Exceeding: %Count%'; fa = 'Exceeding: %Count%';
												|it = 'Eccesso: %Count%';
												|pl = 'Przekroczenie: %Count%';
												|tr = 'Aşım: %Count%'");
						
						GroupRow.Information = StrReplace(Information, "%Count%", Surplus);
					Else
						GroupRow.Information = "";
					EndIf;
					
				EndIf;
			
			EndDo;
			
		EndDo;
		
		ValueToFormAttribute(Tree, "InventoryKindTree");
	EndIf;
	
	If Not VisibilityIsSet Then
		ShippingWarehouseIsUsed = ThereIsShippingWarehouse;
		Items.InventoryKindTreeAmountIncludingVAT.Visible     = (ThereIsSum Or ThereIsSaleAmount);
		Items.InventoryKindTreeVATRate.Visible     = ThereIsVATAmount;
		Items.InventoryKindTreeVATAmount.Visible      = ThereIsVATAmount;
		Items.StorageLocation.Visible                   = ThereIs_Warehouse Or ThereIsDivision;
		Items.InventoryKindTreeOriginWarehouse.Visible = ThereIsShippingWarehouse;
		VisibilityIsSet = True;
	EndIf;
	
	FillInCheckCCDNumberFieldOnServer();
	
EndProcedure

&AtClient
Procedure FillInInformationField(TableRow)
	
	If TableRow.Count > TableRow.QuantityTypesOfInventory Then
		TableRow.Information = "insufficient: " + Format(TableRow.Count - TableRow.QuantityTypesOfInventory, "NFD=3");
	ElsIf TableRow.Count < TableRow.QuantityTypesOfInventory Then
		TableRow.Information = "Excess: " + Format(TableRow.QuantityTypesOfInventory - TableRow.Count, "NFD=3");
	Else
		TableRow.Information = "";
	EndIf;
	
EndProcedure

#Region CCDNumbers

&AtServer
Procedure FillInCheckCCDNumberFieldOnServer()
	
	If Not UseTraceableImportedGoodsAccounting Then
		Return;
	EndIf;
	
	AccountingForTraceableGoodsLocalization.FillInCheckGTDNumberFieldInTree(ThisObject);
	Items.InventoryKindTreeToSelectProductBatchIDKits.Enabled = ThereIsProductBatchIDNoCost;
	
	If Not ThereIsProductBatchIDNoCost
		And Items.InventoryKindTreeToSelectProductBatchIDKits.Check Then
		
		Items.InventoryKindTreeToSelectProductBatchIDKits.Check = False;
		ToSelectProductBatchIDKits = Items.InventoryKindTreeToSelectProductBatchIDKits.Check;
		
	EndIf;
	
EndProcedure

&AtServer
Function CheckTraceabilityDataOfCCDNumberOnServer(CCDNumber)
	
	Return AccountingForTraceableGoodsLocalization.CheckTraceabilityDataOfCCDNumber(CCDNumber);
	
EndFunction

&AtClient
Procedure CCDNumberCreatingCompletion(Result, CurNumberOfCCD) Export
	
	CurrentData = Items.InventoryKindTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurNumberOfCCD)
		And CurrentData.CCDNumber = CurNumberOfCCD Then
		
		Return;
		
	EndIf;
	
	ProcessIndicationOfCCDNumber(CurrentData, CurNumberOfCCD);
	
EndProcedure

&AtClient
Procedure ProcessIndicationOfCCDNumber(CurrentData, CurNumberOfCCD)
	
	RowID = CurrentData.GetID();
	
	If RowID = Undefined Then
		Return;
	EndIf;
	
	ErrorMessageText = "";
	
	ProcessIndicationOfCCDNumberServer(RowID, ErrorMessageText);
	
	If Not IsBlankString(ErrorMessageText) Then
		CurrentData.CCDNumber = CurNumberOfCCD;
		
		ShowMessageBox(, ErrorMessageText);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessIndicationOfCCDNumberServer(RowID, ErrorMessageText)
	
	CurrentRow = InventoryKindTree.FindByID(RowID);
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CCDNumberIsSpecifiedCorrectly = CCDNumberIsSpecifiedCorrectly(CurrentRow, ErrorMessageText);
	
	If CCDNumberIsSpecifiedCorrectly Then
		CurrentRow.CheckCCDNumber = CheckTraceabilityDataOfCCDNumberOnServer(CurrentRow.CCDNumber);
	EndIf;
	
EndProcedure

&AtServer
Function CCDNumberIsSpecifiedCorrectly(CurrentRow, ErrorMessageText)
	
	CCDNumberIsSpecifiedCorrectly	= True;
	CCDNumberType			= Common.ObjectAttributeValue(CurrentRow.CCDNumber, "CCDNumberType");
	ListOfCCDTypes			= AccountingForTraceableGoodsClientServerLocalization.CCDNumberTypes(True);
	
	If ListOfCCDTypes.Find(CCDNumberType) <> Undefined Then
		Return CCDNumberIsSpecifiedCorrectly;
	EndIf;
	
	If CurrentRow.ItemsType = Enums.ItemsTypes.Work_5 Then
		CCDNumberIsSpecifiedCorrectly = False;
		
		ErrorMessageText = NStr("vi = '""%1"" không tương ứng với điều kiện lựa chọn';
								|ru = '""%1"" не соответствует условиям выбора';
								|en = '""%1"" does not meet the selection criteria'; fa = '""%1"" does not meet the selection criteria';
								|it = '""%1"" не соответствует условиям выбора';
								|pl = '""%1"" does not meet the selection criteria';
								|tr = '""%1"" seçim koşullarıyla eşleşmiyor'");
		ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(
									ErrorMessageText,
									TrimAll(String(CurrentRow.CCDNumber)));
	EndIf;
	
	Return CCDNumberIsSpecifiedCorrectly;
	
EndFunction

#EndRegion

&AtClient
Procedure FillInDataOnExciseTaxesInGroup(GroupRow)
	
	GroupRow.ExciseTaxAmount = 0;
	GroupRow.ExciseTaxBase = 0;
	GroupRow.SubjectToExcise = False;
	GroupRow.ExcisableGoods = False;
	For Each String In GroupRow.GetItems() Do
		GroupRow.ExciseTaxAmount = GroupRow.ExciseTaxAmount + String.ExciseTaxAmount;
		GroupRow.ExciseTaxBase = GroupRow.ExciseTaxBase + String.ExciseTaxBase;
		GroupRow.SubjectToExcise = Max(GroupRow.SubjectToExcise, String.SubjectToExcise);
		GroupRow.ExcisableGoods = Max(GroupRow.ExcisableGoods, String.ExcisableGoods);
	EndDo;
	
EndProcedure

&AtClient
Procedure OnChangingInventoryOwnerAttribute(Item)
	
	TableRow = Items.InventoryKindTree.CurrentData;
	ParentRow = TableRow.GetParent();
	If ValueIsFilled(ParentRow.ExcisableGoodsCategory) Then
		TableRow.SubjectToExcise = SubjectToExcise(TableRow[Item.Name]);
		If TableRow.SubjectToExcise Then
			TableRow.ExciseTaxBase = TableRow.Count * TableRow.ExciseConversionRatio;
			TableRow.ExciseTaxAmount = TableRow.ExciseTaxBase * ParentRow.LocalExciseTaxRate;
		Else
			TableRow.ExciseTaxBase = 0;
			TableRow.ExciseTaxAmount = 0;
		EndIf;
		FillInDataOnExciseTaxesInGroup(ParentRow);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function SubjectToExcise(InventoryOwnerAttribute)
	
	Return Catalogs.InventoryKinds.SubjectToExcise(InventoryOwnerAttribute);
	
EndFunction

&AtClient
Procedure EstablishAvailabilityOfDescriptionOfExciseCategoryOfItem(ExcisableGoods)
	
	Items.ExcisableGoodsDataGroup.Enabled = ExcisableGoods;
	
EndProcedure

&AtServer
Procedure FillInInventoryOwnerAttributesAtServer()
	
	BeginTransaction();
	
	Try
		
		ExceptionReason = 1;
		
		MetadataOfDocument = Recorder.Metadata();
		
		If ValueIsFilled(Recorder) Then
			Block = New DataLock;
			
			LockItem = Block.Add(MetadataOfDocument.FullName());
			LockItem.SetValue("Ref", Recorder);
			LockItem.Mode = DataLockMode.Shared;
			
			Block.Lock();
			
			DocumentObject = Recorder.GetObject();
		Else
			DocumentObject = Documents[MetadataOfDocument.Name].CreateDocument();
		EndIf;
		
		If DocumentObject <> Undefined Then
			ExceptionReason = 2;
			
			DocumentData = GetFromTempStorage(AddressOfDocumentDataInRepository);
			
			FillPropertyValues(DocumentObject, DocumentData);
			
			NameTSGoods			= OptionsForEditingInventoryTypes.NameTSGoods;
			NameTSTypesOfStocks	= OptionsForEditingInventoryTypes.NameTSTypesOfStocks;
			
			DocumentObject[NameTSGoods].Load(DocumentData[NameTSGoods]);
			DocumentObject[NameTSTypesOfStocks].Load(GetFromTempStorage(AddressOfInventoryKindsInStorage));
			
			ParametersForFillingInInventoryOwnerAttributesManually = InventoriesServer.ParametersForFillingInInventoryOwnerAttributesManually();
			ParametersForFillingInInventoryOwnerAttributesManually.IgnoreResidueControlErrors		= True;
			ParametersForFillingInInventoryOwnerAttributesManually.DoNotFillInInventoryOwnerAttributesOfExcisableItems	= True;
			
			DocumentObject.AdditionalProperties.Insert("RefillInventoryKinds", True);
			DocumentObject.AdditionalProperties.Insert("ParametersForFillingInInventoryOwnerAttributesManually",
															ParametersForFillingInInventoryOwnerAttributesManually);
			
			DocumentObject.FillOutTypesOfStockWhenExchanging(False, Undefined);
			FillInInventoryTypeTree(DocumentObject[NameTSTypesOfStocks].Unload());
		Else
			MessageText	= NStr("vi = 'Không thể điền dạng vật tư.';
									|ru = 'Не удалось заполнить виды запасов.';
									|en = 'Cannot fill inventory owner attributes.'; fa = 'Cannot fill inventory owner attributes.';
									|it = 'Cannot fill inventory owner attributes.';
									|pl = 'Cannot fill inventory owner attributes.';
									|tr = 'Stok sahibinin öznitelikleri doldurulamadı.'");
			DataKey		= ?(ValueIsFilled(Recorder), Recorder, Undefined);
			
			Common.MessageToUser(MessageText, DataKey);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		MessageText	= "";
		DataKey		= ?(ValueIsFilled(Recorder), Recorder, Undefined);
		
		If ExceptionReason = 1 Then
			MessageText = NStr("vi = 'Không thể phong tỏa %1. %2';
								|ru = 'Не удалось заблокировать %1. %2';
								|en = 'Cannot block %1. %2'; fa = 'Cannot block %1. %2';
								|it = 'Impossibile bloccare %1. %2';
								|pl = 'Nie udało się zablokować %1. %2';
								|tr = '%1 engellenemedi. %2'");
			MessageText = StrTemplate(MessageText,
										String(Recorder),
										ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		ElsIf ExceptionReason = 2 Then
			MessageText = NStr("vi = 'Không thể điền dạng vật tư do nguyên nhân: %1';
								|ru = 'Не удалось заполнить виды запасов по причине: %1';
								|en = 'Cannot fill inventory owner attributes. Reason: %1'; fa = 'Cannot fill inventory owner attributes. Reason: %1';
								|it = 'Cannot fill inventory owner attributes. Reason: %1';
								|pl = 'Cannot fill inventory owner attributes. Reason: %1';
								|tr = 'Stok sahibinin öznitelikleri şu nedenden dolayı doldurulamadı: %1'");
			MessageText = StrTemplate(MessageText,
										ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndIf;
		
		If Not IsBlankString(MessageText) Then
			Common.MessageToUser(MessageText, DataKey);
		EndIf;
		
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion
