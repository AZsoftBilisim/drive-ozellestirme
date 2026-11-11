
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Date = Parameters.Date;
	Organization = Parameters.Organization;
	Partner = Parameters.Partner;
	Terms = Parameters.Terms;
	Counterparty = Parameters.Counterparty;
	Contract = Parameters.Contract;
	Currency = Parameters.Currency;
	BeginOfPeriod = Parameters.BeginOfPeriod;
	EndOfPeriod = Parameters.EndOfPeriod;
	VATTaxation = Parameters.VATTaxation;
	ThisIsASalesReport = Parameters.ThisIsASalesReport;
	AddressGoodsInStorage = Parameters.AddressGoodsInStorage;
	
	If Parameters.Property("DocumentSales") Then
		DocumentSales = Parameters.DocumentSales;
		If AccessRight("Read", Metadata.Documents.CustomerInvoice) Then
			Items.DocumentSales.Visible = True;
			Items.PresentationOfSalesDocument.Visible = False;
		Else
			SetPrivilegedMode(True);
			Items.PresentationOfSalesDocument.Title = String(DocumentSales);
			SetPrivilegedMode(False);
			Items.PresentationOfSalesDocument.Visible = True;
			Items.DocumentSales.Visible = False;
		EndIf;
	Else
		Items.SalesDocumentSubmissionGroup.Visible = False;
	EndIf;
	
	If ThisIsASalesReport Then
		FillInProductTableForSalesReport();
	Else
		FillInProductTableForWriteOffReport();
	EndIf;
	
	Items.TableOfGoodsSellingPrice.Visible = ThisIsASalesReport;
	Items.TableOfGoodsSalesAmount.Visible = ThisIsASalesReport;
	Items.TableOfGoodsTaxInvoiceDate.Visible = ThisIsASalesReport;
	Items.TableOfGoodsCustomer.Visible = ThisIsASalesReport;
	Items.TableOfGoodsCustomerInvoiceIssued.Visible = ThisIsASalesReport;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TableOfGoodsNumberOfPackagesOnChange(Item)
	
	TableRow = Items.TableOfGoods.CurrentData;
	TableRow.Selected = (TableRow.NumberOfPackages <> 0);
	TableRow.SalesAmount = TableRow.SellingPrice * TableRow.NumberOfPackages;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()

	PutProductsInStorage();
	Close(DialogReturnCode.OK);
	
	NotifyChoice(AddressGoodsInStorage);
	
EndProcedure

&AtClient
Procedure SelectRowsExecute()

	For Each TableRow In TableOfGoods Do
		TableRow.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearRowsExecute()

	For Each TableRow In TableOfGoods Do
		TableRow.Selected = False
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectSelectedRows(Command)
	
	RowsArray = Items.TableOfGoods.SelectedRows;
	For Each LineNumber In RowsArray Do
		TableRow = TableOfGoods.FindByID(LineNumber);
		If TableRow <> Undefined Then
			TableRow.Selected = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearSelectedRows(Command)
	
	RowsArray = Items.TableOfGoods.SelectedRows;
	For Each LineNumber In RowsArray Do
		TableRow = TableOfGoods.FindByID(LineNumber);
		If TableRow <> Undefined Then
			TableRow.Selected = False;
		EndIf;
	EndDo;
	
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
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", WebColors.RosyBrown);

EndProcedure

#Region Other

&AtServer
Procedure PutProductsInStorage() 
	
	Filter = New Structure("Selected", True);
	Goods = TableOfGoods.Unload(Filter, "Selected, Products, Characteristic, VATRate, Count, NumberOfPackages, NumberOfPackagesSelected, SellingPrice, SalesAmount, TaxInvoiceDate, CustomerInvoiceIssued, Customer");
	
	For Each TableRow In Goods Do
		
		TableRow.Count         = TableRow.NumberOfPackagesSelected;
		TableRow.NumberOfPackages = TableRow.NumberOfPackagesSelected;
		
	EndDo;
	
	PutToTempStorage(Goods, AddressGoodsInStorage);
	
