#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

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

	DocumentCurrency       = Parameters.DocumentCurrency;
	VATTaxation    = Parameters.VATTaxation;
	PriceIncludesVAT       = Parameters.PriceIncludesVAT;
	UseWarehouseManagemantSystemForGoodsIssue = Parameters.AdvancedWarehousingOnShipment;
	SalesOrder          = Parameters.SalesOrder;
	OrderSales   = Parameters.OrderSales;
	BusinessOperation = Parameters.BusinessOperation;
	ShipmentStarted      = InvoicesServer.ThereIsSpendingOrderForShippingOrders(Parameters.Document);
	If Parameters.Property("ARAPObjectSettings") Then
		ARAPObjectSettings = Parameters.ARAPObjectSettings;
	EndIf;
	
	GoodsAddressInTemporaryStorage = Parameters.GoodsAddressInTemporaryStorage;
	AddressOfBarcodesOfImplementationPackagesInTemporaryStorage = Parameters.AddressOfBarcodesOfImplementationPackagesInTemporaryStorage;
	
	OrdersFirst = 
		Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst;
	UseSalesOrders = GetFunctionalOption("UseSalesOrders") 
		Or GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");
	UseSaleByMultipleOrders = GetFunctionalOption("UseSaleByMultipleOrders");
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	ByNote = (OrdersFirst And UseWarehouseManagemantSystemForGoodsIssue);
	
	Items.ByNote.Visible = UseSalesOrders And UseWarehouseManagemantSystemForGoodsIssue;
	Items.CustomImplementation.Visible = OrderSales And UseSaleByMultipleOrders;
	Items.SalesOrder.Visible = OrderSales And UseSaleByMultipleOrders;
	Items.OrderSales.Visible = OrderSales And UseSaleByMultipleOrders;
	Items.LabelHeaderSalesOrders.Visible = OrderSales And UseSaleByMultipleOrders;
	Items.TableOfGoodsPackagingQuantityInTheNote.Visible = UseWarehouseManagemantSystemForGoodsIssue;
	Items.TableOfGoodsNumberOfPackagingUnitsInTransit.Visible =
		(BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);
	Items.TableOfGoodsDepartment.Visible = UseBusinessUnits;
	
	FillInTheGoodsTable(Parameters.Document, Parameters.DocumentCurrency);
	SetTitleFillInByOrdersOrders();
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Parameters.Document);
	
	ObjectParameters = New Structure(Documents.CustomerInvoice.NamesOfDetailsForFillingInParametersForSpecifyingSeries());
	FillPropertyValues(ObjectParameters, Parameters);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ObjectParameters, Documents.CustomerInvoice);
	Items.TableOfGoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
	ThereAreGatheringGoods = TableOfGoods.Total("AccountingIsCollected") > 0;
	Items.TableOfGoodsNumberInProgress.Visible = ThereAreGatheringGoods;
	Items.InfoDecoration.Visible = ThereAreGatheringGoods;
	Items.DecorationInformationThereAreCollectedGoods.Visible = ThereAreGatheringGoods;
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
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

&AtClient
Procedure TableOfGoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.TableOfGoods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, PriceIncludesVAT);
	CurrentRow.ThereIsAManualChange = True;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CurrentRow.DiscrepancyInvoice = CurrentRow.NumberOfPackages - CurrentRow.PackagingQuantityInInvoice;
EndProcedure

&AtClient
Procedure ByOrdersOnChange(Item)
	
	WhenChangingByOrders();
	
EndProcedure

&AtClient
Procedure ByNoteOnChange(Item)
	ReFillAmountMatched();
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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()
	
	MoveProductsToDocument();
	
EndProcedure

&AtClient
Procedure ToChooseTheProductsExecute()
	
	SelectSelectedRows(True);
	
EndProcedure

&AtClient
Procedure ExcludeGoodsExecute()
	
	SelectSelectedRows(False);
	
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
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	Item.Appearance.SetParameterValue("Visible", False);

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
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "TableOfGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "TableOfGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsPackagingQuantityInTheOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByNote");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.BackgroundColorIsFullyProvided);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsPackagingQuantityInTheNote.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByNote");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.BackgroundColorIsFullyProvided);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsNumberOfPackagingUnitsInTransit.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.BackgroundColorIsFullyProvided);

EndProcedure

#Region Other

