
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Items.TableOfGoodsOpenGoodsProfile.Visible = TMCommonUseClientServer.AnExternalUserIsAuthorized();

	Organization = Parameters.Organization;
	Partner = Parameters.Partner;
	Terms = Parameters.Terms;
	Date = Parameters.Date;
	AddressOfPaymentsInTheStorage = Parameters.AddressOfPaymentsInTheStorage;
	ByPhysicalCountResults = Parameters.ByPhysicalCountResults;
	
	If Parameters.Property("HideSelection") And Parameters.HideSelection Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "CompanyGroup", "Visible", False);
	EndIf;
	
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date);
	
	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT =
		Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Terms);
		
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	FillInTheGoodsTable();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TableOfGoodsNumberOfPackagesOnChange(Item)
	
	TableRow = Items.TableOfGoods.CurrentData;
	TableRow.Selected = (TableRow.NumberOfPackages <> 0);
	
EndProcedure

&AtClient
Procedure TableOfGoodsNumberOfPackagesRealOnChange(Item)
	
	TableRow = Items.TableOfGoods.CurrentData;
	TableRow.Selected = True;
	
EndProcedure

&AtClient
Procedure TableOfGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized()
		And Field.Name = "TableOfGoodsProducts"
		Or Field.Name = "TableOfGoodsCharacteristic" Then
		
		OpenProductItemCard();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()

	PutProductsInStorage();
	Close(DialogReturnCode.OK);
	
	NotifyChoice(AddressOfPaymentsInTheStorage);
	
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

&AtClient
Procedure OpenGoodsProfile(Command)
	
	OpenProductItemCard();
	
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
	
	// Embedding error
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT();
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT		= "TableOfGoods.AccountingForTheRNPTIsMaintained";
	ConditionalDesignParameters.PathToCCDNumberTypeField			= "TableOfGoods.CCDNumberType";
	ConditionalDesignParameters.PathToDocumentDateField			= "Date";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisForm,
																						ConditionalDesignParameters);
	
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceOfAccountingOnGTDVDocumentsOfCommissionAgent(ThisForm);
	
EndProcedure

#Region Other

