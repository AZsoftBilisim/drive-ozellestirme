#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the terms of sales in the order to the supplier
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Currency = PurchaseConditions.Currency;
	
	If ValueIsFilled(PurchaseConditions.Organization)
		And PurchaseConditions.Organization <> Organization Then
		
		Organization = PurchaseConditions.Organization;
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
		
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Warehouse) Then
		Warehouse 					= PurchaseConditions.Warehouse;
		StructureOfResponsible = PurchasesServer.GetWarehouseManager(Warehouse, Manager);
		
		If StructureOfResponsible <> Undefined Then
			ReceivedBy 			= StructureOfResponsible.EmployeeResponsible;
			AcceptedPosition = StructureOfResponsible.ResponsiblePosition;
		EndIf;
	EndIf;
	
	LineOfBusiness = PurchaseConditions.LineOfBusiness;
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If ValueIsFilled(PurchaseConditions.Counterparty)
		And PurchaseConditions.Counterparty <> Counterparty Then
		
		Counterparty = PurchaseConditions.Counterparty;
		
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If Counterparty <> TheCounterpartyPriorToTheChange Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Currency;
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		Contract = PurchasesServer.GetDefaultContract(
					ThisObject, TollingSchemeClientServer.ContractBusinessTransaction(), AddlParameters);
	Else
		Contract = PurchasesServer.GetDefaultContract(
					ThisObject, Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale, AddlParameters);
	EndIf;
	PurchasesServerCall.FillInBankAccountsUnderAgreement(
		Contract, CompanyBankAccount, CounterpartyBankAccount);
	
	If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
	EndIf;
	
	VendorPriceKind = PurchaseConditions.VendorPriceKind;
	
	RegisterVendorPrices = PurchaseConditions.RegisterVendorPrices;
		
EndProcedure

// Fills in the terms of purchases under a trade agreement with the supplier
//
// Parameters:
//	RecalculatePrices_ - Boolean - True if you need to recalculate prices in the table part of the document.
//
Procedure FillInDefaultPurchaseConditions(RecalculatePrices_ = True) Export
	
	If ValueIsFilled(Partner) Then
		
		FilterParameters = New Structure();
		FilterParameters.Insert("OnlyValid",                       True);
		FilterParameters.Insert("ConsiderWarehouseGroups",                  True);
		FilterParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
		FilterParameters.Insert("SelectedAgreement",                     Terms);
		FilterParameters.Insert("BusinessTransactions",                   BusinessOperation);
		
		DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner, FilterParameters);
		
		TheCounterpartyPriorToTheChange = Counterparty;
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
				
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				
				If RecalculatePrices_
					And ValueIsFilled(Terms) Then
					
					FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
					FillParameters.Insert("PopulationFields",    "Price");
					FillParameters.Insert("Date",              Date);
					FillParameters.Insert("Currency",            Currency);
					FillParameters.Insert("Terms",        Terms);
					FillParameters.Insert("VendorPriceKind", VendorPriceKind);
					
					ActionsWithStrings = New Structure;
					ActionsWithStrings.Insert("RecalculateAmount", "NumberOfPackages");
					
					PartnerPricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, ActionsWithStrings);
					
				EndIf;
				
			Else
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
				If TheCounterpartyPriorToTheChange <> Counterparty Then
					CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
				EndIf;
				Terms = DefaultPurchasingConditions.Terms;
			EndIf;
			
		Else
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			If TheCounterpartyPriorToTheChange <> Counterparty Then
				CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
			EndIf;
			Terms = Undefined;
			If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
				Contract = PurchasesServer.GetDefaultContract(
							ThisObject, TollingSchemeClientServer.ContractBusinessTransaction());
			Else
				Contract = PurchasesServer.GetDefaultContract(
							ThisObject, Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
			EndIf;
			PurchasesServerCall.FillInBankAccountsUnderAgreement(
				Contract, CompanyBankAccount, CounterpartyBankAccount);
			
			If ValueIsFilled(Contract) Then
				Currency = Common.ObjectAttributeValue(Contract, "ARAPCurrency");
			EndIf;
			
			SelectingTypeOfPrices = New Structure("Owner, AvailableForPurchase, Currency", Partner, True, Currency);
			VendorPriceKind = Catalogs.VendorPriceTypes.DefaultPriceType(VendorPriceKind, SelectingTypeOfPrices);
			
			If RecalculatePrices_
				And ValueIsFilled(VendorPriceKind) Then
				
				FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
				FillParameters.Insert("PopulationFields",    "Price");
				FillParameters.Insert("Date",              Date);
				FillParameters.Insert("Currency",            Currency);
				FillParameters.Insert("Terms",        Terms);
				FillParameters.Insert("VendorPriceKind", VendorPriceKind);
				
				ActionsWithStrings = New Structure;
				ActionsWithStrings.Insert("RecalculateAmount", "NumberOfPackages");
				
				PartnerPricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, ActionsWithStrings);
				
			EndIf;
			
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			CounterpartyBankAccount);
		
	EndIf;
	
EndProcedure

// Fills in the terms of sales under the agreement in the order to the supplier
//
// Parameters:
//	RecalculatePrices_ - Boolean - True if you need to recalculate prices in the table part of the document.
//
Procedure FillInTermsOfPurchaseUnderAgreement(RecalculatePrices_ = True) Export
	
	PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms, True, True);
	FillInTermsOfPurchase(PurchaseConditions);
	
	If RecalculatePrices_ Then
		
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields",    "Price");
		FillParameters.Insert("Date",              Date);
		FillParameters.Insert("Currency",            Currency);
		FillParameters.Insert("Terms",        Terms);
		FillParameters.Insert("VendorPriceKind", VendorPriceKind);
		
		ActionsWithStrings = New Structure;
		ActionsWithStrings.Insert("RecalculateAmount", "NumberOfPackages");
		
		PartnerPricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, ActionsWithStrings);
		
	EndIf;
	
