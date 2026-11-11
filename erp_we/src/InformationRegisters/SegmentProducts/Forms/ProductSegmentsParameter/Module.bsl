
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not Parameters.Property("Products") Then
		Return;
	EndIf;
	
	DoNotGenerateDynamicSegments = True;
	
	Products = Parameters.Products;
	Product_Name = Common.ObjectAttributeValue(Products, "Description");
	DetermineUseOfCharacteristics();
	Title = Title + " (" + Product_Name + ")";
	
	Items.SegmentsNumberOfCharacteristics.Visible = CharacteristicsUsed;
	Items.UpdatedAndDynamicNumberOfCharacteristics.Visible = CharacteristicsUsed;
	
	HasEditPermission = SegmentsServer.YouHaveRightToChangeCompositionOfSegments("Products");
	
	ArrayOfDependentProps = New Array;
	ArrayOfDependentProps.Add("IncludeInSegment");
	ArrayOfDependentProps.Add("RemoveFromTheSegment");
	ArrayOfDependentProps.Add("SegmentsContextMenuIncludeInSegment");
	ArrayOfDependentProps.Add("SegmentsContextMenuRemoveFromTheSegment");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfDependentProps, "Visible", HasEditPermission);
	
	FillInSegmentTable("Manual_");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesSegmentTypesOnCurrentPageChange(Item, CurrentPage)
	
	If Items.PagesSegmentTypes.CurrentPage = Items.PageUpdatableAndDynamic
		And (Not ListOfDynamicAndUpdatedSegmentsIsGenerated) Then
		
		FillInSegmentTable("UpdatedAndDynamic");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationDynamicSegmentsAreNotDisplayedURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "DisplayDynamicSegments" Then
		DoNotGenerateDynamicSegments = False;
		FillInSegmentTable("UpdatedAndDynamic");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTabularSectionName

