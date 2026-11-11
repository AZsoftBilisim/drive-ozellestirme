
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DocumentReturnPolicy = Parameters.DocumentReturnPolicy;
	Date = Parameters.Date;
	Currency = Parameters.Currency;
	PriceIncludesVAT = Parameters.PriceIncludesVAT;
	Partner = Parameters.Partner;
	Terms = Parameters.Terms;
	Organization = Parameters.Organization;
	Counterparty = Parameters.Counterparty;
	VATTaxation = Parameters.VATTaxation;
	Warehouse = Parameters.Warehouse;
	PurchaseByImport = Parameters.PurchaseByImport;
	DepositForPackageIsRequired = Parameters.DepositForPackageIsRequired;
	
	If PurchaseByImport Then
		Period = New StandardPeriod();
		Period.EndDate = Date;
		Items.PeriodStartDate_.Enabled = False;
	Else
		Period = Common.CommonSettingsStorageLoad("SelectGoodsByReceipts","ProductSelectionPeriodForReceipts");
		LineOfBusiness = Parameters.LineOfBusiness;
	EndIf; 
		
	If Period.EndDate = Date(1, 1, 1) Then
		Period.Variant = StandardPeriodVariant.Month;
	EndIf; 
	
	FillInTheGoodsTable();
	CalculateTotalsOnGoodsTable();
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		GoodsHelpText,
		GoodsSelectedQuantity,
		GoodsSelectedAmount,
		Currency);
	
	UseReusablePackage = GetFunctionalOption("UseReusablePackage");
	
	If UseReusablePackage And Parameters.ShowContainers Then
		
		FillInTareTable();
		CalculateTotalsOnTareTable();
		SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
			PackagingInformationLabel,
			PackageSelectedQuantity,
			PackageSelectedAmount,
			Currency);
		
		If Not Parameters.ShowProducts_ Then
			Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
			Items.Pages.CurrentPage = Items.TarePage;
		Else
			Items.Pages.CurrentPage = Items.GoodsPage;
		EndIf;
		
	Else
		
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
		Items.Pages.CurrentPage = Items.GoodsPage;
		
	EndIf;
		
	ItemArray = New Array();
	ItemArray.Add("PackageTable");
	ItemArray.Add("PackagingInformationLabelSelections");
	ItemArray.Add("PackagingInformationLabel");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", UseReusablePackage And Parameters.ShowContainers);
	
	ItemArray = New Array();
	ItemArray.Add("PeriodOption");
	ItemArray.Add("PeriodStartDate_");
	ItemArray.Add("PeriodEndDate_2");
	ItemArray.Add("Refresh");
	ItemArray.Add("TableOfGoods");
	ItemArray.Add("GoodsHelpText");
	ItemArray.Add("ProductsInformationLabelSelections");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Parameters.ShowProducts_);
	
	ItemArray = New Array();
	ItemArray.Add("TableOfGoodsPrice");
	ItemArray.Add("TableOfGoodsPercentRateOfManualDiscount");
	ItemArray.Add("TableOfGoodsManualDiscount");
	ItemArray.Add("TableOfGoodsPurpose");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Not PurchaseByImport);

	SelectGoodsClientServer.CreateSelectionFormHeader(Title, DocumentReturnPolicy);
	CreateInformationLabelSelections();
	
	Items.TableOfGoodsPurpose.Visible = Not GetFunctionalOption("BaseVersion");
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForceCloseTheForm Or Exit Then
		Return;
	EndIf;
	
	If Not MoveToDocument And (GoodsSelectedQuantity > 0 Or PackageSelectedQuantity > 0)  Then 
		
		If GoodsSelectedQuantity > 0 And PackageSelectedQuantity > 0 Then
			QueryText = NStr("vi = 'Hàng hóa đã chọn và bao bì luân chuyển chưa được chuyển vào chứng từ. Chuyển vào?';
							|ru = 'Подобранные товары и многооборотная тара не перенесены в документ. Перенести?';
							|en = 'Picked items and reusable packaging are not added to the document. Do you want to add them?'; fa = 'Picked items and reusable packaging are not added to the document. Do you want to add them?';
							|it = 'La merce selezionata e l''imballaggio restituibile non sono stati trasferiti nel documento. Trasferire?';
							|pl = 'Wybrane wiersze pozycji i tara wielokrotnego użytku nie zostały przeniesione do dokumentu. Przenieść?';
							|tr = 'Seçili ürünler ve yeniden kullanılabilir ambalajlar belgeye aktarılmadı. Transfer et?'")
		ElsIf GoodsSelectedQuantity > 0 Then
			QueryText = NStr("vi = 'Hàng hóa đã chọn chưa được chuyển vào chứng từ. Chuyển?';
							|ru = 'Подобранные товары не перенесены в документ. Перенести?';
							|en = 'Picked items are not added to the document. Do you want to add them?'; fa = 'Picked items are not added to the document. Do you want to add them?';
							|it = 'La merce selezionata non è stata trasferita nel documento. Trasferire?';
							|pl = 'Wybrane wiersze pozycji nie zostały przeniesione do dokumentu. Przenieść?';
							|tr = 'Seçili ürünler belgeye aktarılmadı. Aktarılsın mı?'")
		ElsIf PackageSelectedQuantity > 0 Then
			QueryText = NStr("vi = 'Bao bì luân chuyển đã chọn chưa được chuyển vào chứng từ. Chuyển vào?';
							|ru = 'Подобранная многооборотная тара не перенесена в документ. Перенести?';
							|en = 'Picked reusable packaging was not transferred to the document. Transfer?'; fa = 'Picked reusable packaging was not transferred to the document. Transfer?';
							|it = 'L''imballaggio restituibile non è stato trasferito nel documento. Trasferire?';
							|pl = 'Wybrana tara wielokrotnego użytku nie została przeniesiona do dokumentu. Przenieść?';
							|tr = 'Seçilen yeniden kullanılabilir ambalajlar belgeye aktarılmadı. Transfer et?'")
		EndIf;
		
		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			QueryText,
			QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		MoveToDocument = True;
		Close();
	ElsIf UserAnswer = DialogReturnCode.No Then
		ForceCloseTheForm = True;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	If MoveToDocument Then
		
		GoodsAddressInStorage = PutProductsInStorage();
		Structure = New Structure("GoodsAddressInStorage", GoodsAddressInStorage);
		MoveToDocument = True;
		NotifyChoice(Structure);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	If PurchaseByImport Then
		Settings.Delete("Period");
	EndIf;
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Common.CommonSettingsStorageSave("SelectGoodsByReceipts","ProductSelectionPeriodForReceipts", Period);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure TableOfGoodsSelectedOnChange(Item)
	
	Data = Items.TableOfGoods.CurrentData;
	
	AdditionSign = ?(Data.Selected, 1, -1);
	GoodsSelectedQuantity = GoodsSelectedQuantity + AdditionSign;
	GoodsSelectedAmount = GoodsSelectedAmount + Data.AmountIncludingVAT*AdditionSign;
	
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		GoodsHelpText,
		GoodsSelectedQuantity,
		GoodsSelectedAmount,
		Currency);
	
EndProcedure

&AtClient
Procedure PackageTableSelectedOnChange(Item)
	
	Data = Items.PackageTable.CurrentData;
	
	AdditionSign = ?(Data.Selected, 1, -1);
	PackageSelectedQuantity = PackageSelectedQuantity + AdditionSign;
	PackageSelectedAmount = PackageSelectedAmount + Data.Sum*AdditionSign;
	
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		PackagingInformationLabel,
		PackageSelectedQuantity,
		PackageSelectedAmount,
		Currency);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()
	
	MoveToDocument = True;
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure ToChooseTheProducts()
	
	SelectAllProductsOnServer();
	
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		GoodsHelpText,
		GoodsSelectedQuantity,
		GoodsSelectedAmount,
		Currency);
	
