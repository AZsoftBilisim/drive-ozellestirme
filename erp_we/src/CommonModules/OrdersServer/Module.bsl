
#Region Public

// Sets the key in the table part rows
//
// Parameters:
//  Object							 - DocumentObject - Document to change
//  TabularSectionName				 - String - Name of the table part
//  PropsMaximumLineCode	 - String - Name of the object's maximum line code attribute
//  TSAttributeName					 - String - Name of the string code detail in the item's PM
//
Procedure SetKeyInRowsOfTablePart(Object,
											TabularSectionName,
											PropsMaximumLineCode = "MaximumRowCode",
											TSAttributeName = "RowCode") Export

	StringsWithoutKey = Object[TabularSectionName].FindRows(New Structure(TSAttributeName, 0));
	If StringsWithoutKey.Count() > 0 Then
		
		CurrentCode = Object[PropsMaximumLineCode];
		
		For Each LineProducts_ In StringsWithoutKey Do
			
			CurrentCode = CurrentCode + 1;
			LineProducts_[TSAttributeName] = CurrentCode;
			
		EndDo;
		
		Object[PropsMaximumLineCode] = CurrentCode;
		
	EndIf;

EndProcedure

// Gets the minimum shipment date for unformed order lines. Used in the fill-in processing event
// to fill in the document date.
//
// Parameters:
//  OrderOrArrayOfOrders - DocumentRef - the order to receive the shipment date for.
//  RegisterName - String - Name of the accumulation register that contains information about unformed order lines.
//  OrderName - String - Name of the dimension of the accumulation register that contains the order.
//
// Returns:
//  Date - Minimum date of shipment for unformulated order lines.
Function GetMinimumOrderShipmentDate(OrderOrArrayOfOrders, RegisterName = "ShipmentAndReturnReferences", OrderName = "ReferenceOrder") Export

	Result = Undefined;

	Query = New Query();
	If RegisterName = "AssemblyOrders" Then

		Query.Text =
			"SELECT TOP 1
			|	RequirementsForRegistration__.Period AS Period
			|FROM
			|	AccumulationRegister.AssemblyOrders.Balance(, ByAssemblyDisassemblyOrder IN(&AnArrayOfOrders)) AS Filter
			|
			|		INNER JOIN AccumulationRegister.AssemblyOrders AS RequirementsForRegistration__
			|		ON Filter.ByAssemblyDisassemblyOrder = RequirementsForRegistration__.ByAssemblyDisassemblyOrder
			|		 AND Filter.RowCode     = RequirementsForRegistration__.RowCode
			|		 AND Filter.ToRegisterBalance > 0
			|		 AND RequirementsForRegistration__.ToRegister > 0
			|		 AND RequirementsForRegistration__.RecordType = VALUE(AccumulationRecordType.Receipt)
			|		 AND RequirementsForRegistration__.Active
			|		 AND Filter.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment)
			|		 AND RequirementsForRegistration__.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment)
			|
			|ORDER BY
			|	Period";

	ElsIf RegisterName = "ShipmentAndReturnReferences" Then
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (&AnArrayOfOrders)";
		TableFormationParameters.Group = "ReferenceOrder, RowCode";
		TableFormationParameters.Indicators = "ToRegister, Issued_1";
		TableFormationParameters.Resources = "Count";
		TableFormationParameters.Indexes = TableFormationParameters.Group;
		TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
		
		TT_ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = TT_ShipmentOrdersTurnoverExpanded +
			Common.QueryBatchSeparator() + "
			|SELECT TOP 1
			|	RequirementsForRegistration__.Period AS Period
			|FROM
			|	TT_ShipmentOrdersTurnoverExpanded AS Filter
			|		INNER JOIN AccumulationRegister.ShipmentAndReturnReferences AS RequirementsForRegistration__
			|		ON Filter.ReferenceOrder = RequirementsForRegistration__.ReferenceOrder
			|			AND Filter.RowCode = RequirementsForRegistration__.RowCode
			|			AND (Filter.ForRegistrationQuantityTurnover
			|				- Filter.IssuedQuantityTurnover) > 0
			|			AND RequirementsForRegistration__.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
			|			AND RequirementsForRegistration__.Count > 0
			|			AND RequirementsForRegistration__.Active
			|
			|ORDER BY
			|	Period";
		
	Else
		
		Query.Text =
			"SELECT TOP 1
			|	RequirementsForRegistration__.Period AS Period
			|FROM
			|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder IN(&AnArrayOfOrders)) AS Filter
			|
			|		INNER JOIN AccumulationRegister.PurchaseOrders AS RequirementsForRegistration__
			|		ON Filter.PurchaseOrder = RequirementsForRegistration__.PurchaseOrder
			|		 AND Filter.RowCode    = RequirementsForRegistration__.RowCode
			|		 AND Filter.ToRegisterBalance > 0
			|		 AND RequirementsForRegistration__.RecordType = VALUE(AccumulationRecordType.Receipt)
			|		 AND RequirementsForRegistration__.ToRegister > 0
			|		 AND RequirementsForRegistration__.Active
			|
			|ORDER BY
			|	Period";
		
		Query.Text = StrReplace(Query.Text, "PurchaseOrders", RegisterName);
		Query.Text = StrReplace(Query.Text, "PurchaseOrder", OrderName);
		
	EndIf;

	Query.SetParameter("AnArrayOfOrders", OrderOrArrayOfOrders);

	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();

	If Selection.Next() Then
		Result = Max(CurrentSessionDate(), Selection.Period);
	EndIf;

	Return Result;

EndFunction

// Gets the minimum Document shipment date. 
//
// Parameters:
//  Object - DocumentObject - Client's order, Client's requestcountry return.
//  TabularSectionName - String - Name of the table part. The default value is "Products".
//
// Returns:
//  Date - Minimum date of shipment of the document.
Function GetMinimumDateOfShipmentOfObject(Object, TabularSectionName = "Goods") Export

	ScheduledShipmentDate = Object.Date;
	If Object.NotShipInInstallments Then
		ScheduledShipmentDate = ?(ValueIsFilled(Object.DateOfShipment), Object.DateOfShipment, Object.Date); 
	Else
		TableOfDates = Object[TabularSectionName].Unload(,"DateOfShipment");
		If TableOfDates.Count() > 0 Then
			TableOfDates.Sort("DateOfShipment Asc"); 
			DateOfShipment = TableOfDates[0].DateOfShipment;
			If ValueIsFilled(DateOfShipment) Then
				ScheduledShipmentDate = DateOfShipment; 
			EndIf;
		EndIf;
	EndIf;
	
	Return ScheduledShipmentDate;

EndFunction

// Gets the maximum shipment date for unformed order lines. Used in the fill-in processing event
// to fill in the document date.
//
// Parameters:
//  OrderOrArrayOfOrders - DocumentRef - the order to receive the shipment date for.
//  RegisterName - String - Name of the accumulation register that contains information about unformed order lines.
//  OrderName - String - Name of the dimension of the accumulation register that contains the order.
//
// Returns:
//  Date - The maximum date of shipment for unformulated order lines.
Function GetMaximumOrderShipmentDate(OrderOrArrayOfOrders, RegisterName = "ShipmentAndReturnReferences", OrderName = "ReferenceOrder") Export

	Result = Undefined;

	Query = New Query();
	If RegisterName = "AssemblyOrders" Then
		
		Query.Text =
			"SELECT TOP 1
			|	RequirementsForRegistration__.Period AS Period
			|FROM
			|	AccumulationRegister.AssemblyOrders.Balance(, ByAssemblyDisassemblyOrder IN(&AnArrayOfOrders)) AS Filter
			|
			|		INNER JOIN AccumulationRegister.AssemblyOrders AS RequirementsForRegistration__
			|		ON Filter.ByAssemblyDisassemblyOrder = RequirementsForRegistration__.ByAssemblyDisassemblyOrder
			|		 AND Filter.RowCode     = RequirementsForRegistration__.RowCode
			|		 AND Filter.ToRegisterBalance > 0
			|		 AND RequirementsForRegistration__.RecordType = VALUE(AccumulationRecordType.Receipt)
			|		 AND RequirementsForRegistration__.ToRegister > 0
			|		 AND RequirementsForRegistration__.Active
			|		 AND Filter.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment)
			|		 AND RequirementsForRegistration__.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment)
			|
			|ORDER BY
			|	Period DESC";

	ElsIf RegisterName = "ShipmentAndReturnReferences" Then
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (&AnArrayOfOrders)";
		TableFormationParameters.Group = "ReferenceOrder, RowCode";
		TableFormationParameters.Indicators = "ToRegister, Issued_1";
		TableFormationParameters.Resources = "Count";
		TableFormationParameters.Indexes = TableFormationParameters.Group;
		TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
		
		TT_ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = TT_ShipmentOrdersTurnoverExpanded +
			Common.QueryBatchSeparator() + "
			|SELECT TOP 1
			|	RequirementsForRegistration__.Period AS Period
			|FROM
			|	TT_ShipmentOrdersTurnoverExpanded AS Filter
			|		INNER JOIN AccumulationRegister.ShipmentAndReturnReferences AS RequirementsForRegistration__
			|		ON Filter.ReferenceOrder = RequirementsForRegistration__.ReferenceOrder
			|			AND Filter.RowCode = RequirementsForRegistration__.RowCode
			|			AND (Filter.ForRegistrationQuantityTurnover
			|				- Filter.IssuedQuantityTurnover) > 0
			|			AND RequirementsForRegistration__.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
			|			AND RequirementsForRegistration__.Count > 0
			|			AND RequirementsForRegistration__.Active
			|
			|ORDER BY
			|	Period DESC";
		
	Else
	
		Query.Text =
			"SELECT TOP 1
			|	RequirementsForRegistration__.Period AS Period
			|FROM
			|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder IN(&AnArrayOfOrders)) AS Filter
			|
			|		INNER JOIN AccumulationRegister.PurchaseOrders AS RequirementsForRegistration__
			|		ON Filter.PurchaseOrder = RequirementsForRegistration__.PurchaseOrder
			|		 AND Filter.RowCode    = RequirementsForRegistration__.RowCode
			|		 AND Filter.ToRegisterBalance > 0
			|		 AND RequirementsForRegistration__.RecordType = VALUE(AccumulationRecordType.Receipt)
			|		 AND RequirementsForRegistration__.ToRegister > 0
			|		 AND RequirementsForRegistration__.Active
			|
			|ORDER BY
			|	Period DESC";

		Query.Text = StrReplace(Query.Text, "PurchaseOrders", RegisterName);
		Query.Text = StrReplace(Query.Text, "PurchaseOrder", OrderName);

	EndIf;

	Query.SetParameter("AnArrayOfOrders", OrderOrArrayOfOrders);

	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();

	If Selection.Next() And Selection.Period >= BegOfDay(CurrentSessionDate()) Then
		Result = Selection.Period;
	EndIf;

	Return Result;