EndProcedure

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.GoodsReceiptForStorage - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure
#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, RoundingParameters());
		
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		LineProducts_ = Goods[CurIndex__]; // LineOfATabularSection
		
		ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'в строке %LineNumber% списка ""Товары""';
							|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
							|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
							|pl = 'w wierszu %LineNumber% listy ""Towary""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", LineProducts_.LineNumber);
		
		If ReceiptUnderOrders And
			Not ValueIsFilled(PurchaseOrder) And
			Not ValueIsFilled(LineProducts_.PurchaseOrder) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Đơn hàng đặt nhà cung cấp""';
							|ru = 'Не заполнено поле ""Заказ поставщику""';
							|en = '""Purchase order"" is required'; fa = '""Purchase order"" is required';
							|it = 'Il campo ""Ordine al fornitore"" non è compilato';
							|pl = 'Nie wypełnione pole ""Zamówienie dla dostawcy""';
							|tr = '""Satın alma siparişi"" alanı doldurulmamış'");
			
			Common.MessageToUser(
				ErrorText + Chars.NBSp + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "PurchaseOrder"),
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		
		NotCheckedAttributeArray.Add("Partner");
		
		If Not ValueIsFilled(Partner) Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Bên đặt gia công""';
							|ru = 'Поле ""Давалец"" не заполнено';
							|en = 'The ""Material provider"" field is not filled'; fa = 'The ""Material provider"" field is not filled';
							|it = 'Campo ""Fornitore"" non compilato';
							|pl = 'Pole ""Właściciel surowców"" nie jest wypełnione';
							|tr = '""Malzeme tedarikçisi"" alanı doldurulmamış'");
			Common.MessageToUser(ErrorText, ThisObject, "Partner",, Cancel);
		EndIf;
		
	EndIf;
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsReceiptForStorage);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												SeriesSpecificationParameters,
												Cancel,
												NotCheckedAttributeArray);
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	
	If ThisIsTraceableDocument
		Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers") Then
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, Goods, Date);
	EndIf;
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel, ReceiptUnderOrders);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"),
		"DateOfReceipt");
		
	QualityControl.ProcessingVerificationOfCorrectnessOfConnectionWithBatches(
		ThisObject,
		SeriesSpecificationParameters.LinkFields,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"),
		Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject,Cancel);
	
	GoodsReceiptForStorageLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Var WarehouseForReceipt;
	Var HeaderAttributes;
	
	BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
	
	FillInDataType = TypeOf(FillingData);

	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("DocumentBasis")
			And (TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.PurchaseOrder")
			Or TypeOf(FillingData.DocumentBasis) = Type("Array")
				And FillingData.DocumentBasis.Count() > 0
				And TypeOf(FillingData.DocumentBasis[0]) = Type("DocumentRef.PurchaseOrder")) Then
			
			FillingData.Property("WarehouseForReceipt", WarehouseForReceipt);
			FillingData.Property("HeaderAttributes", HeaderAttributes);
			FillInDocumentBasedOnOrderToSupplier(FillingData.DocumentBasis, WarehouseForReceipt, HeaderAttributes);
		ElsIf FillingData.Property("DocumentBasis")
				And (TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.MaterialProviderOrder2_5")
					Or TypeOf(FillingData.DocumentBasis) = Type("Array")
						And FillingData.DocumentBasis.Count() > 0
						And TypeOf(FillingData.DocumentBasis[0]) = Type("DocumentRef.MaterialProviderOrder2_5")) Then
			
			FillingData.Property("WarehouseForReceipt", WarehouseForReceipt);
			FillingData.Property("HeaderAttributes",   HeaderAttributes);
			
			FillOutDocumentBasedOnGiverSOrder2_5(
				FillingData.DocumentBasis,
				WarehouseForReceipt,
				HeaderAttributes);
		
		ElsIf FillingData.Property("DocumentIsBasisOfFinishedProductBeingRepaired") Then
			
			FillInDocumentBasedOnOrderOfGiver2_5RepairedFinishedProduct(FillingData.DocumentIsBasisOfFinishedProductBeingRepaired);
			
		ElsIf FillingData.Property("DiscrepancyCertificate")
			And FillingData.Property("BasisOfAct") Then
			
			If TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.GoodsShipmentFromStorage") Then
				FillInDocumentOnBasisOfAcceptanceCertificateAfterShipment(FillingData);
			ElsIf TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.GoodsReceiptForStorage") Then
				If FillingData.Property("Patch") Then
					DocumentCorrection.FillInCorrection(ThisObject, FillingData.BasisOfAct);
					CorrectionOfCorrectionOfDocumentOnBasisOfActOfDiscrepanciesAfterReceipt(FillingData);
				Else
					FillInDocumentOnBasisOfAcceptanceCertificateAfterReceipt(FillingData);
				EndIf;
			EndIf;
			
		ElsIf FillingData.Property("DocumentBasis")
			And TypeOf(FillingData.DocumentBasis) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			FillingData.Property("WarehouseForReceipt", WarehouseForReceipt);
			FillInDocumentBasedOnAgreementWithSupplier(FillingData.DocumentBasis, WarehouseForReceipt);
		ElsIf FillingData.Property("DocumentBasis")
			And TypeOf(FillingData.DocumentBasis) = Type("CatalogRef.CounterpartyContracts") Then
			
			FillingData.Property("Warehouse", Warehouse);
			FillInDocumentOnBasisOfContract(FillingData.DocumentBasis, Warehouse);
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
		
	ElsIf FillInDataType = Type("DocumentRef.PurchaseOrder") Then
		FillInDocumentBasedOnOrderToSupplier(FillingData, WarehouseForReceipt);
	ElsIf FillInDataType = Type("DocumentRef.MaterialProviderOrder2_5") Then
		FillOutDocumentBasedOnGiverSOrder2_5(FillingData, WarehouseForReceipt);
	ElsIf FillInDataType = Type("DocumentRef.TransferOfGoodsToBailee") Then
		FillInDocumentBasedOnTransferToProcessor(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		FillInDocumentBasedOnAgreementWithSupplier(FillingData);
	ElsIf FillInDataType = Type("DocumentRef." + Metadata().Name)Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;

	GoodsReceiptForStorageLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	InitializeDocument(FillingData);
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False);
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
											ThisObject,
											"Warehouse",
											True);
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																					Goods);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters());
	
	// We will clear the details of the document that are not used for the business operation.
	
	DocumentAmount = Goods.Total("Sum");
	
	If ReceiptUnderOrders And ValueIsFilled(PurchaseOrder) Then
		
		For Each CurRow In Goods Do
			
			If Not ValueIsFilled(CurRow.PurchaseOrder) Then
				CurRow.PurchaseOrder = PurchaseOrder;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	ProductsServer.ClearUnusedSeries(ThisObject, 
								ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsReceiptForStorage));
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(ThisObject, WriteMode);
	#Region FillingAppointments
	
	// The appointment is checked only after checking the completion of the document,
	// since it is not guaranteed that all key Attributes
	// affecting the selection of appointments will be filled in before the check.
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
		And WriteMode = DocumentWriteMode.Posting Then
		
		AdditionalProperties.Insert("Purpose", Undefined);
		DestinationPattern  = Documents.GoodsReceiptForStorage.DestinationPattern(ThisObject);
		VerificationDetails_1 = "LineOfBusiness,Partner,Contract";
		
		Catalogs.Assignments.CheckFillBeforeRecording(AdditionalProperties.Purpose, DestinationPattern, ThisObject, VerificationDetails_1, Cancel);
		
		FoundRows = Goods.FindRows(New Structure("Purpose", Catalogs.Assignments.EmptyRef()));
		LinksToNomenclature = New Array;
		For Each CurRow In FoundRows Do
			LinksToNomenclature.Add(CurRow.Products);
		EndDo;
		ItemsTypes = Common.ObjectsAttributeValue(LinksToNomenclature, "ItemsType");
		
		For Each CurRow In FoundRows Do
			If ItemsTypes.Get(CurRow.Products) = Enums.ItemsTypes.OwnGoods Then
				CurRow.Purpose = AdditionalProperties.Purpose;
			EndIf;
		EndDo;
		
	EndIf;
	
	#EndRegion
	If WriteMode = DocumentWriteMode.Posting Then
		
		PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
			BusinessOperation,
			Warehouse,
			Department,
			Partner);
		
		// If the Warehouse is a group, then for the analysis of the inventory item, we take the warehouse from PM
		FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
		WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
		If WarehouseDetails.IsFolder = True And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
			FieldsNames.Insert("Arbitrary", "Warehouse");
		EndIf;
		
		InformationRegisters.ItemsLocationAttributes.FillInCollection(
			Goods,
			PlacesOfAccounting,
			FieldsNames);
		
		FillOutTypesOfDocumentInventory();
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
		
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(Warehouse, BusinessOperation);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods");
	
	GoodsReceiptForStorageLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	GoodsReceiptForStorageLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
	GoodsReceiptForStorageLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);

	Approved = False;
	ReceiptUnderOrders = False;
	PurchaseOrder = Undefined;
	IncomingDocumentDate = Date(1,1,1);
	IncomingDocumentNumber = "";
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	Basis = Undefined;
	
	For Each CurRow In Goods Do
		
		CurRow.PurchaseOrder = Undefined;
		CurRow.RowCode = 0;
		CurRow.InventoryOwnerAttribute = Catalogs.InventoryKinds.EmptyRef();
		CurRow.LotVendorAttributes = Catalogs.KeysForLotVendorAttributes.EmptyRef();
		CurRow.RowID = "";

	EndDo;
	
	SetOfSeries.Clear();
	
	InitializeDocument();
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
											ThisObject,
											"Warehouse",
											True);
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																					Goods);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods");
	
	GoodsReceiptForStorageLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
		And AdditionalProperties.WriteMode = DocumentWriteMode.Posting Then
		DestinationPattern   = Documents.GoodsReceiptForStorage.DestinationPattern(ThisObject);
		Catalogs.Assignments.OnWriteDocument(
			AdditionalProperties.Purpose,
			DestinationPattern,
			ThisObject,
			Partner,
			Enums.VATTaxationTypes.EmptyRef());
	EndIf;
	GoodsReceiptForStorageLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDocumentBasedOnOrderToSupplier(Val DocumentBasis, Val WarehouseForReceipt = Undefined,
		OrderDetails = Undefined)
	
	FillInByLeftovers = False;
	BasisType        = TypeOf(DocumentBasis);
	
	If Not OrderDetails = Undefined Then
		FillPropertyValues(ThisObject, OrderDetails);
	EndIf;
	
	If ValueIsFilled(Terms) Then
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms, True, True);
		FillInTermsOfPurchase(PurchaseConditions);
	EndIf;
	
	If BasisType = Type("DocumentRef.PurchaseOrder") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	PurchaseOrder.Ref AS PurchaseOrder,
		|	PurchaseOrder.Status AS DocumentStatus,
		|	PurchaseOrder.Partner AS Partner,
		|	PurchaseOrder.Counterparty AS Counterparty,
		|	PurchaseOrder.Terms AS Terms,
		|	PurchaseOrder.Organization AS Organization,
		|	CASE
		|		WHEN PurchaseOrder.Warehouse.IsFolder
		|				AND PurchaseOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE PurchaseOrder.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN PurchaseOrder.Warehouse.IsFolder
		|				AND PurchaseOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItIsForbiddenToSelectWarehouseGroup,
		|	PurchaseOrder.Contract AS Contract,
		|	PurchaseOrder.Currency AS Currency,
		|	ISNULL(PurchaseOrder.Terms.VendorPriceKind, VALUE(Catalog.VendorPriceTypes.EmptyRef)) AS VendorPriceKind,
		|	PurchaseOrder.SalesOpportunity AS SalesOpportunity,
		|	PurchaseOrder.Terms.RegisterVendorPrices AS RegisterVendorPrices,
		|	PurchaseOrder.Department AS Department,
		|	PurchaseOrder.LineOfBusiness AS LineOfBusiness,
		|	CASE
		|		WHEN PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|				OR PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	NOT PurchaseOrder.Posted AS ThereAreErrorsPosted
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	OrdersBalance.Warehouse AS Warehouse
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder = &DocumentBasis) AS OrdersBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	OrderedGoods.VendorPriceKind AS VendorPriceKind
		|FROM
		|	Document.PurchaseOrder.Goods AS OrderedGoods
		|WHERE
		|	OrderedGoods.Ref = &DocumentBasis
		|	AND NOT OrderedGoods.VendorPriceKind = VALUE(Catalog.VendorPriceTypes.EmptyRef)
		|";
		
		Query.SetParameter("DocumentBasis", DocumentBasis);
		
		QueryResult = Query.ExecuteBatch();
		
		OrderDetails = QueryResult[0].Select();
		OrderDetails.Next();
		
		ArrayOfValidStatuses = New Array();
		ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Confirmed_);
		ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Closed);
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			OrderDetails.PurchaseOrder,
			OrderDetails.DocumentStatus,
			OrderDetails.ThereAreErrorsPosted,
			OrderDetails.ThereAreErrorsStatus,
			ArrayOfValidStatuses);
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			WarehouseArray = QueryResult[1].Unload().UnloadColumn("Warehouse");
		EndIf;
		
		DetailsOfPriceType = QueryResult[2].Unload().UnloadColumn("VendorPriceKind");
		
		If DetailsOfPriceType.Count() = 1 Then
			ThisObject.VendorPriceKind = DetailsOfPriceType[0];
		EndIf;
		
	ElsIf BasisType = Type("Array") Then
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			
			Query = New Query;
			Query.Text =
			"SELECT DISTINCT
			|	OrdersBalance.Warehouse AS Warehouse
			|FROM
			|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder IN (&DocumentsArray)) AS OrdersBalance";
			
			Query.SetParameter("DocumentsArray", DocumentBasis);
			
			RequestResultForWarehouses = Query.Execute();
			
			WarehouseArray = RequestResultForWarehouses.Unload().UnloadColumn("Warehouse");
			Warehouse = OrderDetails.WarehouseForReceipt;
			
		EndIf;
		
	EndIf;
	
	ReceiptUnderOrders = True;
	
	// Filling in incl. goods.
	If Not ValueIsFilled(WarehouseForReceipt) Then
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			
			// Only service
			If WarehouseArray.Count() = 0 Then
				
				FillInByLeftovers = True;
				
			// Services or goods
			ElsIf WarehouseArray.Count() = 1 Then
				
				FillInByLeftovers = True;
				WarehouseForReceipt    = WarehouseArray[0];
				Warehouse               = WarehouseForReceipt;
				
			// Services and goods
			ElsIf WarehouseArray.Count() = 2 Then
				
				If Not ValueIsFilled(WarehouseArray[0])
					Or Not ValueIsFilled(WarehouseArray[1]) Then
					
					FillInByLeftovers = True;
					WarehouseForReceipt    = ?(ValueIsFilled(WarehouseArray[0]), WarehouseArray[0], WarehouseArray[1]);
					Warehouse               = WarehouseForReceipt;
					
				EndIf;
				
			EndIf;
			
		Else
			FillInByLeftovers = True;
			WarehouseForReceipt    = Warehouse;
		EndIf;
		
	Else
		FillInByLeftovers = True;
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			Warehouse = WarehouseForReceipt;
		EndIf;
	EndIf;
	
	If FillInByLeftovers Then
		
		If BasisType = Type("Array") Then
			AnArrayOfOrders = DocumentBasis;
		Else
			AnArrayOfOrders = New Array();
			AnArrayOfOrders.Add(PurchaseOrder);
		EndIf;
		
		Documents.GoodsReceiptForStorage.FillByOrderBalances(
			ThisObject,
			Goods,
			?(WarehouseForReceipt=Undefined, Catalogs.Warehouses.EmptyRef(), WarehouseForReceipt),
			AnArrayOfOrders);
		
		OrdersServer.FillInOrderInOrderHeaderInTableSection(PurchaseOrder, Goods, "PurchaseOrder");
		
		If Not ValueIsFilled(PurchaseOrder)
			And AnArrayOfOrders.Count() = 1
			And TypeOf(AnArrayOfOrders[0]) = Type("DocumentRef.PurchaseOrder") Then
			PurchaseOrder = AnArrayOfOrders[0];
		EndIf;
		
	EndIf;
	
	If GetFunctionalOption("UseReceiptForMultipleOrders") Then
		SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
	EndIf;
	