EndProcedure

&AtClient
Procedure ExcludeGoods()
	
	ExcludeAllProductsOnServer();
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		GoodsHelpText,
		GoodsSelectedQuantity,
		GoodsSelectedAmount,
		Currency);
	
EndProcedure

&AtClient
Procedure SelectSelectedGoods(Command)
	
	RowsArray = Items.TableOfGoods.SelectedRows;
	For Each RowID In RowsArray Do
		String = TableOfGoods.FindByID(RowID);
		If Not String.Selected Then
			String.Selected = True;
			GoodsSelectedQuantity = GoodsSelectedQuantity + 1;
			GoodsSelectedAmount = GoodsSelectedAmount + String.AmountIncludingVAT;
		EndIf;
	EndDo;
	
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		GoodsHelpText,
		GoodsSelectedQuantity,
		GoodsSelectedAmount, 
		Currency);
	
EndProcedure

&AtClient
Procedure ExcludeSelectedGoods(Command)
	
	RowsArray = Items.TableOfGoods.SelectedRows;
	For Each RowID In RowsArray Do
		String = TableOfGoods.FindByID(RowID);
		If String.Selected Then
			String.Selected = False;
			GoodsSelectedQuantity = GoodsSelectedQuantity - 1;
			GoodsSelectedAmount = GoodsSelectedAmount - String.AmountIncludingVAT;
		EndIf;
	EndDo;
	
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		GoodsHelpText,
		GoodsSelectedQuantity,
		GoodsSelectedAmount,
		Currency);
	
EndProcedure

&AtClient
Procedure ChooseAContainer()
	
	SelectAllContainersOnServer();
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		PackagingInformationLabel,
		PackageSelectedQuantity,
		PackageSelectedAmount,
		Currency);
	
EndProcedure

&AtClient
Procedure ExcludePackage()
	
	ExcludeAllContainersOnServer();
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		PackagingInformationLabel,
		PackageSelectedQuantity,
		PackageSelectedAmount,
		Currency);
	
EndProcedure

&AtClient
Procedure SelectTheSelectedContainer(Command)
	
	RowsArray = Items.PackageTable.SelectedRows;
	For Each RowID In RowsArray Do
		String = PackageTable.FindByID(RowID);
		If Not String.Selected Then
			String.Selected = True;
			PackageSelectedQuantity = PackageSelectedQuantity + 1;
			PackageSelectedAmount = PackageSelectedAmount + String.Sum;
		EndIf;
	EndDo;
	
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		PackagingInformationLabel,
		PackageSelectedQuantity,
		PackageSelectedAmount,
		Currency);
	
EndProcedure

&AtClient
Procedure ExcludeSelectedPackaging(Command)
	
	RowsArray = Items.PackageTable.SelectedRows;
	For Each RowID In RowsArray Do
		String = PackageTable.FindByID(RowID);
		If String.Selected Then
			String.Selected = False;
			PackageSelectedQuantity = PackageSelectedQuantity - 1;
			PackageSelectedAmount = PackageSelectedAmount - String.Sum
		EndIf;
	EndDo;
	
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		PackagingInformationLabel,
		PackageSelectedQuantity,
		PackageSelectedAmount,
		Currency);
	
EndProcedure

&AtClient
Procedure UpdateGoods(Command)
	
	FillInTheGoodsTable();
	
EndProcedure

&AtClient
Procedure UpdatePackaging(Command)
	
	FillInTareTable();
	
EndProcedure

&AtClient
Procedure PeriodOptionOnChange(Item)
	
	FillInTheGoodsTable();
	
EndProcedure

&AtClient
Procedure PeriodStartDate_OnChange(Item)
	
	FillInTheGoodsTable();
	
EndProcedure

&AtClient
Procedure PeriodEndDate_2OnChange(Item)
	
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
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsVATRate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsVATAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsPercentRateOfManualDiscount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "TableOfGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "TableOfGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PackageTableReturnDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PackageTable.ReturnDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);

	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);

EndProcedure

#Region Other

&AtServer
Function PutProductsInStorage()
	
	Goods = TableOfGoods.Unload(New Structure("Selected", True));
	For Each CurRow In PackageTable Do
		If CurRow.Selected Then
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, CurRow);
			NewRow.NumberOfPackages = CurRow.Count;
			NewRow.AmountIncludingVAT = CurRow.Sum;
			NewRow.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
		EndIf;
	EndDo;
	ReturnedStructure = New Structure("Goods", Goods);
	GoodsAddressInStorage = PutToTempStorage(ReturnedStructure, UUID);
	
	Return GoodsAddressInStorage;
	
EndFunction

