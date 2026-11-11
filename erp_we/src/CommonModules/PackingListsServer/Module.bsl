#Region Public

// Called to initialize elements and details of a form that uses packing lists with a hierarchy.
// Parameters:
//	Form - ClientApplicationForm - form for performing actions,
//	TSGoods - FormDataCollection - table part where products and packing lists are displayed,
//	EntryLevelTitle - String - start of the navigation label used to navigate between
//		different nesting levels of packing lists,
//	GoodsViewMode - Boolean - indicates the display mode for the table part with packing lists,
//		True - "by products", False - "by product locations", by default Undefined,
//	PackingListParent - DocumentRef.PackingList - the current packing list is
//		Undefined by default.
//
Procedure WhenReadingCreatingFormWithPackingLists(Form,
	TSGoods, EntryLevelTitle, GoodsViewMode = Undefined, PackingListParent = Undefined) Export
	
	Form.UsePackingLists = GetFunctionalOption("UsePackingLists");
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "ThereAreLabeledProducts") Then
		Form.UsePackingLists = Form.UsePackingLists And Not Form.ThereAreLabeledProducts;
	EndIf;
	
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	FormElementsNames = FormElementsNames(NameTSGoods);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		"DecorationNavigationIndentation, DecorationOfPlaces",
		"Visible",
		Form.UsePackingLists);
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		FormElementsNames.LineNumber,
		"Visible",
		Not Form.UsePackingLists);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		FormElementsNames.GroupProductPackingList,
		"ShowInHeader",
		Form.UsePackingLists);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		FormElementsNames.Products,
		"ShowInHeader",
		Not Form.UsePackingLists);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"GroupScan",
		"Visible",
		Form.UsePeripherals
			And SeriesSpecificationParameters(Form).UseItemsBatch);
			
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		FormElementsNames.UpLevel,
		"Enabled",
		False);
	If PackingListParent = Undefined Then
		Form.PackingListParent = Documents.PackingList.EmptyRef();
	Else
		Form.PackingListParent = PackingListParent;
	EndIf;
	
	TotalNumberOfPackageItems = 0;
	FoundRows = TSGoods.FindRows(New Structure("PackingListParent", Documents.PackingList.EmptyRef()));
	If FoundRows.Count() > 0 Then
		For Each Page1 In FoundRows Do
			TotalNumberOfPackageItems = TotalNumberOfPackageItems + Page1.NumberOfPackages;
		EndDo;
		If Form.Object.TotalNumberOfPackageItems <> TotalNumberOfPackageItems Then
			Form.Object.TotalNumberOfPackageItems = TotalNumberOfPackageItems;
			Form.Modified = False
		EndIf;
	EndIf;
	
	DisplayModeOnChange(Form, TSGoods, EntryLevelTitle, GoodsViewMode);
	
EndProcedure

// Called when the item or packing list is changed
// Parameters:
//	Form - ClientApplicationForm - form for performing actions,
//	TSGoods - FormDataCollection - table part where products and packing lists are displayed,
//	FieldName - String - "Product packaginglist" or " product Nomenclature",
//	CachedValues - Structure - cached values of form details,
//	StructureOfActionsWithCurLine - Structure - actions to process,
//	StructureOfActionsWithAddedStrings_ - Structure - for processing new lines that are subordinate to the packing list,
//		the default value is Undefined,
//	AddLinesToAllSheets - Boolean - indicates whether the PM should be supplemented with lines
//		that are subordinate to the packing list (if the packing list is changed).
//
Procedure ProductsPackingListWhenChanged(Form, TSGoods, FieldName, CachedValues,
	StructureOfActionsWithCurLine, StructureOfActionsWithAddedStrings_ = Undefined, AddLinesToAllSheets = True) Export
	
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	FormElementsNames = FormElementsNames(NameTSGoods);
	
	ProductFormTable_ = Form.Items[NameTSGoods]; // FormTable
	CurrentRow = TSGoods.FindByID(ProductFormTable_.CurrentRow); // DocumentTabularSectionRow.GoodsIssueNote.ShippedGoods, FormDataCollectionItem
	
	If Not Form.UsePackingLists Then
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActionsWithCurLine, CachedValues);
		Return;
	EndIf;
	
	If FieldName = FormElementsNames.PackingList
			And CachedValues.PackingList = CurrentRow.PackingList
		Or FieldName = FormElementsNames.Products
			And CachedValues.Products = CurrentRow.Products Then
		
		Return;
		
	EndIf;

	If FieldName = FormElementsNames.PackingList Then
		CurrentRow.Products = Catalogs.Products.EmptyRef();
	Else
		CurrentRow.PackingList = Documents.PackingList.EmptyRef();
	EndIf;
	
	If FieldName = FormElementsNames.PackingList
		And ValueIsFilled(CurrentRow.PackingList)
		And TSGoods.FindRows(New Structure("PackingList", CurrentRow.PackingList)).Count() > 1 Then
		
		ErrorText = NStr("vi = 'Không thể chọn %PackingList% vì đã có trong thành phần chứng từ.';
						|ru = 'Нельзя выбрать %PackingList%, т.к. он уже включен в состав документа.';
						|en = 'Cannot select %PackingList% as it is already included in the document.'; fa = 'Cannot select %PackingList% as it is already included in the document.';
						|it = 'Non selezionare %PackingList%, poiché è già incluso nella composizione del documento.';
						|pl = 'Nie można wybrać %PackingList%, gdyż jest on już włączony w skład dokumentu.';
						|tr = 'Belge içeriğine zaten dahil edildiği için %PackingList% öğesi seçilemez.'");
		ErrorText = StrReplace(ErrorText, "%PackingList%", CurrentRow.PackingList);
		CommonClientServer.MessageToUser(ErrorText);
		CurrentRow.PackingList = CachedValues.PackingList;
		Return;
		
	EndIf;
	
	StringsToProcess = New Array;
	
	If FieldName = FormElementsNames.PackingList
		And ValueIsFilled(CurrentRow.PackingList) Then
		If CachedValues.PackingList = CurrentRow.PackingList Then
			Return;
		EndIf;
		
		CurrentRow.ThisIsAPackingList  = True;
		CurrentRow.Count          = 1;
		CurrentRow.NumberOfPackages  = 1;
		CurrentRow.Products        = Catalogs.Products.EmptyRef();
		CurrentRow.BatchesIndicationStatus = 0;
		
		If SeriesSpecificationParameters(Form).FullObjectName = "Document.GoodsIssueNote" Then
			CurrentRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;
		EndIf;

		
		If AddLinesToAllSheets Then
			HasErrors = False;
			
			StringsToProcess.Add(CurrentRow);
			AddLinesOnPackingLists(Form, TSGoods, StringsToProcess, HasErrors,,True);
			StringsToProcess.Delete(0);
			
			If HasErrors Then
				CurrentRow.PackingList = CachedValues.PackingList;
				Return;
			EndIf;
		EndIf;
		RecalculateNumberOfSeats(Form, TSGoods);
		
	Else
		If CachedValues.Products = CurrentRow.Products Then
			Return;
		EndIf;
		
		CurrentRow.ThisIsAPackingList = False;
		CurrentRow.Count         = 0;
		CurrentRow.NumberOfPackages = 0;
		CurrentRow.PackingList = Documents.PackingList.EmptyRef();
		CurrentRow.AdditionalInformation = "";
		CurrentRow.PackingListCode = "";
		CurrentRow.PackingListDate = Date(1,1,1);
		CurrentRow.NumberOfCompletedSubordinatePositions = 0;
		CurrentRow.ShowsAPackingListPicture = 0;
		If FieldName = "GoodsProducts"
			And ValueIsFilled(CurrentRow.PackingListParent) Then
			FoundRows = Form.PackingLists.FindRows(
				New Structure("PackingList", CurrentRow.PackingListParent));
			CurrentRow.PackingListParentCode = FoundRows[0].PackingListCode;
		EndIf;
		
	EndIf;
	
	If CachedValues.PackingList <> CurrentRow.PackingList
		And ValueIsFilled(CachedValues.PackingList) Then
		
		If SeriesSpecificationParameters(Form).NameTSGoods = SeriesSpecificationParameters(Form).TSSeriesName Then
			RecursivelyBypassSubordinateStrings(TSGoods, CachedValues.PackingList, , , "Delete");
		Else
			RecursivelyBypassSubordinateStrings(TSGoods,
				CachedValues.PackingList, Form.Object[SeriesSpecificationParameters(Form).TSSeriesName], , "Delete");
		EndIf;
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Form.Object, SeriesSpecificationParameters(Form), StringsToProcess);
	
	// It is necessary to check, clean the packaging, the characteristic for the current line
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActionsWithCurLine, CachedValues);
	//   and re-fill in other service details
	If StructureOfActionsWithAddedStrings_ = Undefined Then
		StructureOfActionsWithAddedStrings_ = New Structure;		
	EndIf;
	FillInServiceDetails(Form, TSGoods, StructureOfActionsWithAddedStrings_, StringsToProcess, False, CachedValues);
		
	If CurrentRow.ThisIsInternalRowOfEmptyPackingList
		And ValueIsFilled(CurrentRow.Products)
		And ValueIsFilled(CurrentRow.PackingListParent) Then
		
		// The service line that is being edited is no longer a service line
		CurrentRow.ThisIsInternalRowOfEmptyPackingList = 0;
		
	EndIf;
	
EndProcedure

