#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.OBEntryGoods - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	If BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5 Then
		
		If Not ValueIsFilled(OrderDocument)
			And Not OrderDocument = Undefined Then
			OrderDocument = Undefined;
		EndIf;
		
		If ValueIsFilled(OrderDocument) Then
			OrderAssignment = Common.ObjectAttributeValue(OrderDocument, "Purpose");
			For Each CurRow In Goods Do
				CurRow.Purpose = OrderAssignment;
			EndDo;
		EndIf;
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		  Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		  Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		
		AttributeNamePurpose = "Purpose";
		
		If ValueIsFilled(OrderDocument) Then
			
			SourceDestination = OrderDocument;
			
			If BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting Then
				AttributeNamePurpose = "AssignmentMaterials";
			EndIf;
			
		Else
			
			SourceDestination = Contract;
			
			If OrderDocument <> Undefined Then
				OrderDocument = Undefined;
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(SourceDestination) Then
			Purpose = GeneralPurposeTMServerCall.ObjectAttributeValue(SourceDestination, AttributeNamePurpose);
		Else
			Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		
		If Goods.Count() > Goods.FindRows(New Structure("Purpose", Purpose)).Count() Then
			
			For Each StringTSGoods In Goods Do
				StringTSGoods.Purpose = Purpose;
			EndDo;
			
		EndIf;
	EndIf;
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned Then
		ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory Then
		Organization = Catalogs.Companies.ManagementCompany;
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors Then
		
		For Each CurRow In Goods Do
			CurRow.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
		EndDo;
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI Then
		
		For Each CurRow In Goods Do
			CurRow.VATRate = Catalogs.VATRates.EmptyRef();
		EndDo;
		
	EndIf;
		
	If WriteMode = DocumentWriteMode.Posting Then
		
		ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
		
		If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryGoodsCostVariances
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods Then
			
			FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
			
			If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
				Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
				Or BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods Then
				
				If Not BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI Then
					FieldsNames.Purpose = "";
				EndIf;
				FieldsNames.Insert("Arbitrary", "");
				PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(Enums.StorageLocationTypes.CounterpartyContract,
																								Contract,
																								Department,
																								Partner,
																								Contract);
			Else
				PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation, Warehouse, Department, Partner, Contract);
			EndIf;
			
			InformationRegisters.ItemsLocationAttributes.FillInCollection(Goods, PlacesOfAccounting, FieldsNames);
			FillStockTypes();
			
			If Not ToUseTermsOfSales Then
				DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
					Partner,
					New Structure("ExcludeWarehouseGroupsAvailableInOrders, SelectedAgreement, BusinessTransactions",
						True,
						TermsOfConsignmentSales,
						Enums.BusinessTransactions.TransferToCommissionAgent));
				
				If DefaultSalesTerms <> Undefined Then
					TermsOfConsignmentSales = DefaultSalesTerms.Terms;
				Else
					TermsOfConsignmentSales = Undefined;
				EndIf;
			EndIf;
			
		EndIf;
		
		
		If BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5 Then
			PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation, Warehouse, Department, Partner, Contract);
			InformationRegisters.ItemsLocationAttributes.FillInCollection(Goods, PlacesOfAccounting);
			FillStockTypes();
		EndIf;
		If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned Then
			PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation, Warehouse, Department, Partner);
			PlacesOfAccounting.Arbitrary = Department;
			InformationRegisters.ItemsLocationAttributes.FillInCollection(Goods, PlacesOfAccounting);
			FillStockTypes();
		EndIf;
		If BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		 Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		 Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
			PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation, Warehouse, Department, Partner);
			InformationRegisters.ItemsLocationAttributes.FillInCollection(Goods, PlacesOfAccounting);
			FillStockTypes();
		EndIf;
	EndIf;
	
		ProductsServer.ClearUnusedSeries(ThisObject,ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.OBEntryGoods));
	
	ClearUnusedCCDNumbers();
	
	// Reflection of balances in the "VAT Accounting" subsystem
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse Then
		RegistrationParameters = Documents.OBEntryGoods.InitializeParametersForRegisteringInvoicesReceived(ThisObject);
		VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		And BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
		And BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned
		And BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5
		And BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		And BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse Then
		
		DeleteIrrelevantLinesDetailingBatches();
		
	EndIf;
	
	DeleteIrrelevantLinesDetailingBatches();
	
	If BusinessOperation =
		Enums.BusinessTransactions.OBEntryShippedGoods Then
		OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Goods");
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryGoods.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TMCommonUse.FillInDocumentIDs(	ThisObject, "Goods");
	
	OBEntryLocalization.OBEntryGoodsBeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse Then
		RegistrationParameters = Documents.OBEntryGoods.InitializeParametersForRegisteringInvoicesReceived(ThisObject);
		VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	EndIf;
	
	OBEntryLocalization.InputOfGoodsBalancesProcessingOfGoods(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse Then
		RegistrationParameters = Documents.OBEntryGoods.InitializeParametersForRegisteringInvoicesReceived(ThisObject);
		VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not RecordInOperationalAccounting 
		And Not PostInCostAccounting
		And Not PostInFinancialAndTaxAccounting
		And Not RecordInMA Then
		
		MessageText = NStr("vi = 'Giao dịch cần được phản ánh vào một trong các dạng kế toán';
							|ru = 'Операция должна отражаться в одном из учетов';
							|en = 'The operation must be recorded in one of accounting types'; fa = 'The operation must be recorded in one of accounting types';
							|it = 'L''operazione deve essere riportata in uno dei tipi della contabilità';
							|pl = 'Operacja powinna być odzwierciedlana w jednej z ewidencji';
							|tr = 'İşlemin hesaplardan birine yansıtılması gerekir'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
		
	EndIf;
	
	CheckedAttributes.Add("Manager");
	CheckedAttributes.Add("Department");
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, Date);
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	NotCheckedAttributeArray = New Array;
	
	Invoices_ = VATAccountingERP.InvoicesReceivedOnLegalGrounds(Ref);
	If Invoices_.Count() = 0
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingReceivedVMI
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryShippedGoods
		And BusinessOperation <> Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5
		And True Then
		NotCheckedAttributeArray.Add("Counterparty");
	EndIf;
	
	AccountingPolicyParameters = Undefined;
	If (RecordInOperationalAccounting Or PostInCostAccounting)
		And (BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse 
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI 
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		
		Or BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryGoodsCostVariances
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI) Then
		
		AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"FinancialAccountingPolicy",
			Organization, 
			BegOfMonth(Date));
		
		If (AccountingPolicyParameters = Undefined
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryGoodsCostVariances
			Or(AccountingPolicyParameters <> Undefined
			And AccountingPolicyParameters.InventoryValuationMethod <> Enums.InventoryValuationMethods.FIFORollingValuation))
			And (VATTaxation <> Enums.VATTaxationTypes.ByActualUsage
				Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
				Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
				Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
				Or False) Then
			NotCheckedAttributeArray.Add("Lot");
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.OBEntryGoodsCostVariances
		 And (AccountingPolicyParameters <> Undefined And Not AccountingPolicyParameters.ItemizeVariancesByBusinessUnits) Then
			NotCheckedAttributeArray.Add("Department");
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.OBEntryGoodsCostVariances
			And AccountingPolicyParameters.InventoryValuationMethod <> Enums.InventoryValuationMethods.MovingAverage Then
			
			MessageText = NStr("vi = 'Đối với thao tác ""%1"" cho phép chỉ ra chỉ doanh nghiệp,
			|mà sử dụng đánh giá giá trị hàng hóa ""%2""';
			|ru = 'Для операции ""%1"" допустимо указывать только организации,
			|использующие оценку стоимости товаров ""%2""';
			|en = 'For the %1 transaction, you can only specify companies
			|using the %2 inventory valuation method'; fa = 'For the %1 transaction, you can only specify companies
			|using the %2 inventory valuation method';
			|it = 'For the %1 transaction, you can only specify companies
			|using the %2 inventory valuation method';
			|pl = 'For the %1 transaction, you can only specify companies
			|using the %2 inventory valuation method';
			|tr = '""%1"" işlemi için, sadece ürün maliyeti,
			| ""%2"" olan iş yerleri belirtilebilir'");
			MessageText = StrTemplate(MessageText, Enums.BusinessTransactions.OBEntryGoodsCostVariances, Enums.InventoryValuationMethods.MovingAverage);
			
			Common.MessageToUser(MessageText,,,,Cancel);
			
		EndIf;
		
	Else
		NotCheckedAttributeArray.Add("Lot");
	EndIf;
	
	If (BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
			Or False)
		And UseBinLocationWarehousing
		And Not GetFunctionalOption("UseItemPackages") Then
		
		NotCheckedAttributeArray.Add("Goods.Package");
		
		MessageText = NStr("vi = 'Trong tùy chỉnh chương trình chưa bật sử dụng đóng gói mặt hàng, 
			|do đó không thể lập chứng từ theo kho (nhà kho) có cất giữ số dư theo địa chỉ. Hãy liên hệ với người quản trị';
			|ru = 'В настройках программы не включено использование упаковок номенклатуры, 
			|поэтому нельзя оформить документ по складу (помещению) с адресным хранением остатков. Обратитесь к администратору';
			|en = 'Packaging options are disabled in the application settings. To create a document that uses bin locations, you need to enable packaging options.
			|Please contact the administrator'; fa = 'Packaging options are disabled in the application settings. To create a document that uses bin locations, you need to enable packaging options.
			|Please contact the administrator';
			|it = 'Le impostazioni del programma non includono l''uso di imballaggio di articoli, 
			|pertanto è impossibile formalizzare il documento per un magazzino (locale) con il sistema di stoccaggio delle rimanenze codificato. Contattare amministratore';
			|pl = 'W ustawieniach programu nie włączono używanie opakowań produktów, 
			|dlatego niemożna sporządzić dokument według magazynu (pomieszczenia) z przechowywaniem adresowym ostatków. Zwróć się do administratora';
			|tr = 'Uygulama ayarlarında ürün paketleme ünitelerinin kullanımı etkin değildir,
			|bu nedenle depo konum takibi olan bir ambar (alan) için belge düzenleyemezsiniz. Yönetici ile iletişime geçin'");
		
		Common.MessageToUser(MessageText,,,,Cancel);
		
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryShippedGoods
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingReceivedVMI
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryGoodsCostVariances
	Then
		NotCheckedAttributeArray.Add("Warehouse");
	EndIf;

	If BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingReceivedVMI
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		Or Not WarehousesServer.UseWarerooms(Warehouse,Date)
		Or Not RecordInOperationalAccounting Then
		
		NotCheckedAttributeArray.Add("Premise");
	
	EndIf;

	If ((BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse 
				Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
				Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
				Or BusinessOperation <> Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
				Or BusinessOperation <> Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
				Or BusinessOperation <> Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
				Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors)
			And UseBinLocationWarehousing
			And RecordInOperationalAccounting)
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory Then
		ProductsServer.CheckFillingOfPackages(ThisObject, NotCheckedAttributeArray, Cancel);
	Else
		NotCheckedAttributeArray.Add("ReceivingArea");
		NotCheckedAttributeArray.Add("Goods.Package");
		NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods.Package");
		NotCheckedAttributeArray.Add("RetailSales.Package");
	EndIf;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned Then
		CheckParameters.CheckPossibilityOfRounding = False;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryGoodsCostVariances Then
		NotCheckedAttributeArray.Add("Goods.Count");
		NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
	Else
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory Then
		NotCheckedAttributeArray.Add("Organization");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory Then
		NotCheckedAttributeArray.Add("Goods.Price");
		NotCheckedAttributeArray.Add("Goods.Sum");
		NotCheckedAttributeArray.Add("Goods.SumCompl");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors Then
		
		For RowIndex = 0 To Goods.Count()-1 Do
			If Goods[RowIndex].DepositForPackageIsRequired Then
			
				If Not ValueIsFilled(Goods[RowIndex].Price) Then
					ErrorText = NStr("vi = 'Chưa điền cột ""Đơn giá"" tại dòng %LineNumber% của phần bảng ""Hàng hóa""';
									|ru = 'Не заполнена колонка ""Цена"" в строке %LineNumber% табличной части ""Товары""';
									|en = 'Column ""Price"" in line %LineNumber% of table ""Goods"" is not filled in'; fa = 'Column ""Price"" in line %LineNumber% of table ""Goods"" is not filled in';
									|it = 'La colonna ""Prezzo"" non è compilata nella riga %LineNumber% della parte tabulare ""Merci""';
									|pl = 'Nie wypełniono kolumny ""Цена"" w wierszu %LineNumber% części tabelarycznej ""Товары""';
									|tr = '""Ürünler"" tablo bölümünün %LineNumber% satırındaki ""Fiyat"" sütunu doldurulmadı'");
					ErrorText =  StrReplace(ErrorText, "%LineNumber%", Goods.Get(RowIndex).LineNumber);
					Common.MessageToUser(
						ErrorText,
						ThisObject,
						CommonClientServer.PathToTabularSection("Goods", Goods.Get(RowIndex).LineNumber, "Price"),
						,
						Cancel);
				EndIf;
			
				If Not ValueIsFilled(Goods[RowIndex].Sum) Then
					ErrorText = NStr("vi = 'Chưa điền cột ""Số tiền"" tại dòng %LineNumber% của phần bảng ""Hàng hóa""';
									|ru = 'Не заполнена колонка ""Сумма"" в строке %LineNumber% табличной части ""Товары""';
									|en = 'Column ""Amount"" in line %LineNumber% of table ""Goods"" is not filled in'; fa = 'Column ""Amount"" in line %LineNumber% of table ""Goods"" is not filled in';
									|it = 'La colonna ""Totale"" non è compilata nella riga %LineNumber% della parte tabulare ""Merci""';
									|pl = 'Nie wypełniono kolumny ""Сумма"" w wierszu %LineNumber% części tabelarycznej ""Товары""';
									|tr = '""Ürünler"" tablo bölümünün %LineNumber% satırındaki ""Tutar"" sütunu doldurulmadı'");
					ErrorText =  StrReplace(ErrorText, "%LineNumber%", Goods.Get(RowIndex).LineNumber);
					Common.MessageToUser(
						ErrorText,
						ThisObject,
						CommonClientServer.PathToTabularSection("Goods", Goods.Get(RowIndex).LineNumber, "Sum"),
						,
						Cancel);
				EndIf;
			
				If Not ValueIsFilled(Goods[RowIndex].SumCompl) Then
					ErrorText = NStr("vi = 'Chưa điền cột ""Số tiền (quy định)"" tại dòng %LineNumber% của phần bảng ""Hàng hóa""';
									|ru = 'Не заполнена колонка ""Сумма(регл)"" в строке %LineNumber% табличной части ""Товары""';
									|en = 'Column ""Amount (local)"" in line %LineNumber% of table ""Goods"" is not filled in'; fa = 'Column ""Amount (local)"" in line %LineNumber% of table ""Goods"" is not filled in';
									|it = 'La colonna ""Totale (regolamentato)"" non è compilata nella riga %LineNumber% della parte tabulare ""Merci""';
									|pl = 'Nie wypełniono kolumny ""Сумма(регл)"" w wierszu %LineNumber% części tabelarycznej ""Товары""';
									|tr = '""Ürünler"" tablo bölümünün %LineNumber% satırındaki ""Tutar(yerel muhasebe)"" sütunu doldurulmadı'");
					ErrorText =  StrReplace(ErrorText, "%LineNumber%", Goods.Get(RowIndex).LineNumber);
					Common.MessageToUser(
						ErrorText,
						ThisObject,
						CommonClientServer.PathToTabularSection("Goods", Goods.Get(RowIndex).LineNumber, "SumCompl"),
						,
						Cancel);
				EndIf;
				
			EndIf;
		EndDo;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods Then
		
		If Not ValueIsFilled(Lot) Then
			
			NotCheckedAttributeArray.Add("Lot");
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Ngày giao hàng""';
							|ru = 'Поле ""Документ отгрузки"" не заполнено';
							|en = '""Shipping document"" is not filled in'; fa = '""Shipping document"" is not filled in';
							|it = '""Shipping document"" is not filled in';
							|pl = '""Shipping document"" is not filled in';
							|tr = '""Sevkiyat belgesi"" alanı doldurulmamış'");
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,,
				"Object.Lot",
				Cancel);
			
		EndIf;
		
	EndIf;
	
	If (Not RecordInOperationalAccounting And Not PostInCostAccounting)
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
		Or BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned Then
		NotCheckedAttributeArray.Add("Goods.VATRate");
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingReceivedVMI
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
		And BusinessOperation <> Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5 Then
		NotCheckedAttributeArray.Add("Partner");
	EndIf;
	
	ContractMustBeCompleted = Documents.OBEntryGoods.ContractMustBeCompleted(ThisObject);
	If Not ContractMustBeCompleted Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	If (Not RecordInOperationalAccounting And Not PostInCostAccounting)
		Or (BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingReceivedVMI
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors) Then
		NotCheckedAttributeArray.Add("Currency");
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryShippedGoods Then
		NotCheckedAttributeArray.Add("VATTaxation");
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned
		And (BusinessOperation <> Enums.BusinessTransactions.OBEntryGoodsCostVariances
		Or AccountingPolicyParameters <> Undefined And Not AccountingPolicyParameters.ItemizeVariancesByLinesOfBusiness)
	Then
		NotCheckedAttributeArray.Add("VATActivityType");
	EndIf;
	
	If (BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5)
		Or (BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
			And Not ToUseTermsOfSales)
		Or (Not RecordInOperationalAccounting And Not PostInCostAccounting) Then
		NotCheckedAttributeArray.Add("TermsOfConsignmentSales");
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
		Or Not ToUseTermsOfSales Then
		NotCheckedAttributeArray.Add("CustomerTermsOfSales");
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned
		And BusinessOperation <> Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		And (BusinessOperation <> Enums.BusinessTransactions.OBEntryGoodsCostVariances
		Or AccountingPolicyParameters <> Undefined And Not AccountingPolicyParameters.ItemizeVariancesByBusinessUnits)
	Then
		NotCheckedAttributeArray.Add("Department");
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
		ProductsServer.CheckSeriesCompletion(
			ThisObject,
			ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.OBEntryGoods),
			Cancel,
			NotCheckedAttributeArray);
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date)
		And (BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
			Or BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned);
	
	If GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers")
		And Goods.Count() > 0
		And (BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods
			Or BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI)
		Or ThisIsTraceableDocument Then
		CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
		CheckParameters.CheckWorks = BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned;
		CheckParameters.CheckItemsAndContainers = BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned;
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel, CheckParameters);
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse 
		Or Not DivisionMaintainsSeparateAccountingForManagers(Department) Then
		NotCheckedAttributeArray.Add("Manager");
	EndIf;
	If Not SubjectToExcise Then
		NotCheckedAttributeArray.Add("BusinessUnitProduction");
	Else
		ControlParameters = ExcisableGoodsAccounting.ControlParametersForFillingExcisableItems();
		ControlParameters.ErrorTextTemplate =
			NStr("vi = 'Cấm nhập số dư hàng hóa chịu thuế TTĐB ""%Products%"" đã chỉ định trong dòng %LineNumber% danh sách ""%TabularSectionPresentation%"" trong kho bán lẻ ""%Warehouse%""';
				|ru = 'Запрещен ввод остатков подакцизного товара ""%Products%"", указанного в строке %LineNumber% списка ""%TabularSectionPresentation%"" на розничный склад ""%Warehouse%""';
				|en = 'Cannot enter the balance of the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list in the ""%Warehouse%"" retail warehouse'; fa = 'Cannot enter the balance of the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list in the ""%Warehouse%"" retail warehouse';
				|it = 'Cannot enter the balance of the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list in the ""%Warehouse%"" retail warehouse';
				|pl = 'Cannot enter the balance of the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list in the ""%Warehouse%"" retail warehouse';
				|tr = '""%TabularSectionPresentation%"" listesinin %LineNumber% satırında belirtilen tüketim vergisine tabi ""%Products%"" ürün stoklarının ""%Warehouse%"" perakende ambarına girişi yasaktır'");
		ControlParameters.CheckingWarehouse = True;
		ExcisableGoodsAccounting.ControlOfFillingExcisableItems(ThisObject, ControlParameters, Cancel);
	EndIf;
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryGoods.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	If NotCheckedAttributeArray.Find("Partner") = Undefined And Partner.IsEmpty() Then
		
		NotCheckedAttributeArray.Add("Partner");
		
		TitlePartner = Documents.OBEntryGoods.HeaderOfPartnerDetailsDependingOnBusinessOperation(
			BusinessOperation);
		ErrorText = CommonClientServer.FillingErrorText(, , TitlePartner);
		
		Common.MessageToUser(ErrorText, ThisObject, "Partner", , Cancel);
		
	EndIf;
	
	If ValueIsFilled(Lot) Then
		
		SourceDocumentDate = Common.ObjectAttributeValue(Lot, "Date");
		SourceDocumentDate = ?(ValueIsFilled(SourceDocumentDate), SourceDocumentDate, '00010101');
		
		If SourceDocumentDate > Date Then
			
			If BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods Then
				NameOfPrimaryDocument = NStr("ru = 'документа отгрузки';
											|vi = 'shipping document';
											|en = 'shipping document'; fa = 'shipping document';
											|it = 'shipping document';
											|pl = 'shipping document';
											|tr = 'Sevkiyat belgesi'");
			Else
				NameOfPrimaryDocument = NStr("ru = 'партии';
											|vi = 'lots';
											|en = 'lots'; fa = 'lots';
											|it = 'lots';
											|pl = 'lots';
											|tr = 'lotlar'");
			EndIf;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Дата %1 не должна быть больше даты ввода остатков';
					|vi = 'Date %1 cannot be later than the balance entry date';
					|en = 'Date %1 cannot be later than the balance entry date'; fa = 'Date %1 cannot be later than the balance entry date';
					|it = 'Date %1 cannot be later than the balance entry date';
					|pl = 'Date %1 cannot be later than the balance entry date';
					|tr = '%1Tarih, bakiye giriş tarihinden büyük olmalıdır.'"),
				NameOfPrimaryDocument);
			
			Common.MessageToUser(MessageText,, "Object.Lot",, Cancel);
			
		EndIf;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	OBEntryLocalization.EnteringProductBalancesProcessingFillChecks(ThisObject, Cancel, CheckedAttributes);
	
	OBEntryServer.CheckCompletionOfPrimaryDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	InitializeDocument(FillingData);
	
	If Documents.ReconcileOpeningBalancesByWarehouses.FillInBalanceOfGoodsBasedOnReconciliation(ThisObject, FillingData) Then
		StandardProcessing = False;
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	OBEntryLocalization.EnteringProductBalancesProcessingFilling(ThisObject, FillingData, StandardProcessing);
	
	FillParameters = Documents.OBEntryGoods.InitializeParametersForVATActivities(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI Then
		FillParameters = Documents.OBEntryGoods.InitializeVATTaxationParameters(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryGoods.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	SetOfSeries.Clear();
	
	For Each TSRow In Goods Do
		TSRow.InventoryOwnerAttribute = Undefined;
	EndDo;
	
	If (BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5)
		And (ValueIsFilled(TermsOfConsignmentSales) Or ValueIsFilled(Contract)) Then
		EnteringBalancesForNewCommission = (BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5);
		If ValueIsFilled(TermsOfConsignmentSales) Then
			AgreementOnNewCommission = Common.ObjectAttributeValue(TermsOfConsignmentSales, "ConsignmentSales25");
			If AgreementOnNewCommission <> EnteringBalancesForNewCommission Then
				TermsOfConsignmentSales = Catalogs.TermsOfSale.EmptyRef();
			EndIf;
		EndIf;
		If ValueIsFilled(Contract) Then
			NewCommissionAgreement = Common.ObjectAttributeValue(Contract, "ConsignmentSales25");
			If NewCommissionAgreement <> EnteringBalancesForNewCommission Then
				Contract = Catalogs.CounterpartyContracts.EmptyRef();
			EndIf;
		EndIf;
	EndIf;

	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5 Then
		FillParameters = Documents.OBEntryGoods.InitializeVATTaxationParameters(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	EndIf;
	
	LocalAccountingCurrency            = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	ManagementAccountingCurrency                = Constants.ManagementAccountingCurrency.Get();
	FactorOfConversionFromManCurrencyToRegulCurrency      = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
														ManagementAccountingCurrency,
														LocalAccountingCurrency,
														?(Date = Date(1,1,1), CurrentSessionDate(), Date));
	If Not BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
	   And Not BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
		
		StructureOfActions = New Structure;
		If BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider Then
			StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
			BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
		Else
			StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
			StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;
			
			StructureOfActions = New Structure;
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
			BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
			
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
			StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				CachedValues.ProcessedRows,
				StructureOfActions,
				Goods,
				Undefined);
			
			StructureOfActions = New Structure;
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
			BatchProcessingOfTablePartServer.TreatTS(LotDetails, StructureOfActions, CachedValues);
			
			For Each String In CachedValues.ProcessedRows Do
				String.VATLocal = PriceManagementSystemClientServer.CalculateVATAmount(String.SumCompl, String.VATRate, False);
				String.VATManag = PriceManagementSystemClientServer.CalculateVATAmount(String.SumMan, String.VATRate, False);
			EndDo;
		EndIf;
	
	EndIf;
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												ThisObject);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Goods);
		
	EndIf;
	
	Author = Users.CurrentUser();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods");
	GenerateVATCharged = False;
	
	OBEntryLocalization.EnteringProductBalancesWhenCopying(ThisObject, CopiedObject);
	
EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	OBEntryLocalization.EnteringProductBalancesWhenRecording(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If ValueIsFilled(Organization) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Else
		Currency = SettingsValueCached.ManagementAccountingCurrency();
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("BusinessOperation") Then
			BusinessOperation = FillingData.BusinessOperation;
		EndIf;
		
		If FillingData.Property("Comment") Then
			Comment = FillingData.Comment;
		EndIf;
		
		If FillingData.Property("CopyingValue") Then
			OBEntryServer.FillInValuesForOldInputBalances(ThisObject, FillingData.CopyingValue);
			SetOfSeries.Clear();
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
		
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
		
	EndIf;
	If Not BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting Then
		FillParameters = Documents.OBEntryGoods.InitializeParametersForVATActivities(ThisObject);
		VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
		
		FillParameters = Documents.RequestForReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	EndIf;
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers Then
		VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	EndIf;
	
	LocalAccountingCurrency            = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	ManagementAccountingCurrency                = Constants.ManagementAccountingCurrency.Get();
	FactorOfConversionFromManCurrencyToRegulCurrency      = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
														ManagementAccountingCurrency,
														LocalAccountingCurrency,
														?(Date = Date(1,1,1), CurrentSessionDate(), Date));
														
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	If BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateLocalAmount",   FactorOfConversionFromManCurrencyToRegulCurrency);
		
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
		
	ElsIf Not BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
			And Not BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
	EndIf;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountMAN", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATMan", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(LotDetails, StructureOfActions, Undefined);
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes()

	QueryTexts = New Array;
	
	PartOfTheRequestText =
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfGoods.ProductsGroup AS ProductsGroup
	|INTO TableOfGoodsVrem
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|INDEX BY
	|	Products
	|";
	QueryTexts.Add(PartOfTheRequestText);
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.ProductTableName_ = "TableOfGoodsVrem";
	
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters));
	PartOfTheRequestText = 
	"SELECT
	|	T.LineNumber,
	|	T.Products,
	|	T.InventoryOwnerAttribute,
	|	T.ProductsGroup
	|INTO TableOfGoods
	|FROM
	|	TableOfGoodsVrem AS T
	|
	|	INNER JOIN Catalog.Products AS CatProducts
	|	ON T.Products = CatProducts.Ref
	|		AND CASE
	|			WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods),
	|				VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods))
	|			THEN
	|				CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|				OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			ELSE TRUE
	|			END
	|		LEFT JOIN Document.OBEntryGoods AS SavedData
	|		ON SavedData.Ref = &Ref
	|WHERE
	|	T.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|	OR &RefillInventoryKinds
	|	OR SavedData.Ref IS NULL
	|	OR SavedData.Organization <> &Organization
	|	OR NOT &Posted
	|	OR SavedData.Date <> &Date
	|	OR SavedData.SubjectToExcise <> &SubjectToExcise
	|	OR SavedData.BusinessUnitProduction <> &BusinessUnitProduction
	|;
	|
	|////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	CASE WHEN &UseSeparateAccountingByTaxation AND NOT &BatchAccountingVersion22 THEN
	|		&VATActivityType
	|	ELSE
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END AS VATTaxation,
	|	UNDEFINED AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse)
	|			THEN &SubjectToExcise
	|		ELSE FALSE
	|	END AS SubjectToExcise,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse)
	|			THEN &BusinessUnitProduction
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON TableOfGoods.Products = Category_Data.Products
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|
	|	UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	CASE WHEN &UseSeparateAccountingByTaxation AND NOT &BatchAccountingVersion22 THEN
	|		&VATTaxation
	|	ELSE
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END AS VATTaxation,
	|	VALUE(Catalog.Partners.EmptyRef) AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers))
	|
	|	UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Catalog.Partners.EmptyRef) AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5)
	|
	|	UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	&Terms AS Terms,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Catalog.Partners.EmptyRef) AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI)
	|
	|	UNION ALL
	|
	|	SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.ConsignmentProcurement) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.ConsignedGoods) AS InventoryType,
	|	&Terms AS Terms,
	|	&Currency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	&Partner AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|
	|	UNION ALL
	|
	|	SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell) AS InventoryType,
	|	&Terms AS Terms,
	|	&Currency AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&Partner AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|
	|	UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN TRUE
	|			THEN VALUE(Enum.BusinessTransactions.TransferToToller2_5)
	|	END AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	&Terms AS Terms,
	|	&Currency AS Currency,
	|	CASE WHEN &UseSeparateAccountingByTaxation AND NOT &BatchAccountingVersion22 THEN
	|		&VATActivityType
	|	ELSE
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END AS VATTaxation,
	|	UNDEFINED AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5))
	|
	|	UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.TransferToProduction) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	&Terms AS Terms,
	|	&Currency AS Currency,
	|	CASE WHEN &UseSeparateAccountingByTaxation AND NOT &BatchAccountingVersion22 THEN
	|		&VATActivityType
	|	ELSE
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END AS VATTaxation,
	|	UNDEFINED AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|	AND CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|	
	|	UNION ALL
	|	
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.TransferToProduction) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.Work_5) AS InventoryType,
	|	&Terms AS Terms,
	|	&Currency AS Currency,
	|	CASE WHEN &UseSeparateAccountingByTaxation AND NOT &BatchAccountingVersion22 THEN
	|		&VATActivityType
	|	ELSE
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END AS VATTaxation,
	|	UNDEFINED AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|
	|	UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	&Terms AS Terms,
	|	&Currency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	UNDEFINED AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods)
	|
	|	UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	&Terms AS Terms,
	|	&Currency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	UNDEFINED AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods)
	|
	|	UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	CASE WHEN &UseSeparateAccountingByTaxation AND NOT &BatchAccountingVersion22 THEN
	|		&VATActivityType
	|	ELSE
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END AS VATTaxation,
	|	UNDEFINED AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS SubjectToExcise,
	|	UNDEFINED AS BusinessUnitProduction,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation =
	|		VALUE(Enum.BusinessTransactions.OBEntryShippedGoods)
	|
	|
	|	UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber                                            AS LineNumber,
	|	TableOfGoods.Products                                           AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END                                                                 AS CurViewOfStocks,
	|	FALSE                                                                  AS ThisIsReusablePackage,
	|	UNDEFINED                                                          AS ProductsGroup,
	|	UNDEFINED                                                          AS PriceKind,
	|	&Organization                                                          AS Organization,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			THEN VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
	|		ELSE VALUE(Enum.BusinessTransactions.TollManufacturing2_5)
	|	END                                                                 AS BusinessOperation,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			THEN VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|			THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|			THEN VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|	END                                                                 AS InventoryType,
	|	&Terms                                                           AS Terms,
	|	&Currency                                                               AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)            AS VATTaxation,
	|	&Partner                                                              AS GoodsOwner,
	|	&Counterparty                                                           AS Counterparty,
	|	&Contract                                                              AS Contract,
	|	&TaxationOfOrganization                                           AS TaxationOfOrganization,
	|	FALSE                                                                  AS SubjectToExcise,
	|	UNDEFINED                                                          AS BusinessUnitProduction,
	|	FALSE                                                                  AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|			VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|			VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider))
	|;
	|////////////////////////////////////////////////////////////////
	|DROP TableOfGoodsVrem
	|;
	|////////////////////////////////////////////////////////////////
	|DROP TableOfGoods";
	
	QueryTexts.Add(PartOfTheRequestText);
	
	TempTablesManager = New TempTablesManager;

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	TableOfGoods = Goods.Unload(, "LineNumber, Products, InventoryOwnerAttribute, ProductsGroup");
	
	Query.SetParameter("TableOfGoods",        TableOfGoods);
	Query.SetParameter("Organization",           Organization);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Partner",               Partner);
	Query.SetParameter("Counterparty",            Counterparty);
	Query.SetParameter("Department",         Department);
	Query.SetParameter("Manager",              Manager);
	Query.SetParameter("Contract",               Contract);
	Query.SetParameter("Currency",                Currency);
	Query.SetParameter("Posted",              Posted);
	Query.SetParameter("VATTaxation",    VATTaxation);
	Query.SetParameter("VATActivityType",    VATActivityType);
	Query.SetParameter("Terms",            TermsOfConsignmentPurchase);
	Query.SetParameter("Ref",                Ref);
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Organization, Date);
	
	Query.SetParameter("TaxationOfOrganization",
		AccountingParametersForOrganization.BasicTaxationVATSales);
	Query.SetParameter("UseSeparateAccountingByTaxation",
		AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(Organization, Date));
	Query.SetParameter("BatchAccountingVersion22",
		CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(Date)));
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("Country", RegistrationCountry);
	Query.SetParameter("SubjectToExcise", SubjectToExcise);
	Query.SetParameter("BusinessUnitProduction", BusinessUnitProduction);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	
	InventoriesServer.FillStockTypesByDefault(TempTablesManager, Goods);
	