&AtServer
Procedure FillInTheGoodsTable()
	
	TableOfGoods.Clear();
	
	Query = New Query;
	
	If PurchaseByImport Then
		Query.Text = QueryTextPurchaseByImport();
		Query.SetParameter("Partner", Partner);
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("Warehouse", Warehouse);
		Query.SetParameter("FilterByWarehouse", ValueIsFilled(Warehouse));  		
		EndDate =  New Boundary(Period.EndDate, BoundaryType.Including);
		Query.SetParameter("Date", EndDate);
		Query.SetParameter("DateOfReceipt", ?(ValueIsFilled(Period.StartDate), Period.StartDate, NULL));
		Query.SetParameter("ImportDocumentType", AccountingForTraceableGoodsLocalization.IDCustomsDeclarationImport());
		
		EconomicOperationsOfSeparatePurchase = PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections();
		Query.SetParameter("EconomicOperationsOfSeparatePurchase", EconomicOperationsOfSeparatePurchase);

		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		
		While Selection.Next() Do
			
			NewRow = TableOfGoods.Add();
			FillPropertyValues(NewRow, Selection);
			
			If Currency <> Selection.CurrencyOfReceipt And ValueIsFilled(Selection.CurrencyOfReceipt) Then
				NewCurrencyRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, Selection.DateOfReceipt, BaseCurrency);
				OldCurrencyRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(Selection.CurrencyOfReceipt, Selection.DateOfReceipt, BaseCurrency);
				
				NewRow.AmountIncludingVAT = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
					NewRow.AmountIncludingVAT,
					OldCurrencyRate,
					NewCurrencyRate);
					
				PriceManagementSystem.RecalculateAmountsInRowWithVAT(
					NewRow,
					False,
					False,
					False);

			EndIf;
			
			If Selection.PriceIncludesVAT <> False Then
				// in the Amount field we will get the amount without VAT
				PriceManagementSystem.RecalculateAmountsInRowWithVAT(NewRow, False, False, False);
			EndIf;
			
		EndDo;

	Else
		Query.Text = QueryTextReturns();
		Query.SetParameter("Partner", Partner);
		Query.SetParameter("Counterparty", Counterparty);
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("StartDate", Period.StartDate);
		Query.SetParameter("EndDate", Period.EndDate);
		Query.SetParameter("Terms", Terms);
		Query.SetParameter("VATTaxation", VATTaxation);
		Query.SetParameter("DocumentReturnPolicy", DocumentReturnPolicy);
		Query.SetParameter("LineOfBusiness", LineOfBusiness);

		TableOfGoodsUnloading = Query.Execute().Unload();
		TheStructureOfTheSearch = New Structure("Products, Characteristic, 
			|Purpose, VATRate, Warehouse, DocumentInflow");
		
		For Each String In TableOfGoodsUnloading Do
			
			If String.Count < 0 Then
				
				FillPropertyValues(TheStructureOfTheSearch, String);
				PurchaseLines = TableOfGoodsUnloading.FindRows(TheStructureOfTheSearch);
				
				For Each PurchaseLine In PurchaseLines Do
					
					If PurchaseLine.Count < 0 Then
						Continue;
					EndIf; 
					
					String.Count 		= -String.Count;
					String.Sum 			= -String.Sum;
					String.VATAmount 		= -String.VATAmount;
					String.AmountIncludingVAT 		= -String.AmountIncludingVAT;
					
					If String.Count > PurchaseLine.Count Then
						AmountToDeduct 	= PurchaseLine.Count;
						AmountToDeduct_ 		= PurchaseLine.Sum;
						AmountOfVATDeducted 	= PurchaseLine.VATAmount;
						AmountWithVATDeductible 	= PurchaseLine.AmountIncludingVAT;
					Else
						AmountToDeduct 	= String.Count;
						AmountToDeduct_ 		= String.Sum;
						AmountOfVATDeducted 	= String.VATAmount;
						AmountWithVATDeductible 	= String.AmountIncludingVAT;
					EndIf;
					
					PurchaseLine.Count 	= PurchaseLine.Count - AmountToDeduct;
					String.Count 			= String.Count - AmountToDeduct;
					
					PurchaseLine.Sum 		= PurchaseLine.Sum - AmountToDeduct_;
					String.Sum 				= String.Sum - AmountToDeduct_;
					
					PurchaseLine.VATAmount 		= PurchaseLine.VATAmount - AmountOfVATDeducted;
					String.VATAmount 			= String.VATAmount - AmountOfVATDeducted;
					
					PurchaseLine.AmountIncludingVAT 	= PurchaseLine.AmountIncludingVAT - AmountWithVATDeductible;
					String.AmountIncludingVAT 			= String.AmountIncludingVAT - AmountWithVATDeductible;
					
				EndDo;
				
			EndIf;
				
		EndDo;
		
		ArrayOfRowsToDelete_1 = New Array();
		For Each String In TableOfGoodsUnloading Do 
			If String.Count <= 0 Then
				ArrayOfRowsToDelete_1.Add(String);
			EndIf;
		EndDo;
		For Each String In ArrayOfRowsToDelete_1 Do
			TableOfGoodsUnloading.Delete(String);
		EndDo;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		
		BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		RowsToProcess = New Array;
		ReceiptCurrencies = New Map;
		For Each String In TableOfGoodsUnloading Do
			
			NewRow = TableOfGoods.Add();
			FillPropertyValues(NewRow, String);
			RowsToProcess.Add(NewRow);
			ReceiptCurrencies.Insert(NewRow, String.CurrencyOfReceipt);

		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			TableOfGoods,
			CachedValues);
				
		For Each NewRow In RowsToProcess Do
			CurrencyOfReceipt = ReceiptCurrencies.Get(NewRow);
			
			If Currency <> CurrencyOfReceipt Then
				NewCurrencyRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, Date, BaseCurrency);
				OldCurrencyRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfReceipt, Date, BaseCurrency);
				
				NewRow.AmountIncludingVAT = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
					NewRow.AmountIncludingVAT,
					OldCurrencyRate,
					NewCurrencyRate);
				
			EndIf;
			
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(
				NewRow,
				PriceIncludesVAT,
				False,
				False,
				True);
			
		EndDo;
	EndIf;
	
	
EndProcedure

