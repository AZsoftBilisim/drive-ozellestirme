#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Structure of acceptable selections of goods for transfer {Warehouse, Organization, recipient Organization, beginning of Period, end of Period}.
//
// Parameters:
//	Filters - Structure - the values of the selections of products to transfer.
//
// Returns:
//	Structure - acceptable selections of goods for transfer.
//
Function SelectionOfGoodsForTransfer(Filters = Undefined) Export
	FilterAvailableFields = New Structure();
	FilterAvailableFields.Insert("Warehouse", Undefined);
	FilterAvailableFields.Insert("Organization", Undefined);
	FilterAvailableFields.Insert("CompanyRecipient", Undefined);
	FilterAvailableFields.Insert("VATTaxation", Undefined);
	FilterAvailableFields.Insert("InventoryType", Undefined);
	FilterAvailableFields.Insert("BeginOfPeriod", '00010101');
	FilterAvailableFields.Insert("EndOfPeriod", '39991231235959');
	
	If Undefined <> Filters Then
		FillPropertyValues(FilterAvailableFields, Filters);
	EndIf;
	Return FilterAvailableFields;
EndFunction

// The list (table) of items and quantities for registration of transfers in the context of measurements of the register of goods for transfer.
//
// Parameters:
//	Filters - Structure - the values of the selections of products to transfer.
//
// Returns:
//	ValueTable - data for registration of transfers of goods.
//
Function GoodsToTransfer(Filters = Undefined) Export
	AllSelections = SelectionOfGoodsForTransfer(Filters);
	
	StartOfGoodsForTransfer = StartOfGoodsForTransfer(AllSelections.Organization, AllSelections.Warehouse);
	
	Query = New Query(TextBalancesToTransferAndConsumption());
	Query.SetParameter("BeginOfPeriod",
		BegOfMonth(?(ValueIsFilled(AllSelections.BeginOfPeriod), AllSelections.BeginOfPeriod, StartOfGoodsForTransfer)));
	Query.SetParameter("EndOfPeriod", EndOfMonth(AllSelections.EndOfPeriod));
	Query.SetParameter("Warehouse", AllSelections.Warehouse);
	Query.SetParameter("Organization", AllSelections.Organization);
	Query.SetParameter("CompanyRecipient", AllSelections.CompanyRecipient);
	Query.SetParameter("VATTaxation", AllSelections.VATTaxation);
	Query.SetParameter("InventoryType", AllSelections.InventoryType);
	Query.SetParameter("PeriodBoundary", New Boundary(EndOfMonth(AllSelections.EndOfPeriod), BoundaryType.Including));
	Result = Query.Execute();
	
	GoodsToTransfer = New ValueTable;
	For Each Column In Result.Columns Do
		Name = Column.Name;
		If Name = "ArrivalPeriod" Or Name = "Passed" Then
			Continue;
		EndIf;
		GoodsToTransfer.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	Passed = 0.;
	Consumption = Undefined;
	Dimension = New Structure(
		"CCDNumber, RecipientInventoryOwnerAttribute, Sender, Warehouse, ItemsLocationAttributes, Month, Consumption_1");
	Dimension.Consumption_1 = GoodsToTransfer.CopyColumns();

	Selection = Result.Select();
	While Selection.Next() Do
		DimensionHasChanged =
			Dimension.ItemsLocationAttributes <> Selection.ItemsLocationAttributes
			Or Dimension.Warehouse <> Selection.Warehouse
			Or Dimension.Sender <> Selection.Sender
			Or Dimension.RecipientInventoryOwnerAttribute <> Selection.RecipientInventoryOwnerAttribute
			Or Dimension.CCDNumber <> Selection.CCDNumber
			Or Dimension.Month <> BegOfMonth(Selection.Period);
		If DimensionHasChanged Then
			AddItemsToTransfer(GoodsToTransfer, Dimension.Consumption_1, Passed, AllSelections);
			
			Passed = 0.;
			Consumption = Undefined;
			FillPropertyValues(Dimension, Selection);
			Dimension.Month = BegOfMonth(Selection.Period);
			Dimension.Consumption_1.Clear();
		EndIf;
		
		If Selection.Consumed > Passed Then
			If Consumption = Undefined Or Selection.RegistrationDate > Consumption.RegistrationDate Then
				Consumption = Dimension.Consumption_1.Add();
				FillPropertyValues(Consumption, Selection);
				Consumption.Consumed = 0.;
			EndIf;
			Consumption.Consumed = Consumption.Consumed + Selection.Consumed - Passed;
			Consumption.Period = Max(Consumption.Period, Selection.Period);
			Passed = 0.;
		Else
			Passed = Passed + Selection.Passed - Selection.Consumed;
		EndIf;
		
	EndDo;
	AddItemsToTransfer(GoodsToTransfer, Dimension.Consumption_1, Passed, AllSelections);
	
	Return GoodsToTransfer;
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(CompanyOwner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

Function StartOfGoodsForTransfer(Organization, Warehouse)
	Query = New Query("
		|SELECT TOP 1
		|	TT__.Period AS Period,
		|	TT__.CompanyOwner,
		|	TT__.ItemsLocationAttributes,
		|	TT__.SellerInventoryOwnerAttribute,
		|	TT__.CCDNumber,
		|	TT__.CountReceipt,
		|	TT__.CountExpense
		|FROM
		|	AccumulationRegister.CompanyGoodsForTransfer.Turnovers( , , Month,
		|		&Organization IN (UNDEFINED, CompanyOwner)
		|	) AS TT__
		|WHERE
		|	TT__.CountReceipt > TT__.CountExpense
		|	AND &Warehouse IN (UNDEFINED, TT__.ItemsLocationAttributes.WarehouseArea)
		|ORDER BY
		|	TT__.Period
		|");
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	Selection = Query.Execute().Select();
	Return ?(Selection.Next(), Selection.Period, '00010101');
EndFunction

// Text of the request for transfer and consumption balances for each day.
// Query result fields:
//		{Period, date of Issue, Sender, Recipient, Warehouse, analyticaccountof Nomenclature,
//		Vijayasen, Emerged, Wijayaratna, Nalogooblozhenie, Taptapani,
//		Transmitted, Consumed}
// Orderliness:
//		{Recipient, Type Of Recipient, Sender, Analyticaccounts, Nomergtd, Period}.
Function TextBalancesToTransferAndConsumption()
	Return "
		|SELECT DISTINCT
		|	BEGINOFPERIOD(Expenses.Period, DAY) AS ConsumptionPeriod_,
		|	Expenses.ItemsLocationAttributes,
		|	Expenses.CompanyOwner,
		|	Expenses.SellerInventoryOwnerAttribute,
		|	Expenses.CCDNumber,
		|	MAX(BEGINOFPERIOD(Parishes.Period, DAY)) AS ArrivalPeriod
		|INTO
		|	Dates
		|FROM
		|	AccumulationRegister.CompanyGoodsForTransfer AS Expenses
		|	INNER JOIN Catalog.InventoryKinds AS TypesOfSellersInventory_
		|		ON TypesOfSellersInventory_.Ref = Expenses.SellerInventoryOwnerAttribute
		|	INNER JOIN AccumulationRegister.CompanyGoods AS Parishes
		|		ON Parishes.ItemsLocationAttributes = Expenses.ItemsLocationAttributes
		|		AND Parishes.Period <= ENDOFPERIOD(Expenses.Period, DAY)
		|		AND Parishes.Organization = Expenses.CompanyOwner
		|		AND Parishes.InventoryOwnerAttribute = TypesOfSellersInventory_.InventoryOwnerAttributeOfCompanyGoodsOwner
		|		AND Parishes.CCDNumber = Expenses.CCDNumber
		|WHERE
		|	Expenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Parishes.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND (Parishes.RecordType = VALUE(AccumulationRecordType.Receipt) OR Parishes.Count < 0.)
		|	AND &Organization IN (UNDEFINED, Expenses.CompanyOwner)
		|	AND &CompanyRecipient IN (UNDEFINED, TypesOfSellersInventory_.Organization)
		|	AND &Warehouse IN (UNDEFINED, Expenses.ItemsLocationAttributes.WarehouseArea)
		|	AND &VATTaxation IN (UNDEFINED, TypesOfSellersInventory_.VATTaxation)
		|	AND &InventoryType IN (UNDEFINED, TypesOfSellersInventory_.InventoryType)
		|GROUP BY
		|	BEGINOFPERIOD(Expenses.Period, DAY),
		|	Expenses.ItemsLocationAttributes,
		|	Expenses.CompanyOwner,
		|	Expenses.SellerInventoryOwnerAttribute,
		|	Expenses.CCDNumber
		|;
		|
		|SELECT
		|	DD.Period,
		|	(CASE
		|		WHEN ISNULL(Dates.ArrivalPeriod, &BeginOfPeriod) <= BEGINOFPERIOD(DD.Period, MONTH) THEN BEGINOFPERIOD(DD.Period, MONTH)
		|		WHEN Dates.ArrivalPeriod = DD.Period THEN DD.Period
		|		ELSE DATEADD(Dates.ArrivalPeriod, DAY, 1) END) AS RegistrationDate,
		|	DD.CompanyOwner AS Sender,
		|	TypesOfSellersInventory_.Organization AS Recipient,
		|	DD.ItemsLocationAttributes.StorageLocation AS Warehouse,
		|	DD.ItemsLocationAttributes,
		|	TypesOfSellersInventory_.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttribute,
		|	DD.CCDNumber,
		|	DD.SellerInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
		|	TypesOfSellersInventory_.VATTaxation,
		|	TypesOfSellersInventory_.InventoryType,
		|	(CASE
		|		WHEN DD.CountExpense > DD.CountReceipt THEN DD.CountExpense - DD.CountReceipt
		|		ELSE 0. END) AS Passed,
		|	(CASE
		|		WHEN DD.CountReceipt > DD.CountExpense THEN DD.CountReceipt - DD.CountExpense
		|		ELSE 0. END) AS Consumed
		|FROM
		|	AccumulationRegister.CompanyGoodsForTransfer.Turnovers(
		|		&BeginOfPeriod, &EndOfPeriod, Day, &Organization IN (UNDEFINED, CompanyOwner)
		|	) AS DD
		|	INNER JOIN Catalog.InventoryKinds AS TypesOfSellersInventory_
		|		ON TypesOfSellersInventory_.Ref = DD.SellerInventoryOwnerAttribute
		|	LEFT JOIN Dates AS Dates
		|		ON Dates.ConsumptionPeriod_ = DD.Period
		|		AND Dates.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND Dates.CompanyOwner = DD.CompanyOwner
		|		AND Dates.SellerInventoryOwnerAttribute = DD.SellerInventoryOwnerAttribute
		|		AND Dates.CCDNumber = DD.CCDNumber
		|
		|	INNER JOIN AccumulationRegister.CompanyGoodsForTransfer.Balance(&PeriodBoundary) AS LeftoversAtEnd
		|	ON DD.CompanyOwner = LeftoversAtEnd.CompanyOwner
		|		AND DD.ItemsLocationAttributes = LeftoversAtEnd.ItemsLocationAttributes
		|		AND DD.SellerInventoryOwnerAttribute = LeftoversAtEnd.SellerInventoryOwnerAttribute
		|		AND DD.CCDNumber = LeftoversAtEnd.CCDNumber
		|
		|WHERE
		|	DD.CountExpense <> DD.CountReceipt
		|	AND &CompanyRecipient IN (UNDEFINED, TypesOfSellersInventory_.Organization)
		|	AND &Warehouse IN (UNDEFINED, DD.ItemsLocationAttributes.WarehouseArea)
		|	AND &VATTaxation IN (UNDEFINED, TypesOfSellersInventory_.VATTaxation)
		|	AND &InventoryType IN (UNDEFINED, TypesOfSellersInventory_.InventoryType)
		|	AND LeftoversAtEnd.CountBalance <> 0
		|
		|ORDER BY
		|	TypesOfSellersInventory_.Organization,
		|	DD.SellerInventoryOwnerAttribute,
		|	DD.CompanyOwner,
		|	DD.ItemsLocationAttributes,
		|	DD.CCDNumber,
		|	DD.Period
		|";
EndFunction

Procedure AddItemsToTransfer(GoodsToTransfer, Consumption_1, Passed, AllSelections)
	For Each Consumption In Consumption_1 Do
		If Passed > 0. Then
			Consumed = Min(Consumption.Consumed, Passed);
			Consumption.Consumed = Consumption.Consumed - Consumed;
			Passed = Passed - Consumed;
		EndIf;
		If Consumption.Consumed > 0.
			And Consumption.RegistrationDate >= AllSelections.BeginOfPeriod
			And Consumption.RegistrationDate <= AllSelections.EndOfPeriod
		Then
			GoodsToBeTransferred = GoodsToTransfer.Add();
			FillPropertyValues(GoodsToBeTransferred, Consumption);
		EndIf;
	EndDo;
EndProcedure

#EndRegion

#EndIf