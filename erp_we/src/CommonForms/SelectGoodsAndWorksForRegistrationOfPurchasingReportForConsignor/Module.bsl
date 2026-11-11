
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
	Counterparty = Parameters.Counterparty;
	Contract = Parameters.Contract;
	Currency = Parameters.Currency;
	If Parameters.Property("DocumentAcquisitions") Then
		DocumentAcquisitions = Parameters.DocumentAcquisitions;
	EndIf;
	ThisIsASalesReport = True;
	AddressGoodsInStorage = Parameters.AddressGoodsInStorage;
	
	FillInProductTableForPurchaseReport();
	Items.TableOfProductsPurchaseAmount.Visible = ThisIsASalesReport;
	Items.ProductTableSupplier.Visible = ThisIsASalesReport;
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "TableOfGoodsCCDNumber");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TableOfGoodsNumberOfPackagesOnChange(Item)
	
	TableRow = Items.TableOfGoods.CurrentData;
	TableRow.Selected = (TableRow.NumberOfPackages <> 0 And TableRow.NumberOfPackagesSelected <> 0);
	
	// a separate method should be used to recalculate the amount based on the amount of balances...
	CoefficientForRecalculatingAmount = 1;
	
	If TableRow.Selected Then
		CoefficientForRecalculatingAmount = TableRow.NumberOfPackagesSelected / TableRow.NumberOfPackages;
	EndIf;
	
	TableRow.AmountIncludingVAT = TableRow.AmountIncludingVATBalance * CoefficientForRecalculatingAmount;
	TableRow.VATAmount = TableRow.VATAmountBalance * CoefficientForRecalculatingAmount;
	TableRow.Sum = ?(TableRow.PriceIncludesVAT, TableRow.AmountIncludingVAT,
							TableRow.AmountIncludingVAT - TableRow.VATAmount);
	
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

	For Each TableRow In Goods Do
		TableRow.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearRowsExecute()

	For Each TableRow In Goods Do
		TableRow.Selected = False
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectSelectedRows(Command)
	
	RowsArray = Items.TableOfGoods.SelectedRows;
	For Each LineNumber In RowsArray Do
		TableRow = Goods.FindByID(LineNumber);
		If TableRow <> Undefined Then
			TableRow.Selected = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearSelectedRows(Command)
	
	RowsArray = Items.TableOfGoods.SelectedRows;
	For Each LineNumber In RowsArray Do
		TableRow = Goods.FindByID(LineNumber);
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

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsSelected.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.NumberOfPackagesSelected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.VATAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

#Region Other

&AtServer
Procedure PutProductsInStorage() 
	
	Query = New Query();
	Query.Text =
	"SELECT 
	|	Goods.Products             AS Products,
	|	Goods.Characteristic           AS Characteristic,
	|	Goods.Purpose               AS Purpose,
	|	Goods.VATRate                AS VATRate,
	|	Goods.Count               AS Count,
	|	Goods.NumberOfPackages       AS NumberOfPackages,
	|	Goods.NumberOfPackagesSelected AS NumberOfPackagesSelected,
	|	Goods.AmountIncludingVAT                AS AmountIncludingVAT,
	|	Goods.VATAmount                 AS VATAmount,
	|	Goods.Sum                    AS Sum,
	|	Goods.CCDNumber                 AS CCDNumber,
	|	Goods.DocumentAcquisitions     AS DocumentAcquisitions,
	|	Goods.Vendor                AS Vendor,
	|	Goods.SalesOrder             AS SalesOrder
	|INTO DocumentGoods
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.Selected
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products             AS Products,
	|	Goods.Characteristic           AS Characteristic,
	|	Goods.Purpose               AS Purpose,
	|	Goods.VATRate                AS VATRate,
	|	Goods.NumberOfPackagesSelected AS Count,
	|	Goods.NumberOfPackagesSelected AS NumberOfPackages,
	|	Goods.AmountIncludingVAT                AS AmountIncludingVAT,
	|	Goods.VATAmount                 AS VATAmount,
	|	Goods.Sum                    AS Sum,
	|	Goods.CCDNumber                 AS CCDNumber,
	|	Goods.DocumentAcquisitions     AS DocumentAcquisitions,
	|	Goods.Vendor                AS Vendor,
	|	DestinationsOfGoods.OrderDocument         AS SalesOrder
	|FROM DocumentGoods AS Goods
	|	LEFT JOIN Catalog.Assignments AS DestinationsOfGoods
	|	ON Goods.Purpose = DestinationsOfGoods.Ref
	|";
	
	Query.SetParameter("Goods", Goods.Unload());
	
	GoodsTable = Query.Execute().Unload();
	PutToTempStorage(GoodsTable, AddressGoodsInStorage);
	