EndProcedure

Procedure FillOutDocumentBasedOnGiverSOrder2_5(
			Val DocumentBasis, Val WarehouseForReceipt = Undefined, OrderDetails = Undefined)
	
	FillInByLeftovers = False;
	
	BasisType        = TypeOf(DocumentBasis);
	If BasisType = Type("DocumentRef.MaterialProviderOrder2_5") Then
		
		FillInDocumentHeaderBasedOnGiverSOrder2_5(DocumentBasis, OrderDetails);
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	OrdersBalance.Warehouse AS Warehouse
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder = &DocumentBasis) AS OrdersBalance
		|";
		
		Query.SetParameter("DocumentBasis", DocumentBasis);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			WarehouseArray = Query.Execute().Unload().UnloadColumn("Warehouse");
		EndIf;
		
	ElsIf BasisType = Type("Array") Then
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			
			Query = New Query;
			Query.Text =
			"SELECT DISTINCT
			|	OrdersBalance.Warehouse AS Warehouse
			|FROM
			|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder IN (&DocumentsArray)) AS OrdersBalance";
			
			Query.SetParameter("DocumentsArray", DocumentBasis);
			
			RequestResultForWarehouses = Query.Execute();
			
			WarehouseArray = RequestResultForWarehouses.Unload().UnloadColumn("Warehouse");
			
			Warehouse = OrderDetails.WarehouseForReceipt;
			
		EndIf;
		
	EndIf;
	
	ReceiptUnderOrders = True;
	
	// Filling in incl. goods.
	If Not ValueIsFilled(WarehouseForReceipt) Then
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			
			// Only service
			If WarehouseArray.Count() = 0 Then
				
				FillInByLeftovers = True;
				
			// Services or goods
			ElsIf WarehouseArray.Count() = 1 Then
				
				FillInByLeftovers = True;
				WarehouseForReceipt    = WarehouseArray[0];
				Warehouse               = WarehouseForReceipt;
				
			// Services and goods
			ElsIf WarehouseArray.Count() = 2 Then
				
				If Not ValueIsFilled(WarehouseArray[0])
				 Or Not ValueIsFilled(WarehouseArray[1]) Then
					
					FillInByLeftovers = True;
					WarehouseForReceipt    = ?(ValueIsFilled(WarehouseArray[0]), WarehouseArray[0], WarehouseArray[1]);
					Warehouse               = WarehouseForReceipt;
					
				EndIf;
				
			EndIf;
			
		Else
			
			FillInByLeftovers = True;
			WarehouseForReceipt    = Warehouse;
			
		EndIf;
		
	Else
		
		FillInByLeftovers = True;
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			Warehouse = WarehouseForReceipt;
		EndIf;
		
	EndIf;
	
	If FillInByLeftovers Then
		
		If BasisType = Type("Array") Then
			AnArrayOfOrders = DocumentBasis;
		Else
			AnArrayOfOrders = New Array;
			AnArrayOfOrders.Add(PurchaseOrder);
		EndIf;
		
		Documents.GoodsReceiptForStorage.FillByOrderBalances(
			ThisObject,
			Goods,
			?(WarehouseForReceipt = Undefined, Catalogs.Warehouses.EmptyRef(), WarehouseForReceipt),
			AnArrayOfOrders);
		
		OrdersServer.FillInOrderInOrderHeaderInTableSection(PurchaseOrder, Goods, "PurchaseOrder");
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnOrderOfGiver2_5RepairedFinishedProduct(DocumentBasis)
	
	// Filling in the document header
	OrderDetails = New Structure;
	FillInDocumentHeaderBasedOnGiverSOrder2_5(DocumentBasis, OrderDetails);
	
	PurchaseOrder = Undefined;
	Basis       = DocumentBasis;
	
	// Filling in the product table
	If ValueIsFilled(OrderDetails.UnderRepairProduct) Then
		
		CurrentData                    = Goods.Add();
		CurrentData.Products       = OrderDetails.UnderRepairProduct;
		CurrentData.Characteristic     = OrderDetails.UnderRepairVariant;
		CurrentData.Purpose         = Common.ObjectAttributeValue(Contract, "Purpose");
		CurrentData.Warehouse              = Warehouse;
		CurrentData.Count         = 1;
		CurrentData.NumberOfPackages = 1;
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsReceiptForStorage));
		
		If ValueIsFilled(OrderDetails.UnderRepairBatch) Then
			
			If ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(OrderDetails.UnderRepairBatchSpecificationStatus, SeriesSpecificationParameters) Then
				CurrentData.Series = OrderDetails.UnderRepairBatch;
			Else
				CurrentBatchData = SetOfSeries.Add();
				FillPropertyValues(CurrentBatchData, CurrentData);
				CurrentBatchData.Series = OrderDetails.UnderRepairBatch;
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(VendorPriceKind) Then
			
			Date = CurrentSessionDate();
			
			FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
			FillParameters.Insert("PopulationFields",    "Price");
			FillParameters.Insert("Date",              Date);
			FillParameters.Insert("Currency",            Currency);
			FillParameters.Insert("VendorPriceKind", VendorPriceKind);
			FillParameters.Insert("Organization",       Organization);
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
			
			PartnerPricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);
			
		EndIf;
		
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentHeaderBasedOnGiverSOrder2_5(Val DocumentBasis, OrderDetails)
	
	BasisType        = TypeOf(DocumentBasis);
	If BasisType = Type("DocumentRef.MaterialProviderOrder2_5") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	MaterialProviderOrder2_5.Ref                                   AS PurchaseOrder,
		|	MaterialProviderOrder2_5.Status                                   AS DocumentStatus,
		|	MaterialProviderOrder2_5.Partner                                  AS Partner,
		|	MaterialProviderOrder2_5.Counterparty                               AS Counterparty,
		|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
		|	MaterialProviderOrder2_5.Organization                              AS Organization,
		|	CASE
		|		WHEN MaterialProviderOrder2_5.WarehouseForReceipt.IsFolder
		|			AND MaterialProviderOrder2_5.WarehouseForReceipt.SelectGroup =
		|													VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|				THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE MaterialProviderOrder2_5.WarehouseForReceipt
		|	END                                                     AS Warehouse,
		|	CASE
		|		WHEN MaterialProviderOrder2_5.WarehouseForReceipt.IsFolder
		|			AND MaterialProviderOrder2_5.WarehouseForReceipt.SelectGroup =
		|													VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                                     AS ItIsForbiddenToSelectWarehouseGroup,
		|	MaterialProviderOrder2_5.Contract                                  AS Contract,
		|	MaterialProviderOrder2_5.Currency                                   AS Currency,
		|	MaterialProviderOrder2_5.PriceTypeMaterials                         AS VendorPriceKind,
		|	MaterialProviderOrder2_5.SalesOpportunity                                   AS SalesOpportunity,
		|	MaterialProviderOrder2_5.RegisterVendorPrices             AS RegisterVendorPrices,
		|	MaterialProviderOrder2_5.Department                            AS Department,
		|	MaterialProviderOrder2_5.LineOfBusiness                  AS LineOfBusiness,
		|	MaterialProviderOrder2_5.UnderRepairProduct         AS UnderRepairProduct,
		|	MaterialProviderOrder2_5.UnderRepairVariant       AS UnderRepairVariant,
		|	MaterialProviderOrder2_5.UnderRepairBatch                AS UnderRepairBatch,
		|	MaterialProviderOrder2_5.UnderRepairBatchSpecificationStatus  AS UnderRepairBatchSpecificationStatus,
		|	NOT MaterialProviderOrder2_5.Status IN (&AcceptableStatuses)         AS ThereAreErrorsStatus,
		|	NOT MaterialProviderOrder2_5.Posted                              AS ThereAreErrorsPosted
		|FROM
		|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
		|WHERE
		|	MaterialProviderOrder2_5.Ref = &DocumentBasis
		|";
		
		Query.SetParameter("DocumentBasis", DocumentBasis);
		
		AcceptableStatuses = Documents.MaterialProviderOrder2_5.ValidInputStatusesBasedOn(Metadata().Name);
		Query.SetParameter("AcceptableStatuses", AcceptableStatuses);
		
		OrderDetails = Query.Execute().Select();
		OrderDetails.Next();
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			OrderDetails.PurchaseOrder,
			OrderDetails.DocumentStatus,
			OrderDetails.ThereAreErrorsPosted,
			OrderDetails.ThereAreErrorsStatus,
			AcceptableStatuses);
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		
	ElsIf BasisType = Type("Array") Then
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		
	EndIf;
	
	BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
	
	If GetFunctionalOption("UseReceiptForMultipleOrders") Then
		SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnTransferToProcessor(Val DocumentBasis)
	
	BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
	
	Query = New Query;
	Query.SetParameter("Basis", DocumentBasis);
	
	TransferAttributes = Common.ObjectAttributesValues(DocumentBasis, "TransferByOrders");
	If TransferAttributes.TransferByOrders
		And GetFunctionalOption("UseMaterialProviderOrder2_5") Then
		ReceiptUnderOrders  = True;
		Query.Text = FillInQueryTextBasedOnTransferToProcessorForOrders();
	Else
		Query.Text = FillInQueryTextBasedOnTransferToProcessorWithoutOrder();
	EndIf;
	
	Result = Query.ExecuteBatch();
	HeaderAttributes = Result[Result.UBound() - 2].Select();
	GoodsTable  = Result[Result.UBound() - 1].Unload();
	OrdersTable  = Result[Result.UBound()].Unload();
	
	If HeaderAttributes.Next() Then
		FillPropertyValues(ThisObject, HeaderAttributes);
	EndIf;
	
	FillInGiverSOrderInProcessorSGoods(GoodsTable, OrdersTable);
	
	// For admission without an order, the appointment is taken from the Contract
	If Not ReceiptUnderOrders
		And ValueIsFilled(Contract) Then
		GoodsTable.FillValues(Common.ObjectAttributeValue(Contract, "Purpose"), "Purpose");
	EndIf;
	
	Goods.Load(GoodsTable);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages", BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	StructureOfActions.Insert("RecalculatePriceByAmount",        "Count");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	OrdersServer.FillInOrderInOrderHeaderInTableSection(PurchaseOrder, Goods, "PurchaseOrder");
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsReceiptForStorage));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Function FillInQueryTextBasedOnTransferToProcessorForOrders()
	
	QueryText =
	"SELECT ALLOWED
	|	TableOfGoods.SalesOrder AS SubcontractOrder
	|INTO OrdersToProcessor
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref = &Basis
	|
	|GROUP BY
	|	TableOfGoods.SalesOrder
	|
	|INDEX BY
	|	SubcontractOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OrderData.Ref AS Ref
	|INTO GiverSOrders
	|FROM
	|	Document.MaterialProviderOrder2_5 AS OrderData
	|WHERE
	|	OrderData.Basis IN
	|		(SELECT
	|			OrdersToProcessor.SubcontractOrder AS SubcontractOrder
	|		FROM
	|			OrdersToProcessor AS OrdersToProcessor)
	|	AND OrderData.Posted
	|	AND NOT OrderData.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved)
	|	AND NOT OrderData.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.Approved)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MIN(OrderData.Organization) AS Organization,
	|	MIN(OrderData.Counterparty)  AS Counterparty,
	|	MIN(OrderData.Partner)     AS Partner,
	|	MIN(OrderData.Contract)     AS Contract,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.LineOfBusiness) = 1
	|			THEN MIN(OrderData.LineOfBusiness)
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END                             AS LineOfBusiness,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.WarehouseForReceipt) = 1
	|			THEN MIN(CASE
	|				WHEN OrderData.WarehouseForReceipt.IsFolder
	|					AND OrderData.WarehouseForReceipt.SelectGroup =
	|						VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|					THEN VALUE(Catalog.Warehouses.EmptyRef)
	|				ELSE OrderData.WarehouseForReceipt
	|			END)
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END                             AS Warehouse,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.PriceTypeMaterials) = 1
	|			THEN MIN(OrderData.PriceTypeMaterials)
	|		ELSE VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|	END                             AS VendorPriceKind,
	|	MIN(OrderData.RegisterVendorPrices) AS RegisterVendorPrices,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.Department) = 1
	|			THEN MIN(OrderData.Department)
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END                             AS Department,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.Currency) = 1
	|			THEN MIN(OrderData.Currency)
	|		ELSE VALUE(Catalog.Currencies.EmptyRef)
	|	END                             AS Currency,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.SalesOpportunity) = 1
	|			THEN MIN(OrderData.SalesOpportunity)
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END                             AS SalesOpportunity,
	|	&Basis                        AS Basis
	|FROM
	|	GiverSOrders AS GiverSOrders
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5 AS OrderData
	|	ON OrderData.Ref = GiverSOrders.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfGoods.Products            AS Products,
	|	TableOfGoods.Characteristic          AS Characteristic,
	|	TableOfGoods.Series                   AS Series,
	|	TableOfGoods.CCDNumber                AS CCDNumber,
	|	VALUE(Catalog.Warehouses.EmptyRef)         AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef)     AS Purpose,
	|	VALUE(Document.MaterialProviderOrder2_5.EmptyRef) AS PurchaseOrder,
	|	0                                      AS RowCode,
	|	SUM(TableOfGoods.Count)       AS Count,
	|	SUM(TableOfGoods.QuantityByGBRN) AS QuantityByGBRN,
	|	0                                      AS Price,
	|	SUM(TableOfGoods.Sum)            AS Sum
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes.Products   AS Products,
	|		TableOfGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		TableOfGoods.ItemsLocationAttributes.Series          AS Series,
	|		TableOfGoods.CCDNumber                                  AS CCDNumber,
	|		TableOfGoods.Count                                AS Count,
	|		TableOfGoods.QuantityByGBRN                          AS QuantityByGBRN,
	|		TableOfGoods.Sum                                     AS Sum
	|	FROM
	|		Document.TransferOfGoodsToBailee.InventoryKinds AS TableOfGoods
	|	WHERE
	|		TableOfGoods.SalesOrder IN
	|			(SELECT
	|				OrdersToProcessor.SubcontractOrder AS SubcontractOrder
	|			FROM
	|				OrdersToProcessor AS OrdersToProcessor)
	|		AND TableOfGoods.Ref.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableOfGoods.Products      AS Products,
	|		TableOfGoods.Characteristic    AS Characteristic,
	|		TableOfGoods.Series             AS Series,
	|		TableOfGoods.CCDNumber          AS CCDNumber,
	|		-TableOfGoods.Count       AS Count,
	|		-TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|		-TableOfGoods.Sum            AS Sum
	|	FROM
	|		Document.GoodsReceiptForStorage.Goods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Ref.Posted
	|		AND TableOfGoods.PurchaseOrder IN
	|			(SELECT
	|				GiverSOrders.Ref
	|			FROM
	|				GiverSOrders AS GiverSOrders)
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.CCDNumber
	|
	|HAVING
	|	SUM(TableOfGoods.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	StockBalance.PurchaseOrder    AS PurchaseOrder,
	|	StockBalance.Products       AS Products,
	|	StockBalance.Characteristic     AS Characteristic,
	|	StockBalance.RowCode          AS RowCode,
	|	StockBalance.Warehouse              AS Warehouse,
	|	OrderMaterials.Purpose        AS Purpose,
	|	StockBalance.ToRegisterBalance AS Count,
	|	OrderMaterials.Price              AS Price
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(,
	|		PurchaseOrder IN
	|			(SELECT
	|				GiverSOrders.Ref
	|			FROM
	|				GiverSOrders AS GiverSOrders)
	|	) AS StockBalance
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5.UsedMaterials AS OrderMaterials
	|	ON OrderMaterials.Ref = StockBalance.PurchaseOrder
	|	AND OrderMaterials.RowCode = StockBalance.RowCode
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5 AS OrderData
	|	ON OrderData.Ref = StockBalance.PurchaseOrder
	|
	|	LEFT JOIN Catalog.Priorities AS CatPriorities
	|	ON CatPriorities.Ref = OrderData.Priority
	|
	|ORDER BY
	|	ISNULL(CatPriorities.AddlOrderingAttribute, 0)
	|";
	
	Return QueryText;
	
EndFunction

Function FillInQueryTextBasedOnTransferToProcessorWithoutOrder()
	
	QueryText =
	"SELECT ALLOWED
	|	CatCompanies.Ref           AS Organization,
	|	CatCounterparties.Ref           AS Counterparty,
	|	CatCounterparties.Partner          AS Partner,
	|	CatContracts.Ref              AS Contract,
	|	CASE
	|		WHEN CatContracts.LineOfBusiness IS NULL
	|			THEN TransferOfGoodsToBailee.LineOfBusiness
	|		ELSE CatContracts.LineOfBusiness
	|	END                           AS LineOfBusiness,
	|	TransferOfGoodsToBailee.Currency AS Currency,
	|	TransferOfGoodsToBailee.SalesOpportunity AS SalesOpportunity,
	|	TransferOfGoodsToBailee.Number  AS IncomingDocumentNumber,
	|	TransferOfGoodsToBailee.Date   AS IncomingDocumentDate,
	|	TransferOfGoodsToBailee.Ref AS Basis
	|FROM
	|	Document.TransferOfGoodsToBailee AS TransferOfGoodsToBailee
	|	
	|	LEFT JOIN Catalog.Counterparties AS Toller
	|	ON Toller.Ref = TransferOfGoodsToBailee.Counterparty
	|	
	|	LEFT JOIN Catalog.Companies AS CatCompanies
	|	ON CatCompanies.TIN = Toller.TIN
	|	AND CatCompanies.CRTR = Toller.CRTR
	|	AND NOT CatCompanies.DeletionMark
	|	
	|	LEFT JOIN Catalog.Companies AS MaterialProvider
	|	ON MaterialProvider.Ref = TransferOfGoodsToBailee.Organization
	|	
	|	LEFT JOIN Catalog.Counterparties AS CatCounterparties
	|	ON CatCounterparties.TIN = MaterialProvider.TIN
	|	AND CatCounterparties.CRTR = MaterialProvider.CRTR
	|	AND NOT CatCounterparties.DeletionMark
	|	
	|	LEFT JOIN Catalog.CounterpartyContracts AS MaterialProviderContract
	|	ON MaterialProviderContract.Ref = TransferOfGoodsToBailee.Contract
	|
	|	LEFT JOIN Catalog.CounterpartyContracts AS CatContracts
	|	ON CatContracts.Organization = CatCompanies.Ref
	|	AND CatContracts.Counterparty = CatCounterparties.Ref
	|	AND CatContracts.Number = MaterialProviderContract.Number
	|	AND CatContracts.Date = MaterialProviderContract.Date
	|	AND CatContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND NOT CatContracts.DeletionMark
	|
	|WHERE
	|	TransferOfGoodsToBailee.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfGoods.ItemsLocationAttributes.Products   AS Products,
	|	TableOfGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes.Series          AS Series,
	|	TableOfGoods.CCDNumber                                  AS CCDNumber,
	|	VALUE(Catalog.Warehouses.EmptyRef)                 AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef)             AS Purpose,
	|	VALUE(Document.MaterialProviderOrder2_5.EmptyRef)         AS PurchaseOrder,
	|	0                                                        AS RowCode,
	|	SUM(TableOfGoods.Count)                         AS Count,
	|	SUM(TableOfGoods.QuantityByGBRN)                   AS QuantityByGBRN,
	|	SUM(TableOfGoods.Sum)                              AS Sum
	|FROM
	|	Document.TransferOfGoodsToBailee.InventoryKinds AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref = &Basis
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	StockBalance.PurchaseOrder    AS PurchaseOrder,
	|	StockBalance.Products       AS Products,
	|	StockBalance.Characteristic     AS Characteristic,
	|	StockBalance.RowCode          AS RowCode,
	|	StockBalance.Warehouse              AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	StockBalance.ToRegisterBalance AS Count
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(, FALSE) AS StockBalance
	|";
	
	Return QueryText;
	