&AtClient
Procedure SelectSelectedRows(SelectionValue = True)
	
	For Each LineNumber In Items.TableOfGoods.SelectedRows Do
		TSRow = TableOfGoods.FindByID(LineNumber);
		TSRow.RowIsSelected = SelectionValue;        
	EndDo;

EndProcedure

&AtServer
Function PutProductsInStorage()
	
	// Forming a table to return to the document.
	SelectedGoodsTable = TableOfGoods.Unload(New Structure("RowIsSelected", True));

	// generating stamp data (if any) for uploading to a document
	TableOfSelectedBarcodesOfPackages = TableOfBarcodesOfPackages.Unload(New Structure("UploadToImplementation", True));
	For Each String In TableOfGoods Do
		BrandSearchStructure = New Structure();
		BrandSearchStructure.Insert("SalesOrder",String.SalesOrder);
		BrandSearchStructure.Insert("Products",String.Products);
		BrandSearchStructure.Insert("Characteristic",String.Characteristic);
		BrandSearchStructure.Insert("Series",String.Series);
		BrandSearchStructure.Insert("FromWarrant",String.RowIsSelected);
		
		FoundRows = TableOfBarcodesOfPackages.FindRows(BrandSearchStructure);
		
		NumberOfAdded = 0;
		For Each FoundRow In FoundRows Do
			NumberOfAdded = NumberOfAdded + 1;

			If String.RowIsSelected And NumberOfAdded > String.NumberOfPackages Then
				Break;
			EndIf;
			
			NewRow = TableOfSelectedBarcodesOfPackages.Add();
			FillPropertyValues(NewRow, FoundRow);
		EndDo;
		
	EndDo;
	
	GoodsAddressInStorage = PutToTempStorage(New Structure("Goods, PackageBarcodes",
														SelectedGoodsTable, TableOfSelectedBarcodesOfPackages));

	Return GoodsAddressInStorage;

EndFunction

&AtServer
Procedure FillInTheGoodsTable(Document, DocumentCurrency)
	
	GoodsSales_ = GetFromTempStorage(GoodsAddressInTemporaryStorage);
	
	SelectionData_ = New Structure;
	SelectionData_.Insert("Partner",                   Parameters.Partner);
	SelectionData_.Insert("Counterparty",                Parameters.Counterparty);
	SelectionData_.Insert("Contract",                   Parameters.Contract);
	SelectionData_.Insert("Organization",               Parameters.Organization);
	SelectionData_.Insert("BusinessOperation",     BusinessOperation);
	SelectionData_.Insert("Terms",                Parameters.Terms);
	SelectionData_.Insert("Currency",                    Parameters.DocumentCurrency);
	SelectionData_.Insert("ARAPCurrency",      Parameters.ARAPCurrency);
	SelectionData_.Insert("VATTaxation",        Parameters.VATTaxation);
	SelectionData_.Insert("PriceIncludesVAT",           Parameters.PriceIncludesVAT);
	SelectionData_.Insert("ARAPObjectSettings",           Parameters.ARAPObjectSettings);
	SelectionData_.Insert("ToReturnReusablePackage", Parameters.ToReturnReusablePackage);
	SelectionData_.Insert("PackageDepositIsRequired",      Parameters.PackageDepositIsRequired);
	SelectionData_.Insert("Warehouse",                     Parameters.Warehouse);
	SelectionData_.Insert("Date",                      Parameters.Date);
	SelectionData_.Insert("Ref",                    Parameters.Document);
	SelectionData_.Insert("SalesOpportunity",                    Parameters.SalesOpportunity);
	SelectionData_.Insert("GoodsSales_",          GoodsSales_);
	SelectionData_.Insert("LineOfBusiness",   Parameters.LineOfBusiness);
	
	FillParameters = New Structure;
	FillParameters.Insert("DisplayMessage_1", False);
	FillParameters.Insert("SelectionByOrdersOrders", True);
	FillParameters.Insert("CourseNumerator", 0);
	FillParameters.Insert("CourseDenominator", 0);
	FillParameters.Insert("AdvancedWarehousingOnShipment", Parameters.AdvancedWarehousingOnShipment);
	FillParameters.Insert("UseAdvancedFeaturesOfSalesOrder",
		Parameters.UseAdvancedFeaturesOfSalesOrder);
	FillParameters.Insert("CheckOrderOfCalculations", False);
	
	Documents.CustomerInvoice.FillByOrderBalances(
		SelectionData_,
		TableOfGoods,
		TableDiscountsMarkups,
		TableAccrualOfBonusPoints,
		Parameters.Warehouse,
		Undefined,
		FillParameters,
		TableOfBarcodesOfPackages);
	
	For Each RowOfGoods In TableOfGoods Do
		RowOfGoods.AmountOfManualDiscountsOnOrder = RowOfGoods.ManualDiscount;
		RowOfGoods.AmountOfBonusPointsToBeDebitedOnOrder = RowOfGoods.AmountOfBonusPointsToDeduction;
		RowOfGoods.AmountOfBonusPointsToBeDebitedInCurrencyOfOrder = RowOfGoods.AmountOfBonusPointsToDeductionInCurrency;
		RowOfGoods.AmountOfAccruedBonusPointsInCurrencyOfOrder = RowOfGoods.AmountOfEarnedBonusPointsInCurrency;
	EndDo; 
	
	OrdersServer.SetSignsOfPresenceOfLineInDocument(TableOfGoods, "SalesOrder", Parameters.ArrayOfStringCodes);
	
	BarcodesOfImplementationPackages = CustomerInvoiceLocalization.GetBarcodesOfImplementationPackages(Document);
	
	ReFillAmountMatched(True, GoodsSales_, BarcodesOfImplementationPackages);
	
