#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

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
	
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	Items.TableOfGoodsDepartment.Visible = UseBusinessUnits;
	If Parameters.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		Items.TableOfGoodsSalesOrder.Title = "ReferenceOrder";
	EndIf;
	
	FillInTheGoodsTable();
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Parameters.Document);
	
	ObjectParameters = New Structure(Documents.SaleAdjustment.NamesOfDetailsForFillingInParametersForSpecifyingSeries());
	FillPropertyValues(ObjectParameters, Parameters);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ObjectParameters, Documents.SaleAdjustment);
	Items.TableOfGoodsSeries.Visible = SeriesSpecificationParameters.Goods.UseCostAccountingByBatches;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ClosingInProgress = False;

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If Not ClosingInProgress And Modified And Not Exit Then
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
																						|ru = 'Данные были изменены. Перенести изменения в документ?';
																						|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
																						|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
																						|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
																						|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'"), QuestionDialogMode.YesNoCancel);

	EndIf;

EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		Modified = False;
		MoveProductsToDocument();
		
	ElsIf Response = DialogReturnCode.No Then
		ClosingInProgress = True;
		Modified = False;
		Close();
		
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure TableOfGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.TableOfGoods.CurrentData <> Undefined Then
		If Field.Name = "TableOfGoodsSalesOrder" Then
			ShowValue(Undefined, Items.TableOfGoods.CurrentData.SalesOrder);
		EndIf;
	EndIf;
	
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
	ItemField.Field = New DataCompositionField(Items.TableOfGoods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.ExistsInTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsAmountIncludingVAT.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceIncludesVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsVATAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsAmountIncludingVAT.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsVATRate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;

	Item.Appearance.SetParameterValue("Visible", False);

EndProcedure

&AtServer
Procedure SelectAllProductsOnServer(SelectionValue = True)
	
	For Each TableRow In TableOfGoods.FindRows(New Structure("RowIsSelected", Not SelectionValue)) Do
		
		TableRow.RowIsSelected = SelectionValue;
		
	EndDo;
	
EndProcedure

&AtServer
Function PutProductsInStorage()

	// Forming a table to return to the document.
	SelectedGoodsTable = TableOfGoods.Unload(New Structure("RowIsSelected", True));

	GoodsAddressInStorage = PutToTempStorage(SelectedGoodsTable);

	Return GoodsAddressInStorage;

EndFunction

&AtServer
Procedure FillInTheGoodsTable()
	
	SelectionData_ = New Structure();
	SelectionData_.Insert("Partner",               Parameters.Partner);
	SelectionData_.Insert("Counterparty",            Parameters.Counterparty);
	SelectionData_.Insert("Contract",               Parameters.Contract);
	SelectionData_.Insert("Organization",           Parameters.Organization);
	SelectionData_.Insert("BusinessOperation", Parameters.BusinessOperation);
	SelectionData_.Insert("Terms",            Parameters.Terms);
	SelectionData_.Insert("Currency",                Parameters.DocumentCurrency);
	SelectionData_.Insert("ARAPCurrency",  Parameters.ARAPCurrency);
	SelectionData_.Insert("VATTaxation",    Parameters.VATTaxation);
	SelectionData_.Insert("PriceIncludesVAT",       Parameters.PriceIncludesVAT);
	SelectionData_.Insert("Warehouse",                 Parameters.Warehouse);
	SelectionData_.Insert("DocumentBasis",     Parameters.DocumentBasis);
	SelectionData_.Insert("SalesOpportunity",                Parameters.SalesOpportunity);
	SelectionData_.Insert("Date",                  Parameters.Date);
	
	If Not ValueIsFilled(Parameters.SalesOrder) Or GetFunctionalOption("UseSaleByMultipleOrders") Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(Parameters.SalesOrder);
	EndIf;
	
	FillByOrderBalances(
		SelectionData_,
		TableOfGoods,
		Parameters.Warehouse,
		AnArrayOfOrders);
	
	OrdersServer.SetSignsOfPresenceOfLineInDocument(TableOfGoods, "SalesOrder", Parameters.ArrayOfStringCodes);
	
EndProcedure

&AtClient
Procedure MoveProductsToDocument()

	// Removal of modification, because before closing, the attribute is checked.
	Modified = False;

	GoodsAddressInStorage = PutProductsInStorage();

	Close();

	NotifyChoice(New Structure("GoodsAddressInStorage", GoodsAddressInStorage));

EndProcedure

&AtServer
Procedure FillByOrderBalances(SelectionData_,
	                                 Goods,
	                                 ImplementationWarehouse,
	                                 AnArrayOfOrders=Undefined)
	
	// Data on the remaining items of the order
	SampleProducts_ = GetQueryResultsForOrderBalances(
		SelectionData_,
		ImplementationWarehouse,
		AnArrayOfOrders
	).Select();
	
	ArrayOfCustomersOrders = New Array();
	
	While SampleProducts_.Next() Do
		If ArrayOfCustomersOrders.Find(SampleProducts_.SalesOrder) = Undefined Then
			ArrayOfCustomersOrders.Add(SampleProducts_.SalesOrder);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("ArrayOfCustomersOrders", ArrayOfCustomersOrders);
	Query.SetParameter("DocumentCurrency",       SelectionData_.Currency);
		
	Query.Text =
	"SELECT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Ref AS SalesOrder,
	|	TheOrdersTable.Currency AS Currency,
	|	TheOrdersTable.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN TheOrdersTable.Currency <> &DocumentCurrency
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConvertToDocumentCurrency
	|FROM
	|	Document.SalesOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY),
	|	TheOrdersTable.Ref,
	|	TheOrdersTable.Currency,
	|	TheOrdersTable.PriceIncludesVAT,
	|	CASE
	|		WHEN TheOrdersTable.Currency <> &DocumentCurrency
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Ref AS SalesOrder,
	|	TheOrdersTable.Currency AS Currency,
	|	TRUE AS PriceIncludesVAT,
	|	CASE
	|		WHEN TheOrdersTable.Currency <> &DocumentCurrency
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConvertToDocumentCurrency
	|FROM
	|	Document.GoodsShipmentToCustomer AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(TableEnteringBalances.Lot.Date, DAY) AS Date,
	|	TableEnteringBalances.Lot AS SalesOrder,
	|	TableEnteringBalances.Lot.Currency AS Currency,
	|	TableEnteringBalances.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN TableEnteringBalances.Lot.Currency <> &DocumentCurrency
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConvertToDocumentCurrency
	|FROM
	|	Document.OBEntryGoods AS TableEnteringBalances
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableEnteringBalances.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	TableEnteringBalances.Posted
	|	AND TableEnteringBalances.Lot IN(&ArrayOfCustomersOrders)
	|	AND DocumentsRegistry.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BEGINOFPERIOD(CombinedOrderTable.Date, DAY) AS Date,
	|	CombinedOrderTable.Currency AS Currency,
	|	CombinedOrderTable.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|		TheOrdersTable.Currency AS Currency,
	|		TheOrdersTable.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|	FROM
	|		Document.SalesOrder AS TheOrdersTable
	|	WHERE
	|		TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|		AND TheOrdersTable.Currency <> &DocumentCurrency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(TheOrdersTable.Date, DAY),
	|		TheOrdersTable.Currency,
	|		TheOrdersTable.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer AS TheOrdersTable
	|	WHERE
	|		TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|		AND TheOrdersTable.Currency <> &DocumentCurrency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(TheOrdersTable.Date, DAY),
	|		TheOrdersTable.Currency,
	|		TheOrdersTable.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|	FROM
	|		Document.GoodsShipmentToCustomer AS TheOrdersTable
	|	WHERE
	|		TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|		AND TheOrdersTable.Currency <> &DocumentCurrency
	|
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(TheOrdersTable.Date, DAY),
	|		TheOrdersTable.Currency,
	|		TheOrdersTable.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|	FROM
	|		Document.SourceDocument AS TheOrdersTable
	|	WHERE
	|		TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|		AND TheOrdersTable.Currency <> &DocumentCurrency) AS CombinedOrderTable";
	
	ResultsArray = Query.ExecuteBatch();
	
	ResultOrderDetails = ResultsArray[0]; // QueryResult
	QueryResult = ResultsArray[1]; // QueryResult
	
	OrderDetails_ = ResultOrderDetails.Select();
	
	TableOfExchangeRates = New ValueTable;
	TableOfExchangeRates.Columns.Add("Currency",    New TypeDescription("CatalogRef.Currencies"));
	TableOfExchangeRates.Columns.Add("Date",      New TypeDescription("Date"));
	TableOfExchangeRates.Columns.Add("CourseNumerator", New TypeDescription("Number"));
	TableOfExchangeRates.Columns.Add("CourseDenominator", New TypeDescription("Number"));
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		NewRow = TableOfExchangeRates.Add();
		FillPropertyValues(NewRow, Selection);
		
		Currency_Rates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Selection.Currency, Selection.Date, Selection.LocalAccountingCurrency);
		NewRow.CourseNumerator = Currency_Rates.CourseNumerator;
		NewRow.CourseDenominator = Currency_Rates.CourseDenominator;
		
	EndDo;
	
	If TableOfExchangeRates.Count() > 0 Then
		StructureOfNewCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(SelectionData_.Currency, CurrentSessionDate(),
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SelectionData_.Organization));
	EndIf;
	
	SampleProducts_.Reset();
	While SampleProducts_.Next() Do
		
		RecalculateAmounts = (SampleProducts_.Count <> SampleProducts_.QuantityInOrder);
		RecalculateVATRate = SelectionData_.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")
			And SampleProducts_.RowCode = 0
			And Not ValueIsFilled(SampleProducts_.VATRate);
		
		ExcludeProperties_ = Undefined;
		If RecalculateAmounts Then
			// If it is necessary to recalculate the amounts, then the Attributes listed in the will be recalculated based on the amount of mutual settlements.
			ExcludeProperties_ = "Sum, VATAmount";
		EndIf;
		
		TabRow = Goods.Add();
		FillPropertyValues(TabRow, SampleProducts_, , ExcludeProperties_);
		
		If RecalculateAmounts Then
			
			TabRow.AmountIncludingVAT = TabRow.AmountARAP;
			
			TabRow.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(TabRow.AmountIncludingVAT,
																			TabRow.VATRate,
																			True,
																			VATTaxation);
			
			TabRow.Sum = TabRow.AmountIncludingVAT - TabRow.VATAmount;
			
		EndIf;
		
		TabRow.NumberOfPackages = SampleProducts_.Count / SampleProducts_.ZoomRatio;
		
		If RecalculateVATRate Then
			
			TabRow.VATRate = VATAccountingERP.VATRateForProductsAndTaxation(
				SampleProducts_.Products,
				SelectionData_.VATTaxation,
				SelectionData_.Organization,
				SelectionData_.Date,
				, True);
		
		EndIf;
		
		OrderDetails_.Reset();
		OrderFound = OrderDetails_.FindNext(TabRow.SalesOrder, "SalesOrder");
		
		FilterParameters = New Structure("Currency,Date", OrderDetails_.Currency, OrderDetails_.Date);
		CurrencyExchangeRate = TableOfExchangeRates.FindRows(FilterParameters);
		
		If OrderFound And OrderDetails_.ConvertToDocumentCurrency Then
			
			If CurrencyExchangeRate.Count() = 1 Then
				
				TabRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.Price,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				TabRow.AmountIncludingVAT = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.AmountIncludingVAT,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				RecalculateAmounts = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function GetQueryResultsForOrderBalances(SelectionData_,
	                                              ImplementationWarehouse = Undefined,
	                                              AnArrayOfOrders = Undefined)

	ThisIsTransferOfOwnership2_5 =
		(SelectionData_.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);

	Query = New Query;
	
	Query.SetParameter("AnArrayOfOrders",         AnArrayOfOrders);
	Query.SetParameter("Partner",               SelectionData_.Partner);
	Query.SetParameter("Counterparty",            SelectionData_.Counterparty);
	Query.SetParameter("Contract",               SelectionData_.Contract);
	Query.SetParameter("Organization",           SelectionData_.Organization);
	Query.SetParameter("SalesOpportunity",                SelectionData_.SalesOpportunity);
	Query.SetParameter("BusinessOperation", ValidOperations());
	Query.SetParameter("Terms",            SelectionData_.Terms);
	Query.SetParameter("ARAPCurrency",  SelectionData_.ARAPCurrency);
	Query.SetParameter("VATTaxation",    SelectionData_.VATTaxation);
	Query.SetParameter("PriceIncludesVAT",       SelectionData_.PriceIncludesVAT);
	Query.SetParameter("DocumentBasis",     SelectionData_.DocumentBasis);
	Query.SetParameter("ImplementationWarehouse",       ImplementationWarehouse);
	Query.SetParameter("SelectByOrder_",      AnArrayOfOrders <> Undefined);
	Query.SetParameter("ThisIsTransferOfOwnership2_5", ThisIsTransferOfOwnership2_5);
	Query.SetParameter(
		"ToUseTermsOfSales",
		Not SelectionData_.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider And
		GetFunctionalOption("ToUseTermsOfSales"));
	
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	Table.Ref AS ReferenceOrder
	|INTO TT_Orders
	|FROM
	|	Document.SalesOrder AS Table
	|		INNER JOIN Document.SalesOrder.Goods AS TableOfGoods
	|		ON Table.Ref = TableOfGoods.Ref
	|WHERE
	|	Table.Posted
	|	AND Table.Partner = &Partner
	|	AND Table.Counterparty = &Counterparty
	|	AND Table.Contract = &Contract
	|	AND Table.Organization = &Organization
	|	AND Table.BusinessOperation IN(&BusinessOperation)
	|	AND CASE
	|		WHEN NOT &ToUseTermsOfSales
	|			THEN TRUE
	|		ELSE
	|			Table.Terms = &Terms
	|	END
	|	AND Table.SalesOpportunity = &SalesOpportunity
	|	AND Table.Currency = &ARAPCurrency
	|	AND CASE
	|		WHEN Table.VATTaxation IN
	|			(VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
	|			VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|		ELSE
	|			Table.VATTaxation
	|	END = &VATTaxation
	|	AND Table.PriceIncludesVAT = &PriceIncludesVAT
	|	AND CASE
	|		WHEN &ThisIsTransferOfOwnership2_5
	|			THEN TRUE
	|		WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|			THEN TableOfGoods.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|		ELSE TableOfGoods.Warehouse = &ImplementationWarehouse
	|	END
	|	AND TableOfGoods.Products.SaleRegistrationOption IN
	|		(VALUE(Enum.SalesRegistrationOptions.CustomerInvoice),
	|		VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Table.Ref AS ReferenceOrder
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS Table
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS TableOfGoods
	|		ON Table.Ref = TableOfGoods.Ref
	|WHERE
	|	Table.Posted
	|	AND Table.Partner = &Partner
	|	AND Table.Counterparty = &Counterparty
	|	AND Table.Contract = &Contract
	|	AND Table.Organization = &Organization
	|	AND Table.BusinessOperation IN(&BusinessOperation)
	|	AND CASE
	|		WHEN NOT &ToUseTermsOfSales
	|			THEN TRUE
	|		ELSE
	|			Table.Terms = &Terms
	|	END
	|	AND Table.SalesOpportunity = &SalesOpportunity
	|	AND Table.Currency = &ARAPCurrency
	|	AND CASE
	|		WHEN Table.VATTaxation IN
	|			(VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
	|			VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|		ELSE
	|			Table.VATTaxation
	|	END = &VATTaxation
	|	AND Table.PriceIncludesVAT = &PriceIncludesVAT
	|	AND CASE
	|		WHEN &ThisIsTransferOfOwnership2_5
	|			THEN TRUE
	|		WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|			THEN TableOfGoods.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|		ELSE
	|			TableOfGoods.Warehouse = &ImplementationWarehouse
	|	END
	|	AND TableOfGoods.Products.SaleRegistrationOption IN
	|		(VALUE(Enum.SalesRegistrationOptions.CustomerInvoice),
	|		VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Table.Ref AS ReferenceOrder
	|FROM
	|	Document.MaterialProviderOrder2_5 AS Table
	|		INNER JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS TableOfGoods
	|		ON Table.Ref = TableOfGoods.Ref
	|WHERE
	|	Table.Posted
	|	AND Table.Partner = &Partner
	|	AND Table.Counterparty = &Counterparty
	|	AND Table.Contract = &Contract
	|	AND Table.Organization = &Organization
	|	AND Table.BusinessOperation IN(&BusinessOperation)
	|	AND Table.SalesOpportunity = &SalesOpportunity
	|	AND Table.Currency = &ARAPCurrency
	|	AND CASE
	|		WHEN Table.VATTaxation IN
	|			(VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
	|			VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|		ELSE
	|			Table.VATTaxation
	|	END = &VATTaxation
	|	AND Table.PriceIncludesVAT = &PriceIncludesVAT
	|	AND CASE
	|		WHEN &ThisIsTransferOfOwnership2_5
	|			THEN FALSE
	|		WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|			THEN TableOfGoods.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|		ELSE
	|			TableOfGoods.Warehouse = &ImplementationWarehouse
	|	END
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CASE
	|		WHEN Table.Patch
	|			THEN Table.CorrectedDocument
	|		ELSE
	|			Table.Ref
	|	END AS ReferenceOrder
	|FROM
	|	Document.GoodsShipmentToCustomer AS Table
	|WHERE
	|	Table.Posted
	|	AND Table.Partner = &Partner
	|	AND Table.Counterparty = &Counterparty
	|	AND Table.Contract = &Contract
	|	AND Table.Organization = &Organization
	|	AND Table.BusinessOperation IN (&BusinessOperation)
	|	AND CASE
	|		WHEN NOT &ToUseTermsOfSales
	|			THEN TRUE
	|		ELSE Table.Terms = &Terms
	|	END
	|	AND Table.SalesOpportunity = &SalesOpportunity
	|	AND Table.Currency = &ARAPCurrency
	|	AND CASE
	|		WHEN Table.VATTaxation IN
	|			(VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
	|			VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|		ELSE
	|			Table.VATTaxation
	|	END = &VATTaxation
	|	AND &PriceIncludesVAT = TRUE
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Table.Lot AS ReferenceOrder
	|FROM
	|	Document.OBEntryGoods AS Table
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON Table.Ref = DocumentsRegistry.ReversedDocument
	|		AND DocumentsRegistry.Posted
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	Table.Posted
	|	AND Table.Organization = &Organization
	|	AND Table.Partner = &Partner
	|	AND Table.Counterparty = &Counterparty
	|	AND Table.Contract = &Contract
	|	AND CASE
	|		WHEN &ThisIsTransferOfOwnership2_5
	|			THEN TRUE
	|		WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|			THEN Table.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|		ELSE
	|			Table.Warehouse = &ImplementationWarehouse
	|	END
	|	AND Table.Currency = &ARAPCurrency
	|	AND Table.BusinessOperation IN(&BusinessOperation)
	|	AND Table.Lot <> VALUE(Document.SourceDocument.EmptyRef)
	|	AND CASE
	|		WHEN Table.VATTaxation IN(
	|			VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
	|			VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|			)
	|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|		ELSE
	|			Table.VATTaxation
	|	END = &VATTaxation
	|	AND DocumentsRegistry.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder AS SalesOrder,
	|	OrdersTable.Products AS Products,
	|	OrdersTable.Characteristic AS Characteristic,
	|	OrdersTable.RowCode AS RowCode,
	|	OrdersTable.Warehouse AS Warehouse,
	|	OrdersTable.Series AS Series,
	|	SUM(OrdersTable.ToRegister) AS Count,
	|	SUM(OrdersTable.Sum) AS Sum
	|INTO TableBalance
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|		TurnoversByOrders.Products AS Products,
	|		TurnoversByOrders.Characteristic AS Characteristic,
	|		TurnoversByOrders.RowCode AS RowCode,
	|		TurnoversByOrders.Warehouse AS Warehouse,
	|		TurnoversByOrders.Series AS Series,
	|		TurnoversByOrders.ShippedQuantityTurnover
	|			- TurnoversByOrders.QuantityToBeShippedTurnover AS ToRegister,
	|		TurnoversByOrders.ShippedAmountTurnover
	|			- TurnoversByOrders.AmountToBeShippedTurnover AS Sum
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded1 AS TurnoversByOrders
	|	WHERE
	|		NOT &ThisIsTransferOfOwnership2_5
	|		AND (TurnoversByOrders.ShippedQuantityTurnover
	|			- TurnoversByOrders.QuantityToBeShippedTurnover <> 0
	|			OR TurnoversByOrders.ShippedAmountTurnover
	|				- TurnoversByOrders.AmountToBeShippedTurnover <> 0)
	|	
	|	UNION ALL
	|
	|	SELECT
	|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|		TurnoversByOrders.Products AS Products,
	|		TurnoversByOrders.Characteristic AS Characteristic,
	|		TurnoversByOrders.RowCode AS RowCode,
	|		VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|		MAX(TurnoversByOrders.Series) AS Series,
	|		SUM(TurnoversByOrders.ShippedQuantityTurnover
	|			+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|			- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|			- TurnoversByOrders.QuantityAccepted_Turnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister,
	|		SUM(TurnoversByOrders.ShippedAmountTurnover
	|			+ TurnoversByOrders.RegisteredUpToPPPAmountTurnover
	|			- TurnoversByOrders.DebitedToPPPAmountTurnover
	|			- TurnoversByOrders.AcceptedAmountTurnover
	|			- TurnoversByOrders.IssuedAmountTurnover) AS Sum
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded2 AS TurnoversByOrders
	|	WHERE
	|		&ThisIsTransferOfOwnership2_5
	|	
	|	GROUP BY
	|		TurnoversByOrders.ReferenceOrder,
	|		TurnoversByOrders.Products,
	|		TurnoversByOrders.Characteristic,
	|		TurnoversByOrders.RowCode
	|	
	|	HAVING
	|		SUM(TurnoversByOrders.ShippedQuantityTurnover
	|			+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|			- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|			- TurnoversByOrders.QuantityAccepted_Turnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|		OR SUM(TurnoversByOrders.ShippedAmountTurnover
	|			+ TurnoversByOrders.RegisteredUpToPPPAmountTurnover
	|			- TurnoversByOrders.DebitedToPPPAmountTurnover
	|			- TurnoversByOrders.AcceptedAmountTurnover
	|			- TurnoversByOrders.IssuedAmountTurnover) <> 0
	|
	|	UNION ALL
	|	
	|	SELECT
	|		OrdersRegisterRecords.ReferenceOrder AS SalesOrder,
	|		OrdersRegisterRecords.Products AS Products,
	|		OrdersRegisterRecords.Characteristic AS Characteristic,
	|		OrdersRegisterRecords.RowCode AS RowCode,
	|		OrdersRegisterRecords.Warehouse AS Warehouse,
	|		OrdersRegisterRecords.Series AS Series,
	|		OrdersRegisterRecords.Count AS Count,
	|		OrdersRegisterRecords.Sum AS Sum
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|	WHERE
	|		(OrdersRegisterRecords.Recorder = &DocumentBasis
	|			OR OrdersRegisterRecords.Recorder IN
	|				(SELECT
	|					AdjustingEntries.Ref
	|				FROM
	|					Document.SaleAdjustment AS AdjustingEntries
	|				WHERE
	|					AdjustingEntries.DocumentBasis = &DocumentBasis
	|					AND AdjustingEntries.Posted))
	|		AND OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|		AND CASE
	|			WHEN &SelectByOrder_
	|				THEN OrdersRegisterRecords.ReferenceOrder IN (&AnArrayOfOrders)
	|			ELSE
	|				OrdersRegisterRecords.ReferenceOrder IN
	|					(SELECT
	|						ReferenceOrder
	|					FROM
	|						TT_Orders)
	|		END
	|		AND OrdersRegisterRecords.Active
	|		AND CASE
	|				WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|					THEN OrdersRegisterRecords.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|							OR OrdersRegisterRecords.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				ELSE OrdersRegisterRecords.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
	|			END
	|		AND OrdersRegisterRecords.Products.SaleRegistrationOption IN (VALUE(Enum.SalesRegistrationOptions.CustomerInvoice),
	|						VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer))) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.RowCode,
	|	OrdersTable.Warehouse,
	|	OrdersTable.Series
	|
	|HAVING
	|	SUM(OrdersTable.ToRegister) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsVATRates.Products AS Products,
	|	ProductsVATRates.VATRate AS VATRate
	|INTO ProductsVATRates
	|FROM
	|	InformationRegister.ProductsVATRates.SliceLast(
	|		&Date,
	|		(Country = &RegistrationCountry
	|			OR Country = VALUE(Catalog.WorldCountries.EmptyRef))
	|		AND Products IN (SELECT 
	|								Products 
	|							FROM 
	|								TableBalance)
	|	) AS ProductsVATRates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BasicVATRates.VATRate
	|INTO BasicVATRates
	|FROM
	|	InformationRegister.BasicVATRates.SliceLast(
	|		&Date,
	|		Country = &RegistrationCountry
	|	) AS BasicVATRates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableBalance.SalesOrder AS SalesOrder,
	|	TableBalance.Products AS Products,
	|	TableBalance.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	TableBalance.RowCode AS RowCode,
	|	TableBalance.Count AS Count,
	|	TableBalance.Sum AS AmountARAP,
	|	TableBalance.Warehouse AS Warehouse,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref.SalesOpportunity AS SalesOpportunity,
	|	GoodsTable.DateOfShipment AS DateOfShipment,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.PriceKind AS PriceKind,
	|	GoodsTable.Count AS QuantityInOrder,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATAmount AS VATAmount,
	|	TableBalance.Sum AS AmountIncludingVAT,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END AS ZoomRatio,
	|	TableBalance.Count / ISNULL(&QueryTextPackagingFactor, 1) AS NumberOfPackages,
	|	GoodsTable.DeliveryPeriodDays AS DeliveryPeriodDays
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.SalesOrder.Goods AS GoodsTable
	|		ON TableBalance.Products = GoodsTable.Products
	|			AND TableBalance.Characteristic = GoodsTable.Characteristic
	|			AND TableBalance.RowCode = GoodsTable.RowCode
	|			AND TableBalance.SalesOrder = GoodsTable.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	TableBalance.SalesOrder AS SalesOrder,
	|	TableBalance.Products AS Products,
	|	TableBalance.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	TableBalance.RowCode AS RowCode,
	|	TableBalance.Count AS Count,
	|	TableBalance.Sum AS AmountARAP,
	|	TableBalance.Warehouse AS Warehouse,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref.SalesOpportunity AS SalesOpportunity,
	|	GoodsTable.DateOfShipment AS DateOfShipment,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.PriceKind AS PriceKind,
	|	GoodsTable.Count AS QuantityInOrder,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATAmount AS VATAmount,
	|	TableBalance.Sum AS AmountIncludingVAT,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END AS ZoomRatio,
	|	TableBalance.Count / ISNULL(&QueryTextPackagingFactor, 1) AS NumberOfPackages,
	|	GoodsTable.DeliveryPeriodDays AS DeliveryPeriodDays
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS GoodsTable
	|		ON TableBalance.Products = GoodsTable.Products
	|			AND TableBalance.Characteristic = GoodsTable.Characteristic
	|			AND TableBalance.RowCode = GoodsTable.RowCode
	|			AND TableBalance.SalesOrder = GoodsTable.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	TableBalance.SalesOrder AS SalesOrder,
	|	TableBalance.Products AS Products,
	|	TableBalance.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	TableBalance.RowCode AS RowCode,
	|	TableBalance.Count AS Count,
	|	TableBalance.Sum AS AmountARAP,
	|	TableBalance.Warehouse AS Warehouse,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref.SalesOpportunity AS SalesOpportunity,
	|	GoodsTable.Ref.Date AS DateOfShipment,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.PriceKind AS PriceKind,
	|	GoodsTable.Count AS QuantityInOrder,
	|	GoodsTable.Price AS Price,
	|	&VATRateShipmentOfGoodsWithoutOrder AS VATRate,
	|	GoodsTable.Sum AS Sum,
	|	0 AS VATAmount,
	|	TableBalance.Sum AS AmountIncludingVAT,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END AS ZoomRatio,
	|	TableBalance.Count / ISNULL(&QueryTextPackagingFactor, 1) AS NumberOfPackages,
	|	GoodsTable.DeliveryPeriodDays AS DeliveryPeriodDays
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|		ON TableBalance.Products = GoodsTable.Products
	|			AND TableBalance.Characteristic = GoodsTable.Characteristic
	|			AND TableBalance.RowCode = GoodsTable.RowCode
	|			AND TableBalance.SalesOrder = GoodsTable.Ref
	|	LEFT JOIN ProductsVATRates AS ProductsVATRates
	|		ON ProductsVATRates.Products = GoodsTable.Products
	|	LEFT JOIN BasicVATRates AS BasicVATRates
	|		ON TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	TableBalance.SalesOrder AS SalesOrder,
	|	TableBalance.Products AS Products,
	|	TableBalance.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	TableBalance.RowCode AS RowCode,
	|	TableBalance.Count AS Count,
	|	TableBalance.Sum AS AmountARAP,
	|	TableBalance.Warehouse AS Warehouse,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	GoodsTable.LineNumber AS LineNumber,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	DATETIME(1, 1, 1) AS DateOfShipment,
	|	GoodsTable.Package AS Package,
	|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind,
	|	GoodsTable.Count AS QuantityInOrder,
	|	GoodsTable.Price AS Price,
	|	&VATRateShipmentOfGoodsWithoutOrder AS VATRate,
	|	GoodsTable.Sum AS Sum,
	|	0 AS VATAmount,
	|	TableBalance.Sum AS AmountIncludingVAT,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END AS ZoomRatio,
	|	TableBalance.Count / ISNULL(&QueryTextPackagingFactor, 1) AS NumberOfPackages,
	|	DATETIME(1, 1, 1) AS DeliveryPeriodDays
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.OBEntryGoods.Goods AS GoodsTable
	|		ON TableBalance.Products = GoodsTable.Products
	|			AND TableBalance.Characteristic = GoodsTable.Characteristic
	|			AND TableBalance.RowCode = GoodsTable.RowCode
	|			AND TableBalance.SalesOrder = GoodsTable.Ref
	|	LEFT JOIN ProductsVATRates AS ProductsVATRates
	|		ON ProductsVATRates.Products = GoodsTable.Products
	|	LEFT JOIN BasicVATRates AS BasicVATRates
	|		ON TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	TableBalance.SalesOrder AS SalesOrder,
	|	TableBalance.Products AS Products,
	|	TableBalance.Characteristic AS Characteristic,
	|	MAX(CASE
	|		WHEN GoodsTable.Series IS NOT NULL AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN GoodsTable.Series
	|		WHEN RegistrationOfItems.Series IS NOT NULL AND RegistrationOfItems.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN RegistrationOfItems.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END) AS Series,
	|	TableBalance.RowCode AS RowCode,
	|	MAX(TableBalance.Count) AS Count,
	|	MAX(TableBalance.Sum) AS AmountARAP,
	|	TableBalance.Warehouse AS Warehouse,
	|	MAX(ISNULL(GoodsTable.ProductsInSet, VALUE(Catalog.Products.EmptyRef))) AS ProductsInSet,
	|	MAX(ISNULL(GoodsTable.ItemVariantOfSet, VALUE(Catalog.ItemsCharacteristics.EmptyRef))) AS ItemVariantOfSet,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	MAX(ISNULL(GoodsTable.LineNumber, 0)) AS LineNumber,
	|	MAX(ISNULL(GoodsTable.Ref.SalesOpportunity, RegistrationOfItems.Ref.SalesOpportunity)) AS SalesOpportunity,
	|	MAX(ISNULL(GoodsTable.Ref.Date, RegistrationOfItems.Ref.Date)) AS DateOfShipment,
	|	TableBalance.Products.UnitOfMeasure AS Package,
	|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind,
	|	SUM(ISNULL(GoodsTable.Count, 0) + ISNULL(RegistrationOfItems.Count, 0)) AS QuantityInOrder,
	|	MAX(ISNULL(GoodsTable.Price, RegistrationOfItems.Price)) AS Price,
	|	MAX(CASE
	|		WHEN GoodsTable.Ref IS NULL
	|			THEN VALUE(Catalog.VATRates.EmptyRef)
	|		ELSE
	|			&VATRateShipmentOfGoodsWithoutOrder
	|	END) AS VATRate,
	|	SUM(ISNULL(GoodsTable.Sum, 0) + ISNULL(RegistrationOfItems.Sum, 0)) AS Sum,
	|	0 AS VATAmount,
	|	MAX(TableBalance.Sum) AS AmountIncludingVAT,
	|	TableBalance.Products.ItemsType AS ItemsType,
	|	1 AS ZoomRatio,
	|	MAX(TableBalance.Count) AS NumberOfPackages,
	|	MAX(ISNULL(GoodsTable.DeliveryPeriodDays, 0)) AS DeliveryPeriodDays
	|FROM
	|	TableBalance AS TableBalance
	|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|		ON TableBalance.Products = GoodsTable.Products
	|			AND TableBalance.Characteristic = GoodsTable.Characteristic
	|			AND TableBalance.RowCode = GoodsTable.RowCode
	|			AND GoodsTable.RowCode = 0
	|			AND TableBalance.SalesOrder = GoodsTable.SalesOrder
	|			AND GoodsTable.Ref.Posted
	|	LEFT JOIN Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS RegistrationOfItems
	|		ON TableBalance.Products = RegistrationOfItems.Products
	|			AND TableBalance.Characteristic = RegistrationOfItems.Characteristic
	|			AND TableBalance.SalesOrder = RegistrationOfItems.ReferenceOrder
	|			AND RegistrationOfItems.Ref.Posted
	|	LEFT JOIN ProductsVATRates AS ProductsVATRates
	|		ON ProductsVATRates.Products = TableBalance.Products
	|	LEFT JOIN BasicVATRates AS BasicVATRates
	|		ON TRUE
	|WHERE
	|	TableBalance.RowCode = 0
	|
	|GROUP BY
	|	TableBalance.SalesOrder,
	|	TableBalance.Products,
	|	TableBalance.Characteristic,
	|	TableBalance.RowCode,
	|	TableBalance.Warehouse
	|
	|ORDER BY
	|	TableBalance.SalesOrder,
	|	GoodsTable.LineNumber,
	|	TableBalance.Products,
	|	TableBalance.Characteristic,
	|	TableBalance.Warehouse,
	|	GoodsTable.DateOfShipment
	|";
	
	// ShipmentOrdersTurnoverExpanded1
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"CASE
		|	WHEN &SelectByOrder_
		|		THEN ReferenceOrder IN (&AnArrayOfOrders)
		|	ELSE
		|		ReferenceOrder IN(
		|			SELECT
		|				ReferenceOrder
		|			FROM
		|				TT_Orders)
		|	END
		|	AND CASE
		|		WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|			THEN Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|					OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
		|	END
		|	AND Products.SaleRegistrationOption IN(
		|		VALUE(Enum.SalesRegistrationOptions.CustomerInvoice),
		|		VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer)
		|		)
		|";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip, Shipped";
	TableFormationParameters.Resources = "Count, Sum";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	// ShipmentOrdersTurnoverExpanded2
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"CASE
		|		WHEN &SelectByOrder_
		|			THEN ReferenceOrder IN (&AnArrayOfOrders)
		|		ELSE ReferenceOrder IN
		|			(SELECT
		|				ReferenceOrder
		|			FROM
		|				TT_Orders)
		|	END
		|	AND Products.SaleRegistrationOption IN
		|		(VALUE(Enum.SalesRegistrationOptions.CustomerInvoice),
		|		VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer))";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Series";
	TableFormationParameters.Indicators = "Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Accepted, Issued_1";
	TableFormationParameters.Resources = "Count, Sum";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsTable.Package",
		"GoodsTable.Products"));
	
	Query.Text = StrReplace(Query.Text,
		"&VATRateShipmentOfGoodsWithoutOrder",
		VATAccountingERP.QueryTextVATRate(
			"GoodsTable.Ref.VATTaxation",
			"GoodsTable.Products"));
	
	VATAccountingERP.SetParametersForVATRateRequest(
		Query.Parameters,
		SelectionData_.Organization,
		?(ValueIsFilled(SelectionData_.Date),
			SelectionData_.Date,
			BegOfDay(CurrentSessionDate())));
		
	SetPrivilegedMode(True);
	
	Return Query.Execute();

EndFunction

&AtServer
Function ValidOperations()
	
	TransactionList = New ValueList;
	
	TransactionList.Add(Enums.BusinessTransactions.SaleToCustomer);
	TransactionList.Add(Enums.BusinessTransactions.ReturnFromRetailCustomer);
	TransactionList.Add(Enums.BusinessTransactions.ReturnOfGoodsFromCustomer);
	TransactionList.Add(Enums.BusinessTransactions.GoodsShipmentToCustomer);
	TransactionList.Add(Enums.BusinessTransactions.OBEntryShippedGoods);
	
	Return TransactionList;
	
EndFunction // Valid operations()

#EndRegion
