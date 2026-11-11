
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
		
	DocumentCurrency    = Parameters.DocumentCurrency;
	VATTaxation = Parameters.VATTaxation;
	PriceIncludesVAT    = Parameters.PriceIncludesVAT;
	SalesOrder = Parameters.SalesOrder;
	AnArrayOfOrders = Parameters.AnArrayOfOrders;
	OrderList.LoadValues(AnArrayOfOrders);
	UseCustomerInvoicesForSeveralOrders = GetFunctionalOption("UseCustomerInvoicesForSeveralOrders");
	ByOrders = (ValueIsFilled(SalesOrder) Or AnArrayOfOrders.Count()>0) And UseCustomerInvoicesForSeveralOrders;
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	If Parameters.Property("ARAPObjectSettings") Then
		ARAPObjectSettings = Parameters.ARAPObjectSettings;
	EndIf;
	
	Items.ServicesTableDepartment.Visible = UseBusinessUnits;
	
	VTOrders = New ValueTable;
	VTOrders.Columns.Add("SalesOrder");
	For Indus=1 To AnArrayOfOrders.Count() Do
		VTOrders.Add();	
	EndDo;
	VTOrders.LoadColumn(AnArrayOfOrders,"SalesOrder");	
	
	FillInTableOfServices(Parameters.SalesOrder, Parameters.Document, Parameters.DocumentCurrency,Parameters.AnArrayOfOrders);
	UpdateOrderInformation(VTOrders,UseCustomerInvoicesForSeveralOrders);
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Parameters.Document);
		
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure UpdateOrderInformation(VTOrders, UseCustomerInvoicesForSeveralOrders)
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "SalesOrder";
	ParametersOfUpdate.TitleLabelName               = "LabelHeaderSalesOrders";
	ParametersOfUpdate.OrderNameInTablePart          = "SalesOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseCustomerInvoicesForSeveralOrders ;
	
	OrdersServer.UpdateOrderInformationInForm(ThisForm, VTOrders, ParametersOfUpdate);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If ForceCloseTheForm Then
		Return;
	EndIf;
	
	If Modified Then

		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
				|ru = 'Данные были изменены. Перенести изменения в документ?';
				|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
				|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
				|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
				|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'"),
			QuestionDialogMode.YesNoCancel);

	EndIf;

EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		MoveProductsToDocument();
		
		ForceCloseTheForm = True;
		
		If ThisForm.IsOpen() Then
			Close();
		EndIf;
		
	ElsIf Response = DialogReturnCode.No Then
		
		ForceCloseTheForm = True;
		
		If ThisForm.IsOpen() Then
			Close();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersServices

