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
	
	FillInTheGoodsTable();
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Parameters.Document);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If Not ClosingInProgress And Modified And Not Exit Then
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), 
			NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
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
		If Field.Name = "TableOfGoodsPurchaseOrder" Then
			ShowValue(Undefined, Items.TableOfGoods.CurrentData.PurchaseOrder);
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
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsPurchaseOrder.Name);

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
	SelectionData_.Insert("Terms",            Parameters.Terms);
	SelectionData_.Insert("Currency",                Parameters.DocumentCurrency);
	SelectionData_.Insert("ARAPCurrency",  Parameters.ARAPCurrency);
	SelectionData_.Insert("VATTaxation",    Parameters.VATTaxation);
	SelectionData_.Insert("PriceIncludesVAT",       Parameters.PriceIncludesVAT);
	SelectionData_.Insert("Warehouse",                 Parameters.Warehouse);
	SelectionData_.Insert("DocumentBasis",     Parameters.DocumentBasis);
	SelectionData_.Insert("SalesOpportunity",                Parameters.SalesOpportunity);
	SelectionData_.Insert("Date",                  Parameters.Date);
	
	If Not ValueIsFilled(Parameters.PurchaseOrder) Or GetFunctionalOption("UseReceiptForMultipleOrders") Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(Parameters.PurchaseOrder);
	EndIf;
	
	FillByOrderBalances(
		SelectionData_,
		TableOfGoods,
		Parameters.Warehouse,
		AnArrayOfOrders);
	
	OrdersServer.SetSignsOfPresenceOfLineInDocument(TableOfGoods, "PurchaseOrder", Parameters.ArrayOfStringCodes);
	
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
	                                 WarehouseForReceipt,
	                                 AnArrayOfOrders=Undefined)
	
	// Data on the remaining items of the order.
	SampleProducts_ = GetQueryResultsForOrderBalances(
		SelectionData_,
		WarehouseForReceipt,
		AnArrayOfOrders
	).Select();
	
	ArrayOfOrdersToSupplier = New Array();
	
	While SampleProducts_.Next() Do
		If ArrayOfOrdersToSupplier.Find(SampleProducts_.PurchaseOrder) = Undefined Then
			ArrayOfOrdersToSupplier.Add(SampleProducts_.PurchaseOrder);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("ArrayOfOrdersToSupplier", ArrayOfOrdersToSupplier);
	Query.SetParameter("DocumentCurrency", SelectionData_.Currency);
		
	Query.Text =
	"
	|SELECT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Ref                    AS PurchaseOrder,
	|	TheOrdersTable.Currency                    AS Currency,
	|	TheOrdersTable.PriceIncludesVAT           AS PriceIncludesVAT,
	|	CASE
	|		WHEN
	|			TheOrdersTable.Currency <> &DocumentCurrency
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ConvertToDocumentCurrency
	|FROM
	|	Document.PurchaseOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN (&ArrayOfOrdersToSupplier)
	|;
	|SELECT DISTINCT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Currency                    AS Currency,
	|	TheOrdersTable.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.PurchaseOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN (&ArrayOfOrdersToSupplier)
	|	AND TheOrdersTable.Currency <> &DocumentCurrency
	|
	|";
	
	QueryResultsArray = Query.ExecuteBatch();
	
	ResultOrderDetails = QueryResultsArray[0]; // QueryResult
	ResultSelection = QueryResultsArray[1]; // QueryResult
	
	OrderDetails_ = ResultOrderDetails.Select();
	
	TableOfExchangeRates = New ValueTable;
	TableOfExchangeRates.Columns.Add("Currency",    New TypeDescription("CatalogRef.Currencies"));
	TableOfExchangeRates.Columns.Add("Date",      New TypeDescription("Date"));
	TableOfExchangeRates.Columns.Add("CourseNumerator",      New TypeDescription("Number"));
	TableOfExchangeRates.Columns.Add("CourseDenominator", New TypeDescription("Number"));
	
	Selection = ResultSelection.Select();
	
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
		
		AmountsMustBeRecalculated = (SampleProducts_.Count<>SampleProducts_.QuantityByOrder);
		
		TabRow = Goods.Add();
		FillPropertyValues(TabRow, SampleProducts_);
		
		TabRow.Count = SampleProducts_.Count;
		TabRow.NumberOfPackages = SampleProducts_.Count / SampleProducts_.ZoomRatio;
		
		OrderDetails_.Reset();
		OrderFound = OrderDetails_.FindNext(TabRow.PurchaseOrder, "PurchaseOrder");
		
		If OrderFound Then
			
			If OrderDetails_.ConvertToDocumentCurrency Then
				
				FilterParameters = New Structure("Currency,Date", OrderDetails_.Currency, OrderDetails_.Date);
				CurrencyExchangeRate = TableOfExchangeRates.FindRows(FilterParameters);
				
				If CurrencyExchangeRate.Count() = 1 Then
					
					TabRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
							TabRow.Price,
							CurrencyExchangeRate[0],
							StructureOfNewCurrencyRates);
					AmountsMustBeRecalculated = True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If AmountsMustBeRecalculated Then
			
			PriceManagementSystem.RecalculateAmountsInRow(TabRow, False, False, True, OrderDetails_.PriceIncludesVAT);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function GetQueryResultsForOrderBalances(SelectionData_,
	                                              WarehouseForReceipt = Undefined,
	                                              AnArrayOfOrders = Undefined)

	QueryText =
	"SELECT
	|	OrdersTable.PurchaseOrder        AS PurchaseOrder,
	|	OrdersTable.Products           AS Products,
	|	OrdersTable.Characteristic         AS Characteristic,
	|	OrdersTable.RowCode              AS RowCode,
	|	OrdersTable.Warehouse                  AS Warehouse,
	|	SUM(OrdersTable.ToRegister)     AS Count
	|
	|INTO TableBalance
	|
	|FROM
	|	(SELECT
	|		OrdersBalance.PurchaseOrder        AS PurchaseOrder,
	|		OrdersBalance.Products           AS Products,
	|		OrdersBalance.Characteristic         AS Characteristic,
	|		OrdersBalance.RowCode              AS RowCode,
	|		OrdersBalance.Warehouse                  AS Warehouse,
	|		OrdersBalance.ToRegisterBalance     AS ToRegister
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Balance(,
	|				CASE WHEN &SelectByOrder_ THEN
	|					PurchaseOrder IN (&AnArrayOfOrders)
	|				ELSE
	|					PurchaseOrder.Partner = &Partner
	|					AND PurchaseOrder.Counterparty = &Counterparty
	|					AND PurchaseOrder.Contract = &Contract
	|					AND PurchaseOrder.Organization = &Organization
	|					AND PurchaseOrder.BusinessOperation = &BusinessOperation
	|					AND PurchaseOrder.Terms = &Terms
	|					AND PurchaseOrder.Currency = &ARAPCurrency
	|					AND PurchaseOrder.VATTaxation = &VATTaxation
	|					AND PurchaseOrder.PriceIncludesVAT = &PriceIncludesVAT
	|				END
	|				AND
	|				CASE
	|					WHEN
	|						CAST(&WarehouseForReceipt AS Catalog.Warehouses).IsFolder
	|					THEN
	|						Warehouse IN HIERARCHY (&WarehouseForReceipt) OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|					ELSE
	|						Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &WarehouseForReceipt)
	|				END
	|			) AS OrdersBalance
	|
	|	UNION ALL
	|
	|	SELECT
	|		TrafficOrders.PurchaseOrder,
	|		TrafficOrders.Products,
	|		TrafficOrders.Characteristic,
	|		TrafficOrders.RowCode,
	|		TrafficOrders.Warehouse,
	|		CASE WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-TrafficOrders.ToRegister
	|			ELSE
	|				TrafficOrders.ToRegister
	|		END
	|	FROM
	|		AccumulationRegister.PurchaseOrders AS TrafficOrders
	|	WHERE
	|		(TrafficOrders.Recorder = &DocumentBasis
	|		OR TrafficOrders.Recorder IN (SELECT
	|							AdjustingEntries.Ref
	|						FROM
	|							Document.PurchaseAdjustment AS AdjustingEntries
	|						WHERE
	|							AdjustingEntries.DocumentBasis = &DocumentBasis
	|							AND AdjustingEntries.Posted))
	|		AND CASE WHEN &SelectByOrder_ THEN
	|			TrafficOrders.PurchaseOrder IN (&AnArrayOfOrders)
	|		ELSE
	|			TrafficOrders.PurchaseOrder.Partner = &Partner
	|			AND TrafficOrders.PurchaseOrder.Counterparty = &Counterparty
	|			AND TrafficOrders.PurchaseOrder.Contract = &Contract
	|			AND TrafficOrders.PurchaseOrder.Organization = &Organization
	|			AND TrafficOrders.PurchaseOrder.BusinessOperation = &BusinessOperation
	|			AND TrafficOrders.PurchaseOrder.Terms = &Terms
	|			AND TrafficOrders.PurchaseOrder.Currency = &ARAPCurrency
	|			AND TrafficOrders.PurchaseOrder.VATTaxation = &VATTaxation
	|			AND TrafficOrders.PurchaseOrder.PriceIncludesVAT = &PriceIncludesVAT
	|		END
	|		AND TrafficOrders.Active
	|				AND CASE
	|					WHEN
	|						CAST(&WarehouseForReceipt AS Catalog.Warehouses).IsFolder
	|					THEN
	|						TrafficOrders.Warehouse IN HIERARCHY (&WarehouseForReceipt) OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|					ELSE
	|						TrafficOrders.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &WarehouseForReceipt)
	|				END
	|
	|	) AS OrdersTable
	|	
	|	GROUP BY
	|		OrdersTable.PurchaseOrder,
	|		OrdersTable.Products,
	|		OrdersTable.Characteristic,
	|		OrdersTable.RowCode,
	|		OrdersTable.Warehouse
	|	
	|	HAVING
	|		SUM(OrdersTable.ToRegister) > 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableBalance.PurchaseOrder           AS PurchaseOrder,
	|	TableBalance.Products              AS Products,
	|	TableBalance.Characteristic            AS Characteristic,
	|	TableBalance.RowCode                 AS RowCode,
	|	TableBalance.Count                AS Count,
	|	TableBalance.Warehouse                     AS Warehouse,
	|	OrderingProducts.Ref.SalesOpportunity                AS SalesOpportunity,
	|	OrderingProducts.ExpenseItem               AS ExpenseItem,
	|	OrderingProducts.DimensionOfExpenses            AS DimensionOfExpenses,
	|	OrderingProducts.DateOfReceipt              AS DateOfReceipt,
	|	OrderingProducts.Package                     AS Package,
	|	OrderingProducts.VendorPriceKind            AS VendorPriceKind,
	|	OrderingProducts.Count                   AS QuantityByOrder,
	|	OrderingProducts.Price                         AS Price,
	|	OrderingProducts.VATRate                    AS VATRate,
	|	OrderingProducts.Sum                        AS Sum,
	|	OrderingProducts.VATAmount                     AS VATAmount,
	|	OrderingProducts.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	OrderingProducts.PercentRateOfManualDiscount          AS PercentRateOfManualDiscount,
	|	OrderingProducts.ManualDiscount            AS ManualDiscount,
	|	OrderingProducts.Products.ItemsType AS ItemsType,
	|	OrderingProducts.PartnerProducts       AS PartnerProducts,
	|	CASE WHEN OrderingProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END                                    AS ZoomRatio
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.PurchaseOrder.Goods AS OrderingProducts
	|		ON  TableBalance.Products     = OrderingProducts.Products
	|			AND TableBalance.Characteristic = OrderingProducts.Characteristic
	|			AND TableBalance.RowCode      = OrderingProducts.RowCode
	|			AND TableBalance.PurchaseOrder = OrderingProducts.Ref
	|
	|ORDER BY
	|	TableBalance.PurchaseOrder,
	|	OrderingProducts.LineNumber,
	|	TableBalance.Products,
	|	TableBalance.Characteristic,
	|	TableBalance.Warehouse,
	|	OrderingProducts.DateOfReceipt";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OrderingProducts.Package",
		"OrderingProducts.Products"));

	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("AnArrayOfOrders",         AnArrayOfOrders);
	Query.SetParameter("Partner",               SelectionData_.Partner);
	Query.SetParameter("Counterparty",            SelectionData_.Counterparty);
	Query.SetParameter("Contract",               SelectionData_.Contract);
	Query.SetParameter("Organization",           SelectionData_.Organization);
	Query.SetParameter("BusinessOperation", Common.ObjectAttributeValue(SelectionData_.DocumentBasis, "BusinessOperation"));
	Query.SetParameter("Terms",            SelectionData_.Terms);
	Query.SetParameter("ARAPCurrency",  SelectionData_.ARAPCurrency);
	Query.SetParameter("VATTaxation",    SelectionData_.VATTaxation);
	Query.SetParameter("PriceIncludesVAT",       SelectionData_.PriceIncludesVAT);
	Query.SetParameter("DocumentBasis",     SelectionData_.DocumentBasis);
	Query.SetParameter("WarehouseForReceipt",      WarehouseForReceipt);
	Query.SetParameter("SelectByOrder_",      AnArrayOfOrders <> Undefined);
	
	SetPrivilegedMode(True);
	Return Query.Execute();

EndFunction

ClosingInProgress = False;

#EndRegion
