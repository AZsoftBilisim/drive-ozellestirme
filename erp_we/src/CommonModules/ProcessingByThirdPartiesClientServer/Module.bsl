////////////////////////////////////////////////////////////////////////////////
// Subsystem "Processing on the side".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a business transaction by document name
//
// Parameters:
//  DocumentName - String -
//
// Returns:
//  EnumRef.BusinessTransactions - 
//
Function BusinessOperationByDocumentName(DocumentName) Export

	BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EmptyRef");
	
	If Upper(DocumentName) = Upper("TransferOfGoodsToBailee") Then
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToToller2_5");
	EndIf;

	Return BusinessOperation;

EndFunction

#Region GroupCosts2_5

// Returns a list of fields that identify the cost group.
//	Parameters:
//		GroupCosts - EnumRef.CostGroupingsInTollingOrder - type of cost grouping.
//	Returns:
//		ValueList - a list of fields identifying the cost group.
//
Function ListOfOrderCostGroupFieldsForProcessor(GroupCosts) Export
	
	FieldList = New ValueList;
	
	If GroupCosts = 
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOM") Then
		FieldList.Add("BillOfMaterials",	NStr("vi = 'Bảng kê chi tiết';
												|ru = 'Спецификация';
												|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
												|it = 'Specifica';
												|pl = 'Bill of materials';
												|tr = 'Ürün reçetesi'"));
	ElsIf GroupCosts = 
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments") Then
		FieldList.Add("BillOfMaterials",	NStr("vi = 'Bảng kê chi tiết';
												|ru = 'Спецификация';
												|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
												|it = 'Specifica';
												|pl = 'Bill of materials';
												|tr = 'Ürün reçetesi'"));
		FieldList.Add("Purpose",		NStr("vi = 'Mục đích';
											|ru = 'Назначение';
											|en = 'Assignment'; fa = 'تخصیص';
											|it = 'Assegnazione';
											|pl = 'Przeznaczenie';
											|tr = 'Atama'"));
	ElsIf GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProducts") Then
		FieldList.Add("Products",	NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Items'; fa = 'اقلام';
											|it = 'Articolo';
											|pl = 'Pozycja';
											|tr = 'Öğe'"));
		FieldList.Add("Characteristic",	NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Caratteristica';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'"));
	ElsIf GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductsAndAssignments") Then
		FieldList.Add("Products",	NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Items'; fa = 'اقلام';
											|it = 'Articolo';
											|pl = 'Pozycja';
											|tr = 'Öğe'"));
		FieldList.Add("Characteristic",	NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Caratteristica';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'"));
		FieldList.Add("Purpose",		NStr("vi = 'Mục đích';
											|ru = 'Назначение';
											|en = 'Assignment'; fa = 'تخصیص';
											|it = 'Assegnazione';
											|pl = 'Przeznaczenie';
											|tr = 'Atama'"));
	ElsIf GroupCosts =
		PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		FieldList.Add("ReferenceOrder",	NStr("vi = 'Lệnh';
												|ru = 'Распоряжение';
												|en = 'Reference'; fa = 'مرجع';
												|it = 'Disposizione';
												|pl = 'Zamówienie';
												|tr = 'Talimat'"));
	EndIf;
	
	Return FieldList;
	
EndFunction

// Returns a list of fields that identify the cost group.
//	Parameters:
//		GroupCosts - EnumRef.CostGroupingsInTollingOrder - type of cost grouping.
//	Returns:
//		ValueList - a list of fields identifying the cost group.
//
Function ListOfCostGroupFieldsInProcessorSReport(GroupCosts) Export
	
	FieldList = New ValueList;
	
	If GroupCosts = 
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOM") Then
		FieldList.Add("BillOfMaterials",	NStr("vi = 'Bảng kê chi tiết';
												|ru = 'Спецификация';
												|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
												|it = 'Specifica';
												|pl = 'Specafikacja';
												|tr = 'Ürün reçetesi'"));
	ElsIf GroupCosts = 
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments") Then
		FieldList.Add("BillOfMaterials",	NStr("vi = 'Bảng kê chi tiết';
												|ru = 'Спецификация';
												|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
												|it = 'Specifica';
												|pl = 'Specafikacja';
												|tr = 'Ürün reçetesi'"));
		FieldList.Add("Purpose",		NStr("vi = 'Mục đích';
											|ru = 'Назначение';
											|en = 'Assignment'; fa = 'تخصیص';
											|it = 'Assegnazione';
											|pl = 'Przeznaczenie';
											|tr = 'Atama'"));
	ElsIf GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProducts") Then
		FieldList.Add("Products",	NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Items'; fa = 'اقلام';
											|it = 'Articolo';
											|pl = 'Pozycja';
											|tr = 'Öğe'"));
		FieldList.Add("Characteristic",	NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Caratteristica';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'"));
		FieldList.Add("Series",			NStr("vi = 'Sê-ri';
												|ru = 'Серия';
												|en = 'Batch'; fa = 'بچ';
												|it = 'Serie';
												|pl = 'Seria';
												|tr = 'Parti'"));
	ElsIf GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductsAndAssignments") Then
		FieldList.Add("Products",	NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Items'; fa = 'اقلام';
											|it = 'Articolo';
											|pl = 'Pozycja';
											|tr = 'Öğe'"));
		FieldList.Add("Characteristic",	NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Caratteristica';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'"));
		FieldList.Add("Series",			NStr("vi = 'Sê-ri';
												|ru = 'Серия';
												|en = 'Batch'; fa = 'بچ';
												|it = 'Serie';
												|pl = 'Seria';
												|tr = 'Parti'"));
		FieldList.Add("Purpose",		NStr("vi = 'Mục đích';
											|ru = 'Назначение';
											|en = 'Assignment'; fa = 'تخصیص';
											|it = 'Assegnazione';
											|pl = 'Przeznaczenie';
											|tr = 'Atama'"));
	ElsIf GroupCosts =
		PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		FieldList.Add("ReferenceOrder",	NStr("vi = 'Lệnh';
												|ru = 'Распоряжение';
												|en = 'Reference'; fa = 'مرجع';
												|it = 'Disposizione';
												|pl = 'Zamówienie';
												|tr = 'Talimat'"));
	EndIf;
	
	Return FieldList;
	
EndFunction

// The submission cost group
// 
// Parameters:
// 	Group - Structure - description of the cost group
// 	CostGroupFields_ - ValueList - list of cost group fields
// Returns:
// 	String
Function CostGroupPresentation(Group, CostGroupFields_) Export
	
	GroupPresentation = "";
	For Each CurField In CostGroupFields_ Do
		
		CurPresentation = String(Group[CurField.Value]);
		
		If ValueIsFilled(CurPresentation) Then
			GroupPresentation = GroupPresentation + CurPresentation + " / ";
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(GroupPresentation) Then
		GroupPresentation = Left(GroupPresentation, StrLen(GroupPresentation) - 3);
	Else
		GroupPresentation = NStr("vi = '<nhóm có giá trị trống>';
								|ru = '<группа с пустыми значениями>';
								|en = '<group with empty values>'; fa = '<group with empty values>';
								|it = '<gruppo con valori vuoti>';
								|pl = '<grupa z pustymi wartościami>';
								|tr = '<boş değerli grup>'");
	EndIf;
	
	Return GroupPresentation;

EndFunction 

// Returns a string containing a list of ways to get fields that identify the cost group.
//	Parameters:
//		TableName - String - name of the source for getting fields that identify the cost group.
//		FieldList - ValueList - a list of fields identifying the cost group.
//	Returns:
//		String - a string containing a list of ways to obtain fields identifying the cost group.
//
Function RequestTextByCostGroupFields(TableName, FieldList) Export
	
	RequestTextByField = "";
	
	For Each CurField In FieldList Do
		RequestTextByField = RequestTextByField + ", " + TableName + "." + CurField.Value;
	EndDo;
	
	Return RequestTextByField;
	
EndFunction

// Returns a structure containing a list of fields that identify the cost group.
//	Parameters:
//		FieldList - ValueList - a list of fields identifying the cost group.
//	Returns:
//		Structure - a structure containing a list of fields identifying the cost group.
//
Function CostGroupSelectionStructure(FieldList) Export
	
	FilterStructure1 = New Structure;
	
	For Each CurField In FieldList Do
		FilterStructure1.Insert(CurField.Value);
	EndDo;
	
	Return FilterStructure1;
	
EndFunction

// Gets the header of the cost group field
// 
// Parameters:
// 	CostGroupFields_ - ValueList
// Returns:
// 	String
Function CostGroupFieldHeader2_5(CostGroupFields_) Export
	
	CostGroupHeader = "";
	For Each CurField In CostGroupFields_ Do
		CostGroupHeader = CostGroupHeader + CurField.Presentation + " / ";
	EndDo;
	
	If ValueIsFilled(CostGroupHeader) Then
		CostGroupHeader = Left(CostGroupHeader, StrLen(CostGroupHeader) - 3);
		CostGroupHeader = NStr("vi = 'Nhóm chi phí';
								|ru = 'Группа затрат';
								|en = 'Cost group'; fa = 'گروه بها';
								|it = 'Gruppo di spese';
								|pl = 'Grupa kosztów';
								|tr = 'Maliyet grubu'") + " (" + CostGroupHeader + ")";
	Else
		CostGroupHeader = NStr("vi = 'Nhóm chi phí';
								|ru = 'Группа затрат';
								|en = 'Cost group'; fa = 'گروه بها';
								|it = 'Gruppo di spese';
								|pl = 'Grupa kosztów';
								|tr = 'Maliyet grubu'");
	EndIf;
	
	Return CostGroupHeader;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	GroupCosts - EnumRef.CostGroupingsInTollingOrder
// Returns:
// 	String
Function CostGroupFieldHintTemplate2_5(GroupCosts) Export
	
	CostGroupHint = "";
	
	If GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProducts") Then
		CostGroupHint = NStr("vi = 'Sản phẩm liên quan %1';
							|ru = 'Продукция к которой относится %1';
							|en = 'Products that include %1'; fa = 'Products that include %1';
							|it = 'Produzione alla quale si riferisce %1';
							|pl = 'Produkcja do której należy %1';
							|tr = '%1 dahilindeki imal edilen ürünler'");
	ElsIf GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductsAndAssignments") Then
		CostGroupHint = NStr("vi = 'Sản phẩm và mục đích có liên quan %1';
							|ru = 'Продукция и назначение к которым относится %1';
							|en = 'Manufactured products and assignment to which %1 belongs'; fa = 'Manufactured products and assignment to which %1 belongs';
							|it = 'Produzione e assegnazione alle quali si riferisce %1';
							|pl = 'Produkcja i przeznaczenie do których należy %1';
							|tr = '%1 dahilindeki atama ve imal edilen ürünler'");
	ElsIf GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOM") Then
		CostGroupHint = NStr("vi = 'Bảng kê chi tiết liên quan %1';
							|ru = 'Спецификация к которой относится %1';
							|en = 'Bill of materials to which %1 belongs'; fa = 'Bill of materials to which %1 belongs';
							|it = 'Specifica alla quale si riferisce %1';
							|pl = 'Specyfikacja do której należy %1';
							|tr = '%1 dahilindeki ürün reçetesi'");
	ElsIf GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments") Then
		CostGroupHint = NStr("vi = 'Bảng kê chi tiết và mục đích có liên quan %1';
							|ru = 'Спецификация и назначение к которым относится %1';
							|en = 'Bill of materials and assignment to which %1 belongs'; fa = 'Bill of materials and assignment to which %1 belongs';
							|it = 'Specifica e assegnazione alle quali si riferisce %1';
							|pl = 'Specyfikacja i przeznaczenie do których należy %1';
							|tr = '%1 dahilindeki atama ve ürün reçetesi'");
	ElsIf GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		CostGroupHint = NStr("vi = 'Công đoạn có liên quan %1';
							|ru = 'Этап к которому относится %1';
							|en = 'Stage to which %1 is related'; fa = 'Stage to which %1 is related';
							|it = 'Fase alla quale si riferisce %1';
							|pl = 'Etap do którego należy %1';
							|tr = '%1 dahilindeki aşama'");
	EndIf;
	
	Return CostGroupHint;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function CostGroupNumberInProcessorSReport(Object, LineProducts) Export
	
	CostGroupNumber = 0;
	
	If Object.ByOrders Then
		
		FieldNameCostGroup = NameOfCostGroupFieldInProcessorReport(Object);
	
		// If the report is on an order, the cost groups can only be from the order
		// If there is only one group, then we will immediately substitute it in the current product line.
		If Object.Services.Count() = 1 Then
			CostGroupNumber = Object.Services[0][FieldNameCostGroup];
		EndIf; 
		
	Else
		
		// If the report is not on order, then filling in the group is similar to filling in the order to the processor.
		If Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProducts") Then
			
			TheStructureOfTheSearch = New Structure("Products,Characteristic,Purpose,DocumentInflow");
			TheStructureOfTheSearch.Products        = LineProducts.Products;
			TheStructureOfTheSearch.Characteristic      = LineProducts.Characteristic;
			TheStructureOfTheSearch.Purpose          = LineProducts.Purpose;
			TheStructureOfTheSearch.DocumentInflow = LineProducts.DocumentInflow;
			
			StringsList = Object.ManufacturedProduct.FindRows(TheStructureOfTheSearch);
			
			For Each RowData In StringsList Do
				If RowData.CostGroupNumber <> 0 Then
					CostGroupNumber = RowData.CostGroupNumber;
					Break;
				EndIf;
			EndDo;
			
			If CostGroupNumber = 0 Then
				Object.MaximumNumberOfCostGroup = Object.MaximumNumberOfCostGroup + 1;
				CostGroupNumber = Object.MaximumNumberOfCostGroup;
			EndIf;
			
		ElsIf Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOM") Then
			
			TheStructureOfTheSearch = New Structure("BillOfMaterials", LineProducts.BillOfMaterials);
			StringsList = Object.ManufacturedProduct.FindRows(TheStructureOfTheSearch);
			For Each RowData In StringsList Do
				If RowData.CostGroupNumber <> 0 Then
					CostGroupNumber = RowData.CostGroupNumber;
					Break;
				EndIf;
			EndDo;
			
			If CostGroupNumber = 0 Then
				Object.MaximumNumberOfCostGroup = Object.MaximumNumberOfCostGroup + 1;
				CostGroupNumber = Object.MaximumNumberOfCostGroup;
			EndIf;
			
		EndIf;
		
	EndIf; 

	Return CostGroupNumber;
	
EndFunction

Function CostGroupFieldHeader(GroupCosts, PegByProductAssignment) Export
	
	If GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProducts") Then
		
		If PegByProductAssignment Then
			GroupTitle = NStr("vi = 'Sản phẩm và mục đích';
								|ru = 'Продукция и назначение';
								|en = 'Products and purpose'; fa = 'Products and purpose';
								|it = 'Prodotti e assegnazione';
								|pl = 'Wiersze pozycji i przeznaczenie';
								|tr = 'İmal edilen ürünler ve atama'");
		Else
			GroupTitle = NStr("vi = 'Sản phẩm';
								|ru = 'Продукция';
								|en = 'Manufactured products'; fa = 'محصولات تولیدی';
								|it = 'Prodotti';
								|pl = 'Wiersze pozycji';
								|tr = 'İmal edilen ürünler'");
		EndIf;
		
	ElsIf GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOM") Then
		
		GroupTitle = NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
							|ru = 'Спецификация продукции';
							|en = 'Product BOM'; fa = 'فهرست مواد محصول (BOM)';
							|it = 'Specificazione dei prodotti';
							|pl = 'Specyfikacja produkcji';
							|tr = 'İmal edilen ürün reçetesi'");
	
	ElsIf GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		
		GroupTitle = NStr("vi = 'Công đoạn sản xuất';
							|ru = 'Этап производства';
							|en = 'Production stage'; fa = 'مرحله تولید';
							|it = 'Fase di produzione';
							|pl = 'Etap produkcji';
							|tr = 'Üretim aşaması'");
		
	EndIf;
	
	Return GroupTitle;
	
EndFunction

Function NameOfCostGroupFieldInProcessorReport(Object) Export
	
	If Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		Return "ProductionStage";
	Else
		Return "CostGroupNumber";
	EndIf;
	
EndFunction

Function NameOfCostGroupFieldInOrderToProcessor(Object) Export
	
	If Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		Return "ReferenceOrder";
	Else
		Return "CostGroupNumber";
	EndIf;
	
EndFunction

#EndRegion