&AtClient
Procedure ServicesTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.ServicesTable.CurrentData <> Undefined Then
		If Field.Name = "ServicesTableSalesOrder" Then
			ShowValue(Undefined, Items.ServicesTable.CurrentData.SalesOrder);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelHeaderSalesOrdersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			OrderList,
			NStr("vi = 'Đơn hàng của khách (%DocumentsCount%)';
				|ru = 'Заказы клиентов (%DocumentsCount%)';
				|en = 'Sales orders (%DocumentsCount%)'; fa = 'Sales orders (%DocumentsCount%)';
				|it = 'Ordini dei clienti (%DocumentsCount%)';
				|pl = 'Zamówienia klientów (%DocumentsCount%)';
				|tr = 'Satış siparişleri (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure ByOrdersOnChange()
	
	If Not ByOrders Then
		Items.ServicesTable.RowFilter = Undefined;
	Else	
		Items.ServicesTable.RowFilter = New FixedStructure("OrderFromCertificate",True);	
	EndIf;
	
EndProcedure

&AtClient
Procedure AcceptanceNoteForOrdersOnChange(Item)
	ByOrdersOnChange();
EndProcedure

&AtClient
Procedure ActOfCompletedWorkOnTheOrderOnChange(Item)
	ByOrdersOnChange();	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()
	
	MoveProductsToDocument();
	
EndProcedure

&AtClient
Procedure ToChooseTheProductsExecute()

	SelectAllProductsOnServer(True);

EndProcedure

&AtClient
Procedure ExcludeGoodsExecute()

	SelectAllProductsOnServer(False);

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

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesTable.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServicesTable.ExistsInTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesTableSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServicesTable.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesTableAmountIncludingVAT.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceIncludesVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesTableVATAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesTableAmountIncludingVAT.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesTableVATRate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;

	Item.Appearance.SetParameterValue("Visible", False);

EndProcedure

#Region Other

&AtClient
Procedure MoveProductsToDocument()
	
	ArrayOfARAPObjectsSettings = New Array;
	If OrderList.Count() > 0 
		And ValueIsFilled(ARAPObjectSettings)Then
		ArrayOfARAPObjectsSettings.Add(ARAPObjectSettings);
	EndIf;
	For Each ServiceLine_1 In ServicesTable Do
		If ServiceLine_1.RowIsSelected
			And ValueIsFilled(ServiceLine_1.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(ServiceLine_1.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(ServiceLine_1.ARAPObjectSettings);
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
	
	GoodsAddressInStorage = PutProductsInStorage();
	
	ForceCloseTheForm = ThisForm.CloseOnChoice;	
	
	NotifyChoice(New Structure("GoodsAddressInStorage", GoodsAddressInStorage));
	
EndProcedure

&AtServer
Procedure SelectAllProductsOnServer(SelectionValue = True)
	
	For Each TableRow In ServicesTable.FindRows(New Structure("RowIsSelected", Not SelectionValue)) Do
		TableRow.RowIsSelected = SelectionValue;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInOrderDataFromReport()
	
	For Each TableRow In ServicesTable Do
		If OrderList.FindByValue(TableRow.SalesOrder)<> Undefined Then
			TableRow.OrderFromCertificate = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function PutProductsInStorage()
	
	// Forming a table to return to the document.
	SelectedGoodsTable = ServicesTable.Unload(New Structure("RowIsSelected", True));
	
	// Formation of a discount table for returning to the document.
	TableOfSelectedDiscountsMargins = TableDiscountsMarkups.Unload(New Structure("ConnectionKey", -1));
	TheStructureOfTheSearch = New Structure("ConnectionKey");
	For Each RowOfGoods In SelectedGoodsTable Do
		
		TheStructureOfTheSearch.ConnectionKey = RowOfGoods.ConnectionKey;
		For Each DiscountsRow In TableDiscountsMarkups.FindRows(TheStructureOfTheSearch) Do
			
			FillPropertyValues(TableOfSelectedDiscountsMargins.Add(), DiscountsRow);
			
		EndDo;
		
	EndDo;
	
	GoodsAddressInStorage = PutToTempStorage(
		New Structure("Goods, DiscountsMarkups", SelectedGoodsTable, TableOfSelectedDiscountsMargins));
	
	Return GoodsAddressInStorage;
	
EndFunction

&AtServer
Procedure FillInTableOfServices(SalesOrder,Document, DocumentCurrency, AnArrayOfOrders)
	
	SelectionData_ = New Structure();
	SelectionData_.Insert("Partner",                 Parameters.Partner);
	SelectionData_.Insert("Counterparty",              Parameters.Counterparty);
	SelectionData_.Insert("Contract",                 Parameters.Contract);
	SelectionData_.Insert("Organization",             Parameters.Organization);
	SelectionData_.Insert("Terms",              Parameters.Terms);
	SelectionData_.Insert("Currency",                  Parameters.DocumentCurrency);
	SelectionData_.Insert("ARAPCurrency",    Parameters.ARAPCurrency);
	SelectionData_.Insert("VATTaxation",      Parameters.VATTaxation);
	SelectionData_.Insert("PriceIncludesVAT",         Parameters.PriceIncludesVAT);
	SelectionData_.Insert("Ref",                  Parameters.Document);
	SelectionData_.Insert("SalesOpportunity",                  Parameters.SalesOpportunity);
	SelectionData_.Insert("Date",                    Parameters.Date);
	SelectionData_.Insert("ARAPObjectSettings",         Parameters.ARAPObjectSettings);
	SelectionData_.Insert("LineOfBusiness", Parameters.LineOfBusiness);
	SelectionData_.Insert("Department",           Parameters.Department);
	
	FillParameters = New Structure;
	FillParameters.Insert("UseAdvancedFeaturesOfSalesOrder", Parameters.UseAdvancedFeaturesOfSalesOrder);
	FillParameters.Insert("DisplayMessage_1", False);
	FillParameters.Insert("CheckOrderOfCalculations", False);
	
	Documents.CustomerInvoiceServices.FillByOrderBalances(
		SelectionData_,
		ServicesTable,
		TableDiscountsMarkups,
		TableAccrualOfBonusPoints,
		Undefined,
		FillParameters);
	
	OrdersServer.SetSignsOfPresenceOfLineInDocument(ServicesTable, "SalesOrder", Parameters.ArrayOfStringCodes);
	FillInOrderDataFromReport();
	ByOrdersOnChange();
	
EndProcedure

#EndRegion

#EndRegion