// Called to initialize elements and details of a form that uses packing lists with a hierarchy.
// Parameters:
//	Form - ClientApplicationForm - form for performing actions,
//	TSGoods - FormDataCollection - table part where products and packing lists are displayed,
//	EntryLevelTitle - String - start of the navigation label used to navigate between
//		different nesting levels of packing lists,
//	GoodsViewMode - Boolean - indicates the display mode for the table part with packing lists,
//		True - "by products", False - "by product locations", by default Undefined.
//
Procedure DisplayModeOnChange(Form, TSGoods, EntryLevelTitle, GoodsViewMode = Undefined) Export
	
	If Not Form.UsePackingLists Then
		Form.MaximumLineNumber = TSGoods.Count();
		Return;
	EndIf;
	
	If GoodsViewMode = Undefined Then
		GoodsViewMode = Form.Object.GoodsViewMode;
	EndIf;
	
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	FormElementsNames = FormElementsNames(NameTSGoods);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		FormElementsNames.PictureOfPackingList + "," + FormElementsNames.UpLevel + ",
		|NavigationText," + FormElementsNames.Unpack + "," + FormElementsNames.Pack + ",
		|" + FormElementsNames.AdditionalInfoPackingList,
		"Visible",
		Not GoodsViewMode);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		"IndentNavigation",
		"Visible",
		GoodsViewMode);
		
	Form.Items[FormElementsNames.GroupProductPackingList].ShowInHeader = Not GoodsViewMode;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		"DecorationNavigationIndentation," + FormElementsNames.PackingListParent,
		"Visible",
		GoodsViewMode);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		"DecorationNavigationIndentation",
		"HorizontalStretch",
		GoodsViewMode);
	
	Form.Items[FormElementsNames.Products].ShowInHeader = GoodsViewMode;
	
	If GoodsViewMode Then
		If Form.Items[NameTSGoods].RowFilter <> Undefined
			And Form.Items[NameTSGoods].RowFilter.Property("DataProcessorIsRequired") Then
			Form.Items[NameTSGoods].RowFilter = New FixedStructure("ThisIsAPackingList, DataProcessorIsRequired", False, 1);
		Else
			Form.Items[NameTSGoods].RowFilter = New FixedStructure("ThisIsAPackingList", False);
		EndIf;
		
		Form.PackingListParent = Documents.PackingList.EmptyRef();
		RenumberLines(Form, TSGoods);
		
	Else
		
		ProductFormTable_ = Form.Items[NameTSGoods]; // FormTable
		RowID = ProductFormTable_.CurrentRow;
		If RowID <> Undefined Then
			CurrentRow = TSGoods.FindByID(RowID);
			If CurrentRow <> Undefined Then
				Form.PackingListParent = CurrentRow.PackingListParent;
			EndIf;
		EndIf;
		
		WhenMovingToAnotherLevel(Form, TSGoods,
			Form.PackingListParent, EntryLevelTitle); // renumbering is also here
		
	EndIf;
	
EndProcedure

// Instead of a string-the packing list in the PM you will see the composition of this packing list,
//		nested packing lists are not expanded.
// Parameters:
//	Form - ClientApplicationForm - Form for performing actions:
// 		* Object - FormDataStructure -:
// 			** SetOfSeries - FormDataCollection -
//
Procedure UnpackPackingList(Form) Export
	
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	
	MinimumWHNumber = Form.Object[NameTSGoods].Count();
	ThereAreUnpackedLines = False;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	For Each Id In Form.Items[NameTSGoods].SelectedRows Do
		
		Page1 = Form.Object[NameTSGoods].FindByID(Id);
		If Not Page1.ThisIsAPackingList Then
			
 			ProductsClientServer.UpdateCachedValuesToAccountForSeries(Page1,CachedValues,SeriesSpecificationParameters(Form)); 			
			
			Page1.PackingListParent = Documents.PackingList.EmptyRef();
			Page1.PackingListParentCode = "";
			ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Form.Object,
																							SeriesSpecificationParameters(Form), 
																							Page1.GetID(),
																							CachedValues);
			ThereAreUnpackedLines = True;
		Else
			
			FoundRows = Form.Object[NameTSGoods].FindRows(New Structure("PackingListParent",Page1.PackingList));
			For Each NestedRow In FoundRows Do
				If NestedRow.ThisIsInternalRowOfEmptyPackingList Then
					Form.Object[NameTSGoods].Delete(NestedRow);
					Break;
				EndIf;
				NestedRow.PackingListParent = Form.PackingListParent;
				NestedRow.PackingListParentCode = Common.ObjectAttributeValue(Form.PackingListParent,"Code");
				IndexOfNestedRow = Form.Object[NameTSGoods].IndexOf(NestedRow);
				Form.Object[NameTSGoods].Move(IndexOfNestedRow, Form.Object[NameTSGoods].IndexOf(Page1) - IndexOfNestedRow);
			EndDo;
			MinimumWHNumber = Min(MinimumWHNumber, Page1.LineNumberDisplayed);
			Form.Object[NameTSGoods].Delete(Page1);
			ThereAreUnpackedLines = True;
			
			If SeriesSpecificationParameters(Form).NameTSGoods <> SeriesSpecificationParameters(Form).TSSeriesName Then
				FoundRows = Form.Object.SetOfSeries.FindRows(New Structure("PackingListParent",Page1.PackingList));
				For Each NestedRow In FoundRows Do
					NestedRow.PackingListParent = Form.PackingListParent;
				EndDo;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ThereAreUnpackedLines Then
		RenumberLines(Form, Form.Object[NameTSGoods], MinimumWHNumber);
		FillInServiceDetails(Form, Form.Object[NameTSGoods], New Structure);
		RecalculateNumberOfSeats(Form, Form.Object[NameTSGoods]);
	EndIf;
	
	Form.Modified = True;
	ProductsServer.FillInStatusesForSpecifyingSeries(Form.Object, SeriesSpecificationParameters(Form));
	
EndProcedure