EndProcedure

&AtServer
Procedure ReFillAmountMatched(WithFilling = False, GoodsSales_ = Undefined, BarcodesOfImplementationPackages = Undefined)
	
	If WithFilling Then
		UpdateOrderInformation(GoodsSales_);
		ByOrders = ?(OrderList.Count() > 0, OrderList.Count() > 0, ValueIsFilled(SalesOrder)) Or ShipmentStarted;
		
		SetSelectionByOrders();
		
		If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
			TheStructureOfTheSearch = New Structure("Products, Characteristic, RowCode, SalesOrder");
		Else
			TheStructureOfTheSearch = New Structure("Products, Characteristic, RowCode, SalesOrder, Series, Warehouse");
		EndIf;
		
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, PriceIncludesVAT);
	
	StructureOfActionsWithoutRecalculationOfManualDiscount = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithoutRecalculationOfManualDiscount, PriceIncludesVAT);
	If StructureOfActionsWithoutRecalculationOfManualDiscount.Property("RecalculateAmountTakingIntoAccountManualDiscount") Then
		StructureOfActionsWithoutRecalculationOfManualDiscount.RecalculateAmountTakingIntoAccountManualDiscount.Insert("RecalculateAmountOfManualDiscount_",False);
	EndIf; 	

	ArrayOfRowsToDelete_1 = New Array;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;
	ProcessedRowsWithoutRecalculatingManualDiscount = New Array;
	For Each CurRow In TableOfGoods Do
		
		If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
			NumberOfPackagesToBeProcessed = CurRow.NumberOfPackagingUnitsInTransit;
			QuantityToRegister = CurRow.QuantityInTransit;
		Else
			NumberOfPackagesToBeProcessed = CurRow.PackagingQuantityInTheOrder;
			QuantityToRegister = CurRow.QuantityInOrder;
		EndIf;
		
		NumberOfPackagesBeforeChange = CurRow.NumberOfPackages;
		CurRow.NumberOfPackages = ?(ByNote, CurRow.PackagingQuantityInTheNote, NumberOfPackagesToBeProcessed);
		CurRow.Count = ?(ByNote, CurRow.NoteQuantity, QuantityToRegister);
		If CurRow.NumberOfPackages <> NumberOfPackagesBeforeChange Then
			If CurRow.ThereIsAManualChange Or QuantityToRegister = 0 Then
				RowsToProcess.Add(CurRow);
			Else
				ConversionFactor_ = (CurRow.Count / QuantityToRegister);
				CurRow.ManualDiscount = CurRow.AmountOfManualDiscountsOnOrder * ConversionFactor_;
				CurRow.AmountOfBonusPointsToDeduction = CurRow.AmountOfBonusPointsToBeDebitedOnOrder * ConversionFactor_;
				CurRow.AmountOfBonusPointsToDeductionInCurrency = CurRow.AmountOfBonusPointsToBeDebitedInCurrencyOfOrder * ConversionFactor_;
				CurRow.AmountOfEarnedBonusPointsInCurrency = CurRow.AmountOfAccruedBonusPointsInCurrencyOfOrder * ConversionFactor_;
				ProcessedRowsWithoutRecalculatingManualDiscount.Add(CurRow);
			EndIf; 
		EndIf;
		If WithFilling Then
			FillPropertyValues(TheStructureOfTheSearch, CurRow);
			Rows = GoodsSales_.FindRows(TheStructureOfTheSearch);
			If Rows.Count() > 0 Then
				ImplementationString = Rows.Get(0);
				FillPropertyValues(CurRow, ImplementationString,,"PriceKind, Price, Count, NumberOfPackages");
				If CurRow.NumberOfPackages <> ImplementationString.NumberOfPackages Then
					RowsToProcess.Add(CurRow);
				EndIf;
				CurRow.QuantityInInvoice = ImplementationString.Count;
				CurRow.PackagingQuantityInInvoice = ImplementationString.NumberOfPackages;
				CurRow.ExistsInTheDocument = True;
				GoodsSales_.Delete(ImplementationString);
			EndIf;
		EndIf;
		
		If OrderList.FindByValue(CurRow.SalesOrder) <> Undefined 
			Or CurRow.SalesOrder = SalesOrder
			Or Not ValueIsFilled(CurRow.SalesOrder) Then
			
			CurRow.OrderFromInvoice = True;
			
		EndIf;
		
		CurRow.DiscrepancyInvoice = CurRow.NumberOfPackages - CurRow.PackagingQuantityInInvoice;
		If (CurRow.DiscrepancyInvoice <> 0 Or CurRow.ThereIsDiscrepancyInBrands)
			And ((CurRow.OrderFromInvoice And ByOrders) Or Not ByOrders) Then
			CurRow.RowIsSelected = True;
		Else
			CurRow.RowIsSelected = False;
		EndIf;
		
		If WithFilling Then
			If (CurRow.PackagingQuantityInInvoice = NumberOfPackagesToBeProcessed
					Or Not ValueIsFilled(CurRow.SalesOrder))
				And (CurRow.PackagingQuantityInInvoice = CurRow.PackagingQuantityInTheNote 
					Or Not CurRow.AdvancedWarehousingOnShipment) Then
					
				If CurRow.MarkedProducts And CurRow.AdvancedWarehousingOnShipment Then
					SetOfStampsIsDifferent = False;
					
					BrandSearchStructure = New Structure("SalesOrder, Products, Characteristic, Series");
					FillPropertyValues(BrandSearchStructure, CurRow);
					BrandsFound = TableOfBarcodesOfPackages.FindRows(BrandSearchStructure);
					
					ArrayOfDeletedRowsOfImplementationMarks = New Array;
					For Each String In BrandsFound Do
						BrandSearchStructure = New Structure("Products, Characteristic, Series, PackageBarcode");
						FillPropertyValues(BrandSearchStructure, String);
						FoundBrandsOfImplementation = BarcodesOfImplementationPackages.FindRows(BrandSearchStructure);
						If FoundBrandsOfImplementation.Count() > 0 Then
							ArrayOfDeletedRowsOfImplementationMarks.Add(FoundBrandsOfImplementation[0]);
						Else
							SetOfStampsIsDifferent = True;
						EndIf; 
					EndDo; 
					
					If Not SetOfStampsIsDifferent Then
						SetOfStampsIsDifferent = (BrandsFound.Count() <> ArrayOfDeletedRowsOfImplementationMarks.Count());
					EndIf; 
					
					If SetOfStampsIsDifferent Then
						CurRow.RowIsSelected = SetOfStampsIsDifferent;
						CurRow.StatusOfStateIPVerification = 2;
						
						For Each String In ArrayOfDeletedRowsOfImplementationMarks Do
							NewRow = TableOfBarcodesOfPackages.Add();
							FillPropertyValues(NewRow, String);
							
							BarcodesOfImplementationPackages.Delete(String);
						EndDo;
					Else
						ArrayOfRowsToDelete_1.Add(TableOfGoods.IndexOf(CurRow));
						
						For Each Item In BrandsFound Do
							Item.UploadToImplementation = True;
						EndDo;
						
						For Each String In ArrayOfDeletedRowsOfImplementationMarks Do
							BarcodesOfImplementationPackages.Delete(String);
						EndDo;
					EndIf;
				Else
					ArrayOfRowsToDelete_1.Add(TableOfGoods.IndexOf(CurRow));
				EndIf;
			Else
				If CurRow.MarkedProducts And CurRow.AdvancedWarehousingOnShipment Then
					BrandSearchStructure = New Structure("SalesOrder, Products, Characteristic, Series");
					FillPropertyValues(BrandSearchStructure, CurRow);
					BrandsFound = TableOfBarcodesOfPackages.FindRows(BrandSearchStructure);
					
					SetOfStampsIsDifferent = BrandsFound.Count() > 0;
					CurRow.ThereIsDiscrepancyInBrands = SetOfStampsIsDifferent;
					
					If SetOfStampsIsDifferent Then
						CurRow.StatusOfStateIPVerification = 2;
						If (CurRow.OrderFromInvoice And ByOrders) Or Not ByOrders Then
							CurRow.RowIsSelected = SetOfStampsIsDifferent;
						EndIf; 
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		CurRow.AccountingIsCollected = Number(Not ValueIsFilled(CurRow.SalesOrder) And CurRow.NumberInProgress > 0);
		
	EndDo;
	
	RowsToProcess = CommonClientServer.CollapseArray(RowsToProcess);
	RowsToProcess = CommonClientServer.ArraysDifference(RowsToProcess, ArrayOfRowsToDelete_1);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TableOfGoods,
		CachedValues);
		
	ProcessedRowsWithoutRecalculatingManualDiscount
		= CommonClientServer.ArraysDifference(ProcessedRowsWithoutRecalculatingManualDiscount, ArrayOfRowsToDelete_1);
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsWithoutRecalculatingManualDiscount,
		StructureOfActionsWithoutRecalculationOfManualDiscount,
		TableOfGoods,
		CachedValues);
	
	IndexOfArrayElement = ArrayOfRowsToDelete_1.Count() - 1;
	While IndexOfArrayElement >= 0 Do
		TableOfGoods.Delete(ArrayOfRowsToDelete_1[IndexOfArrayElement]);
		IndexOfArrayElement = IndexOfArrayElement - 1;
	EndDo;
	
	If WithFilling Then
		For Each CurRow In GoodsSales_ Do
			LineProducts_ = TableOfGoods.Add();
			FillPropertyValues(LineProducts_, CurRow,,"Count, NumberOfPackages");
			LineProducts_.QuantityInInvoice = CurRow.Count;
			LineProducts_.PackagingQuantityInInvoice = CurRow.NumberOfPackages;
			LineProducts_.RowIsSelected = True;
			LineProducts_.ExistsInTheDocument = True;
			LineProducts_.DiscrepancyInvoice = -LineProducts_.PackagingQuantityInInvoice;
			LineProducts_.OrderFromInvoice = True;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveProductsToDocument()
	
	ArrayOfARAPObjectsSettings = New Array;
	If OrderList.Count() > 0 
		And ValueIsFilled(ARAPObjectSettings)Then
		ArrayOfARAPObjectsSettings.Add(ARAPObjectSettings);
	EndIf;
	For Each RowOfProduct In TableOfGoods Do
		If RowOfProduct.RowIsSelected
			And ValueIsFilled(RowOfProduct.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(RowOfProduct.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(RowOfProduct.ARAPObjectSettings);
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
	
	// Removal of modification, because before closing, the attribute is checked.
	Modified = False;
	Cancel = False;
	
	If Not UseSaleByMultipleOrders Then
		Cancel = CheckMultipleOrderSelection();
	EndIf;
	
	If Cancel Then
		ShowMessageBox(,NStr("vi = 'Bạn không thể chọn hàng hóa cho nhiều hơn một đơn hàng.';
							|ru = 'Нельзя выбрать товары больше, чем по одному заказу.';
							|en = 'You cannot select more goods than against one order.'; fa = 'You cannot select more goods than against one order.';
							|it = 'Non è possibile selezionare prodotti per più di un ordine.';
							|pl = 'Nie można wybrać towarów dla więcej niż jednego zamówienia.';
							|tr = 'Bir siparişten fazla mal seçemezsiniz.'"));
		Return
	EndIf;
	
	GoodsAddressInStorage = PutProductsInStorage();
	
	Close();

	NotifyChoice(New Structure("GoodsAddressInStorage", GoodsAddressInStorage));

EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, PriceIncludesVAT)
	
	StructureOfRecalculationOfAmount = New Structure("PriceIncludesVAT", PriceIncludesVAT);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountOfAutomaticDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints",
									New Structure("RecalculateAmountOfBonusPointsByLine", True));
	
EndProcedure

&AtServer
Function CheckMultipleOrderSelection()
	
	CustomerSFirstOrder = Undefined;
	
	For Each CurRow In TableOfGoods.FindRows(New Structure("RowIsSelected", True)) Do
		If CurRow.RowIsSelected Then
			If ValueIsFilled(CustomerSFirstOrder)
				And ValueIsFilled(CurRow.SalesOrder)
				And CustomerSFirstOrder <> CurRow.SalesOrder Then
				
				Return True
				
			EndIf;
			
			CustomerSFirstOrder = CurRow.SalesOrder;
			
		EndIf;
	EndDo;
	
	Return False
	
EndFunction

&AtServer
Procedure UpdateOrderInformation(GoodsSales_)
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "SalesOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.OrderNameInTablePart          = "SalesOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseSaleByMultipleOrders;
	
	OrdersServer.UpdateOrderInformationInForm(ThisForm, GoodsSales_, ParametersOfUpdate);
	
EndProcedure

&AtServer
Procedure WhenChangingByOrders()
	
	SetSelectionByOrders();
	
	If ByOrders Then
		ResetSelectionOfRowsNotFromInvoice();
	Else
		SetSelectionOfLinesNotFromInvoice();
	EndIf;
EndProcedure

&AtServer
Procedure SetSelectionByOrders()
	
	If ByOrders Then
		Items.TableOfGoods.RowFilter = New FixedStructure("OrderFromInvoice", True);
	Else
		Items.TableOfGoods.RowFilter = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure ResetSelectionOfRowsNotFromInvoice()
	TheStructureOfTheSearch = New Structure("RowIsSelected", True);
	GoodsSelected = TableOfGoods.FindRows(TheStructureOfTheSearch);
	
	For Each StringMatched In GoodsSelected Do
		StringMatched.RowIsSelected = StringMatched.OrderFromInvoice;
	EndDo; 
EndProcedure

&AtServer
Procedure SetSelectionOfLinesNotFromInvoice()
	TheStructureOfTheSearch = New Structure("RowIsSelected", False);
	GoodsSelected = TableOfGoods.FindRows(TheStructureOfTheSearch);
	
	For Each StringMatched In GoodsSelected Do
		If StringMatched.DiscrepancyInvoice <> 0 Then
			StringMatched.RowIsSelected = True;
		Else
			StringMatched.RowIsSelected = False;
		EndIf;
	EndDo; 
	
EndProcedure

&AtServer
Procedure SetTitleFillInByOrdersOrders()
	
	If Not UseWarehouseManagemantSystemForGoodsIssue And UseSalesOrders Then
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ đơn hàng';
							|ru = 'Подбор товаров по заказам';
							|en = 'Pick goods by orders'; fa = 'Pick goods by orders';
							|it = 'Selezione delle merci per ordini';
							|pl = 'Wybór towarów wg zamówień';
							|tr = 'Siparişe göre ürünlerin seçimi'");
	ElsIf UseWarehouseManagemantSystemForGoodsIssue And Not UseSalesOrders Then
		TitleFillIn = NStr("vi = 'Lựa chọn hàng hóa theo lệnh';
							|ru = 'Подбор товаров по ордерам';
							|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
							|it = 'Selezione delle merci per mandati';
							|pl = 'Wybór towarów wg zleceń';
							|tr = 'Emire göre ürünlerin seçimi'");
	Else
		TitleFillIn = NStr("vi = 'Lựa chọn hàng hóa theo lệnh / đơn hàng';
							|ru = 'Подбор товаров по заказам/ордерам';
							|en = 'Pick by Order/Goods issue'; fa = 'انتخاب بر اساس سفارش/صدور کالا';
							|it = 'Selezione delle merci per ordini/mandati';
							|pl = 'Wybór towarów wg zamówień/zleceń wydania';
							|tr = 'Siparişe/emre göre ürünlerin seçimi'");
	EndIf;
	
	Title = TitleFillIn;
	
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

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