EndFunction

Procedure FillInGiverSOrderInProcessorSGoods(GoodsTable, OrdersTable)
	
	If OrdersTable.Count() = 0 Then
		Return;
	EndIf;
	
	GoodsTable.Indexes.Add("Products, Characteristic, RowCode");
	
	For Each GiverSOrderLine In OrdersTable Do
		
		GiverSOrderQuantity = GiverSOrderLine.Count;
		
		Filter =
			New Structure(
				"Products, Characteristic, RowCode",
				GiverSOrderLine.Products,
				GiverSOrderLine.Characteristic,
				0);
		
		For Each CurrentData In GoodsTable.FindRows(Filter) Do
			
			If CurrentData.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GiverSOrderQuantity, CurrentData.Count);
			
			NewRow = GoodsTable.Add();
			FillPropertyValues(NewRow, CurrentData);
			FillPropertyValues(NewRow, GiverSOrderLine);
			NewRow.Count      = Count;
			NewRow.Sum           = Round(NewRow.Count * NewRow.Price, 2);
			
			CurrentData.Count = CurrentData.Count - Count;
			CurrentData.Sum      = CurrentData.Sum - NewRow.Sum;
			
			GiverSOrderQuantity = GiverSOrderQuantity - Count;
			
			If GiverSOrderQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	GoodsTable.Indexes.Clear();
	
	Filter = New Structure("Count", 0);
	For Each CurrentData In GoodsTable.FindRows(Filter) Do
		GoodsTable.Delete(CurrentData);
	EndDo;
	