EndProcedure

&AtServer
Procedure FillInProductTableForSalesReport()
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Date",				Date);
	ParametersStructure.Insert("BeginOfPeriod",		BeginOfPeriod);
	ParametersStructure.Insert("EndOfPeriod",		EndOfDay(?(ValueIsFilled(EndOfPeriod),
																	EndOfPeriod,
																	CurrentSessionDate())));
	ParametersStructure.Insert("Organization",			Organization);
	ParametersStructure.Insert("Partner",				Partner);
	ParametersStructure.Insert("Terms",			Terms);
	ParametersStructure.Insert("Counterparty",			Counterparty);
	ParametersStructure.Insert("Contract",				Contract);
	ParametersStructure.Insert("Currency",				Currency);
	ParametersStructure.Insert("VATTaxation",	VATTaxation);
	ParametersStructure.Insert("ThereIsCCDNumber",		False);
	ParametersStructure.Insert("ThereIsVATSaleAmount",	False);
	ParametersStructure.Insert("DocumentSales",		DocumentSales);
	
	TempTablesManager = New TempTablesManager;
	
	ConsignmentSalesServer.GenerateDataForReportToCommittee(ParametersStructure, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	GoodsTable.Products				AS Products,
	|	GoodsTable.Characteristic			AS Characteristic,
	|	GoodsTable.Count				AS Count,
	|	GoodsTable.TaxInvoiceDate			AS TaxInvoiceDate,
	|	GoodsTable.CustomerInvoiceIssued	AS CustomerInvoiceIssued,
	|	GoodsTable.Customer				AS Customer
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	TaxInvoiceDate,
	|	CustomerInvoiceIssued,
	|	Customer
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN ISNULL(GoodsServicesForRegistration.Count, 0) > 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END									AS Selected,
	|	GoodsServicesForRegistration.Products			AS Products,
	|	GoodsServicesForRegistration.Characteristic		AS Characteristic,
	|	GoodsServicesForRegistration.Count			AS Count,
	|	GoodsServicesForRegistration.CountBalance			AS CountBalance,
	|	ISNULL(GoodsTable.Count,
	|		GoodsServicesForRegistration.Count)		AS NumberOfPackagesSelected,
	|	GoodsServicesForRegistration.SalesAmount			AS SalesAmount,
	|	GoodsServicesForRegistration.TaxInvoiceDate		AS TaxInvoiceDate,
	|	GoodsServicesForRegistration.TaxInvoiceNumber		AS TaxInvoiceNumber,
	|	GoodsServicesForRegistration.Customer			AS Customer,
	|	GoodsServicesForRegistration.CustomerInvoiceIssued			AS CustomerInvoiceIssued,
	|	GoodsServicesForRegistration.ThereIsVATSaleAmount		AS ThereIsVATSaleAmount
	|FROM
	|	GoodsServicesForRegistration AS GoodsServicesForRegistration
	|		LEFT JOIN GoodsTable AS GoodsTable
	|		ON GoodsServicesForRegistration.Products = GoodsTable.Products
	|			AND GoodsServicesForRegistration.Characteristic = GoodsTable.Characteristic
	|			AND GoodsServicesForRegistration.TaxInvoiceDate = GoodsTable.TaxInvoiceDate
	|			AND GoodsServicesForRegistration.Customer = GoodsTable.Customer
	|			AND (GoodsTable.CustomerInvoiceIssued IN (&BlankValuesInvoiceIssued)
	|				OR GoodsServicesForRegistration.CustomerInvoiceIssued = GoodsTable.CustomerInvoiceIssued)
	|
	|ORDER BY
	|	TaxInvoiceDate DESC
	|
	|TOTALS
	|	SUM(Count),
	|	MAX(CountBalance)
	|BY
	|	Products,
	|	Characteristic";
	
	Goods = GetFromTempStorage(AddressGoodsInStorage); // ValueTable
	Goods.GroupBy("Products, Characteristic, TaxInvoiceDate, CustomerInvoiceIssued, Customer", "Count");
	
	Query.SetParameter("GoodsTable", Goods);
	Query.SetParameter("BlankValuesInvoiceIssued",
								ArrayOfBlankInvoiceValuesIssued());
	
	QueryResult = Query.Execute();
	
	If ValueIsFilled(Counterparty) Then
			
		StructureOfActions = New Structure;
		BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(ParametersStructure, StructureOfActions);
			
		ParametersStructure.Insert("StructureOfActions", StructureOfActions);
	EndIf;
	
	ConsignmentSalesServer.FillInTsForGoodsForMakingReportsToCommitteeForPeriod(TableOfGoods,
																						QueryResult,
																						ParametersStructure);
	
EndProcedure

&AtServer
Procedure FillInProductTableForWriteOffReport()
	
	Query = New Query("
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	GoodsTable.Count AS Count
	|
	|INTO GoodsTable
	|FROM
	|	&Goods AS GoodsTable
	|;
	|///////////////////////////////////////////////////////////////////////////////	
	|SELECT
	|	InventoryKinds.Ref AS InventoryOwnerAttribute
	|
	|INTO InventoryKinds
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND InventoryKinds.Organization = &Organization
	|	AND InventoryKinds.GoodsOwner = &Consignor
	|	AND (InventoryKinds.Terms = &Terms
	|		OR &Terms = UNDEFINED)
	|	AND InventoryKinds.Currency = &Currency
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.ItemsLocationAttributes.Products AS Products,
	|	Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	Balance.ItemsLocationAttributes.Series AS Series,
	|
	|	CASE WHEN &ThisIsASalesReport THEN
	|		Balance.CountBalance
	|	ELSE
	|		Balance.QuantityConsumedBalance
	|	END AS CountBalance,
	|	Balance.RevenueAmountBalance
	|
	|INTO GoodsForRegistration
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Balance(&Boundary,
	|		InventoryOwnerAttribute IN (
	|			SELECT
	|				InventoryOwnerAttribute
	|			FROM
	|				InventoryKinds AS InventoryKinds
	|			)
	|	) AS Balance
	|WHERE
	|	(Balance.CountBalance <> 0 AND &ThisIsASalesReport)
	|	OR 
	|	(Balance.QuantityConsumedBalance <> 0 AND NOT &ThisIsASalesReport)
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|
	|	CASE WHEN &ThisIsASalesReport THEN
	|		Balance.CountBalance
	|	ELSE
	|		Balance.QuantityConsumedBalance
	|	END AS CountBalance,
	|	CASE WHEN &ThisIsASalesReport AND Balance.CountBalance < 0 THEN
	|		-1
	|	ELSE
	|		1
	|	END AS Character,
	|	Balance.RevenueAmountBalance
	|
	|INTO GoodsForRegistrationBalance
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Balance(,
	|		InventoryOwnerAttribute IN (
	|			SELECT
	|				InventoryOwnerAttribute
	|			FROM
	|				InventoryKinds AS InventoryKinds
	|			)
	|	) AS Balance
	|WHERE
	|	(Balance.CountBalance <> 0 AND &ThisIsASalesReport)
	|	OR 
	|	(Balance.QuantityConsumedBalance <> 0 AND NOT &ThisIsASalesReport)
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE WHEN ISNULL(GoodsTable.Count, 0) > 0 THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS Selected,
	|
	|	GoodsForRegistration.Products AS Products,
	|	GoodsForRegistration.Characteristic AS Characteristic,
	|	GoodsForRegistration.Series AS Series,
	|
	|	CASE WHEN ISNULL(GoodsForRegistrationBalance.CountBalance * GoodsForRegistrationBalance.Character, 0)
	|		< (GoodsForRegistration.CountBalance * ISNULL(GoodsForRegistrationBalance.Character, 1))
	|	THEN
	|		ISNULL(GoodsForRegistrationBalance.CountBalance, 0)
	|	ELSE
	|		GoodsForRegistration.CountBalance
	|	END AS NumberOfPackages,
	|
	|	ISNULL(GoodsTable.Count, 0) AS NumberOfPackagesSelected,
	|
	|	CASE WHEN ISNULL(GoodsForRegistrationBalance.CountBalance * GoodsForRegistrationBalance.Character, 0)
	|		< (GoodsForRegistration.CountBalance * ISNULL(GoodsForRegistrationBalance.Character, 1))
	|	THEN
	|		ISNULL(GoodsForRegistrationBalance.CountBalance, 0)
	|	ELSE
	|		GoodsForRegistration.CountBalance
	|	END AS NumberOfPackagesAccounting,
	|
	|	CASE WHEN ISNULL(GoodsForRegistrationBalance.CountBalance * GoodsForRegistrationBalance.Character, 0)
	|		< (GoodsForRegistration.CountBalance * ISNULL(GoodsForRegistrationBalance.Character, 1))
	|	THEN
	|		ISNULL(GoodsForRegistrationBalance.RevenueAmountBalance, 0)
	|	ELSE
	|		GoodsForRegistration.RevenueAmountBalance
	|	END AS SalesAmount,
	|
	|	CASE WHEN (
	|		CASE WHEN ISNULL(GoodsForRegistrationBalance.CountBalance * GoodsForRegistrationBalance.Character, 0)
	|			< (GoodsForRegistration.CountBalance * ISNULL(GoodsForRegistrationBalance.Character, 1))
	|		THEN
	|			ISNULL(GoodsForRegistrationBalance.CountBalance, 0)
	|		ELSE
	|			GoodsForRegistration.CountBalance
	|		END
	|		) = 0
	|	THEN
	|		0
	|	ELSE
	|		GoodsForRegistration.RevenueAmountBalance / 
	|		(
	|		CASE WHEN ISNULL(GoodsForRegistrationBalance.CountBalance * GoodsForRegistrationBalance.Character, 0)
	|			< (GoodsForRegistration.CountBalance * ISNULL(GoodsForRegistrationBalance.Character, 1))
	|		THEN
	|			ISNULL(GoodsForRegistrationBalance.CountBalance, 0)
	|		ELSE
	|			GoodsForRegistration.CountBalance
	|		END
	|		)
	|	END AS SellingPrice
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|
	|	LEFT JOIN GoodsForRegistrationBalance AS GoodsForRegistrationBalance
	|	ON GoodsForRegistration.ItemsLocationAttributes = GoodsForRegistrationBalance.ItemsLocationAttributes
 	|	LEFT JOIN GoodsTable AS GoodsTable
	|	ON GoodsForRegistration.Products = GoodsTable.Products
	|	AND GoodsForRegistration.Characteristic = GoodsTable.Characteristic
	|
	|WHERE
	|	GoodsForRegistration.CountBalance <> 0
	|	AND ISNULL(GoodsForRegistrationBalance.CountBalance, 0) <> 0
	|
	|ORDER BY
	|	GoodsForRegistration.Products,
	|	GoodsForRegistration.Characteristic
	|");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Consignor", Partner);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("ThisIsASalesReport", ThisIsASalesReport);
	
	FillingDate = ?(ValueIsFilled(EndOfPeriod), EndOfDay(EndOfPeriod), CurrentSessionDate());
	Boundary = New Boundary(FillingDate, BoundaryType.Including);
	Query.SetParameter("Boundary", Boundary);
	
	Goods = GetFromTempStorage(AddressGoodsInStorage); // ValueTable
	Goods.GroupBy("Products, Characteristic", "Count");
	Query.SetParameter("Goods", Goods);
	
	TableOfGoods.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Function ArrayOfBlankInvoiceValuesIssued()
	ArrayOfEmptyValues = New Array;
	ArrayOfEmptyValues.Add(Undefined);
	Return ArrayOfEmptyValues;
EndFunction	

#EndRegion

#EndRegion