&AtServer
Procedure PutProductsInStorage() 
	
	Filter = New Structure("Selected", True);
	Goods =
		TableOfGoods.Unload(
			Filter,
			"Selected, Products, Characteristic, CCDNumber, OriginCountry, NumberOfPackages, Count,
			|NumberOfPackagesReal, NumberOfPackagesAccounting");
	
	For Each TableRow In Goods Do
		
		If ByPhysicalCountResults Then
			TableRow.NumberOfPackages = TableRow.NumberOfPackagesAccounting - TableRow.NumberOfPackagesReal;
		EndIf;
		TableRow.Count = TableRow.NumberOfPackages;
		
	EndDo;
	
	PutToTempStorage(Goods, AddressOfPaymentsInTheStorage);
	
EndProcedure

&AtServer
Procedure FillInTheGoodsTable()
	
	Query = New Query("
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.CCDNumber AS CCDNumber,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	Goods.Count AS Count,
	|	Goods.QuantityByGBRN AS QuantityByGBRN
	|
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|///////////////////////////////////////////////////////////////////////////////	
	|SELECT
	|	Dimension.Ref AS DimensionKey
	|
	|INTO TTAnalytics_
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS Dimension
	|WHERE
	|	Dimension.StorageLocation = &Partner
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.ItemsLocationAttributes.Products AS Products,
	|	Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.ItemsLocationAttributes.Series AS Series,
	|	Balance.CountBalance AS CountBalance,
	|	Balance.QuantityByGBRNBalance AS QuantityByGBRNBalance
	|
	|INTO GoodsTransferred
	|FROM
	|	AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(&Boundary,
	|		Organization = &Organization
	|		AND Terms = &Terms
	|		AND ItemsLocationAttributes IN (
	|			SELECT
	|				Dimension.DimensionKey
	|			FROM
	|				TTAnalytics_ AS Dimension
	|			)
	|	) AS Balance
	|
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.CCDNumber AS CCDNumber,
	|	Balance.CountBalance AS CountBalance,
	|	Balance.QuantityByGBRNBalance AS QuantityByGBRNBalance,
	|	CASE WHEN Balance.CountBalance < 0 THEN
	|		-1
	|	ELSE
	|		1
	|	END AS Character
	|
	|INTO GoodsTransferredBalance
	|FROM
	|	AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(,
	|		Organization = &Organization
	|		AND Terms = &Terms
	|		AND ItemsLocationAttributes IN (
	|			SELECT
	|				Dimension.DimensionKey
	|			FROM
	|				TTAnalytics_ AS Dimension
	|			)
	|	) AS Balance
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	CCDNumber
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE WHEN Goods.Count IS NULL
	|		OR Goods.Count = 0
	|	THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS Selected,
	|	GoodsTransferred.Products AS Products,
	|	GoodsTransferred.Products.KeepRecordsByCCD AS TheRecordsAreKeptByCCD,
	|	ISNULL(GoodsTransferred.Products.TracedGoods, FALSE) AS AccountingForTheRNPTIsMaintained,
	|	GoodsTransferred.Characteristic AS Characteristic,
	|	GoodsTransferred.CCDNumber AS CCDNumber,
	|	GoodsTransferred.CCDNumber.CCDNumberType AS CCDNumberType,
	|	GoodsTransferred.CCDNumber.OriginCountry AS OriginCountry,
	|	GoodsTransferred.Series AS Series,
	|
	|	CASE WHEN ISNULL(Balance.CountBalance * Balance.Character, 0)
	|		< (GoodsTransferred.CountBalance * ISNULL(Balance.Character, 1))
	|	THEN
	|		ISNULL(Balance.CountBalance, 0)
	|	ELSE
	|		GoodsTransferred.CountBalance
	|	END AS NumberOfPackagesAccounting,
	|
	|	CASE WHEN ISNULL(Balance.QuantityByGBRNBalance * Balance.Character, 0)
	|		< (GoodsTransferred.QuantityByGBRNBalance * ISNULL(Balance.Character, 1))
	|	THEN
	|		ISNULL(Balance.QuantityByGBRNBalance, 0)
	|	ELSE
	|		GoodsTransferred.QuantityByGBRNBalance
	|	END AS QuantityAccordingToRnptuchet,
	|
	|	CASE WHEN Goods.Count IS NULL
	|		OR Goods.Count = 0
	|	THEN
	|		CASE WHEN ISNULL(Balance.CountBalance * Balance.Character, 0)
	|			< (GoodsTransferred.CountBalance * ISNULL(Balance.Character, 1))
	|		THEN
	|			ISNULL(Balance.CountBalance, 0)
	|		ELSE
	|			GoodsTransferred.CountBalance
	|		END
	|	ELSE
	|		Goods.Count
	|	END AS NumberOfPackages
	|FROM
	|	GoodsTransferred AS GoodsTransferred
	|
	|	LEFT JOIN
	|		GoodsTransferredBalance AS Balance
	|	ON
	|		GoodsTransferred.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND GoodsTransferred.CCDNumber = Balance.CCDNumber
	|
	|	LEFT JOIN
	|		Goods AS Goods
	|	ON
	|		GoodsTransferred.Products = Goods.Products
	|		AND GoodsTransferred.Characteristic = Goods.Characteristic
	|		AND GoodsTransferred.CCDNumber = Goods.CCDNumber
	|		AND GoodsTransferred.Series = Goods.Series
	|
	|WHERE
	|	GoodsTransferred.CountBalance <> 0
	|	AND ISNULL(Balance.CountBalance, 0) <> 0
	|
	|ORDER BY
	|	GoodsTransferred.Products,
	|	GoodsTransferred.Characteristic,
	|	GoodsTransferred.Series
	|");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Terms", Terms);
	
	FillingDate = ?(ValueIsFilled(Date), EndOfDay(Date), CurrentSessionDate());
	Boundary = New Boundary(FillingDate, BoundaryType.Including);
	Query.SetParameter("Boundary", Boundary);
	
	Goods = GetFromTempStorage(AddressOfPaymentsInTheStorage); // ValueTable
	Goods.GroupBy("Products, Characteristic, CCDNumber", "Count, QuantityByGBRN");
	Query.SetParameter("Goods", Goods);
	
	SetPrivilegedMode(True);
	TableOfGoods.Load(Query.Execute().Unload());
	SetPrivilegedMode(False);
	
	Items.TableOfGoodsNumberOfPackages.Visible = Not ByPhysicalCountResults;
	Items.TableOfGoodsNumberOfPackagesReal.Visible = ByPhysicalCountResults;
		
EndProcedure

&AtClient
Procedure OpenProductItemCard()

	CurrentData = Items.TableOfGoods.CurrentData;
	
	If CurrentData <> Undefined Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	EndIf;

EndProcedure

#EndRegion

#EndRegion