EndProcedure

Procedure FillInDocumentBasedOnAgreementWithSupplier(Val DocumentBasis, Val WarehouseForReceipt = Undefined)
	
	Query = New Query(
		"SELECT
		|	TermsOfPurchases.Ref AS Terms,
		|	TermsOfPurchases.Partner AS Partner,
		|	TermsOfPurchases.Status AS DocumentStatus,
		|	CASE
		|		WHEN TermsOfPurchases.Status <> VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThereAreErrorsStatus,
		|	TermsOfPurchases.BusinessOperation AS BusinessOperation,
		|	TermsOfPurchases.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
		|WHERE
		|	TermsOfPurchases.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsReadyForReceiptBalance.Warehouse,
		|	GoodsReadyForReceiptBalance.DocumentInflow,
		|	GoodsReadyForReceiptBalance.Products,
		|	GoodsReadyForReceiptBalance.Characteristic,
		|	GoodsReadyForReceiptBalance.Purpose,
		|	GoodsReadyForReceiptBalance.Series,
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance AS Count,
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance AS NumberOfPackages
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(,DocumentInflow = &DocumentBasis 
		|		AND CASE WHEN &WarehouseSpecified
		|			THEN Warehouse = &WarehouseForReceipt
		|			ELSE TRUE
		|	END) AS GoodsReadyForReceiptBalance
		|WHERE
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance > 0");
		
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("WarehouseForReceipt", WarehouseForReceipt);
	Query.SetParameter("WarehouseSpecified", ValueIsFilled(WarehouseForReceipt));
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	Selection.Next();
	
	SalesServer.CheckPossibilityOfEnteringOnBasisOfAgreement("GoodsReceiptForStorage",
		Selection.BusinessOperation);
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfTermsOfPurchase.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.Terms,
		Selection.DocumentStatus,
		,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
		
	FillPropertyValues(ThisObject, Selection);
	Goods.Load(QueryResult[1].Unload());
	FillInTermsOfPurchaseUnderAgreement();
	
EndProcedure

Procedure FillInDocumentOnBasisOfContract(Contract, WarehouseForReceipt = Undefined)
	
	Query = New Query(
		"SELECT
		|	Contract.Ref AS Contract,
		|	Contract.Partner AS Partner,
		|	Contract.Counterparty AS Counterparty,
		|	Contract.Organization AS Organization,
		|	Contract.Status AS DocumentStatus,
		|	CASE
		|		WHEN Contract.Status <> VALUE(Enum.CounterpartyContractStatuses.Valid)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThereAreErrorsStatus,
		|	Contract.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Catalog.CounterpartyContracts AS Contract
		|WHERE
		|	Contract.Ref = &Contract
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsReadyForReceiptBalance.Warehouse,
		|	GoodsReadyForReceiptBalance.DocumentInflow,
		|	GoodsReadyForReceiptBalance.Products,
		|	GoodsReadyForReceiptBalance.Characteristic,
		|	GoodsReadyForReceiptBalance.Purpose,
		|	GoodsReadyForReceiptBalance.Series,
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance AS Count,
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance AS NumberOfPackages
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(,DocumentInflow = &Contract
		|		AND CASE WHEN &WarehouseSpecified
		|			THEN Warehouse = &WarehouseForReceipt
		|			ELSE TRUE
		|	END) AS GoodsReadyForReceiptBalance
		|WHERE
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance > 0");
		
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("WarehouseForReceipt", WarehouseForReceipt);
	Query.SetParameter("WarehouseSpecified", ValueIsFilled(WarehouseForReceipt));
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.CounterpartyContractStatuses.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.Contract,
		Selection.DocumentStatus,
		,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
		
	FillPropertyValues(ThisObject, Selection);
	Goods.Load(QueryResult[1].Unload());
	FillInTermsOfPurchaseUnderAgreement();
	
EndProcedure

Procedure FillInDocumentOnBasisOfAcceptanceCertificateAfterShipment(Val FillingData)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsShipmentFromStorage.Ref                                            AS Ref,
	|	GoodsShipmentFromStorage.Partner                                           AS Partner,
	|	GoodsShipmentFromStorage.Counterparty                                        AS Counterparty,
	|	GoodsShipmentFromStorage.Terms                                        AS Terms,
	|	GoodsShipmentFromStorage.Organization                                       AS Organization,
	|	GoodsShipmentFromStorage.Contract                                           AS Contract,
	|	GoodsShipmentFromStorage.Warehouse                                             AS Warehouse,
	|	GoodsShipmentFromStorage.Director                                      AS Director,
	|	GoodsShipmentFromStorage.ChiefAccountant                                  AS ChiefAccountant,
	|	CASE
	|		WHEN GoodsShipmentFromStorage.BusinessOperation IN (
	|											VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5),
	|											VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5))
	|			THEN VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
	|		WHEN TRUE
	|			THEN VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale)
	|	END                                                                      AS BusinessOperation,
	|	GoodsShipmentFromStorage.SalesOpportunity                                            AS SalesOpportunity,
	|	GoodsShipmentFromStorage.Department                                     AS Department,
	|	GoodsShipmentFromStorage.Currency                                            AS Currency,
	|	NOT GoodsShipmentFromStorage.Posted                                       AS ThereAreErrorsPosted,
	|	GoodsShipmentFromStorage.LineOfBusiness                           AS LineOfBusiness
	|FROM
	|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
	|WHERE
	|	GoodsShipmentFromStorage.Ref = &DocumentBasisCorrectionOfBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products                       AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic                     AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose                         AS Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder                       AS PurchaseOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode                          AS RowCode,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package                           AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series                              AS Series,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages -
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.Count -
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument)         AS Count,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices                         AS DocumentSalesOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price                               AS Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse                              AS Warehouse,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum -
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument)              AS Sum
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages - CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument > 0
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products               AS Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic             AS Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose                 AS Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series                      AS Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse                      AS Warehouse,
	|	SUM(DiscrepancyReportFollowingShipmentSetOfSeries.Count -
	|		DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS DiscrepancyReportFollowingShipmentSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.Count - DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument > 0
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.SaleOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse";
	
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	
	// Filling in the act if there is a correction of the grounds of the act.
	If FillingData.Property("CorrectionOfBasis") And ValueIsFilled(FillingData.CorrectionOfBasis) Then
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingData.CorrectionOfBasis);
	Else
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingData.BasisOfAct);
	EndIf;
	
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection  = QueryBatch[0].Select();
	
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.Ref, Undefined,
		HeaderSelection.ThereAreErrorsPosted);
	
	SubsequentDeliveryByDocument = FillingData.BasisOfAct;
	FillPropertyValues(ThisObject, HeaderSelection);
	
	TableOfGoods = QueryBatch[1].Unload();
	
	For Each CurRow In TableOfGoods Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurRow);
		
		NewRow.Sum = NewRow.Price * NewRow.NumberOfPackages;
		
	EndDo;
	
	SetOfSeries.Load(QueryBatch[2].Unload());
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		
		For Each TableRow In Goods Do
			
			If Not ValueIsFilled(TableRow.PurchaseOrder) Then
				Continue;
			EndIf;
			
			ReceiptUnderOrders = True;
			If Not GetFunctionalOption("UseReceiptForMultipleOrders") Then
				PurchaseOrder = TableRow.PurchaseOrder;
			EndIf;
			
			Break;
			
		EndDo;
		
	EndIf;