&AtServer
Procedure FillInTareTable()
	
	PackageTable.Clear();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ReceivedReturnablePackagingBalance.Products        AS Products,
	|	ReceivedReturnablePackagingBalance.Characteristic      AS Characteristic,
	|	ReceivedReturnablePackagingBalance.Partner             AS Partner,
	|	ReceivedReturnablePackagingBalance.DocumentInflow AS DocumentInflow,
	|	ReceivedReturnablePackagingBalance.CountBalance   AS Count,
	|	ReceivedReturnablePackagingBalance.SumBalance        AS Sum
	|INTO
	|	TTAcceptedReturnPackaging
	|FROM
	|	AccumulationRegister.ReceivedReturnablePackaging.Balance(
	|			,
	|			Partner = &Partner
	|			AND DocumentInflow.Organization = &Organization
	|			AND DocumentInflow.Counterparty = &Counterparty
	|			AND DocumentInflow.Organization = &Organization
	|			AND (DocumentInflow.Terms = &Terms OR NOT DocumentInflow REFS Document.VendorInvoice)
	|			AND DocumentInflow.Currency = &Currency
	|			AND (DocumentInflow.VATTaxation = &VATTaxation OR NOT DocumentInflow REFS Document.VendorInvoice)
	|			AND DocumentInflow.PackageDepositIsRequired = &DepositForPackageIsRequired
	|		) AS ReceivedReturnablePackagingBalance
	|
	|UNION ALL
	|
	|SELECT
	|	AcceptedReturnMovementPackaging.Products        AS Products,
	|	AcceptedReturnMovementPackaging.Characteristic      AS Characteristic,
	|	AcceptedReturnMovementPackaging.Partner             AS Partner,
	|	AcceptedReturnMovementPackaging.DocumentInflow AS DocumentInflow,
	|	CASE WHEN AcceptedReturnMovementPackaging.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			-AcceptedReturnMovementPackaging.Count
	|		ELSE
	|			AcceptedReturnMovementPackaging.Count
	|	END AS Count,
	|	CASE WHEN AcceptedReturnMovementPackaging.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			-AcceptedReturnMovementPackaging.Sum
	|		ELSE
	|			AcceptedReturnMovementPackaging.Sum
	|	END AS Sum
	|FROM
	|	AccumulationRegister.ReceivedReturnablePackaging AS AcceptedReturnMovementPackaging
	|WHERE
	|	AcceptedReturnMovementPackaging.Recorder = &DocumentReturnPolicy
	|;
	|SELECT
	|	TTAcceptedReturnPackaging.Products              AS Products,
	|	TTAcceptedReturnPackaging.Characteristic            AS Characteristic,
	|	TTAcceptedReturnPackaging.Partner                   AS Partner,
	|	TTAcceptedReturnPackaging.DocumentInflow       AS DocumentInflow,
	|	TTAcceptedReturnPackaging.DocumentInflow.Number AS NumberOfReceipt,
	|	TTAcceptedReturnPackaging.DocumentInflow.Date  AS DateOfReceipt,
	|	TTAcceptedReturnPackaging.DocumentInflow.ReusablePackagesReturnDate AS ReturnDate,
	|	SUM(TTAcceptedReturnPackaging.Count)         AS Count,
	|	SUM(TTAcceptedReturnPackaging.Sum)              AS Sum,
	|	CASE
	|		WHEN
	|			SUM(TTAcceptedReturnPackaging.Count) = 0
	|		THEN
	|			SUM(TTAcceptedReturnPackaging.Sum)
	|		ELSE
	|			SUM(TTAcceptedReturnPackaging.Sum) / SUM(TTAcceptedReturnPackaging.Count)
	|	END AS Price
	|FROM
	|	TTAcceptedReturnPackaging
	|GROUP BY
	|	TTAcceptedReturnPackaging.Products,
	|	TTAcceptedReturnPackaging.Characteristic,
	|	TTAcceptedReturnPackaging.Partner,
	|	TTAcceptedReturnPackaging.DocumentInflow
	|HAVING
	|	SUM(TTAcceptedReturnPackaging.Count) > 0
	|ORDER BY
	|	ReturnDate ASC,
	|	Products.Description ASC,
	|	Characteristic.Description ASC
	|";

	Query.SetParameter("Partner",                 Partner);
	Query.SetParameter("Counterparty",              Counterparty);
	Query.SetParameter("Organization",             Organization);
	Query.SetParameter("Terms",              Terms);
	Query.SetParameter("Currency",                  Currency);
	Query.SetParameter("VATTaxation",      VATTaxation);
	Query.SetParameter("DocumentReturnPolicy",        DocumentReturnPolicy);
	Query.SetParameter("DepositForPackageIsRequired", DepositForPackageIsRequired);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		NewRow = PackageTable.Add();
		FillPropertyValues(NewRow, Selection);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateTotalsOnGoodsTable()
	
	GoodsSelectedQuantity = 0;
	GoodsSelectedAmount = 0;
	
	For LineNumber=0 To TableOfGoods.Count()-1 Do
		
		If TableOfGoods[LineNumber].Selected Then
			GoodsSelectedQuantity = GoodsSelectedQuantity + 1;
			GoodsSelectedAmount = GoodsSelectedAmount + TableOfGoods[LineNumber].AmountIncludingVAT;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateTotalsOnTareTable()
	
	PackageSelectedQuantity = 0;
	PackageSelectedAmount = 0;
	
	For LineNumber=0 To PackageTable.Count()-1 Do
		
		If PackageTable[LineNumber].Selected Then
			PackageSelectedQuantity = PackageSelectedQuantity + 1;
			PackageSelectedAmount = PackageSelectedAmount + PackageTable[LineNumber].Sum;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SelectAllProductsOnServer()
	
	For Each TableRow In TableOfGoods Do
		TableRow.Selected = True;
	EndDo;
	
	GoodsSelectedQuantity = TableOfGoods.Count();
	GoodsSelectedAmount = TableOfGoods.Total("AmountIncludingVAT");
	
EndProcedure

&AtServer
Procedure ExcludeAllProductsOnServer()
	
	For Each TableRow In TableOfGoods Do
		TableRow.Selected = False;
	EndDo;
	
	GoodsSelectedQuantity = 0;
	GoodsSelectedAmount = 0;
	
EndProcedure

&AtServer
Procedure SelectAllContainersOnServer()
	
	For Each TableRow In PackageTable Do
		TableRow.Selected = True;
	EndDo;
	
	PackageSelectedQuantity = PackageTable.Count();
	PackageSelectedAmount = PackageTable.Total("Sum");
	
EndProcedure

&AtServer
Procedure ExcludeAllContainersOnServer()
	
	For Each TableRow In PackageTable Do
		TableRow.Selected = False;
	EndDo;
	
	PackageSelectedQuantity = 0;
	PackageSelectedAmount = 0;
	
EndProcedure