EndFunction

// Function-constructor of parameters for updating information on orders in the form
//
// Returns:
// Structure - The structure of parameters for determining the account:
//      * PropsNameOrderList         - String - The Name of the Attribute of the form containing the list of orders, for example, "List of orders".
//      * OrderPathInHeader                  - String - The path to the header order, for example, to call from the document form "Object.Customer Order",
//                                                     or "Customer Order" for a call from the matching form.
//      * TitleLabelName               - String - The Name of the Attribute of the form for displaying the inscription "Total orders" or "Order
//                                                     ...".
//      * NameOfColumnGroupInTableSection   - String - The name of the column group of the customer's order and the line code
//                                                          in the document TS for setting the grouping.
//      * OrderNameInTablePart          - String - The name of the TS column with orders (for example, "Customer's order").
//      * UseOrdersInTabularSection - Boolean - The value of the use multiple orders function option.
//      * LabelTotalOrders               - String - Optional, the prefix of the order label.
//      * OrdersUse                - Undefined, Boolean - orders are used.
//
Function ParametersForUpdatingOrderInformationInForm() Export
	
	ParametersOfUpdate = New Structure();
	ParametersOfUpdate.Insert("PropsNameOrderList");
	ParametersOfUpdate.Insert("OrderPathInHeader");
	ParametersOfUpdate.Insert("TitleLabelName");
	ParametersOfUpdate.Insert("NameOfColumnGroupInTableSection");
	ParametersOfUpdate.Insert("OrderNameInTablePart");
	ParametersOfUpdate.Insert("UseOrdersInTabularSection");
	ParametersOfUpdate.Insert("LabelTotalOrders", Undefined);
	ParametersOfUpdate.Insert("OrdersUse", Undefined);
	
	Return ParametersOfUpdate;
	
EndFunction