EndProcedure

#EndRegion

#Region Other

Function DivisionMaintainsSeparateAccountingForManagers(Department)
	
	Query = New Query("
		|SELECT
		|	TRUE
		|FROM
		|	Catalog.BusinessStructure AS T
		|WHERE
		|	T.Ref = &Department
		|	AND T.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
		|");
	
	Query.SetParameter("Department", Department);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Procedure ClearUnusedCCDNumbers()
	
	Query = New Query("
	|SELECT
	|	Goods.LineNumber,
	|	Goods.Products,
	|	Goods.CCDNumber
	|INTO
	|	SGTDProducts
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|;
	|SELECT
	|	Goods.LineNumber
	|FROM
	|	SGTDProducts AS Goods
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = Goods.Products
	|WHERE
	|	NOT CatProducts.KeepRecordsByCCD
	|");
	Query.SetParameter("Goods", Goods.Unload(, "LineNumber, Products, CCDNumber"));
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		String = Goods[Selection.LineNumber - 1];
		String.CCDNumber = Undefined;
	EndDo;
	
EndProcedure

Procedure DeleteIrrelevantLinesDetailingBatches()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	LotDetails.RowID AS RowID
	|INTO TTPartyDetails
	|FROM
	|	&LotDetails AS LotDetails
	|;
	|
	|/////////////////////////////////////
	|SELECT
	|	Goods.RowID AS RowID
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	RowID
	|;
	|
	|/////////////////////////////////////
	|SELECT DISTINCT
	|	LotDetails.RowID AS RowID
	|FROM
	|	TTPartyDetails AS LotDetails
	|	LEFT JOIN
	|		TTProducts_1 AS Goods
	|	ON
	|		LotDetails.RowID = Goods.RowID 
	|WHERE
	|	Goods.RowID IS NULL
	|";
	Query.SetParameter("LotDetails", LotDetails.Unload());
	Query.SetParameter("Goods", Goods.Unload());
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		LinesToDelete = LotDetails.FindRows(New Structure("RowID", Selection.RowID));
		For Each RowToDelete In LinesToDelete Do
			LotDetails.Delete(RowToDelete);
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
