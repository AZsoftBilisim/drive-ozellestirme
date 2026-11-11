
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	Organization = Parameters.Organization;
	CompanyRecipient = Parameters.CompanyRecipient;
	Warehouse = Parameters.Warehouse;
	AddressInStorage = Parameters.AddressInStorage;
	Negative_Balance = Parameters.Negative_Balance;
	Date = Parameters.Date;
	
	If Parameters.Property("VATTaxation") Then
		Restrictions = VATAccountingERP.RestrictionOfGoodsOnTaxation(Parameters.VATTaxation);
		For Each Restriction In Restrictions Do
			If Restriction.Attribute = "DeleteExcisableGoods" Then
				HideExcisableGoods = True;
			EndIf;
			If Restriction.Attribute = "SubjectToVATAtCustomer" Then
				SubjectToVATAtCustomer = Restriction.Value;
			EndIf;
		EndDo;
	EndIf;
	
	ThisIsACommission = ?(Parameters.Property("ThisIsACommission") <> False, Parameters.ThisIsACommission, False);
	ThisIsSale = ?(Parameters.Property("ThisIsSale") <> False, Parameters.ThisIsSale, False);
	ThisIsReturn = ?(Parameters.Property("ThisIsReturn") <> False, Parameters.ThisIsReturn, False);
	
	Items.HideExcisableGoods.Visible = HideExcisableGoods;
	Items.TableOfGoodsSeries.Visible = Parameters.UseItemsBatch;
	
	FillInTheGoodsTable();
	FormItemsManagement();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInTheGoodsTable();
	
EndProcedure

&AtClient
Procedure HideExcisableGoodsOnChange(Item)
	
	FillInTheGoodsTable();
	
EndProcedure

&AtClient
Procedure TableOfGoodsCountOnChange(Item)
	
	TableRow = Items.TableOfGoods.CurrentData;
	TableRow.Selected = (TableRow.Count <> 0);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()

	PutProductsInStorage();
	Close(DialogReturnCode.OK);
	
	NotifyChoice(AddressInStorage);
	
EndProcedure

&AtClient
Procedure SelectRowsExecute()

	For Each TableRow In TableOfGoods Do
		If Negative_Balance And TableRow.AmountRecipientSBalance < 0
		 Or Not Negative_Balance And TableRow.QuantitySenderSBalance > 0 Then
			TableRow.Selected = True;
		EndIf;
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

&AtClient
Procedure Refresh(Command)
	
	FillInTheGoodsTable();
	
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

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Items.CompanyRecipient.Visible = Negative_Balance;
	Items.TableOfGoodsAmountRecipientSBalance.Visible = Negative_Balance;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure PutProductsInStorage() 
	
	Filter = New Structure("Selected", True);
	Goods = TableOfGoods.Unload(Filter, "Selected, Products, Characteristic, Series, Purpose, NumberOfPackages, Count");
	
	For Each TableRow In Goods Do
		TableRow.NumberOfPackages = TableRow.Count;
	EndDo;
	
	PutToTempStorage(Goods, AddressInStorage);
	
EndProcedure