EndProcedure

Procedure FillInDocumentOnBasisOfAcceptanceCertificateAfterReceipt(FillingData)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DiscrepancyReportFollowingReceipt.Ref                             AS DiscrepancyCertificate,
	|	GoodsReceiptForStorage.Ref                                 AS DocumentInflow,
	|	GoodsReceiptForStorage.Partner                                AS Partner,
	|	GoodsReceiptForStorage.Counterparty                             AS Counterparty,
	|	GoodsReceiptForStorage.Terms                             AS Terms,
	|	GoodsReceiptForStorage.Organization                            AS Organization,
	|	GoodsReceiptForStorage.Contract                                AS Contract,
	|	GoodsReceiptForStorage.Warehouse                                  AS Warehouse,
	|	DiscrepancyReportFollowingReceipt.Director                       AS Director,
	|	DiscrepancyReportFollowingReceipt.ChiefAccountant                   AS ChiefAccountant,
	|	GoodsReceiptForStorage.BusinessOperation                  AS BusinessOperation,
	|	GoodsReceiptForStorage.Manager                               AS Manager,
	|	GoodsReceiptForStorage.SalesOpportunity                                 AS SalesOpportunity,
	|	GoodsReceiptForStorage.Department                          AS Department,
	|	GoodsReceiptForStorage.Currency                                 AS Currency,
	|	GoodsReceiptForStorage.VendorPriceKind                      AS VendorPriceKind,
	|	NOT GoodsReceiptForStorage.Posted                            AS ThereAreErrorsInReceiptDocument,
	|	NOT DiscrepancyReportFollowingReceipt.Posted                        AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingReceipt.Status                             AS StatusOfDivergenceReport,
	|	NOT DiscrepancyReportFollowingReceipt.Status IN (
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_)) AS ThereAreErrorsStatusReport
	|FROM
	|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|		ON (TRUE)
	|WHERE
	|	GoodsReceiptForStorage.Ref = &DocumentBasisCorrectionOfBasis
	|	AND DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingReceipt.RowCode               AS RowCode,
	|	DiscrepancyReportFollowingReceipt.Products            AS Products,
	|	DiscrepancyReportFollowingReceipt.PartnerProducts  AS PartnerProducts,
	|	DiscrepancyReportFollowingReceipt.Characteristic          AS Characteristic,
	|	DiscrepancyReportFollowingReceipt.Package                AS Package,
	|	DiscrepancyReportFollowingReceipt.Purpose              AS Purpose,
	|	DiscrepancyReportFollowingReceipt.Series                   AS Series,
	|	DiscrepancyReportFollowingReceipt.BatchesIndicationStatus     AS BatchesIndicationStatus,
	|	SUM(DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument -
	|		DiscrepancyReportFollowingReceipt.NumberOfPackages) AS NumberOfPackages,
	|	SUM(DiscrepancyReportFollowingReceipt.CountByDocument -
	|		DiscrepancyReportFollowingReceipt.Count)         AS Count,
	|	DiscrepancyReportFollowingReceipt.Price                    AS Price,
	|	SUM(DiscrepancyReportFollowingReceipt.SumByDocument -
	|		DiscrepancyReportFollowingReceipt.Sum)              AS Sum,
	|	DiscrepancyReportFollowingReceipt.PurchaseOrder         AS PurchaseOrder,
	|	DiscrepancyReportFollowingReceipt.Warehouse                   AS Warehouse,
	|	DiscrepancyReportFollowingReceipt.SalesOpportunity                  AS SalesOpportunity,
	|	DiscrepancyReportFollowingReceipt.CCDNumber                AS CCDNumber
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceipt.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)
	|	AND DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument - DiscrepancyReportFollowingReceipt.NumberOfPackages > 0
	|	AND DiscrepancyReportFollowingReceipt.DocumentBasis = &DocumentBasis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceipt.RowCode,
	|	DiscrepancyReportFollowingReceipt.Products,
	|	DiscrepancyReportFollowingReceipt.PartnerProducts,
	|	DiscrepancyReportFollowingReceipt.Characteristic,
	|	DiscrepancyReportFollowingReceipt.Package,
	|	DiscrepancyReportFollowingReceipt.Purpose,
	|	DiscrepancyReportFollowingReceipt.Series,
	|	DiscrepancyReportFollowingReceipt.BatchesIndicationStatus,
	|	DiscrepancyReportFollowingReceipt.Price,
	|	DiscrepancyReportFollowingReceipt.PurchaseOrder,
	|	DiscrepancyReportFollowingReceipt.Warehouse,
	|	DiscrepancyReportFollowingReceipt.SalesOpportunity,
	|	DiscrepancyReportFollowingReceipt.CCDNumber
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products    AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic  AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series           AS Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose      AS Purpose,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument -
	|		DiscrepancyReportFollowingReceiptSetOfSeries.Count) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument - DiscrepancyReportFollowingReceiptSetOfSeries.Count > 0
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.DocumentBasis = &DocumentBasis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose";
	
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	
	// Filling in the act if there is a correction of the grounds of the act.
	If FillingData.Property("CorrectionOfBasis") And ValueIsFilled(FillingData.CorrectionOfBasis) Then
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingData.CorrectionOfBasis);
	Else
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingData.BasisOfAct);
	EndIf;
	
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[0].Select();
	
	HeaderSelection.Next();
	
	// According to the receipt document
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.DocumentInflow, Undefined,
		HeaderSelection.ThereAreErrorsInReceiptDocument);
	
	// According to the act of discrepancies
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.DiscrepancyCertificate,
		HeaderSelection.StatusOfDivergenceReport,
		HeaderSelection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
		HeaderSelection.ThereAreErrorsStatusReport,
		DiscrepanciesServer.ArrayOfAcceptableStatusesOfReportsOfDiscrepanciesWhenCreatedBasedOn());
	
	SubsequentDeliveryByDocument = FillingData.BasisOfAct;
	FillPropertyValues(ThisObject, HeaderSelection);
	
	TableOfGoods = QueryBatch[1].Unload();
	
	For Each CurRow In TableOfGoods Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurRow);
		
		NewRow.Sum = NewRow.Price * NewRow.NumberOfPackages;
		
		If ValueIsFilled(CurRow.PurchaseOrder) Then
			ReceiptUnderOrders = True;
		EndIf;
	EndDo;
	
	OrdersServer.FillInOrderInOrderHeaderInTableSection(PurchaseOrder, Goods, "PurchaseOrder");
	
	SetOfSeries.Load(QueryBatch[2].Unload());
	