// The selected lines are included in the new packing list. in PM, they are displayed as a packing list line.
// Parameters:
//	Form - ClientApplicationForm - Form for performing actions:
// 		* Object - FormDataStructure -:
// 			** SetOfSeries - FormDataCollection -
//
// Returns:
//   - DocumentRef.PackingList - link to the created packing list.
//
Function PackServer(Form) Export
	
	Var CachedValues;
	
	If Not Form.CheckFilling() Then
		Return Undefined;
	EndIf;
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	
	StringsCombined = New Array;
	
	DocObject = Documents.PackingList.CreateDocument();
	DocObject.Date = CurrentSessionDate();
	DocObject.Kind = Enums.PackingListKinds.Outgoing;
	
	If SeriesSpecificationParameters(Form).FullObjectName = "Document.GoodsIssueNote" Then
		DocObject.PackedBy = Users.CurrentUser();
		DocObject.PackageWarehouse = Form.Object.Warehouse;
		DocObject.Basis = BasisOfPackingListOnOrder(Form.Object);
	EndIf;
	
	DocObject.Write(DocumentWriteMode.Posting);
	DocObject.Lock();
	
	MinimumIndex_ = Form.Object[NameTSGoods].Count();
	
	ThereAreGoodsUnshipped = False;
	For Each Id In Form.Items[NameTSGoods].SelectedRows Do
		Page1 = Form.Object[NameTSGoods].FindByID(Id); // DocumentTabularSectionRow.GoodsIssueNote.ShippedGoods, FormDataCollectionItem
		If Page1.Property("DoNotShip") And Page1.DoNotShip Then
			ThereAreGoodsUnshipped = True;
			Continue;
		EndIf;
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(Page1, CachedValues, SeriesSpecificationParameters(Form));
		StringsCombined.Add(Page1);
		If Page1.ThisIsAPackingList Then
			RecursivelyBypassSubordinateStrings(Form.Object[NameTSGoods], Page1.PackingList, , StringsCombined);
		EndIf;
		Page1.PackingListParent = DocObject.Ref;
		Page1.PackingListParentCode = DocObject.Code;
		
		If SeriesSpecificationParameters(Form).FullObjectName = "Document.GoodsIssueNote" Then
			Page1.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;
		EndIf;
		
		MinimumIndex_ = Min(MinimumIndex_, Form.Object[NameTSGoods].IndexOf(Page1));
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Form.Object, SeriesSpecificationParameters(Form), Id, CachedValues);
	EndDo;
	If ThereAreGoodsUnshipped Then
		CommonClientServer.MessageToUser(NStr("vi = 'Sẽ không thêm các dòng chưa giao hàng vào phiếu đóng gói.';
												|ru = 'Неотгружаемые строки не будут добавлены в упаковочный лист.';
												|en = 'Unshipped lines will not be added to the packing list.'; fa = 'Unshipped lines will not be added to the packing list.';
												|it = 'Le linee non caricate non verranno aggiunte alla lista di imballaggio.';
												|pl = 'Niewysłane wiersze nie zostaną dodane do arkusza opakowaniowego.';
												|tr = 'Sevk edilmeyen satırlar ürün listesine eklenmeyecektir.'"));
	EndIf;

	If StringsCombined.Count() = 0 Then
		Return Undefined;
	EndIf;

	MinimumNumber_ = Form.Object[NameTSGoods][MinimumIndex_].LineNumberDisplayed;
	
	GoodsTable = Form.Object[NameTSGoods].Unload(StringsCombined);
	If GoodsTable.Columns.Find("Purpose") = Undefined Then
		GoodsTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	EndIf;
	
	FoundRows = GoodsTable.FindRows(New Structure("PackingListParent", DocObject.Ref));
	For Each RowOfProductsTable In FoundRows Do
		RowOfProductsTable.PackingListParent = Documents.PackingList.EmptyRef();
	EndDo;
	If SeriesSpecificationParameters(Form).NameTSGoods <> SeriesSpecificationParameters(Form).TSSeriesName Then
		
		GoodsTable.GroupBy("Products,Characteristic,Purpose,Package,PackingList,
			|ThisIsAPackingList,PackingListParent",
			"Count,NumberOfPackages");
		Query = New Query;
		Query.Text=
		"SELECT
		|	Goods.Count,
		|	Goods.NumberOfPackages,
		|	Goods.Products,
		|	Goods.Package,
		|	Goods.PackingList,
		|	Goods.ThisIsAPackingList,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	CASE
		|		WHEN Goods.PackingListParent = &Ref
		|			THEN VALUE(Document.PackingList.EmptyRef)
		|		ELSE Goods.PackingListParent
		|	END AS PackingListParent
		|INTO Goods
		|FROM
		|	&GoodsTable AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.Count,
		|	SetOfSeries.NumberOfPackages,
		|	SetOfSeries.Products,
		|	SetOfSeries.Series,
		|	SetOfSeries.Package,
		|	SetOfSeries.Characteristic,
		|	SetOfSeries.Purpose,
		|	CASE
		|		WHEN SetOfSeries.PackingListParent = &Ref
		|			THEN VALUE(Document.PackingList.EmptyRef)
		|		ELSE SetOfSeries.PackingListParent
		|	END AS PackingListParent
		|INTO SetOfSeries
		|FROM
		|	&SeriesTable AS SetOfSeries
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductPackages.Ref AS Ref,
		|	&QueryTextPackagingFactor AS ZoomRatio
		|INTO Packages
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|WHERE
		|	ProductPackages.Ref IN
		|			(SELECT
		|				Goods.Package
		|			FROM
		|				Goods)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	ISNULL(SetOfSeries.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
		|	Goods.Package AS Package,
		|	Goods.PackingList,
		|	Goods.ThisIsAPackingList,
		|	Goods.PackingListParent AS PackingListParent,
		|	ISNULL(SetOfSeries.Count, Goods.Count) AS Count,
		|	ISNULL(SetOfSeries.Count, Goods.Count) / ISNULL(Packages.ZoomRatio, 1) AS NumberOfPackages
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN SetOfSeries AS SetOfSeries
		|		ON Goods.Products = SetOfSeries.Products
		|			AND Goods.Characteristic = SetOfSeries.Characteristic
		|			AND Goods.PackingListParent = SetOfSeries.PackingListParent
		|			AND &ConditionForPackages
		|		LEFT JOIN Packages AS Packages
		|		ON Goods.Package = Packages.Ref";
		
		Query.Text = StrReplace(Query.Text,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPackages", Undefined));
		If SeriesSpecificationParameters(Form).LinkFields.Find("Package") = Undefined Then
			Query.Text = StrReplace(Query.Text, "&ConditionForPackages", "TRUE");
		Else
			Query.Text = StrReplace(Query.Text, "&ConditionForPackages", "Goods.Package = SetOfSeries.Package");
		EndIf;
		
		Query.SetParameter("GoodsTable", GoodsTable);
		
		If ThereAreGoodsUnshipped Then
			SeriesTable = Form.Object.SetOfSeries.Unload(New Structure("DoNotShip", 0));//ValueTable
		Else
			SeriesTable = Form.Object.SetOfSeries.Unload();//ValueTable
		EndIf;
		If SeriesTable.Columns.Find("Purpose") = Undefined Then
			SeriesTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		EndIf;
		Query.SetParameter("SeriesTable", SeriesTable);
		
		Query.SetParameter("Ref", DocObject.Ref);
		GoodsTable = Query.Execute().Unload();
		
	EndIf;
	
	DocObject.Goods.Load(GoodsTable);
	ProductsServer.FillInStatusesForSpecifyingSeries(DocObject, Documents.PackingList.SeriesSpecificationParameters(DocObject));
	DocObject.Write(DocumentWriteMode.Posting);
	DocObject.Unlock();
	
	NewRow = Form.Object[NameTSGoods].Insert(MinimumIndex_); // DocumentTabularSectionRow.GoodsIssueNote.ShippedGoods, FormDataCollectionItem
	NewRow.ThisIsAPackingList = True;
	NewRow.PackingList = DocObject.Ref;
	NewRow.PackingListParent = Form.PackingListParent;
	NewRow.Count = 1;
	NewRow.NumberOfPackages = 1;
	
	If SeriesSpecificationParameters(Form).FullObjectName = "Document.GoodsIssueNote" Then
		NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;	
	EndIf;	
		
	FillInServiceDetails(Form, Form.Object[NameTSGoods], New Structure, NewRow, False);
	
	RenumberLines(Form, Form.Object[NameTSGoods], MinimumNumber_);
	
	RecalculateNumberOfSeats(Form, Form.Object[NameTSGoods]);
	
	Return DocObject.Ref;
	
EndFunction

// Conditional clearance for the PM with the packing lists.
// Parameters:
//	Form - ClientApplicationForm - form for performing actions,
//	TSName - String - name of the table part to be checked, by default "Products".
//
Procedure EstablishConditionalAppearanceTakingIntoAccountPackingLists(Form, TSName = "Goods") Export
	
	PathToPropsIsPackingList = "Object." + TSName + ".ThisIsAPackingList";
	FormElementsNames = FormElementsNames(TSName);
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.PackingList);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.AdditionalInfoPackingList);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.PackingListCode);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToPropsIsPackingList);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.Products);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.AdditionalInfoProducts);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.ProductsCode);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToPropsIsPackingList);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.ProductsSKU);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToPropsIsPackingList);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng mã hiệu>';
													|ru = '<артикул не используется>';
													|en = '<item ID is not used>'; fa = '<item ID is not used>';
													|it = '< articolo non si utilizza>';
													|pl = '<element nie jest używany>';
													|tr = '<kod kullanılmıyor>'"));
	
	//
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.Characteristic);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToPropsIsPackingList);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.ProductsUnitOfMeasure);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToPropsIsPackingList);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'vị trí';
													|ru = 'место';
													|en = 'place'; fa = 'place';
													|it = 'luogo';
													|pl = 'place';
													|tr = 'yer'"));
	
	//
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.Package);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToPropsIsPackingList);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementsNames.NumberOfPackages);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToPropsIsPackingList);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Verification of filling with PM characteristics with packing lists
// Parameters:
//	Object	- ClientApplicationForm - The Form contains, among other things:
//				* Ref - DocumentRef - document being checked
//			- DocumentObject - document being checked
//	CheckedAttributes - Array - the names of the details you need to check,
//	NotCheckedAttributeArray - Array - the names of the details that you want to exclude from checking platform,
//	Cancel - Boolean - a sign of validation errors,
//	TSName - String - name of the table part to be checked, by default "Products".
//
Procedure CheckFillingOfPMWithPackingLists(Object, CheckedAttributes, NotCheckedAttributeArray, Cancel, TSName = "Goods") Export
	
	QueryFields = "";
	LengthOfTSName = StrLen(TSName);
	
	If TypeOf(Object) <> Type("ClientApplicationForm") Then
		ObjectMetadata = Object.Metadata();
	Else
		ObjectMetadata = Object.Ref.Metadata();
	EndIf;
	
	TSDetailsForVerification = New Array;
	For Each Attribute In CheckedAttributes Do
		If NotCheckedAttributeArray.Find(Attribute) <> Undefined Then
			Continue;
		EndIf;
		If Left(Attribute, LengthOfTSName + 1) = TSName +"." Then
			NotCheckedAttributeArray.Add(Attribute);
			If Attribute <> TSName + ".PackingList"
				And Attribute <> TSName + ".Count" Then
				TSDetailsForVerification.Add(Mid(Attribute, LengthOfTSName + 2, StrLen(Attribute) - LengthOfTSName - 1));
				QueryFields = QueryFields + "
					|" + Attribute + ",";
			EndIf;
		EndIf;
	EndDo;
	
	QueryText =
	"SELECT
	|	Goods.QueryFields,
	|	Goods.Products,
	|	Goods.PackingList,
	|	Goods.PackingListParent,
	|	Goods.ThisIsAPackingList,
	|	Goods.ThisIsInternalRowOfEmptyPackingList,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.PackingList,
	|	TRUE AS ThereAreDuplicates
	|INTO TTPackingListsWithErrors
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.PackingList
	|
	|HAVING
	|	COUNT(*) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.PackingListParent AS PackingList,
	|	MAX(ISNULL(TTPackingListsWithErrors.ThereAreDuplicates, FALSE)) AS ThereAreDuplicates,
	|	SUM(CASE
	|			WHEN Goods.Products = VALUE(Catalog.Products.EmptyRef)
	|					AND Goods.PackingList = VALUE(Document.PackingList.EmptyRef)
	|				THEN 0
	|			ELSE 1
	|		END) AS NumberOfFilledRows,
	|	MIN(Goods.LineNumber) AS LineNumber
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN TTPackingListsWithErrors AS TTPackingListsWithErrors
	|		ON Goods.PackingListParent = TTPackingListsWithErrors.PackingList
	|WHERE
	|	Goods.PackingListParent <> VALUE(Document.PackingList.EmptyRef)
	|
	|GROUP BY
	|	Goods.PackingListParent
	|
	|HAVING
	|	(MAX(ISNULL(TTPackingListsWithErrors.ThereAreDuplicates, FALSE)) = TRUE
	|		OR SUM(CASE
	|				WHEN Goods.Products = VALUE(Catalog.Products.EmptyRef)
	|						OR Goods.PackingList = VALUE(Document.PackingList.EmptyRef)
	|					THEN 0
	|				ELSE 1
	|			END) = 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.QueryFields,
	|	Goods.LineNumber
	|	
	|FROM
	|	Goods AS Goods
	|WHERE
	|	NOT Goods.ThisIsAPackingList
	|	AND Goods.ThisIsInternalRowOfEmptyPackingList = 0";
	
	QueryFields = StrReplace(QueryFields, TSName + ".", "Goods.");
	
	QueryText = StrReplace(QueryText,"Goods.QueryFields,",QueryFields);
	
	Query = New Query(QueryText);
	
	Query.SetParameter("Goods", Object[TSName].Unload());
	
	ResultsArray = Query.ExecuteBatch();
	Result = ResultsArray[2]; // QueryResult
	Selection = Result.Select();
	
	PresentationOfTS = ObjectMetadata.TabularSections[TSName].Synonym;
	
	While Selection.Next() Do
		
		Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "Products");
		
		If Selection.ThereAreDuplicates Then
			ErrorText = NStr("vi = '%PackingList% đã chỉ ra nhiều lần trong chứng từ. Hãy xóa các dòng trùng lặp có phiếu đóng gói, khi sử dụng chế độ xem ""Theo vị trí hàng hóa"".';
							|ru = '%PackingList% указан в документе несколько раз. Удалите дублирующиеся строки с упаковочными листами, используя режим просмотра ""По товарным местам"".';
							|en = '%PackingList% has been specified in the document several times. Delete duplicate entries with packing lists using the ""By cargo items"" view mode.'; fa = '%PackingList% has been specified in the document several times. Delete duplicate entries with packing lists using the ""By cargo items"" view mode.';
							|it = '%PackingList% indicata nel documento diverse volte. Eliminare le righe doppiate con le distinte di imballaggio che utilizzano la modalità di visualizzazione ""Per luoghi"".';
							|pl = '%PackingList% określono w dokumencie kilka razy. Usuń zduplikowane wiersze z górnymi kartkami, korzystając z trybu wyświetlania ""Wg miejsc towarowych"".';
							|tr = 'Belgede birkaç kez %PackingList% belirtildi. ""Kargo paketine göre"" görünüm modunu kullanarak yinelenen ürün listesi satırlarını sil.'");
			ErrorText = StrReplace(ErrorText, "%PackingList%", Selection.PackingList);
			CommonClientServer.MessageToUser(ErrorText, Object, Field, "Object",Cancel);
		EndIf;
		If Selection.NumberOfFilledRows = 0 Then
			ErrorText = NStr("vi = '%PackingList%: chưa điền thành phần.';
							|ru = '%PackingList%: состав не заполнен.';
							|en = '%PackingList%: content is not filled in.'; fa = '%PackingList%: content is not filled in.';
							|it = '%PackingList%:  composizione non compilata.';
							|pl = '%PackingList%: zawartość nie jest wypełniona.';
							|tr = '%PackingList%: içerik doldurulmadı.'");
			ErrorText = StrReplace(ErrorText, "%PackingList%", Selection.PackingList);
			CommonClientServer.MessageToUser(ErrorText,, TSName, "Object", Cancel);
		EndIf;
		
	EndDo;
	
	Result = ResultsArray[3]; // QueryResult
	Selection = Result.Select();
	
	LineNumber = 1;
	While Selection.Next() Do
		
		For Each Attribute In TSDetailsForVerification Do
			If Not ValueIsFilled(Selection[Attribute]) Then
				ErrorText = NStr("vi = 'Chưa điền cột ""%Attribute%"" tại dòng %LineNumber% trong danh sách ""%TSName%"".';
								|ru = 'Не заполнена колонка ""%Attribute%"" в строке %LineNumber% списка ""%TSName%"".';
								|en = 'Column ""%Attribute%"" in line %LineNumber% of the ""%TSName%"" list is not filled in.'; fa = 'Column ""%Attribute%"" in line %LineNumber% of the ""%TSName%"" list is not filled in.';
								|it = 'Colonna ""%Attribute%""  non compilata nella riga %LineNumber% dell''elenco ""%TSName%"".';
								|pl = 'Nie wypełniona kolumna ""%Attribute%"" w wierszu %LineNumber% listy ""%TSName%"".';
								|tr = '""%TSName%"" listesinin %LineNumber% satırındaki ""%Attribute%"" sütunu doldurulmadı.'");
				ErrorText = StrReplace(ErrorText, "%TSName%", PresentationOfTS);
				ErrorText = StrReplace(ErrorText, "%Attribute%", ObjectMetadata.TabularSections[TSName].Attributes[Attribute].Synonym);
				ErrorText = StrReplace(ErrorText, "%LineNumber%", LineNumber);
				Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, Attribute);
				CommonClientServer.MessageToUser(ErrorText, , Field, "Object", Cancel);
			EndIf;
		EndDo;
		
		LineNumber = LineNumber + 1;
	EndDo;
	
EndProcedure

// Defines packing lists that have the composition cached in the order that does not match the contents
//	stored in the packing list, and synchronizes such packing lists with the order.
// Parameters:
//	OrderLink - DocumentRef.GoodsIssueNote - order to synchronize,
//	UseBinLocationWarehousing - Boolean - indicates whether address storage is used in a warehouse or in a room.
// 
// Returns:
//   - Array - links to packing lists whose PM needed to be synchronized.
//
Function SynchronizePackingListsWithSpendingOrder(OrderLink, UseBinLocationWarehousing) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.PackingList AS PackingList
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ThisIsAPackingList
	|	AND GoodsTable.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Package,
	|	1 AS Count,
	|	1 AS NumberOfPackages,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	GoodsTable.ThisIsAPackingList AS ThisIsAPackingList,
	|	GoodsTable.PackingList AS PackingList,
	|	GoodsTable.PackingListParent AS PackingListParent
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ThisIsAPackingList
	|	AND GoodsTable.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Package,
	|	GoodsTable.Count,
	|	GoodsTable.NumberOfPackages,
	|	GoodsTable.Series,
	|	GoodsTable.ThisIsAPackingList AS ThisIsAPackingList,
	|	VALUE(Document.PackingList.EmptyRef),
	|	GoodsTable.PackingListParent
	|FROM
	|	Document.GoodsIssueNote.ShippedGoods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.ThisIsAPackingList
	|	AND GoodsTable.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|";
	
	OrderDetails_1 = Common.ObjectAttributesValues(OrderLink, "Status, Warehouse");
	
	Query.SetParameter("Ref",OrderLink);
	Query.SetParameter("Status",OrderDetails_1.Status);
	ResultsArray = Query.ExecuteBatch();
	PackingLists = ResultsArray[0].Unload().UnloadColumn("PackingList");
	Result = ResultsArray[1]; // QueryResult
	Goods = Result.Unload();
	Goods.Columns.Add("TopLevelPackingList", New TypeDescription("DocumentRef.PackingList"));
	
	ProductsToCheckForChanges = Goods.CopyColumns();
	
	For Each PackingList In PackingLists Do
		PackingListLines = New Array;
		RecursivelyBypassSubordinateStrings(Goods, PackingList, , PackingListLines);
		GoodsByPackingList = Goods.Copy(PackingListLines);
		GoodsByPackingList.FillValues(PackingList, "TopLevelPackingList");
		CommonClientServer.SupplementTable(GoodsByPackingList, ProductsToCheckForChanges);
	EndDo;
	
	Query.Text =
	"SELECT
	|	Goods.TopLevelPackingList AS Ref,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.Package,
	|	Goods.Count,
	|	Goods.PackingList,
	|	CASE
	|		WHEN Goods.PackingListParent = Goods.TopLevelPackingList
	|			THEN VALUE(Document.PackingList.EmptyRef)
	|		ELSE Goods.PackingListParent
	|	END AS PackingListParent
	|INTO ProductsToCheckForChanges
	|FROM
	|	&ProductsToCheckForChanges AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Goods.Ref
	|INTO ReFillTS
	|FROM
	|	(SELECT
	|		Goods.Ref AS Ref,
	|		Goods.Products AS Products,
	|		Goods.Characteristic AS Characteristic,
	|		Goods.Series AS Series,
	|		Goods.Package AS Package,
	|		Goods.Count AS Count,
	|		Goods.PackingList AS PackingList,
	|		Goods.PackingListParent AS PackingListParent
	|	FROM
	|		Document.PackingList.Goods AS Goods
	|	WHERE
	|		Goods.Ref IN(&PackingLists)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Ref,
	|		Goods.Products,
	|		Goods.Characteristic,
	|		Goods.Series,
	|		Goods.Package,
	|		-Goods.Count,
	|		Goods.PackingList,
	|		Goods.PackingListParent
	|	FROM
	|		ProductsToCheckForChanges AS Goods) AS Goods
	|
	|GROUP BY
	|	Goods.Ref,
	|	Goods.PackingListParent,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
	|	Goods.PackingList
	|
	|HAVING
	|	SUM(Goods.Count) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReFillTS.Ref
	|FROM
	|	ReFillTS AS ReFillTS
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReFillBase.Ref AS Ref
	|FROM
	|	Document.PackingList AS ReFillBase
	|WHERE
	|	ReFillBase.Ref IN(&PackingLists)
	|	AND ReFillBase.Basis <> &Basis
	|	AND NOT ReFillBase.Ref IN
	|				(SELECT
	|					ReFillTS.Ref
	|				FROM
	|					ReFillTS)"; 
	
	Basis = BasisOfPackingListOnOrder(OrderLink);
	
	Query.SetParameter("PackingLists",PackingLists);
	Query.SetParameter("ProductsToCheckForChanges", ProductsToCheckForChanges);
	Query.SetParameter("Basis", Basis);
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[3].Select();
	While Selection.Next() Do
		DocObject = Selection.Ref.GetObject();
		DocObject.Lock();
		DocObject.Basis = Basis;
		DocObject.Write();
	EndDo;
	
	PackingLists = Result[2].Unload().UnloadColumn("Ref");
	If Result[2].IsEmpty() Then
		PackingLists = New Array;
	EndIf;
	
	For Each Ref In PackingLists Do
		
		ProductsToDownload = ProductsToCheckForChanges.Copy(New Structure("TopLevelPackingList",Ref));
		For Each Page1 In ProductsToDownload Do
			If Page1.PackingListParent = Ref Then
				Page1.PackingListParent = Documents.PackingList.EmptyRef();
			EndIf;
		EndDo;
		DocObject = Ref.GetObject();
		DocObject.Lock();
		DocObject.PackedBy = Users.CurrentUser();
		DocObject.PackageWarehouse = OrderDetails_1.Warehouse;
		DocObject.Basis = Basis;
		DocObject.Goods.Load(ProductsToDownload);
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocObject, Documents.PackingList);
		ProductsServer.FillInStatusesForSpecifyingSeries(DocObject, SeriesSpecificationParameters);
		DocObject.Write();
		
	EndDo;
	
	Return PackingLists;
	
EndFunction

// Adds lines of the packing list to the inventory Items, is called when the item or packing list is changed,
//		and checks whether the packing lists are re-included in the Inventory items.
// Parameters:
//	Form - ClientApplicationForm - form for performing actions,
//	TSGoods - FormDataCollection - table part where products and packing lists are displayed,
//	StringsToProcessAreConcatenated - Array - processed PM lines are Goods,
//		and PM lines supplemented from the packing list are also collected in this array,
//	HasErrors - Boolean - indicates whether there are errors during the procedure, False by default,
//	ErrorsInLog - Boolean - indicates that errors need to be recorded in the log,
//		false by default,
//	ExcludeFirstBlankSheetFromCheck - Boolean - indicates that the first packing list from the
//		string for processing is Combined and should be excluded from the check. by default, it is false.
//
Procedure AddLinesOnPackingLists(Form,
	TSGoods, StringsToProcessAreConcatenated, HasErrors = False, ErrorsInLog = False, ExcludeFirstBlankSheetFromCheck = False) Export
	
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	
	Query = New Query;
		Query.Text =
		"SELECT
		|	PackingListGoods.Ref
		|INTO TTPackingListsWithErrors
		|FROM
		|	Document.PackingList.Goods AS PackingListGoods
		|WHERE
		|	PackingListGoods.PackingList IN(&PackingSheetsOfDocument)
		|	AND NOT PackingListGoods.PackingList = &ExcludedPackingList
		|	AND PackingListGoods.Ref IN(&PackingLists)
		|
		|GROUP BY
		|	PackingListGoods.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTPackingListsWithErrors.Ref
		|FROM
		|	TTPackingListsWithErrors AS TTPackingListsWithErrors
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PackingListGoods.Ref AS Ref,
		|	PackingListGoods.Products,
		|	PackingListGoods.Characteristic,
		|	PackingListGoods.Series,
		|	PackingListGoods.Purpose,
		|	CASE WHEN PackingListGoods.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		AND PackingListGoods.Package.MeasuredValueType IN
		|			(VALUE(Enum.TypesOfMeasuredValues.Weight),
		|			 VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
		|			 VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement),
		|			 VALUE(Enum.TypesOfMeasuredValues.Length))
		|		THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		ELSE PackingListGoods.Package
		|	END AS Package,
		|	CASE WHEN PackingListGoods.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		AND PackingListGoods.Package.MeasuredValueType IN
		|			(VALUE(Enum.TypesOfMeasuredValues.Weight),
		|			 VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
		|			 VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement),
		|			 VALUE(Enum.TypesOfMeasuredValues.Length))
		|		THEN PackingListGoods.Count
		|		ELSE PackingListGoods.NumberOfPackages
		|	END AS NumberOfPackages,
		|	PackingListGoods.Count,
		|	PackingListGoods.PackingList,
		|	PackingListGoods.PartnerProducts,
		|	PackingListGoods.Comment,
		|	PackingListGoods.ThisIsAPackingList,
		|	CASE
		|		WHEN PackingListGoods.PackingListParent = VALUE(Document.PackingList.EmptyRef)
		|			THEN PackingListGoods.Ref
		|		ELSE PackingListGoods.PackingListParent
		|	END AS PackingListParent
		|INTO TTPackingSheets
		|FROM
		|	Document.PackingList.Goods AS PackingListGoods
		|WHERE
		|	PackingListGoods.Ref IN(&PackingLists)
		|	AND NOT PackingListGoods.Ref IN
		|				(SELECT
		|					TTPackingListsWithErrors.Ref
		|				FROM
		|					TTPackingListsWithErrors)
		|
		|INDEX BY
		|	Ref,
		|	PackingListParent
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTPackingLists.Ref AS Ref,
		|	MAX(TTPackingLists.Code) AS Code
		|INTO TTPackingLists
		|FROM
		|	Document.PackingList AS TTPackingLists
		|		INNER JOIN TTPackingSheets AS TTPackingSheets
		|		ON (TTPackingSheets.PackingListParent = TTPackingLists.Ref)
		|
		|GROUP BY
		|	TTPackingLists.Ref
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTPackingSheets.Products,
		|	TTPackingSheets.Characteristic,
		|	CASE WHEN &WHSeriesProducts THEN
		|			TTPackingSheets.Series
		|		ELSE
		|			VALUE(Catalog.ItemsBatches.EmptyRef)
		|		END AS Series,
		|	TTPackingSheets.Purpose,
		|	TTPackingSheets.Characteristic,
		|	TTPackingSheets.Package,
		|	SUM(TTPackingSheets.NumberOfPackages) AS NumberOfPackages,
		|	SUM(TTPackingSheets.Count) AS Count,
		|	TTPackingSheets.PackingList,
		|	TTPackingSheets.ThisIsAPackingList,
		|	TTPackingSheets.PackingListParent,
		|	TTPackingLists.Code AS PackingListParentCode
		|FROM
		|	TTPackingSheets AS TTPackingSheets
		|		LEFT JOIN TTPackingLists AS TTPackingLists
		|		ON TTPackingSheets.PackingListParent = TTPackingLists.Ref
		|
		|GROUP BY
		|	TTPackingSheets.Package,
		|	TTPackingSheets.PackingList,
		|	TTPackingSheets.ThisIsAPackingList,
		|	TTPackingSheets.PackingListParent,
		|	CASE WHEN &WHSeriesProducts THEN
		|			TTPackingSheets.Series
		|		ELSE
		|			VALUE(Catalog.ItemsBatches.EmptyRef)
		|		END,
		|	TTPackingSheets.Purpose,
		|	TTPackingSheets.Characteristic,
		|	TTPackingSheets.Products,
		|	TTPackingLists.Code
		|;
		|
		|//[5]//////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	SetOfSeries.Series,
		|	SetOfSeries.Purpose,
		|	CASE
		|		WHEN &PackingInCommunicationFields
		|			THEN SetOfSeries.Package
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END AS Package,
		|	CASE
		|		WHEN &PackingInCommunicationFields
		|			THEN SUM(SetOfSeries.NumberOfPackages)
		|		ELSE SUM(SetOfSeries.Count)
		|	END AS NumberOfPackages,
		|	SUM(SetOfSeries.Count) AS Count,
		|	SetOfSeries.PackingListParent
		|FROM
		|	TTPackingSheets AS SetOfSeries
		|WHERE
		|	SetOfSeries.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|
		|GROUP BY
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	SetOfSeries.Series,
		|	SetOfSeries.Purpose,
		|	CASE
		|		WHEN &PackingInCommunicationFields
		|			THEN SetOfSeries.Package
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END,
		|	SetOfSeries.PackingListParent";
	
	PackingLists = TSGoods.Unload(StringsToProcessAreConcatenated, "PackingList").UnloadColumn("PackingList");
	
	Query.SetParameter("PackingLists", PackingLists);
	WHSeriesProducts = (SeriesSpecificationParameters(Form).NameTSGoods = SeriesSpecificationParameters(Form).TSSeriesName);
	Query.SetParameter("WHSeriesProducts", WHSeriesProducts);
	
	VTPackingLists = TSGoods.Unload(New Structure("ThisIsAPackingList",True),"PackingList");
	Query.SetParameter("PackingSheetsOfDocument", VTPackingLists.UnloadColumn("PackingList"));
	Query.SetParameter("PackingInCommunicationFields", SeriesSpecificationParameters(Form).LinkFields.Find("Package") <> Undefined);
	Query.SetParameter("ExcludedPackingList",
		?(ExcludeFirstBlankSheetFromCheck, StringsToProcessAreConcatenated[0].PackingList, Documents.PackingList.EmptyRef()));
	
	QueryResult = Query.ExecuteBatch();
	ErrorSelection = QueryResult[1].Select();
	EventName  = NStr("vi = 'Đã xảy ra lỗi trong khi bổ sung chứng từ với các dòng trên danh sách đóng gói.';
						|ru = 'Ошибка при дополнении документа строками по упаковочным листам.';
						|en = 'An error occurred while adding packing list lines to the document.'; fa = 'An error occurred while adding packing list lines to the document.';
						|it = 'Errore durante l''aggiunta del documento alle distinte di imballaggio.';
						|pl = 'Błąd podczas uzupełnienie dokumentu wierszami dla arkuszy opakowań.';
						|tr = 'Ürün listesine göre belge satırlarını doldururken hata.'",
		CommonClientServer.DefaultLanguageCode());
	ErrorText = NStr("vi = 'Không thể thêm %PackingList% vì đã có phiếu đóng gói trong thành phần chứng từ.';
					|ru = 'Нельзя добавить %PackingList%, т.к. он содержит упаковочные листы, которые уже включены в состав документа.';
					|en = 'Cannot add  %PackingList% as it includes packing lists included in the document.'; fa = 'Cannot add  %PackingList% as it includes packing lists included in the document.';
					|it = 'Non aggiungere %PackingList%, poiché contiene distinte di imballaggio che sono già incluse nella composizione del documento.';
					|pl = 'Nie można dodać %PackingList%, bo zawiera on arkusze, opakowań które już są zawarte w dokumencie.';
					|tr = 'Belge içeriğine zaten dahil edilmiş olan ürün listeleri içerdiğinden %PackingList% eklenemez.'");
	
	While ErrorSelection.Next() Do
		
		ErrorText = StrReplace(ErrorText, "%PackingList%", ErrorSelection.Ref);
		FoundRows = TSGoods.FindRows(New Structure("PackingList", ErrorSelection.Ref)); // Array of LineOfATabularSection
		If FoundRows.Count() > 0 Then
			
			If ErrorsInLog Then
				
				WriteLogEvent(
					EventName,
					EventLogLevel.Error,
					ErrorSelection.Ref.Metadata(),
					ErrorSelection.Ref,
					ErrorText);
			Else
				Field = CommonClientServer.PathToTabularSection("Object." + NameTSGoods,
					FoundRows[0].LineNumber, "PackingList");
					CommonClientServer.MessageToUser(ErrorText, , Field,,HasErrors);
			EndIf;
			FoundRows[0].PackingList = Documents.PackingList.EmptyRef();
		EndIf;
		
	EndDo;
	
	For Each Page1 In QueryResult[4].Unload() Do
		NewRow = TSGoods.Add(); // DocumentTabularSectionRow.GoodsIssueNote.ShippedGoods
		FillPropertyValues(NewRow, Page1);
		If SeriesSpecificationParameters(Form).FullObjectName = "Document.GoodsIssueNote" Then
			NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;
		EndIf;
		StringsToProcessAreConcatenated.Add(NewRow);
	EndDo;
	
	If Not WHSeriesProducts Then
		For Each Page1 In QueryResult[5].Unload() Do
			FormOfTS = Form.Object[SeriesSpecificationParameters(Form).TSSeriesName]; // FormDataCollection
			NewRow = FormOfTS.Add();
			FillPropertyValues(NewRow, Page1);
		EndDo;
	EndIf;
	
EndProcedure

// Recursively traverses the rows of the packing list is used to retrieve or delete all the rows in the hierarchy
// Parameters:
//	TSGoods - FormDataCollection - table part where products and packing lists are displayed,
//	PackingList - DocumentRef.PackingList - packing list to bypass the lines,
//	TSSetOfSeries - FormDataCollection - table part with product series, Undefined by default,
//	StringsCombined - Array - consists of data form elements of the collection Element, where PM lines
//		that are subordinate to the packing list are collected, by default Undefined,
//	Action - String - "Merge "or" Delete", by default"Merge".
//
Procedure RecursivelyBypassSubordinateStrings(TSGoods,
	PackingList, TSSetOfSeries = Undefined, StringsCombined = Undefined, Action = "Union") Export
	
	FoundRows = TSGoods.FindRows(New Structure("PackingListParent", PackingList));
	For Each Page1 In FoundRows Do
		If Action = "Delete" Then
			TSGoods.Delete(Page1);
			If Not TSSetOfSeries = Undefined Then
				FoundSeriesRows_ = TSSetOfSeries.FindRows(New Structure("PackingListParent", PackingList));
				For Each SeriesString In FoundSeriesRows_ Do
					TSSetOfSeries.Delete(SeriesString);
				EndDo;
			EndIf;
		Else
			StringsCombined.Add(Page1);
		EndIf;
		If Page1.ThisIsAPackingList Then
			RecursivelyBypassSubordinateStrings(TSGoods, Page1.PackingList, TSSetOfSeries, StringsCombined, Action);
		EndIf;
	EndDo;
	
EndProcedure

// The service fills in the details.
// Parameters:
//	Form - ClientApplicationForm - form for performing actions,
//	TSGoods - FormDataCollection - table part where products and packing lists are displayed,
//	StructureOfActions - Structure - the steps needed to produce,
//	FillInLines - Array - line Mccovery in which you need to fill the service details
//		default is Undefined,
//	Renumber - Boolean - indicates that the PM needs to be numbered after filling in,
//	CachedValues - Structure - cache for filling in Bank details.
//
Procedure FillInServiceDetails(Form,
	TSGoods, StructureOfActions, Val FillInLines = Undefined, Renumber = True, CachedValues = Undefined) Export
	
	If Not Form.UsePackingLists Then
		Form.MaximumLineNumber = TSGoods.Count();
		If StructureOfActions <> Undefined Then
			ProductsServer.FillInServiceDetailsForProductInCollection(TSGoods,StructureOfActions);
		EndIf;
		Return;
	EndIf;
	
	If TSGoods.Count() > 0
		And TSGoods.Count() <> TSGoods[TSGoods.Count() - 1].LineNumber Then
		For LineNumber = 1 To TSGoods.Count() Do
			TSGoods[LineNumber - 1].LineNumber = LineNumber;
		EndDo;
	EndIf;
	
	GoodsTable = TSGoods.Unload(,
		"ThisIsAPackingList,PackingList,Products,
		|PackingListParent,LineNumber,ThisIsInternalRowOfEmptyPackingList");
	
	If FillInLines = Undefined Then
		ArrayOfFillInLineNumbers = GoodsTable.UnloadColumn("LineNumber");
	Else
		If TypeOf(FillInLines) = Type("FormDataCollectionItem") Then
			FillString = FillInLines;
			FillInLines = New Array;
			FillInLines.Add(FillString);
		ElsIf TypeOf(FillInLines) = Type("Number") Then
			FillString = TSGoods.FindByID(FillInLines);
			FillInLines = New Array;
			FillInLines.Add(FillString);
		EndIf;
		ArrayOfFillInLineNumbers = TSGoods.Unload(FillInLines, "LineNumber").UnloadColumn("LineNumber");
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.ThisIsAPackingList,
	|	GoodsTable.PackingList,
	|	GoodsTable.Products,
	|	GoodsTable.PackingListParent,
	|	GoodsTable.LineNumber,
	|	GoodsTable.ThisIsInternalRowOfEmptyPackingList
	|INTO TTProducts_1
	|FROM
	|	&Goods AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.PackingListParent,
	|	COUNT(*) AS RowsCount,
	|	SUM(CASE
	|			WHEN TTProducts_1.Products = VALUE(Catalog.Products.EmptyRef)
	|					AND TTProducts_1.PackingList = VALUE(Document.PackingList.EmptyRef)
	|				THEN 0
	|			ELSE 1
	|		END) AS NumberOfFilledRows
	|INTO TTNumberOfSubordinates
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	TTProducts_1.PackingListParent <> VALUE(Document.PackingList.EmptyRef)
	|
	|GROUP BY
	|	TTProducts_1.PackingListParent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackingLists.Ref,
	|	PackingLists.Code,
	|	PackingLists.Date,
	|	ISNULL(TTNumberOfSubordinates.RowsCount, 0) AS RowsCount,
	|	ISNULL(TTNumberOfSubordinates.NumberOfFilledRows, 0) AS NumberOfFilledRows,
	|	TTProducts_1.PackingListParent
	|INTO TTPackingSheets
	|FROM
	|	Document.PackingList AS PackingLists
	|		INNER JOIN TTProducts_1 AS TTProducts_1
	|		ON (TTProducts_1.PackingList = PackingLists.Ref)
	|		LEFT JOIN TTNumberOfSubordinates AS TTNumberOfSubordinates
	|		ON (TTProducts_1.PackingList = TTNumberOfSubordinates.PackingListParent)
	|;
	|
	|//[3]//////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.LineNumber,
	|	0 AS ShowsAPackingListPicture,
	|	PackingListsParents.Code AS PackingListParentCode
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|		LEFT JOIN TTPackingSheets AS PackingListsParents
	|		ON TTProducts_1.PackingListParent = PackingListsParents.Ref
	|WHERE
	|	NOT TTProducts_1.ThisIsAPackingList
	|	AND TTProducts_1.LineNumber IN(&ArrayOfFillInLineNumbers)
	|;
	|
	|//[4]//////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.LineNumber,
	|	PackingLists.Code AS PackingListCode,
	|	PackingLists.Date AS PackingListDate,
	|	1 AS ShowsAPackingListPicture,
	|	PackingLists.NumberOfFilledRows AS NumberOfCompletedSubordinatePositions,
	|	PackingLists.RowsCount AS RowsCount,
	|	CASE
	|		WHEN PackingLists.NumberOfFilledRows = 0
	|			THEN 1
	|		ELSE 0
	|	END AS DataProcessorIsRequired,
	|	CASE
	|		WHEN PackingLists.NumberOfFilledRows = 0
	|			THEN &LineCompositionIsNotFilledIn
	|		ELSE &StringNumberOfPositions
	|	END AS AdditionalInformation
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|		INNER JOIN TTPackingSheets AS PackingLists
	|		ON TTProducts_1.PackingList = PackingLists.Ref
	|WHERE
	|	TTProducts_1.ThisIsAPackingList
	|;
	|
	|//[5]//////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServiceLines.Ref AS PackingListParent,
	|	ServiceLines.Code AS PackingListParentCode,
	|	1 AS ThisIsInternalRowOfEmptyPackingList,
	|	1 AS DataProcessorIsRequired,
	|	&LineCompositionIsNotFilledIn AS AdditionalInformation
	|FROM
	|	TTPackingSheets AS ServiceLines
	|WHERE
	|	ServiceLines.RowsCount = 0
	|;
	|
	|//[6]//////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServiceLinesToDelete.LineNumber
	|FROM
	|	TTProducts_1 AS ServiceLinesToDelete
	|		INNER JOIN TTPackingSheets AS TTPackingSheets
	|		ON ServiceLinesToDelete.PackingListParent = TTPackingSheets.Ref
	|WHERE
	|	ServiceLinesToDelete.ThisIsInternalRowOfEmptyPackingList = 1
	|	AND TTPackingSheets.RowsCount > 1
	|
	|ORDER BY
	|	ServiceLinesToDelete.LineNumber DESC";
	
	LineCompositionIsNotFilledIn  = NStr("vi = '<chưa điền thành phần phiếu đóng gói>';
										|ru = '<не заполнен состав упаковочного листа>';
										|en = '<packing list content is not filled in>'; fa = '<packing list content is not filled in>';
										|it = '<composizione della distinta di imballaggio non compilata>';
										|pl = '<nie jest wypełniony na liście pakowania>';
										|tr = '< ürün listesi bileşimi doldurulmadı>'");
	StringNumberOfPositions = NStr("vi = '%NumberOfRows% trong thành phần';
									|ru = '%NumberOfRows% в составе';
									|en = '%NumberOfRows% in'; fa = '%NumberOfRows% in';
									|it = '%NumberOfRows% nella composizione';
									|pl = '%NumberOfRows% w składzie';
									|tr = '%NumberOfRows% içeriğinde'");
	
	TemplateForNumberOfPositions	= NStr("vi = '; %1 vị trí; ; %1 vị trí; %1 vị trí;';
											|ru = ';%1 позиция; ;%1 позиции;%1 позиций;';
											|en = ';%1 position; ;%1 positions;%1 positions;'; fa = ';%1 position; ;%1 positions;%1 positions;';
											|it = '%1 posizione;;%1 posizione;%1 posizioni;';
											|pl = ';%1 pozycja; ;%1 pozycji;%1 pozycji;';
											|tr = ';%1 konum; ;%1 konumlar;%1 konumların;'");
	
	Query.SetParameter("Goods", GoodsTable);
	Query.SetParameter("ArrayOfFillInLineNumbers", ArrayOfFillInLineNumbers);
	Query.SetParameter("LineCompositionIsNotFilledIn", LineCompositionIsNotFilledIn);
	Query.SetParameter("StringNumberOfPositions", StringNumberOfPositions);
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[3].Select();
	While Selection.Next() Do
		Page1 = TSGoods[Selection.LineNumber-1];
		FillPropertyValues(Page1, Selection);
	EndDo;
	
	Selection = Result[4].Select();
	While Selection.Next() Do
		Page1 = TSGoods[Selection.LineNumber-1];
		FillPropertyValues(Page1, Selection);
		
		FoundRows = Form.PackingLists.FindRows(New Structure("PackingList", Page1.PackingList));
		If FoundRows.Count() = 0 Then
			RowWithNewSheet = Form.PackingLists.Add();
		Else
			RowWithNewSheet = FoundRows[0];
		EndIf;
		FillPropertyValues(RowWithNewSheet, Page1);
		RowWithNewSheet.IDOfTheRowWithTheUpSheet = Page1.GetID();
		
		If Selection.NumberOfCompletedSubordinatePositions > 0 Then
			Page1.AdditionalInformation = StrReplace(StringNumberOfPositions,
														"%NumberOfRows%",
														StringFunctionsClientServer.StringWithNumberForAnyLanguage(TemplateForNumberOfPositions,
																												Selection.NumberOfCompletedSubordinatePositions,
																												Undefined));
		EndIf;
		
	EndDo;
	
	For Each Page1 In Result[5].Unload() Do
		NewRow = TSGoods.Add();
		FillPropertyValues(NewRow, Page1);
	EndDo;
	
	Selection = Result[6].Select();
	While Selection.Next() Do
		TSGoods.Delete(Selection.LineNumber-1);
	EndDo;
	
	FillingStructure = New Structure;
	For Each KeyAndValue In StructureOfActions Do
		If BatchProcessingOfTablePartServer.KeyForFillingInServiceDetailsIsSupported(KeyAndValue.Key) Then
			FillingStructure.Insert(KeyAndValue.Key, KeyAndValue.Value);
			StructureOfActions.Delete(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	If FillingStructure.Count() > 0 Then 
		ProductsServer.FillInServiceDetailsForProductInCollection(TSGoods,FillingStructure);
	EndIf;
	
	If StructureOfActions <> Undefined
		And StructureOfActions.Count() > 0 Then
		// Checking, cleaning of packages, characteristics was performed earlier in the nomenclature of the Packing List().
		BatchProcessingOfTablePartServer.TreatTS(TSGoods, StructureOfActions, CachedValues);
	EndIf;
	
	If Renumber Then
		RenumberLines(Form, TSGoods);
	EndIf;
	
EndProcedure

// Numbers lines in PM where the default numbering does not match the displayed line order,
//		used for PM with packing lists
// Parameters:
//	Form - ClientApplicationForm - form for performing actions,
//	TSGoods - FormDataCollection - table part where products and packing lists are displayed,
//	StartingWithNumber - Number - the line number (displayed) to start numbering from, by default 1.
//
Procedure RenumberLines(Form, TSGoods, StartingWithNumber = 1) Export
	
	If Not Form.UsePackingLists Then
		Form.MaximumLineNumber = TSGoods.Count();
		Return;
	EndIf;
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	
	RowFilter = Form.Items[NameTSGoods].RowFilter;
	If RowFilter.Property("ThisIsAPackingList") Then
		TheStructureOfTheSearch = New Structure("ThisIsAPackingList", False);
	Else
		TheStructureOfTheSearch = New Structure(
			"PackingListParent, ThisIsInternalRowOfEmptyPackingList",
			Form.PackingListParent, 0);
	EndIf;
	
	FoundRows = TSGoods.FindRows(TheStructureOfTheSearch);
	StartingWithNumber = Min(Max(StartingWithNumber, 1), FoundRows.Count());
	If StartingWithNumber > 0 Then
		For IndexOf = StartingWithNumber - 1 To FoundRows.Count() - 1 Do
			FoundRows[IndexOf].LineNumberDisplayed = IndexOf + 1;
		EndDo;
		Form.MaximumLineNumber = IndexOf;
	Else
		Form.MaximumLineNumber = 0;
	EndIf;
	
EndProcedure

// Fills in the details of the Object form.Segment.
// Parameters:
//	Form - ClientApplicationForm - form for performing actions,
//	TSGoods - FormDataCollection - table part that displays products and packing lists.
//
Procedure RecalculateNumberOfSeats(Form, TSGoods) Export
	
	Form.Object.TotalNumberOfPackageItems = NumberOfSeatsWH(TSGoods);
	
EndProcedure

// Calculates the total number of seats in PM
//
// Parameters:
//  TS	 - FormDataCollection - table part for which the number of seats is calculated.
// 
// Returns:
//   - Number - the number of items in PM.
//
Function NumberOfSeatsWH(TS) Export
	
	FoundRows = TS.FindRows(New Structure("PackingListParent", Documents.PackingList.EmptyRef()));
	TotalNumberOfPackageItems = 0;
	For Each Page1 In FoundRows Do
		TotalNumberOfPackageItems = TotalNumberOfPackageItems + Page1.NumberOfPackages;
	EndDo;
	Return TotalNumberOfPackageItems;
	
EndFunction

// Performs actions when navigating through the nesting levels of packing lists.
// Parameters:
//	Form - ClientApplicationForm - form for performing actions,
//	TSGoods - FormDataCollection - table part where products and packing lists are displayed
//	URL - DocumentRef.PackingList, String, UUID -
//		indicator of the level to go to
//	EntryLevelTitle - String - start of the navigation label used to navigate between
//		different nesting levels of packing lists,
//	DisplayHyperlinks - Boolean - indicates that the navigation bar is displayed as hyperlinks,
//		True by default.
//
Procedure WhenMovingToAnotherLevel(Form,
	TSGoods, URL, EntryLevelTitle, DisplayHyperlinks = True) Export
	
	If Not Form.UsePackingLists Then
		Form.MaximumLineNumber = TSGoods.Count();
		Return;
	EndIf;
	
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	FormElementsNames = FormElementsNames(NameTSGoods);
	
	If URL = "0" Then
		PackingListParent = Documents.PackingList.EmptyRef()
	ElsIf TypeOf(URL) <> Type("DocumentRef.PackingList") Then
		PackingListParent = Documents.PackingList.GetRef(New UUID(URL));
	Else
		PackingListParent = URL;
	EndIf;
	
	Form.PackingListParent = PackingListParent;
	
	If Form.FormName <> Metadata.DataProcessors.GoodsQuantityCheckInGoodsReceiptNote.DefaultForm.FullName() Then
		ButtonToLevelUp = Form.Items[FormElementsNames.UpLevel]; // FormButton
		ButtonToLevelUp.Enabled = ValueIsFilled(PackingListParent);
	EndIf;
	
	CreateNavigationLabel(Form, EntryLevelTitle, DisplayHyperlinks);
	
	If Form.Items[NameTSGoods].RowFilter <> Undefined
		And Form.Items[NameTSGoods].RowFilter.Property("DataProcessorIsRequired") Then
		Form.Items[NameTSGoods].RowFilter = New FixedStructure(
			"PackingListParent, ThisIsInternalRowOfEmptyPackingList, DataProcessorIsRequired",
			Form.PackingListParent, 0, 1);
	Else
		Form.Items[NameTSGoods].RowFilter = New FixedStructure(
			"PackingListParent, ThisIsInternalRowOfEmptyPackingList",
			Form.PackingListParent, 0);
	EndIf;
	
	RenumberLines(Form, TSGoods);
	
EndProcedure

// Creates a label for navigating through the nesting levels of packing lists.
// Parameters:
//	Form - ClientApplicationForm - form for performing actions,
//	EntryLevelTitle - String - start of the navigation label used to navigate between
//		different nesting levels of packing lists,
//	DisplayHyperlinks - Boolean - indicates that the navigation bar is displayed as hyperlinks,
//		True by default.
//
Procedure CreateNavigationLabel(Form, EntryLevelTitle, DisplayHyperlinks = True) Export
	
	If Not Form.UsePackingLists Then
		Return;
	EndIf;
	
	If Form.Items.Find("DisplayMode") = Undefined Then
		DisplayHyperlinks = False;
	EndIf;
	
	If Not ValueIsFilled(Form.PackingListParent) Then
		
		Form.NavigationText = New FormattedString(EntryLevelTitle, New Font(,,True));
		
	Else
		FoundRows = Form.PackingLists.FindRows(New Structure("PackingList", Form.PackingListParent));
		CurUpSheet = FoundRows[0];
		RowsArray = New Array;
		RowWithCurSheet = New FormattedString(Metadata.Documents.PackingList.ObjectPresentation
			+ " " + CurUpSheet.PackingListCode, New Font(,,True));
		RowsArray.Add(" \ ");
		RowsArray.Add(RowWithCurSheet);
		
		If ValueIsFilled(CurUpSheet.PackingListParent) Then
			
			RecursivelyAssembleArrayOfNavigationLabelLines(Form.PackingLists,
				CurUpSheet.PackingListParent, RowsArray, False, DisplayHyperlinks);
			
			NavigationText = New FormattedString(RowsArray);
			If StrLen(NavigationText) > 80 Then
				RowsArray = New Array;
				RowsArray.Add(" \ ");
				RowsArray.Add(RowWithCurSheet);
				RecursivelyAssembleArrayOfNavigationLabelLines(Form.PackingLists,
					Form.PackingListParent, RowsArray, True, DisplayHyperlinks);
			EndIf;
		EndIf;
		If DisplayHyperlinks Then
			RowsArray.Insert(0, New FormattedString(EntryLevelTitle,,,,"0"));
		Else
			RowsArray.Insert(0, New FormattedString(EntryLevelTitle));
		EndIf;
		Form.NavigationText = New FormattedString(RowsArray);
		
	EndIf;
	
EndProcedure

// Performs actions after deleting a line in PM with packing lists.
//
// Parameters:
//  Form					 - ClientApplicationForm - form for performing actions,
//  TSGoods				 - FormDataCollection - table part with packing lists,
//  GoodsViewMode	 - Boolean - indicates the display mode for the table part with packing lists,
//		True - "by goods", False - "by goods places".
//
Procedure AfterRemovalOfVTCHSPackingSheets(Form, TSGoods, GoodsViewMode) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.PackingList,
	|	GoodsTable.PackingListParent,
	|	GoodsTable.ThisIsAPackingList,
	|	GoodsTable.LineNumber
	|INTO TTProducts_1
	|FROM
	|	&GoodsTable AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.PackingListParent AS PackingList
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	NOT TTProducts_1.PackingListParent IN
	|				(SELECT
	|					TTProducts_1.PackingList
	|				FROM
	|					TTProducts_1)
	|	AND TTProducts_1.PackingListParent <> VALUE(Document.PackingList.EmptyRef)
	|
	|GROUP BY
	|	TTProducts_1.PackingListParent";
	
	Query.SetParameter("GoodsTable", TSGoods.Unload(,"PackingList, PackingListParent,ThisIsAPackingList, LineNumber"));
	
	ResultsArray = Query.ExecuteBatch();
	Result = ResultsArray[1]; // QueryResult
	Selection = Result.Select();
	
	ArrayOfPackingListRowsToDelete = New Array;
	
	While Selection.Next() Do
		If SeriesSpecificationParameters(Form).NameTSGoods = SeriesSpecificationParameters(Form).TSSeriesName Then
			RecursivelyBypassSubordinateStrings(TSGoods, Selection.PackingList, , , "Delete");
		Else
			RecursivelyBypassSubordinateStrings(TSGoods,
				Selection.PackingList, Form.Object[SeriesSpecificationParameters(Form).TSSeriesName], , "Delete");
		EndIf;
		
		Filter = New Structure("PackingList", Selection.PackingList);
		PackingListLines_ = Form.PackingLists.FindRows(Filter);
		If PackingListLines_.Count() > 0 Then
			ArrayOfPackingListRowsToDelete.Add(PackingListLines_[0]);
		EndIf
	EndDo;
	
	For Each PackingListLineToDelete In ArrayOfPackingListRowsToDelete Do
		Form.PackingLists.Delete(PackingListLineToDelete);
	EndDo;
	
	If GoodsViewMode Then
		// In the product view mode, after deleting the goods, we delete the packing lists that have become empty.
		IterativelyRemoveEmptyPackingSheets(TSGoods);
	EndIf;
	
	// Service lines will be added for empty packing lists in the commodity places mode.
	FillInServiceDetails(Form, TSGoods, New Structure);
	RecalculateNumberOfSeats(Form, TSGoods);
	
EndProcedure

#EndRegion

#Region Private

Procedure RecursivelyAssembleArrayOfNavigationLabelLines(PackingLists, PackingList, RowsArray, Pack, DisplayHyperlinks)
	
	FoundRows = PackingLists.FindRows(New Structure("PackingList",PackingList));
	CurUpSheet = FoundRows[0];
	If DisplayHyperlinks Then
		NewRow = New FormattedString(NStr("vi = 'Phiếu đóng gói';
											|ru = 'Уп. лист';
											|en = 'Packing list'; fa = 'فهرست بسته‌بندی';
											|it = 'Distinta d''imballaggio';
											|pl = 'Ark. opakowań';
											|tr = 'Ürün listesi'") + " " + ?(Pack,"...", CurUpSheet.PackingListCode),,,,
			String(PackingList.UUID()));
	Else
		NewRow = New FormattedString(NStr("vi = 'Phiếu đóng gói';
											|ru = 'Уп. лист';
											|en = 'Packing list'; fa = 'فهرست بسته‌بندی';
											|it = 'Distinta d''imballaggio';
											|pl = 'Ark. opakowań';
											|tr = 'Ürün listesi'") + " " + ?(Pack,"...", CurUpSheet.PackingListCode));
	EndIf;
	RowsArray.Insert(0, NewRow);
	RowsArray.Insert(0, " \ ");
	
	If ValueIsFilled(CurUpSheet.PackingListParent) Then
		
		RecursivelyAssembleArrayOfNavigationLabelLines(PackingLists,
					CurUpSheet.PackingListParent, RowsArray, Pack, DisplayHyperlinks);
	EndIf;
	
EndProcedure

Procedure IterativelyRemoveEmptyPackingSheets(TSGoods)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.PackingList,
	|	GoodsTable.PackingListParent,
	|	GoodsTable.ThisIsAPackingList,
	|	GoodsTable.LineNumber
	|INTO TTProducts_1
	|FROM
	|	&GoodsTable AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.PackingList AS PackingList,
	|	TTProducts_1.LineNumber AS LineNumber
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	NOT TTProducts_1.PackingList IN
	|				(SELECT
	|					TTProducts_1.PackingListParent
	|				FROM
	|					TTProducts_1)
	|	AND TTProducts_1.ThisIsAPackingList
	|
	|GROUP BY
	|	TTProducts_1.PackingList,
	|	TTProducts_1.LineNumber
	|
	|ORDER BY
	|	LineNumber DESC";
	
	Query.SetParameter("GoodsTable", TSGoods.Unload(,"PackingList, PackingListParent,ThisIsAPackingList, LineNumber"));
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		TSGoods.Delete(Selection.LineNumber - 1);
	EndDo;
	
	IterativelyRemoveEmptyPackingSheets(TSGoods);
	
EndProcedure

Function SeriesSpecificationParameters(Form)
	
	If Form.SeriesSpecificationParameters.Property("ShippedGoods") Then
		Return Form.SeriesSpecificationParameters.ShippedGoods;
	Else
		Return Form.SeriesSpecificationParameters;
	EndIf;
	
EndFunction

Function BasisOfPackingListOnOrder(WarehouseDocument)
	
	If TypeOf(WarehouseDocument) = Type("FormDataStructure") Then
		OrderDetails_1 = WarehouseDocument;
	Else
		OrderDetails_1 = Common.ObjectAttributesValues(WarehouseDocument, "Recipient, Number");
	EndIf;
	
	Basis = NStr("vi = '%Recipient% / Đơn %Number%';
				|ru = '%Recipient% / Ордер %Number%';
				|en = '%Recipient% / Note %Number%'; fa = '%Recipient% / Note %Number%';
				|it = '%Recipient% / Ordine %Number%';
				|pl = '%Recipient% / Order %Number%';
				|tr = '%Recipient% / Emir %Number%'");
	
	Basis = StrReplace(Basis,
		"%Recipient%",
		OrderDetails_1.Recipient);
	
	Return StrReplace(Basis,
		"%Number%",
		ObjectsPrefixesClientServer.NumberForPrinting(OrderDetails_1.Number));

EndFunction

// Returns a collection of field names of the form table.
//
// Parameters:
//	NameTSGoods - String - Name of the form table.
//
// Returns:
//	Structure - a collection of form table field names containing the following properties:
//		* LineNumber - String - name of the prop on the form.
//		* GroupProductPackingList - String - name of the prop on the form.
//		* Products - String - name of the prop on the form.
//		* ProductsCode - String - name of the prop on the form.
//		* ProductsSKU - String - name of the prop on the form.
//		* ProductsUnitOfMeasure - String - name of the prop on the form.
//		* AdditionalInfoProducts - String - name of the prop on the form.
//		* Characteristic - String - name of the prop on the form.
//		* Package - String - name of the prop on the form.
//		* NumberOfPackages - String - name of the prop on the form.
//		* UpLevel - String - name of the prop on the form.
//		* PackingList - String - name of the prop on the form.
//		* PictureOfPackingList - String - name of the prop on the form.
//		* Unpack - String - name of the prop on the form.
//		* Pack - String - name of the prop on the form.
//		* AdditionalInfoPackingList - String - name of the prop on the form.
//		* PackingListParent - String - name of the prop on the form.
//		* PackingListCode - String - name of the prop on the form.
//
Function FormElementsNames(NameTSGoods)
	
	ItemsNames	= New Structure;
	ExceptionText	= "";
	
	If NameTSGoods = "Goods" Then
		
		ItemsNames.Insert("LineNumber", "GoodsLineNumber");
		ItemsNames.Insert("GroupProductPackingList", "GoodsGroupProductPackingList");
		ItemsNames.Insert("Products", "GoodsProducts");
		ItemsNames.Insert("ProductsCode", "GoodsProductsCode");
		ItemsNames.Insert("ProductsSKU", "GoodsProductsSKU");
		ItemsNames.Insert("ProductsUnitOfMeasure", "GoodsProductsUnitOfMeasure");
		ItemsNames.Insert("AdditionalInfoProducts", "ProductsAdditionalInfoNomenclature");
		ItemsNames.Insert("Characteristic", "GoodsCharacteristic");
		ItemsNames.Insert("Package", "GoodsPackage");
		ItemsNames.Insert("NumberOfPackages", "GoodsNumberOfPackages");
		ItemsNames.Insert("UpLevel", "GoodsUpLevel");
		ItemsNames.Insert("PackingList", "GoodsPackingList");
		ItemsNames.Insert("PictureOfPackingList", "ProductsPictureOfThePackingList");
		ItemsNames.Insert("Unpack", "GoodsUnpack");
		ItemsNames.Insert("Pack", "GoodsPack");
		ItemsNames.Insert("AdditionalInfoPackingList", "ProductsAdditionalInfoPackingList");
		ItemsNames.Insert("PackingListParent", "ProductsPackingListParent");
		ItemsNames.Insert("PackingListCode", "GoodsPackingListCode");
		
	ElsIf NameTSGoods = "ShippedGoods" Then
		
		ItemsNames.Insert("LineNumber", "ShippedItemsLineNumber");
		ItemsNames.Insert("GroupProductPackingList", "ShippedGoodsGroupProductPackingList");
		ItemsNames.Insert("Products", "ShippedGoodsProducts");
		ItemsNames.Insert("ProductsCode", "ShippedGoodsProductsCode");
		ItemsNames.Insert("ProductsSKU", "ShippedGoodsNomenclatureArticle");
		ItemsNames.Insert("ProductsUnitOfMeasure", "ShippedGoodsProductsUnitOfMeasure");
		ItemsNames.Insert("AdditionalInfoProducts", "ShippedGoodsAdditionalInfoNomenclature");
		ItemsNames.Insert("Characteristic", "ShippedGoodsCharacteristic");
		ItemsNames.Insert("Package", "ShippedGoodsPackage");
		ItemsNames.Insert("NumberOfPackages", "ShippedGoodsNumberOfPackages");
		ItemsNames.Insert("UpLevel", "ShippedGoodsUpLevel");
		ItemsNames.Insert("PackingList", "ShippedGoodsPackingList");
		ItemsNames.Insert("PictureOfPackingList", "ShippedGoodsPictureOfThePackingList");
		ItemsNames.Insert("Unpack", "ShippedGoodsUnpack");
		ItemsNames.Insert("Pack", "ShippedGoodsPack");
		ItemsNames.Insert("AdditionalInfoPackingList", "ShippedGoodsAdditionalInfoPackingList");
		ItemsNames.Insert("PackingListParent", "ShippedItemsPackingListParent");
		ItemsNames.Insert("PackingListCode", "ShippedGoodsPackingListCode");
		
	ElsIf IsBlankString(NameTSGoods) Then
		
		ExceptionText = NStr("vi = 'Chưa chỉ ra tên bảng.';
							|ru = 'Не указано имя таблицы.';
							|en = 'The table name is not specified.'; fa = 'The table name is not specified.';
							|it = 'Nome tabella non indicato.';
							|pl = 'Nie podano nazwy tabeli.';
							|tr = 'Tablo adı belirtilmedi.'");
		
	Else
		
		ExceptionText = StrTemplate(NStr("vi = 'Trên biểu mẫu không có bảng ""%1"".';
										|ru = 'На форме отсутствует таблица ""%1"".';
										|en = 'No ""%1"" table in the form.'; fa = 'No ""%1"" table in the form.';
										|it = 'Nel modulo manca la tabella ""%1"".';
										|pl = 'Formularz nie zawiera tabeli ""%1"".';
										|tr = 'Formda ""%1"" tablosu eksik'"), NameTSGoods);
		
	EndIf;
	
	If Not IsBlankString(ExceptionText) Then
		Raise ExceptionText;
	Else
		Return ItemsNames;
	EndIf;
	
EndFunction

#EndRegion
