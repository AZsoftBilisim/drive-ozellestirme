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
	
	EconomicOperationsOfSeparatePurchase = PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections();
	
	SeparatePurchaseOperationIsUsed = False;
	If EconomicOperationsOfSeparatePurchase.Find(Parameters.BusinessOperation) <> Undefined Then
		SeparatePurchaseOperationIsUsed = True;
	EndIf;
	
	Ref             = Parameters.Ref;
	DocumentCurrency    = Parameters.DocumentCurrency;
	VATTaxation = Parameters.VATTaxation;
	PriceIncludesVAT    = Parameters.PriceIncludesVAT;
	ReceiptUnderOrders = Parameters.ReceiptUnderOrders;
	PurchaseOrder      = Parameters.PurchaseOrder;
	If Parameters.Property("BusinessOperation") Then
		BusinessOperation = Parameters.BusinessOperation;
	EndIf;
	If Parameters.Property("ARAPObjectSettings") Then
		ARAPObjectSettings = Parameters.ARAPObjectSettings;
	EndIf;
	
	AddressGoodsReceiptGoodsInTheTemporaryStorage = Parameters.AddressGoodsReceiptGoodsInTheTemporaryStorage;
	UseReceiptForMultipleOrders = GetFunctionalOption("UseReceiptForMultipleOrders");
	UseWarehouseManagemantSystemForGoodsReceipt = Parameters.AdvancedWarehousingOnReceiving;
	UsePurchaseOrders = GetFunctionalOption("UsePurchaseOrders");
	If Parameters.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		UsePurchaseOrders = GetFunctionalOption("UseMaterialProviderOrder2_5");
		Items.TableOfGoodsPurchaseOrder.Title = NStr("vi = 'Bên đặt gia công';
													|ru = 'Давалец';
													|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
													|it = 'Fornitore';
													|pl = 'Material provider';
													|tr = 'Malzeme tedarikçisi'");
		UseReceiptForMultipleOrders = True;
	EndIf;
	UseDiscountAdjustmentsInSales = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	
	Items.ByNote.Visible = UsePurchaseOrders And UseWarehouseManagemantSystemForGoodsReceipt;
	If SeparatePurchaseOperationIsUsed Then
		Items.TableOfGoodsPackagingQuantityInTheNote.Title = NStr("vi = 'Trong tiếp nhận';
																	|ru = 'В поступлениях';
																	|en = 'In receipts'; fa = 'In receipts';
																	|it = 'Negli arrivi';
																	|pl = 'We wpłatach';
																	|tr = 'Makbuzlarda'");
	EndIf;
	Items.ReceiptAgainstOrder.Visible = ReceiptUnderOrders And UseReceiptForMultipleOrders;
	Items.PurchaseOrder.Visible = ReceiptUnderOrders And UseReceiptForMultipleOrders;
	Items.ReceiptUnderOrders.Visible = ReceiptUnderOrders And UseReceiptForMultipleOrders;
	Items.LabelHeadingOrdersToSuppliers.Visible = ReceiptUnderOrders And UseReceiptForMultipleOrders;
	Items.TableOfGoodsPackagingQuantityInTheNote.Visible = UseWarehouseManagemantSystemForGoodsReceipt;
	
	PurchaseIsSubjectToVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(VATTaxation);
	
	If PurchaseIsSubjectToVAT Then
		Items.VATPageGroup.CurrentPage   = Items.PageVAT;
		Items.PagesTotalGroup.CurrentPage = Items.TotalSNDSPage;
	Else
		Items.VATPageGroup.CurrentPage   = Items.PageExcludingVAT;
		Items.PagesTotalGroup.CurrentPage = Items.PageTotalWithoutVAT;
	EndIf;
		
	FillInTheGoodsTable();
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Parameters.Ref);
	SetTitleFillInByOrdersOrders();
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

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TableOfGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.TableOfGoods.CurrentData <> Undefined Then
		If Field.Name = "TableOfGoodsPurchaseOrder" Then
			ShowValue(Undefined, Items.TableOfGoods.CurrentData.PurchaseOrder);
		ElsIf Field.Name = "TableOfGoodsSalesOpportunity" Then
			ShowValue(Undefined, Items.TableOfGoods.CurrentData.SalesOpportunity);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ByNoteOnChange(Item)
	ReFillAmountMatched();
EndProcedure

&AtClient
Procedure ByOrdersOnChange(Item)
	
	WhenChangingByOrders();
	
EndProcedure

&AtClient
Procedure LabelHeadingOrdersToSuppliersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	If BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5") Then
		ValueOfHeaderParameter = NStr("vi = 'Đơn hàng của bên đặt gia công (%DocumentsCount%)';
										|ru = 'Заказы давальцев (%DocumentsCount%)';
										|en = 'Subcontracting sales orders (%DocumentsCount%)'; fa = 'Subcontracting sales orders (%DocumentsCount%)';
										|it = 'Ordini dei prestatori (%DocumentsCount%)';
										|pl = 'Zamówienia właścicieli surowca (%DocumentsCount%)';
										|tr = 'Sağlayıcı siparişleri (%DocumentsCount%)'");
	Else
		ValueOfHeaderParameter = NStr("vi = 'Đơn hàng đặt nhà cung cấp (%DocumentsCount%)';
										|ru = 'Заказы поставщикам (%DocumentsCount%)';
										|en = 'Purchase orders (%DocumentsCount%)'; fa = 'Purchase orders (%DocumentsCount%)';
										|it = 'Ordini ai fornitori (%DocumentsCount%)';
										|pl = 'Zamówienia dla dostawców (%DocumentsCount%)';
										|tr = 'Satın alma siparişleri (%DocumentsCount%)'");
	EndIf;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			OrderList,
			ValueOfHeaderParameter
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()
	
	MoveProductsToDocument();
	
EndProcedure

&AtClient
Procedure ToChooseTheProductsExecute()
	
	SelectSelectedRows();
		
EndProcedure

&AtClient
Procedure ExcludeGoodsExecute()
	
	SelectSelectedRows(False);
		
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure TableOfGoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.TableOfGoods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, PriceIncludesVAT);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);

	RecalculateTotalAmount();
	
EndProcedure

&AtClient
Procedure TableOfGoodsSelectedOnChange(Item)
	
	RecalculateTotalAmount();
	
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
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsSalesOpportunity.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.SalesOpportunity");
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
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsVATRate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsAmountIncludingVAT.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;

	Item.Appearance.SetParameterValue("Visible", False);

	// Registration of the warehouse and division
	// disabling the visibility of the warehouse, if the work or service.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ValueList.Add(Enums.ItemsTypes.OperationService);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("Visible", False);
	
	// disabling the visibility of the division if the product or container

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("Visible", False);
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "TableOfGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "TableOfGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsVendorPriceKind.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
	ValueList.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	ValueList.Add(Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5);
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("Visible", False);

EndProcedure

#Region Other

&AtClient
Procedure SelectSelectedRows(SelectionValue = True)
	
	For Each LineNumber In Items.TableOfGoods.SelectedRows Do
		TSRow = TableOfGoods.FindByID(LineNumber);
		TSRow.RowIsSelected = SelectionValue;        
	EndDo;

	RecalculateTotalAmount();
	
EndProcedure

&AtServer
Function PutProductsInStorage()
	
	Result = TableOfGoods.Unload(New Structure("RowIsSelected", True));
	Return PutToTempStorage(Result);
	
EndFunction

&AtServer
Procedure FillInTheGoodsTable()
	
	InvoiceGoods = GetFromTempStorage(AddressGoodsReceiptGoodsInTheTemporaryStorage);
	
	SelectionData_ = New Structure();
	SelectionData_.Insert("Partner",                   Parameters.Partner);
	SelectionData_.Insert("Counterparty",                Parameters.Counterparty);
	SelectionData_.Insert("Contract",                   Parameters.Contract);
	SelectionData_.Insert("Organization",               Parameters.Organization);
	SelectionData_.Insert("BusinessOperation",     Parameters.BusinessOperation);
	SelectionData_.Insert("Terms",                Parameters.Terms);
	SelectionData_.Insert("Currency",                    Parameters.DocumentCurrency);
	SelectionData_.Insert("ARAPCurrency",      Parameters.ARAPCurrency);
	SelectionData_.Insert("VATTaxation",        Parameters.VATTaxation);
	SelectionData_.Insert("PriceIncludesVAT",           Parameters.PriceIncludesVAT);
	SelectionData_.Insert("ARAPObjectSettings",           Parameters.ARAPObjectSettings);
	SelectionData_.Insert("ToReturnReusablePackage", Parameters.ToReturnReusablePackage);
	SelectionData_.Insert("PackageDepositIsRequired",      Parameters.PackageDepositIsRequired);
	SelectionData_.Insert("Warehouse",                     Parameters.Warehouse);
	SelectionData_.Insert("Ref",                    Parameters.Ref);
	SelectionData_.Insert("Date",                      Parameters.Date);
	SelectionData_.Insert("LineOfBusiness",   Parameters.LineOfBusiness);
	SelectionData_.Insert("InvoiceGoods",           InvoiceGoods);
	SelectionData_.Insert("GoodsReceiptOption",     Parameters.GoodsReceiptOption);
	SelectionData_.Insert("FinancialAccountingGroup",    Parameters.FinancialAccountingGroup);
	SelectionData_.Insert("Department",             Parameters.Department);
	SelectionData_.Insert("OperationWithSelfEmployedPerson",      Parameters.OperationWithSelfEmployedPerson);
	SelectionData_.Insert("OnlyWorksServices",        Parameters.OnlyWorksServices);
	
	If Not ValueIsFilled(Parameters.PurchaseOrder) Or GetFunctionalOption("UseReceiptForMultipleOrders") Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(Parameters.PurchaseOrder);
	EndIf;
	
	FillInForAcceptanceOrders(SelectionData_, TableOfGoods, Parameters.Warehouse, ByNote, AnArrayOfOrders);
	OrdersServer.SetSignsOfPresenceOfLineInDocument(TableOfGoods, "PurchaseOrder", Parameters.ArrayOfStringCodes);
	ReFillAmountMatched(True, InvoiceGoods, SelectionData_);
	
EndProcedure

&AtServer
Procedure FillInForAcceptanceOrders(SelectionData_, Goods, WarehouseForReceipt, ByNote,
		AnArrayOfOrders = Undefined)
	
	OrderOrder = False;
	ObjectManager   = Common.ObjectManagerByRef(SelectionData_.Ref);
	
	ObjectManager.FillByOrderBalances(SelectionData_, Goods, WarehouseForReceipt, AnArrayOfOrders, False);
	
	AcceptedGoods = GetResultOfRequestForAcceptedProducts(SelectionData_, WarehouseForReceipt, AnArrayOfOrders).Unload();
	
	For Each String In AcceptedGoods Do
		DocumentInflow = String.PurchaseOrder;
		OrderOrder   = (TypeOf(DocumentInflow) = Type("DocumentRef.PurchaseOrder"));
		OrderOrder   = OrderOrder 
							  Or TypeOf(DocumentInflow) = Type("DocumentRef.MaterialProviderOrder2_5");
		If Not OrderOrder Then
			Break;
		EndIf;
	EndDo;
	
	TheStructureOfTheSearch = New Structure("Warehouse,Products,Characteristic,Purpose");
	
	If OrderOrder Then
		TheStructureOfTheSearch.Insert("PurchaseOrder");
	EndIf;
	
	IndexOfProductsRow = -1;
	While (IndexOfProductsRow+1) <= Goods.Count()-1 Do
		
		IndexOfProductsRow = IndexOfProductsRow + 1;
		LineProducts_ = Goods.Get(IndexOfProductsRow);
		
		CurLineProducts = LineProducts_;
		
		LineProducts_.PackagingQuantityInTheOrder = LineProducts_.QuantityInOrder / LineProducts_.ZoomRatio;
		
		FillPropertyValues(TheStructureOfTheSearch, LineProducts_);
		FoundRows = AcceptedGoods.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() = 0 Then
			Continue;
		EndIf;
		
		LineProductsQuantity = LineProducts_.Count;
		QuantityInProductLineHasChanged = False;
		For Each AcceptedString In FoundRows Do
			
			If AcceptedString.Count > 0 Then
				
				If AcceptedString.Count < LineProductsQuantity Then
					QuantityInProductLineHasChanged = True;
					LineProducts_.Count = AcceptedString.Count;
				Else
					LineProducts_.Count = LineProductsQuantity;
				EndIf;
				
				LineProducts_.QuantityInOrder = LineProductsQuantity;
				
				LineProducts_.NoteQuantity = LineProducts_.Count;
				LineProducts_.NumberOfPackages = LineProducts_.Count / LineProducts_.ZoomRatio;
				LineProducts_.PackagingQuantityInTheNote = LineProducts_.Count / LineProducts_.ZoomRatio;
				LineProducts_.PackagingQuantityInTheOrder = LineProducts_.QuantityInOrder / LineProducts_.ZoomRatio;
				
				LineProducts_.Series = AcceptedString.Series;
				LineProducts_.AdvancedWarehousingOnReceiving = AcceptedString.AdvancedWarehousingOnReceiving;
				LineProducts_.ItemsType = AcceptedString.ItemsType;
				
				AcceptedString.Count = AcceptedString.Count - LineProducts_.Count;
				LineProductsQuantity = LineProductsQuantity - LineProducts_.Count;
				
				If ByNote Then
					LineProducts_.Count = LineProducts_.NoteQuantity;
					LineProducts_.NumberOfPackages = LineProducts_.PackagingQuantityInTheNote;
				EndIf;
				
				If Not OrderOrder Or OrderOrder And QuantityInProductLineHasChanged Then
					PriceManagementSystem.RecalculateAmountsInRow(LineProducts_, False, False, True, PriceIncludesVAT);
				EndIf;
				
				If LineProductsQuantity > 0 And FoundRows.Find(AcceptedString) <> FoundRows.UBound() Then
					IndexOfProductsRow = IndexOfProductsRow + 1;
					LineProducts_ = Goods.Insert(IndexOfProductsRow);
					FillPropertyValues(LineProducts_, CurLineProducts);
				Else
					Break;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		For Each AcceptedProductLine In AcceptedGoods.FindRows(New Structure("Count",0)) Do
			AcceptedGoods.Delete(AcceptedProductLine);
		EndDo;
		
	EndDo;
	
	If AcceptedGoods.Count() > 0 Then
		
		ListOfProperties = "Products,Characteristic,Warehouse";
		AcceptableDeviations = PurchasesServer.PermissibleDeviationsOfMeasuredGoods(AnArrayOfOrders, OrderOrder);
		
		If OrderOrder Then 
			ListOfProperties = ListOfProperties + ",PurchaseOrder";
		EndIf;
		
		DeviationSearchStructure = New Structure(ListOfProperties);
		
		For Each AcceptedString In AcceptedGoods Do
			
			If AcceptedString.Count > 0 Then
				FillPropertyValues(DeviationSearchStructure, AcceptedString, ListOfProperties);
				
				ToleranceLines = AcceptableDeviations.FindRows(DeviationSearchStructure);
				ProductLines_2              = Goods.FindRows(DeviationSearchStructure);
				
				If ProductLines_2.Count() > 0 And ToleranceLines.Count() > 0 
					And ToleranceLines[0].AllowableVariance >= AcceptedString.Count Then
					LineProducts_ = ProductLines_2[0];
					LineProducts_.NoteQuantity = LineProducts_.NoteQuantity + AcceptedString.Count;
					LineProducts_.PackagingQuantityInTheNote = LineProducts_.NoteQuantity / LineProducts_.ZoomRatio;
				Else
					LineProducts_ = Goods.Add();
					FillPropertyValues(LineProducts_, AcceptedString);
					LineProducts_.NoteQuantity = AcceptedString.Count;
					LineProducts_.PackagingQuantityInTheNote = AcceptedString.Count;
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function GetResultOfRequestForAcceptedProducts(SelectionData_,WarehouseForReceipt = Undefined,AnArrayOfOrders = Undefined)
	
	Query = New Query;
	Query.SetParameter("InvoiceReference",         SelectionData_.Ref);
	Query.SetParameter("CurrentDate",             CurrentSessionDate());
	Query.SetParameter("Terms",              SelectionData_.Terms);
	Query.SetParameter("Contract",                 SelectionData_.Contract);
	Query.SetParameter("WarehouseForReceipt",        WarehouseForReceipt);
	Query.SetParameter("AnArrayOfOrders",           AnArrayOfOrders);
	Query.SetParameter("FillInByReceipts", SeparatePurchaseOperationIsUsed);
	
	Query.Text =
	"SELECT
	|	BalanceTable.DocumentInflow AS PurchaseOrder,
	|	BalanceTable.Warehouse,
	|	BalanceTable.Products,
	|	BalanceTable.Products.ItemsType AS ItemsType,
	|	BalanceTable.Characteristic,
	|	BalanceTable.Purpose,
	|	BalanceTable.Series,
	|	BalanceTable.AdvancedWarehousingOnReceiving,
	|	SUM(BalanceTable.ToRegisterBalance) AS Count
	|FROM
	|	(SELECT
	|		GoodsReadyForReceiptBalance.DocumentInflow AS DocumentInflow,
	|		GoodsReadyForReceiptBalance.Warehouse AS Warehouse,
	|		CASE
	|			WHEN GoodsReadyForReceiptBalance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt = TRUE
	|					AND GoodsReadyForReceiptBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS AdvancedWarehousingOnReceiving,
	|		GoodsReadyForReceiptBalance.Products AS Products,
	|		GoodsReadyForReceiptBalance.Characteristic AS Characteristic,
	|		GoodsReadyForReceiptBalance.Purpose AS Purpose,
	|		GoodsReadyForReceiptBalance.Series AS Series,
	|		CASE
	|			WHEN &FillInByReceipts = TRUE THEN
	|				-GoodsReadyForReceiptBalance.ToRegisterReceiptsByInvoicesBalance
	|			WHEN GoodsReadyForReceiptBalance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt = TRUE
	|					AND GoodsReadyForReceiptBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDate
	|				THEN GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance
	|			ELSE GoodsReadyForReceiptBalance.ToRegisterInvoicesByReferenceBalance
	|		END AS ToRegisterBalance
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Balance(
	|				,
	|				DocumentInflow IN (&AnArrayOfOrders)
	|					OR DocumentInflow = &Terms
	|					OR DocumentInflow = &Contract
	|					OR DocumentInflow = &InvoiceReference) AS GoodsReadyForReceiptBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsReadyForReceipt.DocumentInflow,
	|		GoodsReadyForReceipt.Warehouse,
	|		CASE
	|			WHEN GoodsReadyForReceipt.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt = TRUE
	|					AND GoodsReadyForReceipt.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS AdvancedWarehousingOnReceiving,
	|		GoodsReadyForReceipt.Products,
	|		GoodsReadyForReceipt.Characteristic,
	|		GoodsReadyForReceipt.Purpose,
	|		GoodsReadyForReceipt.Series,
	|		CASE
	|			WHEN &FillInByReceipts = TRUE THEN
	|				GoodsReadyForReceipt.ToRegisterReceiptsByInvoices
	|			WHEN GoodsReadyForReceipt.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt = TRUE
	|					AND GoodsReadyForReceipt.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDate
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceipts
	|			ELSE GoodsReadyForReceipt.ToRegisterInvoicesByReference
	|		END AS Count
	|	FROM
	|		AccumulationRegister.GoodsToReceive AS GoodsReadyForReceipt
	|	WHERE
	|		GoodsReadyForReceipt.Recorder = &InvoiceReference
	|		AND GoodsReadyForReceipt.Active) AS BalanceTable
	|
	|GROUP BY
	|	BalanceTable.DocumentInflow,
	|	BalanceTable.Warehouse,
	|	BalanceTable.AdvancedWarehousingOnReceiving,
	|	BalanceTable.Products,
	|	BalanceTable.Characteristic,
	|	BalanceTable.Purpose,
	|	BalanceTable.Series
	|
	|HAVING
	|	SUM(BalanceTable.ToRegisterBalance) > 0";
	
	SetPrivilegedMode(True);
	
	Return Query.Execute();
	
EndFunction

&AtServer
Procedure ReFillAmountMatched(WithFilling = False, InvoiceGoods = Undefined, SelectionData_ = Undefined)
	
	If WithFilling Then
		UpdateOrderInformation(InvoiceGoods);
		ByOrders = ?(OrderList.Count() > 0, OrderList.Count() > 0, ValueIsFilled(PurchaseOrder));
		
		SetSelectionByOrders();
		TheStructureOfTheSearch = New Structure("Products, Characteristic, RowCode, PurchaseOrder, Series, Warehouse");
		SearchStructureWithoutSeries = New Structure("Products, Characteristic, RowCode, PurchaseOrder, Warehouse");
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, PriceIncludesVAT);
	If SelectionData_ <> Undefined Then
		ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate();
		FillPropertyValues(ParametersForFillingInVATRate, SelectionData_);
		ParametersForFillingInVATRate.InitializingIncomingDocument = True;
		StructureOfActions.Insert("AdjustVATRate", ParametersForFillingInVATRate);
	EndIf;
	
	ArrayOfRowsToDelete_1 = New Array;
	
	CompositionOfExcludedFields = "Count, NumberOfPackages, Sum";
	If TypeOf(Ref) <> Type("DocumentRef.GoodsReceiptForStorage") Then
		CompositionOfExcludedFields = CompositionOfExcludedFields + ", AmountIncludingVAT, VATAmount";
	EndIf;
	
	If  UseDiscountAdjustmentsInSales 
		And WithFilling 
		And Not InvoiceGoods.Columns.Find("ManualDiscount") = Undefined Then
		CompositionOfExcludedFields = CompositionOfExcludedFields + ", ManualDiscount";
	EndIf;
	
	If WithFilling Then
		SpentLines = New Array();
		For Each CurRow In TableOfGoods Do
			FillPropertyValues(TheStructureOfTheSearch, CurRow);
			Rows = InvoiceGoods.FindRows(TheStructureOfTheSearch);
			If Rows.Count() > 0 Then
				ImplementationString = Rows.Get(0);
				FillPropertyValues(CurRow, ImplementationString,, CompositionOfExcludedFields);
				CurRow.QuantityInInvoice = ImplementationString.Count;
				CurRow.PackagingQuantityInInvoice = ImplementationString.NumberOfPackages;
				CurRow.ExistsInTheDocument = True;
				InvoiceGoods.Delete(ImplementationString);
				SpentLines.Add(CurRow);
			EndIf;
		EndDo;
		For Each CurRow In TableOfGoods Do
			If SpentLines.Find(CurRow) <> Undefined Then
				Continue;
			EndIf;
			
			FillPropertyValues(SearchStructureWithoutSeries, CurRow);
			Rows = InvoiceGoods.FindRows(SearchStructureWithoutSeries);
			If Rows.Count() > 0 Then
				ImplementationString = Rows.Get(0);
				FillPropertyValues(CurRow, ImplementationString,,"Count, NumberOfPackages");
				CurRow.QuantityInInvoice = ImplementationString.Count;
				CurRow.PackagingQuantityInInvoice = ImplementationString.NumberOfPackages;
				CurRow.ExistsInTheDocument = True;
				InvoiceGoods.Delete(ImplementationString);
			EndIf;
		EndDo;
	EndIf;
	
	RowsToProcess = New Array;
	
	For Each CurRow In TableOfGoods Do
		
		NumberOfPackagesBeforeChange = CurRow.NumberOfPackages;
		QuantityBeforeChange = CurRow.Count;
		CurRow.NumberOfPackages = ?(ByNote, CurRow.PackagingQuantityInTheNote, CurRow.PackagingQuantityInTheOrder);
		CurRow.Count = ?(ByNote, CurRow.NoteQuantity, CurRow.QuantityInOrder);
		If CurRow.NumberOfPackages <> NumberOfPackagesBeforeChange
			Or CurRow.Count <> QuantityBeforeChange Then
				RowsToProcess.Add(CurRow);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TableOfGoods);
	
	For Each CurRow In TableOfGoods Do
		If OrderList.FindByValue(CurRow.PurchaseOrder) <> Undefined 
			Or CurRow.PurchaseOrder = PurchaseOrder
			Or Not ValueIsFilled(CurRow.PurchaseOrder) Then
			
			CurRow.OrderFromInvoice = True;
			
		EndIf;
		
		CurRow.DiscrepancyInvoice = CurRow.NumberOfPackages - CurRow.PackagingQuantityInInvoice;
		If CurRow.DiscrepancyInvoice <> 0 
			And ((CurRow.OrderFromInvoice And ByOrders) Or Not ByOrders) Then
			CurRow.RowIsSelected = True;
		Else
			CurRow.RowIsSelected = False;
		EndIf;
		
		If WithFilling Then
			If (CurRow.PackagingQuantityInInvoice = CurRow.PackagingQuantityInTheOrder
					Or Not ValueIsFilled(CurRow.PurchaseOrder))
				And (CurRow.PackagingQuantityInInvoice = CurRow.PackagingQuantityInTheNote 
					Or (ValueIsFilled(CurRow.Warehouse) And Not CurRow.AdvancedWarehousingOnReceiving)) Then
					ArrayOfRowsToDelete_1.Add(TableOfGoods.IndexOf(CurRow));
			EndIf;
		EndIf;
	EndDo;
	
	IndexOfArrayElement = ArrayOfRowsToDelete_1.Count() - 1;
	While IndexOfArrayElement >= 0 Do
		TableOfGoods.Delete(ArrayOfRowsToDelete_1[IndexOfArrayElement]);
		IndexOfArrayElement = IndexOfArrayElement - 1;
	EndDo;
	
	If WithFilling Then
		For Each CurRow In InvoiceGoods Do
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
	
	UpdateTotalsByAmount();
	