EndProcedure

&AtServer
Procedure FillInProductTableForPurchaseReport()
	
	TempTablesManager = New TempTablesManager;
	
	QueryTextTTBalancesToBeProcessed = Documents.PurchasingReportToConsignorPrincipal.TextOfRequestGoodsServicesForPreparationOfReportsToPurchasingCommitteeBalancesByAppointment("TTBalancesToBeProcessed");
	
	RequestTextAndInvoicesReceived = "
	|SELECT DISTINCT
	|	BasisDocuments.DocumentAcquisitions AS DocumentBasis
	|INTO BasisDocuments
	|FROM
	|	TTBalancesToBeProcessed AS BasisDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.DocumentAcquisitions AS DocumentAcquisitions,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Vendor AS Vendor,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BasisDocuments.DocumentBasis AS Ref
	|INTO TableOfBases_
	|FROM
	|	BasisDocuments AS BasisDocuments
	|
	|GROUP BY
	|	BasisDocuments.DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN ISNULL(GoodsTable.NumberOfPackages, 0) <> 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Selected,
	|	RequirementsForRegistration_1.Organization AS Organization,
	|	RequirementsForRegistration_1.Products AS Products,
	|	RequirementsForRegistration_1.Characteristic AS Characteristic,
	|	RequirementsForRegistration_1.Purpose AS Purpose,
	|	RequirementsForRegistration_1.Package AS Package,
	|	RequirementsForRegistration_1.DocumentAcquisitions AS DocumentAcquisitions,
	|	RequirementsForRegistration_1.DocumentAcquisitions.VATTaxation AS VATTaxation,
	|	RequirementsForRegistration_1.DocumentAcquisitions.PriceIncludesVAT AS PriceIncludesVAT,
	|	RequirementsForRegistration_1.DocumentAcquisitions.Date AS PurchaseDate,
	|	RequirementsForRegistration_1.Vendor AS Vendor,
	|	RequirementsForRegistration_1.CCDNumber AS CCDNumber,
	|	RequirementsForRegistration_1.Currency AS Currency,
	|	RequirementsForRegistration_1.Count AS Count,
	|	RequirementsForRegistration_1.NumberOfPackages AS NumberOfPackages,
	|	RequirementsForRegistration_1.VATRate AS VATRate,
	|	RequirementsForRegistration_1.AmountIncludingVAT AS AmountIncludingVATBalance,
	|	RequirementsForRegistration_1.VATAmount AS VATAmountBalance,
	|	ISNULL(GoodsTable.NumberOfPackages, RequirementsForRegistration_1.NumberOfPackages) AS NumberOfPackagesSelected
	|FROM
	|	TTBalancesToBeProcessed AS RequirementsForRegistration_1
	|		INNER JOIN TableOfBases_ AS TableOfBases_
	|		ON RequirementsForRegistration_1.DocumentAcquisitions = TableOfBases_.Ref
	|		LEFT JOIN GoodsTable AS GoodsTable
	|		ON RequirementsForRegistration_1.Products = GoodsTable.Products
	|			AND RequirementsForRegistration_1.Characteristic = GoodsTable.Characteristic
	|			AND RequirementsForRegistration_1.Purpose = GoodsTable.Purpose
	|			AND RequirementsForRegistration_1.DocumentAcquisitions = GoodsTable.DocumentAcquisitions
	|			AND RequirementsForRegistration_1.Vendor = GoodsTable.Vendor
	|			AND RequirementsForRegistration_1.CCDNumber = GoodsTable.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.Products AS Products,
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.Characteristic AS Characteristic,
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.Purpose AS Purpose,
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.CCDNumber AS CCDNumber,
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.CountExpense AS CountExpense
	|FROM
	|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Turnovers(
	|			,
	|			,
	|			,
	|			(Products, Purpose, Characteristic, CCDNumber) IN
	|				(SELECT
	|					GoodsTable.Products,
	|					GoodsTable.Purpose,
	|					GoodsTable.Characteristic,
	|					GoodsTable.CCDNumber
	|				FROM
	|					GoodsTable)) AS GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers
	|";

	
	
	Query = New Query(QueryTextTTBalancesToBeProcessed + ";" + RequestTextAndInvoicesReceived);
	Query.TempTablesManager = TempTablesManager;
		
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Currency", Currency);

	Query.SetParameter("Vendor", Vendor);
	Query.SetParameter("UseSupplierSelection", ValueIsFilled(Vendor));
	
	Query.SetParameter("UseSelectionAsIntended", False);
	Query.SetParameter("AssignmentsArray", New Array);
	
	ArrayOfPurchaseDocuments = New Array();
	If ValueIsFilled(DocumentAcquisitions) Then
		Query.SetParameter("UseDocumentSelection", True);
		ArrayOfPurchaseDocuments.Add(DocumentAcquisitions);
		Query.SetParameter("ArrayOfPurchaseDocuments", ArrayOfPurchaseDocuments);
	Else
		Query.SetParameter("UseDocumentSelection", False);
		Query.SetParameter("ArrayOfPurchaseDocuments", ArrayOfPurchaseDocuments);
	EndIf;

	Query.SetParameter("Period", Date);
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	
	GoodsTable = GetFromTempStorage(AddressGoodsInStorage); // ValueTable
	GoodsTable.GroupBy("Products, Characteristic, Purpose, DocumentAcquisitions, Vendor, CCDNumber", "NumberOfPackages");
	Query.SetParameter("GoodsTable", GoodsTable);
	Goods.Clear();

	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();

	SampleReslutateNumber = 4;
	ResultNumberShipmentData = 5;
	
	
	SelectionOfResult = QueryResult[SampleReslutateNumber].Select();
	ShipmentData = QueryResult[ResultNumberShipmentData].Unload();

	While SelectionOfResult.Next() Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, SelectionOfResult);
		
		// a separate method should be used to recalculate the amount based on the amount of balances...
		CoefficientForRecalculatingAmount = 1;
		If NewRow.NumberOfPackagesSelected<>0 And NewRow.NumberOfPackages<>0 Then
			CoefficientForRecalculatingAmount = NewRow.NumberOfPackagesSelected / NewRow.NumberOfPackages;
		EndIf;
		NewRow.AmountIncludingVAT = NewRow.AmountIncludingVATBalance * CoefficientForRecalculatingAmount;
		NewRow.VATAmount = NewRow.VATAmountBalance * CoefficientForRecalculatingAmount;
		NewRow.PriceIncludesVAT = SelectionOfResult.PriceIncludesVAT;
		NewRow.Sum = ?(NewRow.PriceIncludesVAT, NewRow.AmountIncludingVAT,
								NewRow.AmountIncludingVAT - NewRow.VATAmount);
		PackagingFactor = SelectionOfResult.NumberOfPackages / ?(SelectionOfResult.Count=0, 1, SelectionOfResult.Count);
		
		FilterByProduct = New Structure();
		FilterByProduct.Insert("Products", SelectionOfResult.Products);
		FilterByProduct.Insert("Characteristic", SelectionOfResult.Characteristic);
		FilterByProduct.Insert("Purpose", SelectionOfResult.Purpose);
		FilterByProduct.Insert("CCDNumber", SelectionOfResult.CCDNumber);
		ShippingLines = ShipmentData.FindRows(FilterByProduct);
		For Each ShipmentLine In ShippingLines Do
			If ShipmentLine.CountExpense > 0 
				And NewRow.NumberOfPackagesShipped < NewRow.NumberOfPackages Then
				NumberOfPackagesShipped = Min(ShipmentLine.CountExpense / PackagingFactor, NewRow.NumberOfPackages);
				NewRow.NumberOfPackagesShipped = NewRow.NumberOfPackagesShipped + NumberOfPackagesShipped;
				ShipmentLine.CountExpense = ShipmentLine.CountExpense - ShipmentLine.CountExpense*PackagingFactor;
			EndIf;
		EndDo;
		
	EndDo;
	
	
EndProcedure

&AtClient
Procedure VendorOnChange(Item)
	
	VendorOnChangeServer();
	
EndProcedure

&AtServer
Procedure VendorOnChangeServer()
	
	FillInProductTableForPurchaseReport();
	
EndProcedure

#EndRegion

#EndRegion
