
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Currency = Parameters.Currency;
	
	FillInTableOfManufacturedProducts(Parameters);
	
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Parameters.Ref);

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// ItemsAndDimensionsSelectionParameters
	FormData1 = New Structure;
	FormData1.Insert("FormData1", New Structure("ProductTable", ProductTable));
	FormData1.Insert("Items", Items);
	FormData1.Insert("ConditionalAppearance", ConditionalAppearance);
	FormData1.Insert("MechanismDataCache", New Structure);
	
	ItemsAndDimensionsSelectionParameters = Documents.ReportToMaterialProvider2_5.ItemsAndDimensionsSelectionParameters();
	ItemsAndDimensionsSelectionParameters[0].DataPath = "FormData1.ProductTable";
	IncomeAndExpensesServer.OnCreateAtServer(FormData1, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	QueryText = NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
					|ru = 'Данные были изменены. Перенести изменения в документ?';
					|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
					|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
					|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
					|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'");
	Notification   = New CallbackDescription("BeforeCloseCompletion", ThisObject);
	
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit, QueryText);
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	MoveToDocument(Undefined);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersServices

&AtClient
Procedure ProductTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ProductTable.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ProductTableMaterialProviderOrder Then
		
		ShowValue(Undefined, CurrentData.MaterialProviderOrder);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	ArrayOfARAPObjectsSettings = New Array;
	For Each ProductionLine In ProductTable Do
		If ProductionLine.RowIsSelected
			And ValueIsFilled(ProductionLine.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(ProductionLine.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(ProductionLine.ARAPObjectSettings);
		EndIf;
	EndDo;
	
	If ArrayOfARAPObjectsSettings.Count() > 1 Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Trong các đơn hàng đã chọn, khác trường ""Trình tự hạch toán""';
										|ru = 'У выбранных заказов отличается поле ""Порядок расчетов""';
										|en = 'The ""Payment terms"" field data is different for the selected orders'; fa = 'The ""Payment terms"" field data is different for the selected orders';
										|it = 'У выбранных заказов отличается поле ""Порядок расчетов""';
										|pl = 'The ""Payment terms"" field data is different for the selected orders';
										|tr = 'Seçilen siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		Return;
	EndIf;
	
	Modified = False;
	
	Close();
	
	NotifyChoice(New Structure("AddressInStorage", PutInStorage()));
	
EndProcedure

&AtClient
Procedure CheckAll(Command)

	SetValueOfCheckboxes(True);

EndProcedure

&AtClient
Procedure UncheckAll(Command)

	SetValueOfCheckboxes(False);

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ProductTableProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "ProductTable.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductTable.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ProductTable.ExistsInTheDocument");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductTableMaterialProviderOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductTable.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductTableMaterialProviderOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductTable.MaterialProviderOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có đơn hàng>';
													|ru = '<без заказа>';
													|en = '<without order>'; fa = '<بدون سفارش>';
													|it = '<senza ordine>';
													|pl = '<bez zamówienia>';
													|tr = '<sipariş verilmeden>.'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductTableRecipient.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ProductTable.ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text",      NStr("vi = '<khi ghi giảm vào chi phí>';
														|ru = '<при списании на расходы>';
														|en = '<when writing off as expenses>'; fa = '<when writing off as expenses>';
														|it = '<durante lo storno sulle spese>';
														|pl = '<przy wyksięgowaniu na rozchody>';
														|tr = '<gider yazılması>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

#Region Other

&AtClient
Procedure SetValueOfCheckboxes(Value)
	
	RowsArray = ProductTable.FindRows(New Structure("RowIsSelected", Not Value));
	For Each TableRow In RowsArray Do
		TableRow.RowIsSelected = Value;
	EndDo;
	
EndProcedure

&AtServer
Function PutInStorage()
	
	Return PutToTempStorage(ProductTable.Unload(New Structure("RowIsSelected", True)));
	
EndFunction

&AtServer
Procedure FillInTableOfManufacturedProducts(PickingParameters)
	
	FillParameters = New Structure;
	FillParameters.Insert("CheckOrderOfCalculations", False);
	
	Documents.ReportToMaterialProvider2_5.FillByOrderBalances(
		PickingParameters, ProductTable, PickingParameters.AnArrayOfOrders, FillParameters);
	
	OrdersServer.SetSignsOfPresenceOfLineInDocument(
		ProductTable, "MaterialProviderOrder", PickingParameters.ArrayOfStringCodes);
	
	LineNumber = 0;
	For Each TableRow In ProductTable Do
		LineNumber = LineNumber + 1;
		TableRow.LineNumber = LineNumber;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