EndProcedure

&AtServer
Procedure UpdateTotalsByAmount()
			
	SelectingSelectedRows = New Structure();
	SelectingSelectedRows.Insert("RowIsSelected",True);
	SelectedProductLines_ = TableOfGoods.FindRows(SelectingSelectedRows);
	AmountTotal = 0;
	VATAmount = 0;
	For Each RowOfProduct In SelectedProductLines_ Do
		AmountTotal = AmountTotal + RowOfProduct.AmountIncludingVAT;
		If ValueIsFilled(RowOfProduct.VATAmount) Then
			VATAmount = VATAmount + RowOfProduct.VATAmount;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure UpdateOrderInformation(InvoiceGoods)
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "PurchaseOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "GoodsTableGroupPurchaseOrder";
	ParametersOfUpdate.OrderNameInTablePart          = "PurchaseOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseReceiptForMultipleOrders;

	OrdersServer.UpdateOrderInformationInForm(ThisForm, InvoiceGoods, ParametersOfUpdate);
	
EndProcedure

&AtServer
Procedure SetSelectionByOrders()
	
	If ByOrders Then
		Items.TableOfGoods.RowFilter = New FixedStructure("OrderFromInvoice", True);
	Else
		Items.TableOfGoods.RowFilter = Undefined;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, PriceIncludesVAT)
	
	StructureOfRecalculationOfAmount =  New Structure("PriceIncludesVAT", PriceIncludesVAT);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
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
	
	If Not UseWarehouseManagemantSystemForGoodsReceipt And UsePurchaseOrders Then
		TitleFillIn = NStr("vi = 'Chọn hàng';
							|ru = 'Подбор товаров по заказам';
							|en = 'Pick goods by orders'; fa = 'Pick goods by orders';
							|it = 'Selezione delle merci per ordini';
							|pl = 'Wybór towarów wg zamówień';
							|tr = 'Siparişe göre ürünlerin seçimi'");
	ElsIf UseWarehouseManagemantSystemForGoodsReceipt And Not UsePurchaseOrders Then
		TitleFillIn = NStr("vi = 'Lựa chọn hàng hóa theo đơn đặt hàng';
							|ru = 'Подбор товаров по ордерам';
							|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
							|it = 'Selezione delle merci per mandati';
							|pl = 'Wybór towarów wg zleceń';
							|tr = 'Emire göre ürünlerin seçimi'");
	Else
		TitleFillIn = NStr("vi = 'Lựa chọn hàng hóa theo đơn đặt hàng / đơn hàng';
							|ru = 'Подбор товаров по заказам/ордерам';
							|en = 'Add items from Purchase order/Goods receipt'; fa = 'Add items from Purchase order/Goods receipt';
							|it = 'Selezione delle merci per ordini/mandati';
							|pl = 'Wybór towarów wg zamówień/zleceń wydania';
							|tr = 'Siparişe/emre göre ürünlerin seçimi'");
	EndIf;
	
	Title = TitleFillIn;
	
EndProcedure

&AtClient
Procedure MoveProductsToDocument()
	
	AnArrayOfOrders = New Array;
	ArrayOfARAPObjectsSettings = New Array;
	If OrderList.Count() > 0 
		And ValueIsFilled(ARAPObjectSettings)Then
		ArrayOfARAPObjectsSettings.Add(ARAPObjectSettings);
	EndIf;
	For Each RowOfProduct In TableOfGoods Do
		If RowOfProduct.RowIsSelected Then
			If ValueIsFilled(RowOfProduct.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(RowOfProduct.ARAPObjectSettings) = Undefined Then
				ArrayOfARAPObjectsSettings.Add(RowOfProduct.ARAPObjectSettings);
			EndIf;
			If ValueIsFilled(RowOfProduct.PurchaseOrder)
				And AnArrayOfOrders.Find(RowOfProduct.PurchaseOrder) = Undefined Then
				AnArrayOfOrders.Add(RowOfProduct.PurchaseOrder);
			EndIf;
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
	
	If UsePurchaseOrders
		And Not UseReceiptForMultipleOrders
		And AnArrayOfOrders.Count() > 1 Then
		
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Bạn không thể chọn hàng hóa cho nhiều hơn một đơn hàng.';
										|ru = 'Нельзя выбрать товары больше, чем по одному заказу.';
										|en = 'You cannot select more goods than against one order.'; fa = 'You cannot select more goods than against one order.';
										|it = 'Нельзя выбрать товары больше, чем по одному заказу.';
										|pl = 'Nie można wybrać towarów dla więcej niż jednego zamówienia.';
										|tr = 'Bir siparişten fazla ürün seçemezsiniz.'"));
														
		Return;
	EndIf;
	
	// Removal of modification, because before closing, the attribute is checked.
	Modified = False;

	Close();

	NotifyChoice(New Structure("GoodsAddressInStorage", PutProductsInStorage()));

EndProcedure

&AtClient
Procedure RecalculateTotalAmount()
	
	SelectingSelectedRows = New Structure();
	SelectingSelectedRows.Insert("RowIsSelected",True);
	SelectedProductLines_ = TableOfGoods.FindRows(SelectingSelectedRows);
	AmountTotal = 0;
	VATAmount = 0;
	For Each RowOfProduct In SelectedProductLines_ Do
		AmountTotal = AmountTotal + RowOfProduct.AmountIncludingVAT;
		If ValueIsFilled(RowOfProduct.VATAmount) Then
			VATAmount = VATAmount + RowOfProduct.VATAmount;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