// Updates information about orders in the form
//
// Parameters:
// 	 Form - ClientApplicationForm - form for updating order information
// 	 TabularSection - FormDataCollection - Table of values, the Table part used to fill in the list of orders.
// 	 ParametersOfUpdate - See OrdersServer.ParametersForUpdatingOrderInformationInForm
//
Procedure UpdateOrderInformationInForm(Form, TabularSection, ParametersOfUpdate) Export
	
	FormItems                     = Form.Items;
	OrderList                     = Form[ParametersOfUpdate.PropsNameOrderList];
	
	OrderInHeader                       = CommonClientServer.GetFormAttributeByPath(Form, ParametersOfUpdate.OrderPathInHeader);
	GroupOfColumnsInTablePart      = ?(ParametersOfUpdate.NameOfColumnGroupInTableSection = Undefined, Undefined, Form.Items[ParametersOfUpdate.NameOfColumnGroupInTableSection]);
	
	OrderNameInTablePart          = ParametersOfUpdate.OrderNameInTablePart;
	UseOrdersInTabularSection = ParametersOfUpdate.UseOrdersInTabularSection;
	LabelTotalOrders               = ParametersOfUpdate.LabelTotalOrders;
	
	If ParametersOfUpdate.OrdersUse <> Undefined Then
		If Not ParametersOfUpdate.OrdersUse Then
			If ValueIsFilled(OrderInHeader) Then
				FormItems.PagesOrder.Enabled = False;
			Else
				FormItems.PagesOrder.Visible = False;
			EndIf;
			If Not GroupOfColumnsInTablePart = Undefined Then
				GroupOfColumnsInTablePart.Visible = False;
			EndIf;
		Else
			FormItems.PagesOrder.Visible = True;
			FormItems.PagesOrder.Enabled = True;
		EndIf;
	EndIf;
	
	If Not UseOrdersInTabularSection Then
		Return;
	EndIf;
		
	OrderList.Clear();
	InAllRowsThereIsOrder = True;
	For Each CurRow In TabularSection Do
		If ValueIsFilled(CurRow[OrderNameInTablePart]) Then
			If  OrderList.FindByValue(CurRow[OrderNameInTablePart]) = Undefined Then
				OrderList.Add(CurRow[OrderNameInTablePart]);
			EndIf;
		Else
			InAllRowsThereIsOrder = False;
		EndIf;
	EndDo;
	
	If OrderList.Count() = 1 And InAllRowsThereIsOrder Then
		CommonClientServer.SetFormAttributeByPath(Form,ParametersOfUpdate.OrderPathInHeader,OrderList[0].Value);
	ElsIf OrderList.Count() > 1 Or Not InAllRowsThereIsOrder Then
		CommonClientServer.SetFormAttributeByPath(Form,ParametersOfUpdate.OrderPathInHeader,Undefined);
	EndIf;
	OrderInHeader = CommonClientServer.GetFormAttributeByPath(Form, ParametersOfUpdate.OrderPathInHeader); 
	
	If OrderList.Count() > 1 Then
		If LabelTotalOrders = Undefined Then
			LabelTotalOrders = NStr("vi = 'Tất cả đơn hàng';
									|ru = 'Всего заказов';
									|en = 'Total orders'; fa = 'Total orders';
									|it = 'Ordini in tutto';
									|pl = 'Łącznie zamówień';
									|tr = 'Toplam siparişler'");
		EndIf;
		Form[ParametersOfUpdate.TitleLabelName] = LabelTotalOrders + ": " + OrderList.Count();
	EndIf;
	
	If OrderList.Count() <= 1 Then
		FormItems.PagesOrder.CurrentPage = FormItems.PageOrder;
	Else
		FormItems.PagesOrder.CurrentPage = FormItems.OrdersPage;
		If ParametersOfUpdate.OrdersUse <> Undefined Then
			If Not ParametersOfUpdate.OrdersUse Then
				FormItems.PagesOrder.Visible = True;
				FormItems.OrdersPage.Enabled = False;
			Else
				FormItems.OrdersPage.Enabled = True;
			EndIf;
		EndIf;
	EndIf;
	
	If GroupOfColumnsInTablePart <> Undefined Then
		If ValueIsFilled(OrderInHeader) Or Not UseOrdersInTabularSection Then
			GroupOfColumnsInTablePart.Group = ColumnsGroup.Vertical;
		Else
			GroupOfColumnsInTablePart.Group = ColumnsGroup.InCell;
		EndIf;
	EndIf; 
	
EndProcedure

// Fills in an order in the invoice header if only one order is specified in the table part.
//
// Parameters:
//  OrderInHeader - DocumentRef - the field to fill in.
//  TabularSection - TabularSection - table part of the invoice for which you need to fill out the order in the header.
//  OrderNameInTablePart - String - the name of the detail in the table part where the link to the order is stored.
//
Procedure FillInOrderInOrderHeaderInTableSection(OrderInHeader, Val TabularSection, Val OrderNameInTablePart) Export
	
	// We will fill in the order in the header if one order is specified in the table part
	TablePartOrders = TabularSection.Unload(,OrderNameInTablePart);
	TablePartOrders.GroupBy(OrderNameInTablePart);
	
	If TablePartOrders.Count() = 1 Then
		LineOfATabularSection = TablePartOrders[0];
		If ValueIsFilled(LineOfATabularSection[OrderNameInTablePart]) Then
			OrderInHeader = LineOfATabularSection[OrderNameInTablePart];
		EndIf;
	EndIf;

EndProcedure

// Fills in the details of the caps according to table parts
//
// Parameters:
//  MatchingBankDetails	- Map - Matching cap details and table parts details (key-cap details, value-PM details)
//  TabularSections			- String - A list of table parts of which you need to get the values
//  Object					- DocumentObject, FormDataStructure - The object where you need to fill in the details.
//
Procedure FillInHeaderDetailsByTableParts(MatchingBankDetails, TabularSections, Object) Export

	ListOfTS = StrSplit(TabularSections, ",");
	
	For Each KeyAndValue In MatchingBankDetails Do
		
		ValuesCount = 0;
		AttributeValue = Undefined;
		
		For Each TSName In ListOfTS Do
			
			For Each RowData In Object[TSName] Do
				
				If Not ValueIsFilled(RowData[KeyAndValue.Value]) Then
					Continue;
				EndIf;
				
				If RowData[KeyAndValue.Value] <> AttributeValue Then
					ValuesCount = ValuesCount + 1;
				EndIf;
				AttributeValue = RowData[KeyAndValue.Value];
				If ValuesCount > 1 Then
					Break;
				EndIf;
				
			EndDo;
			
			If ValuesCount > 1 Then
				Break;
			EndIf;
			
		EndDo;
		
		If ValuesCount <> 1 Then
			TypesArray = New Array;
			TypesArray.Add(TypeOf(Object[KeyAndValue.Key]));
			AttributeType = New TypeDescription(TypesArray);
			AttributeValue = AttributeType.AdjustValue();
		EndIf; 
		
		Object[KeyAndValue.Key] = AttributeValue;
		
	EndDo;
	
EndProcedure

// Sets whether a line is present in the document relative to the order by line codes.
//
// Parameters:
//  GoodsTable            - ValueTable - the table where you want to set the attribute.
//  OrderNameInTablePart - String - name of the Order detail in the table for matching.
//  ArrayOfStringCodes         - Array - codes of the order lines that are being matched.
//  PropsNameLineCode    - String - name of the order string detail In the table for matching.
//
Procedure SetSignsOfPresenceOfLineInDocument(GoodsTable, OrderNameInTablePart, ArrayOfStringCodes, PropsNameLineCode = "RowCode") Export

	For Each TabRow In GoodsTable Do
	
		TabRow.ExistsInTheDocument = False;
		
		For Each CurRow In ArrayOfStringCodes Do
			
			If CurRow[PropsNameLineCode] = TabRow[PropsNameLineCode] 
				And CurRow[OrderNameInTablePart] = TabRow[OrderNameInTablePart] Then
				
				TabRow.ExistsInTheDocument = True;
				Break;
				
			EndIf;
			
		EndDo;
		
		TabRow.RowIsSelected = Not TabRow.ExistsInTheDocument;
		
	EndDo;
	
EndProcedure

// Sets the conditional design of the canceled PM line in the Order form
// Parameters:
//	ConditionalAppearance - DataCompositionConditionalAppearance - conditional form design;
//	FormTable - FormTable - element of the form associated with the PM in which lines are canceled;
//	TagNameCanceled - String - name of the form element associated with the order line cancellation attribute;
//	ElementNameReasonForCancellation - String - name of the form element associated with the reason for canceling the order line.
//	NameOfPriceInputField - String - name of the form element associated with the price entry field
//	NameOfAmountInputField - String - name of the form element associated with the amount input field
//
Procedure SetAppearanceOfCanceledLine(ConditionalAppearance, FormTable, TagNameCanceled, ElementNameReasonForCancellation = "", NameOfPriceInputField = "", NameOfAmountInputField = "") Export
	
	Item = ConditionalAppearance.Items.Add();
	KTCHPath = FormTable.DataPath;
	
	ExcludingFields = New Array;
	ExcludingFields.Add(TagNameCanceled);
	If ValueIsFilled(ElementNameReasonForCancellation) Then
		ExcludingFields.Add(ElementNameReasonForCancellation);
	EndIf;
	TMCommonUse.FillInConditionalAppearanceFieldsRecursively(Item.Fields, FormTable.ChildItems, ExcludingFields);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(KTCHPath + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
	
	If ValueIsFilled(ElementNameReasonForCancellation) Then
	
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(ElementNameReasonForCancellation);
		
		FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(KTCHPath + ".CancellationReason");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(KTCHPath + ".Canceled");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(ElementNameReasonForCancellation);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(KTCHPath + ".Canceled");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
	EndIf;
	
	If ValueIsFilled(NameOfPriceInputField) Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(NameOfPriceInputField);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(KTCHPath + ".Canceled");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
	EndIf;
	
	If ValueIsFilled(NameOfAmountInputField) Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(NameOfAmountInputField);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(KTCHPath + ".Canceled");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
	EndIf;
	
EndProcedure

Procedure CheckDuplicatesOfRowCodesInTable(DocumentObject, RowCode, LineNumber, MatchingLineCodes, Cancel, TSName = Undefined) Export
	If TSName = Undefined Then
		TSName = "Goods";
	EndIf;
	
	If ValueIsFilled(RowCode) Then
		If MatchingLineCodes[RowCode] = Undefined Then
			MatchingLineCodes.Insert(RowCode, LineNumber);
		Else
			DoubleLineNumber = MatchingLineCodes[RowCode];
			ErrorText = NStr("vi = 'Trùng lặp giá trị mục tin ""Mã dòng"" tại dòng %1 và dòng %2 của đơn hàng.
				|Chứng từ đã lập không chính xác.';
				|ru = 'Дублируется значение реквизита ""Код строки"" строки %1 и строки %2 заказа.
				|Документ создан некорректно.';
				|en = 'The ""Line code"" attribute value of line %1 and line %2 of the order has a duplicate.
				|The document was created incorrectly.'; fa = 'The ""Line code"" attribute value of line %1 and line %2 of the order has a duplicate.
				|The document was created incorrectly.';
				|it = 'Duplicazione del valore del requisito ""Codice riga"" della riga %1 e %2 dell''ordine.
				| Il documento non è stato creato correttamente.';
				|pl = 'Dubluje się wartość atrybutu ""Kod wiersza"" wiersza %1 i wiersza %2 zamówienia.
				|Dokument jest utworzony niepoprawnie.';
				|tr = 'Siparişin %1 ve %2 satırının ""Satır kodu"" özniteliğinin değeri tekrarlanıyor.
				|Belge hatalı oluşturuldu.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, DoubleLineNumber, LineNumber); 
			CommonClientServer.MessageToUser(
				ErrorText,
				DocumentObject,
				CommonClientServer.PathToTabularSection(TSName, LineNumber, "RowCode"),
				,
				Cancel);
				
		EndIf;
	EndIf;
	
EndProcedure

#Region FillType

// Fills in the service details "Divergence of orders" in the line
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed row
//  FillParameters  - See OrdersClientServer.FillInParametersFlagDiscrepancyOrder
//  CachedValues - Structure - stored values of parameters used in processing
//
Procedure FillInDiscrepancyAttributeOrder(CurrentRow, FillParameters, CachedValues) Export

	If Not FillParameters.ByOrders Then
		Return;
	EndIf;

	CurrentRow.OrderDiscrepancy_3 = ?(CurrentRow.RowCode = 0, 1, 0);
	
EndProcedure

// Fills in the "Order divergence" flag in the rows of the table
// 
//	Parameters:
//   FillParameters  - See OrdersClientServer.FillInParametersFlagDiscrepancyOrder
//	 Table              - FormDataCollection - table being processed
//	 Rows               - Array, Undefined - array of processed strings
//  
Procedure FillInDiscrepancyOrderAttributeInTable(FillParameters, Table, Rows = Undefined) Export
	
	If Not FillParameters.ByOrders Or Table.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	Table.LineNumber      AS LineNumber,
	|	Table.RowCode        AS RowCode,
	|	Table.OrderDiscrepancy_3 AS OrderDiscrepancy_3
	|INTO Table
	|FROM
	|	&Table AS Table
	|
	|INDEX BY
	|	RowCode,
	|	OrderDiscrepancy_3
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	CASE
	|		WHEN RowCode = 0
	|			THEN 1
	|		ELSE 0
	|	END               AS OrderDiscrepancy_3
	|FROM
	|	Table AS Table
	|WHERE
	|	Table.RowCode = 0 AND Table.OrderDiscrepancy_3 = 0
	|	OR
	|	Table.RowCode <> 0 AND Table.OrderDiscrepancy_3 <> 0
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Table", Table.Unload(Rows, "LineNumber, RowCode, OrderDiscrepancy_3"));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		FillPropertyValues(Table[Selection.LineNumber - 1], Selection,, "LineNumber");
	EndDo;
	
EndProcedure

// Unlinds rows in the table from orders, resetting the value of the "Code String" props to 0
//
//	Parameters:
//   FillParameters - See OrdersClientServer.FillInParametersFlagDiscrepancyOrder
//	 Table             - FormDataCollection - table being processed
//	 Rows              - Array, Undefined - array of processed strings
//  
Procedure UntieRowsFromOrders(FillParameters, Table, Rows = Undefined) Export
	
	If Table.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	Table.LineNumber      AS LineNumber,
	|	Table.RowCode        AS RowCode,
	|	Table.OrderDiscrepancy_3 AS OrderDiscrepancy_3
	|INTO Table
	|FROM
	|	&Table AS Table
	|
	|INDEX BY
	|	RowCode
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	0                   AS RowCode,
	|	&OrderDiscrepancy_3   AS OrderDiscrepancy_3
	|FROM
	|	Table AS Table
	|WHERE
	|	NOT Table.RowCode = 0 OR Table.OrderDiscrepancy_3 = 0
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Table", Table.Unload(Rows, "LineNumber, RowCode, OrderDiscrepancy_3"));
	Query.SetParameter("OrderDiscrepancy_3", ?(FillParameters.ByOrders, 1, 0));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		FillPropertyValues(Table[Selection.LineNumber - 1], Selection,, "LineNumber");
	EndDo;
	
EndProcedure

#EndRegion

#Region CancelUnfulfilledLines

// Constructor function for the order line adjustment structure
//
// Returns:
//  Structure - Structure of parameters for adjusting order lines:
//      * DocumentObject - DocumentObject - The order in which you want to adjust the lines.
//      * DocumentName                    - String - Name of the order (metadata object).
//      * TabularSectionName               - String - Name of the table part of the order.
//      * CancellationReason                   - CatalogRef.ReasonsForSaleOrderCancellation, CatalogRef.ReasonsForPurchaseOrderCancellation - The reason for the cancellation of order lines.
//      * CheckBalance                - Boolean - If you want to check out the remains when adjusting lines.
//      * CancelUnprocessedLines    - Boolean - Order lines that have not been issued an invoice and have not
//                                                   been accepted/shipped will be canceled.
//      * CorrectMeasuringGoods     - Boolean - Order lines that
//                                                   have not been issued an invoice or accepted/shipped within the acceptable deviation will be
//                                                   canceled. Order lines for which more items were accepted/shipped and
//                                                   processed than in the order within the acceptable
//                                                   deviation will be increased.
//      * AdjustTheMeasuredGoodsUponAcceptance - Boolean - the same as adjusting the size of the Goods, but applies if the document has
//                                                   there is a separate table part focused on acceptance.
//      * CorrectPrices             - Boolean - The order prices will be converted to the invoice prices.
//      * CloseOrders                 - Boolean - Whether to attempt to set the Closed status for the order.
//
Function OrderLineAdjustmentStructure() Export
	
	Structure = New Structure;
	Structure.Insert("DocumentObject");
	Structure.Insert("DocumentName");
	Structure.Insert("TabularSectionName",                    "Goods");
	Structure.Insert("CancellationReason");
	Structure.Insert("CheckBalance",                     False);
	Structure.Insert("CancelUnprocessedLines",         False);
	Structure.Insert("CorrectMeasuringGoods",          False);
	Structure.Insert("AdjustTheMeasuredGoodsUponAcceptance", False);
	Structure.Insert("CorrectPrices",                  False);
	Structure.Insert("CloseOrders",                      False);
	
	Return Structure;
	
EndFunction

// Returns:
// 	Structure - Content:
// * RegisterManager  - AccumulationRegisterManager
// * FilterByDimensions - Structure
// * TabularSectionName - String
// * DataPaths       - Structure
// * ReplacementTable      - Undefined
//
Function FillOptionsForCancelingRows() Export
	
	FillParameters = New Structure;
	FillParameters.Insert("RegisterManager",  Undefined);
	FillParameters.Insert("FilterByDimensions", New Structure);
	FillParameters.Insert("TabularSectionName", "Goods");
	FillParameters.Insert("DataPaths",       New Structure);
	FillParameters.Insert("ReplacementTable",      Undefined);
	
	Return FillParameters;
	
EndFunction

// Returns:
// 	Structure - Content:
// * FieldNameReasonForCancellation        - String
// * CancellationReason               - Undefined
// * DeleteRows_1               - Boolean
// * AdjustAmount         - Boolean
// * CancelOnlyMeasuredGoods  - Boolean
// * CorrectMeasuringGoods - Boolean
//
Function OptionsForCancelingOrderLines() Export
	
	CancellationOptions = New Structure;
	CancellationOptions.Insert("FieldNameReasonForCancellation",        "CancellationReason");
	CancellationOptions.Insert("CancellationReason",               Undefined);
	CancellationOptions.Insert("DeleteRows_1",               False);
	CancellationOptions.Insert("AdjustAmount",         False);
	CancellationOptions.Insert("CancelOnlyMeasuredGoods",  False);
	CancellationOptions.Insert("CorrectMeasuringGoods", False);
	
	Return CancellationOptions;
	
EndFunction

// Depending on the order type, it calls the line adjustment procedure and the order post-processing procedure.
//
// Parameters:
//  OrderObject                       - DocumentObject - The corrected order.
//  StructureOfAdditionalParameters - Structure - Structure of order line adjustments.
// 
// Returns:
//  Boolean - To adjust order line
Function AdjustOrderLines(OrderObject, StructureOfAdditionalParameters) Export
	
	OrderLineAdjustmentStructure = OrdersServer.OrderLineAdjustmentStructure();
	FillPropertyValues(OrderLineAdjustmentStructure, StructureOfAdditionalParameters);
	
	OrderChanged = False;
	
	If TypeOf(OrderObject) = Type("DocumentObject.SalesOrder") Then
		
		OrderLineAdjustmentStructure.DocumentObject   = OrderObject;
		OrderLineAdjustmentStructure.CheckBalance = 
			Not (OrderObject.Status = Enums.SalesOrderStatuses.NotApproved);
		
		ResultStructure1 = SalesServer.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If ResultStructure1.RowsCount <> 0 Or ResultStructure1.AdjustmentSum > 0 Then
			
			OrderChanged = True;
			
			PaymentStepsServer.CheckAndFillInPaymentScheduleStages(OrderObject);
			
		EndIf;
		
	ElsIf TypeOf(OrderObject) = Type("DocumentObject.PurchaseOrder") Then
		
		OrderLineAdjustmentStructure.CheckBalance = 
			Not (OrderObject.Status = Enums.PurchaseOrderStatuses.NotApproved);
		
		ResultStructure1 = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If ResultStructure1.RowsCount <> 0 Then
			
			OrderChanged = True;
			
			PaymentStepsServer.CheckAndFillInPaymentScheduleStages(OrderObject);
			
		EndIf;
		
	ElsIf TypeOf(OrderObject) = Type("DocumentObject.RequestForReturnOfGoodsFromCustomer") Then
		
		OrderLineAdjustmentStructure.DocumentObject   = OrderObject;
		OrderLineAdjustmentStructure.CheckBalance = True;
		
		// Returned goods
		OrderLineAdjustmentStructure.TabularSectionName = "ReturnedGoods";
		TTResultStructure = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		// Replacement products
		OrderLineAdjustmentStructure.TabularSectionName = "SubstituteGoods";
		StructureOfZTResult = SalesServer.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If StructureOfZTResult.RowsCount > 0 Or StructureOfZTResult.AdjustmentSum > 0 Then
			OrderChanged = True;
			
			PaymentStepsServer.CheckAndFillInPaymentScheduleStages(OrderObject);
		EndIf;
		
		If TTResultStructure.RowsCount > 0 Then
			OrderChanged = True;
		EndIf;
		
	ElsIf TypeOf(OrderObject) = Type("DocumentObject.InventoryConsumptionOrder") Then
		
		OrderLineAdjustmentStructure.CheckBalance = 
			OrderObject.Status <> Enums.InternalOrderStatuses.AwaitingApproval;
		
		ResultStructure1 = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If ResultStructure1.RowsCount > 0 Then
			OrderChanged = True;
		EndIf;
		
	ElsIf TypeOf(OrderObject) = Type("DocumentObject.ByAssemblyDisassemblyOrder") Then
		
		OrderLineAdjustmentStructure.CheckBalance = True;
		
		ResultStructure1 = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If ResultStructure1.RowsCount > 0 Then
			OrderChanged = True;
		EndIf;
		
	ElsIf TypeOf(OrderObject) = Type("DocumentObject.TransferOrder") Then
		
		OrderLineAdjustmentStructure.CheckBalance = True;
		
		ResultStructure1 = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If ResultStructure1.RowsCount > 0 Then
			OrderChanged = True;
		EndIf;
	ElsIf TypeOf(OrderObject) = Type("DocumentObject.OrderOfMaterialsForProduction") Then
		
		OrderLineAdjustmentStructure.CheckBalance = True;
		
		ResultStructure1 = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If ResultStructure1.RowsCount > 0 Then
			OrderChanged = True;
		EndIf;
	ElsIf TypeOf(OrderObject) = Type("DocumentObject.SubcontractOrder2_5") Then
		
		OrderLineAdjustmentStructure.CheckBalance = 
			OrderObject.Status <> Enums.TollingOrderStatuses.NotApproved;
		
		ResultStructure1 = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If ResultStructure1.RowsCount > 0 Then
			OrderChanged = True;
		EndIf;
	ElsIf TypeOf(OrderObject) = Type("DocumentObject.MaterialProviderOrder2_5") Then
		
		OrderLineAdjustmentStructure.CheckBalance = 
			OrderObject.Status <> Enums.StatusesOfMaterialProviderOrders.NotApproved
			And OrderObject.Status <> Enums.StatusesOfMaterialProviderOrders.Approved;
		
		ResultStructure1 = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If ResultStructure1.RowsCount > 0 Then
			OrderChanged = True;
		EndIf;
		
	ElsIf TypeOf(OrderObject) = Type("DocumentObject.RMOrder") Then
		
		OrderLineAdjustmentStructure.TabularSectionName = "MaterialsAndWorks";
		OrderLineAdjustmentStructure.CheckBalance = 
			OrderObject.Status <> Enums.RMOrderStatuses.Created;
		
		ResultStructure1 = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If ResultStructure1.RowsCount > 0 Then
			OrderChanged = True;
		EndIf;
		
	ElsIf TypeOf(OrderObject) = Type("DocumentObject.ProductionStage2_2") Then
		
		OrderLineAdjustmentStructure.CheckBalance = 
			OrderObject.Status <> Enums.StatusesOfProductionStages2_2.BeingGenerated;
		
		ResultStructure1 = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
		
		If ResultStructure1.RowsCount > 0 Then
			OrderChanged = True;
		EndIf;
	EndIf;
	
	Return OrderChanged;
	
EndFunction

// Parameters:
// 	DocumentObject - DocumentObject
// 	FillParameters - See FillOptionsForCancelingRows
// 	CancellationOptions - See OptionsForCancelingOrderLines
// Returns:
// 	See OrdersServer.ResultOfUndoingUnprocessedRows
// 
Function UndoUnprocessedShippingLines(DocumentObject, FillParameters, CancellationOptions) Export
	
	// 1. Description of the table
	TableOfSelectedRows = New ValueTable();
	TableOfSelectedRows.Columns.Add("Ref",               New TypeDescription("DocumentRef." + DocumentObject.Ref.Metadata().Name));
	TableOfSelectedRows.Columns.Add("RowCode",            New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Add("Products",         New TypeDescription("CatalogRef.Products"));
	TableOfSelectedRows.Columns.Add("Characteristic",       New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfSelectedRows.Columns.Add("Warehouse",                New TypeDescription("CatalogRef.Warehouses"));
	TableOfSelectedRows.Columns.Add("Series",                New TypeDescription("CatalogRef.ItemsBatches"));
	TableOfSelectedRows.Columns.Add("Purpose",           New TypeDescription("CatalogRef.Assignments"));
	TableOfSelectedRows.Columns.Add("WarehouseAssignment",     New TypeDescription("CatalogRef.Assignments")); // without old appointments
	TableOfSelectedRows.Columns.Add("Id",        New TypeDescription("Number"));
	
	TableOfSelectedRows.Columns.Add("Count",           New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Add("QuantityInInvoice", New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Add("NoteQuantity",    New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Add("Order",              New TypeDescription("Number")); // for an adequate distribution of orders
	
	// 2. Filling in the document data
	Id = 0;
	ThereIsTableOfSubstitutions = ValueIsFilled(FillParameters.ReplacementTable);
	DocumentObjectTS = DocumentObject[FillParameters.TabularSectionName]; // TabularSection
	For Each String In DocumentObjectTS Do
		If (CancellationOptions.DeleteRows_1 Or Not String.Canceled)
			And Not String.SupplyOption = Enums.SupplyOptions.TransferedEarlier Then
			
			NewRow = TableOfSelectedRows.Add();
			FillPropertyValues(NewRow, String);
			NewRow.Ref        = DocumentObject.Ref;
			NewRow.Id = Id;
			
			For Each DataPath In FillParameters.DataPaths Do
				NewRow[DataPath.Key] = DocumentObject[DataPath.Value];
			EndDo;
			
			If ThereIsTableOfSubstitutions Then
				FillPropertyValues(NewRow, FillParameters.ReplacementTable[String.LineNumber-1]);
			EndIf;
			
			If String.SupplyOption <> Enums.SupplyOptions.Ship Or Not String.WithAssignment Then
				NewRow.Purpose = Catalogs.Assignments.EmptyRef();
			EndIf;
			
			If String.SupplyOption = Enums.SupplyOptions.Ship Then
				NewRow.Order = 0;
			ElsIf String.SupplyOption = Enums.SupplyOptions.FromWarehouse Then
				NewRow.Order = 1;
			Else
				NewRow.Order = 2;
			EndIf;
			
		EndIf;
		Id = Id + 1;
	EndDo;
	
	TableOfSelectedRows.Sort("Order");
	
	AssignmentProperties = Catalogs.Assignments.AssignmentProperties(TableOfSelectedRows.UnloadColumn("Purpose"));
	For Each TableRow In TableOfSelectedRows Do
		If ValueIsFilled(TableRow.Purpose)
			And AssignmentProperties[TableRow.Purpose].ItIsTakenIntoAccountInWarehouseSubsystem Then
			TableRow.WarehouseAssignment = TableRow.Purpose;
		EndIf;
	EndDo;
	
	// 3. Distribution of the number of invoices
	IssuedByWaybills = FillParameters.RegisterManager.TableDecorated(TableOfSelectedRows, FillParameters.FilterByDimensions);
	NumberColumn = IssuedByWaybills.Columns.Count; // ValueTableColumn
	NumberColumn.Name = "QuantityInInvoice";
	
	Condition = "On [Count]";
	
	Var_Key = "RowCode";
	InvoicesServer.AllocateQuantity(IssuedByWaybills, TableOfSelectedRows, "QuantityInInvoice", Var_Key, Condition, True);
	
	// 4. Distribution of the number of orders
	Adjusting = TableOfSelectedRows.Copy(); // an empty table for Transferring to registers
	Adjusting.Columns.Add("ToShip", New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Purpose.Name = "DocumentAssignment";
	TableOfSelectedRows.Columns.WarehouseAssignment.Name = "Purpose";
	
	IssuedByOrders = AccumulationRegisters.GoodsForIssue.TableDecorated(TableOfSelectedRows, Adjusting, True);
	NumberColumn = IssuedByOrders.Columns.Count; // ValueTableColumn
	NumberColumn.Name = "NoteQuantity";
	
	// For an interconnected distribution of the number of orders, we will take into account the previous distribution of the number of invoices by line codes
	Condition = "On [QuantityInInvoice]";
	
	Var_Key = "Products, Characteristic, Series, Purpose";
	InvoicesServer.AllocateQuantity(IssuedByOrders, TableOfSelectedRows, "NoteQuantity", Var_Key, Condition);
	
	Condition = "On [Count]";
	
	Var_Key = "Products, Characteristic, Series, Purpose";
	InvoicesServer.AllocateQuantity(IssuedByOrders, TableOfSelectedRows, "NoteQuantity", Var_Key, Condition, True);
	
	// If the order does not specify the destination or is specified incorrectly
	Var_Key = "Products, Characteristic, Series";
	InvoicesServer.AllocateQuantity(IssuedByOrders, TableOfSelectedRows, "NoteQuantity", Var_Key, Condition, True);
	
	TableOfSelectedRows.Columns.Delete("Purpose");
	DocumentAssignmentColumn = TableOfSelectedRows.Columns.DocumentAssignment; // ValueTableColumn
	DocumentAssignmentColumn.Name = "Purpose";
	
	// 5. Convolution of the table to the canceled rows
	NumberOfIndexes = TableOfSelectedRows.Count() - 1;
	For IndexOf = 0 To NumberOfIndexes Do
		String = TableOfSelectedRows[NumberOfIndexes - IndexOf];
		If String.Count < String.QuantityInInvoice Then
			Issued_1 = String.QuantityInInvoice;
		Else
			Issued_1 = Max(String.QuantityInInvoice, String.NoteQuantity);
		EndIf;
		String.Count = String.Count - Issued_1;
		If String.Count = 0 Then
			TableOfSelectedRows.Delete(String);
		EndIf;
	EndDo;
	
	NumberOfRowsToCancel = MoveCanceledRowsToDocumentTable(DocumentObject,
		DocumentObject[FillParameters.TabularSectionName], TableOfSelectedRows,
		CancellationOptions, Enums.InventoryMovementTypes.Shipment);
	
	Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfRowsToCancel);
	
EndFunction

// Parameters:
// 	DocumentObject - DocumentObject
// 	FillParameters - See FillOptionsForCancelingRows
// 	CancellationOptions - See OptionsForCancelingOrderLines
// Returns:
// 	See OrdersServer.ResultOfUndoingUnprocessedRows
//
Function CancelUnprocessedAcceptanceLines(DocumentObject, FillParameters, CancellationOptions) Export
	
	// 1. Description of the table
	TableOfSelectedRows = New ValueTable();
	TableOfSelectedRows.Columns.Add("Ref",               New TypeDescription("DocumentRef." + DocumentObject.Ref.Metadata().Name));
	TableOfSelectedRows.Columns.Add("RowCode",            New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Add("Products",         New TypeDescription("CatalogRef.Products"));
	TableOfSelectedRows.Columns.Add("Characteristic",       New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfSelectedRows.Columns.Add("Warehouse",                New TypeDescription("CatalogRef.Warehouses"));
	TableOfSelectedRows.Columns.Add("Purpose",           New TypeDescription("CatalogRef.Assignments"));
	TableOfSelectedRows.Columns.Add("WarehouseAssignment",     New TypeDescription("CatalogRef.Assignments")); // without old appointments
	TableOfSelectedRows.Columns.Add("Id",        New TypeDescription("Number"));
	
	TableOfSelectedRows.Columns.Add("Count",           New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Add("QuantityInInvoice", New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Add("NoteQuantity",    New TypeDescription("Number"));
	
	// 2. Filling in the document data
	Id = 0;
	ThereIsTableOfSubstitutions = ValueIsFilled(FillParameters.ReplacementTable);
	DocumentObjectTS = DocumentObject[FillParameters.TabularSectionName]; // DocumentTabularSection.ByAssemblyDisassemblyOrder.Goods, DocumentTabularSection.MaterialProviderOrder2_5.UsedMaterials
	For Each String In DocumentObjectTS Do
		If (CancellationOptions.DeleteRows_1 Or Not String.Canceled)
			And Not (CommonClientServer.HasAttributeOrObjectProperty(String, "Action")
				And String.Action = Enums.ActionsOnMaterialsToSubcontract.UseAvailable)
			Then
			NewRow = TableOfSelectedRows.Add();
			FillPropertyValues(NewRow, String);
			NewRow.Ref        = DocumentObject.Ref;
			NewRow.Id = Id;
			For Each DataPath In FillParameters.DataPaths Do
				NewRow[DataPath.Key] = DocumentObject[DataPath.Value];
			EndDo;
			If ThereIsTableOfSubstitutions Then
				FillPropertyValues(NewRow, FillParameters.ReplacementTable[String.LineNumber-1]);
			EndIf;
		EndIf;
		Id = Id + 1;
	EndDo;
	
	// 3. Distribution of the number of invoices
	IssuedByWaybills = FillParameters.RegisterManager.TableDecorated(TableOfSelectedRows, FillParameters.FilterByDimensions);
	ColumnQuantity = IssuedByWaybills.Columns.Count; // ValueTableColumn
	ColumnQuantity.Name = "QuantityInInvoice";
	
	Condition = "On [Count]";
	
	Var_Key = "RowCode";
	InvoicesServer.AllocateQuantity(IssuedByWaybills, TableOfSelectedRows, "QuantityInInvoice", Var_Key, Condition, True);
	
	// 4. Distribution of the number of orders
	Adjusting = TableOfSelectedRows.Copy(); // an empty table for Transferring to registers
	Adjusting.Columns.Add("ToReceive", New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Purpose.Name = "DocumentAssignment";
	TableOfSelectedRows.Columns.WarehouseAssignment.Name = "Purpose";
	
	IssuedByOrders = AccumulationRegisters.GoodsToReceive.TableDecorated(TableOfSelectedRows, Adjusting, True);
	ColumnQuantity = IssuedByOrders.Columns.Count; // ValueTableColumn
	ColumnQuantity.Name = "NoteQuantity";
	
	// For an interconnected distribution of the number of orders, we will take into account the previous distribution of the number of invoices by line codes
	Condition = "On [QuantityInInvoice]";
	
	Var_Key = "Products, Characteristic, Purpose";
	InvoicesServer.AllocateQuantity(IssuedByOrders, TableOfSelectedRows, "NoteQuantity", Var_Key, Condition);
	
	Condition = "On [Count]";
	
	Var_Key = "Products, Characteristic, Purpose";
	InvoicesServer.AllocateQuantity(IssuedByOrders, TableOfSelectedRows, "NoteQuantity", Var_Key, Condition, True);
	
	// If the order does not specify the destination or is specified incorrectly
	Var_Key = "Products, Characteristic";
	InvoicesServer.AllocateQuantity(IssuedByOrders, TableOfSelectedRows, "NoteQuantity", Var_Key, Condition, True);
	
	TableOfSelectedRows.Columns.Delete("Purpose");
	DocumentAssignmentColumn = TableOfSelectedRows.Columns.DocumentAssignment; // ValueTableColumn
	DocumentAssignmentColumn.Name = "Purpose";
	
	// 5. Convolution of the table to the canceled rows
	NumberOfIndexes = TableOfSelectedRows.Count() - 1;
	For IndexOf = 0 To NumberOfIndexes Do
		String = TableOfSelectedRows[NumberOfIndexes - IndexOf];
		If String.Count < String.QuantityInInvoice Then
			Issued_1 = String.QuantityInInvoice;
		Else
			Issued_1 = Max(String.QuantityInInvoice, String.NoteQuantity);
		EndIf;
		String.Count = String.Count - Issued_1;
		If String.Count = 0 Then
			TableOfSelectedRows.Delete(String);
		EndIf;
	EndDo;
	
	NumberOfRowsToCancel = MoveCanceledRowsToDocumentTable(DocumentObject,
		DocumentObject[FillParameters.TabularSectionName], TableOfSelectedRows,
		CancellationOptions, Enums.InventoryMovementTypes.Inpayment);
	
	Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfRowsToCancel);
	
EndFunction


// LongDesc
// 
// Parameters:
// 	DocumentObject - DocumentObject
// 	DocumentTable - TabularSection
// 	TableOfCanceledRows - ValueTable:
// * Ref - DocumentRef
// * RowCode - Number
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
// * Warehouse - CatalogRef.Warehouses
// * Purpose - CatalogRef.Assignments
// * WarehouseAssignment - CatalogRef.Assignments
// * Id - Number
// * Count - Number
// * QuantityInInvoice - Number
// * NoteQuantity - Number
// * ToReceive - Number
// 	CancellationOptions - Structure:
// * CancellationReason - Undefined
// * DeleteRows_1 - Boolean
// * AdjustAmount - Boolean
// * CancelOnlyMeasuredGoods - Boolean
// * CorrectMeasuringGoods - Boolean
// 	InventoryMovementType - EnumRef.InventoryMovementTypes
// 	
// Returns:
// 	Number 
Function MoveCanceledRowsToDocumentTable(DocumentObject, DocumentTable, TableOfCanceledRows, CancellationOptions, InventoryMovementType)
	
	ReadyForProcessing_ = New Map();
	For Each String In TableOfCanceledRows Do
		LineProducts_ = DocumentTable[String.Id];
		ReadyForProcessing_.Insert(String, LineProducts_);
	EndDo;
	
	If CancellationOptions.CorrectMeasuringGoods Then
		
		AcceptableDeviations = Documents[DocumentObject.Ref.Metadata().Name].PermissibleDeviationsOfMeasuredGoods(
			DocumentObject.Ref, InventoryMovementType); // See Documents.TransferOrder.PermissibleDeviationsOfMeasuredGoods
		
		Var_Key = New Array;
		For Each Column In AcceptableDeviations.Columns Do
			If Column.Name <> "AllowableVariance" And Column.Name <> "OrderDocument" Then
				Var_Key.Add(Column.Name);
			EndIf;
		EndDo;
		Var_Key = StrConcat(Var_Key, ",");
		
		TheStructureOfTheSearch = New Structure(Var_Key);
		
		TableOfProductsToCancel = AcceptableDeviations.Copy();
		TableOfProductsToCancel.Clear();
		TableOfProductsToCancel.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType());
		
		// Collapse the lines that we are going to cancel
		For Each KeyValue In ReadyForProcessing_ Do
			String = KeyValue.Key;
			LineProducts_ = KeyValue.Value;
			
			ReadyToCancel = TableOfProductsToCancel.Add();
			FillPropertyValues(ReadyToCancel, LineProducts_);
			ReadyToCancel.Count = String.Count;
		EndDo;
		
		TableOfProductsToCancel.GroupBy(Var_Key,"Count");
		TableOfProductsToCancel.Columns.Add("ExcludeFromCancellation",New TypeDescription("Boolean"));
		TableOfProductsToCancel.Indexes.Add(Var_Key);
		
		// Unacceptable deviations are excluded from cancellation
		For Each UndoString In TableOfProductsToCancel Do
			FillPropertyValues(TheStructureOfTheSearch,UndoString);
			ToleranceLines = AcceptableDeviations.FindRows(TheStructureOfTheSearch);
			If ToleranceLines.Count() = 0
				Or ToleranceLines[0].AllowableVariance < -UndoString.Count
				Or ToleranceLines[0].AllowableVariance < UndoString.Count Then
				UndoString.ExcludeFromCancellation = UndoString.Count < 0 Or CancellationOptions.CancelOnlyMeasuredGoods;
			EndIf;
		EndDo;
		
	EndIf;
	
	NumberOfCanceledLines     = 0;
	RecalculateNumberOfPackages = False;
	
	For Each KeyValue In ReadyForProcessing_ Do
		String = KeyValue.Key;
		LineProducts_ = KeyValue.Value;
		
		If CancellationOptions.CorrectMeasuringGoods Then
			
			FillPropertyValues(TheStructureOfTheSearch, LineProducts_);
			TableRowToCancel = TableOfProductsToCancel.FindRows(TheStructureOfTheSearch)[0];
			If TableRowToCancel.ExcludeFromCancellation Then
				Continue;
			EndIf;
			
		ElsIf String.Count < 0 Then
			
			Continue;
			
		EndIf;
		
		If String.Count < LineProducts_.Count Then
			
			If CancellationOptions.AdjustAmount Then
				CancellationAmount = Round(LineProducts_.Sum / LineProducts_.Count * String.Count, 2);
				LineProducts_.Sum = LineProducts_.Sum - CancellationAmount;
			EndIf;
			
			LineProducts_.Count = LineProducts_.Count - String.Count;
			
			If String.Count > 0 And Not CancellationOptions.DeleteRows_1 Then
				
				NewRow = DocumentTable.Insert(DocumentTable.IndexOf(LineProducts_) + 1);
				FillPropertyValues(NewRow, LineProducts_);
				
				NewRow.Count = String.Count;
				NewRow.Canceled = True;
				NewRow.RowCode = 0;
				If CancellationOptions.CancellationReason <> Undefined 
					And CommonClientServer.HasAttributeOrObjectProperty(NewRow, CancellationOptions.FieldNameReasonForCancellation) Then
					NewRow[CancellationOptions.FieldNameReasonForCancellation] = CancellationOptions.CancellationReason;
				EndIf;
				If CancellationOptions.AdjustAmount Then
					NewRow.Sum = CancellationAmount;
				EndIf;
				
			EndIf;
			
		ElsIf CancellationOptions.DeleteRows_1 Then
			DocumentTable.Delete(LineProducts_);
			NumberOfCanceledLines = NumberOfCanceledLines + 1;
			Continue;
		Else
			
			LineProducts_.Canceled = True;
			If CancellationOptions.CancellationReason <> Undefined
				And CommonClientServer.HasAttributeOrObjectProperty(LineProducts_, CancellationOptions.FieldNameReasonForCancellation) Then
				LineProducts_[CancellationOptions.FieldNameReasonForCancellation] = CancellationOptions.CancellationReason;
			EndIf;
			
		EndIf;
		
		If Not LineProducts_ = Undefined
			And Not RecalculateNumberOfPackages Then
			RecalculateNumberOfPackages = CommonClientServer.HasAttributeOrObjectProperty(LineProducts_, "Package");
		EndIf;
		
		NumberOfCanceledLines = NumberOfCanceledLines + 1;
		
	EndDo;
	
	If RecalculateNumberOfPackages Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert(
			"RecalculateNumberOfPackages",
			BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
		
		BatchProcessingOfTablePartServer.TreatTS(DocumentTable, StructureOfActions, Undefined);
		
	EndIf;
	
	Return NumberOfCanceledLines;
	
EndFunction

// Returns the text of the notification about the row cancellation operation
//
// Parameters:
//  CancelledRowsCount      - Number - The number of canceled rows.
//  Modified - Boolean - The form parameter of the same name to change in the procedure.
// 
// Returns:
//  Structure - the text of the notification about the row cancellation operation and the number of rows canceled.
//
Function ResultOfUndoingUnprocessedRows(CancelledRowsCount, Modified = False) Export
	
	CancellationResult = New Structure("Notification, RowsCount");
	
	If CancelledRowsCount = Undefined Then
		CancellationResult.Notification = NStr("vi = 'Hàng chưa xử lý không thành công';
												|ru = 'Отмена неотработанных строк не выполнена';
												|en = 'Cannot cancel unprocessed lines'; fa = 'Cannot cancel unprocessed lines';
												|it = 'Annullamento delle righe non elaborate non riuscito';
												|pl = 'Anulowanie nieprzetworzonych wierszy nie jest wykonane';
												|tr = 'Bekleyen satırların iptali başarısız oldu'");
		CancellationResult.RowsCount = 0;
	ElsIf CancelledRowsCount = 0 Then
		CancellationResult.Notification = NStr("vi = 'Các dòng không bị hủy vì chúng được xử lý đầy đủ';
												|ru = 'Строки не отменены, поскольку полностью отработаны';
												|en = 'Lines were not canceled as they are not fully processed'; fa = 'Lines were not canceled as they are not fully processed';
												|it = 'Le righe non sono state annullate, poiché sono state già elaborate';
												|pl = 'Wierszy nie są anulowane, ponieważ są całkowicie przetworzone';
												|tr = 'Satırlar tamamen işlendiği için iptal edilmedi'");
		CancellationResult.RowsCount = 0;
	Else
		CancellationResult.Notification = StrTemplate(NStr("vi = 'Đã hủy hàng chưa xử lý: %1';
															|ru = 'Отменено неотработанных строк: %1';
															|en = 'Canceled unprocessed lines: %1'; fa = 'Canceled unprocessed lines: %1';
															|it = 'Annullata riga non elaborata: %1';
															|pl = 'Anulowano nieprzetworzonych wierszy: %1';
															|tr = 'İşlenmeyen satırlar iptal edildi: %1'"), CancelledRowsCount);
		CancellationResult.RowsCount = CancelledRowsCount;
		Modified = True;
	EndIf;
	
	Return CancellationResult;

EndFunction

#EndRegion

#Region ScheduledJob

// Corrects rows of dimensional goods of orders that are included in the order queue register.corrects rows of dimensional Goods.
// The method of routine assignment of adjustment of the order of goods ' orders.
//
Procedure AutomaticAdjustmentOfOrderLinesOfDimensionalGoods() Export
	
	ScheduledJob = Metadata.ScheduledJobs.AdjustmentOfMeasuringGoodsOrderRows;
	
	Common.OnStartExecuteScheduledJob(ScheduledJob);
	
	If Not GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving") Then
		Return;
	EndIf;
	
	OrderLineAdjustmentStructure = New Structure();
	OrderLineAdjustmentStructure.Insert("CorrectMeasuringGoods", True);
	OrderLineAdjustmentStructure.Insert("AdjustTheMeasuredGoodsUponAcceptance", True);
	
	LevelInformation = EventLogLevel.Information;
	
	DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	OrderQueueToAdjustRowsOfMeasuringGoods.OrderDocument AS OrderDocument,
	|	OrderQueueToAdjustRowsOfMeasuringGoods.OrderDocument.Posted AS Posted
	|FROM
	|	InformationRegister.OrderQueueToAdjustRowsOfMeasuringGoods AS OrderQueueToAdjustRowsOfMeasuringGoods
	|
	|ORDER BY
	|	OrderQueueToAdjustRowsOfMeasuringGoods.AddedOn";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.OrderQueueToAdjustRowsOfMeasuringGoods");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("OrderDocument", Selection.OrderDocument);
		Block.Lock();
		
		If Not Selection.Posted Then
			
			RecordSet = InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.CreateRecordSet();
			RecordSet.Filter.OrderDocument.Set(Selection.OrderDocument);
			
			RecordSet.Write();
			
		EndIf;
		
		// Capturing an object for editing
		Try
			LockDataForEdit(Selection.OrderDocument);
		Except
			
			RollbackTransaction();
			
			WriteLogEvent(
				NStr("vi = 'Không thể khóa đối tượng trong quá trình điều chỉnh tự động các dòng hàng đo.';
					|ru = 'Не удалось заблокировать объект при автоматической корректировке строк мерных товаров.';
					|en = 'Cannot lock the object on automatic adjustment of lines with measured goods.'; fa = 'Cannot lock the object on automatic adjustment of lines with measured goods.';
					|it = 'Non è stato possibile bloccare l''oggetto durante la correzione automatica dell''inserimento delle righe delle merci di misurazione.';
					|pl = 'Zablokowanie obiektu nie powiodło się podczas korekty automatycznej wierszy towarów miarowych.';
					|tr = 'Ölçülen ürün satırlarının otomatik düzeltilmesi sırasında nesne kilitlenemedi.'", DefaultLanguageCode),
				EventLogLevel.Warning,
				,
				Selection.OrderDocument);
			
			Continue;
			
		EndTry;
		
		OrderObject = Selection.OrderDocument.GetObject(); // DocumentObject
		
		OrderChanged = OrdersServer.AdjustOrderLines(OrderObject, OrderLineAdjustmentStructure);
		
		If OrderChanged Then
			Try
				OrderObject.Write(DocumentWriteMode.Posting);

				RecordSet = InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.CreateRecordSet();
				RecordSet.Filter.OrderDocument.Set(Selection.OrderDocument);
				RecordSet.Write();
				
				MessageText = NStr("vi = 'Sửa hàng đo được theo đơn đặt hàng %OrderDocument%';
									|ru = 'Выполнена корректировка строк мерных товаров по заказу %OrderDocument%';
									|en = 'Adjustment of lines with measured goods against the %OrderDocument% order is executed'; fa = 'Adjustment of lines with measured goods against the %OrderDocument% order is executed';
									|it = 'Correzione dell''inserimento delle righe delle merci di misurazione in base all''ordine %OrderDocument% effettuata.';
									|pl = 'Został wykonany zapis korygujący wierszy towarów miarowych na zamówienie %OrderDocument%';
									|tr = 'Ölçülen ürün satırları %OrderDocument% siparişi için düzeltildi'", DefaultLanguageCode);
				MessageText = StrReplace(MessageText, "%OrderDocument%", Selection.OrderDocument);
				WriteLogEvent(
					NStr("vi = 'Kết thúc điều chỉnh các dòng hàng đo.';
						|ru = 'Окончание корректировки строк мерных товаров.';
						|en = 'End of adjustment of lines with measured goods.'; fa = 'End of adjustment of lines with measured goods.';
						|it = 'Fine della correzione dell''inserimento delle righe delle merci di misurazione.';
						|pl = 'Koniec korekty wierszy towarów miarowych.';
						|tr = 'Ölçülen ürün satırlarının düzeltilmesi sonu.'", DefaultLanguageCode),
					LevelInformation,
					,
					Selection.OrderDocument,
					MessageText);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				MessageText = NStr("vi = 'Không thể thực hiện điều chỉnh các dòng
				                            | của hàng hóa theo đơn hàng %OrderDocument% do nguyên nhân: %Cause%';
				                            |ru = 'Не удалось выполнить корректировку строк
				                            | мерных товаров по заказу %OrderDocument% по причине: %Cause%';
				                            |en = 'Cannot correct lines with measured goods
				                            |against the %OrderDocument% order. Reason: %Cause%'; fa = 'Cannot correct lines with measured goods
				                            |against the %OrderDocument% order. Reason: %Cause%';
				                            |it = 'Non è stato possibile eseguire la correzione dell''inserimento delle righe 
				                            | della merce di misurazione in base all''ordine  %OrderDocument% a causa di: %Cause%';
				                            |pl = 'Nie udało się wykonanie korekty wierszy
				                            | towarów miarowych na zamówienie %OrderDocument% z powodu: %Cause%';
				                            |tr = '%OrderDocument% siparişi için ölçülen öğelerin
				                            | satırları şu nedenle düzeltilemedi: %Cause%'");
				MessageText = StrReplace(MessageText, "%OrderDocument%", Selection.OrderDocument);
				MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(NStr("vi = 'Điều chỉnh nền các dòng đơn hàng của hàng đo';
									|ru = 'Фоновая корректировка строк заказов мерных товаров';
									|en = 'Background adjustment of lines of orders with measured goods'; fa = 'Background adjustment of lines of orders with measured goods';
									|it = 'Correzione in background dell''inserimento delle righe degli ordini delle merci di misurazione';
									|pl = 'Korekta w tle wierszy zamówień towarów miarowych';
									|tr = 'Ölçülen ürünler için sipariş satırlarının arka plan düzeltmesi'", DefaultLanguageCode),
					EventLogLevel.Error, , ,
					MessageText);
				Raise;
				
			EndTry
			
		Else
			
			Try
				
				RecordSet = InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.CreateRecordSet();
				RecordSet.Filter.OrderDocument.Set(Selection.OrderDocument);
				RecordSet.Write();
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
				MessageText = NStr("vi = 'Không thể xóa %OrderDocument% khỏi trình tự điều chỉnh dòng
				                            | của hàng hóa do nguyên nhân: %Cause%';
				                            |ru = 'Не удалось удалить %OrderDocument% из очереди на корректировку строк
				                            | мерных товаров по причине: %Cause%';
				                            |en = 'Cannot delete %OrderDocument% from adjustment of lines with measured goods
				                            |queue. Reason: %Cause%'; fa = 'Cannot delete %OrderDocument% from adjustment of lines with measured goods
				                            |queue. Reason: %Cause%';
				                            |it = 'Non è stato possibile eliminare %OrderDocument% dalla coda di correzione dell''inserimento delle righe 
				                            |della merce di misurazione a causa di: %Cause%';
				                            |pl = 'Nie udało się usunąć %OrderDocument% z kolejki do korekty wierszy
				                            | towarów miarowych z powodu: %Cause%';
				                            |tr = '%OrderDocument%, şu nedenle satır düzeltme sırası
				                            | boyutlu öğelerden kaldırılamadı: %Cause%'");
				MessageText = StrReplace(MessageText, "%OrderDocument%", Selection.OrderDocument);
				MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(NStr("vi = 'Điều chỉnh nền các dòng đơn hàng của hàng đo';
									|ru = 'Фоновая корректировка строк заказов мерных товаров';
									|en = 'Background adjustment of lines of orders with measured goods'; fa = 'Background adjustment of lines of orders with measured goods';
									|it = 'Correzione in background dell''inserimento delle righe degli ordini delle merci di misurazione';
									|pl = 'Korekta w tle wierszy zamówień towarów miarowych';
									|tr = 'Ölçülen ürünler için sipariş satırlarının arka plan düzeltmesi'", DefaultLanguageCode),
					EventLogLevel.Error, , ,
					MessageText);
				Raise;
				
			EndTry
			
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region EventsSubscriptionsHandlers

Procedure ClearOrderQueueToAdjustRowsOfMeasuringGoodsBeforeRemovingDocumentBeforeDelete(Source, Cancel) Export
	
    If Source.DataExchange.Load Then
        Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
		
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.OrderQueueToAdjustRowsOfMeasuringGoods");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("OrderDocument", Source.Ref);
		Block.Lock();
		
		Set = InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.CreateRecordSet();
		Set.Filter.OrderDocument.Set(Source.Ref);
		Set.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorDescription = ErrorDescription();
		Raise ErrorDescription;
		
	EndTry;

EndProcedure


#EndRegion

#EndRegion

#Region Internal

// When splitting the rows, it recalculates the values of the details and dependent details.
// Parameters:
//  ModifiedRows   - ValueTable - table with columns:
//   * Id   - Number - ID of the original row that was split into multiple rows.
//   * String          - String - A row of the form table, the result of the split. Subject to recalculation of the bank details.
//  Attributes          - String    - The details of the form table are separated by commas.
Procedure RecalculateDependentPropsAfterSplittingRows(ModifiedRows, Attributes) Export
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(Attributes);
	
	Id = Undefined;
	For Each Update In ModifiedRows Do
		
		If Id <> Update.Id Then
			
			Id = Update.Id;
			
			BatchProcessingOfTablePartClientServer.RecalculateAmounts(StructureOfRecalculationOfAmount);
			BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, Update.String);
			
		EndIf;
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(StructureOfRecalculationOfAmount, Update.String);
		
	EndDo;
	BatchProcessingOfTablePartClientServer.RecalculateAmounts(StructureOfRecalculationOfAmount);
	
EndProcedure

#EndRegion