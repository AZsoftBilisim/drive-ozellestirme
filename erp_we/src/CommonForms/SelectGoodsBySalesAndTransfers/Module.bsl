
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	UseCustomerContracts = GetFunctionalOption("UseCustomerContracts");
	UseLinesOfBusiness = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	
	Items.TableOfGoodsOpenGoodsProfile.Visible = TMCommonUseClientServer.AnExternalUserIsAuthorized();
	
	DocumentReturnPolicy = Parameters.DocumentReturnPolicy;
	Currency = Parameters.Currency;
	Date = Parameters.Date;
	PriceIncludesVAT = Parameters.PriceIncludesVAT;
	Partner = Parameters.Partner;
	Terms = Parameters.Terms;
	Contract = Parameters.Contract;
	Warehouse = Parameters.Warehouse;
	Organization = Parameters.Organization;
	Counterparty = Parameters.Counterparty;
	VATTaxation = Parameters.VATTaxation;
	ReturnFromRetailCustomer = Parameters.ReturnFromRetailCustomer;
	ReturnBetweenCompanies = Parameters.ReturnBetweenCompanies;
	CashRegisterReceipt = Parameters.CashRegisterReceipt;
	LineOfBusiness = Parameters.LineOfBusiness;
	DepositForPackageIsRequired = Parameters.DepositForPackageIsRequired;
	BusinessOperation = Parameters.BusinessOperation;
	CustomerCounterparty = Parameters.CustomerCounterparty;
	CustomerPartner = Parameters.CustomerPartner;
	CustomerContract = Parameters.CustomerContract;
	
	If ReturnBetweenCompanies Then
		Title = NStr("vi = 'Lựa chọn hàng hóa theo chứng từ chuyển nhượng trong';
					|ru = 'Подбор товаров по документам передачи в';
					|en = 'Pick goods against transfer documents in'; fa = 'Pick goods against transfer documents in';
					|it = 'Selezione merce per documenti di trasferimento in';
					|pl = 'Dobór towarów według dokumentów przekazania do';
					|tr = 'Transfer belgelerine göre ürünlerin seçimi'");
	Else
		Title = NStr("vi = 'Lựa chọn hàng hóa theo chứng từ bán hàng trong';
					|ru = 'Подбор товаров по документам продажи в';
					|en = 'Pick goods against sales documents in'; fa = 'Pick goods against sales documents in';
					|it = 'Selezione merce per documenti di vendita in';
					|pl = 'Dobór towarów według dokumentów sprzedaży do';
					|tr = 'Satış belgelerine göre ürünlerin seçimi'");
	EndIf;
	
	If ValueIsFilled(DocumentReturnPolicy) Then
		TextDocument_ = DocumentReturnPolicy;
	Else
		TextDocument_ = NStr("vi = '%1 (mới)';
							|ru = '%1 (новый)';
							|en = '%1 (new)'; fa = '%1 (new)';
							|it = '%1 (nuovo)';
							|pl = '%1 (nowy)';
							|tr = '%1 (yeni)'");
		TextDocument_ = StringFunctionsClientServer.SubstituteParametersToString(TextDocument_,
																				DocumentReturnPolicy.Metadata().Synonym);
	EndIf;
	
	Title = Title + Chars.NBSp + TextDocument_;
	
	Period = Common.CommonSettingsStorageLoad("SelectGoodsBySalesAndTransfers",
																"ProductSelectionPeriodBySales");
	
	FillInTheGoodsTable();
	CalculateTotalsOnGoodsTable();
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(
		GoodsHelpText,
		GoodsSelectedQuantity,
		GoodsSelectedAmount,
		Currency);
	
	UseReusablePackage = GetFunctionalOption("UseReusablePackage");
	ThereIsRightToTara = AccessRight("Read", Metadata.AccumulationRegisters.TransferredReturnablePackaging);
	If UseReusablePackage And Parameters.ShowContainers And ThereIsRightToTara Then
		
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
	ItemArray.Add("PackagingInformationLabel");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
																	ItemArray,
																	"Visible",
																	UseReusablePackage
																		And Parameters.ShowContainers);
	
	ItemArray = New Array();
	ItemArray.Add("PeriodOption");
	ItemArray.Add("PeriodStartDate_");
	ItemArray.Add("PeriodEndDate_2");
	ItemArray.Add("Refresh");
	ItemArray.Add("TableOfGoods");
	ItemArray.Add("GoodsHelpText");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible",
		Parameters.ShowProducts_);
		
	ItemArray = New Array();
	ItemArray.Add("TableOfGoodsWarehouse");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
																	ItemArray,
																	"Visible",
																	?(Parameters.NotShowWarehouse = True, False, True));
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "TableOfGoodsCCDNumber");
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForcefullyCloseTheForm 
		Or Exit Then
		Return;
	EndIf;
	
	Cancel = True;
	If Not MoveToDocument And GoodsSelectedQuantity > 0 Then
		
		ShowQueryBox(
			New CallbackDescription("QuestionSelectedGoodsAreNotTransferredToDocument", ThisObject),
			NStr("vi = 'Hàng hóa đã chọn chưa được chuyển vào chứng từ. Chuyển?';
				|ru = 'Подобранные товары не перенесены в документ. Перенести?';
				|en = 'Picked items are not added to the document. Do you want to add them?'; fa = 'Picked items are not added to the document. Do you want to add them?';
				|it = 'La merce selezionata non è stata trasferita nel documento. Trasferire?';
				|pl = 'Wybrane wiersze pozycji nie zostały przeniesione do dokumentu. Przenieść?';
				|tr = 'Seçili ürünler belgeye aktarılmadı. Aktarılsın mı?'"),
			QuestionDialogMode.YesNoCancel);
		
	Else
		
		BeforeClosingFragment();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionSelectedGoodsAreNotTransferredToDocument(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		
		MoveToDocument = True;
		BeforeClosingFragment();
		
	ElsIf UserAnswer = DialogReturnCode.No Then
		
		ForcefullyCloseTheForm = True;
		MoveToDocument = False;
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingFragment()
	
	TransferReceipt = CheckWhetherCashRegisterReceiptCanBeTransferred();
	If MoveToDocument And Not TransferReceipt Then
		
		AnswersOptions = New ValueList;
		AnswersOptions.Add(DialogReturnCode.Yes, NStr("vi = 'Chuyển mà không có phiếu tính tiền';
														|ru = 'Перенести без чека ККМ';
														|en = 'Move without receipt'; fa = 'Move without receipt';
														|it = 'Trasferire senza scontrino KKM (Macchinari di Registrazione e Controllo)';
														|pl = 'Przenieś bez paragonu kasowego';
														|tr = 'Yazar Kasa fişi olmadan transfer et'"));
		AnswersOptions.Add(DialogReturnCode.No, NStr("vi = 'Trả lại';
													|ru = 'Вернуться';
													|en = 'Return'; fa = 'مرجوعی';
													|it = 'Ritornare';
													|pl = 'Return';
													|tr = 'Geri dön'"));
		
		ShowQueryBox(
			New CallbackDescription("BeforeClosingFragmentQuestionCompletion", ThisObject),
			NStr("vi = 'Đã chọn hàng hóa từ các phiếu tính tiền khác nhau. Chưa điền phiếu tính tiền. Chuyển hàng hóa mà không có phiếu tính tiền?';
				|ru = 'Выбраны товары из разных чеков ККМ. Чек ККМ не будет заполнен. Перенести товары без чека ККМ?';
				|en = 'You have selected goods from different receipts. The receipt will not be filled in. Transfer goods without a receipt?'; fa = 'You have selected goods from different receipts. The receipt will not be filled in. Transfer goods without a receipt?';
				|it = 'Selezionate merci da diversi scontrini KKM. Lo scontrino KKM non sarà compilato. Trasferire merci senza scontrino KKM?';
				|pl = 'Wybrano wiersze pozycji z różnych paragonów kasowych. Paragon kasowy nie zostanie wypełniony. Przenieść wiersze pozycji bez paragonu kasowego?';
				|tr = 'Farklı Yazar Kasa fişlerinden seçilen ürünler. Yazar Kasa fişi doldurulmayacaktır. Yazar Kasa fişi olmadan mal transferi edilsin mi?'"),
			AnswersOptions);
		
	Else
		
		ForcefullyCloseTheForm = True;
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingFragmentQuestionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		MoveToDocument = False;
	Else
		ForcefullyCloseTheForm = True;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	If MoveToDocument Then
		
		GoodsAddressInStorage = PutProductsInStorage();
		Structure = New Structure("GoodsAddressInStorage", GoodsAddressInStorage);
		NotifyChoice(Structure);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Common.CommonSettingsStorageSave("SelectGoodsBySalesAndTransfers",
		"ProductSelectionPeriodBySales", Period);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtServer
Procedure TableOfProductsSelectedWhenChangingOnServer()
	
	CurrentData = TableOfGoods.FindByID(Items.TableOfGoods.CurrentRow);
	
	AdditionSign = ?(CurrentData.Selected, 1, -1);
	GoodsSelectedQuantity = GoodsSelectedQuantity + AdditionSign;
	GoodsSelectedAmount = GoodsSelectedAmount + CurrentData.AmountIncludingVAT*AdditionSign;
	
	ProductsInSet         = CurrentData.ProductsInSet;
	ItemVariantOfSet       = CurrentData.ItemVariantOfSet;
	SetPricingOption   = CurrentData.SetPricingOption;
	SaleTransferDocument = CurrentData.SaleTransferDocument;
	
	If ValueIsFilled(ProductsInSet) And (SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
		Or SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices) Then
		
		GoodsSelectedAmount = 0;
		GoodsSelectedQuantity = 0;
		
		For Each TSRow In TableOfGoods Do
			
			If  TSRow.ProductsInSet = ProductsInSet
				And TSRow.ItemVariantOfSet = ItemVariantOfSet
				And TSRow.SaleTransferDocument = SaleTransferDocument Then
				TSRow.Selected = CurrentData.Selected;
			EndIf;
			
			If TSRow.Selected Then
				GoodsSelectedAmount = GoodsSelectedAmount + TSRow.AmountIncludingVAT;
				GoodsSelectedQuantity = GoodsSelectedQuantity + TSRow.NumberOfPackages;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(GoodsHelpText, GoodsSelectedQuantity, GoodsSelectedAmount, Currency);
	
EndProcedure

&AtClient
Procedure TableOfGoodsSelectedOnChange(Item)
	
	TableOfProductsSelectedWhenChangingOnServer();
	
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

&AtClient
Procedure TableOfGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized()
		And Field.Name = "TableOfGoodsProducts"
		Or Field.Name = "TableOfGoodsCharacteristic"
		Or Field.Name = "TableOfGoodsSeries" Then
		
		OpenProductItemCard();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()
	
	MoveToDocument = True;
	ForcefullyCloseTheForm = True;
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure ToChooseTheProducts()
	
	SelectAllProductsOnServer();
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(GoodsHelpText, GoodsSelectedQuantity, GoodsSelectedAmount, Currency);
	
EndProcedure

&AtClient
Procedure ExcludeGoods()
	
	ExcludeAllProductsOnServer();
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(GoodsHelpText, GoodsSelectedQuantity, GoodsSelectedAmount, Currency);
	
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
	
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(GoodsHelpText, GoodsSelectedQuantity, GoodsSelectedAmount, Currency);
	
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
	
	SelectGoodsClientServer.CreateInformationLabelForSelectedProducts(GoodsHelpText, GoodsSelectedQuantity, GoodsSelectedAmount, Currency);
	
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
			PackageSelectedAmount = PackageSelectedAmount - String.Sum;
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
	ItemFilter.LeftValue = New DataCompositionField("ManualDiscount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsDiscountMarkupAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsPercentRateOfAutomaticDiscountMarkup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DiscountMarkupAmount");
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
	HeaderStructure_ = New Structure("CashRegisterReceipt,Partner",
										Documents.CashRegisterReceipt.EmptyRef(),
										Partner);
	
	If ReturnFromRetailCustomer Then
		
		TableOfBases_ = TableOfGoods.Unload(New Structure("Selected", True));
		TableOfBases_.GroupBy("SaleTransferDocument,Partner");
		
		If TableOfBases_.Count() = 1 Then
			TableRow = TableOfBases_.Get(0);
			HeaderStructure_.CashRegisterReceipt = TableRow.SaleTransferDocument;
			HeaderStructure_.Partner = TableRow.Partner;
		EndIf;
		
	Else
		
		For Each CurRow In PackageTable Do
			If CurRow.Selected Then
				NewRow = Goods.Add();
				FillPropertyValues(NewRow, CurRow);
				NewRow.NumberOfPackages = CurRow.Count;
				NewRow.AmountIncludingVAT = CurRow.Sum;
				NewRow.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
			EndIf;
		EndDo;
	
	EndIf; 
	
	GoodsAddressInStorage = PutToTempStorage(New Structure("Goods,HeaderStructure_", Goods, HeaderStructure_), UUID);
	
	Return GoodsAddressInStorage;
	
EndFunction

&AtServer
Procedure FillInTheGoodsTable()
	
	TableOfGoods.Clear();
	
	Query = New Query;
	If Not ReturnFromRetailCustomer
		And Not ReturnBetweenCompanies Then
		Query.Text =
		"SELECT ALLOWED
		|	CustomerInvoice.Ref AS Ref
		|INTO SaleDocuments
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|	LEFT JOIN
		|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
		|	ON
		|		CustomerInvoice.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
		|		AND RegisterOfDocumentsStornoCorrection.Posted
		|		AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
		|WHERE
		|	CustomerInvoice.Date BETWEEN &StartDate AND &EndDate
		|	AND CustomerInvoice.Posted
		|	AND CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|	AND CustomerInvoice.Counterparty = &Counterparty
		|	AND CustomerInvoice.CustomerCounterparty = &CustomerCounterparty
		|	AND CustomerInvoice.Organization = &Organization
		|	AND CASE
		|			WHEN NOT &ToUseTermsOfSales
		|				THEN TRUE
		|			ELSE CustomerInvoice.Terms = &Terms
		|		END
		|	AND CASE
		|			WHEN NOT &UseVATTaxation 
		|				THEN TRUE
		|			ELSE CustomerInvoice.VATTaxation = &VATTaxation
		|		END
		|	AND CustomerInvoice.Partner = &Partner
		|	AND CustomerInvoice.CustomerPartner = &CustomerPartner
		|	AND CASE
		|			WHEN NOT &UseCustomerContracts
		|				THEN TRUE
		|			ELSE CustomerInvoice.Contract = &Contract
		|		END
		|	AND CASE
		|			WHEN NOT &UseLinesOfBusiness
		|				THEN TRUE
		|			ELSE CustomerInvoice.LineOfBusiness = &LineOfBusiness
		|		END
		|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	MAX(SaleAdjustment.Date) AS Date,
		|	SaleDocuments.Ref AS ImplementationReference
		|INTO AdjustmentData
		|FROM
		|	SaleDocuments AS SaleDocuments
		|		LEFT JOIN Document.SaleAdjustment AS SaleAdjustment
		|		ON (SaleAdjustment.DocumentBasis = SaleDocuments.Ref)
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
		|		ON SaleAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
		|			AND RegisterOfDocumentsStornoCorrection.Posted
		|			AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
		|WHERE
		|	SaleAdjustment.Posted
		|	AND NOT SaleAdjustment.AdjustmentKind IN (VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods), VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
		|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
		|
		|GROUP BY
		|	SaleDocuments.Ref
		|
		|INDEX BY
		|	ImplementationReference
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	MAX(SaleAdjustment.Ref) AS Ref,
		|	MAX(SaleAdjustment.Ref.Date) AS Date,
		|	SaleAdjustment.Ref.DocumentBasis AS ImplementationReference
		|INTO LastAdjustmentData
		|FROM
		|	Document.SaleAdjustment AS SaleAdjustment
		|WHERE
		|	(SaleAdjustment.Ref.DocumentBasis, SaleAdjustment.Ref.Date) IN
		|			(SELECT
		|				AdjustmentData.ImplementationReference AS ImplementationReference,
		|				AdjustmentData.Date AS Date
		|			FROM
		|				AdjustmentData)
		|
		|GROUP BY
		|	SaleAdjustment.Ref.DocumentBasis
		|
		|INDEX BY
		|	Ref,
		|	ImplementationReference
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CASE
		|		WHEN LastAdjustmentData.Ref IS NULL
		|			THEN SaleDocuments.Ref
		|		ELSE LastAdjustmentData.Ref
		|	END AS Ref
		|INTO ReferencesToImplementations
		|FROM
		|	SaleDocuments AS SaleDocuments
		|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
		|		ON SaleDocuments.Ref = LastAdjustmentData.ImplementationReference
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	SaleAdjustmentGoods.ProductsInSet AS ProductsInSet,
		|	SaleAdjustmentGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|	SaleAdjustmentGoods.Products AS Products,
		|	SaleAdjustmentGoods.Characteristic AS Characteristic,
		|	SaleAdjustmentGoods.Series AS Series,
		|	SaleAdjustmentGoods.Purpose AS Purpose,
		|	SUM(SaleAdjustmentGoods.NumberOfPackages) AS NumberOfPackages,
		|	SUM(SaleAdjustmentGoods.Count) AS Count,
		|	SaleAdjustmentGoods.Price AS Price,
		|	SaleAdjustmentGoods.Ref.DocumentBasis AS SaleTransferDocument,
		|	SaleAdjustmentGoods.Package AS Package,
		|	SaleAdjustmentGoods.PriceKind AS PriceKind,
		|	SUM(SaleAdjustmentGoods.Sum) AS Sum,
		|	SaleAdjustmentGoods.VATRate AS VATRate,
		|	SUM(SaleAdjustmentGoods.VATAmount) AS VATAmount,
		|	SUM(SaleAdjustmentGoods.AmountIncludingVAT) AS AmountIncludingVAT,
		|	SaleAdjustmentGoods.Warehouse AS Warehouse,
		|	NULL AS ManualDiscount,
		|	NULL AS DiscountMarkupAmount,
		|	NULL AS PercentRateOfManualDiscount,
		|	NULL AS PercentRateOfAutomaticDiscountMarkup,
		|	SaleAdjustmentGoods.Ref.PriceIncludesVAT AS PriceIncludesVAT,
		|	SaleAdjustmentGoods.Ref.Currency AS Currency,
		|	SaleAdjustmentGoods.Ref.DocumentBasis.Date AS SaleTransferDate,
		|	SaleAdjustmentGoods.Ref.DocumentBasis.Number AS SaleTransferNumber,
		|	SaleAdjustmentGoods.Ref.DocumentBasis.ToReturnReusablePackage AS ToReturnReusablePackage
		|INTO DataFromImplementationDocuments
		|FROM
		|	ReferencesToImplementations AS ReferencesToImplementations
		|		INNER JOIN Document.SaleAdjustment.Goods AS SaleAdjustmentGoods
		|		ON (SaleAdjustmentGoods.Ref = ReferencesToImplementations.Ref)
		|
		|GROUP BY
		|	SaleAdjustmentGoods.ProductsInSet,
		|	SaleAdjustmentGoods.ItemVariantOfSet,
		|	SaleAdjustmentGoods.Products,
		|	SaleAdjustmentGoods.Characteristic,
		|	SaleAdjustmentGoods.Series,
		|	SaleAdjustmentGoods.Price,
		|	SaleAdjustmentGoods.Ref.DocumentBasis,
		|	SaleAdjustmentGoods.Package,
		|	SaleAdjustmentGoods.PriceKind,
		|	SaleAdjustmentGoods.VATRate,
		|	SaleAdjustmentGoods.Warehouse,
		|	SaleAdjustmentGoods.Ref.PriceIncludesVAT,
		|	SaleAdjustmentGoods.Ref.Currency,
		|	SaleAdjustmentGoods.Ref.DocumentBasis.Date,
		|	SaleAdjustmentGoods.Ref.DocumentBasis.Number,
		|	SaleAdjustmentGoods.Package,
		|	SaleAdjustmentGoods.Ref.DocumentBasis.ToReturnReusablePackage,
		|	SaleAdjustmentGoods.Purpose
		|
		|UNION ALL
		|
		|SELECT
		|	SalesOfGoodsServicesGoods.ProductsInSet,
		|	SalesOfGoodsServicesGoods.ItemVariantOfSet,
		|	SalesOfGoodsServicesGoods.Products,
		|	SalesOfGoodsServicesGoods.Characteristic,
		|	SalesOfGoodsServicesGoods.Series,
		|	SalesOfGoodsServicesGoods.Purpose,
		|	SUM(SalesOfGoodsServicesGoods.NumberOfPackages),
		|	SUM(SalesOfGoodsServicesGoods.Count),
		|	SalesOfGoodsServicesGoods.Price,
		|	SalesOfGoodsServicesGoods.Ref,
		|	SalesOfGoodsServicesGoods.Package,
		|	SalesOfGoodsServicesGoods.PriceKind,
		|	SUM(SalesOfGoodsServicesGoods.Sum),
		|	SalesOfGoodsServicesGoods.VATRate,
		|	SUM(SalesOfGoodsServicesGoods.VATAmount),
		|	SUM(SalesOfGoodsServicesGoods.AmountIncludingVAT),
		|	SalesOfGoodsServicesGoods.Warehouse,
		|	SalesOfGoodsServicesGoods.ManualDiscount,
		|	SalesOfGoodsServicesGoods.DiscountMarkupAmount,
		|	SalesOfGoodsServicesGoods.PercentRateOfManualDiscount,
		|	SalesOfGoodsServicesGoods.PercentRateOfAutomaticDiscountMarkup,
		|	SalesOfGoodsServicesGoods.Ref.PriceIncludesVAT,
		|	SalesOfGoodsServicesGoods.Ref.Currency,
		|	SalesOfGoodsServicesGoods.Ref.Date,
		|	SalesOfGoodsServicesGoods.Ref.Number,
		|	SalesOfGoodsServicesGoods.Ref.ToReturnReusablePackage
		|FROM
		|	ReferencesToImplementations AS ReferencesToImplementations
		|		INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
		|		ON (SalesOfGoodsServicesGoods.Ref = ReferencesToImplementations.Ref)
		|
		|GROUP BY
		|	SalesOfGoodsServicesGoods.ProductsInSet,
		|	SalesOfGoodsServicesGoods.ItemVariantOfSet,
		|	SalesOfGoodsServicesGoods.Products,
		|	SalesOfGoodsServicesGoods.Characteristic,
		|	SalesOfGoodsServicesGoods.Series,
		|	SalesOfGoodsServicesGoods.Price,
		|	SalesOfGoodsServicesGoods.Ref,
		|	SalesOfGoodsServicesGoods.Package,
		|	SalesOfGoodsServicesGoods.PriceKind,
		|	SalesOfGoodsServicesGoods.VATRate,
		|	SalesOfGoodsServicesGoods.ManualDiscount,
		|	SalesOfGoodsServicesGoods.DiscountMarkupAmount,
		|	SalesOfGoodsServicesGoods.PercentRateOfManualDiscount,
		|	SalesOfGoodsServicesGoods.PercentRateOfAutomaticDiscountMarkup,
		|	SalesOfGoodsServicesGoods.Warehouse,
		|	SalesOfGoodsServicesGoods.Ref.PriceIncludesVAT,
		|	SalesOfGoodsServicesGoods.Ref.Currency,
		|	SalesOfGoodsServicesGoods.Ref.Date,
		|	SalesOfGoodsServicesGoods.Ref.Number,
		|	SalesOfGoodsServicesGoods.Purpose,
		|	SalesOfGoodsServicesGoods.Package,
		|	SalesOfGoodsServicesGoods.Ref.ToReturnReusablePackage
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	TableOfCheckedProducts.ProductsInSet AS ProductsInSet,
		|	TableOfCheckedProducts.ItemVariantOfSet AS ItemVariantOfSet,
		|	TableOfCheckedProducts.Products AS Products,
		|	TableOfCheckedProducts.Characteristic AS Characteristic,
		|	TableOfCheckedProducts.Series AS Series,
		|	TableOfCheckedProducts.Purpose AS Purpose,
		|	TableOfCheckedProducts.Package AS Package,
		|	TableOfCheckedProducts.VATRate AS VATRate,
		|	TableOfCheckedProducts.Warehouse AS Warehouse,
		|	SUM(TableOfCheckedProducts.NumberOfPackages) AS NumberOfPackages,
		|	SUM(TableOfCheckedProducts.Count) AS Count,
		|	TableOfCheckedProducts.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|	SUM(TableOfCheckedProducts.Sum) AS Sum,
		|	SUM(TableOfCheckedProducts.VATAmount) AS VATAmount,
		|	SUM(TableOfCheckedProducts.AmountIncludingVAT) AS AmountIncludingVAT
		|INTO ReturnDocumentData
		|FROM
		|	SaleDocuments AS SaleDocuments
		|		LEFT JOIN Document.ReturnOfGoodsFromCustomer.Goods AS TableOfCheckedProducts
		|		ON (TableOfCheckedProducts.DocumentSalesOfGoodsAndServices = SaleDocuments.Ref)
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
		|		ON TableOfCheckedProducts.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
		|			AND RegisterOfDocumentsStornoCorrection.Posted
		|			AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
		|WHERE
		|	TableOfCheckedProducts.Ref.Posted
		|	AND TableOfCheckedProducts.Ref <> &DocumentReturnPolicy
		|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
		|
		|GROUP BY
		|	TableOfCheckedProducts.ProductsInSet,
		|	TableOfCheckedProducts.ItemVariantOfSet,
		|	TableOfCheckedProducts.Products,
		|	TableOfCheckedProducts.Characteristic,
		|	TableOfCheckedProducts.Series,
		|	TableOfCheckedProducts.Warehouse,
		|	TableOfCheckedProducts.Purpose,
		|	TableOfCheckedProducts.Package,
		|	TableOfCheckedProducts.VATRate,
		|	TableOfCheckedProducts.DocumentSalesOfGoodsAndServices
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Series,
		|	Purpose,
		|	DocumentSalesOfGoodsAndServices
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ISNULL(DataFromImplementationDocuments.ProductsInSet, ReturnDocumentData.ProductsInSet) AS ProductsInSet,
		|	ISNULL(DataFromImplementationDocuments.ItemVariantOfSet, ReturnDocumentData.ItemVariantOfSet) AS ItemVariantOfSet,
		|	ISNULL(DataFromImplementationDocuments.Products, ReturnDocumentData.Products) AS Products,
		|	ISNULL(DataFromImplementationDocuments.Characteristic, ReturnDocumentData.Characteristic) AS Characteristic,
		|	ISNULL(DataFromImplementationDocuments.Series, ReturnDocumentData.Series) AS Series,
		|	ISNULL(DataFromImplementationDocuments.Warehouse, ReturnDocumentData.Warehouse) AS Warehouse,
		|	ISNULL(DataFromImplementationDocuments.Purpose, ReturnDocumentData.Purpose) AS Purpose,
		|	ISNULL(DataFromImplementationDocuments.Package, ReturnDocumentData.Package) AS Package,
		|	0 AS NumberOfPackages,
		|	ISNULL(DataFromImplementationDocuments.Count, 0) - ISNULL(ReturnDocumentData.Count, 0) AS Count,
		|	ISNULL(DataFromImplementationDocuments.Sum, 0) - ISNULL(ReturnDocumentData.Sum, 0) AS Sum,
		|	ISNULL(DataFromImplementationDocuments.VATAmount, 0) - ISNULL(ReturnDocumentData.VATAmount, 0) AS VATAmount,
		|	ISNULL(DataFromImplementationDocuments.AmountIncludingVAT, 0) - ISNULL(ReturnDocumentData.AmountIncludingVAT, 0) AS AmountIncludingVAT,
		|	ISNULL(DataFromImplementationDocuments.VATRate, ReturnDocumentData.VATRate) AS VATRate,
		|	ISNULL(DataFromImplementationDocuments.SaleTransferDocument, ReturnDocumentData.DocumentSalesOfGoodsAndServices) AS SaleTransferDocument,
		|	ISNULL(DataFromImplementationDocuments.ToReturnReusablePackage, FALSE) AS ToReturnReusablePackage
		|INTO DataFromRefundImplementationDocuments
		|FROM
		|	DataFromImplementationDocuments AS DataFromImplementationDocuments
		|		FULL JOIN ReturnDocumentData AS ReturnDocumentData
		|		ON DataFromImplementationDocuments.Products = ReturnDocumentData.Products
		|			AND DataFromImplementationDocuments.Characteristic = ReturnDocumentData.Characteristic
		|			AND DataFromImplementationDocuments.ProductsInSet = ReturnDocumentData.ProductsInSet
		|			AND DataFromImplementationDocuments.ItemVariantOfSet = ReturnDocumentData.ItemVariantOfSet
		|			AND DataFromImplementationDocuments.Series = ReturnDocumentData.Series
		|			AND DataFromImplementationDocuments.Warehouse = ReturnDocumentData.Warehouse
		|			AND DataFromImplementationDocuments.Purpose = ReturnDocumentData.Purpose
		|			AND DataFromImplementationDocuments.SaleTransferDocument = ReturnDocumentData.DocumentSalesOfGoodsAndServices
		|			AND DataFromImplementationDocuments.Package = ReturnDocumentData.Package
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	DataFromRefundImplementationDocuments.Count AS Count,
		|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
		|	CASE
		|		WHEN DataFromRefundImplementationDocuments.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
		|			THEN 1
		|		ELSE 0
		|	END AS SetIndex,
		|	DataFromRefundImplementationDocuments.ProductsInSet AS ProductsInSet,
		|	DataFromRefundImplementationDocuments.ItemVariantOfSet AS ItemVariantOfSet,
		|	DataFromRefundImplementationDocuments.Products AS Products,
		|	DataFromRefundImplementationDocuments.Characteristic AS Characteristic,
		|	DataFromRefundImplementationDocuments.Series AS Series,
		|	DataFromRefundImplementationDocuments.Purpose AS Purpose,
		|	DataFromRefundImplementationDocuments.NumberOfPackages AS NumberOfPackages,
		|	DataFromRefundImplementationDocuments.Package AS Package,
		|	DataFromRefundImplementationDocuments.Sum AS Sum,
		|	DataFromRefundImplementationDocuments.VATAmount AS VATAmount,
		|	DataFromRefundImplementationDocuments.AmountIncludingVAT AS AmountIncludingVAT,
		|	DataFromRefundImplementationDocuments.Warehouse AS Warehouse,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument.Date AS SaleTransferDate,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument.Number AS SaleTransferNumber,
		|	DataFromRefundImplementationDocuments.VATRate AS VATRate,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument AS SaleTransferDocument,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument.Currency AS CurrencyOfImplementation,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument.PriceIncludesVAT AS PriceIncludesVAT
		|
		|FROM DataFromRefundImplementationDocuments AS DataFromRefundImplementationDocuments
		|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|		ON (ProductKitConfigurations.Owner = DataFromRefundImplementationDocuments.ProductsInSet)
		|			AND (ProductKitConfigurations.Characteristic = DataFromRefundImplementationDocuments.ItemVariantOfSet)
		|			AND (ProductKitConfigurations.Main)
		|WHERE
		|	CASE
		|		WHEN NOT DataFromRefundImplementationDocuments.ToReturnReusablePackage
		|			THEN DataFromRefundImplementationDocuments.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
		|		ELSE DataFromRefundImplementationDocuments.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods))
		|	END
		|	AND CASE
		|		WHEN VALUETYPE(&DocumentReturnPolicy) IN (TYPE(Document.ReturnOfGoodsFromCustomer), TYPE(Document.RequestForReturnOfGoodsFromCustomer))
		|			THEN NOT ISNULL(ProductKitConfigurations.ContainsServices, FALSE)
		|		ELSE TRUE
		|	END
		|
		|ORDER BY
		|	SaleTransferDate DESC";
		
		Query.SetParameter("Partner",                          Partner);
		Query.SetParameter("CustomerPartner",                    CustomerPartner);
		Query.SetParameter("Counterparty",                       Counterparty);
		Query.SetParameter("CustomerCounterparty",                 CustomerCounterparty);
		Query.SetParameter("Organization",                      Organization);
		Query.SetParameter("StartDate",                       Period.StartDate);
		Query.SetParameter("EndDate",                    Period.EndDate);
		Query.SetParameter("Terms",                       Terms);
		Query.SetParameter("Contract",                          Contract);
		Query.SetParameter("UseVATTaxation",   Not VATTaxation = Enums.VATTaxationTypes.EmptyRef());
		Query.SetParameter("VATTaxation",               VATTaxation);
		Query.SetParameter("DocumentReturnPolicy",                 DocumentReturnPolicy);
		Query.SetParameter("ToUseTermsOfSales", ToUseTermsOfSales);
		Query.SetParameter("UseCustomerContracts",   UseCustomerContracts);
		Query.SetParameter("UseLinesOfBusiness", UseLinesOfBusiness);
		Query.SetParameter("LineOfBusiness",          LineOfBusiness);
		
	ElsIf ReturnFromRetailCustomer Then
		Query.Text =
		"SELECT ALLOWED
		|	CashRegisterReceiptGoods.Ref AS SaleTransferDocument,
		|	CashRegisterReceiptGoods.ProductsInSet AS ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products AS Products,
		|	CashRegisterReceiptGoods.Characteristic AS Characteristic,
		|	CashRegisterReceiptGoods.Series AS Series,
		|	CashRegisterReceiptGoods.Package AS Package,
		|	SUM(CashRegisterReceiptGoods.NumberOfPackages) AS NumberOfPackages,
		|	SUM(CashRegisterReceiptGoods.Count) AS Count,
		|	CASE
		|		WHEN SUM(CashRegisterReceiptGoods.ManualDiscount) + SUM(CashRegisterReceiptGoods.DiscountMarkupAmount) = 0
		|				OR SUM(CashRegisterReceiptGoods.NumberOfPackages) = 0
		|			THEN CashRegisterReceiptGoods.Price
		|		ELSE SUM(CashRegisterReceiptGoods.Sum) / SUM(CashRegisterReceiptGoods.NumberOfPackages)
		|	END AS Price,
		|	SUM(CashRegisterReceiptGoods.Sum) AS Sum,
		|	CashRegisterReceiptGoods.VATRate AS VATRate,
		|	SUM(CashRegisterReceiptGoods.VATAmount) AS VATAmount,
		|	CashRegisterReceiptGoods.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
		|	SUM(CashRegisterReceiptGoods.DiscountMarkupAmount) AS DiscountMarkupAmount,
		|	CashRegisterReceiptGoods.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
		|	SUM(CashRegisterReceiptGoods.ManualDiscount) AS ManualDiscount,
		|	CashRegisterReceiptGoods.Ref.Date AS SaleTransferDate,
		|	CashRegisterReceiptGoods.Ref.Number AS SaleTransferNumber,
		|	CashRegisterReceiptGoods.Ref.Currency AS CurrencyOfImplementation,
		|	CashRegisterReceiptGoods.Ref.PriceIncludesVAT AS PriceIncludesVAT,
		|	CashRegisterReceiptGoods.Ref.Partner AS Partner
		|INTO CashRegisterReceipts
		|FROM
		|	Document.CashRegisterReceipt.Goods AS CashRegisterReceiptGoods
		|WHERE
		|	CashRegisterReceiptGoods.Ref.Date BETWEEN &StartDate AND &EndDate
		|	AND CashRegisterReceiptGoods.Ref.VATTaxation = &VATTaxation
		|	AND CashRegisterReceiptGoods.Ref.Posted
		|	AND CashRegisterReceiptGoods.Ref.Organization = &Organization
		|	AND CashRegisterReceiptGoods.Ref.Partner = &Partner
		|	AND (CashRegisterReceiptGoods.Ref = &CashRegisterReceipt OR &CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef))
		|
		|GROUP BY
		|	CashRegisterReceiptGoods.Ref,
		|	CashRegisterReceiptGoods.ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products,
		|	CashRegisterReceiptGoods.Characteristic,
		|	CashRegisterReceiptGoods.Series,
		|	CashRegisterReceiptGoods.Package,
		|	CashRegisterReceiptGoods.Price,
		|	CashRegisterReceiptGoods.VATRate,
		|	CashRegisterReceiptGoods.PercentRateOfAutomaticDiscountMarkup,
		|	CashRegisterReceiptGoods.PercentRateOfManualDiscount,
		|	CashRegisterReceiptGoods.Ref.Date,
		|	CashRegisterReceiptGoods.Ref.Number,
		|	CashRegisterReceiptGoods.Ref.Currency,
		|	CashRegisterReceiptGoods.Ref.PriceIncludesVAT,
		|	CashRegisterReceiptGoods.Ref.Partner
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CombinedTable.SaleTransferDocument AS SaleTransferDocument,
		|	CombinedTable.ProductsInSet AS ProductsInSet,
		|	CombinedTable.ItemVariantOfSet AS ItemVariantOfSet,
		|	CombinedTable.Products AS Products,
		|	CombinedTable.Characteristic AS Characteristic,
		|	CombinedTable.Package AS Package,
		|	CombinedTable.Series AS Series,
		|	CombinedTable.VATRate AS VATRate,
		|	SUM(CombinedTable.NumberOfPackages) AS NumberOfPackages,
		|	SUM(CombinedTable.Count) AS Count,
		|	SUM(CombinedTable.Sum) AS Sum,
		|	SUM(CombinedTable.VATAmount) AS VATAmount
		|INTO ReturnData
		|FROM
		|	(SELECT
		|		CashRegisterReceiptReturnProducts.Ref.CashRegisterReceipt AS SaleTransferDocument,
		|		CashRegisterReceiptReturnProducts.ProductsInSet AS ProductsInSet,
		|		CashRegisterReceiptReturnProducts.ItemVariantOfSet AS ItemVariantOfSet,
		|		CashRegisterReceiptReturnProducts.Products AS Products,
		|		CashRegisterReceiptReturnProducts.Characteristic AS Characteristic,
		|		CashRegisterReceiptReturnProducts.Package AS Package,
		|		CashRegisterReceiptReturnProducts.Series AS Series,
		|		CashRegisterReceiptReturnProducts.VATRate AS VATRate,
		|		CashRegisterReceiptReturnProducts.NumberOfPackages AS NumberOfPackages,
		|		CashRegisterReceiptReturnProducts.Count AS Count,
		|		CashRegisterReceiptReturnProducts.Sum AS Sum,
		|		CashRegisterReceiptReturnProducts.VATAmount AS VATAmount
		|	FROM
		|		Document.CashRegisterReceiptReturn.Goods AS CashRegisterReceiptReturnProducts
		|	WHERE
		|		CashRegisterReceiptReturnProducts.Ref.Date BETWEEN &StartDate AND &EndDate
		|		AND CashRegisterReceiptReturnProducts.Ref.VATTaxation = &VATTaxation
		|		AND CashRegisterReceiptReturnProducts.Ref.Posted
		|		AND CashRegisterReceiptReturnProducts.Ref.Organization = &Organization
		|		AND CashRegisterReceiptReturnProducts.NumberOfPackages <> 0
		|
		|	UNION ALL
		|
		|	SELECT
		|		TableOfCheckedProducts.Ref.CashRegisterReceipt,
		|		TableOfCheckedProducts.ProductsInSet,
		|		TableOfCheckedProducts.ItemVariantOfSet,
		|		TableOfCheckedProducts.Products,
		|		TableOfCheckedProducts.Characteristic,
		|		TableOfCheckedProducts.Package,
		|		TableOfCheckedProducts.Series,
		|		TableOfCheckedProducts.VATRate,
		|		TableOfCheckedProducts.NumberOfPackages AS NumberOfPackages,
		|		TableOfCheckedProducts.Count AS Count,
		|		TableOfCheckedProducts.Sum AS Sum,
		|		TableOfCheckedProducts.VATAmount AS VATAmount
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			LEFT JOIN Document.ReturnOfGoodsFromCustomer.Goods AS TableOfCheckedProducts
		|			ON CashRegisterReceipts.SaleTransferDocument = TableOfCheckedProducts.Ref.CashRegisterReceipt
		|			LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
		|			ON TableOfCheckedProducts.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
		|				AND RegisterOfDocumentsStornoCorrection.Posted
		|				AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
		|	WHERE
		|		TableOfCheckedProducts.Ref.Posted
		|		AND TableOfCheckedProducts.Ref <> &DocumentReturnPolicy
		|		AND RegisterOfDocumentsStornoCorrection.Ref IS NULL) AS CombinedTable
		|
		|
		|GROUP BY
		|	CombinedTable.SaleTransferDocument,
		|	CombinedTable.ProductsInSet,
		|	CombinedTable.ItemVariantOfSet,
		|	CombinedTable.Products,
		|	CombinedTable.Characteristic,
		|	CombinedTable.Package,
		|	CombinedTable.Series,
		|	CombinedTable.VATRate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ISNULL(CashRegisterReceipts.SaleTransferDocument, ReturnData.SaleTransferDocument) AS SaleTransferDocument,
		|	ISNULL(CashRegisterReceipts.Products, ReturnData.Products) AS Products,
		|	ISNULL(CashRegisterReceipts.Characteristic, ReturnData.Characteristic) AS Characteristic,
		|	ISNULL(CashRegisterReceipts.ProductsInSet, ReturnData.ProductsInSet) AS ProductsInSet,
		|	ISNULL(CashRegisterReceipts.ItemVariantOfSet, ReturnData.ItemVariantOfSet) AS ItemVariantOfSet,
		|	ISNULL(CashRegisterReceipts.Series, ReturnData.Series) AS Series,
		|	ISNULL(CashRegisterReceipts.Package, ReturnData.Package) AS Package,
		|	ISNULL(CashRegisterReceipts.VATRate, ReturnData.VATRate) AS VATRate,
		|	0 AS NumberOfPackages,
		|	ISNULL(CashRegisterReceipts.Count, 0) - ISNULL(ReturnData.Count, 0) AS Count,
		|	ISNULL(CashRegisterReceipts.Sum, 0) - ISNULL(ReturnData.Sum, 0) AS Sum,
		|	ISNULL(CashRegisterReceipts.VATAmount, 0) - ISNULL(ReturnData.VATAmount, 0) AS VATAmount
		|INTO DataFromRefundImplementationDocuments
		|FROM
		|	CashRegisterReceipts AS CashRegisterReceipts
		|		FULL JOIN ReturnData AS ReturnData
		|		ON CashRegisterReceipts.SaleTransferDocument = ReturnData.SaleTransferDocument
		|			AND CashRegisterReceipts.Products = ReturnData.Products
		|			AND CashRegisterReceipts.Characteristic = ReturnData.Characteristic
		|			AND CashRegisterReceipts.ProductsInSet = ReturnData.ProductsInSet
		|			AND CashRegisterReceipts.ItemVariantOfSet = ReturnData.ItemVariantOfSet
		|			AND CashRegisterReceipts.Series = ReturnData.Series
		|			AND CashRegisterReceipts.Package = ReturnData.Package
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	DataFromRefundImplementationDocuments.Count AS Count,
		|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
		|	CASE
		|		WHEN DataFromRefundImplementationDocuments.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
		|			THEN 1
		|		ELSE 0
		|	END AS SetIndex,
		|	DataFromRefundImplementationDocuments.ProductsInSet AS ProductsInSet,
		|	DataFromRefundImplementationDocuments.ItemVariantOfSet AS ItemVariantOfSet,
		|	DataFromRefundImplementationDocuments.Products AS Products,
		|	DataFromRefundImplementationDocuments.Characteristic AS Characteristic,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	DataFromRefundImplementationDocuments.Series AS Series,
		|	DataFromRefundImplementationDocuments.NumberOfPackages AS NumberOfPackages,
		|	DataFromRefundImplementationDocuments.Package AS Package,
		|	DataFromRefundImplementationDocuments.Sum AS Sum,
		|	DataFromRefundImplementationDocuments.VATAmount AS VATAmount,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument.Warehouse AS Warehouse,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument.Date AS SaleTransferDate,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument.Number AS SaleTransferNumber,
		|	DataFromRefundImplementationDocuments.VATRate AS VATRate,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument AS SaleTransferDocument,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument.Currency AS CurrencyOfImplementation,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument.PriceIncludesVAT AS PriceIncludesVAT,
		|	DataFromRefundImplementationDocuments.SaleTransferDocument.Partner AS Partner,
		|	0 AS AmountIncludingVAT
		|FROM
		|	DataFromRefundImplementationDocuments AS DataFromRefundImplementationDocuments
		|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|			ON ProductKitConfigurations.Owner = DataFromRefundImplementationDocuments.ProductsInSet
		|				AND ProductKitConfigurations.Characteristic = DataFromRefundImplementationDocuments.ItemVariantOfSet
		|				AND ProductKitConfigurations.Main
		|WHERE
		|	DataFromRefundImplementationDocuments.Products.ItemsType IN
		|		(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
		|
		|ORDER BY
		|	SaleTransferDate DESC";
		
		Query.SetParameter("Partner", Partner);
		Query.SetParameter("StartDate", Period.StartDate);
		Query.SetParameter("EndDate", Period.EndDate);
		Query.SetParameter("VATTaxation", VATTaxation);
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("CashRegisterReceipt", CashRegisterReceipt);
		Query.SetParameter("DocumentReturnPolicy", DocumentReturnPolicy);
		
	ElsIf ReturnBetweenCompanies Then
		
		Query.Text =
		"SELECT ALLOWED
		|	DocumentTable.Ref            AS SaleTransferDocument,
		|	DocumentTable.Ref.Warehouse      AS Warehouse,
		|	DocumentTable.Ref.Date       AS SaleTransferDate,
		|	DocumentTable.Ref.Number      AS SaleTransferNumber,
		|	DocumentTable.Ref.Currency     AS CurrencyOfImplementation,
		|	DocumentTable.ItemsLocationAttributes.Products   AS Products,
		|	DocumentTable.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	DocumentTable.ItemsLocationAttributes.Series          AS Series,
		|	DocumentTable.ItemsLocationAttributes.Purpose     AS Purpose,
		|	DocumentTable.Package          AS Package,
		|	SUM(DocumentTable.Count) AS Count,
		|	SUM(DocumentTable.NumberOfPackages) AS NumberOfPackages,
		|	DocumentTable.Ref.PriceIncludesVAT    AS PriceIncludesVAT,
		|	MAX(DocumentTable.AmountIncludingVAT
		|		/ DocumentTable.Count) AS Price,
		|	SUM(DocumentTable.AmountIncludingVAT)  AS Sum,
		|	DocumentTable.VATRate         AS VATRate,
		|	SUM(DocumentTable.VATAmount)   AS VATAmount,
		|	SUM(DocumentTable.AmountIncludingVAT)  AS AmountIncludingVAT
		|INTO TTTransfersGoods
		|FROM
		|	Document.CustomerInvoiceIntercompany.InventoryKinds AS DocumentTable
		|WHERE
		|	DocumentTable.Ref.Posted
		|	AND DocumentTable.Ref.Date BETWEEN &StartDate AND &EndDate
		|	AND DocumentTable.Ref.Warehouse = &Warehouse
		|	AND DocumentTable.Ref.Contract = &Contract
		|	AND DocumentTable.Ref.Organization = &Organization
		|	AND DocumentTable.Ref.CompanyRecipient = &Partner
		|	AND CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
		|				THEN DocumentTable.Ref.VATTaxation = &VATTaxation
		|			ELSE TRUE
		|		END
		|	AND DocumentTable.Ref.BusinessOperation = &BusinessOperation
		|
		|GROUP BY
		|	DocumentTable.Ref,
		|	DocumentTable.Ref.Warehouse,
		|	DocumentTable.Ref.Date,
		|	DocumentTable.Ref.Number,
		|	DocumentTable.Ref.Currency,
		|	DocumentTable.ItemsLocationAttributes,
		|	DocumentTable.Package,
		|	DocumentTable.Ref.PriceIncludesVAT,
		|	DocumentTable.VATRate
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT ALLOWED
		|	DocumentTable.DocumentTransfers_                  AS SaleTransferDocument,
		|	DocumentTable.Products                      AS Products,
		|	DocumentTable.Characteristic                    AS Characteristic,
		|	DocumentTable.Series                             AS Series,
		|	DocumentTable.Purpose                        AS Purpose,
		|	DocumentTable.Package                          AS Package,
		|	DocumentTable.VATRate                         AS VATRate,
		|	DocumentTable.DocumentTransfers_.Warehouse            AS Warehouse,
		|	DocumentTable.DocumentTransfers_.Date             AS SaleTransferDate,
		|	DocumentTable.DocumentTransfers_.Number            AS SaleTransferNumber,
		|	DocumentTable.DocumentTransfers_.Currency           AS CurrencyOfImplementation,
		|	DocumentTable.DocumentTransfers_.PriceIncludesVAT  AS PriceIncludesVAT,
		|	SUM(DocumentTable.Count)                 AS Count,
		|	SUM(DocumentTable.AmountIncludingVAT)                  AS Sum,
		|	SUM(DocumentTable.VATAmount)                   AS VATAmount,
		|	SUM(DocumentTable.AmountIncludingVAT)                  AS AmountIncludingVAT
		|INTO TTRefunds
		|FROM
		|	Document.IntercompanyGoodsReturn.Goods AS DocumentTable
		|WHERE
		|	DocumentTable.Ref.Posted
		|	AND DocumentTable.Ref <> &DocumentReturnPolicy
		|	AND DocumentTable.Ref.Date BETWEEN &StartDate AND &EndDate
		|	AND DocumentTable.Ref.Warehouse = &Warehouse
		|	AND DocumentTable.Ref.Contract = &Contract
		|	AND DocumentTable.Ref.Organization = &Partner
		|	AND DocumentTable.Ref.CompanyRecipient = &Organization
		|
		|GROUP BY
		|	DocumentTable.DocumentTransfers_,
		|	DocumentTable.Products,
		|	DocumentTable.Characteristic,
		|	DocumentTable.Series,
		|	DocumentTable.Purpose,
		|	DocumentTable.VATRate,
		|	DocumentTable.Package
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(DocumentTable.SaleTransferDocument, RefundTable.SaleTransferDocument) AS SaleTransferDocument,
		|	ISNULL(DocumentTable.Warehouse, RefundTable.Warehouse) AS Warehouse,
		|	ISNULL(DocumentTable.SaleTransferDate, RefundTable.SaleTransferDate) AS SaleTransferDate,
		|	ISNULL(DocumentTable.SaleTransferNumber, RefundTable.SaleTransferNumber) AS SaleTransferNumber,
		|	ISNULL(DocumentTable.CurrencyOfImplementation, RefundTable.CurrencyOfImplementation) AS CurrencyOfImplementation,
		|	ISNULL(DocumentTable.Products, RefundTable.Products) AS Products,
		|	ISNULL(DocumentTable.Characteristic, RefundTable.Characteristic) AS Characteristic,
		|	ISNULL(DocumentTable.Series, RefundTable.Series) AS Series,
		|	ISNULL(DocumentTable.Purpose, RefundTable.Purpose) AS Purpose,
		|	ISNULL(DocumentTable.Package, RefundTable.Package) AS Package,
		|	ISNULL(DocumentTable.PriceIncludesVAT, RefundTable.PriceIncludesVAT) AS PriceIncludesVAT,
		|	ISNULL(DocumentTable.VATRate, RefundTable.VATRate) AS VATRate,
		|	0 NumberOfPackages,
		|	ISNULL(DocumentTable.Count, 0) - ISNULL(RefundTable.Count, 0) AS Count,
		|	ISNULL(DocumentTable.Sum, 0) - ISNULL(RefundTable.Sum, 0) AS Sum,
		|	ISNULL(DocumentTable.VATAmount, 0) - ISNULL(RefundTable.VATAmount, 0) AS VATAmount,
		|	ISNULL(DocumentTable.AmountIncludingVAT, 0) - ISNULL(RefundTable.AmountIncludingVAT, 0) AS AmountIncludingVAT
		|FROM
		|	TTTransfersGoods AS DocumentTable
		|		FULL JOIN TTRefunds AS RefundTable
		|		ON DocumentTable.SaleTransferDocument = RefundTable.SaleTransferDocument
		|			AND DocumentTable.Products            = RefundTable.Products
		|			AND DocumentTable.Characteristic          = RefundTable.Characteristic
		|			AND DocumentTable.Series                   = RefundTable.Series
		|			AND DocumentTable.Purpose              = RefundTable.Purpose
		|			AND DocumentTable.Package                = RefundTable.Package
		|WHERE
		|	DocumentTable.Products.ItemsType IN
		|		(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
		|ORDER BY
		|	SaleTransferDate DESC";
		
		Query.SetParameter("DocumentReturnPolicy", DocumentReturnPolicy);
		Query.SetParameter("Partner", Partner);
		Query.SetParameter("Contract", Contract);
		Query.SetParameter("Warehouse", Warehouse);
		Query.SetParameter("Counterparty", Counterparty);
		Query.SetParameter("StartDate", Period.StartDate);
		Query.SetParameter("EndDate", Period.EndDate);
		Query.SetParameter("VATTaxation", VATTaxation);
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("BusinessOperation", BusinessOperation);
		
	EndIf;
	
	TableOfGoodsUnloading = Query.Execute().Unload();
	TheStructureOfTheSearch = New Structure("Products, Characteristic, 
			|Series, Purpose, VATRate, Warehouse, SaleTransferDocument");
	
	For Each String In TableOfGoodsUnloading Do
		
		If String.Count < 0 Then
		
			FillPropertyValues(TheStructureOfTheSearch, String);
			SalesLines = TableOfGoodsUnloading.FindRows(TheStructureOfTheSearch);
			
			For Each LineOfSale In SalesLines Do
			
				If LineOfSale.Count < 0 Then
					Continue;
				EndIf; 
				
				String.Count 		= -String.Count;
				String.Sum 			= -String.Sum;
				String.VATAmount 		= -String.VATAmount;
				String.AmountIncludingVAT 		= -String.AmountIncludingVAT;
				
				If String.Count > LineOfSale.Count Then
					AmountToDeduct 	= LineOfSale.Count;
					AmountToDeduct_ 		= LineOfSale.Sum;
					AmountOfVATDeducted 	= LineOfSale.VATAmount;
					AmountWithVATDeductible 	= LineOfSale.AmountIncludingVAT;
				Else
					AmountToDeduct 	= String.Count;
					AmountToDeduct_ 		= String.Sum;
					AmountOfVATDeducted 	= String.VATAmount;
					AmountWithVATDeductible 	= String.AmountIncludingVAT;
				EndIf;
				
				LineOfSale.Count 	= LineOfSale.Count - AmountToDeduct;
				String.Count 			= String.Count - AmountToDeduct;
				
				LineOfSale.Sum 		= LineOfSale.Sum - AmountToDeduct_;
				String.Sum 				= String.Sum - AmountToDeduct_;
				
				LineOfSale.VATAmount 		= LineOfSale.VATAmount - AmountOfVATDeducted;
				String.VATAmount 			= String.VATAmount - AmountOfVATDeducted;
				
				LineOfSale.AmountIncludingVAT 	= LineOfSale.AmountIncludingVAT - AmountWithVATDeductible;
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
	
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	NewCurrencyRate      = ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, Date, BaseCurrency);
	NewRateParameters = New Structure("Currency, CourseNumerator, CourseDenominator",
											Currency, NewCurrencyRate.CourseNumerator, NewCurrencyRate.CourseDenominator);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	RowsToProcess = New Array;
	RowsMap = New Map;
	For Each String In TableOfGoodsUnloading Do
	
		NewRow = TableOfGoods.Add();
		FillPropertyValues(NewRow, String);
		RowsToProcess.Add(NewRow);
		RowsMap.Insert(NewRow, String);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TableOfGoods,
		CachedValues);
	
	For Each NewRow In RowsToProcess Do
		
		String = RowsMap.Get(NewRow);
		
		If ReturnFromRetailCustomer Then
			NewRow.AmountIncludingVAT = NewRow.Sum + ?(PriceIncludesVAT, 0, NewRow.VATAmount);
		EndIf;
		
		If Currency <> String.CurrencyOfImplementation Then
			OldCurrencyRate       = ProcessingOfExchangeRatesTM.GetCurrencyRate(String.CurrencyOfImplementation, Date, BaseCurrency);
			SourceRateParameters = New Structure("Currency, CourseNumerator, CourseDenominator",
													String.CurrencyOfImplementation, OldCurrencyRate.CourseNumerator, OldCurrencyRate.CourseDenominator);
			
			NewRow.AmountIncludingVAT = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(NewRow.AmountIncludingVAT,
																						SourceRateParameters,
																						NewRateParameters);
		EndIf;
		
		PriceManagementSystem.RecalculateAmountsInRowWithVAT(NewRow, PriceIncludesVAT, False, False, True);
	
	EndDo; 
	
	FillInCCDNumbersOnOrders();
	
	TableOfGoods.Sort("SaleTransferDate,SaleTransferNumber,Products,Characteristic");
	
EndProcedure

&AtServer
Procedure FillInTareTable()
	
	PackageTable.Clear();
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	TransferredReturnablePackagingBalance.Products      AS Products,
	|	TransferredReturnablePackagingBalance.Characteristic    AS Characteristic,
	|	TransferredReturnablePackagingBalance.Partner           AS Partner,
	|	TransferredReturnablePackagingBalance.DocumentTransfers_  AS DocumentTransfers_,
	|	TransferredReturnablePackagingBalance.CountBalance AS Count,
	|	TransferredReturnablePackagingBalance.SumBalance      AS Sum
	|INTO
	|	TTTransferredReturnPackaging
	|FROM
	|	AccumulationRegister.TransferredReturnablePackaging.Balance(
	|			,
	|			Partner = &Partner
	|			AND DocumentTransfers_.Organization = &Organization
	|			AND DocumentTransfers_.Counterparty = &Counterparty
	|			AND DocumentTransfers_.CustomerCounterparty = &CustomerCounterparty
	|			AND DocumentTransfers_.CustomerPartner = &CustomerPartner
	|			AND DocumentTransfers_.Organization = &Organization
	|			AND CASE
	|				WHEN NOT &ToUseTermsOfSales
	|					THEN TRUE
	|				ELSE DocumentTransfers_.Terms = &Terms
	|			END
	|			AND CASE
	|				WHEN NOT &UseCustomerContracts
	|					THEN TRUE
	|				ELSE DocumentTransfers_.Contract = &Contract
	|			END
	|			AND DocumentTransfers_.Currency = &Currency
	|			AND DocumentTransfers_.VATTaxation = &VATTaxation
	|			AND DocumentTransfers_.PackageDepositIsRequired = &DepositForPackageIsRequired
	|		) AS TransferredReturnablePackagingBalance
	|
	|UNION ALL
	|
	|SELECT
	|	TransferredReturnMovementPackaging.Products     AS Products,
	|	TransferredReturnMovementPackaging.Characteristic   AS Characteristic,
	|	TransferredReturnMovementPackaging.Partner          AS Partner,
	|	TransferredReturnMovementPackaging.DocumentTransfers_ AS DocumentTransfers_,
	|	CASE WHEN TransferredReturnMovementPackaging.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			-TransferredReturnMovementPackaging.Count
	|		ELSE
	|			TransferredReturnMovementPackaging.Count
	|	END AS Count,
	|	CASE WHEN TransferredReturnMovementPackaging.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			-TransferredReturnMovementPackaging.Sum
	|		ELSE
	|			TransferredReturnMovementPackaging.Sum
	|	END AS Sum
	|FROM
	|	AccumulationRegister.TransferredReturnablePackaging AS TransferredReturnMovementPackaging
	|WHERE
	|	TransferredReturnMovementPackaging.Recorder = &DocumentReturnPolicy
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TTTransferredReturnPackaging.Products           AS Products,
	|	TTTransferredReturnPackaging.Characteristic         AS Characteristic,
	|	TTTransferredReturnPackaging.Partner                AS Partner,
	|	TTTransferredReturnPackaging.DocumentTransfers_       AS SaleTransferDocument,
	|	TTTransferredReturnPackaging.DocumentTransfers_.Number AS SaleTransferNumber,
	|	TTTransferredReturnPackaging.DocumentTransfers_.Date  AS SaleTransferDate,
	|	TTTransferredReturnPackaging.DocumentTransfers_.ReusablePackagesReturnDate AS ReturnDate,
	|	SUM(TTTransferredReturnPackaging.Count)      AS Count,
	|	SUM(TTTransferredReturnPackaging.Sum)           AS Sum,
	|	CASE
	|		WHEN
	|			SUM(TTTransferredReturnPackaging.Count) = 0
	|		THEN
	|			SUM(TTTransferredReturnPackaging.Sum)
	|		ELSE
	|			SUM(TTTransferredReturnPackaging.Sum) / SUM(TTTransferredReturnPackaging.Count)
	|	END AS Price
	|FROM
	|	TTTransferredReturnPackaging
	|GROUP BY
	|	TTTransferredReturnPackaging.Products,
	|	TTTransferredReturnPackaging.Characteristic,
	|	TTTransferredReturnPackaging.Partner,
	|	TTTransferredReturnPackaging.DocumentTransfers_
	|HAVING
	|	SUM(TTTransferredReturnPackaging.Count) > 0
	|ORDER BY
	|	ReturnDate ASC,
	|	Products.Description ASC,
	|	Characteristic.Description ASC
	|";

	Query.SetParameter("Partner",                          Partner);
	Query.SetParameter("CustomerPartner",                    CustomerPartner);
	Query.SetParameter("Counterparty",                       Counterparty);
	Query.SetParameter("CustomerCounterparty",                 CustomerCounterparty);
	Query.SetParameter("Organization",                      Organization);
	Query.SetParameter("Terms",                       Terms);
	Query.SetParameter("Contract",                          Contract);
	Query.SetParameter("Currency",                           Currency);
	Query.SetParameter("VATTaxation",               VATTaxation);
	Query.SetParameter("DocumentReturnPolicy",                 DocumentReturnPolicy);
	Query.SetParameter("ToUseTermsOfSales", ToUseTermsOfSales);
	Query.SetParameter("UseCustomerContracts",   UseCustomerContracts);
	Query.SetParameter("DepositForPackageIsRequired",          DepositForPackageIsRequired);
	
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
Function CheckWhetherCashRegisterReceiptCanBeTransferred()
	
	If ReturnFromRetailCustomer Then
		TableOfBases_ = TableOfGoods.Unload(TableOfGoods.FindRows(New Structure("Selected", True)));
		TableOfBases_.GroupBy("SaleTransferDocument");
		If TableOfBases_.Count() <= 1 Then
			Return True
		Else
			Return False
		EndIf;
	Else
		Return True
	EndIf;
	
EndFunction

&AtClient
Procedure OpenProductItemCard()

	CurrentData = Items.TableOfGoods.CurrentData;
	
	If CurrentData <> Undefined Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	EndIf;

EndProcedure

&AtServer
Procedure FillInCCDNumbersOnOrders()
	
	FillParameters = PurchasesServer.ParametersForFillingInCCDNumbersBasedOnCredentials();
	QueryOptions = FillParameters.QueryOptions;
	QueryOptions.Ref = DocumentReturnPolicy;
	
	ParametersForRecalculatingAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	ActionsWithString = New Structure;
	ActionsWithString.Insert("RecalculateAmount");
	ActionsWithString.Insert("RecalculateVATAmount",	ParametersForRecalculatingAmount);
	ActionsWithString.Insert("RecalculateAmountWithVAT",	ParametersForRecalculatingAmount);
	
	FillParameters.ActionsWithString	= ActionsWithString;
	FillParameters.NameOfOrderField	= "SaleTransferDocument";
	
	PurchasesServer.FillInCCDNumbersAccordingToCredentials(TableOfGoods, "ByReferences", FillParameters);
	
EndProcedure

#EndRegion

#EndRegion