EndProcedure

Procedure CorrectionOfCorrectionOfDocumentOnBasisOfActOfDiscrepanciesAfterReceipt(FillingData)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsOfAct.RowCode            AS RowCode,
	|	ProductsOfAct.FilledUsingBaseDocument AS FilledUsingBaseDocument,
	|	ProductsOfAct.Products         AS Products,
	|	ProductsOfAct.PartnerProducts AS PartnerProducts,
	|	ProductsOfAct.Characteristic       AS Characteristic,
	|	ProductsOfAct.Package             AS Package,
	|	ProductsOfAct.Purpose           AS Purpose,
	|	ProductsOfAct.Series                AS Series,
	|	ProductsOfAct.BatchesIndicationStatus  AS BatchesIndicationStatus,
	|	ProductsOfAct.Price                 AS Price,
	|	ProductsOfAct.PurchaseOrder      AS PurchaseOrder,
	|	ProductsOfAct.Warehouse                AS Warehouse,
	|	ProductsOfAct.SalesOpportunity               AS SalesOpportunity,
	|	ProductsOfAct.CCDNumber             AS CCDNumber,
	|	ProductsOfAct.Count           AS Count,
	|	ProductsOfAct.Sum                AS Sum
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS ProductsOfAct
	|WHERE
	|	ProductsOfAct.Ref = &DiscrepancyCertificate
	|	AND ProductsOfAct.DocumentBasis = &DocumentBasis
	|	AND ProductsOfAct.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|	AND ProductsOfAct.Count > 0
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	ActSeries.LineNumber    AS LineNumber,
	|	ActSeries.Products   AS Products,
	|	ActSeries.Characteristic AS Characteristic,
	|	ActSeries.Series          AS Series,
	|	ActSeries.Purpose     AS Purpose,
	|	ActSeries.Warehouse          AS Warehouse,
	|	ActSeries.Count     AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS ActSeries
	|WHERE
	|	ActSeries.Ref = &DiscrepancyCertificate
	|	AND ActSeries.DocumentBasis = &DocumentBasis
	|	AND ActSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|	AND ActSeries.Count > 0
	|	AND NOT (NOT ActSeries.FilledUsingBaseDocument
	|		AND ActSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef))";
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	TableOfItemsOfReport = QueryBatch[0].Unload();
	ActSeriesTable  = QueryBatch[1].Unload();
	
	GoodsTable = Goods.Unload();
	SeriesTable  = SetOfSeries.Unload();
	
	// Re-filling of products and series according to the act
	SelectionColumns =
		"Warehouse,
		|Products,
		|PartnerProducts,
		|Characteristic,
		|Purpose,
		|Series,
		|CCDNumber";
	If ReceiptUnderOrders Then
		SelectionColumns = "RowCode, PurchaseOrder, " + SelectionColumns;
	EndIf;
	FilterParameters = New Structure(SelectionColumns);
	
	For Each CurRow In TableOfItemsOfReport Do
		
		If CurRow.FilledUsingBaseDocument Then
			FillPropertyValues(FilterParameters, CurRow);
			FoundRows = GoodsTable.FindRows(FilterParameters);
			If FoundRows.Count() > 0 Then
				FoundRow = FoundRows[0];
				FoundRow.Count = CurRow.Count;
				FoundRow.Sum      = CurRow.Sum;
			Else
				NewRow = GoodsTable.Add();
				FillPropertyValues(NewRow, CurRow);
			EndIf;
		Else // to add lines from the over-order report
			NewRow = GoodsTable.Add();
			FillPropertyValues(NewRow, CurRow);
		EndIf;
		
	EndDo;
	
	SelectionColumns =
		"LineNumber,
		|Products,
		|Characteristic,
		|Series,
		|Purpose,
		|Warehouse";
	FilterParameters = New Structure(SelectionColumns);
	
	For Each CurRow In ActSeriesTable Do
		
		FillPropertyValues(FilterParameters, CurRow);
		
		FoundRows = SeriesTable.FindRows(FilterParameters);
		If FoundRows.Count() > 0 Then 
			
			For Each FoundRow In FoundRows Do
				
				If FoundRow.Count = CurRow.Count Then
					Continue;
				EndIf;
				
				If FoundRow.Count > CurRow.Count Then
					FoundRow.Count = CurRow.Count;
				Else
					NewRow = SeriesTable.Add();
					FillPropertyValues(NewRow, FoundRow);
					NewRow.Count = CurRow.Count - FoundRow.Count;
				EndIf;
				
			EndDo;
			
		Else // to add lines from the act in addition to the order
			NewRow = SeriesTable.Add();
			FillPropertyValues(NewRow, CurRow);
		EndIf;
		
	EndDo;
	
	Goods.Load(GoodsTable);
	SetOfSeries.Load(SeriesTable);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	CurBusinessTransaction = Undefined;
	If FillingData.Property("BusinessOperation", CurBusinessTransaction)
	   And ValueIsFilled(CurBusinessTransaction) Then
		
		BusinessOperation = CurBusinessTransaction;
		
	EndIf;
	
	If FillingData.Property("Warehouse") Then
		
		Warehouse = FillingData.Warehouse;
		
	EndIf;
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		FillInDefaultPurchaseConditions();
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	SelectingTypeOfPrices = New Structure("Owner, AvailableForPurchase", Partner, True);
	VendorPriceKind = Catalogs.VendorPriceTypes.DefaultPriceType(VendorPriceKind, SelectingTypeOfPrices);
	
	If ValueIsFilled(VendorPriceKind) Then
		
		FieldsNames                 = "Currency";
		DetailsSupplierSPriceType = Common.ObjectAttributesValues(VendorPriceKind, FieldsNames);
		
		If Not ValueIsFilled(Currency) Then
			Currency = DetailsSupplierSPriceType.Currency;
		EndIf;
		
	EndIf;
	If ValueIsFilled(Contract)
	   And Common.ObjectAttributeValue(Contract, "BusinessOperation") =
											TollingSchemeClientServer.ContractBusinessTransaction() Then
		Department = Common.ObjectAttributeValue(Contract, "Department");
	Else
		Department = SettingsValueCached.UserDivision(Manager, Department);
	EndIf;
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Warehouse") Then
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse, GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments"), True);
	EndIf;
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
		
	StructureOfResponsible = PurchasesServer.GetWarehouseManager(Warehouse, Manager);
	If StructureOfResponsible <> Undefined Then
		ReceivedBy = StructureOfResponsible.EmployeeResponsible;
		AcceptedPosition = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	ReferenceOrder = DocumentBaseWhenFillingIn(FillingData);
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder, Contract);
	