&AtServer
Procedure FillInTheGoodsTable()
	
	Query = New Query("
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.Purpose AS Purpose
	|
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Products             AS Products,
	|	Balance.Characteristic           AS Characteristic,
	|	Balance.Series                    AS Series,
	|	Balance.Purpose               AS Purpose,
	|	SUM(Balance.CountBalance) AS CountBalance
	|INTO SenderSBalances
	|FROM
	|	(SELECT
	|		Balance.ItemsLocationAttributes.Products AS Products,
	|		Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		Balance.ItemsLocationAttributes.Series AS Series,
	|		Balance.ItemsLocationAttributes.Purpose AS Purpose,
	|		SUM(Balance.CountBalance) AS CountBalance
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(&Boundary,
	|			Organization = &SenderOrganization
	|			AND ItemsLocationAttributes.StorageLocation = &Warehouse
	|			AND NOT (&HideExcisableGoods
	|				AND ItemsLocationAttributes.Products.DeleteExcisableGoods)
	|			AND InventoryOwnerAttribute.InventoryType IN (&AvailableStockTypes)
	|			AND (InventoryOwnerAttribute.GoodsOwner = &GoodsOwner OR &ForAllOwners)
	|		) AS Balance
	|		
	|	GROUP BY
	|		Balance.ItemsLocationAttributes.Products,
	|		Balance.ItemsLocationAttributes.Characteristic,
	|		Balance.ItemsLocationAttributes.Series,
	|		Balance.ItemsLocationAttributes.Purpose
	|
	|	UNION ALL
	|
	|	SELECT
	|		Balance.ItemsLocationAttributes.Products AS Products,
	|		Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		Balance.ItemsLocationAttributes.Series AS Series,
	|		Balance.ItemsLocationAttributes.Purpose AS Purpose,
	|		SUM(Balance.CountBalance) AS CountBalance
	|	FROM
	|		AccumulationRegister.CompanySafeStock.Balance(&Boundary,
	|			Organization = &SenderOrganization
	|			AND ItemsLocationAttributes.StorageLocation = &Warehouse
	|			AND NOT (&HideExcisableGoods
	|				AND ItemsLocationAttributes.Products.DeleteExcisableGoods)
	|			AND InventoryOwnerAttribute.InventoryType IN (&AvailableStockTypes)
	|			AND (InventoryOwnerAttribute.GoodsOwner = &GoodsOwner OR &ForAllOwners)
	|		) AS Balance
	|
	|	GROUP BY
	|		Balance.ItemsLocationAttributes.Products,
	|		Balance.ItemsLocationAttributes.Characteristic,
	|		Balance.ItemsLocationAttributes.Series,
	|		Balance.ItemsLocationAttributes.Purpose
	|
	|	) AS Balance
	|
	|	GROUP BY
	|		Balance.Products,
	|		Balance.Characteristic,
	|		Balance.Series,
	|		Balance.Purpose
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.Series AS Series,
	|	Balance.Purpose AS Purpose,
	|	SUM(Balance.CountBalance) AS CountBalance
	|INTO RecipientSBalances
	|FROM
	|	(SELECT
	|		Balance.ItemsLocationAttributes.Products AS Products,
	|		Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		Balance.ItemsLocationAttributes.Series AS Series,
	|		Balance.ItemsLocationAttributes.Purpose AS Purpose,
	|		SUM(Balance.CountBalance) AS CountBalance
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(&Boundary,
	|			&Negative_Balance
	|			AND Organization = &CompanyRecipient
	|			AND ItemsLocationAttributes.StorageLocation = &Warehouse
	|			AND NOT (&HideExcisableGoods
	|				AND ItemsLocationAttributes.Products.DeleteExcisableGoods)
	|			AND ItemsLocationAttributes.Products.SubjectToVATAtCustomer = &SubjectToVATAtCustomer
	|		) AS Balance
	|
	|	WHERE
	|		Balance.CountBalance < 0
	|	
	|	GROUP BY
	|		Balance.ItemsLocationAttributes.Products,
	|		Balance.ItemsLocationAttributes.Characteristic,
	|		Balance.ItemsLocationAttributes.Series,
	|		Balance.ItemsLocationAttributes.Purpose
	|
	|	UNION ALL
	|
	|	SELECT
	|		Balance.ItemsLocationAttributes.Products AS Products,
	|		Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		Balance.ItemsLocationAttributes.Series AS Series,
	|		Balance.ItemsLocationAttributes.Purpose AS Purpose,
	|		SUM(Balance.CountBalance) AS CountBalance
	|FROM
	|	AccumulationRegister.CompanySafeStock.Balance(&Boundary,
	|		&Negative_Balance
	|		AND Organization = &CompanyRecipient
	|		AND ItemsLocationAttributes.StorageLocation = &Warehouse
	|		AND NOT (&HideExcisableGoods
	|			AND ItemsLocationAttributes.Products.DeleteExcisableGoods)
	|		AND ItemsLocationAttributes.Products.SubjectToVATAtCustomer = &SubjectToVATAtCustomer
	|	) AS Balance
	|	
	|	GROUP BY
	|		Balance.ItemsLocationAttributes.Products,
	|		Balance.ItemsLocationAttributes.Characteristic,
	|		Balance.ItemsLocationAttributes.Series,
	|		Balance.ItemsLocationAttributes.Purpose
	|
	|	) AS Balance
	|
	|GROUP BY
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Series,
	|	Balance.Purpose
	|
	|HAVING
	|	SUM(Balance.CountBalance) < 0
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE WHEN Goods.Count IS NULL
	|		OR Goods.Count = 0
	|	THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS Selected,
	|	RecipientSBalances.Products AS Products,
	|	RecipientSBalances.Characteristic AS Characteristic,
	|	RecipientSBalances.Series AS Series,
	|	RecipientSBalances.Purpose AS Purpose,
	|	SUM(SenderSBalances.CountBalance) AS QuantitySenderSBalance,
	|	SUM(RecipientSBalances.CountBalance) AS AmountRecipientSBalance,
	|
	|	SUM(CASE WHEN Goods.Count IS NULL
	|		OR Goods.Count = 0
	|	THEN
	|		CASE WHEN (-RecipientSBalances.CountBalance) < SenderSBalances.CountBalance THEN
	|			-RecipientSBalances.CountBalance
	|		ELSE
	|			SenderSBalances.CountBalance
	|		END
	|	ELSE
	|		Goods.Count
	|	END) AS Count
	|FROM
	|	RecipientSBalances AS RecipientSBalances
	|
	|	LEFT JOIN
	|		Goods AS Goods
	|	ON
	|		RecipientSBalances.Products = Goods.Products
	|		AND RecipientSBalances.Characteristic = Goods.Characteristic
	|		AND RecipientSBalances.Series = Goods.Series
	|		AND RecipientSBalances.Purpose = Goods.Purpose
	|
	|	LEFT JOIN
	|		SenderSBalances AS SenderSBalances
	|	ON
	|		RecipientSBalances.Products = SenderSBalances.Products
	|		AND RecipientSBalances.Characteristic = SenderSBalances.Characteristic
	|		AND RecipientSBalances.Series = SenderSBalances.Series
	|		AND RecipientSBalances.Purpose = SenderSBalances.Purpose
	|WHERE
	|	&Negative_Balance
	|
	|GROUP BY
	|	CASE WHEN Goods.Count IS NULL
	|		OR Goods.Count = 0
	|	THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END,
	|	RecipientSBalances.Products,
	|	RecipientSBalances.Characteristic,
	|	RecipientSBalances.Series,
	|	RecipientSBalances.Purpose
	|
	|HAVING
	|	SUM(CASE WHEN Goods.Count IS NULL
	|		OR Goods.Count = 0
	|	THEN
	|		CASE WHEN (-RecipientSBalances.CountBalance) < SenderSBalances.CountBalance THEN
	|			-RecipientSBalances.CountBalance
	|		ELSE
	|			SenderSBalances.CountBalance
	|		END
	|	ELSE
	|		Goods.Count
	|	END) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	CASE WHEN Goods.Count IS NULL
	|		OR Goods.Count = 0
	|	THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS Selected,
	|	SenderSBalances.Products AS Products,
	|	SenderSBalances.Characteristic AS Characteristic,
	|	SenderSBalances.Series AS Series,
	|	SenderSBalances.Purpose AS Purpose,
	|	SUM(SenderSBalances.CountBalance) AS QuantitySenderSBalance,
	|	0 AS AmountRecipientSBalance,
	|
	|	SUM(CASE WHEN Goods.Count IS NULL
	|		OR Goods.Count = 0
	|	THEN
	|		SenderSBalances.CountBalance
	|	ELSE
	|		Goods.Count
	|	END) AS Count
	|FROM
	|	SenderSBalances AS SenderSBalances
	|
	|	LEFT JOIN
	|		Goods AS Goods
	|	ON
	|		SenderSBalances.Products = Goods.Products
	|		AND SenderSBalances.Characteristic = Goods.Characteristic
	|		AND SenderSBalances.Series = Goods.Series
	|		AND SenderSBalances.Purpose = Goods.Purpose
	|WHERE
	|	NOT &Negative_Balance
	|
	|GROUP BY
	|	CASE WHEN Goods.Count IS NULL
	|		OR Goods.Count = 0
	|	THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END,
	|	SenderSBalances.Products,
	|	SenderSBalances.Characteristic,
	|	SenderSBalances.Series,
	|	SenderSBalances.Purpose
	|
	|HAVING
	|	 SUM(CASE WHEN Goods.Count IS NULL
	|		OR Goods.Count = 0
	|	THEN
	|		SenderSBalances.CountBalance
	|	ELSE
	|		Goods.Count
	|	END) <> 0
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose
	|");
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CompanyRecipient", CompanyRecipient);
	Query.SetParameter("SenderOrganization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Negative_Balance", Negative_Balance);
	Query.SetParameter("HideExcisableGoods", HideExcisableGoods);
	Query.SetParameter("SubjectToVATAtCustomer", SubjectToVATAtCustomer);
	
	AvailableStockTypes = New Array();
	GoodsOwner = Undefined;
	If ThisIsACommission And ThisIsReturn Then
		AvailableStockTypes.Add(Enums.InventoryTypes.ConsignedGoods);
		GoodsOwner = CompanyRecipient;
	Else
		AvailableStockTypes.Add(Enums.InventoryTypes.ConsignedGoods);
		AvailableStockTypes.Add(Enums.InventoryTypes.OwnGoods);
		AvailableStockTypes.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	EndIf;
	Query.SetParameter("AvailableStockTypes", AvailableStockTypes);
	Query.SetParameter("GoodsOwner", GoodsOwner);
	Query.SetParameter("ForAllOwners", Not ValueIsFilled(GoodsOwner));
	
	FillingDate = ?(ValueIsFilled(Date), EndOfDay(Date), CurrentSessionDate());
	Boundary = New Boundary(FillingDate, BoundaryType.Including);
	Query.SetParameter("Boundary", Boundary);
	
	If TableOfGoods.Count() > 0 Then
		Goods = TableOfGoods.Unload(, "Selected, Products, Characteristic, Series, Purpose, Count");
		LinesToDelete = Goods.FindRows(New Structure("Selected", False));
		For Each RowToDelete In LinesToDelete Do
			Goods.Delete(RowToDelete);
		EndDo;
	Else
		Goods = GetFromTempStorage(AddressInStorage);
		Goods.GroupBy("Products, Characteristic, Series, Purpose", "Count");
	EndIf;
	Query.SetParameter("Goods", Goods);
	
	RecipientSpecified = ValueIsFilled(CompanyRecipient);
	UseCommission = (ThisIsACommission And RecipientSpecified);
	UseSale = (ThisIsSale And RecipientSpecified);
	
	Query.SetParameter("UseCommission", UseCommission);
	Query.SetParameter("UseSale", UseSale);
	Query.SetParameter("CommissionForPurchases", UseCommission And GetFunctionalOption("UsePurchaseCommission"));
	Query.SetParameter("InventoryBySupplier", UseSale And GetFunctionalOption("GenerateInventoryOwnerAttributesByVendors"));
	
	Result = Query.Execute();
	TableOfGoods.Load(Result.Unload());
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