&AtClient
Procedure SegmentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ClearMessages();
	
	If Items.PagesSegmentTypes.CurrentPage = Items.PageUpdatableAndDynamic Then
		CurrentData = Items.UpdatedAndDynamic.CurrentData;
	ElsIf Items.PagesSegmentTypes.CurrentPage = Items.PageGeneratedManually Then
		CurrentData = Items.Segments.CurrentData;
	EndIf;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "SegmentsNumberOfCharacteristics" Then
		
		If CurrentData.Characteristics.Count() = 0 Then
			CommonClientServer.MessageToUser(NStr("vi = 'Không ấn định đặc tính';
													|ru = 'Характеристики не назначены.';
													|en = 'Variants are not assigned.'; fa = 'Variants are not assigned.';
													|it = 'Caratteristiche non impostate.';
													|pl = 'Charakterystyki nie są przypisane.';
													|tr = 'Varyantlar atanmadı.'"));
			Return;
		EndIf;
		IncludeDeleteInSegmentClient(True);
		
	ElsIf Field.Name = "UpdatedAndDynamicNumberOfCharacteristics" Then
		
		If CurrentData.Characteristics.Count() = 0 Then
			CommonClientServer.MessageToUser(NStr("vi = 'Không ấn định đặc tính';
													|ru = 'Характеристики не назначены.';
													|en = 'Variants are not assigned.'; fa = 'Variants are not assigned.';
													|it = 'Caratteristiche non impostate.';
													|pl = 'Charakterystyki nie są przypisane.';
													|tr = 'Varyantlar atanmadı.'"));
			Return;
		EndIf;
	OpenForm("InformationRegister.SegmentProducts.Form.SelectItemVariant",
			New Structure("CharacteristicTable,ReadOnly",CurrentData.Characteristics,True),,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Field.Name = "SegmentsSegment" Or Field.Name = "UpdatedAndDynamicSegment"  Then
		
		ShowValue(Undefined, CurrentData.Segment);
		
	ElsIf Field.Name = "SegmentsEmployeeResponsible" Or Field.Name = "UpdatedAndDynamicEmployeeResponsible"Then
		
		ShowValue(Undefined, CurrentData.EmployeeResponsible);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IncludeInSegment(Command)
	
	IncludeDeleteInSegmentClient(True);
	
EndProcedure

&AtClient
Procedure RemoveFromTheSegment(Command)
	
	IncludeDeleteInSegmentClient(False);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	If Items.PagesSegmentTypes.CurrentPage = Items.PageGeneratedManually Then
		FillInSegmentTable("Manual_");
	Else
		FillInSegmentTable("UpdatedAndDynamic");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SegmentsNumberOfCharacteristics.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Segments.NumberOfCharacteristics");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không có>';
													|ru = '<Отсутствуют>';
													|en = '<Missing>'; fa = '<Missing>';
													|it = '<Mancanti>';
													|pl = '<Missing>';
													|tr = '<Eksik>'"));

EndProcedure

&AtServer
Procedure FillInSegmentTable(TableType)
	
	If TableType = "Manual_" Then
		
		TypeOfFormation = Enums.SegmentGenerationMethods.GenerateManually;
		TableName = "Segments";
		
	ElsIf TableType = "UpdatedAndDynamic" Then
		
		TypeOfFormation = Enums.SegmentGenerationMethods.UpdateRegularly;
		TableName = "UpdatedAndDynamic";
		
	Else
		
		Return;
		
	EndIf;
	
	ThisForm[TableName].Clear();
	
	If CharacteristicsUsed Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Products.Ref AS Products,
		|	ItemsCharacteristics.Ref AS Characteristic
		|INTO AllCharacteristicsOfProductRange
		|FROM
		|	Catalog.Products AS Products
		|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|		ON (CASE
		|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|					THEN Products.Ref
		|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|					THEN Products.ItemVariantsOwner
		|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
		|					THEN Products.ProductKind
		|				ELSE UNDEFINED
		|			END = ItemsCharacteristics.Owner)
		|WHERE
		|	Products.Ref = &Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductSegments.Ref AS Segment,
		|	ProductSegments.EmployeeResponsible AS EmployeeResponsible,
		|	AllCharacteristicsOfProductRange.Products,
		|	AllCharacteristicsOfProductRange.Characteristic
		|INTO SegmentsProductCharacteristics
		|FROM
		|	Catalog.ProductSegments AS ProductSegments
		|INNER JOIN AllCharacteristicsOfProductRange AS AllCharacteristicsOfProductRange
		|ON (TRUE)
		|WHERE
		|	NOT ProductSegments.IsFolder
		|	AND NOT ProductSegments.DeletionMark
		|	AND ProductSegments.GenerationMethod = &GenerationMethod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SegmentsProductCharacteristics.Segment AS Segment,
		|	SegmentsProductCharacteristics.EmployeeResponsible AS EmployeeResponsible,
		|	SegmentsProductCharacteristics.Characteristic,
		|	CASE
		|		WHEN SegmentProducts.Characteristic IS NULL 
		|			THEN 0
		|		ELSE 1
		|	END AS BelongsToSegment
		|FROM
		|	SegmentsProductCharacteristics AS SegmentsProductCharacteristics
		|		LEFT JOIN InformationRegister.SegmentProducts AS SegmentProducts
		|		ON SegmentsProductCharacteristics.Segment = SegmentProducts.Segment
		|			AND SegmentsProductCharacteristics.Products = SegmentProducts.Products
		|			AND SegmentsProductCharacteristics.Characteristic = SegmentProducts.Characteristic
		|TOTALS
		|	SUM(BelongsToSegment)
		|BY
		|	Segment";
		
		Query.SetParameter("Products",Products);
		Query.SetParameter("GenerationMethod",TypeOfFormation);
		
		SampleSegments = Query.Execute().Select(QueryResultIteration.ByGroups);
		
		While SampleSegments.Next() Do
			
			NewRow = ThisForm[TableName].Add();
			NewRow.Segment = SampleSegments.Segment;
			NewRow.BelongsToSegment = ?(SampleSegments.BelongsToSegment > 0, True, False);
			NewRow.NumberOfCharacteristics = SampleSegments.BelongsToSegment;
			If TableType = "UpdatedAndDynamic" Then
				NewRow.GenerationMethod = Enums.SegmentGenerationMethods.UpdateRegularly;
			EndIf;
			
			FeatureSelection_ = SampleSegments.Select();
			While FeatureSelection_.Next() Do
				
				NewRow.EmployeeResponsible = FeatureSelection_.EmployeeResponsible;
				
				If FeatureSelection_.Characteristic <> NULL Then
					
					CharacteristicTable = NewRow.Characteristics; // ValueTable 
					
					NewCharacteristic = CharacteristicTable.Add();
					NewCharacteristic.Characteristic = FeatureSelection_.Characteristic;
					NewCharacteristic.BelongsToSegment = ?(FeatureSelection_.BelongsToSegment > 0, True, False);
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	Else
		
		Query = New Query;
		Query.Text = "
		|SELECT DISTINCT
		|	ProductSegments.Ref AS Segment,
		|	CASE
		|		WHEN SegmentProducts.Products IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS BelongsToSegment,
		|	ProductSegments.EmployeeResponsible
		|FROM
		|	Catalog.ProductSegments AS ProductSegments
		|		LEFT JOIN InformationRegister.SegmentProducts AS SegmentProducts
		|		ON (SegmentProducts.Segment = ProductSegments.Ref)
		|			AND (SegmentProducts.Products = &Products)
		|WHERE
		|	(NOT ProductSegments.DeletionMark)
		|	AND (NOT ProductSegments.IsFolder)
		|	AND ProductSegments.GenerationMethod = &GenerationMethod";
		
		Query.SetParameter("Products", Products);
		Query.SetParameter("GenerationMethod",TypeOfFormation);
		
		ThisForm[TableName].Load(Query.Execute().Unload());
		
		If TableType = "UpdatedAndDynamic" Then
			
			For Each TableRow In ThisForm[TableName] Do
				TableRow.GenerationMethod = Enums.SegmentGenerationMethods.UpdateRegularly;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	If TableType = "UpdatedAndDynamic" Then
		
		FillInDataForDynamicSegments();
		
	EndIf;
	
EndProcedure 

&AtServer
Procedure FillInDataForDynamicSegments()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ProductSegments.Ref AS Segment,
	|	ProductSegments.EmployeeResponsible,
	|	ProductSegments.GenerationMethod
	|FROM
	|	Catalog.ProductSegments AS ProductSegments
	|WHERE
	|	(NOT ProductSegments.IsFolder)
	|	AND (NOT ProductSegments.DeletionMark)
	|	AND ProductSegments.GenerationMethod = VALUE(Enum.SegmentGenerationMethods.GenerateDynamically)";
	
	Selection = Query.Execute().Select();
	
	DynamicSegmentQuantity = Selection.Count();
	If DoNotGenerateDynamicSegments Then
		
		If DynamicSegmentQuantity < 5 Then
			
			DoNotGenerateDynamicSegments = False;
			Items.DecorationDynamicSegmentsAreNotDisplayed.Visible = False;
			
		Else
			
			Items.DecorationDynamicSegmentsAreNotDisplayed.Visible = True;
			
		EndIf;
		
	EndIf;
	
	If DoNotGenerateDynamicSegments Then
		ListOfDynamicAndUpdatedSegmentsIsGenerated = True;
		Return;
	EndIf;
	
	If CharacteristicsUsed Then
		
		CharacteristicTable = New ValueTable;
		CharacteristicTable.Columns.Add("Segment",New TypeDescription("CatalogRef.ProductSegments"));
		CharacteristicTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		CharacteristicTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		
	EndIf;
	
	While Selection.Next() Do
		
		If CharacteristicsUsed Then
			TableOfSegmentCharacteristics = SegmentsServer.GetProductSegmentCharacteristics(Products, Selection.Segment);
			For Each RowInSegmentCharacteristicsTable In TableOfSegmentCharacteristics Do
				
				NewRow = CharacteristicTable.Add();
				NewRow.Segment = Selection.Segment;
				NewRow.Products = RowInSegmentCharacteristicsTable.ListItem;
				NewRow.Characteristic = RowInSegmentCharacteristicsTable.ElementCharacteristics;
			
			EndDo;
			
		Else
			
			NewRow = UpdatedAndDynamic.Add();
			FillPropertyValues(NewRow,Selection);
			NewRow.BelongsToSegment = SegmentsServer.BelongsToSegment(Products, Selection.Segment);
			
		EndIf;
		
	EndDo;
	
	If CharacteristicsUsed Then
		
		Query = New Query;
		Query.Text ="
		|SELECT
		|	Products.Ref AS Products,
		|	ItemsCharacteristics.Ref AS Characteristic
		|INTO AllCharacteristicsOfProductRange
		|FROM
		|	Catalog.Products AS Products
		|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|		ON (ItemsCharacteristics.Owner = Products.Ref
		|				OR ItemsCharacteristics.Owner = Products.ProductKind)
		|WHERE
		|	Products.Ref = &Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductSegments.Ref AS Segment,
		|	ProductSegments.EmployeeResponsible AS EmployeeResponsible,
		|	AllCharacteristicsOfProductRange.Products,
		|	AllCharacteristicsOfProductRange.Characteristic
		|INTO SegmentsProductCharacteristics
		|FROM
		|	Catalog.ProductSegments AS ProductSegments,
		|	AllCharacteristicsOfProductRange AS AllCharacteristicsOfProductRange
		|WHERE
		|	(NOT ProductSegments.IsFolder)
		|	AND (NOT ProductSegments.DeletionMark)
		|	AND ProductSegments.GenerationMethod = VALUE(Enum.SegmentGenerationMethods.GenerateDynamically)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DynamicSegmentData.Segment,
		|	DynamicSegmentData.Products,
		|	DynamicSegmentData.Characteristic
		|INTO DynamicSegmentData
		|FROM
		|	&DynamicSegmentData AS DynamicSegmentData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SegmentsProductCharacteristics.Segment AS Segment,
		|	SegmentsProductCharacteristics.EmployeeResponsible AS EmployeeResponsible,
		|	SegmentsProductCharacteristics.Characteristic,
		|	CASE
		|		WHEN SegmentProducts.Characteristic IS NULL 
		|			THEN 0
		|		ELSE 1
		|	END AS BelongsToSegment
		|FROM
		|	SegmentsProductCharacteristics AS SegmentsProductCharacteristics
		|		LEFT JOIN DynamicSegmentData AS SegmentProducts
		|		ON SegmentsProductCharacteristics.Segment = SegmentProducts.Segment
		|			AND SegmentsProductCharacteristics.Products = SegmentProducts.Products
		|			AND SegmentsProductCharacteristics.Characteristic = SegmentProducts.Characteristic
		|TOTALS
		|	SUM(BelongsToSegment)
		|BY
		|	Segment";
		
		Query.SetParameter("Products",Products);
		Query.SetParameter("DynamicSegmentData",CharacteristicTable);
		SampleSegments = Query.Execute().Select(QueryResultIteration.ByGroups);
		
		While SampleSegments.Next() Do
			
			NewRow = UpdatedAndDynamic.Add();
			NewRow.Segment = SampleSegments.Segment;
			NewRow.BelongsToSegment = ?(SampleSegments.BelongsToSegment > 0, True, False);
			NewRow.NumberOfCharacteristics = SampleSegments.BelongsToSegment;
			NewRow.GenerationMethod = Enums.SegmentGenerationMethods.GenerateDynamically;
			
			FeatureSelection_ = SampleSegments.Select();
			While FeatureSelection_.Next() Do
				
				NewRow.EmployeeResponsible = FeatureSelection_.EmployeeResponsible;
				
				NewCharacteristic = NewRow.Characteristics.Add();
				NewCharacteristic.Characteristic = FeatureSelection_.Characteristic;
				NewCharacteristic.BelongsToSegment = ?(FeatureSelection_.BelongsToSegment > 0, True, False);
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	Items.DecorationDynamicSegmentsAreNotDisplayed.Visible = False;
	ListOfDynamicAndUpdatedSegmentsIsGenerated         = True;
	
EndProcedure 

&AtServer
Procedure DetermineUseOfCharacteristics()
	
	CharacteristicsUsed = False;
	
	If GetFunctionalOption("UseItemVariants") Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	ItemKinds.UseCharacteristics
		|FROM
		|	Catalog.Products AS Products
		|		INNER JOIN Catalog.ItemKinds AS ItemKinds
		|		ON Products.ProductKind = ItemKinds.Ref
		|WHERE
		|	Products.Ref = &Products";
		
		Query.SetParameter("Products",Products );
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		If Selection.UseCharacteristics Then
			
			CharacteristicsUsed = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure IncludeDeleteInSegmentClient(Enable)
	
	ClearMessages();
	SelectedRows = Items.Segments.SelectedRows;
	
	If SelectedRows = Undefined Then
		Return;
	EndIf;
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	If CharacteristicsUsed Then
		
		If Items.Segments.RowData(SelectedRows[0]).Characteristics.Count() = 0 Then
			CommonClientServer.MessageToUser(NStr("vi = 'Đối với mặt hàng này, có tiến hành ghi nhận theo đặc tính, nhưng chưa chỉ ra đặc tính nào. Không thể đưa vào phân khúc.';
													|ru = 'Для данной номенклатуры предусмотрен учет по характеристикам, но не указано ни одной характеристики. Включение в сегмент невозможно.';
													|en = 'Variant usage is enabled for the product but no variant is specified. Cannot include it in the segment.'; fa = 'Variant usage is enabled for the product but no variant is specified. Cannot include it in the segment.';
													|it = 'Per questi articoli è prevista la registrazione in base alle caratteristiche però non è stata specificata nessuna caratteristica. Impossibile includere nel segmento.';
													|pl = 'Dla podanej nomenklatury jest prowadzona ewidencja charakterystyk, ale nie podano żadnych charakterystyk. Włączenie do segmentu nie jest możliwe.';
													|tr = 'Bu ürün için varyantlar bazında muhasebe öngörüldü, ancak hiçbir varyant belirtilmedi. Segmente dahil edilmesi mümkün değildir.'"));
			Return;
		EndIf;
		
	EndIf;
	
	ArrayOfSegmentsToProcess = New Array;
	
	If CharacteristicsUsed And Enable Then
		
		CharacteristicsForChange.Clear();
		YouNeedToFillInTable = True;
		
		For Each SelectedRow In SelectedRows Do
			
			RowData = Items.Segments.RowData(SelectedRow);
			If RowData = Undefined Then
				Continue;
			EndIf;
			
			ArrayOfSegmentsToProcess.Add(RowData.Segment);
			
			If (Not RowData.BelongsToSegment) And (Not YouNeedToFillInTable) Then
				Continue;
			EndIf;
			
			If YouNeedToFillInTable Then
				
				CommonClientServer.SupplementTable(RowData.Characteristics, CharacteristicsForChange);
				YouNeedToFillInTable = False;
				
			Else
				
				For Each RowInSegmentCharacteristicsTable In RowData.Characteristics Do
				
					If RowInSegmentCharacteristicsTable.BelongsToSegment Then
						
						StructureOfSearchParameters = New Structure;
						StructureOfSearchParameters.Insert("Characteristic",RowInSegmentCharacteristicsTable.Characteristic);
						StructureOfSearchParameters.Insert("BelongsToSegment",False);
						
						FoundRows = CharacteristicsForChange.FindRows(StructureOfSearchParameters);
						If FoundRows.Count() > 0 Then
							FoundRows[0].BelongsToSegment = True;
						EndIf;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
		If ArrayOfSegmentsToProcess.Count() = 0 Then
			Return;
		EndIf;
		
		ResultTable1 = Undefined;

		
		OpenForm("InformationRegister.SegmentProducts.Form.SelectItemVariant",
			New Structure("CharacteristicTable",CharacteristicsForChange,True),,,,, New CallbackDescription("IncludeDeleteInSegmentClientCompletion", ThisObject, New Structure("ArrayOfSegmentsToProcess", ArrayOfSegmentsToProcess)), FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		For Each SelectedRow In SelectedRows Do
			
			RowData = Items.Segments.RowData(SelectedRow);
			If RowData = Undefined Then
				Continue;
			EndIf;
			
			If RowData.BelongsToSegment = Enable Then
				Continue;
			Else
				ArrayOfSegmentsToProcess.Add(RowData.Segment);
			EndIf;
			
		EndDo;
		
		If ArrayOfSegmentsToProcess.Count() > 0 Then
			
			IncludeDeleteInSegmentServer(ArrayOfSegmentsToProcess, Enable);
			Notify("IncludeDeleteInSegment", Products);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure IncludeDeleteInSegmentClientCompletion(Result, AdditionalParameters) Export
	
	ArrayOfSegmentsToProcess = AdditionalParameters.ArrayOfSegmentsToProcess;
	
	
	ResultTable1 = Result;
	
	If ResultTable1 <> Undefined Then
		
		ArrayOfProcessedCharacteristics = New Array;
		For Each TableRow In ResultTable1 Do
			
			If TableRow.BelongsToSegment Then 
				
				ArrayOfProcessedCharacteristics.Add(TableRow.Characteristic);
				
			EndIf;
			
		EndDo;
		
		WriteToSegments(ArrayOfSegmentsToProcess,ArrayOfProcessedCharacteristics);
		
		Notify("IncludeDeleteInSegment", Products);
		
	EndIf;
	
EndProcedure // Turn on the Client Segment()

&AtServer
Procedure WriteToSegments(ArrayOfSegmentsToProcess,ArrayOfProcessedCharacteristics)
	
	For Each Segment In ArrayOfSegmentsToProcess Do
		
		RecordSet = InformationRegisters.SegmentProducts.CreateRecordSet();
		RecordSet.Filter.Segment.Set(Segment);
		RecordSet.Filter.Products.Set(Products);
		
		For Each ProcessedCharacteristic In ArrayOfProcessedCharacteristics Do
			
			NewRow = RecordSet.Add();
			NewRow.Active = True;
			NewRow.Products = Products;
			NewRow.Segment = Segment;
			NewRow.Characteristic = ProcessedCharacteristic;
			
		EndDo;
		
		RecordSet.Write();
		
	EndDo;
	
	FillInSegmentTable("Manual_");
	
EndProcedure // Perform recordsegments()

&AtServer
Procedure IncludeDeleteInSegmentServer(ArrayOfSegmentsToProcess,Enable);
	
	For Each ArrayElement In ArrayOfSegmentsToProcess Do
		
		If Enable Then
			
			SegmentsServer.AddProductsToSegment(ArrayElement,Products);
			
		Else
			
			SegmentsServer.RemoveProductsFromSegment(ArrayElement,Products);
			
		EndIf;
		
	EndDo;
		
	FillInSegmentTable("Manual_");
	
EndProcedure // Turn on the Reality of the Segmentserver()

#EndRegion