EndProcedure

Function DocumentBaseWhenFillingIn(FillingData)
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DocumentBasis")
		And (TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.PurchaseOrder")
			Or TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.MaterialProviderOrder2_5")
			Or TypeOf(FillingData.DocumentBasis) = Type("CatalogRef.TermsOfPurchaseFromVendors")) Then
		
		Return FillingData.DocumentBasis;
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DocumentBasis")
		And TypeOf(FillingData.DocumentBasis) = Type("Array") Then
		
		Return FillingData.DocumentBasis[0];
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DiscrepancyCertificate")
		And FillingData.Property("BasisOfAct") 
		And (TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.GoodsShipmentFromStorage")
			Or TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.GoodsReceiptForStorage")) Then
		
		Return FillingData.BasisOfAct;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder")
		Or TypeOf(FillingData) = Type("DocumentRef.MaterialProviderOrder2_5")
		Or TypeOf(FillingData) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		
		Return FillingData;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InventoryKinds

Procedure FillOutTypesOfDocumentInventory() Export
	
	Query = New Query("
	|SELECT
	|	CAST(TableOfGoods.Products AS Catalog.Products) AS Products,
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.InventoryOwnerAttribute	AS InventoryOwnerAttribute
	|INTO TableOfDocumentProducts
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber  AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE						AS ThisIsReusablePackage,
	|	&Organization				AS Organization,
	|	&InventoryType                 AS InventoryType,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&Terms					AS Terms,
	|	&BusinessOperation      AS BusinessOperation,
	|	&Currency						AS Currency,
	|	&TaxationOfOrganization	AS TaxationOfOrganization,
	|	&Partner					AS GoodsOwner,
	|	&Counterparty					AS Counterparty,
	|	&Contract					AS Contract,
	|	&VendorPriceKind          AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TableOfDocumentProducts AS TableOfGoods
	|	
	|	LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|	ON TableOfGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|	OR InventoryKinds.InventoryType <> &InventoryType
	|	OR InventoryKinds.Organization <> &Organization
	|	OR InventoryKinds.Contract <> &Contract
	|	OR InventoryKinds.GoodsOwner <> &Partner
	|	OR InventoryKinds.PriceKind <> &VendorPriceKind
	|");
	
	TempTablesManager = New TempTablesManager;
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		InventoryType = Enums.InventoryTypes.MaterialOfMaterialProvider;
	Else
		InventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell;
	EndIf;
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Organization, Date);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("TableOfGoods",				Goods.Unload(, "LineNumber, Products, InventoryOwnerAttribute"));
	Query.SetParameter("Organization",				Organization);
	Query.SetParameter("Partner",					Partner);
	Query.SetParameter("Counterparty",					Counterparty);
	Query.SetParameter("Terms",					Terms);
	Query.SetParameter("Contract",					Contract);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("TaxationOfOrganization",	AccountingParametersForOrganization.BasicTaxationVATSales);
	Query.SetParameter("SalesOpportunity",						SalesOpportunity);
	Query.SetParameter("BusinessOperation",		BusinessOperation);
	Query.SetParameter("InventoryType",					InventoryType);
	Query.SetParameter("ReceiptUnderOrders",		ReceiptUnderOrders);
	Query.SetParameter("VendorPriceKind",			VendorPriceKind);
	Query.SetParameter("Posted",					Posted);
	
	Query.SetParameter("UseSeparateAccountingByTaxation",
		AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(Organization, Date));
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);

	Query.Execute();
	
	InventoriesServer.FillStockTypesByDefault(TempTablesManager, Goods);
	
EndProcedure

#EndRegion

#Region Rounding

Function RoundingParameters() Export
	
	Parameters = Undefined;
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
	
		Parameters = ProductsServer.ParametersForCheckingFillingQuantity();
	
		Parameters.AdditionalFields.Insert("Warehouse", "Goods.Warehouse");
		Parameters.ConditionForSelectingRowsByAdditionalFields =
			ProductionServer.ConditionForSelectingRowsForRounding("Goods", "Warehouse");
		
	EndIf;
	Return Parameters;

EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