&AtServer
Procedure CreateInformationLabelSelections()
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	ProductsInformationLabelSelections = NStr("vi = 'Lọc theo: %Organization%, %Partner%, %Counterparty%, %Terms%, %VATTaxation%, %Warehouse%';
												|ru = 'Отбор по: %Organization%, %Partner%, %Counterparty%, %Terms%, %VATTaxation%, %Warehouse%';
												|en = 'Filter by: %Organization%, %Partner%, %Counterparty%, %Terms%, %VATTaxation%, %Warehouse%'; fa = 'Filter by: %Organization%, %Partner%, %Counterparty%, %Terms%, %VATTaxation%, %Warehouse%';
												|it = 'Selezione per: %Organization%, %Partner%, %Counterparty%, %Terms%, %VATTaxation%, %Warehouse%';
												|pl = 'Filtr wg: %Organization%, %Partner%, %Counterparty%, %Terms%, %VATTaxation%, %Warehouse%';
												|tr = 'Filtre: %Organization%, %Partner%, %Counterparty%, %Terms%, %VATTaxation%, %Warehouse%'");
	If UsePartnersAsCounterparties Then
		ProductsInformationLabelSelections = StrReplace(ProductsInformationLabelSelections,", %Counterparty%", "");
	EndIf;
	ProductsInformationLabelSelections = StrReplace(ProductsInformationLabelSelections,"%Organization%", Organization);
	ProductsInformationLabelSelections = StrReplace(ProductsInformationLabelSelections,"%Partner%", Partner);
	ProductsInformationLabelSelections = StrReplace(ProductsInformationLabelSelections,"%Counterparty%", Counterparty);
	ProductsInformationLabelSelections = StrReplace(ProductsInformationLabelSelections,"%Terms%", Terms);
	ProductsInformationLabelSelections = StrReplace(ProductsInformationLabelSelections,"%VATTaxation%", VATTaxation);
	ProductsInformationLabelSelections = StrReplace(ProductsInformationLabelSelections,"%Warehouse%", Warehouse);
	
	PackagingInformationLabelSelections = NStr("vi = 'Lọc theo: %Organization%, %Partner%, %Counterparty%, %Currency%, %Terms%, %VATTaxation%';
												|ru = 'Отбор по: %Organization%, %Partner%, %Counterparty%, %Currency%, %Terms%, %VATTaxation%';
												|en = 'Filter by: %Organization%, %Partner%, %Counterparty%, %Currency%, %Terms%, %VATTaxation%'; fa = 'Filter by: %Organization%, %Partner%, %Counterparty%, %Currency%, %Terms%, %VATTaxation%';
												|it = 'Selezione per:  %Organization%, %Partner%, %Counterparty%, %Currency%, %Terms%, %VATTaxation%';
												|pl = 'Filtr wg: %Organization%, %Partner%, %Counterparty%, %Currency%, %Terms%, %VATTaxation%';
												|tr = 'Filtre: %Organization%, %Partner%, %Counterparty%, %Currency%, %Terms%, %VATTaxation%'");
	If UsePartnersAsCounterparties Then
		PackagingInformationLabelSelections = StrReplace(PackagingInformationLabelSelections,", %Counterparty%", "");
	EndIf;
	PackagingInformationLabelSelections = StrReplace(PackagingInformationLabelSelections,"%Organization%", Organization);
	PackagingInformationLabelSelections = StrReplace(PackagingInformationLabelSelections,"%Partner%", Partner);
	PackagingInformationLabelSelections = StrReplace(PackagingInformationLabelSelections,"%Counterparty%", Counterparty);
	PackagingInformationLabelSelections = StrReplace(PackagingInformationLabelSelections,"%Terms%", Terms);
	PackagingInformationLabelSelections = StrReplace(PackagingInformationLabelSelections,"%Currency%", Currency);
	PackagingInformationLabelSelections = StrReplace(PackagingInformationLabelSelections,"%VATTaxation%", VATTaxation);
	
EndProcedure

&AtServerNoContext
Function QueryTextReturns()
	
	QueryText =
	"SELECT ALLOWED
	|	VendorInvoice.Ref AS Ref
	|INTO ReceiptDocuments
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|	ON
	|		VendorInvoice.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|		AND RegisterOfDocumentsStornoCorrection.Posted
	|		AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|WHERE
	|	VendorInvoice.Date BETWEEN &StartDate AND &EndDate
	|	AND VendorInvoice.Posted
	|	AND VendorInvoice.Counterparty = &Counterparty
	|	AND VendorInvoice.Organization = &Organization
	|	AND VendorInvoice.Terms = &Terms
	|	AND VendorInvoice.VATTaxation = &VATTaxation
	|	AND VendorInvoice.Partner = &Partner
	|	AND VendorInvoice.LineOfBusiness = &LineOfBusiness
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MAX(PurchaseAdjustment.Date) AS Date,
	|	ReceiptDocuments.Ref AS ReceiptLink
	|INTO AdjustmentData
	|FROM
	|	ReceiptDocuments AS ReceiptDocuments
	|		LEFT JOIN Document.PurchaseAdjustment AS PurchaseAdjustment
	|		ON (PurchaseAdjustment.DocumentBasis = ReceiptDocuments.Ref)
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|		ON PurchaseAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|		AND RegisterOfDocumentsStornoCorrection.Posted
	|		AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|WHERE
	|	PurchaseAdjustment.Posted
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|
	|GROUP BY
	|	ReceiptDocuments.Ref
	|
	|INDEX BY
	|	ReceiptLink
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MAX(PurchaseAdjustment.Ref) AS Ref,
	|	MAX(PurchaseAdjustment.Ref.Date) AS Date,
	|	PurchaseAdjustment.Ref.DocumentBasis AS ReceiptLink
	|INTO LastAdjustmentData
	|FROM
	|	Document.PurchaseAdjustment AS PurchaseAdjustment
	|WHERE
	|	(PurchaseAdjustment.Ref.DocumentBasis, PurchaseAdjustment.Ref.Date) IN
	|			(SELECT
	|				AdjustmentData.ReceiptLink AS ReceiptLink,
	|				AdjustmentData.Date AS Date
	|			FROM
	|				AdjustmentData)
	|
	|GROUP BY
	|	PurchaseAdjustment.Ref.DocumentBasis
	|
	|INDEX BY
	|	Ref,
	|	ReceiptLink
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CASE
	|		WHEN LastAdjustmentData.Ref IS NULL 
	|			THEN ReceiptDocuments.Ref
	|		ELSE LastAdjustmentData.Ref
	|	END AS Ref
	|INTO LinksToReceipts
	|FROM
	|	ReceiptDocuments AS ReceiptDocuments
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON ReceiptDocuments.Ref = LastAdjustmentData.ReceiptLink
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AdjustmentOfAcquisitionOfGoods.Products AS Products,
	|	AdjustmentOfAcquisitionOfGoods.Characteristic AS Characteristic,
	|	AdjustmentOfAcquisitionOfGoods.Purpose AS Purpose,
	|	AdjustmentOfAcquisitionOfGoods.Price AS Price,
	|	AdjustmentOfAcquisitionOfGoods.Ref.DocumentBasis AS DocumentInflow,
	|	AdjustmentOfAcquisitionOfGoods.Package,
	|	AdjustmentOfAcquisitionOfGoods.VATRate AS VATRate,
	|	AdjustmentOfAcquisitionOfGoods.Warehouse AS Warehouse,
	|	NULL AS PercentRateOfManualDiscount,
	|	AdjustmentOfAcquisitionOfGoods.Ref.PriceIncludesVAT AS PriceIncludesVAT,
	|	AdjustmentOfAcquisitionOfGoods.Ref.Currency AS Currency,
	|	AdjustmentOfAcquisitionOfGoods.Ref.DocumentBasis.Date AS DateOfReceipt,
	|	AdjustmentOfAcquisitionOfGoods.Ref.DocumentBasis.Number AS NumberOfReceipt,
	|	AdjustmentOfAcquisitionOfGoods.Ref.DocumentBasis.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	SUM(AdjustmentOfAcquisitionOfGoods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(AdjustmentOfAcquisitionOfGoods.Count) AS Count,
	|	SUM(AdjustmentOfAcquisitionOfGoods.Sum) AS Sum,
	|	SUM(AdjustmentOfAcquisitionOfGoods.VATAmount) AS VATAmount,
	|	SUM(AdjustmentOfAcquisitionOfGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	NULL AS ManualDiscount,
	|	NULL AS LineNumber
	|INTO ReceiptDocumentData_
	|FROM
	|	LinksToReceipts AS LinksToReceipts
	|		INNER JOIN Document.PurchaseAdjustment.Goods AS AdjustmentOfAcquisitionOfGoods
	|		ON (AdjustmentOfAcquisitionOfGoods.Ref = LinksToReceipts.Ref)
	|
	|GROUP BY
	|	AdjustmentOfAcquisitionOfGoods.Products,
	|	AdjustmentOfAcquisitionOfGoods.Characteristic,
	|	AdjustmentOfAcquisitionOfGoods.Purpose,
	|	AdjustmentOfAcquisitionOfGoods.Price,
	|	AdjustmentOfAcquisitionOfGoods.Ref.DocumentBasis,
	|	AdjustmentOfAcquisitionOfGoods.Package,
	|	AdjustmentOfAcquisitionOfGoods.VATRate,
	|	AdjustmentOfAcquisitionOfGoods.Warehouse,
	|	AdjustmentOfAcquisitionOfGoods.Ref.PriceIncludesVAT,
	|	AdjustmentOfAcquisitionOfGoods.Ref.Currency,
	|	AdjustmentOfAcquisitionOfGoods.Ref.DocumentBasis.Date,
	|	AdjustmentOfAcquisitionOfGoods.Ref.DocumentBasis.Number
	|
	|UNION ALL
	|
	|SELECT
	|	PurchaseOfGoodsServicesGoods.Products AS Products,
	|	PurchaseOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	PurchaseOfGoodsServicesGoods.Purpose AS Purpose,
	|	PurchaseOfGoodsServicesGoods.Price AS Price,
	|	PurchaseOfGoodsServicesGoods.Ref AS DocumentInflow,
	|	PurchaseOfGoodsServicesGoods.Package AS Package,
	|	PurchaseOfGoodsServicesGoods.VATRate AS VATRate,
	|	PurchaseOfGoodsServicesGoods.Warehouse AS Warehouse,
	|	PurchaseOfGoodsServicesGoods.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	PurchaseOfGoodsServicesGoods.Ref.PriceIncludesVAT AS PriceIncludesVAT,
	|	PurchaseOfGoodsServicesGoods.Ref.Currency AS Currency,
	|	PurchaseOfGoodsServicesGoods.Ref.Date AS DateOfReceipt,
	|	PurchaseOfGoodsServicesGoods.Ref.Number AS NumberOfReceipt,
	|	PurchaseOfGoodsServicesGoods.Ref.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	SUM(PurchaseOfGoodsServicesGoods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(PurchaseOfGoodsServicesGoods.Count) AS Count,
	|	SUM(PurchaseOfGoodsServicesGoods.Sum) AS Sum,
	|	SUM(PurchaseOfGoodsServicesGoods.VATAmount) AS VATAmount,
	|	SUM(PurchaseOfGoodsServicesGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	SUM(PurchaseOfGoodsServicesGoods.ManualDiscount) AS ManualDiscount,
	|	MIN(LineNumber) AS LineNumber
	|FROM
	|	LinksToReceipts AS LinksToReceipts
	|		INNER JOIN Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|		ON (PurchaseOfGoodsServicesGoods.Ref = LinksToReceipts.Ref)
	|
	|GROUP BY
	|	PurchaseOfGoodsServicesGoods.Products,
	|	PurchaseOfGoodsServicesGoods.Characteristic,
	|	PurchaseOfGoodsServicesGoods.Purpose,
	|	PurchaseOfGoodsServicesGoods.Price,
	|	PurchaseOfGoodsServicesGoods.Ref,
	|	PurchaseOfGoodsServicesGoods.VATRate,
	|	PurchaseOfGoodsServicesGoods.PercentRateOfManualDiscount,
	|	PurchaseOfGoodsServicesGoods.Warehouse,
	|	PurchaseOfGoodsServicesGoods.Package,
	|	PurchaseOfGoodsServicesGoods.Ref.PriceIncludesVAT,
	|	PurchaseOfGoodsServicesGoods.Ref.Currency,
	|	PurchaseOfGoodsServicesGoods.Ref.Date,
	|	PurchaseOfGoodsServicesGoods.Ref.Number
	|
	|INDEX BY
	|	Products,
	|	Characteristic, 
	|	Purpose,
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfCheckedProducts.Products AS Products,
	|	TableOfCheckedProducts.Characteristic AS Characteristic,
	|	TableOfCheckedProducts.Purpose AS Purpose,
	|	TableOfCheckedProducts.DocumentInflow,
	|	TableOfCheckedProducts.DocumentInflow.Date AS DateOfReceipt,
	|	TableOfCheckedProducts.DocumentInflow.Number AS NumberOfReceipt,
	|	TableOfCheckedProducts.DocumentInflow.Currency AS Currency,
	|	TableOfCheckedProducts.DocumentInflow.PriceIncludesVAT AS PriceIncludesVAT,
	|	TableOfCheckedProducts.Package,
	|	TableOfCheckedProducts.Ref.Warehouse AS Warehouse,
	|	TableOfCheckedProducts.VATRate AS VATRate,
	|	SUM(TableOfCheckedProducts.NumberOfPackages) AS NumberOfPackages,
	|	SUM(TableOfCheckedProducts.Count) AS Count,
	|	SUM(TableOfCheckedProducts.Sum) AS Sum,
	|	SUM(TableOfCheckedProducts.VATAmount) AS VATAmount,
	|	SUM(TableOfCheckedProducts.AmountIncludingVAT) AS AmountIncludingVAT
	|INTO ReturnDocumentData
	|FROM
	|	ReceiptDocuments AS ReceiptDocuments
	|		LEFT JOIN Document.ReturnOfGoodsToVendor.Goods AS TableOfCheckedProducts
	|		ON (TableOfCheckedProducts.DocumentInflow = ReceiptDocuments.Ref)
	|			AND TableOfCheckedProducts.Ref <> &DocumentReturnPolicy
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|		ON TableOfCheckedProducts.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|			AND RegisterOfDocumentsStornoCorrection.Posted
	|			AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|WHERE
	|	TableOfCheckedProducts.Ref.Posted
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|
	|GROUP BY
	|	TableOfCheckedProducts.Products,
	|	TableOfCheckedProducts.Characteristic,
	|	TableOfCheckedProducts.DocumentInflow,
	|	TableOfCheckedProducts.Purpose,
	|	TableOfCheckedProducts.Package,
	|	TableOfCheckedProducts.VATRate,
	|	TableOfCheckedProducts.Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic, 
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ISNULL(ReceiptDocumentData_.Products, ReturnDocumentData.Products) AS Products,
	|	ISNULL(ReceiptDocumentData_.Characteristic, ReturnDocumentData.Characteristic) AS Characteristic,
	|	ISNULL(ReceiptDocumentData_.Purpose, ReturnDocumentData.Purpose) AS Purpose,
	|	0 AS NumberOfPackages,
	|	ISNULL(ReceiptDocumentData_.Package, ReturnDocumentData.Package) AS Package,
	|	ISNULL(ReceiptDocumentData_.Warehouse, ReturnDocumentData.Warehouse) AS Warehouse,
	|	ISNULL(ReceiptDocumentData_.DateOfReceipt, ReturnDocumentData.DateOfReceipt) AS DateOfReceipt,
	|	ISNULL(ReceiptDocumentData_.NumberOfReceipt, ReturnDocumentData.NumberOfReceipt) AS NumberOfReceipt,
	|	ISNULL(ReceiptDocumentData_.VATRate, ReturnDocumentData.VATRate) AS VATRate,
	|	ISNULL(ReceiptDocumentData_.DocumentInflow, ReturnDocumentData.DocumentInflow) AS DocumentInflow,
	|	ISNULL(ReceiptDocumentData_.DocumentInflow.Currency, ReturnDocumentData.Currency) AS CurrencyOfReceipt,
	|	ISNULL(ReceiptDocumentData_.DocumentInflow.PriceIncludesVAT, ReturnDocumentData.PriceIncludesVAT) AS PriceIncludesVAT,
	|	ISNULL(ReceiptDocumentData_.Count, 0) - ISNULL(ReturnDocumentData.Count, 0) AS Count,
	|	ISNULL(ReceiptDocumentData_.Sum, 0) - ISNULL(ReturnDocumentData.Sum, 0) AS Sum,
	|	ISNULL(ReceiptDocumentData_.VATAmount, 0) - ISNULL(ReturnDocumentData.VATAmount, 0) AS VATAmount,
	|	ISNULL(ReceiptDocumentData_.AmountIncludingVAT, 0) - ISNULL(ReturnDocumentData.AmountIncludingVAT, 0) AS AmountIncludingVAT,
	|	ISNULL(ReceiptDocumentData_.LineNumber, 99999) AS LineNumber
	|
	|FROM
	|	ReceiptDocumentData_ AS ReceiptDocumentData_
	|		FULL JOIN ReturnDocumentData AS ReturnDocumentData
	|		ON ReceiptDocumentData_.Products = ReturnDocumentData.Products
	|			AND ReceiptDocumentData_.Characteristic = ReturnDocumentData.Characteristic
	|			AND ReceiptDocumentData_.Purpose = ReturnDocumentData.Purpose
	|			AND ReceiptDocumentData_.Package = ReturnDocumentData.Package
	|			AND ReceiptDocumentData_.DocumentInflow = ReturnDocumentData.DocumentInflow
	|WHERE
	|	CASE 
	|		WHEN NOT ReceiptDocumentData_.ToReturnReusablePackage THEN
	|			ReceiptDocumentData_.Products.ItemsType IN
	|				(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|		ELSE ReceiptDocumentData_.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods))
	|	END
	|
	|ORDER BY
	|	DateOfReceipt DESC,
	|	LineNumber,
	|	Products, 
	|	Characteristic,
	|	Package";
	
	Return QueryText;
	
EndFunction

&AtServerNoContext
Function QueryTextPurchaseByImport()
	
	Return "SELECT
	|	GoodsForRegistrationOfImportDocumentsBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsForRegistrationOfImportDocumentsBalance.DocumentInflow AS DocumentInflow,
	|	GoodsForRegistrationOfImportDocumentsBalance.CountBalance AS CountBalance,
	|	GoodsForRegistrationOfImportDocumentsBalance.ItemsLocationAttributes AS ItemsLocationAttributes
	|INTO TTBalance
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(
	|			&Date,
	|			Organization = &Organization
	|				AND Vendor = &Partner
	|				AND ImportDocumentType = &ImportDocumentType
	|				AND CASE
	|					WHEN &FilterByWarehouse
	|						THEN ItemsLocationAttributes.StorageLocation = &Warehouse
	|							OR ItemsLocationAttributes.StorageType <> VALUE(Enum.StorageLocationTypes.Warehouse)
	|					ELSE TRUE
	|				END) AS GoodsForRegistrationOfImportDocumentsBalance
	|
	|
	|INDEX BY
	|	DocumentInflow,
	|	InventoryOwnerAttribute,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorInvoice.Ref AS DocumentInflow,
	|	VendorInvoice.Date AS Date,
	|	VendorInvoice.Number AS Number,
	|	VendorInvoice.Currency AS Currency,
	|	PurchaseOfGoodsServicesGoods.Warehouse AS Warehouse,
	|	VendorInvoice.PriceIncludesVAT AS PriceIncludesVAT,
	|	VendorInvoice.PurchaseForActivity AS PurchaseForActivity,
	|	VendorInvoice.BusinessOperation AS BusinessOperation,
	|	PurchaseOfGoodsServicesGoods.Products AS Products,
	|	PurchaseOfGoodsServicesGoods.Purpose AS Purpose,
	|	PurchaseOfGoodsServicesGoods.PartnerProducts AS PartnerProducts,
	|	PurchaseOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	PurchaseOfGoodsServicesGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	PurchaseOfGoodsServicesGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	SUM(PurchaseOfGoodsServicesGoods.Count) AS NumberOfReceipts_1,
	|	PurchaseOfGoodsServicesGoods.VATRate AS VATRate,
	|	SUM(PurchaseOfGoodsServicesGoods.Sum) AS Sum,
	|	SUM(PurchaseOfGoodsServicesGoods.VATAmount) AS VATAmount,
	|	SUM(PurchaseOfGoodsServicesGoods.AmountIncludingVAT) AS AmountIncludingVAT
	|INTO TTReceipts
	|FROM
	|	TTBalance AS TTBalance
	|		LEFT JOIN Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|			INNER JOIN Document.VendorInvoice AS VendorInvoice
	|			ON PurchaseOfGoodsServicesGoods.Ref = VendorInvoice.Ref
	|		ON TTBalance.DocumentInflow = PurchaseOfGoodsServicesGoods.Ref
	|			AND TTBalance.ItemsLocationAttributes = PurchaseOfGoodsServicesGoods.ItemsLocationAttributes
	|WHERE
	|	TTBalance.DocumentInflow <> VALUE(Document.VendorInvoice.EmptyRef)
	|	AND (VendorInvoice.BusinessOperation NOT IN (&EconomicOperationsOfSeparatePurchase)
	|		OR NOT TTBalance.ItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses)
	|
	|GROUP BY
	|	VendorInvoice.Ref,
	|	VendorInvoice.Date,
	|	VendorInvoice.Number,
	|	PurchaseOfGoodsServicesGoods.Warehouse,
	|	VendorInvoice.Currency,
	|	VendorInvoice.PriceIncludesVAT,
	|	VendorInvoice.BusinessOperation,
	|	VendorInvoice.PurchaseForActivity,
	|	PurchaseOfGoodsServicesGoods.Products,
	|	PurchaseOfGoodsServicesGoods.Purpose,
	|	PurchaseOfGoodsServicesGoods.PartnerProducts,
	|	PurchaseOfGoodsServicesGoods.Characteristic,
	|	PurchaseOfGoodsServicesGoods.InventoryOwnerAttribute,
	|	PurchaseOfGoodsServicesGoods.ItemsLocationAttributes,
	|	PurchaseOfGoodsServicesGoods.VATRate
	|
	|UNION ALL
	|
	|SELECT
	|	VendorInvoice.Ref AS DocumentInflow,
	|	VendorInvoice.Date AS Date,
	|	VendorInvoice.Number AS Number,
	|	VendorInvoice.Currency AS Currency,
	|	VendorInvoice.Warehouse AS Warehouse,
	|	VendorInvoice.PriceIncludesVAT AS PriceIncludesVAT,
	|	VendorInvoice.PurchaseForActivity AS PurchaseForActivity,
	|	VendorInvoice.BusinessOperation AS BusinessOperation,
	|	PurchaseOfGoodsServicesGoods.ItemsLocationAttributes.Products AS Products,
	|	PurchaseOfGoodsServicesGoods.ItemsLocationAttributes.Purpose AS Purpose,
	|	VALUE(Catalog.Products.EmptyRef) AS PartnerProducts,
	|	PurchaseOfGoodsServicesGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	PurchaseOfGoodsServicesGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	PurchaseOfGoodsServicesGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	SUM(PurchaseOfGoodsServicesGoods.Count) AS NumberOfReceipts_1,
	|	PurchaseOfGoodsServicesGoods.VATRate AS VATRate,
	|	SUM(PurchaseOfGoodsServicesGoods.Price * PurchaseOfGoodsServicesGoods.Count) AS Sum,
	|	SUM(PurchaseOfGoodsServicesGoods.VATAmount) AS VATAmount,
	|	SUM(PurchaseOfGoodsServicesGoods.AmountIncludingVAT) AS AmountIncludingVAT
	|FROM
	|	TTBalance AS TTBalance
	|		LEFT JOIN Document.VendorInvoice.InventoryKinds AS PurchaseOfGoodsServicesGoods
	|			INNER JOIN Document.VendorInvoice AS VendorInvoice
	|			ON PurchaseOfGoodsServicesGoods.Ref = VendorInvoice.Ref
	|		ON TTBalance.DocumentInflow = PurchaseOfGoodsServicesGoods.Ref
	|			AND TTBalance.InventoryOwnerAttribute = PurchaseOfGoodsServicesGoods.InventoryOwnerAttribute
	|			AND TTBalance.ItemsLocationAttributes = PurchaseOfGoodsServicesGoods.ItemsLocationAttributes
	|WHERE
	|	VendorInvoice.BusinessOperation IN (&EconomicOperationsOfSeparatePurchase)
	|	AND TTBalance.DocumentInflow <> VALUE(Document.VendorInvoice.EmptyRef)
	|	AND TTBalance.ItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses
	|
	|GROUP BY
	|	VendorInvoice.Ref,
	|	VendorInvoice.Date,
	|	VendorInvoice.Number,
	|	VendorInvoice.Warehouse,
	|	VendorInvoice.Currency,
	|	VendorInvoice.PriceIncludesVAT,
	|	VendorInvoice.BusinessOperation,
	|	VendorInvoice.PurchaseForActivity,
	|	PurchaseOfGoodsServicesGoods.InventoryOwnerAttribute,
	|	PurchaseOfGoodsServicesGoods.ItemsLocationAttributes,
	|	PurchaseOfGoodsServicesGoods.VATRate
	|
	|INDEX BY
	|	DocumentInflow,
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTReceipts.DocumentInflow, VALUE(Document.VendorInvoice.EmptyRef)) AS DocumentInflow,
	|	TTReceipts.Currency AS CurrencyOfReceipt,
	|	ISNULL(TTReceipts.Warehouse, TTBalance.ItemsLocationAttributes.StorageLocation) AS Warehouse,
	|	TTReceipts.Date AS DateOfReceipt,
	|	TTReceipts.Number AS NumberOfReceipt,
	|	TTReceipts.PriceIncludesVAT AS PriceIncludesVAT,
	|	TTReceipts.PurchaseForActivity AS PurchaseForActivity,
	|	TTReceipts.BusinessOperation AS BusinessOperation,
	|	ISNULL(TTReceipts.Products, TTBalance.ItemsLocationAttributes.Products) AS Products,
	|	ISNULL(TTReceipts.Purpose, TTBalance.ItemsLocationAttributes.Purpose) AS Purpose,
	|	TTReceipts.PartnerProducts AS PartnerProducts,
	|	ISNULL(TTReceipts.Characteristic, TTBalance.ItemsLocationAttributes.Characteristic) AS Characteristic,
	|	CASE
	|		WHEN TTBalance.CountBalance >= ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|			THEN ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|		ELSE TTBalance.CountBalance
	|	END AS Count,
	|	CASE
	|		WHEN TTBalance.CountBalance >= ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|			THEN ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|		ELSE TTBalance.CountBalance
	|	END AS NumberOfPackages,
	|	TTBalance.ItemsLocationAttributes.Series AS Series,
	|	UNDEFINED AS Package,
	|	0 AS Price,
	|	0 AS PercentRateOfManualDiscount,
	|	0 AS ManualDiscount,
	|	TTReceipts.VATRate AS VATRate,
	|	ISNULL(TTReceipts.Sum, 0) / ISNULL(TTReceipts.NumberOfReceipts_1, 1) * CASE
	|		WHEN TTBalance.CountBalance >= ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|			THEN ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|		ELSE TTBalance.CountBalance
	|	END AS Sum,
	|	ISNULL(TTReceipts.VATAmount, 0) / ISNULL(TTReceipts.NumberOfReceipts_1, 1) * CASE
	|		WHEN TTBalance.CountBalance >= ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|			THEN ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|		ELSE TTBalance.CountBalance
	|	END AS VATAmount,
	|	ISNULL(TTReceipts.AmountIncludingVAT, 0) / ISNULL(TTReceipts.NumberOfReceipts_1, 1) * CASE
	|		WHEN TTBalance.CountBalance >= ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|			THEN ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|		ELSE TTBalance.CountBalance
	|	END AS AmountIncludingVAT,
	|	TTBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTBalance.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	TTBalance AS TTBalance
	|		LEFT JOIN TTReceipts AS TTReceipts
	|		ON (TTReceipts.DocumentInflow = TTBalance.DocumentInflow)
	|			AND (TTReceipts.ItemsLocationAttributes = TTBalance.ItemsLocationAttributes)
	|			AND (TTBalance.InventoryOwnerAttribute = TTReceipts.InventoryOwnerAttribute
	|				OR NOT TTBalance.ItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses)
	|
	|WHERE
	|	(TTReceipts.Date >= &DateOfReceipt OR &DateOfReceipt IS NULL OR TTReceipts.Date IS NULL)
	|	AND (NOT &FilterByWarehouse
	|	OR ISNULL(TTReceipts.Warehouse, TTBalance.ItemsLocationAttributes.StorageLocation) = &Warehouse)
	|	
	|
	|ORDER BY
	|	ISNULL(TTReceipts.DocumentInflow, VALUE(Document.VendorInvoice.EmptyRef))";
	
EndFunction

#EndRegion

#EndRegion
